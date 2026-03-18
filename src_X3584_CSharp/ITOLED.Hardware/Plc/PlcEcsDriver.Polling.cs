// =============================================================================
// PlcEcsDriver.Polling.cs  (partial)
// Background polling loop, Read_PollingData, Process_RobotData, Process_CVData,
// Process_ECSData, Process_AlarmQue, Process_MESQue, and all Process_ROBOT_* handlers.
// Converted from Delphi: CommPLC_ECS.pas lines 2948-4411
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Hardware.Plc;

public sealed partial class PlcEcsDriver
{
    // =========================================================================
    // ExecuteLoop (Delphi: TCommPLCThread.Execute, line 2948)
    // =========================================================================

    private void ExecuteLoop(CancellationToken ct)
    {
        AddLog("ExecuteLoop: started");
        long preTick = Environment.TickCount64;
        _linkTestTick = preTick;

        while (_stopped == 0 && !ct.IsCancellationRequested)
        {
            try
            {
                long tick = Environment.TickCount64;

                // --- Connection management ---
                if (!_opened)
                {
                    if (UseSimulator)
                    {
                        _opened = true; // Auto-open in simulator mode
                    }
                    else
                    {
                        Thread.Sleep((int)PollingInterval);

                        if (!IgnoreConnect)
                            OpenPlc();

                        if (!_opened)
                        {
                            if (!ConnectionError && tick > preTick + ConnectionTimeout)
                            {
                                ConnectionError = true;
                                AddLog("Can not Connect **********");
                                SendMessageMain(CommPlcConst.ModeConnect, 0, 1, 0, "PLC Connect Fail");
                            }
                            continue;
                        }
                    }
                }

                // --- Read polling data ---
                ReadPollingData();

                // --- Log save ---
                if ((DateTime.Now - _logSaveTime).TotalSeconds > _logAccumulateSecond)
                    AddLog(string.Empty, true);

                // --- Wait for next cycle ---
                Thread.Sleep((int)PollingInterval);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.Error("ExecuteLoop exception", ex);
                Thread.Sleep(1000);
            }
        }

        AddLog("ExecuteLoop: exited");
    }

    // =========================================================================
    // Read_PollingData (Delphi: line 3110)
    // =========================================================================

