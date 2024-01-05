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
    nParam  : Integer;
    nParam2 : Integer;
    Msg     : string;
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

//    m_SetCallback  : procedure ( t8 : CallBackSample); cdecl;


    m_MainOC_VerifyStart : function(nCH : Integer): Integer; cdecl;
    m_MainOC_ThreadStateCheck : function(nCH : Integer): Integer; cdecl;

    m_SetCallback_measure_XYL : procedure (nChannel : Integer; CaallbackFunction : TCallBackMeasure_XYL); cdecl;
    m_SetCallback_SetSync : procedure (nChannel : Integer; CaallbackFunction : TCallBackSetSync);cdecl;
    m_SetCallback_GetWaveformData : procedure (nChannel : Integer; CaallbackFunction : TCallBackGetWaveformData);cdecl;

    m_SetCallback_TextChanged : procedure (nChannel : integer; CaallbackFunction : TCallBackTextChanged);cdecl;


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
    m_CountInspections : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Integer;
    FDataArray: array of TArray<Integer>;
    m_GetSummaryLogData : function (nCH : Integer; sParameter : PAnsiChar): PAnsiChar; cdecl;

    m_GetOCConverterVersion : function : PAnsiChar; cdecl;
    m_MainOC_START_CH1 : function(nCH : Integer; sParameter : PAnsiChar; nLength,nCheckSum : Integer): Integer; cdecl;
    m_MainOC_START_CH2 : function(nCH : Integer; sParameter : PAnsiChar; nLength,nCheckSum : Integer): Integer; cdecl;
    m_MainOC_START_CH3 : function(nCH : Integer; sParameter : PAnsiChar; nLength,nCheckSum : Integer): Integer; cdecl;
    m_MainOC_START_CH4 : function(nCH : Integer; sParameter : PAnsiChar; nLength,nCheckSum : Integer): Integer; cdecl;
    m_MainOC_STOP_CH1 : procedure(nCH : Integer); cdecl;
    m_MainOC_STOP_CH2 : procedure(nCH : Integer); cdecl;
    m_MainOC_STOP_CH3 : procedure(nCH : Integer); cdecl;
    m_MainOC_STOP_CH4 : procedure(nCH : Integer); cdecl;

    m_MainOC_Flash_Read : procedure (nCH : Integer); cdecl;

    m_MainOC_IsAlive : function (nCH : Integer) : Integer; cdecl;

    m_MainOC_ChangeDLL : function(sDLLName : PAnsiChar): Integer;  cdecl;

    m_nFlagCount : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Integer;
