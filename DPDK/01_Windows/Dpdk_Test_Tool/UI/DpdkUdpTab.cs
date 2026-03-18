using HwNet;
using HwNet.Config;
using HwNet.Engine;
using HwNet.Logging;
using HwNet.Models;
using HwNet.Stats;
using HwNet.Utilities;
using DpdkTestTool.Core;

namespace DpdkTestTool.UI
{
    public class DpdkUdpTab : UserControl
    {
        // Mode selection
        private GroupBox grpMode;
        private RadioButton rdoTx, rdoRx, rdoEcho, rdoReqResp;

        // TX Settings
        private GroupBox grpTxSettings;
        private Label lblDstMac, lblDstIp, lblDstPort, lblSrcIp, lblSrcPort, lblPayloadSize, lblSendRate, lblPayloadText, lblTimeout, lblRepeatCount, lblWindowSize;
        private TextBox txtDstMac, txtDstIp, txtSrcIp, txtPayloadText;
        private NumericUpDown nudDstPort, nudSrcPort, nudPayloadSize, nudSendRate, nudTimeout, nudRepeatCount, nudWindowSize;
        private CheckBox chkWarmup;

        // RX Settings
        private GroupBox grpRxSettings;
        private Label lblFilterIp, lblFilterPort;
        private TextBox txtFilterIp;
        private NumericUpDown nudFilterPort;

        // Control
        private Button btnStart, btnStop;
        private Label lblLiveStats;

        // Log
        private RichTextBox rtbLog;
        private Button btnClearLog;

        // Engines
        private readonly PerformanceCounter _perfCounter = new();
        private HwUdpTxEngine? _txEngine;
        private HwUdpRxEngine? _rxEngine;
        private HwEchoEngine? _echoEngine;
        private HwUdpReqRespEngine? _reqRespEngine;
        private PacketLogger? _pktLogger;
        private System.Windows.Forms.Timer _uiTimer = null!;
        private bool _engineRunning;

        private RttStats? _lastRttStats;

        public PerformanceCounter PerfCounter => _perfCounter;
        public RttStats? CurrentRttStats => _reqRespEngine?.Stats ?? _lastRttStats;

        public DpdkUdpTab()
        {
            InitializeUI();
        }

