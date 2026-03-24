// =============================================================================
// UiUpdateService.cs — Bridges IMessageBus events to Blazor UI updates.
// Replaces Delphi's WM_COPYDATA → Control.BeginInvoke pattern.
// Components subscribe to specific events; service triggers StateHasChanged.
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Logging;
using Dongaeltek.ITOLED.BusinessLogic.Scripting;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.Messaging;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.OC.Services;

/// <summary>
/// Singleton service that subscribes to MessageBus topics and
/// re-raises them as C# events that Blazor components can subscribe to.
/// </summary>
public sealed class UiUpdateService : IDisposable
{
    private readonly IMessageBus _bus;
    private readonly MLogWriter? _mLog;
    private readonly List<IDisposable> _subscriptions = [];

    /// <summary>Raised when PLC status changes.</summary>
    public event Action? PlcStatusChanged;

    /// <summary>Raised when DIO signal state changes.</summary>
    public event Action? DioStatusChanged;

    /// <summary>Raised when inspection results are available.</summary>
    public event Action? InspectionResultReady;

    /// <summary>Raised when a log entry is added.</summary>
    public event Action<string>? LogEntryAdded;

    /// <summary>Raised when ECS glass data is updated.</summary>
    public event Action? EcsDataChanged;

    /// <summary>Raised on general UI refresh tick.</summary>
    public event Action? RefreshTick;

    /// <summary>Raised when a channel inspection result is available (channel, ngCode).</summary>
    public event Action<int, int>? ChannelResultReady;

    /// <summary>Raised when a channel log entry is added (channel, message).</summary>
    public event Action<int, string>? ChannelLogAdded;

    /// <summary>Raised when power data is updated for a PG (pgIndex).</summary>
    public event Action<int>? PowerDataUpdated;

    /// <summary>Raised when a channel status changes (channel, statusCode).</summary>
    public event Action<int, int>? ChannelStatusChanged;

    /// <summary>Raised when a CA-410 event is received (channel, mode, param, isError, message).</summary>
    public event Action<int, int, int, bool, string>? Ca410EventReceived;

    /// <summary>Raised when tact time starts/stops (channel, option: 1=TotalStart, 2=TotalEnd, 3=UnitStart, 4=UnitEnd).</summary>
    public event Action<int, int>? TactTimeChanged;

    /// <summary>Raised when a channel stage phase changes (channel, phase: 0=Idle,1=Load,2=Power,3=OC,4=Report,5=Unload).</summary>
    public event Action<int, int>? StagePhaseChanged;

    /// <summary>Raised when PLC reports door opened (UI should show DoorOpenAlarmDialog).</summary>
    public event Action<bool>? DoorOpenAlarmRequested;

    /// <summary>Raised when continuous NG count exceeds threshold (channel, message).</summary>
    public event Action<int, string>? NgAlarmRequested;

    // ── PG Transport mode (set by Program.cs at startup) ──────────────
    /// <summary>PG 통신 모드 표시 문자열 ("DPDK" / "Socket" / "Socket (DPDK 실패)").</summary>
    public string PgTransportMode { get; set; } = "---";

    /// <summary>DPDK 초기화 실패 후 Socket으로 폴백했으면 true.</summary>
    public bool IsDpdkFallback { get; set; }

    // ── Cached last-known state per channel (survives page navigation) ──
    private const int MaxCachedLogEntries = 200;
    private const int MaxCachedPrevResults = 20;

    private readonly int[] _lastChannelStagePhase = new int[4]; // 0=Idle,1=Load,2=Power,3=OC,4=Report,5=Unload
    private readonly int[] _lastChannelStatus = [4, 4, 4, 4]; // default: Stop
    private readonly int[] _lastChannelNgCode = [-1, -1, -1, -1]; // -1 = no result yet
    private readonly string[] _lastChannelResult = ["---", "---", "---", "---"];
    private readonly int[] _lastChannelOkCount = new int[4];
    private readonly int[] _lastChannelNgCount = new int[4];
    private readonly string[] _lastChannelSerialNo = ["", "", "", ""];
    private readonly List<string>[] _lastChannelLogs = [[], [], [], []];
    private readonly List<(int NgCode, bool IsPass)>[] _lastChannelPrevResults = [[], [], [], []];
    private readonly object[] _channelLocks = [new(), new(), new(), new()];

