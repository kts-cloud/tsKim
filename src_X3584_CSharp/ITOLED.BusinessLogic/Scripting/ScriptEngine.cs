// =============================================================================
// ScriptEngine.cs
// Converted from Delphi: src_X3584\pasScriptClass.pas (TScrCls class)
// Per-channel C# Roslyn Script engine: loads scripts, runs sequences, manages state.
// Replaces Delphi TMS TatPascalScripter with Microsoft.CodeAnalysis.CSharp.Scripting.
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Scripting
// =============================================================================

using System;
using System.Collections.Concurrent;
using System.Collections.Immutable;
using System.Linq;
using System.Threading;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp.Scripting;
using Microsoft.CodeAnalysis.Scripting;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Logging;
using Dongaeltek.ITOLED.BusinessLogic.Dfs;
using Dongaeltek.ITOLED.BusinessLogic.Dll;
using Dongaeltek.ITOLED.BusinessLogic.Inspection;
using Dongaeltek.ITOLED.BusinessLogic.Mes;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Hardware.Plc;

namespace Dongaeltek.ITOLED.BusinessLogic.Scripting;

/// <summary>
/// Per-channel script engine implementing <see cref="IScriptRunner"/>.
/// Uses Microsoft.CodeAnalysis.CSharp.Scripting (Roslyn) to compile and
/// execute C# scripts that were originally Delphi Pascal scripts.
/// One instance per PG channel (0..MAX_CH).
/// <para>Delphi origin: TScrCls class (pasScriptClass.pas)</para>
/// </summary>
public sealed class ScriptEngine : IScriptRunner
{
    // =========================================================================
    // Fields
    // =========================================================================

    private readonly int _pgNo;
    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _status;
    private readonly IPathManager _path;
    private readonly IMessageBus _bus;
    private readonly ILogger _logger;
    private readonly ICommPgDriver[] _pg;
    private readonly IDioController _dio;
    private readonly IDllManager _dll;
    private readonly IGmesCommunication? _gmes;
    private readonly IPlcEcsDriver? _plc;
    private readonly IDfsService[] _dfs;
    private readonly IModelInfoService _modelInfo;
    private readonly CommLogger? _mLogLogger;

    /// <summary>
    /// Sequence status array indexed by sequence key (0..SeqMax).
    /// <para>Delphi: SeqStatus : array[SEQ_STOP..SEQ_MAX] of RSeqStatus</para>
    /// </summary>
    private readonly RSeqStatus[] _seqStatus;

    /// <summary>
    /// Compiled script (cached after LoadSource).
    /// <para>Delphi: atPasScrpt : TatPascalScripter</para>
    /// </summary>
    private ScriptRunner<object>? _compiledScript;

    /// <summary>
    /// Persistent script state that preserves top-level variable values across
    /// subroutine calls. Initialized once during LoadSource by running the
    /// script's top-level code (constants, variable declarations, function
    /// definitions). Updated after each ExecuteSubroutine via ContinueWithAsync.
    /// <para>
    /// This is critical: without persisting state, each ExecuteSubroutine call
    /// would re-evaluate the entire script, resetting variables like SummaryCsv
    /// back to null even after Seq_INIT had initialized them.
    /// </para>
    /// </summary>
    private ScriptState<object>? _scriptState;

    /// <summary>
    /// Script source code (stored for recompilation and maintenance scripts).
    /// </summary>
    private string _scriptSource = string.Empty;

    /// <summary>
    /// Script options configured for Roslyn compilation.
    /// </summary>
    private ScriptOptions? _scriptOptions;

    /// <summary>
    /// The ScriptGlobals instance bound to this channel.
    /// Provides all 122 host methods and 37 script variables.
    /// </summary>
    private ScriptGlobals? _globals;

    /// <summary>
    /// Lock flag indicating script thread is active.
    /// <para>Delphi: m_bLockThread : Boolean</para>
    /// </summary>
    private volatile bool _lockThread;

    /// <summary>
    /// Thread terminated status flag.
    /// <para>Delphi: m_bTheadIsTerminated : Boolean</para>
    /// </summary>
    private volatile bool _threadIsTerminated;

    /// <summary>
    /// Whether we are running a maintenance script (not main flow).
    /// <para>Delphi: m_bToMaint : Boolean</para>
    /// </summary>
    private volatile bool _toMaint;

    /// <summary>
    /// Currently executing sequence index.
    /// <para>Delphi: CurrentSEQ : Integer</para>
    /// </summary>
    private int _currentSeq;

    /// <summary>
    /// Whether the script is actively running.
    /// <para>Delphi: atPasScrpt.Running</para>
    /// </summary>
    private volatile bool _isRunning;

    /// <summary>
    /// Whether the script is paused (for spRepeat toggle).
    /// <para>Delphi: atPasScrpt.Paused</para>
    /// </summary>
    private volatile bool _isPaused;

    /// <summary>
    /// Whether script work is active.
    /// <para>Delphi: m_bIsScriptWork : Boolean</para>
    /// </summary>
    private volatile bool _isScriptWork;

    /// <summary>
    /// Cancellation token source for halting scripts.
    /// <para>Replaces Delphi's atPasScrpt.Halt</para>
    /// </summary>
    private CancellationTokenSource? _haltCts;

