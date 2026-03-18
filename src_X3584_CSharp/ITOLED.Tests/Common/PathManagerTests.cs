// =============================================================================
// PathManagerTests.cs — Tests for IPathManager implementation
// =============================================================================

using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.Common;

public class PathManagerTests : IDisposable
{
    private readonly string _tempRoot;
    private readonly PathManager _pm;

    public PathManagerTests()
    {
        _tempRoot = Path.Combine(Path.GetTempPath(), "ITOLED_PM_" + Guid.NewGuid().ToString("N")[..8]);
        Directory.CreateDirectory(_tempRoot);
        _pm = new PathManager(_tempRoot);
        _pm.InitializePaths();
    }

    public void Dispose()
    {
        try { Directory.Delete(_tempRoot, recursive: true); }
        catch { /* ignore cleanup errors */ }
    }

    // ── Root/INI ─────────────────────────────────────────────

    [Fact]
    public void RootDir_EndsWithSeparator()
    {
        Assert.EndsWith(Path.DirectorySeparatorChar.ToString(), _pm.RootDir);
    }

    [Fact]
    public void IniDir_IsSubOfRoot()
    {
        Assert.StartsWith(_pm.RootDir, _pm.IniDir);
        Assert.Contains("INI", _pm.IniDir);
    }

    // ── Pattern directories ──────────────────────────────────

    [Fact]
    public void PatternDir_Structure()
    {
        Assert.Contains("pattern", _pm.PatternDir);
        Assert.Contains("group", _pm.PatternGroupDir);
        Assert.Contains("bmp", _pm.BmpDir);
    }

    // ── Log directories created ──────────────────────────────

    [Fact]
    public void InitializePaths_CreatesLogDirectories()
    {
        Assert.True(Directory.Exists(_pm.LogDir));
        Assert.True(Directory.Exists(_pm.FlashDir));
        Assert.True(Directory.Exists(_pm.FlashBackupDir));
        Assert.True(Directory.Exists(_pm.MesLogDir));
        Assert.True(Directory.Exists(_pm.EasLogDir));
        Assert.True(Directory.Exists(_pm.MLogDir));
        Assert.True(Directory.Exists(_pm.DebugLogDir));
        Assert.True(Directory.Exists(_pm.DioLogDir));
        Assert.True(Directory.Exists(_pm.CelLogDir));
        Assert.True(Directory.Exists(_pm.SummaryCsvDir));
        Assert.True(Directory.Exists(_pm.ApdrCsvDir));
        Assert.True(Directory.Exists(_pm.GammaLogDir));
        Assert.True(Directory.Exists(_pm.TempCsvDir));
    }

    // ── Config file paths ────────────────────────────────────

    [Fact]
    public void SystemConfigPath_PointsToIniDir()
    {
        Assert.StartsWith(_pm.IniDir, _pm.SystemConfigPath);
        Assert.EndsWith("SysTemConfig.ini", _pm.SystemConfigPath);
    }

    [Fact]
    public void PgSettingPath_PointsToIniDir()
    {
        Assert.StartsWith(_pm.IniDir, _pm.PgSettingPath);
        Assert.EndsWith("PGSetting.ini", _pm.PgSettingPath);
    }

    [Fact]
    public void PowerCalibrationFileName_IsRelative()
    {
        Assert.Equal("PowerCalibration.ini", _pm.PowerCalibrationFileName);
    }

    // ── SetCurrentModel ──────────────────────────────────────

    [Fact]
    public void SetCurrentModel_SetsModelCurrentDir()
    {
        _pm.SetCurrentModel("TestModel_V1");
        Assert.Contains("TestModel_V1", _pm.ModelCurrentDir);
        Assert.True(Directory.Exists(_pm.ModelCurrentDir));
    }

    [Fact]
    public void SetCurrentModel_EmptyName_Throws()
    {
        Assert.Throws<ArgumentException>(() => _pm.SetCurrentModel(""));
    }

    // ── GetFilePath ──────────────────────────────────────────

    [Fact]
    public void GetFilePath_Model_ReturnsMcfExtension()
    {
        _pm.SetCurrentModel("M1");
        string path = _pm.GetFilePath("myfile", PathIndex.Model);
        Assert.EndsWith(".mcf", path);
        Assert.Contains("M1", path);
    }

