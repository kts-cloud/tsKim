// =============================================================================
// CommonUtilityTests.cs — Tests for CRC, encryption, hex conversion, etc.
// =============================================================================

using System.Text;
using Dongaeltek.ITOLED.Core.Common;

namespace ITOLED.Tests.Common;

public class CommonUtilityTests
{
    // ── CRC16 Tests ──────────────────────────────────────────

    [Fact]
    public void Crc16_EmptyString_ReturnsInvertedInitial()
    {
        // When len=0, should return ~0xFFFF byte-swapped
        ushort result = CommonUtility.Crc16("", 0);
        Assert.Equal((ushort)0x0000, result); // ~0xFFFF = 0x0000, then byte-swap = 0x0000
    }

    [Fact]
    public void Crc16_KnownInput_ProducesConsistentResult()
    {
        // ASCII "123" → 3 bytes
        string input = "123";
        int len = Encoding.GetEncoding(949).GetByteCount(input);
        ushort crc1 = CommonUtility.Crc16(input, len);
        ushort crc2 = CommonUtility.Crc16(input, len);
        Assert.Equal(crc1, crc2); // Same input → same output
        Assert.NotEqual((ushort)0, crc1); // Non-trivial for non-empty input
    }

    [Fact]
    public void Crc16Buf_KnownInput_ProducesConsistentResult()
    {
        byte[] data = [0x01, 0x02, 0x03, 0x04];
        ushort crc1 = CommonUtility.Crc16Buf(data, data.Length);
        ushort crc2 = CommonUtility.Crc16Buf(data, data.Length);
        Assert.Equal(crc1, crc2);
        Assert.NotEqual((ushort)0, crc1);
    }

    [Fact]
    public void Crc16_DifferentInputs_ProduceDifferentCrc()
    {
        ushort crcA = CommonUtility.Crc16("ABC", 3);
        ushort crcB = CommonUtility.Crc16("XYZ", 3);
        Assert.NotEqual(crcA, crcB);
    }

    [Fact]
    public void GetStringCrc_ReturnsHex4Digits()
    {
        string crc = CommonUtility.GetStringCrc("TestData");
        Assert.Equal(4, crc.Length);
        Assert.True(crc.All(c => "0123456789ABCDEF".Contains(c)),
            "CRC should be uppercase hex");
    }

    [Fact]
    public void GetScriptCrc_CombinesAllLines()
    {
        var lines = new List<string> { "line1", "line2", "line3" };
        string crc = CommonUtility.GetScriptCrc(lines);
        Assert.Equal(4, crc.Length);

        // Should equal CRC of concatenated string
        string combined = "line1line2line3";
        string expected = CommonUtility.GetStringCrc(combined);
        Assert.Equal(expected, crc);
    }

    // ── CalcCheckSum Tests ───────────────────────────────────

    [Fact]
    public void CalcCheckSum_SumsAllBytes()
    {
        byte[] data = [1, 2, 3, 4, 5];
        uint sum = CommonUtility.CalcCheckSum(data, (uint)data.Length);
        Assert.Equal(15u, sum);
    }

    [Fact]
    public void CalcCheckSum_EmptyBuffer_ReturnsZero()
    {
        byte[] data = [];
        uint sum = CommonUtility.CalcCheckSum(data, 0);
        Assert.Equal(0u, sum);
    }

    [Fact]
    public void CalcCheckSum_AccumulatesOnRef()
    {
        byte[] data = [10, 20];
        uint runningSum = 100;
        CommonUtility.CalcCheckSum(data, 2, ref runningSum);
        Assert.Equal(130u, runningSum); // 100 + 10 + 20
    }

    // ── Hex Conversion Tests ─────────────────────────────────

    [Fact]
    public void ValueToHex_ConvertsSingleCharsToTwoDigitHex()
    {
        Assert.Equal("41", CommonUtility.ValueToHex("A"));   // 'A' = 0x41
        Assert.Equal("61", CommonUtility.ValueToHex("a"));   // 'a' = 0x61
        Assert.Equal("30", CommonUtility.ValueToHex("0"));   // '0' = 0x30
    }

    [Fact]
    public void ValueToHex_MultiCharString()
    {
        Assert.Equal("414243", CommonUtility.ValueToHex("ABC"));
    }

    [Fact]
    public void HexToValue_RevertsValueToHex()
    {
        string original = "Hello";
        string hex = CommonUtility.ValueToHex(original);
        string recovered = CommonUtility.HexToValue(hex);
        Assert.Equal(original, recovered);
    }

