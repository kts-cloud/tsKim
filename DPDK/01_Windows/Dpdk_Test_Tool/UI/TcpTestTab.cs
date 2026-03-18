using DpdkTestTool.Engine;

namespace DpdkTestTool.UI
{
    public class TcpTestTab : UserControl
    {
        // Mode
        private GroupBox grpMode;
        private RadioButton rdoServer, rdoClient;

        // Server Panel
        private Panel pnlServer;
        private GroupBox grpServerSettings;
        private Label lblServerPort, lblServerMode;
        private NumericUpDown nudServerPort;
        private ComboBox cboServerMode;
        private Button btnServerStart, btnServerStop;
        private ListView lvClients;
        private RichTextBox rtbServerLog;

        // Client Panel
        private Panel pnlClient;
        private GroupBox grpClientSettings;
        private Label lblServerIp, lblClientPort, lblMessage;
        private TextBox txtServerIp, txtMessage;
        private NumericUpDown nudClientPort;
        private Button btnConnect, btnDisconnect, btnSend;
        private CheckBox chkAutoSend;
        private Label lblConnInfo;
        private RichTextBox rtbClientLog;

        // Engines
        private TcpServerEngine? _serverEngine;
        private TcpClientEngine? _clientEngine;
        private System.Windows.Forms.Timer _uiTimer = null!;
        private System.Windows.Forms.Timer? _autoSendTimer;

        public TcpTestTab()
        {
            InitializeUI();
        }

