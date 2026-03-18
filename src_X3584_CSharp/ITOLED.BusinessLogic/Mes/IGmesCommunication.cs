// =============================================================================
// IGmesCommunication.cs
// Converted from Delphi: src_X3584\GMesCom.pas (TGmes class interface)
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Mes
// =============================================================================

namespace Dongaeltek.ITOLED.BusinessLogic.Mes;

/// <summary>
/// GMES (Global Manufacturing Execution System) communication service.
/// Handles all MES/EAS/R2R protocol communication for production reporting,
/// including PCHK, EICR, APDR, LPIR, EIJR, ZSET, SGEN, and R2R data exchange.
/// <para>Delphi origin: TGmes class from GMesCom.pas</para>
/// </summary>
public interface IGmesCommunication : IDisposable
{
    // =========================================================================
    // Initialization
    // =========================================================================

    /// <summary>
    /// Initialize the HOST (MES) TIB server connection.
    /// <para>Delphi: function HOST_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath)</para>
    /// </summary>
    /// <returns><c>true</c> if initialization succeeded.</returns>
    bool HostInitial(string servicePort, string network, string daemonPort,
                     string localSubject, string remoteSubject, string logPath);

    /// <summary>
    /// Initialize the EAS TIB server connection.
    /// <para>Delphi: function Eas_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath)</para>
    /// </summary>
    /// <returns><c>true</c> if initialization succeeded.</returns>
    bool EasInitial(string servicePort, string network, string daemonPort,
                    string localSubject, string remoteSubject, string logPath);

    /// <summary>
    /// Initialize the R2R (Run-to-Run) TIB server connection.
    /// <para>Delphi: function R2R_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath)</para>
    /// </summary>
    /// <returns><c>true</c> if initialization succeeded.</returns>
    bool R2RInitial(string servicePort, string network, string daemonPort,
                    string localSubject, string remoteSubject, string logPath);

    // =========================================================================
    // Host Start / R2R Start
    // =========================================================================

    /// <summary>
    /// Start HOST communication sequence: EAYT -> UCHK -> EDTI.
    /// <para>Delphi: procedure SendHostStart</para>
    /// </summary>
    void SendHostStart();

    /// <summary>
    /// Start R2R communication sequence: R2R_EAYT.
    /// <para>Delphi: procedure SendR2RStart</para>
    /// </summary>
    void SendR2RStart();

    // =========================================================================
    // MES Send Methods
    // =========================================================================

    /// <summary>
    /// Send EAYT (Equipment Auto/Ready Transition) to HOST.
    /// <para>Delphi: procedure SendHostEayt</para>
    /// </summary>
    void SendHostEayt();

    /// <summary>
    /// Send UCHK (User Check) to HOST.
    /// <para>Delphi: procedure SendHostUchk</para>
    /// </summary>
    void SendHostUchk();

    /// <summary>
    /// Send EQCC (Equipment Quality Check Confirmation) to HOST.
    /// <para>Delphi: procedure SendHostEqcc</para>
    /// </summary>
    void SendHostEqcc();

    /// <summary>
    /// Send PCHK (Process Check) to HOST. Enqueued and sent via the message queue timer.
    /// <para>Delphi: procedure SendHostPchk(sSerialNo, nPg, sJigId, bIsDelayed)</para>
    /// </summary>
    /// <param name="serialNo">Panel serial number (PID or SERIAL_NO).</param>
    /// <param name="pg">PG/channel index (0-based).</param>
    /// <param name="jigId">JIG/ZIG ID.</param>
    void SendHostPchk(string serialNo, int pg, string jigId);

    /// <summary>
    /// Send LPIR (Lot Process Information Report) to HOST.
    /// <para>Delphi: procedure SendHostLpir(sSerialNo, nPg, bIsDelayed)</para>
    /// </summary>
    void SendHostLpir(string serialNo, int pg);

    /// <summary>
    /// Send INS_PCHK (Inspection Process Check) to HOST.
    /// <para>Delphi: procedure SendHostIns_Pchk(sSerialNo, nPg, sJigId, bIsDelayed)</para>
    /// </summary>
    void SendHostInsPchk(string serialNo, int pg, string jigId);

    /// <summary>
    /// Send EICR (Equipment Inspection Complete Report) to HOST.
    /// <para>Delphi: procedure SendHostEicr(sSerialNo, nPg, sJigId, bIsDelayed)</para>
    /// </summary>
    void SendHostEicr(string serialNo, int pg, string jigId);

    /// <summary>
    /// Send EIJR to HOST.
    /// <para>Delphi: procedure SendHostEijr(sSerialNo, nPg, sJigId, bIsDelayed)</para>
    /// </summary>
    void SendHostEijr(string serialNo, int pg, string jigId);

    /// <summary>
    /// Send RPR_EIJR (Repair EIJR) to HOST.
    /// <para>Delphi: procedure SendHostRPr_Eijr(sSerialNo, nPg, sJigId, bIsDelayed)</para>
    /// </summary>
    void SendHostRprEijr(string serialNo, int pg, string jigId);

