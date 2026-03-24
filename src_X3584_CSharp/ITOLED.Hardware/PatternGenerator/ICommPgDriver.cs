// =============================================================================
// ICommPgDriver.cs
// Converted from Delphi: src_X3584\CommPG.pas (TCommPG public interface)
// Pattern generator driver interface for ITOLED inspection system.
// Supports both AF9 (USB) and DP860 (UDP/IP) pattern generators.
// Namespace: Dongaeltek.ITOLED.Hardware.PatternGenerator
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Hardware.PatternGenerator;

// =============================================================================
// Supporting Types
// =============================================================================

/// <summary>
/// Current pattern display information.
/// <para>Delphi: <c>TCurPatDispInfo</c> record</para>
/// </summary>
public class CurrentPatternDisplayInfo
{
    /// <summary>Power state. Delphi: bPowerOn</summary>
    public bool PowerOn { get; set; }

    /// <summary>Pattern display active. Delphi: bPatternOn</summary>
    public bool PatternOn { get; set; }

    /// <summary>Current pattern number. Delphi: nCurPatNum</summary>
    public int CurrentPatternNumber { get; set; }

    /// <summary>Current AllPat index. Delphi: nCurAllPatIdx</summary>
    public int CurrentAllPatIndex { get; set; }

    /// <summary>Simple pattern flag. Delphi: bSimplePat</summary>
    public bool IsSimplePattern { get; set; } = true;

    /// <summary>Gray change offset (-255..255). Delphi: nGrayOffset (FEATURE_GRAY_CHANGE)</summary>
    public int GrayOffset { get; set; }

    /// <summary>Delphi: bGrayChangeR</summary>
    public bool GrayChangeR { get; set; }

    /// <summary>Delphi: bGrayChangeG</summary>
    public bool GrayChangeG { get; set; }

    /// <summary>Delphi: bGrayChangeB</summary>
    public bool GrayChangeB { get; set; }

    /// <summary>Current PWM duty (0..100). Delphi: nCurPwmDuty (FEATURE_DIMMING_STEP)</summary>
    public int CurrentPwmDuty { get; set; } = 100;

    /// <summary>Current dimming step (1..4). Delphi: nCurDimmingStep (FEATURE_DIMMING_STEP)</summary>
    public int CurrentDimmingStep { get; set; } = 1;
}

/// <summary>
/// Public interface for the PG driver (TCommPG).
/// Covers both AF9 (USB via IAf9FpgaDriver) and DP860 (UDP) pattern generator types.
/// <para>Delphi origin: <c>TCommPG</c> class — public section (CommPG.pas)</para>
/// </summary>
public interface ICommPgDriver : IDisposable
{
    // =========================================================================
    // Properties — Common
    // =========================================================================

    /// <summary>PG index (0-based). Delphi: m_nPg</summary>
    int PgIndex { get; }

    /// <summary>Inspection channel index (0-based). Delphi: m_nCh</summary>
    int ChannelIndex { get; }

    /// <summary>Model type name (e.g. "X3584"). Delphi: m_ModelTypeName</summary>
    string ModelTypeName { get; }

    /// <summary>PG type (AF9 or DP860). Delphi: PG_TYPE</summary>
    int PgType { get; }

    /// <summary>PG connection status. Delphi: StatusPg : enumPgStatus</summary>
    PgStatus Status { get; }

    /// <summary>Whether PG is ready. Delphi: IsPgReady</summary>
    bool IsPgReady { get; }

    /// <summary>Power state. Delphi: m_bPowerOn</summary>
    bool IsPowerOn { get; set; }

    /// <summary>Whether flash access is in progress. Delphi: FIsOnFlashAccess</summary>
    bool IsFlashAccessActive { get; }

    /// <summary>PG version info. Delphi: m_PgVer : TPgVer</summary>
    PgVersion Version { get; }

    /// <summary>Current power measurement data. Delphi: m_PwrData : TPwrData</summary>
    PwrData PowerData { get; }

    /// <summary>Raw power measurement data. Delphi: m_RxPwrData : TRxPwrData</summary>
    RxPwrData RawPowerData { get; }

