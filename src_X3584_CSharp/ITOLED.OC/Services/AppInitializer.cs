// =============================================================================
// AppInitializer.cs — Full SW initialization service
// Equivalent to Delphi Main_OC.pas: btnInitClick → InitialAll(True) + CreateClassData
// =============================================================================

using System.Globalization;
using System.Text;
using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.BusinessLogic.Dll;
using Dongaeltek.ITOLED.BusinessLogic.Inspection;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.OC.Services;

/// <summary>
/// Manages full software initialization: stop hardware → reload config → restart hardware.
/// Mirrors Delphi <c>TfrmMain_OC.InitialAll(True)</c> + <c>CreateClassData</c>.
/// </summary>
public sealed class AppInitializer : IAppInitializer
{
    private readonly ISystemStatusService _status;
    private readonly IConfigurationService _config;
    private readonly IModelInfoService _model;
    private readonly IPlcEcsDriver _plc;
    private readonly IDaeDioDriver _dio;
    private readonly ICaSdk2Driver _ca410;
    private readonly IMessageBus _bus;
    private readonly IScriptRunner[] _scriptRunners;
    private readonly IPathManager _pathManager;
    private readonly IDllManager _dllManager;

    public AppInitializer(
        ISystemStatusService status,
        IConfigurationService config,
        IModelInfoService model,
        IPlcEcsDriver plc,
        IDaeDioDriver dio,
        ICaSdk2Driver ca410,
        IMessageBus bus,
        IScriptRunner[] scriptRunners,
        IPathManager pathManager,
        IDllManager dllManager)
    {
        _status = status;
        _config = config;
        _model = model;
        _plc = plc;
        _dio = dio;
        _ca410 = ca410;
        _bus = bus;
        _scriptRunners = scriptRunners;
        _pathManager = pathManager;
        _dllManager = dllManager;
    }

    /// <inheritdoc />
    public bool CanInitialize => !_status.AutoMode && !_status.IsClosing;

