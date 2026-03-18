// =============================================================================
// CommLogger.cs
// Communication/measurement logger with per-channel buffering and periodic save.
// Replaces Delphi's TLogCommon from CommLog.pas.
//
// Architecture:
//   - Per-channel in-memory buffers (List<string>) with CriticalSection
//   - Background thread periodically flushes to date-based log files
//   - High-resolution timing using Stopwatch for inter-log time deltas
//   - Daily file rolling with AM/PM split
//
// Namespace: Dongaeltek.ITOLED.Core.Logging
// =============================================================================

using System.Diagnostics;
using System.Text;

namespace Dongaeltek.ITOLED.Core.Logging;

/// <summary>
/// Communication logger that accumulates log entries in memory and
/// periodically flushes them to date-based text files.
/// Direct C# port of Delphi's TLogCommon from CommLog.pas.
/// <para>
/// Key differences from <see cref="ChannelLogger"/>:
/// <list type="bullet">
///   <item>Uses in-memory List&lt;string&gt; instead of ring buffers</item>
///   <item>Includes inter-message time delta in each log line</item>
///   <item>Files split by AM/PM within each day</item>
///   <item>System-channel (last index) uses a different filename prefix</item>
/// </list>
/// </para>
/// </summary>
public sealed class CommLogger : IDisposable
{
    // ── Constants ────────────────────────────────────────────────────────
    private const int DefaultAccumulateCount = 30;    // Save after 30 entries
    private const int DefaultAccumulateSeconds = 10;  // Or after 10 seconds

    // ── Per-channel state ────────────────────────────────────────────────
    private readonly List<string>[] _logs;
    private readonly object[] _locks;
    private readonly DateTime[] _saveTime;
    private readonly DateTime[] _baseLogTime;
    private readonly long[] _baseCounter;

    // ── Configuration ────────────────────────────────────────────────────
    private readonly int _maxChannel;        // Highest channel index (system channel)
    private readonly string _logPath;
    private readonly string _eqpId;
    private readonly int _accumulateCount;
    private readonly int _accumulateSeconds;

    // ── Thread control ───────────────────────────────────────────────────
    private readonly CancellationTokenSource _cts;
    private readonly Task _cycleTask;
    private bool _disposed;

    /// <summary>
    /// Prefix for system-channel log files (channel index = MaxChannel).
    /// Default: "SystemLog_"
    /// </summary>
    public string SystemLogPrefix { get; set; } = "SystemLog_";

    /// <summary>
    /// Prefix for per-channel log files.
    /// Default: "MLog_"
    /// </summary>
    public string LogPrefix { get; set; } = "MLog_";

    // ── Constructor ──────────────────────────────────────────────────────

    /// <summary>
    /// Creates a new CommLogger instance.
    /// </summary>
    /// <param name="maxSystemLog">
    /// Maximum channel index. Channel indices 0..(maxSystemLog-1) are per-channel logs.
    /// Channel index maxSystemLog is the system-wide log channel.
    /// </param>
    /// <param name="logPath">Base directory for log files.</param>
    /// <param name="eqpId">Equipment ID string used in filenames.</param>
    public CommLogger(int maxSystemLog, string logPath, string eqpId)
    {
        _maxChannel = maxSystemLog;
        _logPath = logPath;
        _eqpId = eqpId;
        _accumulateCount = DefaultAccumulateCount;
        _accumulateSeconds = DefaultAccumulateSeconds;

        var channelCount = _maxChannel + 1;
        _logs = new List<string>[channelCount];
        _locks = new object[channelCount];
        _saveTime = new DateTime[channelCount];
        _baseLogTime = new DateTime[channelCount];
        _baseCounter = new long[channelCount];

        for (var i = 0; i < channelCount; i++)
        {
            _logs[i] = new List<string>();
            _locks[i] = new object();
            _saveTime[i] = DateTime.MinValue;
            _baseLogTime[i] = DateTime.Now;
            _baseCounter[i] = Stopwatch.GetTimestamp();
        }

        _cts = new CancellationTokenSource();
        _cycleTask = Task.Run(() => ProcessCycle(_cts.Token));
    }

    // ── Public API ───────────────────────────────────────────────────────

