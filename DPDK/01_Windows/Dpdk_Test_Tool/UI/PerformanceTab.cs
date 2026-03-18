using HwNet;
using HwNet.Stats;
using HwNet.Utilities;
using DpdkTestTool.Export;

namespace DpdkTestTool.UI
{
    public class PerformanceTab : UserControl
    {
        // DPDK Live Performance
        private GroupBox grpDpdkLive;
        private Label lblDpdkTxPps, lblDpdkRxPps, lblDpdkTxMbps, lblDpdkRxMbps;
        private Label lblDpdkPeakTxPps, lblDpdkPeakRxPps;
        private Button btnDpdkPerfReset;

        // Socket UDP Live Performance
        private GroupBox grpSocketLive;
        private Label lblSocketTxPps, lblSocketRxPps, lblSocketTxMbps, lblSocketRxMbps;
        private Label lblSocketPeakTxPps, lblSocketPeakRxPps;
        private Button btnSocketPerfReset;

        // Link Info
        private GroupBox grpLink;
        private Label lblLinkSpeed, lblLinkDuplex, lblLinkStatus, lblMacAddr;

        // Comparison Panel
        private GroupBox grpComparison;
        private ListView lvComparison;
        private Button btnCaptureDpdk, btnCaptureSocket, btnCompareReset, btnExportHtml;

        // Session History
        private ListView lvHistory;
        private Button btnClearHistory;

        private System.Windows.Forms.Timer _timer = null!;
        private Func<PerformanceCounter?>? _getDpdkPerfCounter;
        private Func<PerformanceCounter?>? _getSocketPerfCounter;
        private Func<RttStats?>? _getDpdkRttStats;
        private Func<RttStats?>? _getSocketRttStats;

        // Comparison state
        private ComparisonEntry? _dpdkComparison;
        private ComparisonEntry? _socketComparison;
        private bool _dpdkWasActive;
        private bool _socketWasActive;

        // Time-series data for HTML export
        private readonly List<StatsSnapshot> _dpdkTimeSeries = new();
        private readonly List<StatsSnapshot> _socketTimeSeries = new();

        private class ComparisonEntry
        {
            public double AvgPps;
            public double PeakPps;
            public double AvgRtt;
            public double MinRtt;
            public double MaxRtt;
            public double StdDevRtt;
            public long Sent;
            public long Received;
            public long Timeouts;
            public double ElapsedSec;
        }

        public void SetPerfCounterSource(Func<PerformanceCounter?> getter) => _getDpdkPerfCounter = getter;
        public void SetSocketPerfCounterSource(Func<PerformanceCounter?> getter) => _getSocketPerfCounter = getter;
        public void SetDpdkRttStatsSource(Func<RttStats?> getter) => _getDpdkRttStats = getter;
        public void SetSocketRttStatsSource(Func<RttStats?> getter) => _getSocketRttStats = getter;

        public PerformanceTab()
        {
            InitializeUI();
        }