    /// <summary>
    /// Host event synchronization for MES/ECS callbacks.
    /// <para>Delphi: m_hSyncEvnet : THandle + m_bIsSyncEvent</para>
    /// </summary>
    private readonly ManualResetEventSlim _hostEvent = new(false);

    /// <summary>
    /// Host event return value.
    /// <para>Delphi: m_nHostResult : Integer</para>
    /// </summary>
    private int _hostResult;

    /// <summary>
    /// Whether sync event is in use.
    /// <para>Delphi: m_bIsSyncEvent : Boolean</para>
    /// </summary>
    private volatile bool _isSyncEvent;

    /// <summary>
    /// Inspection status.
    /// <para>Delphi: m_InsStatus : TInsStatus</para>
    /// </summary>
    private InsStatus _insStatus = InsStatus.Ready;

    /// <summary>
    /// Message bus subscription for NextStep messages.
    /// </summary>
    private IDisposable? _nextStepSubscription;

    /// <summary>
    /// Compiled subroutine cache: procedure name -> delegate.
    /// Avoids re-parsing scripts for each RunSeq call.
    /// </summary>
    private readonly ConcurrentDictionary<string, ScriptRunner<object>?> _subroutineCache = new();

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a new script engine for the specified PG channel.
    /// <para>Delphi origin: constructor TScrCls.Create(nPgNo, hMain, hTest, AOwner)</para>
    /// </summary>
    public ScriptEngine(
        int pgNo,
        IConfigurationService config,
        ISystemStatusService status,
        IPathManager path,
        IMessageBus bus,
        ILogger logger,
        ICommPgDriver[] pg,
        IDioController dio,
        IDllManager dll,
        IGmesCommunication? gmes,
        IPlcEcsDriver? plc,
        IDfsService[] dfs,
        IModelInfoService modelInfo,
        CommLogger? mLogLogger = null)
    {
        _pgNo = pgNo;
        _config = config;
        _status = status;
        _path = path;
        _bus = bus;
        _logger = logger;
        _pg = pg;
        _dio = dio;
        _dll = dll;
        _gmes = gmes;
        _plc = plc;
        _dfs = dfs;
        _modelInfo = modelInfo;
        _mLogLogger = mLogLogger;

        // Initialize TestInfo
        _testInfo = new ScriptTestInfo();

        // Compute pair channel (Delphi: if (nPgNo mod 2) = 0 then PairCh := nPgNo+1 else PairCh := nPgNo-1)
        PairChannel = (pgNo % 2 == 0) ? pgNo + 1 : pgNo - 1;

        // Initialize sequence status array (SEQ_STOP..SEQ_MAX)
        _seqStatus = new RSeqStatus[DefScript.SeqMax + 1];
        for (int i = 0; i <= DefScript.SeqMax; i++)
        {
            _seqStatus[i] = new RSeqStatus
            {
                Status = SeqStatus.None,
                Process = SeqProcess.Normal
            };
        }
        // Delphi: SeqStatus[DefScript.SEQ_STOP].Process := spStop
        _seqStatus[DefScript.SeqStop].Process = SeqProcess.Stop;

        _currentSeq = DefScript.SeqStop;
        _lockThread = false;
        _insStatus = InsStatus.Ready;

        // Configure Roslyn script options
        _scriptOptions = CreateScriptOptions();

        // Subscribe to NextStep messages for sequence control
        _nextStepSubscription = _bus.Subscribe<ScriptNextStepMessage>(OnNextStepMessage);
    }

    // =========================================================================
    // IScriptRunner Properties
    // =========================================================================

    /// <inheritdoc />
    public bool IsInUse { get; set; }

    /// <inheritdoc />
    public bool FirstProcessDone { get; set; }

    /// <inheritdoc />
    public bool CelStop { get; set; }

    /// <inheritdoc />
    public bool IsSyncSequence { get; set; }

    /// <inheritdoc />
    public int ConfirmHostReturn { get; set; }

    /// <inheritdoc />
    public bool IsProbeBackSignal { get; set; }

    private readonly ScriptTestInfo _testInfo;

    /// <inheritdoc />
    public ScriptTestInfo TestInfo => _testInfo;

    // =========================================================================
    // Additional Properties (from TScrCls public fields)
    // =========================================================================

    /// <summary>Pair channel index. Delphi: PairCh</summary>
    public int PairChannel { get; }

    /// <summary>Currently executing sequence index. Delphi: CurrentSEQ</summary>
    public int CurrentSequence => _currentSeq;

    /// <summary>
    /// Access to the ScriptGlobals instance (for test forms, maintenance, etc.)
    /// </summary>
    public ScriptGlobals? Globals => _globals;

    /// <inheritdoc />
    public string? ExecuteAutoStart()
    {
        if (_globals == null || _scriptState == null)
        {
            _logger.Warn(_pgNo, "ExecuteAutoStart: script not loaded");
            return "Script not loaded";
        }

        try
        {
            _globals.AutoStartReady = false;
            _globals.AutoStartFailReason = string.Empty;
            SyncPropertiesToGlobals();

            var token = _haltCts?.Token ?? CancellationToken.None;
            _scriptState = _scriptState.ContinueWithAsync<object>(
                "Execute_AutoStart(0);",
                _scriptOptions,
                token).GetAwaiter().GetResult();
            SyncPropertiesFromGlobals();

            if (_globals.AutoStartReady)
                return null; // success

            return string.IsNullOrEmpty(_globals.AutoStartFailReason)
                ? "Unknown error"
                : _globals.AutoStartFailReason;
        }
        catch (Exception ex)
        {
            _logger.Error(_pgNo, $"ExecuteAutoStart error: {ex.Message}", ex);
            return $"Exception: {ex.Message}";
        }
    }

