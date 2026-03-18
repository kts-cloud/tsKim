// =============================================================================
// ThermometerMultiDriver.cs
// Converted from Delphi: src_X3584\CommThermometerMulti.pas (TCommThermometerMulti)
// Namespace: Dongaeltek.ITOLED.Hardware.Thermometer
// =============================================================================

using System.IO.Ports;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Thermometer;

// =============================================================================
// Constants
// =============================================================================

/// <summary>
/// Thermometer communication constants.
/// Original Delphi: CommThermometerMulti.pas top-level constants.
/// </summary>
public static class DefThermometer
{
    /// <summary>Connection status mode. Delphi: COMMTHERMOMETER_CONNECT = 0</summary>
    public const int Connect = 0;

    /// <summary>Temperature update mode. Delphi: COMMTHERMOMETER_UPDATE = 1</summary>
    public const int Update = 1;

    /// <summary>Add log mode. Delphi: COMMTHERMOMETER_ADDLLOG = 100</summary>
    public const int AddLog = 100;

    /// <summary>Maximum channel index (0-based). Delphi: COMMTHERMOMETER_MAX_CH_NUM = 7</summary>
    public const int MaxChNum = 7;

    /// <summary>Maximum channel count. Delphi: COMMTHERMOMETER_MAX_CH_CNT = 3</summary>
    public const int MaxChCnt = 3;

    /// <summary>Total number of channels (MaxChNum + 1).</summary>
    public const int ChannelCount = MaxChNum + 1;

    /// <summary>Timeout threshold in polling cycles (16 cycles = timeout). Delphi: m_nTimeoutCount = 16</summary>
    public const int TimeoutThreshold = 16;

    /// <summary>Maximum timeout counter value before clamping.</summary>
    public const int TimeoutMaxCount = 100;
}

// =============================================================================
// Interface
// =============================================================================

/// <summary>
/// Abstraction over the Autonix TK thermometer (Modbus RTU serial).
/// Mirrors the public surface of Delphi's <c>TCommThermometerMulti</c>.
/// </summary>
public interface IThermometerDriver : IDisposable
{
    /// <summary>Whether the serial port is currently connected.</summary>
    bool Connected { get; }

    /// <summary>
    /// Current temperature values for each channel (0..7), in degrees Celsius.
    /// Temperature = raw_value * 0.1
    /// </summary>
    double[] CurrentValue { get; }

    /// <summary>
    /// Opens the serial port and starts cyclic polling.
    /// Original Delphi: <c>TCommThermometerMulti.Connect</c>
    /// </summary>
    /// <param name="portName">COM port name (e.g., "COM3").</param>
    /// <returns><c>true</c> if connection succeeded.</returns>
    bool Connect(string portName);

    /// <summary>
    /// Overload accepting a port number (e.g., 3 for COM3).
    /// Original Delphi: <c>TCommThermometerMulti.Connect(nPort: Integer)</c>
    /// </summary>
    bool Connect(int portNumber);

    /// <summary>
    /// Stops polling and closes the serial port.
    /// Original Delphi: <c>TCommThermometerMulti.Disconnect</c>
    /// </summary>
    void Disconnect();

    /// <summary>
    /// Sends a Modbus Function 04 query to the specified slave channel.
    /// Original Delphi: <c>TCommThermometerMulti.QueryData</c>
    /// </summary>
    /// <param name="channel">Slave address (1-based, default 1).</param>
    void QueryData(byte channel = 1);
}

// =============================================================================
// Modbus CRC16 Lookup Tables
// =============================================================================

/// <summary>
/// Modbus CRC16 calculation using Hi/Lo byte lookup tables.
/// Exact port of the Delphi <c>CalcCRC16</c> function and tables from CommThermometerMulti.pas.
/// </summary>
public static class ModbusCrc16
{
    // -------------------------------------------------------------------------
    // High-Order Byte Table
    // Table of CRC values for high-order byte
    // Original Delphi: abCRCHi
    // -------------------------------------------------------------------------
    private static readonly byte[] CrcHi =
    [
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40
    ];

