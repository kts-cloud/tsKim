using Dongaeltek.ITOLED.BusinessLogic.Database;
using ITOLED.Tests.Plc;

namespace ITOLED.Tests.BusinessLogic;

public class DatabaseServiceTests : IDisposable
{
    private readonly string _dbPath;
    private readonly DatabaseService _svc;

    public DatabaseServiceTests()
    {
        _dbPath = Path.Combine(Path.GetTempPath(), $"ITOLED_TEST_{Guid.NewGuid():N}.db");
        _svc = new DatabaseService(_dbPath, new NullLogger());
        _svc.Initialize();
    }

    public void Dispose()
    {
        _svc.Dispose();
        try { File.Delete(_dbPath); } catch { }
    }

    [Fact]
    public void Initialize_CreatesDatabase()
    {
        Assert.True(File.Exists(_dbPath));
    }

    [Fact]
    public void UpdateNgTypeCount_InsertsNewRow()
    {
        _svc.UpdateNgTypeCount(0, 1);
        var rows = _svc.QueryNgRatio(DateTime.Today, DateTime.Today);
        Assert.Single(rows);
        Assert.Equal(1, rows[0].NgType);
        Assert.Equal(1, rows[0].Ch1);
        Assert.Equal(0, rows[0].Ch2);
    }

    [Fact]
    public void UpdateNgTypeCount_IncrementsExisting()
    {
        _svc.UpdateNgTypeCount(0, 1);
        _svc.UpdateNgTypeCount(0, 1);
        _svc.UpdateNgTypeCount(0, 1);

        var rows = _svc.QueryNgRatio(DateTime.Today, DateTime.Today);
        Assert.Single(rows);
        Assert.Equal(3, rows[0].Ch1);
    }

    [Fact]
    public void UpdateNgTypeCount_MultipleChannels()
    {
        _svc.UpdateNgTypeCount(0, 5);
        _svc.UpdateNgTypeCount(1, 5);
        _svc.UpdateNgTypeCount(2, 5);
        _svc.UpdateNgTypeCount(3, 5);

        var rows = _svc.QueryNgRatio(DateTime.Today, DateTime.Today);
        Assert.Single(rows);
        Assert.Equal(1, rows[0].Ch1);
        Assert.Equal(1, rows[0].Ch2);
        Assert.Equal(1, rows[0].Ch3);
        Assert.Equal(1, rows[0].Ch4);
        Assert.Equal(4, rows[0].Total);
    }

    [Fact]
    public void QueryNgRatio_EmptyRange_ReturnsEmpty()
    {
        var rows = _svc.QueryNgRatio(DateTime.Today.AddDays(-10), DateTime.Today.AddDays(-5));
        Assert.Empty(rows);
    }

    [Fact]
    public void DeleteNgData_RemovesRows()
    {
        _svc.UpdateNgTypeCount(0, 1);
        _svc.UpdateNgTypeCount(0, 2);

        _svc.DeleteNgData(DateTime.Today, DateTime.Today);

        var rows = _svc.QueryNgRatio(DateTime.Today, DateTime.Today);
        Assert.Empty(rows);
    }

    [Fact]
    public void InsertTactTime_StoresValue()
    {
        _svc.InsertTactTime(12.5);
        var times = _svc.GetRecentTactTimes();
        Assert.Single(times);
        Assert.Equal(12.5, times[0]);
    }

    [Fact]
    public void InsertTactTime_RollingBuffer_MaxTen()
    {
        for (int i = 0; i < 15; i++)
            _svc.InsertTactTime(i * 1.1);

        var times = _svc.GetRecentTactTimes();
        Assert.True(times.Count <= 10);
    }

    [Fact]
    public void InvalidChannel_Ignored()
    {
        _svc.UpdateNgTypeCount(-1, 1);
        _svc.UpdateNgTypeCount(5, 1);
        var rows = _svc.QueryNgRatio(DateTime.Today, DateTime.Today);
        Assert.Empty(rows);
    }
}
