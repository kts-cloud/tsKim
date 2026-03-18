// =============================================================================
// PlcEcsDriver.BitOps.cs  (partial)
// Bit operations, GlassData conversion, Save/Load, SetGlassData_*/GetGlassData_*.
// Converted from Delphi: CommPLC_ECS.pas lines 4949-5625
// =============================================================================

using System.Text;
using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Hardware.Plc;

public sealed partial class PlcEcsDriver
{
    // =========================================================================
    // Bit Operations (Delphi: Get_Bit, Set_Bit, IsBitOn variants)
    // =========================================================================

    /// <inheritdoc />
    public int GetBit(int data, int bitLoc)
    {
        return (data >> bitLoc) & 0x01;
    }

    /// <inheritdoc />
    public int SetBit(ref int data, int bitLoc, int value)
    {
        if (value == 0)
            data &= ~(1 << bitLoc);
        else
            data |= (1 << bitLoc);
        return data;
    }

    /// <inheritdoc />
    public bool IsBitOn(int data, int bitLoc)
    {
        return ((data >> bitLoc) & 0x01) == 0x01;
    }

    /// <inheritdoc />
    public bool IsBitOnByDivision(int division, int index, int bitLoc)
    {
        return division switch
        {
            0 => IsBitOn(PollingEqp[index], bitLoc),  // EQP
            1 => IsBitOn(PollingData[index], bitLoc),  // Robot
            2 => IsBitOn(PollingEcs[index], bitLoc),   // ECS
            _ => IsBitOn(PollingCv[index], bitLoc),    // CV
        };
    }

    /// <inheritdoc />
    public bool IsBitOnEcs(int index)
    {
        int div = index / 16;
        int bitLoc = index % 16;
        return IsBitOn(PollingEcs[div], bitLoc);
    }

    /// <inheritdoc />
    public bool IsBitOnEqp(int index)
    {
        int div = index / 16;
        int bitLoc = index % 16;
        return IsBitOn(PollingEqp[div], bitLoc);
    }

    /// <summary>
    /// IPlcService.IsBitOnRobot implementation.
    /// <para>Delphi origin: function IsBitOn_Robot(nIndex) (line 5108)</para>
    /// </summary>
    public bool IsBitOnRobot(int index)
    {
        int div = index / 16;
        int bitLoc = index % 16;
        return IsBitOn(PollingData[div], bitLoc);
    }

    /// <summary>
    /// IPlcService.IsBusyRobot implementation.
    /// Checks if robot is busy (load or unload) for the given group.
    /// <para>Delphi origin: function IsBusy_Robot(nCH) (line 5117)</para>
    /// </summary>
    public bool IsBusyRobot(int group)
    {
        // Bit $02 in each word pair: Load Busy / Unload Busy
        int nIndex = 0x02;
        int div = nIndex / 16;
        int bitLoc = nIndex % 16;

        // Either of the two words in the pair is busy
        return GetBit(PollingData[div + group * 2], bitLoc) == 1
            || GetBit(PollingData[div + group * 2 + 1], bitLoc) == 1;
    }

    /// <inheritdoc />
    public bool IsBusyRobotEach(int channel)
    {
        // Only checks the load busy bit for the specific channel
        int nIndex = 0x02;
        int div = nIndex / 16;
        int bitLoc = nIndex % 16;
        return GetBit(PollingData[div + channel * 2], bitLoc) == 1;
    }

    /// <inheritdoc />
    public bool IsGlassDataRobot(int channel)
    {
        int nIndex = 0xC1;
        int div = nIndex / 16;
        int bitLoc = nIndex % 16;
        return GetBit(PollingData[div + channel * 2], bitLoc) == 1
            || GetBit(PollingData[div + channel * 2 + 1], bitLoc) == 1;
    }

    /// <inheritdoc />
    public bool IsRequestRobot()
    {
        int nIndex = 0xC0;
        int div = nIndex / 16;
        int bitLoc = nIndex % 16;

        return GetBit(PollingEqp[div], bitLoc + 1) == 1
            || GetBit(PollingEqp[div], bitLoc + 4) == 1
            || GetBit(PollingEqp[div + 2], bitLoc + 1) == 1
            || GetBit(PollingEqp[div + 2], bitLoc + 4) == 1;
    }

