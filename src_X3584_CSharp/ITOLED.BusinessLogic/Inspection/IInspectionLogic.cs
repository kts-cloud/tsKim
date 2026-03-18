// =============================================================================
// IInspectionLogic.cs
// Converted from Delphi: src_X3584\LogicVh.pas (TLogic public interface)
// Per-channel inspection logic: timing, sequence, state, CSV reporting.
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Inspection
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Models;
using Dongaeltek.ITOLED.Hardware.Fpga;
using FlashData = Dongaeltek.ITOLED.Core.Definitions.FlashData;

namespace Dongaeltek.ITOLED.BusinessLogic.Inspection;

// =============================================================================
// Supporting Types (from LogicVh.pas record types)
// =============================================================================

/// <summary>
/// Inspection status enumeration.
/// <para>Delphi origin: TInspectionStatus = (IsStop, IsReady, IsRun)</para>
/// </summary>
public enum InspectionStatus
{
    /// <summary>Ready or Stop state. Delphi: IsStop</summary>
    Stop = 0,

    /// <summary>Got serial info, ready to run. Delphi: IsReady</summary>
    Ready = 1,

    /// <summary>Running inspection. Delphi: IsRun</summary>
    Running = 2,
}

/// <summary>
/// Per-channel inspection data record.
/// <para>Delphi origin: TInspectionInfo = record (LogicVh.pas line 16)</para>
/// </summary>
public class InspectionInfo
{
    /// <summary>Delphi: PowerOn : Boolean</summary>
    public bool PowerOn { get; set; }

    /// <summary>Delphi: IsScanned : Boolean</summary>
    public bool IsScanned { get; set; }

    /// <summary>Delphi: IsReport : Boolean</summary>
    public bool IsReport { get; set; }

    /// <summary>Delphi: IsLoaded : Boolean</summary>
    public bool IsLoaded { get; set; }

    /// <summary>Delphi: Fail_Message : string</summary>
    public string FailMessage { get; set; } = string.Empty;

    /// <summary>Delphi: Full_name : string</summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>Delphi: KeyIn : string</summary>
    public string KeyIn { get; set; } = string.Empty;

    /// <summary>Delphi: CarrierId : string</summary>
    public string CarrierId { get; set; } = string.Empty;

    /// <summary>Delphi: SerialNo : string</summary>
    public string SerialNo { get; set; } = string.Empty;

    /// <summary>Delphi: ZigId : string</summary>
    public string ZigId { get; set; } = string.Empty;

    /// <summary>Delphi: Result : string</summary>
    public string Result { get; set; } = string.Empty;

    /// <summary>Delphi: csvHeader : string</summary>
    public string CsvHeader { get; set; } = string.Empty;

    /// <summary>Delphi: csvData : string</summary>
    public string CsvData { get; set; } = string.Empty;

    /// <summary>Delphi: uniformity : Double</summary>
    public double Uniformity { get; set; }

    /// <summary>Delphi: TimeStart : TDateTime</summary>
    public DateTime TimeStart { get; set; }

    /// <summary>Delphi: TimeEnd : TDateTime</summary>
    public DateTime TimeEnd { get; set; }

    /// <summary>
    /// Resets all fields to default values.
    /// <para>Delphi origin: FillChar(m_Inspect, SizeOf(m_Inspect), 0) + manual field reset</para>
    /// </summary>
    public void Reset()
    {
        PowerOn = false;
        IsScanned = false;
        IsReport = false;
        IsLoaded = false;
        FailMessage = string.Empty;
        FullName = string.Empty;
        KeyIn = string.Empty;
        CarrierId = string.Empty;
        SerialNo = string.Empty;
        ZigId = string.Empty;
        Result = string.Empty;
        CsvHeader = string.Empty;
        CsvData = string.Empty;
        Uniformity = 0;
        TimeStart = default;
        TimeEnd = default;
    }
}

/// <summary>
/// CSV data result holder.
/// </summary>
public class CsvResult
{
    /// <summary>CSV header row.</summary>
    public string Header { get; set; } = string.Empty;

    /// <summary>CSV data row.</summary>
    public string Data { get; set; } = string.Empty;
}

// =============================================================================
// Main Interface
// =============================================================================

/// <summary>
/// Per-channel inspection logic interface.
/// Manages inspection flow: timing, sequence, state machine, CSV reporting.
/// One instance per PG channel (0..MAX_CH).
/// <para>Delphi origin: TLogic class (LogicVh.pas)</para>
/// </summary>
public interface IInspectionLogic : IDisposable
{
    // =========================================================================
    // Properties
    // =========================================================================

    /// <summary>
    /// PG channel index (0-based).
    /// <para>Delphi: FPgNo</para>
    /// </summary>
    int PgIndex { get; }

    /// <summary>
    /// Current inspection data.
    /// <para>Delphi: m_Inspect : TInspectionInfo</para>
    /// </summary>
    InspectionInfo Inspection { get; }

