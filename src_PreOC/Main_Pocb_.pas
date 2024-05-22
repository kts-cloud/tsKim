unit Main_Pocb;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ALed, RzPanel, RzButton, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList,
  Vcl.Themes, System.UITypes, TILed, pasScriptClass, System.DateUtils, CamComm,
  CommonClass, UserID, GMesCom, DefCommon, DefGmes, NGMsg, ModelInfo, Mainter, LogIn, LogicVh, HandBCR, defPlc, PlcTcpPocb,
  CamLight, AdvListV, Vcl.ComCtrls, DfsFtp,
  UdpServerClient, Test4ChPocb, SwitchBtn, ScriptClass, ModelSelect, ModelDownload, SystemSetup, RzStatus;
{$I Common.inc}
type
  TfrmMain_Pocb = class(TForm)
    ilIMGMain: TImageList;
    tolGroupMain: TRzToolbar;
    btnModel: TRzToolButton;
    rzspcr8: TRzSpacer;
    btnExit: TRzToolButton;
    btnModelChange: TRzToolButton;
    rzspcr2: TRzSpacer;
    btnInit: TRzToolButton;
    RzSpacer1: TRzSpacer;
    RzSpacer2: TRzSpacer;
    RzSpacer3: TRzSpacer;
    RzSpacer4: TRzSpacer;
    btnStation: TRzToolButton;
    btnMaint: TRzToolButton;
    ilFlag: TImageList;
    pnlSysInfo: TRzPanel;
    grpSystemInfo: TRzGroupBox;
    RzGroupBox5: TRzGroupBox;
    RzPanel5: TRzPanel;
    pnlUserId: TRzPanel;
    RzPanel17: TRzPanel;
    pnlStationNo: TRzPanel;
    RzPanel28: TRzPanel;
    pnlUserName: TRzPanel;
    RzGroupBox3: TRzGroupBox;
    RzPanel11: TRzPanel;
    pnlResolution: TRzPanel;
    pnlPsuVer: TRzPanel;
    RzPanel18: TRzPanel;
    RzPanel12: TRzPanel;
    pnlPatternGroup: TRzPanel;
    RzPanel14: TRzPanel;
    pnlIsuVer: TRzPanel;
    pnlModelNameInfo: TPanel;
    tmAlarmMsg: TTimer;
    tmrDisplayTestForm: TTimer;
    RzStatusBar1: TRzStatusBar;
    RzResourceStatus1: TRzResourceStatus;
    RzClockStatus1: TRzClockStatus;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    RzKeyStatus1: TRzKeyStatus;
    grpPlc: TRzGroupBox;
    ledPlc: ThhALed;
    pnlPlcTop: TRzPanel;
    pnlPlcStatus: TRzPanel;
    RzStatusPane3: TRzStatusPane;
    pnlStLocalIp: TRzStatusPane;
    pnlSubTool: TPanel;
    pnlMesReady: TPanel;
    btnLogIn: TRzToolButton;
    pnlPlcReady: TPanel;
    tmrMemCheck: TTimer;
    pnlMemCheck: TRzStatusPane;
    RzPanel21: TRzPanel;
    ledCam1: ThhALed;
    RzPanel22: TRzPanel;
    RzPanel23: TRzPanel;
    ledCam3: ThhALed;
    RzPanel24: TRzPanel;
    ledCam4: ThhALed;
    RzPanel25: TRzPanel;
    ledCam2: ThhALed;
    pnlZAxis: TRzPanel;
    pnlZxis: TRzPanel;
    tmrPlcAlarm: TTimer;
    RzPanel8: TRzPanel;
    ledHandBcr: ThhALed;
    pnlHandBcr: TRzPanel;
    pnlSwA: TRzPanel;
    ledSwJigA: ThhALed;
    RzPanel3: TRzPanel;
    RzPanel10: TRzPanel;
    pnlSwB: TRzPanel;
    ledSwJigB: ThhALed;
    RzPanel1: TRzPanel;
    ledCamLight: ThhALed;
    pnlCamLight: TRzPanel;
    stsCpuTemp: TRzStatusPane;
    tmrCpuCheck: TTimer;
    grpPwrInfo: TRzGroupBox;
    btnAutoReady: TRzToolButton;
    RzgrpDFS: TRzGroupBox;
    RzPanel2: TRzPanel;
    pnlCombiModelRCP: TRzPanel;
    pnlCombiProcessNo: TRzPanel;
    pnlCombiRouterNo: TRzPanel;
    RzPanel4: TRzPanel;
    RzPanel7: TRzPanel;
    RzPanel9: TRzPanel;
    ledDfs: ThhALed;
    pnlSysinfoDfs: TRzPanel;
    RzPanel6: TRzPanel;
    ledGmes: ThhALed;
    pnlHost: TRzPanel;
    procedure FormCreate(Sender: TObject);
    procedure btnInitClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure tmrDisplayTestFormTimer(Sender: TObject);
    procedure btnLogInClick(Sender: TObject);
    procedure btnModelChangeClick(Sender: TObject);
    procedure btnModelClick(Sender: TObject);
    procedure btnStationClick(Sender: TObject);
    procedure btnMaintClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    function IsHeaderExist( asHeaders : array of string) : Boolean;
    procedure tmrMemCheckTimer(Sender: TObject);
    procedure tmrPlcAlarmTimer(Sender: TObject);
    procedure tmAlarmMsgTimer(Sender: TObject);
    procedure btnAutoReadyClick(Sender: TObject);
  private
    { Private declarations }

    // for PLC Signal.
    ledPlcIn,   ledPlcIn2 : array[0.. defPlc.MAX_IN_CNT] of  TTILed;
    ledPlcOut,  ledPlcOut2 : array[0.. defPlc.MAX_OUT_CNT] of  TTILed;
    m_naPLCAlarmData: array [0..7] of Integer; //plc Alarm Data

    m_sPlcModelZAxis : string;
    m_bUnloadCheck, m_bCamCheck : Boolean;
    lstPwrView     : TAdvListView;
    m_nCamPos, m_nLoadPos : Integer;

    function CheckAdminPasswd : boolean;
    procedure initform;
    procedure DisplayScriptInfo;
    procedure InitialAll(bReset : Boolean = True);
    procedure ReadPlcStatus(nRet : Integer; sMsg : String);
    procedure GetBcrConnStatus(bConnected : Boolean; sMsg : string);
    procedure CreateClassData;
    function  DisplayLogIn : Integer;
    function InitGmes : Boolean;
    procedure ShowNgMessage(sMessage: string);
    function CheckPgRun : Boolean; // True : Run, False : Pg Stop.
    procedure InitMainTool(bEnable : Boolean);

    procedure OnMesMsg(nMsgType, nPg: Integer;bError : Boolean; sErrMsg : string);
    procedure MakePlcSig;
    procedure MainPlcStatus(bIn, nConnectCheck : Boolean; nLen : Integer; naReadData : array of Integer);
    procedure ShowPlcAlarm(naReadData : array of Integer);
    procedure ShowPlcJigTact(nData : Integer);
    // Style 변경 완료후 Main과 Test의 Handle값이 변경 됨. == > 이벤트 처리하기 위함.
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure MakeOpticCsvData(var sFileName : string; var sHeader: array of string; var sData : string; nCh : Integer);
    procedure MakeOpticSummaryCsvLog(sScrFileName : String; sCsvHeader : array of string; sCsvData: string);

    procedure AutoStart(nJig, nJigCh : Integer; sErr : string);
    procedure MakePlcLog;
    procedure ReleaseReadyModOnPlc;
    function CheckScriptRun : Boolean;
    procedure CheckScriptRunWithPlc;
    procedure GetCamConnStatus(nCh: Integer; nConnect: Integer);
    procedure ShowModelNgMsg(sMsg : string);
    procedure CreatePwrGui;
    procedure InitDfs;
  public
    { Public declarations }
  end;

var
  frmMain_Pocb: TfrmMain_Pocb;

implementation

{$R *.dfm}

uses DefCam, PlcDisplayAlarm;

procedure TfrmMain_Pocb.AutoStart(nJig, nJigCh: Integer; sErr : string);
var
  nRealJig : Integer;
  nPauseProbe : Integer;
begin
  nRealJig := nJig mod 2;
  nPauseProbe := nJig div 2;
  if frmTest4ChPocb[nRealJig] = nil then Exit;

  // 0.B일 경우.
  if nPauseProbe = 0 then begin
    frmTest4ChPocb[nRealJig].AutoLogicStart;
  end;
  // Carrier detect & Load complete OK checking ==> Only NG.
  if nPauseProbe = 1 then begin
    frmTest4ChPocb[nRealJig].ShowPlcNgMeg(nJigCh,sErr);
  end;
end;

