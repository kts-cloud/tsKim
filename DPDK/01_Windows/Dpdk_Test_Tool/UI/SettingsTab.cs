using System.ComponentModel;
using System.Diagnostics;
using HwNet;
using HwNet.Utilities;
using DpdkTestTool.Core;

namespace DpdkTestTool.UI
{
    public class SettingsTab : UserControl
    {
        // EAL Settings
        private GroupBox grpEal;
        private Label lblCoreMask, lblMemory, lblLogLevel;
        private TextBox txtCoreMask, txtMemory;
        private ComboBox cboLogLevel;
        private Button btnCpuUsage;

        // CPU Usage Panel
        private GroupBox grpCpuUsage;
        private ListView lvCpuUsage;
        private Button btnRefreshCpu, btnApplyCore;

        // Port Settings
        private GroupBox grpPort;
        private Label lblPortId, lblMbufPoolSize, lblLinkSpeed;
        private NumericUpDown nudPortId, nudMbufPoolSize;
        private ComboBox cboLinkSpeed;

        // Profile
        private GroupBox grpProfile;
        private ComboBox cboProfile;
        private Button btnSaveProfile, btnLoadProfile, btnDeleteProfile;

        // Controls
        private GroupBox grpControl;
        private Button btnInitialize, btnRestart;
        private Label lblStatus;
        private RichTextBox rtbInitLog;

        // Info
        private GroupBox grpInfo;
        private Label lblVersion, lblMac, lblState;
        private Label lblActivePort;
        private ComboBox cboActivePort;

        public SettingsTab()
        {
            InitializeUI();
            HwManager.Instance.StatusChanged += OnDpdkStatusChanged;
            HwManager.Instance.ActivePortChanged += OnActivePortChanged;
        }