    // ── NG alarm tracking ─────────────────────────────────────────────
    private readonly int[] _continuousNgCount = new int[4];
    private int _ngAlarmThreshold;

    /// <summary>Sets the continuous NG alarm threshold. 0 = disabled.</summary>
    public void SetNgAlarmThreshold(int count) => _ngAlarmThreshold = count;

    /// <summary>Returns last known channel stage phase (0=Idle,1=Load,2=Power,3=OC,4=Report,5=Unload).</summary>
    public int GetLastChannelStagePhase(int ch) => (ch >= 0 && ch < 4) ? _lastChannelStagePhase[ch] : 0;

    /// <summary>Returns last known channel status code (0=Ready,1=Running,2=PASS,3=NG,4=Stop).</summary>
    public int GetLastChannelStatus(int ch) => (ch >= 0 && ch < 4) ? _lastChannelStatus[ch] : 4;

    /// <summary>Returns last known channel NG code (-1 if no result yet).</summary>
    public int GetLastChannelNgCode(int ch) => (ch >= 0 && ch < 4) ? _lastChannelNgCode[ch] : -1;

    /// <summary>Returns last known channel result string.</summary>
    public string GetLastChannelResult(int ch) => (ch >= 0 && ch < 4) ? _lastChannelResult[ch] : "---";

    /// <summary>Returns OK/NG counts for channel.</summary>
    public (int Ok, int Ng) GetLastChannelCounts(int ch) =>
        (ch >= 0 && ch < 4) ? (Volatile.Read(ref _lastChannelOkCount[ch]), Volatile.Read(ref _lastChannelNgCount[ch])) : (0, 0);

    /// <summary>Returns last known serial number for channel.</summary>
    public string GetLastChannelSerialNo(int ch) => (ch >= 0 && ch < 4) ? _lastChannelSerialNo[ch] : "";

    /// <summary>Returns cached log entries for channel (copy).</summary>
    public List<string> GetLastChannelLogs(int ch)
    {
        if (ch < 0 || ch >= 4) return [];
        lock (_channelLocks[ch])
        {
            return new List<string>(_lastChannelLogs[ch]);
        }
    }

    /// <summary>Returns cached previous results for channel (copy).</summary>
    public List<(int NgCode, bool IsPass)> GetLastChannelPrevResults(int ch)
    {
        if (ch < 0 || ch >= 4) return [];
        lock (_channelLocks[ch])
        {
            return new List<(int, bool)>(_lastChannelPrevResults[ch]);
        }
    }

    public UiUpdateService(IMessageBus bus, MLogWriter? mLog = null)
    {
        _bus = bus;
        _mLog = mLog;

        // Subscribe to CA-410 events from the message bus
        _subscriptions.Add(
            _bus.Subscribe<Ca410EventMessage>(msg =>
            {
                // CA-410 activity → Measure phase
                UpdateStagePhase(msg.Channel, 3);
                Ca410EventReceived?.Invoke(msg.Channel, msg.Mode, msg.Param, msg.IsError, msg.Message);
            }));

        // Subscribe to Script GUI messages — bridge between CSX scripts and Blazor UI
        // Replaces Delphi WM_COPYDATA handler in Test4ChOC.pas (MSG_TYPE_SCRIPT)
        _subscriptions.Add(
            _bus.Subscribe<ScriptGuiMessage>(OnScriptGuiMessage));

        // Subscribe to DLL event messages — bridge between OC DLL callbacks and Blazor UI
        // Replaces Delphi WM_COPYDATA handler in Test4ChOC.pas (MSG_TYPE_DLL)
        _subscriptions.Add(
            _bus.Subscribe<DllEventMessage>(OnDllEvent));

        // Subscribe to PLC events — door open alarm
        // Replaces Delphi Main_OC WM_COPYDATA → ProcessDoorOpenInfo
        _subscriptions.Add(
            _bus.Subscribe<PlcEventMessage>(OnPlcEvent));
    }

