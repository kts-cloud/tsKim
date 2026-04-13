// =============================================================================
// CameraRadiantDriver.cs
// Converted from Delphi: src_X3584\CommCameraRadiant.pas (TCommCamera class)
// Namespace: Dongaeltek.ITOLED.Hardware.Camera
// =============================================================================
//
// POCB Camera (Radiant) communication driver.
// Acts as a TCP server with one TcpListener per channel (4 channels).
// Protocol: 8-byte header (4-byte size LE + 4-byte checksum LE) followed by
//           a null-terminated command string, optionally followed by binary data.
// =============================================================================

using System.Net;
using System.Net.Sockets;
using System.Text;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Models;
using Dongaeltek.ITOLED.Hardware.Light;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Camera;

// =============================================================================
// Constants
// =============================================================================

/// <summary>
/// Camera communication constants.
/// Original Delphi: CommCameraRadiant unit-level constants.
/// </summary>
public static class CameraConstants
{
    /// <summary>Maximum camera channel index (0-based, inclusive). Delphi: MAX_COUNT_CAMERA = 3</summary>
    public const int MaxCountCamera = 3;

    /// <summary>Total number of camera channels (0..MaxCountCamera).</summary>
    public const int ChannelCount = MaxCountCamera + 1;

    /// <summary>GUI message type offset. Delphi: GUIMESSAGE_CAMREA = 500</summary>
    public const int GuiMessageCamera = 500;

    // ---- Message modes ----

    /// <summary>Delphi: MSG_MODE_CONNECT = 100</summary>
    public const int MsgModeConnect = 100;

    /// <summary>Delphi: MSG_MODE_WORKING = 101</summary>
    public const int MsgModeWorking = 101;

    /// <summary>Delphi: MSG_MODE_ERROR / MSG_MODE_ALARM = 102</summary>
    public const int MsgModeError = 102;

    // ---- Error codes ----

    /// <summary>Delphi: COMMCAM_ERR_NONE = 0</summary>
    public const int ErrNone = 0;

    /// <summary>Delphi: COMMCAM_ERR_NAK = 1</summary>
    public const int ErrNak = 1;

    /// <summary>Delphi: COMMCAM_ERR_RESULT = 2</summary>
    public const int ErrResult = 2;

    /// <summary>Delphi: COMMCAM_ERR_TIMEOUT = 3</summary>
    public const int ErrTimeout = 3;

    /// <summary>Delphi: COMMCAM_ERR_FLASHERASE = 4</summary>
    public const int ErrFlashErase = 4;

    /// <summary>Delphi: COMMCAM_ERR_CANCEL = 5</summary>
    public const int ErrCancel = 5;

    /// <summary>Delphi: COMMCAM_ERR_SENDFAIL = 100</summary>
    public const int ErrSendFail = 100;

    /// <summary>Delphi: COMMCAM_ERR_EXCEPTION = 101</summary>
    public const int ErrException = 101;

    /// <summary>Delphi: COMMCAM_ERR_SIZE = 102</summary>
    public const int ErrSize = 102;

    /// <summary>Delphi: COMMCAM_ERR_CHECKSUM = 103</summary>
    public const int ErrChecksum = 103;

    /// <summary>Delphi: COMMCAM_ERR_CHGPTN = 104</summary>
    public const int ErrChgPtn = 104;

    // ---- Network defaults ----

    /// <summary>Delphi: BASE_CAMERA_IP = '192.168.'</summary>
    public const string BaseCameraIp = "192.168.";

    /// <summary>Delphi: BASE_CAMERA_PORT = 2291</summary>
    public const int BaseCameraPort = 2291;

    /// <summary>Delphi: BASE_CAMERA_INDEX = 1</summary>
    public const int BaseCameraIndex = 1;
}

// =============================================================================
// Camera process step enum
// =============================================================================

/// <summary>
/// Camera command processing steps.
/// Original Delphi: CAM_PROCESS_NONE through CAM_PROCESS_AFTERSTART constants.
/// </summary>
public enum CameraProcessStep
{
    /// <summary>Idle. Delphi: CAM_PROCESS_NONE = 0</summary>
    None = 0,

    /// <summary>Model change. Delphi: CAM_PROCESS_MODELCHG = 1</summary>
    ModelChange = 1,

    /// <summary>Ping/heartbeat. Delphi: CAM_PROCESS_PING = 2</summary>
    Ping = 2,

    /// <summary>Start inspection. Delphi: CAM_PROCESS_START = 3</summary>
    Start = 3,

    /// <summary>Measure in progress. Delphi: CAM_PROCESS_MEASURE = 4</summary>
    Measure = 4,

    /// <summary>POCB Gamma. Delphi: CAM_PROCESS_POCBGAMMA = 5</summary>
    PocbGamma = 5,

    /// <summary>FFC start. Delphi: CAM_PROCESS_FFCSTART = 6</summary>
    FfcStart = 6,

    /// <summary>End inspection. Delphi: CAM_PROCESS_END = 7</summary>
    End = 7,

    /// <summary>FTP upload. Delphi: CAM_PROCESS_FTPUPLOAD = 8</summary>
    FtpUpload = 8,

    /// <summary>Stain start. Delphi: CAM_PROCESS_STAINSTART = 9</summary>
    StainStart = 9,

    /// <summary>Change RCB. Delphi: CAM_PROCESS_CHANGERCB = 10</summary>
    ChangeRcb = 10,

    /// <summary>After start. Delphi: CAM_PROCESS_AFTERSTART = 11</summary>
    AfterStart = 11,
}

// =============================================================================
// Record types (Delphi packed records -> C# classes)
// =============================================================================

/// <summary>
/// Camera data buffer for receiving POCB binary data.
/// Original Delphi: <c>TCameraData</c> record.
/// </summary>
public sealed class CameraDataBuffer
{
    /// <summary>Total expected data size.</summary>
    public int FullSize { get; set; }

    /// <summary>Current accumulated size.</summary>
    public int Size { get; set; }

    /// <summary>Raw data buffer.</summary>
    public byte[] Data { get; set; } = Array.Empty<byte>();
}

/// <summary>
/// Camera command processing state per channel.
/// Original Delphi: <c>TCameraCommandData</c> record.
/// </summary>
public sealed class CameraCommandData
{
    /// <summary>Current process step. Delphi: Step</summary>
    public CameraProcessStep Step { get; set; } = CameraProcessStep.None;

    /// <summary>Reply code (0=ACK, 1=NAK, etc.). Delphi: Reply</summary>
    public int Reply { get; set; }

    /// <summary>Waiting for continuation binary data. Delphi: WaitingData</summary>
    public bool WaitingData { get; set; }

    /// <summary>Current data is template. Delphi: TemplateData</summary>
    public bool TemplateData { get; set; }

    /// <summary>Need more command string data (split across packets). Delphi: NeedMoreCommand</summary>
    public bool NeedMoreCommand { get; set; }

    /// <summary>Product ID from START command. Delphi: PID</summary>
    public string PID { get; set; } = string.Empty;

    /// <summary>Error message string. Delphi: ErrorMsg</summary>
    public string ErrorMsg { get; set; } = string.Empty;

    /// <summary>Received data string. Delphi: RecvData</summary>
    public string RecvData { get; set; } = string.Empty;

    /// <summary>PUC version from camera. Delphi: PUCVer</summary>
    public string PUCVer { get; set; } = string.Empty;

    /// <summary>TrueTest program version from camera. Delphi: TrueTestVer</summary>
    public string TrueTestVer { get; set; } = string.Empty;
}

/// <summary>
/// Camera INFO/FFC/Stain data per channel.
/// Original Delphi: <c>TCameraInfoData</c> record.
/// </summary>
public sealed class CameraInfoData
{
    /// <summary>Camera temperature. Delphi: Temperature</summary>
    public double Temperature { get; set; }

