// =============================================================================
// SystemStatusPanel.razor.cs — Code-behind for left info panel.
// Replaces Delphi pnlSysInfo (Main_OC.pas) status display logic.
// =============================================================================

using Dongaeltek.ITOLED.BusinessLogic.Dfs;
using Dongaeltek.ITOLED.BusinessLogic.Dll;
using Dongaeltek.ITOLED.BusinessLogic.Mes;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Messaging;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.Messaging.Messages;
using Microsoft.AspNetCore.Components;
using MudBlazor;

namespace Dongaeltek.ITOLED.OC.Components;

public partial class SystemStatusPanel : IDisposable
{
    // ── DI ──────────────────────────────────────────────────────
    [Inject] private IConfigurationService Config { get; set; } = default!;
    [Inject] private IPlcEcsDriver Plc { get; set; } = default!;
    [Inject] private IDaeDioDriver Dio { get; set; } = default!;
    [Inject] private ICaSdk2Driver Ca410 { get; set; } = default!;
    [Inject] private IMessageBus MessageBus { get; set; } = default!;
    [Inject] private IGmesCommunication? Gmes { get; set; }
    [Inject] private IDfsService? Dfs { get; set; }
    [Inject] private IPathManager PathManager { get; set; } = default!;
    [Inject] private IDllManager DllManager { get; set; } = default!;
    [Inject] private Services.UiUpdateService UiService { get; set; } = default!;

    // ── Section 1: System Information ───────────────────────────
    private readonly bool[] _ca410Connected = new bool[4];
    private bool _handBcrConnected;
    private string _handBcrText = "---";
    private bool _switchAConnected;
    private string _switchAText = "---";
    private bool _switchBConnected;
    private string _switchBText = "---";
    private bool _ionizer1Connected;
    private string _ionizer1Text = "---";
    private bool _ionizer2Connected;
    private bool _dioConnected;
    private string _dioStatusText = "---";
    private bool _ecsConnected;
    private string _ecsStatusText = "---";
    private bool _irTempConnected;
    private string _irTempText = "---";

    // ── Section 2: GMES ─────────────────────────────────────────
    private bool _gmesConnected;
    private string _gmesText = "---";
    private string _eqpIdLabel = "EQP ID";
    private string _eqpId = "---";
    private bool _easConnected;
    private string _easText = "---";
    private bool _r2rConnected;
    private string _r2rText = "---";
    private string _userId = "---";
    private string _userName = "---";

    // ── Section 3: Script Information ───────────────────────────
    private string _modelName = "---";
    private string _lgdDllName = "---";       // Delphi: pnlLGDDLLName (Param=1, multi-line)
    private string _ocConDllName = "---";     // Delphi: pnlOC_ConDLLName (Param=3)
    private string _ocConverterVer = "---";   // Delphi: pnlOC_conVer (Param=2)
    private string _csxModified = "---";
    private bool _aaModeOn;

    // ── Section 4: DFS Info ─────────────────────────────────────
    private bool _dfsVisible;
    private bool _dfsConnected;
    private string _dfsText = "---";
    private string _dfsRcpName = "---";

    // ── Section 5: Power Information ────────────────────────────
    private string _powerVlcd = "---";
    private string _powerVel = "---";
    private string _powerVcc = "---";
    private string _powerVbat = "---";
    private string _powerExt = "---";

    // ── Timer & subscriptions ───────────────────────────────────
    private System.Threading.Timer? _refreshTimer;
    private readonly List<IDisposable> _subscriptions = [];

