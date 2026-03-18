// =============================================================================
// DaeDioDriver.cs
// Low-level UDP-based communication driver for DAE digital I/O devices (DJ596-DIO).
// Converted from Delphi: src_X3584\CommDIO_DAE.pas (TCommDIOThread, 1814 lines)
// Namespace: Dongaeltek.ITOLED.Hardware.Dio
//
// Architecture:
//   - Background Task replaces Delphi TThread.Execute polling loop
//   - UdpClient replaces TIdUDPServer/TIdUDPClient pair
//   - ManualResetEventSlim replaces Windows Event for command ack synchronization
//   - IMessageBus replaces WM_COPYDATA inter-form messaging
//   - ILogger replaces direct AddLog/SaveLog file operations
//
// Protocol:
//   - Custom binary header: [ID:2][Len:2][Data:Len]
//   - Commands: Connect(0x02), HeartBeat(0x02), ReadDI(0x10), ReadDO(0x12),
//               ClearDO(0x20), WriteDO(0x22), WriteBit(0x24), Version(0xA0),
//               FileDownload(0xF0), Config(0xF2)
//   - Response ID = CommandID + 1
//   - DI data: N bytes (up to 12 = 96 channels), change detection via comparison
//   - DO data: N bytes (up to 12 = 96 channels), flush buffer for last written state
// =============================================================================

using System.Net.Sockets;
using System.Text;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Messaging;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Dio;

// =============================================================================
// Protocol Constants
// =============================================================================

/// <summary>
/// Internal protocol constants for the DAE DIO UDP protocol.
/// <para>Delphi origin: <c>CommDIO_DAE.pas</c> implementation const block.</para>
/// </summary>
internal static class DioProtocol
{
    // ---- Command IDs (sent to device) ----
    /// <summary>Delphi: COMMDIO_ID_FIRSTCONNECTION = 1</summary>
    public const ushort IdFirstConnection = 0x0001;

    /// <summary>Delphi: COMMDIO_ID_CONNECTION = 2</summary>
    public const ushort IdConnection = 0x0002;

    /// <summary>Delphi: COMMDIO_ID_EVENTNOTIFY = 4</summary>
    public const ushort IdEventNotify = 0x0004;

    /// <summary>Delphi: COMMDIO_ID_READ_DI = $10</summary>
    public const ushort IdReadDi = 0x0010;

    /// <summary>Delphi: COMMDIO_ID_READ_DO = $12</summary>
    public const ushort IdReadDo = 0x0012;

    /// <summary>Delphi: COMMDIO_ID_CLEARDO = $20</summary>
    public const ushort IdClearDo = 0x0020;

    /// <summary>Delphi: COMMDIO_ID_WRITE_DO = $22</summary>
    public const ushort IdWriteDo = 0x0022;

    /// <summary>Delphi: COMMDIO_ID_WRITE_BIT = $24</summary>
    public const ushort IdWriteBit = 0x0024;

    /// <summary>Delphi: COMMDIO_ID_VERSION = $A0</summary>
    public const ushort IdVersion = 0x00A0;

    /// <summary>Delphi: COMMDIO_ID_FILEDOWNLOAD = $F0</summary>
    public const ushort IdFileDownload = 0x00F0;

    /// <summary>Delphi: COMMDIO_ID_CONFIG = $F2</summary>
    public const ushort IdConfig = 0x00F2;
}

/// <summary>
/// Message mode constants for DIO notifications.
/// <para>Delphi origin: COMMDIO_MSG_xxx constants in CommDIO_DAE.pas.</para>
/// </summary>
internal static class DioMsgMode
{
    /// <summary>Delphi: COMMDIO_MSG_NONE = 100</summary>
    public const int None = 100;

    /// <summary>Delphi: COMMDIO_MSG_CONNECT = 101</summary>
    public const int Connect = 101;

    /// <summary>Delphi: COMMDIO_MSG_HEARTBEAT = 102</summary>
    public const int Heartbeat = 102;

    /// <summary>Delphi: COMMDIO_MSG_CHANGE_DI = 103</summary>
    public const int ChangeDi = 103;

    /// <summary>Delphi: COMMDIO_MSG_CHANGE_DO = 104</summary>
    public const int ChangeDo = 104;

    /// <summary>Delphi: COMMDIO_MSG_LOG = 105</summary>
    public const int Log = 105;

    /// <summary>Delphi: COMMDIO_MSG_LOG_CH = 106</summary>
    public const int LogChannel = 106;

    /// <summary>Delphi: COMMDIO_MSG_ERROR = 200</summary>
    public const int Error = 200;
}

// =============================================================================
// Device Info Record
// =============================================================================

/// <summary>
/// Device information and version data returned by the DIO device.
/// <para>Delphi origin: <c>TDIODeviceInfo</c> packed record.</para>
/// </summary>
internal sealed class DioDeviceInfo
{
    public ushort Ack { get; set; }
    public uint DeviceIp { get; set; }
    public uint DevicePort { get; set; }
    public uint ServerIp { get; set; }
    public uint ServerPort { get; set; }
    public byte Count { get; set; }
    public uint[] Versions { get; set; } = [];
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// UDP-based communication driver for DAE DJ596-DIO digital I/O devices.
/// Replaces Delphi's <c>TCommDIOThread</c> class (CommDaeDIO global variable).
/// <para>
/// The driver runs a background polling loop that periodically reads DI data,
/// flushes DO data (in flush mode), and monitors connection health via heartbeat.
/// WM_COPYDATA messaging is replaced with <see cref="IMessageBus"/> publishing
/// <see cref="DioEventMessage"/> instances and C# events.
/// </para>
/// </summary>
public sealed class DaeDioDriver : IDaeDioDriver
{
    // =========================================================================
    // Constants
    // =========================================================================

    /// <summary>
    /// Maximum number of DIO device bytes (OC inspector mode = 12 bytes = 96 channels).
    /// <para>Delphi origin: MAX_DIO_DEVICE_COUNT = 12 (INSPECTOR_OC)</para>
    /// </summary>
    private const int MaxDioDeviceCount = 12;

    /// <summary>Header size: ID(2) + Len(2) = 4 bytes.</summary>
    private const int HeaderSize = 4;

    // =========================================================================
    // Dependencies
    // =========================================================================

    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;

    // =========================================================================
    // Configuration Fields
    // =========================================================================

    private readonly int _deviceCount;
    private readonly int _serverPort;
    private readonly bool _useFlushMode;
    private byte _pollingMode;

    // =========================================================================
    // Network
    // =========================================================================

    private UdpClient? _udpListener;
    private UdpClient? _udpSender;
    private readonly object _sendLock = new();

    // =========================================================================
    // Thread / Lifecycle
    // =========================================================================

    private CancellationTokenSource? _cts;
    private Task? _pollingTask;
    private Task? _receiveTask;
    private volatile bool _disposed;
    private volatile int _stopped;

    // =========================================================================
    // Command Ack Synchronization
    // =========================================================================

    /// <summary>
    /// Replaces Delphi's <c>m_hEventCommand</c> (Windows Event object)
    /// for synchronous command-ack waiting.
    /// </summary>
    private readonly ManualResetEventSlim _commandAckEvent = new(false);

    private ushort _lastAck;

