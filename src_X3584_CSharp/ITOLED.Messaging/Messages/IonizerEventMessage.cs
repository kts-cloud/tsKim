using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Ionizer events (Delphi MSG_TYPE_IONIZER = 8).
/// Published by CommIonizer when ionizer status changes
/// or communication events occur.
/// </summary>
public sealed class IonizerEventMessage : AppMessage;
