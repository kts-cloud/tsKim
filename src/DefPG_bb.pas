unit DefPG;

interface

const
{Command Ack/Nak Chaeck}
  CMD_READY               = $01;
  CMD_RESULT_ACK          = $06;
	CMD_RESULT_NAK          = $15;
	UDP_BUF_SIZE            = 512;
	UDP_DEFAULT_PORT        = 6889;
//  REV_DATA_BUFF           = 10000;

  MAX_FRAME_SIZE          = 1116; // 31 x 18 x 2 = 1116 ==> 여유 버퍼 1200.
  MAX_FRAME_COUNT         = 60; // 2016 10 25 현재 Max 50 Frame. 여유 버퍼 10만 더주자.
  RX_NR           = 0;
  RX_ACK          = 4;
  RX_NAK          = 5;
  RX_EXP          = 6;

{Firmware Packet Size}
	PACKET_SIZE             = 1024;//1024;
	TCP_BUF_SIZE      			= 1023;   //TCP/IP용 Buffer Size

  // code Download  For Fusing.
	TRANS_TYPE_BMP            = 1;
	TRANS_TYPE_TXIC           = 2;  // .mpt
	TRANS_TYPE_MODULE_ON      = 3;  // .mion
	TRANS_TYPE_MODULE_OFF     = 4;  // .mioff
	TRANS_TYPE_PWR_ON         = 5;  // .pwon
  TRANS_TYPE_PWR_OFF        = 6;  // .pwoff
  TRANS_TYPE_PWR_ON_AUTO    = 7;  // .miau
  TRANS_TYPE_OTP_WRITE      = 8;  // .otpw
  TRANS_TYPE_OTP_READ       = 9;  // .otpr
  TRANS_TYPE_SCREEN_CODE    = 10; // .misc
  TRANS_TYPE_PAT_INFO       = 11;


  // code download for fw download.
  FUSING_TYPE_PG_FPGA        = 0;
  FUSING_TYPE_PG_FW          = 1;
	FUSING_TYPE_TOUCH_FW       = 3;  //Touch FW

  FUSING_MODE_START           = 1;
  FUSING_MODE_END             = 2;
  FUSING_MODE_DOWNLOAD        = 3;

  FW_VER_LEN              = 16;

  DATA_POS_FIRST          = 6;
{pc -> pg protocol}
	SIG_FIRST_CONNREQ      = $0001; //PG->PC First Connection Inform.
  SIG_CONCHECKREQ        = $0002; //PC->PG
  SIG_CONCHECKACK        = $0003; //PG->PC
  SIG_MODELINFO          = $0012;
  SIG_MODELINFO_ACK      = $0013;
  SIG_PATTERN_LOAD       = $0024;
  SIG_PATTERN_LOAD_ACK   = $0025;
  SIG_FUSING             = $0026;          // Added by modong 2015-06-01 : BMP, INIT/OFFCODE
	SIG_FUSING_ACK         = $0027;

  SIG_ENABLE_VOLTSET     = $0086;
  SIG_ENABLE_VOLTSET_ACK = $0087;
  SIG_CHANGE_VOLTSET     = $0034;
  SIG_CHANGE_VOLTSET_ACK = $0035;

  SIG_SET_COLOR          = $0040;
	SIG_SET_COLOR_ACK      = $0041;
	SIG_SET_POSITION_MODE  = $0042;
	SIG_SET_FREQUENCY      = $0044;
	SIG_SET_FREQUENCY_ACK  = $0045;
	SIG_SET_PWM            = $0046;
	SIG_SET_PWM_ACK        = $0047;
	SIG_PWR_ON       			 = $0048;
	SIG_PWR_ON_ACK   			 = $0049;
	SIG_DISPLAY_PATTERN    = $0050;
	SIG_DISPLAY_PATTERN_ACK= $0051;
  SIG_SINGLE_PATTERN     = $0054;
	SIG_SINGLE_PATTERN_ACK = $0055;
  SIG_ERR_FLAG_CHECK     = $0056;
  SIG_ERR_FLAG_CHECK_ACK = $0057;
  SIG_PATTERN_ROLL       = $0058;
  SIG_PATTERN_ROLL_ACK   = $0059;
  SIG_MIPI_IC_WRITE_REQ  = $0060;
  SIG_MIPI_IC_WRITE_ACK  = $0061;
	SIG_GPIO_SET           = $0062;
	SIG_GPIO_SET_ACK       = $0063;
	SIG_I2C_WRITE          = $0064;
	SIG_I2C_WRITE_ACK      = $0065;
  SIG_I2C_READ           = $0066;
  SIG_I2C_READ_ACK       = $0067;
  SIG_MIPI_CLK_REQ       = $006C;
  SIG_MIPI_CLK_REV       = $006D;
  SIG_MIPI_WRITE         = $006E;
	SIG_MIPI_WRITE_ACK     = $006F;
  SIG_MIPI_READ          = $0070;
	SIG_MIPI_READ_ACK      = $0071;