    // =========================================================================
    // Timing (tick-based, using Environment.TickCount64)
    // =========================================================================

    private long _lastTickRecv;
    private long _lastTickSend;

    // =========================================================================
    // State
    // =========================================================================

    private volatile bool _connected;
    private volatile bool _firstConnection;
    private volatile bool _working;
    private bool _connectionError;
    private int _checkTime;

    // =========================================================================
    // DI/DO Data Buffers
    // =========================================================================

    /// <summary>Current DI data. Delphi: DIData</summary>
    private readonly byte[] _diData;

    /// <summary>Previous DI data for change detection. Delphi: DIDataPre</summary>
    private readonly byte[] _diDataPre;

    /// <summary>Current DO data (confirmed by device). Delphi: DOData</summary>
    private readonly byte[] _doData;

    /// <summary>DO flush buffer (pending writes). Delphi: DODataFlush</summary>
    private readonly byte[] _doDataFlush;

    /// <summary>Device information and version data.</summary>
    private readonly DioDeviceInfo _deviceInfo = new();

    // =========================================================================
    // Tower Lamp
    // =========================================================================

    private int _towerLampState;
    private long _towerLampTick;

    // =========================================================================
    // Receive buffer for synchronous read operations
    // =========================================================================

    private byte[]? _recvBuffer;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a new DAE DIO driver instance.
    /// <para>Delphi origin: <c>TCommDIOThread.Create(hMain, nMsgType, nServerPort, nDeviceCount, bFlushMode, nPollingMode, nLogSaveMode)</c></para>
    /// </summary>
    /// <param name="messageBus">Message bus replacing WM_COPYDATA for UI notifications.</param>
    /// <param name="logger">Application logger.</param>
    /// <param name="serverPort">Local UDP port to listen on. Delphi default: 6989.</param>
    /// <param name="deviceCount">Number of DIO device bytes (1..12). Delphi default: 1.</param>
    /// <param name="useFlushMode">True for flush mode (buffered DO writes). Delphi default: false.</param>
    /// <param name="pollingMode">DI polling mode. 0=None, 1=Polling, 2=EventNotify, 3=Both. Delphi default: 1.</param>
    public DaeDioDriver(
        IMessageBus messageBus,
        ILogger logger,
        int serverPort = 6989,
        int deviceCount = 1,
        bool useFlushMode = false,
        byte pollingMode = 1)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        _serverPort = serverPort;
        _deviceCount = Math.Clamp(deviceCount, 1, MaxDioDeviceCount);
        _useFlushMode = useFlushMode;
        _pollingMode = pollingMode;

        // Configuration defaults (Delphi constructor)
        PollingInterval = 1000;
        FlushReadInterval = 50;
        HeartBeatPeriod = 1000;
        ExpirationPeriod = 20000;
        ConnectionTimeout = 7000;
        LogLevel = 0;

        DeviceIp = "192.168.0.99";
        DevicePort = 6989;

        // Allocate DI/DO buffers
        _diData = new byte[_deviceCount];
        _diDataPre = new byte[_deviceCount];
        _doData = new byte[_deviceCount];
        _doDataFlush = new byte[_deviceCount];

        var tickNow = Environment.TickCount64;
        _lastTickRecv = tickNow;
        _lastTickSend = tickNow;
        _towerLampTick = tickNow;

        _logger.Info($"DaeDioDriver: Create ServerPort={serverPort}, DeviceCount={deviceCount}, " +
                     $"FlushMode={useFlushMode}, PollingMode={pollingMode}");
    }

    // =========================================================================
    // IDaeDioDriver Properties
    // =========================================================================

    /// <inheritdoc />
    public bool Connected => _connected;

    /// <inheritdoc />
    public string DeviceIp { get; set; }

    /// <inheritdoc />
    public int DevicePort { get; set; }

    /// <inheritdoc />
    public int PollingInterval { get; set; }

    /// <inheritdoc />
    public string LogPath { get; set; } = string.Empty;

    /// <inheritdoc />
    public int LogLevel { get; set; }

    // =========================================================================
    // Additional Configuration Properties
    // =========================================================================

    /// <summary>
    /// Interval (ms) to sleep between flush write and DI read.
    /// <para>Delphi origin: FlushReadInterval (default 50)</para>
    /// </summary>
    public int FlushReadInterval { get; set; }

    /// <summary>
    /// Heartbeat send period in ms when idle.
    /// <para>Delphi origin: HeartBeatPeriod (default 1000)</para>
    /// </summary>
    public int HeartBeatPeriod { get; set; }

    /// <summary>
    /// Connection expiration period in ms. Lost connection if no recv within this period.
    /// <para>Delphi origin: ExpirationPeriod (default 20000)</para>
    /// </summary>
    public int ExpirationPeriod { get; set; }

    /// <summary>
    /// Connection timeout in ms for initial connection.
    /// <para>Delphi origin: ConnectionTimeout (default 7000)</para>
    /// </summary>
    public uint ConnectionTimeout { get; set; }

    /// <summary>
    /// Whether the initial connection attempt failed.
    /// <para>Delphi origin: ConnectionError</para>
    /// </summary>
    public bool ConnectionError => _connectionError;

    /// <summary>
    /// Simulation mode flag.
    /// <para>Delphi origin: UseSimulator</para>
    /// </summary>
    public bool UseSimulator { get; set; }

    // =========================================================================
    // IDaeDioDriver Events
    // =========================================================================

    /// <inheritdoc />
    public event EventHandler<DioNotifyEventArgs>? OnConnect;

    /// <inheritdoc />
    public event EventHandler<DioNotifyEventArgs>? OnInputChanged;

    /// <inheritdoc />
    public event EventHandler<DioNotifyEventArgs>? OnOutputChanged;

    /// <inheritdoc />
    public event EventHandler<DioNotifyEventArgs>? OnError;

    // =========================================================================
    // IDaeDioDriver - Digital Input Access
    // =========================================================================

    /// <inheritdoc />
    public byte GetInputByte(int byteIndex)
    {
        if (byteIndex < 0 || byteIndex >= _deviceCount)
            return 0;
        return _diData[byteIndex];
    }

    /// <inheritdoc />
    public bool GetInputBit(int signalIndex)
    {
        var byteIdx = signalIndex / 8;
        var bitIdx = signalIndex % 8;
        if (byteIdx < 0 || byteIdx >= _deviceCount)
            return false;
        return ((_diData[byteIdx] >> bitIdx) & 0x01) == 1;
    }

    // =========================================================================
    // IDaeDioDriver - Digital Output Access
    // =========================================================================

    /// <inheritdoc />
    public byte GetOutputFlushByte(int byteIndex)
    {
        if (byteIndex < 0 || byteIndex >= _deviceCount)
            return 0;
        return _doDataFlush[byteIndex];
    }

    /// <inheritdoc />
    public bool GetOutputBit(int signalIndex)
    {
        var byteIdx = signalIndex / 8;
        var bitIdx = signalIndex % 8;
        if (byteIdx < 0 || byteIdx >= _deviceCount)
            return false;
        return ((_doDataFlush[byteIdx] >> bitIdx) & 0x01) == 1;
    }

    // =========================================================================
    // IDaeDioDriver - Digital Output Write
    // =========================================================================

