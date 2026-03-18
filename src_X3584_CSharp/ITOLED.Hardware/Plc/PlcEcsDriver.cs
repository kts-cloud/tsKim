// =============================================================================
// PlcEcsDriver.cs
// Complete PLC/ECS communication driver.
// Converted from Delphi: src_X3584\CommPLC_ECS.pas (TCommPLCThread, 5769 lines)
//
// Conversion rules applied:
//   TCommPLCThread          -> PlcEcsDriver : IPlcEcsDriver, IDisposable
//   TThread.Execute          -> Task.Run + CancellationToken
//   PLC access via IActUtlType interface
//   SendMessage(WM_COPYDATA) -> IMessageBus.Publish<PlcEventMessage>()
//   TCriticalSection         -> lock (_writeLock)
//   TThreadSafeQue<T>        -> ConcurrentQueue<T>
//   Sleep(100)               -> await Task.Delay(100, ct)
//   Common.SystemInfo.xxx    -> _config.SystemInfo.xxx
//   Common.PLCInfo.xxx       -> _config.PlcInfo.xxx
//   AddLog()                 -> _logger.Info() / _logger.Debug()
//
// Namespace: Dongaeltek.ITOLED.Hardware.Plc
// =============================================================================

using System.Collections.Concurrent;
using System.Text;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Models;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Plc;

/// <summary>
/// Full PLC/ECS communication driver implementing <see cref="IPlcEcsDriver"/>.
/// <para>Delphi origin: TCommPLCThread (CommPLC_ECS.pas)</para>
/// </summary>
public sealed partial class PlcEcsDriver : IPlcEcsDriver
{
    // =========================================================================
    // Dependencies (injected)
    // =========================================================================

    private IActUtlType? _actUtl;
    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _status;

    // =========================================================================
    // Synchronisation
    // =========================================================================

    private readonly object _writeLock = new();
    private readonly object _logLock = new();

    // =========================================================================
    // Background task
    // =========================================================================

    private CancellationTokenSource? _cts;
    private Task? _pollingTask;
    private volatile int _stopped; // 0 = running, 1 = stopped

    // =========================================================================
    // Internal state (Delphi: m_* fields)
    // =========================================================================

    private int _resultRobot;
    private int _resultEcs;
    private int _resultEqp;
    private int _resultCv;
    private int _statusMode;        // m_nStatus
    private int _statusOnline;      // m_nStatus_ONLINE
    private bool _opened;           // m_bOpend
    private int _robotDataSize;     // m_nRobotDataSize
    private int _eqpDataSize;       // m_nEQPDataSize

    // ── Queues ──────────────────────────────────────────────────────────────
    private readonly ConcurrentQueue<AlarmItem> _alarmQueue = new();
    private readonly ConcurrentQueue<MesItem> _mesQueue = new();
    private volatile bool _mesWorking;

    // ── Tick tracking ───────────────────────────────────────────────────────
    private long _lastAlarmTick;
    private long _lastMesTick;
    private long _linkTestTick;

    // ── Log accumulation ────────────────────────────────────────────────────
    private readonly StringBuilder _logBuffer = new();
    private DateTime _logSaveTime = DateTime.Now;
    private string _logPath = string.Empty;
    private int _logAccumulateCount = 30;
    private int _logAccumulateSecond = 10;

    // ── Simulator memory ──────────────────────────────────────────────────
    private PlcSimulatorMemory? _simMemory;

    // ── Disposed flag ───────────────────────────────────────────────────────
    private bool _disposed;

    // =========================================================================
    // Public properties - IPlcEcsDriver
    // =========================================================================

    /// <inheritdoc />
    /// <remarks>
    /// True only when both the driver is opened AND the underlying transport is connected.
    /// Prevents false-positive when _opened=true but TCP to ActUtilTCPServer.exe is down.
    /// </remarks>
    public bool Connected => _opened && (_actUtl?.Connected ?? true);

    /// <inheritdoc />
    public long PollingInterval { get; set; } = 500;

    /// <inheritdoc />
    public uint ConnectionTimeout { get; set; } = 10000;

    /// <inheritdoc />
    public uint EcsTimeout { get; set; } = 10000;

    /// <inheritdoc />
    public bool ConnectionError { get; private set; }

    /// <inheritdoc />
    public bool IgnoreConnect { get; set; }

    /// <inheritdoc />
    public bool InlineGib { get; set; }

    /// <inheritdoc />
    public bool UseSimulator { get; private set; }

    /// <inheritdoc />
    public int EqpId { get; private set; }

    /// <inheritdoc />
    public bool IsLoggedIn { get; set; }

