// =============================================================================
// PgDpdkServer.cs
// DPDK kernel-bypass transport for DP860 pattern generator communication.
// Implements IPgTransport using DpdkNet library for low-latency UDP.
// Namespace: Dongaeltek.ITOLED.Hardware.PatternGenerator
// =============================================================================

using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using HwNet;
using HwNet.Utilities;

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

/// <summary>
/// DPDK kernel-bypass transport for DP860 pattern generator communication.
/// Uses DpdkNet library for ~0.1ms RTT UDP communication.
/// Falls back to <see cref="PgUdpServer"/> if DPDK initialization fails.
/// </summary>
public sealed class PgDpdkServer : IPgTransport
{
    // =========================================================================
    // Constants
    // =========================================================================

    private const int DebugLogMsgTypeInspect = 0;
    private const int MaxRxBurst = 32;
    private const int ArpTimeoutMs = 3000;
    private const int ArpRetries = 3;
    private const ushort EtherTypeIpv4 = 0x0008; // network byte order
    private const ushort EtherTypeArp = 0x0608;  // network byte order
    private const byte IpProtoUdp = 17;

    // =========================================================================
    // Fields
    // =========================================================================

    private readonly ILogger _logger;
    private readonly CommPgDriver[] _pgDrivers;
    private readonly HwManager _dpdk;

    /// <summary>Resolved MAC addresses per PG index.</summary>
    private readonly byte[][] _pgMacCache;

    /// <summary>Local MAC address from DPDK port.</summary>
    private readonly byte[] _localMac;

    /// <summary>Local IP as network-byte-order uint.</summary>
    private readonly uint _localIpNet;

    /// <summary>Per-PG local port numbers (PcPortBase + 1 + pgIndex).</summary>
    private readonly int[] _localPorts;

    /// <summary>Per-channel enable flags (skip ARP for disabled channels).</summary>
    private readonly bool[] _enabledChannels;

    /// <summary>Per-CH send timestamp for lock-free latency measurement.</summary>
    private long[] _sendTimestamps = Array.Empty<long>();

    /// <summary>IP (ReadUInt32BE format) → PG index lookup for fast RX dispatch.</summary>
    private Dictionary<uint, int> _ipToPgMap = new();

    /// <summary>TX serialization (DPDK TX queue is not thread-safe).</summary>
    private readonly object _txLock = new();


    /// <summary>RX polling thread.</summary>
    private Thread? _rxThread;
    private volatile bool _running;
    private volatile bool _txPaused;
    private readonly object _pauseLock = new();
    private bool _disposed;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a new DPDK-based PG transport.
    /// </summary>
    /// <param name="logger">Application logger.</param>
    /// <param name="pgDrivers">Array of PG drivers (same as PgUdpServer).</param>
    /// <param name="dpdk">Initialized HwManager instance.</param>
    /// <param name="enabledChannels">Per-channel enable flags (USE_CH). Null = all enabled.</param>
    /// <param name="enableWarmup">Send 64 dummy packets to prime NIC/DMA/CPU caches.</param>
    public PgDpdkServer(ILogger logger, CommPgDriver[] pgDrivers, HwManager dpdk,
        bool[]? enabledChannels = null, bool enableWarmup = true)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _pgDrivers = pgDrivers ?? throw new ArgumentNullException(nameof(pgDrivers));
        _dpdk = dpdk ?? throw new ArgumentNullException(nameof(dpdk));
        _enabledChannels = enabledChannels ?? Enumerable.Repeat(true, pgDrivers.Length).ToArray();

        _logger.Info("[PgDpdkServer] 생성자 진입");

        if (_dpdk.State != HwState.Ready)
            throw new InvalidOperationException("HwManager must be in Ready state");

        _logger.Info($"[PgDpdkServer] LocalMac={NetUtils.FormatMac(_dpdk.LocalMac)}, PortId={_dpdk.PortId}");
        _localMac = _dpdk.LocalMac;
        _localIpNet = NetUtils.Htonl(NetUtils.IpToUint(Dp860Network.PcIpAddr));
        _pgMacCache = new byte[pgDrivers.Length][];
        _localPorts = new int[pgDrivers.Length];

        for (int i = 0; i < pgDrivers.Length; i++)
        {
            _localPorts[i] = Dp860Network.PcPortBase + 1 + i;
        }
        _sendTimestamps = new long[pgDrivers.Length];
        for (int i = 0; i < pgDrivers.Length; i++)
        {
            var ipBe = NetUtils.Htonl(NetUtils.IpToUint(pgDrivers[i].PgIpAddress));
            _ipToPgMap[ipBe] = i;
        }
        _logger.Info($"[PgDpdkServer] PG count={pgDrivers.Length}, LocalIP={Dp860Network.PcIpAddr}");

        // Resolve MAC addresses for each PG via ARP
        _logger.Info("[PgDpdkServer] ARP 해석 시작...");
        ResolveAllPgMacs();
        _logger.Info("[PgDpdkServer] ARP 해석 완료");

        // Send gratuitous ARP so PGs know our MAC
        _logger.Info("[PgDpdkServer] GARP 전송...");
        SendGratuitousArp();
        _logger.Info("[PgDpdkServer] GARP 전송 완료");

        // DPDK warmup: send dummy packets to prime NIC/DMA/CPU caches
        if (enableWarmup)
            PerformDpdkWarmup();

        // Start RX polling thread
        _running = true;
        _rxThread = new Thread(RxPollLoop)
        {
            Name = "PgDpdkServer_RX",
            IsBackground = true,
            Priority = ThreadPriority.Highest
        };
        _rxThread.Start();

