using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Publish/subscribe message bus replacing Delphi's WM_COPYDATA inter-form messaging.
/// All message types derive from <see cref="AppMessage"/>.
/// </summary>
public interface IMessageBus
{
    /// <summary>
    /// Publishes a message to all subscribers of type <typeparamref name="T"/>.
    /// Delivery happens synchronously on the calling thread unless a
    /// <see cref="SynchronizationContext"/> is provided.
    /// </summary>
    void Publish<T>(T message) where T : AppMessage;

    /// <summary>
    /// Publishes a message, marshaling delivery to the specified
    /// <see cref="SynchronizationContext"/> (typically the UI thread context).
    /// </summary>
    void PublishOnContext<T>(T message, SynchronizationContext syncContext) where T : AppMessage;

    /// <summary>
    /// Subscribes to messages of type <typeparamref name="T"/>.
    /// Returns an <see cref="IDisposable"/> that unsubscribes when disposed.
    /// </summary>
    IDisposable Subscribe<T>(Action<T> handler) where T : AppMessage;

    /// <summary>
    /// Subscribes to messages of type <typeparamref name="T"/> and ensures
    /// the handler is invoked on the specified <see cref="SynchronizationContext"/>.
    /// Useful for UI-thread marshaling without depending on WinForms.
    /// </summary>
    IDisposable SubscribeOnContext<T>(Action<T> handler, SynchronizationContext syncContext) where T : AppMessage;
}
