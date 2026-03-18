// =============================================================================
// JigController.cs
// Converted from Delphi: src_X3584\JigControl.pas (TJig class, 567 lines)
// Manages jig hardware state and step sequences for TOP/BOTTOM channels.
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Inspection
// =============================================================================

using System;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.BusinessLogic.Inspection;

/// <summary>
/// Jig controller implementation managing jig hardware state and step sequences.
/// Two instances: JIG_A (TOP CH1-CH2) and JIG_B (BOTTOM CH3-CH4).
/// <para>Delphi origin: TJig class (JigControl.pas)</para>
/// </summary>
public sealed class JigController : IJigController
{
    // =========================================================================
    // Dependencies (injected)
    // =========================================================================

    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _systemStatus;
    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly IOcDllService _ocDll;
    private readonly IDioController _dioController;
    private readonly IPlcService _plcService;

    /// <summary>
    /// Per-channel PG drivers. Indexed 0..MaxJigCh (4 channels total).
    /// <para>Delphi: Pg[nCh] : TCommPG</para>
    /// </summary>
    private readonly ICommPgDriver[] _pgDrivers;

    /// <summary>
    /// Per-channel inspection logic instances. Indexed 0..MaxJigCh.
    /// <para>Delphi: Logic[nCh] : TLogic</para>
    /// </summary>
    private readonly IInspectionLogic[] _inspectionLogic;

    /// <summary>
    /// Per-channel script runners. Indexed 0..MaxJigCh.
    /// <para>Delphi: PasScr[nCh] : TScrCls</para>
    /// </summary>
    private readonly IScriptRunner[] _scriptRunners;

    // =========================================================================
    // State Fields (from Delphi TJig private section)
    // =========================================================================

    /// <summary>Current jig index (0=JIG_A, 1=JIG_B). Delphi: m_nCurJig</summary>
    private readonly int _jigIndex;

    /// <summary>Start channel index for this jig. Delphi: m_nCurChStart</summary>
    private readonly int _channelStart;

    /// <summary>Number of channels per jig. Delphi: MAX_PG_CNT div MAX_JIG_CNT</summary>
    private readonly int _channelsPerJig;

    /// <summary>Pattern contact index. Delphi: m_nIdxPatContact</summary>
    private int _patContactIndex = -1;

    /// <summary>CA310 working flag. Delphi: m_bIsCa310Working</summary>
    private bool _isCa310Working;

    /// <summary>Per-channel CA310 shot ready flags. Delphi: m_nShotCa310Ready[CH1..MAX_JIG_CH]</summary>
    private readonly bool[] _shotCa310Ready;

    private bool _disposed;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates a new JigController instance for the specified jig index.
    /// <para>Delphi origin: constructor TJig.Create(nJigIdx: Integer; hMain, hTest: HWND; AOwner: TComponent)</para>
    /// </summary>
    /// <param name="jigIndex">Jig index (0=JIG_A, 1=JIG_B).</param>
    /// <param name="config">Configuration service (replaces Common global).</param>
    /// <param name="systemStatus">System status service (replaces Common.StatusInfo).</param>
    /// <param name="messageBus">Message bus (replaces SendMessage/WM_COPYDATA).</param>
    /// <param name="logger">Logger instance.</param>
    /// <param name="ocDll">OC DLL service (replaces CSharpDll global).</param>
    /// <param name="dioController">DIO controller (replaces ControlDio global).</param>
    /// <param name="plcService">PLC service (replaces g_CommPLC global).</param>
    /// <param name="pgDrivers">Array of PG drivers indexed by channel (0..MaxJigCh).</param>
    /// <param name="inspectionLogic">Array of per-channel inspection logic (0..MaxJigCh).</param>
    /// <param name="scriptRunners">Array of per-channel script runners (0..MaxJigCh).</param>
    public JigController(
        int jigIndex,
        IConfigurationService config,
        ISystemStatusService systemStatus,
        IMessageBus messageBus,
        ILogger logger,
        IOcDllService ocDll,
        IDioController dioController,
        IPlcService plcService,
        ICommPgDriver[] pgDrivers,
        IInspectionLogic[] inspectionLogic,
        IScriptRunner[] scriptRunners)
    {
        _jigIndex = jigIndex;
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _systemStatus = systemStatus ?? throw new ArgumentNullException(nameof(systemStatus));
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _ocDll = ocDll ?? throw new ArgumentNullException(nameof(ocDll));
        _dioController = dioController ?? throw new ArgumentNullException(nameof(dioController));
        _plcService = plcService ?? throw new ArgumentNullException(nameof(plcService));
        _pgDrivers = pgDrivers ?? throw new ArgumentNullException(nameof(pgDrivers));
        _inspectionLogic = inspectionLogic ?? throw new ArgumentNullException(nameof(inspectionLogic));
        _scriptRunners = scriptRunners ?? throw new ArgumentNullException(nameof(scriptRunners));

        // Delphi: nChCnt := MAX_PG_CNT div MAX_JIG_CNT;
        _channelsPerJig = ChannelConstants.MaxPgCount / Math.Max(ChannelConstants.MaxJigCount, 1);
        _channelStart = _jigIndex * _channelsPerJig;

        // Initialize per-channel CA310 ready flags
        // Delphi: for nCh := CH1 to MAX_JIG_CH do m_nShotCa310Ready[nCh] := False;
        _shotCa310Ready = new bool[ChannelConstants.MaxJigCh + 1];

        IsKeyLocked = false;
        Status = JigStatus.Ready;
    }