procedure TfrmMain_Pocb.btnAutoReadyClick(Sender: TObject);
begin
  if PlcPocb <> nil then begin
    if btnAutoReady.Tag = 0 then begin
      btnAutoReady.Caption := 'STOP AUTO MODE';
      btnAutoReady.Tag      := 1;
      pnlPlcReady.Caption   := 'ABB Robot Auto Mode (PLC)';
      pnlPlcReady.Color     := clGreen;//$00FFDFBF;
      pnlPlcReady.Font.Color := clYellow; //clBlack;
      PlcPocb.writePlc(defPlc.PLC_WRITE_ABB_AUTO_MODE,False);
      PlcPocb.IsPlcAbbMode := True;
    end
    else begin
      btnAutoReady.Caption := 'READY AUTO MODE';
      btnAutoReady.Tag      := 0;
      pnlPlcReady.Caption   := 'Manual Mode (PLC)';
      pnlPlcReady.Color     := clBlue;//$00FFDFBF;
      PlcPocb.writePlc(defPlc.PLC_WRITE_ABB_AUTO_MODE,True);
      PlcPocb.IsPlcAbbMode := False;
    end;
  end
  else begin

  end;
end;

procedure TfrmMain_Pocb.btnExitClick(Sender: TObject);
begin

  Close;
end;

procedure TfrmMain_Pocb.btnInitClick(Sender: TObject);
var
  sMsg, sDebug : string;
  i : integer;
begin

  sMsg :=        #13#10 + 'bạn có muốn khởi tạo chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to initialize this Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    sDebug := '[Click Event] Initialize';
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
    InitialAll;
  end;
end;

procedure TfrmMain_Pocb.btnLogInClick(Sender: TObject);
var
  i, nRet: Integer;
begin
  if Trim(Common.SystemInfo.ServicePort) <> '' then begin

    if DongaGmes <> nil then begin
      if Common.SystemInfo.OcManualType then  begin
        if Trim(Common.SystemInfo.ServicePort) <> '' then begin
          nRet := DisplayLogIn;
          if nRet = mrCancel then begin
            DongaGmes.Free;
            DongaGmes := nil;
            btnLogIn.Caption := 'đăng nhập (Log In)';
            Common.m_sUserId := 'PM';
            pnlUserId.Caption := Common.m_sUserId;
            pnlUserName.Caption := '';
            pnlMesReady.Caption := 'MES OFF';
            pnlMesReady.Color := $000050F7;
            Exit;
          end
          else begin
            {$IFDEF DFS_HEX}
            InitDfs;
            {$ENDIF}
            if Common.m_sUserId = 'PM' then begin
              DongaGmes.Free;
              DongaGmes := nil;
              pnlHost.Caption := 'PM Mode';
              ledGmes.FalseColor := clGray;
              ledGmes.Value := False;
              pnlUserId.Caption := 'PM';
              pnlUserName.Caption := '';
              pnlMesReady.Caption := 'MES OFF';
              pnlMesReady.Color := $000050F7;
            end
            else begin
              if DongaGmes is TGmes then begin
                DongaGmes.MesUserId := Common.m_sUserId;
                if not DongaGmes.MesEayt then DongaGmes.SendHostUchk
                else                          DongaGmes.SendHostEayt;
              end
              else begin
                InitGmes;
                if frmTest4ChPocb[DefCommon.JIG_A] <> nil then begin
                  DongaGmes.hTestHandle1 := frmTest4ChPocb[DefCommon.JIG_A].Handle;
                end;
                if frmTest4ChPocb[DefCommon.JIG_B] <> nil then begin
                  DongaGmes.hTestHandle2 := frmTest4ChPocb[DefCommon.JIG_B].Handle;
                end;
              end;
            end;
          end;
        end;
      end
      else begin
        DongaGmes.Free;
        DongaGmes := nil;
        btnLogIn.Caption := 'đăng nhập (Log In)';
        Common.m_sUserId := 'PM';
        pnlUserId.Caption := Common.m_sUserId;
        pnlUserName.Caption := '';
        for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
          frmTest4ChPocb[i].SetHostConnShow(False);
        end;
        pnlMesReady.Caption := 'MES OFF';
        pnlMesReady.Color := $000050F7;
      end;
    end
    else begin
      if Common.SystemInfo.OcManualType then  begin
        if Trim(Common.SystemInfo.ServicePort) <> '' then begin
          nRet := DisplayLogIn;
          if nRet = mrCancel then begin
            Exit;
          end
          else begin
            if Common.m_sUserId = 'PM' then begin
              pnlHost.Caption := 'PM Mode';
              ledGmes.FalseColor := clGray;
              ledGmes.Value := False;
              pnlUserId.Caption := 'PM';
              pnlUserName.Caption := '';
              pnlMesReady.Caption := 'MES OFF';
              pnlMesReady.Color := $000050F7;
              if DongaGmes <> nil then begin
                DongaGmes.Free;
                DongaGmes := nil;
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
                if frmTest4ChPocb[DefCommon.JIG_A] <> nil then begin
                  DongaGmes.hTestHandle1 := frmTest4ChPocb[DefCommon.JIG_A].Handle;
                end;
                if frmTest4ChPocb[DefCommon.JIG_B] <> nil then begin
                  DongaGmes.hTestHandle2 := frmTest4ChPocb[DefCommon.JIG_B].Handle;
                end;
              end;
            end;
          end;
        end;
      end
      else begin
        {$IFDEF DFS_HEX}
          InitDfs;
        {$ENDIF}
        InitGmes;
        if frmTest4ChPocb[DefCommon.JIG_A] <> nil then begin
          DongaGmes.hTestHandle1 := frmTest4ChPocb[DefCommon.JIG_A].Handle;
        end;
        if frmTest4ChPocb[DefCommon.JIG_B] <> nil then begin
          DongaGmes.hTestHandle2 := frmTest4ChPocb[DefCommon.JIG_B].Handle;
        end;
      end;
    end;
  end
  else begin
    btnLogIn.Caption := 'đăng nhập (Log In)';
    ShowMessage('Please input correct GMES Configration');
  end;
//  if CheckPgRun then Exit;

end;

procedure TfrmMain_Pocb.btnMaintClick(Sender: TObject);
var
  i : Integer;
  sDebug : string;
begin
  if CheckScriptRun then Exit;
  if CheckAdminPasswd then begin
    ReleaseReadyModOnPlc;
    sDebug := '[Click Event] Maint';
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
//    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then TStyleManager.SetStyle('Windows10');
    frmMainter := TfrmMainter.Create(Application);
    try
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        PasScr[i].m_bMaintWindowOn := True;
      end;
      frmMainter.ShowModal;
    finally
      frmMainter.Free;
      frmMainter := nil;
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        PasScr[i].m_bMaintWindowOn := False;
      end;
    end;
//    if Common.m_bIsChanged or (Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR) then begin
//      InitialAll;
//    end;
  end;
end;

procedure TfrmMain_Pocb.btnModelChangeClick(Sender: TObject);
var
  bChangeModel : Boolean;
  sOldModel, sDebug : string;
  i : Integer;
begin
  if CheckScriptRun then Exit;

  if CheckPgRun then Exit;
  ReleaseReadyModOnPlc;
  if not CheckAdminPasswd then Exit;
  sOldModel := Common.SystemInfo.TestModel;
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
    sDebug := '[Click Event] M/C : Old Model - '+sOldModel +' ===> New Model - ' + Common.SystemInfo.TestModel;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);

    // Fusing model Data.
    Common.LoadModelInfo(Common.SystemInfo.TestModel);
    frmModelDownload := TfrmModelDownload.Create(Self);
    try
      frmModelDownload.ShowModal;
    finally
      frmModelDownload.Free;
      frmModelDownload := nil;
    end;
    InitialAll;
  end;
  DisplayScriptInfo;
end;

procedure TfrmMain_Pocb.btnModelClick(Sender: TObject);
var
  i : Integer;
  sDebug : string;
begin
  if CheckScriptRun then Exit;

  if CheckAdminPasswd then begin
    ReleaseReadyModOnPlc;
    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then TStyleManager.SetStyle('Windows10');

    frmModelInfo := TfrmModelInfo.Create(nil);
    try
      frmModelInfo.ShowModal;
    finally
      Freeandnil(frmModelInfo);
    end;
    if Common.m_bIsChanged or (Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR) then begin
      sDebug := '[Click Event] Model Info';
      for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
      InitialAll;
    end;
//    Common.LoadModelInfo(Common.SystemInfo.TestModel);
//    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then begin
//      initform;
////      Common.Delay(2000);
//    end;
//    DisplayScriptInfo;
  end;
end;

procedure TfrmMain_Pocb.btnStationClick(Sender: TObject);
var
  i : Integer;
  sDebug : string;
begin
  if CheckScriptRun then Exit;
  ReleaseReadyModOnPlc;
  if CheckAdminPasswd then begin
    sDebug := '[Click Event] System Info';
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
//    if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then TStyleManager.SetStyle('Windows10');
    frmSystemSetup := TfrmSystemSetup.Create(nil);
    try
      frmSystemSetup.ShowModal;
    finally

      frmSystemSetup.Free;
      frmSystemSetup := nil;
    end;
    if Common.m_bIsChanged {or (Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR)} then begin
      InitialAll;
    end;
//    initForm;
//    for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
//      // Distroy current alloc class
//      if frmTest4ChGB[i] <> nil then begin
//        frmTest4ChGB[i].SetConfig;
//      end;
//    end;
  end;
end;

function TfrmMain_Pocb.CheckAdminPasswd: boolean;
var
  bRet : boolean;
begin
  bRet := False;
  frmLogIn := TfrmLogIn.Create(Self);
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

function TfrmMain_Pocb.CheckPgRun: Boolean;
var
  i     : Integer;
  bRtn  : Boolean;
  sData : string;