        private void InitializeUI()
        {
            this.Dock = DockStyle.Fill;

            var fConsolas9 = new Font("Consolas", 9);
            var fConsolas10B = new Font("Consolas", 10, FontStyle.Bold);
            var fConsolas8 = new Font("Consolas", 8);

            // === Link Info ===
            grpLink = new GroupBox { Text = "링크 상태", Location = new Point(10, 5), Size = new Size(320, 130) };

            lblLinkSpeed = new Label { Text = "Speed: -", Location = new Point(10, 20), AutoSize = true, Font = fConsolas9 };
            lblLinkDuplex = new Label { Text = "Duplex: -", Location = new Point(10, 40), AutoSize = true, Font = fConsolas9 };
            lblLinkStatus = new Label { Text = "Status: -", Location = new Point(10, 60), AutoSize = true, Font = fConsolas9 };
            lblMacAddr = new Label { Text = "MAC: -", Location = new Point(10, 80), AutoSize = true, Font = fConsolas9 };

            grpLink.Controls.AddRange(new Control[] { lblLinkSpeed, lblLinkDuplex, lblLinkStatus, lblMacAddr });

            // === DPDK Live Performance ===
            grpDpdkLive = new GroupBox { Text = "DPDK UDP 성능", Location = new Point(10, 140), Size = new Size(325, 85) };

            lblDpdkTxPps = new Label { Text = "TX: 0 PPS", Location = new Point(10, 18), Size = new Size(150, 18), Font = fConsolas10B };
            lblDpdkRxPps = new Label { Text = "RX: 0 PPS", Location = new Point(170, 18), Size = new Size(150, 18), Font = fConsolas10B };
            lblDpdkTxMbps = new Label { Text = "TX: 0.0 Mbps", Location = new Point(10, 38), Size = new Size(150, 18), Font = fConsolas9 };
            lblDpdkRxMbps = new Label { Text = "RX: 0.0 Mbps", Location = new Point(170, 38), Size = new Size(150, 18), Font = fConsolas9 };
            lblDpdkPeakTxPps = new Label { Text = "Peak TX: 0", Location = new Point(10, 58), AutoSize = true, Font = fConsolas8, ForeColor = Color.Gray };
            lblDpdkPeakRxPps = new Label { Text = "Peak RX: 0", Location = new Point(170, 58), AutoSize = true, Font = fConsolas8, ForeColor = Color.Gray };
            btnDpdkPerfReset = new Button { Text = "초기화", Location = new Point(265, 56), Size = new Size(52, 22), Font = fConsolas8 };
            btnDpdkPerfReset.Click += (s, e) => ResetDpdkPerf();

            grpDpdkLive.Controls.AddRange(new Control[] {
                lblDpdkTxPps, lblDpdkRxPps, lblDpdkTxMbps, lblDpdkRxMbps,
                lblDpdkPeakTxPps, lblDpdkPeakRxPps, btnDpdkPerfReset
            });

            // === Socket UDP Live Performance ===
            grpSocketLive = new GroupBox { Text = "Socket UDP 성능", Location = new Point(340, 140), Size = new Size(320, 85) };

            lblSocketTxPps = new Label { Text = "TX: 0 PPS", Location = new Point(10, 18), Size = new Size(150, 18), Font = fConsolas10B };
            lblSocketRxPps = new Label { Text = "RX: 0 PPS", Location = new Point(170, 18), Size = new Size(150, 18), Font = fConsolas10B };
            lblSocketTxMbps = new Label { Text = "TX: 0.0 Mbps", Location = new Point(10, 38), Size = new Size(150, 18), Font = fConsolas9 };
            lblSocketRxMbps = new Label { Text = "RX: 0.0 Mbps", Location = new Point(170, 38), Size = new Size(150, 18), Font = fConsolas9 };
            lblSocketPeakTxPps = new Label { Text = "Peak TX: 0", Location = new Point(10, 58), AutoSize = true, Font = fConsolas8, ForeColor = Color.Gray };
            lblSocketPeakRxPps = new Label { Text = "Peak RX: 0", Location = new Point(170, 58), AutoSize = true, Font = fConsolas8, ForeColor = Color.Gray };
            btnSocketPerfReset = new Button { Text = "초기화", Location = new Point(260, 56), Size = new Size(52, 22), Font = fConsolas8 };
            btnSocketPerfReset.Click += (s, e) => ResetSocketPerf();

            grpSocketLive.Controls.AddRange(new Control[] {
                lblSocketTxPps, lblSocketRxPps, lblSocketTxMbps, lblSocketRxMbps,
                lblSocketPeakTxPps, lblSocketPeakRxPps, btnSocketPerfReset
            });

            // === Comparison Panel ===
            grpComparison = new GroupBox { Text = "성능 비교", Location = new Point(10, 230), Size = new Size(650, 175) };

            lvComparison = new ListView
            {
                Location = new Point(10, 18), Size = new Size(628, 122),
                View = View.Details, FullRowSelect = true, GridLines = true,
                Font = fConsolas9, HeaderStyle = ColumnHeaderStyle.Nonclickable
            };
            lvComparison.Columns.Add("항목", 85);
            lvComparison.Columns.Add("DPDK UDP", 155);
            lvComparison.Columns.Add("Socket UDP", 155);
            lvComparison.Columns.Add("비교", 215);

            // Pre-populate 7 rows
            string[] rowLabels = { "Avg PPS", "Peak PPS", "Avg RTT", "Min RTT", "Max RTT", "StdDev RTT", "성공/전체", "소요시간" };
            foreach (var label in rowLabels)
            {
                var item = new ListViewItem(label);
                item.SubItems.Add("-");
                item.SubItems.Add("-");
                item.SubItems.Add("");
                lvComparison.Items.Add(item);
            }

            btnExportHtml = new Button { Text = "HTML 내보내기", Location = new Point(10, 145), Size = new Size(110, 23), Font = fConsolas8 };
            btnExportHtml.Click += (s, e) => ExportHtmlReport();
            btnCaptureDpdk = new Button { Text = "DPDK 캡처", Location = new Point(355, 145), Size = new Size(85, 23), Font = fConsolas8 };
            btnCaptureDpdk.Click += (s, e) => CaptureDpdkComparison();
            btnCaptureSocket = new Button { Text = "Socket 캡처", Location = new Point(445, 145), Size = new Size(90, 23), Font = fConsolas8 };
            btnCaptureSocket.Click += (s, e) => CaptureSocketComparison();
            btnCompareReset = new Button { Text = "초기화", Location = new Point(540, 145), Size = new Size(60, 23), Font = fConsolas8 };
            btnCompareReset.Click += (s, e) => ResetComparison();

            grpComparison.Controls.AddRange(new Control[] {
                lvComparison, btnExportHtml, btnCaptureDpdk, btnCaptureSocket, btnCompareReset
            });

            // === Session History ===
            btnClearHistory = new Button { Text = "Clear", Location = new Point(600, 410), Size = new Size(60, 23) };
            btnClearHistory.Click += (s, e) =>
            {
                lvHistory.Items.Clear();
                _dpdkTimeSeries.Clear();
                _socketTimeSeries.Clear();
            };

            lvHistory = new ListView
            {
                Location = new Point(10, 435), Size = new Size(650, 220),
                View = View.Details, FullRowSelect = true, GridLines = true,
                Font = fConsolas8
            };
            lvHistory.Columns.Add("시간", 60);
            lvHistory.Columns.Add("소스", 55);
            lvHistory.Columns.Add("TX PPS", 75);
            lvHistory.Columns.Add("RX PPS", 75);
            lvHistory.Columns.Add("TX Mbps", 65);
            lvHistory.Columns.Add("RX Mbps", 65);
            lvHistory.Columns.Add("총 TX", 70);
            lvHistory.Columns.Add("총 RX", 70);
            lvHistory.Columns.Add("Err", 40);
            lvHistory.Columns.Add("Drop", 45);

            this.Controls.AddRange(new Control[] {
                grpLink, grpDpdkLive, grpSocketLive,
                grpComparison,
                btnClearHistory, lvHistory
            });

            // Timer
            _timer = new System.Windows.Forms.Timer { Interval = 1000 };
            _timer.Tick += Timer_Tick;
            _timer.Start();
        }

