unit Main_GB;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ALed, RzPanel, RzButton, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList,
  Vcl.Themes, System.UITypes, TILed, pasScriptClass, System.DateUtils,
{$IFDEF ALGO_DLL}
  Algrithm_Jncd,
{$ENDIF}
  //
  CommonClass, UserID, GMesCom, DefCommon, DefGmes, NGMsg, ModelInfo, Mainter, LogIn, LogicVh, HandBCR, Ca310, defPlc, PlcTcp,

  UdpServerClient, Test4ChGB, SwitchBtn, ScriptClass, AXDioLib, DefDio, ModelSelect, ModelDownload, SystemSetup, RzStatus;
{$I Common.inc}
type
  TfrmMain_GB = class(TForm)
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
    ledGmes: ThhALed;
    RzPanel6: TRzPanel;
    pnlHost: TRzPanel;
    RzGroupBox5: TRzGroupBox;
    RzPanel5: TRzPanel;
    pnlUserId: TRzPanel;
    RzPanel17: TRzPanel;
    pnlStationNo: TRzPanel;
    RzPanel28: TRzPanel;
    pnlUserName: TRzPanel;
    RzPanel2: TRzPanel;
    ledCa310Up: ThhALed;
    ledCa310Dn: ThhALed;
    RzPanel4: TRzPanel;
    pnlCa310Com2: TRzPanel;
    pnlCa310Com1: TRzPanel;
    grpDioSig: TRzGroupBox;
    pnlDioSigTitle: TRzPanel;
    pnlDioStatus: TRzPanel;
    ledDioConnected: ThhALed;
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
    btnShowDioSig: TRzBitBtn;
    RzStatusBar1: TRzStatusBar;
    RzResourceStatus1: TRzResourceStatus;
    RzClockStatus1: TRzClockStatus;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    RzKeyStatus1: TRzKeyStatus;
    grpPlc: TRzGroupBox;
    ledPlc: ThhALed;
    RzPanel1: TRzPanel;
    pnlPlcStatus: TRzPanel;
    pnlPlcA: TRzPanel;
    pnlPlcB: TRzPanel;
    pnlAddrInA: TRzPanel;
    pnlAddrInB: TRzPanel;
    pnlAddrOutA: TRzPanel;
    pnlAddrOutB: TRzPanel;
    pnlManualItems: TRzPanel;
    RzPanel8: TRzPanel;
    ledHandBcr: ThhALed;
    pnlHandBcr: TRzPanel;
    pnlSwA: TRzPanel;
    ledSwJigA: ThhALed;
    RzPanel3: TRzPanel;
    RzPanel10: TRzPanel;
    ledSwJigB: ThhALed;
    pnlSwB: TRzPanel;
    RzStatusPane3: TRzStatusPane;
    pnlStLocalIp: TRzStatusPane;
    pnlSubTool: TPanel;
    pnlMesReady: TPanel;
    btnLogIn: TRzToolButton;
    pnlPlcReady: TPanel;
    btnAutoReady: TRzToolButton;
    tmrMemCheck: TTimer;
    pnlMemCheck: TRzStatusPane;
    RzBitBtn1: TRzBitBtn;
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
    procedure btnShowDioSigClick(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    function IsHeaderExist( asHeaders : array of string) : Boolean;
    procedure btnAutoReadyClick(Sender: TObject);
    procedure tmrMemCheckTimer(Sender: TObject);
    procedure RzBitBtn1Click(Sender: TObject);
  private
    { Private declarations }
    // for DIO Signal.
    ledDioIn : array[0.. DefDio.MAX_IN_CNT] of  TTILed;
    ledDioOut : array[0.. DefDio.MAX_OUT_CNT] of  TTILed;
    // for PLC Signal.
    ledPlcIn,   ledPlcIn2 : array[0.. defPlc.MAX_INPUT_CNT] of  TTILed;
    ledPlcOut,  ledPlcOut2 : array[0.. defPlc.MAX_OUT_CNT] of  TTILed;

    m_bDioIn : array[0.. DefDio.MAX_IN_CNT] of boolean;
    m_bDioOut : array[0.. DefDio.MAX_OUT_CNT] of Boolean;
    m_bPlcIn : array[DefCommon.JIG_A .. DefCommon.JIG_B, 0 .. defPlc.MAX_INPUT_CNT] of boolean;
    m_bPlcOut : array[DefCommon.JIG_A .. DefCommon.JIG_B, 0 .. defPlc.MAX_OUT_CNT] of boolean;
    m_nPlcInPre1, m_nPlcInPre2, m_nPlcOutPre11, m_nPlcOutPre12, m_nPlcOutPre21, m_nPlcOutPre22 : Integer;
    procedure ShowAlarmMsg(sMsg : string);
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
    procedure MakeDioSig;
    procedure MakePlcSig;
    procedure MainDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg : string);
    procedure MainPlcStatus(nJig, nLen : Integer; naReadData : array of Integer);
//    procedure WorkingWithDio(nJig : Integer);
    // Style 변경 완료후 Main과 Test의 Handle값이 변경 됨. == > 이벤트 처리하기 위함.
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
//    procedure MakeCsvData(var sFileName : string;var sHeader: string; var sData : string; nCh : Integer);
    procedure MakeOpticCsvData(var sFileName : string; var sHeader: array of string; var sData : string; nCh : Integer);
//    procedure MakeSummaryCsvLog(sScrFileName, sHeader, sData : string);
    procedure MakeOpticSummaryCsvLog(sScrFileName : String; sCsvHeader : array of string; sCsvData: string);

    procedure AutoStart(nJig, nJigCh : Integer; sErr : string);
    procedure MakePlcLog;
    procedure ReleaseReadyModOnPlc;
    function CheckScriptRun : Boolean;
  public
    { Public declarations }
  end;

var
  frmMain_GB: TfrmMain_GB;

implementation

{$R *.dfm}

uses DioSignal;

procedure TfrmMain_GB.btnShowDioSigClick(Sender: TObject);
var
  scmd : string;
begin
//  scmd := Format('%d',[(Common.ProcessMemory div 1024) div 1024]);
//  scmd := FormatFloat('#,',Common.ProcessMemory);
//  ShowMessage(scmd);
//  exit;

  if frmDioSignal <> nil then begin
    frmDioSignal.Close;
    btnShowDioSig.Caption := 'Show DIO Signal Status';
  end
  else begin
    frmDioSignal := TfrmDioSignal.Create(Self);
    frmDioSignal.Show;
    btnShowDioSig.Caption := 'Close DIO Signal Window';
  end;
end;

procedure TfrmMain_GB.AutoStart(nJig, nJigCh: Integer; sErr : string);
var
  nRealJig : Integer;
  nPauseProbe : Integer;
begin
  nRealJig := nJig mod 2;
  nPauseProbe := nJig div 2;

  // 0.B일 경우.
  if nPauseProbe = 0 then begin
    frmTest4ChGB[nRealJig].AutoLogicStart;
  end;
  // Carrier detect & Load complete OK checking ==> Only NG.
  if nPauseProbe = 1 then begin
    frmTest4ChGB[nRealJig].ShowPlcNgMeg(nJigCh,sErr);
  end;
end;

procedure TfrmMain_GB.btnAutoReadyClick(Sender: TObject);
var
  i : integer;
begin
  if btnAutoReady.Tag = 0 then begin
    if PlcCtl <> nil then begin
      PlcCtl.writePlc(DefCommon.JIG_A, defPlc.IDX_FIRST_WORD,defPlc.OUT_PC_READY,False);
      PlcCtl.writePlc(DefCommon.JIG_B, defPlc.IDX_FIRST_WORD,defPlc.OUT_PC_READY,False);
      // NG 처리 초기화.
      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        PlcCtl.writePlc(DefCommon.JIG_A,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl i,True);
        PlcCtl.writePlc(DefCommon.JIG_B,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl i,True);
      end;
