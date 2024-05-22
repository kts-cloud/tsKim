unit Main_L;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, RzButton, TILed, DefCommon, ScriptClass,
  ALed, System.ImageList, Vcl.ImgList, DefDio, AXDioLib, CommonClass, GMesCom, UdpServerClient, HandBCR,
  Vcl.Themes, LogicVh, Test_L, RzStatus, ModelSelect, ModelDownload, LogIn, ModelInfo, System.DateUtils,
  SystemSetup, UserID, NGMsg, DefGmes, SwitchBtn, DIO_ADLINK, pasScriptClass;
{$I Common.inc}
type
  RMainDio = record
    InDio : ADioStatus;
    OutDio : ADioStatus;
  end;
  TfrmMainL = class(TForm)
    ilFlag: TImageList;
    ilIMGMain: TImageList;
    pnlSysInfo: TRzPanel;
    RzGroupBox3: TRzGroupBox;
    RzPanel11: TRzPanel;
    pnlResolution: TRzPanel;
    pnlScriptVer: TRzPanel;
    RzPanel18: TRzPanel;
    RzPanel12: TRzPanel;
    pnlPatternGroup: TRzPanel;
    RzPanel2: TRzPanel;
    pnlCheckSum: TRzPanel;
    RzGroupBox4: TRzGroupBox;
    ledGmes: ThhALed;
    ledBcr1: ThhALed;
    ledSwJigA: ThhALed;
    RzPanel6: TRzPanel;
    pnlHost: TRzPanel;
    pnlBcr1: TRzPanel;
    pnlBcrStatus1: TRzPanel;
    pnlSwitch: TRzPanel;
    pnlSwA: TRzPanel;
    grpDioSig: TRzGroupBox;
    ledDioConnected: ThhALed;
    RzPanel17: TRzPanel;
    pnlDioStatus: TRzPanel;
    RzGroupBox1: TRzGroupBox;
    RzPanel1: TRzPanel;
    pnlUserId: TRzPanel;
    RzPanel4: TRzPanel;
    pnlEQPId: TRzPanel;
    RzPanel9: TRzPanel;
    pnlUserName: TRzPanel;
    btnMaintMsg: TRzBitBtn;
    tmAlarmMsg: TTimer;
    tmrDisplayTestForm: TTimer;
    tolGroupMain: TRzToolbar;
    btnModel: TRzToolButton;
    rzspcr8: TRzSpacer;
    btnExit: TRzToolButton;
    btnLogIn: TRzToolButton;
    rzspcr1: TRzSpacer;
    btnModelChange: TRzToolButton;
    rzspcr2: TRzSpacer;
    btnInit: TRzToolButton;
    RzSpacer1: TRzSpacer;
    RzSpacer2: TRzSpacer;
    RzSpacer3: TRzSpacer;
    RzSpacer4: TRzSpacer;
    btnSetup: TRzToolButton;
    btnMaint: TRzToolButton;
    pnlModelNameInfo: TPanel;
    RzStatusBar1: TRzStatusBar;
    RzResourceStatus1: TRzResourceStatus;
    RzClockStatus1: TRzClockStatus;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    RzKeyStatus1: TRzKeyStatus;
    grpADDioSig: TRzGroupBox;
    ledADDioConnected: ThhALed;
    RzPanel3: TRzPanel;
    pnlADDioStatus: TRzPanel;
    pnlStLocalIp: TRzStatusPane;
    RzStatusPane3: TRzStatusPane;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnLogInClick(Sender: TObject);
    procedure btnModelChangeClick(Sender: TObject);
    procedure btnModelClick(Sender: TObject);
    procedure btnMaintClick(Sender: TObject);
    procedure btnSetupClick(Sender: TObject);
    procedure btnInitClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure tmAlarmMsgTimer(Sender: TObject);
    procedure tmrDisplayTestFormTimer(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
  private
    { Private declarations }
//    frmTest4Ch     : array[.JIG_A .. DefPocb.JIG_B] of TfrmTest4Ch;
    ledDioIn, ledDioOut : array[0.. DefDio.MAX_IN_CNT] of  TTILed;
    ledADDioIn, ledADDioOut : array[0.. DefDio.MAX_ADLINK_IO_CNT] of  TTILed;
    m_bSensorIn : array[0.. DefDio.MAX_ADLINK_IO_CNT] of Boolean;
    m_ADDioEnable : Boolean;
    procedure ReadDioStatus(InDio, OutDio: ADioStatus);
    function CheckAdminPasswd : boolean;
    procedure initform;
    procedure InitAll;
    procedure DisplayScriptInfo;
//    function CheckDioAlarm : Boolean;
    procedure GetBcrConnStatus(bConnected : Boolean; sMsg : string);
    procedure CreateClassData;
    function  DisplayLogIn : Integer;
    procedure InitGmes;
    procedure ShowNgMessage(sMessage: string);
    function CheckPgRun : Boolean; // True : Run, False : Pg Stop.
    procedure InitMainTool(bEnable : Boolean);
    procedure OnMesMsg(nMsgType, nPg: Integer;bError : Boolean; sErrMsg : string);
    procedure MakeDioSig;
    procedure MainDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg: string);
    procedure MakeCsvData(var sHeader : string; var sData : string; nCh : Integer);
  public
  end;