    // =========================================================================
    // IJigController Properties
    // =========================================================================

    /// <inheritdoc />
    public int JigIndex => _jigIndex;

    /// <inheritdoc />
    public JigStatus Status { get; set; }

    /// <inheritdoc />
    public bool IsKeyLocked { get; set; }

    // =========================================================================
    // IJigController - Inspection Start/Stop TOP (CH1, CH2)
    // =========================================================================

    /// <inheritdoc />
    public bool StartInspectionTop(int sequenceKey = 1)
    {
        // Delphi: {$IFNDEF SIMENV_NO_PG}
        //   if not CheckPgConnect(0) then Exit(False);
        // {$ENDIF}
        if (!_config.AppConfig.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            if (!CheckPgConnect(0))
                return false;
        }

        // Delphi: if CheckScript(0, nSeq) then Exit(False);
        if (CheckScript(0, sequenceKey))
            return false;

        // Delphi: if (CSharpDll.MainOC_GetOCFlowIsAlive(0)=1) or (CSharpDll.MainOC_GetOCFlowIsAlive(1)=1) then Exit(False);
        if (_ocDll.GetFlowIsAlive(ChannelConstants.Ch1) == 1 ||
            _ocDll.GetFlowIsAlive(ChannelConstants.Ch2) == 1)
        {
            return false;
        }

        // PreOC-specific checks
        // Delphi: if Common.SystemInfo.OCType = DefCommon.PreOCType then begin
        if (_config.SystemInfo.OCType == ChannelConstants.PreOcType)
        {
            if (sequenceKey == DefScript.SeqKey9)
            {
                // Check if first process is done for all top channels
                bool firstProcessDone = true;
                for (int ch = ChannelConstants.Ch1; ch <= ChannelConstants.Ch2; ch++)
                {
                    if (!_scriptRunners[ch].FirstProcessDone)
                    {
                        firstProcessDone = false;
                        break;
                    }
                }

                if (firstProcessDone)
                {
                    // Delphi: if not ControlDio.CheckDIO_Start(0) then begin
                    if (!_dioController.CheckDioStart(0))
                    {
                        string logMsg = "You must close Pinblock to Start CH 1,2";
                        PublishMainGuiDisplay(MsgType.CtlDio, 0, 2, 0, logMsg);
                        return false;
                    }
                }
                else
                {
                    // Delphi: if ControlDio.CheckPreOcPanelDetectJig(0) <> 0 then begin
                    if (_dioController.CheckPreOcPanelDetectJig(0) != 0)
                    {
                        string logMsg = "1,2 Ch not have to Panel. Check Detect Sensor";
                        PublishMainGuiDisplay(MsgType.CtlDio, 0, 2, 0, logMsg);
                        return false;
                    }
                }

                // Delphi: if frmNgMsg <> nil then frmNgMsg.FormAutoClose;
                // Note: NG message form auto-close is handled via message bus
                _messageBus.Publish(new JigEventMessage
                {
                    Channel = _jigIndex,
                    Mode = MsgMode.DioSenNg, // Signal to close NG message form
                    Param = 0,
                });

                // Delphi: g_CommPLC.EQP_Clear_ROBOT_Request(0);
                _plcService.ClearRobotRequest(0);
            }
        }

        // Run sequence on each channel
        // Delphi: for i := CH1 to CH2 do begin
        string warningLog = string.Empty;
        for (int ch = ChannelConstants.Ch1; ch <= ChannelConstants.Ch2; ch++)
        {
            // PreOC auto-mode already-inspected panel check
            // Delphi: if Common.SystemInfo.OCType = PreOCType then begin
            //           if Common.StatusInfo.AutoMode then begin
            //             if PasScr[i].m_nConfirmHostRet = 1 then begin
            if (_config.SystemInfo.OCType == ChannelConstants.PreOcType)
            {
                if (_systemStatus.AutoMode)
                {
                    if (_scriptRunners[ch].ConfirmHostReturn == 1)
                    {
                        // Delphi: sLog := sLog + Format(' CH : %d This is a panel that was inspected',[i+1]) + #13#10;
                        warningLog += $" CH : {ch + 1} This is a panel that was inspected\r\n";
                        continue;
                    }
                }
            }

            // Delphi: PasScr[i].TestInfo.NgCode := 0;
            _scriptRunners[ch].TestInfo.NgCode = 0;

            // Delphi: PasScr[i].RunSeq(nSeq);
            _scriptRunners[ch].RunSequence(sequenceKey);

            // Delphi: PasScr[i].m_bIsProbeBackSig := False;
            _scriptRunners[ch].IsProbeBackSignal = false;
        }

        // Delphi: if Length(sLog) <> 0 then SendMainGuiDisplay(MSG_TYPE_CTL_DIO, 0, 2, 0, sLog);
        if (warningLog.Length > 0)
        {
            PublishMainGuiDisplay(MsgType.CtlDio, 0, 2, 0, warningLog);
        }

        return true;
    }