//      for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
//        // 상태, 선택 .
//        SetComeInOrderPlc;
//      end;
    end
    else begin
      Exit;
    end;
    btnAutoReady.Caption := 'STOP AUTO MODE';
    btnAutoReady.Tag      := 1;
    pnlPlcReady.Caption   := 'PLC Ready On';
    pnlPlcReady.Color     := clGreen;//$00FFDFBF;
    pnlPlcReady.Font.Color := clYellow; //clBlack;
  end
  else begin
    if PlcCtl <> nil then begin
      PlcCtl.writePlc(DefCommon.JIG_A, defPlc.IDX_FIRST_WORD,defPlc.OUT_PC_READY,True);
      PlcCtl.writePlc(DefCommon.JIG_B, defPlc.IDX_FIRST_WORD,defPlc.OUT_PC_READY,True);
    end
    else begin
      Exit;
    end;
    btnAutoReady.Caption := 'READY AUTO MODE';
    btnAutoReady.Tag      := 0;
    pnlPlcReady.Caption   := 'PLC Ready Off';
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlPlcReady.Color   := $000050F7;//$00FF80FF;//clBlack;
    end
    else begin
      pnlPlcReady.Color   := $000050F7;//$00FF80FF;//clBtnFace;
    end;
    pnlPlcReady.Font.Color := clYellow;
  end;
end;

procedure TfrmMain_GB.btnExitClick(Sender: TObject);
begin

  Close;
end;

procedure TfrmMain_GB.btnInitClick(Sender: TObject);
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

procedure TfrmMain_GB.btnLogInClick(Sender: TObject);
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
                if frmTest4ChGB[DefCommon.JIG_A] <> nil then begin
                  DongaGmes.hTestHandle1 := frmTest4ChGB[DefCommon.JIG_A].Handle;
                end;
                if frmTest4ChGB[DefCommon.JIG_B] <> nil then begin
                  DongaGmes.hTestHandle2 := frmTest4ChGB[DefCommon.JIG_B].Handle;
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
          frmTest4ChGB[i].SetHostConnShow(False);
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
                if frmTest4ChGB[DefCommon.JIG_A] <> nil then begin
                  DongaGmes.hTestHandle1 := frmTest4ChGB[DefCommon.JIG_A].Handle;
                end;
                if frmTest4ChGB[DefCommon.JIG_B] <> nil then begin
                  DongaGmes.hTestHandle2 := frmTest4ChGB[DefCommon.JIG_B].Handle;
                end;
              end;
            end;
          end;
        end;
      end
      else begin
        InitGmes;
        if frmTest4ChGB[DefCommon.JIG_A] <> nil then begin
          DongaGmes.hTestHandle1 := frmTest4ChGB[DefCommon.JIG_A].Handle;
        end;
        if frmTest4ChGB[DefCommon.JIG_B] <> nil then begin
          DongaGmes.hTestHandle2 := frmTest4ChGB[DefCommon.JIG_B].Handle;
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

procedure TfrmMain_GB.btnMaintClick(Sender: TObject);
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

procedure TfrmMain_GB.btnModelChangeClick(Sender: TObject);
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

procedure TfrmMain_GB.btnModelClick(Sender: TObject);
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

procedure TfrmMain_GB.btnStationClick(Sender: TObject);
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

function TfrmMain_GB.CheckAdminPasswd: boolean;
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

function TfrmMain_GB.CheckPgRun: Boolean;
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

function TfrmMain_GB.CheckScriptRun : Boolean;
var
  i: Integer;
  bRet : Boolean;
begin
  bRet := False;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChGB[i] <> nil then begin
      if frmTest4ChGB[i].CheckScriptRun then begin
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

procedure TfrmMain_GB.CMStyleChanged(var Message: TMessage);
var
  i : Integer;
begin
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChGB[i] <> nil then begin
      frmTest4ChGB[i].SetHandleAgain(Self.Handle);
    end;
  end;
end;

procedure TfrmMain_GB.CreateClassData;
begin
  // UDP 서버 IP 192.168.0.11
  // 내부적으로 Common file을 읽어 오기 대문에 반드시 Common Create 이후 호출.
  UdpServer := TUdpServerVh.Create(Self.Handle, DefCommon.MAX_PG_CNT);
  InitForm;
  tmrDisplayTestForm.Interval := 100;
  tmrDisplayTestForm.Enabled := True;
//
  Script := TScript.Create(Common.Path.MODEL_CUR + Common.SystemInfo.TestModel + '.isu');//TScript.Create(Common.Path.MODEL + Common.SystemInfo.TestModel + '.script');
  DisplayScriptInfo;
//
  DongaHandBcr := TSerialBcr.Create(Self);
  DongaHandBcr.OnRevBcrConn := GetBcrConnStatus;
  DongaHandBcr.ChangePort(Common.SystemInfo.Com_HandBCR);

  pnlStationNo.Caption := Common.SystemInfo.EQPId;
  tmrMemCheck.Enabled := True;
end;

function TfrmMain_GB.DisplayLogIn: Integer;
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

procedure TfrmMain_GB.DisplayScriptInfo;
begin
  pnlResolution.Caption := Format(' %d(H) x %d(V)',[Common.TestModelInfo.H_Active, Common.TestModelInfo.V_Active]);
  pnlPatternGroup.Caption :=  Common.TestModelInfo2.PatGrpName;
  pnlModelNameInfo.Caption := Common.SystemInfo.TestModel;

  pnlAddrOutA.Caption := Trim(Common.SystemInfo.RobotOutA);
  pnlAddrOutB.Caption := Trim(Common.SystemInfo.RobotOutB);
  pnlAddrInA.Caption := Trim(Common.SystemInfo.RobotRevA);
  pnlAddrInB.Caption := Trim(Common.SystemInfo.RobotRevB);

  pnlPsuVer.Caption    := Common.m_Ver.psu_Date+'('+Common.m_Ver.psu_Crc+')';
  pnlIsuVer.Caption    := Common.m_Ver.isu_Date;
//  pnlCheckSum.Caption  :=  Common.TestModelInfo2.CheckSum + '/'+ Common.SystemInfo.ScriptCrc;
//  pnlScriptVer.Caption :=  Common.SystemInfo.ScriptVer;
end;

procedure TfrmMain_GB.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
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

procedure TfrmMain_GB.FormCreate(Sender: TObject);
var
  i : Integer;
  sDebug : string;
begin
//  Self.WindowState := wsMaximized;// wsNormal;
  Common := TCommon.Create;
  Common.m_sUserId := 'PM';
  pnlUserId.Caption := Common.m_sUserId;
  pnlUserName.Caption := '';
//  if Trim(Common.SystemInfo.ServicePort) <> '' then begin
//    nRet := DisplayLogIn;
//    if nRet = mrCancel then begin
//      Application.ShowMainForm := False;
//      Common.Free;
//      Common := nil;
//      Application.Terminate;
//      Exit;
//    end
//    else begin
//      if Common.m_sUserId = 'PM' then begin
//        pnlHost.Caption := 'PM Mode';
//        ledGmes.FalseColor := clGray;
//        ledGmes.Value := False;
//        pnlUserId.Caption := 'PM';
//        pnlUserName.Caption := '';
//      end
//      else begin
//        if DongaGmes is TGmes then begin
//          DongaGmes.MesUserId := Common.m_sUserId;
//          if not DongaGmes.MesEayt then DongaGmes.SendHostUchk
//          else                          DongaGmes.SendHostEayt;
//        end
//        else begin
//          InitGmes;
//        end;
//      end;
//    end;
//  end
//  else begin
//    btnLogIn.Visible := False;
//  end;
  btnLogIn.Visible := True;
  sDebug := '#################################### Turn On ISPD Program (';
  sDebug := sDebug + Common.GetVersionDate + ') ####################################';
  for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
  MakeDioSig;

  MakePlcSig;
  if common.SystemInfo.OcManualType then begin
    grpSystemInfo.Height := 148;
  end
  else begin
    grpSystemInfo.Height := 84;
  end;
  CreateClassData;
  // 현재 설정 되어 있는 Local IP Display 하자.
  pnlStLocalIp.Caption := Common.GetLocalIpList;
