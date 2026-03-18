using HwNet.Utilities;

namespace HwNet
{
    public class PortInfo
    {
        public ushort PortId { get; init; }
        public byte[] Mac { get; set; } = new byte[6];
        public bool LinkUp { get; set; }
        public uint LinkSpeed { get; set; }
        public bool IsSetup { get; set; }
        public string DisplayName => $"포트 {PortId}: {NetUtils.FormatMac(Mac)} | " +
            (LinkUp ? $"UP ({LinkSpeed} Mbps)" : "DOWN") +
            (IsSetup ? "" : " [미설정]");
    }
}
