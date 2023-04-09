unit AF9_FPGA;

interface


uses
  System.Classes, System.SysUtils, System.Threading,
  Winapi.Windows, Winapi.Messages, Winapi.WinSock,
  IdGlobal,
  Vcl.Dialogs, Vcl.ExtCtrls,

  {$IF Defined(INSEPECTOR_FI) or Defined(INSEPECTOR_OQA) or Defined(PAS_SCRIPT)}
  DefScript,
  {$ENDIF}
	DefAF9, AF9_API,DefCommon,UserUtils

{$IFDEF DEBUG}
  ,CodeSiteLogging
{$ENDIF}
;


type

	enumPgConnSt = (PgConnStDisconn=0, PgConnStStart=1, PgConnStConn=2);
    // AF9: AF9ConnStDisconn -> (Call Start_Connection) -> AF9ConnStStart -> (Call Conn_Status:OK) -> (Call SW_Revision) -> AF9ConnStConn

  //-----------------
  RxMaintEvent = procedure(nCh: Integer; sMsg: string) of object;
  TxMaintEvent = procedure(nCh: Integer; sMsg: string) of object;

  //-----------------
  TRxDataPg   = record
		NgOrYes   : Integer;
    DataLen   : Word;
    Data      : array [0..8191] of Byte; //TBD:ITOLED:Flash?
	end;

  PPwrValPg = ^RPwrValPg;
  RPwrValPg = record     //TBD:AF9?
    VCC : integer;
    VEL : integer;
    ICC : integer;
    IEL : integer;
  end;

  //-----------------
  PGuiAF92Main = ^RGuiAF92Main;
  RGuiAF92Main = packed record
    MsgType  : Integer;
    PgNo     : Integer;
    Mode     : Integer;
    Param    : Integer;
    sMsg     : string;
  end;

  PGuiAF92Test = ^RGuiAF92Test;
  RGuiAF92Test = packed record
    MsgType  : Integer;
    PgNo     : Integer;
    Mode     : Integer;
    Param    : Integer;
    sMsg     : string;
    PwrValPg : RPwrValPg; //TBD:AF9?
  end;

  PGuiPgDownData = ^TGuiPgDownData; //DownloadBmpPg //TBD:AF9?
  TGuiPgDownData = packed record
    MsgType : Integer;
    PgNo    : Integer;
    Mode    : Integer;
    Total   : Integer;
    CurPos  : Integer;
    Param   : Integer;
    IsDone  : Boolean;
    sMsg    : string;
  end;

  //-----------------
  RPatDispStatus = record   //FEATURE_GRAY_CHANGE, FEATURE_DIMMING_STEP
    bPowerOn        : Boolean;
    bPatternOn      : Boolean;
    // FEATURE_GRAY_CHANGE
    nCurrPatNum     : Integer;
    nCurrAllPatIdx  : Integer;  //index of AllPat
    bSimplePat      : Boolean;
    nGrayOffset     : Integer;  //Gray Change Offset Value (-255~255)
    bGrayChangeR, bGrayChangeG, bGrayChangeB : Boolean;  //if (Simple Pattern) and (R|G|B Valuse is not 0) then True else False
    // FEATURE_DIMMING_STEP
    nCurrPwmDuty    : Integer; //0~100
    nCurrDimmingStep: Integer; //1~4
  end;



  //----------------- BMP Download
  TFileTranStr = record
    TransMode : Integer;
    TransType : Integer;
    TransSigId : Word;  //TBD:ITOLED?
    TotalSize : Integer;
    fileName  : string[80];
    filePath  : string[200];
    CheckSum  : DWORD;
    BmpWidth  : DWORD; //2021-11-10 DP201:BMP_DOW //TBD:ITOLED?
    Data      : array of Byte;
  end;

  TPwrDataPg = record //TBD:AF9?
    VCC     : word; // 1 = 1mV
    VDD_VEL : word; // 1 = 1mV   //ELVDD  //Auto(VDD),Foldable(VEL)
    VBR     : word; // 1 = 1mV   //VBRa
    ICC     : word; // 1 = 1mA
    IDD_IEL : word; // 1 = 1mA   //ELIDD  //Auto(IDD),Foldable(IEL)
    VddXXX  : byte;
    dummy1  : byte;
    dummy2  : byte;
    dummy3  : byte;
    dummy4  : byte;
    NG      : byte; // 0xFF: All OK
	end;

  //----------------- Flash Read/Write/Data
  TFlashData = record    //TBD:ITOLED?
    StartAddr      : DWORD;   //TBD:ITOLED?
    Size           : DWORD;
    Data           : array[0..(DefAF9.MAX_FLASHSIZE_BYTE-1)] of Byte;
    Checksum       : UInt32;
  //ChecksumCalc   : UInt32;
    //
    bValid         : Boolean;
  //SaveFilePath   : string;
  //SaveFileName   : string;
  end;

//TPgFlashAccessSts = (flashAccessUnknown=0, flashAccessDisabled=1, flashAccessEnabled=2);

  TFlashReadType = (flashReadNone=0, flashReadUnit=1, flashReadGamma=2, flashReadAll=2); //TBD:ITOLED?
  TFlashRead = record    //FOLD:EDNA:FLASH  //TBD:ITOLED?
    ReadType       : TFlashReadType;
    ReadSize       : Integer;
    RxSize         : Integer;
    RxData         : array[0..(DefAF9.MAX_FLASHSIZE_BYTE-1)] of Byte;
    ChecksumRx     : UInt32;
    ChecksumCalc   : UInt32;
    //
    bReadDone      : Boolean;
    SaveFilePath   : string;
    SaveFileName   : string;
  end;

  {$IFDEF PANEL_FOLDABLE}
  TFlashUnitStatus = (flashUnitEmpty=0, flashUnitRead=1, flashUnitUpdated=2, flashUnitWriteErr=3); //FOLD:EDNA:FLASH   //TBD:ITOLED?
  TFlashUnitBuf = record  //FOLD:EDNA:FLASH
    UnitAddr       : UInt32;
    UnitSize       : UInt32;
    UnitStatus     : TFlashUnitStatus;
    Data           : array[0..(DefPG.FLASH_DATAUNIT_SIZE-1)] of Byte;
    Checksum       : UInt32;
  end;
  {$ENDIF}

  //---------------------------------------------------------------------------- TAF9Fpga
  TAF9Fpga = class(TObject)

  private
    //------------------------------------------------------ COMMON
    m_nOldPatNum : Integer;
    //------------------------------------------------------ AF9
    //------------------------------------------------------ FLOW-specific
    //------------------------------------------------------ ETC
		
    {$IFDEF SIMULATOR_PANEL}
    SimTconData   : array[0..SIM_TCON_SIZE] of Byte;
    SimAPSRegData : array[0..SIM_APSREG_SIZE] of Byte;
    {$ENDIF}

	public
		//------------------------------------
    m_hMain    : HWND; // frmMain
    m_hTest    : HWND; // frmTest
    m_hGuiDown : HWND; // BmpDown
    m_nCh      : Integer;             // 0(CH1), 1(CH2), 2(ALL)
    m_nAF9Ch   : AF9_enumCHANNEL_TYPE; // 0(ALL), 1(CH1), 2(CH2)
		//------------------------------------ AF9-specific
	  m_PgConnSt     : enumPgConnSt;  //# StatusPg: TPgStatus //TBD:ITOLED?
    m_nAF9VerFpga  : Integer;
    m_nAF9VerDll   : Integer;
    m_sAF9APIType  : string;  //Debug
		//------------------------------------
    m_bCyclicTimer : Boolean; 
    m_nConnCheckNG : Integer;
    tmConnCheck    : TTimer;
		//------------------------------------
    m_bPwrMeasure  : boolean;
    tmPwrMeasure   : TTimer;
    m_PwrValPg     : RPwrValPg;   //TBD:AF9?
    m_PwrValAF9    : RPwrValAF9;  //TBD:AF9?
    //
		//------------------------------------FLOW-specific
    m_sFwVerPg     : string;  //Format(FPGA%0.3d_DLL%0.3d) for AF9 //TBD:AF9?
    m_nPatNumPrev  : Integer;
    m_nPatNumNow   : Integer;
    m_FlashData    : TFlashData; //TBD:ITOLED?

    FRxDataPg      : TRxDataPg;


    FIsMainter: Boolean;
    FOnTxMaintEvent: TxMaintEvent;
    FOnRxMaintEvent: RxMaintEvent;

		//?????????????????????????
		//?????????????????????????
		//?????????????????????????
    m_bPowerOn : Boolean;

    constructor Create(hMain, hTest: THandle; nCh: Integer); virtual;
    destructor Destroy; override;
    //-------------------------------------------------------------------------- AF9_API
		//------------------------------------
		function AF9_Start_Connection: Integer;
		function AF9_Stop_Connection: Integer;   //TBD:AF9:API? MULTI?
		function AF9_Connection_Status: Integer;
		//------------------------------------
		function AF9_SW_Revision: Integer;
		function AF9_DLL_Revision: Integer;      //TBD:AF9:API? MULTI?
		//------------------------------------
		function AF9_DAC_SET(nType: Integer; Channel: Integer; Voltage: Integer; Option: Integer): Boolean; //type->nType
		function AF9_ExtendIO_Set(Address: Integer; Channel: Integer; Enable: Integer): Boolean;
		function AF9_AllPowerOnOff(OnOff: Integer): Integer;
		//------------------------------------
		function AF9_APSPatternRGBSet(R, G, B: Integer): Integer;
		function AF9_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, Background_R,Background_G,Background_B: Integer): Integer;
		//------------------------------------
		function AF9_LGDSetReg(Addr: DWORD; data: Byte): Integer;
		function AF9_LGDSetRegM(LGDCommand: AF9_PLGDCommand; CommandCnt: Integer): Integer;
		function AF9_LGDGetReg(Addr: DWORD): Byte;
		function AF9_LGDRangeGetReg(const pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte;
		//------------------------------------
		function AF9_APSSetReg(Addr: Integer; Data: Integer): Integer;
		//------------------------------------
		function AF9_SendHexFileCRC(CRC: Word): Integer;
		function AF9_SendHexFile(const pbyteBuffer: PByte; len: Integer): Integer;
    function AF9_SendHexFileOC(const pbyteBuffer: PByte; len: Integer): Integer;
		//------------------------------------
		function AF9_WriteBMPFile(const pbyteBuffer: PByte; len: Integer): Integer;
		function AF9_BMPFileSend(pbyteBuffer: PByte; len: Integer; num: Integer): Integer;
		function AF9_BMPFileView(num: Integer): Integer;
		//------------------------------------
		function AF9_FLASHRead(const pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte;
		//------------------------------------
		function AF9_FrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTN1,PTN2,PTN3,PTN4,PTN5,PTN6: Byte; Hz: Integer): Integer;
		//------------------------------------------------------ /TBD:AF9:API? MULTI?
		function AF9_InitAF9API: Boolean;
		function AF9_FreeAF9API: Boolean;
		function AF9_IsVaildUSBHandler: Boolean;
		function AF9_SetResolution(ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP: Integer): Integer;
		function AF9_SetFreqChange(const pbyteBuffer: PByte; len: Integer; HzCnt: Integer; nRepeat: Integer): Integer;
		//------------------------------------------------------
		function AF9_APSFrrSet(FrrStart: Integer; R,G,B, BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD): Integer;
		function AF9_APSFrrSet2(FrrStart: Integer; R,G,B, BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz:Integer): Integer;
		function AF9_APSSFRSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz: Integer): Integer;
		//------------------------------------------------------
	//function AF9_APS_REG_Set(Address: Integer; Data: Integer): Boolean; 
	//function AF9_PatternRGBSet(R, G, B: Integer): Integer;
	//function AF9_Set_Power(ch: Integer; Vol: Integer; Option: Integer): Boolean;
	//function AF9_WriteHexFile(const pbyteBuffer: PByte; len: Integer): Integer;

    //-------------------------------------------------------------------------- PG
    function IsPgReady: Boolean;
    procedure ConnCheckTimer(Sender: TObject);
		//------------------------------------------------------
		//------------------------------------------------------
    function SendPowerOn(nMode: Integer; nWait: Integer = 10000; nTryCnt: Integer = 1) : DWORD;
		//------------------------------------------------------
    function SendI2CRead(nDevAddr,nRegAddr,nDataCnt: Integer; nWaitSec: Integer=2000; nTryCnt: Integer=1): DWORD;
		{$IFDEF INSPECTOR_POCB}
    function SendI2CWrite(nDevAddr,nRegAddr,nDataCnt: Integer; arrData: TIdBytes; nWaitSec: Integer=2000; nTryCnt: Integer=1): DWORD;
		{$ELSE}
    function SendI2CWrite(nDevAddr,nRegAddr,nDataCnt: Integer; arrData: array of Integer; nWaitSec: Integer=2000; nTryCnt: Integer=1): DWORD;	
		{$ENDIF}
		//------------------------------------------------------
    function SendDimming(nDimming: Integer; nTryCnt: Integer = 1): DWORD;
    function SendDisplayPat(nIdx: Integer; nWait : Integer = 3000; nTryCnt: Integer = 1): DWORD;
    function SendDisplayPwmPat(nIdx: Integer; nWait : Integer = 3000; nTryCnt: Integer = 1): DWORD;
