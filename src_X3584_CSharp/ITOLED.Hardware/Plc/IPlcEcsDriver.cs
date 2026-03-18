// =============================================================================
// IPlcEcsDriver.cs
// Public interface for PLC/ECS communication driver.
// Converted from Delphi: src_X3584\CommPLC_ECS.pas (TCommPLCThread public API)
// Namespace: Dongaeltek.ITOLED.Hardware.Plc
// =============================================================================

using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Hardware.Plc;

// =========================================================================
// Supporting Records (converted from Delphi packed records)
// =========================================================================

/// <summary>
/// ECS Glass Data structure processed from PLC word blocks.
/// <para>Delphi origin: TECSGlassData (CommPLC_ECS.pas line 151)</para>
/// </summary>
public class EcsGlassData
{
    /// <summary>Carrier (LOT) ID, 16 chars from 8 words.</summary>
    public string CarrierId { get; set; } = string.Empty;

    /// <summary>Processing code, 8 chars from 4 words.</summary>
    public string ProcessingCode { get; set; } = string.Empty;

    /// <summary>LOT-specific data, 4 words.</summary>
    public int[] LotSpecificData { get; set; } = new int[4];

    /// <summary>Recipe number.</summary>
    public int RecipeNumber { get; set; }

    /// <summary>Glass type.</summary>
    public int GlassType { get; set; }

    /// <summary>Glass code.</summary>
    public int GlassCode { get; set; }

    /// <summary>Glass ID, 16 chars from 8 words.</summary>
    public string GlassId { get; set; } = string.Empty;

    /// <summary>Glass judge value. 'G'=71, 'N', 'S'.</summary>
    public int GlassJudge { get; set; }

    /// <summary>Glass-specific data, 4 words.</summary>
    public int[] GlassSpecificData { get; set; } = new int[4];

    /// <summary>Previous unit processing data, 8 words.</summary>
    public int[] PreviousUnitProcessing { get; set; } = new int[8];

    /// <summary>Glass processing status data, 8 words.</summary>
    public int[] GlassProcessingStatus { get; set; } = new int[8];

    /// <summary>Material ID, 30 chars from 15 words.</summary>
    public string MateriId { get; set; } = string.Empty;

    /// <summary>LCM ID (used in PCHK flow).</summary>
    public string LcmId { get; set; } = string.Empty;

    /// <summary>PCZT code.</summary>
    public int PcztCode { get; set; }
}

/// <summary>
/// ECS Alarm queue item.
/// <para>Delphi origin: TAlarmItem (CommPLC_ECS.pas line 183)</para>
/// </summary>
public readonly record struct AlarmItem(int AlarmType, int AlarmCode, int AlarmValue);

/// <summary>
/// ECS MES item value for queued MES operations.
/// <para>Delphi origin: TMESItemValue (CommPLC_ECS.pas line 191)</para>
/// </summary>
public class MesItemValue
{
    public int Channel { get; set; }
    public string SerialNo { get; set; } = string.Empty;
    public string CarrierId { get; set; } = string.Empty;
    public string ErrorCode { get; set; } = string.Empty;
    public string InspectionResult { get; set; } = string.Empty;
    public int BondingType { get; set; }
    public string PcbId { get; set; } = string.Empty;
    public DateTime TimeStart { get; set; }
    public DateTime TimeEnd { get; set; }
    public int TactTime { get; set; }
    public string SendData { get; set; } = string.Empty;
    public string LcmId { get; set; } = string.Empty;
    /// <summary>0 = OK, other = NG.</summary>
    public int Ack { get; set; }
}

/// <summary>
/// Callback delegate for MES completion notification.
/// <para>Delphi origin: TMESNotifyEvent (CommPLC_ECS.pas line 209)</para>
/// </summary>
public delegate void MesNotifyEvent(MesItemValue item);

/// <summary>
/// ECS MES queue item.
/// <para>Delphi origin: TMESItem (CommPLC_ECS.pas line 212)</para>
/// </summary>
public class MesItem
{
    public int Kind { get; set; }
    public MesNotifyEvent? NotifyEvent { get; set; }
    public MesItemValue Value { get; set; } = new();
}

// =========================================================================
// Constants
// =========================================================================

/// <summary>
/// CommPLC message mode/param constants.
/// <para>Delphi origin: COMMPLC_MODE_*, COMMPLC_PARAM_* (CommPLC_ECS.pas lines 19-108)</para>
/// </summary>
public static class CommPlcConst
{
    public const int MsgType = 200;

