// =============================================================================
// BcrDriver.cs
// Converted from Delphi: src_X3584\HandBCR.pas (TSerialBcr class)
// Namespace: Dongaeltek.ITOLED.Hardware.Bcr
// =============================================================================

using System.IO.Ports;
using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Hardware.Bcr;

// =============================================================================
// Event argument types
// =============================================================================

/// <summary>
/// Event data for <see cref="IBcrDriver.BarcodeReceived"/>.
/// Carries the scanned barcode string.
/// Original Delphi: <c>InBcrEvnt = procedure(sGetData : String) of object</c>
/// </summary>
public sealed class BarcodeReceivedEventArgs : EventArgs
{
    /// <summary>The barcode data received from the scanner.</summary>
    public required string BarcodeData { get; init; }
}

/// <summary>
/// Event data for <see cref="IBcrDriver.ConnectionChanged"/>.
/// Original Delphi: <c>InBcrConn = procedure(bConnected : Boolean; sMsg : string) of object</c>
/// </summary>
public sealed class BcrConnectionChangedEventArgs : EventArgs
{
    /// <summary>Whether the BCR serial port is currently connected.</summary>
    public required bool IsConnected { get; init; }

    /// <summary>
    /// Human-readable description (e.g. "COM3" when connected, "NONE" when disconnected).
    /// </summary>
    public required string Message { get; init; }
}

// =============================================================================
// Interface
// =============================================================================

/// <summary>
/// Abstraction over a hand-held barcode reader connected via RS-232 serial.
/// Mirrors the public surface of Delphi's <c>TSerialBcr</c> in HandBCR.pas.
/// </summary>
public interface IBcrDriver : IDisposable
{
    /// <summary>
    /// Whether the serial port is currently open and connected.
    /// Original Delphi: <c>m_bBcrConnection</c>
    /// </summary>
    bool IsConnected { get; }

    /// <summary>
    /// Opens the serial port on the specified COM port number (1-based),
    /// or closes and disconnects when <paramref name="portNumber"/> is 0.
    /// Original Delphi: <c>TSerialBcr.ChangePort</c>
    /// </summary>
    /// <param name="portNumber">
    /// 1-based COM port number (e.g. 3 for COM3).
    /// Pass 0 to close/disconnect.
    /// </param>
    void ChangePort(int portNumber);

    /// <summary>
    /// Raised when a complete barcode string has been received (terminated by CR).
    /// Original Delphi: <c>OnRevBcrData</c> event.
    /// </summary>
    event EventHandler<BarcodeReceivedEventArgs>? BarcodeReceived;

    /// <summary>
    /// Raised when the connection state changes (open/close/error).
    /// Original Delphi: <c>OnRevBcrConn</c> event.
    /// </summary>
    event EventHandler<BcrConnectionChangedEventArgs>? ConnectionChanged;
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// Hand-held barcode reader driver using <see cref="SerialPort"/> at 115200/8N1.
/// Replaces Delphi's <c>TSerialBcr</c> class that used TVaComm.
/// <para>
/// Packet detection uses CR (<c>\r</c>) as the line terminator, matching the
/// original Delphi <c>EventChars.EofChar := CR</c> configuration.
/// </para>
/// </summary>
public sealed class BcrDriver : IBcrDriver
{
    private readonly ILogger _logger;
    private SerialPort? _serialPort;
    private bool _disposed;

