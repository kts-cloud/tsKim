using HwNet.Logging;
using HwNet.Models;
using HwNet.Stats;
using DpdkTestTool.Core;
using DpdkTestTool.Engine;

namespace DpdkTestTool.UI
{
    public class SocketUdpTab : UserControl
    {
        // Mode selection
        private GroupBox grpMode;
        private RadioButton rdoTx, rdoRx, rdoEcho, rdoServer, rdoReqResp;

        // TX Settings
        private GroupBox grpTxSettings;
        private Label lblDstIp, lblDstPort, lblSrcPort, lblPayloadSize, lblSendRate, lblPayloadText, lblTimeout, lblRepeatCount;
        private TextBox txtDstIp, txtPayloadText;
        private NumericUpDown nudDstPort, nudSrcPort, nudPayloadSize, nudSendRate, nudTimeout, nudRepeatCount;

        // RX Settings
        private GroupBox grpRxSettings;
        private Label lblListenPort, lblFilterIp;
        private TextBox txtFilterIp;
        private NumericUpDown nudListenPort;

        // Server Settings
        private GroupBox grpServerSettings;
        private Label lblSvrPort, lblAutoResp;
        private NumericUpDown nudSvrPort;
        private TextBox txtAutoResp;
        private TextBox txtManualSend;
        private Button btnManualSend;

        // Control
        private Button btnStart, btnStop;
        private Label lblLiveStats;

        // Log
        private RichTextBox rtbLog;
        private Button btnClearLog;

        // Engines
        private readonly PerformanceCounter _perfCounter = new();
        private SocketUdpTxEngine? _txEngine;
        private SocketUdpRxEngine? _rxEngine;
        private SocketEchoEngine? _echoEngine;
        private SocketUdpServerEngine? _serverEngine;
        private SocketUdpReqRespEngine? _reqRespEngine;
        private PacketLogger? _pktLogger;
        private System.Windows.Forms.Timer _uiTimer = null!;
        private bool _engineRunning;

        private RttStats? _lastRttStats;

        public PerformanceCounter PerfCounter => _perfCounter;
        public RttStats? CurrentRttStats => _reqRespEngine?.Stats ?? _lastRttStats;

        public SocketUdpTab()
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
            rdoServer = new RadioButton { Text = "수신/응답", Location = new Point(380, 20), AutoSize = true };
            rdoReqResp = new RadioButton { Text = "Req/Resp", Location = new Point(490, 20), AutoSize = true };
            rdoTx.CheckedChanged += (s, e) => UpdateModeUI();
            rdoRx.CheckedChanged += (s, e) => UpdateModeUI();
            rdoEcho.CheckedChanged += (s, e) => UpdateModeUI();
            rdoServer.CheckedChanged += (s, e) => UpdateModeUI();
            rdoReqResp.CheckedChanged += (s, e) => UpdateModeUI();
            grpMode.Controls.AddRange(new Control[] { rdoTx, rdoRx, rdoEcho, rdoServer, rdoReqResp });

            // === TX Settings ===
            grpTxSettings = new GroupBox { Text = "TX 설정 (일반 소켓)", Location = new Point(10, 60), Size = new Size(650, 110) };

            lblDstIp = new Label { Text = "Dst IP:", Location = new Point(10, 25), AutoSize = true };
            txtDstIp = new TextBox { Text = "192.168.0.1", Location = new Point(70, 22), Width = 120 };

            lblDstPort = new Label { Text = "Dst Port:", Location = new Point(200, 25), AutoSize = true };
            nudDstPort = new NumericUpDown { Location = new Point(265, 22), Width = 80, Minimum = 1, Maximum = 65535, Value = 5000 };

            lblSrcPort = new Label { Text = "Src Port:", Location = new Point(360, 25), AutoSize = true };
            nudSrcPort = new NumericUpDown { Location = new Point(425, 22), Width = 80, Minimum = 1, Maximum = 65535, Value = 4000 };

            lblPayloadSize = new Label { Text = "Payload (B):", Location = new Point(10, 55), AutoSize = true };
            nudPayloadSize = new NumericUpDown { Location = new Point(90, 52), Width = 80, Minimum = 1, Maximum = 65000, Value = 64 };

            lblSendRate = new Label { Text = "Rate (PPS, 0=Max):", Location = new Point(185, 55), AutoSize = true };
            nudSendRate = new NumericUpDown { Location = new Point(315, 52), Width = 100, Minimum = 0, Maximum = 10000000, Value = 0 };

