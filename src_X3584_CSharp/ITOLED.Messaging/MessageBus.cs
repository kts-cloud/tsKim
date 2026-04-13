using System.Collections.Concurrent;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging;

/// <summary>
/// Thread-safe publish/subscribe message bus.
/// Replaces Delphi's WM_COPYDATA inter-form messaging.
/// <para>
/// Subscriptions hold a <strong>strong</strong> reference to the handler delegate
/// for as long as the subscription is alive. Callers MUST dispose the
/// <see cref="IDisposable"/> returned by <see cref="Subscribe{T}"/> to release
/// the handler — forgotten unsubscriptions will keep the handler (and any
/// captured target) alive until the bus itself is collected.
/// </para>
/// </summary>
public sealed class MessageBus : IMessageBus
{
    // ── Subscription storage ───────────────────────────────────────────
    // Key   = concrete AppMessage subtype (e.g. typeof(ScriptEventMessage))
    // Value = list of Subscription records holding strong references to delegates
    private readonly ConcurrentDictionary<Type, List<Subscription>> _subscriptions = new();

    // Lock per message type to serialise mutations on each subscription list
    private readonly ConcurrentDictionary<Type, object> _locks = new();

    // ── IMessageBus: Publish ───────────────────────────────────────────

    /// <inheritdoc />
    public void Publish<T>(T message) where T : AppMessage
    {
        ArgumentNullException.ThrowIfNull(message);
        InvokeSubscribers(message, publishContext: null);
    }

    /// <inheritdoc />
    public void PublishOnContext<T>(T message, SynchronizationContext syncContext) where T : AppMessage
    {
        ArgumentNullException.ThrowIfNull(message);
        ArgumentNullException.ThrowIfNull(syncContext);
        InvokeSubscribers(message, syncContext);
    }

    // ── IMessageBus: Subscribe ─────────────────────────────────────────

    /// <inheritdoc />
    public IDisposable Subscribe<T>(Action<T> handler) where T : AppMessage
    {
        ArgumentNullException.ThrowIfNull(handler);
        return AddSubscription(typeof(T), handler, syncContext: null);
    }

    /// <inheritdoc />
    public IDisposable SubscribeOnContext<T>(Action<T> handler, SynchronizationContext syncContext) where T : AppMessage
    {
        ArgumentNullException.ThrowIfNull(handler);
        ArgumentNullException.ThrowIfNull(syncContext);
        return AddSubscription(typeof(T), handler, syncContext);
    }

    // ── Internal plumbing ──────────────────────────────────────────────

    private IDisposable AddSubscription(Type messageType, Delegate handler, SynchronizationContext? syncContext)
    {
        var subscription = new Subscription(handler, syncContext);
        var @lock = _locks.GetOrAdd(messageType, _ => new object());

        lock (@lock)
        {
            var list = _subscriptions.GetOrAdd(messageType, _ => new List<Subscription>());
            list.Add(subscription);
        }

        return new Unsubscriber(this, messageType, subscription);
    }

    private void RemoveSubscription(Type messageType, Subscription subscription)
    {
        if (!_locks.TryGetValue(messageType, out var @lock))
            return;

        lock (@lock)
        {
            if (_subscriptions.TryGetValue(messageType, out var list))
            {
                list.Remove(subscription);
            }
        }
    }

    private void InvokeSubscribers<T>(T message, SynchronizationContext? publishContext) where T : AppMessage
    {
        var messageType = typeof(T);

        if (!_subscriptions.TryGetValue(messageType, out var list))
            return;

        // Snapshot the list under the per-type lock, then invoke outside the
        // lock so a slow handler can't block other publishers / subscribers.
        Subscription[] snapshot;
        if (!_locks.TryGetValue(messageType, out var @lock))
            return; // lost a race with subscription removal — no subscribers

        lock (@lock)
        {
            snapshot = list.ToArray();
        }

        foreach (var sub in snapshot)
        {
            // Skip subscriptions that have been disposed concurrently.
            var handler = sub.Handler;
            if (handler is null)
                continue;

            var action = (Action<T>)handler;

            // Determine which SynchronizationContext to use:
            // 1. Per-subscription context (from SubscribeOnContext) takes priority
            // 2. Per-publish context (from PublishOnContext) is fallback
            // 3. No context = invoke synchronously on current thread
            var ctx = sub.SyncContext ?? publishContext;

            if (ctx is not null)
            {
                // Post (async) to avoid deadlocks if called from the target thread
                ctx.Post(_ =>
                {
                    try { action(message); }
                    catch (Exception ex)
                    {
                        OnHandlerException(message, ex);
                    }
                }, null);
            }
            else
            {
                try { action(message); }
                catch (Exception ex)
                {
                    OnHandlerException(message, ex);
                }
            }
        }
    }

    /// <summary>
    /// Called when a subscriber handler throws.
    /// Override-friendly via event; default behavior swallows the exception
    /// to prevent one faulty handler from breaking delivery to others.
    /// </summary>
    private void OnHandlerException<T>(T message, Exception ex) where T : AppMessage
    {
        HandlerException?.Invoke(this, new MessageBusExceptionEventArgs(message, ex));
    }

    /// <summary>
    /// Raised when a subscriber's handler throws an exception.
    /// Attach a handler here to log or act on messaging errors.
    /// </summary>
    public event EventHandler<MessageBusExceptionEventArgs>? HandlerException;

    // ── Inner types ────────────────────────────────────────────────────

    /// <summary>
    /// Holds a strong reference to the handler delegate plus an optional
    /// <see cref="SynchronizationContext"/> for marshaling.
    /// <para>
    /// The handler reference is volatile so that <see cref="Release"/> on the
    /// disposing thread is observed by an in-flight publish on another thread
    /// without taking a lock — the publisher checks for null and skips the
    /// disposed subscription.
    /// </para>
    /// </summary>
    private sealed class Subscription
    {
        private Delegate? _handler;

        public Delegate? Handler => Volatile.Read(ref _handler);
        public SynchronizationContext? SyncContext { get; }

        public Subscription(Delegate handler, SynchronizationContext? syncContext)
        {
            _handler = handler;
            SyncContext = syncContext;
        }

        /// <summary>Releases the strong reference so the handler is eligible for GC.</summary>
        public void Release() => Volatile.Write(ref _handler, null);
    }

    /// <summary>
    /// Returned from Subscribe / SubscribeOnContext.
    /// Disposing this removes the subscription.
    /// </summary>
    private sealed class Unsubscriber : IDisposable
    {
        private MessageBus? _bus;
        private readonly Type _messageType;
        private Subscription? _subscription;

        public Unsubscriber(MessageBus bus, Type messageType, Subscription subscription)
        {
            _bus = bus;
            _messageType = messageType;
            _subscription = subscription;
        }

        public void Dispose()
        {
            var bus = Interlocked.Exchange(ref _bus, null);
            var sub = Interlocked.Exchange(ref _subscription, null);
            if (bus is null || sub is null) return;

            sub.Release();
            bus.RemoveSubscription(_messageType, sub);
        }
    }
}

/// <summary>
/// Event data for <see cref="MessageBus.HandlerException"/>.
/// </summary>
public sealed class MessageBusExceptionEventArgs : EventArgs
{
    /// <summary>The message that was being delivered.</summary>
    public AppMessage Message { get; }

    /// <summary>The exception thrown by the handler.</summary>
    public Exception Exception { get; }

    public MessageBusExceptionEventArgs(AppMessage message, Exception exception)
    {
        Message = message;
        Exception = exception;
    }
}