        private void InitializeUI()
        {
            this.Dock = DockStyle.Fill;

            // === Mode Selection ===
            grpMode = new GroupBox { Text = "모드 선택", Location = new Point(10, 5), Size = new Size(650, 50) };
            rdoTx = new RadioButton { Text = "TX (송신)", Location = new Point(20, 20), AutoSize = true, Checked = true };
            rdoRx = new RadioButton { Text = "RX (수신)", Location = new Point(140, 20), AutoSize = true };
            rdoEcho = new RadioButton { Text = "Echo (에코)", Location = new Point(260, 20), AutoSize = true };
            rdoReqResp = new RadioButton { Text = "Req/Resp", Location = new Point(380, 20), AutoSize = true };
            rdoTx.CheckedChanged += (s, e) => UpdateModeUI();
            rdoRx.CheckedChanged += (s, e) => UpdateModeUI();
            rdoEcho.CheckedChanged += (s, e) => UpdateModeUI();
            rdoReqResp.CheckedChanged += (s, e) => UpdateModeUI();
            grpMode.Controls.AddRange(new Control[] { rdoTx, rdoRx, rdoEcho, rdoReqResp });

            // === TX Settings ===
            grpTxSettings = new GroupBox { Text = "TX 설정", Location = new Point(10, 60), Size = new Size(650, 170) };

            lblDstMac = new Label { Text = "Dst MAC:", Location = new Point(10, 22), AutoSize = true };
            txtDstMac = new TextBox { Text = "FF:FF:FF:FF:FF:FF", Location = new Point(80, 19), Width = 130 };

            lblDstIp = new Label { Text = "Dst IP:", Location = new Point(220, 22), AutoSize = true };
            txtDstIp = new TextBox { Text = "192.168.0.1", Location = new Point(275, 19), Width = 110 };

            lblDstPort = new Label { Text = "Dst Port:", Location = new Point(395, 22), AutoSize = true };
            nudDstPort = new NumericUpDown { Location = new Point(460, 19), Width = 80, Minimum = 1, Maximum = 65535, Value = 5000 };

            lblSrcIp = new Label { Text = "Src IP:", Location = new Point(10, 52), AutoSize = true };
            txtSrcIp = new TextBox { Text = "192.168.0.2", Location = new Point(80, 49), Width = 110 };

            lblSrcPort = new Label { Text = "Src Port:", Location = new Point(220, 52), AutoSize = true };
            nudSrcPort = new NumericUpDown { Location = new Point(290, 49), Width = 80, Minimum = 1, Maximum = 65535, Value = 4000 };

            lblPayloadSize = new Label { Text = "Payload (B):", Location = new Point(385, 52), AutoSize = true };
            nudPayloadSize = new NumericUpDown { Location = new Point(465, 49), Width = 80, Minimum = 1, Maximum = 1400, Value = 64 };

            lblSendRate = new Label { Text = "Rate (PPS, 0=Max):", Location = new Point(10, 82), AutoSize = true };
            nudSendRate = new NumericUpDown { Location = new Point(140, 79), Width = 100, Minimum = 0, Maximum = 10000000, Value = 0 };

            lblPayloadText = new Label { Text = "명령어:", Location = new Point(10, 112), AutoSize = true };
            txtPayloadText = new TextBox { Text = "", Location = new Point(65, 109), Width = 555, PlaceholderText = "비우면 바이너리, 입력하면 텍스트 (예: version.all#)" };

            lblTimeout = new Label { Text = "Timeout (ms):", Location = new Point(10, 82), AutoSize = true, Visible = false };
            nudTimeout = new NumericUpDown { Location = new Point(110, 79), Width = 100, Minimum = 100, Maximum = 30000, Value = 1000, Visible = false };

            lblRepeatCount = new Label { Text = "반복 (0=무한):", Location = new Point(230, 82), AutoSize = true, Visible = false };
            nudRepeatCount = new NumericUpDown { Location = new Point(330, 79), Width = 100, Minimum = 0, Maximum = 1000000, Value = 0, Visible = false };

            lblWindowSize = new Label { Text = "Window:", Location = new Point(450, 82), AutoSize = true, Visible = false };
            nudWindowSize = new NumericUpDown { Location = new Point(510, 79), Width = 60, Minimum = 1, Maximum = 256, Value = 1, Visible = false };

            chkWarmup = new CheckBox { Text = "Warmup", Location = new Point(580, 81), AutoSize = true, Checked = true, Visible = false };

            grpTxSettings.Controls.AddRange(new Control[] {
                lblDstMac, txtDstMac, lblDstIp, txtDstIp, lblDstPort, nudDstPort,
                lblSrcIp, txtSrcIp, lblSrcPort, nudSrcPort,
                lblPayloadSize, nudPayloadSize, lblSendRate, nudSendRate,
                lblPayloadText, txtPayloadText,
                lblTimeout, nudTimeout,
                lblRepeatCount, nudRepeatCount,
                lblWindowSize, nudWindowSize,
                chkWarmup
            });

            // === RX Settings ===
            grpRxSettings = new GroupBox { Text = "RX 필터", Location = new Point(10, 60), Size = new Size(650, 50), Visible = false };

            lblFilterIp = new Label { Text = "필터 IP:", Location = new Point(10, 20), AutoSize = true };
            txtFilterIp = new TextBox { Text = "", Location = new Point(70, 17), Width = 120, PlaceholderText = "비우면 전체 수신" };

            lblFilterPort = new Label { Text = "필터 Port:", Location = new Point(210, 20), AutoSize = true };
            nudFilterPort = new NumericUpDown { Location = new Point(280, 17), Width = 80, Minimum = 0, Maximum = 65535, Value = 0 };

            grpRxSettings.Controls.AddRange(new Control[] { lblFilterIp, txtFilterIp, lblFilterPort, nudFilterPort });

            // === Control ===
            int controlY = 235;
            btnStart = new Button
            {
                Text = "▶ Start", Location = new Point(10, controlY), Size = new Size(100, 30),
                BackColor = Color.LightGreen, Font = new Font(this.Font.FontFamily, 9, FontStyle.Bold)
            };
            btnStart.Click += BtnStart_Click;

            btnStop = new Button
            {
                Text = "■ Stop", Location = new Point(120, controlY), Size = new Size(100, 30),
                BackColor = Color.LightCoral, Enabled = false
            };
            btnStop.Click += BtnStop_Click;

            lblLiveStats = new Label
            {
                Text = "TX: 0 PPS (0 Mbps) | RX: 0 PPS (0 Mbps) | Err: 0 | Drop: 0",
                Location = new Point(240, controlY + 7), AutoSize = true,
                Font = new Font("Consolas", 9, FontStyle.Bold)
            };

            // === Log ===
            int logY = controlY + 40;
            btnClearLog = new Button { Text = "Clear", Location = new Point(600, logY), Size = new Size(60, 22) };
            btnClearLog.Click += (s, e) => rtbLog.Clear();

            rtbLog = new RichTextBox
            {
                Location = new Point(10, logY + 25), Size = new Size(650, 250),
                ReadOnly = true, BackColor = Color.Black, ForeColor = Color.Lime,
                Font = new Font("Consolas", 9)
            };

            this.Controls.AddRange(new Control[] {
                grpMode, grpTxSettings, grpRxSettings,
                btnStart, btnStop, lblLiveStats,
                btnClearLog, rtbLog
            });

            // UI Timer
            _uiTimer = new System.Windows.Forms.Timer { Interval = 200 };
            _uiTimer.Tick += UiTimer_Tick;
        }