var
  frmMainL: TfrmMainL;

implementation

uses
  Mainter;

{$R *.dfm}

{ TfrmMainLOptic }

procedure TfrmMainL.btnExitClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMainL.btnInitClick(Sender: TObject);
var
  sMsg : string;
begin
  sMsg :=        #13#10 + 'bạn có muốn khởi tạo chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to initialize this Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    InitAll;
  end;
end;

procedure TfrmMainL.btnLogInClick(Sender: TObject);
begin
  if CheckPgRun then Exit;

  if DisplayLogIn = mrCancel then Exit;

  if Common.m_sUserId = 'PM' then begin
    InitMainTool(True);
    if DongaGmes is TGmes then begin
      DongaGmes.Free;
      DongaGmes := nil;
    end;
    ledGmes.FalseColor := clGray;
    ledGmes.Value := False;
  end
  else begin
    InitMainTool(False);
    if DongaGmes is TGmes then begin
      DongaGmes.hMainHandle := frmTest_L.Handle;
      DongaGmes.MesUserId := Common.m_sUserId;
      if not DongaGmes.MesEayt then DongaGmes.SendHostUchk
      else                          DongaGmes.SendHostEayt;
    end
    else begin
      InitGmes;
      DongaGmes.hMainHandle := frmTest_L.Handle;
    end;
  end;
  pnlUserName.Caption   := '';
  pnlUserId.Caption     := Common.m_sUserId;
end;

procedure TfrmMainL.btnMaintClick(Sender: TObject);
begin
  if CheckAdminPasswd then begin
    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then TStyleManager.SetStyle('Windows10');
    frmMainter := TfrmMainter.Create(Application);
//    Common.Mlog('[PGM] Mainter Click!');
    try
      frmMainter.ShowModal;
    finally
      frmMainter.Free;
      frmMainter := nil;
    end;
    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then begin
      initform;
    end;
  end;
end;

procedure TfrmMainL.btnModelChangeClick(Sender: TObject);
var
  bChangeModel : Boolean;
begin
  if CheckPgRun then Exit;
  if not CheckAdminPasswd then Exit;
  frmSelectModel := TfrmSelectModel.Create(Self);
  try
    frmSelectModel.ShowModal;
  finally
    bChangeModel := frmSelectModel.m_bClickOkBtn;
    frmSelectModel.Free;
    frmSelectModel := nil;
  end;

  if bChangeModel then begin
//    tolGroupMain.Enabled := False;
    // Fusing model Data.

    Common.LoadModelInfo(Common.SystemInfo.TestModel);
    frmModelDownload := TfrmModelDownload.Create(Self);
    try
      frmModelDownload.ShowModal;
    finally
      frmModelDownload.Free;
      frmModelDownload := nil;
    end;
    Sleep(100);
    InitAll;
  end;
  DisplayScriptInfo;
end;

procedure TfrmMainL.btnModelClick(Sender: TObject);
begin
  if CheckAdminPasswd then begin
    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then TStyleManager.SetStyle('Windows10');

    frmModelInfo := TfrmModelInfo.Create(nil);
    try
      frmModelInfo.ShowModal;
    finally
      Freeandnil(frmModelInfo);
    end;
    if Common.m_bIsChanged or (Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR) then begin
      InitAll;
    end;

//    Common.LoadModelInfo(Common.SystemInfo.TestModel);
//    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then begin
//      initform;
////      Common.Delay(2000);
//    end;
//    DisplayScriptInfo;
  end;
end;

procedure TfrmMainL.btnSetupClick(Sender: TObject);
begin
  if CheckAdminPasswd then begin
    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then TStyleManager.SetStyle('Windows10');
    frmSystemSetup := TfrmSystemSetup.Create(Self);
    try
      frmSystemSetup.ShowModal;
    finally
      frmSystemSetup := nil;
      frmSystemSetup.Free;
    end;
    if Common.m_bIsChanged or (Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR) then begin
      InitAll;
    end;