        private void InitializeUI()
        {
            this.Dock = DockStyle.Fill;

            // === EAL Settings ===
            grpEal = new GroupBox { Text = "EAL 파라미터", Location = new Point(10, 10), Size = new Size(360, 120) };

            lblCoreMask = new Label { Text = "Core Mask:", Location = new Point(15, 28), AutoSize = true };
            txtCoreMask = new TextBox { Text = "0", Location = new Point(120, 25), Width = 100 };

            lblMemory = new Label { Text = "Memory (MB):", Location = new Point(15, 58), AutoSize = true };
            txtMemory = new TextBox { Text = "512", Location = new Point(120, 55), Width = 100 };

            lblLogLevel = new Label { Text = "Log Level:", Location = new Point(15, 88), AutoSize = true };
            cboLogLevel = new ComboBox
            {
                Location = new Point(120, 85), Width = 150, DropDownStyle = ComboBoxStyle.DropDownList
            };
            cboLogLevel.Items.AddRange(new[] { "*:error", "*:warning", "*:info", "*:debug", "lib.eal:debug" });
            cboLogLevel.SelectedIndex = 0;

            btnCpuUsage = new Button { Text = "CPU 확인", Location = new Point(230, 24), Size = new Size(75, 24), Font = new Font("Segoe UI", 8) };
            btnCpuUsage.Click += (s, e) => ToggleCpuUsagePanel();

            grpEal.Controls.AddRange(new Control[] { lblCoreMask, txtCoreMask, btnCpuUsage, lblMemory, txtMemory, lblLogLevel, cboLogLevel });

            // === CPU Usage Panel (initially hidden) ===
            grpCpuUsage = new GroupBox { Text = "CPU 코어 사용량", Location = new Point(10, 500), Size = new Size(650, 180), Visible = false };

            lvCpuUsage = new ListView
            {
                Location = new Point(10, 20), Size = new Size(520, 148),
                View = View.Details, FullRowSelect = true, GridLines = true,
                Font = new Font("Consolas", 9),
                BackColor = Color.FromArgb(30, 30, 30), ForeColor = Color.White,
                HeaderStyle = ColumnHeaderStyle.Nonclickable
            };
            lvCpuUsage.Columns.Add("코어", 55, HorizontalAlignment.Center);
            lvCpuUsage.Columns.Add("사용률", 75, HorizontalAlignment.Center);
            lvCpuUsage.Columns.Add("상태", 120, HorizontalAlignment.Center);
            lvCpuUsage.Columns.Add("바", 260, HorizontalAlignment.Left);

            btnRefreshCpu = new Button { Text = "새로고침", Location = new Point(540, 20), Size = new Size(100, 30) };
            btnRefreshCpu.Click += async (s, e) => await RefreshCpuUsageAsync();

            btnApplyCore = new Button { Text = "선택 적용", Location = new Point(540, 55), Size = new Size(100, 30) };
            btnApplyCore.Click += (s, e) => ApplySelectedCore();

            grpCpuUsage.Controls.AddRange(new Control[] { lvCpuUsage, btnRefreshCpu, btnApplyCore });

            // === Port Settings ===
            grpPort = new GroupBox { Text = "포트 설정", Location = new Point(380, 10), Size = new Size(280, 120) };

            lblPortId = new Label { Text = "Port ID:", Location = new Point(15, 28), AutoSize = true };
            nudPortId = new NumericUpDown { Location = new Point(130, 25), Width = 80, Minimum = 0, Maximum = 31, Value = 0 };

            lblMbufPoolSize = new Label { Text = "Mbuf Pool Size:", Location = new Point(15, 58), AutoSize = true };
            nudMbufPoolSize = new NumericUpDown { Location = new Point(130, 55), Width = 80, Minimum = 1023, Maximum = 65535, Value = 8191 };

            lblLinkSpeed = new Label { Text = "Link Speed:", Location = new Point(15, 88), AutoSize = true };
            cboLinkSpeed = new ComboBox
            {
                Location = new Point(130, 85), Width = 130, DropDownStyle = ComboBoxStyle.DropDownList
            };
            cboLinkSpeed.Items.AddRange(new[] { "Auto (협상)", "10 Mbps", "100 Mbps", "1 Gbps", "10 Gbps" });
            cboLinkSpeed.SelectedIndex = 0;

            grpPort.Controls.AddRange(new Control[] { lblPortId, nudPortId, lblMbufPoolSize, nudMbufPoolSize,
                lblLinkSpeed, cboLinkSpeed });

            // === Profile Management ===
            grpProfile = new GroupBox { Text = "프로필 관리", Location = new Point(10, 140), Size = new Size(650, 55) };

            cboProfile = new ComboBox { Location = new Point(15, 22), Width = 180, DropDownStyle = ComboBoxStyle.DropDown };
            btnSaveProfile = new Button { Text = "저장", Location = new Point(205, 20), Size = new Size(70, 28) };
            btnLoadProfile = new Button { Text = "불러오기", Location = new Point(285, 20), Size = new Size(80, 28) };
            btnDeleteProfile = new Button { Text = "삭제", Location = new Point(375, 20), Size = new Size(60, 28), BackColor = Color.MistyRose };

            btnSaveProfile.Click += BtnSaveProfile_Click;
            btnLoadProfile.Click += BtnLoadProfile_Click;
            btnDeleteProfile.Click += BtnDeleteProfile_Click;

            grpProfile.Controls.AddRange(new Control[] { cboProfile, btnSaveProfile, btnLoadProfile, btnDeleteProfile });

            // === Control ===
            grpControl = new GroupBox { Text = "초기화 제어", Location = new Point(10, 205), Size = new Size(650, 60) };

            btnInitialize = new Button
            {
                Text = "▶ DPDK 초기화", Location = new Point(15, 22), Size = new Size(150, 30),
                BackColor = Color.LightGreen, Font = new Font(this.Font.FontFamily, 10, FontStyle.Bold)
            };
            btnInitialize.Click += BtnInitialize_Click;

            btnRestart = new Button
            {
                Text = "♻ 재시작", Location = new Point(180, 22), Size = new Size(130, 30),
                BackColor = Color.LightCoral, Enabled = false
            };
            btnRestart.Click += BtnRestart_Click;

            lblStatus = new Label
            {
                Text = "상태: 초기화 안됨", Location = new Point(330, 28), AutoSize = true,
                Font = new Font(this.Font.FontFamily, 10, FontStyle.Bold), ForeColor = Color.Gray
            };

            grpControl.Controls.AddRange(new Control[] { btnInitialize, btnRestart, lblStatus });

            // === Info ===
            grpInfo = new GroupBox { Text = "DPDK 정보", Location = new Point(10, 275), Size = new Size(650, 100) };

            lblVersion = new Label { Text = "버전: -", Location = new Point(15, 25), AutoSize = true };
            lblState = new Label { Text = "상태: NotInitialized", Location = new Point(300, 25), AutoSize = true };
            lblMac = new Label { Text = "MAC: -", Location = new Point(300, 45), AutoSize = true };

            lblActivePort = new Label { Text = "활성 포트:", Location = new Point(15, 48), AutoSize = true };
            cboActivePort = new ComboBox
            {
                Location = new Point(90, 45), Width = 200, DropDownStyle = ComboBoxStyle.DropDownList,
                Enabled = false
            };
            cboActivePort.SelectedIndexChanged += CboActivePort_SelectedIndexChanged;

            grpInfo.Controls.AddRange(new Control[] { lblVersion, lblState, lblMac, lblActivePort, cboActivePort });

            // === Init Log ===
            rtbInitLog = new RichTextBox
            {
                Location = new Point(10, 385), Size = new Size(650, 105),
                ReadOnly = true, BackColor = Color.Black, ForeColor = Color.Lime,
                Font = new Font("Consolas", 9)
            };

            this.Controls.AddRange(new Control[] { grpEal, grpPort, grpProfile, grpControl, grpInfo, rtbInitLog, grpCpuUsage });

            RefreshProfileList();
        }