//  Common.MLog(DefCommon.MAX_SYSTEM_LOG,'1');
  Self.Caption := DefCommon.PROGRAM_NAME + ' Version ' + Common.GetVersionDate;
  Common.TaskBar(True);
  // Added by ClintPark 2018-11-23 오후 2:03:48  GIB Use GMES.
  pnlSubTool.Visible   := True;

  pnlMesReady.Font.Color :=  clYellow;// clBlack;
  pnlMesReady.Color       := $000050F7;//$00FF80FF;//clBtnFace;

  if common.SystemInfo.OcManualType then begin
    pnlPlcReady.Visible     := False;
    pnlPlcReady.Font.Color  := clYellow;
    pnlPlcReady.Color       := clMaroon;//$000050F7;//$00FF80FF;//clBtnFace;
  end;
end;

procedure TfrmMain_GB.GetBcrConnStatus(bConnected: Boolean; sMsg: string);
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


procedure TfrmMain_GB.initform;
begin
  case Common.SystemInfo.UIType of
    Defcommon.UI_WIN10_NOR  : TStyleManager.SetStyle('Windows10');
    Defcommon.UI_WIN10_BLACK : TStyleManager.SetStyle('Windows10 Dark')
    else begin
      TStyleManager.SetStyle('Windows10');
    end;
  end;
  pnlManualItems.Visible := common.SystemInfo.OcManualType;
  grpPlc.Visible          := not Common.SystemInfo.OcManualType;

end;

Function TfrmMain_GB.InitGmes : Boolean;
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
  if not Common.SystemInfo.OcManualType then begin
    DongaGmes.MesUserId := '602462';// Common.m_sUserId;
    Common.m_sUserId := 'PM';
  end
  else begin
    DongaGmes.MesUserId := Common.m_sUserId;
  end;
  pnlUserId.Caption := Common.m_sUserId;
  pnlUserName.Caption := '';
  DongaGmes.MesSystemNo   := Common.SystemInfo.EQPId;
  bRtn := DongaGmes.HOST_Initial(sService, sNetWork, sDeamon,sLocal,sRemote ,sHostPath);
  ledGmes.Value := bRtn;

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

procedure TfrmMain_GB.InitialAll(bReset: Boolean);
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
  ReleaseReadyModOnPlc;
  if DongaGmes <> nil then begin
    btnLogIn.Caption := 'đăng nhập (Log In)';
    DongaGmes.Free;
    DongaGmes := nil;
  end;

  if PlcCtl <> nil then begin
    PlcCtl.Free;
    PlcCtl := nil;
  end;
  if frmDioSignal <> nil then begin
    frmDioSignal.Close;
    btnShowDioSig.Caption := 'Show DIO Signal Status';
  end;
  if DongaHandBcr <> nil then begin
    DongaHandBcr.Free;
    DongaHandBcr := nil;
  end;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if DongaCa310[i] <> nil then begin
      DongaCa310[i].Free;
      DongaCa310[i] := nil;
    end;
    // Distroy current alloc class
    if frmTest4ChGB[i] <> nil then begin
      frmTest4ChGB[i].Free;
      frmTest4ChGB[i] := nil;
    end;
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
  if bReset then begin

    // Create Again.
    Common :=	TCommon.Create;
    CreateClassData;
  end;
end;

procedure TfrmMain_GB.InitMainTool(bEnable: Boolean);
begin
  btnModelChange.Enabled := bEnable;
  btnModel.Enabled  := bEnable;
end;

function TfrmMain_GB.IsHeaderExist(asHeaders: array of string): Boolean;
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

procedure TfrmMain_GB.MainDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg : string);
var
  i : Integer;
//  bTemp : Boolean;
//  nMaxCh: Integer;
begin
  if bIn then begin
    if not Common.SystemInfo.OcManualType then begin
      for i := DefDio.DIO_IN_PROBE_UP_1 to DefDio.DIO_IN_BACK_2 do begin
          ledDioIn[i].LedOn := IoDio[i];
      end;
      if frmDioSignal <> nil then begin
        for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
          frmDioSignal.ledDioIn[i].LedOn :=  IoDio[i];
        end;
      end;
      // DIO Signal이 변경 되었을때 PLC쪽으로 신호 보내자.
      if PlcCtl <> nil then begin
  //      bTemp := IoDio[DefDio.DIO_IN_EMS_1] or IoDio[DefDio.DIO_IN_EMS_2];
  //      bTemp := bTemp or IoDio[DefDio.DIO_IN_DOOR_SENSOR_1] or IoDio[DefDio.DIO_IN_DOOR_SENSOR_2];
        // 현재는 Test. 향후 완료되면 입력하자.
  //      bTemp := bTemp or (not IoDio[DefDio.DIO_IN_FAN_1]) or (not IoDio[DefDio.DIO_IN_FAN_2]);
  //      bTemp := bTemp or IoDio[DefDio.DIO_IN_TEMP_CONTR];
  //      nMaxCh := DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
        for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
          // Back 신호 전달.
          PlcCtl.writePlc(i,defPlc.IDX_FIRST_WORD,defPlc.OUT_PROBE_BACK ,not IoDio[DefDio.DIO_IN_BACK_1+i]);
        end;
      end;
      for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
        if frmTest4ChGB[i] <> nil then begin
          frmTest4ChGB[i].SetDioStatus(IoDio);
        end;
      end;
    end
    else begin
      for i := DefDio.DIO_IN_PROBE_UP_1 to DefDio.DIO_IN_PROBE_DOWN_2 do begin
        ledDioIn[i].LedOn := IoDio[i];
      end;
      for i := DefDio.DIO_IN_FAN_1 to DefDio.DIO_IN_TEMP_CONTR do begin
        ledDioIn[i].LedOn := IoDio[i];
      end;
    end;
  end
  else begin
    if frmDioSignal <> nil then begin
      for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
        frmDioSignal.ledDioOut[i].LedOn :=  IoDio[i];
      end;
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

procedure TfrmMain_GB.MainPlcStatus(nJig, nLen: Integer; naReadData: array of Integer);
var
  i, j : Integer;
  dwTemp : DWORD;