    /// <inheritdoc />
    public void StopInspectionTop()
    {
        // Delphi: for i := CH1 to CH2 do begin
        for (int ch = ChannelConstants.Ch1; ch <= ChannelConstants.Ch2; ch++)
        {
            StopChannelScript(ch);
        }
    }

    // =========================================================================
    // IJigController - Inspection Start/Stop BOTTOM (CH3, CH4)
    // =========================================================================

    /// <inheritdoc />
    public bool StartInspectionBottom(int sequenceKey = 1)
    {
        // Delphi: {$IFNDEF SIMENV_NO_PG}
        //   if not CheckPgConnect(1) then Exit(False);
        // {$ENDIF}
        if (!_config.AppConfig.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            if (!CheckPgConnect(1))
                return false;
        }

        // Delphi: if CheckScript(1, nSeq) then Exit(False);
        if (CheckScript(1, sequenceKey))
            return false;

        // Delphi: if (CSharpDll.MainOC_GetOCFlowIsAlive(2)=1) or (CSharpDll.MainOC_GetOCFlowIsAlive(3)=1) then Exit(False);
        if (_ocDll.GetFlowIsAlive(ChannelConstants.Ch3) == 1 ||
            _ocDll.GetFlowIsAlive(ChannelConstants.Ch4) == 1)
        {
            return false;
        }

        // PreOC-specific checks
        // Delphi: if Common.SystemInfo.OCType = DefCommon.PreOCType then begin
        if (_config.SystemInfo.OCType == ChannelConstants.PreOcType)
        {
            if (sequenceKey == DefScript.SeqKey9)
            {
                // Check if first process is done for all bottom channels
                bool firstProcessDone = true;
                for (int ch = ChannelConstants.Ch3; ch <= ChannelConstants.Ch4; ch++)
                {
                    if (!_scriptRunners[ch].FirstProcessDone)
                    {
                        firstProcessDone = false;
                        break;
                    }
                }

                if (firstProcessDone)
                {
                    // Delphi: if not ControlDio.CheckDIO_Start(1) then begin
                    if (!_dioController.CheckDioStart(1))
                    {
                        string logMsg = "You must close Pinblock to Start CH 3,4";
                        PublishMainGuiDisplay(MsgType.CtlDio, 0, 2, 0, logMsg);
                        return false;
                    }
                }
                else
                {
                    // Delphi: if ControlDio.CheckPreOcPanelDetectJig(1) <> 0 then begin
                    if (_dioController.CheckPreOcPanelDetectJig(1) != 0)
                    {
                        string logMsg = "3,4 Ch not have to Panel. Check Detect Sensor";
                        PublishMainGuiDisplay(MsgType.CtlDio, 0, 2, 0, logMsg);
                        return false;
                    }
                }

                // Delphi: if frmNgMsg <> nil then frmNgMsg.FormAutoClose;
                _messageBus.Publish(new JigEventMessage
                {
                    Channel = _jigIndex,
                    Mode = MsgMode.DioSenNg,
                    Param = 0,
                });

                // Delphi: g_CommPLC.EQP_Clear_ROBOT_Request(1);
                _plcService.ClearRobotRequest(1);
            }
        }

        // Run sequence on each channel
        // Delphi: for i := CH3 to CH4 do begin
        string warningLog = string.Empty;
        for (int ch = ChannelConstants.Ch3; ch <= ChannelConstants.Ch4; ch++)
        {
            // PreOC auto-mode already-inspected panel check
            if (_config.SystemInfo.OCType == ChannelConstants.PreOcType)
            {
                if (_systemStatus.AutoMode)
                {
                    if (_scriptRunners[ch].ConfirmHostReturn == 1)
                    {
                        warningLog += $" CH : {ch + 1} This is a panel that was inspected\r\n";
                        continue;
                    }
                }
            }

            // Delphi: PasScr[i].TestInfo.NgCode := 0;
            _scriptRunners[ch].TestInfo.NgCode = 0;

            // Delphi: PasScr[i].RunSeq(nSeq);
            _scriptRunners[ch].RunSequence(sequenceKey);

            // Delphi: PasScr[i].m_bIsProbeBackSig := False;
            _scriptRunners[ch].IsProbeBackSignal = false;
        }

        // Delphi: if Length(sLog) <> 0 then SendMainGuiDisplay(MSG_TYPE_CTL_DIO, 0, 2, 0, sLog);
        if (warningLog.Length > 0)
        {
            PublishMainGuiDisplay(MsgType.CtlDio, 0, 2, 0, warningLog);
        }

        return true;
    }

