// =============================================================================
// ChannelLogger.cs
// Multi-channel file logger with background writer and log-file rolling.
// Replaces Delphi's TLogger from ControlLogger.pas.
//
// Architecture:
//   - Each channel has its own bounded Channel<LogItem> (replaces TRingBuffer<T>)
//   - A single background Task drains all channels and writes to rolling log files
//   - Per-channel locks ensure timestamp+enqueue are atomic (no ordering inversion)
//   - Daily or hourly file rolling with date-based subdirectories
//   - Batch flush: every 50 lines OR every 1 second
//
// Namespace: Dongaeltek.ITOLED.Core.Logging
// =============================================================================

using System.Diagnostics;
using System.Text;
using System.Threading.Channels;

namespace Dongaeltek.ITOLED.Core.Logging;

/// <summary>
/// Rolling option for log file segmentation.
/// </summary>
public enum RollOption
{
    /// <summary>Roll log files daily (one file per day, unless max size exceeded).</summary>
    Daily = 0,
    /// <summary>Roll log files hourly (one file per hour, unless max size exceeded).</summary>
    Hourly = 1
}

/// <summary>
/// A single log entry with a high-resolution timestamp.
/// Replaces Delphi's TLogItem record.
/// </summary>
internal readonly struct LogItem
{
    /// <summary>High-resolution timestamp (ticks from Stopwatch).</summary>
    public long TimestampTicks { get; }

    /// <summary>Wall-clock time corresponding to the timestamp.</summary>
    public DateTime WallClock { get; }

    /// <summary>The log message text.</summary>
    public string Message { get; }

    public LogItem(long timestampTicks, DateTime wallClock, string message)
    {
        TimestampTicks = timestampTicks;
        WallClock = wallClock;
        Message = message;
    }
}

/// <summary>
/// Per-channel state: ring buffer, file stream, rolling keys.
/// </summary>
internal sealed class ChannelState : IDisposable
{
    public Channel<LogItem> Buffer { get; }
    public string BaseDir { get; }
    public string BaseName { get; }

    public StreamWriter? Writer { get; set; }
    public FileStream? FileStream { get; set; }
    public string CurrentFolderKey { get; set; } = string.Empty;
    public string CurrentRollKey { get; set; } = string.Empty;
    public string CurrentLogPath { get; set; } = string.Empty;
    public int FileIndex { get; set; } = 1;
    public int FlushCount { get; set; }
    public DateTime LastFlushTime { get; set; }

    /// <summary>
    /// Per-channel lock ensuring timestamp capture + enqueue are atomic.
    /// Prevents timestamp ordering inversion across concurrent producers.
    /// </summary>
    public readonly object EnqueueLock = new();

    public ChannelState(string baseDir, string baseName, int bufferSize)
    {
        BaseDir = baseDir;
        BaseName = baseName;
        Buffer = Channel.CreateBounded<LogItem>(new BoundedChannelOptions(bufferSize)
        {
            FullMode = BoundedChannelFullMode.DropOldest,
            SingleReader = true,  // only the background writer reads
            SingleWriter = false  // multiple threads may log
        });
        LastFlushTime = DateTime.Now;
    }

    public void Dispose()
    {
        Writer?.Dispose();
        FileStream?.Dispose();
    }
}

/// <summary>
/// Multi-channel file logger with background writer thread and daily/hourly rolling.
/// Direct C# port of Delphi's TLogger from ControlLogger.pas.
/// <para>
/// Usage:
/// <code>
/// var logger = new ChannelLogger(
///     bufferSize: 4096,
///     baseFilePaths: new[] { @"C:\LOG\System", @"C:\LOG\CH0", @"C:\LOG\CH1" },
///     maxFileSize: 10 * 1024 * 1024,
///     rollOption: RollOption.Hourly);
///
/// logger.Log(0, "System initialized");
/// logger.Log(1, "CH0 inspection started");
///
/// // On shutdown:
/// logger.Dispose();
/// </code>
/// </para>
/// </summary>
public sealed class ChannelLogger : IDisposable
{
    // ── Constants ────────────────────────────────────────────────────────
    private const int FlushBatchSize = 50;     // Flush every N lines
    private const int FlushIntervalSec = 1;    // Or every N seconds

