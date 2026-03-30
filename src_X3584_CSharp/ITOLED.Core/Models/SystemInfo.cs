// =============================================================================
// SystemInfo.cs
// Converted from Delphi: src_X3584\CommonClass.pas (lines 47-236)
// Contains: TSystemInfo, TPLCInfo, TSimulateInfo
// =============================================================================

using System.Collections.Generic;
using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// Main system configuration record holding all machine/software settings.
    /// <para>Original Delphi: TSystemInfo = record (CommonClass.pas line 47)</para>
    /// </summary>
    public class SystemInfo
    {
        // ---- Paths and general settings ----

        /// <summary>
        /// DAELoadWizard installation path. Added by KTS 2022-12-27.
        /// <para>Delphi field: DAELoadWizardPath : string</para>
        /// </summary>
        public string DAELoadWizardPath { get; set; } = string.Empty;

        /// <summary>
        /// System password.
        /// <para>Delphi field: Password : String</para>
        /// </summary>
        public string Password { get; set; } = string.Empty;

        /// <summary>
        /// Supervisor password.
        /// <para>Delphi field: SupervisorPassword : string</para>
        /// </summary>
        public string SupervisorPassword { get; set; } = string.Empty;

        /// <summary>
        /// Test model name (editing use).
        /// <para>Delphi field: TestModel : String</para>
        /// </summary>
        public string TestModel { get; set; } = string.Empty;

        /// <summary>
        /// Pattern group name.
        /// <para>Delphi field: PatGrp : string</para>
        /// </summary>
        public string PatGrp { get; set; } = string.Empty;

        /// <summary>
        /// LGD DLL version name.
        /// <para>Delphi field: LGD_DLLVER_Name : string</para>
        /// </summary>
        public string LGDDLLVerName { get; set; } = string.Empty;

        /// <summary>
        /// OC Converter name.
        /// <para>Delphi field: OC_Converter_Name : string</para>
        /// </summary>
        public string OCConverterName { get; set; } = string.Empty;

        // ---- Channel-indexed arrays ----

        /// <summary>
        /// IP addresses per channel (PG-0).
        /// <para>Delphi field: IPAddr : TArrayChannelString (array[0..MAX_CH] of String)</para>
        /// </summary>
        public string[] IPAddr { get; set; }

        /// <summary>
        /// Probe addresses per channel.
        /// <para>Delphi field: ProbAddr : TArrayChannelString</para>
        /// </summary>
        public string[] ProbAddr { get; set; }

        // ---- COM port assignments ----

        /// <summary>
        /// Hand BCR COM port assignments (0:None, 1:COM1, 2:COM2...).
        /// <para>Delphi field: Com_HandBCR : array[0..pred(MAX_BCR_CNT)] of Integer</para>
        /// </summary>
        public int[] ComHandBCR { get; set; }

        /// <summary>
        /// RCB switch COM port assignments.
        /// <para>Delphi field: Com_RCB : array[0..pred(MAX_SWITCH_CNT)] of Integer</para>
        /// </summary>
        public int[] ComRCB { get; set; }

        /// <summary>
        /// Z motor configuration.
        /// <para>Delphi field: Z_Motor : Integer</para>
        /// </summary>
        public int ZMotor { get; set; }

        /// <summary>
        /// Camera light COM port.
        /// <para>Delphi field: Com_CamLight : Integer</para>
        /// </summary>
        public int ComCamLight { get; set; }

        /// <summary>
        /// Camera delay in ms.
        /// <para>Delphi field: CamDelay : Integer</para>
        /// </summary>
        public int CamDelay { get; set; }

        /// <summary>
        /// IR temperature sensor COM port.
        /// <para>Delphi field: Com_IrTempSensor : Integer</para>
        /// </summary>
        public int ComIrTempSensor { get; set; }

        /// <summary>
        /// Set temperature value.
        /// <para>Delphi field: SetTemperature : Integer</para>
        /// </summary>
        public int SetTemperature { get; set; }

        /// <summary>
        /// Number of ionizers in use.
        /// <para>Delphi field: IonizerCnt : Integer</para>
        /// </summary>
        public int IonizerCnt { get; set; }

        /// <summary>
        /// Ionizer COM port assignments.
        /// <para>Delphi field: Com_Ionizer : array[0..pred(MAX_IONIZER_CNT)] of Integer</para>
        /// </summary>
        public int[] ComIonizer { get; set; }

        /// <summary>
        /// Ionizer model types.
        /// <para>Delphi field: Model_Ionizer : array[0..pred(MAX_IONIZER_CNT)] of Integer</para>
        /// </summary>
        public int[] ModelIonizer { get; set; }

        /// <summary>
        /// PG Memory size (128Mb, 256Mb, 512Mb).
        /// <para>Delphi field: PGMemorySize : Integer</para>
        /// </summary>
        public int PGMemorySize { get; set; }

        /// <summary>
        /// UI type: 0=Normal, 1=Black.
        /// <para>Delphi field: UIType : Integer</para>
        /// </summary>
        public int UIType { get; set; }

        /// <summary>
        /// OC type: OC / Pre OC distinction. Added by KTS 2022-11-25.
        /// <para>Delphi field: OCType : Integer</para>
        /// </summary>
        public int OCType { get; set; }

        /// <summary>
        /// Number of channels used.
        /// <para>Delphi field: ChCountUsed : Integer</para>
        /// </summary>
        public int ChCountUsed { get; set; }

        /// <summary>
        /// Whether auto start is enabled.
        /// <para>Delphi field: AutoStart : Boolean</para>
        /// </summary>
        public bool AutoStart { get; set; }

        /// <summary>
        /// OC manual mode type.
        /// <para>Delphi field: OcManualType : Boolean</para>
        /// </summary>
        public bool OcManualType { get; set; }

        // ---- MES/Network settings ----

        /// <summary>
        /// Service port string.
        /// <para>Delphi field: ServicePort : String</para>
        /// </summary>
        public string ServicePort { get; set; } = string.Empty;

        /// <summary>
        /// Network string.
        /// <para>Delphi field: Network : String</para>
        /// </summary>
        public string Network { get; set; } = string.Empty;

        /// <summary>
        /// Daemon port string.
        /// <para>Delphi field: DaemonPort : String</para>
        /// </summary>
        public string DaemonPort { get; set; } = string.Empty;

        /// <summary>
        /// Local subject string.
        /// <para>Delphi field: LocalSubject : String</para>
        /// </summary>
        public string LocalSubject { get; set; } = string.Empty;

        /// <summary>
        /// Remote subject string.
        /// <para>Delphi field: RemoteSubject : String</para>
        /// </summary>
        public string RemoteSubject { get; set; } = string.Empty;

        /// <summary>
        /// EQCC interval string.
        /// <para>Delphi field: EqccInterval : String</para>
        /// </summary>
        public string EqccInterval { get; set; } = string.Empty;

        /// <summary>
        /// EQP ID type.
        /// <para>Delphi field: EQPId_Type : Integer</para>
        /// </summary>
        public int EQPIdType { get; set; }

        /// <summary>
        /// Selected EQP ID.
        /// <para>Delphi field: EQPId : String</para>
        /// </summary>
        public string EQPId { get; set; } = string.Empty;

        /// <summary>
        /// Inline EQP ID.
        /// <para>Delphi field: EQPId_INLINE : String</para>
        /// </summary>
        public string EQPIdInline { get; set; } = string.Empty;

        /// <summary>
        /// MGIB EQP ID.
        /// <para>Delphi field: EQPId_MGIB : String</para>
        /// </summary>
        public string EQPIdMGIB { get; set; } = string.Empty;

        /// <summary>
        /// PGIB EQP ID.
        /// <para>Delphi field: EQPId_PGIB : String</para>
        /// </summary>
        public string EQPIdPGIB { get; set; } = string.Empty;

        /// <summary>
        /// MGIB Process Code (LPIR-related).
        /// <para>Delphi field: EQPId_MGIB_Process_Code : string</para>
        /// </summary>
        public string EQPIdMGIBProcessCode { get; set; } = string.Empty;

        /// <summary>
        /// PGIB Process Code (LPIR-related).
        /// <para>Delphi field: EQPId_PGIB_Process_Code : string</para>
        /// </summary>
        public string EQPIdPGIBProcessCode { get; set; } = string.Empty;

        /// <summary>
        /// Set A model flag.
        /// <para>Delphi field: SetAModel : boolean</para>
        /// </summary>
        public bool SetAModel { get; set; }

        // ---- Length limits ----

        /// <summary>
        /// PID length limit.
        /// <para>Delphi field: PIDLengthLimit : Integer</para>
        /// </summary>
        public int PIDLengthLimit { get; set; }

        /// <summary>
        /// ZIG length limit.
        /// <para>Delphi field: ZIGLengthLimit : Integer</para>
        /// </summary>
        public int ZIGLengthLimit { get; set; }

        // ---- EAS settings ----

        /// <summary>
        /// EAS service string.
        /// <para>Delphi field: Eas_Service : string</para>
        /// </summary>
        public string EasService { get; set; } = string.Empty;

        /// <summary>
        /// EAS network string.
        /// <para>Delphi field: Eas_Network : string</para>
        /// </summary>
        public string EasNetwork { get; set; } = string.Empty;

        /// <summary>
        /// EAS daemon port string.
        /// <para>Delphi field: Eas_DeamonPort : string</para>
        /// </summary>
        public string EasDaemonPort { get; set; } = string.Empty;

        /// <summary>
        /// EAS local subject string.
        /// <para>Delphi field: Eas_LocalSubject : string</para>
        /// </summary>
        public string EasLocalSubject { get; set; } = string.Empty;

        /// <summary>
        /// EAS remote subject string.
        /// <para>Delphi field: Eas_RemoteSubject : string</para>
        /// </summary>
        public string EasRemoteSubject { get; set; } = string.Empty;

        // ---- R2R settings ----

        /// <summary>
        /// R2R service string.
        /// <para>Delphi field: R2R_Service : string</para>
        /// </summary>
        public string R2RService { get; set; } = string.Empty;

        /// <summary>
        /// R2R network string.
        /// <para>Delphi field: R2R_Network : string</para>
        /// </summary>
        public string R2RNetwork { get; set; } = string.Empty;

        /// <summary>
        /// R2R daemon port string.
        /// <para>Delphi field: R2R_DeamonPort : string</para>
        /// </summary>
        public string R2RDaemonPort { get; set; } = string.Empty;

        /// <summary>
        /// R2R local subject string.
        /// <para>Delphi field: R2R_LocalSubject : string</para>
        /// </summary>
        public string R2RLocalSubject { get; set; } = string.Empty;

        /// <summary>
        /// R2R remote subject string.
        /// <para>Delphi field: R2R_RemoteSubject : string</para>
        /// </summary>
        public string R2RRemoteSubject { get; set; } = string.Empty;

        // ---- Counts and delays ----

        /// <summary>
        /// Service count.
        /// <para>Delphi field: Service_Cnt : integer</para>
        /// </summary>
        public int ServiceCnt { get; set; }

        /// <summary>
        /// MES code count.
        /// <para>Delphi field: MES_CODE_Cnt : Integer</para>
        /// </summary>
        public int MESCodeCnt { get; set; }

        /// <summary>
        /// Popup message timeout (ms).
        /// <para>Delphi field: PopupMsgTime : Integer</para>
        /// </summary>
        public int PopupMsgTime { get; set; }

        /// <summary>
        /// PG reset delay time (ms).
        /// <para>Delphi field: PGResetDelayTime : Integer</para>
        /// </summary>
        public int PGResetDelayTime { get; set; }

        /// <summary>
        /// PG reset total count.
        /// <para>Delphi field: PGResetTotalConut : Integer</para>
        /// </summary>
        public int PGResetTotalCount { get; set; }

        /// <summary>
        /// Display DLL count.
        /// <para>Delphi field: DisplayDLLCnt : Integer</para>
        /// </summary>
        public int DisplayDLLCnt { get; set; }

        /// <summary>
        /// MES model info for PCHK (model name used for mix-up prevention).
        /// <para>Delphi field: MesModelInfo : string</para>
        /// </summary>
        public string MesModelInfo { get; set; } = string.Empty;

        /// <summary>
        /// Loader index string.
        /// <para>Delphi field: Loader_Index : string</para>
        /// </summary>
        public string LoaderIndex { get; set; } = string.Empty;

        /// <summary>
        /// Power log enabled.
        /// <para>Delphi field: PowerLog : Boolean</para>
        /// </summary>
        public bool PowerLog { get; set; }

        /// <summary>
        /// Channel usage flags per channel.
        /// <para>Delphi field: UseCh : TArrayChannelBoolean (array[0..MAX_CH] of Boolean)</para>
        /// </summary>
        public bool[] UseCh { get; set; }

        /// <summary>
        /// Offset values per channel.
        /// <para>Delphi field: OffSet_Ch : TArrayChannelDouble (array[0..MAX_CH] of Double)</para>
        /// </summary>
        public double[] OffsetCh { get; set; }

        // ---- FTP settings ----

        /// <summary>
        /// Host FTP IP address.
        /// <para>Delphi field: HOST_FTP_IPAddr : string</para>
        /// </summary>
        public string HostFTPIPAddr { get; set; } = string.Empty;

        /// <summary>
        /// Host FTP username.
        /// <para>Delphi field: HOST_FTP_User : string</para>
        /// </summary>
        public string HostFTPUser { get; set; } = string.Empty;

        /// <summary>
        /// Host FTP password.
        /// <para>Delphi field: HOST_FTP_Passwd : string</para>
        /// </summary>
        public string HostFTPPasswd { get; set; } = string.Empty;

        /// <summary>
        /// Host FTP combi data path.
        /// <para>Delphi field: HOST_FTP_CombiPath : string</para>
        /// </summary>
        public string HostFTPCombiPath { get; set; } = string.Empty;

        // ---- Backup settings ----

        /// <summary>
        /// Auto backup enabled.
        /// <para>Delphi field: AutoBackupUse : Boolean</para>
        /// </summary>
        public bool AutoBackupUse { get; set; }

        /// <summary>
        /// Auto backup file list.
        /// <para>Delphi field: AutoBackupList : string</para>
        /// </summary>
        public string AutoBackupList { get; set; } = string.Empty;

        /// <summary>
        /// Auto LGD log backup enabled.
        /// <para>Delphi field: AutoLGDLogBackup : Boolean</para>
        /// </summary>
        public bool AutoLGDLogBackup { get; set; }

        // ---- DLL version interlock ----

        /// <summary>
        /// DLL version interlock enabled.
        /// <para>Delphi field: DLLVerInterlock : Boolean</para>
        /// </summary>
        public bool DLLVerInterlock { get; set; }

        /// <summary>
        /// SW version interlock string.
        /// <para>Delphi field: SWVerInterlock : string</para>
        /// </summary>
        public string SWVerInterlock { get; set; } = string.Empty;

        /// <summary>
        /// DLL version interlock list.
        /// <para>Delphi field: DLLVerInterlockList : string</para>
        /// </summary>
        public string DLLVerInterlockList { get; set; } = string.Empty;

        // ---- Local IP ----

        /// <summary>
        /// Local IP for GMES.
        /// <para>Delphi field: LocalIP_GMES : string</para>
        /// </summary>
        public string LocalIPGMES { get; set; } = string.Empty;

        /// <summary>
        /// Local IP for PLC.
        /// <para>Delphi field: LocalIP_PLC : string</para>
        /// </summary>
        public string LocalIPPLC { get; set; } = string.Empty;

        /// <summary>
        /// PLC configuration file path.
        /// <para>Delphi field: PlcConfigPath : string</para>
        /// </summary>
        public string PlcConfigPath { get; set; } = string.Empty;

        // ---- Feature flags ----

        /// <summary>
        /// Use manual serial number entry.
        /// <para>Delphi field: UseManualSerial : Boolean</para>
        /// </summary>
        public bool UseManualSerial { get; set; }

        /// <summary>
        /// System log enabled.
        /// <para>Delphi field: SystemLogUse : Boolean</para>
        /// </summary>
        public bool SystemLogUse { get; set; }

        /// <summary>
        /// Auto BCR enabled.
        /// <para>Delphi field: UseAutoBCR : Boolean</para>
        /// </summary>
        public bool UseAutoBCR { get; set; }

        /// <summary>
        /// EQCC enabled.
        /// <para>Delphi field: UseEQCC : Boolean</para>
        /// </summary>
        public bool UseEQCC { get; set; }

        /// <summary>
        /// Touch test enabled.
        /// <para>Delphi field: UseTouchTest : Boolean</para>
        /// </summary>
        public bool UseTouchTest { get; set; }

        /// <summary>
        /// DIO type identifier.
        /// <para>Delphi field: DIOType : Integer</para>
        /// </summary>
        public int DIOType { get; set; }

        /// <summary>
        /// Index motor timeout (ms).
        /// <para>Delphi field: IndexMotor_Timeout : Integer</para>
        /// </summary>
        public int IndexMotorTimeout { get; set; }

        /// <summary>
        /// Script version.
        /// <para>Delphi field: ScriptVer : string</para>
        /// </summary>
        public string ScriptVer { get; set; } = string.Empty;

        /// <summary>
        /// Script CRC.
        /// <para>Delphi field: ScriptCrc : string</para>
        /// </summary>
        public string ScriptCrc { get; set; } = string.Empty;

        // ---- Robot settings ----

        /// <summary>
        /// Robot revision A.
        /// <para>Delphi field: RobotRevA : string</para>
        /// </summary>
        public string RobotRevA { get; set; } = string.Empty;

        /// <summary>
        /// Robot revision B.
        /// <para>Delphi field: RobotRevB : string</para>
        /// </summary>
        public string RobotRevB { get; set; } = string.Empty;

        /// <summary>
        /// Robot output A.
        /// <para>Delphi field: RobotOutA : string</para>
        /// </summary>
        public string RobotOutA { get; set; } = string.Empty;

        /// <summary>
        /// Robot output B.
        /// <para>Delphi field: RobotOutB : string</para>
        /// </summary>
        public string RobotOutB { get; set; } = string.Empty;

        /// <summary>
        /// Power version per channel.
        /// <para>Delphi field: nPwrVer : TArrayChannelInteger (array[0..MAX_CH] of Integer)</para>
        /// </summary>
        public int[] PwrVer { get; set; }

        /// <summary>
        /// Firmware version string.
        /// <para>Delphi field: FwVer : string</para>
        /// </summary>
        public string FwVer { get; set; } = string.Empty;

        /// <summary>
        /// FPGA version string.
        /// <para>Delphi field: FpgaVer : string</para>
        /// </summary>
        public string FpgaVer { get; set; } = string.Empty;

        /// <summary>
        /// Process name.
        /// <para>Delphi field: ProcessName : string</para>
        /// </summary>
        public string ProcessName { get; set; } = string.Empty;

        /// <summary>
        /// Inspection type.
        /// <para>Delphi field: InspectionType : integer</para>
        /// </summary>
        public int InspectionType { get; set; }

        /// <summary>
        /// NG alarm count threshold.
        /// <para>Delphi field: NGAlarmCount : integer</para>
        /// </summary>
        public int NGAlarmCount { get; set; }

        /// <summary>
        /// Contact retry count.
        /// <para>Delphi field: RetryCount : integer</para>
        /// </summary>
        public int RetryCount { get; set; }

        /// <summary>
        /// Write POCB retry count.
        /// <para>Delphi field: RetryCount_WritePOCB : integer</para>
        /// </summary>
        public int RetryCountWritePOCB { get; set; }

        /// <summary>
        /// ECS timeout (ms).
        /// <para>Delphi field: ECS_Timeout : integer</para>
        /// </summary>
        public int ECSTimeout { get; set; }

        /// <summary>
        /// MIPI log enabled.
        /// <para>Delphi field: MIPILog : Boolean</para>
        /// </summary>
        public bool MIPILog { get; set; }

        /// <summary>
        /// Use ECS for production reporting (UCHK, PCHK, EICR, APDR).
        /// <para>Delphi field: Use_ECS : Boolean</para>
        /// </summary>
        public bool UseECS { get; set; }

        /// <summary>
        /// Use MES for production reporting (UCHK, PCHK, EICR, APDR).
        /// <para>Delphi field: Use_MES : Boolean</para>
        /// </summary>
        public bool UseMES { get; set; }

        /// <summary>
        /// Use GIB when MES is used (INSPCHK, EIJR).
        /// <para>Delphi field: Use_GIB : Boolean</para>
        /// </summary>
        public bool UseGIB { get; set; }

        // ---- Camera settings ----

        /// <summary>
        /// Camera FFC data process enabled.
        /// <para>Delphi field: CAM_FFCData : Boolean</para>
        /// </summary>
        public bool CAMFFCData { get; set; }

        /// <summary>
        /// Camera stain (blemish) detection process enabled.
        /// <para>Delphi field: CAM_StainData : Boolean</para>
        /// </summary>
        public bool CAMStainData { get; set; }

        /// <summary>
        /// Camera FTP image upload enabled.
        /// <para>Delphi field: CAM_FTPUpload : Boolean</para>
        /// </summary>
        public bool CAMFTPUpload { get; set; }

        /// <summary>
        /// Camera result type selector.
        /// <para>Delphi field: CAM_ResultType : Integer</para>
        /// </summary>
        public int CAMResultType { get; set; }

        /// <summary>
        /// Camera callback for ChangePattern via script function.
        /// <para>Delphi field: CAM_CallbackChangePattern : Boolean</para>
        /// </summary>
        public bool CAMCallbackChangePattern { get; set; }

        /// <summary>
        /// Camera template data enabled.
        /// <para>Delphi field: CAM_TemplateData : Boolean</para>
        /// </summary>
        public bool CAMTemplateData { get; set; }

        /// <summary>
        /// Auto login ID.
        /// <para>Delphi field: AutoLoginID : string</para>
        /// </summary>
        public string AutoLoginID { get; set; } = string.Empty;

        /// <summary>
        /// Test auto-repeat mode.
        /// <para>Delphi field: Test_Repeat : Boolean</para>
        /// </summary>
        public bool TestRepeat { get; set; }

        /// <summary>
        /// No exchange on carrier detection.
        /// <para>Delphi field: UseNoExchange : Boolean</para>
        /// </summary>
        public bool UseNoExchange { get; set; }

        /// <summary>
        /// No POGO on contact.
        /// <para>Delphi field: UseNoPogo : Boolean</para>
        /// </summary>
        public bool UseNoPogo { get; set; }

        /// <summary>
        /// Inline AA mode enabled.
        /// <para>Delphi field: UseInLine_AAMode : Boolean</para>
        /// </summary>
        public bool UseInLineAAMode { get; set; }

        // ---- DPDK transport ----

        /// <summary>
        /// Use DPDK kernel-bypass transport for PG communication.
        /// When false (default), standard Socket UDP is used.
        /// <para>INI key: USE_DPDK</para>
        /// </summary>
        public bool UseDpdk { get; set; }

        /// <summary>
        /// Use Pipeline transport (System.IO.Pipelines + NetCoreServer) for PG communication.
        /// <para>INI key: USE_PIPELINE</para>
        /// </summary>
        public bool UsePipeline { get; set; }

        /// <summary>
        /// DPDK EAL core mask (e.g. "0" = core 0 only, "0x3" = cores 0-1).
        /// <para>INI key: DPDK_CORE_MASK, default "0"</para>
        /// </summary>
        public string DpdkCoreMask { get; set; } = "0";

        /// <summary>
        /// DPDK huge-page memory allocation in MB.
        /// <para>INI key: DPDK_MEMORY_MB, default 256</para>
        /// </summary>
        public int DpdkMemoryMb { get; set; } = 256;

        /// <summary>
        /// DPDK NIC port ID to use.
        /// <para>INI key: DPDK_PORT_ID, default 0</para>
        /// </summary>
        public ushort DpdkPortId { get; set; }

        // ---- CA410 settings (CA410_USE) ----

        /// <summary>
        /// CA310 COM ports per channel.
        /// <para>Delphi field: Com_Ca310 : array[CH1..MAX_CH] of Integer (CA410_USE)</para>
        /// </summary>
        public int[] ComCa310 { get; set; }

        /// <summary>
        /// CA310 device IDs per channel.
        /// <para>Delphi field: Com_Ca310_DevieId : array[CH1..MAX_CH] of Integer (CA410_USE)</para>
        /// </summary>
        public int[] ComCa310DeviceId { get; set; }

        /// <summary>
        /// CA310 serial numbers per channel.
        /// <para>Delphi field: Com_Ca310_SERIAL : array[CH1..MAX_CH] of string (CA410_USE)</para>
        /// </summary>
        public string[] ComCa310Serial { get; set; }

        /// <summary>
        /// CA device list.
        /// <para>Delphi field: Com_CaDeviceList : array[0..pred(MAX_CA_DRIVE_CNT)] of string (CA410_USE)</para>
        /// </summary>
        public string[] ComCaDeviceList { get; set; }

        // ---- Debug and PG settings ----

        /// <summary>
        /// Debug log level configuration (2020-09-16 DEBUG_LOG).
        /// <para>Delphi field: DebugLogLevelConfig : Integer</para>
        /// </summary>
        public int DebugLogLevelConfig { get; set; }

        /// <summary>
        /// PG type (AF9 or DP860).
        /// <para>Delphi field: PG_TYPE : Integer</para>
        /// </summary>
        public int PGType { get; set; }

        /// <summary>
        /// ITO mode enabled.
        /// <para>Delphi field: UseITOMode : Boolean</para>
        /// </summary>
        public bool UseITOMode { get; set; }

        /// <summary>
        /// Save energy mode.
        /// <para>Delphi field: SaveEnergy : Integer</para>
        /// </summary>
        public int SaveEnergy { get; set; }

        /// <summary>
        /// Channel reversal (line inversion, CH1/CH2 swapped).
        /// <para>Delphi field: CHReversal : Boolean</para>
        /// </summary>
        public bool CHReversal { get; set; }

        /// <summary>
        /// B-contact inversion signal list. Added by KTS 2023-01-17.
        /// <para>Delphi field: SignalInversion : string</para>
        /// </summary>
        public string SignalInversion { get; set; } = string.Empty;

        // ---- PG TCON settings ----

        /// <summary>
        /// PG write-read pass address.
        /// <para>Delphi field: PG_WriteReadPassAddr : string</para>
        /// </summary>
        public string PGWriteReadPassAddr { get; set; } = string.Empty;

        /// <summary>
        /// PG TCON write log display (2023-03-28 for T/T Test).
        /// <para>Delphi field: PG_TconWriteLogDisplay : Boolean</para>
        /// </summary>
        public bool PGTconWriteLogDisplay { get; set; }

        /// <summary>
        /// PG TCON write command type (0=all tcon.ocwrite, 1=all tcon.write, 2=mixed).
        /// <para>Delphi field: PG_TconWriteCmdType : Integer</para>
        /// </summary>
        public int PGTconWriteCmdType { get; set; }

        /// <summary>
        /// PG TCON read command type.
        /// <para>Delphi field: PG_TconReadCmdType : Integer</para>
        /// </summary>
        public int PGTconReadCmdType { get; set; }

        /// <summary>
        /// PG TCON OC write delay (ms).
        /// <para>Delphi field: PG_TconOcWriteDelayMsec : Integer</para>
        /// </summary>
        public int PGTconOcWriteDelayMsec { get; set; }

        /// <summary>
        /// PG TCON OC write sync address string (2023-03-30 for T/T Test).
        /// <para>Delphi field: PG_TconOcWriteSyncAddrStr : string</para>
        /// </summary>
        public string PGTconOcWriteSyncAddrStr { get; set; } = string.Empty;

        /// <summary>
        /// PG TCON OC write sync address array (parsed from sync addr string).
        /// <para>Delphi field: PG_ToonOcWriteSyncAddrArr : array of Integer</para>
        /// </summary>
        public List<int> PGTconOcWriteSyncAddrArr { get; set; } = new List<int>();

        /// <summary>
        /// PG GPIO read HPD before measure (2023-03-30 for T/T Test).
        /// <para>Delphi field: PG_GpioReadHpdBeforeMeasure : Boolean</para>
        /// </summary>
        public bool PGGpioReadHpdBeforeMeasure { get; set; }

        /// <summary>
        /// PG wait ack after continuous OC write count (2023-03-31 for T/T Test).
        /// <para>Delphi field: PG_WaitAckAfterContOcWriteCnt : Integer</para>
        /// </summary>
        public int PGWaitAckAfterContOcWriteCnt { get; set; }

        /// <summary>
        /// PG TCON read before delay (ms) (2023-04-24 for T/T Test).
        /// <para>Delphi field: PG_TconReadBeforeDelayMsec : Integer</para>
        /// </summary>
        public int PGTconReadBeforeDelayMsec { get; set; }

        /// <summary>
        /// PG TCON OC write delay loop count (2023-04-24 for T/T Test).
        /// <para>Delphi field: PG_TconOcWriteDelayLoopCnt : Integer</para>
        /// </summary>
        public int PGTconOcWriteDelayLoopCnt { get; set; }

        /// <summary>
        /// PG TCON OC write delay in microseconds (2023-04-24 for T/T Test).
        /// <para>Delphi field: PG_TconOcWriteDelayMicroSec : Integer</para>
        /// </summary>
        public int PGTconOcWriteDelayMicroSec { get; set; }

        /// <summary>
        /// Enable driver warmup on PgDpdkServer initialization.
        /// Sends 64 dummy packets to prime NIC/DMA/CPU caches for lower RTT.
        /// <para>INI key: [DEBUG] PG_EnableDpdkWarmup (default: true)</para>
        /// </summary>
        public bool PGEnableDpdkWarmup { get; set; } = true;

        /// <summary>
        /// PG firmware version per channel. Added by sam81 2023-04-28.
        /// <para>Delphi field: PG_FWVsersion : array[CH1..MAX_CH] of string</para>
        /// </summary>
        public string[] PGFWVersion { get; set; }

        /// <summary>
        /// CA410 memory channel per channel. Added by sam81 2023-04-28.
        /// <para>Delphi field: CA410_MemoryCh : array[CH1..MAX_CH] of string</para>
        /// </summary>
        public string[] CA410MemoryCh { get; set; }

        /// <summary>
        /// Configuration version list.
        /// <para>Delphi field: ConfigVer : array of TSWVer</para>
        /// </summary>
        public List<SWVersion> ConfigVer { get; set; } = new List<SWVersion>();

        /// <summary>
        /// Configuration version count.
        /// <para>Delphi field: ConfigVerCount : Integer</para>
        /// </summary>
        public int ConfigVerCount { get; set; }

        /// <summary>
        /// R2R CA410 memory channel.
        /// <para>Delphi field: R2RCa410MemCh : Integer</para>
        /// </summary>
        public int R2RCa410MemCh { get; set; }

        /// <summary>
        /// R2R EODS data per channel.
        /// <para>Delphi field: R2REODS_Data : array[CH1..MAX_CH] of string</para>
        /// </summary>
        public string[] R2REODSData { get; set; }

        /// <summary>
        /// R2R MmcTxnID data per channel.
        /// <para>Delphi field: R2RMmcTxnID_Data : array[CH1..MAX_CH] of string</para>
        /// </summary>
        public string[] R2RMmcTxnIDData { get; set; }

        /// <summary>
        /// Only-restart mode flag.
        /// <para>Delphi field: OnlyRestartMode : Boolean</para>
        /// </summary>
        public bool OnlyRestartMode { get; set; }

        // =========================================================================
        // Alias properties for driver compatibility (underscore-naming convention)
        // These delegate to the existing PascalCase properties so driver code
        // written with Delphi-style names compiles without change.
        // =========================================================================

        /// <summary>
        /// Alias for <see cref="PGType"/> — PG type (AF9 or DP860).
        /// <para>Delphi field: PG_TYPE : Integer</para>
        /// </summary>
        public int PG_TYPE { get => PGType; set => PGType = value; }

        /// <summary>
        /// Alias for <see cref="PGTconWriteCmdType"/>.
        /// <para>Delphi field: PG_TconWriteCmdType : Integer</para>
        /// </summary>
        public int PG_TconWriteCmdType { get => PGTconWriteCmdType; set => PGTconWriteCmdType = value; }

        /// <summary>
        /// Alias for <see cref="PGTconReadCmdType"/>.
        /// <para>Delphi field: PG_TconReadCmdType : Integer</para>
        /// </summary>
        public int PG_TconReadCmdType { get => PGTconReadCmdType; set => PGTconReadCmdType = value; }

        /// <summary>
        /// Alias for <see cref="PGTconReadBeforeDelayMsec"/>.
        /// <para>Delphi field: PG_TconReadBeforeDelayMsec : Integer</para>
        /// </summary>
        public int PG_TconReadBeforeDelayMsec { get => PGTconReadBeforeDelayMsec; set => PGTconReadBeforeDelayMsec = value; }

        /// <summary>
        /// Alias for <see cref="PGTconOcWriteDelayMsec"/>.
        /// <para>Delphi field: PG_TconOcWriteDelayMsec : Integer</para>
        /// </summary>
        public int PG_TconOcWriteDelayMsec { get => PGTconOcWriteDelayMsec; set => PGTconOcWriteDelayMsec = value; }

        /// <summary>
        /// Alias for <see cref="OCType"/> — OC/PreOC/GIB type selector.
        /// <para>Delphi field: OCType : Integer</para>
        /// </summary>
        public int OcType { get => OCType; set => OCType = value; }

        /// <summary>
        /// Current model file name (for DP860 model.file command).
        /// <para>Delphi field: ModelFileName : string (from TModelInfoFLOW, propagated to SystemInfo at runtime)</para>
        /// </summary>
        public string ModelFileName { get; set; } = string.Empty;

        /// <summary>
        /// PG model configuration (resolution and timing) — runtime field loaded from model INI.
        /// <para>Delphi: SystemInfo does not originally hold this; it is copied from TModelInfoPG.PgModelConf
        /// at model-load time for convenient access by CommPG.</para>
        /// </summary>
        public PgModelConfig? PgModelConf { get; set; }

        /// <summary>
        /// PG power data settings — runtime field loaded from model INI (DP860-only).
        /// <para>Delphi: copied from TModelInfoPG.PgPwrData at model-load time.</para>
        /// </summary>
        public PgModelPowerData? PgPwrData { get; set; }

        /// <summary>
        /// PG power sequence configuration — runtime field loaded from model INI (DP860-only).
        /// <para>Delphi: copied from TModelInfoPG.PgPwrSeq at model-load time.</para>
        /// </summary>
        public PgModelPowerSequence? PgPwrSeq { get; set; }

        /// <summary>
        /// Alias for <see cref="PGResetDelayTime"/> — PG reset delay time (ms).
        /// <para>Delphi field: PGResetDelayTime : Integer</para>
        /// </summary>
        public int PgResetDelayTime { get => PGResetDelayTime; set => PGResetDelayTime = value; }

        /// <summary>
        /// Initializes all arrays with proper sizes based on DefCommon constants.
        /// </summary>
        public SystemInfo()
        {
            int chCount = ChannelConstants.MaxCh + 1;

            IPAddr = new string[chCount];
            ProbAddr = new string[chCount];
            ComHandBCR = new int[LimitConstants.MaxBcrCount];
            ComRCB = new int[LimitConstants.MaxSwitchCount];
            ComIonizer = new int[LimitConstants.MaxIonizerCount];
            ModelIonizer = new int[LimitConstants.MaxIonizerCount];
            UseCh = new bool[chCount];
            OffsetCh = new double[chCount];
            PwrVer = new int[chCount];

            // CA410_USE arrays
            ComCa310 = new int[chCount];
            ComCa310DeviceId = new int[chCount];
            ComCa310Serial = new string[chCount];
            ComCaDeviceList = new string[CaConstants.MaxCaDriveCount];

            PGFWVersion = new string[chCount];
            CA410MemoryCh = new string[chCount];
            R2REODSData = new string[chCount];
            R2RMmcTxnIDData = new string[chCount];

            // Initialize string arrays to empty
            for (int i = 0; i < chCount; i++)
            {
                IPAddr[i] = string.Empty;
                ProbAddr[i] = string.Empty;
                ComCa310Serial[i] = string.Empty;
                PGFWVersion[i] = string.Empty;
                CA410MemoryCh[i] = string.Empty;
                R2REODSData[i] = string.Empty;
                R2RMmcTxnIDData[i] = string.Empty;
            }

            for (int i = 0; i < CaConstants.MaxCaDriveCount; i++)
                ComCaDeviceList[i] = string.Empty;
        }
    }

    /// <summary>
    /// PLC (Programmable Logic Controller) configuration.
    /// <para>Original Delphi: TPLCInfo = record (CommonClass.pas line 206)</para>
    /// </summary>
    public class PLCInfo
    {
        /// <summary>
        /// Equipment ID.
        /// <para>Delphi field: EQP_ID : Integer</para>
        /// </summary>
        public int EQPId { get; set; }

        /// <summary>
        /// Station number.
        /// <para>Delphi field: StationNO : Integer</para>
        /// </summary>
        public int StationNo { get; set; }

        /// <summary>
        /// Polling interval (ms).
        /// <para>Delphi field: PollingInterval : Integer</para>
        /// </summary>
        public int PollingInterval { get; set; }

        /// <summary>
        /// Connection timeout (ms).
        /// <para>Delphi field: Timeout_Connection : Integer</para>
        /// </summary>
        public int TimeoutConnection { get; set; }

        /// <summary>
        /// ECS timeout (ms).
        /// <para>Delphi field: Timeout_ECS : Integer</para>
        /// </summary>
        public int TimeoutECS { get; set; }

        /// <summary>
        /// ECS read address.
        /// <para>Delphi field: Address_ECS : string</para>
        /// </summary>
        public string AddressECS { get; set; } = string.Empty;

        /// <summary>
        /// Robot read address.
        /// <para>Delphi field: Address_ROBOT : string</para>
        /// </summary>
        public string AddressRobot { get; set; } = string.Empty;

        /// <summary>
        /// Equipment read address.
        /// <para>Delphi field: Address_EQP : string</para>
        /// </summary>
        public string AddressEQP { get; set; } = string.Empty;

        /// <summary>
        /// ECS write address.
        /// <para>Delphi field: Address_ECS_W : string</para>
        /// </summary>
        public string AddressECSWrite { get; set; } = string.Empty;

        /// <summary>
        /// Robot write address.
        /// <para>Delphi field: Address_ROBOT_W : string</para>
        /// </summary>
        public string AddressRobotWrite { get; set; } = string.Empty;

        /// <summary>
        /// Equipment write address.
        /// <para>Delphi field: Address_EQP_W : string</para>
        /// </summary>
        public string AddressEQPWrite { get; set; } = string.Empty;

        /// <summary>
        /// Computer name.
        /// <para>Delphi field: ComputerName : string</para>
        /// </summary>
        public string ComputerName { get; set; } = string.Empty;

        /// <summary>
        /// Robot 2 read address.
        /// <para>Delphi field: Address_ROBOT2 : string</para>
        /// </summary>
        public string AddressRobot2 { get; set; } = string.Empty;

        /// <summary>
        /// Robot 2 write address.
        /// <para>Delphi field: Address_ROBOT_W2 : string</para>
        /// </summary>
        public string AddressRobotWrite2 { get; set; } = string.Empty;

        /// <summary>
        /// Door open signal address.
        /// <para>Delphi field: Address_DoorOpen : string</para>
        /// </summary>
        public string AddressDoorOpen { get; set; } = string.Empty;

        /// <summary>
        /// Simulation mode enabled.
        /// <para>Delphi field: Use_Simulation : Boolean</para>
        /// </summary>
        public bool UseSimulation { get; set; }

        /// <summary>
        /// Inline GIB mode (different PLC memory layout).
        /// <para>Delphi field: InlineGIB : Boolean</para>
        /// </summary>
        public bool InlineGIB { get; set; }

        /// <summary>Alias for <see cref="InlineGIB"/> — driver compatibility.</summary>
        public bool InlineGib { get => InlineGIB; set => InlineGIB = value; }

        /// <summary>
        /// Zone identifier.
        /// <para>Delphi field: Zone : Integer</para>
        /// </summary>
        public int Zone { get; set; }
    }

    /// <summary>
    /// Simulation mode configuration.
    /// <para>Original Delphi: TSimulateInfo = record (CommonClass.pas line 227)</para>
    /// </summary>
    public class SimulateInfo
    {
        /// <summary>
        /// Use simulated PG.
        /// <para>Delphi field: Use_PG : boolean</para>
        /// </summary>
        public bool UsePG { get; set; }

        /// <summary>
        /// Use simulated DIO.
        /// <para>Delphi field: Use_DIO : boolean</para>
        /// </summary>
        public bool UseDIO { get; set; }

        /// <summary>
        /// Use simulated PLC.
        /// <para>Delphi field: Use_PLC : boolean</para>
        /// </summary>
        public bool UsePLC { get; set; }

        /// <summary>
        /// Use simulated camera.
        /// <para>Delphi field: Use_CAM : boolean</para>
        /// </summary>
        public bool UseCAM { get; set; }

        /// <summary>
        /// PG base port for simulation.
        /// <para>Delphi field: PG_BasePort : integer</para>
        /// </summary>
        public int PGBasePort { get; set; }

        /// <summary>
        /// Camera simulation IP.
        /// <para>Delphi field: CAM_IP : string</para>
        /// </summary>
        public string CAMIP { get; set; } = string.Empty;

        /// <summary>
        /// DIO simulation IP.
        /// <para>Delphi field: DIO_IP : String</para>
        /// </summary>
        public string DIOIP { get; set; } = string.Empty;

        /// <summary>
        /// DIO simulation port.
        /// <para>Delphi field: DIO_PORT : Integer</para>
        /// </summary>
        public int DIOPort { get; set; }

        // ---- Alias properties for driver compatibility ----

        /// <summary>Alias for <see cref="UseDIO"/>.</summary>
        public bool UseDio { get => UseDIO; set => UseDIO = value; }

        /// <summary>Alias for <see cref="DIOIP"/>.</summary>
        public string DioIp { get => DIOIP; set => DIOIP = value; }

        /// <summary>Alias for <see cref="DIOPort"/>.</summary>
        public int DioPort { get => DIOPort; set => DIOPort = value; }
    }

    // NOTE: DfsConfInfo is defined in MesTypes.cs
    // NOTE: OcInfo (Delphi TOcInfo) is defined in InspectionTypes.cs with full CalTarget/CalMemCh arrays
}
