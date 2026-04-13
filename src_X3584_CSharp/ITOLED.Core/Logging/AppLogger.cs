// =============================================================================
// AppLogger.cs — Bridge from custom ILogger to Microsoft.Extensions.Logging
//                + Direct file logging (CommLogger 패턴)
// =============================================================================

using System.Text;
using Microsoft.Extensions.Logging;
using IAppLogger = Dongaeltek.ITOLED.Core.Interfaces.ILogger;

namespace Dongaeltek.ITOLED.Core.Logging;

/// <summary>
/// Bridges the custom <see cref="Dongaeltek.ITOLED.Core.Interfaces.ILogger"/>
/// to Microsoft's <see cref="Microsoft.Extensions.Logging.ILogger"/>.
/// Also writes log entries to date-based files under DebugLogDir.
/// Registered as singleton in the DI container.
/// </summary>
public sealed class AppLogger : IAppLogger, IDisposable
{
    private readonly Microsoft.Extensions.Logging.ILogger _msLogger;

    // ── File logging (CommLogger 패턴) ──────────────────────────
    private string? _logDir;
    /// <summary>Guards the in-memory buffer only. Held briefly — never during disk I/O.</summary>
    private readonly object _fileLock = new();
    /// <summary>Serializes actual file writes so disk I/O can't run concurrently.</summary>
    private readonly object _writeLock = new();
    private readonly List<string> _buffer = new();
    private DateTime _lastFlush = DateTime.MinValue;
    private const int FlushIntervalSec = 5;
    private const int FlushCountThreshold = 20;
    /// <summary>Cap on retained lines when disk writes are failing — prevents unbounded growth.</summary>
    private const int BufferOverflowLimit = 1000;
    private readonly CancellationTokenSource _cts = new();
    private Task? _flushTask;
    private bool _disposed;

    public AppLogger(ILoggerFactory loggerFactory)
    {
        _msLogger = loggerFactory.CreateLogger("ITOLED");
    }