    // Modes
    public const int ModeNone = 2000;
    public const int ModeConnect = ModeNone + 1;
    public const int ModeHeartbeat = ModeNone + 2;
    public const int ModeChangeRobot = ModeNone + 3;
    public const int ModeChangeEcs = ModeNone + 4;
    public const int ModeEventRobot = ModeNone + 5;
    public const int ModeEventEcs = ModeNone + 6;
    public const int ModeLogRobot = ModeNone + 7;
    public const int ModeLogEcs = ModeNone + 8;
    public const int ModeLogin = ModeNone + 9;
    public const int ModeShowMes = ModeNone + 10;

    // Params
    public const int ParamNone = 0;
    public const int ParamLoadComplete = 1;
    public const int ParamGlassDataReport = 2;
    public const int ParamLoadGlassData = 3;
    public const int ParamLoadBusy = 4;
    public const int ParamUnloadComplete = 11;
    public const int ParamUnloadBusy = 13;
    public const int ParamInspectionStart = 100;
    public const int ParamResetCount = 101;
    public const int ParamLastProduct = 102;
    public const int ParamDoorOpened = 103;
    public const int ParamAabMode = 104;
    public const int ParamAddLog = 200;
    public const int ParamInterfaceError = 201;

    // Polling data sizes
    public const int RobotDataSize = 4;
    public const int EcsDataSize = 3;
    public const int CvDataSize = 1;
    public const int CommonDataSize = 1;

    // Unit state modes
    public const int UnitStateOnline = 0;
    public const int UnitStateAuto = 5;
    public const int UnitStateBcr = 6;
    public const int UnitStateRun = 8;
    public const int UnitStateIdle = 9;
    public const int UnitStateDown = 10;
    public const int UnitStateGlassProcess = 11;
    public const int UnitStateGlassExist = 12;
    public const int UnitStatePreviousTransferEnable = 13;

    // MES kinds
    public const int MesKindPchk = 0;
    public const int MesKindEicr = 1;
    public const int MesKindApdr = 2;
    public const int MesKindZset = 3;

    // Alarm types
    public const int AlarmLight = 0;
    public const int AlarmHeavy = 1;

    // Channel groups
    public const int Ch12 = 0;
    public const int Ch34 = 1;

    // Load flow steps
    public const int ModeLoad1 = 1;   // Glass Data Request
    public const int ModeLoad2 = 2;   // Glass Data Report
    public const int ModeLoad3 = 3;   // Load Request
    public const int ModeLoad4 = 4;   // Load Enable
    public const int ModeLoad5 = 5;   // Robot Busy
    public const int ModeLoad6 = 6;   // Load Complete
    public const int ModeLoad7 = 7;   // Load Complete Confirm
    public const int ModeLoad11 = 11; // Load EQP Normal Status
    public const int ModeLoad12 = 12; // Load ROBOT Normal Status

    // Unload flow steps
    public const int ModeUnload1 = 21;  // Glass Data Report
    public const int ModeUnload2 = 22;  // UnLoad Request
    public const int ModeUnload3 = 23;  // UnLoad Enable
    public const int ModeUnload4 = 24;  // Robot Busy
    public const int ModeUnload5 = 25;  // UnLoad Complete
    public const int ModeUnload6 = 26;  // UnLoad Complete Confirm
    public const int ModeUnload11 = 31; // UnLoad EQP Normal Status
    public const int ModeUnload12 = 32; // UnLoad ROBOT Normal Status

    // ECS protocol timeout
    public const int EcsTimeout = 3000;
}

// =========================================================================
// Main Interface
// =========================================================================

/// <summary>
/// Full PLC/ECS communication driver interface.
/// Extends <see cref="IPlcService"/> with all ECS protocol, Robot interlock,
/// PLC I/O, and glass data management methods.
/// <para>Delphi origin: TCommPLCThread public API (CommPLC_ECS.pas lines 332-576)</para>
/// </summary>
public interface IPlcEcsDriver : IPlcService, IDisposable
{
    // =====================================================================
    // Connection and Lifecycle
    // =====================================================================

    /// <summary>
    /// Whether PLC communication is open and active.
    /// <para>Delphi origin: property Connected: Boolean read m_bOpend</para>
    /// </summary>
    bool Connected { get; }

    /// <summary>
    /// Starts the background polling task.
    /// <para>Delphi origin: inherited Create(True) followed by .Start</para>
    /// </summary>
    void Start();

    /// <summary>
    /// Stops the background polling task and releases resources.
    /// <para>Delphi origin: TCommPLCThread.StopThread + Destroy</para>
    /// </summary>
    void Stop();