    private void OnScriptGuiMessage(ScriptGuiMessage msg)
    {
        switch (msg.Mode)
        {
            case MessageConstants.MsgModeWorking:
                // Script log messages → channel log display + cache
                // If Idle → Load phase (first script activity = flow starting)
                if (msg.Channel >= 0 && msg.Channel < 4 && _lastChannelStagePhase[msg.Channel] == 0)
                    UpdateStagePhase(msg.Channel, 1); // Load
                CacheChannelLog(msg.Channel, msg.Msg);
                ChannelLogAdded?.Invoke(msg.Channel, msg.Msg);
                break;

            case MessageConstants.MsgModeChResult:
                // Test result (PASS/NG) → result display + count update + cache
                // Param carries NgCode (0=PASS, >0=NG code)
                if (msg.Channel >= 0 && msg.Channel < 4)
                {
                    string? ngAlarmMsg = null;
                    lock (_channelLocks[msg.Channel])
                    {
                        _lastChannelNgCode[msg.Channel] = msg.Param;
                        _lastChannelResult[msg.Channel] = msg.Param == 0 ? "OK" : $"NG({msg.Param})";
                        _lastChannelStatus[msg.Channel] = msg.Param > 0 ? 3 : 2;

                        // Continuous NG alarm tracking (atomic under lock)
                        if (msg.Param > 0)
                        {
                            _continuousNgCount[msg.Channel]++;
                            if (_ngAlarmThreshold > 0 && _continuousNgCount[msg.Channel] >= _ngAlarmThreshold)
                            {
                                ngAlarmMsg = $"CH{msg.Channel + 1} 연속 NG {_continuousNgCount[msg.Channel]}회 발생 (NG Code: {msg.Param})";
                                _continuousNgCount[msg.Channel] = 0;
                            }
                        }
                        else
                        {
                            _continuousNgCount[msg.Channel] = 0;
                        }
                    }
                    CacheChannelResult(msg.Channel, msg.Param);
                    if (ngAlarmMsg != null)
                        NgAlarmRequested?.Invoke(msg.Channel, ngAlarmMsg);
                }
                UpdateStagePhase(msg.Channel, 4); // Report
                ChannelResultReady?.Invoke(msg.Channel, msg.Param);
                break;

            case MessageConstants.MsgModeShowSerialNumber:
                // Serial number display + cache
                if (msg.Channel >= 0 && msg.Channel < 4)
                    _lastChannelSerialNo[msg.Channel] = msg.Msg;
                CacheChannelLog(msg.Channel, $"S/N: {msg.Msg}");
                ChannelLogAdded?.Invoke(msg.Channel, $"S/N: {msg.Msg}");
                break;

            case MessageConstants.MsgModePowerOn:
                UpdateStagePhase(msg.Channel, 2); // Power
                CacheChannelLog(msg.Channel, "Power ON");
                ChannelLogAdded?.Invoke(msg.Channel, "Power ON");
                break;

            case MessageConstants.MsgModePowerOff:
                CacheChannelLog(msg.Channel, "Power OFF");
                ChannelLogAdded?.Invoke(msg.Channel, "Power OFF");
                break;

            case MessageConstants.MsgModePatDisplay:
                UpdateStagePhase(msg.Channel, 3); // OC
                CacheChannelLog(msg.Channel, $"Pattern Display ({msg.Param})");
                ChannelLogAdded?.Invoke(msg.Channel, $"Pattern Display ({msg.Param})");
                break;

            case MessageConstants.MsgModeChClear:
                // Channel clear/init → Load phase (new cycle beginning)
                UpdateStagePhase(msg.Channel, 1); // Load
                break;

            case MessageConstants.MsgModeSyncWork:
                // Sync work notification — status update + cache
                if (msg.Channel >= 0 && msg.Channel < 4)
                {
                    int phase;
                    lock (_channelLocks[msg.Channel])
                    {
                        _lastChannelStatus[msg.Channel] = msg.Param;
                        // Stage phase mapping:
                        // Ready/Stop → Idle, Running → Load if Idle else keep,
                        // PASS/NG → Report
                        phase = msg.Param switch
                        {
                            0 or 4 => 0, // Ready/Stop → Idle
                            1 => _lastChannelStagePhase[msg.Channel] == 0
                                ? 1 // Idle → Load
                                : _lastChannelStagePhase[msg.Channel], // keep current
                            2 => 4, // PASS → Report
                            3 => 4, // NG → Report
                            _ => 0
                        };
                    }
                    UpdateStagePhase(msg.Channel, phase);
                }
                ChannelStatusChanged?.Invoke(msg.Channel, msg.Param);
                break;

            case MessageConstants.MsgModeTactStart:
                // Tact start → ensure Load phase if still Idle
                if (msg.Channel >= 0 && msg.Channel < 4 && _lastChannelStagePhase[msg.Channel] == 0)
                    UpdateStagePhase(msg.Channel, 1); // Load
                TactTimeChanged?.Invoke(msg.Channel, 1);
                break;

            case MessageConstants.MsgModeTactEnd:
                // Tact end → Unload phase if we're in Report (flow completed)
                if (msg.Channel >= 0 && msg.Channel < 4 && _lastChannelStagePhase[msg.Channel] >= 4)
                    UpdateStagePhase(msg.Channel, 5); // Unload
                TactTimeChanged?.Invoke(msg.Channel, 2);
                break;

            case MessageConstants.MsgModeUnitTtStart:
                TactTimeChanged?.Invoke(msg.Channel, 3);
                break;

            case MessageConstants.MsgModeUnitTtEnd:
                TactTimeChanged?.Invoke(msg.Channel, 4);
                break;
        }
    }