            lblPayloadText = new Label { Text = "명령어:", Location = new Point(10, 85), AutoSize = true };
            txtPayloadText = new TextBox { Text = "", Location = new Point(65, 82), Width = 555, PlaceholderText = "비우면 바이너리, 입력하면 텍스트 (예: version.all#)" };

            lblTimeout = new Label { Text = "Timeout (ms):", Location = new Point(185, 55), AutoSize = true, Visible = false };
            nudTimeout = new NumericUpDown { Location = new Point(315, 52), Width = 100, Minimum = 100, Maximum = 30000, Value = 1000, Visible = false };

            lblRepeatCount = new Label { Text = "반복 (0=무한):", Location = new Point(430, 55), AutoSize = true, Visible = false };
            nudRepeatCount = new NumericUpDown { Location = new Point(530, 52), Width = 90, Minimum = 0, Maximum = 1000000, Value = 0, Visible = false };

            grpTxSettings.Controls.AddRange(new Control[] {
                lblDstIp, txtDstIp, lblDstPort, nudDstPort, lblSrcPort, nudSrcPort,
                lblPayloadSize, nudPayloadSize, lblSendRate, nudSendRate,
                lblPayloadText, txtPayloadText,
                lblTimeout, nudTimeout,
                lblRepeatCount, nudRepeatCount
            });

            // === RX Settings ===
            grpRxSettings = new GroupBox { Text = "RX 설정 (일반 소켓)", Location = new Point(10, 60), Size = new Size(650, 55), Visible = false };

            lblListenPort = new Label { Text = "Listen Port:", Location = new Point(10, 22), AutoSize = true };
            nudListenPort = new NumericUpDown { Location = new Point(85, 19), Width = 80, Minimum = 1, Maximum = 65535, Value = 5000 };

            lblFilterIp = new Label { Text = "필터 IP:", Location = new Point(185, 22), AutoSize = true };
            txtFilterIp = new TextBox { Text = "", Location = new Point(245, 19), Width = 120, PlaceholderText = "비우면 전체 수신" };

            grpRxSettings.Controls.AddRange(new Control[] { lblListenPort, nudListenPort, lblFilterIp, txtFilterIp });

            // === Server Settings ===
            grpServerSettings = new GroupBox { Text = "수신/응답 설정", Location = new Point(10, 60), Size = new Size(650, 110), Visible = false };

            lblSvrPort = new Label { Text = "Listen Port:", Location = new Point(10, 25), AutoSize = true };
            nudSvrPort = new NumericUpDown { Location = new Point(85, 22), Width = 80, Minimum = 1, Maximum = 65535, Value = 8001 };

            lblAutoResp = new Label { Text = "자동 응답:", Location = new Point(185, 25), AutoSize = true };
            txtAutoResp = new TextBox { Text = "", Location = new Point(255, 22), Width = 365, PlaceholderText = "비우면 수동 응답, 입력하면 자동 응답" };

            var lblManual = new Label { Text = "수동 전송:", Location = new Point(10, 58), AutoSize = true };
            txtManualSend = new TextBox { Text = "", Location = new Point(85, 55), Width = 445, PlaceholderText = "수신 후 마지막 발신자에게 전송할 텍스트" };
            txtManualSend.KeyDown += (s, e) => { if (e.KeyCode == Keys.Enter) { BtnManualSend_Click(s, e); e.SuppressKeyPress = true; } };
            btnManualSend = new Button { Text = "전송", Location = new Point(540, 53), Size = new Size(80, 28), Enabled = false };
            btnManualSend.Click += BtnManualSend_Click;

            grpServerSettings.Controls.AddRange(new Control[] {
                lblSvrPort, nudSvrPort, lblAutoResp, txtAutoResp,
                lblManual, txtManualSend, btnManualSend
            });

            // === Control ===
            int controlY = 175;
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
                Text = "TX: 0 PPS (0 Mbps) | RX: 0 PPS (0 Mbps) | Err: 0",
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
                grpMode, grpTxSettings, grpRxSettings, grpServerSettings,
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
            grpRxSettings.Visible = rdoRx.Checked || rdoEcho.Checked;
            grpServerSettings.Visible = rdoServer.Checked;

            // Req/Resp: Rate 숨김, Timeout + 반복횟수 표시
            bool isReqResp = rdoReqResp.Checked;
            lblTimeout.Visible = isReqResp;
            nudTimeout.Visible = isReqResp;
            lblRepeatCount.Visible = isReqResp;
            nudRepeatCount.Visible = isReqResp;
            lblSendRate.Visible = !isReqResp;
            nudSendRate.Visible = !isReqResp;
        }

