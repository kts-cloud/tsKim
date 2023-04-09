unit Main_A;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzPanel, RzButton, ALed, Vcl.ExtCtrls, System.ImageList,
  Vcl.ImgList, Vcl.Themes, System.UITypes,
  CommonClass, UserID, GMesCom, DefCommon, DefGmes, NGMsg, ModelInfo, Mainter, LogIn, LogicVh, HandBCR,
  UdpServerClient, Test4Ch, SwitchBtn, ScriptClass, AXDioLib, DefDio, TILed, AutoBCRClient,
  Vcl.StdCtrls, RzStatus, pasScriptClass, DefScript, Vcl.Buttons;

type
  TfrmMainA = class(TForm)
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
    RzPanel17: TRzPanel;
    pnlDioStatus: TRzPanel;
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
    btnMaint: TRzToolButton;
    tmrDisplayTestForm: TTimer;
    pnlModelNameInfo: TPanel;
    RzGroupBox1: TRzGroupBox;
    RzPanel1: TRzPanel;
    pnlUserId: TRzPanel;
    RzPanel4: TRzPanel;
    pnlStationNo: TRzPanel;
    RzPanel9: TRzPanel;
    pnlUserName: TRzPanel;
    ledDioConnected: ThhALed;
    RzPanel2: TRzPanel;
    pnlCheckSum: TRzPanel;
    btnMaintMsg: TRzBitBtn;
    tmAlarmMsg: TTimer;
    pnlBcr2: TRzPanel;
    pnlBcrStatus2: TRzPanel;
    RzStatusBar1: TRzStatusBar;
    RzResourceStatus1: TRzResourceStatus;
    RzClockStatus1: TRzClockStatus;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    RzKeyStatus1: TRzKeyStatus;
    tmrEQCC: TTimer;
    pnlMESConn: TPanel;
    tmrMESConn: TTimer;
    pnlStLocalIp: TRzStatusPane;
    RzStatusPane3: TRzStatusPane;

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnInitClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnLogInClick(Sender: TObject);
    procedure btnModelChangeClick(Sender: TObject);
    procedure btnModelClick(Sender: TObject);
    procedure btnMaintClick(Sender: TObject);
    procedure btnSetUpClick(Sender: TObject);
    procedure tmrDisplayTestFormTimer(Sender: TObject);

    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure btnMaintMsgClick(Sender: TObject);
    procedure tmAlarmMsgTimer(Sender: TObject);

    // Style 변경 완료후 Main과 Test의 Handle값이 변경 됨. == > 이벤트 처리하기 위함.
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure tmrEQCCTimer(Sender: TObject);
    procedure tmrMESConnTimer(Sender: TObject);
  private
    { Private declarations }
//    frmTest4Ch     : array[.JIG_A .. DefPocb.JIG_B] of TfrmTest4Ch;
    ledDioIn, ledDioOut : array[0.. DefDio.MAX_IN_CNT] of  TTILed;
    ledBcr2 : ThhALed;
    function CheckAdminPasswd : boolean;
    procedure initform;
    procedure InitAll;
    procedure DisplayScriptInfo;
//    function CheckDioAlarm : Boolean;
    procedure GetBcrConnStatus(bConnected : Boolean; sMsg : string);
    procedure BCRConnection(wCh : Word; bConn : Boolean);
    procedure CreateClassData;
    function  DisplayLogIn : Integer;
    procedure InitGmes;
    procedure ShowNgMessage(sMessage: string);
    function CheckPgRun : Boolean; // True : Run, False : Pg Stop.
    procedure InitMainTool(bEnable : Boolean);
    procedure OnMesMsg(nMsgType, nPg: Integer;bError : Boolean; sMsg : string);
    procedure MakeDioSig;
    procedure MainDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg : string);
  public
    { Public declarations }
  end;

var
  frmMainA: TfrmMainA;

implementation

{$R *.dfm}

uses ModelSelect, ModelDownload, SystemSetup;

{ TForm1 }

