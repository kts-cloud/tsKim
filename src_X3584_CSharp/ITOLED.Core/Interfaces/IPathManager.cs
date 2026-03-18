// =============================================================================
// IPathManager.cs
// Converted from Delphi: src_X3584\CommonClass.pas — TPath record (lines 530-603)
//                         and path-related methods: InitPath, GetFilePath, CheckDir
// Namespace: Dongaeltek.ITOLED.Core.Interfaces
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Centralizes all file/directory path resolution originally scattered
/// across CommonClass.pas TCommon (TPath record, InitPath, GetFilePath, CheckDir).
/// <para>Delphi origin: TPath = record (CommonClass.pas lines 530-603)</para>
/// </summary>
public interface IPathManager
{
    // =========================================================================
    // Root and INI Directories
    // =========================================================================

    /// <summary>
    /// Application root directory.
    /// <para>Delphi origin: TPath.RootSW — ExtractFilePath(Application.ExeName)</para>
    /// </summary>
    string RootDir { get; }

    /// <summary>
    /// INI configuration directory (RootDir\INI\).
    /// <para>Delphi origin: TPath.Ini</para>
    /// </summary>
    string IniDir { get; }

    // =========================================================================
    // Pattern Directories
    // =========================================================================

    /// <summary>
    /// Pattern files directory (RootDir\pattern\).
    /// <para>Delphi origin: TPath.PATTERN</para>
    /// </summary>
    string PatternDir { get; }

    /// <summary>
    /// Pattern group directory (PatternDir\group\).
    /// <para>Delphi origin: TPath.PATTERNGROUP</para>
    /// </summary>
    string PatternGroupDir { get; }

    /// <summary>
    /// BMP pattern images directory (PatternDir\bmp\).
    /// <para>Delphi origin: TPath.BMP</para>
    /// </summary>
    string BmpDir { get; }

    // =========================================================================
    // Image and Model Directories
    // =========================================================================

    /// <summary>
    /// OC/PreOC layout image directory (RootDir\image\).
    /// <para>Delphi origin: TPath.IMAGE</para>
    /// </summary>
    string ImageDir { get; }

    /// <summary>
    /// Model root directory (RootDir\MODEL\).
    /// <para>Delphi origin: TPath.MODEL</para>
    /// </summary>
    string ModelRootDir { get; }

    /// <summary>
    /// Current model directory. Set dynamically when a model is loaded.
    /// <para>Delphi origin: TPath.MODEL_CUR — set by LoadModelInfo(fName)</para>
    /// </summary>
    string ModelCurrentDir { get; }

    // =========================================================================
    // Data Directories
    // =========================================================================

    /// <summary>
    /// Data root directory (RootDir\DATA\).
    /// <para>Delphi origin: TPath.DATA</para>
    /// </summary>
    string DataDir { get; }

    /// <summary>
    /// PG firmware directory (DataDir\PG_FW\).
    /// <para>Delphi origin: TPath.PG_FW</para>
    /// </summary>
    string PgFirmwareDir { get; }

    /// <summary>
    /// PG FPGA directory (DataDir\PG_FPGA\).
    /// <para>Delphi origin: TPath.PG_FPGA</para>
    /// </summary>
    string PgFpgaDir { get; }

    // =========================================================================
    // Log Directories
    // =========================================================================

    /// <summary>
    /// Log root directory (RootDir\LOG\).
    /// <para>Delphi origin: TPath.LOG</para>
    /// </summary>
    string LogDir { get; }

    /// <summary>
    /// Flash log directory (LogDir\FLASH\).
    /// <para>Delphi origin: TPath.FLASH</para>
    /// </summary>
    string FlashDir { get; }

    /// <summary>
    /// Flash backup directory (FlashDir\BackUp\).
    /// <para>Delphi origin: TPath.FLASHBackup</para>
    /// </summary>
    string FlashBackupDir { get; }

    /// <summary>
    /// MES log directory (LogDir\Mes\).
    /// <para>Delphi origin: TPath.GMES</para>
    /// </summary>
    string MesLogDir { get; }

    /// <summary>
    /// EAS log directory (LogDir\Eas\).
    /// <para>Delphi origin: TPath.EAS</para>
    /// </summary>
    string EasLogDir { get; }

    /// <summary>
    /// R2R log directory (LogDir\R2R\).
    /// <para>Delphi origin: TPath.R2R</para>
    /// </summary>
    string R2RDir { get; }

    /// <summary>
    /// R2R log backup directory (LogDir\R2RLOG\).
    /// <para>Delphi origin: TPath.R2RLOG</para>
    /// </summary>
    string R2RLogDir { get; }

    /// <summary>
    /// MLog directory (LogDir\MLog\).
    /// <para>Delphi origin: TPath.MLOG</para>
    /// </summary>
    string MLogDir { get; }

    /// <summary>
    /// Debug log directory (LogDir\DebugLog\).
    /// <para>Delphi origin: TPath.DebugLog</para>
    /// </summary>
    string DebugLogDir { get; }