    /// <summary>Current pattern display info. Delphi: m_CurPatDispInfo</summary>
    CurrentPatternDisplayInfo CurrentPatternInfo { get; }

    /// <summary>PG TX/RX data (no-ack channel). Delphi: FTxRxDEF</summary>
    PgTxRxData TxRxDefault { get; }

    /// <summary>PG TX/RX data (cmd/ack channel). Delphi: FTxRxPG</summary>
    PgTxRxData TxRxPg { get; }

    /// <summary>TCON read/write counters. Delphi: TconRWCnt</summary>
    TconRwCount TconRwCount { get; }

    /// <summary>Maintenance mode flag. Delphi: FIsMainter</summary>
    bool IsMainter { get; set; }

    /// <summary>Whether cyclic timer is enabled. Delphi: m_bCyclicTimer</summary>
    bool IsCyclicTimerEnabled { get; }

    /// <summary>HWCID array (5 entries). Delphi: m_HWCID</summary>
    string[] HwcId { get; }

    /// <summary>Reprogramming OK/NG flag. Delphi: bIsReProgramming</summary>
    bool IsReProgramming { get; set; }

    /// <summary>IRA check flag. Delphi: m_bChkIRA</summary>
    bool CheckIra { get; set; }

    /// <summary>Shutdown fault check flag. Delphi: m_bChkShutdown_Fault</summary>
    bool CheckShutdownFault { get; set; }

    // =========================================================================
    // Properties — DP860-specific
    // =========================================================================

    /// <summary>PG IP address (DP860). Delphi: PG_IPADDR</summary>
    string PgIpAddress { get; }

    /// <summary>PG IP port (DP860). Delphi: PG_IPPORT</summary>
    int PgIpPort { get; }

    // =========================================================================
    // Init
    // =========================================================================

    /// <summary>Init PG TX/RX data. Delphi: InitPgTxRxData</summary>
    void InitPgTxRxData();

    /// <summary>Init PG version info. Delphi: InitPgVer</summary>
    void InitPgVersion();

    /// <summary>Init power measurement data. Delphi: InitPgPwrData</summary>
    void InitPgPowerData();

    /// <summary>Init pattern data. Delphi: InitPgPatternData</summary>
    void InitPgPatternData();

    /// <summary>Init flash read state. Delphi: InitFlashRead (FEATURE_FLASH_ACCESS)</summary>
    void InitFlashRead();

    /// <summary>Flash 작업 완료 후 FTP 세션 해제. DLL flow 종료 시 호출.</summary>
    void ReleaseFlashFtpSession();

    // =========================================================================
    // Timer Control
    // =========================================================================

    /// <summary>
    /// Enable/disable cyclic timer (connection check + power measure).
    /// Delphi: SetCyclicTimer
    /// </summary>
    void SetCyclicTimer(bool enable, int disableSec = 0);

    /// <summary>
    /// Enable/disable power measure timer.
    /// Delphi: SetPwrMeasureTimer
    /// </summary>
    void SetPowerMeasureTimer(bool enable, int intervalMs = 0);

    // =========================================================================
    // Maintenance Events
    // =========================================================================

    /// <summary>Maintenance TX event (DP860). Delphi: OnTxMaintEventPG</summary>
    event Action<int, string, string, string>? TxMaintEventPg;

    /// <summary>Maintenance RX event (DP860). Delphi: OnRxMaintEventPG</summary>
    event Action<int, string, string, string>? RxMaintEventPg;

    /// <summary>Maintenance TX event (AF9). Delphi: OnTxMaintEventAF9</summary>
    event Action<int, string>? TxMaintEventAf9;

    /// <summary>Maintenance RX event (AF9). Delphi: OnRxMaintEventAF9</summary>
    event Action<int, string>? RxMaintEventAf9;

    // =========================================================================
    // FLOW-SPECIFIC: Power On/Off
    // =========================================================================

    /// <summary>
    /// Power on with mode. Delphi: SendPowerOn
    /// </summary>
    uint SendPowerOn(int mode, bool powerReset = false, int waitMs = 10000, int retry = 0);

    /// <summary>
    /// Power BIST on. Delphi: SendPowerBistOn
    /// </summary>
    uint SendPowerBistOn(int mode, bool powerReset = false, int waitMs = 10000, int retry = 0);