    [Fact]
    public void GetFilePath_Pattern_ReturnsPatExtension()
    {
        string path = _pm.GetFilePath("pat1", PathIndex.Pattern);
        Assert.EndsWith(".pat", path);
    }

    [Fact]
    public void GetFilePath_PatternGroup_ReturnsGrpExtension()
    {
        string path = _pm.GetFilePath("grp1", PathIndex.PatternGroup);
        Assert.EndsWith(".grp", path);
    }

    [Fact]
    public void GetFilePath_ScriptIsu_ReturnsIsuExtension()
    {
        _pm.SetCurrentModel("M1");
        string path = _pm.GetFilePath("script1", PathIndex.ScriptIsu);
        Assert.EndsWith(".isu", path);
    }

    [Fact]
    public void GetFilePath_ScriptPsu_ReturnsPsuExtension()
    {
        _pm.SetCurrentModel("M1");
        string path = _pm.GetFilePath("script2", PathIndex.ScriptPsu);
        Assert.EndsWith(".psu", path);
    }

    [Fact]
    public void GetFilePath_UnknownIndex_ReturnsFileNameAsIs()
    {
        string path = _pm.GetFilePath("raw.txt", 999);
        Assert.Equal("raw.txt", path);
    }

    // ── GetLogDir / GetChannelLogDir ─────────────────────────

    [Fact]
    public void GetLogDir_DateBased()
    {
        var date = new DateTime(2025, 3, 15);
        string logDir = _pm.GetLogDir(date);
        Assert.Contains("202503", logDir);
    }

    [Fact]
    public void GetChannelLogDir_IncludesChannelFolder()
    {
        var date = new DateTime(2025, 3, 15);
        string chDir = _pm.GetChannelLogDir(2, date);
        Assert.Contains("202503", chDir);
        Assert.Contains("CH2", chDir);
    }

    // ── Resolve ──────────────────────────────────────────────

    [Fact]
    public void Resolve_CombinesWithRoot()
    {
        string resolved = _pm.Resolve("sub/file.txt");
        Assert.StartsWith(_pm.RootDir, resolved);
        Assert.Contains("sub", resolved);
    }

    [Fact]
    public void Resolve_Empty_ReturnsRoot()
    {
        Assert.Equal(_pm.RootDir, _pm.Resolve(""));
    }

    // ── NotInitialized ───────────────────────────────────────

    [Fact]
    public void GetFilePath_BeforeInit_Throws()
    {
        var uninitPm = new PathManager(_tempRoot);
        _pm.SetCurrentModel("M1"); // init the main PM
        Assert.Throws<InvalidOperationException>(
            () => uninitPm.GetFilePath("file", PathIndex.Model));
    }

    // ── EnsureDirectory ──────────────────────────────────────

    [Fact]
    public void EnsureDirectory_CreatesIfNotExist()
    {
        string newDir = Path.Combine(_tempRoot, "brand_new_dir");
        Assert.False(Directory.Exists(newDir));

        _pm.EnsureDirectory(newDir);
        Assert.True(Directory.Exists(newDir));
    }

    [Fact]
    public void EnsureDirectory_ExistingDir_NoError()
    {
        _pm.EnsureDirectory(_pm.LogDir); // Already exists
        Assert.True(Directory.Exists(_pm.LogDir));
    }

    // ── Constructor validation ───────────────────────────────

    [Fact]
    public void Constructor_NullRoot_Throws()
    {
        Assert.Throws<ArgumentException>(() => new PathManager(null!));
    }

    [Fact]
    public void Constructor_EmptyRoot_Throws()
    {
        Assert.Throws<ArgumentException>(() => new PathManager(""));
    }

    // ── LGD directories ─────────────────────────────────────

    [Fact]
    public void LgdDirectories_Structure()
    {
        Assert.Contains("LGDDLL", _pm.LgdDllDir);
        Assert.Contains("OCSet", _pm.LgdSettingDir);
        Assert.Contains("Parameters", _pm.LgdParameterDir);
        Assert.Contains("ReProgramming", _pm.LgdReProgrammingDir);
        Assert.Contains("_bk", _pm.LgdLogBackupDir);
        Assert.Contains("SummaryLog", _pm.LgdSummaryLogDir);
    }
}
