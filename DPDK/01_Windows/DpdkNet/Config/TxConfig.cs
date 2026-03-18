namespace HwNet.Config
{
    public class TxConfig
    {
        public byte[] DstMac { get; set; } = new byte[6];
        public string DstIp { get; set; } = "192.168.0.1";
        public ushort DstPort { get; set; } = 5000;
        public string SrcIp { get; set; } = "192.168.0.2";
        public ushort SrcPort { get; set; } = 4000;
        public int PayloadSize { get; set; } = 64;
        public int TargetPps { get; set; } = 0;
        public string? PayloadText { get; set; }
    }
}