    /// <summary>
    /// Send RPR_VSIR (Repair VSIR) to HOST.
    /// <para>Delphi: procedure SendHostRpr_Vsir(sSerialNo, nPg)</para>
    /// </summary>
    void SendHostRprVsir(string serialNo, int pg);

    /// <summary>
    /// Send APDR (Automatic Process Data Report) to HOST.
    /// <para>Delphi: procedure SendHostApdr(sSerialNo, nPg, bIsDelayed)</para>
    /// </summary>
    void SendHostApdr(string serialNo, int pg);

    /// <summary>
    /// Send REPN (Report Notification / Label Print) to HOST.
    /// <para>Delphi: procedure SendHostRePn(sSerialNo, nPg)</para>
    /// </summary>
    void SendHostRepn(string serialNo, int pg);

    /// <summary>
    /// Send FLDR (File Download Report) to HOST.
    /// <para>Delphi: procedure SendHostFldr(sMsg)</para>
    /// </summary>
    void SendHostFldr(string message);

    /// <summary>
    /// Send ZSET (Z-axis Setting) to HOST.
    /// <para>Delphi: procedure SendHostZset(sPid, sZigId)</para>
    /// </summary>
    void SendHostZset(string pid, string zigId);

    /// <summary>
    /// Send SGEN (Serial Generation) to HOST.
    /// <para>Delphi: procedure SendHostSGEN(sSerialNo, nPg, bIsDelayed)</para>
    /// </summary>
    void SendHostSgen(string serialNo, int pg);

    // =========================================================================
    // EAS Send Methods
    // =========================================================================

    /// <summary>
    /// Send APDR to EAS server.
    /// <para>Delphi: procedure SendEasApdr(sSerialNo, nPg, bIsDelayed)</para>
    /// </summary>
    void SendEasApdr(string serialNo, int pg);

    // =========================================================================
    // R2R Send Methods
    // =========================================================================

    /// <summary>
    /// Send R2R EAYT.
    /// <para>Delphi: procedure SendR2REayt</para>
    /// </summary>
    void SendR2REayt();

    /// <summary>
    /// Send R2R EODS response.
    /// <para>Delphi: procedure SendR2REods(nPG)</para>
    /// </summary>
    void SendR2REods(int pg);

    /// <summary>
    /// Send R2R EODS test message.
    /// <para>Delphi: procedure SendR2REodsTest(nCH)</para>
    /// </summary>
    void SendR2REodsTest(int channel);

    /// <summary>
    /// Send R2R EODA (End Of Data Acknowledgement).
    /// <para>Delphi: procedure SendR2REoda(nPg, nAACK)</para>
    /// </summary>
    void SendR2REoda(int pg, int aack);

    // =========================================================================
    // Data Processing (incoming message handlers)
    // =========================================================================

    /// <summary>
    /// Process incoming HOST (MES) data message.
    /// <para>Delphi: procedure GetHostData(sMsg)</para>
    /// </summary>
    void GetHostData(string message);

    /// <summary>
    /// Process incoming EAS data message.
    /// <para>Delphi: procedure GetEasData(sMsg)</para>
    /// </summary>
    void GetEasData(string message);

    /// <summary>
    /// Process incoming R2R data message.
    /// <para>Delphi: procedure GetR2RData(sMsg)</para>
    /// </summary>
    void GetR2RData(string message);

    /// <summary>
    /// Get EAS R2R data string for specified channel.
    /// <para>Delphi: function GetEASR2RData(nCH): string</para>
    /// </summary>
    string GetEasR2RData(int channel);

    // =========================================================================
    // Properties
    // =========================================================================

    /// <summary>
    /// MES data per channel. Index: 0..MAX_PG_CNT-1.
    /// <para>Delphi: MesData : array[0..MAX_PG_CNT-1] of TGmesDataPack</para>
    /// </summary>
    GmesDataPack[] MesData { get; }

    /// <summary>
    /// Whether HOST connection is available.
    /// <para>Delphi: CanUseHost : Boolean</para>
    /// </summary>
    bool CanUseHost { get; set; }

    /// <summary>
    /// Whether EAS connection is available.
    /// <para>Delphi: CanUseEas : Boolean</para>
    /// </summary>
    bool CanUseEas { get; }

    /// <summary>
    /// Whether R2R connection is available.
    /// <para>Delphi: CanUseR2R : Boolean</para>
    /// </summary>
    bool CanUseR2R { get; }

    /// <summary>
    /// PM (Preventive Maintenance) mode.
    /// <para>Delphi: MesPmMode : Boolean</para>
    /// </summary>
    bool MesPmMode { get; set; }

    /// <summary>
    /// EAYT acknowledged.
    /// <para>Delphi: MesEayt : Boolean</para>
    /// </summary>
    bool MesEayt { get; set; }

