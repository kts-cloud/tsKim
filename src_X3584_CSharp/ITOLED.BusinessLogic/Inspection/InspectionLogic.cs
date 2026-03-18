// =============================================================================
// InspectionLogic.cs
// Converted from Delphi: src_X3584\LogicVh.pas (TLogic class, 763 lines)
// Per-channel inspection logic: timing, sequence, state, CSV reporting.
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Inspection
// =============================================================================

using System;
using System.Threading;
using System.Threading.Tasks;
using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Models;
using Dongaeltek.ITOLED.Hardware.Fpga;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Messaging.Messages;
using FlashData = Dongaeltek.ITOLED.Core.Definitions.FlashData;

namespace Dongaeltek.ITOLED.BusinessLogic.Inspection;

/// <summary>
/// Per-channel inspection logic.
/// Manages the inspection flow: timing, sequence, state machine, CSV reporting.
/// One instance per PG channel (0..MAX_CH).
/// <para>Delphi origin: TLogic class (LogicVh.pas)</para>
/// </summary>
public sealed class InspectionLogic : IInspectionLogic
{
    // =========================================================================
    // Dependencies (injected)
    // =========================================================================

    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _systemStatus;
    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly ICommPgDriver _pgDriver;

    // =========================================================================
    // State Fields (from Delphi TLogic private section)
    // =========================================================================

    /// <summary>PG channel index (0-based). Delphi: FPgNo</summary>
    private readonly int _pgIndex;

    /// <summary>Thread lock flag - only one task at a time. Delphi: FLockThread</summary>
    private volatile bool _lockThread;

    /// <summary>Stop key lock to prevent re-entry. Delphi: FbStopKeyLock</summary>
    private volatile bool _stopKeyLock;

    /// <summary>Logic-level lock. Delphi: m_bLogicLock</summary>
    private volatile bool _logicLock;

    /// <summary>Camera event return code. Delphi: m_nCamRet</summary>
    private int _camReturnCode = -1;

    /// <summary>Camera event signaling flag. Delphi: m_bCamEvnt</summary>
    private volatile bool _cameraEventActive;

    /// <summary>Camera event handle (replaced with ManualResetEventSlim). Delphi: m_hCamEvnt</summary>
    private readonly ManualResetEventSlim _cameraEvent = new(false);

    /// <summary>EE repeat counter. Delphi: m_nEERepeat</summary>
    private int _eeRepeat;

    /// <summary>Configuration data string. Delphi: m_sConfigData</summary>
    private string _configData = string.Empty;

    /// <summary>Current pattern index. Delphi: m_nCurPat</summary>
    private int _currentPattern;

    /// <summary>Synchronization lock for thread task. Replaces Delphi FLockThread boolean guard.</summary>
    private readonly object _taskLock = new();

    private bool _disposed;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a new InspectionLogic instance for the specified PG channel.
    /// <para>Delphi origin: constructor TLogic.Create(nPgNo: Integer; hMain, hTest: HWND)</para>
    /// </summary>
    /// <param name="pgIndex">PG channel index (0-based).</param>
    /// <param name="config">Configuration service (replaces Common global).</param>
    /// <param name="systemStatus">System status service (replaces Common.StatusInfo).</param>
    /// <param name="messageBus">Message bus (replaces SendMessage/WM_COPYDATA).</param>
    /// <param name="logger">Logger instance.</param>
    /// <param name="pgDriver">PG driver for this channel.</param>
    public InspectionLogic(
        int pgIndex,
        IConfigurationService config,
        ISystemStatusService systemStatus,
        IMessageBus messageBus,
        ILogger logger,
        ICommPgDriver pgDriver)
    {
        _pgIndex = pgIndex;
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _systemStatus = systemStatus ?? throw new ArgumentNullException(nameof(systemStatus));
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _pgDriver = pgDriver ?? throw new ArgumentNullException(nameof(pgDriver));

        _logicLock = false;
        _lockThread = false;
        _stopKeyLock = false;

        FlashAllData = new FlashData();
        Inspection = new InspectionInfo();

        InitializeData();
    }

    // =========================================================================
    // IInspectionLogic Properties
    // =========================================================================

    /// <inheritdoc />
    public int PgIndex => _pgIndex;

    /// <inheritdoc />
    public InspectionInfo Inspection { get; private set; }