    /// <summary>
    /// Switches between simulator and real PLC mode at runtime.
    /// Must be called after <see cref="Stop()"/> and before <see cref="Start()"/>.
    /// <para>Delphi origin: InitialAll → FreeAndNil(g_CommPLC) + CreateClassData re-create</para>
    /// </summary>
    void ApplySimulationMode();

    // =====================================================================
    // Configuration
    // =====================================================================

    /// <summary>
    /// Polling interval in milliseconds.
    /// <para>Delphi origin: PollingInterval: Int64</para>
    /// </summary>
    long PollingInterval { get; set; }

    /// <summary>
    /// Connection timeout in milliseconds.
    /// <para>Delphi origin: ConnectionTimeout: Cardinal</para>
    /// </summary>
    uint ConnectionTimeout { get; set; }

    /// <summary>
    /// ECS protocol operation timeout in milliseconds.
    /// <para>Delphi origin: ECS_Timeout: Cardinal</para>
    /// </summary>
    uint EcsTimeout { get; set; }

    /// <summary>
    /// Whether a connection error has occurred.
    /// <para>Delphi origin: ConnectionError: Boolean</para>
    /// </summary>
    bool ConnectionError { get; }

    /// <summary>
    /// Whether to ignore PLC connection (for GIB scenarios).
    /// <para>Delphi origin: IgnoreConnect: Boolean</para>
    /// </summary>
    bool IgnoreConnect { get; set; }

    /// <summary>
    /// Whether Inline GIB mode is active.
    /// <para>Delphi origin: InlineGIB: Boolean</para>
    /// </summary>
    bool InlineGib { get; set; }

    /// <summary>
    /// Whether simulator mode is used instead of real PLC.
    /// <para>Delphi origin: UseSimulator: Boolean</para>
    /// </summary>
    bool UseSimulator { get; }

    /// <summary>
    /// EQP ID number (equipment identifier, 33 range).
    /// <para>Delphi origin: EQP_ID: Integer</para>
    /// </summary>
    int EqpId { get; }

    /// <summary>
    /// Whether ECS login has completed.
    /// <para>Delphi origin: Logined: Boolean</para>
    /// </summary>
    bool IsLoggedIn { get; set; }

    /// <summary>
    /// Last heavy alarm code reported.
    /// <para>Delphi origin: m_nLastHeavyCode: Integer</para>
    /// </summary>
    int LastHeavyCode { get; }

    /// <summary>
    /// Last light alarm code reported.
    /// <para>Delphi origin: m_nLastLightCode: Integer</para>
    /// </summary>
    int LastLightCode { get; }

    /// <summary>
    /// Sets EQP ID and propagates to simulator if active.
    /// <para>Delphi origin: procedure SetEQPID(nEQP_ID: Integer)</para>
    /// </summary>
    void SetEqpId(int eqpId);

    /// <summary>
    /// Configures PLC start addresses for all data blocks.
    /// <para>Delphi origin: procedure SetStartAddress(...) (line 5628)</para>
    /// </summary>
    void SetStartAddress(long startAddrEqp, long startAddrEcs, long startAddrRobot, long startAddrRobot2,
        long startAddrEqpW, long startAddrEcsW, long startAddrRobotW, long startAddrRobotW2, long startAddrRobotDoor);

    /// <summary>
    /// Log file base path.
    /// <para>Delphi origin: property LogPath: String read m_sLogPath write Set_LogPath</para>
    /// </summary>
    string LogPath { get; set; }

    // =====================================================================
    // Polling Data (read-only snapshots)
    // =====================================================================

    /// <summary>Robot interlock polling data (current). Delphi: PollingData</summary>
    int[] PollingData { get; }

    /// <summary>Robot interlock polling data (previous). Delphi: PollingDataPre</summary>
    int[] PollingDataPre { get; }

    /// <summary>ECS polling data (current). Delphi: PollingECS</summary>
    int[] PollingEcs { get; }

    /// <summary>ECS polling data (previous). Delphi: PollingECSPre</summary>
    int[] PollingEcsPre { get; }

    /// <summary>EQP polling data (current). Delphi: PollingEQP</summary>
    int[] PollingEqp { get; }

    /// <summary>EQP polling data (previous). Delphi: PollingEQPPre</summary>
    int[] PollingEqpPre { get; }

    /// <summary>Conveyor polling data (current). Delphi: PollingCV</summary>
    int[] PollingCv { get; }