    /// <summary>
    /// Power VSYS on. Delphi: SendPowerVsysOn
    /// </summary>
    uint SendPowerVsysOn(int mode, bool powerReset = false, int waitMs = 10000, int retry = 0);

    // =========================================================================
    // FLOW-SPECIFIC: Power Measure
    // =========================================================================

    /// <summary>
    /// Send power measurement request. Delphi: SendPowerMeasure
    /// </summary>
    uint SendPowerMeasure(bool cyclicMeasure = false);

    // =========================================================================
    // FLOW-SPECIFIC: Pattern Display
    // =========================================================================

    /// <summary>Display RGB pattern. Delphi: SendDisplayPatRGB</summary>
    uint SendDisplayPatRgb(int r, int g, int b, int waitMs = 3000, int retry = 0);

    /// <summary>Display BIST RGB pattern. Delphi: SendDisplayPatBistRGB</summary>
    uint SendDisplayPatBistRgb(int r, int g, int b, int waitMs = 3000, int retry = 0);

    /// <summary>Display BIST RGB 9-bit pattern. Delphi: SendDisplayPatBistRGB_9Bit</summary>
    uint SendDisplayPatBistRgb9Bit(int r, int g, int b, int waitMs = 3000, int retry = 0);

    /// <summary>Display pattern by number. Delphi: SendDisplayPatNum</summary>
    uint SendDisplayPatNum(int patNum, int waitMs = 2000, int retry = 0);

    /// <summary>Display PWM pattern. Delphi: SendDisplayPatPwmNum</summary>
    uint SendDisplayPatPwmNum(int patNum, int waitMs = 3000, int retry = 0);

    /// <summary>Display next pattern. Delphi: SendDisplayPatNext</summary>
    uint SendDisplayPatNext(int waitMs = 3000, int retry = 0);

    // =========================================================================
    // FLOW-SPECIFIC: Gray Change / Dimming
    // =========================================================================

    /// <summary>Gray offset change. Delphi: SendGrayChange (FEATURE_GRAY_CHANGE)</summary>
    uint SendGrayChange(int grayOffset, int waitMs = 3000, int retry = 0);

    /// <summary>Set dimming (DBV). Delphi: SendDimming</summary>
    uint SendDimming(int dimming, int waitMs = 3000, int retry = 0);

    /// <summary>Set dimming BIST (DBV). Delphi: SendDimmingBist</summary>
    uint SendDimmingBist(int dimming, int waitMs = 3000, int retry = 0);

    /// <summary>POCB on/off. Delphi: SendPocbOnOff (FEATURE_POCB_ONOFF)</summary>
    uint SendPocbOnOff(bool on, int waitMs = 3000, int retry = 0);

    // =========================================================================
    // FLOW-SPECIFIC: I2C Read/Write
    // =========================================================================

    /// <summary>
    /// I2C read. Delphi: SendI2CRead
    /// </summary>
    uint SendI2CRead(int devAddr, int regAddr, int dataCnt, byte[] readData,
        int waitMs = 2000, int retry = 0, int debugLog = 0);

    /// <summary>
    /// I2C TEMP read. Delphi: SendTEMPRead
    /// </summary>
    uint SendTempRead(int devAddr, int regAddr, int dataCnt, byte[] readData,
        int waitMs = 2000, int retry = 0, int debugLog = 0);

    /// <summary>
    /// I2C write. Delphi: SendI2CWrite
    /// </summary>
    uint SendI2CWrite(int devAddr, int regAddr, int dataCnt, byte[] writeData,
        int waitMs = 2000, int retry = 0, int debugLog = 0);

    /// <summary>
    /// I2C multi-write. Delphi: SendI2CMultiWrite
    /// </summary>
    uint SendI2CMultiWrite(int devAddr, int dataCnt, int[] regAddrs, byte[] writeData,
        int waitMs = 2000, int retry = 0);

    /// <summary>
    /// I2C sequential write. Delphi: SendI2CSeqWrite
    /// </summary>
    uint SendI2CSeqWrite(int mode, int seqIdx, int dataCnt, int[] regAddrs, byte[] writeData,
        int waitMs = 2000, int retry = 0);

