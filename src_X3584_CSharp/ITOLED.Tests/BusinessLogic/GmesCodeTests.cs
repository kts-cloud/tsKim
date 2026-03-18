using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.BusinessLogic;

public class GmesCodeTests : IDisposable
{
    private readonly string _tempRoot;
    private readonly PathManager _pm;
    private readonly ConfigurationService _svc;

    public GmesCodeTests()
    {
        _tempRoot = Path.Combine(Path.GetTempPath(), "ITOLED_GMES_" + Guid.NewGuid().ToString("N")[..8]);
        Directory.CreateDirectory(_tempRoot);
        _pm = new PathManager(_tempRoot);
        _pm.InitializePaths();
        _svc = new ConfigurationService(_pm, new AppConfiguration());
    }

    public void Dispose()
    {
        try { Directory.Delete(_tempRoot, recursive: true); } catch { }
    }

    [Fact]
    public void ReadGmesCsvFile_NoFile_ReturnsZero_WithPassEntry()
    {
        var count = _svc.ReadGmesCsvFile();
        Assert.Equal(0, count);
        Assert.Single(_svc.GmesInfo); // index 0 PASS entry
        Assert.Equal("PASS", _svc.GmesInfo[0].ErrCode);
    }

    [Fact]
    public void ReadGmesCsvFile_ValidCsv_ParsesCorrectly()
    {
        var csvContent = "1,Optical Compensation,Optical Defect,OD01,EEPROM Read Fail,A06-B01-G78\n" +
                         "2,Optical Compensation,Optical Defect,OD02,Gamma Fail,A06-B01-IZJ";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);

        var count = _svc.ReadGmesCsvFile();
        Assert.Equal(3, count); // 1 PASS + 2 data rows
        Assert.Equal(3, _svc.GmesInfo.Count);
        Assert.Equal(2, _svc.GmesInfoCount); // excludes PASS

        // Verify first data entry
        Assert.Equal("OD01", _svc.GmesInfo[1].ErrCode);
        Assert.Equal("EEPROM Read Fail", _svc.GmesInfo[1].ErrMsg);

        // Verify MES code formatting (A06-B01-G78 -> formatted with padding)
        Assert.StartsWith("A06-B01-----G78", _svc.GmesInfo[1].MESCode);
    }

    [Fact]
    public void ReadGmesCsvFile_SkipsEmptyLines()
    {
        var csvContent = "\n1,Optical,Defect,OD01,Fail,A06-B01-G78\n\n";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);

        _svc.ReadGmesCsvFile();
        Assert.Equal(2, _svc.GmesInfo.Count); // PASS + 1 data row
    }

    [Fact]
    public void ReadGmesCsvFile_SkipsInvalidRows()
    {
        var csvContent = "bad,data\n1,Optical,Defect,OD01,Fail,A06-B01-G78\n-1,bad,row,X,Y,Z";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);

        _svc.ReadGmesCsvFile();
        Assert.Equal(2, _svc.GmesInfo.Count); // PASS + 1 valid row
    }

    [Fact]
    public void ReadGmesCsvFile_ParsesOptionField()
    {
        var csvContent = "1,Optical,Defect,OD01,Fail,A06-B01-G78,1";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);

        _svc.ReadGmesCsvFile();
        Assert.Equal(1, _svc.GmesInfo[1].Option);
    }

    [Fact]
    public void ReadGmesCsvFile_MesCodeNoHyphen_KeepsOriginal()
    {
        var csvContent = "1,Optical,Defect,OD01,Fail,SIMPLE";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);

        _svc.ReadGmesCsvFile();
        Assert.Equal("SIMPLE", _svc.GmesInfo[1].MESCode);
    }

    [Fact]
    public void ReadGmesCsvFile_CalledTwice_ClearsPrevious()
    {
        var csvContent = "1,Optical,Defect,OD01,Fail,A06-B01-G78";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);
        _svc.ReadGmesCsvFile();
        Assert.Equal(2, _svc.GmesInfo.Count);

        // Call again -- should reset
        _svc.ReadGmesCsvFile();
        Assert.Equal(2, _svc.GmesInfo.Count);
    }
}