        private void Timer_Tick(object? sender, EventArgs e)
        {
            // Update DPDK live performance
            var dpdkPerf = _getDpdkPerfCounter?.Invoke();
            if (dpdkPerf != null)
            {
                var snap = dpdkPerf.TakeSnapshot();
                bool dpdkActive = snap.TxPps > 0 || snap.RxPps > 0;

                if (dpdkActive)
                {
                    lblDpdkTxPps.Text = $"TX: {FormatPps(snap.TxPps)}";
                    lblDpdkRxPps.Text = $"RX: {FormatPps(snap.RxPps)}";
                    lblDpdkTxMbps.Text = $"TX: {snap.TxMbps:F1} Mbps";
                    lblDpdkRxMbps.Text = $"RX: {snap.RxMbps:F1} Mbps";
                }
                lblDpdkPeakTxPps.Text = $"Peak TX: {FormatPps(dpdkPerf.PeakTxPps)}";
                lblDpdkPeakRxPps.Text = $"Peak RX: {FormatPps(dpdkPerf.PeakRxPps)}";

                // Auto-capture on engine stop (active → idle transition)
                if (_dpdkWasActive && !dpdkActive)
                    CaptureDpdkComparison();
                _dpdkWasActive = dpdkActive;

                AddHistory("DPDK", snap);
            }

            // Update Socket UDP live performance
            var socketPerf = _getSocketPerfCounter?.Invoke();
            if (socketPerf != null)
            {
                var snap = socketPerf.TakeSnapshot();
                bool socketActive = snap.TxPps > 0 || snap.RxPps > 0;

                if (socketActive)
                {
                    lblSocketTxPps.Text = $"TX: {FormatPps(snap.TxPps)}";
                    lblSocketRxPps.Text = $"RX: {FormatPps(snap.RxPps)}";
                    lblSocketTxMbps.Text = $"TX: {snap.TxMbps:F1} Mbps";
                    lblSocketRxMbps.Text = $"RX: {snap.RxMbps:F1} Mbps";
                }
                lblSocketPeakTxPps.Text = $"Peak TX: {FormatPps(socketPerf.PeakTxPps)}";
                lblSocketPeakRxPps.Text = $"Peak RX: {FormatPps(socketPerf.PeakRxPps)}";

                // Auto-capture on engine stop
                if (_socketWasActive && !socketActive)
                    CaptureSocketComparison();
                _socketWasActive = socketActive;

                AddHistory("Socket", snap);
            }

            RefreshLinkInfo();
        }

