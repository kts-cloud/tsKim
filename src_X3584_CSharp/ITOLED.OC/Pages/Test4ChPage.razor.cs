// =============================================================================
// Test4ChPage.razor.cs — Code-behind for 4-channel inspection test page.
// Replaces Delphi Test4ChOC.pas: per-channel status, DIO LEDs, tact time,
// power data, log display, result history, JIG controls.
// =============================================================================

using Dongaeltek.ITOLED.BusinessLogic.Inspection;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.OC.Services;
using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using MudBlazor;

namespace Dongaeltek.ITOLED.OC.Pages;

public partial class Test4ChPage : IDisposable
{
    // ── Dependency Injection ──────────────────────────────────────
    [Inject] private ISystemStatusService Status { get; set; } = default!;
    [Inject] private IPlcEcsDriver Plc { get; set; } = default!;
    [Inject] private IDioController Dio { get; set; } = default!;
    [Inject] private ICommPgDriver[] PgDrivers { get; set; } = default!;
    [Inject] private ICaSdk2Driver Ca410 { get; set; } = default!;
    [Inject] private UiUpdateService UiService { get; set; } = default!;
    [Inject] private IConfigurationService Config { get; set; } = default!;
    [Inject] private IScriptRunner[] ScriptRunners { get; set; } = default!;
    [Inject] private IJSRuntime JS { get; set; } = default!;

    // ── Constants ─────────────────────────────────────────────────
    private const int ChannelCount = 4;
    private const int JigCount = 2; // JIG_A (CH1+CH2), JIG_B (CH3+CH4)
    private const int MaxLogEntries = 200;
    private const int MaxPrevResults = 20;

    // ── Per-channel state ─────────────────────────────────────────
    private readonly ChannelState[] _ch = new ChannelState[ChannelCount];

    // PG version/connection moved to per-channel ChannelState (PgVersionText, PgLedColor, etc.)

    // ── JIG state ─────────────────────────────────────────────────
    private readonly bool[] _lampOn = new bool[JigCount];
    private readonly bool[] _ionizerOn = new bool[JigCount];

    // ── Timers ────────────────────────────────────────────────────
    private System.Threading.Timer? _refreshTimer;   // 500ms DIO/power/status
    private System.Threading.Timer? _tactTimer;      // 1000ms tact time counter
    private bool _disposed;

    // ── DIO signal mapping per channel ────────────────────────────
    private static readonly int[][] DiProbeSignals =
    [
        [DioInput.Ch1ProbeForwardSensor, DioInput.Ch1ProbeBackwardSensor, DioInput.Ch1ProbeUpSensor, DioInput.Ch1ProbeDownSensor],
        [DioInput.Ch2ProbeForwardSensor, DioInput.Ch2ProbeBackwardSensor, DioInput.Ch2ProbeUpSensor, DioInput.Ch2ProbeDownSensor],
        [DioInput.Ch3ProbeForwardSensor, DioInput.Ch3ProbeBackwardSensor, DioInput.Ch3ProbeUpSensor, DioInput.Ch3ProbeDownSensor],
        [DioInput.Ch4ProbeForwardSensor, DioInput.Ch4ProbeBackwardSensor, DioInput.Ch4ProbeUpSensor, DioInput.Ch4ProbeDownSensor],
    ];

    private static readonly int[][] DoProbeSignals =
    [
        [DioOutput.Ch1ProbeForwardSol, DioOutput.Ch1ProbeBackwardSol, DioOutput.Ch1ProbeUpSol, DioOutput.Ch1ProbeDownSol],
        [DioOutput.Ch2ProbeForwardSol, DioOutput.Ch2ProbeBackwardSol, DioOutput.Ch2ProbeUpSol, DioOutput.Ch2ProbeDownSol],
        [DioOutput.Ch3ProbeForwardSol, DioOutput.Ch3ProbeBackwardSol, DioOutput.Ch3ProbeUpSol, DioOutput.Ch3ProbeDownSol],
        [DioOutput.Ch4ProbeForwardSol, DioOutput.Ch4ProbeBackwardSol, DioOutput.Ch4ProbeUpSol, DioOutput.Ch4ProbeDownSol],
    ];