    /// <summary>
    /// MES return code from last response.
    /// <para>Delphi: MesRtnCd : string</para>
    /// </summary>
    string MesRtnCd { get; set; }

    /// <summary>
    /// MES error message (English).
    /// <para>Delphi: MesErrMsgEn : string</para>
    /// </summary>
    string MesErrMsgEn { get; set; }

    /// <summary>
    /// MES error message (Local/Korean).
    /// <para>Delphi: MesErrMsgLc : string</para>
    /// </summary>
    string MesErrMsgLc { get; set; }

    /// <summary>
    /// MES model name returned from host.
    /// <para>Delphi: MesModel : string</para>
    /// </summary>
    string MesModel { get; set; }

    /// <summary>
    /// MES model info for PCHK (mix-up prevention).
    /// <para>Delphi: MesModelInfo : string</para>
    /// </summary>
    string MesModelInfo { get; set; }

    /// <summary>
    /// System number (equipment ID).
    /// <para>Delphi: MesSystemNo : string</para>
    /// </summary>
    string MesSystemNo { get; set; }

    /// <summary>
    /// MGIB system number.
    /// <para>Delphi: MesSystemNo_MGIB : string</para>
    /// </summary>
    string MesSystemNoMgib { get; set; }

    /// <summary>
    /// PGIB system number.
    /// <para>Delphi: MesSystemNo_PGIB : string</para>
    /// </summary>
    string MesSystemNoPgib { get; set; }

    /// <summary>
    /// User ID for MES operations.
    /// <para>Delphi: MesUserId : string</para>
    /// </summary>
    string MesUserId { get; set; }

    /// <summary>
    /// MES serial number.
    /// <para>Delphi: MesSerialNo : string</para>
    /// </summary>
    string MesSerialNo { get; set; }

    /// <summary>
    /// MES label ID.
    /// <para>Delphi: MesLabelID : string</para>
    /// </summary>
    string MesLabelId { get; set; }

    /// <summary>
    /// MES user name returned from UCHK.
    /// <para>Delphi: MesUserName : string</para>
    /// </summary>
    string MesUserName { get; set; }

    /// <summary>
    /// MES PID (Panel ID).
    /// <para>Delphi: MesPID : string</para>
    /// </summary>
    string MesPid { get; set; }

    /// <summary>
    /// Current PG number for MES operations.
    /// <para>Delphi: MesPg : Integer</para>
    /// </summary>
    int MesPg { get; set; }

    /// <summary>
    /// Current APDR PG number.
    /// <para>Delphi: MesApdrPg : Integer</para>
    /// </summary>
    int MesApdrPg { get; set; }

    /// <summary>
    /// MES serial type (0=FOG_ID, 1=PID, 2=SERIAL_NO).
    /// <para>Delphi: MesSerialType : Integer</para>
    /// </summary>
    int MesSerialType { get; set; }

    /// <summary>
    /// MES FOG ID.
    /// <para>Delphi: MesFogId : string</para>
    /// </summary>
    string MesFogId { get; set; }

    /// <summary>
    /// R2R Machine ID.
    /// <para>Delphi: R2RMachine : string (read-only)</para>
    /// </summary>
    string R2RMachine { get; }

    /// <summary>
    /// R2R MMC Transaction ID.
    /// <para>Delphi: R2RMmcTxnID : string (read-only)</para>
    /// </summary>
    string R2RMmcTxnId { get; }

    /// <summary>
    /// Lot number.
    /// <para>Delphi: m_sLotNo : string</para>
    /// </summary>
    string LotNo { get; set; }

    /// <summary>
    /// EIJR send flag.
    /// <para>Delphi: FEiJRSend : Boolean</para>
    /// </summary>
    bool EijrSend { get; set; }

    /// <summary>
    /// EODS done flags per channel.
    /// <para>Delphi: m_bDoneEODS : array[CH1..MAX_CH] of Boolean</para>
    /// </summary>
    bool[] DoneEods { get; }

    /// <summary>
    /// Number of pending MES queue items + 1.
    /// <para>Delphi: MES_Queue_Cnt : Integer</para>
    /// </summary>
    int MesQueueCount { get; }

    // =========================================================================
    // FTP Properties
    // =========================================================================

    /// <summary>FTP server address. Delphi: FtpAddr</summary>
    string FtpAddr { get; set; }

    /// <summary>FTP username. Delphi: FtpUser</summary>
    string FtpUser { get; set; }

    /// <summary>FTP password. Delphi: FtpPass</summary>
    string FtpPass { get; set; }

    /// <summary>FTP combi data path. Delphi: FtpCombiPath</summary>
    string FtpCombiPath { get; set; }

    // =========================================================================
    // Events
    // =========================================================================

    /// <summary>
    /// Event raised when a GMES operation completes (replaces Delphi TGmesEvent callback).
    /// Parameters: (msgType, pg, isError, errorMessage).
    /// <para>Delphi: OnGmsEvent : TGmesEvent</para>
    /// </summary>
    event Action<int, int, bool, string>? OnGmesEvent;
}