        private void InitializeUI()
        {
            this.Dock = DockStyle.Fill;

            // === Mode ===
            grpMode = new GroupBox { Text = "모드 선택", Location = new Point(10, 5), Size = new Size(650, 50) };
            rdoServer = new RadioButton { Text = "TCP Server", Location = new Point(20, 20), AutoSize = true, Checked = true };
            rdoClient = new RadioButton { Text = "TCP Client", Location = new Point(160, 20), AutoSize = true };
            rdoServer.CheckedChanged += (s, e) => UpdateModeUI();
            grpMode.Controls.AddRange(new Control[] { rdoServer, rdoClient });

            // === Server Panel ===
            pnlServer = new Panel { Location = new Point(0, 60), Size = new Size(670, 440) };

            grpServerSettings = new GroupBox { Text = "서버 설정", Location = new Point(10, 0), Size = new Size(650, 55) };
            lblServerPort = new Label { Text = "Listen Port:", Location = new Point(10, 22), AutoSize = true };
            nudServerPort = new NumericUpDown { Location = new Point(85, 19), Width = 80, Minimum = 1, Maximum = 65535, Value = 7000 };
            lblServerMode = new Label { Text = "모드:", Location = new Point(180, 22), AutoSize = true };
            cboServerMode = new ComboBox
            {
                Location = new Point(220, 19), Width = 100, DropDownStyle = ComboBoxStyle.DropDownList
            };
            cboServerMode.Items.AddRange(new object[] { "Echo", "Receive Only" });
            cboServerMode.SelectedIndex = 0;

            btnServerStart = new Button { Text = "▶ Start", Location = new Point(340, 17), Size = new Size(80, 28), BackColor = Color.LightGreen };
            btnServerStart.Click += BtnServerStart_Click;
            btnServerStop = new Button { Text = "■ Stop", Location = new Point(430, 17), Size = new Size(80, 28), BackColor = Color.LightCoral, Enabled = false };
            btnServerStop.Click += BtnServerStop_Click;

            grpServerSettings.Controls.AddRange(new Control[] {
                lblServerPort, nudServerPort, lblServerMode, cboServerMode, btnServerStart, btnServerStop
            });

            // Client list
            lvClients = new ListView
            {
                Location = new Point(10, 60), Size = new Size(650, 80),
                View = View.Details, FullRowSelect = true, GridLines = true
            };
            lvClients.Columns.Add("EndPoint", 180);
            lvClients.Columns.Add("연결 시간", 130);
            lvClients.Columns.Add("수신 (B)", 90);
            lvClients.Columns.Add("송신 (B)", 90);
            lvClients.Columns.Add("상태", 70);

            rtbServerLog = new RichTextBox
            {
                Location = new Point(10, 145), Size = new Size(650, 290),
                ReadOnly = true, BackColor = Color.Black, ForeColor = Color.Lime,
                Font = new Font("Consolas", 9)
            };

            pnlServer.Controls.AddRange(new Control[] { grpServerSettings, lvClients, rtbServerLog });

            // === Client Panel ===
            pnlClient = new Panel { Location = new Point(0, 60), Size = new Size(670, 440), Visible = false };

            grpClientSettings = new GroupBox { Text = "클라이언트 설정", Location = new Point(10, 0), Size = new Size(650, 90) };
            lblServerIp = new Label { Text = "Server IP:", Location = new Point(10, 22), AutoSize = true };
            txtServerIp = new TextBox { Text = "127.0.0.1", Location = new Point(80, 19), Width = 120 };
            lblClientPort = new Label { Text = "Port:", Location = new Point(210, 22), AutoSize = true };
            nudClientPort = new NumericUpDown { Location = new Point(245, 19), Width = 80, Minimum = 1, Maximum = 65535, Value = 7000 };

            btnConnect = new Button { Text = "연결", Location = new Point(340, 17), Size = new Size(80, 28), BackColor = Color.LightGreen };
            btnConnect.Click += BtnConnect_Click;
            btnDisconnect = new Button { Text = "연결해제", Location = new Point(430, 17), Size = new Size(80, 28), BackColor = Color.LightCoral, Enabled = false };
            btnDisconnect.Click += BtnDisconnect_Click;

            lblMessage = new Label { Text = "메시지:", Location = new Point(10, 55), AutoSize = true };
            txtMessage = new TextBox { Text = "Hello TCP!", Location = new Point(65, 52), Width = 200 };
            btnSend = new Button { Text = "Send", Location = new Point(275, 50), Size = new Size(60, 25), Enabled = false };
            btnSend.Click += BtnSend_Click;
            chkAutoSend = new CheckBox { Text = "자동 (200ms)", Location = new Point(345, 54), AutoSize = true, Enabled = false };
            chkAutoSend.CheckedChanged += ChkAutoSend_Changed;

            lblConnInfo = new Label
            {
                Text = "연결시간: - | RTT: - | 송신: 0B | 수신: 0B",
                Location = new Point(450, 55), AutoSize = true,
                Font = new Font("Consolas", 8)
            };

            grpClientSettings.Controls.AddRange(new Control[] {
                lblServerIp, txtServerIp, lblClientPort, nudClientPort,
                btnConnect, btnDisconnect,
                lblMessage, txtMessage, btnSend, chkAutoSend, lblConnInfo
            });

            rtbClientLog = new RichTextBox
            {
                Location = new Point(10, 95), Size = new Size(650, 340),
                ReadOnly = true, BackColor = Color.Black, ForeColor = Color.Lime,
                Font = new Font("Consolas", 9)
            };

            pnlClient.Controls.AddRange(new Control[] { grpClientSettings, rtbClientLog });

            this.Controls.AddRange(new Control[] { grpMode, pnlServer, pnlClient });

            // UI Timer
            _uiTimer = new System.Windows.Forms.Timer { Interval = 300 };
            _uiTimer.Tick += UiTimer_Tick;
            _uiTimer.Start();

            _autoSendTimer = new System.Windows.Forms.Timer { Interval = 200 };
            _autoSendTimer.Tick += async (s, e) => { if (_clientEngine != null) await _clientEngine.SendAsync(txtMessage.Text); };
        }

        private void UpdateModeUI()
        {
            pnlServer.Visible = rdoServer.Checked;
            pnlClient.Visible = rdoClient.Checked;
        }

