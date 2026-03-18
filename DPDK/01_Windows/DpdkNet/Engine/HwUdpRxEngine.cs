using System.Collections.Concurrent;
using System.Runtime.InteropServices;
using HwNet.Config;
using HwNet.Interop;
using HwNet.Logging;
using HwNet.Models;
using HwNet.Stats;
using HwNet.Utilities;

namespace HwNet.Engine
{
    public class HwUdpRxEngine : IHwEngine
    {
        [DllImport("kernel32.dll")]
        private static extern IntPtr GetCurrentThread();
        [DllImport("kernel32.dll")]
        private static extern UIntPtr SetThreadAffinityMask(IntPtr hThread, UIntPtr dwThreadAffinityMask);
        private readonly IHwContext _dpdk;
        private readonly PerformanceCounter _perfCounter;
        private Thread? _rxThread;
        private volatile bool _running;

        public bool IsRunning => _running;
        public string? LastError { get; set; }
        public PacketLogger? Logger { get; set; }

        public ConcurrentQueue<RxPacketInfo> PacketQueue { get; } = new();

        public ushort FilterPort { get; set; }
        public string? FilterIp { get; set; }
        public int MaxQueueSize { get; set; } = 10000;

        public HwUdpRxEngine(IHwContext dpdk, PerformanceCounter perfCounter)
        {
            _dpdk = dpdk;
            _perfCounter = perfCounter;
        }

        public void Start()
        {
            if (_running) return;
            _running = true;
            _rxThread = new Thread(RxLoop) { IsBackground = true, Name = "DPDK-RX", Priority = ThreadPriority.Highest };
            _rxThread.Start();
        }

        public void Stop()
        {
            _running = false;
            _rxThread?.Join(2000);
            _rxThread = null;
        }

        public void Dispose()
        {
            Stop();
            GC.SuppressFinalize(this);
        }

        private void RxLoop()
        {
            if (_dpdk.State != HwState.Ready) return;

            // Pin RX thread to core 1 (same convention as PgDpdkServer)
            try { SetThreadAffinityMask(GetCurrentThread(), new UIntPtr(1u << 1)); } catch { }

            const int BatchSize = 32;
            IntPtr[] rxMbufs = new IntPtr[BatchSize];

            while (_running)
            {
                ushort nbRx = HwInterop.hw_rx_burst(_dpdk.PortId, 0, rxMbufs, BatchSize);
                if (nbRx == 0)
                {
                    Thread.SpinWait(10);
                    continue;
                }

                for (int i = 0; i < nbRx; i++)
                {
                    IntPtr mbuf = rxMbufs[i];
                    try
                    {
                        IntPtr data = HwInterop.hw_pktmbuf_mtod(mbuf);
                        ushort dataLen = HwInterop.hw_pktmbuf_data_len(mbuf);
                        EtherHdr eth = Marshal.PtrToStructure<EtherHdr>(data);

                        if (eth.EtherType == 0x0008)
                        {
                            IntPtr ipPtr = data + EtherHdr.Size;
                            Ipv4Hdr ip = Marshal.PtrToStructure<Ipv4Hdr>(ipPtr);

                            if (ip.NextProtoId == 17)
                            {
                                IntPtr udpPtr = ipPtr + Ipv4Hdr.Size;
                                UdpHdr udp = Marshal.PtrToStructure<UdpHdr>(udpPtr);

                                ushort dstPort = NetUtils.Ntohs(udp.DstPort);
                                string dstIp = NetUtils.UintToIp(ip.DstAddr);

                                bool pass = true;
                                if (FilterPort != 0 && dstPort != FilterPort)
                                    pass = false;
                                if (!string.IsNullOrEmpty(FilterIp) && dstIp != FilterIp)
                                    pass = false;

                                if (pass)
                                {
                                    int payloadLen = dataLen - EtherHdr.Size - Ipv4Hdr.Size - UdpHdr.Size;
                                    _perfCounter.AddRx(1, dataLen);

                                    string? payloadText = null;
                                    if (payloadLen > 0)
                                    {
                                        IntPtr payloadPtr = udpPtr + UdpHdr.Size;
                                        byte[] payloadBytes = new byte[payloadLen];
                                        Marshal.Copy(payloadPtr, payloadBytes, 0, payloadLen);
                                        payloadText = System.Text.Encoding.ASCII.GetString(payloadBytes).TrimEnd('\0');
                                    }

                                    Logger?.LogRx(ip.SrcAddr, ip.DstAddr,
                                        NetUtils.Ntohs(udp.SrcPort), dstPort,
                                        payloadLen > 0 ? payloadLen : 0, payloadText);

                                    if (PacketQueue.Count < MaxQueueSize)
                                    {
                                        PacketQueue.Enqueue(new RxPacketInfo
                                        {
                                            SrcMac = (byte[])eth.Src.Clone(),
                                            DstMac = (byte[])eth.Dst.Clone(),
                                            SrcIp = NetUtils.UintToIp(ip.SrcAddr),
                                            DstIp = dstIp,
                                            SrcPort = NetUtils.Ntohs(udp.SrcPort),
                                            DstPort = dstPort,
                                            DataLen = payloadLen > 0 ? payloadLen : 0,
                                            PayloadText = payloadText
                                        });
                                    }
                                }
                            }
                        }
                    }
                    catch
                    {
                        _perfCounter.AddErrors(1);
                    }
                    finally
                    {
                        HwInterop.hw_pktmbuf_free(mbuf);
                    }
                }
            }
        }
    }
}