    // -------------------------------------------------------------------------
    // Low-Order Byte Table
    // Table of CRC values for low-order byte
    // Original Delphi: abCRCLo
    // -------------------------------------------------------------------------
    private static readonly byte[] CrcLo =
    [
        0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06, 0x07, 0xC7, 0x05, 0xC5, 0xC4, 0x04,
        0xCC, 0x0C, 0x0D, 0xCD, 0x0F, 0xCF, 0xCE, 0x0E, 0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09, 0x08, 0xC8,
        0xD8, 0x18, 0x19, 0xD9, 0x1B, 0xDB, 0xDA, 0x1A, 0x1E, 0xDE, 0xDF, 0x1F, 0xDD, 0x1D, 0x1C, 0xDC,
        0x14, 0xD4, 0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3, 0x11, 0xD1, 0xD0, 0x10,
        0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3, 0xF2, 0x32, 0x36, 0xF6, 0xF7, 0x37, 0xF5, 0x35, 0x34, 0xF4,
        0x3C, 0xFC, 0xFD, 0x3D, 0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A, 0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38,
        0x28, 0xE8, 0xE9, 0x29, 0xEB, 0x2B, 0x2A, 0xEA, 0xEE, 0x2E, 0x2F, 0xEF, 0x2D, 0xED, 0xEC, 0x2C,
        0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26, 0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0,
        0xA0, 0x60, 0x61, 0xA1, 0x63, 0xA3, 0xA2, 0x62, 0x66, 0xA6, 0xA7, 0x67, 0xA5, 0x65, 0x64, 0xA4,
        0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F, 0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB, 0x69, 0xA9, 0xA8, 0x68,
        0x78, 0xB8, 0xB9, 0x79, 0xBB, 0x7B, 0x7A, 0xBA, 0xBE, 0x7E, 0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C,
        0xB4, 0x74, 0x75, 0xB5, 0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71, 0x70, 0xB0,
        0x50, 0x90, 0x91, 0x51, 0x93, 0x53, 0x52, 0x92, 0x96, 0x56, 0x57, 0x97, 0x55, 0x95, 0x94, 0x54,
        0x9C, 0x5C, 0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E, 0x5A, 0x9A, 0x9B, 0x5B, 0x99, 0x59, 0x58, 0x98,
        0x88, 0x48, 0x49, 0x89, 0x4B, 0x8B, 0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C,
        0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42, 0x43, 0x83, 0x41, 0x81, 0x80, 0x40
    ];

    /// <summary>
    /// Calculates Modbus CRC16 using the Hi/Lo byte lookup tables.
    /// Exact port of Delphi's <c>CalcCRC16</c> function.
    /// </summary>
    /// <param name="data">Input byte buffer.</param>
    /// <param name="length">Number of bytes to process from <paramref name="data"/>.</param>
    /// <returns>CRC16 value (hi byte in bits 15..8, lo byte in bits 7..0).</returns>
    public static ushort CalcCRC16(ReadOnlySpan<byte> data, int length)
    {
        byte crcHi = 0xFF; // high byte of CRC initialized
        byte crcLo = 0xFF; // low byte of CRC initialized

        for (var i = 0; i < length; i++)
        {
            var index = crcLo ^ data[i];
            crcLo = (byte)(crcHi ^ CrcHi[index]);
            crcHi = CrcLo[index];
        }

        return (ushort)((crcHi << 8) | crcLo);
    }

    /// <summary>
    /// Overload accepting a byte array.
    /// </summary>
    public static ushort CalcCRC16(byte[] data, int length)
        => CalcCRC16((ReadOnlySpan<byte>)data, length);
}

// =============================================================================
// Utilities
// =============================================================================

/// <summary>
/// Hex formatting utility for serial communication logging.
/// </summary>
public static class BufferUtils
{
    /// <summary>
    /// Converts a byte buffer to a space-separated hex string.
    /// Exact port of Delphi's <c>BufferToHex</c> function.
    /// </summary>
    /// <param name="data">Byte buffer.</param>
    /// <param name="count">Number of bytes to format.</param>
    /// <returns>Space-separated hex string (e.g., "01 04 03 e8 00 02 ").</returns>
    public static string BufferToHex(ReadOnlySpan<byte> data, int count)
    {
        var sb = new System.Text.StringBuilder(count * 3);
        for (var i = 0; i < count; i++)
        {
            sb.AppendFormat("{0:x2} ", data[i]);
        }
        return sb.ToString();
    }

