unit DefScript;


interface

const
    // Sequence ID.
  SEQ_STOP      = 0;
  SEQ_KEY_START = 1;
  SEQ_KEY_STOP  = 2;
  SEQ_KEY_1     = 3;
  SEQ_KEY_2     = 4;
  SEQ_KEY_3     = 5;
  SEQ_KEY_4     = 6;
  SEQ_KEY_5     = 7;
  SEQ_KEY_6     = 8;
  SEQ_KEY_7     = 9;
  SEQ_KEY_8     = 10;
  SEQ_KEY_9     = 11;
  SEQ_KEY_SCAN  = 12;
  SEQ_CAM_ZONE  = 13;
  SEQ_UNLOAD_ZONE = 14;

  SEQ_PRE_STOP  = 15;
  SEQ_REPORT    = 16;
  SEQ_1         = 17;
  SEQ_2         = 18;
  SEQ_3         = 19;
  SEQ_4         = 20;
  SEQ_5         = 21;
  SEQ_6         = 22;
  SEQ_7         = 23;
  SEQ_8         = 24;
  SEQ_9         = 25;
  SEQ_Finish    = 26;

  SEQ_MAINT_1   = 31;
  SEQ_MAINT_2   = 32;
  SEQ_MAINT_3   = 33;
  SEQ_MAINT_4   = 34;
  SEQ_MAINT_5   = 35;

  SEQ_MAX       = SEQ_MAINT_5;


  SEQ_ERR_NONE      = 0;
  SEQ_ERR_RUNNING   = 1;

  DAYA_NONE         = 0;
  DATA_TYPE_HEX     = 1;
  DATA_TYPE_DEC     = 2;
  DATA_TYPE_REAL    = 3;
  DATA_TYPE_STR     = 6;
//  DATA_TYPE_MODE1   = 8;

  REF_IDX_NONE      = 0;
  REF_IDX_MAX       = 1;
  REF_IDX_MIN       = 2;
  REF_IDX_DIFF      = 3;
  REF_IDX_AVR       = 4;
  REF_IDX_DIFF_P2P2 = 5;
  REF_IDX_AVR_JITER = 6;
  REF_IDX_SLOPE_ROW = 7;
  REF_IDX_SLOPE_COL = 8;
  REF_IDX_JIT_DELTA = 9;
  REF_IDX_RAWCS_OPEN  = 11;
  REF_IDX_RAWCS_OPEN2 = 12;
//  REF_IDX_CV5A_OPEN   = 15;
  REF_IDX_GET_CAL     = 20; // frame AIEA Average¡ÍiiAC ¨Ï©ª¢®i¡Ë?e AU¡Íi¡Ë? ¢®¨¡e¢®ieEA ¨Ïoo¡§¢®U¡Ë?¡Ë¢ç AuAa.
  REF_IDX_DOWN_FW     = 30;
  REF_IDX_ID_UPDATE   = 31;
//  REF_IDX_Y3_FLASH_WR = 32;
  REF_IDX_RTY_MODIFY  = 300;

  LIMIT_TYPE_NG           = 0;
  LIMIT_TYPE_IS           = 1;
  LIMIT_TYPE_ISNOT        = 2;
  LIMIT_TYPE_MIN          = 3;
  LIMIT_TYPE_MAX          = 4;
  LIMIT_TYPE_MAXMIN       = 5;
  LIMIT_TYPE_MAXMIN_FLOAT = 6;
  LIMIT_TYPE_MAX_SUB_MIN  = 7;
  LIMIT_TYPE_STR          = 8;
  LIMIT_TYPE_LOG          = 9;
  LIMIT_TYPE_FWVER        = 10;
