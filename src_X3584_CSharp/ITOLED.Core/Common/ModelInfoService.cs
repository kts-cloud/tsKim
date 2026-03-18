// =============================================================================
// ModelInfoService.cs
// Implements IModelInfoService — loads and parses MCF model configuration files.
// MCF files are INI format located at MODEL\{modelName}\{modelName}.mcf
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Models;

namespace Dongaeltek.ITOLED.Core.Common;

public class ModelInfoService : IModelInfoService
{
    private readonly IPathManager _pathManager;
    private readonly IConfigurationService _configService;
    private IniFileHelper? _mcfIni;

    // =========================================================================
    // Parsed data (accessible by UI)
    // =========================================================================

    public ModelInfo ModelData { get; private set; } = new();
    public ModelInfo2 ModelData2 { get; private set; } = new();
    public ModelInfoPG PgData { get; private set; } = new();
    public ModelInfoFlow FlowData { get; private set; } = new();
    public List<PatternGroupItem> PatternItems { get; private set; } = new();

    /// <summary>Pattern group name from [MODEL_INFO] Pattern_Group.</summary>
    public string PatternGroupName { get; set; } = string.Empty;

    // =========================================================================
    // IModelInfoService implementation
    // =========================================================================

    public string CurrentModelName { get; private set; } = string.Empty;
    public bool IsModelLoaded { get; private set; }
    public event EventHandler<ModelLoadedEventArgs>? ModelLoaded;

    public ModelInfoService(IPathManager pathManager, IConfigurationService configService)
    {
        _pathManager = pathManager ?? throw new ArgumentNullException(nameof(pathManager));
        _configService = configService ?? throw new ArgumentNullException(nameof(configService));
    }

    public bool LoadModel(string modelName)
    {
        if (string.IsNullOrWhiteSpace(modelName))
            return false;

        var mcfPath = Path.Combine(_pathManager.ModelRootDir, modelName, modelName + ".mcf");
        if (!File.Exists(mcfPath))
            return false;

        _mcfIni?.Dispose();
        _mcfIni = new IniFileHelper(mcfPath);
        _pathManager.SetCurrentModel(modelName);
        CurrentModelName = modelName;

        ParseModelInfo();
        ParseModelInfo2();
        ParsePgResolutionAndTiming();
        ParsePowerData();
        ParsePatternData();
        ParseFlowData();

        IsModelLoaded = true;
        ModelLoaded?.Invoke(this, new ModelLoadedEventArgs(modelName, false));
        return true;
    }

    public bool ReloadCurrentModel()
    {
        if (string.IsNullOrEmpty(CurrentModelName))
            return false;

        var result = LoadModel(CurrentModelName);
        if (result)
            ModelLoaded?.Invoke(this, new ModelLoadedEventArgs(CurrentModelName, true));
        return result;
    }

    public IReadOnlyList<string> GetAvailableModels()
    {
        if (!Directory.Exists(_pathManager.ModelRootDir))
            return Array.Empty<string>();

        return Directory.GetDirectories(_pathManager.ModelRootDir)
            .Select(Path.GetFileName)
            .Where(n => !string.IsNullOrEmpty(n))
            .OrderBy(n => n)
            .ToList()!;
    }

    public string GetModelValue(string section, string key, string defaultValue = "")
        => _mcfIni?.ReadString(section, key, defaultValue) ?? defaultValue;

    public int GetModelValueInt(string section, string key, int defaultValue = 0)
        => _mcfIni?.ReadInteger(section, key, defaultValue) ?? defaultValue;

    public double GetModelValueDouble(string section, string key, double defaultValue = 0.0)
        => _mcfIni?.ReadFloat(section, key, defaultValue) ?? defaultValue;

    public void SetModelValue(string section, string key, string value)
        => _mcfIni?.WriteString(section, key, value);

