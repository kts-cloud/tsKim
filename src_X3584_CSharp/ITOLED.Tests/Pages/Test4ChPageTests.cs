// =============================================================================
// Test4ChPageTests.cs — Unit tests for Test4ChPage logic.
// Tests tact time formatting, result buffer management, log buffer management,
// and DIO signal mapping correctness.
// Self-contained: no OC project reference needed (avoids Blazor/WinForms deps).
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.Pages;

public class Test4ChPageTests
{
    // =========================================================================
    // FormatTactTime — MMM:SS format (mirrors Test4ChPage.FormatTactTime)
    // =========================================================================

    private static string FormatTactTime(int totalSeconds)
    {
        int min = totalSeconds / 60;
        int sec = totalSeconds % 60;
        return $"{min:D3}:{sec:D2}";
    }

    private static string FormatUnitTactTime(int totalSeconds)
    {
        int min = totalSeconds / 60;
        int sec = totalSeconds % 60;
        return $"{min:D2}:{sec:D2}";
    }

    [Theory]
    [InlineData(0, "000:00")]
    [InlineData(1, "000:01")]
    [InlineData(59, "000:59")]
    [InlineData(60, "001:00")]
    [InlineData(61, "001:01")]
    [InlineData(3599, "059:59")]
    [InlineData(3600, "060:00")]
    [InlineData(59999, "999:59")]
    public void FormatTactTime_VariousValues_CorrectFormat(int seconds, string expected)
    {
        Assert.Equal(expected, FormatTactTime(seconds));
    }

    [Theory]
    [InlineData(0, "00:00")]
    [InlineData(1, "00:01")]
    [InlineData(59, "00:59")]
    [InlineData(60, "01:00")]
    [InlineData(599, "09:59")]
    [InlineData(3599, "59:59")]
    public void FormatUnitTactTime_VariousValues_CorrectFormat(int seconds, string expected)
    {
        Assert.Equal(expected, FormatUnitTactTime(seconds));
    }

    // =========================================================================
    // Previous Results Buffer — Trim Logic
    // =========================================================================

    [Fact]
    public void PrevResults_AddAndTrim_KeepsMaxCount()
    {
        var prevResults = new List<(int NgCode, bool IsPass)>();
        int maxPrev = 5;

        for (int i = 0; i < 7; i++)
        {
            prevResults.Insert(0, (i, i % 2 == 0));
            while (prevResults.Count > maxPrev)
                prevResults.RemoveAt(prevResults.Count - 1);
        }

        Assert.Equal(maxPrev, prevResults.Count);
        Assert.Equal(6, prevResults[0].NgCode);
        Assert.Equal(5, prevResults[1].NgCode);
        Assert.Equal(2, prevResults[^1].NgCode);
    }

    [Fact]
    public void PrevResults_PassAndNgTracked()
    {
        var prevResults = new List<(int NgCode, bool IsPass)>();

        prevResults.Insert(0, (0, true));    // PASS
        prevResults.Insert(0, (101, false)); // NG
        prevResults.Insert(0, (0, true));    // PASS

        Assert.Equal(3, prevResults.Count);
        Assert.True(prevResults[0].IsPass);
        Assert.False(prevResults[1].IsPass);
        Assert.True(prevResults[2].IsPass);
    }

    // =========================================================================
    // Log Buffer — Max Entries Trim
    // =========================================================================

    [Fact]
    public void LogEntries_ExceedMax_OldestRemoved()
    {
        var logEntries = new List<string>();
        int maxLog = 200;

        for (int i = 0; i < 210; i++)
        {
            logEntries.Add($"[00:00:00] Log {i}");
            while (logEntries.Count > maxLog)
                logEntries.RemoveAt(0);
        }

        Assert.Equal(maxLog, logEntries.Count);
        Assert.Contains("Log 10", logEntries[0]);
        Assert.Contains("Log 209", logEntries[^1]);
    }

