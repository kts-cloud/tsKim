unit Mainter;

interface
{$I Common.inc}
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzRadChk, Vcl.StdCtrls, RzLabel, Vcl.Mask,
  RzEdit, RzCmboBx, RzButton, RzPanel, ALed, Vcl.ExtCtrls, RzTabs, {UdpServerClient,}CommPG, DefDio, RzCommon,
  HandBCR, IdGlobal, System.IniFiles, Ezi_Servo, CommDIO_DAE, NGMsg,LogicVh,DefScript,dllClass,UserUtils,
  CommonClass, RzShellDialogs, DefCommon, DefPG, RzLstBox, ScrMemo, ScrMps, pasScriptClass, CommIonizer,Math,
  AdvUtil, Vcl.Grids, AdvObj, BaseGrid,SyncObjs, AdvGrid,{, system.threading}  ControlDio_OC, DoorOpenAlarmMsg, ECSStatusForm,
{$IFDEF AXDIO_USE}
  AXDioLib,
{$ENDIF}
  Winapi.WinSock, Vcl.Imaging.pngimage, AdvPanel, AdvSmoothListBox, AdvSmoothComboBox, CommPLC_ECS
  ,CA_SDK2, Vcl.ComCtrls,LibCa410Option, VclTee.TeeGDIPlus, AdvChartView,GMesCom
  ;
  const

  // TAB: PG/CAM : PG Commands (AF9)
  MAINT_PG_CMD_POWER_ON_ONLY        = 0;
  MAINT_PG_CMD_POWER_OFF            = 1;
  MAINT_PG_CMD_POWER_ON_BIST        = 2;
  MAINT_PG_CMD_POWER_OFF_BIST       = 3;
  MAINT_PG_CMD_PATTERN_NUM          = 4;
  MAINT_PG_CMD_PATTERN_NEXT         = 5;
  MAINT_PG_CMD_PATTERN_RGB          = 6;
  MAINT_PG_CMD_BIST_RGB             = 7;
  MAINT_PG_CMD_TCON_REG_READ        = 8;
  MAINT_PG_CMD_TCON_REG_WRITE       = 9;
  MAINT_PG_CMD_FLASH_GAMMA_READ     = 10;
  MAINT_PG_CMD_FLASH_ALL_READ       = 11;
  MAINT_PG_CMD_FLASH_ALL_WRITE      = 12;
  MAINT_PG_CMD_POWER_RESET          = 13;
  MAINT_PG_CMD_DP860                = 14;
  MAINT_PG_REPROGRARMING            = 15;
//MAINT_PG_CMD_DIMMING              = xx;
//MAINT_PG_CMD_DBV_READ             = xx;
//MAINT_PG_CMD_DBV_WRITE            = xx;

  // TAB: PG/CAM : CAM Commands (Radiant)
  MAINT_CAM_CMD_POCBGAMMA   = 0;
  MAINT_CAM_CMD_GETVER      = 1;
  MAINT_CAM_CMD_GETSEQUENCE = 2;
  MAINT_CAM_CMD_START_CB1   = 3;
  MAINT_CAM_CMD_CHGRCB_CB2  = 4;
  MAINT_CAM_CMD_CHGRCB_CB3  = 5;
  MAINT_CAM_CMD_AFTERSTART  = 6;
  MAINT_CAM_CMD_END         = 7;
  MAINT_CAM_CMD_AUTOTEST    = 8;

type

  PGuiMainter  = ^RGuiMainter;
  RGuiMainter = packed record
    MsgType : Integer;  // 1 : PG, 2 : Camera.
    Channel : Integer;  // Channel.
    Mode    : Integer;
    Msg     : string;
  end;

  TfrmMainter = class(TForm)
    btnClose: TRzBitBtn;
    pnlMainter: TRzPanel;
    RzPageControl1: TRzPageControl;
    TabSheet1: TRzTabSheet;
    tabIoMap: TRzTabSheet;
    RzGroupBox1: TRzGroupBox;
    RzPanel1: TRzPanel;
    cboChannelPg: TRzComboBox;
    RzPanel2: TRzPanel;
    mmCommPg: TMemo;
    grpBcr: TRzGroupBox;
    mmHandBcr: TMemo;
    RzBitBtn1: TRzBitBtn;
    RzOpenDialog1: TRzOpenDialog;
    btnPowerOff: TRzBitBtn;
    RzGroupBox2: TRzGroupBox;
    RzPanel3: TRzPanel;
    cboScriptCh: TRzComboBox;
    btn2: TRzBitBtn;
    btnRunScript: TRzBitBtn;
    RzGroupBox5: TRzGroupBox;
    RzGroupBox6: TRzGroupBox;
    ScrMemo1: TScrMemo;
    mmoScrResult: TMemo;
    ScrPascalMemoStyler1: TScrPascalMemoStyler;
    tbSystemInfo: TRzTabSheet;
    RzGroupBox4: TRzGroupBox;
    lstIpInformation: TRzListBox;
    RzGroupBox8: TRzGroupBox;
    img1: TImage;
    img2: TImage;
    pnl1: TPanel;
    pnl2: TPanel;
    RzGroupBox11: TRzGroupBox;
    lstLocalIp: TRzListBox;
    btnScriptOpen: TRzBitBtn;
    btnScriptSave: TRzBitBtn;
    btnStopScript: TRzBitBtn;
    tabLoaderPlcComm: TRzTabSheet;
    btnPowerOn: TRzBitBtn;
    dlgSavePro: TRzSaveDialog;
    dlgOpenPro: TRzOpenDialog;
    grpDioIn: TRzGroupBox;
    grpDioOut: TRzGroupBox;
    grpDioCtl: TRzGroupBox;
    btnShutterUpCH12: TRzBitBtn;
    btnShutterDnCH12: TRzBitBtn;
    btnAutoFront: TRzBitBtn;
    btnCarrierUnLockTop: TRzBitBtn;
    btnCarrierUnLockBottom: TRzBitBtn;
    btnAutoBack: TRzBitBtn;
    btnUnlockTopDoors: TRzBitBtn;
    btnReadOutSig: TRzBitBtn;
    RzBitBtn11: TRzBitBtn;
    tmrTableTurn: TTimer;
    chkUseTowerLamp: TCheckBox;
    TabSheet2: TRzTabSheet;
    btnCal0: TRzBitBtn;
    btnMemChInfo: TRzBitBtn;
    btnOneTimeMeasure: TRzBitBtn;
    btnRGBWMeasure: TRzBitBtn;
    RzGroupBox23: TRzGroupBox;
    RzGroupBox24: TRzGroupBox;
    grdCalVerify: TAdvStringGrid;
    btnSaveCalResult: TRzBitBtn;
    RzBitBtn12: TRzBitBtn;
    RzGroupBox14: TRzGroupBox;
    RzGroupBox15: TRzGroupBox;
    gridTarget: TAdvStringGrid;
    btnAutoCal: TRzBitBtn;
    RzGroupBox16: TRzGroupBox;
    mmoAutoCalLog: TMemo;
    btnStopCalibration: TRzBitBtn;
    pnlCalLog: TPanel;
    grpCalControl: TRzGroupBox;
    RzPanel39: TRzPanel;
    edRty_Cal: TRzNumericEdit;
    edAging_Cal: TRzNumericEdit;
    RzPanel33: TRzPanel;
    RzPanel149: TRzPanel;
    RzGroupBox17: TRzGroupBox;
    RzPanel7: TRzPanel;
    cboModelType: TRzComboBox;
    cboCalData: TRzComboBox;
    RzPanel8: TRzPanel;
    rdoProbe1: TRzRadioButton;
    rdoProbe2: TRzRadioButton;
    RzGroupBox19: TRzGroupBox;
    pnlMemChWhite: TRzPanel;
    pnlMCh1: TPanel;
    btnProbeWhite: TRzBitBtn;
    btnProbeRed: TRzBitBtn;
    btnProbeGreen: TRzBitBtn;
    Blue: TRzBitBtn;
    btnProbeBlack: TRzBitBtn;
    btnProbeUnLockCarrier: TRzBitBtn;
    btnProbeLockCarrier: TRzBitBtn;
    btnCalStProbe: TRzBitBtn;
    btnCalEdProbe: TRzBitBtn;
    RzPanel5: TRzPanel;
    edRgbwMAging: TRzNumericEdit;
    RzPanel9: TRzPanel;
    btnUnlockBottomDoors: TRzBitBtn;
    btnCarrierLockBottom: TRzBitBtn;
    RzGroupBox18: TRzGroupBox;
    cboChannelFrobe: TRzComboBox;
    btnShutterUpCH34: TRzBitBtn;
    btnShutterDnCH34: TRzBitBtn;
    btnCarrierLockTop: TRzBitBtn;
    grpDioCtlPreOC: TRzGroupBox;
    RzGroupBox25: TRzGroupBox;
    btnAutoBackPreOC: TRzBitBtn;
    btnAutoFrontPreOC: TRzBitBtn;
    cboChannelFrobePreOC: TRzComboBox;
    RzGroupBox21: TRzGroupBox;
    btnAutoPinBlackLock: TRzBitBtn;
    btnAutoPinBlackUnlock: TRzBitBtn;
    cboCHPinBllackPreOC: TRzComboBox;
    cboPatList: TRzComboBox;
    pnlParamDesc: TRzPanel;
    cbPatDispPwm: TRzCheckBox;
    RzGroupBox12: TRzGroupBox;
    RzBitBtn2: TRzBitBtn;
    btnAutoVaccumON: TRzBitBtn;
    cboCHPreOC: TRzComboBox;
    btnAutoVaccumOFF: TRzBitBtn;
    TabSheet3: TRzTabSheet;
    gbIonizer: TRzGroupBox;
    btnIonizerStart: TRzBitBtn;
    memoIonizer: TRzMemo;
    btnIonizerStop: TRzBitBtn;
    RzGroupBox3: TRzGroupBox;
    btnLampOnOff12: TRzBitBtn;
    btnLampOnOff34: TRzBitBtn;
    rdoProbe3: TRzRadioButton;
    rdoProbe4: TRzRadioButton;
    cboChannelIonlzer: TRzComboBox;
    cmbxPgCmd: TRzComboBox;
    edPgCmdParam: TRzEdit;
    RzpnlPgCmdParam: TRzPanel;
    btnPgFileOpen: TRzBitBtn;
    edPgFileSend: TRzEdit;
    btnPgSendCmd: TRzBitBtn;
    TabSheet4: TRzTabSheet;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    edtW_Y: TEdit;
    edtW_Z: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    edtW_LV: TEdit;
    edtW_YY: TEdit;
    edtW_XX: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    edtR_LV: TEdit;
    edtR_YY: TEdit;
    edtR_XX: TEdit;
    edtR_Z: TEdit;
    edtR_Y: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    edtW_X: TEdit;
    edtR_X: TEdit;
    edtG_X: TEdit;
    edtG_Y: TEdit;
    edtG_Z: TEdit;
    edtG_XX: TEdit;
    edtG_YY: TEdit;
    edtG_LV: TEdit;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    edtB_X: TEdit;
    edtB_Y: TEdit;
    edtB_Z: TEdit;
    edtB_xx: TEdit;
    edtB_yy: TEdit;
    edtB_LV: TEdit;
    mmoLog: TRzRichEdit;
    Button3: TButton;
    RzComboBox1: TRzComboBox;
    RzPanel4: TRzPanel;
    RzPanel6: TRzPanel;
    cboCa310Channel: TRzComboBox;
    Button1: TButton;
    tbCA410Measurement: TRzTabSheet;
    cboBandCount: TRzComboBox;
    RzPanel10: TRzPanel;
    RzPanel11: TRzPanel;
    cboGrayRGB: TRzComboBox;
    rbGrayScale: TRadioButton;
    rbDBVTracking: TRadioButton;
    cboMeasureCH: TRzComboBox;
    RzPanel12: TRzPanel;
    btnStop: TRzBitBtn;
    btnMeasure: TRzBitBtn;
    pnlDataView: TPanel;
    chkOddMeasurement: TCheckBox;
    chkReversal: TCheckBox;
    btnSendEods_R: TButton;
    btnSendEoda: TButton;
    Button2: TButton;
    cboSaveCa410Channel: TButton;
    rbCEL_Yufeng: TRadioButton;

    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnSendCmdPgClick(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure RzBitBtn1Click(Sender: TObject);
    procedure btnPowerOffClick(Sender: TObject);
    procedure btnControlPlcClick(Sender: TObject);
    procedure btnRunScriptClick(Sender: TObject);
    procedure btnAutoFrontClick(Sender: TObject);
    procedure btnAutoBackClick(Sender: TObject);
    procedure btnAutoCalClick(Sender: TObject);
    procedure gridTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOneTimeMeasureClick(Sender: TObject);
    procedure btnScriptOpenClick(Sender: TObject);
    procedure btnScriptSaveClick(Sender: TObject);
    procedure btnStopScriptClick(Sender: TObject);
    procedure btnStartJNCDMeasureClick(Sender: TObject);
    procedure RzPageControl1Click(Sender: TObject);
    procedure btnPowerOnClick(Sender: TObject);


    procedure btnCalStProbeClick(Sender: TObject);
    procedure btnCalEdProbeClick(Sender: TObject);
    procedure RzBitBtn19Click(Sender: TObject);



    procedure RzBitBtn20Click(Sender: TObject);


    procedure tbPocbOptionClick(Sender: TObject);
    procedure btnTurnAStageClick(Sender: TObject);
    procedure btnTurnBStageClick(Sender: TObject);
    procedure btnShutterUpCH12Click(Sender: TObject);
    procedure btnShutterDnCH12Click(Sender: TObject);
    procedure btnCarrierUnLockTopClick(Sender: TObject);
    procedure btnCarrierUnLockBottomClick(Sender: TObject);
    procedure btnClampUpStageAClick(Sender: TObject);
    procedure btnClampUpStageBClick(Sender: TObject);
    procedure btnMotorStopClick(Sender: TObject);
    procedure btnUnlockTopDoorsClick(Sender: TObject);
    procedure btnReadOutSigClick(Sender: TObject);
    procedure RzBitBtn11Click(Sender: TObject);
    procedure tmrTableTurnTimer(Sender: TObject);
    procedure edCmdPosChange(Sender: TObject);
    procedure pnAxisMoveJog_DecMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pnAxisMoveJog_IncMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure chkUseTowerLampClick(Sender: TObject);
    procedure btnStopCalibrationClick(Sender: TObject);
    procedure btnRGBWMeasureClick(Sender: TObject);
    procedure btnMemChInfoClick(Sender: TObject);
    procedure btnCal0Click(Sender: TObject);
    procedure btnUnlockBottomDoorsClick(Sender: TObject);
    procedure btnCarrierLockTopClick(Sender: TObject);
    procedure btnCarrierLockBottomClick(Sender: TObject);
    procedure btnShutterUpCH34Click(Sender: TObject);
    procedure btnShutterDnCH34Click(Sender: TObject);
    procedure btnAutoPinBlackUnlockClick(Sender: TObject);
    procedure btnAutoPinBlackLockClick(Sender: TObject);
    procedure btnAutoFrontPreOCClick(Sender: TObject);
    procedure btnAutoBackPreOCClick(Sender: TObject);
    procedure btnAutoVaccumONClick(Sender: TObject);
    procedure btnAutoVaccumOFFClick(Sender: TObject);
    procedure btnLampOnOff34Click(Sender: TObject);
    procedure btnLampOnOff12Click(Sender: TObject);
    procedure btnIonizerStartClick(Sender: TObject);
    procedure btnIonizerStopClick(Sender: TObject);
    procedure btnPgFileOpenClick(Sender: TObject);
    procedure btnPgSendCmdClick(Sender: TObject);
    procedure cboChannelPgChange(Sender: TObject);
    procedure btnProbeLockCarrierClick(Sender: TObject);
    procedure btnProbeUnLockCarrierClick(Sender: TObject);
    procedure btnProbeWhiteClick(Sender: TObject);
    procedure btnProbeRedClick(Sender: TObject);
    procedure btnProbeBlackClick(Sender: TObject);
    procedure btnProbeGreenClick(Sender: TObject);
    procedure BlueClick(Sender: TObject);
    procedure btnSaveCalResultClick(Sender: TObject);
    procedure cboModelTypeClick(Sender: TObject);
    procedure cboCalDataClick(Sender: TObject);
    procedure btnSendEods_RClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnMeasureClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure Button211Click(Sender: TObject);
    procedure btnSendEodaClick(Sender: TObject);
    procedure cmbxPgCmdChange(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Panel1DblClick(Sender: TObject);
    procedure cboSaveCa410ChannelClick(Sender: TObject);

  private
    { Private declarations }
    bIs_Stop : Boolean;

    ledIn : array[0 .. DefDio.MAX_IO_CNT] of ThhALed;
    pnlIn : array[0 .. DefDio.MAX_IO_CNT] of TRzPanel;
    pnlDioIn : array[0 .. DefDio.MAX_IO_CNT] of TRzPanel;

    ledOut : array[0 .. DefDio.MAX_IO_CNT] of ThhALed;
    btnOutSig : array[0 .. DefDio.MAX_IO_CNT] of TRzBitBtn;
    pnlOut : array[0 .. DefDio.MAX_IO_CNT] of TRzPanel;
    pnlDioOut : array[0 .. DefDio.MAX_IO_CNT] of TRzPanel;
    m_bChangeZAxisValue: Boolean;

    m_bStopCa310Cal : boolean;

    Mutex: TMutex;

    advstrngrdDataView : array[DefCommon.CH1 ..DefCommon.MAX_CH] of TAdvStringGrid;

    pnlR2RName : array [0..23] of TRzPanel;
    pnlR2RData : array [0..23] of TEdit;

{$IFDEF  AXDIO_USE}
    m_PreInIo, m_PreOutIo         : AxIoStatus;
{$ENDIF}

    procedure AddItemsInCbo;  // Added by KTS 2022-08-09 오전 11:55:25
    procedure AddCboCsvData;
    procedure LoadOptIni(sDir: string);
    procedure LoadOptCsv(sFileName: string);
    procedure SaveOptCsv(sFileName : string);
    procedure ClearCalResult;
    procedure ShowUsercalItems;  // Added by KTS 2022-08-09 오전 11:54:14


    procedure DisplayPgLog(nCh : Integer; sMsg: string);

    {$IFDEF PG_AF9}
    procedure AF9ApiLogCall(nPgNo : Integer; sMsg: string);
    procedure AF9ApiLogReturn(nPgNo : Integer; sMsg: string);
    {$ENDIF}
    {$IFDEF PG_DP860}
    procedure GetPgRxData(nPgNo: Integer; sLocal,sRemote: string; sMsg: string);
    procedure GetPgTxData(nPgNo: Integer; sLocal,sRemote: string; sMsg: string);
    {$ENDIF}
    procedure MaintFlashAllWrite(nCh: Integer);
    procedure MaintFlashAllRead(nCh: Integer);

    procedure GetPgRevData(nPgNo : Integer; nLength : Integer; RevData : array of byte);
    procedure SendGuiDisplay(nCh: Integer; sMsg : string);
    procedure Ca310CalControlPnl(bEnable : Boolean);

    procedure ThreadTask(task : TProc; btnObj : TRzBitBtn);
    procedure ThreadTaskTracking(task: TProc; btnObj : TRzBitBtn);

    procedure SaveCsvMeasureLog(nCh: Integer; sSerialNo,sDataHeader,sData : string);
    procedure PowerOffSeq(nCh : Integer);
    procedure PowerOnSeq(nCh : Integer);
//    procedure CmdThread(nCh : Integer);
    procedure PgCmdThread(nCh: Integer);
    procedure OnEvtOutBtn(Sender: TObject);
    procedure getBcrData(sScanData : string);

    procedure GetLocalIpList;
    procedure MeasureJncdPg(nCh, nCa310Pos: Integer;sCa310Ch : string);

    function GetProbeNum : Integer;
    procedure SaveCalResult(bIsVerify : Boolean = False);

    procedure RunDosInMemo(DosApp: string; var sGetResult : string);
  
    procedure MaintFlashPucDataWrite(nCh: Integer);
    procedure POcbIpList;
    procedure CamLightEvent(sData : string);
    procedure MakeDIOSignal;
    procedure ThreadStartDio(task : TProc);
    procedure MakePlcSignal;
//    procedure ShowIoSignal(bIsIn, bConnChange : Boolean; nLen : Integer; naReadData : array of Integer);
    procedure LoadZAsixValue;
    procedure SaveZAsixValue;

    procedure ShowNgMessage(sMessage: string);

    function Make_reference_All_DBV_Gray_Data(fDBV : double) :  TArray<Double>;
    function Find_Gray_index_Near_Target_1(fDBV,Target_Lv : Double) : TArray<Double>;
    procedure Run_GrayScale(nFPgNo,mBand_Count : Integer);
    procedure Run_DBVtracking(nFPgNo,nRGBIdx: Integer);
    procedure Run_Measure_CEL_NY(nFPgNo: Integer; fSearch_Lv : Double);
    function ReadFlashSerialNo(nPgNo: Integer): string;
{$IFDEF CA410_USE}
    procedure CA410Calibration(Lth : TThread; GetAllxy, Getlmt: TAllLvXy);
    procedure wRgb_Measure(thMain : TThread);
{$ENDIF}
{$IFDEF ADLINK_DIO}
    procedure ADDioStatus(InDio, OutDio: ADioStatus);
{$ENDIF}
{$IFDEF AXDIO_USE}
    procedure AxDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg : string);
{$ENDIF}
//    procedure AddItemsInCbo;
  public
    m_hMain : HWND;
    procedure DisplayDio( bIn : Boolean );
    procedure GetR2RData(nCH : Integer);

    procedure IonizerReadData(bConnect : Boolean; sReadData : String);
  end;

var
  frmMainter: TfrmMainter;

implementation


{$R *.dfm}

{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$WARN IMPLICIT_STRING_CAST OFF}

procedure TfrmMainter.btnReadOutSigClick(Sender: TObject);
begin
  if CommDaeDIO <> nil then  CommDaeDIO.ReadDO(0,DefDio.DAE_IO_DEVICE_COUNT+Common.SystemInfo.DioType);
end;

procedure TfrmMainter.ClearCalResult;
var
  i : Integer;
  sTemp : string;
begin
// Header for first line.
  grdCalVerify.ClearAll;
  grdCalVerify.Cells[0,0]   := 'Date/Time';
  grdCalVerify.Cells[1,0]   := 'CH';
  grdCalVerify.Cells[2,0]   := 'Count';
// Header for Second Line.
  for i := 1 to 4 do begin
    case i of
      1 : sTemp := 'R';
      2 : sTemp := 'G';
      3 : sTemp := 'B';
      4 : sTemp := 'W'
      else sTemp := '';
    end;
    grdCalVerify.Cells[(i*3)    ,0] := sTemp + '_x';
    grdCalVerify.Cells[(i*3) + 1,0] := sTemp + '_y';
    grdCalVerify.Cells[(i*3) + 2,0] := sTemp + '_Lv';
  end;
  grdCalVerify.Cells[15,0]  := 'Result';
end;




procedure TfrmMainter.cmbxPgCmdChange(Sender: TObject);
begin

end;

{$IFDEF CA410_USE}
procedure TfrmMainter.CA410Calibration(Lth: TThread; GetAllxy, Getlmt: TAllLvXy);
var
  i, j, k , nCh, nR, nG, nB, nMemCh : Integer;
  sDebug, sCh, sTemp : string;
  bRet, bIsOk : boolean;
  MemChInfo : array [0 .. DefCaSdk.IDX_MAX] of  TLvXY;
  x, y , lv : Double;
  GetData : TBrightValue;
  sPidNo  : AnsiString;
  nCaRet : Integer;

  rx, ry, rLv : Double;
  gx, gy, gLv : Double;
  bx, by, bLv : Double;
  wx, wy, wLv : Double;
begin
// System Connection Checking.
  nCh := GetProbeNum;

  bIsOk := True;
  nMemCh := Common.OpticInfo.CalMemCh[DefCaSdk.IDX_WHITE];
  sDebug := Format('Ch%d OpticInfo.CalMemCh : %d',[nCh + 1,nMemCh]);
  mmoAutoCalLog.Lines.Add(sDebug);
  if m_bStopCa310Cal then Exit;
  try
    nCaRet := CaSdk2.UsrCalReady(nCh,nMemCh);
    if nCaRet <> 0 then begin
      Lth.Synchronize(Lth, procedure begin
        sDebug := Format('Ch%d UserCalReady NG, error code(%d) ',[nCh + 1,nCaRet]);
        mmoAutoCalLog.Lines.Add(sDebug);
      end);
      Exit;
    end;

//    nCaRet := CaSdk2.init_MemCh(nCh,nMemCh);
//    if nCaRet <> 0 then begin
//      Lth.Synchronize(Lth, procedure begin
//        sDebug := Format('Ch%d Mem Ch Initial NG, error code(%d) ',[nCh + 1,nCaRet]);
//        mmoAutoCalLog.Lines.Add(sDebug);
//      end);
//      Exit;
//    end;
//
//    nCaRet := CaSdk2.SetMemCh(nCh,nMemCh);
//    if nCaRet <> 0 then begin
//      Lth.Synchronize(Lth, procedure begin
//        sDebug := Format('Ch%d SetMemCh NG, error code(%d) ',[nCh + 1,nCaRet]);
//        mmoAutoCalLog.Lines.Add(sDebug);
//      end);
//      Exit;
//    end;
//
//    nCaRet := CaSdk2.set_DisplayMode(nCh);
//    if nCaRet <> 0 then begin
//      Lth.Synchronize(Lth, procedure begin
//        sDebug := Format('Ch%d set_DisplayMode NG, error code(%d) ',[nCh + 1,nCaRet]);
//        mmoAutoCalLog.Lines.Add(sDebug);
//      end);
//      Exit;
//    end;
//    nCaRet := CaSdk2.set_CalZero(nCh);
//    if nCaRet <> 0 then begin
//      Lth.Synchronize(Lth, procedure begin
//        sDebug := Format('Ch%d set_CalZero NG, error code(%d) ',[nCh + 1,nCaRet]);
//        mmoAutoCalLog.Lines.Add(sDebug);
//      end);
//      Exit;
//    end;
//    nCaRet := CaSdk2.setLvxyCalMode(nCh);
//    if nCaRet <> 0 then begin
//      Lth.Synchronize(Lth, procedure begin
//        sDebug := Format('Ch%d setLvxyCalMode NG, error code(%d) ',[nCh + 1,nCaRet]);
//        mmoAutoCalLog.Lines.Add(sDebug);
//      end);
//      Exit;
//    end;
    Sleep(1000);

    for i := DefCaSdk.IDX_RED to  DefCaSdk.IDX_MAX do begin
      case i of
        DefCaSdk.IDX_WHITE : begin
          nR := 255;  nG := 255;  nB := 255;  sTemp := 'W';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_1);  // white.
        end;
        DefCaSdk.IDX_RED : begin
          nR := 255;  nG := 0;    nB := 0;    sTemp := 'R';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_2);  // R.
        end;
        DefCaSdk.IDX_GREEN : begin
          nR := 0;    nG := 255;  nB := 0;    sTemp := 'G';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_3);  // G.
        end;
        DefCaSdk.IDX_BLUE : begin
          nR := 0;    nG := 0;    nB := 255;  sTemp := 'B';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_4);  // B.
        end;
      end;

      Sleep(5000);
      nCaRet := CaSdk2.UsrCalMeasure(nCh,i,x, y , lv);
      if nCaRet <> 0 then begin
        Lth.Synchronize(Lth, procedure begin
          sDebug := Format('Ch%d Calibration Measure NG, error code(%d) ',[nCh + 1,nCaRet]);
          mmoAutoCalLog.Lines.Add(sDebug);
        end);
        Exit;
      end;
      Lth.Synchronize(Lth, procedure begin
        sDebug := Format('Cal Measure  Ch %d , x(%0.4f), y(%0.4f), Lv(%0.4f)',[nCh + 1,x, y , lv]);
        mmoAutoCalLog.Lines.Add(sDebug);
      end);
//      sDebug := Format('Cal Measure  Ch %d ,GetAllxy[i].x-x(%0.4f), GetAllxy[i].y-y(%0.4f), GetAllxy[i].Lv-Lv(%0.4f)',[nCh + 1,GetAllxy[i].x-x, GetAllxy[i].y-y ,GetAllxy[i].Lv- lv]);
//        mmoAutoCalLog.Lines.Add(sDebug);
//      nCaRet := CaSdk2.UsrCalSetCalData(nCh,i,(GetAllxy[i].x-x + 0.3127),(GetAllxy[i].y-y+0.3290),(GetAllxy[i].Lv-Lv+100));
//      nCaRet := CaSdk2.UsrCalSetCalData(nCh,i,(GetAllxy[i].x),(GetAllxy[i].y),(GetAllxy[i].Lv));
//      if nCaRet <> 0 then begin
//        Lth.Synchronize(Lth, procedure begin
//          sDebug := Format('Ch%d SetMatrixCal NG, error code(%d) ',[nCh + 1,nCaRet]);
//          mmoAutoCalLog.Lines.Add(sDebug);
//        end);
//        Exit;
//      end;
//      Lth.Synchronize(Lth, procedure begin
//        sDebug := Format('%s:SetMatrixCal:Ch(%d), x(%0.4f), y(%0.4f), Lv(%0.4f)',[sTemp, nCh +1, GetAllxy[i].x,GetAllxy[i].y,GetAllxy[i].Lv]);
//        sDebug := Format('Mem Ch %d , ',[nMemCh]) + sDebug;
//        mmoAutoCalLog.Lines.Add(sDebug);
//      end);
    end;

    for i := DefCaSdk.IDX_RED to  DefCaSdk.IDX_MAX do begin
      case i of
        DefCaSdk.IDX_WHITE  : sTemp := 'W';
        DefCaSdk.IDX_RED    : sTemp := 'R';
        DefCaSdk.IDX_GREEN  : sTemp := 'G';
        DefCaSdk.IDX_BLUE   : sTemp := 'B';
      end;

      nCaRet := CaSdk2.UsrCalSetCalData(nCh,i,GetAllxy[i].x,GetAllxy[i].y,GetAllxy[i].Lv);
      if nCaRet <> 0 then begin
        Lth.Synchronize(Lth, procedure begin
          sDebug := Format('Ch%d SetMatrixCal NG, error code(%d) ',[nCh + 1,nCaRet]);
          mmoAutoCalLog.Lines.Add(sDebug);
        end);
        Exit;
      end;
      Lth.Synchronize(Lth, procedure begin
        sDebug := Format('%s:SetMatrixCal:Ch(%d), x(%0.4f), y(%0.4f), Lv(%0.4f)',[sTemp, nCh +1, GetAllxy[i].x,GetAllxy[i].y,GetAllxy[i].Lv]);
        sDebug := Format('Mem Ch %d , ',[nMemCh]) + sDebug;
        mmoAutoCalLog.Lines.Add(sDebug);
      end);
    end;

    Lth.Synchronize(Lth, procedure begin
      mmoAutoCalLog.Lines.Add('Matrix Calibration Update');
    end);
