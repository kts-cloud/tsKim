unit DefCommon;

interface

uses
  Winapi.Messages;

Const


// ISPD_L_OPTIC : ISPD_OPTIC - E5 광학 보상.
// ISPD_A       : ISPD_A     - D818 Model for Apple customer.
// ISPD_L       : ISPD_L     - A1+  Model for LG customer.
// ISPD_POCB    : ISPD_POCB  - E5 #205 Line POCB
// ISPD_OPTIC.exe
  PROGRAM_VER      = 'R1.00';
  PROGRAM_NAME     = 'Inspector OLED Display OC';

  MSG_SCAN_BCR         = 'SCAN BCR';


  TIBServer_MES = 0;
  TIBServer_EAS = 1;
  TIBServer_R2R = 2;
  TIBServer_MAX = TIBServer_EAS + 1;

  PG_CNT                  = 4;

  OCType                  = 0;
  PreOCType               = 1;

  MAX_PG_CNT 							= 4;
  CH_TOP                  = 0;
  CH_BOTTOM               = 1;
  CH_ALL                  = 2;
  JIG_A                   = 0;
  JIG_B                   = 0;
  MAX_JIG_CNT             = 1;
  PG_1                    = 0;
  PG_MAX                  = 3;
  CH1                     = 0;
  CH2                     = 1;
  CH3                     = 2;
  CH4                     = 3;
  CH5                     = 4;
  CH6                     = 5;
  CH7                     = 6;
  CH8                     = 7;
  CH_STAGE_A              = 8;
  CH_STAGE_B              = 9;
  CH_TOPGroup             = 10;
  CH_BOTTOMGroup          = 11;
  CH_ALLGroup             = 12;
  CH1_GIB                 = 0;
  CH2_GIB                 = 1;
  CH3_GIB                 = 2;
  CH4_GIB                 = 3;

  MAX_CH                  = 3;
  MAX_JIG_CH              = 3;
  MAX_CSV_HEADER_ROWS     = 3;
  MAX_CSV_DATA_ROW        = 4;

  MAX_CA_DRIVE_CNT        = 10;

  MAX_PREVIOUS_RESULT     = 2;
  MAX_SYSTEM_LOG          = MAX_PG_CNT;
  MAX_PLC_LOG             = MAX_PG_CNT + 1;
  MAX_CA310_CAL_ITEM      = 4; // White, R, G, B

  IDX_RGB_AVR_TYPE_NONE = 0; // AVERAGE TYPE NOT USE.
  IDX_RGB_AVR_TYPE_A    = 1; // A Type : 1개 부터 Average 계산 순차적으로 Average.
  IDX_RGB_AVR_TYPE_B    = 2; // B Type : Average Count 이후 부터 Average 계산.
  IDX_RGB_AVR_TYPE_C    = 3; // C Type : Average Count 이후 부터 Average 계산. - MIN / MAX 제외. Option 기능 추가.

  MAX_BCR_CNT             = 2;
  MAX_SWITCH_CNT          = 2;

  MAX_IONIZER_CNT         = 2;
//{$IFDEF ISPD_L_OPTIC}
//  {$DEFINE SIMULATOR}
//  {$DEFINE VACCUM_SENSOR}
//{$ENDIF}

//  MAX_DATA_LENGTH_GUI     = 36;
//  MAX_AVR_TIME_CNT        = 5;
//  // Control GUI.
  MAX_GUI_DATA_CNT        = 10;

  IP_LOCAL_ALL            = 0;
  IP_LOCAL_GMES           = 1;
  IP_LOCAL_PLC            = 2;
  IP_PLC_CONFIG_PATH      = 3;
  IP_EM_NUMBER            = 4;

  // Sequence ID.
  SEQ_STOP         = 0;  // Start 1 : bcr or power on.
  SEQ_2             = 1;  // start 2 : bcr or power on.
  SEQ_3         = 2;  //
  SEQ_4         = 3;
  SEQ_END       = 9;  // POWER OFF.

  OC_TABLE_PARAM    = 1;
  OC_TABLE_VERIFY   = 2;
  OC_OTP_TABLE      = 3;
  OC_OFFSET_TABLE   = 4;

  CHECK_CA310_OK = 0;
  CHECK_CA310_NOT_CHECK   = 1;
  CHECK_CA310_USER_CAL_NG = 2;
  CHECK_CA310_PROBE_NG = 3;
