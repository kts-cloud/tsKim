unit CA_SDK2;

{----------------------------------------------------------------
Copyrightⓒ 1999-2019 DONG A ELTEK CO.,LTD All rights reserved.
-----------------------------------------------------------------
File name : CA_SDK2.pas
작성자    : Clint
작성일    : 2019-03-11 오후 06:00:00
사용예제  :

Create.
    DongaCa210 := TDongaCa210.Create(1,3,'1234');
    DongaCa210.OnReadCa210 := ReadCa210Event; // ReadCa210Event ==> 사용자 임의 지정 함수. Ca210 결과값을 받으면 ReadCa210Event 함수로 데이터 전달.
Shot.
    nRet := CASDK2_SHOT(DefCa310.CA210_FLICK,'13'); // Channel 1,3 번 Flicker 측정. nRet : True면 이벤트 발생. False면 오류 리턴.

Side Effect :
수정 사항 :
-----------------------------------------------------------------}

interface
  uses
    System.SysUtils, Winapi.Windows, winapi.messages, Vcl.Dialogs, system.Classes, System.Math, DefCommon, IdGlobal;


const

  CA_SDK2_DLL = 'CASDK2_DAE.dll';

type
  CA_SDK2_Handle = THandle;

  TCallbackFunc = function : Integer;

  PTTEST = ^TTEST;
  TTEST = record
    a : PAnsiChar;
    b : PAnsiChar;
    c : PAnsiChar;
  end;

(****************************************************************************)
(*          CASDK2 Functions Declarations                                   *)
(****************************************************************************)
  function NewCaSdk2 : CA_SDK2_Handle ;cdecl;//stdcall;
  function DeleteCaSdk2(handel : CA_SDK2_Handle  ) : Integer ;cdecl;//stdcall;
  function SetConfigration(handel :  CA_SDK2_Handle) : Integer; cdecl;
  function GetDeviceCnt(handel :  CA_SDK2_Handle) : Integer; cdecl;
  function GetProbeInfo(nCh : Integer; var nPortNo; var SerialNo : PAnsiChar  ) : Integer ;cdecl;//stdcall;
  function GetDllVerInfo(var Version : PAnsiChar) : Integer ;cdecl;
//
  function CalZero(nCh : Integer ) : Integer ;cdecl;
  function set_Measure(nCh : Integer ) : Integer ;cdecl;
  function get_sXylvVal(nCh : Integer; var xVal, yVal, LvVal : Double ) : Integer ;cdecl;
  function get_sUvlvVal(nCh : Integer; var u, v, Lv : Double ) : Integer ;cdecl;
  function get_sXyUvlvVal(nCh : Integer; var x, y, u, v, Lv, dUv : Double ) : Integer ;cdecl;
  function GetErrorMessage(nErrCode : Integer ; ErrMessage : PWideChar ; var nSize ) : Integer ;cdecl;//stdcall;
  function set_AvrMode(nCh : Integer) : Integer ;cdecl;
//  function SetDisplayMode(nCh : Integer; nMode : Integer) : Integer ;cdecl;
  function set_SyncMode(nCh : Integer; nSync : Integer; dFrea : Double; nIntegTime : Integer ) : Integer ;cdecl;
  function set_DefaultConnect(nCh : Integer; nMemCh : Integer; nAutoMode : Integer ) : Integer ;cdecl;
  // for user calibration.
  function set_MemCh(nCh, nMemCh : Integer) : Integer ;cdecl;
  function get_MemCh(nCh : Integer; var nMemCh : Integer) : Integer; cdecl;
  function InitMemCh(nCh : Integer; nMemCh : Integer) : Integer; cdecl;

//  function set_LvxyCalMode(nCh : Integer) : Integer ;cdecl;
  function CalMeasure(nCh, nIdxRgb : Integer) : Integer ;cdecl;
  function SetLvxy_CalData(nCh,nIdxRgb : Integer; x, y, Lv : Double) : Integer ;cdecl;
  function MatrixCal_Update(nCh : Integer) : Integer ;cdecl;