        private void BtnStart_Click(object? sender, EventArgs e)
        {
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

                    _pktLogger = new PacketLogger("socket_tx");
                    _txEngine = new SocketUdpTxEngine(_perfCounter)
                    {
                        DstIp = txtDstIp.Text,
                        DstPort = (ushort)nudDstPort.Value,
                        SrcPort = (ushort)nudSrcPort.Value,
                        PayloadSize = payloadSize,
                        TargetPps = (int)nudSendRate.Value,
                        PayloadText = string.IsNullOrEmpty(payloadText) ? null : payloadText,
                        Logger = _pktLogger
                    };
                    _txEngine.Start();
                    AppendLog("Socket TX 엔진 시작", Color.LightGreen);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"설정 오류: {ex.Message}", "오류", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }
            else if (rdoRx.Checked)
            {
                _pktLogger = new PacketLogger("socket_rx");
                _rxEngine = new SocketUdpRxEngine(_perfCounter)
                {
                    ListenPort = (ushort)nudListenPort.Value,
                    FilterIp = string.IsNullOrWhiteSpace(txtFilterIp.Text) ? null : txtFilterIp.Text,
                    Logger = _pktLogger
                };
                _rxEngine.Start();
                AppendLog("Socket RX 엔진 시작", Color.Cyan);
            }
            else if (rdoReqResp.Checked)
            {
                try
                {
                    string payloadTextRR = txtPayloadText.Text.Trim();
                    int payloadSizeRR = (int)nudPayloadSize.Value;
                    if (!string.IsNullOrEmpty(payloadTextRR))
                        payloadSizeRR = payloadTextRR.Length;

                    _pktLogger = new PacketLogger("socket_reqresp");
                    _reqRespEngine = new SocketUdpReqRespEngine(_perfCounter)
                    {
                        DstIp = txtDstIp.Text,
                        DstPort = (ushort)nudDstPort.Value,
                        SrcPort = (ushort)nudSrcPort.Value,
                        PayloadSize = payloadSizeRR,
                        PayloadText = string.IsNullOrEmpty(payloadTextRR) ? null : payloadTextRR,
                        TimeoutMs = (int)nudTimeout.Value,
                        RepeatCount = (int)nudRepeatCount.Value,
                        Logger = _pktLogger
                    };
                    _reqRespEngine.Start();
                    AppendLog("Socket Req/Resp 엔진 시작", Color.LightBlue);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"설정 오류: {ex.Message}", "오류", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }
            else if (rdoEcho.Checked)
            {
                _pktLogger = new PacketLogger("socket_echo");
                _echoEngine = new SocketEchoEngine(_perfCounter)
                {
                    ListenPort = (ushort)nudListenPort.Value,
                    Logger = _pktLogger
                };
                _echoEngine.Start();
                AppendLog("Socket Echo 엔진 시작", Color.Yellow);
            }
            else // Server
            {
                string autoResp = txtAutoResp.Text.Trim();
                _pktLogger = new PacketLogger("socket_server");
                _serverEngine = new SocketUdpServerEngine(_perfCounter)
                {
                    ListenPort = (ushort)nudSvrPort.Value,
                    AutoResponse = string.IsNullOrEmpty(autoResp) ? null : autoResp,
                    Logger = _pktLogger
                };
                _serverEngine.Start();
                btnManualSend.Enabled = true;
                AppendLog($"수신/응답 서버 시작 (Port: {nudSvrPort.Value}" +
                    (string.IsNullOrEmpty(autoResp) ? ", 수동 응답)" : $", 자동 응답: {autoResp})"), Color.Yellow);
            }

            _engineRunning = true;
            btnStart.Enabled = false;
            btnStop.Enabled = true;
            grpMode.Enabled = false;
            _uiTimer.Start();
        }

        private void BtnStop_Click(object? sender, EventArgs e)
        {
            _lastRttStats = _reqRespEngine?.Stats;
            _txEngine?.Stop();
            _rxEngine?.Stop();
            _echoEngine?.Stop();
            _serverEngine?.Stop();
            _reqRespEngine?.Stop();
            _pktLogger?.Dispose();
            _txEngine = null;
            _rxEngine = null;
            _echoEngine = null;
            _serverEngine = null;
            _reqRespEngine = null;
            _pktLogger = null;

            _engineRunning = false;
            _uiTimer.Stop();
            btnStart.Enabled = true;
            btnStop.Enabled = false;
            btnManualSend.Enabled = false;
            grpMode.Enabled = true;
            AppendLog("엔진 중지", Color.Orange);
        }

