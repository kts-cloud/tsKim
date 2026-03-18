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
    public class HwUdpReqRespEngine : IHwEngine
    {
        private readonly IHwContext _dpdk;
        private readonly PerformanceCounter _perfCounter;
        private Thread? _thread;
        private volatile bool _running;
        private ReqRespConfig _config = new();
        private ushort _packetId;

        public bool IsRunning => _running;
        public string? LastError { get; set; }
        public PacketLogger? Logger { get; set; }

        public ConcurrentQueue<ReqRespResult> ResultQueue { get; } = new();
        public ConcurrentQueue<string> DiagQueue { get; } = new();
        public RttStats Stats { get; } = new();
        public bool IsCompleted { get; private set; }

        public HwUdpReqRespEngine(IHwContext dpdk, PerformanceCounter perfCounter)
        {
            _dpdk = dpdk;
            _perfCounter = perfCounter;
        }

        public void Start(ReqRespConfig config)
        {
            if (_running) return;
            _config = config;
            Stats.Reset();
            IsCompleted = false;
            _running = true;
            _thread = new Thread(MainLoop) { IsBackground = true, Name = "DPDK-ReqResp", Priority = ThreadPriority.Highest };
            _thread.Start();
        }

        public void Stop()
        {
            _running = false;
            _thread?.Join(3000);
            _thread = null;
        }

        public void Dispose()
        {
            Stop();
            GC.SuppressFinalize(this);
        }

        private void MainLoop()
        {
            try
            {
                MainLoopInner();
            }
            catch (Exception ex)
            {
                LastError = $"ReqResp 스레드 예외: {ex.GetType().Name}: {ex.Message}";
            }
        }

        #region ARP

        private byte[]? ResolveDestMac(uint srcIp, uint dstIp, int timeoutMs = 3000)
        {
            const int RxBatch = 32;
            IntPtr[] rxMbufs = new IntPtr[RxBatch];

            for (int attempt = 0; attempt < 3 && _running; attempt++)
            {
                int pktLen = EtherHdr.Size + ArpHdr.Size;
                IntPtr mbuf = HwInterop.hw_pktmbuf_alloc(_dpdk.MbufPool);
                if (mbuf == IntPtr.Zero) continue;

                IntPtr appendRes = HwInterop.hw_pktmbuf_append(mbuf, (ushort)pktLen);
                if (appendRes == IntPtr.Zero)
                {
                    HwInterop.hw_pktmbuf_free(mbuf);
                    continue;
                }

                IntPtr data = HwInterop.hw_pktmbuf_mtod(mbuf);

                var eth = new EtherHdr
                {
                    Dst = new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF },
                    Src = (byte[])_dpdk.LocalMac.Clone(),
                    EtherType = 0x0608
                };
                Marshal.StructureToPtr(eth, data, false);

                var arp = new ArpHdr
                {
                    HardwareType = 0x0100,
                    ProtocolType = 0x0008,
                    HardwareLen = 6,
                    ProtocolLen = 4,
                    Opcode = 0x0100,
                    SenderMac = (byte[])_dpdk.LocalMac.Clone(),
                    SenderIp = srcIp,
                    TargetMac = new byte[6],
                    TargetIp = dstIp
                };
                Marshal.StructureToPtr(arp, data + EtherHdr.Size, false);

                IntPtr[] txBuf = { mbuf };
                ushort sent = HwInterop.hw_tx_burst(_dpdk.PortId, 0, txBuf, 1);
                if (sent == 0)
                {
                    HwInterop.hw_pktmbuf_free(mbuf);
                    continue;
                }

                DiagQueue.Enqueue($"[ARP] ARP Request 전송 → {_config.DstIp} (시도 {attempt + 1}/3)");

                long deadline = System.Diagnostics.Stopwatch.GetTimestamp() +
                    (long)(1000.0 / 1000.0 * System.Diagnostics.Stopwatch.Frequency);

                while (_running && System.Diagnostics.Stopwatch.GetTimestamp() < deadline)
                {
                    ushort nbRx = HwInterop.hw_rx_burst(_dpdk.PortId, 0, rxMbufs, RxBatch);
                    for (int i = 0; i < nbRx; i++)
                    {
                        IntPtr rxMbuf = rxMbufs[i];
                        try
                        {
                            IntPtr rxData = HwInterop.hw_pktmbuf_mtod(rxMbuf);
                            ushort rxDataLen = HwInterop.hw_pktmbuf_data_len(rxMbuf);
                            EtherHdr rxEth = Marshal.PtrToStructure<EtherHdr>(rxData);

                            if (rxEth.EtherType != 0x0608 || rxDataLen < EtherHdr.Size + ArpHdr.Size)
                                continue;

                            ArpHdr rxArp = Marshal.PtrToStructure<ArpHdr>(rxData + EtherHdr.Size);
                            ushort opcode = NetUtils.Ntohs(rxArp.Opcode);

                            if (opcode == 2 && rxArp.SenderIp == dstIp && rxArp.SenderMac != null)
                            {
                                byte[] mac = (byte[])rxArp.SenderMac.Clone();
                                DiagQueue.Enqueue($"[ARP] MAC 학습 완료: {_config.DstIp} = {NetUtils.FormatMac(mac)}");
                                for (int j = i + 1; j < nbRx; j++)
                                    HwInterop.hw_pktmbuf_free(rxMbufs[j]);
                                return mac;
                            }
                        }
                        finally { HwInterop.hw_pktmbuf_free(rxMbuf); }
                    }

                    if (nbRx == 0)
                        Thread.SpinWait(10);
                }
            }

            return null;
        }

        private void SendGratuitousArp(uint ourIp)
        {
            int pktLen = EtherHdr.Size + ArpHdr.Size;
            IntPtr mbuf = HwInterop.hw_pktmbuf_alloc(_dpdk.MbufPool);
            if (mbuf == IntPtr.Zero) return;

            IntPtr appendRes = HwInterop.hw_pktmbuf_append(mbuf, (ushort)pktLen);
            if (appendRes == IntPtr.Zero)
            {
                HwInterop.hw_pktmbuf_free(mbuf);
                return;
            }

            IntPtr data = HwInterop.hw_pktmbuf_mtod(mbuf);

            var eth = new EtherHdr
            {
                Dst = new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF },
                Src = (byte[])_dpdk.LocalMac.Clone(),
                EtherType = 0x0608
            };
            Marshal.StructureToPtr(eth, data, false);

            var arp = new ArpHdr
            {
                HardwareType = 0x0100,
                ProtocolType = 0x0008,
                HardwareLen = 6,
                ProtocolLen = 4,
                Opcode = 0x0100,
                SenderMac = (byte[])_dpdk.LocalMac.Clone(),
                SenderIp = ourIp,
                TargetMac = new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF },
                TargetIp = ourIp
            };
            Marshal.StructureToPtr(arp, data + EtherHdr.Size, false);

            IntPtr[] txBuf = { mbuf };
            ushort sent = HwInterop.hw_tx_burst(_dpdk.PortId, 0, txBuf, 1);
            if (sent == 0)
                HwInterop.hw_pktmbuf_free(mbuf);
        }

        private void HandleArpIfNeeded(IntPtr rxData, ushort rxDataLen, uint ourIp)
        {
            if (rxDataLen < EtherHdr.Size + ArpHdr.Size) return;

            IntPtr arpPtr = rxData + EtherHdr.Size;
            ArpHdr arp = Marshal.PtrToStructure<ArpHdr>(arpPtr);

            ushort opcode = NetUtils.Ntohs(arp.Opcode);
            if (opcode != 1) return;

            int replyLen = EtherHdr.Size + ArpHdr.Size;
            IntPtr replyMbuf = HwInterop.hw_pktmbuf_alloc(_dpdk.MbufPool);
            if (replyMbuf == IntPtr.Zero) return;

            IntPtr appendRes = HwInterop.hw_pktmbuf_append(replyMbuf, (ushort)replyLen);
            if (appendRes == IntPtr.Zero)
            {
                HwInterop.hw_pktmbuf_free(replyMbuf);
                return;
            }

            IntPtr replyData = HwInterop.hw_pktmbuf_mtod(replyMbuf);

            var replyEth = new EtherHdr
            {
                Dst = (byte[])arp.SenderMac.Clone(),
                Src = (byte[])_dpdk.LocalMac.Clone(),
                EtherType = 0x0608
            };
            Marshal.StructureToPtr(replyEth, replyData, false);

            var replyArp = new ArpHdr
            {
                HardwareType = 0x0100,
                ProtocolType = 0x0008,
                HardwareLen = 6,
                ProtocolLen = 4,
                Opcode = 0x0200,
                SenderMac = (byte[])_dpdk.LocalMac.Clone(),
                SenderIp = arp.TargetIp,
                TargetMac = (byte[])arp.SenderMac.Clone(),
                TargetIp = arp.SenderIp
            };
            Marshal.StructureToPtr(replyArp, replyData + EtherHdr.Size, false);

            IntPtr[] txBuf = { replyMbuf };
            ushort txSent = HwInterop.hw_tx_burst(_dpdk.PortId, 0, txBuf, 1);
            if (txSent == 0)
                HwInterop.hw_pktmbuf_free(replyMbuf);
        }

        #endregion

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetCurrentThread();
        [DllImport("kernel32.dll")]
        private static extern IntPtr SetThreadAffinityMask(IntPtr hThread, IntPtr dwThreadAffinityMask);

        private void MainLoopInner()
        {
            try
            {
                int coreCount = Environment.ProcessorCount;
                if (coreCount >= 2)
                {
                    IntPtr mask = new IntPtr(1 << 1);
                    SetThreadAffinityMask(GetCurrentThread(), mask);
                }
            }
            catch { }

            if (_dpdk.State != HwState.Ready) return;

            int totalHdrLen = EtherHdr.Size + Ipv4Hdr.Size + UdpHdr.Size;
            int pktLen = totalHdrLen + _config.PayloadSize;
            uint srcIp = NetUtils.IpToUint(_config.SrcIp);
            uint dstIp = NetUtils.IpToUint(_config.DstIp);
            long timeoutTicks = (long)(_config.TimeoutMs / 1000.0 * System.Diagnostics.Stopwatch.Frequency);
            uint seqNum = 0;

            DiagQueue.Enqueue($"[INFO] {_config.SrcIp}:{_config.SrcPort} → {_config.DstIp}:{_config.DstPort} payload={_config.PayloadSize}B text=\"{_config.PayloadText}\" timeout={_config.TimeoutMs}ms");

            byte[] dstMac = _config.DstMac;
            bool needArpDiscovery = dstMac.All(b => b == 0) || dstMac.All(b => b == 0xFF);

            if (needArpDiscovery)
            {
                DiagQueue.Enqueue($"[ARP] DstMac 자동 탐색 중... ({_config.DstIp})");
                byte[]? resolved = ResolveDestMac(srcIp, dstIp);
                if (resolved != null)
                {
                    dstMac = resolved;
                }
                else
                {
                    DiagQueue.Enqueue($"[ARP] MAC 탐색 실패 — UI에서 DstMac을 수동 입력하세요");
                    LastError = $"ARP 실패: {_config.DstIp}의 MAC을 찾을 수 없습니다";
                    return;
                }
            }
            else
            {
                DiagQueue.Enqueue($"[INFO] DstMac={NetUtils.FormatMac(dstMac)}");
            }

            for (int g = 0; g < 3; g++)
            {
                SendGratuitousArp(srcIp);
                if (g < 2) Thread.Sleep(100);
            }

            byte[] templatePkt = new byte[pktLen];
            var pinHandle = GCHandle.Alloc(templatePkt, GCHandleType.Pinned);
            try
            {
                IntPtr tmpl = pinHandle.AddrOfPinnedObject();

                var eth = new EtherHdr
                {
                    Dst = (byte[])dstMac.Clone(),
                    Src = (byte[])_dpdk.LocalMac.Clone(),
                    EtherType = 0x0008
                };
                Marshal.StructureToPtr(eth, tmpl, false);

                ushort udpLen = (ushort)(UdpHdr.Size + _config.PayloadSize);
                var ip = new Ipv4Hdr
                {
                    VersionIhl = 0x45,
                    TypeOfService = 0,
                    TotalLength = NetUtils.Htons((ushort)(Ipv4Hdr.Size + UdpHdr.Size + _config.PayloadSize)),
                    PacketId = 0,
                    FragmentOffset = 0,
                    TimeToLive = 64,
                    NextProtoId = 17,
                    HdrChecksum = 0,
                    SrcAddr = srcIp,
                    DstAddr = dstIp
                };
                Marshal.StructureToPtr(ip, tmpl + EtherHdr.Size, false);

                byte[] ipHdrTmp = new byte[Ipv4Hdr.Size];
                Marshal.Copy(tmpl + EtherHdr.Size, ipHdrTmp, 0, Ipv4Hdr.Size);
                ip.HdrChecksum = NetUtils.Htons(NetUtils.ComputeIpChecksum(ipHdrTmp));
                Marshal.StructureToPtr(ip, tmpl + EtherHdr.Size, false);

                var udp = new UdpHdr
                {
                    SrcPort = NetUtils.Htons(_config.SrcPort),
                    DstPort = NetUtils.Htons(_config.DstPort),
                    Len = NetUtils.Htons(udpLen),
                    Cksum = 0
                };
                Marshal.StructureToPtr(udp, tmpl + EtherHdr.Size + Ipv4Hdr.Size, false);

                IntPtr payPtr = tmpl + totalHdrLen;
                if (!string.IsNullOrEmpty(_config.PayloadText))
                {
                    byte[] textBytes = System.Text.Encoding.ASCII.GetBytes(_config.PayloadText);
                    int copyLen = Math.Min(textBytes.Length, _config.PayloadSize);
                    Marshal.Copy(textBytes, 0, payPtr, copyLen);
                    for (int p = copyLen; p < _config.PayloadSize; p++)
                        Marshal.WriteByte(payPtr, p, 0);
                }
                else
                {
                    for (int p = 0; p < _config.PayloadSize; p++)
                        Marshal.WriteByte(payPtr, p, (byte)(p & 0xFF));
                }
            }
            finally { pinHandle.Free(); }

            int repeatCount = _config.RepeatCount;
            int windowSize = _config.WindowSize;
            byte[] localMac = (byte[])_dpdk.LocalMac.Clone();

            if (_config.EnableWarmup)
            {
                const int WarmupCount = 64;
                IntPtr[] warmMbufs = new IntPtr[32];
                int warmSent = 0;
                for (int w = 0; w < WarmupCount; w += 32)
                {
                    int batch = Math.Min(32, WarmupCount - w);
                    int allocated = 0;
                    for (int b = 0; b < batch; b++)
                    {
                        IntPtr mb = HwInterop.hw_pktmbuf_alloc(_dpdk.MbufPool);
                        if (mb == IntPtr.Zero) break;
                        IntPtr ap = HwInterop.hw_pktmbuf_append(mb, (ushort)pktLen);
                        if (ap == IntPtr.Zero) { HwInterop.hw_pktmbuf_free(mb); break; }
                        Marshal.Copy(templatePkt, 0, HwInterop.hw_pktmbuf_mtod(mb), pktLen);
                        warmMbufs[allocated++] = mb;
                    }
                    if (allocated > 0)
                    {
                        ushort sent = HwInterop.hw_tx_burst(_dpdk.PortId, 0, warmMbufs, (ushort)allocated);
                        for (int k = sent; k < allocated; k++)
                            HwInterop.hw_pktmbuf_free(warmMbufs[k]);
                        warmSent += sent;
                    }
                }
                Thread.Sleep(50);
                IntPtr[] drainBuf = new IntPtr[32];
                for (int d = 0; d < 10; d++)
                {
                    ushort nb = HwInterop.hw_rx_burst(_dpdk.PortId, 0, drainBuf, 32);
                    for (int i = 0; i < nb; i++)
                        HwInterop.hw_pktmbuf_free(drainBuf[i]);
                    if (nb == 0) break;
                }
                DiagQueue.Enqueue($"[워밍업] TX {warmSent}패킷 전송 완료 (NIC/DMA/캐시 워밍업)");
            }
            else
            {
                DiagQueue.Enqueue("[워밍업] 비활성화됨");
            }

            if (windowSize <= 1)
            {
                DiagQueue.Enqueue("[모드] 동기 Req/Resp (Window=1)");
                byte[] respBuf = new byte[2048];
                var nativeResult = new HwReqRespResult();

                while (_running)
                {
                    if (repeatCount > 0 && seqNum >= (uint)repeatCount)
                    { IsCompleted = true; break; }

                    ushort pktId = _packetId++;
                    HwInterop.hw_reqresp_once(
                        _dpdk.PortId, _dpdk.MbufPool,
                        templatePkt, (ushort)pktLen, pktId,
                        dstIp, _config.SrcPort, _config.TimeoutMs,
                        respBuf, (ushort)respBuf.Length,
                        ref nativeResult, localMac, srcIp);

                    if (nativeResult.Status == 0)
                    {
                        _perfCounter.AddTx(1, pktLen);
                        _perfCounter.AddRx(1, pktLen);
                        Stats.AddSent();
                        Stats.AddReceived(nativeResult.RttMs);

                        string? respText = nativeResult.RespLen > 0
                            ? System.Text.Encoding.ASCII.GetString(respBuf, 0, nativeResult.RespLen).TrimEnd('\0')
                            : null;
                        Logger?.LogReqResp(srcIp, dstIp, _config.SrcPort, _config.DstPort,
                            _config.PayloadSize, _config.PayloadText, nativeResult.RttMs, 0,
                            respText, nativeResult.RespLen);
                        seqNum++;
                    }
                    else if (nativeResult.Status == 1)
                    {
                        _perfCounter.AddTx(1, pktLen);
                        Stats.AddSent();
                        Stats.AddTimeout();
                        Logger?.LogReqResp(srcIp, dstIp, _config.SrcPort, _config.DstPort,
                            _config.PayloadSize, _config.PayloadText, _config.TimeoutMs, 1);
                        seqNum++;

                        if (ResultQueue.Count < 10000)
                            ResultQueue.Enqueue(new ReqRespResult
                            {
                                SeqNumber = seqNum, Success = false,
                                RttMs = _config.TimeoutMs
                            });
                    }
                    else { _perfCounter.AddDropped(1); }
                }
            }
            else
            {
                DiagQueue.Enqueue($"[모드] 파이프라인 Req/Resp (Window={windowSize})");
                var batchStats = new HwBatchStats();

                while (_running)
                {
                    int remaining = repeatCount > 0 ? repeatCount - (int)seqNum : windowSize;
                    int batchCount = Math.Min(windowSize, remaining);
                    if (batchCount <= 0) { IsCompleted = true; break; }

                    ushort startId = _packetId;
                    _packetId += (ushort)batchCount;

                    HwInterop.hw_reqresp_batch(
                        _dpdk.PortId, _dpdk.MbufPool,
                        templatePkt, (ushort)pktLen,
                        startId, (ushort)batchCount,
                        dstIp, _config.SrcPort, _config.TimeoutMs,
                        ref batchStats, localMac, srcIp);

                    _perfCounter.AddTx(batchStats.Sent, batchStats.Sent * pktLen);
                    _perfCounter.AddRx(batchStats.Received, batchStats.Received * pktLen);

                    int timeouts = batchStats.Sent - batchStats.Received;
                    Stats.AddBatch(batchStats.Sent, batchStats.Received, timeouts,
                        batchStats.TotalRttMs, batchStats.TotalRttSqMs,
                        batchStats.MinRttMs, batchStats.MaxRttMs);

                    double avgRtt = batchStats.Received > 0
                        ? batchStats.TotalRttMs / batchStats.Received : 0;
                    Logger?.LogReqResp(srcIp, dstIp, _config.SrcPort, _config.DstPort,
                        _config.PayloadSize, _config.PayloadText, avgRtt,
                        timeouts > 0 ? (byte)1 : (byte)0);

                    seqNum += batchStats.Sent;

                    if (timeouts > 0 && ResultQueue.Count < 10000)
                        ResultQueue.Enqueue(new ReqRespResult
                        {
                            SeqNumber = seqNum,
                            Success = false,
                            RttMs = (double)_config.TimeoutMs
                        });
                }
            }
        }
    }
}