//  function GetTargetData(nCh : Integer; Pid : PAnsiChar; var x : Double; var y : Double; var Lv : Double ) : Integer ;cdecl;
  function ResetLvCalMode(nCh : Integer) : Integer; cdecl;

  function fGetMemChData(nCh, nMemCh : Integer; var R_Lv, R_x, R_y, G_Lv, G_x, G_y, B_Lv, B_x, B_y, W_Lv, W_x, W_y : Double) : Integer; cdecl
  function UserCalReady(nCh, nTargetCh : Integer) : Integer; cdecl;
  function UserCalMeasure(nCh, iColorType : Integer;var x, y, Lv : Double) : Integer; cdecl;
//  function MemCh_Initial(nCh, nMemCh : Integer) : Integer ;cdecl;
  function VSync_CntSet( nCh, nFrame : Integer;  sRetMsg : PAnsiChar) : Integer; cdecl;
  function CA_SetCommand( nCh : Integer; sCmd ,  sRetMsg : PAnsiChar) : Integer; cdecl;

  function Get_waveformData(nChannel : integer; waveform_T, waveformData : PDouble; measureAmount : Integer): Double; cdecl;
  function Get_waveform_Data(nChannel : integer; waveform_T, waveformData : PDouble; waveformDataSize : Integer; measurementTime : Double): Double; cdecl;

  function Measure_waveform(nChannel,m_nSamplingNumber : integer) : integer; cdecl;
  function Get_waveformDataSize(nChannel,m_nSamplingNumber : integer) : DWORD;cdecl;

//  function DLLArrayTest(var buf : Pbyte) : Integer; cdecl;
//  function DLLArrayTest2(var buf : TTEST) : Integer; cdecl;
type
  ///	<summary>
  ///	  광학 측정 장비 CA310 관련 Define class
  ///	</summary>
  DefCaSdk  = class public
    const
      CONNECTION_NONE = 0;
      CONNECTION_OK   = 1;
      CONNECTION_NG   = 2;

      IDX_RED     = 0;
      IDX_GREEN   = 1;
      IDX_BLUE    = 2;
      IDX_WHITE   = 3;
      IDX_MAX     = 3;

      MAX_CH_CNT  = 4;
      MAX_CH      = MAX_CH_CNT;
      CA310_LvXY  = 0;
      CA310_FLICK = 6;
      CA310_JEITA = 8;

      DISCONNECTION_CODE = 10000;
  end;

  PSyncCa = ^RSyncCa;
  RSyncCa = packed record
    MsgType : Integer;
    Channel	: Integer;
    MsgMode : Integer;
    nParam  : Integer;
    bError  : Boolean;
    Msg     : string;
  end;

  TBrightValue = record
    xVal        : Double;
    yVal        : Double;
    LvVal       : Double;
    Flicker     : Double;
  end;

  TLvXYUV = record
    x       : Double;
    y       : Double;
    u       : Double;
    v       : Double;
    Lv      : Double;
    dUv     : Double;
    dXy     : Double;
  end;

  TLvXY = record
    x   : Double;
    y   : Double;
    Lv  : Double;
  end;
  TAllLvXy    = array[0 .. DefCaSdk.IDX_MAX] of TLvXY;

  TDeviceInfo = record
    DeviceId    : Integer;    // Usb connected but Serial Port Number (COM5) - Device ID.
    SerialNo    : string;
    DllVer      : string;
  end;

  TCaSetupInfo  = record
    SelectIdx : Integer;
    Ca410Ch   : Integer;
    DeviceId  : Integer;
    SerialNo  : string;
  end;

  TCaSetupInfoList = record
    SetupList :  array [0..pred(DefCaSdk.MAX_CH_CNT)] of TCaSetupInfo;
  end;




  TCA_SDK2 = class(TObject)
  private
    { Private declarations }
    m_hCaSdk2 : CA_SDK2_Handle;
    m_hMain, m_hTest   : HWND;
    FDeviceCount: Integer;
    m_nMemCh    : Integer;
    m_nAutoMode : Integer;
    FSetupCnt   : TCaSetupInfoList;
    procedure SetDeviceCount(const Value: Integer);
    function GetSetupPort(nIndex: Integer): TCaSetupInfo;
    procedure SetSetupPort(nIndex: Integer; const Value: TCaSetupInfo);
    procedure ShowMainForm(nMode, nCh: Integer; bError: Boolean; sMsg: string; nParam : Integer = 1);
    procedure ShowTestForm(nMode, nCh: Integer; bError: Boolean; sMsg: string; nParam : Integer = 1);
    procedure CheckConnect(nCh : Integer);
  public
    { Public declarations }
    m_DeviceInfo : array of  TDeviceInfo;
    m_bConnection : array[0 .. pred(DefCaSdk.MAX_CH_CNT)] of Boolean;
    m_bScriptWorking : array[0 .. pred(DefCaSdk.MAX_CH_CNT)] of Boolean;
    constructor Create(hMain, hTest : HWND; nMemCh : Integer; bAuto : Boolean); virtual;
    destructor Destroy; override;
    function ManualConnect: Integer;
    function Measure(nCh : Integer; var MeasRet : TBrightValue) : Integer;
    function MeasureAllData(nCh : Integer; var MeasRet : TLvXYUV) : Integer;
    function MeasureData(nCh : Integer; var MeasRet : TLvXYUV) : Integer;
    function GetMemCh(nCh : Integer; var nMemCh : Integer) : Integer;
    function SetMemCh(nCh : Integer; nMemCh : Integer) : Integer;
    function SetDefaultMemCh(nCh : Integer; nMemCh : Integer) : Integer;

    function GetMemInfo(nCh, nMemCh : Integer;var R_Lv, R_x, R_y, G_Lv, G_x, G_y, B_Lv, B_x, B_y, W_Lv, W_x, W_y : Double) : Integer;
    function UsrCalReady(nCh, nMemCh : Integer) : Integer;
    function UsrCalMeasure(nCh, nColorType : Integer;var x, y , lv : Double) : Integer;
    function UsrCalSetCalData(nCh, nColorType : Integer; tX, tY, tLv : Double) : Integer;