procedure TfrmMainA.BCRConnection(wCh: Word; bConn: Boolean);
begin
  if bConn then begin
    if wCh = UPPER_AUTO_BCR then begin
      ledBcr1.Value := True;
      pnlBcrStatus1.Caption := 'Connected';
    end
    else if wCh = LOWER_AUTO_BCR then begin
      ledBcr2.Value := True;
      pnlBcrStatus2.Caption := 'Connected';
    end;
  end
  else begin
    if wCh = UPPER_AUTO_BCR then begin
      ledBcr1.Value := False;
      pnlBcrStatus1.Caption := 'Disconnected';
    end
    else if wCh = LOWER_AUTO_BCR then begin
      ledBcr2.Value := False;
      pnlBcrStatus2.Caption := 'Disconnected';
    end;
  end;
end;


procedure TfrmMainA.btnExitClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMainA.btnInitClick(Sender: TObject);
var
  sMsg : string;
begin
  sMsg :=        #13#10 + 'bạn có muốn khởi tạo chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to initialize this Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    InitAll;
  end;
end;

procedure TfrmMainA.btnLogInClick(Sender: TObject);
begin
  if CheckPgRun then Exit;

  if DisplayLogIn = mrCancel then Exit;

  if Common.m_sUserId = 'PM' then begin
    if CheckAdminPasswd then begin
//      InitMainTool(True);
      if DongaGmes is TGmes then begin
        DongaGmes.Free;
        DongaGmes := nil;
      end;
      ledGmes.FalseColor := clGray;
      ledGmes.Value := False;
      pnlHost.Caption := 'PM Mode';
      if Common.SystemInfo.ChCountUsed = 1 then begin
        tmrMESConn.Enabled := True;
        pnlMESConn.Visible := True;
      end;
    end;
  end
  else begin
//    InitMainTool(False);
    if DongaGmes is TGmes then begin
      DongaGmes.hMainHandle := frmTest4Ch.Handle;
      DongaGmes.MesUserId := Common.m_sUserId;
      if not DongaGmes.MesEayt then DongaGmes.SendHostUchk
      else                          DongaGmes.SendHostEayt;
    end
    else begin
      InitGmes;
      DongaGmes.hMainHandle := frmTest4Ch.Handle;
    end;
  end;
  pnlUserName.Caption   := '';
  pnlUserId.Caption     := Common.m_sUserId;
end;

procedure TfrmMainA.btnMaintClick(Sender: TObject);
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

procedure TfrmMainA.btnMaintMsgClick(Sender: TObject);
begin
  if AxDio <> nil then begin
    AxDio.WriteDio(DefDio.DIO_OUT_6,1); // Lamp On.
    AxDio.WriteDio(DefDio.DIO_OUT_2,0); // Red Off.    // YELLOW Lamp;
    AxDio.WriteDio(DefDio.DIO_OUT_3,1); // YELLOW on.    // YELLOW Lamp;
    AxDio.WriteDio(DefDio.DIO_OUT_4,0); // Green Off.    // YELLOW Lamp;
  end;
  ShowNgMessage('Checking System');
  if AxDio <> nil then begin
    if True then
    if AxDio.m_bInDio[DefDio.DIO_IN_0] and AxDio.m_bInDio[DefDio.DIO_IN_1] and (not AxDio.m_bInDio[DefDio.DIO_IN_2]) then begin
      AxDio.WriteDio(DefDio.DIO_OUT_2,0); // Red Off.    // YELLOW Lamp;
      AxDio.WriteDio(DefDio.DIO_OUT_3,0); // YELLOW off.    // YELLOW Lamp;
      AxDio.WriteDio(DefDio.DIO_OUT_4,1); // Green On.    // YELLOW Lamp;
    end
    else begin
      AxDio.WriteDio(DefDio.DIO_OUT_2,1); // Red on.    // YELLOW Lamp;
      AxDio.WriteDio(DefDio.DIO_OUT_3,0); // YELLOW off.    // YELLOW Lamp;
      AxDio.WriteDio(DefDio.DIO_OUT_4,0); // Green off.    // YELLOW Lamp;
    end;
  end;
