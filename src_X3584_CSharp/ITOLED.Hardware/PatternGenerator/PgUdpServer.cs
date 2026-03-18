// =============================================================================
// PgUdpServer.cs
// Converted from Delphi: src_X3584\CommPG.pas (TUdpServerPG class)
// UDP server for DP860 pattern generator communication.
// Replaces TIdUDPServer with System.Net.Sockets.UdpClient.
// Namespace: Dongaeltek.ITOLED.Hardware.PatternGenerator
// =============================================================================

using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

/// <summary>
/// UDP server for DP860 pattern generator communication.
/// Creates per-PG UDP bindings and routes incoming data to the appropriate
/// <see cref="CommPgDriver"/> instance.
/// <para>Delphi origin: <c>TUdpServerPG</c> (CommPG.pas lines 510-940)</para>
/// </summary>
public sealed class PgUdpServer : IPgTransport
{
    // =========================================================================
    // Constants
    // =========================================================================

    /// <summary>Delphi: DEBUG_LOG_MSGTYPE_INSPECT</summary>
    private const int DebugLogMsgTypeInspect = 0;

    // =========================================================================
    // Fields
    // =========================================================================

    private readonly ILogger _logger;
    private readonly CommPgDriver[] _pgDrivers;

    /// <summary>
    /// Per-PG UDP clients for sending. Index = PG index.
    /// Delphi: UdpSvr.Bindings[nPg]
    /// </summary>
    private readonly UdpClient?[] _pgUdpClients;

    /// <summary>
    /// Base-port UDP client for ConnCheck/PowerRead/PgInit (no-ack channel).
    /// Delphi: UdpSvr.Bindings[PG_CNT] bound to CommPG_PC_PORT_BASE.
    /// </summary>
    private UdpClient? _baseUdpClient;

    /// <summary>
    /// High-resolution timer for latency measurement.
    /// Replaces Delphi's QueryPerformanceFrequency/QueryPerformanceCounter.
    /// </summary>
    private readonly Dictionary<int, long> _sendTimestamps = new();
    private readonly object _timestampLock = new();

    /// <summary>Cancellation for receive loops.</summary>
    private CancellationTokenSource? _cts;

    private bool _isReadyToRead;
    private bool _disposed;

    // =========================================================================
    // Constructor / Dispose
    // =========================================================================

    /// <summary>
    /// Creates the UDP server, binds per-PG ports, and starts receive loops.
    /// <para>Delphi: <c>TUdpServerPG.Create(hMain)</c></para>
    /// </summary>
    /// <param name="logger">Logger instance.</param>
    /// <param name="pgDrivers">Array of PG driver instances (index 0..PG_MAX-1).</param>
    public PgUdpServer(ILogger logger, CommPgDriver[] pgDrivers)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _pgDrivers = pgDrivers ?? throw new ArgumentNullException(nameof(pgDrivers));
        _pgUdpClients = new UdpClient[pgDrivers.Length];

        _isReadyToRead = false;

        // Create per-PG UDP clients
        for (int pg = 0; pg < pgDrivers.Length; pg++)
        {
            try
            {
                var endpoint = new IPEndPoint(IPAddress.Parse(Dp860Network.PcIpAddr), pgDrivers[pg].PgIpPort);
                _pgUdpClients[pg] = new UdpClient(endpoint);
            }
            catch (Exception ex)
            {
                _logger.Error(pg, $"Failed to bind UDP port {pgDrivers[pg].PgIpPort}: {ex.Message}");
                _pgUdpClients[pg] = null;
            }
        }

        // Create base-port UDP client for ConnCheck/PowerRead/PgInit
        try
        {
            var baseEndpoint = new IPEndPoint(IPAddress.Parse(Dp860Network.PcIpAddr), Dp860Network.PcPortBase);
            _baseUdpClient = new UdpClient(baseEndpoint);
        }
        catch (Exception ex)
        {
            _logger.Error($"Failed to bind base UDP port {Dp860Network.PcPortBase}: {ex.Message}");
            _baseUdpClient = null;
        }

