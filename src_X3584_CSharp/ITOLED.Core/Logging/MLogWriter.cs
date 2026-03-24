// =============================================================================
// MLogWriter.cs — MLog 전용 로거 (UI 표시용 검사 로그)
// 기록 대상: [DLL], <SEQUENCE>, <DIO>, <RESULT>, <MES>, <CSV> 등
// 파일: LOG\MLog\{yyyyMMdd}\MLog_{EQPID}_{date}_{AM/PM}_Ch{N}.txt
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Logging;

/// <summary>
/// MLog 전용 래퍼. UI에 표시되는 검사/시퀀스 로그만 기록.
/// PG 통신 로그는 <see cref="DebugLogWriter"/>에 기록.
/// </summary>
public sealed class MLogWriter : IDisposable
{
    private readonly CommLogger _logger;

    public MLogWriter(int maxChannel, string logPath, string eqpId)
    {
        _logger = new CommLogger(maxChannel, logPath, eqpId)
        {
            LogPrefix = "MLog_"
        };
    }

    /// <summary>채널별 MLog 기록.</summary>
    public void Write(int channel, string message, bool saveNow = false)
        => _logger.MLog(channel, message, saveNow);

    /// <summary>즉시 플러시.</summary>
    public void SaveNow(int channel) => _logger.MLog(channel, "", true);

    public void Dispose() => _logger.Dispose();
}
