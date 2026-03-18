// =============================================================================
// IDllManager.cs
// Converted from Delphi: src_X3584\dllClass.pas (TCSharpDll class)
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Dll
//
// The OC inspection DLL (OC_Converter_X3584.dll) is a managed .NET assembly
// referenced directly. This interface hides the DLL interaction details
// behind a clean contract that can be injected via DI.
// =============================================================================

namespace Dongaeltek.ITOLED.BusinessLogic.Dll;

/// <summary>
/// Manages the OC inspection DLL (OC_Converter_X3584) lifecycle and operations.
/// <para>Original Delphi: <c>TCSharpDll</c> class in dllClass.pas.</para>
/// <para>
/// Responsibilities:
/// <list type="bullet">
///   <item>Initialize the DLL with model name and factory configuration.</item>
///   <item>Register hardware callback delegates (TCON R/W, Flash, CA-410 measure, power).</item>
///   <item>Start/Stop/Verify OC inspection flows per channel.</item>
///   <item>Retrieve summary log data and version information.</item>
///   <item>Monitor flow-alive status via periodic polling.</item>
/// </list>
/// </para>
/// </summary>
public interface IDllManager : IDisposable
{
    // =========================================================================
    // Properties
    // =========================================================================

    /// <summary>
    /// Error message set during DLL loading.  Empty string means no error.
    /// <para>Original Delphi: <c>TCSharpDll.NgMsg : string</c></para>
    /// </summary>
    string NgMessage { get; }

    /// <summary>
    /// Whether the DLL was loaded successfully.
    /// </summary>
    bool IsLoaded { get; }

    /// <summary>
    /// LGD DLL version name(s), multi-line joined by \n.
    /// <para>Delphi: pnlLGDDLLName.Caption (set by MSG_TYPE_DLL Param=1)</para>
    /// </summary>
    string LgdDllName { get; }

    /// <summary>
    /// OC Converter DLL name (e.g. "OC_Converter_X3584").
    /// <para>Delphi: pnlOC_ConDLLName.Caption (set by MSG_TYPE_DLL Param=3)</para>
    /// </summary>
    string OcConDllName { get; }

    /// <summary>
    /// OC Converter version string.
    /// <para>Delphi: pnlOC_conVer.Caption (set by MSG_TYPE_DLL Param=2)</para>
    /// </summary>
    string OcConverterVersion { get; }

    /// <summary>
    /// Per-channel flag indicating whether the OC flow is currently running.
    /// <para>Original Delphi: <c>m_OCFlowStart[CH]</c></para>
    /// </summary>
    bool IsFlowRunning(int channel);

    /// <summary>
    /// Per-channel flag indicating whether the DLL inspection work is in progress.
    /// <para>Original Delphi: <c>m_bIsDLLWork[CH]</c></para>
    /// </summary>
    bool IsDllWorking(int channel);

    /// <summary>
    /// Per-channel flag indicating whether the process is done.
    /// <para>Original Delphi: <c>m_bIsProcessDone[CH]</c></para>
    /// </summary>
    bool IsProcessDone(int channel);

    /// <summary>
    /// Per-channel flag indicating whether the unload process is done.
    /// <para>Original Delphi: <c>m_bIsProcessUnloadDone[CH]</c></para>
    /// </summary>
    bool IsProcessUnloadDone(int channel);

    /// <summary>
    /// Per-channel current band index during OC flow.
    /// <para>Original Delphi: <c>m_CurrentBand[CH]</c></para>
    /// </summary>
    int GetCurrentBand(int channel);

    /// <summary>
    /// Per-channel pre-action NG code (0 = no error).
    /// <para>Original Delphi: <c>m_PreActionNG[CH]</c></para>
    /// </summary>
    int GetPreActionNg(int channel);

    /// <summary>
    /// Sets the per-channel pre-action NG code.
    /// </summary>
    void SetPreActionNg(int channel, int value);

    /// <summary>
    /// Per-channel serial number check flag for matching validation.
    /// <para>Original Delphi: <c>m_OCCkSerialNB[CH]</c></para>
    /// </summary>
    bool GetSerialNumberCheckFlag(int channel);

    /// <summary>
    /// Sets the per-channel serial number check flag.
    /// </summary>
    void SetSerialNumberCheckFlag(int channel, bool value);

    // =========================================================================
    // State setters for external coordination
    // =========================================================================

    /// <summary>
    /// Sets the per-channel DLL working flag.
    /// </summary>
    void SetDllWorking(int channel, bool value);

