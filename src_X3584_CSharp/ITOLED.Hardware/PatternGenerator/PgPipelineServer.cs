// =============================================================================
// PgPipelineServer.cs
// High-performance UDP transport for DP860 PG communication.
// Uses NetCoreServer (UdpServer) + System.IO.Pipelines for zero-copy RX parsing.
// Third transport mode alongside PgUdpServer (Socket) and PgDpdkServer (DPDK).
// =============================================================================

using System.Buffers;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Channels;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using NetCoreServer;

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

public sealed class PgPipelineServer : IPgTransport
{
    private const int DebugLogMsgTypeInspect = 0;

    private readonly ILogger _logger;
    private readonly CommPgDriver[] _pgDrivers;
    private readonly PgUdpChannel?[] _pgChannels;
    private readonly PgUdpChannel? _baseChannel;
    private readonly long[] _sendTimestamps;
    private bool _disposed;

    public PgPipelineServer(ILogger logger, CommPgDriver[] pgDrivers)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _pgDrivers = pgDrivers ?? throw new ArgumentNullException(nameof(pgDrivers));
        _pgChannels = new PgUdpChannel[pgDrivers.Length];
        _sendTimestamps = new long[pgDrivers.Length];

        // Per-PG channels
        for (int pg = 0; pg < pgDrivers.Length; pg++)
        {
            try
            {
                int localPort = Dp860Network.PcPortBase + 1 + pg;
                _pgChannels[pg] = new PgUdpChannel(
                    Dp860Network.PcIpAddr, localPort, pg, false, _pgDrivers, _sendTimestamps, _logger);
                _logger.Info($"[Pipeline] CH{pg} bound to {Dp860Network.PcIpAddr}:{localPort}");
            }
            catch (Exception ex)
            {
                _logger.Error(pg, $"[Pipeline] Failed to bind port: {ex.Message}");
                _pgChannels[pg] = null;
            }
        }

        // Base port channel (pg.status, power.read, pg.init)
        try
        {
            _baseChannel = new PgUdpChannel(
                Dp860Network.PcIpAddr, Dp860Network.PcPortBase, -1, true, _pgDrivers, _sendTimestamps, _logger);
            _logger.Info($"[Pipeline] Base port bound to {Dp860Network.PcIpAddr}:{Dp860Network.PcPortBase}");
        }
        catch (Exception ex)
        {
            _logger.Error($"[Pipeline] Failed to bind base port: {ex.Message}");
            _baseChannel = null;
        }

