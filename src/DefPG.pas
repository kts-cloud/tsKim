unit DefPG;

interface
{$I Common.inc}

uses Windows, Messages,
{$IFDEF PG_AF9}
AF9_API,
{$ENDIF}
SysUtils;

//##############################################################################
//##############################################################################
//###                                                                        ###
//###                        COMMON (PG_AF9 + PG_DP860)                      ###
//###                                                                        ###
//##############################################################################
//##############################################################################

const
  //============================================================================
  // 
  //============================================================================

	//-------------------------------------------------------- PG Type
  PG_TYPE_DP860 = 0;
  PG_TYPE_AF9   = 1;

	//-------------------------------------------------------- PG Cyclic Timer
  PG_CMD_WAITACK_DEF         = 200;  //msec //TBD:DP860?

	PG_CONNCHECK_INTERVAL      = 2000; //msec

	PG_PWRMEASURE_INTERVAL_DEF = 2000; //msec //TBD:DP860?
	PG_PWRMEASURE_INTERVAL_MIN = 1000; //msec //TBD:DP860?
	PG_PWRMEASURE_WAITACK_DEF  = 1000;  //msec //TBD:DP860? // 500 -> 1000


	//-------------------------------------------------------- PG Command Paratemer
  // General
  PG_CMDID_UNKNOWN  = 0;
  PG_CMDSTR_UNKNOWN = 'UnknownPgCommand';

  // Power On/Off
	CMD_POWER_OFF = 0;
	CMD_POWER_ON  = 1;

  // Display On/Off
  CMD_DISPLAY_OFF = 0;
  CMD_DISPLAY_ON  = 1;

  // Flash-related
  MAX_FLASH_SIZE_BYTE         = 16*1024*1024; // 16M //ITOLED (PANEL-dependent)
  MAX_FLASH_GAMMA_SIZE_BYTE   = 1*1024*1024;  // 1M  //ITOLED (PANEL-dependent)
  MAX_FLASH_PUCPARA_SIZE_BYTE = 1*1024*1024;  // 1M  //ITOLED (PANEL-dependent)
  MAX_FLASH_PUCDATA_SIZE_BYTE = 8*1024*1024;  // 8M  //ITOLED (PANEL-dependent)

  //
  FLASH_ERASE_WAITMS_MINIMUM  = 5*1000;  //  5 sec
  FLASH_READ_WAITMS_MINIMUM   = 5*1000;  //  5 sec
  FLASH_WRITE_WAITMS_MINIMUM  = 10*1000; // 10 sec

  FLASH_SIZE_KB_DEF        = 8192; // 8 MB (ITOLED)
  FLASH_READ_KBperSEC_DEF  = 80;   // 80 KB/sec for read (default) //TBD?
  FLASH_WRITE_KBperSEC_DEF =  7;   //  7 KB/sec for erase/write/read/verify (default) //TBD?
  FLASH_ERASE_KBperSEC_DEF =  20;  // 20 KB/sec for erase/write/read/verify (default) //TBD?

  {$IFDEF SIMULATOR_PANEL}
  SIM_TCON_SIZE   = 1024*64;
  SIM_APSREG_SIZE = 1024*64;
  {$ENDIF}

	//-------------------------------------------------------- Power Items
  // Power Setting/Limit
  PWR_VDD1 = 0;  PWR_VCC = PWR_VDD1;
  PWR_VDD2 = 1;  PWR_VIN = PWR_VDD2;
  PWR_VDD3 = 2;
  PWR_VDD4 = 3;
  PWR_VDD5 = 4;
  PWR_MAX = PWR_VDD5;
  // Power Sequence
  PWR_SEQ_MAX = 2;

	//--------------------------------------------------------
  PG_CMDSTATE_NONE       = 0;
  PG_CMDSTATE_TX_NOACK   = 1;
  PG_CMDSTATE_TX_WAITACK = 2;
  PG_CMDSTATE_RX_ACK     = 3; //TBD:DP860?

  PG_CMDRESULT_NONE = 0;
  PG_CMDRESULT_OK   = 1;
  PG_CMDRESULT_NG   = 2;

	//--------------------------------------------------------
  TCON_REG_DEVICE  = $A0; //Temporary values for I2C (for TCON R/W, no need DevAddr)
  PROGRAMING_DEVICE = $14;
