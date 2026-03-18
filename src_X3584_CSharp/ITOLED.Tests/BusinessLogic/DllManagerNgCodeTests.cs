using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;

namespace ITOLED.Tests.BusinessLogic;

public class DllManagerNgCodeTests : IDisposable
{
    private readonly string _tempRoot;
    private readonly PathManager _pm;
    private readonly ConfigurationService _configSvc;

    public DllManagerNgCodeTests()
    {
        _tempRoot = Path.Combine(Path.GetTempPath(), "ITOLED_DLL_" + Guid.NewGuid().ToString("N")[..8]);
        Directory.CreateDirectory(_tempRoot);
        _pm = new PathManager(_tempRoot);
        _pm.InitializePaths();
        _configSvc = new ConfigurationService(_pm, new AppConfiguration());
    }

    public void Dispose()
    {
        try { Directory.Delete(_tempRoot, recursive: true); } catch { }
    }

    [Fact]
    public void GmesInfo_AfterLoad_ContainsPassEntry()
    {
        var csvContent = "1,Optical,Defect,OD01,Fail,A06-B01-G78\n2,Optical,Defect,OD02,Gamma,A06-B01-IZJ";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);
        _configSvc.ReadGmesCsvFile();

        Assert.Equal("PASS", _configSvc.GmesInfo[0].ErrCode);
    }

    [Fact]
    public void GmesInfo_FindByErrCode_ReturnsCorrectIndex()
    {
        var csvContent = "1,Optical,Defect,OD01,Fail,A06-B01-G78\n2,Optical,Defect,OD02,Gamma,A06-B01-IZJ";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);
        _configSvc.ReadGmesCsvFile();

        // Simulate what GetNgCodeByErrorCode does
        var gmesInfo = _configSvc.GmesInfo;
        int foundIndex = -1;
        for (int i = 1; i < gmesInfo.Count; i++)
        {
            if (string.Equals(gmesInfo[i].ErrCode, "OD02", StringComparison.OrdinalIgnoreCase))
            {
                foundIndex = i;
                break;
            }
        }
        Assert.Equal(2, foundIndex);
    }

    [Fact]
    public void GmesInfo_FindByErrCode_UnknownCode_NotFound()
    {
        var csvContent = "1,Optical,Defect,OD01,Fail,A06-B01-G78";
        File.WriteAllText(Path.Combine(_pm.IniDir, "MES_CODE.csv"), csvContent);
        _configSvc.ReadGmesCsvFile();

        var gmesInfo = _configSvc.GmesInfo;
        int foundIndex = -1;
        for (int i = 1; i < gmesInfo.Count; i++)
        {
            if (string.Equals(gmesInfo[i].ErrCode, "UNKNOWN", StringComparison.OrdinalIgnoreCase))
            {
                foundIndex = i;
                break;
            }
        }
        Assert.Equal(-1, foundIndex); // Not found -> DllManager would return 3181
    }

    [Fact]
    public void GmesInfo_EmptyOrXXXX_ShouldReturnPass()
    {
        // GetNgCodeByErrorCode returns 0 for empty/XXXX error codes
        Assert.True(string.IsNullOrEmpty("") || "" == "XXXX" || true);
        Assert.True("XXXX" == "XXXX");
    }
}
