// =============================================================================
// PlcEcsDriver.RobotEqp.cs  (partial)
// Robot interlock + EQP control methods.
// Converted from Delphi: CommPLC_ECS.pas lines 2038-2600
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Hardware.Plc;

public sealed partial class PlcEcsDriver
{
    // =========================================================================
    // Helper: Get load/unload bit offsets based on InlineGIB + OCType
    // =========================================================================

    /// <summary>
    /// Returns (loadBase, unloadBase) hex offsets for EQP bit addressing.
    /// InlineGIB+OC: $08/$09, InlineGIB+PreOC: $10/$11, non-GIB OC: $0C/$0D, non-GIB PreOC: $12/$13
    /// </summary>
    private (int loadBase, int unloadBase) GetLoadUnloadBases()
    {
        if (InlineGib)
            return IsOcType ? (0x08, 0x09) : (0x10, 0x11);
        else
            return IsOcType ? (0x0C, 0x0D) : (0x12, 0x13);
    }

    /// <summary>
    /// Returns (loadBaseW, unloadBaseW) hex offsets for EQP word addressing.
    /// InlineGIB+OC/non-GIB OC: $10, InlineGIB+PreOC/non-GIB PreOC: $20
    /// </summary>
    private int GetGlassDataWordBase()
    {
        if (IsPreOcType && InlineGib) return 0x20;
        return 0x10;
    }

    // =========================================================================
    // EQP_Clear_ECS_Area
    // Delphi origin: line 2038
    // =========================================================================

