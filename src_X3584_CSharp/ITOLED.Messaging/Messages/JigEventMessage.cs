using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Jig control events (Delphi MSG_TYPE_JIG = 5).
/// Published by JigControl when jig state changes,
/// sensor readings update, or jig errors are detected.
/// </summary>
public sealed class JigEventMessage : AppMessage;
