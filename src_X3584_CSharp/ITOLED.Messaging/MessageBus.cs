using System.Collections.Concurrent;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging;

/// <summary>
/// Thread-safe publish/subscribe message bus.
/// Replaces Delphi's WM_COPYDATA inter-form messaging.
/// <para>
/// Subscriptions are stored as <see cref="WeakReference{T}"/> to delegates
/// so that forgotten unsubscriptions do not prevent garbage collection of
/// the owning object. However, callers SHOULD still dispose the returned
/// <see cref="IDisposable"/> for deterministic cleanup.
/// </para>
/// </summary>
public sealed class MessageBus : IMessageBus
{
    // ── Subscription storage ───────────────────────────────────────────
    // Key   = concrete AppMessage subtype (e.g. typeof(ScriptEventMessage))
    // Value = list of Subscription records holding weak-referenced delegates
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

        // Snapshot the list under lock, then invoke outside the lock
        // to avoid holding the lock during potentially slow handlers.
        Subscription[] snapshot;
        var @lock = _locks.GetOrAdd(messageType, _ => new object());

        lock (@lock)
        {
            snapshot = list.ToArray();
        }

        List<Subscription>? dead = null;

        foreach (var sub in snapshot)
        {
            if (!sub.HandlerRef.TryGetTarget(out var target))
            {
                // Weak reference expired - mark for cleanup
                (dead ??= new List<Subscription>()).Add(sub);
                continue;
            }

            var action = (Action<T>)target;

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

        // Lazy cleanup of dead weak references
        if (dead is not null)
        {
            lock (@lock)
            {
                foreach (var d in dead)
                    list.Remove(d);
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
    /// Holds a weak reference to the delegate plus an optional
    /// <see cref="SynchronizationContext"/> for marshaling.
    /// </summary>
    private sealed class Subscription
    {
        public WeakReference<Delegate> HandlerRef { get; }
        public SynchronizationContext? SyncContext { get; }

        /// <summary>
        /// Strong reference kept so the delegate is not GC'd while
        /// the subscription is alive. Cleared on unsubscribe.
        /// </summary>
        internal Delegate? StrongRef;

        public Subscription(Delegate handler, SynchronizationContext? syncContext)
        {
            HandlerRef = new WeakReference<Delegate>(handler);
            StrongRef = handler;
            SyncContext = syncContext;
        }

        /// <summary>
        /// Releases the strong reference so the weak reference
        /// can be collected on next GC cycle.
        /// </summary>
        public void Release() => StrongRef = null;
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
