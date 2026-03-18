using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class SystemConfigStep : SetupStepBase
{
    public override string Name => "시스템 설정";
    public override string Description => "SeLockMemoryPrivilege, TestSigning 설정 후 재부팅이 필요합니다.";

    private Button? _btnReboot;

    protected override void OnCreateContent(Panel panel)
    {
        _btnReboot = new Button
        {
            Text = "지금 재부팅",
            Width = 140,
            Height = 36,
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(0, 122, 204),
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 10f),
            Visible = false,
            Anchor = AnchorStyles.Bottom | AnchorStyles.Right
        };
        _btnReboot.Click += (_, _) => DoReboot();

        var btnLater = new Button
        {
            Text = "나중에 재부팅",
            Width = 140,
            Height = 36,
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(80, 80, 80),
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 10f),
            Visible = false,
            Anchor = AnchorStyles.Bottom | AnchorStyles.Right
        };
        btnLater.Click += (_, _) =>
        {
            LogWarning("재부팅을 나중에 수행합니다. 재부팅 전까지 이후 스텝은 실패할 수 있습니다.");
            btnLater.Visible = false;
            _btnReboot!.Visible = false;
        };

        var flowPanel = new FlowLayoutPanel
        {
            Dock = DockStyle.Bottom,
            Height = 50,
            FlowDirection = FlowDirection.RightToLeft,
            WrapContents = false,
            Padding = new Padding(8)
        };
        flowPanel.Controls.Add(btnLater);
        flowPanel.Controls.Add(_btnReboot);
        panel.Controls.Add(flowPanel);
    }

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        // 1. SeLockMemoryPrivilege
        LogInfo("[1/4] SeLockMemoryPrivilege 설정 중...");
        await ConfigureSeLockMemory(ct);

        ct.ThrowIfCancellationRequested();

        // 2. System Restore Point
        LogInfo("[2/4] 시스템 복원 지점 생성 중...");
        await CreateRestorePoint(ct);

        ct.ThrowIfCancellationRequested();

        // 3. BCD Backup
        LogInfo("[3/4] BCD 백업 중...");
        await BackupBcd(ct);

        ct.ThrowIfCancellationRequested();

        // 4. TestSigning
        LogInfo("[4/4] TestSigning 활성화 중...");
        await EnableTestSigning(ct);

        // Save state for resume after reboot
        var state = SetupState.Load() ?? new SetupState();
        state.CurrentStep = 3; // Resume at DpdkBuild after reboot
        state.ProjectRoot = GetProjectRoot();
        state.Save();
        SetupState.RegisterRunOnce();

        LogSuccess("시스템 설정 완료 — 재부팅이 필요합니다.");
        if (_btnReboot != null)
        {
            _btnReboot.BeginInvoke(() => _btnReboot.Visible = true);
            // Also show "later" button
            var flowPanel = _btnReboot.Parent as FlowLayoutPanel;
            if (flowPanel != null)
            {
                foreach (Control c in flowPanel.Controls)
                    c.BeginInvoke(() => c.Visible = true);
            }
        }
    }

    private async Task ConfigureSeLockMemory(CancellationToken ct)
    {
        var (granted, _) = await SystemInfo.CheckSeLockMemoryPrivilege();
        if (granted)
        {
            LogSuccess("  SeLockMemoryPrivilege 이미 부여됨");
            return;
        }

        string tempCfg = Path.Combine(Path.GetTempPath(), $"secpol_{Guid.NewGuid():N}.cfg");
        string tempDb = Path.Combine(Path.GetTempPath(), $"secedit_{Guid.NewGuid():N}.sdb");

        try
        {
            // Export current policy
            var exportResult = await ProcessRunner.RunAsync("secedit.exe",
                $"/export /cfg \"{tempCfg}\" /areas USER_RIGHTS",
                onOutputLine: s => LogInfo($"  {s}"), ct: ct);

            if (!exportResult.Success)
                throw new Exception("secedit export 실패");

            // Read and modify
            string content = await File.ReadAllTextAsync(tempCfg, ct);
            string userName = System.Security.Principal.WindowsIdentity.GetCurrent().Name;
            string newLine = $"SeLockMemoryPrivilege = *S-1-5-32-544,{userName}";

            if (content.Contains("SeLockMemoryPrivilege", StringComparison.OrdinalIgnoreCase))
            {
                content = System.Text.RegularExpressions.Regex.Replace(
                    content, @"SeLockMemoryPrivilege\s*=\s*.*", newLine);
            }
            else
            {
                content = content.Replace("[Privilege Rights]", $"[Privilege Rights]\r\n{newLine}");
            }

            await File.WriteAllTextAsync(tempCfg, content, ct);

            // Apply
            var applyResult = await ProcessRunner.RunAsync("secedit.exe",
                $"/configure /db \"{tempDb}\" /cfg \"{tempCfg}\" /areas USER_RIGHTS",
                onOutputLine: s => LogInfo($"  {s}"), ct: ct);

            if (!applyResult.Success)
                throw new Exception("secedit configure 실패");

            // Verify
            var (verified, detail) = await SystemInfo.CheckSeLockMemoryPrivilege();
            if (verified)
                LogSuccess("  SeLockMemoryPrivilege 설정 및 검증 완료");
            else
                LogWarning($"  SeLockMemoryPrivilege 적용 확인 필요: {detail}");
        }
        finally
        {
            if (File.Exists(tempCfg)) File.Delete(tempCfg);
            if (File.Exists(tempDb)) File.Delete(tempDb);
        }
    }

    private async Task CreateRestorePoint(CancellationToken ct)
    {
        try
        {
            var result = await ProcessRunner.RunPowerShellAsync(
                "Checkpoint-Computer -Description 'DPDK_Setup_PreConfig' -RestorePointType MODIFY_SETTINGS",
                onOutputLine: s => LogInfo($"  {s}"), ct: ct);

            if (result.Success)
                LogSuccess("  복원 지점 생성 완료");
            else
                LogWarning("  복원 지점 생성 실패 (비치명적)");
        }
        catch
        {
            LogWarning("  복원 지점 생성 건너뜀 (비치명적)");
        }
    }

    private async Task BackupBcd(CancellationToken ct)
    {
        string backupDir = Path.Combine(GetProjectRoot(), "_backup_system");
        Directory.CreateDirectory(backupDir);
        string bcdBackup = Path.Combine(backupDir,
            $"bcd_backup_{DateTime.Now:yyyyMMdd_HHmmss}.bak");

        var result = await ProcessRunner.RunAsync("bcdedit.exe", $"/export \"{bcdBackup}\"",
            onOutputLine: s => LogInfo($"  {s}"), ct: ct);

        if (result.Success)
        {
            LogSuccess($"  BCD 백업 완료: {bcdBackup}");
            var state = SetupState.Load() ?? new SetupState();
            state.BcdBackupPath = bcdBackup;
            state.Save();
        }
        else
        {
            LogWarning("  BCD 백업 실패");
        }
    }

    private async Task EnableTestSigning(CancellationToken ct)
    {
        bool already = await SystemInfo.IsTestSigningEnabled();
        if (already)
        {
            LogSuccess("  TestSigning 이미 활성화됨");
            return;
        }

        // Double-check Secure Boot
        var secureBoot = await SystemInfo.IsSecureBootEnabled();
        if (secureBoot == true)
        {
            LogError("  Secure Boot ON 상태에서 TestSigning 활성화 불가!");
            LogError("  BIOS에서 Secure Boot를 먼저 비활성화하세요.");
            throw new Exception("Secure Boot가 활성화되어 있어 TestSigning 설정 불가");
        }

        var result = await ProcessRunner.RunAsync("bcdedit.exe", "/set testsigning on",
            onOutputLine: s => LogInfo($"  {s}"), ct: ct);

        if (result.Success)
            LogSuccess("  TestSigning 활성화 완료 (재부팅 후 적용)");
        else
            throw new Exception("TestSigning 활성화 실패");
    }

    private static void DoReboot()
    {
        try
        {
            System.Diagnostics.Process.Start("shutdown.exe", "/r /t 10 /c \"DPDK Setup: 시스템 설정 적용을 위해 재부팅합니다.\"");
        }
        catch { }
    }
}