    /// <summary>FFC data array (up to 51 entries). Delphi: FFCData[0..50]</summary>
    public double[] FFCData { get; } = new double[51];

    /// <summary>INFO names (up to 151 entries). Delphi: INFOName[0..150]</summary>
    public string[] INFOName { get; } = new string[151];

    /// <summary>INFO data values (up to 151 entries). Delphi: INFOData[0..150]</summary>
    public double[] INFOData { get; } = new double[151];

    /// <summary>Stain data strings (up to 51 entries). Delphi: StainData[0..50]</summary>
    public string[] StainData { get; } = new string[51];

    public CameraInfoData()
    {
        Array.Fill(INFOName, string.Empty);
        Array.Fill(StainData, string.Empty);
    }

    /// <summary>Clears all FFC and INFO data arrays to defaults.</summary>
    public void Clear()
    {
        Temperature = 0;
        Array.Clear(FFCData);
        Array.Clear(INFOData);
        Array.Fill(INFOName, string.Empty);
        Array.Fill(StainData, string.Empty);
    }
}

/// <summary>
/// OTP data buffer for START command.
/// Original Delphi: <c>TCameraOtpData</c> record.
/// </summary>
public sealed class CameraOtpData
{
    /// <summary>OTP data size in bytes.</summary>
    public int Size { get; set; }

    /// <summary>OTP data buffer.</summary>
    public byte[] Data { get; set; } = Array.Empty<byte>();
}

// =============================================================================
// Delegate for script execution callbacks (replaces PasScr[nPgNo].ExecExtraFunction)
// =============================================================================

/// <summary>
/// Delegate for executing script extra functions.
/// Replaces Delphi: <c>PasScr[nPgNo].ExecExtraFunction(sCommand)</c>
/// </summary>
/// <param name="pageNo">Page number (channel + jigNo * 4).</param>
/// <param name="command">The script command string.</param>
/// <returns>Empty string on success, error message on failure.</returns>
public delegate string ScriptExtraFunctionDelegate(int pageNo, string command);

// =============================================================================
// Interface
// =============================================================================

/// <summary>
/// Abstraction over the POCB Radiant camera TCP server driver.
/// Mirrors the public surface of Delphi's <c>TCommCamera</c> in CommCameraRadiant.pas.
/// </summary>
public interface ICameraDriver : IDisposable
{
    /// <summary>Jig number (0 or 1). Used to calculate page number: nPgNo = nCh + JigNo * 4.</summary>
    int JigNo { get; set; }

    /// <summary>Whether to use template data mode.</summary>
    bool UseTemplate { get; set; }

    /// <summary>Per-channel command state data. Delphi: CommandData[0..3]</summary>
    CameraCommandData[] CommandData { get; }

    /// <summary>Per-channel INFO data (up to 8 pages). Delphi: InfoData[0..7]</summary>
    CameraInfoData[] InfoData { get; }

    /// <summary>Per-channel serial numbers. Delphi: m_sSerialNo[0..3]</summary>
    string[] SerialNumbers { get; }

    /// <summary>Per-channel send data counters. Delphi: m_nSendData[0..3]</summary>
    int[] SendDataCounters { get; }

    /// <summary>Per-channel OTP data. Delphi: m_OtpData[0..3]</summary>
    CameraOtpData[] OtpData { get; }

    /// <summary>
    /// Sends a command to a specific camera channel and waits for reply.
    /// Original Delphi: <c>TCommCamera.SendCommand</c>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <param name="command">Command string (e.g. "START PID001 1024").</param>
    /// <param name="waitTimeMs">Timeout in milliseconds (default 3000).</param>
    /// <returns>Error code from <see cref="CameraConstants"/>.</returns>
    int SendCommand(int channel, string command, int waitTimeMs = 3000);

    /// <summary>
    /// Cancels pending command on a channel (or all channels if channel > 3).
    /// Original Delphi: <c>TCommCamera.CancelCommand</c>
    /// </summary>
    int CancelCommand(int channel);

    /// <summary>
    /// Sends raw binary buffer to a channel.
    /// Original Delphi: <c>TCommCamera.SendBuffer</c>
    /// </summary>
    bool SendBuffer(int channel, byte[] buffer, int waitTimeMs = 3000);

    /// <summary>
    /// Sends a model change command to all channels.
    /// Original Delphi: <c>TCommCamera.SendModel</c>
    /// </summary>
    int SendModel(string modelName);

    /// <summary>
    /// Sets OTP data buffer for a channel's START command.
    /// Original Delphi: <c>TCommCamera.SetBufferForOtpDataAtStartCmd</c>
    /// </summary>
    void SetBufferForOtpDataAtStartCmd(int channel, int totalSize);

    /// <summary>
    /// Sends data string to a specific channel (by finding connected client).
    /// Original Delphi: <c>TCommCamera.SendDataByChannel</c>
    /// </summary>
    bool SendDataByChannel(int channel, string data);

    /// <summary>
    /// Sends data string to all channels.
    /// Original Delphi: <c>TCommCamera.SendDataAll</c>
    /// </summary>
    bool SendDataAll(string data);
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// POCB Camera (Radiant) driver using TCP server per channel.
/// Replaces Delphi's <c>TCommCamera</c> class from CommCameraRadiant.pas.
/// <para>
/// WM_COPYDATA inter-form messaging is replaced with <see cref="IMessageBus"/>
/// publishing <see cref="CameraEventMessage"/> instances.
/// </para>
/// <para>
/// Each channel runs a <see cref="TcpListener"/> on port BASE_CAMERA_PORT + ch,
/// accepting a single camera client connection. Data is received asynchronously
/// and processed according to the Dooone protocol.
/// </para>
/// </summary>
public sealed class CameraRadiantDriver : ICameraDriver
{
    // =====================================================================
    // Dependencies
    // =====================================================================

    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _statusService;
    private readonly IPathManager _pathManager;
    private readonly ILightDriver _lightDriver;
    private readonly int _camType;

    /// <summary>
    /// Callback for script execution (CHGPTN / CHGPTNDONE / EraseFlash_POCB).
    /// Set by the owning form/logic layer after construction.
    /// </summary>
    public ScriptExtraFunctionDelegate? ScriptExtraFunction { get; set; }

    // =====================================================================
    // Per-channel state
    // =====================================================================

    private readonly TcpListener?[] _listeners = new TcpListener[CameraConstants.ChannelCount];
    private readonly TcpClient?[] _clients = new TcpClient[CameraConstants.ChannelCount];
    private readonly NetworkStream?[] _streams = new NetworkStream[CameraConstants.ChannelCount];
    private readonly CancellationTokenSource[] _listenerCts = new CancellationTokenSource[CameraConstants.ChannelCount];
    private readonly object[] _channelLocks = new object[CameraConstants.ChannelCount];
    private readonly ManualResetEventSlim[] _commandEvents = new ManualResetEventSlim[CameraConstants.ChannelCount];
    private readonly CameraDataBuffer[] _cameraData = new CameraDataBuffer[CameraConstants.ChannelCount];
    private readonly int[] _lightState = new int[CameraConstants.ChannelCount];
    /// <summary>Background accept loop tasks per channel, tracked so Dispose can await them.</summary>
    private readonly Task?[] _acceptTasks = new Task?[CameraConstants.ChannelCount];

    // =====================================================================
    // Public per-channel arrays (exposed via interface)
    // =====================================================================

    /// <inheritdoc />
    public CameraCommandData[] CommandData { get; } = new CameraCommandData[CameraConstants.ChannelCount];

    /// <inheritdoc />
    public CameraInfoData[] InfoData { get; } = new CameraInfoData[8];