//	SIG_GPIO_READ          = $006C;
//	SIG_GPIO_READ_ACK      = $006D;
//	SIG_MIPI_NVM_FULL_READ = $0070;
//	SIG_MIPI_NVM_FULL_READ_ACK = $0071;
//	SIG_MIPI_MODE_RESET    = $0072;
//	SIG_MIPI_MODE_RESET_ACK= $0073;
  SIG_OTP_WRITE          = $0072;
  SIG_OTP_WRITE_ACK      = $0073;
  SIG_OTP_READ           = $0074;
  SIG_OTP_READ_ACK       = $0075;
//	SIG_TOUCH_VERSION_REQ  = $0074;
//	SIG_TOUCH_VERSION_ACK  = $0075;
//	SIG_ICT_TEST_REQ       = $0076;
//	SIG_ICT_TEST_ACK       = $0077;
	SIG_TOUCH_REQ					 = $0078;
	SIG_TOUCH_ACK     		 = $0079;
	SIG_TOUCH_FW_DOWN  		 = $007A;
	SIG_TOUCH_FW_DOWN_ACK	 = $007B;
	SIG_TOUCH_RESULT   		 = $007C;
  SIG_MIPI_WRITE_HS      = $007E;
  SIG_MIPI_WRITE_HS_ACK  = $007F;
  SIG_FLASH_READ         = $007E;
  SIG_FLASH_READ_ACK     = $007F;
	SIG_CHANNEL_ONOFF      = $0080;
	SIG_CHANNEL_ONOFF_ACK  = $0081;
	SIG_READ_VOLTCUR       = $0082;
	SIG_READ_VOLTCUR_ACK   = $0083;
	SIG_POWERCMD_SET       = $0084;
	SIG_POWERCMD_SET_ACK   = $0085;
	SIG_CHANNEL_NG         = $0086;
	SIG_CHANNEL_NG_ACK     = $0087;
	SIG_PWM_DISCHARGE      = $0088;
	SIG_PWM_DISCHARGE_ACK  = $0089;
  SIG_ID_UPDATE          = $008A;
  SIG_ID_UPDATE_ACK      = $008B;
	SIG_PG_RESET           = $0090;
	SIG_PG_RESET_ACK       = $0091;
	SIG_ALARM_REPORT       = $00a1; //PG->PC
  SIG_POCB_DOWN_REQ      = $00a2;
  SIG_POCB_DOWN_ACK      = $00a3;
  SIG_POCB_DATA_W_REQ    = $00a4;
  SIG_POCB_DATA_W_REV    = $00a5;
  SIG_POCB_FUNC_REQ      = $00b0;
  SIG_POCB_FUNC_ACK      = $00b1;
  SIG_POCB_FUNC2_REQ     = $00b2;
  SIG_POCB_FUNC2_ACK     = $00b3;
//	SIG_MANU_SWITCH_ACK    = $00d3;
	SIG_FW_VERSION_REQ     = $00f0;
	SIG_FW_VERSION_ACK     = $00f1;
	SIG_FW_DOWNLOAD        = $00f2;
	SIG_FW_DOWNLOAD_ACK    = $00f3;
  SIG_PATTERN_VERSION_REQ    = $00F4;
  SIG_PATTERN_VERSION_ACK    = $00F5;




implementation

end.


