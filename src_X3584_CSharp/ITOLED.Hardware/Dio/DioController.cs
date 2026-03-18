// =============================================================================
// DioController.cs
// Converted from Delphi: src_X3584\ControlDio_OC.pas (TControlDio)
// DIO controller orchestrator for carrier lock/unlock, probe movement,
// shutter control, pin-block, vacuum, tower lamp, and alarm management.
// Namespace: Dongaeltek.ITOLED.Hardware.Dio
// =============================================================================

using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Messaging;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Dio;

// =========================================================================
// Constants (Delphi unit-level constants from ControlDio_OC.pas)
// =========================================================================

/// <summary>
/// Message mode and alarm severity constants from ControlDio_OC.pas.
/// </summary>
internal static class DioMsgConstants
{
    // CommDIO_DAE message constants (from CommDIO_DAE.pas)
    public const int CommDioMsgNone    = 100;
    public const int CommDioMsgConnect = 101;
    public const int CommDioMsgChangeDi = 103;
    public const int CommDioMsgChangeDo = 104;
    public const int CommDioMsgLog     = 105;
    public const int CommDioMsgLogCh   = 106;
    public const int CommDioMsgError   = 200;
    public const int CommDioMsgMax     = 201;

    // ControlDio_OC display message modes
    public const int MsgModeDisplayStart  = CommDioMsgMax;
    public const int MsgModeDisplayAlarm  = MsgModeDisplayStart + 1; // 202
    public const int MsgModeSystemAlarm   = MsgModeDisplayStart + 2; // 203
    public const int MsgModeDisplayIo     = MsgModeDisplayStart + 3; // 204
    public const int MsgModeStageTurn     = MsgModeDisplayStart + 4; // 205

    // Alarm severity
    public const int AlarmNone  = 0;
    public const int AlarmLight = 1;
    public const int AlarmHeavy = 2;
}

/// <summary>
/// DIO controller orchestrator implementation.
/// Manages all digital I/O operations for the ITOLED OC inspection system.
/// <para>Delphi origin: <c>TControlDio</c> in ControlDio_OC.pas (3744 lines)</para>
/// </summary>
public sealed class DioController : IDioController
{
    // =========================================================================
    // Dependencies (constructor-injected)
    // =========================================================================

    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _status;
    private readonly IPlcService _plcService;
    private readonly IDaeDioDriver _dioDriver;

    // =========================================================================
    // Private Fields (Delphi: TControlDio private section)
    // =========================================================================

    private readonly object _lock = new();
    private readonly int _msgType;
    private System.Threading.Timer? _cycleTimer;
    private bool _disposed;

    private bool _connected;
    private bool _doorOpen;
    private int _towerLampState;
    private uint _towerLampTick;
    private bool _ioThreadWork;
    private int _stageToFront;

    // =========================================================================
    // Public Properties
    // =========================================================================

    /// <inheritdoc />
    public bool Connected => _connected;

    /// <inheritdoc />
    public int[] DioAlarmData { get; } = new int[DioError.MaxAlarmDataSize + 1];

    /// <inheritdoc />
    public string LastNgMsg { get; private set; } = string.Empty;

    /// <inheritdoc />
    public LoadZoneStage LoadZoneStage { get; set; }

    /// <inheritdoc />
    public bool UseTowerLamp { get; set; } = true;

    /// <inheritdoc />
    public bool MelodyOn { get; set; } = true;

    // =========================================================================
    // Constructor / Destructor
    // Delphi: TControlDio.Create(hMain, nMsgType, nDeviceCnt)
    // =========================================================================

    public DioController(
        IMessageBus messageBus,
        ILogger logger,
        IConfigurationService config,
        ISystemStatusService status,
        IPlcService plcService,
        IDaeDioDriver dioDriver,
        int msgType = 0)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _status = status ?? throw new ArgumentNullException(nameof(status));
        _plcService = plcService ?? throw new ArgumentNullException(nameof(plcService));
        _dioDriver = dioDriver ?? throw new ArgumentNullException(nameof(dioDriver));

        _msgType = msgType;
        _connected = false;
        _doorOpen = false;
        _towerLampState = 0;
        _towerLampTick = (uint)Environment.TickCount;

        // Initialize alarm data
        for (int i = 0; i < DioAlarmData.Length; i++)
            DioAlarmData[i] = 0;

        // Configure DIO driver
        if (_config.SimulateInfo.UseDio)
        {
            _dioDriver.DeviceIp = _config.SimulateInfo.DioIp;
            _dioDriver.DevicePort = _config.SimulateInfo.DioPort;
        }
        else
        {
            _dioDriver.DeviceIp = DioConfig.DaeIoDeviceIp;
            _dioDriver.DevicePort = DioConfig.DaeIoDevicePort;
        }
        _dioDriver.PollingInterval = DioConfig.DaeIoDeviceInterval;
        _dioDriver.LogLevel = 0;

        // Subscribe to DIO driver events
        _dioDriver.OnConnect += OnDioConnect;
        _dioDriver.OnInputChanged += OnDioInputChanged;
        _dioDriver.OnOutputChanged += OnDioOutputChanged;
        _dioDriver.OnError += OnDioError;

        // Start the DIO driver
        _dioDriver.Start();

        // Start the cycle timer (500ms interval) - Delphi: tmrCycle
        _cycleTimer = new System.Threading.Timer(
            CycleTimerCallback, null, 500, 500);

        _doorOpen = false;
        _ioThreadWork = false;
        _stageToFront = 0;