    /// <inheritdoc />
    public string[] SerialNumbers { get; } = new string[CameraConstants.ChannelCount];

    /// <inheritdoc />
    public int[] SendDataCounters { get; } = new int[CameraConstants.ChannelCount];

    /// <inheritdoc />
    public CameraOtpData[] OtpData { get; } = new CameraOtpData[CameraConstants.ChannelCount];

    // =====================================================================
    // Heartbeat timer
    // =====================================================================

    private Timer? _heartbeatTimer;
    private uint _tickLast;

    /// <inheritdoc />
    public int JigNo { get; set; }

    /// <inheritdoc />
    public bool UseTemplate { get; set; }

    private bool _disposed;

    // =====================================================================
    // Constructor
    // =====================================================================

    /// <summary>
    /// Creates a new Radiant camera driver instance.
    /// Original Delphi: <c>TCommCamera.Create(hMain, nCamType, nLightType, nPort)</c>
    /// </summary>
    /// <param name="messageBus">Message bus replacing WM_COPYDATA.</param>
    /// <param name="logger">Application logger.</param>
    /// <param name="config">Configuration service (provides SystemInfo, etc.).</param>
    /// <param name="statusService">System status service (provides UseChannel, etc.).</param>
    /// <param name="pathManager">Path manager (provides CB_DATA path).</param>
    /// <param name="lightDriver">Light controller driver (replaces CommLight ownership).</param>
    /// <param name="camType">Camera type identifier (maps to Delphi <c>m_nCamType</c>).</param>
    public CameraRadiantDriver(
        IMessageBus messageBus,
        ILogger logger,
        IConfigurationService config,
        ISystemStatusService statusService,
        IPathManager pathManager,
        ILightDriver lightDriver,
        int camType = 0)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _statusService = statusService ?? throw new ArgumentNullException(nameof(statusService));
        _pathManager = pathManager ?? throw new ArgumentNullException(nameof(pathManager));
        _lightDriver = lightDriver ?? throw new ArgumentNullException(nameof(lightDriver));
        _camType = camType;

        // Initialize per-channel objects
        for (var i = 0; i < CameraConstants.ChannelCount; i++)
        {
            _channelLocks[i] = new object();
            _commandEvents[i] = new ManualResetEventSlim(false);
            _cameraData[i] = new CameraDataBuffer();
            _lightState[i] = 0;

            CommandData[i] = new CameraCommandData();
            SerialNumbers[i] = string.Empty;
            OtpData[i] = new CameraOtpData();
            _listenerCts[i] = new CancellationTokenSource();
        }

        for (var i = 0; i < InfoData.Length; i++)
        {
            InfoData[i] = new CameraInfoData();
        }

        // Start TCP listeners
        for (var i = 0; i < CameraConstants.ChannelCount; i++)
        {
            StartListener(i);
        }

        // Start heartbeat timer (60 second interval, initially disabled via long dueTime)
        // Matches Delphi: m_tmrHeartbeat.Interval := 60000; m_tmrHeartbeat.Enabled := False;
        _heartbeatTimer = new Timer(HeartbeatTimerCallback, null, Timeout.Infinite, 60000);
    }

    // =====================================================================
    // Heartbeat control
    // =====================================================================

    /// <summary>
    /// Enables or disables the heartbeat timer.
    /// Original Delphi: <c>m_tmrHeartbeat.Enabled := value</c>
    /// </summary>
    public void SetHeartbeatEnabled(bool enabled)
    {
        _heartbeatTimer?.Change(enabled ? 60000 : Timeout.Infinite, 60000);
    }

    // =====================================================================
    // ICameraDriver: SendCommand
    // =====================================================================

    /// <inheritdoc />
    public int SendCommand(int channel, string command, int waitTimeMs = 3000)
    {
        var result = CameraConstants.ErrException;
        CommandData[channel].ErrorMsg = string.Empty;

        var parts = command.Split(' ');
        var cmd = parts[0].Trim();

        switch (cmd)
        {
            case "START":
                CommandData[channel].Step = CameraProcessStep.Start;
                CommandData[channel].WaitingData = false;
                for (var i = 0; i < CameraConstants.ChannelCount; i++)
                    _lightState[i] = 0;
                break;

            case "MODELCHG":
                CommandData[channel].Step = CameraProcessStep.ModelChange;
                break;

            case "PING":
                CommandData[channel].Step = CameraProcessStep.Ping;
                break;

            case "POCBGAMMA":
                CommandData[channel].Step = CameraProcessStep.PocbGamma;
                break;

            case "FFCSTART":
                CommandData[channel].Step = CameraProcessStep.FfcStart;
                break;

            case "END":
                CommandData[channel].Step = CameraProcessStep.End;
                break;

            case "FTPUPLOAD":
                CommandData[channel].Step = CameraProcessStep.FtpUpload;
                break;

            case "STAINSTART":
                CommandData[channel].Step = CameraProcessStep.StainStart;
                break;

            case "CHGRCB":
                CommandData[channel].Step = CameraProcessStep.ChangeRcb;
                break;

            case "AFTERSTART":
                CommandData[channel].Step = CameraProcessStep.AfterStart;
                break;

            case "CLEARDATA":
            {
                var pgNo = channel + JigNo * 4;
                InfoData[pgNo].Clear();
                result = CameraConstants.ErrNone;
                PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, "Camera Command: CLEARDATA OK");
                return result;
            }

            default:
                CommandData[channel].ErrorMsg = "Camera Command: Unknown Command : " + cmd;
                return result;
        }

        CommandData[channel].RecvData = string.Empty;
        CommandData[channel].NeedMoreCommand = false;

        _commandEvents[channel].Reset();
        var sent = SendDataByChannel(channel, command);

