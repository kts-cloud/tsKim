unit Main_OC;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ALed, RzPanel, RzButton, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList,
  Vcl.Themes, System.UITypes, TILed, pasScriptClass, System.DateUtils, CommCameraRadiant, CommDIO_DAE, ControlDio_OC,
  CommonClass, UserID, GMesCom, DefCommon, DefGmes, NGMsg, ModelInfo, Mainter, LogIn, HandBCR, DefDio,
  CommLightNaratech, Vcl.AppEvnts, Vcl.StdCtrls, Vcl.ComCtrls, AdvListV,  DfsFtp, CommIonizer, JigControl, DefScript,
  {UdpServerClient,} Test4ChOC, SwitchBtn, ScriptClass, ModelSelect, {ModelDownload,} SystemSetup, RzStatus,
  DoorOpenAlarmMsg, CommPLC_ECS, ECSStatusForm, DBModule, NGRatioForm,ShellApi
  , CA_SDK2, dllClass,CommPG,DefPG, Registry, Inifiles,DllMesCom ,OtlTaskControl, OtlParallel

;
  {$I Common.inc}
type
  TfrmMain_OC = class(TForm)
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
    btnSetup: TRzToolButton;
    btnMaint: TRzToolButton;
    ilFlag: TImageList;
    pnlSysInfo: TRzPanel;
    grpSystemInfo: TRzGroupBox;
    RzGroupBox5: TRzGroupBox;
    pnlEQPID: TRzPanel;
    pnlStationNo: TRzPanel;
    RzGroupBox3: TRzGroupBox;
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
    grpDIO: TRzGroupBox;
    RzStatusPane3: TRzStatusPane;
    pnlStLocalIp: TRzStatusPane;
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
    RzPanel8: TRzPanel;
    ledHandBcr: ThhALed;
    pnlHandBcr: TRzPanel;
    pnlSwA: TRzPanel;
    ledSwJigA: ThhALed;
    RzPanel3: TRzPanel;
    RzPanel10: TRzPanel;
    pnlIonizer: TRzPanel;
    ledIonizer: ThhALed;
    stsCpuTemp: TRzStatusPane;
    tmrWatch: TTimer;
    grpPwrInfo: TRzGroupBox;
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
    btnShowNGRatio: TRzBitBtn;
    tmDioAlarm: TTimer;
    tmNgMsg: TTimer;
    pnlSubTitle: TPanel;
    mmoSysLog: TRichEdit;
    pnlMesReady: TPanel;
    btnLogIn: TRzToolButton;
    lblMesReady: TLabel;
    pnlPlcReady: TPanel;
    btnAutoReady: TRzToolButton;
    lblPlcReady: TLabel;
    RzPanel13: TRzPanel;
    pnlModelConfig: TRzPanel;
    pnlDioTop: TRzPanel;
    ledDio: ThhALed;
    pnlDioStatus: TRzPanel;
    RzPanel5: TRzPanel;
    ledPlc: ThhALed;
    pnlPlcStatus: TRzPanel;
    btnShowECSStatus: TRzBitBtn;
    lvPower: TAdvListView;
    ApplicationEvents1: TApplicationEvents;
    btnShowAlarm: TRzBitBtn;
    RzPanel15: TRzPanel;
    pnlEAS: TRzPanel;
    ledEAS: ThhALed;
    grpAutoTester: TRzGroupBox;
    btnStartAutoTest: TRzBitBtn;
    btnStopAutoTest: TRzBitBtn;
    ledIonizer2: ThhALed;
    pnlIonizer2: TRzPanel;
    ledSwJigB: ThhALed;
    pnlSwB: TRzPanel;
    tmSaveEnergy: TTimer;
    RzPanel1: TRzPanel;
    hhALed1: ThhALed;
    pnlR2R: TRzPanel;
    ledR2R: ThhALed;
    Button1: TButton;
    RzPanel11: TRzPanel;
    pnlLGDDLLName: TRzPanel;
    procedure FormCreate(Sender: TObject);
    procedure MyExceptionHandler(Sender : TObject; E : Exception );
    procedure btnInitClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure tmrDisplayTestFormTimer(Sender: TObject);
    procedure btnLogInClick(Sender: TObject);
    procedure btnModelChangeClick(Sender: TObject);
    procedure btnModelClick(Sender: TObject);
    procedure btnSetupClick(Sender: TObject);
    procedure btnMaintClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure WMCopyData_PG(var CopyMsg: TMessage);



    procedure WMPostMessage(var Msg : TMessage); message WM_USER + 1;
    function IsHeaderExist( asHeaders : array of string) : Boolean;
    procedure tmrMemCheckTimer(Sender: TObject);
    procedure tmAlarmMsgTimer(Sender: TObject);
    procedure btnShowNGRatioClick(Sender: TObject);
    procedure tmDioAlarmTimer(Sender: TObject);
    procedure tmNgMsgTimer(Sender: TObject);
    procedure btnAutoReadyClick(Sender: TObject);
    procedure btnShowECSStatusClick(Sender: TObject);
    procedure ApplicationEvents1ShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure tmrWatchTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnShowAlarmClick(Sender: TObject);
    procedure btnStartAutoTestClick(Sender: TObject);
    procedure btnStopAutoTestClick(Sender: TObject);
    procedure tmSaveEnergyTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure RzPanel6DblClick(Sender: TObject);
  private
    { Private declarations }
    // DIO
    ledDioIn,   ledDioOut : array[0.. DefDio.MAX_IN_CNT] of  TTILed;
    m_bIsClose : boolean;
    DongaSwitch     :array [0..DefCommon.MAX_SWITCH_CNT] of TSerialSwitch;
//    DongaBCR        : array [0..DefCommon.MAX_BCR_CNT] of TSerialBcr;
    m_sNgMsg : string;
    m_bSaveEnergy, m_bSaveEnergyChnage : Boolean;
    function CheckAdminPasswd : boolean;
    procedure initform;
    procedure DisplayScriptInfo;
    procedure InitialAll(bReset : Boolean = True);
    procedure GetBcrConnStatus( bConnected : Boolean; sMsg : string);
    procedure CreateClassData;
    procedure Login_MES;
    procedure Login_ECS;
    function  DisplayLogIn : Integer;
    function InitGmes : Boolean;
    procedure ShowNgMessage(sMessage: string);

    procedure DongaGmesEvent(nMsgType, nPg: Integer;bError : Boolean; sErrMsg : string);
    procedure MakeDioSig;
    procedure ShowNgAlarm(sNgMsg : string;bIsFrmClose : Boolean = False);
    // Style 변경 완료후 Main과 Test의 Handle값이 변경 됨. == > 이벤트 처리하기 위함.
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;

    procedure SaveCsvSummaryLog(nCh : Integer);
    procedure MakeCsvApdrLog(nCh: Integer);

    procedure ReleaseReadyModOnPlc;
    function CheckScriptRun : Boolean;
    procedure UpdatePwrGui;
    procedure InitDfs;
    procedure Display_Memory_DI;
    procedure Display_Memory_DO;

    procedure DisplayMes(bIsOn : Boolean);
    procedure DisplayECS(bLogin: Boolean);
    procedure SetEcsMesPosition;
    procedure ShowSysLog(sMsg : string; nType : Integer = 0);
    procedure DongaSwitchRevSwDataJig(nGroup : Integer; sGetData: String);
    procedure ProcessMsg_STAGE(pGUIMsg: PGUIMessage);
    procedure ProcessMsg_COMM_DIO(pGUIMsg: PGUIMessage);
    procedure ProcessMsg_COMM_ECS(pGUIMsg: PGUIMessage);
    procedure ProcessMsg_SCRIPT(pGUIMsg: PGUIMessage);
    procedure Robot_Request_Exchange(nCh: Integer);
    procedure Robot_Request_LoadUnLoad(nCh: Integer);

    procedure ThreadTask(Task: TProc);
    procedure Update_Stage_Position(nStage: Integer);
    procedure UpdateECS_Glass_Position(nCh: Integer);
    procedure UpdateECS_Glass_Position_Pair(nStage, nPair: Integer);
    function CheckReadyToAutoStart(nPair: Integer): Boolean;
    function CheckLoad_Used(nStage, nPair: Integer): Boolean;
    function CheckDetect_Loaded( nCH: Integer): Boolean;


    function CheckDetect_Empty(nStage: Integer): Boolean;
    function CheckStage_Started(nPair: Integer): Boolean;
    function CheckState_DIO: Boolean;
//    function CheckDIO_Start(nCH : Integer) : Boolean;
    function CheckPG_Connect(nStage: Integer): Boolean;
    function CheckCAM_Connect(nStage: Integer): Boolean;

    function GetStageNo_LoadZone: Integer;
    procedure StartAutoProcess;
//    procedure ThreadTurnStage;
//    procedure Execute_AutoStart(nCH : Integer);
    procedure Set_AlarmData(nIndex, nValue, nType: Integer);
    procedure Set_AutoMode(bAuto: Boolean);
    procedure Set_Login(bLogin: Boolean);
    procedure Init_AlarmMessage;
    procedure SendMsgAddLog(nMsgMode, nParam, nParam2: Integer; sMsg: String; pData: Pointer=nil);
    function IsStageWorking(nStage: Integer=2): Boolean;
    procedure AddLog_AllCh(sLog: String);
    procedure WMSyscommandBroadcast(var Msg: TMessage);
  public
    { Public declarations }
    function CheckEmpty_Pair(nStage, nPair: Integer): Boolean;
    function CheckProbe(nCH: Integer): Boolean;
    function CheckPinBlock(nCH : Integer) : Boolean;
    procedure DoAlarmReset;
    procedure Execute_AutoStart(nCH : Integer);

  end;

var
  frmMain_OC: TfrmMain_OC;

implementation


{$R *.dfm}

uses DefCam, DioDisplayAlarm, SelectDetect;

procedure TfrmMain_OC.AddLog_AllCh(sLog: String);
var
  i: Integer;
begin
  for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i, 'Program InitialAll');
end;

procedure TfrmMain_OC.ApplicationEvents1ShortCut(var Msg: TWMKey; var Handled: Boolean);
//var
//  nShift, nControl, nAlt: SmallInt;
begin
  if Self.Enabled = False then Exit;
(*
  nShift:= GetKeyState(VK_SHIFT) and $8000;
  nControl:= GetKeyState(VK_CONTROL) and $8000;;
  nAlt:= GetKeyState(VK_MENU) and $8000;;

  if (nShift = 0) and (nControl = 0) and (nAlt = 0) then begin
    //순수키일 경우에만 - Alt + F4 방지
    case Msg.CharCode of
      VK_F2: begin
          btnModelChangeClick(self);
          Handled:= True;
      end;
      VK_F3: begin
          btnModelClick(self);
          Handled:= True;
      end;
      VK_F4: begin
          btnMaintClick(self);
          Handled:= True;
      end;
      VK_F5: begin
          btnSetupClick(self);
          Handled:= True;
      end;
      VK_F6: begin
          btnInitClick(self);
          Handled:= True;
      end;
    end;
  end;
*)
end;

procedure TfrmMain_OC.btnAutoReadyClick(Sender: TObject);
var
  nRet: Integer;
begin
  if g_CommPLC <> nil then begin
    if not g_CommPLC.Connected then Exit;

    nRet:= Application.MessageBox('Do you want to change Mode?', 'Confirm', MB_OKCANCEL + MB_ICONQUESTION);
    if nRet <> IDOK then Exit;

    if Common.StatusInfo.AutoMode then begin
      //수동으로 변경
      Set_AutoMode(False);
    end
    else begin
      ///자동으로 변경
//      if ControlDio.ReadInSig(IN_TEACH_MODE_SEL_KEY) then begin
//        //Teach mode일 경우 자동 시작 안함
//        ShowSysLog('Teach Mode - Can not Auto Mode');
////        ControlDio.Set_TowerLampState(LAMP_STATE_MANUAL);
////        g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_AUTO, 0); //Auto Mode Off
//        Exit;
//      end;
      Set_AutoMode(True);
    end;
  end;
end;

procedure TfrmMain_OC.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain_OC.btnInitClick(Sender: TObject);
var
  sMsg, sDebug : string;
  i : integer;
begin
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;

  sMsg :=        #13#10 + 'bạn có muốn khởi tạo chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to initialize this Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    sDebug := '[Click Event] Initialize';
    ShowSysLog(sDebug);
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
    InitialAll;
  end;
end;

procedure TfrmMain_OC.btnLogInClick(Sender: TObject);
var
  nRet: Integer;
begin

  nRet:= Application.MessageBox('Do you want to change Login?', 'Confirm', MB_OKCANCEL + MB_ICONQUESTION);
  if nRet <> IDOK then Exit;

  if Common.StatusInfo.LogIn then begin
    Set_Login(False);
  end
  else begin
    Set_Login(True);
  end;
end;

procedure TfrmMain_OC.btnMaintClick(Sender: TObject);
var
  i : Integer;
  sDebug : string;
begin
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;

  if CheckScriptRun then Exit;
  if CheckAdminPasswd then begin
    ReleaseReadyModOnPlc;
    sDebug := '[Click Event] Maint';
    ShowSysLog(sDebug);
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

procedure TfrmMain_OC.btnModelChangeClick(Sender: TObject);
var
  bChangeModel : Boolean;
  sOldModel, sDebug : string;
  i, nRet : Integer;
begin
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;

  if CheckScriptRun then Exit;

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
    ShowSysLog(sDebug);
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);

    // Fusing model Data.
    Common.LoadModelInfo(Common.SystemInfo.TestModel);
//    frmModelDownload := TfrmModelDownload.Create(Self);
//    try
//      nRet:= frmModelDownload.ShowModal;
////      if nRet = mrCancel then begin
////        for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
////          frmTest4ChOC[0].AddLog('Model Download Error!!', i, 1);
////          frmTest4ChOC[1].AddLog('Model Download Error!!', i, 1);
////        end;
////        Application.MessageBox('Model Download Error!!' + #13#10 + 'Retry Again', 'ERROR', MB_OK + MB_ICONSTOP);
////        Exit;
////      end;
//    finally
//      frmModelDownload.Free;
//      frmModelDownload := nil;
//    end;

    InitialAll;
  end;
  DisplayScriptInfo;
end;

procedure TfrmMain_OC.btnModelClick(Sender: TObject);
var
  i : Integer;
  sDebug : string;
begin
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;

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
      ShowSysLog(sDebug);
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

procedure TfrmMain_OC.btnSetupClick(Sender: TObject);
var
  i : Integer;
  sDebug : string;
begin
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;

  if CheckScriptRun then Exit;
  ReleaseReadyModOnPlc;
  if CheckAdminPasswd then begin
    sDebug := '[Click Event] System Info';
    ShowSysLog(sDebug);
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

function TfrmMain_OC.CheckAdminPasswd: boolean;
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


function TfrmMain_OC.CheckDetect_Empty(nStage: Integer): Boolean;
var
  i: Integer;
begin
  Result:= True;
  //하나라도 있으면 False
  for i := 0 to DefCommon.MAX_JIG_CH do begin
    if Common.StatusInfo.UseChannel[i + nStage*2] then begin
      if ControlDio.ReadInSig(IN_CH_1_CARRIER_SENSOR + (i*16 + (nStage*32))) then begin
        Result:= False;
        Exit;
      end;
    end;
  end;
end;

function TfrmMain_OC.CheckDetect_Loaded( nCh: Integer): Boolean;
var
  i: Integer;
begin
  Result:= True;

  for i := (nCh*2) to (nCh*2 + 1) do begin
    if Common.StatusInfo.UseChannel[i] then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin

        if not ControlDio.ReadInSig(IN_CH_1_CARRIER_SENSOR + (i*16)) then begin
          Result:= False;
          Exit;
        end;
      end
      else begin
        if not ControlDio.ReadInSig(IN_GIB_CH_1_CARRIER_SENSOR + (i*8)) then begin
          Result:= False;
          Exit;
        end;

      end;
    end;
  end;
end;


function TfrmMain_OC.CheckEmpty_Pair(nStage, nPair: Integer): Boolean;
var
  i: Integer;
begin
  Result:= True;

  for i := (nPair*2) to (nPair*2 + 1) do begin
    if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
      if not ControlDio.ReadInSig(IN_CH_1_CARRIER_SENSOR + (i*16)) then begin
        Result:= False;
        Exit;
      end;
    end
    else begin
      if not ControlDio.ReadInSig(IN_GIB_CH_1_CARRIER_SENSOR + (i*8)) then begin
        Result:= False;
        Exit;
      end;

    end;
    //end;
  end;
end;

function TfrmMain_OC.CheckStage_Started(nPair: Integer): Boolean;
var
  i: Integer;
begin
  Result:= False;
  for i := (nPair*2) to (nPair*2 + 1) do begin
    if PasScr[i].m_bIsScriptWork then begin
      Result:= True;
      Exit;
    end;
  end;
end;

function TfrmMain_OC.CheckState_DIO: Boolean;
begin
  Result:= False;
  if not ControlDio.Connected then begin
    ShowSysLog('CheckState: DIO not Connected ', 1);
    Exit;
  end;

  if Common.SystemInfo.OCType = DefCommon.OCType then begin

    if ControlDio.ReadInSig(IN_EMO_SWITCH)  then begin
      ShowSysLog('CheckState: EMS', 1);
      Exit;
    end;

    if not ControlDio.ReadInSig(IN_MC_MONITORING) then begin
      ShowSysLog('CheckState: MC MONITORING', 1);
      Exit;
    end;
  end
  else begin
    if  ControlDio.ReadInSig(IN_GIB_CH_12_EMO_SWITCH)  then begin
      ShowSysLog('CheckState: CH 1..2 EMS', 1);
      Exit;
    end;
    if  ControlDio.ReadInSig(IN_GIB_CH_34_EMO_SWITCH)  then begin
      ShowSysLog('CheckState: CH 3..4 EMS', 1);
      Exit;
    end;

    if not ControlDio.ReadInSig(IN_GIB_CH_12_MC_MONITORING) then begin
      ShowSysLog('CheckState:CH 1..2 MC MONITORING', 1);
      Exit;
    end;
    if not ControlDio.ReadInSig(IN_GIB_CH_34_MC_MONITORING) then begin
      ShowSysLog('CheckState:CH 3..4 MC MONITORING', 1);
      Exit;
    end;

  end;


  Result:= True;
end;

function TfrmMain_OC.CheckLoad_Used(nStage, nPair: Integer): Boolean;
var
  i: Integer;
begin
  //채널 사용 여부에 따른 Load 요청 여부 - Pair 중에 하나라도 사용 안할 경우 로드 안함
  Result:= True;
  for i := (nPair*2) to (nPair*2 + 1) do begin
    if not Common.StatusInfo.UseChannel[i + nStage*4] then begin
      Result:= False;
    end;
  end;
end;


function TfrmMain_OC.CheckCAM_Connect(nStage: Integer): Boolean;
begin
  Result := True;
  if Common.SimulateInfo.Use_CAM then Exit;

  if (Common.StatusInfo.UseChannel[0 + nStage*4] and Common.StatusInfo.UseChannel[1 + nStage*4]) then begin
    if (not ledCam1.Value) or (not ledCam2.Value) then begin
      Result:= False;
      Exit;
    end;
  end;

  if (Common.StatusInfo.UseChannel[2 + nStage*4] and Common.StatusInfo.UseChannel[3 + nStage*4]) then begin
    if (not ledCam3.Value) or  (not ledCam4.Value) then begin
      Result:= False;
      Exit;
    end;
  end;
end;

function TfrmMain_OC.CheckPG_Connect(nStage: Integer): Boolean;
var
i : integer;
begin
  Result := True;
  for I := DefCommon.CH1 to DefCommon.MAX_CH do  begin

    if Common.StatusInfo.UseChannel[i]  then begin
      if (Pg[i].StatusPG <> pgReady) then begin
        Result:= False;
        Exit;
      end;
    end;

  end;
end;

function TfrmMain_OC.CheckPinBlock(nCH: Integer): Boolean;
var
i : Integer;
begin
  Result := True;
  for i := (nCH*2) to (nCH*2 + 1) do begin

    if  (not ControlDio.ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_OPEN_SENSOR +i*8)) or
        (not ControlDio.ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_UNLOCK_ON_SENSOR +i*8)) or
        (not ControlDio.ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_UP_SENSOR +i*8))
    then begin
      Result := False;
      Exit;
    end;
  end;

end;

function TfrmMain_OC.CheckProbe(nCH: Integer): Boolean;
var
i : Integer;
begin
  Result := True;
  if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
    for i := (nCH*2) to (nCH*2 + 1) do begin

      if  ( ControlDio.ReadInSig(DefDio.IN_CH_1_PROBE_BACKWARD_SENSOR +i*16)) or
           ( ControlDio.ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +i*16)) then begin
        Result := False;
        Exit;
      end;
      if  (not ControlDio.ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +i*16)) or
           (not ControlDio.ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +i*16)) or
           (not ControlDio.ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +i*16)) or
           (not ControlDio.ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +i*16))  then begin
        Result := False;
        Exit;
      end;

    end;

  end
  else begin
    if  (ControlDio.ReadInSig(DefDio.IN_GIB_CH_12_PROBE_UP_SENSOR +nCH*4)) or
        (not ControlDio.ReadInSig(DefDio.IN_GIB_CH_12_PROBE_DN_SENSOR +nCH*4)) or
        (ControlDio.ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_UP_SENSOR +nCH*4)) or
        (not ControlDio.ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_DN_SENSOR +nCH*4))
    then begin
      Result := False;
      Exit;
    end;
  end;

end;

function TfrmMain_OC.CheckReadyToAutoStart(nPair: Integer): Boolean;
var
  i: Integer;
begin
  //자동 시작 여부 검사
  //캐리어가 최대 사용 개수만큼 인식 되었는가?
  Result:= True;
  for i := (nPair*2) to (nPair*2 + 1) do begin
    if Common.StatusInfo.UseChannel[i] then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        if not ControlDio.ReadInSig(IN_CH_1_CARRIER_SENSOR + (i*16)) then begin
          Result:= False;
          Exit;
        end;
      end
      else begin
        if not ControlDio.ReadInSig(IN_GIB_CH_1_CARRIER_SENSOR + (i*8)) then begin
          Result:= False;
          Exit;
        end;
      end;
    end;
  end;

end;

function TfrmMain_OC.CheckScriptRun : Boolean;
var
  i: Integer;
  bRet : Boolean;
begin
  bRet := False;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChOC[i] <> nil then begin
      if frmTest4ChOC[i].CheckScriptRun then begin
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

procedure TfrmMain_OC.CMStyleChanged(var Message: TMessage);
var
  i : Integer;
begin
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChOC[i] <> nil then begin
      frmTest4ChOC[i].SetHandleAgain(Self.Handle);
    end;
  end;
end;

procedure TfrmMain_OC.CreateClassData;
var
I : integer;
begin
  // UDP 서버 IP 192.168.0.11
  // 내부적으로 Common file을 읽어 오기 대문에 반드시 Common Create 이후 호출.
  self.Enabled:= False;
  Common.StatusInfo.Closing:= False; //종료 중 아님
  Common.StatusInfo.LogIn:= False;
  Common.StatusInfo.AutoMode:= False;

  if Common.SystemInfo.Use_MES then begin
    btnLogIn.Visible:= True;
    btnLogIn.Caption := 'đăng nhập (Log In)';
    pnlMesReady.Color := $000050F7; // $00FFFFE1;
    if Common.SystemInfo.Use_GIB then begin
      lblMesReady.Caption := 'MES GIB OFF';
    end
    else begin
      lblMesReady.Caption := 'MES OFF';
    end;
  end
  else begin
    btnLogIn.Visible:= True;
    btnLogIn.Caption := 'đăng nhập (Log In)';
    pnlMesReady.Color := $000050F7; // $00FFFFE1;
    lblMesReady.Caption := 'ECS Report OFF';
    Common.m_sUserId := 'PM';
  end;

  Init_AlarmMessage;

  tmrDisplayTestForm.Interval := 100;     // Added by KTS 2022-08-05 오전 10:47:08
  tmrDisplayTestForm.Enabled := True;

  InitForm;

  {$IFDEF PG_DP860}
  if Common.SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
    if (UdpServerPG <> nil) then begin
      UdpServerPG.Free;
      UdpServerPG := nil;
    end;
    UdpServerPG := TUdpServerPG.Create(Self.Handle);
  end;
  {$ENDIF}

  pnlStationNo.Caption := Common.SystemInfo.EQPId;
  case Common.SystemInfo.EQPId_Type of
    0: pnlEQPID.Caption:= 'EQP ID';
    1: pnlEQPID.Caption:= 'M-GIB EQP ID';
    2: pnlEQPID.Caption:= 'P-GIB EQP ID';
  end;

  tmrMemCheck.Enabled := True;

  Script := TScript.Create(Common.Path.MODEL_CUR + Common.SystemInfo.TestModel + '.isu');
  DisplayScriptInfo;
  UpdatePwrGui;

  DongaHandBcr := TSerialBcr.Create(Self);
  DongaHandBcr.OnRevBcrConn := GetBcrConnStatus;
  DongaHandBcr.ChangePort(Common.SystemInfo.Com_HandBCR[0]);

end;


procedure TfrmMain_OC.Update_Stage_Position(nStage: Integer);
var
  nAnother: Integer;
begin
  nAnother:= (nStage + 1) mod 2; //반대편 Stage

  if g_CommPLC <> nil then begin
    g_CommPLC.StageNo:= nStage;
//    g_CommPLC.ECS_Stage_Position(nStage)
  end;

//  if CommCamera <> nil then begin
//    //카메라는 반대 위치
//    CommCamera.m_hTest := frmTest4ChOC[nAnother].Handle;
//    CommCamera.JigNo := nAnother;
//  end;
end;

procedure TfrmMain_OC.UpdateECS_Glass_Position(nCh: Integer);
var
  i: Integer;
  nExistsCount, nUseCount: Integer;
  //naPosition: array [0..15] of Integer;
