// =============================================================================
// IonizerDriver.cs
// Converted from Delphi: src_X3584\CommIonizer.pas (TIonizer class)
// Namespace: Dongaeltek.ITOLED.Hardware.Ionizer
// =============================================================================

using System.IO.Ports;
using System.Text;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Ionizer;

// =============================================================================
// Constants (local to this unit, mirroring Delphi CommIonizer consts)
// =============================================================================

/// <summary>
/// Internal message mode constants used by the ionizer protocol.
/// Original Delphi constants in <c>CommIonizer</c> unit.
/// </summary>
internal static class IonizerMsgMode
{
    /// <summary>Original Delphi: MSG_MODE_IONIZER_CONNECTION = 1</summary>
    public const int Connection = 1;

    /// <summary>Original Delphi: MSG_MODE_IONIZER_ERR_MSG = 2</summary>
    public const int ErrorMessage = 2;

    /// <summary>Original Delphi: MSG_MODE_IONIZER_LOG = 3</summary>
    public const int Log = 3;

    /// <summary>Original Delphi: MSG_TESTFORM_IONIZER_STATUS = 400</summary>
    public const int TestFormStatus = 400;
}

// =============================================================================
// Enums
// =============================================================================

/// <summary>
/// Ionizer operational status.
/// Original Delphi: <c>TIonStatus = (IonNone, IonStop, IonRun, IonAlarm)</c>
/// </summary>
public enum IonStatus
{
    None,
    Stop,
    Run,
    Alarm,
}

/// <summary>
/// Ionizer hardware model type.
/// Original Delphi: <c>FModelType : Integer; // 0: SIB4, 1: SIB4A, 2: SIB5-S</c>
/// </summary>
public enum IonizerModelType
{
    /// <summary>SIB4 (prefix B5)</summary>
    Sib4 = 0,

    /// <summary>SIB4A (prefix B6)</summary>
    Sib4A = 1,

    /// <summary>SIB5-S (prefix BB)</summary>
    Sib5S = 2,
}

// =============================================================================
// Event args
// =============================================================================

/// <summary>
/// Event data raised when ionizer serial data is received.
/// Replaces Delphi callback: <c>InIonizerEvent = procedure(bIsConnect: Boolean; sGetData: String) of object</c>
/// </summary>
public sealed class IonizerDataReceivedEventArgs : EventArgs
{
    public bool IsConnected { get; init; }
    public string Data { get; init; } = string.Empty;
}

// =============================================================================
// Interface
// =============================================================================

/// <summary>
/// Abstraction over a serial ionizer controller (SIB4 / SIB4A / SIB5-S).
/// Mirrors the public surface of Delphi's <c>TIonizer</c>.
/// </summary>
public interface IIonizerDriver : IDisposable
{
    /// <summary>Whether the ionizer is currently responding to keepalive requests.</summary>
    bool IsConnected { get; }

    /// <summary>
    /// When true, all NG checks and outgoing commands are suppressed.
    /// Original Delphi: <c>TIonizer.IsIgnoreNg</c>
    /// </summary>
    bool IsIgnoreNg { get; set; }

    /// <summary>Current operational status.</summary>
    IonStatus Status { get; }

    /// <summary>
    /// Whether the script engine controls NG handling.
    /// Original Delphi: <c>m_bScriptControl</c>
    /// </summary>
    bool ScriptControl { get; set; }

    /// <summary>
    /// Opens/closes the serial port and sets the model type.
    /// Pass <paramref name="comPort"/> = 0 to close and disable the ionizer.
    /// Original Delphi: <c>TIonizer.ChangePort</c>
    /// </summary>
    void ChangePort(int comPort, IonizerModelType modelType);

    /// <summary>
    /// Sends a status request command (<c>,REQ,1</c>).
    /// Original Delphi: <c>TIonizer.SendRequest</c>
    /// </summary>
    void SendRequest();

    /// <summary>
    /// Sends a run command (<c>,RUN,1</c>).
    /// Original Delphi: <c>TIonizer.SendRun</c>
    /// </summary>
    void SendRun();

    /// <summary>
    /// Sends a stop command (<c>,STP,1</c>).
    /// Original Delphi: <c>TIonizer.SendStop</c>
    /// </summary>
    void SendStop();