//    nCaRet := MatrixCal_Update(nCh);
    nCaRet := CaSdk2.CasdkEnter(nCh);
    if nCaRet <> 0 then begin
      Lth.Synchronize(Lth, procedure begin
        sDebug := Format('Ch%d Calibration Update NG, error code(%d) ',[nCh + 1,nCaRet]);
        mmoAutoCalLog.Lines.Add(sDebug);
      end);
      Exit;
    end;
    Sleep(500);
  except
    on E: Exception do begin
      Lth.Synchronize(Lth, procedure begin
        sDebug := 'Error --- Reset.';
        mmoAutoCalLog.Lines.Add(sDebug);
        sDebug := 'CA410(' +E.Message+')';
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
    end;
  end;

  // Power Off.
  if Pg[nCh].SendPowerOn(0) <> WAIT_OBJECT_0 then begin    // Added by KTS 2022-08-09 오후 1:27:29 auto cal
    Lth.Synchronize(Lth, procedure begin
      sDebug := Format('Ch%d Power Off ==> NAK ',[nCh + 1]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;                                       // Added by KTS 2022-08-09 오후 1:27:34auto cal
  // Reset Lvxy Mode.
  CaSdk2.ResetCalMode(nCh);
  //ResetLvCalMode(nCh);
//  PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_9,False); // Added by KTS 2022-08-09 오후 1:26:52 auto cal
//  Sleep(1000);
//  // Power On.
  if Pg[nCh].SendPowerOn(1) <> WAIT_OBJECT_0 then begin
    Lth.Synchronize(Lth, procedure begin
      sDebug := Format('Ch%d Power Off ==> NAK ',[nCh + 1]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;
//  sleep(1000);
//  Pg[nCh].SendSpiWp(0);
  // Display White.
  PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_2);   // Added by KTS 2022-08-09 오후 1:29:17auto cal

  nCaRet := set_MemCh(nCh,Common.OpticInfo.CalMemCh[DefCaSdk.IDX_WHITE]);
  sDebug := Format('Ch%d set_MemCh : %d) ',[nCh + 1,Common.OpticInfo.CalMemCh[DefCaSdk.IDX_WHITE]]);
  mmoAutoCalLog.Lines.Add(sDebug);
  if nCaRet <> 0 then begin
    Lth.Synchronize(Lth, procedure begin
      sDebug := Format('Ch%d Memory Set NG, error code(%d) ',[nCh + 1,nCaRet]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;
  Sleep(1000);
  // 3회 Retry.
  for i := 1 to Common.OpticInfo.CalRetryCnt do begin
    Lth.Synchronize(Lth, procedure begin
      grdCalVerify.Cells[0,i] := FormatDateTime('hh:mm:ss',now);
      grdCalVerify.Cells[1,i] := Format('%d',[nCh+1]);
      grdCalVerify.Cells[2,i] := Format('%d',[i]);
    end);
    bRet := False;
    for j := DefCaSdk.IDX_RED to  DefCaSdk.IDX_MAX do begin
      case j of
        DefCaSdk.IDX_WHITE : begin
          nR := 255;  nG := 255;  nB := 255;
          sTemp := 'WHITE';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_1);  // Added by KTS 2022-08-09 오후 1:29:32auto cal
        end;
        DefCaSdk.IDX_RED : begin
          nR := 255;  nG := 0;  nB := 0;
          sTemp := 'RED';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_2);  // R.  // Added by KTS 2022-08-09 오후 1:29:45auto cal
        end;
        DefCaSdk.IDX_GREEN : begin
          nR := 0;  nG := 255;  nB := 0;
          sTemp := 'GREEN';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_3);  // G.   // Added by KTS 2022-08-09 오후 1:29:53 auto cal
        end;
        DefCaSdk.IDX_BLUE : begin
          nR := 0;  nG := 0;  nB := 255;
          sTemp := 'BLUE';
          PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_4);  // B. // Added by KTS 2022-08-09 오후 1:30:02 auto cal
        end;
      end;
      // White.
      Sleep(5000);

      Lth.Synchronize(Lth, procedure begin
        nCaRet := CaSdk2.Measure(nCh,GetData);
      end);
      if nCaRet <> 0 then begin
        Lth.Synchronize(Lth, procedure begin
          sDebug := Format('Ch%d CA410 Measure NG, error code(%d) ',[nCh + 1,nCaRet]);
          mmoAutoCalLog.Lines.Add(sDebug);
        end);
        Exit;
      end;
      Lth.Synchronize(Lth, procedure begin
        grdCalVerify.Cells[j*3 + 3,i] := Format('%0.6f',[GetData.xVal]);
        grdCalVerify.Cells[j*3 + 4,i] := Format('%0.6f',[GetData.yVal]);
        grdCalVerify.Cells[j*3 + 5,i] := Format('%0.6f',[GetData.LvVal]);
      end);
      if not (Abs(GetAllxy[j].x -GetData.xVal) < Getlmt[j].x) then begin
        Lth.Synchronize(Lth, procedure begin
          sDebug := Format('Ch%d %s %d,%d,%d x Limit NG ',[nCh + 1,sTemp, nR, nG, nB]);
          mmoAutoCalLog.Lines.Add(sDebug);
          sDebug := Format('abs(%0.6f - %0.6f) ',[GetAllxy[j].x , GetData.xVal]);
          sDebug := sDebug + Format(': %0.6f >= %0.6f ',[Abs(GetAllxy[j].x - GetData.xVal),Getlmt[j].x ]);
          mmoAutoCalLog.Lines.Add(sDebug);
          bRet := True;
        end);
      end;
      if not (Abs(GetAllxy[j].y - GetData.yVal) < Getlmt[j].y) then begin
        Lth.Synchronize(Lth, procedure begin
          sDebug := Format('Ch%d %s %d,%d,%d y Limit NG ',[nCh + 1,sTemp, nR, nG, nB]);
          mmoAutoCalLog.Lines.Add(sDebug);
          sDebug := Format('abs(%0.6f - %0.6f) ',[GetAllxy[j].y , GetData.yVal]);
          sDebug := sDebug + Format(': %0.6f >= %0.6f ',[Abs(GetAllxy[j].y -GetData.yVal),Getlmt[j].y ]);
          mmoAutoCalLog.Lines.Add(sDebug);
          bRet := True;
        end);
      end;
      if not (Abs(GetAllxy[j].Lv - GetData.LvVal) < Getlmt[j].Lv) then begin
        Lth.Synchronize(Lth, procedure begin
          sDebug := Format('Ch%d %s %d,%d,%d Lv Limit NG ',[nCh + 1,sTemp, nR, nG, nB]);
          mmoAutoCalLog.Lines.Add(sDebug);
          sDebug := Format('abs(%0.6f - %0.6f) ',[GetAllxy[j].Lv , GetData.LvVal]);
          sDebug := sDebug + Format(': %0.6f >= %0.6f ',[Abs(GetAllxy[j].Lv -GetData.LvVal),Getlmt[j].Lv ]);
          mmoAutoCalLog.Lines.Add(sDebug);
          bRet := True;
        end);
      end;
    end;
    if bRet then grdCalVerify.Cells[15,i] := 'NG'
    else         grdCalVerify.Cells[15,i] := 'OK';
    bIsOk := (not bRet) and bIsOk;
  end;
  bRet := False;

  // Get Memory Information.
  nCaRet := CaSdk2.GetMemInfo(nCh,nMemCh,  rLv, rx, ry, gLv ,gx, gy, bLv , bx, by , wLv ,  wx, wy);
  if nCaRet <> 0 then begin
    Lth.Synchronize(Lth, procedure begin
      sDebug := Format('Ch%d Get Memory Channel Info NG, error code(%d) ',[nCh + 1,nCaRet]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;
  for i := DefCaSdk.IDX_RED to DefCaSdk.IDX_MAX do begin
    case i of
      DefCaSdk.IDX_WHITE : begin
        x := wx; y := wy; lv := wLv;  sTemp := 'W';
      end;
      DefCaSdk.IDX_RED : begin
        x := rx; y := ry; lv := rLv;    sTemp := 'R';
      end;
      DefCaSdk.IDX_GREEN : begin
        x := gx; y := gy; lv := gLv;    sTemp := 'G';
      end;
      DefCaSdk.IDX_BLUE : begin
        x := bx; y := by; lv := bLv;  sTemp := 'B';
      end;
    end;
    Lth.Synchronize(Lth, procedure begin
      sDebug := Format('Ch Info: MemCh(%d),Color Type(%s),x(%.4f), y(%.4f), Lv(%.1f)',[nMemCh,sTemp,x, y, Lv]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    if x <> GetAllxy[i].x then begin
      Lth.Synchronize(Lth, procedure begin
        sDebug := Format('NG - Color Type(%s) -Target X (%.4f), Measure X (%0.4f)',[sTemp,x, GetAllxy[i].x]);
        mmoAutoCalLog.Lines.Add(sDebug);
        bRet := True;
      end);
    end;
    if y <> GetAllxy[i].y then begin
      Lth.Synchronize(Lth, procedure begin
        sDebug := Format('NG - Color Type(%s) - Target y (%.4f), Measure y (%0.4f)',[sTemp,y, GetAllxy[i].y]);
        mmoAutoCalLog.Lines.Add(sDebug);
        bRet := True;
      end);
    end;
    if Lv <> GetAllxy[i].Lv then begin
      Lth.Synchronize(Lth, procedure begin
        sDebug := Format('NG - Color Type(%s) -Target Lv (%.4f), Measure Lv (%0.4f)',[sTemp,Lv, GetAllxy[i].Lv]);
        mmoAutoCalLog.Lines.Add(sDebug);
        bRet := True;
      end);
    end;
    bIsOk := bIsOk and (not bRet);
  end;
  Lth.Synchronize(Lth, procedure begin
    if bIsOk then   pnlCalLog.Caption := 'Cal is OK'
    else            pnlCalLog.Caption := 'Cal is NG';
  end);
  // Power Off.
  if Pg[nCh].SendPowerOn(0) <> WAIT_OBJECT_0 then begin  // Added by KTS 2022-08-09 오후 1:30:18auto cal
    Lth.Synchronize(Lth, procedure begin
      sDebug := Format('Ch%d Power Off ==> NAK ',[nCh + 1]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;               // Added by KTS 2022-08-09 오후 1:30:25 auto cal
  SaveCalResult;
end;
{$ENDIF}

{$IFDEF CA410_USE}
procedure TfrmMainter.wRgb_Measure(thMain : TThread);
var
  i, j, nRow : Integer;
  nPgNo, nProbeNum, nProbeCh, nStage : Integer;
  sCh, sColor, sDebug, sTemp : string;
  getData : TBrightValue;
begin
  nPgNo := GetProbeNum;

  // Power Off.
//  Pg[nPgNo].SendSpiPowerOn(0);
  sleep(500);
  // Power On.
//  PasScr[nPgNo].RunSeq(DefScript.SEQ_MAINT_9,False);
  thMain.Synchronize(thMain, procedure begin
    sDebug := Format('Ch%d Power On',[nPgNo + 1]);
    mmoAutoCalLog.Lines.Add(sDebug);
  end);
  // Display white
//  PasScr[nPgNo].RunSeq(DefScript.SEQ_MAINT_1,False);
  thMain.Synchronize(thMain, procedure begin
    sDebug := Format('Ch%d Display White patten',[nPgNo + 1]);
    mmoAutoCalLog.Lines.Add(sDebug);
  end);

  // Aging
  if Common.OpticInfo.CalRgbwAgingTm > 0 then begin
    for i := 0 to Pred(Common.OpticInfo.CalRgbwAgingTm) do begin
      thMain.Synchronize(thMain, procedure begin
        pnlCalLog.Caption := Format('%d Sec',[(Common.OpticInfo.CalRgbwAgingTm-i)]);
      end);
      sleep(1000);
      if m_bStopCa310Cal then break;
    end;
  end;
  if m_bStopCa310Cal then begin
    //Power Off
    Sleep(200);
//    Pg[nPgNo].SendSpiPowerOn(0);
    mmoAutoCalLog.Lines.Add('Power Off');
    Exit;
  end;

//  CaSdk2.SetMemCh(nPgNo,Common.OpticInfo.CalMemCh[DefCaSdk.IDX_WHITE]);
//  thMain.Synchronize(thMain, procedure begin
//    sDebug := Format('Ch%d Set Memory Channel %d',[nPgNo + 1,Common.OpticInfo.CalMemCh[DefCaSdk.IDX_WHITE]]);
//    mmoAutoCalLog.Lines.Add(sDebug);
//  end);

  for i := 1 to Common.OpticInfo.CalRetryCnt do begin
    thMain.Synchronize(thMain, procedure begin
      grdCalVerify.Cells[0,i] := FormatDateTime('hh:mm:ss',now);
      grdCalVerify.Cells[1,i] := Format('%d',[nPgNo+1]);
      grdCalVerify.Cells[2,i] := Format('%d',[i]);
    end);

    for j := DefCaSdk.IDX_RED to  DefCaSdk.IDX_MAX do begin
      case j of
        DefCaSdk.IDX_WHITE : begin
//          PasScr[nPgNo].RunSeq(DefScript.SEQ_MAINT_1,False);
          sColor := 'WHITE';
        end;
        DefCaSdk.IDX_RED : begin
//          PasScr[nPgNo].RunSeq(DefScript.SEQ_MAINT_2,False);
          sColor := 'RED';
        end;
        DefCaSdk.IDX_GREEN : begin
//          PasScr[nPgNo].RunSeq(DefScript.SEQ_MAINT_3,False);
          sColor := 'GREEN';
        end;
        DefCaSdk.IDX_BLUE : begin
//          PasScr[nPgNo].RunSeq(DefScript.SEQ_MAINT_4,False);
          sColor := 'BLUE';
        end;
      end;
      Sleep(500);
      CaSdk2.Measure(nPgNo,GetData);
      thMain.Synchronize(thMain, procedure begin
        grdCalVerify.Cells[j*3 + 3,i] := Format('%0.6f',[GetData.xVal]);
        grdCalVerify.Cells[j*3 + 4,i] := Format('%0.6f',[GetData.yVal]);
        grdCalVerify.Cells[j*3 + 5,i] := Format('%0.6f',[GetData.LvVal]);
      end);
    end;
  end;
  SaveCalResult(True);
  //Power Off
  Sleep(200);
//  Pg[nPgNo].SendSpiPowerOn(0);
  thMain.Synchronize(thMain, procedure begin
    mmoAutoCalLog.Lines.Add('Power Off');
  end);
end;
{$ENDIF}


procedure TfrmMainter.btnRGBWMeasureClick(Sender: TObject);
var
  nPgNo : Integer;
  thAutoMeasure : TThread;
  sDebug : string;
begin
  nPgNo := GetProbeNum;
  m_bStopCa310Cal := False;
  Common.OpticInfo.CalRgbwAgingTm := StrToIntDef(edRgbwMAging.Text,0);
  if Pg[nPgNo].StatusPg in [pgDisconn,pgWait] then begin
    thAutoMeasure.Synchronize(thAutoMeasure, procedure begin
      sDebug := Format('Channel %d is disconnected',[nPgNo + 1]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;
  ClearCalResult;
  mmoAutoCalLog.Lines.Clear;
{$IFDEF CA410_USE}
  // CA310 Connection Check.
  if not CaSdk2.m_bConnection[nPgNo] then begin
    thAutoMeasure.Synchronize(thAutoMeasure, procedure begin
      sDebug := Format('CA410 Channel %d is disconnected',[nPgNo + 1]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;
  thAutoMeasure := TThread.CreateAnonymousThread(procedure begin
    wRgb_Measure(thAutoMeasure);
  end);
  thAutoMeasure.Start;
{$ENDIF}
{$IFDEF CA310_USE}
  // CA310 Connection Check.
  if not DongaCa310[0].m_bConnection then begin
    thAutoMeasure.Synchronize(thAutoMeasure, procedure begin
      sDebug := Format('CA310 Channel %d is disconnected',[nPgNo + 1]);
      mmoAutoCalLog.Lines.Add(sDebug);
    end);
    Exit;
  end;
  thAutoMeasure := TThread.CreateAnonymousThread(procedure begin
    wRgb_Measure(thAutoMeasure);
  end);
  thAutoMeasure.Start;
{$ENDIF}
end;

procedure TfrmMainter.btnRunScriptClick(Sender: TObject);
var
  nCh, i : Integer;
{$IFDEF ISPD_L_OPTIC}
  nStartPos, nEndPos : Integer;
{$ENDIF}
begin
  nCh := cboScriptCh.ItemIndex;
{$IFDEF ISPD_L_OPTIC}

  if nCh > DefCommon.MAX_CH then begin
    if nCh = (DefCommon.MAX_CH + 1) then begin
      nStartPos := DefCommon.CH1;
      nEndPos   := DefCommon.MAX_JIG_CH;
    end
    else begin
      nStartPos := DefCommon.CH1 + 4;
      nEndPos   := DefCommon.MAX_JIG_CH + 4;
    end;

    for i := nStartPos to nEndPos do begin
      PasScr[i].RunMaintScript(Self.Handle,ScrMemo1);
    end;
  end
  else begin
    PasScr[nCh].RunMaintScript(Self.Handle,ScrMemo1);
  end;

{$ELSE}
  if nCh > Common.SystemInfo.ChCountUsed then begin
    for i := 0 to Pred(Common.SystemInfo.ChCountUsed) do begin
      PasScr[i].RunMaintScript(Self.Handle,ScrMemo1);
    end;
  end
  else begin
    PasScr[nCh].RunMaintScript(Self.Handle,ScrMemo1);
  end;
{$ENDIF}
end;

procedure TfrmMainter.btnAutoFrontClick(Sender: TObject);
var
nCh : integer;
begin
  nCh := cboChannelFrobe.ItemIndex;
  if (nCh = -1) or (nCh > DefCommon.MAX_CH) then Exit;
  ThreadStartDio(procedure begin
    ControlDio.ProbeForward(nCh);
  end);
end;

procedure TfrmMainter.btnAutoFrontPreOCClick(Sender: TObject);
var
nCH  : Integer;
begin
  nCh := cboChannelFrobePreOC.ItemIndex;
  if (nCh = -1) or (nCh > DefCommon.MAX_CH) then Exit;
  ThreadStartDio(procedure begin
    ControlDio.MovingProbe(nCh,true);
  end);

end;

procedure TfrmMainter.btnAutoPinBlackLockClick(Sender: TObject);
var
nCH  : Integer;
begin
  nCh := cboCHPinBllackPreOC.ItemIndex;
  if (nCh = -1) or (nCh > DefCommon.MAX_CH) then Exit;
  ThreadStartDio(procedure begin
    ControlDio.LockPinBlock(nCh);
  end);
end;

procedure TfrmMainter.btnAutoPinBlackUnlockClick(Sender: TObject);
var
nCH  : Integer;
begin
  nCh := cboCHPinBllackPreOC.ItemIndex;
  if (nCh = -1) or (nCh > DefCommon.MAX_CH) then Exit;
  ThreadStartDio(procedure begin
    ControlDio.UnlockPinBlock(nCh);
  end);
end;

procedure TfrmMainter.btnAutoVaccumOFFClick(Sender: TObject);
var
nCh : integer;
begin
  nCh := cboCHPreOC.ItemIndex;
  if (nCh = -1) or (nCh > DefCommon.MAX_CH) then Exit;
  ThreadStartDio(procedure begin
    ControlDio.VaccumOFF(nCh);
  end);
end;

procedure TfrmMainter.btnAutoVaccumONClick(Sender: TObject);
var
nCh : integer;
begin
  nCh := cboCHPreOC.ItemIndex;
  if (nCh = -1) or (nCh > DefCommon.MAX_CH) then Exit;
  ThreadStartDio(procedure begin
    ControlDio.VaccumON(nCh);
  end);
end;

procedure TfrmMainter.btnCarrierUnLockTopClick(Sender: TObject);
begin
  ThreadStartDio(procedure begin
    ControlDio.UnlockCarrier(DefCommon.CH_TOPGroup,true);
  end);
end;

procedure TfrmMainter.btnCarrierLockBottomClick(Sender: TObject);
begin
  ThreadStartDio(procedure begin
    ControlDio.LockCarrier(DefCommon.CH_BOTTOMGroup,true);
  end);
end;

procedure TfrmMainter.btnCarrierLockTopClick(Sender: TObject);
begin
  ThreadStartDio(procedure begin
    ControlDio.LockCarrier(DefCommon.CH_TOPGroup,True);
  end);
end;

procedure TfrmMainter.btnCarrierUnLockBottomClick(Sender: TObject);
begin
  ThreadStartDio(procedure begin
    ControlDio.UnlockCarrier(DefCommon.CH_BOTTOMGroup,True);
  end);
end;

procedure TfrmMainter.btnClampUpStageBClick(Sender: TObject);
begin
//  ThreadStartDio(procedure begin
//    ControlDio.ContactDown(DefCommon.CH_STAGE_B);
//  end);
end;

procedure TfrmMainter.btnClampUpStageAClick(Sender: TObject);
begin
//  ThreadStartDio(procedure begin
//    ControlDio.ContactDown(DefCommon.CH_STAGE_A);
//  end);
end;



procedure TfrmMainter.btnCloseClick(Sender: TObject);
begin
  if m_bChangeZAxisValue then SaveZAsixValue;
  
  Close;
end;



procedure TfrmMainter.btnControlPlcClick(Sender: TObject);
var
  nCh : Integer;
begin
  nCh := cboChannelPg.ItemIndex;
  if nCh = -1 then Exit;

//  if nCh in [8,9] then begin
//    if PlcCtl.PlcType = defPlc.PLC_KIND_TYPE_VH_VACUUM then begin
//      if nCh = 8 then begin
//        nPlcCh := defPlc.PLC_WRITE_C_VACUUM_A;
//      end
//      else begin
//        nPlcCh := defPlc.PLC_WRITE_C_VACUUM_B;
//      end;
//    end
//    else begin
//      if nCh = 8 then begin
//        nPlcCh := defPlc.PLC_WRITE_VACUUM_A;
//      end
//      else begin
//        nPlcCh := defPlc.PLC_WRITE_VACUUM_B;
//      end;
//    end;
//  end
//  else begin
//    case nCh of
//      0 : nPlcCh := defPlc.PLC_WRITE_CUP_1;  // Clamp UP과 Vaccum 과 Address 같아 따로 사용 안함.
//      1 : nPlcCh := defPlc.PLC_WRITE_CUP_2;
//      2 : nPlcCh := defPlc.PLC_WRITE_CUP_3;
//      3 : nPlcCh := defPlc.PLC_WRITE_CUP_4;
//      4 : nPlcCh := defPlc.PLC_WRITE_CUP_5;
//      5 : nPlcCh := defPlc.PLC_WRITE_CUP_6;
//      6 : nPlcCh := defPlc.PLC_WRITE_CUP_7;
//      7 : nPlcCh := defPlc.PLC_WRITE_CUP_8
//      else begin
//        nPlcCh := 0;
//      end;
//    end;
//  end;
//  if PlcCtl.PlcType <> defPlc.PLC_KIND_TYPE_MANUAL then begin
//    // Contact이 되어 있지 않는 경우. Power Off 한 뒤에
//    if (PlcCtl.m_nWriteData and nPlcCh) > 0 then begin
//      // Contact가 안되어 있으면 Contact을 하고 Power On을 하자.
//      plcCtl.writePlc(nPlcCh,True);
//      btnControlPlc.Caption := 'CLAMP DOWN';
//    end
//    else begin
//      plcCtl.writePlc(nPlcCh);
//      btnControlPlc.Caption := 'CLAMP UP';
//    end;
//  end
//  else begin
//    // Contact이 되어 있지 않는 경우. Power Off 한 뒤에
//    if (PlcCtl.m_nWriteData and nPlcCh) = 0 then begin
//      // Contact가 안되어 있으면 Contact을 하고 Power On을 하자.
//      plcCtl.writePlc(nPlcCh);
//      btnControlPlc.Caption := 'VACUUM OFF';
//    end
//    else begin
//      plcCtl.writePlc(nPlcCh,True);
//      btnControlPlc.Caption := 'VACUUM ON';
//    end;
//  end;
end;


procedure TfrmMainter.btnIonizerStartClick(Sender: TObject);
begin
  if DaeIonizer[cboChannelIonlzer.ItemIndex] <> nil then
      DaeIonizer[cboChannelIonlzer.ItemIndex].SendRun;
end;

procedure TfrmMainter.btnIonizerStopClick(Sender: TObject);
begin
  if DaeIonizer[cboChannelIonlzer.ItemIndex] <> nil then
      DaeIonizer[cboChannelIonlzer.ItemIndex].SendStop;
end;

procedure TfrmMainter.btnLampOnOff12Click(Sender: TObject);
begin
    if ControlDio.ReadOutSig(DefDio.OUT_CH_1_2_LAMP_OFF)  then begin
      ControlDio.LampOnOff(DefCommon.CH_TOP,True);
      btnLampOnOff12.Caption := 'CH 1,2 LAMP ON';
    end
    else begin
      ControlDio.LampOnOff(DefCommon.CH_TOP,False);
      btnLampOnOff12.Caption := 'CH 1,2 LAMP OFF';

    end;
end;

procedure TfrmMainter.btnLampOnOff34Click(Sender: TObject);
begin
    if ControlDio.ReadOutSig(DefDio.OUT_CH_3_4_LAMP_OFF)  then begin
      ControlDio.LampOnOff(DefCommon.CH_BOTTOM,True);
      btnLampOnOff34.Caption := 'CH 3,4 LAMP ON';
    end
    else begin
      ControlDio.LampOnOff(DefCommon.CH_BOTTOM,False);
      btnLampOnOff34.Caption := 'CH 3,4 LAMP OFF';
    end;
end;


{$IFDEF PG_DP860}
procedure TfrmMainter.GetPgTxData(nPgNo: Integer; sLocal,sRemote: string; sMsg: string);
var
  sDebug : string;
begin
  sMsg := StringReplace(sMsg, #$0D, '#', [rfReplaceAll]); // change #$0D to '#'
  sDebug := FormatDateTime('[hh:mm:ss.zzz] ',Now) + Format('CH%d TX[%s>%s]: (%s)',[nPgNo+1, sLocal,sRemote, sMsg]);
  mmCommPg.Lines.Add(sDebug);
end;

procedure TfrmMainter.GetPgRxData(nPgNo: Integer; sLocal,sRemote: string; sMsg: string);
var
  sDebug : string;
begin
  sMsg := StringReplace(sMsg, #$0D, '#', [rfReplaceAll]); // change #$0D to '#'
  sDebug := FormatDateTime('[hh:mm:ss.zzz] ',Now) + Format('CH%d RX[%s<%s]: (%s)',[nPgNo+1, sLocal,sRemote, sMsg]);
  mmCommPg.Lines.Add(sDebug);
end;
{$ENDIF}

function TfrmMainter.Find_Gray_index_Near_Target_1(fDBV, Target_Lv: Double): TArray<Double>;
var
 output : TArray<Double>;
Lv_Gray_per_band: TArray<Double>;
fTop_diff, fBottom_diff: double;
nGray,nIndex_gray: Integer;
begin
  SetLength(Lv_Gray_per_band,512);
  SetLength(output,2);

  Lv_Gray_per_band := Make_reference_All_DBV_Gray_Data(fDBV);

//  CopyMemory(@Lv_Gray_per_band,Make_reference_All_DBV_Gray_Data(fDBV),512*sizeof(Lv_Gray_per_band[0]));
  for nIndex_gray := 0 to 511 do begin
    if Lv_Gray_per_band[nIndex_gray] < Target_Lv then Break;
  end;

  if (nIndex_gray > 0) or (nIndex_gray <= 511) then begin
    fTop_diff := Abs(Lv_Gray_per_band[nIndex_gray - 1] - Target_Lv);
    fBottom_diff := Abs(Target_Lv - Lv_Gray_per_band[nIndex_gray]);
    if fTop_diff >= fBottom_diff then
    else  nIndex_gray := nIndex_gray -1;

    output[0] := nIndex_gray;
    output[1] := Lv_Gray_per_band[nIndex_gray];

    Result := output;

  end
  else begin
    output[0] := 0;
    output[1] := -1;
    Result := output;
  end;

  SetLength(Lv_Gray_per_band, 0);
end;

procedure TfrmMainter.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  nCh : integer;
begin
  if Mutex <> nil then
    Mutex.Free;
//  if DaeIonizer[0] <> nil then begin
//    DaeIonizer[0].IsIgnoreNg:= True;
//    DaeIonizer[0].OnRevIonizerData:= nil;
//  end;
  if UdpServerPG <> nil then begin
    for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if PG[nCh] <> nil then begin
        PG[nCh].IsMainter := False;
        PG[nCh].OnRxMaintEventPG := nil;
        PG[nCh].OnTxMaintEventPG := nil;
      end;
    end;

  end;
  for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if advstrngrdDataView[nCh] <> nil then begin
      advstrngrdDataView[nCh].Free;
      advstrngrdDataView[nCh] := nil;
    end;
  end;

//  if CtrlCa410 <> nil then begin
//    CtrlCa410.Free;
//    CtrlCa410 := nil;
//  end;
end;

procedure TfrmMainter.AddItemsInCbo;
var
  TempList : TSearchRec;
begin
  cboModelType.Items.Clear;
  if FindFirst(Common.Path.UserCal + '\*', faAnyFile, TempList) = 0 then begin
    repeat
      if ((TempList.attr and faDirectory) = faDirectory) and
         not (TempList.Name = '.') and
         not (TempList.Name = '..') then
      begin
        if Trim(TempList.Name) = 'User_Cal_Log' then Continue;
        cboModelType.Items.Add(TempList.Name);
      end;
    until FindNext(TempList) <> 0;
  end;
  FindClose(TempList);
end;

procedure TfrmMainter.BlueClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;
PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_4);
end;

procedure TfrmMainter.AddCboCsvData;
var
  TempList : TSearchRec;
  sCurDir  : string;
begin
  cboCalData.Items.Clear;
  if cboModelType.Items.Count < 1 then Exit;

  sCurDir := Common.Path.UserCal + cboModelType.Items[cboModelType.ItemIndex];

  if FindFirst(sCurDir + '\*.csv', faAnyFile, TempList) = 0 then begin
    repeat
      cboCalData.Items.Add(TempList.Name);
    until FindNext(TempList) <> 0;
  end;
  FindClose(TempList);
end;


procedure TfrmMainter.LoadOptIni(sDir: string);
var
  fSys        : TIniFile;
  i : Integer;
  sCalFile : string;
begin
  fSys := TIniFile.Create(Common.Path.UserCal + sDir + '\OcConfig.ini');
  try
    pnlMCh1.Caption := fSys.ReadString('CA310_USER_CAL','CAL_MEMORY_CH1','1');
    edAging_Cal.Text := fSys.ReadString('CA310_USER_CAL','AGING_TIME','600');
    edRty_Cal.Text  := fSys.ReadString('CA310_USER_CAL','VERIFY_CNT','3');
    edRgbwMAging.Text := fSys.ReadString('CA310_USER_CAL','AGING_RGBWM','0');

    if cboCalData.Items.Count > 0 then begin
      sCalFile := fSys.ReadString('CA310_USER_CAL','SEL_CAL_FILE','');
      if sCalFile <> '' then begin
        for i := 0 to Pred(cboCalData.Items.Count) do begin
          if cboCalData.Items[i] = sCalFile then begin
            cboCalData.ItemIndex := i;
            Break;
          end;
        end;
      end;
    end;
  finally
    fSys.Free;
  end;
{$IFDEF CA410_USE}
  Common.OpticInfo.CalMemCh[DefCaSdk.IDX_WHITE] := StrToIntDef(pnlMCh1.Caption,1);
  Common.OpticInfo.CalAgingTime := StrToIntDef(edAging_Cal.Text,600);
  Common.OpticInfo.CalRetryCnt := StrToIntDef(edRty_Cal.Text,3);
{$ENDIF}
end;


procedure TfrmMainter.LoadOptCsv(sFileName: string);
var
  sCurFile : string;
  sTemp    : string;
  dTemp    : Single;
  i        : Integer;
begin

  sCurFile := Common.Path.UserCal + cboModelType.Items[cboModelType.ItemIndex] + '\' + sFileName;
  if FileExists(sCurFile) then  begin
    try
      gridTarget.LoadFromCSV(sCurFile);
{$IFDEF CA410_USE}
      for i := DefCaSdk.IDX_RED to  DefCaSdk.IDX_MAX do begin
        sTemp      := gridTarget.Cells[1,i+1];
        dTemp      := StrToFloatDef(sTemp,0.0);
        gridTarget.Cells[1,i+1] := Format('%0.4f',[dTemp]);

        sTemp      := gridTarget.Cells[2,i+1];
        dTemp      := StrToFloatDef(sTemp,0.0);
        gridTarget.Cells[2,i+1] := Format('%0.4f',[dTemp]);

        sTemp      := gridTarget.Cells[3,i+1];
        dTemp      := StrToFloatDef(sTemp,0.0);
        gridTarget.Cells[3,i+1] := Format('%0.1f',[dTemp]);
      end;
{$ENDIF}
{$IFDEF CA310_USE}
      for i := DefCa310.IDX_RED to  DefCa310.IDX_MAX do begin
        sTemp      := gridTarget.Cells[1,i+1];
        dTemp      := StrToFloatDef(sTemp,0.0);
        gridTarget.Cells[1,i+1] := Format('%0.4f',[dTemp]);

        sTemp      := gridTarget.Cells[2,i+1];
        dTemp      := StrToFloatDef(sTemp,0.0);
        gridTarget.Cells[2,i+1] := Format('%0.4f',[dTemp]);

        sTemp      := gridTarget.Cells[3,i+1];
        dTemp      := StrToFloatDef(sTemp,0.0);
        gridTarget.Cells[3,i+1] := Format('%0.1f',[dTemp]);
      end;
{$ENDIF}
    except
    end;
  end;
end;


procedure TfrmMainter.ShowNgMessage(sMessage: string);
begin
  if frmNgMsg = nil then begin
    frmNgMsg  := TfrmNgMsg.Create(nil);
  end;

  frmNgMsg.lblShow.Caption := sMessage;
  frmNgMsg.Show; //ShowModal;
end;

procedure TfrmMainter.ShowUsercalItems;
begin
  cboModelType.Clear;
  // Add Items To combo box of model type.
  AddItemsInCbo;
  if cboModelType.Items.Count > 0 then begin
    cboModelType.ItemIndex :=  Common.OpticInfo.CalModelType;
    AddCboCsvData;
    LoadOptIni(cboModelType.Items[cboModelType.ItemIndex]);
  end;
  if cboCalData.Items.Count > 0 then begin
    LoadOptCsv(cboCalData.Items[cboCalData.ItemIndex]);
  end;
end;



{$IFDEF PG_AF9}
procedure TfrmMainter.AF9ApiLogCall(nPgNo: Integer; sMsg: string);
var
  sDebug : string;
begin
  sDebug := FormatDateTime('[hh:mm:ss.zzz] ',Now) + Format('CH%d: %s Call',[nPgNo+1,sMsg]);
  mmCommPg.Lines.Add(sDebug);
end;

procedure TfrmMainter.AF9ApiLogReturn(nPgNo: Integer; sMsg: string);
var
  sDebug : string;
begin
  sDebug := FormatDateTime('[hh:mm:ss.zzz] ',Now) + Format('CH%d: %s',[nPgNo+1, sMsg]);
  mmCommPg.Lines.Add(sDebug);
end;
{$ENDIF}

procedure TfrmMainter.FormCreate(Sender: TObject);
var
  nCh, i : integer;
  sTemp   : string;
  frmTemp: TfrmECSStatus;
begin
  cboChannelPg.Items.clear;
  cboScriptCh.Items.clear;
  cboChannelFrobe.Items.Clear;
  Button2.Visible := False;

//  CtrlCa410 := TControlCa410.Create(self.Handle,Self.Handle,Common.TestModelInfoFLOW.Ca410MemCh+1);
  cboCa310Channel.Items.Clear;
  for i := 0 to 99 do begin
    sTemp := Format('%d',[i]);
    cboCa310Channel.Items.Add(sTemp);
  end;
  cboCa310Channel.ItemIndex := Common.SystemInfo.R2RCa410MemCh;

  cboBandCount.Items.Clear;
  cboBandCount.Items.Add('ALLBand');
  for i := 1 to 32 do begin
    sTemp := Format('Band %d',[i]);
    cboBandCount.Items.Add(sTemp);
  end;
  cboBandCount.ItemIndex := 0;

  cboGrayRGB.Items.Clear;
  for i := 511 downto 0 do begin
    sTemp := Format('%d',[i]);
    cboGrayRGB.Items.Add(sTemp);
  end;
  cboGrayRGB.ItemIndex := 0;
  for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
    sTemp := Format('%d',[nCh + 1]);
    cboChannelPg.Items.Add(sTemp);
    cboChannelFrobe.Items.Add(sTemp);
    cboScriptCh.Items.Add(sTemp);
  end;

  cboScriptCh.Items.Add('Stage A(1,2,3,4)');
  cboScriptCh.Items.Add('Stage B (5,6,7,8)');

  cboChannelPg.ItemIndex := 0;
  PG[DefCommon.CH1].IsMainter := True;
  PG[DefCommon.CH2].IsMainter := False;
  PG[DefCommon.CH3].IsMainter := False;
  PG[DefCommon.CH4].IsMainter := False;

  cboScriptCh.ItemIndex := 0;
//  if UdpServer is TUdpServerVh then begin
//    UdpServer.OnRevDataForMaint := GetPgRevData;
//    UdpServer.IsMainter := True;
//  end;

    if RzPageControl1.ActivePage = TabSheet1 then begin
      for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
        Pg[nCh].IsMainter := True;
        case Common.SystemInfo.PG_TYPE of
          {$IFDEF PG_AF9}
          DefPG.PG_TYPE_AF9 : begin
            Pg[nCh].OnTxMaintEventAF9 := AF9ApiLogCall;
            Pg[nCh].OnRxMaintEventAF9 := AF9ApiLogReturn;
          end;
          {$ENDIF}
          {$IFDEF PG_DP860}
          DefPG.PG_TYPE_DP860 : begin
            Pg[nCh].OnTxMaintEventPG := GetPgTxData;
            Pg[nCh].OnRxMaintEventPG := GetPgRxData;
          end;
          {$ENDIF}
        end;
      end;
    end
    else begin
      for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
        Pg[nCh].IsMainter := False;
        case Common.SystemInfo.PG_TYPE of
          {$IFDEF PG_AF9}
          DefPG.PG_TYPE_AF9 : begin
            Pg[nCh].OnTxMaintEventAF9 := nil;
            Pg[nCh].OnRxMaintEventAF9 := nil;
          end;
          {$ENDIF}
          {$IFDEF PG_DP860}
          DefPG.PG_TYPE_DP860 : begin
            Pg[nCh].OnTxMaintEventPG := nil;
            Pg[nCh].OnRxMaintEventPG := nil;
          end;
          {$ENDIF}
        end;
      end;
    end;

  if Common.SystemInfo.OCType = DefCommon.OCType  then
        grpDioCtlPreOC.Visible := False
  else  grpDioCtlPreOC.Visible := True;




  tabIoMap.TabVisible := True;

  tabLoaderPlcComm.TabVisible := True;

  RzPageControl1.ActivePageIndex:= 0;

  POcbIpList;
//
//  if DongaHandBcr <> nil then begin            // Maint 창에서 BCR SCAN 시 Access violation 생성하여 삭제
//    DongaHandBcr.OnRevBcrDataMaint := getBcrData;
//  end;

//  if DaeIonizer[0] <> nil then begin
//    DaeIonizer[0].OnRevIonizerData:= IonizerReadData;
//  end
//  else begin
//
//  end;

  if Common.SystemInfo.OCType = DefCommon.OCType  then begin
    btnShutterUpCH12.Visible := False;
    btnShutterUpCH34.Visible := False;
    btnShutterDnCH12.Visible := False;
    btnShutterDnCH34.Visible := False;
  end
  else begin
    btnShutterUpCH12.Visible := True;
    btnShutterUpCH34.Visible := True;
    btnShutterDnCH12.Visible := True;
    btnShutterDnCH34.Visible := True;
  end;

  GetLocalIpList;
  m_bStopCa310Cal := False;
  chkUseTowerLamp.Checked:= ControlDio.UseTowerLamp;
  MakeDIOSignal;



//Adds 20 Points with random value from 0 to 50 to the first Pane (0)
//with the first Series (0)
// for i := 0 to 511 do begin
//   AdvChartView1.Panes[0].Series[0].AddSinglePoint(Random(i));
   //Set Range from 0 to 20
//   AdvChartView1.Panes[0].Range.RangeFrom := 0;
//   AdvChartView1.Panes[0].Range.RangeTo := 511;

   //Set Auto Display Range to arEnabled
//   AdvChartView1.Panes[0].Series[0].Autorange := AutoRange.arEnabled;
// end;
  Mutex := TMutex.Create;
  for I := DefCommon.CH1 to DefCommon.CH4 do begin
    advstrngrdDataView[i] := TAdvStringGrid.Create(Self);
    advstrngrdDataView[i].Clear;
    advstrngrdDataView[i].Parent := pnlDataView;
    advstrngrdDataView[i].Font.Name := 'Tahoma';
    advstrngrdDataView[i].Top := 0;
    advstrngrdDataView[i].Left := i * 360;
    advstrngrdDataView[i].Width  := 360;
    advstrngrdDataView[i].Height := 708;
    advstrngrdDataView[i].Align := TAlign.alNone;
    advstrngrdDataView[i].ColCount := 6;
    advstrngrdDataView[i].RowCount := 2048;
    advstrngrdDataView[i].FixedCols := 0;
    advstrngrdDataView[i].ScrollBars := TScrollStyle.ssBoth;
//    advstrngrdDataView[i].AutoSizeColumns(true);
  end;

  for I := 0 to 23 do begin
    pnlR2RData[i] := TEdit.Create(self);
    pnlR2RData[i].Parent := Panel1;
    pnlR2RData[i].Name := format('pnlR2RData%d',[i +1]);
    if i < 12 then begin
      pnlR2RData[i].Left := 137 + (255 *(i div 3));
      pnlR2RData[i].Top := 53 + (27 *(i mod 3));
    end
    else begin
      pnlR2RData[i].Left := 137 + (255 *((i-12) div 3));
      pnlR2RData[i].Top := 135 + (27 *(i mod 3));
    end;

    pnlR2RData[i].Height := 27;
    pnlR2RData[i].Width := 120;
    pnlR2RData[i].Font.Size := 12;
    pnlR2RData[i].Tag := i;
    pnlR2RData[i].Font.Color  := clBlack;
    pnlR2RData[i].Text := '';
    pnlR2RData[i].StyleElements := [];
  end;

  //frmTemp:= TfrmMainter_PLC.Create(self);
  frmTemp:= TfrmECSStatus.Create(self);
  frmTemp.BorderStyle:= bsNone;
  frmTemp.Parent:= tabLoaderPlcComm;
  frmTemp.SetMode(1); //Mainter Mode
  frmTemp.Align:= alClient;
  frmTemp.Show;

//  ControlDio.DisplayIo;


  //tbCa310AutoCorr.TabVisible := True;
  ShowUsercalItems;   // Added by KTS 2022-08-09 오후 12:01:08
end;


procedure TfrmMainter.getBcrData(sScanData: string);
begin
  mmHandBcr.Lines.Add(sScanData);
end;

procedure TfrmMainter.GetLocalIpList;
type
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  phe : PHostEnt;
  pptr : PaPInAddr;
  Buffer : array[0..63] of AnsiChar;
  i : Integer;
  WSAData : TWSAData;
  a : TStringList;
//  sRet : string;
begin

  WSAStartup(MakeWord(2,2),WSAData);
  a := TStringList.Create ;
  try
    a.Clear;
    lstLocalIp.Items.Clear;
    gethostname(Buffer, SizeOf(Buffer));
    phe := gethostbyname(buffer);
    if phe = nil then Exit;
    pptr := papinaddr(phe^.h_addr_list);
    i := 0;
    while pptr^[i] <> nil do begin
      a.Add(inet_ntoa(pptr^[i]^));
      Inc(i);
    end;
    WSACleanup;
    for i := 0 to Pred(a.Count) do begin
      lstLocalIp.Items.Add(a[i]);
    end;
  finally
    a.Free;
  end;
end;

procedure TfrmMainter.GetPgRevData(nPgNo, nLength: Integer; RevData: array of byte);
var
  sDebug, sTemp : string;
  i : Integer;
begin
  sTemp := '';
  for i := 0 to Pred(nLength) do sTemp := sTemp + Format('%0.2x ',[RevData[i]]);

  sDebug := FormatDateTime('[hh:mm:ss.zzz]',Now) + Format('Ch %d, Rev : ( Length : %d, Data (%s))',[nPgNo+1, nLength , sTemp ]);
  mmCommPg.Lines.Add(sDebug);
end;

function TfrmMainter.GetProbeNum: Integer;
var
i : integer;
begin
  if (rdoProbe1.Checked) then Result := 0
  else if (rdoProbe2.Checked) then Result := 1
  else if (rdoProbe3.Checked) then Result := 2
  else if (rdoProbe4.Checked) then Result := 3;

end;



procedure TfrmMainter.GetR2RData(nCH : Integer);
var
i,j : Integer;
begin
  if DongaGmes <> nil then begin
    for I := 0 to 23 do begin
      for j := 0 to 23 do begin
        if R2REODSNAME[i] = PasScr[nCH].FR2ROC_EODSname[j] then begin
          pnlR2RData[i].Text := PasScr[nCH].FR2ROC_EODSData[j];
          Break;
        end;
      end;
    end;
  end;
end;

procedure TfrmMainter.gridTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = vkReturn then Key := vkTab;

end;


procedure TfrmMainter.IonizerReadData(bConnect: Boolean; sReadData: String);
begin
  //
  if bConnect then begin
    memoIonizer.Lines.Add(FormatDateTime('HH:NN:SS.ZZZ ', Now) + sReadData);
  end
  else begin
    memoIonizer.Lines.Add('Disconnect ' + sReadData);
  end;

end;

procedure TfrmMainter.LoadZAsixValue;

begin

end;

procedure TfrmMainter.SaveZAsixValue;

begin

end;


procedure TfrmMainter.MaintFlashPucDataWrite(nCh: Integer);
begin

end;

procedure TfrmMainter.MakeDIOSignal;
var
  i, nDiv, nMod, nCh, nMaxCnt,nInterval: Integer;
  sTemp : string;
begin
  // for In --------------------------------------------
  nMaxCnt := DefDio.MAX_IO_CNT + Common.SystemInfo.DIOType*8;
  //nDiv := DefDio.MAX_IO_CNT div 2; //defPlc.MAX_IN_CNT div 2;
  nDiv := 144 div 3;
  for i := 0 to Pred(nMaxCnt) do begin
    // Number.
    nInterval := 0;
    pnlIn[i] := TRzPanel.Create(nil);
    pnlIn[i].Parent := grpDioIn;
    if i < nDiv then                             pnlIn[i].Left   := 10
    else if (i >= nDiv) and (i < 2 *nDiv)  then  pnlIn[i].Left   := 300
    else                                         pnlIn[i].Left   := 430;

    pnlIn[i].BevelWidth := 1;
    pnlIn[i].FlatColor := clBlack;
    pnlIn[i].BorderInner  := TframeStyleEx(fsNone);
    pnlIn[i].BorderOuter  := TframeStyleEx(fsFlat);
    pnlIn[i].Width        := 30;
    pnlIn[i].Height       := 13;
    pnlIn[i].Caption      := Format('%0.2d',[i]);//Common.DecToOct(i);
    pnlIn[i].Visible      := True;
    pnlIn[i].Font.Size      := 7;

    if i in [0, nDiv,2*nDiv] then begin
      pnlIn[i].Top := 16;
    end
    else begin
      if i mod 8 = 0  then nInterval := 2;
      if Common.SystemInfo.DIOType <> 0 then begin
        pnlIn[i].Top := pnlIn[i-1].Top + pnlIn[i-1].Height + nInterval;
      end
      else begin
        pnlIn[i].Top := pnlIn[i-1].Top + pnlIn[i-1].Height + 1 + nInterval;;
      end;
    end;
    // Led.
    ledIn[i] := ThhALed.Create(nil);
    ledIn[i].Parent := grpDioIn;
    ledIn[i].Left   := pnlIn[i].Left + pnlIn[i].Width + 3;
    ledIn[i].Top    := pnlIn[i].Top -1;
    ledIn[i].Height := 13;
    ledIn[i].LEDStyle := LEDSqSmall;
    ledIn[i].FalseColor := clRed;
    ledIn[i].TrueColor  := clLime;
    ledIn[i].Blink := False;
    ledIn[i].Visible := True;
    ledIn[i].Value := False;

    // Items.
    pnlDioIn[i] := TRzPanel.Create(nil);
    pnlDioIn[i].Parent := grpDioIn;
    pnlDioIn[i].Left   := ledIn[i].Left + ledIn[i].Width + 3;
    pnlDioIn[i].BevelWidth := 1;
    pnlDioIn[i].Top           := pnlIn[i].Top;
    pnlDioIn[i].FlatColor     := clBlack;
    pnlDioIn[i].BorderInner   := TframeStyleEx(fsNone);
    pnlDioIn[i].BorderOuter   := TframeStyleEx(fsFlat);
    pnlDioIn[i].Width         := 200;
    pnlDioIn[i].Height        := pnlIn[i].Height;
    pnlDioIn[i].Visible       := True;
    pnlDioIn[i].Font.Name     := 'Tahoma';
    pnlDioIn[i].Font.Style    := [];
    pnlDioIn[i].Font.Size     := 6;
    sTemp := '';
    if Common.SystemInfo.OCType = DefCommon.OCType  then begin

      case i of

        DefDio.IN_FAN_1_EXHAUST : sTemp := 'FAN #1 OUT';
        DefDio.IN_FAN_2_INTAKE : sTemp := 'FAN #2 IN';
        DefDio.IN_FAN_3_EXHAUST : sTemp := 'FAN #3 OUT';
        DefDio.IN_FAN_4_INTAKE : sTemp := 'FAN #3 IN';
        DefDio.IN_UNDEFINED_4 : sTemp := '';
        DefDio.IN_UNDEFINED_5 : sTemp := '';
        DefDio.IN_UNDEFINED_6 : sTemp := '';
        DefDio.IN_UNDEFINED_7 : sTemp := '';


        DefDio.IN_EMO_SWITCH : sTemp := 'EMO SWITCH';
        DefDio.IN_CH_1_2_DOOR_LEFT_OPEN : sTemp := 'CH #1 #2 LEFT DOOR[Reversal]';
        DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN : sTemp := 'CH #1 #2 RIGHT DOOR[Reversal]';
        DefDio.IN_CH_3_4_DOOR_LEFT_OPEN : sTemp := 'CH #3 #4 LEFT DOOR[Reversal]';
        DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN : sTemp := 'CH #3 #4 RIGHT DOOR[Reversal]';
        DefDio.IN_MC_MONITORING : sTemp := 'MC MONITORING';
        DefDio.IN_UNDEFINED_14 : sTemp := '';
        DefDio.IN_UNDEFINED_15 : sTemp := '';

        DefDio.IN_TEMPERATURE_ALARM : sTemp := 'TEMPERATURE ALARM';
        DefDio.IN_UNDEFINED_17 : sTemp := '';
        DefDio.IN_UNDEFINED_18 : sTemp := '';
        DefDio.IN_UNDEFINED_19 : sTemp := '';
        DefDio.IN_UNDEFINED_20 : sTemp := '';
        DefDio.IN_UNDEFINED_21 : sTemp := '';
        DefDio.IN_UNDEFINED_22 : sTemp := '';
        DefDio.IN_UNDEFINED_23 : sTemp := '';

        DefDio.IN_CYL_PRESSURE_GAUGE : sTemp := 'CYL PRESSURE GAUGE';
        DefDio.IN_UNDEFINED_25 : sTemp := '';
        DefDio.IN_UNDEFINED_26 : sTemp := '';
        DefDio.IN_UNDEFINED_27 : sTemp := '';
        DefDio.IN_UNDEFINED_28 : sTemp := '';
        DefDio.IN_UNDEFINED_29 : sTemp := '';
        DefDio.IN_UNDEFINED_30 : sTemp := '';
        DefDio.IN_UNDEFINED_31 : sTemp := '';


        DefDio.IN_CH_1_CARRIER_SENSOR .. DefDio.IN_CH_4_CARRIER_LOCK_4 : begin
          nMod := (i - DefDio.IN_CH_1_CARRIER_SENSOR) mod 16;
          nCh := (i - DefDio.IN_CH_1_CARRIER_SENSOR) div 16;  // 4 signal이 한묶음이라 4로 나누자.
          case nMod of
            0 : sTemp := Format('CH %d CARRIER SENSOR',[nCh + 1]);
            1 : sTemp := Format('CH %d PROBE FORWARD SENSOR[Reversal]',[nCh + 1]);
            2 : sTemp := Format('CH %d PROBE BACKWARD SENSOR[Reversal]',[nCh + 1]);
            3 : sTemp := Format('CH %d PROBE UP SENSOR[Reversal]',[nCh + 1]);
            4 : sTemp := Format('CH %d PROBE DOWN SENSOR[Reversal]',[nCh + 1]);
            5 : sTemp := '';
            6 : sTemp := '';
            7 : sTemp := '';


            8 : sTemp :=  Format('CH %d CARRIER Clamp UP SENSOR #1',[nCh + 1]);
            9 : sTemp :=  Format('CH %d CARRIER Clamp DN SENSOR #1'  ,[nCh + 1]);
            10 : sTemp := Format('CH %d CARRIER Clamp UP SENSOR #2',[nCh + 1]);
            11 : sTemp := Format('CH %d CARRIER Clamp DN SENSOR #2'  ,[nCh + 1]);
            12 : sTemp := Format('CH %d CARRIER Clamp UP SENSOR #3'  ,[nCh + 1]);
            13 : sTemp := Format('CH %d CARRIER Clamp DN SENSOR #3'  ,[nCh + 1]);
            14 : sTemp := Format('CH %d CARRIER Clamp UP SENSOR #4'  ,[nCh + 1]);
            15 : sTemp := Format('CH %d CARRIER Clamp DN SENSOR #4'  ,[nCh + 1]);

//            16 : sTemp := '';
//            17 : sTemp := '';
//            18 : sTemp := '';
//            19 : sTemp := '';
//            20 : sTemp := '';
//            21 : sTemp := '';
//            22 : sTemp := '';
//            23 : sTemp := '';

          end;
        end;
      end;

    end
    else begin
      case i of

        DefDio.IN_FAN_1_EXHAUST : sTemp := 'FAN #1 OUT';
        DefDio.IN_FAN_2_INTAKE : sTemp := 'FAN #2 IN';
        DefDio.IN_FAN_3_EXHAUST : sTemp := 'FAN #3 OUT';
        DefDio.IN_FAN_4_INTAKE : sTemp := 'FAN #3 IN';
        DefDio.IN_GIB_CH_12_EMO_SWITCH  : sTemp := 'CH 1,2_EMO_SWITCH';
        DefDio.IN_GIB_CH_34_EMO_SWITCH  : sTemp := 'CH 3,4_EMO_SWITCH';
        DefDio.IN_GIB_CH_12_LIGHTCURTAIN : sTemp  := 'CH 1,2 LIGHT CURTAIN';
        DefDio.IN_GIB_CH_34_LIGHTCURTAIN : sTemp  := 'CH 3,4 LIGHT CURTAIN';


        DefDio.IN_GIB_CH_12_MUTING_LAMP    : sTemp := 'CH 1,2 MUTING LAMP';
        DefDio.IN_GIB_CH_34_MUTING_LAMP    : sTemp := 'CH 3,4 MUTING LAMP';
        DefDio.IN_GIB_CH_12_MC_MONITORING  : sTemp := 'CH 1,2 MC MONITORING';
        DefDio.IN_GIB_CH_34_MC_MONITORING  : sTemp := 'CH 3,4 MC MONITORING';
        DefDio.IN_GIB_TEMPERATURE_ALARM    : sTemp := 'TEMPERATURE ALARM';
        DefDio.IN_GIB_CH_12_ROBOT_SENSOR   : sTemp := 'CH 1,2 ROBOT Sensing';
        DefDio.IN_GIB_CH_34_ROBOT_SENSOR   : sTemp := 'CH 3,4 ROBOT Sensing';
        DefDio.IN_UNDEFINED_15             : sTemp := '';

        DefDio.IN_GIB_CYL_PRESSURE_GAUGE   : sTemp := 'CYL PRESSURE GAUGE';
        DefDio.IN_UNDEFINED_17 : sTemp := '';
        DefDio.IN_UNDEFINED_18 : sTemp := '';
        DefDio.IN_UNDEFINED_19 : sTemp := '';
        DefDio.IN_UNDEFINED_20 : sTemp := '';
        DefDio.IN_UNDEFINED_21 : sTemp := '';
        DefDio.IN_UNDEFINED_22 : sTemp := '';
        DefDio.IN_UNDEFINED_23 : sTemp := '';

        DefDio.IN_GIB_CH_1_CARRIER_SENSOR .. DefDio.IN_GIB_CH_4_PINBLOCK_CLOSE_DN_SENSOR : begin
          nMod := (i - DefDio.IN_GIB_CH_1_CARRIER_SENSOR) mod 8;
          nCh := (i - DefDio.IN_GIB_CH_1_CARRIER_SENSOR) div 8;
          case nMod of
            0 : sTemp := Format('CH %d CARRIER SENSOR',[nCh + 1]);
            1 : sTemp := Format('CH %d TILTING SENSOR',[nCh + 1]);
            2 : sTemp := Format('CH %d PINBLOCK OPEN SENSOR',[nCh + 1]);
            3 : sTemp := Format('CH %d PRESSURE GUAGE',[nCh + 1]);
            4 : sTemp := Format('CH %d PINBLOCK UNLOCK OFF SENSOR',[nCh + 1]);
            5 : sTemp := Format('CH %d PINBLOCK UNLOCK ON SENSOR',[nCh + 1]);
            6 : sTemp := Format('CH %d PINBLOCK CLOSE UP SENSOR',[nCh + 1]);
            7 : sTemp := Format('CH %d PINBLOCK CLOSE DN SENSOR',[nCh + 1]);

          end;

        end;
        DefDio.IN_GIB_CH_12_PROBE_UP_SENSOR    : sTemp := 'CH 1,2 PROBE UP SENSOR';
        DefDio.IN_GIB_CH_12_PROBE_DN_SENSOR    : sTemp := 'CH 1,2 PROBE DN SENSOR';
        DefDio.IN_GIB_CH_12_SHUTTER_UP_SENSOR  : sTemp := 'CH 1,2 SHUTTER UP SENSOR';
        DefDio.IN_GIB_CH_12_SHUTTER_DN_SENSOR  : sTemp := 'CH 1,2 SHUTTER DN SENSOR';
        DefDio.IN_GIB_CH_34_PROBE_UP_SENSOR    : sTemp := 'CH 3,4 PROBE UP SENSOR';
        DefDio.IN_GIB_CH_34_PROBE_DN_SENSOR    : sTemp := 'CH 3,4 PROBE DN SENSOR';
        DefDio.IN_GIB_CH_34_SHUTTER_UP_SENSOR  : sTemp := 'CH 3,4 SHUTTER UP SENSOR';
        DefDio.IN_GIB_CH_34_SHUTTER_DN_SENSOR  : sTemp := 'CH 3,4 SHUTTER DN SENSOR';

      end;
    end;

    pnlDioIn[i].Caption := sTemp;
  end;
  DisplayDio(True);

  nDiv := 144 div 3;
  for i := 0 to Pred(defDio.MAX_OUT_CNT) do begin
    // Number.
    nInterval := 0;
    pnlOut[i] := TRzPanel.Create(nil);
    pnlOut[i].Parent := grpDioOut;
    if i < nDiv then                                pnlOut[i].Left   := 10
    else if (i >= nDiv) and (i < 2 *nDiv)  then     pnlOut[i].Left   := 250
    else                                            pnlOut[i].Left   := 490;

    pnlOut[i].BevelWidth := 1;
    pnlOut[i].FlatColor := clBlack;
    pnlOut[i].BorderInner  := TframeStyleEx(fsNone);
    pnlOut[i].BorderOuter  := TframeStyleEx(fsFlat);
    pnlOut[i].Width        := 30;
    pnlOut[i].Height       := 13;
    pnlOut[i].Caption      := Format('%0.2d',[i]);//Common.DecToOct(i); //
    pnlOut[i].Visible      := True;
    pnlOut[i].Font.Size      := 7;

    if i mod 8 = 0  then nInterval := 2;
    if i in [0, nDiv,2*nDiv] then begin
      pnlOut[i].Top := 16;
    end
    else begin
      pnlOut[i].Top := pnlOut[i-1].Top + pnlOut[i-1].Height + 1 + nInterval;
    end;

    // Led.
    ledOut[i] := ThhALed.Create(nil);
    ledOut[i].Parent := grpDioOut;
    ledOut[i].Left   := pnlOut[i].Left + pnlOut[i].Width + 3;
    ledOut[i].Top    := pnlOut[i].Top-1;
    ledOut[i].LEDStyle := LEDSqSmall;
    ledOut[i].Height := 13;
    ledOut[i].FalseColor := clRed;
    ledOut[i].TrueColor  := clLime;
    ledOut[i].Blink := False;
    ledOut[i].Visible := True;
    ledOut[i].Value := False;

    // Items.
    pnlDioOut[i] := TRzPanel.Create(nil);
    pnlDioOut[i].Parent := grpDioOut;
    pnlDioOut[i].Left   := ledOut[i].Left + ledOut[i].Width + 3;
    pnlDioOut[i].BevelWidth := 1;
    pnlDioOut[i].Top     := pnlOut[i].Top;
    pnlDioOut[i].FlatColor := clBlack;
    pnlDioOut[i].BorderInner  := TframeStyleEx(fsNone);
    pnlDioOut[i].BorderOuter  := TframeStyleEx(fsFlat);
    pnlDioOut[i].Width        := 150;
    pnlDioOut[i].Height       := pnlOut[i].Height;
    pnlDioOut[i].Visible      := True;
    pnlDioOut[i].Font.Name     := 'Tahoma';
    pnlDioOut[i].Font.Style    := [];
    pnlDioOut[i].Font.Size     := 6;

    sTemp := '';

    if Common.SystemInfo.OCType = DefCommon.OCType  then begin

      case i of

        DefDio.OUT_CH_1_2_LAMP_OFF : sTemp := 'CH #1 #2 LAMP OFF';
        DefDio.OUT_CH_3_4_LAMP_OFF : sTemp := 'CH #3 #4 LAMP OFF';
        DefDio.OUT_CH_1_PG_POWER_OFF : sTemp := 'CH #1 PG POWER OFF';
        DefDio.OUT_CH_2_PG_POWER_OFF : sTemp := 'CH #2 PG POWER OFF';
        DefDio.OUT_CH_3_PG_POWER_OFF : sTemp := 'CH #3 PG POWER OFF';
        DefDio.OUT_CH_4_PG_POWER_OFF : sTemp := 'CH #4 PG POWER OFF';
        DefDio.OUT_UNDEFINED_6 : sTemp := '';
        DefDio.OUT_START_SW_LED : sTemp := 'START_SW';

        DefDio.OUT_CH_1_2_DOOR_LEFT_UNLOCK : sTemp := 'CH #1 #2 DOOR LEFT UNLOCK';
        DefDio.OUT_CH_1_2_DOOR_RIGHT_UNLOCK : sTemp := 'CH #1 #2 DOOR RIGHT UNLOCK';
        DefDio.OUT_CH_3_4_DOOR_LEFT_UNLOCK : sTemp := 'CH #3 #4 DOOR LEFT UNLOCK';
        DefDio.OUT_CH_3_4_DOOR_RIGHT_UNLOCK : sTemp := 'CH #3 #4 DOOR RIGHT UNLOCK';
        DefDio.OUT_RESET_SWITCH_LED : sTemp := 'REST SWITCH LED';
        DefDio.OUT_UNDEFINED_13 : sTemp := '';
        DefDio.OUT_UNDEFINED_14 : sTemp := '';
        DefDio.OUT_UNDEFINED_15 : sTemp := '';

        DefDio.OUT_TOWER_LAMP_RED : sTemp := 'TOWER LAMP RED';
        DefDio.OUT_TOWER_LAMP_YELLOW : sTemp := 'TOWER LAMP YELLOW';
        DefDio.OUT_TOWER_LAMP_GREEN : sTemp := 'TOWER LAMP GREEN';
        DefDio.OUT_BUZZER_1 : sTemp := 'BUZZER #1';
        DefDio.OUT_BUZZER_2 : sTemp := 'BUZZER #2';
        DefDio.OUT_BUZZER_3 : sTemp := 'BUZZER #3';
        DefDio.OUT_BUZZER_4 : sTemp := 'BUZZER #4';
        DefDio.OUT_UNDEFINED_23 : sTemp := '';

        DefDio.OUT_CH_1_2_ION_ONOFF_SOL : sTemp := 'CH #1 #2 ION ON/OFF SOL';
        DefDio.OUT_CH_3_4_ION_ONOFF_SOL : sTemp := 'CH #3 #4 ION ON/OFF SOL';
        DefDio.OUT_CH_1_2_BACK_DOOR_LAMPON : sTemp := 'CH #1 #2 BACK_DOOR_LAMP';
        DefDio.OUT_CH_3_4_BACK_DOOR_LAMPON : sTemp := 'CH #3 #4 BACK_DOOR_LAMP';
        DefDio.OUT_UNDEFINED_28 : sTemp := '';
        DefDio.OUT_UNDEFINED_29 : sTemp := '';
        DefDio.OUT_UNDEFINED_30 : sTemp := '';
        DefDio.OUT_UNDEFINED_31 : sTemp := '';


        DefDio.IN_CH_1_CARRIER_SENSOR .. DefDio.IN_CH_4_CARRIER_LOCK_4 : begin
          nMod := (i - DefDio.IN_CH_1_CARRIER_SENSOR) mod 16;
          nCh := (i - DefDio.IN_CH_1_CARRIER_SENSOR) div 16;  // 4 signal이 한묶음이라 4로 나누자.
          case nMod of
            0 : sTemp := Format('CH %d PROBE FORWARD SOL',[nCh + 1]);
            1 : sTemp := Format('CH %d PROBE BACKWARD SOL',[nCh + 1]);
            2 : sTemp := Format('CH %d PROBE UP SOL',[nCh + 1]);
            3 : sTemp := Format('CH %d PROBE DOWN SOL',[nCh + 1]);
            4 : sTemp := Format('CH %d CARRIER Clamp UP SOL',[nCh + 1]);
            5 : sTemp := Format('CH %d CARRIER Clamp DN SOL',[nCh + 1]);
            6 : sTemp := '';
            7 : sTemp := '';

            8 : sTemp := Format('CH %d PMIC_LASER_POINT',[nCh + 1]);
            9 : sTemp := Format('CH %d CENTER_LASER_POINT',[nCh + 1]);
            10 : sTemp := Format('CH %d PMIC_FAN_ON',[nCh + 1]);
            11 : sTemp := '';
            12 : sTemp := '';
            13 : sTemp := '';
            14 : sTemp := '';
            15 : sTemp := '';



          end;
        end;


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
        DefDio.OUT_GIB_BUZZER_2          : sTemp := 'BUZZER #2';
        DefDio.OUT_GIB_BUZZER_3          : sTemp := 'BUZZER #3';
        DefDio.OUT_GIB_BUZZER_4          : sTemp := 'BUZZER #4';
        DefDio.OUT_UNDEFINED_15          : sTemp := '';

        DefDio.OUT_GIB_CH_12_ION_ONOFF_SOL : sTemp := 'CH #1 #2 ION ONOFF SOL';
        DefDio.OUT_GIB_CH_34_ION_ONOFF_SOL : sTemp := 'CH #3 #4 ION ONOFF SOL';
        18                                 : sTemp := '';
        19                                 : sTemp := '';
        20                                 : sTemp := '';
        21                                 : sTemp := '';
        22                                 : sTemp := '';
        23                                 : sTemp := '';



        DefDio.OUT_GIB_CH_1_VACCUM_SOL .. DefDio.OUT_GIB_CH_4_PINBLOCK_CLOSE_SOL : begin
          nMod := (i - DefDio.OUT_GIB_CH_1_VACCUM_SOL) mod 8;
          nCh := (i - DefDio.OUT_GIB_CH_1_VACCUM_SOL) div 8;  // 4 signal이 한묶음이라 4로 나누자.
          case nMod of
            0 : sTemp := Format('CH %d VACCUM SOL',[nCh + 1]);
            1 : sTemp := Format('CH %d PINBLOCK UNLOCK ON/OFF SOL',[nCh + 1]);
            2 : sTemp := Format('CH %d PINBLOCK CLOSE ON/OFF SOL',[nCh + 1]);
            3 : sTemp := '';
            4 : sTemp := '';
            5 : sTemp := '';
            6 : sTemp := '';
            7 : sTemp := '';

          end;
        end;

        DefDio.OUT_GIB_CH_12_PROBE_UP_SOL      : sTemp := 'CH #1 #2 PROBE UP SOL';
        DefDio.OUT_GIB_CH_12_PROBE_DN_SOL      : sTemp := 'CH #1 #2 PROBE DN SOL';
        DefDio.OUT_GIB_CH_12_SHUTTER_UP_SOL    : sTemp := 'CH #1 #2 SHUTTER UP SOL';
        DefDio.OUT_GIB_CH_12_SHUTTER_DN_SOL    : sTemp := 'CH #1 #2 SHUTTER DN SOL';
        DefDio.OUT_GIB_CH_34_PROBE_UP_SOL      : sTemp := 'CH #3 #4 PROBE UP SOL';
        DefDio.OUT_GIB_CH_34_PROBE_DN_SOL      : sTemp := 'CH #3 #4 PROBE DN SOL';
        DefDio.OUT_GIB_CH_34_SHUTTER_UP_SOL    : sTemp := 'CH #3 #4 SHUTTER UP SOL';
        DefDio.OUT_GIB_CH_34_SHUTTER_DN_SOL    : sTemp := 'CH #3 #4 SHUTTER DN SOL';


      end;

    end;
    pnlDioOut[i].Caption := sTemp;

    // Buttons.
    btnOutSig[i] := TRzBitBtn.Create(nil);
    btnOutSig[i].Parent := grpDioOut;
    btnOutSig[i].Left   := pnlDioOut[i].Left + pnlDioOut[i].Width + 3;
    btnOutSig[i].Top     := pnlOut[i].Top;
    btnOutSig[i].Width        := 30;
    btnOutSig[i].Height       := pnlOut[i].Height;
    btnOutSig[i].Visible      := True;
    btnOutSig[i].Font.Name     := 'Tahoma';
    btnOutSig[i].Font.Style    := [];
    btnOutSig[i].Font.Size     := 8;
    btnOutSig[i].Caption       := 'On';
    btnOutSig[i].Tag           := i;
    btnOutSig[i].OnClick       := OnEvtOutBtn;
    if Common.SystemInfo.OCType = DefCommon.PreOCType then begin
      if (i = OUT_GIB_CH_12_SHUTTER_UP_SOL) or (i = OUT_GIB_CH_12_SHUTTER_DN_SOL) or (i = OUT_GIB_CH_34_SHUTTER_UP_SOL) or (i = OUT_GIB_CH_34_SHUTTER_DN_SOL)  then
        btnOutSig[i].Enabled := false;
    end;
//    if  i in [28 .. 31] then begin // -1 : Range Error 발생... 아예 쓰지 말짜.
//      ledOut[i].Visible      := False;
//      pnlDioOut[i].Visible      := False;
//      pnlOut[i].Visible      := False;
//      btnOutSig[i].Visible      := False;
//    end;
//    if  i in [(DefDio.OUT_POGO_DN_SOL_78CH + 1) .. Pred(defDio.MAX_OUT_CNT)] then begin // -1 : Range Error 발생... 아예 쓰지 말짜.
//      ledOut[i].Visible      := False;
//      pnlOut[i].Visible      := False;
//      pnlDioOut[i].Visible      := False;
//      btnOutSig[i].Visible      := False;
//    end;
  end;
  DisplayDio(False);
end;

procedure TfrmMainter.MakePlcSignal;
//var
//  i, nDiv : Integer;
//  sTemp : string;
begin
//  // for In --------------------------------------------
//  SetLength(ledIn,defPlc.MAX_IN_CNT*2);
//  SetLength(pnlIn,defPlc.MAX_IN_CNT*2);
//  SetLength(pnlDioIn,defPlc.MAX_IN_CNT*2);
//
//  nDiv := defPlc.MAX_IN_CNT div 2;
//  for i := 0 to Pred(defPlc.MAX_IN_CNT) do begin
//    // Number.
//    pnlIn[i] := TRzPanel.Create(nil);
//    pnlIn[i].Parent := grpPlcIn;
//    if i < nDiv then pnlIn[i].Left   := 10
//    else             pnlIn[i].Left   := 300;
//    pnlIn[i].BevelWidth := 1;
//    pnlIn[i].FlatColor := clBlack;
//    pnlIn[i].BorderInner  := TframeStyleEx(fsNone);
//    pnlIn[i].BorderOuter  := TframeStyleEx(fsFlat);
//    pnlIn[i].Width        := 23;
//    pnlIn[i].Height       := 20;
//    pnlIn[i].Caption      := Format('%0.2d',[i]);//Common.DecToOct(i);
//    pnlIn[i].Visible      := True;
//
//    if i in [0, nDiv] then begin
//      pnlIn[i].Top := 16;
//    end
//    else begin
//      pnlIn[i].Top := pnlIn[i-1].Top + pnlIn[i-1].Height + 1;
//    end;
//    // Led.
//    ledIn[i] := ThhALed.Create(nil);
//    ledIn[i].Parent := grpPlcIn;
//    ledIn[i].Left   := pnlIn[i].Left + pnlIn[i].Width + 3;
//    ledIn[i].Top    := pnlIn[i].Top;
//    ledIn[i].Height := 20;
//    ledIn[i].LEDStyle := LEDSqLarge;
//    ledIn[i].FalseColor := clRed;
//    ledIn[i].TrueColor  := clLime;
//    ledIn[i].Blink := False;
//    ledIn[i].Visible := True;
//    ledIn[i].Value := False;
//
//    // Items.
//    pnlDioIn[i] := TRzPanel.Create(nil);
//    pnlDioIn[i].Parent := grpPlcIn;
//    pnlDioIn[i].Left   := ledIn[i].Left + ledIn[i].Width + 3;
//    pnlDioIn[i].BevelWidth := 1;
//    pnlDioIn[i].Top           := pnlIn[i].Top;
//    pnlDioIn[i].FlatColor     := clBlack;
//    pnlDioIn[i].BorderInner   := TframeStyleEx(fsNone);
//    pnlDioIn[i].BorderOuter   := TframeStyleEx(fsFlat);
//    pnlDioIn[i].Width         := 260;
//    pnlDioIn[i].Height        := pnlIn[i].Height;
//    pnlDioIn[i].Visible       := True;
//    pnlDioIn[i].Font.Name     := 'Tahoma';
//    pnlDioIn[i].Font.Style    := [];
//    pnlDioIn[i].Font.Size     := 8;
//    sTemp := '';
//    case i of
//      0 : sTemp := 'START S/W';
//      2 : sTemp := 'FRONT EMS';
//      3 : sTemp := 'SIDE EMS';
//      4 : sTemp := 'RIGHT INNER EMS';
//      5 : sTemp := 'LEFT INNER EMS';
//      6 : sTemp := 'REAR EMS';
//      7 : sTemp := 'FAN #1 IN';
//      8 : sTemp := 'FAN #2 IN';
//      9 : sTemp := 'FAN #3 OUT';
//      10 : sTemp := 'FAN #4 OUT';
//      11 : sTemp := 'FAN #5 IN';
//      12 : sTemp := 'FAN #6 IN';
//      13 : sTemp := 'FAN #7 OUT';
//      14 : sTemp := 'FAN #8 OUT';
//      15 : sTemp := 'MOVING AIR REGULATOR';
//      16 : sTemp := 'AIR KNIFE, ION BAR REGULATOR';
//      17 : sTemp := 'TEMPERATURE ALARM';
//      18 : sTemp := 'POWER HIGH ALARM';
//      19 : sTemp := 'LIGHT CURTAIN';
//      20 : sTemp := 'FRONT AUTO MODE SELECT KEY';
//      21 : sTemp := 'FRONT TEACH MODE SELECT KEY';
//      22 : sTemp := 'SIDE AUTO MODE SELECT KEY';
//      23 : sTemp := 'SIDE TEACH MODE SELECT KEY';
//      24 : sTemp := 'UPPER LEFT DOOR';
//      25 : sTemp := 'UPPER RIGHT DOOR';
//      26 : sTemp := 'LOWER LEFT DOOR';
//      27 : sTemp := 'LOWER RIGHT DOOR';
//      28 : sTemp := 'MC MONITORING';
//      29 : sTemp := 'A STATION INPOSITION SENSOR';
//      30 : sTemp := 'B STATION INPOSITION SENSOR';
//      31 : sTemp := 'MOTOR STOP SENSOR';
//      32 : sTemp := 'SHUTTER UP SENSOR';
//      33 : sTemp := 'SHUTTER DOWN SENSOR';
//      34..41 : sTemp := Format('%dCH CLAMP UP SENSOR',[i-33]);
//      42..49 : sTemp := Format('%dCH POGO DOWN SENSOR',[i-41]);
//      50..57 : sTemp := Format('%dCH CARRIER INPOSITION SENSOR',[i-49]);
//    end;
//    pnlDioIn[i].Caption := sTemp;
//  end;
//  // for Out --------------------------------------------
//  SetLength(ledOut,defPlc.MAX_OUT_CNT*2);
//  SetLength(pnlOut,defPlc.MAX_OUT_CNT*2);
//  SetLength(pnlDioOut,defPlc.MAX_OUT_CNT*2);
//  SetLength(btnOutSig,defPlc.MAX_OUT_CNT*2);
//
//  nDiv := defPlc.MAX_OUT_CNT div 2;
//  for i := 0 to Pred(defPlc.MAX_OUT_CNT) do begin
//    // Number.
//    pnlOut[i] := TRzPanel.Create(nil);
//    pnlOut[i].Parent := grpPlcOut;
//    if i < nDiv then pnlOut[i].Left   := 10
//    else             pnlOut[i].Left   := 400;
//    pnlOut[i].BevelWidth := 1;
//    pnlOut[i].FlatColor := clBlack;
//    pnlOut[i].BorderInner  := TframeStyleEx(fsNone);
//    pnlOut[i].BorderOuter  := TframeStyleEx(fsFlat);
//    pnlOut[i].Width        := 23;
//    pnlOut[i].Height       := 30;
//    pnlOut[i].Caption      := Format('%0.2d',[i]);//Common.DecToOct(i); //
//    pnlOut[i].Visible      := True;
//    if i in [0, nDiv] then begin
//      pnlOut[i].Top := 16;
//    end
//    else begin
//      pnlOut[i].Top := pnlOut[i-1].Top + pnlOut[i-1].Height + 2;
//    end;
//    // Led.
//    ledOut[i] := ThhALed.Create(nil);
//    ledOut[i].Parent := grpPlcOut;
//    ledOut[i].Left   := pnlOut[i].Left + pnlOut[i].Width + 3;
//    ledOut[i].Top    := pnlOut[i].Top;
//    ledOut[i].LEDStyle := LEDSqLarge;
//    ledOut[i].Height := 30;
//    ledOut[i].FalseColor := clRed;
//    ledOut[i].TrueColor  := clLime;
//    ledOut[i].Blink := False;
//    ledOut[i].Visible := True;
//    ledOut[i].Value := False;
//
//    // Items.
//    pnlDioOut[i] := TRzPanel.Create(nil);
//    pnlDioOut[i].Parent := grpPlcOut;
//    pnlDioOut[i].Left   := ledOut[i].Left + ledOut[i].Width + 3;
//    pnlDioOut[i].BevelWidth := 1;
//    pnlDioOut[i].Top     := pnlOut[i].Top;
//    pnlDioOut[i].FlatColor := clBlack;
//    pnlDioOut[i].BorderInner  := TframeStyleEx(fsNone);
//    pnlDioOut[i].BorderOuter  := TframeStyleEx(fsFlat);
//    pnlDioOut[i].Width        := 230;
//    pnlDioOut[i].Height       := pnlOut[i].Height;
//    pnlDioOut[i].Visible      := True;
//    pnlDioOut[i].Font.Name     := 'Tahoma';
//    pnlDioOut[i].Font.Style    := [];
//    pnlDioOut[i].Font.Size     := 8;
//
//    sTemp := '';
//    case i of
//      0 : sTemp := 'START SW LED';
//      1 : sTemp := 'RESET SW LED';
//      2 : sTemp := 'WORKER LAMP';
//      3 : sTemp := 'RED LAMP';
//      4 : sTemp := 'YELLOW LAMP';
//      5 : sTemp := 'GREEN LAMP';
//      6 : sTemp := 'MELODY #1';
//      7 : sTemp := 'MELODY #2';
//      8 : sTemp := 'MELODY #3';
//      9 : sTemp := 'MELODY #4';
//      10 : sTemp := 'FRONT SELECT KEY UNLOCK';
//      11 : sTemp := 'SIDE SELECT KEY UNLOCK';
//      12 : sTemp := 'UPPER LEFT DOOR UNLOCK';
//      13 : sTemp := 'UPPER RIGHT DOOR UNLOCK';
//      14 : sTemp := 'ION BAR SOL';
//      15 : sTemp := 'AIR KNIFE SOL';
//      16 : sTemp := 'A Stage Front';
//      17 : sTemp := 'B Stage Front';
//      18 : sTemp := 'SHUTTER UP SOL';
//      19 : sTemp := 'SHUTTER DOWN SOL';
//      32 : sTemp := '1,2CH CLAMP CYLINDER UP SOL';
//      33 : sTemp := '3,4CH CLAMP CYLINDER UP SOL';
//      34 : sTemp := '5,6CH CLAMP CYLINDER UP SOL';
//      35 : sTemp := '7,8CH CLAMP CYLINDER UP SOL';
//      36 : sTemp := '1,2CH CLAMP CYLINDER DOWN SOL';
//      37 : sTemp := '3,4CH CLAMP CYLINDER DOWN SOL';
//      38 : sTemp := '5,6CH CLAMP CYLINDER DOWN SOL';
//      39 : sTemp := '7,8CH CLAMP CYLINDER DOWN SOL';
//      40 : sTemp := '1,2CH POGO UP SOL';
//      41 : sTemp := '3,4CH POGO UP SOL';
//      42 : sTemp := '5,6CH POGO UP SOL';
//      43 : sTemp := '7,8CH POGO UP SOL';
//      44 : sTemp := '1,2CH POGO DOWN SOL';
//      45 : sTemp := '3,4CH POGO DOWN SOL';
//      46 : sTemp := '5,6CH POGO DOWN SOL';
//      47 : sTemp := '7,8CH POGO DOWN SOL';
//    end;
//    pnlDioOut[i].Caption := sTemp;
//
//    // Buttons.
//    btnOutSig[i] := TRzBitBtn.Create(nil);
//    btnOutSig[i].Parent := grpPlcOut;
//    btnOutSig[i].Left   := pnlDioOut[i].Left + pnlDioOut[i].Width + 3;
//    btnOutSig[i].Top     := pnlOut[i].Top;
//    btnOutSig[i].Width        := 90;
//    btnOutSig[i].Height       := pnlOut[i].Height;
//    btnOutSig[i].Visible      := True;
//    btnOutSig[i].Font.Name     := 'Tahoma';
//    btnOutSig[i].Font.Style    := [];
//    btnOutSig[i].Font.Size     := 8;
//    btnOutSig[i].Caption       := 'On';
//    btnOutSig[i].Tag           := i;
//    btnOutSig[i].OnClick       := OnEvtOutBtn;
//    if  i in [21 .. 31] then begin // -1 : Range Error 발생... 아예 쓰지 말짜.
//      ledOut[i].Visible      := False;
//      pnlDioOut[i].Visible      := False;
//      pnlOut[i].Visible      := False;
//      btnOutSig[i].Visible      := False;
//    end;
//    if  i in [53 .. Pred(defPlc.MAX_OUT_CNT)] then begin // -1 : Range Error 발생... 아예 쓰지 말짜.
//      ledOut[i].Visible      := False;
//      pnlOut[i].Visible      := False;
//      pnlDioOut[i].Visible      := False;
//      btnOutSig[i].Visible      := False;
//    end;
//  end;
end;

procedure TfrmMainter.MeasureJncdPg(nCh, nCa310Pos: Integer;sCa310Ch : string);
var
  thJnCD : TThread;
begin
{$IFDEF CA310_USE}
  thJnCD := TThread.CreateAnonymousThread(procedure var getData : TAChExt; begin
    Pg[nCh].SendSinglePat(255,255,255);
    Pg[nCh].SendPowerOn(1); // power on
    Pg[nCh].SendSinglePat(255,255,255);
    sleep(100);
    DongaCa310[nCa310Pos].Ca310Shot(DefCa310.CA310_LvXY,sCa310Ch,getData);
    grdMeasureWRGB.Cells[1,1] := Format('%0.5f',[getData[nCh+1].ColorValX]);
    grdMeasureWRGB.Cells[2,1] := Format('%0.5f',[getData[nCh+1].ColorValY]);
    grdMeasureWRGB.Cells[3,1] := Format('%0.5f',[getData[nCh+1].GrayVal]);

    Pg[nCh].SendSinglePat(255,0,0);
    sleep(100);
    DongaCa310[nCa310Pos].Ca310Shot(DefCa310.CA310_LvXY,sCa310Ch,getData);
    grdMeasureWRGB.Cells[1,2] := Format('%0.5f',[getData[nCh+1].ColorValX]);
    grdMeasureWRGB.Cells[2,2] := Format('%0.5f',[getData[nCh+1].ColorValY]);
    grdMeasureWRGB.Cells[3,2] := Format('%0.5f',[getData[nCh+1].GrayVal]);

    Pg[nCh].SendSinglePat(0,255,0);
    sleep(100);
    DongaCa310[nCa310Pos].Ca310Shot(DefCa310.CA310_LvXY,sCa310Ch,getData);
    grdMeasureWRGB.Cells[1,3] := Format('%0.5f',[getData[nCh+1].ColorValX]);
    grdMeasureWRGB.Cells[2,3] := Format('%0.5f',[getData[nCh+1].ColorValY]);
    grdMeasureWRGB.Cells[3,3] := Format('%0.5f',[getData[nCh+1].GrayVal]);

    Pg[nCh].SendSinglePat(0,0,255);
    sleep(100);
    DongaCa310[nCa310Pos].Ca310Shot(DefCa310.CA310_LvXY,sCa310Ch,getData);
    grdMeasureWRGB.Cells[1,4] := Format('%0.5f',[getData[nCh+1].ColorValX]);
    grdMeasureWRGB.Cells[2,4] := Format('%0.5f',[getData[nCh+1].ColorValY]);
    grdMeasureWRGB.Cells[3,4] := Format('%0.5f',[getData[nCh+1].GrayVal]);

    Pg[nCh].SendPowerOn(0); // power off
  end);

  thJnCD.Start;
 {$ENDIF}
end;

procedure TfrmMainter.OnEvtOutBtn(Sender: TObject);
var
  nSig : Integer;
  bVal : boolean;
begin
  nSig := TRzBitBtn(Sender).Tag;
  bVal := ledOut[TRzBitBtn(Sender).Tag].Value;
//  if (nSig = DefDio.OUT_A_STAGE_FRONT) and ControlDio.ReadInSig(DefDio.IN_B_STAGE_IN_CAM) then begin
//    Application.MessageBox('Already A Front', 'Confirm', MB_OK+ MB_ICONSTOP);
//    Exit;
//  end;
//
//  if (nSig = DefDio.OUT_B_STAGE_FRONT) and ControlDio.ReadInSig(DefDio.IN_A_STAGE_IN_CAM) then begin
//    Application.MessageBox('Already B Front', 'Confirm', MB_OK+ MB_ICONSTOP);
//    Exit;
//  end;

//  if (nSig = DefDio.OUT_A_STAGE_FRONT) or (nSig = DefDio.OUT_B_STAGE_FRONT) then begin
//    if ControlDio.ReadInSig(DefDio.IN_SHUTTER_DN_SNENSOR) then begin
//      Application.MessageBox('SHUTTER_DN_SNENSOR ', 'Confirm', MB_OK+ MB_ICONSTOP);
//      Exit;
//    end;
//
//    if not ControlDio.ReadInSig(DefDio.IN_SHUTTER_UP_SENSOR) then begin
//      Application.MessageBox('SHUTTER_UP_SENSOR ', 'Confirm', MB_OK+ MB_ICONSTOP);
//      Exit;
//    end;

  if Common.SystemInfo.OCType = DefCommon.PreOCType then begin


//    if nSig = OUT_GIB_CH_12_SHUTTER_DN_SOL  then begin
//      Application.MessageBox('CH_12_SHUTTER Down', 'Confirm', MB_OK+ MB_ICONSTOP);
//      Exit;
//    end;
//
//    if nSig = OUT_GIB_CH_34_SHUTTER_DN_SOL  then begin
//      Application.MessageBox('CH_34_SHUTTER Down ', 'Confirm', MB_OK+ MB_ICONSTOP);
//      Exit;
//    end;
//    if not ControlDio.ReadInSig(DefDio.IN_CH_3_4_DOOR_LEFT_OPEN) then begin
//      Application.MessageBox('CH_3_4_DOOR_LEFT ', 'Confirm', MB_OK+ MB_ICONSTOP);
//      Exit;
//    end;
//
//    if not ControlDio.ReadInSig(DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN) then begin
//      Application.MessageBox('CH_3_4_DOOR_RIGH ', 'Confirm', MB_OK+ MB_ICONSTOP);
//      Exit;
//    end;
  end;

//  if nSig in [DefDio.OUT_UPPER_LEFT_DOOR_UNLOCK, OUT_UPPER_RIGHT_DOOR_UNLOCK] then begin
//    if ControlDio.ReadInSig(IN_AUTO_MODE_SEL_KEY) then begin
//      Application.MessageBox('Door(s) can not be Opened in Key Auto', 'Confirm', MB_OK+ MB_ICONSTOP);
//      Exit;
//    end;
//  end;


  ControlDio.WriteDioSig(nSig,bVal)
end;

procedure TfrmMainter.pnAxisMoveJog_DecMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  EziMotor.StopMove;
end;

procedure TfrmMainter.pnAxisMoveJog_IncMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  EziMotor.StopMove;
end;



procedure TfrmMainter.POcbIpList;
begin
  lstIpInformation.Clear;

  lstIpInformation.Add('169.254.199.10 , 192.168.0.10  : GPC (PG, DIO)');
  lstIpInformation.Add('169.254.199.11 : PG1        ');
  lstIpInformation.Add('169.254.199.12 : PG2        ');
  lstIpInformation.Add('169.254.199.13 : PG3        ');
  lstIpInformation.Add('169.254.199.14 : PG4        ');


  lstIpInformation.Add('192.168.0.99 : DIO        ');
end;

//procedure TfrmMainter.POCB_Data_Down_Seq(nCh: Integer);
//var
//  sFileName : string;
//  transData: TFileTranStr ;
//  dGetCheckSum : dword;
//  nRet : Integer;
//  Stream : TMemoryStream;
//begin
//  SendGuiDisplay(nCh,'POCB Data Download Test');
//  sFileName := Trim(edCmdPath.Text) ;
//  if sFileName = '' then begin
//    SendGuiDisplay(nCh,'Select POCB Data File');
//    Exit;
//  end;
//  if not FileExists(sFileName) then begin
//    SendGuiDisplay(nCh,'the PCOB File does not Exist');
//    Exit;
//  end;
//
//  Stream := TMemoryStream.Create;
//  dGetCheckSum := 0;
//  try
//    try
//      Stream.LoadFromFile(sFileName);
//      if Stream.Size > 0 then begin
//        common.CalcCheckSum(Stream.Memory, Stream.Size, dGetCheckSum);
//      end;
//      transData.TotalSize := Stream.Size;
//      transData.CheckSum  := dGetCheckSum;
//      SetLength(transData.Data,transData.TotalSize);
//      CopyMemory(@transData.Data[0],Stream.Memory,transData.TotalSize);
//    except {...} end;
//  finally
//    Stream.Free;
//  end;
//  nRet := Pg[nCh].SendPocbData(transData);
//  case nRet of
//    0 : SendGuiDisplay(nCh,'the PCOB Data File Download OK ');
//    1 : SendGuiDisplay(nCh,'the PCOB Data File Download NG - S MODE NAK');
//    2 : SendGuiDisplay(nCh,'the PCOB Data File Download NG - D MODE NAK');
//    3 : SendGuiDisplay(nCh,'the PCOB Data File Download NG - D MODE - Data Length is under 3');
//    4 : SendGuiDisplay(nCh,'the PCOB Data File Download NG - D MODE - Return Idx is not matched send one.');
//    5 : SendGuiDisplay(nCh,'the PCOB Data File Download NG - E MODE NAK');
//  end;
//
//end;

//procedure TfrmMainter.PowerOffSeq(nCh: Integer);
//begin
//  ThreadTask( procedure begin
//    SendGuiDisplay(nCh,'Power OFF');
//    Pg[nCh].SendPowerOn(0);
//    Pg[nCh].SetPowerMeasureTimer(False);
//  end, btnPowerOff);
//end;
//
//procedure TfrmMainter.PowerOnSeq(nCh: Integer);
//begin
//  ThreadTask( procedure begin
//    SendGuiDisplay(nCh,'Power On');
//    Pg[nCh].SendPowerOn(2);
//    Pg[nCh].SetPowerMeasureTimer(False);
//  end, btnPowerOn);
//end;


procedure TfrmMainter.RzBitBtn11Click(Sender: TObject);
var
  frmWarringMsg : TfrmDoorOpenAlarmMsg;
begin
  try
    frmWarringMsg := TfrmDoorOpenAlarmMsg.Create(Self);
    frmWarringMsg.btnClose.Visible := True;
//    frmWarringMsg := TfrmNgMsg.Create(Self);
//    frmWarringMsg.Caption := 'Warning Message';
//    frmWarringMsg.lblShow.Font.Size := 40;
//    frmWarringMsg.lblShow.Caption := 'Prohibit operation during work / Cấm thao tác trong quá trình làm việc / 작업중 조작 금지';
    frmWarringMsg.ShowModal;
  finally
    frmWarringMsg.Free;
    frmWarringMsg := nil;
  end;
end;





procedure TfrmMainter.RzBitBtn19Click(Sender: TObject);
var
  nCh : Integer;
begin
  nCh := GetProbeNum-1;
  PowerOffSeq(nCh);
end;

procedure TfrmMainter.RzBitBtn1Click(Sender: TObject);
begin
  mmCommPg.Clear;
  mmHandBcr.Clear;
end;
procedure TfrmMainter.btnCalStProbeClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;

  if g_CommPLC.IsGlassData_Robot(nCH div 2) then exit;

  if ControlDio <> nil then begin
    if rdoProbe1.Checked or rdoProbe2.Checked or rdoProbe3.Checked or rdoProbe4.Checked then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        ThreadStartDio(procedure begin
          ControlDio.lockCarrier(nCH,true);
          ControlDio.ProbeForward(nCH);
        end);
        end
      else ControlDio.MovingProbe(nCH,False);
    end;
  end;
end;

procedure TfrmMainter.btnCal0Click(Sender: TObject);
var
  nProbeNum, nStage : Integer;
  i: Integer;
  sMsg : string;
  idx : Integer;
  sSerial : array of AnsiChar;
begin
{$IFDEF CA410_USE}
  sMsg := '(Are you sure you want to '+'0-CAL ?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    nProbeNum := GetProbeNum;
    try
      CalZero(nProbeNum);

    except
      on E: Exception do begin
        mmoAutoCalLog.Lines.Add(E.Message);
      end;
    end;
  end;
{$ENDIF}
{$IFDEF CA310_USE}
  sMsg := '(Are you sure you want to '+'0-CAL ?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    nProbeNum := GetProbeNum;
    if nProbeNum < 5 then nStage := 0
    else                  nStage := 1;
    try
      DongaCa310[nStage].RBrightobj.objCa.CalZero;
    except
      on E: Exception do begin
        mmoAutoCalLog.Lines.Add(E.Message);
      end;
    end;
  end;
{$ENDIF}
end;

procedure TfrmMainter.btnCalEdProbeClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;

  if g_CommPLC.IsGlassData_Robot(nCH div 2) then exit;


  if ControlDio <> nil then begin
    if rdoProbe1.Checked or rdoProbe2.Checked or rdoProbe3.Checked or rdoProbe4.Checked then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin

          ThreadStartDio(procedure begin

            ControlDio.ProbeBackward(nCH);
            ControlDio.UnlockCarrier(nCH,true);
          end);

       end
      else  ControlDio.MovingProbe(nCH,true);
    end;
  end;
end;

procedure TfrmMainter.RzBitBtn20Click(Sender: TObject);
var
  nCh : Integer;
begin
  nCh := GetProbeNum-1;
  PowerOnSeq(nCh);
end;



procedure TfrmMainter.btnUnlockBottomDoorsClick(Sender: TObject);
begin
  if pos('Unlock CH 34 Doors',btnUnlockBottomDoors.Caption) > 0 then begin
    if (Common.PLCInfo.InlineGIB) then begin
      if g_CommPLC.EQP_Door_Open_Warning then begin
        ControlDio.UnlockDoorOpen(DefDio.BOTTOM_CH,true); //Unlock
        btnUnlockBottomDoors.Caption := 'lock CH 34 Doors';
      end
      else begin
        ShowNgMessage('EQP_Door_Open_Warning : NG');
      end;
    end
    else begin
      ControlDio.UnlockDoorOpen(DefDio.BOTTOM_CH,true); //Unlock
      btnUnlockBottomDoors.Caption := 'lock CH 34 Doors';
    end;
  end
  else begin
    ControlDio.UnlockDoorOpen(DefDio.BOTTOM_CH,false);
    btnUnlockBottomDoors.Caption := 'Unlock CH 34 Doors';

  end;

end;

procedure TfrmMainter.btnUnlockTopDoorsClick(Sender: TObject);
begin
  if pos('Unlock CH 12 Doors',btnUnlockTopDoors.Caption) > 0 then  begin
    if (Common.PLCInfo.InlineGIB) then begin
      if g_CommPLC.EQP_Door_Open_Warning then begin
        ControlDio.UnlockDoorOpen(DefDio.TOP_CH,true); //Unlock
        btnUnlockTopDoors.Caption := 'lock CH 12 Doors';
      end
      else begin
        ShowNgMessage('EQP_Door_Open_Warning : NG');
      end;
    end
    else begin
      ControlDio.UnlockDoorOpen(DefDio.TOP_CH,true); //Unlock
      btnUnlockTopDoors.Caption := 'lock CH 12 Doors';
    end;
  end
  else begin
    ControlDio.UnlockDoorOpen(DefDio.TOP_CH,False); //lock
    btnUnlockTopDoors.Caption := 'Unlock CH 12 Doors';
  end;

end;

procedure TfrmMainter.RunDosInMemo(DosApp: string;var sGetResult : string);
const
    READ_BUFFER_SIZE = 2400;
var
    Security: TSecurityAttributes;
    readableEndOfPipe, writeableEndOfPipe: THandle;
    start: TStartUpInfo;
    ProcessInfo: TProcessInformation;
    Buffer: PAnsiChar;
    BytesRead: DWORD;
    AppRunning: DWORD;
begin
    Security.nLength := SizeOf(TSecurityAttributes);
    Security.bInheritHandle := True;
    Security.lpSecurityDescriptor := nil;

    if CreatePipe({var}readableEndOfPipe, {var}writeableEndOfPipe, @Security, 0) then  begin
      try
        Buffer := AllocMem(READ_BUFFER_SIZE+1);
        FillChar(Start, Sizeof(Start), #0);
        start.cb := SizeOf(start);

        // Set up members of the STARTUPINFO structure.
        // This structure specifies the STDIN and STDOUT handles for redirection.
        // - Redirect the output and error to the writeable end of our pipe.
        // - We must still supply a valid StdInput handle (because we used STARTF_USESTDHANDLES to swear that all three handles will be valid)
        start.dwFlags := start.dwFlags or STARTF_USESTDHANDLES;
        start.hStdInput := GetStdHandle(STD_INPUT_HANDLE); //we're not redirecting stdInput; but we still have to give it a valid handle
        start.hStdOutput := writeableEndOfPipe; //we give the writeable end of the pipe to the child process; we read from the readable end
        start.hStdError := writeableEndOfPipe;

        //We can also choose to say that the wShowWindow member contains a value.
        //In our case we want to force the console window to be hidden.
        start.dwFlags := start.dwFlags + STARTF_USESHOWWINDOW;
        start.wShowWindow := SW_HIDE;

        // Don't forget to set up members of the PROCESS_INFORMATION structure.
        ProcessInfo := Default(TProcessInformation);

        //WARNING: The unicode version of CreateProcess (CreateProcessW) can modify the command-line "DosApp" string.
        //Therefore "DosApp" cannot be a pointer to read-only memory, or an ACCESS_VIOLATION will occur.
        //We can ensure it's not read-only with the RTL function: UniqueString
        UniqueString({var}DosApp);

        if CreateProcess(nil, PChar(DosApp), nil, nil, True, NORMAL_PRIORITY_CLASS, nil, nil, start, {var}ProcessInfo) then begin
            //Wait for the application to terminate, as it writes it's output to the pipe.
            //WARNING: If the console app outputs more than 2400 bytes (ReadBuffer),
            //it will block on writing to the pipe and *never* close.
            repeat
                Apprunning := WaitForSingleObject(ProcessInfo.hProcess, 100);
                Application.ProcessMessages;
            until (Apprunning <> WAIT_TIMEOUT);

            //Read the contents of the pipe out of the readable end
            //WARNING: if the console app never writes anything to the StdOutput, then ReadFile will block and never return
            repeat
                BytesRead := 0;
                ReadFile(readableEndOfPipe, Buffer[0], READ_BUFFER_SIZE, {var}BytesRead, nil);
                Buffer[BytesRead]:= #0;
                OemToAnsi(Buffer,Buffer);
                sGetResult := sGetResult + String(Buffer);
            until (BytesRead < READ_BUFFER_SIZE);
        end;
      finally
        FreeMem(Buffer);
        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
        CloseHandle(readableEndOfPipe);
        CloseHandle(writeableEndOfPipe);
      end;
    end;
end;



procedure TfrmMainter.Button1Click(Sender: TObject);
var
  cdCal : LibCa410Option.TCalValue;
  sRet,sSendCmd,sMsg,slog : string;
  stlTemp :  TStringList;
  i,nRet : Integer;
begin
  if MessageDlg(#13#10 + format('Do you want to change to the following data on Memory Channel %d on CA410 CH %d??',[cboCa310Channel.ItemIndex +1,RzComboBox1.ItemIndex + 1]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    cdCal.W_X := StrToFloatDef(pnlR2RData[0].text,0);
    cdCal.W_Y := StrToFloatDef(pnlR2RData[1].text,0);
    cdCal.W_Z := StrToFloatDef(pnlR2RData[2].text,0);
    cdCal.W_Lv := StrToFloatDef(pnlR2RData[12].text,0);
    cdCal.W_xx := StrToFloatDef(pnlR2RData[13].text,0);
    cdCal.W_yy := StrToFloatDef(pnlR2RData[14].text,0);

    cdCal.R_X := StrToFloatDef(pnlR2RData[3].Text,0);
    cdCal.R_Y := StrToFloatDef(pnlR2RData[4].Text,0);
    cdCal.R_Z := StrToFloatDef(pnlR2RData[5].Text,0);
    cdCal.R_Lv := StrToFloatDef(pnlR2RData[15].Text,0);
    cdCal.R_xx := StrToFloatDef(pnlR2RData[16].Text,0);
    cdCal.R_yy := StrToFloatDef(pnlR2RData[17].Text,0);

    cdCal.G_X := StrToFloatDef(pnlR2RData[6].Text,0);
    cdCal.G_Y := StrToFloatDef(pnlR2RData[7].Text,0);
    cdCal.G_Z := StrToFloatDef(pnlR2RData[8].Text,0);
    cdCal.G_Lv := StrToFloatDef(pnlR2RData[18].Text,0);
    cdCal.G_xx := StrToFloatDef(pnlR2RData[19].Text,0);
    cdCal.G_yy := StrToFloatDef(pnlR2RData[20].Text,0);

    cdCal.B_X := StrToFloatDef(pnlR2RData[9].Text,0);
    cdCal.B_Y := StrToFloatDef(pnlR2RData[10].Text,0);
    cdCal.B_Z := StrToFloatDef(pnlR2RData[11].Text,0);
    cdCal.B_Lv := StrToFloatDef(pnlR2RData[21].Text,0);
    cdCal.B_xx := StrToFloatDef(pnlR2RData[22].Text,0);
    cdCal.B_yy := StrToFloatDef(pnlR2RData[23].Text,0);
    CtrlCa410.CDCal := cdCal;

    CtrlCa410.TestExample(RzComboBox1.ItemIndex,cboCa310Channel.ItemIndex,sRet); // 0 is channel num.
    mmoLog.Lines.Add('----------------');
    mmoLog.Lines.Add(sRet);


  end
  else Exit;
end;

procedure TfrmMainter.Button211Click(Sender: TObject);
var
 I : Integer;
begin

end;

procedure TfrmMainter.Button2Click(Sender: TObject);
begin
//  if DongaGmes <> nil then
//   DongaGmes.SendR2REodsTest;
  pnlR2RData[0].text := edtW_X.Text;
  pnlR2RData[1].text := edtW_Y.Text;
  pnlR2RData[2].text := edtW_Z.Text;

  pnlR2RData[3].text := edtR_X.Text;
  pnlR2RData[4].text := edtR_Y.Text;
  pnlR2RData[5].text := edtR_Z.Text;

  pnlR2RData[6].text := edtG_X.Text;
  pnlR2RData[7].text := edtG_Y.Text;
  pnlR2RData[8].text := edtG_Z.Text;

  pnlR2RData[9].text := edtB_X.Text;
  pnlR2RData[10].text := edtB_Y.Text;
  pnlR2RData[11].text := edtB_Z.Text;

  pnlR2RData[12].text := edtW_LV.Text;
  pnlR2RData[13].text := edtW_XX.Text;
  pnlR2RData[14].text := edtW_YY.Text;

  pnlR2RData[15].text := edtR_LV.Text;
  pnlR2RData[16].text := edtR_XX.Text;
  pnlR2RData[17].text := edtR_YY.Text;

  pnlR2RData[18].text := edtG_LV.Text;
  pnlR2RData[19].text := edtG_XX.Text;
  pnlR2RData[20].text := edtG_YY.Text;

  pnlR2RData[21].text := edtB_LV.Text;
  pnlR2RData[22].text := edtB_XX.Text;
  pnlR2RData[23].text := edtB_YY.Text;
end;

procedure TfrmMainter.btnSendEodaClick(Sender: TObject);
begin
  if DongaGmes <> nil then
    DongaGmes.SendR2REoda(RzComboBox1.ItemIndex,0);
end;

procedure TfrmMainter.btnSendEods_RClick(Sender: TObject);

var
  sSendCmd, sTemp, sRet : string;
  stlTemp :  TStringList;
  i : Integer;
  cdCal : LibCa410Option.TCalValue;
begin
  if DongaGmes <> nil then
    DongaGmes.SendR2REods(RzComboBox1.ItemIndex);
//  Exit;
//  cdCal.W_X := 677.2256;
//  cdCal.W_Y := 716.7414;
//  cdCal.W_Z := 769.7799;
//  cdCal.W_xx := 0.3120;
//  cdCal.W_yy := 0.3309;
//  cdCal.W_Lv := 730.1678;
//
//  cdCal.R_X := 420.4322;
//  cdCal.R_Y := 192.6249;
//  cdCal.R_Z := 0.3449;
//  cdCal.R_xx := 0.6853;
//  cdCal.R_yy := 0.3142;
//  cdCal.R_Lv := 195.1299;
//
//  cdCal.G_X := 183.3479;
//  cdCal.G_Y := 553.7119;
//  cdCal.G_Z := 27.5488;
//  cdCal.G_xx := 0.2401;
//  cdCal.G_yy := 0.7239;
//  cdCal.G_Lv := 564.8961;
//
//  cdCal.B_X := 133.9259;
//  cdCal.B_Y := 46.0480;
//  cdCal.B_Z := 795.0201;
//  cdCal.B_xx := 0.1373;
//  cdCal.B_yy := 0.0472;
//  cdCal.B_Lv := 47.1118;
//  CtrlCa410.CDCal := cdCal;
//  sSendCmd :=  'AppDllCaller.exe 7 1 02';
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_X]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_Y]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_Z]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_xx]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_yy]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.W_Lv]);
//
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_X]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_Y]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_Z]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_xx]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_yy]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.R_Lv]);
//
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_X]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_Y]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_Z]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_xx]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_yy]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.G_Lv]);
//
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_X]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_Y]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_Z]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_xx]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_yy]);
//  sSendCmd := sSendCmd + Format(' %0.4f',[CtrlCa410.CDCal.B_Lv]);
//
//  sTemp := ' 42BE175842C8000042D9CFC23F8000003F8000003F8000003F8000003F8000003F8000003F8000003F8000003F8000003EA01A373EA872B042C800003EAAAAAB3EAAAAAB3F8000003EAAAAAB3EAAAAAB3F8000003EAAAAAB3EAAAAAB3F80000042BE175842C8000042D9CFC2501C8C4501C8C4501C8C400A3';
//  sSendCmd := sSendCmd + sTemp;
//  sRet := '';
////  RunDosInMemo(sSendCmd,sRet);
//  mmoLog.Lines.Add(sRet);
//  mmoLog.Lines.Add('-----------------------------------');
//  stlTemp :=  TStringList.Create;
//  try
//    ExtractStrings([#10, #13], [], PWideChar(sRet), stlTemp);
//    for i := 0 to Pred(stlTemp.Count) do mmoLog.Lines.Add('#'+i.ToString+' '+Trim(stlTemp[i]));
//  finally
//    stlTemp.Free;
//  end;
end;

