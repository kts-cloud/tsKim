// =============================================================================
// IActUtlType.cs
// Interface for Mitsubishi ActUtlType64 PLC communication.
// Extracted from Delphi: DllActUtlType64Com.pas (TDLLActUtlType64 public API).
//
// Namespace: Dongaeltek.ITOLED.Hardware.Plc
// =============================================================================

namespace Dongaeltek.ITOLED.Hardware.Plc;

/// <summary>
/// Abstraction over the Mitsubishi ActUtlType64 COM/DLL interface.
/// <para>
/// Enables unit testing by decoupling callers from the native DLL.
/// The concrete implementation (<see cref="ActUtlTypeInterop"/>) loads the
/// unmanaged DLL at runtime via <see cref="System.Runtime.InteropServices.NativeLibrary"/>.
/// </para>
/// </summary>
public interface IActUtlType : IDisposable
{
    /// <summary>
    /// Whether the native DLL was loaded successfully.
    /// </summary>
    bool IsLoaded { get; }

    /// <summary>
    /// Whether the underlying connection to the PLC is established and ready.
    /// For TCP mode: true when TCP socket is connected to ActUtilTCPServer.exe.
    /// For DLL mode: true when IsLoaded (no separate connection state).
    /// </summary>
    bool Connected { get; }

    /// <summary>
    /// Error message set when the DLL fails to load or a function export is missing.
    /// Empty when <see cref="IsLoaded"/> is true.
    /// </summary>
    string ErrorMessage { get; }

    /// <summary>
    /// Creates the internal ActUtlType64 COM object inside the DLL.
    /// Must be called before any other operation.
    /// </summary>
    void CreateActType64();

    /// <summary>
    /// Sets the logical station number for the PLC connection.
    /// </summary>
    /// <param name="logicalStationNumber">Station number configured in GX Works.</param>
    void SetActLogicalStationNumber(int logicalStationNumber);

    /// <summary>
    /// Opens the communication channel to the PLC.
    /// </summary>
    /// <returns>0 on success; non-zero Mitsubishi error code on failure.</returns>
    int Open();

    /// <summary>
    /// Closes the communication channel to the PLC.
    /// </summary>
    /// <returns>0 on success; non-zero error code on failure.</returns>
    int Close();

    /// <summary>
    /// Reads a single device value from the PLC.
    /// </summary>
    /// <param name="deviceName">Device name (e.g. "D100", "M200").</param>
    /// <param name="deviceValue">Receives the read value.</param>
    /// <param name="returnCode">Receives the Mitsubishi return code (0 = success).</param>
    void GetDevice(string deviceName, ref int deviceValue, ref int returnCode);

    /// <summary>
    /// Writes a single device value to the PLC.
    /// </summary>
    /// <param name="deviceName">Device name (e.g. "D100", "M200").</param>
    /// <param name="deviceValue">Value to write.</param>
    /// <param name="returnCode">Receives the Mitsubishi return code (0 = success).</param>
    void SetDevice(string deviceName, ref int deviceValue, ref int returnCode);

    /// <summary>
    /// Reads a contiguous block of device values from the PLC.
    /// </summary>
    /// <param name="deviceName">Starting device name.</param>
    /// <param name="numberOfData">Number of consecutive devices to read.</param>
    /// <param name="deviceValues">Buffer receiving the read values (must have at least <paramref name="numberOfData"/> elements).</param>
    /// <param name="returnCode">Receives the Mitsubishi return code (0 = success).</param>
    void ReadDeviceBlock(string deviceName, int numberOfData, int[] deviceValues, ref int returnCode);

    /// <summary>
    /// Writes a contiguous block of device values to the PLC.
    /// </summary>
    /// <param name="deviceName">Starting device name.</param>
    /// <param name="numberOfData">Number of consecutive devices to write.</param>
    /// <param name="deviceValues">Buffer containing values to write.</param>
    /// <param name="returnCode">Receives the Mitsubishi return code (0 = success).</param>
    void WriteDeviceBlock(string deviceName, int numberOfData, int[] deviceValues, ref int returnCode);

    /// <summary>
    /// Reads data from the PLC buffer memory.
    /// </summary>
    /// <param name="startIO">Start I/O number of the target module.</param>
    /// <param name="address">Start address in buffer memory.</param>
    /// <param name="size">Number of points (short values) to read.</param>
    /// <param name="data">Buffer receiving the read data (must have at least <paramref name="size"/> elements).</param>
    /// <param name="returnCode">Receives the Mitsubishi return code (0 = success).</param>
    void ReadBuffer(int startIO, int address, int size, short[] data, ref int returnCode);

    /// <summary>
    /// Writes data to the PLC buffer memory.
    /// </summary>
    /// <param name="startIO">Start I/O number of the target module.</param>
    /// <param name="address">Start address in buffer memory.</param>
    /// <param name="size">Number of points (short values) to write.</param>
    /// <param name="data">Buffer containing data to write.</param>
    /// <param name="returnCode">Receives the Mitsubishi return code (0 = success).</param>
    void WriteBuffer(int startIO, int address, int size, short[] data, ref int returnCode);

    /// <summary>
    /// Reads the PLC's real-time clock.
    /// </summary>
    /// <param name="year">Receives the year (last 2 digits).</param>
    /// <param name="month">Receives the month (1-12).</param>
    /// <param name="day">Receives the day (1-31).</param>
    /// <param name="dayOfWeek">Receives the day of week (0=Sun..6=Sat).</param>
    /// <param name="hour">Receives the hour (0-23).</param>
    /// <param name="minute">Receives the minute (0-59).</param>
    /// <param name="second">Receives the second (0-59).</param>
    /// <param name="returnCode">Receives the Mitsubishi return code (0 = success).</param>
    void GetClockData(
        out short year, out short month, out short day, out short dayOfWeek,
        out short hour, out short minute, out short second,
        ref int returnCode);
}