    [Fact]
    public void LogEntries_UnderMax_AllRetained()
    {
        var logEntries = new List<string>();
        int maxLog = 200;

        for (int i = 0; i < 50; i++)
        {
            logEntries.Add($"[00:00:00] Log {i}");
            while (logEntries.Count > maxLog)
                logEntries.RemoveAt(0);
        }

        Assert.Equal(50, logEntries.Count);
        Assert.Contains("Log 0", logEntries[0]);
        Assert.Contains("Log 49", logEntries[^1]);
    }

    // =========================================================================
    // Count Logic — Display Result
    // =========================================================================

    [Fact]
    public void DisplayResult_Ok_IncreasesOkCount()
    {
        int okCount = 0, ngCount = 0;
        int ngCode = 0; // PASS

        if (ngCode == 0) okCount++;
        else ngCount++;

        Assert.Equal(1, okCount);
        Assert.Equal(0, ngCount);
        Assert.Equal(1, okCount + ngCount);
    }

    [Fact]
    public void DisplayResult_Ng_IncreasesNgCount()
    {
        int okCount = 0, ngCount = 0;
        int ngCode = 101;

        if (ngCode == 0) okCount++;
        else ngCount++;

        Assert.Equal(0, okCount);
        Assert.Equal(1, ngCount);
    }

    [Fact]
    public void DisplayResult_MixedResults_CorrectCounts()
    {
        int okCount = 0, ngCount = 0;
        int[] codes = [0, 0, 101, 0, 202, 303, 0];

        foreach (var code in codes)
        {
            if (code == 0) okCount++;
            else ngCount++;
        }

        Assert.Equal(4, okCount);
        Assert.Equal(3, ngCount);
        Assert.Equal(7, okCount + ngCount);
    }

    // =========================================================================
    // DIO Signal Mapping — Verify correct signal indices per channel
    // =========================================================================

    [Theory]
    [InlineData(0, 33, 34, 35, 36)] // CH1
    [InlineData(1, 49, 50, 51, 52)] // CH2
    [InlineData(2, 65, 66, 67, 68)] // CH3
    [InlineData(3, 81, 82, 83, 84)] // CH4
    public void DiProbeSignals_CorrectPerChannel(int ch, int fwd, int bwd, int up, int dn)
    {
        int[][] diProbeSignals =
        [
            [DioInput.Ch1ProbeForwardSensor, DioInput.Ch1ProbeBackwardSensor, DioInput.Ch1ProbeUpSensor, DioInput.Ch1ProbeDownSensor],
            [DioInput.Ch2ProbeForwardSensor, DioInput.Ch2ProbeBackwardSensor, DioInput.Ch2ProbeUpSensor, DioInput.Ch2ProbeDownSensor],
            [DioInput.Ch3ProbeForwardSensor, DioInput.Ch3ProbeBackwardSensor, DioInput.Ch3ProbeUpSensor, DioInput.Ch3ProbeDownSensor],
            [DioInput.Ch4ProbeForwardSensor, DioInput.Ch4ProbeBackwardSensor, DioInput.Ch4ProbeUpSensor, DioInput.Ch4ProbeDownSensor],
        ];

        Assert.Equal(fwd, diProbeSignals[ch][0]);
        Assert.Equal(bwd, diProbeSignals[ch][1]);
        Assert.Equal(up, diProbeSignals[ch][2]);
        Assert.Equal(dn, diProbeSignals[ch][3]);
    }

