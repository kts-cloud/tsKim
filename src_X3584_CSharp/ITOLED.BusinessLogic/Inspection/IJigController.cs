// =============================================================================
// IJigController.cs
// Converted from Delphi: src_X3584\JigControl.pas (TJig public interface)
// Manages jig hardware state and step sequences for TOP/BOTTOM channels.
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Inspection
// =============================================================================

namespace Dongaeltek.ITOLED.BusinessLogic.Inspection;

// =============================================================================
// Supporting Types (from JigControl.pas)
// =============================================================================

/// <summary>
/// Jig operational status enumeration.
/// <para>Delphi origin: TJigStatus = (jsReady, jsLoadReq, jsLoadComplete, jsOutputReq)</para>
/// </summary>
public enum JigStatus
{
    /// <summary>Jig is ready for operation. Delphi: jsReady</summary>
    Ready = 0,

    /// <summary>Load request active. Delphi: jsLoadReq</summary>
    LoadRequest = 1,

    /// <summary>Load completed. Delphi: jsLoadComplete</summary>
    LoadComplete = 2,

    /// <summary>Output request active. Delphi: jsOutputReq</summary>
    OutputRequest = 3,
}

/// <summary>
/// Jig physical position enumeration.
/// <para>Delphi origin: TJigPosition = (jsLoadZone, jsCameraZone)</para>
/// </summary>
public enum JigPosition
{
    /// <summary>Load zone. Delphi: jsLoadZone</summary>
    LoadZone = 0,

    /// <summary>Camera zone. Delphi: jsCameraZone</summary>
    CameraZone = 1,
}

// =============================================================================
// Main Interface
// =============================================================================

/// <summary>
/// Jig controller interface managing jig hardware state and step sequences.
/// Two instances: JIG_A (TOP CH1-CH2) and JIG_B (BOTTOM CH3-CH4).
/// <para>Delphi origin: TJig class (JigControl.pas)</para>
/// </summary>
public interface IJigController : IDisposable
{
    // =========================================================================
    // Properties
    // =========================================================================

    /// <summary>
    /// Current jig index (0=JIG_A, 1=JIG_B).
    /// <para>Delphi: m_nCurJig</para>
    /// </summary>
    int JigIndex { get; }

    /// <summary>
    /// Current jig status.
    /// <para>Delphi: m_JigStatus : TJigStatus</para>
    /// </summary>
    JigStatus Status { get; set; }

    /// <summary>
    /// Key lock flag to prevent double-entry.
    /// <para>Delphi: m_bKeyLock : boolean</para>
    /// </summary>
    bool IsKeyLocked { get; set; }

    // =========================================================================
    // Inspection Start/Stop - TOP (CH1, CH2)
    // =========================================================================

    /// <summary>
    /// Starts inspection for TOP channels (CH1, CH2).
    /// Checks PG connection, running scripts, DIO conditions, and then runs
    /// the specified sequence on each channel's script engine.
    /// <para>Delphi origin: function TJig.StartIspd_TOP(nSeq: Integer): Boolean</para>
    /// </summary>
    /// <param name="sequenceKey">Sequence key to run (DefScript.SEQ_KEY_* constant).</param>
    /// <returns>True if started successfully, false if blocked by preconditions.</returns>
    bool StartInspectionTop(int sequenceKey = 1);

    /// <summary>
    /// Stops inspection for TOP channels (CH1, CH2).
    /// Signals stop to each channel's script engine.
    /// <para>Delphi origin: procedure TJig.StopIspd_TOP</para>
    /// </summary>
    void StopInspectionTop();

    // =========================================================================
    // Inspection Start/Stop - BOTTOM (CH3, CH4)
    // =========================================================================

    /// <summary>
    /// Starts inspection for BOTTOM channels (CH3, CH4).
    /// Checks PG connection, running scripts, DIO conditions, and then runs
    /// the specified sequence on each channel's script engine.
    /// <para>Delphi origin: function TJig.StartIspd_BOTTOM(nSeq: Integer): Boolean</para>
    /// </summary>
    /// <param name="sequenceKey">Sequence key to run (DefScript.SEQ_KEY_* constant).</param>
    /// <returns>True if started successfully, false if blocked by preconditions.</returns>
    bool StartInspectionBottom(int sequenceKey = 1);

    /// <summary>
    /// Stops inspection for BOTTOM channels (CH3, CH4).
    /// Signals stop to each channel's script engine.
    /// <para>Delphi origin: procedure TJig.StopIspd_BOTTOM</para>
    /// </summary>
    void StopInspectionBottom();

    // =========================================================================
    // Per-channel stop
    // =========================================================================

    /// <summary>
    /// Stops inspection for a specific channel.
    /// <para>Delphi origin: procedure TJig.StopIspdCh(nCh: Integer)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-based, CH1..CH4).</param>
    void StopInspectionChannel(int channel);

    // =========================================================================
    // Status Queries
    // =========================================================================

    /// <summary>
    /// Checks whether any script is currently running in this jig's channels.
    /// <para>Delphi origin: function TJig.IsScriptRunning: Boolean</para>
    /// </summary>
    /// <returns>True if any channel's script is running.</returns>
    bool IsScriptRunning();

    // =========================================================================
    // Handle Management
    // =========================================================================

    /// <summary>
    /// Updates internal message routing handles when the UI form changes.
    /// <para>Delphi origin: procedure TJig.SetHandleAgain(hMain, hTest: HWND)</para>
    /// </summary>
    void RefreshHandles();
}
