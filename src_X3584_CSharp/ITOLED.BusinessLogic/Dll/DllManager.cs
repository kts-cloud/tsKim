// =============================================================================
// DllManager.cs
// Converted from Delphi: src_X3584\dllClass.pas (TCSharpDll class, ~1788 lines)
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Dll
//
// Manages the OC inspection flow lifecycle by directly loading Factory DLLs
// (LGD_OC_X3584.dll, etc.) via OcFlowOrchestrator. OC_Converter_X3584.dll
// has been completely removed — its role (JSON parsing, Factory DLL loading,
// callback bridging) is now handled by:
//   - OcFlowOrchestrator: Factory DLL load + CompensationFlow lifecycle
//   - HardwareBridge: X2146_API → ICommPgDriver delegation
//   - OcMeasurementBridge: IMeasurement → ICaSdk2Driver delegation
//   - FactoryAssemblyLoadContext: shared-type ALC for type identity
//
// DI dependencies:
//   - IConfigurationService: system configuration (paths, channel count, etc.)
//   - ILogger:               custom logging (Dongaeltek.ITOLED.Core.Interfaces)
//   - IMessageBus:           replaces WM_COPYDATA inter-form messaging
//   - ICaSdk2Driver:         CA-410 colorimeter measurement
//   - ICommPgDriver[]:       per-channel PG drivers
// =============================================================================

using System.Text;
using System.Text.Json;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.BusinessLogic.Dll;

// =============================================================================
// DllManager implementation
// =============================================================================

/// <summary>
/// Manages the OC inspection DLL lifecycle, flow control, and data retrieval.
/// <para>Original Delphi: <c>TCSharpDll</c> class in dllClass.pas (~1788 lines).</para>
/// <para>
/// Factory DLLs (LGD_OC_X3584.dll, etc.) are loaded directly via
/// <see cref="OcFlowOrchestrator"/> with custom <see cref="FactoryAssemblyLoadContext"/>
/// for type identity. The former OC_Converter_X3584.dll intermediary has been removed.
/// </para>
/// </summary>
public sealed class DllManager : IDllManager
{
    // ---- Dependencies ----
    private readonly IConfigurationService _config;
    private readonly ILogger _logger;
    private readonly IMessageBus _messageBus;
    private readonly ICaSdk2Driver _caSdk2;
    private readonly IPathManager? _pathManager;
    private readonly ICommPgDriver[] _pg;

    // ---- State ----
    private bool _initialized;
    private bool _disposed;

    // ---- Per-channel state ----
    private readonly int _channelCount;

    private readonly bool[] _ocFlowStart;
    private readonly bool[] _isDllWork;
    private readonly bool[] _isProcessDone;
    private readonly bool[] _isProcessUnloadDone;
    private readonly bool[] _ocCheckSerialNb;
    private readonly string[] _serialNo;
    private readonly int[] _currentBand;
    private readonly int[] _preActionNg;
    private readonly int[] _countInspections;
    private readonly int[] _dllType;

    // ---- Alive-check timers ----
    private readonly System.Timers.Timer?[] _aliveCheckTimers;

    // ---- OcFlowOrchestrator ----
    private OcFlowOrchestrator? _orchestrator;
    // GC pinning — LGD DLL에 전달하는 delegate를 필드에 유지하여 GC 수집 방지
    private Action<int, string>? _dllLogCallback;