    /// <inheritdoc />
    public bool ExecuteRobotLoad()
    {
        if (_globals == null || _scriptState == null)
        {
            _logger.Warn(_pgNo, "ExecuteRobotLoad: script not loaded");
            return false;
        }

        try
        {
            SyncPropertiesToGlobals();
            var token = _haltCts?.Token ?? CancellationToken.None;
            _scriptState = _scriptState.ContinueWithAsync<object>(
                "Robot_Request_Load(0);",
                _scriptOptions, token).GetAwaiter().GetResult();
            SyncPropertiesFromGlobals();
            return true;
        }
        catch (Exception ex)
        {
            _logger.Error(_pgNo, $"ExecuteRobotLoad error: {ex.Message}", ex);
            return false;
        }
    }

    /// <inheritdoc />
    public bool ExecuteRobotUnload()
    {
        if (_globals == null || _scriptState == null)
        {
            _logger.Warn(_pgNo, "ExecuteRobotUnload: script not loaded");
            return false;
        }

        try
        {
            SyncPropertiesToGlobals();
            var token = _haltCts?.Token ?? CancellationToken.None;
            _scriptState = _scriptState.ContinueWithAsync<object>(
                "Robot_Request_UnLoad(0);",
                _scriptOptions, token).GetAwaiter().GetResult();
            SyncPropertiesFromGlobals();
            return true;
        }
        catch (Exception ex)
        {
            _logger.Error(_pgNo, $"ExecuteRobotUnload error: {ex.Message}", ex);
            return false;
        }
    }

    // =========================================================================
    // IScriptRunner - LoadSource
    // =========================================================================

    /// <summary>
    /// Loads script source code, creates a ScriptGlobals instance, and compiles.
    /// <para>Delphi origin: procedure TScrCls.LoadSource(stData: TStrings)</para>
    /// <para>
    /// In Delphi this sets atPasScrpt.SourceCode, calls DefineMethodFunc, then Compile.
    /// In C# Roslyn, the script source is compiled with ScriptGlobals as the globals type,
    /// so all 122 methods and 37 variables are accessible directly in the script.
    /// </para>
    /// </summary>
    public void LoadSource(IEnumerable<string> scriptSource)
    {
        try
        {
            _scriptSource = string.Join(Environment.NewLine, scriptSource);

            // Create or re-create ScriptGlobals for this channel
            _globals = new ScriptGlobals(
                _pgNo, _config, _status, _path, _bus, _logger,
                _pg, _dio, _dll, _gmes, _plc, _dfs, _modelInfo, _mLogLogger);

            // Synchronize properties from engine to globals
            SyncPropertiesToGlobals();

            // Compile the script with Roslyn
            var script = CSharpScript.Create<object>(
                _scriptSource,
                _scriptOptions,
                globalsType: typeof(ScriptGlobals));

            // Build and cache the compiled runner
            var diagnostics = script.Compile();
            if (HasCompilationErrors(diagnostics))
            {
                string errors = FormatDiagnostics(diagnostics);
                _logger.Error(_pgNo, $"Script compilation failed: {errors}");
                SendGuiMessage(MessageConstants.MsgModeChResult, "SCRIPT LOAD NG", logType: -2);
                SendGuiMessage(MessageConstants.MsgModeWorking, errors, logType: 1);
                return;
            }

            _compiledScript = script.CreateDelegate();
            _subroutineCache.Clear();

            // Run the script once to evaluate top-level code (constants,
            // variable declarations, function definitions) and capture the
            // initial ScriptState. This state will be used as the base for
            // all subsequent ExecuteSubroutine calls via ContinueWithAsync,
            // preserving variable values across sequence calls.
            _scriptState = script.RunAsync(_globals).GetAwaiter().GetResult();

            _logger.Info(_pgNo, "Script compiled and initialized successfully");
        }
        catch (Exception ex)
        {
            _logger.Error(_pgNo, "Script load exception", ex);
            SendGuiMessage(MessageConstants.MsgModeChResult, "SCRIPT LOAD NG", logType: -2);
            SendGuiMessage(MessageConstants.MsgModeWorking, ex.Message, logType: 1);
        }
    }

    // =========================================================================
    // IScriptRunner - InitialScript
    // =========================================================================

