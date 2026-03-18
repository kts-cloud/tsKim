namespace HwNet.Models
{
    public class RxPacketInfo
    {
        public byte[] SrcMac { get; set; } = Array.Empty<byte>();
        public byte[] DstMac { get; set; } = Array.Empty<byte>();
        public string SrcIp { get; set; } = "";
        public string DstIp { get; set; } = "";
        public ushort SrcPort { get; set; }
        public ushort DstPort { get; set; }
        public int DataLen { get; set; }
        public string? PayloadText { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.Now;
    }
}