//
//  INS_TYPE_NONE = 0;
//  INS_TYPE_WHITE = 1;
//  INS_TYPE_BLACK = 2;
//  INS_TYPE_UNIFORM = 3;
//  INS_TYPE_LUMINANCE = 4;
//
//  // JOB POSITION. : 가상의 Logic이 일하고 있는 곳.
//  JOB_POS_NONE = 1;
//  JOB_POS_LOAD = 2;
//  JOB_POS_CAMERA = 3;
//  JOB_POS_UNLOAD = 4;
//

  LOG_TYPE_OK   = 0;
  LOG_TYPE_NG   = 1;
  LOG_TYPE_INFO = 2;
  // Item Type. 구조체가 달라 재일 먼처 체크 할 필요 있음.
  MSG_TYPE_NONE = 0;
  MSG_TYPE_SCRIPT = 1;
  MSG_TYPE_SWITCH = 2;
  MSG_TYPE_LOGIC  = 3;
  MSG_TYPE_PG     = 4;
  MSG_TYPE_JIG    = 5;
  MSG_TYPE_STAGE   = 6;
  // MSGTYPE_COMMDIO = 101;  in CommDIO_DAE
  MSG_TYPE_DAEIO  = 101;
  MSG_TYPE_CTL_DIO = 102;
  MSG_TYPE_COMM_ECS  = 103;
  MSG_TYPE_EXT_CONTROL  = 1001;

  MSG_TYPE_ADLINK = 7;
  MSG_TYPE_IONIZER  = 8;
  MSG_TYPE_HOST   = 9;
  MSG_TYPE_CAMERA = 10;
  MSG_TYPE_CAM_LIGHT = 11;



  MSG_TYPE_FLOW_DATA_VIEW  = 12;
  MSG_TYPE_JNCD_SW = 13;
  MSG_TYPE_DFS    = 14;

  MSG_TYPE_CA410  = 15;
  MSG_TYPE_DLL    = 16;
  MSG_TYPE_AF9FPGA  = 17;

  MSG_MODE_LOAD = 1;
  MSG_MODE_CAL  = 2;
  MSG_MODE_ADDLOG      = 3;
  MSG_MODE_ADDLOG_CHANNEL = 4;
  MSG_MODE_RESET_ALARM = 5;

    
  MAX_TOUCH_DATA_LENGTH_GUI       = 36;
  PWR_VCI   = 0;
  PWR_DVDD  = 1;
  PWR_VDD   = 2;
  PWR_VPP   = 3;
  PWR_VBAT  = 4;
  PWR_VNEG  = 5;
  PWR_RESET = 6;

  PWR_ELVDD = 0;
  PWR_ELVSS = 1;
  PWR_DDVDH = 2;

  // Message Mode.
  MSG_MODE_DISPLAY_CHANNEL        = 0;
	MSG_MODE_DISPLAY_VOLCUR         = 1;
	MSG_MODE_DISPLAY_ALARM          = 2;
	MSG_MODE_DISPLAY_MODELINFO      = 3;
	MSG_MODE_CONTINUETIMER_ENABLE   = 4;
	MSG_MODE_DISPLAY_RCBDATA     		= 5;

	MSG_MODE_SWITCH_ONOFF   		    = 7;
	MSG_MODE_TEST_HOST 							= 8;
	MSG_MODE_DISPLAY_FLOW						=	9;
	MSG_MODE_DISPLAY_RESULT					=	10;
	MSG_MODE_CH_CLEAR 	  					=	11;
	MSG_MODE_BARCODE_READY	   			=	12;
	MSG_MODE_TACT_START   	   			=	13;
	MSG_MODE_TACT_END     	   			=	14;
	MSG_MODE_FLOW_START   	   			=	15;
	MSG_MODE_FLOW_STOP     	   			=	16;
  MSG_MODE_POWER_ON               = 17;
  MSG_MODE_POWER_OFF              = 18;
	MSG_MODE_NG_CNT		     	   			=	19;
  MSG_MODE_BTN_ENABLE             = 20;
  MSG_MODE_BTN_DISABLE            = 21;
  MSG_MODE_MODEL_DOWN_START       = 22;
  MSG_MODE_MODEL_DOWN_END         = 23;
  MSG_MODE_MODEL_DOWNLOADING      = 24;
  MSG_MODE_FLOW_STOP_REPORT       = 25;
  MSG_MODE_FLOW_DATA_VIEW         = 26;
  MSG_MODE_MAKE_SUMMARY_CSV         = 27;
  MSG_MODE_SEND_GMES              = 28;
  MSG_MODE_SEND_RSTDONE           = 29;

  MSG_MODE_WORK_DONE              = 30;
  MSG_MODE_WORKING                = 31;
  MSG_MODE_LOG_PWR                = 32;
  MSG_MODE_LOG_CSV                = 33;
  MSG_MODE_LOG_ON_GUI             = 35;
  MSG_MODE_DISPLAY_CONNECTION     = 36;
  MSG_MODE_TRANS_DOWNLOAD_STATUS  = 37;
  MSG_MODE_UNIT_TT_START          = 38;
  MSG_MODE_UNIT_TT_END            = 39;
  MSG_MODE_SHOW_SERIAL_NUMBER     = 40;
  MSG_MODE_HOST_RESULT            = 41;

  MSG_MODE_PAT_DISPLAY            = 42;
  MSG_MODE_CH_RESULT              = 43;
  MSG_MODE_CA310_STATUS           = 44;
  MSG_MODE_CA310_NG               = 45;
  MSG_MODE_DIO_SEN_NG             = 46;
  MSG_MODE_DIFF_MODEL             = 47;
  MSG_MODE_CA310_MEASURE          = 48;
  MSG_MODE_DIO_CONTROL            = 49;

  MSG_MODE_TOUCH_INFO             = 50;
  MSG_MODE_TOUCH_RESULT           = 51;

  MSG_MODE_SYNC_WORK              = 52;
  MSG_MODE_FOR_RTY_MAKE_ALL_NG    = 53;
  MSG_MODE_PRODUCT_CNT            = 54;
  MSG_MODE_CA310_ERROR_MSG        = 55;
  MSG_MODE_ANGING_TIME            = 57;

  MSG_MODE_PASS_RGB               = 60;
  MSG_MODE_GET_AVG_RGB            = 61;
  MSG_MODE_SET_SCRIPT_NG          = 62;
  MSG_MODE_FW_CHECK               = 63;

  MSG_MODE_LOG_CSV_SUMMARY        = 64;
  MSG_MODE_LOG_CSV_APDR           = 65;
  MSG_MODE_CAX10_MEM_CH_NO        = 66;

