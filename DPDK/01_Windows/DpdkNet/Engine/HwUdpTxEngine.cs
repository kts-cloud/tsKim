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
    public class HwUdpTxEngine : IHwEngine
    {
        private readonly IHwContext _dpdk;
        private readonly PerformanceCounter _perfCounter;
        private Thread? _txThread;
        private volatile bool _running;
        private TxConfig _config = new();
        private ushort _packetId;

        public bool IsRunning => _running;
        public string? LastError { get; set; }
        public PacketLogger? Logger { get; set; }

        public ConcurrentQueue<RxPacketInfo> ResponseQueue { get; } = new();

        public HwUdpTxEngine(IHwContext dpdk, PerformanceCounter perfCounter)
        {
            _dpdk = dpdk;
            _perfCounter = perfCounter;
        }

        public void Start(TxConfig config)
        {
            if (_running) return;
            _config = config;
            _running = true;
            _txThread = new Thread(TxLoop) { IsBackground = true, Name = "DPDK-TX", Priority = ThreadPriority.Highest };
            _txThread.Start();
        }

        public void Stop()
        {
            _running = false;
            _txThread?.Join(2000);
            _txThread = null;
        }

        public void Dispose()
        {
            Stop();
            GC.SuppressFinalize(this);
        }

        private void TxLoop()
        {
            try
            {
                TxLoopInner();
            }
            catch (Exception ex)
            {
                LastError = $"TX 스레드 예외: {ex.GetType().Name}: {ex.Message}";
                System.Diagnostics.Debug.WriteLine(LastError);
            }
        }

        private void TxLoopInner()
        {
            if (_dpdk.State != HwState.Ready) return;

            const int BatchSize = 32;
            IntPtr[] txMbufs = new IntPtr[BatchSize];
            int totalHdrLen = EtherHdr.Size + Ipv4Hdr.Size + UdpHdr.Size;
            int pktLen = totalHdrLen + _config.PayloadSize;

            uint srcIp = NetUtils.IpToUint(_config.SrcIp);
            uint dstIp = NetUtils.IpToUint(_config.DstIp);

            bool rateLimit = _config.TargetPps > 0;
            long ticksPerPacket = rateLimit
                ? System.Diagnostics.Stopwatch.Frequency / _config.TargetPps
                : 0;
            long nextSendTick = System.Diagnostics.Stopwatch.GetTimestamp();

            int _diagIter = 0;
            bool _firstFailLogged = false;

            while (_running)
            {
                if (rateLimit)
                {
                    long now = System.Diagnostics.Stopwatch.GetTimestamp();
                    if (now < nextSendTick)
                    {
                        Thread.SpinWait(10);
                        continue;
                    }
                }

                int batchCount = 0;
                int batchTarget = rateLimit ? 1 : BatchSize;

                for (int b = 0; b < batchTarget; b++)
                {
                    IntPtr mbuf = HwInterop.hw_pktmbuf_alloc(_dpdk.MbufPool);
                    if (mbuf == IntPtr.Zero)
                    {
                        if (!_firstFailLogged) { LastError = $"[DIAG-TX] iter={_diagIter} alloc FAIL at b={b}"; _firstFailLogged = true; }
                        _perfCounter.AddDropped(1);
                        break;
                    }

                    IntPtr appendResult = HwInterop.hw_pktmbuf_append(mbuf, (ushort)pktLen);
                    if (appendResult == IntPtr.Zero)
                    {
                        if (!_firstFailLogged) { LastError = $"[DIAG-TX] iter={_diagIter} append FAIL pktLen={pktLen}"; _firstFailLogged = true; }
                        HwInterop.hw_pktmbuf_free(mbuf);
                        _perfCounter.AddDropped(1);
                        break;
                    }

                    IntPtr data = HwInterop.hw_pktmbuf_mtod(mbuf);

                    var eth = new EtherHdr
                    {
                        Dst = (byte[])_config.DstMac.Clone(),
                        Src = (byte[])_dpdk.LocalMac.Clone(),
                        EtherType = 0x0008
                    };
                    Marshal.StructureToPtr(eth, data, false);

                    IntPtr ipPtr = data + EtherHdr.Size;
                    var ip = new Ipv4Hdr
                    {
                        VersionIhl = 0x45,
                        TypeOfService = 0,
                        TotalLength = NetUtils.Htons((ushort)(Ipv4Hdr.Size + UdpHdr.Size + _config.PayloadSize)),
                        PacketId = NetUtils.Htons(_packetId++),
                        FragmentOffset = 0,
                        TimeToLive = 64,
                        NextProtoId = 17,
                        HdrChecksum = 0,
                        SrcAddr = srcIp,
                        DstAddr = dstIp
                    };

                    int ipHdrSize = Ipv4Hdr.Size;
                    byte[] ipBytes = new byte[ipHdrSize];
                    Marshal.StructureToPtr(ip, ipPtr, false);
                    Marshal.Copy(ipPtr, ipBytes, 0, ipHdrSize);
                    ip.HdrChecksum = NetUtils.Htons(NetUtils.ComputeIpChecksum(ipBytes));
                    Marshal.StructureToPtr(ip, ipPtr, false);

                    IntPtr udpPtr = ipPtr + Ipv4Hdr.Size;
                    var udp = new UdpHdr
                    {
                        SrcPort = NetUtils.Htons(_config.SrcPort),
                        DstPort = NetUtils.Htons(_config.DstPort),
                        Len = NetUtils.Htons((ushort)(UdpHdr.Size + _config.PayloadSize)),
                        Cksum = 0
                    };
                    Marshal.StructureToPtr(udp, udpPtr, false);

                    IntPtr payloadPtr = udpPtr + UdpHdr.Size;
                    if (!string.IsNullOrEmpty(_config.PayloadText))
                    {
                        byte[] textBytes = System.Text.Encoding.ASCII.GetBytes(_config.PayloadText);
                        int copyLen = Math.Min(textBytes.Length, _config.PayloadSize);
                        Marshal.Copy(textBytes, 0, payloadPtr, copyLen);
                        for (int p = copyLen; p < _config.PayloadSize; p++)
                            Marshal.WriteByte(payloadPtr, p, 0);
                    }
                    else
                    {
                        for (int p = 0; p < _config.PayloadSize; p++)
                            Marshal.WriteByte(payloadPtr, p, (byte)(p & 0xFF));
                    }

                    txMbufs[batchCount++] = mbuf;
                }

                if (batchCount > 0)
                {
                    ushort sent = HwInterop.hw_tx_burst(_dpdk.PortId, 0, txMbufs, (ushort)batchCount);
                    _perfCounter.AddTx(sent, (long)sent * pktLen);
                    if (sent > 0)
                        Logger?.LogTx(srcIp, dstIp, _config.SrcPort, _config.DstPort,
                            _config.PayloadSize, _config.PayloadText);

                    if (sent < batchCount && !_firstFailLogged)
                    {
                        LastError = $"[DIAG-TX] iter={_diagIter} tx_burst partial: batch={batchCount} sent={sent}";
                        _firstFailLogged = true;
                    }

                    for (int k = sent; k < batchCount; k++)
                    {
                        HwInterop.hw_pktmbuf_free(txMbufs[k]);
                        _perfCounter.AddDropped(1);
                    }

                    if (rateLimit)
                        nextSendTick += ticksPerPacket * sent;
                }

                _diagIter++;

                PollRxResponses();
            }
        }

        private void PollRxResponses()
        {
            const int RxBatch = 32;
            IntPtr[] rxMbufs = new IntPtr[RxBatch];

            ushort nbRx = HwInterop.hw_rx_burst(_dpdk.PortId, 0, rxMbufs, RxBatch);
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

                            int payloadLen = dataLen - EtherHdr.Size - Ipv4Hdr.Size - UdpHdr.Size;
                            string? payloadText = null;
                            if (payloadLen > 0)
                            {
                                IntPtr payloadPtr = udpPtr + UdpHdr.Size;
                                byte[] payloadBytes = new byte[payloadLen];
                                Marshal.Copy(payloadPtr, payloadBytes, 0, payloadLen);
                                payloadText = System.Text.Encoding.ASCII.GetString(payloadBytes).TrimEnd('\0');
                            }

                            _perfCounter.AddRx(1, dataLen);
                            Logger?.LogRx(ip.SrcAddr, ip.DstAddr,
                                NetUtils.Ntohs(udp.SrcPort), NetUtils.Ntohs(udp.DstPort),
                                payloadLen > 0 ? payloadLen : 0, payloadText);
                            if (ResponseQueue.Count < 10000)
                            {
                                ResponseQueue.Enqueue(new RxPacketInfo
                                {
                                    SrcIp = NetUtils.UintToIp(ip.SrcAddr),
                                    DstIp = NetUtils.UintToIp(ip.DstAddr),
                                    SrcPort = NetUtils.Ntohs(udp.SrcPort),
                                    DstPort = NetUtils.Ntohs(udp.DstPort),
                                    DataLen = payloadLen > 0 ? payloadLen : 0,
                                    PayloadText = payloadText
                                });
                            }
                        }
                    }
                }
                catch { _perfCounter.AddErrors(1); }
                finally { HwInterop.hw_pktmbuf_free(mbuf); }
            }
        }
    }
}