type

  //------------------------------------------ Temporary (for OC T/T Test)
  TTconRWCnt = record //2023-03-28 jhhwang (for T/T Test)
    TconReadDllCall  : Integer;
    TconWriteDllCall : Integer;
    TconReadTX       : Integer;
    TConWriteTX      : Integer;
    TConOcWriteTX    : Integer;
    //
    ContTConOcWrite  : Integer;

    TconReadArrayDllCall  : Integer;
    TconWriteArrayDllCall : Integer;

    TconMultiWriteDllCall : Integer;
    TconSeqWriteDllCall : Integer;

    TconRetryReadCall : Integer;
    TconRetryWriteCall : Integer;



  end;

	//------------------------------------- PG TX/RX Data
  PPgTxRxData = ^TPgTxRxData;
  TPgTxRxData = record
		CmdState  : Integer;
		CmdResult : Integer;
		// TX
    TxCmdId   : Integer;
    TxCmdStr  : string;
    TxDataLen : Integer; //TBD:DP860?
    TxData    : array [0..256*1024] of Byte; //TBD:DP860?
		// RX
    RxCmdId   : Integer; //TBD:DP860?
    RxAckStr  : string;
    RxDataLen : Integer; //TBD:DP860?
    RxData    : array [0..256*1024] of Byte; //TBD:DP860?
    //
    RxPrevStr : string;
	end;

	//------------------------------------- PG Version
  TPgVer = record
    VerAll    : string;    //AF9(MCS%0.3d_API%0.3d) //DP860(HW_1.3_APP_1.0.2_FW_1.02_FPGA_10105(1.6.0)_PWR_1.0)
	  {$IFDEF PG_DP860}
    HW     : string;
    FW     : string;
    SubFW  : string;
    IP     : string;
    FPGA   : string;
    PWR    : string;
    ITO_APP : string;
    //
    VerScript : string;    //DP860-only
		{$ENDIF}
		{$IFDEF PG_AF9}
    AF9VerMCS   : Integer;
    AF9VerAPI   : Integer;
    sAF9APIType : string;  //Debug(1CH|MULTI)
		{$ENDIF}
	end;

	//------------------------------------- PG ModelInfo
  // DP860: model.config <Link rate> <lane> <H width> <H bporch> <H active> <H fporch> <V width> <V bporch> <V active> <V fporch> <Vsync> <Format> <ALPM set> <vfb_offset>
  // DP860: alpm.config <h_fdp> <h_sdp> <h_pcnt> <vb_n5b> <vb_n7> <vb_n5a> <vb_sleep> <vb_n2> <vb_n3> <vb_n4>
  //                    <m_vid> <n_vid> <misc_0> <misc_1> <xpol> <xdelay>  <h_mg> <NoAux_Sel> <NoAux_active> <NoAux_Sleep>
  //                    <Critical_section> <tps> <v_blank> <chop_enable> <chop_interval> <chop_size>
  TPgModelConf = record  // Resolution - DP860(model.config), AF9
    // Resolution
    H_Active	: Word;
    H_BP      : Word;
    H_SA      : Word; //Width
    H_FP      : Word;
    V_Active  : Word;
    V_BP      : Word;
    V_SA      : Word; //Width
    V_FP      : Word;
    {$IFDEF PG_AF9}
    Bmp2RawType : Integer; // e.g, 0:Large(X2146), 1:Small(X2381) //2022-07-05 BMP-to-RAW Conversion
    {$ENDIF}
    {$IFDEF PG_DP860}
    // Timing
		link_rate     : Longword;
		lane			    : Integer;
		Vsync			    : Integer;
		RGBFormat     : string;
		ALPM_Mode	    : Integer;
		vfb_offset    : Integer;
    // ALPDP
    h_fdp         : Integer;
    h_sdp         : Integer;
    h_pcnt        : Integer;
    vb_n5b        : Integer;
    vb_n7         : Integer;
    vb_n5a        : Integer;
    vb_sleep      : Integer;
    vb_n2         : Integer;
    vb_n3         : Integer;
    vb_n4         : Integer;
    m_vid         : Integer;
    n_vid         : Integer;
    misc_0        : Integer;
    misc_1        : Integer;
    xpol          : Integer;
    xdelay        : Integer;
    h_mg          : Integer;
    NoAux_Sel     : Integer;
    NoAux_Active  : Integer;
    NoAux_Sleep   : Integer;
    //
    critical_section : Integer;
    tps           : Integer;
    v_blank       : Integer;
    chop_enable   : Integer;
    chop_interval : Integer;
    chop_size     : Integer;
    {$ENDIF}
	end;

  {$IFDEF PG_DP860}	//TBD:DP860?
  //obsoleted!!! power.open,<channel>,<VCC_voltage_value>,<VIN_voltage_value>,<VDD3_voltage_value>,<VDD4_voltage_value>,<VDD5_voltage_value>
  //obsoleted!!! power.limit,<VCC_highlimit_value>,<VIN_highlimit_value>,<VCC_lowlimit_value>,<VIN_lowlimit_value>,<IVCC_highlimit_value>,<IVIN_highlimit_value>,<IVCC_lowlimit_value>,<IVIN_lowlimit_value>
  // power.open <channel> <VCC_voltage_value> <VIN_voltage_value> <VDD3_voltage_value> <VDD4_voltage_value> <VDD5_voltage_value>
  //                         <slope_set> <I_VCC_high_limit_value> <I_VIN_high_limit_value>  <VCC_high_limit_value> <VIN_high_limit_value>
  TPgModelPwrData = record
    PWR_SLOPE   : Integer;  // slope_set
    PWR_NAME    : array[0..PWR_MAX] of String;
		//
    PWR_VOL     : array[0..PWR_MAX] of UInt32; //1=1mV  // Voltage Setting - DP860(power.open)
		//
    PWR_VOL_LL  : array[0..PWR_MAX] of UInt32; //1=1mV  // Power Limit - DP860(power.limit)
    PWR_VOL_HL  : array[0..PWR_MAX] of UInt32; //1=1mV
    PWR_CUR_LL  : array[0..PWR_MAX] of UInt32; //1=1mA
    PWR_CUR_HL  : array[0..PWR_MAX] of UInt32; //1=1mA
	end;

  //obsoleted!!! power.sequence,<sequence_value>,<ON_parameter0_value>,<ON_parameter1_value>,<ON_parameter2_value>,<OFF_parameter0_value>,<OFF_parameter1_value>,<OFF_parameter2_value>
  // power.seq <ON_parameter1_value> <ON_parameter2_value> <OFF_parameter1_value> <OFF_parameter2_value>
  TPgModelPwrSeq = record 	// Power Sequence
    //obsoleted!!! SeqType : integer;
    SeqOn   : array[0..PWR_SEQ_MAX] of Integer;
    SeqOff  : array[0..PWR_SEQ_MAX] of Integer;
	end;
  {$ENDIF}

	//------------------------------------- PG Status
	// AF9  : (pgDisconn) -> (Call Start_Connection) -> pgConnect -> (Call Conn_Status:OK) -> (Call SW_Revision) -> pgReady
  // DP860: (pgDisconn) -> Rcv (1st ConnCheckAck or pg.init) -> (pgConnect) -> Send version.all -> (pgGetPgVer) -> Send ModelInfo -> (pgModelDown) -> (pgReady)
  enumPgStatus = (pgDisconn=0,
                  pgConnect=1,     //Rcv (first ConnCheckAck or pg.init)
                  pgGetPgVer=2,    //Sending version.all
                  pgModelDown=3,   //Sending model info
                  pgReady=4,
                  pgWait=5,        //TBD:DP860?
                  pgDone=6,        //TBD:DP860?
                  pgForceStop=7);  //TBD:DP860?

	//------------------------------------- Power Read
  PPwrData = ^TPwrData;
  TPwrData = record //VCC~VDD5:1=1mV, IVCC~iVDD5:1=1mA //#ReadVoltCurr
    // Voltage (mV)
    VCC   : UInt32;
    VIN   : UInt32;
    VDD3  : UInt32; //TBD:DP860?
    VDD4  : UInt32; //TBD:DP860?
    VDD5  : UInt32; //TBD:DP860?
    // Current (mA)
    IVCC  : UInt32;
    IVIN  : UInt32;
    IVDD3 : UInt32; //TBD:DP860?
    IVDD4 : UInt32; //TBD:DP860?
    IVDD5 : UInt32; //TBD:DP860?
  end;

  PRxPwrData = ^TRxPwrData;
  TRxPwrData = record //VCC~VDD5:1=1mV, IVCC~iVDD5:1=1uA //#PReadVoltC,RealVoltC
    // Voltage (mV)
    VCC   : UInt32;
    VIN   : UInt32;
    VDD3  : UInt32; //TBD:DP860?
    VDD4  : UInt32; //TBD:DP860?
    VDD5  : UInt32; //TBD:DP860?
    // Current (uA)
    IVCC  : UInt32; //TBD:DP860?
    IVIN  : UInt32; //TBD:DP860?
    IVDD3 : UInt32; //TBD:DP860?
    IVDD4 : UInt32; //TBD:DP860?
    IVDD5 : UInt32; //TBD:DP860?
  end;

	//------------------------------------- Flash R/W and Data
	// Flash Access/Read Status
  enumPgFlashAccSt  = (flashAccUnknown=0, flashAccDisabled=1, flashAccEnabled=2);
  enumFlashReadType = (flashReadNone=0, flashReadUnit=1, flashReadGamma=2, flashReadAll=2);
  TFlashRead = record 
    FlashAccSt     : enumPgFlashAccSt;
		//
    ReadType       : enumFlashReadType;
    ReadSize       : Integer;
    RxSize         : Integer;
    RxData         : array[0..(DefPG.MAX_FLASH_SIZE_BYTE-1)] of Byte;
    ChecksumRx     : UInt32;
    ChecksumCalc   : UInt32;
    //
    bReadDone      : Boolean;
    SaveFilePath   : string;
    SaveFileName   : string;
  end;
	// Flash R/W and Data (inspector-specific)
  PFlashData = ^TFlashData;
  TFlashData = record    //TBD:ITOLED?
    StartAddr      : Integer;   //TBD:ITOLED?
    Size           : Integer;
    Data           : array[0..(DefPG.MAX_FLASH_SIZE_BYTE-1)] of Byte;
    Checksum       : UInt32;
    //
    bValid         : Boolean;
  //SaveFilePath   : string;
  //SaveFileName   : string;
  end;

	//-------------------------------------------------------- PG XXXXXX

//##############################################################################
{$IFDEF PG_AF9} //##############################################################
//##############################################################################
//###                                                                        ###
//###                               PG_AF9                                   ###
//###                                                                        ###
//##############################################################################

  //============================================================================
  // AF9_API
  //============================================================================

	//----------------------------------------------------------------------------
  //  Data Types
  //          C++            Delphi
  //     	unsigned short   WORD
  //	    unsigned long    DWORD=LongWord=Cardinal
  //      char*            PAnsiChar
  //      BYTE*            PByte
  //
  // API
	//         1CH                  MULTI(CH1,CH2)  //2022-020-25 DLL(V2.02)
	//  Start_Connection        MULTI_Start_Connection
	//  Stop_Connection         ???
	//  Connection_Status       MULTI_Connection_Status
	//  SW_Revision 						MULTI_SW_Revision
	//  DLL_Revision            ???
	//  DAC_SET                 MULTI_DAC_SET
	//  ExtendIO_Set            MULTI_ExtendIO_Set
	//  AllPowerOnOff           MULTI_AllPowerOnOff
	//  APSPatternRGBSet        MULTI_APSPatternRGBSet
	//  APSBoxPatternSet        MULTI_APSBoxPatternSet
	//  LGDSetReg               MULTI_LGDSetReg                                     ma
	//  LGDSetRegM              MULTI_LGDSetRegM
	//  LGDGetReg               MULTI_LGDGetReg
	//  LGDRangeGetReg          MULTI_LGDRangeGetReg
	//  APSSetReg               MULTI_APSSetReg
	//  SendHexFileCRC          MULTI_SendHexFileCRC
	//  SendHexFile             MULTI_SendHexFile
	//  WriteBMPFile            MULTI_WriteBMPFile
	//  BMPFileSend             MULTI_BMPFileSend
	//  BMPFileView             MULTI_BMPFileView
	//  FLASHRead               MULTI_FLASHRead
	//  FrrSet                  MULTI_FrrSet
	//  //
	//  InitAF9API              InitAF9API 
	//  FreeAF9API              FreeAF9API 
	//  IsVaildUSBHandler       //TBD:AF9:API? IsVaildUSBHandler 
	//  SetResolution           //TBD:AF9:API? SetResolution 
	//  SetFreqChange           //TBD:AF9:API? SetFreqChange 
	//  APSFrrSet               //TBD:AF9:API?
	//  APSFrrSet2              //TBD:AF9:API?
	//  APSSFRSet               //TBD:AF9:API?
	//----------------------------------------------------------------------------

