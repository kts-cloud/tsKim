unit MainControlEtc;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Win.Registry, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzButton, Vcl.ExtCtrls, TILed, DioDisplayAlarm, NgRatioDetail, Vcl.StdCtrls, RzStatus;

const
  TEST_MSG_NONE        = 1000;
  TEST_MSG_CONNECT     = TEST_MSG_NONE + 1;
  TEST_MSG_HEARTBEAT   = TEST_MSG_NONE + 2;

type
  InTestEvent = procedure( nTemp : Integer; sGetData : String) of object;

  PGuiTest  = ^RGuiTest;
  RGuiTest = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param1  : Integer;
    Msg     : string;
  end;

  TfrmMainControlEtc = class(TForm)
    btn64AlgorithmDll: TRzBitBtn;
    TILed1: TTILed;
    RzBitBtn1: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    RzBitBtn3: TRzBitBtn;
    Memo1: TMemo;
    RzBitBtn4: TRzBitBtn;
    RzBitBtn5: TRzBitBtn;
    RzBitBtn6: TRzBitBtn;
    RzProgressStatus1: TRzProgressStatus;
    procedure btn64AlgorithmDllClick(Sender: TObject);
    procedure RzBitBtn1Click(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
    procedure RzBitBtn3Click(Sender: TObject);
    procedure RzBitBtn4Click(Sender: TObject);
    procedure RzBitBtn5Click(Sender: TObject);
    procedure RzBitBtn6Click(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
  private
    { Private declarations }
    procedure SetReg(sPath, sKey, sValue: string);
    procedure TestThread(nParam : Integer);
    procedure OnEvntMain( nTemp : Integer; sGetData : string);
  public
    { Public declarations }
  end;

  TTestClass = class(TObject)

  private
    m_nMsgType : Integer;
    m_hMain    : HWND;
    FOnTestEvent: InTestEvent;
    procedure SetOnTestEvent(const Value: InTestEvent);
    procedure DisplayMainGui(nMsgType, nMode, nParam : Integer; sMsg : string);
    procedure InternalTest(nParam : Integer; sMsg : string);
  public
    procedure TestA;
    Procedure TestB;
    Procedure TestC;
    constructor Create(hMain :HWND; nMsgType : Integer); virtual;
    destructor Destroy; override;
    property OnTestEvent : InTestEvent read FOnTestEvent write SetOnTestEvent;
  end;

var
  frmMainControlEtc: TfrmMainControlEtc;

implementation

{$R *.dfm}

procedure TfrmMainControlEtc.btn64AlgorithmDllClick(Sender: TObject);
begin
//  SetReg(
end;

procedure TfrmMainControlEtc.OnEvntMain(nTemp: Integer; sGetData: string);
var
  sDebug : string;
  nMode : Integer;
begin
  nMode := 10;
  sDebug := Format('Mode : %d / Param : %d ',[nMode,nTemp]) + sGetData;
  Memo1.Lines.Add(sDebug);
  frmMainControlEtc.RzProgressStatus1.Percent := nTemp*10;
end;

procedure TfrmMainControlEtc.RzBitBtn1Click(Sender: TObject);
var
  m_naDioAlarmData : array of Integer;
  i : Integer;
begin
  SetLength(m_naDioAlarmData,8);
  for i := 0 to 7 do m_naDioAlarmData[i] := 0;
  m_naDioAlarmData[0] := 2;
  m_naDioAlarmData[4] := 7;

  if Assigned(frmDisplayAlarm) = False then  frmDisplayAlarm:= TfrmDisplayAlarm.Create(Self);
  frmDisplayAlarm.SetAlarmData(m_naDioAlarmData);
  //frmDisplayAlarm.Show;
  frmDisplayAlarm.ShowModal;
  frmDisplayAlarm.Free;
  frmDisplayAlarm:= nil;
end;

procedure TfrmMainControlEtc.RzBitBtn2Click(Sender: TObject);
begin
  frmNgRatioDetail := TfrmNgRatioDetail.Create(Self);
  //frmDisplayAlarm.Show;
  frmNgRatioDetail.ShowModal;
  frmNgRatioDetail.Free;
  frmNgRatioDetail:= nil;
end;

procedure TfrmMainControlEtc.RzBitBtn3Click(Sender: TObject);
var
  i: Integer;
  nCount: Integer;
  sValue: String;
  nTick: Cardinal;
begin
  nCount:= 1000000;
  Memo1.Lines.Clear;
  nTick:= GetTickCount;
  for i := 0 to nCount do begin
    sValue:= format('%d', [i]);
  end;
  Memo1.Lines.Add(format('format Elaps: %s: %d', [sValue, GetTickCount- nTick]));
  Memo1.Lines.Add(format('format GetTickCount %d, nTick : %d', [GetTickCount,nTick]));

  nTick:= GetTickCount;
  for i := 0 to nCount do begin
    sValue:= IntToStr(i);
  end;
  Memo1.Lines.Add(format('IntToStr Elaps: %s: %d', [sValue, GetTickCount- nTick]));
  Memo1.Lines.Add(format('IntToStr GetTickCount %d, nTick : %d', [GetTickCount,nTick]));

end;

procedure TfrmMainControlEtc.RzBitBtn4Click(Sender: TObject);
begin

  TestThread(0);
end;

procedure TfrmMainControlEtc.RzBitBtn5Click(Sender: TObject);
begin
  TestThread(1);
end;

procedure TfrmMainControlEtc.RzBitBtn6Click(Sender: TObject);
begin
  TestThread(2);
end;

procedure TfrmMainControlEtc.SetReg(sPath, sKey, sValue: string);
var
  R: TRegistry;
begin
  R := TRegistry.Create;
  try
    if not R.OpenKey(sPath, True) then
      RaiseLastOSError;
    R.WriteString(sKey, sValue);
  finally
    R.Free;
  end;

end;
procedure TfrmMainControlEtc.TestThread(nParam: Integer);
var
  TestClass : TTestClass;
begin
  try
    TestClass := TTestClass.Create(self.Handle,10);
    case nParam of
      0 : TestClass.TestA;
      1 : begin
        TestClass.OnTestEvent := OnEvntMain;
        TestClass.TestB;
      end;
      2 : TestClass.TestC;
    end;
  finally
    TestClass.free;
    TestClass := nil;
  end;
end;

procedure TfrmMainControlEtc.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, nTemp : Integer;
  sMsg, sSubMsg, sFileName, sDebug : string;
  sCsvHeader : array [0..2] of string;
  sCsvData : string;
begin
  nType := PGuiTest(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := PGuiTest(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
  case nType of
    10 : begin
      nMode := PGuiTest(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiTest(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp := PGuiTest(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      sDebug := Format('Mode : %d / Param : %d ',[nMode,nTemp]) + sMsg;
      Memo1.Lines.Add(sDebug);
      RzProgressStatus1.Percent := nTemp*10;
    end;
  end;
end;

{procedure TForm3.InsertToRegBtnClick(Sender: TObject);
var
  reg        : TRegistry;
  openResult : Boolean;
  today      : TDateTime;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := HKEY_LOCAL_MACHINE;

  if (not reg.KeyExists('Software\MyCompanyName\MyApplication\')) then
    begin
      MessageDlg('Key not found! Created now.',
					        mtInformation, mbOKCancel, 0);
    end;
  reg.Access := KEY_WRITE;
  openResult := reg.OpenKey('Software\MyCompanyName\MyApplication\',True);

  if not openResult = True then
    begin
      MessageDlg('Unable to create key! Exiting.',
                  mtError, mbOKCancel, 0);
      Exit();
    end;

//  { Checking if the values exist and inserting when neccesary }
//
//  if not reg.KeyExists('Creation\ Date') then
//    begin
//      today := Now;
//  		reg.WriteDateTime('Creation\ Date', today);
//    end;
//
//  if not reg.KeyExists('Licenced\ To') then
//    begin
//  		reg.WriteString('Licenced\ To', 'MySurname\ MyFirstName');
//    end;
//
//  if not reg.KeyExists('App\ Location') then
//    begin
//  		reg.WriteExpandString('App\ Location',
//                            '%PROGRAMFILES%\MyCompanyName\MyApplication\');
//    end;
//
//  if not reg.KeyExists('Projects\ Location') then
//    begin
//  		reg.WriteExpandString('Projects\ Location',
//                            '%USERPROFILE%\MyApplication\Projects\');
//    end;
//
//  reg.CloseKey();
//  reg.Free;
//
//end;
//
//procedure TForm3.DeleteFromRegBtnClick(Sender: TObject);
//var
//  reg : TRegistry;
//begin
//  reg := TRegistry.Create(KEY_WRITE);
//  reg.RootKey := HKEY_LOCAL_MACHINE;
//
//  reg.DeleteKey('Software\MyCompanyName\MyApplication');
//  reg.DeleteKey('Software\MyCompanyName');
//
//  reg.CloseKey();
//  reg.Free;
//
//end;}
{ TTestClass }

constructor TTestClass.Create(hMain: HWND; nMsgType: Integer);
begin
  m_nMsgType := nMsgType;
  m_hMain    := hMain;
end;

destructor TTestClass.Destroy;
begin

  inherited;
end;

procedure TTestClass.DisplayMainGui(nMsgType,nMode, nParam: Integer; sMsg: string);
var
  ccd         : TCopyDataStruct;
  GuiTestData :  RGuiTest;
begin

  GuiTestData.MsgType := nMsgType;
  GuiTestData.Channel := 0;
  GuiTestData.Mode    := nMode;
  GuiTestData.Param1  := nParam;
  GuiTestData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiTestData);
  ccd.lpData      := @GuiTestData;
  SendMessage(m_hMain,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TTestClass.InternalTest(nParam: Integer; sMsg: string);
var
  sDebug : string;
  nMode : Integer;
begin
  nMode := 10;
  sDebug := Format('Mode : %d / Param : %d ',[nMode,nParam]) + sMsg;
  frmMainControlEtc.Memo1.Lines.Add(sDebug);
  frmMainControlEtc.RzProgressStatus1.Percent := nParam;
end;

procedure TTestClass.SetOnTestEvent(const Value: InTestEvent);
begin
  FOnTestEvent := Value;
end;

procedure TTestClass.TestA;
var
  th : TThread;
begin
  th := TThread.CreateAnonymousThread( procedure
  var
    i: Integer;
  begin
    sleep(100);
    for i := 0 to 10 do begin
      DisplayMainGui(10,TEST_MSG_CONNECT,i,'TEST1');
      sleep(1000);
    end;

    sleep(100);
  end);
  th.Start;

end;

procedure TTestClass.TestB;
var
  th : TThread;
begin
  th := TThread.CreateAnonymousThread( procedure
  var
    i: Integer;
  begin
    sleep(100);
    for i := 0 to 10 do begin
      OnTestEvent(i,'TEST2');
      sleep(1000);
    end;

//    DisplayMainGui(TEST_MSG_CONNECT,2,'TEST1');
    sleep(100);
  end);
  th.Start;
end;

procedure TTestClass.TestC;
var
  th : TThread;
begin
  th := TThread.CreateAnonymousThread( procedure
  var
    i: Integer;
  begin
    sleep(100);
    for i := 0 to 10 do begin
      InternalTest(i*10,'TEST3');
      sleep(1000);
    end;
    sleep(100);
  end);
  th.Start;
end;

end.