//    function setLvxyCalMode(nCh: Integer) : Integer;
//    function set_DisplayMode(nCh: Integer) : Integer;
    function set_CalZero(nCh: Integer) : Integer;
    function ResetCalMode(nCh : Integer) : Integer;
    function CasdkEnter(nCh : Integer) : Integer;

    function GetWaveformData(nChannel : integer; waveform_T, waveformData : PDouble; measureAmount : Integer): Double;
    function SetSyncMode(nCh : Integer; nSync : Integer; dFrea : Double; nIntegTime : Integer) : Integer ;

    function SetVsyncFrame(nCh, nFrame : Integer;var sRetMsg : PAnsiChar) : Integer;
    function SetCommandCa410(nCh : Integer;sCmd : PAnsiChar; var sRetMsg : PAnsiChar) : Integer;
    procedure TestDll;
    property DeviceCount : Integer read FDeviceCount write SetDeviceCount;
    property SetupPort[nIndex : Integer] : TCaSetupInfo read GetSetupPort write SetSetupPort;


  end;

var
  CaSdk2 : TCA_SDK2;

implementation

function NewCaSdk2;       external CA_SDK2_DLL;
function DeleteCaSdk2;    external CA_SDK2_DLL;
function SetConfigration; external CA_SDK2_DLL;
function GetDeviceCnt; external CA_SDK2_DLL;


function GetProbeInfo  ;  external CA_SDK2_DLL;
function GetDllVerInfo  ;  external CA_SDK2_DLL;

