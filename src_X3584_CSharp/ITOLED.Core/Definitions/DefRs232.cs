namespace Dongaeltek.ITOLED.Core.Definitions;

/// <summary>
/// Serial communication constants. Converted from DefRs232.pas.
/// </summary>
public static class DefRs232
{
    /// <summary>Comm port buffer size</summary>
    public const int COM_BUFF = 4095;

    public const int MAX_RX_CNT = 1000;

    public const char STX = '\x02';
    public const char ETX = '\x03';
    public const char CR = '\r';
    public const char LF = '\n';
    public const char SYN = '\x16';
    public const string CRLF = "\r\n";
    public const string LFCR = "\n\r";

    public const char RCB_STX = '[';
    public const char RCB_ETX = ']';

    public const byte SF5 = 0xF5;
    public const byte SF1 = 0xF1;

    public static readonly byte[] PG_PRO_ST = { (byte)STX, SF1, SF5 };

    public const int MAX_SERIAL_NUM = 100;
}