    protected override void OnInitialized()
    {
        // Load static config values (once)
        LoadStaticConfig();

        // Subscribe to message bus events
        _subscriptions.Add(MessageBus.Subscribe<DllEventMessage>(OnDllEvent));
        _subscriptions.Add(MessageBus.Subscribe<IonizerEventMessage>(OnIonizerEvent));
        _subscriptions.Add(MessageBus.Subscribe<ThermometerEventMessage>(OnThermometerEvent));
        _subscriptions.Add(MessageBus.Subscribe<HostEventMessage>(OnHostEvent));
        _subscriptions.Add(MessageBus.Subscribe<SwitchEventMessage>(OnSwitchEvent));
        _subscriptions.Add(MessageBus.Subscribe<DfsEventMessage>(OnDfsEvent));

        // 500ms polling timer — mirrors Delphi tmrMain
        _refreshTimer = new System.Threading.Timer(async _ =>
        {
            PollConnectionStatus();
            await InvokeAsync(StateHasChanged);
        }, null, 0, 500);
    }

    private void LoadStaticConfig()
    {
        var sysInfo = Config.SystemInfo;

        // Switch COM port labels
        _switchAText = sysInfo.ComRCB.Length > 0 ? $"COM{sysInfo.ComRCB[0]}" : "---";
        _switchBText = sysInfo.ComRCB.Length > 1 ? $"COM{sysInfo.ComRCB[1]}" : "---";
        _switchAConnected = sysInfo.ComRCB.Length > 0 && sysInfo.ComRCB[0] > 0;
        _switchBConnected = sysInfo.ComRCB.Length > 1 && sysInfo.ComRCB[1] > 0;

        // Ionizer COM labels
        _ionizer1Text = sysInfo.ComIonizer.Length > 0 ? $"COM{sysInfo.ComIonizer[0]}" : "---";
        _ionizer1Connected = sysInfo.ComIonizer.Length > 0 && sysInfo.ComIonizer[0] > 0;
        _ionizer2Connected = sysInfo.ComIonizer.Length > 1 && sysInfo.ComIonizer[1] > 0;

        // Hand BCR
        _handBcrText = sysInfo.ComHandBCR.Length > 0 ? $"COM{sysInfo.ComHandBCR[0]}" : "---";

        // EQP ID
        _eqpIdLabel = sysInfo.EQPIdType switch
        {
            1 => "M-GIB EQP ID",
            2 => "P-GIB EQP ID",
            _ => "EQP ID"
        };
        _eqpId = !string.IsNullOrEmpty(sysInfo.EQPId) ? sysInfo.EQPId : "---";

        // Script info
        _modelName = !string.IsNullOrEmpty(sysInfo.TestModel) ? sysInfo.TestModel : "---";
        _aaModeOn = sysInfo.UseInLineAAMode;

        // Read cached DLL version info (events fired before UI is created)
        if (DllManager.IsLoaded)
        {
            _lgdDllName = !string.IsNullOrEmpty(DllManager.LgdDllName) ? DllManager.LgdDllName : "---";
            _ocConDllName = !string.IsNullOrEmpty(DllManager.OcConDllName) ? DllManager.OcConDllName : "---";
            _ocConverterVer = !string.IsNullOrEmpty(DllManager.OcConverterVersion) ? DllManager.OcConverterVersion : "---";
        }
        else
        {
            _lgdDllName = !string.IsNullOrEmpty(sysInfo.LGDDLLVerName) ? sysInfo.LGDDLLVerName : "---";
        }

        // CSX file info
        RefreshCsxInfo(sysInfo.TestModel);

        // DFS visibility
        _dfsVisible = Config.DfsConfInfo.UseDfs;
    }