begin
  bRtn := False;  sData := '';
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
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

function TfrmMain_Pocb.CheckScriptRun : Boolean;
var
  i: Integer;
  bRet : Boolean;
begin
  bRet := False;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChPocb[i] <> nil then begin
      if frmTest4ChPocb[i].CheckScriptRun then begin
        bRet := True;
        Break;
      end;
    end;
  end;
  if bRet then begin
    ShowMessage('Script is Running!!!');
  end;
  Result := bRet;
end;

procedure TfrmMain_Pocb.CheckScriptRunWithPlc;
var
  bRet : boolean;
  i : Integer;
begin
  bRet := True;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    // 한놈이라도 움직이고 있으면 빠지자...
    if PasScr[i].m_bIsScriptWork then begin
      bRet := False;
      Break;
    end;
  end;
  if PlcPocb <> nil then begin
    PlcPocb.writePlc(defPlc.PLC_WRITE_VISUAL_INSPECT,bRet);
  end;

end;

procedure TfrmMain_Pocb.CMStyleChanged(var Message: TMessage);
var
  i : Integer;
begin
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChPocb[i] <> nil then begin
      frmTest4ChPocb[i].SetHandleAgain(Self.Handle);
    end;
  end;
end;

procedure TfrmMain_Pocb.CreateClassData;
begin
  // UDP 서버 IP 192.168.0.11
  // 내부적으로 Common file을 읽어 오기 대문에 반드시 Common Create 이후 호출.
  UdpServer := TUdpServerVh.Create(Self.Handle, DefCommon.MAX_PG_CNT);
  InitForm;
  tmrDisplayTestForm.Interval := 100;
  tmrDisplayTestForm.Enabled := True;
  m_bUnloadCheck := False;
  m_bCamCheck := False;

//
  Script := TScript.Create(Common.Path.MODEL_CUR + Common.SystemInfo.TestModel + '.isu');//TScript.Create(Common.Path.MODEL + Common.SystemInfo.TestModel + '.script');
  DisplayScriptInfo;
//
  DongaHandBcr := TSerialBcr.Create(Self);
  DongaHandBcr.OnRevBcrConn := GetBcrConnStatus;
  DongaHandBcr.ChangePort(Common.SystemInfo.Com_HandBCR);

  pnlStationNo.Caption := Common.SystemInfo.EQPId;
  tmrMemCheck.Enabled := True;
  CreatePwrGui;
  m_nCamPos := 0;
  m_nLoadPos := 0;
end;

procedure TfrmMain_Pocb.CreatePwrGui;
var
  nItemHeight : Integer;
  sTemp : string;
begin
  nItemHeight := 26;
  grpPwrInfo.Height := nItemHeight*7;
  lstPwrView := TAdvListView.Create(self);
  lstPwrView.Parent := grpPwrInfo;
  lstPwrView.Top :=  20;
  lstPwrView.Left := 2;
  lstPwrView.Height := nItemHeight*6 - 10;
  lstPwrView.Width := grpPwrInfo.Width -3 ;//180;
  lstPwrView.Font.Size := 8;
  lstPwrView.ViewStyle := vsReport;
  lstPwrView.Columns.Add.Caption := 'Power';
  lstPwrView.Columns.Add.Caption := 'Voltage';
  lstPwrView.Columns[0].Width := (grpPwrInfo.Width -6) div 2 - 1;
  lstPwrView.Columns[1].Width := (grpPwrInfo.Width -8) div 2 - 1;
  with lstPwrView do begin
    with Items.Add do begin
      Caption := 'VPNL';//'VCI';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VCI] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VDDI';//'DVDD';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_DVDD] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'T_AVDD';//'VDD';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VDD] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VPP';//'VPP';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VPP] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VBAT';//'VBAT';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VBAT] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VCI';//'VNEG';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VNEG] / 100]);
      SubItems.Add(sTemp);
    end;
  end;
end;

function TfrmMain_Pocb.DisplayLogIn: Integer;
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

procedure TfrmMain_Pocb.DisplayScriptInfo;
begin
  pnlResolution.Caption := Format(' %d(H) x %d(V)',[Common.TestModelInfo.H_Active, Common.TestModelInfo.V_Active]);
  pnlPatternGroup.Caption :=  Common.TestModelInfo2.PatGrpName;
  pnlModelNameInfo.Caption := Common.SystemInfo.TestModel;

  pnlPsuVer.Caption    := Common.m_Ver.psu_Date+'('+Common.m_Ver.psu_Crc+')';
  pnlIsuVer.Caption    := Common.m_Ver.isu_Date;
  pnlZxis.Caption := Format('  / %d',[ Common.TestModelInfo2.Zxis]);
//  pnlCheckSum.Caption  :=  Common.TestModelInfo2.CheckSum + '/'+ Common.SystemInfo.ScriptCrc;
//  pnlScriptVer.Caption :=  Common.SystemInfo.ScriptVer;
end;

procedure TfrmMain_Pocb.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  sMsg, sDebug : string;
  i    : Integer;
begin
   sMsg := #13#10 + 'bạn có muốn thóat chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to Exit Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    sDebug := '[Click Event] Terminate ISPD Program';
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
    Common.TaskBar(False);
    InitialAll(False);
    CanClose := True;
  end
  else
    CanClose := False;
end;

procedure TfrmMain_Pocb.FormCreate(Sender: TObject);
var
  i : Integer;
  sDebug : string;

begin
//  Self.WindowState := wsMaximized;// wsNormal;
  Common := TCommon.Create;
  Common.m_sUserId := 'PM';
  pnlUserId.Caption := Common.m_sUserId;
  pnlUserName.Caption := '';
  btnLogIn.Visible := True;
  sDebug := '#################################### Turn On ISPD Program (';
  sDebug := sDebug + Common.GetVersionDate + ') ####################################';
  for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
  MakePlcSig;

  CreateClassData;
  // 현재 설정 되어 있는 Local IP Display 하자.
  pnlStLocalIp.Caption := Common.GetLocalIpList;
//  Common.MLog(DefCommon.MAX_SYSTEM_LOG,'1');
  Self.Caption := DefCommon.PROGRAM_NAME + ' Version ' + Common.GetVersionDate;
  //Common.TaskBar(True);
  // Added by ClintPark 2018-11-23 오후 2:03:48  GIB Use GMES.
  pnlSubTool.Visible   := True;

  pnlMesReady.Font.Color :=  clYellow;// clBlack;
  pnlMesReady.Color       := $000050F7;//$00FF80FF;//clBtnFace;

  if common.SystemInfo.OcManualType then begin
    pnlPlcReady.Visible     := False;
    pnlPlcReady.Font.Color  := clYellow;
    pnlPlcReady.Color       := clMaroon;//$000050F7;//$00FF80FF;//clBtnFace;
  end;
  m_sPlcModelZAxis := '';

  tmrCpuCheck.Enabled := True;


end;

procedure TfrmMain_Pocb.GetBcrConnStatus(bConnected: Boolean; sMsg: string);
begin
  if sMsg = 'NONE' then begin
    ledHandBcr.FalseColor := clGray;
  end
  else begin
    ledHandBcr.FalseColor := clRed;
  end;
  pnlHandBcr.Caption := sMsg;
  ledHandBcr.Value   := bConnected;
end;


procedure TfrmMain_Pocb.GetCamConnStatus(nCh, nConnect: Integer);
var
  sTemp : string;
begin
  sTemp := Format('ledCam%d',[nCh+1]);
  case nConnect of
    DefCam.CAM_CONNECT_FIRST_OK : begin
      (FindComponent(sTemp) as ThhALed).TrueColor := clLime;
      (FindComponent(sTemp) as ThhALed).Value := True;
    end;
    DefCam.CAM_CONNECT_OK : begin
      (FindComponent(sTemp) as ThhALed).TrueColor := clLime;//clYellow;
      (FindComponent(sTemp) as ThhALed).Value := True;
    end;
    DefCam.CAM_CONNECT_NG : begin
      (FindComponent(sTemp) as ThhALed).Value := False;
    end;
  end;
end;

procedure TfrmMain_Pocb.InitDfs;
var
  sIp, sUsrName, sPw : string;
  nCh : Integer;
  sDebug : string;
begin
  DfsFtpConnOK := False; //2019-04-09
  if Common.DfsConfInfo.bUseDfs then begin
    if DfsFtpCommon <> nil then begin
      if DfsFtpCommon.IsConnected then DfsFtpCommon.Disconnect;
      DfsFtpCommon.Free;
      DfsFtpCommon := nil;
    end;
    for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if DfsFtpCh[nCh] <> nil then begin
        DfsFtpCh[nCh].Free;
        DfsFtpCh[nCh] := nil;
      end;
    end;
    pnlSysinfoDfs.Caption    := 'Disconnected';