        private void CaptureDpdkComparison()
        {
            var perf = _getDpdkPerfCounter?.Invoke();
            if (perf == null) return;
            var rtt = _getDpdkRttStats?.Invoke();
            double elapsed = perf.ElapsedSeconds;
            // RttStats의 Sent 사용 (ReqResp 모드), fallback으로 PerfCounter의 누적 TxPackets
            long sent = rtt?.Sent ?? 0;
            if (sent == 0)
            {
                var snap = perf.TakeSnapshot();
                sent = snap.TxPackets;
            }

            _dpdkComparison = new ComparisonEntry
            {
                AvgPps = elapsed > 0 && sent > 0 ? sent / elapsed : 0,
                PeakPps = perf.PeakTxPps,
                AvgRtt = rtt?.AvgRtt ?? 0,
                MinRtt = rtt?.MinRtt ?? 0,
                MaxRtt = rtt?.MaxRtt ?? 0,
                StdDevRtt = rtt?.StdDevRtt ?? 0,
                Sent = sent,
                Received = rtt?.Received ?? 0,
                Timeouts = rtt?.Timeouts ?? 0,
                ElapsedSec = elapsed
            };
            UpdateComparisonView();
        }

        private void CaptureSocketComparison()
        {
            var perf = _getSocketPerfCounter?.Invoke();
            if (perf == null) return;
            var rtt = _getSocketRttStats?.Invoke();
            double elapsed = perf.ElapsedSeconds;
            long sent = rtt?.Sent ?? 0;
            if (sent == 0)
            {
                var snap = perf.TakeSnapshot();
                sent = snap.TxPackets;
            }

            _socketComparison = new ComparisonEntry
            {
                AvgPps = elapsed > 0 && sent > 0 ? sent / elapsed : 0,
                PeakPps = perf.PeakTxPps,
                AvgRtt = rtt?.AvgRtt ?? 0,
                MinRtt = rtt?.MinRtt ?? 0,
                MaxRtt = rtt?.MaxRtt ?? 0,
                StdDevRtt = rtt?.StdDevRtt ?? 0,
                Sent = sent,
                Received = rtt?.Received ?? 0,
                Timeouts = rtt?.Timeouts ?? 0,
                ElapsedSec = elapsed
            };
            UpdateComparisonView();
        }