    /// <inheritdoc />
    public bool IsLoadRequestRobot(int channel)
    {
        int nIndex;
        if (InlineGib)
            nIndex = IsOcType ? 0x80 : 0x100;
        else
            nIndex = IsOcType ? 0xC0 : 0x120;

        int div = nIndex / 16;
        int bitLoc = nIndex % 16;
        return GetBit(PollingEqp[div + channel * 2], bitLoc + 1) == 1;
    }

    /// <inheritdoc />
    public bool IsUnloadRequestRobot(int channel)
    {
        int nIndex;
        if (InlineGib)
            nIndex = IsOcType ? 0x90 : 0x110;
        else
            nIndex = IsOcType ? 0xD0 : 0x130;

        int div = nIndex / 16;
        int bitLoc = nIndex % 16;
        return GetBit(PollingEqp[div + channel * 2], bitLoc + 1) == 1;
    }

    // =========================================================================
    // GlassData Conversion: Block <-> EcsGlassData
    // (Delphi: ConvertBlockToGlassData line 4949, ConvertGlassDataToBlock line 4978)
    // =========================================================================

    /// <summary>
    /// Converts a 64-word PLC block to an EcsGlassData object.
    /// </summary>
    private void ConvertBlockToGlassData(int[] block, EcsGlassData gd)
    {
        // NOTE: ConvertStrFromPlc takes CHARACTER count (not word count).
        // Delphi ConvertStrFromPLC takes word count, so we double it for char count.
        // CarrierId: 8 words = 16 chars, ProcessingCode: 4 words = 8 chars,
        // GlassId: 8 words = 16 chars, MateriId: 15 words = 30 chars.
        gd.CarrierId = ConvertStrFromPlc(16, SubArray(block, 0, 8));
        gd.ProcessingCode = ConvertStrFromPlc(8, SubArray(block, 8, 4));

        Array.Copy(block, 12, gd.LotSpecificData, 0, 4);
        gd.RecipeNumber = block[16];
        gd.GlassType = block[17];
        gd.GlassCode = block[18];
        gd.GlassId = ConvertStrFromPlc(16, SubArray(block, 19, 8));
        gd.GlassJudge = block[27] & 0x00FF;

        Array.Copy(block, 28, gd.GlassSpecificData, 0, 4);
        Array.Copy(block, 32, gd.PreviousUnitProcessing, 0, 8);
        Array.Copy(block, 40, gd.GlassProcessingStatus, 0, 8);
        gd.MateriId = ConvertStrFromPlc(30, SubArray(block, 48, 15));
        gd.PcztCode = block[63];

        AddLog($"ConvertBlockToGlassData {GetGlassDataString(gd)}");
    }

    /// <summary>
    /// Converts an EcsGlassData object to a 64-word PLC block.
    /// </summary>
    private void ConvertGlassDataToBlock(EcsGlassData gd, int[] block)
    {
        var tmp = new int[16];

        ConvertStrToPlc(gd.CarrierId, 16, tmp);
        Array.Copy(tmp, 0, block, 0, 8);

        ConvertStrToPlc(gd.ProcessingCode, 8, tmp);
        Array.Copy(tmp, 0, block, 8, 4);

        Array.Copy(gd.LotSpecificData, 0, block, 12, 4);
        block[16] = gd.RecipeNumber;
        block[17] = gd.GlassType;
        block[18] = gd.GlassCode;

        ConvertStrToPlc(gd.GlassId, 16, tmp);
        Array.Copy(tmp, 0, block, 19, 8);

        block[27] = gd.GlassJudge;

        Array.Copy(gd.GlassSpecificData, 0, block, 28, 4);
        Array.Copy(gd.PreviousUnitProcessing, 0, block, 32, 8);
        Array.Copy(gd.GlassProcessingStatus, 0, block, 40, 8);

        var matTmp = new int[16];
        ConvertStrToPlc(gd.MateriId, 30, matTmp);
        Array.Copy(matTmp, 0, block, 48, 15);

        block[63] = gd.PcztCode;
    }

    /// <summary>Helper to extract a sub-array from a PLC block.</summary>
    private static int[] SubArray(int[] source, int offset, int length)
    {
        var result = new int[length];
        Array.Copy(source, offset, result, 0, Math.Min(length, source.Length - offset));
        return result;
    }

    // =========================================================================
    // GetGlassDataString (Delphi: line 5002)
    // =========================================================================

