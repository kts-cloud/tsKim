namespace Dongaeltek.ITOLED.Core.Definitions;

/// <summary>
/// PLC communication constants. Converted from defPlc.pas.
/// The original uses {$IFDEF ISPD_POCB} for two configurations.
/// In C#, we use the non-POCB (ECS) variant which is the active config for X3584.
/// </summary>
public static class DefPlc
{
    // PLC read/write address indices
    public const int IDX_PLC_READ_1 = 1;    // Read Stage A address
    public const int IDX_PLC_READ_2 = 2;    // Read Stage B address
    public const int IDX_PLC_WRITE_1 = 3;   // Write Stage A address
    public const int IDX_PLC_WRITE_2 = 4;   // Write Stage B address

    public const int IDX_FIRST_WORD = 0;
    public const int IDX_SECOND_WORD = 1;

    // Input signal bit masks
    public const int IN_PLC_READY = 0x0001;
    public const int IN_LOAD_DONE_CH1 = 0x0010;
    public const int IN_LOAD_DONE_CH2 = 0x0020;
    public const int IN_LOAD_DONE_CH3 = 0x0040;
    public const int IN_LOAD_DONE_CH4 = 0x0080;
    public const int IN_LOT_DONE = 0x0400;
    public const int IN_PAUSE_PROBE = 0x0800;
    public const int IN_UNLOAD_DONE_CH1 = 0x1000;
    public const int IN_UNLOAD_DONE_CH2 = 0x2000;
    public const int IN_UNLOAD_DONE_CH3 = 0x4000;
    public const int IN_UNLOAD_DONE_CH4 = 0x8000;

    // Output signal bit masks (word 1)
    public const int OUT_PC_READY = 0x0001;
    public const int OUT_BLINK_PC = 0x0002;
    public const int OUT_PROBE_BACK = 0x0008;
    public const int OUT_SEL_CH1 = 0x0020;
    public const int OUT_SEL_CH2 = 0x0040;
    public const int OUT_SEL_CH3 = 0x0080;
    public const int OUT_SEL_CH4 = 0x0100;
    public const int OUT_REQ_LOAD = 0x0200;
    public const int OUT_CONFIRM_DONE = 0x0400;
    public const int OUT_REQ_UNLOAD = 0x0800;
    public const int OUT_RESULT_NG_CH1 = 0x1000;
    public const int OUT_RESULT_NG_CH2 = 0x2000;
    public const int OUT_RESULT_NG_CH3 = 0x4000;
    public const int OUT_RESULT_NG_CH4 = 0x8000;

    // Output signal bit masks (word 2)
    public const int OUT_READY_CH1 = 0x0001;
    public const int OUT_READY_CH2 = 0x0002;
    public const int OUT_READY_CH3 = 0x0004;
    public const int OUT_READY_CH4 = 0x0008;
    public const int OUT_DETECT_CH1 = 0x0100;
    public const int OUT_DETECT_CH2 = 0x0200;
    public const int OUT_DETECT_CH3 = 0x0400;
    public const int OUT_DETECT_CH4 = 0x0800;

    // Input signal bit indices
    public const int IDX_IN_PLC_READY = 0;
    public const int IDX_IN_COMPLETE_1 = 4;
    public const int IDX_IN_COMPLETE_2 = 5;
    public const int IDX_IN_COMPLETE_3 = 6;
    public const int IDX_IN_COMPLETE_4 = 7;
    public const int IDX_IN_LOT_FINISH = 10;
    public const int IDX_IN_PAUSE_PROBE = 11;
    public const int IDX_IN_UNLOADED_1 = 12;
    public const int IDX_IN_UNLOADED_2 = 13;
    public const int IDX_IN_UNLOADED_3 = 14;
    public const int IDX_IN_UNLOADED_4 = 15;

    // Output signal bit indices (word 1)
    public const int IDX_OUT_PC_READY = 0;
    public const int IDX_OUT_BLINK = 1;
    public const int IDX_OUT_CA310_BACK_1 = 3;
    public const int IDX_OUT_CA310_BACK_2 = 4;
    public const int IDX_OUT_SEL_CH_1 = 5;
    public const int IDX_OUT_SEL_CH_2 = 6;
    public const int IDX_OUT_SEL_CH_3 = 7;
    public const int IDX_OUT_SEL_CH_4 = 8;
    public const int IDX_OUT_LOAD_REQ = 9;
    public const int IDX_OUT_UNLOAD_REQ = 10;
    public const int IDX_OUT_COMPLETE = 11;
    public const int IDX_OUT_NG_CH1 = 12;
    public const int IDX_OUT_NG_CH2 = 13;
    public const int IDX_OUT_NG_CH3 = 14;
    public const int IDX_OUT_NG_CH4 = 15;

    // Output signal bit indices (word 2)
    public const int IDX_OUT_READY_1 = 0;
    public const int IDX_OUT_READY_2 = 1;
    public const int IDX_OUT_READY_3 = 2;
    public const int IDX_OUT_READY_4 = 3;

    // Data sizes
    public const int MAX_INPUT_CNT = 16;
    public const int MAX_OUT_CNT = 32;
    public const int MAX_NOR_DATA_SIZE = 1;
    public const int MAX_WRITE_DATA_SIZE = 2;
}