    /// <inheritdoc />
    public void WriteOutputBit(int byteIndex, int bitPosition, int value)
    {
        WriteDoBit((byte)byteIndex, (byte)bitPosition, (byte)value);
    }

    // =========================================================================
    // Lifecycle: Start / Stop
    // =========================================================================

    /// <inheritdoc />
    public void Start()
    {
        if (_disposed) throw new ObjectDisposedException(nameof(DaeDioDriver));
        if (_pollingTask is not null) return; // already running

        _stopped = 0;
        _cts = new CancellationTokenSource();

        try
        {
            // Create UDP listener (replaces TIdUDPServer)
            _udpListener = new UdpClient(_serverPort);
            _udpListener.Client.ReceiveTimeout = 500;

            // Create UDP sender (replaces TIdUDPClient)
            _udpSender = new UdpClient();

            _logger.Info($"DaeDioDriver: Started on port {_serverPort}");
        }
        catch (Exception ex)
        {
            _logger.Error($"DaeDioDriver: Cannot create UDP socket: {ex.Message}", ex);
            RaiseError(0, $"Cannot create UDP socket: {ex.Message}");
            return;
        }

        // Start background receive task
        var ct = _cts.Token;
        _receiveTask = Task.Run(() => ReceiveLoop(ct), ct)
            .ContinueWith(t =>
            {
                if (t.IsFaulted)
                    _logger.Error($"DaeDioDriver ReceiveLoop crashed: {t.Exception?.InnerException?.Message}",
                        t.Exception?.InnerException!);
            }, TaskContinuationOptions.OnlyOnFaulted);

        // Start polling task (replaces TThread.Execute)
        _pollingTask = Task.Run(() => PollingLoop(ct), ct);
    }

    /// <inheritdoc />
    public void Stop()
    {
        Interlocked.Exchange(ref _stopped, 1);
        _connected = false;

        _cts?.Cancel();

        try
        {
            _pollingTask?.Wait(TimeSpan.FromSeconds(5));
        }
        catch (AggregateException)
        {
            // Expected on cancellation
        }

        CleanupNetwork();

        try
        {
            _receiveTask?.Wait(TimeSpan.FromSeconds(3));
        }
        catch (AggregateException)
        {
            // Expected on cancellation
        }

        _commandAckEvent.Set(); // Unblock any waiting threads
        _pollingTask = null;
        _receiveTask = null;
        _cts?.Dispose();
        _cts = null;

        _logger.Info("DaeDioDriver: Stopped");
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        Stop();
        _commandAckEvent.Dispose();
    }

    // =========================================================================
    // Public Read/Write Operations
    // =========================================================================

    /// <summary>
    /// Reads DI data from the device.
    /// <para>Delphi origin: <c>TCommDIOThread.ReadDI</c></para>
    /// </summary>
    /// <param name="addr">Starting byte address.</param>
    /// <param name="count">Number of bytes to read.</param>
    /// <param name="values">Output buffer for read values (only filled when waitReply=true).</param>
    /// <param name="waitReply">If true, blocks until device responds.</param>
    /// <returns>0=success, 1=not connected, 2=invalid address.</returns>
    public int ReadDi(byte addr, byte count, out byte[] values, bool waitReply = false)
    {
        values = [];
        if (!_connected) return 1;
        if (addr > _deviceCount - 1) return 2;

        if ((LogLevel & 0x02) == 0x02)
            _logger.Debug($"DaeDioDriver: ReadDI Addr={addr}, Count={count}");

        if (!waitReply)
        {
            return SendReadDi(addr, count);
        }

        values = new byte[count];
        _recvBuffer = values;
        try
        {
            var result = WaitForCommandAck(() => SendReadDi(addr, count));
            return (int)result;
        }
        finally
        {
            _recvBuffer = null;
        }
    }

    /// <summary>
    /// Reads DO data from the device.
    /// <para>Delphi origin: <c>TCommDIOThread.ReadDO</c></para>
    /// </summary>
    /// <param name="addr">Starting byte address.</param>
    /// <param name="count">Number of bytes to read.</param>
    /// <param name="waitReply">If true, blocks until device responds.</param>
    /// <returns>0=success, 1=not connected, 2=invalid address.</returns>
    public int ReadDo(byte addr, byte count, bool waitReply = false)
    {
        if (!_connected) return 1;
        if (addr > _deviceCount - 1) return 2;

        if ((LogLevel & 0x02) == 0x02)
            _logger.Debug($"DaeDioDriver: ReadDO Addr={addr}, Count={count}");

        if (!waitReply)
        {
            return SendReadDo(addr, count);
        }

        return (int)WaitForCommandAck(() => SendReadDo(addr, count));
    }

    /// <summary>
    /// Clears (zeroes) DO data on the device.
    /// <para>Delphi origin: <c>TCommDIOThread.ClearDO</c></para>
    /// </summary>
    /// <param name="addr">Starting byte address.</param>
    /// <param name="count">Number of bytes to clear.</param>
    /// <param name="waitReply">If true, blocks until device responds.</param>
    /// <returns>0=success, 1=not connected, 2=invalid address.</returns>
    public int ClearDo(byte addr, byte count, bool waitReply = false)
    {
        if (!_connected) return 1;
        if (addr > _deviceCount - 1) return 2;

        if ((LogLevel & 0x01) == 0x01)
            _logger.Debug($"DaeDioDriver: ClearDO Addr={addr}, Count={count}");

        // Flush mode: just zero the flush buffer
        if (_useFlushMode)
        {
            lock (_sendLock)
            {
                Array.Clear(_doDataFlush, addr, count);
            }
            return 0;
        }

        if (!waitReply)
        {
            var ret = SendClearDo(addr, count);
            if (ret == 0)
            {
                Array.Clear(_doData, addr, count);
                Array.Clear(_doDataFlush, addr, count); // keep flush buffer in sync
            }
            return ret;
        }

        var result = WaitForCommandAck(() => SendClearDo(addr, count));
        if (result == WaitResult.Success)
        {
            Array.Clear(_doData, addr, count);
            Array.Clear(_doDataFlush, addr, count); // keep flush buffer in sync
        }
        return (int)result;
    }

    /// <summary>
    /// Writes DO data bytes to the device.
    /// <para>Delphi origin: <c>TCommDIOThread.WriteDO</c></para>
    /// </summary>
    /// <param name="addr">Starting byte address.</param>
    /// <param name="count">Number of bytes to write.</param>
    /// <param name="values">Byte values to write.</param>
    /// <param name="waitReply">If true, blocks until device responds.</param>
    /// <returns>0=success, 1=not connected, 2=invalid address.</returns>
    public int WriteDo(byte addr, byte count, byte[] values, bool waitReply = false)
    {
        if (!_connected) return 1;
        if (addr > _deviceCount - 1) return 2;

        if ((LogLevel & 0x01) == 0x01)
        {
            var dataStr = string.Join(" ", values.Select(v => v.ToString()));
            _logger.Debug($"DaeDioDriver: WriteDO Addr={addr}, Count={count}, Data={dataStr}");
        }

        // Flush mode: update the flush buffer only
        if (_useFlushMode)
        {
            lock (_sendLock)
            {
                Buffer.BlockCopy(values, 0, _doDataFlush, addr, count);
            }
            return 0;
        }

        if (!waitReply)
        {
            var ret = SendWriteDo(addr, count, values);
            if (ret == 0)
            {
                Buffer.BlockCopy(values, 0, _doData, addr, count);
                Buffer.BlockCopy(values, 0, _doDataFlush, addr, count); // keep flush buffer in sync
            }
            return ret;
        }

        var result = WaitForCommandAck(() => SendWriteDo(addr, count, values));
        if (result == WaitResult.Success)
        {
            Buffer.BlockCopy(values, 0, _doData, addr, count);
            Buffer.BlockCopy(values, 0, _doDataFlush, addr, count); // keep flush buffer in sync
        }
        return (int)result;
    }