    /// <summary>
    /// Initializes script state by executing Seq_INIT procedure.
    /// Called after LoadSource to initialize script-level variables
    /// (SummaryCsv, GRRCsv, PowerCalCsv, CbApdr, etc.).
    /// <para>Delphi origin: procedure TScrCls.InitialScript</para>
    /// <para>Calls ScriptThread('Seq_Init', 0) then CheckAutoVersionInterlock.</para>
    /// </summary>
    public void InitialScript()
    {
        if (_scriptState == null || _globals == null)
        {
            _logger.Warn(_pgNo, "InitialScript skipped — script not loaded");
            return;
        }

        try
        {
            // Delphi: ScriptThread('Seq_Init', 0);
            // We call ExecuteSubroutine directly (synchronous) since this is
            // initialization that must complete before the engine is ready.
            SyncPropertiesToGlobals();
            var token = _haltCts?.Token ?? CancellationToken.None;
            _scriptState = _scriptState.ContinueWithAsync<object>(
                "Seq_INIT(0);",
                _scriptOptions,
                token).GetAwaiter().GetResult();
            SyncPropertiesFromGlobals();

            _logger.Info(_pgNo, "InitialScript (Seq_INIT) completed");
        }
        catch (Exception ex)
        {
            _logger.Error(_pgNo, $"InitialScript error: {ex.Message}", ex);
            SendGuiMessage(MessageConstants.MsgModeChResult, "SCRIPT Initialize NG", logType: 1);
            SendGuiMessage(MessageConstants.MsgModeWorking, ex.Message, logType: 1);
        }
    }

    // =========================================================================
    // IScriptRunner - RunSequence
    // =========================================================================

    /// <summary>
    /// Runs the specified sequence by key index.
    /// <para>Delphi origin: function TScrCls.RunSeq(nIdx: Integer): Integer</para>
    /// <para>
    /// Maps sequence index to procedure name (e.g., SeqKeyStart -> "Seq_Key_Start"),
    /// then launches a background thread via ScriptThread.
    /// Handles running/paused/halt state transitions.
    /// </para>
    /// </summary>
    public int RunSequence(int sequenceKeyIndex)
    {
        // Check PG connection (Delphi: if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit)
        if (_pg.Length > _pgNo && IsPgUnavailable())
        {
            _logger.Warn(_pgNo, $"RunSequence({sequenceKeyIndex}) skipped — PG unavailable (status={_pg[_pgNo].Status})");
            SendGuiMessage(MessageConstants.MsgModeWorking,
                $"PG disconnected — cannot start sequence {sequenceKeyIndex}");
            return DefScript.SeqErrNone;
        }

        // Must be in use
        if (!IsInUse)
        {
            _logger.Warn(_pgNo, $"RunSequence({sequenceKeyIndex}) skipped — channel not in use");
            return DefScript.SeqErrNone;
        }

        // If script is already running...
        if (_isRunning)
        {
            // Repeat mode toggle (Delphi: if SeqStatus[nIdx].Process = spRepeat then toggle Paused)
            if (sequenceKeyIndex < _seqStatus.Length &&
                _seqStatus[sequenceKeyIndex].Process == SeqProcess.Repeat)
            {
                _isPaused = !_isPaused;
                return DefScript.SeqErrRunning;
            }

            // Stop request or process marked as stop
            if (sequenceKeyIndex == DefScript.SeqKeyStop ||
                (sequenceKeyIndex < _seqStatus.Length &&
                 _seqStatus[sequenceKeyIndex].Process == SeqProcess.Stop))
            {
                if (_lockThread && CheckLastIndexStop(sequenceKeyIndex))
                {
                    return DefScript.SeqErrRunning;
                }
                else
                {
                    // Halt the running script
                    HaltScript();
                    Thread.Sleep(100);
                }
            }
        }

        // If thread is locked (running), return busy
        if (_lockThread)
            return DefScript.SeqErrRunning;

        _toMaint = false;

        // Reset sequence status for this index
        if (sequenceKeyIndex < _seqStatus.Length)
            _seqStatus[sequenceKeyIndex].Status = SeqStatus.None;

        // Map sequence index to procedure name
        string seqName = MapSequenceIndexToName(sequenceKeyIndex);
        if (string.IsNullOrEmpty(seqName))
        {
            _logger.Warn(_pgNo, $"Unknown sequence index: {sequenceKeyIndex}");
            return DefScript.SeqErrNone;
        }

        // Save current sequence
        _currentSeq = sequenceKeyIndex;

        // Log the run
        string debugMsg = $"Ch{_pgNo + 1} --- Run Seq : Idx({sequenceKeyIndex}), " +
                          $"status({(int)_seqStatus[sequenceKeyIndex].Status}) - " +
                          $"SCRIPT Implement : procedure Name : ({seqName})";
        SendGuiMessage(MessageConstants.MsgModeWorking, debugMsg);

        // Execute on background thread
        ScriptThread(seqName, sequenceKeyIndex);

        return DefScript.SeqErrNone;
    }

    // =========================================================================
    // IScriptRunner - IsSequenceRunning
    // =========================================================================

    /// <summary>
    /// Checks if a specific sequence key is currently running.
    /// <para>Delphi origin: function TScrCls.ScriptRunning(nKeyIdx: Integer): Boolean</para>
    /// </summary>
    public bool IsSequenceRunning(int sequenceKeyIndex)
    {
        // PG not connected => not running
        if (_pg.Length > _pgNo && IsPgUnavailable())
            return false;

        if (!IsInUse)
            return false;

        // Running AND process is normal
        if (_isRunning && sequenceKeyIndex < _seqStatus.Length &&
            _seqStatus[sequenceKeyIndex].Process == SeqProcess.Normal)
            return true;

        return false;
    }

    // =========================================================================
    // IScriptRunner - IsScriptRunning
    // =========================================================================

    /// <summary>
    /// Checks if any script is currently running on this channel.
    /// <para>Delphi origin: function TScrCls.IsScriptRun: Boolean</para>
    /// </summary>
    public bool IsScriptRunning()
    {
        return _isRunning;
    }

