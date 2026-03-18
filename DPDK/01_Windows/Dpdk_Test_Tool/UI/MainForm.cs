using System.Diagnostics;
using HwNet;
using HwNet.Utilities;
using DpdkTestTool.Core;

namespace DpdkTestTool.UI
{
    public class MainForm : Form
    {
        private TabControl tabControl = null!;
        private DpdkUdpTab udpTab = null!;
        private SocketUdpTab socketUdpTab = null!;
        private TcpTestTab tcpTab = null!;
        private PerformanceTab perfTab = null!;
        private DpdkFtpTab ftpTab = null!;
        private SettingsTab settingsTab = null!;
        private PowerPlanHelper? _powerPlan;

        public MainForm()
        {
            this.Text = "DPDK Test Tool - TCP/UDP 통신 테스터";
            this.Size = new Size(700, 700);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.MinimumSize = new Size(700, 700);

            InitializeUI();
            LoadLastSettings();
            ApplyHighPerformancePower();

            this.FormClosing += MainForm_FormClosing;
        }

        private void InitializeUI()
        {
            tabControl = new TabControl
            {
                Dock = DockStyle.Fill,
                Font = new Font(this.Font.FontFamily, 10)
            };

            // Tab 1: DPDK UDP
            var tabUdp = new TabPage("DPDK UDP");
            udpTab = new DpdkUdpTab();
            tabUdp.Controls.Add(udpTab);

            // Tab 2: Socket UDP
            var tabSocketUdp = new TabPage("Socket UDP");
            socketUdpTab = new SocketUdpTab();
            tabSocketUdp.Controls.Add(socketUdpTab);

            // Tab 3: TCP
            var tabTcp = new TabPage("TCP 테스트");
            tcpTab = new TcpTestTab();
            tabTcp.Controls.Add(tcpTab);

            // Tab 4: Performance
            var tabPerf = new TabPage("성능 모니터");
            perfTab = new PerformanceTab();
            perfTab.SetPerfCounterSource(() => udpTab.PerfCounter);
            perfTab.SetSocketPerfCounterSource(() => socketUdpTab.PerfCounter);
            perfTab.SetDpdkRttStatsSource(() => udpTab.CurrentRttStats);
            perfTab.SetSocketRttStatsSource(() => socketUdpTab.CurrentRttStats);
            tabPerf.Controls.Add(perfTab);

            // Tab 5: DPDK FTP
            var tabFtp = new TabPage("DPDK FTP");
            ftpTab = new DpdkFtpTab();
            tabFtp.Controls.Add(ftpTab);

            // Tab 6: Settings
            var tabSettings = new TabPage("DPDK 설정");
            settingsTab = new SettingsTab();
            tabSettings.Controls.Add(settingsTab);

            tabControl.TabPages.AddRange(new[] { tabUdp, tabSocketUdp, tabTcp, tabPerf, tabFtp, tabSettings });

            this.Controls.Add(tabControl);

            // Profile callbacks
            settingsTab.CollectAllSettings = () =>
            {
                var s = new AppSettings();
                settingsTab.CollectSettings(s);
                udpTab.CollectSettings(s);
                ftpTab.CollectSettings(s);
                return s;
            };
            settingsTab.ApplyAllSettings = (s) =>
            {
                settingsTab.ApplySettings(s);
                udpTab.ApplySettings(s);
                socketUdpTab.ApplySettings(s);
                ftpTab.ApplySettings(s);
            };

            // Restart callback
            settingsTab.RestartRequested = PerformRestart;
        }

        private void LoadLastSettings()
        {
            try
            {
                var settings = AppSettings.Load();
                settingsTab.ApplySettings(settings);
                udpTab.ApplySettings(settings);
                socketUdpTab.ApplySettings(settings);
                ftpTab.ApplySettings(settings);
            }
            catch { }
        }

        private bool _restarting;

        private void PerformRestart()
        {
            // 1. Save current settings
            try
            {
                var settings = new AppSettings();
                settingsTab.CollectSettings(settings);
                udpTab.CollectSettings(settings);
                ftpTab.CollectSettings(settings);
                settings.Save();
            }
            catch { }

            // 2. Start new instance
            string exePath = Environment.ProcessPath ?? Process.GetCurrentProcess().MainModule?.FileName
                ?? Application.ExecutablePath;
            Process.Start(new ProcessStartInfo
            {
                FileName = exePath,
                UseShellExecute = true,
                Verb = "runas"  // DPDK needs admin privileges
            });

            // 3. Close current instance (FormClosing will handle cleanup)
            _restarting = true;
            Application.Exit();
        }

        private void ApplyHighPerformancePower()
        {
            _powerPlan = new PowerPlanHelper();
            _powerPlan.ApplyHighPerformance();
        }

        private void MainForm_FormClosing(object? sender, FormClosingEventArgs e)
        {
            // 1. Auto-save current settings
            try
            {
                var settings = new AppSettings();
                settingsTab.CollectSettings(settings);
                udpTab.CollectSettings(settings);
                ftpTab.CollectSettings(settings);
                settings.Save();
            }
            catch { }

            // 2. 모든 엔진 중지 (DPDK 장치 정리 전 필수)
            try { udpTab.StopAllEngines(); } catch { }
            try { ftpTab?.StopEngine(); } catch { }

            // 3. DPDK 장치 중지 + EAL 정리 (hugepage 메모리 해제)
            try { HwManager.Instance.Cleanup(); } catch { }

            // 4. 전원 설정 복원
            try { _powerPlan?.Restore(); } catch { }
        }
    }
}