begin
  if g_CommPLC = nil then Exit;
  //Dectect Flag에 따른 보고
  ShowSysLog('UpdateECS_Glass_Position ' + IntToStr(nCh));
  nUseCount:= 0;
  nExistsCount:= 0;

  for i := 0 to MAX_CH do begin
    if Common.StatusInfo.UseChannel[i] then begin
      Inc(nUseCount); //전체 사용 채널 개수
      if ControlDio.ReadInSig(i*16 + IN_CH_1_CARRIER_SENSOR) then begin
        Inc(nExistsCount); //캐리어 있는 채널 개수
      end;
    end;
  end;

  for i := 0 to DefCommon.MAX_JIG_CH do begin
    //naPosition[i] := Integer(ControlDio.ReadInSig(i*4 + IN_DETECTION_SENSOR_1CH));
    //naPosition[i + 4] := Integer(ControlDio.ReadInSig(i*4 + IN_DETECTION_SENSOR_1CH + 16));
    g_CommPLC.ECS_Glass_Position(i , ControlDio.ReadInSig(i*16 + IN_CH_1_CARRIER_SENSOR));          // Added by KTS 2023-03-23 오후 4:49:35
//    g_CommPLC.ECS_Glass_Position(i + 2, ControlDio.ReadInSig(i*16 + IN_CH_1_CARRIER_SENSOR + 32));   // Added by KTS 2023-03-23 오후 4:49:39
//    Sleep(10);
//    g_CommPLC.ECS_Glass_Position(i + nStage*4 , ControlDio.ReadInSig(i*4 + IN_DETECTION_SENSOR_1CH + nStage*16));

  end;

end;

procedure TfrmMain_OC.UpdateECS_Glass_Position_Pair(nStage, nPair: Integer);
var
  i: Integer;
  nExistsCount, nUseCount: Integer;
  //naPosition: array [0..15] of Integer;
  bExist1, bExist2: Boolean;
begin
  if g_CommPLC = nil then Exit;
  //Dectect Flag에 따른 보고
  if Common.SystemInfo.OCType = DefCommon.OCType then begin

    bExist1:= ControlDio.ReadInSig(IN_CH_1_CARRIER_SENSOR + nPair*32);
    bExist2:= ControlDio.ReadInSig( 16 + IN_CH_1_CARRIER_SENSOR + nPair*32);
  end
  else begin
    bExist1:= ControlDio.ReadInSig(nPair + 0 + IN_GIB_CH_1_CARRIER_SENSOR + nPair*16);
    bExist2:= ControlDio.ReadInSig(nPair * 8 + IN_GIB_CH_1_CARRIER_SENSOR + nPair*16);
  end;

  ShowSysLog(format('UpdateECS_Glass_Position_Pair Station=%d, Pair=%d : Exists=%d, %d', [nStage, nPair, Ord(bExist1), Ord(bExist2)]));

  g_CommPLC.ECS_Glass_Position(nPair*2, bExist1);  // Added by KTS 2022-11-14 오전 11:03:14
   sleep(10);
  g_CommPLC.ECS_Glass_Position(nPair*2+ 1, bExist2);  // Added by KTS 2022-11-14 오전 11:03:17

  nUseCount:= 0;
  nExistsCount:= 0;

  for i := 0 to MAX_CH do begin
    if Common.StatusInfo.UseChannel[i] then begin
      Inc(nUseCount); //전체 사용 채널 개수
      if ControlDio.ReadInSig(i*16 + IN_CH_1_CARRIER_SENSOR) then begin
        Inc(nExistsCount); //캐리어 있는 채널 개수
      end;
    end;
  end;
  if nExistsCount = 0 then  g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_IDLE,0);

//  g_CommPLC.ECS_Glass_Exist(nExistsCount, nUseCount);
end;

procedure TfrmMain_OC.UpdatePwrGui;
var
  sTemp : string;
begin
  with lvPower do begin
    Items.Clear;

    with Items.Add do begin
      Caption := 'VCC';//'VCI';
      sTemp := Format('%0.2f',[Common.TestModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VCC] / 1000]);
      SubItems.Add(sTemp);

      sTemp := 'VIN';
      SubItems.Add(sTemp);
      sTemp := Format('%0.2f',[Common.TestModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VIN] / 1000]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VDD3';//'DVDD';
      sTemp := Format('%0.2f',[Common.TestModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD3] / 1000]);
      SubItems.Add(sTemp);

      sTemp := 'VDD4';
      SubItems.Add(sTemp);
      sTemp := Format('%0.2f',[Common.TestModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD4] / 1000]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VDD5';//'VDD';
      sTemp := Format('%0.2f',[Common.TestModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD5] / 1000]);
      SubItems.Add(sTemp);
    end;
  end;
end;

function TfrmMain_OC.DisplayLogIn: Integer;
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

procedure TfrmMain_OC.DisplayMes(bIsOn: Boolean);
begin
  if not Common.SystemInfo.Use_MES then begin
    Exit;
  end;
  if bIsOn then begin
    if not Common.StatusInfo.LogIn then begin
      ShowSysLog('MES Login On');
    end;

    Common.StatusInfo.LogIn:= True;
    btnLogIn.Caption := 'đăng xuất (Log Out)';
    btnLogIn.Tag := 1;
    pnlMesReady.Color := clGreen;// $00FFFFE1;
    if Common.SystemInfo.Use_GIB then begin
      lblMesReady.Caption := 'MES GIB ON';
    end
    else begin
      lblMesReady.Caption := 'MES ON';
    end;
  end
  else begin
    if Common.StatusInfo.LogIn then begin
      ShowSysLog('MES Login Off');
    end;
    Common.StatusInfo.LogIn:= False;
    btnLogIn.Caption := 'đăng nhập (Log In)';
    btnLogIn.Tag := 0;
    pnlMesReady.Color := $000050F7;
    if Common.SystemInfo.Use_GIB then begin
      lblMesReady.Caption := 'MES GIB OFF';
    end
    else begin
      lblMesReady.Caption := 'MES OFF';
    end;
  end;
end;

procedure TfrmMain_OC.DisplayECS(bLogin: Boolean);
begin
  if bLogin then begin
    Common.StatusInfo.LogIn:= True;
    btnLogIn.Caption := 'đăng xuất   (Log Out)';

    btnLogIn.Tag := 1;
    pnlMesReady.Color := clGreen;// $00FFFFE1;
    lblMesReady.Caption := 'ECS ON';
    ShowSysLog('ECS Login On');
  end
  else begin
    Common.StatusInfo.LogIn:= False;
    btnLogIn.Caption := 'đăng nhập (Log In)';
    lblMesReady.Caption := 'ECS OFF';
    pnlMesReady.Color := $000050F7;
    btnLogIn.Tag := 0;
    ShowSysLog('ECS Login Off');
  end;
end;


procedure TfrmMain_OC.DisplayScriptInfo;
begin
  pnlPatternGroup.Caption :=  Common.TestModelInfoFLOW.PatGrpName;
  pnlModelNameInfo.Caption := Common.SystemInfo.TestModel;
  pnlModelConfig.Caption  := Common.GetModelConfig(Common.SystemInfo.TestModel);
  pnlPsuVer.Caption    := Common.m_Ver.psu_Date+'('+Common.m_Ver.psu_Crc+')';
  pnlIsuVer.Caption    := Common.m_Ver.isu_Date;
end;

// DIO Status Display.
procedure TfrmMain_OC.Display_Memory_DI;
var
  i, nMod, nDiv : Integer;
  bTemp : Boolean;
begin
  if CommDaeDIO = nil then Exit;

  for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
//    if i > DefDio.IN_SHUTTER_DN_SNENSOR then Break;
    nDiv := i div 8; nMod := i mod 8;
    bTemp := (CommDaeDIO.DIData[nDiv] and (1 shl nMod)) > 0;
    if Common.SignalInversion(i) then bTemp := not bTemp; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
    ledDioIn[i].LedOn := bTemp;
  end;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChOC[i] <> nil then begin
      frmTest4ChOC[i].DisplayDio(True);
    end;
  end;
  if frmMainter <> nil then frmMainter.DisplayDio(True);
end;

procedure TfrmMain_OC.Display_Memory_DO;
var
  i, nMod, nDiv : Integer;
  bTemp : Boolean;
begin
  if CommDaeDIO = nil then Exit;

  for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
//    if i > DefDio.OUT_SHUTTER_DN_SOL then Break;
    nDiv := i div 8; nMod := i mod 8;
    bTemp := (CommDaeDIO.DODataFlush[nDiv] and (1 shl nMod)) > 0;
//    if Common.SignalInversion(i) then bTemp := not bTemp; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
    ledDioOut[i].LedOn := bTemp;
  end;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChOC[i] <> nil then begin
      frmTest4ChOC[i].DisplayDio(False);
    end;
  end;
  if frmMainter <> nil then frmMainter.DisplayDio(False);
end;

procedure TfrmMain_OC.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  sMsg, sDebug : string;
  i    : Integer;
begin
   sMsg := #13#10 + 'bạn có muốn thóat chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to Exit Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    sDebug := '[Click Event] Terminate ISPD Program';
    ShowSysLog(sDebug);
    tmSaveEnergy.Enabled := False;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
    Common.TaskBar(False);

    ControlDio.Set_TowerLampState(LAMP_STATE_NONE);

    if g_CommPLC <> nil then begin
      g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_IDLE, 200); //프로그램 종료 Down
      g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_ONLINE, 0);
    end;

    Sleep(500);

    InitialAll(False);
    CanClose := True;
  end
  else
    CanClose := False;
end;

procedure TfrmMain_OC.FormCreate(Sender: TObject);
var
  i : Integer;
  sDebug : string;

begin
//  Self.WindowState := wsMaximized;// wsNormal;
  Common := TCommon.Create;
  Common.m_sUserId := 'PM';
  //grpSystemInfo.Caption:= 'System Information. ST ' + IntToStr(Common.PLCInfo.EQP_ID);
  m_bIsClose := False;

  Common.UpdateSystemInfo_Runtime;
//  pnlUserId.Caption := Common.m_sUserId;
//  pnlUserName.Caption := '';
  sDebug := '#################################### Turn On ISPD Program (';
  sDebug := sDebug + Common.GetVersionDate + ') ####################################';
  for i := DefCommon.CH1 to DefCommon.MAX_CH do common.MLog(i,sDebug);
  ShowSysLog('[ Turn On Program ] - Version ' + Common.GetVersionDate);
    // 현재 설정 되어 있는 Local IP Display 하자.
  pnlStLocalIp.Caption := Common.GetLocalIpList;
  Self.Caption := DefCommon.PROGRAM_NAME + ' Version ' + Common.GetVersionDate + ' - Station #' + IntToStr(Common.PLCInfo.EQP_ID-10);
  //Self.Caption := DefCommon.PROGRAM_NAME + ' Version ' + Common.ExeVersion + ' - Station #' + IntToStr(Common.PLCInfo.EQP_ID-32);
  //grpSystemInfo.Caption:= 'System Information. ' + Common.GetVerOnlyDate;
  MakeDioSig;

  modDB := TDBModule_Sqlite.Create(Self);
  if modDB.DBConnect then begin
    if modDB.CheckAndCreateTable(MAX_PG_CNT, 'TLB_ISPD') then begin
      modDB.CheckNGTypeFieldCount;
    end
    else begin
    end;
  end;

  CreateClassData;

  Application.OnException := MyExceptionHandler;         // Added by KTS 2021-12-21 오후 3:34:52

//  tmrDisplayTestForm.Interval := 100;
//  tmrDisplayTestForm.Enabled := True;
end;

procedure TfrmMain_OC.FormDestroy(Sender: TObject);
begin
  modDB.Free;
end;

procedure TfrmMain_OC.GetBcrConnStatus( bConnected: Boolean; sMsg: string);
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


function TfrmMain_OC.GetStageNo_LoadZone: Integer;
begin
  Result:= -1;
  Result := 0;
//  if ControlDio.ReadInSig(DefDio.IN_B_STAGE_IN_CAM) then begin
//    Result:= 0;
//  end
//  else if ControlDio.ReadInSig(DefDio.IN_A_STAGE_IN_CAM) then begin
//    Result:= 1;
//  end;
end;

procedure TfrmMain_OC.Execute_AutoStart(nCH : Integer) ;
var
  nStage: Integer;
  nStation, nSeq, nCurSeq, nJudge: Integer;
  i: Integer;
begin
  if g_CommPLC = nil then Exit;

//  if Common.StatusInfo.StageTurnning then exit;  //Turn 중 시작 방지
  if not g_CommPLC.Connected then begin
    ShowSysLog('Do not Auto Start - PLC Disconected');
    Set_AlarmData(116, 1, 1);
    Exit;
  end;
  if g_CommPLC.IsBusy_Robot(nCH) then begin
    ShowSysLog('Do not Auto Start - Robot Busy');
    Exit;
  end;
  Common.StatusInfo.Loading:= False;
  g_CommPLC.EQP_Clear_ROBOT_Request(nCH);     // Added by KTS 2023-03-19 오전 10:33:25
  g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_RUN, 0);
//  g_CommPLC.ECS_Glass_Processing(True);   // Added by KTS 2023-04-04 오후 6:56:26
  nStage:= 0;

  if not CheckPG_Connect(nStage) then begin
    ShowSysLog('Do not Auto Start - PG Disconnected');
    Exit;
  end;


  if Common.StatusInfo.AABMode then begin
    ShowSysLog('Execute_AutoStart - AAB Mode');
    //AAB Mode일 경우 이전 검사가 OK일 경우 재 검사 skip
    nCurSeq:= 0;
    for i := 0 to 1 do begin
      //현재 차수 구하기
      g_CommPLC.GetGlassData_Processing_Status(g_CommPLC.GlassData[i + nStage*4], nSeq, 3);
      if nCurSeq < nSeq then begin
        nCurSeq:=  nSeq;
      end;
    end;

    for i := 0 to 1 do begin
      nStation:= g_CommPLC.GetGlassData_Processing_Status(g_CommPLC.GlassData[i + nStage*4], nSeq, 3);
      nJudge:= g_CommPLC.GlassData[i + nStage*4].GlassJudge; //, ord('G'));
      //ShowSysLog(format('AABMode Station=%d, Seq=%d, nJudge=%d', [nStation, nSeq, nJudge]));
      Common.MLog(i + nStage*4, format('AABMode Station=%d, CurSeq=%d, Seq=%d, nJudge=%d', [nStation, nCurSeq, nSeq, nJudge]));
      if (nSeq < nCurSeq) and (nJudge = ord('G'))  then begin
        //2차 검사이고 이전 검사가 'G'인 경우
        //ShowSysLog(format('AABMode Skip Ch %d - Pre OK ', [i]));
        PasScr[i + nStage*4].InitialData; //시작 안되므로 미리 클리어
        Common.MLog(i + nStage*4, format('AABMode Skip Ch %d - Pre OK ', [i]));
        PasScr[i + nStage*4].m_bUse:= false; //해당 채널 임시 검사 skip
      end;
    end;

    nCurSeq:= 0;
    for i := 2 to 3 do begin
      //현재 차수 구하기
      g_CommPLC.GetGlassData_Processing_Status(g_CommPLC.GlassData[i + nStage*4], nSeq, 3);
      if nCurSeq < nSeq then begin
        nCurSeq:=  nSeq;
      end;
    end;

    for i := 2 to 3 do begin
      nStation:= g_CommPLC.GetGlassData_Processing_Status(g_CommPLC.GlassData[i + nStage*4], nSeq, 3);
      nJudge:= g_CommPLC.GlassData[i + nStage*4].GlassJudge; //, ord('G'));
      Common.MLog(i + nStage*4, format('AABMode Station=%d, CurSeq=%d, Seq=%d, nJudge=%d', [nStation, nCurSeq, nSeq, nJudge]));
      if (nSeq < nCurSeq) and (nJudge = ord('G'))  then begin
        //2차 검사이고 이전 검사가 'G'인 경우
        //ShowSysLog(format('AABMode Skip Ch %d - Pre OK ', [i]));
        PasScr[i + nStage*4].InitialData; //시작 안되므로 미리 클리어
        Common.MLog(i + nStage*4, format('AABMode Skip Ch %d - Pre OK ', [i]));
        PasScr[i + nStage*4].m_bUse:= false; //해당 채널 임시 검사 skip
      end;
    end;

    case nStage of
      JIG_A : begin
        ShowSysLog('AABMode - AutoLogicStart A');
        Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_LOADZONE;
        frmTest4ChOC[DefCommon.JIG_A].AutoLogicStart(0);
      end;
//      JIG_B : begin
//        ShowSysLog('AABMode - AutoLogicStart B');
//        Common.StatusInfo.StageStep[JIG_B]:= STAGE_STEP_LOADZONE;
//        frmTest4ChOC[DefCommon.JIG_B].AutoLogicStart;
//      end;
      else begin
        ShowSysLog('Turnning is not Complete', 1);
      end;
    end;

    //임시 검사 skip 원복
    for i := 0 to MAX_JIG_CH do begin
      if (not PasScr[i + nStage*4].m_bUse) and Common.StatusInfo.UseChannel[i + nStage*4] then begin
        frmTest4ChOC[nStage].AddLog('AABMode Skip', i);
      end;
      PasScr[i + nStage*4].m_bUse := Common.StatusInfo.UseChannel[i + nStage*4];
    end;

  end  //if Common.StatusInfo.AABMode then begin
  else begin
    case nStage of
      JIG_A : begin
        Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_LOADZONE;
//        g_CommPLC.ECS_Accessory_Unit_Status(0, 1, 0); //Stage A
        frmTest4ChOC[DefCommon.JIG_A].AutoLogicStart(nCH);
      end;
      else begin
        ShowSysLog('Turnning is not Complete', 1);
      end;
    end;
  end;
end;



procedure TfrmMain_OC.InitDfs;
var
  sIp, sUsrName, sPw : string;
  nCh : Integer;
  sDebug : string;
begin
  DfsFtpConnOK := False; //2019-04-09
  if Common.DfsConfInfo.bUseDfs then begin
    ShowSysLog('InitDfs');
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

    DfsFtpCommon := TDfsFtp.Create(sIp, sUsrName, sPw, DefCommon.MAX_PG_CNT); //-1{nCh:dummy for DfsFtpCommon});
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

    Common.LoadCombiFile;

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

procedure TfrmMain_OC.initform;
begin
  if Common.SystemInfo.Test_Repeat then begin
    //반복 테스트용
    grpAutoTester.Visible:= True;
    TStyleManager.SetStyle('Windows10 Dark');
  end
  else begin
    grpAutoTester.Visible:= False;
    case Common.SystemInfo.UIType of
      Defcommon.UI_WIN10_NOR   : TStyleManager.SetStyle('Windows10');
      Defcommon.UI_WIN10_BLACK : TStyleManager.SetStyle('Windows10 Dark')
      else begin
        TStyleManager.SetStyle('Windows10');
      end;
    end;
    //grpPlc.Visible          := not Common.SystemInfo.OcManualType;
  end;
end;

Function TfrmMain_OC.InitGmes : Boolean;
var
  sService, sNetWork, sDeamon : string;
  sLocal, sRemote, sHostPath  : string;
  bRtn, nEasRtn               : Boolean;
begin
  Result:= True;
  if DongaGmes <> nil then begin
    ShowSysLog('InitGmes Exit - Not nil');
    Exit;
  end;

  ShowSysLog('InitGmes');

  DongaGmes := TGmes.Create(Self, Self.Handle);
    ShowSysLog('Create');
  DongaGmes.OnGmsEvent  := DongaGmesEvent;  // Added by KTS 2023-03-27 오전 9:58:58
      ShowSysLog('OnGmsEvent');

  if frmTest4ChOC[DefCommon.JIG_A] <> nil then begin
    DongaGmes.hTestHandle1 := frmTest4ChOC[DefCommon.JIG_A].Handle;
    CommTibRv.m_TestHandle := frmTest4ChOC[DefCommon.JIG_A].Handle;
  end;
    ShowSysLog('OnGmsEvent');

//  InitMainTool(False);
  sService    := Common.SystemInfo.ServicePort;
  sNetWork    := Common.SystemInfo.Network;
  sDeamon     := Common.SystemInfo.DaemonPort;
  sLocal      := Common.SystemInfo.LocalSubject;
  sRemote     := Common.SystemInfo.RemoteSubject;
  sHostPath   := Common.Path.GMES;
  DongaGmes.MesUserId := Common.SystemInfo.AutoLoginID; // '602462';
  Common.m_sUserId := 'PM';
  Common.m_sUserId  := DongaGmes.MesUserId;
    ShowSysLog('1');
//  pnlUserId.Caption := Common.m_sUserId;
//  pnlUserName.Caption := '';
  DongaGmes.MesSystemNo   := Common.SystemInfo.EQPId;
  DongaGmes.MesSystemNo_MGIB := Common.SystemInfo.EQPId_MGIB;
  DongaGmes.MesSystemNo_PGIB := Common.SystemInfo.EQPId_PGIB;
  DongaGmes.MesModelInfo  := Common.SystemInfo.MesModelInfo;
    ShowSysLog('2');
  if ((Trim(sService) = '') or (Trim(sDeamon) = '') or (sRemote = '')) then begin
    ShowSysLog('MES Info is Empty');
    Exit;
  end;
    ShowSysLog('3');
  bRtn := DongaGmes.HOST_Initial(sService, sNetWork, sDeamon,sLocal,sRemote ,sHostPath);

    ShowSysLog('4');
     ledGmes.Value := bRtn;
  if bRtn then begin
    pnlHost.Caption := 'Connected';
    ShowSysLog('MES Connected');
  end
  else begin
    pnlHost.Caption := 'Disconnected';
    ShowSysLog('MES Disconnected', 1);
  end;
  nEasRtn := True;
{$IFDEF EAS_USE}
  // EAS Open.
  sService    := Common.SystemInfo.Eas_Service;
  sNetWork    := Common.SystemInfo.Eas_Network;
  sDeamon     := Common.SystemInfo.Eas_DeamonPort;
  sLocal      := Common.SystemInfo.Eas_LocalSubject;
  sRemote     := Common.SystemInfo.Eas_RemoteSubject;
  sHostPath   := Common.Path.EAS;
  //if ((Trim(sService) = '') or (Trim(sNetWork) = '') or (Trim(sDeamon) = '') or (sRemote = '')) then begin
  if ((Trim(sService) = '') or (Trim(sDeamon) = '') or (sRemote = '')) then begin
    ShowSysLog('EAS Info is Empty');
    nEasRtn := False;
  end
  else begin
    nEasRtn := DongaGmes.Eas_Initial(sService, sNetWork, sDeamon,sLocal,sRemote ,sHostPath);
    ledEAS.Value := nEasRtn;
    if nEasRtn then begin
      pnlEAS.Caption := 'Connected';
      ShowSysLog('EAS Connected');
    end
    else begin
      pnlEAS.Caption := 'Disonnected';
      ShowSysLog('EAS Disonnected', 1);
    end;
  end;
{$ENDIF}



  if bRtn and nEasRtn then begin
   // pnlHost.Caption := 'Connected';
    DongaGmes.FtpAddr := Common.SystemInfo.HOST_FTP_IPAddr;
    DongaGmes.FtpUser := Common.SystemInfo.HOST_FTP_User;
    DongaGmes.FtpPass := Common.SystemInfo.HOST_FTP_Passwd;
    DongaGmes.FtpCombiPath := Common.SystemInfo.HOST_FTP_CombiPath;
    // EAYT Start....
    DongaGmes.SendHostStart;
  end
  else begin
    //pnlHost.Caption := 'Disonnected';

  end;


  sService    := Common.SystemInfo.R2R_Service;
  sNetWork    := Common.SystemInfo.R2R_Network;
  sDeamon     := Common.SystemInfo.R2R_DeamonPort;
  sLocal      := Common.SystemInfo.R2R_LocalSubject;
  sRemote     := Common.SystemInfo.R2R_RemoteSubject;
  sHostPath   := Common.Path.GMES;

  if ((Trim(sService) = '') or (Trim(sDeamon) = '') or (sRemote = '')) then begin
    ShowSysLog('R2R Info is Empty');
    Exit;
  end;

  bRtn := DongaGmes.R2R_Initial(sService, sNetWork, sDeamon,sLocal,sRemote ,sHostPath);
  ledR2R.Value := bRtn;
  if bRtn then begin
    pnlR2R.Caption := 'Connected';
    ShowSysLog('R2R Connected');
  end
  else begin
    pnlR2R.Caption := 'Disconnected';
    ShowSysLog('R2R Disconnected', 1);
  end;
end;

procedure TfrmMain_OC.InitialAll(bReset: Boolean);
var
  i : Integer;
begin
  Common.StatusInfo.Closing:= True; //종료 중
  Self.Enabled:= False;

  if g_CommPLC <> nil then begin
    g_CommPLC.SaveGlassData(Common.Path.Ini + 'GlassData.dat');
    g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_DOWN, 201); //프로그램 초기화down
//    g_CommPLC.ECS_Accessory_Unit_Status(0, 2, 201); //Stage A
//    g_CommPLC.ECS_Accessory_Unit_Status(1, 2, 201); //Stage B
//    Sleep(500);
  end;

  m_bIsClose := True;
  if CommCamera <> nil then begin
    CommCamera.Free;
    CommCamera := nil;

    ledCam1.Value := False;
    ledCam2.Value := False;
    ledCam3.Value := False;
    ledCam4.Value := False;
  end;
  ReleaseReadyModOnPlc;
  for I := 0 to Pred(DefCommon.MAX_SWITCH_CNT) do begin
    if DongaSwitch[i] <> nil then begin
      DongaSwitch[i].Free;
      DongaSwitch[i] := nil;
    end;
  end;


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
//    btnLogIn.Caption := 'đăng nhập (Log In)';
    DongaGmes.Free;
    DongaGmes := nil;
  end;

  if DongaHandBcr <> nil then begin
    DongaHandBcr.Free;
    DongaHandBcr := nil;
  end;





    if UdpServerPG <> nil then begin
      for I := DefCommon.PG_1 to DefCommon.PG_MAX do begin
        if (Pg[i] <> nil) and (not (Pg[i].StatusPg in [pgDisconn])) then begin
        //TBD:DP860? Pg[0].SendPgReset;
          Sleep(500);
        end;
      end;
      UdpServerPG.Free;
      UdpServerPG := nil;
    end;

