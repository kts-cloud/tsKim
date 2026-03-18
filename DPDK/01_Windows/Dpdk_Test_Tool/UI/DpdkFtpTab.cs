using HwNet;
using HwNet.Config;
using HwNet.Engine;
using DpdkTestTool.Core;

namespace DpdkTestTool.UI
{
    public class DpdkFtpTab : UserControl
    {
        // Connection
        private GroupBox grpConnection;
        private Label lblServerIp, lblPort, lblUsername, lblPassword;
        private TextBox txtServerIp, txtUsername, txtPassword;
        private NumericUpDown nudPort;
        private Label lblLocalIp, lblNetmask, lblGateway;
        private TextBox txtLocalIp, txtNetmask, txtGateway;
        private Button btnConnect, btnDisconnect;

        // Browser
        private GroupBox grpBrowser;
        private Label lblCurrentPath;
        private TextBox txtPath;
        private Button btnCd, btnRefresh;
        private ListView lvFiles;

        // Transfer
        private GroupBox grpTransfer;
        private Button btnDownload, btnUpload;
        private ProgressBar progressBar;

        // Log
        private RichTextBox rtbLog;
        private Button btnClearLog;

        // Engine
        private HwFtpEngine? _ftpEngine;
        private FtpConfig? _ftpConfig;
        private System.Windows.Forms.Timer _logTimer = null!;
        private bool _connected;

        public DpdkFtpTab()
        {
            InitializeUI();
        }

        private void InitializeUI()
        {
            this.Dock = DockStyle.Fill;

            // === Connection ===
            grpConnection = new GroupBox { Text = "FTP 서버 설정", Location = new Point(10, 5), Size = new Size(650, 110) };

            lblServerIp = new Label { Text = "Server IP:", Location = new Point(10, 22), AutoSize = true };
            txtServerIp = new TextBox { Text = "192.168.0.1", Location = new Point(80, 19), Width = 110 };

            lblPort = new Label { Text = "Port:", Location = new Point(200, 22), AutoSize = true };
            nudPort = new NumericUpDown { Location = new Point(240, 19), Width = 65, Minimum = 1, Maximum = 65535, Value = 21 };

            lblUsername = new Label { Text = "User:", Location = new Point(320, 22), AutoSize = true };
            txtUsername = new TextBox { Text = "anonymous", Location = new Point(360, 19), Width = 100 };

            lblPassword = new Label { Text = "Pass:", Location = new Point(470, 22), AutoSize = true };
            txtPassword = new TextBox { Text = "", Location = new Point(510, 19), Width = 100, PasswordChar = '*' };

            lblLocalIp = new Label { Text = "Local IP:", Location = new Point(10, 52), AutoSize = true };
            txtLocalIp = new TextBox { Text = "192.168.0.2", Location = new Point(80, 49), Width = 110 };

            lblNetmask = new Label { Text = "Netmask:", Location = new Point(200, 52), AutoSize = true };
            txtNetmask = new TextBox { Text = "255.255.255.0", Location = new Point(265, 49), Width = 110 };

            lblGateway = new Label { Text = "Gateway:", Location = new Point(385, 52), AutoSize = true };
            txtGateway = new TextBox { Text = "192.168.0.1", Location = new Point(450, 49), Width = 110 };

            btnConnect = new Button
            {
                Text = "Connect", Location = new Point(10, 78), Size = new Size(100, 26),
                BackColor = Color.LightGreen, Font = new Font(this.Font.FontFamily, 9, FontStyle.Bold)
            };
            btnConnect.Click += BtnConnect_Click;

            btnDisconnect = new Button
            {
                Text = "Disconnect", Location = new Point(120, 78), Size = new Size(100, 26),
                BackColor = Color.LightCoral, Enabled = false
            };
            btnDisconnect.Click += BtnDisconnect_Click;

            grpConnection.Controls.AddRange(new Control[] {
                lblServerIp, txtServerIp, lblPort, nudPort, lblUsername, txtUsername, lblPassword, txtPassword,
                lblLocalIp, txtLocalIp, lblNetmask, txtNetmask, lblGateway, txtGateway,
                btnConnect, btnDisconnect
            });

            // === Browser ===
            grpBrowser = new GroupBox { Text = "파일 탐색", Location = new Point(10, 120), Size = new Size(650, 230) };

            lblCurrentPath = new Label { Text = "현재 경로: /", Location = new Point(10, 20), AutoSize = true, Font = new Font(this.Font.FontFamily, 9, FontStyle.Bold) };

            txtPath = new TextBox { Text = "/", Location = new Point(10, 42), Width = 480 };
            btnCd = new Button { Text = "이동", Location = new Point(500, 40), Size = new Size(60, 24) };
            btnCd.Click += BtnCd_Click;

            btnRefresh = new Button { Text = "새로고침", Location = new Point(570, 40), Size = new Size(70, 24) };
            btnRefresh.Click += BtnRefresh_Click;

            lvFiles = new ListView
            {
                Location = new Point(10, 70), Size = new Size(630, 150),
                View = View.Details, FullRowSelect = true, GridLines = true,
                Font = new Font("Consolas", 9),
                BackColor = Color.FromArgb(30, 30, 30), ForeColor = Color.White,
                HeaderStyle = ColumnHeaderStyle.Nonclickable
            };
            lvFiles.Columns.Add("Name", 250, HorizontalAlignment.Left);
            lvFiles.Columns.Add("Size", 100, HorizontalAlignment.Right);
            lvFiles.Columns.Add("Date", 150, HorizontalAlignment.Left);
            lvFiles.Columns.Add("Type", 80, HorizontalAlignment.Center);
            lvFiles.DoubleClick += LvFiles_DoubleClick;

            grpBrowser.Controls.AddRange(new Control[] { lblCurrentPath, txtPath, btnCd, btnRefresh, lvFiles });

            // === Transfer ===
            grpTransfer = new GroupBox { Text = "파일 전송", Location = new Point(10, 355), Size = new Size(650, 50) };

            btnDownload = new Button { Text = "다운로드", Location = new Point(10, 18), Size = new Size(80, 26) };
            btnDownload.Click += BtnDownload_Click;

            btnUpload = new Button { Text = "업로드", Location = new Point(100, 18), Size = new Size(80, 26) };
            btnUpload.Click += BtnUpload_Click;

            progressBar = new ProgressBar { Location = new Point(200, 20), Size = new Size(430, 22), Visible = false };

            grpTransfer.Controls.AddRange(new Control[] { btnDownload, btnUpload, progressBar });

            // === Log ===
            btnClearLog = new Button { Text = "Clear", Location = new Point(600, 410), Size = new Size(60, 22) };
            btnClearLog.Click += (s, e) => rtbLog.Clear();

            rtbLog = new RichTextBox
            {
                Location = new Point(10, 435), Size = new Size(650, 150),
                ReadOnly = true, BackColor = Color.Black, ForeColor = Color.Lime,
                Font = new Font("Consolas", 9)
            };

            this.Controls.AddRange(new Control[] {
                grpConnection, grpBrowser, grpTransfer,
                btnClearLog, rtbLog
            });

            // Log Timer
            _logTimer = new System.Windows.Forms.Timer { Interval = 1000 };
            _logTimer.Tick += LogTimer_Tick;
            _logTimer.Start();
        }

