// =============================================================================
// IDaeDioDriver.cs
// Abstraction for the DAE DIO hardware communication thread.
// Converted from Delphi: src_X3584\CommDIO_DAE.pas (TCommDIOThread)
// Namespace: Dongaeltek.ITOLED.Hardware.Dio
// =============================================================================

namespace Dongaeltek.ITOLED.Hardware.Dio;

/// <summary>
/// Low-level DAE DIO device communication driver interface.
/// Abstracts the Delphi <c>TCommDIOThread</c> (CommDaeDIO global) that manages
/// UDP-based communication with DAE digital I/O devices.
/// </summary>
public interface IDaeDioDriver : IDisposable
{
    // =========================================================================
    // Connection Status
    // =========================================================================

    /// <summary>
    /// Whether the DIO device is currently connected and communicating.
    /// <para>Delphi origin: CommDaeDIO.Connected</para>
    /// </summary>
    bool Connected { get; }

    // =========================================================================
    // Device Configuration
    // =========================================================================

    /// <summary>
    /// DIO device IP address.
    /// <para>Delphi origin: CommDaeDIO.DeviceIP</para>
    /// </summary>
    string DeviceIp { get; set; }

    /// <summary>
    /// DIO device TCP/UDP port.
    /// <para>Delphi origin: CommDaeDIO.DevicePort</para>
    /// </summary>
    int DevicePort { get; set; }

    /// <summary>
    /// DIO device polling interval in milliseconds.
    /// <para>Delphi origin: CommDaeDIO.PollingInterval</para>
    /// </summary>
    int PollingInterval { get; set; }

    /// <summary>
    /// Log file path for DIO communication logging.
    /// <para>Delphi origin: CommDaeDIO.LogPath</para>
    /// </summary>
    string LogPath { get; set; }

    /// <summary>
    /// Log level (0=minimal, higher=more verbose).
    /// <para>Delphi origin: CommDaeDIO.LogLevel</para>
    /// </summary>
    int LogLevel { get; set; }

    // =========================================================================
    // Digital Input Data Access
    // =========================================================================

    /// <summary>
    /// Reads a byte from the digital input data array.
    /// Each byte holds 8 input channels.
    /// <para>Delphi origin: CommDaeDIO.DIData[byteIndex]</para>
    /// </summary>
    /// <param name="byteIndex">Byte index (0..11 for 96 channels).</param>
    /// <returns>Byte containing 8 input channel states.</returns>
    byte GetInputByte(int byteIndex);

    /// <summary>
    /// Reads a specific digital input bit.
    /// </summary>
    /// <param name="signalIndex">Signal index (0..95).</param>
    /// <returns>True if the input bit is set (high).</returns>
    bool GetInputBit(int signalIndex);

    // =========================================================================
    // Digital Output Data Access
    // =========================================================================

    /// <summary>
    /// Reads a byte from the digital output flush data array (last written state).
    /// <para>Delphi origin: CommDaeDIO.DODataFlush[byteIndex]</para>
    /// </summary>
    /// <param name="byteIndex">Byte index (0..11 for 96 channels).</param>
    /// <returns>Byte containing 8 output channel states.</returns>
    byte GetOutputFlushByte(int byteIndex);

    /// <summary>
    /// Reads a specific digital output bit from the flush buffer.
    /// </summary>
    /// <param name="signalIndex">Signal index (0..95).</param>
    /// <returns>True if the output bit is set (high).</returns>
    bool GetOutputBit(int signalIndex);

    // =========================================================================
    // Digital Output Write Operations
    // =========================================================================

    /// <summary>
    /// Writes a single digital output bit.
    /// <para>Delphi origin: CommDaeDIO.WriteDO_Bit(nIdx, nPos, nValue)</para>
    /// </summary>
    /// <param name="byteIndex">Byte index of the output (signal / 8).</param>
    /// <param name="bitPosition">Bit position within the byte (signal % 8).</param>
    /// <param name="value">1 to set (ON), 0 to clear (OFF).</param>
    void WriteOutputBit(int byteIndex, int bitPosition, int value);

    // =========================================================================
    // Lifecycle
    // =========================================================================

    /// <summary>
    /// Starts the DIO communication thread (UDP polling).
    /// <para>Delphi origin: CommDaeDIO.Start</para>
    /// </summary>
    void Start();

    /// <summary>
    /// Stops the DIO communication thread.
    /// </summary>
    void Stop();

    // =========================================================================
    // Events
    // =========================================================================

    /// <summary>
    /// Raised when the DIO device connects or disconnects.
    /// <para>EventArgs.Param: 1=connected, 0=disconnected.</para>
    /// </summary>
    event EventHandler<DioNotifyEventArgs>? OnConnect;

    /// <summary>
    /// Raised when digital input data changes.
    /// <para>EventArgs.Message contains comma-separated "index=value" pairs.</para>
    /// </summary>
    event EventHandler<DioNotifyEventArgs>? OnInputChanged;

    /// <summary>
    /// Raised when digital output data changes.
    /// </summary>
    event EventHandler<DioNotifyEventArgs>? OnOutputChanged;

    /// <summary>
    /// Raised on communication errors.
    /// <para>EventArgs.Param: error code (100=disconnected).</para>
    /// </summary>
    event EventHandler<DioNotifyEventArgs>? OnError;
}

/// <summary>
/// Event arguments for DIO driver notifications.
/// Maps to Delphi's <c>PGuiDaeDio</c> structure fields.
/// </summary>
public class DioNotifyEventArgs : EventArgs
{
    /// <summary>Notification mode (COMMDIO_MSG_xxx constant).</summary>
    public int Mode { get; init; }

    /// <summary>General-purpose parameter.</summary>
    public int Param { get; init; }

    /// <summary>Second parameter.</summary>
    public int Param2 { get; init; }

    /// <summary>Message text (e.g., comma-separated changed-signal list).</summary>
    public string Message { get; init; } = string.Empty;
}
