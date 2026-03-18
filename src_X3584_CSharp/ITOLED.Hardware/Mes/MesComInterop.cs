// =============================================================================
// MesComInterop.cs
// Converted from Delphi: DllMesCom.pas (TCommTibRv64)
// Provides P/Invoke interop with TIBCO_ECS_Converter.dll (clsGMES) for
// MES/EAS/R2R communication.
//
// TIBCO_ECS_Converter.dll is a .NET Framework 4.7.2 assembly built with
// DllExport 1.7.4. It depends on TIBCO.Rendezvous.dll which is a multi-file
// assembly (with .netmodule) — .NET 8 CoreCLR cannot load these directly.
//
// Calling via [DllImport] P/Invoke lets the DllExport native stub bootstrap
// the .NET Framework CLR, which handles the multi-file assembly correctly.
// =============================================================================

using System.Runtime.InteropServices;
using System.Text;
using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Hardware.Mes;

#region Native callback delegates

/// <summary>
/// Callback for data returned from MES/EAS/R2R servers.
/// <para>DLL side: <c>delegate void Callback_m_ReturnMsg(StringBuilder addedText)</c></para>
/// <para>P/Invoke receives: ANSI char* → IntPtr</para>
/// </summary>
[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void NativeReturnMsgCallback(IntPtr msg);

/// <summary>
/// Callback for log messages from the DLL.
/// <para>DLL side: <c>delegate void Callback_m_Log(int nMsgType, StringBuilder addedText)</c></para>
/// <para>P/Invoke receives: int, ANSI char* → int, IntPtr</para>
/// </summary>
[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void NativeLogCallback(int msgType, IntPtr msg);

#endregion

#region IMesCommunication interface

/// <summary>
/// Abstraction for MES (Manufacturing Execution System) communication
/// via TIBCO_ECS_Converter.dll (clsGMES via DllExport).
/// <para>Replaces Delphi <c>TCommTibRv64</c> from DllMesCom.pas.</para>
/// </summary>
public interface IMesCommunication : IDisposable
{
    /// <summary>
    /// Path for MES DLL log files.
    /// </summary>
    string LogPath { get; set; }

    /// <summary>
    /// Initialize a specific TIB server channel with connection parameters.
    /// </summary>
    /// <param name="channel">Server channel index (0 = MES, 1 = EAS, 2 = R2R).</param>
    /// <param name="servicePort">TIB service port.</param>
    /// <param name="network">TIB network address.</param>
    /// <param name="daemonPort">TIB daemon port.</param>
    /// <param name="localSubject">Local subject for message subscription.</param>
    /// <param name="remoteSubject">Remote subject for message publishing.</param>
    /// <returns><c>true</c> if the channel was initialized successfully.</returns>
    bool Initialize(int channel, string servicePort, string network,
                    string daemonPort, string localSubject, string remoteSubject);

    /// <summary>
    /// Send a message to a specific TIB server channel.
    /// Uses <c>Send_Data_New</c> with CRC16 checksum. Retries once on failure.
    /// </summary>
    bool SendData(int channel, string message);

    /// <summary>
    /// Register managed callbacks for MES, EAS, R2R data return and logging.
    /// Must be called after construction and before <see cref="Initialize"/>.
    /// </summary>
    void SetCallbacks(Action<string>? mesCallback, Action<string>? easCallback,
                      Action<string>? r2rCallback, Action<int, string>? logCallback);

    /// <summary>
    /// Terminate all active TIB server channels.
    /// </summary>
    void Terminate();

    /// <summary>
    /// Whether the DLL was loaded and Create_TIB succeeded.
    /// </summary>
    bool IsLoaded { get; }

    /// <summary>
    /// Error message if the DLL could not be loaded or Create_TIB failed.
    /// </summary>
    string ErrorMessage { get; }
}

#endregion

#region MesComManaged implementation

/// <summary>
/// P/Invoke wrapper for TIBCO_ECS_Converter.dll (clsGMES via DllExport),
/// providing MES/EAS/R2R communication.
/// <para>
/// Uses <c>[DllImport]</c> to call the DllExport'd native entry points.
/// The DllExport stub bootstraps .NET Framework CLR to execute the managed code,
/// which correctly handles the multi-file TIBCO.Rendezvous assembly (netmodule).
/// </para>
/// </summary>
public sealed class MesComManaged : IMesCommunication
{
    private const string DllName = "TIBCO_ECS_Converter.dll";

    private readonly ILogger _logger;
    private readonly int _serverCount;
    private bool _disposed;

    // ---------------------------------------------------------------------------
    // P/Invoke declarations for TIBCO_ECS_Converter.dll DllExport'd functions.
    // Parameter types match the DLL's clsGMES static method signatures.
    // StringBuilder → marshaled as LPSTR (ANSI char buffer) by P/Invoke.
    // ---------------------------------------------------------------------------

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern bool Create_TIB(int nCount);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    private static extern bool Init_TIB(int nCH, StringBuilder ServicePort);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    private static extern bool Send_Data(int nCH, StringBuilder sMsg);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    private static extern bool Send_Data_New(int nCH, int nLength, int CheckSum, StringBuilder sMsg);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void Callback_Log(NativeLogCallback handler);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void Callback_ReturnMsgMES(NativeReturnMsgCallback handler);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void Callback_ReturnMsgEAS(NativeReturnMsgCallback handler);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void Callback_ReturnMsgR2R(NativeReturnMsgCallback handler);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "Terminate")]
    private static extern void Terminate_TIB(int nCH);

    // ---------------------------------------------------------------------------
    // Callback delegates — must stay rooted to prevent GC collection.
    // The DLL internally holds native function pointers to these.
    // ---------------------------------------------------------------------------
    private NativeReturnMsgCallback? _pinnedMesCallback;
    private NativeReturnMsgCallback? _pinnedEasCallback;
    private NativeReturnMsgCallback? _pinnedR2RCallback;
    private NativeLogCallback? _pinnedLogCallback;

    /// <summary>
    /// ANSI code page used for CRC16 byte length calculation (Korean Windows: 949).
    /// </summary>
    private static readonly Encoding AnsiEncoding = Encoding.GetEncoding(949);

    /// <summary>
    /// Log path appended to the address string sent to Init_TIB.
    /// </summary>
    public string LogPath { get; set; } = string.Empty;

    /// <inheritdoc />
    public bool IsLoaded { get; private set; }

    /// <inheritdoc />
    public string ErrorMessage { get; private set; } = string.Empty;

    /// <summary>
    /// Creates a new <see cref="MesComManaged"/> instance.
    /// Pre-loads the DLL from the specified path and calls <c>Create_TIB</c>.
    /// </summary>
    /// <param name="logger">Application logger.</param>
    /// <param name="dllPath">Directory containing TIBCO_ECS_Converter.dll.</param>
    /// <param name="serverCount">Number of TIB server channels (typically 2 or 3).</param>
    public MesComManaged(ILogger logger, string dllPath, int serverCount)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _serverCount = serverCount;

        // Pre-load the DLL by full path so [DllImport] can find it by name.
        string fullPath = Path.Combine(dllPath, DllName);
        if (!File.Exists(fullPath))
        {
            ErrorMessage = $"Cannot find '{DllName}' in '{dllPath}'.";
            _logger.Error(ErrorMessage);
            return;
        }

        try
        {
            NativeLibrary.Load(fullPath);
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Failed to pre-load {DllName}: {ex.Message}";
            _logger.Error(ErrorMessage, ex);
            return;
        }

        try
        {
            bool created = Create_TIB(serverCount);
            IsLoaded = true;
            if (!created)
                _logger.Warn($"Create_TIB({serverCount}) returned false.");
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Create_TIB failed: {ex.Message}";
            _logger.Error(ErrorMessage, ex);
        }
    }

    /// <inheritdoc />
    public bool Initialize(
        int channel,
        string servicePort,
        string network,
        string daemonPort,
        string localSubject,
        string remoteSubject)
    {
        if (!IsLoaded)
        {
            _logger.Error("Init_TIB not available (DLL not loaded).");
            return false;
        }

        // Delphi: sAddr := ServicePort + ',' + Network + ',' + Deamon_Port + ',' +
        //         Local_Subject + ',' + Remote_Subject + ',' + sLogPath;
        string addr = string.Join(',', servicePort, network, daemonPort,
                                       localSubject, remoteSubject, LogPath);

        try
        {
            return Init_TIB(channel, new StringBuilder(addr));
        }
        catch (Exception ex)
        {
            _logger.Error($"Init_TIB(ch={channel}) exception: {ex.Message}", ex);
            return false;
        }
    }

    /// <inheritdoc />
    public bool SendData(int channel, string message)
    {
        if (!IsLoaded)
        {
            _logger.Error("Send_Data not available (DLL not loaded).");
            return false;
        }

        try
        {
            return SendDataWithCrc(channel, message);
        }
        catch (Exception ex)
        {
            _logger.Error($"SendData(ch={channel}) exception: {ex.Message}", ex);
            return false;
        }
    }

    /// <inheritdoc />
    public void SetCallbacks(
        Action<string>? mesCallback,
        Action<string>? easCallback,
        Action<string>? r2rCallback,
        Action<int, string>? logCallback)
    {
        if (!IsLoaded) return;

        // Bridge: DLL callback (IntPtr → ANSI) → managed Action<string>
        // Keep delegate references rooted to prevent GC collection.

        if (logCallback is not null)
        {
            _pinnedLogCallback = (msgType, pMsg) =>
            {
                try
                {
                    string msg = Marshal.PtrToStringAnsi(pMsg) ?? string.Empty;
                    logCallback(msgType, msg);
                }
                catch { /* prevent DLL callback from throwing */ }
            };
            Callback_Log(_pinnedLogCallback);
        }

        if (mesCallback is not null)
        {
            _pinnedMesCallback = pMsg =>
            {
                try
                {
                    string msg = Marshal.PtrToStringAnsi(pMsg) ?? string.Empty;
                    mesCallback(msg);
                }
                catch { /* prevent DLL callback from throwing */ }
            };
            Callback_ReturnMsgMES(_pinnedMesCallback);
        }

        if (easCallback is not null)
        {
            _pinnedEasCallback = pMsg =>
            {
                try
                {
                    string msg = Marshal.PtrToStringAnsi(pMsg) ?? string.Empty;
                    easCallback(msg);
                }
                catch { /* prevent DLL callback from throwing */ }
            };
            Callback_ReturnMsgEAS(_pinnedEasCallback);
        }

        if (r2rCallback is not null)
        {
            _pinnedR2RCallback = pMsg =>
            {
                try
                {
                    string msg = Marshal.PtrToStringAnsi(pMsg) ?? string.Empty;
                    r2rCallback(msg);
                }
                catch { /* prevent DLL callback from throwing */ }
            };
            Callback_ReturnMsgR2R(_pinnedR2RCallback);
        }
    }

    /// <inheritdoc />
    public void Terminate()
    {
        if (!IsLoaded) return;

        for (int i = 0; i < _serverCount; i++)
        {
            try
            {
                Terminate_TIB(i);
            }
            catch (Exception ex)
            {
                _logger.Error($"Error terminating TIB channel {i}.", ex);
            }
        }
    }

    #region IDisposable

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        Terminate();

        _pinnedMesCallback = null;
        _pinnedEasCallback = null;
        _pinnedR2RCallback = null;
        _pinnedLogCallback = null;

        GC.SuppressFinalize(this);
    }

    ~MesComManaged()
    {
        Dispose();
    }

    #endregion

    #region Private helpers

    /// <summary>
    /// Send data using <c>Send_Data_New</c> with CRC16 checksum. Retries once on failure.
    /// </summary>
    private bool SendDataWithCrc(int channel, string message)
    {
        int ansiLength = AnsiEncoding.GetByteCount(message);
        ushort checkSum = CommonUtility.Crc16(message, ansiLength);

        var sb = new StringBuilder(message);
        bool result = Send_Data_New(channel, ansiLength, checkSum, sb);

        // Retry once on failure (Delphi: if not bRet then ...)
        if (!result)
            result = Send_Data_New(channel, ansiLength, checkSum, sb);

        return result;
    }

    #endregion
}

#endregion
