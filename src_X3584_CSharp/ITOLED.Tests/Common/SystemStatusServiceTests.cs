// =============================================================================
// SystemStatusServiceTests.cs — Tests for thread-safe SystemStatusService
// =============================================================================

using Dongaeltek.ITOLED.Core.Common;

namespace ITOLED.Tests.Common;

public class SystemStatusServiceTests : IDisposable
{
    private readonly SystemStatusService _svc = new();

    public void Dispose() => _svc.Dispose();

    // ── Scalar flag defaults ───────────────────────────────────

    [Fact]
    public void AllFlags_DefaultToFalse()
    {
        Assert.False(_svc.AutoMode);
        Assert.False(_svc.IsLoggedIn);
        Assert.False(_svc.IsClosing);
        Assert.False(_svc.IsLoading);
        Assert.False(_svc.AlarmOn);
        Assert.False(_svc.RobotDoorOpened);
        Assert.False(_svc.IsLastProduct);
        Assert.False(_svc.IsStageTurning);
        Assert.False(_svc.AabMode);
        Assert.False(_svc.AutoRepeatTest);
    }

    // ── Scalar flag get/set ────────────────────────────────────

    [Fact]
    public void AutoMode_SetAndGet()
    {
        _svc.AutoMode = true;
        Assert.True(_svc.AutoMode);
        _svc.AutoMode = false;
        Assert.False(_svc.AutoMode);
    }

    [Fact]
    public void IsClosing_SetAndGet()
    {
        _svc.IsClosing = true;
        Assert.True(_svc.IsClosing);
    }

    [Fact]
    public void IsLoggedIn_SetAndGet()
    {
        _svc.IsLoggedIn = true;
        Assert.True(_svc.IsLoggedIn);
    }

    // ── Channel enabled ────────────────────────────────────────

    [Fact]
    public void ChannelEnabled_DefaultFalse()
    {
        for (int i = 0; i < 4; i++)
            Assert.False(_svc.GetChannelEnabled(i));
    }

    [Fact]
    public void ChannelEnabled_SetAndGet()
    {
        _svc.SetChannelEnabled(2, true);
        Assert.True(_svc.GetChannelEnabled(2));
        Assert.False(_svc.GetChannelEnabled(0));
        Assert.False(_svc.GetChannelEnabled(1));
        Assert.False(_svc.GetChannelEnabled(3));
    }

