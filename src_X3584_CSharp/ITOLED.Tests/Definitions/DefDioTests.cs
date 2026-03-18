// =============================================================================
// DefDioTests.cs — Verify DIO definition constants match Delphi originals
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.Definitions;

public class DefDioTests
{
    [Fact]
    public void DioConfig_IoCountsForOcInspector()
    {
        Assert.Equal(96, DioConfig.MaxIoCnt);
        Assert.Equal(96, DioConfig.MaxInCnt);
        Assert.Equal(96, DioConfig.MaxOutCnt);
    }

    [Fact]
    public void DioConfig_DeviceConnectionDefaults()
    {
        Assert.Equal("192.168.0.99", DioConfig.DaeIoDeviceIp);
        Assert.Equal(6989, DioConfig.DaeIoDevicePort);
        Assert.Equal(200, DioConfig.DaeIoDeviceInterval);
        Assert.Equal(12, DioConfig.DaeIoDeviceCount);
    }

    [Fact]
    public void InspectorType_Values()
    {
        Assert.Equal(0, InspectorType.TypeNormal);
        Assert.Equal(1, InspectorType.TypeGib);
    }

    [Fact]
    public void ChannelSelect_Values()
    {
        Assert.Equal(0, ChannelSelect.AllCh);
        Assert.Equal(1, ChannelSelect.TopCh);
        Assert.Equal(2, ChannelSelect.BottomCh);
    }

    [Fact]
    public void DioInput_FanSignals_StartAtZero()
    {
        Assert.Equal(0, DioInput.Fan1Exhaust);
    }
}
