using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Core.Common;

/// <summary>
/// Thread-safe implementation of <see cref="ISystemStatusService"/>.
/// Replaces Delphi's <c>Common.StatusInfo : TStatusInfo</c> record.
/// <para>
/// All property access is synchronized via a <see cref="ReaderWriterLockSlim"/>
/// to prevent torn reads when UI threads read flags that background threads update.
/// </para>
/// </summary>
public sealed class SystemStatusService : ISystemStatusService, IDisposable
{
    private readonly ReaderWriterLockSlim _lock = new(LockRecursionPolicy.NoRecursion);

    // ── Scalar flags ────────────────────────────────────────────────
    private bool _autoMode;
    private bool _isLoggedIn;
    private bool _isClosing;
    private bool _isLoading;
    private bool _alarmOn;
    private bool _robotDoorOpened;
    private bool _isLastProduct;
    private bool _isStageTurning;
    private bool _aabMode;
    private bool _autoRepeatTest;

    // ── Array fields ────────────────────────────────────────────────
    private readonly bool[] _useChannel = new bool[4];
    private readonly int[] _stageStep = new int[3];
    private readonly byte[] _alarmData = new byte[151];
    private readonly string[] _alarmMsg = new string[151];
    private readonly int[][] _loadUnloadFlowData;

    public SystemStatusService()
    {
        // Initialize alarm messages to empty strings
        Array.Fill(_alarmMsg, string.Empty);

        // Initialize LoadUnloadFlowData: [CH1..MAX_CH][0..50]
        var channelCount = ChannelConstants.MaxCh + 1; // 0-based inclusive
        _loadUnloadFlowData = new int[channelCount][];
        for (var i = 0; i < channelCount; i++)
            _loadUnloadFlowData[i] = new int[51];
    }

    // ── Scalar property implementations ─────────────────────────────

    /// <inheritdoc />
    public bool AutoMode
    {
        get { _lock.EnterReadLock(); try { return _autoMode; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _autoMode = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool IsLoggedIn
    {
        get { _lock.EnterReadLock(); try { return _isLoggedIn; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _isLoggedIn = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool IsClosing
    {
        get { _lock.EnterReadLock(); try { return _isClosing; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _isClosing = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool IsLoading
    {
        get { _lock.EnterReadLock(); try { return _isLoading; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _isLoading = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool AlarmOn
    {
        get { _lock.EnterReadLock(); try { return _alarmOn; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _alarmOn = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool RobotDoorOpened
    {
        get { _lock.EnterReadLock(); try { return _robotDoorOpened; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _robotDoorOpened = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool IsLastProduct
    {
        get { _lock.EnterReadLock(); try { return _isLastProduct; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _isLastProduct = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool IsStageTurning
    {
        get { _lock.EnterReadLock(); try { return _isStageTurning; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _isStageTurning = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool AabMode
    {
        get { _lock.EnterReadLock(); try { return _aabMode; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _aabMode = value; } finally { _lock.ExitWriteLock(); } }
    }

    /// <inheritdoc />
    public bool AutoRepeatTest
    {
        get { _lock.EnterReadLock(); try { return _autoRepeatTest; } finally { _lock.ExitReadLock(); } }
        set { _lock.EnterWriteLock(); try { _autoRepeatTest = value; } finally { _lock.ExitWriteLock(); } }
    }

    // ── Array-backed property implementations ───────────────────────

    /// <inheritdoc />
    public bool GetChannelEnabled(int channel)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(channel);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(channel, _useChannel.Length);
        _lock.EnterReadLock();
        try { return _useChannel[channel]; }
        finally { _lock.ExitReadLock(); }
    }

    /// <inheritdoc />
    public void SetChannelEnabled(int channel, bool enabled)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(channel);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(channel, _useChannel.Length);
        _lock.EnterWriteLock();
        try { _useChannel[channel] = enabled; }
        finally { _lock.ExitWriteLock(); }
    }

    /// <inheritdoc />
    public int GetStageStep(int stageIndex)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(stageIndex);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(stageIndex, _stageStep.Length);
        _lock.EnterReadLock();
        try { return _stageStep[stageIndex]; }
        finally { _lock.ExitReadLock(); }
    }

    /// <inheritdoc />
    public void SetStageStep(int stageIndex, int step)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(stageIndex);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(stageIndex, _stageStep.Length);
        _lock.EnterWriteLock();
        try { _stageStep[stageIndex] = step; }
        finally { _lock.ExitWriteLock(); }
    }

    /// <inheritdoc />
    public byte GetAlarmData(int index)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(index);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(index, _alarmData.Length);
        _lock.EnterReadLock();
        try { return _alarmData[index]; }
        finally { _lock.ExitReadLock(); }
    }

    /// <inheritdoc />
    public void SetAlarmData(int index, byte value)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(index);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(index, _alarmData.Length);
        _lock.EnterWriteLock();
        try { _alarmData[index] = value; }
        finally { _lock.ExitWriteLock(); }
    }

    /// <inheritdoc />
    public string GetAlarmMessage(int index)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(index);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(index, _alarmMsg.Length);
        _lock.EnterReadLock();
        try { return _alarmMsg[index]; }
        finally { _lock.ExitReadLock(); }
    }

    /// <inheritdoc />
    public void SetAlarmMessage(int index, string message)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(index);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(index, _alarmMsg.Length);
        _lock.EnterWriteLock();
        try { _alarmMsg[index] = message ?? string.Empty; }
        finally { _lock.ExitWriteLock(); }
    }

    /// <inheritdoc />
    public int GetLoadUnloadFlowData(int channel, int stepIndex)
    {
        ValidateChannelAndStep(channel, stepIndex);
        _lock.EnterReadLock();
        try { return _loadUnloadFlowData[channel][stepIndex]; }
        finally { _lock.ExitReadLock(); }
    }

    /// <inheritdoc />
    public void SetLoadUnloadFlowData(int channel, int stepIndex, int value)
    {
        ValidateChannelAndStep(channel, stepIndex);
        _lock.EnterWriteLock();
        try { _loadUnloadFlowData[channel][stepIndex] = value; }
        finally { _lock.ExitWriteLock(); }
    }

    // ── Bulk operations ─────────────────────────────────────────────

    /// <inheritdoc />
    public void ClearAlarms()
    {
        _lock.EnterWriteLock();
        try
        {
            _alarmOn = false;
            Array.Clear(_alarmData);
            Array.Fill(_alarmMsg, string.Empty);
        }
        finally { _lock.ExitWriteLock(); }
    }

    /// <inheritdoc />
    public void Reset()
    {
        _lock.EnterWriteLock();
        try
        {
            _autoMode = false;
            _isLoggedIn = false;
            _isClosing = false;
            _isLoading = false;
            _alarmOn = false;
            _robotDoorOpened = false;
            _isLastProduct = false;
            _isStageTurning = false;
            _aabMode = false;
            _autoRepeatTest = false;

            Array.Clear(_useChannel);
            Array.Clear(_stageStep);
            Array.Clear(_alarmData);
            Array.Fill(_alarmMsg, string.Empty);

            foreach (var arr in _loadUnloadFlowData)
                Array.Clear(arr);
        }
        finally { _lock.ExitWriteLock(); }
    }

    // ── Helpers ─────────────────────────────────────────────────────

    private void ValidateChannelAndStep(int channel, int stepIndex)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(channel);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(channel, _loadUnloadFlowData.Length);
        ArgumentOutOfRangeException.ThrowIfNegative(stepIndex);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(stepIndex, 51);
    }

    public void Dispose()
    {
        _lock.Dispose();
    }
}
