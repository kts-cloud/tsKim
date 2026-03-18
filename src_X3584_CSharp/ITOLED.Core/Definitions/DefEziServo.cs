namespace Dongaeltek.ITOLED.Core.Definitions;

/// <summary>
/// EZI servo motor constants. Converted from DefEziServo.pas.
/// </summary>
public static class DefEziServo
{
    // Motor operation modes
    public const int MODE_MOTOR_CONNECT = 1;
    public const int MODE_MOTOR_BOARD_CHECK = 2;
    public const int MODE_GET_SLAVE_INFO = 3;
    public const int MODE_ABS_AXIS_MOVE = 4;
    public const int MODE_INC_AXIS_MOVE = 5;
    public const int MODE_MOVE_STOP = 6;
    public const int MODE_GET_ACTUAL_POS = 7;

    // Return codes (from define.h)
    public const int FMM_OK = 0;
    public const int FMM_NOT_OPEN = 1;
    public const int FMM_INVALID_PORT_NUM = 2;
    public const int FMM_INVALID_SLAVE_NUM = 3;

    public const int FMC_DISCONNECTED = 5;
    public const int FMC_TIMEOUT_ERROR = 6;
    public const int FMC_CRCFAILED_ERROR = 7;
    public const int FMC_RECVPACKET_ERROR = 8;
    public const int FMM_POSTABLE_ERROR = 9;

    public const int FMP_FRAMETYPEERROR = 0x80;
    public const int FMP_DATAERROR = FMP_FRAMETYPEERROR + 1;       // 0x81
    public const int FMP_PACKETERROR = FMP_FRAMETYPEERROR + 2;     // 0x82
    public const int FMP_RUNFAIL = 0x85;
    public const int FMP_RESETFAIL = FMP_RUNFAIL + 1;              // 0x86
    public const int FMP_SERVOONFAIL1 = FMP_RUNFAIL + 2;           // 0x87
    public const int FMP_SERVOONFAIL2 = FMP_RUNFAIL + 3;           // 0x88
    public const int FMP_SERVOONFAIL3 = FMP_RUNFAIL + 4;           // 0x89
    public const int FMP_SERVOOFF_FAIL = FMP_RUNFAIL + 5;          // 0x8A
    public const int FMP_ROMACCESS = FMP_RUNFAIL + 6;              // 0x8B

    public const int FMP_PACKETCRCERROR = 0xAA;
    public const int FMM_UNKNOWN_ERROR = 0xFF;
}