    /// <summary>
    /// Current inspection status (Stop/Ready/Running).
    /// <para>Delphi: m_InsStatus : TInspectionStatus</para>
    /// </summary>
    InspectionStatus Status { get; }

    /// <summary>
    /// Whether this channel is in use.
    /// <para>Delphi: m_bUse : boolean</para>
    /// </summary>
    bool IsInUse { get; set; }

    /// <summary>
    /// Whether the SW start has been triggered.
    /// <para>Delphi: m_IsSWStart : Boolean</para>
    /// </summary>
    bool IsSoftwareStarted { get; set; }

    /// <summary>
    /// Flash data buffer for this inspector channel.
    /// <para>Delphi: m_FlashAllData : TFlashData</para>
    /// </summary>
    FlashData FlashAllData { get; }

    /// <summary>
    /// Pattern group assigned to this channel.
    /// <para>Delphi: property PatGrp : TPatterGroup</para>
    /// </summary>
    PatterGroup? PatternGroup { get; set; }

    // =========================================================================
    // Initialization
    // =========================================================================

    /// <summary>
    /// Resets all inspection data to initial state.
    /// <para>Delphi origin: procedure TLogic.InitialData</para>
    /// </summary>
    void InitializeData();

    // =========================================================================
    // Inspection Flow
    // =========================================================================

    /// <summary>
    /// Starts BCR scan flow: initializes data, signals GUI clear and barcode ready.
    /// <para>Delphi origin: function TLogic.StartBcrScan : Boolean</para>
    /// </summary>
    /// <returns>True if scan started successfully, false if PG disconnected.</returns>
    bool StartBcrScan();

    /// <summary>
    /// Starts the inspection sequence at a given index.
    /// <para>Delphi origin: procedure TLogic.StartSeq(nIdx: Integer)</para>
    /// </summary>
    /// <param name="index">Sequence index to start.</param>
    void StartSequence(int index);

    /// <summary>
    /// Stops the current inspection and powers off.
    /// <para>Delphi origin: procedure TLogic.StopInspect</para>
    /// </summary>
    void StopInspection();

    /// <summary>
    /// Stops PLC-related work for this channel.
    /// <para>Delphi origin: procedure TLogic.StopPlcWork</para>
    /// </summary>
    void StopPlcWork();

    /// <summary>
    /// Reports inspection results: powers off, generates CSV, sends GMES data.
    /// <para>Delphi origin: procedure TLogic.ReportInspection</para>
    /// </summary>
    void ReportInspection();

    /// <summary>
    /// Stops inspection from alarm (force stop).
    /// <para>Delphi origin: procedure TLogic.StopFromAlarm</para>
    /// </summary>
    void StopFromAlarm();

    /// <summary>
    /// Stops the power measurement timer.
    /// <para>Delphi origin: procedure TLogic.StopPowerMeasureTimer</para>
    /// </summary>
    void StopPowerMeasureTimer();

    // =========================================================================
    // PG Operations
    // =========================================================================

    /// <summary>
    /// Checks if PG is connected and not in force-stop state.
    /// <para>Delphi origin: function TLogic.PgConnection : Boolean</para>
    /// </summary>
    /// <returns>True if PG is connected and available.</returns>
    bool IsPgConnected();

    /// <summary>
    /// Reads flash memory from PG.
    /// <para>Delphi origin: function TLogic.FlashRead(nStartAddr, nFlashReadSize): Integer</para>
    /// </summary>
    /// <param name="startAddr">Flash start address.</param>
    /// <param name="flashReadSize">Number of bytes to read.</param>
    /// <returns>0 = success, 1 = failure.</returns>
    int FlashRead(int startAddr, int flashReadSize);

    /// <summary>
    /// Sets the camera event return code and signals the camera event.
    /// <para>Delphi origin: procedure TLogic.MakeTEndEvt(nIdxErr: Integer)</para>
    /// </summary>
    /// <param name="indexError">Error index code.</param>
    void MakeTestEndEvent(int indexError);

    // =========================================================================
    // CSV / Data
    // =========================================================================

    /// <summary>
    /// Generates CSV header and data strings for the inspection report.
    /// <para>Delphi origin: procedure TLogic.GetCsvData(var sHead, sData: string; nTactTime: Integer)</para>
    /// </summary>
    /// <param name="tactTime">Tact time in tenths of a second.</param>
    /// <returns>CSV result containing header and data strings.</returns>
    CsvResult GetCsvData(int tactTime);

    // =========================================================================
    // Model Download
    // =========================================================================

    /// <summary>
    /// Sends model info download command to PG.
    /// <para>Delphi origin: procedure TLogic.SendModelInfoDownLoad(...)</para>
    /// </summary>
    /// <param name="sendDataCount">Number of data items to send.</param>
    /// <param name="fileTransRecords">File transfer records array.</param>
    void SendModelInfoDownload(int sendDataCount, FileTranStr[] fileTransRecords);
}