        private void UiTimer_Tick(object? sender, EventArgs e)
        {
            var snap = _perfCounter.TakeSnapshot();

            lblLiveStats.Text =
                $"TX: {FormatPps(snap.TxPps)} ({snap.TxMbps:F1} Mbps) | " +
                $"RX: {FormatPps(snap.RxPps)} ({snap.RxMbps:F1} Mbps) | " +
                $"Err: {snap.Errors}";

            // TX engine error
            if (_txEngine?.LastError != null)
            {
                AppendLog($"[오류] {_txEngine.LastError}", Color.Red);
                _txEngine.LastError = null;
            }

            // Drain TX response queue
            if (_txEngine != null)
            {
                int logCount = 0;
                while (_txEngine.ResponseQueue.TryDequeue(out var pkt) && logCount < 50)
                {
                    string msg = $"[RX] {pkt.SrcIp}:{pkt.SrcPort} [{pkt.DataLen}B]";
                    if (!string.IsNullOrEmpty(pkt.PayloadText))
                        msg += $" {pkt.PayloadText}";
                    AppendLog(msg, Color.Cyan);
                    logCount++;
                }
            }

            // Drain RX packet queue
            if (_rxEngine != null)
            {
                int logCount = 0;
                while (_rxEngine.PacketQueue.TryDequeue(out var pkt) && logCount < 50)
                {
                    string rxMsg = $"{pkt.SrcIp}:{pkt.SrcPort} [{pkt.DataLen}B]";
                    if (!string.IsNullOrEmpty(pkt.PayloadText))
                        rxMsg += $" {pkt.PayloadText}";
                    AppendLog(rxMsg, Color.Cyan);
                    logCount++;
                }
            }

            // Req/Resp engine
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
                    $"Sent: {rtt.Sent} | Recv: {rtt.Received} | Timeout: {rtt.Timeouts} | " +
                    $"RTT min={rtt.MinRtt:F1}ms avg={rtt.AvgRtt:F1}ms max={rtt.MaxRtt:F1}ms";

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

            // Server engine
            if (_serverEngine != null)
            {
                if (_serverEngine.LastError != null)
                {
                    AppendLog($"[오류] {_serverEngine.LastError}", Color.Red);
                    _serverEngine.LastError = null;
                }

                int logCount = 0;
                while (_serverEngine.PacketQueue.TryDequeue(out var pkt) && logCount < 50)
                {
                    string rxMsg = $"[RX] {pkt.SrcIp}:{pkt.SrcPort} [{pkt.DataLen}B]";
                    if (!string.IsNullOrEmpty(pkt.PayloadText))
                        rxMsg += $" {pkt.PayloadText}";
                    AppendLog(rxMsg, Color.Cyan);
                    logCount++;
                }
            }
        }

        private void BtnManualSend_Click(object? sender, EventArgs e)
        {
            string text = txtManualSend.Text.Trim();
            if (string.IsNullOrEmpty(text) || _serverEngine == null) return;
            _serverEngine.SendQueue.Enqueue(text);
            AppendLog($"[TX] → {text}", Color.LightGreen);
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

        private static string FormatPps(double pps)
        {
            if (pps >= 1_000_000) return $"{pps / 1_000_000:F2}M PPS";
            if (pps >= 1_000) return $"{pps / 1_000:F1}K PPS";
            return $"{pps:F0} PPS";
        }

        public void ApplySettings(AppSettings settings)
        {
            txtDstIp.Text = settings.DstIp;
            nudDstPort.Value = Math.Clamp(settings.DstPort, (int)nudDstPort.Minimum, (int)nudDstPort.Maximum);
            nudSrcPort.Value = Math.Clamp(settings.SrcPort, (int)nudSrcPort.Minimum, (int)nudSrcPort.Maximum);
            nudPayloadSize.Value = Math.Clamp(settings.PayloadSize, (int)nudPayloadSize.Minimum, (int)nudPayloadSize.Maximum);
            nudSendRate.Value = Math.Clamp(settings.SendRate, (int)nudSendRate.Minimum, (int)nudSendRate.Maximum);
            txtPayloadText.Text = settings.PayloadText;
            txtFilterIp.Text = settings.FilterIp;
        }
    }
}
