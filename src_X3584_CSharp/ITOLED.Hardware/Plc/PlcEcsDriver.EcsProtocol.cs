// =============================================================================
// PlcEcsDriver.EcsProtocol.cs  (partial)
// ECS protocol methods: UCHK, PCHK, EICR, APDR, ZSET, Alarm, GlassData, etc.
// Converted from Delphi: CommPLC_ECS.pas lines 1084-2030
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Hardware.Plc;

public sealed partial class PlcEcsDriver
{
    // =========================================================================
    // ECS_Accessory_Unit_Status
    // Delphi origin: line 1084
    // =========================================================================

    /// <inheritdoc />
    public int EcsAccessoryUnitStatus(int stage, int value, int alarmCode)
    {
        if (!Connected) return 1;

        AddLog($"ECS_Accessory_Unit_Status Stage={stage}, Value={value}");
        if (value == 2)
            WriteDevice($"W{StartAddrEqpW + 0x10 * 0x0E + stage:X3}", alarmCode);
        else
            WriteDevice($"W{StartAddrEqpW + 0x10 * 0x0E + stage:X3}", 0);

        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x0D + stage:X3}", value);
        return 0;
    }

    // =========================================================================
    // ECS_Alarm_Add / ECS_Alarm_Report
    // Delphi origin: line 1102 / 1131
    // =========================================================================

    /// <inheritdoc />
    public int EcsAlarmAdd(int alarmType, int alarmCode, int onOff)
    {
        if (!Connected) return 1;
        if (_statusMode == 3 && onOff == 1) return 0;
        if (alarmType == 0 && onOff == 1 && LastLightCode != 0) return 0;
        if (alarmType == 0 && onOff == 0 && LastLightCode == 0) return 0;

        AddLog($"ECS_Alarm_Add Type={alarmType}, Code={alarmCode}, OnOff={onOff}");
        _alarmQueue.Enqueue(new AlarmItem(alarmType, alarmCode, onOff));

        EcsAlarmReport(alarmType, alarmCode, onOff);

        if (alarmType == 1)
            LastHeavyCode = alarmCode;
        if (alarmType == 0)
        {
            LastLightCode = alarmCode;
            if (onOff == 0) LastLightCode = 0;
        }
        return 0;
    }

    /// <inheritdoc />
    public int EcsAlarmReport(int alarmType, int alarmCode, int onOff)
    {
        if (!Connected) return 1;

        AddLog($"ECS_Alarm_Report Type={alarmType}, Code={alarmCode}, OnOff={onOff}");

        if (onOff != 0)
        {
            if (alarmType == 0) // Light Alarm ON
            {
                WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xC:X3}", alarmCode);
                PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0xC:X3}", 0xC, 1000);
            }
            else // Heavy Alarm ON
            {
                WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xD:X3}", alarmCode);
                PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0xE:X3}", 0xE, 1000);
            }
        }
        else
        {
            if (alarmType == 0) // Light Alarm OFF
            {
                WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xE:X3}", alarmCode);
                PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0xD:X3}", 0xD, 1000);
            }
            else // Heavy Alarm OFF
            {
                WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xF:X3}", alarmCode);
                PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0xF:X3}", 0xF, 1000);
            }
        }
        return 0;
    }

    // =========================================================================
    // ECS_GlassData_Report
    // Delphi origin: line 1177
    // =========================================================================

    /// <inheritdoc />
    public int EcsGlassDataReport(int channel, EcsGlassData glassData)
    {
        if (!Connected) return 1;

        AddLog("ECS_GlassData_Report");
        var block = new int[65];
        ConvertGlassDataToBlock(glassData, block);
        block[27] = glassData.GlassJudge + channel; // nCH added to GlassJudge

        if (IsPreOcType && InlineGib)
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x20 + 0x0 + channel * 0x40:X3}", 64, block);
        else
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x10 + 0x0 + channel * 0x40:X3}", 64, block);

        return 0;
    }

    // =========================================================================
    // ECS_Glass_Position / ECS_Glass_PositionAll
    // Delphi origin: line 1219 / 1279
    // =========================================================================

    /// <inheritdoc />
    public int EcsGlassPosition(int channel, bool exists)
    {
        if (!Connected) return 1;

        AddLog($"ECS_Glass_Position Ch={channel}, Exist={exists}");

        int posWordOffset = IsOcType ? 0x07 : 0x0C;
        int posBitOffset = IsOcType ? 0x07 : 0x0C;
        int code = exists ? GlassData[channel].GlassCode : 0;
        int bitVal = exists ? 1 : 0;

        WriteDevice($"W{StartAddrEqpW + 0x10 * posWordOffset + channel:X3}", code);
        Thread.Sleep(10);
        WriteDevice($"B{StartAddrEqp + 0x10 * posBitOffset + channel:X3}", bitVal);

        return 0;
    }

    /// <inheritdoc />
    public int EcsGlassPositionAll(int[] existsArr)
    {
        if (!Connected) return 1;

        var glassCode = new int[16];
        var log = "ECS_Glass_PositionAll:";
        for (int i = 0; i < 8 && i < existsArr.Length; i++)
        {
            log += $" {existsArr[i]}";
            glassCode[i] = existsArr[i] != 0 ? GlassData[i].GlassCode : 0;
        }
        AddLog(log);

        WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x1F + 0x0:X3}", 16, glassCode);
        WriteDeviceBlock($"B{StartAddrEqp + 0x10 * 0x0A + 0x0:X3}", 16, existsArr);
        return 0;
    }

    // =========================================================================
    // ECS_Glass_Processing / ECS_Glass_Exist / ECS_IonizerStatus
    // =========================================================================

    /// <inheritdoc />
    public int EcsGlassProcessing(bool processing)
    {
        AddLog($"ECS_Glass_Processing processing={processing}");
        if (processing)
        {
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0xB:X3}", 1);
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x04 + 0x3:X3}", 0);
        }
        else
        {
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0xB:X3}", 0);
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x04 + 0x3:X3}", 1);
        }
        return 0;
    }

    /// <inheritdoc />
    public int EcsGlassExist(int existCount, int useCount)
    {
        if (!Connected) return 1;
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xC:X3}", existCount);
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xD:X3}", useCount);
        return 0;
    }

    /// <inheritdoc />
    public int EcsIonizerStatus(int index, int value)
    {
        AddLog($"ECS_IonizerStatus Index={index}, Value={value}");
        if (index > 15)
            WriteDeviceBit($"W{StartAddrEqpW + 0x10 * 0x00 + 0x6:X3}", index, value);
        else
            WriteDeviceBit($"W{StartAddrEqpW + 0x10 * 0x00 + 0x7:X3}", index, value);
        return 0;
    }

    // =========================================================================
    // ECS_Link_Test / ECS_ECSRestart_Test
    // =========================================================================

    /// <inheritdoc />
    public int EcsLinkTest()
    {
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x1:X3}", 1);
        int ret = WaitSignal($"B{StartAddrEcs + 0x10 * 0x30 + 0x1:X3}", 1, CommPlcConst.EcsTimeout);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x1:X3}", 0);
        return ret != 0 ? 258 : 0;
    }

    /// <inheritdoc />
    public int EcsRestartTest()
    {
        AddLog("ECS_ECSRestart_Test");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x0:X3}", 1);
        int ret = WaitSignal("B000", 0, CommPlcConst.EcsTimeout);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x0:X3}", 0);
        if (ret != 0) return 258;

        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x2:X3}", 1);
        Thread.Sleep(1000);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x2:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x3:X3}", 1);
        Thread.Sleep(1000);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x3:X3}", 0);
        return 0;
    }

    // =========================================================================
    // ECS_Lost_Glass_Request
    // Delphi origin: line 1349
    // =========================================================================

    /// <inheritdoc />
    public int EcsLostGlassRequest(string glassId, int glassCode, int requestOption, int channel = 0)
    {
        if (!Connected) return 1;

        int nIndex = (EqpId + 13) % 16;
        AddLog($"ECS_Lost_Glass_Request GlassCode={glassCode}, GlassID={glassId}, Option={requestOption}, Ch={channel}");

        if (IsOcType)
        {
            WriteString($"W{StartAddrEqpW + 0x10 * 0x02 + 0x0:X3}", glassId.PadRight(16));
            WriteDevice($"W{StartAddrEqpW + 0x10 * 0x02 + 0xF:X3}", glassCode);
            WriteDevice($"W{StartAddrEqpW + 0x10 * 0x02 + 0xE:X3}", requestOption);
        }
        else
        {
            WriteString($"W{StartAddrEqpW + 0x10 * 0x08 + 0x0:X3}", glassId.PadRight(16));
            WriteDevice($"W{StartAddrEqpW + 0x10 * 0x08 + 0xF:X3}", glassCode);
            WriteDevice($"W{StartAddrEqpW + 0x10 * 0x08 + 0xE:X3}", requestOption);
        }
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x0:X3}", 1); // Lost Glass Data Request

        string ecsBitAddr = InlineGib
            ? $"B{StartAddrEcs + 0x100 + (EqpId + 10) % 16:X3}"
            : $"B{StartAddrEcs + 0x100 + nIndex:X3}";

        int ret = WaitSignal(ecsBitAddr, 1, 3000);
        if (ret != 0)
        {
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x0:X3}", 0);
            Thread.Sleep(1000);
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x0:X3}", 1);
            ret = WaitSignal(ecsBitAddr, 1, 3000);
            if (ret != 0)
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x0:X3}", 0);
                AddLog("ECS_Lost_Glass_Request T3 TIME OUT");
                SendMessageMain(CommPlcConst.ModeEventEcs, 0, 2, 0, "ECS_Lost_Glass_Request T3 TIME OUT");
                return 258;
            }
        }

        var glassBlock = new int[65];
        ReadDeviceBlock($"W{StartAddrEcsW + 0x10 * 0x0C + 0x0:X3}", 64, glassBlock, out _);

        string logBefore = GetGlassDataString(GlassData[channel]);
        AddLog($"<LostGlass> Before Glass CH:{channel + 1} Glassdata : {logBefore}");

        ConvertBlockToGlassData(glassBlock, GlassData[channel]);

        string logAfter = GetGlassDataString(GlassData[channel]);
        AddLog($"<LostGlass> After Glass CH:{channel + 1} Glassdata : {logAfter}");

        WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x0:X3}", 0);

        ReadDevice("B003", out int lpData, false);
        ReadDevice("B004", out int lpData2, false);

        int result = 1;
        if (lpData == 1) result = 0;
        if (lpData2 == 1)
        {
            SendMessageMain(CommPlcConst.ModeEventEcs, 0, 2, 0, $"Lost Glass Data Ack NG GlassID={glassId}");
            result = 1;
        }

        AddLog($"ECS_Lost_Glass_Request Ok GlassID={GlassData[channel].GlassId}");
        return result;
    }

    // =========================================================================
    // ECS_Change_Glass_Report / ECS_Scrap_Glass_Report
    // =========================================================================

    /// <inheritdoc />
    public int EcsChangeGlassReport(EcsGlassData glassData)
    {
        if (!Connected) return 1;

        AddLog($"ECS_Change_Glass_Report CarrierID={glassData.CarrierId}");
        var block = new int[65];
        ConvertGlassDataToBlock(glassData, block);
        WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x01 + 0x0:X3}", 64, block);
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x06 + 0x0:X3}", 7); // CEID=7
        PulseDevice($"B{StartAddrEqp + 0x10 * 0x02 + 0x4:X3}", 3000);
        return 0;
    }

    /// <inheritdoc />
    public int EcsScrapGlassReport(EcsGlassData glassData, string scrapCode)
    {
        if (!Connected) return 1;

        AddLog($"ECS_Scrap_Glass_Report ScrapCode={scrapCode}");
        var block = new int[65];
        ConvertGlassDataToBlock(glassData, block);
        WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x01 + 0x0:X3}", 64, block);
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x06 + 0x0:X3}", 2); // CEID=2

        int code = 0;
        if (int.TryParse(scrapCode, out int parsed)) code = parsed;
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x06 + 0x1:X3}", code);

        PulseDevice($"B{StartAddrEqp + 0x10 * 0x02 + 0x2:X3}", 3000);
        return 0;
    }

    // =========================================================================
    // ECS_MES_AddItem
    // =========================================================================

    /// <inheritdoc />
    public int EcsMesAddItem(MesItem item)
    {
        if (!Connected) return 1;
        AddLog($"ECS_MES_AddItem Ch={item.Value.Channel}, Kind={item.Kind}");
        _mesQueue.Enqueue(item);
        return 0;
    }

    // =========================================================================
    // ECS_ModelChange_Request
    // Delphi origin: line 1506
    // =========================================================================

    /// <inheritdoc />
    public int EcsModelChangeRequest(int index)
    {
        if (!Connected) return 1;

        AddLog($"ECS_ModelChange_Request: Index={index}");
        WriteDevice($"W{StartAddr2EqpW + 0x10 * 0x00 + 0xA:X3}", index);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x5:X3}", 1);

        int ret = WaitSignal($"B{StartAddrEcs + 0x10 * 0xBA + 0x0:X3}", 3, 3000);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x5:X3}", 0);
        if (ret != 0) return 258;

        ReadDevice($"W{StartAddrEcsW + 0x10 * 0x30 + 0x1:X3}", out int lpData);
        if (lpData != 0)
        {
            AddLog("ECS_ModelChange_Request NG");
            return lpData;
        }
        AddLog("ECS_ModelChange_Request OK");
        return 0;
    }

    // =========================================================================
    // ECS_NormalOperation
    // =========================================================================

    /// <inheritdoc />
    public int EcsNormalOperation(string glassId)
    {
        if (!Connected) return 1;
        AddLog($"ECS_NormalOperation GlassID={glassId}");
        WriteString($"W{StartAddrEqpW + 0x10 * 0x07 + 0x0:X3}", glassId.PadRight(16));
        return 0;
    }

    // =========================================================================
    // ECS_Unit_Status
    // Delphi origin: line 1551
    // =========================================================================

    /// <inheritdoc />
    public int EcsUnitStatus(int mode, int value)
    {
        if (!Connected) return 1;

        AddLog($"ECS_Unit_Status Mode={mode}, Value={value}");

        switch (mode)
        {
            case CommPlcConst.UnitStateOnline: // 0
                if (InlineGib)
                {
                    ItcAllChNormalStatusOnOff(value);
                    ReadDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x0:X3}", out int eqpOnline);
                    if (eqpOnline == value)
                    {
                        AddLog($"ECS_Unit_Status Mode={mode}, Value={value} skip: Same Status={eqpOnline}");
                        return 0;
                    }
                }
                if (_statusOnline != value)
                {
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x0:X3}", value);
                    _statusOnline = value;
                    PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0x2:X3}", 0x2, 1000);
                }
                if (InlineGib)
                {
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xD:X3}", 0);
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0xF:X3}", 0);
                }
                break;

            case CommPlcConst.UnitStateRun: // 8
                if (_statusMode != 1)
                {
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x3:X3}", 1); // Run
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x4:X3}", 0); // Down Alarm Code clear
                    PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0x3:X3}", 0x3, 1000);
                }
                _statusMode = 1;
                break;

            case CommPlcConst.UnitStateIdle: // 9
                if (_statusMode != 2)
                {
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x3:X3}", 2); // Idle
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x4:X3}", 0);
                    PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0x3:X3}", 0x3, 1000);
                }
                _statusMode = 2;
                break;

            case CommPlcConst.UnitStateDown: // 10
                if (InlineGib)
                {
                    ItcAllChNormalStatusOnOff(0);
                    ReadDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x4:X3}", out int eqpAlarm);
                    if (eqpAlarm != 0)
                    {
                        AddLog($"ECS_Unit_Status Mode={mode}, Value={value} skip: Exist Alarm Code={eqpAlarm}");
                        return 0;
                    }
                }
                if (_statusMode != 3)
                {
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x3:X3}", 3); // Down
                    WriteDevice($"W{StartAddrEqpW + 0x10 * 0x00 + 0x4:X3}", value); // Alarm code
                    PulseDeviceBit($"B{StartAddrEqp + 0x10 * 0x00 + 0x3:X3}", 0x3, 1000);
                }
                _statusMode = 3;
                break;

            case CommPlcConst.UnitStateGlassProcess: // 11
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0xB:X3}", value);
                break;

            case CommPlcConst.UnitStateGlassExist: // 12
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0xC:X3}", value);
                break;

            case CommPlcConst.UnitStatePreviousTransferEnable: // 13
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0xD:X3}", value);
                break;
        }
        return 0;
    }

    // =========================================================================
    // ECS_WriteTactTime
    // =========================================================================

    /// <inheritdoc />
    public int EcsWriteTactTime(int tactTimeMs)
    {
        if (!Connected) return 0;
        int plcTact = tactTimeMs / 10; // 3.5s => 350
        AddLog($"ECS_WriteTactTime: TACTTIME={plcTact}");
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x0F + 0xF:X3}", plcTact);
        PulseDevice($"B{StartAddrEqp + 0x10 * 0x07 + 0x0:X3}", CommPlcConst.EcsTimeout);
        return 0;
    }

    // =========================================================================
    // ECS_UCHK
    // Delphi origin: line 1659
    // =========================================================================

    /// <inheritdoc />
    public int EcsUchk(string userId)
    {
        if (!Connected) return 1;

        AddLog($"ECS_UCHK UID={userId}");
        WriteString($"W{StartAddrEqpW + 0x10 * 0x0F + 0x4:X3}", userId.PadRight(20));
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x07 + 0xF:X3}", 1); // User ID Manual Report

        int ret = WaitSignal($"B{StartAddrEcs + 0x10 * 0x01 + 0x1:X3}", 1, CommPlcConst.EcsTimeout);

        ReadDevice($"W{StartAddrEcsW + 0x10 * 0x14 + 0xF:X3}", out int lpData);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x07 + 0xF:X3}", 0); // Report Off

        if (ret != 0)
        {
            AddLog("ECS_UCHK NG Response Timeout");
            SendMessageMain(CommPlcConst.ModeLogin, 0, 2, 0, "ECS_UCHK NG Response Timeout");
            return 258;
        }

        if (lpData != 0)
        {
            IsLoggedIn = false;
            AddLog("ECS_UCHK NG");
            SendMessageMain(CommPlcConst.ModeLogin, 0, 0, 0, "ECS_UCHK NG");
            return 100;
        }

        IsLoggedIn = true;
        AddLog("ECS_UCHK OK");
        SendMessageMain(CommPlcConst.ModeLogin, 0, 1, 0, "ECS_UCHK OK");
        return 0;
    }

    // =========================================================================
    // ECS_PCHK
    // Delphi origin: line 1710
    // =========================================================================

    /// <inheritdoc />
    public int EcsPchk(int channel, string serial)
    {
        if (!Connected) return 1;

        AddLog($"ECS_PCHK: Ch={channel}, Serial={serial}");

        WriteString($"W{StartAddrEqpW + 0x10 * 0x10 + 0x0:X3}", serial.PadRight(174));
        AddLog("BCR Read Report");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x0:X3}", 1); // BCR Data Report On

        int ret = WaitSignal($"B{StartAddrEcs + 0x10 * 0x03 + 0:X3}", 1, EcsTimeout);

        var glassBlock = new int[65];
        ReadDeviceBlock($"W{StartAddrEcsW + 0x10 * 0x00 + 0x0:X3}", 64, glassBlock, out _);
        ConvertBlockToGlassData(glassBlock, EcsGlassDataArray[channel]);

        EcsLcmId[channel] = ReadString($"W{StartAddrEcsW + 0x10 * 0x04 + 0x0:X3}", 0, 24);

        ReadDevice($"W{StartAddrEcsW + 0x10 * 0x04 + 0xF:X3}", out int nValue);

        AddLog("BCR Read Report Off");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x0:X3}", 0); // BCR Data Report Off

        if (ret != 0)
        {
            AddLog("ECS_PCHK NG Response Timeout");
            return 258;
        }

        string glassLog = GetGlassDataString(EcsGlassDataArray[channel]);
        AddLog(glassLog);

        if (InlineGib)
        {
            if (EcsGlassDataArray[channel].GlassJudge != 71) // 'G' = 71
            {
                AddLog("GIB ECS_PCHK NG");
                return 1;
            }
            AddLog("GIB ECS_PCHK OK");
            return 0;
        }

        if (nValue != 0)
        {
            AddLog($"ECS_PCHK NG {nValue}");
            return nValue;
        }
        AddLog("ECS_PCHK OK");
        return 0;
    }

    // =========================================================================
    // ECS_EICR
    // Delphi origin: line 1843
    // =========================================================================

    /// <inheritdoc />
    public int EcsEicr(int channel, string lcmId, string errorCode, string inspResult)
    {
        if (!Connected) return 1;

        AddLog($"ECS_EICR Ch={channel}, LCM_ID={lcmId}, Result:{inspResult}, ErrorCode={errorCode}");

        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x8:X3}", 0); // ACK Off first
        WriteString($"W{StartAddrEqpW + 0x10 * 0x16 + 0x0:X3}", lcmId.PadRight(24));
        WriteString($"W{StartAddrEqpW + 0x10 * 0x17 + 0x0:X3}", errorCode.PadRight(80));

        int inspResultInt = 0;
        int.TryParse(inspResult, out inspResultInt);
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x19 + 0xF:X3}", inspResultInt);

        AddLog("Inspection Data Report");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x4:X3}", 1); // Report On

        int ret = WaitSignal($"B{StartAddrEcs + 0x10 * 0x02 + 0x1:X3}", 1, EcsTimeout);
        if (ret != 0)
        {
            AddLog("ECS_EICR NG - Inspection Data Confirm Timeout");
            return 258;
        }

        ReadDevice($"W{StartAddrEcsW + 0x10 * 0x05 + 0xF:X3}", out int lpData);
        AddLog("Inspection Data Confirm ACK");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x4:X3}", 0); // Report Off

        if (lpData != 0)
        {
            AddLog($"ECS_EICR NG {lpData}");
            return lpData;
        }
        AddLog("ECS_EICR OK");
        return 0;
    }

    // =========================================================================
    // ECS_APDR
    // Delphi origin: line 1944
    // =========================================================================

    /// <inheritdoc />
    public int EcsApdr(int channel, string inspectionResult)
    {
        if (!Connected) return 1;

        AddLog($"ECS_APDR Ch={channel}, Result:{inspectionResult}");

        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x06 + 0x0:X3}", 1); // CEID = 1

        if (UseSimulator)
            WriteString($"W{0x500 + StartAddrEqpW + 0x10 * 0x01 + 0x0:X3}", inspectionResult.PadRight(100));
        else
            WriteString($"W{0x10000 + StartAddrEqpW + 0x10 * 0x01 + 0x0:X3}", inspectionResult.PadRight(556));

        WriteDevice($"B{StartAddrEqp + 0x10 * 0x02 + 0x1:X3}", 1); // Glass APD Report

        int ret = WaitSignal($"B{StartAddrEcs + 0x10 * 0x00 + 0x1:X3}", 1, 3000);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x02 + 0x1:X3}", 0); // Off

        if (ret != 0)
        {
            AddLog("ECS_APDR NG - Inspection Data Confirm Timeout");
            return 258;
        }
        return 0;
    }

    // =========================================================================
    // ECS_ZSET
    // Delphi origin: line 1996
    // =========================================================================

    /// <inheritdoc />
    public int EcsZset(int channel, int bondingType, string zigId, string pid, string pcbId, out int resultData)
    {
        resultData = 0;
        if (!Connected) return 1;

        AddLog($"ECS_ZSET ZigID={zigId}, PID={pid}, PcbID={pcbId}");

        WriteString($"W{StartAddrEqpW + 0x10 * 0x10 + 0x0 + channel * 0x50:X3}", zigId);
        WriteString($"W{StartAddrEqpW + 0x10 * 0x11 + 0x0 + channel * 0x50:X3}", pid);
        WriteString($"W{StartAddrEqpW + 0x10 * 0x12 + 0xC + channel * 0x50:X3}", pcbId);

        int bondVal = bondingType == 0 ? 0x41 : 0x44;
        WriteDevice($"W{StartAddrEqpW + 0x10 * 0x13 + 0xF + channel * 0x50:X3}", bondVal);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x07 + 0xA:X3}", 1); // Bonding Report

        int ret = WaitSignal($"B{StartAddrEcs + 0x10 * 0x02 + 0x0 + channel:X3}", 1, CommPlcConst.EcsTimeout);
        if (ret != 0) return 258;

        ReadDevice($"W{StartAddrEcsW + 0x10 * 0x0A + 0xD + channel * 0x180:X3}", out resultData);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x07 + 0xA:X3}", 0); // Off

        return resultData;
    }

    // =========================================================================
    // ECS_DEFECT_CODE
    // =========================================================================

    /// <inheritdoc />
    public int EcsDefectCode(string pid, string glsCode, string glsJudge, string code, string comment, out string value)
    {
        value = string.Empty;
        if (!Connected) return 1;

        AddLog($"ECS_DEFECT_CODE PID={pid}, Code={code}");

        WriteString($"W{StartAddrEqpW + 0x10 * 0x10 + 0x0:X3}", pid.PadRight(16));
        WriteString($"W{StartAddrEqpW + 0x10 * 0x10 + 0x8:X3}", glsCode.PadRight(16));
        WriteString($"W{StartAddrEqpW + 0x10 * 0x11 + 0x0:X3}", glsJudge.PadRight(16));
        WriteString($"W{StartAddrEqpW + 0x10 * 0x11 + 0x8:X3}", code.PadRight(16));
        WriteString($"W{StartAddrEqpW + 0x10 * 0x12 + 0x0:X3}", comment.PadRight(16));

        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x2:X3}", 1);

        int nIndex = (EqpId + 10) % 16;
        int ret = WaitSignal($"B{StartAddrEcs + 0xA6 + EqpId - 1:X3}", 1, 3000);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x06 + 0x2:X3}", 0);

        if (ret != 0) return 258;

        value = ReadString($"W{StartAddrEcsW + 0x10 * 0x10 + 0x0:X3}", 0, 32);
        return 0;
    }

    // =========================================================================
    // ECS_TakeOutReport
    // =========================================================================

    /// <inheritdoc />
    public int EcsTakeOutReport(int channel, string panelId)
    {
        if (!Connected) return 1;

        AddLog($"ECS_TakeOutReport Ch={channel}, PanelID={panelId}");

        int nIndex = (EqpId + 13) % 16;
        var block = new int[16];
        ConvertStrToPlc(panelId.PadRight(16), 16, block);

        if (InlineGib)
        {
            int ecsAddr = (EqpId + 10) % 16;
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x03 + 0x0:X3}", 8, block);
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 1);
            int ret = WaitSignal($"B{StartAddrEcs + 0x100 + ecsAddr:X3}", 1, CommPlcConst.EcsTimeout);
            if (ret != 0)
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 0);
                Thread.Sleep(1000);
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 1);
                ret = WaitSignal($"B{StartAddrEcs + 0x100 + ecsAddr:X3}", 1, CommPlcConst.EcsTimeout);
                if (ret != 0)
                {
                    WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 0);
                    AddLog("ECS_TakeOutReport T3 TIME OUT");
                    return 258;
                }
            }
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 0);
        }
        else
        {
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x09 + 0x0:X3}", 8, block);
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 1);
            int ret = WaitSignal($"B{StartAddrEcs + 0x100 + nIndex:X3}", 1, CommPlcConst.EcsTimeout);
            if (ret != 0)
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 0);
                Thread.Sleep(1000);
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 1);
                ret = WaitSignal($"B{StartAddrEcs + 0x100 + nIndex:X3}", 1, CommPlcConst.EcsTimeout);
                if (ret != 0)
                {
                    WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 0);
                    AddLog("ECS_TakeOutReport T3 TIME OUT");
                    return 258;
                }
            }
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x01 + 0x6:X3}", 0);
        }
        return 0;
    }

    // =========================================================================
    // ECS_Status_Mode / ECS_Stage_Position
    // =========================================================================

    /// <inheritdoc />
    public int EcsStatusMode(int mode, int value)
    {
        if (!Connected) return 1;
        AddLog($"ECS_Status_Mode Mode={mode}, Value={value}");

        switch (mode)
        {
            case 1: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x1:X3}", value); break;
            case 2: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x2:X3}", value); break;
            case 3: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x3:X3}", value); break;
            case 4: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x4:X3}", value); break;
            case 5: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x5:X3}", value); break;
            case 6: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x6:X3}", value); break;
            case 7: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x7:X3}", value); break;
            case 8: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x8:X3}", value); break;
            case 9: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x9:X3}", value); break;
            case 10: WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0xA:X3}", value); break;
        }
        return 0;
    }

    /// <inheritdoc />
    public int EcsStagePosition(int stage)
    {
        if (!Connected) return 1;
        AddLog($"ECS_Stage_Position Stage={stage}");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x04 + 0x6:X3}", (stage >> 0) & 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x04 + 0x7:X3}", (stage >> 1) & 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x04 + 0x8:X3}", (stage >> 2) & 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x04 + 0x9:X3}", (stage >> 3) & 1);
        return 0;
    }
}