    [Fact]
    public void ChannelEnabled_OutOfRange_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetChannelEnabled(-1));
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetChannelEnabled(4));
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.SetChannelEnabled(4, true));
    }

    // ── Stage step ─────────────────────────────────────────────

    [Fact]
    public void StageStep_DefaultZero()
    {
        for (int i = 0; i < 3; i++)
            Assert.Equal(0, _svc.GetStageStep(i));
    }

    [Fact]
    public void StageStep_SetAndGet()
    {
        _svc.SetStageStep(1, 5);
        Assert.Equal(5, _svc.GetStageStep(1));
        Assert.Equal(0, _svc.GetStageStep(0));
    }

    [Fact]
    public void StageStep_OutOfRange_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetStageStep(-1));
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetStageStep(3));
    }

    // ── Alarm data ─────────────────────────────────────────────

    [Fact]
    public void AlarmData_DefaultZero()
    {
        Assert.Equal(0, _svc.GetAlarmData(0));
        Assert.Equal(0, _svc.GetAlarmData(150));
    }

    [Fact]
    public void AlarmData_SetAndGet()
    {
        _svc.SetAlarmData(50, 0xAB);
        Assert.Equal(0xAB, _svc.GetAlarmData(50));
    }

    [Fact]
    public void AlarmData_OutOfRange_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetAlarmData(151));
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetAlarmData(-1));
    }

    // ── Alarm messages ─────────────────────────────────────────

    [Fact]
    public void AlarmMessage_DefaultEmpty()
    {
        Assert.Equal("", _svc.GetAlarmMessage(0));
        Assert.Equal("", _svc.GetAlarmMessage(150));
    }

    [Fact]
    public void AlarmMessage_SetAndGet()
    {
        _svc.SetAlarmMessage(10, "Emergency Stop");
        Assert.Equal("Emergency Stop", _svc.GetAlarmMessage(10));
    }

    [Fact]
    public void AlarmMessage_NullBecomesEmpty()
    {
        _svc.SetAlarmMessage(5, null!);
        Assert.Equal("", _svc.GetAlarmMessage(5));
    }

    [Fact]
    public void AlarmMessage_OutOfRange_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetAlarmMessage(151));
    }

    // ── LoadUnloadFlowData ─────────────────────────────────────

    [Fact]
    public void LoadUnloadFlowData_DefaultZero()
    {
        Assert.Equal(0, _svc.GetLoadUnloadFlowData(0, 0));
        Assert.Equal(0, _svc.GetLoadUnloadFlowData(0, 50));
    }

    [Fact]
    public void LoadUnloadFlowData_SetAndGet()
    {
        _svc.SetLoadUnloadFlowData(1, 25, 999);
        Assert.Equal(999, _svc.GetLoadUnloadFlowData(1, 25));
    }

    [Fact]
    public void LoadUnloadFlowData_OutOfRange_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetLoadUnloadFlowData(-1, 0));
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetLoadUnloadFlowData(0, 51));
        Assert.Throws<ArgumentOutOfRangeException>(() => _svc.GetLoadUnloadFlowData(0, -1));
    }

    // ── ClearAlarms ────────────────────────────────────────────

    [Fact]
    public void ClearAlarms_ResetsAlarmState()
    {
        _svc.AlarmOn = true;
        _svc.SetAlarmData(5, 42);
        _svc.SetAlarmMessage(5, "Test alarm");

        _svc.ClearAlarms();

        Assert.False(_svc.AlarmOn);
        Assert.Equal(0, _svc.GetAlarmData(5));
        Assert.Equal("", _svc.GetAlarmMessage(5));
    }

    // ── Reset ──────────────────────────────────────────────────

    [Fact]
    public void Reset_ClearsAllState()
    {
        // Set various state
        _svc.AutoMode = true;
        _svc.IsLoggedIn = true;
        _svc.IsClosing = true;
        _svc.IsLoading = true;
        _svc.AlarmOn = true;
        _svc.RobotDoorOpened = true;
        _svc.IsLastProduct = true;
        _svc.IsStageTurning = true;
        _svc.AabMode = true;
        _svc.AutoRepeatTest = true;
        _svc.SetChannelEnabled(0, true);
        _svc.SetStageStep(0, 3);
        _svc.SetAlarmData(0, 1);
        _svc.SetAlarmMessage(0, "alarm");
        _svc.SetLoadUnloadFlowData(0, 0, 7);

        _svc.Reset();

        // All flags should be false
        Assert.False(_svc.AutoMode);
        Assert.False(_svc.IsLoggedIn);
        Assert.False(_svc.IsClosing);
        Assert.False(_svc.IsLoading);
        Assert.False(_svc.AlarmOn);
        Assert.False(_svc.RobotDoorOpened);
        Assert.False(_svc.IsLastProduct);
        Assert.False(_svc.IsStageTurning);
        Assert.False(_svc.AabMode);
        Assert.False(_svc.AutoRepeatTest);

        // Arrays should be cleared
        Assert.False(_svc.GetChannelEnabled(0));
        Assert.Equal(0, _svc.GetStageStep(0));
        Assert.Equal(0, _svc.GetAlarmData(0));
        Assert.Equal("", _svc.GetAlarmMessage(0));
        Assert.Equal(0, _svc.GetLoadUnloadFlowData(0, 0));
    }

    // ── Thread safety ──────────────────────────────────────────

    [Fact]
    public async Task ConcurrentReadWrite_NoDeadlock()
    {
        var tasks = new List<Task>();

        for (int i = 0; i < 10; i++)
        {
            tasks.Add(Task.Run(() =>
            {
                for (int j = 0; j < 100; j++)
                {
                    _svc.AutoMode = true;
                    _ = _svc.AutoMode;
                    _svc.SetAlarmData(0, (byte)(j % 256));
                    _ = _svc.GetAlarmData(0);
                    _svc.SetAlarmMessage(0, $"msg{j}");
                    _ = _svc.GetAlarmMessage(0);
                }
            }));
        }

        await Task.WhenAll(tasks);
        Assert.True(true); // No deadlock or exception
    }

    // ── Dispose ────────────────────────────────────────────────

    [Fact]
    public void Dispose_ThenAccess_Throws()
    {
        var svc2 = new SystemStatusService();
        svc2.Dispose();

        // After Dispose, the internal lock is disposed — access should throw
        Assert.ThrowsAny<Exception>(() => _ = svc2.AutoMode);
    }
}