//
//	MSG_CHANNEL_ALL                 = $ff;
//
//  MSG_PARAM_RESULT_READY          = 0;
//  MSG_PARAM_RESULT_OK             = 1;
//  MSG_PARAM_RESULT_NG             = 2;
//
//  SEQ_RESULT_CLEAR          = 1;
//  SEQ_RESULT_PASS           = 2;
//  SEQ_RESULT_FAIL           = 3;
//  SEQ_RESULT_WORKING        = 4;
//
  MAX_MODEL_CGID_CNT      = 100;
//
//
////  MAX_PATTERN_CNT         = 128;  //AllPat.pdat
////  MAX_TOOL_CNT            = 128;
////  MAX_SIMPLE_PAT_CNT      = 7;
//  MAX_BMP_CNT             = 20;
//
//  MAX_TOUCH_TP            = 40;
//  MAX_TOUCH_Model         = 5;
//  MAX_TOUCH_FREQ          = 5;
//  MAX_TOUCH_FRAME         = 50;
		//암호화 작업을 위한 Default Key
		C1				              = 74054;
		C2        			        = 12337;
		HexaChar : array [0..15] of Char =( '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F' );

        //PG
    PG_CONN_DISCONNECTED = 0;
    PG_CONN_CONNECTED    = 2;
    PG_CONN_VERSION      = 3;
    PG_CONN_READY        = 4;
    //
//
//	LCM_OFF                = 0; //LCMTest On/Off
//	LCM_ON                 = 1; //LCMTest On/Off
//
//	DISPLAY_OFF            = 0;
//	DISPLAY_ON             = 1;
//
//  PG_CONNECT       = 0;
//	PG_DISCONNECT    = 1;
//
//
//
//{F/W Download Status}
//	DATA_DOWNLOAD_START        = 0; //PROGRAM, BMP
//	DATA_DOWNLOAD              = 1;
//	DATA_FUSING                = 2;
//	DATA_FUSING_END            = 3;
//	FUSING_TYPE_PANEL_FW_hex   = 4;  //Touch Panel FW_hex
//	FUSING_TYPE_PANEL_FW_img   = 5;  //Touch Panel FW_img
//
//
//	FW_DOWNLOAD_START      = 0; //FW, FPGA
//	FW_DOWNLOAD            = 1;
//	FW_RESET               = 2;
//
//
//{DownTypeTabControl.TabIndex }
	DOWNLOAD_TYPE_BMP         = 0;
	DOWNLOAD_TYPE_PRG         = 1;
	DOWNLOAD_TYPE_PG_FPGA     = 2;
	DOWNLOAD_TYPE_PG_FW       = 3;
  DOWNLOAD_TYPE_PALLET_FPGA = 4;
	DOWNLOAD_TYPE_PALLET_FW   = 5;