//  if UdpServer <> nil then begin
//    UdpServer.Free;
//    UdpServer := nil;
//  end;
  if Script <> nil then begin
    Script.Free;
    Script := nil;
  end;

  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    // Distroy current alloc class
    if frmTest4ChOC[i] <> nil then begin
      frmTest4ChOC[i].Free;
      frmTest4ChOC[i] := nil;
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



//  ControlDio.ClearOutDioSig(OUT_ION_BAR_SOL);
//  ControlDio.ClearOutDioSig(OUT_AIR_KNIFE_SOL);
  Sleep(300); //DIO 출력 대기
  for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
    if DaeIonizer[i] <> nil then begin
      DaeIonizer[i].IsIgnoreNg:= True;
      DaeIonizer[i].Free;
      DaeIonizer[i] := nil;
    end;
  end;


  if ControlDio <> nil then begin
    ControlDio.Free;
    ControlDio := nil;
  end;

  if g_CommPLC <> nil then begin
    g_CommPLC.StopThread;
    g_CommPLC.Free;
    g_CommPLC := nil;
  end;

  if Common is TCommon then begin
    Common.Free;
    Common := nil;
  end;

  if bReset then begin
    // Create Again.
    Common :=	TCommon.Create;
    CreateClassData;
    m_bIsClose := False;
    ShowSysLog('Program InitialAll');
    AddLog_AllCh('Program InitialAll');
  end;
end;

function TfrmMain_OC.IsHeaderExist(asHeaders: array of string): Boolean;
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

function TfrmMain_OC.IsStageWorking(nStage: Integer): Boolean;
var
  i: Integer;
begin
  Result:= True;
  if nStage = 2 then begin
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if PasScr[i].m_bIsScriptWork then begin
        Exit;
      end;
    end;
  end
  else begin
    //하나라도 있으면 False
    for i := 0 to DefCommon.MAX_JIG_CH do begin
      if PasScr[i + nStage*4].m_bIsScriptWork then begin
        Exit;
      end;
    end;
  end;

  Result:= False;
end;

procedure TfrmMain_OC.Login_ECS;
begin
  //ECS Login
  if g_CommPLC <> nil then begin
    ShowSysLog('Login_ECS');
    //Common.m_sUserId := Common.SystemInfo.AutoLoginID; // '602462'; //'PM';

    TThread.CreateAnonymousThread( procedure var nRet: Integer; begin
      nRet:= g_CommPLC.ECS_UCHK(Common.m_sUserId); //g_CommPLC.ECS_UCHK('602462');
      if nRet <> 0 then begin

      end
      else begin

      end;
    end).Start;
  end;
end;

procedure TfrmMain_OC.Login_MES;
var
  i, nRet: Integer;
begin
  //ShowSysLog('Login_MES');
  if Trim(Common.SystemInfo.ServicePort) <> '' then begin

    if DongaGmes <> nil then begin
      if Common.SystemInfo.OcManualType then  begin
        if Trim(Common.SystemInfo.ServicePort) <> '' then begin
          nRet := DisplayLogIn;
          if nRet = mrCancel then begin
            Common.m_sUserId := 'PM';
            DongaGmes.Free;
            DongaGmes := nil;
            btnLogIn.Caption := 'đăng nhập (Log In)';
            Common.m_sUserId := 'PM';
            if Common.SystemInfo.Use_GIB then begin
              lblMesReady.Caption := 'MES GIB OFF';
            end
            else begin
              lblMesReady.Caption := 'MES OFF';
            end;
            pnlMesReady.Color := $000050F7;
            Exit;
          end
          else begin
//               Common.m_sUserId  := Common.SystemInfo.AutoLoginID;
            if Common.m_sUserId = 'PM' then begin
              DongaGmes.Free;
              DongaGmes := nil;
              pnlHost.Caption := 'PM Mode';
              ledGmes.FalseColor := clGray;
              ledGmes.Value := False;
              if Common.SystemInfo.Use_GIB then begin
                lblMesReady.Caption := 'MES GIB OFF';
              end
              else begin
                lblMesReady.Caption := 'MES OFF';
              end;
              pnlMesReady.Color := $000050F7;
            end
            else begin
              if DongaGmes is TGmes then begin
                ShowSysLog(Format(' Common.m_sUserId : %s',[Common.m_sUserId]));
                DongaGmes.MesUserId := Common.m_sUserId;
                if not DongaGmes.MesEayt then DongaGmes.SendHostUchk
                else                          DongaGmes.SendHostEayt;
              end
              else begin
                InitGmes;
                if frmTest4ChOC[DefCommon.JIG_A] <> nil then begin
                  DongaGmes.hTestHandle1 := frmTest4ChOC[DefCommon.JIG_A].Handle;
                end;
                if frmTest4ChOC[DefCommon.JIG_B] <> nil then begin
                  DongaGmes.hTestHandle2 := frmTest4ChOC[DefCommon.JIG_B].Handle;
                end;
              end;
            end;
          end;
        end;
      end  //if Common.SystemInfo.OcManualType then  begin
      else begin
        DongaGmes.Free;
        DongaGmes := nil;
        btnLogIn.Caption := 'đăng nhập (Log In)';
        Common.m_sUserId := 'PM';
        ledGmes.Value:= False;
        ledEAS.Value:= False;

        for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
          frmTest4ChOC[i].SetHostConnShow(False);
        end;
//        if Common.SystemInfo.Use_GIB then begin
//          lblMesReady.Caption := 'MES GIB OFF';
//        end
//        else begin
//          lblMesReady.Caption := 'MES OFF';
//        end;
//        lblMesReady.Color := $000050F7;
      end;
    end //if DongaGmes <> nil then begin
    else begin
      if Common.SystemInfo.OcManualType then  begin
        if Trim(Common.SystemInfo.ServicePort) <> '' then begin
          nRet := DisplayLogIn;
//
          if nRet = mrCancel then begin
            Exit;
          end
          else begin
//             Common.m_sUserId  := Common.SystemInfo.AutoLoginID;
            if Common.m_sUserId = 'PM' then begin
              pnlHost.Caption := 'PM Mode';
              ledGmes.FalseColor := clGray;
              ledGmes.Value := False;
              if Common.SystemInfo.Use_GIB then begin
                lblMesReady.Caption := 'MES GIB OFF';
              end
              else begin
                lblMesReady.Caption := 'MES OFF';
              end;
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
                if frmTest4ChOC[DefCommon.JIG_A] <> nil then begin
                  DongaGmes.hTestHandle1 := frmTest4ChOC[DefCommon.JIG_A].Handle;
                end;
                if frmTest4ChOC[DefCommon.JIG_B] <> nil then begin
                  DongaGmes.hTestHandle2 := frmTest4ChOC[DefCommon.JIG_B].Handle;
                end;
              end;
            end;
          end;
        end;
      end
      else begin

        InitGmes;
        if frmTest4ChOC[DefCommon.JIG_A] <> nil then begin
          DongaGmes.hTestHandle1 := frmTest4ChOC[DefCommon.JIG_A].Handle;
        end;
        if frmTest4ChOC[DefCommon.JIG_B] <> nil then begin
          DongaGmes.hTestHandle2 := frmTest4ChOC[DefCommon.JIG_B].Handle;
        end;
      end;
    end;
  end
  else begin
    btnLogIn.Caption := 'đăng nhập (Log In)';
    ShowMessage('Please input correct GMES Configration');
  end;
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
//  sTemp := FormatDateTime('yyyymmdd hh:nn:ss', PasScr[nCh].TestInfo.StartTime);
//
//  // for Header.
//  sHeader := Format('%s,%s,%s,%s,%s',['Date/Time','User_ID','S/W_VER','Script_VER','PG_FW/FPGA/MDM/PWR']);
//  sHeader := sHeader+ format(',%s,%s,%s,',['End_Time','Total_Time(sec)','OC Time(sec)']);
//  sHeader := sHeader+ format(',%s,%s,%s,%s,%s',['Result', 'Channel','Carrier_ID','Panel_ID','Before_OTP_Count']);
//  sHeader := sHeader + PasScr[nCh].TestInfo.csvHeader;
////  sHeader := sHeader + Chr(13)+'1,2222'+Chr(13)+'2,1111';
//
//  // 'Date/Time','User_ID','S/W_VER','Script_VER','PG_FW/FPGA/MDM/PWR'
//  sData := format('%s,%s,%s,(%s),%s',[sTemp,Common.m_sUserId,Common.GetVersionDate, common.SystemInfo.ScriptVer,sPgVer]);
//  // 'End_Time','Total_Time(sec)','OC Time(sec)'
//  sTemp := FormatDateTime('HH:NN:SS', PasScr[nCh].TestInfo.EndTime);
//  sTemp2 := Format('%d',[SecondsBetween(PasScr[nCh].TestInfo.StartTime,PasScr[nCh].TestInfo.EndTime)]);
//  // OC Time ==> later....
//  sTemp3 := '1';
//  sData := sData + format(',%s,%s,%s,',[sTemp,sTemp3, sTemp2]);
//
//  //'Result', 'Channel','Carrier_ID','Panel_ID','Before_OTP_Count'
//  sData := sData + format(',%s,%d,%s,%s,%d,',[PasScr[nCh].TestInfo.Result,nCh + 1,PasScr[nCh].TestInfo.CarrierId, PasScr[nCh].TestInfo.SerialNo,PasScr[nCh].TestInfo.Before_OtpCnt ]);
//  sData := sData + PasScr[nCh].TestInfo.csvData;
//
//  sFileName := PasScr[nCh].m_sFileCsv;
//end;

procedure TfrmMain_OC.MakeCsvApdrLog(nCh: Integer);
var
  sFileName, sFilePath, sData : string;
  i : Integer;
begin
  sFilePath := Common.Path.ApdrCsv+formatDateTime('yyyymm',now) + '\';
  sFileName := sFilePath + PasScr[nCh].m_sFileCsv;
  if Common.CheckDir(sFilePath) then Exit;
  //sData := StringReplace(Common.GetVerOnlyDate,' ','',[rfReplaceAll]);
  sData := '';
  for i := 0 to Pred(PasScr[nCh].TestInfo.InsApdr.FColCnt) do begin
    sData := sData + Trim(PasScr[nCh].TestInfo.InsApdr.Data[0,i])+':';
    sData := sData + Trim(PasScr[nCh].TestInfo.InsApdr.Data[1,i])+':';
    sData := sData + Trim(PasScr[nCh].TestInfo.InsApdr.Data[2,i]);
    if i <> Pred(PasScr[nCh].TestInfo.InsApdr.FColCnt) then begin
      sData := sData + ',';
    end;
  end;
end;
procedure TfrmMain_OC.MakeDioSig;
var
  i,nMod, nCh, nNotUse: Integer;
  nWidth, nHeight, nTopPos : Integer;
  sTemp : string;
begin
  nWidth := 120;
  nHeight := 15;
  nNotUse := 0;

  nTopPos := 23;// pnlDioTop.Top + pnlDioTop.Height + 1;
  for i := 0 to Pred(DefDio.MAX_IN_CNT) do begin


    ledDioIn[i] := TTILed.Create(Self);
    ledDioIn[i].Parent := grpDIO;
//    if i-nNotUse > 24 then begin
//      ledDioIn[i].Left := ledDioIn[i-1].Width + 2;//pnlZAxis.Left + ledDioIn[i-1].Width + 1;
//      ledDioIn[i].Top  := nTopPos + (i-25-nNotUse)*(nHeight);
//    end
//    else begin
//      ledDioIn[i].Left := 1;//pnlZAxis.Left;
//      ledDioIn[i].Top  := nTopPos + (i-nNotUse)*(nHeight);
//    end;
    ledDioIn[i].Left := 1;//pnlZAxis.Left;
    ledDioIn[i].Top  := nTopPos + (i-nNotUse)*(nHeight);
    ledDioIn[i].Width := grpDIO.Width div 2;
    ledDioIn[i].Height := nHeight;
    ledDioIn[i].Font.Size := 7;
    ledDioIn[i].LedColor := TLedColor(Green);
    ledDioIn[i].StyleElements := [seBorder];
    sTemp := '';

    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      case i of

        DefDio.IN_FAN_1_EXHAUST : sTemp := 'FAN #1 OUT';
        DefDio.IN_FAN_2_INTAKE : sTemp := 'FAN #2 IN';
        DefDio.IN_FAN_3_EXHAUST : sTemp := 'FAN #3 OUT';
        DefDio.IN_FAN_4_INTAKE : sTemp := 'FAN #4 IN';
        DefDio.IN_UNDEFINED_4 : sTemp := '';
        DefDio.IN_UNDEFINED_5 : sTemp := '';
        DefDio.IN_UNDEFINED_6 : sTemp := '';
        DefDio.IN_UNDEFINED_7 : sTemp := '';

        DefDio.IN_EMO_SWITCH : sTemp := 'EMO SWITCH';
        DefDio.IN_CH_1_2_DOOR_LEFT_OPEN : sTemp := '#1#2 L/DOOR';
        DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN : sTemp := '#1#2 R/DOOR';
        DefDio.IN_CH_3_4_DOOR_LEFT_OPEN : sTemp := '#3#4 L/DOOR';
        DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN : sTemp := '#3#4 R/DOOR';
        DefDio.IN_MC_MONITORING : sTemp := 'MC MONITORING';
        DefDio.IN_UNDEFINED_14 : sTemp := '';
        DefDio.IN_UNDEFINED_15 : sTemp := '';

        DefDio.IN_TEMPERATURE_ALARM : sTemp := 'TEMPERATURE ALARM';


        DefDio.IN_CYL_PRESSURE_GAUGE : sTemp := 'CYL PRESSURE GAUGE';


      end;
    end
    else begin
      case i of

        DefDio.IN_FAN_1_EXHAUST : sTemp := 'FAN #1 OUT';
        DefDio.IN_FAN_2_INTAKE : sTemp := 'FAN #2 IN';
        DefDio.IN_FAN_3_EXHAUST : sTemp := 'FAN #3 OUT';
        DefDio.IN_FAN_4_INTAKE : sTemp := 'FAN #4 IN';
        DefDio.IN_GIB_CH_12_EMO_SWITCH  : sTemp := 'CH 1,2_EMO_SWITCH';
        DefDio.IN_GIB_CH_34_EMO_SWITCH  : sTemp := 'CH 3,4_EMO_SWITCH';
        DefDio.IN_GIB_CH_12_LIGHTCURTAIN : sTemp  := 'CH 1,2 LIGHT CURTAIN';
        DefDio.IN_GIB_CH_34_LIGHTCURTAIN : sTemp  := 'CH 3,4 LIGHT CURTAIN';


        DefDio.IN_GIB_CH_12_MUTING_LAMP    : sTemp := 'CH 1,2 MUTING LAMP';
        DefDio.IN_GIB_CH_34_MUTING_LAMP    : sTemp := 'CH 3,4 MUTING LAMP';
        DefDio.IN_GIB_CH_12_MC_MONITORING  : sTemp := 'CH 1,2 MC MONITORING';
        DefDio.IN_GIB_CH_34_MC_MONITORING  : sTemp := 'CH 3,4 MC MONITORING';
        DefDio.IN_GIB_TEMPERATURE_ALARM    : sTemp := 'TEMPERATURE ALARM';


        DefDio.IN_GIB_CYL_PRESSURE_GAUGE   : sTemp := 'CYL PRESSURE GAUGE';

        DefDio.IN_GIB_CH_12_SHUTTER_UP_SENSOR   : sTemp := ' CH 1,2 SHUTTER UP';
        DefDio.IN_GIB_CH_12_SHUTTER_DN_SENSOR   : sTemp := ' CH 1,2 SHUTTER Down';

        DefDio.IN_GIB_CH_34_SHUTTER_UP_SENSOR   : sTemp := ' CH 3,4 SHUTTER UP';
        DefDio.IN_GIB_CH_34_SHUTTER_DN_SENSOR   : sTemp := ' CH 3,4 SHUTTER Down';
      end;


    end;
    ledDioIn[i].Caption := sTemp;
    ledDioIn[i].Hint     := sTemp;
    if sTemp <> '' then ledDioIn[i].ShowHint := True;
    if sTemp <> '' then ledDioIn[i].Visible := True
    else ledDioIn[i].Visible := False;
    if sTemp = '' then nNotUse := nNotUse + 1;

  end;

  nNotUse := 0;
  for i := 0 to Pred(DefDio.MAX_OUT_CNT) do begin
    ledDioOut[i] := TTILed.Create(Self);
    ledDioOut[i].Width := grpDIO.Width div 2;
    ledDioOut[i].Height := nHeight;
    ledDioOut[i].Parent := grpDIO;
    ledDioOut[i].Left := nWidth;
    ledDioOut[i].Top  := nTopPos + (i-nNotUse)*(nHeight);
    ledDioOut[i].Font.Size := 7;
    sTemp := '';
    if Common.SystemInfo.OCType = DefCommon.OCType then begin

    case i of
      DefDio.OUT_CH_1_2_LAMP_OFF : sTemp := '#1#2 LAMP OFF';
      DefDio.OUT_CH_3_4_LAMP_OFF : sTemp := '#3#4 LAMP OFF';
      DefDio.OUT_CH_1_PG_POWER_OFF : sTemp := '#1 PG POWER OFF';
      DefDio.OUT_CH_2_PG_POWER_OFF : sTemp := '#2 PG POWER OFF';
      DefDio.OUT_CH_3_PG_POWER_OFF : sTemp := '#3 PG POWER OFF';
      DefDio.OUT_CH_4_PG_POWER_OFF : sTemp := '#4 PG POWER OFF';
      DefDio.OUT_UNDEFINED_6 : sTemp := '';
      DefDio.OUT_START_SW_LED : sTemp := 'START_SW_LED';

      DefDio.OUT_CH_1_2_DOOR_LEFT_UNLOCK : sTemp := '#1#2 L/DOOR UNLOCK';
      DefDio.OUT_CH_1_2_DOOR_RIGHT_UNLOCK : sTemp := '#1#2 R/DOOR UNLOCK';
      DefDio.OUT_CH_3_4_DOOR_LEFT_UNLOCK : sTemp := '#3#4 L/DOOR UNLOCK';
      DefDio.OUT_CH_3_4_DOOR_RIGHT_UNLOCK : sTemp := '#3#4 R/DOOR UNLOCK';
      DefDio.OUT_RESET_SWITCH_LED : sTemp := 'RESET SWITCH LED';
      DefDio.OUT_UNDEFINED_13 : sTemp := '';
      DefDio.OUT_UNDEFINED_14 : sTemp := '';
      DefDio.OUT_UNDEFINED_15 : sTemp := '';

      DefDio.OUT_TOWER_LAMP_RED : sTemp := 'TOWER LAMP RED';
      DefDio.OUT_TOWER_LAMP_YELLOW : sTemp := 'TOWER LAMP YELLOW';
      DefDio.OUT_TOWER_LAMP_GREEN : sTemp := 'TOWER LAMP GREEN';
      DefDio.OUT_BUZZER_1 : sTemp := 'BUZZER #1';
      DefDio.OUT_UNDEFINED_23 : sTemp := '';

      DefDio.OUT_CH_1_2_ION_ONOFF_SOL : sTemp := '#1#2 ION ON/OFF SOL';
      DefDio.OUT_CH_3_4_ION_ONOFF_SOL : sTemp := '#1#2 ION ON/OFF SOL';
      DefDio.OUT_CH_1_2_BACK_DOOR_LAMPON : sTemp := '#1#2 BACKDOORLAMP ON/OFF';
      DefDio.OUT_CH_3_4_BACK_DOOR_LAMPON : sTemp := '#3#4 BACKDOORLAMP ON/OFF';
      DefDio.OUT_UNDEFINED_28 : sTemp := '';
      DefDio.OUT_UNDEFINED_29 : sTemp := '';
      DefDio.OUT_UNDEFINED_30 : sTemp := '';
      DefDio.OUT_UNDEFINED_31 : sTemp := '';


    end;
    end
    else begin
      case i of
        DefDio.OUT_CH_1_2_LAMP_OFF      : sTemp := 'CH #1 #2 LAMP OFF';
        DefDio.OUT_CH_3_4_LAMP_OFF      : sTemp := 'CH #3 #4 LAMP OFF';
        DefDio.OUT_CH_1_PG_POWER_OFF    : sTemp := 'CH #1 PG POWER OFF';
        DefDio.OUT_CH_2_PG_POWER_OFF    : sTemp := 'CH #2 PG POWER OFF';
        DefDio.OUT_CH_3_PG_POWER_OFF    : sTemp := 'CH #3 PG POWER OFF';
        DefDio.OUT_CH_4_PG_POWER_OFF    : sTemp := 'CH #4 PG POWER OFF';
        DefDio.OUT_CH_12_RESET_SWTCH_LED: sTemp := 'CH #1 #2 RESET SWTCH';
        DefDio.OUT_CH_34_RESET_SWTCH_LED: sTemp := 'CH #3 #4 RESET SWTCH';

        DefDio.OUT_GIB_TOWER_LAMP_RED    : sTemp := 'TOWER LAMP RED';
        DefDio.OUT_GIB_TOWER_LAMP_YELLOW : sTemp := 'TOWER LAMP YELLOW';
        DefDio.OUT_GIB_TOWER_LAMP_GREEN  : sTemp := 'TOWER LAMP GREEN';
        DefDio.OUT_GIB_BUZZER_1          : sTemp := 'BUZZER #1';
        DefDio.OUT_UNDEFINED_15          : sTemp := '';

        DefDio.OUT_GIB_CH_12_ION_ONOFF_SOL : sTemp := 'CH #1 #2 ION ONOFF SOL';
        DefDio.OUT_GIB_CH_34_ION_ONOFF_SOL : sTemp := 'CH #3 #4 ION ONOFF SOL';
      end;

    end;
    ledDioOut[i].Caption := sTemp;

    ledDioOut[i].Width := nWidth;
    ledDioOut[i].Height := nHeight;
    ledDioOut[i].LedColor := TLedColor(Yellow);
    ledDioOut[i].StyleElements := [seBorder];
    if sTemp = '' then nNotUse := nNotUse + 1;
    if sTemp <> '' then ledDioOut[i].Visible := True
    else ledDioOut[i].Visible := False;
    ledDioOut[i].Hint     := sTemp;
    if sTemp <> '' then ledDioOut[i].ShowHint := True;

  end;
end;


procedure TfrmMain_OC.MyExceptionHandler(Sender: TObject; E: Exception);
begin
  common.MLog(0,'Application Exception Error, class=' + Sender.ClassName +', mesg='+ E.Message);
  raise Exception.Create('Here!');
end;

procedure TfrmMain_OC.DoAlarmReset;
var
  i: Integer;
begin
  ShowSysLog('[ALARM RESET] ERROR RESET');
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    frmTest4ChOC[i].ClearPreviousResult;
  end;
end;

procedure TfrmMain_OC.DongaGmesEvent(nMsgType, nPg: Integer; bError: Boolean; sErrMsg: string);
var
  sHostErrMsg : string;
  nCh , i: Integer;
begin
  sHostErrMsg := StringReplace(sErrMsg, '[', '', [rfReplaceAll]);
  sHostErrMsg := StringReplace(sHostErrMsg, ']', '', [rfReplaceAll]);

  case nMsgType of
    DefGmes.MES_EAYT  : begin
      if bError then begin
//        ShowNgMessage(sHostErrMsg);

      end;
    end;
    DefGmes.MES_UCHK  : begin
      DongaGmes.MesUserName  := StringReplace(DongaGmes.MesUserName, '[', '', [rfReplaceAll]);
      DongaGmes.MesUserName  := StringReplace(DongaGmes.MesUserName, ']', '', [rfReplaceAll]);
      if not bError then begin
//        pnlUserName.Caption := DongaGmes.MesUserName;
//        pnlUserId.Caption := DongaGmes.MesUserId;
        for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin   // JH:qHWANG-GMES: 2018-06-20
          PasScr[nCh].m_bMesPMMode := False;
        end;

      end
      else begin

//        ShowNgMessage(sHostErrMsg);  // Added by KTS 2023-03-25 오후 12:22:01
      end;
    end;
    DefGmes.MES_EDTI  : begin
//      InitMainTool(True);
      ShowSysLog('DIO MES_EDTI: 1');
      for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
        frmTest4ChOC[i].SetHostConnShow(True);
      end;
      ShowSysLog('DIO MES_EDTI: 2');
      Common.m_sUserId := DongaGmes.MesUserId;
      ShowSysLog('DIO MES_EDTI: 3');
//      pnlUserId.Caption := Common.m_sUserId;
      if bError then begin
//        ShowNgMessage(sHostErrMsg);  // Added by KTS 2023-03-25 오후 12:24:05
      end;
      ShowSysLog('DIO MES_EDTI: 4');
      DisplayMes(True);
      ShowSysLog('DIO MES_EDTI: 5');

    end;
    DefGmes.MES_FLDR  : begin
      if bError then begin
//        ShowNgMessage(sHostErrMsg); // Added by KTS 2023-03-25 오후 12:24:15
      end;
    end;
    DefGmes.MES_APDR  : begin
      if bError then begin
//        ShowMessage(sHostErrMsg);  // Added by KTS 2023-03-25 오후 12:24:22
      end;
    end;
    DefGmes.MES_EQCC  : begin
      if bError then begin
//        ShowNgMessage(sHostErrMsg);  // Added by KTS 2023-03-25 오후 12:24:28
      end;
    end;
  end;
end;

procedure TfrmMain_OC.ProcessMsg_COMM_DIO(pGUIMsg: PGUIMessage);
var
  dtTime: TDateTime;
begin
  case pGUIMsg.Mode of
    CommDIO_DAE.COMMDIO_MSG_CONNECT :  begin//  COMMDIO_MSG_CONNECT: begin
      if pGUIMsg.Param <> 0 then begin
        pnlDioStatus.Caption := 'Connected'; // + IntToHex(CommDaeDIO.DeviceInfo.Version[0]); // + PGuiDaeDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