    private void PollConnectionStatus()
    {
        // CA410 channels
        for (int i = 0; i < 4; i++)
            _ca410Connected[i] = Ca410.IsConnected(i);

        // DIO
        _dioConnected = Dio.Connected;
        _dioStatusText = Dio.Connected ? "Connected" : "Disconnected";

        // ECS (PLC)
        _ecsConnected = Plc.Connected;
        _ecsStatusText = Plc.Connected ? "Connected" : "Disconnected";

        // GMES
        if (Gmes is not null)
        {
            _gmesConnected = Gmes.CanUseHost;
            _gmesText = Gmes.MesPmMode ? "PM Mode" : (Gmes.CanUseHost ? "Connected" : "Disconnected");
            _easConnected = Gmes.CanUseEas;
            _easText = Gmes.CanUseEas ? "Connected" : "Disconnected";
            _r2rConnected = Gmes.CanUseR2R;
            _r2rText = Gmes.CanUseR2R ? "Connected" : "Disconnected";
            _userId = !string.IsNullOrEmpty(Gmes.MesUserId) ? Gmes.MesUserId : "---";
            _userName = !string.IsNullOrEmpty(Gmes.MesUserName) ? Gmes.MesUserName : "---";
        }

        // DFS
        if (_dfsVisible && Dfs is not null)
        {
            _dfsConnected = Dfs.AnyConnectionOk;
            _dfsText = Dfs.AnyConnectionOk ? "Connected" : "Disconnected";
        }

        // Script info — refresh on model change
        var sysInfo = Config.SystemInfo;
        var currentModel = sysInfo.TestModel ?? "";
        if (_modelName != currentModel && !string.IsNullOrEmpty(currentModel))
        {
            _modelName = currentModel;
            RefreshCsxInfo(currentModel);
        }
        _aaModeOn = sysInfo.UseInLineAAMode;
    }

    private void RefreshCsxInfo(string? testModel)
    {
        try
        {
            if (!string.IsNullOrEmpty(testModel))
            {
                var csxPath = PathManager.GetFilePath(testModel, PathIndex.ScriptCsx);
                if (!string.IsNullOrEmpty(csxPath) && System.IO.File.Exists(csxPath))
                {
                    _csxModified = System.IO.File.GetLastWriteTime(csxPath).ToString("yyyy-MM-dd HH:mm");
                    return;
                }
            }
        }
        catch { /* file access failure */ }

        _csxModified = "---";
    }

    // ── Message handlers ────────────────────────────────────────

    private void OnDllEvent(DllEventMessage msg)
    {
        // Delphi: MSG_TYPE_NONE → MSG_TYPE_DLL sub-case in Main_OC.pas:6525-6563
        // Only handle DLL-type messages (Mode=16); ignore AddLog/Display/etc.
        if (msg.Mode != MsgType.Dll)
            return;

        // Param=1: LGD DLL name (Param2=0 → base, Param2>0 → append with newline)
        //   Delphi: Param2=N requires DisplayDLLCnt >= N
        //   dllClass.pas:1326 iterates OC_Factory_Config.json and sends all entries
        // Param=2: OC Converter version (pnlOC_conVer)
        // Param=3: OC Converter DLL name (pnlOC_ConDLLName)
        var sysInfo = Config.SystemInfo;
        switch (msg.Param)
        {
            case 1:
                if (msg.Param2 == 0)
                {
                    _lgdDllName = msg.Message;
                    sysInfo.LGDDLLVerName = msg.Message;
                }
                else if (sysInfo.OCType == ChannelConstants.OcType
                    && !string.IsNullOrEmpty(msg.Message)
                    && !string.Equals(msg.Message, "N/A", StringComparison.OrdinalIgnoreCase)
                    && msg.Param2 > 0
                    && sysInfo.DisplayDLLCnt >= msg.Param2)
                {
                    _lgdDllName += "\n" + msg.Message;
                }
                break;
            case 2:
                sysInfo.OCConverterName = msg.Message;
                _ocConverterVer = msg.Message;
                break;
            case 3:
                _ocConDllName = msg.Message;
                break;
        }
        InvokeAsync(StateHasChanged);
    }