//  LIMIT_TYPE_SPEC_BY_CSV1 = ;
//  LIMIT_TYPE_SPEC_BY_CSV2 = ;
//---------------------------------------------------------
  FUNC_CALL_START         = 'Func_call::';
	func_call_TxIcInit      = 'Func_call::TxIcInit()'; 	  //TxIcInit                 .mpt
	func_call_Module_on     = 'Func_call::ModuleOn()';    //Module On Code.          .mion
	func_call_Module_off    = 'Func_call::ModuleOff()';   //Module Off Code.         .miOff
	func_call_Power_On      = 'Func_call::PwrOn()';       //Power On Full Init Code. .pwon.
	func_call_Power_Off     = 'Func_call::PwrOff()';      //Power Off Code.          .pwoff.
  func_call_Power_On_Auto = 'Func_call::PwrOn_Auto()';  // Power On Auto Code      .miau

  func_call_Otp_Write     = 'Func_call::OtpWrite()';    // OTP Write Code.          .otpw
  func_call_Otp_Read      = 'Func_call::OtpRead()';     // Otp Read Code.           .otpr
  func_call_ScreenCode    = 'Func_call::ScreenCode()';  // Screen Code              .misc.

  CODE_TXICINIT      = 1;
  CODE_MODULE_ON     = 2;
  CODE_MODULE_OFF    = 3;
  CODE_POWER_ON      = 4;
  CODE_POWER_OFF     = 5;
  CODE_POWER_ON_AUTO = 6;
  CODE_OTP_WRITE     = 7;
  CODE_OTP_READ      = 8;
  CODE_SCR_CODE      = 9;
  CODE_MAX           = CODE_SCR_CODE;

  CMD_ITEM_1        = 'delay.ms';
  CMD_ITEM_2        = 'mipiic.write';
  CMD_ITEM_3        = 'mipi.write';
  CMD_ITEM_4        = 'vbat.on';
  CMD_ITEM_5        = 'vneg.on';
  CMD_ITEM_6        = 'vext.on';
  CMD_ITEM_7        = 'vcc.on';
  CMD_ITEM_8        = 'vlcd.on';
  CMD_ITEM_9        = 'mdm.reset';
  CMD_ITEM_10       = 'lcm.reset';
  CMD_ITEM_11       = 'gpio.on';
  CMD_ITEM_12       = 'gpio.off';
  CMD_ITEM_13       = 'mdm.init';
  CMD_ITEM_14       = 'mipi.on';
  CMD_ITEM_15       = 'vbat.off';
  CMD_ITEM_16       = 'vneg.off';
  CMD_ITEM_17       = 'vext.off';
  CMD_ITEM_18       = 'vcc.off';
  CMD_ITEM_19       = 'vlcd.off';
  CMD_ITEM_20       = 'mipi.read';
  CMD_ITEM_21       = 'mipiic.read';
  CMD_ITEM_22       = 'vel.on';
  CMD_ITEM_23       = 'vel.off';
  CMD_ITEM_24       = 'mdm.deinit';

  CMD_ITEM_25       = 'vci.on';
  CMD_ITEM_26       = 'dvdd.on';
  CMD_ITEM_27       = 'vdd.on';
  CMD_ITEM_28       = 'vpp.on';
  CMD_ITEM_29       = 'vneg.on';

  CMD_ITEM_30       = 'gpio.on';
  CMD_ITEM_31       = 'gpio.off';
  CMD_ITEM_32       = 'mipi.on';
  CMD_ITEM_33       = 'vci.off';
  CMD_ITEM_34       = 'dvdd.off';
  CMD_ITEM_35       = 'vdd.off';
  CMD_ITEM_36       = 'vpp.off';
  CMD_ITEM_37       = 'mipi.off';
  CMD_ITEM_38       = 'touch.model';
  CMD_ITEM_39       = 'mipi.wpacket';
  CMD_ITEM_40       = 'voltage.limit';

  // for PG To Comm.
  // Pascal Script SIG ID.
  PP_SIGID_1        = 1;    // Power
  PP_SIGID_2        = 2;    // Pattern Display
  PP_SIGID_3        = 3;

  // Pascal Script Command - 4th param.
  PP_COMMAD_PWR_OFF = 0;
  PP_COMMAD_PWR_ON  = 1;
  PP_COMMAD_PWR_ON_AUTOCODE  = 2;
  PP_COMMAD_PWR_OFF_RESET = 3;
  PP_COMMAD_PWR_ON_RESET  = 4;

  PP_COMMAD_MES_OFF = 0;
  PP_COMMAD_MES_ON  = 1;
  PP_COMMAD_PAT_GRP = 0;
  PP_COMMAD_PAT_SNG = 1;

  end_func          = '}_end_func';

  ERR_ST_NONE       = 0;
  ERR_ST_SEME       = 1;
implementation

end.
