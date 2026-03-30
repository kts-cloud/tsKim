// =============================================================================
// CommPgDriver.cs
// Converted from Delphi: src_X3584\CommPG.pas (TCommPG class — full 7274 lines)
// Pattern generator driver for ITOLED inspection system.
// Supports both AF9 (USB via IAf9FpgaDriver) and DP860 (UDP/IP).
// Namespace: Dongaeltek.ITOLED.Hardware.PatternGenerator
// =============================================================================

using System.Globalization;
using System.Net.Sockets;
using System.Text;
using System.Text.RegularExpressions;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Logging;
using Dongaeltek.ITOLED.Hardware.Fpga;
using Dongaeltek.ITOLED.Messaging.Messages;
using HwNet.Config;
using HwNet.Engine;

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

/// <summary>
/// Pattern generator driver — unified AF9/DP860 implementation.
/// Replaces Delphi's <c>TCommPG</c> class (CommPG.pas, 7274 lines).
/// <para>
/// WM_COPYDATA inter-form messaging is replaced with <see cref="IMessageBus"/>
/// publishing <see cref="PgEventMessage"/> instances.
/// </para>
/// </summary>
public sealed class CommPgDriver : ICommPgDriver
{
    // =========================================================================
    // Win32 constants used as return values
    // =========================================================================

    private const uint WAIT_OBJECT_0 = 0x00000000;
    private const uint WAIT_FAILED   = 0xFFFFFFFF;
    private const uint WAIT_TIMEOUT  = 0x00000102;

    // =========================================================================
    // Injected Dependencies
    // =========================================================================

    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly DebugLogWriter? _debugLogWriter;
    private readonly IConfigurationService _configService;
    private readonly ISystemStatusService _systemStatus;
    private readonly IAf9FpgaDriver? _af9Driver;
    private readonly AppConfiguration _appConfig;

    // =========================================================================
    // Fields — Common
    // =========================================================================

    private readonly object _lock = new();
    private Timer? _connCheckTimer;
    private Timer? _pwrMeasureTimer;

    private int _connCheckNgCount;
    private bool _cyclicTimerEnabled;
    private bool _pwrMeasureEnabled;
    private bool _waitEvent;
    private bool _waitPwrEvent;
    private bool _isOnFlashAccess;
    private bool _forceStop;
    private readonly object _threadLock = new();
    private string _previousCommand = string.Empty;
    private string _addrFormat;
    private int _modelType;
    private string _modelFileName = string.Empty;

    /// <summary>
    /// Windows event handle replaced by ManualResetEventSlim for command/ack synchronization.
    /// Delphi: m_hEvent + m_sEvent + WaitForSingleObject/SetEvent pattern.
    /// </summary>
    private ManualResetEventSlim? _cmdAckEvent;

    /// <summary>
    /// Reference to the UDP server (set externally after construction).
    /// Delphi: global UdpServerPG variable accessed by TCommPG.
    /// </summary>
    private IPgTransport? _transport;

    /// <summary>
    /// NIC coordinator for exclusive DPDK FTP access (set externally for DPDK mode).
    /// </summary>
    private IDpdkNicCoordinator? _nicCoordinator;

    /// <summary>
    /// DpdkManager reference for creating HwFtpEngine (set externally for DPDK mode).
    /// </summary>
    private HwNet.HwManager? _dpdkManager;

    /// <summary>
    /// Flash directory path for temporary FTP files.
    /// </summary>
    private string _flashDir = string.Empty;

    // =========================================================================
    // Fields — DP860 Flash Data
    // =========================================================================

    private Dongaeltek.ITOLED.Core.Definitions.FlashRead _flashRead = new();
    private Dongaeltek.ITOLED.Core.Definitions.FlashData _flashData = new();

    // FTP 세션 — DLL flow 기간 동안 유지 (FlashRead_Data 수백 회 반복 호출 시 재사용)
    // InitFlashRead에서 이전 세션 정리, DLL WorkDone에서 ReleaseFlashFtpSession() 호출
    // SetLwipExternalRx는 앱 시작 시 1회 활성화 (NicCoordinator.EnableLwipMode)
    private HwNet.Engine.HwFtpEngine? _ftpEngine;
    private IAsyncDisposable? _ftpLease;
    private bool _ftpConnected;

    private bool _disposed;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a PG driver instance for a specific PG index.
    /// <para>Delphi: <c>TCommPG.Create(nPg, hMain, sModelTypeName)</c></para>
    /// </summary>
    public CommPgDriver(
        int pgIndex,
        string modelTypeName,
        IMessageBus messageBus,
        ILogger logger,
        IConfigurationService configService,
        ISystemStatusService systemStatus,
        IAf9FpgaDriver? af9Driver = null,
        DebugLogWriter? debugLogWriter = null)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _debugLogWriter = debugLogWriter;
        _configService = configService ?? throw new ArgumentNullException(nameof(configService));
        _systemStatus = systemStatus ?? throw new ArgumentNullException(nameof(systemStatus));
        _af9Driver = af9Driver;
        _appConfig = configService.AppConfig;

        // PG#/CH#
        PgIndex = pgIndex;
        ChannelIndex = pgIndex;
        ModelTypeName = modelTypeName ?? string.Empty;

        // Determine model type and address format
        var upperModel = ModelTypeName.ToUpperInvariant();
        if (upperModel.Contains("X3584") || upperModel.Contains("X3585"))
        {
            _addrFormat = "0x{0:x8}";
            _modelType = 1;
        }
        else
        {
            _addrFormat = "0x{0:x4}";
            _modelType = 0;
        }

        // PG type from config
        PgType = _configService.SystemInfo.PG_TYPE;

        // DP860 connection parameters
        PgIpAddress = $"{Dp860Network.NetworkPrefix}.{Dp860Network.PgIpAddrBase + pgIndex}";
        PgIpPort = Dp860Network.PgPortBase + pgIndex;

        // HW CID array
        HwcId = new string[5];
        for (int i = 0; i < 5; i++) HwcId[i] = string.Empty;

        // Init data structures
        TxRxDefault = new PgTxRxData();
        TxRxPg = new PgTxRxData();
        Version = new PgVersion();
        TconRwCount = new TconRwCount();
        CurrentPatternInfo = new CurrentPatternDisplayInfo();

        InitPgTxRxData();
        InitPgVersion();
        InitPgPowerData();
        InitPgPatternData();

        // PG status
        Status = PgStatus.Disconnected;

        // Timers
        _cyclicTimerEnabled = true;
        _connCheckNgCount = 0;

        _connCheckTimer = new Timer(ConnCheckTimerCallback, null, Timeout.Infinite, Timeout.Infinite);
        _pwrMeasureTimer = new Timer(PwrMeasureTimerCallback, null, Timeout.Infinite, Timeout.Infinite);

        // DP860-specific init
        _waitEvent = false;
        _waitPwrEvent = false;

        // Flow-specific
        IsPowerOn = false;

        // Flash access
        if (_appConfig.FeatureFlashAccess)
        {
            InitFlashRead();
        }

        // Misc
        _threadLock = false;
        _forceStop = false;
        IsMainter = false;