    private static readonly int[] DiCarrierSensor =
        [DioInput.Ch1CarrierSensor, DioInput.Ch2CarrierSensor, DioInput.Ch3CarrierSensor, DioInput.Ch4CarrierSensor];

    private static readonly int[][] DiCarrierLockSignals =
    [
        [DioInput.Ch1CarrierLock1, DioInput.Ch1CarrierLock2, DioInput.Ch1CarrierLock3, DioInput.Ch1CarrierLock4],
        [DioInput.Ch2CarrierLock1, DioInput.Ch2CarrierLock2, DioInput.Ch2CarrierLock3, DioInput.Ch2CarrierLock4],
        [DioInput.Ch3CarrierLock1, DioInput.Ch3CarrierLock2, DioInput.Ch3CarrierLock3, DioInput.Ch3CarrierLock4],
        [DioInput.Ch4CarrierLock1, DioInput.Ch4CarrierLock2, DioInput.Ch4CarrierLock3, DioInput.Ch4CarrierLock4],
    ];

    private static readonly int[][] DiCarrierUnlockSignals =
    [
        [DioInput.Ch1CarrierUnlockSensor1, DioInput.Ch1CarrierUnlockSensor2, DioInput.Ch1CarrierUnlockSensor3, DioInput.Ch1CarrierUnlockSensor4],
        [DioInput.Ch2CarrierUnlockSensor1, DioInput.Ch2CarrierUnlockSensor2, DioInput.Ch2CarrierUnlockSensor3, DioInput.Ch2CarrierUnlockSensor4],
        [DioInput.Ch3CarrierUnlockSensor1, DioInput.Ch3CarrierUnlockSensor2, DioInput.Ch3CarrierUnlockSensor3, DioInput.Ch3CarrierUnlockSensor4],
        [DioInput.Ch4CarrierUnlockSensor1, DioInput.Ch4CarrierUnlockSensor2, DioInput.Ch4CarrierUnlockSensor3, DioInput.Ch4CarrierUnlockSensor4],
    ];

    private static readonly int[] DoCarrierLockSol =
        [DioOutput.Ch1CarrierLockSol, DioOutput.Ch2CarrierLockSol, DioOutput.Ch3CarrierLockSol, DioOutput.Ch4CarrierLockSol];

    private static readonly int[] DoCarrierUnlockSol =
        [DioOutput.Ch1CarrierUnlockSol, DioOutput.Ch2CarrierUnlockSol, DioOutput.Ch3CarrierUnlockSol, DioOutput.Ch4CarrierUnlockSol];

    // =========================================================================
    // Initialization & Disposal
    // =========================================================================

