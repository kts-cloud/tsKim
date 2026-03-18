namespace DpdkTestTool.Export
{
    public class PerformanceReportData
    {
        public DateTime GeneratedAt { get; set; }
        public ComparisonData? Dpdk { get; set; }
        public ComparisonData? Socket { get; set; }
        public List<TimeSeriesPoint> DpdkTimeSeries { get; set; } = new();
        public List<TimeSeriesPoint> SocketTimeSeries { get; set; } = new();
        public SystemInfoData? SystemInfo { get; set; }
        public TestConfigData? TestConfig { get; set; }
    }

    public class SystemInfoData
    {
        public string OsVersion { get; set; } = "";
        public string MachineName { get; set; } = "";
        public string ProcessorName { get; set; } = "";
        public int ProcessorCount { get; set; }
        public double TotalRamGB { get; set; }
    }

    public class TestConfigData
    {
        public string DstIp { get; set; } = "";
        public int DstPort { get; set; }
        public string SrcIp { get; set; } = "";
        public int SrcPort { get; set; }
        public int PayloadSize { get; set; }
        public string PayloadText { get; set; } = "";
        public int SendRate { get; set; }
        public int TimeoutMs { get; set; }
        public int RepeatCount { get; set; }
        public int WindowSize { get; set; }
        public string DstMac { get; set; } = "";
    }

    public class ComparisonData
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

    public class TimeSeriesPoint
    {
        public string Time { get; set; } = "";
        public double TxPps { get; set; }
        public double RxPps { get; set; }
        public double TxMbps { get; set; }
        public double RxMbps { get; set; }
        public long TxPackets { get; set; }
        public long RxPackets { get; set; }
        public long Errors { get; set; }
        public long Dropped { get; set; }
    }

}