        // === Event Handlers ===

        private async void BtnConnect_Click(object? sender, EventArgs e)
        {
            if (HwManager.Instance.State != HwState.Ready)
            {
                MessageBox.Show("DPDK가 초기화되지 않았습니다.\nSettings 탭에서 먼저 초기화하세요.",
                    "오류", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string serverIp = txtServerIp.Text.Trim();
            ushort port = (ushort)nudPort.Value;
            string user = txtUsername.Text.Trim();
            string pass = txtPassword.Text;
            string localIp = txtLocalIp.Text.Trim();
            string netmask = txtNetmask.Text.Trim();
            string gateway = txtGateway.Text.Trim();

            if (string.IsNullOrEmpty(serverIp) || string.IsNullOrEmpty(localIp))
            {
                MessageBox.Show("IP 주소를 입력하세요.", "오류", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            btnConnect.Enabled = false;
            AppendLog($"lwIP 초기화 중... (Local={localIp}, Mask={netmask}, GW={gateway})", Color.White);

            try
            {
                _ftpEngine = new HwFtpEngine(HwManager.Instance);
                _ftpConfig = new FtpConfig
                {
                    LocalIp = localIp,
                    Netmask = netmask,
                    Gateway = gateway,
                    ServerIp = serverIp,
                    ServerPort = port,
                    Username = user,
                    Password = pass
                };
                _ftpEngine.InitLwip(_ftpConfig);
                AppendLog("lwIP 초기화 완료", Color.LightGreen);

                AppendLog($"FTP 연결 중... {serverIp}:{port} (user={user})", Color.Cyan);
                bool ok = await _ftpEngine.ConnectAsync(serverIp, port, user, pass, 10000);

                if (ok)
                {
                    _connected = true;
                    btnConnect.Enabled = false;
                    btnDisconnect.Enabled = true;
                    SetConnectionInputsEnabled(false);
                    AppendLog("FTP 연결 성공!", Color.LightGreen);

                    // Get current directory
                    string? pwd = await _ftpEngine.PwdAsync();
                    if (pwd != null)
                    {
                        txtPath.Text = pwd;
                        lblCurrentPath.Text = $"현재 경로: {pwd}";
                    }

                    // List files
                    await RefreshFileListAsync();
                }
                else
                {
                    AppendLog("FTP 연결 실패", Color.Red);
                    _ftpEngine.StopLwip();
                    _ftpEngine = null;
                    btnConnect.Enabled = true;
                }
            }
            catch (Exception ex)
            {
                AppendLog($"연결 오류: {ex.Message}", Color.Red);
                try { _ftpEngine?.StopLwip(); } catch { }
                _ftpEngine = null;
                btnConnect.Enabled = true;
            }
        }

        private async void BtnDisconnect_Click(object? sender, EventArgs e)
        {
            btnDisconnect.Enabled = false;

            try
            {
                if (_ftpEngine != null)
                {
                    AppendLog("FTP 연결 해제 중...", Color.White);
                    await _ftpEngine.DisconnectAsync();
                    _ftpEngine.StopLwip();
                    _ftpEngine = null;
                    AppendLog("FTP 연결 해제 완료", Color.LightGreen);
                }
            }
            catch (Exception ex)
            {
                AppendLog($"연결 해제 오류: {ex.Message}", Color.Red);
                try { _ftpEngine?.StopLwip(); } catch { }
                _ftpEngine = null;
            }

            _connected = false;
            btnConnect.Enabled = true;
            btnDisconnect.Enabled = false;
            SetConnectionInputsEnabled(true);
            lvFiles.Items.Clear();
            lblCurrentPath.Text = "현재 경로: /";
            txtPath.Text = "/";
        }

        private async void BtnCd_Click(object? sender, EventArgs e)
        {
            if (!_connected || _ftpEngine == null) return;

            string path = txtPath.Text.Trim();
            if (string.IsNullOrEmpty(path)) return;

            try
            {
                AppendLog($"CWD {path}", Color.Cyan);
                bool ok = await _ftpEngine.CwdAsync(path);

                // 실패 시 재연결 후 재시도
                if (!ok)
                {
                    if (await TryReconnectAsync())
                    {
                        AppendLog($"CWD {path} (재시도)", Color.Cyan);
                        ok = await _ftpEngine.CwdAsync(path);
                    }
                }

                if (ok)
                {
                    string? pwd = await _ftpEngine.PwdAsync();
                    if (pwd != null)
                    {
                        txtPath.Text = pwd;
                        lblCurrentPath.Text = $"현재 경로: {pwd}";
                    }
                    await RefreshFileListAsync();
                }
                else
                {
                    AppendLog($"디렉토리 이동 실패: {path}", Color.Red);
                }
            }
            catch (Exception ex)
            {
                AppendLog($"CWD 오류: {ex.Message}", Color.Red);
            }
        }

        private async void BtnRefresh_Click(object? sender, EventArgs e)
        {
            if (!_connected || _ftpEngine == null) return;
            await RefreshFileListAsync();
        }

        private async void LvFiles_DoubleClick(object? sender, EventArgs e)
        {
            if (!_connected || _ftpEngine == null) return;
            if (lvFiles.SelectedItems.Count == 0) return;

            var item = lvFiles.SelectedItems[0];
            string type = item.SubItems[3].Text;
            string name = item.SubItems[0].Text;

            // Remove folder prefix icon
            if (name.StartsWith("[DIR] "))
                name = name.Substring(6);

            if (type == "DIR")
            {
                string currentPath = txtPath.Text.TrimEnd('/');
                string newPath = currentPath + "/" + name;
                txtPath.Text = newPath;
                BtnCd_Click(sender, e);
            }
        }

        private async void BtnDownload_Click(object? sender, EventArgs e)
        {
            if (!_connected || _ftpEngine == null) return;
            if (lvFiles.SelectedItems.Count == 0)
            {
                MessageBox.Show("다운로드할 파일을 선택하세요.", "알림", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var item = lvFiles.SelectedItems[0];
            string type = item.SubItems[3].Text;
            string name = item.SubItems[0].Text;

            if (type == "DIR")
            {
                MessageBox.Show("디렉토리는 다운로드할 수 없습니다.", "알림", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            using var sfd = new SaveFileDialog
            {
                FileName = name,
                Title = "파일 저장 위치 선택"
            };

            if (sfd.ShowDialog() != DialogResult.OK) return;

            try
            {
                string remotePath = txtPath.Text.TrimEnd('/') + "/" + name;
                AppendLog($"RETR {remotePath}", Color.Cyan);
                progressBar.Visible = true;
                progressBar.Style = ProgressBarStyle.Marquee;

                byte[]? data = await _ftpEngine.DownloadAsync(remotePath, 30000);

                // 실패 시 재연결 후 재시도
                if (data == null)
                {
                    if (await TryReconnectAsync())
                    {
                        AppendLog($"RETR {remotePath} (재시도)", Color.Cyan);
                        data = await _ftpEngine.DownloadAsync(remotePath, 30000);
                    }
                }

                progressBar.Visible = false;

                if (data != null)
                {
                    File.WriteAllBytes(sfd.FileName, data);
                    AppendLog($"다운로드 완료: {name} ({data.Length:N0} bytes) → {sfd.FileName}", Color.LightGreen);
                }
                else
                {
                    AppendLog($"다운로드 실패: {name}", Color.Red);
                }
            }
            catch (Exception ex)
            {
                progressBar.Visible = false;
                AppendLog($"다운로드 오류: {ex.Message}", Color.Red);
            }
        }

        private async void BtnUpload_Click(object? sender, EventArgs e)
        {
            if (!_connected || _ftpEngine == null) return;

            using var ofd = new OpenFileDialog
            {
                Title = "업로드할 파일 선택"
            };

            if (ofd.ShowDialog() != DialogResult.OK) return;

            try
            {
                string fileName = Path.GetFileName(ofd.FileName);
                byte[] data = File.ReadAllBytes(ofd.FileName);
                string remotePath = txtPath.Text.TrimEnd('/') + "/" + fileName;

                AppendLog($"STOR {remotePath} ({data.Length:N0} bytes)", Color.Cyan);
                progressBar.Visible = true;
                progressBar.Style = ProgressBarStyle.Marquee;

                bool ok = await _ftpEngine.UploadAsync(remotePath, data, 30000);

                // 실패 시 재연결 후 재시도
                if (!ok)
                {
                    if (await TryReconnectAsync())
                    {
                        AppendLog($"STOR {remotePath} (재시도)", Color.Cyan);
                        ok = await _ftpEngine.UploadAsync(remotePath, data, 30000);
                    }
                }

                progressBar.Visible = false;

                if (ok)
                {
                    AppendLog($"업로드 완료: {fileName} ({data.Length:N0} bytes)", Color.LightGreen);
                    await RefreshFileListAsync();
                }
                else
                {
                    AppendLog($"업로드 실패: {fileName}", Color.Red);
                }
            }
            catch (Exception ex)
            {
                progressBar.Visible = false;
                AppendLog($"업로드 오류: {ex.Message}", Color.Red);
            }
        }

        // === Helpers ===

        /// <summary>재연결 시도 (실패 시 false)</summary>
        private async Task<bool> TryReconnectAsync()
        {
            if (_ftpEngine == null || _ftpConfig == null) return false;

            AppendLog("연결 끊김 감지 — 재연결 시도...", Color.Yellow);
            bool ok = await _ftpEngine.ReconnectAsync(_ftpConfig);
            if (ok)
            {
                AppendLog("재연결 성공", Color.LightGreen);
                return true;
            }
            else
            {
                AppendLog("재연결 실패 — Disconnect 후 다시 Connect 하세요", Color.Red);
                _connected = false;
                btnConnect.Enabled = true;
                btnDisconnect.Enabled = false;
                SetConnectionInputsEnabled(true);
                return false;
            }
        }

        private async Task RefreshFileListAsync()
        {
            if (_ftpEngine == null) return;

            try
            {
                AppendLog("LIST", Color.Cyan);
                string? listing = await _ftpEngine.ListAsync(10000);

                // LIST 실패 시 재연결 후 재시도
                if (listing == null)
                {
                    if (await TryReconnectAsync())
                    {
                        listing = await _ftpEngine.ListAsync(10000);
                    }
                }

                lvFiles.Items.Clear();

                if (listing != null)
                {
                    var entries = ParseFtpListing(listing);
                    foreach (var entry in entries)
                    {
                        string displayName = entry.IsDirectory ? $"[DIR] {entry.Name}" : entry.Name;
                        string sizeText = entry.IsDirectory ? "" : FormatFileSize(entry.Size);
                        string typeText = entry.IsDirectory ? "DIR" : "FILE";

                        var item = new ListViewItem(new[] { displayName, sizeText, entry.Date, typeText });
                        item.ForeColor = entry.IsDirectory ? Color.Gold : Color.White;
                        item.UseItemStyleForSubItems = true;
                        lvFiles.Items.Add(item);
                    }

                    AppendLog($"목록 수신: {entries.Count}개 항목", Color.LightGreen);
                }
                else
                {
                    AppendLog("LIST 실패", Color.Red);
                }
            }
            catch (Exception ex)
            {
                AppendLog($"LIST 오류: {ex.Message}", Color.Red);
            }
        }

        private struct FtpEntry
        {
            public string Name;
            public long Size;
            public string Date;
            public bool IsDirectory;
        }

        private List<FtpEntry> ParseFtpListing(string listing)
        {
            var entries = new List<FtpEntry>();
            var lines = listing.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;

                // Unix format: "drwxr-xr-x  2 user group  4096 Mar 01 12:00 dirname"
                // Or: "-rw-r--r--  1 user group  1234 Mar 01 12:00 filename.txt"
                // Minimum: permissions + fields + name
                var parts = line.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length < 9) continue;

                try
                {
                    bool isDir = parts[0].StartsWith('d');
                    long size = long.TryParse(parts[4], out long s) ? s : 0;
                    string date = $"{parts[5]} {parts[6]} {parts[7]}";
                    // Name may contain spaces — rejoin everything from index 8 onward
                    string name = string.Join(' ', parts, 8, parts.Length - 8);

                    // Skip . and ..
                    if (name == "." || name == "..") continue;

                    entries.Add(new FtpEntry
                    {
                        Name = name,
                        Size = size,
                        Date = date,
                        IsDirectory = isDir
                    });
                }
                catch
                {
                    // Skip unparseable lines
                }
            }

            // Sort: directories first, then by name
            entries.Sort((a, b) =>
            {
                if (a.IsDirectory != b.IsDirectory)
                    return a.IsDirectory ? -1 : 1;
                return string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase);
            });

            return entries;
        }

        private void SetConnectionInputsEnabled(bool enabled)
        {
            txtServerIp.Enabled = enabled;
            nudPort.Enabled = enabled;
            txtUsername.Enabled = enabled;
            txtPassword.Enabled = enabled;
            txtLocalIp.Enabled = enabled;
            txtNetmask.Enabled = enabled;
            txtGateway.Enabled = enabled;
        }

        private void LogTimer_Tick(object? sender, EventArgs e)
        {
            if (_ftpEngine == null) return;

            int count = 0;
            while (_ftpEngine.LogQueue.TryDequeue(out var msg) && count < 100)
            {
                Color color = Color.White;
                if (msg.StartsWith(">>>") || msg.StartsWith("CMD"))
                    color = Color.Cyan;
                else if (msg.StartsWith("<<<") || msg.StartsWith("RSP"))
                    color = Color.LightGreen;
                else if (msg.StartsWith("ERR") || msg.Contains("error", StringComparison.OrdinalIgnoreCase))
                    color = Color.Red;

                AppendLog(msg, color);
                count++;
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

        private static string FormatFileSize(long bytes)
        {
            if (bytes < 1024) return $"{bytes} B";
            if (bytes < 1024 * 1024) return $"{bytes / 1024.0:F1} KB";
            if (bytes < 1024 * 1024 * 1024) return $"{bytes / (1024.0 * 1024.0):F1} MB";
            return $"{bytes / (1024.0 * 1024.0 * 1024.0):F2} GB";
        }

        /// <summary>엔진 정리 (앱 종료 시 MainForm에서 호출)</summary>
        public void StopEngine()
        {
            _logTimer.Stop();
            try { _ftpEngine?.StopLwip(); } catch { }
            _ftpEngine = null;
        }

        public void ApplySettings(AppSettings settings)
        {
            txtServerIp.Text = settings.FtpServerIp;
            nudPort.Value = Math.Clamp(settings.FtpServerPort, (int)nudPort.Minimum, (int)nudPort.Maximum);
            txtUsername.Text = settings.FtpUsername;
            txtPassword.Text = settings.FtpPassword;
            txtLocalIp.Text = settings.FtpLocalIp;
            txtNetmask.Text = settings.FtpNetmask;
            txtGateway.Text = settings.FtpGateway;
        }

        public void CollectSettings(AppSettings settings)
        {
            settings.FtpServerIp = txtServerIp.Text;
            settings.FtpServerPort = (int)nudPort.Value;
            settings.FtpUsername = txtUsername.Text;
            settings.FtpPassword = txtPassword.Text;
            settings.FtpLocalIp = txtLocalIp.Text;
            settings.FtpNetmask = txtNetmask.Text;
            settings.FtpGateway = txtGateway.Text;
        }
    }
}
