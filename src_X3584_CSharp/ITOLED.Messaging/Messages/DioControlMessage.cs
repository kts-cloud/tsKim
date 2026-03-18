using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// DIO control commands (Delphi MSG_TYPE_CTL_DIO = 102).
/// Published by ControlDio_OC to request or report
/// digital output changes and alarm conditions.
/// </summary>
public sealed class DioControlMessage : AppMessage;
