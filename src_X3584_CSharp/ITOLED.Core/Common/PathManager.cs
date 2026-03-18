// =============================================================================
// PathManager.cs
// Converted from Delphi: src_X3584\CommonClass.pas
//   - TPath record (lines 530-603)
//   - procedure TCommon.InitPath (line 2642)
//   - function  TCommon.GetFilePath (line 2297)
//   - function  TCommon.CheckDir (line 1431)
//   - Path.MODEL_CUR assignment in LoadModelInfo (line 3933)
// Namespace: Dongaeltek.ITOLED.Core.Common
// =============================================================================

using System;
using System.IO;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Core.Common;

/// <summary>
/// Manages all application file and directory paths.
/// Replaces the <c>TPath</c> record and path-related methods from the Delphi
/// <c>TCommon</c> class in CommonClass.pas.
/// <para>
/// Usage: Call <see cref="InitializePaths"/> once at application startup
/// (equivalent to Delphi <c>TCommon.InitPath</c>). Then use properties
/// to obtain specific directory or file paths.
/// </para>
/// </summary>
public class PathManager : IPathManager
{
    // =========================================================================
    // Private state
    // =========================================================================

    private bool _initialized;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a PathManager using the specified root directory.
    /// </summary>
    /// <param name="rootDirectory">
    /// The application root directory. In production this is typically
    /// <c>AppContext.BaseDirectory</c> (equivalent to Delphi
    /// <c>ExtractFilePath(Application.ExeName)</c>).
    /// </param>
    public PathManager(string rootDirectory)
    {
        if (string.IsNullOrWhiteSpace(rootDirectory))
            throw new ArgumentException("Root directory must not be null or empty.", nameof(rootDirectory));

        // Normalize: ensure trailing separator
        RootDir = rootDirectory.EndsWith(Path.DirectorySeparatorChar)
            ? rootDirectory
            : rootDirectory + Path.DirectorySeparatorChar;
    }

    /// <summary>
    /// Creates a PathManager using <c>AppContext.BaseDirectory</c> as root.
    /// </summary>
    public PathManager()
        : this(AppContext.BaseDirectory)
    {
    }

    // =========================================================================
    // Root and INI Directories
    //   Delphi: TPath.RootSW, TPath.Ini
    // =========================================================================

    /// <inheritdoc />
    public string RootDir { get; private set; }

    /// <inheritdoc />
    public string IniDir { get; private set; } = string.Empty;

    // =========================================================================
    // Pattern Directories
    //   Delphi: TPath.PATTERN, TPath.PATTERNGROUP, TPath.BMP
    // =========================================================================

    /// <inheritdoc />
    public string PatternDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string PatternGroupDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string BmpDir { get; private set; } = string.Empty;

    // =========================================================================
    // Image and Model Directories
    //   Delphi: TPath.IMAGE, TPath.MODEL, TPath.MODEL_CUR
    // =========================================================================

    /// <inheritdoc />
    public string ImageDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string ModelRootDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string ModelCurrentDir { get; private set; } = string.Empty;

    // =========================================================================
    // Data Directories
    //   Delphi: TPath.DATA, TPath.PG_FW, TPath.PG_FPGA
    // =========================================================================

    /// <inheritdoc />
    public string DataDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string PgFirmwareDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string PgFpgaDir { get; private set; } = string.Empty;

    // =========================================================================
    // Log Directories
    //   Delphi: TPath.LOG, FLASH, FLASHBackup, GMES, EAS, R2R, R2RLOG,
    //           MLOG, DebugLog, DIOLog, CEL, TempCsv, RePGMLog,
    //           Shutdown_Fault_Log, SumCsv, ApdrCsv, HWCIDLog, Gamma
    // =========================================================================

    /// <inheritdoc />
    public string LogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string FlashDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string FlashBackupDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string MesLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string EasLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string R2RDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string R2RLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string MLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string DebugLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string DioLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string CelLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string TempCsvDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string ReProgrammingLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string ShutdownFaultLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string SummaryCsvDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string ApdrCsvDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string HwcidLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string GammaLogDir { get; private set; } = string.Empty;