//    initForm;
//    if frmTest4Ch <> nil then begin
//      frmTest4Ch.SetConfig;
//    end;
  end;
end;

function TfrmMainL.CheckAdminPasswd: boolean;
var
  bRet : boolean;
begin
  bRet := False;
  frmLogIn := TfrmLogIn.Create(Nil);
  try
    frmLogIn.Caption := 'Confirm Admin Password';
    if frmLogIn.ShowModal = mrOK then begin
      frmLogIn.Update;
      bRet := True;
    end;
  finally
    frmLogIn.Free;
    frmLogIn := nil;
  end;
  Result := bRet;
end;

function TfrmMainL.CheckPgRun: Boolean;
var
  i     : Integer;
  bRtn  : Boolean;
  sData : string;
begin
  bRtn := False;  sData := '';
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if pred(Common.SystemInfo.ChCountUsed) < i then break;
    if Logic[i] <> nil then begin
      if Logic[i].m_InsStatus = IsRun then begin
        bRtn  := True;
        if sData <> '' then begin
          sData := sData + Format(' ,%d',[i+1]);
        end
        else begin
          sData := sData + Format('%d',[i+1]);
        end;
      end;
    end;
  end;
  if bRtn then begin
    ShowMessage(sData + 'is working. please stop the PG.(PG đi vào hoạt động)');
  end;
  Result := bRtn;
end;

procedure TfrmMainL.CreateClassData;
begin
//  m_bTurnOnSkipSig := False;
//  m_bStartZone     := False;
  InitForm;
  // UDP 서버 IP 192.168.0.11
  // 내부적으로 Common file을 읽어 오기 대문에 반드시 Common Create 이후 호출.
  UdpServer := TUdpServerVh.Create(Self.Handle, DefCommon.MAX_PG_CNT);

  tmrDisplayTestForm.Enabled := True;

  Script := TScript.Create(Common.Path.MODEL + Common.SystemInfo.TestModel + '.script');//TScript.Create(Common.Path.MODEL + Common.SystemInfo.TestModel + '.script');
  DisplayScriptInfo;

  DongaHandBcr := TSerialBcr.Create(Self);
  DongaHandBcr.OnRevBcrConn := GetBcrConnStatus;
  DongaHandBcr.ChangePort(Common.SystemInfo.Com_HandBCR);

  pnlEQPId.Caption := Common.SystemInfo.EQPId;
end;

function TfrmMainL.DisplayLogIn: Integer;
var
  nRtn : Integer;
begin
  UserIdDlg := TUserIdDlg.Create(Application);
  try
    nRtn := UserIdDlg.ShowModal;
  finally
    UserIdDlg.Free;
  end;
	Result := nRtn;
end;

procedure TfrmMainL.DisplayScriptInfo;
begin
//  pnlScriptVer.Caption :=  Script.m_sScriptVer + ' / ' + Script.m_sScriptVerDate;
  pnlResolution.Caption := Format(' %d(H) x %d(V)',[Common.TestModelInfo.H_Active, Common.TestModelInfo.V_Active]);
  pnlPatternGroup.Caption :=  Common.TestModelInfo2.PatGrpName;
  pnlModelNameInfo.Caption := Common.SystemInfo.TestModel;

  pnlCheckSum.Caption  :=  Common.TestModelInfo2.CheckSum + '/'+ Common.SystemInfo.ScriptCrc;
  pnlScriptVer.Caption :=  Common.SystemInfo.ScriptVer;
end;

procedure TfrmMainL.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  sMsg : string;
  i : Integer;
begin
  sMsg := #13#10 + 'bạn có muốn thóat chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to Exit Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    if AxDio <> nil then begin
      for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
        AxDio.WriteDio(i,1); // All Off
        AxDio.WriteDio(i,0); // All Off
      end;
    end;
  {$IFDEF ADLINK_DIO}
    if AdLinkDio <> nil then begin
      AdLinkDio.Free;
      AdLinkDio := nil;
    end;
  {$ENDIF}
    if DongaHandBcr <> nil then begin
      DongaHandBcr.Free;
      DongaHandBcr := nil;
    end;

    if frmTest_L <> nil then begin
      frmTest_L.Free;
      frmTest_L := nil;
    end;

    if UdpServer <> nil then begin
      UdpServer.Free;
      UdpServer := nil;
    end;//FreeAndNil(UdpServer);