begin
  case nJig of
    DefPlc.IDX_PLC_READ_1 : begin
      for i := 0 to Pred(nLen) do begin
        for j := 0 to Pred(defPlc.MAX_INPUT_CNT) do begin
          dwTemp := 1 shl j;
          if (dwTemp and naReadData[i]) <> 0 then begin
            ledPlcIn[j].LedOn := True;
            m_bPlcIn[DefCommon.JIG_A,j] := True;
          end
          else begin
            ledPlcIn[j].LedOn := False;
            m_bPlcIn[DefCommon.JIG_A,j] := False;
          end;
        end;
      end;

    end;
    DefPlc.IDX_PLC_READ_2 : begin
      for i := 0 to Pred(nLen) do begin
        for j := 0 to Pred(defPlc.MAX_INPUT_CNT) do begin
          dwTemp := 1 shl j;
          if (dwTemp and naReadData[i]) <> 0 then begin
            ledPlcIn2[j+i*defPlc.MAX_INPUT_CNT].LedOn := True;
            m_bPlcIn[DefCommon.JIG_B,j+i*defPlc.MAX_INPUT_CNT] := True;
          end
          else begin
            ledPlcIn2[j+i*defPlc.MAX_INPUT_CNT].LedOn := False;
            m_bPlcIn[DefCommon.JIG_B,j+i*defPlc.MAX_INPUT_CNT] := False;
          end;
        end;
      end;
    end;
    DefPlc.IDX_PLC_WRITE_1 : begin
      for i := 0 to Pred(nLen) do begin
        for j := 0 to Pred(defPlc.MAX_INPUT_CNT) do begin
          dwTemp := 1 shl j;
          if (dwTemp and naReadData[i]) <> 0 then begin
            ledPlcOut[j+i*defPlc.MAX_INPUT_CNT].LedOn := True;
            m_bPlcOut[DefCommon.JIG_A,j+i*defPlc.MAX_INPUT_CNT] := True;
          end
          else begin
            ledPlcOut[j+i*defPlc.MAX_INPUT_CNT].LedOn := False;
            m_bPlcOut[DefCommon.JIG_A,j+i*defPlc.MAX_INPUT_CNT] := False;
          end;
        end;
      end;
      if frmTest4ChGB[DefCommon.JIG_A] <> nil then begin
        frmTest4ChGB[DefCommon.JIG_A].SetPlcStatus(naReadData[0]);
      end;
    end;
    defPlc.IDX_PLC_WRITE_2 : begin
      for i := 0 to Pred(nLen) do begin
        for j := 0 to Pred(defPlc.MAX_INPUT_CNT) do begin
          dwTemp := 1 shl j;
          if (dwTemp and naReadData[i]) <> 0 then begin
            ledPlcOut2[j+i*defPlc.MAX_INPUT_CNT].LedOn := True;
            m_bPlcOut[DefCommon.JIG_B,j+i*defPlc.MAX_INPUT_CNT] := True;
          end
          else begin
            ledPlcOut2[j+i*defPlc.MAX_INPUT_CNT].LedOn := False;
            m_bPlcOut[DefCommon.JIG_B,j+i*defPlc.MAX_INPUT_CNT] := False;
          end;
        end;
      end;
      if frmTest4ChGB[DefCommon.JIG_B] <> nil then begin
        frmTest4ChGB[DefCommon.JIG_B].SetPlcStatus(naReadData[0]);
      end
    end;
  end;
//  // when it Events
//{$IFNDEF NEW_PROCESS}
//  WorkingWithDio(nJig mod 2);
//{$ENDIF}
  MakePlcLog;
end;

//procedure TfrmMain_GB.MakeCsvData(var sFileName : string; var sHeader : string;var sData: string; nCh : Integer);
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

procedure TfrmMain_GB.MakeDioSig;
var
  i: Integer;
  sIoName : string;
  nWidth, nHeight, nTopPos, nLeft, nDiv, nMod, nTop, nLeftOut, nTemp : Integer;
begin
  nWidth := 106;// 26;
  nHeight := 26;
  nTopPos := pnlDioSigTitle.Top + pnlDioSigTitle.Height + 2;
//  nLeft  := pnlDioSigTitle.Left;
  nDiv    := DefDio.MAX_IN_CNT div 4;
  nMod    := DefDio.MAX_IN_CNT mod 4;
  if nMod <> 0 then nDiv := nDiv + 1;
  if Common.SystemInfo.OcManualType then begin
    for i := DefDio.DIO_IN_PROBE_UP_1 to DefDio.DIO_IN_PROBE_DOWN_2 do begin
      nTemp := i div 2;
      if (i mod 2) = 0 then begin
        nLeft := pnlDioSigTitle.Left;// pnlDioSigTitle.Left + (i div nDiv)*nWidth;
        nTop  := nTopPos + nTemp*(nHeight);
      end
      else begin
        nLeft := pnlDioSigTitle.Left + 1 + nWidth;// pnlDioSigTitle.Left + (i div nDiv)*nWidth;
        nTop  := ledDioIn[i-1].Top;
      end;
      ledDioIn[i] := TTILed.Create(Self);
      ledDioIn[i].Parent := grpDioSig;
      ledDioIn[i].Left := nLeft;
      ledDioIn[i].Top  := nTop;
      ledDioIn[i].Width := nWidth;
      ledDioIn[i].Height := nHeight;
      ledDioIn[i].LedColor := TLedColor(Green);
      ledDioIn[i].StyleElements := [seBorder];

      sIoName := '';
      case i of
        DefDio.DIO_IN_PROBE_UP_1    : sIoName := 'Probe Up #1';
        DefDio.DIO_IN_PROBE_UP_2    : sIoName := 'Probe Up #2';
        DefDio.DIO_IN_PROBE_DOWN_1  : sIoName := 'Probe Down #1';
        DefDio.DIO_IN_PROBE_DOWN_2  : sIoName := 'Probe Down #2';
      end;
      ledDioIn[i].Caption := sIoName;
    end;

    for i := DefDio.DIO_IN_FAN_1 to DefDio.DIO_IN_TEMP_CONTR do begin
      nTemp := (i - DefDio.DIO_IN_FAN_1 + DIO_IN_PROBE_DOWN_2 + 1) div 2;
      if (i mod 2) = 0 then begin
        nLeft := pnlDioSigTitle.Left;// pnlDioSigTitle.Left + (i div nDiv)*nWidth;
        nTop  := nTopPos + nTemp*(nHeight);
      end
      else begin
        nLeft := pnlDioSigTitle.Left + 1 + nWidth;// pnlDioSigTitle.Left + (i div nDiv)*nWidth;
        nTop  := ledDioIn[i-1].Top;
      end;
      ledDioIn[i] := TTILed.Create(Self);
      ledDioIn[i].Parent := grpDioSig;
      ledDioIn[i].Left := nLeft;
      ledDioIn[i].Top  := nTop;
      ledDioIn[i].Width := nWidth;
      ledDioIn[i].Height := nHeight;
      ledDioIn[i].LedColor := TLedColor(Green);
      ledDioIn[i].StyleElements := [seBorder];

      sIoName := '';
      case i of
        DefDio.DIO_IN_FAN_1       : sIoName := 'FAN #1';
        DefDio.DIO_IN_FAN_2       : sIoName := 'FAN #2';
        DefDio.DIO_IN_TEMP_CONTR  : sIoName := 'TEMP CONTROLLER';
      end;
      ledDioIn[i].Caption := sIoName;
    end;

  end
  else begin
    for i := DefDio.DIO_IN_PROBE_UP_1 to DefDio.DIO_IN_BACK_2 do begin
      nTemp := i div 2;
      if (i mod 2) = 0 then begin
        nLeft := pnlDioSigTitle.Left;// pnlDioSigTitle.Left + (i div nDiv)*nWidth;
        nTop  := nTopPos + nTemp*(nHeight);
      end
      else begin
        nLeft := pnlDioSigTitle.Left + 1 + nWidth;// pnlDioSigTitle.Left + (i div nDiv)*nWidth;
        nTop  := ledDioIn[i-1].Top;
      end;
      ledDioIn[i] := TTILed.Create(Self);
      ledDioIn[i].Parent := grpDioSig;
      ledDioIn[i].Left := nLeft;
      ledDioIn[i].Top  := nTop;
      ledDioIn[i].Width := nWidth;
      ledDioIn[i].Height := nHeight;
      ledDioIn[i].LedColor := TLedColor(Green);
      ledDioIn[i].StyleElements := [seBorder];

      sIoName := '';
      case i of
        DefDio.DIO_IN_PROBE_UP_1    : sIoName := 'Probe Up #1';
        DefDio.DIO_IN_PROBE_UP_2    : sIoName := 'Probe Up #2';
        DefDio.DIO_IN_PROBE_DOWN_1  : sIoName := 'Probe Down #1';
        DefDio.DIO_IN_PROBE_DOWN_2  : sIoName := 'Probe Down #2';
        DefDio.DIO_IN_PUSHER_UP_1   : sIoName := 'Pusher Up #1';
        DefDio.DIO_IN_PUSHER_UP_2   : sIoName := 'Pusher Up #2';
        DefDio.DIO_IN_PUSHER_DOWN_1 : sIoName := 'Pusher Down #1';
        DefDio.DIO_IN_PUSHER_DOWN_2 : sIoName := 'Pusher Down #2';
        DefDio.DIO_IN_FORWORD_1     : sIoName := 'Probe Forword #1';
        DefDio.DIO_IN_FORWORD_2     : sIoName := 'Probe Forword #2';
        DefDio.DIO_IN_BACK_1        : sIoName := 'Probe Back #1';
        DefDio.DIO_IN_BACK_2        : sIoName := 'Probe Back #2';
      end;
      ledDioIn[i].Caption := sIoName;
    end;
  end;