procedure TfrmMainter.Button3Click(Sender: TObject);
var
  sRet : string;
  cdCal : LibCa410Option.TCalValue;
begin
//    CtrlCa410.TestExample(RzComboBox1.ItemIndex,cboCa310Channel.ItemIndex,sRet); // 0 is channel num.

    CtrlCa410.ReadR2R(RzComboBox1.ItemIndex,cboCa310Channel.ItemIndex,sRet);
    mmoLog.Lines.Add('----------------');
    mmoLog.Lines.Add(Format('CH : %d Memory CH %d :',[RzComboBox1.ItemIndex+1,cboCa310Channel.ItemIndex+1])+sRet);

end;

procedure GetBoxPtnSizeinfo(nModel,mBand : Integer; var nStartX,nStartY,nEndX,nEndY : Integer);
begin
  if nModel = 0 then begin      //Model X2146
    if mBand = 1 then begin     //APL 40%
      nStartX := 0;
      nStartY := 619;
      nEndX := 688;
      nEndY := 826;
    end
    else if mBand = 2 then begin  // APL 60%
      nStartX := 0;
      nStartY := 412;
      nEndX := 688;
      nEndY := 1239;
    end;
  end
  else if nModel = 1 then begin   //Model X2381
    if mBand = 1 then begin     //APL 40%
      nStartX := 0;
      nStartY := 500;
      nEndX := 605;
      nEndY := 667;
    end
    else if mBand = 2 then begin  // APL 60%
      nStartX := 0;
      nStartY := 334;
      nEndX := 605;
      nEndY := 1001;
    end;
  end;
