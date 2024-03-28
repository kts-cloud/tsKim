unit defPlc;

interface
  const
{$IFDEF ISPD_POCB}
    PLC_READ_TYPE_FIRST = 0;
    PLC_READ_TYPE_MAINT = 1;
    PLC_READ_TYPE_RUN   = 2;


    PLC_MANU_READY_SW1  = 0;

    MAX_IN_CNT    = 64;
    MAX_OUT_CNT   = 64;

    MAX_MAINT_DATA_SIZE = 3;
    MAX_NOR_DATA_SIZE   = 3;
    MAX_MODEL_DATA_CNT  = 1;
    MAX_WRITE_DATA_SIZE = 2;
    MAX_ALARM_DATA_SIZE = 7;

    PLC_MAINT_ADDR   = 'R500';
    PLC_NOR_ADDR     = 'D1300';
    PLC_WRITE_ADDR   = 'D1200';
    PLC_ALARM        = 'D1320';
    PLC_JIG_TACT     = 'D1316';

//    PLC_WRITE_SKIP_TURN = $02; // 신호 바뀌어 임시 교체
//    PLC_WRITE_PASS_TURN = $01; // 신호 바뀌어 임시 교체
    PLC_WRITE_PC_READY      = $01;
    PLC_WRITE_PC_ALARM        = $02;
    PLC_WRITE_TURN_CMD        = $04;
    PLC_WRITE_VISUAL_INSPECT  = $08;
    //10 20 40 80


    PLC_WRITE_NG_RET_CH1      = $100;
    PLC_WRITE_NG_RET_CH2      = PLC_WRITE_NG_RET_CH1 shl 1;

    PLC_WRITE_CLAMP_ON_CH1    = $010000;
    PLC_WRITE_CLAMP_ON_CH2    = $020000;
    PLC_WRITE_CLAMP_ON_CH3    = $040000;
    PLC_WRITE_CLAMP_ON_CH4    = $080000;
    PLC_WRITE_CLAMP_ON_CH5    = $100000;
    PLC_WRITE_CLAMP_ON_CH6    = $200000;
    PLC_WRITE_CLAMP_ON_CH7    = $400000;
    PLC_WRITE_CLAMP_ON_CH8    = $800000;
    PLC_WRITE_ABB_AUTO_MODE   = $1000000;

    PLC_WRITE_CLAMP_ON_A = PLC_WRITE_CLAMP_ON_CH1 or PLC_WRITE_CLAMP_ON_CH2 or PLC_WRITE_CLAMP_ON_CH3 or PLC_WRITE_CLAMP_ON_CH4;
    PLC_WRITE_CLAMP_ON_B = PLC_WRITE_CLAMP_ON_CH5 or PLC_WRITE_CLAMP_ON_CH6 or PLC_WRITE_CLAMP_ON_CH7 or PLC_WRITE_CLAMP_ON_CH8;

    PLC_READ_PLC_READY      = $01;
    PLC_READ_ERROR          = $02;

    PLC_READ_TURN_MOVE      = $04;
    PLC_READ_TURN_DONE      = $08;
    PLC_READ_JIG_A_FRONT_POS  = $10;
    PLC_READ_JIG_B_FRONT_POS  = $20;
    PLC_READ_SHUTTER_DOWN   = $40;
    PLC_READ_SHUTTER_UP     = $80;
    PLC_READ_AUTO_START_REQ = $0100;
    PLC_READ_ABB_MODE       = $0200;

    PLC_READ_CH1_CLAMP_OK   = $010000;
    PLC_READ_CH2_CLAMP_OK   = $020000;
    PLC_READ_CH3_CLAMP_OK   = $040000;
    PLC_READ_CH4_CLAMP_OK   = $080000;
    PLC_READ_CH5_CLAMP_OK   = $100000;
    PLC_READ_CH6_CLAMP_OK   = $200000;
    PLC_READ_CH7_CLAMP_OK   = $400000;
    PLC_READ_CH8_CLAMP_OK   = $800000;
    PLC_READ_CH1_JOB_EXIST  = $01000000;
    PLC_READ_CH2_JOB_EXIST  = $02000000;
    PLC_READ_CH3_JOB_EXIST  = $04000000;
    PLC_READ_CH4_JOB_EXIST  = $08000000;
    PLC_READ_CH5_JOB_EXIST  = $10000000;
    PLC_READ_CH6_JOB_EXIST  = $20000000;
    PLC_READ_CH7_JOB_EXIST  = $40000000;
    PLC_READ_CH8_JOB_EXIST  = $80000000;


    PLC_READ_CLMP_ON_CH1    = $01;
    PLC_READ_JOB_EXIST_CH1  = $0100;

    ADDR_JIG_TACT           = 'D1310';

    ADDR_Z_MODEL_GET        = 'R570'; // 설정된 Model 정보 for Z-Axis.

    ADDR_USE_CH             = 'M400';  // bit
    ADDR_Z_MODEL_SET        = 'D330';

    IDX_USE_CH1             = 0;
    OUT_BLINK_PC        = $0002;