    /// <summary>
    /// Creates a new BCR driver instance.
    /// Original Delphi: <c>TSerialBcr.Create(AOwner: TComponent)</c>
    /// </summary>
    /// <param name="logger">Logger replacing Delphi's <c>Common.AddLog</c>.</param>
    public BcrDriver(ILogger logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    // =====================================================================
    // Properties
    // =====================================================================

    /// <inheritdoc />
    public bool IsConnected { get; private set; }

    // =====================================================================
    // Events
    // =====================================================================

    /// <inheritdoc />
    public event EventHandler<BarcodeReceivedEventArgs>? BarcodeReceived;

    /// <inheritdoc />
    public event EventHandler<BcrConnectionChangedEventArgs>? ConnectionChanged;

    // =====================================================================
    // ChangePort
    // =====================================================================

    /// <inheritdoc />
    public void ChangePort(int portNumber)
    {
        if (portNumber != 0)
        {
            try
            {
                // Close existing port if already open
                CloseSerialPort();

                var portName = $"COM{portNumber}";

                _serialPort = new SerialPort
                {
                    PortName  = portName,
                    BaudRate  = 115200,
                    Parity    = Parity.None,
                    DataBits  = 8,
                    StopBits  = StopBits.One,
                    NewLine   = "\r",   // CR as line terminator (Delphi: EventChars.EofChar := CR)
                    Encoding  = System.Text.Encoding.ASCII,
                    ReadTimeout  = SerialPort.InfiniteTimeout,
                    WriteTimeout = SerialPort.InfiniteTimeout,
                };

                _serialPort.DataReceived += OnSerialDataReceived;
                _serialPort.Open();

                IsConnected = true;
                RaiseConnectionChanged(true, portName);
            }
            catch (Exception ex)
            {
                _logger.Error($"<HAND-BCR> Failed to open COM{portNumber}: {ex.Message}", ex);
                IsConnected = false;
                RaiseConnectionChanged(false, $"COM{portNumber}");
            }
        }
        else
        {
            // portNumber == 0  =>  close / disconnect
            IsConnected = false;
            CloseSerialPort();
            RaiseConnectionChanged(false, "NONE");
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

        CloseSerialPort();
    }

    // =====================================================================
    // Private helpers
    // =====================================================================

    /// <summary>
    /// Handles <see cref="SerialPort.DataReceived"/> events.
    /// Reads complete lines (CR-terminated) and raises <see cref="BarcodeReceived"/>.
    /// Original Delphi: <c>TSerialBcr.ReadVaCom</c>
    /// </summary>
    private void OnSerialDataReceived(object sender, SerialDataReceivedEventArgs e)
    {
        if (_disposed || _serialPort is null || !_serialPort.IsOpen)
            return;

        try
        {
            // ReadLine blocks until CR is received (matching Delphi's EofChar = CR behavior).
            // SerialPort.DataReceived fires on a background thread, so ReadLine is safe here.
            while (_serialPort.BytesToRead > 0)
            {
                var data = _serialPort.ReadLine();

                _logger.Debug($"<HAND-BCR> Event Start Raw Data {data}");

                BarcodeReceived?.Invoke(this, new BarcodeReceivedEventArgs
                {
                    BarcodeData = data,
                });

                _logger.Debug($"<HAND-BCR> Event End {data}");
            }
        }
        catch (TimeoutException)
        {
            // ReadLine timed out — partial data, will be completed on next event
        }
        catch (InvalidOperationException)
        {
            // Port was closed between the check and ReadLine — expected during shutdown
        }
        catch (Exception ex)
        {
            _logger.Error($"<HAND-BCR> Error reading serial data: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Safely closes and disposes the current serial port, if any.
    /// Original Delphi: <c>TSerialBcr.Destroy</c> (comHandBcr.Close / Free).
    /// </summary>
    private void CloseSerialPort()
    {
        if (_serialPort is null)
            return;

        try
        {
            _serialPort.DataReceived -= OnSerialDataReceived;

            if (_serialPort.IsOpen)
                _serialPort.Close();
        }
        catch (Exception ex)
        {
            _logger.Error($"<HAND-BCR> Error closing serial port: {ex.Message}", ex);
        }
        finally
        {
            _serialPort.Dispose();
            _serialPort = null;
        }
    }

    /// <summary>
    /// Raises the <see cref="ConnectionChanged"/> event.
    /// </summary>
    private void RaiseConnectionChanged(bool isConnected, string message)
    {
        ConnectionChanged?.Invoke(this, new BcrConnectionChangedEventArgs
        {
            IsConnected = isConnected,
            Message = message,
        });
    }
}