//    m_sFlagString : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of string[255];

    m_sSerialNo : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of string;

    CB_PowerOnOff           : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackAllPowerOnOff;

    CB_TCONSetReg           : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackTCONSetReg;
    CB_TCONGetReg           : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackTCONGetReg;
    CB_TCONSetRegArray      : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackTCONSetRegArray;
    CB_TCONGetRegArray      : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackTCONGetRegArray;
    CB_FlashWrite_File      : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackFlashWrite_File;
    CB_FlashWrite_Data      : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackFlashWrite_Data;
    CB_FlashRead_File       : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackFlashRead_File;
    CB_FlashRead_Data       : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackFlashRead_Data;
    CB_FlashErase           : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackFlashErase;
    CB_TCONMultiSetReg      : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackTCONMultiSetReg;
    CB_TCONSeqSetReg        : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackTCONSeqSetReg;
    CB_Measure_XYL          : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackMeasure_XYL;
    CB_SetSync              : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackSetSync;
    CB_GetWaveformData      : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackGetWaveformData;
    CB_TextChanged          : array [DefCommon.CH1 .. DefCommon.MAX_CH] of  TCallBackTextChanged;

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
    procedure SendMainGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
    procedure OntmGetOCFlowIsAlive1(Sender : TObject);
    procedure OntmGetOCFlowIsAlive2(Sender : TObject);
    procedure OntmGetOCFlowIsAlive3(Sender : TObject);
    procedure OntmGetOCFlowIsAlive4(Sender : TObject);

    procedure TconWriteAnalysis(nChannel,nAddr,nData : Integer);

  public
    m_GetDBVdata : function(nBand : Integer): Integer; cdecl;
    m_bIsDLLWork :array of Boolean; // Added by KTS 2022-12-27 오전 9:00:40 현재 DLL 작업중 확ㅇ인
    m_bIsProcessDone : array of Boolean;
    m_bIsProcessUnloadDone : array of Boolean;
    m_GetOCversion : function : PAnsiChar; cdecl;
    m_OCFlowStart : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Boolean;
    m_OCCkSerialNB : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Boolean;
    constructor Create(hMain,hTest: HWND;sDLLPath, sFileName: string);
    procedure  Create_Test;
    destructor Destroy; override;
    procedure MLOG(nChannel_Index : Integer;bClear : Boolean; sMLOG : string);

    procedure Initialize(sModelName : string);
    procedure FormDestroy;
    function MainOC_Start_CH1(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
    function MainOC_Start_CH2(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
    function MainOC_Start_CH3(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
    function MainOC_Start_CH4(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
    function MainOC_Stop_CH1(nCH : Integer): integer;
    function MainOC_Stop_CH2(nCH : Integer): integer;
    function MainOC_Stop_CH3(nCH : Integer): integer;
    function MainOC_Stop_CH4(nCH : Integer): integer;
    function MainOC_Verify_Start(nCH : Integer): integer;
    function MainOC_ThreadStateCheck(nCH : Integer): integer;
    function MainOC_Flash_Read(nCH : Integer): integer;
    function MainOC_GetOCFlowIsAlive(nCH : Integer): Integer;

    function MainOC_GetSummaryLogData(nCH : Integer; sParameter : string): string;

    function MainOC_ChangeDLL(sDLLName : string): Integer;

//    property OnRevSwData : TArray<TCallBackTextChanged> write CB_TextChangedTEST;
//    property OnRevData : TCallBackTextChanged write SetOnRevSwData ;
    property NgMsg : string read FNgMsg write SetNgMsg;

  end;


  procedure MyCB_TextChanged_1(channel_Index : Integer; bClear : Boolean;  sAddedText : PAnsiChar);cdecl;
  procedure MyCB_TextChanged_2(channel_Index : Integer; bClear : Boolean;  sAddedText : PAnsiChar);cdecl;
  procedure MyCB_TextChanged_3(channel_Index : Integer; bClear : Boolean;  sAddedText : PAnsiChar);cdecl;
  procedure MyCB_TextChanged_4(channel_Index : Integer; bClear : Boolean;  sAddedText : PAnsiChar);cdecl;


  function MyCB_AllPowerOnOff_1(nChannel,OnOff: Integer): Integer;
  function MyCB_AllPowerOnOff_2(nChannel,OnOff: Integer): Integer;
  function MyCB_AllPowerOnOff_3(nChannel,OnOff: Integer): Integer;
  function MyCB_AllPowerOnOff_4(nChannel,OnOff: Integer): Integer;

  function MyCB_TCONSetReg_1(nChannel,Addr : Integer; data : Byte): Integer;
  function MyCB_TCONSetReg_2(nChannel,Addr : Integer; data : Byte): Integer;
  function MyCB_TCONSetReg_3(nChannel,Addr : Integer; data : Byte): Integer;
  function MyCB_TCONSetReg_4(nChannel,Addr : Integer; data : Byte): Integer;

  function MyCB_TCONGetReg_1(nChannel,Addr : Integer; var data : Byte): Integer;
  function MyCB_TCONGetReg_2(nChannel,Addr : Integer; var data : Byte): Integer;
  function MyCB_TCONGetReg_3(nChannel,Addr : Integer; var data : Byte): Integer;
  function MyCB_TCONGetReg_4(nChannel,Addr : Integer; var data : Byte): Integer;

  function MyCB_TCONSetRegArray_1(nChannel,Addr : Integer; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegArray_2(nChannel,Addr : Integer; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegArray_3(nChannel,Addr : Integer; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegArray_4(nChannel,Addr : Integer; const data : PByte; nLength : Integer): Integer;

  function MyCB_TCONSetRegMultiWrite_1(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegMultiWrite_2(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegMultiWrite_3(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegMultiWrite_4(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;

  function MyCB_TCONSetRegSeqWrite_1(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegSeqWrite_2(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegSeqWrite_3(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
  function MyCB_TCONSetRegSeqWrite_4(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;


  function MyCB_TCONGetRegArray_1(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
  function MyCB_TCONGetRegArray_2(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
  function MyCB_TCONGetRegArray_3(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
  function MyCB_TCONGetRegArray_4(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;

  function MyCB_FlashWrite_File_1(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashWrite_File_2(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashWrite_File_3(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashWrite_File_4(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;

  function MyCB_FlashWrite_Data_1(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
  function MyCB_FlashWrite_Data_2(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
  function MyCB_FlashWrite_Data_3(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
  function MyCB_FlashWrite_Data_4(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;

  function MyCB_FlashRead_File_1(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashRead_File_2(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashRead_File_3(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
  function MyCB_FlashRead_File_4(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;

  function MyCB_FlashRead_Data_1(nChannel,nStartSeg,nLength : Integer;  data: PByte): Integer;
  function MyCB_FlashRead_Data_2(nChannel,nStartSeg,nLength : Integer;  data: PByte): Integer;
  function MyCB_FlashRead_Data_3(nChannel,nStartSeg,nLength : Integer;  data: PByte): Integer;
  function MyCB_FlashRead_Data_4(nChannel,nStartSeg,nLength : Integer;  data: PByte): Integer;


  function MyCB_FlashErase_1(nChannel,nStartSeg,nLength : Integer): Integer;
  function MyCB_FlashErase_2(nChannel,nStartSeg,nLength : Integer): Integer;
  function MyCB_FlashErase_3(nChannel,nStartSeg,nLength : Integer): Integer;
  function MyCB_FlashErase_4(nChannel,nStartSeg,nLength : Integer): Integer;

  function MyCB_measure_XYL_1(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;
  function MyCB_measure_XYL_2(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;
  function MyCB_measure_XYL_3(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;
  function MyCB_measure_XYL_4(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;

  function MyCB_GetWaveformData_1(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
  function MyCB_GetWaveformData_2(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
  function MyCB_GetWaveformData_3(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
  function MyCB_GetWaveformData_4(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;

  function MyCB_SetSync_1(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
  function MyCB_SetSync_2(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
  function MyCB_SetSync_3(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
  function MyCB_SetSync_4(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
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
//  Common.MLog(DefCommon.MAX_SYSTEM_LOG,Format('TCSharpDll.Create sDllFile : %s',[sDllFile]));
  SendTestGuiDisplay(MAX_SYSTEM_LOG,DefCommon.MSG_MODE_WORKING,Format('TCSharpDll.Create sDllFile : %s',[sDllFile]));

  m_MainHandle := hMain;
  m_TestHandle := hTest;
  SetLength(m_bIsProcessDone,4);
  SetLength(m_bIsProcessUnloadDone,4);
  SetLength(m_bIsDLLWork,4);

  for I := 0 to DefCommon.MAX_CH do begin

    m_bIsProcessDone[i] := False;
    m_bIsDLLWork[i] := False;

    m_OCFlowStart[i] := False;

    m_OCCkSerialNB[i] := False;
    m_sSerialNo[i] := '';

    tmCheckOCAlive[i] := TTimer.Create(nil);
    tmCheckOCAlive[i].Interval := 1000;
    tmCheckOCAlive[i].Enabled := False;
    case i of
    DefCommon.CH1 :
      begin
        tmCheckOCAlive[i].OnTimer := OntmGetOCFlowIsAlive1;
      end;
    DefCommon.CH2 :
      begin
        tmCheckOCAlive[i].OnTimer := OntmGetOCFlowIsAlive2;
      end;
    DefCommon.CH3 :
      begin
        tmCheckOCAlive[i].OnTimer := OntmGetOCFlowIsAlive3;
      end;
    DefCommon.CH4 :
      begin
        tmCheckOCAlive[i].OnTimer := OntmGetOCFlowIsAlive4;
      end;
    end;

  end;

  FNgMsg := '';
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

//  common.MLog(DefCommon.MAX_SYSTEM_LOG,'TCSharpDll.Create End');
  SendTestGuiDisplay(MAX_SYSTEM_LOG,DefCommon.MSG_MODE_WORKING,'TCSharpDll.Create End');

end;


procedure TCSharpDll.OntmGetOCFlowIsAlive1(Sender: TObject);
var
 nPGCH : integer;
begin
  nPGCH := 0;
  if (m_OCFlowStart[nPGCH]) and Pg[nPGCH].bIsReProgramming  then begin
    Pg[nPGCH].bIsReProgramming := False;
//    common.MLog(DefCommon.CH1,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH1(nPGCH);
  end;
  if (m_OCFlowStart[nPGCH]) and  m_OCCkSerialNB[nPGCH] then begin
    m_OCCkSerialNB[nPGCH] := False;
//    common.MLog(nPGCH,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sFlagString[nPGCH])]));
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sSerialNo[nPGCH])]));
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH1(nPGCH);
  end;

  if (m_OCFlowStart[nPGCH]) and (MainOC_GetOCFlowIsAlive(nPGCH) = 0) then begin
    m_OCFlowStart[nPGCH] := False;
    tmCheckOCAlive[nPGCH].Enabled := false;
    m_nFlagCount[nPGCH] := 0;
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> CountInspections : %d',[m_CountInspections[nPGCH]]));
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_WORK_DONE,'OKFLOW_END',0);
  end;
//  m_nFlagCount[nPGCH] := m_nFlagCount[nPGCH] + 1;
//  if (m_nFlagCount[nPGCH] > 60) then begin
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,CSharpDll.m_sFlagString[nPGCH]);
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH]));
////    Common.MLog(nPGCH,CSharpDll.m_sFlagString[nPGCH]);
////    Common.MLog(nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH]));
//    m_nFlagCount[nPGCH] := 0;
//  end;


end;

procedure TCSharpDll.OntmGetOCFlowIsAlive2(Sender: TObject);
var
 nPGCH : integer;
begin
  nPGCH := 1;
  if (m_OCFlowStart[nPGCH]) and Pg[nPGCH].bIsReProgramming then begin
    Pg[nPGCH].bIsReProgramming := False;
//    common.MLog(DefCommon.CH2,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH2(nPGCH);
  end;
  if (m_OCFlowStart[nPGCH]) and  m_OCCkSerialNB[nPGCH] then begin
    m_OCCkSerialNB[nPGCH] := False;
//    common.MLog(nPGCH,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sFlagString[nPGCH])]));
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sSerialNo[nPGCH])]));
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH2(nPGCH);
  end;

  if (m_OCFlowStart[nPGCH]) and (MainOC_GetOCFlowIsAlive(nPGCH) = 0) then begin
    m_OCFlowStart[nPGCH] := False;
    tmCheckOCAlive[nPGCH].Enabled := false;
    m_nFlagCount[nPGCH] := 0;
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> CountInspections : %d',[m_CountInspections[nPGCH]]));
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_WORK_DONE,'OKFLOW_END',0);

  end;
//  m_nFlagCount[nPGCH] := m_nFlagCount[nPGCH] + 1;
//  if (m_nFlagCount[nPGCH] > 60)  then begin
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,CSharpDll.m_sFlagString[nPGCH]);
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH]));
////    Common.MLog(nPGCH,CSharpDll.m_sFlagString[nPGCH]);
////    Common.MLog(nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH]));
//    m_nFlagCount[nPGCH] := 0;
//  end;

end;

procedure TCSharpDll.OntmGetOCFlowIsAlive3(Sender: TObject);
var
 nPGCH : integer;
begin
  nPGCH := 2;
  if (m_OCFlowStart[nPGCH]) and Pg[nPGCH].bIsReProgramming then begin
    Pg[nPGCH].bIsReProgramming := False;
//    common.MLog(nPGCH,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH3(nPGCH);
  end;
  if (m_OCFlowStart[nPGCH]) and  m_OCCkSerialNB[nPGCH] then begin
    m_OCCkSerialNB[nPGCH] := False;
//    common.MLog(nPGCH,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sFlagString[nPGCH])]));
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sSerialNo[nPGCH])]));
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH3(nPGCH);
  end;
  if (m_OCFlowStart[nPGCH]) and (MainOC_GetOCFlowIsAlive(nPGCH) = 0) then begin
    m_OCFlowStart[nPGCH] := False;
    tmCheckOCAlive[nPGCH].Enabled := false;
    m_nFlagCount[nPGCH] := 0;
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> CountInspections : %d',[m_CountInspections[nPGCH]]));
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_WORK_DONE,'OKFLOW_END',0);

  end;
//  m_nFlagCount[nPGCH] := m_nFlagCount[nPGCH] + 1;
//  if (m_nFlagCount[nPGCH] > 60)  then begin
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,CSharpDll.m_sFlagString[nPGCH]);
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH]));
////    Common.MLog(nPGCH,CSharpDll.m_sFlagString[nPGCH]);
////    Common.MLog(nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH]));
//    m_nFlagCount[nPGCH] := 0;
//  end;

end;

procedure TCSharpDll.OntmGetOCFlowIsAlive4(Sender: TObject);
var
 nPGCH : integer;
begin
  nPGCH := 3;
  if (m_OCFlowStart[nPGCH]) and Pg[nPGCH].bIsReProgramming then begin
    Pg[nPGCH].bIsReProgramming := False;
//    common.MLog(nPGCH,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,'<SEQUENCE> ReProgramming - NG');
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH4(nPGCH);
  end;
  if (m_OCFlowStart[nPGCH]) and  m_OCCkSerialNB[nPGCH] then begin
    m_OCCkSerialNB[nPGCH] := False;
//    common.MLog(nPGCH,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sFlagString[nPGCH])]));
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> S/N Matching ERR(%d) - NG',[Length(m_sSerialNo[nPGCH])]));
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_LOG_REPGM,'',0);
    CSharpDll.MainOC_Stop_CH4(nPGCH);
  end;
  if (m_OCFlowStart[nPGCH]) and (MainOC_GetOCFlowIsAlive(nPGCH) = 0) then begin
    SendTestGuiDisplay(nPGCH,DefCommon.MSG_MODE_WORKING,Format('<SEQUENCE> CountInspections : %d',[m_CountInspections[nPGCH]]));
    m_OCFlowStart[nPGCH] := False;
    tmCheckOCAlive[nPGCH].Enabled := false;
    m_nFlagCount[nPGCH] := 0;
    SendTestGuiDisplay(nPGCH,defCommon.MSG_MODE_WORK_DONE,'OKFLOW_END',0);

  end;
//  m_nFlagCount[nPGCH] := m_nFlagCount[nPGCH] + 1;
//  if (m_nFlagCount[nPGCH] > 60) then begin
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,CSharpDll.m_sFlagString[nPGCH]);
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH]));
////    Common.MLog(nPGCH,CSharpDll.m_sFlagString[nPGCH]);
////    Common.MLog(nPGCH,format(' CH : %d  FlagCheck time out : 60s', [nPGCH+1]));
//    m_nFlagCount[nPGCH] := 0;
//  end;

end;

procedure TCSharpDll.Create_Test;
begin
  CreateCallBackFunction;

  tmrCycle := TTimer.Create(nil);
  tmrCycle.Interval := 500;
  tmrCycle.OnTimer := tmrCycleTimer;
  tmrCycle.Enabled := True;

end;

function MyCB_AllPowerOnOff_1(nChannel,OnOff: Integer): Integer;
var
nWaitMS,nRetry,wdRet : Integer;
PwrData : PPwrData;
begin
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
//  Sleep(500); //2023-04-05
  {$ENDIF}
end;


function MyCB_AllPowerOnOff_2(nChannel,OnOff: Integer): Integer;
var
nWaitMS,nRetry,wdRet : Integer;
begin
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
//  Sleep(500); //2023-04-05
  {$ENDIF}
end;

function MyCB_AllPowerOnOff_3(nChannel,OnOff: Integer): Integer;
var
nWaitMS,nRetry,wdRet : Integer;
begin
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
//  Sleep(500); //2023-04-05
  {$ENDIF}
end;

function MyCB_AllPowerOnOff_4(nChannel,OnOff: Integer): Integer;
var
nWaitMS,nRetry,wdRet : Integer;
begin
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
//  Sleep(500); //2023-04-05
  {$ENDIF}
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

function MyCB_TCONSetReg_1(nChannel , Addr : Integer; data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
nResult,i,nRet,nDebugLog : integer;
sGrayRGB : string;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  {$IFDEF PG_AF9}
  PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
  Result := WAIT_OBJECT_0;
  {$ENDIF}
  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    CSharpDll.TconWriteAnalysis(nChannel,Addr,data);
  end;
  nDataCnt := 1;
  SetLength(arRData,nDataCnt);
  arrData[0] := data;
  sTxData := Format(' 0x%0.2x',[arrData[0]]);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nDataCnt, arrData, nWaitMS,0,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetReg NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);

//      nRet:= Application.MessageBox('SendI2CWrite NG!!', 'Confirm', MB_OK + MB_ICONQUESTION);
//      if nRet = IDOK then Break;
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH1(nChannel);
  end;

  Result := nResult;

  {$ENDIF}
end;


function MyCB_TCONSetReg_2(nChannel , Addr : Integer; data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData,sGrayRGB : string;
arRData : TIdBytes;
nResult,i,nRet,nDebugLog: integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  {$IFDEF PG_AF9}
  PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
  Result := WAIT_OBJECT_0;
  {$ENDIF}
  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    CSharpDll.TconWriteAnalysis(nChannel,Addr,data);
  end;
  nDataCnt := 1;
  SetLength(arRData,nDataCnt);
  arrData[0] := data;
  sTxData := Format(' 0x%0.2x',[arrData[0]]);
//  sDebug := Format('I2C WRITE: DevAddr(0x%0.2x) RegAddr(0x%0.4x) DataCnt(%d), WaitSec(%d) Retry(%d) Data(%s)',
//                     [DEVICE_ADDRESS,Addr,nDataCnt, nWaitMS,nRetry, sTxData]);
//  Common.MLog(nChannel,sDebug);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nDataCnt, arrData, nWaitMS,0,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetReg NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      nRet:= Application.MessageBox('SendI2CWrite NG!!', 'Confirm', MB_OK + MB_ICONQUESTION);
//      if nRet = IDOK then Break;
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH2(nChannel);
  end;
  Result := nResult;
  {$ENDIF}
end;



function MyCB_TCONSetReg_3(nChannel , Addr : Integer; data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData,sGrayRGB : string;
arRData : TIdBytes;
nResult,i,nRet,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  {$IFDEF PG_AF9}
  PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
  Result := WAIT_OBJECT_0;
  {$ENDIF}
  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    CSharpDll.TconWriteAnalysis(nChannel,Addr,data);
  end;
  nDataCnt := 1;
  SetLength(arRData,nDataCnt);
  arrData[0] := data;
  sTxData := Format(' 0x%0.2x',[arrData[0]]);
//  sDebug := Format('I2C WRITE: DevAddr(0x%0.2x) RegAddr(0x%0.4x) DataCnt(%d), WaitSec(%d) Retry(%d) Data(%s)',
//                     [DEVICE_ADDRESS,Addr,nDataCnt, nWaitMS,nRetry, sTxData]);
//  Common.MLog(nChannel,sDebug);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nDataCnt, arrData, nWaitMS,0,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetReg NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      nRet:= Application.MessageBox('SendI2CWrite NG!!', 'Confirm', MB_OK + MB_ICONQUESTION);
//      if nRet = IDOK then Break;
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH3(nChannel);
  end;
  Result := nResult;
  {$ENDIF}
end;


function MyCB_TCONSetReg_4(nChannel , Addr : Integer; data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData,sGrayRGB : string;
arRData : TIdBytes;
nResult,i,nRet,nDebugLog: integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  {$IFDEF PG_AF9}
  PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
  Result := WAIT_OBJECT_0;
  {$ENDIF}
  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    CSharpDll.TconWriteAnalysis(nChannel,Addr,data);
  end;
  nDataCnt := 1;
  SetLength(arRData,nDataCnt);
  arrData[0] := data;
  sTxData := Format(' 0x%0.2x',[arrData[0]]);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nDataCnt, arrData, nWaitMS,0 ,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetReg NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      nRet:= Application.MessageBox('SendI2CWrite NG!!', 'Confirm', MB_OK + MB_ICONQUESTION);
//      if nRet = IDOK then Break;
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH4(nChannel);
  end;

//  nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nDataCnt, arrData, nWaitMS,nRetry);
//  if nResult <> WAIT_OBJECT_0  then  begin
//    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nDataCnt, arrData, nWaitMS,nRetry);
//    if nResult <> WAIT_OBJECT_0 then begin
//      sDebug := Format('TCONSetReg NG CH : %d',[nChannel]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH4(nChannel);
//    end;
//  end;
  Result := nResult;
  {$ENDIF}
end;

function MyCB_TCONSetRegArray_1(nChannel , Addr : Integer; const data : PByte; nLength : integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRData,nDataCnt);
  Move(data^, arRData[0], nLength);                                     

  nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegArray NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH1(nChannel);
    end;
  end;
  Result := nResult;

end;

function MyCB_TCONSetRegArray_2(nChannel , Addr : Integer; const data : PByte; nLength : integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRData,nDataCnt);
  Move(data^, arRData[0], nLength);

  nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegArray NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH2(nChannel);
    end;
  end;
  Result := nResult;
end;

function MyCB_TCONSetRegArray_3(nChannel , Addr : Integer; const  data : PByte; nLength : integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRData,nDataCnt);
  Move(data^, arRData[0], nLength);

  nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegArray NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH3(nChannel);
    end;
  end;
  Result := nResult;
end;

function MyCB_TCONSetRegArray_4(nChannel , Addr : Integer; const data : PByte; nLength : integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRData,nDataCnt);
  Move(data^, arRData[0],nLength);

  nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CWrite(DEVICE_ADDRESS,Addr,nLength, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegArray NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH4(nChannel);
    end;
  end;
  Result := nResult;
end;

function MyCB_TCONSetRegMultiWrite_1(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconMultiWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nDataCnt * SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegMultiWrite NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH1(nChannel);
    end;
  end;
//  Sleep(50); //2023-0926
  Result := nResult;
end;


function MyCB_TCONSetRegMultiWrite_2(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconMultiWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nLength*  SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegMultiWrite NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH2(nChannel);
    end;
  end;
//  Sleep(50); //2023-0926
  Result := nResult;
end;


function MyCB_TCONSetRegMultiWrite_3(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconMultiWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nLength*  SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegMultiWrite NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH3(nChannel);
    end;
  end;
//  Sleep(50); //2023-0926
  Result := nResult;
end;


function MyCB_TCONSetRegMultiWrite_4(nChannel,nType : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconMultiWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 200; //2023-04-08 (3000->100->200)
  nRetry  := 0;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nLength*  SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
  if nResult <> WAIT_OBJECT_0  then  begin
    nResult := Pg[nChannel].SendI2CMultiWrite(DEVICE_ADDRESS,nLength,arRAddr, arRData, nWaitMS,nRetry);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('TCONSetRegMultiWrite NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
      CSharpDll.MainOC_Stop_CH4(nChannel);
    end;
  end;
//  Sleep(50); //2023-0926
  Result := nResult;
end;

function MyCB_TCONSetRegSeqWrite_1(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult,nDebugLog : integer;
i : Integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall);

  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 3000; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nDataCnt * SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].DP860_SendTconSeqWrite(nMode,nSeqIdx,nLength,arRAddr, arRData, nWaitMS,0,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetRegSeqWrite NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetRegSeqWrite NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH1(nChannel);
  end;

  Result := nResult;
end;

function MyCB_TCONSetRegSeqWrite_2(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult,i,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 3000; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nDataCnt * SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].DP860_SendTconSeqWrite(nMode,nSeqIdx,nLength,arRAddr, arRData, nWaitMS,0,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetRegSeqWrite NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetRegSeqWrite NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH2(nChannel);
  end;
  Result := nResult;
end;

function MyCB_TCONSetRegSeqWrite_3(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult,i,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 3000; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nDataCnt * SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].DP860_SendTconSeqWrite(nMode,nSeqIdx,nLength,arRAddr, arRData, nWaitMS,0,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetRegSeqWrite NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetRegSeqWrite NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH3(nChannel);
  end;
  Result := nResult;
end;

function MyCB_TCONSetRegSeqWrite_4(nChannel,nMode,nSeqIdx : Integer; Addr : PINT; const data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
arRAddr : array of Integer;
nResult,i,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconWriteDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 3000; //2023-04-08 (3000->100->200)
  nRetry  := 2;   //2023-04-08 (0->3->0)

  nDataCnt := nLength;
  SetLength(arRAddr,nDataCnt);
  SetLength(arRData,nDataCnt);

  Move(Addr^, arRAddr[0],nDataCnt * SizeOf(Integer));
  Move(data^, arRData[0],nLength);

  for I := 0 to nRetry do begin
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].DP860_SendTconSeqWrite(nMode,nSeqIdx,nLength,arRAddr, arRData, nWaitMS,0,nDebugLog);
    if nResult <> WAIT_OBJECT_0 then begin
      Inc(PG[nChannel].TconRWCnt.TconRetryWriteCall);
//      sDebug := Format('TCONSetRegSeqWrite NG CH : %d Retry : %d',[nChannel,i + 1]);
//      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    end
    else begin
      Break;
    end;
  end;
  if nResult <> WAIT_OBJECT_0 then begin
    sDebug := Format('TCONSetRegSeqWrite NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH4(nChannel);
  end;
  Result := nResult;
end;





function MyCB_TCONGetReg_1(nChannel , Addr : Integer; var data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconReadDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := 1;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)
  data := 0;
  {$IFDEF PG_AF9}
  PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
  Result := WAIT_OBJECT_0;
  {$ENDIF}
  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  nDataCnt := 1;
//  sDebug := Format('I2C READ: DevAddr(0x%0.2x) RegAddr(0x%0.4x) DataCnt(%d), WaitMS(%d) Retry(%d) ',[DEVICE_ADDRESS,Addr,nDataCnt, nWaitMS,nRetry]);
//  Common.MLog(nChannel,sDebug);

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry},nDebugLog);
    if nResult = WAIT_OBJECT_0 then break
    else Inc(PG[nChannel].TconRWCnt.TconRetryReadCall);
  end;
  if nResult = WAIT_OBJECT_0 then
    data := arRData[0]
  else begin
    data := 0;
    sDebug := Format('TCONGetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH1(nChannel);
  end;
  Result := nResult;
//2023-03-28 Sleep(1);
//Sleep(5);
//Pg[nChannel].SetCyclicTimer(true{bEnable});
  {$ENDIF}
end;



function MyCB_TCONGetReg_2(nChannel , Addr : Integer; var data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconReadDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)
  nResult := 1;
  data := 0;
  {$IFDEF PG_AF9}
  PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
  Result := WAIT_OBJECT_0;
  {$ENDIF}
  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  nDataCnt := 1;
//  sDebug := Format('I2C READ: DevAddr(0x%0.2x) RegAddr(0x%0.4x) DataCnt(%d), WaitMS(%d) Retry(%d) ',[DEVICE_ADDRESS,Addr,nDataCnt, nWaitMS,nRetry]);
//  Common.MLog(nChannel,sDebug);

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry},nDebugLog);
    if nResult = WAIT_OBJECT_0 then break
    else Inc(PG[nChannel].TconRWCnt.TconRetryReadCall);
  end;
  if nResult = WAIT_OBJECT_0 then
    data := arRData[0]
  else begin
    data := 0;
    sDebug := Format('TCONGetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH2(nChannel);
  end;
  {$ENDIF}
  Result := nResult;
end;



function MyCB_TCONGetReg_3(nChannel , Addr : Integer; var data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconReadDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)
  nResult := 1;
  data := 0;
  {$IFDEF PG_AF9}
  PGAF9Fpga[nChannel].AF9_AllPowerOnOff(OnOff);  //OFF
  Result := WAIT_OBJECT_0;
  {$ENDIF}
  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  nDataCnt := 1;
//  sDebug := Format('I2C READ: DevAddr(0x%0.2x) RegAddr(0x%0.4x) DataCnt(%d), WaitMS(%d) Retry(%d) ',[DEVICE_ADDRESS,Addr,nDataCnt, nWaitMS,nRetry]);
//  Common.MLog(nChannel,sDebug);

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry},nDebugLog);
    if nResult = WAIT_OBJECT_0 then break
    else Inc(PG[nChannel].TconRWCnt.TconRetryReadCall);
  end;
  if nResult = WAIT_OBJECT_0 then
    data := arRData[0]
  else begin
    data := 0;
    sDebug := Format('TCONGetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH3(nChannel);
  end;
  {$ENDIF}
  Result := nResult;
end;



function MyCB_TCONGetReg_4(nChannel , Addr : Integer; var data : Byte): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult,nDebugLog : integer;
begin
  Inc(PG[nChannel].TconRWCnt.TconReadDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)
  nResult := 1;
  data := 0;

  {$IFDEF PG_DP860}
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  nDataCnt := 1;
//  sDebug := Format('I2C READ: DevAddr(0x%0.2x) RegAddr(0x%0.4x) DataCnt(%d), WaitMS(%d) Retry(%d) ',[DEVICE_ADDRESS,Addr,nDataCnt, nWaitMS,nRetry]);
//  Common.MLog(nChannel,sDebug);

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    if I = nRetry then
      nDebugLog := 1
    else
      nDebugLog := 0;
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry},nDebugLog);
    if nResult = WAIT_OBJECT_0 then break
    else Inc(PG[nChannel].TconRWCnt.TconRetryReadCall);
  end;
  if nResult = WAIT_OBJECT_0 then
    data := arRData[0]
  else begin
    data := 0;
    sDebug := Format('TCONGetReg NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH4(nChannel);
  end;
  {$ENDIF}
  Result := nResult;
end;


function MyCB_TCONGetRegArray_1(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult : integer;
begin
  Result := 0;
  Inc(PG[nChannel].TconRWCnt.TconReadArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)

  nDataCnt := nLength;

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry});
    if nResult = WAIT_OBJECT_0 then break;
  end;
  if nResult = WAIT_OBJECT_0 then
    CopyMemory(data,@arRData[0],nLength)
  else begin
    sDebug := Format('TCONGetRegArray NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH1(nChannel);
  end;
  Result := nResult;
end;

function MyCB_TCONGetRegArray_2(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult : integer;
begin
  Result := 0;
  Inc(PG[nChannel].TconRWCnt.TconReadArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)

  nDataCnt := nLength;

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry});
    if nResult = WAIT_OBJECT_0 then break;
  end;
  if nResult = WAIT_OBJECT_0 then
    CopyMemory(data,@arRData[0],nLength)
  else begin
    sDebug := Format('TCONGetRegArray NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH2(nChannel);
  end;
  Result := nResult;
end;

function MyCB_TCONGetRegArray_3(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult : integer;
begin
  Result := 0;
  Inc(PG[nChannel].TconRWCnt.TconReadArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)

  nDataCnt := nLength;

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry});
    if nResult = WAIT_OBJECT_0 then break;
  end;
  if nResult = WAIT_OBJECT_0 then
    CopyMemory(data,@arRData[0],nLength)
  else begin
    sDebug := Format('TCONGetRegArray NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH3(nChannel);
  end;
  Result := nResult;
end;


function MyCB_TCONGetRegArray_4(nChannel,Addr : Integer; data : PByte; nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
i : Integer;
nResult : integer;
begin
  Result := 0;
  Inc(PG[nChannel].TconRWCnt.TconReadArrayDllCall); //2023-03-28 jhhwang (for T/T Test)
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nWaitMS := 100; //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (500->100)
  nRetry  := 2;   //2023-03-28 jhhwang (for T/T Test) //2023-04-08 (1->2)

  nDataCnt := nLength;

  SetLength(arRData,nDataCnt);
  for i := 0 to nRetry do begin //2023-04-07 retry at here (RxParsingErr)
    nResult := Pg[nChannel].SendI2CRead(DEVICE_ADDRESS,Addr,nDataCnt,arRData, nWaitMS,0{nRetry});
    if nResult = WAIT_OBJECT_0 then break;
  end;
  if nResult = WAIT_OBJECT_0 then
    CopyMemory(data,@arRData[0],nLength)
  else begin
    sDebug := Format('TCONGetRegArray NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH4(nChannel);
  end;
  Result := nResult;
end;



function MyCB_FlashWrite_File_1(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := EndSeg - StartSeg;
  Result := 0;
end;

function MyCB_FlashWrite_File_2(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;

function MyCB_FlashWrite_File_3(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;

function MyCB_FlashWrite_File_4(nChannel,StartSeg,EndSeg : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;

function MyCB_FlashWrite_Data_1(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data); //TBD:ITOLED?
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashWrite_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH1(nChannel);
    end;
  end;
  Result := nResult;
end;

function MyCB_FlashWrite_Data_2(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data); //TBD:ITOLED?
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashWrite_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH2(nChannel);
    end;
  end;
  Result := nResult;
end;

function MyCB_FlashWrite_Data_3(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data); //TBD:ITOLED?
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashWrite_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH3(nChannel);
    end;
  end;
  Result := nResult;
end;

function MyCB_FlashWrite_Data_4(nChannel,StartSeg,nLength : Integer; const data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data); //TBD:ITOLED?
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashWrite(StartSeg,nLength, data);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashWrite_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH4(nChannel);
    end;
  end;
  Result := nResult;
end;

function MyCB_FlashRead_File_1(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;

function MyCB_FlashRead_File_2(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;

function MyCB_FlashRead_File_3(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;

function MyCB_FlashRead_File_4(nChannel,StartSeg,nLength : Integer; filePath : PAnsiChar): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  Result := 0;
end;


function MyCB_FlashRead_Data_1(nChannel,nStartSeg,nLength : Integer; data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashRead_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH1(nChannel);
    end;
  end;
  CopyMemory(data,@Logic[nChannel].m_FlashAllData.Data[0],nLength);
  Result := nResult;

//Pg[nChannel].SetCyclicTimer(true{bEnable});
end;

function MyCB_FlashRead_Data_2(nChannel,nStartSeg,nLength  : Integer; data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashRead_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH2(nChannel);
    end;
  end;
  CopyMemory(data,@Logic[nChannel].m_FlashAllData.Data[0],nLength);
  Result := nResult;

//Pg[nChannel].SetCyclicTimer(true{bEnable});
end;

function MyCB_FlashRead_Data_3(nChannel,nStartSeg,nLength  : Integer; data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashRead_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH3(nChannel);
    end;
  end;
  CopyMemory(data,@Logic[nChannel].m_FlashAllData.Data[0],nLength);
  Result := nResult;

//Pg[nChannel].SetCyclicTimer(true{bEnable});
end;

function MyCB_FlashRead_Data_4(nChannel,nStartSeg,nLength  : Integer; data: PByte): Integer;
var
 sDebug : string;
 nResult : integer;
begin
//Pg[nChannel].SetCyclicTimer(False{bEnable});
  CSharpDll.m_nFlagCount[nChannel] := 0;
  nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
  if nResult <> WAIT_OBJECT_0 then begin
    nResult := Pg[nChannel].SendFlashRead(nStartSeg,nLength,@Logic[nChannel].m_FlashAllData.Data[0]);
    if nResult <> WAIT_OBJECT_0 then begin
      sDebug := Format('FlashRead_Data NG CH : %d',[nChannel]);
      CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
//      CSharpDll.MainOC_Stop_CH4(nChannel);
    end;
  end;
  CopyMemory(data,@Logic[nChannel].m_FlashAllData.Data[0],nLength);
  Result := nResult;

//Pg[nChannel].SetCyclicTimer(true{bEnable});
end;


function MyCB_FlashErase_1(nChannel,nStartSeg,nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  sDebug := Format('Flash Erase:  StartSeg(0x%0.4x) Length(%d)',[nStartSeg,nLength]);
//  Common.MLog(nChannel,sDebug);
  Result := Pg[nChannel].DP860_SendNvmErase(nStartSeg,nLength);

end;

function MyCB_FlashErase_2(nChannel,nStartSeg,nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  sDebug := Format('Flash Erase:  StartSeg(0x%0.4x) Length(%d)',[nStartSeg,nLength]);
//  Common.MLog(nChannel,sDebug);
  Result := Pg[nChannel].DP860_SendNvmErase(nStartSeg,nLength);

end;

function MyCB_FlashErase_3(nChannel,nStartSeg,nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  sDebug := Format('Flash Erase:  StartSeg(0x%0.4x) Length(%d)',[nStartSeg,nLength]);
//  Common.MLog(nChannel,sDebug);
  Result := Pg[nChannel].DP860_SendNvmErase(nStartSeg,nLength);

end;

function MyCB_FlashErase_4(nChannel,nStartSeg,nLength : Integer): Integer;
var
nWaitMS,nRetry,nDataCnt : Integer;
sDebug,sTxData : string;
arRData : TIdBytes;
begin
  nDataCnt := 1;
  sDebug := Format('Flash Erase:  StartSeg(0x%0.4x) Length(%d)',[nStartSeg,nLength]);
//  Common.MLog(nChannel,sDebug);
  Result := Pg[nChannel].DP860_SendNvmErase(nStartSeg,nLength);

end;



function MyCB_GetWaveformData_1(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
var
i,j : Integer;
waveform,Data : array of Double;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  SetLength(waveform,nMeasureAmount);
  SetLength(Data,nMeasureAmount);
//    sDebug := Format('MyCB_GetWaveformData: Length(%d)',[nMeasureAmount]);
//    Common.MLog(nChannel,sDebug);

  result := CaSdk2.GetWaveformData(nChannel,@waveform[0],@Data[0] ,nMeasureAmount);
  CopyMemory(waveform_T,@waveform[0],nMeasureAmount*sizeof(waveform[0]));
  CopyMemory(waveformData,@Data[0],nMeasureAmount*sizeof(waveform[0]));

end;
function MyCB_GetWaveformData_2(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
var
i,j : Integer;
waveform,Data : array of Double;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  SetLength(waveform,nMeasureAmount);
  SetLength(Data,nMeasureAmount);

  result := CaSdk2.GetWaveformData(nChannel,@waveform[0],@Data[0] ,nMeasureAmount);
  CopyMemory(waveform_T,@waveform[0],nMeasureAmount*sizeof(waveform[0]));
  CopyMemory(waveformData,@Data[0],nMeasureAmount*sizeof(waveform[0]));
end;
function MyCB_GetWaveformData_3(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
var
i,j : Integer;
waveform,Data : array of Double;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  SetLength(waveform,nMeasureAmount);
  SetLength(Data,nMeasureAmount);

  result := CaSdk2.GetWaveformData(nChannel,@waveform[0],@Data[0] ,nMeasureAmount);
  CopyMemory(waveform_T,@waveform[0],nMeasureAmount*sizeof(waveform[0]));
  CopyMemory(waveformData,@Data[0],nMeasureAmount*sizeof(waveform[0]));
end;
function MyCB_GetWaveformData_4(nChannel : Integer; var waveform_T: Pdouble; var  waveformData : Pdouble; nMeasureAmount : Integer): Double;
var
i,j : Integer;
waveform,Data : array of Double;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  SetLength(waveform,nMeasureAmount);
  SetLength(Data,nMeasureAmount);

  result := CaSdk2.GetWaveformData(nChannel,@waveform[0],@Data[0] ,nMeasureAmount);
  CopyMemory(waveform_T,@waveform[0],nMeasureAmount*sizeof(waveform[0]));
  CopyMemory(waveformData,@Data[0],nMeasureAmount*sizeof(waveform[0]));
end;

function MyCB_measure_XYL_1(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;
var
i,wdRet: Integer;
m_Ca410Data  : TBrightValue;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  if Common.SystemInfo.PG_GpioReadHpdBeforeMeasure then begin //2023-03-30 jhhwang (for T/T Test)
    PG[nChannel].DP860_SendGpioRead('HPD');
  end;
  PG[nChannel].TconRWCnt.ContTConOcWrite := 0; //2023-03-30 jhhwang (for T/T Test)

  wdRet := CaSdk2.Measure(nChannel,m_Ca410Data);

  if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    sDebug := format('<CA410> Measure_XYL : Ca410Data x : %f y : %f LV : %f',[m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
  end;
  if wdRet <> WAIT_OBJECT_0 then begin
    sDebug := Format('CA410 measure NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH1(nChannel);
  end;

  t5[0] := m_Ca410Data.xVal;
  t5[1] := m_Ca410Data.yVal;
  t5[2] := m_Ca410Data.LvVal;
  Result := wdRet;

end;
function MyCB_measure_XYL_2(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;
var
i,wdRet: Integer;
m_Ca410Data  : TBrightValue;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  if Common.SystemInfo.PG_GpioReadHpdBeforeMeasure then begin //2023-03-30 jhhwang (for T/T Test)
    PG[nChannel].DP860_SendGpioRead('HPD');
  end;
  PG[nChannel].TconRWCnt.ContTConOcWrite := 0; //2023-03-30 jhhwang (for T/T Test)
//  sDebug :='measure_XYL';
//  Common.MLog(nChannel,sDebug);
  wdRet := CaSdk2.Measure(nChannel,m_Ca410Data);

  if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    sDebug := format('<CA410> Measure_XYL : Ca410Data x : %f y : %f LV : %f',[m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
  end;
  if wdRet <> WAIT_OBJECT_0 then begin
    sDebug := Format('CA410 measure NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH2(nChannel);
  end;


  t5[0] := m_Ca410Data.xVal;
  t5[1] := m_Ca410Data.yVal;
  t5[2] := m_Ca410Data.LvVal;
  Result := wdRet;
end;

function MyCB_measure_XYL_3(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;
var
i,wdRet: Integer;
m_Ca410Data  : TBrightValue;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  if Common.SystemInfo.PG_GpioReadHpdBeforeMeasure then begin //2023-03-30 jhhwang (for T/T Test)
    PG[nChannel].DP860_SendGpioRead('HPD');
  end;
  PG[nChannel].TconRWCnt.ContTConOcWrite := 0; //2023-03-30 jhhwang (for T/T Test)

  wdRet := CaSdk2.Measure(nChannel,m_Ca410Data);

    if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    sDebug := format('<CA410> Measure_XYL : Ca410Data x : %f y : %f LV : %f',[m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
  end;
    if wdRet <> WAIT_OBJECT_0 then begin
    sDebug := Format('CA410 measure NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH3(nChannel);
  end;

  t5[0] := m_Ca410Data.xVal;
  t5[1] := m_Ca410Data.yVal;
  t5[2] := m_Ca410Data.LvVal;
  Result := wdRet;
end;

function MyCB_measure_XYL_4(nChannel:Integer; var t5 : TArray<double>; var nLen : Integer): Integer;
var
i,wdRet: Integer;
m_Ca410Data  : TBrightValue;
sDebug : string;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  if Common.SystemInfo.PG_GpioReadHpdBeforeMeasure then begin //2023-03-30 jhhwang (for T/T Test)
    PG[nChannel].DP860_SendGpioRead('HPD');
  end;
  PG[nChannel].TconRWCnt.ContTConOcWrite := 0; //2023-03-30 jhhwang (for T/T Test)

  wdRet := CaSdk2.Measure(nChannel,m_Ca410Data);

    if (Common.SystemInfo.DebugLogLevelConfig > 0) then begin
    sDebug := format('<CA410> Measure_XYL : Ca410Data x : %f y : %f LV : %f',[m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
  end;
    if wdRet <> WAIT_OBJECT_0 then begin
    sDebug := Format('CA410 measure NG CH : %d',[nChannel]);
    CSharpDll.SendTestGuiDisplay(nChannel,defCommon.MSG_MODE_WORKING,sDebug,0);
    CSharpDll.MainOC_Stop_CH4(nChannel);
  end;

  t5[0] := m_Ca410Data.xVal;
  t5[1] := m_Ca410Data.yVal;
  t5[2] := m_Ca410Data.LvVal;
  Result := wdRet;
end;

function MyCB_SetSync_1(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
var
i : Integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  Result := CaSdk2.SetSyncMode(nChannel,CA_SyncMode,CA_Hz,0);
end;
function MyCB_SetSync_2(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
var
i : Integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  Result := CaSdk2.SetSyncMode(nChannel,CA_SyncMode,CA_Hz,0);
end;
function MyCB_SetSync_3(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
var
i : Integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  Result := CaSdk2.SetSyncMode(nChannel,CA_SyncMode,CA_Hz,0);
end;
function MyCB_SetSync_4(nChannel,CA_SyncMode,CA_Hz,channel_num : Integer): Integer ;
var
i : Integer;
begin
  CSharpDll.m_nFlagCount[nChannel] := 0;
  Result := CaSdk2.SetSyncMode(nChannel,CA_SyncMode,CA_Hz,0);
end;

procedure TCSharpDll.SendTestGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiDLL;
begin
  GuiData.MsgType := defCommon.MSG_TYPE_DLL;
  GuiData.Channel := nCh;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam := nParam;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_TestHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TCSharpDll.SendMainGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiDLL;
begin
  GuiData.MsgType := MSG_TYPE_NONE;
  GuiData.Channel := nCh;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam := nParam;
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
  regex := TRegEx.Create('\d+');
  match := regex.Match(inputString);

  // 추출된 숫자를 모두 결합하여 반환
  Result := '';
  while match.Success do
  begin
    Result := Result + match.Value;
    match := match.NextMatch;
  end;
end;

procedure TCSharpDll.MLOG(nChannel_Index : Integer; bClear : Boolean; sMLOG : string);
var
  th : TThread;
  sLog : string;
  nParam : integer;
begin
  if bClear then nParam := 10
  else nParam := 0;
  if pos('Delay_Time',sMLOG) > 0 then begin
    sLog := ExtractNumbersFromString(sMLOG);

    SendTestGuiDisplay(nChannel_Index,defCommon.MSG_MODE_DELAY_TIME,sLog,nParam);
    Exit;
  end;
  if Pos('[cnt]',sMLOG) >0 then
    inc(m_CountInspections[nChannel_Index]);

  SendTestGuiDisplay(nChannel_Index,defCommon.MSG_MODE_WORKING,sMLOG,nParam);
end;

procedure MyCB_TextChanged_1(channel_Index : Integer; bClear : Boolean; sAddedText : PAnsiChar);cdecl;
begin
  CSharpDll.m_nFlagCount[channel_Index] := 0;
  CSharpDll.MLOG(channel_Index,bClear,(PAnsiChar(sAddedText)));
end;
procedure MyCB_TextChanged_2(channel_Index : Integer; bClear : Boolean; sAddedText : PAnsiChar);cdecl;
begin
  CSharpDll.m_nFlagCount[channel_Index] := 0;
  CSharpDll.MLOG(channel_Index,bClear,(PAnsiChar(sAddedText)));
end;
procedure MyCB_TextChanged_3(channel_Index : Integer; bClear : Boolean; sAddedText : PAnsiChar);cdecl;
begin
  CSharpDll.m_nFlagCount[channel_Index] := 0;
  CSharpDll.MLOG(channel_Index,bClear,(PAnsiChar(sAddedText)));
end;
procedure MyCB_TextChanged_4(channel_Index : Integer; bClear : Boolean; sAddedText : PAnsiChar);cdecl;
begin
  CSharpDll.m_nFlagCount[channel_Index] := 0;
  CSharpDll.MLOG(channel_Index,bClear,(PAnsiChar(sAddedText)));
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
    sVer := PAnsiChar(m_GetOCversion); // DLL Ver 정보 API 함수 호출
    SendMainGuiDisplay(0,MSG_TYPE_DLL,sVer,1); // DLL Ver 정보 MAIN 전달
    if @m_GetOCConverterVersion <> nil then
      sVer := PAnsiChar(m_GetOCConverterVersion)
    else sVer := '';
    SendMainGuiDisplay(0,MSG_TYPE_DLL,sVer,2);

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

    end;
  finally
  end;
end;

function TCSharpDll.MainOC_GetOCFlowIsAlive(nCH : Integer): Integer;
begin
  Result := m_MainOC_IsAlive(nCH);
end;

function TCSharpDll.MainOC_GetSummaryLogData(nCH : Integer; sParameter : string): string;
begin
  try
    Result := PAnsiChar(m_GetSummaryLogData(nCH,Common.StringToPAnsiChar(sParameter)));
  except
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,'GetSummaryLogData Error Occurrence!!',10);
    Result := PAnsiChar(m_GetSummaryLogData(nCH,Common.StringToPAnsiChar(sParameter)));
  end;
end;

function TCSharpDll.MainOC_ChangeDLL(sDLLName : string): Integer;
begin

  Result := 0;
end;



function TCSharpDll.MainOC_Start_CH1(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
var
sParameter : string;
sHWCID,sDebug : string;
sCrcData   : AnsiString;
dCheckSum: dword;
begin
  try
    sParameter := sPID + ',' + sSerialNumber + ',' + sUser_ID +',' + sEquipment;
    sHWCID := Pg[nCH].m_HWCID[1] + ',' + Pg[nCH].m_HWCID[0] + ',' + Pg[nCH].m_HWCID[2] + ',' + Pg[nCH].m_HWCID[3] + ',' + Pg[nCH].m_HWCID[4];
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sParameter,0);
//    sDebug := 'CPU Usage: ' + FormatFloat('0.00%', GetCpuUsage);
    sDebug := sDebug + #13#10 + 'Memory usage : ' + Format('%0.2f%%', [Common.GetMemoryUsagePercentage]);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sDebug,0);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_LOG_HWCID,sHWCID,0);
    m_bIsProcessDone[nCH] := False;
    m_sSerialNo[nCH] := sSerialNumber;
    m_CountInspections[nCH] := 0; //검사 횟수 초기화
    sCrcData := sParameter;
    dCheckSum := Common.crc16(sCrcData,Length(sParameter));
    if m_MainOC_START_CH1(nCH,Common.StringToPAnsiChar(sParameter),Length(sParameter),dCheckSum) <> 0 then
      Exit(2);
    m_OCFlowStart[nCH] := true;
    tmCheckOCAlive[nCH].Enabled := True;
    Result := 0;
  except
    Result := 2;
  end;

end;

function TCSharpDll.MainOC_Start_CH2(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
var
sParameter,sHWCID,sDebug : string;
sCrcData   : AnsiString;
dCheckSum: dword;
begin
  try
//    Pg[nCH].SetCyclicTimer(False{bEnable});
    sParameter := sPID + ',' + sSerialNumber + ',' + sUser_ID +',' + sEquipment;
    sHWCID := Pg[nCH].m_HWCID[1] + ',' + Pg[nCH].m_HWCID[0] + ',' + Pg[nCH].m_HWCID[2] + ',' + Pg[nCH].m_HWCID[3] + ',' + Pg[nCH].m_HWCID[4];
    m_bIsProcessDone[nCH] := False;
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sParameter,0);
    sDebug := 'Memory usage : ' + Format('%0.2f%%', [Common.GetMemoryUsagePercentage]);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sDebug,0);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_LOG_HWCID,sHWCID,0);
    m_sSerialNo[nCH] := sSerialNumber;
    m_CountInspections[nCH] := 0; //검사 횟수 초기화
    sCrcData := sParameter;
    dCheckSum := Common.crc16(sCrcData,Length(sParameter));
    if m_MainOC_START_CH2(nCH,Common.StringToPAnsiChar(sParameter),Length(sParameter),dCheckSum) <> 0 then
      Exit(2);
    m_OCFlowStart[nCH] := true;
    tmCheckOCAlive[nCH].Enabled := True;
    Result := 0;
  except
//    Pg[nCH].SetCyclicTimer(true{bEnable});
    Result := 2;
  end;
end;

function TCSharpDll.MainOC_Start_CH3(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
var
sParameter,sHWCID,sDebug : string;
sCrcData   : AnsiString;
dCheckSum: dword;
begin
  try
//    Pg[nCH].SetCyclicTimer(False{bEnable});
    sParameter := sPID + ',' + sSerialNumber + ',' + sUser_ID +',' + sEquipment;
    sHWCID := Pg[nCH].m_HWCID[1] + ',' + Pg[nCH].m_HWCID[0] + ',' + Pg[nCH].m_HWCID[2] + ',' + Pg[nCH].m_HWCID[3] + ',' + Pg[nCH].m_HWCID[4];    m_bIsProcessDone[nCH] := False;
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sParameter,0);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_LOG_HWCID,sHWCID,0);
    sDebug := 'Memory usage : ' + Format('%0.2f%%', [Common.GetMemoryUsagePercentage]);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sDebug,0);
    m_sSerialNo[nCH] := sSerialNumber;
    m_CountInspections[nCH] := 0; //검사 횟수 초기화
    sCrcData := sParameter;
    dCheckSum := Common.crc16(sCrcData,Length(sParameter));
    if m_MainOC_START_CH3(nCH,Common.StringToPAnsiChar(sParameter),Length(sParameter),dCheckSum) <> 0 then
      Exit(2);
    m_OCFlowStart[nCH] := true;
    tmCheckOCAlive[nCH].Enabled := True;
    Result := 0;
  except
//      Pg[nCH].SetCyclicTimer(true{bEnable});
    Result := 2;
  end;
end;

function TCSharpDll.MainOC_Start_CH4(nCH : Integer; sPID,sSerialNumber,sUser_ID,sEquipment : string): Integer;
var
sParameter,sHWCID,sDebug : string;
sCrcData   : AnsiString;
dCheckSum: dword;
begin
  try
//    Pg[nCH].SetCyclicTimer(False{bEnable});
    sParameter := sPID + ',' + sSerialNumber + ',' + sUser_ID +',' + sEquipment;
    sHWCID := Pg[nCH].m_HWCID[1] + ',' + Pg[nCH].m_HWCID[0] + ',' + Pg[nCH].m_HWCID[2] + ',' + Pg[nCH].m_HWCID[3] + ',' + Pg[nCH].m_HWCID[4];    m_bIsProcessDone[nCH] := False;
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sParameter,0);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_LOG_HWCID,sHWCID,0);
    sDebug := 'Memory usage : ' + Format('%0.2f%%', [Common.GetMemoryUsagePercentage]);
    SendTestGuiDisplay(nCH,defCommon.MSG_MODE_WORKING,sDebug,0);

    m_sSerialNo[nCH] := sSerialNumber;
    m_CountInspections[nCH] := 0; //검사 횟수 초기화
    sCrcData := sParameter;
    dCheckSum := Common.crc16(sCrcData,Length(sParameter));
    if m_MainOC_START_CH4(nCH,Common.StringToPAnsiChar(sParameter),Length(sParameter),dCheckSum) <> 0 then
      Exit(2);
    m_OCFlowStart[nCH] := true;
    tmCheckOCAlive[nCH].Enabled := True;
    Result := 0;
  except
//    Pg[nCH].SetCyclicTimer(true{bEnable});
    Result := 2;
  end;
end;

function TCSharpDll.MainOC_Stop_CH1(nCH : Integer): integer;
begin
   m_MainOC_STOP_CH1(nCH);
   Result := 0;
end;

function TCSharpDll.MainOC_Flash_Read(nCH : Integer): integer;
begin
m_MainOC_Flash_Read(nCH);
end;


function TCSharpDll.MainOC_Stop_CH2(nCH : Integer): integer;
begin
  m_MainOC_STOP_CH2(nCH);
  Result := 0;
end;

function TCSharpDll.MainOC_Stop_CH3(nCH : Integer): integer;
begin
  m_MainOC_STOP_CH3(nCH);
  Result := 0;
end;

function TCSharpDll.MainOC_Stop_CH4(nCH : Integer): integer;
begin
  m_MainOC_STOP_CH4(nCH);
  Result := 0;
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
    case i of
      DefCommon.CH1 : begin
        @CB_PowerOnOff[i] := @MyCB_AllPowerOnOff_1;
        @CB_TCONSetReg[i] := @MyCB_TCONSetReg_1;
        @CB_TCONGetReg[i] := @MyCB_TCONGetReg_1;
        @CB_FlashWrite_File[i] := @MyCB_FlashWrite_File_1;
        @CB_FlashWrite_Data[i] := @MyCB_FlashWrite_Data_1;
        @CB_FlashRead_File[i] := @MyCB_FlashRead_File_1;
        @CB_FlashRead_Data[i] := @MyCB_FlashRead_Data_1;
        @CB_FlashErase[i] := @MyCB_FlashErase_1;

        @CB_TCONSetRegArray[i] := @MyCB_TCONSetRegArray_1;
        @CB_TCONGetRegArray[i] := @MyCB_TCONGetRegArray_1;

        @CB_TCONMultiSetReg[i] := @MyCB_TCONSetRegMultiWrite_1;
        @CB_TCONSeqSetReg[i] := @MyCB_TCONSetRegSeqWrite_1;
        @CB_Measure_XYL[i] := @MyCB_measure_XYL_1;
        @CB_SetSync[i] := @MyCB_SetSync_1;
        @CB_GetWaveformData[i] := @MyCB_GetWaveformData_1;
        @CB_TextChanged[i] := @MyCB_TextChanged_1;

      end;
      DefCommon.CH2 : begin
        @CB_PowerOnOff[i] := @MyCB_AllPowerOnOff_2;
        @CB_TCONSetReg[i] := @MyCB_TCONSetReg_2;
        @CB_TCONGetReg[i] := @MyCB_TCONGetReg_2;
        @CB_FlashWrite_File[i] := @MyCB_FlashWrite_File_2;
        @CB_FlashWrite_Data[i] := @MyCB_FlashWrite_Data_2;
        @CB_FlashRead_File[i] := @MyCB_FlashRead_File_2;
        @CB_FlashRead_Data[i] := @MyCB_FlashRead_Data_2;
        @CB_FlashErase[i] := @MyCB_FlashErase_2;

        @CB_TCONSetRegArray[i] := @MyCB_TCONSetRegArray_2;
        @CB_TCONGetRegArray[i] := @MyCB_TCONGetRegArray_2;

        @CB_TCONMultiSetReg[i] := @MyCB_TCONSetRegMultiWrite_2;
        @CB_TCONSeqSetReg[i] := @MyCB_TCONSetRegSeqWrite_2;
        @CB_Measure_XYL[i] := @MyCB_measure_XYL_2;
        @CB_SetSync[i] := @MyCB_SetSync_2;
        @CB_GetWaveformData[i] := @MyCB_GetWaveformData_2;
        @CB_TextChanged[i] := @MyCB_TextChanged_2;

      end;
      DefCommon.CH3 : begin
        @CB_PowerOnOff[i] := @MyCB_AllPowerOnOff_3;

        @CB_TCONSetReg[i] := @MyCB_TCONSetReg_3;
        @CB_TCONGetReg[i] := @MyCB_TCONGetReg_3;
        @CB_FlashWrite_File[i] := @MyCB_FlashWrite_File_3;
        @CB_FlashWrite_Data[i] := @MyCB_FlashWrite_Data_3;
        @CB_FlashRead_File[i] := @MyCB_FlashRead_File_3;
        @CB_FlashRead_Data[i] := @MyCB_FlashRead_Data_3;
        @CB_FlashErase[i] := @MyCB_FlashErase_3;

        @CB_TCONSetRegArray[i] := @MyCB_TCONSetRegArray_3;
        @CB_TCONGetRegArray[i] := @MyCB_TCONGetRegArray_3;

        @CB_TCONMultiSetReg[i] := @MyCB_TCONSetRegMultiWrite_3;
        @CB_TCONSeqSetReg[i] := @MyCB_TCONSetRegSeqWrite_3;
        @CB_Measure_XYL[i] := @MyCB_measure_XYL_3;
        @CB_SetSync[i] := @MyCB_SetSync_3;
        @CB_GetWaveformData[i] := @MyCB_GetWaveformData_3;
        @CB_TextChanged[i] := @MyCB_TextChanged_3;

      end;
      DefCommon.CH4 : begin
        @CB_PowerOnOff[i] := @MyCB_AllPowerOnOff_4;

        @CB_TCONSetReg[i] := @MyCB_TCONSetReg_4;
        @CB_TCONGetReg[i] := @MyCB_TCONGetReg_4;
        @CB_FlashWrite_File[i] := @MyCB_FlashWrite_File_4;
        @CB_FlashWrite_Data[i] := @MyCB_FlashWrite_Data_4;
        @CB_FlashRead_File[i] := @MyCB_FlashRead_File_4;
        @CB_FlashRead_Data[i] := @MyCB_FlashRead_Data_4;
        @CB_FlashErase[i] := @MyCB_FlashErase_4;

        @CB_TCONSetRegArray[i] := @MyCB_TCONSetRegArray_4;
        @CB_TCONGetRegArray[i] := @MyCB_TCONGetRegArray_4;

        @CB_TCONMultiSetReg[i] := @MyCB_TCONSetRegMultiWrite_4;
        @CB_TCONSeqSetReg[i] := @MyCB_TCONSetRegSeqWrite_4;
        @CB_Measure_XYL[i] := @MyCB_measure_XYL_4;
        @CB_SetSync[i] := @MyCB_SetSync_4;
        @CB_GetWaveformData[i] := @MyCB_GetWaveformData_4;
        @CB_TextChanged[i] := @MyCB_TextChanged_4;

      end;
    end;

  end;
//  CsharpDll.Initialize_TEST;
end;




procedure TCSharpDll.Setfunction;
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
  @m_MainOC_START_CH1 :=  GetProcAddress(m_hDll,'MainOC_START_CH1');
  @m_MainOC_START_CH2 :=  GetProcAddress(m_hDll,'MainOC_START_CH2');
  @m_MainOC_START_CH3 :=  GetProcAddress(m_hDll,'MainOC_START_CH3');
  @m_MainOC_START_CH4 :=  GetProcAddress(m_hDll,'MainOC_START_CH4');
  @m_MainOC_STOP_CH1 :=  GetProcAddress(m_hDll,'MainOC_STOP_CH1');
  @m_MainOC_STOP_CH2 :=  GetProcAddress(m_hDll,'MainOC_STOP_CH2');
  @m_MainOC_STOP_CH3 :=  GetProcAddress(m_hDll,'MainOC_STOP_CH3');
  @m_MainOC_STOP_CH4 :=  GetProcAddress(m_hDll,'MainOC_STOP_CH4');
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

end;

procedure TCSharpDll.SetNgMsg(const Value: string);
begin
  FNgMsg := Value;
end;



end.
