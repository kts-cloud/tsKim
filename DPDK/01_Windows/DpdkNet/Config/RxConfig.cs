namespace HwNet.Config
{
    public class RxConfig
    {
        public ushort FilterPort { get; set; }
        public string? FilterIp { get; set; }
        public int MaxQueueSize { get; set; } = 10000;
    }
}