//
    if Script <> nil then begin //FreeAndNil(Script);
      Script.Free;
      Script := nil;
    end;

    // DIO Card 해제.
    if AxDio <> nil then begin
      AxDio.Free;
      AxDio := nil;
    end;

    if DongaGmes <> nil then begin
      DongaGmes.Free;
      DongaGmes := nil;
    end;

    if Common <> nil then begin
//      Common.TaskBar(False);
      Common.Free;
      Common := nil;
    end;
    Sleep(1000);

    CanClose := True;
  end
  else
    CanClose := False;
end;

procedure TfrmMainL.FormCreate(Sender: TObject);
var
  nRet : Integer;
begin
  Self.WindowState := wsNormal;
  Common := TCommon.Create;
  if Trim(Common.SystemInfo.ServicePort) <> '' then begin
    nRet := DisplayLogIn;
    if nRet = mrCancel then begin
      Application.ShowMainForm := False;
      Common.Free;
      Common := nil;
      Application.Terminate;
      Exit;
    end
    else begin
      if Common.m_sUserId = 'PM' then begin
        pnlHost.Caption := 'PM Mode';
        ledGmes.FalseColor := clGray;
        ledGmes.Value := False;
        pnlUserId.Caption := 'PM';
        pnlUserName.Caption := '';
      end
      else begin
        if DongaGmes is TGmes then begin
          DongaGmes.MesUserId := Common.m_sUserId;
          if not DongaGmes.MesEayt then DongaGmes.SendHostUchk
          else                          DongaGmes.SendHostEayt;
        end
        else begin
          InitGmes;
        end;
      end;
    end;
  end
  else begin
    Common.m_sUserId := 'PM';
    btnLogIn.Visible := False;
  end;
//  MakeDioSig;
  CreateClassData;
  // 현재 설정 되어 있는 Local IP Display 하자.
  pnlStLocalIp.Caption := Common.GetLocalIpList;
  Self.Caption := DefCommon.PROGRAM_NAME + ' Version ' + Common.GetVersionDate;
//  Common.TaskBar(True);
end;

procedure TfrmMainL.GetBcrConnStatus(bConnected: Boolean;
  sMsg: string);
begin
  if sMsg = 'NONE' then begin
    ledBcr1.FalseColor := clGray;
  end
  else begin
    ledBcr1.FalseColor := clRed;
  end;
  pnlBcr1.Caption := 'Hand BCR';
  pnlBcrStatus1.Caption := sMsg;
  ledBcr1.Value   := bConnected;
end;

procedure TfrmMainL.InitAll;
var
  i : Integer;
begin
  if DongaHandBcr <> nil then begin
    DongaHandBcr.Free;
    DongaHandBcr := nil;
  end;

  // Distroy current alloc class
  if frmTest_L <> nil then begin
    frmTest_L.Free;
    frmTest_L := nil;
  end;

  if UdpServer <> nil then begin
    UdpServer.Free;
    UdpServer := nil;
  end;
  if Script <> nil then begin
    Script.Free;
    Script := nil;
  end;
  if AxDio <> nil then begin
    AxDio.Free;
    AxDio := nil;
  end;

  if Common is TCommon then begin
    Common.Free;
    Common := nil;
  end;
  Sleep(1000);
  // Create Again.
  Common :=	TCommon.Create;
  CreateClassData;
end;

procedure TfrmMainL.initform;
begin
  case Common.SystemInfo.UIType of
    Defcommon.UI_WIN10_NOR  : TStyleManager.SetStyle('Windows10');
    Defcommon.UI_WIN10_BLACK : TStyleManager.SetStyle('Windows10 Dark')
    else begin
      TStyleManager.SetStyle('Windows10');
    end;
  end;
end;

procedure TfrmMainL.InitGmes;
var
  sService, sNetWork, sDeamon : string;
  sLocal, sRemote, sHostPath  : string;
  bRtn                        : Boolean;
