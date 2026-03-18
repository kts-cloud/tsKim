// =============================================================================
// IOcDllService.cs
// Converted from Delphi: src_X3584\dllClass.pas
// Interface for the OC (Optical Compensation) inspection DLL service.
// Namespace: Dongaeltek.ITOLED.Core.Interfaces
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Interface for the OC (Optical Compensation) inspection DLL service.
/// Replaces Delphi's <c>TCSharpDll</c> from dllClass.pas.
/// <para>The underlying DLL is a C# assembly that manages OC inspection flows.
/// In the original Delphi application, it was loaded via <c>LoadLibrary</c> and
/// function pointers were resolved with <c>GetProcAddress</c>. In the C# conversion,
/// this becomes a direct .NET assembly reference behind this interface.</para>
/// <para>Delphi origin: TCSharpDll — dllClass.pas</para>
/// </summary>
public interface IOcDllService : IDisposable
{
    // =========================================================================
    // Per-channel state
    // =========================================================================

    /// <summary>
    /// Whether the OC process is complete for each channel.
    /// <para>Delphi origin: <c>TCSharpDll.m_bIsProcessDone : array of Boolean</c></para>
    /// </summary>
    bool[] IsProcessDone { get; }

    /// <summary>
    /// Whether the OC unload process is complete for each channel.
    /// <para>Delphi origin: <c>TCSharpDll.m_bIsProcessUnloadDone : array of Boolean</c></para>
    /// </summary>
    bool[] IsProcessUnloadDone { get; }

    /// <summary>
    /// Whether the DLL is currently working for each channel.
    /// <para>Delphi origin: <c>TCSharpDll.m_bIsDLLWork : array of Boolean</c></para>
    /// </summary>
    bool[] IsDllWorking { get; }

    /// <summary>
    /// Whether the OC flow has been started for each channel.
    /// <para>Delphi origin: <c>TCSharpDll.m_OCFlowStart : array[CH1..MAX_JIG_CH] of Boolean</c></para>
    /// </summary>
    bool[] OcFlowStarted { get; }

    /// <summary>
    /// Whether serial number check is pending for each channel.
    /// <para>Delphi origin: <c>TCSharpDll.m_OCCkSerialNB : array[CH1..MAX_JIG_CH] of Boolean</c></para>
    /// </summary>
    bool[] OcCheckSerialNb { get; }

    /// <summary>
    /// Current band index for each channel.
    /// <para>Delphi origin: <c>TCSharpDll.m_CurrentBand : array[CH1..MAX_JIG_CH] of Integer</c></para>
    /// </summary>
    int[] CurrentBand { get; }

    /// <summary>
    /// Pre-action NG code for each channel (0 = OK).
    /// </summary>
    int[] PreActionNg { get; }

    // =========================================================================
    // Initialization
    // =========================================================================

    /// <summary>
    /// Initializes the OC DLL with the given model name.
    /// Calls the DLL's internal initialize function with the channel count and model.
    /// <para>Delphi origin: <c>procedure TCSharpDll.Initialize(sModelName : string)</c></para>
    /// </summary>
    /// <param name="modelName">Model name string to pass to the DLL.</param>
    void Initialize(string modelName);

    /// <summary>
    /// Performs cleanup of the DLL resources.
    /// <para>Delphi origin: <c>procedure TCSharpDll.FormDestroy</c></para>
    /// </summary>
    void FormDestroy();

    // =========================================================================
    // OC Flow control
    // =========================================================================

    /// <summary>
    /// Starts the OC inspection flow for a given channel.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_Start(nDLLType, nCH, sPID, sSerialNumber, sUser_ID, sEquipment) : Integer</c></para>
    /// </summary>
    /// <param name="dllType">DLL type selector (varies by model configuration).</param>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="pid">Product ID string.</param>
    /// <param name="serialNumber">Serial number of the panel under test.</param>
    /// <param name="userId">Operator user ID.</param>
    /// <param name="equipment">Equipment identifier string.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int Start(int dllType, int channel, string pid, string serialNumber, string userId, string equipment);

    /// <summary>
    /// Stops the OC inspection flow for a given channel.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_Stop(nCH : Integer) : Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int Stop(int channel);

    /// <summary>
    /// Starts the verification step for a given channel.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_Verify_Start(nCH : Integer) : Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int VerifyStart(int channel);

    /// <summary>
    /// Checks the state of the OC processing thread for a given channel.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_ThreadStateCheck(nCH : Integer) : Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <returns>Thread state code.</returns>
    int ThreadStateCheck(int channel);

    /// <summary>
    /// Initiates a flash read operation for a given channel.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_Flash_Read(nCH : Integer) : Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int FlashRead(int channel);

    /// <summary>
    /// Checks whether the OC flow thread is still alive for a given channel.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_GetOCFlowIsAlive(nCH : Integer) : Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <returns>Non-zero if alive, 0 if not.</returns>
    int GetFlowIsAlive(int channel);

    // =========================================================================
    // Data retrieval
    // =========================================================================

    /// <summary>
    /// Retrieves a summary log data value for a given channel and parameter key.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_GetSummaryLogData(nCH, sParameter) : string</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="parameter">Parameter key to query from the summary log.</param>
    /// <returns>The summary log data value as a string.</returns>
    string GetSummaryLogData(int channel, string parameter);

    /// <summary>
    /// Retrieves the full summary log dictionary for a given channel.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_GetSummaryLogDictionary(nCH) : string</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <returns>The summary log dictionary as a serialized string.</returns>
    string GetSummaryLogDictionary(int channel);

    /// <summary>
    /// Gets the OC DLL version string for the given DLL type.
    /// <para>Delphi origin: <c>m_GetOCversion(nDLLType : Integer) : PAnsiChar</c></para>
    /// </summary>
    /// <param name="dllType">DLL type selector.</param>
    /// <returns>Version string.</returns>
    string GetOcVersion(int dllType);

    /// <summary>
    /// Gets the OC Converter version string.
    /// <para>Delphi origin: <c>m_GetOCConverterVersion : PAnsiChar</c></para>
    /// </summary>
    /// <returns>Converter version string, or empty if not available.</returns>
    string GetOcConverterVersion();

    // =========================================================================
    // DLL management
    // =========================================================================

    /// <summary>
    /// Changes the active OC DLL at runtime to a different assembly.
    /// <para>Delphi origin: <c>function TCSharpDll.MainOC_ChangeDLL(sDLLName : string) : Integer</c></para>
    /// </summary>
    /// <param name="dllName">Name or path of the DLL to switch to.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int ChangeDll(string dllName);
}