    /// <inheritdoc />
    public string GetGlassDataString(EcsGlassData gd)
    {
        try
        {
            var sb = new StringBuilder();
            sb.Append($"CarrierID={gd.CarrierId}, MateriID={gd.MateriId}, ProcessingCode={gd.ProcessingCode}");
            sb.Append($", LOTSpecificData={gd.LotSpecificData[0]} {gd.LotSpecificData[1]} {gd.LotSpecificData[2]} {gd.LotSpecificData[3]}");
            sb.Append($", RecipeNumber={gd.RecipeNumber}, GlassType={gd.GlassType}, GlassCode={gd.GlassCode}");
            sb.Append($", GlassID={gd.GlassId}, GlassJudge={gd.GlassJudge}");
            sb.Append($", GlassSpecificData={gd.GlassSpecificData[0]} {gd.GlassSpecificData[1]} {gd.GlassSpecificData[2]} {gd.GlassSpecificData[3]}");
            sb.Append($", PreviousUnitProcessing={string.Join(" ", gd.PreviousUnitProcessing)}");
            sb.Append($", GlassProcessingStatus={string.Join(" ", gd.GlassProcessingStatus)}");
            sb.Append($", PCZTCode={gd.PcztCode}");
            return sb.ToString();
        }
        catch
        {
            return string.Empty;
        }
    }

    // =========================================================================
    // SaveGlassData / LoadGlassData (Delphi: lines 5289-5360)
    // =========================================================================

    /// <inheritdoc />
    public void SaveGlassData(string fileName)
    {
        try
        {
            using var fs = new FileStream(fileName, FileMode.Create, FileAccess.Write);
            using var bw = new BinaryWriter(fs);
            var block = new int[65];
            for (int i = 0; i < 4; i++)
            {
                ConvertGlassDataToBlock(GlassData[i], block);
                for (int j = 0; j < 65; j++)
                    bw.Write(block[j]);
            }
        }
        catch (Exception ex)
        {
            _logger.Error("SaveGlassData exception", ex);
        }
    }

    /// <inheritdoc />
    public void SaveGlassDataChannel(int channel, string fileName)
    {
        try
        {
            AddLog($"SaveGlassData_CH {channel} : Start");
            using var fs = new FileStream(fileName, FileMode.Create, FileAccess.Write);
            using var bw = new BinaryWriter(fs);
            var block = new int[65];
            ConvertGlassDataToBlock(GlassData[channel], block);
            for (int j = 0; j < 65; j++)
                bw.Write(block[j]);
            AddLog($"SaveGlassData_CH : End");
        }
        catch (Exception ex)
        {
            _logger.Error($"SaveGlassDataChannel({channel}) exception", ex);
        }
    }

    /// <inheritdoc />
    public void LoadGlassData(string fileName)
    {
        if (!File.Exists(fileName)) return;

        try
        {
            using var fs = new FileStream(fileName, FileMode.Open, FileAccess.Read);
            using var br = new BinaryReader(fs);
            var block = new int[65];
            for (int i = 0; i < 4; i++)
            {
                for (int j = 0; j < 65; j++)
                    block[j] = br.ReadInt32();
                ConvertBlockToGlassData(block, GlassData[i]);
            }
        }
        catch (Exception ex)
        {
            _logger.Error("LoadGlassData exception", ex);
        }
    }

    /// <inheritdoc />
    public void LoadGlassDataChannel(int channel, string fileName)
    {
        if (!File.Exists(fileName)) return;

        try
        {
            using var fs = new FileStream(fileName, FileMode.Open, FileAccess.Read);
            using var br = new BinaryReader(fs);
            var block = new int[65];
            for (int j = 0; j < 65; j++)
                block[j] = br.ReadInt32();
            ConvertBlockToGlassData(block, GlassData[channel]);
        }
        catch (Exception ex)
        {
            _logger.Error($"LoadGlassDataChannel({channel}) exception", ex);
        }
    }

    // =========================================================================
    // SetGlassData_* Helpers (Delphi: lines 5375-5539)
    // =========================================================================

    /// <inheritdoc />
    public int SetGlassDataContactNg(EcsGlassData glassData, int value)
    {
        // Glass Specific Data, bit 2: Contact NG
        SetBit(ref glassData.GlassSpecificData[0], 2, value);
        return 0;
    }

