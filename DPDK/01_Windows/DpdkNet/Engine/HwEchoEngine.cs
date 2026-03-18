using System.Runtime.InteropServices;
using HwNet.Interop;
using HwNet.Logging;
using HwNet.Stats;
using HwNet.Utilities;

namespace HwNet.Engine
{
    public class HwEchoEngine : IHwEngine
    {
        private readonly IHwContext _dpdk;
        private readonly PerformanceCounter _perfCounter;
        private Thread? _echoThread;
        private volatile bool _running;

        public bool IsRunning => _running;
        public string? LastError { get; set; }
        public PacketLogger? Logger { get; set; }

        public HwEchoEngine(IHwContext dpdk, PerformanceCounter perfCounter)
        {
            _dpdk = dpdk;
            _perfCounter = perfCounter;
        }

        public void Start()
        {
            if (_running) return;
            _running = true;
            _echoThread = new Thread(EchoLoop) { IsBackground = true, Name = "DPDK-Echo", Priority = ThreadPriority.Highest };
            _echoThread.Start();
        }

        public void Stop()
        {
            _running = false;
            _echoThread?.Join(2000);
            _echoThread = null;
        }

        public void Dispose()
        {
            Stop();
            GC.SuppressFinalize(this);
        }

        private void EchoLoop()
        {
            if (_dpdk.State != HwState.Ready) return;

            const int BatchSize = 32;
            IntPtr[] rxMbufs = new IntPtr[BatchSize];
            IntPtr[] txMbufs = new IntPtr[BatchSize];

            while (_running)
            {
                ushort nbRx = HwInterop.hw_rx_burst(_dpdk.PortId, 0, rxMbufs, BatchSize);
                if (nbRx == 0)
                {
                    Thread.SpinWait(10);
                    continue;
                }

                int txCount = 0;

                for (int i = 0; i < nbRx; i++)
                {
                    IntPtr mbuf = rxMbufs[i];
                    bool sendBack = false;

                    try
                    {
                        IntPtr data = HwInterop.hw_pktmbuf_mtod(mbuf);
                        ushort dataLen = HwInterop.hw_pktmbuf_data_len(mbuf);
                        EtherHdr eth = Marshal.PtrToStructure<EtherHdr>(data);

                        _perfCounter.AddRx(1, dataLen);

                        if (eth.EtherType == 0x0008)
                        {
                            IntPtr ipPtr = data + EtherHdr.Size;
                            Ipv4Hdr ip = Marshal.PtrToStructure<Ipv4Hdr>(ipPtr);

                            if (ip.NextProtoId == 17)
                            {
                                IntPtr udpPtr = ipPtr + Ipv4Hdr.Size;
                                UdpHdr udp = Marshal.PtrToStructure<UdpHdr>(udpPtr);

                                byte[] tmpMac = eth.Src;
                                eth.Src = eth.Dst;
                                eth.Dst = tmpMac;
                                Marshal.StructureToPtr(eth, data, false);

                                uint tmpIp = ip.SrcAddr;
                                ip.SrcAddr = ip.DstAddr;
                                ip.DstAddr = tmpIp;
                                ip.HdrChecksum = 0;
                                Marshal.StructureToPtr(ip, ipPtr, false);

                                byte[] ipBytes = new byte[Ipv4Hdr.Size];
                                Marshal.Copy(ipPtr, ipBytes, 0, Ipv4Hdr.Size);
                                ip.HdrChecksum = NetUtils.Htons(NetUtils.ComputeIpChecksum(ipBytes));
                                Marshal.StructureToPtr(ip, ipPtr, false);

                                ushort tmpPort = udp.SrcPort;
                                udp.SrcPort = udp.DstPort;
                                udp.DstPort = tmpPort;
                                udp.Cksum = 0;
                                Marshal.StructureToPtr(udp, udpPtr, false);

                                sendBack = true;
                                txMbufs[txCount++] = mbuf;
                            }
                        }
                    }
                    catch
                    {
                        _perfCounter.AddErrors(1);
                    }

                    if (!sendBack)
                        HwInterop.hw_pktmbuf_free(mbuf);
                }

                if (txCount > 0)
                {
                    ushort sent = HwInterop.hw_tx_burst(_dpdk.PortId, 0, txMbufs, (ushort)txCount);
                    _perfCounter.AddTx(sent, 0);

                    for (int k = sent; k < txCount; k++)
                    {
                        HwInterop.hw_pktmbuf_free(txMbufs[k]);
                        _perfCounter.AddDropped(1);
                    }
                }
            }
        }
    }
}
