// =============================================================================
// IPgTransport.cs
// Transport layer abstraction for PG (Pattern Generator) communication.
// Enables switching between Socket UDP and DPDK transports.
// Namespace: Dongaeltek.ITOLED.Hardware.PatternGenerator
// =============================================================================

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

/// <summary>
/// Transport layer interface for PG communication.
/// Implemented by <see cref="PgUdpServer"/> (Socket UDP), <see cref="PgDpdkServer"/> (DPDK),
/// and <see cref="PgPipelineServer"/> (Pipeline: NetCoreServer + System.IO.Pipelines).
/// </summary>
public interface IPgTransport : IDisposable
{
    /// <summary>
    /// Sends data to a specific PG via the appropriate binding.
    /// </summary>
    /// <param name="bindIdx">Binding index: 0..PG_MAX-1 for per-PG ports, PG_MAX for base port.</param>
    /// <param name="pgIndex">PG index (0-based).</param>
    /// <param name="data">Command string to send.</param>
    void Send(int bindIdx, int pgIndex, string data);

    /// <summary>
    /// Attempts to rebind any failed UDP clients (for hot-plug/NIC delay scenarios).
    /// DPDK implementations may return true if the engine is ready.
    /// </summary>
    bool TryRebindClients();

    /// <summary>
    /// Warms up the transport layer (e.g., prime NIC/DMA/CPU caches).
    /// Called before compensation flow to ensure optimal latency.
    /// </summary>
    void Warmup() { } // default no-op for non-DPDK transports

    /// <summary>
    /// Synchronous send-and-receive: sends command and blocks until response or timeout.
    /// DPDK: uses hw_reqresp_once_mc (entire TX→RX in native C, no C# parsing overhead).
    /// Socket: falls back to Send + CheckCmdAck pattern.
    /// </summary>
    /// <param name="bindIdx">Binding index.</param>
    /// <param name="pgIndex">PG index (0-based).</param>
    /// <param name="data">Command string to send.</param>
    /// <param name="timeoutMs">Response timeout in milliseconds.</param>
    /// <returns>(status: 0=success/1=timeout/-1=error, response: ASCII payload, rttUs: measured RTT)</returns>
    (int status, string response, long rttUs) SendAndReceive(int bindIdx, int pgIndex, string data, int timeoutMs)
        => (-1, string.Empty, 0); // default: not supported

    /// <summary>
    /// RX-only wait: blocks until a matching response arrives or timeout.
    /// Used after RET:INFO to wait for subsequent RET:OK/RET:NG without re-sending TX.
    /// DPDK: uses hw_reqresp_once_mc with empty TX (RX polling only).
    /// Socket: not supported (uses CheckCmdAck pattern).
    /// </summary>
    (int status, string response, long rttUs) WaitForResponse(int pgIndex, int timeoutMs)
        => (-1, string.Empty, 0); // default: not supported
}