    // ---- DLL directory ----
    private readonly string _dllPath;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a new DllManager.
    /// <para>Original Delphi: <c>TCSharpDll.Create(hMain, hTest, sDLLPath, sFileName, nModelType)</c></para>
    /// </summary>
    public DllManager(
        IConfigurationService config,
        ILogger logger,
        IMessageBus messageBus,
        ICaSdk2Driver caSdk2,
        string dllPath,
        IPathManager? pathManager = null,
        ICommPgDriver[]? pg = null,
        int modelType = 0)
    {
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _pathManager = pathManager;
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _caSdk2 = caSdk2 ?? throw new ArgumentNullException(nameof(caSdk2));
        _pg = pg ?? Array.Empty<ICommPgDriver>();
        _dllPath = dllPath;

        _channelCount = ChannelConstants.MaxCh + 1; // CH1..MAX_CH (0-based)

        // Allocate per-channel arrays
        _ocFlowStart = new bool[_channelCount];
        _isDllWork = new bool[_channelCount];
        _isProcessDone = new bool[_channelCount];
        _isProcessUnloadDone = new bool[_channelCount];
        // Default ProcessUnloadDone to true so channels that haven't inspected don't block unload
        for (int i = 0; i < _channelCount; i++)
            _isProcessUnloadDone[i] = true;
        _ocCheckSerialNb = new bool[_channelCount];
        _serialNo = new string[_channelCount];
        _currentBand = new int[_channelCount];
        _preActionNg = new int[_channelCount];
        _countInspections = new int[_channelCount];
        _dllType = new int[_channelCount];
        _aliveCheckTimers = new System.Timers.Timer?[_channelCount];

        // Initialize per-channel state
        for (var i = 0; i < _channelCount; i++)
        {
            _serialNo[i] = string.Empty;

            var timer = new System.Timers.Timer(1000);
            var ch = i; // capture for closure
            timer.Elapsed += (_, _) => OnAliveCheckTimer(ch);
            timer.AutoReset = true;
            timer.Enabled = false;
            _aliveCheckTimers[i] = timer;
        }

        NgMessage = string.Empty;

        try
        {
            _initialized = true;
            PublishMainFormMessage(0, MsgType.Dll, "Direct Factory DLL", param: 3);
        }
        catch (Exception ex)
        {
            NgMessage = $"DllManager init failed: {ex.Message}";
            _logger.Error("Failed to initialize DllManager", ex);
        }
    }

    // =========================================================================
    // IDllManager — Properties
    // =========================================================================

    /// <inheritdoc />
    public string NgMessage { get; private set; } = string.Empty;

    /// <inheritdoc />
    public bool IsLoaded => _initialized;