//    pnlSysinfoDfs.Font.Color := clYellow;
    ledDfs.TrueColor  := clLime;
    ledDfs.FalseColor := clRed;
    ledDfs.Value   := False;

    sIp       := Common.DfsConfInfo.sDfsServerIP;
    sUsrName  := Common.DfsConfInfo.sDfsUserName;
    sPw       := Common.DfsConfInfo.sDfsPassword;
    if Trim(sIp) = ''       then Exit;
    if Trim(sUsrName) = ''  then Exit;
    if Trim(sPw) = ''       then Exit;

    DfsFtpCommon := TDfsFtp.Create(sIp, sUsrName, sPw, -1{nCh:dummy for DfsFtpCommon});
    DfsFtpCommon.m_hMain := Self.Handle;
    DfsFtpCommon.Connect;
    for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
      DfsFtpCh[nCh] := TDfsFtp.Create(sIp, sUsrName, sPw, nCh);
      DfsFtpCh[nCh].m_hMain := Self.Handle;
    end;
    //
    if Common.DfsConfInfo.bUseCombiDown and DfsFtpCommon.IsConnected then begin
      DfsFtpCommon.DownloadCombiFile;
      ledDfs.Value   := True;
    end;
    DfsFtpCommon.Disconnect;
  end
  else begin
    pnlSysinfoDfs.Caption := '';
//    pnlSysinfoDfs.Color   := clBtnFace;
    ledDfs.FalseColor := clGray;
    ledDfs.Value   := False;
    if DfsFtpCommon <> nil then begin
      if DfsFtpCommon.IsConnected then begin

        DfsFtpCommon.Disconnect;
      end;
      DfsFtpCommon.Free;
      DfsFtpCommon := nil;
    end;
    for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if DfsFtpCh[nCh] <> nil then begin
        DfsFtpCh[nCh].Free;
        DfsFtpCh[nCh] := nil;
      end;
    end;
  end;
  if Common.DfsConfInfo.bUseDfs then begin
    RzgrpDFS.visible := True;

    pnlCombiModelRCP.Caption      := Common.CombiCodeData.sRcpName;
    pnlCombiProcessNo.Caption     := Common.CombiCodeData.sProcessNo;
    pnlCombiRouterNo.Caption      := IntToStr(Common.CombiCodeData.nRouterNo); //2019-04-07

    sDebug := Format('sRcpName(%s),ProcessNo(%s),RouterNo(%d)',[Common.CombiCodeData.sRcpName,Common.CombiCodeData.sProcessNo,Common.CombiCodeData.nRouterNo]);
    Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  end
  else begin
    RzgrpDFS.visible := False;
  end;
end;

procedure TfrmMain_Pocb.initform;
begin
  case Common.SystemInfo.UIType of
    Defcommon.UI_WIN10_NOR  : TStyleManager.SetStyle('Windows10');
    Defcommon.UI_WIN10_BLACK : TStyleManager.SetStyle('Windows10 Dark')
    else begin
      TStyleManager.SetStyle('Windows10');
    end;
  end;
  grpPlc.Visible          := not Common.SystemInfo.OcManualType;

end;

Function TfrmMain_Pocb.InitGmes : Boolean;
var
  sService, sNetWork, sDeamon : string;
  sLocal, sRemote, sHostPath  : string;
  bRtn, nEasRtn               : Boolean;
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
  DongaGmes.MesUserId := '602462';// Common.m_sUserId;
  Common.m_sUserId := 'PM';

  pnlUserId.Caption := Common.m_sUserId;
  pnlUserName.Caption := '';
  DongaGmes.MesSystemNo   := Common.SystemInfo.EQPId;
  bRtn := DongaGmes.HOST_Initial(sService, sNetWork, sDeamon,sLocal,sRemote ,sHostPath);
  ledGmes.Value := bRtn;
  nEasRtn := True;
{$IFDEF EAS_USE}
  // EAS Open.
  sService    := Common.SystemInfo.Eas_Service;
  sNetWork    := Common.SystemInfo.Eas_Network;
  sDeamon     := Common.SystemInfo.Eas_DeamonPort;
  sLocal      := Common.SystemInfo.LocalSubject;
  sRemote     := Common.SystemInfo.Eas_RemoteSubject;
  sHostPath   := Common.Path.GMES;
  if ((Trim(sService) = '') or (Trim(sNetWork) = '') or (Trim(sDeamon) = '') or (sRemote = '')) then begin
    nEasRtn := False;
  end
  else begin
    nEasRtn := DongaGmes.Eas_Initial(sService, sNetWork, sDeamon,sLocal,sRemote ,sHostPath);
    if nEasRtn then begin
      pnlHost.Caption := 'EAS Connected';
    end
    else begin
      pnlHost.Caption := 'EAS Disonnected';
    end;
  end;
{$ENDIF}

  if bRtn and nEasRtn then begin
    pnlHost.Caption := 'Connected';
    DongaGmes.FtpAddr := Common.SystemInfo.HOST_FTP_IPAddr;
    DongaGmes.FtpUser := Common.SystemInfo.HOST_FTP_User;
    DongaGmes.FtpPass := Common.SystemInfo.HOST_FTP_Passwd;
    DongaGmes.FtpCombiPath := Common.SystemInfo.HOST_FTP_CombiPath;
    // EAYT Start....
    DongaGmes.SendHostStart;
  end
  else begin
    pnlHost.Caption := 'Disonnected';
  end;
end;

procedure TfrmMain_Pocb.InitialAll(bReset: Boolean);
var
  i : Integer;
begin

{$IFDEF ALGO_DLL}
  tmrMemCheck.Enabled := False;
  if Jncd <> nil then begin
    Jncd.Free;
    Jncd := nil;
  end;
{$ENDIF}
  if CamCommTri <> nil then begin
    CamCommTri.Free;
    CamCommTri := nil;
  end;
  ReleaseReadyModOnPlc;

  if DfsFtpCommon <> nil then begin
    if DfsFtpCommon.IsConnected then DfsFtpCommon.Disconnect;
    DfsFtpCommon.Free;
    DfsFtpCommon := nil;
  end;

  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if DfsFtpCh[i] <> nil then begin
      DfsFtpCh[i].Free;
      DfsFtpCh[i] := nil;
    end;
  end;

  if DongaGmes <> nil then begin
    btnLogIn.Caption := 'đăng nhập (Log In)';
    DongaGmes.Free;
    DongaGmes := nil;
  end;

  if PlcPocb <> nil then begin
    PlcPocb.Free;
    PlcPocb := nil;
  end;
  if DongaHandBcr <> nil then begin
    DongaHandBcr.Free;
    DongaHandBcr := nil;
  end;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    // Distroy current alloc class
    if frmTest4ChPocb[i] <> nil then begin
      frmTest4ChPocb[i].Free;
      frmTest4ChPocb[i] := nil;
    end;
  end;

  // NG Msg close.
  if frmModelNgMsg <> nil then begin
    frmModelNgMsg.Free;
    frmModelNgMsg := nil;
  end;
  if frmDisplayAlarm <> nil then begin
    frmDisplayAlarm.Free;
    frmDisplayAlarm := nil;
  end;
  if frmNgMsg <> nil then begin
    frmNgMsg.Free;
    frmNgMsg := nil;
  end;

  if UdpServer <> nil then begin
    UdpServer.Free;
    UdpServer := nil;
  end;
  if Script <> nil then begin
    Script.Free;
    Script := nil;
  end;

  if Common is TCommon then begin
    Common.Free;
    Common := nil;
  end;
  if lstPwrView <> nil then begin
    lstPwrView.Free;
    lstPwrView := nil;
  end;
  Sleep(1000);
  if bReset then begin

    // Create Again.
    Common :=	TCommon.Create;
    CreateClassData;
  end;
end;

procedure TfrmMain_Pocb.InitMainTool(bEnable: Boolean);
begin
  btnModelChange.Enabled := bEnable;
  btnModel.Enabled  := bEnable;
end;

function TfrmMain_Pocb.IsHeaderExist(asHeaders: array of string): Boolean;
var
  i : Integer;
  bRet : boolean;
begin
  bRet := False;
  for i := 0 to Pred(DefCommon.MAX_CSV_HEADER_ROWS) do begin
    if Trim(asHeaders[i]) <> '' then begin
      bRet := True;
      Break;
    end;
  end;
  Result := bRet;

end;

procedure TfrmMain_Pocb.MainPlcStatus(bIn, nConnectCheck : Boolean; nLen: Integer; naReadData: array of Integer);
var
  i, j, nModelIdx : Integer;
  dwTemp : DWORD;
begin
  if bIn then begin
    if nConnectCheck then begin
      dwTemp := 1;
      if (dwTemp and naReadData[0]) <> 0 then begin
        ledPlcIn[0].LedOn := True;
      end
      else begin
        ledPlcIn[0].LedOn := False;
      end;
    end
    else begin
      for j := 0 to Pred(defPlc.MAX_IN_CNT) do begin
        dwTemp := 1 shl j;
        if (dwTemp and naReadData[0]) <> 0 then begin
          ledPlcIn[j].LedOn := True;
        end
        else begin
          ledPlcIn[j].LedOn := False;
          case j of
            1 : begin
              //PLC Error Bit((D1300.01)가 클리어 되었으면 알람창 닫기
              if frmDisplayAlarm <> nil  then begin
                frmDisplayAlarm.Close;
              end;
            end;
          end;
        end;
      end;
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        if PasScr[i] <> nil then begin
          PasScr[i].m_nPlcReadData := naReadData[1];
        end;

      end;

      // Model Info.
      nModelIdx := naReadData[2];
      pnlZxis.Caption := Format('%d / %d',[nModelIdx, Common.TestModelInfo2.Zxis]);

      // NG Msg.
      if nModelIdx <> Common.TestModelInfo2.Zxis then begin
        m_sPlcModelZAxis := Format('Z-Axis NG : PLC(%d) / GPC(%d)',[nModelIdx, Common.TestModelInfo2.Zxis]);
        tmAlarmMsg.Interval := 100;
        tmAlarmMsg.Enabled := True;
      end
      else begin
        m_sPlcModelZAxis := '';
        tmAlarmMsg.Enabled := False;
        if frmModelNgMsg <> nil  then begin
          frmModelNgMsg.Close;
        end;
      end;

      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        if PasScr[i] <> nil then begin
          if (naReadData[1] and (1 shl (i + 8))) > 0 then begin
            PasScr[i].m_bPlcDetect := True;
          end
          else begin
            PasScr[i].m_bPlcDetect := False;
            PlcPocb.writePlc(defPlc.PLC_WRITE_NG_RET_CH1 shl i,True);
          end;
        end;
      end;
      for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
        if frmTest4ChPocb[i] <> nil then begin
