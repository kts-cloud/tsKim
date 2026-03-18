// =============================================================================
// MessageBusTests.cs — Tests for the pub/sub message bus
// =============================================================================

using Dongaeltek.ITOLED.Core.Messaging;
using Dongaeltek.ITOLED.Messaging;

namespace ITOLED.Tests.Messaging;

// ── Test message types ───────────────────────────────────
public class TestMessage : AppMessage { }
public class OtherMessage : AppMessage { }

public class MessageBusTests
{
    private readonly MessageBus _bus = new();

    // ── Basic Pub/Sub ────────────────────────────────────────

    [Fact]
    public void Publish_DeliverToSubscriber()
    {
        TestMessage? received = null;
        _bus.Subscribe<TestMessage>(m => received = m);

        var msg = new TestMessage { Channel = 1, Mode = 2, Message = "hello" };
        _bus.Publish(msg);

        Assert.NotNull(received);
        Assert.Equal(1, received!.Channel);
        Assert.Equal(2, received.Mode);
        Assert.Equal("hello", received.Message);
    }

    [Fact]
    public void Publish_MultipleSubscribers_AllReceive()
    {
        int count = 0;
        _bus.Subscribe<TestMessage>(_ => Interlocked.Increment(ref count));
        _bus.Subscribe<TestMessage>(_ => Interlocked.Increment(ref count));
        _bus.Subscribe<TestMessage>(_ => Interlocked.Increment(ref count));

        _bus.Publish(new TestMessage());

        Assert.Equal(3, count);
    }

    [Fact]
    public void Publish_WrongType_NotDelivered()
    {
        bool received = false;
        _bus.Subscribe<TestMessage>(_ => received = true);

        _bus.Publish(new OtherMessage());

        Assert.False(received);
    }

    // ── Unsubscribe ──────────────────────────────────────────

    [Fact]
    public void Unsubscribe_StopsDelivery()
    {
        int count = 0;
        var sub = _bus.Subscribe<TestMessage>(_ => count++);

        _bus.Publish(new TestMessage());
        Assert.Equal(1, count);

        sub.Dispose();

        _bus.Publish(new TestMessage());
        Assert.Equal(1, count); // Should NOT increase
    }

    [Fact]
    public void Unsubscribe_DoubleDispose_NoError()
    {
        var sub = _bus.Subscribe<TestMessage>(_ => { });
        sub.Dispose();
        sub.Dispose(); // Should not throw
    }

    // ── Exception Handling ───────────────────────────────────

    [Fact]
    public void Handler_Exception_DoesNotBreakOtherHandlers()
    {
        int successCount = 0;
        _bus.Subscribe<TestMessage>(_ => throw new InvalidOperationException("boom"));
        _bus.Subscribe<TestMessage>(_ => successCount++);

        _bus.Publish(new TestMessage());

        Assert.Equal(1, successCount); // Second handler still called
    }

    [Fact]
    public void HandlerException_Event_Fires()
    {
        Exception? caughtEx = null;
        _bus.HandlerException += (_, args) => caughtEx = args.Exception;
        _bus.Subscribe<TestMessage>(_ => throw new InvalidOperationException("test error"));

        _bus.Publish(new TestMessage());

        Assert.NotNull(caughtEx);
        Assert.IsType<InvalidOperationException>(caughtEx);
        Assert.Equal("test error", caughtEx!.Message);
    }

    // ── AppMessage Properties ────────────────────────────────

    [Fact]
    public void AppMessage_DefaultValues()
    {
        var msg = new TestMessage();
        Assert.Equal(-1, msg.Channel); // Default channel = -1
        Assert.Equal(0, msg.Mode);
        Assert.Equal(0, msg.Param);
        Assert.Equal(0, msg.Param2);
        Assert.Equal("", msg.Message);
        Assert.Null(msg.Data);
    }

    [Fact]
    public void AppMessage_InitProperties()
    {
        var data = new byte[] { 1, 2, 3 };
        var msg = new TestMessage
        {
            Channel = 2,
            Mode = 5,
            Param = 10,
            Param2 = 3,
            Message = "test",
            Data = data
        };

        Assert.Equal(2, msg.Channel);
        Assert.Equal(5, msg.Mode);
        Assert.Equal(10, msg.Param);
        Assert.Equal(3, msg.Param2);
        Assert.Equal("test", msg.Message);
        Assert.Equal(data, msg.Data);
    }

    [Fact]
    public void AppMessage_Timestamp_IsRecent()
    {
        var before = DateTime.UtcNow;
        var msg = new TestMessage();
        var after = DateTime.UtcNow;

        Assert.InRange(msg.Timestamp, before, after);
    }

    [Fact]
    public void AppMessage_ToString_IncludesTypeName()
    {
        var msg = new TestMessage { Channel = 1, Mode = 2, Message = "hi" };
        string str = msg.ToString();
        Assert.Contains("TestMessage", str);
        Assert.Contains("Ch=1", str);
        Assert.Contains("Mode=2", str);
    }

    // ── Thread Safety ────────────────────────────────────────

    [Fact]
    public async Task ConcurrentPublishAndSubscribe_NoDeadlock()
    {
        int totalReceived = 0;
        var tasks = new List<Task>();

        // Multiple threads subscribing
        for (int i = 0; i < 10; i++)
        {
            tasks.Add(Task.Run(() =>
            {
                var sub = _bus.Subscribe<TestMessage>(_ =>
                    Interlocked.Increment(ref totalReceived));
                Thread.Sleep(10);
                sub.Dispose();
            }));
        }

        // Multiple threads publishing
        for (int i = 0; i < 10; i++)
        {
            tasks.Add(Task.Run(() =>
            {
                _bus.Publish(new TestMessage());
                Thread.Sleep(5);
                _bus.Publish(new TestMessage());
            }));
        }

        await Task.WhenAll(tasks);

        // Just verify no deadlock/exception — exact count depends on timing
        Assert.True(true);
    }

    // ── Null checks ──────────────────────────────────────────

    [Fact]
    public void Publish_Null_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => _bus.Publish<TestMessage>(null!));
    }

    [Fact]
    public void Subscribe_NullHandler_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => _bus.Subscribe<TestMessage>(null!));
    }
}