    /// <summary>Conveyor polling data (previous). Delphi: PollingCVPre</summary>
    int[] PollingCvPre { get; }

    /// <summary>Door opened polling state. Delphi: PollingDoorOpened</summary>
    long PollingDoorOpened { get; set; }

    /// <summary>AAB mode polling value. Delphi: PollingAABMode</summary>
    int PollingAabMode { get; set; }

    // =====================================================================
    // Glass Data
    // =====================================================================

    /// <summary>
    /// Per-channel glass data (indices 0..8). Delphi: GlassData[0..8]
    /// </summary>
    EcsGlassData[] GlassData { get; }

    /// <summary>
    /// Per-channel ECS glass data. Delphi: ECS_GlassData[0..8]
    /// </summary>
    EcsGlassData[] EcsGlassDataArray { get; }

    /// <summary>
    /// Per-channel ECS LCM IDs. Delphi: ECS_LCM_ID[0..7]
    /// </summary>
    string[] EcsLcmId { get; }

    /// <summary>
    /// Per-channel unload-only flags. Delphi: UnloadOnly[0..3]
    /// </summary>
    bool[] UnloadOnly { get; }

    /// <summary>
    /// Per-channel load request state. Delphi: RequestState_Load[0..3]
    /// </summary>
    int[] RequestStateLoad { get; }

    /// <summary>
    /// Per-channel unload request state. Delphi: RequestState_Unload[0..3]
    /// </summary>
    int[] RequestStateUnload { get; }

    /// <summary>
    /// Per-channel robot loading status. Delphi: RobotLoadingStatus[0..3]
    /// </summary>
    bool[] RobotLoadingStatus { get; }

    /// <summary>
    /// Saves all glass data to file.
    /// <para>Delphi origin: procedure SaveGlassData(sFileName)</para>
    /// </summary>
    void SaveGlassData(string fileName);

    /// <summary>
    /// Saves single-channel glass data to file.
    /// <para>Delphi origin: procedure SaveGlassData_CH(nCH, sFileName)</para>
    /// </summary>
    void SaveGlassDataChannel(int channel, string fileName);

    /// <summary>
    /// Loads all glass data from file.
    /// <para>Delphi origin: procedure LoadGlassData(sFileName)</para>
    /// </summary>
    void LoadGlassData(string fileName);

    /// <summary>
    /// Loads single-channel glass data from file.
    /// <para>Delphi origin: procedure LoadGlassData_CH(nCH, sFileName)</para>
    /// </summary>
    void LoadGlassDataChannel(int channel, string fileName);

    /// <summary>
    /// Returns human-readable string of glass data fields.
    /// <para>Delphi origin: function GetGlassDataString(AGlassData): String</para>
    /// </summary>
    string GetGlassDataString(EcsGlassData glassData);

    // =====================================================================
    // PLC Device I/O
    // =====================================================================

    /// <summary>
    /// Reads a single PLC device value.
    /// <para>Delphi origin: function ReadDevice(szDevice, lplData, bSaveLog): integer</para>
    /// </summary>
    int ReadDevice(string device, out int value, bool saveLog = true);

    /// <summary>
    /// Writes a single PLC device value.
    /// <para>Delphi origin: function WriteDevice(szDevice, nData, bSaveLog): integer</para>
    /// </summary>
    int WriteDevice(string device, int value, bool saveLog = true);

    /// <summary>
    /// Reads a single bit from a PLC device.
    /// <para>Delphi origin: function ReadDeviceBit(szDevice, nBitLoc, lplData): integer</para>
    /// </summary>
    int ReadDeviceBit(string device, int bitLoc, out int value);

    /// <summary>
    /// Writes a single bit to a PLC device.
    /// <para>Delphi origin: function WriteDeviceBit(szDevice, nBitLoc, nValue, bSaveLog): integer</para>
    /// </summary>
    int WriteDeviceBit(string device, int bitLoc, int value, bool saveLog = true);

    /// <summary>
    /// Reads a block of PLC device values.
    /// <para>Delphi origin: function ReadDeviceBlock(szDevice, lSize, lplData, nReturn, bSaveLog): integer</para>
    /// </summary>
    int ReadDeviceBlock(string device, int size, int[] data, out int returnCode, bool saveLog = true);

    /// <summary>
    /// Writes a block of PLC device values.
    /// <para>Delphi origin: function WriteDeviceBlock(szDevice, lSize, lplData): integer</para>
    /// </summary>
    int WriteDeviceBlock(string device, int size, int[] data);

