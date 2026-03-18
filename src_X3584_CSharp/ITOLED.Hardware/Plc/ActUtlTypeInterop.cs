// =============================================================================
// ActUtlTypeInterop.cs
// P/Invoke wrapper for Mitsubishi ActUtlType64 DLL.
// Converted from Delphi: DllActUtlType64Com.pas (TDLLActUtlType64).
//
// The Delphi original uses LoadLibrary/GetProcAddress for dynamic binding.
// This C# version uses NativeLibrary.Load + NativeLibrary.GetExport +
// Marshal.GetDelegateForFunctionPointer for the same pattern.
//
// The Delphi WM_COPYDATA SendMessage for GUI display is replaced by
// IMessageBus.Publish<GuiLogMessage>().
//
// Namespace: Dongaeltek.ITOLED.Hardware.Plc
// =============================================================================

using System.Runtime.InteropServices;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Plc;

/// <summary>
/// Concrete implementation of <see cref="IActUtlType"/> that dynamically loads
/// the Mitsubishi ActUtlType64 native DLL at runtime.
/// <para>
/// Replaces Delphi's <c>TDLLActUtlType64</c> from DllActUtlType64Com.pas.
/// All native function pointers are resolved via
/// <see cref="NativeLibrary.GetExport"/> using the same export names as
/// the original Delphi GetProcAddress calls.
/// </para>
/// </summary>
public sealed unsafe class ActUtlTypeInterop : IActUtlType
{
    // ── Native delegate types (cdecl calling convention) ─────────────────

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DCreate_ActType64();

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DSetActLogicalStationNumber(int logicalStationNumber);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate int DOpen();

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate int DClose();

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DGetDevice(
        IntPtr deviceName, int* deviceValue, ref int returnCode);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DSetDevice(
        IntPtr deviceName, int* deviceValue, ref int returnCode);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DReadDeviceBlock(
        IntPtr deviceName, int numberOfData, int* deviceValues, ref int returnCode);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DWriteDeviceBlock(
        IntPtr deviceName, int numberOfData, int* deviceValues, ref int returnCode);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DReadBuffer(
        int startIO, int address, int size, short* data, ref int returnCode);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DWriteBuffer(
        int startIO, int address, int size, short* data, ref int returnCode);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void DGetClockData(
        out short year, out short month, out short day, out short dayOfWeek,
        out short hour, out short minute, out short second,
        ref int returnCode);

    // ── Resolved function pointers ───────────────────────────────────────

    private DCreate_ActType64? _fnCreate;
    private DSetActLogicalStationNumber? _fnSetStation;
    private DOpen? _fnOpen;
    private DClose? _fnClose;
    private DGetDevice? _fnGetDevice;
    private DSetDevice? _fnSetDevice;
    private DReadDeviceBlock? _fnReadDeviceBlock;
    private DWriteDeviceBlock? _fnWriteDeviceBlock;
    private DReadBuffer? _fnReadBuffer;
    private DWriteBuffer? _fnWriteBuffer;
    private DGetClockData? _fnGetClockData;

    // ── Instance state ───────────────────────────────────────────────────

    private IntPtr _hDll;
    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private bool _disposed;

    // ── Public properties ────────────────────────────────────────────────

    /// <inheritdoc />
    public bool IsLoaded => _hDll != IntPtr.Zero;

    /// <inheritdoc />
    public bool Connected => IsLoaded;

    /// <inheritdoc />
    public string ErrorMessage { get; private set; } = string.Empty;

    // ── Constructor ──────────────────────────────────────────────────────

    /// <summary>
    /// Loads the native ActUtlType64 DLL and resolves all exported functions.
    /// </summary>
    /// <param name="dllDirectory">
    /// Directory containing the DLL. Corresponds to Delphi's <c>sDLLPath</c>.
    /// </param>
    /// <param name="dllFileName">
    /// DLL file name (e.g. "ActUtlType64Com.dll"). Corresponds to Delphi's <c>sFileName</c>.
    /// </param>
    /// <param name="messageBus">
    /// Message bus replacing WM_COPYDATA SendMessage for GUI notifications.
    /// </param>
    /// <param name="logger">Application logger.</param>
    public ActUtlTypeInterop(
        string dllDirectory,
        string dllFileName,
        IMessageBus messageBus,
        ILogger logger)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        var dllPath = Path.Combine(dllDirectory, dllFileName);