    // ── High-resolution time base ────────────────────────────────────────
    // Capture a base pair (Stopwatch.GetTimestamp, DateTime.UtcNow) once.
    // Subsequent timestamps compute offset from the base for µs precision.
    private static readonly long _timeBase = Stopwatch.GetTimestamp();
    private static readonly DateTime _wallBase = DateTime.Now;
    private static readonly double _tickFrequency = Stopwatch.Frequency;

    // ── Instance fields ──────────────────────────────────────────────────
    private readonly ChannelState[] _channels;
    private readonly RollOption _rollOption;
    private readonly long _maxFileSize;
    private readonly CancellationTokenSource _cts;
    private readonly Task _writerTask;
    private Action<string>? _onLogCallback;
    private bool _disposed;

    // ── Constructor ──────────────────────────────────────────────────────

    /// <summary>
    /// Creates a new ChannelLogger instance.
    /// </summary>
    /// <param name="bufferSize">Ring buffer capacity per channel (number of log items).</param>
    /// <param name="baseFilePaths">
    /// Array of base file paths, one per channel.
    /// Each path is split into directory + base filename.
    /// Example: "C:\LOG\System" → dir="C:\LOG", name="System"
    /// </param>
    /// <param name="maxFileSize">Maximum log file size in bytes before rolling to next index.</param>
    /// <param name="rollOption">Daily or hourly file rolling.</param>
    public ChannelLogger(
        int bufferSize,
        string[] baseFilePaths,
        long maxFileSize,
        RollOption rollOption)
    {
        ArgumentNullException.ThrowIfNull(baseFilePaths);
        if (baseFilePaths.Length == 0)
            throw new ArgumentException("At least one base file path is required.", nameof(baseFilePaths));

        _rollOption = rollOption;
        _maxFileSize = maxFileSize;
        _cts = new CancellationTokenSource();

        var now = DateTime.Now;
        _channels = new ChannelState[baseFilePaths.Length];

        for (var i = 0; i < baseFilePaths.Length; i++)
        {
            var dir = Path.GetDirectoryName(baseFilePaths[i]) ?? ".";
            var name = Path.GetFileNameWithoutExtension(baseFilePaths[i]);

            if (!Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            var ch = new ChannelState(dir, name, bufferSize);
            ch.CurrentFolderKey = now.ToString("yyyyMMdd");
            ch.CurrentRollKey = _rollOption == RollOption.Daily
                ? ch.CurrentFolderKey
                : now.ToString("yyyyMMddHH");

            _channels[i] = ch;
            OpenNewLogFile(i);
        }

        // Start the background writer task
        _writerTask = Task.Run(() => WriterLoop(_cts.Token));
    }

    /// <summary>
    /// Number of channels (process count).
    /// </summary>
    public int ChannelCount => _channels.Length;

    // ── Public API ───────────────────────────────────────────────────────

    /// <summary>
    /// Enqueues a log message for the specified channel.
    /// Thread-safe. Per-channel lock ensures timestamp ordering.
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="message">Log message text.</param>
    public void Log(int channel, string message)
    {
        if (_disposed) return;
        if (channel < 0 || channel >= _channels.Length) return;

        var ch = _channels[channel];

        // Per-channel lock: timestamp capture + enqueue must be atomic
        // to prevent timestamp ordering inversion (see MEMORY.md)
        lock (ch.EnqueueLock)
        {
            var ticks = Stopwatch.GetTimestamp();
            var wallClock = ComputeWallClock(ticks);
            var item = new LogItem(ticks, wallClock, message);
            ch.Buffer.Writer.TryWrite(item);
        }
    }

    /// <summary>
    /// Sets an optional callback that is invoked for each log line written.
    /// Can be used for UI display (invoke on UI thread separately).
    /// </summary>
    public void SetOnLogCallback(Action<string>? callback)
    {
        _onLogCallback = callback;
    }

    /// <summary>
    /// Gets the current log file path for a channel.
    /// </summary>
    public string GetLogPath(int channel = 0)
    {
        if (channel >= 0 && channel < _channels.Length)
            return _channels[channel].CurrentLogPath;
        return string.Empty;
    }

    /// <summary>
    /// Opens the current log file in the default text editor.
    /// </summary>
    public void OpenLogInEditor(int channel = 0)
    {
        var path = GetLogPath(channel);
        if (!string.IsNullOrEmpty(path) && File.Exists(path))
        {
            Process.Start(new ProcessStartInfo(path) { UseShellExecute = true });
        }
    }

    /// <summary>
    /// Reads the current log file content as a string array (for UI display).
    /// </summary>
    public string[] ReadCurrentLog(int channel = 0)
    {
        var path = GetLogPath(channel);
        if (!string.IsNullOrEmpty(path) && File.Exists(path))
        {
            try
            {
                // Open with shared read access since the writer also has the file open
                using var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                using var reader = new StreamReader(fs, Encoding.UTF8);
                var content = reader.ReadToEnd();
                return content.Split(Environment.NewLine, StringSplitOptions.None);
            }
            catch
            {
                // File may be locked or rotating
            }
        }
        return Array.Empty<string>();
    }

    // ── Background Writer Loop ───────────────────────────────────────────

    private async Task WriterLoop(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            var processed = ProcessAllChannels();
            if (!processed)
            {
                // No data processed - wait briefly to avoid busy spin
                try { await Task.Delay(1, ct); }
                catch (OperationCanceledException) { break; }
            }
        }

        // Final drain: flush remaining items after cancellation
        DrainAllChannels();
    }