//            Display_Memory_DI;
//            Display_Memory_DO;
        ledDio.Value := True;
        ShowSysLog('DIO Connected:' + pGUIMsg.Msg);
      end
      else begin
        pnlDioStatus.Caption := 'Disconnected'; // + PGuiDaeDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
        ledDio.Value := False;
        ShowSysLog('DIO Disconnected:' + pGUIMsg.Msg, 1);
      end;
    end; //COMMPLC_MODE_CONNECT: begin
    CommDIO_DAE.COMMDIO_MSG_CHANGE_DI : begin //COMMDIO_MSG_CHANGE_DI: begin
      //데이터 변경
      { TODO : Teach Mode로 변경 될경우 Auto Mode 해제 처리 }

      Display_Memory_DI;
    end; //COMMDIO_MSG_CHANGE_DI: begin
    CommDIO_DAE.COMMDIO_MSG_CHANGE_DO : begin //COMMDIO_MSG_CHANGE_DO: begin
      //데이터 변경
      Display_Memory_DO;
//          if ControlDio <> nil then ControlDio.BackgroundErrorCheck;
    end; //COMMDIO_MSG_CHANGE_DO: begin
    CommDIO_DAE.COMMDIO_MSG_LOG: begin //COMMDIO_MSG_LOG: begin         
      //단순 로그
      ShowSysLog(pGUIMsg.Msg);
    end; //COMMDIO_MSG_LOG
    CommDIO_DAE.COMMDIO_MSG_ERROR: begin //COMMDIO_MSG_LOG: begin
      ShowSysLog('DIO ERROR : ' + pGUIMsg.Msg, 1);
    end; //COMMPLC_MODE_CHANGEDATA: begin
    ControlDio_OC.MSG_MODE_DISPLAY_ALARAM :  begin//  COMMDIO_MSG_CONNECT: begin
      Set_AlarmData(pGUIMsg.Param, pGUIMsg.Param2, 0); //경 알람
    end;
    ControlDio_OC.MSG_MODE_SYSTEM_ALARAM :  begin
      Set_AlarmData(pGUIMsg.Param, pGUIMsg.Param2, 1); //중 알람
    end;
    ControlDio_OC.MSG_MODE_DISPLAY_IO :  begin
      Display_Memory_DI;
      Display_Memory_DO;
    end;

  end;
end;

procedure TfrmMain_OC.ProcessMsg_COMM_ECS(pGUIMsg: PGUIMessage);
var
  i, nStage, nAnother: Integer;
  sMsg: String;
begin

  nStage:= GetStageNo_LoadZone;
  nAnother:= (nStage + 1) mod 2; //반대편 Stage

  case pGUIMsg.Mode of
    COMMPLC_MODE_CONNECT: begin
      //연결 처리
      case pGUIMsg.Param of
        0: begin
          //PLC 연결 됨
          pnlPlcStatus.Caption:= 'Connected';
          ledPlc.Value:= True;
          ShowSysLog('PLC Connected:' + pGUIMsg.Msg);
        end;
        1: begin
          pnlPlcStatus.Caption:= 'Disconnected';
          ledPlc.Value:= False;
          ShowSysLog('PLC Disconnected:' + pGUIMsg.Msg);
        end;
        2: begin
          pnlPlcStatus.Caption:= 'Link Test Expired';
          ledPlc.Value:= False;
          ShowSysLog('PLC Linkt Test Expired:' + pGUIMsg.Msg);
        end;
      end;
    end; //COMMPLC_MODE_CONNECT: begin

    COMMPLC_MODE_LOGIN: begin
      case pGUIMsg.Param of
        0: begin
          //NG
          ShowSysLog('ECS_UCHK NG ' + pGUIMsg.Msg,1);
          DisplayECS(False);
        end;
        1: begin
          //OK
          ShowSysLog('ECS_UCHK OK ' + pGUIMsg.Msg,3);
          DisplayECS(True);
        end;
        2: begin
          //OK
          ShowSysLog('ECS_UCHK NG Timeout ' + pGUIMsg.Msg);
          DisplayECS(True);
        end;
      end;
    end;

    COMMPLC_MODE_EVENT_ECS: begin
      case pGUIMsg.Param of
        1: begin  //시간 동기화
          ShowSysLog('ECS_READTIMEDATA ' + pGUIMsg.Msg);
        end;

        COMMPLC_PARAM_AAB_MODE: begin  //AAB Mode 변경
          Common.StatusInfo.AABMode:= pGUIMsg.Param2 <> 0;
          if pGUIMsg.Param2 <> 0 then begin
            ShowSysLog('ECS_AAB Mode ON ' + pGUIMsg.Msg);
          end
          else begin
            ShowSysLog('ECS_AAB Mode OFF ' + pGUIMsg.Msg);
          end;
        end;
      end;
    end;

    COMMPLC_MODE_EVENT_ROBOT: begin
      case pGUIMsg.Param of  //Robot 이벤트 종류
        COMMPLC_PARAM_GALSSDATA_REPORT: begin
          ShowSysLog(format('GlassData Report: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
          frmTest4ChOC[nStage].DisplayResult(pGUIMsg.Channel*2 + 0, -3, 0, 'GlassData Report');
          frmTest4ChOC[nStage].DisplayResult(pGUIMsg.Channel*2 + 1, -3, 0, 'GlassData Report');
          PasScr[nStage*4 + pGUIMsg.Channel*2].TestInfo.GlassID:=  g_CommPLC.GlassData[nStage*4 + pGUIMsg.Channel*2].GlassID;
          PasScr[nStage*4 + pGUIMsg.Channel*2 + 1].TestInfo.GlassID:=  g_CommPLC.GlassData[nStage*4 + pGUIMsg.Channel*2 + 1].GlassID;
        end;

        COMMPLC_PARAM_LOADCOMPLETE: begin
          if pGUIMsg.Param2 <> 0 then begin
            ShowSysLog(format('Load Complete On: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
            frmTest4ChOC[nStage].DisplayResult(pGUIMsg.Channel*2 + 0, -3, 0, 'Load Complete');
            frmTest4ChOC[nStage].DisplayResult(pGUIMsg.Channel*2 + 1, -3, 0, 'Load Complete');
            //Common.MLog(pGUIMsg.Channel*2 + 0 + nStage*4, 'Load Complete');
//            g_CommPLC.ECS_Glass_Processing(True);
            sMsg:= '[LOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[pGUIMsg.Channel*2 + 0 + nStage*4]);
            frmTest4ChOC[nStage].AddLog(sMsg, pGUIMsg.Channel*2 + 0);
            sMsg:= '[LOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[pGUIMsg.Channel*2 + 1 + nStage*4]);
            frmTest4ChOC[nStage].AddLog(sMsg, pGUIMsg.Channel*2 + 1);

          end
          else begin
            ShowSysLog(format('Load Complete Off: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));

          end; //else begin
        end; //COMMPLC_PARAM_LOADCOMPLETE_OFF: begin

        COMMPLC_PARAM_LOADBUSY: begin
          if pGUIMsg.Param2 <> 0 then begin
            ShowSysLog(format('Load Busy On: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
            {$IFDEF SIMULATOR_DIO}
            ControlDio.WriteDioSig(DefDio.OUT_UNDEFINED_37 + pGUIMsg.Channel*32,false);
            {$ENDIF}
          end
          else begin
            ShowSysLog(format('Load Busy Off: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));

            //Glass Position 보고
            UpdateECS_Glass_Position_Pair(nStage, pGUIMsg.Channel); //ECS_Glass_Postion  // Added by KTS 2023-03-23 오후 4:51:22

            if Common.StatusInfo.LastProduct then begin
              //잔량 처리일 경우Detect 검사 안하고 바로 시작한다.

              if CheckDetect_Empty(nStage) then begin
                ShowSysLog(format('Last Product Process: Do not Start - Stage=%d  Empty', [nStage]));
                Exit;
              end;

              //Unload가 남아 있으면 
              if g_CommPLC.IsUnloadRequest_Robot(pGUIMsg.Channel) then begin
                ShowSysLog('Last Product Process: Do not Start - Unloading..');
                Exit;
              end;

              ShowSysLog('Last Product Process: AutoStart');
              Execute_AutoStart(pGUIMsg.Channel);
              Exit;
            end; //if Common.StatusInfo.LastProduct then begin

            ShowSysLog(format('CheckDetect_Loaded CH=%d', [pGUIMsg.Channel]));

            //일반 처리
            if not CheckDetect_Loaded( pGUIMsg.Channel) then begin
              //로드 이상 - Detect NG는  Pair로 처리
              if Common.SystemInfo.OCType = DefCommon.OCType then begin
                Set_AlarmData(IN_CH_1_CARRIER_SENSOR + pGUIMsg.Channel*32 , 1, 1);
                Set_AlarmData(IN_CH_1_CARRIER_SENSOR + pGUIMsg.Channel*32 + 16 , 1, 1);
              end
              else begin
                Set_AlarmData(IN_GIB_CH_1_CARRIER_SENSOR + pGUIMsg.Channel*16 , 1, 1);
                Set_AlarmData(IN_GIB_CH_1_CARRIER_SENSOR + pGUIMsg.Channel*16 + 8 , 1, 1);
              end;
              //sMsg:= format('!!!!! Detect NG Pair=%d', [pGUIMsg.Channel]);
              //ShowNgMessage(sMsg);
              //ShowSysLog(sMsg, 1);
              Exit;
            end;
            ShowSysLog(format('CheckDetect_Loaded CH=%d Doen', [pGUIMsg.Channel]));

            //Unload가 남아 있으면
            ShowSysLog(format('IsUnloadRequest_Robot CH=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));

            if g_CommPLC.IsUnloadRequest_Robot(pGUIMsg.Channel) then begin
              ShowSysLog('Do not Start - Unloading..');
              Exit;
            end;

            //Load가 남아 있으면
            if g_CommPLC.IsLoadRequest_Robot(pGUIMsg.Channel) then begin
              ShowSysLog('Do not Start - Load Request');
              Exit;
            end;

            //자동 시작 확인
            if CheckReadyToAutoStart(pGUIMsg.Channel) then begin
//              ShowSysLog('Auto Start - Full Load');

              Execute_AutoStart(pGUIMsg.Channel); // Added by KTS 2023-03-28 오후 3:28:34
//              ShowSysLog('Auto Start - End');

            end
            else begin
              ShowSysLog(format('Ready To Start Pair=%d', [pGUIMsg.Channel]));
            end;
          end;
        end; //COMMPLC_PARAM_LOADBUSY: begin

        COMMPLC_PARAM_UNLOADCOMPLETE: begin
          //Unload 완료 시에는....

          //Exchange에서 요청 된 것이 아닐 경우 Load 요청
          if pGUIMsg.Param2 <> 0 then begin
            ShowSysLog(format('Unload Complete On: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
            frmTest4ChOC[nStage].DisplayResult(pGUIMsg.Channel*2 + 0, -3, 0, 'Unload Complete');
            frmTest4ChOC[nStage].DisplayResult(pGUIMsg.Channel*2 + 1, -3, 0, 'Unload Complete');
            {$IFDEF SIMULATOR_DIO}
            ControlDio.WriteDioSig(DefDio.OUT_UNDEFINED_37 + pGUIMsg.Channel*32,true);
            {$ENDIF}
          end
          else begin
            ShowSysLog(format('Unload Complete Off: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
          end;
        end; //COMMPLC_PARAM_UNLOADCOMPLETE: begin

        COMMPLC_PARAM_UNLOADBUSY: begin
          if pGUIMsg.Param2 <> 0 then begin
            ShowSysLog(format('Unload Busy On: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
          end
          else begin
            ShowSysLog(format('Unload Busy Off: Pair=%d, %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
            UpdateECS_Glass_Position_Pair(nStage, pGUIMsg.Channel); //ECS_Glass_Postion   // Added by KTS 2023-03-23 오후 4:51:33

            if Common.StatusInfo.LastProduct then begin
              //잔량 처리일 경우 Unload 완료 시 로드 된 것이 있으면 자동 시작 
              //양쪽 모두 빈 경우 
              //Unload가 남아 있으면 
              if g_CommPLC.IsUnloadRequest_Robot(pGUIMsg.Channel) then begin
                ShowSysLog('Last Product Process: Do not Start - Unloading..');
                Exit;
              end;

              if CheckDetect_Empty(nStage) and CheckDetect_Empty(nAnother) then begin
                ShowSysLog(format('Last Product Process: Do not Start - Stage=%d  Empty', [nStage]));
                Exit;
              end;

              if not CheckDetect_Empty(nStage) then begin
                ShowSysLog('Last Product Process: AutoStart');
                Execute_AutoStart(pGUIMsg.Channel);
                Exit;
              end;

              if not CheckDetect_Empty(nAnother) then begin
                //모든 스크립트 종료 되지 않았으면 통과
                for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
                  //Stage의 모든 채널이 작업 종료일 때
                  if PasScr[i].m_bIsScriptWork then begin
                    ShowSysLog('Last Product Process: Do not Turn - Another Side is Working');
                    Exit;
                  end;
                end;
//                ShowSysLog('Last Product Process: Turn - Another Side Detected');    // Added by KTS 2022-08-23 오후 3:41:00
//                //턴 처리
//                ThreadTurnStage;
              end;
              Exit;
            end;
            Robot_Request_LoadUnLoad(pGUIMsg.Channel);
          end;
        end; //COMMPLC_PARAM_UNLOADBUSY: begin

        COMMPLC_PARAM_INSPECTION_START: begin
          //검사 시작
//          ShowSysLog(format('Inspection Start Pair=%d - %s', [pGUIMsg.Channel, pGUIMsg.Msg]));
//          //Busy가 살아 있울경우 동작 안함
//          if g_CommPLC.IsBusy_Robot then begin
//            ShowSysLog('Do not Auto Start - Robot Busy');
//            Exit;
//          end;
//
//          Execute_AutoStart;
        end; //COMMPLC_PARAM_INSPECTION_START: begin

        COMMPLC_PARAM_RESET_COUNT: begin
          //Reset count
          ShowSysLog('Reset Count: ' + pGUIMsg.Msg);
        end; //COMMPLC_PARAM_RESET_COUNT: begin

        COMMPLC_PARAM_DOOR_OPENED: begin
          //Reset count
          ShowSysLog('Robot Door Opened: ' + pGUIMsg.Msg);
          Set_AlarmData(114, pGUIMsg.Param2, 0); //경알람
        end; //COMMPLC_PARAM_RESET_COUNT: begin

        COMMPLC_PARAM_LAST_PRODUCT: begin
          //Last Product
          //자기 Zone 해당 확인(A Zone(0):33,34,35,36, B Zone(1):37,38,39,40, C Zone(2):41,42,43,44)
          if pGUIMsg.Channel <> Common.PLCInfo.Zone then Exit;

          Common.StatusInfo.LastProduct:= pGUIMsg.Param2 <> 0;

          if Common.StatusInfo.LastProduct then begin
            ShowSysLog('Last Product: On');

            if not Common.StatusInfo.AutoMode then begin
              ShowSysLog('Last Product: Not Auto mode');
              Exit;  //자동 모드 아니면 무시
            end;

            if Common.StatusInfo.StageTurnning then begin
              ShowSysLog('Last Product: Turning..');
              Exit;  //Turn 중에는 무시
            end;

            if not CheckDetect_Empty(nStage) then begin
              //1개라도 있으면 시작
              if CheckStage_Started(nStage) then begin
                ShowSysLog('Last Product Process: Do Not Start - Script is Running');
                Exit;
              end;
              ShowSysLog('Last Product Process: AutoStart');
              Execute_AutoStart(pGUIMsg.Channel);
            end
            else begin
              if CheckDetect_Empty(nAnother) then begin
                ShowSysLog('Last Product Process: Do not Turn - Another Side is empty');
                Exit;
              end;

              //모든 스크립트 종료 되지 않았으면 통과
              for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
                //Stage의 모든 채널이 작업 종료일 때
                if PasScr[i].m_bIsScriptWork then begin
                  ShowSysLog('Last Product Process: Do not Turn - Another Side is Working');
                  Exit;
                end;
              end;
//              ShowSysLog('Last Product Process: Turn - Another Side Detected');     // Added by KTS 2022-08-23 오후 3:41:22
//              //턴 처리
//              ThreadTurnStage;
            end;
          end
          else begin
            ShowSysLog('Last Product: Off');
          end;
          
        end; //COMMPLC_PARAM_LAST_PRODUCT: begin

//        COMMPLC_PARAM_INTERFACE_ERROR: begin
//          //Reset count
//          ShowSysLog('Robot Interface Error: ' + pGUIMsg.Msg);
//          Set_AlarmData(117, pGUIMsg.Param2, 1); //경알람
//        end; //COMMPLC_PARAM_INTERFACE_ALARM
      end; //case pGUIMsg.Param of //Robot 이벤트 종류
    end; //COMMPLC_MODE_EVENT_ROBOT: begin
  end;
end;

procedure TfrmMain_OC.ProcessMsg_SCRIPT(pGUIMsg: PGUIMessage);
var
  nCh : Integer;
  sDebug : string;
begin
  nCh:= pGUIMsg.Channel;
  case pGUIMsg.Mode of
    DefCommon.MSG_MODE_LOG_CSV : begin
      //
    end;
    DefCommon.MSG_MODE_LOG_CSV_SUMMARY : begin
      SaveCsvSummaryLog(nCh);
    end;
    DefCommon.MSG_MODE_LOG_CSV_APDR : begin
      MakeCsvApdrLog(nCh);
    end;
    DefGmes.MES_PCHK : begin
      //sDebug := 'MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
      DongaGmes.MesSerialType := PasScr[nCh].TestInfo.nSerialType;
      DongaGmes.SendHostPchk(PasScr[nCh].TestInfo.SerialNo, nCh);
    end;
    DefGmes.MES_INS_PCHK : begin
      //sDebug := 'MSG_TYPE_HOST, MES_INS_PCHK, PG'+IntToStr(nCh+1); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
      DongaGmes.SendHostIns_Pchk(PasScr[nCh].TestInfo.SerialNo, nCh);
    end;
    DefGmes.MES_EICR : begin
      //sDebug := 'MSG_TYPE_HOST, MES_EICR, PG'+IntToStr(nCh+1); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
      DongaGmes.SendHostEicr(PasScr[nCh].TestInfo.SerialNo, nCh, PasScr[nCh].m_sCarrierId{.TestInfo.CarrierId});
    end;
    Defgmes.MES_RPR_EIJR : begin
      DongaGmes.SendHostRPr_Eijr(PasScr[nCh].TestInfo.SerialNo, nCh);
    end;
    DefGmes.MES_APDR : begin
      DongaGmes.MesData[nCh].ApdrData := PasScr[nCh].TestInfo.ApdrData;
      DongaGmes.SendHostApdr(PasScr[nCh].TestInfo.SerialNo, nCh);
    end;
    DefGmes.MES_SGEN : begin
      //sDebug := 'MSG_TYPE_HOST, MES_SGEN, PG'+IntToStr(nCh+1); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
      DongaGmes.SendHostSGEN(PasScr[nCh].TestInfo.SerialNo, nCh);
    end;
    DefGmes.EAS_APDR : begin
      DongaGmes.MesData[nCh].ApdrData := PasScr[nCh].TestInfo.ApdrData;
      DongaGmes.SendEasApdr(PasScr[nCh].TestInfo.SerialNo, nCh);
    end;
  end;
end;

procedure TfrmMain_OC.ProcessMsg_STAGE(pGUIMsg: PGUIMessage);
var
  nCHGoup, nAnother : Integer;
  nScriptSEQ: Integer;
  i: Integer;
  sMsg : string;
begin
  //Application.ProcessMessages;
  nCHGoup:= pGUIMsg.Channel;
  nAnother:= (nCHGoup + 1) mod 2; //반대편 Stage
  nScriptSEQ:=  pGUIMsg.Param2;

  //if Common.StatusInfo.AutoMode then begin
  case pGUIMsg.Mode of

    MSG_TYPE_DLL : begin
      sMsg  := string(pGUIMsg.Msg);
      pnlLGDDLLName.Caption :=  sMsg;
    end; //DefCommon.MSG_TYPE_DLL : begin

    STAGE_MODE_UNLOAD :  begin

      if pGUIMsg.Param = 2 then begin
        //A Front
        ShowSysLog(Format('STAGE_MODE_UNLOAD - CH %d',[nCHGoup]));

        if ControlDio.IsDetected(nCHGoup) then begin
          //패널이 있을 경우
          //if Common.StatusInfo.StageStep[JIG_A] >= STAGE_STEP_CAMZONE_FINISH then begin
            ShowSysLog(format('UnloadScriptStart CH = %d',[nCHGoup]));
            Common.StatusInfo.StageStep[nCHGoup]:= STAGE_STEP_UNLOADZONE;
            frmTest4ChOC[DefCommon.JIG_A].UnloadScriptStart(nCHGoup);
          //end;
        end
        else begin
          //패널이 없을 경우 로드 요청
          if Common.StatusInfo.AutoMode then begin
            ShowSysLog('Stage Not Detected A - Request Load');
            Robot_Request_LoadUnLoad(nCHGoup);
          end;
        end;

      end
      else begin
        //예외
        ShowSysLog('Unknown Msg: ' + pGUIMsg.Msg);
      end;
    end;

    STAGE_MODE_SCRIPT_DONE_UNLOAD: begin
      //Unloadzone 종료
      ShowSysLog(format('Stage Script UnloadZone Done Stage=%d, Ch=%d, Step=%d', [pGUIMsg.Channel, pGUIMsg.Param, pGUIMsg.Param2]));

      if Common.StatusInfo.AutoMode then begin
        if Common.SystemInfo.OCType = DefCommon.OCType  then
          Robot_Request_LoadUnLoad(pGUIMsg.Channel)
        else
          Robot_Request_Exchange(pGUIMsg.Channel);

      end;
    end; //STAGE_MODE_SCRIPT_DONE_UNLOAD: begin

    STAGE_MODE_TEST_START: begin
      //Start 버튼
      ShowSysLog(format('Start Test Stage=%d', [pGUIMsg.Channel]));
      if Common.StatusInfo.AutoMode then begin
//          g_CommPLC.EQP_Clear_ROBOT_Request(pGUIMsg.Channel);     // Added by KTS 2023-03-19 오전 10:33:43
      end;
    end; //STAGE_MODE_TEST_START

    STAGE_MODE_TEST_STOP: begin
      //Start 버튼
      ShowSysLog(format('Stop Test Stage=%d', [pGUIMsg.Channel]));
      if Common.StatusInfo.AutoMode then begin
//          g_CommPLC.EQP_Clear_ROBOT_Request(pGUIMsg.Channel);     // Added by KTS 2023-03-19 오전 10:33:50
      end;
    end; //STAGE_MODE_TEST_STOP
  end;  //case pGUIMsg.Mode of
  //end; //if Common.StatusInfo.AutoMode then begin
end;


procedure TfrmMain_OC.ReleaseReadyModOnPlc;
begin
  if Common.StatusInfo.AutoMode then Set_AutoMode(False);
end;

procedure TfrmMain_OC.Robot_Request_Exchange(nCh: Integer);
var
  nRet: Integer;
  nStage: Integer;
  sMsg: String;
begin
  if g_CommPLC = nil then  Exit;

  //4채널 동시 진행으로 수정
  nStage:= GetStageNo_LoadZone;

  ShowSysLog(format('Robot_Request_Exchange %s', [chr(ord('A') + nStage)]));

  Common.StatusInfo.Loading:= True; //로딩 중 Interlock

  ThreadTask(procedure begin
    //ContactDown 때문에 쓰레드 필요
try
    //Pogo 사용여부에 따른 처리
//    if Common.SystemInfo.UseNoPogo then begin
//      nRet:= ControlDio.ClampUp(DefCommon.CH_STAGE_A + nStage);
//    end
//    else begin
//      nRet:= ControlDio.ContactDown(DefCommon.CH_STAGE_A + nStage);
//    end;

//    nRet:= ControlDio.UnlockCarrier(nCh,False);


    if nRet <> 0 then begin
      //ShowSysLog(format('ContactDown NG %s Ret=%d', [chr(ord('A') + nStage), nRet]));
      //알람 처리 필요.
      Exit;
    end;
{$REGION 'Last Product'}
    if Common.StatusInfo.LastProduct then begin
      //잔여 처리
      if not CheckLoad_Used(nStage, COMMPLC_CH_12) then begin
        //사용 안할 경우
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Not Used Pair=0');
      end
      else if not CheckEmpty_Pair(nStage, COMMPLC_CH_12) then begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(nStage) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 0', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(0);
        frmTest4ChOC[nStage].ClearChData(1);
        frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request Load');
        frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request Load');

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_LOADING;
        g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_12);
      end
      else begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(nStage) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: not Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Exchange %s 0', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(0);
        frmTest4ChOC[nStage].ClearChData(1);
        frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request Exchange');
        frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request Exchange');
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[0 + nStage*4]);
        //Common.MLog(0 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 0);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 0, sMsg);
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[1 + nStage*4]);
        //Common.MLog(1 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 1);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 1, sMsg);

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_EXCHANGE;
        g_CommPLC.ROBOT_Exchange_Request(COMMPLC_CH_12);
      end;

      Sleep(10);

      if not CheckLoad_Used(nStage, COMMPLC_CH_34) then begin
        //사용 안할 경우
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Not Used Pair=1');
      end
      else if CheckEmpty_Pair(nStage, COMMPLC_CH_34) then begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(nStage) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 1', [chr(ord('A') + nStage)]));
        frmTest4ChOC[nStage].ClearChData(2);
        frmTest4ChOC[nStage].ClearChData(3);
        frmTest4ChOC[nStage].DisplayResult(2, -1, 0, 'Request Load');
        frmTest4ChOC[nStage].DisplayResult(3, -1, 0, 'Request Load');

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_LOADING;
        g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_34);
      end
      else begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(nStage) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: not Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Exchange %s 1', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(2);
        frmTest4ChOC[nStage].ClearChData(3);
        frmTest4ChOC[nStage].DisplayResult(2, -3, 0, 'Request Exchange');
        frmTest4ChOC[nStage].DisplayResult(3, -3, 0, 'Request Exchange');

        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[2 + nStage*4]);
        //Common.MLog(2 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 2);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 2, sMsg);
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[3 + nStage*4]);
        //Common.MLog(3 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 3);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 3, sMsg);

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_EXCHANGE;
        g_CommPLC.ROBOT_Exchange_Request(COMMPLC_CH_34);
      end;

      exit;
    end; // if Common.StatusInfo.LastProduct then begin
{$ENDREGION}
    if not CheckLoad_Used(nStage, COMMPLC_CH_12) then begin
      //사용 안할 경우
      SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Not Used Pair=0');
    end
    else if not CheckEmpty_Pair(nStage, COMMPLC_CH_12) then begin
      //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
      if CheckStage_Started(nStage) then begin
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
        Exit;
      end;
      if not CheckProbe(COMMPLC_CH_12) then begin
        if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
          nRet := 0;
          nRet := ControlDio.ProbeBackward(DefCommon.CH1);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 1- NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(DefCommon.CH1,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 1 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(DefCommon.CH2);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 2 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(DefCommon.CH2,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier  2- NG');
            Exit;
          end;
        end
        else begin
          nRet := 0;
          nRet := ControlDio.MovingProbe(DefCommon.CH_TOP,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingProbe UP CH 1,2 - NG');
            Exit;
          end;
          nRet := ControlDio.MovingShutter(DefCommon.CH_TOP,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingShutter UP CH 1,2 - NG');
            Exit;
          end;
          if not CheckPinBlock(0) then begin
            nRet := ControlDio.VaccumOFF(DefCommon.CH1);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 1 - NG');
              Exit;
            end;
            nRet := ControlDio.VaccumOFF(DefCommon.CH2);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 2 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH1);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 1 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH2);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 2 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH1);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock CLose Prev. UP CH 1 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH2);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock CLose Prev. UP CH 2 - NG');
              Exit;
            end;
          end;
        end;
      end;


      SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 0', [chr(ord('A') + nStage)]));
      frmTest4ChOC[nStage].ClearChData(0);
      frmTest4ChOC[nStage].ClearChData(1);
      frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request Load');
      frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request Load');
      Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_LOADING;


      g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_12);
    end
    else begin
      //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
      if CheckStage_Started(nStage) then begin
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
        Exit;
      end;

      SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Exchange %s 0', [chr(ord('A') + nStage)]));
      if not CheckProbe(COMMPLC_CH_12) then begin
        if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
          nRet := 0;
          nRet := ControlDio.ProbeBackward(0);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 1 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(0,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 1 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(1);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 2 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(1,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier  2- NG');
            Exit;
          end;
        end
        else begin
          nRet := 0;
          nRet := ControlDio.MovingProbe(DefCommon.CH_TOP,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingProbe UP CH 1,2 - NG');
            Exit;
          end;
          nRet := ControlDio.MovingShutter(DefCommon.CH_TOP,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingShutter UP CH 1,2 - NG');
            Exit;
          end;
          if not CheckPinBlock(0) then begin
            nRet := ControlDio.VaccumOFF(DefCommon.CH1);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 1 - NG');
              Exit;
            end;
            nRet := ControlDio.VaccumOFF(DefCommon.CH2);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 2 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH1);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 1 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH2);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 2 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH1);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock CLose Prev. UP CH 1 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH2);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock CLose Prev. UP CH 2 - NG');
              Exit;
            end;
          end;
        end;
      end;

      frmTest4ChOC[nStage].ClearChData(0);
      frmTest4ChOC[nStage].ClearChData(1);
      frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request Exchange');
      frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request Exchange');

      sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[0 + nStage*4]);
      //Common.MLog(0 + nStage*4, sMsg);
      //frmTest4ChOC[nStage].AddLog(sMsg, 0);
      SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 0, sMsg);
      sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[1 + nStage*4]);
      //Common.MLog(1 + nStage*4, sMsg);
      //frmTest4ChOC[nStage].AddLog(sMsg, 1);
      SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 1, sMsg);

      Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_EXCHANGE;
      g_CommPLC.ROBOT_Exchange_Request(COMMPLC_CH_12);
    end;

    Sleep(10);

    if not CheckLoad_Used(nStage, COMMPLC_CH_34) then begin
      //사용 안할 경우
      SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Not Used Pair=1');
    end
    else if not CheckEmpty_Pair(nStage, COMMPLC_CH_34) then begin
      //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
      if CheckStage_Started(nStage) then begin
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
        Exit;
      end;

      if not CheckProbe(COMMPLC_CH_34) then begin
        if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
          nRet := 0;
          nRet := ControlDio.ProbeBackward(DefCommon.CH3);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward CH 3- NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(DefCommon.CH3,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier CH 3 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(DefCommon.CH4);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward CH 4 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(DefCommon.CH4,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier  CH 4 - NG');
            Exit;
          end;
        end
        else begin
          nRet := 0;
          nRet := ControlDio.MovingProbe(DefCommon.CH_BOTTOM,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingProbe UP CH 3,4 - NG');
            Exit;
          end;
          nRet := ControlDio.MovingShutter(DefCommon.CH_BOTTOM,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingShutter UP CH 3,4 - NG');
            Exit;
          end;
          if not CheckPinBlock(1) then begin
            nRet := ControlDio.VaccumOFF(DefCommon.CH3);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 3 - NG');
              Exit;
            end;
            nRet := ControlDio.VaccumOFF(DefCommon.CH4);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 4 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH3);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 3 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH4);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 4 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH3);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock CLose Prev. UP CH 3 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH4);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock CLose Prev. UP CH 4 - NG');
              Exit;
            end;
          end;
        end;
      end;

      SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 1', [chr(ord('A') + nStage)]));
      frmTest4ChOC[nStage].ClearChData(2);
      frmTest4ChOC[nStage].ClearChData(3);
      frmTest4ChOC[nStage].DisplayResult(2, -3, 0, 'Request Load');
      frmTest4ChOC[nStage].DisplayResult(3, -3, 0, 'Request Load');
      Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_LOADING;
      g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_34);
    end
    else begin
      //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
      if CheckStage_Started(nStage) then begin
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
        Exit;
      end;

      SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Exchange %s 1', [chr(ord('A') + nStage)]));
      if not CheckProbe(COMMPLC_CH_34) then begin
        if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
          nRet := 0;
          nRet := ControlDio.ProbeBackward(2);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward CH 3- NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(2,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier CH 3 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(3);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward CH 4 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(3,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier CH 4 - NG');
            Exit;
          end;
        end
        else begin
          nRet := 0;
          nRet := ControlDio.MovingProbe(DefCommon.CH_BOTTOM,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingProbe UP CH 3,4 - NG');
            Exit;
          end;
          nRet := ControlDio.MovingShutter(DefCommon.CH_BOTTOM,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'MovingShutter UP CH 3,4 - NG');
            Exit;
          end;
          if not CheckPinBlock(1) then begin
            nRet := ControlDio.VaccumOFF(DefCommon.CH3);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 3 - NG');
              Exit;
            end;
            nRet := ControlDio.VaccumOFF(DefCommon.CH4);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'VaccumOFF CH 4 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH3);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 3 - NG');
              Exit;
            end;
            nRet := ControlDio.UnlockPinBlock(DefCommon.CH4);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockPinBlock CH 4 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH3);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock CLose Prev. UP CH 3 - NG');
              Exit;
            end;
            nRet := ControlDio.CLOSE_Up_PinBlock(DefCommon.CH4);
            if nRet > 0 then begin
              SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'PinBlock Close Prev. UP CH 4 - NG');
              Exit;
            end;
          end;
        end;
      end;

      frmTest4ChOC[nStage].ClearChData(2);
      frmTest4ChOC[nStage].ClearChData(3);
      frmTest4ChOC[nStage].DisplayResult(2, -3, 0, 'Request Exchange');
      frmTest4ChOC[nStage].DisplayResult(3, -3, 0, 'Request Exchange');

      sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[2 + nStage*4]);
      //Common.MLog(2 + nStage*4, sMsg);
      //frmTest4ChOC[nStage].AddLog(sMsg, 2);
      SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 2, sMsg);
      sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[3 + nStage*4]);
      //Common.MLog(3 + nStage*4, sMsg);
      //frmTest4ChOC[nStage].AddLog(sMsg, 3);
      SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 3, sMsg);

      Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_EXCHANGE;
      g_CommPLC.ROBOT_Exchange_Request(COMMPLC_CH_34);
    end;

    //둘다 사용하지 않을 경우
    //Common.StatusInfo.Loading:= Falses;
except
  on E: Exception do SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Exception: Robot_Request_Exchange ' + E.Message);
end;
  end); //ThreadTask(procedure begin

end;

procedure TfrmMain_OC.Robot_Request_LoadUnLoad(nCh: Integer);
var
  nRet: Integer;
  nStage: Integer;
  sMsg: String;
begin
  if g_CommPLC = nil then  Exit;

  //4채널 동시 진행으로 수정
  nStage:= GetStageNo_LoadZone;

  ShowSysLog(format('Robot_Request_LoadUnLoad %s', [chr(ord('A') + nStage)]));

  Common.StatusInfo.Loading:= True; //로딩 중 Interlock

  ThreadTask(procedure begin
    //ContactDown 때문에 쓰레드 필요
try
    //Pogo 사용여부에 따른 처리
//    if Common.SystemInfo.UseNoPogo then begin
//      nRet:= ControlDio.ClampUp(DefCommon.CH_STAGE_A + nStage);
//    end
//    else begin
//      nRet:= ControlDio.ContactDown(DefCommon.CH_STAGE_A + nStage);
//    end;

//    nRet:= ControlDio.UnlockCarrier(DefCommon.CH_ALL,False);

//
//    if nRet <> 0 then begin
//      //ShowSysLog(format('ContactDown NG %s Ret=%d', [chr(ord('A') + nStage), nRet]));
//      //알람 처리 필요.
//      Exit;
//    end;
{$REGION 'Last Product'}
    if Common.StatusInfo.LastProduct then begin
      //잔여 처리
      if not CheckLoad_Used(nStage, COMMPLC_CH_12) then begin
        //사용 안할 경우
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Not Used Pair=0');
      end
      else if not CheckEmpty_Pair(nStage, COMMPLC_CH_12) then begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(nStage) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 0', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(0);
        frmTest4ChOC[nStage].ClearChData(1);
        frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request Load');
        frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request Load');

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_LOADING;
        g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_12);
      end
      else begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(nStage) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: not Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Exchange %s 0', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(0);
        frmTest4ChOC[nStage].ClearChData(1);
        frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request Exchange');
        frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request Exchange');
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[0 + nStage*4]);
        //Common.MLog(0 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 0);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 0, sMsg);
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[1 + nStage*4]);
        //Common.MLog(1 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 1);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 1, sMsg);

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_EXCHANGE;
        g_CommPLC.ROBOT_Exchange_Request(COMMPLC_CH_12);
      end;

      Sleep(10);

      if not CheckLoad_Used(nStage, COMMPLC_CH_34) then begin
        //사용 안할 경우
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Not Used Pair=1');
      end
      else if CheckEmpty_Pair(nStage, COMMPLC_CH_34) then begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(nStage) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 1', [chr(ord('A') + nStage)]));
        frmTest4ChOC[nStage].ClearChData(2);
        frmTest4ChOC[nStage].ClearChData(3);
        frmTest4ChOC[nStage].DisplayResult(2, -1, 0, 'Request Load');
        frmTest4ChOC[nStage].DisplayResult(3, -1, 0, 'Request Load');

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_LOADING;
        g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_34);
      end
      else begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(COMMPLC_CH_34) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Last Product Process: not Empty');
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Exchange %s 1', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(2);
        frmTest4ChOC[nStage].ClearChData(3);
        frmTest4ChOC[nStage].DisplayResult(2, -3, 0, 'Request Exchange');
        frmTest4ChOC[nStage].DisplayResult(3, -3, 0, 'Request Exchange');

        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[2 + nStage*4]);
        //Common.MLog(2 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 2);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 2, sMsg);
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[3 + nStage*4]);
        //Common.MLog(3 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 3);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 3, sMsg);

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_EXCHANGE;
        g_CommPLC.ROBOT_Exchange_Request(COMMPLC_CH_34);
      end;

      exit;
    end; // if Common.StatusInfo.LastProduct then begin
{$ENDREGION}
    if nCh = CH_TOP then begin

      Sleep(500);
      if not CheckLoad_Used(nStage, COMMPLC_CH_12) then begin
        //사용 안할 경우
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Not Used Pair=0');
      end
      else if not CheckEmpty_Pair(nStage, COMMPLC_CH_12) then begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if not CheckProbe(COMMPLC_CH_12) then begin
          nRet := 0;
          nRet := ControlDio.ProbeBackward(0);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 1- NG');

            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(0,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 1 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(1);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 2 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(1,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier  2- NG');
            Exit;
          end;
        end;

        if CheckStage_Started(COMMPLC_CH_12) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
          Exit;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 0', [chr(ord('A') + nStage)]));
        frmTest4ChOC[nStage].ClearChData(0);
        frmTest4ChOC[nStage].ClearChData(1);
        frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request Load');
        frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request Load');
        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_LOADING;
        g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_12);
      end
      else begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(COMMPLC_CH_12) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
          Exit;
        end;
        if not CheckProbe(COMMPLC_CH_12) then begin
          nRet := 0;
          nRet := ControlDio.ProbeBackward(0);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 1- NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(0,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 1 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(1);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 2 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(1,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier  2- NG');
            Exit;
          end;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request UnLoad %s 0', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(0);
        frmTest4ChOC[nStage].ClearChData(1);
        frmTest4ChOC[nStage].DisplayResult(0, -3, 0, 'Request UnLoad');
        frmTest4ChOC[nStage].DisplayResult(1, -3, 0, 'Request UnLoad');

        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[0 + nStage*4]);
        Common.MLog(0 + nStage*4, sMsg);
        frmTest4ChOC[nStage].AddLog(sMsg, 0);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 0, sMsg);
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[1 + nStage*4]);
        Common.MLog(1 + nStage*4, sMsg);
        frmTest4ChOC[nStage].AddLog(sMsg, 1);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 1, sMsg);

        Common.StatusInfo.StageStep[nStage]:= STAGE_STEP_UNLOADING;
        g_CommPLC.ROBOT_Unload_Request(COMMPLC_CH_12);
      end;

    end;


    if nCh = CH_BOTTOM then begin
      Sleep(500);
      if not CheckLoad_Used(nStage, COMMPLC_CH_34) then begin
        //사용 안할 경우
        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Not Used Pair=1');
      end
      else if not CheckEmpty_Pair(nStage, COMMPLC_CH_34) then begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(COMMPLC_CH_34) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
          Exit;
        end;
        if not CheckProbe(COMMPLC_CH_34) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'CheckProbe - NG');
