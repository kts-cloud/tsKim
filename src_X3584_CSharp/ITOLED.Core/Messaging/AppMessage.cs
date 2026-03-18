namespace Dongaeltek.ITOLED.Core.Messaging;

/// <summary>
/// Abstract base class for all inter-component messages.
/// Replaces Delphi's <c>TGUIMessage</c> packed record that was
/// marshaled via WM_COPYDATA between forms.
/// <para>
/// Concrete subclasses carry the same fields:
/// Channel, Mode, Param, Param2, Message, and an optional Data payload.
/// The original Delphi MsgType integer is replaced by the concrete class type
/// (e.g. <c>ScriptEventMessage</c> for MSG_TYPE_SCRIPT = 1).
/// </para>
/// </summary>
public abstract class AppMessage
{
    /// <summary>
    /// Inspection channel index (0-based, or -1 for broadcast/all channels).
    /// Delphi: TGUIMessage.Channel
    /// </summary>
    public int Channel { get; init; } = -1;

    /// <summary>
    /// Message mode / sub-command.
    /// Delphi: TGUIMessage.Mode
    /// </summary>
    public int Mode { get; init; }

    /// <summary>
    /// General-purpose parameter.
    /// Delphi: TGUIMessage.Param
    /// </summary>
    public int Param { get; init; }

    /// <summary>
    /// Second general-purpose parameter.
    /// When Data is non-null, this typically carries the payload length
    /// (matching Delphi's convention where Param2 = data length).
    /// </summary>
    public int Param2 { get; init; }

    /// <summary>
    /// Human-readable message text.
    /// Delphi: TGUIMessage.Msg
    /// </summary>
    public string Message { get; init; } = string.Empty;

    /// <summary>
    /// Optional binary payload (replaces Delphi's pData: PBYTE with length = Param2).
    /// Null when no extra data is attached.
    /// </summary>
    public byte[]? Data { get; init; }

    /// <summary>
    /// Timestamp when the message was created.
    /// Not present in the original Delphi record; added for diagnostics and ordering.
    /// </summary>
    public DateTime Timestamp { get; } = DateTime.UtcNow;

    /// <inheritdoc />
    public override string ToString()
        => $"{GetType().Name}[Ch={Channel}, Mode={Mode}, P={Param}, P2={Param2}, Msg=\"{Message}\"]";
}
