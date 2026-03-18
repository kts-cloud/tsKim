// =============================================================================
// DpdkNicCoordinator.cs
// Coordinates DPDK NIC access between PG UDP and FTP (lwIP).
// With the unified dispatcher (shim_dispatch_poll), RX polling continues
// during FTP — only lwIP external RX mode is toggled.
// Supports concurrent multi-channel FTP via reference counting.
// =============================================================================

using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

/// <summary>
/// Coordinates DPDK NIC access. FTP operations acquire a lease that enables
/// lwIP external RX mode (dispatcher feeds TCP/ARP to lwIP while UDP continues).
/// Multiple channels can FTP simultaneously — lwIP supports multiple TCP connections.
/// </summary>
public sealed class DpdkNicCoordinator : IDpdkNicCoordinator
{
    private readonly PgDpdkServer _pgServer;
    private readonly ILogger _logger;
    private volatile int _ftpActiveCount;

    public DpdkNicCoordinator(PgDpdkServer pgServer, ILogger logger)
    {
        _pgServer = pgServer ?? throw new ArgumentNullException(nameof(pgServer));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public bool IsFtpActive => _ftpActiveCount > 0;

    /// <inheritdoc/>
    public Task<IAsyncDisposable> AcquireFtpAccessAsync(CancellationToken ct = default)
    {
        int count = Interlocked.Increment(ref _ftpActiveCount);
        _logger.Info($"[NicCoordinator] FTP 활성화 (activeCount={count})");

        try
        {
            // First session: enable lwIP external RX
            if (count == 1)
            {
                _pgServer.Dpdk.SetLwipExternalRx(true);
                _logger.Info("[NicCoordinator] external RX 활성화 (첫 FTP 세션)");
            }
            return Task.FromResult<IAsyncDisposable>(new FtpLease(this));
        }
        catch
        {
            Interlocked.Decrement(ref _ftpActiveCount);
            throw;
        }
    }

    private void ReleaseFtpAccess()
    {
        int count = Interlocked.Decrement(ref _ftpActiveCount);
        _logger.Info($"[NicCoordinator] FTP 해제 (activeCount={count})");

        // Last session: disable lwIP external RX
        if (count == 0)
        {
            _pgServer.Dpdk.SetLwipExternalRx(false);
            _logger.Info("[NicCoordinator] external RX 비활성화 (마지막 FTP 세션 종료)");
        }
    }

    /// <summary>
    /// Disposable lease returned by <see cref="AcquireFtpAccessAsync"/>.
    /// Disposing decrements the FTP active count and disables lwIP when last.
    /// </summary>
    private sealed class FtpLease : IAsyncDisposable
    {
        private readonly DpdkNicCoordinator _coordinator;
        private int _disposed;

        public FtpLease(DpdkNicCoordinator coordinator) => _coordinator = coordinator;

        public ValueTask DisposeAsync()
        {
            if (Interlocked.CompareExchange(ref _disposed, 1, 0) == 0)
            {
                _coordinator.ReleaseFtpAccess();
            }
            return ValueTask.CompletedTask;
        }
    }
}
