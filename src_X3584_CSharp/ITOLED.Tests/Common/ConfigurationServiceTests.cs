// =============================================================================
// ConfigurationServiceTests.cs — Tests for ConfigurationService INI round-trip
// =============================================================================

using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.Common;

public class ConfigurationServiceTests : IDisposable
{
    private readonly string _tempRoot;
    private readonly PathManager _pm;
    private readonly AppConfiguration _appConfig;
    private readonly ConfigurationService _svc;

    public ConfigurationServiceTests()
    {
        _tempRoot = Path.Combine(Path.GetTempPath(), "ITOLED_CS_" + Guid.NewGuid().ToString("N")[..8]);
        Directory.CreateDirectory(_tempRoot);
        _pm = new PathManager(_tempRoot);
        _pm.InitializePaths();
        _appConfig = new AppConfiguration();
        _svc = new ConfigurationService(_pm, _appConfig);
    }

    public void Dispose()
    {
        try { Directory.Delete(_tempRoot, recursive: true); }
        catch { /* ignore cleanup errors */ }
    }

    // ── Constructor validation ──────────────────────────────────

    [Fact]
    public void Constructor_NullPathManager_Throws()
    {
        Assert.Throws<ArgumentNullException>(() =>
            new ConfigurationService(null!, _appConfig));
    }

    [Fact]
    public void Constructor_NullAppConfig_Throws()
    {
        Assert.Throws<ArgumentNullException>(() =>
            new ConfigurationService(_pm, null!));
    }

    [Fact]
    public void AppConfig_ReturnsInjectedInstance()
    {
        Assert.Same(_appConfig, _svc.AppConfig);
    }

    // ── Low-level INI access ───────────────────────────────────

    [Fact]
    public void SetString_GetString_Roundtrip()
    {
        _svc.SetString("TEST", "Key1", "Hello");
        string value = _svc.GetString("TEST", "Key1", "default");
        Assert.Equal("Hello", value);
    }

    [Fact]
    public void SetInt_GetInt_Roundtrip()
    {
        _svc.SetInt("TEST", "IntKey", 42);
        int value = _svc.GetInt("TEST", "IntKey", 0);
        Assert.Equal(42, value);
    }

    [Fact]
    public void SetBool_GetBool_Roundtrip()
    {
        _svc.SetBool("TEST", "BoolKey", true);
        bool value = _svc.GetBool("TEST", "BoolKey", false);
        Assert.True(value);
    }

    [Fact]
    public void GetString_Missing_ReturnsDefault()
    {
        string value = _svc.GetString("NOSECTION", "NOKEY", "fallback");
        Assert.Equal("fallback", value);
    }

    [Fact]
    public void GetInt_Missing_ReturnsDefault()
    {
        int value = _svc.GetInt("NOSECTION", "NOKEY", 99);
        Assert.Equal(99, value);
    }

    [Fact]
    public void GetBool_Missing_ReturnsDefault()
    {
        bool value = _svc.GetBool("NOSECTION", "NOKEY", true);
        Assert.True(value);
    }

    [Fact]
    public void GetDouble_Missing_ReturnsDefault()
    {
        double value = _svc.GetDouble("NOSECTION", "NOKEY", 3.14);
        Assert.Equal(3.14, value, 2);
    }

    // ── ReadSystemInfo / SaveSystemInfo roundtrip ───────────────

    [Fact]
    public void ReadSystemInfo_NoFile_InitializesDefaults()
    {
        // Ensure no SysTemConfig.ini exists
        if (File.Exists(_pm.SystemConfigPath))
            File.Delete(_pm.SystemConfigPath);

        _svc.ReadSystemInfo();

        // Should set defaults and create the file
        Assert.True(File.Exists(_pm.SystemConfigPath));
        Assert.Equal("LCD", _svc.SystemInfo.Password);
        Assert.Equal(512, _svc.SystemInfo.PGMemorySize);
    }

