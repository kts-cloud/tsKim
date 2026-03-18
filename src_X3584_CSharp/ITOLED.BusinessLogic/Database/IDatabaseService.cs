// =============================================================================
// IDatabaseService.cs — NG ratio statistics database operations.
// Delphi origin: DBModule.pas (TDBModule_Sqlite)
// =============================================================================

namespace Dongaeltek.ITOLED.BusinessLogic.Database;

/// <summary>
/// Provides NG ratio tracking and tact time storage via SQLite.
/// </summary>
public interface IDatabaseService : IDisposable
{
    /// <summary>
    /// Initializes the database: creates tables if they don't exist.
    /// </summary>
    void Initialize();

    /// <summary>
    /// Increments the NG count for a specific channel and NG type on today's date.
    /// Creates the row if it doesn't exist.
    /// </summary>
    void UpdateNgTypeCount(int channel, int ngType);

    /// <summary>
    /// Queries NG ratio data for a date range, grouped by NG type.
    /// Returns a list of (NgType, Ch1Count, Ch2Count, Ch3Count, Ch4Count).
    /// </summary>
    List<NgRatioRow> QueryNgRatio(DateTime startDate, DateTime endDate);

    /// <summary>
    /// Deletes all NG data within the specified date range.
    /// </summary>
    void DeleteNgData(DateTime startDate, DateTime endDate);

    /// <summary>
    /// Inserts a tact time entry (rolling buffer of 10).
    /// </summary>
    void InsertTactTime(double tactTime);

    /// <summary>
    /// Gets the last N tact time entries.
    /// </summary>
    List<double> GetRecentTactTimes(int count = 10);
}

/// <summary>
/// A single row of NG ratio query results.
/// </summary>
public record NgRatioRow(int NgType, int Ch1, int Ch2, int Ch3, int Ch4)
{
    public int Total => Ch1 + Ch2 + Ch3 + Ch4;
}