    /// <summary>
    /// Overload accepting a byte array.
    /// </summary>
    public static string BufferToHex(byte[] data, int count)
        => BufferToHex((ReadOnlySpan<byte>)data, count);
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// Autonix TK thermometer driver communicating via Modbus RTU over serial (9600/8N2).
/// Replaces Delphi's <c>TCommThermometerMulti</c> class.
/// <para>
/// Polls up to 8 channels (slave addresses 1..8) in round-robin via a
/// <see cref="System.Threading.Timer"/>. Temperature readings are published
/// as <see cref="ThermometerEventMessage"/> instances through <see cref="IMessageBus"/>.
/// </para>
/// <para>
/// Modbus protocol: Function 04 (Read Input Register), start address 0x03E8 (301001),
/// register count 2. Response carries raw temperature value; actual = raw * 0.1.
/// </para>
/// </summary>
public sealed class ThermometerMultiDriver : IThermometerDriver
{
    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly object _lock = new();

    private SerialPort? _serialPort;
    private Timer? _cycleTimer;
    private readonly int _intervalMs;

    // Receive buffer for accumulating partial Modbus responses
    private readonly byte[] _rxBuffer = new byte[100];
    private int _rxBufferCount;

    // Round-robin channel index (0..7), used to compute slave address = index + 1
    private int _currentChannelIndex;

    // Timeout detection: incremented each polling cycle, reset on valid response
    private int _timeoutCount;

    private bool _disposed;

    /// <summary>
    /// Creates a new thermometer driver instance.
    /// Original Delphi: <c>TCommThermometerMulti.Create(hMain, nMsgType, nInterval)</c>
    /// </summary>
    /// <param name="messageBus">Message bus replacing WM_COPYDATA for GUI updates.</param>
    /// <param name="logger">Application logger.</param>
    /// <param name="intervalMs">Polling interval in milliseconds.</param>
    public ThermometerMultiDriver(IMessageBus messageBus, ILogger logger, int intervalMs = 500)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _intervalMs = intervalMs;

        CurrentValue = new double[DefThermometer.ChannelCount];
        _logger.Debug("ThermometerMultiDriver created");
    }

    // =====================================================================
    // Properties
    // =====================================================================

    /// <inheritdoc />
    public bool Connected { get; private set; }

    /// <inheritdoc />
    public double[] CurrentValue { get; }

    /// <summary>
    /// Device state byte. Delphi: <c>TCommThermometerMulti.State</c>
    /// </summary>
    public byte State { get; set; }

    // =====================================================================
    // Connect / Disconnect
    // =====================================================================

    /// <inheritdoc />
    public bool Connect(int portNumber)
    {
        if (portNumber == 0)
        {
            PublishMessage(DefThermometer.Connect, param: 3, param2: 0, message: "NONE");
            return false;
        }

        return Connect($"COM{portNumber}");
    }

    /// <inheritdoc />
    public bool Connect(string portName)
    {
        if (Connected)
            return true;

        _logger.Info($"Thermometer connecting to {portName}...");

        try
        {
            _serialPort = new SerialPort
            {
                PortName = portName,
                BaudRate = 9600,
                Parity = Parity.None,
                DataBits = 8,
                StopBits = StopBits.Two,    // 2 stop bits per Delphi sb2
                ReadTimeout = 1000,
                WriteTimeout = 1000,
            };

            _serialPort.DataReceived += OnSerialDataReceived;
            _serialPort.Open();

            Connected = true;
            _currentChannelIndex = 0;
            _timeoutCount = 0;
            _rxBufferCount = 0;

            // Start cyclic polling timer
            _cycleTimer = new Timer(OnCycleTimerElapsed, null, _intervalMs, _intervalMs);

            PublishMessage(DefThermometer.Connect, param: 1, param2: 0, message: portName);

            // Send initial query (slave address 1)
            QueryData();

            return true;
        }
        catch (Exception ex)
        {
            _logger.Error($"Thermometer connect failed: {ex.Message}", ex);
            PublishMessage(DefThermometer.Connect, param: 2, param2: 0, message: ex.Message);
            return false;
        }
    }