begin
  DongaGmes := TGmes.Create(Self, Self.Handle);
  DongaGmes.OnGmsEvent  := OnMesMsg;
  InitMainTool(False);
  sService    := Common.SystemInfo.ServicePort;
  sNetWork    := Common.SystemInfo.Network;
  sDeamon     := Common.SystemInfo.DaemonPort;
  sLocal      := Common.SystemInfo.LocalSubject;
  sRemote     := Common.SystemInfo.RemoteSubject;
  sHostPath   := Common.Path.GMES;
  DongaGmes.MesUserId := Common.m_sUserId;

  DongaGmes.MesSystemNo   := Common.SystemInfo.EQPId;
  bRtn := DongaGmes.HOST_Initial(sService, sNetWork, sDeamon, sLocal, sRemote, sHostPath);
  ledGmes.Value := bRtn;
  if bRtn then begin
    pnlHost.Caption := 'Connected';
    DongaGmes.FtpAddr := Common.SystemInfo.HOST_FTP_IPAddr;
    DongaGmes.FtpUser := Common.SystemInfo.HOST_FTP_User;
    DongaGmes.FtpPass := Common.SystemInfo.HOST_FTP_Passwd;
    DongaGmes.FtpCombiPath := Common.SystemInfo.HOST_FTP_CombiPath;
  end
  else begin
    pnlHost.Caption := 'Disonnected';
  end;
end;

procedure TfrmMainL.InitMainTool(bEnable: Boolean);
begin
  btnModelChange.Enabled := bEnable;
  btnModel.Enabled  := bEnable;
end;

procedure TfrmMainL.MainDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg: string);
var
  i : Integer;
begin
  if bIn then begin
    for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
      ledDioIn[i].LedOn :=  IoDio[i];
    end;
    if not ((IoDio[DefDio.DIO_IN_0] and IoDio[DefDio.DIO_IN_1] and (not IoDio[DefDio.DIO_IN_2])))  then begin
      if frmNgMsg = nil then begin
        tmAlarmMsg.Interval := 1000;
        tmAlarmMsg.Enabled := True;
      end;
    end;
  end
  else begin
    for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
      ledDioOut[i].LedOn :=  IoDio[i];
    end;
  end;
  if sErrMsg = '' then begin
    ledDioConnected.Value := True;
  end
  else begin
    ledDioConnected.Value := False;
  end;
  pnlDioStatus.Caption := sErrMsg;

end;

procedure TfrmMainL.MakeCsvData(var sHeader, sData: string; nCh: Integer);
var
  sPgVer : string;
  sTemp,sTemp2,sTemp3 : string;
begin
  // PG[nCh].m_sFwVer ==> ,P124,F409,M54D,PW21
  sPgVer := Trim(Copy(PG[nCh].m_sFwVer,2,4));
  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,7,4));
  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,12,4));
  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,17,4));

  // for Header.
  sHeader := Format('%s,%s,%s,%s',['EQP_ID','User_ID','Model_Name','Channel']);
  sHeader := sHeader+ format(',%s,%s',['S/W_VER', 'Script_VER']);
  sHeader := sHeader+ format(',%s,%s',['PG_FW/FPGA/MDM/PWR','Serial_Number']);
  sHeader := sHeader+ format(',%s,%s,%s,%s,%s',['Date','Start_Time','End_Time','Tact_Time','Result']);
  sHeader := sHeader + PasScr[nCh].m_TestRet.csvHeader;

  // for data.
  sTemp := Format('%d',[nCh+1]);
  sData := format('%s,%s,%s,%s',[common.SystemInfo.EQPId, Common.m_sUserId, Common.SystemInfo.TestModel,sTemp]);

  sData := sData+ format(',%s,%s',[DefCommon.PROGRAM_VER, Script.m_sScriptVer]);
  sData := sData+ format(',%s,%s',[sPgVer, Logic[nCh].m_Inspect.SerialNo]);

  sTemp := FormatDateTime('YYYY/MM/DD', PasScr[nCh].m_TestRet.StartTime);
  sData := sData+ format(',%s',[sTemp]);

  sTemp := FormatDateTime('hh:nn:ss', PasScr[nCh].m_TestRet.StartTime);
  sTemp2 := FormatDateTime('hh:nn:ss', PasScr[nCh].m_TestRet.EndTime);
  sTemp3 := Format('%d',[SecondsBetween(PasScr[nCh].m_TestRet.StartTime,PasScr[nCh].m_TestRet.EndTime)]);    // for tact time
  sData := sData + format(',%s,%s,%s,%s',[sTemp,sTemp2,sTemp3,PasScr[nCh].m_TestRet.Result]);
  sData := sData + PasScr[nCh].m_TestRet.csvData;
end;

procedure TfrmMainL.MakeDioSig;
var
  i: Integer;
  nWidth, nHeight : Integer;