    public void SaveModelConfig()
    {
        if (_mcfIni is null) return;

        WriteModelInfo();
        WriteModelInfo2();
        WritePgResolutionAndTiming();
        WritePowerData();
        WritePatternData();
        WriteFlowData();

        _mcfIni.Flush();
    }

    // =========================================================================
    // Writers — write parsed data back to MCF INI
    // =========================================================================

    private void WriteModelInfo()
    {
        if (_mcfIni is null) return;
        const string S = "MODEL_INFO";
        var m = ModelData;

        _mcfIni.WriteInteger(S, "SigType", m.SigType);
        _mcfIni.WriteInteger(S, "Freq", (int)m.Freq);
        _mcfIni.WriteInteger(S, "H_Active", m.HActive);
        _mcfIni.WriteInteger(S, "H_BP", m.HBP);
        _mcfIni.WriteInteger(S, "H_Width", m.HWidth);
        _mcfIni.WriteInteger(S, "H_FP", m.HFP);
        _mcfIni.WriteInteger(S, "V_Active", m.VActive);
        _mcfIni.WriteInteger(S, "V_BP", m.VBP);
        _mcfIni.WriteInteger(S, "V_Width", m.VWidth);
        _mcfIni.WriteInteger(S, "V_FP", m.VFP);
        _mcfIni.WriteInteger(S, "VLCD", m.ELVDD);
        _mcfIni.WriteInteger(S, "VEL", m.ELVSS);
        _mcfIni.WriteInteger(S, "VCC", m.DDVDH);

        for (int i = 0; i < 6; i++)
        {
            _mcfIni.WriteInteger(S, $"PWR_VOL_{i}", m.PwrVol[i]);
            _mcfIni.WriteInteger(S, $"PWR_CUR_HL_{i}", m.PwrCurHL[i]);
            _mcfIni.WriteInteger(S, $"PWR_CUR_LL_{i}", m.PwrCurLL[i]);
            _mcfIni.WriteInteger(S, $"PWR_VOL_HL_{i}", m.PwrVolHL[i]);
            _mcfIni.WriteInteger(S, $"PWR_VOL_LL_{i}", m.PwrVolLL[i]);
        }

        for (int i = 0; i < 3; i++)
        {
            _mcfIni.WriteInteger(S, $"PWR_VOL_HL2_{i}", m.PwrVolHL2[i]);
            _mcfIni.WriteInteger(S, $"PWR_VOL_LL2_{i}", m.PwrVolLL2[i]);
            _mcfIni.WriteInteger(S, $"PWR_CUR_HL2_{i}", m.PwrCurHL2[i]);
            _mcfIni.WriteInteger(S, $"PWR_CUR_LL2_{i}", m.PwrCurLL2[i]);
        }

        _mcfIni.WriteString(S, "Pattern_Group", PatternGroupName);
    }

    private void WriteModelInfo2()
    {
        if (_mcfIni is null) return;
        const string S = "MODEL_INFO2";
        var m = ModelData2;

        _mcfIni.WriteString(S, "PatGrpName", m.PatGrpName);
        _mcfIni.WriteString(S, "ConfigName", m.ConfigName);
        _mcfIni.WriteString(S, "CheckSum", m.CheckSum);
        _mcfIni.WriteInteger(S, "Z_AXIS", m.ZAxis);
    }