function CalZero  ;       external CA_SDK2_DLL;
function set_SyncMode  ;  external CA_SDK2_DLL;
function set_Measure  ;   external CA_SDK2_DLL;
function get_sXylvVal  ;  external CA_SDK2_DLL;
function get_sUvlvVal  ;  external CA_SDK2_DLL;
function get_sXyUvlvVal  ;  external CA_SDK2_DLL;

function GetErrorMessage; external CA_SDK2_DLL;
function set_AvrMode; external CA_SDK2_DLL;
//function SetDisplayMode; external CA_SDK2_DLL;
function set_DefaultConnect; external CA_SDK2_DLL;
// for user calibration.
function set_MemCh  ;  external CA_SDK2_DLL;
function get_MemCh  ;  external CA_SDK2_DLL;
function initMemCh  ; external CA_SDK2_DLL;
//function set_LvxyCalMode; external CA_SDK2_DLL;
function CalMeasure; external CA_SDK2_DLL;
function SetLvxy_CalData; external CA_SDK2_DLL;
function MatrixCal_Update; external CA_SDK2_DLL;
//function GetTargetData; external CA_SDK2_DLL;
function ResetLvCalMode; external CA_SDK2_DLL;

function fGetMemChData; external CA_SDK2_DLL;
function UserCalReady; external CA_SDK2_DLL;
function UserCalMeasure; external CA_SDK2_DLL;

function VSync_CntSet; external CA_SDK2_DLL;
function CA_SetCommand; external CA_SDK2_DLL;
//function DLLArrayTest; external CA_SDK2_DLL;
//function DLLArrayTest2; external CA_SDK2_DLL;
//function MemCh_Initial ; external CA_SDK2_DLL;

function Get_waveformData; external CA_SDK2_DLL;
function Get_waveform_Data; external CA_SDK2_DLL;

function Measure_waveform; external CA_SDK2_DLL;
function Get_waveformDataSize; external CA_SDK2_DLL;


{ TCA_SDK2 }
procedure TCA_SDK2.TestDll;
var
  data : TIdBytes;
  a : PByte;
  buf : TTEST;
  sData : string;
begin
//  SetLength(data,10);
//  data[0] := 10;
//  data[1] := 11;
//  data[2] := 12;
//  a := nil;
////  DLLArrayTest(PByte(data));   ==> 이걸로 하니깐 데이터 이상한걸로 들어옮.
//  DLLArrayTest(a);
//  CopyMemory(@data[0],a,8);
//  data[0] := 10;

 //DLLArrayTest2(buf);
 sData := StrPas(buf.a);
 sData := StrPas(buf.b);
 sData := StrPas(buf.c);
  ShowTestForm(DefCommon.MSG_MODE_WORKING,0,False,'OK');



end;

procedure TCA_SDK2.CheckConnect(nCh: Integer);
var
  nErr, nRet, nPort : integer;
  i, k, nGetMemCh: Integer;
  wdRet : DWORD;
  sErrMsg : string;
  bIsNg   : boolean;
  thCa    : TThread;
begin
  case FSetupCnt.SetupList[nCh].SelectIdx of
    DefCaSdk.CONNECTION_NONE : begin
      ShowMainForm(DefCommon.MSG_MODE_CA310_STATUS,nCh,False,sErrMsg,0) ;
      m_bConnection[nCh] := False;
    end
    else begin
      if FDeviceCount <> 0 then begin
        bIsNg := True;
        for i := 0 to Pred(FDeviceCount) do begin
          if m_DeviceInfo[i].SerialNo = FSetupCnt.SetupList[nCh].SerialNo then begin
            bIsNg := False;
            FSetupCnt.SetupList[nCh].Ca410Ch := i;
            break;
          end;
        end;
        if bIsNg then begin
          sErrMsg := Format('Cannel %d CA410 Connection NG',[nCh+1]);
          ShowMainForm(DefCommon.MSG_MODE_CA310_STATUS,nCh,True,sErrMsg);
          ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,True,sErrMsg);
          m_bConnection[nCh] := False;
        end
        else begin
          sErrMsg := '';
          ShowMainForm(DefCommon.MSG_MODE_CA310_STATUS,nCh,False,sErrMsg);
          sErrMsg := 'CA410 Connect OK';
          ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sErrMsg);
          m_bConnection[nCh] := True;

          // Init 쪽에 CA Command 추가하려니 Back ground와 출돌남. 피하기 위하여 순차적으로 하자.
          // In Case of ALL OK