    private bool ProcessAllChannels()
    {
        var totalProcessed = 0;

        for (var i = 0; i < _channels.Length; i++)
        {
            var ch = _channels[i];
            var channelProcessed = 0;

            while (ch.Buffer.Reader.TryRead(out var item))
            {
                if (string.IsNullOrWhiteSpace(item.Message))
                    continue;

                WriteLogItem(i, ch, item);
                channelProcessed++;
            }

            if (channelProcessed > 0)
            {
                totalProcessed += channelProcessed;
                TryFlush(i, ch);
            }
        }

        return totalProcessed > 0;
    }

    private void DrainAllChannels()
    {
        for (var i = 0; i < _channels.Length; i++)
        {
            var ch = _channels[i];
            while (ch.Buffer.Reader.TryRead(out var item))
            {
                if (string.IsNullOrWhiteSpace(item.Message))
                    continue;
                WriteLogItem(i, ch, item);
            }

            // Final flush
            try
            {
                ch.Writer?.Flush();
                ch.FileStream?.Flush(true);
            }
            catch { /* swallow during shutdown */ }
        }
    }

    private void WriteLogItem(int chIndex, ChannelState ch, LogItem item)
    {
        try
        {
            // Format: "HH:mm:ss.uuuuuu >> message"
            var line = FormatTimestamp(item.WallClock) + " >> " + item.Message;

            EnsureLogFile(chIndex);
            ch.Writer!.WriteLine(line);
            ch.FlushCount++;

            _onLogCallback?.Invoke(line);
        }
        catch (Exception ex)
        {
            // Swallow write errors to prevent one bad line from breaking the writer.
            // In Delphi original: CodeSite.Send(...)
            System.Diagnostics.Debug.WriteLine(
                $"ChannelLogger write error: {ex.Message} BaseName={ch.BaseName}");
        }
    }