//          ThreadTask(procedure begin
//            ControlDio.ProbeBackward(2);
//            ControlDio.UnlockCarrier(2,true);
//            ControlDio.ProbeBackward(3);
//            ControlDio.UnlockCarrier(3,true);
//
//
//          end);
          nRet := 0;
          nRet := ControlDio.ProbeBackward(2);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 3- NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(2,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 3 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(3);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 4 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(3,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 4 - NG');
            Exit;
          end;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request Load %s 1', [chr(ord('A') + nStage)]));
        frmTest4ChOC[nStage].ClearChData(2);
        frmTest4ChOC[nStage].ClearChData(3);
        frmTest4ChOC[nStage].DisplayResult(2, -3, 0, 'Request Load');
        frmTest4ChOC[nStage].DisplayResult(3, -3, 0, 'Request Load');
        Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_LOADING;
        g_CommPLC.ROBOT_Load_Request(COMMPLC_CH_34);
      end
      else begin
        //Last Product 갑자기 변경하는 현상에 대한 방어 - Start 여부 확인
        if CheckStage_Started(COMMPLC_CH_34) then begin
          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Do not Request - Script is Running');
          Exit;
        end;
        if not CheckProbe(COMMPLC_CH_34) then begin
//          SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'CheckProbe - NG');
//          ThreadTask(procedure begin
//            ControlDio.ProbeBackward(2);
//            ControlDio.UnlockCarrier(2,true);
//            ControlDio.ProbeBackward(3);
//            ControlDio.UnlockCarrier(3,true);
//
//
//          END);
          nRet := 0;
          nRet := ControlDio.ProbeBackward(2);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 3- NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(2,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 3 - NG');
            Exit;
          end;
          nRet := ControlDio.ProbeBackward(3);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'ProbeBackward 4 - NG');
            Exit;
          end;
          nRet := ControlDio.UnlockCarrier(3,true);
          if nRet > 0 then begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'UnlockCarrier 4 - NG');
            Exit;
          end;
        end;

        SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, format('Request UnLoad %s 1', [chr(ord('A') + nStage)]));

        frmTest4ChOC[nStage].ClearChData(2);
        frmTest4ChOC[nStage].ClearChData(3);
        frmTest4ChOC[nStage].DisplayResult(2, -3, 0, 'Request UnLoad');
        frmTest4ChOC[nStage].DisplayResult(3, -3, 0, 'Request UnLoad');

        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[2 + nStage*4]);
        //Common.MLog(2 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 2);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 2, sMsg);
        sMsg:= '[UNLOAD GLASSDATA] ' + g_CommPLC.GetGlassDataString(g_CommPLC.GlassData[3 + nStage*4]);
        //Common.MLog(3 + nStage*4, sMsg);
        //frmTest4ChOC[nStage].AddLog(sMsg, 3);
        SendMsgAddLog(MSG_MODE_ADDLOG_CHANNEL, nStage, 3, sMsg);

        Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_UNLOADING;
        g_CommPLC.ROBOT_Unload_Request(COMMPLC_CH_34);
      end;

    end;

    //둘다 사용하지 않을 경우
    //Common.StatusInfo.Loading:= Falses;
except
  on E: Exception do SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Exception: Robot_Request_Exchange ' + E.Message);
end;
  end); //ThreadTask(procedure begin

end;


procedure TfrmMain_OC.RzPanel6DblClick(Sender: TObject);
begin
  Button1.Visible := not Button1.Visible;
end;

procedure TfrmMain_OC.DongaSwitchRevSwDataJig(nGroup : Integer; sGetData: String);
var
  nPos, nJigNo: Integer;
  btData : Byte;
begin
  if Common.StatusInfo.AutoMode then Exit; //Auto일 경우 키 입력 무 - 실수로 인한 동작 방지

  if Length(sGetData) < 4 then Exit;
  nPos := Pos('3',sGetData);

  nJigNo := 0;
//  if ControlDio <> nil then begin
//    Case ControlDio.LoadZoneStage of
//      lzsA : begin
//        nJigNo := DefCommon.JIG_A;
//      end;
//      lzsB : begin
//        nJigNo := DefCommon.JIG_B;
//      end;
//    end;
//  end;
  if nJigNo <  DefCommon.JIG_A then Exit;
  btData := Byte(sGetData[nPos + 1]);
//  sDebug := format('Switch : 0x%0.2x',[btData]);
//  ShowSysLog(sDebug );
  case btData of
    $4E : begin   // Next
      ShowSysLog('Press Switch Key #9');
      if nGroup = DefCommon.CH_TOP then
        JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_9)
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_9);
    end;
    $42 : begin  // 1
      ShowSysLog('Press Switch Key #1');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_1)
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_1);
    end;
    $31 : begin  // 2
      ShowSysLog('Press Switch Key #2');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StopIspd_TOP
      else JigLogic[nJigNo].StopIspd_BOTTOM;
      //JigLogic[nJigNo].StartIspd_A(DefScript.SEQ_KEY_2);
    end;
    $45 : begin  // 3
      ShowSysLog('Press Switch Key #3');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_3)
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_3);
    end;
    //5
    $33 : begin //4
      ShowSysLog('Press Switch Key #4');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_4)
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_4);
    end;
    $36 : begin  // 5
      // back ---
      ShowSysLog('Press Switch Key #5');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_5)//NextIspd(False);
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_5);
    end;
    $35 : begin  // 6
      ShowSysLog('Press Switch Key #6');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_6)//StartIspd_A_Repeat;
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_6);
    end;
    $38 : begin  // 7
      ShowSysLog('Press Switch Key #7');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_7)//StopIspd_A;
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_7);
    end;
    $37 : begin  // 8
      ShowSysLog('Press Switch Key #8');
      if nGroup = DefCommon.CH_TOP then
      JigLogic[nJigNo].StartIspd_TOP(DefScript.SEQ_KEY_8)//.StartIspd_A_Auto;
      else JigLogic[nJigNo].StartIspd_BOTTOM(DefScript.SEQ_KEY_8);
    end;

  end;
  // 순서대로 버튼 눌렀을때 데이터.  NEXT ==> 상단
{
02 3F 33 4E 03 (02 3F 33 4E 03 )
02 3F 33 42 03 (02 3F 33 4E 03 )
02 3F 33 31 03 (02 3F 33 31 03 )
02 3F 33 45 03 (02 3F 33 33 03 )
02 3F 33 33 03 (02 3F 33 45 03 )
02 3F 33 36 03 (02 3F 33 35 03 )     //3
02 3F 33 35 03 (02 3F 33 36 03 )     //4
02 3F 33 38 03 (02 3F 33 37 03 )    //1
02 3F 33 37 03 (02 3F 33 38 03 )}   //2
end;

procedure TfrmMain_OC.btnShowAlarmClick(Sender: TObject);
begin
  tmDioAlarmTimer(Sender);
end;

procedure TfrmMain_OC.btnShowECSStatusClick(Sender: TObject);
begin
  frmEcsStatus := TfrmEcsStatus.Create(Self);
  frmEcsStatus.SetMode(1); //Status mode
  frmEcsStatus.ShowModal;
  frmEcsStatus.Free;
  frmEcsStatus:= nil;
end;

procedure TfrmMain_OC.btnShowNGRatioClick(Sender: TObject);
begin
  frmNGRatio:= TfrmNGRatio.Create(self);
  frmNGRatio.ShowModal;
  frmNGRatio.Free;
  frmNGRatio:= nil;
end;

procedure TfrmMain_OC.btnStartAutoTestClick(Sender: TObject);
begin
  if Common.StatusInfo.AutoMode then begin
    ShowMessage('Please make Manual mode');
    Exit;
  end;
  if ControlDio.Connected then begin
//    if ControlDio.ReadInSig(IN_TEACH_MODE_SEL_KEY) then begin
//      //Teach mode일 경우 자동 시작 안함
//      ShowSysLog('Teach Mode - Can not Start Auto Test Mode');
//      Exit;
//    end;
  end;

  Common.StatusInfo.Test_AutoRepeat := True;
  btnStartAutoTest.Enabled := False;
  btnStopAutoTest.Enabled := True;
  ShowSysLog('START Auto Repeat Test Mode');

  if ControlDio.Connected then begin
    //자동 모드 이므로 Door Open 불가능
    ControlDio.UnlockDoorOpen(DefDio.ALL_CH, False);
    ControlDio.Set_TowerLampState(LAMP_STATE_AUTO);
  end;

  case ControlDio.LoadZoneStage of
    lzsA : begin
      ShowSysLog('AutoLogicStart A');
      Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_LOADZONE;
      frmTest4ChOC[DefCommon.JIG_A].AutoLogicStart(JIG_A);
    end;
    lzsB : begin
      ShowSysLog('AutoLogicStart B');
      Common.StatusInfo.StageStep[JIG_B]:= STAGE_STEP_LOADZONE;
      frmTest4ChOC[DefCommon.JIG_B].AutoLogicStart(JIG_B);
    end
    else begin
      if ControlDio.Connected then begin
        ControlDio.Set_TowerLampState(LAMP_STATE_MANUAL);
      end;
      ShowSysLog('Turnning is not Complete - STOP Auto Mode', 1);
      Common.StatusInfo.Test_AutoRepeat := False;
      btnStartAutoTest.Enabled := True;
      btnStopAutoTest.Enabled := False;
      exit;
    end;
  end;
end;

procedure TfrmMain_OC.btnStopAutoTestClick(Sender: TObject);
begin
  Common.StatusInfo.Test_AutoRepeat := False;
  ShowSysLog('STOP Auto Repeat Test Mode');
  btnStartAutoTest.Enabled := True;
  btnStopAutoTest.Enabled := False;
end;

procedure TfrmMain_OC.Button1Click(Sender: TObject);
begin
  if DongaGmes is TGmes then begin
    DongaGmes.SendR2REodsTest;
  end
end;

procedure TfrmMain_OC.SaveCsvSummaryLog(nCh: Integer);
var
  sFilePath, sFileName : String;
  sLine: String;
  txtF                 : Textfile;
  i : integer;
begin
  sFilePath := Common.Path.SumCsv + FormatDateTime('yyyymm',now) + '\';
  sFileName := sFilePath + PasScr[nCh].m_sFileCsv;
  if Common.CheckDir(sFilePath) then Exit;
  try
    try
      AssignFile(txtF, sFileName);
      try

        if not FileExists(sFileName) then begin
          //Header 생성
          Rewrite(txtF);
          sLine:= PasScr[nCh].TestInfo.InsCsv.Data[0, 0];
          for i:= 1 to Pred(PasScr[nCh].TestInfo.InsCsv.FColCnt) do begin
            sLine:=  sLine + ',' + PasScr[nCh].TestInfo.InsCsv.Data[0, i];
          end;
          WriteLn(txtF, sLine);
        end;

        //Data
        Append(txtF);
        sLine:= PasScr[nCh].TestInfo.InsCsv.Data[1, 0];
        for i:= 1 to Pred(PasScr[nCh].TestInfo.InsCsv.FColCnt) do begin
          sLine:=  sLine + ',' + PasScr[nCh].TestInfo.InsCsv.Data[1, i];
        end;
        WriteLn(txtF, sLine);
      except
      end;
    finally
      CloseFile(txtF); // Close the file
    end;
  except

  end;
end;

procedure TfrmMain_OC.SendMsgAddLog(nMsgMode, nParam, nParam2: Integer; sMsg: String; pData: Pointer);
var
  cds         : TCopyDataStruct;
  COPYDATAMessage : RGuiDaeDio;
begin
  COPYDATAMessage.MsgType := MSG_TYPE_NONE;
  COPYDATAMessage.Channel := 0;
  COPYDATAMessage.Mode    := nMsgMode;
  COPYDATAMessage.Param   := nParam;
  COPYDATAMessage.Param2  := nParam2;
  COPYDATAMessage.Msg     := sMsg;
  COPYDATAMessage.pData   := pData;

  cds.dwData      := 0;
  cds.cbData      := SizeOf(COPYDATAMessage);
  cds.lpData      := @COPYDATAMessage;
  SendMessage(frmMain_OC.Handle ,WM_COPYDATA,0, LongInt(@cds));