end;


procedure TfrmMainter.Run_DBVtracking(nFPgNo,nRGBIdx: Integer);
var
i,nDBVValue,nWaitMS,nRetry,wdRet : Integer;
m_Ca410Data: TBrightValue ;
sFilePath : string;
sDataHeader, sData,sSerialNo : string;
nSX,nSy,nEX,nEY : Integer;

begin
  PasScr[nFPgNo].m_sFileCsv :=  format('%s_CH%d_Gray_%d_DBVtracking_',[Common.SystemInfo.EQPId,nFPgNo+1,nRGBIdx]) + formatDateTime('yyMMddHHmmss',now) + '.csv';
  sSerialNo := ReadFlashSerialNo(nFPgNo);
  sSerialNo := Format('sSerialNo : %s',[sSerialNo]);
  sDataHeader := 'Gray,DBV,x,y,LV,';

  advstrngrdDataView[nFPgNo].Cells[0, 0] := 'Gray';
  advstrngrdDataView[nFPgNo].Cells[1, 0] := 'DBV';
  advstrngrdDataView[nFPgNo].Cells[2, 0] := 'x';
  advstrngrdDataView[nFPgNo].Cells[3, 0] := 'y';
  advstrngrdDataView[nFPgNo].Cells[4, 0] := 'Lv';

  nWaitMS := 3000;
  nRetry  := 0;  // No Retry
  for I := 2047 downto 1 do begin
    if bIs_Stop then Exit;
    if i = 2047 then       //APL 40%  1Band
    begin
      GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,1,nSX,nSy,nEX,nEY);
      wdRet := Pg[nFPgNo].DP860_SendBistAPL(nRGBIdx,nRGBIdx,nRGBIdx,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
    end
    else if i = 1850 then //APL 60% 2Band
    begin
      GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,2,nSX,nSy,nEX,nEY);
      wdRet := Pg[nFPgNo].DP860_SendBistAPL(nRGBIdx,nRGBIdx,nRGBIdx,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
    end
    else if i = 1644 then
    begin
      wdRet := Pg[nFPgNo].SendDisplayPatBistRGB_9Bit(nRGBIdx,nRGBIdx,nRGBIdx,nWaitMS,nRetry);
    end;
    Sleep(100);

    wdRet := Pg[nFPgNo].SendDimmingBist(i, nWaitMS,nRetry);
    Sleep(100);
    wdRet := CaSdk2.Measure(nFPgNo, m_Ca410Data);
    advstrngrdDataView[nFPgNo].DisableAlign;
    advstrngrdDataView[nFPgNo].Cells[0, Abs(2048-i)] := IntToStr(nRGBIdx);
    advstrngrdDataView[nFPgNo].Cells[1, Abs(2048-i)] := IntToStr(i);
    advstrngrdDataView[nFPgNo].Cells[2, Abs(2048-i)] := FloatToStr(m_Ca410Data.xVal);
    advstrngrdDataView[nFPgNo].Cells[3, Abs(2048-i)] := FloatToStr(m_Ca410Data.yVal);
    advstrngrdDataView[nFPgNo].Cells[4, Abs(2048-i)] := FloatToStr(m_Ca410Data.LvVal);
    advstrngrdDataView[nFPgNo].EnableAlign;
    sData := Format('%d,%d,%4.4f,%4.4f,%4.4f,',[nRGBIdx,i,m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
    SaveCsvMeasureLog(nFPgNo,sSerialNo,sDataHeader,sData);
  end;
end;


procedure TfrmMainter.SaveCsvMeasureLog(nCh: Integer; sSerialNo,sDataHeader,sData : string);
var
  sFilePath, sFileName : String;
  sLine: String;
  txtF                 : Textfile;
  i : integer;
begin
//  m_csWriteCsvLog.Acquire; // 메인에서 sync 처리 되어서 들어옴
  sFilePath := Common.Path.Gamma + FormatDateTime('yymmdd',now) + '\';
  sFileName := sFilePath + PasScr[nCh].m_sFileCsv;
  if Common.CheckDir(sFilePath) then Exit;
  try
    AssignFile(txtF, sFileName);
    try

      if not FileExists(sFileName) then begin
        //Header 생성
        Rewrite(txtF);
        WriteLn(txtF, sSerialNo);
        WriteLn(txtF, sDataHeader);
      end;

      //Data
      Append(txtF);
      WriteLn(txtF, sData);
    except

    end;
  finally
    CloseFile(txtF); // Close the file

  end;
end;




function TfrmMainter.ReadFlashSerialNo(nPgNo: Integer): string;
var
nStartAddr,nLength : integer;
SerialNoBuf : TIdBytes;
wdRet : integer;
sAnsiStr : string;

begin
  nStartAddr := Common.TestModelInfoFLOW.SerialNoFlashInfo.nAddr;
  nLength :=  Common.TestModelInfoFLOW.SerialNoFlashInfo.nLength;
  Common.MLog(nPgNo,format('OCThreadFlash_READ_Proc nStartAddr : %d nLength : %d ',[nStartAddr,nLength]));

  SetLength(SerialNoBuf,nLength);
  wdRet :=  Pg[nPgNo].SendFlashRead(nStartAddr,nLength, @SerialNoBuf[0]);
  SetString(sAnsiStr, PAnsiChar(@SerialNoBuf[0]), nLength);
  sAnsiStr := Copy(sAnsiStr,1,nLength);
  SetLength(SerialNoBuf,0);
  Result := string(Trim(sAnsiStr));
end;

//function TfrmMainter.Make_reference_All_DBV_Gray_Data(fDBV : double) : TArray<Double>;
//var
//Lv_Gray_per_band : array of double;
//MAX_Lv : double;
//nGray : Integer;
//begin
//  setlength(Lv_Gray_per_band,512);
//
//  MAX_Lv := 1680.0;
//  if (Common.TestModelInfoFLOW.Is_3200NitDOE = true) then
//    MAX_Lv := 2100.0;
//  for nGray := 0 to 511 do begin
//    Lv_Gray_per_band[nGray] := MAX_Lv * Power(fDBV / 2047.0, 2.2) * Power(((511.0 - nGray) / 511.0), 2.2);
//  end;
//
//  Result := Lv_Gray_per_band;
//
//end;

function TfrmMainter.Make_reference_All_DBV_Gray_Data(fDBV: Double): TArray<Double>;
var
  Lv_Gray_per_band: TArray<Double>;
  MAX_Lv: Double;
  nGray: Integer;
begin
  SetLength(Lv_Gray_per_band, 512);

  MAX_Lv := 1680.0;
  if Common.TestModelInfoFLOW.Is_3200NitDOE then
    MAX_Lv := 2100.0;

  for nGray := 0 to 511 do
  begin
    Lv_Gray_per_band[nGray] := MAX_Lv * Power(fDBV / 2047.0, 2.2) * Power(((511.0 - nGray) / 511.0), 2.2);
  end;

  Result := Lv_Gray_per_band; // 수정: 배열을 반환하도록 변경
end;



procedure TfrmMainter.Run_GrayScale(nFPgNo,mBand_Count : Integer);
var
i,nDBVValue,nWaitMS,nRetry,wdRet : Integer;
m_Ca410Data: TBrightValue;
sFilePath : string;
sDataHeader, sData,sSerialNo : string;
nSX,nSy,nEX,nEY : Integer;

begin
  PasScr[nFPgNo].m_sFileCsv :=  format('%s_CH%d_%dband_GrayScale_',[Common.SystemInfo.EQPId,nFPgNo+1,mBand_Count]) + formatDateTime('yyMMddHHmmss',now) + '.csv';
  sSerialNo := ReadFlashSerialNo(nFPgNo);
  sSerialNo := Format('sSerialNo : %s',[sSerialNo]);
  sDataHeader := 'DBV,GRAY,x,y,LV,';
  advstrngrdDataView[nFPgNo].Cells[0, 0] := 'DBV';
  advstrngrdDataView[nFPgNo].Cells[1, 0] := 'Gray';
  advstrngrdDataView[nFPgNo].Cells[2, 0] := 'x';
  advstrngrdDataView[nFPgNo].Cells[3, 0] := 'y';
  advstrngrdDataView[nFPgNo].Cells[4, 0] := 'Lv';
  nWaitMS := 3000;
  nRetry  := 0;  // No Retry
//  Sleep(1000);
//  nDBVValue := BandDBV[mBand_Count-1];
//  wdRet := Pg[nFPgNo].SendDimmingBist(BandDBV[mBand_Count-1], nWaitMS,nRetry);  //2019-10-11 DIMMING (SendDisplayPat -> SendDisplayPWMPat)
  Sleep(1000);
  if not chkReversal.Checked then begin
    for I := 511 downto 1 do begin
      if bIs_Stop then exit;
      if chkOddMeasurement.Checked then begin
        if i mod 2 = 0 then Continue;
      end;

      if (mBand_Count = 1) or (mBand_Count = 2) then begin
        GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,mBand_Count,nSX,nSy,nEX,nEY);
        wdRet := Pg[nFPgNo].DP860_SendBistAPL(i,i,i,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
        if i = 511 then begin
           wdRet := Pg[nFPgNo].SendDimmingBist(CSharpDll.m_GetDBVdata(mBand_Count-1), nWaitMS,nRetry);
           Sleep(100);
        end;
      end
      else begin
       wdRet := Pg[nFPgNo].SendDisplayPatBistRGB_9Bit(i,i,i,nWaitMS,nRetry);
       if i = 511 then begin
           wdRet := Pg[nFPgNo].SendDimmingBist(CSharpDll.m_GetDBVdata(mBand_Count-1), nWaitMS,nRetry);
           Sleep(100);
       end;
      end;
      Sleep(100);
      wdRet := CaSdk2.Measure(nFPgNo, m_Ca410Data);
  //    AdvChartView1.Panes[0].Series[0].AddSinglePoint(m_Ca410Data.LvVal);
      advstrngrdDataView[nFPgNo].DisableAlign;

      advstrngrdDataView[nFPgNo].Cells[0, Abs(512-i)] := IntToStr(CSharpDll.m_GetDBVdata(mBand_Count-1));
      advstrngrdDataView[nFPgNo].Cells[1, Abs(512-i)] := IntToStr(i);
      advstrngrdDataView[nFPgNo].Cells[2, Abs(512-i)] := FloatToStr(m_Ca410Data.xVal);
      advstrngrdDataView[nFPgNo].Cells[3, Abs(512-i)] := FloatToStr(m_Ca410Data.yVal);
      advstrngrdDataView[nFPgNo].Cells[4, Abs(512-i)] := FloatToStr(m_Ca410Data.LvVal);
      advstrngrdDataView[nFPgNo].EnableAlign;
      sData := Format('%d,%d,%4.4f,%4.4f,%4.4f,',[CSharpDll.m_GetDBVdata(mBand_Count-1),i,m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
      SaveCsvMeasureLog(nFPgNo,sSerialNo,sDataHeader,sData);
    end;
  end
  else begin
    for I := 1 to 511 do begin
      if bIs_Stop then exit;
      if chkOddMeasurement.Checked then begin
        if i mod 2 = 0 then Continue;
      end;

      if (mBand_Count = 1) or (mBand_Count = 2) then begin
        GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,mBand_Count,nSX,nSy,nEX,nEY);
        wdRet := Pg[nFPgNo].DP860_SendBistAPL(i,i,i,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
        if i = 1 then begin
//           wdRet := Pg[nFPgNo].SendDimmingBist(BandDBV[mBand_Count-1], nWaitMS,nRetry);
          wdRet := Pg[nFPgNo].SendDimmingBist(CSharpDll.m_GetDBVdata(mBand_Count-1), nWaitMS,nRetry);
          Sleep(100);
        end;
      end
      else begin
      wdRet := Pg[nFPgNo].SendDisplayPatBistRGB_9Bit(i,i,i,nWaitMS,nRetry);
        if i = 1 then begin
           wdRet := Pg[nFPgNo].SendDimmingBist(CSharpDll.m_GetDBVdata(mBand_Count-1), nWaitMS,nRetry);
           Sleep(100);
        end;
      end;
      Sleep(100);
      wdRet := CaSdk2.Measure(nFPgNo, m_Ca410Data);
  //    AdvChartView1.Panes[0].Series[0].AddSinglePoint(m_Ca410Data.LvVal);
      advstrngrdDataView[nFPgNo].DisableAlign;

      advstrngrdDataView[nFPgNo].Cells[0, Abs(i)] := IntToStr(CSharpDll.m_GetDBVdata(mBand_Count-1));
      advstrngrdDataView[nFPgNo].Cells[1, Abs(i)] := IntToStr(i);
      advstrngrdDataView[nFPgNo].Cells[2, Abs(i)] := FloatToStr(m_Ca410Data.xVal);
      advstrngrdDataView[nFPgNo].Cells[3, Abs(i)] := FloatToStr(m_Ca410Data.yVal);
      advstrngrdDataView[nFPgNo].Cells[4, Abs(i)] := FloatToStr(m_Ca410Data.LvVal);
      advstrngrdDataView[nFPgNo].EnableAlign;
      sData := Format('%d,%d,%4.4f,%4.4f,%4.4f,',[CSharpDll.m_GetDBVdata(mBand_Count-1),i,m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
      SaveCsvMeasureLog(nFPgNo,sSerialNo,sDataHeader,sData);
    end;
  end;
end;

procedure TfrmMainter.Run_Measure_CEL_NY(nFPgNo: Integer; fSearch_Lv: Double);
var
sSerialNo,sDataHeader,sData : string;
output : TArray<Double>;
nDBV,nFind_Gray_index,nGray : Integer;
nSX,nSy,nEX,nEY,nWaitMS,nRetry,wdRet : integer;
m_Ca410Data: TBrightValue ;
fIdeal_Target_Lv : Double;
begin
  PasScr[nFPgNo].m_sFileCsv :=  format('%s_CH%d_CEL_NY_%f_GrayScale_',[Common.SystemInfo.EQPId,nFPgNo+1,fSearch_Lv]) + formatDateTime('yyMMddHHmmss',now) + '.csv';
  sSerialNo := ReadFlashSerialNo(nFPgNo);
  sSerialNo := Format('sSerialNo : %s',[sSerialNo]);
  sDataHeader := 'DBV,DBV_Nits,Gray,Measure_Lv,x,y';

  advstrngrdDataView[nFPgNo].Cells[0, 0] := 'DBV';
  advstrngrdDataView[nFPgNo].Cells[1, 0] := 'DBV_Nits';
  advstrngrdDataView[nFPgNo].Cells[2, 0] := 'Gray';
  advstrngrdDataView[nFPgNo].Cells[3, 0] := 'x';
  advstrngrdDataView[nFPgNo].Cells[4, 0] := 'y';
  advstrngrdDataView[nFPgNo].Cells[5, 0] := 'Lv';

  nWaitMS := 3000;
  nRetry  := 0;  // No Retry

  SetLength(output,2);

  wdRet := Pg[nFPgNo].SendDimmingBist(180, nWaitMS,nRetry);

  for nDBV := 180 to 2047 do begin
    if bIs_Stop then Exit;
    output := Find_Gray_index_Near_Target_1(nDBV,fSearch_Lv);
    if output[1] = -1 then continue;
    nFind_Gray_index := Trunc(output[0]);
    fIdeal_Target_Lv := output[1];

    nGray := 511 - nFind_Gray_index;

    if nDBV < 1645 then       //APL 100%  1Band
    begin
      wdRet := Pg[nFPgNo].SendDisplayPatBistRGB_9Bit(nGray,nGray,nGray,nWaitMS,nRetry);
    end
    else if nDBV <= 1850 then //APL 60% 2Band
    begin
      GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,2,nSX,nSy,nEX,nEY);
      wdRet := Pg[nFPgNo].DP860_SendBistAPL(nGray,nGray,nGray,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
    end
    else
    begin
      GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,1,nSX,nSy,nEX,nEY);
      wdRet := Pg[nFPgNo].DP860_SendBistAPL(nGray,nGray,nGray,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
    end;
    Sleep(50);
    wdRet := Pg[nFPgNo].SendDimmingBist(nDBV, nWaitMS,nRetry);
    Sleep(100);
    wdRet := CaSdk2.Measure(nFPgNo, m_Ca410Data);

    advstrngrdDataView[nFPgNo].DisableAlign;
    advstrngrdDataView[nFPgNo].Cells[0, Abs(nDBV-179)] := IntToStr(nDBV);
    advstrngrdDataView[nFPgNo].Cells[1, Abs(nDBV-179)] := FloatToStr(fIdeal_Target_Lv);
    advstrngrdDataView[nFPgNo].Cells[2, Abs(nDBV-179)] := IntToStr(nGray);

    advstrngrdDataView[nFPgNo].Cells[3, Abs(nDBV-179)] := FloatToStr(m_Ca410Data.xVal);
    advstrngrdDataView[nFPgNo].Cells[4, Abs(nDBV-179)] := FloatToStr(m_Ca410Data.yVal);
    advstrngrdDataView[nFPgNo].Cells[5, Abs(nDBV-179)] := FloatToStr(m_Ca410Data.LvVal);
    advstrngrdDataView[nFPgNo].EnableAlign;

    sData := Format('%d,%4.4f,%d,%4.4f,%4.4f,%4.4f,',[nDBV,fIdeal_Target_Lv,nGray,m_Ca410Data.LvVal,m_Ca410Data.xVal,m_Ca410Data.yVal]);
    SaveCsvMeasureLog(nFPgNo,sSerialNo,sDataHeader,sData);

  end;
  SetLength(output,0);
end;


procedure TfrmMainter.btnMeasureClick(Sender: TObject);
var
  nBandIdx, wdRet,nRGBIdx,j: integer;
  sRGB : string;
  fDelay: Double;
  afDelays: array of integer;
begin
  bIs_Stop := false;

  if cboMeasureCH.ItemIndex <> 4 then begin
    ThreadTaskTracking( procedure var i : Integer; begin
      ControlDio.lockCarrier(cboMeasureCH.ItemIndex,true);
      ControlDio.ProbeForward(cboMeasureCH.ItemIndex);
      wdRet := Pg[cboMeasureCH.ItemIndex].SendPowerBistOn(1{On},False,3000,0);
      if rbGrayScale.Checked then begin
        Sleep(500);
        if cboBandCount.Text = 'ALLBamd' then begin
          for I := 1 to 32 do begin
            if bIs_Stop then Break;
            advstrngrdDataView[cboMeasureCH.ItemIndex].ClearAll;
            Run_GrayScale(cboMeasureCH.ItemIndex,i);
          end;
        end
        else begin
          advstrngrdDataView[cboMeasureCH.ItemIndex].ClearAll;

          nBandIdx := cboBandCount.ItemIndex;
          Run_GrayScale(cboMeasureCH.ItemIndex,nBandIdx);
        end;
      end
      else if rbDBVTracking.Checked then begin
        Sleep(500);
        sRGB := cboGrayRGB.Text;
        advstrngrdDataView[cboMeasureCH.ItemIndex].ClearAll;
        Run_DBVtracking(cboMeasureCH.ItemIndex,StrToIntDef(sRGB,0));
      end
      else if rbCEL_Yufeng.Checked then
      begin
        afDelays := [1, 5,9, 10, 50, 90, 100, 1000, 10000];
        for i in afDelays do
        begin
          Sleep(500);
          Run_Measure_CEL_NY(cboMeasureCH.ItemIndex, i/10);
          advstrngrdDataView[cboMeasureCH.ItemIndex].ClearAll;
          if bIs_Stop then
            Break;
          Sleep(100);
        end;
      end;

      wdRet := Pg[cboMeasureCH.ItemIndex].SendPowerBistOn(0{Off},False,3000,0); //TBD:DP860?
      ControlDio.ProbeBackward(cboMeasureCH.ItemIndex);
      ControlDio.UnlockCarrier(cboMeasureCH.ItemIndex,true);

    end,btnMeasure);

  end
  else begin

    for j := DefCommon.CH1 to DefCommon.CH4 do begin
      if j = DefCommon.CH1 then begin
        ThreadTaskTracking( procedure var i : Integer; begin

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.lockCarrier(0,true);
            ControlDio.ProbeForward(0);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

          wdRet := Pg[0].SendPowerBistOn(1{On},False,3000,0);
          if rbGrayScale.Checked then begin
            Sleep(500);
            if cboBandCount.Text = 'ALLBamd' then begin
              for I := 1 to 32 do begin
                if bIs_Stop then Break;
                advstrngrdDataView[0].ClearAll;
                Run_GrayScale(0,i);
              end;
            end
            else begin
              advstrngrdDataView[0].ClearAll;
              nBandIdx := cboBandCount.ItemIndex;
              Run_GrayScale(0,nBandIdx);
            end;
          end
          else if rbDBVTracking.Checked then begin
            nRGBIdx := StrToIntDef(cboGrayRGB.text,0);
            advstrngrdDataView[0].ClearAll;
            Run_DBVtracking(0,nRGBIdx);
          end
          else if rbCEL_Yufeng.Checked then begin
            Sleep(500);
            Run_Measure_CEL_NY(0,0.1);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,0.5);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,0.9);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,1);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,5);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,9);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,10);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,100);
            advstrngrdDataView[0].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(0,1000);
          end;
          wdRet := Pg[0].SendPowerBistOn(0{Off},False,3000,0); //TBD:DP860?

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.ProbeBackward(0);
            ControlDio.UnlockCarrier(0,true);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

        end,btnMeasure);

      end
      else if j = DefCommon.CH2 then begin
        ThreadTaskTracking( procedure var i : Integer; begin

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.lockCarrier(1,true);
            ControlDio.ProbeForward(1);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

          wdRet := Pg[1].SendPowerBistOn(1{On},False,3000,0);
          if rbGrayScale.Checked then begin
            Sleep(500);
            if cboBandCount.Text = 'ALLBamd' then begin
              for I := 1 to 32 do begin
                if bIs_Stop then Break;
                advstrngrdDataView[1].ClearAll;
                Run_GrayScale(1,i);
              end;
            end
            else begin
              advstrngrdDataView[1].ClearAll;
              nBandIdx := cboBandCount.ItemIndex;
              Run_GrayScale(1,nBandIdx);
            end;
          end
          else if rbDBVTracking.Checked then begin
            nRGBIdx := StrToIntDef(cboGrayRGB.text,0);
            advstrngrdDataView[1].ClearAll;
            Run_DBVtracking(1,nRGBIdx);
          end
          else if rbCEL_Yufeng.Checked then begin
            Sleep(500);
            Run_Measure_CEL_NY(1,0.1);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,0.5);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,0.9);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,1);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,5);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,9);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,10);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,100);
            advstrngrdDataView[1].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(1,1000);
          end;
          wdRet := Pg[1].SendPowerBistOn(0{Off},False,3000,0); //TBD:DP860?

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.ProbeBackward(1);
            ControlDio.UnlockCarrier(1,true);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

        end,btnMeasure);

      end
      else if j = DefCommon.CH3 then begin
        ThreadTaskTracking( procedure var i : Integer; begin

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.lockCarrier(2,true);
            ControlDio.ProbeForward(2);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

          wdRet := Pg[2].SendPowerBistOn(1{On},False,3000,0);
          if rbGrayScale.Checked then begin
            Sleep(500);
            if cboBandCount.Text = 'ALLBamd' then begin
              for I := 1 to 32 do begin
                if bIs_Stop then Break;
                advstrngrdDataView[2].ClearAll;
                Run_GrayScale(2,i);
              end;
            end
            else begin
              advstrngrdDataView[2].ClearAll;
              nBandIdx := cboBandCount.ItemIndex;
              Run_GrayScale(2,nBandIdx);
            end;
          end
          else if rbDBVTracking.Checked then begin
            nRGBIdx := StrToIntDef(cboGrayRGB.text,0);
            advstrngrdDataView[2].ClearAll;
            Run_DBVtracking(2,nRGBIdx);
          end
          else if rbCEL_Yufeng.Checked then begin
            Sleep(500);
            Run_Measure_CEL_NY(2,0.1);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,0.5);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,0.9);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,1);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,5);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,9);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,10);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,100);
            advstrngrdDataView[2].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(2,1000);
          end;
          wdRet := Pg[2].SendPowerBistOn(0{Off},False,3000,0); //TBD:DP860?

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.ProbeBackward(2);
            ControlDio.UnlockCarrier(2,true);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

        end,btnMeasure);

      end
      else if j = DefCommon.CH4 then begin
        ThreadTaskTracking( procedure var i : Integer; begin

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.lockCarrier(3,true);
            ControlDio.ProbeForward(3);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

          wdRet := Pg[3].SendPowerBistOn(1{On},False,3000,0);
          if rbGrayScale.Checked then begin
            Sleep(500);
            if cboBandCount.Text = 'ALLBamd' then begin
              for I := 1 to 32 do begin
                if bIs_Stop then Break;
                advstrngrdDataView[3].ClearAll;
                Run_GrayScale(3,i);
              end;
            end
            else begin
              advstrngrdDataView[3].ClearAll;
              nBandIdx := cboBandCount.ItemIndex;
              Run_GrayScale(3,nBandIdx);
            end;
          end
          else if rbDBVTracking.Checked then begin
            nRGBIdx := StrToIntDef(cboGrayRGB.text,0);
            advstrngrdDataView[3].ClearAll;
            Run_DBVtracking(3,nRGBIdx);
          end
          else if rbCEL_Yufeng.Checked then begin
            Sleep(500);
            Run_Measure_CEL_NY(3,0.1);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,0.5);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,0.9);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,1);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,5);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,9);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,10);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,100);
            advstrngrdDataView[3].ClearAll;
            sleep(100);
            Run_Measure_CEL_NY(3,1000);
          end;
          wdRet := Pg[3].SendPowerBistOn(0{Off},False,3000,0); //TBD:DP860?

          Mutex.Acquire; // 뮤텍스 획득
          try
            ControlDio.ProbeBackward(3);
            ControlDio.UnlockCarrier(3,true);
          finally
            Mutex.Release; // 뮤텍스 반환
          end;

        end,btnMeasure);

      end
    end;
  end;
