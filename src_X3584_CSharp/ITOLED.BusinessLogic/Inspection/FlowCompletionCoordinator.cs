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
    private readonly ILogger _logger;
    private readonly IDisposable _subscription;

    public FlowCompletionCoordinator(
        IMessageBus bus,
        IDllManager dll,
        IScriptRunner[] scripts,
        IConfigurationService config,
        ILogger logger)
    {
        _dll = dll ?? throw new ArgumentNullException(nameof(dll));
        _scripts = scripts ?? throw new ArgumentNullException(nameof(scripts));
        _config = config ?? throw new ArgumentNullException(nameof(config));
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
            }
            else
            {
                _logger.Debug($"CH{ch} done, waiting for pair partner (pair={pairStart},{pairEnd})");
            }
        }
    }

    public void Dispose() => _subscription.Dispose();
}