        private async void BtnInitialize_Click(object? sender, EventArgs e)
        {
            btnInitialize.Enabled = false;
            rtbInitLog.Clear();

            var options = new HwInitOptions
            {
                CoreMask = txtCoreMask.Text,
                MemoryMb = int.TryParse(txtMemory.Text, out int m) ? m : 256,
                LogLevel = cboLogLevel.SelectedItem?.ToString() ?? "*:error",
                PortId = (ushort)nudPortId.Value,
                MbufPoolSize = (uint)nudMbufPoolSize.Value,
                LinkSpeeds = GetLinkSpeedsValue()
            };
            await HwManager.Instance.InitializeAsync(options);

            if (HwManager.Instance.State == HwState.Ready)
            {
                btnRestart.Enabled = true;
            }
            else
            {
                btnInitialize.Enabled = true;
            }
        }

        [Browsable(false), DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
        public Action? RestartRequested { get; set; }

        private void BtnRestart_Click(object? sender, EventArgs e)
        {
            if (MessageBox.Show(
                "DPDK를 재초기화하려면 앱을 재시작해야 합니다.\n현재 설정을 저장하고 재시작하시겠습니까?",
                "재시작 확인",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes)
                return;

            RestartRequested?.Invoke();
        }

        private void CboActivePort_SelectedIndexChanged(object? sender, EventArgs e)
        {
            if (cboActivePort.SelectedIndex < 0) return;
            var mgr = HwManager.Instance;
            if (mgr.State != HwState.Ready) return;

            var setupPorts = mgr.Ports.Where(p => p.IsSetup).ToList();
            if (cboActivePort.SelectedIndex < setupPorts.Count)
            {
                ushort newPortId = setupPorts[cboActivePort.SelectedIndex].PortId;
                mgr.SwitchPort(newPortId);
            }
        }

        private void OnActivePortChanged()
        {
            if (this.IsDisposed || !this.IsHandleCreated) return;
            if (this.InvokeRequired) { try { this.BeginInvoke(OnActivePortChanged); } catch { } return; }
            var mgr = HwManager.Instance;
            lblMac.Text = $"MAC: {NetUtils.FormatMac(mgr.LocalMac)}";
        }

        // === Profile Management ===

        [Browsable(false), DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
        public Func<AppSettings>? CollectAllSettings { get; set; }

        [Browsable(false), DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
        public Action<AppSettings>? ApplyAllSettings { get; set; }

        private void RefreshProfileList()
        {
            cboProfile.Items.Clear();
            foreach (var name in AppSettings.GetSavedProfiles())
                cboProfile.Items.Add(name);
        }

        private void BtnSaveProfile_Click(object? sender, EventArgs e)
        {
            string name = cboProfile.Text.Trim();
            if (string.IsNullOrEmpty(name))
            {
                MessageBox.Show("프로필 이름을 입력하세요.", "알림", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var settings = CollectAllSettings?.Invoke() ?? new AppSettings();
            settings.SaveAs(name);
            settings.Save(); // also save as last
            RefreshProfileList();
            cboProfile.Text = name;
            MessageBox.Show($"프로필 '{name}' 저장 완료!", "저장", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void BtnLoadProfile_Click(object? sender, EventArgs e)
        {
            string name = cboProfile.Text.Trim();
            if (string.IsNullOrEmpty(name))
            {
                MessageBox.Show("불러올 프로필을 선택하세요.", "알림", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var settings = AppSettings.LoadProfile(name);
            ApplyAllSettings?.Invoke(settings);
        }

        private void BtnDeleteProfile_Click(object? sender, EventArgs e)
        {
            string name = cboProfile.Text.Trim();
            if (string.IsNullOrEmpty(name))
                return;

            if (MessageBox.Show($"프로필 '{name}'을 삭제하시겠습니까?", "삭제 확인",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                string path = Path.Combine(
                    AppDomain.CurrentDomain.BaseDirectory, "settings", name + ".json");
                if (File.Exists(path))
                    File.Delete(path);
                RefreshProfileList();
                cboProfile.Text = "";
            }
        }

        /// <summary>
        /// ComboBox 인덱스 → DPDK link_speeds 값 변환
        /// 0=Auto, 1=10M, 2=100M, 3=1G, 4=10G
        /// </summary>
        private uint GetLinkSpeedsValue()
        {
            const uint RTE_ETH_LINK_SPEED_FIXED = (1 << 30);
            return cboLinkSpeed.SelectedIndex switch
            {
                1 => RTE_ETH_LINK_SPEED_FIXED | (1 << 1),   // 10M
                2 => RTE_ETH_LINK_SPEED_FIXED | (1 << 2),   // 100M
                3 => RTE_ETH_LINK_SPEED_FIXED | (1 << 4),   // 1G
                4 => RTE_ETH_LINK_SPEED_FIXED | (1 << 8),   // 10G
                _ => 0  // Autoneg
            };
        }

        public void ApplySettings(AppSettings settings)
        {
            txtCoreMask.Text = settings.CoreMask;
            txtMemory.Text = settings.Memory;
            int logIdx = cboLogLevel.Items.IndexOf(settings.LogLevel);
            cboLogLevel.SelectedIndex = logIdx >= 0 ? logIdx : 0;
            nudPortId.Value = Math.Clamp(settings.PortId, (int)nudPortId.Minimum, (int)nudPortId.Maximum);
            nudMbufPoolSize.Value = Math.Clamp(settings.MbufPoolSize, (int)nudMbufPoolSize.Minimum, (int)nudMbufPoolSize.Maximum);
            cboLinkSpeed.SelectedIndex = Math.Clamp(settings.LinkSpeed, 0, cboLinkSpeed.Items.Count - 1);
        }

        public void CollectSettings(AppSettings settings)
        {
            settings.CoreMask = txtCoreMask.Text;
            settings.Memory = txtMemory.Text;
            settings.LogLevel = cboLogLevel.SelectedItem?.ToString() ?? "*:error";
            settings.PortId = (int)nudPortId.Value;
            settings.MbufPoolSize = (int)nudMbufPoolSize.Value;
            settings.LinkSpeed = cboLinkSpeed.SelectedIndex;
        }

        // === CPU Usage ===

        private void ToggleCpuUsagePanel()
        {
            grpCpuUsage.Visible = !grpCpuUsage.Visible;
            if (grpCpuUsage.Visible && lvCpuUsage.Items.Count == 0)
                _ = RefreshCpuUsageAsync();
        }

        private async Task RefreshCpuUsageAsync()
        {
            btnRefreshCpu.Enabled = false;
            btnRefreshCpu.Text = "측정 중...";
            lvCpuUsage.Items.Clear();

            int coreCount = Environment.ProcessorCount;
            var usage = new double[coreCount];

            await Task.Run(() =>
            {
                // Use PerformanceCounter for per-core CPU usage
                var counters = new PerformanceCounter[coreCount];
                try
                {
                    for (int i = 0; i < coreCount; i++)
                        counters[i] = new PerformanceCounter("Processor Information", "% Processor Utility", $"0,{i}");

                    // First call initializes (always returns 0)
                    for (int i = 0; i < coreCount; i++)
                    {
                        try { counters[i].NextValue(); }
                        catch { }
                    }

                    Thread.Sleep(1000);

                    for (int i = 0; i < coreCount; i++)
                    {
                        try { usage[i] = Math.Min(100, counters[i].NextValue()); }
                        catch { usage[i] = -1; }
                    }
                }
                catch
                {
                    // Fallback: try "Processor" category
                    try
                    {
                        for (int i = 0; i < coreCount; i++)
                            counters[i] = new PerformanceCounter("Processor", "% Processor Time", i.ToString());

                        for (int i = 0; i < coreCount; i++)
                        {
                            try { counters[i].NextValue(); }
                            catch { }
                        }

                        Thread.Sleep(1000);

                        for (int i = 0; i < coreCount; i++)
                        {
                            try { usage[i] = Math.Min(100, counters[i].NextValue()); }
                            catch { usage[i] = -1; }
                        }
                    }
                    catch { }
                }
                finally
                {
                    foreach (var c in counters)
                        c?.Dispose();
                }
            });

            // Populate ListView
            for (int i = 0; i < coreCount; i++)
            {
                string pct = usage[i] >= 0 ? $"{usage[i]:F1}%" : "N/A";
                string status;
                Color rowColor;

                if (usage[i] < 0) { status = "측정 불가"; rowColor = Color.Gray; }
                else if (usage[i] < 15) { status = "여유 (추천)"; rowColor = Color.LimeGreen; }
                else if (usage[i] < 50) { status = "보통"; rowColor = Color.Yellow; }
                else if (usage[i] < 80) { status = "높음"; rowColor = Color.Orange; }
                else { status = "과부하"; rowColor = Color.Red; }

                // ASCII bar
                int barLen = usage[i] >= 0 ? (int)(usage[i] / 100.0 * 30) : 0;
                string bar = new string('|', barLen) + new string('.', 30 - barLen);

                var item = new ListViewItem(new[] { $"Core {i}", pct, status, $"[{bar}]" });
                item.ForeColor = rowColor;
                item.UseItemStyleForSubItems = true;
                lvCpuUsage.Items.Add(item);
            }

            btnRefreshCpu.Text = "새로고침";
            btnRefreshCpu.Enabled = true;
        }

        private void ApplySelectedCore()
        {
            if (lvCpuUsage.SelectedItems.Count == 0)
            {
                MessageBox.Show("코어를 선택하세요.", "알림", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            int coreIndex = lvCpuUsage.SelectedItems[0].Index;
            txtCoreMask.Text = coreIndex.ToString();
        }

        private void OnDpdkStatusChanged(object? sender, HwStatusEventArgs e)
        {
            if (this.IsDisposed || !this.IsHandleCreated) return;
            if (this.InvokeRequired)
            {
                try { this.BeginInvoke(() => OnDpdkStatusChanged(sender, e)); } catch { }
                return;
            }

            // Update status label
            switch (e.State)
            {
                case HwState.Initializing:
                    lblStatus.Text = "상태: 초기화 중...";
                    lblStatus.ForeColor = Color.Orange;
                    break;
                case HwState.Ready:
                    lblStatus.Text = "상태: ✓ 준비 완료";
                    lblStatus.ForeColor = Color.Green;
                    break;
                case HwState.Error:
                    lblStatus.Text = "상태: ✗ 오류";
                    lblStatus.ForeColor = Color.Red;
                    break;
                case HwState.CleanedUp:
                    lblStatus.Text = "상태: 정리 완료";
                    lblStatus.ForeColor = Color.Gray;
                    break;
            }

            // Update info labels
            var mgr = HwManager.Instance;
            lblState.Text = $"상태: {mgr.State}";
            if (mgr.DriverVersion != null)
                lblVersion.Text = $"버전: {mgr.DriverVersion}";
            if (mgr.State == HwState.Ready)
            {
                lblMac.Text = $"MAC: {NetUtils.FormatMac(mgr.LocalMac)}";

                // Populate active port ComboBox
                cboActivePort.SelectedIndexChanged -= CboActivePort_SelectedIndexChanged;
                cboActivePort.Items.Clear();
                var setupPorts = mgr.Ports.Where(p => p.IsSetup).ToList();
                int activeIdx = 0;
                for (int i = 0; i < setupPorts.Count; i++)
                {
                    cboActivePort.Items.Add(setupPorts[i].DisplayName);
                    if (setupPorts[i].PortId == mgr.PortId) activeIdx = i;
                }
                if (cboActivePort.Items.Count > 0)
                    cboActivePort.SelectedIndex = activeIdx;
                cboActivePort.Enabled = setupPorts.Count > 1;
                cboActivePort.SelectedIndexChanged += CboActivePort_SelectedIndexChanged;
            }

            // Append to log
            Color logColor = e.State switch
            {
                HwState.Error => Color.Red,
                HwState.Ready => Color.LightGreen,
                _ => Color.Cyan
            };

            rtbInitLog.SelectionStart = rtbInitLog.TextLength;
            rtbInitLog.SelectionColor = Color.Gray;
            rtbInitLog.AppendText($"[{DateTime.Now:HH:mm:ss}] ");
            rtbInitLog.SelectionColor = logColor;
            rtbInitLog.AppendText($"{e.Message}\n");
            rtbInitLog.ScrollToCaret();
        }
    }
}
