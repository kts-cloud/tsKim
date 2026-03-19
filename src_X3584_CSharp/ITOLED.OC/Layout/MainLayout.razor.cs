// =============================================================================
// MainLayout.razor.cs — Code-behind for MainLayout
// =============================================================================

using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Plc;
using Microsoft.AspNetCore.Components;
using MudBlazor;

namespace Dongaeltek.ITOLED.OC.Layout;

public partial class MainLayout : IDisposable
{
    [Inject] private ISystemStatusService Status { get; set; } = default!;
    [Inject] private IConfigurationService? Config { get; set; }
    [Inject] private IPlcEcsDriver? Plc { get; set; }

    private bool _drawerOpen = true;
    private bool _autoMode;
    private bool _alarmOn;
    private bool _plcConnected;
    private string _equipmentId = "";
    private string _modelName = "";
    private string _swVersion = "";

    private System.Threading.Timer? _refreshTimer;

    private readonly MudTheme _theme = new()
    {
        PaletteLight = new PaletteLight
        {
            Primary = "#37474F",
            Secondary = "#546E7A",
            AppbarBackground = "#263238",
            Surface = "#FAFAFA",
            Background = "#ECEFF1",
            DrawerBackground = "#ECEFF1",
        },
        PaletteDark = new PaletteDark
        {
            Primary = "#78909C",
            Secondary = "#90A4AE",
            AppbarBackground = "#1C2833",
            Background = "#0E1621",
            Surface = "#172130",
            DrawerBackground = "#141E2B",
            TextPrimary = "#CFD8DC",
            TextSecondary = "#90A4AE",
            ActionDefault = "#78909C",
            ActionDisabled = "#455A64",
            ActionDisabledBackground = "#1E2D3D",
            LinesDefault = "#37474F",
            TableLines = "#263238",
            Divider = "#263238",
            HoverOpacity = 0.08,
            RippleOpacity = 0.12,
        },
        Typography = new Typography
        {
            Default = new DefaultTypography { FontFamily = ["Roboto", "sans-serif"] }
        }
    };

    protected override void OnInitialized()
    {
        _equipmentId = Config?.SystemInfo?.EQPId ?? "N/A";
        _modelName = Config?.SystemInfo?.TestModel ?? "N/A";
        _swVersion = Config?.SystemInfo?.SWVerInterlock ?? "0.0.0.0";

        // Periodic UI refresh (500ms) — replaces Delphi TTimer
        _refreshTimer = new System.Threading.Timer(async _ =>
        {
            _autoMode = Status.AutoMode;
            _alarmOn = Status.AlarmOn;
            _plcConnected = Plc?.Connected ?? false;
            _modelName = Config?.SystemInfo?.TestModel ?? "N/A";
            await InvokeAsync(StateHasChanged);
        }, null, 0, 500);
    }

    private void ToggleDrawer() => _drawerOpen = !_drawerOpen;

    public void Dispose()
    {
        _refreshTimer?.Dispose();
    }
}
