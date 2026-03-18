// =============================================================================
// IOcDllCallbacks.cs
// Converted from Delphi: src_X3584\dllClass.pas
// Callback interface for OC DLL → host application interaction.
// Namespace: Dongaeltek.ITOLED.Core.Interfaces
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Callback interface for the OC DLL to call back into the host application.
/// These methods are registered with the DLL and called during OC inspection flows
/// to control hardware (TCON, flash, power, colorimeter) and report status.
/// <para>Delphi origin: <c>dllClass.pas</c> — <c>TCallbackRecord</c> and individual
/// callback type definitions (<c>TMyCB_*</c>) registered per channel via
/// <c>m_SetCallback_*</c> / <c>m_SetCallBack*</c> procedures.</para>
/// </summary>
public interface IOcDllCallbacks
{
    // =========================================================================
    // Power control
    // =========================================================================

    /// <summary>
    /// Turns all power on or off for a given channel.
    /// <para>Delphi origin: <c>TCallBackAllPowerOnOff = function(nChannel, OnOff: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="onOff">1 = power on, 0 = power off.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int AllPowerOnOff(int channel, int onOff);

    // =========================================================================
    // TCON register access (single byte)
    // =========================================================================

    /// <summary>
    /// Writes a single byte to a TCON register.
    /// <para>Delphi origin: <c>TCallBackTCONSetReg = function(nChannel, Addr: Integer; data: Byte): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="addr">Register address.</param>
    /// <param name="data">Byte value to write.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int TconSetReg(int channel, int addr, byte data);

    /// <summary>
    /// Reads a single byte from a TCON register.
    /// <para>Delphi origin: <c>TMyCB_TCONGetReg = function(nChannel, Addr: Integer; var data: Byte): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="addr">Register address.</param>
    /// <param name="data">On return, contains the byte value read.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int TconGetReg(int channel, int addr, out byte data);

    // =========================================================================
    // TCON register access (array / bulk)
    // =========================================================================

    /// <summary>
    /// Writes an array of bytes to TCON registers starting at a given address.
    /// <para>Delphi origin: <c>TCallBackTCONSetRegArray = function(nChannel, Addr: Integer; data: PByte; nLength: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="addr">Starting register address.</param>
    /// <param name="data">Byte array to write.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int TconSetRegArray(int channel, int addr, byte[] data);

    /// <summary>
    /// Reads an array of bytes from TCON registers starting at a given address.
    /// <para>Delphi origin: <c>TCallBackTCONGetRegArray = function(nChannel, Addr: Integer; data: PByte; nLength: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="addr">Starting register address.</param>
    /// <param name="data">Buffer to receive the read bytes (must be pre-allocated).</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int TconGetRegArray(int channel, int addr, byte[] data);

    /// <summary>
    /// Writes multiple TCON registers in a single batch operation (multi-write).
    /// <para>Delphi origin: <c>TCallBackTCONMultiSetReg = function(nChannel, nType: Integer; Addr: PINT; data: PByte; nLength: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="type">Write type / mode selector.</param>
    /// <param name="addrs">Array of register addresses to write.</param>
    /// <param name="data">Array of byte values corresponding to each address.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int TconMultiSetReg(int channel, int type, int[] addrs, byte[] data);

    /// <summary>
    /// Writes TCON registers in a sequential/indexed mode.
    /// <para>Delphi origin: <c>TCallBackTCONSeqSetReg = function(nChannel, nMode, nSeqIdx: Integer; Addr: PINT; data: PByte; nLength: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="mode">Sequence mode selector.</param>
    /// <param name="seqIdx">Sequence index.</param>
    /// <param name="addrs">Array of register addresses.</param>
    /// <param name="data">Array of byte values corresponding to each address.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int TconSeqSetReg(int channel, int mode, int seqIdx, int[] addrs, byte[] data);

    // =========================================================================
    // Flash memory operations
    // =========================================================================

    /// <summary>
    /// Writes data from a file to flash memory.
    /// <para>Delphi origin: <c>TCallBackFlashWrite_File = function(nChannel, nStartSeg, nLength: Integer; filePath: PAnsiChar): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="startSeg">Starting flash segment.</param>
    /// <param name="endSeg">Ending flash segment.</param>
    /// <param name="filePath">Path to the source file.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int FlashWriteFile(int channel, int startSeg, int endSeg, string filePath);