    protected override void OnInitialized()
    {
        for (int i = 0; i < ChannelCount; i++)
        {
            _ch[i] = new ChannelState
            {
                Enabled = Status.GetChannelEnabled(i)
            };

            // Query current CA-410 connection state from driver
            // (events fired during startup may have been missed before this page loaded)
            if (Ca410.IsConnected(i))
            {
                _ch[i].Ca410Connected = true;
                var setup = Ca410.GetSetupPort(i);
                _ch[i].Ca410Info = $"CH{i + 1}/{string.Format(DefCaSdk.CA410_DISPLAY_ITEM, setup.DeviceId, setup.SerialNo)}";
            }

            // Restore cached state (survives page navigation)
            int status = UiService.GetLastChannelStatus(i);
            _ch[i].StatusCode = status;
            _ch[i].StatusText = status switch
            {
                0 => "Ready", 1 => "Running", 2 => "PASS", 3 => "NG", 4 => "Stop", _ => "Unknown"
            };

            int ngCode = UiService.GetLastChannelNgCode(i);
            if (ngCode >= 0)
                _ch[i].NgCode = ngCode;

            _ch[i].SerialNo = UiService.GetLastChannelSerialNo(i);

            var (ok, ng) = UiService.GetLastChannelCounts(i);
            _ch[i].OkCount = ok;
            _ch[i].NgCount = ng;
            _ch[i].TotalCount = ok + ng;

            _ch[i].LogEntries = UiService.GetLastChannelLogs(i);
            _ch[i].PrevResults = UiService.GetLastChannelPrevResults(i);
        }

        // Subscribe to UiUpdateService events
        UiService.ChannelResultReady += OnChannelResult;
        UiService.ChannelLogAdded += OnChannelLog;
        UiService.ChannelStatusChanged += OnChannelStatusChanged;
        UiService.PowerDataUpdated += OnPowerDataUpdated;
        UiService.Ca410EventReceived += OnCa410Event;
        UiService.TactTimeChanged += OnTactTimeChanged;

        // 500ms refresh timer — DIO signals, power data, PG version, general status
        // All mutations inside InvokeAsync to prevent concurrent access with rendering
        _refreshTimer = new System.Threading.Timer(_ =>
        {
            if (Status.IsClosing) return;
            SafeInvokeAsync(() =>
            {
                RefreshDioState();
                RefreshPowerData();
                RefreshChannelEnabled();
                RefreshPgVersion();
                StateHasChanged();
            });
        }, null, 500, 500);

        // 1000ms tact timer — increment tact time counters
        _tactTimer = new System.Threading.Timer(_ =>
        {
            if (Status.IsClosing) return;
            SafeInvokeAsync(() =>
            {
                bool changed = false;
                for (int ch = 0; ch < ChannelCount; ch++)
                {
                    if (_ch[ch].TotalTimerRunning)
                    {
                        _ch[ch].TotalTactSec++;
                        changed = true;
                    }
                    if (_ch[ch].UnitTimerRunning)
                    {
                        _ch[ch].UnitTactSec++;
                        changed = true;
                    }
                }
                if (changed)
                    StateHasChanged();
            });
        }, null, 1000, 1000);
    }

    private void SafeInvokeAsync(Action action)
    {
        _ = InvokeAsync(() =>
        {
            if (_disposed) return;
            try { action(); }
            catch (ObjectDisposedException) { }
        });
    }

    private void SafeInvokeAsync(Func<Task> action)
    {
        _ = InvokeAsync(async () =>
        {
            if (_disposed) return;
            try { await action(); }
            catch (ObjectDisposedException) { }
        });
    }

    public void Dispose()
    {
        _disposed = true;
        _refreshTimer?.Dispose();
        _tactTimer?.Dispose();
        UiService.ChannelResultReady -= OnChannelResult;
        UiService.ChannelLogAdded -= OnChannelLog;
        UiService.ChannelStatusChanged -= OnChannelStatusChanged;
        UiService.PowerDataUpdated -= OnPowerDataUpdated;
        UiService.Ca410EventReceived -= OnCa410Event;
        UiService.TactTimeChanged -= OnTactTimeChanged;
    }

    // =========================================================================
    // Refresh Methods (called from timers)
    // =========================================================================

    private void RefreshChannelEnabled()
    {
        for (int ch = 0; ch < ChannelCount; ch++)
            _ch[ch].Enabled = Status.GetChannelEnabled(ch);
    }

