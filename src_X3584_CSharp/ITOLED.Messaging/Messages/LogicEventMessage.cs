using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Inspection logic events (Delphi MSG_TYPE_LOGIC = 3).
/// Published by LogicVh to report flow step transitions,
/// result status, and test progress.
/// </summary>
public sealed class LogicEventMessage : AppMessage;