    /// <inheritdoc />
    public int EqpClearEcsArea()
    {
        if (!Connected) return 1;

        AddLog("EQP_Clear_ECS_Area");
        var (lb, ub) = GetLoadUnloadBases();

        for (int nCh = 0; nCh <= ChannelConstants.MaxCh; nCh++)
        {
            int chOff = nCh * 0x20;
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 0); // Unload Enable off
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x1 + chOff:X3}", 0); // Glass Data Report off
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x5 + chOff:X3}", 0); // Unload Request off
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x6 + chOff:X3}", 0); // Unload Complete Confirm off
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 0); // Load Enable Off
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x1 + chOff:X3}", 0); // Glass Data Request off
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x5 + chOff:X3}", 0); // Load Request Off
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x6 + chOff:X3}", 0); // Load Complete Confirm Off

            // PreOC+GIB also clears Vacuum
            if (InlineGib && IsPreOcType)
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0xA + chOff:X3}", 0); // Load Vacuum OFF
                WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0xA + chOff:X3}", 0); // Unload Vacuum OFF
            }
        }
        return 0;
    }

    // =========================================================================
    // EQP_Clear_ROBOT_Request (IPlcService.ClearRobotRequest)
    // Delphi origin: line 2110
    // =========================================================================

    /// <inheritdoc />
    public void ClearRobotRequest(int index)
    {
        EqpClearRobotRequest(index);
    }

    private int EqpClearRobotRequest(int nCh)
    {
        if (!Connected) return 1;

        AddLog($"EQP_Clear_ROBOT_Request: {nCh}");
        var (lb, ub) = GetLoadUnloadBases();
        int chOff = nCh * 0x20;

        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x1 + chOff:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x5 + chOff:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x6 + chOff:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x1 + chOff:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x5 + chOff:X3}", 0);
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x6 + chOff:X3}", 0);

        if (InlineGib && IsPreOcType)
        {
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0xA + chOff:X3}", 0);
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0xA + chOff:X3}", 0);
        }

        RequestStateLoad[nCh] = 0;
        RequestStateUnload[nCh] = 0;
        return 0;
    }

    // =========================================================================
    // EQP_Door_Open_Warning / EQP_Door_Open_Info
    // =========================================================================

    /// <inheritdoc />
    public bool EqpDoorOpenWarning()
    {
        AddLog("Process_EQP_Door_Open_Warning 1");

        WriteDevice($"B{StartAddrEqp + 0x10 * 0x05 + 0x0:X3}", 1);
        int ret = WaitSignal($"B{StartAddrRobotDoorBit + 0x10 * 0x00 + 0x2:X3}", 1, 3000);
        if (ret != 0)
        {
            AddLog("Door Open Warning Confirm ON Timeout");
            WriteDevice($"B{StartAddrEqp + 0x10 * 0x05 + 0x0:X3}", 0);
            return false;
        }

        WriteDevice($"B{StartAddrEqp + 0x10 * 0x05 + 0x0:X3}", 0);
        ret = WaitSignal($"B{StartAddrRobotDoorBit + 0x10 * 0x00 + 0x2:X3}", 0, 3000);
        if (ret != 0)
        {
            AddLog("Door Open Warning Confirm OFF Timeout");
            return false;
        }
        return true;
    }

    /// <inheritdoc />
    public void EqpDoorOpenInfo(int value)
    {
        if (!Connected) return;
        AddLog($"EQP_Door_Open_Info {value}");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x05 + 0x2:X3}", value);
    }

    // =========================================================================
    // EQP_SkipCh / EQP_UnloadBeforeCh
    // =========================================================================

    /// <inheritdoc />
    public int EqpSkipChannel(int jig, int channel, int skip)
    {
        if (!Connected) return 1;
        AddLog($"EQP_SKIP_CH: Jig={jig} Ch={channel} SKIP={skip}");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x04 + 0x08 + channel:X3}", skip);
        return 0;
    }

    /// <inheritdoc />
    public int EqpUnloadBeforeChannel(int jig, int channel, int onOff)
    {
        if (!Connected) return 1;

        AddLog($"EQP_UNLOAD_CH: Jig={jig} Ch={channel + 1} OnOff={onOff}");
        int tempCh = channel % 2;

        if (IsPreOcType)
        {
            if (_config.SystemInfo.CHReversal)
            {
                int bit = tempCh == 0 ? 0x0B : 0x0A;
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x13 + jig * 0x20 + bit:X3}", onOff);
            }
            else
            {
                WriteDevice($"B{StartAddrEqp + 0x10 * 0x13 + jig * 0x20 + 0x0A + tempCh:X3}", onOff);
            }
        }
        return 0;
    }

    // =========================================================================
    // ITC_AllChNormalStatusOnOff
    // Delphi origin: line 5270
    // =========================================================================

    /// <inheritdoc />
    public int ItcAllChNormalStatusOnOff(int onOff)
    {
        if (!Connected) return 1;

        var (lb, ub) = GetLoadUnloadBases();
        for (int nCh = 0; nCh <= ChannelConstants.MaxCh; nCh++)
        {
            int chOff = nCh * 0x20;
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x4 + chOff:X3}", onOff); // Unload Normal Status
            WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x4 + chOff:X3}", onOff); // Load Normal Status
            Thread.Sleep(100);
        }
        return 0;
    }

    // =========================================================================
    // ROBOT_Exchange_Request
    // Delphi origin: line 2466
    // =========================================================================

    /// <inheritdoc />
    public int RobotExchangeRequest(int channel)
    {
        if (!Connected) return 1;

        AddLog($"ROBOT_Exchange_Request: {channel}");
        var (lb, ub) = GetLoadUnloadBases();
        int chOff = channel * 0x20;
        int wordBase = GetGlassDataWordBase();

        if (InlineGib && IsPreOcType)
            ProcessRobotVacuum(channel, 1);

        // Set Normal Status
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x4 + chOff:X3}", 1); // Unload Normal Status
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeUnload11, 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x4 + chOff:X3}", 1); // Load Normal Status
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeLoad11, 1);
        Thread.Sleep(50);

        // Write Glass Data
        var block = new int[65];
        ConvertGlassDataToBlock(GlassData[channel], block);

        if (!InlineGib && IsPreOcType)
        {
            int wordOffset = _config.SystemInfo.CHReversal ? channel * 0x80 : channel * 0x40;
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * wordBase + 0x0 + wordOffset:X3}", 64, block);
        }
        else
        {
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * wordBase + 0x0 + channel * 0x40:X3}", 64, block);
        }

        Thread.Sleep(50);
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeUnload1, 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x1 + chOff:X3}", 1); // Unload Glass Data Report
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeUnload2, 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x5 + chOff:X3}", 1); // Unload Request
        Thread.Sleep(100);
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x1 + chOff:X3}", 1); // Load Glass Data Request

        RequestStateUnload[channel] = 1;
        RequestStateLoad[channel] = 1;

        int ret = WaitSignal($"B{StartAddrRobot + 0x10 * 0x00 + 0x1 + chOff:X3}", 1, 5000);
        if (ret != 0)
        {
            _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeUnload3, 1);
            WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x0 + chOff:X3}", 1); // Unload Enable
        }
        return 0;
    }

    // =========================================================================
    // ROBOT_Load_Request
    // Delphi origin: line 2576
    // =========================================================================

    /// <inheritdoc />
    public int RobotLoadRequest(int channel)
    {
        if (!Connected) return 1;

        AddLog($"ROBOT_Load_Request: {channel}");
        var (lb, ub) = GetLoadUnloadBases();
        int chOff = channel * 0x20;

        // Set Normal Status
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x4 + chOff:X3}", 1); // Load Normal Status
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeLoad11, 1);
        Thread.Sleep(50);

        // Clear old signals
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x0 + chOff:X3}", 0); // Load Enable Off
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x5 + chOff:X3}", 0); // Load Request Off
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x6 + chOff:X3}", 0); // Load Complete Confirm Off

        // Glass Data Request
        WriteDevice($"B{StartAddrEqp + 0x10 * lb + 0x1 + chOff:X3}", 1);
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeLoad1, 1);
        RequestStateLoad[channel] = 1;

        return 0;
    }

    // =========================================================================
    // ROBOT_Unload_Request
    // Delphi origin: line 2640
    // =========================================================================

    /// <inheritdoc />
    public int RobotUnloadRequest(int channel)
    {
        if (!Connected) return 1;

        AddLog($"ROBOT_Unload_Request: {channel}");
        var (lb, ub) = GetLoadUnloadBases();
        int chOff = channel * 0x20;
        int wordBase = GetGlassDataWordBase();

        if (InlineGib && IsPreOcType)
            ProcessRobotVacuum(channel, 1);

        // Set Normal Status
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x4 + chOff:X3}", 1);
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeUnload11, 1);
        Thread.Sleep(50);

        // Write Glass Data
        var block = new int[65];
        ConvertGlassDataToBlock(GlassData[channel], block);

        if (!InlineGib && IsPreOcType)
        {
            int wordOffset = _config.SystemInfo.CHReversal ? channel * 0x80 : channel * 0x40;
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * wordBase + 0x0 + wordOffset:X3}", 64, block);
        }
        else
        {
            WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * wordBase + 0x0 + channel * 0x40:X3}", 64, block);
        }

        Thread.Sleep(50);
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeUnload1, 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x1 + chOff:X3}", 1); // Glass Data Report
        _status.SetLoadUnloadFlowData(channel, CommPlcConst.ModeUnload2, 1);
        WriteDevice($"B{StartAddrEqp + 0x10 * ub + 0x5 + chOff:X3}", 1); // Unload Request
        RequestStateUnload[channel] = 1;

        return 0;
    }

    // =========================================================================
    // ROBOT_ReadyToStart_Request
    // =========================================================================

    /// <inheritdoc />
    public int RobotReadyToStartRequest(int channel, int ready)
    {
        if (!Connected) return 1;
        AddLog($"ROBOT_ReadyToStart_Request Ch={channel}, Ready={ready}");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x0C + 0xD:X3}", ready);
        return 0;
    }

    // =========================================================================
    // ROBOT_Copy_GlassData
    // Delphi origin: line 2442
    // =========================================================================

    /// <inheritdoc />
    public int RobotCopyGlassData()
    {
        if (!Connected) return 1;

        var block = new int[65];

        ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x00 + 0x0:X3}", 64, block, out _);
        WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x10 + 0x0:X3}", 64, block);

        if (StartAddrRobotW2 == 0)
        {
            ReadDeviceBlock($"W{StartAddrRobotW + 0x10 * 0x00 + 0x0 + 0x40:X3}", 64, block, out _);
        }
        else
        {
            ReadDeviceBlock($"W{StartAddrRobotW2 + 0x10 * 0x00 + 0x0 + 0x40:X3}", 64, block, out _);
        }
        WriteDeviceBlock($"W{StartAddrEqpW + 0x10 * 0x10 + 0x0 + 0x40:X3}", 64, block);

        return 0;
    }

    // =========================================================================
    // Process_ROBOT_Vacuum (internal helper)
    // Delphi origin: line 4263
    // =========================================================================

    private void ProcessRobotVacuum(int channel, int value)
    {
        if (!InlineGib || !IsPreOcType) return;

        int chOff = channel * 0x20;
        AddLog($"Process_ROBOT_Vacuum Ch={channel}, Value={value}");
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x10 + 0xA + chOff:X3}", value); // Load Vacuum
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x11 + 0xA + chOff:X3}", value); // Unload Vacuum
    }
}