    /// <summary>
    /// Reads a string from PLC word devices.
    /// <para>Delphi origin: function ReadString(szDevice, nAddress, nLen): String</para>
    /// </summary>
    string ReadString(string device, int address, int length);

    /// <summary>
    /// Writes a string to PLC word devices.
    /// <para>Delphi origin: function WriteString(szDevice, sValue): Integer</para>
    /// </summary>
    int WriteString(string device, string value);

    /// <summary>
    /// Reads PLC buffer memory.
    /// <para>Delphi origin: function ReadBuffer(lStartIO, lAddress, lSize, lpsData): Integer</para>
    /// </summary>
    int ReadBuffer(int startIo, int address, int size, short[] data);

    /// <summary>
    /// Writes PLC buffer memory.
    /// <para>Delphi origin: function WriteBuffer(lStartIO, lAddress, lSize, lpsData): Integer</para>
    /// </summary>
    int WriteBuffer(int startIo, int address, int size, short[] data);

    /// <summary>
    /// Writes glass data block to PLC device.
    /// <para>Delphi origin: function WriteGlassData(szDevice, AGlassData): Integer</para>
    /// </summary>
    int WriteGlassData(string device, EcsGlassData glassData);

    /// <summary>
    /// Reads tact time for a channel.
    /// <para>Delphi origin: function ReadTactTime(nChannel): Integer</para>
    /// </summary>
    int ReadTactTime(int channel);

    /// <summary>
    /// Reads PLC clock data.
    /// <para>Delphi origin: function ReadClockData(...): Integer</para>
    /// </summary>
    int ReadClockData(out short year, out short month, out short day, out short dayOfWeek,
        out short hour, out short minute, out short second);

    // =====================================================================
    // ECS Protocol Functions
    // =====================================================================

    /// <summary>
    /// User ID check (ECS UCHK).
    /// <para>Delphi origin: function ECS_UCHK(sUserID): Integer (line 1659)</para>
    /// </summary>
    int EcsUchk(string userId);

    /// <summary>
    /// Panel check (ECS PCHK / BCR reading data report).
    /// <para>Delphi origin: function ECS_PCHK(nCh, sSerial): Integer (line 1710)</para>
    /// </summary>
    int EcsPchk(int channel, string serial);

    /// <summary>
    /// Inspection data report and confirm (ECS EICR).
    /// <para>Delphi origin: function ECS_EICR(nCh, sLCM_ID, sErrorCode, sInpResult): Integer (line 1843)</para>
    /// </summary>
    int EcsEicr(int channel, string lcmId, string errorCode, string inspResult);

    /// <summary>
    /// Glass APD report (ECS APDR).
    /// <para>Delphi origin: function ECS_APDR(nCh, sInspectionResult): Integer (line 1944)</para>
    /// </summary>
    int EcsApdr(int channel, string inspectionResult);

    /// <summary>
    /// Bonding report (ECS ZSET).
    /// <para>Delphi origin: function ECS_ZSET(nCh, nBondingType, sZigID, sPID, sPcbID, lplData): Integer (line 1996)</para>
    /// </summary>
    int EcsZset(int channel, int bondingType, string zigId, string pid, string pcbId, out int resultData);

    /// <summary>
    /// Defect code report (ECS).
    /// <para>Delphi origin: function ECS_DEFECT_CODE(sPID, sGLSCode, sGLSJudge, sCode, sComment, sValue): Integer</para>
    /// </summary>
    int EcsDefectCode(string pid, string glsCode, string glsJudge, string code, string comment, out string value);

    /// <summary>
    /// Adds an alarm to the queue and immediately reports it.
    /// <para>Delphi origin: function ECS_Alarm_Add(nAlarmType, nAlarmCode, nOnOff): Integer (line 1102)</para>
    /// </summary>
    int EcsAlarmAdd(int alarmType, int alarmCode, int onOff);

    /// <summary>
    /// Reports an alarm directly to PLC.
    /// <para>Delphi origin: function ECS_Alarm_Report(nAlarmType, nAlarmCode, nOnOff): Integer (line 1131)</para>
    /// </summary>
    int EcsAlarmReport(int alarmType, int alarmCode, int onOff);

    /// <summary>
    /// Glass data report to PLC.
    /// <para>Delphi origin: function ECS_GlassData_Report(nCH, AGlassData): Integer (line 1177)</para>
    /// </summary>
    int EcsGlassDataReport(int channel, EcsGlassData glassData);

    /// <summary>
    /// Reports glass position to PLC.
    /// <para>Delphi origin: function ECS_Glass_Position(nCh, bExist): Integer (line 1219)</para>
    /// </summary>
    int EcsGlassPosition(int channel, bool exists);