    /// <summary>
    /// Sends an arbitrary command payload through the XOR-checksum protocol.
    /// The payload is prefixed with the model code and wrapped with <c>$...*XX\r\n</c>.
    /// Original Delphi: <c>TIonizer.SendMsg</c>
    /// </summary>
    void SendMsg(string data);

    /// <summary>
    /// Raised when a valid ionizer packet has been parsed from the serial port.
    /// Replaces Delphi: <c>OnRevIonizerData</c>
    /// </summary>
    event EventHandler<IonizerDataReceivedEventArgs>? OnIonizerDataReceived;
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// Serial ionizer driver wrapping <see cref="SerialPort"/> (9600/8N1).
/// Replaces Delphi's <c>TIonizer</c> class.
/// <para>
/// WM_COPYDATA inter-form messaging is replaced with <see cref="IMessageBus"/>
/// publishing <see cref="IonizerEventMessage"/> instances.
/// </para>
/// </summary>
public sealed class IonizerDriver : IIonizerDriver
{
    // =====================================================================
    // Fields
    // =====================================================================

    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly int _channelIndex;
    private readonly object _lock = new();

    private SerialPort? _serialPort;
    private Timer? _keepAliveTimer;
    private Timer? _timeoutTimer;

    private IonizerModelType _modelType;
    private int _connectCount;
    private string _readBuffer = string.Empty;
    private bool _disposed;

    // =====================================================================
    // Constructor
    // =====================================================================

    /// <summary>
    /// Creates a new ionizer driver instance.
    /// Original Delphi: <c>TIonizer.Create(nIdx, hMain, hTest, nMsgType)</c>
    /// </summary>
    /// <param name="messageBus">Message bus replacing WM_COPYDATA for UI notifications.</param>
    /// <param name="logger">Application logger.</param>
    /// <param name="channelIndex">0-based ionizer channel index.</param>
    public IonizerDriver(IMessageBus messageBus, ILogger logger, int channelIndex)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _channelIndex = channelIndex;

        // Original Delphi: tmIonTimeOut.Interval := 300; tmIonTimeOut.Enabled := False
        _timeoutTimer = new Timer(OnTimeoutElapsed, null, Timeout.Infinite, Timeout.Infinite);

        // Original Delphi: tmIonAliveCheck.Interval := 1000; tmIonAliveCheck.Enabled := True
        _keepAliveTimer = new Timer(OnKeepAliveElapsed, null, Timeout.Infinite, Timeout.Infinite);

        Status = IonStatus.Stop;
    }

    // =====================================================================
    // Properties
    // =====================================================================

    /// <inheritdoc />
    public bool IsConnected { get; private set; }

    /// <inheritdoc />
    public bool IsIgnoreNg { get; set; }

    /// <inheritdoc />
    public IonStatus Status { get; private set; }

    /// <inheritdoc />
    public bool ScriptControl { get; set; }

    // =====================================================================
    // Events
    // =====================================================================

    /// <inheritdoc />
    public event EventHandler<IonizerDataReceivedEventArgs>? OnIonizerDataReceived;

    // =====================================================================
    // Public methods
    // =====================================================================

    /// <inheritdoc />
    public void ChangePort(int comPort, IonizerModelType modelType)
    {
        _modelType = modelType;

        if (comPort != 0)
        {
            var portName = $"COM{comPort}";
            try
            {
                CloseSerialPort();

                _serialPort = new SerialPort
                {
                    PortName = portName,
                    BaudRate = 9600,
                    DataBits = 8,
                    Parity = Parity.None,
                    StopBits = StopBits.One,
                    Handshake = Handshake.None,
                    // Read events driven by DataReceived
                    ReceivedBytesThreshold = 1,
                    Encoding = Encoding.ASCII,
                };

                _serialPort.DataReceived += OnSerialDataReceived;
                _serialPort.Open();

                IsConnected = true;
                PublishMainGui(IonizerMsgMode.Connection, connectParam: 1, portName);
            }
            catch (Exception ex)
            {
                // 0 : disconnect, 1 : Connect, 2 : NONE
                PublishMainGui(IonizerMsgMode.Connection, connectParam: 0, portName);
                _logger.Error(_channelIndex, $"Ionizer ChangePort failed: {ex.Message}", ex);
            }

            // Enable keepalive timer (1s interval)
            _keepAliveTimer?.Change(1000, 1000);
        }
        else
        {
            // Disable keepalive
            _keepAliveTimer?.Change(Timeout.Infinite, Timeout.Infinite);
            PublishMainGui(IonizerMsgMode.Connection, connectParam: 2, "NONE");
            CloseSerialPort();
        }
    }