    // =========================================================================
    // IScriptRunner - SetHostEvent
    // =========================================================================

    /// <summary>
    /// Sets the host event return value, signaling the script engine.
    /// <para>Delphi origin: procedure TScrCls.SetHostEvent(nRet: Integer)</para>
    /// </summary>
    public void SetHostEvent(int returnValue)
    {
        if (_isSyncEvent)
        {
            _hostResult = returnValue;
            _hostEvent.Set();
        }
    }

    // =========================================================================
    // IScriptRunner - RefreshHandles
    // =========================================================================

    /// <summary>
    /// Updates internal message routing handles when the UI form changes.
    /// <para>Delphi origin: procedure TScrCls.SetHandleAgain(hMain, hTest: HWND)</para>
    /// <para>In C# with message bus, this is a no-op since routing is via pub/sub.</para>
    /// </summary>
    public void RefreshHandles()
    {
        // No-op in C# version. Message routing is handled by IMessageBus.
        // Delphi used HWND handles for WM_COPYDATA; we use publish/subscribe.
    }

    // =========================================================================
    // Script Execution Core
    // =========================================================================

    /// <summary>
    /// Launches script execution on a background thread.
    /// <para>Delphi origin: procedure TScrCls.ScriptThread(sScriptFunc: string; nFirstParam: Integer)</para>
    /// </summary>
    private void ScriptThread(string scriptFuncName, int firstParam)
    {
        var oldCts = Interlocked.Exchange(ref _haltCts, new CancellationTokenSource());
        oldCts?.Dispose();

        var thread = new Thread(() =>
        {
            try
            {
                _threadIsTerminated = true;
                _lockThread = true;
                _isScriptWork = true;
                _isRunning = true;

                try
                {
                    ExecuteSubroutine(scriptFuncName, firstParam);
                }
                catch (OperationCanceledException)
                {
                    // Script was halted - this is normal flow
                    _logger.Debug(_pgNo, $"Script '{scriptFuncName}' was halted");
                }
                catch (Exception ex)
                {
                    _logger.Error(_pgNo, $"Script '{scriptFuncName}' error: {ex.Message}", ex);
                    SendGuiMessage(MessageConstants.MsgModeChResult, "SCRIPT LOAD NG", logType: -2);
                    SendGuiMessage(MessageConstants.MsgModeWorking, ex.Message, logType: 1);
                }
            }
            finally
            {
                _lockThread = false;
                _isRunning = false;
                ScriptThreadIsDone();
            }
        })
        {
            IsBackground = true,
            Name = $"ScriptEngine_Ch{_pgNo}_{scriptFuncName}",
        };

        // Priority boost for camera zone (Delphi: if sScriptFunc = 'Seq_Cam_Zone' then tpHigher)
        if (scriptFuncName == "Seq_Cam_Zone")
        {
            thread.Priority = ThreadPriority.AboveNormal;
        }

        thread.Start();
    }

    /// <summary>
    /// Executes a named subroutine from the compiled script.
    /// <para>Delphi origin: atPasScrpt.ExecuteSubroutine(sScriptFunc, nFirstParam)</para>
    /// <para>
    /// Uses <see cref="ScriptState{T}.ContinueWithAsync"/> to call the target
    /// procedure while preserving all top-level variable values from previous
    /// calls. This mirrors Delphi's TatPascalScripter.ExecuteSubroutine which
    /// kept global script variables alive across calls.
    /// </para>
    /// </summary>
    private void ExecuteSubroutine(string funcName, int param)
    {
        if (_globals == null || _scriptState == null)
        {
            _logger.Error(_pgNo, $"Cannot execute '{funcName}': script not loaded");
            return;
        }

        // Sync engine state to globals before execution
        SyncPropertiesToGlobals();

        try
        {
            // Use ContinueWithAsync to call the function while preserving
            // all top-level variable state from previous calls.
            // This is critical: without this, variables like SummaryCsv
            // initialized in Seq_INIT would be reset to null when
            // Seq_Key_Start re-evaluates the script's top-level code.
            var token = _haltCts?.Token ?? CancellationToken.None;
            _scriptState = _scriptState.ContinueWithAsync<object>(
                $"{funcName}({param});",
                _scriptOptions,
                token).GetAwaiter().GetResult();
        }
        catch (CompilationErrorException cex)
        {
            _logger.Error(_pgNo, $"Script compilation error calling '{funcName}': {cex.Message}");
            throw;
        }

        // Sync globals state back to engine
        SyncPropertiesFromGlobals();
    }

    /// <summary>
    /// Called when script thread completes (success or error).
    /// <para>Delphi origin: procedure TScrCls.ScriptThreadIsDone(Sender: TObject)</para>
    /// </summary>
    private void ScriptThreadIsDone()
    {
        _logger.Debug(_pgNo, "ScriptThreadIsDone");
        _threadIsTerminated = false;
        _isScriptWork = false;

        // Sync sequence mode (Delphi: if m_bIsSyncSeq then SendTestGuiDisplay MSG_MODE_SYNC_WORK)
        if (IsSyncSequence)
        {
            SendGuiMessage(MessageConstants.MsgModeSyncWork,
                param: _globals?.c_nSyncMode ?? 0);

            if (_insStatus == InsStatus.Stop)
            {
                IsSyncSequence = false;
            }
        }

        // Unload zone completion notification
        if (_currentSeq == DefScript.SeqUnloadZone)
        {
            if (_globals?.c_TestInfo.PreOcReStart != true)
            {
                SendGuiMessage(MessageConstants.MsgModeSyncWork, param: 3);
            }
            else
            {
                SendGuiMessage(MessageConstants.MsgModeWorking,
                    "SEQ_UNLOAD_ZONE Done - PreOcReStart");
            }
        }
    }

