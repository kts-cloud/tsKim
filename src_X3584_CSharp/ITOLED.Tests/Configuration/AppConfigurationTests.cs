// =============================================================================
// AppConfigurationTests.cs — Tests for AppConfiguration defaults and flags
// =============================================================================

using Dongaeltek.ITOLED.Core.Configuration;

namespace ITOLED.Tests.Configuration;

public class AppConfigurationTests
{
    // ── Default values ─────────────────────────────────────────

    [Fact]
    public void Default_InspectorType_IsOC()
    {
        var config = new AppConfiguration();
        Assert.Equal(InspectorType.OC, config.Inspector);
    }

    [Fact]
    public void Default_PatternGenerator_IsDP860()
    {
        var config = new AppConfiguration();
        Assert.Equal(PgType.DP860, config.PatternGenerator);
    }

    [Fact]
    public void Default_Colorimeter_IsCA410()
    {
        var config = new AppConfiguration();
        Assert.Equal(ColorimeterType.CA410, config.Colorimeter);
    }

    [Fact]
    public void Default_Af9Api_IsSingleChannel()
    {
        var config = new AppConfiguration();
        Assert.Equal(Af9ApiMode.SingleChannel, config.Af9Api);
    }

    [Fact]
    public void Default_Simulator_IsNone()
    {
        var config = new AppConfiguration();
        Assert.Equal(SimulatorFlags.None, config.Simulator);
        Assert.False(config.IsSimulator);
    }

    [Fact]
    public void Default_FeatureFlags_AreTrue()
    {
        var config = new AppConfiguration();
        Assert.True(config.FeatureGrayChange);
        Assert.True(config.FeatureFlashAccess);
        Assert.True(config.UseDfs);
        Assert.True(config.UseEas);
        Assert.True(config.DfsHex);
        Assert.True(config.DfsOffline);
    }

    [Fact]
    public void Default_HardwareFlags_AreFalse()
    {
        var config = new AppConfiguration();
        Assert.False(config.UseAdlinkDio);
        Assert.False(config.UseAxDio);
        Assert.False(config.UseTouch);
        Assert.False(config.Dio60Channel);
    }

    [Fact]
    public void Default_MaxPgCount_Is4()
    {
        var config = new AppConfiguration();
        Assert.Equal(4, config.MaxPgCount);
    }

    // ── IsSimulator ────────────────────────────────────────────

    [Theory]
    [InlineData(SimulatorFlags.None, false)]
    [InlineData(SimulatorFlags.Dio, true)]
    [InlineData(SimulatorFlags.Pg, true)]
    [InlineData(SimulatorFlags.Dio | SimulatorFlags.Pg, true)]
    [InlineData(SimulatorFlags.All, true)]
    public void IsSimulator_ReflectsFlags(SimulatorFlags flags, bool expected)
    {
        var config = new AppConfiguration { Simulator = flags };
        Assert.Equal(expected, config.IsSimulator);
    }

    // ── SimulatorFlags combinations ────────────────────────────

    [Fact]
    public void SimulatorFlags_All_IncludesAllComponents()
    {
        var all = SimulatorFlags.All;
        Assert.True(all.HasFlag(SimulatorFlags.Dio));
        Assert.True(all.HasFlag(SimulatorFlags.Pg));
        Assert.True(all.HasFlag(SimulatorFlags.Bcr));
        Assert.True(all.HasFlag(SimulatorFlags.Cax10));
        Assert.True(all.HasFlag(SimulatorFlags.Gmes));
    }

    [Fact]
    public void SimulatorFlags_Combinable()
    {
        var combined = SimulatorFlags.Dio | SimulatorFlags.Pg;
        Assert.True(combined.HasFlag(SimulatorFlags.Dio));
        Assert.True(combined.HasFlag(SimulatorFlags.Pg));
        Assert.False(combined.HasFlag(SimulatorFlags.Bcr));
    }

    // ── Enum values ────────────────────────────────────────────

    [Fact]
    public void InspectorType_HasExpectedValues()
    {
        Assert.Equal(0, (int)InspectorType.OC);
        Assert.Equal(1, (int)InspectorType.PreOC);
    }

    [Fact]
    public void PgType_HasExpectedValues()
    {
        Assert.Equal(0, (int)PgType.DP860);
        Assert.Equal(1, (int)PgType.AF9);
    }

    [Fact]
    public void ColorimeterType_HasExpectedValues()
    {
        Assert.Equal(0, (int)ColorimeterType.CA410);
        Assert.Equal(1, (int)ColorimeterType.CA310);
    }
}