begin
  nWidth := 75;
  nHeight := 18;
  for i := 0 to Pred(DefDio.MAX_IN_CNT) do begin
    ledDioIn[i] := TTILed.Create(Self);
    ledDioIn[i].Parent := grpDioSig;
    ledDioIn[i].Left := 3;
    ledDioIn[i].Top  := 49 + i*(nHeight + 1);
    ledDioIn[i].Width := nWidth;
    ledDioIn[i].Height := nHeight;
    ledDioIn[i].LedColor := TLedColor(Green);
    ledDioIn[i].StyleElements := [seBorder];
    ledDioIn[i].Caption := '';

    ledDioOut[i] := TTILed.Create(Self);
    ledDioOut[i].Parent := grpDioSig;
    ledDioOut[i].Left := 78;
    ledDioOut[i].Top  := 49 + i*(nHeight + 1);
    ledDioOut[i].Width := nWidth;
    ledDioOut[i].Height := nHeight;
    ledDioOut[i].LedColor := TLedColor(Yellow);
    ledDioOut[i].StyleElements := [seBorder];
    ledDioOut[i].Caption := '';
  end;

  ledDioIn[DIO_IN_0].Caption := 'FAN #1';
  ledDioIn[DIO_IN_1].Caption := 'FAN #2';
  ledDioIn[DIO_IN_2].Caption := 'Temp Sensor';

  if Common.SystemInfo.DIOType = 0 then begin
    grpADDioSig.Visible := False;
    ledDioOut[DIO_OUT_0].Caption := 'Open Sylinder';
    ledDioOut[DIO_OUT_1].Caption := 'Vacuum Eject';
    ledDioOut[DIO_OUT_2].Caption := 'Red Lamp';
    ledDioOut[DIO_OUT_3].Caption := 'Yellow Lamp';
    ledDioOut[DIO_OUT_4].Caption := 'Green Lamp';
    ledDioOut[DIO_OUT_5].Caption := 'Buzzer';
    ledDioOut[DIO_OUT_6].Caption := 'Light';
  end
  else if Common.SystemInfo.DIOType = 1 then begin
    grpADDioSig.Visible := True;
    ledDioOut[DIO_OUT_0].Caption := 'Auto Contact1';
    ledDioOut[DIO_OUT_1].Caption := 'Auto Contact2';
    ledDioOut[DIO_OUT_2].Caption := 'Auto Open1';
    ledDioOut[DIO_OUT_3].Caption := 'Auto Open2';
    ledDioOut[DIO_OUT_4].Caption := 'Vaccum1';
    ledDioOut[DIO_OUT_5].Caption := 'Vaccum2';
    ledDioOut[DIO_OUT_6].Caption := 'Vaccum3';
    ledDioOut[DIO_OUT_7].Caption := 'Vaccum4';
    ledDioOut[DIO_OUT_8].Caption := 'Light';
    ledDioOut[DIO_OUT_9].Caption := 'Red Lamp';
    ledDioOut[DIO_OUT_10].Caption := 'Yellow Lamp';
    ledDioOut[DIO_OUT_11].Caption := 'Green Lamp';
    ledDioOut[DIO_OUT_12].Caption := 'Buzzer';
    ledDioOut[DIO_OUT_13].Caption := 'Ion Bar';

    for i := 0 to Pred(DefDio.MAX_ADLINK_IO_CNT) do begin
      ledADDioIn[i] := TTILed.Create(Self);
      ledADDioIn[i].Parent := grpADDioSig;
      ledADDioIn[i].Left := 3;
      ledADDioIn[i].Top  := 49 + i*(nHeight + 1);
      ledADDioIn[i].Width := nWidth;
      ledADDioIn[i].Height := nHeight;
      ledADDioIn[i].LedColor := TLedColor(Green);
      ledADDioIn[i].StyleElements := [seBorder];
      ledADDioIn[i].Caption := '';

      ledADDioOut[i] := TTILed.Create(Self);
      ledADDioOut[i].Parent := grpADDioSig;
      ledADDioOut[i].Left := 78;
      ledADDioOut[i].Top  := 49 + i*(nHeight + 1);
      ledADDioOut[i].Width := nWidth;
      ledADDioOut[i].Height := nHeight;
      ledADDioOut[i].LedColor := TLedColor(Yellow);
      ledADDioOut[i].StyleElements := [seBorder];
      ledADDioOut[i].Caption := '';
    end;

    ledADDioIn[ADLINK_IN_0].Caption := 'Vaccum Sen1';
    ledADDioIn[ADLINK_IN_1].Caption := 'Vaccum Sen2';
    ledADDioIn[ADLINK_IN_2].Caption := 'Vaccum Sen3';
    ledADDioIn[ADLINK_IN_3].Caption := 'Vaccum Sen4';

    ledADDioOut[ADLINK_OUT_0].Caption := 'Vaccum Sen1';
    ledADDioOut[ADLINK_OUT_1].Caption := 'Vaccum Sen2';
    ledADDioOut[ADLINK_OUT_2].Caption := 'Vaccum Sen3';
    ledADDioOut[ADLINK_OUT_3].Caption := 'Vaccum Sen4';
  end;