        // AF9 simulator label
        if (_appConfig.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            // Simulator mode
        }
    }

    /// <inheritdoc/>
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        DisposeFtpSession();

        _connCheckTimer?.Dispose();
        _connCheckTimer = null;

        _pwrMeasureTimer?.Dispose();
        _pwrMeasureTimer = null;

        _cmdAckEvent?.Dispose();
        _cmdAckEvent = null;
    }

    // =========================================================================
    // Properties — ICommPgDriver
    // =========================================================================

    /// <inheritdoc/>
    public int PgIndex { get; }

    /// <inheritdoc/>
    public int ChannelIndex { get; }

    /// <inheritdoc/>
    public string ModelTypeName { get; private set; }

    /// <inheritdoc/>
    public int PgType { get; }

    /// <inheritdoc/>
    public PgStatus Status { get; private set; }

    /// <inheritdoc/>
    public bool IsPgReady => Status == PgStatus.Ready;

    /// <inheritdoc/>
    public bool IsPowerOn { get; set; }

    /// <inheritdoc/>
    public bool IsFlashAccessActive => _isOnFlashAccess;

    /// <inheritdoc/>
    public PgVersion Version { get; private set; }

    /// <inheritdoc/>
    public PwrData PowerData { get; private set; }

    /// <inheritdoc/>
    public RxPwrData RawPowerData { get; private set; }

    /// <inheritdoc/>
    public CurrentPatternDisplayInfo CurrentPatternInfo { get; }

    /// <inheritdoc/>
    public PgTxRxData TxRxDefault { get; }

    /// <inheritdoc/>
    public PgTxRxData TxRxPg { get; }

    /// <inheritdoc/>
    public TconRwCount TconRwCount { get; }

    /// <inheritdoc/>
    public bool IsMainter { get; set; }

    /// <inheritdoc/>
    public bool IsCyclicTimerEnabled => _cyclicTimerEnabled;

    /// <inheritdoc/>
    public string[] HwcId { get; }

    /// <inheritdoc/>
    public bool IsReProgramming { get; set; }

    /// <inheritdoc/>
    public bool CheckIra { get; set; }

    /// <inheritdoc/>
    public bool CheckShutdownFault { get; set; }

    /// <inheritdoc/>
    public string PgIpAddress { get; }

    /// <inheritdoc/>
    public int PgIpPort { get; }

    // =========================================================================
    // Events
    // =========================================================================

    /// <inheritdoc/>
    public event Action<int, string, string, string>? TxMaintEventPg;

    /// <inheritdoc/>
    public event Action<int, string, string, string>? RxMaintEventPg;

    /// <inheritdoc/>
    public event Action<int, string>? TxMaintEventAf9;

    /// <inheritdoc/>
    public event Action<int, string>? RxMaintEventAf9;

    // =========================================================================
    // Internal methods exposed for PgUdpServer
    // =========================================================================

    /// <summary>
    /// Sets the UDP server reference (called after server construction).
    /// </summary>
    public void SetTransport(IPgTransport transport) => _transport = transport;

    /// <summary>
    /// Warms up the transport layer before compensation flow.
    /// </summary>
    public void WarmupTransport() => _transport?.Warmup();

    /// <summary>
    /// Sets the flash directory for FTP download/upload temp files.
    /// Called for both Socket and DPDK modes (EXE경로\LOG\FLASH\).
    /// </summary>
    public void SetFlashDir(string flashDir) => _flashDir = flashDir;

    /// <summary>
    /// Sets the DPDK NIC coordinator and DpdkManager for DPDK FTP flash operations.
    /// Called after PgDpdkServer construction.
    /// </summary>
    public void SetDpdkFtpAccess(IDpdkNicCoordinator coordinator, HwNet.HwManager dpdkManager)
    {
        _nicCoordinator = coordinator;
        _dpdkManager = dpdkManager;
    }

    /// <summary>
    /// Updates model type name and recalculates _modelType / _addrFormat.
    /// Also stores model file name for DP860_SendModelFile.
    /// Called after model MCF is loaded (since PG singleton is created before model load).
    /// <para>Delphi: sModelTypeName passed to TCommPG.Create from Common.TestModelInfoFLOW.ModelTypeName</para>
    /// </summary>
    public void UpdateModelType(string modelTypeName, string modelFileName = "")
    {
        ModelTypeName = modelTypeName ?? string.Empty;
        _modelFileName = modelFileName ?? string.Empty;
        var upperModel = ModelTypeName.ToUpperInvariant();
        if (upperModel.Contains("X3584") || upperModel.Contains("X3585"))
        {
            _addrFormat = "0x{0:x8}";
            _modelType = 1;
        }
        else
        {
            _addrFormat = "0x{0:x4}";
            _modelType = 0;
        }
        _logger.Info(PgIndex, $"PG ModelType updated: '{ModelTypeName}' type={_modelType} addrFmt={_addrFormat} modelFile='{_modelFileName}'");
    }

    /// <summary>Raises TX maintenance event for PG. Called by PgUdpServer.</summary>
    internal void RaiseTxMaintEventPg(int pg, string local, string remote, string msg)
        => TxMaintEventPg?.Invoke(pg, local, remote, msg);

    /// <summary>Raises RX maintenance event for PG. Called by PgUdpServer.</summary>
    internal void RaiseRxMaintEventPg(int pg, string local, string remote, string msg)
        => RxMaintEventPg?.Invoke(pg, local, remote, msg);

    /// <summary>Publishes test window message via message bus.</summary>
    internal void PublishTestWindow(int mode, int param, string msg)
    {
        _messageBus.Publish(new PgEventMessage
        {
            Channel = PgIndex,
            Mode = mode,
            Param = param,
            Message = msg
        });
    }

    /// <summary>Publishes main window message via message bus.</summary>
    internal void PublishMainWindow(int mode, int param, string msg)
    {
        _messageBus.Publish(new PgEventMessage
        {
            Channel = PgIndex,
            Mode = mode,
            Param = param,
            Message = msg
        });
    }

    /// <summary>Writes to PG-specific log. Called by PgUdpServer.</summary>
    internal void AddLog(string log)
    {
        _logger.Info(PgIndex, log);
        _debugLogWriter?.Write(PgIndex, log);
    }

    /// <summary>
    /// Called by PgUdpServer when UDP data is received for this PG.
    /// <para>Delphi: <c>TCommPG.DP860_OnUdpRX</c></para>
    /// </summary>
    internal void OnUdpReceived(string cmdAck, int localPort, int peerPort)
    {
        TconRwCount.ContTconOcWrite = 0;

        var parts = cmdAck.Split('\r');
        var len = parts.Length;

        // Case 1: NoAckWait (ConnCheck | PowerRead | PgInit)
        if (localPort == Dp860Network.PcPortBase)
        {
            TxRxDefault.CmdResult = parts[len - 1].Trim().Equals("RET:OK", StringComparison.OrdinalIgnoreCase)
                ? PgCmdResult.Ok : PgCmdResult.Ng;

            if (cmdAck.Contains("power parameters :", StringComparison.OrdinalIgnoreCase))
            {
                TxRxDefault.CmdState = PgCmdState.None;
                TxRxDefault.TxCmdId = PgCommandParam.CmdIdUnknown;
                TxRxDefault.RxCmdId = Dp860Commands.CmdIdPowerRead;
                Dp860ReadPowerMeasureAck(cmdAck);
            }
            else if (cmdAck.Contains(Dp860Commands.CmdStrPgInit, StringComparison.OrdinalIgnoreCase))
            {
                TxRxDefault.RxCmdId = Dp860Commands.CmdIdPgInit;
                Dp860ReadPgInit();
            }
            else
            {
                if (TxRxDefault.TxCmdId == Dp860Commands.CmdIdConnCheck)
                {
                    TxRxDefault.CmdState = PgCmdState.None;
                    TxRxDefault.TxCmdId = PgCommandParam.CmdIdUnknown;
                    TxRxDefault.RxCmdId = Dp860Commands.CmdIdConnCheck;
                    Dp860ReadConnCheckAck(cmdAck);
                }
                else
                {
                    TxRxDefault.RxCmdId = PgCommandParam.CmdIdUnknown;
                }
            }
            return;
        }

        // Case 2: CmdAck (regular commands)
        var lastPart = parts[len - 1].Trim();

        // RET:INFO means PG is still processing — do NOT signal the wait event
        if (lastPart.Equals("RET:INFO", StringComparison.OrdinalIgnoreCase))
        {
            TxRxPg.RxAckStr = cmdAck;
            return;
        }

        TxRxPg.CmdState = PgCmdState.RxAck;
        TxRxPg.CmdResult = lastPart.Equals("RET:OK", StringComparison.OrdinalIgnoreCase)
            ? PgCmdResult.Ok : PgCmdResult.Ng;
        TxRxPg.RxAckStr = cmdAck;

        if (_waitEvent) _cmdAckEvent?.Set();
    }

    // =========================================================================
    // Init Methods
    // =========================================================================

    /// <inheritdoc/>
    public void InitPgTxRxData()
    {
        ResetTxRxData(TxRxDefault);
        ResetTxRxData(TxRxPg);
    }

    /// <inheritdoc/>
    public void InitPgVersion()
    {
        Version = new PgVersion();
    }

    /// <inheritdoc/>
    public void InitPgPowerData()
    {
        PowerData = default;
        RawPowerData = default;
    }

    /// <inheritdoc/>
    public void InitPgPatternData()
    {
        CurrentPatternInfo.PatternOn = false;
        CurrentPatternInfo.CurrentPatternNumber = 0;
        CurrentPatternInfo.CurrentAllPatIndex = 0;
        CurrentPatternInfo.IsSimplePattern = true;
        CurrentPatternInfo.GrayOffset = 0;
        CurrentPatternInfo.GrayChangeR = false;
        CurrentPatternInfo.GrayChangeG = false;
        CurrentPatternInfo.GrayChangeB = false;
        CurrentPatternInfo.CurrentPwmDuty = 100;
        CurrentPatternInfo.CurrentDimmingStep = 1;
    }

    /// <inheritdoc/>
    public void InitFlashRead()
    {
        DisposeFtpSession(); // 이전 Flash 작업의 FTP 세션 정리
        _isOnFlashAccess = false;
        _flashRead = new Dongaeltek.ITOLED.Core.Definitions.FlashRead();
    }

    /// <summary>
    /// Flash 작업 완료 후 FTP 세션 해제. DLL flow 종료 시 호출.
    /// FlashRead_Data/FlashWrite_Data 반복 호출 동안 세션 재사용 후 마지막에 정리.
    /// </summary>
    public void ReleaseFlashFtpSession() => DisposeFtpSession();

    // =========================================================================
    // Timer Control
    // =========================================================================

    /// <inheritdoc/>
    public void SetCyclicTimer(bool enable, int disableSec = 0)
    {
        _cyclicTimerEnabled = enable;
        _connCheckNgCount = 0;

        if (enable)
        {
            _connCheckTimer?.Change(PgTimerDefaults.ConnCheckInterval, PgTimerDefaults.ConnCheckInterval);
            if (_pwrMeasureEnabled)
                _pwrMeasureTimer?.Change(PgTimerDefaults.PwrMeasureIntervalDefault, PgTimerDefaults.PwrMeasureIntervalDefault);
        }
        else
        {
            _connCheckTimer?.Change(Timeout.Infinite, Timeout.Infinite);
            _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);

            if (disableSec > 0)
            {
                _ = Task.Run(async () =>
                {
                    for (int cnt = 1; cnt <= disableSec; cnt++)
                    {
                        if (_cyclicTimerEnabled) return;
                        await Task.Delay(3000).ConfigureAwait(false);
                    }
                    _cyclicTimerEnabled = true;
                    _connCheckTimer?.Change(PgTimerDefaults.ConnCheckInterval, PgTimerDefaults.ConnCheckInterval);
                    if (_pwrMeasureEnabled)
                        _pwrMeasureTimer?.Change(PgTimerDefaults.PwrMeasureIntervalDefault, PgTimerDefaults.PwrMeasureIntervalDefault);
                });
            }
        }
    }

    /// <inheritdoc/>
    public void SetPowerMeasureTimer(bool enable, int intervalMs = 0)
    {
        if (PgType == Dongaeltek.ITOLED.Core.Definitions.PgType.Af9) return;

        if (enable)
        {
            if (intervalMs < PgTimerDefaults.PwrMeasureIntervalMin)
                intervalMs = PgTimerDefaults.PwrMeasureIntervalMin;
            _pwrMeasureTimer?.Change(intervalMs, intervalMs);
        }
        else
        {
            _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);
        }
        _pwrMeasureEnabled = enable;
    }

    // =========================================================================
    // Timer Callbacks
    // =========================================================================

    /// <summary>
    /// Connection check timer callback.
    /// <para>Delphi: <c>TCommPG.ConnCheckTimer -> ConnCheckTimer_DP860</c></para>
    /// </summary>
    private void ConnCheckTimerCallback(object? state)
    {
        if (!_cyclicTimerEnabled) return;
        if (_waitEvent) return;
        if (_waitPwrEvent) return;
        if (_systemStatus.IsClosing) return;
        if (_isOnFlashAccess) return;

        try
        {
            if (_connCheckNgCount > 5 && Status != PgStatus.Disconnected)
            {
                _connCheckNgCount = 0;
                Status = PgStatus.Disconnected;

                InitPgVersion();
                PublishTestWindow(DefCommon.MsgModeDisplayConnection, DefCommon.PgConnDisconnected, "DP860 Disconnected");
                PublishMainWindow(DefCommon.MsgModeDisplayConnection, DefCommon.PgConnDisconnected, "DP860 Disconnected");

                // Change interval for disconnect polling
                _connCheckTimer?.Change(1000, 1000);
                _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);
                _pwrMeasureEnabled = false;
            }
            else
            {
                // If PG disconnected, try to rebind UDP clients
                // (NIC may have come up after PG was plugged in)
                if (Status == PgStatus.Disconnected)
                    _transport?.TryRebindClients();

                Dp860SendConnCheck();
                _connCheckNgCount++;
            }
        }
        catch (Exception ex)
        {
            _logger.Error(PgIndex, $"ConnCheckTimer exception: {ex.Message}");
        }
    }

    /// <summary>
    /// Power measure timer callback.
    /// <para>Delphi: <c>TCommPG.PwrMeasureTimer</c></para>
    /// </summary>
    private void PwrMeasureTimerCallback(object? state)
    {
        if (!_cyclicTimerEnabled) return;
        if (!_pwrMeasureEnabled) return;
        if (PgType == Dongaeltek.ITOLED.Core.Definitions.PgType.Af9) return;
        if (_waitEvent) return;
        if (_waitPwrEvent) return;
        if (_isOnFlashAccess) return;

        try
        {
            _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);
            SendPowerMeasure(cyclicMeasure: true);
            if (_pwrMeasureEnabled)
                _pwrMeasureTimer?.Change(PgTimerDefaults.PwrMeasureIntervalDefault, PgTimerDefaults.PwrMeasureIntervalDefault);
        }
        catch (Exception ex)
        {
            _logger.Error(PgIndex, $"PwrMeasureTimer exception: {ex.Message}");
        }
    }

    // =========================================================================
    // DP860 Core TX/RX
    // =========================================================================

    /// <summary>
    /// Command/ack synchronization using ManualResetEventSlim.
    /// <para>Delphi: <c>TCommPG.CheckCmdAck</c></para>
    /// </summary>
    private uint CheckCmdAck(Action task, int cmdId, string cmdName, int waitMs, int retry)
    {
        uint result = WAIT_FAILED;

        try
        {
            // lock(_threadLock) in Dp860SendCmd guarantees serialization — no spin-wait needed
            _waitEvent = true;
            _cmdAckEvent ??= new ManualResetEventSlim(false);
            _cmdAckEvent.Reset();

            for (int i = 0; i <= retry; i++)
            {
                if (Status == PgStatus.Disconnected) break;

                TxRxPg.CmdState = PgCmdState.TxWaitAck;
                TxRxPg.CmdResult = PgCmdResult.None;
                TxRxPg.TxCmdId = cmdId;
                TxRxPg.RxCmdId = PgCommandParam.CmdIdUnknown;
                TxRxPg.RxAckStr = string.Empty;
                TxRxPg.RxDataLen = 0;

                try
                {
                    task();

                    bool signaled = false;

                    // Phase 1: Spin-wait (~2ms) — avoids kernel wakeup latency
                    // Covers typical tcon/command RTT of ~0.3-1.0ms without kernel transition
                    const int SpinDurationMs = 2;
                    long spinEnd = System.Diagnostics.Stopwatch.GetTimestamp()
                        + SpinDurationMs * System.Diagnostics.Stopwatch.Frequency / 1000;
                    while (System.Diagnostics.Stopwatch.GetTimestamp() < spinEnd)
                    {
                        if (TxRxPg.CmdResult != PgCmdResult.None)
                        {
                            signaled = true;
                            break;
                        }
                        Thread.SpinWait(4);
                    }

                    // Phase 2: Kernel wait — for slow responses (FTP, flash, etc.)
                    if (!signaled && waitMs > SpinDurationMs)
                    {
                        int remainMs = waitMs - SpinDurationMs;
                        signaled = _cmdAckEvent.Wait(remainMs);
                    }

                    _cmdAckEvent.Reset();
                    TxRxPg.CmdState = PgCmdState.None;

                    if (signaled || TxRxPg.CmdResult != PgCmdResult.None)
                    {
                        if (TxRxPg.CmdResult == PgCmdResult.Ok)
                        {
                            result = WAIT_OBJECT_0;
                            break;
                        }
                        else
                        {
                            result = WAIT_FAILED;
                        }
                    }
                    else
                    {
                        result = WAIT_TIMEOUT;
                    }
                }
                catch
                {
                    break;
                }
            }
        }
        finally
        {
            _waitEvent = false;
        }

        return result;
    }

    /// <inheritdoc/>
    public uint Dp860SendCmd(string command, int cmdId, string cmdName, int waitMs = 3000, int retry = 0)
    {
        // ConnCheck: skip if another command is in progress (existing behavior)
        bool isStatusCmd = cmdId == Dp860Commands.CmdIdConnCheck;
        if ((_waitEvent || _waitPwrEvent) && isStatusCmd) return WAIT_OBJECT_0;

        lock (_threadLock) // Serialize all PG commands — prevents concurrent CheckCmdAck race condition
        {
            uint result = WAIT_OBJECT_0;

            switch (cmdId)
            {
                case Dp860Commands.CmdIdConnCheck:
                    waitMs = 0;
                    break;
                case Dp860Commands.CmdIdPowerRead:
                    if (Status != PgStatus.Ready) return WAIT_FAILED;
                    if (waitMs > 0) _waitPwrEvent = true;
                    break;
                default:
                    if (Status == PgStatus.Disconnected) return WAIT_FAILED;
                    break;
            }

            // Select TxRx channel
            var txRxData = waitMs <= 0 ? TxRxDefault : TxRxPg;
            txRxData.CmdState = waitMs > 0 ? PgCmdState.TxWaitAck : PgCmdState.TxNoAck;
            txRxData.CmdResult = PgCmdResult.None;
            txRxData.TxCmdId = cmdId;
            txRxData.TxCmdStr = command;

            if (waitMs <= 0)
            {
                // No-ack: send on base port
                Dp860SendData(_configService.AppConfig.MaxPgCount, command);
                result = WAIT_OBJECT_0;
            }
            else
            {
                txRxData.RxPrevStr = string.Empty;

                // RxPollLoop가 후속 응답(RET:OK)을 ProcessCmdAck으로 처리할 수 있도록
                // SendAndReceive 호출 전에 대기 상태를 미리 설정
                _waitEvent = true;
                _cmdAckEvent ??= new ManualResetEventSlim(false);
                _cmdAckEvent.Reset();
                txRxData.CmdState = PgCmdState.TxWaitAck;
                txRxData.CmdResult = PgCmdResult.None;
                txRxData.TxCmdId = cmdId;
                txRxData.RxCmdId = PgCommandParam.CmdIdUnknown;
                txRxData.RxAckStr = string.Empty;
                txRxData.RxDataLen = 0;

                // DPDK 네이티브 경로: hw_reqresp_once_mc (TX→RX 전체를 C 코드 내 처리)
                var nativeResult = _transport?.SendAndReceive(PgIndex, PgIndex, command + "\r", waitMs);
                if (nativeResult is { status: >= 0 } nr)
                {
                    if (nr.status == 0 && nr.response.Length > 0)
                    {
                        var resp = nr.response.TrimEnd('\r', '\n', ' ');
                        txRxData.RxAckStr = resp;

                        if (resp.Contains("RET:OK", StringComparison.OrdinalIgnoreCase) ||
                                 resp.Contains("RET:00", StringComparison.OrdinalIgnoreCase))
                        {
                            // 최종 응답: RET:OK
                            txRxData.CmdResult = PgCmdResult.Ok;
                            result = WAIT_OBJECT_0;
                            OnUdpReceived(resp, Dp860Network.PcPortBase + 1 + PgIndex, PgIpPort);
                        }
                        else if (resp.Contains("RET:NG", StringComparison.OrdinalIgnoreCase))
                        {
                            // 최종 응답: RET:NG
                            txRxData.CmdResult = PgCmdResult.Ng;
                            result = WAIT_FAILED;
                            OnUdpReceived(resp, Dp860Network.PcPortBase + 1 + PgIndex, PgIpPort);
                        }
                        else
                        {
                            // 중간 응답 (RET:INFO, progress, empty 등)
                            // → _waitEvent=true 상태에서 RxPollLoop이 후속 RET:OK를 수신하면
                            //   OnUdpReceived → CmdResult=Ok → _cmdAckEvent.Set()
                            int elapsed = (int)(nr.rttUs / 1000);
                            int remainMs = Math.Max(waitMs - elapsed, 100);

                            // RxPollLoop이 이미 처리했을 수 있으므로 먼저 확인
                            if (txRxData.CmdResult == PgCmdResult.Ok)
                            {
                                result = WAIT_OBJECT_0;
                            }
                            else if (txRxData.CmdResult == PgCmdResult.Ng)
                            {
                                result = WAIT_FAILED;
                            }
                            else
                            {
                                bool signaled = _cmdAckEvent.Wait(remainMs);
                                if (signaled || txRxData.CmdResult != PgCmdResult.None)
                                {
                                    result = txRxData.CmdResult == PgCmdResult.Ok
                                        ? WAIT_OBJECT_0 : WAIT_FAILED;
                                }
                                else
                                {
                                    result = WAIT_TIMEOUT;
                                }
                            }
                        }
                    }
                    else
                    {
                        txRxData.CmdResult = PgCmdResult.None;
                        result = WAIT_TIMEOUT;
                    }
                    txRxData.CmdState = PgCmdState.None;
                    _waitEvent = false;
                }
                else
                {
                    // 네이티브 경로 미지원 (Socket 모드) → 기존 CheckCmdAck
                    result = CheckCmdAck(
                        () => Dp860SendData(PgIndex, command),
                        cmdId, command, waitMs, retry);
                }
            }

            return result;
        }
    }

    /// <summary>
    /// Sends data via UDP server.
    /// <para>Delphi: <c>TCommPG.DP860_SendData</c></para>
    /// </summary>
    private void Dp860SendData(int bindIdx, string command)
    {
        _transport?.Send(bindIdx, PgIndex, command + "\r");
    }

    /// <summary>
    /// Gets a string description of a command result.
    /// <para>Delphi: <c>TCommPG.DP860_GetStrCmdResult</c></para>
    /// </summary>
    private static string GetStrCmdResult(uint result) => result switch
    {
        WAIT_OBJECT_0 => " OK",
        WAIT_FAILED => " NG(Failed)",
        WAIT_TIMEOUT => " NG(TimeOut)",
        _ => " NG(Etc)"
    };

    /// <summary>
    /// Extracts PG log message from ack string.
    /// <para>Delphi: <c>TCommPG.DP860_GetPgLogMsg</c></para>
    /// </summary>
    private static string GetPgLogMsg(string ackStr)
    {
        if (string.IsNullOrEmpty(ackStr)) return string.Empty;
        try
        {
            var parts = ackStr.Split('\r');
            var sb = new System.Text.StringBuilder();
            for (int i = 0; i < parts.Length - 1; i++) // Without RET:xx
            {
                if (i > 0) sb.Append('#');
                sb.Append(parts[i].Trim());
            }
            return sb.ToString();
        }
        catch
        {
            return "GetErrorPgLogMsg";
        }
    }

    /// <summary>
    /// Formats address using model-appropriate format string.
    /// </summary>
    private string FormatAddr(int addr) => string.Format(_addrFormat, addr);

    // =========================================================================
    // DP860 Connection Check
    // =========================================================================

    /// <summary>
    /// Sends connection check (pg.status).
    /// <para>Delphi: <c>TCommPG.DP860_SendConnCheck</c></para>
    /// </summary>
    private void Dp860SendConnCheck()
    {
        if (_waitEvent || _waitPwrEvent) return;

        Dp860SendCmd(Dp860Commands.CmdStrConnCheck,
            Dp860Commands.CmdIdConnCheck, Dp860Commands.CmdStrConnCheck, 0, 0);
    }

    /// <summary>
    /// Processes connection check ack.
    /// <para>Delphi: <c>TCommPG.DP860_ReadConnCheckAck</c></para>
    /// </summary>
    private void Dp860ReadConnCheckAck(string cmdAck)
    {
        _connCheckNgCount = 0;

        switch (Status)
        {
            case PgStatus.Disconnected:
            case PgStatus.Connected:
                PublishTestWindow(DefCommon.MsgModeDisplayConnection, DefCommon.PgConnConnected, "PG Connected");
                Status = PgStatus.GetPgVersion;
                _ = Task.Run(() => Dp860SendVersionAll());
                break;
            case PgStatus.Ready:
                break;
        }
    }

    /// <summary>
    /// Processes pg.init received.
    /// <para>Delphi: <c>TCommPG.DP860_ReadPgInit</c></para>
    /// </summary>
    private void Dp860ReadPgInit()
    {
        try
        {
            SetCyclicTimer(false);

            AddLog("RCV pg.init");
            Thread.Sleep(100);

            _connCheckNgCount = 0;
            Status = PgStatus.GetPgVersion;
            Dp860SendVersionAll();
        }
        finally
        {
            SetCyclicTimer(true);
        }
    }

    // =========================================================================
    // DP860 Version Commands
    // =========================================================================

    /// <inheritdoc/>
    public uint Dp860SendVersionAll(int waitMs = 5000, int retry = 0)
    {
        var result = Dp860SendCmd(Dp860Commands.CmdStrVersionAll,
            Dp860Commands.CmdIdVersionAll, Dp860Commands.CmdStrVersionAll, waitMs, retry);

        AddLog($"<PG> {Dp860Commands.CmdStrVersionAll}:{GetStrCmdResult(result)}");
        Thread.Sleep(100);

        switch (result)
        {
            case WAIT_OBJECT_0:
                Dp860ReadVersionAllAck(TxRxPg.RxAckStr);

                if (Status != PgStatus.Ready)
                {
                    _ = Task.Run(() => Dp860SendModelVersion());
                }
                break;
            case WAIT_TIMEOUT:
                Status = PgStatus.Disconnected;
                break;
            default:
                Status = PgStatus.Connected;
                break;
        }

        return result;
    }

    private void Dp860ReadVersionAllAck(string cmdAck)
    {
        var lines = cmdAck.Split('\r');
        Version.VerAll = lines.Length > 0 ? lines[0] : string.Empty;

        var parts = Version.VerAll.Split('_');
        for (int i = 0; i + 1 < parts.Length; i++)
        {
            switch (parts[i])
            {
                case "ITO APP": Version.ItoApp = i + 2 < parts.Length ? $"{parts[i + 1]}_{parts[i + 2]}" : parts[i + 1]; break;
                case "FW": Version.FW = parts[i + 1]; break;
                case "IP": Version.IP = parts[i + 1]; break;
                case "PWR": Version.PWR = parts[i + 1]; break;
            }
        }
    }

    private uint Dp860SendModelVersion(int waitMs = 3000, int retry = 0)
    {
        var result = Dp860SendCmd(Dp860Commands.CmdStrModelVersion,
            Dp860Commands.CmdIdModelVersion, Dp860Commands.CmdStrModelVersion, waitMs, retry);

        AddLog($"<PG> {Dp860Commands.CmdStrModelVersion}:{GetStrCmdResult(result)}");
        Thread.Sleep(100);

        switch (result)
        {
            case WAIT_OBJECT_0:
                Dp860ReadModelVersionAck(TxRxPg.RxAckStr);
                PublishTestWindow(DefCommon.MsgModeDisplayConnection, DefCommon.PgConnVersion, "PG Connected");

                if (Status != PgStatus.Ready)
                {
                    if (_modelType == 1) // X3584/X3585
                    {
                        // Delphi: DP860_SendModelFile(Common.TestModelInfoFLOW.ModelFileName)
                        _ = Task.Run(() => Dp860SendModelFile(_modelFileName));
                    }
                    else
                    {
                        _ = Task.Run(() => Dp860ModelInfoDownload());
                    }
                }
                break;
            case WAIT_TIMEOUT:
                Status = PgStatus.Disconnected;
                break;
            default:
                Status = PgStatus.Connected;
                break;
        }

        return result;
    }

    private void Dp860ReadModelVersionAck(string cmdAck)
    {
        var lines = cmdAck.Split('\r');
        Version.VerScript = lines.Length > 0 ? lines[0] : string.Empty;
    }

    // =========================================================================
    // DP860 Model Download
    // =========================================================================

    /// <inheritdoc/>
    public uint Dp860ModelInfoDownload()
    {
        uint result = WAIT_FAILED;
        try
        {
            SetCyclicTimer(false);
            Status = PgStatus.ModelDownload;

            result = Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerOpen, Dp860Commands.CmdStrPowerOpen,
                MakePowerOpenParam(), "power.open", 3000, 1);
            if (result != WAIT_OBJECT_0) return result;

            result = Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerSeq, Dp860Commands.CmdStrPowerSeq,
                MakePowerSeqParam(), "power.seq", 3000, 1);
            if (result != WAIT_OBJECT_0) return result;

            result = Dp860SendSimpleCmd(Dp860Commands.CmdIdModelConfig, Dp860Commands.CmdStrModelConfig,
                MakeModelConfigParam(), "model.config", 3000, 1);
            if (result != WAIT_OBJECT_0) return result;

            result = Dp860SendSimpleCmd(Dp860Commands.CmdIdAlpmConfig, Dp860Commands.CmdStrAlpmConfig,
                MakeAlpmConfigParam(), "alpm.config", 3000, 1);
            if (result != WAIT_OBJECT_0) return result;

            result = WAIT_OBJECT_0;
        }
        finally
        {
            switch (result)
            {
                case WAIT_OBJECT_0:
                    Status = PgStatus.Ready;
                    PublishTestWindow(DefCommon.MsgModeDisplayConnection, DefCommon.PgConnReady, "PG Ready");
                    _connCheckTimer?.Change(3000, 3000);
                    break;
                case WAIT_TIMEOUT:
                    Status = PgStatus.Disconnected;
                    break;
                default:
                    Status = PgStatus.Connected;
                    break;
            }
            SetCyclicTimer(true);
        }
        return result;
    }

    /// <inheritdoc/>
    public uint Dp860SendModelFile(string modelFileName, int waitMs = 10000, int retry = 0)
    {
        uint result = 0;
        SetCyclicTimer(false);
        try
        {
            var cmd = $"{Dp860Commands.CmdStrSetModelFile} {modelFileName}";
            result = Dp860SendCmd(cmd, Dp860Commands.CmdIdSetModelFile, Dp860Commands.CmdStrSetModelFile, waitMs, retry);
            var etcMsg = result != WAIT_OBJECT_0 ? $"[{GetPgLogMsg(TxRxPg.RxAckStr)}]" : "";
            AddLog($"<PG> {cmd} :{GetStrCmdResult(result)}{etcMsg}");
        }
        finally
        {
            switch (result)
            {
                case WAIT_OBJECT_0:
                    Status = PgStatus.Ready;
                    PublishTestWindow(DefCommon.MsgModeDisplayConnection, DefCommon.PgConnReady, "PG Ready");
                    _connCheckTimer?.Change(3000, 3000);
                    break;
                case WAIT_TIMEOUT:
                    Status = PgStatus.Disconnected;
                    break;
                default:
                    Status = PgStatus.Connected;
                    break;
            }
            SetCyclicTimer(true);
        }
        return result;
    }

    // =========================================================================
    // DP860 Power Commands
    // =========================================================================

    /// <inheritdoc/>
    public uint Dp860SendPowerOn(int waitMs = 10000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerOn, Dp860Commands.CmdStrPowerOn, "", "power.on", waitMs, retry);

    /// <inheritdoc/>
    public uint Dp860SendPowerOff(int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerOff, Dp860Commands.CmdStrPowerOff, "", "power.off", waitMs, retry);

    // =========================================================================
    // DP860 Misc Commands
    // =========================================================================

    /// <inheritdoc/>
    public void Dp860ClearOcTconRwCount()
    {
        TconRwCount.TconReadDllCall = 0;
        TconRwCount.TconWriteDllCall = 0;
        TconRwCount.TconReadTx = 0;
        TconRwCount.TconWriteTx = 0;
        TconRwCount.TconOcWriteTx = 0;
        TconRwCount.ContTconOcWrite = 0;
        TconRwCount.TconReadArrayDllCall = 0;
        TconRwCount.TconWriteArrayDllCall = 0;
        TconRwCount.TconMultiWriteDllCall = 0;
        TconRwCount.TconSeqWriteDllCall = 0;
        TconRwCount.TconRetryReadCall = 0;
        TconRwCount.TconRetryWriteCall = 0;
    }

    /// <inheritdoc/>
    public uint Dp860SendOcOnOff(int state, int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdOcOnOff, Dp860Commands.CmdStrOcOnOff, state.ToString(), "oc.onoff", waitMs, retry);

    /// <inheritdoc/>
    public uint Dp860SendNvmInit(int mode, int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdNvmInit, Dp860Commands.CmdStrNvmInit, mode.ToString(), "nvm.init", waitMs, retry);

    /// <inheritdoc/>
    public uint Dp860SendGpioRead(string gpio, int waitMs = 5000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdGpioRead, Dp860Commands.CmdStrGpioRead, gpio, "gpio.read", waitMs, retry);

    /// <inheritdoc/>
    public uint Dp860SendGpioPanelIrq(out int data, int waitMs = 5000, int retry = 0)
    {
        data = 0;
        var result = Dp860SendSimpleCmd(Dp860Commands.CmdIdGpioPanelIrq, Dp860Commands.CmdStrGpioPanelIrq, "", "gpio.panel_irq", waitMs, retry);
        if (result == WAIT_OBJECT_0)
        {
            try
            {
                var parts = TxRxPg.RxAckStr.Split('\r');
                if (parts.Length > 0)
                    int.TryParse(parts[0].Trim(), out data);
            }
            catch { /* parsing error */ }
        }
        return result;
    }

    /// <inheritdoc/>
    public uint Dp860FtpDisconnect()
    {
        // FTP disconnect — placeholder for FTP client integration
        AddLog("<PG> FTP Disconnect");
        return WAIT_OBJECT_0;
    }

    // =========================================================================
    // DP860 Power Measurement
    // =========================================================================

    private void Dp860ReadPowerMeasureAck(string cmdAck)
    {
        _waitPwrEvent = false;

        if (!cmdAck.Contains("power parameters :", StringComparison.OrdinalIgnoreCase))
            return;

        try
        {
            var lines = cmdAck.Split('\r');
            if (lines.Length <= 10) return;

            var rxPwr = new RxPwrData();

            rxPwr.Vcc = ParseUInt(lines[1]);
            rxPwr.Ivcc = ParseCurrentUa(lines[2]);
            rxPwr.Vin = ParseUInt(lines[3]);
            rxPwr.Ivin = ParseCurrentUa(lines[4]);
            rxPwr.Vdd3 = ParseUInt(lines[5]);
            rxPwr.Ivdd3 = ParseCurrentUa(lines[6]);
            rxPwr.Vdd4 = ParseUInt(lines[7]);
            rxPwr.Ivdd4 = ParseCurrentUa(lines[8]);
            rxPwr.Vdd5 = ParseUInt(lines[9]);
            rxPwr.Ivdd5 = ParseCurrentUa(lines[10]);

            RawPowerData = rxPwr;

            PowerData = new PwrData
            {
                Vcc = rxPwr.Vcc,
                Ivcc = rxPwr.Ivcc / 1000,
                Vin = rxPwr.Vin,
                Ivin = rxPwr.Ivin / 1000,
                Vdd3 = rxPwr.Vdd3,
                Ivdd3 = rxPwr.Ivdd3 / 1000,
                Vdd4 = rxPwr.Vdd4,
                Ivdd4 = rxPwr.Ivdd4 / 1000,
                Vdd5 = rxPwr.Vdd5,
                Ivdd5 = rxPwr.Ivdd5 / 1000,
            };

            PublishTestWindow(DefCommon.MsgModeDisplayVolCur, 0, "");
        }
        catch (Exception ex)
        {
            _logger.Error(PgIndex, $"Power measure parse error: {ex.Message}");
        }
    }

    // =========================================================================
    // FLOW-SPECIFIC: Power On/Off
    // =========================================================================

    private const int DelayPowerInterposerOff = 10;
    private const int DelayPowerInterposerOn = 10;

    /// <summary>
    /// Common interposer initialization sequence used by SendPowerOn and SendPowerBistOn.
    /// Delphi: InterposerOff → Sleep → InterposerOn (retry: Off→100ms→On)
    ///         → [X3584: ERASE.DELAYMS 64K 300] → Sleep → [DutDetect if enabled]
    /// </summary>
    private uint InterposerInitSequence(int waitMs, int retry)
    {
        // Step 1: InterposerOff first (cleanup), then InterposerOn
        Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
        Thread.Sleep(DelayPowerInterposerOff);

        var result = Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOn, Dp860Commands.CmdStrInterposerOn, "", "interposer.init", waitMs, retry);

        // Retry: Off → 100ms → On
        if (result != WAIT_OBJECT_0)
        {
            Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
            Thread.Sleep(100);
            result = Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOn, Dp860Commands.CmdStrInterposerOn, "", "interposer.init", waitMs, retry);
        }

        if (result != WAIT_OBJECT_0)
            return result;

        // Step 2: X3584/X3585 — send ERASE command before power-on
        // Delphi: CommPG.pas line 5563-5566
        if (_modelType == 1)
        {
            const string eraseCmd = "ERASE.DELAYMS 64K 300";
            Dp860SendCmd(eraseCmd, PgCommandParam.CmdIdUnknown, eraseCmd, 3000, 0);
        }

        Thread.Sleep(DelayPowerInterposerOn);
        return WAIT_OBJECT_0;
    }

    /// <inheritdoc/>
    public uint SendPowerOn(int mode, bool powerReset = false, int waitMs = 10000, int retry = 0)
    {
        uint result = WAIT_FAILED;
        try
        {
            SetCyclicTimer(false);

            if (mode == PgCommandParam.PowerOff)
            {
                // ── Power OFF ──────────────────────────────────────────
                // Delphi: CommPG.pas line 5496-5539 (CMD_POWER_OFF, DP860)
                if (_isOnFlashAccess)
                {
                    _logger.Warn(PgIndex, "Power Off NG (On Flash Access) ...Try again after flash access is done");
                    return WAIT_FAILED;
                }
                result = Dp860SendPowerOff(waitMs, retry);
                if (!powerReset)
                {
                    Thread.Sleep(DelayPowerInterposerOff);
                    Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
                }
                if (result == WAIT_OBJECT_0)
                    IsPowerOn = false;
            }
            else
            {
                // ── Power ON ───────────────────────────────────────────
                // Delphi: CommPG.pas line 5541-5597 (CMD_POWER_ON, DP860)
                if (!powerReset)
                {
                    // Full init: InterposerOff → InterposerOn → [ERASE] → DutDetect → PowerOn → TconInfo
                    result = InterposerInitSequence(waitMs, retry);
                    if (result != WAIT_OBJECT_0) return result;

                    // DUT detect
                    result = Dp860SendSimpleCmd(Dp860Commands.CmdIdDutDetect, Dp860Commands.CmdStrDutDetect, "", "dut.detect", 1000, 1);
                    if (result != WAIT_OBJECT_0)
                    {
                        // Fail recovery: PowerOff + InterposerOff
                        Dp860SendPowerOff(waitMs, retry);
                        Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
                        return result;
                    }

                    // Power on
                    result = Dp860SendPowerOn(waitMs, retry);
                    if (result == WAIT_OBJECT_0)
                    {
                        // TconInfo after power-on
                        Dp860SendSimpleCmd(Dp860Commands.CmdIdTconInfo, Dp860Commands.CmdStrTconInfo, "", "tcon.info", 1000, 0);
                        IsPowerOn = true;
                    }
                }
                else
                {
                    // PowerReset: just power.on (no interposer init)
                    result = Dp860SendPowerOn(waitMs, retry);
                    if (result == WAIT_OBJECT_0)
                        IsPowerOn = true;
                }
            }
        }
        finally
        {
            SetCyclicTimer(true);
        }
        return result;
    }

    /// <inheritdoc/>
    public uint SendPowerBistOn(int mode, bool powerReset = false, int waitMs = 10000, int retry = 0)
    {
        uint result = WAIT_FAILED;
        try
        {
            SetCyclicTimer(false);

            if (mode == PgCommandParam.PowerOff)
            {
                // ── BIST Power OFF ─────────────────────────────────────
                // Delphi: CommPG.pas line 5706-5750 (CMD_POWER_OFF, DP860)
                if (_isOnFlashAccess)
                {
                    _logger.Warn(PgIndex, "Power BIST Off NG (On Flash Access) ...Try again after flash access is done");
                    return WAIT_FAILED;
                }
                result = Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerBistOff, Dp860Commands.CmdStrPowerBistOff, "", "power.bist.off", waitMs, retry);
                if (!powerReset)
                {
                    Thread.Sleep(DelayPowerInterposerOff);
                    Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
                }
                if (result == WAIT_OBJECT_0)
                    IsPowerOn = false;
            }
            else
            {
                // ── BIST Power ON ──────────────────────────────────────
                // Delphi: CommPG.pas line 5751-5808 (CMD_POWER_ON, DP860)
                if (!powerReset)
                {
                    result = InterposerInitSequence(waitMs, retry);
                    if (result != WAIT_OBJECT_0) return result;

                    // DUT detect
                    result = Dp860SendSimpleCmd(Dp860Commands.CmdIdDutDetect, Dp860Commands.CmdStrDutDetect, "", "dut.detect", 1000, 1);
                    if (result != WAIT_OBJECT_0)
                    {
                        // Fail recovery
                        Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerBistOff, Dp860Commands.CmdStrPowerBistOff, "", "power.bist.off", waitMs, retry);
                        Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
                        return result;
                    }

                    result = Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerBistOn, Dp860Commands.CmdStrPowerBistOn, "", "power.bist.on", waitMs, retry);
                    if (result == WAIT_OBJECT_0)
                    {
                        Dp860SendSimpleCmd(Dp860Commands.CmdIdTconInfo, Dp860Commands.CmdStrTconInfo, "", "tcon.info", 1000, 0);
                        IsPowerOn = true;
                    }
                }
                else
                {
                    // PowerReset: just power.bist.on
                    result = Dp860SendSimpleCmd(Dp860Commands.CmdIdPowerBistOn, Dp860Commands.CmdStrPowerBistOn, "", "power.bist.on", waitMs, retry);
                    if (result == WAIT_OBJECT_0)
                        IsPowerOn = true;
                }
            }
        }
        finally
        {
            SetCyclicTimer(true);
        }
        return result;
    }

    /// <inheritdoc/>
    /// <remarks>
    /// Delphi: CommPG.pas SendPowerVsysOn (line 5617-5677)
    /// <para>
    /// VSYS power uses sys1v8.on/off instead of power.on/off.
    /// Unlike SendPowerOn, the VSYS interposer sequence does NOT do
    /// InterposerOff first — it goes directly to InterposerOn, and only
    /// does Off→On as a retry. Also no ERASE command or TconInfo.
    /// </para>
    /// </remarks>
    public uint SendPowerVsysOn(int mode, bool powerReset = false, int waitMs = 10000, int retry = 0)
    {
        uint result = WAIT_FAILED;
        try
        {
            SetCyclicTimer(false);

            if (mode == PgCommandParam.PowerOff)
            {
                // ── VSYS Power OFF ───────────────────────────────────
                // Delphi: DP860_SendVsysPowerOff → [if !powerReset: delay + InterposerOff]
                result = Dp860SendSimpleCmd(Dp860Commands.CmdIdSys1V8Off, Dp860Commands.CmdStrSys1V8Off, "", "sys1v8.off", waitMs, retry);
                if (!powerReset)
                {
                    Thread.Sleep(DelayPowerInterposerOff);
                    Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
                }
                if (result == WAIT_OBJECT_0)
                    IsPowerOn = false;
            }
            else
            {
                // ── VSYS Power ON ────────────────────────────────────
                // Delphi: [if !powerReset: InterposerOn → DutDetect → sys1v8.on]
                //         [if  powerReset: sys1v8.on only]
                if (!powerReset)
                {
                    // InterposerOn directly (no InterposerOff first, unlike SendPowerOn)
                    result = Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOn, Dp860Commands.CmdStrInterposerOn, "", "interposer.init", waitMs, retry);

                    // Retry: Off → 100ms → On
                    if (result != WAIT_OBJECT_0)
                    {
                        Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
                        Thread.Sleep(100);
                        result = Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOn, Dp860Commands.CmdStrInterposerOn, "", "interposer.init", waitMs, retry);
                    }

                    if (result == WAIT_OBJECT_0)
                    {
                        Thread.Sleep(DelayPowerInterposerOn);

                        // DUT detect (if enabled in model config)
                        result = Dp860SendSimpleCmd(Dp860Commands.CmdIdDutDetect, Dp860Commands.CmdStrDutDetect, "", "dut.detect", 1000, 1);

                        if (result == WAIT_OBJECT_0)
                        {
                            result = Dp860SendSimpleCmd(Dp860Commands.CmdIdSys1V8On, Dp860Commands.CmdStrSys1V8On, "", "sys1v8.on", waitMs, retry);
                            if (result == WAIT_OBJECT_0)
                                IsPowerOn = true;
                        }
                        else
                        {
                            // Fail recovery: VsysPowerOff + InterposerOff
                            Dp860SendSimpleCmd(Dp860Commands.CmdIdSys1V8Off, Dp860Commands.CmdStrSys1V8Off, "", "sys1v8.off", waitMs, retry);
                            Dp860SendSimpleCmd(Dp860Commands.CmdIdInterposerOff, Dp860Commands.CmdStrInterposerOff, "", "interposer.deinit", waitMs, retry);
                        }
                    }
                }
                else
                {
                    // PowerReset: just sys1v8.on (no interposer init)
                    result = Dp860SendSimpleCmd(Dp860Commands.CmdIdSys1V8On, Dp860Commands.CmdStrSys1V8On, "", "sys1v8.on", waitMs, retry);
                    if (result == WAIT_OBJECT_0)
                        IsPowerOn = true;
                }
            }
        }
        finally
        {
            SetCyclicTimer(true);
        }
        return result;
    }

    // =========================================================================
    // FLOW-SPECIFIC: Power Measure
    // =========================================================================

    /// <inheritdoc/>
    public uint SendPowerMeasure(bool cyclicMeasure = false)
    {
        if (_waitEvent || _waitPwrEvent)
        {
            if (!cyclicMeasure)
                Thread.Sleep(_waitPwrEvent ? PgTimerDefaults.PwrMeasureWaitAckDefault : PgTimerDefaults.CmdWaitAckDefault);
            else
                return WAIT_FAILED;
        }

        var result = Dp860SendCmd(Dp860Commands.CmdStrPowerRead,
            Dp860Commands.CmdIdPowerRead, Dp860Commands.CmdStrPowerRead, PgTimerDefaults.PwrMeasureWaitAckDefault);

        // Delphi: SendPowerMeasure calls DP860_ReadPowerMeasureAck(FTxRxPG.RxAckStr)
        // after CheckCmdAck returns OK — this clears _waitPwrEvent and parses power data.
        if (result == WAIT_OBJECT_0)
        {
            Dp860ReadPowerMeasureAck(TxRxPg.RxAckStr);
        }
        else
        {
            // On failure, _waitPwrEvent was set true by Dp860SendCmd but never cleared
            // because Dp860ReadPowerMeasureAck was not called. Clear it to prevent
            // all subsequent PG commands from being delayed by the busy-wait loop.
            _waitPwrEvent = false;
        }

        return result;
    }

    // =========================================================================
    // FLOW-SPECIFIC: Pattern Display
    // =========================================================================

    /// <inheritdoc/>
    public uint SendDisplayPatRgb(int r, int g, int b, int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdImageRgb, Dp860Commands.CmdStrImageRgb, $"{r} {g} {b}", "image.rgb", waitMs, retry);

    /// <inheritdoc/>
    public uint SendDisplayPatBistRgb(int r, int g, int b, int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdBistRgb, Dp860Commands.CmdStrBistRgb, $"{r} {g} {b}", "bist.rgb", waitMs, retry);

    /// <inheritdoc/>
    public uint SendDisplayPatBistRgb9Bit(int r, int g, int b, int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdBistRgb9Bit, Dp860Commands.CmdStrBistRgb9Bit, $"{r} {g} {b}", "bist.9bit", waitMs, retry);

    /// <inheritdoc/>
    public uint SendDisplayPatNum(int patNum, int waitMs = 2000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdImageDisplay, Dp860Commands.CmdStrImageDisplay, patNum.ToString(), "image.display", waitMs, retry);

    /// <inheritdoc/>
    public uint SendDisplayPatPwmNum(int patNum, int waitMs = 3000, int retry = 0)
        => SendDisplayPatNum(patNum, waitMs, retry);

    /// <inheritdoc/>
    public uint SendDisplayPatNext(int waitMs = 3000, int retry = 0)
        => SendDisplayPatNum(CurrentPatternInfo.CurrentPatternNumber + 1, waitMs, retry);

    // =========================================================================
    // FLOW-SPECIFIC: Gray Change / Dimming
    // =========================================================================

    /// <inheritdoc/>
    public uint SendGrayChange(int grayOffset, int waitMs = 3000, int retry = 0)
    {
        if (!_appConfig.FeatureGrayChange) return WAIT_OBJECT_0;

        // Apply gray offset via I2C writes or pattern display adjustments
        // Implementation depends on current pattern RGB values
        CurrentPatternInfo.GrayOffset = grayOffset;
        return WAIT_OBJECT_0;
    }

    /// <inheritdoc/>
    public uint SendDimming(int dimming, int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdAlpdpDbv, Dp860Commands.CmdStrAlpdpDbv, $"0x{dimming:x}", "alpdp.dbv", waitMs, retry);

    /// <inheritdoc/>
    public uint SendDimmingBist(int dimming, int waitMs = 3000, int retry = 0)
        => Dp860SendSimpleCmd(Dp860Commands.CmdIdBistDbv, Dp860Commands.CmdStrBistDbv, $"0x{dimming:x}", "bist.dbv", waitMs, retry);

    /// <inheritdoc/>
    public uint SendPocbOnOff(bool on, int waitMs = 3000, int retry = 0)
    {
        // FEATURE_POCB_ONOFF — only for FI/OQA inspectors
        return WAIT_OBJECT_0;
    }

    // =========================================================================
    // FLOW-SPECIFIC: I2C Read/Write
    // =========================================================================

    /// <inheritdoc/>
    public uint SendI2CRead(int devAddr, int regAddr, int dataCnt, byte[] readData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        if (readData.Length < dataCnt)
        {
            AddLog($"SendI2CRead NG(ReadDataCnt:{dataCnt} < ReadDataBuf.Length:{readData.Length})");
            return WAIT_FAILED;
        }

        var btaData = new byte[dataCnt];

        // OC/PreOC delay before read (SpinWait for precision)
        var sysInfo = _configService.SystemInfo;
        if (sysInfo.PG_TconWriteCmdType == 0 && sysInfo.PG_TconReadBeforeDelayMsec > 0)
            SpinWaitMilliseconds(sysInfo.PG_TconReadBeforeDelayMsec);

        uint result;
        switch (sysInfo.PG_TconReadCmdType)
        {
            case 1:
                result = Dp860SendTconByteRead(regAddr, dataCnt, btaData, waitMs, retry, debugLog);
                break;
            default:
                result = Dp860SendTconRead(regAddr, dataCnt, btaData, waitMs, retry, debugLog);
                break;
        }

        if (result == WAIT_OBJECT_0)
        {
            TxRxPg.RxDataLen = dataCnt;
            Array.Copy(btaData, readData, dataCnt);
            Array.Copy(btaData, TxRxPg.RxData, dataCnt);
        }

        return result;
    }

    /// <inheritdoc/>
    public uint SendTempRead(int devAddr, int regAddr, int dataCnt, byte[] readData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        if (readData.Length < dataCnt)
        {
            AddLog($"SendTEMPRead NG(ReadDataCnt:{dataCnt} < ReadDataBuf.Length:{readData.Length})");
            return WAIT_FAILED;
        }

        var sysInfo = _configService.SystemInfo;
        if (sysInfo.PG_TconWriteCmdType == 0 && sysInfo.PG_TconReadBeforeDelayMsec > 0)
            SpinWaitMilliseconds(sysInfo.PG_TconReadBeforeDelayMsec);

        var btaData = new byte[dataCnt];
        var result = Dp860SendI2CRead(devAddr, regAddr, dataCnt, btaData, waitMs, retry, debugLog);
        if (result != WAIT_OBJECT_0)
            result = Dp860SendI2CRead(devAddr, regAddr, dataCnt, btaData, waitMs, retry, debugLog);

        if (result == WAIT_OBJECT_0)
        {
            TxRxPg.RxDataLen = dataCnt;
            Array.Copy(btaData, readData, dataCnt);
            Array.Copy(btaData, TxRxPg.RxData, dataCnt);
        }

        return result;
    }

    /// <inheritdoc/>
    public uint SendI2CWrite(int devAddr, int regAddr, int dataCnt, byte[] writeData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        var sysInfo = _configService.SystemInfo;

        // OC/PreOC write strategy selection
        uint result;
        switch (sysInfo.PG_TconWriteCmdType)
        {
            case 0: // tcon.ocwrite (no ack)
                result = Dp860SendTconOcWrite(regAddr, dataCnt, writeData, 0, 0);

                break;
            case 1: // tcon.write (ack)
                result = Dp860SendTconWrite(regAddr, dataCnt, writeData, waitMs, retry, debugLog);

                break;
            case 3: // tcon.writeread (ack)
                result = Dp860SendTconWriteRead(regAddr, dataCnt, 1, writeData, waitMs, retry, debugLog);

                break;
            default: // case 2: selective ocwrite + sync
                result = Dp860SendTconWrite(regAddr, dataCnt, writeData, waitMs, retry, debugLog);
                break;
        }

        return result;
    }

    /// <inheritdoc/>
    public uint SendI2CMultiWrite(int devAddr, int dataCnt, int[] regAddrs, byte[] writeData,
        int waitMs = 2000, int retry = 0)
        => Dp860SendTconMultiWrite(dataCnt, regAddrs, writeData, waitMs, retry);

    /// <inheritdoc/>
    public uint SendI2CSeqWrite(int mode, int seqIdx, int dataCnt, int[] regAddrs, byte[] writeData,
        int waitMs = 2000, int retry = 0)
        => Dp860SendTconSeqWrite(mode, seqIdx, dataCnt, regAddrs, writeData, waitMs, retry);

    /// <inheritdoc/>
    public uint SendReProgramming(int devAddr, int regAddr, int dataCnt, byte[] writeData,
        int waitMs = 3000, int retry = 0)
        => Dp860SendProgrammingWrite(devAddr, regAddr, dataCnt, writeData, waitMs, retry);

    // =========================================================================
    // FLOW-SPECIFIC: Flash
    // =========================================================================

    /// <inheritdoc/>
    public uint SendFlashRead(uint addr, uint size, byte[] data,
        int waitMs = 5000, int retry = 0, bool clearAfterGet = false, bool readMode = false)
    {
        if (!_appConfig.FeatureFlashAccess) return WAIT_FAILED;

        var sFunc = $"FlashRead(Addr=0x{addr:X},Size={size})";
        var caller = new System.Diagnostics.StackTrace().GetFrame(1)?.GetMethod();
        var callerName = caller != null ? $"{caller.DeclaringType?.Name}.{caller.Name}" : "unknown";
        _logger.Info(PgIndex, $"[FlashRead] {sFunc} readMode={readMode} caller={callerName}");

        try
        {
            _isOnFlashAccess = true;

            if (readMode)
            {
                // --- 256-byte chunk read (NVM read via UDP) ---
                uint curAddr = addr;
                int remain = (int)size;
                int offset = 0;
                uint result = WAIT_OBJECT_0;

                while (remain > 0)
                {
                    int chunk = remain >= 256 ? 256 : remain;
                    var chunkBuf = new byte[chunk];
                    uint resChunk = WAIT_FAILED;

                    for (int nTry = 0; nTry <= retry; nTry++)
                    {
                        resChunk = Dp860SendNvmRead(curAddr, (uint)chunk, chunkBuf, waitMs, retry);
                        if (resChunk == WAIT_OBJECT_0) break;
                    }

                    if (resChunk != WAIT_OBJECT_0) { result = resChunk; break; }

                    Array.Copy(chunkBuf, 0, data, offset, chunk);
                    curAddr += (uint)chunk;
                    offset += chunk;
                    remain -= chunk;
                }

                return result;
            }
            else
            {
                // --- File-based read: NVM readfile → FTP download ---
                var remoteFile = $"FlashR_A0x{addr:x}_L{size}.bin";
                var result = Dp860SendNvmReadFile(addr, size, remoteFile, waitMs, retry);
                if (result != WAIT_OBJECT_0) return result;

                var flashDir = _flashDir;
                var localFile = Path.Combine(flashDir, $"CH{PgIndex + 1}_{remoteFile}");

                if (File.Exists(localFile)) File.Delete(localFile);

                // FTP download from PG
                result = Dp860FileGetPg2Pc("/home/upload", remoteFile, localFile, clearAfterGet);
                if (result != WAIT_OBJECT_0)
                {
                    // Retry: reconnect FTP and try again
                    AddLog($"{sFunc} FTP download failed, retrying...");
                    result = Dp860SendNvmReadFile(addr, size, remoteFile, waitMs, retry);
                    if (result != WAIT_OBJECT_0) return result;
                    result = Dp860FileGetPg2Pc("/home/upload", remoteFile, localFile, clearAfterGet);
                    if (result != WAIT_OBJECT_0) return result;
                }

                // Read downloaded file into data buffer
                var fileData = File.ReadAllBytes(localFile);
                if (fileData.Length != (int)size)
                    AddLog($"{sFunc} WARNING: file size {fileData.Length} != requested {size}");
                Array.Copy(fileData, 0, data, 0, Math.Min(fileData.Length, (int)size));

                return WAIT_OBJECT_0;
            }
        }
        finally
        {
            _isOnFlashAccess = false;
        }
    }

    /// <inheritdoc/>
    public uint SendFlashWrite(uint addr, uint size, byte[] data, int waitMs = 100000, int retry = 0)
    {
        if (!_appConfig.FeatureFlashAccess) return WAIT_FAILED;

        // Delphi: X3584/X3585 requires SendFlashPrework before writing
        if (_modelType == 1)
        {
            var preworkResult = SendFlashPrework();
            if (preworkResult != WAIT_OBJECT_0) return preworkResult;
        }

        // Calc SumCRC for logging
        ushort calcCrc = 0;
        for (int i = 0; i < size; i++)
            calcCrc = (ushort)((calcCrc + data[i]) & 0xFFFF);

        var sFunc = $"SendFlashWrite(Addr=0x{addr:X},Size={size},Retry={retry})(CRC=0x{calcCrc:X}:{calcCrc})";

        try
        {
            _isOnFlashAccess = true;

            for (int nTry = 0; nTry <= retry; nTry++)
            {
                var remotePath = "/home/upload";
                var remoteFile = $"FlashW_A0x{addr:x}_L{size}.bin";
                var flashDir = _flashDir;
                var localFile = Path.Combine(flashDir, $"CH{PgIndex + 1}_{remoteFile}");

                // Write data to local file
                File.WriteAllBytes(localFile, data.AsSpan(0, (int)size).ToArray());

                // FTP upload to PG
                var result = Dp860FilePutPc2Pg(localFile, remotePath, remoteFile);
                if (result != WAIT_OBJECT_0)
                {
                    // Retry FTP upload once
                    result = Dp860FilePutPc2Pg(localFile, remotePath, remoteFile);
                    if (result != WAIT_OBJECT_0) break;
                }

                // Send nvm.writefile command
                result = Dp860SendNvmWriteFile(addr, size, remoteFile, true, true, waitMs, retry);
                if (result != WAIT_OBJECT_0) break;

                return WAIT_OBJECT_0;
            }
        }
        finally
        {
            _isOnFlashAccess = false;
        }

        AddLog($"{sFunc}...NG");
        return WAIT_FAILED;
    }

    /// <inheritdoc/>
    public uint SendFlashPrework(int waitMs = 100000, int retry = 0)
    {
        if (!_appConfig.FeatureFlashAccess) return WAIT_FAILED;

        // X3584/X3585 specific IXORA pre-work
        // Delphi: sPgCmdPara := 'IXORA.DFUSTS 1 4096 18864 36';
        var cmd = "IXORA.DFUSTS 1 4096 18864 36";
        var result = Dp860SendCmd(cmd, PgCommandParam.CmdIdUnknown, cmd, 3000, 0);
        if (result != WAIT_OBJECT_0)
        {
            AddLog($"SendCmd Error! [{cmd}]!");
            return result;
        }

        return WAIT_OBJECT_0;
    }

    /// <inheritdoc/>
    public uint GetFlashDataBuf(uint addr, uint len, byte[] data)
    {
        if (!_flashData.IsValid) return WAIT_FAILED;
        if (addr < (uint)_flashData.StartAddr) return WAIT_FAILED;
        if (addr + len > (uint)(_flashData.StartAddr + _flashData.Size)) return WAIT_FAILED;

        Array.Copy(_flashData.Data, (int)addr, data, 0, (int)len);
        return WAIT_OBJECT_0;
    }

    /// <inheritdoc/>
    public uint UpdateFlashDataBuf(uint addr, uint len, byte[] data)
    {
        if (!_flashData.IsValid) return WAIT_FAILED;
        if (addr < (uint)_flashData.StartAddr) return WAIT_FAILED;
        if (addr + len > (uint)(_flashData.StartAddr + _flashData.Size)) return WAIT_FAILED;

        Array.Copy(data, 0, _flashData.Data, (int)addr, (int)len);
        return WAIT_OBJECT_0;
    }

    // =========================================================================
    // DP860 Low-Level TCON Commands
    // =========================================================================

    private uint Dp860SendTconRead(int regAddr, int dataCnt, byte[] readData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        // Large read: split into 128-byte chunks to avoid IP fragmentation
        // (DPDK has no IP reassembly; 128 hex values → ~400B response → fits in single MTU)
        const int MaxChunkSize = 128;
        if (dataCnt > MaxChunkSize)
        {
            int offset = 0;
            while (offset < dataCnt)
            {
                int chunk = Math.Min(MaxChunkSize, dataCnt - offset);
                var chunkCmd = $"{Dp860Commands.CmdStrTconRead} {FormatAddr(regAddr + offset)} {chunk}";
                var chunkResult = Dp860SendCmd(chunkCmd, Dp860Commands.CmdIdTconRead,
                    Dp860Commands.CmdStrTconRead, waitMs, retry);

                TconRwCount.TconReadTx++;
                TconRwCount.ContTconOcWrite = 0;

                if (chunkResult != WAIT_OBJECT_0)
                    return chunkResult;

                try
                {
                    var parts = TxRxPg.RxAckStr.Split('\r')[0].Split(' ');
                    if (parts.Length >= chunk)
                    {
                        for (int i = 0; i < chunk; i++)
                            readData[offset + i] = byte.Parse(parts[i], NumberStyles.HexNumber);
                    }
                    else
                        return WAIT_FAILED;
                }
                catch { return WAIT_FAILED; }

                offset += chunk;
            }
            return WAIT_OBJECT_0;
        }

        var cmd = $"{Dp860Commands.CmdStrTconRead} {FormatAddr(regAddr)} {dataCnt}";
        var result = Dp860SendCmd(cmd, Dp860Commands.CmdIdTconRead, Dp860Commands.CmdStrTconRead, waitMs, retry);

        TconRwCount.TconReadTx++;
        TconRwCount.ContTconOcWrite = 0;

        if (result == WAIT_OBJECT_0)
        {
            try
            {
                var parts = TxRxPg.RxAckStr.Split('\r')[0].Split(' ');
                if (parts.Length >= dataCnt)
                {
                    for (int i = 0; i < dataCnt; i++)
                        readData[i] = byte.Parse(parts[i], NumberStyles.HexNumber);
                }
                else
                {
                    result = WAIT_FAILED;
                }
            }
            catch
            {
                result = WAIT_FAILED;
            }
        }
        return result;
    }

    private uint Dp860SendTconByteRead(int regAddr, int dataCnt, byte[] readData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        var cmd = $"{Dp860Commands.CmdStrTconByteRead} {FormatAddr(regAddr)} {dataCnt}";
        var result = Dp860SendCmd(cmd, Dp860Commands.CmdIdTconByteRead, Dp860Commands.CmdStrTconByteRead, waitMs, retry);

        TconRwCount.TconReadTx++;
        TconRwCount.ContTconOcWrite = 0;

        if (result == WAIT_OBJECT_0)
        {
            try
            {
                var lines = TxRxPg.RxAckStr.Split('\r');
                if (lines.Length >= dataCnt + 1)
                {
                    for (int i = 0; i < dataCnt; i++)
                        readData[i] = byte.Parse(lines[i + 1].Trim(), NumberStyles.HexNumber);
                }
                else
                {
                    result = WAIT_FAILED;
                }
            }
            catch
            {
                result = WAIT_FAILED;
            }
        }
        return result;
    }

    private uint Dp860SendI2CRead(int devAddr, int regAddr, int dataCnt, byte[] readData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        var cmd = $"{Dp860Commands.CmdStrI2cRead} 4 0x{devAddr:x4} 0x{regAddr:x4} {dataCnt}";
        var result = Dp860SendCmd(cmd, Dp860Commands.CmdIdI2cRead, Dp860Commands.CmdStrI2cRead, waitMs, retry);

        TconRwCount.TconReadTx++;
        TconRwCount.ContTconOcWrite = 0;

        if (result == WAIT_OBJECT_0)
        {
            try
            {
                var parts = TxRxPg.RxAckStr.Split('\r')[0].Split(' ');
                if (parts.Length >= dataCnt)
                {
                    for (int i = 0; i < dataCnt; i++)
                        readData[i] = byte.Parse(parts[i], NumberStyles.HexNumber);
                }
                else
                {
                    result = WAIT_FAILED;
                }
            }
            catch
            {
                result = WAIT_FAILED;
            }
        }
        return result;
    }

    private uint Dp860SendTconWrite(int regAddr, int dataCnt, byte[] writeData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        const int CHUNK = 256;
        uint overallResult = WAIT_OBJECT_0;

        if (dataCnt <= 0 || writeData.Length < dataCnt) return WAIT_FAILED;

        int chunkIdx = 0;
        while (chunkIdx * CHUNK < dataCnt)
        {
            int chunkStart = chunkIdx * CHUNK;
            int chunkCount = Math.Min(CHUNK, dataCnt - chunkStart);
            int curAddr = regAddr + chunkStart;

            var sb = new System.Text.StringBuilder();
            sb.Append($"{Dp860Commands.CmdStrTconWrite} {FormatAddr(curAddr)} {chunkCount}");

            int crcData = 0;
            for (int i = 0; i < chunkCount; i++)
            {
                sb.Append($" 0x{writeData[chunkStart + i]:x2}");
                crcData += writeData[chunkStart + i];
            }

            crcData = 0xFFFF & (crcData + curAddr);
            sb.Append($" 0x{crcData:x4}");

            var result = Dp860SendCmd(sb.ToString(), Dp860Commands.CmdIdTconWrite, Dp860Commands.CmdStrTconWrite, waitMs, retry);
            TconRwCount.TconWriteTx++;
            TconRwCount.ContTconOcWrite = 0;

            if (result != WAIT_OBJECT_0)
                overallResult = result;

            chunkIdx++;
        }

        return overallResult;
    }

    private uint Dp860SendTconOcWrite(int regAddr, int dataCnt, byte[] writeData,
        int waitMs = 0, int retry = 0)
    {
        var sb = new System.Text.StringBuilder();
        sb.Append($"{Dp860Commands.CmdStrTconOcWrite} {FormatAddr(regAddr)} {dataCnt}");
        for (int i = 0; i < dataCnt; i++)
            sb.Append($" 0x{writeData[i]:x2}");

        var result = Dp860SendCmd(sb.ToString(), Dp860Commands.CmdIdTconOcWrite, Dp860Commands.CmdStrTconOcWrite, waitMs, retry);
        TconRwCount.TconOcWriteTx++;
        TconRwCount.ContTconOcWrite++;
        return result;
    }

    private uint Dp860SendTconMultiWrite(int dataCnt, int[] regAddrs, byte[] writeData,
        int waitMs = 0, int retry = 0)
    {
        var sb = new System.Text.StringBuilder();
        sb.Append($"{Dp860Commands.CmdStrTconMultiWrite} {dataCnt}");
        for (int i = 0; i < dataCnt; i++)
            sb.Append($" {FormatAddr(regAddrs[i])} 0x{writeData[i]:x2}");

        var result = Dp860SendCmd(sb.ToString(), Dp860Commands.CmdIdTconMultiWrite, Dp860Commands.CmdStrTconMultiWrite, waitMs, retry);
        TconRwCount.TconMultiWriteDllCall++;
        TconRwCount.ContTconOcWrite++;
        return result;
    }

    private uint Dp860SendTconSeqWrite(int mode, int seqIdx, int dataCnt, int[] regAddrs, byte[] writeData,
        int waitMs = 0, int retry = 0, int debugLog = 0)
    {
        var dataSb = new System.Text.StringBuilder();
        long crcAddr = 0;
        long crcData = 0;

        for (int i = 0; i < dataCnt; i++)
        {
            dataSb.Append($" {FormatAddr(regAddrs[i])} {writeData[i]:x2}");
            crcAddr += regAddrs[i];
            crcData += writeData[i];
        }

        crcAddr = 0xFFFF & crcAddr;
        crcData = 0xFF & crcData;

        var cmd = $"{Dp860Commands.CmdStrTconSeqWrite} {mode} {seqIdx} {dataCnt} {crcAddr:x4} {crcData:x2}{dataSb}";
        var result = Dp860SendCmd(cmd, Dp860Commands.CmdIdTconSeqWrite, Dp860Commands.CmdStrTconSeqWrite, waitMs, retry);


        TconRwCount.TconSeqWriteDllCall++;
        return result;
    }

    private uint Dp860SendTconWriteRead(int regAddr, int dataCnt, int verify, byte[] writeData,
        int waitMs = 2000, int retry = 0, int debugLog = 0)
    {
        int crcData = 0;
        var sb = new System.Text.StringBuilder();
        sb.Append($"{Dp860Commands.CmdStrTconWriteRead} {verify} {FormatAddr(regAddr)} {dataCnt}");
        for (int i = 0; i < dataCnt; i++)
        {
            sb.Append($" 0x{writeData[i]:x2}");
            crcData += writeData[i];
        }
        crcData = 0xFFFF & (crcData + regAddr);
        sb.Append($" 0x{crcData:x4}");

        var result = Dp860SendCmd(sb.ToString(), Dp860Commands.CmdIdTconWriteRead, Dp860Commands.CmdStrTconWriteRead, waitMs, retry);
        TconRwCount.TconWriteTx++;
        if (result == WAIT_OBJECT_0) _previousCommand = sb.ToString();
        return result;
    }

    private uint Dp860SendProgrammingWrite(int devAddr, int regAddr, int dataCnt, byte[] writeData,
        int waitMs = 2000, int retry = 0)
    {
        var sb = new System.Text.StringBuilder();
        sb.Append($"{Dp860Commands.CmdStrReprograming} 0x{devAddr:x2} 0x{regAddr:x4} {dataCnt}");
        for (int i = 0; i < dataCnt; i++)
            sb.Append($" {writeData[i]:x2}");

        return Dp860SendCmd(sb.ToString(), Dp860Commands.CmdIdReprograming, Dp860Commands.CmdStrReprograming, waitMs, retry);
    }

    // =========================================================================
    // DP860 NVM (Flash) Commands
    // =========================================================================

    private uint Dp860SendNvmReadFile(uint addr, uint size, string remoteFile, int waitMs, int retry)
    {
        // Delphi: nvm.readfile <filename.bin> <hex_addr> <length>
        // Delphi Format('%s 0x%x %d') → 소문자 hex
        var cmd = $"{Dp860Commands.CmdStrNvmReadFile} {remoteFile} 0x{addr:x} {size}";
        // Adjust waitMs based on flash read speed
        int flashReadKbPerSec = PgFlashConstants.FlashReadKbPerSecDefault;
        waitMs = (int)(((size / (flashReadKbPerSec * 1024)) + 1) * 1000) + waitMs;

        try
        {
            _isOnFlashAccess = true;
            return Dp860SendCmd(cmd, Dp860Commands.CmdIdNvmReadFile, Dp860Commands.CmdStrNvmReadFile, waitMs, retry);
        }
        finally
        {
            _isOnFlashAccess = false;
        }
    }

    private uint Dp860SendNvmWriteFile(uint addr, uint size, string remoteFile,
        bool verify = true, bool erase = true, int waitMs = 10000, int retry = 0)
    {
        // Delphi: nvm.writefile <filename.bin> <hex_addr> <length> <option1> <option2>
        var eraseOpt = erase ? "erase" : "0";
        var verifyOpt = verify ? "verify" : "0";
        var cmd = $"{Dp860Commands.CmdStrNvmWriteFile} {remoteFile} 0x{addr:x} {size} {eraseOpt} {verifyOpt}";

        // Adjust waitMs based on flash write speed
        int flashWriteKbPerSec = PgFlashConstants.FlashWriteKbPerSecDefault;
        waitMs = (int)(((size / (flashWriteKbPerSec * 1024)) + 1) * 1000) + waitMs;

        try
        {
            _isOnFlashAccess = true;
            return Dp860SendCmd(cmd, Dp860Commands.CmdIdNvmWriteFile, Dp860Commands.CmdStrNvmWriteFile, waitMs, retry);
        }
        finally
        {
            _isOnFlashAccess = false;
        }
    }

    /// <summary>
    /// NVM read via UDP (small chunks). Delphi: DP860_SendNvmRead
    /// </summary>
    private uint Dp860SendNvmRead(uint addr, uint size, byte[] data, int waitMs, int retry)
    {
        var cmd = $"{Dp860Commands.CmdStrNvmRead} 0x{addr:x} {size}";
        try
        {
            _isOnFlashAccess = true;
            var result = Dp860SendCmd(cmd, Dp860Commands.CmdIdNvmRead, Dp860Commands.CmdStrNvmRead, waitMs, retry);
            if (result == WAIT_OBJECT_0)
            {
                // Parse hex data from RxAckStr
                var parts = TxRxPg.RxAckStr.Split('\r')[0].Split(' ');
                for (int i = 0; i < Math.Min(parts.Length, (int)size); i++)
                {
                    if (byte.TryParse(parts[i], NumberStyles.HexNumber, null, out var b))
                        data[i] = b;
                }
            }
            return result;
        }
        finally
        {
            _isOnFlashAccess = false;
        }
    }

    // =========================================================================
    // DP860 FTP Operations (PG internal FTP server)
    // =========================================================================

    /// <summary>
    /// FTP download from PG to PC. Delphi: DP860_FileGetPG2PC
    /// Uses HwFtpEngine (lwIP) for DPDK mode.
    /// </summary>
    private uint Dp860FileGetPg2Pc(string remotePath, string remoteFile, string localFullName, bool clearAfterGet = false)
    {
        AddLog($"<PG> FTP FileDownload: {remoteFile} → {localFullName}");

        if (_nicCoordinator != null && _dpdkManager != null)
        {
            // DPDK mode: use HwFtpEngine (lwIP)
            return DpdkFtpDownload(remotePath, remoteFile, localFullName, clearAfterGet);
        }
        else
        {
            // Non-DPDK fallback: use standard socket FTP
            return SocketFtpDownload(remotePath, remoteFile, localFullName, clearAfterGet);
        }
    }

    /// <summary>
    /// FTP upload from PC to PG. Delphi: DP860_FilePutPC2PG
    /// Uses HwFtpEngine (lwIP) for DPDK mode.
    /// </summary>
    private uint Dp860FilePutPc2Pg(string localFullName, string remotePath, string remoteFile, bool clearBeforePut = true)
    {
        AddLog($"<PG> FTP FileUpload: {localFullName} → {remoteFile}");

        if (_nicCoordinator != null && _dpdkManager != null)
        {
            // DPDK mode: use HwFtpEngine (lwIP)
            return DpdkFtpUpload(localFullName, remotePath, remoteFile, clearBeforePut);
        }
        else
        {
            // Non-DPDK fallback: use standard socket FTP
            return SocketFtpUpload(localFullName, remotePath, remoteFile, clearBeforePut);
        }
    }

    /// <summary>
    /// DPDK FTP download using HwFtpEngine (lwIP).
    /// FTP 세션을 DLL flow 기간 동안 유지하여 lwIP TCP 리소스 고갈 방지.
    /// </summary>
    private uint DpdkFtpDownload(string remotePath, string remoteFile, string localFullName, bool clearAfterGet)
    {
        try
        {
            EnsureFtpSession();
            return DpdkFtpDownloadWithEngine(_ftpEngine!, remoteFile, localFullName);
        }
        catch (Exception ex)
        {
            _logger.Error($"<PG> DPDK FTP download error: {ex.Message}", ex);
            // 에러 시 세션 해제 — 다음 호출에서 재생성
            DisposeFtpSession();
            return WAIT_FAILED;
        }
    }

    private uint DpdkFtpDownloadWithEngine(HwFtpEngine ftpEngine, string remoteFile, string localFullName)
    {
        var data = ftpEngine.DownloadAsync(remoteFile, 30000).GetAwaiter().GetResult();
        if (data == null)
        {
            AddLog($"<PG> FTP download failed: {ftpEngine.LastError}");
            // 다운로드 실패 시 세션 리셋 → 다음 호출에서 재생성
            DisposeFtpSession();
            return WAIT_FAILED;
        }
        File.WriteAllBytes(localFullName, data);
        AddLog($"<PG> FTP downloaded {remoteFile} ({data.Length} bytes)");
        return WAIT_OBJECT_0;
    }

    /// <summary>
    /// FTP 세션이 없거나 끊어졌으면 새로 생성/연결. 이미 연결되어 있으면 재사용.
    /// Delphi FFTPClient 패턴: 드라이버 수명 동안 1회 생성, 에러 시에만 재생성.
    /// </summary>
    private void EnsureFtpSession()
    {
        if (_ftpEngine != null && _ftpConnected)
            return;

        // 기존 엔진이 있지만 연결이 끊어진 경우 → 정리 후 재생성
        if (_ftpEngine != null)
            DisposeFtpSession();

        var lease = _nicCoordinator!.AcquireFtpAccessAsync().GetAwaiter().GetResult();
        var ftpEngine = new HwFtpEngine(_dpdkManager!, PgIndex);

        var ftpConfig = CreatePgFtpConfig();
        if (!ftpEngine.InitLwip(ftpConfig))
        {
            ftpEngine.Dispose();
            lease.DisposeAsync().GetAwaiter().GetResult();
            throw new InvalidOperationException($"FTP lwIP init failed: {ftpEngine.LastError}");
        }

        if (!ftpEngine.ConnectAsync(PgIpAddress, 21,
            Dp860Ftp.FtpUsername, Dp860Ftp.FtpPassword, 10000).GetAwaiter().GetResult())
        {
            ftpEngine.StopLwip();
            ftpEngine.Dispose();
            lease.DisposeAsync().GetAwaiter().GetResult();
            throw new InvalidOperationException($"FTP connect failed: {ftpEngine.LastError}");
        }

        _ftpEngine = ftpEngine;
        _ftpLease = lease;
        _ftpConnected = true;
        AddLog($"<PG> FTP session created (PG{PgIndex})");
    }

    /// <summary>FTP 세션 해제 — Dispose() 및 에러 복구 시 호출</summary>
    private void DisposeFtpSession()
    {
        _ftpConnected = false;
        if (_ftpEngine != null)
        {
            // lease가 없는 상태(Dispose 경로 등)에서도 RX 폴링 일시정지 보장
            // — hw_lwip_stop_ref()와 hw_dispatch_poll() 동시 실행 방지
            bool needDirectPause = _ftpLease == null && _nicCoordinator != null;
            if (needDirectPause)
            {
                try
                {
                    // lease 없이 직접 RX 정지 (임시 lease 획득으로 Pause 트리거)
                    _ftpLease = _nicCoordinator!.AcquireFtpAccessAsync().GetAwaiter().GetResult();
                }
                catch { }
            }

            try { _ftpEngine.DisconnectAsync().GetAwaiter().GetResult(); } catch { }
            try { _ftpEngine.StopLwip(); } catch { }
            try { _ftpEngine.Dispose(); } catch { }
            _ftpEngine = null;
        }
        if (_ftpLease != null)
        {
            try { _ftpLease.DisposeAsync().GetAwaiter().GetResult(); } catch { }
            _ftpLease = null;
        }
    }

    /// <summary>
    /// DPDK FTP upload using HwFtpEngine (lwIP).
    /// FTP 세션을 드라이버 수명 동안 유지하여 lwIP TCP 리소스 고갈 방지 (Delphi FFTPClient 패턴).
    /// </summary>
    private uint DpdkFtpUpload(string localFullName, string remotePath, string remoteFile, bool clearBeforePut)
    {
        try
        {
            EnsureFtpSession();

            var fileData = File.ReadAllBytes(localFullName);
            if (!_ftpEngine!.UploadAsync(remoteFile, fileData, 30000).GetAwaiter().GetResult())
            {
                AddLog($"<PG> FTP upload failed: {_ftpEngine.LastError}");
                // 업로드 실패 시 세션 해제 → 다음 호출에서 재생성
                DisposeFtpSession();
                return WAIT_FAILED;
            }

            AddLog($"<PG> FTP uploaded {remoteFile} ({fileData.Length} bytes)");
            return WAIT_OBJECT_0;
        }
        catch (Exception ex)
        {
            _logger.Error($"<PG> DPDK FTP upload error: {ex.Message}", ex);
            DisposeFtpSession();
            return WAIT_FAILED;
        }
    }

    /// <summary>
    /// Creates FtpConfig for PG FTP access via DPDK lwIP.
    /// </summary>
    private FtpConfig CreatePgFtpConfig()
    {
        return new FtpConfig
        {
            ServerIp = PgIpAddress,
            ServerPort = 21,
            Username = Dp860Ftp.FtpUsername,
            Password = Dp860Ftp.FtpPassword,
            LocalIp = $"{Dp860Network.NetworkPrefix}.10",  // 169.254.199.10
            Netmask = "255.255.255.0",
            Gateway = $"{Dp860Network.NetworkPrefix}.10",
            TimeoutMs = 10000
        };
    }

    /// <summary>
    /// Standard socket FTP download (non-DPDK mode). Delphi: TFTPClient-based.
    /// Uses standard RFC 959 FTP over TCP to PG's internal FTP server.
    /// </summary>
    private uint SocketFtpDownload(string remotePath, string remoteFile, string localFullName, bool clearAfterGet)
    {
        try
        {
            using var tcpClient = new TcpClient();
            tcpClient.ReceiveTimeout = 10000;
            tcpClient.SendTimeout = 10000;
            tcpClient.Connect(PgIpAddress, 21);

            using var stream = tcpClient.GetStream();
            using var reader = new StreamReader(stream, Encoding.ASCII);
            using var writer = new StreamWriter(stream, Encoding.ASCII) { AutoFlush = true };

            // 220 Welcome
            ReadFtpResponse(reader, 220);
            // Login
            SendFtpCommand(writer, reader, $"USER {Dp860Ftp.FtpUsername}", 331);
            SendFtpCommand(writer, reader, $"PASS {Dp860Ftp.FtpPassword}", 230);
            // Binary mode
            SendFtpCommand(writer, reader, "TYPE I", 200);
            // PASV → data connection
            var (dataHost, dataPort) = EnterFtpPassiveMode(writer, reader);

            using var dataClient = new TcpClient();
            dataClient.Connect(dataHost, dataPort);
            using var dataStream = dataClient.GetStream();

            SendFtpCommand(writer, reader, $"RETR {remoteFile}", 150);

            // Save to local file
            var dir = Path.GetDirectoryName(localFullName);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            using (var fs = new FileStream(localFullName, FileMode.Create, FileAccess.Write))
            {
                dataStream.CopyTo(fs);
            }

            dataClient.Close();
            ReadFtpResponse(reader, 226);

            var fileLen = new FileInfo(localFullName).Length;
            AddLog($"<PG> FTP downloaded {remoteFile} ({fileLen} bytes)");

            // Delete remote file after download if requested
            if (clearAfterGet)
            {
                try { SendFtpCommand(writer, reader, $"DELE {remoteFile}", 250); }
                catch { /* ignore delete failure */ }
            }

            try { writer.WriteLine("QUIT"); } catch { }

            return WAIT_OBJECT_0;
        }
        catch (Exception ex)
        {
            AddLog($"<PG> Socket FTP download error: {ex.Message}");
            return WAIT_FAILED;
        }
    }

    /// <summary>
    /// Standard socket FTP upload (non-DPDK mode). Delphi: TFTPClient-based.
    /// Uses standard RFC 959 FTP over TCP to PG's internal FTP server.
    /// </summary>
    private uint SocketFtpUpload(string localFullName, string remotePath, string remoteFile, bool clearBeforePut)
    {
        try
        {
            if (!File.Exists(localFullName))
            {
                AddLog($"<PG> Socket FTP upload error: file not found — {localFullName}");
                return WAIT_FAILED;
            }

            using var tcpClient = new TcpClient();
            tcpClient.ReceiveTimeout = 10000;
            tcpClient.SendTimeout = 10000;
            tcpClient.Connect(PgIpAddress, 21);

            using var stream = tcpClient.GetStream();
            using var reader = new StreamReader(stream, Encoding.ASCII);
            using var writer = new StreamWriter(stream, Encoding.ASCII) { AutoFlush = true };

            // 220 Welcome
            ReadFtpResponse(reader, 220);
            // Login
            SendFtpCommand(writer, reader, $"USER {Dp860Ftp.FtpUsername}", 331);
            SendFtpCommand(writer, reader, $"PASS {Dp860Ftp.FtpPassword}", 230);
            // Binary mode
            SendFtpCommand(writer, reader, "TYPE I", 200);

            // Delete existing remote file before upload if requested
            if (clearBeforePut)
            {
                try { SendFtpCommand(writer, reader, $"DELE {remoteFile}", 250); }
                catch { /* ignore — file may not exist */ }
            }

            // PASV → data connection
            var (dataHost, dataPort) = EnterFtpPassiveMode(writer, reader);

            using var dataClient = new TcpClient();
            dataClient.Connect(dataHost, dataPort);
            using var dataStream = dataClient.GetStream();

            SendFtpCommand(writer, reader, $"STOR {remoteFile}", 150);

            // Send file data
            using (var fs = new FileStream(localFullName, FileMode.Open, FileAccess.Read))
            {
                fs.CopyTo(dataStream);
            }

            dataClient.Close();
            ReadFtpResponse(reader, 226);

            var fileLen = new FileInfo(localFullName).Length;
            AddLog($"<PG> FTP uploaded {remoteFile} ({fileLen} bytes)");

            try { writer.WriteLine("QUIT"); } catch { }

            return WAIT_OBJECT_0;
        }
        catch (Exception ex)
        {
            AddLog($"<PG> Socket FTP upload error: {ex.Message}");
            return WAIT_FAILED;
        }
    }

    // ---- Socket FTP helper methods (RFC 959) ----

    /// <summary>
    /// Reads FTP response and validates the status code.
    /// Handles multi-line responses (code-hyphen continuation).
    /// </summary>
    private static string ReadFtpResponse(StreamReader reader, int expectedCode)
    {
        var sb = new StringBuilder();
        string? line;
        bool complete = false;

        while (!complete)
        {
            line = reader.ReadLine();
            if (line == null)
                throw new IOException("FTP connection closed unexpectedly.");

            sb.AppendLine(line);

            if (line.Length >= 3 && int.TryParse(line[..3], out int code))
            {
                // Final line: "NNN " (space after code) or exactly 3 chars
                if (line.Length == 3 || line[3] == ' ')
                {
                    complete = true;
                    if (expectedCode > 0 && code / 100 != expectedCode / 100
                        && !(expectedCode == 150 && code == 125))
                    {
                        throw new IOException(
                            $"FTP error: expected {expectedCode}, got {code}. Response: {line}");
                    }
                }
            }
        }

        return sb.ToString();
    }

    /// <summary>
    /// Sends an FTP command and reads the expected response.
    /// </summary>
    private static string SendFtpCommand(StreamWriter writer, StreamReader reader,
        string command, int expectedCode)
    {
        writer.WriteLine(command);
        writer.Flush();
        return ReadFtpResponse(reader, expectedCode);
    }

    /// <summary>
    /// Enters FTP passive mode (PASV) and returns the data connection endpoint.
    /// Parses "227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)".
    /// </summary>
    private static (string Host, int Port) EnterFtpPassiveMode(StreamWriter writer, StreamReader reader)
    {
        string response = SendFtpCommand(writer, reader, "PASV", 227);

        int start = response.IndexOf('(');
        int end = response.IndexOf(')');
        if (start < 0 || end < 0)
            throw new IOException($"Cannot parse PASV response: {response}");

        string[] parts = response[(start + 1)..end].Split(',');
        if (parts.Length != 6)
            throw new IOException($"Invalid PASV response format: {response}");

        string host = $"{parts[0]}.{parts[1]}.{parts[2]}.{parts[3]}";
        int port = int.Parse(parts[4]) * 256 + int.Parse(parts[5]);

        return (host, port);
    }

    // =========================================================================
    // Helper Methods
    // =========================================================================

    /// <summary>
    /// Sends a simple DP860 command with optional parameters.
    /// </summary>
    private uint Dp860SendSimpleCmd(int cmdId, string cmdStr, string param, string logName, int waitMs, int retry)
    {
        var cmd = string.IsNullOrEmpty(param) ? cmdStr : $"{cmdStr} {param}";
        var result = Dp860SendCmd(cmd, cmdId, cmdStr, waitMs, retry);
        var etcMsg = result != WAIT_OBJECT_0 ? $"[{GetPgLogMsg(TxRxPg.RxAckStr)}]" : "";
        AddLog($"<PG> {cmd}:{GetStrCmdResult(result)}{etcMsg}");
        Thread.Sleep(50);
        return result;
    }

    /// <summary>
    /// Resets a TxRx data structure to defaults.
    /// </summary>
    private static void ResetTxRxData(PgTxRxData data)
    {
        data.CmdState = PgCmdState.None;
        data.CmdResult = PgCmdResult.None;
        data.TxCmdId = PgCommandParam.CmdIdUnknown;
        data.TxCmdStr = string.Empty;
        data.TxDataLen = 0;
        data.RxCmdId = PgCommandParam.CmdIdUnknown;
        data.RxAckStr = string.Empty;
        data.RxDataLen = 0;
        data.RxPrevStr = string.Empty;
    }

    private static void SpinWaitMilliseconds(int ms)
    {
        if (ms >= 16) { Thread.Sleep(ms); return; }
        var sw = System.Diagnostics.Stopwatch.StartNew();
        while (sw.ElapsedMilliseconds < ms) Thread.SpinWait(10);
    }

    /// <summary>Parses voltage value from power read ack line.</summary>
    private static uint ParseUInt(string line)
    {
        var parts = line.Split(':');
        return parts.Length > 1 ? uint.Parse(parts[1].Trim()) : 0;
    }

    /// <summary>Parses current value (mA -> uA) from power read ack line.</summary>
    private static uint ParseCurrentUa(string line)
    {
        var parts = line.Split(':');
        return parts.Length > 1 ? (uint)(double.Parse(parts[1].Trim(), CultureInfo.InvariantCulture) * 1000) : 0;
    }

    /// <summary>Extracts alphanumeric chars from a string.</summary>
    private static string ExtractAlphanumeric(string input)
    {
        var result = Regex.Replace(input, @"[^A-Za-z0-9]", "");
        return string.IsNullOrEmpty(result) ? "Not found" : result;
    }

    // =========================================================================
    // Model Config Parameter Builders
    // =========================================================================

    private string MakePowerOpenParam()
    {
        var pwrData = _configService.SystemInfo.PgPwrData;
        if (pwrData == null) return "ALL 0 0 0 0 0 S0 I0 I0 V0 V0";

        return $"ALL {pwrData.PwrVol[PgPowerIndex.Vdd1]} {pwrData.PwrVol[PgPowerIndex.Vdd2]} " +
               $"{pwrData.PwrVol[PgPowerIndex.Vdd3]} {pwrData.PwrVol[PgPowerIndex.Vdd4]} {pwrData.PwrVol[PgPowerIndex.Vdd5]} " +
               $"S{pwrData.PwrSlope} " +
               $"I{pwrData.PwrCurHl[PgPowerIndex.Vdd1]} I{pwrData.PwrCurHl[PgPowerIndex.Vdd2]} " +
               $"V{pwrData.PwrVolHl[PgPowerIndex.Vdd1] / 100} V{pwrData.PwrVolHl[PgPowerIndex.Vdd2] / 100}";
    }

    private string MakePowerSeqParam()
    {
        var pwrSeq = _configService.SystemInfo.PgPwrSeq;
        if (pwrSeq == null) return "0 0 0 0";

        return $"{pwrSeq.SeqOn[0]} {pwrSeq.SeqOn[1]} {pwrSeq.SeqOff[0]} {pwrSeq.SeqOff[1]}";
    }

    private string MakeModelConfigParam()
    {
        var conf = _configService.SystemInfo.PgModelConf;
        if (conf == null) return string.Empty;

        return $"{conf.LinkRate} {conf.Lane} {conf.HSa} {conf.HBp} {conf.HActive} {conf.HFp} " +
               $"{conf.VSa} {conf.VBp} {conf.VActive} {conf.VFp} {conf.Vsync} " +
               $"{conf.RgbFormat} {conf.AlpmMode} {conf.VfbOffset}";
    }

    private string MakeAlpmConfigParam()
    {
        var conf = _configService.SystemInfo.PgModelConf;
        if (conf == null) return string.Empty;

        return $"{conf.HFdp} {conf.HSdp} {conf.HPcnt} {conf.VbN5b} {conf.VbN7} {conf.VbN5a} " +
               $"{conf.VbSleep} {conf.VbN2} {conf.VbN3} {conf.VbN4} {conf.MVid} {conf.NVid} " +
               $"{conf.Misc0} {conf.Misc1} {(conf.Xpol == 0 ? "X0" : "X1")} {conf.Xdelay} " +
               $"{conf.HMg} {conf.NoAuxSel} {conf.NoAuxActive} {conf.NoAuxSleep} " +
               $"{conf.CriticalSection} {conf.Tps} {conf.VBlank} " +
               $"{conf.ChopEnable} {conf.ChopInterval} {conf.ChopSize}";
    }
}