    /// <summary>
    /// Writes raw byte data to flash memory.
    /// <para>Delphi origin: <c>TCallBackFlashWrite_Data = function(nChannel, StartSeg, nLength: Integer; data: PByte): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="startSeg">Starting flash segment.</param>
    /// <param name="data">Byte array to write.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int FlashWriteData(int channel, int startSeg, byte[] data);

    /// <summary>
    /// Reads flash memory contents into a file.
    /// <para>Delphi origin: <c>TCallBackFlashRead_File = function(nChannel, StartSeg, nLength: Integer; filePath: PAnsiChar): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="startSeg">Starting flash segment.</param>
    /// <param name="length">Number of bytes/segments to read.</param>
    /// <param name="filePath">Destination file path.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int FlashReadFile(int channel, int startSeg, int length, string filePath);

    /// <summary>
    /// Reads flash memory contents into a byte buffer.
    /// <para>Delphi origin: <c>TCallBackFlashRead_Data = function(nChannel, nStartSeg, nLength: Integer; data: PByte): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="startSeg">Starting flash segment.</param>
    /// <param name="data">Buffer to receive the read data (must be pre-allocated).</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int FlashReadData(int channel, int startSeg, byte[] data);

    /// <summary>
    /// Erases a range of flash memory segments.
    /// <para>Delphi origin: <c>TCallBackFlashErase = function(nChannel, nStartSeg, nLength: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="startSeg">Starting flash segment.</param>
    /// <param name="length">Number of segments to erase.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int FlashErase(int channel, int startSeg, int length);

    // =========================================================================
    // Colorimeter / measurement
    // =========================================================================

    /// <summary>
    /// Measures XYL (chromaticity + luminance) values via the colorimeter (CA-410).
    /// <para>Delphi origin: <c>TCallBackMeasure_XYL = function(nChannel: Integer; t5: TArray&lt;double&gt;; nLen: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="measureData">On return, contains the measured XYL data array.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int MeasureXyl(int channel, out double[] measureData);

    /// <summary>
    /// Sets the colorimeter synchronization mode and frequency.
    /// <para>Delphi origin: <c>TCallBackSetSync = function(CA_SyncMode, CA_Hz, channel_num: Integer): Integer</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="syncMode">Synchronization mode (internal/external).</param>
    /// <param name="hz">Frequency in Hz.</param>
    /// <param name="channelNum">Colorimeter channel number.</param>
    /// <returns>0 on success, non-zero error code on failure.</returns>
    int SetSync(int channel, int syncMode, int hz, int channelNum);

    /// <summary>
    /// Captures waveform data from the colorimeter and computes flicker.
    /// Returns paired time/value arrays for AFM computation.
    /// <para>Delphi origin: <c>TCallBackGetWaveformData = function(nChannel: Integer; waveform_T, waveformData: TArray&lt;double&gt;; nMeasureAmount: Integer): Double</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="waveformT">Output array of time-axis sample points.</param>
    /// <param name="waveformData">Output array of measured waveform amplitude values.</param>
    /// <param name="measureAmount">Number of samples to capture.</param>
    /// <returns>Computed measurement value (e.g., JEITA flicker).</returns>
    double GetWaveformData(int channel, double[] waveformT, double[] waveformData, int measureAmount);

    /// <summary>
    /// Captures waveform data (simplified variant without output arrays).
    /// <para>Delphi origin: <c>TCallBackGetWaveformData_2 = function(nChannel: Integer; nMeasureAmount: Integer): Double</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="measureAmount">Number of samples to capture.</param>
    /// <returns>Computed measurement value.</returns>
    double GetWaveformData2(int channel, int measureAmount);

    // =========================================================================
    // Status / UI notification
    // =========================================================================

    /// <summary>
    /// Called by the DLL when text output changes (log messages during OC flow).
    /// <para>Delphi origin: <c>TCallBackTextChanged = procedure(channel_Index: Integer; bClear: Boolean; sAddedText: PAnsiChar)</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="clear">If true, clear existing text before appending.</param>
    /// <param name="text">Text to display or append.</param>
    void TextChanged(int channel, bool clear, string text);

    /// <summary>
    /// Called by the DLL when the OC flow completes for a channel.
    /// <para>Delphi origin: <c>TCallBackFlowDone = procedure(channel_Index: Integer)</c></para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    void FlowDone(int channel);
}