    [Fact]
    public void SaveSystemInfo_ThenRead_PreservesValues()
    {
        // Set values
        _svc.SystemInfo.TestModel = "TestModel_XYZ";
        _svc.SystemInfo.EQPId = "EQP001";
        _svc.SystemInfo.EQPIdInline = "EQP001_INLINE";
        _svc.SystemInfo.PGMemorySize = 1024;
        _svc.SystemInfo.UIType = 2;
        _svc.SystemInfo.OCType = 1;
        _svc.SystemInfo.NGAlarmCount = 5;
        _svc.SystemInfo.RetryCount = 3;
        _svc.SystemInfo.ECSTimeout = 15000;
        _svc.SystemInfo.UseECS = false;
        _svc.SystemInfo.UseMES = true;
        _svc.SystemInfo.TestRepeat = true;
        _svc.SystemInfo.FwVer = "1.2.3";
        _svc.SystemInfo.FpgaVer = "4.5.6";
        _svc.SystemInfo.AutoLoginID = "999999";

        // Save
        _svc.SaveSystemInfo();

        // Create a fresh instance to read back
        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.Equal("TestModel_XYZ", svc2.SystemInfo.TestModel);
        Assert.Equal("EQP001", svc2.SystemInfo.EQPId);
        Assert.Equal(1024, svc2.SystemInfo.PGMemorySize);
        Assert.Equal(2, svc2.SystemInfo.UIType);
        Assert.Equal(1, svc2.SystemInfo.OCType);
        Assert.Equal(5, svc2.SystemInfo.NGAlarmCount);
        Assert.Equal(3, svc2.SystemInfo.RetryCount);
        Assert.Equal(15000, svc2.SystemInfo.ECSTimeout);
        Assert.False(svc2.SystemInfo.UseECS);
        Assert.True(svc2.SystemInfo.UseMES);
        Assert.True(svc2.SystemInfo.TestRepeat);
        Assert.Equal("1.2.3", svc2.SystemInfo.FwVer);
        Assert.Equal("4.5.6", svc2.SystemInfo.FpgaVer);
        Assert.Equal("999999", svc2.SystemInfo.AutoLoginID);
    }

    [Fact]
    public void Password_EncryptedInFile()
    {
        _svc.SystemInfo.Password = "MySecret";
        _svc.SaveSystemInfo();

        // Read the INI file raw to verify password is encrypted (not plaintext)
        string content = File.ReadAllText(_pm.SystemConfigPath);
        Assert.DoesNotContain("MySecret", content);
        Assert.Contains("PASSWORD=", content);
    }

    [Fact]
    public void Password_DecryptsCorrectly()
    {
        _svc.SystemInfo.Password = "TestPwd123";
        _svc.SystemInfo.SupervisorPassword = "SuperPwd456";
        _svc.SaveSystemInfo();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.Equal("TestPwd123", svc2.SystemInfo.Password);
        Assert.Equal("SuperPwd456", svc2.SystemInfo.SupervisorPassword);
    }

    // ── IP addresses roundtrip ─────────────────────────────────

    [Fact]
    public void IpAddresses_SaveAndLoad()
    {
        _svc.SystemInfo.IPAddr[0] = "10.0.0.1";
        _svc.SystemInfo.IPAddr[1] = "10.0.0.2";
        _svc.SaveSystemInfo();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.Equal("10.0.0.1", svc2.SystemInfo.IPAddr[0]);
        Assert.Equal("10.0.0.2", svc2.SystemInfo.IPAddr[1]);
    }

    // ── PLC info roundtrip ─────────────────────────────────────

    [Fact]
    public void PlcInfo_SaveAndLoad()
    {
        _svc.PlcInfo.EQPId = 37;
        _svc.PlcInfo.PollingInterval = 200;
        _svc.PlcInfo.TimeoutECS = 8000;
        _svc.PlcInfo.TimeoutConnection = 15000;
        _svc.PlcInfo.UseSimulation = true;
        _svc.PlcInfo.AddressEQP = "D100";
        _svc.SaveSystemInfo();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.Equal(37, svc2.PlcInfo.EQPId);
        Assert.Equal(200, svc2.PlcInfo.PollingInterval);
        Assert.Equal(8000, svc2.PlcInfo.TimeoutECS);
        Assert.Equal(15000, svc2.PlcInfo.TimeoutConnection);
        Assert.True(svc2.PlcInfo.UseSimulation);
        Assert.Equal("D100", svc2.PlcInfo.AddressEQP);

        // Zone calculation: (37-33)/4 = 1
        Assert.Equal(1, svc2.PlcInfo.Zone);
    }

    // ── Interlock info roundtrip ───────────────────────────────

    [Fact]
    public void InterlockInfo_SaveAndLoad()
    {
        _svc.InterlockInfo.Use = true;
        _svc.InterlockInfo.VersionSW = "3.2.1";
        _svc.InterlockInfo.VersionFW = "1.0.0";
        _svc.SaveSystemInfo();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.True(svc2.InterlockInfo.Use);
        Assert.Equal("3.2.1", svc2.InterlockInfo.VersionSW);
        Assert.Equal("1.0.0", svc2.InterlockInfo.VersionFW);
    }

