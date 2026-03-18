// =============================================================================
// Dashboard.razor.cs — Code-behind for main dashboard page.
// Replaces Main_OC.pas main form logic for status display and control.
// =============================================================================

using Dongaeltek.ITOLED.BusinessLogic.Inspection;
using Dongaeltek.ITOLED.BusinessLogic.Mes;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.OC.Components;
using Dongaeltek.ITOLED.OC.Services;
using Microsoft.AspNetCore.Components;
using MudBlazor;
using static Dongaeltek.ITOLED.OC.Components.LoginDialog;

namespace Dongaeltek.ITOLED.OC.Pages;

public partial class Dashboard : IDisposable
{
    [Inject] private ISystemStatusService Status { get; set; } = default!;
    [Inject] private IPlcEcsDriver Plc { get; set; } = default!;
    [Inject] private ICommPgDriver[] PgDrivers { get; set; } = default!;
    [Inject] private IAppInitializer AppInit { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private UiUpdateService UiService { get; set; } = default!;
    [Inject] private IConfigurationService Config { get; set; } = default!;
    [Inject] private IGmesCommunication? Gmes { get; set; }
    [Inject] private IPathManager PathManager { get; set; } = default!;
    [Inject] private IScriptRunner[] ScriptRunners { get; set; } = default!;
    [Inject] private IDioController Dio { get; set; } = default!;
    [Inject] private IModelInfoService ModelInfoService { get; set; } = default!;

    // ── Channel state ────────────────────────────────────────
    private readonly bool[] _channelEnabled = new bool[4];
    private readonly int[] _channelStatus = new int[4]; // 0=Ready, 1=Running, 2=PASS, 3=NG, 4=Stop
    private readonly string[] _channelStatusText = ["Stop", "Stop", "Stop", "Stop"];
    private readonly bool[] _channelNg = new bool[4];
    private readonly string[] _serialNos = ["", "", "", ""];
    private readonly string[] _channelResult = ["---", "---", "---", "---"];

    // ── Per-channel stage flow ───────────────────────────────
    private readonly int[] _channelStagePhase = new int[4]; // 0=Idle, 1=Load, 2=Power, 3=OC, 4=Report, 5=Unload
    private readonly int[] _stageStep = new int[3];

    // ── System state ─────────────────────────────────────────
    private bool _autoMode;
    private bool _canInitialize;
    private bool _initializing;
    private readonly double[] _tactTime = new double[4];
    private readonly List<string> _logEntries = [];

    // ── Login state (Delphi: Set_Login / DisplayMes) ────────
    private bool _isLoggedIn;
    private string _loginButtonText = "Log In";
    private string _mesStatusText = string.Empty;

    // ── MES/GMES connection state ──────────────────────────
    private bool _gmesConnected;

    // ── PG connection state (per-channel) ───────────────────
    private readonly bool[] _pgConnected = new bool[4];
    private readonly MudBlazor.Color[] _pgLedColor = [MudBlazor.Color.Dark, MudBlazor.Color.Dark, MudBlazor.Color.Dark, MudBlazor.Color.Dark];

    // ── Door/NG alarm state ──────────────────────────────────
    private bool _doorAlarmShowing;
    private bool _disposed;

    private System.Threading.Timer? _refreshTimer;

    protected override void OnInitialized()
    {
        // Restore cached channel state (survives page navigation)
        for (int ch = 0; ch < 4; ch++)
        {
            int status = UiService.GetLastChannelStatus(ch);
            _channelStatus[ch] = status;
            _channelStatusText[ch] = status switch
            {
                0 => "Ready", 1 => "Running", 2 => "PASS", 3 => "NG", 4 => "Stop", _ => "Unknown"
            };
            _channelStagePhase[ch] = UiService.GetLastChannelStagePhase(ch);
            _channelNg[ch] = status == 3;

            int ngCode = UiService.GetLastChannelNgCode(ch);
            if (ngCode >= 0)
                _channelResult[ch] = UiService.GetLastChannelResult(ch);
        }

        UiService.LogEntryAdded += OnLogEntry;
        UiService.ChannelStatusChanged += OnChannelStatusChanged;
        UiService.ChannelResultReady += OnChannelResult;
        UiService.StagePhaseChanged += OnStagePhaseChanged;
        UiService.DoorOpenAlarmRequested += OnDoorOpenAlarmRequested;
        UiService.NgAlarmRequested += OnNgAlarmRequested;

        // Subscribe to GMES events for MES_EDTI callback → DisplayMes(true)
        // Delphi: DongaGmes.OnGmsEvent := DongaGmesEvent
        if (Gmes is not null)
            Gmes.OnGmesEvent += OnGmesEvent;

        // 500ms refresh — replaces Delphi tmrMain TTimer
        // Thread-safety: all state mutations inside InvokeAsync
        _refreshTimer = new System.Threading.Timer(_ =>
        {
            SafeInvokeAsync(() =>
            {
                RefreshFromStatus();
                StateHasChanged();
            });
        }, null, 0, 500);
    }

    private void RefreshFromStatus()
    {
        _autoMode = Status.AutoMode;
        _canInitialize = AppInit.CanInitialize;
        _isLoggedIn = Status.IsLoggedIn;
        _loginButtonText = _isLoggedIn ? "Log Out" : "Log In";

        // NOTE: _mesStatusText is set ONLY by SetLogin/DisplayMes/OnGmesEvent
        // — NOT overwritten here, to avoid masking MES connection failures.

        for (int ch = 0; ch < 4; ch++)
        {
            _channelEnabled[ch] = Status.GetChannelEnabled(ch);
        }
        for (int i = 0; i < 3; i++)
        {
            _stageStep[i] = Status.GetStageStep(i);
        }

        // Stage phase is now driven by UiUpdateService events (StagePhaseChanged)
        // — no longer derived from LoadUnloadFlowData which only tracks PLC robot steps

        // PG connection status per channel (Delphi: ledPGStatuses LED per PG[CH1..MAX_CH])
        for (int ch = 0; ch < 4; ch++)
        {
            var pg = PgDrivers[ch];
            _pgConnected[ch] = pg.Status != PgStatus.Disconnected;
            _pgLedColor[ch] = pg.IsPgReady ? MudBlazor.Color.Success
                            : _pgConnected[ch] ? MudBlazor.Color.Warning
                            : MudBlazor.Color.Dark;
        }

        // Read tact time from PLC (per-channel)
        if (Plc.Connected)
        {
            for (int ch = 0; ch < 4; ch++)
            {
                int tactMs = Plc.ReadTactTime(ch);
                _tactTime[ch] = tactMs / 1000.0;
            }
        }
    }

    private void OnLogEntry(string message)
    {
        SafeInvokeAsync(() =>
        {
            _logEntries.Add($"[{DateTime.Now:HH:mm:ss}] {message}");
            if (_logEntries.Count > 500) _logEntries.RemoveAt(0);
            StateHasChanged();
        });
    }

    private void OnChannelStatusChanged(int ch, int statusCode)
    {
        if (ch < 0 || ch >= 4) return;
        SafeInvokeAsync(() =>
        {
            _channelStatus[ch] = statusCode;
            _channelStatusText[ch] = statusCode switch
            {
                0 => "Ready",
                1 => "Running",
                2 => "PASS",
                3 => "NG",
                4 => "Stop",
                _ => "Unknown"
            };
            // Stage phase is now handled by OnStagePhaseChanged (from UiUpdateService)
            _channelNg[ch] = statusCode == 3;
            StateHasChanged();
        });
    }

    private void OnStagePhaseChanged(int ch, int phase)
    {
        if (ch < 0 || ch >= 4) return;
        SafeInvokeAsync(() =>
        {
            _channelStagePhase[ch] = phase;
            StateHasChanged();
        });
    }

    private void OnChannelResult(int ch, int ngCode)
    {
        if (ch < 0 || ch >= 4) return;
        SafeInvokeAsync(() =>
        {
            _channelNg[ch] = ngCode > 0;
            _channelResult[ch] = ngCode == 0 ? "OK" : $"NG({ngCode})";
            _channelStatus[ch] = ngCode > 0 ? 3 : 2;
            _channelStatusText[ch] = ngCode > 0 ? "NG" : "PASS";
            StateHasChanged();
        });
    }

    private static MudBlazor.Color GetStatusColor(int statusCode) => statusCode switch
    {
        0 => MudBlazor.Color.Info,      // Ready — 파란색
        1 => MudBlazor.Color.Warning,   // Running — 노란색
        2 => MudBlazor.Color.Success,   // PASS — 초록색
        3 => MudBlazor.Color.Error,     // NG — 빨간색
        4 => MudBlazor.Color.Dark,      // Stop — 회색
        _ => MudBlazor.Color.Default
    };

    private async Task OnStartClick()
    {
        try
        {
            // ── Phase 1: 전 채널 공통 셋업 (PLC/Robot/PG 체크 + 채널 데이터 초기화) ──
            var setupTasks = ScriptRunners
                .Select(r => Task.Run(() => r.ExecuteAutoStart()))
                .ToArray();
            var setupResults = await Task.WhenAll(setupTasks);

            // 채널별 셋업 결과 로그 (상세 실패 사유 포함)
            for (int i = 0; i < setupResults.Length; i++)
            {
                if (setupResults[i] == null)
                    UiService.NotifyLog($"AutoStart CH{i + 1}: OK");
                else
                    UiService.NotifyLog($"AutoStart CH{i + 1}: FAIL - {setupResults[i]}");
            }

            if (setupResults.All(r => r != null))
            {
                Snackbar.Add("Auto Start 전체 실패 - 하단 로그 확인", Severity.Warning);
                return;
            }

            // ── Phase 2: 그룹별 모드 결정 ──
            // Group 0 = Jig A (CH1,CH2), Group 1 = Jig B (CH3,CH4)
            for (int group = 0; group < 2; group++)
            {
                int ch1 = group * 2;       // primary channel index
                int ch2 = group * 2 + 1;

                if (setupResults[ch1] != null && setupResults[ch2] != null)
                    continue; // 이 그룹은 셋업 실패 → skip

                bool detected = Dio.IsDetected(group);

                if (!detected)
                {
                    // ── Mode 1: Not Detected → Robot Load ──
                    UiService.NotifyLog($"Jig {(char)('A' + group)}: Not Detected → Robot Load Request");
                    await Task.Run(() => ScriptRunners[ch1].ExecuteRobotLoad());
                }
                else
                {
                    // ── Detected → 사용자 선택 다이얼로그 ──
                    UiService.NotifyLog($"Jig {(char)('A' + group)}: Detected → 사용자 선택 대기");
                    var result = await DialogService.ShowMessageBox(
                        $"CH{ch1 + 1},{ch2 + 1} Carrier Detected",
                        $"Jig {(char)('A' + group)} 에 패널이 감지되었습니다.\n검사를 시작하거나 언로드를 선택하세요.",
                        yesText: "Start Inspection",
                        noText: "Unload",
                        cancelText: "Cancel");

                    if (result == true)
                    {
                        // ── Mode 2: Detected → Start Inspection ──
                        UiService.NotifyLog($"Jig {(char)('A' + group)}: Start Inspection (CH{ch1 + 1}, CH{ch2 + 1})");

                        // Set Running status immediately (like Test4ChPage.StartSingleChannel)
                        foreach (var chIdx in new[] { ch1, ch2 })
                        {
                            if (setupResults[chIdx] == null) // setup 성공 채널만
                            {
                                _channelStatus[chIdx] = 1;
                                _channelStatusText[chIdx] = "Running";
                                _channelNg[chIdx] = false;
                                _channelResult[chIdx] = "---";
                                UiService.NotifyChannelStatus(chIdx, 1); // also sets stage phase
                            }
                        }
                        StateHasChanged();

                        await Task.WhenAll(
                            Task.Run(() => ScriptRunners[ch1].RunSequence(1)),
                            Task.Run(() => ScriptRunners[ch2].RunSequence(1)));
                    }
                    else if (result == false)
                    {
                        // ── Mode 3: Detected → Unload ──
                        UiService.NotifyLog($"Jig {(char)('A' + group)}: Robot Unload Request");
                        await Task.Run(() => ScriptRunners[ch1].ExecuteRobotUnload());
                    }
                    else
                    {
                        UiService.NotifyLog($"Jig {(char)('A' + group)}: Cancelled");
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Snackbar.Add($"Auto Start 오류: {ex.Message}", Severity.Error);
        }
    }

    private async Task OnStopClick()
    {
        await Task.Run(() => Plc.Stop());
    }

    private Task OnAlarmResetClick()
    {
        Status.ClearAlarms();
        return Task.CompletedTask;
    }

    private async Task OnInitializeClick()
    {
        // Delphi: btnInitClick confirmation dialog
        var result = await DialogService.ShowMessageBox(
            "SW Initialize",
            "프로그램을 초기화 하시겠습니까?\n(Are you sure you want to initialize this Program?)",
            yesText: "Yes", cancelText: "No");

        if (result != true) return;

        _initializing = true;
        StateHasChanged();

        try
        {
            var success = await AppInit.InitializeAllAsync();
            Snackbar.Add(
                success ? "SW 초기화 완료" : "초기화 실패 (AutoMode 또는 검사 중)",
                success ? Severity.Success : Severity.Error);
        }
        finally
        {
            _initializing = false;
            StateHasChanged();
        }
    }

    // ── Login logic (Delphi: Set_Login / Login_MES / InitGmes / DisplayMes) ──

    private async Task OnLoginClick()
    {
        if (Status.AutoMode)
        {
            Snackbar.Add("Auto 모드에서는 Login 변경 불가", Severity.Warning);
            return;
        }

        var confirm = await DialogService.ShowMessageBox(
            "Confirm",
            "Do you want to change Login?",
            yesText: "OK", cancelText: "Cancel");

        if (confirm != true) return;

        await SetLogin(!Status.IsLoggedIn);
    }

    /// <summary>
    /// Delphi origin: TfrmMain_OC.Set_Login(bLogin) — Main_OC.pas:5322-5362
    /// </summary>
    private async Task SetLogin(bool login)
    {
        var sysInfo = Config.SystemInfo;
        if (sysInfo == null) return;

        UiService.NotifyLog($"Set_Login({login})");

        if (sysInfo.UseECS)
        {
            // ECS: 즉시 로그인 상태 설정 (EDTI 핸드셰이크 없음)
            Status.IsLoggedIn = login;
            _mesStatusText = login ? "ECS Report ON" : "ECS Report OFF";
            UiService.NotifyLog(login ? "ECS Report ON" : "ECS Report OFF");
        }

        if (sysInfo.UseMES)
        {
            if (login)
            {
                // MES: 아직 로그인 상태 설정하지 않음
                // EDTI 성공 시 DisplayMes(true)에서 Status.IsLoggedIn = true 설정
                await LoginMes();
            }
            else
            {
                // 로그아웃: 즉시 해제
                if (Gmes is not null)
                    Gmes.MesUserId = "PM";
                _gmesConnected = false;
                DisplayMes(false);
            }
        }

        // ECS도 아니고 MES도 아닌 경우에만 직접 설정
        if (!sysInfo.UseECS && !sysInfo.UseMES)
        {
            Status.IsLoggedIn = login;
        }

        StateHasChanged();
    }

    /// <summary>
    /// Delphi origin: TfrmMain_OC.Login_MES — Main_OC.pas:2300-2443
    /// Called from SetLogin(true) when UseMES is true.
    /// </summary>
    private async Task LoginMes()
    {
        var sysInfo = Config.SystemInfo;
        if (sysInfo == null || string.IsNullOrWhiteSpace(sysInfo.ServicePort))
        {
            Snackbar.Add("GMES Configuration이 올바르지 않습니다", Severity.Error);
            return;
        }

        if (Gmes is null)
        {
            UiService.NotifyLog("GMES not initialized");
            return;
        }

        if (sysInfo.OcManualType)
        {
            // OcManualType: show UserID dialog (Delphi: DisplayLogIn → TUserIdDlg.ShowModal)
            var userId = await ShowUserIdDialog();

            if (userId is null)
            {
                // Cancel → PM mode, MES OFF (Delphi: nRet=mrCancel → PM, MES OFF)
                Gmes.MesUserId = "PM";
                DisplayMes(false);
                UiService.NotifyLog("Login_MES: Cancelled → PM Mode");
                return;
            }

            if (string.Equals(userId, "PM", StringComparison.OrdinalIgnoreCase))
            {
                // PM mode — no real user
                Gmes.MesUserId = "PM";
                _gmesConnected = false;
                DisplayMes(false);
                UiService.NotifyLog("Login_MES: PM Mode");
            }
            else
            {
                // Real user → UCHK or EAYT
                Gmes.MesUserId = userId;
                UiService.NotifyLog($"Login_MES: UserId={userId}");

                if (!Gmes.CanUseHost)
                {
                    // HOST not connected → InitGmes (HostInitial + SendHostStart)
                    InitGmes();
                }
                else
                {
                    // HOST already connected → UCHK/EAYT
                    // Delphi: if not DongaGmes.MesEayt then SendHostUchk else SendHostEayt
                    if (!Gmes.MesEayt)
                        Gmes.SendHostUchk();
                    else
                        Gmes.SendHostEayt();
                }
            }
        }
        else
        {
            // Non-OcManualType: show UserID dialog too
            var userId = await ShowUserIdDialog();

            if (userId is null)
            {
                // Cancel
                UiService.NotifyLog("Login_MES: Cancelled");
                DisplayMes(false);
                return;
            }

            Gmes.MesUserId = userId;
            UiService.NotifyLog($"Login_MES: UserId={userId}");

            if (!Gmes.CanUseHost)
            {
                InitGmes();
            }
            else
            {
                // Already connected → re-send UCHK
                Gmes.SendHostUchk();
            }
        }
    }

    /// <summary>
    /// Shows the UserID input dialog. Replaces Delphi DisplayLogIn (Main_OC.pas:1436-1447).
    /// Returns the entered userId, or null if cancelled.
    /// </summary>
    private async Task<string?> ShowUserIdDialog()
    {
        var sysInfo = Config.SystemInfo;

        // Pre-fill with AutoLoginID if available
        var defaultId = sysInfo == null || string.IsNullOrWhiteSpace(sysInfo.AutoLoginID) ? "" : sysInfo.AutoLoginID;

        var parameters = new DialogParameters
        {
            { nameof(UserIdDialog.DefaultUserId), defaultId }
        };

        var options = new DialogOptions
        {
            CloseOnEscapeKey = true,
            MaxWidth = MaxWidth.Small,
            FullWidth = false
        };

        var dialog = await DialogService.ShowAsync<UserIdDialog>("User ID", parameters, options);
        var result = await dialog.Result;

        if (result is null || result.Canceled)
            return null;

        return result.Data as string;
    }

    /// <summary>
    /// Delphi origin: TfrmMain_OC.InitGmes — Main_OC.pas:1982-2100
    /// Initializes HOST/EAS connection and sends EAYT→UCHK→EDTI.
    /// EDTI callback (OnGmesEvent) will trigger DisplayMes(true).
    /// </summary>
    private void InitGmes()
    {
        if (Gmes is null) return;

        var sysInfo = Config.SystemInfo;
        if (sysInfo == null) return;

        // Set userId (Delphi: OCType=OCType → AutoLoginID, else m_sUserId)
        if (sysInfo.OCType == ChannelConstants.OcType)
        {
            if (!string.IsNullOrWhiteSpace(sysInfo.AutoLoginID))
                Gmes.MesUserId = sysInfo.AutoLoginID;
        }

        // Set MES system properties
        Gmes.MesSystemNo = sysInfo.EQPId;
        Gmes.MesSystemNoMgib = sysInfo.EQPIdMGIB;
        Gmes.MesSystemNoPgib = sysInfo.EQPIdPGIB;
        Gmes.MesModelInfo = sysInfo.MesModelInfo;

        // Validate config
        if (string.IsNullOrWhiteSpace(sysInfo.ServicePort) ||
            string.IsNullOrWhiteSpace(sysInfo.DaemonPort) ||
            string.IsNullOrWhiteSpace(sysInfo.RemoteSubject))
        {
            UiService.NotifyLog($"MES Info is Empty (ServicePort={sysInfo.ServicePort}, DaemonPort={sysInfo.DaemonPort}, RemoteSubject={sysInfo.RemoteSubject})");
            return;
        }

        // Diagnostic log: show connection parameters
        UiService.NotifyLog($"InitGmes: ServicePort={sysInfo.ServicePort}, Network={sysInfo.Network}, " +
            $"DaemonPort={sysInfo.DaemonPort}, Local={sysInfo.LocalSubject}, Remote={sysInfo.RemoteSubject}, " +
            $"LogDir={PathManager.MesLogDir}");

        // Connect to HOST (Delphi: HOST_Initial)
        bool hostOk = Gmes.HostInitial(
            sysInfo.ServicePort,
            sysInfo.Network,
            sysInfo.DaemonPort,
            sysInfo.LocalSubject,
            sysInfo.RemoteSubject,
            PathManager.MesLogDir);

        if (hostOk)
        {
            _gmesConnected = true;
            UiService.NotifyLog("MES Connected");

            // Set FTP properties
            Gmes.FtpAddr = sysInfo.HostFTPIPAddr;
            Gmes.FtpUser = sysInfo.HostFTPUser;
            Gmes.FtpPass = sysInfo.HostFTPPasswd;
            Gmes.FtpCombiPath = sysInfo.HostFTPCombiPath;

            // Start MES sequence: EAYT → UCHK → EDTI
            // EDTI callback will fire OnGmesEvent → DisplayMes(true)
            Gmes.SendHostStart();
        }
        else
        {
            _gmesConnected = false;
            UiService.NotifyLog("MES Disconnected");
            DisplayMes(false);
        }
    }

    /// <summary>
    /// GMES event callback. Replaces Delphi DongaGmesEvent (Main_OC.pas:2706-2766).
    /// When MES_EDTI succeeds → DisplayMes(true) (MES Login OK).
    /// When MES_UCHK succeeds → update user info.
    /// </summary>
    private void OnGmesEvent(int msgType, int pg, bool isError, string errMsg)
    {
        SafeInvokeAsync(() =>
        {
            switch (msgType)
            {
                case DefGmes.MesEdti:
                    // Delphi: SendMsgAddLog(MSG_MODE_DISPLAY, 1, 0, 'MES_Login OK!!!')
                    //       → Main_OC receives → DisplayMes(True)
                    if (!isError)
                    {
                        _gmesConnected = true;
                        UiService.NotifyLog("MES_Login OK!!!");
                        DisplayMes(true);
                    }
                    else
                    {
                        UiService.NotifyLog($"MES_EDTI Error: {errMsg}");
                        DisplayMes(false);
                    }
                    break;

                case DefGmes.MesUchk:
                    if (!isError && Gmes is not null)
                    {
                        UiService.NotifyLog($"UCHK OK - User: {Gmes.MesUserName}");
                    }
                    else
                    {
                        UiService.NotifyLog($"MES_UCHK Error: {errMsg}");
                    }
                    break;

                case DefGmes.MesEayt:
                    if (isError)
                        UiService.NotifyLog($"MES_EAYT Error: {errMsg}");
                    break;
            }
            StateHasChanged();
        });
    }

    /// <summary>
    /// Delphi origin: TfrmMain_OC.DisplayMes(bIsOn) — Main_OC.pas:1449-1487
    /// </summary>
    private void DisplayMes(bool isOn)
    {
        var sysInfo = Config.SystemInfo;
        if (sysInfo == null || !sysInfo.UseMES) return;

        if (isOn)
        {
            Status.IsLoggedIn = true;
            _loginButtonText = "Log Out";
            _mesStatusText = sysInfo.UseGIB ? "MES GIB ON" : "MES ON";
            UiService.NotifyLog("MES Login On");
        }
        else
        {
            Status.IsLoggedIn = false;
            _loginButtonText = "Log In";
            _mesStatusText = sysInfo.UseGIB ? "MES GIB OFF" : "MES OFF";
            UiService.NotifyLog("MES Login Off");
        }
    }

    private string GetChannelStyle(int ch)
    {
        if (!_channelEnabled[ch]) return "opacity: 0.5;";
        if (_channelNg[ch]) return "border-left: 4px solid var(--mud-palette-error);";
        if (_channelStatus[ch] == 1) return "border-left: 4px solid var(--mud-palette-info);"; // Running
        if (_channelStatus[ch] == 2) return "border-left: 4px solid var(--mud-palette-success);"; // PASS
        return "";
    }

    // ── Admin Login Helper ────────────────────────────────────────

    private async Task<LoginResult?> ShowAdminLoginDialog()
    {
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small };
        var dialog = await DialogService.ShowAsync<LoginDialog>("Admin Login", options);
        var result = await dialog.Result;
        if (result is null || result.Canceled) return null;
        return result.Data as LoginResult;
    }

    // ── Model Change (Delphi: btnModelChangeClick) ────────────────

    private async Task OnModelChangeClick()
    {
        if (Status.AutoMode)
        {
            Snackbar.Add("Auto 모드에서는 모델 변경 불가", Severity.Warning);
            return;
        }

        // Step 1: Admin login
        var loginResult = await ShowAdminLoginDialog();
        if (loginResult is null) return;

        // Step 2: Model select
        var modelParams = new DialogParameters
        {
            { nameof(ModelSelectDialog.CurrentModel), Config.SystemInfo?.TestModel ?? "" }
        };
        var modelOptions = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Medium, FullWidth = true };
        var modelDialog = await DialogService.ShowAsync<ModelSelectDialog>("Select Model", modelParams, modelOptions);
        var modelResult = await modelDialog.Result;
        if (modelResult is null || modelResult.Canceled) return;
        var selectedModel = modelResult.Data as string;
        if (string.IsNullOrEmpty(selectedModel)) return;

        // Step 3: Load model
        if (!ModelInfoService.LoadModel(selectedModel))
        {
            Snackbar.Add($"모델 '{selectedModel}' 로드 실패", Severity.Error);
            return;
        }
        Config.SystemInfo!.TestModel = selectedModel;
        Config.SaveSystemInfo();
        UiService.NotifyLog($"Model changed to: {selectedModel}");
        Snackbar.Add($"모델 '{selectedModel}' 로드 완료", Severity.Success);

        // Clear stale channel results from previous model
        UiService.ClearAllChannelResults();
        StateHasChanged();

        // Step 4: Model download (PG pattern upload) — waits for all 4CH
        var dlOptions = new DialogOptions { CloseButton = false, BackdropClick = false, MaxWidth = MaxWidth.Small, FullWidth = true };
        var dlDialog = await DialogService.ShowAsync<ModelDownloadDialog>("Model Download", dlOptions);
        await dlDialog.Result;

        // Step 5: Auto SW Initialize after 4CH download complete
        if (AppInit.CanInitialize)
        {
            UiService.NotifyLog("[ModelChange] 4CH 다운로드 완료 → SW 자동 초기화 시작");
            var success = await AppInit.InitializeAllAsync();
            Snackbar.Add(success ? "SW 초기화 완료" : "초기화 실패", success ? Severity.Success : Severity.Error);
        }
    }

    // ── Change Password ───────────────────────────────────────────

    private async Task OnChangePasswordClick()
    {
        if (Status.AutoMode)
        {
            Snackbar.Add("Auto 모드에서는 비밀번호 변경 불가", Severity.Warning);
            return;
        }

        // Require admin login first
        var loginResult = await ShowAdminLoginDialog();
        if (loginResult is null) return;

        var pwParams = new DialogParameters
        {
            { nameof(PasswordChangeDialog.IsSupervisor), loginResult.IsSupervisor }
        };
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small };
        var dialog = await DialogService.ShowAsync<PasswordChangeDialog>("Change Password", pwParams, options);
        var result = await dialog.Result;
        if (result is not null && !result.Canceled)
            Snackbar.Add("비밀번호가 변경되었습니다", Severity.Success);
    }

    // ── Door Open Alarm Auto-Trigger ──────────────────────────────

    private void OnDoorOpenAlarmRequested(bool doorOpened)
    {
        if (!doorOpened || _doorAlarmShowing) return;
        SafeInvokeAsync(async () =>
        {
            _doorAlarmShowing = true;
            try
            {
                var options = new DialogOptions
                {
                    CloseButton = false,
                    BackdropClick = false,
                    CloseOnEscapeKey = false,
                    MaxWidth = MaxWidth.Small
                };
                var dialog = await DialogService.ShowAsync<DoorOpenAlarmDialog>("Door Open Alarm", options);
                await dialog.Result;
            }
            finally
            {
                _doorAlarmShowing = false;
            }
        });
    }

    // ── NG Alarm Auto-Trigger ─────────────────────────────────────

    private void OnNgAlarmRequested(int ch, string message)
    {
        SafeInvokeAsync(async () =>
        {
            var parameters = new DialogParameters
            {
                { nameof(NgMessageDialog.Message), message }
            };
            var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small };
            await DialogService.ShowAsync<NgMessageDialog>("NG Alarm", parameters, options);
        });
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
        UiService.LogEntryAdded -= OnLogEntry;
        UiService.ChannelStatusChanged -= OnChannelStatusChanged;
        UiService.ChannelResultReady -= OnChannelResult;
        UiService.StagePhaseChanged -= OnStagePhaseChanged;
        UiService.DoorOpenAlarmRequested -= OnDoorOpenAlarmRequested;
        UiService.NgAlarmRequested -= OnNgAlarmRequested;
        if (Gmes is not null)
            Gmes.OnGmesEvent -= OnGmesEvent;
    }
}