        private void UpdateComparisonView()
        {
            var d = _dpdkComparison;
            var s = _socketComparison;

            // Row 0: Avg PPS (higher is better)
            lvComparison.Items[0].SubItems[1].Text = d != null ? FormatPps(d.AvgPps) : "-";
            lvComparison.Items[0].SubItems[2].Text = s != null ? FormatPps(s.AvgPps) : "-";
            lvComparison.Items[0].SubItems[3].Text = FormatDiff(d?.AvgPps, s?.AvgPps, false);

            // Row 1: Peak PPS (higher is better)
            lvComparison.Items[1].SubItems[1].Text = d != null ? FormatPps(d.PeakPps) : "-";
            lvComparison.Items[1].SubItems[2].Text = s != null ? FormatPps(s.PeakPps) : "-";
            lvComparison.Items[1].SubItems[3].Text = FormatDiff(d?.PeakPps, s?.PeakPps, false);

            // Row 2: Avg RTT (lower is better)
            lvComparison.Items[2].SubItems[1].Text = d != null && d.AvgRtt > 0 ? $"{d.AvgRtt:F3} ms" : "-";
            lvComparison.Items[2].SubItems[2].Text = s != null && s.AvgRtt > 0 ? $"{s.AvgRtt:F3} ms" : "-";
            lvComparison.Items[2].SubItems[3].Text = FormatDiff(d?.AvgRtt, s?.AvgRtt, true);

            // Row 3: Min RTT (lower is better)
            lvComparison.Items[3].SubItems[1].Text = d != null && d.MinRtt > 0 ? $"{d.MinRtt:F3} ms" : "-";
            lvComparison.Items[3].SubItems[2].Text = s != null && s.MinRtt > 0 ? $"{s.MinRtt:F3} ms" : "-";
            lvComparison.Items[3].SubItems[3].Text = FormatDiff(d?.MinRtt, s?.MinRtt, true);

            // Row 4: Max RTT (lower is better)
            lvComparison.Items[4].SubItems[1].Text = d != null && d.MaxRtt > 0 ? $"{d.MaxRtt:F3} ms" : "-";
            lvComparison.Items[4].SubItems[2].Text = s != null && s.MaxRtt > 0 ? $"{s.MaxRtt:F3} ms" : "-";
            lvComparison.Items[4].SubItems[3].Text = FormatDiff(d?.MaxRtt, s?.MaxRtt, true);

            // Row 5: StdDev RTT (lower is better)
            lvComparison.Items[5].SubItems[1].Text = d != null && d.StdDevRtt > 0 ? $"{d.StdDevRtt:F3} ms" : "-";
            lvComparison.Items[5].SubItems[2].Text = s != null && s.StdDevRtt > 0 ? $"{s.StdDevRtt:F3} ms" : "-";
            lvComparison.Items[5].SubItems[3].Text = FormatDiff(d?.StdDevRtt, s?.StdDevRtt, true);

            // Row 6: 성공/전체
            lvComparison.Items[6].SubItems[1].Text = d != null && d.Sent > 0 ? $"{d.Received:N0}/{d.Sent:N0}" : "-";
            lvComparison.Items[6].SubItems[2].Text = s != null && s.Sent > 0 ? $"{s.Received:N0}/{s.Sent:N0}" : "-";
            if (d != null && s != null && d.Sent > 0 && s.Sent > 0)
            {
                double dRate = (double)d.Received / d.Sent * 100;
                double sRate = (double)s.Received / s.Sent * 100;
                lvComparison.Items[6].SubItems[3].Text = $"{dRate:F1}% vs {sRate:F1}%";
            }
            else
                lvComparison.Items[6].SubItems[3].Text = "";

            // Row 7: 소요시간 (lower is better)
            lvComparison.Items[7].SubItems[1].Text = d != null && d.ElapsedSec > 0 ? $"{d.ElapsedSec:F1} s" : "-";
            lvComparison.Items[7].SubItems[2].Text = s != null && s.ElapsedSec > 0 ? $"{s.ElapsedSec:F1} s" : "-";
            lvComparison.Items[7].SubItems[3].Text = FormatDiff(d?.ElapsedSec, s?.ElapsedSec, true);
        }

        private static string FormatDiff(double? dpdkVal, double? socketVal, bool lowerIsBetter)
        {
            if (dpdkVal == null || socketVal == null) return "";
            double dv = dpdkVal.Value, sv = socketVal.Value;
            if (dv <= 0 || sv <= 0) return "";
            double pct = (dv - sv) / sv * 100;
            if (Math.Abs(pct) < 0.5) return "동일";

            bool dpdkBetter = lowerIsBetter ? pct < 0 : pct > 0;
            string absPct = $"{Math.Abs(pct):F1}%";
            return dpdkBetter ? $"DPDK 우세 ({absPct})" : $"Socket 우세 ({absPct})";
        }