        // === Server ===
        private async void BtnServerStart_Click(object? sender, EventArgs e)
        {
            _serverEngine = new TcpServerEngine
            {
                Port = (int)nudServerPort.Value,
                Mode = cboServerMode.SelectedIndex == 0 ? TcpServerMode.Echo : TcpServerMode.ReceiveOnly
            };
            btnServerStart.Enabled = false;
            btnServerStop.Enabled = true;
            await _serverEngine.StartAsync();
        }

        private void BtnServerStop_Click(object? sender, EventArgs e)
        {
            _serverEngine?.Stop();
            _serverEngine = null;
            btnServerStart.Enabled = true;
            btnServerStop.Enabled = false;
        }

        // === Client ===
        private async void BtnConnect_Click(object? sender, EventArgs e)
        {
            _clientEngine = new TcpClientEngine
            {
                ServerIp = txtServerIp.Text,
                ServerPort = (int)nudClientPort.Value
            };
            bool ok = await _clientEngine.ConnectAsync();
            if (ok)
            {
                btnConnect.Enabled = false;
                btnDisconnect.Enabled = true;
                btnSend.Enabled = true;
                chkAutoSend.Enabled = true;
            }
        }

        private void BtnDisconnect_Click(object? sender, EventArgs e)
        {
            chkAutoSend.Checked = false;
            _clientEngine?.Disconnect();
            _clientEngine = null;
            btnConnect.Enabled = true;
            btnDisconnect.Enabled = false;
            btnSend.Enabled = false;
            chkAutoSend.Enabled = false;
        }

        private async void BtnSend_Click(object? sender, EventArgs e)
        {
            if (_clientEngine != null)
                await _clientEngine.SendAsync(txtMessage.Text);
        }

        private void ChkAutoSend_Changed(object? sender, EventArgs e)
        {
            if (chkAutoSend.Checked) _autoSendTimer?.Start();
            else _autoSendTimer?.Stop();
        }

        // === UI Update ===
        private void UiTimer_Tick(object? sender, EventArgs e)
        {
            // Server log drain
            if (_serverEngine != null)
            {
                int count = 0;
                while (_serverEngine.LogQueue.TryDequeue(out var line) && count < 100)
                {
                    AppendLog(rtbServerLog, line, Color.Lime);
                    count++;
                }

                // Update client list
                lvClients.BeginUpdate();
                lvClients.Items.Clear();
                foreach (var kv in _serverEngine.Clients)
                {
                    var info = kv.Value;
                    var item = new ListViewItem(info.EndPoint);
                    item.SubItems.Add(info.ConnectedAt.ToString("HH:mm:ss"));
                    item.SubItems.Add(info.BytesReceived.ToString("N0"));
                    item.SubItems.Add(info.BytesSent.ToString("N0"));
                    item.SubItems.Add(info.IsConnected ? "연결됨" : "해제됨");
                    item.ForeColor = info.IsConnected ? Color.Green : Color.Gray;
                    lvClients.Items.Add(item);
                }
                lvClients.EndUpdate();
            }

            // Client log drain
            if (_clientEngine != null)
            {
                int count = 0;
                while (_clientEngine.LogQueue.TryDequeue(out var line) && count < 100)
                {
                    AppendLog(rtbClientLog, line, Color.Lime);
                    count++;
                }
                lblConnInfo.Text =
                    $"연결시간: {_clientEngine.ConnectTimeMs:F1}ms | RTT: {_clientEngine.LastRttMs:F2}ms | " +
                    $"송신: {_clientEngine.TotalBytesSent:N0}B | 수신: {_clientEngine.TotalBytesReceived:N0}B";
            }
        }

        private static void AppendLog(RichTextBox rtb, string msg, Color color)
        {
            if (rtb.Lines.Length > 5000)
            {
                rtb.Clear();
                rtb.AppendText("[로그 초기화됨]\n");
            }
            rtb.SelectionStart = rtb.TextLength;
            rtb.SelectionColor = color;
            rtb.AppendText(msg + "\n");
            rtb.ScrollToCaret();
        }
    }
}