    /// <inheritdoc />
    public void StopInspectionBottom()
    {
        // Delphi: for i := CH3 to CH4 do begin
        for (int ch = ChannelConstants.Ch3; ch <= ChannelConstants.Ch4; ch++)
        {
            StopChannelScript(ch);
        }
    }

    // =========================================================================
    // IJigController - Per-channel Stop
    // =========================================================================

    /// <inheritdoc />
    public void StopInspectionChannel(int channel)
    {
        // Delphi: procedure TJig.StopIspdCh(nCh: Integer);
        StopChannelScript(channel);
    }

    // =========================================================================
    // IJigController - Status Queries
    // =========================================================================

    /// <inheritdoc />
    public bool IsScriptRunning()
    {
        // Delphi: for nCh := m_nCurChStart to Pred(m_nCurChStart + nChCnt) do begin
        //           if PasScr[nCh].IsScriptRun then begin bRet := True; Break; end;
        for (int ch = _channelStart; ch < _channelStart + _channelsPerJig; ch++)
        {
            if (ch < _scriptRunners.Length && _scriptRunners[ch].IsScriptRunning())
                return true;
        }
        return false;
    }

    // =========================================================================
    // IJigController - Handle Management
    // =========================================================================

    /// <inheritdoc />
    public void RefreshHandles()
    {
        // Delphi: procedure TJig.SetHandleAgain(hMain, hTest: HWND);
        //   m_nCurChStart := m_nCurJig * nChCnt;
        //   for nCh := m_nCurChStart to Pred(m_nCurChStart + nChCnt) do
        //     PasScr[nCh].SetHandleAgain(hMain, hTest);
        //
        // In C# the handles are replaced by the message bus, so we forward
        // the refresh to each script runner in case it needs to re-subscribe.
        for (int ch = _channelStart; ch < _channelStart + _channelsPerJig; ch++)
        {
            if (ch < _scriptRunners.Length)
                _scriptRunners[ch].RefreshHandles();
        }
    }

    // =========================================================================
    // Private Helpers
    // =========================================================================

    /// <summary>
    /// Checks whether at least one PG in the given group is connected and ready.
    /// <para>Delphi origin: function TJig.CheckPgConnect(nGroup: Integer): Boolean</para>
    /// </summary>
    /// <param name="group">Channel group (0=TOP, 1=BOTTOM).</param>
    /// <returns>True if at least one PG in the group is ready.</returns>
    private bool CheckPgConnect(int group)
    {
        // Delphi: for nCh := nGroup * 2 to nGroup * 2 + 1 do begin
        //           if not PasScr[nCh].m_bUse then Continue;
        //           if Pg[nCh].StatusPg in [pgReady] then begin bRet := True; Break; end;
        int startCh = group * 2;
        int endCh = startCh + 1;

        for (int ch = startCh; ch <= endCh; ch++)
        {
            if (ch >= _scriptRunners.Length)
                continue;
            if (!_scriptRunners[ch].IsInUse)
                continue;
            if (ch < _pgDrivers.Length && _pgDrivers[ch].Status == PgStatus.Ready)
                return true;
        }
        return false;
    }