end;

procedure TfrmMain_GB.MakeOpticCsvData(var sFileName: string; var sHeader: array of string; var sData: string; nCh: Integer);
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
  sHeader[0] := sHeader[0]+ Format(',%s,%s,%s,%s',['ICU_VER','PSU_VER','OC_PARAM_VER','OC_VERIFY_VER']);
  sHeader[0] := sHeader[0]+ Format(',%s,%s,%s,%s',['OTP_TABLE_VER','OC_OFFSET_VER','MES_CSV_VER','Model_Name']);
  sHeader[0] := sHeader[0]+ format(',%s,%s,%s,%s,%s',['Start_Time','End_Time','Total_Time(sec)','OC Time(sec)','Result']);
  sHeader[0] := sHeader[0]+ format(',%s',['ERROR_MESSAGE']);
  sHeader[0] := sHeader[0]+ format(',%s,%s,%s,%s,%s',['PLC_RET','EQP ID', 'Channel','Carrier_ID','Panel_ID']);

//  nHeaderRow := Length(sHeader);

  sHeader[1] := ',,,';
  sHeader[1] := sHeader[1]+ ',,,,';
  sHeader[1] := sHeader[1]+ ',,,,';
  sHeader[1] := sHeader[1]+ ',,,,,';
  sHeader[1] := sHeader[1]+ ',,,,,';
  sHeader[1] := sHeader[1]+ ',';

  sHeader[2] := ',,,';
  sHeader[2] := sHeader[2]+ ',,,,';
  sHeader[2] := sHeader[2]+ ',,,,';
  sHeader[2] := sHeader[2]+ ',,,,,';
  sHeader[2] := sHeader[2]+ ',,,,,';
  sHeader[2] := sHeader[2]+ ',';

  // for data.
  sTemp := FormatDateTime('yyyymmdd', PasScr[nCh].m_TestRet.StartTime);
  // 'Date/Time','User_ID','S/W_VER','Script_VER','PG_FW/FPGA/MDM/PWR'
  sData := format('%s,%s,%s,%s',[sTemp,Common.m_sUserId,Common.GetVersionDate,sPgVer]);
  sData := sData + format(',%s(%s),%s(%s)',[Common.m_Ver.isu_Date,Common.m_Ver.isu_Crc,Common.m_Ver.psu_Date,Common.m_Ver.psu_Crc]);
  sData := sData + format(',%s,%s,%s,%s',[Common.m_Ver.OcParam,Common.m_Ver.OcVerify,Common.m_Ver.OtpTable,Common.m_Ver.OcOffSet]);
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

procedure TfrmMain_GB.MakeOpticSummaryCsvLog(sScrFileName : String; sCsvHeader : array of string; sCsvData: string);
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
procedure TfrmMain_GB.MakePlcLog;
var
  i, j : Integer;
  sDebug, sDebug2 : string;
  InData1, InData2, OutData11, OutData21, OutData12, OutData22  : Integer;
  bMakeLog : boolean;
begin
  InData1  := PlcCtl.m_nReadSig1 or (defPlc.IN_PLC_READY shl 1);
  InData2  := PlcCtl.m_nReadSig2 or (defPlc.IN_PLC_READY shl 1);
  OutData11 := PlcCtl.m_nWriteSig11 or (defPlc.OUT_PC_READY shl 1);
  OutData21 := PlcCtl.m_nWriteSig21 or (defPlc.OUT_PC_READY shl 1);

  OutData12 := PlcCtl.m_nWriteSig12;
  OutData22 := PlcCtl.m_nWriteSig22;
{      btnLogIn.Caption := 'đăng nhập';
      btnModelChange.Caption := 'thay đổi Model';
      btnModel.Caption := 'Model Info';
      btnMaint.Caption := 'Maint';
      btnStation.Caption := 'cấu hình';
      btnInit.Caption := 'khởi tạo';
      btnExit.Caption := 'Lối thoát';}
  bMakeLog := False;
  //  Input for A Stage.
  if InData1 <> m_nPlcInPre1      then bMakeLog := True;
  if bMakeLog then begin
    sDebug := '[STAGE A IO  INPUT CHECK] :';
    sDebug2 := '';
    for i := 0 to defPlc.MAX_INPUT_CNT do begin
      if i = 1 then Continue;

      if  m_bPlcIn[DefCommon.JIG_A,i] then begin
        sDebug := sDebug + Format(' %0.2x,',[i]);
        case i of
          0 : sDebug2 := sDebug2 + ' PLC_READY';
          4.. 7 : sDebug2 := sDebug2 + Format(' LOAD_COMPLT%d',[i-3]);
          9 : sDebug2 := sDebug2 + ' START_INS';
          10 : sDebug2 := sDebug2 + ' NO_ALARM';
          11..15 :  sDebug2 := sDebug2 + Format(' UNLOAD_COMPLT%d',[i-10]);
        end;
      end;
    end;
    sDebug := sDebug + '(' + sDebug2 + ')';
    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);
  end;
  m_nPlcInPre1 := InData1;
  // Input B Stage.
  bMakeLog := False;
  if InData2 <> m_nPlcInPre2      then bMakeLog := True;
  if bMakeLog then begin
    sDebug := '[STAGE B IO  INPUT CHECK] :';
    sDebug2 := '';
    for i := 0 to defPlc.MAX_INPUT_CNT do begin
      if i = 1 then Continue;

      if  m_bPlcIn[DefCommon.JIG_B,i] then begin
        sDebug := sDebug + Format(' %0.2x,',[i]);
        case i of
          0 : sDebug2 := sDebug2 + ' PLC_READY';
          4.. 7 : sDebug2 := sDebug2 + Format(' LOAD_COMPLT%d',[i-3]);
          9 : sDebug2 := sDebug2 + ' START_INS';
          10 : sDebug2 := sDebug2 + ' NO_ALARM';
          11..15 :  sDebug2 := sDebug2 + Format(' UNLOAD_COMPLT%d',[i-10]);
        end;
      end;
    end;
    sDebug := sDebug + '(' + sDebug2 + ')';
    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);
  end;
  m_nPlcInPre2 := InData2;

  // Stage A Output.
  bMakeLog := False;
  if OutData11 <> m_nPlcOutPre11  then bMakeLog := True;
  if OutData12 <> m_nPlcOutPre12  then bMakeLog := True;
  if bMakeLog then begin
    sDebug :='[STAGE A IO OUTPUT CHECK] :';  sDebug2 := '';
    for j := 0 to defPlc.MAX_OUT_CNT do begin
      if  m_bPlcOut[DefCommon.JIG_A,j] then begin
        if j = 1 then Continue;
        case j of
          0 : sDebug2 := sDebug2 + ' PC_READY';
          3 : sDebug2 := sDebug2 + ' PROBE_BACK';
          5.. 8 : sDebug2 := sDebug2 + Format(' CH%d_SEL',[j-4]);
          9 : sDebug2 := sDebug2 + ' LOAD_REQ';
          10 : sDebug2 := sDebug2 + ' FINISH_WORK';
          11..15 :  sDebug2 := sDebug2 + Format(' NG_CH%d',[j-10]);
          16.. 19 : sDebug2 := sDebug2 + Format(' CH%d_READY',[j-15]);
          24.. 27 : sDebug2 := sDebug2 + Format(' CH%d_DETECT',[j-23]);
        end;
        sDebug := sDebug + Format(' %0.2x,',[j]);
      end;
    end;
    sDebug := sDebug + '(' + sDebug2 + ')';
    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);

  end;
  m_nPlcOutPre11 := OutData11;
  m_nPlcOutPre12 := OutData12;

  bMakeLog := False;
  if OutData21 <> m_nPlcOutPre21  then bMakeLog := True;
  if OutData22 <> m_nPlcOutPre22  then bMakeLog := True;
  if bMakeLog then begin
    sDebug :='[STAGE B IO OUTPUT CHECK] :';
    sDebug2 := '';
    for j := 0 to defPlc.MAX_OUT_CNT do begin
      if  m_bPlcOut[DefCommon.JIG_B,j] then begin
        if j = 1 then Continue;
        case j of
          0 : sDebug2 := sDebug2 + ' PC_READY';
          3 : sDebug2 := sDebug2 + ' PROBE_BACK';
          5.. 8 : sDebug2 := sDebug2 + Format(' CH%d_SEL',[j-4]);
          9 : sDebug2 := sDebug2 + ' LOAD_REQ';
          10 : sDebug2 := sDebug2 + ' FINISH_WORK';
          11..15 :  sDebug2 := sDebug2 + Format(' NG_CH%d',[j-10]);
          16.. 19 : sDebug2 := sDebug2 + Format(' CH%d_READY',[j-15]);
          24.. 27 : sDebug2 := sDebug2 + Format(' CH%d_DETECT',[j-23]);
        end;
        sDebug := sDebug + Format(' %0.2x,',[j]);
      end;
    end;
    sDebug := sDebug + '(' + sDebug2 + ')';
    common.MLog(DefCommon.MAX_PLC_LOG,sDebug);
  end;
  m_nPlcOutPre21 := OutData21;
  m_nPlcOutPre22 := OutData22;