//type
	//----------------------------------------------------------------------------
	// AF9_API (1CH)
	//----------------------------------------------------------------------------

	//------------------------------------- Start the USB connection.
	// @param	None
	// @return	-1 : USB library open fail.
	//			     0 : No USB device found.
	//			     1 : USB device found and connect ok.
	//
	// @note		USB driver must be installed.
	//		Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int Start_Connection(void);	
	function AF9API_Start_Connection: Integer; stdcall; 	// AF9API_Start_Connection, AF9API_MULTI_Start_Connection

	//------------------------------------- Stop the USB connection.
	// @param	None
	// @return	0 : USB device stop fail.
	//			    1 : USB device stop and USB device release.
	//
	// @note		USB driver must be installed.
	//		Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int Stop_Connection(void);
	function AF9API_Stop_Connection: Integer; stdcall;

	//------------------------------------- Read the connection status of USB.
	// @param	None
	// @return	0 : USB connection is not working.
	//			    1 : USB connected.
	//
	// @note		USB driver must be installed.
	//			Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int Connection_Status(void);
	function AF9API_Connection_Status: Integer; stdcall;	// AF9API_Connection_Status, AF9API_MULTI_Connection_Status

	//------------------------------------- Read the FPGA IP version.
	// @param	None
	// @return	FPGA IP Version(xxx).
	//
	// @note		None
	//
	//DLLFunction int SW_Revision(void);
	function AF9API_SW_Revision: Integer; stdcall; // AF9API_SW_Revision, AF9API_MULTI_SW_Revision

	//------------------------------------- Read the DLL version.
	// @param	None
	// @return	DLL IP Version(x.xx).
	//
	// @note		None
	//
	//DLLFunction int DLL_Revision(void);	
	function AF9API_DLL_Revision: Integer; stdcall;

	//------------------------------------- Set the voltage of the power.
	// @param	Type	  : Set the power type.
	// @param	ch		  : Set the power channel.
	// @param	Voltage	: Set the power voltage(mV, absolute value).
	// @param	Option	: Set the power option(plus voltage : 1, minus voltage : 2)
	// 
	// @return	0 : Failed to set the power.
	//			    1 : Successful set the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL DAC_SET(int Type, int channel, int Voltage, int Option);
	function AF9API_DAC_SET(nType: Integer; channel: Integer; Voltage: Integer; Option: Integer): Boolean; stdcall; //type->nType //DAC_SET, MULTI_DAC_SET

	//------------------------------------- Turn on/off the power.
	// @param	Address	: Turn on/off the power address.
	// @param	ch		  : Turn on/off the power channel.
	// @param	Enable	: Turn on/off the power.
	// 
	// @return	0 : Failed to turn on/off the power.
	//			    1 : Successful turn on/off the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL ExtendIO_Set(int Address, int Channel, int Enable);
	function AF9API_ExtendIO_Set(Address: Integer; Channel: Integer; Enable: Integer): Boolean; stdcall; //ExtendIO_Set, MULTI_ExtendIO_Set

	//------------------------------------- Turn on/off all power and initial modlue.
	// @param	OnOff	: Turn on/off all power and initial modlue(ON, OFF).
	//
	// @return	0 : Failed to turn on/off the module.
	//			    1 : Successful turn on/off the module.
	//
	// @note		From the SPI Flash of the module, 
	//			    power settings and other settings are read and processed.
	//
	//DLLFunction int AllPowerOnOff(int OnOff);
	function AF9API_AllPowerOnOff(OnOff: Integer): Integer; stdcall; //AllPowerOnOff, MULTI_AllPowerOnOff

	//------------------------------------- Display RGB Gray pattern.
	// @param	R	: Red color(0 ~ 255).
	// @param	G	: Green color(0 ~ 255).
	// @param	B	: Blue color(0 ~ 255).
	//
	// @return	0 : Display fail.
	//			    1 : Display success.
	//
	// @note		None
	//
	//DLLFunction int APSPatternRGBSet(int R, int G, int B);
	function AF9API_APSPatternRGBSet(R,G,B: Integer): Integer; stdcall; //APSPatternRGBSet, MULTI_APSPatternRGBSet

	//------------------------------------- Display BOX RGB Gray pattern.
	// @param	XOffset			: X position Offset(0 ~ 2920).
	// @param	YOffset			: Y position Offset(0 ~ 1900).
	// @param	Width			  : X Width(0 ~ 2920).
	// @param	Height			: Y Height(0 ~ 1900).
	// @param	R				    : Foreground red color(0 ~ 255).
	// @param	G				    : Foreground green color(0 ~ 255).
	// @param	B				    : Foreground blue color(0 ~ 255).
	// @param	Background_R	: Background red color(0 ~ 255).
	// @param	Background_G	: Background green color(0 ~ 255).
	// @param	Background_B	: Background blue color(0 ~ 255).
	// 
	// @return	0 : BOX display fail.
	//			    1 : BOX display success.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction int APSBoxPatternSet(int XOffset, int YOffset, int Width, int Height, int R, int G, int B, int Background_R, int Background_G, int Background_B);
	function AF9API_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, BR,BG,BB: Integer): Integer; stdcall;  //APSBoxPatternSet, MULTI_APSBoxPatternSet

	//------------------------------------- Setting the internal register of the LGD.
	// @param	Addr	: Address.
	// @param	data	: Data.
	//
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int LGDSetReg(unsigned long Addr, unsigned char data);
	function AF9API_LGDSetReg(Addr: DWORD; data: Byte): Integer; stdcall; //AF9API_LGDSetReg, AF9API_MULTI_LGDSetReg

	//------------------------------------- Multiple setting the internal register of the LGD.
	// @param	LCommand	: Command list(Addr : address, Data : data)
	// @param	CommandCnt	: Command count.
	//
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		typedef struct {
	//				unsigned long Addr;
	//				unsigned char Data;
	//			} LGD_COMMAND;
	// 
	//			Please contact the manufacturer for register information.
	//
	//DLLFunction int LGDSetRegM(LGD_COMMAND* LCommand, int CommandCnt);
	function AF9API_LGDSetRegM(LGDCommand: AF9_PLGDCommand; CommandCnt: Integer): Integer; stdcall; //LGDSetRegM, MULTI_LGDSetRegM

	//------------------------------------- Read the internal register of the LGD.
	// @param	Addr	: Address
	//
	// @return	The data value of bytes received.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char LGDGetReg(unsigned long Addr);
	function AF9API_LGDGetReg(Addr: DWORD): Byte; stdcall; //TBD:AF9_API? //LGDGetReg, MULTI_LGDGetReg

	//------------------------------------- Multiple read the internal register of the LGD.
	// @param	pBuffer		: Read value buffer.
	// @param	StartAddr	: Read start address.
	// @param	EndAddr		: Read end address.
	//
	// @return	0 : Read fail.
	//			    1 : Read success.
	// 
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char LGDRangeGetReg(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr);
	function AF9API_LGDRangeGetReg(pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte; stdcall; //LGDRangeGetReg, AF9API_MULTI_LGDRangeGetReg

	//------------------------------------- Setting the internal register of the APSOLUTION.
	// @param	Addr	: Address.
	// @param	data	: Data.
	//
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int APSSetReg(int Addr, int Data);
	function AF9API_APSSetReg(Addr: Integer; Data: Integer): Integer; stdcall; //APSSetReg, MULTI_APSSetReg

	//------------------------------------- Send the hex file CRC.
	// @param	CRC	: Checksum data(The sum of all values & 0xFFFF)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make checksum data.
	//			    Please refer to the example file.
	//
	//DLLFunction int SendHexFileCRC(unsigned short CRC);
	function AF9API_SendHexFileCRC(CRC: UInt16): Integer; stdcall; //SendHexFileCRC, MULTI_SendHexFileCRC

	//------------------------------------- Send the hex file and write in SPI flash.
	// @param	pbyteBuffer	: Hex data buffer.
	// @param	len			    : hex data buffer length.
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please refer to the example file.
	//
	//DLLFunction int SendHexFile(BYTE* pbyteBuffer, int len);
	function AF9API_SendHexFile(pbyteBuffer: PByte; len: Integer): Integer; stdcall; //SendHexFile, MULTI_SendHexFile 

	//------------------------------------- Send BMP file and view.
	// @param	pbyteBuffer	: Raw data buffer.
	// @param	len			    : Raw data buffer length.
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			    Please refer to the example file.
	//
	//DLLFunction int WriteBMPFile(BYTE* pbyteBuffer, int len);
	function AF9API_WriteBMPFile(pbyteBuffer: PByte; len: Integer): Integer; stdcall; //WriteBMPFile, MULTI_WriteBMPFile

	//------------------------------------- Send BMP files
	// @param	pbyteBuffer	: Raw data buffer.
	// @param	len			    : Raw data buffer length.
	// @param	num			    : Image file number(1 ~ 20).
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			    Please refer to the example file.
	//			    When it is rebooting the board, the data disappears. !!!!
	//
	//DLLFunction int BMPFileSend(BYTE* pbyteBuffer, int len, int num);
	function AF9API_BMPFileSend(pbyteBuffer: PByte; len: Integer; num: Integer): Integer; stdcall; //BMPFileSend, MULTI_BMPFileSend 

	//------------------------------------- Show the BMP file.
	// @param	num	: Image file number(1 ~ 20).
	//
	// @return	0 : Send fail.
	//					1 : Send success.
	//
	// @note		If there is no image transmitted, a wrong screen appears.
	//
	//DLLFunction int BMPFileView(int num);
	function AF9API_BMPFileView(num: Integer): Integer; stdcall; //BMPFileView, MULTI_BMPFileView
	
	//------------------------------------- Read data from SPI flash
	// @param	pBuffer		: SPI flash data buffer.
	// @param	StartAddr	: Read SPI flash start address(align 256byte).
	// @param	EndAddr		: Read SPI flash end address(align 256byte).
	//
	// @return	0 : Read fail.
	//					1 : Read success.
	//
	// @note		None
	//
	//DLLFunction unsigned char FLASHRead(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr);
	function AF9API_FLASHRead(pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte; stdcall; //FLASHRead, MULTI_FLASHRead

	//------------------------------------- FRR Function.
	// @param	FrrStart : FRR function start.
	// @param	R		   : Foreground red color(0 ~ 255).
	// @param	G		   : Foreground green color(0 ~ 255).
	// @param	B		   : Foreground blue color(0 ~ 255).
	// @param	BR		 : Background red color(0 ~ 255).
	// @param	BG		 : Background green color(0 ~ 255).
	// @param	BB		 : Background blue color(0 ~ 255).
	// @param	PTN1	 : Pattern1(1 ~ 6).
	// @param	PTN2	 : Pattern2(1 ~ 6).
	// @param	PTN3	 : Pattern3(1 ~ 6).
	// @param	PTN4	 : Pattern4(1 ~ 6).
	// @param	PTN5	 : Pattern5(1 ~ 6).
	// @param	PTN6	 : Pattern6(1 ~ 6).
	// @param	Hz	 	 : Frequency Set.
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please contact the manufacturer for more information.
	//
	//DLLFunction int FrrSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTN1, BYTE PTN2, BYTE PTN3, BYTE PTN4, BYTE PTN5, BYTE PTN6, int Hz);
	function AF9API_FrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTN1,PTN2,PTN3,PTN4,PTN5,PTN6: Byte; Hz: Integer): Integer; stdcall; //FrrSeta, MULTI_FrrSet

	//------------------------------------- 2022-05-24 AF9API
  // Display RGB Dot patterns.
  //
  // @param	FR	: First Red color(0 ~ 255).
  // @param	FG	: First Green color(0 ~ 255).
  // @param	FB	: First Blue color(0 ~ 255).
  // @param	BR	: Second Red color(0 ~ 255).
  // @param	BG	: Second Green color(0 ~ 255).
  // @param	BB	: Second Blue color(0 ~ 255).
  //
  // @return	0 : Display fail.
  //			    1 : Display success.
  //
  // @note		1 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //           2 Line : (BR, BG, BB), (FR, FG, FB), (BR, BG, BB), (FR, FG, FB) ...
  //           3 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //           4 Line : (BR, BG, BB), (FR, FG, FB), (BR, BG, BB), (FR, FG, FB) ...
  //           ......
  //
  //DLLFunction int APSDotPatternRGBSet(int FR, int FG, int FB, int BR, int BG, int BB);
	function AF9API_APSDotPatternRGBSet(FR,FG,FB: Integer; BR,BG,BB: Integer): Integer; stdcall;

	//------------------------------------- 2022-05-24 AF9API
  // Display RGB Lie Dot patterns.
  //
  // @param	FR	: First Red color(0 ~ 255).
  // @param	FG	: First Green color(0 ~ 255).
  // @param	FB	: First Blue color(0 ~ 255).
  // @param	BR	: Second Red color(0 ~ 255).
  // @param	BG	: Second Green color(0 ~ 255).
  // @param	BB	: Second Blue color(0 ~ 255).
  //
  // @return	0 : Display fail.
  //			    1 : Display success.
  //
  // @note		1 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //          2 Line : (BR, BG, BB), (BR, BG, BB), (BR, BG, BB), (BR, BG, BB) ...
  //          3 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //          4 Line : (BR, BG, BB), (BR, BG, BB), (BR, BG, BB), (BR, BG, BB) ...
  //          ......
  //
  //DLLFunction int APSLineDotPatternRGBSet(int FR, int FG, int FB, int BR, int BG, int BB);
	function AF9API_APSLineDotPatternRGBSet(FR,FG,FB: Integer; BR,BG,BB: Integer): Integer; stdcall;

	//----------------------------------------------------------------------------
	// AF9_API (MULTI)
	//----------------------------------------------------------------------------

	//------------------------------------- Start the multi USB connection.
	// @param	None
	// @return	-1 : USB library open fail.
	//			     0 : No USB device found.
	//			     1 : USB device found and connect ok.
	//
	// @note		USB driver must be installed.
	//					Refer to another document for instructions on installing USB drivers.
	//           Two USBs must be connected. //TBD:ITOLED???
	// 
	//DLLFunction int MULTI_Start_Connection(void);
	function AF9API_MULTI_Start_Connection: Integer; stdcall; 

	//------------------------------------- Read the connection status of USB.
	// @param	CH	: Set the USB device channel(CH1, CH2)
	// @return	0 : USB connection is not working.
	//					1 : USB connected.
	//
	// @note		USB driver must be installed.
	//					Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int MULTI_Connection_Status(int CH);
	function AF9API_MULTI_Connection_Status(CH: Integer): Integer; stdcall;

	//------------------------------------- Read multiple FPGA IP versions.
	// @param	None
	// @return	FPGA IP Version(xxx).
	//
	// @note		None
	//
	//DLLFunction int MULTI_SW_Revision(int CH);
	function AF9API_MULTI_SW_Revision(CH: Integer): Integer; stdcall;

	//------------------------------------- Set the voltage of multiple power.
	// @param	Type	: Set the power type.
	// @param	channel	: Set the power channel.
	// @param	Voltage	: Set the power voltage(mV, absolute value).
	// @param	Option	: Set the power option(plus voltage : 1, minus voltage : 2)
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Failed to set the power.
	//			1 : Successful set the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL MULTI_DAC_SET(int Type, int channel, int Voltage, int Option, int CH);
	function AF9API_MULTI_DAC_SET(nType: Integer; channel: Integer; Voltage: Integer; Option: Integer; CH: Integer): Boolean; stdcall; //type->nType

	//------------------------------------- Turn on/off multiple power.
	// @param	Address	: Turn on/off the power address.
	// @param	Channel	: Turn on/off the power channel.
	// @param	Enable	: Turn on/off the power.
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Failed to turn on/off the power.
	//			1 : Successful turn on/off the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL MULTI_ExtendIO_Set(int Address, int Channel, int Enable, int CH);
	function AF9API_MULTI_ExtendIO_Set(Address: Integer; Channel: Integer; Enable: Integer; CH: Integer): Boolean; stdcall;

	//------------------------------------- multiple turn on/off all power and initial module.
	// @param	OnOff	: Turn on/off all power and initial module(ON, OFF).
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Failed to turn on/off the module.
	//			1 : Successful turn on/off the module.
	//
	// @note		From the SPI Flash of the module,
	//			power settings and other settings are read and processed.
	//
	//DLLFunction int MULTI_AllPowerOnOff(int OnOff, int CH);
	function AF9API_MULTI_AllPowerOnOff(OnOff: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Display multiple RGB Gray patterns.
	// @param	R	: Red color(0 ~ 255).
	// @param	G	: Green color(0 ~ 255).
	// @param	B	: Blue color(0 ~ 255).
	// @param	CH	: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Display fail.
	//			1 : Display success.
	//
	// @note		None
	//
	//DLLFunction int MULTI_APSPatternRGBSet(int R, int G, int B, int CH);
	function AF9API_MULTI_APSPatternRGBSet(R,G,B: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Display multiple BOX RGB Gray pattern.
	// @param	XOffset			: X position Offset(0 ~ 2920).
	// @param	YOffset			: Y position Offset(0 ~ 1900).
	// @param	Width			: X Width(0 ~ 2920).
	// @param	Height			: Y Height(0 ~ 1900).
	// @param	R				: Foreground red color(0 ~ 255).
	// @param	G				: Foreground green color(0 ~ 255).
	// @param	B				: Foreground blue color(0 ~ 255).
	// @param	Background_R	: Background red color(0 ~ 255).
	// @param	Background_G	: Background green color(0 ~ 255).
	// @param	Background_B	: Background blue color(0 ~ 255).
	// @param	CH				: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : BOX display fail.
	//			1 : BOX display success.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction int MULTI_APSBoxPatternSet(int XOffset, int YOffset, int Width, int Height, int R, int G, int B, int Background_R, int Background_G, int Background_B, int CH);
	function AF9API_MULTI_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, BR,BG,BB: Integer; CH: Integer): Integer; stdcall; 

	//------------------------------------- Multiple setting the internal register of the LGD.
	// @param	Addr	: Address.
	// @param	data	: Data.
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Setting fail.
	//			1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int MULTI_LGDSetReg(unsigned long Addr, unsigned char Data, int CH);
	function AF9API_MULTI_LGDSetReg(Addr: DWORD; data: Byte; CH: Integer): Integer; stdcall; 

	//------------------------------------- Multiple setting the internal register of the LGD.
	//
	// @param	LCommand	: Command list(Addr : address, Data : data)
	// @param	CommandCnt	: Command count.
	// @param	CH			: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Setting fail.
	//			1 : Setting success.
	//
	// @note		typedef struct {
	//				unsigned long Addr;
	//				unsigned char Data;
	//			} LGD_COMMAND;
	//
	//			Please contact the manufacturer for register information.
	//
	//DLLFunction int MULTI_LGDSetRegM(LGD_COMMAND* LCommand, int CommandCnt, int CH);
	function AF9API_MULTI_LGDSetRegM(LGDCommand: AF9_PLGDCommand; CommandCnt: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Multiple read the internal register of the LGD.
	// @param	Addr	: Address
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	The data value of bytes received.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char MULTI_LGDGetReg(unsigned long Addr, int CH);
	function AF9API_MULTI_LGDGetReg(Addr: DWORD; CH: Integer): Byte; stdcall; //TBD:AF9_API? 

	//------------------------------------- Multiple read the internal register of the LGD.
	// @param	pBuffer		: Read value buffer.
	// @param	StartAddr	: Read start address.
	// @param	EndAddr		: Read end address.
	// @param	CH			  : Set the USB device channel(CH1, CH2)
	// 
	// @return	0 : Read fail.
	//			    1 : Read success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char MULTI_LGDRangeGetReg(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr, int CH);
	function AF9API_MULTI_LGDRangeGetReg(pBuffer: PByte; StartAddr,EndAddr: DWORD; CH: Integer): Byte; stdcall;

	//------------------------------------- Multiple setting the internal register of the APSOLUTION.
	// @param	Addr	: Address.
	// @param	data	: Data.
	// @param	CH		: Set the USB device channel(CH1, CH2)
	// 
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int MULTI_APSSetReg(int Addr, int Data, int CH);
	function AF9API_MULTI_APSSetReg(Addr: Integer; Data: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Multiple send the hex file CRC.
	// @param	CRC	: Checksum data(The sum of all values & 0xFFFF)
	// @param	CH	: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make checksum data.
	//			    Please refer to the example file.
	//
	//DLLFunction int MULTI_SendHexFileCRC(unsigned short CRC, int CH);
	function AF9API_MULTI_SendHexFileCRC(CRC: UInt16; CH: Integer): Integer; stdcall;

	//------------------------------------- Multiple send the hex file and write in SPI flash.
	// @param	pbyteBuffer	: Hex data buffer.
	// @param	len			    : hex data buffer length.
	// @param	CH			    : Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please refer to the example file.
	//
	//DLLFunction int MULTI_SendHexFile(BYTE* pbyteBuffer, int len, int CH);
	function AF9API_MULTI_SendHexFile(pbyteBuffer: PByte; len: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Multiple send BMP file and view.
	// @param	pbyteBuffer	: raw data buffer.
	// @param	len			    : raw data buffer length.
	// @param	CH			    : Set the USB device channel(CH1, CH2)
	// 
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			Please refer to the example file.
	//
	//DLLFunction int MULTI_WriteBMPFile(BYTE* pbyteBuffer, int len, int CH);
	function AF9API_MULTI_WriteBMPFile(pbyteBuffer: PByte; len: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Sends multiple BMP files.
	// @param	pbyteBuffer	: Raw data buffer.
	// @param	len			    : Raw data buffer length.
	// @param	num			    : Image file number(1 ~ 20).
	// @param	CH			    : Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			Please refer to the example file.
	//			When it is rebooting the board, the data disappears.
	//			
	//DLLFunction int MULTI_BMPFileSend(BYTE* pbyteBuffer, int len, int num, int CH);
	function AF9API_MULTI_BMPFileSend(pbyteBuffer: PByte; len: Integer; num: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Show the multiple BMP file.
	// @param	num	    : Image file number(1 ~ 10).
	// @param	CH			: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		If there is no image transmitted, a wrong screen appears.
	//
	//DLLFunction int MULTI_BMPFileView(int num, int CH);
	function AF9API_MULTI_BMPFileView(num: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- Multiple read data from SPI flash.
	// @param	pBuffer		: SPI flash data buffer.
	// @param	StartAddr	: Read SPI flash start address(align 256byte).
	// @param	EndAddr		: Read SPI flash end address(align 256byte).
	// @param	CH			: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Read fail.
	//			    1 : Read success.
	//
	// @note		None
	//
	//DLLFunction unsigned char MULTI_FLASHRead(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr, int CH);
	function AF9API_MULTI_FLASHRead(pBuffer: PByte; StartAddr,EndAddr: DWORD; CH: Integer): Byte; stdcall;

	//------------------------------------- Multiple FRR Function.
	// @param	FrrStart : FRR function start.
	// @param	R		   : Foreground red color(0 ~ 255).
	// @param	G		   : Foreground green color(0 ~ 255).
	// @param	B    	 : Foreground blue color(0 ~ 255).
	// @param	BR		 : Background red color(0 ~ 255).
	// @param	BG		 : Background green color(0 ~ 255).
	// @param	BB		 : Background blue color(0 ~ 255).
	// @param	PTN1	 : Pattern1(1 ~ 6).
	// @param	PTN2	 : Pattern2(1 ~ 6).
	// @param	PTN3	 : Pattern3(1 ~ 6).
	// @param	PTN4	 : Pattern4(1 ~ 6).
	// @param	PTN5	 : Pattern5(1 ~ 6).
	// @param	PTN6	 : Pattern6(1 ~ 6).
	// @param	Hz	 	 : Frequency Set.
	// @param	CH		 : Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please contact the manufacturer for more information.
	//
	//DLLFunction int MULTI_FrrSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTN1, BYTE PTN2, BYTE PTN3, BYTE PTN4, BYTE PTN5, BYTE PTN6, int Hz, int CH);
	function AF9API_MULTI_FrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTN1,PTN2,PTN3,PTN4,PTN5,PTN6: Byte; Hz: Integer; CH: Integer): Integer; stdcall;

  //------------------------------------- 2022-05-24 AF9API
  // Display RGB Dot patterns.
  //
  // @param	FR	: First Red color(0 ~ 255).
  // @param	FG	: First Green color(0 ~ 255).
  // @param	FB	: First Blue color(0 ~ 255).
  // @param	BR	: Second Red color(0 ~ 255).
  // @param	BG	: Second Green color(0 ~ 255).
  // @param	BB	: Second Blue color(0 ~ 255).
  // @param	CH	: Set the USB device channel(CH1, CH2)
  //
  // @return	0 : Display fail.
  //			    1 : Display success.
  //
  // @note		1 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //           2 Line : (BR, BG, BB), (FR, FG, FB), (BR, BG, BB), (FR, FG, FB) ...
  //           3 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //           4 Line : (BR, BG, BB), (FR, FG, FB), (BR, BG, BB), (FR, FG, FB) ...
  //           ......
  //
  //DLLFunction int MULTI_APSDotPatternRGBSet(int FR, int FG, int FB, int BR, int BG, int BB, int CH);
	function AF9API_MULTI_APSDotPatternRGBSet(FR,FG,FB: Integer; BR,BG,BB: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 2022-05-24 AF9API
  // Display RGB Line Dot patterns.
  //
  // @param	FR	: First Red color(0 ~ 255).
  // @param	FG	: First Green color(0 ~ 255).
  // @param	FB	: First Blue color(0 ~ 255).
  // @param	BR	: Second Red color(0 ~ 255).
  // @param	BG	: Second Green color(0 ~ 255).
  // @param	BB	: Second Blue color(0 ~ 255).
  // @param	CH	: Set the USB device channel(CH1, CH2)
  //
  // @return	0 : Display fail.
  //			    1 : Display success.
  //
  // @note		1 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //          2 Line : (BR, BG, BB), (BR, BG, BB), (BR, BG, BB), (BR, BG, BB) ...
  //          3 Line : (FR, FG, FB), (BR, BG, BB), (FR, FG, FB), (BR, BG, BB) ...
  //          4 Line : (BR, BG, BB), (BR, BG, BB), (BR, BG, BB), (BR, BG, BB) ...
  //          ......
  //
  //DLLFunction int MULTI_APSLineDotPatternRGBSet(int FR, int FG, int FB, int BR, int BG, int BB, int CH);
	function AF9API_MULTI_APSLineDotPatternRGBSet(FR,FG,FB: Integer; BR,BG,BB: Integer; CH: Integer): Integer; stdcall;

	//----------------------------------------------------------------------------
	// AF9_API (TBD)
	//----------------------------------------------------------------------------
	//
	// DLLFunction void InitAF9API(void);
  //procedure	AF9API_InitAF9API; stdcall; //TBD:AF9:API? v2.02? 
	// DLLFunction void FreeAF9API(void);
	procedure	AF9API_FreeAF9API; stdcall; //TBD:AF9:API?
	// DLLFunction BOOL IsVaildUSBHandler(void);
	function AF9API_IsVaildUSBHandler: Boolean; stdcall;	// USB Handler Validation Written by Steve //TBD:AF9:API?
	//DLLFunction int SetResolution(int ResHRes, int ResHBP, int ResHSA, int ResHFP, int ResVRes, int ResVBP, int ResVSA, int ResVFP);
	function AF9API_SetResolution(ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP: Integer): Integer; stdcall; //TBD:AF9:API?
	//DLLFunction int SetFreqChange(BYTE* pbyteBuffer, int len, int HzCnt, int Repeat);
	function AF9API_SetFreqChange(pbyteBuffer: PByte; len: Integer; HzCnt: Integer; nRepeat: Integer): Integer; stdcall; //TBD:AF9:API?
	// LGD function.
	//    Please contact the manufacturer for more information.
	//DLLFunction int APSFrrSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTNCnt, DWORD PTN);
	function AF9API_APSFrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD): Integer; stdcall; //TBD:AF9:API?
	//DLLFunction int APSFrrSet2(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTNCnt, DWORD PTN, int Hz);
	function AF9API_APSFrrSet2(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz:Integer): Integer; stdcall; //TBD:AF9:API?
	//DLLFunction int APSSFRSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTNCnt, DWORD PTN, int Hz);
	function AF9API_APSSFRSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz:Integer): Integer; stdcall; //TBD:AF9:API?


const
  //============================================================================
	AF9API_DLL = 'AF9_API2.dll';

	//----------------------------------------------------------------------------
  function AF9API_Start_Connection; external AF9API_DLL name 'Start_Connection';
  function AF9API_Stop_Connection; external AF9API_DLL name 'Stop_Connection';
  function AF9API_Connection_Status; external AF9API_DLL name 'Connection_Status';
  function AF9API_SW_Revision; external AF9API_DLL name 'SW_Revision';
  function AF9API_DLL_Revision; external AF9API_DLL name 'DLL_Revision';
  function AF9API_DAC_SET; external AF9API_DLL name 'DAC_SET';
  function AF9API_ExtendIO_Set; external AF9API_DLL name 'ExtendIO_Set';
  function AF9API_AllPowerOnOff; external AF9API_DLL name 'AllPowerOnOff';
  function AF9API_APSPatternRGBSet; external AF9API_DLL name 'APSPatternRGBSet';
  function AF9API_APSBoxPatternSet; external AF9API_DLL name 'APSBoxPatternSet';
  function AF9API_LGDSetReg; external AF9API_DLL name 'LGDSetReg';
  function AF9API_LGDSetRegM; external AF9API_DLL name 'LGDSetRegM';
  function AF9API_LGDGetReg; external AF9API_DLL name 'LGDGetReg';
  function AF9API_LGDRangeGetReg; external AF9API_DLL name 'LGDRangeGetReg';
  function AF9API_APSSetReg; external AF9API_DLL name 'APSSetReg';
  function AF9API_SendHexFileCRC; external AF9API_DLL name 'SendHexFileCRC';
  function AF9API_SendHexFile; external AF9API_DLL name 'SendHexFile';
  function AF9API_WriteBMPFile; external AF9API_DLL name 'WriteBMPFile';
	function AF9API_BMPFileSend; external AF9API_DLL name 'BMPFileSend';
	function AF9API_BMPFileView;  external AF9API_DLL name 'BMPFileView';
  function AF9API_FLASHRead; external AF9API_DLL name 'FLASHRead';
  function AF9API_FrrSet; external AF9API_DLL name 'FrrSet';
  function AF9API_APSDotPatternRGBSet; external AF9API_DLL name 'APSDotPatternRGBSet'; //2022-06-14
  function AF9API_APSLineDotPatternRGBSet; external AF9API_DLL name 'APSLineDotPatternRGBSet'; //2022-06-14
	//----------------------------------------------------------------------------
  function AF9API_MULTI_Start_Connection; external AF9API_DLL name 'MULTI_Start_Connection';
//function AF9API_MULTI_Stop_Connection; external AF9API_DLL name 'MULTI_Stop_Connection'; //TBD:AF9:API?
  function AF9API_MULTI_Connection_Status; external AF9API_DLL name 'MULTI_Connection_Status';
  function AF9API_MULTI_SW_Revision; external AF9API_DLL name 'MULTI_SW_Revision';
//function AF9API_MULTI_DLL_Revision; external AF9API_DLL name 'MULTI_DLL_Revision'; //TBD:AF9:API?
  function AF9API_MULTI_DAC_SET; external AF9API_DLL name 'MULTI_DAC_SET';
  function AF9API_MULTI_ExtendIO_Set; external AF9API_DLL name 'MULTI_ExtendIO_Set';
  function AF9API_MULTI_AllPowerOnOff; external AF9API_DLL name 'MULTI_AllPowerOnOff';
  function AF9API_MULTI_APSPatternRGBSet; external AF9API_DLL name 'MULTI_APSPatternRGBSet';
  function AF9API_MULTI_APSBoxPatternSet; external AF9API_DLL name 'MULTI_APSBoxPatternSet';
  function AF9API_MULTI_LGDSetReg; external AF9API_DLL name 'MULTI_LGDSetReg';
  function AF9API_MULTI_LGDSetRegM; external AF9API_DLL name 'MULTI_LGDSetRegM';
  function AF9API_MULTI_LGDGetReg; external AF9API_DLL name 'MULTI_LGDGetReg';
  function AF9API_MULTI_LGDRangeGetReg; external AF9API_DLL name 'MULTI_LGDRangeGetReg';
  function AF9API_MULTI_APSSetReg; external AF9API_DLL name 'MULTI_APSSetReg';
  function AF9API_MULTI_SendHexFileCRC; external AF9API_DLL name 'MULTI_SendHexFileCRC';
  function AF9API_MULTI_SendHexFile; external AF9API_DLL name 'MULTI_SendHexFile';
  function AF9API_MULTI_WriteBMPFile; external AF9API_DLL name 'MULTI_WriteBMPFile';
	function AF9API_MULTI_BMPFileSend; external AF9API_DLL name 'MULTI_BMPFileSend';
	function AF9API_MULTI_BMPFileView;  external AF9API_DLL name 'MULTI_BMPFileView';
  function AF9API_MULTI_FLASHRead; external AF9API_DLL name 'MULTI_FLASHRead';
  function AF9API_MULTI_FrrSet; external AF9API_DLL name 'MULTI_FrrSet';
  function AF9API_MULTI_APSDotPatternRGBSet; external AF9API_DLL name 'MULTI_APSDotPatternRGBSet'; //2022-06-14
  function AF9API_MULTI_APSLineDotPatternRGBSet; external AF9API_DLL name 'MULTI_APSLineDotPatternRGBSet'; //2022-06-14
	//----------------------------------------------------------------------------
	//TBD:AF9:v2.02? procedure AF9API_InitAF9API; external AF9API_DLL name 'InitAF9API';
  procedure AF9API_FreeAF9API; external AF9API_DLL name 'FreeAF9API';
  function AF9API_IsVaildUSBHandler; external AF9API_DLL name 'IsVaildUSBHandler';
  function AF9API_SetResolution; external AF9API_DLL name 'SetResolution';
  function AF9API_SetFreqChange; external AF9API_DLL name 'SetFreqChange';
	//----------------------------------------------------------------------------
  function AF9API_APSFrrSet; external AF9API_DLL name 'APSFrrSet';
  function AF9API_APSFrrSet2; external AF9API_DLL name 'APSFrrSet2';
  function AF9API_APSSFRSet; external AF9API_DLL name 'APSSFRSet';
	//----------------------------------------------------------------------------
//function AF9API_APS_REG_Set; external AF9API_DLL name 'APS_REG_Set';
//function AF9API_PatternRGBSet; external AF9API_DLL name 'PatternRGBSet';
//function AF9API_Set_Power; external AF9API_DLL name 'Set_Power';
//function AF9API_WriteHexFile; external AF9API_DLL name 'WriteHexFile';

const

  //============================================================================
  //  - AF9API_Start_Connection
  AF9API_STARTCONN_USB_OPENFAIL  = -1;
  AF9API_STARTCONN_USB_NOTFOUND  = 0;
  AF9API_STARTCONN_OK            = 1;
  AF9API_STARTCONN_DLL_EXCEPTION = 2;

  //  - AF9_Connection_Status
  //  - AF9_APSPatternRGBSet
  AF9API_RESULT_OK = 1; //
  AF9API_RESULT_NG = 0;
  AF9API_RESULT_DLL_EXCEPTION = 2;

  // arbitrary value for AF9-FPGA RGD_REG(T-CON?) and APS_REG
  APS_REG_DEVICE  = $B0; //arbitrary !!!

//##############################################################################
{$ENDIF} //PG_AF9 ##############################################################
//##############################################################################

//##############################################################################
{$IFDEF PG_DP860} //############################################################
//##############################################################################
//###                                                                        ###
//###                              PG_DP860                                  ###   
//###                                                                        ###
//##############################################################################
//##############################################################################

const
	//-------------------------------------------------------- PG IPADDR/PORT
  // ch#        PC(SW)               PG
  // ---- ------------------  -------------------
  // CH1  169.254.199.10/any  169.254.199.11/8001
  // CH2  169.254.199.10/any  169.254.199.12/8002
  // CH3  169.254.199.10/any  169.254.199.12/8003
  // CH4  169.254.199.10/any  169.254.199.12/8004
{$IFDEF SIMULATOR_PG}
  CommPG_NETWORK_PREFIX = '169.254.200'; //for PG Simulator
{$ELSE}
  CommPG_NETWORK_PREFIX = '169.254.199';
{$ENDIF}
  CommPG_PC_IPADDR      = CommPG_NETWORK_PREFIX+'.10';
  CommPG_PC_PORT_BASE   = 8000;  //TBD?
  CommPG_PC_PORT_STATIC = False; //TBD:DP860?

  CommPG_PG_IPADDR_BASE = 11;
  CommPG_PG_PORT_BASE   = 8001;

	//-------------------------------------------------------- PG Username/Password for file Upload/Download
  DP860_FTP_USERNAME      = 'upload';
  DP860_FTP_PASSWORD      = 'upload';
  DP860_FTP_PATH_UPLOAD   = '/home/upload';
  DP860_FTP_PATH_DOWNLOAD = '/home/upload';

  DP860_ROOT_USERNAME     = 'root';
  DP860_ROOT_PASSWORD     = 'insta';

	//-------------------------------------------------------- PG Commands
//PG_CMDID_UNKNOWN              =   0;  PG_CMDSTR_UNKNOWN              = 'UnknownPgCommand';
	//------------------------------------------ //TBD:DP860?
  PG_CMDID_CONNCHECK            =   1;	PG_CMDSTR_CONNCHECK            = 'pg.status';
  PG_CMDID_PG_INIT              =   2;	PG_CMDSTR_PG_INIT              = 'pg.init';
	//------------------------------------------ Read Version Information
  PG_CMDID_VERSION_ALL          =   3;  PG_CMDSTR_VERSION_ALL          = 'version.all';   //Insta HW+FW (e.g., "ITO_HW_1.3_APP_1.0.2_FW_1.02_FPGA_10105(1.6.0)_PWR_1.0")
//PG_CMDID_VERSION_HW           =   4;	PG_CMDSTR_VERSION_HW           = 'version.hw';    //Insta HW    (e.g., "1.3")
//PG_CMDID_VERSION_FW           =   5;  PG_CMDSTR_VERSION_FW           = 'version.fw';    //Insta FW    (e.g., "APP_1.0.2_FW_1.02")
//PG_CMDID_VERSION_PWR          =   6;  PG_CMDSTR_VERSION_PWR          = 'version.pwr';   //Insta POWER (e.g., "HW_1.0_FW_1.0")
//PG_CMDID_VERSION_FPGA         =   7;  PG_CMDSTR_VERSION_FPGA         = 'version.fpga';  //Insta FPGA  (e.g., "FPGA_10105(1.6.0)")
  PG_CMDID_MODEL_VERSION        =   8;  PG_CMDSTR_MODEL_VERSION        = 'model.version'; //Insta Script(e.g., "ITO_DP860__v0002_20221206")
	//------------------------------------------ Module selection and identity
  PG_CMDID_POWER_OPEN           =  10;  PG_CMDSTR_POWER_OPEN           = 'power.open';
  PG_CMDID_POWER_SEQ            =  11;  PG_CMDSTR_POWER_SEQ            = 'power.seq';
  PG_CMDID_MODEL_CONFIG         =  12;  PG_CMDSTR_MODEL_CONFIG         = 'model.config';
  PG_CMDID_ALPM_CONFIG          =  13;  PG_CMDSTR_ALPM_CONFIG          = 'alpm.config';
	//
  PG_CMDID_SET_MODEL_FILE       =  15;  PG_CMDSTR_SET_MODEL_FILE       = 'model.file';    //TBD:DP860?
  PG_CMDID_GET_MODEL            =  16;  PG_CMDSTR_GET_MODEL            = 'model';         //TBD:DP860?
  PG_CMDID_GET_MODEL_LIST       =  17;  PG_CMDSTR_GET_MODEL_LIST       = 'model.list';    //TBD:DP860?
	//------------------------------------------ Power On/Off
  PG_CMDID_POWER_ON             =  20;  PG_CMDSTR_POWER_ON             = 'power.on';          // PowerOn : interposer.init -> power.on
  PG_CMDID_POWER_OFF            =  21;  PG_CMDSTR_POWER_OFF            = 'power.off';         // PowerOff: power.off -> interposer.deinit
  PG_CMDID_INTERPOSER_ON        =  22;  PG_CMDSTR_INTERPOSER_ON        = 'interposer.init';
  PG_CMDID_INTERPOSER_OFF       =  23;  PG_CMDSTR_INTERPOSER_OFF       = 'interposer.deinit';
  PG_CMDID_DUT_DETECT           =  24;  PG_CMDSTR_DUT_DETECT           = 'dut.detect';
  PG_CMDID_TCON_INFO            =  25;  PG_CMDSTR_TCON_INFO            = 'tcon.info';
  PG_CMDID_POWER_BIST_ON        =  26;  PG_CMDSTR_POWER_BIST_ON        = 'power.bist.on'; // PreOC 및 OC는bist on,off로 전원 제어
  PG_CMDID_POWER_BIST_OFF       =  27;  PG_CMDSTR_POWER_BIST_OFF       = 'power.bist.off'; // PreOC 및 OC는bist on,off로 전원 제어
  PG_CMDID_BIST_RGB             =  28;  PG_CMDSTR_BIST_RGB             = 'bist.rgb'; // PreOC 및 OC RGB 패턴 출력
  PG_CMDID_BIST_RGB_9BIT        =  29;  PG_CMDSTR_BIST_RGB_9BIT        = 'bist.9bit'; // PreOC 및 OC RGB 패턴 출력	//------------------------------------------ Power measurement
  PG_CMDID_POWER_READ           =  30;  PG_CMDSTR_POWER_READ           = 'power.read';    //voltage+current
  //
  PG_CMDID_POWER_VOLTAGE        =  31;  PG_CMDSTR_POWER_VOLTAGE        = 'power.voltage'; //voltage(specific rail)
  PG_CMDID_POWER_CURRENT        =  32;  PG_CMDSTR_POWER_CURRENT        = 'power.current'; //current(specific rail)
     	PGSIG_POWER_RAIL_VDD1 = 'VCC';  //TBD:DP860?
     	PGSIG_POWER_RAIL_VDD2 = 'VIN';  //TBD:DP860?
     	PGSIG_POWER_RAIL_VDD3 = 'VDD3';
     	PGSIG_POWER_RAIL_VDD4 = 'VDD4';
     	PGSIG_POWER_RAIL_VDD5 = 'VDD5';
  PG_CMDID_BIST_APL             =  33;  PG_CMDSTR_BIST_APL             = 'bist.box.apl'; // APL 함수 추가
	//------------------------------------------ TCON R/W
  PG_CMDID_TCON_READ            =  40;  PG_CMDSTR_TCON_READ            = 'tcon.read';
  PG_CMDID_TCON_WRITE           =  41;  PG_CMDSTR_TCON_WRITE           = 'tcon.write';
  PG_CMDID_TCON_OCWRITE         =  42;  PG_CMDSTR_TCON_OCWRITE         = 'tcon.ocwrite';
  PG_CMDID_TCON_MULTIWRITE      =  43;  PG_CMDSTR_TCON_MULTIWRITE      = 'tcon.multiwrite';
  PG_CMDID_TCON_SEQWRITE        =  44;  PG_CMDSTR_TCON_SEQWRITE        = 'tcon.seqwrite';
  PG_CMDID_TCON_WRITEREAD       =  45;  PG_CMDSTR_TCON_WRITEREAD       = 'tcon.writeread';
  PG_CMDID_TCON_BYTEREAD        =  46;  PG_CMDSTR_TCON_BYTEREAD       = 'tcon.byteread';

  	//------------------------------------------ I2C R/W
  PG_CMDID_I2C_READ            =  47;  PG_CMDSTR_I2C_READ            = 'i2c.read';

	//------------------------------------------ NVM(FLASH) R/W
  PG_CMDID_NVM_INIT             =  50;  PG_CMDSTR_NVM_INIT             = 'nvm.init';        //TBD:DP860?  //SPI Speed and Init 
  PG_CMDID_NVM_ERASE            =  51;  PG_CMDSTR_NVM_ERASE            = 'nvm.erase';       //TBD:DP860?
  PG_CMDID_NVM_READ             =  52;  PG_CMDSTR_NVM_READ             = 'nvm.read';
//PG_CMDID_NVM_WRITE            =  53;  PG_CMDSTR_NVM_WRITE            = 'nvm.write';       //TBD:DP860?
  PG_CMDID_NVM_READFILE         =  54;  PG_CMDSTR_NVM_READFILE         = 'nvm.readfile';
  PG_CMDID_NVM_WRITEFILE        =  55;  PG_CMDSTR_NVM_WRITEFILE        = 'nvm.writefile';
  PG_CMDID_NVM_READASCII        =  56;  PG_CMDSTR_NVM_READASCII        = 'nvm.read_ascii'; 
//PG_CMDID_NVM_WRITEASCII       =  57;  PG_CMDSTR_NVM_WRITEASCII       = 'nvm.write2ascii'; //TBD:DP860?
//PG_CMDID_DYNAMIC_LOAD         =  58;  PG_CMDSTR_DYNAMIC_LOAD         = 'dynamic.load';    //TBD:DP860?
	//------------------------------------------ Pattern Display
  // RGB
  PG_CMDID_IMAGE_RGB            =  70;  PG_CMDSTR_IMAGE_RGB            = 'image.rgb';           //Full Display Color(RGB)
//PG_CMDID_IMAGE_APL            =  71;  PG_CMDSTR_IMAGE_APL            = 'image.apl';           //TBD:DP860?
	// BMP
  PG_CMDID_IMAGE_FILE           =  72;  PG_CMDSTR_IMAGE_FILE           = 'image.file';
//PG_CMDID_IMAGE_APL_FILE       =  73;  PG_CMDSTR_IMAGE_APL_FILE       = 'image.apl_file';      //Dimming? Pwm? //TBD:DP860?
	// Lookup Table(pattern list)
  PG_CMDID_IMAGE_DISPLAY        =  74;  PG_CMDSTR_IMAGE_DISPLAY        = 'image.display';       //pattern#
//PG_CMDID_IMAGE_FIRST          =  75;  PG_CMDSTR_IMAGE_FIRST          = 'image.first';         //pattern#0
//PG_CMDID_IMAGE_NEXT           =  76;  PG_CMDSTR_IMAGE_NEXT           = 'image.next';          //next pattern#
//PG_CMDID_IMAGE_PREV           =  77;  PG_CMDSTR_IMAGE_PREV           = 'image.prev';          //prev pattern#
	// PATTERN TOOL
  PG_CMDID_IMAGE_BOX            =  80;  PG_CMDSTR_IMAGE_BOX            = 'image.box';       //Rectangle(RGB) with (Black|RGB) background
  PG_CMDID_IMAGE_EMPTYBOX       =  81;  PG_CMDSTR_IMAGE_EMPTYBOX       = 'image.emptybox';  //Empty box with Black background
  PG_CMDID_IMAGE_CIRCLE         =  82;  PG_CMDSTR_IMAGE_CIRCLE         = 'image.circle';    //Circle(RGB) with Black background
  PG_CMDID_IMAGE_LINE           =  83;  PG_CMDSTR_IMAGE_LINE           = 'image.line';      //Line(RGB) with Black background
  PG_CMDID_IMAGE_DOT            =  84;  PG_CMDSTR_IMAGE_DOT            = 'image.dot';       //Dot(RGB) with Black background
  PG_CMDID_IMAGE_HGRAY          =  85;  PG_CMDSTR_IMAGE_HGRAY          = 'image.hgray';     //H_Gradation(R|G|B|RG|RB\GB\RGB|W) with Black background
    	PGSIG_GRADATION_DIR_H_INC 	  = 0; //   0(left) ~ 255(right)
    	PGSIG_GRADATION_DIR_H_DEC 	  = 1; // 255(left) ~   0(right)
  PG_CMDID_IMAGE_VGRAY          =  86;  PG_CMDSTR_IMAGE_VGRAY          = 'image.vgray';     //V_Gradation(R|G|B|RG|RB\GB\RGB|W) with Black background
    	PGSIG_GRADATION_DIR_V_INC 	  = 0; //   0(top) ~ 255(bottom)
    	PGSIG_GRADATION_DIR_V_DEC 	  = 1; // 255(top) ~   0(bottom)
  PG_CMDID_IMAGE_CHECKER        =  87;  PG_CMDSTR_IMAGE_CHECKER        = 'image.checker';   //TBD:DP860?
  PG_CMDID_IMAGE_TILE           =  88;  PG_CMDSTR_IMAGE_TILE           = 'image.tile';      //TBD:DP860?
  PG_CMDID_IMAGE_TOOL           =  89;  PG_CMDSTR_IMAGE_TOOL           = 'image.tool';      //multiple boxes/shapes in a single image //TBD:DP860?
	// (Dynamic) FPGA generated pattern with frame rate(Hz) //TBD:DP860?
//PG_CMDID_IMAGE_FLAME_XYTILE   =  90;  PG_CMDSTR_IMAGE_FLAME_XYTILE   = 'image.frame_xytile';  //4 frmae 4x4 pixel repeating tile pattern
//PG_CMDID_IMAGE_FLAME_CHUNKY6F	=  91;  PG_CMDSTR_IMAGE_FLAME_CHUNKY6F = 'image.chunky6f';      //6 frmae 32x48 pixel repeating tile pattern
//PG_CMDID_IMAGE_FLAME_CHUNKY2F =  92;  PG_CMDSTR_IMAGE_FLAME_CHUNKY2F = 'image.chunky2f';      //chunky 2FFR repeating tile pattern with PNGs
//PG_CMDID_IMAGE_FLAME_CHUNKY3F =  93;  PG_CMDSTR_IMAGE_FLAME_CHUNKY3F = 'image.chunky3f';      //
//PG_CMDID_IMAGE_FLAME_CHUNKY4F =  94;  PG_CMDSTR_IMAGE_FLAME_CHUNKY4F = 'image.chunky4f';      //
//PG_CMDID_IMAGE_FLAME_VRR      =  95;  PG_CMDSTR_IMAGE_FLAME_VRR      = 'image.vrr';           //Vaiable refresh rate solid pattern(RGB)
	// Set refresh rate
//PG_CMDID_SET_REFRESHRATE      =  96;  PG_CMDSTR_SET_REFRESHRATE      = 'display.refreshrate';
	// Pulse Control
//PG_CMDID_BSYNC                =  97;  PG_CMDSTR_BSYNC                = 'bsync.out';
//PG_CMDID_BSYNC_DELAYED        =  98;  PG_CMDSTR_BSYNC_DELAYED        = 'bsyncvb.out';
//PG_CMDID_BSYNC_GET_FREQ       =  99;  PG_CMDSTR_BSYNC_GET_FREQ       = 'freq.read';
//PG_CMDID_BSYNC_GET_DUTY       = 100;  PG_CMDSTR_BSYNC_GET_DUTY       = 'duty.read';
   // DBV
  PG_CMDID_ALPDP_DBV            = 101;  PG_CMDSTR_ALPDP_DBV            = 'alpdp.dbv'; //TBD:DP860? TBD:2023-02-02? alpdp.dbv?
  PG_CMDID_BIST_DBV             = 102;  PG_CMDSTR_BIST_DBV             = 'bist.dbv'; //TBD:DP860? TBD:2023-02-02? alpdp.dbv?
  PG_CMDID_REPROGRAMING         = 103;  PG_CMDSTR_REPROGRAMING         = 'programming.write';
  PG_CMDID_CHK_ENABLE           = 104;  PG_CMDSTR_CHK_ENABLE           = 'chk.enable';
	//------------------------------------------ System Commands
  // BMP list
  PG_CMDID_GET_BMP_LIST         = 110;  PG_CMDSTR_GET_BMP_LIST         = 'bmp'; //TBD:DP860?
  // Temperature
  // LED On/Off
  // Delay
//PG_CMDID_WAIT_MS              = 114;  PG_CMDSTR_WAIT_MS              = 'wait'; //TBD:DP860?
//PG_CMDID_DELAY_MS             = 115;  PG_CMDSTR_DELAY_MS             = 'delay.ms'; //TBD:DP860?
//PG_CMDID_DELAY_US             = 116;  PG_CMDSTR_DELAY_US             = 'delay.us'; //TBD:DP860?
  // NOP
//PG_CMDID_NOP                  = 117;  PG_CMDSTR_NOP                  = 'nop'; //TBD:DP860?
  // System
  PG_CMDID_RESET                = 119;  PG_CMDSTR_RESET                = 'reset';
  PG_CMDID_SYSTEM               = 120;  PG_CMDSTR_SYSTEM               = 'system'; //TBD:DP860?
  PG_CMDID_HELP                 = 121;  PG_CMDSTR_HELP                 = 'help'; //TBD:DP860?

	//------------------------------------------ Temporary (for OC T/T Test)
  PG_CMDID_OC_ONOFF             = 130;  PG_CMDSTR_OC_ONOFF             = 'oc.onoff';  //2023-03-30
  PG_CMDID_GPIO_READ            = 131;  PG_CMDSTR_GPIO_READ            = 'gpio.read'; // e.g., "gpio.read HPD" // 2023-03-30 jhhwang (for OC T/T Test)
  PG_CMDID_GPIO_PANEL_IRQ       = 132;  PG_CMDSTR_GPIO_PANEL_IRQ       = 'gpio.read,panel_irq';
  PG_PACKET_SIZE  = 1024; //TBD? DP860?

//##############################################################################
{$ENDIF} //PG_DP860 ############################################################
//##############################################################################

implementation

end.