    /// <summary>
    /// Re-programming write. Delphi: SendReProgramming
    /// </summary>
    uint SendReProgramming(int devAddr, int regAddr, int dataCnt, byte[] writeData,
        int waitMs = 3000, int retry = 0);

    // =========================================================================
    // FLOW-SPECIFIC: Flash (FEATURE_FLASH_ACCESS)
    // =========================================================================

    /// <summary>
    /// Flash read. Delphi: SendFlashRead
    /// </summary>
    uint SendFlashRead(uint addr, uint size, byte[] data,
        int waitMs = 5000, int retry = 0, bool clearAfterGet = false, bool readMode = false);

    /// <summary>
    /// Flash write. Delphi: SendFlashWrite
    /// </summary>
    uint SendFlashWrite(uint addr, uint size, byte[] data,
        int waitMs = 100000, int retry = 0);

    /// <summary>
    /// Flash pre-work (X3584/X3585 specific). Delphi: SendFlashPrework
    /// </summary>
    uint SendFlashPrework(int waitMs = 100000, int retry = 0);

    /// <summary>
    /// Get flash data from buffer (AF9). Delphi: GetFlashDataBuf
    /// </summary>
    uint GetFlashDataBuf(uint addr, uint len, byte[] data);

    /// <summary>
    /// Update flash data buffer (AF9). Delphi: UpdateFlashDataBuf
    /// </summary>
    uint UpdateFlashDataBuf(uint addr, uint len, byte[] data);

    // =========================================================================
    // DP860 Low-Level Commands (exposed for Mainter/diagnostics)
    // =========================================================================

    /// <summary>
    /// Send raw DP860 command. Delphi: DP860_SendCmd
    /// </summary>
    uint Dp860SendCmd(string command, int cmdId, string cmdName, int waitMs = 3000, int retry = 0);

    /// <summary>
    /// Send DP860 version.all. Delphi: DP860_SendVersionAll
    /// </summary>
    uint Dp860SendVersionAll(int waitMs = 5000, int retry = 0);

    /// <summary>
    /// Send DP860 model info download. Delphi: DP860_ModelInfoDownload
    /// </summary>
    uint Dp860ModelInfoDownload();

    /// <summary>
    /// Send DP860 model file. Delphi: DP860_SendModelFile
    /// </summary>
    uint Dp860SendModelFile(string modelFileName, int waitMs = 10000, int retry = 0);

    /// <summary>
    /// Send DP860 power on. Delphi: DP860_SendPowerOn
    /// </summary>
    uint Dp860SendPowerOn(int waitMs = 10000, int retry = 0);

    /// <summary>
    /// Send DP860 power off. Delphi: DP860_SendPowerOff
    /// </summary>
    uint Dp860SendPowerOff(int waitMs = 3000, int retry = 0);

    /// <summary>
    /// Clear OC TCON R/W counters. Delphi: DP860_ClearOcTconRWCnt
    /// </summary>
    void Dp860ClearOcTconRwCount();

    /// <summary>
    /// OC on/off. Delphi: DP860_SendOcOnOff
    /// </summary>
    uint Dp860SendOcOnOff(int state, int waitMs = 3000, int retry = 0);

    /// <summary>
    /// Warms up the transport layer (NIC/DMA/CPU caches) before compensation flow.
    /// </summary>
    void WarmupTransport();

    /// <summary>
    /// NVM init. Delphi: DP860_SendNvmInit
    /// </summary>
    uint Dp860SendNvmInit(int mode, int waitMs = 3000, int retry = 0);

    /// <summary>
    /// GPIO read. Delphi: DP860_SendGpioRead
    /// </summary>
    uint Dp860SendGpioRead(string gpio, int waitMs = 5000, int retry = 0);

    /// <summary>
    /// GPIO panel IRQ read. Delphi: DP860_SendGpioPanel_IRQ
    /// </summary>
    uint Dp860SendGpioPanelIrq(out int data, int waitMs = 5000, int retry = 0);

    /// <summary>
    /// FTP disconnect. Delphi: DP860_FTPDiscon
    /// </summary>
    uint Dp860FtpDisconnect();
}
