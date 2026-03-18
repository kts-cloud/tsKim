// =============================================================================
// MainForm.cs — WinForms host for Blazor UI via BlazorWebView
// Graceful shutdown: mirrors Delphi TfrmMain_OC.FormCloseQuery (Main_OC.pas:1564)
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.Plc;
using Microsoft.AspNetCore.Components.WebView.WindowsForms;
using Microsoft.Extensions.DependencyInjection;

namespace Dongaeltek.ITOLED.OC;

public sealed class MainForm : Form
{
    private readonly IServiceProvider _services;
    private bool _shutdownConfirmed;

    public MainForm(IServiceProvider services)
    {
        _services = services;

        Text = "ITOLED OC";
        Size = new System.Drawing.Size(1920, 1080);
        WindowState = FormWindowState.Maximized;
        StartPosition = FormStartPosition.CenterScreen;

        var blazorWebView = new BlazorWebView
        {
            Dock = DockStyle.Fill,
            HostPage = "wwwroot\\index.html",
            Services = services,
        };
        blazorWebView.RootComponents.Add<Routes>("#app");

        Controls.Add(blazorWebView);
    }

    protected override async void OnFormClosing(FormClosingEventArgs e)
    {
        base.OnFormClosing(e);

        // Already confirmed — let the form close
        if (_shutdownConfirmed)
            return;

        var status = _services.GetRequiredService<ISystemStatusService>();

        // 1. AutoMode 차단 (Delphi: if Common.StatusInfo.AutoMode)
        if (status.AutoMode)
        {
            MessageBox.Show(this,
                "Auto 모드에서는 종료할 수 없습니다.\n(Can not Execute On Auto Mode)",
                "Confirm", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            e.Cancel = true;
            return;
        }

        // 2. 검사 중 차단 (Delphi: MainOC_GetOCFlowIsAlive)
        var dllService = _services.GetService<IOcDllService>();
        if (dllService != null)
        {
            for (int ch = ChannelConstants.Ch1; ch <= ChannelConstants.MaxCh; ch++)
            {
                if (dllService.GetFlowIsAlive(ch) != 0)
                {
                    MessageBox.Show(this,
                        "검사 중에는 종료할 수 없습니다.\n(Unable to close while inspecting)",
                        "Confirm", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    e.Cancel = true;
                    return;
                }
            }
        }

        // 3. 종료 확인 다이얼로그 (Delphi: MessageDlg)
        var result = MessageBox.Show(this,
            "프로그램을 종료하시겠습니까?\n(Are you sure you want to Exit Program?)",
            "Confirm", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (result != DialogResult.Yes)
        {
            e.Cancel = true;
            return;
        }

        // Cancel close temporarily — will re-close after graceful shutdown
        e.Cancel = true;
        Enabled = false; // Delphi: Self.Enabled := False

        // 4. Graceful shutdown sequence
        status.IsClosing = true;

        // 타워램프 OFF (Delphi: ControlDio.Set_TowerLampState(LAMP_STATE_NONE))
        try
        {
            var dio = _services.GetService<IDioController>();
            dio?.SetTowerLampState((int)LampState.None);
        }
        catch { }

        // PLC ECS 상태 전환 (Delphi: ECS_Unit_Status(COMMPLC_UNIT_STATE_IDLE, 200) + ECS_Unit_Status(COMMPLC_UNIT_STATE_ONLINE, 0))
        var plc = _services.GetService<IPlcEcsDriver>();
        try
        {
            plc?.EcsUnitStatus(CommPlcConst.UnitStateIdle, 200);
            plc?.EcsUnitStatus(CommPlcConst.UnitStateOnline, 0);
        }
        catch { }

        // 5. 하드웨어 안정화 대기 (Delphi: Sleep(500))
        await Task.Delay(500);

        // 6. 하드웨어 명시적 Stop (Delphi: InitialAll(False) 내부 순서)
        try { plc?.Stop(); } catch { }
        try
        {
            var dioDriver = _services.GetService<IDaeDioDriver>();
            dioDriver?.Stop();
        }
        catch { }
        try
        {
            var ca410 = _services.GetService<ICaSdk2Driver>();
            ca410?.Disconnect();
        }
        catch { }

        // 7. 추가 안정화 대기
        await Task.Delay(300);

        // Now allow close
        _shutdownConfirmed = true;
        Close();
    }
}