    /// <inheritdoc />
    public string LgdDllName { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string OcConDllName { get; private set; } = string.Empty;

    /// <inheritdoc />
    public string OcConverterVersion { get; private set; } = string.Empty;

    /// <inheritdoc />
    public bool IsFlowRunning(int channel) => ValidateChannel(channel) && _ocFlowStart[channel];

    /// <inheritdoc />
    public bool IsDllWorking(int channel) => ValidateChannel(channel) && _isDllWork[channel];

    /// <inheritdoc />
    public bool IsProcessDone(int channel) => ValidateChannel(channel) && _isProcessDone[channel];

    /// <inheritdoc />
    public bool IsProcessUnloadDone(int channel) => ValidateChannel(channel) && _isProcessUnloadDone[channel];

    /// <inheritdoc />
    public int GetCurrentBand(int channel) => ValidateChannel(channel) ? _currentBand[channel] : 0;

    /// <inheritdoc />
    public int GetPreActionNg(int channel) => ValidateChannel(channel) ? _preActionNg[channel] : 0;

    /// <inheritdoc />
    public void SetPreActionNg(int channel, int value)
    {
        if (ValidateChannel(channel))
            _preActionNg[channel] = value;
    }

    /// <inheritdoc />
    public bool GetSerialNumberCheckFlag(int channel) => ValidateChannel(channel) && _ocCheckSerialNb[channel];

    /// <inheritdoc />
    public void SetSerialNumberCheckFlag(int channel, bool value)
    {
        if (ValidateChannel(channel))
            _ocCheckSerialNb[channel] = value;
    }

    /// <inheritdoc />
    public void SetDllWorking(int channel, bool value)
    {
        if (ValidateChannel(channel))
            _isDllWork[channel] = value;
    }

    /// <inheritdoc />
    public void SetProcessDone(int channel, bool value)
    {
        if (ValidateChannel(channel))
            _isProcessDone[channel] = value;
    }

    /// <inheritdoc />
    public void SetProcessUnloadDone(int channel, bool value)
    {
        if (ValidateChannel(channel))
            _isProcessUnloadDone[channel] = value;
    }

    // =========================================================================
    // IDllManager — Initialization
    // =========================================================================

    /// <inheritdoc />
    public void Initialize(string modelName)
    {
        if (!IsLoaded)
            return;

        try
        {
            // Load JSON configuration from file
            var iniDir = _pathManager?.IniDir ?? _config.GetString("PATH", "INI", ".\\");
            var configPath = Path.Combine(iniDir, "OC_Factory_Config.json");

            string configJson;
            if (File.Exists(configPath))
            {
                configJson = File.ReadAllText(configPath, Encoding.UTF8);
            }
            else
            {
                configJson = "[]";
                PublishMainFormMessage(0, MsgMode.AddLog, "Config file not found: OC_Factory_Config.json");
            }

            // Normalize DllPath separators (forward slash → backslash)
            configJson = NormalizeDllPathSeparators(configJson);

            // Parse configuration JSON
            var configs = new List<OcFactoryConfig>();
            try
            {
                configs = JsonSerializer.Deserialize<List<OcFactoryConfig>>(configJson)
                          ?? new List<OcFactoryConfig>();
            }
            catch (JsonException ex)
            {
                _logger.Warn($"Failed to parse OC_Factory_Config.json: {ex.Message}");
            }

            // Create and initialize orchestrator
            // delegate를 필드에 보관 → GC가 수집하지 못하도록 (LGD DLL 내부 캐시 포인터 보호)
            _dllLogCallback = (ch, msg) => PublishTestFormMessage(ch, MsgMode.Working, msg);
            _orchestrator = new OcFlowOrchestrator(_logger);
            _orchestrator.Initialize(
                _dllPath,
                _channelCount,
                modelName,
                configs,
                _pg,
                _caSdk2,
                _dllLogCallback);

            // Retrieve versions for each DLL index
            ProcessFactoryConfigVersions(configs);

            // Get Converter version (our own assembly version)
            var converterVersion = _orchestrator.GetConverterVersion();
            PublishMainFormMessage(0, MsgType.Dll, converterVersion, param: 2);
        }
        catch (Exception ex)
        {
            _logger.Error("DllManager.Initialize failed", ex);
        }
    }

    /// <inheritdoc />
    public void FormDestroy()
    {
        _orchestrator?.FormDestroy();
    }

    // =========================================================================
    // IDllManager — OC Flow Control
    // =========================================================================

    /// <inheritdoc />
    public int StartOcFlow(int dllType, int channel, string pid, string serialNumber,
                           string userId, string equipment)
    {
        if (!ValidateChannel(channel) || _orchestrator == null)
            return 2;

        try
        {
            _dllType[channel] = dllType;
            var parameter = $"{pid},{serialNumber},{userId},{equipment}\0";

            var debugMsg = $"{parameter}\r\nMemory usage : {GC.GetTotalMemory(false) / (1024.0 * 1024.0):F2} MB";
            PublishTestFormMessage(channel, MsgMode.Working, debugMsg);

            PublishTestFormMessage(channel, MsgMode.LogHwcid, string.Empty);

            _isProcessDone[channel] = false;
            _serialNo[channel] = serialNumber;
            _currentBand[channel] = 0;
            _countInspections[channel] = 0;

            // Compute CRC16 checksum — Delphi: crc16(sParameter, Length(sParameter)-1)
            // null 문자(\0) 제외한 길이로 계산 (Delphi Length는 null 미포함이지만 sParameter에 #0 추가됨)
            var checkSum = ComputeCrc16(parameter, parameter.Length - 1);

            // Start flow via orchestrator — paramLength도 null 제외
            var result = _orchestrator.StartFlow(dllType, channel, parameter, parameter.Length - 1, checkSum);
            if (result != 0)
                return 2;

            _ocFlowStart[channel] = true;
            _isProcessUnloadDone[channel] = false; // Reset: will be set true when Process_Finish completes
            EnableAliveCheckTimer(channel, true);
            return 0;
        }
        catch (Exception ex)
        {
            _logger.Error($"StartOcFlow failed for channel {channel}", ex);
            return 2;
        }
    }

    /// <inheritdoc />
    public int StopOcFlow(int channel)
    {
        if (!ValidateChannel(channel) || _orchestrator == null)
            return 0;

        try
        {
            _orchestrator.StopFlow(_dllType[channel], channel);
        }
        catch (Exception ex)
        {
            _logger.Warn($"StopOcFlow error on channel {channel}: {ex.Message}");
        }
        return 0;
    }

    /// <inheritdoc />
    public bool WaitForFlowComplete(int channel, int timeoutMs = 10000)
    {
        if (!ValidateChannel(channel) || _orchestrator == null)
            return true;
        return _orchestrator.WaitForFlowComplete(_dllType[channel], channel, timeoutMs);
    }

    /// <inheritdoc />
    public int StartVerify(int channel)
    {
        _logger.Warn("StartVerify called but method not available");
        return 0;
    }

    /// <inheritdoc />
    public int CheckThreadState(int channel)
    {
        _logger.Warn("CheckThreadState called but method not available");
        return 0;
    }

    /// <inheritdoc />
    public int FlashRead(int channel)
    {
        // Flash read not directly exposed through orchestrator
        return 0;
    }

    /// <inheritdoc />
    public int GetOcFlowIsAlive(int channel)
    {
        if (channel > ChannelConstants.MaxCh || _orchestrator == null)
            return 0;

        return _orchestrator.GetFlowIsAlive(_dllType[channel], channel);
    }

    // =========================================================================
    // IDllManager — Data Retrieval
    // =========================================================================

    /// <inheritdoc />
    public string GetSummaryLogData(int channel, string parameter)
    {
        if (!ValidateChannel(channel) || _orchestrator == null)
            return string.Empty;

        try
        {
            // Retry up to 3 times
            for (var i = 0; i < 3; i++)
            {
                var result = _orchestrator.GetSummaryLogData(_dllType[channel], channel, parameter);
                if (!string.IsNullOrEmpty(result))
                    return result;
            }

            // Final attempt
            return _orchestrator.GetSummaryLogData(_dllType[channel], channel, parameter);
        }
        catch (Exception ex)
        {
            _logger.Error($"GetSummaryLogData error on channel {channel}", ex);
            return string.Empty;
        }
    }

    /// <inheritdoc />
    public string GetSummaryLogDictionary(int channel)
    {
        if (!ValidateChannel(channel) || _orchestrator == null)
            return string.Empty;

        var jsonStr = _orchestrator.GetSummaryLogDictionary(_dllType[channel], channel);

        // Parse JSON and format as "OC:key:value,OC:key:value,..."
        try
        {
            using var doc = JsonDocument.Parse(jsonStr);
            var sb = new StringBuilder();

            foreach (var prop in doc.RootElement.EnumerateObject())
            {
                var key = prop.Name.Trim();
                var val = prop.Value.GetString()?.Trim() ?? prop.Value.GetRawText().Trim();

                sb.Append("OC")
                  .Append(':')
                  .Append(key)
                  .Append(':')
                  .Append(val)
                  .Append(',');
            }

            return sb.ToString();
        }
        catch (JsonException ex)
        {
            throw new InvalidOperationException("Invalid JSON from DLL", ex);
        }
    }

    /// <inheritdoc />
    public int ChangeDll(string dllName)
    {
        return 0;
    }

    // =========================================================================
    // IDllManager — Logging
    // =========================================================================

    /// <inheritdoc />
    public void AddDllLog(int channel, bool clear, string message)
    {
        if (message.Contains("Delay_Time", StringComparison.Ordinal))
            return;

        var param = clear ? 10 : 0;
        PublishTestFormMessage(channel, MsgMode.Working, message, param);
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed)
            return;
        _disposed = true;

        // Stop and dispose all timers
        for (var i = 0; i < _channelCount; i++)
        {
            if (_aliveCheckTimers[i] is { } timer)
            {
                timer.Enabled = false;
                timer.Dispose();
                _aliveCheckTimers[i] = null;
            }
        }

        // Dispose orchestrator
        _orchestrator?.Dispose();
        _orchestrator = null;

        _logger.Info("DllManager disposed");
    }

