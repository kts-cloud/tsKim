using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Stage movement events (Delphi MSG_TYPE_STAGE = 6).
/// Published when the inspection stage position changes
/// (load, turn, camera zone, unload, etc.).
/// </summary>
public sealed class StageEventMessage : AppMessage;
