using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class NicBindingStep : SetupStepBase
{
    public override string Name => "NIC 바인딩";
    public override string Description => "네트워크 어댑터를 netuio 드라이버에 바인딩/언바인딩합니다.";

    private DataGridView? _grid;
    private Button? _btnBind;
    private Button? _btnUnbind;
    private Button? _btnRefresh;
    private List<NicInfo> _nics = new();

    protected override void OnCreateContent(Panel panel)
    {
        var toolbar = new FlowLayoutPanel
        {
            Dock = DockStyle.Top,
            Height = 40,
            FlowDirection = FlowDirection.LeftToRight,
            Padding = new Padding(0, 4, 0, 4)
        };

        _btnRefresh = CreateButton("새로고침", Color.FromArgb(80, 80, 80));
        _btnRefresh.Click += async (_, _) => await RefreshNics();
        toolbar.Controls.Add(_btnRefresh);

        _btnBind = CreateButton("DPDK 바인딩", Color.FromArgb(0, 122, 204));
        _btnBind.Click += async (_, _) => await BindSelected();
        toolbar.Controls.Add(_btnBind);

        _btnUnbind = CreateButton("Windows 복원", Color.FromArgb(180, 100, 30));
        _btnUnbind.Click += async (_, _) => await UnbindSelected();
        toolbar.Controls.Add(_btnUnbind);

        panel.Controls.Add(toolbar);

        _grid = new DataGridView
        {
            Dock = DockStyle.Fill,
            BackgroundColor = Color.FromArgb(30, 30, 30),
            ForeColor = Color.White,
            DefaultCellStyle = new DataGridViewCellStyle
            {
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.White,
                SelectionBackColor = Color.FromArgb(62, 62, 66),
                SelectionForeColor = Color.White,
                Font = new Font("Segoe UI", 9.5f)
            },
            ColumnHeadersDefaultCellStyle = new DataGridViewCellStyle
            {
                BackColor = Color.FromArgb(45, 45, 48),
                ForeColor = Color.White,
                Font = new Font("Segoe UI Semibold", 9.5f)
            },
            EnableHeadersVisualStyles = false,
            AllowUserToAddRows = false,
            AllowUserToDeleteRows = false,
            ReadOnly = false,
            SelectionMode = DataGridViewSelectionMode.FullRowSelect,
            MultiSelect = false,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            RowHeadersVisible = false,
            GridColor = Color.FromArgb(60, 60, 60)
        };

        _grid.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Select", HeaderText = "", Width = 30, AutoSizeMode = DataGridViewAutoSizeColumnMode.None });
        _grid.Columns.Add("Name", "이름");
        _grid.Columns.Add("HardwareId", "Hardware ID");
        _grid.Columns.Add("Driver", "현재 드라이버");
        _grid.Columns.Add("Supported", "DPDK 지원");
        _grid.Columns.Add("Status", "상태");

        panel.Controls.Add(_grid);
        _grid.BringToFront();
    }

    private static Button CreateButton(string text, Color bgColor) => new Button
    {
        Text = text,
        Width = 120,
        Height = 30,
        FlatStyle = FlatStyle.Flat,
        BackColor = bgColor,
        ForeColor = Color.White,
        Font = new Font("Segoe UI", 9f),
        Margin = new Padding(4, 0, 4, 0)
    };

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        // Load supported HW IDs from netuio.inf
        string root = GetProjectRoot();
        string infPath = Path.Combine(root, "dpdk-kmods", "windows", "netuio", "x64", "Release", "netuio", "netuio.inf");
        if (File.Exists(infPath))
        {
            NicDetector.LoadSupportedIds(infPath);
            LogInfo($"netuio.inf에서 지원 HW ID 로드 완료");
        }
        else
        {
            LogWarning("netuio.inf를 찾을 수 없음 — DPDK 지원 여부 확인 불가");
        }

        await RefreshNics();
        LogInfo("NIC 목록을 확인하고 바인딩/언바인딩할 어댑터를 선택하세요.");
        LogInfo("선택 후 'DPDK 바인딩' 또는 'Windows 복원' 버튼을 클릭하세요.");
    }

    private async Task RefreshNics()
    {
        LogInfo("NIC 목록 갱신 중...");
        _nics = await NicDetector.EnumerateNicsAsync();

        if (_grid == null) return;

        if (_grid.InvokeRequired)
        {
            _grid.BeginInvoke(() => PopulateGrid());
        }
        else
        {
            PopulateGrid();
        }

        LogSuccess($"  {_nics.Count}개 어댑터 감지");
    }

    private void PopulateGrid()
    {
        _grid!.Rows.Clear();
        foreach (var nic in _nics)
        {
            int row = _grid.Rows.Add(
                false,
                nic.FriendlyName,
                nic.HardwareId,
                nic.CurrentDriver,
                nic.IsDpdkSupported ? "\u2714" : "",
                nic.StatusDisplay
            );

            if (nic.IsBoundToNetuio)
                _grid.Rows[row].DefaultCellStyle.ForeColor = Color.LimeGreen;
            else if (nic.IsDpdkSupported)
                _grid.Rows[row].DefaultCellStyle.ForeColor = Color.DodgerBlue;
        }
    }

    private async Task BindSelected()
    {
        var selected = GetSelectedNics();
        if (selected.Count == 0)
        {
            LogWarning("바인딩할 NIC를 선택하세요.");
            return;
        }

        string? devcon = WdkLocator.FindDevcon();
        string root = GetProjectRoot();
        string infPath = Path.Combine(root, "dpdk-kmods", "windows", "netuio", "x64", "Release", "netuio", "netuio.inf");

        if (!File.Exists(infPath))
        {
            LogError($"netuio.inf 없음: {infPath}");
            return;
        }

        foreach (var nic in selected)
        {
            if (nic.IsBoundToNetuio)
            {
                LogInfo($"  {nic.FriendlyName} — 이미 netuio 바인딩됨");
                continue;
            }

            LogInfo($"바인딩 중: {nic.FriendlyName} ({nic.InstanceId})...");
            bool bound = false;

            // 1. Try devcon update (preferred)
            if (devcon != null)
            {
                LogInfo($"  [1] devcon update 시도...");
                // Extract short HW ID (PCI\VEN_xxxx&DEV_xxxx) from InstanceId
                string shortHwId = ExtractShortHwId(nic.InstanceId);
                var result = await ProcessRunner.RunAsync(devcon,
                    $"update \"{infPath}\" \"{shortHwId}\"",
                    onOutputLine: s => LogInfo($"  {s}"),
                    onErrorLine: s => LogWarning($"  {s}"));

                await Task.Delay(2000);

                if (result.Success)
                {
                    bound = await VerifyBinding(nic.InstanceId);
                    if (bound)
                    {
                        LogSuccess($"  {nic.FriendlyName} devcon 바인딩 성공");
                        continue;
                    }
                }
                LogWarning($"  devcon 실패 (exit: {result.ExitCode}), fallback 시도...");
            }

            // 2. Fallback: pnputil /add-driver + /scan-devices (same as toggle_x550.ps1)
            LogInfo("  [2] pnputil /add-driver + /scan-devices 시도...");

            var addResult = await ProcessRunner.RunAsync("pnputil.exe",
                $"/add-driver \"{infPath}\" /install",
                onOutputLine: s => LogInfo($"  {s}"),
                onErrorLine: s => LogWarning($"  {s}"));

            await ProcessRunner.RunAsync("pnputil.exe", "/scan-devices",
                onOutputLine: s => LogInfo($"  {s}"));

            await Task.Delay(3000);

            bound = await VerifyBinding(nic.InstanceId);
            if (bound)
            {
                LogSuccess($"  {nic.FriendlyName} pnputil 바인딩 성공");
            }
            else
            {
                LogError($"  {nic.FriendlyName} 자동 바인딩 실패");
                LogWarning("  수동 방법: 장치 관리자 → NIC 우클릭 → 드라이버 업데이트 → 찾아보기:");
                LogWarning($"  {Path.GetDirectoryName(infPath)}");
            }
        }

        await RefreshNics();
    }

    /// <summary>
    /// Verify if a device is now bound to netuio by checking its class.
    /// </summary>
    private async Task<bool> VerifyBinding(string instanceId)
    {
        var result = await ProcessRunner.RunPowerShellAsync(
            $"(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {{ $_.InstanceId -eq '{instanceId}' }}).Class");
        return result.Output.Trim().Equals("Windows UIO", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Extract short HW ID like "PCI\VEN_8086&DEV_1563" from full InstanceId.
    /// </summary>
    private static string ExtractShortHwId(string instanceId)
    {
        // InstanceId: PCI\VEN_8086&DEV_1563&SUBSYS_001D8086&REV_01\4&1F22BE48&0&00E4
        // We need:    PCI\VEN_8086&DEV_1563
        var match = System.Text.RegularExpressions.Regex.Match(instanceId,
            @"(PCI\\VEN_[0-9A-Fa-f]+&DEV_[0-9A-Fa-f]+)", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        return match.Success ? match.Groups[1].Value : instanceId;
    }

    private async Task UnbindSelected()
    {
        var selected = GetSelectedNics();
        if (selected.Count == 0)
        {
            LogWarning("언바인딩할 NIC를 선택하세요.");
            return;
        }

        foreach (var nic in selected)
        {
            if (!nic.IsBoundToNetuio)
            {
                LogInfo($"  {nic.FriendlyName} — 이미 Windows 드라이버 사용 중");
                continue;
            }

            LogInfo($"언바인딩 중: {nic.FriendlyName}...");

            // 1. Find and remove ALL netuio OEM driver packages (same logic as toggle_x550.ps1)
            LogInfo("  [1] netuio 드라이버 패키지 제거 중...");
            var enumResult = await ProcessRunner.RunAsync("pnputil.exe", "/enum-drivers");
            string[] lines = enumResult.Output.Split('\n');

            string? currentOem = null;
            int removedCount = 0;
            foreach (var line in lines)
            {
                var oemMatch = System.Text.RegularExpressions.Regex.Match(line, @"(oem\d+\.inf)");
                if (oemMatch.Success)
                    currentOem = oemMatch.Groups[1].Value;

                if (line.Contains("netuio", StringComparison.OrdinalIgnoreCase) && currentOem != null)
                {
                    LogInfo($"  제거: {currentOem}");
                    await ProcessRunner.RunAsync("pnputil.exe",
                        $"/delete-driver {currentOem} /uninstall /force",
                        onOutputLine: s => LogInfo($"    {s}"),
                        onErrorLine: s => LogWarning($"    {s}"));
                    removedCount++;
                    currentOem = null;
                }
            }

            if (removedCount == 0)
                LogWarning("  netuio OEM 패키지를 찾지 못함");

            // 2. Rescan devices
            LogInfo("  [2] 하드웨어 재스캔...");
            await ProcessRunner.RunAsync("pnputil.exe", "/scan-devices",
                onOutputLine: s => LogInfo($"  {s}"));

            await Task.Delay(3000);

            // 3. Verify
            bool restored = !(await VerifyBinding(nic.InstanceId));
            if (restored)
                LogSuccess($"  {nic.FriendlyName} 원래 드라이버 복원 완료");
            else
                LogWarning($"  {nic.FriendlyName} 아직 netuio 상태 — 재부팅 필요할 수 있음");
        }

        await RefreshNics();
    }

    private List<NicInfo> GetSelectedNics()
    {
        var selected = new List<NicInfo>();
        if (_grid == null) return selected;

        for (int i = 0; i < _grid.Rows.Count; i++)
        {
            if (_grid.Rows[i].Cells["Select"].Value is true && i < _nics.Count)
                selected.Add(_nics[i]);
        }
        return selected;
    }
}