        _logger.Info($"PgDpdkServer started: {pgDrivers.Length} PG(s), DPDK port {_dpdk.PortId}");
    }

    /// <summary>
    /// Exposes the HwManager for DpdkFtpEngine creation.
    /// </summary>
    public HwManager Dpdk => _dpdk;

    // =========================================================================
    // Pause/Resume for Exclusive FTP Access
    // =========================================================================

    /// <summary>
    /// Pauses the RX polling thread to allow exclusive FTP access via DpdkFtpEngine.
    /// TX is also blocked to prevent queue contention with lwIP.
    /// </summary>
    public void PauseRxPolling()
    {
        lock (_pauseLock)
        {
            if (!_running) return;
            _running = false;
            _txPaused = true;
            _rxThread?.Join(5000);
            _rxThread = null;
            _logger.Info("[PgDpdkServer] RX polling paused for FTP");
        }
    }

    /// <summary>
    /// Resumes the RX polling thread after FTP access is released.
    /// </summary>
    public void ResumeRxPolling()
    {
        lock (_pauseLock)
        {
            if (_running || _disposed) return;
            _running = true;
            _txPaused = false;
            _rxThread = new Thread(RxPollLoop)
            {
                Name = "PgDpdkServer_RX",
                IsBackground = true,
                Priority = ThreadPriority.Highest
            };
            _rxThread.Start();
            _logger.Info("[PgDpdkServer] RX polling resumed after FTP");
        }
    }

    // =========================================================================
    // IPgTransport Implementation
    // =========================================================================

    /// <inheritdoc/>
    public void Send(int bindIdx, int pgIndex, string data)
    {
        if (_disposed) return;
        if (_txPaused) return;
        if (pgIndex < 0 || pgIndex >= _pgDrivers.Length) return;

        var driver = _pgDrivers[pgIndex];
        var peerIpStr = driver.PgIpAddress;
        var peerPort = driver.PgIpPort;

        // Determine local port
        int localPort;
        if (bindIdx >= _pgDrivers.Length)
            localPort = Dp860Network.PcPortBase; // base port
        else if (bindIdx >= 0 && bindIdx < _pgDrivers.Length)
            localPort = _localPorts[bindIdx]; // per-PG port
        else
            return;

        // Debug log (skip pg.status)
        if (!data.Contains("pg.status", StringComparison.OrdinalIgnoreCase))
        {
            DebugLog(pgIndex, DebugLogMsgTypeInspect, "TX",
                localPort.ToString(), peerPort.ToString(), data);
        }

        // Maintenance TX event
        if (driver.IsMainter)
        {
            driver.RaiseTxMaintEventPg(pgIndex, localPort.ToString(), peerPort.ToString(), data);
        }

        try
        {
            var payload = Encoding.ASCII.GetBytes(data);
            var dstIpNet = NetUtils.Htonl(NetUtils.IpToUint(peerIpStr));
            var dstMac = _pgMacCache[pgIndex] ?? new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };

            // Record TX timestamp for RTT measurement (lock-free per-CH array)
            Interlocked.Exchange(ref _sendTimestamps[pgIndex], Stopwatch.GetTimestamp());

            // Async TX: non-blocking, RX thread handles response per-CH independently
            SendUdpPacket(dstMac, dstIpNet, (ushort)localPort, (ushort)peerPort, payload);
        }
        catch (Exception ex)
        {
            driver.PublishTestWindow(DefCommon.MsgModeWorking, DefCommon.LogTypeNg,
                $"DpdkSvrSend : Error : {ex.Message}");
            DebugLog(pgIndex, DebugLogMsgTypeInspect, "TX",
                localPort.ToString(), peerPort.ToString(), data + " ...TX_NG");

            if (driver.IsMainter)
            {
                driver.RaiseTxMaintEventPg(pgIndex, localPort.ToString(),
                    peerPort.ToString(), data + " ...TX_NG");
            }
        }
    }

    // =========================================================================
    // Synchronous Send-and-Receive (native hw_reqresp_once_mc)
    // Entire TX→RX→match loop runs in native C — no C# parsing overhead
    // =========================================================================

    private int _packetId;
    private readonly object _rxExclusiveLock = new(); // 상호 배제: DispatchPoll vs hw_reqresp_once_mc
    [ThreadStatic] private static byte[]? t_respBuf;

    public (int status, string response, long rttUs) SendAndReceive(
        int bindIdx, int pgIndex, string data, int timeoutMs)
    {
        if (_disposed || pgIndex < 0 || pgIndex >= _pgDrivers.Length)
            return (-1, string.Empty, 0);

        var driver = _pgDrivers[pgIndex];
        var peerIpStr = driver.PgIpAddress;
        var peerPort = driver.PgIpPort;
        int localPort = (bindIdx >= _pgDrivers.Length)
            ? Dp860Network.PcPortBase
            : _localPorts[bindIdx];

        // Debug log TX
        if (!data.Contains("pg.status", StringComparison.OrdinalIgnoreCase))
            DebugLog(pgIndex, DebugLogMsgTypeInspect, "TX", localPort.ToString(), peerPort.ToString(), data);

        // Maintenance TX event
        if (driver.IsMainter)
            driver.RaiseTxMaintEventPg(pgIndex, localPort.ToString(), peerPort.ToString(), data);

        try
        {
            var payload = Encoding.ASCII.GetBytes(data);
            var dstIpNet = NetUtils.Htonl(NetUtils.IpToUint(peerIpStr));
            var dstMac = _pgMacCache[pgIndex] ?? new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };

            // Build full Ethernet/IP/UDP frame
            var templatePkt = BuildUdpPacket(dstMac, dstIpNet, (ushort)localPort, (ushort)peerPort, payload);

            // Reuse response buffer (thread-local)
            t_respBuf ??= new byte[4096];

            var result = new HwNet.Models.ReqRespNativeResult();
            var pid = Interlocked.Increment(ref _packetId);

            // Expected src IP = raw memcpy representation (IpToUint returns bytes matching
            // what C's memcpy(&rx_src_ip, packet+offset, 4) reads on x86 little-endian).
            // Do NOT use Htonl — dstIpNet is byte-swapped for packet building, not for matching.
            var expectedSrcIp = NetUtils.IpToUint(peerIpStr);
            var expectedDstPort = (ushort)localPort;

            // 상호 배제: RxPollLoop의 DispatchPoll과 동시 실행 방지
            int ret;
            lock (_rxExclusiveLock)
            {
                ret = _dpdk.ReqRespOnceMc(
                    templatePkt, (ushort)templatePkt.Length, (ushort)pid,
                    expectedSrcIp, expectedDstPort,
                    timeoutMs, t_respBuf, (ushort)t_respBuf.Length,
                    out result, _localMac, _localIpNet);
            }

            string response = result.RespLen > 0
                ? Encoding.ASCII.GetString(t_respBuf, 0, result.RespLen)
                : string.Empty;

            long rttUs = (long)(result.RttMs * 1000);

            // Debug log RX
            if (ret == 0 && !data.Contains("pg.status", StringComparison.OrdinalIgnoreCase))
                DebugLog(pgIndex, DebugLogMsgTypeInspect, "RX", localPort.ToString(),
                    peerPort.ToString(), $"{response.TrimEnd()} [{rttUs}\u03BCs]");

            if (ret == 0 && driver.IsMainter)
                driver.RaiseRxMaintEventPg(pgIndex, localPort.ToString(), peerPort.ToString(), response.TrimEnd());

            return (ret, response, rttUs);
        }
        catch (Exception ex)
        {
            DebugLog(pgIndex, DebugLogMsgTypeInspect, "TX", localPort.ToString(),
                peerPort.ToString(), data + " ...REQRESP_NG: " + ex.Message);
            return (-1, string.Empty, 0);
        }
    }

    /// <summary>
    /// RX-only wait: polls NIC for a matching response without sending TX.
    /// Used after RET:INFO to wait for subsequent RET:OK/RET:NG.
    /// </summary>
    public (int status, string response, long rttUs) WaitForResponse(int pgIndex, int timeoutMs)
    {
        if (_disposed || pgIndex < 0 || pgIndex >= _pgDrivers.Length)
            return (-1, string.Empty, 0);

        var driver = _pgDrivers[pgIndex];
        var expectedSrcIp = NetUtils.IpToUint(driver.PgIpAddress);
        var expectedDstPort = (ushort)_localPorts[pgIndex];
        int localPort = _localPorts[pgIndex];
        int peerPort = driver.PgIpPort;

        t_respBuf ??= new byte[4096];
        var sw = System.Diagnostics.Stopwatch.StartNew();
        var rxPkts = new IntPtr[32];

        // RxPollLoop 차단: 전체 대기 기간 동안 _rxExclusiveLock 유지
        // (hw_reqresp_once_mc와 동일 패턴 — RxPollLoop가 RET:OK를 가로채는 것 방지)
        lock (_rxExclusiveLock)
        {
            while (sw.ElapsedMilliseconds < timeoutMs)
            {
                ushort nbRx;
                try
                {
                    nbRx = _dpdk.DispatchPoll(rxPkts, 32, out _);
                }
                catch
                {
                    Thread.SpinWait(100);
                    continue;
                }

                for (int i = 0; i < nbRx; i++)
                {
                    try
                    {
                        var dataPtr = _dpdk.GetMbufData(rxPkts[i]);
                        var dataLen = _dpdk.GetMbufDataLen(rxPkts[i]);
                        if (dataPtr == IntPtr.Zero || dataLen < EtherHdr.Size + Ipv4Hdr.Size + UdpHdr.Size)
                            continue;

                        var etherType = (ushort)(Marshal.ReadByte(dataPtr, 12) << 8 | Marshal.ReadByte(dataPtr, 13));
                        if (etherType == 0x0806) { HandleArpPacket(dataPtr, dataLen); continue; }
                        if (etherType != 0x0800) continue;

                        byte proto = Marshal.ReadByte(dataPtr, EtherHdr.Size + 9);
                        if (proto != IpProtoUdp) continue;

                        uint srcIpNet = ReadUInt32BE(dataPtr, EtherHdr.Size + 12);
                        if (!_ipToPgMap.TryGetValue(srcIpNet, out int rxPgIdx) || rxPgIdx != pgIndex)
                            continue;

                        int udpOff = EtherHdr.Size + Ipv4Hdr.Size;
                        int dstPort = NetUtils.Ntohs((ushort)Marshal.ReadInt16(dataPtr, udpOff + 2));
                        if (dstPort != expectedDstPort && dstPort != Dp860Network.PcPortBase) continue;

                        ushort udpLenNet = (ushort)Marshal.ReadInt16(dataPtr, udpOff + 4);
                        int payloadLen = NetUtils.Ntohs(udpLenNet) - UdpHdr.Size;
                        if (payloadLen <= 0) continue;

                        var payloadBytes = new byte[payloadLen];
                        Marshal.Copy(dataPtr + udpOff + UdpHdr.Size, payloadBytes, 0, payloadLen);
                        var response = Encoding.ASCII.GetString(payloadBytes);
                        long rttUs = sw.ElapsedMilliseconds * 1000;

                        // RET:INFO 또는 RET: 없는 중간 패킷은 무시하고 계속 대기
                        if (!response.Contains("RET:OK", StringComparison.OrdinalIgnoreCase) &&
                            !response.Contains("RET:NG", StringComparison.OrdinalIgnoreCase) &&
                            !response.Contains("RET:00", StringComparison.OrdinalIgnoreCase))
                        {
                            DebugLog(pgIndex, DebugLogMsgTypeInspect, "RX", localPort.ToString(),
                                peerPort.ToString(), $"{response.TrimEnd()} (intermediate, waiting...)");
                            continue;
                        }

                        // 최종 응답 (RET:OK / RET:NG) 수신
                        DebugLog(pgIndex, DebugLogMsgTypeInspect, "RX", localPort.ToString(),
                            peerPort.ToString(), $"{response.TrimEnd()} [{rttUs}\u03BCs]");

                        if (driver.IsMainter)
                            driver.RaiseRxMaintEventPg(pgIndex, localPort.ToString(), peerPort.ToString(), response.TrimEnd());

                        return (0, response, rttUs);
                    }
                    finally
                    {
                        _dpdk.FreeMbuf(rxPkts[i]);
                    }
                }

                if (nbRx == 0) Thread.SpinWait(10);
            }
        } // _rxExclusiveLock 해제

        return (1, string.Empty, timeoutMs * 1000); // timeout
    }

    /// <inheritdoc/>
    public bool TryRebindClients()
    {
        // DPDK doesn't use OS socket binding — just check engine readiness
        return _dpdk.State == HwState.Ready;
    }

    /// <inheritdoc/>
    public void Warmup() => PerformDpdkWarmup();

    // =========================================================================
    // UDP Packet Construction & Transmission
    // =========================================================================

    private byte[] BuildUdpPacket(byte[] dstMac, uint dstIpNet,
        ushort srcPort, ushort dstPort, byte[] payload)
    {
        int totalLen = EtherHdr.Size + Ipv4Hdr.Size + UdpHdr.Size + payload.Length;
        var pktBuf = new byte[totalLen];

        // --- Ethernet Header ---
        int off = 0;
        Buffer.BlockCopy(dstMac, 0, pktBuf, off, 6); off += 6;
        Buffer.BlockCopy(_localMac, 0, pktBuf, off, 6); off += 6;
        pktBuf[off++] = 0x08; pktBuf[off++] = 0x00; // EtherType IPv4

        // --- IPv4 Header ---
        int ipOff = off;
        pktBuf[off++] = 0x45; // Version=4, IHL=5
        pktBuf[off++] = 0x00; // DSCP/ECN
        ushort ipTotalLen = (ushort)(Ipv4Hdr.Size + UdpHdr.Size + payload.Length);
        WriteUInt16BE(pktBuf, off, ipTotalLen); off += 2;
        off += 2; // Identification = 0
        off += 2; // Flags/Fragment = 0
        pktBuf[off++] = 64;  // TTL
        pktBuf[off++] = IpProtoUdp;
        int checksumOff = off;
        off += 2; // Checksum placeholder
        WriteUInt32(pktBuf, off, _localIpNet); off += 4;
        WriteUInt32(pktBuf, off, dstIpNet); off += 4;

        // Compute IPv4 header checksum
        ushort ipCksum = ComputeIpChecksum(pktBuf, ipOff, Ipv4Hdr.Size);
        WriteUInt16BE(pktBuf, checksumOff, ipCksum);

        // --- UDP Header ---
        WriteUInt16BE(pktBuf, off, srcPort); off += 2;
        WriteUInt16BE(pktBuf, off, dstPort); off += 2;
        ushort udpLen = (ushort)(UdpHdr.Size + payload.Length);
        WriteUInt16BE(pktBuf, off, udpLen); off += 2;
        off += 2; // Checksum = 0 (optional for UDP over IPv4)

        // --- Payload ---
        Buffer.BlockCopy(payload, 0, pktBuf, off, payload.Length);

        return pktBuf;
    }

    private void SendUdpPacket(byte[] dstMac, uint dstIpNet,
        ushort srcPort, ushort dstPort, byte[] payload)
    {
        var pktBuf = BuildUdpPacket(dstMac, dstIpNet, srcPort, dstPort, payload);

        lock (_txLock)
        {
            var mbuf = _dpdk.AllocMbuf();
            if (mbuf == IntPtr.Zero)
            {
                _logger.Error("PgDpdkServer: Failed to allocate mbuf");
                return;
            }

            bool freed = false;
            try
            {
                var dataPtr = _dpdk.AppendMbuf(mbuf, (ushort)pktBuf.Length);
                if (dataPtr == IntPtr.Zero)
                {
                    _dpdk.FreeMbuf(mbuf); freed = true;
                    _logger.Error("PgDpdkServer: Failed to append to mbuf");
                    return;
                }

                Marshal.Copy(pktBuf, 0, dataPtr, pktBuf.Length);

                var txPkts = new IntPtr[] { mbuf };
                var sent = _dpdk.TxBurst(txPkts, 1);
                if (sent == 0)
                {
                    _dpdk.FreeMbuf(mbuf); freed = true;
                    _logger.Error("PgDpdkServer: tx_burst returned 0");
                }
            }
            catch
            {
                if (!freed) _dpdk.FreeMbuf(mbuf);
                throw;
            }
        }
    }

    // =========================================================================
    // DPDK Warmup — Prime NIC/DMA/CPU Caches
    // =========================================================================

    private void PerformDpdkWarmup()
    {
        _logger.Info("[PgDpdkServer] DPDK Warmup 시작 (64 dummy packets)...");
        try
        {
            // Find first enabled PG's MAC/IP for warmup target
            byte[] dstMac = new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };
            uint dstIpNet = 0;
            for (int pg = 0; pg < _pgDrivers.Length; pg++)
            {
                if (!_enabledChannels[pg]) continue;
                dstIpNet = NetUtils.Htonl(NetUtils.IpToUint(_pgDrivers[pg].PgIpAddress));
                if (_pgMacCache[pg] != null) dstMac = _pgMacCache[pg];
                break;
            }

            const int totalPackets = 64;
            const int batchSize = 32;
            byte[] dummyPayload = Encoding.ASCII.GetBytes("warmup");

            // Phase 1: Send 64 dummy packets in batches of 32
            for (int batch = 0; batch < totalPackets / batchSize; batch++)
            {
                lock (_txLock)
                {
                    var txPkts = new IntPtr[batchSize];
                    int allocated = 0;
                    for (int i = 0; i < batchSize; i++)
                    {
                        var pktBuf = BuildUdpPacket(dstMac, dstIpNet,
                            (ushort)Dp860Network.PcPortBase, 9999, dummyPayload);

                        var mbuf = _dpdk.AllocMbuf();
                        if (mbuf == IntPtr.Zero) break;

                        var dataPtr = _dpdk.AppendMbuf(mbuf, (ushort)pktBuf.Length);
                        if (dataPtr == IntPtr.Zero)
                        {
                            _dpdk.FreeMbuf(mbuf);
                            break;
                        }

                        Marshal.Copy(pktBuf, 0, dataPtr, pktBuf.Length);
                        txPkts[i] = mbuf;
                        allocated++;
                    }

                    if (allocated > 0)
                    {
                        var sent = _dpdk.TxBurst(txPkts,(ushort)allocated);
                        for (int i = (int)sent; i < allocated; i++)
                            _dpdk.FreeMbuf(txPkts[i]);
                    }
                }
            }

            // Phase 2: Wait for NIC/DMA processing
            Thread.Sleep(50);

            // Phase 3: Drain RX buffer (warmup responses + stale packets)
            var rxPkts = new IntPtr[MaxRxBurst];
            for (int drain = 0; drain < 10; drain++)
            {
                var nbRx = _dpdk.RxBurst(rxPkts,MaxRxBurst);
                for (int i = 0; i < nbRx; i++)
                    _dpdk.FreeMbuf(rxPkts[i]);
                if (nbRx == 0) break;
            }

            _logger.Info("[PgDpdkServer] DPDK Warmup 완료");
        }
        catch (Exception ex)
        {
            _logger.Error($"[PgDpdkServer] Warmup failed: {ex.Message}");
        }
    }

    // =========================================================================
    // RX Polling Thread
    // =========================================================================

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetCurrentThread();

    [DllImport("kernel32.dll")]
    private static extern UIntPtr SetThreadAffinityMask(IntPtr hThread, UIntPtr dwThreadAffinityMask);

    private void RxPollLoop()
    {
        // Pin RX thread to core 1 for consistent low-latency polling
        try
        {
            SetThreadAffinityMask(GetCurrentThread(), new UIntPtr(1u << 1));
            _logger.Info("[PgDpdkServer] RxPollLoop pinned to core 1");
        }
        catch (Exception ex)
        {
            _logger.Error($"[PgDpdkServer] Core pinning failed: {ex.Message}");
        }

        _logger.Info("[PgDpdkServer] RxPollLoop 스레드 시작");
        var rxPkts = new IntPtr[MaxRxBurst];

        while (_running)
        {
            // hw_reqresp_once_mc가 락을 잡고 있으면 skip (NIC RX 큐 상호 배제)
            if (!Monitor.TryEnter(_rxExclusiveLock, 0))
            {
                Thread.SpinWait(10);
                continue;
            }

            ushort nbRx;
            int lwipCount = 0;
            try
            {
                try
                {
                    nbRx = _dpdk.DispatchPoll(rxPkts, (ushort)MaxRxBurst, out lwipCount);
                }
                catch (Exception ex)
                {
                    _logger.Error($"[PgDpdkServer] shim_dispatch_poll error: {ex.Message}");
                    if (!_running) break;
                    Thread.SpinWait(100);
                    continue;
                }
            }
            finally
            {
                Monitor.Exit(_rxExclusiveLock);
            }

            if (nbRx == 0 && lwipCount == 0)
            {
                Thread.SpinWait(10);
                continue;
            }
            if (nbRx == 0)
                continue;

            for (int i = 0; i < nbRx; i++)
            {
                try
                {
                    ProcessRxPacket(rxPkts[i]);
                }
                catch (Exception ex)
                {
                    _logger.Error($"PgDpdkServer RX process error: {ex.Message}");
                }
                finally
                {
                    _dpdk.FreeMbuf(rxPkts[i]);
                }
            }
        }
        _logger.Info("[PgDpdkServer] RxPollLoop 스레드 종료");
    }

    private void ProcessRxPacket(IntPtr mbuf)
    {
        // Capture RX timestamp immediately before any parsing for accurate RTT
        var rxTimestamp = Stopwatch.GetTimestamp();

        if (mbuf == IntPtr.Zero) return;

        var dataPtr = _dpdk.GetMbufData(mbuf);
        if (dataPtr == IntPtr.Zero) return;

        var dataLen = _dpdk.GetMbufDataLen(mbuf);
        if (dataLen < 14 || dataLen > 65535) return; // 최소 Ethernet 헤더(14B) 검증

        // Read EtherType
        var etherType = (ushort)(Marshal.ReadByte(dataPtr, 12) << 8 | Marshal.ReadByte(dataPtr, 13));

        if (etherType == 0x0806) // ARP
        {
            HandleArpPacket(dataPtr, dataLen);
            return;
        }

        if (etherType != 0x0800) return; // Not IPv4

        if (dataLen < EtherHdr.Size + Ipv4Hdr.Size + UdpHdr.Size) return;

        // Read IP protocol
        int ipOff = EtherHdr.Size;
        byte proto = Marshal.ReadByte(dataPtr, ipOff + 9);
        if (proto != IpProtoUdp) return;

        // Read source IP
        uint srcIpNet = ReadUInt32BE(dataPtr, ipOff + 12);

        // Read UDP ports (network byte order)
        int udpOff = ipOff + Ipv4Hdr.Size;
        ushort srcPortNet = (ushort)Marshal.ReadInt16(dataPtr, udpOff);
        ushort dstPortNet = (ushort)Marshal.ReadInt16(dataPtr, udpOff + 2);
        ushort udpLenNet = (ushort)Marshal.ReadInt16(dataPtr, udpOff + 4);

        int srcPort = NetUtils.Ntohs(srcPortNet);
        int dstPort = NetUtils.Ntohs(dstPortNet);
        int udpPayloadLen = NetUtils.Ntohs(udpLenNet) - UdpHdr.Size;

        if (udpPayloadLen <= 0) return;
        if (dataLen < udpOff + UdpHdr.Size + udpPayloadLen) return;

        // Extract UDP payload
        var payloadBytes = new byte[udpPayloadLen];
        Marshal.Copy(dataPtr + udpOff + UdpHdr.Size, payloadBytes, 0, udpPayloadLen);
        var sAnsiData = Encoding.ASCII.GetString(payloadBytes);

        // Determine PG index from source IP (lock-free uint lookup, no string alloc)
        if (!_ipToPgMap.TryGetValue(srcIpNet, out int pgIndex)) return;
        if (pgIndex < 0 || pgIndex >= _pgDrivers.Length) return;

        // Filter out non-PG UDP traffic (e.g. mDNS port 5353 from PG board)
        if (dstPort != Dp860Network.PcPortBase && dstPort != _localPorts[pgIndex])
        {
            return;
        }

        var driver = _pgDrivers[pgIndex];
        int localPort = dstPort;
        int peerPort = srcPort;

        // Parse response — same logic as PgUdpServer.ReceiveLoop
        var txRxData = (localPort == Dp860Network.PcPortBase)
            ? driver.TxRxDefault
            : driver.TxRxPg;
        var sData = txRxData.RxPrevStr + sAnsiData;

        int retXxLen = 6;
        bool bEnd = false;

        while (!bEnd)
        {
            var posAck = sData.IndexOf("RET:", StringComparison.OrdinalIgnoreCase);

            if (posAck < 0)
            {
                bEnd = true;
                break;
            }

            retXxLen = 6;
            if (sData.IndexOf("RET:IN", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                if (sData.IndexOf("RET:INFO", StringComparison.OrdinalIgnoreCase) < 0)
                {
                    bEnd = true;
                    break;
                }
                retXxLen = 8;
            }

            if (sData.Length < (posAck + retXxLen))
            {
                bEnd = true;
                break;
            }

            var sCmdAck = sData[..(posAck + retXxLen)].Trim();
            int nextStart = posAck + retXxLen + 1;
            sData = nextStart < sData.Length ? sData[nextStart..].Trim() : string.Empty;

            // Latency measurement (lock-free per-CH array)
            long deltaMicro;
            var perfSent = Interlocked.Exchange(ref _sendTimestamps[pgIndex], 0);
            deltaMicro = perfSent > 0
                ? (rxTimestamp - perfSent) * 1_000_000 / Stopwatch.Frequency
                : -1;

            sCmdAck = sCmdAck.Replace("\n", "").Replace("\r\r", "\r");

            if (!sCmdAck.Contains("PG.STATUS", StringComparison.OrdinalIgnoreCase))
            {
                var sLocal = localPort.ToString();
                var sRemote = peerPort.ToString();

                if (deltaMicro >= 0)
                    DebugLog(pgIndex, DebugLogMsgTypeInspect, "RX", sLocal, sRemote,
                        $"{sCmdAck} [{deltaMicro}\u03BCs]");
                else
                    DebugLog(pgIndex, DebugLogMsgTypeInspect, "RX", sLocal, sRemote, sCmdAck);
            }

            if (driver.IsMainter)
            {
                driver.RaiseRxMaintEventPg(pgIndex, localPort.ToString(),
                    peerPort.ToString(), sCmdAck);
            }

            // RET:INFO — continue parsing, don't dispatch
            if (retXxLen != 6)
            {
                txRxData.RxPrevStr = sData.Trim().Length > 0 ? sData : string.Empty;
                continue;
            }

            driver.OnUdpReceived(sCmdAck, localPort, peerPort);

            if (sData.Length < 6) bEnd = true;
        }

        txRxData.RxPrevStr = sData.Trim().Length > 0 ? sData : string.Empty;
    }

    // =========================================================================
    // ARP Resolution
    // =========================================================================

    private void ResolveAllPgMacs()
    {
        _logger.Info($"[PgDpdkServer] ResolveAllPgMacs: {_pgDrivers.Length}개 PG MAC 해석 시작");
        for (int pg = 0; pg < _pgDrivers.Length; pg++)
        {
            // Skip ARP for disabled channels — use broadcast MAC as fallback
            if (pg < _enabledChannels.Length && !_enabledChannels[pg])
            {
                _pgMacCache[pg] = new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };
                _logger.Info($"[PgDpdkServer] PG{pg} 채널 비활성 — ARP 건너뜀 (broadcast MAC 사용)");
                continue;
            }

            var pgIp = _pgDrivers[pg].PgIpAddress;
            _logger.Info($"[PgDpdkServer] PG{pg} ARP 시작: IP={pgIp}");
            var dstIpNet = NetUtils.Htonl(NetUtils.IpToUint(pgIp));

            byte[]? mac = null;
            for (int attempt = 0; attempt < ArpRetries && mac == null; attempt++)
            {
                _logger.Info($"[PgDpdkServer] PG{pg} ARP attempt {attempt + 1}/{ArpRetries} (timeout={ArpTimeoutMs}ms)");
                mac = ResolveDestMac(dstIpNet, ArpTimeoutMs);
                if (mac == null && attempt < ArpRetries - 1)
                {
                    _logger.Warn($"PgDpdkServer: ARP attempt {attempt + 1} failed for PG{pg} ({pgIp}), retrying...");
                }
            }

            if (mac != null)
            {
                _pgMacCache[pg] = mac;
                _logger.Info($"PgDpdkServer: PG{pg} ({pgIp}) MAC resolved: {NetUtils.FormatMac(mac)}");
            }
            else
            {
                // Use broadcast as fallback (link-local network should still work)
                _pgMacCache[pg] = new byte[] { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };
                _logger.Warn($"PgDpdkServer: PG{pg} ({pgIp}) ARP failed, using broadcast MAC");
            }
        }
    }

    private byte[]? ResolveDestMac(uint dstIpNet, int timeoutMs)
    {
        _logger.Info($"[PgDpdkServer] ResolveDestMac: ARP TX 전송 준비 (dstIpNet=0x{dstIpNet:X8})");
        // Build ARP request packet
        int arpPktLen = EtherHdr.Size + ArpHdr.Size;
        var arpPkt = new byte[arpPktLen];

        // Ethernet header — broadcast destination
        int off = 0;
        for (int i = 0; i < 6; i++) arpPkt[off++] = 0xFF; // dst = broadcast
        Buffer.BlockCopy(_localMac, 0, arpPkt, off, 6); off += 6;
        arpPkt[off++] = 0x08; arpPkt[off++] = 0x06; // EtherType ARP

        // ARP header
        arpPkt[off++] = 0x00; arpPkt[off++] = 0x01; // Hardware type: Ethernet
        arpPkt[off++] = 0x08; arpPkt[off++] = 0x00; // Protocol type: IPv4
        arpPkt[off++] = 6;  // Hardware addr len
        arpPkt[off++] = 4;  // Protocol addr len
        arpPkt[off++] = 0x00; arpPkt[off++] = 0x01; // Opcode: ARP Request
        Buffer.BlockCopy(_localMac, 0, arpPkt, off, 6); off += 6; // Sender MAC
        WriteUInt32(arpPkt, off, _localIpNet); off += 4; // Sender IP
        off += 6; // Target MAC: 00:00:00:00:00:00
        WriteUInt32(arpPkt, off, dstIpNet); // Target IP

        // Send ARP request
        lock (_txLock)
        {
            try
            {
                var mbuf = _dpdk.AllocMbuf();
                if (mbuf == IntPtr.Zero)
                {
                    _logger.Error("[PgDpdkServer] ResolveDestMac: AllocMbuf returned NULL");
                    return null;
                }

                var dataPtr = _dpdk.AppendMbuf(mbuf, (ushort)arpPktLen);
                if (dataPtr == IntPtr.Zero)
                {
                    _dpdk.FreeMbuf(mbuf);
                    _logger.Error("[PgDpdkServer] ResolveDestMac: AppendMbuf returned NULL");
                    return null;
                }

                Marshal.Copy(arpPkt, 0, dataPtr, arpPktLen);
                var txPkts = new IntPtr[] { mbuf };
                var sent = _dpdk.TxBurst(txPkts, 1);
                if (sent == 0)
                {
                    _dpdk.FreeMbuf(mbuf);
                    _logger.Warn("[PgDpdkServer] ResolveDestMac: ARP tx_burst sent=0");
                }
                else
                {
                    _logger.Info("[PgDpdkServer] ResolveDestMac: ARP 요청 전송 완료");
                }
            }
            catch (AccessViolationException ex)
            {
                _logger.Error($"[PgDpdkServer] ResolveDestMac: ARP TX AccessViolation: {ex.Message}");
                return null;
            }
            catch (Exception ex)
            {
                _logger.Error($"[PgDpdkServer] ResolveDestMac: ARP TX error: {ex.Message}");
                return null;
            }
        }

        // Poll for ARP reply
        _logger.Info($"[PgDpdkServer] ResolveDestMac: ARP 응답 대기 (timeout={timeoutMs}ms)...");
        var sw = Stopwatch.StartNew();
        var rxPkts = new IntPtr[MaxRxBurst];

        while (sw.ElapsedMilliseconds < timeoutMs)
        {
            var nbRx = _dpdk.RxBurst(rxPkts,MaxRxBurst);
            for (int i = 0; i < nbRx; i++)
            {
                byte[]? foundMac = null;
                try
                {
                    var pktPtr = _dpdk.GetMbufData(rxPkts[i]);
                    var pktLen = _dpdk.GetMbufDataLen(rxPkts[i]);

                    if (pktLen >= EtherHdr.Size + ArpHdr.Size)
                    {
                        var ethType = (ushort)(Marshal.ReadByte(pktPtr, 12) << 8 |
                                               Marshal.ReadByte(pktPtr, 13));
                        if (ethType == 0x0806) // ARP
                        {
                            int arpOff = EtherHdr.Size;
                            var opcode = (ushort)(Marshal.ReadByte(pktPtr, arpOff + 6) << 8 |
                                                  Marshal.ReadByte(pktPtr, arpOff + 7));
                            if (opcode == 0x0002) // ARP Reply
                            {
                                uint senderIp = ReadUInt32BE(pktPtr, arpOff + 14);
                                if (senderIp == dstIpNet)
                                {
                                    foundMac = new byte[6];
                                    Marshal.Copy(pktPtr + arpOff + 8, foundMac, 0, 6);
                                }
                            }
                        }
                    }
                }
                finally
                {
                    // Always free exactly once
                    _dpdk.FreeMbuf(rxPkts[i]);
                }

                if (foundMac != null)
                {
                    // Free remaining packets
                    for (int j = i + 1; j < nbRx; j++)
                        _dpdk.FreeMbuf(rxPkts[j]);
                    return foundMac;
                }
            }

            Thread.SpinWait(100);
        }

        return null;
    }

    private void SendGratuitousArp()
    {
        int arpPktLen = EtherHdr.Size + ArpHdr.Size;
        var arpPkt = new byte[arpPktLen];

        int off = 0;
        for (int i = 0; i < 6; i++) arpPkt[off++] = 0xFF; // dst = broadcast
        Buffer.BlockCopy(_localMac, 0, arpPkt, off, 6); off += 6;
        arpPkt[off++] = 0x08; arpPkt[off++] = 0x06; // ARP

        // ARP header — GARP (sender IP == target IP)
        arpPkt[off++] = 0x00; arpPkt[off++] = 0x01; // Ethernet
        arpPkt[off++] = 0x08; arpPkt[off++] = 0x00; // IPv4
        arpPkt[off++] = 6; arpPkt[off++] = 4;
        arpPkt[off++] = 0x00; arpPkt[off++] = 0x01; // ARP Request (GARP)
        Buffer.BlockCopy(_localMac, 0, arpPkt, off, 6); off += 6;
        WriteUInt32(arpPkt, off, _localIpNet); off += 4;
        off += 6; // target MAC = 0
        WriteUInt32(arpPkt, off, _localIpNet); // target IP = our IP

        lock (_txLock)
        {
            var mbuf = _dpdk.AllocMbuf();
            if (mbuf == IntPtr.Zero) return;

            var dataPtr = _dpdk.AppendMbuf(mbuf, (ushort)arpPktLen);
            if (dataPtr == IntPtr.Zero)
            {
                _dpdk.FreeMbuf(mbuf);
                return;
            }

            Marshal.Copy(arpPkt, 0, dataPtr, arpPktLen);
            var txPkts = new IntPtr[] { mbuf };
            var sent = _dpdk.TxBurst(txPkts,1);
            if (sent == 0) _dpdk.FreeMbuf(mbuf);
        }
    }

    private void HandleArpPacket(IntPtr dataPtr, ushort dataLen)
    {
        if (dataLen < EtherHdr.Size + ArpHdr.Size) return;

        int arpOff = EtherHdr.Size;
        var opcode = (ushort)(Marshal.ReadByte(dataPtr, arpOff + 6) << 8 |
                              Marshal.ReadByte(dataPtr, arpOff + 7));

        if (opcode != 0x0001) return; // Not ARP Request

        // Check target IP is ours
        uint targetIp = ReadUInt32BE(dataPtr, arpOff + 24);
        if (targetIp != _localIpNet) return;

        // Build ARP Reply
        int arpPktLen = EtherHdr.Size + ArpHdr.Size;
        var reply = new byte[arpPktLen];

        // Sender MAC from request
        var reqSenderMac = new byte[6];
        Marshal.Copy(dataPtr + arpOff + 8, reqSenderMac, 0, 6);
        uint reqSenderIp = ReadUInt32BE(dataPtr, arpOff + 14);

        int off = 0;
        Buffer.BlockCopy(reqSenderMac, 0, reply, off, 6); off += 6; // dst = requester
        Buffer.BlockCopy(_localMac, 0, reply, off, 6); off += 6;
        reply[off++] = 0x08; reply[off++] = 0x06; // ARP

        reply[off++] = 0x00; reply[off++] = 0x01; // Ethernet
        reply[off++] = 0x08; reply[off++] = 0x00; // IPv4
        reply[off++] = 6; reply[off++] = 4;
        reply[off++] = 0x00; reply[off++] = 0x02; // ARP Reply
        Buffer.BlockCopy(_localMac, 0, reply, off, 6); off += 6; // our MAC
        WriteUInt32(reply, off, _localIpNet); off += 4; // our IP
        Buffer.BlockCopy(reqSenderMac, 0, reply, off, 6); off += 6; // target MAC
        WriteUInt32(reply, off, reqSenderIp); // target IP

        lock (_txLock)
        {
            var mbuf = _dpdk.AllocMbuf();
            if (mbuf == IntPtr.Zero) return;

            var dataReplyPtr = _dpdk.AppendMbuf(mbuf, (ushort)arpPktLen);
            if (dataReplyPtr == IntPtr.Zero)
            {
                _dpdk.FreeMbuf(mbuf);
                return;
            }

            Marshal.Copy(reply, 0, dataReplyPtr, arpPktLen);
            var txPkts = new IntPtr[] { mbuf };
            var sent = _dpdk.TxBurst(txPkts,1);
            if (sent == 0) _dpdk.FreeMbuf(mbuf);
        }
    }

    // =========================================================================
    // Helper Methods
    // =========================================================================

    private int IpToPgNo(string peerIp)
    {
        if (string.IsNullOrEmpty(peerIp)) return -1;
        for (int pg = 0; pg < _pgDrivers.Length; pg++)
        {
            if (_pgDrivers[pg].PgIpAddress == peerIp)
                return pg;
        }
        return -1;
    }

    private void DebugLog(int pgIndex, int msgType, string rtx,
        string localPort, string remotePort, string msg)
    {
        msg = msg.Replace("\r", "#");
        string ipText = rtx == "RX"
            ? $"[RX] {localPort}<{remotePort}"
            : $"[TX] {localPort}>{remotePort}";
        _pgDrivers[pgIndex].AddLog($"{ipText}: {msg.Trim()}");
    }

    private static void WriteUInt16BE(byte[] buf, int offset, ushort value)
    {
        buf[offset] = (byte)(value >> 8);
        buf[offset + 1] = (byte)(value & 0xFF);
    }

    private static void WriteUInt32(byte[] buf, int offset, uint value)
    {
        buf[offset] = (byte)((value >> 24) & 0xFF);
        buf[offset + 1] = (byte)((value >> 16) & 0xFF);
        buf[offset + 2] = (byte)((value >> 8) & 0xFF);
        buf[offset + 3] = (byte)(value & 0xFF);
    }

    private static uint ReadUInt32BE(IntPtr ptr, int offset)
    {
        return (uint)(
            (Marshal.ReadByte(ptr, offset) << 24) |
            (Marshal.ReadByte(ptr, offset + 1) << 16) |
            (Marshal.ReadByte(ptr, offset + 2) << 8) |
            Marshal.ReadByte(ptr, offset + 3));
    }

    private static ushort ComputeIpChecksum(byte[] data, int offset, int length)
    {
        uint sum = 0;
        for (int i = 0; i < length; i += 2)
        {
            sum += (uint)(data[offset + i] << 8);
            if (i + 1 < length)
                sum += data[offset + i + 1];
        }
        while ((sum >> 16) != 0)
            sum = (sum & 0xFFFF) + (sum >> 16);
        return (ushort)~sum;
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        _running = false;

        _rxThread?.Join(2000);
        _rxThread = null;

        _logger.Info("PgDpdkServer disposed");
    }
}
