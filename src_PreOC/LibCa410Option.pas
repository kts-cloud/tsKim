unit LibCa410Option;
// CA410 관련 Library 함수 모음.

interface

uses
  Winapi.Windows,Winapi.Messages, System.Classes, System.SysUtils , Ca_SDK2, LibCommFuncs,DefCommon,DefGmes;

type

  PGuiLibCa410 = ^RGuiLibCa410;
  RGuiLibCa410 = packed record
    MsgType : Integer;
    Channel	: Integer;
    MsgMode : Integer;
    nParam  : Integer;
    bError  : Boolean;
    Msg     : string;
  end;

  TCalValue = packed record
    W_X : single;
    W_Y : single;
    W_Z : single;
    W_xx : single;
    W_yy : single;
    W_Lv : single;

    R_X : single;
    R_Y : single;
    R_Z : single;
    R_xx : single;
    R_yy : single;
    R_Lv : single;

    G_X : single;
    G_Y : single;
    G_Z : single;
    G_xx : single;
    G_yy : single;
    G_Lv : single;

    B_X : single;
    B_Y : single;
    B_Z : single;
    B_xx : single;
    B_yy : single;
    B_Lv : single;

    procedure init();
  end;
  PstCd  = ^TStCD;
  TStCD  = packed record
    Read    : PAnsiChar;
    write_1 : PAnsiChar;
    write_2 : PAnsiChar;
    write_3 : PAnsiChar;
    write_4 : PAnsiChar;
    write_5 : PAnsiChar;
    write_6 : PAnsiChar;
  end;

  TControlCa410 = class(TObject)

  private

    FhDllR2R       : THandle;
    //FCLgdLogicDll_CD_Read : function (pMemCh : Pointer; pProbe : Pointer; pMode : Pointer;  CDCal2 : TCalvalue ; pRead : Pointer ; var stRW2 : TStCD ) : Integer; cdecl;
    FCDCal: TCalValue;
    FCurMemoryCh : Integer;
    procedure SetFunction;
    procedure SetCDCal(const Value: TCalValue);

    procedure ShowTestForm(nMode, nCh: Integer; bError: Boolean; sMsg: string; nParam : Integer = 1);

  public
    FhMain, FhTest : HWND;
    constructor Create(hMain, hTest : HWND; nCurMemCh : Integer); virtual;
    destructor Destroy; override;
    function TestExample(nCh,nCurMemoryCh : Integer;var sMsg : string): string;
    procedure RunR2R;
    procedure ReadR2R(nCh,nCurMemoryCh : Integer;var sMsg : string);
    procedure writeR2R(var sRet :string);
    function PlayR2RProcess(nCh ,nMemoryCh, nProbe, nMode : Integer; sCdr : string): string;
    procedure SetCa410Command(nCh : Integer; sCmd: string; var nRet : Integer; var sRet, sLog : string);
    property CDCal : TCalValue read FCDCal write SetCDCal;
  end;


var
  CtrlCa410 : TControlCa410;

implementation
uses
Mainter;


{ TControlCa410 }

constructor TControlCa410.Create(hMain, hTest : HWND; nCurMemCh : Integer);
var
  sNgMsg : string;
begin
  if LibCommonFunc = nil then begin
    // 현장 상황에 맞게 지워도 상관 없음.
    LibCommonFunc := TLibCommonFunc.Create;
  end;

  FhMain := hMain;
  FhTest := hTest;
//  if CaSdk2 = nil then begin
//    // IT OLED 예제 Sampe - Type값이 MSG_TYPE_CA410 = 15로 설정되 잇어 15로 표시함.
//    // 현장 상황에 맞게 지워도 상관 없음.
//    CaSdk2 := TCA_SDK2.Create(15,hMain, nTest, nCurMemCh,1) ;
//  end;
  FCurMemoryCh := nCurMemCh;
  //LibCommonFunc.LoadDllFilePathName(FhDllR2R,'\driver\win32\OC_dll_Calypso.dll', sNgMsg);
end;

destructor TControlCa410.Destroy;
begin
  FreeLibrary(FhDllR2R);
  if LibCommonFunc <> nil then begin
    // 현장 상황에 맞게 지워도 상관 없음.
    LibCommonFunc.Free;
    LibCommonFunc := nil;
  end;
  inherited;
end;

procedure TControlCa410.ShowTestForm(nMode, nCh: Integer; bError: Boolean; sMsg: string; nParam: Integer);
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

  SendMessage(FhTest ,WM_COPYDATA,0, LongInt(@ccd));
end;


function TControlCa410.PlayR2RProcess(nCh,nMemoryCh, nProbe, nMode : Integer; sCdr : string): string;
var
  sCmd, sRet : string;
  stlTemp :  TStringList;
  i, nRet : Integer;
  sTemp1, sTemp2 : string;