    // =========================================================================
    // Private — Alive check timer
    // =========================================================================

    private void OnAliveCheckTimer(int channel)
    {
        if (!ValidateChannel(channel))
            return;

        if (_ocFlowStart[channel] && _preActionNg[channel] != 0)
        {
            _logger.Warn($"CH{channel} <SEQUENCE> PreAction - NG : {_preActionNg[channel]}");
            _preActionNg[channel] = 0;
            StopOcFlow(channel);
            return;
        }

        if (_ocFlowStart[channel] && _ocCheckSerialNb[channel])
        {
            _ocCheckSerialNb[channel] = false;
            _logger.Warn($"CH{channel} <SEQUENCE> S/N Matching ERR({_serialNo[channel].Length}) - NG");
            StopOcFlow(channel);
            return;
        }

        // Poll IsAlive — the flow thread completion is detected here
        if (_ocFlowStart[channel] && GetOcFlowIsAlive(channel) == 0)
        {
            _ocFlowStart[channel] = false;
            EnableAliveCheckTimer(channel, false);

            int ngCode = 0;
            try
            {
                _logger.Info($"CH{channel} <SEQUENCE> CountInspections : {_countInspections[channel]}");

                var defectCode = GetSummaryLogData(channel, "DEFECT_CODE");
                _logger.Info($"CH{channel} GetSummaryLogData DEFECT_CODE: {defectCode}");

                if (_pg.Length > channel)
                    _pg[channel].Dp860SendOcOnOff(0, 2000, 0);

                if (!string.IsNullOrEmpty(defectCode) && defectCode != "XXXX")
                    ngCode = GetNgCodeByErrorCode(defectCode);
            }
            finally
            {
                // DLL flow 완료 → Flash 작업용 FTP 세션 해제 (lwIP external RX 비활성화)
                if (channel < _pg.Length)
                    _pg[channel].ReleaseFlashFtpSession();

                _isProcessDone[channel] = true;
                PublishTestFormMessage(channel, MsgMode.WorkDone, "OKFLOW_END", ngCode);
            }
        }
    }

