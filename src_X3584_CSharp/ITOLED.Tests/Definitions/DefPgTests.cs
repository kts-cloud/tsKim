// =============================================================================
// DefPgTests.cs — Verify Pattern Generator definition constants
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.Definitions;

public class DefPgTests
{
    [Fact]
    public void PgType_Values_MatchDelphi()
    {
        Assert.Equal(0, PgType.Dp860);
        Assert.Equal(1, PgType.Af9);
    }

    [Fact]
    public void PgTimerDefaults_MatchDelphi()
    {
        Assert.Equal(200, PgTimerDefaults.CmdWaitAckDefault);
        Assert.Equal(2000, PgTimerDefaults.ConnCheckInterval);
        Assert.Equal(2000, PgTimerDefaults.PwrMeasureIntervalDefault);
        Assert.Equal(1000, PgTimerDefaults.PwrMeasureIntervalMin);
        Assert.Equal(1000, PgTimerDefaults.PwrMeasureWaitAckDefault);
    }

    [Fact]
    public void PgCommandParam_Values_MatchDelphi()
    {
        Assert.Equal(0, PgCommandParam.CmdIdUnknown);
        Assert.Equal("UnknownPgCommand", PgCommandParam.CmdStrUnknown);
        Assert.Equal(0, PgCommandParam.PowerOff);
        Assert.Equal(1, PgCommandParam.PowerOn);
        Assert.Equal(0, PgCommandParam.DisplayOff);
        Assert.Equal(1, PgCommandParam.DisplayOn);
    }

    [Fact]
    public void PgFlashConstants_MaxFlashSize_16MB()
    {
        Assert.Equal(16 * 1024 * 1024, PgFlashConstants.MaxFlashSizeByte);
    }
}