    /// <summary>
    /// Writes a single DO bit.
    /// <para>Delphi origin: <c>TCommDIOThread.WriteDO_Bit</c></para>
    /// </summary>
    /// <param name="addr">Byte address.</param>
    /// <param name="bitLoc">Bit position within byte (0-7).</param>
    /// <param name="value">Bit value (0 or 1).</param>
    /// <param name="waitReply">If true, blocks until device responds.</param>
    /// <returns>0=success, 1=not connected, 2=invalid address, 3=invalid bit location.</returns>
    public int WriteDoBit(byte addr, byte bitLoc, byte value, bool waitReply = false)
    {
        if (!_connected) return 1;
        if (addr > _deviceCount - 1) return 2;
        if (bitLoc > 7) return 3;

        if ((LogLevel & 0x01) == 0x01)
            _logger.Debug($"DaeDioDriver: WriteDO_Bit Addr={addr}, BitLoc={bitLoc}, Data={value}");

        // Flush mode: update the flush buffer only
        if (_useFlushMode)
        {
            lock (_sendLock)
            {
                SetBit(ref _doDataFlush[addr], bitLoc, value);
            }
            return 0;
        }

        if (!waitReply)
        {
            var ret = SendWriteBit(addr, bitLoc, value);
            if (ret == 0)
            {
                SetBit(ref _doData[addr], bitLoc, value);
                SetBit(ref _doDataFlush[addr], bitLoc, value); // keep flush buffer in sync
            }
            return ret;
        }

        var result = WaitForCommandAck(() => SendWriteBit(addr, bitLoc, value));
        if (result == WaitResult.Success)
        {
            SetBit(ref _doData[addr], bitLoc, value);
            SetBit(ref _doDataFlush[addr], bitLoc, value); // keep flush buffer in sync
        }
        return (int)result;
    }

    /// <summary>
    /// Writes a DO bit in the flush buffer only (no immediate device write).
    /// <para>Delphi origin: <c>TCommDIOThread.WriteDO_FlushBit</c></para>
    /// </summary>
    /// <param name="addr">Byte address.</param>
    /// <param name="bitLoc">Bit position (0-7).</param>
    /// <param name="value">Bit value (0 or 1).</param>
    /// <returns>0=success, 1=not connected, 2=invalid address, 3=invalid bit, 4=not flush mode.</returns>
    public int WriteDoFlushBit(byte addr, byte bitLoc, byte value)
    {
        if (!_connected) return 1;
        if (addr > _deviceCount - 1) return 2;
        if (bitLoc > 7) return 3;
        if (!_useFlushMode) return 4;

        if ((LogLevel & 0x01) == 0x01)
            _logger.Debug($"DaeDioDriver: WriteDO_FlushBit Addr={addr}, BitLoc={bitLoc}, Data={value}");

        lock (_sendLock)
        {
            SetBit(ref _doDataFlush[addr], bitLoc, value);
        }
        return 0;
    }

    /// <summary>
    /// Configures the DIO event notification mode on the device.
    /// <para>Delphi origin: <c>TCommDIOThread.WriteEventNotify</c></para>
    /// </summary>
    /// <param name="value">Notification mode value.</param>
    /// <returns>0=success, 1=not connected.</returns>
    public int WriteEventNotify(byte value)
    {
        if (!_connected) return 1;
        var ret = SendEventNotify(value);
        if (ret == 0)
            SetBit(ref _pollingMode, 1, value);
        return ret;
    }

    /// <summary>
    /// Sends an arbitrary binary buffer to the device.
    /// <para>Delphi origin: <c>TCommDIOThread.SendBuffer</c></para>
    /// </summary>
    /// <param name="data">Raw bytes to send.</param>
    /// <returns>0=success.</returns>
    public int SendBuffer(byte[] data) => SendData(data);

