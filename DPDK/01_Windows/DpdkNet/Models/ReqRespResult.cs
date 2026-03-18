namespace HwNet.Models
{
    public class ReqRespResult
    {
        public uint SeqNumber { get; set; }
        public bool Success { get; set; }
        public double RttMs { get; set; }
        public string? ResponsePayload { get; set; }
        public string SrcIp { get; set; } = "";
        public ushort SrcPort { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.Now;
    }
}
