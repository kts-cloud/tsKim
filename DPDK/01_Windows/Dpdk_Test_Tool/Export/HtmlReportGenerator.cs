using System.Globalization;
using System.Text;

namespace DpdkTestTool.Export
{
    public static class HtmlReportGenerator
    {
        public static string Generate(PerformanceReportData data)
        {
            var sb = new StringBuilder(65536);

            AppendHead(sb, data);
            AppendHeader(sb, data);
            AppendSystemAndConfig(sb, data);
            AppendSummaryTable(sb, data);
            AppendChartSection(sb);
            AppendHistoryTables(sb, data);
            AppendScripts(sb, data);
            AppendFooter(sb);

            return sb.ToString();
        }

        private static void AppendHead(StringBuilder sb, PerformanceReportData data)
        {
            sb.AppendLine(@"<!DOCTYPE html>
<html lang=""ko"">
<head>
<meta charset=""UTF-8"">
<meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
<title>DPDK vs Socket UDP 성능 비교 리포트</title>
<style>
:root {
    --bg: #0f172a;
    --surface: #1e293b;
    --surface2: #334155;
    --border: #475569;
    --text: #e2e8f0;
    --text-muted: #94a3b8;
    --accent: #38bdf8;
    --accent2: #818cf8;
    --green: #4ade80;
    --orange: #fb923c;
    --red: #f87171;
    --yellow: #fbbf24;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
    font-family: 'Segoe UI', -apple-system, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.6;
    padding: 0;
}
header {
    background: linear-gradient(135deg, #1e293b, #0f172a, #1e1b4b);
    border-bottom: 1px solid var(--border);
    padding: 2rem;
    text-align: center;
}
header h1 {
    font-size: 2rem;
    font-weight: 700;
    background: linear-gradient(135deg, var(--accent), var(--accent2));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}
header p { color: var(--text-muted); font-size: 0.95rem; margin-top: 0.3rem; }
.container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
h2 {
    font-size: 1.4rem; font-weight: 700; color: var(--text);
    margin: 2rem 0 1rem; padding-bottom: 0.5rem;
    border-bottom: 1px solid var(--border);
}
h2:first-child { margin-top: 0; }
h3 { font-size: 1.1rem; color: var(--accent); margin: 1.5rem 0 0.5rem; }

/* Tables */
table { width: 100%; border-collapse: collapse; margin: 0.5rem 0 1.5rem; font-size: 0.9rem; }
th {
    background: var(--surface2); color: var(--accent); text-align: left;
    padding: 0.6rem 1rem; font-weight: 600; border: 1px solid var(--border);
}
td { padding: 0.5rem 1rem; border: 1px solid var(--border); }
tr:nth-child(even) td { background: rgba(30,41,59,0.5); }
td.val-dpdk { color: var(--accent); font-weight: 600; font-family: 'Cascadia Code', Consolas, monospace; }
td.val-socket { color: var(--accent2); font-weight: 600; font-family: 'Cascadia Code', Consolas, monospace; }
td.winner { background: rgba(74,222,128,0.1); }
td.diff-positive { color: var(--green); font-weight: 600; }
td.diff-negative { color: var(--red); font-weight: 600; }
td.diff-equal { color: var(--text-muted); }

/* Chart containers */
.chart-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin: 1rem 0; }
.chart-box {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: 8px; padding: 1rem; position: relative;
}
.chart-box h4 { color: var(--text-muted); font-size: 0.85rem; margin-bottom: 0.5rem; text-align: center; }
.chart-box canvas { height: 280px !important; }
.chart-full { grid-column: 1 / -1; }

/* Legend badges */
.legend { display: flex; gap: 1.5rem; justify-content: center; margin: 1rem 0; }
.legend-item { display: flex; align-items: center; gap: 0.4rem; font-size: 0.85rem; color: var(--text-muted); }
.legend-dot { width: 12px; height: 12px; border-radius: 3px; }
.legend-dot.dpdk { background: var(--accent); }
.legend-dot.socket { background: var(--accent2); }

/* Info boxes */
.info-box {
    background: rgba(56,189,248,0.06); border-left: 4px solid var(--accent);
    border-radius: 8px; padding: 1rem 1.25rem; margin: 1rem 0;
}
.info-box strong { color: var(--accent); }

/* History table */
.history-scroll { max-height: 400px; overflow-y: auto; border: 1px solid var(--border); border-radius: 8px; }
.history-scroll table { margin: 0; }
.history-scroll th { position: sticky; top: 0; z-index: 1; }
.row-dpdk td:nth-child(1) { border-left: 3px solid var(--accent); }
.row-socket td:nth-child(1) { border-left: 3px solid var(--accent2); }

/* Responsive */
@media (max-width: 768px) { .chart-grid { grid-template-columns: 1fr; } .container { padding: 1rem; } }
@media print {
    body { background: #fff; color: #000; }
    header { background: #f5f5f5; }
    header h1 { -webkit-text-fill-color: #1e293b; }
    .chart-box { border-color: #ccc; }
    td.val-dpdk, td.val-socket { color: #000; }
}
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: var(--bg); }
::-webkit-scrollbar-thumb { background: var(--surface2); border-radius: 3px; }
</style>
</head>
<body>");
        }

        private static void AppendHeader(StringBuilder sb, PerformanceReportData data)
        {
            sb.AppendLine($@"
<header>
    <h1>DPDK vs Socket UDP 성능 비교 리포트</h1>
    <p>생성: {data.GeneratedAt:yyyy-MM-dd HH:mm:ss}</p>
</header>
<div class=""container"">");
        }

        private static void AppendSystemAndConfig(StringBuilder sb, PerformanceReportData data)
        {
            sb.AppendLine(@"<h2>테스트 환경</h2>");

            sb.AppendLine(@"<div style=""display:grid;grid-template-columns:1fr 1fr;gap:1.5rem"">");

            // System info
            sb.AppendLine(@"<div>");
            sb.AppendLine(@"<h3>PC 사양</h3>");
            sb.AppendLine(@"<table>");
            if (data.SystemInfo is { } si)
            {
                sb.AppendLine($@"<tr><td style=""width:35%""><strong>PC 이름</strong></td><td>{Esc(si.MachineName)}</td></tr>");
                sb.AppendLine($@"<tr><td><strong>OS</strong></td><td>{Esc(si.OsVersion)}</td></tr>");
                sb.AppendLine($@"<tr><td><strong>CPU</strong></td><td>{Esc(si.ProcessorName)}</td></tr>");
                sb.AppendLine($@"<tr><td><strong>CPU 코어</strong></td><td>{si.ProcessorCount} (논리)</td></tr>");
                sb.AppendLine($@"<tr><td><strong>RAM</strong></td><td>{si.TotalRamGB:F1} GB</td></tr>");
            }
            else
            {
                sb.AppendLine(@"<tr><td colspan=""2"" style=""color:var(--text-muted)"">수집 실패</td></tr>");
            }
            sb.AppendLine(@"</table>");
            sb.AppendLine(@"</div>");

            // Test config
            sb.AppendLine(@"<div>");
            sb.AppendLine(@"<h3>테스트 설정</h3>");
            sb.AppendLine(@"<table>");
            if (data.TestConfig is { } tc)
            {
                sb.AppendLine($@"<tr><td style=""width:35%""><strong>목적지</strong></td><td>{Esc(tc.DstIp)}:{tc.DstPort}</td></tr>");
                sb.AppendLine($@"<tr><td><strong>출발지</strong></td><td>{Esc(tc.SrcIp)}:{tc.SrcPort}</td></tr>");
                sb.AppendLine($@"<tr><td><strong>DST MAC</strong></td><td>{Esc(tc.DstMac)}</td></tr>");
                sb.AppendLine($@"<tr><td><strong>Payload</strong></td><td>{tc.PayloadSize} bytes</td></tr>");
                if (!string.IsNullOrEmpty(tc.PayloadText))
                    sb.AppendLine($@"<tr><td><strong>명령어</strong></td><td><code>{Esc(tc.PayloadText)}</code></td></tr>");
                sb.AppendLine($@"<tr><td><strong>전송률</strong></td><td>{(tc.SendRate == 0 ? "무제한" : $"{tc.SendRate:N0} PPS")}</td></tr>");
                sb.AppendLine($@"<tr><td><strong>Timeout</strong></td><td>{tc.TimeoutMs:N0} ms</td></tr>");

                // Show actual sent counts from comparison data
                if (data.Dpdk != null && data.Dpdk.Sent > 0)
                    sb.AppendLine($@"<tr><td><strong>DPDK 전송 횟수</strong></td><td>{data.Dpdk.Sent:N0} 회</td></tr>");
                if (data.Socket != null && data.Socket.Sent > 0)
                    sb.AppendLine($@"<tr><td><strong>Socket 전송 횟수</strong></td><td>{data.Socket.Sent:N0} 회</td></tr>");
            }
            else
            {
                sb.AppendLine(@"<tr><td colspan=""2"" style=""color:var(--text-muted)"">설정 정보 없음</td></tr>");
            }
            sb.AppendLine(@"</table>");
            sb.AppendLine(@"</div>");

            sb.AppendLine(@"</div>");
        }

        private static string Esc(string s) => System.Net.WebUtility.HtmlEncode(s);

        private static void AppendSummaryTable(StringBuilder sb, PerformanceReportData data)
        {
            var d = data.Dpdk;
            var s = data.Socket;

            sb.AppendLine(@"<h2>성능 비교 요약</h2>");

            sb.AppendLine(@"<div class=""legend"">
    <div class=""legend-item""><div class=""legend-dot dpdk""></div>DPDK UDP</div>
    <div class=""legend-item""><div class=""legend-dot socket""></div>Socket UDP</div>
</div>");

            sb.AppendLine(@"<table>
<tr><th>항목</th><th>DPDK UDP</th><th>Socket UDP</th><th>비교</th></tr>");

            // Row helpers
            AppendCompRow(sb, "Avg PPS", FormatPps(d?.AvgPps), FormatPps(s?.AvgPps), d?.AvgPps, s?.AvgPps, false);
            AppendCompRow(sb, "Peak PPS", FormatPps(d?.PeakPps), FormatPps(s?.PeakPps), d?.PeakPps, s?.PeakPps, false);
            AppendCompRow(sb, "Avg RTT", FormatMs(d?.AvgRtt), FormatMs(s?.AvgRtt), d?.AvgRtt, s?.AvgRtt, true);
            AppendCompRow(sb, "Min RTT", FormatMs(d?.MinRtt), FormatMs(s?.MinRtt), d?.MinRtt, s?.MinRtt, true);
            AppendCompRow(sb, "Max RTT", FormatMs(d?.MaxRtt), FormatMs(s?.MaxRtt), d?.MaxRtt, s?.MaxRtt, true);
            AppendCompRow(sb, "StdDev RTT", FormatMs(d?.StdDevRtt), FormatMs(s?.StdDevRtt), d?.StdDevRtt, s?.StdDevRtt, true);

            // Success / Total
            string dSuccess = d != null && d.Sent > 0 ? $"{d.Received:N0} / {d.Sent:N0}" : "-";
            string sSuccess = s != null && s.Sent > 0 ? $"{s.Received:N0} / {s.Sent:N0}" : "-";
            string successDiff = "";
            string successDiffClass = "diff-equal";
            if (d != null && s != null && d.Sent > 0 && s.Sent > 0)
            {
                double dRate = (double)d.Received / d.Sent * 100;
                double sRate = (double)s.Received / s.Sent * 100;
                successDiff = $"{dRate:F1}% vs {sRate:F1}%";
            }
            sb.AppendLine($@"<tr><td>성공/전체</td><td class=""val-dpdk"">{dSuccess}</td><td class=""val-socket"">{sSuccess}</td><td class=""{successDiffClass}"">{successDiff}</td></tr>");

            AppendCompRow(sb, "소요시간", FormatSec(d?.ElapsedSec), FormatSec(s?.ElapsedSec), d?.ElapsedSec, s?.ElapsedSec, true);

            sb.AppendLine("</table>");
        }

        private static void AppendCompRow(StringBuilder sb, string label, string dVal, string sVal, double? dNum, double? sNum, bool lowerIsBetter)
        {
            string diffText = "";
            string diffClass = "diff-equal";
            string dWinner = "", sWinner = "";

            if (dNum.HasValue && sNum.HasValue && dNum.Value > 0 && sNum.Value > 0)
            {
                double pct = (dNum.Value - sNum.Value) / sNum.Value * 100;
                if (Math.Abs(pct) >= 0.5)
                {
                    bool dpdkBetter = lowerIsBetter ? pct < 0 : pct > 0;
                    string who = dpdkBetter ? "DPDK" : "Socket";
                    diffText = $"{who} 우세 ({Math.Abs(pct):F1}%)";
                    diffClass = dpdkBetter ? "diff-positive" : "diff-negative";
                    if (dpdkBetter) dWinner = " winner"; else sWinner = " winner";
                }
                else
                {
                    diffText = "동일";
                }
            }

            sb.AppendLine($@"<tr><td>{label}</td><td class=""val-dpdk{dWinner}"">{dVal}</td><td class=""val-socket{sWinner}"">{sVal}</td><td class=""{diffClass}"">{diffText}</td></tr>");
        }

        private static void AppendChartSection(StringBuilder sb)
        {
            sb.AppendLine(@"
<h2>시계열 그래프</h2>
<div class=""chart-grid"">
    <div class=""chart-box""><h4>TX PPS (Packets Per Second)</h4><canvas id=""chartTxPps""></canvas></div>
    <div class=""chart-box""><h4>RX PPS (Packets Per Second)</h4><canvas id=""chartRxPps""></canvas></div>
    <div class=""chart-box""><h4>TX Throughput (Mbps)</h4><canvas id=""chartTxMbps""></canvas></div>
    <div class=""chart-box""><h4>RX Throughput (Mbps)</h4><canvas id=""chartRxMbps""></canvas></div>
</div>

<h2>비교 차트</h2>
<div class=""chart-grid"">
    <div class=""chart-box""><h4>Peak PPS 비교</h4><canvas id=""chartPeakPps""></canvas></div>
    <div class=""chart-box"" id=""rttChartBox""><h4>RTT 비교 (ms)</h4><canvas id=""chartRtt""></canvas></div>
</div>");
        }

        private static void AppendHistoryTables(StringBuilder sb, PerformanceReportData data)
        {
            sb.AppendLine(@"<h2>세션 히스토리</h2>");

            if (data.DpdkTimeSeries.Count == 0 && data.SocketTimeSeries.Count == 0)
            {
                sb.AppendLine(@"<div class=""info-box""><strong>데이터 없음</strong> — 엔진을 실행한 후 내보내기하세요.</div>");
                return;
            }

            sb.AppendLine(@"<div class=""history-scroll""><table>
<tr><th>시간</th><th>소스</th><th>TX PPS</th><th>RX PPS</th><th>TX Mbps</th><th>RX Mbps</th><th>총 TX</th><th>총 RX</th><th>Err</th><th>Drop</th></tr>");

            // Merge and sort by time
            var allPoints = new List<(string source, TimeSeriesPoint p)>();
            foreach (var p in data.DpdkTimeSeries) allPoints.Add(("DPDK", p));
            foreach (var p in data.SocketTimeSeries) allPoints.Add(("Socket", p));
            allPoints.Sort((a, b) => string.Compare(a.p.Time, b.p.Time, StringComparison.Ordinal));

            foreach (var (source, p) in allPoints)
            {
                string rowClass = source == "DPDK" ? "row-dpdk" : "row-socket";
                sb.AppendLine($@"<tr class=""{rowClass}""><td>{p.Time}</td><td>{source}</td><td>{FormatPps(p.TxPps)}</td><td>{FormatPps(p.RxPps)}</td><td>{p.TxMbps:F1}</td><td>{p.RxMbps:F1}</td><td>{p.TxPackets:N0}</td><td>{p.RxPackets:N0}</td><td>{p.Errors}</td><td>{p.Dropped}</td></tr>");
            }

            sb.AppendLine("</table></div>");
        }

        private static void AppendScripts(StringBuilder sb, PerformanceReportData data)
        {
            // Serialize time-series data as JSON arrays
            string dpdkTimes = JsonArray(data.DpdkTimeSeries.Select(p => p.Time));
            string dpdkTxPps = NumArray(data.DpdkTimeSeries.Select(p => p.TxPps));
            string dpdkRxPps = NumArray(data.DpdkTimeSeries.Select(p => p.RxPps));
            string dpdkTxMbps = NumArray(data.DpdkTimeSeries.Select(p => p.TxMbps));
            string dpdkRxMbps = NumArray(data.DpdkTimeSeries.Select(p => p.RxMbps));

            string socketTimes = JsonArray(data.SocketTimeSeries.Select(p => p.Time));
            string socketTxPps = NumArray(data.SocketTimeSeries.Select(p => p.TxPps));
            string socketRxPps = NumArray(data.SocketTimeSeries.Select(p => p.RxPps));
            string socketTxMbps = NumArray(data.SocketTimeSeries.Select(p => p.TxMbps));
            string socketRxMbps = NumArray(data.SocketTimeSeries.Select(p => p.RxMbps));

            // Comparison data for bar charts
            double dPeakPps = data.Dpdk?.PeakPps ?? 0;
            double sPeakPps = data.Socket?.PeakPps ?? 0;
            double dAvgRtt = data.Dpdk?.AvgRtt ?? 0;
            double sAvgRtt = data.Socket?.AvgRtt ?? 0;
            double dMinRtt = data.Dpdk?.MinRtt ?? 0;
            double sMinRtt = data.Socket?.MinRtt ?? 0;
            double dMaxRtt = data.Dpdk?.MaxRtt ?? 0;
            double sMaxRtt = data.Socket?.MaxRtt ?? 0;
            double dStdDevRtt = data.Dpdk?.StdDevRtt ?? 0;
            double sStdDevRtt = data.Socket?.StdDevRtt ?? 0;
            bool hasRtt = dAvgRtt > 0 || sAvgRtt > 0;

            sb.AppendLine($@"
<script src=""https://cdn.jsdelivr.net/npm/chart.js@4""></script>
<script>
// Global Chart.js defaults
Chart.defaults.color = '#94a3b8';
Chart.defaults.borderColor = '#334155';
Chart.defaults.font.family = ""'Segoe UI', sans-serif"";

const DPDK_COLOR = '#38bdf8';
const DPDK_BG = 'rgba(56,189,248,0.15)';
const SOCKET_COLOR = '#818cf8';
const SOCKET_BG = 'rgba(129,140,248,0.15)';

const numberFmt = new Intl.NumberFormat('ko-KR');
const tooltipCb = {{
    label: ctx => {{
        let v = ctx.parsed.y;
        return ctx.dataset.label + ': ' + (v >= 1000 ? numberFmt.format(Math.round(v)) : v.toFixed(1));
    }}
}};

// ── Time-Series Data ──
const dpdkTimes = {dpdkTimes};
const socketTimes = {socketTimes};
const dpdkTxPps = {dpdkTxPps};
const dpdkRxPps = {dpdkRxPps};
const dpdkTxMbps = {dpdkTxMbps};
const dpdkRxMbps = {dpdkRxMbps};
const socketTxPps = {socketTxPps};
const socketRxPps = {socketRxPps};
const socketTxMbps = {socketTxMbps};
const socketRxMbps = {socketRxMbps};

// Merge unique time labels preserving order
function mergeLabels(a, b) {{
    const set = new Set();
    const result = [];
    for (const t of a) {{ if (!set.has(t)) {{ set.add(t); result.push(t); }} }}
    for (const t of b) {{ if (!set.has(t)) {{ set.add(t); result.push(t); }} }}
    result.sort();
    return result;
}}

function mapToLabels(labels, times, values) {{
    const map = new Map();
    times.forEach((t, i) => map.set(t, values[i]));
    return labels.map(t => map.has(t) ? map.get(t) : null);
}}

// ── Time-Series Charts ──
function createTimeChart(canvasId, title, dpdkVals, socketVals) {{
    const labels = mergeLabels(dpdkTimes, socketTimes);
    const dData = mapToLabels(labels, dpdkTimes, dpdkVals);
    const sData = mapToLabels(labels, socketTimes, socketVals);

    new Chart(document.getElementById(canvasId), {{
        type: 'line',
        data: {{
            labels: labels,
            datasets: [
                {{
                    label: 'DPDK',
                    data: dData,
                    borderColor: DPDK_COLOR,
                    backgroundColor: DPDK_BG,
                    borderWidth: 2,
                    pointRadius: 0,
                    tension: 0.3,
                    fill: true,
                    spanGaps: false
                }},
                {{
                    label: 'Socket',
                    data: sData,
                    borderColor: SOCKET_COLOR,
                    backgroundColor: SOCKET_BG,
                    borderWidth: 2,
                    pointRadius: 0,
                    tension: 0.3,
                    fill: true,
                    spanGaps: false
                }}
            ]
        }},
        options: {{
            responsive: true,
            maintainAspectRatio: false,
            interaction: {{ mode: 'index', intersect: false }},
            plugins: {{
                tooltip: {{ callbacks: tooltipCb }},
                legend: {{ labels: {{ usePointStyle: true, pointStyle: 'rect' }} }}
            }},
            scales: {{
                x: {{
                    grid: {{ color: '#1e293b' }},
                    ticks: {{ maxTicksLimit: 15, maxRotation: 0 }}
                }},
                y: {{
                    grid: {{ color: '#1e293b' }},
                    beginAtZero: true,
                    ticks: {{
                        callback: v => v >= 1000000 ? (v/1000000).toFixed(1)+'M' : v >= 1000 ? (v/1000).toFixed(0)+'K' : v.toFixed(0)
                    }}
                }}
            }}
        }}
    }});
}}

createTimeChart('chartTxPps', 'TX PPS', dpdkTxPps, socketTxPps);
createTimeChart('chartRxPps', 'RX PPS', dpdkRxPps, socketRxPps);
createTimeChart('chartTxMbps', 'TX Mbps', dpdkTxMbps, socketTxMbps);
createTimeChart('chartRxMbps', 'RX Mbps', dpdkRxMbps, socketRxMbps);

// ── Peak PPS Bar Chart ──
new Chart(document.getElementById('chartPeakPps'), {{
    type: 'bar',
    data: {{
        labels: ['Peak PPS'],
        datasets: [
            {{ label: 'DPDK', data: [{F(dPeakPps)}], backgroundColor: DPDK_COLOR, borderRadius: 4 }},
            {{ label: 'Socket', data: [{F(sPeakPps)}], backgroundColor: SOCKET_COLOR, borderRadius: 4 }}
        ]
    }},
    options: {{
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: 'y',
        plugins: {{
            tooltip: {{ callbacks: tooltipCb }},
            legend: {{ labels: {{ usePointStyle: true, pointStyle: 'rect' }} }}
        }},
        scales: {{
            x: {{
                grid: {{ color: '#1e293b' }},
                ticks: {{
                    callback: v => v >= 1000000 ? (v/1000000).toFixed(1)+'M' : v >= 1000 ? (v/1000).toFixed(0)+'K' : v
                }}
            }},
            y: {{ grid: {{ display: false }} }}
        }}
    }}
}});

// ── RTT Bar Chart ──
{(hasRtt ? $@"
new Chart(document.getElementById('chartRtt'), {{
    type: 'bar',
    data: {{
        labels: ['Avg RTT', 'Min RTT', 'Max RTT', 'StdDev RTT'],
        datasets: [
            {{ label: 'DPDK', data: [{F(dAvgRtt)}, {F(dMinRtt)}, {F(dMaxRtt)}, {F(dStdDevRtt)}], backgroundColor: DPDK_COLOR, borderRadius: 4 }},
            {{ label: 'Socket', data: [{F(sAvgRtt)}, {F(sMinRtt)}, {F(sMaxRtt)}, {F(sStdDevRtt)}], backgroundColor: SOCKET_COLOR, borderRadius: 4 }}
        ]
    }},
    options: {{
        responsive: true,
        maintainAspectRatio: false,
        plugins: {{
            tooltip: {{ callbacks: {{ label: ctx => ctx.dataset.label + ': ' + ctx.parsed.y.toFixed(3) + ' ms' }} }},
            legend: {{ labels: {{ usePointStyle: true, pointStyle: 'rect' }} }}
        }},
        scales: {{
            x: {{ grid: {{ display: false }} }},
            y: {{ grid: {{ color: '#1e293b' }}, beginAtZero: true, title: {{ display: true, text: 'ms', color: '#94a3b8' }} }}
        }}
    }}
}});" : @"
document.getElementById('rttChartBox').innerHTML = '<h4>RTT 비교 (ms)</h4><p style=""color:#94a3b8;text-align:center;padding:4rem"">RTT 데이터 없음 (Request/Response 모드에서만 수집)</p>';")}
</script>");
        }

        private static void AppendFooter(StringBuilder sb)
        {
            sb.AppendLine(@"
</div>
<footer style=""text-align:center;padding:2rem;color:#64748b;font-size:0.8rem;border-top:1px solid #334155"">
    DPDK vs Socket UDP Performance Report &middot; Generated by Dpdk Test Tool
</footer>
</body>
</html>");
        }

        // ── Formatting helpers ──

        private static string FormatPps(double? pps)
        {
            if (pps == null || pps <= 0) return "-";
            double v = pps.Value;
            if (v >= 1_000_000) return $"{v / 1_000_000:F2}M";
            if (v >= 1_000) return $"{v / 1_000:F1}K";
            return $"{v:F0}";
        }

        private static string FormatPps(double pps)
        {
            if (pps <= 0) return "-";
            if (pps >= 1_000_000) return $"{pps / 1_000_000:F2}M";
            if (pps >= 1_000) return $"{pps / 1_000:F1}K";
            return $"{pps:F0}";
        }

        private static string FormatMs(double? ms)
        {
            if (ms == null || ms <= 0) return "-";
            return $"{ms.Value:F3} ms";
        }

        private static string FormatSec(double? sec)
        {
            if (sec == null || sec <= 0) return "-";
            return $"{sec.Value:F1} s";
        }

        private static string F(double v) => v.ToString("G", CultureInfo.InvariantCulture);

        private static string JsonArray(IEnumerable<string> items)
        {
            return "[" + string.Join(",", items.Select(s => $"'{s}'")) + "]";
        }

        private static string NumArray(IEnumerable<double> items)
        {
            return "[" + string.Join(",", items.Select(v => v.ToString("G", CultureInfo.InvariantCulture))) + "]";
        }
    }
}
