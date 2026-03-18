using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Switch/button events (Delphi MSG_TYPE_SWITCH = 2).
/// Published by the SwitchBtn module when physical or virtual
/// switch state changes occur.
/// </summary>
public sealed class SwitchEventMessage : AppMessage;