        private void ResetComparison()
        {
            _dpdkComparison = null;
            _socketComparison = null;
            for (int i = 0; i < lvComparison.Items.Count; i++)
            {
                lvComparison.Items[i].SubItems[1].Text = "-";
                lvComparison.Items[i].SubItems[2].Text = "-";
                lvComparison.Items[i].SubItems[3].Text = "";
            }
        }

        private void AddHistory(string source, StatsSnapshot snap)
        {
            if (snap.TxPps > 0 || snap.RxPps > 0)
            {
                var item = new ListViewItem(snap.Timestamp.ToString("HH:mm:ss"));
                item.SubItems.Add(source);
                item.SubItems.Add(FormatPps(snap.TxPps));
                item.SubItems.Add(FormatPps(snap.RxPps));
                item.SubItems.Add($"{snap.TxMbps:F1}");
                item.SubItems.Add($"{snap.RxMbps:F1}");
                item.SubItems.Add(snap.TxPackets.ToString("N0"));
                item.SubItems.Add(snap.RxPackets.ToString("N0"));
                item.SubItems.Add(snap.Errors.ToString());
                item.SubItems.Add(snap.Dropped.ToString());

                if (source == "Socket")
                    item.ForeColor = Color.DodgerBlue;

                lvHistory.Items.Insert(0, item);
                if (lvHistory.Items.Count > 500)
                    lvHistory.Items.RemoveAt(lvHistory.Items.Count - 1);

                // Store structured data for HTML export
                var list = source == "DPDK" ? _dpdkTimeSeries : _socketTimeSeries;
                list.Add(snap);
                if (list.Count > 500)
                    list.RemoveAt(0);
            }
        }

        private void ResetDpdkPerf()
        {
            var perf = _getDpdkPerfCounter?.Invoke();
            if (perf != null) perf.Reset();
            lblDpdkTxPps.Text = "TX: 0 PPS";
            lblDpdkRxPps.Text = "RX: 0 PPS";
            lblDpdkTxMbps.Text = "TX: 0.0 Mbps";
            lblDpdkRxMbps.Text = "RX: 0.0 Mbps";
            lblDpdkPeakTxPps.Text = "Peak TX: 0";
            lblDpdkPeakRxPps.Text = "Peak RX: 0";
        }

        private void ResetSocketPerf()
        {
            var perf = _getSocketPerfCounter?.Invoke();
            if (perf != null) perf.Reset();
            lblSocketTxPps.Text = "TX: 0 PPS";
            lblSocketRxPps.Text = "RX: 0 PPS";
            lblSocketTxMbps.Text = "TX: 0.0 Mbps";
            lblSocketRxMbps.Text = "RX: 0.0 Mbps";
            lblSocketPeakTxPps.Text = "Peak TX: 0";
            lblSocketPeakRxPps.Text = "Peak RX: 0";
        }

        private void RefreshLinkInfo()
        {
            try
            {
                if (HwManager.Instance.State != HwState.Ready) return;

                var link = HwManager.Instance.GetLinkInfo();

                lblLinkSpeed.Text = $"Speed: {link.link_speed} Mbps";
                lblLinkDuplex.Text = $"Duplex: {(link.link_duplex == 1 ? "Full" : "Half")}";
                lblLinkStatus.Text = $"Status: {(link.link_status == 1 ? "UP" : "DOWN")}";
                lblLinkStatus.ForeColor = link.link_status == 1 ? Color.Green : Color.Red;
                lblMacAddr.Text = $"MAC: {NetUtils.FormatMac(HwManager.Instance.LocalMac)}";
            }
            catch { }
        }