    // =========================================================================
    // Sequence Name Mapping
    // =========================================================================

    /// <summary>
    /// Maps a sequence key index to its C# procedure name.
    /// <para>Delphi origin: case nIdx of ... in RunSeq</para>
    /// </summary>
    private static string MapSequenceIndexToName(int index)
    {
        // First, check the primary key mapping (when SeqStatus is None)
        return index switch
        {
            DefScript.SeqStop => "Seq_Stop",
            DefScript.SeqKeyStart => "Seq_Key_Start",
            DefScript.SeqKeyStop => "Seq_Key_Stop",
            DefScript.SeqKey1 => "Seq_Key_1",
            DefScript.SeqKey2 => "Seq_Key_2",
            DefScript.SeqKey3 => "Seq_Key_3",
            DefScript.SeqKey4 => "Seq_Key_4",
            DefScript.SeqKey5 => "Seq_Key_5",
            DefScript.SeqKey6 => "Seq_Key_6",
            DefScript.SeqKey7 => "Seq_Key_7",
            DefScript.SeqKey8 => "Seq_Key_8",
            DefScript.SeqKey9 => "Seq_Key_9",
            DefScript.SeqKeyScan => "Seq_Key_Scan",
            DefScript.SeqCamZone => "Seq_Cam_Zone",
            DefScript.SeqUnloadZone => "Seq_Unload_Zone",
            DefScript.SeqFinish => "Process_Finish",
            DefScript.SeqRestart1 => "Seq_ReStart_1",
            DefScript.SeqMaint1 => "Mainter_1",
            DefScript.SeqMaint2 => "Mainter_2",
            DefScript.SeqMaint3 => "Mainter_3",
            DefScript.SeqMaint4 => "Mainter_4",
            DefScript.SeqMaint5 => "Mainter_5",
            _ => string.Empty,
        };
    }

    /// <summary>
    /// Maps a SeqStatus enum value to its corresponding procedure name.
    /// Used when SeqStatus is not None (secondary mapping from Delphi RunSeq).
    /// <para>Delphi origin: case SeqStatus[nIdx].Status of ... in RunSeq (else branch)</para>
    /// </summary>
    private static string MapSeqStatusToName(SeqStatus status)
    {
        return status switch
        {
            SeqStatus.Seq1 => "Seq_1",
            SeqStatus.Seq2 => "Seq_2",
            SeqStatus.Seq3 => "Seq_3",
            SeqStatus.Seq4 => "Seq_4",
            SeqStatus.Seq5 => "Seq_5",
            SeqStatus.Seq6 => "Seq_6",
            SeqStatus.Seq7 => "Seq_7",
            SeqStatus.Seq8 => "Seq_8",
            SeqStatus.Seq9 => "Seq_9",
            SeqStatus.Seq10 => "Seq_10",
            SeqStatus.Seq11 => "Seq_11",
            SeqStatus.Seq12 => "Seq_12",
            SeqStatus.Seq13 => "Seq_13",
            SeqStatus.Seq14 => "Seq_14",
            SeqStatus.Seq15 => "Seq_15",
            SeqStatus.Seq16 => "Seq_16",
            SeqStatus.Seq17 => "Seq_17",
            SeqStatus.Seq18 => "Seq_18",
            SeqStatus.Seq19 => "Seq_19",
            SeqStatus.Scan => "Seq_Scan",
            SeqStatus.PreStop => "Seq_Pre_Stop",
            SeqStatus.SeqReport => "Seq_Report",
            _ => string.Empty,
        };
    }

    // =========================================================================
    // Script State Management
    // =========================================================================

    /// <summary>
    /// Resets all sequence statuses to initial state.
    /// <para>Delphi origin: procedure TScrCls.ResetScriptStatus</para>
    /// </summary>
    public void ResetScriptStatus()
    {
        for (int i = DefScript.SeqStop; i <= DefScript.SeqMax; i++)
        {
            _seqStatus[i].Status = SeqStatus.None;
            _seqStatus[i].Process = SeqProcess.Normal;
        }
        _seqStatus[DefScript.SeqStop].Process = SeqProcess.Stop;
    }

    /// <summary>
    /// Checks if the last and current index are both SEQ_KEY_STOP.
    /// <para>Delphi origin: function TScrCls.CheckLastIndexStop(nIndex: integer): Boolean</para>
    /// </summary>
    private bool CheckLastIndexStop(int index)
    {
        return _currentSeq == DefScript.SeqKeyStop && index == DefScript.SeqKeyStop;
    }

    /// <summary>
    /// Halts the currently running script.
    /// <para>Replaces Delphi's atPasScrpt.Halt + StopManualKey</para>
    /// </summary>
    private void HaltScript()
    {
        _haltCts?.Cancel();
    }