    // ── SimulateInfo roundtrip ─────────────────────────────────

    [Fact]
    public void SimulateInfo_SaveAndLoad()
    {
        // SimulateInfo is read but not saved in SaveSystemInfo (read-only config)
        // We write it manually and verify read
        using var ini = new IniFileHelper(_pm.SystemConfigPath);
        ini.WriteBool("SimulateInfo", "USE_PG", true);
        ini.WriteBool("SimulateInfo", "USE_PLC", true);
        ini.WriteInteger("SimulateInfo", "PG_BASEPORT", 9000);
        ini.WriteString("SimulateInfo", "CAM_IP", "192.168.1.100");
        ini.Dispose();

        _svc.ReadSystemInfo();

        Assert.True(_svc.SimulateInfo.UsePG);
        Assert.True(_svc.SimulateInfo.UsePLC);
        Assert.Equal(9000, _svc.SimulateInfo.PGBasePort);
        Assert.Equal("192.168.1.100", _svc.SimulateInfo.CAMIP);
    }

    // ── Save / Reload ──────────────────────────────────────────

    [Fact]
    public void Save_CallsSaveSystemInfo()
    {
        _svc.SystemInfo.TestModel = "SaveTest";
        _svc.Save();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();
        Assert.Equal("SaveTest", svc2.SystemInfo.TestModel);
    }

    [Fact]
    public void Reload_ReadsFromDisk()
    {
        _svc.SystemInfo.TestModel = "Before";
        _svc.SaveSystemInfo();

        // Modify on disk via another instance
        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();
        svc2.SystemInfo.TestModel = "After";
        svc2.SaveSystemInfo();

        // Original instance reloads
        _svc.Reload();
        Assert.Equal("After", _svc.SystemInfo.TestModel);
    }

    // ── SaveLocalIpToSys ───────────────────────────────────────

    [Fact]
    public void SaveLocalIpToSys_Gmes_WritesCorrectKey()
    {
        _svc.SystemInfo.LocalIPGMES = "192.168.5.10";
        _svc.SaveLocalIpToSys(IpLocalIndex.Gmes);

        using var ini = new IniFileHelper(_pm.SystemConfigPath);
        Assert.Equal("192.168.5.10", ini.ReadString("SYSTEMDATA", "LocalIP_GMES", ""));
    }

    [Fact]
    public void SaveLocalIpToSys_Plc_WritesCorrectKey()
    {
        _svc.SystemInfo.LocalIPPLC = "10.10.10.1";
        _svc.SaveLocalIpToSys(IpLocalIndex.Plc);

        using var ini = new IniFileHelper(_pm.SystemConfigPath);
        Assert.Equal("10.10.10.1", ini.ReadString("SYSTEMDATA", "LocalIP_PLC", ""));
    }

    // ── SaveSystemInfoFwVersion ────────────────────────────────

    [Fact]
    public void SaveSystemInfoFwVersion_WritesPerChannel()
    {
        _svc.SaveSystemInfoFwVersion(0, "FW_v1.0");
        _svc.SaveSystemInfoFwVersion(1, "FW_v2.0");

        using var ini = new IniFileHelper(_pm.SystemConfigPath);
        Assert.Equal("FW_v1.0", ini.ReadString("SYSTEMDATA", "PG_VERSION_CH0", ""));
        Assert.Equal("FW_v2.0", ini.ReadString("SYSTEMDATA", "PG_VERSION_CH1", ""));
    }

    // ── SaveSystemInfoCa410Memory ──────────────────────────────

    [Fact]
    public void SaveSystemInfoCa410Memory_WritesPerChannel()
    {
        _svc.SaveSystemInfoCa410Memory(2, "MEM_CH2_DATA");

        using var ini = new IniFileHelper(_pm.SystemConfigPath);
        Assert.Equal("MEM_CH2_DATA", ini.ReadString("SYSTEMDATA", "CA410_MEMORY_CH2", ""));
    }

    // ── ReadOcInfo / SaveOcInfo ────────────────────────────────

    [Fact]
    public void SaveOcInfo_ThenReadOcInfo_Roundtrip()
    {
        _svc.SaveOcInfo(5);
        _svc.ReadOcInfo();

        Assert.Equal(5, _svc.OcInfo.CalModelType);
    }

    // ── ReadPgSettingInfo ───────────────────────────────────────