    private void RefreshDioState()
    {
        for (int ch = 0; ch < ChannelCount; ch++)
        {
            var s = _ch[ch];

            // Probe DI (input sensors)
            s.DiProbeForward = Dio.ReadInSig(DiProbeSignals[ch][0]);
            s.DiProbeBackward = Dio.ReadInSig(DiProbeSignals[ch][1]);
            s.DiProbeUp = Dio.ReadInSig(DiProbeSignals[ch][2]);
            s.DiProbeDown = Dio.ReadInSig(DiProbeSignals[ch][3]);

            // Probe DO (output solenoids)
            s.DoProbeForward = Dio.ReadOutSig(DoProbeSignals[ch][0]);
            s.DoProbeBackward = Dio.ReadOutSig(DoProbeSignals[ch][1]);
            s.DoProbeUp = Dio.ReadOutSig(DoProbeSignals[ch][2]);
            s.DoProbeDown = Dio.ReadOutSig(DoProbeSignals[ch][3]);

            // Carrier detection
            s.DiDetect = Dio.ReadInSig(DiCarrierSensor[ch]);

            // Carrier lock sensors (4 positions)
            s.DiCarrierLock1 = Dio.ReadInSig(DiCarrierLockSignals[ch][0]);
            s.DiCarrierLock2 = Dio.ReadInSig(DiCarrierLockSignals[ch][1]);
            s.DiCarrierLock3 = Dio.ReadInSig(DiCarrierLockSignals[ch][2]);
            s.DiCarrierLock4 = Dio.ReadInSig(DiCarrierLockSignals[ch][3]);

            // Carrier unlock sensors (4 positions)
            s.DiCarrierUnlock1 = Dio.ReadInSig(DiCarrierUnlockSignals[ch][0]);
            s.DiCarrierUnlock2 = Dio.ReadInSig(DiCarrierUnlockSignals[ch][1]);
            s.DiCarrierUnlock3 = Dio.ReadInSig(DiCarrierUnlockSignals[ch][2]);
            s.DiCarrierUnlock4 = Dio.ReadInSig(DiCarrierUnlockSignals[ch][3]);

            // Carrier lock/unlock solenoids
            s.DoCarrierLock = Dio.ReadOutSig(DoCarrierLockSol[ch]);
            s.DoCarrierUnlock = Dio.ReadOutSig(DoCarrierUnlockSol[ch]);
        }
    }

    /// <summary>
    /// Refresh PG version text.
    /// Delphi: pnlHwVersion[nCh].Caption := Format('DP860 (%s, %s)', [PG.m_PgVer.VerAll, PG.m_PgVer.VerScript])
    /// </summary>
    private void RefreshPgVersion()
    {
        for (int ch = 0; ch < ChannelCount; ch++)
        {
            var pg = PgDrivers[ch];
            var s = _ch[ch];
            s.PgConnected = pg.Status != PgStatus.Disconnected;
            s.PgReady = pg.IsPgReady;
            s.PgLedColor = pg.IsPgReady ? MudBlazor.Color.Success
                         : s.PgConnected ? MudBlazor.Color.Warning
                         : MudBlazor.Color.Dark;

            if (pg.IsPgReady)
            {
                var ver = pg.Version;
                s.PgVersionText = !string.IsNullOrEmpty(ver.VerAll)
                    ? $"DP860 ({ver.VerAll}, {ver.VerScript})"
                    : $"DP860 (FW:{ver.FW} HW:{ver.HW})";
            }
            else if (s.PgConnected)
                s.PgVersionText = "PG Connected";
            else
                s.PgVersionText = "PG Disconnected";
        }
    }

    private void RefreshPowerData()
    {
        for (int ch = 0; ch < ChannelCount; ch++)
        {
            var pwr = PgDrivers[ch].PowerData;
            _ch[ch].VccVoltage = pwr.Vcc / 1000.0;  // mV → V
            _ch[ch].VccCurrent = pwr.Ivcc;            // mA
            _ch[ch].VinVoltage = pwr.Vin / 1000.0;   // mV → V
            _ch[ch].VinCurrent = pwr.Ivin;            // mA
        }
    }

    // =========================================================================
    // Event Handlers (from UiUpdateService)
    // =========================================================================

    private void OnChannelResult(int ch, int ngCode)
    {
        if (ch < 0 || ch >= ChannelCount) return;

        SafeInvokeAsync(() =>
        {
            var s = _ch[ch];
            s.NgCode = ngCode;

            if (ngCode == 0)
            {
                s.StatusCode = 2; // Pass
                s.StatusText = "PASS";
                s.OkCount++;
            }
            else
            {
                s.StatusCode = 3; // NG
                s.StatusText = $"{ngCode:D3} NG";
                s.NgCount++;
            }
            s.TotalCount = s.OkCount + s.NgCount;

            // Stop unit tact timer
            s.UnitTimerRunning = false;

            // Add to previous results history
            s.PrevResults.Insert(0, (ngCode, ngCode == 0));
            int maxPrev = Config.SystemInfo?.NGAlarmCount ?? 10;
            if (maxPrev < 1) maxPrev = 10;
            while (s.PrevResults.Count > maxPrev)
                s.PrevResults.RemoveAt(s.PrevResults.Count - 1);

            StateHasChanged();
        });
    }