        private void UpdateModeUI()
        {
            grpTxSettings.Visible = rdoTx.Checked || rdoReqResp.Checked;
            grpRxSettings.Visible = rdoRx.Checked;

            // Req/Resp: show timeout + repeat count, hide rate
            bool isReqResp = rdoReqResp.Checked;
            lblTimeout.Visible = isReqResp;
            nudTimeout.Visible = isReqResp;
            lblRepeatCount.Visible = isReqResp;
            nudRepeatCount.Visible = isReqResp;
            lblWindowSize.Visible = isReqResp;
            nudWindowSize.Visible = isReqResp;
            chkWarmup.Visible = isReqResp;
            lblSendRate.Visible = !isReqResp;
            nudSendRate.Visible = !isReqResp;

            // PayloadText는 항상 Row 4 (Y=112) — TX/ReqResp 공통
            lblPayloadText.Location = new Point(10, 112);
            txtPayloadText.Location = new Point(65, 109);
            txtPayloadText.Width = 555;
        }

        private void BtnStart_Click(object? sender, EventArgs e)
        {
            if (HwManager.Instance.State != HwState.Ready)
            {
                MessageBox.Show("DPDK가 초기화되지 않았습니다.\nSettings 탭에서 먼저 초기화하세요.",
                    "오류", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            _perfCounter.Reset();
            _perfCounter.Start();

            if (rdoTx.Checked)
            {
                try
                {
                    string payloadText = txtPayloadText.Text.Trim();
                    int payloadSize = (int)nudPayloadSize.Value;
                    if (!string.IsNullOrEmpty(payloadText))
                        payloadSize = Math.Max(payloadSize, payloadText.Length);

                    var config = new TxConfig
                    {
                        DstMac = NetUtils.ParseMac(txtDstMac.Text),
                        DstIp = txtDstIp.Text,
                        DstPort = (ushort)nudDstPort.Value,
                        SrcIp = txtSrcIp.Text,
                        SrcPort = (ushort)nudSrcPort.Value,
                        PayloadSize = payloadSize,
                        TargetPps = (int)nudSendRate.Value,
                        PayloadText = string.IsNullOrEmpty(payloadText) ? null : payloadText
                    };
                    _pktLogger = new PacketLogger("dpdk_tx");
                    _txEngine = new HwUdpTxEngine(HwManager.Instance, _perfCounter) { Logger = _pktLogger };
                    _txEngine.Start(config);
                    AppendLog("TX 엔진 시작", Color.LightGreen);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"설정 오류: {ex.Message}", "오류", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }
            else if (rdoRx.Checked)
            {
                _pktLogger = new PacketLogger("dpdk_rx");
                _rxEngine = new HwUdpRxEngine(HwManager.Instance, _perfCounter)
                {
                    FilterPort = (ushort)nudFilterPort.Value,
                    FilterIp = string.IsNullOrWhiteSpace(txtFilterIp.Text) ? null : txtFilterIp.Text,
                    Logger = _pktLogger
                };
                _rxEngine.Start();
                AppendLog("RX 엔진 시작", Color.Cyan);
            }
            else if (rdoReqResp.Checked)
            {
                try
                {
                    string payloadTextRR = txtPayloadText.Text.Trim();
                    int payloadSizeRR = (int)nudPayloadSize.Value;
                    if (!string.IsNullOrEmpty(payloadTextRR))
                        payloadSizeRR = payloadTextRR.Length; // 텍스트 명령: 정확한 길이만 전송 (zero 패딩 없음)

                    var rrConfig = new ReqRespConfig
                    {
                        DstMac = NetUtils.ParseMac(txtDstMac.Text),
                        DstIp = txtDstIp.Text,
                        DstPort = (ushort)nudDstPort.Value,
                        SrcIp = txtSrcIp.Text,
                        SrcPort = (ushort)nudSrcPort.Value,
                        PayloadSize = payloadSizeRR,
                        PayloadText = string.IsNullOrEmpty(payloadTextRR) ? null : payloadTextRR,
                        TimeoutMs = (int)nudTimeout.Value,
                        RepeatCount = (int)nudRepeatCount.Value,
                        WindowSize = (int)nudWindowSize.Value,
                        EnableWarmup = chkWarmup.Checked
                    };
                    _pktLogger = new PacketLogger("dpdk_reqresp");
                    _reqRespEngine = new HwUdpReqRespEngine(HwManager.Instance, _perfCounter) { Logger = _pktLogger };
                    _reqRespEngine.Start(rrConfig);
                    AppendLog("Req/Resp 엔진 시작", Color.LightBlue);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"설정 오류: {ex.Message}", "오류", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }
            else // Echo
            {
                _pktLogger = new PacketLogger("dpdk_echo");
                _echoEngine = new HwEchoEngine(HwManager.Instance, _perfCounter) { Logger = _pktLogger };
                _echoEngine.Start();
                AppendLog("Echo 엔진 시작", Color.Yellow);
            }

            _engineRunning = true;
            btnStart.Enabled = false;
            btnStop.Enabled = true;
            grpMode.Enabled = false;
            _uiTimer.Start();
        }

        /// <summary>모든 엔진 중지 (앱 종료 시 MainForm에서 호출)</summary>
        public void StopAllEngines()
        {
            _lastRttStats = _reqRespEngine?.Stats;
            _txEngine?.Stop();
            _rxEngine?.Stop();
            _echoEngine?.Stop();
            _reqRespEngine?.Stop();
            _pktLogger?.Dispose();
            _txEngine = null;
            _rxEngine = null;
            _echoEngine = null;
            _reqRespEngine = null;
            _pktLogger = null;
            _engineRunning = false;
            _uiTimer.Stop();
        }

        private void BtnStop_Click(object? sender, EventArgs e)
        {
            StopAllEngines();
            btnStart.Enabled = true;
            btnStop.Enabled = false;
            grpMode.Enabled = true;
            AppendLog("엔진 중지", Color.Orange);
        }

        private void UiTimer_Tick(object? sender, EventArgs e)
        {
            var snap = _perfCounter.TakeSnapshot();

            lblLiveStats.Text =
                $"TX: {FormatPps(snap.TxPps)} ({snap.TxMbps:F1} Mbps) | " +
                $"RX: {FormatPps(snap.RxPps)} ({snap.RxMbps:F1} Mbps) | " +
                $"Err: {snap.Errors} | Drop: {snap.Dropped}";

            // Show TX engine error
            if (_txEngine?.LastError != null)
            {
                AppendLog($"[오류] {_txEngine.LastError}", Color.Red);
                _txEngine.LastError = null;
            }

            // Drain TX engine response queue (command/response mode)
            if (_txEngine != null)
            {
                int logCount = 0;
                while (_txEngine.ResponseQueue.TryDequeue(out var pkt) && logCount < 50)
                {
                    string msg = $"[RX] {pkt.SrcIp}:{pkt.SrcPort} → {pkt.DstIp}:{pkt.DstPort} [{pkt.DataLen}B]";
                    if (!string.IsNullOrEmpty(pkt.PayloadText))
                        msg += $" {pkt.PayloadText}";
                    AppendLog(msg, Color.Cyan);
                    logCount++;
                }
            }

            // Drain RX packet queue for log
            if (_rxEngine != null)
            {
                int logCount = 0;
                while (_rxEngine.PacketQueue.TryDequeue(out var pkt) && logCount < 50)
                {
                    string rxMsg = $"{pkt.SrcIp}:{pkt.SrcPort} → {pkt.DstIp}:{pkt.DstPort} [{pkt.DataLen}B]";
                    if (!string.IsNullOrEmpty(pkt.PayloadText))
                        rxMsg += $" {pkt.PayloadText}";
                    AppendLog(rxMsg, Color.Cyan);
                    logCount++;
                }
            }

            // Drain Req/Resp result queue
            if (_reqRespEngine != null)
            {
                int logCount = 0;
                while (_reqRespEngine.ResultQueue.TryDequeue(out var result) && logCount < 50)
                {
                    if (!result.Success)
                    {
                        AppendLog($"[#{result.SeqNumber}] TIMEOUT", Color.Red);
                        logCount++;
                    }
                }

                var rtt = _reqRespEngine.Stats;
                lblLiveStats.Text =
                    $"Sent: {rtt.Sent} | Recv: {rtt.Received} | Timeout: {rtt.Timeouts} | Other: {rtt.RxOther} | " +
                    $"RTT min={rtt.MinRtt:F1}ms avg={rtt.AvgRtt:F1}ms max={rtt.MaxRtt:F1}ms";

                // Drain diagnostic messages
                while (_reqRespEngine.DiagQueue.TryDequeue(out var diagMsg))
                    AppendLog(diagMsg, Color.Yellow);

                if (_reqRespEngine.LastError != null)
                {
                    AppendLog($"[오류] {_reqRespEngine.LastError}", Color.Red);
                    _reqRespEngine.LastError = null;
                }

                // 반복 완료 시 자동 정지
                if (_reqRespEngine.IsCompleted)
                {
                    AppendLog($"[완료] {rtt.Sent}회 반복 완료 (응답: {rtt.Received}, 타임아웃: {rtt.Timeouts})", Color.Yellow);
                    BtnStop_Click(null, EventArgs.Empty);
                    return;
                }
            }
        }

        private void AppendLog(string msg, Color color)
        {
            if (rtbLog.InvokeRequired)
            {
                rtbLog.Invoke(() => AppendLog(msg, color));
                return;
            }

            if (rtbLog.Lines.Length > 5000)
            {
                rtbLog.Clear();
                rtbLog.AppendText("[로그 초기화됨]\n");
            }

            rtbLog.SelectionStart = rtbLog.TextLength;
            rtbLog.SelectionColor = Color.Gray;
            rtbLog.AppendText($"[{DateTime.Now:HH:mm:ss.fff}] ");
            rtbLog.SelectionColor = color;
            rtbLog.AppendText($"{msg}\n");
            rtbLog.ScrollToCaret();
        }

        public void ApplySettings(AppSettings settings)
        {
            txtDstMac.Text = settings.DstMac;
            txtDstIp.Text = settings.DstIp;
            nudDstPort.Value = Math.Clamp(settings.DstPort, (int)nudDstPort.Minimum, (int)nudDstPort.Maximum);
            txtSrcIp.Text = settings.SrcIp;
            nudSrcPort.Value = Math.Clamp(settings.SrcPort, (int)nudSrcPort.Minimum, (int)nudSrcPort.Maximum);
            nudPayloadSize.Value = Math.Clamp(settings.PayloadSize, (int)nudPayloadSize.Minimum, (int)nudPayloadSize.Maximum);
            nudSendRate.Value = Math.Clamp(settings.SendRate, (int)nudSendRate.Minimum, (int)nudSendRate.Maximum);
            txtPayloadText.Text = settings.PayloadText;
            txtFilterIp.Text = settings.FilterIp;
            nudFilterPort.Value = Math.Clamp(settings.FilterPort, (int)nudFilterPort.Minimum, (int)nudFilterPort.Maximum);
            nudTimeout.Value = Math.Clamp(settings.ResponseTimeoutMs, (int)nudTimeout.Minimum, (int)nudTimeout.Maximum);
        }

        public void CollectSettings(AppSettings settings)
        {
            settings.DstMac = txtDstMac.Text;
            settings.DstIp = txtDstIp.Text;
            settings.DstPort = (int)nudDstPort.Value;
            settings.SrcIp = txtSrcIp.Text;
            settings.SrcPort = (int)nudSrcPort.Value;
            settings.PayloadSize = (int)nudPayloadSize.Value;
            settings.SendRate = (int)nudSendRate.Value;
            settings.PayloadText = txtPayloadText.Text;
            settings.FilterIp = txtFilterIp.Text;
            settings.FilterPort = (int)nudFilterPort.Value;
            settings.ResponseTimeoutMs = (int)nudTimeout.Value;
        }

        private static string FormatPps(double pps)
        {
            if (pps >= 1_000_000) return $"{pps / 1_000_000:F2}M PPS";
            if (pps >= 1_000) return $"{pps / 1_000:F1}K PPS";
            return $"{pps:F0} PPS";
        }
    }
}
