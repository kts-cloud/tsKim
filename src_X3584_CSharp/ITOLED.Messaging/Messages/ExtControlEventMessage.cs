using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// External control events (Delphi MSG_TYPE_EXT_CONTROL = 1001).
/// Published for external system control commands that come from
/// outside the normal PLC/MES path.
/// </summary>
public sealed class ExtControlEventMessage : AppMessage;