end;


procedure TfrmMainter.btnMemChInfoClick(Sender: TObject);
var
  nCh, i , nMemCh: Integer;
  rx, ry, rLv : Double;
  gx, gy, gLv : Double;
  bx, by, bLv : Double;
  wx, wy, wLv : Double;
  nErr : Integer;
  sDebug : string;
begin
//  nCh := cboScriptCh.ItemIndex;
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;
  nMemCh := 0;
  // Get Current Memory Channel
{$IFDEF CA410_USE}
  nErr := CaSdk2.GetMemCh(nCh,nMemCh);
  if nErr <> 0 then begin
    sDebug := Format('CaSDK Get Mem Ch - Error Code is %d',[nErr]);
    mmoAutoCalLog.Lines.Add(sDebug);
    Exit;
  end;
  sDebug := Format('Current Mem Channel is %d',[nMemCh]);
  mmoAutoCalLog.Lines.Add(sDebug);

  // Get Information.
//  nErr := fGetMemChData(nCh,nMemCh, rx, ry, rLv, gx, gy, gLv , bx, by, bLv , wx, wy, wLv);

  nErr := CaSdk2.GetMemInfo(nCh,nMemCh, rLv, rx, ry, gLv ,gx, gy, bLv , bx, by , wLv ,  wx, wy);
  if nErr <> 0 then begin
    sDebug := Format('CaSDK Mem Ch Data - Error Code is %d',[nErr]);
    mmoAutoCalLog.Lines.Add(sDebug);
    Exit;
  end;
  sDebug := Format('Saved Target Data R : x(%0.4f), y(%0.4f), lv(%0.4f) ',[rx, ry, rLv]);
  mmoAutoCalLog.Lines.Add(sDebug);
  sDebug := Format('Saved Target Data G : x(%0.4f), y(%0.4f), lv(%0.4f) ',[gx, gy, gLv]);
  mmoAutoCalLog.Lines.Add(sDebug);
  sDebug := Format('Saved Target Data B : x(%0.4f), y(%0.4f), lv(%0.4f) ',[bx, by, bLv]);
  mmoAutoCalLog.Lines.Add(sDebug);
  sDebug := Format('Saved Target Data W : x(%0.4f), y(%0.4f), lv(%0.4f) ',[wx, wy, wLv]);
  mmoAutoCalLog.Lines.Add(sDebug);
{$ENDIF}

