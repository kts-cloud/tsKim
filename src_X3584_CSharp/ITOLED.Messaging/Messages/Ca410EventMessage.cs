using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// CA-410 colorimeter events (Delphi MSG_TYPE_CA410 = 15).
/// Published by CA_SDK2 / LibCa410Option when measurement results
/// are available, calibration completes, or errors occur.
/// <para>
/// Original Delphi record: <c>RSyncCa</c> in CA_SDK2.pas carried a
/// <c>bError</c> boolean that is mapped to <see cref="IsError"/>.
/// </para>
/// </summary>
public sealed class Ca410EventMessage : AppMessage
{
    /// <summary>
    /// Indicates whether this event represents an error condition.
    /// Original Delphi: <c>RSyncCa.bError</c>
    /// </summary>
    public bool IsError { get; init; }
}
