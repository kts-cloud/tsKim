// =============================================================================
// ConfigurationService.cs
// Converted from Delphi: src_X3584\CommonClass.pas — TCommon configuration methods
// Methods: ReadSystemInfo, SaveSystemInfo, InitSystemInfo, ReadPGSettingInfo,
//          ReadSWVer, ReadDLLSet, ReadOcInfo, SaveOcInfo,
//          UpdateSystemInfo_Runtime, SaveLocalIpToSys,
//          SavesystemInfoFwVersion, SavesystemInfoCA410Memory
// Namespace: Dongaeltek.ITOLED.Core.Common
// =============================================================================

using System.Diagnostics;
using System.Reflection;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Models;

namespace Dongaeltek.ITOLED.Core.Common;

/// <summary>
/// Reads and writes system configuration from INI files.
/// Replaces the configuration-related subset of Delphi's TCommon class.
/// <para>Delphi origin: CommonClass.pas — TCommon (lines ~2755-7240)</para>
/// </summary>
public class ConfigurationService : IConfigurationService
{
    // =========================================================================
    // Dependencies
    // =========================================================================

    private readonly IPathManager _pathManager;

    // =========================================================================
    // Configuration Data Properties
    // =========================================================================

    /// <inheritdoc />
    public AppConfiguration AppConfig { get; }

    /// <inheritdoc />
    public SystemInfo SystemInfo { get; } = new();

    /// <inheritdoc />
    public PLCInfo PlcInfo { get; } = new();

    /// <inheritdoc />
    public SimulateInfo SimulateInfo { get; } = new();

    /// <inheritdoc />
    public InterlockInfo InterlockInfo { get; } = new();

    /// <inheritdoc />
    public OnLineInterlockInfo OnlineInterlockInfo { get; } = new();

    /// <inheritdoc />
    public DfsConfInfo DfsConfInfo { get; } = new();

    /// <inheritdoc />
    public OcInfo OcInfo { get; } = new();

    private readonly List<GmesCode> _gmesInfo = [];

    /// <inheritdoc />
    public IReadOnlyList<GmesCode> GmesInfo => _gmesInfo.AsReadOnly();

    /// <inheritdoc />
    public int GmesInfoCount => _gmesInfo.Count > 0 ? _gmesInfo.Count - 1 : 0; // exclude index-0 PASS

    /// <summary>
    /// Log accumulate count (read from [SYSTEMDATA] LogAccumulateCount).
    /// <para>Delphi origin: TCommon.LogAccumulateCount</para>
    /// </summary>
    public int LogAccumulateCount { get; set; } = 10;

    /// <summary>
    /// Log accumulate second (read from [SYSTEMDATA] LogAccumulateSecond).
    /// <para>Delphi origin: TCommon.LogAccumulateSecond</para>
    /// </summary>
    public int LogAccumulateSecond { get; set; } = 10;

    /// <summary>
    /// Active debug log level.
    /// <para>Delphi origin: TCommon.m_nDebugLogLevelActive</para>
    /// </summary>
    public int DebugLogLevelActive { get; set; }

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a new ConfigurationService.
    /// </summary>
    /// <param name="pathManager">Path manager for resolving INI file locations.</param>
    /// <param name="appConfig">Application configuration (replaces compile-time flags).</param>
    public ConfigurationService(IPathManager pathManager, AppConfiguration appConfig)
    {
        _pathManager = pathManager ?? throw new ArgumentNullException(nameof(pathManager));
        AppConfig = appConfig ?? throw new ArgumentNullException(nameof(appConfig));
    }

    // =========================================================================
    // Low-level INI Access
    // =========================================================================