    /// <inheritdoc />
    public int LastHeavyCode { get; private set; }

    /// <inheritdoc />
    public int LastLightCode { get; private set; }

    /// <inheritdoc />
    public string LogPath
    {
        get => _logPath;
        set
        {
            _logPath = value;
            if (!string.IsNullOrEmpty(_logPath) && !Directory.Exists(_logPath))
                Directory.CreateDirectory(_logPath);
        }
    }

    // ── Polling data arrays ─────────────────────────────────────────────────

    /// <inheritdoc />
    public int[] PollingData { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public int[] PollingDataPre { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public int[] PollingEcs { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public int[] PollingEcsPre { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public int[] PollingEqp { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public int[] PollingEqpPre { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public int[] PollingCv { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public int[] PollingCvPre { get; private set; } = Array.Empty<int>();

    /// <inheritdoc />
    public long PollingDoorOpened { get; set; }

    /// <inheritdoc />
    public int PollingAabMode { get; set; }

    // ── Glass data ──────────────────────────────────────────────────────────

    /// <inheritdoc />
    public EcsGlassData[] GlassData { get; } = CreateGlassDataArray(9);

    /// <inheritdoc />
    public EcsGlassData[] EcsGlassDataArray { get; } = CreateGlassDataArray(9);

    /// <inheritdoc />
    public string[] EcsLcmId { get; } = new string[8];

    /// <inheritdoc />
    public bool[] UnloadOnly { get; } = new bool[4];

    /// <inheritdoc />
    public int[] RequestStateLoad { get; } = new int[4];

    /// <inheritdoc />
    public int[] RequestStateUnload { get; } = new int[4];

    /// <inheritdoc />
    public bool[] RobotLoadingStatus { get; } = new bool[4];

    // ── PLC start addresses ─────────────────────────────────────────────────

    private int StartAddrEqp;
    private int StartAddrEcs;
    private int StartAddrRobot;
    private int StartAddrRobot2;
    private int StartAddrEqpW;
    private int StartAddrEcsW;
    private int StartAddrRobotW;
    private int StartAddrRobotW2;
    private int StartAddrRobotDoorBit;

    // Second set (computed from first set in Delphi)
    private int StartAddr2Eqp;
    private int StartAddr2Ecs;
    private int StartAddr2Robot;
    private int StartAddr2EqpW;
    private int StartAddr2EcsW;
    private int StartAddr2RobotW;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates the PLC/ECS driver.
    /// <para>Delphi origin: TCommPLCThread.Create (line 677)</para>
    /// </summary>
    public PlcEcsDriver(
        IActUtlType? actUtl,
        IMessageBus messageBus,
        ILogger logger,
        IConfigurationService config,
        ISystemStatusService status)
    {
        _actUtl = actUtl;
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _status = status ?? throw new ArgumentNullException(nameof(status));

        // Delphi: TCommPLCThread.Create(..., Common.PLCInfo.Use_Simulation)
        UseSimulator = _config.PlcInfo.UseSimulation;
        if (_actUtl is null) UseSimulator = true;
        InlineGib = _config.PlcInfo.InlineGIB;

        // Robot data size: GIB uses 8 (2 per channel interlock), else 4
        _robotDataSize = InlineGib ? 8 : 4;

        // EQP data size depends on OCType and InlineGIB
        if (_config.SystemInfo.OCType == ChannelConstants.OcType)
            _eqpDataSize = 16;
        else if (_config.SystemInfo.OCType == ChannelConstants.PreOcType && InlineGib)
            _eqpDataSize = 24;
        else
            _eqpDataSize = 22;

        // Allocate polling arrays
        PollingData = new int[_robotDataSize];
        PollingDataPre = new int[_robotDataSize];
        PollingEcs = new int[CommPlcConst.EcsDataSize + 1];
        PollingEcsPre = new int[CommPlcConst.EcsDataSize + 1];
        PollingEqp = new int[_eqpDataSize];
        PollingEqpPre = new int[_eqpDataSize];
        PollingCv = new int[CommPlcConst.CvDataSize];
        PollingCvPre = new int[CommPlcConst.CvDataSize];

        // Door opened init: InlineGIB + OC => B-side(1), else A-side(0)
        PollingDoorOpened = (InlineGib && _config.SystemInfo.OCType == ChannelConstants.OcType) ? 1 : 0;

        // Initialize string arrays
        for (int i = 0; i < EcsLcmId.Length; i++)
            EcsLcmId[i] = string.Empty;

        // Initialize log path
        _logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Log", "CommPLC");
        if (!Directory.Exists(_logPath))
            Directory.CreateDirectory(_logPath);

        // Initialize simulator memory if in simulator mode
        if (UseSimulator)
            _simMemory = new PlcSimulatorMemory();

        AddLog("========================================");
        AddLog($"[Create] UseSimulator={UseSimulator}, InlineGIB={InlineGib}");
    }

    // =========================================================================
    // Lifecycle: Start / Stop / Dispose
    // =========================================================================

    /// <inheritdoc />
    public void Start()
    {
        if (_cts != null) return;

        _cts = new CancellationTokenSource();
        _stopped = 0;

        if (UseSimulator)
        {
            _opened = true; // Simulator always "connected"
            StartSimulatorMonitoring(_cts.Token);
            SendMessageMain(CommPlcConst.ModeConnect, -1, 1, 0, "PLC Simulator Connected");
        }

        _pollingTask = Task.Run(() => ExecuteLoop(_cts.Token));
        AddLog("Start: polling task launched.");
    }

    /// <inheritdoc />
    public void Stop()
    {
        if (_cts == null) return;

        Interlocked.Exchange(ref _stopped, 1);
        _cts.Cancel();

        try { _pollingTask?.Wait(3000); }
        catch (AggregateException) { /* expected on cancel */ }

        try { _simMonitoringTask?.Wait(3000); }
        catch (AggregateException) { /* expected on cancel */ }

        _cts.Dispose();
        _cts = null;
        _pollingTask = null;
        _simMonitoringTask = null;

        ClosePlc();
        SaveLog(DateTime.Now);
        AddLog("Stop: polling task stopped.");
    }

    /// <summary>
    /// Switches between simulator and real PLC mode at runtime.
    /// Must be called after <see cref="Stop()"/> and before <see cref="Start()"/>.
    /// <para>Delphi origin: InitialAll → FreeAndNil(g_CommPLC) + CreateClassData re-create</para>
    /// </summary>
    public void ApplySimulationMode()
    {
        bool newMode = _config.PlcInfo.UseSimulation;
        if (newMode == UseSimulator)
        {
            AddLog($"[ApplySimulationMode] No change (UseSimulator={UseSimulator})");
            return;
        }
        AddLog($"[ApplySimulationMode] Switching: {UseSimulator} → {newMode}");

        // Dispose existing transport
        if (_actUtl is IDisposable disposable)
        {
            try { disposable.Dispose(); } catch { }
        }
        _actUtl = null;

        if (newMode)
        {
            // → Simulator mode
            _simMemory = new PlcSimulatorMemory();
            UseSimulator = true;
        }
        else
        {
            // → Real PLC mode
            _simMemory = null;
            _actUtl = new ActUtlTypeTcp("127.0.0.1", 3888, _messageBus, _logger);
            UseSimulator = false;
        }
    }

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        Stop();
        (_actUtl as IDisposable)?.Dispose();
        _actUtl = null;
    }

    // =========================================================================
    // Address configuration
    // =========================================================================

    /// <inheritdoc />
    public void SetStartAddress(
        long startAddrEqp, long startAddrEcs, long startAddrRobot, long startAddrRobot2,
        long startAddrEqpW, long startAddrEcsW, long startAddrRobotW, long startAddrRobotW2,
        long startAddrRobotDoor)
    {
        StartAddrEqp = (int)startAddrEqp;
        StartAddrEcs = (int)startAddrEcs;
        StartAddrRobot = (int)startAddrRobot;
        StartAddrRobot2 = (int)startAddrRobot2;
        StartAddrEqpW = (int)startAddrEqpW;
        StartAddrEcsW = (int)startAddrEcsW;
        StartAddrRobotW = (int)startAddrRobotW;
        StartAddrRobotW2 = (int)startAddrRobotW2;
        StartAddrRobotDoorBit = (int)startAddrRobotDoor;

        AddLog($"SetStartAddress EQP=0x{StartAddrEqp:X}, ECS=0x{StartAddrEcs:X}, " +
               $"ROBOT=0x{StartAddrRobot:X}, ROBOT2=0x{StartAddrRobot2:X}, " +
               $"EQP_W=0x{StartAddrEqpW:X}, ECS_W=0x{StartAddrEcsW:X}, " +
               $"ROBOT_W=0x{StartAddrRobotW:X}, ROBOT_W2=0x{StartAddrRobotW2:X}, " +
               $"DOOR=0x{StartAddrRobotDoorBit:X}");
    }

    /// <inheritdoc />
    public void SetEqpId(int eqpId)
    {
        EqpId = eqpId;
        AddLog($"SetEqpId: {eqpId}");
    }

    // =========================================================================
    // PLC Open / Close
    // =========================================================================

    /// <summary>
    /// Opens the PLC communication channel.
    /// <para>Delphi origin: procedure OpenPLC (line 755)</para>
    /// </summary>
    private void OpenPlc()
    {
        if (_opened) return;
        if (_actUtl is null) { AddLog("OpenPLC skipped (no ActUtlType driver)"); return; }

        AddLog("OpenPLC");
        try
        {
            _actUtl.CreateActType64();
            _actUtl.SetActLogicalStationNumber(_config.PlcInfo.StationNo);
            int ret = _actUtl.Open();
            if (ret == 0)
            {
                _opened = true;
                ConnectionError = false;
                AddLog("OpenPLC: success");
                SendMessageMain(CommPlcConst.ModeConnect, -1, 1, 0, "PLC Connected");
            }
            else
            {
                _opened = false;
                ConnectionError = true;
                AddLog($"OpenPLC: failed ret={ret}");
                SendMessageMain(CommPlcConst.ModeConnect, -1, 0, 0, $"PLC Connect Failed ({ret})");
            }
        }
        catch (Exception ex)
        {
            _opened = false;
            ConnectionError = true;
            _logger.Error("OpenPLC exception", ex);
        }
    }

    /// <summary>
    /// Closes the PLC communication channel.
    /// <para>Delphi origin: procedure ClosePLC (line 797)</para>
    /// </summary>
    private void ClosePlc()
    {
        if (!_opened) return;
        if (_actUtl is null) { _opened = false; return; }

        AddLog("ClosePLC");
        try
        {
            _actUtl.Close();
        }
        catch (Exception ex)
        {
            _logger.Error("ClosePLC exception", ex);
        }
        _opened = false;
        SendMessageMain(CommPlcConst.ModeConnect, -1, 0, 0, "PLC Disconnected");
    }

    // =========================================================================
    // Logging helpers
    // =========================================================================

    /// <summary>
    /// Adds a log line to the buffer and optionally saves.
    /// <para>Delphi origin: procedure AddLog (line 590)</para>
    /// </summary>
    private void AddLog(string log, bool save = false)
    {
        if (_stopped == 1) return;

        var now = DateTime.Now;
        lock (_logLock)
        {
            if (_logSaveTime.Hour != now.Hour)
                SaveLog(_logSaveTime);

            _logBuffer.AppendLine($"{now:HH:mm:ss.fff} {log}");

            if (save || _logBuffer.Length > 4096)
                SaveLog(now);
        }
        _logger.Debug(log);
    }

    /// <summary>
    /// Saves accumulated log to file.
    /// <para>Delphi origin: procedure SaveLog (line 614)</para>
    /// </summary>
    private void SaveLog(DateTime dt)
    {
        lock (_logLock)
        {
            if (_logBuffer.Length == 0) return;

            try
            {
                var dir = Path.Combine(_logPath, dt.ToString("yyyyMMdd"));
                if (!Directory.Exists(dir))
                    Directory.CreateDirectory(dir);

                var fileName = Path.Combine(dir, $"CommPLC_{dt:yyyyMMddHH}.txt");
                File.AppendAllText(fileName, _logBuffer.ToString());
                _logBuffer.Clear();
                _logSaveTime = DateTime.Now;
            }
            catch
            {
                // Swallow file I/O errors like Delphi original
            }
        }
    }

    // =========================================================================
    // GUI notification (replaces WM_COPYDATA SendMessage)
    // =========================================================================

    /// <summary>
    /// Publishes a PlcEventMessage to the message bus.
    /// <para>Delphi origin: procedure SendMessageMain (line 814)</para>
    /// </summary>
    private void SendMessageMain(int mode, int channel, int param, int param2, string msg)
    {
        _messageBus.Publish(new PlcEventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            Param2 = param2,
            Message = msg
        });
    }

    // =========================================================================
    // Static helpers
    // =========================================================================

    private static EcsGlassData[] CreateGlassDataArray(int count)
    {
        var arr = new EcsGlassData[count];
        for (int i = 0; i < count; i++)
            arr[i] = new EcsGlassData();
        return arr;
    }

    /// <summary>
    /// Helper: returns true if this is OC type (not PreOC).
    /// </summary>
    private bool IsOcType => _config.SystemInfo.OCType == ChannelConstants.OcType;

    /// <summary>
    /// Helper: returns true if this is PreOC type.
    /// </summary>
    private bool IsPreOcType => _config.SystemInfo.OCType == ChannelConstants.PreOcType;
}