begin
  Result := '';
  sCmd := Format('AppDllCaller.exe %d %d %0.2d',[nMemoryCh, nProbe, nMode]);   // 'AppDllCaller.exe 7 1 02';
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_X]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_Y]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_Z]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_xx]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_yy]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_Lv]);

  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_X]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_Y]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_Z]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_xx]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_yy]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_Lv]);

  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_X]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_Y]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_Z]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_xx]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_yy]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_Lv]);

  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_X]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_Y]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_Z]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_xx]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_yy]);
  sCmd := sCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_Lv]);
  sCmd := sCmd + ' ' + sCdr;
  LibCommonFunc.RunCommandOrder(sCmd,sRet);
  //FCLgdLogicDll_CD_Read(pMemch, pProbe, pMode, CDCal, PtrRead, stRw );

  stlTemp :=  TStringList.Create;

  try
    ExtractStrings([#10, #13], [], PWideChar(sRet), stlTemp);
    for i := 0 to Pred(stlTemp.Count) do begin
      ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,'#'+i.ToString+' '+Trim(stlTemp[i]));
      ShowTestForm(DefGmes.R2R_LOG,nCh,False,'#'+i.ToString+' '+Trim(stlTemp[i]));
      SetCa410Command(nCh, stlTemp[i],nRet,sTemp1,sTemp2);
      Result := Result + sTemp1 + ',';
    end;

  finally
    stlTemp.Free;
  end;


end;

procedure TControlCa410.ReadR2R(nCh,nCurMemoryCh : Integer;var sMsg : string);
var
  nRet : Integer;
  sCmd,slog : string;
begin
  try
    if not CaSdk2.m_bConnection[nCh] then  Exit;

    sLog := 'ReadR2R - START' + Format('nCurMemoryCh : %d DeviceId : %d',[nCurMemoryCh,CaSdk2.m_DeviceInfo[nCh].DeviceId]);
    ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sLog);
    sCmd := Format('CDR,%d,%d',[nCurMemoryCh,1]);
    Self.SetCa410Command(nCh,sCmd,nRet,sMsg,slog);
  finally

  end;
end;

procedure TControlCa410.RunR2R;
begin

end;

procedure TControlCa410.SetCa410Command(nCh : Integer; sCmd: string; var nRet: Integer; var sRet, sLog : string);
var
  pCmd, pRetMsg : PAnsiChar;
  sRetErr, sTemp : string;
  wdRet : DWORD;
  slData : TStringList;
begin
  try
    sLog := '';   sRet := '';
    pRetMsg := AllocMem(1000);
    wdRet := 0;
    if wdRet = 0 then begin
      pCmd := PAnsiChar(Ansistring(sCmd));
      wdRet := CaSdk2.SetCommandCa410(nCh,pCmd,pRetMsg);
      sRetErr := StrPas(pRetMsg);
      sLog := 'CA410 Set Command ('+ sCmd + '): ' + sRetErr;
      sLog := StringReplace(sLog,#$0a, '', [rfReplaceAll]);
      sLog := StringReplace(sLog,#$0d, '', [rfReplaceAll]);
      ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sLog);
      ShowTestForm(DefGmes.R2R_LOG,nCh,False,sLog);
      sRet := sRetErr;
      if wdRet <> 0 then begin
        sLog := sLog + Format(' (NG Code: %d)',[wdRet]);
        ShowTestForm(DefCommon.MSG_MODE_WORKING,nCh,False,sLog);
        ShowTestForm(DefGmes.R2R_LOG,nCh,False,sLog);
      end;
      nRet := 0;
      slData := TStringList.Create;
      try
        ExtractStrings([','], [], PWideChar(sRetErr), slData);
        if slData.Count > 1 then begin
          sTemp := slData[1];
          nRet := StrToIntDef(sTemp,0);
        end;
      finally
        slData.Free;
      end;
    end;
  finally
    FreeMem(pRetMsg) ;
  end;
end;

procedure TControlCa410.SetCDCal(const Value: TCalValue);
begin
  FCDCal := Value;
end;

procedure TControlCa410.SetFunction;
begin
//  @FCLgdLogicDll_CD_Read    := GetProcAddress(FhDllR2R, 'CD_Read');
end;

function TControlCa410.TestExample(nCh,nCurMemoryCh : Integer;var sMsg : string): string;
var
  nRet : Integer;
  sCmd,slog : string;
  asMsg: TArray<String>;
  MyClass: TObject;
begin
//  sCmd := Format('CDR,%d,%d',[nCurMemoryCh,CaSdk2.m_DeviceInfo[nCh].DeviceId]);

  try
    Result := '';
    if not CaSdk2.m_bConnection[nCh] then  Exit;
    sCmd := Format('CDR,%d,%d',[nCurMemoryCh,1]);
    Self.SetCa410Command(nCh,sCmd,nRet,sMsg,slog);
    Result := PlayR2RProcess(nCh,nCurMemoryCh,1,2,sMsg);

    sCmd := Format('CDR,%d,%d',[nCurMemoryCh,1]);
    Self.SetCa410Command(nCh,sCmd,nRet,sMsg,slog);

  except
    Result := '';
  end;
end;

procedure TControlCa410.writeR2R(var sRet: string);
begin

end;

{ TCalValue }

procedure TCalValue.init;
begin
  W_X := 0;
  W_Y := 0;
  W_Z := 0;
  W_xx := 0;
  W_yy := 0;
  W_Lv := 0;

  R_X := 0;
  R_Y := 0;
  R_Z := 0;
  R_xx := 0;
  R_yy := 0;
  R_Lv := 0;

  G_X := 0;
  G_Y := 0;
  G_Z := 0;
  G_xx := 0;
  G_yy := 0;
  G_Lv := 0;

  B_X := 0;
  B_Y := 0;
  B_Z := 0;
  B_xx := 0;
  B_yy := 0;
  B_Lv := 0;
end;

end.