    /// <inheritdoc />
    public void Disconnect()
    {
        _cycleTimer?.Change(Timeout.Infinite, Timeout.Infinite);
        _cycleTimer?.Dispose();
        _cycleTimer = null;

        if (_serialPort is { IsOpen: true })
        {
            try
            {
                _serialPort.DataReceived -= OnSerialDataReceived;
                _serialPort.Close();
            }
            catch (Exception ex)
            {
                _logger.Warn($"Thermometer disconnect error: {ex.Message}");
            }
        }
        _serialPort?.Dispose();
        _serialPort = null;

        if (Connected)
        {
            Connected = false;
            PublishMessage(DefThermometer.Connect, param: 0, param2: 0, message: "Disconnected");
        }
    }

    // =====================================================================
    // QueryData - Modbus RTU Function 04
    // =====================================================================

    /// <inheritdoc />
    public void QueryData(byte channel = 1)
    {
        if (!Connected || _serialPort is not { IsOpen: true })
            return;

        // Build Modbus RTU request:
        // [SlaveAddr] [Func=04] [StartAddrHi=03] [StartAddrLo=E8] [CountHi=00] [CountLo=02] [CRC16Lo] [CRC16Hi]
        Span<byte> buffer = stackalloc byte[8];
        buffer[0] = channel;    // Slave Address
        buffer[1] = 0x04;       // Function - Read Input Register
        buffer[2] = 0x03;       // Starting Address (Hi)
        buffer[3] = 0xE8;       // Starting Address (Lo) => 0x03E8 = 301001
        buffer[4] = 0x00;       // Count (Hi)
        buffer[5] = 0x02;       // Count (Lo) => 2 registers

        var crc = ModbusCrc16.CalcCRC16(buffer, 6);
        buffer[6] = (byte)(crc & 0xFF);         // CRC16 Lo
        buffer[7] = (byte)((crc >> 8) & 0xFF);  // CRC16 Hi

        var sendBytes = buffer.ToArray();
        _logger.Debug($"Thermometer Send: {BufferUtils.BufferToHex(sendBytes, 8)}");

        try
        {
            _serialPort.Write(sendBytes, 0, 8);
        }
        catch (Exception ex)
        {
            _logger.Error($"Thermometer send error: {ex.Message}");
        }
    }

    // =====================================================================
    // Serial Data Received (replaces VaCommRxChar)
    // =====================================================================

    /// <summary>
    /// Handles incoming serial data. Accumulates bytes into <c>_rxBuffer</c>
    /// and processes a complete Modbus response when 9+ bytes are available.
    /// Original Delphi: <c>TCommThermometerMulti.VaCommRxChar</c>
    /// </summary>
    private void OnSerialDataReceived(object sender, SerialDataReceivedEventArgs e)
    {
        if (_serialPort is not { IsOpen: true })
            return;

        try
        {
            var bytesToRead = _serialPort.BytesToRead;
            if (bytesToRead <= 0)
                return;

            var tempBuffer = new byte[bytesToRead];
            var bytesRead = _serialPort.Read(tempBuffer, 0, bytesToRead);

            _logger.Debug($"Thermometer Recv: {BufferUtils.BufferToHex(tempBuffer, bytesRead)}");

            lock (_lock)
            {
                // Append to accumulation buffer
                if (_rxBufferCount + bytesRead > _rxBuffer.Length)
                {
                    // Overflow protection: reset buffer
                    _rxBufferCount = 0;
                    return;
                }

                Array.Copy(tempBuffer, 0, _rxBuffer, _rxBufferCount, bytesRead);
                _rxBufferCount += bytesRead;

                ProcessReceivedData();
            }
        }
        catch (Exception ex)
        {
            _logger.Error($"Thermometer receive error: {ex.Message}");
        }
    }