    /// <summary>
    /// Builds display lines for LGD DLL + OC Converter version + OC_CON DLL.
    /// Extracts [version] bracket part for compact display.
    /// </summary>
    private IEnumerable<(string Label, string Value)> GetDllDisplayLines()
    {
        // LGD DLL lines (may be multi-line \n separated)
        var lines = (_lgdDllName ?? "---").Split('\n', StringSplitOptions.RemoveEmptyEntries);
        for (int i = 0; i < lines.Length; i++)
        {
            var raw = lines[i].Trim();
            if (string.IsNullOrEmpty(raw) || string.Equals(raw, "N/A", StringComparison.OrdinalIgnoreCase))
                continue;

            var label = i == 0 ? "LGD DLL" : $"LGD DLL {i + 1}";
            yield return (label, FormatDllName(raw));
        }

        // OC Converter version (Delphi: pnlOC_conVer, Param=2)
        if (!string.IsNullOrEmpty(_ocConverterVer) && _ocConverterVer != "---")
            yield return ("OC_CON VER", _ocConverterVer);

        // OC Converter DLL name (Delphi: pnlOC_ConDLLName, Param=3)
        if (!string.IsNullOrEmpty(_ocConDllName) && _ocConDllName != "---")
            yield return ("OC_CON DLL", _ocConDllName);
    }

    /// <summary>
    /// Formats DLL name: "LGD_OC_X3584_V1.62_V831001_V128_IXXL_NG_O.dll [V1.62...]"
    /// → shows just the bracket part if available, otherwise full name.
    /// </summary>
    private static string FormatDllName(string raw)
    {
        // Extract [version] bracket content if present
        var bracketStart = raw.IndexOf('[');
        var bracketEnd = raw.IndexOf(']');
        if (bracketStart >= 0 && bracketEnd > bracketStart)
            return raw[(bracketStart + 1)..bracketEnd];

        // Fallback: strip .dll extension
        if (raw.EndsWith(".dll", StringComparison.OrdinalIgnoreCase))
            return raw[..^4];

        return raw;
    }

    private void OnIonizerEvent(IonizerEventMessage msg)
    {
        // Mode 0 = status update, Channel = ionizer index
        if (msg.Mode == 0)
        {
            if (msg.Channel == 0)
            {
                _ionizer1Connected = msg.Param > 0;
                _ionizer1Text = msg.Param > 0 ? "ON" : "OFF";
            }
            else if (msg.Channel == 1)
            {
                _ionizer2Connected = msg.Param > 0;
            }
        }
        InvokeAsync(StateHasChanged);
    }

    private void OnThermometerEvent(ThermometerEventMessage msg)
    {
        _irTempConnected = msg.Param > 0;
        _irTempText = !string.IsNullOrEmpty(msg.Message) ? msg.Message : (msg.Param > 0 ? "Connected" : "---");
        InvokeAsync(StateHasChanged);
    }

    private void OnHostEvent(HostEventMessage msg)
    {
        // Refresh GMES status on host event
        if (Gmes is not null)
        {
            _gmesConnected = Gmes.CanUseHost;
            _gmesText = Gmes.MesPmMode ? "PM Mode" : (Gmes.CanUseHost ? "Connected" : "Disconnected");
        }
        InvokeAsync(StateHasChanged);
    }

    private void OnSwitchEvent(SwitchEventMessage msg)
    {
        // Hand BCR connection status
        _handBcrConnected = msg.Param > 0;
        if (!string.IsNullOrEmpty(msg.Message))
            _handBcrText = msg.Message;
        InvokeAsync(StateHasChanged);
    }

    private void OnDfsEvent(DfsEventMessage msg)
    {
        if (Dfs is not null)
        {
            _dfsConnected = Dfs.AnyConnectionOk;
            _dfsText = Dfs.AnyConnectionOk ? "Connected" : "Disconnected";
            if (!string.IsNullOrEmpty(msg.Message))
                _dfsRcpName = msg.Message;
        }
        InvokeAsync(StateHasChanged);
    }

    public void Dispose()
    {
        _refreshTimer?.Dispose();
        foreach (var sub in _subscriptions)
            sub.Dispose();
        _subscriptions.Clear();
    }
}