    private void OnPlcEvent(PlcEventMessage msg)
    {
        if (msg.Param == CommPlcConst.ParamDoorOpened)
        {
            bool doorOpened = msg.Param2 != 0;
            DoorOpenAlarmRequested?.Invoke(doorOpened);
        }
    }

    /// <summary>
    /// Handles DLL event messages (OC DLL callbacks → UI).
    /// Replaces Delphi Test4ChOC.pas MSG_TYPE_DLL handler (lines 4747-4866).
    /// </summary>
    private void OnDllEvent(DllEventMessage msg)
    {
        switch (msg.Mode)
        {
            case MsgMode.Working:
                // Delphi: if nTemp=10 → Common.AddLog only (file log, skip UI)
                if (msg.Param == 10)
                    break;
                // DLL is actively working → OC phase
                if (msg.Channel >= 0 && msg.Channel < 4)
                    UpdateStagePhase(msg.Channel, 3); // OC
                // Delphi: AddLog('[DLL] ' + sMsg, nCh, nTemp)
                var dllMsg = $"[DLL] {msg.Message}";
                CacheChannelLog(msg.Channel, dllMsg);
                ChannelLogAdded?.Invoke(msg.Channel, dllMsg);
                // mlog 파일 기록 (Delphi: Common.AddLog → MLog 파일에도 기록)
                _mLog?.Write(msg.Channel, dllMsg);
                break;

            case MsgMode.WorkDone:
                // Delphi: AddLog('DLL DONE : X, NG Code=Y')
                var dllDoneMsg = $"DLL DONE : {msg.Channel + 1}, NG Code={msg.Param}";
                CacheChannelLog(msg.Channel, dllDoneMsg);
                ChannelLogAdded?.Invoke(msg.Channel, dllDoneMsg);
                _mLog?.Write(msg.Channel, dllDoneMsg);
                // Cache + result UI update (ngCode → PASS/NG display)
                if (msg.Channel >= 0 && msg.Channel < 4)
                {
                    lock (_channelLocks[msg.Channel])
                    {
                        _lastChannelNgCode[msg.Channel] = msg.Param;
                        _lastChannelResult[msg.Channel] = msg.Param == 0 ? "OK" : $"NG({msg.Param})";
                        _lastChannelStatus[msg.Channel] = msg.Param > 0 ? 3 : 2;
                    }
                    CacheChannelResult(msg.Channel, msg.Param);
                }
                UpdateStagePhase(msg.Channel, 4); // Report
                ChannelResultReady?.Invoke(msg.Channel, msg.Param);
                break;
        }
    }

    /// <summary>
    /// Manually trigger a UI refresh for all subscribers.
    /// </summary>
    public void NotifyRefresh() => RefreshTick?.Invoke();