    /// <summary>
    /// Waits for a specific DI bit to reach a target value.
    /// <para>Delphi origin: <c>TCommDIOThread.WaitSignal</c></para>
    /// </summary>
    /// <param name="addr">Byte address.</param>
    /// <param name="bitLoc">Bit position (0-7).</param>
    /// <param name="value">Target bit value (0 or 1).</param>
    /// <param name="waitTimeMs">Maximum wait time in milliseconds.</param>
    /// <returns>0=signal matched, 1=timeout.</returns>
    public int WaitSignal(byte addr, byte bitLoc, byte value, int waitTimeMs)
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();
        var spinWait = new SpinWait();
        while (sw.ElapsedMilliseconds < waitTimeMs)
        {
            if (GetBit(_diData[addr], bitLoc) == value)
                return 0;
            spinWait.SpinOnce();
        }
        return 1;
    }

    /// <summary>
    /// Sets the tower lamp state.
    /// <para>Delphi origin: <c>TCommDIOThread.Set_TowerLampState</c></para>
    /// </summary>
    /// <param name="state">Tower lamp state code (0=off, 2=red, 4=green blink, 8=green, 16=yellow blink, 32=red blink, 64=red on).</param>
    public void SetTowerLampState(int state)
    {
        _towerLampState = state;
        ProcessTowerLamp();
    }

    // =========================================================================
    // Bit Manipulation Helpers
    // =========================================================================

    /// <summary>
    /// Gets a single bit from a byte.
    /// <para>Delphi origin: <c>TCommDIOThread.Get_Bit</c></para>
    /// </summary>
    public static byte GetBit(byte data, int loc)
        => (byte)((data >> loc) & 0x01);

    /// <summary>
    /// Sets or clears a single bit in a byte.
    /// <para>Delphi origin: <c>TCommDIOThread.Set_Bit</c></para>
    /// </summary>
    public static void SetBit(ref byte data, int loc, byte value)
    {
        if (value == 0)
            data = (byte)(data & ~(1 << loc));
        else
            data = (byte)(data | (1 << loc));
    }

    /// <summary>
    /// Checks whether a DI bit is on by byte address and bit position.
    /// <para>Delphi origin: <c>TCommDIOThread.IsDIOn(nAddr, nLoc)</c></para>
    /// </summary>
    public bool IsDiOn(byte addr, byte loc)
    {
        if (addr >= _deviceCount) return false;
        if (loc > 7) return false;
        return ((_diData[addr] >> loc) & 0x01) == 1;
    }

    /// <summary>
    /// Checks whether a DI bit is on by signal index.
    /// <para>Delphi origin: <c>TCommDIOThread.IsDIOn(nIndex)</c></para>
    /// </summary>
    public bool IsDiOn(int index)
        => IsDiOn((byte)(index / 8), (byte)(index % 8));

    // =========================================================================
    // IP Conversion Helpers
    // =========================================================================

    /// <summary>
    /// Converts an IP address string to a uint (network byte order, big-endian).
    /// <para>Delphi origin: <c>TCommDIOThread.IP2Int</c></para>
    /// </summary>
    public static uint IpToUint(string ip)
    {
        var parts = ip.Split('.');
        if (parts.Length != 4) return 0;
        uint result = 0;
        for (var i = 0; i < 4; i++)
        {
            if (!uint.TryParse(parts[i], out var v) || v > 255)
                return 0;
            result += v << ((3 - i) * 8);
        }
        return result;
    }

    /// <summary>
    /// Converts a uint IP to string representation.
    /// <para>Delphi origin: <c>TCommDIOThread.Int2IP</c></para>
    /// </summary>
    public static string UintToIp(uint ip)
    {
        if (ip >= 0xFFFFFFFF)
            return "255.255.255.255";
        return $"{(ip >> 24) & 0xFF}.{(ip >> 16) & 0xFF}.{(ip >> 8) & 0xFF}.{ip & 0xFF}";
    }

    // =========================================================================
    // Background Polling Loop (replaces TThread.Execute)
    // =========================================================================

    /// <summary>
    /// Main polling loop that runs on a background task.
    /// Mirrors Delphi's <c>TCommDIOThread.Execute</c> method.
    /// </summary>
    private async Task PollingLoop(CancellationToken ct)
    {
        _logger.Debug("DaeDioDriver: Polling loop started");

        while (!ct.IsCancellationRequested && _stopped == 0)
        {
            try
            {
                var tickNow = Environment.TickCount64;

                // Wait for first connection
                if (!_firstConnection)
                {
                    if (!_connectionError && tickNow > _lastTickRecv + ConnectionTimeout)
                    {
                        _logger.Warn("DaeDioDriver: Cannot connect");
                        RaiseError(100, $"Cannot connect ({DateTime.Now:HH:mm:ss.fff})");
                        _connectionError = true;
                    }
                    await Task.Delay(PollingInterval, ct);
                    continue;
                }

                if (!_connected)
                {
                    await Task.Delay(PollingInterval, ct);
                    continue;
                }

                if (_working)
                {
                    await Task.Delay(PollingInterval, ct);
                    continue;
                }

                // Send heartbeat if idle too long
                if (tickNow > _lastTickSend + HeartBeatPeriod)
                {
                    SendHeartbeat();
                }

                // Check connection expiration
                if (tickNow > _lastTickRecv + ExpirationPeriod)
                {
                    _logger.Warn($"DaeDioDriver: Lost connection ({tickNow - _lastTickRecv}ms)");
                    _connected = false;
                    RaiseConnect(0, $"Lost connection ({DateTime.Now:HH:mm:ss.fff})");
                }

                // Flush mode: write pending DO data
                var flushChanged = 0;
                if (_useFlushMode)
                {
                    flushChanged = WriteFlushData();
                    if (flushChanged != 0 && FlushReadInterval != 0)
                    {
                        await Task.Delay(FlushReadInterval, ct);
                    }
                }

                // Polling mode: read DI data
                if (flushChanged != 0 || (_pollingMode & 0x01) == 0x01)
                {
                    ReadPollingData();
                }

                await Task.Delay(PollingInterval, ct);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.Error($"DaeDioDriver: Polling loop exception: {ex.Message}", ex);
                await Task.Delay(PollingInterval, ct);
            }
        }

        _logger.Debug("DaeDioDriver: Polling loop exited");
    }

    // =========================================================================
    // Background Receive Loop (replaces TIdUDPServer.OnUDPRead)
    // =========================================================================

    /// <summary>
    /// Background loop that receives UDP packets from the device.
    /// Replaces Delphi's <c>TIdUDPServer.OnUDPRead</c> event.
    /// </summary>
    private async Task ReceiveLoop(CancellationToken ct)
    {
        _logger.Debug("DaeDioDriver: Receive loop started");

        while (!ct.IsCancellationRequested && _stopped == 0)
        {
            try
            {
                if (_udpListener is null) break;

                UdpReceiveResult result;
                try
                {
                    result = await _udpListener.ReceiveAsync(ct);
                }
                catch (SocketException)
                {
                    continue; // Timeout or socket error
                }
                catch (OperationCanceledException)
                {
                    break;
                }

                ProcessReceivedData(result.Buffer);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.Error($"DaeDioDriver: Receive loop exception: {ex.Message}", ex);
            }
        }

        _logger.Debug("DaeDioDriver: Receive loop exited");
    }

    /// <summary>
    /// Processes a received UDP packet.
    /// <para>Delphi origin: <c>TCommDIOThread.UDPServerUDPRead</c></para>
    /// </summary>
    private void ProcessReceivedData(byte[] data)
    {
        if (_stopped != 0) return;
        if (data.Length < HeaderSize) return;

        // Parse header: [ID:2 LE][Len:2 LE]
        var id = BitConverter.ToUInt16(data, 0);
        var len = BitConverter.ToUInt16(data, 2);

        // Log received data (hex string, max 100 bytes)
        if ((LogLevel & 0x08) == 0x08)
        {
            var isPolling = id == (DioProtocol.IdReadDi + 1) &&
                            data.Length > 4 && data[4] == 0 && data[5] == _deviceCount;
            isPolling = isPolling || id == (DioProtocol.IdConnection + 1);
            if (!isPolling || (LogLevel & 0x10) == 0x10)
            {
                _logger.Debug($"DaeDioDriver: Recv({data.Length})<= {FormatHex(data)}");
            }
        }

        // Validate packet size
        if (len != data.Length - HeaderSize)
        {
            _logger.Warn($"DaeDioDriver: Size mismatch ({len + HeaderSize}:{data.Length}): {FormatHex(data)}");
            RaiseError(0, $"Size mismatch ({len + HeaderSize}:{data.Length})");
            return;
        }

        // First connection packet (device announcing itself)
        if (id == DioProtocol.IdFirstConnection)
        {
            ProcessConnection();
            return;
        }

        // Check Ack field (bytes 4-5 in data area)
        if (data.Length >= 6)
        {
            var ack = BitConverter.ToUInt16(data, 4);
            if (ack != 0 && id != DioProtocol.IdFirstConnection)
            {
                _commandAckEvent.Set();
                _logger.Warn($"DaeDioDriver: Ack Error ID:0x{id:X4} Ack:0x{ack:X4}");
                RaiseError(0, $"Ack Error ID:0x{id:X4} Ack:0x{ack:X4}");
                return;
            }
            _lastAck = ack;
        }

        _lastTickRecv = Environment.TickCount64;
        _connected = true;

        // Dispatch by response ID (command ID + 1)
        switch (id)
        {
            case DioProtocol.IdConnection + 1:
                // Heartbeat/connection response - nothing special
                break;

            case DioProtocol.IdEventNotify + 1:
                _commandAckEvent.Set();
                break;

            case DioProtocol.IdReadDi + 1:
                ProcessReadDiResponse(data);
                break;

            case DioProtocol.IdReadDo + 1:
                ProcessReadDoResponse(data);
                break;

            case DioProtocol.IdClearDo + 1:
                Array.Clear(_doData, 0, _deviceCount);
                _commandAckEvent.Set();
                break;

            case DioProtocol.IdWriteDo + 1:
                _commandAckEvent.Set();
                break;

            case DioProtocol.IdWriteBit + 1:
                _commandAckEvent.Set();
                break;

            case DioProtocol.IdVersion + 1:
                ProcessVersionResponse(data);
                break;

            case DioProtocol.IdFileDownload + 1:
                _commandAckEvent.Set();
                break;

            case DioProtocol.IdConfig + 1:
                _commandAckEvent.Set();
                break;
        }
    }

    /// <summary>
    /// Processes ReadDI response, updates DI buffers and detects changes.
    /// <para>Delphi origin: case COMMDIO_ID_READ_DI+1 in UDPServerUDPRead</para>
    /// </summary>
    private void ProcessReadDiResponse(byte[] data)
    {
        // Data layout: [ID:2][Len:2][Ack:2][Addr:1][Count:1][DIData:Count]
        if (data.Length < 8) return;
        var addr = data[6];
        var count = data[7];

        if (_recvBuffer is not null && data.Length >= 8 + count)
        {
            Buffer.BlockCopy(data, 8, _recvBuffer, 0, Math.Min(count, _recvBuffer.Length));
            _commandAckEvent.Set();
        }

        if (data.Length >= 8 + count && addr + count <= _deviceCount)
        {
            Buffer.BlockCopy(data, 8, _diData, addr, count);
        }

        ProcessPollingData();
    }

    /// <summary>
    /// Processes ReadDO response, updates DO buffer.
    /// <para>Delphi origin: case COMMDIO_ID_READ_DO+1 in UDPServerUDPRead</para>
    /// </summary>
    private void ProcessReadDoResponse(byte[] data)
    {
        // Data layout: [ID:2][Len:2][Ack:2][Addr:1][Count:1][DOData:Count]
        if (data.Length < 8) return;
        var addr = data[6];
        var count = data[7];

        if (_recvBuffer is not null && data.Length >= 8 + count)
        {
            Buffer.BlockCopy(data, 8, _recvBuffer, 0, Math.Min(count, _recvBuffer.Length));
        }

        if (data.Length >= 8 + count && addr + count <= _deviceCount)
        {
            Buffer.BlockCopy(data, 8, _doData, addr, count);
        }

        _commandAckEvent.Set();
    }

    /// <summary>
    /// Processes Version info response.
    /// <para>Delphi origin: case COMMDIO_ID_VERSION+1 in UDPServerUDPRead</para>
    /// </summary>
    private void ProcessVersionResponse(byte[] data)
    {
        // Version data starts at offset 4 (after header)
        if (data.Length < HeaderSize + 19) { _commandAckEvent.Set(); return; }

        var ofs = HeaderSize;
        _deviceInfo.Ack = BitConverter.ToUInt16(data, ofs); ofs += 2;
        _deviceInfo.DeviceIp = BitConverter.ToUInt32(data, ofs); ofs += 4;
        _deviceInfo.DevicePort = BitConverter.ToUInt32(data, ofs); ofs += 4;
        _deviceInfo.ServerIp = BitConverter.ToUInt32(data, ofs); ofs += 4;
        _deviceInfo.ServerPort = BitConverter.ToUInt32(data, ofs); ofs += 4;
        _deviceInfo.Count = data[ofs]; ofs += 1;

        var verCount = Math.Min(_deviceInfo.Count, (data.Length - ofs) / 4);
        _deviceInfo.Versions = new uint[verCount];
        for (var i = 0; i < verCount; i++)
        {
            _deviceInfo.Versions[i] = BitConverter.ToUInt32(data, ofs + i * 4);
        }

        _commandAckEvent.Set();
    }

    // =========================================================================
    // Connection Sequence
    // =========================================================================

    /// <summary>
    /// Handles the initial device connection sequence.
    /// <para>Delphi origin: <c>TCommDIOThread.ProcessConnection</c></para>
    /// </summary>
    private void ProcessConnection()
    {
        _logger.Info("DaeDioDriver: Processing connection...");

        // Run connection sequence on a background thread (mirrors Delphi TThread.CreateAnonymousThread)
        _ = Task.Run(async () =>
        {
            try
            {
                // Step 1: Send heartbeat
                SendHeartbeat();
                await Task.Delay(200);

                // Step 2: Read version info
                WaitForCommandAck(() => SendVersionInfoRequest());
                await Task.Delay(50);

                // Step 3: Read current DO state
                WaitForCommandAck(() => SendReadDo(0, (byte)_deviceCount));
                await Task.Delay(50);

                // Step 4: Configure event notify
                byte notifyValue = (byte)((_pollingMode & 0x02) == 0x02 ? 1 : 0);
                WaitForCommandAck(() => SendEventNotify(notifyValue));
                await Task.Delay(50);

                // Step 5: Initial DI read
                WaitForCommandAck(() => SendReadDi(0, (byte)_deviceCount));

                // Sync flush buffer with current DO state
                Buffer.BlockCopy(_doData, 0, _doDataFlush, 0, _deviceCount);

                _logger.Info("DaeDioDriver: Connected");
                _firstConnection = true;
                _connectionError = false;

                RaiseConnect(1, $"Connected ({DateTime.Now:HH:mm:ss.fff})");
            }
            catch (Exception ex)
            {
                _logger.Error($"DaeDioDriver: Connection sequence error: {ex.Message}", ex);
            }
        });
    }

    // =========================================================================
    // Polling Data Processing
    // =========================================================================

    /// <summary>
    /// Detects DI changes and raises notification events.
    /// <para>Delphi origin: <c>TCommDIOThread.ProcessPollingData</c></para>
    /// </summary>
    private void ProcessPollingData()
    {
        if (_stopped != 0) return;

        var changed = false;
        var changedList = new StringBuilder();
        _checkTime++;

        for (var i = 0; i < _deviceCount; i++)
        {
            if (_diData[i] != _diDataPre[i])
            {
                for (var k = 0; k < 8; k++)
                {
                    var newVal = GetBit(_diData[i], k);
                    if (newVal != GetBit(_diDataPre[i], k))
                    {
                        if (changedList.Length > 0)
                            changedList.Append(',');
                        changedList.Append($"{i * 8 + k}={newVal}");
                    }
                }
                changed = true;
            }
        }

        // Force periodic update (every 60 cycles)
        if (_checkTime > 60) changed = true;

        if (changed)
        {
            _checkTime = 0;

            var changeMsg = changedList.ToString();
            _logger.Debug($"DaeDioDriver: Changed DI: {changeMsg}");

            OnInputChanged?.Invoke(this, new DioNotifyEventArgs
            {
                Mode = DioMsgMode.ChangeDi,
                Message = changeMsg,
            });

            _messageBus.Publish(new DioEventMessage
            {
                Mode = DioMsgMode.ChangeDi,
                Message = changeMsg,
                Data = (byte[])_diDataPre.Clone(),
            });

            // Copy current to previous
            Buffer.BlockCopy(_diData, 0, _diDataPre, 0, _deviceCount);
        }
    }

    /// <summary>
    /// Reads polling data from the device (full DI read starting at address 0).
    /// <para>Delphi origin: <c>TCommDIOThread.ReadPollingData</c></para>
    /// </summary>
    private int ReadPollingData()
    {
        if (!_connected) return 1;
        return SendReadDi(0, (byte)_deviceCount);
    }

    /// <summary>
    /// Flushes pending DO data if changed from current device state.
    /// <para>Delphi origin: <c>TCommDIOThread.WriteFlushData</c></para>
    /// </summary>
    /// <returns>1 if data was flushed, 0 if no change.</returns>
    private int WriteFlushData()
    {
        if (_stopped != 0) return 0;

        var changed = false;
        for (var i = 0; i < _deviceCount; i++)
        {
            if (_doDataFlush[i] != _doData[i])
            {
                changed = true;
                break;
            }
        }

        if (!changed) return 0;

        // Copy flush buffer to DO data
        Buffer.BlockCopy(_doDataFlush, 0, _doData, 0, _deviceCount);

        // Send to device
        SendWriteDo(0, (byte)_deviceCount, _doDataFlush);

        OnOutputChanged?.Invoke(this, new DioNotifyEventArgs
        {
            Mode = DioMsgMode.ChangeDo,
            Message = "DO Data Changed",
        });

        _messageBus.Publish(new DioEventMessage
        {
            Mode = DioMsgMode.ChangeDo,
            Message = "DO Data Changed",
            Data = (byte[])_doDataFlush.Clone(),
        });

        return 1;
    }

    // =========================================================================
    // Tower Lamp Processing
    // =========================================================================

    /// <summary>
    /// Processes tower lamp state changes and controls lamp/melody outputs.
    /// <para>Delphi origin: <c>TCommDIOThread.Process_TowerLamp</c></para>
    /// </summary>
    private void ProcessTowerLamp()
    {
        var tickNow = Environment.TickCount64;

        switch (_towerLampState)
        {
            case 0: // All off
                if (GetBit(_doData[0], 3) != 0) WriteDoBit(0, 3, 0); // RED
                if (GetBit(_doData[0], 4) != 0) WriteDoBit(0, 4, 0); // Yellow
                if (GetBit(_doData[0], 5) != 0) WriteDoBit(0, 5, 0); // Green
                if (GetBit(_doData[0], 6) != 0) WriteDoBit(0, 6, 0); // Melody #1
                if (GetBit(_doData[0], 7) != 0) WriteDoBit(0, 7, 0); // Melody #2
                break;

            case 2: // Standby/Pass - Red On
                if (GetBit(_doData[0], 3) != 1) WriteDoBit(0, 3, 1); // RED On
                if (GetBit(_doData[0], 4) != 0) WriteDoBit(0, 4, 0);
                if (GetBit(_doData[0], 5) != 0) WriteDoBit(0, 5, 0);
                if (GetBit(_doData[0], 6) != 0) WriteDoBit(0, 6, 0);
                if (GetBit(_doData[0], 7) != 0) WriteDoBit(0, 7, 0);
                break;

            case 4: // Ready blinking green
                if (GetBit(_doData[0], 3) != 0) WriteDoBit(0, 3, 0);
                if (GetBit(_doData[0], 4) != 0) WriteDoBit(0, 4, 0);
                if (tickNow - _towerLampTick > 450)
                {
                    var greenState = (byte)(GetBit(_doData[0], 5) != 0 ? 0 : 1);
                    WriteDoBit(0, 5, greenState);
                    _towerLampTick = tickNow;
                }
                if (GetBit(_doData[0], 6) != 0) WriteDoBit(0, 6, 0);
                if (GetBit(_doData[0], 7) != 0) WriteDoBit(0, 7, 0);
                break;

            case 8: // Ready complete - Green On
                if (GetBit(_doData[0], 3) != 0) WriteDoBit(0, 3, 0);
                if (GetBit(_doData[0], 4) != 0) WriteDoBit(0, 4, 0);
                if (GetBit(_doData[0], 5) != 1) WriteDoBit(0, 5, 1);
                if (GetBit(_doData[0], 6) != 0) WriteDoBit(0, 6, 0);
                if (GetBit(_doData[0], 7) != 0) WriteDoBit(0, 7, 0);
                break;

            case 16: // Material request - Yellow blink, melody
                if (GetBit(_doData[0], 3) != 0) WriteDoBit(0, 3, 0);
                if (tickNow - _towerLampTick > 450)
                {
                    var yellowState = (byte)(GetBit(_doData[0], 4) != 0 ? 0 : 1);
                    WriteDoBit(0, 4, yellowState);
                    _towerLampTick = tickNow;
                }
                if (GetBit(_doData[0], 5) != 0) WriteDoBit(0, 5, 1);
                if (GetBit(_doData[0], 6) != 1) WriteDoBit(0, 6, 0);
                if (GetBit(_doData[0], 7) != 0) WriteDoBit(0, 7, 0);
                break;

            case 32: // Error - Red blink, melody
                if (tickNow - _towerLampTick > 450)
                {
                    var redState = (byte)(GetBit(_doData[0], 3) != 0 ? 0 : 1);
                    WriteDoBit(0, 3, redState);
                    _towerLampTick = tickNow;
                }
                if (GetBit(_doData[0], 4) != 0) WriteDoBit(0, 4, 0);
                if (GetBit(_doData[0], 5) != 0) WriteDoBit(0, 5, 1);
                if (GetBit(_doData[0], 6) != 1) WriteDoBit(0, 6, 1);
                if (GetBit(_doData[0], 7) != 0) WriteDoBit(0, 7, 0);
                break;

            case 64: // Abnormal - Red On, melody
                if (GetBit(_doData[0], 3) != 1) WriteDoBit(0, 3, 0);
                if (GetBit(_doData[0], 4) != 0) WriteDoBit(0, 4, 0);
                if (GetBit(_doData[0], 5) != 0) WriteDoBit(0, 5, 1);
                if (GetBit(_doData[0], 6) != 1) WriteDoBit(0, 6, 0);
                if (GetBit(_doData[0], 7) != 0) WriteDoBit(0, 7, 0);
                break;
        }
    }

    // =========================================================================
    // Send Command Methods
    // =========================================================================

    /// <summary>
    /// Sends a heartbeat (connection check) packet.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_HeatBeat</c></para>
    /// </summary>
    private int SendHeartbeat()
    {
        var buffer = new byte[4];
        WriteHeader(buffer, DioProtocol.IdConnection, 0);
        return SendData(buffer);
    }

    /// <summary>
    /// Sends a ReadDI command.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_ReadDI</c></para>
    /// </summary>
    private int SendReadDi(byte addr, byte count)
    {
        var buffer = new byte[6];
        WriteHeader(buffer, DioProtocol.IdReadDi, 2);
        buffer[4] = addr;
        buffer[5] = count;
        return SendData(buffer);
    }

    /// <summary>
    /// Sends a ReadDO command.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_ReadDO</c></para>
    /// </summary>
    private int SendReadDo(byte addr, byte count)
    {
        var buffer = new byte[6];
        WriteHeader(buffer, DioProtocol.IdReadDo, 2);
        buffer[4] = addr;
        buffer[5] = count;
        return SendData(buffer);
    }

    /// <summary>
    /// Sends a ClearDO command.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_ClearDO</c></para>
    /// </summary>
    private int SendClearDo(byte addr, byte count)
    {
        var buffer = new byte[6];
        WriteHeader(buffer, DioProtocol.IdClearDo, 2);
        buffer[4] = addr;
        buffer[5] = count;
        return SendData(buffer);
    }

    /// <summary>
    /// Sends a WriteDO command with data bytes.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_WriteDO</c></para>
    /// </summary>
    private int SendWriteDo(byte addr, byte count, byte[] values)
    {
        var buffer = new byte[6 + count];
        WriteHeader(buffer, DioProtocol.IdWriteDo, (ushort)(count + 2));
        buffer[4] = addr;
        buffer[5] = count;
        Buffer.BlockCopy(values, 0, buffer, 6, count);
        return SendData(buffer);
    }

    /// <summary>
    /// Sends a WriteBit command.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_WriteBit</c></para>
    /// </summary>
    private int SendWriteBit(byte addr, byte bitLoc, byte value)
    {
        var buffer = new byte[7];
        WriteHeader(buffer, DioProtocol.IdWriteBit, 3);
        buffer[4] = addr;
        buffer[5] = bitLoc;
        buffer[6] = value;
        return SendData(buffer);
    }

    /// <summary>
    /// Sends an EventNotify configuration command.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_EventNotify</c></para>
    /// </summary>
    private int SendEventNotify(byte value)
    {
        var buffer = new byte[5];
        WriteHeader(buffer, DioProtocol.IdEventNotify, 1);
        buffer[4] = value;
        return SendData(buffer);
    }

    /// <summary>
    /// Sends a ReadVersionInfo command.
    /// <para>Delphi origin: <c>TCommDIOThread.Send_ReadVerionInfo</c></para>
    /// </summary>
    private int SendVersionInfoRequest()
    {
        var buffer = new byte[4];
        WriteHeader(buffer, DioProtocol.IdVersion, 0);
        return SendData(buffer);
    }

    // =========================================================================
    // Low-Level Send
    // =========================================================================

    /// <summary>
    /// Sends raw bytes to the DIO device via UDP.
    /// <para>Delphi origin: <c>TCommDIOThread.SendData</c></para>
    /// </summary>
    private int SendData(byte[] buffer)
    {
        if (_stopped != 0) return 1;

        try
        {
            // Log send data
            if ((LogLevel & 0x04) == 0x04)
            {
                var id = BitConverter.ToUInt16(buffer, 0);
                var isPolling = id == DioProtocol.IdReadDi &&
                                buffer.Length > 5 && buffer[4] == 0 && buffer[5] == _deviceCount;
                isPolling = isPolling || id == DioProtocol.IdConnection;

                if (!isPolling || (LogLevel & 0x10) == 0x10)
                {
                    _logger.Debug($"DaeDioDriver: Send({buffer.Length})> {FormatHex(buffer)}");
                }
            }

            lock (_sendLock)
            {
                _udpSender?.Send(buffer, buffer.Length, DeviceIp, DevicePort);
            }

            _lastTickSend = Environment.TickCount64;
            return 0;
        }
        catch (Exception ex)
        {
            _logger.Error($"DaeDioDriver: Exception in SendData: {ex.Message}", ex);
            RaiseError(255, $"Exception in SendData: {ex.Message}");
            return 255;
        }
    }

    // =========================================================================
    // Command Ack Synchronization
    // =========================================================================

    /// <summary>
    /// Result codes for WaitForCommandAck, mirroring Windows WaitForSingleObject results.
    /// </summary>
    private enum WaitResult
    {
        /// <summary>WAIT_OBJECT_0 = 0 (success)</summary>
        Success = 0,

        /// <summary>WAIT_TIMEOUT = 258</summary>
        Timeout = 258,

        /// <summary>WAIT_FAILED = uint max</summary>
        Failed = unchecked((int)0xFFFFFFFF),
    }

    /// <summary>
    /// Sends a command and waits for the device acknowledgement.
    /// <para>Delphi origin: <c>TCommDIOThread.WaitForCommandAck</c></para>
    /// </summary>
    /// <param name="commandAction">Action that sends the command.</param>
    /// <param name="waitTimeMs">Timeout in milliseconds. Default: 2000.</param>
    /// <param name="retryCount">Number of retries. Default: 0 (no retry).</param>
    /// <returns>WaitResult indicating success, timeout, or failure.</returns>
    private WaitResult WaitForCommandAck(Action commandAction, int waitTimeMs = 2000, int retryCount = 0)
    {
        var result = WaitResult.Failed;

        for (var i = 0; i <= retryCount; i++)
        {
            _commandAckEvent.Reset();
            commandAction();

            if (_commandAckEvent.Wait(waitTimeMs))
            {
                result = WaitResult.Success;
                break;
            }

            result = WaitResult.Timeout;
        }

        return result;
    }

    // =========================================================================
    // Helper Methods
    // =========================================================================

    /// <summary>
    /// Writes a DIO protocol header (ID + Len) to a byte buffer (little-endian).
    /// </summary>
    private static void WriteHeader(byte[] buffer, ushort id, ushort len)
    {
        buffer[0] = (byte)(id & 0xFF);
        buffer[1] = (byte)((id >> 8) & 0xFF);
        buffer[2] = (byte)(len & 0xFF);
        buffer[3] = (byte)((len >> 8) & 0xFF);
    }

    /// <summary>
    /// Formats a byte array as a hex string for logging (max 100 bytes).
    /// </summary>
    private static string FormatHex(byte[] data)
    {
        var count = Math.Min(data.Length, 100);
        var sb = new StringBuilder(count * 3);
        for (var i = 0; i < count; i++)
        {
            if (i > 0) sb.Append(' ');
            sb.Append(data[i].ToString("X2"));
        }
        if (data.Length > 100) sb.Append("...");
        return sb.ToString();
    }

    /// <summary>
    /// Calculates a simple checksum by summing all bytes.
    /// <para>Delphi origin: <c>TCommDIOThread.CalcChecksum</c></para>
    /// </summary>
    private static int CalcChecksum(byte[] data, int offset, int count)
    {
        var sum = 0;
        for (var i = offset; i < offset + count; i++)
            sum += data[i];
        return sum;
    }

    // =========================================================================
    // Event Raising Helpers
    // =========================================================================

    private void RaiseConnect(int param, string message)
    {
        var args = new DioNotifyEventArgs
        {
            Mode = DioMsgMode.Connect,
            Param = param,
            Message = message,
        };

        OnConnect?.Invoke(this, args);
        _messageBus.Publish(new DioEventMessage
        {
            Mode = DioMsgMode.Connect,
            Param = param,
            Message = message,
        });
    }

    private void RaiseError(int param, string message)
    {
        var args = new DioNotifyEventArgs
        {
            Mode = DioMsgMode.Error,
            Param = param,
            Message = message,
        };

        OnError?.Invoke(this, args);
        _messageBus.Publish(new DioEventMessage
        {
            Mode = DioMsgMode.Error,
            Param = param,
            Message = message,
        });
    }

    // =========================================================================
    // Network Cleanup
    // =========================================================================

    private void CleanupNetwork()
    {
        try
        {
            _udpListener?.Close();
            _udpListener?.Dispose();
        }
        catch { /* swallow */ }
        _udpListener = null;

        try
        {
            _udpSender?.Close();
            _udpSender?.Dispose();
        }
        catch { /* swallow */ }
        _udpSender = null;
    }
}
