namespace HwNet.Stats
{
    public class StatsSnapshot
    {
        public DateTime Timestamp { get; set; } = DateTime.Now;
        public long TxPackets { get; set; }
        public long RxPackets { get; set; }
        public long TxBytes { get; set; }
        public long RxBytes { get; set; }
        public double TxPps { get; set; }
        public double RxPps { get; set; }
        public double TxMbps { get; set; }
        public double RxMbps { get; set; }
        public long Errors { get; set; }
        public long Dropped { get; set; }
    }
}