    /// <inheritdoc />
    public int SetGlassDataCheckReverseLogistics(int channel, EcsGlassData glassData, int value)
    {
        // Check GlassSpecificData[1] bit 2 for reverse logistics
        if (GetBit(glassData.GlassSpecificData[1], 2) > 0)
        {
            AddLog($"CH : {channel + 1} Reverse Logistics");
            for (int i = 0; i < 8; i++)
            {
                glassData.GlassProcessingStatus[i] = 0;
                glassData.PreviousUnitProcessing[i] = 0;
            }
            SetBit(ref glassData.GlassSpecificData[1], 2, 0);
        }
        return 0;
    }

    /// <inheritdoc />
    public int SetGlassDataJudgeCode(EcsGlassData glassData, int value)
    {
        glassData.GlassJudge = value;
        return 0;
    }

    /// <inheritdoc />
    public int SetGlassDataPreviousUnitProcessing(EcsGlassData glassData, int value)
    {
        if (_config.SystemInfo.UseGIB)
        {
            glassData.PreviousUnitProcessing[0] = value;
        }
        else
        {
            if (IsOcType)
                glassData.PreviousUnitProcessing[1] = value;
            else if (IsPreOcType)
                SetBit(ref glassData.PreviousUnitProcessing[1], value * 2, 1);
        }
        return 0;
    }

    /// <inheritdoc />
    public int SetGlassDataPreviousUnitProcessingGib(EcsGlassData glassData, int eqpId, int channel, int abbCount)
    {
        int nValue = channel + 1;
        if (!RobotLoadingStatus[channel] && abbCount != 0)
            abbCount--;

        if (eqpId == 1)
        {
            SetBit(ref glassData.PreviousUnitProcessing[0], 0 + 3 * abbCount, GetBit(nValue, 0));
            SetBit(ref glassData.PreviousUnitProcessing[0], 1 + 3 * abbCount, GetBit(nValue, 1));
            SetBit(ref glassData.PreviousUnitProcessing[0], 2 + 3 * abbCount, GetBit(nValue, 2));
        }
        else
        {
            if (abbCount == 2)
            {
                SetBit(ref glassData.PreviousUnitProcessing[1], 0, GetBit(nValue, 0));
                SetBit(ref glassData.PreviousUnitProcessing[1], 1, GetBit(nValue, 1));
                SetBit(ref glassData.PreviousUnitProcessing[1], 2, GetBit(nValue, 2));
            }
            else
            {
                SetBit(ref glassData.PreviousUnitProcessing[0], 10 + 3 * abbCount, GetBit(nValue, 0));
                SetBit(ref glassData.PreviousUnitProcessing[0], 11 + 3 * abbCount, GetBit(nValue, 1));
                SetBit(ref glassData.PreviousUnitProcessing[0], 12 + 3 * abbCount, GetBit(nValue, 2));
            }
        }
        return 0;
    }

    /// <inheritdoc />
    public int SetGlassDataProcessingStatus(EcsGlassData glassData, int seq, int bitCount = 4)
    {
        int nStation;
        if (_config.SystemInfo.UseGIB)
            nStation = EqpId - 6;
        else if (IsOcType)
            nStation = EqpId - 10;
        else
            nStation = EqpId - 13;

        switch (bitCount)
        {
            case 4:
                SetBit(ref glassData.GlassProcessingStatus[seq], 5, GetBit(nStation, 0));
                SetBit(ref glassData.GlassProcessingStatus[seq], 6, GetBit(nStation, 1));
                SetBit(ref glassData.GlassProcessingStatus[seq], 7, GetBit(nStation, 2));
                SetBit(ref glassData.GlassProcessingStatus[seq], 8, GetBit(nStation, 3));
                break;

            case 5: // Pre OC
                SetBit(ref glassData.GlassProcessingStatus[seq], nStation * 2, 1);
                break;

            case 6: // OC
                SetBit(ref glassData.GlassProcessingStatus[seq], 0, GetBit(nStation, 0));
                SetBit(ref glassData.GlassProcessingStatus[seq], 1, GetBit(nStation, 1));
                SetBit(ref glassData.GlassProcessingStatus[seq], 2, GetBit(nStation, 2));
                SetBit(ref glassData.GlassProcessingStatus[seq], 3, GetBit(nStation, 3));
                SetBit(ref glassData.GlassProcessingStatus[seq], 4, GetBit(nStation, 4));
                SetBit(ref glassData.GlassProcessingStatus[seq], 5, GetBit(nStation, 5));
                break;

            case 2: // Pre OC GIB
                if (nStation == 1)
                    glassData.GlassProcessingStatus[seq] = 1;
                if (nStation == 2)
                    glassData.GlassProcessingStatus[seq] = 4;
                break;

            case 3: // Inline GIB AAB
                SetBit(ref glassData.GlassProcessingStatus[seq], 3, GetBit(nStation, 0));
                SetBit(ref glassData.GlassProcessingStatus[seq], 4, GetBit(nStation, 1));
                SetBit(ref glassData.GlassProcessingStatus[seq], 5, GetBit(nStation, 2));
                break;
        }
        return 0;
    }