    /// <inheritdoc />
    public InspectionStatus Status { get; private set; }

    /// <inheritdoc />
    public bool IsInUse { get; set; }

    /// <inheritdoc />
    public bool IsSoftwareStarted { get; set; }

    /// <inheritdoc />
    public FlashData FlashAllData { get; }

    /// <inheritdoc />
    public PatterGroup? PatternGroup { get; set; }

    // =========================================================================
    // IInspectionLogic - Initialization
    // =========================================================================

    /// <inheritdoc />
    public void InitializeData()
    {
        // Delphi: FillChar(m_Inspect,SizeOf(m_Inspect),0) + manual resets
        Inspection.Reset();
        Inspection.PowerOn = false;
        Status = InspectionStatus.Stop;
        _eeRepeat = 0;
        _camReturnCode = -1;
        _configData = string.Empty;
        _currentPattern = 0;
    }

    // =========================================================================
    // IInspectionLogic - Inspection Flow
    // =========================================================================

    /// <inheritdoc />
    public bool StartBcrScan()
    {
        // Delphi: if Pg[FPgNo].StatusPg = pgDisconn then Exit(False);
        if (_pgDriver.Status == PgStatus.Disconnected)
            return false;

        RunThreadTask(() =>
        {
            // Delphi: InitialData; SendMainGuiDisplay(...); SendMainGuiDisplay(...)
            InitializeData();
            PublishMainGuiDisplay(MsgMode.ChClear);
            PublishMainGuiDisplay(MsgMode.BarcodeReady);
        });

        return true;
    }

    /// <inheritdoc />
    public void StartSequence(int index)
    {
        // Delphi: Currently commented out in the original code.
        // Kept as a stub matching the Delphi source structure.
        // The original code was:
        //   if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
        //   if not m_bUse then Exit;
        //   ThreadTask(procedure begin ... end);
    }

    /// <inheritdoc />
    public void StopInspection()
    {
        // Delphi: if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
        if (_pgDriver.Status is PgStatus.ForceStop or PgStatus.Disconnected)
            return;

        // Delphi: if not m_bUse then Exit;
        if (!IsInUse)
            return;

        StopPowerMeasureTimer();

        RunThreadTask(() =>
        {
            // Delphi: Pg[FPgNo].SendPowerOn(0);
            _pgDriver.SendPowerOn(0);
            PublishTestGuiDisplay(MsgMode.Working, "Power Off");
            Inspection.PowerOn = false;
            // Delphi: Pg[FPgNo].StatusPg := pgDone;
            // Note: PgStatus.Done would be set via the driver; the driver manages its own state
        });
    }

    /// <inheritdoc />
    public void StopPlcWork()
    {
        // Delphi: if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
        if (_pgDriver.Status is PgStatus.ForceStop or PgStatus.Disconnected)
            return;

        // Delphi: if not m_bUse then Exit;
        if (!IsInUse)
            return;

        // Delphi: Currently commented out in original - m_InsStatus := IsStop; SendMainGuiDisplay(...)
    }

    /// <inheritdoc />
    public void ReportInspection()
    {
        // Delphi: {$IFNDEF SIMULATOR_PG} if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit; {$ENDIF}
        if (!_config.AppConfig.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            if (_pgDriver.Status is PgStatus.ForceStop or PgStatus.Disconnected)
                return;
        }

        // Delphi: if not m_bUse then Exit;
        if (!IsInUse)
            return;

        // Delphi: if FbStopKeyLock then Exit;
        if (_stopKeyLock)
            return;

        _stopKeyLock = true;

        // Delphi: If FLockThread then force-stop the PG first, then run report task
        // Use force=true to bypass the lock check when a previous task is still running
        RunThreadTask(() => ExecuteReportSequence(), force: _lockThread);

        IsSoftwareStarted = false;
    }

    /// <inheritdoc />
    public void StopFromAlarm()
    {
        // Delphi: Currently commented out in original source.
        // Kept as stub matching original structure.
    }

    /// <inheritdoc />
    public void StopPowerMeasureTimer()
    {
        // Delphi: Pg[Self.FPgNo].SetPowerMeasureTimer(False);
        // Currently a no-op in Delphi (commented out).
    }

    // =========================================================================
    // IInspectionLogic - PG Operations
    // =========================================================================