    /// <summary>
    /// Checks whether any script in the given group is currently running the specified sequence.
    /// <para>Delphi origin: function TJig.CheckScript(nGroup, nKeyIdx: Integer): Boolean</para>
    /// </summary>
    /// <param name="group">Channel group (0=TOP, 1=BOTTOM).</param>
    /// <param name="keyIndex">Sequence key index to check.</param>
    /// <returns>True if any channel in the group has the specified sequence running.</returns>
    private bool CheckScript(int group, int keyIndex)
    {
        // Delphi: for nCh := CH1 + nGroup * 2 to CH2 + nGroup * 2 do begin
        //           if PasScr[nCh].ScriptRunning(nKeyIdx) then begin bRet := True; Break; end;
        int startCh = ChannelConstants.Ch1 + group * 2;
        int endCh = ChannelConstants.Ch2 + group * 2;

        for (int ch = startCh; ch <= endCh; ch++)
        {
            if (ch < _scriptRunners.Length && _scriptRunners[ch].IsSequenceRunning(keyIndex))
                return true;
        }
        return false;
    }

    /// <summary>
    /// Stops the script on a specific channel by setting stop flags and running the stop sequence.
    /// Shared by StopIspd_TOP, StopIspd_BOTTOM, and StopIspdCh.
    /// <para>Delphi origin: inline code in TJig.StopIspd_TOP/StopIspd_BOTTOM/StopIspdCh</para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    private void StopChannelScript(int channel)
    {
        if (channel < 0 || channel >= _scriptRunners.Length)
            return;

        var script = _scriptRunners[channel];

        // Delphi: PasScr[i].m_bIsSyncSeq := False;
        script.IsSyncSequence = false;

        // Delphi: PasScr[i].m_bCEL_Stop := True;
        script.CelStop = true;

        // Delphi: PasScr[i].SetHostEvent(0);
        script.SetHostEvent(0);

        // Delphi: PasScr[i].RunSeq(DefScript.SEQ_KEY_STOP);
        script.RunSequence(DefScript.SeqKeyStop);

        // Delphi: PasScr[i].m_nConfirmHostRet := 0;
        script.ConfirmHostReturn = 0;

        // Delphi: sLog := Format('ReStart Mode(%d) : Initialization ',[PasScr[i].m_nConfirmHostRet]);
        //         SendTestGuiDisplay(MSG_MODE_WORKING, i, sLog);
        string logMsg = $"ReStart Mode({script.ConfirmHostReturn}) : Initialization ";
        PublishTestGuiDisplay(MsgMode.Working, channel, logMsg);
    }

    /// <summary>
    /// Publishes a jig event message to the main form via the message bus.
    /// <para>Delphi origin: procedure TJig.SendMainGuiDisplay(nMsgMode, nCh, nParam, nParam2: Integer; sMsg: String; pData: Pointer)</para>
    /// </summary>
    private void PublishMainGuiDisplay(int msgType, int channel, int param, int param2, string message, byte[]? data = null)
    {
        // Delphi: SendData.MsgType := MSG_TYPE_JIG; SendData.Channel := m_nCurJig;
        // In C# the message type is implicit via the class type (JigEventMessage).
        // We store msgType in Param field since the Delphi code used a different MsgType field
        // for routing; here, the MsgType routing is handled by the generic type parameter.
        _messageBus.Publish(new JigEventMessage
        {
            Channel = _jigIndex,
            Mode = msgType,  // Delphi used MsgType here; map to Mode for message bus routing
            Param = param,
            Param2 = param2,
            Message = message,
            Data = data,
        });
    }

    /// <summary>
    /// Publishes a test GUI display message via the message bus.
    /// <para>Delphi origin: procedure TJig.SendTestGuiDisplay(nGuiMode, nCh: Integer; sMsg, sMsg2: string; nParam, nParam2: Integer)</para>
    /// </summary>
    private void PublishTestGuiDisplay(int guiMode, int channel, string message = "", string message2 = "", int param = 0, int param2 = 0)
    {
        // Delphi: GuiData.MsgType := MSG_TYPE_JIG; GuiData.Channel := nCh;
        _messageBus.Publish(new GuiLogMessage
        {
            Channel = channel,
            Mode = guiMode,
            Param = param,
            Param2 = param2,
            Message = message,
        });
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed)
            return;

        _disposed = true;
    }
}