//          // 감지 Sensor 관련 Test GUI에 Display.

          for j := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            if (naReadData[1] and (1 shl (j + 4*i))) > 0 then begin
              frmTest4ChPocb[i].pnlPlcClampDn[j].Color := clLime;
              frmTest4ChPocb[i].pnlPlcClampDn[j].Font.Color := clBlack;
            end
            else begin
              if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
                frmTest4ChPocb[i].pnlPlcClampDn[j].Color   := clBlack;
                frmTest4ChPocb[i].pnlPlcClampDn[j].Font.Color := clWhite;
              end
              else begin
                frmTest4ChPocb[i].pnlPlcClampDn[j].Color   := clBtnFace;
                frmTest4ChPocb[i].pnlPlcClampDn[j].Font.Color := clBlack;
              end;
            end;

            if (naReadData[1] and (1 shl (j + 4*i + 8))) > 0 then begin
              frmTest4ChPocb[i].pnlPlcCarrierDetect[j].Color := clLime;
              frmTest4ChPocb[i].pnlPlcCarrierDetect[j].Font.Color := clBlack;
            end
            else begin
              if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
                frmTest4ChPocb[i].pnlPlcCarrierDetect[j].Color   := clBlack;
                frmTest4ChPocb[i].pnlPlcCarrierDetect[i].Font.Color := clWhite;
              end
              else begin
                frmTest4ChPocb[i].pnlPlcCarrierDetect[j].Color   := clBtnFace;
                frmTest4ChPocb[i].pnlPlcCarrierDetect[j].Font.Color := clBlack;
              end;
            end;
          end;

          // Position 변경시.
          if (naReadData[0] and defPlc.PLC_READ_JIG_A_FRONT_POS) > 0 then begin
            case i of
              DefCommon.JIG_A : begin
                frmTest4ChPocb[i].pnlJigTitle.Caption := 'FRONT';
                frmTest4ChPocb[i].Top := m_nLoadPos;
                // Start시.
                if (naReadData[0] and defPlc.PLC_READ_AUTO_START_REQ) > 0  then begin
                  if btnAutoReady.Tag = 1 then begin
                    frmTest4ChPocb[i].AutoLogicStart;
                  end;
                end
                else begin
                  frmTest4ChPocb[i].UnloadScriptStart;
                end;
              end;
              DefCommon.JIG_B : begin
                frmTest4ChPocb[i].pnlJigTitle.Caption := 'BACK';
                frmTest4ChPocb[i].Top := m_nCamPos;
                if CamCommTri <> nil then begin
                  CamCommTri.m_nCurJig := i;
                  CamCommTri.m_hTest   := frmTest4ChPocb[i].Handle;
                end;
                if PlcPocb <> nil then begin
                  PlcPocb.m_nCurJig := i;
                end;
                if (naReadData[0] and defPlc.PLC_READ_SHUTTER_DOWN) > 0 then begin
                  frmTest4ChPocb[i].CamScriptStart;
                end;
              end;
            end;
          end
          else if (naReadData[0] and defPlc.PLC_READ_JIG_B_FRONT_POS) > 0 then begin
            case i of
              DefCommon.JIG_A : begin
                frmTest4ChPocb[i].pnlJigTitle.Caption := 'BACK';
                frmTest4ChPocb[i].Top := m_nCamPos;
                if CamCommTri <> nil then begin
                  CamCommTri.m_nCurJig := i;
                  CamCommTri.m_hTest   := frmTest4ChPocb[i].Handle;
                end;
                if PlcPocb <> nil then begin
                  PlcPocb.m_nCurJig := i;
                end;
                if (naReadData[0] and defPlc.PLC_READ_SHUTTER_DOWN) > 0 then begin

                  if not m_bCamCheck then begin
                    frmTest4ChPocb[i].CamScriptStart;
                    m_bCamCheck := True;
                  end;

                end;
              end;
              DefCommon.JIG_B : begin
                // Start시.
                if (naReadData[0] and defPlc.PLC_READ_AUTO_START_REQ) > 0  then begin
                  if btnAutoReady.Tag = 1 then begin
                    frmTest4ChPocb[i].AutoLogicStart;
                  end;
                end
                else begin
                  if not m_bUnloadCheck then begin
                    m_bUnloadCheck := True;
                    frmTest4ChPocb[i].UnloadScriptStart;
                  end;

                end;
                frmTest4ChPocb[i].pnlJigTitle.Caption := 'FRONT';
                frmTest4ChPocb[i].Top := m_nLoadPos;
              end;
            end;
          end
          else if (naReadData[0] and defPlc.PLC_READ_TURN_MOVE) > 0 then  begin
            case i of
              DefCommon.JIG_A : frmTest4ChPocb[i].pnlJigTitle.Caption := 'Moving';
              DefCommon.JIG_B : frmTest4ChPocb[i].pnlJigTitle.Caption := 'Moving';
            end;
            m_bUnloadCheck := False;
            m_bCamCheck := False;
          end;
        end;
      end;
    end;

  end
  else begin
    for j := 0 to Pred(defPlc.MAX_OUT_CNT) do begin
      dwTemp := 1 shl j;
      if (dwTemp and naReadData[0]) <> 0 then begin
        ledPlcOut[j].LedOn := True;
      end
      else begin
        ledPlcOut[j].LedOn := False;
      end;
    end;
    if ((defPlc.PLC_WRITE_ABB_AUTO_MODE shr 16) and naReadData[1]) > 0 then begin
      ledPlcOut[8].LedOn := True;
    end
    else begin
      ledPlcOut[8].LedOn := False;
    end;

    CheckScriptRunWithPlc;
  end;

  MakePlcLog;
end;

//procedure TfrmMain_Pocb.MakeCsvData(var sFileName : string; var sHeader : string;var sData: string; nCh : Integer);
//var
//  sPgVer : string;
//  sTemp,sTemp2,sTemp3 : string;
//begin
//  // PG[nCh].m_sFwVer ==> ,P124,F409,M54D,PW21
//  sPgVer := Trim(Copy(PG[nCh].m_sFwVer,2,4));
//  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,7,4));
//  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,12,4));
//  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,17,4));
//  // for data.
//  sTemp := FormatDateTime('yyyymmdd hh:nn:ss', PasScr[nCh].m_TestRet.StartTime);
//
//  // for Header.
//  sHeader := Format('%s,%s,%s,%s,%s',['Date/Time','User_ID','S/W_VER','Script_VER','PG_FW/FPGA/MDM/PWR']);
//  sHeader := sHeader+ format(',%s,%s,%s,',['End_Time','Total_Time(sec)','OC Time(sec)']);
//  sHeader := sHeader+ format(',%s,%s,%s,%s,%s',['Result', 'Channel','Carrier_ID','Panel_ID','Before_OTP_Count']);
//  sHeader := sHeader + PasScr[nCh].m_TestRet.csvHeader;
////  sHeader := sHeader + Chr(13)+'1,2222'+Chr(13)+'2,1111';
//
//  // 'Date/Time','User_ID','S/W_VER','Script_VER','PG_FW/FPGA/MDM/PWR'
//  sData := format('%s,%s,%s,(%s),%s',[sTemp,Common.m_sUserId,Common.GetVersionDate, common.SystemInfo.ScriptVer,sPgVer]);
//  // 'End_Time','Total_Time(sec)','OC Time(sec)'
//  sTemp := FormatDateTime('HH:NN:SS', PasScr[nCh].m_TestRet.EndTime);
//  sTemp2 := Format('%d',[SecondsBetween(PasScr[nCh].m_TestRet.StartTime,PasScr[nCh].m_TestRet.EndTime)]);
//  // OC Time ==> later....
//  sTemp3 := '1';
//  sData := sData + format(',%s,%s,%s,',[sTemp,sTemp3, sTemp2]);
//
//  //'Result', 'Channel','Carrier_ID','Panel_ID','Before_OTP_Count'
//  sData := sData + format(',%s,%d,%s,%s,%d,',[PasScr[nCh].m_TestRet.Result,nCh + 1,PasScr[nCh].m_TestRet.CarrierId, PasScr[nCh].m_TestRet.SerialNo,PasScr[nCh].m_TestRet.Before_OtpCnt ]);
//  sData := sData + PasScr[nCh].m_TestRet.csvData;
//
//  sFileName := PasScr[nCh].m_sFileCsv;
//end;