//          thCa    := TThread.CreateAnonymousThread(procedure var k : Integer; begin
            // Script Log와 출동남 - 피하기 위하여 스크립트 끝나고 0 Cal

          thCa    := TThread.CreateAnonymousThread(procedure begin
//            for k := 0 to 300 do begin
//              sleep(100);
//              if not m_bScriptWorking[nCh] then break;
//            end;
            CalZero(FSetupCnt.SetupList[nCh].Ca410Ch);
            sErrMsg := 'CA410 ZeroCal';
            ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sErrMsg);
            set_DefaultConnect(FSetupCnt.SetupList[nCh].Ca410Ch,m_nMemCh,m_nAutoMode);
            sErrMsg := 'CA410 Default Set';
            ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sErrMsg);
            sErrMsg := 'CA410 Get Ca410 MemChannel.';
            ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sErrMsg);
            wdRet := CaSdk2.GetMemCh(nCh,nGetMemCh);
            if wdRet <> 0 then begin
              ShowTestForm(defCommon.MSG_MODE_CAX10_MEM_CH_NO,nCh,False,'MEM CH: NG',-1);
              sErrMsg := Format('Ca410 Memory Channel Read NG - NG Code :%0.2d',[wdRet]);
              ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sErrMsg);
              ShowMainForm(DefCommon.MSG_MODE_CA310_STATUS,nCh,True,sErrMsg);
            end
            else begin
              sErrMsg := Format('MEM CH:%0.2d',[nGetMemCh]);
//              ShowTestForm(defCommon.MSG_MODE_CAX10_MEM_CH_NO,nCh,False,sErrMsg);
              ShowTestForm(defCommon.MSG_MODE_CAX10_MEM_CH_NO,nCh,False, '' , nGetMemCh);
              sErrMsg := Format('Get CA410 MEM CH:%0.2d - OK',[nGetMemCh]);
              ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sErrMsg);
            end;

          end);
          thCa.Start;

//          end);
//          thCa.Start;
        end;
      end
      else begin
        sErrMsg := Format('Cannel %d CA410 Connection NG',[nCh+1]);
        ShowMainForm(DefCommon.MSG_MODE_CA310_STATUS,nCh,True,sErrMsg);
        ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,True,sErrMsg);
        m_bConnection[nCh] := False;
      end;
    end;
  end;
end;

constructor TCA_SDK2.Create(hMain, hTest: HWND; nMemCh : Integer; bAuto : Boolean);
var
  i: Integer;
  PVerInfo : PAnsiChar;
  sDebug : string;
begin

  m_hCaSdk2 := NewCaSdk2;
    m_nMemCh := nMemCh;
  //0: Slow, 1 : FAST MODE, 2 : LTD Auto. 3 : Auto
  if bAuto then begin
    m_nAutoMode := 2;
  end
  else begin
    m_nAutoMode := 2;
  end;

  FDeviceCount := 0;
  for i := 0 to Pred(DefCaSdk.MAX_CH) do begin
    m_bConnection[i] := False;
  end;
  m_hMain :=  hMain;
  m_hTest := hTest;

  GetDllVerInfo(PVerInfo);
  sDebug := 'CA DLL Version : '+StrPas(PVerInfo);
  for i := 0 to Pred(DefCaSdk.MAX_CH) do ShowTestForm(DefCommon.MSG_MODE_WORKING,i,False,sDebug);

end;

destructor TCA_SDK2.Destroy;
var
  i: Integer;
begin

  for i := 0 to Pred(FDeviceCount) do begin
    m_DeviceInfo[i].DeviceId := 0;
    m_DeviceInfo[i].SerialNo := '';
  end;
  SetLength(m_DeviceInfo,0);
  DeleteCaSdk2(m_hCaSdk2);
  inherited;