    private void WritePgResolutionAndTiming()
    {
        if (_mcfIni is null) return;
        var conf = PgData.PgModelConf;

        // [MODEL_RESOLUTION]
        const string R = "MODEL_RESOLUTION";
        _mcfIni.WriteInteger(R, "H_Active", conf.HActive);
        _mcfIni.WriteInteger(R, "H_BP", conf.HBp);
        _mcfIni.WriteInteger(R, "H_SA", conf.HSa);
        _mcfIni.WriteInteger(R, "H_FP", conf.HFp);
        _mcfIni.WriteInteger(R, "V_Active", conf.VActive);
        _mcfIni.WriteInteger(R, "V_BP", conf.VBp);
        _mcfIni.WriteInteger(R, "V_SA", conf.VSa);
        _mcfIni.WriteInteger(R, "V_FP", conf.VFp);

        // [MODEL_TIMING]
        const string T = "MODEL_TIMING";
        _mcfIni.WriteInteger(T, "link_rate", (int)conf.LinkRate);
        _mcfIni.WriteInteger(T, "lane", conf.Lane);
        _mcfIni.WriteInteger(T, "Vsync", conf.Vsync);
        _mcfIni.WriteString(T, "RGBFormat", conf.RgbFormat);
        _mcfIni.WriteInteger(T, "ALPM_Mode", conf.AlpmMode);
        _mcfIni.WriteInteger(T, "vfb_offset", conf.VfbOffset);

        // [MODEL_ALPDP]
        const string A = "MODEL_ALPDP";
        _mcfIni.WriteInteger(A, "h_fdp", conf.HFdp);
        _mcfIni.WriteInteger(A, "h_sdp", conf.HSdp);
        _mcfIni.WriteInteger(A, "h_pcnt", conf.HPcnt);
        _mcfIni.WriteInteger(A, "vb_n5b", conf.VbN5b);
        _mcfIni.WriteInteger(A, "vb_n7", conf.VbN7);
        _mcfIni.WriteInteger(A, "vb_n5a", conf.VbN5a);
        _mcfIni.WriteInteger(A, "vb_sleep", conf.VbSleep);
        _mcfIni.WriteInteger(A, "vb_n2", conf.VbN2);
        _mcfIni.WriteInteger(A, "vb_n3", conf.VbN3);
        _mcfIni.WriteInteger(A, "vb_n4", conf.VbN4);
        _mcfIni.WriteInteger(A, "m_vid", conf.MVid);
        _mcfIni.WriteInteger(A, "n_vid", conf.NVid);
        _mcfIni.WriteInteger(A, "misc_0", conf.Misc0);
        _mcfIni.WriteInteger(A, "misc_1", conf.Misc1);
        _mcfIni.WriteInteger(A, "xpol", conf.Xpol);
        _mcfIni.WriteInteger(A, "xdelay", conf.Xdelay);
        _mcfIni.WriteInteger(A, "h_mg", conf.HMg);
        _mcfIni.WriteInteger(A, "NoAux_Sel", conf.NoAuxSel);
        _mcfIni.WriteInteger(A, "NoAux_Active", conf.NoAuxActive);
        _mcfIni.WriteInteger(A, "NoAux_Sleep", conf.NoAuxSleep);
        _mcfIni.WriteInteger(A, "critical_section", conf.CriticalSection);
        _mcfIni.WriteInteger(A, "tps", conf.Tps);
        _mcfIni.WriteInteger(A, "v_blank", conf.VBlank);
        _mcfIni.WriteInteger(A, "chop_enable", conf.ChopEnable);
        _mcfIni.WriteInteger(A, "chop_interval", conf.ChopInterval);
        _mcfIni.WriteInteger(A, "chop_size", conf.ChopSize);
    }

    private void WritePowerData()
    {
        if (_mcfIni is null) return;

        // [POWER_DATA]
        const string P = "POWER_DATA";
        var pwr = PgData.PgPwrData;
        _mcfIni.WriteInteger(P, "PWR_SLOPE", pwr.PwrSlope);

        for (int i = 0; i <= PgPowerIndex.Max; i++)
        {
            _mcfIni.WriteString(P, $"PWR_NAME_{i}", pwr.PwrName[i]);
            _mcfIni.WriteInteger(P, $"PWR_VOL_{i}", (int)pwr.PwrVol[i]);
            _mcfIni.WriteInteger(P, $"PWR_VOL_LL_{i}", (int)pwr.PwrVolLl[i]);
            _mcfIni.WriteInteger(P, $"PWR_VOL_HL_{i}", (int)pwr.PwrVolHl[i]);
            _mcfIni.WriteInteger(P, $"PWR_CUR_LL_{i}", (int)pwr.PwrCurLl[i]);
            _mcfIni.WriteInteger(P, $"PWR_CUR_HL_{i}", (int)pwr.PwrCurHl[i]);
        }

        // [POWER_SEQUENCE]
        const string PS = "POWER_SEQUENCE";
        var seq = PgData.PgPwrSeq;
        for (int i = 0; i <= PgPowerIndex.SeqMax; i++)
        {
            _mcfIni.WriteInteger(PS, $"PWR_SEQ_ON_{i}", seq.SeqOn[i]);
            _mcfIni.WriteInteger(PS, $"PWR_SEQ_OFF_{i}", seq.SeqOff[i]);
        }
    }