    [Fact]
    public void HexToValue_EmptyString_ReturnsEmpty()
    {
        Assert.Equal("", CommonUtility.HexToValue(""));
    }

    // ── Encrypt/Decrypt Tests ────────────────────────────────

    [Theory]
    [InlineData("HelloWorld", (ushort)12345)]
    [InlineData("Test123!@#", (ushort)0)]
    [InlineData("A", (ushort)65535)]
    [InlineData("Simple text with spaces", (ushort)1000)]
    public void EncryptDecrypt_Roundtrip(string plainText, ushort key)
    {
        string encrypted = CommonUtility.Encrypt(plainText, key);
        string decrypted = CommonUtility.Decrypt(encrypted, key);
        Assert.Equal(plainText, decrypted);
    }

    [Fact]
    public void Encrypt_OutputIsHexEncoded()
    {
        string encrypted = CommonUtility.Encrypt("Test", 100);
        // ValueToHex produces uppercase hex, 2 chars per input char
        Assert.True(encrypted.Length > 0);
        Assert.True(encrypted.All(c => "0123456789ABCDEF".Contains(c)),
            "Encrypted output should be hex-encoded");
    }

    [Fact]
    public void Encrypt_DifferentKeys_ProduceDifferentOutput()
    {
        string enc1 = CommonUtility.Encrypt("Test", 100);
        string enc2 = CommonUtility.Encrypt("Test", 200);
        Assert.NotEqual(enc1, enc2);
    }

    // ── Time Formatting Tests ────────────────────────────────

    [Theory]
    [InlineData(0, "00:00:00")]
    [InlineData(61, "00:01:01")]
    [InlineData(3600, "01:00:00")]
    [InlineData(3661, "01:01:01")]
    [InlineData(86399, "23:59:59")]
    public void SetTimeToStr_FormatsCorrectly(long seconds, string expected)
    {
        Assert.Equal(expected, CommonUtility.SetTimeToStr(seconds));
    }

    // ── DecToOct Tests ───────────────────────────────────────

    [Theory]
    [InlineData(0, "0")]
    [InlineData(8, "10")]
    [InlineData(9, "11")]
    [InlineData(64, "100")]
    [InlineData(255, "377")]
    public void DecToOct_ConvertsCorrectly(int input, string expected)
    {
        Assert.Equal(expected, CommonUtility.DecToOct(input));
    }

    // ── String Utility Tests ─────────────────────────────────

    [Fact]
    public void RemoveControlCharacters_StripsAsciiControlCodes()
    {
        string input = "Hello\u0001World\u000A\u001FEnd";
        string result = CommonUtility.RemoveControlCharacters(input);
        Assert.Equal("HelloWorldEnd", result);
    }

    [Fact]
    public void RemoveControlCharacters_NullReturnsEmpty()
    {
        Assert.Equal("", CommonUtility.RemoveControlCharacters(null!));
        Assert.Equal("", CommonUtility.RemoveControlCharacters(""));
    }

    [Theory]
    [InlineData("abc123def456", "123456")]
    [InlineData("no_digits_here", "")]
    [InlineData("12345", "12345")]
    [InlineData("", "")]
    public void ExtractNumbersFromString_ExtractsDigits(string input, string expected)
    {
        Assert.Equal(expected, CommonUtility.ExtractNumbersFromString(input));
    }

    // ── Type Conversion Tests ────────────────────────────────

    [Fact]
    public void IntToIdBytes_LittleEndian()
    {
        byte[] bytes = CommonUtility.IntToIdBytes(0x01020304);
        Assert.Equal(4, bytes.Length);
        Assert.Equal(0x04, bytes[0]); // Little-endian: least significant byte first
        Assert.Equal(0x03, bytes[1]);
        Assert.Equal(0x02, bytes[2]);
        Assert.Equal(0x01, bytes[3]);
    }

    [Fact]
    public void StringToIdBytes_TakesLowByte()
    {
        byte[] bytes = CommonUtility.StringToIdBytes("ABC");
        Assert.Equal(3, bytes.Length);
        Assert.Equal((byte)'A', bytes[0]);
        Assert.Equal((byte)'B', bytes[1]);
        Assert.Equal((byte)'C', bytes[2]);
    }

    [Fact]
    public void StringToPAnsiBytes_NullTerminated()
    {
        byte[] bytes = CommonUtility.StringToPAnsiBytes("Hi");
        Assert.True(bytes.Length >= 3);
        Assert.Equal(0, bytes[^1]); // Null-terminated
    }
}