    /// <inheritdoc />
    public bool IsPgConnected()
    {
        // Delphi: if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Result := False
        //         else Result := True;
        return _pgDriver.Status is not (PgStatus.ForceStop or PgStatus.Disconnected);
    }

    /// <inheritdoc />
    public int FlashRead(int startAddr, int flashReadSize)
    {
        // Delphi: Result := 1; (default = failure)
        string flowMsg = $"FLASH Read nStartAddr: 0x{startAddr:X4} FlashReadSize: {flashReadSize}";
        PublishTestGuiDisplay(MsgMode.Working, flowMsg);

        // Delphi: dwRtn := Pg[FPgNo].SendFlashRead(nStartAddr, nFlashReadSize, @m_FlashAllData.Data[0]);
        uint result = _pgDriver.SendFlashRead(
            (uint)startAddr,
            (uint)flashReadSize,
            FlashAllData.Data);

        const uint WAIT_OBJECT_0 = 0;
        if (result != WAIT_OBJECT_0)
        {
            return 1; // failure
        }

        FlashAllData.StartAddr = startAddr;
        FlashAllData.Size = flashReadSize;
        FlashAllData.IsValid = true;

        return 0; // success
    }

    /// <inheritdoc />
    public void MakeTestEndEvent(int indexError)
    {
        // Delphi: m_nCamRet := nIdxErr;
        //         if m_bCamEvnt then SetEvent(m_hCamEvnt);
        _camReturnCode = indexError;
        if (_cameraEventActive)
        {
            _cameraEvent.Set();
        }
    }

    // =========================================================================
    // IInspectionLogic - CSV / Data
    // =========================================================================

    /// <inheritdoc />
    public CsvResult GetCsvData(int tactTime)
    {
        // Delphi origin: procedure TLogic.GetCsvData(var sHead, sData: string; nTactTime: Integer)
        Inspection.TimeEnd = DateTime.Now;

        var result = new CsvResult();

        // SW Version, Script VERSION
        // Delphi: sHead := 'S/W_VER,Script_VER';
        //         sData := format('%s,%s',[common.GetVersionDate, Script.m_sScriptVer]);
        result.Header = "S/W_VER,Script_VER";
        string versionDate = CommonUtility.GetVersionDate(
            _config.SystemInfo.FwVer,
            ProgramInfo.ProgramName);
        result.Data = $"{versionDate},{_config.SystemInfo.ScriptVer}";

        // PG version
        // Delphi: sHead := sHead + ',PG F/W,PG BOOT,PG FPGA,POWER';
        result.Header += ",PG F/W,PG BOOT,PG FPGA,POWER";

        // EQP ID, CH, Carrier ID, Serial Number
        // Delphi: sHead := sHead + ',EQP_ID,CH,Carrier_Id,SerialNumber';
        //         sData := sData + Format(',%s,%d,%s,%s',[...]);
        result.Header += ",EQP_ID,CH,Carrier_Id,SerialNumber";
        result.Data += $",{_config.SystemInfo.EQPId},{_pgIndex + 1},{Inspection.CarrierId},{Inspection.SerialNo}";

        // Result, Failed Message
        // Delphi: if Trim(m_Inspect.Result) <> '' then sTemp1 := 'Failed' else sTemp1 := 'Pass';
        result.Header += ",Final_Pass_Failed,Failed_Message";
        string passFailText = string.IsNullOrWhiteSpace(Inspection.Result) ? "Pass" : "Failed";
        result.Data += $",{passFailText},{Inspection.FailMessage}";

        // Tact Time
        // Delphi: sHead := sHead + ',Start_Date,Start_Time,End_Time,Tact_Time';
        result.Header += ",Start_Date,Start_Time,End_Time,Tact_Time";
        string startDate = Inspection.TimeStart.ToString("yyyy/MM/dd");
        string startTime = Inspection.TimeStart.ToString("HH:mm:ss");
        string endTime = Inspection.TimeEnd.ToString("HH:mm:ss");
        int secondsBetween = (int)(Inspection.TimeEnd - Inspection.TimeStart).TotalSeconds;
        result.Data += $",{startDate},{startTime},{endTime},{secondsBetween}";

        // Jig Tact
        result.Header += ",Jig_Tact";
        result.Data += $",{tactTime / 10.0:F1}";

        // Separator marker between standard and custom data
        // Delphi: sHead := sHead + ',#'; sData := sData + ',#';
        result.Header += ",#";
        result.Data += ",#";

        // Custom inspection data
        // Delphi: sHead := sHead + m_Inspect.csvHeader; sData := sData + m_Inspect.csvData;
        result.Header += Inspection.CsvHeader;
        result.Data += Inspection.CsvData;

        return result;
    }