end;

procedure TfrmMain_GB.MakePlcSig;
var
  i: Integer;
  nWidth, nHeight, nTopPos : Integer;
  sPlcHint : string;
begin
  nWidth := 35;
  nHeight := 16;
  nTopPos := pnlPlcA.Top + pnlPlcA.Height + 1;
  for i := 0 to Pred(defPlc.MAX_INPUT_CNT) do begin
    ledPlcIn[i] := TTILed.Create(Self);
    ledPlcIn[i].Parent := grpPlc;
    ledPlcIn[i].Left := pnlPlcA.Left;
    ledPlcIn[i].Top  := nTopPos + i*(nHeight);
    ledPlcIn[i].Width := nWidth;
    ledPlcIn[i].Height := nHeight;
    ledPlcIn[i].LedColor := TLedColor(Green);
    ledPlcIn[i].StyleElements := [seBorder];
    ledPlcIn[i].Caption := Format('0.%X',[i]);
    sPlcHint := '';
    case i of
      defPlc.IDX_IN_PLC_READY   : sPlcHint := 'PLC Ready';
      defPlc.IDX_IN_COMPLETE_1  : sPlcHint := 'Supply Complete #1';
      defPlc.IDX_IN_COMPLETE_2  : sPlcHint := 'Supply Complete #2';
      defPlc.IDX_IN_COMPLETE_3  : sPlcHint := 'Supply Complete #3';
      defPlc.IDX_IN_COMPLETE_4  : sPlcHint := 'Supply Complete #4';
      defPlc.IDX_IN_LOT_FINISH  : sPlcHint := 'Start Inspection';
      defPlc.IDX_IN_PAUSE_PROBE : sPlcHint := 'NO Problem Robot & Probe Position';
      defPlc.IDX_IN_UNLOADED_1  : sPlcHint := 'Carrier Out Complete #1';
      defPlc.IDX_IN_UNLOADED_2  : sPlcHint := 'Carrier Out Complete #2';
      defPlc.IDX_IN_UNLOADED_3  : sPlcHint := 'Carrier Out Complete #3';
      defPlc.IDX_IN_UNLOADED_4  : sPlcHint := 'Carrier Out Complete #4';
    end;
    if sPlcHint <> '' then ledPlcIn[i].ShowHint := True;
    ledPlcIn[i].Hint     := sPlcHint;
  end;
  for i := 0 to Pred(defPlc.MAX_OUT_CNT) do begin
    ledPlcOut[i] := TTILed.Create(Self);
    ledPlcOut[i].Parent := grpPlc;

    if i < defPlc.MAX_INPUT_CNT then begin
      ledPlcOut[i].Left := nWidth + pnlPlcA.Left;
      ledPlcOut[i].Top  := nTopPos + i*(nHeight);
      ledPlcOut[i].Caption := Format('1.%X',[i]);
      sPlcHint := '';
      case i of
        defPlc.IDX_OUT_PC_READY   : sPlcHint := 'PC Ready';
        defPlc.IDX_OUT_BLINK      : sPlcHint := 'Checking CONNECTION';
        defPlc.IDX_OUT_CA310_BACK_1 : sPlcHint := 'PROBE FRONT POSITION';
        defPlc.IDX_OUT_SEL_CH_1   : sPlcHint := 'SELECT Channel #1';
        defPlc.IDX_OUT_SEL_CH_2   : sPlcHint := 'SELECT Channel #2';
        defPlc.IDX_OUT_SEL_CH_3   : sPlcHint := 'SELECT Channel #3';
        defPlc.IDX_OUT_SEL_CH_4   : sPlcHint := 'SELECT Channel #4';
        defPlc.IDX_OUT_LOAD_REQ   : sPlcHint := 'Load Request';
        defPlc.IDX_OUT_UNLOAD_REQ : sPlcHint := 'Unload Request';
        defPlc.IDX_OUT_COMPLETE   : sPlcHint := 'INSPECTION Complete';
        defPlc.IDX_OUT_NG_CH1     : sPlcHint := 'NG Channel #1';
        defPlc.IDX_OUT_NG_CH2     : sPlcHint := 'NG Channel #2';
        defPlc.IDX_OUT_NG_CH3     : sPlcHint := 'NG Channel #3';
        defPlc.IDX_OUT_NG_CH4     : sPlcHint := 'NG Channel #4';
      end;

    end
    else begin
      ledPlcOut[i].Left := nWidth*2 + pnlPlcA.Left;
      ledPlcOut[i].Top  := nTopPos + (i-defPlc.MAX_INPUT_CNT)*(nHeight);
      ledPlcOut[i].Caption := Format('2.%X',[i-defPlc.MAX_INPUT_CNT]);
      sPlcHint := '';
      case i of
        defPlc.IDX_OUT_READY_1    : sPlcHint := 'Channel Ready #1';
        defPlc.IDX_OUT_READY_2    : sPlcHint := 'Channel Ready #2';
        defPlc.IDX_OUT_READY_3    : sPlcHint := 'Channel Ready #3';
        defPlc.IDX_OUT_READY_4    : sPlcHint := 'Channel Ready #4';
      end;
    end;
    ledPlcOut[i].Width := nWidth;
    ledPlcOut[i].Height := nHeight;
    ledPlcOut[i].LedColor := TLedColor(Yellow);
    ledPlcOut[i].StyleElements := [seBorder];

    if sPlcHint <> '' then ledPlcOut[i].ShowHint := True;
    ledPlcOut[i].Hint     := sPlcHint;
  end;

  for i := 0 to Pred(defPlc.MAX_INPUT_CNT) do begin
    ledPlcIn2[i] := TTILed.Create(Self);
    ledPlcIn2[i].Parent := grpPlc;
    ledPlcIn2[i].Left := pnlPlcB.Left;
    ledPlcIn2[i].Top  := nTopPos + i*(nHeight);
    ledPlcIn2[i].Width := nWidth;
    ledPlcIn2[i].Height := nHeight;
    ledPlcIn2[i].LedColor := TLedColor(Green);
    ledPlcIn2[i].StyleElements := [seBorder];
    ledPlcIn2[i].Caption := Format('0.%X',[i]);
    sPlcHint := '';
    case i of
      defPlc.IDX_IN_PLC_READY   : sPlcHint := 'PLC Ready';
      defPlc.IDX_IN_COMPLETE_1  : sPlcHint := 'Supply Complete #1';
      defPlc.IDX_IN_COMPLETE_2  : sPlcHint := 'Supply Complete #2';
      defPlc.IDX_IN_COMPLETE_3  : sPlcHint := 'Supply Complete #3';
      defPlc.IDX_IN_COMPLETE_4  : sPlcHint := 'Supply Complete #4';
      defPlc.IDX_IN_LOT_FINISH  : sPlcHint := 'Start Inspection';
      defPlc.IDX_IN_PAUSE_PROBE : sPlcHint := 'NO Problem Robot & Probe Position';
      defPlc.IDX_IN_UNLOADED_1  : sPlcHint := 'Carrier Out Complete #1';
      defPlc.IDX_IN_UNLOADED_2  : sPlcHint := 'Carrier Out Complete #2';
      defPlc.IDX_IN_UNLOADED_3  : sPlcHint := 'Carrier Out Complete #3';
      defPlc.IDX_IN_UNLOADED_4  : sPlcHint := 'Carrier Out Complete #4';
    end;
    if sPlcHint <> '' then ledPlcIn2[i].ShowHint := True;
    ledPlcIn2[i].Hint     := sPlcHint;
  end;
  for i := 0 to Pred(defPlc.MAX_OUT_CNT) do begin
      ledPlcOut2[i] := TTILed.Create(Self);
      ledPlcOut2[i].Parent := grpPlc;
    if i < defPlc.MAX_INPUT_CNT then begin
      ledPlcOut2[i].Left := nWidth + pnlPlcB.Left;
      ledPlcOut2[i].Top  := nTopPos + i*(nHeight);
      ledPlcOut2[i].Caption := Format('1.%X',[i]);
      sPlcHint := '';
      case i of
        defPlc.IDX_OUT_PC_READY   : sPlcHint := 'PC Ready';
        defPlc.IDX_OUT_BLINK      : sPlcHint := 'Checking CONNECTION';
        defPlc.IDX_OUT_CA310_BACK_1 : sPlcHint := 'PROBE FRONT POSITION';
        defPlc.IDX_OUT_SEL_CH_1   : sPlcHint := 'SELECT Channel #1';
        defPlc.IDX_OUT_SEL_CH_2   : sPlcHint := 'SELECT Channel #2';
        defPlc.IDX_OUT_SEL_CH_3   : sPlcHint := 'SELECT Channel #3';
        defPlc.IDX_OUT_SEL_CH_4   : sPlcHint := 'SELECT Channel #4';
        defPlc.IDX_OUT_LOAD_REQ   : sPlcHint := 'Load Request';
        defPlc.IDX_OUT_UNLOAD_REQ : sPlcHint := 'Unload Request';
        defPlc.IDX_OUT_COMPLETE   : sPlcHint := 'INSPECTION Complete';
        defPlc.IDX_OUT_NG_CH1     : sPlcHint := 'NG Channel #1';
        defPlc.IDX_OUT_NG_CH2     : sPlcHint := 'NG Channel #2';
        defPlc.IDX_OUT_NG_CH3     : sPlcHint := 'NG Channel #3';
        defPlc.IDX_OUT_NG_CH4     : sPlcHint := 'NG Channel #4';
      end;
    end
    else begin
      ledPlcOut2[i].Left := nWidth*2 + pnlPlcB.Left;
      ledPlcOut2[i].Top  := nTopPos + (i-defPlc.MAX_INPUT_CNT)*(nHeight);
      ledPlcOut2[i].Caption := Format('2.%X',[i-defPlc.MAX_INPUT_CNT]);
      sPlcHint := '';
      case i of
        defPlc.IDX_OUT_READY_1    : sPlcHint := 'Channel Ready #1';
        defPlc.IDX_OUT_READY_2    : sPlcHint := 'Channel Ready #2';
        defPlc.IDX_OUT_READY_3    : sPlcHint := 'Channel Ready #3';
        defPlc.IDX_OUT_READY_4    : sPlcHint := 'Channel Ready #4';
      end;
    end;
    ledPlcOut2[i].Width := nWidth;
    ledPlcOut2[i].Height := nHeight;
    ledPlcOut2[i].LedColor := TLedColor(Yellow);
    ledPlcOut2[i].StyleElements := [seBorder];

    if sPlcHint <> '' then ledPlcOut2[i].ShowHint := True;
    ledPlcOut2[i].Hint     := sPlcHint;
  end;