{$IFDEF CA310_USE}
  ReadCa310MemInfo;
{$ENDIF}

end;

procedure TfrmMainter.btnMotorStopClick(Sender: TObject);
begin

end;

{$IFDEF ADLINK_DIO}
procedure TfrmMainter.ADDioStatus(InDio, OutDio: ADioStatus);
var
  i : integer;
begin

  for i := 0 to Pred(DefDio.MAX_ADLINK_IO_CNT) do begin
    ledIn2[i].Value := InDio[i];

    ledOut2[i].Value := OutDio[i];
    if OutDio[i] then btnOutSig2[i].Caption := 'Off'
    else              btnOutSig2[i].Caption := 'On';
  end;


//  if bIn then begin
//    for i := 0 to Pred(DefDio.MAX_ADLINK_IO_CNT) do begin
//      ledIn2[i].Value :=  IoDio[i];
//    end;
//  end
//  else begin
//    for i := 0 to Pred(DefDio.MAX_ADLINK_IO_CNT) do begin
//      ledOut2[i].Value :=  IoDio[i];
//      if IoDio[i] then btnOutSig2[i].Caption := 'Off'
//      else             btnOutSig2[i].Caption := 'On';
//    end;
//  end;
//  pnlDioCardMsg.Caption := sErrMsg;

end;
{$ENDIF}

procedure TfrmMainter.btnAutoBackClick(Sender: TObject);
var
nCh : Integer;
begin
  nCh := cboChannelFrobe.ItemIndex;
  if nCh = -1 then Exit;
  ThreadStartDio(procedure begin
    ControlDio.ProbeBackward(nCh);
  end);
end;

procedure TfrmMainter.btnAutoBackPreOCClick(Sender: TObject);
var
nCH  : Integer;
begin
  nCh := cboChannelFrobePreOC.ItemIndex;
  if nCh = -1 then Exit;
  ThreadStartDio(procedure begin
    ControlDio.MovingProbe(nCh,False);
  end);
end;

procedure TfrmMainter.btnAutoCalClick(Sender: TObject);
var
  bRet : Boolean;
  i : Integer;
{$IFDEF CA310_USE}
  GetxyLv : TLvXY;
  GetAllxy, GetLimitxy: TAllLvXy;

{$ENDIF}
  sDebug,sTemp: string;
  thAutoCal : TThread;
  nProbeNum, nStage : Integer;
{$IFDEF CA410_USE}
  GetxyLv : TLvXY;
  GetAllxy, GetLimitxy: TAllLvXy;

  nCh : Integer;
{$ENDIF}
begin

{$IFDEF CA410_USE}
  nCh := GetProbeNum;
  if cboCalData.ItemIndex < 0 then Exit;
  if cboModelType.ItemIndex < 0 then Exit;
  ClearCalResult;
  mmoAutoCalLog.Lines.Clear;
  SaveOptCsv(cboCalData.Items[cboCalData.ItemIndex]);
  Common.SaveOpticInfo(cboModelType.ItemIndex);
  m_bStopCa310Cal := False;
  bRet := True;
  sDebug := '';
  pnlCalLog.Caption := '';
  for i := DefCaSdk.IDX_RED to  DefCaSdk.IDX_MAX do begin
    sTemp      := gridTarget.Cells[1,i+1];
    GetxyLv.x  := StrToFloatDef(sTemp,0.0);

    sTemp      := gridTarget.Cells[2,i+1];
    GetxyLv.y  := StrToFloatDef(sTemp,0.0);

    sTemp      := gridTarget.Cells[3,i+1];
    GetxyLv.Lv := StrToFloatDef(sTemp,0.0);
    GetAllxy[i] := GetxyLv;

    GetLimitxy[i].x := 0.005; // StrToFloatDef(grdTarget.Cells[4,i+1],0.0);
    GetLimitxy[i].y := 0.005; //StrToFloatDef(grdTarget.Cells[5,i+1],0.0);
    case i of
      DefCaSdk.IDX_RED    :  GetLimitxy[i].Lv := 2;
      DefCaSdk.IDX_GREEN  :  GetLimitxy[i].Lv := 5;
      DefCaSdk.IDX_BLUE   :  GetLimitxy[i].Lv := 1;
      DefCaSdk.IDX_WHITE  :  GetLimitxy[i].Lv := 6;
    end;
//    GetLimitxy[i].Lv := StrToFloatDef(grdTarget.Cells[6,i+1],0.0);

    if (GetxyLv.x <= 0) or (GetxyLv.y <= 0) or (GetxyLv.Lv <= 0)  then begin
      bRet := False;
      sDebug := sDebug + 'Grid: ' + gridTarget.Cells[1,i+1] +','+ gridTarget.Cells[2,i+1] +','+ gridTarget.Cells[3,i+1];
      sDebug := sDebug + Format(' Idx(%d),x(%0.4f),y(%0.4f),Lv(%0.4f),%s',[i,GetxyLv.x,GetxyLv.y,GetxyLv.Lv,sTemp]);
      Break;
    end;
//    if (GetxyLv.x + GetxyLv.y) >= 1 then begin
//      sDebug := sDebug + Format('Idx(%d),x(%0.4f),y(%0.4f),Sum(%0.4f)',[i,GetxyLv.x,GetxyLv.y,(GetxyLv.x + GetxyLv.y)]);
//      bRet := False;
//
//      Break;
//    end;
  end;

  if not bRet then begin
    mmoAutoCalLog.Lines.Add('Target Value is wrong! Please Check Target Data');
    mmoAutoCalLog.Lines.Add(sDebug);
    Ca310CalControlPnl(True);
    Exit;
  end;

  thAutoCal := TThread.CreateAnonymousThread(procedure var i, nPgNo : Integer; begin
    nPgNo := GetProbeNum;
  // PG 연결 안되어 있으면 Exit.
    if Pg[nPgNo].StatusPg in [pgDisconn,pgWait] then begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        sDebug := Format('Channel %d is disconnected',[nPgNo + 1]);
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
      Exit;
    end;
    // CA310 Connection Check.
    if not CaSdk2.m_bConnection[nPgNo] then begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        sDebug := Format('CA410 on Channel %X is disconnected',[nPgNo + 1]);
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
      Exit;
    end;

    if m_bStopCa310Cal then Exit;
    // Power Off 부터 다하자.
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      Pg[i].SendPowerOn(0);   // Added by KTS 2023-01-09 오후 4:30:48  PG POWER 확인
    end;
    sleep(100);

    // Probe Move.
    if ControlDio <> nil then ControlDio.ProbeForward(nPgNo);
    sleep(500);
    // Power On.
    if Pg[nPgNo].SendPowerOn(1) <> WAIT_OBJECT_0 then begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        sDebug := Format('Ch%d Power On ==> NAK ',[nPgNo + 1]);
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
      Exit;
    end;
//
//    sleep(600);
//    Pg[nCh].SendSpiWp(0);
//    PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_9,False); // Added by KTS 2023-01-09 오후 4:31:53  Flow 확인
    // White.
    PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_1); // Added by KTS 2023-01-09 오후 4:32:18 Flow 확인

    for i := 0 to Pred(Common.OpticInfo.CalAgingTime) do begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        pnlCalLog.Caption := Format('%d Sec',[(Common.OpticInfo.CalAgingTime-i)]);
      end);
      sleep(1000);
      if m_bStopCa310Cal then break;
    end;
    pnlCalLog.Caption := '';

    if not m_bStopCa310Cal then begin
      CA410Calibration( thAutoCal,GetAllxy,GetLimitxy);
    end;
    Pg[nPgNo].SendPowerOn(0); // power Off.   // Added by KTS 2023-01-09 오후 4:32:18 Flow 확인
    sleep(500);
    if ControlDio <> nil then ControlDio.ProbeBackward(nPgNo div 2);

    thAutoCal.Synchronize(thAutoCal, procedure begin
      Ca310CalControlPnl(True);
    end);
  end);
  Ca310CalControlPnl(False);
  thAutoCal.Start;
{$ENDIF}  //CA410_USE
{$IFDEF CA310_USE}
  nProbeNum := GetProbeNum;
  if nProbeNum < 5 then nStage := 0
  else                  nStage := 1;
  if cboCalData.ItemIndex < 0 then Exit;
  if cboModelType.ItemIndex < 0 then Exit;

  m_bStopCa310Cal := False;
  ClearCalResult;
  mmoAutoCalLog.Lines.Clear;
  SaveOptCsv(cboCalData.Items[cboCalData.ItemIndex]);
  Common.SaveOpticInfo(cboModelType.ItemIndex);