        private void ExportHtmlReport()
        {
            bool hasComparison = _dpdkComparison != null || _socketComparison != null;
            bool hasTimeSeries = _dpdkTimeSeries.Count > 0 || _socketTimeSeries.Count > 0;

            if (!hasComparison && !hasTimeSeries)
            {
                MessageBox.Show("내보낼 데이터가 없습니다.\n엔진을 실행한 후 다시 시도하세요.", "HTML 내보내기", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var data = new PerformanceReportData { GeneratedAt = DateTime.Now };

            // Comparison data
            if (_dpdkComparison is { } dc)
            {
                data.Dpdk = new ComparisonData
                {
                    AvgPps = dc.AvgPps, PeakPps = dc.PeakPps,
                    AvgRtt = dc.AvgRtt, MinRtt = dc.MinRtt, MaxRtt = dc.MaxRtt, StdDevRtt = dc.StdDevRtt,
                    Sent = dc.Sent, Received = dc.Received, Timeouts = dc.Timeouts,
                    ElapsedSec = dc.ElapsedSec
                };
            }
            if (_socketComparison is { } sc)
            {
                data.Socket = new ComparisonData
                {
                    AvgPps = sc.AvgPps, PeakPps = sc.PeakPps,
                    AvgRtt = sc.AvgRtt, MinRtt = sc.MinRtt, MaxRtt = sc.MaxRtt, StdDevRtt = sc.StdDevRtt,
                    Sent = sc.Sent, Received = sc.Received, Timeouts = sc.Timeouts,
                    ElapsedSec = sc.ElapsedSec
                };
            }

            // Time-series data
            data.DpdkTimeSeries = _dpdkTimeSeries.Select(s => new TimeSeriesPoint
            {
                Time = s.Timestamp.ToString("HH:mm:ss"),
                TxPps = s.TxPps, RxPps = s.RxPps,
                TxMbps = s.TxMbps, RxMbps = s.RxMbps,
                TxPackets = s.TxPackets, RxPackets = s.RxPackets,
                Errors = s.Errors, Dropped = s.Dropped
            }).ToList();

            data.SocketTimeSeries = _socketTimeSeries.Select(s => new TimeSeriesPoint
            {
                Time = s.Timestamp.ToString("HH:mm:ss"),
                TxPps = s.TxPps, RxPps = s.RxPps,
                TxMbps = s.TxMbps, RxMbps = s.RxMbps,
                TxPackets = s.TxPackets, RxPackets = s.RxPackets,
                Errors = s.Errors, Dropped = s.Dropped
            }).ToList();

            // System info
            data.SystemInfo = CollectSystemInfo();

            // Test config from current settings
            try
            {
                var settings = Core.AppSettings.Load();
                data.TestConfig = new TestConfigData
                {
                    DstIp = settings.DstIp,
                    DstPort = settings.DstPort,
                    SrcIp = settings.SrcIp,
                    SrcPort = settings.SrcPort,
                    PayloadSize = settings.PayloadSize,
                    PayloadText = settings.PayloadText,
                    SendRate = settings.SendRate,
                    TimeoutMs = settings.ResponseTimeoutMs,
                    DstMac = settings.DstMac,
                };
            }
            catch { }

            // Generate HTML
            string html = HtmlReportGenerator.Generate(data);

            // Save to reports directory
            string dir = Path.Combine(AppContext.BaseDirectory, "reports");
            Directory.CreateDirectory(dir);
            string filename = $"perf_report_{DateTime.Now:yyyyMMdd_HHmmss}.html";
            string path = Path.Combine(dir, filename);
            File.WriteAllText(path, html, System.Text.Encoding.UTF8);

            // Open in default browser
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(path) { UseShellExecute = true });
        }

        private static SystemInfoData CollectSystemInfo()
        {
            var info = new SystemInfoData
            {
                OsVersion = $"{Environment.OSVersion.VersionString}",
                MachineName = Environment.MachineName,
                ProcessorCount = Environment.ProcessorCount,
            };

            try
            {
                using var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(
                    @"HARDWARE\DESCRIPTION\System\CentralProcessor\0");
                info.ProcessorName = key?.GetValue("ProcessorNameString")?.ToString()?.Trim() ?? "Unknown";
            }
            catch { info.ProcessorName = "Unknown"; }

            try
            {
                var gcInfo = GC.GetGCMemoryInfo();
                info.TotalRamGB = gcInfo.TotalAvailableMemoryBytes / (1024.0 * 1024 * 1024);
            }
            catch { }

            return info;
        }

        private static string FormatPps(double pps)
        {
            if (pps >= 1_000_000) return $"{pps / 1_000_000:F2}M";
            if (pps >= 1_000) return $"{pps / 1_000:F1}K";
            return $"{pps:F0}";
        }
    }
}
