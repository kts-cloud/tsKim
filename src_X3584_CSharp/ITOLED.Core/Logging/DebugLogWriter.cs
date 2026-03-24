// =============================================================================
// DebugLogWriter.cs — DebugLog 전용 로거 (PG 통신/하드웨어 디버그 로그)
// 기록 대상: <PG> 통신, FTP, TCon R/W, UDP TX/RX 등
// 파일: LOG\DebugLog\{yyyyMMdd}\DebugLog_{EQPID}_{date}_{AM/PM}_Ch{N}.txt
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Logging;

/// <summary>
/// DebugLog 전용 래퍼. PG 통신/하드웨어 디버그 로그 기록.
/// UI 표시용 검사 로그는 <see cref="MLogWriter"/>에 기록.
/// </summary>
public sealed class DebugLogWriter : IDisposable
{
    private readonly CommLogger _logger;

    public DebugLogWriter(int maxChannel, string logPath, string eqpId)
    {
        _logger = new CommLogger(maxChannel, logPath, eqpId)
        {
            LogPrefix = "DebugLog_"
        };
    }

    /// <summary>채널별 DebugLog 기록.</summary>
    public void Write(int channel, string message, bool saveNow = false)
        => _logger.MLog(channel, message, saveNow);

    public void Dispose() => _logger.Dispose();
}