    private void ReadPollingData()
    {
        int nRet;

        // --- CV / Door data (OC type only) ---
        if (IsOcType)
        {
            nRet = ReadDeviceBlock($"B{StartAddrRobotDoorBit:X3}",
                CommPlcConst.CvDataSize, PollingCv, out _, false);
            if (nRet != 0)
                AddLog("Polling Door Open ReadDevice Fail");

            if (_stopped != 0) return;

            bool cvChanged = false;
            for (int i = 0; i < CommPlcConst.CvDataSize; i++)
            {
                if (PollingCv[i] != PollingCvPre[i])
                {
                    cvChanged = true;
                    break;
                }
            }
            if (cvChanged)
            {
                ProcessCvData();
                Array.Copy(PollingCv, PollingCvPre, CommPlcConst.CvDataSize);
            }
        }

        // --- AAB mode (InlineGIB + OC) ---
        if (InlineGib && IsOcType)
        {
            nRet = ReadDevice("B030", out int aabVal, false);
            if (PollingAabMode != aabVal)
            {
                PollingAabMode = aabVal;
                SendMessageMain(CommPlcConst.ModeEventEcs, 0,
                    CommPlcConst.ParamAabMode, aabVal, "PLC AA MODE");
            }
        }

        if (_stopped != 0) return;

        // --- Robot data ---
        _resultRobot = 0;
        if (StartAddrRobot2 != 0)
        {
            _resultRobot = ReadDeviceBlock($"B{StartAddrRobot + 0x10 * 0x00 + 0x0:X3}",
                2, PollingData, out _resultRobot, false);
            var tmpData = new int[2];
            _resultRobot = ReadDeviceBlock($"B{StartAddrRobot2 + 0x10 * 0x00 + 0x0:X3}",
                2, tmpData, out _resultRobot, false);
            PollingData[2] = tmpData[0];
            PollingData[3] = tmpData[1];
        }
        else
        {
            _resultRobot = ReadDeviceBlock($"B{StartAddrRobot + 0x10 * 0x00 + 0x0:X3}",
                _robotDataSize, PollingData, out _resultRobot, false);
        }

        if (_resultRobot != 0)
            AddLog($"Polling Robot ReadDeviceBlock Fail: B{StartAddrRobot:X3} ERR CODE: {_resultRobot}");

        if (_stopped != 0) return;

        bool robotChanged = false;
        for (int i = 0; i < _robotDataSize; i++)
        {
            if (PollingData[i] != PollingDataPre[i])
            {
                robotChanged = true;
                AddLog($"<< Changed Robot Data {i}");
                break;
            }
        }
        if (robotChanged)
        {
            ProcessRobotData();
            Array.Copy(PollingData, PollingDataPre, _robotDataSize);
        }

        // --- ECS data (4 reads) ---
        _resultEcs = 0;

        // Read common data at B000
        var ecsCommon = new int[1];
        _resultEcs = ReadDeviceBlock("B000", 1, ecsCommon, out _resultEcs, false);
        PollingEcs[CommPlcConst.EcsDataSize] = ecsCommon[0];

        // Read ECS block 0: Link Test Request
        var ecsTmp = new int[1];
        _resultEcs = ReadDeviceBlock($"B{StartAddrEcs + 0x10 * 0x00 + 0x0:X3}",
            1, ecsTmp, out _resultEcs, false);
        PollingEcs[0] = ecsTmp[0];

        // Read ECS block 1: Lost Panel Data Report
        _resultEcs = ReadDeviceBlock($"B{StartAddrEcs + 0x100 + 0x10 * 0x00 + 0x0:X3}",
            1, ecsTmp, out _resultEcs, false);
        PollingEcs[1] = ecsTmp[0];

        // Read ECS block 2: Take Out Report_Confirm
        _resultEcs = ReadDeviceBlock($"B{StartAddrEcs + 0x200 + 0x10 * 0x00 + 0x0:X3}",
            1, ecsTmp, out _resultEcs, false);
        PollingEcs[2] = ecsTmp[0];

        if (_stopped != 0) return;

        bool ecsChanged = false;
        for (int i = 0; i <= CommPlcConst.EcsDataSize; i++)
        {
            if (PollingEcs[i] != PollingEcsPre[i])
            {
                ecsChanged = true;
                AddLog($"<< Changed ECS Data {i}");
                break;
            }
        }
        if (ecsChanged)
        {
            ProcessEcsData();
            Array.Copy(PollingEcs, PollingEcsPre, CommPlcConst.EcsDataSize + 1);
        }

        // --- EQP data ---
        _resultEqp = 0;
        _resultEqp = ReadDeviceBlock($"B{StartAddrEqp + 0x10 * 0x00 + 0x0:X3}",
            _eqpDataSize, PollingEqp, out _resultEqp, false);

        if (_resultEqp != 0)
            AddLog($"Polling EQP ReadDeviceBlock Fail: B{StartAddrEqp + 0x10 * 0x00 + 0x0:X3} ERR CODE: {_resultEqp}");
    }

    // =========================================================================
    // Process_RobotData (Delphi: line 3323)
    // =========================================================================

