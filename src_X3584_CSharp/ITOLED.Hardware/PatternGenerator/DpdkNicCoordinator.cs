// =============================================================================
// DpdkNicCoordinator.cs
// Coordinates DPDK NIC access between PG UDP and FTP (lwIP).
// SetLwipExternalRx는 앱 시작/종료 시 1회만 토글 (hwio.dll 힙 손상 방지).
// FTP lease는 레퍼런스 카운팅으로 관리.
// =============================================================================

using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

/// <summary>
/// Coordinates DPDK NIC access. lwIP external RX mode is enabled once at startup
/// and disabled at shutdown — never toggled during OC flow to avoid hwio.dll heap corruption.
/// FTP operations acquire/release leases for reference counting only.
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

    /// <summary>
    /// 앱 시작 시 1회 호출 — lwIP external RX 모드 활성화.
    /// 이후 FTP lease 획득/해제 시 토글하지 않음.
    /// </summary>
    public void EnableLwipMode()
    {
        _pgServer.Dpdk.SetLwipExternalRx(true);
        _logger.Info("[NicCoordinator] lwIP external RX 활성화 (앱 시작 — 1회)");
    }

    /// <summary>
    /// 앱 종료 시 1회 호출 — lwIP external RX 모드 비활성화.
    /// </summary>
    public void DisableLwipMode()
    {
        _pgServer.Dpdk.SetLwipExternalRx(false);
        _logger.Info("[NicCoordinator] lwIP external RX 비활성화 (앱 종료)");
    }

    /// <inheritdoc/>
    public Task<IAsyncDisposable> AcquireFtpAccessAsync(CancellationToken ct = default)
    {
        int count = Interlocked.Increment(ref _ftpActiveCount);
        _logger.Info($"[NicCoordinator] FTP lease 획득 (activeCount={count})");
        return Task.FromResult<IAsyncDisposable>(new FtpLease(this));
    }

    private void ReleaseFtpAccess()
    {
        int count = Interlocked.Decrement(ref _ftpActiveCount);
        _logger.Info($"[NicCoordinator] FTP lease 해제 (activeCount={count})");
    }

    private sealed class FtpLease : IAsyncDisposable
    {
        private readonly DpdkNicCoordinator _coordinator;
        private int _disposed;

        public FtpLease(DpdkNicCoordinator coordinator) => _coordinator = coordinator;

        public ValueTask DisposeAsync()
        {
            if (Interlocked.CompareExchange(ref _disposed, 1, 0) == 0)
                _coordinator.ReleaseFtpAccess();
            return ValueTask.CompletedTask;
        }
    }
}
