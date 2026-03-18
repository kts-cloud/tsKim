// =============================================================================
// LightNaratechDriver.cs
// Converted from Delphi: src_X3584\CommLightNaratech.pas (TCommLight class)
// Namespace: Dongaeltek.ITOLED.Hardware.Light
// =============================================================================

using System.IO.Ports;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Light;

// =============================================================================
// Constants
// =============================================================================

/// <summary>
/// Light controller constants.
/// Original Delphi: <c>CommLightNaratech</c> unit-level constants.
/// </summary>
public static class DefLight
{
    /// <summary>Maximum number of light channels. Original Delphi: MAX_LIGHTCOUNT = 8</summary>
    public const int MaxLightCount = 8;

    /// <summary>Connection message mode. Original Delphi: COMM_CAM_LIGHT_CONNECTION = 100</summary>
    public const int CommCamLightConnection = 100;
}

// =============================================================================
// Interface
// =============================================================================

/// <summary>
/// Abstraction over a multi-channel light controller.
/// Mirrors the public surface of Delphi's <c>TCommLight</c>.
/// </summary>
public interface ILightDriver : IDisposable
{
    /// <summary>Whether the serial port is currently connected.</summary>
    bool Connected { get; }

    /// <summary>Current brightness values for all 8 channels (0-based).</summary>
    byte[] BrightList { get; }

    /// <summary>Maintenance mode flag.</summary>
    bool IsMaint { get; set; }

    /// <summary>
    /// Opens the serial port on the specified COM port number.
    /// Original Delphi: <c>TCommLight.Connect</c>
    /// </summary>
    /// <param name="port">COM port number (1-based). 0 means no port configured.</param>
    /// <returns>True if connection succeeded.</returns>
    bool Connect(int port);

    /// <summary>
    /// Closes the serial port.
    /// Original Delphi: <c>TCommLight.Disconnect</c>
    /// </summary>
    void Disconnect();

    /// <summary>
    /// Sets brightness for a single channel using the single-channel protocol.
    /// Binary protocol: <c>$4C</c> + channel(<c>$30+nCh</c>) + 3-digit brightness ASCII + CR+LF (7 bytes).
    /// Original Delphi: <c>TCommLight.WriteBrightOne</c>
    /// </summary>
    void WriteBrightOne(byte channel, byte brightness);

    /// <summary>
    /// Sets brightness for two channels sequentially with inter-command delays.
    /// Original Delphi: <c>TCommLight.WriteBrightTwin</c>
    /// </summary>
    void WriteBrightTwin(byte ch1, byte ch2, byte bright1, byte bright2);

    /// <summary>
    /// Sets brightness for all 8 channels using the bulk protocol.
    /// Bulk protocol: <c>$3A$3A</c> + command(0) + 8 brightness bytes + XOR checksum + <c>$EE$EE</c> (14 bytes).
    /// Original Delphi: <c>TCommLight.WriteBrights</c>
    /// </summary>
    void WriteBrights(byte[] brights);

    /// <summary>
    /// Sets all 8 channels to the same brightness value.
    /// Original Delphi: <c>TCommLight.WriteBrightsAll</c>
    /// </summary>
    void WriteBrightsAll(byte brightness);

    /// <summary>
    /// Saves current brightness values to controller memory (command 'W').
    /// Original Delphi: <c>TCommLight.SaveBrights</c>
    /// </summary>
    void SaveBrights();

    /// <summary>
    /// Loads brightness values from controller memory (command 'R').
    /// Original Delphi: <c>TCommLight.LoadBrights</c>
    /// </summary>
    void LoadBrights();
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// Naratech PD3000 light controller driver via RS-232 serial (19200/8N1).
/// Replaces Delphi's <c>TCommLight</c> class from CommLightNaratech.pas.
/// <para>
/// WM_COPYDATA inter-form messaging is replaced with <see cref="IMessageBus"/>
/// publishing <see cref="LightEventMessage"/> instances.
/// </para>
/// </summary>
public sealed class LightNaratechDriver : ILightDriver
{
    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly int _lightType;
    private readonly object _portLock = new();

    private SerialPort? _serialPort;
    private bool _disposed;

    /// <summary>
    /// Creates a new Naratech PD3000 light controller driver instance.
    /// Original Delphi: <c>TCommLight.Create(hMain: HWND; nLightType: Integer)</c>
    /// </summary>
    /// <param name="messageBus">Message bus replacing WM_COPYDATA for UI notifications.</param>
    /// <param name="logger">Application logger.</param>
    /// <param name="lightType">Light type identifier (maps to Delphi <c>m_nType</c>).</param>
    public LightNaratechDriver(IMessageBus messageBus, ILogger logger, int lightType = 0)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _lightType = lightType;