//	DOWNLOAD_TYPE_IF_FW       = 6;
	DOWNLOAD_TYPE_TOUCH_FW    = 6;
	DOWNLOAD_TYPE_PANEL_FW_hex= 7;
//
//{Simple Pattern Kind}
//	SIMPLE_PAT_RASTER     = 1;
//  SIMPLE_PAT_GRAY       = 2;
//  SIMPLE_PAT_RGBW       = 3;
//  SIMPLE_PAT_LINEONOFF  = 4;
//  SIMPLE_PAT_PIXELONOFF = 5;
//  SIMPLE_PAT_FLICKER    = 6;
//  SIMPLE_PAT_CINEMA     = 7;
//	SIMPLE_PAT_CHESSBOARD = 8;
//{Simple Pattern List}
//  RASTER_PATTERN_NAME      = 'SIMPLE_RASTER.spt';
//  GRAY_PATTERN_NAME        = 'SIMPLE_GRAY.spt';
//  RGBW_PATTERN_NAME        = 'SIMPLE_RGBW_GRAY.spt';
//  LINEONOFF_PATTERN_NAME   = 'SIMPLE_LINE_ONOFF.spt';
//  PIXELONOFF_PATTERN_NAME  = 'SIMPLE_PIXEL_ONOFF.spt';
//  FLICKER_PATTERN_NAME     = 'SIMPLE_FLICKER.spt';
//  CINEMA_PATTERN_NAME      = 'SIMPLE_CINEMA.spt';
//
  MODEL_PATH             = 0;
  PATRN_PATH             = 1;
	PATGR_PATH             = 2;
	SCRIPT_PATH_ISU        = 3;
  SCRIPT_PATH_PSU        = 4;
//	INIT1_PATH             = 4;
//	INIT2_PATH             = 5;
//	INIT3_PATH             = 6;
//	INIT4_PATH             = 7;
//
//{Pattern Preview}
//  PAT_PREVIEW_H       = 400;
//  PAT_PREVIEW_V       = 300;
//  SCR_PREVIEW_H       = 400;
//  SCR_PREVIEW_V       = 300;
//
//{Pattern Type} //일반패턴, 이미지, 동영상
  PTYPE_NORMAL           = 0;   //일반패턴
  PTYPE_BITMAP           = 1;   //BMP
  PTYPE_NONE             = $ff; //Initial
//
//	{Temperature Control kind}
//  TEMP_NONE       = 0;
//  TEMP_ST580      = 1; //LGD PJ MTV AGING 4x4EA사용, NJ STARION 2EA
//  TEMP_TEMP2500   = 2;
//  TEMP_SP790      = 3;
//  TEMP_TEMP880    = 4;
//	sTEMP_KIND : array[0..4] of String =
//		( 'NONE', 'ST-580', 'TEMP-2500', 'SP-790', 'TEMP-880' );
//	COMBUFF           = 511;
//	MAX_TEMP_CNT        = 3;
//
//{Common Protocol}
//  STX             = #02;
//	ETX             = #03;
//	CR              = #13;
//  LF              = #10;
//	CRLF            = #13#10;
//	RCB_STX         = '[';
//	RCB_ETX         = ']';
//
//{FPAG Timing}
//  FPGA_TIME_DUAL         = 0;
//  FPGA_TIME_QUAD         = 1;
//
//	OFF_REQ                = 0; //Channel On/Off, Switch
//	ON_REQ                 = 1; //Channel On/Off, Switch
//
  CRC16POLY              = $8408;