    /// <inheritdoc />
    public int SetGlassDataProcessingStatusGib(EcsGlassData glassData, int eqpId, int channel, int abbCount)
    {
        int nStation = channel + 1;

        if (eqpId == 1)
        {
            SetBit(ref glassData.GlassProcessingStatus[0], 0 + 3 * abbCount, GetBit(nStation, 0));
            SetBit(ref glassData.GlassProcessingStatus[0], 1 + 3 * abbCount, GetBit(nStation, 1));
            SetBit(ref glassData.GlassProcessingStatus[0], 2 + 3 * abbCount, GetBit(nStation, 2));
        }
        else
        {
            if (abbCount == 2)
            {
                SetBit(ref glassData.GlassProcessingStatus[1], 0, GetBit(nStation, 0));
                SetBit(ref glassData.GlassProcessingStatus[1], 1, GetBit(nStation, 1));
                SetBit(ref glassData.GlassProcessingStatus[1], 2, GetBit(nStation, 2));
            }
            else
            {
                SetBit(ref glassData.GlassProcessingStatus[0], 10 + 3 * abbCount, GetBit(nStation, 0));
                SetBit(ref glassData.GlassProcessingStatus[0], 11 + 3 * abbCount, GetBit(nStation, 1));
                SetBit(ref glassData.GlassProcessingStatus[0], 12 + 3 * abbCount, GetBit(nStation, 2));
            }
        }
        return 0;
    }

    // =========================================================================
    // GetGlassData_* Helpers (Delphi: lines 5542-5626)
    // =========================================================================

    /// <inheritdoc />
    public int GetGlassDataProcessingStatus(EcsGlassData glassData, int eqpId, ref int seq, int bitCount = 4)
    {
        int nStation = 0;

        for (int i = 0; i < 8; i++)
        {
            int nValue;
            switch (bitCount)
            {
                case 4:
                    nValue = glassData.GlassProcessingStatus[i];
                    nValue = (nValue >> 5) & 0x0F;
                    if (nValue == 0) { seq = i; return 0; }
                    nStation = nValue;
                    break;

                case 16:
                    nValue = glassData.GlassProcessingStatus[0];
                    int nValue2 = glassData.GlassProcessingStatus[1];
                    if (eqpId == 1)
                    {
                        if ((nValue & 0x1C0) == 0) seq = 2;
                        if ((nValue & 0x38) == 0) seq = 1;
                        if ((nValue & 0x7) == 0) seq = 0;
                    }
                    else
                    {
                        if ((nValue2 & 0x7) == 0) seq = 2;
                        if ((nValue & 0xE000) == 0) seq = 1;
                        if ((nValue & 0x1C00) == 0) seq = 0;
                    }
                    return nValue;

                case 6:
                    nValue = glassData.GlassProcessingStatus[1] & 0x3F;
                    if (nValue == 0) { seq = i; return 0; }
                    nStation = nValue;
                    break;

                case 3:
                    nValue = glassData.GlassProcessingStatus[i];
                    nValue = (nValue >> 3) & 0x07;
                    if (nValue == 0) { seq = i; return 0; }
                    nStation = nValue;
                    break;
            }
        }
        seq = 3;
        return nStation;
    }

    /// <inheritdoc />
    public int GetGlassDataPreviousUnitProcessing(EcsGlassData glassData, int eqpId, ref int seq, int bitCount = 4)
    {
        int nValue = glassData.PreviousUnitProcessing[0];
        int nValue2 = glassData.PreviousUnitProcessing[1];

        if (eqpId == 1)
        {
            if ((nValue & 0x1C0) == 0) seq = 2;
            if ((nValue & 0x38) == 0) seq = 1;
            if ((nValue & 0x7) == 0) seq = 0;
        }
        else
        {
            if ((nValue2 & 0x7) == 0) seq = 2;
            if ((nValue & 0xE000) == 0) seq = 1;
            if ((nValue & 0x1C00) == 0) seq = 0;
        }
        return nValue;
    }
}