        // Start receive loops
        _cts = new CancellationTokenSource();
        StartReceiveLoops();
    }

    /// <inheritdoc/>
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        _cts?.Cancel();

        for (int pg = 0; pg < _pgUdpClients.Length; pg++)
        {
            _pgUdpClients[pg]?.Close();
            _pgUdpClients[pg]?.Dispose();
            _pgUdpClients[pg] = null;
        }

        _baseUdpClient?.Close();
        _baseUdpClient?.Dispose();
        _baseUdpClient = null;

        _cts?.Dispose();
    }

    // =========================================================================
    // Public API
    // =========================================================================

    /// <summary>
    /// Whether the server is ready to process received data.
    /// Delphi: FIsReadyToRead
    /// </summary>
    public bool IsReadyToRead
    {
        get => _isReadyToRead;
        set => _isReadyToRead = value;
    }

    /// <summary>
    /// Sends data to a specific PG via the appropriate binding.
    /// <para>Delphi: <c>TUdpServerPG.UdpSvrSend(nBindIdx, nPg, sData)</c></para>
    /// </summary>
    /// <param name="bindIdx">
    /// Binding index: 0..PG_MAX-1 for per-PG ports, PG_MAX for base port.
    /// Delphi: nBindIdx
    /// </param>
    /// <param name="pgIndex">PG index (0-based).</param>
    /// <param name="data">Command string to send (CR will be appended by caller).</param>
    public void Send(int bindIdx, int pgIndex, string data)
    {
        if (_disposed) return;
        if (pgIndex < 0 || pgIndex >= _pgDrivers.Length) return;

        var driver = _pgDrivers[pgIndex];
        UdpClient? client;

        if (bindIdx >= _pgDrivers.Length)
            client = _baseUdpClient;
        else if (bindIdx >= 0 && bindIdx < _pgUdpClients.Length)
            client = _pgUdpClients[bindIdx];
        else
            return;

        if (client == null) return;

        var peerIp = driver.PgIpAddress;
        var peerPort = driver.PgIpPort;

        // Debug/maint log
        int localPort;
        try
        {
            localPort = ((IPEndPoint)client.Client.LocalEndPoint!).Port;
        }
        catch
        {
            localPort = 0;
        }

        var sLocal = localPort.ToString();
        var sRemote = peerPort.ToString();

        // Skip logging pg.status commands
        if (!data.Contains("pg.status", StringComparison.OrdinalIgnoreCase))
        {
            DebugLog(pgIndex, DebugLogMsgTypeInspect, "TX", sLocal, sRemote, data);
        }

        // Record send timestamp for latency measurement
        var perfCount = Stopwatch.GetTimestamp();
        lock (_timestampLock)
        {
            _sendTimestamps[pgIndex] = perfCount;
        }

        // Fire maintenance TX event
        if (driver.IsMainter)
        {
            driver.RaiseTxMaintEventPg(pgIndex, sLocal, sRemote, data);
        }

        // Send
        try
        {
            var bytes = Encoding.ASCII.GetBytes(data);
            var endpoint = new IPEndPoint(IPAddress.Parse(peerIp), peerPort);
            client.Send(bytes, bytes.Length, endpoint);
        }
        catch (Exception ex)
        {
            driver.PublishTestWindow(DefCommon.MsgModeWorking, DefCommon.LogTypeNg,
                $"UdpSvrSend : Error : {ex.Message}");
            DebugLog(pgIndex, DebugLogMsgTypeInspect, "TX", sLocal, sRemote, data + " ...TX_NG");

            if (driver.IsMainter)
            {
                driver.RaiseTxMaintEventPg(pgIndex, sLocal, sRemote, data + " ...TX_NG");
            }
        }
    }

    // =========================================================================
    // UDP Client Rebinding (hot-plug support)
    // =========================================================================

    /// <summary>
    /// Attempts to rebind null UDP clients when PG NIC was unavailable at startup.
    /// Called from ConnCheck timer when PG status is Disconnected.
    /// <para>
    /// At startup, <c>new UdpClient(IPEndPoint)</c> may fail with SocketException
    /// if the PG network interface (169.254.199.x) is not yet configured.
    /// This method retries binding for any client that is still null.
    /// </para>
    /// </summary>
    /// <returns>true if any client was successfully rebound.</returns>
    public bool TryRebindClients()
    {
        if (_disposed) return false;

        bool anyRebound = false;

        // Rebind per-PG UDP clients
        for (int pg = 0; pg < _pgDrivers.Length; pg++)
        {
            if (_pgUdpClients[pg] != null) continue;

            try
            {
                var endpoint = new IPEndPoint(
                    IPAddress.Parse(Dp860Network.PcIpAddr), _pgDrivers[pg].PgIpPort);
                var client = new UdpClient(endpoint);
                _pgUdpClients[pg] = client;

                // Start receive loop for newly bound client
                var pgIdx = pg;
                var token = _cts!.Token;
                _ = Task.Run(() => ReceiveLoop(client, pgIdx, false, token), token)
                    .ContinueWith(t => _logger.Error($"PgUdpServer ReceiveLoop[{pgIdx}] crashed: {t.Exception?.InnerException?.Message}"),
                        TaskContinuationOptions.OnlyOnFaulted);

                _logger.Info(pg, $"UDP client rebound on port {_pgDrivers[pg].PgIpPort}");
                anyRebound = true;
            }
            catch
            {
                // NIC still not ready — will retry next ConnCheck cycle
            }
        }

        // Rebind base port
        if (_baseUdpClient == null)
        {
            try
            {
                var baseEndpoint = new IPEndPoint(
                    IPAddress.Parse(Dp860Network.PcIpAddr), Dp860Network.PcPortBase);
                var client = new UdpClient(baseEndpoint);
                _baseUdpClient = client;

                var token = _cts!.Token;
                _ = Task.Run(() => ReceiveLoop(client, -1, true, token), token)
                    .ContinueWith(t => _logger.Error($"PgUdpServer BaseReceiveLoop crashed: {t.Exception?.InnerException?.Message}"),
                        TaskContinuationOptions.OnlyOnFaulted);

                _logger.Info($"Base UDP client rebound on port {Dp860Network.PcPortBase}");
                anyRebound = true;
            }
            catch
            {
                // NIC still not ready
            }
        }

        return anyRebound;
    }

    // =========================================================================
    // Receive Loops
    // =========================================================================

    /// <summary>
    /// Starts async receive loops for each bound UDP client.
    /// </summary>
    private void StartReceiveLoops()
    {
        var token = _cts!.Token;

        // Per-PG receive loops
        for (int pg = 0; pg < _pgUdpClients.Length; pg++)
        {
            if (_pgUdpClients[pg] == null) continue;
            var pgIdx = pg;
            var client = _pgUdpClients[pg]!;
            _ = Task.Run(() => ReceiveLoop(client, pgIdx, false, token), token)
                .ContinueWith(t => _logger.Error($"PgUdpServer ReceiveLoop[{pgIdx}] crashed: {t.Exception?.InnerException?.Message}"),
                    TaskContinuationOptions.OnlyOnFaulted);
        }

        // Base port receive loop
        if (_baseUdpClient != null)
        {
            _ = Task.Run(() => ReceiveLoop(_baseUdpClient, -1, true, token), token)
                .ContinueWith(t => _logger.Error($"PgUdpServer BaseReceiveLoop crashed: {t.Exception?.InnerException?.Message}"),
                    TaskContinuationOptions.OnlyOnFaulted);
        }
    }

    /// <summary>
    /// Continuous receive loop for a single UDP client.
    /// <para>Delphi: <c>TUdpServerPG.UdpSvrRead</c></para>
    /// </summary>
    private async Task ReceiveLoop(UdpClient client, int fixedPgIndex, bool isBasePort, CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                var result = await client.ReceiveAsync(ct).ConfigureAwait(false);

                var peerIp = result.RemoteEndPoint.Address.ToString();
                var peerPort = result.RemoteEndPoint.Port;
                int localPort;
                try
                {
                    localPort = ((IPEndPoint)client.Client.LocalEndPoint!).Port;
                }
                catch
                {
                    localPort = 0;
                }

                // Determine PG index from peer IP
                int pgIndex = isBasePort ? IpToPgNo(peerIp) : fixedPgIndex;
                if (pgIndex < 0 || pgIndex >= _pgDrivers.Length) continue;
                var driver = _pgDrivers[pgIndex];

                // Filter out packets not from the expected PG IP (e.g. mDNS multicast)
                if (!isBasePort && peerIp != driver.PgIpAddress)
                    continue;

                // Discard non-PG packets (mDNS, etc.) — PG responses are printable ASCII
                if (ContainsBinaryData(result.Buffer))
                    continue;

                // Convert received bytes to ASCII string
                var sAnsiData = Encoding.ASCII.GetString(result.Buffer);

                // Determine which TxRx buffer to use
                var txRxData = (localPort == Dp860Network.PcPortBase) ? driver.TxRxDefault : driver.TxRxPg;
                var sData = txRxData.RxPrevStr + sAnsiData;

                int retXxLen = 6; // "RET:OK" or "RET:NG"

                bool bEnd = false;
                while (!bEnd)
                {
                    var upperData = sData.ToUpperInvariant();
                    var posAck = upperData.IndexOf("RET:", StringComparison.Ordinal);

                    if (posAck < 0)
                    {
                        bEnd = true;
                        break;
                    }

                    // Check for RET:INFO
                    retXxLen = 6;
                    if (upperData.IndexOf("RET:IN", StringComparison.Ordinal) >= 0)
                    {
                        if (upperData.IndexOf("RET:INFO", StringComparison.Ordinal) < 0)
                        {
                            bEnd = true;
                            break;
                        }
                        retXxLen = 8; // "RET:INFO"
                    }

                    if (sData.Length < (posAck + retXxLen))
                    {
                        bEnd = true;
                        break;
                    }

                    // Extract command ack: everything up to and including RET:xx
                    var sCmdAck = sData[..(posAck + retXxLen)].Trim();
                    int nextStart = posAck + retXxLen + 1;
                    sData = nextStart < sData.Length ? sData[nextStart..].Trim() : string.Empty;

                    // Latency measurement
                    long deltaMicro;
                    var perfNow = Stopwatch.GetTimestamp();
                    lock (_timestampLock)
                    {
                        if (_sendTimestamps.TryGetValue(pgIndex, out var perfSent))
                        {
                            deltaMicro = (perfNow - perfSent) * 1_000_000 / Stopwatch.Frequency;
                            _sendTimestamps.Remove(pgIndex);
                        }
                        else
                        {
                            deltaMicro = -1;
                        }
                    }

                    // Clean up control characters
                    sCmdAck = sCmdAck.Replace("\n", "").Replace("\r\r", "\r");

                    // Debug log (skip PG.STATUS)
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

                    // Maintenance RX event
                    if (driver.IsMainter)
                    {
                        var sLocal = localPort.ToString();
                        var sRemote = peerPort.ToString();
                        driver.RaiseRxMaintEventPg(pgIndex, sLocal, sRemote, sCmdAck);
                    }

                    // RET:INFO (pg.process) — continue parsing, don't dispatch
                    if (retXxLen != 6)
                    {
                        txRxData.RxPrevStr = sData.Trim().Length > 0 ? sData : string.Empty;
                        continue;
                    }

                    // Dispatch to driver
                    driver.OnUdpReceived(sCmdAck, localPort, peerPort);

                    if (sData.Length < 6) bEnd = true;
                }

                txRxData.RxPrevStr = sData.Trim().Length > 0 ? sData : string.Empty;
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (ObjectDisposedException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.Error($"PgUdpServer receive error: {ex.Message}");
                await Task.Delay(100, ct).ConfigureAwait(false);
            }
        }
    }

    // =========================================================================
    // Helper Methods
    // =========================================================================

    /// <summary>
    /// Maps a peer IP to a PG index.
    /// <para>Delphi: <c>TUdpServerPG.IpToPgNo</c></para>
    /// </summary>
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

    /// <summary>
    /// Checks if the buffer contains binary (non-printable) data,
    /// indicating a non-PG packet (e.g. mDNS multicast from PG board).
    /// PG responses are printable ASCII + CR/LF only.
    /// </summary>
    private static bool ContainsBinaryData(byte[] buffer)
    {
        for (int i = 0; i < buffer.Length; i++)
        {
            byte b = buffer[i];
            // Allow printable ASCII (0x20-0x7E), TAB (0x09), CR (0x0D), LF (0x0A)
            if (b >= 0x20 && b <= 0x7E) continue;
            if (b == 0x09 || b == 0x0D || b == 0x0A) continue;
            return true; // binary byte found
        }
        return false;
    }

    /// <summary>
    /// Writes a debug log entry.
    /// <para>Delphi: <c>TUdpServerPG.DebugLog</c></para>
    /// </summary>
    private void DebugLog(int pgIndex, int msgType, string rtx, string localPort, string remotePort, string msg)
    {
        msg = msg.Replace("\r", "#");

        string ipText;
        if (rtx == "RX")
            ipText = $"[RX] {localPort}<{remotePort}";
        else
            ipText = $"[TX] {localPort}>{remotePort}";

        var inputData = $"{ipText}: {msg.Trim()}";
        _pgDrivers[pgIndex].AddLog(inputData);
    }
}