    // =========================================================================
    // LGD Directories
    //   Delphi: TPath.LGDDLL, LGDSet, LGDPara, LGDReProgramming,
    //           LGD_LOG_BK, LGD_LOG_SL, LGD_LOG_SL_BK
    // =========================================================================

    /// <inheritdoc />
    public string LgdDllDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string LgdSettingDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string LgdParameterDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string LgdReProgrammingDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string LgdLogBackupDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string LgdSummaryLogDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string LgdSummaryLogBackupDir { get; private set; } = string.Empty;

    // =========================================================================
    // Maintenance and Flash-prework
    //   Delphi: TPath.Maint, TPath.FlashPrework
    // =========================================================================

    /// <inheritdoc />
    public string MaintenanceDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string FlashPreworkDir { get; private set; } = string.Empty;

    // =========================================================================
    // User Calibration (Delphi CA410_USE)
    //   Delphi: TPath.UserCal, TPath.UserCalLog
    // =========================================================================

    /// <inheritdoc />
    public string UserCalDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string UserCalLogDir { get; private set; } = string.Empty;

    // =========================================================================
    // DFS Directories (Delphi DFS_HEX / USE_DFS)
    //   Delphi: TPath.QualityCode, CombiCode, CombiBackUp,
    //           DfsDefect, DfsHex, DfsHexIndex
    // =========================================================================