/// <summary>
/// PLC constants for POCB variant (kept for reference if needed at runtime).
/// </summary>
public static class DefPlcPocb
{
    public const int PLC_READ_TYPE_FIRST = 0;
    public const int PLC_READ_TYPE_MAINT = 1;
    public const int PLC_READ_TYPE_RUN = 2;

    public const int PLC_MANU_READY_SW1 = 0;

    public const int MAX_IN_CNT = 64;
    public const int MAX_OUT_CNT = 64;

    public const int MAX_MAINT_DATA_SIZE = 3;
    public const int MAX_NOR_DATA_SIZE = 3;
    public const int MAX_MODEL_DATA_CNT = 1;
    public const int MAX_WRITE_DATA_SIZE = 2;
    public const int MAX_ALARM_DATA_SIZE = 7;

    public const string PLC_MAINT_ADDR = "R500";
    public const string PLC_NOR_ADDR = "D1300";
    public const string PLC_WRITE_ADDR = "D1200";
    public const string PLC_ALARM = "D1320";
    public const string PLC_JIG_TACT = "D1316";

    public const int PLC_WRITE_PC_READY = 0x01;
    public const int PLC_WRITE_PC_ALARM = 0x02;
    public const int PLC_WRITE_TURN_CMD = 0x04;
    public const int PLC_WRITE_VISUAL_INSPECT = 0x08;

    public const int PLC_WRITE_NG_RET_CH1 = 0x100;
    public const int PLC_WRITE_NG_RET_CH2 = PLC_WRITE_NG_RET_CH1 << 1;

    public const int PLC_WRITE_CLAMP_ON_CH1 = 0x010000;
    public const int PLC_WRITE_CLAMP_ON_CH2 = 0x020000;
    public const int PLC_WRITE_CLAMP_ON_CH3 = 0x040000;
    public const int PLC_WRITE_CLAMP_ON_CH4 = 0x080000;
    public const int PLC_WRITE_CLAMP_ON_CH5 = 0x100000;
    public const int PLC_WRITE_CLAMP_ON_CH6 = 0x200000;
    public const int PLC_WRITE_CLAMP_ON_CH7 = 0x400000;
    public const int PLC_WRITE_CLAMP_ON_CH8 = 0x800000;
    public const int PLC_WRITE_ABB_AUTO_MODE = 0x1000000;

    public const int PLC_WRITE_CLAMP_ON_A = PLC_WRITE_CLAMP_ON_CH1 | PLC_WRITE_CLAMP_ON_CH2 | PLC_WRITE_CLAMP_ON_CH3 | PLC_WRITE_CLAMP_ON_CH4;
    public const int PLC_WRITE_CLAMP_ON_B = PLC_WRITE_CLAMP_ON_CH5 | PLC_WRITE_CLAMP_ON_CH6 | PLC_WRITE_CLAMP_ON_CH7 | PLC_WRITE_CLAMP_ON_CH8;

    public const int PLC_READ_PLC_READY = 0x01;
    public const int PLC_READ_ERROR = 0x02;
    public const int PLC_READ_TURN_MOVE = 0x04;
    public const int PLC_READ_TURN_DONE = 0x08;
    public const int PLC_READ_JIG_A_FRONT_POS = 0x10;
    public const int PLC_READ_JIG_B_FRONT_POS = 0x20;
    public const int PLC_READ_SHUTTER_DOWN = 0x40;
    public const int PLC_READ_SHUTTER_UP = 0x80;
    public const int PLC_READ_AUTO_START_REQ = 0x0100;
    public const int PLC_READ_ABB_MODE = 0x0200;

    public const int PLC_READ_CH1_CLAMP_OK = 0x010000;
    public const int PLC_READ_CH2_CLAMP_OK = 0x020000;
    public const int PLC_READ_CH3_CLAMP_OK = 0x040000;
    public const int PLC_READ_CH4_CLAMP_OK = 0x080000;
    public const int PLC_READ_CH5_CLAMP_OK = 0x100000;
    public const int PLC_READ_CH6_CLAMP_OK = 0x200000;
    public const int PLC_READ_CH7_CLAMP_OK = 0x400000;
    public const int PLC_READ_CH8_CLAMP_OK = 0x800000;

    public const uint PLC_READ_CH1_JOB_EXIST = 0x01000000;
    public const uint PLC_READ_CH2_JOB_EXIST = 0x02000000;
    public const uint PLC_READ_CH3_JOB_EXIST = 0x04000000;
    public const uint PLC_READ_CH4_JOB_EXIST = 0x08000000;
    public const uint PLC_READ_CH5_JOB_EXIST = 0x10000000;
    public const uint PLC_READ_CH6_JOB_EXIST = 0x20000000;
    public const uint PLC_READ_CH7_JOB_EXIST = 0x40000000;
    public const uint PLC_READ_CH8_JOB_EXIST = 0x80000000;

    public const int PLC_READ_CLMP_ON_CH1 = 0x01;
    public const int PLC_READ_JOB_EXIST_CH1 = 0x0100;

    public const string ADDR_JIG_TACT = "D1310";
    public const string ADDR_Z_MODEL_GET = "R570";
    public const string ADDR_USE_CH = "M400";
    public const string ADDR_Z_MODEL_SET = "D330";

    public const int IDX_USE_CH1 = 0;
    public const int OUT_BLINK_PC = 0x0002;
}
