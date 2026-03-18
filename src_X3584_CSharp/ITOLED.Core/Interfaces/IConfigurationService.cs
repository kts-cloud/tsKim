// =============================================================================
// IConfigurationService.cs
// Converted from Delphi: src_X3584\CommonClass.pas
// Configuration read/write functionality from TCommon.
// Namespace: Dongaeltek.ITOLED.Core.Interfaces
// =============================================================================

using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Models;

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Provides access to runtime configuration that was previously controlled
/// by Delphi's Common.inc conditional defines and SystemConfig.ini.
/// Holds the main configuration data records (SystemInfo, PlcInfo, etc.)
/// and provides methods to read/write them from INI files.
/// <para>Delphi origin: TCommon — configuration-related fields and methods
/// from CommonClass.pas.</para>
/// </summary>
public interface IConfigurationService
{
    // =========================================================================
    // Application Configuration (replaces Common.inc compile-time flags)
    // =========================================================================

    /// <summary>
    /// The application-level configuration loaded from appsettings.json.
    /// Replaces Common.inc compile-time flags.
    /// </summary>
    AppConfiguration AppConfig { get; }

    // =========================================================================
    // Configuration Data Properties
    // =========================================================================

    /// <summary>
    /// System configuration data read from SystemConfig.ini [SYSTEMDATA] section.
    /// <para>Delphi origin: TCommon.SystemInfo : TSystemInfo</para>
    /// </summary>
    SystemInfo SystemInfo { get; }

    /// <summary>
    /// PLC configuration data read from SystemConfig.ini [PLC] section.
    /// <para>Delphi origin: TCommon.PLCInfo : TPLCInfo</para>
    /// </summary>
    PLCInfo PlcInfo { get; }

    /// <summary>
    /// Simulator configuration data read from SystemConfig.ini [SimulateInfo] section.
    /// <para>Delphi origin: TCommon.SimulateInfo : TSimulateInfo</para>
    /// </summary>
    SimulateInfo SimulateInfo { get; }

    /// <summary>
    /// Offline interlock version data read from SystemConfig.ini [Interlock] section.
    /// <para>Delphi origin: TCommon.InterlockInfo : TInterlockInfo</para>
    /// </summary>
    InterlockInfo InterlockInfo { get; }

    /// <summary>
    /// Online interlock version data read from SystemConfig.ini [OnLineInterlock] section.
    /// <para>Delphi origin: TCommon.OnLineInterlockInfo : TOnLineInterlockInfo</para>
    /// </summary>
    OnLineInterlockInfo OnlineInterlockInfo { get; }

    /// <summary>
    /// DFS (Data File Server) configuration data read from SystemConfig.ini [DFSDATA] section.
    /// <para>Delphi origin: TCommon.DfsConfInfo : TDfsConfInfo</para>
    /// </summary>
    DfsConfInfo DfsConfInfo { get; }

    /// <summary>
    /// Optic (colorimeter) calibration info read from OpticConfig.ini.
    /// <para>Delphi origin: TCommon.OcInfo : TOcInfo</para>
    /// </summary>
    OcInfo OcInfo { get; }

    /// <summary>
    /// Loaded GMES defect code list (index 0 = PASS, rest from MES_CODE.csv).
    /// <para>Delphi origin: TCommon.GmesInfo : array of TGmesCode</para>
    /// </summary>
    IReadOnlyList<GmesCode> GmesInfo { get; }

    /// <summary>
    /// Number of GMES codes loaded (excluding index-0 PASS entry).
    /// <para>Delphi origin: TCommon.m_nGmesInfoCnt</para>
    /// </summary>
    int GmesInfoCount { get; }

    /// <summary>
    /// Reads MES_CODE.csv from the INI directory and populates GmesInfo.
    /// Returns the number of valid rows loaded.
    /// <para>Delphi origin: TCommon.LoadMesCode (CommonClass.pas line 3423)</para>
    /// </summary>
    int ReadGmesCsvFile();

    // =========================================================================
    // Low-level INI Access (for ad-hoc reads outside the main records)
    // =========================================================================

    /// <summary>
    /// Reads a string value from the system configuration (SystemConfig.ini equivalent).
    /// </summary>
    string GetString(string section, string key, string defaultValue = "");

    /// <summary>
    /// Reads an integer value from the system configuration.
    /// </summary>
    int GetInt(string section, string key, int defaultValue = 0);