    /// <inheritdoc />
    public string QualityCodeDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string CombiCodeDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string CombiBackupDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string DfsDefectDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string DfsHexDir { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string DfsHexIndexDir { get; private set; } = string.Empty;

    // =========================================================================
    // Configuration File Paths
    //   Delphi: TPath.SysInfo, PGInfo, SWVersionInfo, OcInfo, PowerCali
    // =========================================================================

    /// <inheritdoc />
    public string SystemConfigPath { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string PgSettingPath { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string SwVersionInfoPath { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string OpticConfigPath { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string PowerCalibrationFileName { get; private set; } = "PowerCalibration.ini";

    // =========================================================================
    // InitializePaths — Delphi: procedure TCommon.InitPath (line 2642)
    // =========================================================================

    /// <inheritdoc />
    public void InitializePaths()
    {
        // -----------------------------------------------------------------
        // Build all directory paths relative to RootDir
        //   Mirrors the Delphi InitPath line-by-line (lines 2643-2751)
        // -----------------------------------------------------------------

        // INI directory
        IniDir              = Path.Combine(RootDir, "INI") + Path.DirectorySeparatorChar;
        FlashPreworkDir     = Path.Combine(IniDir, "FlashPrework") + Path.DirectorySeparatorChar;

        // Pattern directories
        PatternDir          = Path.Combine(RootDir, "pattern") + Path.DirectorySeparatorChar;
        PatternGroupDir     = Path.Combine(PatternDir, "group") + Path.DirectorySeparatorChar;
        BmpDir              = Path.Combine(PatternDir, "bmp") + Path.DirectorySeparatorChar;

        // Model directories
        ModelRootDir        = Path.Combine(RootDir, "MODEL") + Path.DirectorySeparatorChar;

        // Log directories
        LogDir              = Path.Combine(RootDir, "LOG") + Path.DirectorySeparatorChar;
        FlashDir            = Path.Combine(LogDir, "FLASH") + Path.DirectorySeparatorChar;
        FlashBackupDir      = Path.Combine(FlashDir, "BackUp") + Path.DirectorySeparatorChar;
        ImageDir            = Path.Combine(RootDir, "image") + Path.DirectorySeparatorChar;
        MLogDir             = Path.Combine(LogDir, "MLog") + Path.DirectorySeparatorChar;
        DebugLogDir         = Path.Combine(LogDir, "DebugLog") + Path.DirectorySeparatorChar;
        DioLogDir           = Path.Combine(LogDir, "CommDIO") + Path.DirectorySeparatorChar;
        MesLogDir           = Path.Combine(LogDir, "Mes") + Path.DirectorySeparatorChar;
        EasLogDir           = Path.Combine(LogDir, "Eas") + Path.DirectorySeparatorChar;
        R2RDir              = Path.Combine(LogDir, "R2R") + Path.DirectorySeparatorChar;
        TempCsvDir          = Path.Combine(LogDir, "TempCsv") + Path.DirectorySeparatorChar;
        ReProgrammingLogDir = Path.Combine(LogDir, "ReProgrammingLOG") + Path.DirectorySeparatorChar;
        CelLogDir           = Path.Combine(LogDir, "CEL") + Path.DirectorySeparatorChar;
        ShutdownFaultLogDir = Path.Combine(LogDir, "Shutdown_FaultLOG") + Path.DirectorySeparatorChar;
        R2RLogDir           = Path.Combine(LogDir, "R2RLOG") + Path.DirectorySeparatorChar;
        SummaryCsvDir       = Path.Combine(LogDir, "SummaryCsv") + Path.DirectorySeparatorChar;
        ApdrCsvDir          = Path.Combine(LogDir, "ApdrCsv") + Path.DirectorySeparatorChar;
        HwcidLogDir         = Path.Combine(LogDir, "HWCIDLog") + Path.DirectorySeparatorChar;
        GammaLogDir         = Path.Combine(LogDir, "Gamma") + Path.DirectorySeparatorChar;

        // Data directories
        DataDir             = Path.Combine(RootDir, "DATA") + Path.DirectorySeparatorChar;
        PgFirmwareDir       = Path.Combine(DataDir, "PG_FW") + Path.DirectorySeparatorChar;
        PgFpgaDir           = Path.Combine(DataDir, "PG_FPGA") + Path.DirectorySeparatorChar;

        // Maintenance
        MaintenanceDir      = Path.Combine(RootDir, "MAINT") + Path.DirectorySeparatorChar;

        // LGD directories
        LgdDllDir               = Path.Combine(RootDir, "LGDDLL") + Path.DirectorySeparatorChar;
        LgdSettingDir           = Path.Combine(LgdDllDir, "Setting", "OCSet") + Path.DirectorySeparatorChar;
        LgdReProgrammingDir     = Path.Combine(LgdDllDir, "ReProgramming") + Path.DirectorySeparatorChar;
        LgdParameterDir         = Path.Combine(LgdDllDir, "Setting", "Parameters") + Path.DirectorySeparatorChar;
        LgdLogBackupDir         = Path.Combine(LgdDllDir, "_bk") + Path.DirectorySeparatorChar;
        LgdSummaryLogDir        = Path.Combine(LgdDllDir, "OCLog", "SummaryLog") + Path.DirectorySeparatorChar;
        LgdSummaryLogBackupDir  = Path.Combine(LgdDllDir, "OCLog", "SummaryLog", "_BK") + Path.DirectorySeparatorChar;

        // -----------------------------------------------------------------
        // CA410_USE block (always enabled for OC/PreOC variants)
        //   Delphi: {$IFDEF CA410_USE} (Common.inc lines 18, 43)
        // -----------------------------------------------------------------
        UserCalDir      = Path.Combine(RootDir, "USER_CAL") + Path.DirectorySeparatorChar;
        UserCalLogDir   = Path.Combine(UserCalDir, "User_Cal_Log") + Path.DirectorySeparatorChar;
        OpticConfigPath = Path.Combine(IniDir, "OpticConfig.ini");

        // -----------------------------------------------------------------
        // Configuration file paths
        //   Delphi: lines 2688-2694
        // -----------------------------------------------------------------
        SystemConfigPath        = Path.Combine(IniDir, "SysTemConfig.ini");
        PgSettingPath           = Path.Combine(IniDir, "PGSetting.ini");
        SwVersionInfoPath       = Path.Combine(IniDir, "SW Version 관리.ini");
        PowerCalibrationFileName = "PowerCalibration.ini";

        // -----------------------------------------------------------------
        // Create all required directories
        //   Delphi: CheckDir calls (lines 2696-2725)
        // -----------------------------------------------------------------
        EnsureDirectory(IniDir);
        EnsureDirectory(FlashPreworkDir);
        EnsureDirectory(PatternDir);
        EnsureDirectory(PatternGroupDir);
        EnsureDirectory(BmpDir);
        EnsureDirectory(ImageDir);
        EnsureDirectory(ModelRootDir);
        EnsureDirectory(LogDir);
        EnsureDirectory(CelLogDir);
        EnsureDirectory(MesLogDir);
        EnsureDirectory(EasLogDir);
        EnsureDirectory(R2RDir);
        EnsureDirectory(R2RLogDir);
        EnsureDirectory(DataDir);
        EnsureDirectory(PgFirmwareDir);
        EnsureDirectory(PgFpgaDir);
        EnsureDirectory(FlashDir);
        EnsureDirectory(FlashBackupDir);
        EnsureDirectory(MaintenanceDir);
        EnsureDirectory(MLogDir);
        EnsureDirectory(DebugLogDir);
        EnsureDirectory(DioLogDir);
        EnsureDirectory(SummaryCsvDir);
        EnsureDirectory(ApdrCsvDir);
        EnsureDirectory(LgdDllDir);
        EnsureDirectory(LgdReProgrammingDir);
        EnsureDirectory(ShutdownFaultLogDir);
        EnsureDirectory(GammaLogDir);
        EnsureDirectory(TempCsvDir);
        EnsureDirectory(ReProgrammingLogDir);
        EnsureDirectory(HwcidLogDir);
        EnsureDirectory(LgdLogBackupDir);
        EnsureDirectory(LgdSummaryLogDir);
        EnsureDirectory(LgdSummaryLogBackupDir);
        EnsureDirectory(UserCalDir);
        EnsureDirectory(UserCalLogDir);

        // -----------------------------------------------------------------
        // DFS_HEX block (enabled when USE_DFS is defined, which is true
        // for both IITOLED_OC and ITOLED_PreOC via Common.inc lines 34, 61)
        //   Delphi: {$IFDEF DFS_HEX} (lines 2737-2751)
        // -----------------------------------------------------------------
        QualityCodeDir  = Path.Combine(RootDir, "Quality Code") + Path.DirectorySeparatorChar;
        CombiCodeDir    = Path.Combine(QualityCodeDir, "Combi Code") + Path.DirectorySeparatorChar;
        CombiBackupDir  = Path.Combine(QualityCodeDir, "Backup") + Path.DirectorySeparatorChar;
        DfsDefectDir    = @"C:\DEFECT\";
        DfsHexDir       = Path.Combine(DfsDefectDir, "HEX") + Path.DirectorySeparatorChar;
        DfsHexIndexDir  = Path.Combine(DfsDefectDir, "HEX_INDEX") + Path.DirectorySeparatorChar;

        EnsureDirectory(QualityCodeDir);
        EnsureDirectory(CombiCodeDir);
        EnsureDirectory(CombiBackupDir);
        EnsureDirectory(DfsDefectDir);
        EnsureDirectory(DfsHexDir);
        EnsureDirectory(DfsHexIndexDir);

        _initialized = true;
    }

    // =========================================================================
    // SetCurrentModel — Delphi: Path.MODEL_CUR := Path.MODEL + fName + '\'
    //   Called from LoadModelInfo (line 3933), SaveModelInfo (line 6645),
    //   and SaveModelInfoAll (line 6847).
    // =========================================================================

    /// <inheritdoc />
    public void SetCurrentModel(string modelName)
    {
        ThrowIfNotInitialized();

        if (string.IsNullOrWhiteSpace(modelName))
            throw new ArgumentException("Model name must not be null or empty.", nameof(modelName));

        ModelCurrentDir = Path.Combine(ModelRootDir, modelName) + Path.DirectorySeparatorChar;
        EnsureDirectory(ModelCurrentDir);
    }

    // =========================================================================
    // GetFilePath — Delphi: function TCommon.GetFilePath (line 2297)
    //
    //   case Path of
    //     MODEL_PATH       : Result := Path.MODEL_CUR + FName + '.mcf';
    //     PATRN_PATH       : Result := Path.PATTERN   + FName + '.pat';
    //     PATGR_PATH       : Result := Path.PATTERNGROUP + FName + '.grp';
    //     SCRIPT_PATH_ISU  : Result := Path.MODEL_CUR + FName + '.isu';
    //     SCRIPT_PATH_PSU  : Result := Path.MODEL_CUR + FName + '.psu';
    //   else
    //     Result := FName;
    //   end;
    // =========================================================================

    /// <inheritdoc />
    public string GetFilePath(string fileName, int pathIndex)
    {
        ThrowIfNotInitialized();

        return pathIndex switch
        {
            PathIndex.Model        => Path.Combine(ModelCurrentDir, fileName + ".mcf"),
            PathIndex.Pattern      => Path.Combine(PatternDir, fileName + ".pat"),
            PathIndex.PatternGroup => Path.Combine(PatternGroupDir, fileName + ".grp"),
            PathIndex.ScriptIsu    => Path.Combine(ModelCurrentDir, fileName + ".isu"),
            PathIndex.ScriptPsu    => Path.Combine(ModelCurrentDir, fileName + ".psu"),
            PathIndex.ScriptCsx    => Path.Combine(ModelCurrentDir, fileName + ".csx"),
            _                      => fileName  // Delphi: else Result := FName
        };
    }

    // =========================================================================
    // Resolve — utility to combine a relative path with the root directory
    // =========================================================================

    /// <inheritdoc />
    public string Resolve(string relativePath)
    {
        if (string.IsNullOrEmpty(relativePath))
            return RootDir;

        return Path.Combine(RootDir, relativePath);
    }

    // =========================================================================
    // EnsureDirectory — Delphi: function TCommon.CheckDir (line 1431)
    //
    //   Original returns True on FAILURE (cannot create), False on success.
    //   C# version throws IOException on failure instead of returning a boolean,
    //   which is more idiomatic for .NET error handling.
    // =========================================================================

    /// <inheritdoc />
    public void EnsureDirectory(string directoryPath)
    {
        if (string.IsNullOrWhiteSpace(directoryPath))
            return;

        if (!Directory.Exists(directoryPath))
        {
            try
            {
                Directory.CreateDirectory(directoryPath);
            }
            catch (Exception ex)
            {
                // Delphi original: MessageDlg('Cannot make the Path(' + sPath + ')!!!', ...)
                throw new IOException(
                    $"Cannot create directory '{directoryPath}'. " +
                    $"Original Delphi error: 'Cannot make the Path({directoryPath})!!!'",
                    ex);
            }
        }
    }

    // =========================================================================
    // Helper: GetLogDir / GetChannelLogDir
    //   These provide date-based sub-directory resolution under LogDir,
    //   useful for inspection result logs organized by date/channel.
    // =========================================================================

    /// <summary>
    /// Returns a date-based log subdirectory (LogDir\yyyyMM\).
    /// </summary>
    /// <param name="date">The date used to construct the subdirectory name.</param>
    /// <returns>Full path to the date-based log directory.</returns>
    public string GetLogDir(DateTime date)
    {
        ThrowIfNotInitialized();
        return Path.Combine(LogDir, date.ToString("yyyyMM")) + Path.DirectorySeparatorChar;
    }

    /// <summary>
    /// Returns a channel-specific, date-based log subdirectory (LogDir\yyyyMM\CH{channel}\).
    /// </summary>
    /// <param name="channel">Zero-based channel index.</param>
    /// <param name="date">The date used to construct the subdirectory name.</param>
    /// <returns>Full path to the channel log directory.</returns>
    public string GetChannelLogDir(int channel, DateTime date)
    {
        ThrowIfNotInitialized();
        var dateDir = GetLogDir(date);
        return Path.Combine(dateDir, $"CH{channel}") + Path.DirectorySeparatorChar;
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    private void ThrowIfNotInitialized()
    {
        if (!_initialized)
        {
            throw new InvalidOperationException(
                "PathManager has not been initialized. Call InitializePaths() first.");
        }
    }
}