    private void TryFlush(int chIndex, ChannelState ch)
    {
        try
        {
            if (ch.FlushCount >= FlushBatchSize ||
                (DateTime.Now - ch.LastFlushTime).TotalSeconds >= FlushIntervalSec)
            {
                ch.Writer?.Flush();
                ch.FileStream?.Flush(true); // FlushFileBuffers equivalent
                ch.FlushCount = 0;
                ch.LastFlushTime = DateTime.Now;
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(
                $"ChannelLogger flush error: {ex.Message} BaseName={ch.BaseName}");
        }
    }

    // ── File Rolling ─────────────────────────────────────────────────────

    private void EnsureLogFile(int chIndex)
    {
        var ch = _channels[chIndex];
        var now = DateTime.Now;

        var newFolderKey = now.ToString("yyyyMMdd");
        var newRollKey = _rollOption == RollOption.Daily
            ? newFolderKey
            : now.ToString("yyyyMMddHH");

        // Date/hour changed → new file
        if (newFolderKey != ch.CurrentFolderKey || newRollKey != ch.CurrentRollKey)
        {
            ch.CurrentFolderKey = newFolderKey;
            ch.CurrentRollKey = newRollKey;
            ch.FileIndex = 1;
            OpenNewLogFile(chIndex);
            return;
        }

        // Size exceeded → increment index
        if (ch.Writer != null && ch.Writer.BaseStream.Length >= _maxFileSize)
        {
            ch.FileIndex++;
            OpenNewLogFile(chIndex);
        }
    }

    private void OpenNewLogFile(int chIndex)
    {
        var ch = _channels[chIndex];

        // Close existing streams
        ch.Writer?.Dispose();
        ch.Writer = null;
        ch.FileStream?.Dispose();
        ch.FileStream = null;

        // Subdirectory: BaseDir\yyyyMMdd\
        var subDir = Path.Combine(ch.BaseDir, ch.CurrentFolderKey);
        if (!Directory.Exists(subDir))
            Directory.CreateDirectory(subDir);

        // Filename: BaseName_RollKey_Index.log
        //   Daily:  System_20240115_1.log
        //   Hourly: System_2024011514_1.log
        var fileName = Path.Combine(subDir,
            $"{ch.BaseName}_{ch.CurrentRollKey}_{ch.FileIndex}.log");

        // Open with shared read access (other processes can read while we write)
        ch.FileStream = new FileStream(
            fileName,
            FileMode.OpenOrCreate,
            FileAccess.Write,
            FileShare.Read);
        ch.FileStream.Seek(0, SeekOrigin.End); // Append mode

        ch.Writer = new StreamWriter(ch.FileStream, Encoding.UTF8)
        {
            AutoFlush = false // Batch flush for performance
        };
        ch.CurrentLogPath = fileName;
    }

    // ── Timestamp Formatting ─────────────────────────────────────────────

    /// <summary>
    /// Formats a DateTime with microsecond precision: "HH:mm:ss.ffffff"
    /// Equivalent to Delphi's FormatFileTimePrecise function.
    /// </summary>
    private static string FormatTimestamp(DateTime dt)
    {
        // DateTime.ToString("HH:mm:ss.ffffff") gives microsecond precision
        return dt.ToString("HH:mm:ss.ffffff");
    }

    /// <summary>
    /// Computes wall-clock time from a Stopwatch timestamp with µs precision.
    /// Uses the base pair captured at static initialization.
    /// </summary>
    private static DateTime ComputeWallClock(long ticks)
    {
        var elapsed = (ticks - _timeBase) / _tickFrequency;
        return _wallBase.AddSeconds(elapsed);
    }

    // ── Static helper (replaces global GetPreciseTimeString) ─────────────

    /// <summary>
    /// Returns the current time as "HH:mm:ss.ffffff" with microsecond precision.
    /// Replaces Delphi's global GetPreciseTimeString function.
    /// </summary>
    public static string GetPreciseTimeString()
    {
        var ticks = Stopwatch.GetTimestamp();
        var dt = ComputeWallClock(ticks);
        return FormatTimestamp(dt);
    }

    // ── IDisposable ──────────────────────────────────────────────────────

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        // Signal the writer to stop and wait for it
        _cts.Cancel();
        try { _writerTask.Wait(TimeSpan.FromSeconds(5)); }
        catch { /* timeout or cancellation */ }

        // Dispose all channel states
        foreach (var ch in _channels)
            ch.Dispose();

        _cts.Dispose();
    }
}