end;

function TCA_SDK2.GetMemCh(nCh: Integer; var nMemCh: Integer): Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);

  Result := get_MemCh(FSetupCnt.SetupList[nCh].Ca410Ch,nMemCh);
end;

function TCA_SDK2.GetWaveformData(nChannel : integer; waveform_T, waveformData : PDouble; measureAmount : Integer): Double;
var
  waveformDataSize : DWORD;
  SamplingPitch,measurementTime : Double;
  i : Integer;
  weightedWaveformData : array of Double;
begin

  if not m_bConnection[nChannel] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Measure_waveform(FsetupCnt.SetupList[nChannel].Ca410Ch,measureAmount);
  waveformDataSize := Get_waveformDataSize(FsetupCnt.SetupList[nChannel].Ca410Ch,measureAmount);
  Setlength(weightedWaveformData,waveformDataSize);

  measurementTime := 0;
  measurementTime := Get_waveform_Data(FsetupCnt.SetupList[nChannel].Ca410Ch,waveformData,@weightedWaveformData[0],waveformDataSize,measurementTime);
  SamplingPitch := measurementTime / waveformDataSize;

  for I := 0 to waveformDataSize -1  do
  begin
    waveform_T^ := SamplingPitch * i;
    if i <> waveformDataSize -1 then
      inc(waveform_T);
  end;

  Result := measurementTime;

end;



//function TCA_SDK2.setLvxyCalMode(nCh: Integer): Integer;
//begin
//  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
//  Result := set_LvxyCalMode(FSetupCnt.SetupList[nCh].Ca410Ch);
//end;


//function TCA_SDK2.set_DisplayMode(nCh: Integer): Integer;
//begin
//  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
//  Result := SetDisplayMode(FSetupCnt.SetupList[nCh].Ca410Ch,0);
//end;

function TCA_SDK2.set_CalZero(nCh: Integer): Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := CalZero(FSetupCnt.SetupList[nCh].Ca410Ch);
end;


function TCA_SDK2.SetVsyncFrame(nCh, nFrame : Integer;var sRetMsg : PAnsiChar) : Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);

  Result := VSync_CntSet(FSetupCnt.SetupList[nCh].Ca410Ch,nFrame,sRetMsg);
end;

function TCA_SDK2.SetCommandCa410(nCh : Integer;sCmd : PAnsiChar; var sRetMsg : PAnsiChar) : Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);

  Result := CA_SetCommand(FSetupCnt.SetupList[nCh].Ca410Ch,sCmd,sRetMsg);
end;


function TCA_SDK2.ResetCalMode(nCh: Integer): Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := ResetLvCalMode(FSetupCnt.SetupList[nCh].Ca410Ch);
end;


function TCA_SDK2.CasdkEnter(nCh: Integer): Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := MatrixCal_Update(FSetupCnt.SetupList[nCh].Ca410Ch);
end;


function TCA_SDK2.GetSetupPort(nIndex: Integer): TCaSetupInfo;
begin
  Result := FSetupCnt.SetupList[nIndex];
end;

function TCA_SDK2.ManualConnect: Integer;
var
  nErr, nRet, nPort : integer;
  i, nCh: Integer;
  pSerialNo : PAnsiChar;
  sErrMsg : string;
  bIsNg   : boolean;
begin
  nErr :=  SetConfigration(m_hCaSdk2);
  FDeviceCount :=  GetDeviceCnt(m_hCaSdk2);
  if FDeviceCount > 0 then begin
    SetLength(m_DeviceInfo,FDeviceCount);
    for i := 0 to Pred(FDeviceCount) do begin
      nPort := 0;
      nRet := GetProbeInfo(i,nPort, pSerialNo);
      m_DeviceInfo[i].DeviceId := nPort;
      m_DeviceInfo[i].SerialNo := StrPas(pSerialNo);