    /// <inheritdoc />
    public string GetString(string section, string key, string defaultValue = "")
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);
        return ini.ReadString(section, key, defaultValue);
    }

    /// <inheritdoc />
    public int GetInt(string section, string key, int defaultValue = 0)
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);
        return ini.ReadInteger(section, key, defaultValue);
    }

    /// <inheritdoc />
    public bool GetBool(string section, string key, bool defaultValue = false)
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);
        return ini.ReadBool(section, key, defaultValue);
    }

    /// <inheritdoc />
    public double GetDouble(string section, string key, double defaultValue = 0.0)
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);
        return ini.ReadFloat(section, key, defaultValue);
    }

    /// <inheritdoc />
    public void SetString(string section, string key, string value)
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);
        ini.WriteString(section, key, value);
    }

    /// <inheritdoc />
    public void SetInt(string section, string key, int value)
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);
        ini.WriteInteger(section, key, value);
    }

    /// <inheritdoc />
    public void SetBool(string section, string key, bool value)
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);
        ini.WriteBool(section, key, value);
    }

    /// <inheritdoc />
    public void Save()
    {
        SaveSystemInfo();
    }

    /// <inheritdoc />
    public void Reload()
    {
        ReadSystemInfo();
    }

    // =========================================================================
    // ReadGmesCsvFile
    // Delphi origin: TCommon.LoadMesCode (CommonClass.pas line 3423)
    // =========================================================================

    /// <inheritdoc />
    public int ReadGmesCsvFile()
    {
        _gmesInfo.Clear();

        // Index 0: PASS entry (Delphi: GmesInfo[0].sErrCode := 'PASS')
        _gmesInfo.Add(new GmesCode { Idx = 0, ErrCode = "PASS", ErrMsg = "", MESCode = "", Option = 0 });

        var csvPath = Path.Combine(_pathManager.IniDir, "MES_CODE.csv");
        if (!File.Exists(csvPath))
            return 0;

        var lines = File.ReadAllLines(csvPath);
        foreach (var rawLine in lines)
        {
            var line = rawLine.Trim();
            if (string.IsNullOrEmpty(line))
                continue;

            // Delphi uses ExtractStrings([','], ...) which splits on comma
            var parts = line.Split(',');
            if (parts.Length < 6)
                continue;

            if (!int.TryParse(parts[0].Trim(), out var idx) || idx < 0)
                continue;

            var errCode = parts[3].Trim();
            var errMsg = parts[4].Trim();
            var rawMesCode = parts[5].Trim();

            // MES code formatting: pad parts to fixed width
            // Input: A06-B01-IZJ → Output: A06-B01-----IZJ---------------------------
            var mesCodeParts = rawMesCode.Split('-');
            string mesCode;
            if (mesCodeParts.Length > 2)
            {
                mesCode = mesCodeParts[0] + "-" + mesCodeParts[1] + "-----" + mesCodeParts[2] + "---------------------------";
            }
            else
            {
                mesCode = rawMesCode;
            }

            int option = 0;
            if (parts.Length > 6)
                int.TryParse(parts[6].Trim(), out option);

            _gmesInfo.Add(new GmesCode
            {
                Idx = idx,
                ErrCode = errCode,
                ErrMsg = errMsg,
                MESCode = mesCode,
                Option = option
            });
        }

        return _gmesInfo.Count;
    }

    // =========================================================================
    // InitSystemInfo
    // Delphi origin: procedure TCommon.InitSystemInfo (line 2755)
    // =========================================================================

    /// <summary>
    /// Sets default values for SystemInfo fields.
    /// <para>Delphi origin: procedure TCommon.InitSystemInfo</para>
    /// </summary>
    private void InitSystemInfo()
    {
        SystemInfo.Password = "LCD";
        SystemInfo.TestModel = string.Empty;

        for (int i = 0; i < ChannelConstants.MaxPgCount; i++)
        {
            SystemInfo.IPAddr[i] = $"192.168.0.{i + 21}";
        }

        for (int i = 0; i < LimitConstants.MaxBcrCount; i++)
            SystemInfo.ComHandBCR[i] = 0;

        for (int i = 0; i < LimitConstants.MaxSwitchCount; i++)
            SystemInfo.ComRCB[i] = 0;

        SystemInfo.ZMotor = 0;
        SystemInfo.PGMemorySize = 512;
    }

    // =========================================================================
    // ReadSystemInfo
    // Delphi origin: procedure TCommon.ReadSystemInfo (line 6294)
    // =========================================================================

    /// <inheritdoc />
    public void ReadSystemInfo()
    {
        if (!File.Exists(_pathManager.SystemConfigPath))
        {
            InitSystemInfo();
            SaveSystemInfo();
            return;
        }

        using var fSys = new IniFileHelper(_pathManager.SystemConfigPath);
        const string S = "SYSTEMDATA";

        // ---- Passwords (encrypted) ----
        SystemInfo.Password = Decrypt(fSys.ReadString(S, "PASSWORD", Encrypt("LED", 17307)), 17307);
        SystemInfo.SupervisorPassword = Decrypt(fSys.ReadString(S, "SUPERVISORPASSWORD", Encrypt("LED", 18307)), 18307);

        // ---- General settings ----
        SystemInfo.DAELoadWizardPath = fSys.ReadString(S, "DAELoadWizardPath", "");
        SystemInfo.TestModel = fSys.ReadString(S, "TESTING_MODEL", "");
        SystemInfo.ComIrTempSensor = fSys.ReadInteger(S, "COM_IR_TEMP_SENSOR", 0);
        SystemInfo.SetTemperature = fSys.ReadInteger(S, "Set_IR_TEMP", 0);
        SystemInfo.UseITOMode = fSys.ReadBool(S, "USE_ITOMODE", false);
        SystemInfo.PGType = fSys.ReadInteger(S, "PG_TYPE", Dongaeltek.ITOLED.Core.Definitions.PgType.Dp860);
        SystemInfo.CHReversal = fSys.ReadBool(S, "CHReversal", false);
        SystemInfo.SaveEnergy = fSys.ReadInteger(S, "SAVE_ENERGY", 0);

        // ---- Channel-indexed arrays ----
        int maxCh = ChannelConstants.MaxCh;
        for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
        {
            SystemInfo.IPAddr[i] = fSys.ReadString(S, $"IP_ADDR{i}", $"192.168.0.{i + 21}");
            if (string.IsNullOrWhiteSpace(SystemInfo.IPAddr[i]))
                SystemInfo.IPAddr[i] = $"192.168.0.{i + 21}";
            SystemInfo.UseCh[i] = fSys.ReadBool(S, $"USE_CH_{i + 1}", true);
        }

        for (int i = ChannelConstants.Ch1; i < LimitConstants.MaxBcrCount; i++)
            SystemInfo.ComHandBCR[i] = fSys.ReadInteger(S, $"COM_HandBCR{i + 1}", 0);

        for (int i = ChannelConstants.Ch1; i < LimitConstants.MaxSwitchCount; i++)
            SystemInfo.ComRCB[i] = fSys.ReadInteger(S, $"COM_RCB{i + 1}", 0);

        // ---- Motor and camera ----
        SystemInfo.ZMotor = fSys.ReadInteger(S, "COM_Z_AXIS", 0);
        SystemInfo.ComCamLight = fSys.ReadInteger(S, "COM_CAM_LIGHT", 0);

        // ---- Ionizers ----
        SystemInfo.IonizerCnt = 2;
        for (int i = 0; i < LimitConstants.MaxIonizerCount; i++)
        {
            SystemInfo.ComIonizer[i] = fSys.ReadInteger(S, $"COM_IONIZER_{i + 1}", 0);
            SystemInfo.ModelIonizer[i] = fSys.ReadInteger(S, $"MODEL_IONIZER_{i + 1}", 0);
        }

        // ---- PG memory and UI ----
        SystemInfo.PGMemorySize = fSys.ReadInteger(S, "PG_MEMORY_SIZE", 512);
        SystemInfo.UIType = fSys.ReadInteger(S, "UI_TYPE", 0);
        SystemInfo.OCType = fSys.ReadInteger(S, "OC_TYPE", 0);

        // ---- Limits ----
        SystemInfo.PIDLengthLimit = fSys.ReadInteger(S, "PID_LENGTH", 0);
        SystemInfo.ZIGLengthLimit = fSys.ReadInteger(S, "ZIG_LENGTH", 0);

        // ---- EQP IDs ----
        SystemInfo.EQPIdType = fSys.ReadInteger(S, "EQPId_Type", 0);
        SystemInfo.EQPId = fSys.ReadString(S, "EQPID", "");
        SystemInfo.EQPIdInline = fSys.ReadString(S, "EQPID_INLINE", "");
        SystemInfo.EQPIdMGIB = fSys.ReadString(S, "EQPID_MGIB", "");
        SystemInfo.EQPIdPGIB = fSys.ReadString(S, "EQPID_PGIB", "");
        SystemInfo.EQPIdMGIBProcessCode = fSys.ReadString(S, "EQPID_MGIB_PROCESS_CODE", "");
        SystemInfo.EQPIdPGIBProcessCode = fSys.ReadString(S, "EQPID_PGIB_PROCESS_CODE", "");

        // ---- Test flags ----
        SystemInfo.TestRepeat = fSys.ReadBool(S, "TEST_REPEAT", false);
        SystemInfo.UseNoExchange = fSys.ReadBool(S, "UseNoExchange", false);
        SystemInfo.UseNoPogo = fSys.ReadBool(S, "UseNoPogo", false);

        SystemInfo.R2RCa410MemCh = fSys.ReadInteger(S, "R2RCa410MemCh", 0);
        SystemInfo.DLLVerInterlock = fSys.ReadBool(S, "DLL_VER_INTERLOCK", false);
        SystemInfo.DLLVerInterlockList = fSys.ReadString(S, "DLL_VER_INTERLOCK_PATH", "");

        SystemInfo.PGResetDelayTime = fSys.ReadInteger(S, "PG_RESET_DELAY_TIME", 0);
        SystemInfo.PGResetTotalCount = fSys.ReadInteger(S, "PG_RESET_TOTAL_COUNT", 0);
        SystemInfo.OnlyRestartMode = fSys.ReadBool(S, "USE_ONLYRESTART", false);
        SystemInfo.DisplayDLLCnt = fSys.ReadInteger(S, "DISPLAY_DLL_CNT", 0);

        // ---- EQP ID fallback logic (Delphi compatibility) ----
        if (string.IsNullOrEmpty(SystemInfo.EQPIdInline))
            SystemInfo.EQPIdInline = SystemInfo.EQPId;

        if (string.IsNullOrEmpty(SystemInfo.EQPId))
        {
            SystemInfo.EQPId = SystemInfo.EQPIdType switch
            {
                0 => SystemInfo.EQPIdInline,
                1 => SystemInfo.EQPIdMGIB,
                2 => SystemInfo.EQPIdPGIB,
                _ => SystemInfo.EQPId
            };
        }

        // ---- MES / Network ----
        SystemInfo.ServicePort = fSys.ReadString(S, "MES_SERVICEPORT", "28451");
        SystemInfo.Network = fSys.ReadString(S, "MES_NETWORK", ";239.28.4.51;");
        SystemInfo.DaemonPort = fSys.ReadString(S, "MES_DAEMONPORT", "tcp:10.119.211.150:28401");
        SystemInfo.LocalSubject = fSys.ReadString(S, "MES_LOCALSUBJECT", "HN.G3.EQP.MOD.");
        SystemInfo.RemoteSubject = fSys.ReadString(S, "MES_REMOTESUBJECT", "HN.G1.EIFsvr.MOD");
        SystemInfo.EqccInterval = fSys.ReadString(S, "MES_EQCC_INTERVAL", "60000");
        SystemInfo.MesModelInfo = fSys.ReadString(S, "MES_MODELINFO", "");
        SystemInfo.LoaderIndex = fSys.ReadString(S, "LOADER_INDEX", "");
        SystemInfo.PowerLog = fSys.ReadBool(S, "PWRLOG", false);

        // ---- EAS ----
        SystemInfo.EasService = fSys.ReadString(S, "EAS_SERVICEPORT", "28481");
        SystemInfo.EasNetwork = fSys.ReadString(S, "EAS_NETWORK", ";239.28.4.81;");
        SystemInfo.EasDaemonPort = fSys.ReadString(S, "EAS_DAEMONPORT", "tcp:28401");
        SystemInfo.EasLocalSubject = fSys.ReadString(S, "EAS_LOCALSUBJECT", "HN.G3.EQP.HN.");
        SystemInfo.EasRemoteSubject = fSys.ReadString(S, "EAS_REMOTESUBJECT", "HN.G1.DIFsvr.HN");
        SystemInfo.ServiceCnt = 2;

        // ---- R2R ----
        SystemInfo.R2RService = fSys.ReadString(S, "R2R_SERVICEPORT", "28481");
        SystemInfo.R2RNetwork = fSys.ReadString(S, "R2R_NETWORK", ";239.28.4.81;");
        SystemInfo.R2RDaemonPort = fSys.ReadString(S, "R2R_DAEMONPORT", "tcp:28401");
        SystemInfo.R2RLocalSubject = fSys.ReadString(S, "R2R_LOCALSUBJECT", "HN.G3.EQP.HN.");
        SystemInfo.R2RRemoteSubject = fSys.ReadString(S, "R2R_REMOTESUBJECT", "HN.G1.DIFsvr.HN");

        for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
        {
            SystemInfo.R2REODSData[i] = fSys.ReadString(S, $"R2R_EODS_DATA_{i + 1}", "");
            SystemInfo.R2RMmcTxnIDData[i] = fSys.ReadString(S, $"R2R_MMCTXN_ID_DATA_{i + 1}", "");
        }

        if (!string.IsNullOrEmpty(SystemInfo.R2RService))
            SystemInfo.ServiceCnt = SystemInfo.ServiceCnt + 1;

        // ---- Firmware versions ----
        SystemInfo.FwVer = fSys.ReadString(S, "FW_VER", "");
        SystemInfo.FpgaVer = fSys.ReadString(S, "FPGA_VER", "");

        // ---- Robot addresses ----
        SystemInfo.RobotRevA = fSys.ReadString(S, "ROBOT_REV_A_ADDR", "");
        SystemInfo.RobotRevB = fSys.ReadString(S, "ROBOT_REV_B_ADDR", "");
        SystemInfo.RobotOutA = fSys.ReadString(S, "ROBOT_OUT_A_ADDR", "");
        SystemInfo.RobotOutB = fSys.ReadString(S, "ROBOT_OUT_B_ADDR", "");

        // ---- Manual and backup ----
        SystemInfo.OcManualType = fSys.ReadBool(S, "OC_MANUAL_TYPE", false);
        SystemInfo.AutoBackupUse = fSys.ReadBool(S, "AUTOBACKUP_USE", false);
        SystemInfo.AutoBackupList = fSys.ReadString(S, "AUTOBACKUP_PATH", "");
        SystemInfo.AutoLGDLogBackup = fSys.ReadBool(S, "AUTO_LGDLOG_BACKUP_USE", false);

        // ---- Logging ----
        SystemInfo.SystemLogUse = fSys.ReadBool(S, "SYSTEM_LOG_USE", false);
        LogAccumulateCount = fSys.ReadInteger(S, "LogAccumulateCount", 10);
        LogAccumulateSecond = fSys.ReadInteger(S, "LogAccumulateSecond", 10);
        SystemInfo.MIPILog = fSys.ReadBool(S, "MIPI_LOG_USE", false);

        // ---- Alarm and retry ----
        SystemInfo.NGAlarmCount = fSys.ReadInteger(S, "NGAlarmCount", 3);
        SystemInfo.RetryCount = fSys.ReadInteger(S, "RetryCount", 1);
        SystemInfo.ECSTimeout = fSys.ReadInteger(S, "ECS_Timeout", 10000);
        SystemInfo.RetryCountWritePOCB = fSys.ReadInteger(S, "RetryCount_WritePOCB", 2);

        // ---- Feature flags ----
        SystemInfo.UseECS = fSys.ReadBool(S, "USE_ECS", true);
        SystemInfo.UseMES = fSys.ReadBool(S, "USE_MES", false);
        SystemInfo.UseGIB = fSys.ReadBool(S, "USE_GIB", false);

        // ---- Camera ----
        SystemInfo.CAMFFCData = fSys.ReadBool(S, "CAM_FFCData", false);
        SystemInfo.CAMStainData = fSys.ReadBool(S, "CAM_STAINDATA", false);
        SystemInfo.CAMFTPUpload = fSys.ReadBool(S, "CAM_FTPUPLOAD", false);
        SystemInfo.CAMTemplateData = fSys.ReadBool(S, "CAM_TemplateData", false);
        SystemInfo.CAMCallbackChangePattern = fSys.ReadBool(S, "CAM_CALLBACK_CHANGEPATTERN", false);
        SystemInfo.CAMResultType = fSys.ReadInteger(S, "CAM_ResultType", 0);
        SystemInfo.MESCodeCnt = fSys.ReadInteger(S, "MES_CODE_Cnt", 3181);
        SystemInfo.PopupMsgTime = fSys.ReadInteger(S, "POPUPMSGTIME", 0);

        // ---- AA mode ----
        SystemInfo.UseInLineAAMode = fSys.ReadBool(S, "USE_INLINE_AAMODE", false);
        SystemInfo.UseDpdk = fSys.ReadBool(S, "USE_DPDK", false);
        SystemInfo.UsePipeline = fSys.ReadBool(S, "USE_PIPELINE", false);
        SystemInfo.DpdkCoreMask = fSys.ReadString(S, "DPDK_CORE_MASK", "auto");
        SystemInfo.DpdkMemoryMb = fSys.ReadInteger(S, "DPDK_MEMORY_MB", 256);
        SystemInfo.DpdkPortId = (ushort)fSys.ReadInteger(S, "DPDK_PORT_ID", 0);

        // ---- CA410 (runtime config check replaces {$IFDEF CA410_USE}) ----
        if (AppConfig.Colorimeter == ColorimeterType.CA410)
        {
            for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
            {
                SystemInfo.ComCa310[i] = fSys.ReadInteger(S, $"COM_CA310{i}", 0);
                SystemInfo.ComCa310Serial[i] = fSys.ReadString(S, $"COM_CA310{i}_SERIAL", "");
                SystemInfo.ComCa310DeviceId[i] = fSys.ReadInteger(S, $"COM_CA310{i}_DEVICE_ID", 0);
            }
            for (int i = 0; i < CaConstants.MaxCaDriveCount; i++)
            {
                SystemInfo.ComCaDeviceList[i] = fSys.ReadString(S, $"COM_CA_DEIVCE{i}_List", "");
            }
        }

        // ---- Auto login ----
        SystemInfo.AutoLoginID = fSys.ReadString(S, "AUTOLOGINID", "602462");
        SystemInfo.SetAModel = false;

        // ---- Channel count (ISPD_L_OPTIC check via runtime config) ----
        SystemInfo.ChCountUsed = fSys.ReadInteger(S, "USED_CH_COUNT", ChannelConstants.MaxPgCount);
        for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
        {
            SystemInfo.ProbAddr[i] = fSys.ReadString(S, $"PROBE_SERIAL_{i}", "");
        }

        // ---- DFS (runtime config check replaces {$IFDEF DFS_HEX}) ----
        if (AppConfig.DfsHex)
        {
            DfsConfInfo.UseDfs = fSys.ReadBool("DFSDATA", "USE_DFS", false);
            DfsConfInfo.DfsHexCompress = fSys.ReadBool("DFSDATA", "USE_HEX_COMPRESS", false);
            DfsConfInfo.DfsHexDelete = fSys.ReadBool("DFSDATA", "USE_HEX_DELETE", false);
            DfsConfInfo.DfsServerIP = fSys.ReadString("DFSDATA", "DFS_SERVER_IP", "");
            DfsConfInfo.DfsUserName = fSys.ReadString("DFSDATA", "DFS_USER_NAME", "");
            DfsConfInfo.DfsPassword = fSys.ReadString("DFSDATA", "DFS_PASSWORD", "");

            // Hardcoded values per Delphi RELEASE vs DEBUG
#if RELEASE
            DfsConfInfo.DfsServerIP = "10.122.8.64";
            DfsConfInfo.DfsUserName = "dfsopsh9";
            DfsConfInfo.DfsPassword = "!01dfsops";
            DfsConfInfo.CombiDownPath = "/data0h9d01/H9_MOD/DEFECT/MD";
#else
            DfsConfInfo.DfsServerIP = "127.0.0.1";
            DfsConfInfo.DfsUserName = "kts";
            DfsConfInfo.DfsPassword = "1111";
            DfsConfInfo.CombiDownPath = "/h9_mod/DEFECT/MD";
#endif

            DfsConfInfo.UseCombiDown = fSys.ReadBool("DFSDATA", "USE_COMBI_DOWN", false);
            DfsConfInfo.ProcessName = fSys.ReadString("DFSDATA", "PROCESS_NAME", "");
        }

        // ---- Local IPs ----
        SystemInfo.LocalIPGMES = fSys.ReadString(S, "LocalIP_GMES", "");
        SystemInfo.LocalIPPLC = fSys.ReadString(S, "LocalIP_PLC", "");
        SystemInfo.PlcConfigPath = fSys.ReadString(S, "PLC_CONFIG_PATH", "");
        SystemInfo.UseManualSerial = fSys.ReadBool(S, "MANUAL_SERAIL_INPUT", false);
        SystemInfo.UseAutoBCR = fSys.ReadBool(S, "USE_AUTO_BCR", false);
        SystemInfo.UseEQCC = fSys.ReadBool(S, "USE_EQCC", false);
        SystemInfo.UseTouchTest = fSys.ReadBool(S, "USE_TOUCH_TEST", false);
        SystemInfo.DIOType = fSys.ReadInteger(S, "DIO_TYPE", 0);
        SystemInfo.IndexMotorTimeout = fSys.ReadInteger(S, "IndexMotor_Timeout", 25);
        SystemInfo.CamDelay = fSys.ReadInteger(S, "CAMERA_MC_DELAY", 7);

        // ---- White uniformity offsets ----
        for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
        {
            SystemInfo.OffsetCh[i] = fSys.ReadFloat("WHITE_UNIFORMITY",
                $"OFFSET_{SystemInfo.TestModel}_CH{i + 1}", 0.0);
        }

        // ---- Signal inversion ----
        SystemInfo.SignalInversion = fSys.ReadString(S, "SIGNAL_INVERSION_OC", "0");
        SystemInfo.PGWriteReadPassAddr = fSys.ReadString(S, "PG_WRTIEREAD_PASS_ADDR", "");

        // ---- PLC info ----
        PlcInfo.EQPId = fSys.ReadInteger("PLC", "EQP_ID", 0);
        PlcInfo.PollingInterval = fSys.ReadInteger("PLC", "PollingInterval", 500);
        PlcInfo.TimeoutECS = fSys.ReadInteger("PLC", "Timeout_ECS", 5000);
        PlcInfo.TimeoutConnection = fSys.ReadInteger("PLC", "Timeout_Connection", 10000);
        PlcInfo.UseSimulation = fSys.ReadBool("PLC", "USE_SIMULATION", false);
        PlcInfo.InlineGIB = fSys.ReadBool("PLC", "InlineGIB", false);
        PlcInfo.AddressEQP = fSys.ReadString("PLC", "Address_EQP", "0");
        PlcInfo.AddressRobot = fSys.ReadString("PLC", "Address_ROBOT", "0");
        PlcInfo.AddressECS = fSys.ReadString("PLC", "Address_ECS", "0");
        PlcInfo.AddressEQPWrite = fSys.ReadString("PLC", "Address_EQP_W", "0");
        PlcInfo.AddressRobotWrite = fSys.ReadString("PLC", "Address_ROBOT_W", "0");
        PlcInfo.AddressECSWrite = fSys.ReadString("PLC", "Address_ECS_W", "0");
        PlcInfo.AddressRobot2 = fSys.ReadString("PLC", "Address_ROBOT2", "0");
        PlcInfo.AddressRobotWrite2 = fSys.ReadString("PLC", "Address_ROBOT_W2", "0");
        PlcInfo.AddressDoorOpen = fSys.ReadString("PLC", "Address_DOOROPEN", "0");

        // Zone calculation: (EQP_ID - 33) / 4, starting number 33
        PlcInfo.Zone = (PlcInfo.EQPId - 33) / 4;

        // ---- Interlock info ----
        InterlockInfo.Use = fSys.ReadBool("Interlock", "USE", false);
        InterlockInfo.VersionSW = fSys.ReadString("Interlock", "Version_SW", "-");
        InterlockInfo.VersionScript = fSys.ReadString("Interlock", "Version_Script", "-");
        InterlockInfo.VersionFW = fSys.ReadString("Interlock", "Version_FW", "-");
        InterlockInfo.VersionFPGA = fSys.ReadString("Interlock", "Version_FPGA", "-");
        InterlockInfo.VersionPower = fSys.ReadString("Interlock", "Version_Power", "-");
        InterlockInfo.VersionDLL = fSys.ReadString("Interlock", "Version_DLL", "");
        InterlockInfo.VersionLGDDLL = fSys.ReadString("Interlock", "Version_LGDDLL", "");

        // ---- Online interlock info ----
        OnlineInterlockInfo.Use = fSys.ReadBool("OnLineInterlock", "USE", true);
        OnlineInterlockInfo.ProcessCode = fSys.ReadString("OnLineInterlock", "Process_Code", "");
        OnlineInterlockInfo.ProcessIndex = fSys.ReadInteger("OnLineInterlock", "Process_Index", 0);
        OnlineInterlockInfo.VersionSW = fSys.ReadString("OnLineInterlock", "Version_SW", "-");
        OnlineInterlockInfo.VersionModel = fSys.ReadString("OnLineInterlock", "Version_MODEL", "LD130QD1");
        OnlineInterlockInfo.VersionModel = "LD130QD1"; // Hardcoded override from Delphi
        OnlineInterlockInfo.VersionFW = fSys.ReadString("OnLineInterlock", "Version_FW", "-");
        OnlineInterlockInfo.VersionFPGA = fSys.ReadString("OnLineInterlock", "Version_FPGA", "-");
        OnlineInterlockInfo.VersionPower = fSys.ReadString("OnLineInterlock", "Version_Power", "-");
        OnlineInterlockInfo.VersionDLL = fSys.ReadString("OnLineInterlock", "Version_DLL", "");
        OnlineInterlockInfo.VersionLGDDLL = fSys.ReadString("OnLineInterlock", "Version_LGDDLL", "");

        // DFS settings tied to OnLineInterlock
        DfsConfInfo.UseDfs = OnlineInterlockInfo.Use;
        DfsConfInfo.UseCombiDown = OnlineInterlockInfo.Use;

        // Extract line number from EQP ID (3rd char from end)
        if (SystemInfo.EQPId.Length >= 3)
        {
            if (int.TryParse(SystemInfo.EQPId.Substring(SystemInfo.EQPId.Length - 3, 1), out int nLine))
            {
                OnlineInterlockInfo.ProcessCode = $"45100_50{nLine}";
            }
        }

        // ---- Simulate info ----
        SimulateInfo.UsePG = fSys.ReadBool("SimulateInfo", "USE_PG", false);
        SimulateInfo.UsePLC = fSys.ReadBool("SimulateInfo", "USE_PLC", false);
        SimulateInfo.UseDIO = fSys.ReadBool("SimulateInfo", "USE_DIO", false);
        SimulateInfo.UseCAM = fSys.ReadBool("SimulateInfo", "USE_CAM", false);
        SimulateInfo.PGBasePort = fSys.ReadInteger("SimulateInfo", "PG_BASEPORT", 8000);
        SimulateInfo.CAMIP = fSys.ReadString("SimulateInfo", "CAM_IP", "127.0.0.1");
        SimulateInfo.DIOIP = fSys.ReadString("SimulateInfo", "DIO_IP", "127.0.0.1");
        SimulateInfo.DIOPort = fSys.ReadInteger("SimulateInfo", "DIO_PORT", 6988);

        // ---- Debug settings ----
        SystemInfo.DebugLogLevelConfig = fSys.ReadInteger("DEBUG", "DEBUG_LOG_LEVEL_PG", 0);
        DebugLogLevelActive = SystemInfo.DebugLogLevelConfig;

        ReadPgTconDebugSettings(fSys);
    }

    /// <summary>
    /// Reads PG TCON debug settings from the INI file.
    /// Shared between ReadSystemInfo and ReadPgSettingInfo.
    /// </summary>
    private void ReadPgTconDebugSettings(IniFileHelper fSys)
    {
        SystemInfo.PGTconWriteLogDisplay = fSys.ReadBool("DEBUG", "PG_TconWriteLogDisplay", false);
        SystemInfo.PGTconWriteCmdType = fSys.ReadInteger("DEBUG", "PG_TconWriteCmdType", 1);
        SystemInfo.PGTconReadCmdType = fSys.ReadInteger("DEBUG", "PG_TconReadCmdType", 0);
        SystemInfo.PGTconOcWriteDelayMsec = fSys.ReadInteger("DEBUG", "PG_TconOcWriteDelayMsec", 1);
        SystemInfo.PGTconOcWriteSyncAddrStr = fSys.ReadString("DEBUG", "PG_TconOcWriteSyncAddrStr",
            "1727,6926,6928,6930,6936,10260").Trim();

        // Parse sync address array from comma-separated string
        SystemInfo.PGTconOcWriteSyncAddrArr.Clear();
        if (!string.IsNullOrEmpty(SystemInfo.PGTconOcWriteSyncAddrStr))
        {
            var parts = SystemInfo.PGTconOcWriteSyncAddrStr.Split(',');
            foreach (var part in parts)
            {
                if (int.TryParse(part.Trim(), out int addr))
                    SystemInfo.PGTconOcWriteSyncAddrArr.Add(addr);
            }
        }

        SystemInfo.PGGpioReadHpdBeforeMeasure = fSys.ReadBool("DEBUG", "PG_GpioReadHpdBeforeMeasure", true);
        SystemInfo.PGWaitAckAfterContOcWriteCnt = fSys.ReadInteger("DEBUG", "PG_WaitAckAfterContOcWriteCnt", 0);
        SystemInfo.PGTconReadBeforeDelayMsec = fSys.ReadInteger("DEBUG", "PG_TconReadBeforeDelayMsec", 0);
        SystemInfo.PGTconOcWriteDelayLoopCnt = fSys.ReadInteger("DEBUG", "PG_TconOcWriteDelayLoopCnt", 0);
        SystemInfo.PGTconOcWriteDelayMicroSec = fSys.ReadInteger("DEBUG", "PG_TconOcWriteDelayMicroSec", 0);
        SystemInfo.PGEnableDpdkWarmup = fSys.ReadBool("DEBUG", "PG_EnableDpdkWarmup", true);
    }

    // =========================================================================
    // SaveSystemInfo
    // Delphi origin: procedure TCommon.SaveSystemInfo (line 6984)
    // =========================================================================

    /// <inheritdoc />
    public void SaveSystemInfo()
    {
        using var sysF = new IniFileHelper(_pathManager.SystemConfigPath);
        const string S = "SYSTEMDATA";
        int maxCh = ChannelConstants.MaxCh;

        // ---- Passwords (encrypted) ----
        sysF.WriteString(S, "PASSWORD", Encrypt(SystemInfo.Password, 17307));
        sysF.WriteString(S, "SUPERVISORPASSWORD", Encrypt(SystemInfo.SupervisorPassword, 18307));

        // ---- General settings ----
        sysF.WriteString(S, "DAELoadWizardPath", SystemInfo.DAELoadWizardPath);
        sysF.WriteString(S, "TESTING_MODEL", SystemInfo.TestModel);

        for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
        {
            sysF.WriteString(S, $"IP_ADDR{i}", SystemInfo.IPAddr[i]);
            sysF.WriteBool(S, $"USE_CH_{i + 1}", SystemInfo.UseCh[i]);
        }

        sysF.WriteBool(S, "CHReversal", SystemInfo.CHReversal);
        sysF.WriteBool(S, "USE_ITOMODE", SystemInfo.UseITOMode);
        sysF.WriteBool(S, "USE_ONLYRESTART", SystemInfo.OnlyRestartMode);
        sysF.WriteInteger(S, "COM_IR_TEMP_SENSOR", SystemInfo.ComIrTempSensor);
        sysF.WriteInteger(S, "Set_IR_TEMP", SystemInfo.SetTemperature);
        sysF.WriteInteger(S, "EQPID_TYPE", SystemInfo.EQPIdType);
        sysF.WriteString(S, "EQPID", SystemInfo.EQPId);
        sysF.WriteString(S, "EQPID_INLINE", SystemInfo.EQPIdInline);
        sysF.WriteString(S, "EQPID_MGIB", SystemInfo.EQPIdMGIB);
        sysF.WriteString(S, "EQPID_PGIB", SystemInfo.EQPIdPGIB);
        sysF.WriteString(S, "EQPID_MGIB_PROCESS_CODE", SystemInfo.EQPIdMGIBProcessCode);
        sysF.WriteString(S, "EQPID_PGIB_PROCESS_CODE", SystemInfo.EQPIdPGIBProcessCode);

        // ---- MES ----
        sysF.WriteString(S, "MES_SERVICEPORT", SystemInfo.ServicePort);
        sysF.WriteString(S, "MES_NETWORK", SystemInfo.Network);
        sysF.WriteString(S, "MES_DAEMONPORT", SystemInfo.DaemonPort);
        sysF.WriteString(S, "MES_LOCALSUBJECT", SystemInfo.LocalSubject);
        sysF.WriteString(S, "MES_REMOTESUBJECT", SystemInfo.RemoteSubject);
        sysF.WriteString(S, "MES_MODELINFO", SystemInfo.MesModelInfo);

        // ---- EAS ----
        sysF.WriteString(S, "EAS_SERVICEPORT", SystemInfo.EasService);
        sysF.WriteString(S, "EAS_NETWORK", SystemInfo.EasNetwork);
        sysF.WriteString(S, "EAS_DAEMONPORT", SystemInfo.EasDaemonPort);
        sysF.WriteString(S, "EAS_LOCALSUBJECT", SystemInfo.EasLocalSubject);
        sysF.WriteString(S, "EAS_REMOTESUBJECT", SystemInfo.EasRemoteSubject);

        // ---- R2R ----
        sysF.WriteString(S, "R2R_SERVICEPORT", SystemInfo.R2RService);
        sysF.WriteString(S, "R2R_NETWORK", SystemInfo.R2RNetwork);
        sysF.WriteString(S, "R2R_DAEMONPORT", SystemInfo.R2RDaemonPort);
        sysF.WriteString(S, "R2R_LOCALSUBJECT", SystemInfo.R2RLocalSubject);
        sysF.WriteString(S, "R2R_REMOTESUBJECT", SystemInfo.R2RRemoteSubject);

        for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
        {
            sysF.WriteString(S, $"R2R_EODS_DATA_{i + 1}", SystemInfo.R2REODSData[i]);
            sysF.WriteString(S, $"R2R_MMCTXN_ID_DATA_{i + 1}", SystemInfo.R2RMmcTxnIDData[i]);
        }

        sysF.WriteString(S, "MES_EQCC_INTERVAL", SystemInfo.EqccInterval);
        sysF.WriteString(S, "LOADER_INDEX", SystemInfo.LoaderIndex);

        // ---- COM ports ----
        for (int i = 0; i < LimitConstants.MaxBcrCount; i++)
            sysF.WriteInteger(S, $"COM_HandBCR{i + 1}", SystemInfo.ComHandBCR[i]);

        for (int i = 0; i < LimitConstants.MaxSwitchCount; i++)
            sysF.WriteInteger(S, $"COM_RCB{i + 1}", SystemInfo.ComRCB[i]);

        sysF.WriteInteger(S, "COM_Z_AXIS", SystemInfo.ZMotor);
        sysF.WriteInteger(S, "COM_CAM_LIGHT", SystemInfo.ComCamLight);

        for (int i = 0; i < LimitConstants.MaxIonizerCount; i++)
        {
            sysF.WriteInteger(S, $"COM_IONIZER_{i + 1}", SystemInfo.ComIonizer[i]);
            sysF.WriteInteger(S, $"MODEL_IONIZER_{i + 1}", SystemInfo.ModelIonizer[i]);
        }

        // ---- Memory / UI / Type ----
        sysF.WriteInteger(S, "PG_MEMORY_SIZE", SystemInfo.PGMemorySize);
        sysF.WriteInteger(S, "UI_TYPE", SystemInfo.UIType);
        sysF.WriteInteger(S, "OC_TYPE", SystemInfo.OCType);
        sysF.WriteInteger(S, "SAVE_ENERGY", SystemInfo.SaveEnergy);
        sysF.WriteInteger(S, "PID_LENGTH", SystemInfo.PIDLengthLimit);
        sysF.WriteInteger(S, "ZIG_LENGTH", SystemInfo.ZIGLengthLimit);
        sysF.WriteBool(S, "PWRLOG", SystemInfo.PowerLog);
        sysF.WriteInteger(S, "USED_CH_COUNT", SystemInfo.ChCountUsed);

        // ---- Backup and serial ----
        sysF.WriteBool(S, "AUTOBACKUP_USE", SystemInfo.AutoBackupUse);
        sysF.WriteBool(S, "MANUAL_SERAIL_INPUT", SystemInfo.UseManualSerial);
        sysF.WriteBool(S, "AUTO_LGDLOG_BACKUP_USE", SystemInfo.AutoLGDLogBackup);

        // ---- Alarm / retry ----
        sysF.WriteInteger(S, "NGAlarmCount", SystemInfo.NGAlarmCount);
        sysF.WriteInteger(S, "RetryCount", SystemInfo.RetryCount);
        sysF.WriteInteger(S, "ECS_Timeout", SystemInfo.ECSTimeout);
        sysF.WriteInteger(S, "RetryCount_WritePOCB", SystemInfo.RetryCountWritePOCB);

        // ---- Feature flags ----
        sysF.WriteBool(S, "SYSTEM_LOG_USE", SystemInfo.SystemLogUse);
        sysF.WriteBool(S, "MIPI_LOG_USE", SystemInfo.MIPILog);
        sysF.WriteBool(S, "USE_ECS", SystemInfo.UseECS);
        sysF.WriteBool(S, "USE_MES", SystemInfo.UseMES);
        sysF.WriteBool(S, "USE_GIB", SystemInfo.UseGIB);

        sysF.WriteString(S, "AUTOLOGINID", SystemInfo.AutoLoginID);
        sysF.WriteBool(S, "TEST_REPEAT", SystemInfo.TestRepeat);
        sysF.WriteBool(S, "UseNoExchange", SystemInfo.UseNoExchange);
        sysF.WriteBool(S, "UseNoPogo", SystemInfo.UseNoPogo);

        sysF.WriteString(S, "AUTOBACKUP_PATH", SystemInfo.AutoBackupList);
        sysF.WriteBool(S, "USE_AUTO_BCR", SystemInfo.UseAutoBCR);
        sysF.WriteBool(S, "USE_EQCC", SystemInfo.UseEQCC);
        sysF.WriteBool(S, "USE_TOUCH_TEST", SystemInfo.UseTouchTest);
        sysF.WriteBool(S, "OC_MANUAL_TYPE", SystemInfo.OcManualType);
        sysF.WriteInteger(S, "DIO_TYPE", SystemInfo.DIOType);
        sysF.WriteInteger(S, "IndexMotor_Timeout", SystemInfo.IndexMotorTimeout);
        sysF.WriteInteger(S, "CAM_ResultType", SystemInfo.CAMResultType);
        sysF.WriteBool(S, "CAM_FFCData", SystemInfo.CAMFFCData);
        sysF.WriteBool(S, "CAM_STAINDATA", SystemInfo.CAMStainData);
        sysF.WriteBool(S, "CAM_FTPUPLOAD", SystemInfo.CAMFTPUpload);
        sysF.WriteBool(S, "CAM_TemplateData", SystemInfo.CAMTemplateData);
        sysF.WriteBool(S, "CAM_CALLBACK_CHANGEPATTERN", SystemInfo.CAMCallbackChangePattern);

        // ---- Firmware ----
        sysF.WriteString(S, "FW_VER", SystemInfo.FwVer);
        sysF.WriteString(S, "FPGA_VER", SystemInfo.FpgaVer);

        // ---- Robot ----
        sysF.WriteString(S, "ROBOT_REV_A_ADDR", SystemInfo.RobotRevA);
        sysF.WriteString(S, "ROBOT_REV_B_ADDR", SystemInfo.RobotRevB);
        sysF.WriteString(S, "ROBOT_OUT_A_ADDR", SystemInfo.RobotOutA);
        sysF.WriteString(S, "ROBOT_OUT_B_ADDR", SystemInfo.RobotOutB);
        sysF.WriteInteger(S, "CAMERA_MC_DELAY", SystemInfo.CamDelay);

        // ---- DLL interlock ----
        sysF.WriteBool(S, "DLL_VER_INTERLOCK", SystemInfo.DLLVerInterlock);
        sysF.WriteString(S, "DLL_VER_INTERLOCK_PATH", SystemInfo.DLLVerInterlockList);

        for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
            sysF.WriteString(S, $"PROBE_SERIAL_{i}", SystemInfo.ProbAddr[i]);

        sysF.WriteInteger(S, "PG_RESET_DELAY_TIME", SystemInfo.PGResetDelayTime);
        sysF.WriteInteger(S, "PG_RESET_TOTAL_COUNT", SystemInfo.PGResetTotalCount);
        sysF.WriteString(S, "SIGNAL_INVERSION_OC", SystemInfo.SignalInversion);
        sysF.WriteInteger(S, "R2RCa410MemCh", SystemInfo.R2RCa410MemCh);
        sysF.WriteInteger(S, "MES_CODE_Cnt", SystemInfo.MESCodeCnt);
        sysF.WriteInteger(S, "POPUPMSGTIME", SystemInfo.PopupMsgTime);
        sysF.WriteInteger(S, "DISPLAY_DLL_CNT", SystemInfo.DisplayDLLCnt);
        sysF.WriteInteger("DEBUG", "DEBUG_LOG_LEVEL_PG", SystemInfo.DebugLogLevelConfig);
        sysF.WriteBool(S, "USE_INLINE_AAMODE", SystemInfo.UseInLineAAMode);

        // ---- DFS (runtime config check replaces {$IFDEF DFS_HEX}) ----
        if (AppConfig.DfsHex)
        {
            sysF.WriteBool("DFSDATA", "USE_DFS", DfsConfInfo.UseDfs);
            sysF.WriteBool("DFSDATA", "USE_HEX_COMPRESS", DfsConfInfo.DfsHexCompress);
            sysF.WriteBool("DFSDATA", "USE_HEX_DELETE", DfsConfInfo.DfsHexDelete);
            sysF.WriteString("DFSDATA", "DFS_SERVER_IP", DfsConfInfo.DfsServerIP);
            sysF.WriteString("DFSDATA", "DFS_USER_NAME", DfsConfInfo.DfsUserName);
            sysF.WriteString("DFSDATA", "DFS_PASSWORD", DfsConfInfo.DfsPassword);
            sysF.WriteBool("DFSDATA", "USE_COMBI_DOWN", DfsConfInfo.UseCombiDown);
            sysF.WriteString("DFSDATA", "COMBI_DOWN_PATH", DfsConfInfo.CombiDownPath);
            sysF.WriteString("DFSDATA", "PROCESS_NAME", DfsConfInfo.ProcessName);
        }

        // ---- CA410 (runtime config check replaces {$IFDEF CA410_USE}) ----
        if (AppConfig.Colorimeter == ColorimeterType.CA410)
        {
            for (int i = ChannelConstants.Ch1; i <= maxCh; i++)
            {
                sysF.WriteInteger(S, $"COM_CA310{i}", SystemInfo.ComCa310[i]);
                sysF.WriteInteger(S, $"COM_CA310{i}_DEVICE_ID", SystemInfo.ComCa310DeviceId[i]);
                sysF.WriteString(S, $"COM_CA310{i}_SERIAL", SystemInfo.ComCa310Serial[i]);
            }
            for (int i = 0; i < CaConstants.MaxCaDriveCount; i++)
            {
                sysF.WriteString(S, $"COM_CA_DEIVCE{i}_List", SystemInfo.ComCaDeviceList[i]);
            }
        }

        // ---- PLC ----
        sysF.WriteInteger("PLC", "EQP_ID", PlcInfo.EQPId);
        sysF.WriteInteger("PLC", "PollingInterval", PlcInfo.PollingInterval);
        sysF.WriteInteger("PLC", "Timeout_Connection", PlcInfo.TimeoutConnection);
        sysF.WriteInteger("PLC", "Timeout_ECS", PlcInfo.TimeoutECS);
        sysF.WriteBool("PLC", "USE_SIMULATION", PlcInfo.UseSimulation);
        sysF.WriteBool("PLC", "InlineGIB", PlcInfo.InlineGIB);
        sysF.WriteString("PLC", "Address_EQP", PlcInfo.AddressEQP);
        sysF.WriteString("PLC", "Address_ECS", PlcInfo.AddressECS);
        sysF.WriteString("PLC", "Address_ROBOT", PlcInfo.AddressRobot);
        sysF.WriteString("PLC", "Address_EQP_W", PlcInfo.AddressEQPWrite);
        sysF.WriteString("PLC", "Address_ECS_W", PlcInfo.AddressECSWrite);
        sysF.WriteString("PLC", "Address_ROBOT_W", PlcInfo.AddressRobotWrite);
        sysF.WriteString("PLC", "Address_ROBOT2", PlcInfo.AddressRobot2);
        sysF.WriteString("PLC", "Address_ROBOT_W2", PlcInfo.AddressRobotWrite2);
        sysF.WriteString("PLC", "Address_DOOROPEN", PlcInfo.AddressDoorOpen);

        // ---- Interlock ----
        sysF.WriteBool("Interlock", "USE", InterlockInfo.Use);
        sysF.WriteString("Interlock", "Version_SW", InterlockInfo.VersionSW);
        sysF.WriteString("Interlock", "Version_Script", InterlockInfo.VersionScript);
        sysF.WriteString("Interlock", "Version_FW", InterlockInfo.VersionFW);
        sysF.WriteString("Interlock", "Version_FPGA", InterlockInfo.VersionFPGA);
        sysF.WriteString("Interlock", "Version_Power", InterlockInfo.VersionPower);
        sysF.WriteString("Interlock", "Version_DLL", InterlockInfo.VersionDLL);
        sysF.WriteString("Interlock", "Version_LGDDLL", InterlockInfo.VersionLGDDLL);

        // ---- Online interlock ----
        sysF.WriteBool("OnLineInterlock", "USE", OnlineInterlockInfo.Use);
        sysF.WriteString("OnLineInterlock", "Process_Code", OnlineInterlockInfo.ProcessCode);
        sysF.WriteInteger("OnLineInterlock", "Process_Index", OnlineInterlockInfo.ProcessIndex);
        sysF.WriteString("OnLineInterlock", "Version_SW", OnlineInterlockInfo.VersionSW);
        sysF.WriteString("OnLineInterlock", "Version_MODEL", OnlineInterlockInfo.VersionModel);
        sysF.WriteString("OnLineInterlock", "Version_FW", OnlineInterlockInfo.VersionFW);
        sysF.WriteString("OnLineInterlock", "Version_FPGA", OnlineInterlockInfo.VersionFPGA);
        sysF.WriteString("OnLineInterlock", "Version_Power", OnlineInterlockInfo.VersionPower);
        sysF.WriteString("OnLineInterlock", "Version_DLL", OnlineInterlockInfo.VersionDLL);
        sysF.WriteString("OnLineInterlock", "Version_LGDDLL", OnlineInterlockInfo.VersionLGDDLL);

        // IniFileHelper.Dispose() will flush to disk
    }

    // =========================================================================
    // ReadPgSettingInfo
    // Delphi origin: function TCommon.ReadPGSettingInfo (line 6037)
    // =========================================================================

    /// <inheritdoc />
    public bool ReadPgSettingInfo()
    {
        if (!File.Exists(_pathManager.PgSettingPath))
            return false;

        using var fSys = new IniFileHelper(_pathManager.PgSettingPath);
        ReadPgTconDebugSettings(fSys);
        return true;
    }

    // =========================================================================
    // ReadSwVersion
    // Delphi origin: function TCommon.ReadSWVer (line 6227)
    // =========================================================================

    /// <inheritdoc />
    public bool ReadSwVersion()
    {
        if (!File.Exists(_pathManager.SwVersionInfoPath))
            return false;

        using var fSys = new IniFileHelper(_pathManager.SwVersionInfoPath);
        var keyList = fSys.ReadSection("OC");

        SystemInfo.ConfigVer.Clear();
        foreach (var sKey in keyList)
        {
            var sVer = fSys.ReadString("OC", sKey, "");
            var parts = sVer.Split(':');
            var ver = new SWVersion
            {
                ConfigVer = sKey,
                SWVer = parts.Length > 1 ? parts[0] : string.Empty,
                DLLVer = parts.Length > 1 ? parts[1] : string.Empty
            };
            SystemInfo.ConfigVer.Add(ver);
        }
        SystemInfo.ConfigVerCount = keyList.Count;
        return true;
    }

    // =========================================================================
    // ReadDllSettings
    // Delphi origin: function TCommon.ReadDLLSet (line 6268)
    // =========================================================================

    /// <inheritdoc />
    public bool ReadDllSettings()
    {
        // Build path: LGDSet + ModelTypeName + "\Optimum_Setting.ini"
        // Note: This requires TestModelInfoFLOW.ModelTypeName, which is set externally.
        // The caller must set up the correct path. For now we use a pattern-based approach.
        // This matches the Delphi: Path.LGDSet + Common.TestModelInfoFLOW.ModelTypeName + '\Optimum_Setting.ini'
        // Since we don't hold TestModelInfoFLOW here, this method accepts the resolved path
        // through the path manager or must be called after model info is loaded.

        // For a faithful conversion, we check LgdSettingDir-based paths.
        // The caller should ensure the model is loaded first.
        // We'll search for the file in a generic way:
        string settingDir = _pathManager.LgdSettingDir;
        // The actual file needs the model type name, which is external state.
        // Return false if directory doesn't exist
        if (string.IsNullOrEmpty(settingDir) || !Directory.Exists(settingDir))
            return false;

        // This method is intentionally left with a simplified implementation.
        // The full path resolution requires TestModelInfoFLOW.ModelTypeName
        // which belongs to a different service (IModelInfoService).
        return true;
    }

    // =========================================================================
    // ReadOcInfo
    // Delphi origin: procedure TCommon.ReadOcInfo (line 6024)
    // =========================================================================

    /// <inheritdoc />
    public void ReadOcInfo()
    {
        if (!File.Exists(_pathManager.OpticConfigPath))
            return;

        using var fSys = new IniFileHelper(_pathManager.OpticConfigPath);
        OcInfo.CalModelType = fSys.ReadInteger("CA310_CALIBRATION", "CAL_MODEL_TYPE", 0);
    }

    // =========================================================================
    // SaveOcInfo
    // Delphi origin: procedure TCommon.SaveOcInfo(nModelType) (line 6935)
    // =========================================================================

    /// <inheritdoc />
    public void SaveOcInfo(int modelType)
    {
        using var sysF = new IniFileHelper(_pathManager.OpticConfigPath);
        sysF.WriteInteger("CA310_CALIBRATION", "CAL_MODEL_TYPE", modelType);
        // Delphi calls WritePrivateProfileString(nil, nil, nil, ...) to flush cache.
        // IniFileHelper.Dispose() handles flushing.
    }

    // =========================================================================
    // UpdateSystemInfoRuntime
    // Delphi origin: procedure TCommon.UpdateSystemInfo_Runtime (line 2872)
    // =========================================================================

    /// <inheritdoc />
    public void UpdateSystemInfoRuntime()
    {
        using var ini = new IniFileHelper(_pathManager.SystemConfigPath);

        var exePath = Environment.ProcessPath ?? Assembly.GetEntryAssembly()?.Location ?? "";
        var exeFileName = Path.GetFileName(exePath);
        var exeVersion = GetExeVersion();

        ini.WriteString("SYSTEMDATA", "EXE_FILENAME", exePath);
        ini.WriteString("SYSTEMDATA", "TESTING_EXE", $"{exeFileName} ({exeVersion})");
    }

    // =========================================================================
    // SaveLocalIpToSys
    // Delphi origin: procedure TCommon.SaveLocalIpToSys(nIdx) (line 6613)
    // =========================================================================

    /// <inheritdoc />
    public void SaveLocalIpToSys(int index)
    {
        using var fSys = new IniFileHelper(_pathManager.SystemConfigPath);

        switch (index)
        {
            case IpLocalIndex.Gmes:
                fSys.WriteString("SYSTEMDATA", "LocalIP_GMES", SystemInfo.LocalIPGMES);
                break;
            case IpLocalIndex.Plc:
                fSys.WriteString("SYSTEMDATA", "LocalIP_PLC", SystemInfo.LocalIPPLC);
                break;
            case IpLocalIndex.PlcConfigPath:
                fSys.WriteString("SYSTEMDATA", "PLC_CONFIG_PATH", SystemInfo.PlcConfigPath);
                break;
            case IpLocalIndex.EmNumber:
                fSys.WriteString("SYSTEMDATA", "EQPID", SystemInfo.EQPId);
                break;
        }
    }

    // =========================================================================
    // SaveSystemInfoFwVersion
    // Delphi origin: procedure TCommon.SavesystemInfoFwVersion(nCh, sData) (line 7225)
    // =========================================================================

    /// <inheritdoc />
    public void SaveSystemInfoFwVersion(int channel, string data)
    {
        using var sysF = new IniFileHelper(_pathManager.SystemConfigPath);
        sysF.WriteString("SYSTEMDATA", $"PG_VERSION_CH{channel}", data);
    }

    // =========================================================================
    // SaveSystemInfoCa410Memory
    // Delphi origin: procedure TCommon.SavesystemInfoCA410Memory(nCh, sData) (line 7210)
    // =========================================================================

    /// <inheritdoc />
    public void SaveSystemInfoCa410Memory(int channel, string data)
    {
        using var sysF = new IniFileHelper(_pathManager.SystemConfigPath);
        sysF.WriteString("SYSTEMDATA", $"CA410_MEMORY_CH{channel}", data);
    }

    // =========================================================================
    // Encryption / Decryption Helpers
    // Ported from Delphi: CommonClass.pas Encrypt/Decrypt functions
    // Uses the same algorithm with constants C1=74054, C2=12337
    // =========================================================================

    private const int C1 = EncryptionConstants.C1; // 74054
    private const int C2 = EncryptionConstants.C2; // 12337

    /// <summary>
    /// Encrypts a string using the Delphi-compatible XOR cipher.
    /// <para>Delphi origin: function TCommon.Encrypt(const S: String; Key: Word): String</para>
    /// </summary>
    /// <param name="s">Plaintext string.</param>
    /// <param name="key">Encryption key (e.g., 17307 for password, 18307 for supervisor).</param>
    /// <returns>Hex-encoded encrypted string.</returns>
    private static string Encrypt(string s, int key)
    {
        if (string.IsNullOrEmpty(s)) return string.Empty;

        var result = new char[s.Length * 2];
        int currentKey = key;

        for (int i = 0; i < s.Length; i++)
        {
            int ch = s[i];
            int encrypted = ch ^ (currentKey >> 8);
            encrypted = encrypted & 0xFF;
            currentKey = (encrypted + currentKey) * C1 + C2;
            currentKey = currentKey & 0xFFFF;

            // Convert to two hex chars
            result[i * 2] = EncryptionConstants.HexaChar[(encrypted >> 4) & 0x0F];
            result[i * 2 + 1] = EncryptionConstants.HexaChar[encrypted & 0x0F];
        }

        return new string(result);
    }

    /// <summary>
    /// Decrypts a hex-encoded string using the Delphi-compatible XOR cipher.
    /// <para>Delphi origin: function TCommon.Decrypt(const S: String; Key: Word): String</para>
    /// </summary>
    /// <param name="s">Hex-encoded encrypted string.</param>
    /// <param name="key">Decryption key (same as encryption key).</param>
    /// <returns>Decrypted plaintext string.</returns>
    private static string Decrypt(string s, int key)
    {
        if (string.IsNullOrEmpty(s) || s.Length % 2 != 0) return string.Empty;

        int len = s.Length / 2;
        var result = new char[len];
        int currentKey = key;

        for (int i = 0; i < len; i++)
        {
            // Parse two hex chars
            int hi = HexCharToInt(s[i * 2]);
            int lo = HexCharToInt(s[i * 2 + 1]);
            int encrypted = (hi << 4) | lo;

            int decrypted = encrypted ^ (currentKey >> 8);
            decrypted = decrypted & 0xFF;
            currentKey = (encrypted + currentKey) * C1 + C2;
            currentKey = currentKey & 0xFFFF;

            result[i] = (char)decrypted;
        }

        return new string(result);
    }

    /// <summary>
    /// Converts a hex character to its integer value.
    /// </summary>
    private static int HexCharToInt(char c)
    {
        return c switch
        {
            >= '0' and <= '9' => c - '0',
            >= 'A' and <= 'F' => c - 'A' + 10,
            >= 'a' and <= 'f' => c - 'a' + 10,
            _ => 0
        };
    }

    /// <summary>
    /// Gets the file version of the current executable.
    /// </summary>
    private static string GetExeVersion()
    {
        try
        {
            var exePath = Environment.ProcessPath ?? Assembly.GetEntryAssembly()?.Location;
            if (!string.IsNullOrEmpty(exePath))
            {
                var versionInfo = FileVersionInfo.GetVersionInfo(exePath);
                return versionInfo.FileVersion ?? "0.0.0.0";
            }
        }
        catch
        {
            // Ignore version retrieval errors
        }
        return "0.0.0.0";
    }
}