    private void ProcessRobotData()
    {
        try
        {
            for (int i = 0; i < _robotDataSize; i++)
            {
                if (PollingData[i] == PollingDataPre[i]) continue;

                for (int k = 0; k <= 15; k++)
                {
                    int nValue = GetBit(PollingData[i], k);
                    if (nValue == GetBit(PollingDataPre[i], k)) continue;

                    int nIndex = i * 16 + k;
                    AddLog($"<< ChangedDevice ROBOT B{StartAddrRobot + nIndex:X3}: {nValue}", true);

                    // Door open info for PreOC
                    switch (nIndex)
                    {
                        case 0x0F:
                        case 0x1F:
                        case 0x2F:
                        case 0x3F:
                            if (IsPreOcType)
                            {
                                ProcessDoorOpenInfo(nValue != 0 ? 0 : 1);
                            }
                            break;
                    }

                    if (!_status.AutoMode) return;

                    // PreOC + non-GIB: RobotLoadingStatus
                    if (IsPreOcType && !InlineGib)
                    {
                        switch (nIndex)
                        {
                            case 0x0A: RobotLoadingStatus[0] = nValue != 0; break;
                            case 0x0B: RobotLoadingStatus[1] = nValue != 0; break;
                            case 0x2A: RobotLoadingStatus[2] = nValue != 0; break;
                            case 0x2B: RobotLoadingStatus[3] = nValue != 0; break;
                        }
                    }

                    // Dispatch bit changes
                    if (IsPreOcType && !InlineGib)
                    {
                        // PreOC non-GIB path
                        ProcessRobotBitPreOcNonGib(nIndex, nValue);
                    }
                    else
                    {
                        // General path (OC, or PreOC+GIB)
                        ProcessRobotBitGeneral(nIndex, nValue);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            AddLog($"Exception On Process_RobotData - {ex.Message}", true);
        }
    }

    /// <summary>PreOC non-GIB robot bit dispatch (Delphi: first case block)</summary>
    private void ProcessRobotBitPreOcNonGib(int nIndex, int nValue)
    {
        switch (nIndex)
        {
            case 0x01: if (nValue != 0) ProcessRobotGlassDataReport(0); break;
            case 0x21: if (nValue != 0) ProcessRobotGlassDataReport(1); break;
            case 0x41: if (nValue != 0) ProcessRobotGlassDataReport(2); break;
            case 0x61: if (nValue != 0) ProcessRobotGlassDataReport(3); break;

            case 0x03: if (nValue != 0) ProcessRobotLoadComplete(0); else ProcessRobotLoadCompleteOff(0); break;
            case 0x23: if (nValue != 0) ProcessRobotLoadComplete(1); else ProcessRobotLoadCompleteOff(1); break;
            case 0x43: if (nValue != 0) ProcessRobotLoadComplete(2); else ProcessRobotLoadCompleteOff(2); break;
            case 0x63: if (nValue != 0) ProcessRobotLoadComplete(3); else ProcessRobotLoadCompleteOff(3); break;

            case 0x13: if (nValue != 0) ProcessRobotUnloadComplete(0); else ProcessRobotUnloadCompleteOff(0); break;
            case 0x33: if (nValue != 0) ProcessRobotUnloadComplete(1); else ProcessRobotUnloadCompleteOff(1); break;
            case 0x53: if (nValue != 0) ProcessRobotUnloadComplete(2); else ProcessRobotUnloadCompleteOff(2); break;
            case 0x73: if (nValue != 0) ProcessRobotUnloadComplete(3); else ProcessRobotUnloadCompleteOff(3); break;

            case 0x12: if (nValue == 0) ProcessRobotUnloadBusyOff(0); else ProcessRobotUnloadBusyOn(0); break;
            case 0x32: if (nValue == 0) ProcessRobotUnloadBusyOff(1); else ProcessRobotUnloadBusyOn(1); break;
            case 0x52: if (nValue == 0) ProcessRobotUnloadBusyOff(2); else ProcessRobotUnloadBusyOn(2); break;
            case 0x72: if (nValue == 0) ProcessRobotUnloadBusyOff(3); else ProcessRobotUnloadBusyOn(3); break;

            case 0x02: if (nValue == 0) ProcessRobotLoadBusyOff(0); else ProcessRobotLoadBusyOn(0); break;
            case 0x22: if (nValue == 0) ProcessRobotLoadBusyOff(1); else ProcessRobotLoadBusyOn(1); break;
            case 0x42: if (nValue == 0) ProcessRobotLoadBusyOff(2); else ProcessRobotLoadBusyOn(2); break;
            case 0x62: if (nValue == 0) ProcessRobotLoadBusyOff(3); else ProcessRobotLoadBusyOn(3); break;

            case 0x04: case 0x24: case 0x44: case 0x64:
                if (nValue == 0)
                {
                    ProcessRobotNormalOff(nIndex / 0x20, nValue);
                    _status.SetLoadUnloadFlowData(nIndex / 0x20, CommPlcConst.ModeLoad12, 0);
                }
                else
                    _status.SetLoadUnloadFlowData(nIndex / 0x20, CommPlcConst.ModeLoad12, 1);
                break;

            case 0x14: case 0x34: case 0x54: case 0x74:
                if (nValue == 0)
                {
                    ProcessRobotNormalOff(nIndex / 0x20, nValue);
                    _status.SetLoadUnloadFlowData(nIndex / 10, CommPlcConst.ModeUnload12, 0);
                }
                else
                    _status.SetLoadUnloadFlowData(nIndex / 10, CommPlcConst.ModeUnload12, 1);
                break;
        }
    }

    /// <summary>General robot bit dispatch (OC, or PreOC+GIB) (Delphi: second case block)</summary>
    private void ProcessRobotBitGeneral(int nIndex, int nValue)
    {
        switch (nIndex)
        {
            case 0x01: if (nValue != 0) ProcessRobotGlassDataReport(0); break;
            case 0x21: if (nValue != 0) ProcessRobotGlassDataReport(1); break;
            case 0x41: if (nValue != 0) ProcessRobotGlassDataReport(2); break;
            case 0x61: if (nValue != 0) ProcessRobotGlassDataReport(3); break;

            case 0x03:
                if (IsPreOcType && InlineGib)
                { if (nValue != 0) ProcessRobotVacuum(0, 1); else ProcessRobotLoadCompleteOff(0); }
                else
                { if (nValue != 0) ProcessRobotLoadComplete(0); else ProcessRobotLoadCompleteOff(0); }
                break;
            case 0x23:
                if (IsPreOcType && InlineGib)
                { if (nValue != 0) ProcessRobotVacuum(1, 1); else ProcessRobotLoadCompleteOff(1); }
                else
                { if (nValue != 0) ProcessRobotLoadComplete(1); else ProcessRobotLoadCompleteOff(1); }
                break;
            case 0x43:
                if (IsPreOcType && InlineGib)
                { if (nValue != 0) ProcessRobotVacuum(2, 1); else ProcessRobotLoadCompleteOff(2); }
                else
                { if (nValue != 0) ProcessRobotLoadComplete(2); else ProcessRobotLoadCompleteOff(2); }
                break;
            case 0x63:
                if (IsPreOcType && InlineGib)
                { if (nValue != 0) ProcessRobotVacuum(3, 1); else ProcessRobotLoadCompleteOff(3); }
                else
                { if (nValue != 0) ProcessRobotLoadComplete(3); else ProcessRobotLoadCompleteOff(3); }
                break;

            case 0x13:
                if (IsPreOcType && InlineGib)
                { if (nValue == 0) ProcessRobotUnloadCompleteOff(0); }
                else
                { if (nValue != 0) ProcessRobotUnloadComplete(0); else ProcessRobotUnloadCompleteOff(0); }
                break;
            case 0x33:
                if (IsPreOcType && InlineGib)
                { if (nValue == 0) ProcessRobotUnloadCompleteOff(1); }
                else
                { if (nValue != 0) ProcessRobotUnloadComplete(1); else ProcessRobotUnloadCompleteOff(1); }
                break;
            case 0x53:
                if (IsPreOcType && InlineGib)
                { if (nValue == 0) ProcessRobotUnloadCompleteOff(2); }
                else
                { if (nValue != 0) ProcessRobotUnloadComplete(2); else ProcessRobotUnloadCompleteOff(2); }
                break;
            case 0x73:
                if (IsPreOcType && InlineGib)
                { if (nValue == 0) ProcessRobotUnloadCompleteOff(3); }
                else
                { if (nValue != 0) ProcessRobotUnloadComplete(3); else ProcessRobotUnloadCompleteOff(3); }
                break;

            case 0x12: if (nValue == 0) ProcessRobotUnloadBusyOff(0); else ProcessRobotUnloadBusyOn(0); break;
            case 0x32: if (nValue == 0) ProcessRobotUnloadBusyOff(1); else ProcessRobotUnloadBusyOn(1); break;
            case 0x52: if (nValue == 0) ProcessRobotUnloadBusyOff(2); else ProcessRobotUnloadBusyOn(2); break;
            case 0x72: if (nValue == 0) ProcessRobotUnloadBusyOff(3); else ProcessRobotUnloadBusyOn(3); break;

            case 0x02: if (nValue == 0) ProcessRobotLoadBusyOff(0); else ProcessRobotLoadBusyOn(0); break;
            case 0x22: if (nValue == 0) ProcessRobotLoadBusyOff(1); else ProcessRobotLoadBusyOn(1); break;
            case 0x42: if (nValue == 0) ProcessRobotLoadBusyOff(2); else ProcessRobotLoadBusyOn(2); break;
            case 0x62: if (nValue == 0) ProcessRobotLoadBusyOff(3); else ProcessRobotLoadBusyOn(3); break;

            case 0x04: case 0x24: case 0x44: case 0x64:
                if (nValue == 0)
                {
                    ProcessRobotNormalOff(nIndex / 0x20, nValue);
                    _status.SetLoadUnloadFlowData(nIndex / 0x20, CommPlcConst.ModeLoad12, 0);
                }
                else
                    _status.SetLoadUnloadFlowData(nIndex / 0x20, CommPlcConst.ModeLoad12, 1);
                break;

            case 0x14: case 0x34: case 0x54: case 0x74:
                if (nValue == 0)
                {
                    ProcessRobotNormalOff(nIndex / 0x20, nValue);
                    _status.SetLoadUnloadFlowData(nIndex / 10, CommPlcConst.ModeUnload12, 0);
                }
                else
                    _status.SetLoadUnloadFlowData(nIndex / 10, CommPlcConst.ModeUnload12, 1);
                break;

            // PreOC+GIB specific: Load Complete via vacuum check
            case 0x09: if (nValue == 0 && IsBitOnRobot(0x02)) ProcessRobotLoadComplete(0); break;
            case 0x29: if (nValue == 0 && IsBitOnRobot(0x22)) ProcessRobotLoadComplete(1); break;
            case 0x49: if (nValue == 0 && IsBitOnRobot(0x42)) ProcessRobotLoadComplete(2); break;
            case 0x69: if (nValue == 0 && IsBitOnRobot(0x62)) ProcessRobotLoadComplete(3); break;

            // PreOC+GIB specific: Unload Complete via vacuum check
            case 0x19:
                if (nValue == 1 && IsBitOnRobot(0x12))
                { ProcessRobotVacuum(0, 0); ProcessRobotUnloadComplete(0); }
                break;
            case 0x39:
                if (nValue == 1 && IsBitOnRobot(0x32))
                { ProcessRobotVacuum(1, 0); ProcessRobotUnloadComplete(1); }
                break;
            case 0x59:
                if (nValue == 1 && IsBitOnRobot(0x52))
                { ProcessRobotVacuum(2, 0); ProcessRobotUnloadComplete(2); }
                break;
            case 0x79:
                if (nValue == 1 && IsBitOnRobot(0x72))
                { ProcessRobotVacuum(3, 0); ProcessRobotUnloadComplete(3); }
                break;
        }
    }

    // =========================================================================
    // Process_CVData (Delphi: line 3730)
    // =========================================================================

    private void ProcessCvData()
    {
        for (int i = 0; i < CommPlcConst.CvDataSize; i++)
        {
            if (PollingCv[i] == PollingCvPre[i]) continue;

            for (int k = 0; k <= 15; k++)
            {
                int nValue = GetBit(PollingCv[i], k);
                if (nValue == GetBit(PollingCvPre[i], k)) continue;

                int nIndex = i * 16 + k;
                AddLog($"<< ChangedDevice CV B{StartAddrRobotDoorBit + nIndex:X3}: {nValue}", true);

                if (InlineGib)
                {
                    switch (nIndex)
                    {
                        case 0x01: // Door Open Warning
                            ProcessDoorOpenWarning(nValue != 0 ? 1 : 0);
                            break;
                        case 0x03: // Door Open Info
                            ProcessDoorOpenInfo(nValue != 0 ? 1 : 0);
                            break;
                    }
                }
            }
        }
    }

    // =========================================================================
    // Process_ECSData (Delphi: line 3880)
    // =========================================================================

    private void ProcessEcsData()
    {
        for (int i = 0; i <= CommPlcConst.EcsDataSize; i++)
        {
            if (PollingEcs[i] == PollingEcsPre[i]) continue;

            for (int k = 0; k <= 15; k++)
            {
                int nValue = GetBit(PollingEcs[i], k);
                if (nValue == GetBit(PollingEcsPre[i], k)) continue;

                int nIndex = i * 16 + k;
                if (i == CommPlcConst.EcsDataSize)
                    AddLog($"<< ChangedDevice ECS Common B000: {nValue}", true);
                else
                    AddLog($"<< ChangedDevice ECS B{StartAddrEcs + nIndex:X3}: {nValue}", true);

                // Link test echo
                int linkTestBit = InlineGib ? (EqpId + 10) % 16 : (EqpId + 13) % 16;
                if (nIndex == linkTestBit)
                {
                    WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x1:X3}", nValue);
                    _linkTestTick = Environment.TickCount64;
                }

                // ECS special events
                switch (nIndex)
                {
                    case 0x30: // ECS Restart
                        _ = Task.Run(() => EcsRestartTest());
                        break;
                    case 0x31: // Time Data Send
                        if (nValue == 1) ReadTimeData();
                        break;
                }
            }
        }
    }

    // =========================================================================
    // Process_AlarmQue (Delphi: line 3779)
    // =========================================================================

    private void ProcessAlarmQue()
    {
        if (_alarmQueue.IsEmpty) return;

        if (_alarmQueue.TryDequeue(out var item))
        {
            EcsAlarmReport(item.AlarmType, item.AlarmCode, item.AlarmValue);
            _lastAlarmTick = Environment.TickCount64;
        }
    }

    // =========================================================================
    // Process_MESQue (Delphi: line 3799)
    // =========================================================================

    private void ProcessMesQue()
    {
        if (_mesQueue.IsEmpty) return;
        if (_mesWorking) return;

        _ = Task.Run(() =>
        {
            long tick = Environment.TickCount64;
            if (tick - _lastMesTick < 1000) return;

            _mesWorking = true;

            if (!_mesQueue.TryDequeue(out var item))
            {
                _mesWorking = false;
                return;
            }

            int nRet = 0;
            try
            {
                switch (item.Kind)
                {
                    case CommPlcConst.MesKindPchk:
                        nRet = EcsPchk(item.Value.Channel, item.Value.SerialNo);
                        if (nRet != 0)
                            AddLog($"ECS_PCHK NG - {nRet}");
                        else
                            item.Value.LcmId = EcsGlassDataArray[item.Value.Channel].LcmId;
                        break;

                    case CommPlcConst.MesKindEicr:
                        nRet = EcsEicr(item.Value.Channel,
                            EcsGlassDataArray[item.Value.Channel].LcmId,
                            item.Value.ErrorCode, item.Value.InspectionResult);
                        if (nRet != 0)
                            AddLog($"ECS_EICR NG - {nRet}");
                        break;

                    case CommPlcConst.MesKindApdr:
                        nRet = EcsApdr(item.Value.Channel, item.Value.InspectionResult);
                        if (nRet != 0)
                            AddLog($"ECS_APDR NG - {nRet}");
                        break;

                    case CommPlcConst.MesKindZset:
                        nRet = EcsZset(item.Value.Channel, item.Value.BondingType,
                            item.Value.CarrierId, item.Value.SerialNo, item.Value.PcbId,
                            out _);
                        if (nRet != 0)
                            AddLog($"ECS_ZSET NG - {nRet}");
                        break;
                }

                item.Value.Ack = nRet;
                item.NotifyEvent?.Invoke(item.Value);
            }
            finally
            {
                _lastMesTick = Environment.TickCount64;
                _mesWorking = false;
            }
        });
    }

    // =========================================================================
    // Process_Door_Open_Warning / Process_Door_Open_Info
    // =========================================================================

    private void ProcessDoorOpenWarning(int value)
    {
        AddLog($"Process_Door_Open_Warning {value}");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x05 + 0x1:X3}", value);
    }

    private void ProcessDoorOpenInfo(int value)
    {
        AddLog($"Process_Door_Open_Info {value}");
        SendMessageMain(CommPlcConst.ModeEventRobot, 0,
            CommPlcConst.ParamDoorOpened, value, "Robot_DoorOpened");
    }

    // =========================================================================
    // Read_ROBOT_GlassData (Delphi: line 3948)
    // =========================================================================

    private void ReadRobotGlassData(int nCh)
    {
        AddLog($"Process_ROBOT_GlassData_Read {nCh}");
        var block = new int[65];
        int rc;

        if (InlineGib)
        {
            ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x0 + 0x0 + nCh * 0x40:X3}",
                64, block, out rc);
            ConvertBlockToGlassData(block, GlassData[nCh]);
        }
        else
        {
            // First glass data block
            if (nCh == 1 && StartAddrRobotW2 != 0)
                ReadDeviceBlock($"W{StartAddrRobotW2 + 0x10 * 0x0 + 0x0:X3}",
                    64, block, out rc);
            else
                ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x0 + 0x0 + nCh * 0x80:X3}",
                    64, block, out rc);

            if (_config.SystemInfo.CHReversal)
                ConvertBlockToGlassData(block, GlassData[nCh * 2 + 1]);
            else
                ConvertBlockToGlassData(block, GlassData[nCh * 2]);

            // Second glass data block
            if (nCh == 1 && StartAddrRobotW2 != 0)
                ReadDeviceBlock($"W{StartAddrRobotW2 + 0x10 * 0x0 + 0x40:X3}",
                    64, block, out rc);
            else
                ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x0 + 0x40 + nCh * 0x80:X3}",
                    64, block, out rc);

            if (_config.SystemInfo.CHReversal)
                ConvertBlockToGlassData(block, GlassData[nCh * 2]);
            else
                ConvertBlockToGlassData(block, GlassData[nCh * 2 + 1]);
        }
    }

    // =========================================================================
    // Read_ECS_GlassData (Delphi: line 3099)
    // =========================================================================

    private void ReadEcsGlassData(int nCh)
    {
        AddLog($"Read_ECS_GlassData {nCh}");
        var block = new int[65];
        ReadDeviceBlock($"W{StartAddrEcsW + 0x10 * 0x0 + 0x0:X3}",
            64, block, out _);
        ConvertBlockToGlassData(block, EcsGlassDataArray[nCh]);
    }

    // =========================================================================
    // Process_ROBOT_GlassData_Report (Delphi: line 3994)
    // =========================================================================

    private void ProcessRobotGlassDataReport(int nCh)
    {
        RequestStateLoad[nCh] = 2;
        _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad2, 1);
        AddLog($"Process_ROBOT_GlassData_Report {nCh}");

        var block = new int[65];
        int rc;
        var (lb, ub) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        if (InlineGib)
        {
            ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x0 + 0x0 + nCh * 0x40:X3}",
                64, block, out rc);
            ConvertBlockToGlassData(block, GlassData[nCh]);

            AddLog($"ROBOT_Load Request {nCh}");
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x5 + chOff:X3}", 1); // Load Request
            _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad3, 1);
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 1); // Unload Enable
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 1); // Load Enable
            _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad4, 1);

            RequestStateLoad[nCh] = 2;
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh, CommPlcConst.ParamGlassDataReport, 0,
                $"{GlassData[nCh].CarrierId} ({GlassData[nCh].GlassId})");
        }
        else
        {
            // Read two glass data blocks
            if (nCh == 1 && StartAddrRobotW2 != 0)
                ReadDeviceBlock($"W{StartAddrRobotW2 + 0x10 * 0x0 + 0x0:X3}",
                    64, block, out rc);
            else
                ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x0 + 0x0 + nCh * 0x80:X3}",
                    64, block, out rc);

            if (_config.SystemInfo.CHReversal)
                ConvertBlockToGlassData(block, GlassData[nCh * 2 + 1]);
            else
                ConvertBlockToGlassData(block, GlassData[nCh * 2]);

            if (nCh == 1 && StartAddrRobotW2 != 0)
                ReadDeviceBlock($"W{StartAddrRobotW2 + 0x10 * 0x0 + 0x40:X3}",
                    64, block, out rc);
            else
                ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x0 + 0x40 + nCh * 0x80:X3}",
                    64, block, out rc);

            if (_config.SystemInfo.CHReversal)
                ConvertBlockToGlassData(block, GlassData[nCh * 2]);
            else
                ConvertBlockToGlassData(block, GlassData[nCh * 2 + 1]);

            AddLog($"ROBOT_Load Request {nCh}");
            _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad3, 1);
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x5 + chOff:X3}", 1); // Load Request
            Thread.Sleep(100);
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 1); // Load Enable
            _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad4, 1);

            RequestStateLoad[nCh] = 2;
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh, CommPlcConst.ParamGlassDataReport, 0,
                $"{GlassData[nCh * 2].CarrierId} ({GlassData[nCh * 2].GlassId}), " +
                $"{GlassData[nCh * 2 + 1].CarrierId} ({GlassData[nCh * 2 + 1].GlassId})");
        }
    }

    // =========================================================================
    // Process_ROBOT_LoadComplete (Delphi: line 4122)
    // =========================================================================

    private void ProcessRobotLoadComplete(int nCh)
    {
        AddLog($"Process_ROBOT_LoadComplete {nCh}");
        _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad6, 1);
        ReadRobotGlassData(nCh);

        var (lb, ub) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x1 + chOff:X3}", 0); // Glass Data Request off
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x5 + chOff:X3}", 0); // Load Request off
        Thread.Sleep(50);
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x6 + chOff:X3}", 1); // Load Complete Confirm
        _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad7, 1);

        RequestStateLoad[nCh] = 3;
        SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
            CommPlcConst.ParamLoadComplete, 1,
            $"Process_ROBOT_LoadComplete {nCh}");
    }

    // =========================================================================
    // Process_ROBOT_LoadComplete_Off (Delphi: line 4167)
    // =========================================================================

    private void ProcessRobotLoadCompleteOff(int nCh)
    {
        AddLog($"Process_ROBOT_LoadComplete_Off {nCh}");
        var (lb, _) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x6 + chOff:X3}", 0); // Load Complete Confirm off

        SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
            CommPlcConst.ParamLoadComplete, 0,
            $"Process_ROBOT_LoadComplete_Off {nCh}");
    }

    // =========================================================================
    // Process_ROBOT_LoadBusy_On (Delphi: line 4216)
    // =========================================================================

    private void ProcessRobotLoadBusyOn(int nCh)
    {
        if (RequestStateLoad[nCh] < 1)
        {
            AddLog($"Process_ROBOT_LoadBusy_On Error - Not Request Ch {nCh}");
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                CommPlcConst.ParamInterfaceError, 1,
                $"Process_ROBOT_LoadBusy_On Error - Not Request Ch {nCh}");
            return;
        }
        _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeLoad5, 1);
        AddLog($"Process_ROBOT_LoadBusy_On {nCh}");
        SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
            CommPlcConst.ParamLoadBusy, 1,
            $"Process_ROBOT_LoadBusy_On {nCh}");
    }

    // =========================================================================
    // Process_ROBOT_LoadBusy_Off (Delphi: line 4230)
    // =========================================================================

    private void ProcessRobotLoadBusyOff(int nCh)
    {
        AddLog($"Process_ROBOT_LoadBusy_Off {nCh}", true);
        var (lb, ub) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        if (InlineGib)
        {
            if (!IsBusyRobotEach(nCh))
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 0); // Load Enable off
                WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 0); // Unload Enable Off
            }
        }
        else
        {
            if (!IsBusyRobot(nCh))
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 0); // Load Enable off
                WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 0); // Unload Enable Off
            }
        }

        RequestStateLoad[nCh] = 0;

        // Send message based on detection status
        if (InlineGib || IsPreOcType)
        {
            // For InlineGIB or PreOC, only notify if detected
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                CommPlcConst.ParamLoadBusy, 0,
                $"Process_ROBOT_LoadBusy_Off {nCh}");
        }
        else
        {
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                CommPlcConst.ParamLoadBusy, 0,
                $"Process_ROBOT_LoadBusy_Off {nCh}");
        }
    }

    // =========================================================================
    // Process_ROBOT_UnloadComplete (Delphi: line 4277)
    // =========================================================================

    private void ProcessRobotUnloadComplete(int nCh)
    {
        AddLog($"Process_ROBOT_UnloadComplete {nCh}", true);
        _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeUnload5, 1);

        var (_, ub) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeUnload6, 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x6 + chOff:X3}", 1); // Unload Complete Confirm
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x5 + chOff:X3}", 0); // Unload Request Off
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x1 + chOff:X3}", 0); // Glass Data Request Off

        SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
            CommPlcConst.ParamUnloadComplete, 1,
            $"Process_ROBOT_UnloadComplete {nCh}");
    }

    // =========================================================================
    // Process_ROBOT_UnloadComplete_Off (Delphi: line 4316)
    // =========================================================================

    private void ProcessRobotUnloadCompleteOff(int nCh)
    {
        AddLog($"Process_ROBOT_UnloadComplete_Off {nCh}", true);
        var (_, ub) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x6 + chOff:X3}", 0); // Unload Complete Confirm Off

        SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
            CommPlcConst.ParamUnloadComplete, 0,
            $"Process_ROBOT_UnloadComplete_Off {nCh}");
    }

    // =========================================================================
    // Process_ROBOT_UnloadBusy_On (Delphi: line 4346)
    // =========================================================================

    private void ProcessRobotUnloadBusyOn(int nCh)
    {
        if (RequestStateUnload[nCh] < 1)
        {
            AddLog($"Process_ROBOT_UnloadBusy_On Error - Not Request Ch={nCh}", true);
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                CommPlcConst.ParamInterfaceError, 1,
                $"Process_ROBOT_UnloadBusy_On Error - Not Request Ch {nCh}");
            return;
        }
        _status.SetLoadUnloadFlowData(nCh, CommPlcConst.ModeUnload4, 1);
        AddLog($"Process_ROBOT_UnloadBusy_On {nCh}", true);
        SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
            CommPlcConst.ParamUnloadBusy, 1,
            $"Process_ROBOT_UnloadBusy_On {nCh}");
    }

    // =========================================================================
    // Process_ROBOT_UnloadBusy_Off (Delphi: line 4359)
    // =========================================================================

    private void ProcessRobotUnloadBusyOff(int nCh)
    {
        AddLog($"Process_ROBOT_UnloadBusy_Off {nCh}", true);
        var (lb, ub) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        if (InlineGib)
        {
            if (!IsBusyRobotEach(nCh))
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 0); // Load Enable off
                WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 0); // Unload Enable Off
            }
        }
        else
        {
            if (!IsBusyRobot(nCh))
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 0); // Load Enable off
                WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 0); // Unload Enable Off
            }
        }

        RequestStateUnload[nCh] = 0;

        if (IsOcType)
        {
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                CommPlcConst.ParamUnloadBusy, 0,
                $"Process_ROBOT_UnloadBusy_Off {nCh}");
        }
        else if (InlineGib)
        {
            int pairCh = (nCh % 2 == 1) ? nCh - 1 : nCh + 1;
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                CommPlcConst.ParamUnloadBusy, 0,
                $"Process_ROBOT_UnloadBusy_Off {nCh}");
            Thread.Sleep(200);
            SendMessageMain(CommPlcConst.ModeEventRobot, pairCh,
                CommPlcConst.ParamUnloadBusy, 0,
                $"Process_ROBOT_UnloadBusy_Off {nCh}");
        }
        else
        {
            SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                CommPlcConst.ParamUnloadBusy, 0,
                $"Process_ROBOT_UnloadBusy_Off {nCh}");
        }
    }

    // =========================================================================
    // Process_Robot_Normal_Off (Delphi: line 4193)
    // =========================================================================

    private void ProcessRobotNormalOff(int nCh, int nValue)
    {
        if (nValue == 0)
        {
            if (RequestStateUnload[0] == 1 || RequestStateLoad[0] == 1
                || RequestStateUnload[1] == 1 || RequestStateLoad[1] == 1)
            {
                SendMessageMain(CommPlcConst.ModeEventRobot, nCh,
                    CommPlcConst.ParamInterfaceError, 1, "Process_ROBOT_Normal_Off");
            }
        }
    }
}