    private void OnChannelLog(int ch, string msg)
    {
        if (ch < 0 || ch >= ChannelCount) return;

        // All mutations must happen inside InvokeAsync to avoid
        // "Collection was modified" during Blazor rendering
        SafeInvokeAsync(async () =>
        {
            var log = _ch[ch].LogEntries;
            log.Add($"[{DateTime.Now:HH:mm:ss}] {msg}");
            while (log.Count > MaxLogEntries)
                log.RemoveAt(0);

            StateHasChanged();
            await Task.Yield(); // DOM 렌더링 완료 대기
            await JS.InvokeVoidAsync("scrollToBottom", $"log-ch{ch}");
        });
    }

    private void OnChannelStatusChanged(int ch, int statusCode)
    {
        if (ch < 0 || ch >= ChannelCount) return;

        SafeInvokeAsync(() =>
        {
            var s = _ch[ch];
            s.StatusCode = statusCode;
            s.StatusText = statusCode switch
            {
                0 => "Ready",
                1 => "Running",
                2 => "PASS",
                3 => "NG",
                4 => "Stop",
                _ => "Unknown"
            };

            if (statusCode == 1) // Running → start timers
            {
                s.TotalTimerRunning = true;
                s.UnitTimerRunning = true;
                s.UnitTactSec = 0;
            }

            StateHasChanged();
        });
    }

    private void OnPowerDataUpdated(int pgNo)
    {
        SafeInvokeAsync(() =>
        {
            RefreshPowerData();
            StateHasChanged();
        });
    }

    /// <summary>
    /// Handles CA-410 events from the message bus.
    /// Delphi: Test4ChOC.pas WM_COPYDATA handler for MSG_TYPE_CA410.
    /// </summary>
    private void OnCa410Event(int channel, int mode, int param, bool isError, string message)
    {
        if (channel < 0 || channel >= ChannelCount) return;

        SafeInvokeAsync(() =>
        {
            var s = _ch[channel];

            switch (mode)
            {
                case MsgMode.Cax10MemChNo:
                    // Delphi: chkChannelUse[nCh].Caption := Format('Channel %d/Memory(%d)/%s', [nCh+1, nTemp, sMsg])
                    if (param > -1)
                    {
                        s.Ca410Info = $"CH{channel + 1}/Memory({param})/{message}";
                        s.Ca410Connected = true;
                    }
                    break;

                case MsgMode.Ca310Status:
                    s.Ca410Connected = !isError;
                    if (isError && !string.IsNullOrEmpty(message))
                        AddChannelLog(channel, message);
                    break;

                case MsgMode.Working:
                    if (!string.IsNullOrEmpty(message))
                        AddChannelLog(channel, message);
                    break;
            }

            StateHasChanged();
        });
    }

    /// <summary>
    /// Handles tact time start/stop from CSX f_TactTime().
    /// option: 1=TotalStart, 2=TotalEnd, 3=UnitStart, 4=UnitEnd
    /// </summary>
    private void OnTactTimeChanged(int ch, int option)
    {
        if (ch < 0 || ch >= ChannelCount) return;

        SafeInvokeAsync(() =>
        {
            var s = _ch[ch];
            switch (option)
            {
                case 1: // Total Tact Start
                    s.TotalTactSec = 0;
                    s.TotalTimerRunning = true;
                    break;
                case 2: // Total Tact End
                    s.TotalTimerRunning = false;
                    break;
                case 3: // Unit Tact Start
                    s.UnitTactSec = 0;
                    s.UnitTimerRunning = true;
                    break;
                case 4: // Unit Tact End
                    s.UnitTimerRunning = false;
                    break;
            }
            StateHasChanged();
        });
    }

