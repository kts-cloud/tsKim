using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Main form events (Delphi MSG_TYPE_MAIN = 21).
/// Published for top-level application state changes
/// (model loading, UI mode transitions, etc.).
/// </summary>
public sealed class MainEventMessage : AppMessage;