    private void EnableAliveCheckTimer(int channel, bool enabled)
    {
        if (channel >= 0 && channel < _aliveCheckTimers.Length && _aliveCheckTimers[channel] is { } timer)
        {
            timer.Enabled = enabled;
        }
    }

    // =========================================================================
    // Private — Version retrieval during Initialize
    // =========================================================================

    private void ProcessFactoryConfigVersions(List<OcFactoryConfig> configs)
    {
        try
        {
            PublishMainFormMessage(0, MsgMode.AddLog,
                $"OC_Factory_Config.json loaded. Count: {configs.Count}");

            foreach (var config in configs)
            {
                var version = _orchestrator?.GetOcVersion(config.Id) ?? "N/A";
                if (string.IsNullOrEmpty(version))
                    version = "N/A";

                // Combine DLL filename with version for display
                // Delphi: mmoLGDDLLName.Lines.Add(format('%d : %s', [idx, sVer]))
                var dllFileName = Path.GetFileName(config.DllPath);
                var displayText = !string.IsNullOrEmpty(version)
                    && !string.Equals(version, "N/A", StringComparison.OrdinalIgnoreCase)
                    ? $"{dllFileName} [{version}]"
                    : dllFileName;

                PublishMainFormMessage(0, MsgMode.AddLog,
                    $"Processing DLL Index {config.Id}: {displayText}");
                PublishMainFormMessage(0, MsgType.Dll, displayText, param: 1, param2: config.Id);
            }
        }
        catch (Exception ex)
        {
            _logger.Warn($"Failed to process factory config versions: {ex.Message}");
        }
    }