end;

procedure TfrmMainL.OnMesMsg(nMsgType, nPg: Integer; bError: Boolean;
  sErrMsg: string);
var
  sHostErrMsg : string;
begin
  sHostErrMsg := StringReplace(sErrMsg, '[', '', [rfReplaceAll]);
  sHostErrMsg := StringReplace(sHostErrMsg, '[', '', [rfReplaceAll]);

  case nMsgType of
    DefGmes.MES_EAYT  : begin
      if bError then begin
        ShowNgMessage(sHostErrMsg);
      end;
    end;
    DefGmes.MES_UCHK  : begin
      DongaGmes.MesUserName  := StringReplace(DongaGmes.MesUserName, '[', '', [rfReplaceAll]);
      DongaGmes.MesUserName  := StringReplace(DongaGmes.MesUserName, ']', '', [rfReplaceAll]);
      if not bError then begin
        pnlUserName.Caption := DongaGmes.MesUserName;
        pnlUserId.Caption := DongaGmes.MesUserId;
      end
      else begin
        ShowNgMessage(sHostErrMsg);
      end;
    end;
    DefGmes.MES_EDTI  : begin
      InitMainTool(True);
      if bError then begin
        ShowNgMessage(sHostErrMsg);
      end;
    end;
    DefGmes.MES_FLDR  : begin
      if bError then begin
        ShowNgMessage(sHostErrMsg);
      end;
    end;
    DefGmes.MES_APDR  : begin
      if bError then begin
        ShowMessage(sHostErrMsg);
      end;
    end;
    DefGmes.MES_EQCC  : begin
      if bError then begin
        ShowNgMessage(sHostErrMsg);
      end;
    end;
  end;
end;

procedure TfrmMainL.ReadDioStatus(InDio, OutDio: ADioStatus);
var
  i : Integer;
begin
  if not m_ADDioEnable then exit;
  m_ADDioEnable := False;

  for i := 0 to Pred(DefDio.MAX_ADLINK_IO_CNT) do begin
    ledADDioIn[i].LedOn := InDio[i];
    ledADDioOut[i].LedOn := OutDio[i];
  end;
 {
  for i := 0 to Pred(DefDio.MAX_ADLINK_IO_CNT) do begin
    if InDio[i] then m_bSensorIn[i] := True;
  end;

  // CH당 센서 1개
  if      m_bSensorIn[0] then AxDio.WriteDio(2, 0)
  else if m_bSensorIn[1] then AxDio.WriteDio(3, 0);

  // CH당 센서 2개 // 이걸 어떻게 구별하지?
  // 전역변수 위치는?
  // 전역변수 초기화 타이밍은 센서 초기화 진행됐을때.. pasScriptClass 에서 밖에 못함.

  if      (m_bSensorIn[0] and m_bSensorIn[1]) then AxDio.WriteDio(2, 0)  // 확인 필요
  else if (m_bSensorIn[2] and m_bSensorIn[3]) then AxDio.WriteDio(3, 0); // 확인 필요
   }
  m_ADDioEnable := True;
end;

procedure TfrmMainL.ShowNgMessage(sMessage: string);
begin
  frmNgMsg  := TfrmNgMsg.Create(nil);
  try
    frmNgMsg.lblShow.Caption := sMessage;
    frmNgMsg.ShowModal;
  finally
    frmNgMsg.Free;
    frmNgMsg := nil;
  end;
end;

procedure TfrmMainL.tmAlarmMsgTimer(Sender: TObject);
var
  sDebug : string;
begin
  tmAlarmMsg.Enabled := False;
  if AxDio <> nil then begin
    sDebug := 'Check system [';
    if not AxDio.m_bInDio[DefDio.DIO_IN_0] then sDebug := sDebug + 'Fan #1,';
    if not AxDio.m_bInDio[DefDio.DIO_IN_1] then sDebug := sDebug + 'Fan #2,';
    if     AxDio.m_bInDio[DefDio.DIO_IN_2] then sDebug := sDebug + 'Temp Sensor';
    sDebug := sDebug +']';