end;

procedure TfrmMainA.btnModelChangeClick(Sender: TObject);
var
  bChangeModel : Boolean;
//  i : Integer;
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

procedure TfrmMainA.btnModelClick(Sender: TObject);
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

procedure TfrmMainA.btnSetUpClick(Sender: TObject);
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

function TfrmMainA.CheckAdminPasswd: boolean;
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

//// 비정상이면 Red Lamp에 Popup 띄우기.
//function TfrmMainA.CheckDioAlarm: Boolean;
//var
//  bRet : Boolean;
//begin
//  bRet := False;
//  if AxDio <> nil then begin
//    // Fan 1, 2가 On이고. 온도 Sensor가 Off일 경우가 정상 상태.
//    if AxDio.m_bInDio[DefDio.DIO_IN_0] and AxDio.m_bInDio[DefDio.DIO_IN_1] and (not AxDio.m_bInDio[DefDio.DIO_IN_2]) then begin
//      bRet := False;
//    end
//    else begin
//      bRet := True;
//      AxDio.WriteDio(DefDio.DIO_OUT_2,1);// Red Lamp On.
//      AxDio.WriteDio(DefDio.DIO_OUT_3,0);// Yellow Lamp Off.
//      AxDio.WriteDio(DefDio.DIO_OUT_4,0);// Green Lamp Off.
//      AxDio.WriteDio(DefDio.DIO_OUT_6,1);// Buzzer On.
//    end;
//  end;
//  Result := bRet;
//end;

function TfrmMainA.CheckPgRun: Boolean;
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

procedure TfrmMainA.CMStyleChanged(var Message: TMessage);
begin
//  ShowMessage(Format('Style Changed - %d',[self.Handle]));
  if frmTest4Ch <> nil then begin
    frmTest4Ch.SetHandleAgain(Self.Handle);
  end;
end;

procedure TfrmMainA.CreateClassData;
var
  sFileName : String;
begin
  InitForm; // InitForm 내부 TStyleManager.SetStyle을 수행하면 Self.Handle 값이 달라짐. 순서 중요!!

  // UDP 서버 IP 192.168.0.11
  // 내부적으로 Common file을 읽어 오기 대문에 반드시 Common Create 이후 호출.
  UdpServer := TUdpServerVh.Create(Self.Handle, DefCommon.MAX_PG_CNT);
  tmrDisplayTestForm.Enabled := True;
  tmrEQCC.Enabled := False;
  sFileName := Common.Path.MODEL + Common.SystemInfo.TestModel + '.script';
  Script := TScript.Create(sFileName);
  DisplayScriptInfo;

  if not Common.SystemInfo.UseAutoBCR then begin
    DongaHandBcr := TSerialBcr.Create(Self);
    DongaHandBcr.OnRevBcrConn := GetBcrConnStatus;
    DongaHandBcr.ChangePort(Common.SystemInfo.Com_HandBCR);
  end;

  pnlStationNo.Caption := Common.SystemInfo.EQPId;
end;

function TfrmMainA.DisplayLogIn: Integer;
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

procedure TfrmMainA.DisplayScriptInfo;
begin
//  pnlScriptVer.Caption :=  Script.m_sScriptVer + ' / ' + Script.m_sScriptVerDate;
  pnlResolution.Caption := Format(' %d(H) x %d(V)',[Common.TestModelInfo.H_Active, Common.TestModelInfo.V_Active]);
  pnlPatternGroup.Caption :=  Common.TestModelInfo2.PatGrpName;
  pnlModelNameInfo.Caption := Common.SystemInfo.TestModel;


  pnlCheckSum.Caption  :=  Common.TestModelInfo2.CheckSum + '/'+ Common.SystemInfo.ScriptCrc;
  pnlScriptVer.Caption :=  Common.SystemInfo.ScriptVer;
end;

procedure TfrmMainA.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  sMsg : string;
  i    : Integer;
