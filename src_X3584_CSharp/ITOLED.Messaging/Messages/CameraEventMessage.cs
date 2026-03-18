using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Camera events (Delphi MSG_TYPE_CAMERA = 10).
/// Published by CommCameraRadiant when camera captures complete,
/// image processing results are available, or errors occur.
/// </summary>
public sealed class CameraEventMessage : AppMessage;