end;

procedure TfrmMain_OC.SetEcsMesPosition;
begin
  lblMesReady.Font.Color :=  clYellow;// clBlack;
  pnlMesReady.Color       := $000050F7;//$00FF80FF;//clBtnFace;

  btnLogIn.Tag := 0;

  mmoSysLog.ScrollBars := ssVertical;
  mmoSysLog.StyleElements := [];
  if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
    mmoSysLog.Color := clBlack;
    mmoSysLog.Font.Color := clWhite;
  end
  else begin
    mmoSysLog.Font.Color := clBlack;
    mmoSysLog.Color := clWhite;
  end;

  pnlSubTitle.Left := pnlSysInfo.Left + pnlSysInfo.Width + 1;
  pnlSubTitle.Top  := frmTest4ChOC[DefCommon.JIG_A].Height * DefCommon.MAX_JIG_CNT + tolGroupMain.Top + tolGroupMain.Height + 2;
  pnlSubTitle.Height := 110 ;
  pnlSubTitle.Width  := Self.Width - (pnlSysInfo.Width + pnlSysInfo.Left) - 20 ;
  pnlSubTitle.Visible := True;
end;


procedure TfrmMain_OC.Set_AlarmData(nIndex, nValue, nType: Integer);
var
  i : Integer;
  bAlarm: Boolean;
begin
  if Common.StatusInfo.AlarmData[nIndex] = nValue then Exit;

  Common.StatusInfo.AlarmData[nIndex]:= nValue;

  if nType <> 0 then begin
    //Heavy Alarm
    if nValue <> 0 then begin
      ShowSysLog('[ALARM ON] ' + Common.StatusInfo.AlarmMsg[nIndex], 1);
//      Set_AutoMode(False); //매뉴얼 모드로 전환

      g_CommPLC.ECS_Alarm_Add(1, nIndex, 1); //알람 보고    // Added by KTS 2022-08-04 오후 4:30:33
      g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_DOWN, nIndex); //
      ControlDio.MelodyOn:= True;
      ControlDio.Set_TowerLampState(LAMP_STATE_ERROR);

      //Door Opend
      if nValue = 2 then begin


        if frmDoorOpenAlarmMsg = nil then begin
          frmDoorOpenAlarmMsg:= TfrmDoorOpenAlarmMsg.Create(self);
        end;
        ShowSysLog(Common.StatusInfo.AlarmMsg[nIndex], 1);
        frmDoorOpenAlarmMsg.Show; //ShowModal; //어차피 전체 창이므로 Modal일 필요 없다.
      end
      else begin
        tmDioAlarm.Interval := 10;
        tmDioAlarm.Enabled := True;
      end;
    end                 
    else begin
      //알람 없을 경우 해제
      ShowSysLog('[ALARM OFF] ' + Common.StatusInfo.AlarmMsg[nIndex], 3);
      if frmDisplayAlarm <> nil then begin
        frmDisplayAlarm.RefreshDisplay;
      end;

       g_CommPLC.ECS_Alarm_Add(1, nIndex, 0);  // Added by KTS 2022-08-04 오후 4:31:41

      bAlarm:= false;
      for i := 0 to 80 do begin
        if Common.StatusInfo.AlarmData[i] <> 0 then bAlarm:= True;
      end;

      if not bAlarm  then begin
        ControlDio.Set_TowerLampState(LAMP_STATE_MANUAL);
      end;
    end;
  end  //if nType <> 0 then begin
  else begin
    //Light Alarm
    if nValue <> 0 then begin
      ShowSysLog('[ALARM ON] ' + Common.StatusInfo.AlarmMsg[nIndex], 2);

        g_CommPLC.ECS_Alarm_Add(0, nIndex, 1); //알람 보고  // Added by KTS 2022-08-04 오후 4:34:53
      ShowNgMessage(Common.StatusInfo.AlarmMsg[nIndex]);
    end
    else begin
      ShowSysLog('[ALARM OFF] ' + Common.StatusInfo.AlarmMsg[nIndex], 3);

       g_CommPLC.ECS_Alarm_Add(0, nIndex, 0); //알람 해제 보고// Added by KTS 2022-08-04 오후 4:34:56
    end;
  end;
end;

procedure TfrmMain_OC.Set_AutoMode(bAuto: Boolean);
var
  nStage: Integer;
begin
  if g_CommPLC <> nil then begin
    if not g_CommPLC.Connected then begin
      ShowSysLog('PLC not Connected', 1);
      Exit;
    end;
    if not CheckPG_Connect(0) then begin
      ShowSysLog('Do not Auto Start - PG Disconnected');
      Exit;
    end;


    if bAuto then begin
      if Common.StatusInfo.AutoMode then Exit;
      g_CommPLC.IgnoreConnect:= False;

      //MC 검사 - DIO 상태 검사 필요
      if not CheckState_DIO then begin
        ShowSysLog('DIO CheckState NG', 1);
        Exit;
      end;

//      if not CheckVersionInterlock then begin
//        ShowSysLog('Version Interlock NG', 1);
//        //ShowNgMessage('Version Interlock NG');
//        Exit;
//      end;

//      nStage:= GetStageNo_LoadZone;
//      if nStage < JIG_A then begin
//        ShowSysLog('Stage Position NG - Turnning is not Complete', 1);
//        Exit;
//      end;

      Update_Stage_Position(0); //Stage 포지션 - ECS, CAM

      btnAutoReady.Caption := 'STOP AUTO MODE';
      lblPlcReady.Caption   := 'Robot Auto Mode (PLC)';
      pnlPlcReady.Color     := clGreen;//$00FFDFBF;
      lblPlcReady.Font.Color := clYellow; //clBlack;

      ShowSysLog('Auto Mode');
      Common.StatusInfo.AutoMode:= True;
      ControlDio.Set_TowerLampState(LAMP_STATE_AUTO);

      if ControlDio.Connected then begin
        //자동 모드 이므로 Door Open 불가능
        ControlDio.UnlockDoorOpen(DefDio.ALL_CH,False);
      end;

      //ECS Online
      Sleep(50);
      g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_ONLINE, 1);
//      g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_AUTO, 1);
//      g_CommPLC.ECS_Accessory_Unit_Status(0, 0, 0); //Stage A
//      g_CommPLC.ECS_Accessory_Unit_Status(1, 0, 0); //Stage B

      if g_CommPLC.IsBusy_Robot(0) and g_CommPLC.IsBusy_Robot(1)  then begin
        ShowSysLog('Do not Auto Start - Robot Busy');
        Exit;
      end;

      StartAutoProcess; //자동 모드 시작
    end
    else begin
      if not Common.StatusInfo.AutoMode then Exit;
      //tolGroupMain.Enabled:= True; //툴바 사용 가능
      Common.StatusInfo.Loading:= False;
      g_CommPLC.IgnoreConnect:= True;
      g_CommPLC.EQP_Clear_ROBOT_Request(0);
      g_CommPLC.EQP_Clear_ROBOT_Request(1);
      btnAutoReady.Caption := 'READY AUTO MODE';
      lblPlcReady.Caption   := 'Manual Mode';
      pnlPlcReady.Color     := clBlue;//$00FFDFBF;
      Common.StatusInfo.AutoMode:= False;
      ShowSysLog('Manual Mode');
      ControlDio.Set_TowerLampState(LAMP_STATE_MANUAL);
      g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_ONLINE, 0);
    end;
  end;
end;

procedure TfrmMain_OC.Set_Login(bLogin: Boolean);
begin
  if bLogin then  begin
    ShowSysLog('Set_Login - ON' );
  end
  else begin
    ShowSysLog('Set_Login - OFF' );
  end;

  if Common.SystemInfo.Use_ECS then begin
    if bLogin then begin
      Common.StatusInfo.LogIn:= True;
      btnLogIn.Caption := 'đăng xuất   (Log Out)';
      pnlMesReady.Color := clGreen;// $00FFFFE1;
      lblMesReady.Caption := 'ECS Report ON';
      ShowSysLog('ECS Report ON');
    end
    else begin
      Common.StatusInfo.LogIn:= False;
      btnLogIn.Caption := 'đăng nhập (Log In)';
      lblMesReady.Caption := 'ECS Report OFF';
      pnlMesReady.Color := $000050F7;
      btnLogIn.Tag := 0;
      ShowSysLog('ECS Report OFF');
    end;
  end;

  if Common.SystemInfo.Use_MES then begin
    if bLogin then begin
      Login_MES;
    end
    else begin
      Common.m_sUserId := 'PM';
      if DongaGmes <> nil then begin
        Login_MES;
      end;

      DisplayMes(False);
    end;
  end;
end;


procedure TfrmMain_OC.ShowNgAlarm(sNgMsg: string; bIsFrmClose: Boolean);
begin
  if not bIsFrmClose then begin
    if frmNgMsg <> nil then begin
      frmNgMsg.lblShow.Caption := sNgMsg;
    end
    else begin
      m_sNgMsg := sNgMsg;
      tmAlarmMsg.Interval := 100;
      tmAlarmMsg.Enabled := True;
    end;
  end
  else begin
    if frmNgMsg <> nil then begin
      frmNgMsg.Close;
    end
  end;
end;

procedure TfrmMain_OC.ShowNgMessage(sMessage: string);
begin
  if frmNgMsg = nil then begin
    frmNgMsg  := TfrmNgMsg.Create(nil);
  end;

  frmNgMsg.lblShow.Caption := sMessage;
  frmNgMsg.Show; //ShowModal;
end;


procedure TfrmMain_OC.ShowSysLog(sMsg: string; nType: Integer);
var
  sDebug : string;
begin
  if mmoSysLog.Lines.Count > 1000 then begin
    mmoSysLog.Clear;
  end;

  //mmoSysLog.DisableAlign;
  case nType of
    1: begin
      mmoSysLog.SelAttributes.Color := clRed;
      mmoSysLog.SelAttributes.Style := [fsBold];
    end;
    2: begin
      mmoSysLog.SelAttributes.Color := clMaroon; //clBlue;
      mmoSysLog.SelAttributes.Style := [fsBold];
    end;
    3: begin
      mmoSysLog.SelAttributes.Color := clBlue; //clGray;
      mmoSysLog.SelAttributes.Style := [fsBold];
    end;
    else begin
      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then
            mmoSysLog.SelAttributes.Color := clWhite
      else  mmoSysLog.SelAttributes.Color := clBlack;

      mmoSysLog.SelAttributes.Style := [];
    end;
  end;

  try
    sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, sMsg);

    mmoSysLog.Lines.Add(sDebug);
    //mmoSysLog.Perform(EM_SCROLL,SB_LINEDOWN,0);
    mmoSysLog.Perform(WM_VSCROLL, SB_BOTTOM, 0);
  except
    //유효하지 않은 문자열일 경우 오류(madException) 방지: RichEdit line insertion error.
    on E: Exception do  begin
      Sleep(10); //MLog 충돌 방지 딜레이
      Common.MLog(DefCommon.MAX_SYSTEM_LOG, 'MLog Exception:' + E.Message + #13#10 + sMsg);
    end;
  end;
  //mmoSysLog.EnableAlign;
end;

procedure TfrmMain_OC.StartAutoProcess;
var
  nRet: Integer;
  nStage, nAnother: Integer;
  i: Integer;
  frmSelectDetect: TfrmSelectDetect;
begin
//  g_CommPLC.EQP_Clear_ROBOT_Request(0);
//  g_CommPLC.EQP_Clear_ROBOT_Request(1);
  g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_IDLE, 0);
  Sleep(50);
  //UpdateECS_Glass_Position(0);
  for i := 0 to 1 do begin
    UpdateECS_Glass_Position_Pair(i, 0);  // Added by KTS 2023-03-23 오후 4:51:45
    Sleep(10);
//    UpdateECS_Glass_Position_Pair(i, 1);
  end;


//  if g_CommPLC.IsRequest_Robot then begin
//    //기존에 요청이 있으면 대기
//    ShowSysLog('StartAutoProcess: Exists Request');
//    Exit;
//  end;




  nStage:= GetStageNo_LoadZone;
  nAnother:= (nStage + 1) mod 2; //반대편 Stage

  if Common.StatusInfo.LastProduct then begin
    //기존 캐리어 있을 경우 시작
(*
    if not CheckDetect_Empty(nStage) then begin 

    end;

    if not CheckDetect_Empty(nAnother) then begin 

    end;
*)    
  end;

  case nStage of
    JIG_A : begin
      if ControlDio.IsDetected(CH_TOP) or ControlDio.IsDetected(CH_BOTTOM)  then
      begin
        frmSelectDetect:= TfrmSelectDetect.Create(nil);
        if Common.SystemInfo.UseNoExchange then begin
          frmSelectDetect.btnNo.Enabled:= False;
        end;
        nRet:= frmSelectDetect.ShowModal;
        frmSelectDetect.Free;

        if nRet = mrYes then begin
          ShowSysLog('StartAutoProcess Carrier Detected. Start A');

          if ControlDio.IsDetected(CH_TOP)then Execute_AutoStart(CH_TOP)
          else Robot_Request_LoadUnLoad(CH_TOP);
          if ControlDio.IsDetected(CH_BOTTOM)then Execute_AutoStart(CH_BOTTOM)
          else Robot_Request_LoadUnLoad(CH_BOTTOM);
        end
        else if nRet = mrNo then begin
          ShowSysLog('StartAutoProcess Carrier Detected. Request Exchange A');
          g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_RUN, 0);
          Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_LOADING;
          Robot_Request_LoadUnLoad(CH_TOP);
          Common.Delay(100);
          Robot_Request_LoadUnLoad(CH_BOTTOM);
        end
        else begin
          ShowSysLog('StartAutoProcess Carrier Detected. User Cancel');
          Set_AutoMode(False);
          Exit;
        end;
      end
      else begin
        //로드 요청
        ShowSysLog('StartAutoProcess Request Load A');


        if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
          Robot_Request_LoadUnLoad(CH_TOP);
          Common.Delay(100);
          Robot_Request_LoadUnLoad(CH_BOTTOM);
        end
        else begin
          Robot_Request_Exchange(CH_TOP);
          Common.Delay(100);
          Robot_Request_Exchange(CH_BOTTOM);
        end;
      end;
    end;
//    JIG_B : begin
//      if ControlDio.IsDetected(JIG_B) then
//      begin
//        frmSelectDetect:= TfrmSelectDetect.Create(nil);
//        if Common.SystemInfo.UseNoExchange then begin
//          frmSelectDetect.btnNo.Enabled:= False;
//        end;
//        nRet:= frmSelectDetect.ShowModal;
//        frmSelectDetect.Free;
//        if nRet = mrYes then begin
//          ShowSysLog('StartAutoProcess Carrier Detected. Start B');
//          Execute_AutoStart;
//        end
//        else if nRet = mrNo then begin
//          ShowSysLog('StartAutoProcess Carrier Detected. Request Exchange B');
//          g_CommPLC.ECS_Unit_Status(COMMPLC_UNIT_STATE_RUN, 0);
//          Common.StatusInfo.StageStep[JIG_A]:= STAGE_STEP_LOADING;
//          Robot_Request_Exchange(0);
//
//        end
//        else begin
//          ShowSysLog('StartAutoProcess Carrier Detected. User Cancel');
//          Set_AutoMode(False);
//          Exit;
//        end;
//      end
//      else begin
//        //Load 요청
//        ShowSysLog('StartAutoProcess Request Load B');
//        Robot_Request_Exchange(0);
//      end;
//    end;
    else begin
      //중간에 멈춘 경우 A Front 처리
      ShowSysLog('StartAutoProcess Turn Stage Continue');
//      ThreadTurnStage;
    end;
  end;
end;

procedure TfrmMain_OC.ThreadTask(Task: TProc);
begin
  TThread.CreateAnonymousThread(
    Task
  ).Start;
end;

procedure TfrmMain_OC.tmAlarmMsgTimer(Sender: TObject);
begin
  tmAlarmMsg.Enabled := False;
//  ShowNgMessage(m_sNgMsg);
end;

procedure TfrmMain_OC.tmDioAlarmTimer(Sender: TObject);
begin
  tmDioAlarm.Enabled := False;

  if Assigned(frmDisplayAlarm) = False then begin
    frmDisplayAlarm:= TfrmDisplayAlarm.Create(Self);
    //frmDisplayAlarm.SetAlarmData(ControlDio.DioAlarmData);
    frmDisplayAlarm.Show;
    //frmDisplayAlarm.ShowModal;
    //frmDisplayAlarm.Free;
    //frmDisplayAlarm:= nil;
  end
  else begin
    frmDisplayAlarm.RefreshDisplay;
  end;
end;

procedure TfrmMain_OC.tmNgMsgTimer(Sender: TObject);
begin
  tmNgMsg.Enabled := False;
  //ShowModelNgMsg(ControlDio.LastNgMsg);
end;

procedure TfrmMain_OC.tmrWatchTimer(Sender: TObject);
var
  nRet,i,nSignal: Integer;
  nStage: Integer;
begin
//  if tmrWatch.Tag = 0 then begin
//    //처음 한번 만 실행
//    tmrWatch.Enabled:= False; //Login 창 표출 시 문제 방지로 임시 정지
//    tmrWatch.Interval:= 1000;
//    tmrWatch.Enabled:= True;
//  end;


  //프로세스 검사
  //시작 시점 확인
  //디바이스 연결 확인
  tmrWatch.Tag:= tmrWatch.Tag + 1;

  //DIO가 연결 안되어 있으면 자동 처리 안됨
  if not ControlDio.Connected then begin
    if tmrWatch.Tag > 20 then begin  //10초 검사
      tmrWatch.Enabled:= False;
      self.Enabled:= True;
      //연결 안됨...Error

//      g_CommPLC.ECS_Alarm_Add(COMMPLC_ALARM_HEAVY, 999, 1);  // Added by KTS 2022-08-04 오후 4:35:02
      Set_AlarmData(ERR_LIST_DIO_CARD_DISCONNECTED, 1, 1);    // Added by KTS 2022-10-31 오후 4:06:06 0 -> 7 변경
    end;
    Exit;
  end;

  if tmrWatch.Tag < 2 then begin
    //준비 완료를 위해 잠시 대기 - 병목현상 방지
    Exit;
  end;

  //PG연결 확인해야 할까?
  g_CommPLC.EQP_Clear_ECS_Area; //ECS 보고 영역 지우기
  Sleep(10);
//  g_CommPLC.EQP_Clear_ROBOT_Request(0); //로봇 요청 부분 지우기
//  g_CommPLC.EQP_Clear_ROBOT_Request(1);

  if Common.SystemInfo.OCType = DefCommon.OCType  then
        nSignal := OUT_CH_1_2_ION_ONOFF_SOL
  else  nSignal := OUT_GIB_CH_12_ION_ONOFF_SOL;

  //Ionizer 동작 시작
  for I := 0 to pred(Defcommon.MAX_IONIZER_CNT) do begin
    if Common.SystemInfo.Com_Ionizer[i] > 0 then begin
      DaeIonizer[i].IsIgnoreNg := False;
      ControlDio.WriteDioSig(nSignal + i, False);
    end;

  end;

//  for I := 0 to pred(Defcommon.MAX_IONIZER_CNT) do begin
//    if  CaSdk2[i].CheckConnect then begin
//      if tmrWatch.Tag > 5 then begin  //5초 검사
//       tmrWatch.Enabled:= False;
//        self.Enabled:= True;
//      //연결 안됨...Error
//
//        Set_AlarmData(7, 1, 1);    // Added by KTS 2022-10-31 오후 4:06:06 0 -> 7 변경
//      end;
//      Exit;
//    end;
//
//  end;

  ShowSysLog('Prepare OK');
  tmrWatch.Enabled:= False;
  tmrWatch.Tag:= 0;
  self.Enabled:= True;

  if g_CommPLC <> nil then begin
    g_CommPLC.LoadGlassData(Common.Path.Ini + 'GlassData.dat'); //기존에 저장된 데이터를 로드 - Initialize나 종료 시 소실 방지
  end;

  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    PasScr[i].InitialScript;
  end;


  ThreadTask(procedure var i : Integer; begin
    for I := 0 to DefCommon.MAX_CH do begin
      if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
        ControlDio.ProbeBackward(i);
        ControlDio.UnlockCarrier(i,true);
      end
      else begin
        ControlDio.UnlockPinBlock(i);
        ControlDio.CLOSE_Up_PinBlock(i);
        ControlDio.MovingProbe(i div 2, True);
        ControlDio.MovingShutter(i div 2,true);
      end;
      Sleep(500);
    end;
  end);

//    common.MLog(DefCommon.MAX_SYSTEM_LOG,'Set_AutoMode Start');
//  if g_CommPLC <> nil then begin
//    if Common.SystemInfo.OCType = DefCommon.OCType then Set_AutoMode(true)
//    else Set_AutoMode(false);   // Added by KTS 2022-11-25 오전 9:36:24 프로그램 시작 시 자동 Auto 모드 설정
//  end;
//    common.MLog(DefCommon.MAX_SYSTEM_LOG,'Set_AutoMode end');
//  common.MLog(DefCommon.MAX_SYSTEM_LOG,'DaeIonizer tmrWatchTimer End');
  Set_Login(True);
  if Common.SystemInfo.Use_ECS then begin
    InitGmes;
  end;
end;


procedure TfrmMain_OC.tmSaveEnergyTimer(Sender: TObject);
var
  bValue : Bool;
  bScriptRun : Boolean;
  i : Integer;
begin
  bScriptRun := False;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if frmTest4ChOC[i] <> nil then begin
      if frmTest4ChOC[i].CheckScriptRun then begin
        bScriptRun := True;
        Break;
      end;
    end;
  end;

  if bScriptRun then begin
    if m_bSaveEnergy then Common.SetScreenSave(0);
    m_bSaveEnergy := False;
    Exit;
  end;
  if not m_bSaveEnergy then begin
    Common.SetScreenSave(Common.SystemInfo.SaveEnergy);

  end;
  m_bSaveEnergy := True;


//  if SystemParametersInfo(SPI_GETSCREENSAVERRUNNING, 0, @bValue, 0) then begin // 화면 보호기 동작 중 상태 수신 함수 / 동작 중 True, 아니면 0 반환
//     //DongaPOCB.SetPowerSaving(bValue);
//  end;
  SystemParametersInfo(SPI_GETSCREENSAVERRUNNING, 0, @bValue, 0);

  if bValue then begin
    // Lamp On.
    // Common.MLog(0,'Screen Saver On');
    if not m_bSaveEnergyChnage then begin
      // Ionizer Off.
      for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
        if Common.SystemInfo.Com_Ionizer[i] = 0 then Continue;
        if not ((Common.SystemInfo.IonizerCnt-1) < i) then begin
          if DaeIonizer[i] <> nil then DaeIonizer[i].SendMsg(',STP,1');
        end;
      end;
      // Lamp Off.
      if ControlDio <> nil then begin
        if common.SystemInfo.OCType = DefCommon.OCType then begin
            ControlDio.WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,False);
            ControlDio.WriteDioSig(DefDio.OUT_CH_1_2_BACK_DOOR_LAMPON,False);
        end
        else begin
            ControlDio.WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,False);
        end;
      end;
    end;
  end
  else begin
    // Lamp OFF.
    // Common.MLog(0,'Screen Saver Off');
    // Screen Saver 원복. ==> Lamp On,
    if m_bSaveEnergyChnage then begin
      // Ionizer On.
      for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
        if Common.SystemInfo.Com_Ionizer[i] = 0 then Continue;
        if not ((Common.SystemInfo.IonizerCnt-1) < i) then begin
          if DaeIonizer[i] <> nil then  DaeIonizer[i].SendMsg(',RUN,1');
        end;
      end;
      // Lamp On.
      if ControlDio <> nil then begin
        if common.SystemInfo.OCType = DefCommon.OCType then begin
            ControlDio.WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,True);
            ControlDio.WriteDioSig(DefDio.OUT_CH_1_2_BACK_DOOR_LAMPON,True);
        end
        else begin
            ControlDio.WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,True);
        end;
      end;
    end;
  end;
  m_bSaveEnergyChnage := bValue;

end;


procedure TfrmMain_OC.tmrDisplayTestFormTimer(Sender: TObject);
var
  i: Integer;
  sTarget, sSource : string;
  aTask : TThread;
  SEInfo: TShellExecuteInfo;
  ExitCode: DWORD;
  ExecuteFile, ParamString, StartInString: string;

  hwnd: THandle;
  DataStruct: CopyDataStruct;
  sFileName: string;
begin
  tmrDisplayTestForm.Enabled := False;

  if not Common.PLCInfo.Use_Simulation then begin
    //ActUTL Server 실행
    sFileName:= ExtractFilePath(Application.ExeName) + 'ActUtilTCPServer.exe';
    ShellExecute(Handle, 'open', PWideChar(sFileName), nil, nil, SW_SHOWNORMAL) ;
  end;

  Self.WindowState := wsMaximized;
//  if Common.SystemInfo.OcManualType then pnlSubTool.Height := 0;
  if Common.SystemInfo.UIType = DefCommon.UI_WIN10_NOR then begin
    Self.Color := clBtnFace;
  end
  else begin
    Self.Color := clBlack;
  end;
//  CreateClassData;
//  pnlMesReady.Width := pnlSubTool.Width - pnlPlcReady.Width - 20 ;
//  if not Common.SystemInfo.OcManualType then begin
//    Self.Height := Self.Height - 38;
//  end;
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    Common.StatusInfo.StageStep[i]:= STAGE_STEP_NONE;

    frmTest4ChOC[i] := TfrmTest4ChOC.Create(self);
    frmTest4ChOC[i].MessageHandle:= self.Handle;
    frmTest4ChOC[i].Tag := i;
    frmTest4ChOC[i].Height := (Self.Height) -38 {tolGroupMain.Top - tolGroupMain.Height} {- (frmSysEtc.Height div 2)} - 170 ;
    frmTest4ChOC[i].Width  := Self.Width - (pnlSysInfo.Width + pnlSysInfo.Left) - 20 ;
    frmTest4ChOC[i].Left   := 0;
    frmTest4ChOC[i].Top    := frmTest4ChOC[i].Height * i;
    frmTest4ChOC[i].Visible := True;
    frmTest4ChOC[i].ShowGui(Self.Handle);

    frmTest4ChOC[i].Caption := Format('%X Stage',[i+10]);
    if not Common.SystemInfo.UseAutoBCR then begin
      frmTest4ChOC[i].SetBcrData;
    end;
  end;
  // system Message window configuration.