    /// <inheritdoc />
    public void SendRequest()
    {
        SendMsg(",REQ,1");
    }

    /// <inheritdoc />
    public void SendRun()
    {
        // '$B5,RUN,1,*CS' + CRLF
        SendMsg(",RUN,1");
    }

    /// <inheritdoc />
    public void SendStop()
    {
        // '$B5,STP,1,*CS' + CRLF
        SendMsg(",STP,1");
    }

    /// <inheritdoc />
    public void SendMsg(string data)
    {
        if (IsIgnoreNg) return;

        // Build model-specific prefix
        // Original Delphi: FModelType=0 -> "B5", 1 -> "B6", 2 -> "BB"
        var prefix = _modelType switch
        {
            IonizerModelType.Sib4A => "B6",
            IonizerModelType.Sib5S => "BB",
            _ => "B5", // Sib4 (default)
        };

        var payload = prefix + data;

        // ---------------------------------------------------------------
        // XOR checksum (byte-for-byte on the ASCII payload, excluding '$')
        // Original Delphi:
        //   sSendData := AnsiString(sTemp);
        //   btCheckSum := ord(sSendData[1]);
        //   for i := 2 to Length(sSendData) do
        //     btCheckSum := btCheckSum xor ord(sSendData[i]);
        //   btCheckSum := btCheckSum and $00ff;
        //   sSendData := '$' + sSendData + Format('*%0.2x',[btCheckSum]) + CR + LF;
        // ---------------------------------------------------------------
        var payloadBytes = Encoding.ASCII.GetBytes(payload);
        byte checksum = payloadBytes[0];
        for (var i = 1; i < payloadBytes.Length; i++)
        {
            checksum ^= payloadBytes[i];
        }
        checksum &= 0xFF;

        var frame = $"${payload}*{checksum:X2}\r\n";

        lock (_lock)
        {
            if (_serialPort is { IsOpen: true })
            {
                _serialPort.Write(frame);
                PublishMainGui(IonizerMsgMode.Log, connectParam: 3,
                    $"[ION BAR] CH : {_channelIndex} TX :{frame.TrimEnd()}");
            }
        }
    }

    // =====================================================================
    // IDisposable
    // =====================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        _keepAliveTimer?.Change(Timeout.Infinite, Timeout.Infinite);
        _keepAliveTimer?.Dispose();
        _keepAliveTimer = null;

        _timeoutTimer?.Change(Timeout.Infinite, Timeout.Infinite);
        _timeoutTimer?.Dispose();
        _timeoutTimer = null;

