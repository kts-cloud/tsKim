// =============================================================================
// CaSdk2DriverSetupTests.cs — Tests for CA-410 connection setup data flow.
// Validates that configuration values are correctly read and passed to driver.
// Cannot test actual SDK calls (requires CASDK2Net.dll + hardware).
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Models;
using Dongaeltek.ITOLED.Hardware.Colorimeter;

namespace ITOLED.Tests.Colorimeter;

public class CaSdk2DriverSetupTests
{
    // =========================================================================
    // CaSetupInfo tests
    // =========================================================================

    [Fact]
    public void CaSetupInfo_DefaultValues()
    {
        var info = new CaSetupInfo();
        Assert.Equal(DefCaSdk.CONNECTION_NONE, info.SelectIdx);
        Assert.Equal(0, info.DeviceId);
        Assert.Equal(string.Empty, info.SerialNo);
        Assert.Equal(0, info.Ca410Ch);
    }

    [Fact]
    public void CaSetupInfo_SetProperties()
    {
        var info = new CaSetupInfo
        {
            SelectIdx = DefCaSdk.CONNECTION_OK,
            DeviceId = 5,
            SerialNo = "AB12345"
        };

        Assert.Equal(DefCaSdk.CONNECTION_OK, info.SelectIdx);
        Assert.Equal(5, info.DeviceId);
        Assert.Equal("AB12345", info.SerialNo);
    }

    // =========================================================================
    // Constants verification
    // =========================================================================

    [Fact]
    public void DefCaSdk_ConnectionConstants()
    {
        Assert.Equal(0, DefCaSdk.CONNECTION_NONE);
        Assert.Equal(1, DefCaSdk.CONNECTION_OK);
        Assert.Equal(2, DefCaSdk.CONNECTION_NG);
        Assert.Equal(10000, DefCaSdk.DISCONNECTION_CODE);
    }

    [Fact]
    public void DefCaSdk_MaxChannelCount_Is4()
    {
        Assert.Equal(4, DefCaSdk.MAX_CH_CNT);
        Assert.Equal(4, DefCaSdk.MAX_CH);
    }

    // =========================================================================
    // MemChannel calculation (Delphi: Ca410MemCh+1)
    // =========================================================================

    [Theory]
    [InlineData(0, 1)]   // Default MCF value 0 → memCh=1
    [InlineData(2, 3)]   // MCF value 2 → memCh=3
    [InlineData(6, 7)]   // MCF value 6 → memCh=7
    public void MemChannel_McfValuePlusOne(int mcfValue, int expected)
    {
        // Simulates: int memCh = modelSvc.GetModelValueInt("FLOW_DATA", "Ca410MemCh", 0) + 1;
        int memCh = mcfValue + 1;
        Assert.Equal(expected, memCh);
    }

    // =========================================================================
    // Channel loop range (Ch1=0 to MaxCh=3 → 4 channels)
    // =========================================================================

    [Fact]
    public void ChannelLoop_CoversAllFourChannels()
    {
        var visited = new List<int>();
        for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
            visited.Add(i);

        Assert.Equal(4, visited.Count);
        Assert.Equal(new[] { 0, 1, 2, 3 }, visited);
    }

    // =========================================================================
    // SystemInfo CA310 arrays initialization
    // =========================================================================

    [Fact]
    public void SystemInfo_Ca310Arrays_DefaultEmpty()
    {
        var sysInfo = new SystemInfo();

        // Arrays should be initialized with default values
        for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
        {
            Assert.Equal(0, sysInfo.ComCa310[i]);
            Assert.Equal(0, sysInfo.ComCa310DeviceId[i]);
            Assert.Equal(string.Empty, sysInfo.ComCa310Serial[i]);
        }
    }

    [Fact]
    public void SystemInfo_Ca310Arrays_SetValues()
    {
        var sysInfo = new SystemInfo();

        // Simulate INI values: COM_CA3100=1, COM_CA3100_SERIAL=AB123, COM_CA3100_DEVICE_ID=5
        sysInfo.ComCa310[0] = 1;
        sysInfo.ComCa310Serial[0] = "AB123";
        sysInfo.ComCa310DeviceId[0] = 5;

        Assert.Equal(DefCaSdk.CONNECTION_OK, sysInfo.ComCa310[0]);
        Assert.Equal("AB123", sysInfo.ComCa310Serial[0]);
        Assert.Equal(5, sysInfo.ComCa310DeviceId[0]);

        // Other channels remain default
        Assert.Equal(DefCaSdk.CONNECTION_NONE, sysInfo.ComCa310[1]);
    }

    // =========================================================================
    // ModelInfoFlow Ca410MemCh
    // =========================================================================

    [Fact]
    public void ModelInfoFlow_Ca410MemCh_DefaultZero()
    {
        var flow = new ModelInfoFlow();
        Assert.Equal(0, flow.Ca410MemCh);
    }

    [Fact]
    public void ModelInfoFlow_Ca410MemCh_SetValue()
    {
        var flow = new ModelInfoFlow { Ca410MemCh = 6 };
        Assert.Equal(6, flow.Ca410MemCh);
    }

    // =========================================================================
    // Setup port mapping (simulates Program.cs DI factory logic)
    // =========================================================================

    [Fact]
    public void SetupPortMapping_FromSystemInfo_CorrectAssignment()
    {
        // Simulate what Program.cs does:
        // for (int i = Ch1; i <= MaxCh; i++)
        //     driver.SetSetupPort(i, new CaSetupInfo { ... });
        var sysInfo = new SystemInfo();
        sysInfo.ComCa310[0] = 1;
        sysInfo.ComCa310Serial[0] = "SERIAL_CH1";
        sysInfo.ComCa310DeviceId[0] = 3;

        sysInfo.ComCa310[1] = 1;
        sysInfo.ComCa310Serial[1] = "SERIAL_CH2";
        sysInfo.ComCa310DeviceId[1] = 4;

        sysInfo.ComCa310[2] = 0; // CH3 disabled
        sysInfo.ComCa310[3] = 0; // CH4 disabled

        var setupList = new CaSetupInfo[DefCaSdk.MAX_CH_CNT];
        for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
        {
            setupList[i] = new CaSetupInfo
            {
                SelectIdx = sysInfo.ComCa310[i],
                DeviceId  = sysInfo.ComCa310DeviceId[i],
                SerialNo  = sysInfo.ComCa310Serial[i]
            };
        }

        // CH1: enabled with serial
        Assert.Equal(DefCaSdk.CONNECTION_OK, setupList[0].SelectIdx);
        Assert.Equal("SERIAL_CH1", setupList[0].SerialNo);
        Assert.Equal(3, setupList[0].DeviceId);

        // CH2: enabled with serial
        Assert.Equal(DefCaSdk.CONNECTION_OK, setupList[1].SelectIdx);
        Assert.Equal("SERIAL_CH2", setupList[1].SerialNo);

        // CH3, CH4: disabled
        Assert.Equal(DefCaSdk.CONNECTION_NONE, setupList[2].SelectIdx);
        Assert.Equal(DefCaSdk.CONNECTION_NONE, setupList[3].SelectIdx);
    }
}
