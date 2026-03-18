using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Pattern generator events (Delphi MSG_TYPE_PG = 4).
/// Published by CommPG when PG connection state changes,
/// pattern downloads complete, or errors occur.
/// </summary>
public sealed class PgEventMessage : AppMessage;