        CloseSerialPort();
    }

    // =====================================================================
    // Timer callbacks
    // =====================================================================

    /// <summary>
    /// Keepalive timer callback (1s interval).
    /// Sends a REQ command and starts the timeout timer.
    /// Original Delphi: <c>TIonizer.OnTimeIonizerCheck</c>
    /// </summary>
    private void OnKeepAliveElapsed(object? state)
    {
        if (_disposed) return;

        SendMsg(",REQ,1");

        // Start timeout timer (300ms one-shot)
        _timeoutTimer?.Change(300, Timeout.Infinite);
    }

    /// <summary>
    /// Timeout timer callback (300ms one-shot).
    /// Increments disconnect counter; after 10 consecutive timeouts marks disconnected.
    /// Original Delphi: <c>TIonizer.OnTimeIonTimeOut</c>
    /// </summary>
    private void OnTimeoutElapsed(object? state)
    {
        if (_disposed) return;

        if (IsIgnoreNg)
        {
            _connectCount = 0;
            return;
        }

        if (_connectCount > 10)
        {
            _connectCount = 0;
            IsConnected = false;
            PublishMainGui(IonizerMsgMode.Connection, connectParam: 3, "Disconnected");
            PublishMainGui(IonizerMsgMode.ErrorMessage, connectParam: 3, "Ionizer No Respose");
            PublishTestGui(IonizerMsgMode.TestFormStatus, string.Empty, param1: 0);
        }

        _connectCount++;
    }

    // =====================================================================
    // Serial port data handler
    // =====================================================================

    /// <summary>
    /// DataReceived handler for <see cref="SerialPort"/>.
    /// Accumulates incoming bytes, extracts fixed-length packets, and parses status.
    /// Original Delphi: <c>TIonizer.ReadVaCom</c>
    /// </summary>
    private void OnSerialDataReceived(object sender, SerialDataReceivedEventArgs e)
    {
        if (_disposed) return;

        try
        {
            string incoming;
            lock (_lock)
            {
                if (_serialPort is null || !_serialPort.IsOpen) return;
                incoming = _serialPort.ReadExisting();
            }

            PublishMainGui(IonizerMsgMode.Log, connectParam: 3, "[ION BAR]" + incoming);

            if (IsIgnoreNg) return;

            _readBuffer += incoming;

            // Original Delphi: if m_sReadData[1] <> '$' then clear buffer
            if (_readBuffer.Length > 0 && _readBuffer[0] != '$')
            {
                _readBuffer = string.Empty;
                return;
            }

            // Determine expected packet length by model
            // SIB5-S (model 2): 25 chars, others: 26 chars
            var packetLength = _modelType == IonizerModelType.Sib5S ? 25 : 26;

            if (_readBuffer.Length < packetLength) return;

            // Extract one packet and advance the buffer
            // Original Delphi: sPacket := Copy(m_sReadData, 1, packetLength);
            //                   m_sReadData := Copy(m_sReadData, packetLength, Length - packetLength);
            var packet = _readBuffer[..packetLength];
            _readBuffer = _readBuffer.Length > packetLength
                ? _readBuffer[packetLength..]
                : string.Empty;

            PublishMainGui(IonizerMsgMode.Log, connectParam: 3, $"[ION BAR] RX: {packet}");

            // Look for expected model prefix
            // Original Delphi: FModelType=0 -> "$B5", 1 -> "$B6", 2 -> "$BB"
            var expectedPrefix = _modelType switch
            {
                IonizerModelType.Sib4A => "$B6",
                IonizerModelType.Sib5S => "$BB",
                _ => "$B5",
            };

            var prefixPos = packet.IndexOf(expectedPrefix, StringComparison.Ordinal);

            // Stop the timeout timer since we received data
            // Original Delphi: tmIonTimeOut.Enabled := False
            _timeoutTimer?.Change(Timeout.Infinite, Timeout.Infinite);

            if (prefixPos >= 0)
            {
                _connectCount = 0;

                if (IsPacketStatusOk(packet, out var statusMsg))
                {
                    IsConnected = true;
                    PublishMainGui(IonizerMsgMode.Connection, connectParam: 1, "Connected");
                    PublishTestGui(IonizerMsgMode.TestFormStatus, string.Empty, param1: 1);
                    Status = IonStatus.Run;
                }
                else
                {
                    PublishMainGui(IonizerMsgMode.ErrorMessage, connectParam: 3, statusMsg);
                    PublishTestGui(IonizerMsgMode.TestFormStatus, string.Empty, param1: 0);
                    Status = IonStatus.Stop;
                    IsConnected = false;
                }
            }
            else
            {
                if (_connectCount > 3)
                {
                    _connectCount = 10;

                    if (IsConnected)
                    {
                        var modelName = _modelType switch
                        {
                            IonizerModelType.Sib4 => "SIB4",
                            IonizerModelType.Sib4A => "SIB4A",
                            IonizerModelType.Sib5S => "SIB5S",
                            _ => "Unknown",
                        };

                        _logger.Warn(_channelIndex, $"Ionizer Read Data: {packet}");
                        PublishMainGui(IonizerMsgMode.ErrorMessage, connectParam: 3,
                            $"{modelName} Model Config Check!");
                    }

                    IsConnected = false;
                }

                _connectCount++;
            }

            // Raise the C# event (replaces Delphi OnRevIonizerData callback)
            OnIonizerDataReceived?.Invoke(this, new IonizerDataReceivedEventArgs
            {
                IsConnected = IsConnected,
                Data = packet,
            });
        }
        catch (Exception ex)
        {
            _logger.Error(_channelIndex, $"Ionizer ReadVaCom Exception: {ex.Message}", ex);
        }
    }

    // =====================================================================
    // Private helpers
    // =====================================================================

    /// <summary>
    /// Parses the comma-separated response packet and determines ionizer health.
    /// Returns true when the ionizer is running with no alarms.
    /// Original Delphi: <c>TIonizer.IsConnectIonizer</c>
    /// </summary>
    /// <remarks>
    /// SIB5-S (model 2) packet format:  $BB,addr,freq,duty,pv,alarm,run*XX
    ///   - field[5] = alarm flag ('1' = H/V Alarm)
    ///   - field[6][0] = run flag ('0' = stopped)
    ///
    /// SIB4 / SIB4A packet format:  $B5,addr,freq,duty,pv,nv,pc,nc,alarm,run*XX
    ///   - field[8] = alarm flag (not '0' = H/V Alarm)
    ///   - field[9][0] = run flag ('0' = stopped)
    /// </remarks>
    private bool IsPacketStatusOk(string packet, out string statusMessage)
    {
        statusMessage = string.Empty;
        var isOk = true;

        // Split on commas (mirrors Delphi ExtractStrings([','], [], ...))
        var fields = packet.Split(',');

        if (_modelType == IonizerModelType.Sib5S)
        {
            if (fields.Length > 6)
            {
                if (fields[5] == "1")
                {
                    statusMessage += "H/V Alarm";
                    isOk = false;
                }

                var runField = fields[6];
                if (runField.Length > 0 && runField[0] == '0')
                {
                    statusMessage += "Stop Status";
                    // Original Delphi sets bRet := True here (stop is not an error)
                    isOk = true;
                }
            }
            else
            {
                statusMessage = "Protocol Format";
            }
        }
        else
        {
            // SIB4 / SIB4A
            if (fields.Length > 9)
            {
                if (fields[8] != "0")
                {
                    statusMessage += "H/V Alarm";
                    isOk = false;
                }

                var runField = fields[9];
                if (runField.Length > 0 && runField[0] == '0')
                {
                    statusMessage += "Stop Status";
                    isOk = true;
                }
            }
            else
            {
                statusMessage = "Protocol Format";
            }
        }

        return isOk;
    }

    /// <summary>
    /// Publishes an ionizer event to the main form via the message bus.
    /// Replaces Delphi: <c>TIonizer.SendMainGuiDisplay</c> (WM_COPYDATA to m_hMain).
    /// </summary>
    private void PublishMainGui(int mode, int connectParam, string message)
    {
        _messageBus.Publish(new IonizerEventMessage
        {
            Channel = _channelIndex,
            Mode = mode,
            Param = connectParam,
            Message = message,
        });
    }

    /// <summary>
    /// Publishes an ionizer event to the test form via the message bus.
    /// Replaces Delphi: <c>TIonizer.SendTestGuiDisplay</c> (WM_COPYDATA to m_hTest).
    /// </summary>
    private void PublishTestGui(int mode, string message, int param1 = 0)
    {
        _messageBus.Publish(new IonizerEventMessage
        {
            Channel = _channelIndex,
            Mode = mode,
            Param = param1,
            Message = message,
        });
    }

    /// <summary>
    /// Safely closes and disposes the current serial port.
    /// </summary>
    private void CloseSerialPort()
    {
        lock (_lock)
        {
            if (_serialPort is not null)
            {
                try
                {
                    if (_serialPort.IsOpen)
                        _serialPort.Close();
                }
                catch
                {
                    // Swallow close errors (port may already be closed or removed)
                }

                _serialPort.DataReceived -= OnSerialDataReceived;
                _serialPort.Dispose();
                _serialPort = null;
            }
        }

        _readBuffer = string.Empty;
    }
}