        if (!File.Exists(dllPath))
        {
            ErrorMessage = $"[{dllDirectory}]\r\n Cannot find the file.!";
            _logger.Error($"ActUtlTypeInterop: {ErrorMessage}");
            return;
        }

        try
        {
            _hDll = NativeLibrary.Load(dllPath);
        }
        catch (DllNotFoundException ex)
        {
            ErrorMessage = $"NativeLibrary.Load failed: {ex.Message}";
            _logger.Error("ActUtlTypeInterop: loadlibrary returns 0", ex);
            return;
        }

        if (_hDll == IntPtr.Zero)
        {
            ErrorMessage = " loadlibrary returns 0";
            _logger.Error($"ActUtlTypeInterop: {ErrorMessage}");
            return;
        }

        ResolveExports();
    }

    // ── IActUtlType implementation ───────────────────────────────────────

    /// <inheritdoc />
    public void CreateActType64()
    {
        ThrowIfNotLoaded();
        _fnCreate!();
    }

    /// <inheritdoc />
    public void SetActLogicalStationNumber(int logicalStationNumber)
    {
        ThrowIfNotLoaded();
        _fnSetStation!(logicalStationNumber);
    }

    /// <inheritdoc />
    public int Open()
    {
        ThrowIfNotLoaded();
        return _fnOpen!();
    }

    /// <inheritdoc />
    public int Close()
    {
        ThrowIfNotLoaded();
        return _fnClose!();
    }

    /// <inheritdoc />
    public void GetDevice(string deviceName, ref int deviceValue, ref int returnCode)
    {
        ThrowIfNotLoaded();

        var pName = Marshal.StringToHGlobalAnsi(deviceName);
        try
        {
            int value = deviceValue;
            _fnGetDevice!(pName, &value, ref returnCode);
            deviceValue = value;
        }
        finally
        {
            Marshal.FreeHGlobal(pName);
        }
    }

    /// <inheritdoc />
    public void SetDevice(string deviceName, ref int deviceValue, ref int returnCode)
    {
        ThrowIfNotLoaded();

        var pName = Marshal.StringToHGlobalAnsi(deviceName);
        try
        {
            int value = deviceValue;
            _fnSetDevice!(pName, &value, ref returnCode);
            deviceValue = value;
        }
        finally
        {
            Marshal.FreeHGlobal(pName);
        }
    }

    /// <inheritdoc />
    public void ReadDeviceBlock(string deviceName, int numberOfData, int[] deviceValues, ref int returnCode)
    {
        ThrowIfNotLoaded();
        ArgumentNullException.ThrowIfNull(deviceValues);

        if (deviceValues.Length < numberOfData)
            throw new ArgumentException(
                $"Buffer too small: need {numberOfData} elements but got {deviceValues.Length}.",
                nameof(deviceValues));

        var pName = Marshal.StringToHGlobalAnsi(deviceName);
        try
        {
            fixed (int* pValues = deviceValues)
            {
                _fnReadDeviceBlock!(pName, numberOfData, pValues, ref returnCode);
            }
        }
        finally
        {
            Marshal.FreeHGlobal(pName);
        }
    }

    /// <inheritdoc />
    public void WriteDeviceBlock(string deviceName, int numberOfData, int[] deviceValues, ref int returnCode)
    {
        ThrowIfNotLoaded();
        ArgumentNullException.ThrowIfNull(deviceValues);

        if (deviceValues.Length < numberOfData)
            throw new ArgumentException(
                $"Buffer too small: need {numberOfData} elements but got {deviceValues.Length}.",
                nameof(deviceValues));

        var pName = Marshal.StringToHGlobalAnsi(deviceName);
        try
        {
            fixed (int* pValues = deviceValues)
            {
                _fnWriteDeviceBlock!(pName, numberOfData, pValues, ref returnCode);
            }
        }
        finally
        {
            Marshal.FreeHGlobal(pName);
        }
    }

    /// <inheritdoc />
    public void ReadBuffer(int startIO, int address, int size, short[] data, ref int returnCode)
    {
        ThrowIfNotLoaded();
        ArgumentNullException.ThrowIfNull(data);

        if (data.Length < size)
            throw new ArgumentException(
                $"Buffer too small: need {size} elements but got {data.Length}.",
                nameof(data));

        fixed (short* pData = data)
        {
            _fnReadBuffer!(startIO, address, size, pData, ref returnCode);
        }
    }

    /// <inheritdoc />
    public void WriteBuffer(int startIO, int address, int size, short[] data, ref int returnCode)
    {
        ThrowIfNotLoaded();
        ArgumentNullException.ThrowIfNull(data);

        if (data.Length < size)
            throw new ArgumentException(
                $"Buffer too small: need {size} elements but got {data.Length}.",
                nameof(data));

        fixed (short* pData = data)
        {
            _fnWriteBuffer!(startIO, address, size, pData, ref returnCode);
        }
    }

    /// <inheritdoc />
    public void GetClockData(
        out short year, out short month, out short day, out short dayOfWeek,
        out short hour, out short minute, out short second,
        ref int returnCode)
    {
        ThrowIfNotLoaded();
        _fnGetClockData!(out year, out month, out day, out dayOfWeek,
                         out hour, out minute, out second, ref returnCode);
    }

    // ── GUI notification (replaces Delphi WM_COPYDATA SendMessage) ──────

    /// <summary>
    /// Publishes a GUI log message via the message bus.
    /// Replaces Delphi's <c>SendTestGuiDisplay</c> which used
    /// WM_COPYDATA/SendMessage to the main form handle.
    /// </summary>
    /// <param name="channel">Inspection channel index.</param>
    /// <param name="mode">GUI mode / sub-command.</param>
    /// <param name="message">Display message text.</param>
    /// <param name="param">General-purpose parameter.</param>
    private void PublishGuiMessage(int channel, int mode, string message, int param = 0)
    {
        _messageBus.Publish(new GuiLogMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            Message = message
        });
    }

    // ── Native export resolution ─────────────────────────────────────────

    /// <summary>
    /// Resolves all DLL exports into managed delegates.
    /// Mirrors Delphi's <c>SetFunction</c> procedure.
    /// Export names match the original GetProcAddress strings exactly.
    /// </summary>
    private void ResolveExports()
    {
        _fnCreate = GetDelegate<DCreate_ActType64>("Create_ActTpye64");
        _fnSetStation = GetDelegate<DSetActLogicalStationNumber>("SetActLogicalStationNumber");
        _fnOpen = GetDelegate<DOpen>("Open");
        _fnClose = GetDelegate<DClose>("Close");
        _fnGetDevice = GetDelegate<DGetDevice>("GetDevice");
        _fnSetDevice = GetDelegate<DSetDevice>("SetDevice");
        _fnReadDeviceBlock = GetDelegate<DReadDeviceBlock>("ReadDeviceBlock");
        _fnWriteDeviceBlock = GetDelegate<DWriteDeviceBlock>("WriteDeviceBlock");
        _fnReadBuffer = GetDelegate<DReadBuffer>("ReadBuffer");
        _fnWriteBuffer = GetDelegate<DWriteBuffer>("WriteBuffer");
        _fnGetClockData = GetDelegate<DGetClockData>("GetClockData");
    }

    /// <summary>
    /// Resolves a single export by name and converts to a typed delegate.
    /// Logs a warning (but does not throw) if the export is missing,
    /// matching Delphi's behavior where GetProcAddress returns nil silently.
    /// </summary>
    private T? GetDelegate<T>(string exportName) where T : Delegate
    {
        if (!NativeLibrary.TryGetExport(_hDll, exportName, out var address))
        {
            var msg = $"ActUtlTypeInterop: Export '{exportName}' not found in DLL.";
            _logger.Warn(msg);
            ErrorMessage = msg;
            return null;
        }

        return Marshal.GetDelegateForFunctionPointer<T>(address);
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private void ThrowIfNotLoaded()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        if (_hDll == IntPtr.Zero)
            throw new InvalidOperationException(
                $"Native DLL not loaded. {ErrorMessage}");
    }

    // ── IDisposable ──────────────────────────────────────────────────────

    /// <summary>
    /// Frees the native DLL handle.
    /// </summary>
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        // Clear delegate references before freeing the library
        _fnCreate = null;
        _fnSetStation = null;
        _fnOpen = null;
        _fnClose = null;
        _fnGetDevice = null;
        _fnSetDevice = null;
        _fnReadDeviceBlock = null;
        _fnWriteDeviceBlock = null;
        _fnReadBuffer = null;
        _fnWriteBuffer = null;
        _fnGetClockData = null;

        if (_hDll != IntPtr.Zero)
        {
            NativeLibrary.Free(_hDll);
            _hDll = IntPtr.Zero;
        }
    }
}
