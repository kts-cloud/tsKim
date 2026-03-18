using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// PLC/ECS communication events (Delphi MSG_TYPE_COMM_ECS = 103).
/// Published by CommPLC_ECS when PLC interlock signals change,
/// handshake sequences complete, or communication errors occur.
/// </summary>
public sealed class PlcEventMessage : AppMessage;
