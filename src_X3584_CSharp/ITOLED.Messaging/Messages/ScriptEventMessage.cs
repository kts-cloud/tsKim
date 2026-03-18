using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Script engine events (Delphi MSG_TYPE_SCRIPT = 1).
/// Published by the script executor (pasScriptClass/dllClass) to notify
/// the UI and other subsystems of script state changes.
/// </summary>
public sealed class ScriptEventMessage : AppMessage;
