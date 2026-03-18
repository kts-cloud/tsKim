using Dongaeltek.ITOLED.Messaging;
using Dongaeltek.ITOLED.OC.Services;

namespace ITOLED.Tests.Services;

public class UiUpdateServiceTests : IDisposable
{
    private readonly MessageBus _bus;
    private readonly UiUpdateService _svc;

    public UiUpdateServiceTests()
    {
        _bus = new MessageBus();
        _svc = new UiUpdateService(_bus);
    }

    public void Dispose()
    {
        _svc.Dispose();
    }

    [Fact]
    public void GetLastChannelLogs_EmptyByDefault()
    {
        var logs = _svc.GetLastChannelLogs(0);
        Assert.Empty(logs);
    }

    [Fact]
    public void GetLastChannelPrevResults_EmptyByDefault()
    {
        var results = _svc.GetLastChannelPrevResults(0);
        Assert.Empty(results);
    }

    [Fact]
    public void GetLastChannelLogs_OutOfRange_ReturnsEmpty()
    {
        Assert.Empty(_svc.GetLastChannelLogs(-1));
        Assert.Empty(_svc.GetLastChannelLogs(4));
    }

    [Fact]
    public void NotifyChannelLog_CachesEntry()
    {
        _svc.NotifyChannelLog(0, "Test message");
        var logs = _svc.GetLastChannelLogs(0);
        Assert.Single(logs);
        Assert.Contains("Test message", logs[0]);
    }

    [Fact]
    public void NotifyChannelResult_UpdatesCounts()
    {
        _svc.NotifyChannelResult(0, 0); // PASS
        _svc.NotifyChannelResult(0, 1); // NG
        _svc.NotifyChannelResult(0, 0); // PASS

        var (ok, ng) = _svc.GetLastChannelCounts(0);
        Assert.Equal(2, ok);
        Assert.Equal(1, ng);
    }

    [Fact]
    public void NotifyChannelResult_CachesPrevResults()
    {
        _svc.NotifyChannelResult(1, 0);
        _svc.NotifyChannelResult(1, 42);

        var results = _svc.GetLastChannelPrevResults(1);
        Assert.Equal(2, results.Count);
        Assert.Equal((42, false), results[0]); // most recent first
        Assert.Equal((0, true), results[1]);
    }

    [Fact]
    public async Task ConcurrentAccess_LogsDoNotCorrupt()
    {
        const int iterations = 500;
        var writeTask = Task.Run(() =>
        {
            for (int i = 0; i < iterations; i++)
                _svc.NotifyChannelLog(0, $"Write {i}");
        });

        var readTask = Task.Run(() =>
        {
            for (int i = 0; i < iterations; i++)
            {
                var logs = _svc.GetLastChannelLogs(0);
                // Should not throw -- returned list is a copy
                _ = logs.Count;
            }
        });

        await Task.WhenAll(writeTask, readTask);
        var finalLogs = _svc.GetLastChannelLogs(0);
        Assert.True(finalLogs.Count <= 200); // max cached entries
    }

    [Fact]
    public async Task ConcurrentAccess_ResultsDoNotCorrupt()
    {
        const int iterations = 500;
        var writeTask = Task.Run(() =>
        {
            for (int i = 0; i < iterations; i++)
                _svc.NotifyChannelResult(2, i % 2 == 0 ? 0 : i);
        });

        var readTask = Task.Run(() =>
        {
            for (int i = 0; i < iterations; i++)
            {
                var results = _svc.GetLastChannelPrevResults(2);
                _ = results.Count;
            }
        });

        await Task.WhenAll(writeTask, readTask);
        var (ok, ng) = _svc.GetLastChannelCounts(2);
        Assert.Equal(iterations, ok + ng);
    }

    [Fact]
    public void NotifyChannelStatus_UpdatesCache()
    {
        _svc.NotifyChannelStatus(0, 1); // Running
        Assert.Equal(1, _svc.GetLastChannelStatus(0));

        _svc.NotifyChannelStatus(0, 2); // PASS
        Assert.Equal(2, _svc.GetLastChannelStatus(0));
    }
}
