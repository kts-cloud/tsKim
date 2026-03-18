// =============================================================================
// EcsStatusPage.razor.cs — Code-behind for ECS Status page.
// Replaces Delphi ECSStatusForm.pas (2069 lines): polling grid, mode toggle,
// glass data detail, load/unload flow visualization, test panel.
//
// Grid columns are loaded from INI/EcsStatusGrid.ini via EcsGridConfigLoader.
// =============================================================================

using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.OC.Services;
using Microsoft.AspNetCore.Components;
using MudBlazor;

namespace Dongaeltek.ITOLED.OC.Pages;

public partial class EcsStatusPage : IDisposable
{
    // ── Dependency Injection ──────────────────────────────────────
    [Inject] private IPlcEcsDriver Plc { get; set; } = default!;
    [Inject] private IConfigurationService Config { get; set; } = default!;
    [Inject] private UiUpdateService UiService { get; set; } = default!;
    [Inject] private ISystemStatusService Status { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private IPathManager PathManager { get; set; } = default!;

    // ── Constants ─────────────────────────────────────────────────
    private const int _channelCount = 4;

    // ── Mode: 0=Status, 1=Maintenance ─────────────────────────────
    private int _mode;

    // ── Connection state ──────────────────────────────────────────
    private bool _ecsConnected;
    private bool _mesConnected;
    private bool _easConnected;
    private bool _r2rConnected;

    // ── Glass data summary fields ─────────────────────────────────
    private string _glassId = "";
    private string _lotId = "";
    private string _carrierId = "";
    private string _productType = "";
    private string _recipeName = "";

    // ── Test panel fields ─────────────────────────────────────────
    private string _userId = "";
    private string _serial = "";
    private string _errorCode = "";
    private string _inspResult = "";
    private int _testChannel;

    private int _alarmType;
    private int _alarmCode;
    private int _alarmOnOff = 1;

    private int _unitStatusMode = CommPlcConst.UnitStateOnline;
    private int _unitStatusValue;

    private int _robotChannel;

    private string _deviceName = "";
    private string _deviceValue = "";

    // ── Flow visualization ────────────────────────────────────────
    private int _flowChannel;

    // ── Busy guard ────────────────────────────────────────────────
    private bool _busy;

    // ── Log ───────────────────────────────────────────────────────
    private readonly List<string> _ecsLog = [];

    // ── Timer ─────────────────────────────────────────────────────
    private System.Threading.Timer? _refreshTimer;

    // ═══════════════════════════════════════════════════════════════
    // Polling Grid — INI-driven dynamic columns
    // ═══════════════════════════════════════════════════════════════

    private readonly EcsGridConfigLoader _gridLoader = new();
    private List<EcsGridConfigLoader.GridColumnDef> _gridColumns = new();

    // ═══════════════════════════════════════════════════════════════
    // Load/Unload Flow Step Definitions
    // ═══════════════════════════════════════════════════════════════

    private readonly record struct FlowStep(string Label, int Index);

    private static readonly FlowStep[] _loadSteps =
    [
        new("GlassDataReq", CommPlcConst.ModeLoad1),
        new("GlassDataRpt", CommPlcConst.ModeLoad2),
        new("LoadReq", CommPlcConst.ModeLoad3),
        new("LoadEnable", CommPlcConst.ModeLoad4),
        new("RobotBusy", CommPlcConst.ModeLoad5),
        new("LoadComplete", CommPlcConst.ModeLoad6),
        new("LoadConfirm", CommPlcConst.ModeLoad7),
        new("EQP Normal", CommPlcConst.ModeLoad11),
        new("Robot Normal", CommPlcConst.ModeLoad12),
    ];

    private static readonly FlowStep[] _unloadSteps =
    [
        new("GlassDataRpt", CommPlcConst.ModeUnload1),
        new("UnloadReq", CommPlcConst.ModeUnload2),
        new("UnloadEnable", CommPlcConst.ModeUnload3),
        new("RobotBusy", CommPlcConst.ModeUnload4),
        new("UnloadComplete", CommPlcConst.ModeUnload5),
        new("UnloadConfirm", CommPlcConst.ModeUnload6),
        new("EQP Normal", CommPlcConst.ModeUnload11),
        new("Robot Normal", CommPlcConst.ModeUnload12),
    ];

    // ═══════════════════════════════════════════════════════════════
    // Lifecycle
    // ═══════════════════════════════════════════════════════════════

    protected override void OnInitialized()
    {
        // Load grid column/bit definitions from INI file
        var iniPath = Path.Combine(PathManager.IniDir, "EcsStatusGrid.ini");
        _gridLoader.Load(iniPath);
        _gridColumns = _gridLoader.Columns;

        UiService.EcsDataChanged += OnEcsDataChanged;

        _refreshTimer = new System.Threading.Timer(async _ =>
        {
            try
            {
                RefreshFromPlc();
                await InvokeAsync(StateHasChanged);
            }
            catch
            {
                // Prevent unhandled exceptions in timer callback
            }
        }, null, 0, 1000);
    }

    public void Dispose()
    {
        _refreshTimer?.Dispose();
        UiService.EcsDataChanged -= OnEcsDataChanged;
    }

    // ═══════════════════════════════════════════════════════════════
    // Data Refresh
    // ═══════════════════════════════════════════════════════════════

    private void RefreshFromPlc()
    {
        try
        {
            _ecsConnected = Plc.Connected;
            _mesConnected = Plc.IsLoggedIn;
            _easConnected = Plc.Connected && Plc.PollingEcs.Length > 0 && Plc.IsBitOnEcs(2);
            _r2rConnected = Plc.Connected && Plc.PollingEcs.Length > 0 && Plc.IsBitOnEcs(3);

            if (Plc.GlassData.Length > 0)
            {
                var gd = Plc.GlassData[0];
                _glassId = gd.GlassId;
                _carrierId = gd.CarrierId;
                _lotId = gd.MateriId;
                _productType = gd.GlassType.ToString();
                _recipeName = $"Recipe #{gd.RecipeNumber}";
            }
        }
        catch
        {
            // Ignore refresh errors (arrays may not be initialized yet)
        }
    }

    private void OnEcsDataChanged()
    {
        InvokeAsync(StateHasChanged);
    }

    // ═══════════════════════════════════════════════════════════════
    // Polling Grid Helpers
    // ═══════════════════════════════════════════════════════════════

    /// <summary>
    /// Reads a single bit from PLC polling data. Used by each grid cell.
    /// Division: 0=PollingEqp, 1=PollingData(Robot), 2=PollingEcs.
    /// </summary>
    private bool GetCellState(int division, int index, int bitLoc)
    {
        try
        {
            return division switch
            {
                0 => index < Plc.PollingEqp.Length && Plc.IsBitOn(Plc.PollingEqp[index], bitLoc),
                1 => index < Plc.PollingData.Length && Plc.IsBitOn(Plc.PollingData[index], bitLoc),
                2 => index < Plc.PollingEcs.Length && Plc.IsBitOn(Plc.PollingEcs[index], bitLoc),
                _ => false
            };
        }
        catch { return false; }
    }

    private static string GetGroupHeaderColor(string group) => group.ToUpperInvariant() switch
    {
        "EQP"   => "#A5D6A7", // EQP header: medium green
        "ROBOT" => "#FFF176", // Robot header: medium yellow
        "ECS"   => "#90CAF9", // ECS header: medium blue
        _       => "#E0E0E0"
    };

    private static string GetGroupOnColor(string group) => group.ToUpperInvariant() switch
    {
        "EQP"   => "#C8E6C9", // EQP cell ON: light green
        "ROBOT" => "#FFF9C4", // Robot cell ON: light yellow
        "ECS"   => "#BBDEFB", // ECS cell ON: light blue
        _       => "#E0E0E0"
    };

    private static string GetGroupTextColor(string group) => group.ToUpperInvariant() switch
    {
        "EQP"   => "#1B5E20", // EQP ON text: dark green
        "ROBOT" => "#E65100", // Robot ON text: dark orange
        "ECS"   => "#0D47A1", // ECS ON text: dark blue
        _       => "#000000"
    };

    /// <summary>
    /// Computes the B-device address string for a grid column header.
    /// Division 0=EQP, 1=Robot, 2=ECS. Address = base + Index * 0x10.
    /// </summary>
    private string GetColumnAddress(EcsGridConfigLoader.GridColumnDef col)
    {
        string baseHex = col.DefaultDivision switch
        {
            0 => Config.PlcInfo.AddressEQP,
            1 => Config.PlcInfo.AddressRobot,
            2 => Config.PlcInfo.AddressECS,
            _ => "0"
        };
        if (int.TryParse(baseHex, System.Globalization.NumberStyles.HexNumber, null, out int baseAddr))
            return $"B{baseAddr + col.DefaultIndex * 0x10:X}";
        return $"B{baseHex}+{col.DefaultIndex}";
    }

    // ═══════════════════════════════════════════════════════════════
    // Glass Data Detail Helpers
    // ═══════════════════════════════════════════════════════════════

    private string GetGlassField(int channel, Func<EcsGlassData, string> selector)
    {
        if (channel < Plc.GlassData.Length)
        {
            var gd = Plc.GlassData[channel];
            if (gd != null) return selector(gd);
        }
        return "";
    }

    // ═══════════════════════════════════════════════════════════════
    // Flow Visualization Helper
    // ═══════════════════════════════════════════════════════════════

    private int GetFlowData(int channel, int stepIndex)
    {
        try { return Status.GetLoadUnloadFlowData(channel, stepIndex); }
        catch { return 0; }
    }

    // ═══════════════════════════════════════════════════════════════
    // Log Helper
    // ═══════════════════════════════════════════════════════════════

    private void AddLog(string message)
    {
        var entry = $"[{DateTime.Now:HH:mm:ss}] {message}";
        _ecsLog.Add(entry);
        if (_ecsLog.Count > 500)
            _ecsLog.RemoveRange(0, _ecsLog.Count - 500);
    }

    // ═══════════════════════════════════════════════════════════════
    // Test Button Handlers — MES
    // ═══════════════════════════════════════════════════════════════

    private async Task RunTestAsync(string name, Func<int> action)
    {
        _busy = true;
        StateHasChanged();
        try
        {
            AddLog($"{name} → Start");
            var res = await Task.Run(action);
            AddLog(res != 0 ? $"{name} → NG ({res})" : $"{name} → OK");
            if (res != 0)
                Snackbar.Add($"{name} returned {res}", Severity.Warning);
        }
        catch (Exception ex)
        {
            AddLog($"{name} → Error: {ex.Message}");
            Snackbar.Add($"{name} error: {ex.Message}", Severity.Error);
        }
        finally
        {
            _busy = false;
            StateHasChanged();
        }
    }

    private Task OnUchkClick() =>
        RunTestAsync("ECS_UCHK", () => Plc.EcsUchk(_userId));

    private Task OnPchkClick() =>
        RunTestAsync($"ECS_PCHK CH={_testChannel}", () => Plc.EcsPchk(_testChannel, _serial));

    private Task OnEicrClick() =>
        RunTestAsync($"ECS_EICR CH={_testChannel}", () => Plc.EcsEicr(_testChannel, _serial, _errorCode, _inspResult));

    private Task OnApdrClick() =>
        RunTestAsync($"ECS_APDR CH={_testChannel}", () => Plc.EcsApdr(_testChannel, _inspResult));

    private Task OnZsetClick()
    {
        _busy = true;
        StateHasChanged();
        return Task.Run(() =>
        {
            AddLog($"ECS_ZSET CH={_testChannel} → Start");
            var res = Plc.EcsZset(_testChannel, 0, "", _serial, "", out var resultData);
            AddLog(res != 0 ? $"ECS_ZSET → NG ({res})" : $"ECS_ZSET → OK, ResultData={resultData}");
        }).ContinueWith(_ =>
        {
            _busy = false;
            InvokeAsync(StateHasChanged);
        });
    }

    private Task OnLinkTestClick() =>
        RunTestAsync("ECS_LinkTest", () => Plc.EcsLinkTest());

    // ═══════════════════════════════════════════════════════════════
    // Test Button Handlers — Alarm / Unit Status
    // ═══════════════════════════════════════════════════════════════

    private Task OnAlarmClick() =>
        RunTestAsync($"Alarm Type={_alarmType} Code={_alarmCode} OnOff={_alarmOnOff}",
            () => Plc.EcsAlarmReport(_alarmType, _alarmCode, _alarmOnOff));

    private Task OnUnitStatusClick() =>
        RunTestAsync($"UnitStatus Mode={_unitStatusMode} Val={_unitStatusValue}",
            () => Plc.EcsUnitStatus(_unitStatusMode, _unitStatusValue));

    private Task OnStatusModeClick() =>
        RunTestAsync($"StatusMode Mode={_unitStatusMode} Val={_unitStatusValue}",
            () => Plc.EcsStatusMode(_unitStatusMode, _unitStatusValue));

    // ═══════════════════════════════════════════════════════════════
    // Test Button Handlers — Robot
    // ═══════════════════════════════════════════════════════════════

    private Task OnRobotLoadClick() =>
        RunTestAsync($"Robot Load CH={_robotChannel}", () => Plc.RobotLoadRequest(_robotChannel));

    private Task OnRobotUnloadClick() =>
        RunTestAsync($"Robot Unload CH={_robotChannel}", () => Plc.RobotUnloadRequest(_robotChannel));

    private Task OnRobotExchangeClick() =>
        RunTestAsync($"Robot Exchange CH={_robotChannel}", () => Plc.RobotExchangeRequest(_robotChannel));

    private Task OnRobotClearClick()
    {
        _busy = true;
        StateHasChanged();
        return Task.Run(() =>
        {
            AddLog($"Robot Clear CH={_robotChannel}");
            Plc.ClearRobotRequest(_robotChannel);
            AddLog("Robot Clear → Done");
        }).ContinueWith(_ =>
        {
            _busy = false;
            InvokeAsync(StateHasChanged);
        });
    }

    // ═══════════════════════════════════════════════════════════════
    // Test Button Handlers — Glass / ECS
    // ═══════════════════════════════════════════════════════════════

    private Task OnGlassDataReportClick()
    {
        if (_testChannel >= Plc.GlassData.Length) return Task.CompletedTask;
        var gd = Plc.GlassData[_testChannel];
        return RunTestAsync($"GlassDataReport CH={_testChannel}",
            () => Plc.EcsGlassDataReport(_testChannel, gd));
    }

    private Task OnGlassPositionClick() =>
        RunTestAsync($"GlassPosition CH={_testChannel}", () => Plc.EcsGlassPosition(_testChannel, true));

    private Task OnGlassExistClick() =>
        RunTestAsync("GlassExist", () => Plc.EcsGlassExist(_channelCount, _channelCount));

    private Task OnGlassProcessingClick() =>
        RunTestAsync("GlassProcessing", () => Plc.EcsGlassProcessing(true));

    private Task OnModelChangeClick() =>
        RunTestAsync("ModelChange", () => Plc.EcsModelChangeRequest(0));

    private Task OnStagePositionClick() =>
        RunTestAsync("StagePosition", () => Plc.EcsStagePosition(0));

    private Task OnTakeOutReportClick() =>
        RunTestAsync($"TakeOutReport CH={_testChannel}",
            () => Plc.EcsTakeOutReport(_testChannel, _serial));

    private Task OnNormalOpClick() =>
        RunTestAsync("NormalOperation", () => Plc.EcsNormalOperation(_glassId));

    // ═══════════════════════════════════════════════════════════════
    // Test Button Handlers — PLC Device R/W
    // ═══════════════════════════════════════════════════════════════

    private Task OnDeviceReadClick()
    {
        if (string.IsNullOrWhiteSpace(_deviceName)) return Task.CompletedTask;
        _busy = true;
        StateHasChanged();
        return Task.Run(() =>
        {
            var ret = Plc.ReadDevice(_deviceName, out var val);
            AddLog(ret == 0
                ? $"ReadDevice({_deviceName}) = {val} (0x{val:X})"
                : $"ReadDevice({_deviceName}) → Error {ret}");
            _deviceValue = val.ToString();
        }).ContinueWith(_ =>
        {
            _busy = false;
            InvokeAsync(StateHasChanged);
        });
    }

    private Task OnDeviceWriteClick()
    {
        if (string.IsNullOrWhiteSpace(_deviceName)) return Task.CompletedTask;
        if (!int.TryParse(_deviceValue, out var val)) return Task.CompletedTask;
        _busy = true;
        StateHasChanged();
        return Task.Run(() =>
        {
            var ret = Plc.WriteDevice(_deviceName, val);
            AddLog(ret == 0
                ? $"WriteDevice({_deviceName}, {val}) → OK"
                : $"WriteDevice({_deviceName}, {val}) → Error {ret}");
        }).ContinueWith(_ =>
        {
            _busy = false;
            InvokeAsync(StateHasChanged);
        });
    }
}