//
//
//
//  // RCB KEY (DR210A)
//  RKEY_INI         = '0'; //RCB Alive and Initial
//  RKEY_SUB         = 'B'; //Subsystem selection
//  RKEY_BLK         = 'C'; //Block selection
//  RKEY_UP          = 'U'; //Gray Up
//  RKEY_DN          = 'D'; //Gray Down
//  RKEY_LT          = 'L'; //Pattern Backward
//  RKEY_RT          = 'R'; //Pattern Forward
//  RKEY_DEL         = 'G'; //Subsystem, Block Cancel->F.G ->B.G
//  RKEY_SET         = 'X'; //Subsystem, Block Setting(Position Off) -> Position On
//  RKEY_AM          = 'A'; //Auto, Manual
//  RKEY_ON          = 'S'; //Start, Stop
//  RKEY_CON         = 'Y'; //Continue Key
//	RKEY_CLS         = 'Z'; //Stop Continue Key
//
//  RPOSITION_OFF    = 0; // RKEY_SET사용
//  RPOSITION_ON_W   = 1; // RKEY_SET사용 + 커서W
//  RPOSITION_ON_R   = 2; // RKEY_SET사용 + 커서R
//  RPOSITION_ON_G   = 3; // RKEY_SET사용 + 커서G
//  RPOSITION_ON_B   = 4; // RKEY_SET사용 + 커서B
//	RPOSITION_PWM    = 5; // RKEY_SET사용
//
//  INC_VALUE        = 0;  // gray or gamma value increase
//  DEC_VALUE        = 1;  // gray or gamma value decrease
//  RCB_FWD          = 2;  // Pattern forward
//  RCB_BWD          = 3;  // Pattern Backward
//  H_POS            = 0;
//	V_POS            = 1;
//
//  MAX_GRAY         = 255;   //Default BIT8
//	MIN_GRAY         = -255;  //Default BIT8
//
//	PALLET_FG        = 0; // RKEY_DEL사용, Foreground
//	PALLET_BG        = 1; // RKEY_DEL사용, Background
//
//  C_GRAY           = 0;
//  C_CURSOR         = 1;
//	C_GAMMA          = 2;
//
//	MAX_RECODER_CH   = 6;
//
//  UI_NORMAL           = 0;
//	UI_BLACK            = 1;
	UI_WIN10_NOR        = 0;
  UI_WIN10_BLACK      = 1;
//
//  LANGUAGE_ENGLISH    = 0;
//  LANGUAGE_VIETNAM    = 1;
//
//	POWER_ON            = 1;
//	POWER_OFF           = 0;

  //Stage 작업 Step
  STAGE_STEP_NONE                = 0;
  STAGE_STEP_LOADING             = STAGE_STEP_NONE + 1;
  STAGE_STEP_LOADING_FINISH      = STAGE_STEP_NONE + 2;
  STAGE_STEP_LOADZONE            = STAGE_STEP_NONE + 3;
  STAGE_STEP_LOADZONE_FINISH     = STAGE_STEP_NONE + 4;
  STAGE_STEP_TURNING_CAM         = STAGE_STEP_NONE + 5;
  STAGE_STEP_CAMZONE             = STAGE_STEP_NONE + 6;
  STAGE_STEP_CAMZONE_FINISH      = STAGE_STEP_NONE + 7;
  STAGE_STEP_TURNING_UNLOAD      = STAGE_STEP_NONE + 8;
  STAGE_STEP_UNLOADZONE          = STAGE_STEP_NONE + 9;
  STAGE_STEP_UNLOADZONE_FINISH   = STAGE_STEP_NONE + 10;
  STAGE_STEP_UNLOADING           = STAGE_STEP_NONE + 11;
  STAGE_STEP_EXCHANGE            = STAGE_STEP_NONE + 12;

  STAGE_STEP_OTHER_SCRIPT_RUN    = STAGE_STEP_NONE + 13;
  STAGE_STEP_OTHER_SCRIPT_FINISH = STAGE_STEP_NONE + 14;

  DEBUG_LOG_MSGTYPE_INSPECT    = 1;
  DEBUG_LOG_MSGTYPE_CONNCHECK  = 2;
  DEBUG_LOG_MSGTYPE_DOWNDATA   = 3;
  DEBUG_LOG_MSGTYPE_MAX        = DEBUG_LOG_MSGTYPE_DOWNDATA;

  DEBUG_LOG_LEVEL_CONFIG_INI        = -1; // set to SystemConfig.DEBUG
  DEBUG_LOG_LEVEL_NONE              = 0;  // None
  DEBUG_LOG_LEVEL_INSPECT           = 1;  // INSPECT/POWERCHECK
  DEBUG_LOG_LEVEL_INSPECT_CONNCHECK = 2;  // INSPECT/POWERCHECK + CONNCHECK
  DEBUG_LOG_LEVEL_DOWNDATA          = 3;  // N/A
  DEBUG_LOG_LEVEL_MAX               = DEBUG_LOG_MSGTYPE_DOWNDATA;

type

{$IFNDEF GUIMESSAGE}
  {$DEFINE GUIMESSAGE}
  /// <summary> GUI Message for WM_COPYDATA </summary>
  TGUIMessage = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param  : Integer;
    Param2 : Integer;
    Msg     : string;
    pData   : PBYTE; //Pointer; //Length = Param2
  end;
  PGUIMessage = ^TGUIMessage;
{$ENDIF}
implementation

end.