    /// <summary>
    /// DIO communication log directory (LogDir\CommDIO\).
    /// <para>Delphi origin: TPath.DIOLog</para>
    /// </summary>
    string DioLogDir { get; }

    /// <summary>
    /// CEL log directory (LogDir\CEL\).
    /// <para>Delphi origin: TPath.CEL</para>
    /// </summary>
    string CelLogDir { get; }

    /// <summary>
    /// Temperature CSV log directory (LogDir\TempCsv\).
    /// <para>Delphi origin: TPath.TempCsv</para>
    /// </summary>
    string TempCsvDir { get; }

    /// <summary>
    /// Re-programming log directory (LogDir\ReProgrammingLOG\).
    /// <para>Delphi origin: TPath.RePGMLog</para>
    /// </summary>
    string ReProgrammingLogDir { get; }

    /// <summary>
    /// Shutdown fault log directory (LogDir\Shutdown_FaultLOG\).
    /// <para>Delphi origin: TPath.Shutdown_Fault_Log</para>
    /// </summary>
    string ShutdownFaultLogDir { get; }

    /// <summary>
    /// Summary CSV log directory (LogDir\SummaryCsv\).
    /// <para>Delphi origin: TPath.SumCsv</para>
    /// </summary>
    string SummaryCsvDir { get; }

    /// <summary>
    /// APDR CSV log directory (LogDir\ApdrCsv\).
    /// <para>Delphi origin: TPath.ApdrCsv</para>
    /// </summary>
    string ApdrCsvDir { get; }

    /// <summary>
    /// HWCID log directory (LogDir\HWCIDLog\).
    /// <para>Delphi origin: TPath.HWCIDLog</para>
    /// </summary>
    string HwcidLogDir { get; }

    /// <summary>
    /// Gamma log directory (LogDir\Gamma\).
    /// <para>Delphi origin: TPath.Gamma</para>
    /// </summary>
    string GammaLogDir { get; }

    // =========================================================================
    // LGD Directories
    // =========================================================================

    /// <summary>
    /// LGD DLL directory (RootDir\LGDDLL\).
    /// <para>Delphi origin: TPath.LGDDLL</para>
    /// </summary>
    string LgdDllDir { get; }

    /// <summary>
    /// LGD OCSet setting directory (LgdDllDir\Setting\OCSet\).
    /// <para>Delphi origin: TPath.LGDSet</para>
    /// </summary>
    string LgdSettingDir { get; }

    /// <summary>
    /// LGD parameter directory (LgdDllDir\Setting\Parameters\).
    /// <para>Delphi origin: TPath.LGDPara</para>
    /// </summary>
    string LgdParameterDir { get; }

    /// <summary>
    /// LGD re-programming directory (LgdDllDir\ReProgramming\).
    /// <para>Delphi origin: TPath.LGDReProgramming</para>
    /// </summary>
    string LgdReProgrammingDir { get; }

    /// <summary>
    /// LGD log backup directory (LgdDllDir\_bk\).
    /// <para>Delphi origin: TPath.LGD_LOG_BK</para>
    /// </summary>
    string LgdLogBackupDir { get; }

    /// <summary>
    /// LGD OC summary log directory (LgdDllDir\OCLog\SummaryLog\).
    /// <para>Delphi origin: TPath.LGD_LOG_SL</para>
    /// </summary>
    string LgdSummaryLogDir { get; }

    /// <summary>
    /// LGD OC summary log backup directory (LgdDllDir\OCLog\SummaryLog\_BK\).
    /// <para>Delphi origin: TPath.LGD_LOG_SL_BK</para>
    /// </summary>
    string LgdSummaryLogBackupDir { get; }

    // =========================================================================
    // Maintenance and Flash-prework
    // =========================================================================

    /// <summary>
    /// Maintenance directory (RootDir\MAINT\).
    /// <para>Delphi origin: TPath.Maint</para>
    /// </summary>
    string MaintenanceDir { get; }

    /// <summary>
    /// Flash prework INI sub-directory (IniDir\FlashPrework\).
    /// <para>Delphi origin: TPath.FlashPrework</para>
    /// </summary>
    string FlashPreworkDir { get; }

    // =========================================================================
    // User Calibration (CA410_USE)
    // =========================================================================

    /// <summary>
    /// User calibration directory (RootDir\USER_CAL\).
    /// <para>Delphi origin: TPath.UserCal (CA410_USE)</para>
    /// </summary>
    string UserCalDir { get; }

    /// <summary>
    /// User calibration log directory (UserCalDir\User_Cal_Log\).
    /// <para>Delphi origin: TPath.UserCalLog (CA410_USE)</para>
    /// </summary>
    string UserCalLogDir { get; }

    // =========================================================================
    // DFS Directories (USE_DFS / DFS_HEX)
    // =========================================================================

    /// <summary>
    /// Quality code directory (RootDir\Quality Code\).
    /// <para>Delphi origin: TPath.QualityCode (DFS_HEX)</para>
    /// </summary>
    string QualityCodeDir { get; }