begin
  sMsg := #13#10 + 'bạn có muốn thóat chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to Exit Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
      AxDio.WriteDio(i,1); // All Off
      AxDio.WriteDio(i,0); // All Off
    end;
    if DongaHandBcr <> nil then begin
      DongaHandBcr.Free;
      DongaHandBcr := nil;
    end;
    for i := UPPER_AUTO_BCR to LOWER_AUTO_BCR do begin
      if tcpAutoBCR[i] <> nil then begin
        tcpAutoBCR[i].Free;
        tcpAutoBCR[i] := nil;
      end;
    end;
    if frmTest4Ch <> nil then begin
      frmTest4Ch.Free;
      frmTest4Ch := nil;
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

procedure TfrmMainA.FormCreate(Sender: TObject);
var
  nRet : Integer;
  nTemp : word;
  nTemp2 : word;
begin
  nTemp := 256;
  nTemp2 := 255;
  ShowMessage(IntToStr(nTemp and nTemp2));
  ShowMessage(IntToStr(nTemp shr 8));
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
        if Common.SystemInfo.ChCountUsed = 1 then begin
          tmrMESConn.Enabled := True;
          pnlMESConn.Visible := True;
        end;
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
//    btnLogIn.Visible := False;
  end;
  MakeDioSig;
  CreateClassData;
  // 현재 설정 되어 있는 Local IP Display 하자.
  pnlStLocalIp.Caption := Common.GetLocalIpList;
  Self.Caption := DefCommon.PROGRAM_NAME + ' Version ' + Common.GetVersionDate;
//  Common.TaskBar(True);
end;

procedure TfrmMainA.GetBcrConnStatus(bConnected: Boolean; sMsg: string);
begin
  if sMsg = 'NONE' then begin
    ledBcr1.FalseColor := clGray;
  end
  else begin
    ledBcr1.FalseColor := clRed;
  end;
  pnlBcr1.Caption := sMsg;
  ledBcr1.Value   := bConnected;
end;

procedure TfrmMainA.InitAll;
var
  i : Integer;
begin
  if DongaHandBcr <> nil then begin
    DongaHandBcr.Free;
    DongaHandBcr := nil;
  end;
  for i := UPPER_AUTO_BCR to LOWER_AUTO_BCR do begin
    if tcpAutoBCR[i] <> nil then begin
      tcpAutoBCR[i].Free;
      tcpAutoBCR[i] := nil;
    end;
  end;

  // Distroy current alloc class
  if frmTest4Ch <> nil then begin
    frmTest4Ch.Free;
    frmTest4Ch := nil;
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

procedure TfrmMainA.initform;
begin
  if Common.SystemInfo.ChCountUsed = 1 then begin
    if not ledGmes.Value then
      pnlMESConn.Visible := True;
  end
  else begin
    pnlMESConn.Visible := False;
  end;

  case Common.SystemInfo.UIType of
    Defcommon.UI_WIN10_NOR  : begin
      TStyleManager.SetStyle('Windows10');
      pnlMESConn.Color := clBtnFace;
    end;
    Defcommon.UI_WIN10_BLACK : begin
      TStyleManager.SetStyle('Windows10 Dark');
      pnlMESConn.Color := clBlack;
    end;
    else begin
      TStyleManager.SetStyle('Windows10');
      pnlMESConn.Color := clBtnFace;
    end;
  end;

  if Common.SystemInfo.UseAutoBCR then begin
    pnlBcr1.Caption := 'AutoBCR_U';
    if ledBcr2 = nil then begin
      ledBcr2 := ThhALed.Create(self);
      ledBcr2.Parent := RzGroupBox4;
      ledBcr2.Top := 60;
      ledBcr2.Left := 61;
      ledBcr2.LEDStyle := LEDVertical;
      ledBcr2.Blink := False;
      ledBcr2.FalseColor := clGray;
    end;
    ledBcr2.Visible := True;

    pnlBcr2.Top := 60;
    pnlBcr2.Visible := True;
    pnlBcrStatus2.Top := 60;
    pnlBcrStatus2.Visible := True;

    pnlSwitch.Top := 81;
    ledSwJigA.Top := 81;
    pnlSwA.Top := 81;
  end
  else begin
    pnlBcr1.Caption := 'Hand BCR';
    pnlBcr2.Visible := False;
    pnlBcrStatus2.Visible := False;

    pnlSwitch.Top := 60;
    ledSwJigA.Top := 60;
    pnlSwA.Top := 60;
    if ledBcr2 <> nil then begin
      ledBcr2.Visible := False;
    end;
  end;
