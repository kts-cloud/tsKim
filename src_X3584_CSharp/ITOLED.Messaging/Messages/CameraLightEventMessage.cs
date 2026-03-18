using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Camera light controller events (Delphi MSG_TYPE_CAM_LIGHT = 11).
/// Published by CommLightNaratech when light control commands
/// complete or errors occur.
/// </summary>
public sealed class CameraLightEventMessage : AppMessage;