//  edtRty_Optic_GRR.Text   := Format('%d',[Common.OpticInfo.OpticGRR_RetryCnt]); //IntToStr(DongaYT.SysInfo.OpticGRR_RetryCnt);

  bRet := True;
  sDebug := '';
  pnlCalLog.Caption := '';
  for i := DefCa310.IDX_RED to  DefCa310.IDX_MAX do begin
    sTemp      := gridTarget.Cells[1,i+1];
    GetxyLv.x  := StrToFloatDef(sTemp,0.0);

    sTemp      := gridTarget.Cells[2,i+1];
    GetxyLv.y  := StrToFloatDef(sTemp,0.0);

    sTemp      := gridTarget.Cells[3,i+1];
    GetxyLv.Lv := StrToFloatDef(sTemp,0.0);
    GetAllxy[i] := GetxyLv;

    GetLimitxy[i].x := 0.005; // StrToFloatDef(grdTarget.Cells[4,i+1],0.0);
    GetLimitxy[i].y := 0.005; //StrToFloatDef(grdTarget.Cells[5,i+1],0.0);
    case i of
      DefCa310.IDX_RED    :  GetLimitxy[i].Lv := 2;
      DefCa310.IDX_GREEN  :  GetLimitxy[i].Lv := 5;
      DefCa310.IDX_BLUE   :  GetLimitxy[i].Lv := 1;
      DefCa310.IDX_WHITE  :  GetLimitxy[i].Lv := 6;
    end;
//    GetLimitxy[i].Lv := StrToFloatDef(grdTarget.Cells[6,i+1],0.0);

    if (GetxyLv.x <= 0) or (GetxyLv.y <= 0) or (GetxyLv.Lv <= 0)  then begin
      bRet := False;
      sDebug := sDebug + 'Grid: ' + gridTarget.Cells[1,i+1] +','+ gridTarget.Cells[2,i+1] +','+ gridTarget.Cells[3,i+1];
      sDebug := sDebug + Format(' Idx(%d),x(%0.4f),y(%0.4f),Lv(%0.4f),%s',[i,GetxyLv.x,GetxyLv.y,GetxyLv.Lv,sTemp]);
      Break;
    end;
    if (GetxyLv.x + GetxyLv.y) >= 1 then begin
      sDebug := sDebug + Format('Idx(%d),x(%0.4f),y(%0.4f),Sum(%0.4f)',[i,GetxyLv.x,GetxyLv.y,(GetxyLv.x + GetxyLv.y)]);
      bRet := False;

      Break;
    end;
  end;

  if not bRet then begin
    mmoAutoCalLog.Lines.Add('Target Value is wrong! Please Check Target Data');
    mmoAutoCalLog.Lines.Add(sDebug);
    Ca310CalControlPnl(True);
    Exit;
  end;
//  Common.SaveOpticInfo;
//  // Carrier Mode 일경우 Contact 신호로 IO 제어 확인 하자.
//  if not Common.SystemInfo.OcManualType then begin
//    // case 1 : keep going if contact up
//    // case 2 : Stop & contact up...
//    if not AxDio.m_bInDio[Defdio.DIO_IN_CONTACT_UP_1 + nProbeNum - 1] then begin
//      thAutoCal := TThread.CreateAnonymousThread(procedure var i, nPgNo, nProbeNum : Integer; begin
//        nProbeNum := GetProbeNum;
//        nPgNo := nStage * 4 + nProbeNum - 1;
//        // Power Off 부터 다하자.
//        for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
//          Pg[i].SendPowerOn(0);
//        end;
//        sleep(600);
//        thAutoCal.Synchronize(thAutoCal, procedure begin
//          AxDio.SetAutoControl(nStage,True);
//        end);
//        for i := 0 to 40 do begin
//          sleep(100);
//          if AxDio.m_bInDio[Defdio.DIO_IN_CONTACT_UP_1 + nProbeNum - 1] then begin
//            break;
//          end;
//        end;
//        if AxDio.m_bInDio[Defdio.DIO_IN_CONTACT_UP_1 + nProbeNum - 1] then begin
//          // Power On.
//          if Pg[nPgNo].SendPowerOn(2) <> WAIT_OBJECT_0 then begin
//            thAutoCal.Synchronize(thAutoCal, procedure begin
//              sDebug := Format('Ch%d Power On ==> NAK ',[nPgNo + 1]);
//              mmoAutoCalLog.Lines.Add(sDebug);
//              Ca310CalControlPnl(True);
//            end);
//            Exit;
//          end;
//          Sleep(100);
//          Pg[nPgNo].SendSinglePat(255,255,255);
//        end
//        else begin
//          thAutoCal.Synchronize(thAutoCal, procedure begin
//            sDebug := Format('Ch%d Contact Up Failed... ',[nPgNo + 1]);
//            mmoAutoCalLog.Lines.Add(sDebug);
//          end);
//        end;
//        Ca310CalControlPnl(True);
//      end);
//      thAutoCal.Start;
//      Exit;
//    end;
//  end;
  thAutoCal := TThread.CreateAnonymousThread(procedure var i, nPgNo, nProbeNum : Integer; begin
    nProbeNum := GetProbeNum;
    nPgNo := nProbeNum - 1;
  // PG 연결 안되어 있으면 Exit.
    if Pg[nPgNo].Status in [pgDisconnect,pgWait] then begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        sDebug := Format('Channel %d is disconnected',[nPgNo + 1]);
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
      Exit;
    end;
    // CA310 Connection Check.
    if not DongaCa310[nStage].m_bConnection then begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        sDebug := Format('CA310 on Stage %X is disconnected',[nStage + 10]);
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
      Exit;
    end;

    if m_bStopCa310Cal then Exit;
    // Power Off 부터 다하자.
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      Pg[i].SendPowerOn(0);
    end;
    sleep(100);

    // Probe Move.
//    if not Common.SystemInfo.OcManualType then AxDio.SetAutoControl(nStage,True);
    sleep(500);
    // Power On.
    if Pg[nPgNo].SendPowerOn(2) <> WAIT_OBJECT_0 then begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        sDebug := Format('Ch%d Power On ==> NAK ',[nPgNo + 1]);
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
      Exit;
    end;

    // White.
    if Pg[nPgNo].SendSinglePat(255,255,255) <> WAIT_OBJECT_0 then begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        sDebug := Format('Ch%d Display Single Pattern 255 Gray ==> NAK ',[nPgNo + 1]);
        mmoAutoCalLog.Lines.Add(sDebug);
        Ca310CalControlPnl(True);
      end);
      Exit;
    end;

    for i := 0 to Pred(Common.OpticInfo.CalAgingTime) do begin
      thAutoCal.Synchronize(thAutoCal, procedure begin
        pnlCalLog.Caption := Format('%d Sec',[(Common.OpticInfo.CalAgingTime-i)]);
      end);
      sleep(1000);
      if m_bStopCa310Cal then break;
    end;
    pnlCalLog.Caption := '';

    if not m_bStopCa310Cal then begin
      CA310Calibration( thAutoCal,GetAllxy,GetLimitxy);
    end;
    Pg[nPgNo].SendPowerOn(0); // power Off.
    sleep(500);
    if Common.SystemInfo.OcManualType then begin
      AxDio.SetAutoManualCtrl(nStage,False);
      AxDio.SetAutoManualOpen(nStage);
    end
    else begin
      AxDio.SetAutoControl(nStage,False);
    end;

    thAutoCal.Synchronize(thAutoCal, procedure begin
      Ca310CalControlPnl(True);
    end);
  end);
  Ca310CalControlPnl(False);
  thAutoCal.Start;                                        
{$ENDIF}
end;

procedure TfrmMainter.PowerOffSeq(nCh: Integer);
begin
  ThreadTask( procedure begin
    SendGuiDisplay(nCh,'Power OFF');                   
    Pg[nCh].SendPowerOn(0);
    Pg[nCh].SetPwrMeasureTimer(False);
  end, btnPowerOff);
end;

procedure TfrmMainter.PowerOnSeq(nCh: Integer);
begin
  ThreadTask( procedure begin
    SendGuiDisplay(nCh,'Power On');
    Pg[nCh].SendPowerOn(1);
    Pg[nCh].SetPwrMeasureTimer(False);
  end, btnPowerOn);
end;


procedure TfrmMainter.btnPowerOnClick(Sender: TObject);
var
  nCh, i, nTemp : Integer;
begin
  nCh := cboChannelPg.ItemIndex;
  if nCh = -1 then Exit;
  if not (Pg[0].StatusPg in [pgReady]) then begin
    SendGuiDisplay(nCh,'Power On  ...Failed(Check PG Status)');
    Exit;
  end;
  //
  btnPowerOn.Enabled := False;
  PowerOnSeq(nCh); //TBD:AF9?
end;

procedure TfrmMainter.btnProbeBlackClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;
PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_5);
end;

procedure TfrmMainter.btnProbeGreenClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;
PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_3);
end;
procedure TfrmMainter.btnProbeLockCarrierClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;

  if ControlDio <> nil then begin
    if rdoProbe1.Checked or rdoProbe2.Checked or rdoProbe3.Checked or rdoProbe4.Checked then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then  begin
          ThreadStartDio(procedure begin
           Pg[nCh].SendPowerOn(1);
          end);
         end;
    end;
  end;
end;

procedure TfrmMainter.btnProbeRedClick(Sender: TObject);

var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;


PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_2);
end;

procedure TfrmMainter.btnProbeUnLockCarrierClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;

  if ControlDio <> nil then begin
    if rdoProbe1.Checked or rdoProbe2.Checked or rdoProbe3.Checked or rdoProbe4.Checked then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin

        ThreadStartDio(procedure begin
           Pg[nCh].SendPowerOn(0);
        end);
      end;
    end;
  end;
end;

procedure TfrmMainter.btnProbeWhiteClick(Sender: TObject);
var
nCH : Integer;
begin
  if rdoProbe1.Checked then nCH := 0
  else if rdoProbe2.Checked then nCH := 1
  else if rdoProbe3.Checked then nCH := 2
  else if rdoProbe4.Checked then nCH := 3;
  if nCH > DefCommon.MAX_CH  then Exit;
PasScr[nCh].RunSeq(DefScript.SEQ_MAINT_1);
end;

procedure TfrmMainter.btnOneTimeMeasureClick(Sender: TObject);
{$IFDEF CA310_USE}
var
  getData : TAChExt;
  sDebug, sCh  : string;
  nCh, i     : Integer;
  nProbeNum, nStage, nProbeCh : Integer;
{$ENDIF}
{$IFDEF CA410_USE}
var
  nCh : Integer;
  sDebug : string;
  getData : TBrightValue;
{$ENDIF}
begin
{$IFDEF CA410_USE}
  nCh := GetProbeNum;

  CaSdk2.Measure(nCh,GetData);
  sDebug := Format('Get Lv data : Probe %d, x(%0.5f), y(%0.5f), Lv(%0.5f)',
                    [nCh+1,  getData.xVal,getData.yVal,getData.LvVal]);
  mmoAutoCalLog.Lines.Add(sDebug);

{$ENDIF}
{$IFDEF CA310_USE}
  nProbeNum := GetProbeNum;
  if nProbeNum < 5 then nStage := 0
  else                  nStage := 1;

  sCh := '';
  nCh := defcommon.MAX_PG_CNT div MAX_JIG_CNT;
  nProbeCh :=  ((nProbeNum - 1) mod nCh)+1;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if Common.SystemInfo.UseCh[nStage*nCh + i] then begin
      sCh := sCh + Format('%d',[i+1]);
    end;
  end;

  DongaCa310[nStage].Ca310Shot(DefCa310.CA310_LvXY,sCh,getData);
  sDebug := Format('Get Lv data : Probe %d, x(%0.5f), y(%0.5f), Lv(%0.5f)',
                    [nProbeNum, getData[nProbeCh].ColorValX,getData[nProbeCh].ColorValY,getData[nProbeCh].GrayVal]);
  mmoAutoCalLog.Lines.Add(sDebug);
{$ENDIF}
end;


procedure TfrmMainter.RzPageControl1Click(Sender: TObject);   // 2018-06-08 jhhwang
begin

  if RzPageControl1.ActivePage = TabSheet1 then begin
      Common.MLog(DefCommon.MAX_SYSTEM_LOG,'Mainter: PG Comm');
  end
  else if RzPageControl1.ActivePage = tabIoMap then begin
      Common.MLog(DefCommon.MAX_SYSTEM_LOG,'Mainter: IO MAP');
  end
{$IFDEF CA310_USE}
  else if RzPageControl1.ActivePage = tbCa31AutoCal then begin
      Common.MLog(DefCommon.MAX_SYSTEM_LOG,'Mainter: CA310 Auto Cal');
  end
  else if RzPageControl1.ActivePage = tbCa310AutoCorr then begin
      Common.MLog(DefCommon.MAX_SYSTEM_LOG,'Mainter: CA310 Auto Corr');
  end
  else if RzPageControl1.ActivePage = tbOcTables then begin
      Common.MLog(DefCommon.MAX_SYSTEM_LOG,'Mainter: Confirm OCTables');
  end
{$ENDIF}
  else if RzPageControl1.ActivePage = tbSystemInfo then begin
      Common.MLog(DefCommon.MAX_SYSTEM_LOG,'Mainter: System Information');
  end
{$IFDEF ISPD_POCB}
  else if RzPageControl1.ActivePage = tabLoaderPlcComm then begin
      Common.MLog(DefCommon.MAX_SYSTEM_LOG,'Mainter: PlcComm');
  end;
{$ENDIF}
end;

procedure TfrmMainter.btnSaveCalResultClick(Sender: TObject);
var
  sSaveFile : string;
begin
  dlgSavePro.InitialDir := Common.Path.UserCalLog;
  dlgSavePro.Filter     := 'Cal Result Files (*.csv)|*.csv';
  if dlgSavePro.Execute then begin
    try
      if Pos('.csv',LowerCase(dlgSavePro.FileName)) = 0 then begin
        sSaveFile := dlgSavePro.FileName + '.csv';
      end
      else begin
        sSaveFile := dlgSavePro.FileName;
      end;
      grdCalVerify.SaveToCSV(sSaveFile);
    finally
    end;
  end;
end;

procedure TfrmMainter.btnScriptOpenClick(Sender: TObject);
begin
  RzOpenDialog1.InitialDir := common.Path.Maint;
  if RzOpenDialog1.Execute then begin
    ScrMemo1.Lines.LoadFromFile(RzOpenDialog1.FileName);
  end;
end;

procedure TfrmMainter.btnScriptSaveClick(Sender: TObject);
begin
  dlgSavePro.InitialDir := common.Path.Maint;
  if dlgSavePro.Execute then begin
    ScrMemo1.Lines.SaveToFile(dlgSavePro.FileName);
  end;
end;

procedure TfrmMainter.btnPgFileOpenClick(Sender: TObject);
begin
  if RzOpenDialog1.Execute then begin
    edPgFileSend.Text := RzOpenDialog1.FileName;
  end;
end;

procedure TfrmMainter.btnPgSendCmdClick(Sender: TObject);
var
  nCh, i : Integer;
begin
//  nCh := DefCommon.CH1; //cboChannelPg.ItemIndex;         ]
  nCh := cboChannelPg.ItemIndex;
  if nCh > DefCommon.MAX_CH then begin
    for i := 0 to DefCommon.MAX_CH do begin
      PgCmdThread(i);
    end;
  end
  else begin

    PgCmdThread(nCh);
  end;
end;


procedure TfrmMainter.btnPowerOffClick(Sender: TObject);
var
  nCh, i, nTemp : Integer;
begin
  nCh := cboChannelPg.ItemIndex;
  if nCh = -1 then Exit;
  btnPowerOff.Enabled := False;
  if nCh in [8,9] then begin
    nTemp := Pred(DefCommon.MAX_PG_CNT div 2);
    if nCh = 8 then begin
      for i := DefCommon.CH1 to 3 do begin
        PowerOffSeq(i)
      end;
    end
    else begin
      for i := (nTemp + 1) to DefCommon.MAX_CH do begin
        if pred(Common.SystemInfo.ChCountUsed) < i then break;
        PowerOffSeq(i)
      end;
    end;

  end
  else begin
    PowerOffSeq(nCh)
  end;


end;

procedure TfrmMainter.Ca310CalControlPnl(bEnable: Boolean);
begin
  btnAutoCal.Enabled    := bEnable;
  btnOneTimeMeasure.Enabled := bEnable;
end;

procedure TfrmMainter.CamLightEvent(sData: string);
begin

end;



procedure TfrmMainter.cboCalDataClick(Sender: TObject);
var
  i: Integer;
begin
  LoadOptCsv(cboCalData.Items[cboCalData.ItemIndex]);
end;

procedure TfrmMainter.cboChannelPgChange(Sender: TObject);
var
	nCh, i : Integer;
begin
  nCh := cboChannelPg.ItemIndex;
  //
  case nCh of
    DefCommon.CH1 : begin
      PG[DefCommon.CH1].IsMainter := True;
      PG[DefCommon.CH2].IsMainter := False;
      PG[DefCommon.CH3].IsMainter := False;
      PG[DefCommon.CH4].IsMainter := False;
    end;
    DefCommon.CH2 : begin
      PG[DefCommon.CH1].IsMainter := False;
      PG[DefCommon.CH2].IsMainter := True;
      PG[DefCommon.CH3].IsMainter := False;
      PG[DefCommon.CH4].IsMainter := False;
    end;
    DefCommon.CH3 : begin
      PG[DefCommon.CH1].IsMainter := False;
      PG[DefCommon.CH2].IsMainter := False;
      PG[DefCommon.CH3].IsMainter := True;
      PG[DefCommon.CH4].IsMainter := False;
    end;
    DefCommon.CH4 : begin
      PG[DefCommon.CH1].IsMainter := False;
      PG[DefCommon.CH2].IsMainter := False;
      PG[DefCommon.CH3].IsMainter := False;
      PG[DefCommon.CH4].IsMainter := True;
    end;
    else begin
      PG[DefCommon.CH1].IsMainter := True;
      PG[DefCommon.CH2].IsMainter := True;
      PG[DefCommon.CH3].IsMainter := True;
      PG[DefCommon.CH4].IsMainter := True;
    end;
  end;
end;

procedure TfrmMainter.cboModelTypeClick(Sender: TObject);
var
  TempList : TSearchRec;
begin
  AddCboCsvData;
  LoadOptIni(cboModelType.Items[cboModelType.ItemIndex]);
  if cboCalData.Items.Count > 0 then begin
    LoadOptCsv(cboCalData.Items[cboCalData.ItemIndex]);
  end;
end;

procedure TfrmMainter.cboSaveCa410ChannelClick(Sender: TObject);
begin
  Common.SystemInfo.R2RCa410MemCh := cboCa310Channel.ItemIndex;
  Common.SaveSystemInfo;
end;

procedure TfrmMainter.chkUseTowerLampClick(Sender: TObject);
begin
  ControlDio.UseTowerLamp:= chkUseTowerLamp.Checked;
end;

procedure TfrmMainter.DisplayPgLog(nCh : Integer; sMsg: string);
var
  sDebug : string;
begin
  sDebug := FormatDateTime('[hh:mm:ss.zzz]',Now) + Format(' CH%d: %s',[nCh+1, sMsg]);
  mmCommPg.Lines.Add(sDebug);
end;


procedure TfrmMainter.MaintFlashAllWrite(nCh: Integer);
var
  dwRtn : DWORD;
  nFlashSize, nDataSize : DWORD;
  DataBuf : TIdBytes;
  sTemp, sFileName : string;
  //
  sFileExt : string;
  bIsHexFile : Boolean;
  mtData : TMemoryStream;
  binData : array of Byte;
begin
  try
    sTemp := '---------- Flash ALL Write';
    DisplayPgLog(nCh,sTemp);
    //
    if Length(edPgFileSend.Text) <= 0 then begin
      sTemp := sTemp + ' ...Parameter Error(Flash All file is NOT selected) !!!';
      DisplayPgLog(nCh,sTemp);
      Exit;
    end;

    sFileName := Trim(edPgFileSend.Text);
    sFileExt  := ExtractFileExt(sFileName);
    if LowerCase(sFileExt) = '.hex'      then bIsHexFile := True
    else if LowerCase(sFileExt) = '.bin' then bIsHexFile := False
    else begin
      sTemp := sTemp + ' ...Parameter Error(the selected file is NOT *.hex|*.bin) !!!';
      DisplayPgLog(nCh,sTemp);
      Exit;
    end;
    DisplayPgLog(nCh,sTemp+Format(': %s',[sFileName]));
    //
    nFlashSize := 8192*1024;  // 8MB
    //
    if bIsHexFile then begin
      nDataSize := Common.GetHexLog(sFileName,nDataSize,@DataBuf[0]);
    end
    else begin
      mtData := TMemoryStream.Create;
      try
        mtData.LoadFromFile(sFileName);
        SetLength(binData,nFlashSize);
        mtData.Position := 0;
        mtData.Read(binData[0],mtData.Size);
        //
        nDataSize := mtData.Size;
        SetLength(DataBuf,nDataSize);
        CopyMemory(@DataBuf[0],@binData[0],Min(nFlashSize,nDataSize));
      finally
        mtData.Free;
      end;
    end;
    if nDataSize <= 0  then begin
      sTemp := sTemp + ' ...Error(Check Flash All hex|bin file data) !!!';
      DisplayPgLog(nCh,sTemp);
      Exit;
    end;
    if nDataSize <> nFlashSize  then begin
      sTemp := sTemp + Format(' ...NG(DataCnt:%d, FlashSize=%d) !!!',[nDataSize,nFlashSize]);
      DisplayPgLog(nCh,sTemp);
      Exit;
    end;
    //
   	dwRtn :=Pg[nCh].SendFlashWrite(0{nStartAddr},nDataSize, @DataBuf[0]);
		sTemp := sTemp + TernaryOp((dwRtn = WAIT_OBJECT_0),' OK',' NG');
    if dwRtn = WAIT_OBJECT_0 then sTemp := sTemp + Format(' [LOG/FLASH/CH%d_FlashAllWrite_A0x0_L%d.bin]',[nCh,nFlashSize]);
    DisplayPgLog(nCh,sTemp);
  finally
  end;
end;


//procedure TfrmMainter.MaintFlashAllWrite(nCh: Integer);
//var
//  dwRtn : DWORD;
//  nFlashSize, nDataSize : DWORD;
//  DataBuf : TIdBytes;
//  sTemp, sFileName : string;
//begin
//  try
//    sTemp := 'Flash Write (All)';
//    DisplayPgLog(nCh,sTemp+' ------');
//
//    if Length(edPgFileSend.Text) <= 0 then begin
//      sTemp := sTemp + ' ...Parameter Error(Flash hex file is NOT selected) !!!';
//      DisplayPgLog(nCh,sTemp);
//      Exit;
//    end;
//
//    sFileName  := Trim(edPgFileSend.Text);
//    DisplayPgLog(nCh,sTemp+Format(': HexFile(%s)',[sFileName]));
//
//    nFlashSize := 3612*1024;
//    nDataSize  := Common.GetHexLog(sFileName,nFlashSize,@Logic[nCh].m_FlashAllData.Data[0]);
//    if nDataSize <= 0  then begin
//      sTemp := sTemp + ' ...Error(Check hex file) !!!';
//      DisplayPgLog(nCh,sTemp);
//      Exit;
//    end;
//    if nDataSize <> nFlashSize  then begin
//      sTemp := sTemp + Format(' ...Warning(HexDataCnt:%d, FlashSize=%d) !!!',[nDataSize,nFlashSize]);
//      DisplayPgLog(nCh,sTemp);
//    end;
//
//    dwRtn := Pg[nCh].SendFlashWrite(0{nStartAddr},nDataSize, @Logic[nCh].m_FlashAllData.Data[0]);
//    if (dwRtn <> WAIT_OBJECT_0) then begin
//      sTemp := sTemp + ' NG';
//      DisplayPgLog(nCh,sTemp);;
//    end
//    else begin
//      sTemp := sTemp + Format(' OK (%s)',[sFileName]);
//      DisplayPgLog(nCh,sTemp);
//    end;
//  finally
//  end;
//end;


procedure TfrmMainter.MaintFlashAllRead(nCh: Integer);
var
  dwRtn : DWORD;
  nDataSize : DWORD;
  sTemp, sFileName : string;
begin
  try
    sTemp := 'Flash Read (All)';
    DisplayPgLog(nCh,sTemp+' ------');

    nDataSize := 3612*1024;
    dwRtn := Pg[nCh].SendFlashRead(0{nStartAddr},nDataSize,@Logic[nCh].m_FlashAllData.Data[0]);
    if (dwRtn <> WAIT_OBJECT_0) then begin
      sTemp := sTemp + ' ...NG';
      DisplayPgLog(nCh,sTemp);;
    end
    else begin
      sFileName := Common.Path.FLASH + Format('CH%d_FlashReadAll_A0x%x_L%d.hex',[nCh+1,0,nDataSize]);
      Common.SaveHexLog(sFileName,nDataSize,@Logic[nCh].m_FlashAllData.Data[0]);
      sTemp := sTemp + Format(' OK (See, %s)',[sFileName]);
      DisplayPgLog(nCh,sTemp);
    end;
  finally
  end;
end;


procedure TfrmMainter.Panel1DblClick(Sender: TObject);
begin
  Button2.Visible := not Button2.Visible;
end;

procedure TfrmMainter.PgCmdThread(nCh: Integer);
var
  nSelect : Integer;
  sParam  : string;
  {nTemp,} i, nLenParam : Integer;
  slTemp : TStringList;
  naTemp : array of integer;
  //wLen   : Word;
  nCmdType, nIdx : Integer;
begin
  nSelect := cmbxPgCmd.ItemIndex;
  sParam  := StringReplace(Trim(edPgCmdParam.Text),'0x','$',[rfReplaceAll]);

	{ //TBD:ITOLED?
  if not Pg[nCh].IsPgReady then begin
    DisplayPgLog(nCh,'Check PG Status');
    btnPgSendCmd.Enabled := True;
    Exit;
  end;

  if Pg[nCh].m_PgConnSt in [pgDisconnect,pgWait] then begin
    DisplayPgLog(nCh,'Check PG');
    btnPgSendCmd.Enabled := True;
    Exit;
  end;
  }

  case nSelect of
     MAINT_PG_CMD_FLASH_ALL_WRITE : begin
      if Trim(edPgFileSend.Text) = '' then begin
        btnPgSendCmd.Enabled := True;
        Exit;
      end;
      if not FileExists(edPgFileSend.Text) then begin
        btnPgSendCmd.Enabled := True;
        Exit;
      end;
    end;
    MAINT_PG_CMD_DP860 : begin
      if Trim(edPgCmdParam.Text) = '' then begin
        btnPgSendCmd.Enabled := True;
        Exit;
      end;
    end;
    else begin
      SetLength(naTemp,2048);
      slTemp := TStringList.Create;
      try
        slTemp := TStringList.Create;
        try
          ExtractStrings([' '],[],PChar(sParam),slTemp);
          nLenParam := slTemp.Count;
          for i := 0 to Pred(nLenParam) do begin
            if i > 20 then break;
            naTemp[i] := StrToIntDef(slTemp.Strings[i],0);
          end;
        except
        end;
      finally
        slTemp.Free;
      end;
    end;
  end;