    public void NotifyPlcChanged() => PlcStatusChanged?.Invoke();
    public void NotifyDioChanged() => DioStatusChanged?.Invoke();
    public void NotifyInspectionResult() => InspectionResultReady?.Invoke();
    public void NotifyLog(string message) => LogEntryAdded?.Invoke(message);
    public void NotifyEcsData() => EcsDataChanged?.Invoke();
    public void NotifyChannelResult(int ch, int ngCode)
    {
        if (ch >= 0 && ch < 4)
        {
            lock (_channelLocks[ch])
            {
                _lastChannelNgCode[ch] = ngCode;
                _lastChannelResult[ch] = ngCode == 0 ? "OK" : $"NG({ngCode})";
                _lastChannelStatus[ch] = ngCode > 0 ? 3 : 2;
            }
            CacheChannelResult(ch, ngCode);
        }
        UpdateStagePhase(ch, 4); // Report
        ChannelResultReady?.Invoke(ch, ngCode);
    }
    public void NotifyChannelLog(int ch, string msg)
    {
        CacheChannelLog(ch, msg);
        ChannelLogAdded?.Invoke(ch, msg);
    }
    public void NotifyPowerData(int pgNo) => PowerDataUpdated?.Invoke(pgNo);
    public void NotifyChannelStatus(int ch, int status)
    {
        if (ch >= 0 && ch < 4)
        {
            int phase;
            lock (_channelLocks[ch])
            {
                _lastChannelStatus[ch] = status;
                phase = status switch
                {
                    0 or 4 => 0, // Ready/Stop → Idle
                    1 => _lastChannelStagePhase[ch] == 0
                        ? 1 // Idle → Load
                        : _lastChannelStagePhase[ch], // keep current
                    2 => 4, // PASS → Report
                    3 => 4, // NG → Report
                    _ => 0
                };
            }
            UpdateStagePhase(ch, phase);
        }
        ChannelStatusChanged?.Invoke(ch, status);
    }

    /// <summary>Externally set stage phase (e.g. from PLC Load/Unload flow).</summary>
    public void NotifyStagePhase(int ch, int phase) => UpdateStagePhase(ch, phase);

    // ── Cache helpers ────────────────────────────────────────────
    private void UpdateStagePhase(int ch, int phase)
    {
        if (ch < 0 || ch >= 4) return;
        if (_lastChannelStagePhase[ch] == phase) return;
        _lastChannelStagePhase[ch] = phase;
        StagePhaseChanged?.Invoke(ch, phase);
    }

    private void CacheChannelLog(int ch, string msg)
    {
        if (ch < 0 || ch >= 4) return;
        lock (_channelLocks[ch])
        {
            var log = _lastChannelLogs[ch];
            log.Add($"[{DateTime.Now:HH:mm:ss}] {msg}");
            while (log.Count > MaxCachedLogEntries)
                log.RemoveAt(0);
        }
    }

    private void CacheChannelResult(int ch, int ngCode)
    {
        if (ch < 0 || ch >= 4) return;
        if (ngCode == 0)
            Interlocked.Increment(ref _lastChannelOkCount[ch]);
        else
            Interlocked.Increment(ref _lastChannelNgCount[ch]);

        lock (_channelLocks[ch])
        {
            _lastChannelPrevResults[ch].Insert(0, (ngCode, ngCode == 0));
            while (_lastChannelPrevResults[ch].Count > MaxCachedPrevResults)
                _lastChannelPrevResults[ch].RemoveAt(_lastChannelPrevResults[ch].Count - 1);
        }
    }

    /// <summary>
    /// Resets all per-channel cached results to initial state.
    /// Called on model change so stale OK/NG from previous model don't persist.
    /// </summary>
    public void ClearAllChannelResults()
    {
        for (int ch = 0; ch < 4; ch++)
        {
            lock (_channelLocks[ch])
            {
                _lastChannelNgCode[ch] = -1;
                _lastChannelResult[ch] = "---";
                _lastChannelStatus[ch] = 4; // Stop
                _lastChannelStagePhase[ch] = 0; // Idle
                _lastChannelOkCount[ch] = 0;
                _lastChannelNgCount[ch] = 0;
                _lastChannelSerialNo[ch] = "";
                _continuousNgCount[ch] = 0;
                _lastChannelLogs[ch].Clear();
                _lastChannelPrevResults[ch].Clear();
            }
            ChannelResultReady?.Invoke(ch, -1);
            ChannelStatusChanged?.Invoke(ch, 4);
        }
    }

    public void Dispose()
    {
        foreach (var sub in _subscriptions)
            sub.Dispose();
        _subscriptions.Clear();
    }
}