    /// <summary>
    /// Handles NextStep messages from scripts (f_NextStep calls).
    /// Updates the sequence status array for flow control.
    /// <para>Delphi origin: NextStep_Proc -> SeqStatus[nParam].Status/Process update</para>
    /// </summary>
    private void OnNextStepMessage(ScriptNextStepMessage msg)
    {
        if (msg.Channel != _pgNo) return;

        int stepIdx = msg.StepIndex;
        if (stepIdx >= 0 && stepIdx < _seqStatus.Length)
        {
            _seqStatus[stepIdx].Status = (SeqStatus)msg.Status;
            _seqStatus[stepIdx].Process = (SeqProcess)msg.Process;
        }
    }

    // =========================================================================
    // PG Connection Check
    // =========================================================================

    /// <summary>
    /// Checks if the PG for this channel is unavailable (ForceStop or Disconnected).
    /// <para>Delphi: Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn]</para>
    /// </summary>
    private bool IsPgUnavailable()
    {
        if (_pgNo >= _pg.Length) return true;
        var status = _pg[_pgNo].Status;
        return status == PgStatus.ForceStop || status == PgStatus.Disconnected;
    }

    // =========================================================================
    // Sync Properties Between Engine and Globals
    // =========================================================================

    /// <summary>
    /// Synchronizes engine-level properties into ScriptGlobals before script execution.
    /// These are the bidirectional variables that the Delphi AddVariable calls
    /// bound to TScrCls fields.
    /// </summary>
    private void SyncPropertiesToGlobals()
    {
        if (_globals == null) return;

        _globals.c_nCurCh = _pgNo;
        _globals.c_nScriptPgNo = _pgNo;
        _globals.c_bCEL_Stop = CelStop;
        _globals.c_bIsSyncSeq = IsSyncSequence;
        _globals.c_nConfirmHostRet = ConfirmHostReturn;
        _globals.c_First_Process_DONE = FirstProcessDone;

        // Sync TestInfo fields to the minimal ScriptTestInfo exposed by IScriptRunner
        _globals.c_TestInfo.NgCode = _testInfo.NgCode;
        _globals.c_TestInfo.SerialNo = _testInfo.SerialNo;
        _globals.c_TestInfo.CarrierId = _testInfo.CarrierId;
    }

    /// <summary>
    /// Synchronizes ScriptGlobals properties back into the engine after execution.
    /// </summary>
    private void SyncPropertiesFromGlobals()
    {
        if (_globals == null) return;

        CelStop = _globals.c_bCEL_Stop;
        IsSyncSequence = _globals.c_bIsSyncSeq;
        ConfirmHostReturn = _globals.c_nConfirmHostRet;
        FirstProcessDone = _globals.c_First_Process_DONE;

        // Sync back TestInfo
        _testInfo.NgCode = _globals.c_TestInfo.NgCode;
        _testInfo.Result = _globals.c_TestInfo.Result;
        _testInfo.SerialNo = _globals.c_TestInfo.SerialNo;
        _testInfo.CarrierId = _globals.c_TestInfo.CarrierId;
        _testInfo.FailMessage = _globals.c_TestInfo.Fail_Message;
    }

    // =========================================================================
    // Roslyn Script Options Configuration
    // =========================================================================

    /// <summary>
    /// Creates the ScriptOptions for Roslyn compilation.
    /// Includes all required references and imports for script execution.
    /// </summary>
    private static ScriptOptions CreateScriptOptions()
    {
        return ScriptOptions.Default
            .WithReferences(
                typeof(object).Assembly,                          // System.Runtime
                typeof(Console).Assembly,                         // System.Console
                typeof(Enumerable).Assembly,                      // System.Linq
                typeof(File).Assembly,                            // System.IO
                typeof(Thread).Assembly,                          // System.Threading
                typeof(ScriptGlobals).Assembly,                   // ITOLED.BusinessLogic
                typeof(DefScript).Assembly,                       // ITOLED.Core
                typeof(ICommPgDriver).Assembly                    // ITOLED.Hardware
            )
            .WithImports(
                "System",
                "System.IO",
                "System.Linq",
                "System.Threading",
                "System.Collections.Generic",
                "Dongaeltek.ITOLED.Core.Definitions",
                "Dongaeltek.ITOLED.BusinessLogic.Scripting"
            );
    }

    // =========================================================================
    // Compilation Helpers
    // =========================================================================

    /// <summary>
    /// Checks if compilation diagnostics contain errors.
    /// </summary>
    private static bool HasCompilationErrors(ImmutableArray<Diagnostic> diagnostics)
    {
        return diagnostics.Any(d => d.Severity == DiagnosticSeverity.Error);
    }

    /// <summary>
    /// Formats compilation diagnostics into a readable string.
    /// </summary>
    private static string FormatDiagnostics(ImmutableArray<Diagnostic> diagnostics)
    {
        return string.Join(Environment.NewLine,
            diagnostics
                .Where(d => d.Severity == DiagnosticSeverity.Error)
                .Select(d => d.ToString()));
    }

    // =========================================================================
    // GUI Messaging Helpers
    // =========================================================================

    /// <summary>
    /// Sends a GUI display message via the message bus.
    /// </summary>
    private void SendGuiMessage(int mode, string msg = "", string msg2 = "",
                                int logType = 0, int param = 0)
    {
        _bus.Publish(new ScriptGuiMessage
        {
            Channel = _pgNo,
            Mode = mode,
            Msg = msg,
            Msg2 = msg2,
            LogType = logType,
            Param = param,
        });
    }

