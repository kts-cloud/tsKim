// =============================================================================
// IScriptRunner.cs
// Converted from Delphi: src_X3584\pasScriptClass.pas (TScrCls public interface)
// Per-channel Pascal Script engine: loads scripts, runs sequences, manages state.
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Inspection
// =============================================================================

namespace Dongaeltek.ITOLED.BusinessLogic.Inspection;

/// <summary>
/// Minimal test information record exposed by the script runner.
/// <para>Delphi origin: TTestInformation class (pasScriptClass.pas line 95)</para>
/// </summary>
public class ScriptTestInfo
{
    /// <summary>Delphi: NgCode : Integer</summary>
    public int NgCode { get; set; }

    /// <summary>Delphi: Result : string</summary>
    public string Result { get; set; } = string.Empty;

    /// <summary>Delphi: SerialNo : string</summary>
    public string SerialNo { get; set; } = string.Empty;

    /// <summary>Delphi: CarrierId : string</summary>
    public string CarrierId { get; set; } = string.Empty;

    /// <summary>Delphi: Fail_Message : string</summary>
    public string FailMessage { get; set; } = string.Empty;
}

/// <summary>
/// Per-channel script engine interface.
/// Wraps the Pascal Script execution engine that drives inspection sequences.
/// One instance per PG channel (0..MAX_CH).
/// <para>Delphi origin: TScrCls class (pasScriptClass.pas)</para>
/// </summary>
public interface IScriptRunner : IDisposable
{
    // =========================================================================
    // Properties
    // =========================================================================

    /// <summary>
    /// Whether this channel is in use for script execution.
    /// <para>Delphi: m_bUse : Boolean</para>
    /// </summary>
    bool IsInUse { get; set; }

    /// <summary>
    /// Whether the first process (PreOC initial step) has been completed.
    /// <para>Delphi: m_First_Process_DONE : Boolean</para>
    /// </summary>
    bool FirstProcessDone { get; set; }

    /// <summary>
    /// CEL (Cancel/Error/Limit) stop flag. Set true to force-stop.
    /// <para>Delphi: m_bCEL_Stop : Boolean</para>
    /// </summary>
    bool CelStop { get; set; }

    /// <summary>
    /// Whether this channel is in synchronization sequence mode.
    /// <para>Delphi: m_bIsSyncSeq : Boolean</para>
    /// </summary>
    bool IsSyncSequence { get; set; }

    /// <summary>
    /// Host confirm return code (0=not confirmed, 1=already inspected).
    /// Used for EICR flow control in PreOC.
    /// <para>Delphi: m_nConfirmHostRet : Integer</para>
    /// </summary>
    int ConfirmHostReturn { get; set; }

    /// <summary>
    /// Probe backward signal flag.
    /// <para>Delphi: m_bIsProbeBackSig : Boolean</para>
    /// </summary>
    bool IsProbeBackSignal { get; set; }

    /// <summary>
    /// Test information record for this channel.
    /// <para>Delphi: TestInfo : TTestInformation</para>
    /// </summary>
    ScriptTestInfo TestInfo { get; }

    // =========================================================================
    // Script Operations
    // =========================================================================

    /// <summary>
    /// Loads script source code into the engine.
    /// <para>Delphi origin: procedure TScrCls.LoadSource(stData: TStrings)</para>
    /// </summary>
    /// <param name="scriptSource">Script source lines.</param>
    void LoadSource(IEnumerable<string> scriptSource);

    /// <summary>
    /// Initializes script state by executing Seq_INIT procedure.
    /// Must be called after LoadSource to initialize script-level variables
    /// (SummaryCsv, GRRCsv, PowerCalCsv, CbApdr, etc.).
    /// <para>Delphi origin: procedure TScrCls.InitialScript</para>
    /// </summary>
    void InitialScript();

    /// <summary>
    /// Runs the specified sequence by key index.
    /// <para>Delphi origin: function TScrCls.RunSeq(nIdx: Integer): Integer</para>
    /// </summary>
    /// <param name="sequenceKeyIndex">Sequence key index (DefScript.SeqKey* constants).</param>
    /// <returns>0 on success, non-zero on error.</returns>
    int RunSequence(int sequenceKeyIndex);

    /// <summary>
    /// Checks if a specific sequence key is currently running.
    /// <para>Delphi origin: function TScrCls.ScriptRunning(nKeyIdx: Integer): Boolean</para>
    /// </summary>
    /// <param name="sequenceKeyIndex">Sequence key index to check.</param>
    /// <returns>True if the specified sequence is running.</returns>
    bool IsSequenceRunning(int sequenceKeyIndex);

    /// <summary>
    /// Checks if any script is currently running on this channel.
    /// <para>Delphi origin: function TScrCls.IsScriptRun: Boolean</para>
    /// </summary>
    /// <returns>True if any script is actively running.</returns>
    bool IsScriptRunning();

    /// <summary>
    /// Sets the host event return value, signaling the script engine.
    /// <para>Delphi origin: procedure TScrCls.SetHostEvent(nRet: Integer)</para>
    /// </summary>
    /// <param name="returnValue">Return value to pass to the waiting script.</param>
    void SetHostEvent(int returnValue);

    /// <summary>
    /// Updates internal message routing handles when the UI form changes.
    /// <para>Delphi origin: procedure TScrCls.SetHandleAgain(hMain, hTest: HWND)</para>
    /// </summary>
    void RefreshHandles();

    /// <summary>
    /// Executes Execute_AutoStart(0) defined in the model CSX script.
    /// Called from Dashboard AUTO START button.
    /// <para>Delphi origin: Main_OC.pas Execute_AutoStart</para>
    /// </summary>
    /// <returns>Null if setup succeeded, failure reason string if failed.</returns>
    string? ExecuteAutoStart();

    /// <summary>
    /// Executes Robot_Request_Load() in CSX. Called when no panel detected.
    /// <para>Delphi origin: Main_OC.pas Robot_Request_Load</para>
    /// </summary>
    bool ExecuteRobotLoad();

    /// <summary>
    /// Executes Robot_Request_UnLoad() in CSX. Called when user selects unload.
    /// <para>Delphi origin: Main_OC.pas Robot_Request_UnLoad</para>
    /// </summary>
    bool ExecuteRobotUnload();
}