//  for i := 0 to Pred(DefDio.MAX_IN_CNT) do begin
//    ledDioIn[i].Caption :=  Trim(arInputNormal[i]);
//  end;
//  for i := 0 to Pred(DefDio.MAX_OUT_CNT) do begin
//    ledDioOut[i].Caption :=  Trim(arOutputNormal[i]);
//  end;



end;

//procedure TfrmMain_GB.MakeSummaryCsvLog(sScrFileName, sHeader, sData: string);
//var
//  sFileName, sFilePath       : string;
//	txtF                       : Textfile;
//begin
//  sFilePath := Common.Path.SumCsv+formatDateTime('yyyymm',now) + '\';
//  sFileName := sFilePath + sScrFileName;// Common.SystemInfo.EQPId +'_OC_Summary_'+ formatDateTime('yyyymmdd',now) + '.csv';
//  if Common.CheckDir(sFilePath) then Exit;
//  if IOResult = 0 then begin
//    try
//        AssignFile(txtF, sFileName);
//        // File Check!
//        if not FileExists(sFileName) then begin
//          Rewrite(txtF);
//          WriteLn(txtF, sHeader);
//        end
//        else begin
//          Append(txtF);
//        end;
//        WriteLn(txtF, sData);
//    finally
//      // Close the file
//      CloseFile(txtF);
//    end;
//  end;
//end;

procedure TfrmMain_GB.OnMesMsg(nMsgType, nPg: Integer; bError: Boolean; sErrMsg: string);
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
        frmTest4ChGB[i].SetHostConnShow(True);
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

procedure TfrmMain_GB.ReadPlcStatus(nRet: Integer; sMsg: String);
begin
  if nRet <> 0 then begin
    ledPlc.Value := False;
    pnlPlcStatus.Caption := sMsg;
  end
  else begin
    ledPlc.Value := True;
    pnlPlcStatus.Caption := sMsg;
  end;
end;

procedure TfrmMain_GB.ReleaseReadyModOnPlc;
var
  nCh : Integer;
begin
  if PlcCtl <> nil then begin
    PlcCtl.writePlc(DefCommon.JIG_A, defPlc.IDX_FIRST_WORD,defPlc.OUT_PC_READY,True);
    PlcCtl.writePlc(DefCommon.JIG_B, defPlc.IDX_FIRST_WORD,defPlc.OUT_PC_READY,True);
    if btnAutoReady.Tag <> 0 then begin
      btnAutoReady.OnClick(nil);
    end;
  end
  else begin
    Exit;
  end;
end;

procedure TfrmMain_GB.RzBitBtn1Click(Sender: TObject);
var
  sModelType : string;
  sFileName : string;
  i: Integer;
begin
  sModelType := Common.GetModelType(2,Common.SystemInfo.TestModel);
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    Common.m_RgbAvr[i].IsReady := False;
    sFileName := Common.Path.OtpCfg + format('JIG_%X_%s_PASS_RGB_DATA.txt',[i + 10,sModelType]);
    if FileExists(sFileName) then begin
      DeleteFile(sFileName);
    end;
  end;
end;

procedure TfrmMain_GB.ShowAlarmMsg(sMsg: string);
begin
  if frmPlcAlarm <> nil  then begin
    frmPlcAlarm.lblShow.Caption := sMsg;
    frmPlcAlarm.RzBitBtn1.Visible := False;
  end
  else begin
    frmPlcAlarm  := TfrmNgMsg.Create(nil);
    frmPlcAlarm.RzBitBtn1.Visible := False;
    try
      frmPlcAlarm.lblShow.Caption := sMsg;
      frmPlcAlarm.ShowModal;
    finally
      frmPlcAlarm.Free;
      frmPlcAlarm := nil;
    end;
  end;