        if (sent)
        {
            // Wait for reply
            var signaled = _commandEvents[channel].Wait(waitTimeMs);

            if (signaled)
            {
                switch (CommandData[channel].Reply)
                {
                    case CameraConstants.ErrNone:
                        CommandData[channel].ErrorMsg = "Camera Command: OK " + cmd;
                        break;
                    case CameraConstants.ErrNak:
                        CommandData[channel].ErrorMsg = "Camera Command: NAK " + cmd;
                        break;
                    case CameraConstants.ErrFlashErase:
                        CommandData[channel].ErrorMsg = "Camera Command: Flash Erase Error";
                        break;
                    case CameraConstants.ErrCancel:
                        CommandData[channel].ErrorMsg = "Camera Command: Cancel " + cmd;
                        break;
                    case CameraConstants.ErrChgPtn:
                        // ErrorMsg already set by ProcessData
                        break;
                    case CameraConstants.ErrException:
                        CommandData[channel].ErrorMsg = "Camera Command: EXCEPTION";
                        break;
                    case CameraConstants.ErrResult:
                        // ErrorMsg already set by ProcessData
                        break;
                    default:
                        CommandData[channel].ErrorMsg = "Camera Command: NG";
                        break;
                }

                result = CommandData[channel].Reply;

                if (CommandData[channel].Step != CameraProcessStep.Ping)
                {
                    PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, CommandData[channel].ErrorMsg);
                }
            }
            else
            {
                // Timeout
                if (CommandData[channel].NeedMoreCommand)
                {
                    _logger.Debug(channel, "MoreCommand:" + CommandData[channel].RecvData);
                }

                CommandData[channel].ErrorMsg = "Camera Command: Time out " + cmd;
                result = CameraConstants.ErrTimeout;
                PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, CommandData[channel].ErrorMsg);
            }
        }
        else
        {
            CommandData[channel].ErrorMsg = "Camera Command: Send Fail";
            result = CameraConstants.ErrSendFail;
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, CommandData[channel].ErrorMsg);
        }

        CommandData[channel].Step = CameraProcessStep.None;
        return result;
    }

    // =====================================================================
    // ICameraDriver: CancelCommand
    // =====================================================================

    /// <inheritdoc />
    public int CancelCommand(int channel)
    {
        if (channel > 3)
        {
            for (var i = 0; i < CameraConstants.ChannelCount; i++)
            {
                CommandData[i].Reply = CameraConstants.ErrCancel;
                _commandEvents[i].Set();
            }
        }
        else
        {
            CommandData[channel].Reply = CameraConstants.ErrCancel;
            _commandEvents[channel].Set();
        }

        return 0;
    }

    // =====================================================================
    // ICameraDriver: SendBuffer
    // =====================================================================

    /// <inheritdoc />
    public bool SendBuffer(int channel, byte[] buffer, int waitTimeMs = 3000)
    {
        lock (_channelLocks[channel])
        {
            var stream = _streams[channel];
            if (stream is null || !(_clients[channel]?.Connected ?? false))
                return false;

            try
            {
                stream.Write(buffer, 0, buffer.Length);
                PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                    "(GPC ==> DPC) Buffer Size:" + BufferToString(buffer, 100));
                return true;
            }
            catch (Exception ex)
            {
                _logger.Error(channel, $"[Camera] SendBuffer failed: {ex.Message}", ex);
                return false;
            }
        }
    }

    // =====================================================================
    // ICameraDriver: SendModel
    // =====================================================================

    /// <inheritdoc />
    public int SendModel(string modelName)
    {
        for (var i = 0; i < CameraConstants.ChannelCount; i++)
        {
            CommandData[i].Step = CameraProcessStep.ModelChange;
        }

        return SendDataAll("MODELCHG " + modelName) ? 0 : 1;
    }

    // =====================================================================
    // ICameraDriver: SetBufferForOtpDataAtStartCmd
    // =====================================================================

    /// <inheritdoc />
    public void SetBufferForOtpDataAtStartCmd(int channel, int totalSize)
    {
        OtpData[channel].Size = totalSize;
        OtpData[channel].Data = new byte[totalSize];
    }

    // =====================================================================
    // ICameraDriver: SendDataByChannel
    // =====================================================================

    /// <inheritdoc />
    public bool SendDataByChannel(int channel, string data)
    {
        lock (_channelLocks[channel])
        {
            var stream = _streams[channel];
            if (stream is null || !(_clients[channel]?.Connected ?? false))
                return false;

            return SendDataToStream(channel, data, stream);
        }
    }

    // =====================================================================
    // ICameraDriver: SendDataAll
    // =====================================================================

    /// <inheritdoc />
    public bool SendDataAll(string data)
    {
        var allOk = true;
        for (var i = 0; i < CameraConstants.ChannelCount; i++)
        {
            if (!SendDataByChannel(i, data))
                allOk = false;
        }

        return allOk;
    }

    // =====================================================================
    // TCP Listener management
    // =====================================================================

    /// <summary>
    /// Starts the TCP listener for a specific channel.
    /// </summary>
    private void StartListener(int channel)
    {
        var port = CameraConstants.BaseCameraPort + channel;

        try
        {
            _listeners[channel] = new TcpListener(IPAddress.Any, port);
            _listeners[channel].Start();

            _logger.Info($"[Camera] Listener started on port {port} for channel {channel}");

            // Start accepting connections asynchronously and remember the task so
            // Dispose can await it (otherwise listener loops can outlive the driver).
            _acceptTasks[channel] = AcceptClientsAsync(channel, _listenerCts[channel].Token);
        }
        catch (Exception ex)
        {
            _logger.Error(channel, $"[Camera] Failed to start listener on port {port}: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Async loop that accepts camera client connections.
    /// Original Delphi: TIdTCPServer accept loop (implicit via Indy).
    /// </summary>
    private async Task AcceptClientsAsync(int channel, CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                var listener = _listeners[channel];
                if (listener is null) break;

                var client = await listener.AcceptTcpClientAsync(ct).ConfigureAwait(false);

                lock (_channelLocks[channel])
                {
                    // Close previous connection if any
                    DisconnectClient(channel);

                    _clients[channel] = client;
                    _streams[channel] = client.GetStream();
                    _streams[channel].ReadTimeout = 3000;
                    _streams[channel].WriteTimeout = 3000;

                    CommandData[channel].WaitingData = false;
                }

                PublishMainEvent(CameraConstants.MsgModeConnect, channel, DefCam.CamConnectOk, 0, "Client Connected");

                // Start reading data from this client
                _ = ReadClientDataAsync(channel, ct);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (ObjectDisposedException)
            {
                break;
            }
            catch (Exception ex)
            {
                if (!ct.IsCancellationRequested)
                {
                    _logger.Error(channel, $"[Camera] Accept error: {ex.Message}", ex);
                    await Task.Delay(1000, ct).ConfigureAwait(false);
                }
            }
        }
    }

    /// <summary>
    /// Async loop that reads data from a connected camera client.
    /// Original Delphi: <c>TCommCamera.TCPServerExecute</c>.
    /// </summary>
    private async Task ReadClientDataAsync(int channel, CancellationToken ct)
    {
        var buffer = new byte[DefCam.TcpBuffSize];

        try
        {
            while (!ct.IsCancellationRequested)
            {
                NetworkStream? stream;
                lock (_channelLocks[channel])
                {
                    stream = _streams[channel];
                }

                if (stream is null || !(_clients[channel]?.Connected ?? false))
                    break;

                int bytesRead;
                try
                {
                    bytesRead = await stream.ReadAsync(buffer.AsMemory(0, buffer.Length), ct).ConfigureAwait(false);
                }
                catch (IOException)
                {
                    break;
                }
                catch (ObjectDisposedException)
                {
                    break;
                }

                if (bytesRead == 0)
                    break; // Client disconnected

                var readBuffer = new byte[bytesRead];
                Buffer.BlockCopy(buffer, 0, readBuffer, 0, bytesRead);

                ProcessData(channel, bytesRead, readBuffer);
            }
        }
        catch (OperationCanceledException)
        {
            // Normal shutdown
        }
        catch (Exception ex)
        {
            if (!ct.IsCancellationRequested)
            {
                PublishTestEvent(CameraConstants.MsgModeWorking, channel, 1, 0, ex.Message);
            }
        }
        finally
        {
            lock (_channelLocks[channel])
            {
                CommandData[channel].WaitingData = false;
            }

            PublishMainEvent(CameraConstants.MsgModeConnect, channel, DefCam.CamConnectNg, 0, "Client Disconnected");
        }
    }

    // =====================================================================
    // Data sending (protocol framing)
    // =====================================================================

    /// <summary>
    /// Sends framed data to a specific network stream.
    /// Protocol: 4-byte size (LE) + 4-byte checksum (LE) + null-terminated ASCII command + optional binary payload.
    /// Original Delphi: <c>TCommCamera.SendData</c>
    /// </summary>
    private bool SendDataToStream(int channel, string data, NetworkStream stream)
    {
        _tickLast = (uint)Environment.TickCount;

        byte[] packet;

        if (CommandData[channel].Step == CameraProcessStep.Start)
        {
            // START command: includes OTP binary data after null terminator
            packet = BuildStartOrGammaPacket(channel, data, isGamma: false);
            if (packet.Length == 0) return false;
        }
        else if (CommandData[channel].Step == CameraProcessStep.PocbGamma)
        {
            // POCBGAMMA command: includes binary data after null terminator
            packet = BuildStartOrGammaPacket(channel, data, isGamma: true);
            if (packet.Length == 0) return false;
        }
        else
        {
            // Normal command: header + null-terminated string
            var cmdBytes = Encoding.ASCII.GetBytes(data);
            var totalSize = 8 + cmdBytes.Length + 1; // header(8) + data + null(1)
            packet = new byte[totalSize];

            // Copy command string + null terminator
            Buffer.BlockCopy(cmdBytes, 0, packet, 8, cmdBytes.Length);
            packet[8 + cmdBytes.Length] = 0x00;

            // Write size and checksum
            WriteHeader(packet, totalSize);
        }

        // Try sending
        try
        {
            stream.Write(packet, 0, packet.Length);

            if (CommandData[channel].Step != CameraProcessStep.Ping)
            {
                var logData = data;
                var nullPos = data.IndexOf('\0');
                if (nullPos >= 0) logData = data[..nullPos];
                PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, "(GPC ==> DPC) " + logData);
            }

            return true;
        }
        catch
        {
            // Retry once after 1 second
            try
            {
                Thread.Sleep(1000);
                stream.Write(packet, 0, packet.Length);
                return true;
            }
            catch (Exception ex2)
            {
                var logMsg = data;
                var np = data.IndexOf('\0');
                if (np >= 0) logMsg = data[..np];
                PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                    "(GPC ==> DPC) Send Data Failed! " + logMsg);
                _logger.Error(channel, $"[Camera] Send failed: {ex2.Message}", ex2);
                return false;
            }
        }
    }

    /// <summary>
    /// Builds a packet for START or POCBGAMMA commands that include binary payload.
    /// The input <paramref name="data"/> format: "COMMAND args\0HEXHEXHEX..." where binary
    /// hex data follows after null character in pairs of 2 hex chars separated by nothing (3-byte stride).
    /// </summary>
    private byte[] BuildStartOrGammaPacket(int channel, string data, bool isGamma)
    {
        var nullPos = data.IndexOf('\0');
        if (nullPos < 0)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                isGamma ? "CAM_PROCESS_POCBGAMMA Data Error" : "CAM_PROCESS_START Data Error");
            return Array.Empty<byte>();
        }

        var commandStr = data[..nullPos];
        var parts = commandStr.Split(' ');

        if (!isGamma && parts.Length < 3)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, "CAM_PROCESS_START Data Error");
            return Array.Empty<byte>();
        }

        if (isGamma && parts.Length < 2)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, "CAM_PROCESS_POCBGAMMA Data Error");
            return Array.Empty<byte>();
        }

        if (!isGamma)
        {
            CommandData[channel].PID = parts[1];
        }

        // Parse advertised data size — guard against malformed input.
        if (!int.TryParse(parts[isGamma ? 1 : 2].Trim(), out var dataSize) || dataSize < 0)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                isGamma ? "CAM_PROCESS_POCBGAMMA: invalid dataSize"
                        : "CAM_PROCESS_START: invalid dataSize");
            return Array.Empty<byte>();
        }

        // Build ASCII portion: command string + null terminator
        var cmdBytes = Encoding.ASCII.GetBytes(commandStr);
        var cmdLen = cmdBytes.Length + 1; // +1 for null

        // Validate the source string actually contains enough hex chars for dataSize bytes.
        // Each byte is encoded as 2 hex chars + 1 separator (3-byte stride). The last byte
        // does not need a trailing separator, so the minimum required length is
        // hexStart + (dataSize - 1) * 3 + 2 = hexStart + dataSize * 3 - 1 chars.
        var hexStart = nullPos + 1;
        var requiredLen = dataSize == 0 ? hexStart : hexStart + dataSize * 3 - 1;
        if (data.Length < requiredLen)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                $"{(isGamma ? "CAM_PROCESS_POCBGAMMA" : "CAM_PROCESS_START")}: " +
                $"data truncated (need {requiredLen}, got {data.Length})");
            return Array.Empty<byte>();
        }

        var totalSize = 8 + cmdLen + dataSize;
        var packet = new byte[totalSize];

        // Copy command string + null
        Buffer.BlockCopy(cmdBytes, 0, packet, 8, cmdBytes.Length);
        packet[8 + cmdBytes.Length] = 0x00;

        // Parse binary hex data: 2 hex chars per byte, 3-byte stride in the source string
        try
        {
            for (var i = 0; i < dataSize; i++)
            {
                var hexStr = data.Substring(hexStart + (i * 3), 2);
                packet[8 + cmdLen + i] = Convert.ToByte(hexStr, 16);
            }
        }
        catch (FormatException ex)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                $"{(isGamma ? "CAM_PROCESS_POCBGAMMA" : "CAM_PROCESS_START")}: " +
                $"hex parse error - {ex.Message}");
            return Array.Empty<byte>();
        }

        // Write size and checksum header
        WriteHeader(packet, totalSize);
        return packet;
    }

    /// <summary>
    /// Writes the 8-byte header (4-byte size LE + 4-byte checksum LE) into the packet buffer.
    /// </summary>
    private static void WriteHeader(byte[] packet, int totalSize)
    {
        var sizeBytes = BitConverter.GetBytes(totalSize);
        var checksum = CalcChecksum(totalSize);
        var checksumBytes = BitConverter.GetBytes(checksum);
        Buffer.BlockCopy(sizeBytes, 0, packet, 0, 4);
        Buffer.BlockCopy(checksumBytes, 0, packet, 4, 4);
    }

    // =====================================================================
    // Data processing (protocol parsing)
    // =====================================================================

    /// <summary>
    /// Processes received data from a camera client.
    /// Original Delphi: <c>TCommCamera.ProcessData</c>
    /// </summary>
    private void ProcessData(int channel, int readBufferLen, byte[] readBuffer)
    {
        var pgNo = channel + JigNo * 4;

        // Continuation of binary POCB data?
        if (CommandData[channel].WaitingData)
        {
            Buffer.BlockCopy(readBuffer, 0, _cameraData[channel].Data,
                _cameraData[channel].Size, readBufferLen);
            _cameraData[channel].Size += readBufferLen;

            if (_cameraData[channel].Size < _cameraData[channel].FullSize)
                return; // Need more data

            // Continuation complete
            SaveCameraData(channel, _cameraData[channel], CommandData[channel].TemplateData);
            CommandData[channel].WaitingData = false;
            SendDataByChannel(channel, "ACK");

            // Complete START process (non-COMMPG_A19 path)
            if (_config.SystemInfo.CAMTemplateData)
            {
                if (CommandData[channel].TemplateData)
                {
                    CommandData[channel].Step = CameraProcessStep.None;
                    CommandData[channel].Reply = CameraConstants.ErrNone;
                    _commandEvents[channel].Set();
                }
            }
            else
            {
                CommandData[channel].Step = CameraProcessStep.None;
                CommandData[channel].Reply = CameraConstants.ErrNone;
                _commandEvents[channel].Set();
            }

            return;
        }

        // Normal data: need at least 8-byte header
        if (readBufferLen < 8)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                $"Not enough Data Size Error ({readBufferLen})");
            CommandData[channel].Reply = CameraConstants.ErrSize;
            _commandEvents[channel].Set();
            return;
        }

        // Read header (size field for later use)
        var headerSize = BitConverter.ToInt32(readBuffer, 0);

        // Find null terminator and parse command string
        var nullPos = -1;
        string recvData;

        if (CommandData[channel].NeedMoreCommand)
        {
            // Continue receiving command string from previous packet
            recvData = CommandData[channel].RecvData;
            for (var i = 0; i < readBufferLen; i++)
            {
                if (readBuffer[i] == 0)
                {
                    nullPos = i;
                    break;
                }

                recvData += (char)readBuffer[i];
            }

            _logger.Debug(pgNo, "NULL=" + nullPos + ", RecvData:" + recvData);
        }
        else
        {
            // New packet: skip 8-byte header
            recvData = string.Empty;
            for (var i = 8; i < readBufferLen; i++)
            {
                if (readBuffer[i] == 0)
                {
                    nullPos = i;
                    break;
                }

                recvData += (char)readBuffer[i];
            }
        }

        CommandData[channel].RecvData = recvData;

        if (nullPos < 0)
        {
            // Command string not complete (no null terminator) - need more data
            _logger.Debug(pgNo, "NeedMoreCommand RecvData:" + recvData);
            CommandData[channel].NeedMoreCommand = true;
            return;
        }

        CommandData[channel].NeedMoreCommand = false;
        if (string.IsNullOrEmpty(recvData)) return;

        if (CommandData[channel].Step != CameraProcessStep.Ping)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, "(GPC <== DPC) " + recvData);
        }

        var parts = recvData.Split(' ');
        var command = parts[0].Trim();

        if (CommandData[channel].Step == CameraProcessStep.None)
        {
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                "Not Working (GPC <== DPC) " + recvData);
            SendDataByChannel(channel, "NAK");
            return;
        }

        // ---- Command dispatch ----

        if (command == "POCBDATA")
        {
            HandlePocbData(channel, parts, readBuffer, readBufferLen, nullPos);
            return;
        }

        if (command == "CHGPTN")
        {
            HandleChgPtn(channel, parts, pgNo);
        }
        else if (command == "PGON")
        {
            HandlePgOn(channel);
        }
        else if (command == "PGOFF")
        {
            HandlePgOff(channel, parts);
        }
        else if (command == "CHGPTNDONE")
        {
            HandleChgPtnDone(channel, pgNo);
        }
        else if (command == "AFTERDONE")
        {
            HandleAfterDone(channel);
        }
        else if (command == "POCBPATH")
        {
            HandlePocbPath(channel, parts);
        }
        else if (command == "PUCVER")
        {
            SendDataByChannel(channel, "ACK");
            CommandData[channel].PUCVer = parts.Length > 1 ? parts[1] : string.Empty;
        }
        else if (command == "GETVER")
        {
            SendDataByChannel(channel, "ACK");
            CommandData[channel].TrueTestVer = parts.Length > 1 ? parts[1] : string.Empty;
        }
        else if (command == "STAINDONE")
        {
            SendDataByChannel(channel, "ACK");
            if (parts.Length > 1) ParseStainData(channel, parts[1]);
            CommandData[channel].Reply = CameraConstants.ErrNone;
        }
        else if (command == "FFCDONE")
        {
            SendDataByChannel(channel, "ACK");
            if (parts.Length > 1) ParseFfcData(channel, parts[1]);
            CommandData[channel].Reply = CameraConstants.ErrNone;
            _commandEvents[channel].Set();
        }
        else if (command == "RESULT")
        {
            HandleResult(channel, parts, recvData, pgNo);
        }
        else if (command == "ACK")
        {
            HandleAck(channel);
        }
        else if (command == "NAK")
        {
            HandleNak(channel);
        }
        else
        {
            // Unknown command
            _logger.Debug(pgNo, $"Unknown Command: {command}");
            SendDataByChannel(channel, "NAK");
        }

        // Process remaining data in buffer
        if (readBufferLen > headerSize && headerSize > 0)
        {
            var remainLen = readBufferLen - headerSize;
            _logger.Debug(pgNo, $"Remain RecvSize({readBufferLen}) - DataSize({headerSize}) = {remainLen}");
            var remainBuffer = new byte[remainLen];
            Buffer.BlockCopy(readBuffer, nullPos + 1, remainBuffer, 0, remainLen);
            ProcessData(channel, remainLen, remainBuffer);
        }
    }

    // =====================================================================
    // Command handlers
    // =====================================================================

    private void HandlePocbData(int channel, string[] parts, byte[] readBuffer, int readBufferLen, int nullPos)
    {
        _cameraData[channel].Size = 0;
        _cameraData[channel].FullSize = int.Parse(parts[2]); // Data Size
        _cameraData[channel].Data = new byte[_cameraData[channel].FullSize];

        CommandData[channel].TemplateData = parts[1] == "RMTE";

        // Copy initial data after null terminator
        var initialDataLen = readBufferLen - nullPos - 1;
        if (initialDataLen > 0)
        {
            Buffer.BlockCopy(readBuffer, nullPos + 1, _cameraData[channel].Data, 0, initialDataLen);
            _cameraData[channel].Size = initialDataLen;
        }

        if (_cameraData[channel].Size < _cameraData[channel].FullSize)
        {
            // Need more data
            CommandData[channel].WaitingData = true;
        }
        else
        {
            // Data reception complete
            SaveCameraData(channel, _cameraData[channel], CommandData[channel].TemplateData);
            CommandData[channel].WaitingData = false;
            SendDataByChannel(channel, "ACK");

            // Complete START process (non-COMMPG_A19 path)
            if (_config.SystemInfo.CAMTemplateData)
            {
                if (CommandData[channel].TemplateData)
                {
                    CommandData[channel].Step = CameraProcessStep.None;
                    CommandData[channel].Reply = CameraConstants.ErrNone;
                    _commandEvents[channel].Set();
                }
            }
            else
            {
                CommandData[channel].Step = CameraProcessStep.None;
                CommandData[channel].Reply = CameraConstants.ErrNone;
                _commandEvents[channel].Set();
            }
        }
    }

    private void HandleChgPtn(int channel, string[] parts, int pgNo)
    {
        if (_config.SystemInfo.CAMCallbackChangePattern)
        {
            string sRet;
            var step = CommandData[channel].Step;

            if (step == CameraProcessStep.Measure
                || step == CameraProcessStep.AfterStart
                || step == CameraProcessStep.StainStart)
            {
                var patternArg = parts.Length > 1 ? parts[1] : "0";
                sRet = ScriptExtraFunction?.Invoke(pgNo, $"Callback_ChangePattern 1,{patternArg},0,0") ?? string.Empty;
            }
            else
            {
                sRet = "Unknown Process CHGPTN NG";
            }

            if (!string.IsNullOrEmpty(sRet))
            {
                SendDataByChannel(channel, "NAK");
                CommandData[channel].ErrorMsg = sRet;
                CommandData[channel].Reply = CameraConstants.ErrChgPtn;
                _commandEvents[channel].Set();
                return;
            }

            SendDataByChannel(channel, "ACK");
        }
        else
        {
            SendDataByChannel(channel, "NAK");
            CommandData[channel].ErrorMsg = "Not Support Internal CHGPTN";
            CommandData[channel].Reply = CameraConstants.ErrChgPtn;
            _commandEvents[channel].Set();
            PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, "Not Support Internal CHGPTN");
        }
    }

    private void HandlePgOn(int channel)
    {
        _lightState[channel] = 0; // Light source off
        var logMsg = $"LS: {_lightState[0]} {_lightState[1]} {_lightState[2]} {_lightState[3]}";
        PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, logMsg);

        // Check all channels off
        if (CheckLightSourceStateAll(allOn: false))
        {
            _lightDriver.WriteBrightsAll(0);
            SendDataAll("ACK");
        }
    }

    private void HandlePgOff(int channel, string[] parts)
    {
        _lightState[channel] = 1; // Light source on
        var logMsg = $"LS: {_lightState[0]} {_lightState[1]} {_lightState[2]} {_lightState[3]}";
        PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0, logMsg);

        var bright1 = parts.Length > 1 ? byte.Parse(parts[1]) : (byte)0;
        var bright2 = parts.Length > 2 ? byte.Parse(parts[2]) : (byte)0;
        _lightDriver.WriteBrightTwin((byte)(channel * 2), (byte)(channel * 2 + 1), bright1, bright2);
        SendDataByChannel(channel, "ACK");
    }

    private void HandleChgPtnDone(int channel, int pgNo)
    {
        SendDataByChannel(channel, "ACK");

        switch (CommandData[channel].Step)
        {
            case CameraProcessStep.None:
                // Not in inspection process
                break;

            case CameraProcessStep.Measure:
                // Erase flash during measure
                var eraseResult = ScriptExtraFunction?.Invoke(pgNo, "EraseFlash_POCB") ?? string.Empty;
                // Note: error result is intentionally not propagated (matches Delphi)
                break;

            case CameraProcessStep.StainStart:
                // Stain process - no action (matches Delphi commented-out SetEvent)
                break;

            case CameraProcessStep.AfterStart:
                _commandEvents[channel].Set();
                break;

            default:
                // Unknown step
                break;
        }
    }

    private void HandleAfterDone(int channel)
    {
        SendDataByChannel(channel, "ACK");

        switch (CommandData[channel].Step)
        {
            case CameraProcessStep.None:
                break;
            case CameraProcessStep.AfterStart:
                _commandEvents[channel].Set();
                break;
            default:
                break;
        }
    }

    private void HandlePocbPath(int channel, string[] parts)
    {
        CommandData[channel].RecvData = parts.Length > 1 ? parts[1] : string.Empty;
        CommandData[channel].Step = CameraProcessStep.None;
        SendDataByChannel(channel, "ACK");
        CommandData[channel].Reply = CameraConstants.ErrNone;
        _commandEvents[channel].Set();
    }

    private void HandleResult(int channel, string[] parts, string recvData, int pgNo)
    {
        SendDataByChannel(channel, "ACK");

        if (_config.SystemInfo.CAMResultType == 0)
        {
            // Simple result: RESULT OK/NG xx.xx xx.xx xx.xx xx.xx xx.xx reason
            if (parts.Length > 1 && parts[1] != "OK")
            {
                CommandData[channel].ErrorMsg = recvData.Length > 40
                    ? recvData[40..] : recvData;
                CommandData[channel].Reply = CameraConstants.ErrResult;
            }
            else
            {
                CommandData[channel].Reply = CameraConstants.ErrNone;
            }
        }
        else
        {
            // Extended result with INFO data
            if (parts.Length < 10)
            {
                CommandData[channel].ErrorMsg = "RESULT size Error";
                CommandData[channel].Reply = CameraConstants.ErrResult;
            }
            else
            {
                if (parts[1] != "OK")
                {
                    // Build error message from parts[9..]
                    CommandData[channel].ErrorMsg = string.Join(' ', parts.Skip(9)).Trim();
                    CommandData[channel].Reply = CameraConstants.ErrResult;
                }
                else
                {
                    CommandData[channel].Reply = CameraConstants.ErrNone;
                }

                // Parse temperature and INFO data
                InfoData[pgNo].Temperature = double.TryParse(parts[7], out var temp) ? temp : 0.0;
                InfoData[pgNo].INFOData[0] = InfoData[pgNo].Temperature;

                if (parts.Length > 8)
                {
                    ParseInfoData(channel, parts[8]);
                }
            }
        }

        _commandEvents[channel].Set();
    }

    private void HandleAck(int channel)
    {
        CommandData[channel].Reply = CameraConstants.ErrNone;

        switch (CommandData[channel].Step)
        {
            case CameraProcessStep.None:
                break;
            case CameraProcessStep.ModelChange:
                _commandEvents[channel].Set();
                break;
            case CameraProcessStep.Ping:
                _commandEvents[channel].Set();
                break;
            case CameraProcessStep.Start:
                // START ACK -> transition to Measure
                CommandData[channel].Step = CameraProcessStep.Measure;
                break;
            case CameraProcessStep.PocbGamma:
                _commandEvents[channel].Set();
                break;
            case CameraProcessStep.End:
                if (_config.SystemInfo.CAMStainData)
                {
                    _commandEvents[channel].Set();
                }
                break;
            case CameraProcessStep.FtpUpload:
                _commandEvents[channel].Set();
                break;
            case CameraProcessStep.ChangeRcb:
                CommandData[channel].Step = CameraProcessStep.Measure;
                break;
            case CameraProcessStep.StainStart:
                // No action (matches Delphi)
                break;
            case CameraProcessStep.AfterStart:
                // No action (matches Delphi)
                break;
            default:
                break;
        }
    }

    private void HandleNak(int channel)
    {
        CommandData[channel].Reply = CameraConstants.ErrNak;

        switch (CommandData[channel].Step)
        {
            case CameraProcessStep.None:
                break;
            case CameraProcessStep.ModelChange:
            case CameraProcessStep.Ping:
            case CameraProcessStep.Start:
            case CameraProcessStep.PocbGamma:
            case CameraProcessStep.End:
            case CameraProcessStep.FtpUpload:
            case CameraProcessStep.ChangeRcb:
            case CameraProcessStep.StainStart:
                _commandEvents[channel].Set();
                break;
            default:
                break;
        }
    }

    // =====================================================================
    // Data parsing helpers
    // =====================================================================

    /// <summary>
    /// Parses FFC data string "A1:value,B2:value,..." into InfoData.
    /// Original Delphi: <c>TCommCamera.Parse_FFCData</c>
    /// </summary>
    private void ParseFfcData(int channel, string ffcData)
    {
        var pgNo = channel + JigNo * 4;
        var items = ffcData.Split(',');

        foreach (var item in items)
        {
            if (string.IsNullOrEmpty(item)) continue;

            var colonPos = item.IndexOf(':');
            if (colonPos < 1)
            {
                PublishTestEvent(CameraConstants.MsgModeWorking, channel, 0, 0,
                    $"Parse_FFCData Data format Error: {item}");
                return;
            }

            var key = item[..colonPos];
            var valueStr = item[(colonPos + 1)..];

            if (key.Length < 2) continue;

            var index = key[1] - '0'; // digit from second character
            var dValue = double.TryParse(valueStr, out var v) ? v : 0.0;

            // Offset based on first character (A=0, B=+10, C=+20, D=+30, E=+40)
            index += key[0] switch
            {
                'A' => 0,
                'B' => 10,
                'C' => 20,
                'D' => 30,
                'E' => 40,
                _ => 0,
            };

            if (index >= 0 && index < InfoData[pgNo].FFCData.Length)
            {
                InfoData[pgNo].FFCData[index] = dValue;
            }
        }
    }

    /// <summary>
    /// Parses INFO data string "INFO=name,value,name,value,...".
    /// Original Delphi: <c>TCommCamera.Parse_INFOData</c>
    /// </summary>
    private void ParseInfoData(int channel, string infoData)
    {
        var pgNo = channel + JigNo * 4;

        // Strip "INFO=" prefix
        var data = infoData;
        if (data.StartsWith("INFO=", StringComparison.OrdinalIgnoreCase))
        {
            data = data[5..];
        }

        var items = data.Split(',');
        var pairCount = items.Length / 2;

        for (var i = 0; i < pairCount; i++)
        {
            var nameIdx = i + 1; // 1-based index matching Delphi
            if (nameIdx >= InfoData[pgNo].INFOName.Length) break;

            InfoData[pgNo].INFOName[nameIdx] = items[i * 2];
            InfoData[pgNo].INFOData[nameIdx] = double.TryParse(items[i * 2 + 1], out var v) ? v : 0.0;
        }
    }

    /// <summary>
    /// Parses stain data CSV string into InfoData.
    /// Original Delphi: <c>TCommCamera.Parse_StainData</c>
    /// </summary>
    private void ParseStainData(int channel, string stainData)
    {
        var pgNo = channel + JigNo * 4;
        var items = stainData.Split(',');

        for (var i = 0; i < items.Length && i < InfoData[pgNo].StainData.Length; i++)
        {
            InfoData[pgNo].StainData[i] = items[i];
        }
    }

    // =====================================================================
    // Camera data file save
    // =====================================================================

    /// <summary>
    /// Saves camera binary data to file.
    /// Original Delphi: <c>TCommCamera.SaveCameraData</c>
    /// </summary>
    private void SaveCameraData(int channel, CameraDataBuffer cameraData, bool isTemplate)
    {
        try
        {
            var cbDataPath = _config.SystemInfo is { } si
                ? _pathManager.Resolve("DATA\\CB_DATA\\")
                : _pathManager.DataDir;

            var dateSubDir = Path.Combine(cbDataPath, DateTime.Now.ToString("yyyyMMdd"));
            _pathManager.EnsureDirectory(dateSubDir);

            var timestamp = DateTime.Now.ToString("yyyyMMddHHmmss_");
            var suffix = isTemplate ? $"_CH{channel + 1}_Template.bin" : $"_CH{channel + 1}.bin";
            var fileName = Path.Combine(dateSubDir, timestamp + CommandData[channel].PID + suffix);

            File.WriteAllBytes(fileName, cameraData.Data.AsSpan(0, cameraData.Size).ToArray());

            // Also save to base CB_DATA directory
            var baseSuffix = isTemplate ? $"CH{channel + 1}_Template.bin" : $"CH{channel + 1}.bin";
            var baseFileName = Path.Combine(cbDataPath, baseSuffix);

            var pgNo = channel + JigNo * 4;
            _logger.Debug(pgNo, $"SaveCameraData: {baseFileName}");

            File.WriteAllBytes(baseFileName, cameraData.Data.AsSpan(0, cameraData.Size).ToArray());
        }
        catch (Exception ex)
        {
            _logger.Error(channel, $"[Camera] SaveCameraData failed: {ex.Message}", ex);
        }
    }

    // =====================================================================
    // Utility methods
    // =====================================================================

    /// <summary>
    /// Calculates the checksum: sum of each byte of the 4-byte size value.
    /// Original Delphi: <c>TCommCamera.CalcChecksum</c>
    /// </summary>
    private static int CalcChecksum(int size)
    {
        return ((size >> 24) & 0xFF)
             + ((size >> 16) & 0xFF)
             + ((size >> 8) & 0xFF)
             + (size & 0xFF);
    }

    /// <summary>
    /// Converts a byte buffer to string for logging (limited length).
    /// Original Delphi: <c>TCommCamera.BufferToString</c>
    /// </summary>
    private static string BufferToString(byte[] buffer, int limit)
    {
        var sb = new StringBuilder();
        foreach (var b in buffer)
        {
            sb.Append((char)b);
            if (sb.Length > limit) break;
        }

        return sb.ToString();
    }

    /// <summary>
    /// Checks if all used channels have light in the specified state.
    /// Original Delphi: <c>TCommCamera.CheckLightSourceStateAll</c>
    /// </summary>
    private bool CheckLightSourceStateAll(bool allOn)
    {
        for (var i = 0; i < CameraConstants.ChannelCount; i++)
        {
            if (!_statusService.GetChannelEnabled(i + JigNo * 4))
                continue;

            if (allOn && _lightState[i] == 0)
                return false;

            if (!allOn && _lightState[i] == 1)
                return false;
        }

        return true;
    }

    /// <summary>
    /// Gets channel index from port number.
    /// Original Delphi: <c>TCommCamera.GetChannelByPort</c>
    /// </summary>
    private static int GetChannelByPort(int port)
    {
        return port - CameraConstants.BaseCameraPort;
    }

    // =====================================================================
    // Messaging helpers
    // =====================================================================

    /// <summary>
    /// Publishes a camera event to the message bus targeting the main form.
    /// Replaces Delphi: <c>TCommCamera.SendMessageMain</c> (WM_COPYDATA to m_hMain).
    /// </summary>
    private void PublishMainEvent(int mode, int channel, int param, int param2, string message)
    {
        _messageBus.Publish(new CameraEventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            Param2 = param2,
            Message = message,
        });
    }

    /// <summary>
    /// Publishes a camera event to the message bus targeting the test form.
    /// Replaces Delphi: <c>TCommCamera.SendMessageTest</c> (WM_COPYDATA to m_hTest).
    /// </summary>
    private void PublishTestEvent(int mode, int channel, int param, int param2, string message)
    {
        _messageBus.Publish(new CameraEventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            Param2 = param2,
            Message = message,
        });
    }

    // =====================================================================
    // Heartbeat timer
    // =====================================================================

    /// <summary>
    /// Heartbeat timer callback. Sends PING to all channels if idle for > 10 seconds.
    /// Original Delphi: <c>TCommCamera.tmrHearBeatTimer</c>
    /// <para>
    /// SendCommand is synchronous and waits up to 3s per channel for a reply, so
    /// running it inline on the timer thread can block for up to 12s, blocking
    /// other timer callbacks. We dispatch to the thread pool so the timer thread
    /// returns immediately.
    /// </para>
    /// </summary>
    private void HeartbeatTimerCallback(object? state)
    {
        if (_disposed) return;

        var elapsed = (uint)Environment.TickCount - _tickLast;
        if (elapsed <= 10000) return;

        // Fire-and-forget on the thread pool — must not block the timer thread.
        Task.Run(() =>
        {
            for (var i = 0; i < CameraConstants.ChannelCount; i++)
            {
                if (_disposed) return;
                try
                {
                    SendCommand(i, "PING");
                }
                catch (Exception ex)
                {
                    _logger.Error(i, $"[Camera] Heartbeat PING failed: {ex.Message}", ex);
                }
            }
        });
    }

    // =====================================================================
    // Connection management
    // =====================================================================

    /// <summary>
    /// Disconnects the client on a specific channel.
    /// </summary>
    private void DisconnectClient(int channel)
    {
        try
        {
            _streams[channel]?.Dispose();
        }
        catch { /* ignore */ }
        _streams[channel] = null;

        try
        {
            _clients[channel]?.Close();
            _clients[channel]?.Dispose();
        }
        catch { /* ignore */ }
        _clients[channel] = null;
    }

    // =====================================================================
    // Dispose
    // =====================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        // Stop heartbeat
        _heartbeatTimer?.Dispose();
        _heartbeatTimer = null;

        // Phase 1: Signal cancellation to accept loops and tear down sockets.
        // Stopping the TcpListener and disposing the client stream causes
        // pending AcceptTcpClientAsync / ReadAsync calls to throw and the
        // background tasks to exit their loops cleanly.
        for (var i = CameraConstants.MaxCountCamera; i >= 0; i--)
        {
            try { _listenerCts[i].Cancel(); }
            catch { /* ignore */ }

            lock (_channelLocks[i])
            {
                DisconnectClient(i);
            }

            try { _listeners[i]?.Stop(); }
            catch { /* ignore */ }
            _listeners[i] = null;
        }

        // Phase 2: Await the accept loops (with a bounded timeout) so they
        // observably finish before we dispose the resources they may touch.
        // Without this, AcceptClientsAsync / ReadClientDataAsync could still
        // be running when Dispose returns and reference disposed
        // ManualResetEventSlim / CancellationTokenSource instances.
        try
        {
            var pending = _acceptTasks
                .Where(t => t is not null)
                .Select(t => t!)
                .ToArray();
            if (pending.Length > 0)
                Task.WaitAll(pending, TimeSpan.FromSeconds(3));
        }
        catch (AggregateException) { /* expected on cancel */ }
        catch (Exception ex)
        {
            _logger.Warn($"[Camera] Dispose: accept-loop wait error: {ex.Message}");
        }

        // Phase 3: Final cleanup of synchronization primitives now that no
        // background task is still using them.
        for (var i = CameraConstants.MaxCountCamera; i >= 0; i--)
        {
            try { _listenerCts[i].Dispose(); } catch { /* ignore */ }
            try { _commandEvents[i].Dispose(); } catch { /* ignore */ }
            _acceptTasks[i] = null;
        }
    }
}