//    function SendGrayChange(nGrayOffset: Integer): DWORD;
    function SendSetColorRGB(nR,nG,nB: Integer): Integer;  //FEATURE_GRAY_CHANGE
    function SendDisplayOnOff(bOn: Boolean): DWORD; //A2CHv3:ASSY-POCB:FLOW
		//------------------------------------------------------
    function GetFlashData(nAddr,nLen: DWORD; pBuf: PByte): DWORD; //TBD:ITOLED?
    function UpdateFlashData(nAddr,nLen: DWORD; pBuf: PByte): DWORD; //TBD:ITOLED?		
//    function SendFlashRead(nAddr,nSize: DWORD; pDataBuf: PByte; nWaitMS: Integer=5000; nRetry: Integer=0): DWORD; //TBD:ITOLED?
    function SendFlashWrite(nAddr,nSize: DWORD; const pData: PByte; nWaitMS: Integer = 100000; nRetry: Integer = 0): DWORD; //TBD:ITOLED?

		//------------------------------------------------------ Mainter
    procedure SetIsMainter(const Value: Boolean);
    procedure SetOnTxMaintEvent(const Value: TxMaintEvent);
    procedure SetOnRxMaintEvent(const Value: RxMaintEvent);

    property IsMainter : Boolean read FIsMainter write SetIsMainter;
    property OnRxMaintEvent : RxMaintEvent read FOnRxMaintEvent write SetOnRxMaintEvent;
    property OnTxMaintEvent : TxMaintEvent read FOnTxMaintEvent write SetOnTxMaintEvent;

		//?????????????????????????
		//?????????????????????????
		//?????????????????????????
    //
    function PgDownBmpFile(const transData: TFileTranStr; bSelfTestForceNG: Boolean = False): Boolean; //TBD:ITOLED?
    function PgDownBmpFiles(nFileCnt: Integer; const arTransData: TArray<TFileTranStr>): Boolean; //TBD:ITOLED?
    procedure PwrMeasureTimer(Sender: TObject);
    procedure SetCyclicTimer(bEnable: Boolean; nDisableSec: Integer = 0);
    function CheckPowerLimit(PwrVal: RPwrValAF9): Boolean;
    function SendPowerMeasure: DWORD;
    procedure SetPowerMeasureTimer(bEnable: Boolean; nInterval : Integer = 1000); //TBD:AF9?
    procedure SendBmpData(nTransDataCnt : Integer;const transData: TArray<TFileTranStr>); //#TDongaPG.SendPgTransDat
    function SendModelInfo(handle: HWND): DWORD;
    //
    //

    procedure ShowMainWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);
    procedure ShowTestWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);

    //

	end;

var
  PGAF9Fpga : array[DefCommon.CH1..DefCommon.MAX_CH] of TAF9Fpga;

implementation

{$IF Defined(INSPECTOR_FI) or Defined(INSPECTOR_OQA)}
uses
  pasScriptClass;
{$ENDIF}

{$r+} // memory range check.

{ AF9Fpga }

//##############################################################################
//###
//### AF9_API (1CH)
//###
//##############################################################################

//==============================================================================
// AF9_API (1CH)
//==============================================================================

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_Start_Connection: Integer;
var
  sApiFunc : string;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := 'MULTI_Start_Connection';
	{$ELSE}
  sApiFunc := 'Start_Connection';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc;
//if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_STARTCONN_OK; //AF9API_STARTCONN_OK
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_Start_Connection;
	{$ELSE}
  Result := AF9API_Start_Connection;
	{$ENDIF}
{$ENDIF}
	//
  sApiFunc := m_sAF9APIType + sApiFunc + Format(':(%d) ',[Result]);
	case Result of
     1  : sApiFunc := sApiFunc + 'OK';
     0  : sApiFunc := sApiFunc + 'NG(USB Device Not Found)';
		-1  : sApiFunc := sApiFunc + 'NG(USB Library Open Fail)';
    else  sApiFunc := sApiFunc + 'NG(Unknown Result)';
	end;
  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnRxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	
  Result := AF9API_STARTCONN_OK; //2022-03-24 TBD:AF9? IMSI?
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_Stop_Connection: Integer;
var
  sApiFunc : string;
begin
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_Stop_Connection[CH%d]',[Integer(m_nAF9Ch)]);
//{$ELSE}
  sApiFunc := 'Stop_Connection';
//{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc;
//if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_MULTI_Stop_Connection(Integer(m_nAF9Ch));
//{$ELSE}
  Result := AF9API_Stop_Connection;  
//{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_Connection_Status: Integer;
var
  sApiFunc : string;
begin
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_Connection_Status[CH%d]',[Integer(m_nAF9Ch)]);
//{$ELSE}
  sApiFunc := 'Connection_Status';
