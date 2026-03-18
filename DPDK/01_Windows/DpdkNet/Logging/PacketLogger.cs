using System.Collections.Concurrent;
using System.Diagnostics;
using System.Text;

namespace HwNet.Logging
{
    public class PacketLogEntry
    {
        public long TimestampTicks;
        public byte Direction;      // 'T'=TX, 'R'=RX
        public uint SrcIp;
        public uint DstIp;
        public ushort SrcPort;
        public ushort DstPort;
        public int DataLen;
        public string? PayloadText;
        public double RttMs;
        public byte ResultStatus;   // 0=OK, 1=timeout, 2=error
    }

    public class PacketLogger : IDisposable
    {
        private readonly ConcurrentQueue<PacketLogEntry> _queue = new();
        private readonly Thread _writerThread;
        private volatile bool _running;
        private readonly string _filePath;
        private readonly long _startTicks;

        public string FilePath => _filePath;

        public PacketLogger(string engineName)
        {
            string dir = Path.Combine(AppContext.BaseDirectory, "logs");
            Directory.CreateDirectory(dir);
            _filePath = Path.Combine(dir, $"pkt_{engineName}_{DateTime.Now:yyyyMMdd_HHmmss}.csv");
            _startTicks = Stopwatch.GetTimestamp();
            _running = true;

            File.WriteAllText(_filePath,
                "Elapsed_ms,Direction,SrcIP,DstIP,SrcPort,DstPort,DataLen,Data,RTT_ms,Status\n",
                Encoding.UTF8);

            _writerThread = new Thread(WriterLoop)
            {
                IsBackground = true,
                Name = $"PktLog-{engineName}",
                Priority = ThreadPriority.BelowNormal
            };
            _writerThread.Start();
        }

        public void LogTx(uint srcIp, uint dstIp, ushort srcPort, ushort dstPort,
                          int dataLen, string? payload)
        {
            _queue.Enqueue(new PacketLogEntry
            {
                TimestampTicks = Stopwatch.GetTimestamp(),
                Direction = (byte)'T',
                SrcIp = srcIp, DstIp = dstIp,
                SrcPort = srcPort, DstPort = dstPort,
                DataLen = dataLen, PayloadText = payload
            });
        }

        public void LogRx(uint srcIp, uint dstIp, ushort srcPort, ushort dstPort,
                          int dataLen, string? payload)
        {
            _queue.Enqueue(new PacketLogEntry
            {
                TimestampTicks = Stopwatch.GetTimestamp(),
                Direction = (byte)'R',
                SrcIp = srcIp, DstIp = dstIp,
                SrcPort = srcPort, DstPort = dstPort,
                DataLen = dataLen, PayloadText = payload
            });
        }

        public void LogReqResp(uint srcIp, uint dstIp, ushort srcPort, ushort dstPort,
                               int dataLen, string? payload, double rttMs, byte status,
                               string? responsePayload = null, int responseDataLen = 0)
        {
            long now = Stopwatch.GetTimestamp();

            // TX 항목 (요청 전송) — payload = 요청 데이터
            _queue.Enqueue(new PacketLogEntry
            {
                TimestampTicks = now,
                Direction = (byte)'T',
                SrcIp = srcIp, DstIp = dstIp,
                SrcPort = srcPort, DstPort = dstPort,
                DataLen = dataLen, PayloadText = payload,
                RttMs = 0, ResultStatus = status
            });

            // RX 항목 (응답 수신) — responsePayload = 실제 응답 데이터
            if (status == 0)
            {
                _queue.Enqueue(new PacketLogEntry
                {
                    TimestampTicks = now,
                    Direction = (byte)'R',
                    SrcIp = dstIp, DstIp = srcIp,
                    SrcPort = dstPort, DstPort = srcPort,
                    DataLen = responseDataLen > 0 ? responseDataLen : dataLen,
                    PayloadText = responsePayload ?? payload,
                    RttMs = rttMs, ResultStatus = 0
                });
            }
        }

        private void WriterLoop()
        {
            var sb = new StringBuilder(16384);
            double freq = Stopwatch.Frequency;

            while (_running || !_queue.IsEmpty)
            {
                int count = 0;
                while (_queue.TryDequeue(out var e) && count < 10000)
                {
                    double ms = (e.TimestampTicks - _startTicks) / freq * 1000.0;
                    char dir = (char)e.Direction;
                    string dataCsv = EscapeCsv(e.PayloadText);
                    sb.Append(ms.ToString("F3")).Append(',')
                      .Append(dir).Append(',')
                      .Append(FormatIp(e.SrcIp)).Append(',')
                      .Append(FormatIp(e.DstIp)).Append(',')
                      .Append(e.SrcPort).Append(',')
                      .Append(e.DstPort).Append(',')
                      .Append(e.DataLen).Append(',')
                      .Append(dataCsv).Append(',')
                      .Append(e.RttMs.ToString("F3")).Append(',')
                      .Append(e.ResultStatus).AppendLine();
                    count++;
                }

                if (sb.Length > 0)
                {
                    try { File.AppendAllText(_filePath, sb.ToString()); }
                    catch { /* I/O 실패 무시 — 엔진에 영향 주지 않음 */ }
                    sb.Clear();
                }

                if (_running) Thread.Sleep(1000);
            }
        }

        private static string EscapeCsv(string? s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            if (s.Contains(',') || s.Contains('"') || s.Contains('\n') || s.Contains('\r'))
                return "\"" + s.Replace("\"", "\"\"") + "\"";
            return s;
        }

        private static string FormatIp(uint ip)
        {
            return $"{ip & 0xFF}.{(ip >> 8) & 0xFF}.{(ip >> 16) & 0xFF}.{(ip >> 24) & 0xFF}";
        }

        public void Dispose()
        {
            _running = false;
            _writerThread.Join(5000);
        }
    }
}
