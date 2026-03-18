using System.Runtime.InteropServices;

namespace HwNet.Interop
{
    [StructLayout(LayoutKind.Sequential)]
    internal struct HwReqRespResult
    {
        public int Status;
        public double RttMs;
        public ushort RespLen;
        public uint SrcIp;
        public ushort SrcPort;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct HwBatchStats
    {
        public ushort Sent;
        public ushort Received;
        public double ElapsedMs;
        public double TotalRttMs;
        public double MinRttMs;
        public double MaxRttMs;
        public double TotalRttSqMs;
    }
}