    /// <summary>
    /// Reports all glass positions to PLC.
    /// <para>Delphi origin: function ECS_Glass_PositionAll(naExists): Integer (line 1279)</para>
    /// </summary>
    int EcsGlassPositionAll(int[] exists);

    /// <summary>
    /// Reports glass processing state.
    /// <para>Delphi origin: function ECS_Glass_Processing(bProcessing): Integer (line 1311)</para>
    /// </summary>
    int EcsGlassProcessing(bool processing);

    /// <summary>
    /// Reports glass exist count.
    /// <para>Delphi origin: function ECS_Glass_Exist(nExistCount, nUseCount): Integer</para>
    /// </summary>
    int EcsGlassExist(int existCount, int useCount);

    /// <summary>
    /// Equipment unit status report.
    /// <para>Delphi origin: function ECS_Unit_Status(nMode, nValue): Integer (line 1551)</para>
    /// </summary>
    int EcsUnitStatus(int mode, int value);

    /// <summary>
    /// Equipment status mode report.
    /// <para>Delphi origin: function ECS_Status_Mode(nMode, nValue): Integer</para>
    /// </summary>
    int EcsStatusMode(int mode, int value);

    /// <summary>
    /// Stage position report.
    /// <para>Delphi origin: function ECS_Stage_Position(nStage): Integer</para>
    /// </summary>
    int EcsStagePosition(int stage);

    /// <summary>
    /// Accessory unit management.
    /// <para>Delphi origin: function ECS_Accessory_Unit_Status(nStage, nValue, nAlarmCode): Integer (line 1084)</para>
    /// </summary>
    int EcsAccessoryUnitStatus(int stage, int value, int alarmCode);

    /// <summary>
    /// Lost glass data request.
    /// <para>Delphi origin: function ECS_Lost_Glass_Request(sGlassID, nGlassCode, nRequestOption, nCh): Integer (line 1349)</para>
    /// </summary>
    int EcsLostGlassRequest(string glassId, int glassCode, int requestOption, int channel = 0);

    /// <summary>
    /// Glass data change report.
    /// <para>Delphi origin: function ECS_Change_Glass_Report(AGlassData): Integer (line 1480)</para>
    /// </summary>
    int EcsChangeGlassReport(EcsGlassData glassData);

    /// <summary>
    /// Scrap glass data report.
    /// <para>Delphi origin: function ECS_Scrap_Glass_Report(AGlassData, sScrapCode): Integer</para>
    /// </summary>
    int EcsScrapGlassReport(EcsGlassData glassData, string scrapCode);

    /// <summary>
    /// Take out report.
    /// <para>Delphi origin: function ECS_TakeOutReport(nCH, sPanelID): Integer</para>
    /// </summary>
    int EcsTakeOutReport(int channel, string panelId);

    /// <summary>
    /// Normal operation report.
    /// <para>Delphi origin: function ECS_NormalOperation(sGlassID): Integer (line 1541)</para>
    /// </summary>
    int EcsNormalOperation(string glassId);

    /// <summary>
    /// Ionizer status report.
    /// <para>Delphi origin: function ECS_IonizerStatus(nIndex, nValue): Integer (line 1325)</para>
    /// </summary>
    int EcsIonizerStatus(int index, int value);

    /// <summary>
    /// Model change confirm request.
    /// <para>Delphi origin: function ECS_ModelChange_Request(nIndex): Integer (line 1506)</para>
    /// </summary>
    int EcsModelChangeRequest(int index);

    /// <summary>
    /// Link test with ECS.
    /// <para>Delphi origin: function ECS_Link_Test: Integer (line 1334)</para>
    /// </summary>
    int EcsLinkTest();

    /// <summary>
    /// ECS restart test.
    /// <para>Delphi origin: function ECS_ECSRestart_Test: Integer (line 1817)</para>
    /// </summary>
    int EcsRestartTest();

    /// <summary>
    /// Write tact time to PLC.
    /// <para>Delphi origin: function ECS_WriteTactTime(nTactTimeMS): Integer (line 1647)</para>
    /// </summary>
    int EcsWriteTactTime(int tactTimeMs);

    /// <summary>
    /// Adds a MES item to the queue.
    /// <para>Delphi origin: function ECS_MES_AddItem(item): Integer (line 1498)</para>
    /// </summary>
    int EcsMesAddItem(MesItem item);

    // =====================================================================
    // Robot Interlock Functions
    // =====================================================================