    // =========================================================================
    // IInspectionLogic - Model Download
    // =========================================================================

    /// <inheritdoc />
    public void SendModelInfoDownload(int sendDataCount, FileTranStr[] fileTransRecords)
    {
        // Delphi: Currently commented out in original source.
        // Kept as stub matching original structure.
    }

    // =========================================================================
    // Private Helpers
    // =========================================================================

    /// <summary>
    /// Executes the report sequence (power off, CSV generation, GMES send).
    /// Shared by both locked-thread and unlocked-thread paths in ReportInspection.
    /// <para>Delphi origin: inline anonymous procedure within TLogic.ReportInspection</para>
    /// </summary>
    private void ExecuteReportSequence()
    {
        // Delphi: sleep(10); Pg[FPgNo].SendPowerOn(0);
        Thread.Sleep(10); // Brief delay to allow lock release to propagate
        _pgDriver.SendPowerOn(0);

        if (Inspection.IsReport)
        {
            // Delphi: SendMainGuiDisplay(defCommon.MSG_MODE_MAKE_SUMMARY_CSV);
            PublishMainGuiDisplay(MsgMode.MakeSummaryCsv);

            // Delphi: if DongaGmes <> nil then begin
            //   Wait up to 20 seconds for GMES send slot, then force send
            //   Thread collision prevention with TIB driver
            // end;
            // GMES send is now handled asynchronously via message bus
            PublishMainGuiDisplay(MsgMode.SendGmes);
        }

        _stopKeyLock = false;
        // Delphi: Pg[FPgNo].StatusPg := pgDone;
        PublishMainGuiDisplay(MsgMode.FlowStopReport);
    }

    /// <summary>
    /// Runs a task on a background thread, ensuring only one task runs at a time per channel.
    /// <para>Delphi origin: procedure TLogic.ThreadTask(task: TProc)</para>
    /// </summary>
    /// <param name="action">The action to execute.</param>
    private void RunThreadTask(Action action, bool force = false)
    {
        // Delphi: if FLockThread then Exit;
        //         FLockThread := True;
        //         thLogic := TThread.CreateAnonymousThread(...)
        lock (_taskLock)
        {
            if (_lockThread && !force)
                return;
            _lockThread = true;
        }

        Task.Run(() =>
        {
            try
            {
                action();
            }
            catch (Exception ex)
            {
                _logger.Error($"InspectionLogic[Ch{_pgIndex}] ThreadTask error", ex);
            }
            finally
            {
                _lockThread = false;
                _logicLock = false;
            }
        });
    }

    /// <summary>
    /// Publishes a logic event message to the main form via the message bus.
    /// <para>Delphi origin: procedure TLogic.SendMainGuiDisplay(nGuiMode, nP1, nP2, nP3)</para>
    /// </summary>
    private void PublishMainGuiDisplay(int mode, int p1 = 0, int p2 = 0, int p3 = 0)
    {
        _messageBus.Publish(new LogicEventMessage
        {
            Channel = _pgIndex,
            Mode = mode,
            Param = p1,
            Param2 = p2,
        });
    }

    /// <summary>
    /// Publishes a GUI log message to the test form via the message bus.
    /// <para>Delphi origin: procedure TLogic.SendTestGuiDisplay(nGuiMode, sMsg, nParam)</para>
    /// </summary>
    private void PublishTestGuiDisplay(int mode, string message = "", int param = 0)
    {
        _messageBus.Publish(new GuiLogMessage
        {
            Channel = _pgIndex % 4,
            Mode = mode,
            Param = param,
            Message = message,
        });
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed)
            return;

        _disposed = true;

        // Delphi: if m_bCamEvnt then SetEvent(m_hCamEvnt); Sleep(10);
        if (_cameraEventActive)
        {
            _cameraEvent.Set();
        }
        Thread.Sleep(10);

        _cameraEvent.Dispose();
    }
}