    /// <summary>
    /// Processes accumulated receive buffer when at least 9 bytes are present.
    /// Validates Modbus CRC16 and extracts temperature value.
    /// <para>
    /// Expected response format (9 bytes):
    /// [SlaveAddr] [Func=04] [ByteCount=04] [DataHi] [DataLo] [DigitHi] [DigitLo] [CRC16Lo] [CRC16Hi]
    /// </para>
    /// Original Delphi: inline logic in <c>VaCommRxChar</c> and <c>TestProcessData</c>.
    /// </summary>
    private void ProcessReceivedData()
    {
        // Minimum response length: SlaveAddr(1) + Func(1) + ByteCount(1) + Data(4) + CRC(2) = 9
        if (_rxBufferCount < 9)
            return;

        // Validate function code
        if (_rxBuffer[1] == 0x04)
        {
            var byteCount = _rxBuffer[2];
            var crc = ModbusCrc16.CalcCRC16(_rxBuffer, byteCount + 3);

            // Extract received CRC (little-endian at offset byteCount + 3)
            var recvCrc = (ushort)(_rxBuffer[byteCount + 3] | (_rxBuffer[byteCount + 4] << 8));

            if (recvCrc != crc)
            {
                // CRC error
                var errorMsg = $"CRC Error: Recv {recvCrc:x4}: Calc {crc:x4}";
                _logger.Warn(errorMsg);
                PublishMessage(DefThermometer.Connect, param: 2, param2: 0, message: errorMsg);
            }
            else
            {
                // Valid packet - extract channel and temperature
                var channelIndex = _rxBuffer[0] - 1; // Convert 1-based slave address to 0-based index

                if (channelIndex is >= 0 and <= DefThermometer.MaxChNum)
                {
                    var rawValue = (ushort)((_rxBuffer[3] << 8) | _rxBuffer[4]);
                    CurrentValue[channelIndex] = rawValue * 0.1; // Decimal point processing
                    _timeoutCount = 0;

                    PublishMessage(DefThermometer.Update,
                        param: rawValue,
                        param2: _rxBuffer[0], // Slave address (1-based)
                        message: string.Empty);
                }
            }
        }
        else
        {
            // Unexpected packet
            _logger.Warn($"Thermometer packet mismatch: {BufferUtils.BufferToHex(_rxBuffer, _rxBufferCount)}");
        }

        // Reset buffer regardless of outcome (same as Delphi: m_nBuffCount := 0)
        _rxBufferCount = 0;
    }

    // =====================================================================
    // Cyclic Timer (replaces tmrCycleTimer)
    // =====================================================================

    /// <summary>
    /// Timer callback for round-robin channel polling.
    /// Cycles through slave addresses 1..8.
    /// Original Delphi: <c>TCommThermometerMulti.tmrCycleTimer</c>
    /// </summary>
    private void OnCycleTimerElapsed(object? state)
    {
        if (!Connected)
            return;

        // Timeout detection
        Interlocked.Increment(ref _timeoutCount);
        var currentTimeout = _timeoutCount;

        if (currentTimeout == DefThermometer.TimeoutThreshold)
        {
            PublishMessage(DefThermometer.Connect, param: 2, param2: 0, message: "Query Timeout");
        }

        if (currentTimeout > DefThermometer.TimeoutMaxCount)
        {
            Interlocked.Exchange(ref _timeoutCount, DefThermometer.TimeoutMaxCount);
        }

        // Round-robin: slave address = (index % 8) + 1
        var slaveAddress = (byte)((_currentChannelIndex % DefThermometer.ChannelCount) + 1);
        QueryData(slaveAddress);
        _currentChannelIndex = (_currentChannelIndex + 1) % DefThermometer.ChannelCount;
    }

    // =====================================================================
    // Message Publishing (replaces SendMessageMain / WM_COPYDATA)
    // =====================================================================

    /// <summary>
    /// Publishes a thermometer event via the message bus.
    /// Replaces Delphi: <c>TCommThermometerMulti.SendMessageMain</c> (WM_COPYDATA).
    /// </summary>
    private void PublishMessage(int mode, int param, int param2, string message)
    {
        _messageBus.Publish(new ThermometerEventMessage
        {
            Channel = 0,
            Mode = mode,
            Param = param,
            Param2 = param2,
            Message = message,
        });
    }

    // =====================================================================
    // Dispose
    // =====================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed)
            return;
        _disposed = true;

        Disconnect();
        _logger.Debug("ThermometerMultiDriver disposed");
    }
}
