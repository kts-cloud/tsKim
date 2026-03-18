using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// ADLINK DIO card events (Delphi MSG_TYPE_ADLINK = 7).
/// Published by DIO_ADLINK when ADLINK digital I/O state changes occur.
/// </summary>
public sealed class AdlinkDioEventMessage : AppMessage;