        _logger.Info($"[Pipeline] PgPipelineServer started: {pgDrivers.Length} PG(s)");
    }

    // =========================================================================
    // IPgTransport — Send (fire-and-forget)
    // =========================================================================

    public void Send(int bindIdx, int pgIndex, string data)
    {
        if (_disposed || pgIndex < 0 || pgIndex >= _pgDrivers.Length) return;

        var driver = _pgDrivers[pgIndex];
        var channel = (bindIdx >= _pgDrivers.Length) ? _baseChannel : _pgChannels.ElementAtOrDefault(bindIdx);
        if (channel == null) return;

        var peerIp = driver.PgIpAddress;
        var peerPort = driver.PgIpPort;

        if (!data.Contains("pg.status", StringComparison.OrdinalIgnoreCase))
            DebugLog(pgIndex, "TX", channel.LocalPort, peerPort, data);

        if (driver.IsMainter)
            driver.RaiseTxMaintEventPg(pgIndex, channel.LocalPort.ToString(), peerPort.ToString(), data);

        try
        {
            Interlocked.Exchange(ref _sendTimestamps[pgIndex], Stopwatch.GetTimestamp());
            var bytes = Encoding.ASCII.GetBytes(data);
            var endpoint = new IPEndPoint(IPAddress.Parse(peerIp), peerPort);
            channel.SendTo(endpoint, bytes);
        }
        catch (Exception ex)
        {
            driver.PublishTestWindow(DefCommon.MsgModeWorking, DefCommon.LogTypeNg,
                $"PipelineSvrSend : Error : {ex.Message}");
        }
    }

    // SendAndReceive / WaitForResponse — Socket과 동일하게 미구현
    // Dp860SendCmd에서 CheckCmdAck (Send + OnUdpReceived 콜백) 경로 사용

    // =========================================================================
    // IPgTransport — TryRebindClients
    // =========================================================================

    public bool TryRebindClients()
    {
        bool anyRebound = false;
        for (int pg = 0; pg < _pgChannels.Length; pg++)
        {
            if (_pgChannels[pg] != null) continue;
            try
            {
                int localPort = Dp860Network.PcPortBase + 1 + pg;
                _pgChannels[pg] = new PgUdpChannel(
                    Dp860Network.PcIpAddr, localPort, pg, false, _pgDrivers, _sendTimestamps, _logger);
                anyRebound = true;
            }
            catch { /* retry next cycle */ }
        }

        if (_baseChannel == null)
        {
            try
            {
                // base channel rebuild not supported after init (readonly field)
            }
            catch { }
        }

        return anyRebound || _pgChannels.Any(c => c != null);
    }

    public void Warmup() { } // no-op

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        foreach (var ch in _pgChannels)
            ch?.Dispose();
        _baseChannel?.Dispose();
    }

    private void DebugLog(int pgIndex, string direction, int srcPort, int dstPort, string data)
    {
        data = data.Replace("\r", "#");
        string ipText = direction == "RX"
            ? $"[RX] {srcPort}<{dstPort}"
            : $"[{direction}] {srcPort}>{dstPort}";
        _pgDrivers[pgIndex].AddLog($"{ipText}: {data.Trim()}");
    }

    // =========================================================================
    // Inner: PgUdpChannel — per-port UDP + Channel<RxDatagram> + parse loop
    // =========================================================================

    private sealed class PgUdpChannel : IDisposable
    {
        private readonly PipelineUdpServer _server;
        private readonly Channel<RxDatagram> _rxChannel;
        private readonly CancellationTokenSource _cts = new();
        private readonly Task _parseTask;
        private readonly CommPgDriver[] _pgDrivers;
        private readonly long[] _sendTimestamps;
        private readonly ILogger _logger;
        private readonly int _fixedPgIndex; // -1 for base port
        private readonly bool _isBasePort;

        // Sync SendAndReceive state
        private readonly ManualResetEventSlim _responseReady = new(false);
        private volatile int _waitingPgIndex = -1;
        private string _syncResponse = string.Empty;
        private int _syncStatus;

        public int LocalPort { get; }

        public PgUdpChannel(string ipAddr, int port, int fixedPgIndex, bool isBasePort,
            CommPgDriver[] pgDrivers, long[] sendTimestamps, ILogger logger)
        {
            LocalPort = port;
            _fixedPgIndex = fixedPgIndex;
            _isBasePort = isBasePort;
            _pgDrivers = pgDrivers;
            _sendTimestamps = sendTimestamps;
            _logger = logger;

            _rxChannel = Channel.CreateBounded<RxDatagram>(new BoundedChannelOptions(256)
            {
                SingleReader = true,
                SingleWriter = false,
                FullMode = BoundedChannelFullMode.DropOldest
            });

            _server = new PipelineUdpServer(this, IPAddress.Parse(ipAddr), port);
            _server.Start();

            _parseTask = Task.Run(() => ParseLoopAsync(_cts.Token));
        }

        public void SendTo(EndPoint endpoint, byte[] data)
        {
            _server.Send(endpoint, data, 0, data.Length);
        }

        public void PrepareSyncWait(int pgIndex)
        {
            _syncResponse = string.Empty;
            _syncStatus = 1; // timeout default
            _responseReady.Reset();
            Interlocked.Exchange(ref _waitingPgIndex, pgIndex);
        }

        public bool WaitForSyncResponse(int timeoutMs)
        {
            bool result = _responseReady.Wait(timeoutMs);
            Interlocked.Exchange(ref _waitingPgIndex, -1);
            return result;
        }

        public (int status, string response) ConsumeSyncResponse()
        {
            return (_syncStatus, _syncResponse);
        }

        internal void OnDatagramReceived(EndPoint endpoint, byte[] buffer, long offset, long size)
        {
            var data = new byte[size];
            Array.Copy(buffer, offset, data, 0, size);
            var datagram = new RxDatagram(endpoint, data, Stopwatch.GetTimestamp());
            _rxChannel.Writer.TryWrite(datagram);
        }

        private async Task ParseLoopAsync(CancellationToken ct)
        {
            var reader = _rxChannel.Reader;
            try
            {
                await foreach (var datagram in reader.ReadAllAsync(ct))
                {
                    try
                    {
                        ProcessDatagram(datagram);
                    }
                    catch (Exception ex)
                    {
                        _logger.Error($"[Pipeline] ParseLoop error: {ex.Message}");
                    }
                }
            }
            catch (OperationCanceledException) { }
        }

        private void ProcessDatagram(RxDatagram datagram)
        {
            var text = Encoding.ASCII.GetString(datagram.Data);

            // Determine PG index
            int pgIndex;
            if (_isBasePort)
            {
                if (datagram.RemoteEndpoint is IPEndPoint ipep)
                {
                    pgIndex = IpToPgIndex(ipep.Address.ToString());
                    if (pgIndex < 0) return;
                }
                else return;
            }
            else
            {
                pgIndex = _fixedPgIndex;
            }

            if (pgIndex < 0 || pgIndex >= _pgDrivers.Length) return;

            var driver = _pgDrivers[pgIndex];
            int localPort = LocalPort;
            int peerPort = (datagram.RemoteEndpoint is IPEndPoint ep) ? ep.Port : 0;

            // Check if SendAndReceive is waiting for this PG's response
            int waitingPg = _waitingPgIndex;
            if (waitingPg == pgIndex)
            {
                _syncResponse = text;
                _syncStatus = text.Contains("RET:NG", StringComparison.OrdinalIgnoreCase) ? -1 : 0;
                _responseReady.Set();
                return; // consumed by SendAndReceive — don't dispatch to OnUdpReceived
            }

            // Fire-and-forget RX — parse and dispatch to CommPgDriver
            var txRxData = (localPort == Dp860Network.PcPortBase)
                ? driver.TxRxDefault
                : driver.TxRxPg;

            var sData = txRxData.RxPrevStr + text;
            int retXxLen = 6;
            bool bEnd = false;

            while (!bEnd)
            {
                var posAck = sData.IndexOf("RET:", StringComparison.OrdinalIgnoreCase);
                if (posAck < 0) { bEnd = true; break; }

                retXxLen = 6;
                if (sData.IndexOf("RET:IN", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    if (sData.IndexOf("RET:INFO", StringComparison.OrdinalIgnoreCase) < 0)
                    { bEnd = true; break; }
                    retXxLen = 8;
                }

                if (posAck + retXxLen > sData.Length)
                {
                    txRxData.RxPrevStr = sData;
                    bEnd = true;
                    break;
                }

                var sCmdAck = sData[..(posAck + retXxLen)];
                sData = sData[(posAck + retXxLen)..];
                txRxData.RxPrevStr = string.Empty;

                if (!sCmdAck.Contains("pg.status", StringComparison.OrdinalIgnoreCase))
                {
                    // RTT measurement
                    long deltaMicro;
                    var perfSent = Interlocked.Exchange(ref _sendTimestamps[pgIndex], 0);
                    deltaMicro = perfSent > 0
                        ? (Stopwatch.GetTimestamp() - perfSent) * 1_000_000 / Stopwatch.Frequency
                        : -1;

                    var ackText = sCmdAck.Replace("\n", "").Replace("\r\r", "\r");
                    if (sCmdAck.Contains("RET:NG", StringComparison.OrdinalIgnoreCase))
                        ackText = $"NG!! {ackText}";

                    if (deltaMicro >= 0)
                        DebugLog(pgIndex, "RX", localPort, peerPort, $"{ackText} [{deltaMicro}\u03BCs]");
                    else
                        DebugLog(pgIndex, "RX", localPort, peerPort, ackText);
                }

                driver.OnUdpReceived(sCmdAck, localPort, peerPort);
            }
        }

        private void DebugLog(int pgIndex, string direction, int srcPort, int dstPort, string data)
        {
            data = data.Replace("\r", "#");
            string ipText = direction == "RX"
                ? $"[RX] {srcPort}<{dstPort}"
                : $"[{direction}] {srcPort}>{dstPort}";
            _pgDrivers[pgIndex].AddLog($"{ipText}: {data.Trim()}");
        }

        private int IpToPgIndex(string ip)
        {
            for (int i = 0; i < _pgDrivers.Length; i++)
            {
                if (_pgDrivers[i].PgIpAddress == ip) return i;
            }
            return -1;
        }

        public void Dispose()
        {
            _cts.Cancel();
            try { _server.Stop(); } catch { }
            try { _server.Dispose(); } catch { }
            _responseReady.Dispose();
            _cts.Dispose();
        }
    }

    // =========================================================================
    // Inner: PipelineUdpServer — NetCoreServer UdpServer wrapper
    // =========================================================================

    private sealed class PipelineUdpServer : NetCoreServer.UdpServer
    {
        private readonly PgUdpChannel _channel;

        public PipelineUdpServer(PgUdpChannel channel, IPAddress address, int port)
            : base(address, port)
        {
            _channel = channel;
        }

        protected override void OnStarted() => ReceiveAsync();

        protected override void OnReceived(EndPoint endpoint, byte[] buffer, long offset, long size)
        {
            _channel.OnDatagramReceived(endpoint, buffer, offset, size);
            ReceiveAsync();
        }

        protected override void OnError(SocketError error)
        {
            // Resume receive chain after transient error
            ReceiveAsync();
        }
    }

    // =========================================================================
    // Inner: RxDatagram record
    // =========================================================================

    private readonly record struct RxDatagram(EndPoint RemoteEndpoint, byte[] Data, long ReceivedTicks);
}