    // =========================================================================
    // UI Action Handlers — JIG Controls
    // =========================================================================

    private Task StartTest(int jig)
    {
        if (Status.AutoMode)
            return Task.CompletedTask; // Block in auto mode

        int ch1 = jig * 2;
        int ch2 = jig * 2 + 1;
        StartSingleChannel(ch1);
        StartSingleChannel(ch2);
        return Task.CompletedTask;
    }

    private Task StopTest(int jig)
    {
        int ch1 = jig * 2;
        int ch2 = jig * 2 + 1;
        StopSingleChannel(ch1);
        StopSingleChannel(ch2);
        return Task.CompletedTask;
    }

    private void ToggleLamp(int jig)
    {
        _lampOn[jig] = !_lampOn[jig];
        Dio.LampOnOff(jig, _lampOn[jig]);
    }

    private void ToggleIonizer(int jig)
    {
        _ionizerOn[jig] = !_ionizerOn[jig];
        Dio.SetIonizer(jig, _ionizerOn[jig]);
    }

    // =========================================================================
    // UI Action Handlers — Per-Channel Controls
    // =========================================================================

    private void StartSingleChannel(int ch)
    {
        if (ch < 0 || ch >= ChannelCount) return;
        if (!_ch[ch].Enabled) return;

        // Sync IsInUse (Delphi: PasScr[ch].m_bUse := chkChannelUse[ch].Checked)
        ScriptRunners[ch].IsInUse = true;

        // UI state update
        var s = _ch[ch];
        s.StatusCode = 1;
        s.StatusText = "Running";
        s.TotalTimerRunning = true;
        s.UnitTimerRunning = true;
        s.UnitTactSec = 0;

        // Update singleton cache so other pages see Running on navigation
        UiService.NotifyChannelStatus(ch, 1);

        AddChannelLog(ch, "Test started");

        // Execute script sequence
        // (Delphi: PasScr[ch].TestInfo.NgCode := 0; PasScr[ch].RunSeq(SEQ_KEY_START))
        ScriptRunners[ch].TestInfo.NgCode = 0;
        ScriptRunners[ch].RunSequence(DefScript.SeqKeyStart);
        ScriptRunners[ch].IsProbeBackSignal = false;

        StateHasChanged();
    }

    private void StopSingleChannel(int ch)
    {
        if (ch < 0 || ch >= ChannelCount) return;

        // Stop script (Delphi: JigControl.pas StopChannelScript)
        var script = ScriptRunners[ch];
        script.IsSyncSequence = false;
        script.CelStop = true;
        script.SetHostEvent(0);
        script.RunSequence(DefScript.SeqKeyStop);
        script.ConfirmHostReturn = 0;

        // UI state update
        var s = _ch[ch];
        s.StatusCode = 4;
        s.StatusText = "Stop";
        s.TotalTimerRunning = false;
        s.UnitTimerRunning = false;

        // Update singleton cache so other pages see Stop on navigation
        UiService.NotifyChannelStatus(ch, 4);

        AddChannelLog(ch, "Test stopped");
        StateHasChanged();
    }

    private void ResetCount(int ch)
    {
        if (ch < 0 || ch >= ChannelCount) return;

        var s = _ch[ch];
        s.OkCount = 0;
        s.NgCount = 0;
        s.TotalCount = 0;
        s.TotalTactSec = 0;
        s.UnitTactSec = 0;
        s.PrevResults.Clear();
        AddChannelLog(ch, "Count reset");
        StateHasChanged();
    }

    private void ClearChannelData(int ch)
    {
        if (ch < 0 || ch >= ChannelCount) return;

        var s = _ch[ch];
        s.SerialNo = "";
        s.StatusCode = 0;
        s.StatusText = "Ready";
        s.MesResult = "";
        s.NgCode = 0;
        s.OkCount = 0;
        s.NgCount = 0;
        s.TotalCount = 0;
        s.TotalTactSec = 0;
        s.UnitTactSec = 0;
        s.TotalTimerRunning = false;
        s.UnitTimerRunning = false;
        s.PrevResults.Clear();
        s.LogEntries.Clear();

        // Update singleton cache so other pages see Ready on navigation
        UiService.NotifyChannelStatus(ch, 0);

        StateHasChanged();
    }