{$ELSE}

  IDX_PLC_READ_1    = 1;     // Read Stage A address.
  IDX_PLC_READ_2    = 2;     // Read Stage B address.
  IDX_PLC_WRITE_1   = 3;     // Write Stage A address.
  IDX_PLC_WRITE_2   = 4;     // Write Stage B address.

  IDX_FIRST_WORD    = 0;
  IDX_SECOND_WORD   = 1;

    // ISPD_OPTIC.exe and ...
    IN_PLC_READY        = $0001;// $0; 1,2,4,8
    IN_LOAD_DONE_CH1    = $0010;//$4;
    IN_LOAD_DONE_CH2    = $0020;//$5;
    IN_LOAD_DONE_CH3    = $0040;//$6;
    IN_LOAD_DONE_CH4    = $0080;//$7;

    IN_LOT_DONE         = $0400;//$A;
    IN_PAUSE_PROBE      = $0800;//$B;
    IN_UNLOAD_DONE_CH1  = $1000;//$C;
    IN_UNLOAD_DONE_CH2  = $2000;//$D;
    IN_UNLOAD_DONE_CH3  = $4000;//$E;
    IN_UNLOAD_DONE_CH4  = $8000;//$F;


    OUT_PC_READY        = $0001; // PC Ready.
    OUT_BLINK_PC        = $0002;
    OUT_PROBE_BACK      = $0008;
    OUT_SEL_CH1         = $0020;
    OUT_SEL_CH2         = $0040;
    OUT_SEL_CH3         = $0080;
    OUT_SEL_CH4         = $0100;
    OUT_REQ_LOAD        = $0200;
    OUT_CONFIRM_DONE    = $0400;
    OUT_REQ_UNLOAD      = $0800;
    OUT_RESULT_NG_CH1   = $1000;
    OUT_RESULT_NG_CH2   = $2000;
    OUT_RESULT_NG_CH3   = $4000;
    OUT_RESULT_NG_CH4   = $8000;

    OUT_READY_CH1       = $0001;
    OUT_READY_CH2       = $0002;
    OUT_READY_CH3       = $0004;
    OUT_READY_CH4       = $0008;
    OUT_DETECT_CH1      = $0100;
    OUT_DETECT_CH2      = $0200;
    OUT_DETECT_CH3      = $0400;
    OUT_DETECT_CH4      = $0800;


    IDX_IN_PLC_READY    = 0;
    IDX_IN_COMPLETE_1   = 4;  // 공급완료.
    IDX_IN_COMPLETE_2   = 5;
    IDX_IN_COMPLETE_3   = 6;
    IDX_IN_COMPLETE_4   = 7;
    IDX_IN_LOT_FINISH   = 10;
    IDX_IN_PAUSE_PROBE  = 11;
    IDX_IN_UNLOADED_1   = 12;
    IDX_IN_UNLOADED_2   = 13;
    IDX_IN_UNLOADED_3   = 14;
    IDX_IN_UNLOADED_4   = 15;

    IDX_OUT_PC_READY      = 0;
    IDX_OUT_BLINK         = 1;
    IDX_OUT_CA310_BACK_1  = 3;
    IDX_OUT_CA310_BACK_2  = 4;
    IDX_OUT_SEL_CH_1      = 5;
    IDX_OUT_SEL_CH_2      = 6;
    IDX_OUT_SEL_CH_3      = 7;
    IDX_OUT_SEL_CH_4      = 8;
    IDX_OUT_LOAD_REQ      = 9;
    IDX_OUT_UNLOAD_REQ    = 10;
    IDX_OUT_COMPLETE      = 11;
    IDX_OUT_NG_CH1        = 12;
    IDX_OUT_NG_CH2        = 13;
    IDX_OUT_NG_CH3        = 14;
    IDX_OUT_NG_CH4        = 15;

    IDX_OUT_READY_1       = 0;
    IDX_OUT_READY_2       = 1;
    IDX_OUT_READY_3       = 2;
    IDX_OUT_READY_4       = 3;

    MAX_INPUT_CNT     = 16;
    MAX_OUT_CNT       = 32;

    MAX_NOR_DATA_SIZE = 1;
    MAX_WRITE_DATA_SIZE = 2;

{$ENDIF}
implementation





end.
