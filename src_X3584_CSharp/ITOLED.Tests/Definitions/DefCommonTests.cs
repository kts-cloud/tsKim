// =============================================================================
// DefCommonTests.cs — Verify key constant values match Delphi originals
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.Definitions;

public class DefCommonTests
{
    // ── ProgramInfo ──────────────────────────────────────────
    [Fact]
    public void ProgramInfo_Constants_MatchDelphi()
    {
        Assert.Equal("R1.00", ProgramInfo.ProgramVersion);
        Assert.Equal("Inspector OLED Display OC", ProgramInfo.ProgramName);
        Assert.Equal("SCAN BCR", ProgramInfo.MsgScanBcr);
    }

    // ── TibServer ────────────────────────────────────────────
    [Fact]
    public void TibServer_Constants_MatchDelphi()
    {
        Assert.Equal(0, TibServer.Mes);
        Assert.Equal(1, TibServer.Eas);
        Assert.Equal(2, TibServer.R2R);
        Assert.Equal(2, TibServer.Max); // TIBServer_MAX = TIBServer_EAS + 1 = 2
    }

    // ── ChannelConstants ─────────────────────────────────────
    [Fact]
    public void ChannelConstants_Values_MatchDelphi()
    {
        Assert.Equal(4, ChannelConstants.PgCount);
        Assert.Equal(0, ChannelConstants.OcType);
        Assert.Equal(1, ChannelConstants.PreOcType);
        Assert.Equal(4, ChannelConstants.MaxPgCount);
        Assert.Equal(0, ChannelConstants.ChTop);
        Assert.Equal(1, ChannelConstants.ChBottom);
        Assert.Equal(2, ChannelConstants.ChAll);
        Assert.Equal(0, ChannelConstants.JigA);
        Assert.Equal(0, ChannelConstants.JigB);
        Assert.Equal(1, ChannelConstants.MaxJigCount);
    }

    [Fact]
    public void ChannelConstants_ChannelIndices_ZeroBased()
    {
        Assert.Equal(0, ChannelConstants.Ch1);
        Assert.Equal(1, ChannelConstants.Ch2);
        Assert.Equal(2, ChannelConstants.Ch3);
        Assert.Equal(3, ChannelConstants.Ch4);
        Assert.Equal(3, ChannelConstants.MaxCh); // MAX_CH = 3 (0-indexed, so 4 channels)
        Assert.Equal(3, ChannelConstants.MaxJigCh);
    }

    [Fact]
    public void ChannelConstants_StageChannels_CorrectOffset()
    {
        Assert.Equal(8, ChannelConstants.ChStageA);
        Assert.Equal(9, ChannelConstants.ChStageB);
        Assert.Equal(10, ChannelConstants.ChTopGroup);
        Assert.Equal(11, ChannelConstants.ChBottomGroup);
        Assert.Equal(12, ChannelConstants.ChAllGroup);
    }

    // ── CsvConstants ─────────────────────────────────────────
    [Fact]
    public void CsvConstants_MatchDelphi()
    {
        Assert.Equal(3, CsvConstants.MaxCsvHeaderRows);
        Assert.Equal(4, CsvConstants.MaxCsvDataRow);
    }

    // ── CaConstants ──────────────────────────────────────────
    [Fact]
    public void CaConstants_MatchDelphi()
    {
        Assert.Equal(10, CaConstants.MaxCaDriveCount);
        Assert.Equal(4, CaConstants.MaxCa310CalItem); // White, R, G, B
    }

    // ── LimitConstants ───────────────────────────────────────
    [Fact]
    public void LimitConstants_MaxPreviousResult_MatchDelphi()
    {
        Assert.Equal(2, LimitConstants.MaxPreviousResult);
    }
}