    // =========================================================================
    // Host Event Synchronization (for MES/ECS sync commands)
    // =========================================================================

    /// <summary>
    /// Waits for a synchronized command acknowledgment.
    /// <para>Delphi origin: function TScrCls.CheckSyncCmdAck(taskPro: TProc; nDelay, nRetry: Integer): DWORD</para>
    /// </summary>
    /// <param name="beforeWait">Action to execute before waiting (typically sends MES command).</param>
    /// <param name="timeoutMs">Timeout in milliseconds.</param>
    /// <param name="retryCount">Number of retries.</param>
    /// <returns>0 on success (WAIT_OBJECT_0), non-zero on timeout or failure.</returns>
    public int CheckSyncCmdAck(Action beforeWait, int timeoutMs, int retryCount)
    {
        _isSyncEvent = true;
        _hostEvent.Reset();
        _hostResult = 0;

        try
        {
            beforeWait();

            for (int retry = 0; retry < retryCount; retry++)
            {
                if (_hostEvent.Wait(timeoutMs, _haltCts?.Token ?? CancellationToken.None))
                {
                    return 0; // WAIT_OBJECT_0
                }
            }
            return 258; // WAIT_TIMEOUT
        }
        catch (OperationCanceledException)
        {
            return 1; // Cancelled
        }
        finally
        {
            _isSyncEvent = false;
        }
    }

    // =========================================================================
    // Maintenance Script Execution
    // =========================================================================

    /// <summary>
    /// Executes a maintenance script on a separate thread.
    /// <para>Delphi origin: procedure TScrCls.RunMaintScript(hDisplay: HWND; stSource: TScrMemo)</para>
    /// </summary>
    /// <param name="maintSource">Maintenance script source lines.</param>
    public void RunMaintScript(IEnumerable<string> maintSource)
    {
        if (_pg.Length > _pgNo && IsPgUnavailable()) return;
        if (!IsInUse) return;
        if (_isRunning) return;

        _toMaint = true;
        string source = string.Join(Environment.NewLine, maintSource);

        var thread = new Thread(() =>
        {
            try
            {
                _isRunning = true;
                if (_globals != null)
                {
                    SyncPropertiesToGlobals();

                    var script = CSharpScript.Create<object>(
                        source, _scriptOptions, typeof(ScriptGlobals));

                    var diagnostics = script.Compile();
                    if (HasCompilationErrors(diagnostics))
                    {
                        string errors = FormatDiagnostics(diagnostics);
                        SendGuiMessage(MessageConstants.MsgModeChResult, "SCRIPT LOAD NG", logType: -2);
                        SendGuiMessage(MessageConstants.MsgModeWorking, errors, logType: 1);
                        return;
                    }

                    var runner = script.CreateDelegate();
                    var ct = _haltCts?.Token ?? CancellationToken.None;
                    var task = runner(_globals, ct);
                    task.GetAwaiter().GetResult();

                    SyncPropertiesFromGlobals();
                }
            }
            catch (Exception ex)
            {
                SendGuiMessage(MessageConstants.MsgModeChResult, "SCRIPT LOAD NG", logType: -2);
                SendGuiMessage(MessageConstants.MsgModeWorking, ex.Message, logType: 1);
            }
            finally
            {
                _isRunning = false;
                _toMaint = false;
            }
        })
        {
            IsBackground = true,
            Name = $"ScriptEngine_Maint_Ch{_pgNo}",
        };
        thread.Start();
    }

    /// <summary>
    /// Executes a function from the loaded script source and returns its string result.
    /// <para>Delphi origin: function TScrCls.ExecExtraFunction(sScriptFunc: string): string</para>
    /// </summary>
    /// <param name="funcName">Name of the function to execute.</param>
    /// <returns>String result of the function, or empty on error.</returns>
    public string ExecExtraFunction(string funcName)
    {
        if (_globals == null || string.IsNullOrEmpty(_scriptSource))
            return string.Empty;

        try
        {
            SyncPropertiesToGlobals();

            string callScript = $"{_scriptSource}{Environment.NewLine}return {funcName}();";

            var script = CSharpScript.Create<object>(
                callScript, _scriptOptions, typeof(ScriptGlobals));

            var runner = script.CreateDelegate();
            var task = runner(_globals, CancellationToken.None);
            var result = task.GetAwaiter().GetResult();

            SyncPropertiesFromGlobals();

            return result?.ToString() ?? string.Empty;
        }
        catch (Exception ex)
        {
            _logger.Error(_pgNo, $"ExecExtraFunction '{funcName}' failed: {ex.Message}", ex);
            return string.Empty;
        }
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    private bool _disposed;

    /// <summary>
    /// Disposes resources (cancellation tokens, event handles, subscriptions).
    /// <para>Delphi origin: destructor TScrCls.Destroy</para>
    /// </summary>
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        // Cancel any running script
        var cts = Interlocked.Exchange(ref _haltCts, null);
        cts?.Cancel();
        cts?.Dispose();

        // Clean up host event
        _hostEvent.Dispose();

        // Unsubscribe from message bus
        _nextStepSubscription?.Dispose();
        _nextStepSubscription = null;

        _compiledScript = null;
        _scriptState = null;
        _globals = null;
    }
}