    [Fact]
    public void ReadPgSettingInfo_NoFile_ReturnsFalse()
    {
        Assert.False(_svc.ReadPgSettingInfo());
    }

    [Fact]
    public void ReadPgSettingInfo_WithFile_ReturnsTrue()
    {
        // Create PGSetting.ini
        using (var ini = new IniFileHelper(_pm.PgSettingPath))
        {
            ini.WriteBool("DEBUG", "PG_TconWriteLogDisplay", true);
            ini.WriteInteger("DEBUG", "PG_TconWriteCmdType", 3);
        }

        bool result = _svc.ReadPgSettingInfo();
        Assert.True(result);
        Assert.True(_svc.SystemInfo.PGTconWriteLogDisplay);
        Assert.Equal(3, _svc.SystemInfo.PGTconWriteCmdType);
    }

    // ── ReadSwVersion ──────────────────────────────────────────

    [Fact]
    public void ReadSwVersion_NoFile_ReturnsFalse()
    {
        Assert.False(_svc.ReadSwVersion());
    }

    [Fact]
    public void ReadSwVersion_WithFile_ParsesVersions()
    {
        // Create SW Version management.ini
        using (var ini = new IniFileHelper(_pm.SwVersionInfoPath))
        {
            ini.WriteString("OC", "Config1", "3.1:1.0");
            ini.WriteString("OC", "Config2", "4.2:2.1");
        }

        bool result = _svc.ReadSwVersion();
        Assert.True(result);
        Assert.Equal(2, _svc.SystemInfo.ConfigVerCount);
        Assert.Equal(2, _svc.SystemInfo.ConfigVer.Count);
    }

    // ── MES settings ───────────────────────────────────────────

    [Fact]
    public void MesSettings_SaveAndLoad()
    {
        _svc.SystemInfo.ServicePort = "28452";
        _svc.SystemInfo.Network = ";239.28.4.52;";
        _svc.SystemInfo.DaemonPort = "tcp:10.0.0.1:28401";
        _svc.SaveSystemInfo();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.Equal("28452", svc2.SystemInfo.ServicePort);
        Assert.Equal(";239.28.4.52;", svc2.SystemInfo.Network);
        Assert.Equal("tcp:10.0.0.1:28401", svc2.SystemInfo.DaemonPort);
    }

    // ── Camera settings ────────────────────────────────────────

    [Fact]
    public void CameraSettings_SaveAndLoad()
    {
        _svc.SystemInfo.CAMFFCData = true;
        _svc.SystemInfo.CAMStainData = true;
        _svc.SystemInfo.CAMFTPUpload = true;
        _svc.SystemInfo.CAMResultType = 2;
        _svc.SaveSystemInfo();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.True(svc2.SystemInfo.CAMFFCData);
        Assert.True(svc2.SystemInfo.CAMStainData);
        Assert.True(svc2.SystemInfo.CAMFTPUpload);
        Assert.Equal(2, svc2.SystemInfo.CAMResultType);
    }

    // ── Feature flags ──────────────────────────────────────────

    [Fact]
    public void FeatureFlags_SaveAndLoad()
    {
        _svc.SystemInfo.UseECS = false;
        _svc.SystemInfo.UseMES = true;
        _svc.SystemInfo.UseGIB = true;
        _svc.SystemInfo.UseInLineAAMode = true;
        _svc.SaveSystemInfo();

        var svc2 = new ConfigurationService(_pm, _appConfig);
        svc2.ReadSystemInfo();

        Assert.False(svc2.SystemInfo.UseECS);
        Assert.True(svc2.SystemInfo.UseMES);
        Assert.True(svc2.SystemInfo.UseGIB);
        Assert.True(svc2.SystemInfo.UseInLineAAMode);
    }

    // ── LogAccumulate settings ─────────────────────────────────

    [Fact]
    public void LogAccumulate_DefaultValues()
    {
        Assert.Equal(10, _svc.LogAccumulateCount);
        Assert.Equal(10, _svc.LogAccumulateSecond);
    }

    [Fact]
    public void LogAccumulate_ReadFromIni()
    {
        using (var ini = new IniFileHelper(_pm.SystemConfigPath))
        {
            ini.WriteInteger("SYSTEMDATA", "LogAccumulateCount", 25);
            ini.WriteInteger("SYSTEMDATA", "LogAccumulateSecond", 30);
        }

        _svc.ReadSystemInfo();

        Assert.Equal(25, _svc.LogAccumulateCount);
        Assert.Equal(30, _svc.LogAccumulateSecond);
    }
}
