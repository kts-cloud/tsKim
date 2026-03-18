using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// DAE I/O card events (Delphi MSG_TYPE_DAEIO = 101).
/// Published by CommDIO_DAE when digital I/O state changes occur.
/// </summary>
public sealed class DioEventMessage : AppMessage;
