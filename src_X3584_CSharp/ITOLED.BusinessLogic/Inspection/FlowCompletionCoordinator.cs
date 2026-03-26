// =============================================================================
// FlowCompletionCoordinator.cs
// Subscribes to DLL WorkDone events, checks JIG pair completion,
// and triggers Process_Finish on the script runners.
// Delphi origin: Test4ChOC.pas:4831-4848 (MSG_MODE_WORK_DONE → JIG pair → STAGE_MODE_UNLOAD)
// =============================================================================

using Dongaeltek.ITOLED.BusinessLogic.Dll;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.BusinessLogic.Inspection;

/// <summary>
/// Coordinates DLL flow completion with CSX script execution.
/// When a channel's OC DLL flow completes (WorkDone), checks JIG pair completion
/// (A: CH0+CH1, B: CH2+CH3) and triggers Process_Finish on the script runners.
/// </summary>
public sealed class FlowCompletionCoordinator : IDisposable
{
    private readonly IDllManager _dll;
    private readonly IScriptRunner[] _scripts;
    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _status;
    private readonly ILogger _logger;
    private readonly IDisposable _subscription;

    public FlowCompletionCoordinator(
        IMessageBus bus,
        IDllManager dll,
        IScriptRunner[] scripts,
        IConfigurationService config,
        ISystemStatusService status,
        ILogger logger)
    {
        _dll = dll ?? throw new ArgumentNullException(nameof(dll));
        _scripts = scripts ?? throw new ArgumentNullException(nameof(scripts));
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _status = status ?? throw new ArgumentNullException(nameof(status));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        _subscription = bus.Subscribe<DllEventMessage>(OnDllEvent);
    }

    private void OnDllEvent(DllEventMessage msg)
    {
        if (msg.Mode != MsgMode.WorkDone)
            return;

        int ch = msg.Channel;
        if (ch < 0 || ch >= _scripts.Length)
            return;

        _logger.Info($"CH{ch} DLL WorkDone received, checking pair completion");

        if (_config.PlcInfo.InlineGIB)
        {
            // InlineGIB: trigger Process_Finish immediately per channel
            // Delphi: SendMessageMain(STAGE_MODE_UNLOAD, nCH, 2, 0, 'OC Flow Process_Finish')
            if (_scripts[ch].IsInUse)
            {
                _logger.Info($"CH{ch} InlineGIB → Process_Finish");
                _scripts[ch].RunSequence(DefScript.SeqFinish);

                // Auto Repeat: Process_Finish 완료 후 자동 재시작
                TryAutoRepeatRestart(ch);
            }
            _dll.SetProcessDone(ch, false);
        }
        else
        {
            // Non-InlineGIB: wait for pair completion
            int pairStart = (ch / 2) * 2;
            int pairEnd = pairStart + 1;

            if (pairEnd >= _scripts.Length)
                return;

            // Delphi: mark unused channels as done (prevent infinite wait)
            for (int i = pairStart; i <= pairEnd; i++)
            {
                if (!_scripts[i].IsInUse)
                    _dll.SetProcessDone(i, true);
            }

            // Check if both channels in pair are done
            if (_dll.IsProcessDone(pairStart) && _dll.IsProcessDone(pairEnd))
            {
                _logger.Info($"Pair CH{pairStart}+CH{pairEnd} complete → Process_Finish");

                for (int i = pairStart; i <= pairEnd; i++)
                {
                    if (_scripts[i].IsInUse)
                        _scripts[i].RunSequence(DefScript.SeqFinish);
                }

                // Reset flags
                _dll.SetProcessDone(pairStart, false);
                _dll.SetProcessDone(pairEnd, false);

                // Auto Repeat: Process_Finish 완료 후 자동 재시작 (pair 단위)
                TryAutoRepeatRestart(pairStart, pairEnd);
            }
            else
            {
                _logger.Debug($"CH{ch} done, waiting for pair partner (pair={pairStart},{pairEnd})");
            }
        }
    }

    /// <summary>
    /// Auto Repeat 모드일 때 Process_Finish 스크립트 완료 대기 후 Seq_Key_Start 자동 재실행.
    /// 별도 스레드에서 실행하여 OnDllEvent 콜백을 블로킹하지 않음.
    /// </summary>
    private bool ShouldAutoRepeat => _status.AutoRepeatTest && !_status.AutoMode && !_status.IsClosing;

    private void TryAutoRepeatRestart(int chStart, int chEnd = -1)
    {
        if (chEnd < 0) chEnd = chStart;

        if (!ShouldAutoRepeat)
            return;

        // 별도 스레드에서 SeqFinish 완료 대기 후 재시작
        var thread = new Thread(() =>
        {
            try
            {
                // Process_Finish 스크립트 스레드 완료 대기 (최대 60초)
                int waitMs = 0;
                while (waitMs < 60000 && ShouldAutoRepeat)
                {
                    bool allDone = true;
                    for (int i = chStart; i <= chEnd; i++)
                    {
                        if (_scripts[i].IsInUse && _scripts[i].IsScriptRunning())
                        {
                            allDone = false;
                            break;
                        }
                    }
                    if (allDone) break;
                    Thread.Sleep(200);
                    waitMs += 200;
                }

                // 최종 확인: Stop/종료로 취소되지 않았는지
                if (!ShouldAutoRepeat)
                {
                    _logger.Info($"<AUTO REPEAT> cancelled (AutoRepeat={_status.AutoRepeatTest}, AutoMode={_status.AutoMode})");
                    return;
                }

                // SeqFinish 완료 후 재시작 전 지연 — Stop 버튼 반영 시간 확보
                Thread.Sleep(1000);

                // 재시작 직전 최종 확인
                if (!ShouldAutoRepeat)
                {
                    _logger.Info($"<AUTO REPEAT> cancelled before restart (AutoRepeat={_status.AutoRepeatTest})");
                    return;
                }

                _logger.Info($"<AUTO REPEAT> auto restart CH{chStart + 1}~CH{chEnd + 1}");

                for (int i = chStart; i <= chEnd; i++)
                {
                    if (!ShouldAutoRepeat) break; // 채널 간에도 체크
                    if (_scripts[i].IsInUse)
                    {
                        _scripts[i].ExecuteAutoStart();
                        _scripts[i].RunSequence(DefScript.SeqKeyStart);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.Error($"<AUTO REPEAT> restart error: {ex.Message}", ex);
            }
        })
        {
            IsBackground = true,
            Name = $"AutoRepeat_CH{chStart}-{chEnd}"
        };
        thread.Start();
    }

    public void Dispose() => _subscription.Dispose();
}
