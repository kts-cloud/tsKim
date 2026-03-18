namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Application-level logger abstraction.
/// Replaces Delphi's direct file/GUI logging calls scattered throughout
/// CommonClass and the various Comm* units.
/// </summary>
public interface ILogger
{
    /// <summary>Log an informational message.</summary>
    void Info(string message);

    /// <summary>Log an informational message with channel context.</summary>
    void Info(int channel, string message);

    /// <summary>Log a warning message.</summary>
    void Warn(string message);

    /// <summary>Log a warning message with channel context.</summary>
    void Warn(int channel, string message);

    /// <summary>Log an error message.</summary>
    void Error(string message);

    /// <summary>Log an error with exception details.</summary>
    void Error(string message, Exception exception);

    /// <summary>Log an error with channel context.</summary>
    void Error(int channel, string message);

    /// <summary>Log an error with channel context and exception details.</summary>
    void Error(int channel, string message, Exception exception);

    /// <summary>Log a debug/trace message (only if debug logging is active).</summary>
    void Debug(string message);

    /// <summary>Log a debug/trace message with channel context.</summary>
    void Debug(int channel, string message);

    /// <summary>
    /// Log an inspection-result line (OK/NG) to the channel log file,
    /// replacing Delphi's LOG_TYPE_OK / LOG_TYPE_NG usage.
    /// </summary>
    /// <param name="channel">Inspection channel (0-based).</param>
    /// <param name="logType">0 = OK, 1 = NG, 2 = Info.</param>
    /// <param name="message">Log content.</param>
    void LogResult(int channel, int logType, string message);

    /// <summary>
    /// Current debug log level.
    /// Maps to Delphi's <c>m_nDebugLogLevelActive</c>.
    /// 0 = OFF, 1 = INSPECT, 2 = INSPECT+CONNCHECK, 3 = DOWNDATA.
    /// </summary>
    int DebugLogLevel { get; set; }
}