procedure TfrmMain_Pocb.MakeOpticCsvData(var sFileName: string; var sHeader: array of string; var sData: string; nCh: Integer);
var
  i,j, nHeaderRow : Integer;
  sPgVer, sTemp, sTemp2 : string;
begin
  // PG[nCh].m_sFwVer ==> ,P124,F409,M54D,PW21
  sPgVer := Trim(Copy(PG[nCh].m_sFwVer,2,4));
  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,7,4));
  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,12,4));
  sPgVer := sPgVer + '/' + Trim(Copy(PG[nCh].m_sFwVer,17,4));

  // for Header.
  sHeader[0] := Format('%s,%s,%s,%s',['Date','User_ID','S/W_VER','PG_FW/FPGA/MDM/PWR']);
  sHeader[0] := sHeader[0]+ Format(',%s,%s',['ICU_VER','PSU_VER']);
  sHeader[0] := sHeader[0]+ Format(',%s,%s',['MES_CSV_VER','Model_Name']);
  sHeader[0] := sHeader[0]+ format(',%s,%s,%s,%s,%s',['Start_Time','End_Time','Total_Time(sec)','OC Time(sec)','Result']);
  sHeader[0] := sHeader[0]+ format(',%s',['ERROR_MESSAGE']);
  sHeader[0] := sHeader[0]+ format(',%s,%s,%s,%s,%s',['PLC_RET','EQP ID', 'Channel','Carrier_ID','Panel_ID']);

//  nHeaderRow := Length(sHeader);

  sHeader[1] := ',,,';
  sHeader[1] := sHeader[1]+ ',,';
  sHeader[1] := sHeader[1]+ ',,';
  sHeader[1] := sHeader[1]+ ',,,,,';
  sHeader[1] := sHeader[1]+ ',,,,,';
  sHeader[1] := sHeader[1]+ ',';

  sHeader[2] := ',,,';
  sHeader[2] := sHeader[2]+ ',,';
  sHeader[2] := sHeader[2]+ ',,';
  sHeader[2] := sHeader[2]+ ',,,,,';
  sHeader[2] := sHeader[2]+ ',,,,,';
  sHeader[2] := sHeader[2]+ ',';

  // for data.
  sTemp := FormatDateTime('yyyymmdd', PasScr[nCh].m_TestRet.StartTime);
  // 'Date/Time','User_ID','S/W_VER','Script_VER','PG_FW/FPGA/MDM/PWR'
  sData := format('%s,%s,%s,%s',[sTemp,Common.m_sUserId,Common.GetVersionDate,sPgVer]);
  sData := sData + format(',%s(%s),%s(%s)',[Common.m_Ver.isu_Date,Common.m_Ver.isu_Crc,Common.m_Ver.psu_Date,Common.m_Ver.psu_Crc]);
  sData := sData + format(',%s,%s',[Common.m_Ver.MES_CSV,Common.SystemInfo.TestModel]);
//  sData := format('%s,%s,%s,(%s),%s,%s',[sTemp,Common.m_sUserId,Common.GetVersionDate, common.SystemInfo.ScriptVer, Common.SystemInfo.TestModel,sPgVer]);

  // 'Start Time.'
  sTemp := FormatDateTime('HH:NN:SS', PasScr[nCh].m_TestRet.StartTime);
  sData := sData + format(',%s',[sTemp]);

  // 'End_Time','Total_Time(sec)','OC Time(sec)'
  sTemp := FormatDateTime('HH:NN:SS', PasScr[nCh].m_TestRet.EndTime);
  sTemp2 := Format('%d',[SecondsBetween(PasScr[nCh].m_TestRet.StartTime,PasScr[nCh].m_TestRet.EndTime)]);
  sData := sData + format(',%s,%s',[sTemp,sTemp2]);

  // OC Time ==>
  sTemp := Format('%d',[SecondsBetween(PasScr[nCh].m_TestRet.StUnitTact,PasScr[nCh].m_TestRet.EdUnitTact)]);
  sData := sData + format(',%s,%s',[sTemp,PasScr[nCh].m_TestRet.Result]);
  sData := sData + format(',%s',[PasScr[nCh].m_TestRet.ERR_Message]);
  //'Result', 'Channel','Carrier_ID','Panel_ID','Before_OTP_Count'
  sData := sData + format(',%d,%s,%d,%s,%s',[PasScr[nCh].m_TestRet.PlcRet,Common.SystemInfo.EQPId,nCh + 1,PasScr[nCh].m_TestRet.CarrierId, PasScr[nCh].m_TestRet.SerialNo ]);


//  sFileName := 'test.csv';  // pus 에서 가져와야 함.
  sFileName := PasScr[nCh].m_sFileCsv;

//  with PasScr[nCh].m_TestRet.InsCsv do begin
    for i := 0 to Pred(pasScr[nCh].m_TestRet.InsCsv.FRowCnt-1) do begin
      for j := 0 to Pred(pasScr[nCh].m_TestRet.InsCsv.FColCnt) do begin
        sHeader[i] := sHeader[i] + ','+trim(pasScr[nCh].m_TestRet.InsCsv.Data[i,j]);
      end;
    end;
    for i := 0 to Pred(PasScr[nCh].m_TestRet.InsCsv.FColCnt) do begin

    sData := sData + ',' + Trim(PasScr[nCh].m_TestRet.InsCsv.Data[Pred(pasScr[nCh].m_TestRet.InsCsv.FRowCnt),i]);
  end;
end;

procedure TfrmMain_Pocb.MakeOpticSummaryCsvLog(sScrFileName : String; sCsvHeader : array of string; sCsvData: string);
var
  sFilePath, sFileName : String;
  txtF                 : Textfile;
begin
  sFilePath := Common.Path.SumCsv+formatDateTime('yyyymm',now) + '\';
  sFileName := sFilePath + sScrFileName;// Common.SystemInfo.EQPId +'_OC_Summary_'+ formatDateTime('yyyymmdd',now) + '.csv';
  if Common.CheckDir(sFilePath) then Exit;
  if IOResult = 0 then begin
    try
      try
        AssignFile(txtF, sFileName);
        try
          // File Check!
          if not FileExists(sFileName) then begin
            Rewrite(txtF);
            WriteLn(txtF, sCsvHeader[0]);
            WriteLn(txtF, sCsvHeader[1]);
            WriteLn(txtF, sCsvHeader[2]);
          end;

          Append(txtF);
          WriteLn(txtF, sCsvData);
        except

        end;
      finally
        // Close the file
        CloseFile(txtF);
      end;
    except

    end;
  end;
end;
procedure TfrmMain_Pocb.MakePlcLog;
var
  i, j : Integer;
  sDebug, sDebug2 : string;
  InData1, InData2, OutData11, OutData21, OutData12, OutData22  : Integer;
  bMakeLog : boolean;