//{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc;
//if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_Connection_Status(Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_Connection_Status;
	{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
{$ENDIF}
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_SW_Revision: Integer;
var
  sApiFunc : string;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_SW_Revision[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'SW_Revision';
	{$ENDIF}
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := 123;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_SW_Revision(Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_SW_Revision;
	{$ENDIF}
{$ENDIF}
	//
  sApiFunc := m_sAF9APIType + sApiFunc + Format(':(%d) ',[Result]);
  ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_DLL_Revision: Integer;
var
  sApiFunc : string;
begin
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_DLL_Revision[CH%d]',[m_nAF9Ch]);
//{$ELSE}
  sApiFunc := 'DLL_Revision';
//{$ENDIF}
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := 456;
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_MULTI_DLL_Revision(m_nAF9Ch); 
//{$ELSE}
  Result := AF9API_DLL_Revision;
//{$ENDIF}
{$ENDIF}
	//
  sApiFunc := m_sAF9APIType + sApiFunc + Format(':(%d) ',[Result]);
  ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_DAC_SET(nType: Integer; Channel: Integer; Voltage: Integer; Option: Integer): Boolean; //type->nType
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_DAC_SET[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'DAC_SET';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(type=%d,channel=%d,voltage=%d,option=%d)',[nType,Channel,Voltage,Option]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := True;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_DAC_SET(nType, Channel, Voltage, Option, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_DAC_SET(nType, Channel, Voltage, Option);
	{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + TernaryOp((Result=True), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result=True),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_ExtendIO_Set(Address: Integer; Channel: Integer; Enable: Integer): Boolean;
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_ExtendIO_Set[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'ExtendIO_Set';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(addr=%d,channel=%d,enable=%d)',[Address,Channel,Enable]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := True;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_ExtendIO_Set(Address, Channel, Enable, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_ExtendIO_Set(Address, Channel, Enable);
	{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result=True), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result=True),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_AllPowerOnOff(OnOff: Integer): Integer;
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_AllPowerOnOff[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'AllPowerOnOff';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(OnOff=%d)',[OnOff]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_AllPowerOnOff(OnOff, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_AllPowerOnOff(OnOff);
	{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_APSPatternRGBSet(R, G, B: Integer): Integer;
var
  sApiFunc : string;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_APSPatternRGBSet[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'APSPatternRGBSet';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(R=%d,G=%d,B=%d)',[R,G,B]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_APSPatternRGBSet(R,G,B, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_APSPatternRGBSet(R,G,B);
	{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, Background_R,Background_G,Background_B: Integer): Integer;
var
  sApiFunc : string;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_APSBoxPatternSet[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'APSBoxPatternSet';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(X=%d,Y=%d, W=%d,H=%, R=%dG=%dB=%d, BR=%d,BG=%d,BB=%d)',[XOffset,YOffset, Width,Height, R,G,B, Background_R,Background_G,Background_B]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, Background_R,Background_G,Background_B, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, Background_R,Background_G,Background_B);
	{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_LGDSetReg(Addr: DWORD; data: Byte): Integer;
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_LGDSetReg[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'LGDSetReg';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(addr=%d,data=0x%0.2x)',[Addr,data]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_LGDSetReg(Addr, data, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_LGDSetReg(Addr, data);
	{$ENDIF}
{$ENDIF}
  {$IFDEF SIMULATOR_PANEL}
  SimTconData[Addr] := data;
  {$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_LGDSetRegM(LGDCommand: AF9_PLGDCommand; CommandCnt: Integer): Integer;
var
  sApiFunc : string;
  {$IFDEF SIMULATOR_PANEL}
  i : Integer;
  pCommand : AF9_PLGDCommand;
  {$ENDIF}
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_LGDSetRegM[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'LGDSetRegM';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(CmdCnt=%d)',[CommandCnt]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_LGDSetRegM(LGDCommand, CommandCnt, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_LGDSetRegM(LGDCommand, CommandCnt);
	{$ENDIF}
{$ENDIF}
  {$IFDEF SIMULATOR_PANEL}
  pCommand := LGDCommand;
  for i := 0 to (CommandCnt-1) do begin
    SimTconData[pCommand^.Addr] := pCommand^.Data;
    Inc(pCommand);  //TBD:ITOLED?
  end;
  {$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_LGDGetReg(Addr: DWORD): Byte;
var
  sApiFunc : string;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_LGDGetReg[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'LGDGetReg';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(addr=%d)',[addr]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IF Defined(SIMULATOR_PG) or Defined(SIMULATOR_PANEL)}
  Result := SimTconData[Addr];
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_LGDGetReg(addr, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_LGDGetReg(addr);
	{$ENDIF}
{$ENDIF}
  sApiFunc := sApiFunc + Format(':(0x%0.2x)',[Result]);
	//
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_LGDRangeGetReg(const pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte;
var
  sApiFunc : string;
  i, nCnt  : Integer;
  pData    : PByte;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_LGDRangeGetReg[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'LGDRangeGetReg';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(start=%d,end=%d)',[StartAddr,EndAddr]); //TBD:AF9? Result?
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IF Defined(SIMULATOR_PG) or Defined(SIMULATOR_PANEL)}
  Result := 1; //TBD:ITOLED? API:SIM
  pData  := pBuffer;
  for i := 0 to (EndAddr-StartAddr+1) do begin
    pData^ := SimTconData[StartAddr+i];
    Inc(pData);
  end;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_LGDRangeGetReg(pBuffer, StartAddr,EndAddr, Integer(m_nAF9Ch)); //TBD:ITOLED? Result?
	{$ELSE}
  Result := AF9API_LGDRangeGetReg(pBuffer, StartAddr,EndAddr);
	{$ENDIF}
{$ENDIF}
  //
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
  sApiFunc := sApiFunc + '(';
  nCnt  := EndAddr - StartAddr + 1;
  pData := pBuffer;
  for i := 0 to (nCnt-1) do begin
    sApiFunc := sApiFunc + Format('0x%0.2x ',[pData^]);
    Inc(pData);
  end;
  sApiFunc := sApiFunc + ')';
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_APSSetReg(Addr: Integer; Data: Integer): Integer;
var
  sApiFunc : string;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_APSSetReg[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'APSSetReg';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(addr=%d,data=0x%0.2x)',[Addr,Data]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_APSSetReg(Addr, Data, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_APSSetReg(Addr, Data);
	{$ENDIF}
{$ENDIF}
  {$IFDEF SIMULATOR_PANEL}
  SimAPSRegData[Addr] := data;
  {$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
// HEX File write
//    Write the hex file to the SPI Flash memory on the module.
//    Writing process takes about 20sec and user must reboot FPGA board after hex write.
//    * When FPGA board transmits hex file, CRC is also transmitted together.
//       After transmitting hex file completed, FPGA board compare hex file in the FPGA and Flash memory
//       If CRC data in the FPGA and Flash memory are not the same, FPGA board will turn off power on the driving board
//       During transmission, LED2 of the FPGA Board turns on, and turns off when completed.
function TAF9Fpga.AF9_SendHexFileCRC(CRC: Word): Integer;
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_SendHexFileCRC[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'SendHexFileCRC';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(CRC=0x%x)',[CRC]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_SendHexFileCRC(CRC, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_SendHexFileCRC(CRC);
	{$ENDIF}
{$ENDIF}
	//-------------------------------------
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;


function TAF9Fpga.AF9_SendHexFileOC(const pbyteBuffer: PByte; len: Integer): Integer;
var
  sApiFunc  : string;
{$IFDEF SIMULATOR_PG}
  sFileName : string;
{$ENDIF}
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_SendHexFileOC[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'SendHexFileOC';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(Len=%d)',[len]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_SendHexFileOC(pbyteBuffer, len, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_SendHexFileOC(pbyteBuffer, len);
	{$ENDIF}
{$ENDIF}
{$IFDEF SIMULATOR_PG}
	sFileName := Common.Path.FLASH + Format('FlashWrite_CH%d_0_%d_%s.hex',[Integer(m_nAF9Ch),len,TernaryOp((Result=AF9API_RESULT_OK),'OK','NG')]);
  Common.SaveHexLog(sFileName,len,pbyteBuffer);
{$ENDIF}
  //
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_SendHexFile(const pbyteBuffer: PByte; len: Integer): Integer;
var
  sApiFunc  : string;
{$IFDEF SIMULATOR_PG}	
  sFileName : string;
{$ENDIF}
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_SendHexFile[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'SendHexFile';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(Len=%d)',[len]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_SendHexFile(pbyteBuffer, len, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_SendHexFile(pbyteBuffer, len);
	{$ENDIF}
{$ENDIF}
{$IFDEF SIMULATOR_PG}
	sFileName := Common.Path.FLASH + Format('FlashWrite_CH%d_0_%d_%s.hex',[Integer(m_nAF9Ch),len,TernaryOp((Result=AF9API_RESULT_OK),'OK','NG')]);
  Common.SaveHexLog(sFileName,len,pbyteBuffer);
{$ENDIF}
  //
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//------------------------------------------------------------------------------
// Transmit BMP File.
//    The resolution of the BMP file is 2920x1900x3Byte
//    and the actual image display area is 2916x1900.
//    During transmission, LED2 of the FPGA Board turns on, and turns off when completed.
//    BMP turns on only when KEY4 is pressed.
//
function TAF9Fpga.AF9_WriteBMPFile(const pbyteBuffer: PByte; len: Integer): Integer; // Send+View
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_WriteBMPFile[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'WriteBMPFile';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(len=%d)',[len]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_WriteBMPFile(pbyteBuffer, len, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_WriteBMPFile(pbyteBuffer, len);
	{$ENDIF}
{$ENDIF}
  //
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_BMPFileSend(pbyteBuffer: PByte; len: Integer; num: Integer): Integer; // Send
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_BMPFileSend[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'BMPFileSend';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(len=%d,num=%d)',[len,num]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_BMPFileSend(pbyteBuffer, len, num, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_BMPFileSend(pbyteBuffer, len, num);
	{$ENDIF}
{$ENDIF}
  //
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

function TAF9Fpga.AF9_BMPFileView(num: Integer): Integer; //View
var
  sApiFunc : String;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_BMPFileView[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'BMPFileView';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(num=%d)',[num]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_BMPFileView(num, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_BMPFileView(num);
	{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);

	Result := 1; //AF9API_RESULT_OK //TBD:AF9? 0값으로 리턴 확인 필요
end;

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_FLASHRead(const pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte;
var
  sApiFunc : string;
{$IF Defined(SIMULATOR_PANEL)}
  sFileName : string;
  pData : PByte;
  //
  txtF  : Textfile;
  sReadLine : string;
  nData  : Integer;
  btData : Byte;
{$ENDIF}
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_FLASHRead[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'FLASHRead';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(Start=%d,End=%d)',[StartAddr,EndAddr]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IF Defined(SIMULATOR_PANEL)}
  Result := AF9API_RESULT_NG;
  sFileName := Common.Path.FLASH + 'X2146_FLASH_SAMPLE.hex'; //TBD:ITOLED?
  if FileExists(sFileName) then begin
    if IOResult = 0 then begin
  		try
        nData := 0;
        pData := pBuffer;
        //
      	AssignFile(txtF, sFileName);
        Reset(txtF);
        while not Eof(txtF) do begin
          //
          Readln(txtF, sReadLine);
  				sReadLine := '$' + sReadline;
          btData := StrToIntDef(sReadLine,0);
          //
          pData^ := btData;
          Inc(pData);
          Inc(nData);
  			end;
        while (nData < EndAddr) do begin
          pData^ := $ff;
          Inc(pData);
          Inc(nData);
        end;
        Result := AF9API_RESULT_OK;
  		finally
        CloseFile(txtF);
  		end;
  	end;
  end;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_FLASHRead(pBuffer, StartAddr,EndAddr, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_FLASHRead(pBuffer, StartAddr,EndAddr);
	{$ENDIF}
{$ENDIF}
  //
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//-----------------------------------------------------------------------------
function TAF9Fpga.AF9_FrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTN1,PTN2,PTN3,PTN4,PTN5,PTN6: Byte; Hz: Integer): Integer;
var
  sApiFunc : string;
begin
	{$IFDEF AF9API_MULTI}
  sApiFunc := Format('MULTI_FrrSet[CH%d]',[Integer(m_nAF9Ch)]);
	{$ELSE}
  sApiFunc := 'FrrSet';
	{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(FrrStart=%d, R=%d,G=%d,B=%d, BR=%d,BG=%d,BB=%d, PTN1=%d,PTN2-%d,{TN3=%d,PTN4=%d,PTN5=%d,PTN6=%d, Hz=%d)',[FrrStart, R,G,B, BR,BG,BB, PTN1,PTN2,PTN3,PTN4,PTN5,PTN6, Hz]);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnTxMaintEvent(m_nCh,sApiFunc);
	//
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
	{$IFDEF AF9API_MULTI}
  Result := AF9API_MULTI_FrrSet(FrrStart, R,G,B, BR,BG,BB, PTN1,PTN2,PTN3,PTN4,PTN5,PTN6, Hz, Integer(m_nAF9Ch));
	{$ELSE}
  Result := AF9API_FrrSet(FrrStart, R,G,B, BR,BG,BB, PTN1,PTN2,PTN3,PTN4,PTN5,PTN6, Hz);
	{$ENDIF}
{$ENDIF}
	//
	sApiFunc := sApiFunc + Format(':(%d) ',[Result]) + TernaryOp((Result = AF9API_RESULT_OK), 'OK', 'NG');
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,TernaryOp((Result = AF9API_RESULT_OK),0,1),sApiFunc);
	if FIsMainter and Assigned(OnTxMaintEvent) then OnRxMaintEvent(m_nCh,sApiFunc);
end;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

//------------------------------------------------------------------------------
function TAF9Fpga.AF9_InitAF9API: Boolean;
//var
//sApiFunc : string;
begin
 	//TBD:AF9:v2.02? AF9API_InitAF9API;
  Result := True;
  //
 	//TBD:AF9:v2.02? sApiFunc := m_sAF9APIType itAF9API';
 	//TBD:AF9:v2.02? ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)  //TBD:ITOLED:DEBUG_AF9API?
end;

function TAF9Fpga.AF9_FreeAF9API: Boolean;
//var
//  sApiFunc : string;
begin
  //TBD:AF9:v2.02? AF9API_FreeAF9API;
  Result := True;
  //
  //TBD:AF9:v2.02? sApiFunc := m_sAF9APIType eeAF9API';
  //TBD:AF9:v2.02? ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)  //TBD:ITOLED:DEBUG_AF9API?
end;

function TAF9Fpga.AF9_IsVaildUSBHandler: Boolean;
//var
//  sApiFunc : string;
begin
{$IFDEF SIMULATOR_PG}
  Result := True;
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_SetResolution(ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP); //TBD:AF9?
//{$ELSE}
  Result := AF9API_IsVaildUSBHandler;
//{$ENDIF}
{$ENDIF}
  Result := AF9API_IsVaildUSBHandler;
end;

function TAF9Fpga.AF9_SetResolution(ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP: Integer): Integer;
var
  sApiFunc : string;
begin
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result   := AF9API_RESULT_OK;
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_SetResolution(ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP); //TBD:AF9?
//{$ELSE}
  Result := AF9API_SetResolution(ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP);
//{$ENDIF}
{$ENDIF}
	//-------------------------------------
  //
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_SetResolution[CH%d]',[m_nAF9Ch]);
//{$ELSE}
  sApiFunc := 'SetResolution';
//{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(H=%d,HBP,HSA,HFP, V=%d,VBP=%d,VSA=%d,VFP=%d)',[ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP]);
//  if Result = AF9API_RESULT_OK then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)  //TBD:ITOLED:DEBUG_AF9API?
//  else                              ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;

function TAF9Fpga.AF9_SetFreqChange(const pbyteBuffer: PByte; len: Integer; HzCnt: Integer; nRepeat: Integer): Integer;
var
  sApiFunc : string;
begin
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_MULTI_SetFreqChange(pbyteBuffer, len, HzCnt, nRepeat); //TBD:AF9?
//{$ELSE}
  Result := AF9API_SetFreqChange(pbyteBuffer, len, HzCnt, nRepeat);
//{$ENDIF}
{$ENDIF}
  Result := AF9API_SetFreqChange(pbyteBuffer, len, HzCnt, nRepeat);
	//-------------------------------------
  //
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_SetFreqChange[CH%d]',[m_nAF9Ch]);
//{$ELSE}
  sApiFunc := 'SetFreqChange';
//{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(Len=%d,HzCnt=%d,Repeat=%d)',[len, HzCnt, nRepeat]);
//  if Result = AF9API_RESULT_OK then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)  //TBD:ITOLED:DEBUG_AF9API?
//  else                              ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;


//------------------------------------------------------------------------------
function TAF9Fpga.AF9_APSFrrSet(FrrStart: Integer; R,G,B, BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD): Integer;
var
  sApiFunc : string;
begin
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result := AF9API_RESULT_OK;
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_MULTI_APSFrrSet(FrrStart, R,G,B, BR,BG,BB, PTNCnt, PTN); //TBD:AF9?
//{$ELSE}
  Result := AF9API_APSFrrSet(FrrStart, R,G,B, BR,BG,BB, PTNCnt, PTN);
//{$ENDIF}
{$ENDIF}
  //
	//-------------------------------------
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_APSFrrSet[CH%d]',[m_nAF9Ch]);
//{$ELSE}
  sApiFunc := 'APSFrrSet';
//{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc +  Format('(FrrStart=%d, R=%d,G=%d,B=%d, BR=%d,BG=%d,BB=%d, PtnCnt=%d,PTN=%d)',[FrrStart, R,G,B, BR,BG,BB, PTNCnt,PTN]);
//  if Result = AF9API_RESULT_OK then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)  //TBD:ITOLED:DEBUG_AF9API?
//  else                              ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;

function TAF9Fpga.AF9_APSFrrSet2(FrrStart: Integer; R,G,B, BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz:Integer): Integer;
var
  sApiFunc : string;
begin
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result   := AF9API_RESULT_OK;
  sApiFunc := 'AF9SIM_';
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_MULTI_APSFrrSet2(FrrStart, R,G,B, BR,BG,BB, PTNCnt, PTN, Hz); //TBD:AF9?
//{$ELSE}
  Result := AF9API_APSFrrSet2(FrrStart, R,G,B, BR,BG,BB, PTNCnt, PTN, Hz);
//{$ENDIF}
{$ENDIF}
  //
	//-------------------------------------
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_APSFrrSet2[CH%d]',[m_nAF9Ch]);
//{$ELSE}
  sApiFunc := 'APSFrrSet2';
//{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc +  Format('(FrrStart=%d, R=%d,G=%d,B=%d, BR=%d,BG=%d,BB=%d, PtnCnt=%d,PTN=%d, Hz=%d)',[FrrStart, R,G,B, BR,BG,BB, PTNCnt,PTN, Hz]);
//  if Result = AF9API_RESULT_OK then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)  //TBD:ITOLED:DEBUG_AF9API?
//  else                              ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;


function TAF9Fpga.AF9_APSSFRSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz: Integer): Integer;
var
  sApiFunc : string;
begin
	//-------------------------------------
{$IFDEF SIMULATOR_PG}
  Result   := AF9API_RESULT_OK;
{$ELSE}
//{$IFDEF AF9API_MULTI}
//Result := AF9API_MULTI_APSSFRSet(FrrStart, R,G,B, BR,BG,BB, PTNCnt, PTN, Hz); //TBD:AF9?
//{$ELSE}
  Result := AF9API_APSSFRSet(FrrStart, R,G,B, BR,BG,BB, PTNCnt, PTN, Hz);
//{$ENDIF}
{$ENDIF}
  //
	//-------------------------------------
//{$IFDEF AF9API_MULTI}
//sApiFunc := Format('MULTI_APSSFRSet[CH%d]',[m_nAF9Ch]);
//{$ELSE}
  sApiFunc := 'APSSFRSet';
//{$ENDIF}
  sApiFunc := m_sAF9APIType + sApiFunc + Format('(FrrStart=%d, R=%d,G=%d,B=%d, BR=%d,BG=%d,BB=%d, PtnCnt=%d,PTN=%d, Hz=%d)',[FrrStart, R,G,B, BR,BG,BB, PTNCnt,PTN, Hz]);
//  if Result = AF9API_RESULT_OK then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)  //TBD:ITOLED:DEBUG_AF9API?
//  else                              ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

{//TBD:AF9?
function TAF9Fpga.AF9_PatternRGBSet(R, G, B: Integer): Integer;
begin
  Result := AF9API_PatternRGBSet(R, G, B);
end;

function TAF9Fpga.AF9_APS_REG_Set(Address: Integer; Data: Integer): Boolean;
var
  sApiFunc : String;
begin
  Result := AF9API_APS_REG_Set(Address, Data);
  //
  sApiFunc := m_sAF9APIType + sApiFunc + Format('AF9_API: APS_REG_Set(Addr=%d,Data=%d)',[Address,Data]);
  if Result then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)   //TBD:ITOLED:DEBUG_AF9API?
  else           ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;

function TAF9Fpga.AF9_Set_Power(ch: Integer; Vol: Integer; Option: Integer): Boolean;
var
  sApiFunc : String;
begin
  Result := AF9API_Set_Power(ch, Vol, Option);
  //
  sApiFunc := m_sAF9APIType + sApiFunc + Format('AF9_API: Set_Power(Ch=%d,Vol=%d,Option=%d)',[ch, Vol, Option]);
  if Result then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)   //TBD:ITOLED:DEBUG_AF9API?
  else           ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;

function TAF9Fpga.AF9_WriteHexFile(const pbyteBuffer: PByte; len: Integer): Integer;  //TBD:ITOLED:AF9?
var
  sApiFunc : String;
begin
  Result := AF9API_WriteHexFile(pbyteBuffer, len);
  //
  sApiFunc := m_sAF9APIType + sApiFunc + Format('AF9_API: WriteHexFile(Len=%d)',[len]);
  if Result = AF9API_RESULT_OK then ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sApiFunc)   //TBD:ITOLED:DEBUG_AF9API?
  else                              ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sApiFunc + ' Failed');
end;
}

//##############################################################################
//##############################################################################
//###                                                                        ###
//##############################################################################
//##############################################################################

//==============================================================================
// procedure/function: 
//
constructor TAF9Fpga.Create(hMain, hTest: THandle; nCh: Integer);
{$IFDEF SIMULATOR_PANEL}
var
  i : integer;
{$ENDIF}
begin
	//------------------------------------
	m_hMain   := hMain;
	m_hTest   := hTest;
  m_nCh     := nCh;
  if m_nCh = 0 then m_nAF9Ch := AF9_enumCHANNEL_TYPE.AF9CH_1
  else                           m_nAF9Ch := AF9_enumCHANNEL_TYPE.AF9CH_2;
	//------------------------------------ AF9-Specific
  m_PgConnSt    := PgConnStDisconn;
  m_nAF9VerFpga := 0;
  m_nAF9VerDll  := 0;
	//------------------------------------
	m_bCyclicTimer := False;
  m_nConnCheckNG := 0;
  //
  tmConnCheck := TTimer.Create(nil);
	tmConnCheck.OnTimer  := ConnCheckTimer;
	tmConnCheck.Interval := 2000;  //TBD:AF9?
	tmConnCheck.Enabled  := False; //IMSI??????
	//------------------------------------
  m_bPwrMeasure := False;
  //
  tmPwrMeasure := TTimer.Create(nil);
	tmPwrMeasure.OnTimer  := PwrMeasureTimer;
	tmPwrMeasure.Interval := 3000;  //TBD:AF9?
	tmPwrMeasure.Enabled  := False;

	//------------------------------------TBD:????
  //
  m_bPowerOn    := False;
  m_nPatNumPrev := 0;
	m_nPatNumNow  := 0;
	//
  FIsMainter := False;

	{$IFDEF SIMULATOR_PG}
  m_sAF9APIType := '<AF9_SIM> ';
	{$ELSE}
  m_sAF9APIType := '<AF9_API> ';
	{$ENDIF}

  {$IFDEF SIMULATOR_PANEL}
  for i := 0 to (SIM_TCON_SIZE-1) do
    SimTconData[i] := $00;
  for i := 0 to (SIM_APSREG_SIZE-1) do
    SimAPSRegData[i] := $00;
  {$ENDIF}
end;

destructor TAF9Fpga.Destroy;
begin
  AF9_Stop_Connection;

	//------------------------------------
  if tmConnCheck <> nil then begin
    tmConnCheck.Enabled := False;
    tmConnCheck.Free;
    tmConnCheck := nil;
  end;
  if tmPwrMeasure <> nil then begin
    tmPwrMeasure.Enabled := False;
    tmPwrMeasure.Free;
    tmPwrMeasure := nil;
  end;
	//------------------------------------TBD:AF9?
  inherited;
end;

//==============================================================================
// procedure/function:
//    - procedure TAF9Fpga.SetCurPatGrInfo(const Value: TPatternGroup);
//    - procedure TAF9Fpga.SetDisPatStruct(const Value: TPatInfoStruct);
//


//==============================================================================
// procedure/function: 
//
procedure TAF9Fpga.SetIsMainter(const Value: Boolean);
begin
  FIsMainter := Value;
end;

procedure TAF9Fpga.SetOnRxMaintEvent(const Value: RxMaintEvent);
begin
  FOnRxMaintEvent := Value;
end;

procedure TAF9Fpga.SetOnTxMaintEvent(const Value: TxMaintEvent);
begin
  FOnTxMaintEvent := Value;
end;

//##############################################################################
//##############################################################################
//###                                                                        ###
//##############################################################################
//##############################################################################

function TAF9Fpga.IsPgReady: Boolean;
begin
  Result := False;
  if m_PgConnSt in [PgConnStConn] then Result := True;
end;

//==============================================================================
// procedure/function: Timer
//		- 

//
// [Ref:AF9_API_MFC_TEST] AF9_API_MFC_TESTDlg.cpp/CAF9_API_MFC_TESTDlg::OnTimer(UINT_PTR nIDEvent)
//
procedure TAF9Fpga.ConnCheckTimer(Sender: TObject);
var
	nRtnAF9 : Integer;
//bConnSt : Boolean;
begin
	try
    // Start Connection if AF9ConnStDisconn
		if (m_PgConnSt = PgConnStDisconn) {or (m_PgConnSt = pgConnStStart)} then begin
			m_bCyclicTimer := True;
      nRtnAF9 := AF9_Start_Connection; //AF9API_Start_Connection;
			if nRtnAF9 = AF9API_STARTCONN_OK then begin
      	m_PgConnSt := pgConnStStart;
      end
      else begin
//				ShowTestWindow(Defcommon.MSG_MODE_DISPLAY_CONNECTION,0{Disconnected},'AF9 Disconnect(Start Fail)'); //TBD:AF9?
  			Exit;
			end;
    end;

		// Exit if Disable Timers
		if (not m_bCyclicTimer) then Exit;
		if m_bPwrMeasure and tmPwrMeasure.Enabled then Exit;

		// Check Connection Status and Update Status if changed
  //nRtnAF9 := AF9_Connection_Status;
    {$IFDEF SIMULATOR_PG}
      nRtnAF9 := AF9_Connection_Status;
    {$ELSE}
    	{$IFDEF AF9API_MULTI}
      nRtnAF9 := AF9API_MULTI_Connection_Status(Integer(m_nAF9Ch));
    	{$ELSE}
      nRtnAF9 := AF9API_Connection_Status;
    	{$ENDIF}
  	{$ENDIF}
    if nRtnAF9 = AF9API_RESULT_OK then begin
			// Connected
		  if (m_PgConnSt = pgConnStStart) or (m_nAF9VerFpga = 0) or (m_nAF9VerDll = 0) then begin
        m_nAF9VerFpga := AF9_SW_Revision;  // FPGA Version //AF9API_SW_Revision;
        m_nAF9VerDll  := AF9_DLL_Revision; // DLL Version
        m_PgConnSt    := pgConnStConn;
//				ShowTestWindow(Defcommon.MSG_MODE_DISPLAY_CONNECTION,1{Connected+Version},'AF9 Connected'); //TBD:AF9?
//				ShowMainWindow(Defcommon.MSG_MODE_DISPLAY_CONNECTION,1{Connected+Version},'AF9 Connected'); //TBD:AF9?
        // Change ConnCheck Interval
  			tmConnCheck.Enabled  := False; //TBD:AF9?
  			tmConnCheck.Interval := 2000;  //TBD:AF9?
  			tmConnCheck.Enabled  := True;  //TBD:AF9?
      end;
      m_nConnCheckNG := 0;
    end
    else begin
			// Disconnected
      Inc(m_nConnCheckNG);
			if (m_PgConnSt <> pgConnStDisconn) and (m_nConnCheckNG >= 1) then begin //Connected->Disconnected //TBD:AF9? 1?
        m_PgConnSt    := pgConnStDisconn;
        m_nAF9VerFpga := 0; // Clear FPGA Version
        m_nAF9VerDll  := 0; // Clear DLL Version
//				ShowTestWindow(Defcommon.MSG_MODE_DISPLAY_CONNECTION,2{Disconnected},'AF9 Disconnected'); //TBD:AF9?
//				ShowMainWindow(Defcommon.MSG_MODE_DISPLAY_CONNECTION,2{Disconnected},'AF9 Disconnected'); //TBD:AF9?
        // Change ConnCheck Interval
  			tmConnCheck.Enabled  := False; //TBD:AF9?
  			tmConnCheck.Interval := 1000;  //TBD:AF9?
  			tmConnCheck.Enabled  := True;  //TBD:AF9?
        // Disable PwrMeasure Timer
				tmPwrMeasure.Enabled := False;
				m_bPwrMeasure := False;
      end; 
    end;
	except
		OutputDebugString(PChar('>> ConnCheckTimer Exception Error!!'));
	end;
end;

procedure TAF9Fpga.PwrMeasureTimer(Sender: TObject);
begin
	if (not m_bCyclicTimer) then Exit;
	if (not m_bPwrMeasure)  then Exit;

	try
		//TBD:AF9?
	except
		OutputDebugString(PChar('>> PwrMeasureTimer Exception Error!!'));
	end;
end;

procedure TAF9Fpga.SetCyclicTimer(bEnable: Boolean; nDisableSec: Integer = 0);
begin
  if m_bCyclicTimer = bEnable then Exit;  // Already Enabled/Disabled
  //
  m_bCyclicTimer      := bEnable;
  tmConnCheck.Enabled := bEnable;
  if m_bPwrMeasure then tmPwrMeasure.Enabled := bEnable;
  m_nConnCheckNG := 0;
  //
  if (not bEnable) and (nDisableSec > 0) then begin  // Disable(Duaration!=0)
    TThread.CreateAnonymousThread(procedure var nCnt : Integer;
    begin
      for nCnt := 1 to nDisableSec do begin
        if m_bCyclicTimer then Exit;
        Sleep(1000);
      end;
      // Enable after nDisableSec expired
      m_bCyclicTimer := True;
      tmConnCheck.Enabled := True;
      if m_bPwrMeasure then tmPwrMeasure.Enabled := True;
    end).Start;
  end;
end;


//##############################################################################
//##############################################################################
//###                                                                        ###
//##############################################################################
//##############################################################################

function TAF9Fpga.GetFlashData(nAddr,nLen: DWORD; pBuf: PByte): DWORD; //TBD:ITOLED?
var
  nRtn : DWORD;
begin
  Result := WAIT_FAILED;
  //
  if not m_FlashData.bValid then Exit; //TBD:ITOLED? //FlashRead?

  if (nAddr < m_FlashData.StartAddr) then Exit; //TBD:ITOLED? //FlashRead?
  if (nAddr+nLen) > (m_FlashData.StartAddr+m_FlashData.Size) then Exit; //TBD:ITOLED? //FlashRead?

  CopyMemory(pBuf,@m_FlashData.Data[nAddr],nLen);
  Result := WAIT_OBJECT_0;
end;

function TAF9Fpga.UpdateFlashData(nAddr,nLen: DWORD; pBuf: PByte): DWORD; //TBD:ITOLED?
var
  nRtn : DWORD;
  i : Integer;
begin
  Result := WAIT_FAILED;
  //
  if not m_FlashData.bValid then Exit; //TBD:ITOLED? //FlashRead?

  if (nAddr < m_FlashData.StartAddr) then Exit; //TBD:ITOLED? //FlashRead?
  if (nAddr+nLen) > (m_FlashData.StartAddr+m_FlashData.Size) then Exit; //TBD:ITOLED? //FlashRead?

  CopyMemory(@m_FlashData.Data[nAddr],pBuf,nLen);
  Result := WAIT_OBJECT_0;
end;


function TAF9Fpga.PgDownBmpFile(const transData: TFileTranStr; bSelfTestForceNG: Boolean = False): Boolean; //TBD:ITOLED?
begin
  Result := False;
  //TBD:AF9?
end;

function TAF9Fpga.PgDownBmpFiles(nFileCnt: Integer; const arTransData: TArray<TFileTranStr>): Boolean; //TBD:ITOLED?
begin
  Result := False;
  //TBD:AF9?
end;

//##############################################################################
//##############################################################################
//###                                                                        ###
//##############################################################################
//##############################################################################

//==============================================================================
// procedure/function:
//		-
//

function TAF9Fpga.SendDisplayPat(nIdx: Integer; nWait : Integer = 3000; nTryCnt: Integer = 1): DWORD;
var
  bOK : Boolean;
begin
//  bOK := SendPatDisplayReq(1, nIdx);
  if bOK then Result := WAIT_OBJECT_0
  else        Result := WAIT_FAILED;
end;

function TAF9Fpga.SendDisplayPwmPat(nIdx: Integer; nWait : Integer = 3000; nTryCnt: Integer = 1): DWORD;
var
  {$IF Defined(INSEPCTOR_FI) or Defined(INSEPCTOR_OQA)}
  nDim : Integer;
  {$ENDIF}
  bOK  : Boolean;
begin
  {$IF Defined(INSEPCTOR_FI) or Defined(INSEPCTOR_OQA)}
  nDim := FCurPatGrpInfo.Dimming[nIdx];
  if (Common.TestModelInfoFLOW.UsePwmPatDisp) and (nDim >= 0) and (nDim <= 100) then begin
    Result := SendDimming(nDim,nTryCnt);
  end;
  {$ENDIF}
  //
//  bOK := SendPatDisplayReq(1, nIdx);
  if bOK then Result := WAIT_OBJECT_0
  else        Result := WAIT_FAILED;
end;
//
//function TAF9Fpga.SendPatDisplayReq(nCmdType, nPatNum: Integer; nBmpCompensate : Byte = 0): Boolean;
//var
//  nApiRtn, i,nDataCnt : Integer;
//  sFunc, sDebug,sCsvFileName : String;
//  sPatName : AnsiString;
//  nPatIdx, nBmpDownNum : Integer;
//  nToolCnt : Integer;
//  nToolType,nDirection,nLevel,nSX,nSY,nEX,nEY,nMX,nMY,nR,nG,nB : Integer;
//begin
//  Result := True;
//
//  {$IFDEF INSPECTOR_POCB}
//  ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_PATTERN,nPatNum,'');
//  {$ENDIF}
//
//  try
//    if nCmdType = DefAF9.CMD_DISPLAY_OFF then begin
//      sFunc    := 'Display OFF: ';
//      nApiRtn := AF9_APSPatternRGBSet(0,0,0);  //TBD:AF9?
//      if nApiRtn <> AF9API_RESULT_OK then Result := False;
//    end
//    else begin
//      sPatName := FCurPatGrpInfo.PatName[nPatNum];
//      for nPatIdx := 0 to Pred(MAX_PATTERN_CNT) do begin
//        if Trim(FDisPatStruct.PatInfo[nPatIdx].pat.Data.PatName) = sPatName then Break;
//      end;
//      //
//      case FCurPatGrpInfo.PatType[nPatNum] of
//        PTYPE_NORMAL : begin
//          sFunc  := Format('Display Pattern(%d:%s]: ',[nPatNum,sPatName]);
//          nToolCnt := FDisPatStruct.PatInfo[nPatIdx].pat.Data.ToolCnt;
//        //sDebug := sFunc + Format(' PatNum(%d) PatName(%s) ToolCnt(%d)',[nPatNum,sPatName,nToolCnt]);
//        //ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
//          for i := 0 to (nToolCnt-1) do begin
//            with FDisPatStruct.PatInfo[nPatIdx].Tool[i].Data do begin
//              {$IFDEF INSPECTOR_POCB}
//            	nSX := Common.GetDrawPosPG(m_nCh,sx);
//            	nSY := Common.GetDrawPosPG(m_nCh,sy);
//            	nEX := Common.GetDrawPosPG(m_nCh,ex);
//            	nEY := Common.GetDrawPosPG(m_nCh,ey);
//            	nMX := Common.GetDrawPosPG(m_nCh,mx);
//            	nMY := Common.GetDrawPosPG(m_nCh,my);
//              {$ELSE}
//            	nSX := Common.GetDrawPosPG(sx);
//            	nSY := Common.GetDrawPosPG(sy);
//            	nEX := Common.GetDrawPosPG(ex);
//            	nEY := Common.GetDrawPosPG(ey);
//            	nMX := Common.GetDrawPosPG(mx);
//            	nMY := Common.GetDrawPosPG(my);
//              {$ENDIF}
//              // (0~4095) -> (0~255)
//             	if R <= 0 then nR := 0 else if R >= 4095 then nR := 255 else nR := (R shr 4);
//             	if G <= 0 then nG := 0 else if G >= 4095 then nG := 255 else nG := (G shr 4);
//             	if B <= 0 then nB := 0 else if B >= 4095 then nB := 255 else nB := (B shr 4);
//              // ToolType
//              // 		ALL_LINE        : 'LINE';
//							//    ALL_BOX         : 'BOX';
//							//    ALL_FILL_BOX    : 'FILL_BOX';
//							//    ALL_TRI         : 'TRI';
//							//    ALL_FILL_TRI    : 'FILL_TRI';
//							//    ALL_CIRCLE      : 'CIRCLE';
//							//    ALL_FILL_CIRCLE : 'FILL_CIRCLE';
//							//    ALL_H_GRAY      : 'HORIZONTAL_GRAY';
//							//    ALL_V_GRAY      : 'VERTICAL_GRAY';
//							//    ALL_C_GRAY      : 'COLOR_GRAY';
//							//    ALL_BLK_COPY    : 'BLOCK_COPY';
//							//    ALL_BLK_PASTE   : 'BLOCK_PASTE';
//							//    ALL_LOOP        : 'LOOP';
//							//    ALL_XYLOOP      : 'XYLOOP';
//							//    ALL_H_GRAY2     : 'HORIZONTAL_GRAY2';
//							//    ALL_V_GRAY2     : 'VERTICAL_GRAY2';
//							//    ALL_C_GRAY2     : 'COLOR_GRAY2';
//              case ToolType of
//                ALL_H_GRAY, ALL_V_GRAY, ALL_C_GRAY,	ALL_H_GRAY2, ALL_V_GRAY2, ALL_C_GRAY2 : begin
//               	  //TBD?
//                end;
//              end;
//            //sDebug := Format('ToolIdx[%d] ToolType(%d) Direction(%d) Level(%d) SX(%d)/SY(%d) EX(%d)/EY(%d) MX(%d)/MY(%d) R(%d)/G(%d)/B(%d)',[i,ToolType,Direction,Level,nSX,nSY,nEX,nEY,nMX,nMY,nR,nG,nB]);
//            //ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
//          	end;
//            //
//            if nToolCnt = 1 then begin
//              nApiRtn  := AF9_APSPatternRGBSet(nR,nG,nB);
//              if nApiRtn <> AF9API_RESULT_OK then Result := False;
//            end
//            else begin
//              nApiRtn  := AF9_APSBoxPatternSet(nSX,nSY, (nEX-nSX+1),(nEY-nSY+1), nR,nG,nB, 0,0,0); //TBD:AF9:BR/BG/BB? (BR/BG/BB option?)
//              if nApiRtn <> AF9API_RESULT_OK then Result := False;
//            end;
//          end;
//        end;
//				//
//        PTYPE_BITMAP : begin
//          nBmpDownNum := CurPatGrpInfo.BmpDownNum[nPatNum];
//          sFunc := Format('Display BMP(%d:%s] : AF9BmpDownNum(%d)',[nPatNum,sPatName,nBmpDownNum]);      // Added by KTS 2022-03-15 오전 9:04:11 패턴 BMP 인 경우
//          {$IFDEF INSPECTOR_POCB}
//          if Common.SysInfo.SYS.UseBmpDownBeforeDisplay then //ITOLED:FI:UseITOMode Added by KTS 2022-03-28 오전 9:53:04 view 전 download 진행
//          {$ELSE}
//          if Common.SystemInfo.UseITOMode then //ITOLED:FI:UseITOMode Added by KTS 2022-03-28 오전 9:53:04 view 전 download 진행
//          {$ENDIF}
//          begin
//            sDebug := sFunc + ' ...Download';
//            ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
//            Common.MakeRawFile_AF9(sPatName,nDataCnt);
//            AF9_BMPFileSend(@Common.RawBgrData[0],nDataCnt,nBmpDownNum);
//            Sleep(50);
//          end;
//
//          if nBmpDownNum > 0 then  begin
//            nApiRtn := AF9_BMPFileView(nBmpDownNum);
//            if nApiRtn <> AF9API_RESULT_OK then Result := False; // Added by KTS 2022-03-25 오전 10:32:48 0값으로 리턴 확인 필요
//          end
//          else begin
//            Result := False;  //TBD:AF9?
//            sDebug := sFunc + ' Download the BMP.!!' ;
//            ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sDebug);
//          end;
//        //  sPatName --> BmpDown? : TBD:AF9:BMP?
//        //AF9_TEST_EXE:  WriteBMPFile(pbyteBuffer2, cnt); + APSSetReg(9, 0);
//	      end;
//      end;
//      m_nOldPatNum := nPatNum;
//    end;
//    //
//		{$IFDEF FEATURE_GRAY_CHANGE}
//    FDisPatStruct.CurrPat.nCurrPatNum    := 0;
//    FDisPatStruct.CurrPat.nCurrAllPatIdx := 0; //index of AllPat
//    FDisPatStruct.CurrPat.bSimplePat   := False;
//    FDisPatStruct.CurrPat.bGrayChangeR := False;
//    FDisPatStruct.CurrPat.bGrayChangeG := False;
//    FDisPatStruct.CurrPat.bGrayChangeB := False;
//    FDisPatStruct.CurrPat.nGrayOffset  := 0;
//    if nCmdType = DefAF9.CMD_DISPLAY_OFF then begin
//      FDisPatStruct.CurrPat.bPatternOn   := False;
//    end
//    else begin
//      FDisPatStruct.CurrPat.bPatternOn     := True;
//      FDisPatStruct.CurrPat.nCurrPatNum    := nPatNum;
//      FDisPatStruct.CurrPat.nCurrAllPatIdx := nPatIdx;
//      if (FCurPatGrpInfo.PatType[nPatNum] = PTYPE_NORMAL) and
//            (FDisPatStruct.PatInfo[nPatIdx].pat.Data.ToolCnt = 1) and
//            (FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data.ToolType = ALL_FILL_BOX) then begin
//        FDisPatStruct.CurrPat.bSimplePat := True;
//        //
//        if (FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data.R <> 0) then FDisPatStruct.CurrPat.bGrayChangeR := True;
//        if (FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data.G <> 0) then FDisPatStruct.CurrPat.bGrayChangeG := True;
//        if (FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data.B <> 0) then FDisPatStruct.CurrPat.bGrayChangeB := True;
//        //
//        if (FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data.R = 0) and (FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data.G = 0)
//            and (FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data.B = 0) then begin  //black
//          FDisPatStruct.CurrPat.bGrayChangeR := True;
//          FDisPatStruct.CurrPat.bGrayChangeG := True;
//          FDisPatStruct.CurrPat.bGrayChangeB := True;
//        end;
//      end;
//    end;
//		{$ENDIF}
//  except
//
//  end;
//end;

function TAF9Fpga.CheckPowerLimit(PwrVal: RPwrValAF9): Boolean;
var
	bRet : Boolean;
begin
  bRet := False;
  //TBD:AF9?
  Result := bRet;
end;

function TAF9Fpga.SendDimming(nDimming: Integer; nTryCnt: Integer = 1): DWORD;
const
  DBV_REG_ADDR1 = 751;
  DBV_REG_ADDR2 = 752;
var
  nApiRtn : Integer;
  nDimmingStep       : Integer;
  nDBV, nWriteValue  : Integer;
  btValue1, btValue2, btRead : Byte;
  sFunc, sDebug : string;
  nTry : Integer;
begin
  Result := WAIT_OBJECT_0;
  sFunc  := Format('DIMMNG(PWM=%d): ',[nDimming]);

  //
  // [REF] AF9_TEST_EXE (v1.11) - DBV
  //    - Write DBV value and press DBV button
  //    - DBV range is 0 to 2047.
  //    < source >
  //    writeData = (inputData << 5) | 31;
	//    Tmp2.Format(_T("DBV Set : Data[%d]:[%x]\n"), inputData, writeData);
  //  	LGDSetReg(751, (writeData & 0xFF00) >> 8);
  //  	LGDSetReg(752, (writeData & 0xFF));
  //
  // nDimming(0~100) --> DBV(0~2047)
  if nDimming = 0        then nDBV := 0
  else if nDimming = 100 then nDBV := 2047
  else                        nDBV := (nDimming * 2048) div 100; //TBD:ITOLED?
  //
  nWriteValue := (nDBV shl 5) or $1F;
  btValue1 := (nWriteValue shr 8) and $FF; //high
  btValue2 := nWriteValue and $FF;         //low
  //
  sDebug := sFunc + Format('DBV(%d), Value(0x%0.4x), Reg(%d:0x%0.2x, %d:0x%0.2x)',[nDBV,nWriteValue,DBV_REG_ADDR1,btValue1,DBV_REG_ADDR2,btValue2]);
//  ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
  for nTry := 1 to nTryCnt do begin

    // DBV_REG_ADDR1 - Wrire
    nApiRtn := AF9_LGDSetReg(DBV_REG_ADDR1, btValue1);
    if nApiRtn <> AF9API_RESULT_OK then begin
      Result := WAIT_FAILED;
      sDebug := sFunc + Format('AF9_API: LGDSetReg(Addr=%d,Value=0x%0.2x) Failed',[DBV_REG_ADDR1,btValue1]);
//      ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
      Continue;
    end;
    sDebug := sFunc + Format('AF9_API: LGDSetReg(Addr=%d,Value=0x%0.2x)',[DBV_REG_ADDR1,btValue1]);
//    ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
    // DBV_REG_ADDR1 - Verify
    btRead := AF9_LGDGetReg(DBV_REG_ADDR1);
    if btRead <> btValue1 then begin
      Result := WAIT_FAILED;
      sDebug := sFunc + Format('AF9_API LGDGetReg(Addr=%d): Value(0x%0.2x) <> Write(0x%0.2x)',[DBV_REG_ADDR1,btRead,btValue1]);
//      ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
      Continue;
    end;
    sDebug := sFunc + Format('AF9_API: LGDGetReg(Addr=%d): Value(0x%0.2x) = Write(0x%0.2x)',[DBV_REG_ADDR1,btRead,btValue1]);
//    ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);

    // DBV_REG_ADDR2 - Write
    nApiRtn := AF9_LGDSetReg(DBV_REG_ADDR2, btValue2);
    if nApiRtn <> AF9API_RESULT_OK then begin
      Result := WAIT_FAILED;
      sDebug := sFunc + Format('AF9_API: LGDSetReg(Addr=%d,Value=0x%0.2x) Failed',[DBV_REG_ADDR2,btValue2]);
//      ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sDebug);
      Continue;
    end;
    sDebug := sFunc + Format('AF9_API: LGDSetReg(Addr=%d,Value=0x%0.2x)',[DBV_REG_ADDR2,btValue2]);
//    ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
    // DBV_REG_ADDR2 - Verify
    btRead := AF9_LGDGetReg(DBV_REG_ADDR2);
    if btRead <> btValue2 then begin
      Result := WAIT_FAILED;
      sDebug := sFunc + Format('AF9_API: LGDGetReg(Addr=%d): Value(0x%0.2x) <> Write(0x%0.2x)',[DBV_REG_ADDR2,btRead,btValue2]);
//      ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sDebug);
      Continue;
    end;
    sDebug := sFunc + Format('AF9_API: LGDGetReg(Addr=%d): Value(0x%0.2x) = Write(0x%0.2x)',[DBV_REG_ADDR2,btRead,btValue2]);
//    ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
  end;
  //
  if (Result <> WAIT_OBJECT_0) then begin
    sDebug := sFunc + '...NG';
//    ShowTestWindow(DefCommon.MSG_MODE_WORKING,1{NG},sDebug);
  end;
  //
  {$IFDEF FEATURE_DIMMING_STEP}
  if (Result = WAIT_OBJECT_0) then begin
    nDimmingStep := 0;
    if      nDimming = Common.TestModelInfoFLOW.DimmingStep1 then nDimmingStep := 1
    else if nDimming = Common.TestModelInfoFLOW.DimmingStep2 then nDimmingStep := 2
    else if nDimming = Common.TestModelInfoFLOW.DimmingStep3 then nDimmingStep := 3
    else if nDimming = Common.TestModelInfoFLOW.DimmingStep4 then nDimmingStep := 4;
    FDisPatStruct.CurrPat.nCurrDimmingStep := nDimmingStep;
  end;
  {$ENDIF}
end;
//
//function TAF9Fpga.SendGrayChange(nGrayOffset: Integer): DWORD;  //FEATURE_GRAY_CHANGE
//var
//  nApiRtn, nTry : Integer;
//  sFunc, sDebug : string;
//  //
//  nPatIdx : Integer;
//  nR, nG, nB : Integer;
//begin
//  Result := WAIT_OBJECT_0;
//  sFunc  := Format('GrayChange(Offset=%d): ',[nGrayOffset]);
//  //
//  nPatIdx := DisPatStruct.CurrPat.nCurrAllPatIdx;
//  with FDisPatStruct.PatInfo[nPatIdx].Tool[0].Data do begin
//    // (0~4095) -> (0~255)
//   	if R <= 0 then nR := 0 else if R >= 4095 then nR := 255 else nR := (R shr 4);
//   	if G <= 0 then nG := 0 else if G >= 4095 then nG := 255 else nG := (G shr 4);
//   	if B <= 0 then nB := 0 else if B >= 4095 then nB := 255 else nB := (B shr 4);
//    // +/- GrayOffset
//    nR := nR + nGrayOffset;
//    nG := nG + nGrayOffset;
//    nB := nB + nGrayOffset;
//    //
//   	if nR <= 0 then nR := 0 else if nR >= 255 then nR := 255;
//   	if nG <= 0 then nG := 0 else if nG >= 255 then nG := 255;
//   	if nB <= 0 then nB := 0 else if nB >= 255 then nB := 255;
//    //
//    nApiRtn := AF9_APSPatternRGBSet(nR,nG,nB);
//    if nApiRtn <> AF9API_RESULT_OK then begin
//      Result := WAIT_FAILED;
//      sDebug := sFunc + ' Failed';
//      ShowTestWindow(DefCommon.MSG_MODE_WORKING,1,sDebug);
//    end
//    else begin
//      FDisPatStruct.CurrPat.nGrayOffset := nGrayOffset;
//      sDebug := sFunc;
//      ShowTestWindow(DefCommon.MSG_MODE_WORKING,0,sDebug);
//    end
//  end;
//end;

function TAF9Fpga.SendPowerOn(nMode: Integer; nWait: Integer = 10000; nTryCnt: Integer = 1) : DWORD; //2021-09-14 (nWait:3000->10000)
var
  nRtn : DWORD;
begin
  Result := WAIT_OBJECT_0;
  //
  if nMode = 1 then begin  // On
     AF9_AllPowerOnOff(1); //ON
    //
    {$IFDEF FEATURE_GRAY_CHANGE}
    with FDisPatStruct.CurrPat do begin
      bPowerOn     := True;
    //bPatternOn   := False;
    //nCurrPatNum  := 0;
    //nCurrAllPatIdx := 0;
    //bSimplePat   := False;
    //bGrayChangeR := False;
    //bGrayChangeG := False;
    //bGrayChangeB := False;
    //nGrayOffset  := 0;
    end;
    {$ENDIF}
  end
  else begin
     AF9_AllPowerOnOff(0);  //OFF
    //
    {$IFDEF FEATURE_GRAY_CHANGE}
    with FDisPatStruct.CurrPat do begin
      bPowerOn     := False;
      bPatternOn   := False;
      nCurrPatNum  := 0;
      nCurrAllPatIdx := 0;
      bSimplePat   := False;
      bGrayChangeR := False;
      bGrayChangeG := False;
      bGrayChangeB := False;
      nGrayOffset  := 0;
    end;
    {$ENDIF}
  end;
end;

function TAF9Fpga.SendPowerMeasure: DWORD;
begin
  if m_bPwrMeasure then tmPwrMeasure.Enabled := False;
  Result := WAIT_FAILED;
  //TBD:AF9?
  if m_bPwrMeasure then tmPwrMeasure.Enabled := True;
end;

procedure TAF9Fpga.SetPowerMeasureTimer(bEnable: Boolean; nInterval : Integer = 1000); //TBD:AF9?
begin
  if nInterval <> 0 then begin
    tmPwrMeasure.Interval := nInterval;
  end;
  tmPwrMeasure.Enabled := bEnable;
  m_bPwrMeasure        := bEnable;
end;


procedure TAF9Fpga.ShowMainWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);
var
  ccd     : TCopyDataStruct;
  GuiData : RGuiAF92Main;
begin
  GuiData.MsgType := DefCommon.MSG_TYPE_AF9FPGA;
  GuiData.Mode    := nGuiMode;
  GuiData.PgNo    := m_nCh;
  GuiData.sMsg    := sMsg;
  GuiData.Param   := nParam;
  //
  ccd.dwData := 0;
  ccd.cbData := SizeOf(GuiData);
  ccd.lpData := @GuiData;
  SendMessage(Self.m_hMain,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TAF9Fpga.ShowTestWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);
var
  ccd     : TCopyDataStruct;
  GuiData : RGuiAF92Test;
begin
  GuiData.MsgType  := DefCommon.MSG_TYPE_AF9FPGA;
  GuiData.Mode     := nGuiMode;
  GuiData.PgNo     := m_nCh;
  GuiData.sMsg     := sMsg;
  GuiData.Param    := nParam;
  GuiData.PwrValPg := m_PwrValPg; //TBD:AF9
  //
  ccd.dwData := 0;
  ccd.cbData := SizeOf(GuiData);
  ccd.lpData := @GuiData;
  SendMessage(Self.m_hTest,WM_COPYDATA,0, LongInt(@ccd));
end;

function TAF9Fpga.SendI2CRead(nDevAddr,nRegAddr,nDataCnt: Integer; nWaitSec: Integer=2000; nTryCnt: Integer=1): DWORD;
var
  sDebug  : string;
  i       : Integer;
  btData  : Byte;
  btaData : array of Byte;
begin
  Result := WAIT_FAILED;

  if nDevAddr = DefAF9.LGD_REG_DEVICE then begin
    if nDataCnt = 1 then begin
      btData := AF9_LGDGetReg(nRegAddr);
      //
      FRxDataPg.DataLen := 1;
      FRxDataPg.Data[0] := btData;
      Result := WAIT_OBJECT_0;
    end
    else begin
      SetLength(btaData, nDataCnt);
      AF9_LGDRangeGetReg(@btaData,nRegAddr{StartAddress},nRegAddr+nDataCnt-1{EndAddress});
      //
      FRxDataPg.DataLen := 1;
      for i := 0 to (nDataCnt-1) do begin
        FRxDataPg.DataLen := 1;
        FRxDataPg.Data[i] := btaData[i];
      end;
      Result := WAIT_OBJECT_0;
    end;
  end
  else begin
    Exit; //2022-02-25 (AF9_API: Not support APS Reg Read)
  end;
end;

{$IFDEF INSPECTOR_POCB}
function TAF9Fpga.SendI2CWrite(nDevAddr,nRegAddr,nDataCnt: Integer; arrData: TIdBytes; nWaitSec: Integer=2000; nTryCnt: Integer=1): DWORD;
{$ELSE}
function TAF9Fpga.SendI2CWrite(nDevAddr,nRegAddr,nDataCnt: Integer; arrData: array of Integer; nWaitSec: Integer=2000; nTryCnt: Integer=1): DWORD;
{$ENDIF}
var
  nApiRtn, i : Integer;
begin
  Result := WAIT_FAILED;
  //
  if nDevAddr = DefAF9.LGD_REG_DEVICE then begin
    for i := 0 to (nDataCnt-1) do begin
      nApiRtn := AF9_LGDSetReg(nRegAddr+i,(arrData[i] and $FF));
      if nApiRtn <> DefAF9.AF9API_RESULT_OK then Exit
    end;
    Result := WAIT_OBJECT_0;
  end
  else begin
    nApiRtn := AF9_APSSetReg(nRegAddr,(arrData[0] and $FF));
    if nApiRtn <> DefAF9.AF9API_RESULT_OK then Exit;
    Result := WAIT_OBJECT_0;
  end;
end;

function TAF9Fpga.SendSetColorRGB(nR,nG,nB: Integer): Integer;
var
  nApiRtn, i : Integer;
begin
  Result := WAIT_FAILED;
  //
  nApiRtn := AF9_APSPatternRGBSet(nR,nG,nB);
  if nApiRtn <> DefAF9.AF9API_RESULT_OK then Exit;
  Result := WAIT_OBJECT_0;
end;

function TAF9Fpga.SendDisplayOnOff(bOn: Boolean): DWORD; //A2CHv3:ASSY-POCB:FLOW
var
  dwRtn : integer;
begin
    Result := WAIT_OBJECT_0;
  //
  {$IFDEF INSPECTOR_POCB}
  if bOn then ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_PATTERN,-3{On},'')
  else        ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_PATTERN,-2{Off},''); // -1:PowerOff, -2:DisplayOff, -3:DisplayOn //TBD:MERGE?
  {$ENDIF}
  //TBD:AF9?
end;


//function TAF9Fpga.SendFlashRead(nAddr,nSize: DWORD; pDataBuf: PByte; nWaitMS: Integer=5000; nRetry: Integer=0): DWORD; //TBD:ITOLED?
//var
//  btApiRtn : Byte;
//  nTry : Integer;
//  sFunc, sDebug : string;
//begin
//  Result := WAIT_FAILED;
//  sFunc  := Format('FlashRead(Addr=%d,Size=%d) ',[nAddr,nSize]);
//  for nTry := 0 to nRetry do begin
//    btApiRtn := AF9_FLASHRead(pDataBuf, nAddr,(nAddr+nSize-1){nEndAddr});
//    if btApiRtn = DefAF9.AF9API_RESULT_OK then begin
//      Result := WAIT_OBJECT_0;
//      //TBD:IMSI?
//      sDebug := Common.Path.FLASH + Format('FlashRead_CH%d_%d_%d.hex',[m_nCh+1,nAddr,(nAddr+nSize-1)]);
//      Common.SaveHexLog(sDebug,nSize,pDataBuf);
//      break;
//    end;
//  end;
//  if (Result <> WAIT_OBJECT_0) then begin
//    sDebug := sFunc + '...NG';
//    ShowTestWindow(DefCommon.MSG_MODE_WORKING,1{NG},sDebug);
//  end;
//end;

function TAF9Fpga.SendFlashWrite(nAddr,nSize: DWORD; const pData: PByte; nWaitMS: Integer = 100000; nRetry: Integer = 0): DWORD; //TBD:ITOLED?
var
  btApiRtn : Byte;
  i, nTry  : integer;
  CalcCRC, RxCRC : Word; //Word?
  tempPtr : PByte;
  sFunc, sDebug : string;
begin
  Result := WAIT_FAILED;

  // Calc SumCRC
  CalcCRC := 0;
  tempPtr := pData;
  for i := 0 to Pred(nSize) do begin
    CalcCRC := Word((CalcCRC + tempPtr^) and $FFFF);
    Inc(tempPtr);
  end;
  sFunc := Format('SendFlashWrite(Size=%d,Retry=%d)(CRC=0x%x)',[nSize,nRetry,CalcCRC]);

  // Send CRC + HEX
  for nTry := 0 to nRetry do begin
    // Send CRC
    btApiRtn := AF9_SendHexFileCRC(CalcCRC);
    if btApiRtn = DefAF9.AF9API_RESULT_OK then begin
      Sleep(20); //!!!
      // Send HEX
   	//RxCRC := AF9_SendHexFile(pData, nSize);  //TBD:AF9API?
      btApiRtn := AF9_SendHexFile(pData, nSize);  //TBD:AF9API?
      if btApiRtn = DefAF9.AF9API_RESULT_OK then begin
        Result := WAIT_OBJECT_0;
        break;
      end;
    end;
  end;

  if (Result <> WAIT_OBJECT_0) then begin
    sDebug := sFunc + '...NG';
//    ShowTestWindow(DefCommon.MSG_MODE_WORKING,1{NG},sDebug);
  end;
end;

procedure TAF9Fpga.SendBmpData(nTransDataCnt : Integer;const transData: TArray<TFileTranStr>); //#TDongaPG.SendPgTransDat //Setup:BmpDown
begin
  //TBD:AF9?
end;

function TAF9Fpga.SendModelInfo(handle: HWND): DWORD;
begin
  Result := WAIT_FAILED;
  //TBD:AF9?
end;

//##############################################################################
//###
//###
//###
//##############################################################################

//==============================================================================
// procedure/function:
//		- procedure TAF9Fpga.ShowMainWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);
//		- procedure TAF9Fpga.ShowTestWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);
//
//procedure TAF9Fpga.ShowMainWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);
//var
//  ccd     : TCopyDataStruct;
//  GuiData : RGuiAF92Main;
//begin
//  GuiData.MsgType := DefCommon.MSG_TYPE_AF9FPGA;
//  GuiData.Mode    := nGuiMode;
//  GuiData.PgNo    := m_nCh;
//  GuiData.sMsg    := sMsg;
//  GuiData.Param   := nParam;
//  //
//  ccd.dwData := 0;
//  ccd.cbData := SizeOf(GuiData);
//  ccd.lpData := @GuiData;
//  SendMessage(Self.m_hMain,WM_COPYDATA,0, LongInt(@ccd));
//end;

//procedure TAF9Fpga.ShowTestWindow(nGuiMode: Integer; nParam: Integer; sMsg: string);
//var
//  ccd     : TCopyDataStruct;
//  GuiData : RGuiAF92Test;
//begin
//  GuiData.MsgType  := DefCommon.MSG_TYPE_AF9FPGA;
//  GuiData.Mode     := nGuiMode;
//  GuiData.PgNo     := m_nCh;
//  GuiData.sMsg     := sMsg;
//  GuiData.Param    := nParam;
//  GuiData.PwrValPg := m_PwrValPg; //TBD:AF9
//  //
//  ccd.dwData := 0;
//  ccd.cbData := SizeOf(GuiData);
//  ccd.lpData := @GuiData;
//  SendMessage(Self.m_hTest,WM_COPYDATA,0, LongInt(@ccd));
//end;

end.