    private void ToggleChannelEnabled(int ch)
    {
        if (ch < 0 || ch >= ChannelCount) return;
        _ch[ch].Enabled = !_ch[ch].Enabled;
        Status.SetChannelEnabled(ch, _ch[ch].Enabled);
        StateHasChanged();
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private void AddChannelLog(int ch, string msg)
    {
        var log = _ch[ch].LogEntries;
        log.Add($"[{DateTime.Now:HH:mm:ss}] {msg}");
        while (log.Count > MaxLogEntries)
            log.RemoveAt(0);
    }

    /// <summary>Formats seconds as "MMM:SS" (Delphi tact time format).</summary>
    internal static string FormatTactTime(int totalSeconds)
    {
        int min = totalSeconds / 60;
        int sec = totalSeconds % 60;
        return $"{min:D3}:{sec:D2}";
    }

    /// <summary>Formats seconds as "MM:SS" for unit tact time.</summary>
    internal static string FormatUnitTactTime(int totalSeconds)
    {
        int min = totalSeconds / 60;
        int sec = totalSeconds % 60;
        return $"{min:D2}:{sec:D2}";
    }

    private static string GetResultColor(int statusCode) => statusCode switch
    {
        2 => "background: #00C853; color: black;",  // PASS = lime green
        3 => "background: #D50000; color: white;",  // NG = red
        _ => ""
    };

    private static MudBlazor.Color GetResultChipColor(int statusCode) => statusCode switch
    {
        1 => MudBlazor.Color.Info,     // Running
        2 => MudBlazor.Color.Success,  // PASS
        3 => MudBlazor.Color.Error,    // NG
        4 => MudBlazor.Color.Warning,  // Stop
        _ => MudBlazor.Color.Default   // Ready
    };

    // =========================================================================
    // Per-Channel State Model
    // =========================================================================

    internal class ChannelState
    {
        // Basic info
        public bool Enabled;
        public string SerialNo = "";
        public string StatusText = "Ready";
        public int StatusCode; // 0=Ready, 1=Running, 2=Pass, 3=NG, 4=Stop
        public string MesResult = "";
        public int NgCode;

        // CA-410 colorimeter info
        public string Ca410Info = "";       // "CHx/Memory(y)/COMM(z)/SerialNo(w)"
        public bool Ca410Connected;

        // PG (Pattern Generator) per-channel info
        public string PgVersionText = "PG Disconnected";
        public bool PgConnected;
        public bool PgReady;
        public MudBlazor.Color PgLedColor = MudBlazor.Color.Dark;

        // Counts
        public int OkCount, NgCount, TotalCount;

        // Tact Time (seconds)
        public int TotalTactSec, UnitTactSec;
        public bool TotalTimerRunning, UnitTimerRunning;

        // Power Data (from PG)
        public double VccVoltage, VccCurrent; // V, mA
        public double VinVoltage, VinCurrent; // V, mA

        // DIO Sensor State — Input (DI, green LEDs)
        public bool DiProbeForward, DiProbeBackward, DiProbeUp, DiProbeDown;
        public bool DiCarrierLock1, DiCarrierLock2, DiCarrierLock3, DiCarrierLock4;
        public bool DiCarrierUnlock1, DiCarrierUnlock2, DiCarrierUnlock3, DiCarrierUnlock4;
        public bool DiDetect;

        // DIO Solenoid State — Output (DO, yellow LEDs)
        public bool DoProbeForward, DoProbeBackward, DoProbeUp, DoProbeDown;
        public bool DoCarrierLock, DoCarrierUnlock;

        // Previous Results (newest first)
        public List<(int NgCode, bool IsPass)> PrevResults = [];

        // Channel Log (newest at end)
        public List<string> LogEntries = [];
    }
}
