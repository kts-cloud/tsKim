using System.Runtime.InteropServices;

namespace HwNet
{
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct EtherHdr
    {
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 6)]
        public byte[] Dst;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 6)]
        public byte[] Src;
        public ushort EtherType;

        public const int Size = 14;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct Ipv4Hdr
    {
        public byte VersionIhl;
        public byte TypeOfService;
        public ushort TotalLength;
        public ushort PacketId;
        public ushort FragmentOffset;
        public byte TimeToLive;
        public byte NextProtoId;
        public ushort HdrChecksum;
        public uint SrcAddr;
        public uint DstAddr;

        public const int Size = 20;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct UdpHdr
    {
        public ushort SrcPort;
        public ushort DstPort;
        public ushort Len;
        public ushort Cksum;

        public const int Size = 8;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct ArpHdr
    {
        public ushort HardwareType;
        public ushort ProtocolType;
        public byte HardwareLen;
        public byte ProtocolLen;
        public ushort Opcode;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 6)]
        public byte[] SenderMac;
        public uint SenderIp;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 6)]
        public byte[] TargetMac;
        public uint TargetIp;

        public const int Size = 28;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RteEthStats
    {
        public ulong ipackets;
        public ulong opackets;
        public ulong ibytes;
        public ulong obytes;
        public ulong imissed;
        public ulong ierrors;
        public ulong oerrors;
        public ulong rx_nombuf;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RteEtherAddr
    {
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 6)]
        public byte[] addr_bytes;
    }

    [StructLayout(LayoutKind.Sequential, Size = 8)]
    public struct RteEthLink
    {
        public uint link_speed;
        private ushort _bitfield;
        private ushort _padding;

        public ushort link_duplex => (ushort)(_bitfield & 1);
        public ushort link_autoneg => (ushort)((_bitfield >> 1) & 1);
        public ushort link_status => (ushort)((_bitfield >> 2) & 1);
        public ushort RawBitfield => _bitfield;
    }
}