//  nIdx := gridPatternList.Row;
//  if nIdx < 0 then begin
//    btnPgSendCmd.Enabled := True;
//    Exit;
//  end;

  ThreadTask( procedure
    var dwRtn: DWORD; nDataLen: Integer; naData: TIdBytes; {sendData: TFileTranStr;} btaTemp: TIdBytes;
                            sTemp,sTemp2 : string; j : Integer; bOn, bOK: Boolean; //Stream: TMemoryStream; dGetCheckSum: dword;
    begin

    case nSelect of

      MAINT_PG_CMD_POWER_ON_ONLY : begin
        DisplayPgLog(nCh,'Power On (without TCon PUC-Para Write)');
//        Logic[nCh].m_Inspect.PowerOn := True;
        Pg[nCh].SendPowerOn(DefPG.CMD_POWER_ON); // power on
        {$IFDEF PANEL_ITOLED}
      //Logic[nCh].PucParaTConWriteProc;
        {$ENDIF}
      end;

      MAINT_PG_CMD_POWER_OFF : begin
        DisplayPgLog(nCh,'Power Off');
//        Logic[nCh].m_Inspect.PowerOn := False;
        Pg[nCh].SendPowerOn(DefPG.CMD_POWER_OFF); // power off
      end;

      MAINT_PG_CMD_POWER_ON_BIST : begin
        DisplayPgLog(nCh,'Power On (without TCon PUC-Para Write)');
//        Logic[nCh].m_Inspect.PowerOn := True;
        Pg[nCh].SendPowerBistOn(DefPG.CMD_POWER_ON); // power on
        {$IFDEF PANEL_ITOLED}
      //Logic[nCh].PucParaTConWriteProc;
        {$ENDIF}
      end;

      MAINT_PG_CMD_POWER_OFF_Bist : begin
        DisplayPgLog(nCh,'Power Off');
//        Logic[nCh].m_Inspect.PowerOn := False;
        Pg[nCh].SendPowerBistOn(DefPG.CMD_POWER_OFF); // power off
      end;

      MAINT_PG_CMD_PATTERN_NUM : begin
        sTemp := 'Display Pattern#';
        if nLenParam <> 1 then begin
          sTemp := sTemp + ' ...Parameter Error(Need 1 Parameter) !!!';
          DisplayPgLog(nCh,sTemp);
          Exit;
        end;
        sTemp := Format('Display Pattern# : PatNum(%d)',[naTemp[0]]);
        DisplayPgLog(nCh,sTemp);
        dwRtn := Pg[nCh].SendDisplayPatNum(naTemp[0]); // pattern display
        if dwRtn <> WAIT_OBJECT_0 then begin
        	case dwRtn of
          	WAIT_FAILED  : sTemp := sTemp + ' ...NG(Failed)';
          	WAIT_TIMEOUT : sTemp := sTemp + ' ...NG(Timeout)';
          	else           sTemp := sTemp + ' ...NG(Etc)';
      		end;
          DisplayPgLog(nCh,sTemp);
				end;
			end;

      MAINT_PG_CMD_PATTERN_NEXT : begin
        sTemp := 'Display NEXT#';

        dwRtn := Pg[nCh].SendDisplayPatNext; // pattern display Next
        if dwRtn <> WAIT_OBJECT_0 then begin
        	case dwRtn of
          	WAIT_FAILED  : sTemp := sTemp + ' ...NG(Failed)';
          	WAIT_TIMEOUT : sTemp := sTemp + ' ...NG(Timeout)';
          	else           sTemp := sTemp + ' ...NG(Etc)';
      		end;
          DisplayPgLog(nCh,sTemp);
				end;
			end;

			MAINT_PG_CMD_PATTERN_RGB : begin
        sTemp := 'Display PatternRGB';
        if nLenParam <> 3 then begin
          sTemp := sTemp + ' ...Parameter Error(Need 3 Parameters) !!!';
          DisplayPgLog(nCh,sTemp);
          Exit;
        end;
        sTemp := Format('Pattern RGB: R(%d) G(%d) B(%d)',[naTemp[0],naTemp[1],naTemp[2]]);
        DisplayPgLog(nCh,sTemp);
        dwRtn := PG[nCh].SendDisplayPatRGB(naTemp[0]{nR},naTemp[1]{nG},naTemp[2]{nB});
        if dwRtn <> WAIT_OBJECT_0 then begin
        	case dwRtn of
          	WAIT_FAILED  : sTemp := sTemp + ' ...NG(Failed)';
          	WAIT_TIMEOUT : sTemp := sTemp + ' ...NG(Timeout)';
          	else           sTemp := sTemp + ' ...NG(Etc)';
        	end;
          DisplayPgLog(nCh,sTemp);
				end;
			end;
      MAINT_PG_CMD_BIST_RGB : begin
        sTemp := 'Display BIST_RGB';
        if nLenParam <> 3 then begin
          sTemp := sTemp + ' ...Parameter Error(Need 3 Parameters) !!!';
          DisplayPgLog(nCh,sTemp);
          Exit;
        end;
        sTemp := Format('Pattern BIST RGB: R(%d) G(%d) B(%d)',[naTemp[0],naTemp[1],naTemp[2]]);
        DisplayPgLog(nCh,sTemp);
        dwRtn := PG[nCh].SendDisplayPatBistRGB(naTemp[0]{nR},naTemp[1]{nG},naTemp[2]{nB});
        if dwRtn <> WAIT_OBJECT_0 then begin
        	case dwRtn of
          	WAIT_FAILED  : sTemp := sTemp + ' ...NG(Failed)';
          	WAIT_TIMEOUT : sTemp := sTemp + ' ...NG(Timeout)';
          	else           sTemp := sTemp + ' ...NG(Etc)';
        	end;
          DisplayPgLog(nCh,sTemp);
				end;
			end;


  		MAINT_PG_CMD_TCON_REG_READ : begin
        sTemp := 'TCON REG READ';
        if nLenParam <> 2 then begin
          sTemp := sTemp + ' ...Parameter Error(Need 2 Parameters) !!!';
          DisplayPgLog(nCh,sTemp);
          Exit;
        end;
        sTemp := sTemp + Format(' Addr(0x%x=%d) DataCnt(%d)',[naTemp[0],naTemp[0],naTemp[1]]);
        DisplayPgLog(nCh,sTemp);
        //
        if not Pg[0].IsPgReady then begin
          DisplayPgLog(nCh,sTemp+' ...NG(Check PG Status)');
          Exit;
        end;
        //
        SetLength(btaTemp,naTemp[1]{nDataLen});
        dwRtn := Pg[nCh].SendI2cRead(Integer(DefPG.TCON_REG_DEVICE),Integer(naTemp[0]){nRegAddr},naTemp[1]{nDataLen},btaTemp);
        if dwRtn <> WAIT_OBJECT_0 then begin
          case dwRtn of
            WAIT_FAILED  : sTemp := sTemp + ' ...NG(Failed)';
            WAIT_TIMEOUT : sTemp := sTemp + ' ...NG(Timeout)';
            else           sTemp := sTemp + ' ...NG(Etc)';
          end;
          DisplayPgLog(nCh,sTemp);
        end;

      end;

  		MAINT_PG_CMD_TCON_REG_WRITE : begin
        sTemp := 'TCON WRITE';
        if nLenParam < 2 then begin
          sTemp := sTemp + ' ...Parameter Error(Need minimum 2 parameters) !!!';
          DisplayPgLog(nCh,sTemp);
          Exit;
        end;
        //
        sTemp := sTemp + Format(' Addr(0x%x=%d) Data(',[naTemp[0],naTemp[0]]);
        nDataLen := nLenParam - 1;
        SetLength(naData, nDataLen);
        for j := 0 to Pred(nDataLen) do begin
          naData[j] := naTemp[j+1];
          sTemp := sTemp + Format(' 0x%0.2x',[naData[j]]);
        end;
        sTemp := sTemp + ')';
        DisplayPgLog(nCh,sTemp);
        //
        if not Pg[0].IsPgReady then begin
          sTemp := sTemp + ' ...NG(Check PG Status)';
          DisplayPgLog(nCh,sTemp);
          Exit;
        end;
        //
        dwRtn := Pg[nCh].SendI2cWrite(DefPG.TCON_REG_DEVICE,naTemp[0]{nRegAddr},nDataLen,naData);
        if dwRtn <> WAIT_OBJECT_0 then begin
          case dwRtn of
            WAIT_FAILED  : sTemp := sTemp + ' ...NG(Failed)';
            WAIT_TIMEOUT : sTemp := sTemp + ' ...NG(Timeout)';
            else           sTemp := sTemp + ' ...NG(Etc)';
          end;
          DisplayPgLog(nCh,sTemp);
        end;
      end;

      MAINT_PG_CMD_FLASH_ALL_READ : begin
        sTemp := '---------- Flash ALL Read';
        DisplayPgLog(nCh,sTemp);
        nDataLen := 8192*1024;
        dwRtn := Pg[nCh].SendFlashRead(0{nStartAddr},nDataLen,@Logic[nCh].m_FlashAllData.Data[0]);
  			sTemp := sTemp + TernaryOp(bOK,' OK',' NG');
        if bOK then sTemp := sTemp + Format(' [LOG/FLASH/CH%d_FlashPucDataRead_A0x0_L%d.hex]',[nCh,nDataLen]);
        DisplayPgLog(nCh,sTemp);;
      end;

  		MAINT_PG_CMD_FLASH_ALL_WRITE : begin
        MaintFlashAllWrite(nCh);
      end;

  		MAINT_PG_CMD_POWER_RESET : begin
				//TBD:ITOLED?
				DisplayPgLog(nCh,'MAINT_PG_CMD_POWER_SET ...TBD');
      end;

      {$IFDEF PG_DP860}
      MAINT_PG_CMD_DP860 : begin
        PG[nCh].DP860_SendCmd(edPgCmdParam.Text, DefPG.PG_CMDID_UNKNOWN,DefPG.PG_CMDSTR_UNKNOWN, 0{nWaitMS},0{nRetry});
      end;
      {$ENDIF}

      MAINT_PG_REPROGRARMING : begin
        SetLength(naData,240);
        for j := 0 to 240 -1 do
          naData[j] := Common.m_DLLReProgrammingData[j];

        Pg[nCh].SendReProgramming(PROGRAMING_DEVICE,0,240,naData);
      end;

			else begin
				//TBD:ITOLED?
				DisplayPgLog(nCh,'else ...TBD');
			end;
    end;
  end, btnPgSendCmd);
end;

//
//procedure TfrmMainter.CmdThread(nCh: Integer);
//var
//  nSelect : Integer;
//  i, nLenParam : Integer;
//  sParam : string;
//  slTemp : TStringList;
//  naTemp : array of integer;
//  btBuff : TIdBytes;
////  wLen   : Word;
//begin
//
//  if Pg[nCh].Status in [pgDisconnect,pgWait] then begin
//    btnSendCmdPg.Enabled := True;
//    Exit;
//  end;
//  nSelect := cboCmdPg.ItemIndex;
//  sParam := StringReplace(Trim(edParam.Text),'0x','$',[rfReplaceAll]);
//
//  SetLength(naTemp,201);
//  slTemp := TStringList.Create;
//  try
//    ExtractStrings([' '],[],PChar(sParam),slTemp);
//    nLenParam := slTemp.Count;
//    for i := 0 to Pred(nLenParam) do begin
//      if i > 199 then break;
//
//      naTemp[i] := StrToIntDef(slTemp.Strings[i],0);
//    end;
//
//  finally
//    slTemp.Free;
//  end;
//
//  ThreadTask( procedure var
//                        sTemp : string; j : Integer; begin
//    case nSelect of
//      0 : begin
//        SendGuiDisplay(nCh,'Power On (initial)');
//        Pg[nCh].SendPowerOn(1); // power on
//      end;
//      1 : begin
//        SendGuiDisplay(nCh,'Power On (Auto)');
//        Pg[nCh].SendPowerOn(2); // power on
//      end;
//      2 : begin
//        SendGuiDisplay(nCh,'Power On (Screen Code)');
//        Pg[nCh].SendPowerOn(3); // power on
//      end;
//
//      3 : begin
//        SendGuiDisplay(nCh,'Power Off');
//        Pg[nCh].SendPowerOn(0); // power off
//      end;
//      4 : begin
//        sTemp := Format('Pattern Display : %d',[naTemp[0]]);
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendDisplayPat(naTemp[0]); // pattern display
//      end;
//      5 : begin
//        if nLenParam <> 3 then begin
//          SendGuiDisplay(nCh,Format('NG - Param Count must be 3 - current %d',[nLenParam]));
//        end;
//        sTemp := Format('Display Single Pattern : %d %d %d',[naTemp[0],naTemp[1],naTemp[2]]);
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendSinglePat(naTemp[0],naTemp[1],naTemp[2]); // pattern display
//      end;
//      6 : begin
//        sTemp := 'POCB power measurement';
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendPowerMeasure; // pattern display
//      end;
//      7 : begin
//        if nLenParam < 2 then begin
//          SendGuiDisplay(nCh,Format('NG - Param Count must be over 2 - current %d',[nLenParam]));
//        end;
//        SetLength(btBuff,nLenParam);
//        for j := 0 to Pred(nLenParam) do begin
//          btBuff[j] := Byte(naTemp[j]);
//        end;
//        sTemp := Format('MIPI Write : %s',[sParam]);
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendMIPIWrite(btBuff,nLenParam); // pattern display
//      end;
//      8 : begin
//        if nLenParam <> 3 then begin
//          SendGuiDisplay(nCh,Format('NG - Param Count must be 3 - current %d',[nLenParam]));
//        end;
//        SetLength(btBuff,nLenParam);
//        for j := 0 to Pred(nLenParam) do begin
//          btBuff[j] := Byte(naTemp[j]);
//        end;
//        sTemp := Format('MIPI Read : %s',[sParam]);
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendMIPIRead(btBuff,nLenParam); // pattern display
//      end;
//      9 : begin
//        if nLenParam < 200 then begin
//          SendGuiDisplay(nCh,Format('NG - Param Count must be over 200 - current %d',[nLenParam]));
//        end;
//        SetLength(btBuff,nLenParam);
//        for j := 0 to Pred(nLenParam) do begin
//          btBuff[j] := Byte(naTemp[j]);
//        end;
//        sTemp := Format('MIPI Write Write : %s',[sParam]);
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendI2CWrite(btBuff,nLenParam); // pattern display
//      end;
//      10 : begin
//        if nLenParam <> 8 then begin
//          SendGuiDisplay(nCh,Format('NG - Param Count must be 8 - current %d',[nLenParam]));
//        end;
//        SetLength(btBuff,nLenParam);
//        for j := 0 to Pred(nLenParam) do begin
//          btBuff[j] := Byte(naTemp[j]);
//        end;
//        sTemp := Format('I2C Read : %s',[sParam]);
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendI2CRead(btBuff,nLenParam); // pattern display
//      end;
//      11 : begin
//        if nLenParam <> 4 then begin
//          SendGuiDisplay(nCh,Format('NG - Param Count must be 8 - current %d',[nLenParam]));
//        end;
//
//        sTemp := Format('Error Flag Check : %s',[sParam]);
//        SendGuiDisplay(nCh,sTemp);
//        Pg[nCh].SendErrorFlag(naTemp[0],naTemp[1],naTemp[2],naTemp[3] ); // pattern display
//      end;
//      12 : begin
//
//
//
//      end;
//      13 : begin
//        POCB_Data_Down_Seq(nCh);
//      end;
//      14 : begin
//        Pg[nCh].SendPocbDataWrite(naTemp[0],naTemp[1],naTemp[2],naTemp[3],naTemp[4] );
//      end;
//      15 : begin
//        Pg[nCh].PocbEraseType(naTemp[0],naTemp[1],naTemp[2]);
//      end;
//      16 : begin
//        SendGuiDisplay(nCh, 'Send PgReset');
//        Pg[nCh].SendPgReset;
//      end;
//      17 : begin  //Byte Data
//        SendGuiDisplay(nCh, 'Send Byte Data: ' + edParam.Text);
//        if nLenParam < 4 then begin
//          SendGuiDisplay(nCh,Format('NG - Param Count must be over 4 - current %d',[nLenParam]));
//        end;
//        SetLength(btBuff,nLenParam);
//        for j := 0 to Pred(nLenParam) do begin
//          btBuff[j] := Byte(naTemp[j]);
//        end;
//        Pg[nCh].SendByteData(btBuff, nLenParam); // pattern display
//      end;
//    end;
//  end, btnSendCmdPg);
//end;


procedure TfrmMainter.DisplayDio(bIn: Boolean);
var
  i, nMod, nDiv, nMaxCnt : Integer;
  bTemp : Boolean;
begin
if CommDaeDIO = nil then Exit;
  nMaxCnt := DefDio.MAX_IO_CNT + Common.SystemInfo.DIOType*8;

  if bIn then begin
    for i := 0 to Pred(nMaxCnt) do begin
      nDiv := i div 8; nMod := i mod 8;
      bTemp := (CommDaeDIO.DIData[nDiv] and (1 shl nMod)) > 0;
      if Common.SignalInversion(i) then bTemp := not bTemp;

      ledIn[i].Value := bTemp;
    end;




  end
  else begin
    for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin
      nDiv := i div 8; nMod := i mod 8;
      bTemp := (CommDaeDIO.DODataFlush[nDiv] and (1 shl nMod)) > 0;
      ledOut[i].Value := bTemp;
      if bTemp then  btnOutSig[i].Caption := 'Off'
      else           btnOutSig[i].Caption := 'On';
    end;
  end;

//  ledIn  / ledOut
end;

procedure TfrmMainter.edCmdPosChange(Sender: TObject);
begin
  m_bChangeZAxisValue:= True;
end;


procedure TfrmMainter.SaveCalResult(bIsVerify: Boolean);
var
  sFilePath, sFileName : string;
  txtF : Textfile;
  sHeader, sData : string;
  i,j : Integer;
begin
  sFilePath := Common.Path.UserCalLog + formatDateTime('yyyymmdd',now) + '\';
  if bIsVerify then begin
    sFileName := sFilePath + formatDateTime('yyyymmdd',now) + Common.SystemInfo.EQPId +'_'+ cboModelType.Text + '_' + cboCalData.Text + '_rgbMeasure.csv';
  end
  else begin
    sFileName := sFilePath + formatDateTime('yyyymmdd',now) + Common.SystemInfo.EQPId +'_'+ cboModelType.Text + '_' + cboCalData.Text + '.csv';
  end;
  if Common.CheckDir(sFilePath) then Exit;
  if IOResult = 0 then begin
    try
      try
        AssignFile(txtF, sFileName);
        try
          // File Check!
          if not FileExists(sFileName) then begin
            sHeader := '';
            for i := 0 to Pred(grdCalVerify.ColCount) do begin
              sHeader := sHeader + grdCalVerify.Cells[i,0] +',';
            end;
            Rewrite(txtF);
            WriteLn(txtF, sHeader);
          end;
          for i := 0 to Pred(grdCalVerify.RowCount) do begin
            sData := '';
            for j := 0 to Pred(grdCalVerify.ColCount) do begin
              sData := sData + grdCalVerify.Cells[j,i+1] +',';
            end;
            Append(txtF);
            WriteLn(txtF, sData);
          end;
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

procedure TfrmMainter.SaveOptCsv(sFileName: string);
var
  fSys        : TIniFile;
  i : Integer;
  sCalDir : string;
begin
  if cboModelType.ItemIndex < 0 then Exit;
  sCalDir := Common.Path.UserCal + cboModelType.Items[cboModelType.ItemIndex] + '\';
  Common.CheckDir(sCalDir);
  fSys := TIniFile.Create(sCalDir + '\OcConfig.ini');
  try
    fSys.WriteString('CA310_USER_CAL','SEL_CAL_FILE',sFileName);
  finally
    fSys.Free;
  end;
end;

procedure TfrmMainter.SendGuiDisplay(nCh: Integer; sMsg: string);
var
  ccd         : TCopyDataStruct;
  CommData    : RGuiMainter;
begin
  CommData.MsgType  := DefCommon.MSG_TYPE_PG;
  CommData.Channel  := nCh;
  CommData.Mode     := 0;
  CommData.Msg      := sMsg;
  ccd.dwData        := 0;
  ccd.cbData        := SizeOf(CommData);
  ccd.lpData        := @CommData;
  SendMessage(Self.Handle,WM_COPYDATA,0, LongInt(@ccd));
end;


procedure TfrmMainter.tbPocbOptionClick(Sender: TObject);
begin

end;

{$IFDEF ISPD_POCB}
procedure TfrmMainter.ShowIoSignal(bIsIn, bConnChange : Boolean; nLen: Integer; naReadData: array of Integer);
var
  i, j : Integer;
  dwTemp : DWORD;
begin
  if bIsIn then begin
    for i := 0 to 1 do begin
      for j := 0 to Pred(defDio.MAX_IN_CNT) do begin
        dwTemp := 1 shl j;
        if (dwTemp and naReadData[i]) <> 0 then begin
          ledIn[j + i*(defDio.MAX_IN_CNT)].Value := True;
        end
        else begin
          ledIn[j + i*(defDio.MAX_IN_CNT)].Value := False;
        end;
      end;
    end;

  end
  else begin
    for i := 0 to 1 do begin
      for j := 0 to Pred(defDio.MAX_OUT_CNT) do begin
        dwTemp := 1 shl j;
        if (dwTemp and naReadData[i]) <> 0 then begin
          ledOut[j + i*(defDio.MAX_OUT_CNT)].Value := True;
          btnOutSig[j + i*(defDio.MAX_OUT_CNT)].Caption := 'OFF';
        end
        else begin
          ledOut[j + i*(defDio.MAX_OUT_CNT)].Value := False;
          btnOutSig[j + i*(defDio.MAX_OUT_CNT)].Caption := 'ON';
        end;
      end;
    end;
  end;

end;
{$ENDIF}

procedure TfrmMainter.ThreadStartDio(task: TProc);
var
  ioThread : TThread;
begin
  grpDioCtl.Enabled := False;
  grpDioCtlPreOC.Enabled := false;
  ioThread := TThread.CreateAnonymousThread(procedure begin
    task;
    ioThread.Synchronize(nil,procedure begin
      if frmMainter <> nil then begin
        grpDioCtl.Enabled := True;
        grpDioCtlPreOC.Enabled := True;
      end;
    end);

  end);
  ioThread.Start;
end;

procedure TfrmMainter.ThreadTask(task: TProc; btnObj : TRzBitBtn);
var
  th : TThread;
begin
  btnObj.Enabled := False;
  th := TThread.CreateAnonymousThread(procedure begin
    task;
    th.Synchronize(nil,procedure begin
      btnObj.Enabled := True;
    end);
  end);
  th.Start;
end;

procedure TfrmMainter.ThreadTaskTracking(task: TProc; btnObj : TRzBitBtn);
var
  th : TThread;
begin
  btnObj.Enabled := False;
  th := TThread.CreateAnonymousThread(procedure begin
    task;
    th.Synchronize(nil,procedure begin
      btnObj.Enabled := True;
      ShowNgMessage('GrayScale or DBVtracking Done');
    end);
  end);
  th.Start;
end;



procedure TfrmMainter.WMCopyData(var Msg: TMessage);
var
  nType, nCh : Integer;
  sMsg, sTemp : string;
begin
  nType := PGuiMainter(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := PGuiMainter(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;

  case nType of
    DefCommon.MSG_TYPE_SCRIPT :begin
      sMsg  := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
      sTemp := FormatDateTime('[hh:mm:ss.zzz]',Now);
      sTemp := sTemp + Format('Ch%d : ',[nCh+1]) + sMsg;
      mmoScrResult.Lines.Add(sTemp);
    end;
    DefCommon.MSG_TYPE_PG : begin   // PG
      sMsg  := PGuiMainter(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
      sTemp := FormatDateTime('[hh:mm:ss.zzz]',Now);
      sTemp := sTemp + Format('Ch%d, Send : ',[nCh+1]) + sMsg;
      mmCommPg.Lines.Add(sTemp);
    end;
  end;

  {procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;}
end;

procedure TfrmMainter.btnSendCmdPgClick(Sender: TObject);
var
  nCh, i : Integer;
begin
  nCh := DefCommon.CH1; //cboChannelPg.ItemIndex;
  if nCh > DefCommon.MAX_CH then begin
    for i := 0 to DefCommon.MAX_CH do begin
//      CmdThread(i);
      PgCmdThread(i);
    end;
  end
  else begin
//    CmdThread(nCh);
    PgCmdThread(nCh);
  end;
end;

procedure TfrmMainter.btnShutterDnCH12Click(Sender: TObject);
begin
//  if ((not ControlDio.ReadInSig(DefDio.IN_B_STAGE_IN_CAM))
//    and (not ControlDio.ReadInSig(DefDio.IN_A_STAGE_IN_CAM))) then begin
//    //Stage Postion이 정위치가 아니면 Shutter Down 금지
//    Application.MessageBox('Check Stage Position', 'Confirm', MB_OK+ MB_ICONSTOP);
//    Exit;
//  end;

  ThreadStartDio(procedure begin
    ControlDio.MovingShutter(DefCommon.CH_TOP,False);
  end);
end;

procedure TfrmMainter.btnShutterDnCH34Click(Sender: TObject);
begin
  ThreadStartDio(procedure begin
    ControlDio.MovingShutter(DefCommon.CH_BOTTOM,False);
  end);
end;

procedure TfrmMainter.btnShutterUpCH12Click(Sender: TObject);
begin
  ThreadStartDio(procedure begin
    ControlDio.MovingShutter(DefCommon.CH_TOP,true);
  end);
end;

procedure TfrmMainter.btnShutterUpCH34Click(Sender: TObject);
begin
  ThreadStartDio(procedure begin
    ControlDio.MovingShutter(DefCommon.CH_BOTTOM,true);
  end);
end;

procedure TfrmMainter.btnStartJNCDMeasureClick(Sender: TObject);
{$IFDEF CA310_USE}
var
  nCh, i, nCa310Pos, nJig : Integer;
  sCh : string;
{$ENDIF}
begin
{$IFDEF CA310_USE}
  nCh := cboSelectCh.ItemIndex;
  nCa310Pos :=  nCh div (DefCommon.MAX_JIG_CH+1);
  sCh := '';
  nJig := defcommon.MAX_PG_CNT div MAX_JIG_CNT;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if Common.SystemInfo.UseCh[nCa310Pos*nJig + i] then begin
      sCh := sCh + Format('%d',[i+1]);
    end;
  end;

  for i := 1 to 4 do begin
    grdMeasureWRGB.Cells[1,i] := '';
    grdMeasureWRGB.Cells[2,i] := '';
    grdMeasureWRGB.Cells[3,i] := '';
  end;
  MeasureJncdPg(nCh, nCa310Pos, sCh);
{$ENDIF}
end;


procedure TfrmMainter.btnStopCalibrationClick(Sender: TObject);
var
  nCh : Integer;
begin
  m_bStopCa310Cal := True;
end;

procedure TfrmMainter.btnStopClick(Sender: TObject);
begin
  bIs_Stop := True;
end;

procedure TfrmMainter.btnStopScriptClick(Sender: TObject);
var
  nCh, i : Integer;
{$IFDEF ISPD_L_OPTIC}
  nStartPos, nEndPos : Integer;
{$ENDIF}
begin
  nCh := cboScriptCh.ItemIndex;
{$IFDEF ISPD_L_OPTIC}

  if nCh > DefCommon.MAX_CH then begin
    if nCh = (DefCommon.MAX_CH + 1) then begin
      nStartPos := DefCommon.CH1;
      nEndPos   := DefCommon.MAX_JIG_CH;
    end
    else begin
      nStartPos := DefCommon.CH1 + 4;
      nEndPos   := DefCommon.MAX_JIG_CH + 4;
    end;

    for i := nStartPos to nEndPos do begin
      PasScr[i].StopMaintScript;
    end;
  end
  else begin
    PasScr[nCh].StopMaintScript;
  end;

{$ELSE}
  if nCh > Common.SystemInfo.ChCountUsed then begin
    for i := 0 to Pred(Common.SystemInfo.ChCountUsed) do begin
      PasScr[i].StopMaintScript;
    end;
  end
  else begin
    PasScr[nCh].StopMaintScript;
  end;
{$ENDIF}
end;

procedure TfrmMainter.tmrTableTurnTimer(Sender: TObject);
var
  bFront: Boolean;
begin
//  if grpDioCtl.Enabled = False then Exit;
//
//  if edtCount_TableTurn.Tag = 0 then begin
//    //횟수만큼 반복 했으면
//    tmrTableTurn.Enabled:= False;
//    Exit;
//  end;
//  //bFront:= btnTestTableTurn.Tag = 0;
//
//  tmrTableTurn.Tag:= tmrTableTurn.Tag + 1;
//  if tmrTableTurn.Tag < edtInterval_TableTurn.Tag then Exit;
//  tmrTableTurn.Tag:= 0;
//  //방향
//  if btnTestTableTurn.Tag = 0 then begin
//    bFront:= True;
//    btnTestTableTurn.Tag:= 1;
//  end
//  else begin
//    bFront:= False;
//    btnTestTableTurn.Tag:= 0;
//  end;
//
//  edtCount_TableTurn.Tag:= edtCount_TableTurn.Tag - 1;
//  lblTurnCount.Caption:= IntToStr(edtCount_TableTurn.Tag);
//  ControlDio.ThreadTurnStage;
end;


procedure TfrmMainter.btnTurnAStageClick(Sender: TObject);
begin
//  grpDioCtl.Tag:= 1;
//  grpDioCtl.Enabled:= False; //DisplayDIO에서 Turn 완료 시 True 처리 됨
//  ControlDio.ThreadTurnStage;
end;

procedure TfrmMainter.btnTurnBStageClick(Sender: TObject);
begin
// grpDioCtl.Tag:= 1;
//  grpDioCtl.Enabled:= False; //DisplayDIO에서  Turn 완료 시 True 처리 됨
//  ControlDio.ThreadTurnStage;
end;

{$IFDEF AXDIO_USE}
procedure TfrmMainter.AxDioStatus(bIn : Boolean; IoDio : AxIoStatus; sErrMsg: string);
var
  i : integer;
  bChanged : boolean;
begin
  if bIn then begin
    bChanged := False;
    for i := 0 to Pred(DefDio.MAX_IN_CNT) do begin
      ledIn[i].Value :=  IoDio[i];
      if m_PreInIo[i] <>  IoDio[i] then begin
        m_PreInIo[i] :=  IoDio[i];
        bChanged := True;
      end;
    end;
    if bChanged then begin
      grpDioIn.Refresh;
    end;
  end
  else begin
    bChanged := False;
    for i := 0 to Pred(DefDio.MAX_IN_CNT) do begin
      ledOut[i].Value :=  IoDio[i];
      if IoDio[i] then btnOutSig[i].Caption := 'Off'
      else             btnOutSig[i].Caption := 'On';
      if m_PreOutIo[i] <>  IoDio[i] then begin
        m_PreOutIo[i] :=  IoDio[i];
        bChanged := True;
      end;
//      AxDio.SetDio64(i,IoDio[i]);
    end;
    if bChanged then begin
      grpDioOut.Refresh;
    end;
  end;
  pnlDioCardMsg.Caption := sErrMsg;
end;
{$ENDIF}
end.