        // Set initial tower lamp state for OC type
        if (IsOcType)
        {
            SetTowerLampState((int)LampState.Manual);
        }
    }

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        if (_cycleTimer != null)
        {
            _cycleTimer.Dispose();
            _cycleTimer = null;
        }

        _dioDriver.OnConnect -= OnDioConnect;
        _dioDriver.OnInputChanged -= OnDioInputChanged;
        _dioDriver.OnOutputChanged -= OnDioOutputChanged;
        _dioDriver.OnError -= OnDioError;
        _dioDriver.Dispose();
    }

    // =========================================================================
    // Helper: Inspector Type Check
    // =========================================================================

    private bool IsOcType => _config.SystemInfo.OcType == ChannelConstants.OcType;
    private bool IsPreOcType => _config.SystemInfo.OcType == ChannelConstants.PreOcType;

    // =========================================================================
    // Low-level I/O Helpers
    // Delphi: CheckDi, ReadInSig, ReadOutSig, WriteDioSig, ClearOutDioSig
    // =========================================================================

    /// <summary>
    /// Checks a digital input bit directly from hardware.
    /// Delphi: function TControlDio.CheckDi(nIdx): Boolean
    /// </summary>
    private bool CheckDi(int index)
    {
        int byteIdx = index / 8;
        int bitPos = index % 8;
        return (_dioDriver.GetInputByte(byteIdx) & (1 << bitPos)) > 0;
    }

    /// <inheritdoc />
    public bool ReadInSig(int signal)
    {
        if (_disposed) return false;
        if (signal > 95) return false;
        int byteIdx = signal / 8;
        int bitPos = signal % 8;
        return (_dioDriver.GetInputByte(byteIdx) & (1 << bitPos)) > 0;
    }

    /// <inheritdoc />
    public bool ReadOutSig(int signal)
    {
        if (_disposed) return false;
        if (signal > 95) return false;
        int byteIdx = signal / 8;
        int bitPos = signal % 8;
        return (_dioDriver.GetOutputFlushByte(byteIdx) & (1 << bitPos)) > 0;
    }

    /// <inheritdoc />
    public int WriteDioSig(int signal, bool isRemove = false)
    {
        // Allow tower lamp and reset LED signals even when door is open
        if (signal != DioOutput.ResetSwitchLed &&
            signal != DioOutput.TowerLampRed &&
            signal != DioOutput.TowerLampYellow &&
            signal != DioOutput.TowerLampGreen &&
            signal != DioOutput.Buzzer1)
        {
            if (_doorOpen) return 0;
        }

        int byteIdx = signal / 8;
        int bitPos = signal % 8;
        int value = isRemove ? 0 : 1;

        _dioDriver.WriteOutputBit(byteIdx, bitPos, value);
        DisplayIo();
        return 0;
    }

    /// <inheritdoc />
    public void ClearOutDioSig(int signal)
    {
        int byteIdx = signal / 8;
        int bitPos = signal % 8;
        _dioDriver.WriteOutputBit(byteIdx, bitPos, 0);
    }

    // =========================================================================
    // Messaging Helpers
    // Delphi: SendMsgMain, SendAlarm, SetAlarmMsg
    // =========================================================================

    /// <summary>
    /// Publishes a DIO control message to the message bus.
    /// Replaces Delphi's WM_COPYDATA SendMessage(m_hMain, ...).
    /// </summary>
    private void SendMsgMain(int msgMode, int param, int param2, string msg)
    {
        if (_disposed) return;

        _messageBus.Publish(new DioControlMessage
        {
            Channel = 1,
            Mode = msgMode,
            Param = param,
            Param2 = param2,
            Message = msg,
        });
    }

    /// <summary>
    /// Sends an alarm only if the state has changed.
    /// Delphi: procedure TControlDio.SendAlarm(nType, nIndex, nValue, sMsg)
    /// </summary>
    private void SendAlarm(int type, int index, int value, string msg = "")
    {
        // Only send if the alarm state actually changed
        if (_status.GetAlarmData(index) == (byte)value) return;

        if (type == DioMsgConstants.MsgModeSystemAlarm)
            SendMsgMain(DioMsgConstants.MsgModeSystemAlarm, index, value, msg);
        else
            SendMsgMain(DioMsgConstants.MsgModeDisplayAlarm, index, value, msg);
    }

    /// <summary>
    /// Sets alarm message in the alarm data bit-array and optionally sends display message.
    /// Delphi: procedure TControlDio.SetAlarmMsg(nIdx, bIsDisplayMessage)
    /// </summary>
    private void SetAlarmMsg(int index, bool isDisplayMessage = true)
    {
        if (index < 0)
        {
            if (isDisplayMessage)
                SendMsgMain(DioMsgConstants.MsgModeDisplayAlarm, index, 0, "");
        }
        else
        {
            int byteIdx = index / 8;
            int bitPos = index % 8;
            bool alreadySet = (DioAlarmData[byteIdx] & (0x01 << bitPos)) != 0;
            if (alreadySet) return; // Already raised

            DioAlarmData[byteIdx] = DioAlarmData[byteIdx] | (1 << bitPos);
            if (isDisplayMessage)
                SendMsgMain(DioMsgConstants.MsgModeDisplayAlarm, index, 0, "");
        }
    }

    // =========================================================================
    // CheckAlarm
    // Delphi: function TControlDio.CheckAlarm: Integer (lines 169-409)
    // =========================================================================

    private int CheckAlarm()
    {
        int ret = DioError.ListStart;

        if (!_dioDriver.Connected)
        {
            LastNgMsg = "Disconnected DIO Card....";
            SendMsgMain(DioMsgConstants.MsgModeSystemAlarm, DioError.DioCardDisconnected, 0, LastNgMsg);
            _connected = false;
            return DioError.DioCardDisconnected;
        }

        if (IsOcType)
        {
            // MC Monitoring
            int alarmNo = DioInput.McMonitoring;
            if (!CheckDi(alarmNo))
            {
                ret = alarmNo;
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1);
            }
            else
            {
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0);
            }

            // EMO Switch
            alarmNo = DioInput.EmoSwitch;
            if (CheckDi(alarmNo))
            {
                ret = alarmNo;
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1);
            }
            else
            {
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0);
            }

            // Door sensors
            alarmNo = DioInput.Ch12DoorLeftOpen;
            if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 2); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            alarmNo = DioInput.Ch12DoorRightOpen;
            if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 2); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            alarmNo = DioInput.Ch34DoorLeftOpen;
            if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 2); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            alarmNo = DioInput.Ch34DoorRightOpen;
            if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 2); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            // Pressure gauge
            alarmNo = DioInput.CylPressureGauge;
            if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            // Temperature
            alarmNo = DioInput.TemperatureAlarm;
            if (CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            // Fan signals (Fan1..Fan4)
            for (int f = 0; f < 4; f++)
            {
                alarmNo = DioInput.Fan1Exhaust + f;
                if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
                else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }
            }
        }
        else
        {
            // GIB/PreOC type alarm checks
            int alarmNo = DioInputGib.Ch12EmoSwitch;
            if (CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 2); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            alarmNo = DioInputGib.Ch34EmoSwitch;
            if (CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 2); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            // Fan signals
            for (int f = 0; f < 4; f++)
            {
                alarmNo = DioInput.Fan1Exhaust + f;
                if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
                else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }
            }

            // Light curtain + muting
            alarmNo = DioInputGib.Ch12LightCurtain;
            if (!CheckDi(DioInputGib.Ch12LightCurtain) && !CheckDi(DioInputGib.Ch12MutingLamp))
            {
                ret = alarmNo;
                SendAlarm(DioMsgConstants.MsgModeDisplayAlarm, alarmNo, 1);
            }

            alarmNo = DioInputGib.Ch34LightCurtain;
            if (!CheckDi(DioInputGib.Ch34LightCurtain) && !CheckDi(DioInputGib.Ch34MutingLamp))
            {
                ret = alarmNo;
                SendAlarm(DioMsgConstants.MsgModeDisplayAlarm, alarmNo, 1);
            }

            // MC Monitoring (GIB)
            alarmNo = DioInputGib.Ch12McMonitoring;
            if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            alarmNo = DioInputGib.Ch34McMonitoring;
            if (!CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            // Temperature (GIB)
            alarmNo = DioInputGib.TemperatureAlarm;
            if (CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }

            // Pressure (GIB)
            alarmNo = DioInputGib.CylPressureGauge;
            if (CheckDi(alarmNo)) { ret = alarmNo; SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 1); }
            else { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, alarmNo, 0); }
        }

        return ret;
    }

    // =========================================================================
    // ErrorCheck
    // Delphi: function TControlDio.ErrorCheck: Integer (lines 2285-2425)
    // =========================================================================

    private int ErrorCheck()
    {
        int ret = DioError.ListStart;

        if (!_dioDriver.Connected)
        {
            LastNgMsg = "Disconnected DIO Card....";
            SendMsgMain(DioMsgConstants.MsgModeSystemAlarm, DioError.DioCardDisconnected, 0, LastNgMsg);
            _connected = false;
            return DioError.DioCardDisconnected;
        }

        ResetError(1);

        // Fan checks
        if (!CheckDi(DioInput.Fan1Exhaust)) { ret = DioError.Fan1Out; SetAlarmMsg(ret, false); }
        if (!CheckDi(DioInput.Fan2Intake)) { ret = DioError.Fan1Out + 1; SetAlarmMsg(ret, false); }
        if (!CheckDi(DioInput.Fan3Exhaust)) { ret = DioError.Fan1Out + 2; SetAlarmMsg(ret, false); }
        if (!CheckDi(DioInput.Fan4Intake)) { ret = DioError.Fan1Out + 3; SetAlarmMsg(ret, false); }

        // Door open check
        bool doorOpen = false;
        if (CheckDi(DioInput.Ch12DoorLeftOpen)) doorOpen = true;
        if (CheckDi(DioInput.Ch12DoorRightOpen)) doorOpen = true;
        if (CheckDi(DioInput.Ch34DoorLeftOpen)) doorOpen = true;
        if (CheckDi(DioInput.Ch34DoorRightOpen)) doorOpen = true;
        if (doorOpen)
            SendMsgMain(DioMsgConstants.MsgModeDisplayAlarm, -2, 0, "Door Opened");

        // Pressure
        if (CheckDi(DioInput.CylPressureGauge)) { ret = DioError.MainAirPressure; SetAlarmMsg(ret, false); }
        // Temperature
        if (CheckDi(DioInput.TemperatureAlarm)) { ret = DioError.Temperature; SetAlarmMsg(ret, false); }

        if (ret != DioError.ListStart)
        {
            SetAlarmMsg(ret);
            ClearOutDioSig(DioOutput.ResetSwitchLed);
            return ret;
        }
        else
        {
            if (!CheckDi(DioInput.McMonitoring)) ret = DioError.McMonitor;
            if (ret != DioError.ListStart)
            {
                EnableCycleTimer(true);
                SetAlarmMsg(ret);
                return ret;
            }
        }

        EnableCycleTimer(false);
        ResetError(2);
        return 0;
    }

    private void EnableCycleTimer(bool enabled)
    {
        _cycleTimer?.Change(enabled ? 500 : Timeout.Infinite, enabled ? 500 : Timeout.Infinite);
    }

    // =========================================================================
    // BackgroundErrorCheck
    // Delphi: procedure TControlDio.BackgroundErrorCheck (lines 148-156)
    // =========================================================================

    /// <inheritdoc />
    public void BackgroundErrorCheck()
    {
        Task.Run(() => ErrorCheck());
    }

    // =========================================================================
    // CheckAllDoorOpen
    // Delphi: function TControlDio.CheckAllDoorOpen (lines 158-167)
    // =========================================================================

    /// <inheritdoc />
    public bool CheckAllDoorOpen()
    {
        if (!IsOcType) return false;
        return CheckDi(DioInput.Ch12DoorLeftOpen) &&
               CheckDi(DioInput.Ch12DoorRightOpen) &&
               CheckDi(DioInput.Ch34DoorLeftOpen) &&
               CheckDi(DioInput.Ch34DoorRightOpen);
    }

    // =========================================================================
    // LampOnOff
    // Delphi: function TControlDio.LampOnOff (lines 460-473)
    // =========================================================================

    /// <inheritdoc />
    public int LampOnOff(int group, bool isOnOff)
    {
        switch (group)
        {
            case ChannelConstants.ChTop:
                WriteDioSig(DioOutput.Ch12LampOff, isOnOff);
                if (IsOcType) WriteDioSig(DioOutput.Ch12BackDoorLampOn, isOnOff);
                break;
            case ChannelConstants.ChBottom:
                WriteDioSig(DioOutput.Ch34LampOff, isOnOff);
                if (IsOcType) WriteDioSig(DioOutput.Ch34BackDoorLampOn, isOnOff);
                break;
        }
        return 0;
    }

    // =========================================================================
    // CheckDIO_Start
    // Delphi: function TControlDio.CheckDIO_Start (lines 476-493)
    // =========================================================================

    /// <inheritdoc />
    public bool CheckDioStart(int channel)
    {
        for (int i = channel * 2; i <= channel * 2 + 1; i++)
        {
            // Check if channel script is in use (simplified - uses status service)
            if (ReadInSig(DioInputGib.Ch1PinblockOpenSensor + i * 8))
            {
                SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0,
                    $"CheckDIO_Start NG : {i}");
                return false;
            }
        }
        return true;
    }

    // =========================================================================
    // CheckOpenPinBlock
    // Delphi: function TControlDio.CheckOpenPinBlock (lines 496-506)
    // =========================================================================

    /// <inheritdoc />
    public int CheckOpenPinBlock(int channel)
    {
        return !ReadInSig(DioInputGib.Ch1PinblockOpenSensor + channel * 8) ? 1 : 0;
    }

    // =========================================================================
    // CheckPreOCPanelDetectCh
    // Delphi: function TControlDio.CheckPreOCPanelDetectCh (lines 508-528)
    // =========================================================================

    /// <inheritdoc />
    public int CheckPreOcPanelDetectChannel(int channel, int reverseMode = 0)
    {
        int result = ReadInSig(DioInputGib.Ch1CarrierSensor + channel * 8) ? 0 : 1;
        if (reverseMode == 1)
            result = result == 0 ? 1 : 0;
        return result;
    }

    // =========================================================================
    // CheckPreOcPanelDetectJig
    // Delphi: function TControlDio.CheckPreOcPanelDetectJig (lines 530-551)
    // =========================================================================

    /// <inheritdoc />
    public int CheckPreOcPanelDetectJig(int jig)
    {
        int result = 1;
        if (jig == 0) // TOP 1,2
        {
            if (ReadInSig(DioInputGib.Ch1CarrierSensor) || ReadInSig(DioInputGib.Ch2CarrierSensor))
                result = 0;
        }
        else if (jig == 1) // BOTTOM 3,4
        {
            if (ReadInSig(DioInputGib.Ch3CarrierSensor) || ReadInSig(DioInputGib.Ch4CarrierSensor))
                result = 0;
        }
        return result;
    }

    // =========================================================================
    // CheckPreOcUnloadStatus
    // Delphi: function TControlDio.CheckPreOcUnloadStatus (lines 553-577)
    // =========================================================================

    /// <inheritdoc />
    public int CheckPreOcUnloadStatus(int channel)
    {
        int result = 0;
        if (!ReadInSig(DioInputGib.Ch1PinblockOpenSensor + channel * 8))
        {
            result = 1;
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm,
                DioInputGib.Ch1PinblockOpenSensor + channel * 8, 1, "");
        }

        if (ReadInSig(DioInputGib.Ch1PressureGauge + channel * 8))
        {
            result = 1;
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm,
                DioInputGib.Ch1PressureGauge + channel * 8, 1, "");
        }
        return result;
    }

    // =========================================================================
    // LockCarrier
    // Delphi: function TControlDio.LockCarrier (lines 579-819)
    // =========================================================================

    /// <inheritdoc />
    public int LockCarrier(int channel, bool isMaintenanceMode)
    {
        const int waitingCount = 80; // 100ms * 80 = 8 seconds
        if (!IsOcType) return 2;

        switch (channel)
        {
            case ChannelConstants.ChTopGroup:
                return LockCarrierGroup(ChannelConstants.Ch1, ChannelConstants.Ch2,
                    DioOutput.Ch1CarrierUnlockSol, DioOutput.Ch2CarrierUnlockSol,
                    DioOutput.Ch1CarrierLockSol, DioOutput.Ch2CarrierLockSol,
                    "TOP_CH", waitingCount);

            case ChannelConstants.ChBottomGroup:
                return LockCarrierGroup(ChannelConstants.Ch3, ChannelConstants.Ch4,
                    DioOutput.Ch3CarrierUnlockSol, DioOutput.Ch4CarrierUnlockSol,
                    DioOutput.Ch3CarrierLockSol, DioOutput.Ch4CarrierLockSol,
                    "BOTTOM_CH", waitingCount);

            default:
                return LockCarrierSingle(channel, waitingCount);
        }
    }

    private int LockCarrierGroup(int chStart, int chEnd,
        int unlockSol1, int unlockSol2, int lockSol1, int lockSol2,
        string label, int waitingCount)
    {
        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"LockCarrier Start {label}");

        ClearOutDioSig(unlockSol1);
        ClearOutDioSig(unlockSol2);

        // Check if already locked
        if (AreAllCarrierLocked(chStart, chEnd))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"LockCarrier Finish {label} - Already");
            return 0;
        }

        // Engage lock solenoids
        WriteDioSig(lockSol1, false);
        WriteDioSig(lockSol2, false);

        if (!AreAllCarrierLocked(chStart, chEnd))
        {
            // Wait for lock confirmation
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (AreAllCarrierLocked(chStart, chEnd)) break;
            }
            Thread.Sleep(100);

            // Final verification with alarm
            for (int j = chStart; j <= chEnd; j++)
            {
                if (IsCarrierLocked(j)) continue;
                ReportCarrierLockFailure(j);
                return 2;
            }
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"LockCarrier Finish {label}");
        return 0;
    }

    private int LockCarrierSingle(int ch, int waitingCount)
    {
        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"LockCarrier Start Ch={ch}");
        ClearOutDioSig(DioOutput.Ch1CarrierUnlockSol + ch * 16);

        if (IsCarrierLocked(ch))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"LockCarrier Finish Ch={ch} - Already");
            return 0;
        }

        WriteDioSig(DioOutput.Ch1CarrierLockSol + ch * 16, false);

        if (!ReadInSig(DioInput.Ch1CarrierSensor + ch * 16) ||
            (!ReadInSig(DioInput.Ch1CarrierLock1 + ch * 16) &&
             !ReadInSig(DioInput.Ch1CarrierLock2 + ch * 16) &&
             !ReadInSig(DioInput.Ch1CarrierLock3 + ch * 16) &&
             !ReadInSig(DioInput.Ch1CarrierLock4 + ch * 16)))
        {
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (IsCarrierLocked(ch)) break;
            }
            Thread.Sleep(100);

            bool ok = true;
            if (!ReadInSig(DioInput.Ch1CarrierSensor + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierSensor + ch * 16, 1, ""); ok = false; }
            if (!ReadInSig(DioInput.Ch1CarrierLock1 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock1 + ch * 16, 1, ""); ok = false; }
            if (!ReadInSig(DioInput.Ch1CarrierLock2 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock2 + ch * 16, 1, ""); ok = false; }
            if (!ReadInSig(DioInput.Ch1CarrierLock3 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock3 + ch * 16, 1, ""); ok = false; }
            if (!ReadInSig(DioInput.Ch1CarrierLock4 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock4 + ch * 16, 1, ""); ok = false; }
            if (!ok) return 2;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"LockCarrier Finish Ch={ch}");
        return 0;
    }

    private bool IsCarrierLocked(int ch)
    {
        return ReadInSig(DioInput.Ch1CarrierSensor + ch * 16) &&
               ReadInSig(DioInput.Ch1CarrierLock1 + ch * 16) &&
               ReadInSig(DioInput.Ch1CarrierLock2 + ch * 16) &&
               ReadInSig(DioInput.Ch1CarrierLock3 + ch * 16) &&
               ReadInSig(DioInput.Ch1CarrierLock4 + ch * 16);
    }

    private bool AreAllCarrierLocked(int chStart, int chEnd)
    {
        for (int i = chStart; i <= chEnd; i++)
            if (!IsCarrierLocked(i)) return false;
        return true;
    }

    private void ReportCarrierLockFailure(int ch)
    {
        if (!ReadInSig(DioInput.Ch1CarrierSensor + ch * 16))
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierSensor + ch * 16, 1, "");
        else if (!ReadInSig(DioInput.Ch1CarrierLock1 + ch * 16))
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock1 + ch * 16, 1, "");
        else if (!ReadInSig(DioInput.Ch1CarrierLock2 + ch * 16))
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock2 + ch * 16, 1, "");
        else if (!ReadInSig(DioInput.Ch1CarrierLock3 + ch * 16))
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock3 + ch * 16, 1, "");
        else if (!ReadInSig(DioInput.Ch1CarrierLock4 + ch * 16))
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierLock4 + ch * 16, 1, "");
    }

    // =========================================================================
    // UnlockCarrier
    // Delphi: function TControlDio.UnLockCarrier (lines 941-1219)
    // =========================================================================

    /// <inheritdoc />
    public int UnlockCarrier(int channel, bool isMaintenanceMode)
    {
        if (_disposed) return 1;
        const int waitingCount = 80;
        if (!IsOcType) return 2;

        switch (channel)
        {
            case ChannelConstants.ChTopGroup:
                return UnlockCarrierGroup(ChannelConstants.Ch1, ChannelConstants.Ch2,
                    DioOutput.Ch1CarrierLockSol, DioOutput.Ch2CarrierLockSol,
                    DioOutput.Ch1CarrierUnlockSol, DioOutput.Ch2CarrierUnlockSol,
                    "TOP_CH", waitingCount, false);

            case ChannelConstants.ChBottomGroup:
                return UnlockCarrierGroup(ChannelConstants.Ch3, ChannelConstants.Ch4,
                    DioOutput.Ch3CarrierLockSol, DioOutput.Ch4CarrierLockSol,
                    DioOutput.Ch3CarrierUnlockSol, DioOutput.Ch4CarrierUnlockSol,
                    "BOTTOM_CH", waitingCount, false);

            case ChannelConstants.ChAllGroup:
                return UnlockCarrierAll(waitingCount);

            default:
                return UnlockCarrierSingle(channel, waitingCount);
        }
    }

    private bool IsCarrierUnlocked(int ch)
    {
        return ReadInSig(DioInput.Ch1CarrierUnlockSensor1 + ch * 16) &&
               ReadInSig(DioInput.Ch1CarrierUnlockSensor2 + ch * 16) &&
               ReadInSig(DioInput.Ch1CarrierUnlockSensor3 + ch * 16) &&
               ReadInSig(DioInput.Ch1CarrierUnlockSensor4 + ch * 16);
    }

    private bool AreAllCarrierUnlocked(int chStart, int chEnd)
    {
        for (int i = chStart; i <= chEnd; i++)
            if (!IsCarrierUnlocked(i)) return false;
        return true;
    }

    private int UnlockCarrierGroup(int chStart, int chEnd,
        int clearLockSol1, int clearLockSol2,
        int unlockSol1, int unlockSol2,
        string label, int waitingCount, bool useSystemAlarm)
    {
        int alarmType = useSystemAlarm
            ? DioMsgConstants.MsgModeSystemAlarm
            : DioMsgConstants.MsgModeDisplayAlarm;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"UnLockCarrier Start {label}");

        ClearOutDioSig(clearLockSol1);
        ClearOutDioSig(clearLockSol2);

        if (AreAllCarrierUnlocked(chStart, chEnd))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"UnLockCarrier Finish {label} - Already");
            return 0;
        }

        WriteDioSig(unlockSol1, false);
        WriteDioSig(unlockSol2, false);

        if (!AreAllCarrierUnlocked(chStart, chEnd))
        {
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (AreAllCarrierUnlocked(chStart, chEnd)) break;
            }
            Thread.Sleep(100);

            for (int j = chStart; j <= chEnd; j++)
            {
                if (IsCarrierUnlocked(j)) continue;
                ReportCarrierUnlockFailure(j, alarmType);
                return 2;
            }
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"UnLockCarrier Finish {label}");
        return 0;
    }

    private int UnlockCarrierAll(int waitingCount)
    {
        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "UnLockCarrier Start ALL_CH");

        ClearOutDioSig(DioOutput.Ch1CarrierLockSol);
        ClearOutDioSig(DioOutput.Ch2CarrierLockSol);
        ClearOutDioSig(DioOutput.Ch3CarrierLockSol);
        ClearOutDioSig(DioOutput.Ch4CarrierLockSol);

        if (AreAllCarrierUnlocked(ChannelConstants.Ch1, ChannelConstants.Ch4))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "UnLockCarrier Finish ALL_CH - Already");
            return 0;
        }

        WriteDioSig(DioOutput.Ch1CarrierUnlockSol, false);
        WriteDioSig(DioOutput.Ch2CarrierUnlockSol, false);
        WriteDioSig(DioOutput.Ch3CarrierUnlockSol, false);
        WriteDioSig(DioOutput.Ch4CarrierUnlockSol, false);

        if (!AreAllCarrierUnlocked(ChannelConstants.Ch1, ChannelConstants.Ch4))
        {
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (AreAllCarrierUnlocked(ChannelConstants.Ch1, ChannelConstants.Ch4)) break;
            }
            Thread.Sleep(100);

            bool ok = true;
            for (int j = ChannelConstants.Ch1; j <= ChannelConstants.Ch4; j++)
            {
                if (IsCarrierUnlocked(j)) continue;
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierSensor + j * 16, 1, "");
                ok = false;
            }
            if (!ok) return 2;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "UnLockCarrier Finish ALL_CH");
        return 0;
    }

    private int UnlockCarrierSingle(int ch, int waitingCount)
    {
        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"UnLockCarrier Start Ch={ch}");
        ClearOutDioSig(DioOutput.Ch1CarrierLockSol + ch * 16);

        if (IsCarrierUnlocked(ch))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"UnLockCarrier Finish Ch={ch} - Already");
            return 0;
        }

        WriteDioSig(DioOutput.Ch1CarrierUnlockSol + ch * 16, false);

        if (!IsCarrierUnlocked(ch))
        {
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (IsCarrierUnlocked(ch)) break;
            }
            Thread.Sleep(100);

            bool ok = true;
            if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor1 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierUnlockSensor1 + ch * 16, 1, ""); ok = false; }
            if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor2 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierUnlockSensor2 + ch * 16, 1, ""); ok = false; }
            if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor3 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierUnlockSensor3 + ch * 16, 1, ""); ok = false; }
            if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor4 + ch * 16))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1CarrierUnlockSensor4 + ch * 16, 1, ""); ok = false; }
            if (!ok) return 2;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"UnLockCarrier Finish Ch={ch}");
        return 0;
    }

    private void ReportCarrierUnlockFailure(int ch, int alarmType)
    {
        if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor1 + ch * 16))
            SendAlarm(alarmType, DioInput.Ch1CarrierUnlockSensor1 + ch * 16, 1, "");
        else if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor2 + ch * 16))
            SendAlarm(alarmType, DioInput.Ch1CarrierUnlockSensor2 + ch * 16, 1, "");
        else if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor3 + ch * 16))
            SendAlarm(alarmType, DioInput.Ch1CarrierUnlockSensor3 + ch * 16, 1, "");
        else if (!ReadInSig(DioInput.Ch1CarrierUnlockSensor4 + ch * 16))
            SendAlarm(alarmType, DioInput.Ch1CarrierUnlockSensor4 + ch * 16, 1, "");
    }

    // =========================================================================
    // PowerResetPG / PowerResetPG_CH
    // Delphi: lines 1222-1272
    // =========================================================================

    /// <inheritdoc />
    public int PowerResetPg()
    {
        int waitingCount = _config.SystemInfo.PgResetDelayTime * 10;
        if (!IsOcType && waitingCount != 0) return 0;

        for (int ch = 0; ch <= ChannelConstants.MaxCh; ch++)
        {
            ClearOutDioSig(DioOutput.Ch1PgPowerOff + ch);
            Thread.Sleep(1000);
            WriteDioSig(DioOutput.Ch1PgPowerOff + ch, false);
            Thread.Sleep(1000);
            WriteDioSig(DioOutput.Ch1PgPowerOff + ch, true);
        }

        for (int i = 0; i <= waitingCount; i++)
            Thread.Sleep(100);

        return 0;
    }

    /// <inheritdoc />
    public int PowerResetPgChannel(int channel)
    {
        int waitingCount = _config.SystemInfo.PgResetDelayTime * 10;
        if (!IsOcType && waitingCount != 0) return 0;

        ClearOutDioSig(DioOutput.Ch1PgPowerOff + channel);
        Thread.Sleep(1000);
        WriteDioSig(DioOutput.Ch1PgPowerOff + channel, false);
        Thread.Sleep(1000);
        WriteDioSig(DioOutput.Ch1PgPowerOff + channel, true);

        for (int i = 0; i <= waitingCount; i++)
            Thread.Sleep(100);

        return 0;
    }

    // =========================================================================
    // ProbeBackward
    // Delphi: function TControlDio.ProbeBackward (lines 1274-1361)
    // =========================================================================

    /// <inheritdoc />
    public int ProbeBackward(int channel)
    {
        if (!IsOcType) return 2;
        const int waitingCount = 80;
        int ch = channel;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"MoveProbe backward Start - CH = {ch}");
        ClearOutDioSig(DioOutput.Ch1ProbeForwardSol + ch * 16);
        ClearOutDioSig(DioOutput.Ch1ProbeDownSol + ch * 16);

        // Check if already in backward position
        if (ReadInSig(DioInput.Ch1ProbeBackwardSensor + ch * 16) ||
            !ReadInSig(DioInput.Ch1ProbeForwardSensor + ch * 16) ||
            !ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16) ||
            ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16))
        {
            // Not in the expected "forward+down" state, handle cases
        }
        else
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"MoveProbe backward Finish CH = {ch} - Already");
            return 0;
        }

        // If probe is not backward yet
        if (!ReadInSig(DioInput.Ch1ProbeBackwardSensor + ch * 16))
        {
            if (!ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16))
            {
                // Already up, proceed
                SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"MoveProbe backward Finish CH = {ch}");
                return 0;
            }
            else
            {
                // Move up first
                WriteDioSig(DioOutput.Ch1ProbeUpSol + ch * 16, false);
                for (int i = 0; i <= waitingCount; i++)
                {
                    Thread.Sleep(100);
                    if (!ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16) &&
                        ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16)) break;
                }
                if (ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16) ||
                    !ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16))
                {
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1ProbeUpSensor + ch * 16, 1, "");
                    return 1;
                }
            }
        }
        else
        {
            // Probe is backward - need to move up if needed
            if (ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16))
            {
                WriteDioSig(DioOutput.Ch1ProbeUpSol + ch * 16, false);
                for (int i = 0; i <= waitingCount; i++)
                {
                    Thread.Sleep(100);
                    if (!ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16) &&
                        ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16)) break;
                }
                if (ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16) ||
                    !ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16))
                {
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1ProbeUpSensor + ch * 16, 1, "");
                    return 1;
                }
            }

            // Move backward
            WriteDioSig(DioOutput.Ch1ProbeBackwardSol + ch * 16, false);
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInput.Ch1ProbeBackwardSensor + ch * 16) &&
                    ReadInSig(DioInput.Ch1ProbeForwardSensor + ch * 16)) break;
            }
            if (ReadInSig(DioInput.Ch1ProbeBackwardSensor + ch * 16) ||
                !ReadInSig(DioInput.Ch1ProbeForwardSensor + ch * 16))
            {
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1ProbeBackwardSensor + ch * 16, 1, "");
                return 1;
            }
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"MoveProbe backward Finish CH = {ch}");
        return 0;
    }

    // =========================================================================
    // ProbeForward
    // Delphi: function TControlDio.ProbeForward (lines 1365-1469)
    // =========================================================================

    /// <inheritdoc />
    public int ProbeForward(int channel)
    {
        if (!IsOcType) return 2;
        const int waitingCount = 80;
        int ch = channel;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"MoveProbe forward Start - CH = {ch}");
        ClearOutDioSig(DioOutput.Ch1ProbeBackwardSol + ch * 16);
        ClearOutDioSig(DioOutput.Ch1ProbeUpSol + ch * 16);

        // Check if already in forward+up position
        bool alreadyForward =
            !(ReadInSig(DioInput.Ch1ProbeForwardSensor + ch * 16) ||
              !ReadInSig(DioInput.Ch1ProbeBackwardSensor + ch * 16) ||
              ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16) ||
              !ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16));

        if (alreadyForward)
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"MoveProbe forward Finish CH = {ch} - Already");
            return 0;
        }

        if (!ReadInSig(DioInput.Ch1ProbeForwardSensor + ch * 16))
        {
            // Probe not forward yet
            if (!ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16))
            {
                return 0; // Already down and not forward - skip
            }
            else
            {
                // Move down first
                WriteDioSig(DioOutput.Ch1ProbeDownSol + ch * 16, false);
                for (int i = 0; i <= waitingCount; i++)
                {
                    Thread.Sleep(100);
                    if (!ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16) &&
                        ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16)) break;
                }
                if (ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16) ||
                    !ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16))
                {
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1ProbeDownSensor + ch * 16, 1, "");
                    return 1;
                }
            }
        }
        else
        {
            // Probe is forward - retract up if needed, then forward, then down
            if (ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16))
            {
                WriteDioSig(DioOutput.Ch1ProbeUpSol + ch * 16, false);
                for (int i = 0; i <= waitingCount; i++)
                {
                    Thread.Sleep(100);
                    if (!ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16) &&
                        ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16)) break;
                }
                if (ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16) ||
                    !ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16))
                {
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1ProbeUpSensor + ch * 16, 1, "");
                    return 1;
                }
            }

            // Move forward
            WriteDioSig(DioOutput.Ch1ProbeForwardSol + ch * 16, false);
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInput.Ch1ProbeForwardSensor + ch * 16) &&
                    ReadInSig(DioInput.Ch1ProbeBackwardSensor + ch * 16)) break;
            }
            if (ReadInSig(DioInput.Ch1ProbeForwardSensor + ch * 16) ||
                !ReadInSig(DioInput.Ch1ProbeBackwardSensor + ch * 16))
            {
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1ProbeForwardSensor + ch * 16, 1, "");
                return 1;
            }

            // Move down
            WriteDioSig(DioOutput.Ch1ProbeDownSol + ch * 16, false);
            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16) &&
                    ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16)) break;
            }
            if (ReadInSig(DioInput.Ch1ProbeDownSensor + ch * 16) ||
                !ReadInSig(DioInput.Ch1ProbeUpSensor + ch * 16))
            {
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInput.Ch1ProbeDownSensor + ch * 16, 1, "");
                return 1;
            }
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"MoveProbe forward Finish CH = {ch}");
        return 0;
    }

    // =========================================================================
    // LockPinBlock
    // Delphi: function TControlDio.LockPinBlock (lines 822-861)
    // =========================================================================

    /// <inheritdoc />
    public int LockPinBlock(int channel)
    {
        if (!IsPreOcType) return 2;
        const int waitingCount = 50;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"lock PinBlock Start - CH = {channel + 1}");

        if (!ReadInSig(DioInputGib.Ch1PinblockUnlockOfSensor + channel * 8))
        {
            // Not locked yet
        }
        else
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"lock PinBlock Finish CH = {channel + 1} - Already");
            return 0;
        }

        WriteDioSig(DioOutputGib.Ch1PinblockUnlockSol + channel * 8, false);

        for (int i = 0; i <= waitingCount; i++)
        {
            Thread.Sleep(100);
            if (ReadInSig(DioInputGib.Ch1PinblockUnlockOfSensor + channel * 8)) break;
        }
        if (!ReadInSig(DioInputGib.Ch1PinblockUnlockOfSensor + channel * 8))
        {
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch1PinblockUnlockOfSensor + channel * 8, 1, "");
            return 1;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"lock PinBlock Finish CH = {channel + 1}");
        return 0;
    }

    // =========================================================================
    // UnlockPinBlock
    // Delphi: function TControlDio.UnlockPinBlock (lines 2154-2196)
    // =========================================================================

    /// <inheritdoc />
    public int UnlockPinBlock(int channel)
    {
        if (!IsPreOcType) return 2;
        // Skip if auto restart mode is active
        // Delphi: if Common.AutoReStart then Exit(0)
        const int waitingCount = 80;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Unlock PinBlock Start - CH = {channel + 1}");
        ClearOutDioSig(DioOutputGib.Ch1VacuumSol + channel * 8);

        if (ReadInSig(DioInputGib.Ch1PinblockUnlockOnSensor + channel * 8))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Unlock PinBlock Finish CH = {channel + 1} - Already");
            return 0;
        }

        WriteDioSig(DioOutputGib.Ch1PinblockUnlockSol + channel * 8, true);

        for (int i = 0; i <= waitingCount; i++)
        {
            Thread.Sleep(100);
            if (ReadInSig(DioInputGib.Ch1PinblockUnlockOnSensor + channel * 8)) break;
        }
        if (!ReadInSig(DioInputGib.Ch1PinblockUnlockOnSensor + channel * 8))
        {
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch1PinblockUnlockOnSensor + channel * 8, 1, "");
            return 1;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Unlock PinBlock Finish CH = {channel + 1}");
        return 0;
    }

    // =========================================================================
    // CLOSE_Dn_PinBlock
    // Delphi: function TControlDio.CLOSE_Dn_PinBlock (lines 863-901)
    // =========================================================================

    /// <inheritdoc />
    public int CloseDnPinBlock(int channel)
    {
        if (!IsPreOcType) return 2;
        const int waitingCount = 50;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"PIN BLOCK CLOSE Prevention Down Start - CH = {channel + 1}");

        if (ReadInSig(DioInputGib.Ch1PinblockCloseDnSensor + channel * 8))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"PIN BLOCK CLOSE Prevention Down Finish CH = {channel + 1} - Already");
            return 0;
        }

        WriteDioSig(DioOutputGib.Ch1PinblockCloseSol + channel * 8, true);

        for (int i = 0; i <= waitingCount; i++)
        {
            Thread.Sleep(100);
            if (ReadInSig(DioInputGib.Ch1PinblockCloseDnSensor + channel * 8)) break;
        }
        if (!ReadInSig(DioInputGib.Ch1PinblockCloseDnSensor + channel * 8))
        {
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch1PinblockCloseDnSensor + channel * 8, 1, "");
            return 1;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"PIN BLOCK CLOSE Prevention Down Finish CH = {channel + 1}");
        return 0;
    }

    // =========================================================================
    // CLOSE_Up_PinBlock
    // Delphi: function TControlDio.CLOSE_up_PinBlock (lines 903-938)
    // =========================================================================

    /// <inheritdoc />
    public int CloseUpPinBlock(int channel)
    {
        if (!IsPreOcType) return 2;
        const int waitingCount = 50;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"PIN BLOCK CLOSE Prevention Up Start - CH = {channel + 1}");

        if (ReadInSig(DioInputGib.Ch1PinblockCloseUpSensor + channel * 8))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"PIN BLOCK CLOSE Prevention Up Finish CH = {channel + 1} - Already");
            return 0;
        }

        WriteDioSig(DioOutputGib.Ch1PinblockCloseSol + channel * 8, false);

        for (int i = 0; i <= waitingCount; i++)
        {
            Thread.Sleep(100);
            if (ReadInSig(DioInputGib.Ch1PinblockCloseUpSensor + channel * 8)) break;
        }
        if (!ReadInSig(DioInputGib.Ch1PinblockCloseUpSensor + channel * 8))
        {
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch1PinblockCloseUpSensor + channel * 8, 1, "");
            return 1;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"PIN BLOCK CLOSE Prevention UP Finish CH = {channel + 1}");
        return 0;
    }

    // =========================================================================
    // VacuumON / VacuumOFF
    // Delphi: lines 2198-2283
    // =========================================================================

    /// <inheritdoc />
    public int VacuumOff(int channel)
    {
        if (!IsPreOcType) return 2;
        const int waitingCount = 50;

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Vaccum OFF Start - CH = {channel}");

        if (!ReadInSig(DioInputGib.Ch1PressureGauge + channel * 8))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Vaccum OFF Finish CH = {channel} - Already");
            return 0;
        }

        WriteDioSig(DioOutputGib.Ch1VacuumSol + channel * 8, true);

        for (int i = 0; i <= waitingCount; i++)
        {
            Thread.Sleep(100);
            if (!ReadInSig(DioInputGib.Ch1PressureGauge + channel * 8)) break;
        }
        if (ReadInSig(DioInputGib.Ch1PressureGauge + channel * 8))
        {
            SendAlarm(DioMsgConstants.MsgModeDisplayAlarm, DioInputGib.Ch1PressureGauge + channel * 8, 1, "");
            return 1;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Vaccum OFF Finish CH = {channel}");
        return 0;
    }

    /// <inheritdoc />
    public int VacuumOn(int channel)
    {
        if (!IsPreOcType) return 2;
        const int waitingCount = 50;

        // Check carrier presence first
        if (!ReadInSig(DioInputGib.Ch1CarrierSensor + channel * 8))
        {
            SendAlarm(DioMsgConstants.MsgModeDisplayAlarm, DioInputGib.Ch1CarrierSensor + channel * 8, 1, "");
            return 1;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Vaccum ON Start - CH = {channel}");

        if (ReadInSig(DioInputGib.Ch1PressureGauge + channel * 8))
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Vaccum ON Finish CH = {channel} - Already");
            return 0;
        }

        WriteDioSig(DioOutputGib.Ch1VacuumSol + channel * 8, false);

        for (int i = 0; i <= waitingCount; i++)
        {
            Thread.Sleep(100);
            if (ReadInSig(DioInputGib.Ch1PressureGauge + channel * 8)) break;
        }
        if (!ReadInSig(DioInputGib.Ch1PressureGauge + channel * 8))
        {
            SendAlarm(DioMsgConstants.MsgModeDisplayAlarm, DioInputGib.Ch1PressureGauge + channel * 8, 1, "");
            return 1;
        }

        SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Vaccum ON Finish CH = {channel}");
        return 0;
    }

    // =========================================================================
    // IsDetected
    // Delphi: function TControlDio.IsDetected (lines 2427-2475)
    // =========================================================================

    /// <inheritdoc />
    public bool IsDetected(int channel)
    {
        if (_config.PlcInfo.InlineGib)
        {
            if (IsOcType)
                return ReadInSig(DioInput.Ch1CarrierSensor + channel * 16);
            else
                return ReadInSig(DioInputGib.Ch1CarrierSensor + channel * 8);
        }
        else
        {
            if (IsOcType)
            {
                if (channel == 0)
                    return ReadInSig(DioInput.Ch1CarrierSensor) || ReadInSig(DioInput.Ch1CarrierSensor + 16);
                else
                    return ReadInSig(DioInput.Ch3CarrierSensor) || ReadInSig(DioInput.Ch3CarrierSensor + 16);
            }
            else
            {
                if (channel == 0)
                    return ReadInSig(DioInputGib.Ch1CarrierSensor) || ReadInSig(DioInputGib.Ch1CarrierSensor + 8);
                else
                    return ReadInSig(DioInputGib.Ch3CarrierSensor) || ReadInSig(DioInputGib.Ch3CarrierSensor + 8);
            }
        }
    }

    // =========================================================================
    // IsPreOCInterlockPROBE / PROBE_CH / SHUTTER
    // Delphi: lines 2478-2533
    // =========================================================================

    /// <inheritdoc />
    public int IsPreOcInterlockProbe(int channel)
    {
        try
        {
            if (!_connected) return 0;
            if (IsOcType) return 0;

            if (!ReadInSig(DioInputGib.Ch12ProbeUpSensor + channel * 4) &&
                !ReadInSig(DioInputGib.Ch1TiltingSensor + channel * 16) &&
                !ReadInSig(DioInputGib.Ch1TiltingSensor + channel * 16 + 8))
            {
                return 1;
            }
            return 0;
        }
        catch { return 0; }
    }

    /// <inheritdoc />
    public int IsPreOcInterlockProbeChannel(int channel)
    {
        try
        {
            if (!_connected) return 0;
            if (IsOcType) return 0;

            if (!ReadInSig(DioInputGib.Ch12ProbeUpSensor + (channel / 2) * 4) &&
                !ReadInSig(DioInputGib.Ch1TiltingSensor + channel * 8))
            {
                return 1;
            }
            return 0;
        }
        catch { return 0; }
    }

    /// <inheritdoc />
    public int IsPreOcInterlockShutter(int channel)
    {
        try
        {
            if (!_connected) return 0;
            if (IsOcType) return 0;

            if (!ReadInSig(DioInputGib.Ch12ShutterUpSensor + channel * 4) &&
                ReadInSig(DioInputGib.Ch12LightCurtain + channel))
            {
                return 1;
            }
            return 0;
        }
        catch { return 0; }
    }

    // =========================================================================
    // MovingAll
    // Delphi: function TControlDio.MovingAll (lines 2537-2681)
    // =========================================================================

    /// <inheritdoc />
    public int MovingAll(int group, bool isUp)
    {
        if (!IsPreOcType) return 2;
        if (!CheckDi(DioInputGib.Ch12McMonitoring + group)) return 2;

        string sCh = group == ChannelConstants.ChTop ? " CH 1,2 " : "CH 3,4 ";
        const int waitingCount = 100;
        bool stateProbe = false, stateShutter = false;

        if (isUp)
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe and Shutter UP Start {sCh}");

            if (ReadInSig(DioInputGib.Ch12RobotSensor + group))
            {
                SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Sensing ROBOT_SENSOR {sCh}");
                return 3;
            }

            ClearOutDioSig(DioOutputGib.Ch12ShutterDnSol + group * 4);
            ClearOutDioSig(DioOutputGib.Ch12ProbeDnSol + group * 4);

            if (!ReadInSig(DioInputGib.Ch12ShutterUpSensor + group * 4))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP Finish {sCh}- Already"); stateShutter = true; }
            if (!ReadInSig(DioInputGib.Ch12ProbeUpSensor + group * 4))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe UP Finish {sCh} - Already"); stateProbe = true; }

            if (stateShutter && stateProbe) return 0;

            WriteDioSig(DioOutputGib.Ch12ShutterUpSol + group * 4);
            WriteDioSig(DioOutputGib.Ch12ProbeUpSol + group * 4);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ProbeUpSensor + group * 4)) stateProbe = true;
                if (!ReadInSig(DioInputGib.Ch12ShutterUpSensor + group * 4)) stateShutter = true;
                if (stateShutter && stateProbe) break;
            }

            if (ReadInSig(DioInputGib.Ch12ProbeUpSensor + group * 4))
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ProbeUpSensor + group * 4, 1, "");
            if (ReadInSig(DioInputGib.Ch12ShutterUpSensor + group * 4))
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ShutterUpSensor + group * 4, 1, "");

            if (stateShutter && stateProbe)
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe and Shutter UP Finish {sCh}"); }
            else
            { return 2; }
        }
        else
        {
            if (ReadInSig(DioInputGib.Ch12RobotSensor + group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Sensing ROBOT_SENSOR {sCh}"); return 3; }
            if (_plcService.IsBusyRobot(group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Robot Busy {sCh}"); return 3; }
            if (ReadInSig(DioInputGib.Ch1TiltingSensor + 16 * group) || ReadInSig(DioInputGib.Ch2TiltingSensor + 16 * group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingProbe - Sensing TILTING_SENSOR {sCh}"); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe and Shutter DN Start {sCh}");
            ClearOutDioSig(DioOutputGib.Ch12ProbeUpSol + group * 4);
            ClearOutDioSig(DioOutputGib.Ch12ShutterUpSol + group * 4);

            if (!ReadInSig(DioInputGib.Ch12ProbeDnSensor + group * 4))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe DN Finish {sCh} - Already"); stateProbe = true; }
            if (!ReadInSig(DioInputGib.Ch12ShutterDnSensor + group * 4))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter DN Finish {sCh} - Already"); stateShutter = true; }

            if (stateShutter && stateProbe) return 0;

            if (_config.PlcInfo.InlineGib)
            { _plcService.ClearRobotRequest(group * 2); _plcService.ClearRobotRequest(group * 2 + 1); }
            else
            { _plcService.ClearRobotRequest(group); }

            WriteDioSig(DioOutputGib.Ch12ProbeDnSol + group * 4);
            WriteDioSig(DioOutputGib.Ch12ShutterDnSol + group * 4);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ProbeDnSensor + group * 4)) stateProbe = true;
                if (!ReadInSig(DioInputGib.Ch12ShutterDnSensor + group * 4)) stateShutter = true;
                if (stateShutter && stateProbe) break;
            }

            if (ReadInSig(DioInputGib.Ch12ProbeDnSensor + group * 4))
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ProbeDnSensor + group * 4, 1, "");
            if (ReadInSig(DioInputGib.Ch12ShutterDnSensor + group * 4))
                SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ShutterDnSensor + group * 4, 1, "");

            if (stateShutter && stateProbe)
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe and Shutter DN Finish {sCh}"); }
            else { return 2; }
        }

        return 0;
    }

    // =========================================================================
    // MovingProbe
    // Delphi: function TControlDio.MovingProbe (lines 2683-2771)
    // =========================================================================

    /// <inheritdoc />
    public int MovingProbe(int group, bool isUp)
    {
        if (!IsPreOcType) return 2;
        if (!CheckDi(DioInputGib.Ch12McMonitoring + group)) return 2;

        string sCh = group == ChannelConstants.ChTop ? " CH 1,2 " : "CH 3,4 ";
        const int waitingCount = 100;

        if (isUp)
        {
            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe UP Start {sCh}");
            ClearOutDioSig(DioOutputGib.Ch12ProbeDnSol + group * 4);

            if (!ReadInSig(DioInputGib.Ch12ProbeUpSensor + group * 4))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe UP Finish {sCh} - Already"); return 0; }

            WriteDioSig(DioOutputGib.Ch12ProbeUpSol + group * 4);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ProbeUpSensor + group * 4)) break;
            }

            if (ReadInSig(DioInputGib.Ch12ProbeUpSensor + group * 4))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ProbeUpSensor + group * 4, 1, ""); return 2; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe UP Finish {sCh}");
        }
        else
        {
            if (ReadInSig(DioInputGib.Ch12RobotSensor + group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingProbe - Sensing ROBOT_SENSOR {sCh}"); return 3; }
            if (ReadInSig(DioInputGib.Ch1TiltingSensor + 16 * group) || ReadInSig(DioInputGib.Ch2TiltingSensor + 16 * group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingProbe - Sensing TILTING_SENSOR {sCh}"); return 3; }
            if (_plcService.IsBusyRobot(group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingProbe - Robot Busy {sCh}"); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe DN Start {sCh}");
            ClearOutDioSig(DioOutputGib.Ch12ProbeUpSol + group * 4);

            if (!ReadInSig(DioInputGib.Ch12ProbeDnSensor + group * 4))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe DN Finish {sCh} - Already"); return 0; }

            if (_config.PlcInfo.InlineGib)
            { _plcService.ClearRobotRequest(group * 2); _plcService.ClearRobotRequest(group * 2 + 1); }
            else
            { _plcService.ClearRobotRequest(group); }

            WriteDioSig(DioOutputGib.Ch12ProbeDnSol + group * 4);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ProbeDnSensor + group * 4)) break;
            }

            if (ReadInSig(DioInputGib.Ch12ProbeDnSensor + group * 4))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ProbeDnSensor + group * 4, 1, ""); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Probe DN Finish {sCh}");
        }

        return 0;
    }

    // =========================================================================
    // MovingShutter
    // Delphi: function TControlDio.MovingShutter (lines 2773-3071)
    // This is the largest single method - handles CH_TOP, CH_BOTTOM, CH_ALL
    // =========================================================================

    /// <inheritdoc />
    public int MovingShutter(int group, bool isUp)
    {
        if (!IsPreOcType) return 2;

        if (group == ChannelConstants.ChAll)
        {
            if (!CheckDi(DioInputGib.Ch12McMonitoring) && !CheckDi(DioInputGib.Ch34McMonitoring)) return 2;
        }
        else
        {
            if (!CheckDi(DioInputGib.Ch12McMonitoring + group)) return 2;
        }

        const int waitingCount = 100;

        switch (group)
        {
            case ChannelConstants.ChTop:
                return MovingShutterTop(isUp, waitingCount);
            case ChannelConstants.ChBottom:
                return MovingShutterBottom(isUp, waitingCount);
            case ChannelConstants.ChAll:
                return MovingShutterAll(isUp, waitingCount);
            default:
                return 2;
        }
    }

    private int MovingShutterTop(bool isUp, int waitingCount)
    {
        const string sCh = "CH 1,2";
        int group = ChannelConstants.ChTop;

        if (isUp)
        {
            if (ReadInSig(DioInputGib.Ch12RobotSensor + group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Sensing ROBOT_SENSOR {sCh}"); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP Start {sCh}");
            ClearOutDioSig(DioOutputGib.Ch12ShutterDnSol);

            if (!ReadInSig(DioInputGib.Ch12ShutterUpSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP Finish {sCh}- Already"); return 0; }

            WriteDioSig(DioOutputGib.Ch12ShutterUpSol, false);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ShutterUpSensor))
                { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP OK. {sCh} Step={i}"); break; }
            }

            if (ReadInSig(DioInputGib.Ch12ShutterUpSensor))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ShutterUpSensor, 1, ""); return 2; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP Finish {sCh}");
        }
        else
        {
            // Wait up to 3s for robot to clear
            for (int i = 0; i <= 30; i++)
            {
                Thread.Sleep(100);
                if (ReadInSig(DioInputGib.Ch12RobotSensor + group)) continue;
                if (!_plcService.IsBitOnRobot(0x0f + group * 0x20))
                    if (!_config.PlcInfo.InlineGib) continue;
                if (_plcService.IsBusyRobot(group)) continue;
                break;
            }

            if (ReadInSig(DioInputGib.Ch12RobotSensor + group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Sensing ROBOT_SENSOR {sCh}"); return 3; }
            if (!_plcService.IsBitOnRobot(0x0f + group * 0x20))
                if (!_config.PlcInfo.InlineGib)
                { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Door Open {sCh}"); return 3; }
            if (_plcService.IsBusyRobot(group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Robot Busy {sCh}"); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter DN Start {sCh}");
            ClearOutDioSig(DioOutputGib.Ch12ShutterUpSol);

            if (!ReadInSig(DioInputGib.Ch12ShutterDnSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter DN Finish {sCh} - Already"); return 0; }

            if (_config.PlcInfo.InlineGib)
            { _plcService.ClearRobotRequest(group * 2); _plcService.ClearRobotRequest(group * 2 + 1); }
            else
            { _plcService.ClearRobotRequest(group); }

            WriteDioSig(DioOutputGib.Ch12ShutterDnSol, false);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ShutterDnSensor)) break;
            }

            if (ReadInSig(DioInputGib.Ch12ShutterDnSensor))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ShutterDnSensor, 1, ""); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter DN Finish {sCh}");
        }
        return 0;
    }

    private int MovingShutterBottom(bool isUp, int waitingCount)
    {
        const string sCh = "CH 3,4";
        int group = ChannelConstants.ChBottom;

        if (isUp)
        {
            if (ReadInSig(DioInputGib.Ch34RobotSensor + group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Sensing ROBOT_SENSOR {sCh}"); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP Start {sCh}");
            ClearOutDioSig(DioOutputGib.Ch34ShutterDnSol);

            if (!ReadInSig(DioInputGib.Ch34ShutterUpSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP Finish {sCh} - Already"); return 0; }

            WriteDioSig(DioOutputGib.Ch34ShutterUpSol, false);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch34ShutterUpSensor)) break;
            }

            if (ReadInSig(DioInputGib.Ch34ShutterUpSensor))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ShutterUpSensor, 1, ""); return 2; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter UP Finish {sCh}");
        }
        else
        {
            if (_config.PlcInfo.InlineGib)
            { _plcService.ClearRobotRequest(group * 2); _plcService.ClearRobotRequest(group * 2 + 1); }
            else
            { _plcService.ClearRobotRequest(group); }

            for (int i = 0; i <= 30; i++)
            {
                Thread.Sleep(100);
                if (ReadInSig(DioInputGib.Ch12RobotSensor + group)) continue;
                if (!_plcService.IsBitOnRobot(0x0f + group * 0x20))
                    if (!_config.PlcInfo.InlineGib) continue;
                if (_plcService.IsBusyRobot(group)) continue;
                break;
            }

            if (ReadInSig(DioInputGib.Ch34RobotSensor + group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Sensing ROBOT_SENSOR {sCh}"); return 3; }
            if (_plcService.IsBusyRobot(group))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Robot Busy {sCh}"); return 3; }
            if (!_plcService.IsBitOnRobot(0x0f + group * 0x20))
                if (!_config.PlcInfo.InlineGib)
                { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, $"Do not MovingShutter - Door Open {sCh}"); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter DN Start {sCh}");
            ClearOutDioSig(DioOutputGib.Ch34ShutterUpSol);

            if (!ReadInSig(DioInputGib.Ch34ShutterDnSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter DN Finish {sCh} - Already"); return 0; }

            WriteDioSig(DioOutputGib.Ch34ShutterDnSol, false);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch34ShutterDnSensor)) break;
            }

            if (ReadInSig(DioInputGib.Ch34ShutterDnSensor))
            { SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch34ShutterDnSensor, 1, ""); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, $"Shutter DN Finish {sCh}");
        }
        return 0;
    }

    private int MovingShutterAll(bool isUp, int waitingCount)
    {
        if (isUp)
        {
            if (ReadInSig(DioInputGib.Ch12RobotSensor) || ReadInSig(DioInputGib.Ch34RobotSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, "Do not MovingShutter - Sensing ROBOT_SENSOR"); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "Shutter UP Start CH ALL");
            ClearOutDioSig(DioOutputGib.Ch12ShutterDnSol);
            ClearOutDioSig(DioOutputGib.Ch34ShutterDnSol);

            if (!ReadInSig(DioInputGib.Ch12ShutterUpSensor) && !ReadInSig(DioInputGib.Ch34ShutterUpSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "Shutter UP Finish CH ALL- Already"); return 0; }

            WriteDioSig(DioOutputGib.Ch12ShutterUpSol, false);
            WriteDioSig(DioOutputGib.Ch34ShutterUpSol, false);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ShutterUpSensor) && !ReadInSig(DioInputGib.Ch34ShutterUpSensor)) break;
            }

            if (ReadInSig(DioInputGib.Ch12ShutterUpSensor) || ReadInSig(DioInputGib.Ch34ShutterUpSensor))
            {
                if (ReadInSig(DioInputGib.Ch12ShutterUpSensor))
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ShutterUpSensor, 1, "");
                if (ReadInSig(DioInputGib.Ch34ShutterUpSensor))
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch34ShutterUpSensor, 1, "");
                return 2;
            }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "Shutter UP Finish CH ALL ");
        }
        else
        {
            if (ReadInSig(DioInputGib.Ch12RobotSensor) || ReadInSig(DioInputGib.Ch34RobotSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, "Do not MovingShutter - Sensing ROBOT_SENSOR "); return 3; }
            if (!_plcService.IsBitOnRobot(0x0f))
                if (!_config.PlcInfo.InlineGib)
                { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, "Do not MovingShutter - Door Open"); return 3; }
            if (_plcService.IsBusyRobot(0) || _plcService.IsBusyRobot(1))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 1, "Do not MovingShutter - Robot Busy CH ALL "); return 3; }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "Shutter DN Start CH ALL");
            ClearOutDioSig(DioOutputGib.Ch12ShutterUpSol);
            ClearOutDioSig(DioOutputGib.Ch34ShutterUpSol);

            if (!ReadInSig(DioInputGib.Ch12ShutterDnSensor) && !ReadInSig(DioInputGib.Ch34ShutterDnSensor))
            { SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "Shutter DN Finish CH ALL - Already"); return 0; }

            WriteDioSig(DioOutputGib.Ch12ShutterDnSol, false);
            WriteDioSig(DioOutputGib.Ch34ShutterDnSol, false);

            for (int i = 0; i <= waitingCount; i++)
            {
                Thread.Sleep(100);
                if (!ReadInSig(DioInputGib.Ch12ShutterDnSensor) && !ReadInSig(DioInputGib.Ch34ShutterDnSensor)) break;
            }

            if (ReadInSig(DioInputGib.Ch12ShutterDnSensor) || ReadInSig(DioInputGib.Ch34ShutterDnSensor))
            {
                if (ReadInSig(DioInputGib.Ch12ShutterDnSensor))
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch12ShutterDnSensor, 1, "");
                if (ReadInSig(DioInputGib.Ch34ShutterDnSensor))
                    SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioInputGib.Ch34ShutterDnSensor, 1, "");
                return 3;
            }

            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "Shutter DN Finish CH ALL");
        }
        return 0;
    }

    // =========================================================================
    // CycleTimer (Tower Lamp State Machine)
    // Delphi: procedure TControlDio.tmrCycleTimer (lines 3075-3282)
    // =========================================================================

    private void CycleTimerCallback(object? state)
    {
        if (_disposed || !_connected) return;

        try
        {
            int lampR, lampY, lampG, lampB1, lampB2;

            if (IsOcType)
            {
                // Reset switch LED blinking when MC not monitoring
                if (!ReadInSig(DioInput.McMonitoring))
                {
                    int idx = DioOutput.ResetSwitchLed / 8;
                    int pos = DioOutput.ResetSwitchLed % 8;
                    bool isOn = (_dioDriver.GetOutputFlushByte(idx) & (1 << pos)) > 0;
                    WriteDioSig(DioOutput.ResetSwitchLed, isOn);
                }
                else
                {
                    if (ReadOutSig(DioOutput.ResetSwitchLed))
                        WriteDioSig(DioOutput.ResetSwitchLed, true);

                    // Back door lamp control
                    if (ReadInSig(DioInput.Ch12DoorLeftOpen) && ReadInSig(DioInput.Ch12DoorRightOpen))
                        WriteDioSig(DioOutput.Ch12BackDoorLampOn, false);
                    else
                        WriteDioSig(DioOutput.Ch12BackDoorLampOn, true);

                    if (ReadInSig(DioInput.Ch34DoorLeftOpen) && ReadInSig(DioInput.Ch34DoorRightOpen))
                        WriteDioSig(DioOutput.Ch34BackDoorLampOn, false);
                    else
                        WriteDioSig(DioOutput.Ch34BackDoorLampOn, true);
                }

                lampR = DioOutput.TowerLampRed;
                lampY = DioOutput.TowerLampYellow;
                lampG = DioOutput.TowerLampGreen;
                lampB1 = DioOutput.Buzzer1;
                lampB2 = DioOutput.Buzzer2;
            }
            else
            {
                lampR = DioOutputGib.TowerLampRed;
                lampY = DioOutputGib.TowerLampYellow;
                lampG = DioOutputGib.TowerLampGreen;
                lampB1 = DioOutputGib.Buzzer1;
                lampB2 = DioOutputGib.Buzzer2;

                // CH 1-2 reset switch LED
                if (!ReadInSig(DioInputGib.Ch12McMonitoring))
                {
                    int idx = DioOutputGib.Ch12ResetSwitchLed / 8;
                    int pos = DioOutputGib.Ch12ResetSwitchLed % 8;
                    bool isOn = (_dioDriver.GetOutputFlushByte(idx) & (1 << pos)) > 0;
                    WriteDioSig(DioOutputGib.Ch12ResetSwitchLed, isOn);
                }
                else
                {
                    if (ReadOutSig(DioOutputGib.Ch12ResetSwitchLed))
                        WriteDioSig(DioOutputGib.Ch12ResetSwitchLed, true);
                }

                // CH 3-4 reset switch LED
                if (!ReadInSig(DioInputGib.Ch34McMonitoring))
                {
                    int idx = DioOutputGib.Ch34ResetSwitchLed / 8;
                    int pos = DioOutputGib.Ch34ResetSwitchLed % 8;
                    bool isOn = (_dioDriver.GetOutputFlushByte(idx) & (1 << pos)) > 0;
                    WriteDioSig(DioOutputGib.Ch34ResetSwitchLed, isOn);
                }
                else
                {
                    if (ReadOutSig(DioOutputGib.Ch34ResetSwitchLed))
                        WriteDioSig(DioOutputGib.Ch34ResetSwitchLed, true);
                }
            }

            if (!UseTowerLamp) return;

            uint tick = (uint)Environment.TickCount;

            switch (_towerLampState)
            {
                case (int)LampState.None:
                    if (ReadOutSig(lampR)) WriteDioSig(lampR, true);
                    if (ReadOutSig(lampY)) WriteDioSig(lampY, true);
                    if (ReadOutSig(lampG)) WriteDioSig(lampG, true);
                    if (ReadOutSig(lampB1)) WriteDioSig(lampB1, true);
                    if (ReadOutSig(lampB2)) WriteDioSig(lampB2, true);
                    break;

                case (int)LampState.Manual:
                    if (ReadOutSig(lampR)) WriteDioSig(lampR, true);
                    if (!ReadOutSig(lampY)) WriteDioSig(lampY, false);
                    if (ReadOutSig(lampG)) WriteDioSig(lampG, true);
                    if (ReadOutSig(lampB1)) WriteDioSig(lampB1, true);
                    if (ReadOutSig(lampB2)) WriteDioSig(lampB2, true);
                    break;

                case (int)LampState.Pause:
                    if (ReadOutSig(lampR)) WriteDioSig(lampR, true);
                    if (ReadOutSig(lampY)) WriteDioSig(lampY, true);
                    if (tick - _towerLampTick > 450)
                    {
                        WriteDioSig(lampG, ReadOutSig(lampG)); // Toggle
                        _towerLampTick = tick;
                    }
                    if (ReadOutSig(lampB1)) WriteDioSig(lampB1, true);
                    if (ReadOutSig(lampB2)) WriteDioSig(lampB2, true);
                    break;

                case (int)LampState.Auto:
                    if (ReadOutSig(lampR)) WriteDioSig(lampR, true);
                    if (ReadOutSig(lampY)) WriteDioSig(lampY, true);
                    if (!ReadOutSig(lampG)) WriteDioSig(lampG, false);
                    if (ReadOutSig(lampB1)) WriteDioSig(lampB1, true);
                    if (IsPreOcType)
                    {
                        if (ReadInSig(DioInputGib.Ch12MutingLamp) || ReadInSig(DioInputGib.Ch34MutingLamp))
                            WriteDioSig(lampB2, false);
                        else
                            WriteDioSig(lampB2, true);
                    }
                    else
                    {
                        if (ReadOutSig(lampB2)) WriteDioSig(lampB2, false);
                    }
                    break;

                case (int)LampState.Request:
                    if (ReadOutSig(lampR)) WriteDioSig(lampR, true);
                    if (tick - _towerLampTick > 450)
                    {
                        WriteDioSig(lampY, ReadOutSig(lampY)); // Toggle
                        _towerLampTick = tick;
                    }
                    if (ReadOutSig(lampG)) WriteDioSig(lampG, true);
                    break;

                case (int)LampState.Error:
                    if (tick - _towerLampTick > 450)
                    {
                        WriteDioSig(lampR, ReadOutSig(lampR)); // Toggle
                        _towerLampTick = tick;
                    }
                    if (ReadOutSig(lampY)) WriteDioSig(lampY, true);
                    if (ReadOutSig(lampG)) WriteDioSig(lampG, true);
                    if (MelodyOn)
                    { if (!ReadOutSig(lampB1)) WriteDioSig(lampB1, false); }
                    else
                    { if (ReadOutSig(lampB1)) WriteDioSig(lampB1, true); }
                    break;

                case (int)LampState.Emergency:
                    if (!ReadOutSig(lampR)) WriteDioSig(lampR, false);
                    if (ReadOutSig(lampY)) WriteDioSig(lampY, true);
                    if (ReadOutSig(lampG)) WriteDioSig(lampG, true);
                    if (MelodyOn)
                    { if (!ReadOutSig(lampB1)) WriteDioSig(lampB1, false); }
                    else
                    { if (ReadOutSig(lampB1)) WriteDioSig(lampB1, true); }
                    break;
            }
        }
        catch (Exception ex)
        {
            _logger.Error($"CycleTimer error: {ex.Message}");
        }
    }

    // =========================================================================
    // Remaining public methods
    // =========================================================================

    /// <inheritdoc />
    public void DisplayIo()
    {
        SendMsgMain(DioMsgConstants.MsgModeDisplayIo, 0, 0, "");
    }

    /// <inheritdoc />
    public void RefreshIo()
    {
        // Currently no-op (Delphi version was all commented out)
    }

    /// <inheritdoc />
    public void ResetError(int index)
    {
        int temp = 0;
        switch (index)
        {
            case 0:
                for (int i = 0; i < DioError.MaxAlarmDataSize; i++)
                    DioAlarmData[i] = 0;
                break;
            case 1:
            {
                int div = DioError.McMonitor / 8;
                for (int i = 0; i <= div; i++) DioAlarmData[i] = 0;
                for (int i = 0; i < DioError.MaxAlarmDataSize; i++) temp += DioAlarmData[i];
                break;
            }
            case 2:
            {
                int div = DioError.McMonitor / 8;
                for (int i = 0; i <= div; i++) DioAlarmData[i] = 0;
                for (int i = 0; i < DioError.MaxAlarmDataSize; i++) temp += DioAlarmData[i];
                if (temp == 0) SetAlarmMsg(-1, true);
                break;
            }
        }
    }

    /// <inheritdoc />
    public bool SetFanOnOff(int channel, bool isOnOff)
    {
        if (IsOcType)
            WriteDioSig(DioOutput.Ch1PmicFanOn + channel * 16, isOnOff);
        return true;
    }

    /// <inheritdoc />
    public bool SetIonizer(int group, bool isOnOff)
    {
        if (IsOcType)
            WriteDioSig(DioOutput.Ch12IonOnOffSol + group, isOnOff);
        else
            WriteDioSig(DioOutputGib.Ch12IonOnOffSol + group, isOnOff);
        return true;
    }

    /// <inheritdoc />
    public bool UnlockDoorOpen(int channel, bool unlock)
    {
        if (!IsOcType) return !unlock;

        switch (channel)
        {
            case ChannelSelect.AllCh:
                WriteDioSig(DioOutput.Ch12DoorLeftUnlock, !unlock);
                WriteDioSig(DioOutput.Ch12DoorRightUnlock, !unlock);
                WriteDioSig(DioOutput.Ch34DoorLeftUnlock, !unlock);
                WriteDioSig(DioOutput.Ch34DoorRightUnlock, !unlock);
                break;
            case ChannelSelect.TopCh:
                WriteDioSig(DioOutput.Ch12DoorLeftUnlock, !unlock);
                WriteDioSig(DioOutput.Ch12DoorRightUnlock, !unlock);
                break;
            case ChannelSelect.BottomCh:
                WriteDioSig(DioOutput.Ch34DoorLeftUnlock, !unlock);
                WriteDioSig(DioOutput.Ch34DoorRightUnlock, !unlock);
                break;
        }
        return !unlock;
    }

    /// <inheritdoc />
    public void SetAlarmData(int index, int value)
    {
        int byteIdx = index / 8;
        int bitPos = index % 8;
        if (value != 0)
            DioAlarmData[byteIdx] = DioAlarmData[byteIdx] | (0x01 << bitPos);
        else
            DioAlarmData[byteIdx] = DioAlarmData[byteIdx] & ~(0x01 << bitPos);
    }

    /// <inheritdoc />
    public void SetTowerLampState(int state)
    {
        _towerLampState = state;
    }

    // =========================================================================
    // WaitSignal
    // Delphi: function TControlDio.WaitSignal (lines 3668-3687)
    // =========================================================================

    private uint WaitSignal(byte index, byte value, uint waitTime)
    {
        int byteIdx = index / 8;
        int bitPos = index % 8;
        uint startTick = (uint)Environment.TickCount;
        uint currentTick = startTick;

        while ((currentTick - startTick) < waitTime)
        {
            int bit = (_dioDriver.GetInputByte(byteIdx) >> bitPos) & 1;
            if (bit == value) return 0;
            Thread.Sleep(10);
            currentTick = (uint)Environment.TickCount;
        }
        return 1;
    }

    // =========================================================================
    // DIO Driver Event Handlers
    // Delphi: procedure TControlDio.CommDIONotify (lines 3690-3742)
    // =========================================================================

    private void OnDioConnect(object? sender, DioNotifyEventArgs e)
    {
        if (e.Param != 0)
        {
            _connected = true;
            CheckAlarm();
        }
        else
        {
            _connected = false;
        }

        _messageBus.Publish(new DioEventMessage
        {
            Mode = DioMsgConstants.CommDioMsgConnect,
            Param = e.Param,
        });
    }

    private void OnDioInputChanged(object? sender, DioNotifyEventArgs e)
    {
        if (!_connected) return;

        CheckAlarm();
        ProcessChangedDi(e.Message);

        _messageBus.Publish(new DioEventMessage
        {
            Mode = DioMsgConstants.CommDioMsgChangeDi,
            Param = 0,
        });
    }

    private void OnDioOutputChanged(object? sender, DioNotifyEventArgs e)
    {
        _messageBus.Publish(new DioEventMessage
        {
            Mode = DioMsgConstants.CommDioMsgChangeDo,
            Param = 0,
        });
    }

    private void OnDioError(object? sender, DioNotifyEventArgs e)
    {
        if (e.Param == 100)
        {
            LastNgMsg = "Disconnected DIO Card....";
            SendAlarm(DioMsgConstants.MsgModeSystemAlarm, DioError.DioCardDisconnected, 1, LastNgMsg);
            _connected = false;
        }
    }

    // =========================================================================
    // Process_ChangedDI
    // Delphi: procedure TControlDio.Process_ChangedDI (lines 3284-3326)
    // =========================================================================

    private void ProcessChangedDi(string message)
    {
        if (string.IsNullOrEmpty(message)) return;

        var items = message.Split(',');
        foreach (var item in items)
        {
            int eqPos = item.IndexOf('=');
            if (eqPos < 1) continue;

            if (!int.TryParse(item.AsSpan(0, eqPos), out int index)) continue;
            if (!int.TryParse(item.AsSpan(eqPos + 1), out int value)) continue;

            switch (index)
            {
                case 0: // START Switch
                    if (value != 1)
                    {
                        if (!_status.AutoMode)
                        {
                            SendMsgMain(DioMsgConstants.CommDioMsgLog, 0, 0, "Press Turn Start Switch");
                            ClearOutDioSig(DioOutput.StartSwLed);
                        }
                    }
                    break;
            }
        }
    }
}