begin
//
//  OutData12 := PlcPocb.m_nWriteSig12;
//  OutData22 := PlcPocb.m_nWriteSig22;
//  bMakeLog := False;
//  //  Input for A Stage.
//  if InData1 <> m_nPlcInPre1      then bMakeLog := True;
//  if bMakeLog then begin
//    sDebug := '[STAGE A IO  INPUT CHECK] :';
//    sDebug2 := '';
//    for i := 0 to defPlc.MAX_INPUT_CNT do begin
//      if i = 1 then Continue;
//
//      if  m_bPlcIn[DefCommon.JIG_A,i] then begin
//        sDebug := sDebug + Format(' %0.2x,',[i]);
//        case i of
//          0 : sDebug2 := sDebug2 + ' PLC_READY';
//          4.. 7 : sDebug2 := sDebug2 + Format(' LOAD_COMPLT%d',[i-3]);
//          9 : sDebug2 := sDebug2 + ' START_INS';
//          10 : sDebug2 := sDebug2 + ' NO_ALARM';
//          11..15 :  sDebug2 := sDebug2 + Format(' UNLOAD_COMPLT%d',[i-10]);
//        end;
//      end;
//    end;
//    sDebug := sDebug + '(' + sDebug2 + ')';
//    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);
//  end;
//  m_nPlcInPre1 := InData1;
//  // Input B Stage.
//  bMakeLog := False;
//  if InData2 <> m_nPlcInPre2      then bMakeLog := True;
//  if bMakeLog then begin
//    sDebug := '[STAGE B IO  INPUT CHECK] :';
//    sDebug2 := '';
//    for i := 0 to defPlc.MAX_INPUT_CNT do begin
//      if i = 1 then Continue;
//
//      if  m_bPlcIn[DefCommon.JIG_B,i] then begin
//        sDebug := sDebug + Format(' %0.2x,',[i]);
//        case i of
//          0 : sDebug2 := sDebug2 + ' PLC_READY';
//          4.. 7 : sDebug2 := sDebug2 + Format(' LOAD_COMPLT%d',[i-3]);
//          9 : sDebug2 := sDebug2 + ' START_INS';
//          10 : sDebug2 := sDebug2 + ' NO_ALARM';
//          11..15 :  sDebug2 := sDebug2 + Format(' UNLOAD_COMPLT%d',[i-10]);
//        end;
//      end;
//    end;
//    sDebug := sDebug + '(' + sDebug2 + ')';
//    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);
//  end;
//  m_nPlcInPre2 := InData2;
//
//  // Stage A Output.
//  bMakeLog := False;
//  if OutData11 <> m_nPlcOutPre11  then bMakeLog := True;
//  if OutData12 <> m_nPlcOutPre12  then bMakeLog := True;
//  if bMakeLog then begin
//    sDebug :='[STAGE A IO OUTPUT CHECK] :';  sDebug2 := '';
//    for j := 0 to defPlc.MAX_OUT_CNT do begin
//      if  m_bPlcOut[DefCommon.JIG_A,j] then begin
//        if j = 1 then Continue;
//        case j of
//          0 : sDebug2 := sDebug2 + ' PC_READY';
//          3 : sDebug2 := sDebug2 + ' PROBE_BACK';
//          5.. 8 : sDebug2 := sDebug2 + Format(' CH%d_SEL',[j-4]);
//          9 : sDebug2 := sDebug2 + ' LOAD_REQ';
//          10 : sDebug2 := sDebug2 + ' FINISH_WORK';
//          11..15 :  sDebug2 := sDebug2 + Format(' NG_CH%d',[j-10]);
//          16.. 19 : sDebug2 := sDebug2 + Format(' CH%d_READY',[j-15]);
//          24.. 27 : sDebug2 := sDebug2 + Format(' CH%d_DETECT',[j-23]);
//        end;
//        sDebug := sDebug + Format(' %0.2x,',[j]);
//      end;
//    end;
//    sDebug := sDebug + '(' + sDebug2 + ')';
//    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);
//
//  end;
//  m_nPlcOutPre11 := OutData11;
//  m_nPlcOutPre12 := OutData12;
//
//  bMakeLog := False;
//  if OutData21 <> m_nPlcOutPre21  then bMakeLog := True;
//  if OutData22 <> m_nPlcOutPre22  then bMakeLog := True;
//  if bMakeLog then begin
//    sDebug :='[STAGE B IO OUTPUT CHECK] :';
//    sDebug2 := '';
//    for j := 0 to defPlc.MAX_OUT_CNT do begin
//      if  m_bPlcOut[DefCommon.JIG_B,j] then begin
//        if j = 1 then Continue;
//        case j of
//          0 : sDebug2 := sDebug2 + ' PC_READY';
//          3 : sDebug2 := sDebug2 + ' PROBE_BACK';
//          5.. 8 : sDebug2 := sDebug2 + Format(' CH%d_SEL',[j-4]);
//          9 : sDebug2 := sDebug2 + ' LOAD_REQ';
//          10 : sDebug2 := sDebug2 + ' FINISH_WORK';
//          11..15 :  sDebug2 := sDebug2 + Format(' NG_CH%d',[j-10]);
//          16.. 19 : sDebug2 := sDebug2 + Format(' CH%d_READY',[j-15]);
//          24.. 27 : sDebug2 := sDebug2 + Format(' CH%d_DETECT',[j-23]);
//        end;
//        sDebug := sDebug + Format(' %0.2x,',[j]);
//      end;
//    end;
//    sDebug := sDebug + '(' + sDebug2 + ')';
//    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);
//  end;
//  m_nPlcOutPre21 := OutData21;
//  m_nPlcOutPre22 := OutData22;
end;

procedure TfrmMain_Pocb.MakePlcSig;
var
  i: Integer;
  nWidth, nHeight, nTopPos : Integer;
  sPlcHint, sTemp : string;
begin
  nWidth := 114;
  nHeight := 26;
  nTopPos := pnlZAxis.Top + pnlZAxis.Height + 1;
  for i := 0 to Pred(defPlc.MAX_IN_CNT*2) do begin
    ledPlcIn[i] := TTILed.Create(Self);
    ledPlcIn[i].Parent := grpPlc;
    ledPlcIn[i].Left := pnlZAxis.Left;
    ledPlcIn[i].Top  := nTopPos + i*(nHeight);
    ledPlcIn[i].Width := nWidth;
    ledPlcIn[i].Height := nHeight;
    ledPlcIn[i].LedColor := TLedColor(Green);
    ledPlcIn[i].StyleElements := [seBorder];
    sTemp := '';
    case i of
      0 : sTemp := 'PLC Connect Ready';
      1 : sTemp := 'PLC ERROR';
      2 : sTemp := 'PLC TURN MOVING';
      3 : sTemp := 'PLC TURN Complete';
      4 : sTemp := 'A Stage Front Pos';
      5 : sTemp := 'B Stage Front Pos';
      6 : sTemp := 'PLC Shuttern Down';
      7 : sTemp := 'PLC Shuttern Up';
      8 : sTemp := 'INSPECT Auto Start';
    //  9 : sTemp := 'Auto / Manual Mode';
    end;
    ledPlcIn[i].Caption := sTemp;
    if sTemp = '' then ledPlcIn[i].Visible := False;

//    sPlcHint := '';
//    if sPlcHint <> '' then ledPlcIn[i].ShowHint := True;
//    ledPlcIn[i].Hint     := sPlcHint;
  end;
  for i := 0 to Pred(defPlc.MAX_OUT_CNT * 2) do begin
    ledPlcOut[i] := TTILed.Create(Self);
    ledPlcOut[i].Parent := grpPlc;
    ledPlcOut[i].Left := nWidth + pnlZAxis.Left + 4;
    ledPlcOut[i].Top  := nTopPos + i*(nHeight);

    sTemp := '';
    case i of
      0 : sTemp := 'PC Connect Ready';
      1 : sTemp := 'PC ERROR';
      2 : sTemp := 'PC TURN COMMAND';
      3 : sTemp := 'PC Vision Inspect';
      4 : sTemp := 'Channel 1 && 2 Use';
      5 : sTemp := 'Channel 3 && 4 Use';
      6 : sTemp := 'Channel 5 && 6 Use';
      7 : sTemp := 'Channel 7 && 8 Use';
      8 : sTemp := 'Auto(ABB) Mode';
    end;
    ledPlcOut[i].Caption := sTemp;

    ledPlcOut[i].Width := nWidth;
    ledPlcOut[i].Height := nHeight;
    ledPlcOut[i].LedColor := TLedColor(Yellow);
    ledPlcOut[i].StyleElements := [seBorder];
    if sTemp = '' then ledPlcOut[i].Visible := False;
//    if sPlcHint <> '' then ledPlcOut[i].ShowHint := True;
//    ledPlcOut[i].Hint     := sPlcHint;
  end;
end;

procedure TfrmMain_Pocb.OnMesMsg(nMsgType, nPg: Integer; bError: Boolean; sErrMsg: string);
var
  sHostErrMsg : string;
  nCh , i: Integer;
begin
  sHostErrMsg := StringReplace(sErrMsg, '[', '', [rfReplaceAll]);
  sHostErrMsg := StringReplace(sHostErrMsg, ']', '', [rfReplaceAll]);

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
        for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin   // JH:qHWANG-GMES: 2018-06-20
          PasScr[nCh].m_bMesPMMode := False;
        end
      end
      else begin
        ShowNgMessage(sHostErrMsg);
      end;
    end;
    DefGmes.MES_EDTI  : begin
//      InitMainTool(True);
      for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
        frmTest4ChPocb[i].SetHostConnShow(True);
      end;
      Common.m_sUserId := DongaGmes.MesUserId;
      pnlUserId.Caption := Common.m_sUserId;
      if bError then begin
        ShowNgMessage(sHostErrMsg);
      end;
      btnLogIn.Caption := 'đăng xuất   (Log Out)';
      pnlMesReady.Color := clGreen;// $00FFFFE1;
      pnlMesReady.Caption := 'MES ON';
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

procedure TfrmMain_Pocb.ReadPlcStatus(nRet: Integer; sMsg: String);
begin
  if nRet <> 0 then begin
    ledPlc.Value := False;
    pnlPlcStatus.Caption := sMsg;
    pnlPlcReady.Color := clMaroon;
    pnlPlcReady.Caption := 'PLC Disconnected';
  end
  else begin
    ledPlc.Value := True;
    pnlPlcStatus.Caption := sMsg;
  end;
end;

procedure TfrmMain_Pocb.ReleaseReadyModOnPlc;
var
  nCh : Integer;
begin
  if PlcPocb <> nil then begin
    if btnAutoReady.Tag <> 0 then begin
      btnAutoReady.OnClick(nil);
    end;
  end
  else begin
    Exit;
  end;
end;

procedure TfrmMain_Pocb.ShowModelNgMsg(sMsg: string);
begin
  if frmModelNgMsg <> nil  then begin
    frmModelNgMsg.lblShow.Caption := sMsg;
    frmModelNgMsg.RzBitBtn1.Visible := False;
  end
  else begin
    frmModelNgMsg  := TfrmNgMsg.Create(nil);
    frmModelNgMsg.RzBitBtn1.Visible := False;
    try
      frmModelNgMsg.lblShow.Caption := sMsg;
      frmModelNgMsg.ShowModal;
    finally
      frmModelNgMsg.Free;
      frmModelNgMsg := nil;
    end;
  end;

end;

procedure TfrmMain_Pocb.ShowNgMessage(sMessage: string);
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

procedure TfrmMain_Pocb.ShowPlcAlarm(naReadData: array of Integer);
begin
  //PLC Alarm Data 복사후 표시는 타이머에서 처리한다. Thread에서 호출
  CopyMemory(@m_naPLCAlarmData, @naReadData, sizeof(Integer) * Pred(defPlc.MAX_ALARM_DATA_SIZE) );
  tmrPlcAlarm.Interval := 100;
  tmrPlcAlarm.Enabled := True;