//  frmSysEtc.Left := 0;
//  frmSysEtc.Top := frmTest4ChOC[DefCommon.JIG_A].Height * DefCommon.MAX_JIG_CNT;
//  frmSysEtc.Height := 110 ;
//  frmSysEtc.Width  := Self.Width - (pnlSysInfo.Width + pnlSysInfo.Left) - 20 ;
  for I := 0 to Pred(DefCommon.MAX_SWITCH_CNT) do begin
    DongaSwitch[i] := TSerialSwitch.Create(Self.Handle,i);
    DongaSwitch[i].OnRevSwData := DongaSwitchRevSwDataJig;
    DongaSwitch[i].ChangePort(Common.SystemInfo.Com_RCB[i]);
  end;
   SetEcsMesPosition;
  for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
    DaeIonizer[i] := TIonizer.Create(i,Self.Handle,frmTest4ChOC[DefCommon.JIG_A].Handle,DefCommon.MSG_TYPE_IONIZER);
    DaeIonizer[i].IsIgnoreNg := True;
    DaeIonizer[i].ChangePort(Common.SystemInfo.Com_Ionizer[i],Common.SystemInfo.Model_Ionizer[i]);
  end;
  for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
    if Common.SystemInfo.Com_Ionizer[i] = 0 then Continue;
    if not ((Common.SystemInfo.IonizerCnt-1) < i) then begin
      DaeIonizer[i].SendRun; // SendMsg(',RUN,1');
    end;
  end;
  // File Copy
  if Common.SystemInfo.AutoBackupUse then begin
    sTarget := Trim(Common.SystemInfo.AutoBackupList);
    if sTarget <> '' then begin
      sSource :=  ExtractFilePath(Application.ExeName);
      if DirectoryExists(sTarget) then begin
        aTask := TThread.CreateAnonymousThread(
          procedure begin
            SendMsgAddLog(MSG_MODE_ADDLOG, 0, 0, 'Execute Auto Backup '  + sSource + ' -> '  + sTarget);
            Common.CopyDirectoryAll(sSource,sTarget, False);
          end);
        aTask.FreeOnTerminate := True;
        aTask.Start;
      end;
    end;
  end;

  try
  ControlDio := TControlDio.Create(Self.Handle, DefCommon.MSG_TYPE_CTL_DIO);   // Added by KTS 2022-08-04 오후 4:04:53
  finally
  end;


//  Application.ProcessMessages;
//  Sleep(10);
//  Application.ProcessMessages;



//  if Common.SystemInfo.ServicePort <> '' then begin
//    btnLogInClick(nil);
//  end;
  Common.StatusInfo.AutoMode:= False;
  if Common.SystemInfo.OcManualType then begin
    g_CommPLC:= TCommPLCThread.Create(self.Handle, MSG_TYPE_COMM_ECS, 1,Common.PLCInfo.Use_Simulation);
    g_CommPLC.SetEQPID(Common.PLCInfo.EQP_ID);
    g_CommPLC.SetStartAddress( StrToInt('$' + Common.PLCInfo.Address_EQP),
                               StrToInt('$' + Common.PLCInfo.Address_ECS) + (Common.PLCInfo.EQP_ID div 19)* $10 , // Address_ECS EQP_ID Ekfk 가변
                               StrToInt('$' + Common.PLCInfo.Address_ROBOT),
                               StrToInt('$' + Common.PLCInfo.Address_ROBOT2),
                               StrToInt('$' + Common.PLCInfo.Address_EQP_W),
                               StrToInt('$' + Common.PLCInfo.Address_ECS_W),
                               StrToInt('$' + Common.PLCInfo.Address_ROBOT_W),
                               StrToInt('$' + Common.PLCInfo.Address_ROBOT_W2));
    g_CommPLC.PollingInterval:=  Common.PLCInfo.PollingInterval; // 500; //default
    g_CommPLC.ConnectionTimeout:= Common.PLCInfo.Timeout_Connection; //10000; //default
    g_CommPLC.ECS_Timeout:= Common.SystemInfo.ECS_Timeout;
    g_CommPLC.InlineGIB:= Common.PLCInfo.InlineGIB;
    g_CommPLC.MessageHandleTest1:= frmTest4ChOC[0].Handle;
//    g_CommPLC.MessageHandleTest2:= frmTest4ChOC[1].Handle;

    //g_CommPLC:= TCommPLCThread.Create(self.Handle, DefCommon.MSG_TYPE_COMM_ECS, 1, True);
    //g_CommPLC.SetEQPID(33);
    //g_CommPLC.SetStartAddress(0, $200, $100, 0, $200, $100 );
    //g_CommPLC.LogPath:= ExtractFilePath(Application.ExeName) + '\Log\CommPLC\'; //default
    g_CommPLC.Start;
//    if g_CommPLC <> nil then begin
//      btnAutoReadyClick(nil);
//    end;

    self.Enabled:= False;
    tmrWatch.Tag:= 0;
    tmrWatch.Interval:= 1000;
    tmrWatch.Enabled := True;
  end;

{$IFDEF DFS_HEX}
  InitDfs;
{$ENDIF}
  for i := DefCommon.PG_1 to DefCommon.PG_MAX do begin
    PG[i].tmConnCheck.Enabled  := true;
  end;

  // Screens Saver Setting.
  m_bSaveEnergy := False;
  m_bSaveEnergyChnage := False;
  Common.SetScreenSave(Common.SystemInfo.SaveEnergy);
  if Common.SystemInfo.SaveEnergy <> 0 then begin
    tmSaveEnergy.Interval := 1000;
    tmSaveEnergy.Enabled := True;
    m_bSaveEnergy := true;
  end
  else begin
    tmSaveEnergy.Enabled := False;
  end;


  //Self.WindowState := wsMaximized;
  //btnLogIn.Click;
  // IO Data 정상적으로 Display 되지 않는 오류 수정 Code.
  //if ControlDio <> nil then ControlDio.RefreshIo;

//  ExecuteFile:= Common.Path.RootSW + 'c#\Test_UI_For_X2146.exe'; // 실행하려는 프로그램의 경로 및 파일명 지정
//
//  ShellExecute(Handle, 'open', PChar(ExecuteFile), nil, nil, SW_SHOWMINIMIZED);
//
//  hwnd := FindWindow('Form1', nil);
//
//  if hwnd <> 0 then
//  begin
//    DataStruct.dwData := 0;
//    DataStruct.cbData := length('TEST') + 1;
//    DataStruct.lpData := PChar('TEST');
//    SetForegroundWindow(hwnd);
//    SendMessage(hwnd, wm_CopyData,0, Integer (@DataStruct));
//  end;


end;

procedure TfrmMain_OC.tmrMemCheckTimer(Sender: TObject);
var
  sCmd : string;
begin
  sCmd := FormatFloat('#,',Common.ProcessMemory);
  pnlMemCheck.Caption := 'MEMORY CHECK : '+sCmd + ' Bytes';
end;


procedure TfrmMain_OC.WMCopyData_PG(var CopyMsg: TMessage);
var
  i, nType, nMode, nCh, nTemp : Integer;
  sMsg, sTemp : string;
  {$IFDEF PG_DP860}
	bPgVerAllNG, bPgVerHwNG, bPgVerFwNG, bPgVerSubFwNG, bPgVerFpgaNG, bPgVerPwrNG : Boolean;
	{$ENDIF}
