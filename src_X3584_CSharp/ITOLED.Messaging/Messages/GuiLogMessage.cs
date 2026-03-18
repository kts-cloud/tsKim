using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// General-purpose log message for display on the UI.
/// This is a new message type (no direct Delphi MSG_TYPE equivalent)
/// used to decouple log sinks from the GUI layer.
/// <para>
/// The <see cref="AppMessage.Mode"/> field carries the log severity:
/// 0 = Info, 1 = Warning, 2 = Error.
/// </para>
/// </summary>
public sealed class GuiLogMessage : AppMessage
{
    /// <summary>Log severity: Info.</summary>
    public const int SeverityInfo = 0;

    /// <summary>Log severity: Warning.</summary>
    public const int SeverityWarning = 1;

    /// <summary>Log severity: Error.</summary>
    public const int SeverityError = 2;

    /// <summary>
    /// Convenience factory for an informational GUI log entry.
    /// </summary>
    public static GuiLogMessage Info(string message, int channel = -1)
        => new() { Channel = channel, Mode = SeverityInfo, Message = message };

    /// <summary>
    /// Convenience factory for a warning GUI log entry.
    /// </summary>
    public static GuiLogMessage Warning(string message, int channel = -1)
        => new() { Channel = channel, Mode = SeverityWarning, Message = message };

    /// <summary>
    /// Convenience factory for an error GUI log entry.
    /// </summary>
    public static GuiLogMessage Error(string message, int channel = -1)
        => new() { Channel = channel, Mode = SeverityError, Message = message };
}