    [Theory]
    [InlineData(0, 32, 33, 34, 35)] // CH1
    [InlineData(1, 48, 49, 50, 51)] // CH2
    [InlineData(2, 64, 65, 66, 67)] // CH3
    [InlineData(3, 80, 81, 82, 83)] // CH4
    public void DoProbeSignals_CorrectPerChannel(int ch, int fwd, int bwd, int up, int dn)
    {
        int[][] doProbeSignals =
        [
            [DioOutput.Ch1ProbeForwardSol, DioOutput.Ch1ProbeBackwardSol, DioOutput.Ch1ProbeUpSol, DioOutput.Ch1ProbeDownSol],
            [DioOutput.Ch2ProbeForwardSol, DioOutput.Ch2ProbeBackwardSol, DioOutput.Ch2ProbeUpSol, DioOutput.Ch2ProbeDownSol],
            [DioOutput.Ch3ProbeForwardSol, DioOutput.Ch3ProbeBackwardSol, DioOutput.Ch3ProbeUpSol, DioOutput.Ch3ProbeDownSol],
            [DioOutput.Ch4ProbeForwardSol, DioOutput.Ch4ProbeBackwardSol, DioOutput.Ch4ProbeUpSol, DioOutput.Ch4ProbeDownSol],
        ];

        Assert.Equal(fwd, doProbeSignals[ch][0]);
        Assert.Equal(bwd, doProbeSignals[ch][1]);
        Assert.Equal(up, doProbeSignals[ch][2]);
        Assert.Equal(dn, doProbeSignals[ch][3]);
    }

    [Theory]
    [InlineData(0, 32)] // CH1 carrier sensor
    [InlineData(1, 48)] // CH2
    [InlineData(2, 64)] // CH3
    [InlineData(3, 80)] // CH4
    public void DiCarrierSensor_CorrectPerChannel(int ch, int expected)
    {
        int[] diCarrierSensor =
            [DioInput.Ch1CarrierSensor, DioInput.Ch2CarrierSensor, DioInput.Ch3CarrierSensor, DioInput.Ch4CarrierSensor];

        Assert.Equal(expected, diCarrierSensor[ch]);
    }

    [Theory]
    [InlineData(0, 36, 37)] // CH1 carrier unlock/lock solenoid
    [InlineData(1, 52, 53)] // CH2
    [InlineData(2, 68, 69)] // CH3
    [InlineData(3, 84, 85)] // CH4
    public void DoCarrierSolenoids_CorrectPerChannel(int ch, int unlockSol, int lockSol)
    {
        int[] doCarrierUnlockSol =
            [DioOutput.Ch1CarrierUnlockSol, DioOutput.Ch2CarrierUnlockSol, DioOutput.Ch3CarrierUnlockSol, DioOutput.Ch4CarrierUnlockSol];
        int[] doCarrierLockSol =
            [DioOutput.Ch1CarrierLockSol, DioOutput.Ch2CarrierLockSol, DioOutput.Ch3CarrierLockSol, DioOutput.Ch4CarrierLockSol];

        Assert.Equal(unlockSol, doCarrierUnlockSol[ch]);
        Assert.Equal(lockSol, doCarrierLockSol[ch]);
    }

    // =========================================================================
    // DIO Signal Spacing — 16 offset between channels
    // =========================================================================

    [Fact]
    public void DiProbeSignals_16Offset_BetweenChannels()
    {
        Assert.Equal(16, DioInput.Ch2ProbeForwardSensor - DioInput.Ch1ProbeForwardSensor);
        Assert.Equal(16, DioInput.Ch3ProbeForwardSensor - DioInput.Ch2ProbeForwardSensor);
        Assert.Equal(16, DioInput.Ch4ProbeForwardSensor - DioInput.Ch3ProbeForwardSensor);
    }

    [Fact]
    public void DoProbeSignals_16Offset_BetweenChannels()
    {
        Assert.Equal(16, DioOutput.Ch2ProbeForwardSol - DioOutput.Ch1ProbeForwardSol);
        Assert.Equal(16, DioOutput.Ch3ProbeForwardSol - DioOutput.Ch2ProbeForwardSol);
        Assert.Equal(16, DioOutput.Ch4ProbeForwardSol - DioOutput.Ch3ProbeForwardSol);
    }
}