end;

procedure TfrmMainA.InitGmes;
var
  sService, sNetWork, sDeamon : string;
  sLocal, sRemote, sHostPath  : string;
  bRtn                        : Boolean;
begin
  DongaGmes := TGmes.Create(Self, Self.Handle);
  DongaGmes.OnGmsEvent  := OnMesMsg;
//  InitMainTool(False);
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
    if Common.SystemInfo.ChCountUsed = 1 then begin
      tmrMESConn.Enabled := False;
      pnlMESConn.Visible := False;
    end;
  end
  else begin
    pnlHost.Caption := 'Disonnected';
    if Common.SystemInfo.ChCountUsed = 1 then begin
      tmrMESConn.Enabled := True;
      pnlMESConn.Visible := True;
    end;
  end;
end;

procedure TfrmMainA.InitMainTool(bEnable: Boolean);
begin
  btnModelChange.Enabled := bEnable;
  btnModel.Enabled  := bEnable;
end;

procedure TfrmMainA.MainDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg: string);
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

procedure TfrmMainA.MakeDioSig;
var
  i: Integer;
  nWidth, nHeight : Integer;
begin
  nWidth := 75;
  nHeight := 20;
  for i := 0 to DefDio.MAX_IN_CNT do begin
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

  if not Common.SystemInfo.UseAutoBCR then begin
    ledDioOut[DIO_OUT_0].Caption := 'Open Sylinder1';
    ledDioOut[DIO_OUT_1].Caption := 'Vacuum Eject1';
    ledDioOut[DIO_OUT_2].Caption := 'Red Lamp';
    ledDioOut[DIO_OUT_3].Caption := 'Yellow Lamp';
    ledDioOut[DIO_OUT_4].Caption := 'Green Lamp';
    ledDioOut[DIO_OUT_5].Caption := 'Buzzer';
    ledDioOut[DIO_OUT_6].Caption := 'Light';
    ledDioOut[DIO_OUT_7].Caption := 'Open Sylinder2';
    ledDioOut[DIO_OUT_8].Caption := 'Vacuum Eject2';
  end;
end;

procedure TfrmMainA.OnMesMsg(nMsgType, nPg: Integer; bError: Boolean; sMsg: string);
var
  sHostMsg : string;
begin
  sHostMsg := StringReplace(sMsg, '[', '', [rfReplaceAll]);
  sHostMsg := StringReplace(sHostMsg, '[', '', [rfReplaceAll]);

  if (Common.SystemInfo.UseEQCC) then begin
    tmrEQCC.Enabled := False;
    tmrEQCC.Enabled := True;
  end;

  case nMsgType of
    DefGmes.MES_EAYT  : begin
      if bError then begin
        ShowNgMessage(sHostMsg);
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
        ShowNgMessage(sHostMsg);
      end;
    end;
    DefGmes.MES_EDTI  : begin
//      InitMainTool(True);
      if bError then begin
        ShowNgMessage(sHostMsg);
      end;
    end;
    DefGmes.MES_FLDR  : begin
      if bError then begin
        ShowNgMessage(sHostMsg);
      end;
    end;
    DefGmes.MES_APDR  : begin
      if bError then begin
        ShowMessage(sHostMsg);
      end;
    end;
    DefGmes.MES_EQCC  : begin
      if bError then begin
        ShowNgMessage(sHostMsg);
      end;
    end;
    DefGmes.MES_ZSET  : begin
      if bError then begin
        ShowNgMessage(sHostMsg);
      end
      else begin
        PasScr[DefCommon.CH1].RunSeq(DefScript.SEQ_KEY_SCAN);
      end;
    end;
  end;