end;

procedure TfrmMain_Pocb.ShowPlcJigTact(nData: Integer);
var
  nCurJig : Integer;
begin
  nCurJig := PlcPocb.m_nCurJig;
  if frmTest4ChPocb[nCurJig] <> nil then begin
    frmTest4ChPocb[nCurJig].m_nJigTact := nData div 10;
  end;
end;

procedure TfrmMain_Pocb.tmAlarmMsgTimer(Sender: TObject);
begin
  tmAlarmMsg.Enabled := False;
  ShowModelNgMsg(m_sPlcModelZAxis);
end;

procedure TfrmMain_Pocb.tmrDisplayTestFormTimer(Sender: TObject);
var
  i, nPlcData: Integer;
  sTarget, sSource : string;
  aTask : TThread;
begin
  tmrDisplayTestForm.Enabled := False;
  Self.WindowState := wsMaximized;
//  if Common.SystemInfo.OcManualType then pnlSubTool.Height := 0;
  if Common.SystemInfo.UIType = DefCommon.UI_WIN10_NOR then begin
    Self.Color := clBtnFace;
  end
  else begin
    Self.Color := clBlack;
  end;
  if Common.SystemInfo.OcManualType then begin
    pnlPlcReady.Visible := False;
    pnlMesReady.Left  := 1;
    pnlMesReady.Width := pnlSubTool.Width - 1 ;
  end
  else begin
    pnlMesReady.Width := pnlSubTool.Width div 2;
    pnlPlcReady.Width := pnlSubTool.Width div 2;
    pnlPlcReady.Left  := 1;
    pnlMesReady.Left  := pnlPlcReady.Width + pnlPlcReady.Left + 1;
  end;
//  pnlMesReady.Width := pnlSubTool.Width - pnlPlcReady.Width - 20 ;
//  if not Common.SystemInfo.OcManualType then begin
//    Self.Height := Self.Height - 38;
//  end;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    frmTest4ChPocb[i] := TfrmTest4ChPocb.Create(self);
    frmTest4ChPocb[i].Tag := i;
    frmTest4ChPocb[i].Height := (Self.Height div 2) - tolGroupMain.Top - tolGroupMain.Height - (pnlSubTool.Height div 2) - 20 ;
    frmTest4ChPocb[i].Width  := Self.Width - (pnlSysInfo.Width + pnlSysInfo.Left) - 20 ;
    frmTest4ChPocb[i].Left   := 0;
    frmTest4ChPocb[i].Top    := frmTest4ChPocb[i].Height * i;
    frmTest4ChPocb[i].Visible := True;
    frmTest4ChPocb[i].ShowGui(Self.Handle);

    frmTest4ChPocb[i].Caption := Format('%X Stage',[i+10]);
    if not Common.SystemInfo.UseAutoBCR then begin
      frmTest4ChPocb[i].SetBcrData;
    end;
    case i of
      DefCommon.JIG_A : begin
        m_nCamPos := frmTest4ChPocb[i].Height * i;
      end;
      DefCommon.JIG_B : begin
        m_nLoadPos := frmTest4ChPocb[i].Height * i;
      end;
    end;
  end;

  // UDP Server가 Data를 입력 받을 Timming ....
  UdpServer.FIsReadyToRead := True;
  PlcPocb := TPlcPocb.Create(Self.Handle);
  PlcPocb.OnPlcConnect := ReadPlcStatus;
  PlcPocb.OnPlcRead := MainPlcStatus ;
  PlcPocb.OnPlcAlarm := ShowPlcAlarm;
  PlcPocb.OnPlcJigTact := ShowPlcJigTact;
//  PlcPocb.OnPlcAutoFlow := AutoStart;
  Common.Delay(200); // 연결 Check 때문.
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    // Channel 초기화.
    if Common.SystemInfo.UseCh[i*2] and Common.SystemInfo.UseCh[i*2+1] then begin
      nPlcData := 1 shl (4+i);
      PlcPocb.writePlc(nPlcData);
    end
    else begin
      nPlcData := 1 shl (4+i);
      PlcPocb.writePlc(nPlcData, True);
    end;
  end;

  CamCommTri := TCamComm.Create(Self.Handle);
  CamCommTri.OnCamConnection := GetCamConnStatus;
  CamCommTri.CheckConnect; // 내부적으로 OnCamConnection를 사용하기 때문에 OnCamConnection 선언 이후에 Code가 와야함.
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    frmTest4ChPocb[i].CamSet;
  end;
  if Common.SystemInfo.ServicePort <> '' then begin
    btnLogIn.Click;
  end;
  if PlcPocb <> nil then begin
    btnAutoReady.Click;
  end;


  // File Copy
  if Common.SystemInfo.AutoBackupUse then begin
    sTarget := Trim(Common.SystemInfo.AutoBackupList);
    if sTarget <> '' then begin
      sSource :=  ExtractFilePath(Application.ExeName);
      if DirectoryExists(sTarget) then begin
        aTask := TThread.CreateAnonymousThread(
          procedure begin
            Common.CopyDirectoryAll(sSource,sTarget, False);
          end);
        aTask.FreeOnTerminate := True;
        aTask.Start;
      end;
    end;
  end;
  Self.WindowState := wsMaximized;
  //btnLogIn.Click;
end;

procedure TfrmMain_Pocb.tmrMemCheckTimer(Sender: TObject);
var
  sCmd : string;
begin
  sCmd := FormatFloat('#,',Common.ProcessMemory);
  pnlMemCheck.Caption := 'MEMORY CHECK : '+sCmd + ' Bytes';
end;

procedure TfrmMain_Pocb.tmrPlcAlarmTimer(Sender: TObject);
begin
  tmrPlcAlarm.Enabled := False;

  if Assigned(frmDisplayAlarm) = False then  frmDisplayAlarm:= TfrmDisplayAlarm.Create(Self);

  frmDisplayAlarm.SetAlarmData(m_naPLCAlarmData);
  frmDisplayAlarm.Show;
//  frmDisplayAlarm.ShowModal;
//  frmDisplayAlarm.Free;
//  frmDisplayAlarm:= nil;

end;

procedure TfrmMain_Pocb.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, nTemp : Integer;
  sMsg, sSubMsg, sFileName, sDebug : string;
  sCsvHeader : array [0..2] of string;
  sCsvData : string;
begin
  nType := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
  case nType of
    DefCommon.MSG_TYPE_CAM_LIGHT : begin
      nMode := PGuiCamLight(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiCamLight(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp  := PGuiCamLight(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
          pnlCamLight.Caption := sMsg;
          case nTemp of
            0 : begin
              ledCamLight.FalseColor := clRed;
              ledCamLight.Value := False;
            end;
            1 : begin
              ledCamLight.Value := True;
            end;
            2 : begin
              ledCamLight.FalseColor := clGray;
              ledCamLight.Value := False;
            end;
          end;
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
          if nCh = DefCommon.JIG_B then begin //GIB_OPTIC
            pnlSwB.Caption := sMsg;
            case nTemp of
              0 : begin
                ledSwJigB.FalseColor := clRed;
                ledSwJigB.Value := False;
              end;
              1 : begin
                ledSwJigB.Value := True;
              end;
              2 : begin
                ledSwJigB.FalseColor := clGray;
                ledSwJigB.Value := False;
              end;
            end;
          end;
        end;
      end;
    end;

    DefCommon.MSG_TYPE_SCRIPT : begin
      nMode := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_LOG_CSV : begin
          MakeOpticCsvData(sFileName , sCsvHeader, sCsvData, nCh);
          MakeOpticSummaryCsvLog(sFileName ,sCsvHeader, sCsvData);
        end;
        DefGmes.MES_PCHK : begin
          sDebug := 'TfrmMainGB.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
          DongaGmes.SendHostPchk(PasScr[nCh].m_TestRet.SerialNo, nCh);
        end;
        DefGmes.MES_INS_PCHK : begin
          sDebug := 'TfrmMainGB.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
          DongaGmes.SendHostIns_Pchk(PasScr[nCh].m_TestRet.SerialNo, nCh);
        end;
        DefGmes.MES_EICR : begin
          DongaGmes.SendHostEicr(PasScr[nCh].m_TestRet.SerialNo, nCh, PasScr[nCh].m_sCarrierId{.m_TestRet.CarrierId});
        end;
        Defgmes.MES_RPR_EIJR : begin
          DongaGmes.SendHostRPr_Eijr(PasScr[nCh].m_TestRet.SerialNo, nCh);
        end;
        DefGmes.MES_APDR : begin
          DongaGmes.MesData[nCh].ApdrData := PasScr[nCh].m_TestRet.ApdrData;
          DongaGmes.SendHostApdr(PasScr[nCh].m_TestRet.SerialNo, nCh);
        end;
        DefGmes.EAS_APDR : begin
          DongaGmes.MesData[nCh].ApdrData := PasScr[nCh].m_TestRet.ApdrData;
          DongaGmes.SendEasApdr(PasScr[nCh].m_TestRet.SerialNo, nCh);
        end;
      end;
    end;

  end;
end;

end.