    private void WritePatternData()
    {
        if (_mcfIni is null) return;
        const string S = "PatternData";

        _mcfIni.WriteInteger(S, "pattern_count", PatternItems.Count);
        for (int i = 0; i < PatternItems.Count; i++)
        {
            var p = PatternItems[i];
            _mcfIni.WriteString(S, $"PatName{i}", p.Name);
            _mcfIni.WriteInteger(S, $"PatType{i}", p.PatType);
            _mcfIni.WriteInteger(S, $"PatIdx{i}", p.PatIdx);
        }
    }

    private void WriteFlowData()
    {
        if (_mcfIni is null) return;
        const string S = "FLOW_DATA";
        var f = FlowData;

        _mcfIni.WriteInteger(S, "MODELTYPE", f.ModelType);
        _mcfIni.WriteString(S, "MODEL_TYPE_NAME", f.ModelTypeName);
        _mcfIni.WriteString(S, "MODEL_FILE_NAME", f.ModelFileName);
        _mcfIni.WriteString(S, "ProcessName", f.ProcessName);
        _mcfIni.WriteString(S, "PatGrpName", f.PatGrpName);
        _mcfIni.WriteBool(S, "UseDutDetect", f.UseDutDetect);
        _mcfIni.WriteInteger(S, "BcrLength", f.BcrLength);
        _mcfIni.WriteInteger(S, "Ca410MemCh", f.Ca410MemCh);
        _mcfIni.WriteInteger(S, "NVMINITMODE", f.UseNvmInit);
        _mcfIni.WriteBool(S, "IDLE_MODE", f.IdleMode);
        _mcfIni.WriteInteger(S, "IDLEMODEDTIME", f.IdleModeDTime);
        _mcfIni.WriteBool(S, "USE_CHECK_VERSION", f.UseCheckVer);
        _mcfIni.WriteBool(S, "USE_CHECK_ReProgramming", f.UseCheckReProgramming);
        _mcfIni.WriteInteger(S, "USE_CHECK_NVMWriteSequence", f.UseCkNVMWriteSequence);
        _mcfIni.WriteBool(S, "USE_CHECK_TCONWRITECHECKSUM", f.UseTconWriteChecksum);
        _mcfIni.WriteBool(S, "USE_IONIZER_ON_OFF", f.UseIonOnOff);
        _mcfIni.WriteInteger(S, "SERIALNO_ADDR", (int)f.SerialNoFlashInfo.Address);
        _mcfIni.WriteInteger(S, "SERIALNO_LENGTH", (int)f.SerialNoFlashInfo.Length);
    }

    // =========================================================================
    // Parsers
    // =========================================================================