    /// <inheritdoc />
    public async Task<bool> InitializeAllAsync()
    {
        if (!CanInitialize) return false;

        _bus.Publish(GuiLogMessage.Info("[InitialAll] SW 초기화 시작"));

        // ═══════════════════════════════════════════════════════════════
        // Phase 1: STOP (Delphi: InitialAll destruction sequence)
        // ═══════════════════════════════════════════════════════════════
        _status.IsClosing = true;

        _bus.Publish(GuiLogMessage.Info("[InitialAll] PLC Stop"));
        _plc.Stop();

        _bus.Publish(GuiLogMessage.Info("[InitialAll] DIO Stop"));
        _dio.Stop();

        _bus.Publish(GuiLogMessage.Info("[InitialAll] CA-410 Disconnect"));
        _ca410.Disconnect();

        // Wait for hardware to stabilize
        await Task.Delay(500);

        // ═══════════════════════════════════════════════════════════════
        // Phase 2: RELOAD CONFIG (Delphi: Common := TCommon.Create)
        // ═══════════════════════════════════════════════════════════════
        _bus.Publish(GuiLogMessage.Info("[InitialAll] Config Reload"));
        _config.Reload();

        _bus.Publish(GuiLogMessage.Info("[InitialAll] Model Reload"));
        var testModel = _config.SystemInfo?.TestModel;
        if (!string.IsNullOrEmpty(testModel))
            _model.LoadModel(testModel);
        else
            _model.ReloadCurrentModel();

        // Reload CSX script (Delphi: LoadPsuFile → LoadSource)
        var modelName = _model.CurrentModelName;
        if (!string.IsNullOrEmpty(modelName))
        {
            var csxPath = _pathManager.GetFilePath(modelName, PathIndex.ScriptCsx);
            if (File.Exists(csxPath))
            {
                _bus.Publish(GuiLogMessage.Info("[InitialAll] CSX Script Reload"));
                var scriptLines = File.ReadAllLines(csxPath, Encoding.UTF8);
                foreach (var runner in _scriptRunners)
                    runner.LoadSource(scriptLines);

                // Delphi: Main_OC.pas:5992-5994 — PasScr[i].InitialScript for each channel
                // Calls Seq_INIT(0) to initialize script-level variables
                // (SummaryCsv, GRRCsv, PowerCalCsv, CbApdr, etc.)
                foreach (var runner in _scriptRunners)
                    runner.InitialScript();
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // Phase 3: RESTART (Delphi: CreateClassData)
        // ═══════════════════════════════════════════════════════════════
        _status.IsClosing = false;
        _status.AutoMode = false;

        // Sync USE_CH flags from INI → runtime status
        if (_config.SystemInfo != null)
        {
            for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
                _status.SetChannelEnabled(i, _config.SystemInfo.UseCh[i]);

            // Sync USE_CH → ScriptRunner.IsInUse
            // (Delphi: Test4ChOC.pas:3032 — PasScr[nCh].m_bUse := Common.SystemInfo.UseCh[nCh])
            for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
            {
                if (i < _scriptRunners.Length)
                    _scriptRunners[i].IsInUse = _config.SystemInfo.UseCh[i];
            }
        }

        // Re-initialize OC DLL with current model
        // (Delphi: TCSharpDll.Initialize called on model change)
        if (_dllManager.IsLoaded && _model is ModelInfoService mis)
        {
            var modelTypeName = mis.FlowData.ModelTypeName;
            if (!string.IsNullOrEmpty(modelTypeName))
            {
                _dllManager.Initialize(modelTypeName);
                _bus.Publish(GuiLogMessage.Info($"[InitialAll] DllManager.Initialize('{modelTypeName}') completed"));
            }
        }

        // ── PLC simulation mode switch (before reconfigure) ──────────
        _plc.ApplySimulationMode();

        // ── PLC reconfigure + restart ────────────────────────────────
        _bus.Publish(GuiLogMessage.Info("[InitialAll] PLC Reconfigure + Start"));
        var plcInfo = _config.PlcInfo;
        _plc.SetEqpId(plcInfo.EQPId);
        _plc.SetStartAddress(
            ParseHexAddress(plcInfo.AddressEQP),
            ParseHexAddress(plcInfo.AddressECS) + (plcInfo.EQPId / 19) * 0x10,
            ParseHexAddress(plcInfo.AddressRobot),
            ParseHexAddress(plcInfo.AddressRobot2),
            ParseHexAddress(plcInfo.AddressEQPWrite),
            ParseHexAddress(plcInfo.AddressECSWrite),
            ParseHexAddress(plcInfo.AddressRobotWrite),
            ParseHexAddress(plcInfo.AddressRobotWrite2),
            ParseHexAddress(plcInfo.AddressDoorOpen));
        if (plcInfo.PollingInterval > 0)
            _plc.PollingInterval = plcInfo.PollingInterval;
        if (plcInfo.TimeoutConnection > 0)
            _plc.ConnectionTimeout = (uint)plcInfo.TimeoutConnection;
        if (_config.SystemInfo?.ECSTimeout > 0)
            _plc.EcsTimeout = (uint)_config.SystemInfo.ECSTimeout;
        _plc.Start();

        // ── ECS initialization (Delphi: CreateClassData ECS sequence) ─
        // Wait for PLC connection before sending ECS commands
        {
            _bus.Publish(GuiLogMessage.Info("[InitialAll] PLC 연결 대기 중..."));
            int waitMs = 0;
            int maxWaitMs = (int)_plc.ConnectionTimeout + 2000; // connection timeout + margin
            while (!_plc.Connected && waitMs < maxWaitMs)
            {
                await Task.Delay(200);
                waitMs += 200;
            }

            if (_plc.Connected)
            {
                _bus.Publish(GuiLogMessage.Info("[InitialAll] ECS 영역 초기화"));
                _plc.EqpClearEcsArea();
                _plc.EcsUnitStatus(CommPlcConst.UnitStateIdle, 0);
                _bus.Publish(GuiLogMessage.Info("[InitialAll] ECS 초기화 완료 (Idle 상태 보고)"));
            }
            else
            {
                _bus.Publish(GuiLogMessage.Warning("[InitialAll] PLC 미연결 — ECS 초기화 건너뜀"));
            }
        }

        // ── DIO restart ──────────────────────────────────────────────
        _bus.Publish(GuiLogMessage.Info("[InitialAll] DIO Start"));
        _dio.Start();

        // ── CA-410 reconfigure + reconnect ───────────────────────────
        _bus.Publish(GuiLogMessage.Info("[InitialAll] CA-410 Reconfigure + ManualConnect"));
        var sysInfo = _config.SystemInfo;
        if (sysInfo != null)
        {
            for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
            {
                _ca410.SetSetupPort(i, new CaSetupInfo
                {
                    SelectIdx = sysInfo.ComCa310[i],
                    DeviceId  = sysInfo.ComCa310DeviceId[i],
                    SerialNo  = sysInfo.ComCa310Serial[i]
                });
            }
        }
        _ca410.ManualConnect();

        _bus.Publish(GuiLogMessage.Info("[InitialAll] SW 초기화 완료"));
        return true;
    }

    /// <summary>
    /// Parses a PLC address hex string (e.g. "400" → 0x400).
    /// Duplicated from Program.cs for reuse.
    /// </summary>
    private static long ParseHexAddress(string? addr)
    {
        if (string.IsNullOrWhiteSpace(addr)) return 0;
        return long.TryParse(addr, NumberStyles.HexNumber, null, out var v) ? v : 0;
    }
}
