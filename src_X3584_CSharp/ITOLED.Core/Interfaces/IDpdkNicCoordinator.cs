// =============================================================================
// IDpdkNicCoordinator.cs
// Coordinates exclusive NIC access between PG UDP (PgDpdkServer) and
// FTP (HwFtpEngine/lwIP). Only one can use rte_eth_rx_burst() at a time.
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Coordinates exclusive NIC access between PG UDP communication
/// and FTP file transfers (lwIP). FTP acquires a lease that pauses PG RX,
/// and releasing the lease resumes PG RX.
/// </summary>
public interface IDpdkNicCoordinator
{
    /// <summary>
    /// Acquires exclusive NIC access for FTP operations.
    /// Pauses PG RX polling and returns a lease. Disposing the lease resumes PG RX.
    /// </summary>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>Disposable lease — PG RX resumes on disposal.</returns>
    Task<IAsyncDisposable> AcquireFtpAccessAsync(CancellationToken ct = default);

    /// <summary>Whether FTP currently holds exclusive NIC access.</summary>
    bool IsFtpActive { get; }
}