    /// <summary>
    /// Reads a boolean value from the system configuration.
    /// </summary>
    bool GetBool(string section, string key, bool defaultValue = false);

    /// <summary>
    /// Reads a double value from the system configuration.
    /// </summary>
    double GetDouble(string section, string key, double defaultValue = 0.0);

    /// <summary>
    /// Writes a string value to the system configuration.
    /// </summary>
    void SetString(string section, string key, string value);

    /// <summary>
    /// Writes an integer value to the system configuration.
    /// </summary>
    void SetInt(string section, string key, int value);

    /// <summary>
    /// Writes a boolean value to the system configuration.
    /// </summary>
    void SetBool(string section, string key, bool value);

    // =========================================================================
    // High-level Configuration Operations
    // =========================================================================

    /// <summary>
    /// Reads all system configuration from SystemConfig.ini into the property records.
    /// If the file does not exist, initializes defaults and saves.
    /// <para>Delphi origin: procedure TCommon.ReadSystemInfo (line 6294)</para>
    /// </summary>
    void ReadSystemInfo();

    /// <summary>
    /// Writes all system configuration from the property records back to SystemConfig.ini.
    /// <para>Delphi origin: procedure TCommon.SaveSystemInfo (line 6984)</para>
    /// </summary>
    void SaveSystemInfo();

    /// <summary>
    /// Reads PG-specific settings from PGSetting.ini into SystemInfo fields.
    /// <para>Delphi origin: function TCommon.ReadPGSettingInfo : Boolean (line 6037)</para>
    /// </summary>
    /// <returns>True if PGSetting.ini exists and was read successfully.</returns>
    bool ReadPgSettingInfo();

    /// <summary>
    /// Reads software version management info from SW Version management.ini.
    /// <para>Delphi origin: function TCommon.ReadSWVer : Boolean (line 6227)</para>
    /// </summary>
    /// <returns>True if the version file exists and was read successfully.</returns>
    bool ReadSwVersion();

    /// <summary>
    /// Reads DLL settings from the model-specific Optimum_Setting.ini.
    /// <para>Delphi origin: function TCommon.ReadDLLSet : Boolean (line 6268)</para>
    /// </summary>
    /// <returns>True if the settings file exists and was read successfully.</returns>
    bool ReadDllSettings();

    /// <summary>
    /// Reads optic (colorimeter) calibration info from OpticConfig.ini.
    /// <para>Delphi origin: procedure TCommon.ReadOcInfo (line 6024)</para>
    /// </summary>
    void ReadOcInfo();

    /// <summary>
    /// Saves optic calibration model type to OpticConfig.ini.
    /// <para>Delphi origin: procedure TCommon.SaveOcInfo(nModelType : Integer) (line 6935)</para>
    /// </summary>
    /// <param name="modelType">Calibration model type value to save.</param>
    void SaveOcInfo(int modelType);

    /// <summary>
    /// Updates runtime system info fields (EXE filename, version) into the INI file.
    /// <para>Delphi origin: procedure TCommon.UpdateSystemInfo_Runtime (line 2872)</para>
    /// </summary>
    void UpdateSystemInfoRuntime();

    /// <summary>
    /// Saves a specific local IP or path setting to SystemConfig.ini based on index.
    /// <para>Delphi origin: procedure TCommon.SaveLocalIpToSys(nIdx: Integer) (line 6613)</para>
    /// </summary>
    /// <param name="index">IP setting index (use IpLocalIndex constants from DefCommon).</param>
    void SaveLocalIpToSys(int index);

    /// <summary>
    /// Saves PG firmware version for a specific channel to SystemConfig.ini.
    /// <para>Delphi origin: procedure TCommon.SavesystemInfoFwVersion(nCh, sData) (line 7225)</para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <param name="data">Firmware version string.</param>
    void SaveSystemInfoFwVersion(int channel, string data);

    /// <summary>
    /// Saves CA410 memory channel info for a specific channel to SystemConfig.ini.
    /// <para>Delphi origin: procedure TCommon.SavesystemInfoCA410Memory(nCh, sData) (line 7210)</para>
    /// </summary>
    /// <param name="channel">Channel number (0-based).</param>
    /// <param name="data">CA410 memory data string.</param>
    void SaveSystemInfoCa410Memory(int channel, string data);

    /// <summary>
    /// Saves any pending configuration changes to disk.
    /// </summary>
    void Save();

    /// <summary>
    /// Reloads configuration from disk.
    /// </summary>
    void Reload();
}