//    AxDio.WriteDio(DefDio.DIO_OUT_2,1);
//    AxDio.WriteDio(DefDio.DIO_OUT_3,0);
//    AxDio.WriteDio(DefDio.DIO_OUT_4,0);
//    AxDio.WriteDio(DefDio.DIO_OUT_6,1);
    ShowNgMessage(sDebug);
//    AxDio.WriteDio(DefDio.DIO_OUT_6,0);
  end;
end;

procedure TfrmMainL.tmrDisplayTestFormTimer(Sender: TObject);
var
  i: Integer;
begin
  tmrDisplayTestForm.Enabled := False;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    frmTest_L := TfrmTest_L.Create(self);

    frmTest_L.Tag := i;
    frmTest_L.Height := Self.Height - tolGroupMain.Top - tolGroupMain.Height - 40 ;
    frmTest_L.Width  := Self.Width - (pnlSysInfo.Width + pnlSysInfo.Left) - 20 ;
    frmTest_L.Left   := 0;
    frmTest_L.Top    := 0;
    frmTest_L.WindowState := wsMaximized;
    frmTest_L.ShowGui(Self.Handle);
    frmTest_L.Visible := True;
    frmTest_L.Caption := Format('Stage %X',[i+1]);
    frmTest_L.SetBcrData;
  end;

  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if Logic[i] = nil then Exit;
  end;
  MakeDioSig;
  UdpServer.FIsReadyToRead := True;
  // Main의 Creat에 놔두변 오류 발생시 MDI 오류 발생.
  AxDio := TAxDio.Create(Self.Handle,DefDio.DONGA_16X16_CH,200);
  AxDio.InDioStatus := MainDioStatus;
  if AxDio <> nil then begin
    for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
      AxDio.WriteDio(i,1); // All Off
      AxDio.WriteDio(i,0); // All Off
    end;
    AxDio.WriteDio(DefDio.DIO_OUT_8,1); // Light On.
  end;
{$IFDEF ADLINK_DIO}
  if Common.SystemInfo.UIType = 1 then begin
    AdLinkDio := TDongaDio.Create(Self.handle, DefDio.TYPE_CARD_7230,100);
    AdLinkDio.InAdDioStatus := ReadDioStatus;
    AdLinkDio.GetDioStatus;
    m_ADDioEnable := True;
  end;

{$ENDIF} 
end;

procedure TfrmMainL.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, nTemp : Integer;
  sMsg : string;
  sHeader, sData : string;
begin
  nType := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
  case nType of
//    // From PG
//    DefCommon.MSG_TYPE_PG : begin
//      nMode := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
//      sMsg  := string(PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg);
//      case nMode of
//        DefCommon.MSG_MODE_DIFF_MODEL : begin
//          ShowNgMessage(sMsg + #13#10 + 'Please M/C');
//        end;
//      end;
//    end;

    DefCommon.MSG_TYPE_SCRIPT : begin
      nMode := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_LOG_CSV : begin
          MakeCsvData(sHeader, sData, nCh);
          Common.MakeSummaryCsvLog(sHeader, sData);
        end;
      end;
    end;


    // From Switch
    DefCommon.MSG_TYPE_SWITCH : begin
      nMode := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp  := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
          if nCh = DefCommon.JIG_A then begin
            pnlSwA.Caption := sMsg;
            case nTemp of
              0 : begin
                ledSwJigA.FalseColor := clRed;
                ledSwJigA.Value := False;
              end;
              1 : begin
                ledSwJigA.Value := True;
              end;
              2 : begin
                ledSwJigA.FalseColor := clGray;
                ledSwJigA.Value := False;
              end;
            end;
          end;
        end;
      end;
    end;

    // From AX DIO
    DefCommon.MSG_TYPE_AXDIO : begin
      nMode := PGuiAxDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiAxDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp := PGuiAxDio(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
          if nTemp = 0 then begin
            ledDioConnected.Value := True;
            pnlDioStatus.Caption := sMsg;
          end
          else begin
            ledDioConnected.Value := False;
            pnlDioStatus.Caption := sMsg;
          end;
        end;
      end;
    end;

    // From ADLINK DIO
    DefCommon.MSG_TYPE_ADLINK : begin
      nMode := PGuiAxDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiAxDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp := PGuiAxDio(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
          if nTemp = 0 then begin
            ledADDioConnected.Value := True;
            pnlADDioStatus.Caption := sMsg;
          end
          else begin
            ledADDioConnected.Value := False;
            pnlADDioStatus.Caption := sMsg;
          end;
        end;
      end;
    end;
  end;
end;
end.