begin
  nType := DefCommon.MSG_TYPE_PG;
  nCh   := PGuiPg2Main(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.PgNo;
  nMode := PGuiPg2Main(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.Mode;
  case nMode of
    DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
      nTemp := PGuiPg2Main(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.Param;
      sMsg  := PGuiPg2Main(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.sMsg;
      case nTemp of
        DefCommon.PG_CONN_DISCONNECTED : begin


        end;
        DefCommon.PG_CONN_CONNECTED : begin

        end;
        DefCommon.PG_CONN_VERSION : begin
          case Common.SystemInfo.PG_TYPE of
            {$IFDEF PG_AF9}
            DefPG.PG_TYPE_AF9 : begin
              if (Pg[nCh].m_PgVer.AF9VerMCS < Common.TestModelInfoPG.PgVer.AF9VerMCS) or (Pg[nCh].m_PgVer.AF9VerAPI < Common.TestModelInfoPG.PgVer.AF9VerAPI) then begin
    						sTemp := '';
                if (Pg[nCh].m_PgVer.AF9VerMCS < Common.TestModelInfoPG.PgVer.AF9VerMCS) then begin
      						sTemp := sTemp + 'AF9-MCS Version mismatched !!' + #13#10;
                  sTemp := sTemp + Format('    MCS[R%d], Model[R%d]',[Pg[nCh].m_PgVer.AF9VerMCS, Common.TestModelInfoPG.PgVer.AF9VerMCS]);
                end;
  	            if sTemp <> '' then sTemp := sTemp + #13#10;
                if (Pg[nCh].m_PgVer.AF9VerAPI < Common.TestModelInfoPG.PgVer.AF9VerAPI) then begin
    							sTemp := sTemp + 'AF9-API Version mismatched !!' + #13#10;
                  sTemp := sTemp + Format('    DLL[R%d], Model[R%d]',[Pg[nCh].m_PgVer.AF9VerAPI, Common.TestModelInfoPG.PgVer.AF9VerAPI]);
                end;
                ShowNgMessage(sTemp);
              end;
            end;
            {$ENDIF}
            {$IFDEF PG_DP860}
            DefPG.PG_TYPE_DP860 : begin
              bPgVerAllNG   := False;
              if Common.TestModelInfoPG.PgVer.VerAll <> '' then bPgVerAllNG  := (CompareText(Pg[nCh].m_PgVer.VerAll, Common.TestModelInfoPG.PgVer.VerAll) < 0);
              bPgVerHwNG    := False;
              if Common.TestModelInfoPG.PgVer.HW    <> '' then bPgVerHwNG    := (CompareText(Pg[nCh].m_PgVer.HW,   Common.TestModelInfoPG.PgVer.HW)    < 0);
              bPgVerFwNG    := False;
              if Common.TestModelInfoPG.PgVer.FW    <> '' then bPgVerFwNG    := (CompareText(Pg[nCh].m_PgVer.FW,   Common.TestModelInfoPG.PgVer.FW)    < 0);
              bPgVerSubFwNG := False;
              if Common.TestModelInfoPG.PgVer.SubFW <> '' then bPgVerSubFwNG := (CompareText(Pg[nCh].m_PgVer.SubFW,Common.TestModelInfoPG.PgVer.SubFW) < 0);
              bPgVerFpgaNG  := False;
              if Common.TestModelInfoPG.PgVer.FPGA  <> '' then bPgVerFpgaNG  := (CompareText(Pg[nCh].m_PgVer.FPGA, Common.TestModelInfoPG.PgVer.FPGA)  < 0);
              bPgVerPwrNG   := False;
              if Common.TestModelInfoPG.PgVer.PWR   <> '' then bPgVerPwrNG   := (CompareText(Pg[nCh].m_PgVer.PWR,  Common.TestModelInfoPG.PgVer.PWR)   < 0);
              //
              if bPgVerAllNG or bPgVerHwNG or bPgVerFwNG or bPgVerSubFwNG or bPgVerFpgaNG or bPgVerPwrNG then begin
                sTemp := '';
                if bPgVerAllNG   then sTemp := sTemp + Format('    PG-ALL[%s], Model-ALL[%s]',    [PG[nCh].m_PgVer.VerAll,Common.TestModelInfoPG.PgVer.VerAll]) + #13#10;;
                if bPgVerHwNG    then sTemp := sTemp + Format('    PG-HW[%s], Model-HW[%s]',      [PG[nCh].m_PgVer.HW,    Common.TestModelInfoPG.PgVer.HW]) + #13#10;;
                if bPgVerFwNG    then sTemp := sTemp + Format('    PG-FW[%s], Model-FW[%s]',      [PG[nCh].m_PgVer.FW,    Common.TestModelInfoPG.PgVer.FW]) + #13#10;;
                if bPgVerSubFwNG then sTemp := sTemp + Format('    PG-SubFW[%s], Model-SubFW[%s]',[PG[nCh].m_PgVer.SubFw, Common.TestModelInfoPG.PgVer.SubFW]) + #13#10;;
                if bPgVerFpgaNG  then sTemp := sTemp + Format('    PG-FPGA[%s], Model-FPGA[%s]',  [PG[nCh].m_PgVer.FPGA,  Common.TestModelInfoPG.PgVer.FPGA]) + #13#10;;
                if bPgVerPwrNG   then sTemp := sTemp + Format('    PG-POWER[%s], Model-POWER[%s]',[PG[nCh].m_PgVer.PWR,   Common.TestModelInfoPG.PgVer.PWR]) + #13#10;;
  							sTemp := 'PG Version Mismatched !!' + #13#10 + sTemp;
                ShowNgMessage(sTemp);
              end;
              //
//              DownloadModel;
            end;
            {$ENDIF}
          end; //PG_CONN_VERSION
        end;
        DefCommon.PG_CONN_READY : begin

        end;
      end;
    end;
    else begin
      //TBD?
    end;
  end;
end;



procedure TfrmMain_OC.WMSyscommandBroadcast(var Msg: TMessage);

var

  SSStr: String;

begin

  if (Msg.wParam and $FFF0) = SC_SCREENSAVE then // 화면 보호기 시작

  begin

    with TRegistry.Create do

    begin

      RootKey := HKEY_CURRENT_USER;

      OpenKey('Control Panel\Desktop',False);

      SSStr := ReadString('SCRNSAVE.EXE'); // Windows NT 기반

      Free;

    end;

    if not FileExists(SSStr) then

    begin

      with TIniFile.Create('system.ini') do

      begin

        SSStr := ReadString('boot','SCRNSAVE.EXE',''); // Windows 98

        Free;

      end;

    end;



    // 사용자가 윈도우즈에서 화면 보호기를 껐다

    // Windows2000은 화면보호기를 사용자가 꺼도 이벤트가 발생하므로 프로그램에서도 화면보호기를 꺼야함

    if FileExists(SSStr) then
      ShowSysLog('SC_SCREENSAVE: 화면 꺼짐')
//      Memo1.Lines.Add('SC_SCREENSAVE: 화면 꺼짐')

    else

      SystemParametersInfo(SPI_SETSCREENSAVEACTIVE, ord(FALSE), nil, SPIF_SENDCHANGE); // 화면보호기 OFF


    Msg.Result := Integer(True);

  end

  else if ((Msg.wParam and $FFF0) = SC_MONITORPOWER) and (Msg.lParam = 2) then // 모니터 꺼짐 (2=turn off the monitor)

  begin
    ShowSysLog('SC_MONITORPOWER: 화면 꺼짐');
//    Memo1.Lines.Add('SC_MONITORPOWER: 화면 꺼짐');

    Msg.Result := Integer(False);

  end;


  inherited;

end;


procedure TfrmMain_OC.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, nTemp : Integer;
  sMsg,sSubMsg : string;
  pGUIMsg: PGUIMessage;
begin
  nType := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
  pGUIMsg:= PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData);



  case nType of
    DefCommon.MSG_TYPE_PG      : WMCopyData_PG(Msg); //= MSG_TYPE_AF9FPGA
    DefCommon.MSG_TYPE_STAGE : begin
      ProcessMsg_STAGE(pGUIMsg);
    end; //DefCommon.MSG_TYPE_STAGE : begin

    DefCommon.MSG_TYPE_CTL_DIO : begin
      ProcessMsg_COMM_DIO(pGUIMsg);
    end; //DefCommon.MSG_TYPE_CTL_DIO : begin

    DefCommon.MSG_TYPE_COMM_ECS : begin
      //PLC ECS 메시지 처리
      ProcessMsg_COMM_ECS(pGUIMsg);
    end; //DefCommon.MSG_TYPE_COMM_ECS : begin

    DefCommon.MSG_TYPE_SCRIPT : begin
      ProcessMsg_SCRIPT(pGUIMsg);
    end; //DefCommon.MSG_TYPE_SCRIPT : begin


    DefCommon.MSG_TYPE_NONE : begin  //공용 메시지 - 지정되지 않음
      case pGUIMsg.Mode of
        MSG_MODE_ADDLOG: begin
          //단순 System Log 추가
          ShowSysLog(pGUIMsg.Msg, pGUIMsg.Param);
        end;
        MSG_MODE_ADDLOG_CHANNEL: begin
          //test에 각 채널에 로그 추가
          frmTest4ChOC[pGUIMsg.Param].AddLog(pGUIMsg.Msg, pGUIMsg.Param2);
        end;

        MSG_MODE_RESET_ALARM: begin

        end;
      end;

    end; //DefCommon.MSG_TYPE_ADDLOG : begin


    DefCommon.MSG_TYPE_SWITCH : begin

      nMode := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp  := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
        nCh := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
        if nCh = 0 then  begin
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

        end
        else begin
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

    DefCommon.MSG_TYPE_CA410 : begin
{$IFDEF CA410_USE}
      nMode := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgMode;
      nTemp := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      // nCh은 해당 Jig로 사용.
      case nMode of
        DefCommon.MSG_MODE_WORKING : begin
            Set_AlarmData(nTemp, 1, 1); //중 알람

        end;
        DefCommon.MSG_MODE_CA310_STATUS : begin
          // nTemp = 0 이면 해당 Channel 사용하지 않음. 아니면 사용.
          if nTemp = 0 then begin
            case nCh of
              DefCommon.CH1 : begin
                ledCam1.FalseColor := clGray;
                ledCam1.Value := False;
              end;
              DefCommon.CH2 : begin
                ledCam2.FalseColor := clGray;
                ledCam2.Value := False;
              end;
              DefCommon.CH3 : begin
                ledCam3.FalseColor := clGray;
                ledCam3.Value := False;
              end;
              DefCommon.CH4 : begin
                ledCam4.FalseColor := clGray;
                ledCam4.Value := False;

              end;

            end;
          end
          else begin
            nTemp := Common.SystemInfo.Com_Ca310_DevieId[nCh];
            sSubMsg := Format('USB ID (COMM%d)',[nTemp]);
            sMsg  := 'CA410 ERROR : '+ PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
            case nCh of
              DefCommon.CH1 : begin
                ledCam1.FalseColor := clRed;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam1.Value := False;

                  ShowSysLog(sMsg, 1);

                end
                else begin
                  ledCam1.Value := True;
                end;
              end;
              DefCommon.CH2 : begin
                ledCam2.FalseColor := clRed;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam2.Value := False;

                  ShowSysLog(sMsg, 1);

                end
                else begin
                  ledCam2.Value := True;
                end;
              end;
              DefCommon.CH3 : begin
                ledCam3.FalseColor := clRed;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam3.Value := False;

                  ShowSysLog(sMsg, 1);

                end
                else begin
                  ledCam3.Value := True;
                end;
              end;
              DefCommon.CH4 : begin
                ledCam4.FalseColor := clRed;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam4.Value := False;
                  ShowSysLog(sMsg, 1);

                end
                else begin
                  ledCam4.Value := True;
                end;
              end;

            end;
          end;
        end;

        DefCommon.MSG_MODE_CA310_NG : begin
          if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
            Common.MLog(DefCommon.MAX_SYSTEM_LOG,PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          end;
        end;
      end;
{$ENDIF}
    end;

    DefCommon.MSG_TYPE_CAMERA : begin
      nMode := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgMode;
      nTemp := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      // nCh은 해당 Jig로 사용.
      case nMode of
        DefCommon.MSG_MODE_CA310_STATUS : begin
          // nTemp = 0 이면 해당 Channel 사용하지 않음. 아니면 사용.
          if nTemp = 0 then begin
            case nCh of
              DefCommon.CH1 : begin
                ledCam1.FalseColor := clGray;
                ledCam1.Value := False;
              end;
              DefCommon.CH2 : begin
                ledCam2.FalseColor := clGray;
                ledCam2.Value := False;
              end;
              DefCommon.CH3 : begin
                ledCam3.FalseColor := clGray;
                ledCam3.Value := False;
              end;
              DefCommon.CH4 : begin
                ledCam4.FalseColor := clGray;
                ledCam4.Value := False;
              end;
            end;
          end
          else begin
            nTemp := Common.SystemInfo.Com_Ca310_DevieId[nCh];
            sSubMsg := Format('USB ID (COMM%d)',[nTemp]);
            sMsg  := 'CA410 ERROR : '+ PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
            case nCh of
              DefCommon.CH1 : begin
                ledCam1.FalseColor := clRed;
//                pnlCa310Com1.Caption := sSubMsg;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam1.Value := False;
                  ShowNgMessage(sMsg);
                end
                else begin
                  ledCam1.Value := True;
                end;
              end;
              DefCommon.CH3 : begin
                ledCam3.FalseColor := clRed;
//                pnlCa310Com1.Caption := sSubMsg;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam3.Value := False;
                  ShowNgMessage(sMsg);
                end
                else begin
                  ledCam3.Value := True;
                end;
              end;
              DefCommon.CH2 : begin
                ledCam2.FalseColor := clRed;
//                pnlCa310Com1.Caption := sSubMsg;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam2.Value := False;
                  ShowNgMessage(sMsg);
                end
                else begin
                  ledCam2.Value := True;
                end;
              end;
              DefCommon.CH4 : begin
                ledCam4.FalseColor := clRed;
//                pnlCa310Com1.Caption := sSubMsg;
                if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
                  ledCam4.Value := False;
                  ShowNgMessage(sMsg);
                end
                else begin
                  ledCam4.Value := True;
                end;
              end;
            end;
          end;

        end;
        DefCommon.MSG_MODE_CA310_NG : begin
          if PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError then begin
            Common.MLog(DefCommon.MAX_SYSTEM_LOG,PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          end;
        end;
      end;

    end;
    DefCommon.MSG_TYPE_IONIZER : begin
      nMode := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp  := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      case nMode of
        CommIonizer.MSG_MODE_IONIZER_CONNECTION : begin
          nCh := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
          case nCh of
            0: begin
            pnlIonizer.Caption := sMsg;
              case nTemp of
                0 : begin
                  ledIonizer.FalseColor := clRed;
                  ledIonizer.Value := False;
                end;
                1 : begin
                  ledIonizer.Value := True;
                end;
                2 : begin
                  ledIonizer.FalseColor := clGray;
                  ledIonizer.Value := False;
                end;
              end;

            end;

            1: begin
            pnlIonizer2.Caption := sMsg;
              case nTemp of
                0 : begin
                  ledIonizer2.FalseColor := clRed;
                  ledIonizer2.Value := False;
                end;
                1 : begin
                  ledIonizer2.Value := True;
                end;
                2 : begin
                  ledIonizer2.FalseColor := clGray;
                  ledIonizer2.Value := False;
                end;
              end;
            end;

          end;

        end;
        CommIonizer.MSG_MODE_IONIZER_ERR_MSG : begin
          nCh := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
          case nCh of
            0: begin
              pnlIonizer.Caption := sMsg;
              if ledIonizer.Value then begin
                ledIonizer.Value:= False;
                ShowSysLog('Ionizer Status NG: ' + sMsg, 2);
              end;
            end;
            1: begin
              pnlIonizer2.Caption := sMsg;
              if ledIonizer2.Value then begin
                ledIonizer2.Value:= False;
                ShowSysLog('Ionizer Status NG: ' + sMsg, 2);
              end;

            end;

          end;


        end;
        CommIonizer.MSG_MODE_IONIZER_LOG : begin
//          ShowSysLog(sMsg);
          if frmMainter <> nil then begin
            frmMainter.IonizerReadData(true,sMsg);
          end
          else begin
//            ShowSysLog(sMsg);
          end;
        end;

      end;


      {sMsg  := string(PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp  := PGuiSwitch(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
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
          end;}
    end;




    DefCommon.MSG_TYPE_EXT_CONTROL: begin
      nMode := pGUIMsg.Mode;
      sMsg  := pGUIMsg.Msg;
      case nMode of
        1: begin //Initialize
          ShowSysLog(Format('Program Initialize from External : %s ',[sMsg]));
        end;

        2 :  begin //Teminate Program
          ShowSysLog(Format('Program Terminate from External : %s ',[sMsg]));
        end;
      end;
    end;
  end;
end;

procedure TfrmMain_OC.WMPostMessage(var Msg: TMessage);
begin
  case Msg.WParam of //보낸주체 종류
    COMMDIO_MSG_CONNECT: begin
      if Msg.LParam <> 0 then begin
        pnlDioStatus.Caption := 'Connected'; // + IntToHex(CommDaeDIO.DeviceInfo.Version[0]); // + PGuiDaeDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
        ledDio.Value := True;
//        ShowSysLog('DIO Connected');
      end
      else begin
        pnlDioStatus.Caption := 'Disconnected'; // + PGuiDaeDio(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
        ledDio.Value := False;
        ShowSysLog('DIO Disconnected', 1);
      end;
    end;

    COMMDIO_MSG_CHANGE_DI: begin
      Display_Memory_DI;
    end;

    COMMDIO_MSG_CHANGE_DO: begin
      Display_Memory_DO;
    end;

  end;
end;

procedure TfrmMain_OC.Init_AlarmMessage;
begin
  FillChar(Common.StatusInfo.AlarmData[0], Common.StatusInfo.AlarmData[0]*150, 0);

  if Common.SystemInfo.OCType = DefCommon.OCType  then begin
    Common.StatusInfo.AlarmMsg[0]:= 'FAN_1_EXHAUST ERROR (DI00)';
    Common.StatusInfo.AlarmMsg[1]:= 'FAN_2_INTAKE ERROR (DI01)';
    Common.StatusInfo.AlarmMsg[2]:= 'FAN_3_EXHAUSTR ERROR (DI02)';
    Common.StatusInfo.AlarmMsg[3]:= 'FAN_4_INTAKE ERROR (DI03)';
    Common.StatusInfo.AlarmMsg[4]:= 'N/A 04';
    Common.StatusInfo.AlarmMsg[5]:= 'N/A 05';
    Common.StatusInfo.AlarmMsg[6]:= 'N/A 06';
    Common.StatusInfo.AlarmMsg[7]:= 'N/A 07';

    Common.StatusInfo.AlarmMsg[8]:= 'EMO_SWITCH (DI08)';
    Common.StatusInfo.AlarmMsg[9]:= 'CH 1,2 LEFT DOOR OPEN (DI09)';
    Common.StatusInfo.AlarmMsg[10]:= 'CH 1,2 RIGHT DOOR OPEN (DI10)';
    Common.StatusInfo.AlarmMsg[11]:= 'CH 3,4 LEFT DOOR OPEN (DI11)';
    Common.StatusInfo.AlarmMsg[12]:= 'CH 3,4 RIGHT DOOR OPEN (DI12)';
    Common.StatusInfo.AlarmMsg[13]:= 'MC MONITORING - NEED RESET BUTTON (DI13)';
    Common.StatusInfo.AlarmMsg[14]:= 'N/A 14';
    Common.StatusInfo.AlarmMsg[15]:= 'N/A 15';

    Common.StatusInfo.AlarmMsg[16]:= 'TEMPERATURE ALARM (DI16)';
    Common.StatusInfo.AlarmMsg[17]:= 'N/A 17';
    Common.StatusInfo.AlarmMsg[18]:= 'N/A 18';
    Common.StatusInfo.AlarmMsg[19]:= 'N/A 19';
    Common.StatusInfo.AlarmMsg[20]:= 'N/A 20';
    Common.StatusInfo.AlarmMsg[21]:= 'N/A 21';
    Common.StatusInfo.AlarmMsg[22]:= 'N/A 22';
    Common.StatusInfo.AlarmMsg[23]:= 'N/A 23';

    Common.StatusInfo.AlarmMsg[24]:= 'MAIN AIR Pressure ERROR (DI24)';
    Common.StatusInfo.AlarmMsg[25]:= 'N/A 25';
    Common.StatusInfo.AlarmMsg[26]:= 'N/A 26';
    Common.StatusInfo.AlarmMsg[27]:= 'N/A 27';
    Common.StatusInfo.AlarmMsg[28]:= 'N/A 28';
    Common.StatusInfo.AlarmMsg[29]:= 'N/A 29';
    Common.StatusInfo.AlarmMsg[30]:= 'N/A 30';
    Common.StatusInfo.AlarmMsg[31]:= 'N/A 31';

    Common.StatusInfo.AlarmMsg[32]:= 'CARRIER_SENSOR NG CH #1 (DI32)';
    Common.StatusInfo.AlarmMsg[33]:= 'PROBE_FORWARD_SENSOR NG  CH #1 (DI33)';
    Common.StatusInfo.AlarmMsg[34]:= 'PROBE_BACKWARD_SENSOR NG  CH #1 (DI34)';
    Common.StatusInfo.AlarmMsg[35]:= 'PROBE_UP_SENSOR NG CH #1 (DI35)';
    Common.StatusInfo.AlarmMsg[36]:= 'PROBE_DOWN_SENSOR NG CH #1 (DI36)';
    Common.StatusInfo.AlarmMsg[37]:= 'N/A 37';
    Common.StatusInfo.AlarmMsg[38]:= 'N/A 38';
    Common.StatusInfo.AlarmMsg[39]:= 'N/A 39';

    Common.StatusInfo.AlarmMsg[40]:= 'CH 1 CARRIER Clamp UP SENSOR #1 (DI40)';
    Common.StatusInfo.AlarmMsg[41]:= 'CH 1 CARRIER Clamp DN SENSOR #1 (DI41)';
    Common.StatusInfo.AlarmMsg[42]:= 'CH 1 CARRIER Clamp UP SENSOR #2 (DI42)';
    Common.StatusInfo.AlarmMsg[43]:= 'CH 1 CARRIER Clamp DN SENSOR #2 (DI43)';
    Common.StatusInfo.AlarmMsg[44]:= 'CH 1 CARRIER Clamp UP SENSOR #3 (DI44)';
    Common.StatusInfo.AlarmMsg[45]:= 'CH 1 CARRIER Clamp DN SENSOR #3 (DI45)';
    Common.StatusInfo.AlarmMsg[46]:= 'CH 1 CARRIER Clamp UP SENSOR #4 (DI46)';
    Common.StatusInfo.AlarmMsg[47]:= 'CH 1 CARRIER Clamp DN SENSOR #4 (DI47)';

    Common.StatusInfo.AlarmMsg[48]:= 'CARRIER_SENSOR NG CH #2 (DI48)';
    Common.StatusInfo.AlarmMsg[49]:= 'PROBE_FORWARD_SENSOR NG  CH #2 (DI49)';
    Common.StatusInfo.AlarmMsg[50]:= 'PROBE_BACKWARD_SENSOR NG  CH #2 (DI50)';
    Common.StatusInfo.AlarmMsg[51]:= 'PROBE_UP_SENSOR NG CH #2 (DI51)';
    Common.StatusInfo.AlarmMsg[52]:= 'PROBE_DOWN_SENSOR NG CH #2 (DI52)';
    Common.StatusInfo.AlarmMsg[53]:= 'N/A 61';
    Common.StatusInfo.AlarmMsg[54]:= 'N/A 62';
    Common.StatusInfo.AlarmMsg[55]:= 'N/A 63';

    Common.StatusInfo.AlarmMsg[56]:= 'CH 2 CARRIER Clamp UP SENSOR #1(DI56)';
    Common.StatusInfo.AlarmMsg[57]:= 'CH 2 CARRIER Clamp DN SENSOR #1(DI57)';
    Common.StatusInfo.AlarmMsg[58]:= 'CH 2 CARRIER Clamp UP SENSOR #2(DI58)';
    Common.StatusInfo.AlarmMsg[59]:= 'CH 2 CARRIER Clamp DN SENSOR #2(DI59)';
    Common.StatusInfo.AlarmMsg[60]:= 'CH 2 CARRIER Clamp UP SENSOR #3(DI60)';
    Common.StatusInfo.AlarmMsg[61]:= 'CH 2 CARRIER Clamp DN SENSOR #3(DI61)';
    Common.StatusInfo.AlarmMsg[62]:= 'CH 2 CARRIER Clamp UP SENSOR #4(DI62)';
    Common.StatusInfo.AlarmMsg[63]:= 'CH 2 CARRIER Clamp DN SENSOR #4(DI63)';

    Common.StatusInfo.AlarmMsg[64]:=  'CARRIER_SENSOR NG CH #3 (DI64)';
    Common.StatusInfo.AlarmMsg[65]:=  'PROBE_FORWARD_SENSOR NG  CH #3 (DI65)';
    Common.StatusInfo.AlarmMsg[66]:=  'PROBE_BACKWARD_SENSOR NG  CH #3 (DI66)';
    Common.StatusInfo.AlarmMsg[67]:=  'PROBE_UP_SENSOR NG CH #3 (DI67)';
    Common.StatusInfo.AlarmMsg[68]:=  'PROBE_DOWN_SENSOR NG CH #3 (DI68)';
    Common.StatusInfo.AlarmMsg[69]:=  'N/A 85';
    Common.StatusInfo.AlarmMsg[70]:=  'N/A 86';
    Common.StatusInfo.AlarmMsg[71]:=  'N/A 87';

    Common.StatusInfo.AlarmMsg[72]:= 'CH 3 CARRIER Clamp UP SENSOR #1(DI72)';
    Common.StatusInfo.AlarmMsg[73]:= 'CH 3 CARRIER Clamp DN SENSOR #1(DI73)';
    Common.StatusInfo.AlarmMsg[74]:= 'CH 3 CARRIER Clamp UP SENSOR #2(DI74)';
    Common.StatusInfo.AlarmMsg[75]:= 'CH 3 CARRIER Clamp DN SENSOR #2(DI75)';
    Common.StatusInfo.AlarmMsg[76]:= 'CH 3 CARRIER Clamp UP SENSOR #3(DI76)';
    Common.StatusInfo.AlarmMsg[77]:= 'CH 3 CARRIER Clamp DN SENSOR #3(DI77)';
    Common.StatusInfo.AlarmMsg[78]:= 'CH 3 CARRIER Clamp UP SENSOR #4(DI78)';
    Common.StatusInfo.AlarmMsg[79]:= 'CH 3 CARRIER Clamp DN SENSOR #4(DI79)';

    Common.StatusInfo.AlarmMsg[80]:= 'CARRIER_SENSOR NG CH #4 (DI80)';
    Common.StatusInfo.AlarmMsg[81]:= 'PROBE_FORWARD_SENSOR NG  CH #4 (DI81)';
    Common.StatusInfo.AlarmMsg[82]:= 'PROBE_BACKWARD_SENSOR NG  CH #4 (DI82)';
    Common.StatusInfo.AlarmMsg[83]:= 'PROBE_UP_SENSOR NG CH #4 (DI83)';
    Common.StatusInfo.AlarmMsg[84]:= 'PROBE_DOWN_SENSOR NG CH #4 (DI84)';
    Common.StatusInfo.AlarmMsg[85]:= 'N/A 109';
    Common.StatusInfo.AlarmMsg[86]:= 'N/A 110';
    Common.StatusInfo.AlarmMsg[87]:= 'N/A 111';

    Common.StatusInfo.AlarmMsg[88]:=   'CH 4 CARRIER Clamp UP SENSOR #1(DI88)';
    Common.StatusInfo.AlarmMsg[89]:=   'CH 4 CARRIER Clamp DN SENSOR #1(DI89)';
    Common.StatusInfo.AlarmMsg[90]:=   'CH 4 CARRIER Clamp UP SENSOR #2(DI90)';
    Common.StatusInfo.AlarmMsg[91]:=   'CH 4 CARRIER Clamp DN SENSOR #2(DI91)';
    Common.StatusInfo.AlarmMsg[92]:=   'CH 4 CARRIER Clamp UP SENSOR #3(DI92)';
    Common.StatusInfo.AlarmMsg[93]:=   'CH 4 CARRIER Clamp DN SENSOR #3(DI93)';
    Common.StatusInfo.AlarmMsg[94]:=   'CH 4 CARRIER Clamp UP SENSOR #4(DI94)';
    Common.StatusInfo.AlarmMsg[95]:=   'CH 4 CARRIER Clamp DN SENSOR #4(DI95)';
//
//  Common.StatusInfo.AlarmMsg[96]:=  'N/A 96';
//  Common.StatusInfo.AlarmMsg[97]:=  'N/A 97';
//  Common.StatusInfo.AlarmMsg[98]:=  'N/A 98';
//  Common.StatusInfo.AlarmMsg[99]:=  'N/A 99';
//  Common.StatusInfo.AlarmMsg[100]:=  'N/A 100';
//  Common.StatusInfo.AlarmMsg[101]:=  'N/A 101';
//  Common.StatusInfo.AlarmMsg[102]:=  'N/A 102';
//  Common.StatusInfo.AlarmMsg[103]:=  'N/A 103';
//
//  Common.StatusInfo.AlarmMsg[104]:=   'CARRIER_SENSOR NG CH #4';
//  Common.StatusInfo.AlarmMsg[105]:=   'PROBE_FORWARD_SENSOR NG  CH #4';
//  Common.StatusInfo.AlarmMsg[106]:=   'PROBE_BACKWARD_SENSOR NG  CH #4';
//  Common.StatusInfo.AlarmMsg[107]:=   'PROBE_UP_SENSOR NG CH #4';
//  Common.StatusInfo.AlarmMsg[108]:=   'PROBE_DOWN_SENSOR NG CH #4';
//  Common.StatusInfo.AlarmMsg[109]:=   'N/A 109';
//  Common.StatusInfo.AlarmMsg[110]:=   'N/A 110';
//  Common.StatusInfo.AlarmMsg[111]:=   'N/A 111';
//
//  Common.StatusInfo.AlarmMsg[112]:=    'CARRIER_UNLOCK_SENSOR_1 NG CH #4';
//  Common.StatusInfo.AlarmMsg[113]:=    'CARRIER_UNLOCK_SENSOR_2 NG CH #4';
//  Common.StatusInfo.AlarmMsg[114]:=    'CARRIER_UNLOCK_SENSOR_3 NG CH #4';
//  Common.StatusInfo.AlarmMsg[115]:=    'CARRIER_UNLOCK_SENSOR_4 NG CH #4';
//  Common.StatusInfo.AlarmMsg[116]:=    'CARRIER_LOCK_1 NG CH #4';
//  Common.StatusInfo.AlarmMsg[117]:=    'CARRIER_LOCK_2 NG CH #4';
//  Common.StatusInfo.AlarmMsg[118]:=    'CARRIER_LOCK_3 NG CH #4';
//  Common.StatusInfo.AlarmMsg[119]:=    'CARRIER_LOCK_4 NG CH #4';

//  Common.StatusInfo.AlarmMsg[120]:=  'N/A 120';
//  Common.StatusInfo.AlarmMsg[121]:=  'N/A 121';
//  Common.StatusInfo.AlarmMsg[122]:=  'N/A 122';
//  Common.StatusInfo.AlarmMsg[123]:=  'N/A 123';
//  Common.StatusInfo.AlarmMsg[124]:=  'N/A 124';
//  Common.StatusInfo.AlarmMsg[125]:=  'N/A 125';
//  Common.StatusInfo.AlarmMsg[126]:=  'N/A 126';
//  Common.StatusInfo.AlarmMsg[127]:=  'N/A 127';
  end
  else begin

    Common.StatusInfo.AlarmMsg[0]:= 'FAN_1_EXHAUST ERROR (DI00)';
    Common.StatusInfo.AlarmMsg[1]:= 'FAN_2_INTAKE ERROR (DI01)';
    Common.StatusInfo.AlarmMsg[2]:= 'FAN_3_EXHAUSTR ERROR (DI02)';
    Common.StatusInfo.AlarmMsg[3]:= 'FAN_4_INTAKE ERROR (DI03)';
    Common.StatusInfo.AlarmMsg[4]:= 'CH 1,2 EMO_SWITCH (DI04)';
    Common.StatusInfo.AlarmMsg[5]:= 'CH 3,4 EMO_SWITCH (DI05)';
    Common.StatusInfo.AlarmMsg[6]:= 'CH 1,2 LIGHT CURTAIN (DI06)';
    Common.StatusInfo.AlarmMsg[7]:= 'CH 3,4 LIGHT CURTAIN (DI07)';

    Common.StatusInfo.AlarmMsg[8]:= 'CH 1,2 MUTING sensing (DI08)';
    Common.StatusInfo.AlarmMsg[9]:= 'CH 3,4 MUTING sensing (DI09)';
    Common.StatusInfo.AlarmMsg[10]:= 'CH 1,2 MC MONITORING - NEED RESET BUTTON (DI10)';
    Common.StatusInfo.AlarmMsg[11]:= 'CH 3,4 MC MONITORING - NEED RESET BUTTON (DI11)';
    Common.StatusInfo.AlarmMsg[12]:= 'TEMPERATURE ALARM (DI12)';
    Common.StatusInfo.AlarmMsg[13]:= 'N/A 13';
    Common.StatusInfo.AlarmMsg[14]:= 'N/A 14';
    Common.StatusInfo.AlarmMsg[15]:= 'N/A 15';

    Common.StatusInfo.AlarmMsg[16]:= 'MAIN AIR Pressure ERROR (DI16)';
    Common.StatusInfo.AlarmMsg[17]:= 'N/A 17';
    Common.StatusInfo.AlarmMsg[18]:= 'N/A 18';
    Common.StatusInfo.AlarmMsg[19]:= 'N/A 19';
    Common.StatusInfo.AlarmMsg[20]:= 'N/A 20';
    Common.StatusInfo.AlarmMsg[21]:= 'N/A 21';
    Common.StatusInfo.AlarmMsg[22]:= 'N/A 22';
    Common.StatusInfo.AlarmMsg[23]:= 'N/A 23';

    Common.StatusInfo.AlarmMsg[24]:= 'CARRIER_SENSOR NG CH #1 (DI24)';
    Common.StatusInfo.AlarmMsg[25]:= 'TILTING_SENSOR NG CH #1 (DI25)';
    Common.StatusInfo.AlarmMsg[26]:= 'PINBLOCK OPEN CH #1 (DI26)';
    Common.StatusInfo.AlarmMsg[27]:= 'PRESSURE GUAGE NG CH #1 (DI27)';
    Common.StatusInfo.AlarmMsg[28]:= 'PINBLOCK UNLOCK OFF SENSOR NG CH #1 (DI28)';
    Common.StatusInfo.AlarmMsg[29]:= 'PINBLOCK UNLOCK ON SENSOR NG CH #1 (DI29)';
    Common.StatusInfo.AlarmMsg[30]:= 'PINBLOCK CLOSE UP SENSOR NG CH #1 (DI30)';
    Common.StatusInfo.AlarmMsg[31]:= 'PINBLOCK CLOSE DOWN SENSOR NG CH #1 (DI31)';

    Common.StatusInfo.AlarmMsg[32]:= 'CARRIER_SENSOR NG CH #2 (DI32)';
    Common.StatusInfo.AlarmMsg[33]:= 'TILTING_SENSOR NG CH #2 (DI33)';
    Common.StatusInfo.AlarmMsg[34]:= 'PINBLOCK OPEN CH #2 (DI34)';
    Common.StatusInfo.AlarmMsg[35]:= 'PRESSURE GUAGE NG CH #2 (DI35)';
    Common.StatusInfo.AlarmMsg[36]:= 'PINBLOCK UNLOCK OFF SENSOR NG  CH #2 (DI36)';
    Common.StatusInfo.AlarmMsg[37]:= 'PINBLOCK UNLOCK ON SENSOR NG  CH #2 (DI37)';
    Common.StatusInfo.AlarmMsg[38]:= 'PINBLOCK CLOSE UP SENSOR NG CH #2 (DI38)';
    Common.StatusInfo.AlarmMsg[39]:= 'PINBLOCK CLOSE DOWN SENSOR NG CH #2 (DI39)';

    Common.StatusInfo.AlarmMsg[40]:= 'CARRIER_SENSOR NG CH #3 (DI40)';
    Common.StatusInfo.AlarmMsg[41]:= 'TILTING_SENSOR NG CH #3 (DI41)';
    Common.StatusInfo.AlarmMsg[42]:= 'PINBLOCK OPEN NG CH #3 (DI42)';
    Common.StatusInfo.AlarmMsg[43]:= 'PRESSURE GUAGE NG CH #3 (DI43)';
    Common.StatusInfo.AlarmMsg[44]:= 'PINBLOCK UNLOCK OFF SENSOR NG  CH #3 (DI44)';
    Common.StatusInfo.AlarmMsg[45]:= 'PINBLOCK UNLOCK ON SENSOR NG  CH #3 (DI45)';
    Common.StatusInfo.AlarmMsg[46]:= 'PINBLOCK CLOSE UP SENSOR NG CH #3 (DI46)';
    Common.StatusInfo.AlarmMsg[47]:= 'PINBLOCK CLOSE DOWN SENSOR NG CH #3 (DI47)';

    Common.StatusInfo.AlarmMsg[48]:= 'CARRIER_SENSOR NG CH #4 (DI48)';
    Common.StatusInfo.AlarmMsg[49]:= 'TILTING_SENSOR NG CH #4 (DI49)';
    Common.StatusInfo.AlarmMsg[50]:= 'PINBLOCK OPEN NG  CH #4 (DI50)';
    Common.StatusInfo.AlarmMsg[51]:= 'PRESSURE GUAGE NG  CH #4 (DI51)';
    Common.StatusInfo.AlarmMsg[52]:= 'PINBLOCK UNLOCK OFF SENSOR NG  CH #4 (DI52)';
    Common.StatusInfo.AlarmMsg[53]:= 'PINBLOCK UNLOCK ON SENSOR NG  CH #4 (DI53)';
    Common.StatusInfo.AlarmMsg[54]:= 'PINBLOCK CLOSE UP SENSOR NG CH #4 (DI54)';
    Common.StatusInfo.AlarmMsg[55]:= 'PINBLOCK CLOSE DOWN SENSOR NG CH #4 (DI55)';

    Common.StatusInfo.AlarmMsg[56]:= 'PROBE_UP_SENSOR NG CH 1,2 (DI56)';
    Common.StatusInfo.AlarmMsg[57]:= 'PROBE_DN_SENSOR NG CH 1,2 (DI57)';
    Common.StatusInfo.AlarmMsg[58]:= 'SHUTTER UP SENSOR NG CH 1,2 DI58)';
    Common.StatusInfo.AlarmMsg[59]:= 'SHUTTER DN SENSOR NG CH 1,2 DI59)';
    Common.StatusInfo.AlarmMsg[60]:= 'PROBE_UP_SENSOR NG CH 3,4 (DI60)';
    Common.StatusInfo.AlarmMsg[61]:= 'PROBE_DN_SENSOR NG CH 3,4 (DI61)';
    Common.StatusInfo.AlarmMsg[62]:= 'SHUTTER UP SENSOR NG CH 3,4 DI62)';
    Common.StatusInfo.AlarmMsg[63]:= 'SHUTTER DN SENSOR NG CH 3,4 DI63)';

    Common.StatusInfo.AlarmMsg[64]:=  'CARRIER_SENSOR NG CH #3';
    Common.StatusInfo.AlarmMsg[65]:=  'PROBE_FORWARD_SENSOR NG  CH #3';
    Common.StatusInfo.AlarmMsg[66]:=  'PROBE_BACKWARD_SENSOR NG  CH #3';
    Common.StatusInfo.AlarmMsg[67]:=  'PROBE_UP_SENSOR NG CH #3';
    Common.StatusInfo.AlarmMsg[68]:=  'PROBE_DOWN_SENSOR NG CH #3';
    Common.StatusInfo.AlarmMsg[69]:=  'N/A 85';
    Common.StatusInfo.AlarmMsg[70]:=  'N/A 86';
    Common.StatusInfo.AlarmMsg[71]:=  'N/A 87';

    Common.StatusInfo.AlarmMsg[72]:= 'CARRIER_UNLOCK_SENSOR_1 NG CH #3';
    Common.StatusInfo.AlarmMsg[73]:= 'CARRIER_UNLOCK_SENSOR_2 NG CH #3';
    Common.StatusInfo.AlarmMsg[74]:= 'CARRIER_UNLOCK_SENSOR_3 NG CH #3';
    Common.StatusInfo.AlarmMsg[75]:= 'CARRIER_UNLOCK_SENSOR_4 NG CH #3';
    Common.StatusInfo.AlarmMsg[76]:= 'CARRIER_LOCK_1 NG CH #3';
    Common.StatusInfo.AlarmMsg[77]:= 'CARRIER_LOCK_2 NG CH #3';
    Common.StatusInfo.AlarmMsg[78]:= 'CARRIER_LOCK_3 NG CH #3';
    Common.StatusInfo.AlarmMsg[79]:= 'CARRIER_LOCK_4 NG CH #3';

    Common.StatusInfo.AlarmMsg[80]:= 'CARRIER_SENSOR NG CH #4';
    Common.StatusInfo.AlarmMsg[81]:= 'PROBE_FORWARD_SENSOR NG  CH #4';
    Common.StatusInfo.AlarmMsg[82]:= 'PROBE_BACKWARD_SENSOR NG  CH #4';
    Common.StatusInfo.AlarmMsg[83]:= 'PROBE_UP_SENSOR NG CH #4';
    Common.StatusInfo.AlarmMsg[84]:= 'PROBE_DOWN_SENSOR NG CH #4';
    Common.StatusInfo.AlarmMsg[85]:= 'N/A 109';
    Common.StatusInfo.AlarmMsg[86]:= 'N/A 110';
    Common.StatusInfo.AlarmMsg[87]:= 'N/A 111';

    Common.StatusInfo.AlarmMsg[88]:=   'CARRIER_UNLOCK_SENSOR_1 NG CH #4';
    Common.StatusInfo.AlarmMsg[89]:=   'CARRIER_UNLOCK_SENSOR_2 NG CH #4';
    Common.StatusInfo.AlarmMsg[90]:=   'CARRIER_UNLOCK_SENSOR_3 NG CH #4';
    Common.StatusInfo.AlarmMsg[91]:=   'CARRIER_UNLOCK_SENSOR_4 NG CH #4';
    Common.StatusInfo.AlarmMsg[92]:=   'CARRIER_LOCK_1 NG CH #4';
    Common.StatusInfo.AlarmMsg[93]:=   'CARRIER_LOCK_2 NG CH #4';
    Common.StatusInfo.AlarmMsg[94]:=   'CARRIER_LOCK_3 NG CH #4';
    Common.StatusInfo.AlarmMsg[95]:=   'CARRIER_LOCK_4 NG CH #4';



  end;

  Common.StatusInfo.AlarmMsg[100]:=  'Cannel 1 CA410 Connection NG';
  Common.StatusInfo.AlarmMsg[101]:=  'Cannel 2 CA410 Connection NG';
  Common.StatusInfo.AlarmMsg[102]:=  'Cannel 3 CA410 Connection NG';
  Common.StatusInfo.AlarmMsg[103]:=  'Cannel 4 CA410 Connection NG';
  Common.StatusInfo.AlarmMsg[107]:=  'DIO Conected NG';


  Common.StatusInfo.AlarmMsg[110]:= 'EICR NG';
  Common.StatusInfo.AlarmMsg[111]:= 'PG Communication Alarm';
  Common.StatusInfo.AlarmMsg[112]:= 'Continuous NG Alarm';
  Common.StatusInfo.AlarmMsg[113]:= 'Camera Communication';
  Common.StatusInfo.AlarmMsg[114]:= 'Robot Door Opened';
  Common.StatusInfo.AlarmMsg[115]:= 'Z-Axis Position';
  Common.StatusInfo.AlarmMsg[116]:= 'PLC Communication';
  Common.StatusInfo.AlarmMsg[117]:= 'Robot Interface Error';


  Common.StatusInfo.AlarmMsg[128]:=  'Connection NG';








end;


end.