//      FreeMem(pSerialNo);
    end;
  end;

  // Connection Error 처리.
  for nCh := 0 to Pred(defCaSdk.MAX_CH_CNT) do begin
    CheckConnect(nCh);
  end;

  Result := nErr;;
end;

function TCA_SDK2.Measure(nCh : Integer; var MeasRet : TBrightValue): Integer;
var
  nRet : Integer;
  dX, dY, dLv : Double;
  sErrMsg : string;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  // CA Driver Channel : 0 ~ 1, But  SelectIdx includes 'NONE' so, 1 ~ 2
  nRet := set_Measure(FSetupCnt.SetupList[nCh].Ca410Ch);
  if nRet = 0 then begin
    nRet := get_sXylvVal(FSetupCnt.SetupList[nCh].Ca410Ch, dX, dY, dLv);
    MeasRet.xVal   :=  dX;
    MeasRet.yVal   :=  dY;
    MeasRet.LvVal  :=  dLv;
  end
  else begin
    sErrMsg := Format('Ca410 Measure NG - NG Code :%0.2d',[nRet]);  // Measure Error 발생 시 Error code 확인
    ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sErrMsg);
    MeasRet.xVal   :=  0.0;
    MeasRet.yVal   :=  0.0;
    MeasRet.LvVal  :=  0.0;
  end;
  Result := nRet;
end;

function TCA_SDK2.MeasureAllData(nCh : Integer; var MeasRet : TLvXYUV): Integer;
var
  nRet : Integer;
  dU, dV,  dX, dY, dLv : Double;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  // CA Driver Channel : 0 ~ 1, But  SelectIdx includes 'NONE' so, 1 ~ 2
  nRet := set_Measure(FSetupCnt.SetupList[nCh].Ca410Ch);
  if nRet = 0 then begin
    nRet := get_sUvlvVal(FSetupCnt.SetupList[nCh].Ca410Ch, dU, dV, dLv);
    MeasRet.u   :=  dU;
    MeasRet.v   :=  dV;
    nRet := get_sXylvVal(FSetupCnt.SetupList[nCh].Ca410Ch, dX, dY, dLv);
    MeasRet.x   :=  dX;
    MeasRet.y   :=  dY;
    MeasRet.Lv  :=  dLv;


  end
  else begin
    MeasRet.x   :=  0.0;
    MeasRet.y   :=  0.0;
    MeasRet.u   :=  0.0;
    MeasRet.v   :=  0.0;
    MeasRet.Lv  :=  0.0;
  end;
  Result := nRet;
end;


function TCA_SDK2.MeasureData(nCh : Integer; var MeasRet : TLvXYUV): Integer;
var
  nRet : Integer;
  dU, dV,  dX, dY, dLv, dUv : Double;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  // CA Driver Channel : 0 ~ 1, But  SelectIdx includes 'NONE' so, 1 ~ 2
  nRet := set_Measure(FSetupCnt.SetupList[nCh].Ca410Ch);
  if nRet = 0 then begin
    nRet := get_sXyUvlvVal(FSetupCnt.SetupList[nCh].Ca410Ch, dX, dY, dU, dV, dLv, dUv);
    MeasRet.u   :=  dU;
    MeasRet.v   :=  dV;
    MeasRet.x   :=  dX;
    MeasRet.y   :=  dY;
    MeasRet.Lv  :=  dLv;
    MeasRet.dUv :=  dUv;
  end
  else begin
    MeasRet.x   :=  0.0;
    MeasRet.y   :=  0.0;
    MeasRet.u   :=  0.0;
    MeasRet.v   :=  0.0;
    MeasRet.Lv  :=  0.0;
    MeasRet.dUv :=  0.0;
  end;
  Result := nRet;
end;





procedure TCA_SDK2.SetDeviceCount(const Value: Integer);
begin
  FDeviceCount := Value;
end;