    /// <summary>
    /// 파일 로깅을 활성화합니다. 호출 후부터 모든 로그가 파일에도 기록됩니다.
    /// <paramref name="debugLogDir"/>: LOG\DebugLog\ 경로
    /// </summary>
    public void EnableFileLogging(string debugLogDir)
    {
        _logDir = debugLogDir;
        if (!Directory.Exists(_logDir))
            Directory.CreateDirectory(_logDir);

        _flushTask = Task.Run(async () =>
        {
            while (!_cts.Token.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(1000, _cts.Token);
                    FlushIfNeeded();
                }
                catch (OperationCanceledException) { break; }
                catch { /* swallow */ }
            }
            // Final flush
            FlushToFile();
        });
    }

    public int DebugLogLevel { get; set; }

    public void Info(string message)
    {
        _msLogger.LogInformation("{Message}", message);
        WriteToBuffer("INFO", message);
    }

    public void Info(int channel, string message)
    {
        _msLogger.LogInformation("[CH{Channel}] {Message}", channel, message);
        WriteToBuffer("INFO", $"[CH{channel}] {message}");
    }

    public void Warn(string message)
    {
        _msLogger.LogWarning("{Message}", message);
        WriteToBuffer("WARN", message);
    }

    public void Warn(int channel, string message)
    {
        _msLogger.LogWarning("[CH{Channel}] {Message}", channel, message);
        WriteToBuffer("WARN", $"[CH{channel}] {message}");
    }

    public void Error(string message)
    {
        _msLogger.LogError("{Message}", message);
        WriteToBuffer("ERROR", message);
    }

    public void Error(string message, Exception exception)
    {
        _msLogger.LogError(exception, "{Message}", message);
        WriteToBuffer("ERROR", $"{message} | {exception}");
    }

    public void Error(int channel, string message)
    {
        _msLogger.LogError("[CH{Channel}] {Message}", channel, message);
        WriteToBuffer("ERROR", $"[CH{channel}] {message}");
    }

    public void Error(int channel, string message, Exception exception)
    {
        _msLogger.LogError(exception, "[CH{Channel}] {Message}", channel, message);
        WriteToBuffer("ERROR", $"[CH{channel}] {message} | {exception}");
    }

    public void Debug(string message)
    {
        if (DebugLogLevel > 0)
            _msLogger.LogDebug("{Message}", message);
        WriteToBuffer("DEBUG", message);
    }

    public void Debug(int channel, string message)
    {
        if (DebugLogLevel > 0)
            _msLogger.LogDebug("[CH{Channel}] {Message}", channel, message);
        WriteToBuffer("DEBUG", $"[CH{channel}] {message}");
    }

    public void LogResult(int channel, int logType, string message)
    {
        var label = logType switch { 0 => "OK", 1 => "NG", _ => "INFO" };
        _msLogger.LogInformation("[CH{Channel}][{Label}] {Message}", channel, label, message);
        WriteToBuffer("RESULT", $"[CH{channel}][{label}] {message}");
    }

    /// <summary>
    /// 버퍼의 모든 로그를 즉시 파일에 기록합니다.
    /// 크래시 위험이 있는 구간 전후에 호출하세요.
    /// </summary>
    public void Flush()
    {
        FlushToFile();
    }

    // ── File logging internals ──────────────────────────────────

    private void WriteToBuffer(string level, string message)
    {
        if (_logDir == null) return;

        var now = DateTime.Now;
        var line = $"{now:HH:mm:ss.fff} [{level}] {message}";

        bool shouldFlush;
        lock (_fileLock)
        {
            _buffer.Add(line);

            // Immediate flush on error, DPDK-related logs, or when buffer is large
            shouldFlush = level == "ERROR"
                || message.Contains("[DPDK]")
                || message.Contains("[PgDpdkServer]")
                || message.Contains("[Startup]")
                || message.Contains("[FATAL]")
                || _buffer.Count >= FlushCountThreshold;
        }

        // Run the actual disk I/O OUTSIDE _fileLock so other producers can keep
        // appending to the buffer in parallel. _writeLock (taken inside FlushToFile)
        // serializes the writers themselves.
        if (shouldFlush)
            FlushToFile();
    }

    private void FlushIfNeeded()
    {
        bool needsFlush;
        lock (_fileLock)
        {
            if (_buffer.Count == 0) return;
            needsFlush = (DateTime.Now - _lastFlush).TotalSeconds >= FlushIntervalSec;
        }
        if (needsFlush)
            FlushToFile();
    }

    private void FlushToFile()
    {
        if (_logDir == null) return;

        // Snapshot the buffer under the in-memory lock and release it before
        // touching disk. Previously the whole disk write happened while
        // holding _fileLock, so a slow filesystem (network drive, antivirus
        // scan, Windows handle exhaustion) would block every log producer.
        List<string> snapshot;
        lock (_fileLock)
        {
            if (_buffer.Count == 0) return;
            snapshot = new List<string>(_buffer);
            _buffer.Clear();
        }

        // Serialize disk writes — only one writer at a time, but producers
        // are no longer blocked.
        lock (_writeLock)
        {
            try
            {
                var now = DateTime.Now;
                var dateDir = Path.Combine(_logDir, now.ToString("yyyyMMdd"));
                if (!Directory.Exists(dateDir))
                    Directory.CreateDirectory(dateDir);

                var ampm = now.Hour < 12 ? "AM" : "PM";
                var fileName = Path.Combine(dateDir, $"AppLog_{now:yyyyMMdd}_{ampm}.txt");

                using var writer = new StreamWriter(fileName, append: true, Encoding.UTF8);
                foreach (var line in snapshot)
                    writer.WriteLine(line);

                lock (_fileLock)
                {
                    _lastFlush = DateTime.Now;
                }
            }
            catch
            {
                // Disk write failed — snapshot is dropped (matching prior best-effort
                // behavior). If the live buffer has since grown past the overflow
                // limit, trim it too so we don't leak memory while disks are down.
                lock (_fileLock)
                {
                    if (_buffer.Count > BufferOverflowLimit)
                        _buffer.Clear();
                }
            }
        }
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        _cts.Cancel();
        try { _flushTask?.Wait(TimeSpan.FromSeconds(3)); }
        catch { /* timeout */ }

        FlushToFile();

        _cts.Dispose();
    }
}
