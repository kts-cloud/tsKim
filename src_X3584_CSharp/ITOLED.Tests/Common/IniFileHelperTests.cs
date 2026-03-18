// =============================================================================
// IniFileHelperTests.cs — Tests for INI file read/write operations
// =============================================================================

using Dongaeltek.ITOLED.Core.Common;

namespace ITOLED.Tests.Common;

public class IniFileHelperTests : IDisposable
{
    private readonly string _tempDir;
    private readonly string _iniPath;

    public IniFileHelperTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), "ITOLED_Tests_" + Guid.NewGuid().ToString("N")[..8]);
        Directory.CreateDirectory(_tempDir);
        _iniPath = Path.Combine(_tempDir, "test.ini");
    }

    public void Dispose()
    {
        try { Directory.Delete(_tempDir, recursive: true); }
        catch { /* ignore cleanup errors in tests */ }
    }

    // ── Basic Read/Write ─────────────────────────────────────

    [Fact]
    public void WriteAndReadString_RoundTrip()
    {
        using (var ini = new IniFileHelper(_iniPath))
        {
            ini.WriteString("Section1", "Key1", "Value1");
            ini.Flush();
        }

        using (var ini = new IniFileHelper(_iniPath))
        {
            Assert.Equal("Value1", ini.ReadString("Section1", "Key1"));
        }
    }

    [Fact]
    public void ReadString_MissingKey_ReturnsDefault()
    {
        using var ini = new IniFileHelper(_iniPath);
        Assert.Equal("default", ini.ReadString("NoSection", "NoKey", "default"));
    }

    [Fact]
    public void WriteAndReadInteger_RoundTrip()
    {
        using (var ini = new IniFileHelper(_iniPath))
        {
            ini.WriteInteger("PLC", "StationNo", 42);
            ini.Flush();
        }

        using (var ini = new IniFileHelper(_iniPath))
        {
            Assert.Equal(42, ini.ReadInteger("PLC", "StationNo"));
        }
    }

    [Fact]
    public void ReadInteger_InvalidValue_ReturnsDefault()
    {
        using var ini = new IniFileHelper(_iniPath);
        ini.WriteString("Test", "BadInt", "not_a_number");
        Assert.Equal(-1, ini.ReadInteger("Test", "BadInt", -1));
    }

    // ── Boolean ──────────────────────────────────────────────

    [Theory]
    [InlineData("1", true)]
    [InlineData("true", true)]
    [InlineData("True", true)]
    [InlineData("yes", true)]
    [InlineData("0", false)]
    [InlineData("false", false)]
    [InlineData("no", false)]
    public void ReadBool_RecognizesAllFormats(string stored, bool expected)
    {
        using var ini = new IniFileHelper(_iniPath);
        ini.WriteString("Test", "Flag", stored);
        Assert.Equal(expected, ini.ReadBool("Test", "Flag"));
    }

    [Fact]
    public void WriteBool_StoresAsOneOrZero()
    {
        using var ini = new IniFileHelper(_iniPath);
        ini.WriteBool("Test", "TrueFlag", true);
        ini.WriteBool("Test", "FalseFlag", false);
        Assert.Equal("1", ini.ReadString("Test", "TrueFlag"));
        Assert.Equal("0", ini.ReadString("Test", "FalseFlag"));
    }

    // ── Float ────────────────────────────────────────────────

    [Fact]
    public void WriteAndReadFloat_RoundTrip()
    {
        using (var ini = new IniFileHelper(_iniPath))
        {
            ini.WriteFloat("Cal", "Offset", 3.14159);
            ini.Flush();
        }

        using (var ini = new IniFileHelper(_iniPath))
        {
            Assert.Equal(3.14159, ini.ReadFloat("Cal", "Offset"), precision: 5);
        }
    }

    // ── Section Operations ───────────────────────────────────

    [Fact]
    public void SectionExists_ReturnsTrueForExistingSection()
    {
        using var ini = new IniFileHelper(_iniPath);
        ini.WriteString("MySection", "Key", "Val");
        Assert.True(ini.SectionExists("MySection"));
        Assert.False(ini.SectionExists("NonExistent"));
    }

    [Fact]
    public void ReadSection_ReturnsAllKeys()
    {
        using var ini = new IniFileHelper(_iniPath);
        ini.WriteString("Sect", "A", "1");
        ini.WriteString("Sect", "B", "2");
        ini.WriteString("Sect", "C", "3");

        var keys = ini.ReadSection("Sect");
        Assert.Equal(3, keys.Count);
        Assert.Contains("A", keys);
        Assert.Contains("B", keys);
        Assert.Contains("C", keys);
    }

    [Fact]
    public void EraseSection_RemovesEntireSection()
    {
        using var ini = new IniFileHelper(_iniPath);
        ini.WriteString("ToDelete", "Key", "Val");
        Assert.True(ini.SectionExists("ToDelete"));

        ini.EraseSection("ToDelete");
        Assert.False(ini.SectionExists("ToDelete"));
    }

    // ── Case Insensitivity ───────────────────────────────────

    [Fact]
    public void SectionAndKey_CaseInsensitive()
    {
        using var ini = new IniFileHelper(_iniPath);
        ini.WriteString("SECTION", "KEY", "value");
        Assert.Equal("value", ini.ReadString("section", "key"));
        Assert.Equal("value", ini.ReadString("Section", "Key"));
    }

    // ── Reload ───────────────────────────────────────────────

    [Fact]
    public void Reload_DiscardsInMemoryChanges()
    {
        // Write initial data to file
        using (var ini = new IniFileHelper(_iniPath))
        {
            ini.WriteString("A", "X", "original");
            ini.Flush();
        }

        // Modify in-memory, then reload
        using (var ini = new IniFileHelper(_iniPath))
        {
            ini.WriteString("A", "X", "modified");
            Assert.Equal("modified", ini.ReadString("A", "X"));

            ini.Reload();
            Assert.Equal("original", ini.ReadString("A", "X"));
        }
    }

    // ── Dispose Flushes ──────────────────────────────────────

    [Fact]
    public void Dispose_FlushesUnflushedChanges()
    {
        using (var ini = new IniFileHelper(_iniPath))
        {
            ini.WriteString("Auto", "Save", "OnDispose");
            // No explicit Flush — Dispose should handle it
        }

        using (var ini = new IniFileHelper(_iniPath))
        {
            Assert.Equal("OnDispose", ini.ReadString("Auto", "Save"));
        }
    }

    // ── Non-existent file ────────────────────────────────────

    [Fact]
    public void Constructor_NonExistentFile_CreatesEmptyConfig()
    {
        string noFile = Path.Combine(_tempDir, "nonexistent.ini");
        using var ini = new IniFileHelper(noFile);
        Assert.Equal("default", ini.ReadString("Any", "Key", "default"));
    }

    // ── Comment lines ────────────────────────────────────────

    [Fact]
    public void Load_SkipsCommentsAndEmptyLines()
    {
        File.WriteAllText(_iniPath, """
            ; This is a comment
            # This is also a comment

            [Section]
            Key1=Value1
            ; Another comment
            Key2=Value2
            """);

        using var ini = new IniFileHelper(_iniPath);
        Assert.Equal("Value1", ini.ReadString("Section", "Key1"));
        Assert.Equal("Value2", ini.ReadString("Section", "Key2"));
    }
}
