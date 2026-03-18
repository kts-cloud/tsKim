// =============================================================================
// DatabaseService.cs — SQLite implementation for NG ratio tracking.
// Delphi origin: DBModule.pas (TDBModule_Sqlite)
// =============================================================================

using Dongaeltek.ITOLED.Core.Interfaces;
using Microsoft.Data.Sqlite;

namespace Dongaeltek.ITOLED.BusinessLogic.Database;

public sealed class DatabaseService : IDatabaseService
{
    private readonly string _connectionString;
    private readonly ILogger _logger;
    private readonly object _lock = new();

    public DatabaseService(string dbPath, ILogger logger)
    {
        _connectionString = $"Data Source={dbPath}";
        _logger = logger;
    }

    public void Initialize()
    {
        lock (_lock)
        {
            using var conn = new SqliteConnection(_connectionString);
            conn.Open();

            using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                CREATE TABLE IF NOT EXISTS TLB_ISPD (
                    INSP_DATE TEXT NOT NULL,
                    NG_TYPE INTEGER NOT NULL,
                    CH1 INTEGER DEFAULT 0,
                    CH2 INTEGER DEFAULT 0,
                    CH3 INTEGER DEFAULT 0,
                    CH4 INTEGER DEFAULT 0,
                    PRIMARY KEY (INSP_DATE, NG_TYPE)
                );
                CREATE TABLE IF NOT EXISTS TLB_ISPD_TIME (
                    No INTEGER PRIMARY KEY,
                    TACTTIME REAL NOT NULL
                );
                """;
            cmd.ExecuteNonQuery();
            _logger.Info($"Database initialized: {_connectionString}");
        }
    }

    public void UpdateNgTypeCount(int channel, int ngType)
    {
        if (channel < 0 || channel > 3) return;
        var chCol = $"CH{channel + 1}";
        var today = DateTime.Now.ToString("yyyyMMdd");

        lock (_lock)
        {
            using var conn = new SqliteConnection(_connectionString);
            conn.Open();

            // Upsert: insert or update
            using var cmd = conn.CreateCommand();
            cmd.CommandText = $"""
                INSERT INTO TLB_ISPD (INSP_DATE, NG_TYPE, {chCol})
                VALUES (@date, @ngType, 1)
                ON CONFLICT(INSP_DATE, NG_TYPE)
                DO UPDATE SET {chCol} = {chCol} + 1;
                """;
            cmd.Parameters.AddWithValue("@date", today);
            cmd.Parameters.AddWithValue("@ngType", ngType);
            cmd.ExecuteNonQuery();
        }
    }

    public List<NgRatioRow> QueryNgRatio(DateTime startDate, DateTime endDate)
    {
        var results = new List<NgRatioRow>();
        var start = startDate.ToString("yyyyMMdd");
        var end = endDate.ToString("yyyyMMdd");

        lock (_lock)
        {
            using var conn = new SqliteConnection(_connectionString);
            conn.Open();

            using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                SELECT NG_TYPE, SUM(CH1) AS ch1, SUM(CH2) AS ch2, SUM(CH3) AS ch3, SUM(CH4) AS ch4
                FROM TLB_ISPD
                WHERE INSP_DATE BETWEEN @start AND @end
                GROUP BY NG_TYPE
                ORDER BY NG_TYPE
                """;
            cmd.Parameters.AddWithValue("@start", start);
            cmd.Parameters.AddWithValue("@end", end);

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                results.Add(new NgRatioRow(
                    reader.GetInt32(0),
                    reader.GetInt32(1),
                    reader.GetInt32(2),
                    reader.GetInt32(3),
                    reader.GetInt32(4)));
            }
        }
        return results;
    }

    public void DeleteNgData(DateTime startDate, DateTime endDate)
    {
        var start = startDate.ToString("yyyyMMdd");
        var end = endDate.ToString("yyyyMMdd");

        lock (_lock)
        {
            using var conn = new SqliteConnection(_connectionString);
            conn.Open();

            using var cmd = conn.CreateCommand();
            cmd.CommandText = "DELETE FROM TLB_ISPD WHERE INSP_DATE BETWEEN @start AND @end";
            cmd.Parameters.AddWithValue("@start", start);
            cmd.Parameters.AddWithValue("@end", end);
            var deleted = cmd.ExecuteNonQuery();
            _logger.Info($"Deleted {deleted} NG data rows ({start}~{end})");
        }
    }

    public void InsertTactTime(double tactTime)
    {
        lock (_lock)
        {
            using var conn = new SqliteConnection(_connectionString);
            conn.Open();

            // Rolling buffer of 10 entries
            using var delCmd = conn.CreateCommand();
            delCmd.CommandText = """
                DELETE FROM TLB_ISPD_TIME
                WHERE No NOT IN (SELECT No FROM TLB_ISPD_TIME ORDER BY No DESC LIMIT 9)
                """;
            delCmd.ExecuteNonQuery();

            using var maxCmd = conn.CreateCommand();
            maxCmd.CommandText = "SELECT COALESCE(MAX(No), -1) FROM TLB_ISPD_TIME";
            var maxNo = Convert.ToInt32(maxCmd.ExecuteScalar());

            using var insCmd = conn.CreateCommand();
            insCmd.CommandText = "INSERT INTO TLB_ISPD_TIME (No, TACTTIME) VALUES (@no, @tt)";
            insCmd.Parameters.AddWithValue("@no", maxNo + 1);
            insCmd.Parameters.AddWithValue("@tt", tactTime);
            insCmd.ExecuteNonQuery();
        }
    }

    public List<double> GetRecentTactTimes(int count = 10)
    {
        var results = new List<double>();
        lock (_lock)
        {
            using var conn = new SqliteConnection(_connectionString);
            conn.Open();

            using var cmd = conn.CreateCommand();
            cmd.CommandText = "SELECT TACTTIME FROM TLB_ISPD_TIME ORDER BY No DESC LIMIT @count";
            cmd.Parameters.AddWithValue("@count", count);

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
                results.Add(reader.GetDouble(0));
        }
        return results;
    }

    public void Dispose() { }
}