end;


procedure TfrmMainA.ShowNgMessage(sMessage: string);
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

procedure TfrmMainA.tmAlarmMsgTimer(Sender: TObject);
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

procedure TfrmMainA.tmrDisplayTestFormTimer(Sender: TObject);
var
  i: Integer;
begin
  tmrDisplayTestForm.Enabled := False;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    frmTest4Ch := TfrmTest4Ch.Create(self);

    frmTest4Ch.Tag := i;
    frmTest4Ch.Height := Self.Height - tolGroupMain.Top - tolGroupMain.Height - 80 ;
    frmTest4Ch.Width  := Self.Width - (pnlSysInfo.Width + pnlSysInfo.Left) - 20 ;
    frmTest4Ch.Left   := 0;
    frmTest4Ch.Top    := 0;
    frmTest4Ch.ShowGui(Self.Handle);
    frmTest4Ch.WindowState := wsMaximized;
    frmTest4Ch.Visible := True;
    frmTest4Ch.Caption := Format('Stage %X',[i+1]);
    if not Common.SystemInfo.UseAutoBCR then begin
      frmTest4Ch.SetBcrData;
    end;
  end;

//  nCh := 0;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if Logic[i] = nil then Exit;
  end;

  UdpServer.FIsReadyToRead := True;
  // Main의 Creat에 놔두변 오류 발생시 MDI 오류 발생.
  AxDio := TAxDio.Create(Self.Handle,DefDio.DONGA_16X16_CH,200);
  AxDio.InDioStatus := MainDioStatus;
  for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
    AxDio.WriteDio(i,1); // All Off
    AxDio.WriteDio(i,0); // All Off
  end;
  if not Common.SystemInfo.UseAutoBCR then begin // 점등검사기는 Lamp 없음. 아직 DIO 사용안함.
    AxDio.WriteDio(DefDio.DIO_OUT_6,1); // Light On.
  end;

  if Common.SystemInfo.UseAutoBCR then begin
    for i := UPPER_AUTO_BCR to LOWER_AUTO_BCR do begin

      //////////  for test /////////////////////////////////////
//      tcpAutoBCR[i] := TAutoBCR.Create('192.168.123.140', 8080+i, 1+i);
      //////////////////////////////////////////////////////////

      if i = UPPER_AUTO_BCR then
        tcpAutoBCR[i] := TAutoBCR.Create(UPPER_IP, 23, UPPER_AUTO_BCR)
      else if i = LOWER_AUTO_BCR then begin
        tcpAutoBCR[i] := TAutoBCR.Create(LOWER_IP, 23, LOWER_AUTO_BCR)
      end;
//      tcpAutoBCR[i] := TAutoBCR.Create('192.168.0.61', 23, 1+i);
      tcpAutoBCR[i].OnConnBCR := BCRConnection;
      tcpAutoBCR[i].Connect;
    end;
    frmTest4Ch.SetAutoBcrData;
  end;
end;

procedure TfrmMainA.tmrEQCCTimer(Sender: TObject);
begin
  // HOST 통신상태 확인용
  // HOST로부터 응답을 받은 후 1분 마다 통신상태 확인
  DongaGmes.SendHostEqcc;
end;

procedure TfrmMainA.tmrMESConnTimer(Sender: TObject);
begin
  if pnlMESConn.Color = clRed then begin
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlMESConn.Color := clBlack;
    end
    else begin
      pnlMESConn.Color := clBtnFace;
    end;
  end
  else begin
    pnlMESConn.Color := clRed;
  end;
end;
procedure TfrmMainA.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, nTemp : Integer;
  sMsg : string;
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
          Common.MakeSummaryCsvLog(PasScr[nCh].m_TestRet.csvHeader, PasScr[nCh].m_TestRet.csvData);
        end;
      end;
    end;
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
  end;
end;

end.