    // =========================================================================
    // Private — JSON path normalization
    // =========================================================================

    /// <summary>
    /// Replaces forward slashes in DllPath values with backslashes.
    /// </summary>
    private static string NormalizeDllPathSeparators(string configJson)
    {
        try
        {
            var array = System.Text.Json.Nodes.JsonNode.Parse(configJson)?.AsArray();
            if (array == null) return configJson;

            bool modified = false;
            foreach (var item in array)
            {
                if (item is System.Text.Json.Nodes.JsonObject obj &&
                    obj.TryGetPropertyValue("DllPath", out var node) &&
                    node is System.Text.Json.Nodes.JsonValue val)
                {
                    var p = val.GetValue<string>();
                    if (p.Contains('/'))
                    {
                        obj["DllPath"] = p.Replace('/', '\\');
                        modified = true;
                    }
                }
            }

            return modified ? array.ToJsonString() : configJson;
        }
        catch
        {
            return configJson;
        }
    }

    // =========================================================================
    // Private — Message publishing (replaces WM_COPYDATA)
    // =========================================================================

    private void PublishTestFormMessage(int channel, int mode, string message, int param = 0)
    {
        _messageBus.Publish(new DllEventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            Message = message,
        });
    }

    private void PublishMainFormMessage(int channel, int mode, string message, int param = 0, int param2 = 0)
    {
        // Cache DLL version info so UI can read it even after startup
        if (mode == MsgType.Dll)
        {
            switch (param)
            {
                case 1: // LGD DLL name
                    if (param2 == 0)
                        LgdDllName = message;
                    else if (!string.IsNullOrEmpty(message) && !string.Equals(message, "N/A", StringComparison.OrdinalIgnoreCase))
                        LgdDllName += "\n" + message;
                    break;
                case 2: // OC Converter version
                    OcConverterVersion = message;
                    break;
                case 3: // OC ConDLL name
                    OcConDllName = message;
                    break;
            }
        }

        _messageBus.Publish(new DllEventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            Param2 = param2,
            Message = message,
        });
    }

    // =========================================================================
    // Private — Utility methods
    // =========================================================================

    /// <summary>
    /// Maps defect error code string to NG code index.
    /// Delphi: GetNGCode_ByErroCode (Test4ChOC.pas:3411-3424)
    /// </summary>
    private int GetNgCodeByErrorCode(string errorCode)
    {
        if (string.IsNullOrEmpty(errorCode) || errorCode == "XXXX")
            return 0;

        var gmesInfo = _config.GmesInfo;
        for (int i = 1; i < gmesInfo.Count; i++)
        {
            if (string.Equals(gmesInfo[i].ErrCode, errorCode, StringComparison.OrdinalIgnoreCase))
                return i;
        }

        return 3181; // Default: "Other" NG code
    }

    private bool ValidateChannel(int channel)
    {
        return channel >= 0 && channel < _channelCount;
    }

    /// <summary>
    /// CRC-16 matching DLL internal CalculateCRC16 exactly.
    /// Polynomial 0x8408 (reflected CCITT), init 0xFFFF, complement + byte swap.
    /// </summary>
    private static ushort ComputeCrc16(string input, int length)
    {
        ushort crc = 0xFFFF;
        int remaining = length;
        int idx = 0;

        if (length == 0)
            return (ushort)~crc;

        while (remaining > 0)
        {
            ushort data = (ushort)(0xFFu & (byte)input[idx]);
            remaining--;
            idx++;
            for (int bit = 0; bit < 8; bit++)
            {
                crc = (((crc & 1) ^ (data & 1)) != 1)
                    ? (ushort)(crc >> 1)
                    : (ushort)((uint)(crc >> 1) ^ 0x8408u);
                data >>= 1;
            }
        }

        crc = (ushort)~crc;
        ushort crcCopy = crc;
        return (ushort)((uint)(crc << 8) | ((uint)(crcCopy >> 8) & 0xFFu));
    }
}
