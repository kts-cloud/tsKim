using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Light controller events (Delphi COMM_CAM_LIGHT_CONNECTION = 100).
/// Published by LightNaratechDriver when connection status changes
/// or communication events occur.
/// </summary>
public sealed class LightEventMessage : AppMessage;