function TCA_SDK2.GetMemInfo(nCh, nMemCh : Integer;var R_Lv, R_x, R_y, G_Lv, G_x, G_y, B_Lv, B_x, B_y, W_Lv, W_x, W_y : Double) : Integer;
var
  nRet : Integer;
begin

//nErr := fGetMemChData(nCh,nMemCh, rx, ry, rLv, gx, gy, gLv , bx, by, bLv , wx, wy, wLv);
  nRet := fGetMemChData(FSetupCnt.SetupList[nCh].Ca410Ch,nMemCh,R_Lv, R_x, R_y, G_Lv, G_x, G_y, B_Lv, B_x, B_y, W_Lv, W_x, W_y);

  Result := nRet;
end;

function TCA_SDK2.SetSyncMode(nCh : Integer; nSync : Integer; dFrea : Double; nIntegTime : Integer) : Integer ;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);

  Result := Set_SyncMode(nCh,nSync,dFrea,nIntegTime);
end;

function TCA_SDK2.UsrCalReady(nCh, nMemCh : Integer) : Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := UserCalReady(FSetupCnt.SetupList[nCh].Ca410Ch,nMemCh);
end;

function TCA_SDK2.UsrCalMeasure(nCh, nColorType : Integer;var x, y , lv : Double) : Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := UserCalMeasure(FSetupCnt.SetupList[nCh].Ca410Ch,nColorType,x, y , lv );
end;


function TCA_SDK2.UsrCalSetCalData(nCh, nColorType : Integer; tX, tY, tLv : Double) : Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := SetLvxy_CalData(FSetupCnt.SetupList[nCh].Ca410Ch,nColorType, tX, tY, tLv );
end;


function TCA_SDK2.SetMemCh(nCh, nMemCh: Integer): Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := set_MemCh(FSetupCnt.SetupList[nCh].Ca410Ch,nMemCh);
end;

function TCA_SDK2.SetDefaultMemCh(nCh : Integer; nMemCh : Integer) : Integer;
begin
  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
  Result := initMemCh(nCh,nMemCh);
end;



//function TCA_SDK2.init_MemCh(nCh, nMemCh: Integer): Integer;
//begin
//  if not m_bConnection[nCh] then Exit(DefCaSdk.DISCONNECTION_CODE);
//  Result := 0;//MemCh_Initial(FSetupCnt.SetupList[nCh].Ca410Ch,nMemCh);
//end;

procedure TCA_SDK2.SetSetupPort(nIndex: Integer; const Value: TCaSetupInfo);
begin
  FSetupCnt.SetupList[nIndex] := Value;
end;

procedure TCA_SDK2.ShowMainForm(nMode, nCh: Integer; bError: Boolean; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  HostUiMsg   : RSyncCa;
begin
  HostUiMsg.MsgType := DefCommon.MSG_TYPE_CA410;
  HostUiMsg.MsgMode := nMode;
  HostUiMsg.Channel	:= nCh;
  HostUiMsg.bError  := bError;
  HostUiMsg.nParam  := nParam;
  HostUiMsg.Msg     := sMsg;
  ccd.dwData        :=   0;
  ccd.cbData        := SizeOf(HostUiMsg);
  ccd.lpData        := @HostUiMsg;

  SendMessage(m_hMain ,WM_COPYDATA,0, LongInt(@ccd));
end;


procedure TCA_SDK2.ShowTestForm(nMode, nCh: Integer; bError: Boolean; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  HostUiMsg   : RSyncCa;
begin
  HostUiMsg.MsgType := DefCommon.MSG_TYPE_CA410;
  HostUiMsg.MsgMode := nMode;
  HostUiMsg.Channel	:= nCh;
  HostUiMsg.bError  := bError;
  HostUiMsg.nParam  := nParam;
  HostUiMsg.Msg     := sMsg;
  ccd.dwData        :=   0;
  ccd.cbData        := SizeOf(HostUiMsg);
  ccd.lpData        := @HostUiMsg;

  SendMessage(m_hTest ,WM_COPYDATA,0, LongInt(@ccd));
end;

end.