    /// <summary>
    /// Sends robot load request for a channel.
    /// <para>Delphi origin: function ROBOT_Load_Request(nCh): Integer</para>
    /// </summary>
    int RobotLoadRequest(int channel);

    /// <summary>
    /// Sends robot unload request for a channel.
    /// <para>Delphi origin: function ROBOT_Unload_Request(nCh): Integer</para>
    /// </summary>
    int RobotUnloadRequest(int channel);

    /// <summary>
    /// Sends robot exchange request for a channel group.
    /// <para>Delphi origin: function ROBOT_Exchange_Request(nCh): Integer</para>
    /// </summary>
    int RobotExchangeRequest(int channel);

    /// <summary>
    /// Sends ready-to-start request.
    /// <para>Delphi origin: function ROBOT_ReadyToStart_Request(nCh, nReady): Integer</para>
    /// </summary>
    int RobotReadyToStartRequest(int channel, int ready);

    /// <summary>
    /// Copies glass data for 2-channel robot operation.
    /// <para>Delphi origin: function ROBOT_Copy_GlassData: Integer</para>
    /// </summary>
    int RobotCopyGlassData();

    // =====================================================================
    // EQP Control Functions
    // =====================================================================

    /// <summary>
    /// Checks if door is open (warning level).
    /// <para>Delphi origin: function EQP_Door_Open_Warning: Boolean</para>
    /// </summary>
    bool EqpDoorOpenWarning();

    /// <summary>
    /// Reports door open info to PLC.
    /// <para>Delphi origin: procedure EQP_Door_Open_Info(nValue)</para>
    /// </summary>
    void EqpDoorOpenInfo(int value);

    /// <summary>
    /// Clears ECS area signals.
    /// <para>Delphi origin: function EQP_Clear_ECS_Area: Integer (line 2038)</para>
    /// </summary>
    int EqpClearEcsArea();

    /// <summary>
    /// Sets unload-before-channel flag.
    /// <para>Delphi origin: function EQP_UnloadBeforeCh(nJig, nCh, nOnOff): integer</para>
    /// </summary>
    int EqpUnloadBeforeChannel(int jig, int channel, int onOff);

    /// <summary>
    /// Sets skip-channel flag.
    /// <para>Delphi origin: function EQP_SkipCh(nJig, nCh, nSkip): Integer</para>
    /// </summary>
    int EqpSkipChannel(int jig, int channel, int skip);

    /// <summary>
    /// Sets all channels normal status on/off.
    /// <para>Delphi origin: function ITC_AllChNormalStatusOnOff(nOnOff): integer (line 5270)</para>
    /// </summary>
    int ItcAllChNormalStatusOnOff(int onOff);

    // =====================================================================
    // Bit Operations and Status Queries
    // =====================================================================

    /// <summary>
    /// Tests if a bit is on in given data.
    /// <para>Delphi origin: function IsBitOn(var nData, nLoc): Boolean</para>
    /// </summary>
    bool IsBitOn(int data, int bitLoc);

    /// <summary>
    /// Tests if a bit is on in polling data by division (0=EQP, 1=Robot, 2=ECS, 3=CV).
    /// <para>Delphi origin: function IsBitOn(nDivision, nIndex, nBitLoc): Boolean</para>
    /// </summary>
    bool IsBitOnByDivision(int division, int index, int bitLoc);

    /// <summary>
    /// Tests if a bit is on in EQP polling data.
    /// <para>Delphi origin: function IsBitOn_EQP(nIndex): Boolean (line 5099)</para>
    /// </summary>
    bool IsBitOnEqp(int index);

    /// <summary>
    /// Tests if a bit is on in ECS polling data.
    /// <para>Delphi origin: function IsBitOn_ECS(nIndex): Boolean (line 5090)</para>
    /// </summary>
    bool IsBitOnEcs(int index);

    /// <summary>
    /// Checks if robot is busy (load or unload) for a channel.
    /// <para>Delphi origin: function IsBusy_Robot(nCH): Boolean (line 5117)</para>
    /// </summary>
    bool IsBusyRobotEach(int channel);

    /// <summary>
    /// Checks if robot request is active.
    /// <para>Delphi origin: function IsRequest_Robot: Boolean (line 5182)</para>
    /// </summary>
    bool IsRequestRobot();

    /// <summary>
    /// Checks if glass data is available from robot.
    /// <para>Delphi origin: function IsGlassData_Robot(nCH): Boolean (line 5159)</para>
    /// </summary>
    bool IsGlassDataRobot(int channel);