{procedure TfrmMain_Pocb.ShowAlarmMsg(sMsg: string);
begin
  if frmPlcAlarm <> nil  then begin
    frmPlcAlarm.lblShow.Caption := sMsg;
    frmPlcAlarm.RzBitBtn1.Visible := False;
  end
  else begin
    frmPlcAlarm  := TfrmNgMsg.Create(nil);
    frmPlcAlarm.RzBitBtn1.Visible := False;
    try
      frmPlcAlarm.lblShow.Caption := sMsg;
      frmPlcAlarm.ShowModal;
    finally
      frmPlcAlarm.Free;
      frmPlcAlarm := nil;
    end;
  end;
end;}
end;

procedure TfrmMain_GB.ShowNgMessage(sMessage: string);
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

procedure TfrmMain_GB.tmrDisplayTestFormTimer(Sender: TObject);
var
  i: Integer;
  sStageARev, sStageBRev, sStageASet, sStageBSet : string;
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
    frmTest4ChGB[i] := TfrmTest4ChGB.Create(self);
    frmTest4ChGB[i].Tag := i;
    frmTest4ChGB[i].Height := (Self.Height div 2) - tolGroupMain.Top - tolGroupMain.Height - (pnlSubTool.Height div 2) - 20 ;
    frmTest4ChGB[i].Width  := Self.Width - (pnlSysInfo.Width + pnlSysInfo.Left) - 20 ;
    frmTest4ChGB[i].Left   := 0;
    frmTest4ChGB[i].Top    := frmTest4ChGB[i].Height * i;
    frmTest4ChGB[i].Visible := True;
    frmTest4ChGB[i].ShowGui(Self.Handle);

    frmTest4ChGB[i].Caption := Format('%X Stage',[i+10]);
    if not Common.SystemInfo.UseAutoBCR then begin
      frmTest4ChGB[i].SetBcrData;
    end;
  end;
//  Common.MLog(DefCommon.MAX_SYSTEM_LOG,'2');
//  nCh := 0;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if Logic[i] = nil then Exit;
  end;
  // UDP Server가 Data를 입력 받을 Timming ....
  UdpServer.FIsReadyToRead := True;

  for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
    m_bDioIn[i] := False;
    m_bDioOut[i] := False;
  end;
  // Main의 Creat에 놔두변 오류 발생시 MDI 오류 발생.
  AxDio := TAxDio.Create(Self.Handle,DefDio.DONGA_60X60_CH,200);
  AxDio.InDioStatus := MainDioStatus;
  // Set Auto Dio Control.
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    frmTest4ChGB[i].SetProbeAutoControl;
  end;

  if not Common.SystemInfo.OcManualType then begin
    // 현재 설정된 PLC IP와 Address 정보가 다르면 NG 처리.
    if Trim(Common.GetLocalIpList(DefCommon.IP_LOCAL_PLC,Common.SystemInfo.LocalIP_PLC)) <> '' then begin
      sStageARev :=  Common.SystemInfo.RobotRevA;
      sStageBRev :=  Common.SystemInfo.RobotRevB;
      sStageASet :=  Common.SystemInfo.RobotOutA;
      sStageBSet :=  Common.SystemInfo.RobotOutB;
      if Common.GetConfigInfo(sStageARev,sStageASet,sStageBRev,sStageBSet) then begin
        m_nPlcInPre1 := 0;
        m_nPlcInPre2 := 0;
        m_nPlcOutPre11 := 0;
        m_nPlcOutPre12 := 0;
        m_nPlcOutPre21 := 0;
        m_nPlcOutPre22 := 0;

        PlcCtl := TPlc.Create(Self.Handle,sStageARev, sStageBRev, sStageASet, sStageBSet);
        PlcCtl.OnPlcConnect := ReadPlcStatus;
        PlcCtl.OnPlcRead := MainPlcStatus ;
        PlcCtl.OnPlcAutoFlow := AutoStart;
        Common.Delay(200);

        btnLogIn.Click;
        btnAutoReady.Click;
      end
      else begin
//        ShowNgMessage('[PLC] Local IP Configuration NG!(Config file)');
        ShowNgMessage('[PLC] cài đặt ip cấu hình kông giống với cài đặt ip từ máy tình! tập tin cấu hình'+#13+' (The IP setting is not the same as the IP from PC : Config file)');
      end;
    end
    else begin
      // Display NG Message.
      ShowNgMessage('[PLC] cài đặt ip cấu hình kông giống với cài đặt ip từ máy tình '+#13+'(The IP setting is not the same as the IP from PC!: PLC IP is not Match)');
    end;
  end
  else begin
    btnLogIn.Click;
  end;
  // Added by ClintPark 2018-06-02 오후 3:38:14 JNCD 기능 DP076에서 빠짐
  // DLL에 문제가 많기 때문에 추후 OLE Variant 부분 확인 필요.
//  Jncd := TJncd.Create;
end;

procedure TfrmMain_GB.tmrMemCheckTimer(Sender: TObject);
var
  sCmd : string;
begin
  sCmd := FormatFloat('#,',Common.ProcessMemory);
  pnlMemCheck.Caption := 'MEMORY CHECK : '+sCmd + ' Bytes';
end;

procedure TfrmMain_GB.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, nTemp : Integer;
  sMsg, sSubMsg, sFileName, sDebug : string;
  sCsvHeader : array [0..2] of string;
  sCsvData : string;
begin
  nType := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
  case nType of
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
        DefCommon.MSG_MODE_DIO_SEN_NG : begin
          ShowNgMessage(sMsg);
        end;
      end;
    end;
    DefCommon.MSG_TYPE_CA310 : begin
      nMode := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgMode;
      nTemp := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      // nCh은 해당 Jig로 사용.
      case nMode of
        DefCommon.MSG_MODE_CA310_STATUS : begin
          // nTemp = 0 이면 해당 Channel 사용하지 않음. 아니면 사용.
          if nTemp = 0 then begin
            case nCh of
              DefCommon.JIG_A : begin
                ledCa310Up.FalseColor := clGray;
                ledCa310Up.Value := False;
                pnlCa310Com1.Caption := 'NONE';
              end;
              DefCommon.JIG_B : begin
                ledCa310Dn.FalseColor := clGray;
                ledCa310Dn.Value := False;
                pnlCa310Com2.Caption := 'NONE';
              end;
            end;
          end
          else begin
            nTemp := Common.SystemInfo.Com_Ca310[nCh];
            if nTemp in [10,11] then begin
              sSubMsg := Format('USB %d',[nTemp - 9]);
            end
            else begin
              sSubMsg := Format('COM %d',[nTemp]);
            end;
            sMsg  := Format('Stage %X CA310 ERROR : ',[10+nCh]) + PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
            case nCh of
              DefCommon.JIG_A : begin
                ledCa310Up.FalseColor := clRed;
                pnlCa310Com1.Caption := sSubMsg;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCa310Up.Value := False;
                  ShowNgMessage(sMsg);
                end
                else begin
                  ledCa310Up.Value := True;
                end;
              end;
              DefCommon.JIG_B : begin
                ledCa310Dn.FalseColor := clRed;
                pnlCa310Com2.Caption := sSubMsg;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCa310Dn.Value := False;
                  ShowNgMessage(sMsg);
                end
                else begin
                  ledCa310Dn.Value := True;
                end;
              end;
            end;
          end;

        end;
        DefCommon.MSG_MODE_CA310_NG : begin
          if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
            ShowAlarmMsg(PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          end;
        end;
        DefCommon.MSG_MODE_CA310_ERROR_MSG : begin
          if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
            Common.MLog(DefCommon.MAX_SYSTEM_LOG,PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          end;
        end;


      end;


    end;
    DefCommon.MSG_TYPE_SCRIPT : begin
      nMode := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_LOG_CSV : begin
//          MakeCsvData(sFileName , sHeader, sData, nCh);
//          MakeSummaryCsvLog(sFileName ,sHeader, sData);
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