        BrightList = new byte[DefLight.MaxLightCount];
    }

    // =====================================================================
    // Properties
    // =====================================================================

    /// <inheritdoc />
    public bool Connected { get; private set; }

    /// <inheritdoc />
    public byte[] BrightList { get; }

    /// <inheritdoc />
    public bool IsMaint { get; set; }

    // =====================================================================
    // Connect / Disconnect
    // =====================================================================

    /// <inheritdoc />
    public bool Connect(int port)
    {
        if (port == 0)
        {
            PublishEvent(DefLight.CommCamLightConnection, channel: 0, param: 2, message: "NONE");
            return false;
        }

        lock (_portLock)
        {
            if (_serialPort is { IsOpen: true })
                return false;

            try
            {
                _serialPort?.Dispose();
                _serialPort = new SerialPort($"COM{port}", 19200, Parity.None, 8, StopBits.One)
                {
                    ReadTimeout = 500,
                    WriteTimeout = 500,
                };
                _serialPort.DataReceived += OnDataReceived;
                _serialPort.Open();

                Connected = true;
                _logger.Info($"[Light] Connected on COM{port}");
            }
            catch (Exception ex)
            {
                _logger.Error($"[Light] Connect failed on COM{port}", ex);
                Connected = false;
            }
        }

        if (Connected)
            PublishEvent(DefLight.CommCamLightConnection, channel: 0, param: 1, message: $"COM {port}");
        else
            PublishEvent(DefLight.CommCamLightConnection, channel: 0, param: 0, message: $"COM {port}");

        return Connected;
    }

    /// <inheritdoc />
    public void Disconnect()
    {
        lock (_portLock)
        {
            if (_serialPort is not null)
            {
                try
                {
                    if (_serialPort.IsOpen)
                        _serialPort.Close();
                }
                catch (Exception ex)
                {
                    _logger.Error("[Light] Error closing serial port", ex);
                }

                _serialPort.DataReceived -= OnDataReceived;
                _serialPort.Dispose();
                _serialPort = null;
            }

            Connected = false;
        }
    }

    // =====================================================================
    // Single-channel protocol
    // $4C + ($30+nCh) + 3-digit brightness ASCII + $0D + $0A  (7 bytes)
    // =====================================================================

    /// <inheritdoc />
    public void WriteBrightOne(byte channel, byte brightness)
    {
        lock (_portLock)
        {
            if (!IsPortOpen()) return;

            var buff = BuildSingleChannelPacket(channel, brightness);
            WriteBytes(buff);
            BrightList[channel] = brightness;
        }
    }

    /// <inheritdoc />
    public void WriteBrightTwin(byte ch1, byte ch2, byte bright1, byte bright2)
    {
        lock (_portLock)
        {
            if (!IsPortOpen()) return;

            Thread.Sleep(50);

            var buff1 = BuildSingleChannelPacket(ch1, bright1);
            WriteBytes(buff1);
            BrightList[ch1] = bright1;

            Thread.Sleep(100);

            var buff2 = BuildSingleChannelPacket(ch2, bright2);
            Thread.Sleep(50);
            WriteBytes(buff2);
            BrightList[ch2] = bright2;
        }
    }

    // =====================================================================
    // Bulk 8-channel protocol
    // $3A $3A + command(0/W/R) + 8 brightness bytes + XOR checksum + $EE $EE  (14 bytes)
    // =====================================================================

    /// <inheritdoc />
    public void WriteBrights(byte[] brights)
    {
        ArgumentNullException.ThrowIfNull(brights);
        if (brights.Length != DefLight.MaxLightCount)
            throw new ArgumentException($"Expected {DefLight.MaxLightCount} brightness values.", nameof(brights));

        lock (_portLock)
        {
            if (!IsPortOpen()) return;

            var buff = BuildBulkPacket(0x00, brights);
            WriteBytes(buff);
            Array.Copy(brights, BrightList, DefLight.MaxLightCount);
        }
    }

    /// <inheritdoc />
    public void WriteBrightsAll(byte brightness)
    {
        lock (_portLock)
        {
            if (!IsPortOpen()) return;

            Array.Fill(BrightList, brightness);

            var buff = BuildBulkPacket(0x00, BrightList);
            WriteBytes(buff);
        }
    }

