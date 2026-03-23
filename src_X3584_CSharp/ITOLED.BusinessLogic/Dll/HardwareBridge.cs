// =============================================================================
// HardwareBridge.cs
// Extends X2146_API (from LGD_OC_AstractPlatForm) by delegating all abstract
// hardware operations to ICommPgDriver. This replaces the callback-based
// approach used by OC_Converter_X3584.dll.
//
// Replaces DllManager callback methods:
//   OnCbAllPowerOnOff, OnCbTconSetReg, OnCbTconGetReg, OnCbTconSetRegArray,
//   OnCbTconGetRegArray, OnCbTconMultiSetReg, OnCbTconSeqSetReg,
//   OnCbFlashWriteData, OnCbFlashReadData, OnCbFlashErase
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using LGD_OC_AstractPlatForm.NY_IT.CommonAPI;
using LGD_OC_AstractPlatForm.NY_IT.ModelAPI;

namespace Dongaeltek.ITOLED.BusinessLogic.Dll;

/// <summary>
/// Concrete X2146_API that bridges Factory DLL hardware calls to
/// <see cref="ICommPgDriver"/>.
/// </summary>
public class HardwareBridge : X2146_API
{
    private const int DeviceAddress = 0xA0;
    private const int WaitObject0 = 0;

    private readonly ICommPgDriver _pg;
    private readonly Action<int, string>? _logCallback;
    private readonly int _channel;

    public HardwareBridge(
        System.Windows.Forms.RichTextBox rtb,
        IMeasurement measurement,
        ICommPgDriver pg,
        int channel,
        Action<int, string>? logCallback = null)
        : base(rtb, measurement)
    {
        _pg = pg;
        _channel = channel;
        _logCallback = logCallback;
    }

    public override void TCONSetReg(int addr, byte data)
    {
        var buf = new byte[] { data };
        int nResult = 1;
        for (int i = 0; i <= 2; i++)
        {
            int debugLog = (i == 2) ? 1 : 0;
            nResult = (int)_pg.SendI2CWrite(DeviceAddress, addr, 1, buf, 1000, 0, debugLog);
            if (nResult == WaitObject0) return;
        }
        _logCallback?.Invoke(_channel, $"TCONSetReg NG CH : {_channel}");
    }

    public override byte TCONGetReg(int addr)
    {
        var buf = new byte[1];
        int nResult = 1;
        for (int i = 0; i <= 2; i++)
        {
            nResult = (int)_pg.SendI2CRead(DeviceAddress, addr, 1, buf, 500, 0, 1);
            if (nResult == WaitObject0) return buf[0];
        }
        _logCallback?.Invoke(_channel, $"TCONGetReg NG CH : {_channel}");
        return 0;
    }

    public override void FlashWrite_File(int StartSeg, int EndSeg, string filePath)
    {
        // Not used — file-based flash operations are unused in current OC flow
    }

    public override void FlashWrite_Data(int StartSeg, int EndSeg, byte[] data)
    {
        // X2146_API는 segment 단위(0x1000=4096), SendFlashWrite는 byte 주소
        uint addr = (uint)StartSeg * 0x1000;
        int length = data.Length;
        _logCallback?.Invoke(_channel, $"[LGD_DLL→FlashWrite_Data] StartSeg=0x{StartSeg:X} → Addr=0x{addr:X} Len={length}");
        int nResult = (int)_pg.SendFlashWrite(addr, (uint)length, data);
        if (nResult != WaitObject0)
        {
            nResult = (int)_pg.SendFlashWrite(addr, (uint)length, data);
            if (nResult != WaitObject0)
                _logCallback?.Invoke(_channel, $"FlashWrite_Data NG CH : {_channel}");
        }
    }

    public override void FlashRead_File(int StartSeg, int EndSeg, string filePath)
    {
        _logCallback?.Invoke(_channel, $"[LGD_DLL→FlashRead_File] StartSeg=0x{StartSeg:X} EndSeg=0x{EndSeg:X} path={filePath}");
    }

    public override void FlashRead_Data(int StartSeg, int EndSeg, ref byte[] data)
    {
        // X2146_API는 segment 단위(0x1000=4096), Delphi 콜백은 byte 주소 단위
        // StartSeg × 0x1000 = byte address (예: 0x7F6 × 0x1000 = 0x7F6000)
        uint addr = (uint)StartSeg * 0x1000;
        int length = data.Length;
        var buf = new byte[length];
        int nResult = (int)_pg.SendFlashRead(addr, (uint)length, buf, 5000, 1, false, false);
        if (nResult != WaitObject0)
            _logCallback?.Invoke(_channel, $"FlashRead_Data NG CH : {_channel}");
        Array.Copy(buf, data, length);
    }

    public override void FlashErase(int StartSeg, int EndSeg)
    {
        // X2146_API는 segment 단위(0x1000=4096)
        uint addr = (uint)StartSeg * 0x1000;
        int length = EndSeg;
        _logCallback?.Invoke(_channel, $"[LGD_DLL→FlashErase] StartSeg=0x{StartSeg:X} → Addr=0x{addr:X} Len={length}");
        var command = $"{Dp860Commands.CmdStrNvmErase} 0x{addr:x} {length}";
        int waitMs = (((length / (PgFlashConstants.FlashEraseKbPerSecDefault * 1024)) + 1) * 1000)
                     + PgFlashConstants.FlashEraseWaitMsMinimum;
        _pg.Dp860SendCmd(command, Dp860Commands.CmdIdNvmErase, Dp860Commands.CmdStrNvmErase, waitMs, 0);
    }

    public override void PowerOnOff(bool OnOff)
    {
        int mode = OnOff ? 1 : 0;
        _pg.SendPowerBistOn(mode, true, 3000, 0);
        if (OnOff)
            _pg.SendPowerMeasure(true);
        Thread.Sleep(500);
    }

    public override void TCONSetRegArray(int addr, byte[] data, int num)
    {
        int nResult = (int)_pg.SendI2CWrite(DeviceAddress, addr, num, data, 1000, 0);
        if (nResult != WaitObject0)
        {
            nResult = (int)_pg.SendI2CWrite(DeviceAddress, addr, num, data, 1000, 0);
            if (nResult != WaitObject0)
                _logCallback?.Invoke(_channel, $"TCONSetRegArray NG CH : {_channel}");
        }
    }

    public override byte[] TCONGetRegArray(int addr, int num)
    {
        var buf = new byte[num];
        int nResult = 1;
        for (int i = 0; i <= 2; i++)
        {
            nResult = (int)_pg.SendI2CRead(DeviceAddress, addr, num, buf, 100, 0);
            if (nResult == WaitObject0) return buf;
        }
        _logCallback?.Invoke(_channel, $"TCONGetRegArray NG CH : {_channel}");
        return buf;
    }

    public override void Delay_Time(int time)
    {
        Thread.Sleep(time);
    }
}
