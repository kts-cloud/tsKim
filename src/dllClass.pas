unit dllClass;

interface
{$I Common.inc}

uses Winapi.Windows, System.Classes, System.SysUtils,  IdGlobal,Vcl.ExtCtrls,Forms,
   Messages, Vcl.Dialogs,CA_SDK2,DefCommon,DefPG,CommPG,LogicVh,CommonClass,RegularExpressions,
   System.Variants,Vcl.Controls, Vcl.StdCtrls,Math
{$IFDEF OC_TT_TEST}
    ,System.Generics.Collections
{$ENDIF}
   ;

const
DEVICE_ADDRESS = $A0;
   type
  TSample = record
    Name: WideString;
  end;
  PSample = ^TSample;

  PGuiDLL = ^RGuiDLL;
  RGuiDLL = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param  : Integer;
    Param2 : Integer;
    Msg     : string;
    pData   : PBYTE; //Pointer; //Length = Param2
  end;


type
  //CA410
  TCallBackMeasure_XYL = function (nChannel : Integer; t5 : TArray<double>; nLen : Integer): Integer ;
  TCallBackSetSync     = function (CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
  TCallBackGetWaveformData = function (nChannel : Integer; waveform_T,waveformData : TArray<double>; nMeasureAmount : Integer ): Double;

  TCallBackTextChanged = procedure (channel_Index : Integer; bClear : Boolean;  sAddedText : PAnsiChar);
  TCallBackSample = procedure(a : Integer);

  TCallBackAllPowerOnOff     = function(nChannel,OnOff: Integer): Integer;

  TCallBackTCONSetReg       = function(nChannel,Addr : Integer; data : Byte): Integer;
  TCallBackTCONGetReg       = function(nChannel,Addr : Integer; data : Byte): Integer;
  TCallBackTCONSetRegArray  = function(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
  TCallBackTCONGetRegArray  = function(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
  TCallBackFlashWrite_File  = function(nChannel,nStartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
  TCallBackFlashWrite_Data  = function(nChannel,nStartSeg,nLength : Integer; data: PByte): Integer;
  TCallBackFlashRead_File   = function(nChannel,nStartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
  TCallBackFlashRead_Data   = function(nChannel,nStartSeg,nLength : Integer; data: PByte): Integer;
  TCallBackFlashErase       = function(nChannel,nStartSeg,nLength : Integer): Integer;
  TCallBackTCONMultiSetReg  = function(nChannel,nType : Integer; Addr : PINT; data : PByte; nLength : Integer): Integer;
  TCallBackTCONSeqSetReg    = function(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; data : PByte; nLength : Integer): Integer;

  TCallBackFlowDone = procedure (channel_Index : Integer);

  TStartFunction = function(nDLLType, nCH: Integer; sParameter: PAnsiChar; nLength, nCheckSum: Integer): Integer; cdecl;
  TStopFunction = procedure(nDLLType, nCH: Integer); cdecl;

  TMyCB_TextChanged         = procedure(channel_Index : Integer; bClear : Boolean;  sAddedText : PAnsiChar);cdecl;
  TMyCB_AllPowerOnOff       = function(nChannel,OnOff: Integer): Integer;
  TMyCB_TCONSetReg          = function(nChannel,Addr : Integer; data : Byte): Integer;
  TMyCB_TCONGetReg          = function(nChannel,Addr : Integer; var data : Byte): Integer;
  TMyCB_TCONSetRegArray      = function(nChannel,Addr : Integer; const data : PByte; nLength : Integer): Integer;
  TMyCB_TCONSetRegMultiWrite = function(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  TMyCB_TCONSetRegSeqWrite    = function(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  TMyCB_TCONGetRegArray       = function(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
  TMyCB_FlashWrite_File       = function(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
  TMyCB_FlashWrite_Data      = function(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
  TMyCB_FlashRead_File       = function(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
  TMyCB_FlashRead_Data       = function(nChannel,nStartSeg,nLength : Integer;  data: PByte): Integer;
  TMyCB_FlashErase            = function(nChannel,nStartSeg,nLength : Integer): Integer;
  TMyCB_measure_XYL          = function(nChannel:Integer; var dMeasureData : TArray<double>; var nLen : Integer): Integer;
  TMyCB_GetWaveformData      = function(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
  TMyCB_SetSync              = function(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
  TMyCB_FlowDone              = procedure(nChannel : Integer);

  type
  PProdutInfo = ^productInfo2;
  productInfo = packed record
    mes : Integer;
    PID   : PByte;
    CBID  : PByte;
    IsOk  : Integer;
    Value : Double;
  end;
  productInfo2 = packed record
    mes : Integer;
    PID   : PAnsiChar;
    CBID  : PAnsiChar;
    IsOk  : Integer;
    Value : Double;
  end;
  TMenuDataStruct = packed record
    exename : string[150];
    caption : string[25];
    userid : string[20];
    password : string[20];
    sparam : string[255];
    workdir : string[100];
    IconSize : Integer;
    IconPos : Integer;
    NextDataPos : Integer;
  end;

  TG2VControl = packed record
    RGB : string;
    Addr : array [0..1]of string[8];
    Data1 : array [0..1]of string[8];
    Data2 : array [0..1]of string[8];
    Data3 : array [0..1]of string[8];
    Data4 : array [0..1]of string[8];

  end;

  TCSharpDll = class(TObject)

    m_MainHandle : HWND;
    m_TestHandle : HWND;
    tmrCycle : TTimer;
    // for DLL.
    m_Initialize : function (channelCount : Integer; sModelName : PAnsiChar) : Integer ; cdecl;
    m_FormDestroy : procedure ; cdecl;

    tmCheckOCAlive   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TTimer;
    m_Init : procedure(sDLLDirectory : PAnsiChar); cdecl;
    m_Init2 : procedure ; cdecl;
    m_UnInit : procedure; cdecl;

    StartFunctions             : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TStartFunction;
    StopFunctions              : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TStopFunction;
    MyCB_TextChanged           : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_TextChanged;
    MyCB_AllPowerOnOff         : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_AllPowerOnOff;
    MyCB_TCONSetReg            : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_TCONSetReg;
    MyCB_TCONGetReg            : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_TCONGetReg;
    MyCB_TCONSetRegArray       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_TCONSetRegArray;
    MyCB_TCONSetRegMultiWrite  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_TCONSetRegMultiWrite;
    MyCB_TCONSetRegSeqWrite    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_TCONSetRegSeqWrite;
    MyCB_TCONGetRegArray       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_TCONGetRegArray;
    MyCB_FlashWrite_File       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_FlashWrite_File;
    MyCB_FlashWrite_Data       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_FlashWrite_Data;
    MyCB_FlashRead_File        : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_FlashRead_File;
    MyCB_FlashRead_Data        : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_FlashRead_Data;
    MyCB_FlashErase            : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_FlashErase;
    MyCB_measure_XYL           : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_measure_XYL;
    MyCB_GetWaveformData       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_GetWaveformData;
    MyCB_SetSync               : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_SetSync;
    MyCB_FlowDone              : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TMyCB_FlowDone;

    m_MainOC_VerifyStart : function(nCH : Integer): Integer; cdecl;
    m_MainOC_ThreadStateCheck : function(nCH : Integer): Integer; cdecl;

    m_SetCallback_measure_XYL       : procedure (nChannel : Integer; CaallbackFunction : TCallBackMeasure_XYL); cdecl;
    m_SetCallback_SetSync           : procedure (nChannel : Integer; CaallbackFunction : TCallBackSetSync);cdecl;
    m_SetCallback_GetWaveformData   : procedure (nChannel : Integer; CaallbackFunction : TCallBackGetWaveformData);cdecl;
    m_SetCallback_TextChanged       : procedure (nChannel : integer; CaallbackFunction : TCallBackTextChanged);cdecl;
    m_SetCallback_FlowDone          : procedure (nChannel : integer; CaallbackFunction : TCallBackFlowDone);cdecl;
    m_SetCallBackAllPowerOnOff      : procedure (nChannel : Integer; CaallbackFunction : TCallBackAllPowerOnOff      );cdecl;
    m_SetCallBackTCONSetReg         : procedure (nChannel : Integer; CaallbackFunction : TCallBackTCONSetReg         );cdecl;
    m_SetCallBackTCONGetReg         : procedure (nChannel : Integer; CaallbackFunction : TCallBackTCONGetReg         );cdecl;
    m_SetCallBackTCONSetRegArray    : procedure (nChannel : Integer; CaallbackFunction : TCallBackTCONSetRegArray    );cdecl;
    m_SetCallBackTCONGetRegArray    : procedure (nChannel : Integer; CaallbackFunction : TCallBackTCONGetRegArray    );cdecl;
    m_SetCallBackFlashWrite_File    : procedure (nChannel : Integer; CaallbackFunction : TCallBackFlashWrite_File    );cdecl;
    m_SetCallBackFlashWrite_Data    : procedure (nChannel : Integer; CaallbackFunction : TCallBackFlashWrite_Data    );cdecl;
    m_SetCallBackFlashRead_File     : procedure (nChannel : Integer; CaallbackFunction : TCallBackFlashRead_File     );cdecl;
    m_SetCallBackFlashRead_Data     : procedure (nChannel : Integer; CaallbackFunction : TCallBackFlashRead_Data     );cdecl;
    m_SetCallBackFlashErase         : procedure (nChannel : Integer; CaallbackFunction : TCallBackFlashErase         );cdecl;
    m_SetCallBackTCONMultiSetReg    : procedure (nChannel : Integer; CaallbackFunction : TCallBackTCONMultiSetReg    );cdecl;
    m_SetCallBackTCONSeqSetReg      : procedure (nChannel : Integer; CaallbackFunction : TCallBackTCONSeqSetReg    );cdecl;


  private
    m_hDll  : HWND;
    m_hMain : HWND;
    FNgMsg: string;
    m_nDLLType : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Integer;
    m_CountInspections : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Integer;
    FDataArray: array of TArray<Integer>;
    m_GetSummaryLogData : function (nDLLType, nCH : Integer; sParameter : PAnsiChar): PAnsiChar; cdecl;
    m_GetSummaryLogData_New : function (nDLLType, nCH: Integer; var nReturn : Integer; sParameter : PAnsiChar): PAnsiChar; cdecl;

    m_GetOCConverterVersion : function : PAnsiChar; cdecl;
    m_GetDBVdata : function(nBand : Integer): Integer; cdecl;

    m_MainOC_Flash_Read : procedure (nCH : Integer); cdecl;

    m_MainOC_IsAlive : function (nDLLType, nCH : Integer) : Integer; cdecl;

    m_MainOC_ChangeDLL : function(sDLLName : PAnsiChar): Integer;  cdecl;

    m_nFlagCount : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Integer;

    m_sSerialNo : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of string;

    m_CurrentTap : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of integer;


    CB_PowerOnOff           : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackAllPowerOnOff;
    CB_TCONSetReg           : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackTCONSetReg;
    CB_TCONGetReg           : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackTCONGetReg;
    CB_TCONSetRegArray      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackTCONSetRegArray;
    CB_TCONGetRegArray      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackTCONGetRegArray;
    CB_FlashWrite_File      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackFlashWrite_File;
    CB_FlashWrite_Data      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackFlashWrite_Data;
    CB_FlashRead_File       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackFlashRead_File;
    CB_FlashRead_Data       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackFlashRead_Data;
    CB_FlashErase           : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackFlashErase;
    CB_TCONMultiSetReg      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackTCONMultiSetReg;
    CB_TCONSeqSetReg        : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackTCONSeqSetReg;
    CB_Measure_XYL          : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackMeasure_XYL;
    CB_SetSync              : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackSetSync;
    CB_GetWaveformData      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackGetWaveformData;
    CB_TextChanged          : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackTextChanged;

    CB_FlowDone          : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH]   of  TCallBackFlowDone;

    m_sGrayRGB :  array[DefCommon.CH1 .. DefCommon.MAX_CH,0..3] of string;

    m_sDBV :  array[DefCommon.CH1 .. DefCommon.MAX_CH,0..1] of string;

    m_rTG2VControl : array[DefCommon.CH1 .. DefCommon.MAX_CH] of TG2VControl;
    procedure CloseMessageBoxWithButton(ButtonCaption: string);
    procedure tmrCycleTimer(Sender : TObject);
    procedure CreateCallBackFunction;
    procedure Setfunction;
    procedure SetNgMsg(const Value: string);
    procedure ThreadTask(Task: TProc);
    procedure SetOnRevSwData(nCH : Integer; const Value: TCallBackTextChanged);
    procedure SendTestGuiDisplay(nCh,nGuiMode: Integer; sMsg: string = ''; nParam: Integer = 0);
    procedure SendMainGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer; nParam2: Integer = 0);
    procedure OntmGetOCFlowIsAlive(Sender: TObject);

    procedure TconWriteAnalysis(nChannel,nAddr,nData : Integer);
    procedure GraySearch(nChannel,nAddr,nData : Integer);
    procedure SendHWCID(nCH : integer);

  public

    m_bIsDLLWork :array of Boolean; // Added by KTS 2022-12-27 오전 9:00:40 현재 DLL 작업중 확ㅇ인
    m_bIsProcessDone : array of Boolean;
    m_bIsProcessUnloadDone : array of Boolean;
    m_GetOCversion : function(nDLLType : Integer) : PAnsiChar; cdecl;
    m_OCFlowStart : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Boolean;
    m_OCCkSerialNB : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Boolean;
    m_CurrentBand : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of integer;
    constructor Create(hMain,hTest: HWND;sDLLPath, sFileName: string);
    procedure  Create_CallBackFunction;
    destructor Destroy; override;
    procedure MLOG(nChannel_Index : Integer;bClear : Boolean; sMLOG : string);

    procedure Initialize(sModelName : string);
    procedure FormDestroy;

    function MainOC_Start(nDLLType,nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
    function MainOC_Stop(nCH : Integer): integer;
    function MainOC_Verify_Start(nCH : Integer): integer;
    function MainOC_ThreadStateCheck(nCH : Integer): integer;
    function MainOC_Flash_Read(nCH : Integer): integer;
    function MainOC_GetOCFlowIsAlive(nCH : Integer): Integer;

    function MainOC_GetSummaryLogData(nCH : Integer; sParameter : string): string;

    function MainOC_ChangeDLL(sDLLName : string): Integer;

    property NgMsg : string read FNgMsg write SetNgMsg;

  end;

  procedure MyCB_TextChanged_Proc(channel_Index : Integer; bClear : Boolean;  sAddedText : PAnsiChar);cdecl;
  procedure MyCB_FlowDone_Proc(channel_Index : Integer);
  function MyCB_AllPowerOnOff_Proc(nChannel,OnOff: Integer): Integer;
  function MyCB_TCONSetReg_Proc(nChannel,Addr : Integer; data : Byte): Integer;
  function MyCB_TCONGetReg_Proc(nChannel,Addr : Integer; var data : Byte): Integer;
  function MyCB_TCONSetRegArray_Proc(nChannel,Addr : Integer; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegMultiWrite_Proc(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegSeqWrite_Proc(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONGetRegArray_Proc(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
  function MyCB_FlashWrite_File_Proc(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashWrite_Data_Proc(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
  function MyCB_FlashRead_File_Proc(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashRead_Data_Proc(nChannel,nStartSeg,nLength : Integer;  data: PByte): Integer;
  function MyCB_FlashErase_Proc(nChannel,nStartSeg,nLength : Integer): Integer;
  function MyCB_measure_XYL_Proc(nChannel:Integer; var dMeasureData : TArray<double>; var nLen : Integer): Integer;
  function MyCB_GetWaveformData_Proc(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
  function MyCB_SetSync_Proc(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;

  var
  CSharpDll : TCSharpDll;

implementation





{ TCharpDll }

constructor TCSharpDll.Create(hMain,hTest: HWND;sDLLPath, sFileName: string);
var
  sDllFile : string;
  i : Integer;

begin
  sDllFile := sDLLPath+sFileName;
  SendTestGuiDisplay(MAX_SYSTEM_LOG,DefCommon.MSG_MODE_WORKING,Format('TCSharpDll.Create sDllFile : %s',[sDllFile]));

  m_MainHandle := hMain;
  m_TestHandle := hTest;
  SetLength(m_bIsProcessDone,DefCommon.MAX_PG_CNT);
  SetLength(m_bIsProcessUnloadDone,DefCommon.MAX_PG_CNT);
  SetLength(m_bIsDLLWork,DefCommon.MAX_PG_CNT);

  for I := 0 to DefCommon.MAX_CH do begin

    m_bIsProcessDone[i] := False;
    m_bIsDLLWork[i] := False;

    m_OCFlowStart[i] := False;

    m_OCCkSerialNB[i] := False;
    m_sSerialNo[i] := '';

    tmCheckOCAlive[i] := TTimer.Create(nil);
    tmCheckOCAlive[i].Interval := 1000;
    tmCheckOCAlive[i].Enabled := False;
    tmCheckOCAlive[I].Tag := I;

    tmCheckOCAlive[i].OnTimer := OntmGetOCFlowIsAlive;

  end;

  FNgMsg := '';
  m_hDll := 0;
  if FileExists(sDllFile) then m_hDll := LoadLibrary(PChar(sDllFile))
  else                         FNgMsg := '[' + sDLLPath + ']' + #13#10 + ' Cannot find the file.!';
  if m_hDll = 0 then begin
    FNgMsg := ' loadlibrary returns 0';
    Exit;
  end;
  Setfunction;

  m_Init(Common.StringToPAnsiChar(sDLLPath));
  SendMainGuiDisplay(0,MSG_TYPE_DLL,sFileName,3);

end;

procedure TCSharpDll.OntmGetOCFlowIsAlive(Sender: TObject);
var
 nPGCH : integer;
begin
  nPGCH := (Sender as TTimer).Tag;
  if (m_OCFlowStart[nPGCH]) and Pg[nPGCH].bIsReProgramming  then begin
    Pg[nPGCH].bIsReProgramming := False;
    common.MLog(nPGCH,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
//    PG[nPGCH].DP860_FTPDiscon;
    MainOC_Stop(nPGCH);
  end;
  if (m_OCFlowStart[nPGCH]) and Pg[nPGCH].m_bChkShutdown_Fault  then begin
    common.MLog(nPGCH,'<SEQUENCE> Shutdown_Fault - NG');
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',1);
//    PG[nPGCH].DP860_FTPDiscon;
    MainOC_Stop(nPGCH);
  end;

  if (m_OCFlowStart[nPGCH]) and  m_OCCkSerialNB[nPGCH] then begin
    m_OCCkSerialNB[nPGCH] := False;
    common.MLog(nPGCH,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sSerialNo[nPGCH])]));
//    PG[nPGCH].DP860_FTPDiscon;
    MainOC_Stop(nPGCH);
  end;
  if @m_SetCallback_FlowDone = nil then begin
    if (m_OCFlowStart[nPGCH]) and (MainOC_GetOCFlowIsAlive(nPGCH) = 0) then begin
      m_OCFlowStart[nPGCH] := False;
      tmCheckOCAlive[nPGCH].Enabled := false;
      try
        m_nFlagCount[nPGCH] := 0;
  //      PG[nPGCH].DP860_FTPDiscon;
        common.MLog(nPGCH,Format('<SEQUENCE> CountInspections : %d',[m_CountInspections[nPGCH]]));
      finally
        SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_WORK_DONE,'OKFLOW_END',0);
      end;

    end;
  end;

end;


procedure TCSharpDll.Create_CallBackFunction;
begin
  CreateCallBackFunction;
end;

function MyCB_AllPowerOnOff_Proc(nChannel,OnOff: Integer): Integer;
var
nWaitMS,nRetry,wdRet : Integer;
PwrData : PPwrData;
begin
  if CSharpDll <> nil then begin
    CSharpDll.m_nFlagCount[nChannel] := 0;
    nWaitMS := 3000;
    nRetry  := 0;  // No Retry
    {$IFDEF PG_AF9}
    PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
    Result := WAIT_OBJECT_0;
    {$ENDIF}
    {$IFDEF PG_DP860}
    Result := Pg[nChannel].SendPowerBistOn(OnOff,True,nWaitMS,nRetry); //TBD:DP860?
    if OnOff = 1 then begin  // Power On 이후 Power 확인
      wdRet   := Pg[nChannel].SendPowerMeasure(True{bWait});
    end;
    {$ENDIF}
  end;
end;



function BinaryToDecimal(binaryStr: string): Integer;
var
  i, digit, power: Integer;
begin
  Result := 0;

  // 문자열을 거꾸로 탐색하여 처리
  for i := Length(binaryStr) downto 1 do
  begin
    if binaryStr[i] = '1' then
    begin
      digit := 1;
      power := Length(binaryStr) - i;
      Result := Result + (digit * Trunc(Math.Power(2, power)));
    end
    else if binaryStr[i] <> '0' then
    begin
      // 0 또는 1 이외의 문자가 포함된 경우 에러 처리
      Writeln('Error: Invalid binary digit detected.');
      Result := -1; // 에러 상황을 나타내기 위해 -1을 반환
      Exit;
    end;
  end;
end;

function DecimalToBinary(decimalValue: Integer; precision: Integer): string;
begin
  Result := '';

  if decimalValue = 0 then
  begin
    Result := '0';
    Exit;
  end;

  while (decimalValue > 0) or (Length(Result) < precision) do
  begin
    Result := IntToStr(decimalValue mod 2) + Result;
    decimalValue := decimalValue div 2;
  end;

  // 필요한 자리수에 맞게 0을 추가
  while Length(Result) < precision do
    Result := '0' + Result;
end;

procedure TCSharpDll.GraySearch(nChannel,nAddr,nData : Integer);
var
sGrayRGB,sDebug : string;
GrayR,GrayG,GrayB,i : Integer;
begin
  case nAddr of
    1684 : begin
      m_sGrayRGB[nChannel,0] := DecimalToBinary(nData,8);
    end;
    1685 : begin
      m_sGrayRGB[nChannel,1] := DecimalToBinary(nData,8);
    end;
    1686 : begin
      m_sGrayRGB[nChannel,2] := DecimalToBinary(nData,8);
    end;
    1687 : begin
      m_sGrayRGB[nChannel,3] := DecimalToBinary(nData,8);
      sGrayRGB := m_sGrayRGB[nChannel,3] + m_sGrayRGB[nChannel,2] + m_sGrayRGB[nChannel,1] + m_sGrayRGB[nChannel,0];
      GrayR := BinaryToDecimal(Copy(sGrayRGB,3,9));
      GrayG := BinaryToDecimal(Copy(sGrayRGB,13,9));
      GrayB := BinaryToDecimal(Copy(sGrayRGB,23,9));
      sDebug := Format('sGrayRGB R : %d G : %d B : %d',[BinaryToDecimal(Copy(sGrayRGB,3,9)),BinaryToDecimal(Copy(sGrayRGB,13,9)),BinaryToDecimal(Copy(sGrayRGB,23,9))]);
      SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,10);

      if m_CurrentBand[nChannel] > 0 then
      begin
        for I := 0 to Length(Common.DGMA_Para[m_CurrentBand[nChannel]-1])-1 do begin
          if  Common.DGMA_Para[m_CurrentBand[nChannel]-1][i].Gray = GrayR then  begin
            m_CurrentTap[nChannel] := i -1;
            sDebug := Format('m_CurrentBand : %d m_CurrentTap : %d - Start ',[m_CurrentBand[nChannel],m_CurrentTap[nChannel]]);
            SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,10);
            exit;
          end;
        end;
        Inc(m_CurrentTap[nChannel]);
        sDebug := Format('m_CurrentBand : %d m_CurrentTap : %d - Start ',[m_CurrentBand[nChannel],m_CurrentTap[nChannel]]);
        SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,10);
      end;

    end;

  end;

end;

procedure TCSharpDll.TconWriteAnalysis (nChannel,nAddr,nData : Integer);
var
sGrayRGB,sDebug,sDBV,sG2VControl: string;
begin
  case nAddr of
    1684 : begin
      CSharpDll.m_sGrayRGB[nChannel,0] := DecimalToBinary(nData,8);
    end;
    1685 : begin
      CSharpDll.m_sGrayRGB[nChannel,1] := DecimalToBinary(nData,8);
    end;
    1686 : begin
      CSharpDll.m_sGrayRGB[nChannel,2] := DecimalToBinary(nData,8);
    end;
    1687 : begin
      CSharpDll.m_sGrayRGB[nChannel,3] := DecimalToBinary(nData,8);
      sGrayRGB := CSharpDll.m_sGrayRGB[nChannel,3] + CSharpDll.m_sGrayRGB[nChannel,2] + CSharpDll.m_sGrayRGB[nChannel,1] + CSharpDll.m_sGrayRGB[nChannel,0];
      sDebug := Format('sGrayRGB R : %d G : %d B : %d',[BinaryToDecimal(Copy(sGrayRGB,3,9)),BinaryToDecimal(Copy(sGrayRGB,13,9)),BinaryToDecimal(Copy(sGrayRGB,23,9))]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,10);
    end;

    1726 : begin
      CSharpDll.m_sDBV[nChannel,0] := DecimalToBinary(nData,8);
    end;
    1727 : begin
      CSharpDll.m_sDBV[nChannel,1] := DecimalToBinary(nData,8);
      sDBV :=  CSharpDll.m_sDBV[nChannel,1] +  CSharpDll.m_sDBV[nChannel,0];
      sDebug := Format('sSet_DBV : %d',[BinaryToDecimal(Copy(sDBV,3,11))]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,10);
    end;

    61571 : begin
      if nData = 64 then m_rTG2VControl[nChannel].RGB := 'R';
      if nData = 128 then m_rTG2VControl[nChannel].RGB := 'G';
      if nData = 192 then m_rTG2VControl[nChannel].RGB := 'B';
    end;

    61568 : begin
      m_rTG2VControl[nChannel].Addr[0] := DecimalToBinary(nData,8);
    end;
    61569 : begin
      m_rTG2VControl[nChannel].Addr[1] := DecimalToBinary(nData,8);
    end;
    61616 : begin
      m_rTG2VControl[nChannel].Data1[0] := DecimalToBinary(nData,8);
    end;
    61617 : begin
      m_rTG2VControl[nChannel].Data1[1] := DecimalToBinary(nData,8);
    end;
    61618 : begin
      m_rTG2VControl[nChannel].Data2[0] := DecimalToBinary(nData,8);
    end;
    61619 : begin
      m_rTG2VControl[nChannel].Data2[1] := DecimalToBinary(nData,8);
    end;
    61620 : begin
      m_rTG2VControl[nChannel].Data3[0] := DecimalToBinary(nData,8);
    end;
    61621 : begin
      m_rTG2VControl[nChannel].Data3[1] := DecimalToBinary(nData,8);
    end;
    61622 : begin
      m_rTG2VControl[nChannel].Data4[0] := DecimalToBinary(nData,8);
    end;
    61623 : begin
      m_rTG2VControl[nChannel].Data4[1] := DecimalToBinary(nData,8);

      sDebug := Format('SetG2VControl RGB : %s ',[m_rTG2VControl[nChannel].RGB]);

      sG2VControl := m_rTG2VControl[nChannel].Addr[1] + m_rTG2VControl[nChannel].Addr[0];
      sDebug := sDebug + Format('SetG2VControl Addr : %d ',[BinaryToDecimal(Copy(sG2VControl,6,8))]);

      sG2VControl := m_rTG2VControl[nChannel].Data1[1] + m_rTG2VControl[nChannel].Data1[0];
      sDebug := sDebug + Format('SetG2VControl Data1 : %d ',[BinaryToDecimal(Copy(sG2VControl,1,12))]);

      sG2VControl := m_rTG2VControl[nChannel].Data2[1] + m_rTG2VControl[nChannel].Data2[0];
      sDebug := sDebug + Format('SetG2VControl Data2 : %d ',[BinaryToDecimal(Copy(sG2VControl,2,12))]);

      sG2VControl := m_rTG2VControl[nChannel].Data3[1] + m_rTG2VControl[nChannel].Data3[0];
      sDebug := sDebug + Format('SetG2VControl Data3 : %d ',[BinaryToDecimal(Copy(sG2VControl,3,12))]);

      sG2VControl := m_rTG2VControl[nChannel].Data4[1] + m_rTG2VControl[nChannel].Data4[0];
      sDebug := sDebug + Format('SetG2VControl Data4 : %d ',[BinaryToDecimal(Copy(sG2VControl,4,12))]);

      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,10);
    end;


  end;
end;

function MyCB_TCONSetReg_Proc(nChannel , Addr : Integer; data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
nResult,i,nRet,nDebugLog : integer;
sGrayRGB : string;
begin
  if CSharpDll <> nil then begin
    Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
    CSharpDll.m_nFlagCount[nChannel] := 0;
    nWaitMS := 1000; //2023-04-08 (3000->100->200->1000)
    nRetry  := 2;   //2023-04-08 (0->3->0)

    {$IFDEF PG_AF9}
    PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
    Result := WAIT_OBJECT_0;
    {$ENDIF}
    {$IFDEF PG_DP860}
    nDataCnt := 1;
    SetLength(arRData,nDataCnt);

    try
      arrData[0] := data;
      sTxData := Format(' 0x%0.2x',[arrData[0]]);

      for I := 0 to nRetry do begin
        if i <> 2 then  nDebugLog := 0
        else nDebugLog := 1;

        nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nDataCnt, arrData, nWaitMS,0,nDebugLog);
        if nResult <> WAIT_OBJECT_0 then begin
          Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
        end
        else begin
          Break;
        end;
      end;
      if nResult <> WAIT_OBJECT_0 then begin
    {$IFDEF SIMULATOR_PG}

    {$ELSE}
        sDebug := Format('TCONSetReg NG CH : %d',[nChannel]);
        CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    {$ENDIF}
      end;
      Result := nResult;
    finally
      SetLength(arRData,0);
    end;

    {$ENDIF}
  end;
end;


function MyCB_TCONSetRegArray_Proc(nChannel , Addr : Integer; const data : PByte; nLength : integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
nResult : integer;
begin
  if CSharpDll <> nil then begin
    Inc(PG[nChannel].TconRWCnt.TconWriteArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
    CSharpDll.m_nFlagCount[nChannel] := 0;
    nWaitMS := 1000; //2023-04-08 (3000->100->200)
    nRetry  := 0;   //2023-04-08 (0->3->0)

    nDataCnt := nLength;
    SetLength(arRData,nDataCnt);
    try
      Move(data^, arRData[0], nLength);

      nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
      if nResult <> WAIT_OBJECT_0  then  begin
        nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
        if nResult <> WAIT_OBJECT_0 then begin
          sDebug := Format('TCONSetRegArray NG CH : %d',[nChannel]);
          CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
        end;
      end;
      Result := nResult;
    finally
      SetLength(arRData,0);
    end;
  end;

end;

function MyCB_TCONSetRegMultiWrite_Proc(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult : integer;
begin
  if CSharpDll <> nil then begin
    Inc(PG[nChannel].TconRWCnt.TconMultiWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
    CSharpDll.m_nFlagCount[nChannel] := 0;
    nWaitMS := 1000; //2023-04-08 (3000->100->200)
    nRetry  := 0;   //2023-04-08 (0->3->0)

    nDataCnt := nLength;
    SetLength(arRAddr,nDataCnt);
    SetLength(arRData,nDataCnt);
    try
      Move(Addr^, arRAddr[0],nDataCnt * SizeOf(Integer));
      Move(data^, arRData[0],nLength);

      nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
      if nResult <> WAIT_OBJECT_0  then  begin
        nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
        if nResult <> WAIT_OBJECT_0 then begin
          sDebug := Format('TCONSetRegMultiWrite NG CH : %d',[nChannel]);
          CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
        end;
      end;
      Result := nResult;
    finally
      SetLength(arRAddr,0);
      SetLength(arRData,0);
    end;
  end;
end;


function MyCB_TCONSetRegSeqWrite_Proc(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult,nDebugLog : integer;
i : Integer;
begin
  if CSharpDll <> nil then begin
    Inc(PG[nChannel].TconRWCnt.TconWriteDllCall);

    CSharpDll.m_nFlagCount[nChannel] := 0;
    nWaitMS := 3000; //2023-04-08 (3000->100->200)
    nRetry  := 2;   //2023-04-08 (0->3->0)

    nDataCnt := nLength;
    SetLength(arRAddr,nDataCnt);
    SetLength(arRData,nDataCnt);
    try
      Move(Addr^, arRAddr[0],nDataCnt * SizeOf(Integer));
      Move(data^, arRData[0],nLength);

      for I := 0 to nRetry do begin
        if i <> 2 then  nDebugLog := 0
        else nDebugLog := 1;
        nResult := Pg[nChannel].DP860_SendTconSeqWrite(nMode,nSeqIdx,nLength,arRAddr, arRData, nWaitMS,0,nDebugLog);
        if nResult <> WAIT_OBJECT_0 then begin
          Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
        end
        else begin
          Break;
        end;
      end;
      if nResult <> WAIT_OBJECT_0 then begin
        sDebug := Format('TCONSetRegSeqWrite NG CH : %d',[nChannel]);
        CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      end;
      Result := nResult;
    finally
      SetLength(arRAddr,0);
      SetLength(arRData,0);
    end;
  end;
end;


function MyCB_TCONGetReg_Proc(nChannel , Addr : Integer; var data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData,arRData2 : TIdBytes;
i : Integer;
nResult,nResult2,nDebugLog : integer;
begin
  if CSharpDll <> nil then begin
    try
      Inc(PG[nChannel].TconRWCnt.TconReadDllCall); //2023-03-28 jhhwang (for T/T Test)
      CSharpDll.m_nFlagCount[nChannel] := 0;
      nResult := 1;
      nWaitMS := 500; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100-> 1000)
      nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)
      data := 0;
      {$IFDEF PG_AF9}
      PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
      Result := WAIT_OBJECT_0;
      {$ENDIF}
      {$IFDEF PG_DP860}
      nDataCnt := 1;

      SetLength(arRData,nDataCnt);
      for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
        nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry},1);
        if nResult = WAIT_OBJECT_0 then break
        else Inc(PG[nChannel].TconRWCnt.TconRetryReadCall);
      end;
      if nResult = WAIT_OBJECT_0 then
        data := arRData[0]
      else begin
        data := 0;
      {$IFDEF SIMULATOR_PG}

      {$ELSE}
        sDebug := Format('TCONGetReg NG CH : %d',[nChannel]);
        CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      {$ENDIF}
      end;
      Result := nResult;
      {$ENDIF}
    finally
      SetLength(arRData,0);
      SetLength(arRData2,0);
    end;
  end;
end;


function MyCB_TCONGetRegArray_Proc(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult : integer;
begin
  Result := 0;
  if CSharpDll <> nil then begin
    Inc(PG[nChannel].TconRWCnt.TconReadArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
    CSharpDll.m_nFlagCount[nChannel] := 0;
    nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
    nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)

    nDataCnt := nLength;
    SetLength(arRData,nDataCnt);
    try
      for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
        nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry});
        if nResult = WAIT_OBJECT_0 then break;
      end;
      if nResult = WAIT_OBJECT_0 then
        CopyMemory(data,@arRData[0],nLength)
      else begin
    {$IFDEF SIMULATOR_PG}

    {$ELSE}
        sDebug := Format('TCONGetRegArray NG CH : %d',[nChannel]);
        CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    {$ENDIF}
      end;
      Result := nResult;
    finally
      SetLength(arRData,0);
    end;
  end;
end;


function MyCB_FlashWrite_File_Proc(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := EndSeg - StartSeg;
  Result := 0;
end;


function MyCB_FlashWrite_Data_Proc(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
  if CSharpDll <> nil then begin
    CSharpDll.m_nFlagCount[nChannel] := 0;
    nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data); //TBD:ITOLED?
    if nResult <> WAIT_OBJECT_0 then begin
      nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data);
      if nResult <> WAIT_OBJECT_0 then begin
        sDebug := Format('FlashWrite_Data NG CH : %d',[nChannel]);
        CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      end;
    end;
    Result := nResult;
  end;
end;


function MyCB_FlashRead_File_Proc(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;


function MyCB_FlashRead_Data_Proc(nChannel,nStartSeg,nLength : Integer; data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
  if CSharpDll <> nil then begin
    CSharpDll.m_nFlagCount[nChannel] := 0;
    nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
    if nResult <> WAIT_OBJECT_0 then begin
      nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
      if nResult <> WAIT_OBJECT_0 then begin
        sDebug := Format('FlashRead_Data NG CH : %d',[nChannel]);
        CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      end;
    end;
    CopyMemory(data,@Logic[nChannel].m_FlashAllData.Data[0],nLength);
    Result := nResult;
  end;
end;


function MyCB_FlashErase_Proc(nChannel,nStartSeg,nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  sDebug := Format('Flash Erase:  StartSeg(0x%0.4x) Length(%d)',[nStartSeg,nLength]);
  Result := Pg[nChannel].DP860_SendNvmErase(nStartSeg,nLength);
end;


function MyCB_GetWaveformData_Proc(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
var
i,j : Integer;
waveform,Data : array of Double;
sDebug : string;
begin
  if CSharpDll <> nil then begin
    CSharpDll.m_nFlagCount[nChannel] := 0;
    SetLength(waveform,nMeasureAmount);
    SetLength(Data,nMeasureAmount);
    try
      result := CaSdk2.GetWaveformData(nChannel,@waveform[0],@Data[0] ,nMeasureAmount);
      CopyMemory(waveform_T,@waveform[0],nMeasureAmount*sizeof(waveform[0]));
      CopyMemory(waveformData,@Data[0],nMeasureAmount*sizeof(waveform[0]));
    finally
      SetLength(waveform,0);
      SetLength(Data,0);
    end;
  end;
end;



function MyCB_measure_XYL_Proc(nChannel:Integer; var dMeasureData : TArray<double>; var nLen : Integer): Integer;
var
i,wdRet: Integer;
m_Ca410Data  : TBrightValue;
sDebug : string;
begin
  if CSharpDll <> nil then begin
    CSharpDll.m_nFlagCount[nChannel] := 0;
    if Common.SystemInfo.PG_GpioReadHpdBeforeMeasure then begin //2023-03-30 jhhwang (for T/T Test)
      PG[nChannel].DP860_SendGpioRead('HPD');
    end;
    PG[nChannel].TconRWCnt.ContTConOcWrite := 0; //2023-03-30 jhhwang (for T/T Test)
    wdRet := CaSdk2.Measure(nChannel,m_Ca410Data);
    if (Common.SystemInfo.PG_TconWriteLogDisplay) then begin
      sDebug := format('<CA410> Measure_XYL : Ca410Data x : %0.4f y : %0.4f LV : %0.4f',[m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    end;
    if wdRet <> WAIT_OBJECT_0 then begin
  {$IFDEF SIMULATOR_PG}

  {$ELSE}
      sDebug := Format('CA410 measure NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
  {$ENDIF}
    end;
    dMeasureData[0] := m_Ca410Data.xVal;
    dMeasureData[1] := m_Ca410Data.yVal;
    dMeasureData[2] := m_Ca410Data.LvVal;
    Result := wdRet;
  end;

end;


function MyCB_SetSync_Proc(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
var
i : Integer;
begin
  if CSharpDll <> nil then begin
    CSharpDll.m_nFlagCount[nChannel] := 0;
    Result := CaSdk2.SetSyncMode(nChannel,CA_SyncMode,CA_Hz,0);
  end;
end;

procedure TCSharpDll.SendTestGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiDLL;
begin
  GuiData.MsgType := defCommon.MSG_TYPE_DLL;
  GuiData.Channel := nCh;
  GuiData.Mode    := nGuiMode;
  GuiData.Param := nParam;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_TestHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TCSharpDll.SendMainGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam,nParam2: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiDLL;
begin
  GuiData.MsgType := MSG_TYPE_NONE;
  GuiData.Channel := nCh;
  GuiData.Mode    := nGuiMode;
  GuiData.Param := nParam;
  GuiData.Param2 := nParam2;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_MainHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TCSharpDll.SetOnRevSwData(nCH : Integer; const Value: TCallBackTextChanged);
begin
	CB_TextChanged[nCH] := Value;
end;


function ExtractNumbersFromString(inputString: string): string;
var
  regex: TRegEx;
  match: TMatch;
begin
  // 정규 표현식을 사용하여 숫자만 추출
  try
    regex := TRegEx.Create('\d+');
    match := regex.Match(inputString);

    // 추출된 숫자를 모두 결합하여 반환
    Result := '';
    while match.Success do
    begin
      Result := Result + match.Value;
      match := match.NextMatch;
    end;
  except
    Result := '';
  end;
end;

procedure TCSharpDll.MLOG(nChannel_Index : Integer; bClear : Boolean; sMLOG : string);
var
  th : TThread;
  sLog,sBand : string;
  nParam : integer;
  arStr : TArray<string>;
begin
  if bClear then nParam := 10
  else nParam := 0;
  if pos('Delay_Time',sMLOG) > 0 then begin
//    sLog := ExtractNumbersFromString(sMLOG);
//    SendTestGuiDisplay(nChannel_Index,defCommon.MSG_MODE_DELAY_TIME,sLog,nParam);
    Exit;
  end;

  if (Pos('Band',sMLOG) > 0) and (pos('Search',sMLOG) > 0)  then begin
    arStr := sMLOG.Split([' ']);
    if Length(arStr) > 2 then begin
      sBand := ExtractNumbersFromString(arStr[1]);
      m_CurrentBand[nChannel_Index] := StrToIntDef(sBand,-1);
    end;
  end;

  SendTestGuiDisplay(nChannel_Index,defCommon.MSG_MODE_WORKING,sMLOG,nParam);
end;

procedure MyCB_TextChanged_Proc(channel_Index : Integer; bClear : Boolean; sAddedText : PAnsiChar);cdecl;
begin
  if CSharpDll <> nil then begin
    CSharpDll.m_nFlagCount[channel_Index] := 0;
    CSharpDll.MLOG(channel_Index,bClear,(PAnsiChar(sAddedText)));
  end;
end;


procedure MyCB_FlowDone_Proc(channel_Index : Integer);
begin
  if CSharpDll <> nil then begin
    CSharpDll.tmCheckOCAlive[channel_Index].Enabled := false;
    CSharpDll.m_OCFlowStart[channel_Index] := False;
    try
      CSharpDll.m_nFlagCount[channel_Index] := 0;
      common.MLog(channel_Index,Format('<SEQUENCE> CountInspections : %d',[CSharpDll.m_CountInspections[channel_Index]]));
    finally
      CSharpDll.SendTestGuiDisplay(channel_Index,defCommon.MSG_MODE_WORK_DONE,'OKFLOW_END',0);
    end;
  end;
end;

procedure TCSharpDll.ThreadTask(Task: TProc);
begin
  TThread.CreateAnonymousThread(
    Task
  ).Start;
end;

function FindAndCloseMsgBoxWithText(Text: string): Boolean;
var
  hWndMsgBox: HWND;
  nButton: Integer;
  sWindowText: string;
begin
  Result := False;
  hWndMsgBox := FindWindow('#32770', nil); // 첫 번째 메시지 창 핸들 검색
  while hWndMsgBox <> 0 do
  begin
    SetLength(sWindowText, GetWindowTextLength(hWndMsgBox) + 1);
    GetWindowText(hWndMsgBox, PChar(sWindowText), Length(sWindowText));
    if Pos(Text, sWindowText) > 0 then // 문자열이 있는 메시지 창이면 종료
    begin
      nButton := SendMessage(GetDlgItem(hWndMsgBox, IDOK), BM_GETCHECK, 0, 0);
      if nButton = BST_CHECKED then
        SendMessage(GetDlgItem(hWndMsgBox, IDOK), BM_CLICK, 0, 0); // OK 버튼 클릭
      nButton := SendMessage(GetDlgItem(hWndMsgBox, IDCANCEL), BM_GETCHECK, 0, 0);
      if nButton = BST_CHECKED then
        SendMessage(GetDlgItem(hWndMsgBox, IDCANCEL), BM_CLICK, 0, 0); // Cancel 버튼 클릭
      Result := True;
      Exit;
    end;
    hWndMsgBox := GetWindow(hWndMsgBox, GW_HWNDNEXT); // 다음 메시지 창 핸들 검색
  end;
end;

function GetMsgBoxText(hWnd: HWND): string;
var
  nLen: Integer;
  lpBuffer: array[0..255] of Char;
begin
  // 메시지 창 텍스트 가져오기
  nLen := SendMessage(hWnd, WM_GETTEXT, Length(lpBuffer), LPARAM(@lpBuffer));
  if nLen > 0 then
    Result := lpBuffer
  else
    Result := '';
end;



function FindMsgBoxWithButton(ButtonCaption: string): HWND;
var
  hResult: HWND;
begin
  hResult := FindWindow('#32770', nil); // 첫 번째 메시지 창 핸들 검색
  while  hResult <> 0 do
  begin
    if (FindWindowEx(hResult, 0, 'Button', PChar(ButtonCaption)) <> 0) and
    (FindWindowEx(hResult, 0, 'Button', PChar('취소')) = 0)  then
      Break; // 버튼이 있는 메시지 창이면 종료
    hResult := GetWindow(Result, GW_HWNDNEXT); // 다음 메시지 창 핸들 검색
  end;
  Result := hResult; // 결과 반환
end;


procedure TCSharpDll.CloseMessageBoxWithButton(ButtonCaption: string);
var
  MsgBoxHandle: HWND;
  ButtonHandle: HWND;
begin
  MsgBoxHandle := FindMsgBoxWithButton(ButtonCaption); // 메시지 창 핸들 검색
  if MsgBoxHandle <> 0 then
  begin
    SendMainGuiDisplay(0,MSG_MODE_ADDLOG,GetMsgBoxText(MsgBoxHandle),0);
    ButtonHandle := FindWindowEx(MsgBoxHandle, 0, 'Button', PChar(ButtonCaption)); // 버튼 핸들 검색
    if ButtonHandle <> 0 then
    begin
      SendMessage(MsgBoxHandle, WM_CLOSE, 0, 0); // 메시지 창 닫기
    end;
  end;
end;

procedure TCSharpDll.tmrCycleTimer(Sender : TObject);
var
nResult : THandle;
hWnd,hMessageBox : THandle;

begin
  tmrCycle.Enabled := false;
  try
    if Common.StatusInfo.AutoMode then
//      CloseMessageBoxWithButton('확인');

//      FindAndCloseMsgBoxWithText('Place the CA410');

//     hWnd := 0;
//     hWnd := FindWindow('#32770',nil);
//     if hWnd > 0 then begin
//       hMessageBox := FindWindowEx(hWnd,0, 'Static','Place the CA410 probe to center position!');
//       if hMessageBox > 0 then
//         PostMessage(hWnd, WM_CLOSE, 0, 0);
//
//
//       hMessageBox := FindWindowEx(hWnd,0, 'Static','CH1 Switch OFF, ON,  Display ON');
//       if hMessageBox > 0 then begin
//
//
//       end;
//     endcr
  finally
     tmrCycle.Enabled := true;
  end;
end;


procedure TCSharpDll.FormDestroy;
begin
  m_FormDestroy;
end;


procedure TCSharpDll.Initialize(sModelName : string);
var
nT1,i : Integer;

sVer : string;
hWnd : THandle;
begin
  try
    nT1 := m_Initialize(DefCommon.MAX_CH + 1,PAnsiChar(AnsiString(sModelName)));
    for I := 0 to 2 do  begin           // AA mode 사용되는  DLL 3가지 호출
      sVer := PAnsiChar(m_GetOCversion(i)); // DLL Ver 정보 API 함수 호출
      SendMainGuiDisplay(0,MSG_TYPE_DLL,sVer,1,i); // DLL Ver 정보 MAIN 전달
    end;
    if @m_GetOCConverterVersion <> nil then
      sVer := PAnsiChar(m_GetOCConverterVersion)
    else sVer := '';
    SendMainGuiDisplay(0,MSG_TYPE_DLL,sVer,2);

    for I := 0 to 31 do
      Common.m_GetDBV[i] := m_GetDBVdata(i);

    for I := DefCommon.CH1 to DefCommon.MAX_CH do begin
      m_SetCallback_TextChanged(i,CB_TextChanged[i]);
      m_SetCallback_measure_XYL(i,CB_measure_XYL[i]);
      m_SetCallback_SetSync(i,CB_SetSync[i]);
      m_SetCallback_GetWaveformData(i,CB_GetWaveformData[i]);
      m_SetCallBackAllPowerOnOff    (i,CB_PowerOnOff[i]);
      m_SetCallBackTCONSetReg       (i,CB_TCONSetReg[i]);
      m_SetCallBackTCONGetReg       (i,CB_TCONGetReg[i]);
      m_SetCallBackFlashWrite_File  (i,CB_FlashWrite_File[i]);
      m_SetCallBackFlashWrite_Data  (i,CB_FlashWrite_Data[i]);
      m_SetCallBackFlashRead_File   (i,CB_FlashRead_File[i]);
      m_SetCallBackFlashRead_Data   (i,CB_FlashRead_Data[i]);
      m_SetCallBackFlashErase       (i,CB_FlashErase[i]);
      m_SetCallBackTCONSetRegArray       (i,CB_TCONSetRegArray[i]);
      m_SetCallBackTCONGetRegArray       (i,CB_TCONGetRegArray[i]);
      if @m_SetCallBackTCONMultiSetReg <> nil then
        m_SetCallBackTCONMultiSetReg(i,CB_TCONMultiSetReg[i]);
      if @m_SetCallBackTCONSeqSetReg <> nil then
        m_SetCallBackTCONSeqSetReg(i,CB_TCONSeqSetReg[i]);

      if @m_SetCallback_FlowDone <> nil then
        m_SetCallback_FlowDone(i,CB_FlowDone[i]);

    end;
  finally
  end;
end;

function TCSharpDll.MainOC_GetOCFlowIsAlive(nCH : Integer): Integer;
begin
  if nCH > DefCommon.MAX_CH then
    Result := 0
  else
    Result := m_MainOC_IsAlive(m_nDLLType[nCH],nCH);
end;

function TCSharpDll.MainOC_GetSummaryLogData(nCH : Integer; sParameter : string): string;
var
nReturn,i : Integer;
sResult : string;
begin
  try
    nReturn := 0;
    Result := '';
    sParameter := sParameter + #0;
    if @m_GetSummaryLogData_New <> nil then begin
      for I := 0 to 2 do begin
        sResult := PAnsiChar(m_GetSummaryLogData_New(m_nDLLType[nCH],nCH,nReturn,Common.StringToPAnsiChar(sParameter)));
        if (nReturn = 0) and (Length(sResult) <> 0) then  Break;
      end;
      Result := sResult;
    end
    else begin
      Result := PAnsiChar(m_GetSummaryLogData(m_nDLLType[nCH],nCH,Common.StringToPAnsiChar(sParameter)));
    end;
  except
    Common.MLog(nCH,'GetSummaryLogData Error Occurrence!!');
    Result := PAnsiChar(m_GetSummaryLogData(m_nDLLType[nCH],nCH,Common.StringToPAnsiChar(sParameter)));
  end;
end;

function TCSharpDll.MainOC_ChangeDLL(sDLLName : string): Integer;
begin
  Result := 0;
end;

procedure TCSharpDll.SendHWCID(nCH : integer);
var
sHWCID : string;
begin
  sHWCID := Pg[nCH].m_HWCID[1] + ',' + Pg[nCH].m_HWCID[0] + ',' + Pg[nCH].m_HWCID[2] + ',' + Pg[nCH].m_HWCID[3] + ',' + Pg[nCH].m_HWCID[4];
  SendTestGuiDisplay(nCH,defCommon.MSG_MODE_LOG_HWCID,sHWCID,0);
end;


function TCSharpDll.MainOC_Start(nDLLType,nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
var
sParameter : string;
sHWCID,sDebug : string;
sCrcData   : AnsiString;
dCheckSum: dword;
begin
  try
    m_nDLLType[nCH] := nDLLType;
    sParameter := sPID + ',' + sSerialNumber + ',' + sUser_ID +',' + sEquipment + #0;
    sDebug := sParameter + #13#10 +'Memory usage : ' + Format('%0.2f%%', [Common.GetMemoryUsagePercentage]);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sDebug,0);
    SendHWCID(nCH);
    m_bIsProcessDone[nCH] := False;
    m_sSerialNo[nCH] := sSerialNumber;
    m_CurrentBand[nCH] := 0;
    m_CurrentTap[nCH] := 0;
    m_CountInspections[nCH] := 0; //검사 횟수 초기화
    dCheckSum := Common.crc16(sParameter,Length(sParameter)-1);
    if StartFunctions[nCH](nDLLType,nCH,Common.StringToPAnsiChar(sParameter),Length(sParameter)-1,dCheckSum) <> 0 then
      Exit(2);
    m_OCFlowStart[nCH] := true;
    tmCheckOCAlive[nCH].Enabled := True;
    Result := 0;
  except
    Result := 2;
  end;
end;

function TCSharpDll.MainOC_Stop(nCH : Integer): integer;
begin
  try
    StopFunctions[nCH](m_nDLLType[nCH],nCH);
  finally
    Result := 0;
  end;
end;



function TCSharpDll.MainOC_Flash_Read(nCH : Integer): integer;
begin
  m_MainOC_Flash_Read(nCH);
end;



function TCSharpDll.MainOC_ThreadStateCheck(nCH : Integer): integer;
begin
  Result :=  m_MainOC_ThreadStateCheck(nCH);
end;

function TCSharpDll.MainOC_Verify_Start(nCH : Integer): integer;
begin
  Result :=  m_MainOC_VerifyStart(nCH);
end;

destructor TCSharpDll.Destroy;
var
i : integer;
hWnd : THandle;
begin

  for I := 0 to DefCommon.MAX_CH do begin
    if tmCheckOCAlive[i] <> nil then begin
      tmCheckOCAlive[i].Enabled := False;
      tmCheckOCAlive[i].Free;
      tmCheckOCAlive[i] := nil;
    end;
  end;
  m_UnInit;
  hWnd := FindWindow(nil,'Form_Hidden');    // Added by KTS 2023-01-17 오후 3:05:15 LGD DLL Form 닫기
  if hWnd > 0 then
    PostMessage(hWnd, WM_CLOSE, 0, 0);

  SetLength(m_bIsProcessDone,0);
  SetLength(m_bIsProcessUnloadDone,0);
  SetLength(m_bIsDLLWork,0);

  if tmrCycle <> nil then  begin
    tmrCycle.Free;
    tmrCycle := nil;

  end;
  FreeLibrary(m_hDll);
  m_hDll := 0;
  inherited;
end;



procedure TCSharpDll.CreateCallBackFunction;
var
  i : integer;
begin
  for I := DefCommon.CH1 to DefCommon.MAX_CH do begin
    @CB_PowerOnOff[i] := @MyCB_AllPowerOnOff[i];
    @CB_TCONSetReg[i] := @MyCB_TCONSetReg[i];
    @CB_TCONGetReg[i] := @MyCB_TCONGetReg[i];
    @CB_FlashWrite_File[i] := @MyCB_FlashWrite_File[i];
    @CB_FlashWrite_Data[i] := @MyCB_FlashWrite_Data[i];
    @CB_FlashRead_File[i] := @MyCB_FlashRead_File[i];
    @CB_FlashRead_Data[i] := @MyCB_FlashRead_Data[i];
    @CB_FlashErase[i] := @MyCB_FlashErase[i];

    @CB_TCONSetRegArray[i] := @MyCB_TCONSetRegArray[i];
    @CB_TCONGetRegArray[i] := @MyCB_TCONGetRegArray[i];

    @CB_TCONMultiSetReg[i] := @MyCB_TCONSetRegMultiWrite[i];
    @CB_TCONSeqSetReg[i] := @MyCB_TCONSetRegSeqWrite[i];
    @CB_Measure_XYL[i] := @MyCB_measure_XYL[i];
    @CB_SetSync[i] := @MyCB_SetSync[i];
    @CB_GetWaveformData[i] := @MyCB_GetWaveformData[i];
    @CB_TextChanged[i] := @MyCB_TextChanged[i];

    @CB_FlowDone[i] := @MyCB_FlowDone[i];
  end;
end;




procedure TCSharpDll.Setfunction;
var
  I: Integer;
  StartFuncPtr: FARPROC;
  StopFuncPtr: FARPROC;
begin
  @m_Initialize      := GetProcAddress(m_hDll, 'Initialize');
  @m_FormDestroy     := GetProcAddress(m_hDll, 'FormDestroy');

  @m_Init            := GetProcAddress(m_hDll, 'DLL_Directory_Init');
  @m_Init2            := GetProcAddress(m_hDll, 'Init2');
  @m_UnInit          := GetProcAddress(m_hDll, 'DLL_Directory_UnInit');

  @m_MainOC_Flash_Read := GetProcAddress(m_hDll, 'MainOC_Flash_Read');

  @m_GetOCversion := GetProcAddress(m_hDll, 'GetOCversion');
  @m_GetOCConverterVersion := GetProcAddress(m_hDll, 'GetOC_Converterversion');
  @m_GetDBVdata := GetProcAddress(m_hDll, 'GetDBVdata');

  @m_MainOC_IsAlive := GetProcAddress(m_hDll, 'GetOCFlowIsAlive');

  @m_SetCallback_measure_XYL := GetProcAddress(m_hDll, 'Callback_measure_XYL');
  @m_SetCallback_SetSync := GetProcAddress(m_hDll,'Callback_SetSync');
  @m_SetCallback_GetWaveformData := GetProcAddress(m_hDll,'Callback_GetWaveformData');
  @m_GetSummaryLogData := GetProcAddress(m_hDll,'GetSummaryLogData');

  @m_GetSummaryLogData_New := GetProcAddress(m_hDll,'GetSummaryLogData_New');

  for I := DefCommon.CH1 to DefCommon.CH4 do
  begin
    StartFuncPtr := GetProcAddress(m_hDll, PAnsiChar(AnsiString(Format('MainOC_START_CH%d', [I+1]))));
    StopFuncPtr := GetProcAddress(m_hDll, PAnsiChar(AnsiString(Format('MainOC_STOP_CH%d', [I+1]))));

    if Assigned(StartFuncPtr) then
      StartFunctions[I] := TStartFunction(StartFuncPtr);

    if Assigned(StopFuncPtr) then
      StopFunctions[I] := TStopFunction(StopFuncPtr);

    MyCB_TextChanged[i] := MyCB_TextChanged_Proc;
    MyCB_AllPowerOnOff[i] := MyCB_AllPowerOnOff_Proc;

    MyCB_TCONSetReg[i]            :=      MyCB_TCONSetReg_Proc;
    MyCB_TCONGetReg[i]            :=      MyCB_TCONGetReg_Proc;
    MyCB_TCONSetRegArray[i]       :=      MyCB_TCONSetRegArray_Proc;
    MyCB_TCONSetRegMultiWrite[i]  :=      MyCB_TCONSetRegMultiWrite_Proc;
    MyCB_TCONSetRegSeqWrite[i]    :=      MyCB_TCONSetRegSeqWrite_Proc;
    MyCB_TCONGetRegArray[i]       :=      MyCB_TCONGetRegArray_Proc;
    MyCB_FlashWrite_File[i]       :=      MyCB_FlashWrite_File_Proc;
    MyCB_FlashWrite_Data[i]       :=      MyCB_FlashWrite_Data_Proc;
    MyCB_FlashRead_File[i]        :=      MyCB_FlashRead_File_Proc;
    MyCB_FlashRead_Data[i]        :=      MyCB_FlashRead_Data_Proc;
    MyCB_FlashErase[i]            :=      MyCB_FlashErase_Proc;
    MyCB_measure_XYL[i]           :=      MyCB_measure_XYL_Proc;
    MyCB_GetWaveformData[i]       :=      MyCB_GetWaveformData_Proc;
    MyCB_SetSync[i]               :=      MyCB_SetSync_Proc;
    MyCB_FlowDone[i]              :=       MyCB_FlowDone_Proc;
  end;

  @m_MainOC_VerifyStart :=  GetProcAddress(m_hDll,'Verify_Start');
  @m_MainOC_ThreadStateCheck := GetProcAddress(m_hDll,'ThreadStateCheck');

  @m_SetCallback_TextChanged := GetProcAddress(m_hDll,'Callback_TextChanged');

  @m_SetCallBackAllPowerOnOff      := GetProcAddress(m_hDll,'Callback_AllPowerOnOff');
  @m_SetCallBackTCONSetReg         := GetProcAddress(m_hDll,'Callback_TCONSetReg');
  @m_SetCallBackTCONGetReg         := GetProcAddress(m_hDll,'Callback_TCONGetReg');

  @m_SetCallBackTCONSetRegArray    := GetProcAddress(m_hDll,'Callback_TCONSetRegArray');
  @m_SetCallBackTCONGetRegArray    := GetProcAddress(m_hDll,'Callback_TCONGetRegArray');
  @m_SetCallBackFlashWrite_File    := GetProcAddress(m_hDll,'Callback_FlashWrite_File');
  @m_SetCallBackFlashWrite_Data    := GetProcAddress(m_hDll,'Callback_FlashWrite_Data');
  @m_SetCallBackFlashRead_File     := GetProcAddress(m_hDll,'Callback_FlashRead_File');
  @m_SetCallBackFlashRead_Data     := GetProcAddress(m_hDll,'Callback_FlashRead_Data');
  @m_SetCallBackFlashErase         := GetProcAddress(m_hDll,'Callback_FlashErase');

  @m_SetCallBackTCONMultiSetReg    := GetProcAddress(m_hDll,'Callback_TCONSetRegMultiwrite');
  @m_SetCallBackTCONSeqSetReg    := GetProcAddress(m_hDll,'Callback_TCONSetRegSeqWrite');

  @m_SetCallback_FlowDone    := GetProcAddress(m_hDll,'Callback_FlowDone');

end;

procedure TCSharpDll.SetNgMsg(const Value: string);
begin
  FNgMsg := Value;
end;



end.