    /// <inheritdoc />
    public void SaveBrights()
    {
        lock (_portLock)
        {
            if (!IsPortOpen()) return;

            // Save command uses 'W' with all-0xFF brightness payload
            var payload = new byte[DefLight.MaxLightCount];
            Array.Fill(payload, (byte)0xFF);

            var buff = BuildBulkPacket((byte)'W', payload);
            WriteBytes(buff);
        }
    }

    /// <inheritdoc />
    public void LoadBrights()
    {
        lock (_portLock)
        {
            if (!IsPortOpen()) return;

            // Load command uses 'R' with current BrightList as payload
            var buff = BuildBulkPacket((byte)'R', BrightList);
            WriteBytes(buff);
        }
    }

    // =====================================================================
    // Dispose
    // =====================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        Disconnect();
    }

    // =====================================================================
    // Private helpers - Packet builders
    // =====================================================================

    /// <summary>
    /// Builds a 7-byte single-channel brightness packet.
    /// Protocol: <c>$4C</c> + <c>$30+channel</c> + 3-digit ASCII brightness + CR + LF
    /// </summary>
    private static byte[] BuildSingleChannelPacket(byte channel, byte brightness)
    {
        var sBright = brightness.ToString("D3");  // 3-digit zero-padded
        return
        [
            0x4C,                   // 'L' command
            (byte)(0x30 + channel), // channel as ASCII digit offset
            (byte)sBright[0],       // brightness digit 1
            (byte)sBright[1],       // brightness digit 2
            (byte)sBright[2],       // brightness digit 3
            0x0D,                   // CR
            0x0A,                   // LF
        ];
    }

    /// <summary>
    /// Builds a 14-byte bulk 8-channel packet.
    /// Protocol: <c>$3A $3A</c> + command + 8 brightness bytes + XOR checksum + <c>$EE $EE</c>
    /// </summary>
    private static byte[] BuildBulkPacket(byte command, byte[] brights)
    {
        var buff = new byte[14];
        buff[0] = 0x3A;  // header byte 1
        buff[1] = 0x3A;  // header byte 2
        buff[2] = command;

        // Copy 8 brightness values
        Array.Copy(brights, 0, buff, 3, DefLight.MaxLightCount);

        // XOR checksum of all 8 brightness values
        buff[11] = CalcChecksum(brights);
        buff[12] = 0xEE;  // trailer byte 1
        buff[13] = 0xEE;  // trailer byte 2

        return buff;
    }

    /// <summary>
    /// Calculates XOR checksum of all 8 brightness values.
    /// Original Delphi: <c>TCommLight.CalcChecksum</c>
    /// </summary>
    private static byte CalcChecksum(byte[] brights)
    {
        byte crc = 0;
        for (var i = 0; i < DefLight.MaxLightCount; i++)
        {
            crc ^= brights[i];
        }
        return (byte)(crc & 0xFF);
    }

    // =====================================================================
    // Private helpers - Serial I/O
    // =====================================================================

    /// <summary>
    /// Checks whether the serial port is open. Must be called under <see cref="_portLock"/>.
    /// </summary>
    private bool IsPortOpen()
    {
        return _serialPort is { IsOpen: true };
    }

    /// <summary>
    /// Writes a byte buffer to the serial port. Must be called under <see cref="_portLock"/>.
    /// </summary>
    private void WriteBytes(byte[] buffer)
    {
        try
        {
            _serialPort!.Write(buffer, 0, buffer.Length);
        }
        catch (Exception ex)
        {
            _logger.Error("[Light] Serial write failed", ex);
        }
    }

    /// <summary>
    /// Serial port DataReceived handler. Currently a no-op, matching the
    /// original Delphi <c>CommLightRxChar</c> which was also empty.
    /// </summary>
    private void OnDataReceived(object sender, SerialDataReceivedEventArgs e)
    {
        // Intentionally empty - matches original Delphi implementation.
        // Future: parse response frames if the controller sends acknowledgments.
    }

    // =====================================================================
    // Private helpers - Messaging
    // =====================================================================

    /// <summary>
    /// Publishes a light event to the message bus.
    /// Replaces Delphi: <c>TCommLight.SendMessageMain</c> (WM_COPYDATA to m_hMain).
    /// </summary>
    /// <param name="mode">Message mode (e.g. <see cref="DefLight.CommCamLightConnection"/>).</param>
    /// <param name="channel">Channel index.</param>
    /// <param name="param">General-purpose parameter (maps to Delphi <c>nParam</c>).</param>
    /// <param name="message">Human-readable message text.</param>
    private void PublishEvent(int mode, int channel, int param, string message)
    {
        _messageBus.Publish(new LightEventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            Param2 = _lightType,
            Message = message,
        });
    }
}