    /// <summary>
    /// Combi code directory (QualityCodeDir\Combi Code\).
    /// <para>Delphi origin: TPath.CombiCode (DFS_HEX)</para>
    /// </summary>
    string CombiCodeDir { get; }

    /// <summary>
    /// Combi backup directory (QualityCodeDir\Backup\).
    /// <para>Delphi origin: TPath.CombiBackUp (DFS_HEX)</para>
    /// </summary>
    string CombiBackupDir { get; }

    /// <summary>
    /// DFS defect directory (default: C:\DEFECT\).
    /// <para>Delphi origin: TPath.DfsDefect (DFS_HEX)</para>
    /// </summary>
    string DfsDefectDir { get; }

    /// <summary>
    /// DFS HEX directory (DfsDefectDir\HEX\).
    /// <para>Delphi origin: TPath.DfsHex (DFS_HEX)</para>
    /// </summary>
    string DfsHexDir { get; }

    /// <summary>
    /// DFS HEX index directory (DfsDefectDir\HEX_INDEX\).
    /// <para>Delphi origin: TPath.DfsHexIndex (DFS_HEX)</para>
    /// </summary>
    string DfsHexIndexDir { get; }

    // =========================================================================
    // Configuration File Paths (files, not directories)
    // =========================================================================

    /// <summary>
    /// System configuration file path (IniDir\SysTemConfig.ini).
    /// <para>Delphi origin: TPath.SysInfo</para>
    /// </summary>
    string SystemConfigPath { get; }

    /// <summary>
    /// PG setting file path (IniDir\PGSetting.ini).
    /// <para>Delphi origin: TPath.PGInfo</para>
    /// </summary>
    string PgSettingPath { get; }

    /// <summary>
    /// SW version info file path (IniDir\SW Version management.ini).
    /// <para>Delphi origin: TPath.SWVersionInfo</para>
    /// </summary>
    string SwVersionInfoPath { get; }

    /// <summary>
    /// Optic configuration file path (IniDir\OpticConfig.ini).
    /// <para>Delphi origin: TPath.OcInfo (CA410_USE)</para>
    /// </summary>
    string OpticConfigPath { get; }

    /// <summary>
    /// Power calibration INI filename (relative; "PowerCalibration.ini").
    /// <para>Delphi origin: TPath.PowerCali</para>
    /// </summary>
    string PowerCalibrationFileName { get; }

    // =========================================================================
    // Methods
    // =========================================================================

    /// <summary>
    /// Initializes all path properties based on the application root directory,
    /// creating all required directories.
    /// <para>Delphi origin: procedure TCommon.InitPath (CommonClass.pas line 2642)</para>
    /// </summary>
    void InitializePaths();

    /// <summary>
    /// Sets the current model directory based on the model name.
    /// <para>Delphi origin: Path.MODEL_CUR := Path.MODEL + fName + '\' (CommonClass.pas line 3933)</para>
    /// </summary>
    /// <param name="modelName">The model name (used as sub-directory under ModelRootDir).</param>
    void SetCurrentModel(string modelName);

    /// <summary>
    /// Constructs a fully-qualified file path for a given filename and path type index.
    /// <para>Delphi origin: function TCommon.GetFilePath (CommonClass.pas line 2297)</para>
    /// </summary>
    /// <param name="fileName">The base file name (without extension).</param>
    /// <param name="pathIndex">Path type index (use <c>PathIndex</c> constants from DefCommon.cs).</param>
    /// <returns>Full file path with appropriate extension (.mcf, .pat, .grp, .isu, .psu, .csx).</returns>
    string GetFilePath(string fileName, int pathIndex);

    /// <summary>
    /// Returns a date-based log subdirectory (LogDir\yyyyMM\).
    /// </summary>
    /// <param name="date">The date used to construct the subdirectory name.</param>
    /// <returns>Full path to the date-based log directory.</returns>
    string GetLogDir(DateTime date);

    /// <summary>
    /// Returns a channel-specific, date-based log subdirectory (LogDir\yyyyMM\CH{channel}\).
    /// </summary>
    /// <param name="channel">Zero-based channel index.</param>
    /// <param name="date">The date used to construct the subdirectory name.</param>
    /// <returns>Full path to the channel log directory.</returns>
    string GetChannelLogDir(int channel, DateTime date);

    /// <summary>
    /// Resolves a relative path against the application root directory.
    /// </summary>
    /// <param name="relativePath">A path relative to <see cref="RootDir"/>.</param>
    /// <returns>The absolute path.</returns>
    string Resolve(string relativePath);

    /// <summary>
    /// Ensures the specified directory exists, creating it if necessary.
    /// <para>Delphi origin: function TCommon.CheckDir (CommonClass.pas line 1431)</para>
    /// </summary>
    /// <param name="directoryPath">The directory path to check/create.</param>
    /// <exception cref="System.IO.IOException">If the directory cannot be created.</exception>
    void EnsureDirectory(string directoryPath);
}