    private void ParseModelInfo()
    {
        if (_mcfIni is null) return;
        const string S = "MODEL_INFO";

        var m = new ModelInfo();
        m.SigType = (byte)_mcfIni.ReadInteger(S, "SigType", 0);
        m.Freq = (uint)_mcfIni.ReadInteger(S, "Freq", 0);
        m.HActive = (ushort)_mcfIni.ReadInteger(S, "H_Active", 0);
        m.HBP = (ushort)_mcfIni.ReadInteger(S, "H_BP", 0);
        m.HWidth = (ushort)_mcfIni.ReadInteger(S, "H_Width", 0);
        m.HFP = (ushort)_mcfIni.ReadInteger(S, "H_FP", 0);
        m.VActive = (ushort)_mcfIni.ReadInteger(S, "V_Active", 0);
        m.VBP = (ushort)_mcfIni.ReadInteger(S, "V_BP", 0);
        m.VWidth = (ushort)_mcfIni.ReadInteger(S, "V_Width", 0);
        m.VFP = (ushort)_mcfIni.ReadInteger(S, "V_FP", 0);
        m.ELVDD = (ushort)_mcfIni.ReadInteger(S, "VLCD", 0);
        m.ELVSS = (ushort)_mcfIni.ReadInteger(S, "VEL", 0);
        m.DDVDH = (ushort)_mcfIni.ReadInteger(S, "VCC", 0);

        // Power voltage / current arrays from MODEL_INFO section
        for (int i = 0; i < 6; i++)
        {
            m.PwrVol[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_VOL_{i}", 0);
            m.PwrCurHL[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_CUR_HL_{i}", 0);
            m.PwrCurLL[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_CUR_LL_{i}", 0);
            m.PwrVolHL[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_VOL_HL_{i}", 0);
            m.PwrVolLL[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_VOL_LL_{i}", 0);
        }

        for (int i = 0; i < 3; i++)
        {
            m.PwrVolHL2[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_VOL_HL2_{i}", 0);
            m.PwrVolLL2[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_VOL_LL2_{i}", 0);
            m.PwrCurHL2[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_CUR_HL2_{i}", 0);
            m.PwrCurLL2[i] = (ushort)_mcfIni.ReadInteger(S, $"PWR_CUR_LL2_{i}", 0);
        }

        PatternGroupName = _mcfIni.ReadString(S, "Pattern_Group", "");
        ModelData = m;
    }

    private void ParseModelInfo2()
    {
        if (_mcfIni is null) return;
        const string S = "MODEL_INFO2";

        ModelData2 = new ModelInfo2
        {
            PatGrpName = _mcfIni.ReadString(S, "PatGrpName", ""),
            ConfigName = _mcfIni.ReadString(S, "ConfigName", ""),
            CheckSum = _mcfIni.ReadString(S, "CheckSum", ""),
            ZAxis = _mcfIni.ReadInteger(S, "Z_AXIS", 0),
        };
    }

    private void ParsePgResolutionAndTiming()
    {
        if (_mcfIni is null) return;

        var pg = new ModelInfoPG();
        var conf = pg.PgModelConf;

        // [MODEL_RESOLUTION]
        const string R = "MODEL_RESOLUTION";
        conf.HActive = (ushort)_mcfIni.ReadInteger(R, "H_Active", 0);
        conf.HBp = (ushort)_mcfIni.ReadInteger(R, "H_BP", 0);
        conf.HSa = (ushort)_mcfIni.ReadInteger(R, "H_SA", 0);
        conf.HFp = (ushort)_mcfIni.ReadInteger(R, "H_FP", 0);
        conf.VActive = (ushort)_mcfIni.ReadInteger(R, "V_Active", 0);
        conf.VBp = (ushort)_mcfIni.ReadInteger(R, "V_BP", 0);
        conf.VSa = (ushort)_mcfIni.ReadInteger(R, "V_SA", 0);
        conf.VFp = (ushort)_mcfIni.ReadInteger(R, "V_FP", 0);

        // [MODEL_TIMING]
        const string T = "MODEL_TIMING";
        conf.LinkRate = (uint)_mcfIni.ReadInteger(T, "link_rate", 0);
        conf.Lane = _mcfIni.ReadInteger(T, "lane", 0);
        conf.Vsync = _mcfIni.ReadInteger(T, "Vsync", 0);
        conf.RgbFormat = _mcfIni.ReadString(T, "RGBFormat", "");
        conf.AlpmMode = _mcfIni.ReadInteger(T, "ALPM_Mode", 0);
        conf.VfbOffset = _mcfIni.ReadInteger(T, "vfb_offset", 0);

        // [MODEL_ALPDP]
        const string A = "MODEL_ALPDP";
        conf.HFdp = _mcfIni.ReadInteger(A, "h_fdp", 0);
        conf.HSdp = _mcfIni.ReadInteger(A, "h_sdp", 0);
        conf.HPcnt = _mcfIni.ReadInteger(A, "h_pcnt", 0);
        conf.VbN5b = _mcfIni.ReadInteger(A, "vb_n5b", 0);
        conf.VbN7 = _mcfIni.ReadInteger(A, "vb_n7", 0);
        conf.VbN5a = _mcfIni.ReadInteger(A, "vb_n5a", 0);
        conf.VbSleep = _mcfIni.ReadInteger(A, "vb_sleep", 0);
        conf.VbN2 = _mcfIni.ReadInteger(A, "vb_n2", 0);
        conf.VbN3 = _mcfIni.ReadInteger(A, "vb_n3", 0);
        conf.VbN4 = _mcfIni.ReadInteger(A, "vb_n4", 0);
        conf.MVid = _mcfIni.ReadInteger(A, "m_vid", 0);
        conf.NVid = _mcfIni.ReadInteger(A, "n_vid", 0);
        conf.Misc0 = _mcfIni.ReadInteger(A, "misc_0", 0);
        conf.Misc1 = _mcfIni.ReadInteger(A, "misc_1", 0);
        conf.Xpol = _mcfIni.ReadInteger(A, "xpol", 0);
        conf.Xdelay = _mcfIni.ReadInteger(A, "xdelay", 0);
        conf.HMg = _mcfIni.ReadInteger(A, "h_mg", 0);
        conf.NoAuxSel = _mcfIni.ReadInteger(A, "NoAux_Sel", 0);
        conf.NoAuxActive = _mcfIni.ReadInteger(A, "NoAux_Active", 0);
        conf.NoAuxSleep = _mcfIni.ReadInteger(A, "NoAux_Sleep", 0);
        conf.CriticalSection = _mcfIni.ReadInteger(A, "critical_section", 0);
        conf.Tps = _mcfIni.ReadInteger(A, "tps", 0);
        conf.VBlank = _mcfIni.ReadInteger(A, "v_blank", 0);
        conf.ChopEnable = _mcfIni.ReadInteger(A, "chop_enable", 0);
        conf.ChopInterval = _mcfIni.ReadInteger(A, "chop_interval", 0);
        conf.ChopSize = _mcfIni.ReadInteger(A, "chop_size", 0);

        pg.PgModelConf = conf;
        PgData = pg;
    }

    private void ParsePowerData()
    {
        if (_mcfIni is null) return;

        // [POWER_DATA]
        const string P = "POWER_DATA";
        var pwr = PgData.PgPwrData;
        pwr.PwrSlope = _mcfIni.ReadInteger(P, "PWR_SLOPE", 0);

        int maxPwr = PgPowerIndex.Max;
        for (int i = 0; i <= maxPwr; i++)
        {
            pwr.PwrName[i] = _mcfIni.ReadString(P, $"PWR_NAME_{i}", "");
            pwr.PwrVol[i] = (uint)_mcfIni.ReadInteger(P, $"PWR_VOL_{i}", 0);
            pwr.PwrVolLl[i] = (uint)_mcfIni.ReadInteger(P, $"PWR_VOL_LL_{i}", 0);
            pwr.PwrVolHl[i] = (uint)_mcfIni.ReadInteger(P, $"PWR_VOL_HL_{i}", 0);
            pwr.PwrCurLl[i] = (uint)_mcfIni.ReadInteger(P, $"PWR_CUR_LL_{i}", 0);
            pwr.PwrCurHl[i] = (uint)_mcfIni.ReadInteger(P, $"PWR_CUR_HL_{i}", 0);
        }

        // [POWER_SEQUENCE]
        const string PS = "POWER_SEQUENCE";
        var seq = PgData.PgPwrSeq;
        int seqMax = PgPowerIndex.SeqMax;
        for (int i = 0; i <= seqMax; i++)
        {
            seq.SeqOn[i] = _mcfIni.ReadInteger(PS, $"PWR_SEQ_ON_{i}", 0);
            seq.SeqOff[i] = _mcfIni.ReadInteger(PS, $"PWR_SEQ_OFF_{i}", 0);
        }
    }

    private void ParsePatternData()
    {
        if (_mcfIni is null) return;
        const string S = "PatternData";

        var items = new List<PatternGroupItem>();
        int count = _mcfIni.ReadInteger(S, "pattern_count", 0);

        // MCF pattern data uses 0-based index keys: PatType0, PatIdx0, PatName0, ...
        // Read as many entries as exist (some MCFs have more entries than pattern_count)
        for (int i = 0; i < 100; i++) // safe upper bound
        {
            var name = _mcfIni.ReadString(S, $"PatName{i}", "");
            if (string.IsNullOrEmpty(name) && i >= count) break;

            items.Add(new PatternGroupItem(
                Index: i,
                Name: name,
                PatType: _mcfIni.ReadInteger(S, $"PatType{i}", 0),
                PatIdx: _mcfIni.ReadInteger(S, $"PatIdx{i}", 0)));
        }

        PatternItems = items;
    }

    private void ParseFlowData()
    {
        if (_mcfIni is null) return;
        const string S = "FLOW_DATA";

        FlowData = new ModelInfoFlow
        {
            ModelType = _mcfIni.ReadInteger(S, "MODELTYPE", 0),
            ModelTypeName = _mcfIni.ReadString(S, "MODEL_TYPE_NAME", ""),
            ModelFileName = _mcfIni.ReadString(S, "MODEL_FILE_NAME", ""),
            ProcessName = _mcfIni.ReadString(S, "ProcessName", ""),
            PatGrpName = _mcfIni.ReadString(S, "PatGrpName", ""),
            UseDutDetect = _mcfIni.ReadBool(S, "UseDutDetect", false),
            BcrLength = _mcfIni.ReadInteger(S, "BcrLength", 0),
            Ca410MemCh = _mcfIni.ReadInteger(S, "Ca410MemCh", 0),
            UseNvmInit = _mcfIni.ReadInteger(S, "NVMINITMODE", 0),
            IdleMode = _mcfIni.ReadBool(S, "IDLE_MODE", false),
            IdleModeDTime = _mcfIni.ReadInteger(S, "IDLEMODEDTIME", 0),
            UseCheckVer = _mcfIni.ReadBool(S, "USE_CHECK_VERSION", false),
            UseCheckReProgramming = _mcfIni.ReadBool(S, "USE_CHECK_ReProgramming", false),
            UseCkNVMWriteSequence = _mcfIni.ReadInteger(S, "USE_CHECK_NVMWriteSequence", 0),
            UseTconWriteChecksum = _mcfIni.ReadBool(S, "USE_CHECK_TCONWRITECHECKSUM", false),
            UseIonOnOff = _mcfIni.ReadBool(S, "USE_IONIZER_ON_OFF", false),
            SerialNoFlashInfo = new ModelParamSerialNoFlash
            {
                Address = (uint)_mcfIni.ReadInteger(S, "SERIALNO_ADDR", 0),
                Length = (uint)_mcfIni.ReadInteger(S, "SERIALNO_LENGTH", 0),
            },
        };
    }
}

/// <summary>
/// UI display record for pattern data entries from MCF [PatternData] section.
/// </summary>
public record PatternGroupItem(int Index, string Name, int PatType, int PatIdx);