    /// <summary>
    /// Sets the per-channel process done flag.
    /// </summary>
    void SetProcessDone(int channel, bool value);

    /// <summary>
    /// Sets the per-channel process unload done flag.
    /// </summary>
    void SetProcessUnloadDone(int channel, bool value);

    // =========================================================================
    // Initialization
    // =========================================================================

    /// <summary>
    /// Initializes the DLL with model name and factory configuration JSON.
    /// Registers hardware callbacks for all channels.
    /// Retrieves DLL version information and DBV data.
    /// <para>Original Delphi: <c>TCSharpDll.Initialize(sModelName: string)</c></para>
    /// </summary>
    /// <param name="modelName">The model name to initialize with.</param>
    void Initialize(string modelName);

    /// <summary>
    /// Destroys the DLL form resources.
    /// <para>Original Delphi: <c>TCSharpDll.FormDestroy</c></para>
    /// </summary>
    void FormDestroy();

    // =========================================================================
    // OC Flow Control
    // =========================================================================

    /// <summary>
    /// Starts the OC inspection flow on the specified channel.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_Start(nDLLType, nCH, sPID, sSerialNumber, sUser_ID, sEquipment)</c></para>
    /// </summary>
    /// <param name="dllType">DLL type index for multi-DLL configurations.</param>
    /// <param name="channel">Channel number (0-based).</param>
    /// <param name="pid">Product ID.</param>
    /// <param name="serialNumber">Panel serial number.</param>
    /// <param name="userId">Operator user ID.</param>
    /// <param name="equipment">Equipment ID string.</param>
    /// <returns>0 = success, 2 = start function error.</returns>
    int StartOcFlow(int dllType, int channel, string pid, string serialNumber,
                    string userId, string equipment);

    /// <summary>
    /// Stops the OC inspection flow on the specified channel.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_Stop(nCH)</c></para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <returns>0 = success.</returns>
    int StopOcFlow(int channel);

    /// <summary>
    /// Waits for the OC flow thread to complete within the given timeout.
    /// </summary>
    bool WaitForFlowComplete(int channel, int timeoutMs = 10000);

    /// <summary>
    /// Starts the OC verification flow on the specified channel.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_Verify_Start(nCH)</c></para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <returns>Result code from the DLL.</returns>
    int StartVerify(int channel);

    /// <summary>
    /// Checks the thread state of the OC flow on the specified channel.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_ThreadStateCheck(nCH)</c></para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <returns>Thread state code from the DLL.</returns>
    int CheckThreadState(int channel);

    /// <summary>
    /// Initiates a flash read operation on the specified channel.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_Flash_Read(nCH)</c></para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <returns>Result code.</returns>
    int FlashRead(int channel);

    /// <summary>
    /// Checks whether the OC flow is still alive on the specified channel.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_GetOCFlowIsAlive(nCH)</c></para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <returns>Non-zero if alive, 0 if completed/dead.</returns>
    int GetOcFlowIsAlive(int channel);

    // =========================================================================
    // Data Retrieval
    // =========================================================================

    /// <summary>
    /// Retrieves summary log data for the specified channel.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_GetSummaryLogData(nCH, sParameter)</c></para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <param name="parameter">Parameter string to pass to the DLL.</param>
    /// <returns>Summary log data string from the DLL.</returns>
    string GetSummaryLogData(int channel, string parameter);

    /// <summary>
    /// Retrieves summary log data as a JSON dictionary string for the specified channel.
    /// Returns key-value pairs formatted as "OC:key:value,OC:key:value,...".
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_GetSummaryLogDictionary(nCH)</c></para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <returns>Formatted dictionary string.</returns>
    string GetSummaryLogDictionary(int channel);

    /// <summary>
    /// Changes the active DLL to a different one.
    /// <para>Original Delphi: <c>TCSharpDll.MainOC_ChangeDLL(sDLLName)</c></para>
    /// </summary>
    /// <param name="dllName">Name of the DLL to switch to.</param>
    /// <returns>0 = success.</returns>
    int ChangeDll(string dllName);

    // =========================================================================
    // Logging
    // =========================================================================

    /// <summary>
    /// Processes a message log entry from the DLL and forwards it to the UI.
    /// <para>Original Delphi: <c>TCSharpDll.MLOG(nChannel_Index, bClear, sMLOG)</c></para>
    /// </summary>
    /// <param name="channel">Channel index.</param>
    /// <param name="clear">Whether to clear the log display first.</param>
    /// <param name="message">Log message text.</param>
    void AddDllLog(int channel, bool clear, string message);
}