    /// <summary>
    /// Checks if load request is active for channel.
    /// <para>Delphi origin: function IsLoadRequest_Robot(nCH): Boolean (line 5206)</para>
    /// </summary>
    bool IsLoadRequestRobot(int channel);

    /// <summary>
    /// Checks if unload request is active for channel.
    /// <para>Delphi origin: function IsUnloadRequest_Robot(nCH): Boolean (line 5238)</para>
    /// </summary>
    bool IsUnloadRequestRobot(int channel);

    /// <summary>
    /// Gets a bit value from an integer.
    /// <para>Delphi origin: function Get_Bit(nData, nLoc): Integer (line 5068)</para>
    /// </summary>
    int GetBit(int data, int bitLoc);

    /// <summary>
    /// Sets a bit value in an integer, returns modified value.
    /// <para>Delphi origin: function Set_Bit(nData, nLoc, Value): Integer (line 5657)</para>
    /// </summary>
    int SetBit(ref int data, int bitLoc, int value);

    // =====================================================================
    // Glass Data Processing Helpers
    // =====================================================================

    /// <summary>
    /// Sets previous unit processing data.
    /// <para>Delphi origin: function SetGlassData_Previous_Unit_Processing(GlassData, nValue): Integer</para>
    /// </summary>
    int SetGlassDataPreviousUnitProcessing(EcsGlassData glassData, int value);

    /// <summary>
    /// Sets previous unit processing data for GIB mode.
    /// <para>Delphi origin: function SetGlassData_Previous_Unit_Processing_GIB(GlassData, nEQP_ID, nCH, nABBCount): Integer</para>
    /// </summary>
    int SetGlassDataPreviousUnitProcessingGib(EcsGlassData glassData, int eqpId, int channel, int abbCount);

    /// <summary>
    /// Sets glass processing status.
    /// <para>Delphi origin: function SetGlassData_Processing_Status(GlassData, nSeq, nBitCount): Integer</para>
    /// </summary>
    int SetGlassDataProcessingStatus(EcsGlassData glassData, int seq, int bitCount = 4);

    /// <summary>
    /// Sets glass processing status for GIB mode.
    /// <para>Delphi origin: function SetGlassData_Processing_Status_GIB(GlassData, nEQP_ID, nCH, nABBCount): Integer</para>
    /// </summary>
    int SetGlassDataProcessingStatusGib(EcsGlassData glassData, int eqpId, int channel, int abbCount);

    /// <summary>
    /// Sets contact NG flag in glass data.
    /// <para>Delphi origin: function SetGlassData_ContactNG(GlassData, nValue): Integer</para>
    /// </summary>
    int SetGlassDataContactNg(EcsGlassData glassData, int value);

    /// <summary>
    /// Checks and resets reverse logistics flag.
    /// <para>Delphi origin: function SetGlassData_CheckRLogistics(nCH, GlassData, nValue): Integer</para>
    /// </summary>
    int SetGlassDataCheckReverseLogistics(int channel, EcsGlassData glassData, int value);

    /// <summary>
    /// Sets glass judge code.
    /// <para>Delphi origin: function SetGlassData_JudgCode(GlassData, nValue): Integer</para>
    /// </summary>
    int SetGlassDataJudgeCode(EcsGlassData glassData, int value);

    /// <summary>
    /// Gets glass processing status with sequence output.
    /// <para>Delphi origin: function GetGlassData_Processing_Status(GlassData, nEQP_ID, nSeq, nBitCount): Integer</para>
    /// </summary>
    int GetGlassDataProcessingStatus(EcsGlassData glassData, int eqpId, ref int seq, int bitCount = 4);

    /// <summary>
    /// Gets previous unit processing with sequence output.
    /// <para>Delphi origin: function GetGlassData_PreviousUnitProcessing(GlassData, nEQP_ID, nSeq, nBitCount): Integer</para>
    /// </summary>
    int GetGlassDataPreviousUnitProcessing(EcsGlassData glassData, int eqpId, ref int seq, int bitCount = 4);

    // =====================================================================
    // Simulator Control (only active when UseSimulator=true)
    // =====================================================================

    /// <summary>
    /// Auto Start mode: triggers Inspection Start after Load Complete cycle.
    /// Only effective in simulator mode.
    /// </summary>
    bool SimAutoStart { get; set; }

    /// <summary>
    /// Injects a bit value directly into simulator memory (for UI event injection).
    /// Only effective in simulator mode.
    /// </summary>
    void SimInjectBit(string device, int value);
}