    /// <summary>
    /// Logs a message to the specified channel with high-resolution timestamp and delta.
    /// </summary>
    /// <param name="channel">Channel index (0-based). Clamped to MaxChannel if out of range.</param>
    /// <param name="message">Log message text.</param>
    /// <param name="saveNow">If true, forces immediate flush to disk.</param>
    public void MLog(int channel, string message, bool saveNow = false)
    {
        if (_disposed) return;

        if (channel < 0 || channel > _maxChannel)
            channel = _maxChannel;

        var counter = Stopwatch.GetTimestamp();
        var freq = (double)Stopwatch.Frequency;

        // Compute elapsed microseconds from base time
        var elapsedMicros = (long)(((counter - _baseCounter[channel]) * 1_000_000L) / freq);
        var elapsedSeconds = (int)(elapsedMicros / 1_000_000L);
        var micros = elapsedMicros % 1_000_000L;
        var dtNow = _baseLogTime[channel].AddSeconds(elapsedSeconds);

        lock (_locks[channel])
        {
            try
            {
                // Day change → save previous day's logs
                if (_logs[channel].Count > 0 &&
                    _saveTime[channel] != DateTime.MinValue &&
                    _saveTime[channel].Day != dtNow.Day)
                {
                    SaveMLog(channel, _saveTime[channel]);
                }

                // Build and add log entry
                if (!(saveNow && string.IsNullOrEmpty(message)))
                {
                    var logEntry = $"{dtNow:HH:mm:ss}.{micros:D6} =>{message}";
                    _logs[channel].Add(logEntry);
                }

                // Flush conditions
                if (saveNow ||
                    _logs[channel].Count > _accumulateCount ||
                    (_saveTime[channel] != DateTime.MinValue &&
                     (dtNow - _saveTime[channel]).TotalSeconds > _accumulateSeconds))
                {
                    SaveMLog(channel, dtNow);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"CommLogger.MLog error: {ex.Message}");
            }
        }
    }

    /// <summary>
    /// Gets the accumulated log entries for a channel (read-only snapshot).
    /// </summary>
    public IReadOnlyList<string> GetLogs(int channel)
    {
        if (channel < 0 || channel > _maxChannel)
            channel = _maxChannel;

        lock (_locks[channel])
        {
            return _logs[channel].ToList().AsReadOnly();
        }
    }

    // ── Background Cycle ─────────────────────────────────────────────────

    private async Task ProcessCycle(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(1000, ct);

                var dtNow = DateTime.Now;
                for (var ch = 0; ch <= _maxChannel; ch++)
                {
                    if (_logs[ch].Count > 0)
                    {
                        lock (_locks[ch])
                        {
                            if (_saveTime[ch] != DateTime.MinValue &&
                                _saveTime[ch].Day != dtNow.Day)
                            {
                                SaveMLog(ch, _saveTime[ch]);
                            }
                            else if (_logs[ch].Count > _accumulateCount ||
                                     (_saveTime[ch] != DateTime.MinValue &&
                                      (dtNow - _saveTime[ch]).TotalSeconds > _accumulateSeconds))
                            {
                                SaveMLog(ch, dtNow);
                            }
                        }
                    }
                }
            }
            catch (OperationCanceledException) { break; }
            catch { /* swallow background errors */ }
        }

        // Final flush
        var finalTime = DateTime.Now;
        for (var ch = 0; ch <= _maxChannel; ch++)
        {
            lock (_locks[ch])
            {
                SaveMLog(ch, finalTime);
            }
        }
    }

    // ── File Save ────────────────────────────────────────────────────────

    /// <summary>
    /// Saves accumulated log entries to a date-based file.
    /// Must be called within the channel's lock.
    /// </summary>
    private void SaveMLog(int channel, DateTime saveDate)
    {
        if (_logs[channel].Count == 0) return;

        var dateStr = saveDate.ToString("yyyyMMdd");
        var filePath = Path.Combine(_logPath, dateStr);

        if (!Directory.Exists(filePath))
            Directory.CreateDirectory(filePath);

        // AM/PM split - matches Delphi FormatDateTime('yyyymmdd_AM/PM', ...)
        var ampm = saveDate.Hour < 12 ? "AM" : "PM";
        var fileDate = $"{dateStr}_{ampm}";

        string fileName;
        if (channel == _maxChannel)
        {
            // System channel: SystemLog_EQPID_yyyyMMdd_AM.txt
            fileName = Path.Combine(filePath,
                $"{SystemLogPrefix}{_eqpId}_{fileDate}.txt");
        }
        else
        {
            // Per-channel: MLog_EQPID_yyyyMMdd_AM_Ch1.txt
            fileName = Path.Combine(filePath,
                $"{LogPrefix}{_eqpId}_{fileDate}_Ch{channel + 1}.txt");
        }

        try
        {
            using var writer = new StreamWriter(fileName, append: true, Encoding.UTF8);
            var content = string.Join(Environment.NewLine, _logs[channel]);
            writer.WriteLine(content.TrimEnd());

            _logs[channel].Clear();
            _saveTime[channel] = DateTime.Now;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(
                $"CommLogger.SaveMLog error: {ex.Message} ch={channel}");
        }
    }

    // ── IDisposable ──────────────────────────────────────────────────────

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        _cts.Cancel();
        try { _cycleTask.Wait(TimeSpan.FromSeconds(5)); }
        catch { /* timeout or cancellation */ }

        _cts.Dispose();
    }
}
