// =============================================================================
// PathConfig.cs
// Converted from Delphi: src_X3584\CommonClass.pas (lines 530-603)
// Contains: TPath
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// Application path configuration for all directories and file paths.
    /// <para>Original Delphi: TPath = record (CommonClass.pas line 530)</para>
    /// </summary>
    public class PathConfig
    {
        // ---- Directory paths ----

        /// <summary>
        /// Root software directory.
        /// <para>Delphi field: RootSW : string</para>
        /// </summary>
        public string RootSW { get; set; } = string.Empty;

        /// <summary>
        /// INI configuration directory.
        /// <para>Delphi field: Ini : string</para>
        /// </summary>
        public string Ini { get; set; } = string.Empty;

        /// <summary>
        /// Image directory (OC or Pre OC layout loading path).
        /// <para>Delphi field: IMAGE : string</para>
        /// </summary>
        public string Image { get; set; } = string.Empty;

        /// <summary>
        /// SPC data directory.
        /// <para>Delphi field: Spc : string</para>
        /// </summary>
        public string Spc { get; set; } = string.Empty;

        /// <summary>
        /// Pattern files directory.
        /// <para>Delphi field: Pattern : string</para>
        /// </summary>
        public string Pattern { get; set; } = string.Empty;

        /// <summary>
        /// Pattern group directory.
        /// <para>Delphi field: PATTERNGROUP : string</para>
        /// </summary>
        public string PatternGroup { get; set; } = string.Empty;

        /// <summary>
        /// BMP files directory.
        /// <para>Delphi field: BMP : string</para>
        /// </summary>
        public string Bmp { get; set; } = string.Empty;

        /// <summary>
        /// Data directory.
        /// <para>Delphi field: DATA : string</para>
        /// </summary>
        public string Data { get; set; } = string.Empty;

        /// <summary>
        /// CB data directory.
        /// <para>Delphi field: CB_DATA : string</para>
        /// </summary>
        public string CbData { get; set; } = string.Empty;

        /// <summary>
        /// Model files directory.
        /// <para>Delphi field: MODEL : string</para>
        /// </summary>
        public string Model { get; set; } = string.Empty;

        /// <summary>
        /// Current model directory.
        /// <para>Delphi field: MODEL_CUR : string</para>
        /// </summary>
        public string ModelCur { get; set; } = string.Empty;

        /// <summary>
        /// Model code directory.
        /// <para>Delphi field: ModelCode : string</para>
        /// </summary>
        public string ModelCode { get; set; } = string.Empty;

        /// <summary>
        /// Log directory.
        /// <para>Delphi field: LOG : string</para>
        /// </summary>
        public string Log { get; set; } = string.Empty;

        /// <summary>
        /// Flash data directory.
        /// <para>Delphi field: FLASH : string</para>
        /// </summary>
        public string Flash { get; set; } = string.Empty;

        /// <summary>
        /// Flash backup directory.
        /// <para>Delphi field: FLASHBackup : string</para>
        /// </summary>
        public string FlashBackup { get; set; } = string.Empty;

        /// <summary>
        /// LGD DLL directory.
        /// <para>Delphi field: LGDDLL : string</para>
        /// </summary>
        public string LgdDll { get; set; } = string.Empty;

        /// <summary>
        /// LGD settings directory.
        /// <para>Delphi field: LGDSet : string</para>
        /// </summary>
        public string LgdSet { get; set; } = string.Empty;

        /// <summary>
        /// LGD parameter directory.
        /// <para>Delphi field: LGDPara : string</para>
        /// </summary>
        public string LgdPara { get; set; } = string.Empty;

        /// <summary>
        /// LGD reprogramming directory.
        /// <para>Delphi field: LGDReProgramming : string</para>
        /// </summary>
        public string LgdReProgramming { get; set; } = string.Empty;

        /// <summary>
        /// LGD log backup directory.
        /// <para>Delphi field: LGD_LOG_BK : string</para>
        /// </summary>
        public string LgdLogBk { get; set; } = string.Empty;

        /// <summary>
        /// LGD log SL directory.
        /// <para>Delphi field: LGD_LOG_SL : string</para>
        /// </summary>
        public string LgdLogSl { get; set; } = string.Empty;

        /// <summary>
        /// LGD log SL backup directory.
        /// <para>Delphi field: LGD_LOG_SL_BK : string</para>
        /// </summary>
        public string LgdLogSlBk { get; set; } = string.Empty;

        /// <summary>
        /// Gamma data directory.
        /// <para>Delphi field: Gamma : string</para>
        /// </summary>
        public string Gamma { get; set; } = string.Empty;

        /// <summary>
        /// CEL data directory.
        /// <para>Delphi field: CEL : string</para>
        /// </summary>
        public string Cel { get; set; } = string.Empty;

        /// <summary>
        /// GMES (Host) directory.
        /// <para>Delphi field: GMES : string</para>
        /// </summary>
        public string Gmes { get; set; } = string.Empty;

        /// <summary>
        /// EAS directory.
        /// <para>Delphi field: EAS : string</para>
        /// </summary>
        public string Eas { get; set; } = string.Empty;

        /// <summary>
        /// R2R directory.
        /// <para>Delphi field: R2R : string</para>
        /// </summary>
        public string R2R { get; set; } = string.Empty;

        /// <summary>
        /// MLOG directory.
        /// <para>Delphi field: MLOG : string</para>
        /// </summary>
        public string MLog { get; set; } = string.Empty;

        /// <summary>
        /// R2R log directory.
        /// <para>Delphi field: R2RLOG : string</para>
        /// </summary>
        public string R2RLog { get; set; } = string.Empty;

        /// <summary>
        /// Debug log directory (2020-09-16 DEBUG_LOG).
        /// <para>Delphi field: DebugLog : string</para>
        /// </summary>
        public string DebugLog { get; set; } = string.Empty;

        /// <summary>
        /// DIO log directory. Added by sam81 2023-04-24.
        /// <para>Delphi field: DIOLog : string</para>
        /// </summary>
        public string DIOLog { get; set; } = string.Empty;

        /// <summary>
        /// PCD log directory.
        /// <para>Delphi field: PCDLog : string</para>
        /// </summary>
        public string PCDLog { get; set; } = string.Empty;

        /// <summary>
        /// Reprogramming log directory.
        /// <para>Delphi field: RePGMLog : string</para>
        /// </summary>
        public string RePGMLog { get; set; } = string.Empty;

        /// <summary>
        /// Shutdown fault log directory.
        /// <para>Delphi field: Shutdown_Fault_Log : string</para>
        /// </summary>
        public string ShutdownFaultLog { get; set; } = string.Empty;

        /// <summary>
        /// HWCID log directory.
        /// <para>Delphi field: HWCIDLog : string</para>
        /// </summary>
        public string HWCIDLog { get; set; } = string.Empty;

        /// <summary>
        /// I Sensing log directory.
        /// <para>Delphi field: Sensing : string</para>
        /// </summary>
        public string Sensing { get; set; } = string.Empty;

        /// <summary>
        /// POCB data directory.
        /// <para>Delphi field: PocbData : string</para>
        /// </summary>
        public string PocbData { get; set; } = string.Empty;

        /// <summary>
        /// Summary CSV directory.
        /// <para>Delphi field: SumCsv : string</para>
        /// </summary>
        public string SumCsv { get; set; } = string.Empty;

        /// <summary>
        /// APDR CSV directory.
        /// <para>Delphi field: ApdrCsv : string</para>
        /// </summary>
        public string ApdrCsv { get; set; } = string.Empty;

        /// <summary>
        /// Touch log directory.
        /// <para>Delphi field: TouchLog : string</para>
        /// </summary>
        public string TouchLog { get; set; } = string.Empty;

        /// <summary>
        /// User calibration log directory.
        /// <para>Delphi field: UserCalLog : string</para>
        /// </summary>
        public string UserCalLog { get; set; } = string.Empty;

        /// <summary>
        /// Power EE directory.
        /// <para>Delphi field: PwrEE : string</para>
        /// </summary>
        public string PwrEE { get; set; } = string.Empty;

        /// <summary>
        /// PG firmware directory.
        /// <para>Delphi field: PG_FW : string</para>
        /// </summary>
        public string PgFw { get; set; } = string.Empty;

        /// <summary>
        /// PG FPGA directory.
        /// <para>Delphi field: PG_FPGA : string</para>
        /// </summary>
        public string PgFpga { get; set; } = string.Empty;

        /// <summary>
        /// Touch firmware directory.
        /// <para>Delphi field: TOUCH_FW : string</para>
        /// </summary>
        public string TouchFw { get; set; } = string.Empty;

        /// <summary>
        /// Interface firmware directory.
        /// <para>Delphi field: IF_FW : string</para>
        /// </summary>
        public string IfFw { get; set; } = string.Empty;

        /// <summary>
        /// Panel firmware directory.
        /// <para>Delphi field: Panel_Fw : string</para>
        /// </summary>
        public string PanelFw { get; set; } = string.Empty;

        /// <summary>
        /// Panel image directory.
        /// <para>Delphi field: PANEL_img : string</para>
        /// </summary>
        public string PanelImg { get; set; } = string.Empty;

        /// <summary>
        /// Panel hex directory.
        /// <para>Delphi field: PANEL_hex : string</para>
        /// </summary>
        public string PanelHex { get; set; } = string.Empty;

        /// <summary>
        /// User calibration directory.
        /// <para>Delphi field: UserCal : string</para>
        /// </summary>
        public string UserCal { get; set; } = string.Empty;

        /// <summary>
        /// Maintenance directory.
        /// <para>Delphi field: Maint : string</para>
        /// </summary>
        public string Maint { get; set; } = string.Empty;

        // ---- File paths ----

        /// <summary>
        /// System info INI file path.
        /// <para>Delphi field: SysInfo : string</para>
        /// </summary>
        public string SysInfo { get; set; } = string.Empty;

        /// <summary>
        /// PG setting INI file path.
        /// <para>Delphi field: PGInfo : string</para>
        /// </summary>
        public string PGInfo { get; set; } = string.Empty;

        /// <summary>
        /// SW version INI file path.
        /// <para>Delphi field: SWVersionInfo : string</para>
        /// </summary>
        public string SWVersionInfo { get; set; } = string.Empty;

        /// <summary>
        /// OC info file path.
        /// <para>Delphi field: OcInfo : string</para>
        /// </summary>
        public string OcInfo { get; set; } = string.Empty;

        /// <summary>
        /// Pattern group file path.
        /// <para>Delphi field: PatGrp : string</para>
        /// </summary>
        public string PatGrp { get; set; } = string.Empty;

        /// <summary>
        /// OTP configuration file path (for RGB Average - OC parameter only pass panel).
        /// <para>Delphi field: OtpCfg : string</para>
        /// </summary>
        public string OtpCfg { get; set; } = string.Empty;

        /// <summary>
        /// Flash prework file path.
        /// <para>Delphi field: FlashPrework : string</para>
        /// </summary>
        public string FlashPrework { get; set; } = string.Empty;

        /// <summary>
        /// Power calibration INI file path.
        /// <para>Delphi field: PowerCali : string</para>
        /// </summary>
        public string PowerCali { get; set; } = string.Empty;

        /// <summary>
        /// Temperature CSV file path.
        /// <para>Delphi field: TempCsv : string</para>
        /// </summary>
        public string TempCsv { get; set; } = string.Empty;

        /// <summary>
        /// Quality code file path.
        /// <para>Delphi field: QualityCode : string</para>
        /// </summary>
        public string QualityCode { get; set; } = string.Empty;

        /// <summary>
        /// Combi code file path.
        /// <para>Delphi field: CombiCode : string</para>
        /// </summary>
        public string CombiCode { get; set; } = string.Empty;

        /// <summary>
        /// Combi backup file path.
        /// <para>Delphi field: CombiBackUp : string</para>
        /// </summary>
        public string CombiBackUp { get; set; } = string.Empty;

        /// <summary>
        /// Local PC DFS log path for DFS DEFECT (default: C:\DEFECT).
        /// <para>Delphi field: DfsDefect : string</para>
        /// </summary>
        public string DfsDefect { get; set; } = string.Empty;

        /// <summary>
        /// Local PC DFS log path for DFS HEX (default: C:\DEFECT\HEX).
        /// <para>Delphi field: DfsHex : string</para>
        /// </summary>
        public string DfsHex { get; set; } = string.Empty;

        /// <summary>
        /// Local PC DFS log path for DFS HEX index (default: C:\DEFECT\HEX_INDEX).
        /// <para>Delphi field: DfsHexIndex : string</para>
        /// </summary>
        public string DfsHexIndex { get; set; } = string.Empty;

        /// <summary>
        /// Local PC DFS log path for DFS SENSE (default: C:\DEFECT\SENSE).
        /// <para>Delphi field: DfsSense : string</para>
        /// </summary>
        public string DfsSense { get; set; } = string.Empty;

        /// <summary>
        /// Local PC DFS log path for DFS SENSE index (default: C:\DEFECT\SENSE_INDEX).
        /// <para>Delphi field: DfsSenseIndex : string</para>
        /// </summary>
        public string DfsSenseIndex { get; set; } = string.Empty;
    }
}
