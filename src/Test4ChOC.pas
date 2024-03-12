unit Test4ChOC;

interface
{$I Common.inc}
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,DateUtils,UserUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzPanel, ALed, RzButton, Vcl.ExtCtrls, RzRadChk, CommDIO_DAE,
  Vcl.StdCtrls, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, RzCommon, SwitchBtn, JigControl, Vcl.Mask, RzEdit, AdvPanel,
  {UdpServerClient,} CommonClass, ScriptClass, DefScript, DefPG, DefCommon, ControlDio_OC, //PlcTcpPocb, defPlc,
  CodeSiteLogging, Vcl.ComCtrls, AdvListV, DongaPattern, RzGrids, AdvUtil, RzLine,LibCa410Option,NgMsg,
  HandBCR, GMesCom, pasScriptClass, AdvGlassButton, DefGmes, CommCameraRadiant, TILed, DefDio, CommPLC_ECS,DBModule
  ,CA_SDK2,dllClass,CommPG,LogicVh,VirtualBcrForm,CommIonizer,ECSRequestForm,System.SyncObjs, System.StrUtils;
const
  //Stage 메시지 Mode
  STAGE_MODE_NONE                = 100;
  STAGE_MODE_SYS_LOG             = STAGE_MODE_NONE + 1;
  STAGE_MODE_SCRIPT_DONE_ALL     = STAGE_MODE_NONE + 2;
  STAGE_MODE_SCRIPT_DONE_UNLOAD  = STAGE_MODE_NONE + 3;
  STAGE_MODE_STAGE_TURN          = STAGE_MODE_NONE + 4;
  STAGE_MODE_TEST_START          = STAGE_MODE_NONE + 5;
  STAGE_MODE_TEST_STOP           = STAGE_MODE_NONE + 6;
  STAGE_MODE_LOAD                = STAGE_MODE_NONE + 7;
  STAGE_MODE_UNLOAD              = STAGE_MODE_NONE + 8;
  STAGE_MODE_EXCHANGE            = STAGE_MODE_NONE + 9;
  STAGE_MODE_DISPLAY_ALARAM      = STAGE_MODE_NONE + 10;

type
  {$IFNDEF GUIMESSAGE}
  {$DEFINE GUIMESSAGE}
  /// <summary> GUI Message for WM_COPYDATA </summary>
  TGUIMessage = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param  : Integer;
    Param2 : Integer;
    Msg     : string;
    pData   : PBYTE; //Pointer; //Length = Param2
  end;
  PGUIMessage = ^TGUIMessage;
  {$ENDIF}


  plcStatus = (psReadyPc, psLoadReq, psStartIns, psComplete, psUnloadReq);

  TfrmTest4ChOC = class(TForm)
    imgCheckBox: TImage;
    tmrDisplayOff: TTimer;
    pnlSwitch: TAdvPanel;
    btnSWNext1: TRzBitBtn;
    btnSWCancel1: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    btnAuto: TRzBitBtn;
    btnCh4: TRzBitBtn;
    btnRepeat: TRzBitBtn;
    btnCh2: TRzBitBtn;
    RzBitBtn7: TRzBitBtn;
    RzBitBtn8: TRzBitBtn;
    pnlInputSerial: TRzPanel;
    btnInputSerial: TRzBitBtn;
    pnlInputS1: TRzPanel;
    pnl4: TRzPanel;
    edSerial1: TRzEdit;
    pnlInputS2: TRzPanel;
    pnl5: TRzPanel;
    edSerial2: TRzEdit;
    pnlInputS3: TRzPanel;
    pnl6: TRzPanel;
    edSerial3: TRzEdit;
    btnStopInputS: TRzBitBtn;
    pnlTestMain: TRzPanel;
    tmAging: TTimer;
    pnlErrAlram: TAdvPanel;
    pnlErrAlramMsg: TPanel;
    btnErrorDisplay: TRzButton;
    pnl2: TPanel;
    tmrRetest: TTimer;
    pnlSwitch2: TAdvPanel;
    btnSWNext1_2: TRzBitBtn;
    btnSWCancel1_2: TRzBitBtn;
    RzBitBtn2_2: TRzBitBtn;
    btnAuto_2: TRzBitBtn;
    btnCh4_2: TRzBitBtn;
    btnRepeat_2: TRzBitBtn;
    btnCh2_2: TRzBitBtn;
    RzBitBtn7_2: TRzBitBtn;
    RzBitBtn8_2: TRzBitBtn;
    pnlJigInform: TRzPanel;
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure WMCopyData_LOGIC(var WmMsg: TMessage);
    procedure WMCopyData_PG(var CopyMsg: TMessage);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnErrorDisplayClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCh2Click(Sender: TObject);
    procedure RzBitBtn7Click(Sender: TObject);
    procedure RzBitBtn8Click(Sender: TObject);
    procedure btnSWCancel1Click(Sender: TObject);
    procedure btnSWNext1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrDisplayOffTimer(Sender: TObject);
    procedure btnInputSerialClick(Sender: TObject);
    procedure btnStopInputSClick(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
    procedure btnAutoClick(Sender: TObject);
    procedure btnRepeatClick(Sender: TObject);
    procedure btnCh4Click(Sender: TObject);
    procedure btnSendHostClick(Sender : TObject);   //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
    procedure btnCancelHostClick(Sender : TObject);
    procedure ButtonKeyPress(Sender: TObject; var Key: Char);

  private
    { Private declarations }

    m_nCurStatus   : Integer;
    m_NGAlarmCount : Integer;
    m_bTheadIsTerminated : Boolean;
    m_nOkCnt, m_nNgCnt,m_LLCnt : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of integer;
    m_nTotalTact, m_nUnitTact   :array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of   Integer;
    tmTotalTactTime  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TTimer;
    tmUnitTactTime   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TTimer;

    m_bAutoPlcProbeBack : Boolean;
//    pnlJigInform   :  TRzPanel;

    btnVirtualBcr  :  TRzBitBtn;
    btnECSRequest  :  TRzBitBtn;

    tmAgingTimer   :  array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TTimer;
    m_nDiscounter  :  array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  Integer;
    btnStartTest   :  array [DefCommon.CH1..DefCommon.MAX_JIG_CNT] of  TRzBitBtn;
    btnStopTest    :  array [DefCommon.CH1..DefCommon.MAX_JIG_CNT] of  TRzBitBtn;
    btnVirtualKey  :  array [DefCommon.CH1..DefCommon.MAX_JIG_CNT] of  TRzBitBtn;
    btnLampOnOff   :  array [DefCommon.CH1..DefCommon.MAX_JIG_CNT] of  TRzBitBtn;
    btnSetIonizer  :  array [DefCommon.CH1..DefCommon.MAX_JIG_CNT] of  TRzBitBtn;
    // tact time.
    pnlTackTimes   :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TRzPanel;
    pnlNowValues   :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TPanel;     // CH 별 개별 표시
    pnlUnitTact    :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TRzPanel;
    pnlJigTact     :  array [DefCommon.CH1..DefCommon.MAX_JIG_CNT] of  TRzPanel;
    pnlJigTactVal  :  TPanel;
    pnlUnitTactVal :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TPanel;    // CH 별 개별 표시
    pnlTackTimes2   :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TRzPanel;
    pnlNowValues2   :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TPanel;     // CH 별 개별 표시
    pnlUnitTact2    :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TRzPanel;
    pnlUnitTactVal2 :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TPanel;    // CH 별 개별 표시

    pnlDelayTimes   :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TRzPanel;
    pnlNowDelayTimes  :  array [DefCommon.CH1..DefCommon.MAX_CH] of  TPanel;

    pnlTackTimesGroup : array [DefCommon.CH1..DefCommon.MAX_CH] of TPanel;
    pnlDelayTimesGroup : array [DefCommon.CH1..DefCommon.MAX_CH] of TPanel;
    m_PlcStatus    : plcStatus;
    pnlLogGrp       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
//    mmChannelLog   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TRichEdit;//  TMemo;
    mmChannelLog   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TMemo;//
    // OK NG count.
    pnlTotalNames  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlTotalValues : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlOKNames     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlOKValues    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlNGNames     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlNGValues    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    btnResetCount  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzBitBtn;
    btnChAutoStart : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TButton;
    btnChStop      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TButton;
    pnlChGrp       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    ledPGStatuses  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of ThhALed;
    pnlHwVersion   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;

    pnlSerials     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlSerials2    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    pnlMESResults  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlAging       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlMesConfirm  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    btnSendHost    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzBitBtn; //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
    btnCancelHost  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzBitBtn; //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST

    pnlPGStatuses  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlTimeNResult : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    btnTakeOutReport : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzBitBtn;

    pnlGrpDio      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;


//    pnlPrevResult  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH,0..DefCommon.MAX_PREVIOUS_RESULT] of TPanel;
    pnlPrevResult  : array of array of TPanel;
//    pnlPlcSupply   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
//    pnlPlcOut      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;

    gridPWRPGs     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TAdvStringGrid;

    m_RGB_Avr_Data : array of array of TGammaCmd;
    m_Rgb_Avr      : TGammaAvg;
    m_bInitGetAvr  : boolean;
    m_csBcrRead    : TCriticalSection;

    FTempIr: array[DefCommon.CH1 .. DefCommon.MAX_PG_CNT * 2 - 1] of Double;


    /// <summary> Log 누적 라인 수 - 초과 될 경우 저장</summary>
    LogAccumulateCount : Integer;
    /// <summary> Log 누적 시간(초단위) - 초과 될 경우 저장</summary>
    LogAccumulateSecond : Integer;

    procedure CreateGui;

    procedure OntmCheckIRTemp1(Sender : TObject);
    procedure OntmCheckIRTemp2(Sender : TObject);
    procedure OntmCheckIRTemp3(Sender : TObject);
    procedure OntmCheckIRTemp4(Sender : TObject);
    procedure OnTotalTimer(Sender : TObject);
    procedure OnUnitTimer(Sender : TObject);
    procedure OnTotal2Timer(Sender : TObject);
    procedure OnUnit2Timer(Sender : TObject);
    procedure OnTotal3Timer(Sender : TObject);
    procedure OnUnit3Timer(Sender : TObject);
    procedure OnTotal4Timer(Sender : TObject);
    procedure OnUnit4Timer(Sender : TObject);
    procedure BtnStartTestClick(Sender: TObject);
    procedure BtnStopTestClick(Sender: TObject);
    procedure btnVirtualKeyClick(Sender : TObject);
    procedure btnResetCountClick(Sender: TObject);
    procedure btnChAutoStartClick(Sender: TObject);
    procedure btnChStopClick(Sender: TObject);
    procedure btnTakeOutReportClick(Sender: TObject);
    procedure chkPgClick(Sender: TObject);
    procedure btnLampOnoffClick(Sender: TObject);
    procedure btnSetIonizerClick(Sender: TObject);
    procedure pnlSerials1DblClick(Sender: TObject);
    procedure DisplayPGStatus(nPgNo, nType : Integer; sMsg : string);
    procedure DisplayPwrData(nPgNo: Integer; PwrData: TPwrData);


    procedure btnVirtualBcrClick(Sender: TObject);
    procedure btnECSRequestClick(Sender: TObject);

//    procedure DisplaySeq;

    procedure UpdatePtList;

    procedure DioWorkDone(nErrCode : Integer; sErrMsg : string);
    procedure SyncProbeBack(nJigCh, nParam1, nNgCode : Integer);
    procedure SyncRunScrpt(nIdxKey : Integer);
    procedure SyncJigUnload(nCh : integer);
    procedure StopTotalTimer(Sender: TObject; nJigCh, nTimerType : Integer);
    procedure DisplayPreviousRet(nCh : Integer);
//    procedure DisplayLogAllCh(nCh : Integer; bNg : Boolean; sMsg : string);
    procedure MakeOpticPassRgb(nCh: Integer);
    // file을 읽고 OC Parameter의 평균값을 구하자.
    procedure GetRgbAvgFromFile;
    procedure CalcLogScroll(nPg, nLogLen : Integer);
    procedure MakeUserEvent(nCh, nIdxErr : Integer; sErrMessage : string);
    procedure MakeUserEvent1(nCh, nIdxErr : Integer; sErrMessage : string);
//    procedure ShowAgingTime(nTime : Integer);

    procedure ScriptLog(nCh : Integer;sDebug : string; isNg : Boolean = False);
    procedure SendMessageMain(nMsgMode, nCh, nParam, nParam2: Integer;
      sMsg: String; pData: Pointer);

    procedure OnAgingTimer(Sender: TObject);
    procedure DisplayPGStatuses(nCH,nResult :Integer);
    function WriteR2RData(nCh : Integer): Integer;
    procedure ShowNgMessage(sMessage: string);

    procedure ControlIRTemp (nCh,nTemp : Integer);
    procedure AddLog(sMsg: string; nCh:Integer; nType: Integer=0);

    function PGPowerReset(nCh : Integer): Integer;
    procedure aTaskThreadIsDone(Sender: TObject);

  public
    { Public declarations }
    /// <summary> Main 폼 Handle - WM_COPYDATA</summary>
    MessageHandle: THandle;
    m_nJigTact      : Integer;
    m_bPassCH :  array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Boolean; // 동일한 NG 발생 시 해당 CH Pass
    m_bFanOnOff : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of Boolean;
    m_nTempIrTact : array [DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of integer;
    tmCheckIRTemp    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TTimer;
    pnlJigTitle    :  array [DefCommon.CH1..DefCommon.MAX_JIG_CNT] of TPanel;
//    pnlPlcClampDn  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    chkChannelUse  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzCheckBox;
    ledDiProbeForward  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiProbeBackward  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiProbeUp  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiProbeDown  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;

    ledDoProbeForward  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDoProbeBackward  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDoProbeUp  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDoProbeDown  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;

    ledDiPinBlockUnlockOFF : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiPinBlockUnlockON  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;


    ledDoPinBlockForward  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDoPinBlockBackward  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;

    ledDoVaccumON  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDoVaccumOFF  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;

    ledDiDetect  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;

    pnlTempPanel  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlTempPanelVal  : array[DefCommon.CH1 .. DefCommon.MAX_PG_CNT *2 - 1] of TPanel;

    //Carrier Sensor In signal
    ledDiCarrierUnlock1 : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiCarrierUnlock2 : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiCarrierUnlock3 : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiCarrierUnlock4 : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiCarrierlock1   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiCarrierlock2   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiCarrierlock3   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDiCarrierlock4   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    //Carrier Sol control out
    ledDoCarrierUnlockSol  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;
    ledDoCarrierLock       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TTILed;

    m_aTempIr : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of array[0 .. 5] of array of string;

//    ledDetect  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    /// <summary>로그창에 추가 및 저장. </summary>
    procedure ShowGui(hMain : HWND);
    procedure SetHandleAgain(hMain : HWND);
    procedure DisplaySysInfo(nCh : Integer);
    procedure ClearChData(nCh : Integer);
    procedure DisplayResult(nCh, nCode, nColorType : Integer; sMsg: String);
    procedure SetConfig;
    procedure SetBcrData;
    procedure SetProbeAutoControl;
    procedure SetTime_StageTurn(nType: Integer; dtTime: TDateTime);
    procedure AutoLogicStart(nCH : integer);
    function StartScript(nCH,nSeq: Integer): Boolean;
    function EndtScript(nCH,nSeq: Integer): Boolean;
    procedure ShowPlcNgMeg(nJigCh : Integer;sErrMsg : string);
    procedure SetHostConnShow(bHostOn : Boolean);
    function CheckScriptRun : Boolean;
    procedure SetIonizer(nCH : Integer; bIsOnOff : Boolean);
    procedure SetPlcStatus(IoPlc : Integer);
    procedure CamScriptStart;
    procedure UnloadScriptStart(nCH : Integer);
    procedure CamSet;
    procedure DisplayDio(bIsIn : Boolean);
    procedure ClearPreviousResult;
    procedure getBcrData(sScanData: string);
    procedure getBcrData2(sScanData: string);
    function GetNGCode_ByErroCode(sErrorCode: string): Integer;
    procedure PGUseStatus(nCH : Integer; bOnOff : Boolean);
    procedure ShowIrTempData(nCh, nData: Integer);
    function GetIRTempData(nCh : Integer): string;
    procedure SaveCsvTempStatus(nCH : integer;sMemo : string; bFanOnOff : Boolean);
//    procedure SetLanguage(nIdx : Integer);
  end;

var
  frmTest4ChOC: array[defcommon.JIG_A .. DefCommon.JIG_B] of TfrmTest4ChOC;

implementation

{$R *.dfm}

uses Main_OC,Mainter;
{$R+}

{ TfrmTest4Ch }


procedure TfrmTest4ChOC.AddLog(sMsg: string; nCh:Integer; nType: Integer);
var
  sLog: string;
begin
  if Common.StatusInfo.Closing then Exit;
  if (nCh > DefCommon.CH4) or (nCh < DefCommon.CH1) then Exit;
  Common.MLog(nCh, sMsg);
  try
//    mmChannelLog[nCh].DisableAlign;
    case nType of
      10: begin
        //저장만 한다.
        Exit;
      end
      else begin
//        if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//           mmChannelLog[nCh].SelAttributes.Color := clWhite;
//        end
//        else begin
//          mmChannelLog[nCh].SelAttributes.Color := clBlack;
//        end;
//        mmChannelLog[nCh].SelAttributes.Style := [];
      end;
    end;
    try
      if Length(sMsg) > 600 then begin
        sLog := FormatDateTime('[HH:MM:SS.zzz] ',now) + Copy(sMsg,1,600);
      end
      else begin
        sLog := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg
      end;

      mmChannelLog[nCh].Lines.Add(sLog);
      mmChannelLog[nCh].Perform(WM_VSCROLL, SB_BOTTOM, 0);

    except
      //유효하지 않은 문자열일 경우 오류(madException) 방지: RichEdit line insertion error.
      on E: Exception do  begin
        Sleep(10); //MLog 충돌 방지 딜레이
  //      Common.MLog(DefCommon.MAX_SYSTEM_LOG, 'MLog Exception:' + E.Message + #13#10 + sMsg);
      end;
    end;

  finally
//    mmChannelLog[nCh].EnableAlign;
  end;

end;



procedure TfrmTest4ChOC.btnECSRequestClick(Sender: TObject);
begin
  ECSTestForm := TECSTestForm.Create(Self);
  if ECSTestForm <> nil then   begin
    ECSTestForm.ShowModal;
  end;
end;

procedure TfrmTest4ChOC.btnErrorDisplayClick(Sender: TObject);
begin
  pnlErrAlram.Visible := False;
end;

procedure TfrmTest4ChOC.btnInputSerialClick(Sender: TObject);
var
  i: Integer;
begin

  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if pnlSerials[i].Caption = '' then pnlSerials[i].Color := clBtnFace
    else                               pnlSerials[i].Color := clSkyBlue;

  end;
//  JigLogic[DefCommon.JIG_A].StartIsfomFlow;
  pnlInputSerial.Visible := False;
  edSerial1.Text := '';
  edSerial2.Text := '';
  edSerial3.Text := '';
end;

procedure TfrmTest4ChOC.SaveCsvTempStatus(nCH : integer; sMemo : string; bFanOnOff : Boolean);
var
  sFilePath, sFileName : String;
  sLine,sFanOnOff: String;
  txtF                 : Textfile;
  i,nSec,nMin: Integer;
begin
  Common.CheckDir(Common.Path.TempCsv);
  sFilePath := Common.Path.TempCsv + FormatDateTime('yymmdd',now) + '\';
  Common.CheckDir(sFilePath);
  sFileName := sFilePath + Common.SystemInfo.EQPId + Format('_CH%d',[nCH+1])+'.csv';
  if bFanOnOff then sFanOnOff := 'ON'
  else              sFanOnOff := 'OFF';

  try
    try
      AssignFile(txtF, sFileName);
      try

        if not FileExists(sFileName) then begin
          //Header 생성
          Rewrite(txtF);
          sLine:=  ',SERIAL NO';
          sLine:=  sLine + format(',Date,Time,Measurement time,Temp_PMIC,Temp_Center,Fan ON/OFF,',[i+1]);

          WriteLn(txtF, sLine);
        end;

        //Data
        Append(txtF);
        sLine:=  sMemo + ',' + PasScr[nCH].TestInfo.SerialNo;
        sLine:=  sLine + FormatDateTime(',yyyy-mm-dd',now);
        sLine:=  sLine + FormatDateTime(',hh:nn:ss.zzz',now);

        nSec := m_nTempIrTact[nCH] mod 60;
        nMin := (m_nTempIrTact[nCH] div 60) mod 60;
        sLine:=  sLine + Format(',%0.2d : %0.2d',[nMin,nSec]);

        sLine:=  sLine + format(',%0.1f,%0.1f,%s,,',[FTempIr[2 * nCH],FTempIr[2 * nCH + 1],sFanOnOff]);

        WriteLn(txtF, sLine);
      except
      end;
    finally
      CloseFile(txtF); // Close the file
    end;
  except

  end;
end;


procedure TfrmTest4ChOC.ShowIrTempData(nCh, nData: Integer);
var
  nRetCh : Integer;
  dTempData : double;
begin
  nRetCh := nCh - 1;
  if nRetCh < 0 then Exit;
  if nRetCh > (DefCommon.MAX_PG_CNT *2) - 1 then Exit;
  dTempData := nData / 10;
  if pnlTempPanelVal[nRetCh] <> nil then begin
    pnlTempPanelVal[nRetCh].Caption := Format('%0.1f °C',[dTempData]);
    FTempIr[nRetCh] := dTempData;
  end;
  //FTempFlate
  //if chkChannelUse[nCh].Checked then DisplayDataInChart(nCh, 0, dTempData);
end;

procedure TfrmTest4ChOC.btnRepeatClick(Sender: TObject);
var
nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_3)
  else            JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_3);
end;

procedure TfrmTest4ChOC.ButtonKeyPress(Sender: TObject; var Key: Char);
begin
  // 엔터 키를 눌렀을 때 동작을 막습니다.
  if Key = #13 then
    Key := #0;
end;

procedure TfrmTest4ChOC.BtnStartTestClick(Sender: TObject);
var
  nCH : Integer;
begin
  nCH := (Sender as TRzButton).Tag;
  if (Common.StatusInfo.AutoMode) then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;


  if (CSharpDll.MainOC_GetOCFlowIsAlive(2 *nCH) = 1) or (CSharpDll.MainOC_GetOCFlowIsAlive(2 *nCH + 1) = 1) then begin
    Application.MessageBox('Unable to run if it is being inspected', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;


  if (Common.PLCInfo.InlineGIB) and (Common.SystemInfo.OCType = DefCommon.OCType)  then begin
    SendMessageMain(STAGE_MODE_TEST_START, nCH, 0, 0, '', nil);
    if nCH = Defcommon.CH_TOP then begin
      btnChAutoStart[0].Click;
      btnChAutoStart[1].Click;
    end
    else if nCH= DefCommon.CH_BOTTOM then begin
      btnChAutoStart[2].Click;
      btnChAutoStart[3].Click;
    end;

  end
  else begin
    SendMessageMain(STAGE_MODE_TEST_START, nCH, 0, 0, '', nil);
    frmMain_OC.Execute_AutoStart(nCH);
  end;
//  AutoLogicStart(nCH);
end;

procedure TfrmTest4ChOC.btnResetCountClick(Sender: TObject);
var
  nCH : Integer;
begin
  nCH := (Sender as TRzButton).Tag;
  m_nOkCnt[nCh] := 0;
  m_nNgCnt[nCh] := 0;
  pnlTotalValues[nCh].Caption := IntToStr(m_nOkCnt[nCh] + m_nNgCnt[nCh]);
  pnlOKValues[nCh].Caption := IntToStr(m_nOkCnt[nCh]);
  pnlNGValues[nCh].Caption := IntToStr(m_nNgCnt[nCh]);

end;

procedure TfrmTest4ChOC.btnSetIonizerClick(Sender: TObject);
var nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;
  if not Common.StatusInfo.AutoMode then begin
    if Pos('Ionizer ON',btnSetIonizer[nCH].Caption) > 0  then begin
      SetIonizer(nCH,True);
      btnSetIonizer[nCH].Caption := 'Ionizer OFF';
    end
    else begin
      SetIonizer(nCH,False);
      btnSetIonizer[nCH].Caption := 'Ionizer ON';
    end;
  end;
end;

procedure TfrmTest4ChOC.btnStopInputSClick(Sender: TObject);
begin
  pnlInputSerial.Visible := False;
  edSerial1.Text := '';
  edSerial2.Text := '';
  edSerial3.Text := '';
//  tmTotalTactTime.Enabled := False;
  pnlInputSerial.Visible := False;
end;

procedure TfrmTest4ChOC.BtnStopTestClick(Sender: TObject);
var
  i,nCH: Integer;
begin
  nCH := (Sender as TRzButton).Tag;
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;

  SendMessageMain(STAGE_MODE_TEST_STOP, nCH, 0, 0, '', nil);

  if nCH = 0  then  begin

    JigLogic[Self.Tag].StopIspd_TOP;
    for i := DefCommon.CH1 to DefCommon.CH2 do begin
      pnlPGStatuses[i].Color := clBtnFace;
      pnlPGStatuses[i].Font.Color := clBlack;
      pnlPGStatuses[i].Font.Size := 24;
      pnlPGStatuses[i].Caption := 'Stop';
    end;
  end
  else begin
    JigLogic[Self.Tag].StopIspd_BOTTOM;
    for i := DefCommon.CH3 to DefCommon.CH4 do begin
      pnlPGStatuses[i].Color := clBtnFace;
      pnlPGStatuses[i].Font.Color := clBlack;
      pnlPGStatuses[i].Font.Size := 24;
      pnlPGStatuses[i].Caption := 'Stop';
    end;

  end;

end;

procedure TfrmTest4ChOC.btnSWCancel1Click(Sender: TObject);
var
nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then JigLogic[Self.Tag].StopIspd_TOP
  else            JigLogic[Self.Tag].StopIspd_BOTTOM;
end;

procedure TfrmTest4ChOC.btnSWNext1Click(Sender: TObject);
var
nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;
  if nCH = 0 then JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_9)
  else            JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_9);
  pnlJigInform.SetFocus;
end;


procedure TfrmTest4ChOC.btnTakeOutReportClick(Sender: TObject);
var
nCH,nRes : integer;
sGlassID : string;
begin
  nCH := (Sender as TRzButton).Tag;
  sGlassID := g_CommPLC.ECS_GlassData[nCH].GlassID;
  if length(sGlassID) > 0  then begin
    if MessageDlg( format('Panel ID [%s] Would you like to report?',[sGlassID]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
      AddLog('Take Out Report: ' + sGlassID,nCH);

      nRes:= g_CommPLC.ECS_TakeOutReport(nCH,sGlassID);
      if nRes <> 0 then begin
        AddLog('Take Out Report NG ' + IntToStr(nRes),nCH);
      end
      else begin
        AddLog('Take Out Report OK',nCH);
      end;
    end;
  end;
end;

procedure TfrmTest4ChOC.CalcLogScroll(nPg, nLogLen: Integer);
var
  i, nTimes : Integer;
begin
  nTimes := (nLogLen div 60);
  for i := 0 to nTimes do begin
    mmChannelLog[nPg].Perform(EM_SCROLL,SB_LINEDOWN,0);
  end;
end;


procedure TfrmTest4ChOC.CamScriptStart;
begin
  JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_CAM_ZONE);
end;

procedure TfrmTest4ChOC.CamSet;
begin
//  if Self.Tag = DefCommon.JIG_A then begin
//    CommCamera.OnTEndEvt := MakeUserEvent;
//  end
//  else begin
//    CommCamera.OnTEndEvt1 := MakeUserEvent1;
//  end;
end;



function TfrmTest4ChOC.CheckScriptRun: Boolean;
var
  bRet : Boolean;
begin
  bRet := False;
  if JigLogic[Self.Tag] <> nil then begin
    bRet := JigLogic[self.Tag].IsScriptRunning;
  end;
  Result := bRet;
end;


procedure TfrmTest4ChOC.btnVirtualBcrClick(Sender: TObject);
var
  sTempBcr : string;
  i,nCH : integer;
begin
  VirtualBcr := TVirtualBcr.Create(Self);
  if VirtualBcr <> nil then   begin
    VirtualBcr.m_MainHandle := MessageHandle;
    VirtualBcr.m_TestHandle  := Self.Handle;
    VirtualBcr.Show;
  end;
end;

procedure TfrmTest4ChOC.btnVirtualKeyClick(Sender: TObject);
var nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;
  if nCH = 0 then  begin
    pnlSwitch.Visible := not pnlSwitch.Visible;
    pnlSwitch.Left := btnVirtualKey[nCH].Left + btnVirtualKey[nCH].Width+ 10;
    pnlSwitch.Top  := btnVirtualKey[nCH].Top - btnVirtualKey[nCH].Height*3;
  end
  else begin
    pnlSwitch2.Visible := not pnlSwitch2.Visible;
    pnlSwitch2.Left := btnVirtualKey[nCH].Left + btnVirtualKey[nCH].Width+ 10;
    pnlSwitch2.Top  := btnVirtualKey[nCH].Top - btnVirtualKey[nCH].Height*3;

  end;
end;

procedure TfrmTest4ChOC.btnLampOnoffClick(Sender: TObject);
var nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;
  if ControlDio.Connected then begin

    if ControlDio.ReadOutSig(DefDio.OUT_CH_1_2_LAMP_OFF +nCH )  then begin
      ControlDio.LampOnOff(nCH,True);
      btnLampOnoff[nCH].Caption := 'tắt đèn   (Lamp OFF)';
    end
    else begin
      ControlDio.LampOnOff(nCH,False);
      btnLampOnoff[nCH].Caption := 'bật đèn   (Lamp ON)';
    end;
  end;
end;

procedure TfrmTest4ChOC.chkPgClick(Sender: TObject);
var
  i,nCH : integer;
begin
  nCH := (Sender as TRzCheckBox).Tag;
  chkChannelUse[nCH].Checked := Common.SystemInfo.UseCh[nCH];

  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if Sender = chkChannelUse[i] then begin
      if chkChannelUse[i].Checked then  chkChannelUse[i].Font.Color := clGreen
      else                              chkChannelUse[i].Font.Color := clRed;
      PasScr[i].m_bUse := chkChannelUse[i].Checked;
      if PasScr[i].m_bUse THEN
        AddLog(Format('m_bUse CH: %d' ,[I]),i)
      else AddLog(Format('m_bUse no CH: %d' ,[I]),i);

      Common.StatusInfo.UseChannel[i]:= chkChannelUse[i].Checked;
      Break;
    end;
  end;
end;

procedure TfrmTest4ChOC.ClearChData(nCh: Integer);
var
I : integer;
begin
  try
    if nCh >= DefCommon.MAX_PG_CNT then Exit;

    pnlSerials[nCh].Caption := '';
    if Common.SystemInfo.OcManualType then begin
      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
        pnlSerials[nCh].Color := clBlack;
        pnlSerials[nCh].Font.Color := clYellow;
      end
      else begin
        pnlSerials[nCh].Color := clBtnFace;
        pnlSerials[nCh].Font.Color := clBlack;
      end;
    end;


    pnlMESResults[nCh].Caption := '';
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlPGStatuses[nCh].Color := clBlack;
      pnlPGStatuses[nCh].Font.Color := clWhite;
      pnlMESResults[nCh].Color := clBlack;
      pnlMESResults[nCh].Font.Color := clWhite;
    end
    else begin
      pnlPGStatuses[nCh].Color := clBtnFace;
      pnlPGStatuses[nCh].Font.Color := clBlack;
      pnlMESResults[nCh].Color := clBtnFace;
      pnlMESResults[nCh].Font.Color := clYellow;
    end;
    pnlPGStatuses[nCh].Font.Size := 24;
    if PasScr[nCh].m_bUse then begin
      pnlPGStatuses[nCh].Caption := 'Ready';
    end
    else begin
      pnlPGStatuses[nCh].Caption := 'Skip';
    end;
    pnlPGStatuses[nCh].Font.Name := 'Verdana';     //Tahoma

    gridPWRPGs[nCh].ClearAll;

    gridPWRPGs[nCh].ColWidths[0] := 60;
    gridPWRPGs[nCh].ColWidths[1] := 30;
    gridPWRPGs[nCh].ColWidths[2] := 60;


    gridPWRPGs[nCh].ColumnHeaders.Add('');
    gridPWRPGs[nCh].ColumnHeaders.Add('Voltage'{'Voltage'});
    gridPWRPGs[nCh].ColumnHeaders.Add('Current'{'Current'});

    gridPWRPGs[nCh].Cells[0,1] := 'VCC/IVCC';
    gridPWRPGs[nCh].Cells[0,2] := 'VIN/IVIN';
    gridPWRPGs[nCh].AutoSizeColumns(true);

    mmChannelLog[nCh].Clear;

    pnlUnitTactVal[nCh].Caption := '000 : 00';
    pnlNowValues[nCh].Caption := '000 : 00';

    m_nUnitTact[nCh] := 0;
    m_nTotalTact[nCh] := 0;
  finally
  end;
end;



procedure TfrmTest4ChOC.ClearPreviousResult;
var
  i, k: Integer;
begin
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    PasScr[Tag*4 + i].m_lstPrevRet.Clear;

    if Common.SystemInfo.NGAlarmCount = 0 then Continue;
    for k := 0 to Common.SystemInfo.NGAlarmCount -1 do begin
      pnlPrevResult[i, k].Caption  := 'Result ' + IntToStr(k+1);
      pnlPrevResult[i, k].Color    := clBtnFace;
      pnlPrevResult[i, k].Font.Color    := clBlack;
    end;
  end;
end;

function TfrmTest4ChOC.GetIRTempData(nCh : Integer): string;
var
i,j : Integer;
sNit : string;
begin
  Result := '';
  with TStringBuilder.Create do
  begin
    try
      for I := 0 to 5 do begin
        case i of
         0: sNit := 'TEMP';
         1: sNit := '2100_';
         2: sNit := '1680_';
         3: sNit := '600_';
         4: sNit := '30_';
         5: sNit := '10_';
        end;

        for j := 0 to System.Length(m_aTempIr[nCH][i]) -1 do
        begin
          Append('OC')
            .Append(':')
            .Append(sNit+IntToStr(j +1))
            .Append(':')
            .Append(m_aTempIr[nCH][i][j]);

          if (i <> 5) or (System.Length(m_aTempIr[nCH][5]) - 1 <> j) then
            Append(',');
        end;
      end;

      Result := ToString;
    finally
      Free;
    end;
  end;

end;

procedure TfrmTest4ChOC.ControlIRTemp(nCh,nTemp: Integer);
var
i : Integer;
begin
  if Common.SystemInfo.OCType = DefCommon.PreOCType then exit;

  if Common.SystemInfo.Com_IrTempSensor = 0 then Exit;

  if nTemp = 1 then begin
    if (Common.SystemInfo.OCType = DefCommon.OCType) and (not Common.PLCInfo.InlineGIB) then begin
      AddLog('[Source Code] CheckIRTemp : Set Temp : '+ IntToStr(Common.SystemInfo.SetTemperature),nCh);
      tmCheckIRTemp[nCh].Enabled := True;
      m_nTempIrTact[nCh] := 0;
      for I := 0 to 5 do
        setlength(m_aTempIr[nCh][i],0); //초기화
      SaveCsvTempStatus(nCh,'START',frmTest4ChOC[0].m_bFanOnOff[nCh]);
    end;
  end;
  if nTemp = 0 then begin
    if (Common.SystemInfo.OCType = DefCommon.OCType) and (not Common.PLCInfo.InlineGIB) then begin
      tmCheckIRTemp[nCh].Enabled := False;   // IR 센서 저장 종료
      ControlDio.WriteDioSig(DefDio.OUT_CH1_PMIC_FAN_ON + 16 * nCH,True); // FAN DIO OFF
      SaveCsvTempStatus(nCh,'END',m_bFanOnOff[nCh]);
    end;
  end;

end;

procedure TfrmTest4ChOC.CreateGui;
var
  i, nItemHeight, nItemWidth, j : Integer;
  nFontSize : Integer;
  sTemp : string;
begin


  //  // tact time을 위한 timer.

  for I := 0 to DefCommon.MAX_CH do begin
    m_nTotalTact[i]:= 0;
    tmTotalTactTime[i] := TTimer.Create(Self);
    tmTotalTactTime[i].Interval := 1000;
    tmTotalTactTime[i].OnTimer := OnTotalTimer;
    tmTotalTactTime[i].Enabled := False;

    m_nUnitTact[i] := 0;
    tmUnitTactTime[i] := TTimer.Create(Self);
    tmUnitTactTime[i].Interval := 1000;
    tmUnitTactTime[i].OnTimer := OnUnitTimer;
    tmUnitTactTime[i].Enabled := False;

    tmCheckIRTemp[i] := TTimer.Create(Self);
    tmCheckIRTemp[i].Interval := 5000;
    tmCheckIRTemp[i].Enabled := False;


    case i of
    DefCommon.CH1 :
      begin
        tmCheckIRTemp[i].OnTimer := OntmCheckIRTemp1;
        tmTotalTactTime[i].OnTimer := OnTotalTimer;
        tmUnitTactTime[i].OnTimer := OnUnitTimer;
      end;
    DefCommon.CH2 :
      begin
        tmCheckIRTemp[i].OnTimer := OntmCheckIRTemp2;
        tmTotalTactTime[i].OnTimer := OnTotal2Timer;
        tmUnitTactTime[i].OnTimer := OnUnit2Timer;
      end;
    DefCommon.CH3 :
      begin
        tmCheckIRTemp[i].OnTimer := OntmCheckIRTemp3;
        tmTotalTactTime[i].OnTimer := OnTotal3Timer;
        tmUnitTactTime[i].OnTimer := OnUnit3Timer;
      end;
    DefCommon.CH4 :
      begin
        tmCheckIRTemp[i].OnTimer := OntmCheckIRTemp4;
        tmTotalTactTime[i].OnTimer := OnTotal4Timer;
        tmUnitTactTime[i].OnTimer := OnUnit4Timer;
      end;
    end;
  end;

  pnlTestMain.Visible := False;

  nItemWidth := (Self.Width - pnlJigInform.Width - pnlJigInform.Left) div (DefCommon.MAX_CH -1)-2;
  nItemHeight := 30;
  // Jig 정보를 위한 Panel.
  for I := DefCommon.CH_TOP to DefCommon.CH_BOTTOM do begin

    pnlJigTitle[i] := TPanel.Create(self);
    pnlJigTitle[i].Parent := pnlJigInform;
    pnlJigTitle[i].Left := 2;
    if Common.SystemInfo.OCType = DefCommon.OCType  then
      pnlJigTitle[i].Top := 424  - i* 422
    else pnlJigTitle[i].Top := 2  + i* 422;

    pnlJigTitle[i].Height := 30;
    pnlJigTitle[i].Width := pnlJigInform.Width -3;
    pnlJigTitle[i].Font.Size := 16;
    pnlJigTitle[i].Color := clBlack;
    pnlJigTitle[i].Font.Color  := clAqua;
    //pnlJigTitle.Alignment := taLeftJustify;
    pnlJigTitle[i].Caption := Format('%d,%d CH',[1+I*2,2+2*I]);
    //pnlJigTitle.Caption := 'Front';
    pnlJigTitle[i].StyleElements := [];

    // button for start testing.
    btnStartTest[i] := TRzBitBtn.Create(self);
    btnStartTest[i].Parent := pnlJigInform;
    btnStartTest[i].Tag := i;
    btnStartTest[i].Top := pnlJigTitle[i].Top + pnlJigTitle[i].Height + 1;//2;
    btnStartTest[i].Left := 2;//100;
    btnStartTest[i].Height := 50;
    btnStartTest[i].Width := pnlJigInform.Width -3;//90;// pnlJig[nJig].Width div nMaxCh;
    btnStartTest[i].Font.Size := 12;
    btnStartTest[i].Cursor := crHandPoint;
    btnStartTest[i].HotTrack := True;
    btnStartTest[i].Caption := 'bắt đầu   (Start)';
    btnStartTest[i].Cursor  := crHandPoint;
    btnStartTest[i].OnClick := BtnStartTestClick;

    // button for start testing.
    btnStopTest[i] := TRzBitBtn.Create(self);
    btnStopTest[i].Parent := pnlJigInform;
    btnStopTest[i].Tag := i;
    btnStopTest[i].Top := btnStartTest[i].Top + btnStartTest[i].Height + 1; //pnlJigTitle.Top + pnlJigTitle.Height + 1;//2;
    btnStopTest[i].Left := 2;// 94;//2[i]00;                [i]
    btnStopTest[i].Height := 50;
    btnStopTest[i].Width := pnlJigInform.Width -3; //90;// pnlJig[nJig].Width div nMaxCh;
    btnStopTest[i].Font.Size := 12;
    btnStopTest[i].HotTrack := True;
    btnStopTest[i].Caption := 'Dừng lại (Stop)';
    btnStopTest[i].Cursor  := crHandPoint;
    btnStopTest[i].OnClick := BtnStopTestClick;
    btnStopTest[i].Cursor := crHandPoint;

    // for Jig Information.
//    pnlTackTimes[i] := TRzPanel.Create(self);
//    pnlTackTimes[i].Parent := pnlJigInform;
//    pnlTackTimes[i].Top := btnStopTest[i].Top + btnStopTest[i].Height + 1;// btnStartTest.Top + btnStartTest.Height + 1;//pnlPGStatuses[nJig].Top + pnlPGStatuses[nJig].Height;
//    pnlTackTimes[i].Left := 2;
//    pnlTackTimes[i].Height := nItemHeight - 10;
//    pnlTackTimes[i].Width := pnlJigInform.Width -3 ;// 90;//66;
//    pnlTackTimes[i].Caption := 'Total Tact';
//    pnlTackTimes[i].BorderOuter := TframeStyleEx(fsFlat);
//    pnlTackTimes[i].Font.Size := 12;
//
//    for j := i * 2 to i * 2 + 1 do begin
//      pnlNowValues[j] := TPanel.Create(self);
//      pnlNowValues[j].Parent := pnlJigInform;
//      pnlNowValues[j].Height := nItemHeight*2 - 40;
//      pnlNowValues[j].Top := pnlTackTimes[i].Top + pnlTackTimes[i].Height + 1 + j* pnlNowValues[j].Height;// pnlTackTimes.Top;
//      pnlNowValues[j].Left := 2;//pnlTackTimes.Left + pnlTackTimes.Width + 1;
//      pnlNowValues[j].Width := pnlJigInform.Width -3;// 90;
//      pnlNowValues[j].Caption := '000: 00';
//      pnlNowValues[j].Color := clBlack;
//      pnlNowValues[j].Font.Color := clLime;
//      pnlNowValues[j].Font.Size := 12;
//      pnlNowValues[j].StyleElements := [];
//    end;
//
//    pnlUnitTact[i] := TRzPanel.Create(self);
//    pnlUnitTact[i].Parent := pnlJigInform;
//    pnlUnitTact[i].Top := pnlNowValues[i+1].Top + pnlNowValues[i].Height + 1;// //pnlTackTimes.Top + pnlTackTimes.Height + 1;
//    pnlUnitTact[i].Left := 2;//pnlNowValues.Left + pnlNowValues.Width+ 1;
//    pnlUnitTact[i].Height := nItemHeight - 10;
//    pnlUnitTact[i].Width := pnlJigInform.Width -3 ;//90;//66;
//    pnlUnitTact[i].Caption := 'CB Tact';
//    pnlUnitTact[i].Font.Size := 8;
//    pnlUnitTact[i].BorderOuter := TframeStyleEx(fsFlat);
//    pnlUnitTact[i].Font.Size := 12;
//
//    pnlUnitTactVal[i] := TPanel.Create(self);
//    pnlUnitTactVal[i].Parent := pnlJigInform;
//    pnlUnitTactVal[i].Top := pnlUnitTact[i].Top + pnlUnitTact[i].Height + 1;
//    pnlUnitTactVal[i].Left := 2;//pnlUnitTact.Left + pnlUnitTact.Width+ 1;
//    pnlUnitTactVal[i].Height := nItemHeight*2 - 20;
//    pnlUnitTactVal[i].Width := pnlJigInform.Width -3 ;//90;
//    pnlUnitTactVal[i].Caption := '000: 00';
//    pnlUnitTactVal[i].Color := clBlack;
//    pnlUnitTactVal[i].Font.Color := clYellow;
//    pnlUnitTactVal[i].Font.Size := 12;
//    pnlUnitTactVal[i].StyleElements := [];

      // button for start testing.
    btnVirtualKey[i] := TRzBitBtn.Create(self);
    btnVirtualKey[i].Parent := pnlJigInform;
    btnVirtualKey[i].Tag  := i;
    //btnVirtualK[i]ey.Top := pnlJigTactVal.Top + pnlJigTactVal.Height + 3;//2;
    btnVirtualKey[i].Top := btnStopTest[i].Top + btnStopTest[i].Height + 1;//2;
    btnVirtualKey[i].Left := 2;//200;

    btnVirtualKey[i].Height := 50;
    btnVirtualKey[i].Width := pnlJigInform.Width - 2;//;180;// pnlJig[nJig].Width div nMaxCh;
    btnVirtualKey[i].Font.Size := 12;
    btnVirtualKey[i].Caption := 'Show Virtual Key';
    btnVirtualKey[i].OnClick := btnVirtualKeyClick;
    btnVirtualKey[i].Cursor := crHandPoint;
    btnVirtualKey[i].HotTrack := True;

    btnLampOnOff[i] := TRzBitBtn.Create(self);
    btnLampOnOff[i].Parent := pnlJigInform;
    btnLampOnOff[i].Tag  := i;
    btnLampOnOff[i].Top := btnVirtualKey[i].Top + btnVirtualKey[i].Height + 1;//2;
    btnLampOnOff[i].Left := 2;//200;
    btnLampOnOff[i].Height := 50;
    btnLampOnOff[i].Width := pnlJigInform.Width - 2;//;180;// pnlJig[nJig].Width div nMaxCh;
    btnLampOnOff[i].Font.Size := 12;
    btnLampOnOff[i].Caption := 'tắt đèn   (Lamp OFF)';
    btnLampOnOff[i].OnClick := btnLampOnOffClick;
    btnLampOnOff[i].Cursor := crHandPoint;
    btnLampOnOff[i].HotTrack := True;

    btnSetIonizer[i] := TRzBitBtn.Create(self);
    btnSetIonizer[i].Parent := pnlJigInform;
    btnSetIonizer[i].Tag  := i;
    btnSetIonizer[i].Top := btnLampOnOff[i].Top + btnLampOnOff[i].Height + 1;//2;
    btnSetIonizer[i].Left := 2;//200;
    btnSetIonizer[i].Height := 50;
    btnSetIonizer[i].Width := pnlJigInform.Width - 2;//;180;// pnlJig[nJig].Width div nMaxCh;
    btnSetIonizer[i].Font.Size := 12;
    btnSetIonizer[i].Caption :=  'Ionizer OFF';
    btnSetIonizer[i].OnClick := btnSetIonizerClick;
    btnSetIonizer[i].Cursor := crHandPoint;
    btnSetIonizer[i].HotTrack := True;

    if i = DefCommon.CH_TOP then begin
      btnVirtualBcr := TRzBitBtn.Create(self);
      btnVirtualBcr.Parent := pnlJigInform;
      btnVirtualBcr.top := btnSetIonizer[i].Top + btnSetIonizer[i].Height  + 1;
      btnVirtualBcr.Left := 2;
      btnVirtualBcr.Height := 50;
      btnVirtualBcr.Width := pnlJigInform.Width - 5;
      btnVirtualBcr.Font.Size := 12;
      btnVirtualBcr.Caption := 'Virtual BCR';
      btnVirtualBcr.OnClick := btnVirtualBcrClick;
      btnVirtualBcr.Cursor := crHandPoint;
      btnVirtualBcr.HotTrack := True;

      btnECSRequest := TRzBitBtn.Create(self);
      btnECSRequest.Parent := pnlJigInform;
      btnECSRequest.Top := btnVirtualBcr.top + btnVirtualBcr.Height + 1;
      btnECSRequest.Left := 2;
//      btnECSRequest.Align := alBottom;
      btnECSRequest.Height := 50;
      btnECSRequest.Width := pnlJigInform.Width - 5;
      btnECSRequest.Font.Size := 12;
      btnECSRequest.Caption := 'ECS Request';
      btnECSRequest.OnClick := btnECSRequestClick;
      btnECSRequest.Cursor := crHandPoint;
      btnECSRequest.HotTrack := True;
    end;
  end;


//  if Common.SystemInfo.OCType = DefCommon.OCType then
//    btnVirtualBcr.Visible := false
//  else btnVirtualBcr.Visible := True;

//  pnlJigTact := TRzPanel.Create(self);
//  pnlJigTact.Parent := pnlJigInform;
//  pnlJigTact.Top := pnlUnitTactVal.Top + pnlUnitTactVal.Height + 1;// //pnlTackTimes.Top + pnlTackTimes.Height + 1;
//  pnlJigTact.Left := 2;//pnlNowValues.Left + pnlNowValues.Width+ 1;
//  pnlJigTact.Height := nItemHeight - 10;
//  pnlJigTact.Width := pnlJigInform.Width -3 ;//90;//66;
//  pnlJigTact.Caption := 'JIG Tact';
//  pnlJigTact.Font.Size := 8;
//  pnlJigTact.BorderOuter := TframeStyleEx(fsFlat);
//  pnlJigTact.Font.Size := 12;
//
//  pnlJigTactVal := TPanel.Create(self);
//  pnlJigTactVal.Parent := pnlJigInform;
//  pnlJigTactVal.Top := pnlJigTact.Top + pnlJigTact.Height + 1;
//  pnlJigTactVal.Left := 2;//pnlUnitTact.Left + pnlUnitTact.Width+ 1;
//  pnlJigTactVal.Height := nItemHeight*2 - 10;
//  pnlJigTactVal.Width := pnlJigInform.Width -3 ;//90;
//  pnlJigTactVal.Caption := '00 : 00';
//  pnlJigTactVal.Color := clBlack;
//  pnlJigTactVal.Font.Color := $00FFC8E3;//clYellow;
//  pnlJigTactVal.Font.Size := 20;
//  pnlJigTactVal.StyleElements := [];

  // detailed items for each channel.
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    pnlChGrp[i] := TRzPanel.Create(self);
    pnlChGrp[i].Parent := pnlTestMain;
    pnlChGrp[i].Font.Size := 8;
    if Common.SystemInfo.OCType = DefCommon.OCType  then begin
      pnlChGrp[i].Height := pnlTestMain.Height div 2;
      pnlChGrp[i].Width := nItemWidth;
      if i div 2 = 0 then
            pnlChGrp[i].Top := 2 + pnlChGrp[i].Height
      else  pnlChGrp[i].Top := 2;
      pnlChGrp[i].Left := nItemWidth * (i mod 2) + pnlJigInform.Width;
    end
    else begin
      pnlChGrp[i].Height := pnlTestMain.Height;
      pnlChGrp[i].Width := nItemWidth div 2;
      pnlChGrp[i].Top := 2;
      pnlChGrp[i].Left := pnlChGrp[i].Width *i + pnlJigInform.Width;
    end;
    pnlChGrp[i].Align := alNone;
    pnlChGrp[i].Font.Color  := clBlack;
    pnlChGrp[i].Alignment := taRightJustify;
//      pnlChGrp[i].Caption := Format('Ch Grp %d',[i+1]);// '';
    pnlChGrp[i].BorderOuter := TframeStyleEx(fsFlat);
//    pnlChGrp[i].Visible := False;


    pnlHwVersion[i] := TRzPanel.Create(self);
    pnlHwVersion[i].Parent := pnlChGrp[i];
    pnlHwVersion[i].Top := 2;
    pnlHwVersion[i].Height := nItemHeight;
    pnlHwVersion[i].Font.Size := 8;
    pnlHwVersion[i].Align := alTop;
    pnlHwVersion[i].Font.Color  := clBlack;
    pnlHwVersion[i].Alignment := taRightJustify;
    pnlHwVersion[i].Caption := '';
    pnlHwVersion[i].Hint    := 'FW , FPGA , MDM , Power Version';
    pnlHwVersion[i].ShowHint := True;
    pnlHwVersion[i].BorderOuter := TframeStyleEx(fsFlat);

    ledPGStatuses[i] := ThhALed.Create(self);
    ledPGStatuses[i].Parent := pnlHwVersion[i];
    ledPGStatuses[i].LEDStyle := LEDSqLarge;
    ledPGStatuses[i].Blink    := False;
    ledPGStatuses[i].Top := 3;
    ledPGStatuses[i].Left := 4;



    chkChannelUse[i] := TRzCheckBox.Create(self);
    chkChannelUse[i].Parent := pnlChGrp[i];
    chkChannelUse[i].CustomGlyphs.Assign(imgCheckBox.Picture.Bitmap);// := bmp;
    chkChannelUse[i].Top := pnlHwVersion[i].Top + pnlHwVersion[i].Height;
    chkChannelUse[i].Tag := i;
    chkChannelUse[i].Height := nItemHeight;
    chkChannelUse[i].Align := alTop;
    chkChannelUse[i].AutoSize := False;
    chkChannelUse[i].OnClick := chkPgClick;
    chkChannelUse[i].Caption := Format('kênh (Channel) %d',[i+1+self.Tag*4]);//Format('Channel %d',[i+1+self.Tag*4]);
    chkChannelUse[i].AlignmentVertical := TAlignmentVertical(avCenter);
    chkChannelUse[i].Font.Size := 12;
//    chkChannelUse[i].State := cbChecked;
    chkChannelUse[i].Font.Color := clGreen;
    chkChannelUse[i].Cursor := crHandPoint;

    //chkChannelUse[i].ReadOnly:= True;

    pnlSerials[i] := TPanel.Create(self);
    pnlSerials[i].Parent := pnlChGrp[i];
    pnlSerials[i].Top := chkChannelUse[i].Top + chkChannelUse[i].Height;
    pnlSerials[i].Height := nItemHeight;
    pnlSerials[i].Align := alTop;
    pnlSerials[i].Color := clBtnFace;
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlSerials[i].Color := clBlack;
      pnlSerials[i].Font.Color := clYellow;
    end
    else begin
      pnlSerials[i].Color := clBtnFace;
      pnlSerials[i].Font.Color := clBlack;
    end;
    pnlSerials[i].Hint  := 'Serial Number';
    pnlSerials[i].ShowHint  := True;
    pnlSerials[i].Alignment := taLeftJustify; //taCenter;
    pnlSerials[i].Font.Name := 'Tahoma';
    pnlSerials[i].Caption := '';//Format('23020218LN36A308416900A2%sC231369V16A3169WFB0000%d',[chr(10),i]);
    pnlSerials[i].ParentBackground := False;
    pnlSerials[i].StyleElements := [];
    pnlSerials[i].Font.Size := 10;
    pnlSerials[i].Tag := i;
    pnlSerials[i].OnDblClick := pnlSerials1DblClick;

    if Common.SystemInfo.UseAutoBCR then begin
      pnlSerials2[i] := TRzPanel.Create(self);
      pnlSerials2[i].Parent := pnlChGrp[i];
      pnlSerials2[i].Top := pnlChGrp[i].Height;
      pnlSerials2[i].Height := nItemHeight;
      pnlSerials2[i].Align := alTop;
      pnlSerials2[i].Color := clBtnFace;
      pnlSerials2[i].Hint  := 'Serial Number2';
      pnlSerials2[i].ShowHint  := True;
      pnlSerials2[i].Alignment := taCenter;
      pnlSerials2[i].WordWrap  := True;
      pnlSerials2[i].Font.Name := 'Tahoma';
      pnlSerials2[i].Caption := '';//Format('23020218LN36A308416900A2%sC231369V16A3169WFB0000%d',[chr(10),i]);
      pnlSerials2[i].BorderOuter := TframeStyleEx(fsFlat);
    end;

    pnlMESResults[i] := TPanel.Create(self);
    pnlMESResults[i].Parent := pnlChGrp[i];
//    pnlMESResults[i].Top := pnlSerials[i].Top + pnlSerials[i].Height;
    pnlMESResults[i].Top := pnlChGrp[i].Height;
    pnlMESResults[i].Height := nItemHeight;
    pnlMESResults[i].Align := alTop;
    pnlMESResults[i].Caption := '';
    pnlMESResults[i].Hint := 'ECS Result';
    pnlMESResults[i].ShowHint := True;
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlMESResults[i].Color := clBlack;
      pnlMESResults[i].Font.Color := clWhite;
    end
    else begin
      pnlMESResults[i].Color := clBtnFace;
      pnlMESResults[i].Font.Color := clYellow;
    end;

    pnlMESResults[i].Font.Size := 12;
    pnlMESResults[i].ParentBackground := False;
    pnlMESResults[i].StyleElements := [];

    pnlAging[i] := TPanel.Create(Self);
    pnlAging[i].Parent := pnlChGrp[i];
    pnlAging[i].Align := alTop;
    pnlAging[i].Top := 275;
    pnlAging[i].Height := 60;
    pnlAging[i].Visible := False;
    pnlAging[i].StyleElements   := [];
    pnlAging[i].ParentBackground:= False;
    pnlAging[i].Color           := clBlue;
    pnlAging[i].Font.Color      := clWhite;
    pnlAging[i].Font.Name       := 'Verdana';
    pnlAging[i].Font.Size       := 24;
    pnlAging[i].Font.Style      := [fsBold];
    pnlAging[i].Caption         := '';
    pnlAging[i].Visible         := False;

    pnlPGStatuses[i] := TPanel.Create(Self);
    pnlPGStatuses[i].Parent := pnlChGrp[i];
//    pnlPGStatuses[i].Top := pnlMESResults[i].Top + pnlMESResults[i].Height;
    pnlPGStatuses[i].Top := pnlChGrp[i].Height;
    pnlPGStatuses[i].Align := alTop;
    pnlPGStatuses[i].Caption := 'Ready';
    pnlPGStatuses[i].Font.Name := 'Verdana';
    pnlPGStatuses[i].Hint := 'Inspection Result';
    pnlPGStatuses[i].ShowHint := True;
    pnlPGStatuses[i].Color := clBtnFace;
    pnlPGStatuses[i].Font.Size := 24;
    pnlPGStatuses[i].ParentBackground := False;
    pnlPGStatuses[i].StyleElements := [];
//    pnlPGStatuses[i].BorderOuter := TframeStyleEx(fsFlat);
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlPGStatuses[i].Color := clBlack;
      pnlPGStatuses[i].Font.Color := clWhite;
//      pnlPGStatuses[i].StyleElements := [];
    end
    else begin
//      pnlPGStatuses[i].StyleElements := [];//[seFont, seClient, seBorder];
      pnlPGStatuses[i].Font.Color := clBlack;
    end;

    // only for result.
    pnlTimeNResult[i] := TRzPanel.Create(self);
    pnlTimeNResult[i].Parent := pnlChGrp[i];
//    pnlTimeNResult[i].Top := pnlPGStatuses[i].Top + pnlPGStatuses[i].Height;
    pnlTimeNResult[i].Top := pnlChGrp[i].Height;
    pnlTimeNResult[i].Height := nItemHeight+4;
    pnlTimeNResult[i].Align := alTop;
    pnlTimeNResult[i].BorderOuter := TframeStyleEx(fsFlat);

        pnlMesConfirm[i] := TPanel.Create(Self);    //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
//    pnlMesConfirm[i].Parent := pnlGrpDio[i];
    pnlMesConfirm[i].Parent := pnlChGrp[i];
    pnlMesConfirm[i].BringToFront();
    pnlMesConfirm[i].Align  := alTop;
    pnlMesConfirm[i].Top    := 275;
    pnlMesConfirm[i].Height := 70;
//    pnlMesConfirm[i].Align  := alTop;
//    pnlMesConfirm[i].Top    := pnlGrpDio[i].Top;
//    pnlMesConfirm[i].Height := pnlGrpDio[i].Height;
//    pnlMesConfirm[i].Width  := pnlGrpDio[i].Width;
    pnlMesConfirm[i].Font.Size := 20;
    pnlMesConfirm[i].Font.Color := clWhite;
    pnlMesConfirm[i].Color   := clFuchsia;
    pnlMesConfirm[i].Visible := false;
    pnlMesConfirm[i].Caption := '';
    pnlMesConfirm[i].StyleElements := [];

    btnSendHost[i] := TRzBitBtn.Create(self);   //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
    btnSendHost[i].Parent := pnlMesConfirm[i];
    btnSendHost[i].Top := 10;
    btnSendHost[i].Left := 10;
    btnSendHost[i].Height := pnlMesConfirm[i].Height div 2 + 15;
    btnSendHost[i].Width := pnlMesConfirm[i].Width div 3;
    btnSendHost[i].Font.Size := 16;
    btnSendHost[i].Font.Style := [fsBold];
    btnSendHost[i].Cursor := crHandPoint;
    btnSendHost[i].Tag := i;
    btnSendHost[i].HotTrack := True;
    btnSendHost[i].Caption := 'Send EICR';
    btnSendHost[i].OnClick := btnSendHostClick;

    btnCancelHost[i] := TRzBitBtn.Create(self);  //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
    btnCancelHost[i].Parent := pnlMesConfirm[i];
    btnCancelHost[i].Top := 10;
    btnCancelHost[i].Height := pnlMesConfirm[i].Height div 2 + 15;
    btnCancelHost[i].Width := pnlMesConfirm[i].Width div 3;
    btnCancelHost[i].Left := pnlMesConfirm[i].Width - 10 - btnCancelHost[i].Width;
    btnCancelHost[i].Font.Size := 16;
    btnCancelHost[i].Cursor := crHandPoint;
    btnCancelHost[i].Tag := i;
    btnCancelHost[i].HotTrack := True;
    btnCancelHost[i].Caption := 'Restart';
    btnCancelHost[i].Font.Style := [fsBold];
    btnCancelHost[i].OnClick := btnCancelHostClick;

    nFontSize := 12;

    pnlTotalNames[i] := TPanel.Create(self);
    pnlTotalNames[i].Parent := pnlTimeNResult[i];
    pnlTotalNames[i].Top := 1;
    pnlTotalNames[i].Left := 0;
    pnlTotalNames[i].Height := pnlTimeNResult[i].Height;
    pnlTotalNames[i].Width := 90;
    pnlTotalNames[i].Caption := 'sản xuất(Total)';
    pnlTotalNames[i].Font.Size := nFontSize - 4;
//
    pnlTotalValues[i] := TPanel.Create(self);
    pnlTotalValues[i].Parent := pnlTimeNResult[i];
    pnlTotalValues[i].Top := 1;
    pnlTotalValues[i].Left := pnlTotalNames[i].Left + pnlTotalNames[i].Width + 1;
    pnlTotalValues[i].Height :=  pnlTimeNResult[i].Height-2;
    pnlTotalValues[i].Width := 50;
    pnlTotalValues[i].Caption := '0';
    pnlTotalValues[i].Font.Size := nFontSize + 2;
    pnlTotalValues[i].Color := clBlack;
    pnlTotalValues[i].Font.Color := clYellow;
    pnlTotalValues[i].StyleElements := [];


    pnlOKNames[i] := TPanel.Create(Self);
    pnlOKNames[i].Parent := pnlTimeNResult[i];
    pnlOKNames[i].Top := 1;
    pnlOKNames[i].Left := pnlTotalValues[i].Left + pnlTotalValues[i].Width + 1;
    pnlOKNames[i].Height := pnlTimeNResult[i].Height;
    pnlOKNames[i].Width := 36;
    pnlOKNames[i].Caption := 'OK';
    pnlOKNames[i].Font.Size := nFontSize-2;

    pnlOKValues[i] := TPanel.Create(Self);
    pnlOKValues[i].Parent := pnlTimeNResult[i];
    pnlOKValues[i].Top := 1;
    pnlOKValues[i].Left := pnlOKNames[i].Left + pnlOKNames[i].Width + 1;
    pnlOKValues[i].Height := pnlTimeNResult[i].Height-2;
    pnlOKValues[i].Width := 50;
    pnlOKValues[i].Color := clBlack;
    pnlOKValues[i].Caption := '0';
    pnlOKValues[i].Font.Size := nFontSize +2;
    pnlOKValues[i].Font.Color := clLime;
    pnlOKValues[i].StyleElements := [];


    pnlNGNames[i] := TPanel.Create(Self);
    pnlNGNames[i].Parent := pnlTimeNResult[i];
    pnlNGNames[i].Top := 1;
    pnlNGNames[i].Left := pnlOKValues[i].Left + pnlOKValues[i].Width + 1;
    pnlNGNames[i].Height := pnlTimeNResult[i].Height;
    pnlNGNames[i].Width := 36;
    pnlNGNames[i].Font.Size := nFontSize-2;
    pnlNGNames[i].Caption := 'NG';

    pnlNGValues[i] := TPanel.Create(Self);
    pnlNGValues[i].Parent := pnlTimeNResult[i];
    pnlNGValues[i].Top := 1;
    pnlNGValues[i].Left := pnlNGNames[i].Left + pnlNGNames[i].Width + 1;
    pnlNGValues[i].Height := pnlTimeNResult[i].Height-2;
    pnlNGValues[i].Width := 50;
    pnlNGValues[i].Color := clBlack;
    pnlNGValues[i].Caption := '0';
    pnlNGValues[i].Font.Size := nFontSize +2;
    pnlNGValues[i].Font.Color := clRed;
    pnlNGValues[i].StyleElements := [];

    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      pnlTempPanel[i]  := TPanel.Create(self);
      pnlTempPanel[i].Parent  := pnlTimeNResult[i];
      pnlTempPanel[i].Top     := 1;
      pnlTempPanel[i].Left    := pnlNGValues[i].Left + pnlNGValues[i].Width + 1;
      pnlTempPanel[i].Height  := pnlTimeNResult[i].Height-2;
      pnlTempPanel[i].Width   := 80;
      pnlTempPanel[i].Caption := 'Panel Temp.';

      pnlTempPanelVal[2 * i]  := TPanel.Create(self);
      pnlTempPanelVal[2 * i].Parent := pnlTimeNResult[i];
      pnlTempPanelVal[2 * i].Top    := 1;
      pnlTempPanelVal[2 * i].Left := pnlTempPanel[i].Left + pnlTempPanel[i].Width + 1;
      pnlTempPanelVal[2 * i].Width  := 70;
      pnlTempPanelVal[2 * i].Height := pnlTimeNResult[i].Height-2;
      pnlTempPanelVal[2 * i].Caption := '- -';//Format('%d °C',[25]);
      pnlTempPanelVal[2 * i].Color := clBlack;
      pnlTempPanelVal[2 * i].Font.Color := clWhite;
      pnlTempPanelVal[2 * i].StyleElements := [];
      pnlTempPanelVal[2 * i].Font.Size := 12;

      pnlTempPanelVal[2*i +1]  := TPanel.Create(self);
      pnlTempPanelVal[2*i +1].Parent := pnlTimeNResult[i];
      pnlTempPanelVal[2*i +1].Top    := 1;
      pnlTempPanelVal[2*i +1].Left := pnlTempPanelVal[2 * i].Left + pnlTempPanelVal[2 * i].Width + 1;
      pnlTempPanelVal[2*i +1].Width  := 70;
      pnlTempPanelVal[2*i +1].Height := pnlTimeNResult[i].Height-2;
      pnlTempPanelVal[2*i +1].Caption := '- -';//Format('%d °C',[25]);
      pnlTempPanelVal[2*i +1].Color := clBlack;
      pnlTempPanelVal[2*i +1].Font.Color := clWhite;
      pnlTempPanelVal[2*i +1].StyleElements := [];
      pnlTempPanelVal[2*i +1].Font.Size := 12;
    end;

    if (Common.PLCInfo.InlineGIB) and (Common.SystemInfo.OCType = DefCommon.OCType)  then begin
      btnChAutoStart[i] := TButton.Create(self);
      btnChAutoStart[i].Parent := pnlTimeNResult[i];
      btnChAutoStart[i].Align := alRight;
      btnChAutoStart[i].Tag := i;
      btnChAutoStart[i].Left := pnlNGValues[i].Left + pnlNGValues[i].Width + 1;
      btnChAutoStart[i].Height := pnlTimeNResult[i].Height-2;
      btnChAutoStart[i].Width := 70;
      btnChAutoStart[i].Font.Size := 10;
      btnChAutoStart[i].Cursor := crHandPoint;
      btnChAutoStart[i].Caption := 'Start Ch ' + IntToStr(i + 1);
      btnChAutoStart[i].Cursor  := crHandPoint;
      btnChAutoStart[i].Font.Color := clLime;
      btnChAutoStart[i].StyleElements := [];
      btnChAutoStart [i].OnClick := btnChAutoStartClick;

      btnChStop[i] := TButton.Create(self);
      btnChStop[i].Parent := pnlTimeNResult[i];
      btnChStop[i].Align := alRight;
      btnChStop[i].Tag := i;
      btnChStop[i].Left := pnlNGValues[i].Left + pnlNGValues[i].Width + 1;
      btnChStop[i].Height := pnlTimeNResult[i].Height-2;
      btnChStop[i].Width := 70;
      btnChStop[i].Font.Size := 10;
      btnChStop[i].Cursor := crHandPoint;
      btnChStop[i].Caption := 'Stop Ch ' + IntToStr(i + 1);
      btnChStop[i].Cursor  := crHandPoint;
      btnChStop[i].Font.Color := clRed;
      btnChStop[i].StyleElements := [];
      btnChStop [i].OnClick := btnChStopClick;
    end;

    btnResetCount[i] := TRzBitBtn.Create(self);
    btnResetCount[i].Parent := pnlTimeNResult[i];
    btnResetCount[i].Align := alRight;
    btnResetCount[i].Tag := i;
    btnResetCount[i].Left := pnlNGValues[i].Left + pnlNGValues[i].Width + 1;
    btnResetCount[i].Height := pnlTimeNResult[i].Height-2;
    btnResetCount[i].Width := 70;
    btnResetCount[i].Font.Size := 10;
    btnResetCount[i].Cursor := crHandPoint;
    btnResetCount[i].HotTrack := True;
    btnResetCount[i].Caption := 'Count Reset';
    btnResetCount[i].Cursor  := crHandPoint;
    btnResetCount[i].OnClick := btnResetCountClick;


    pnlGrpDio[i] := TPanel.Create(Self);
    pnlGrpDio[i].Parent := pnlChGrp[i];
    pnlGrpDio[i].Align := alTop;
    pnlGrpDio[i].Top := 275;
    pnlGrpDio[i].Height := 65;



    gridPWRPGs[i] := TAdvStringGrid.Create(Self);
    gridPWRPGs[i].Clear;
    gridPWRPGs[i].Parent := pnlGrpDio[i];
    gridPWRPGs[i].Font.Name := 'Tahoma';
    gridPWRPGs[i].Top := 275;
    gridPWRPGs[i].Height := 40;
    gridPWRPGs[i].Width  := 160;
    gridPWRPGs[i].Align := alLeft;
    gridPWRPGs[i].ColCount := 3;
    gridPWRPGs[i].RowCount := 3;
    gridPWRPGs[i].FixedCols := 0;
    gridPWRPGs[i].ColumnHeaders.Add('');
    gridPWRPGs[i].ColumnHeaders.Add('Voltage'{'Voltage'});
    gridPWRPGs[i].ColumnHeaders.Add('mA'{'Current'});
    gridPWRPGs[i].ScrollBars := TScrollStyle.ssNone;
    gridPWRPGs[i].AutoSizeColumns(true);
    gridPWRPGs[i].Font.Size := 7;


    if Common.SystemInfo.OCType = DefCommon.OCType  then begin
    // DIO IN.
      ledDiProbeForward[i] := TTILed.Create(Self);
      ledDiProbeForward[i].Parent := pnlGrpDio[i];
      ledDiProbeForward[i].Top := 1+16*0;
      ledDiProbeForward[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiProbeForward[i].Height := 16;
      ledDiProbeForward[i].Width := 80;
      ledDiProbeForward[i].Font.Size := nFontSize-4;
      ledDiProbeForward[i].Caption := 'Probe Forward';
      ledDiProbeForward[i].LedColor := TLedColor(Green);
      ledDiProbeForward[i].StyleElements := [seBorder];

      ledDiProbeBackward[i] := TTILed.Create(Self);
      ledDiProbeBackward[i].Parent := pnlGrpDio[i];
      ledDiProbeBackward[i].Top := 1+16*1;
      ledDiProbeBackward[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiProbeBackward[i].Height := 16;
      ledDiProbeBackward[i].Width := 80;
      ledDiProbeBackward[i].Font.Size := nFontSize-4;
      ledDiProbeBackward[i].Caption := 'Probe Backward';
      ledDiProbeBackward[i].LedColor := TLedColor(Green);
      ledDiProbeBackward[i].StyleElements := [seBorder];

      ledDiProbeUp[i] := TTILed.Create(Self);
      ledDiProbeUp[i].Parent := pnlGrpDio[i];
      ledDiProbeUp[i].Top := 1+16*2;
      ledDiProbeUp[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiProbeUp[i].Height := 16;
      ledDiProbeUp[i].Width := 80;
      ledDiProbeUp[i].Font.Size := nFontSize-4;
      ledDiProbeUp[i].Caption := 'Probe Up';
      ledDiProbeUp[i].LedColor := TLedColor(Green);
      ledDiProbeUp[i].StyleElements := [seBorder];

      ledDiProbeDown[i] := TTILed.Create(Self);
      ledDiProbeDown[i].Parent := pnlGrpDio[i];
      ledDiProbeDown[i].Top := 1+16*3;
      ledDiProbeDown[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiProbeDown[i].Height := 16;
      ledDiProbeDown[i].Width := 80;
      ledDiProbeDown[i].Font.Size := nFontSize-4;
      ledDiProbeDown[i].Caption := 'Probe Down';
      ledDiProbeDown[i].LedColor := TLedColor(Green);
      ledDiProbeDown[i].StyleElements := [seBorder];

      // DIO OUT.
      ledDoProbeForward[i] := TTILed.Create(Self);
      ledDoProbeForward[i].Parent := pnlGrpDio[i];
      ledDoProbeForward[i].Top := 1+16*0;
      ledDoProbeForward[i].Left := gridPWRPGs[i].Width + ledDiProbeForward[i].Width + 2;
      ledDoProbeForward[i].Height := 16;
      ledDoProbeForward[i].Width := 80;
      ledDoProbeForward[i].Font.Size := nFontSize-4;
      ledDoProbeForward[i].Caption := 'Probe Forward';
      ledDoProbeForward[i].LedColor := TLedColor(Yellow);
      ledDoProbeForward[i].StyleElements := [seBorder];

      ledDoProbeBackward[i] := TTILed.Create(Self);
      ledDoProbeBackward[i].Parent := pnlGrpDio[i];
      ledDoProbeBackward[i].Top := 1+16*1;
      ledDoProbeBackward[i].Left := gridPWRPGs[i].Width + ledDiProbeForward[i].Width + 2;
      ledDoProbeBackward[i].Height := 16;
      ledDoProbeBackward[i].Width := 80;
      ledDoProbeBackward[i].Font.Size := nFontSize-4;
      ledDoProbeBackward[i].Caption := 'Probe Backward';
      ledDoProbeBackward[i].LedColor := TLedColor(Yellow);
      ledDoProbeBackward[i].StyleElements := [seBorder];


      // DIO IN
      ledDoProbeUp[i] := TTILed.Create(Self);
      ledDoProbeUp[i].Parent := pnlGrpDio[i];
      ledDoProbeUp[i].Top := 1+16*2;
      ledDoProbeUp[i].Left := gridPWRPGs[i].Width + ledDiProbeForward[i].Width + 2;
      ledDoProbeUp[i].Height := 16;
      ledDoProbeUp[i].Width := 80;
      ledDoProbeUp[i].Font.Size := nFontSize-4;
      ledDoProbeUp[i].Caption := 'Probe Up';
      ledDoProbeUp[i].LedColor := TLedColor(Yellow);
      ledDoProbeUp[i].StyleElements := [seBorder];

      ledDoProbeDown[i] := TTILed.Create(Self);
      ledDoProbeDown[i].Parent := pnlGrpDio[i];
      ledDoProbeDown[i].Top := 1+16*3;
      ledDoProbeDown[i].Left := gridPWRPGs[i].Width + ledDiProbeForward[i].Width + 2;
      ledDoProbeDown[i].Height := 16;
      ledDoProbeDown[i].Width := 80;
      ledDoProbeDown[i].Font.Size := nFontSize-4;
      ledDoProbeDown[i].Caption := 'Probe Down';
      ledDoProbeDown[i].LedColor := TLedColor(Yellow);
      ledDoProbeDown[i].StyleElements := [seBorder];

      ledDiCarrierUnlock1[i] := TTILed.Create(Self);
      ledDiCarrierUnlock1[i].Parent := pnlGrpDio[i];
      ledDiCarrierUnlock1[i].Top := 1+16*0;
      ledDiCarrierUnlock1[i].Left := ledDoProbeDown[i].Width + ledDoProbeDown[i].Left + 2;
      ledDiCarrierUnlock1[i].Height := 16;
      ledDiCarrierUnlock1[i].Width := 80;
      ledDiCarrierUnlock1[i].Font.Size := nFontSize-4;
      ledDiCarrierUnlock1[i].Caption := 'Carrier Unlock1';
      ledDiCarrierUnlock1[i].LedColor := TLedColor(Green);
      ledDiCarrierUnlock1[i].StyleElements := [seBorder];

      ledDiCarrierUnlock2[i] := TTILed.Create(Self);
      ledDiCarrierUnlock2[i].Parent := pnlGrpDio[i];
      ledDiCarrierUnlock2[i].Top := 1+16*1;
      ledDiCarrierUnlock2[i].Left := ledDoProbeDown[i].Width + ledDoProbeDown[i].Left + 2;
      ledDiCarrierUnlock2[i].Height := 16;
      ledDiCarrierUnlock2[i].Width := 80;
      ledDiCarrierUnlock2[i].Font.Size := nFontSize-4;
      ledDiCarrierUnlock2[i].Caption := 'Carrier Unlock2';
      ledDiCarrierUnlock2[i].LedColor := TLedColor(Green);
      ledDiCarrierUnlock2[i].StyleElements := [seBorder];

      ledDiCarrierUnlock3[i] := TTILed.Create(Self);
      ledDiCarrierUnlock3[i].Parent := pnlGrpDio[i];
      ledDiCarrierUnlock3[i].Top := 1+16*2;
      ledDiCarrierUnlock3[i].Left := ledDoProbeDown[i].Width + ledDoProbeDown[i].Left + 2;
      ledDiCarrierUnlock3[i].Height := 16;
      ledDiCarrierUnlock3[i].Width := 80;
      ledDiCarrierUnlock3[i].Font.Size := nFontSize-4;
      ledDiCarrierUnlock3[i].Caption := 'Carrier Unlock3';
      ledDiCarrierUnlock3[i].LedColor := TLedColor(Green);
      ledDiCarrierUnlock3[i].StyleElements := [seBorder];

      ledDiCarrierUnlock4[i] := TTILed.Create(Self);
      ledDiCarrierUnlock4[i].Parent := pnlGrpDio[i];
      ledDiCarrierUnlock4[i].Top := 1+16*3;
      ledDiCarrierUnlock4[i].Left := ledDoProbeDown[i].Width + ledDoProbeDown[i].Left + 2;
      ledDiCarrierUnlock4[i].Height := 16;
      ledDiCarrierUnlock4[i].Width := 80;
      ledDiCarrierUnlock4[i].Font.Size := nFontSize-4;
      ledDiCarrierUnlock4[i].Caption := 'Carrier Unlock4';
      ledDiCarrierUnlock4[i].LedColor := TLedColor(Green);
      ledDiCarrierUnlock4[i].StyleElements := [seBorder];

      ledDiCarrierlock1[i] := TTILed.Create(Self);
      ledDiCarrierlock1[i].Parent := pnlGrpDio[i];
      ledDiCarrierlock1[i].Top := 1+16*0;
      ledDiCarrierlock1[i].Left := ledDiCarrierUnlock1[i].Width + ledDiCarrierUnlock1[i].Left + 2;
      ledDiCarrierlock1[i].Height := 16;
      ledDiCarrierlock1[i].Width := 80;
      ledDiCarrierlock1[i].Font.Size := nFontSize-4;
      ledDiCarrierlock1[i].Caption := 'Carrier lock1';
      ledDiCarrierlock1[i].LedColor := TLedColor(Green);
      ledDiCarrierlock1[i].StyleElements := [seBorder];

      ledDiCarrierlock2[i] := TTILed.Create(Self);
      ledDiCarrierlock2[i].Parent := pnlGrpDio[i];
      ledDiCarrierlock2[i].Top := 1+16*1;
      ledDiCarrierlock2[i].Left := ledDiCarrierUnlock1[i].Width + ledDiCarrierUnlock1[i].Left + 2;
      ledDiCarrierlock2[i].Height := 16;
      ledDiCarrierlock2[i].Width := 80;
      ledDiCarrierlock2[i].Font.Size := nFontSize-4;
      ledDiCarrierlock2[i].Caption := 'Carrier lock2';
      ledDiCarrierlock2[i].LedColor := TLedColor(Green);
      ledDiCarrierlock2[i].StyleElements := [seBorder];

      ledDiCarrierlock3[i] := TTILed.Create(Self);
      ledDiCarrierlock3[i].Parent := pnlGrpDio[i];
      ledDiCarrierlock3[i].Top := 1+16*2;
      ledDiCarrierlock3[i].Left := ledDiCarrierUnlock1[i].Width + ledDiCarrierUnlock1[i].Left + 2;
      ledDiCarrierlock3[i].Height := 16;
      ledDiCarrierlock3[i].Width := 80;
      ledDiCarrierlock3[i].Font.Size := nFontSize-4;
      ledDiCarrierlock3[i].Caption := 'Carrier lock3';
      ledDiCarrierlock3[i].LedColor := TLedColor(Green);
      ledDiCarrierlock3[i].StyleElements := [seBorder];

      ledDiCarrierlock4[i] := TTILed.Create(Self);
      ledDiCarrierlock4[i].Parent := pnlGrpDio[i];
      ledDiCarrierlock4[i].Top := 1+16*3;
      ledDiCarrierlock4[i].Left := ledDiCarrierUnlock1[i].Width + ledDiCarrierUnlock1[i].Left + 2;
      ledDiCarrierlock4[i].Height := 16;
      ledDiCarrierlock4[i].Width := 80;
      ledDiCarrierlock4[i].Font.Size := nFontSize-4;
      ledDiCarrierlock4[i].Caption := 'Carrier lock4';
      ledDiCarrierlock4[i].LedColor := TLedColor(Green);
      ledDiCarrierlock4[i].StyleElements := [seBorder];

    // DIO IN.
      ledDoCarrierUnlockSol[i] := TTILed.Create(Self);
      ledDoCarrierUnlockSol[i].Parent := pnlGrpDio[i];
      ledDoCarrierUnlockSol[i].Top := 1+16*0;
      ledDoCarrierUnlockSol[i].Left := ledDiCarrierlock1[i].Width + ledDiCarrierlock1[i].Left + 2 ;
      ledDoCarrierUnlockSol[i].Height := 16;
      ledDoCarrierUnlockSol[i].Width := 80;
      ledDoCarrierUnlockSol[i].Font.Size := nFontSize-4;
      ledDoCarrierUnlockSol[i].Caption := 'Carrier unlock sol';
      ledDoCarrierUnlockSol[i].LedColor := TLedColor(Yellow);
      ledDoCarrierUnlockSol[i].StyleElements := [seBorder];

      ledDoCarrierLock[i] := TTILed.Create(Self);
      ledDoCarrierLock[i].Parent := pnlGrpDio[i];
      ledDoCarrierLock[i].Top := 1+16*1;
      ledDoCarrierLock[i].Left := ledDiCarrierlock1[i].Width + ledDiCarrierlock1[i].Left+ 2 ;
      ledDoCarrierLock[i].Height := 16;
      ledDoCarrierLock[i].Width := 80;
      ledDoCarrierLock[i].Font.Size := nFontSize-4;
      ledDoCarrierLock[i].Caption := 'Carrier lock sol';
      ledDoCarrierLock[i].LedColor := TLedColor(Yellow);
      ledDoCarrierLock[i].StyleElements := [seBorder];


      ledDiDetect[i] := TTILed.Create(Self);
      ledDiDetect[i].Parent := pnlGrpDio[i];
      ledDiDetect[i].Top := 1;
      ledDiDetect[i].Left := ledDoCarrierLock[i].Width + ledDoCarrierLock[i].Left + 2;
      ledDiDetect[i].Height := 16*2;
      ledDiDetect[i].Width := 50;
      ledDiDetect[i].Font.Size := nFontSize-4;
      ledDiDetect[i].Caption := 'DETECT';
      ledDiDetect[i].LedColor := TLedColor(Green);
      ledDiDetect[i].StyleElements := [seBorder];

      btnTakeOutReport[i] := TRzBitBtn.Create(self);
      btnTakeOutReport[i].Parent := pnlGrpDio[i];
      btnTakeOutReport[i].Top := ledDiDetect[i].Height;
      btnTakeOutReport[i].Tag := i;
      btnTakeOutReport[i].Left := ledDiDetect[i].Left;
      btnTakeOutReport[i].Height := 16 * 2;
      btnTakeOutReport[i].Width := 50;
      btnTakeOutReport[i].Font.Size := 10;
      btnTakeOutReport[i].Cursor := crHandPoint;
      btnTakeOutReport[i].HotTrack := True;
      btnTakeOutReport[i].Caption := 'Take Out';
      btnTakeOutReport[i].Cursor  := crHandPoint;
      btnTakeOutReport[i].OnClick := btnTakeOutReportClick;
    end
    else begin
    // DIO IN.
      ledDiPinBlockUnlockOFF[i] := TTILed.Create(Self);
      ledDiPinBlockUnlockOFF[i].Parent := pnlGrpDio[i];
      ledDiPinBlockUnlockOFF[i].Top := 1+16*0;
      ledDiPinBlockUnlockOFF[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiPinBlockUnlockOFF[i].Height := 16;
      ledDiPinBlockUnlockOFF[i].Width := 80;
      ledDiPinBlockUnlockOFF[i].Font.Size := nFontSize-4;
      ledDiPinBlockUnlockOFF[i].Caption := 'PinBlock Unlock OFF';
      ledDiPinBlockUnlockOFF[i].LedColor := TLedColor(Green);
      ledDiPinBlockUnlockOFF[i].StyleElements := [seBorder];

      ledDiPinBlockUnlockON[i] := TTILed.Create(Self);
      ledDiPinBlockUnlockON[i].Parent := pnlGrpDio[i];
      ledDiPinBlockUnlockON[i].Top := 1+16*1;
      ledDiPinBlockUnlockON[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiPinBlockUnlockON[i].Height := 16;
      ledDiPinBlockUnlockON[i].Width := 80;
      ledDiPinBlockUnlockON[i].Font.Size := nFontSize-4;
      ledDiPinBlockUnlockON[i].Caption := 'PinBlock Unlock ON';
      ledDiPinBlockUnlockON[i].LedColor := TLedColor(Green);
      ledDiPinBlockUnlockON[i].StyleElements := [seBorder];

      ledDiProbeUp[i] := TTILed.Create(Self);
      ledDiProbeUp[i].Parent := pnlGrpDio[i];
      ledDiProbeUp[i].Top := 1+16*2;
      ledDiProbeUp[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiProbeUp[i].Height := 16;
      ledDiProbeUp[i].Width := 80;
      ledDiProbeUp[i].Font.Size := nFontSize-4;
      ledDiProbeUp[i].Caption := 'Probe Up';
      ledDiProbeUp[i].LedColor := TLedColor(Green);
      ledDiProbeUp[i].StyleElements := [seBorder];

      ledDiProbeDown[i] := TTILed.Create(Self);
      ledDiProbeDown[i].Parent := pnlGrpDio[i];
      ledDiProbeDown[i].Top := 1+16*3;
      ledDiProbeDown[i].Left := gridPWRPGs[i].Width + 2 ;
      ledDiProbeDown[i].Height := 16;
      ledDiProbeDown[i].Width := 80;
      ledDiProbeDown[i].Font.Size := nFontSize-4;
      ledDiProbeDown[i].Caption := 'Probe Down';
      ledDiProbeDown[i].LedColor := TLedColor(Green);
      ledDiProbeDown[i].StyleElements := [seBorder];

      // DIO OUT.
      ledDoPinBlockForward[i] := TTILed.Create(Self);
      ledDoPinBlockForward[i].Parent := pnlGrpDio[i];
      ledDoPinBlockForward[i].Top := 1+16*0;
      ledDoPinBlockForward[i].Left := gridPWRPGs[i].Width + ledDiPinBlockUnlockOFF[i].Width + 2;
      ledDoPinBlockForward[i].Height := 16;
      ledDoPinBlockForward[i].Width := 80;
      ledDoPinBlockForward[i].Font.Size := nFontSize-4;
      ledDoPinBlockForward[i].Caption := 'PinBlock Unlock';
      ledDoPinBlockForward[i].LedColor := TLedColor(Yellow);
      ledDoPinBlockForward[i].StyleElements := [seBorder];

      ledDoPinBlockBackward[i] := TTILed.Create(Self);
      ledDoPinBlockBackward[i].Parent := pnlGrpDio[i];
      ledDoPinBlockBackward[i].Top := 1+16*1;
      ledDoPinBlockBackward[i].Left := gridPWRPGs[i].Width + ledDiPinBlockUnlockOFF[i].Width + 2;
      ledDoPinBlockBackward[i].Height := 16;
      ledDoPinBlockBackward[i].Width := 80;
      ledDoPinBlockBackward[i].Font.Size := nFontSize-4;
      ledDoPinBlockBackward[i].Caption := 'PinBlock Lock';
      ledDoPinBlockBackward[i].LedColor := TLedColor(Yellow);
      ledDoPinBlockBackward[i].StyleElements := [seBorder];

      ledDoVaccumON[i] := TTILed.Create(Self);
      ledDoVaccumON[i].Parent := pnlGrpDio[i];
      ledDoVaccumON[i].Top := 1+16*2;
      ledDoVaccumON[i].Left := gridPWRPGs[i].Width + ledDiPinBlockUnlockOFF[i].Width + 2;
      ledDoVaccumON[i].Height := 16;
      ledDoVaccumON[i].Width := 80;
      ledDoVaccumON[i].Font.Size := nFontSize-4;
      ledDoVaccumON[i].Caption := 'Vaccum ON';
      ledDoVaccumON[i].LedColor := TLedColor(Yellow);
      ledDoVaccumON[i].StyleElements := [seBorder];

      ledDoVaccumOFF[i] := TTILed.Create(Self);
      ledDoVaccumOFF[i].Parent := pnlGrpDio[i];
      ledDoVaccumOFF[i].Top := 1+16*3;
      ledDoVaccumOFF[i].Left := gridPWRPGs[i].Width + ledDiPinBlockUnlockOFF[i].Width + 2;
      ledDoVaccumOFF[i].Height := 16;
      ledDoVaccumOFF[i].Width := 80;
      ledDoVaccumOFF[i].Font.Size := nFontSize-4;
      ledDoVaccumOFF[i].Caption := 'Vaccum OFF';
      ledDoVaccumOFF[i].LedColor := TLedColor(Yellow);
      ledDoVaccumOFF[i].StyleElements := [seBorder];

      ledDiDetect[i] := TTILed.Create(Self);
      ledDiDetect[i].Parent := pnlGrpDio[i];
      ledDiDetect[i].Top := 1;
      ledDiDetect[i].Left := ledDoVaccumOFF[i].Width + ledDoVaccumOFF[i].Left + 2;
      ledDiDetect[i].Height := 16*2;
      ledDiDetect[i].Width := 50;
      ledDiDetect[i].Font.Size := nFontSize-4;
      ledDiDetect[i].Caption := 'DETECT';
      ledDiDetect[i].LedColor := TLedColor(Green);
      ledDiDetect[i].StyleElements := [seBorder];

      btnTakeOutReport[i] := TRzBitBtn.Create(self);
      btnTakeOutReport[i].Parent := pnlGrpDio[i];
      btnTakeOutReport[i].Top := ledDiDetect[i].Height;
      btnTakeOutReport[i].Tag := i;
      btnTakeOutReport[i].Left := ledDiDetect[i].Left;
      btnTakeOutReport[i].Height := 16 * 2;
      btnTakeOutReport[i].Width := 50;
      btnTakeOutReport[i].Font.Size := 10;
      btnTakeOutReport[i].Cursor := crHandPoint;
      btnTakeOutReport[i].HotTrack := True;
      btnTakeOutReport[i].Caption := 'Take Out';
      btnTakeOutReport[i].Cursor  := crHandPoint;
      btnTakeOutReport[i].OnClick := btnTakeOutReportClick;

    end;

//    btnTakeOutReport[i] := TRzBitBtn.Create(self);
//    btnTakeOutReport[i].Parent := pnlGrpDio[i];
//    btnTakeOutReport[i].Top := ledDiDetect[i].Height;
//    btnTakeOutReport[i].Tag := i;
//    btnTakeOutReport[i].Left := ledDiDetect[i].Left;
//    btnTakeOutReport[i].Height := 16 * 2;
//    btnTakeOutReport[i].Width := 50;
//    btnTakeOutReport[i].Font.Size := 10;
//    btnTakeOutReport[i].Cursor := crHandPoint;
//    btnTakeOutReport[i].HotTrack := True;
//    btnTakeOutReport[i].Caption := 'Take Out';
//    btnTakeOutReport[i].Cursor  := crHandPoint;
//    btnTakeOutReport[i].OnClick := btnTakeOutReportClick;
//

    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//      pnlPlcClampDn[i].Color   := clBlack;
//      pnlPlcClampDn[i].Font.Color := clWhite;
      ledDiDetect[i].Color   := clBlack;
      ledDiDetect[i].Font.Color := clWhite;
    end
    else begin
//      pnlPlcClampDn[i].Color   := clBtnFace;
//      pnlPlcClampDn[i].Font.Color := clBlack;
      ledDiDetect[i].Color   := clBtnFace;
      ledDiDetect[i].Font.Color := clBlack;
    end;
//    pnlPlcClampDn[i].StyleElements := [];
    //pnlPlcClampDn[i].Visible := True;
    ledDiDetect[i].StyleElements := [];
    ledDiDetect[i].Visible := True;
    if Common.SystemInfo.NGAlarmCount <> 0 then begin
      for j := 0 to Common.SystemInfo.NGAlarmCount -1 do begin
        pnlPrevResult[i,j] := TPanel.Create(Self);
        pnlPrevResult[i,j].Parent := pnlGrpDio[i];

        pnlPrevResult[i,j].Height := 16;
        pnlPrevResult[i,j].Width := 90;
        if j > 3 then begin
          pnlPrevResult[i,j].Top :=  2 + (j-3)*16;
          pnlPrevResult[i,j].Left := ledDiDetect[i].Left + ledDiDetect[i].Width + pnlPrevResult[i,j].Width + 2 ;
        end
        else begin
          pnlPrevResult[i,j].Top :=  2 + j*16;
          pnlPrevResult[i,j].Left := ledDiDetect[i].Left + ledDiDetect[i].Width +  2 ;
        end;



        pnlPrevResult[i,j].Font.Size := nFontSize-2;
        pnlPrevResult[i,j].Caption := Format('Result %d',[j+1]);
        pnlPrevResult[i,j].StyleElements := [];
        pnlPrevResult[i,j].Color   := clBtnFace;
        pnlPrevResult[i,j].Visible := true;// not common.SystemInfo.OcManualType;
        if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
          pnlPrevResult[i,j].Color   := clBlack;
          pnlPrevResult[i,j].Font.Color := clWhite;
        end
        else begin
          pnlPrevResult[i,j].Color   := clBtnFace;
          pnlPrevResult[i,j].Font.Color := clBlack;
        end;
      end;
    end;
    gridPWRPGs[i].ColWidths[0] := 60;
    gridPWRPGs[i].ColWidths[1] := 30;
    gridPWRPGs[i].ColWidths[2] := 60;
//    gridPWRPGs[i].ColWidths[3] := 30;
//    gridPWRPGs[i].ColWidths[4] := 60;
//    gridPWRPGs[i].ColWidths[5] := 60;

    gridPWRPGs[i].Cells[0,1] := 'VCC/IVCC';
    gridPWRPGs[i].Cells[0,2] := 'VIN/IVIN';

//    gridPWRPGs[i].Cells[3,1] := 'VEL';
//    gridPWRPGs[i].Cells[3,2] := '';

    gridPWRPGs[i].DefaultRowHeight := 15;
    gridPWRPGs[i].DefaultAlignment := taCenter;

    pnlLogGrp[i] := TRzPanel.Create(self);
    pnlLogGrp[i].Parent := pnlChGrp[i];
    pnlLogGrp[i].Align := alClient;
    pnlLogGrp[i].BorderOuter := TframeStyleEx(fsFlat);



    mmChannelLog[i] := TMemo.Create(self);// TMemo.Create(self);
    mmChannelLog[i].Parent := pnlLogGrp[i];
    mmChannelLog[i].Align := alClient;
    mmChannelLog[i].ScrollBars := ssVertical;
    mmChannelLog[i].StyleElements := [];
    mmChannelLog[i].ReadOnly := True;
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      mmChannelLog[i].Color := clBlack;
      mmChannelLog[i].Font.Color := clWhite;
      gridPWRPGs[i].Font.Color := clWhite;
    end
    else begin
      mmChannelLog[i].Font.Color := clBlack;
      mmChannelLog[i].Color := clWhite;
      gridPWRPGs[i].Font.Color := clBlack;
    end;

    pnlTackTimesGroup[i] := TPanel.Create(self);
    pnlTackTimesGroup[i].Parent := pnlChGrp[i];
    pnlTackTimesGroup[i].Top := pnlChGrp[i].Height;

    pnlTackTimesGroup[i].Height := 30;

    pnlTackTimesGroup[i].Align := alTop;

    pnlDelayTimesGroup[i] := TPanel.Create(self);
    pnlDelayTimesGroup[i].Parent := pnlChGrp[i];
    pnlDelayTimesGroup[i].Top := pnlChGrp[i].Height;
    if Common.SystemInfo.OCType = DefCommon.OCType  then
      pnlDelayTimesGroup[i].Height := 1
    else pnlDelayTimesGroup[i].Height := 30;


    pnlDelayTimesGroup[i].Align := alTop;

        // for Jig Information.
    pnlTackTimes[i] := TRzPanel.Create(self);
    pnlTackTimes[i].Parent := pnlTackTimesGroup[i];
    pnlTackTimes[i].Top := 1;
    pnlTackTimes[i].Left := 1;
    pnlTackTimes[i].Caption := 'Total Tact';
    pnlTackTimes[i].BorderOuter := TframeStyleEx(fsFlat);
    pnlTackTimes[i].Font.Size := 12;
    pnlTackTimes[i].Align := alLeft;

    pnlNowValues[i] := TPanel.Create(self);
    pnlNowValues[i].Parent := pnlTackTimesGroup[i];
    pnlNowValues[i].Top := 1;
    pnlNowValues[i].Left := 20;
    pnlNowValues[i].Height := 40;
    pnlNowValues[i].Caption := '000: 00';
    pnlNowValues[i].Color := clBlack;
    pnlNowValues[i].Font.Color := clLime;
    pnlNowValues[i].Font.Size := 12;
    pnlNowValues[i].StyleElements := [];
    pnlNowValues[i].Align := alLeft;


    pnlUnitTact[i] := TRzPanel.Create(self);
    pnlUnitTact[i].Parent := pnlTackTimesGroup[i];
    pnlUnitTact[i].Top := pnlTackTimesGroup[i].Height;
    pnlUnitTact[i].Left := 40;
    pnlUnitTact[i].Height := 30;
    pnlUnitTact[i].Caption := 'OC Tact';
    pnlUnitTact[i].BorderOuter := TframeStyleEx(fsFlat);
    pnlUnitTact[i].Font.Size := 12;
    pnlUnitTact[i].Align := alLeft;

    pnlUnitTactVal[i] := TPanel.Create(self);
    pnlUnitTactVal[i].Parent := pnlTackTimesGroup[i];
    pnlUnitTactVal[i].Top := pnlTackTimesGroup[i].Height;
    pnlUnitTactVal[i].Left := 50;
    pnlUnitTactVal[i].Height := 30;
    pnlUnitTactVal[i].Caption := '000: 00';
    pnlUnitTactVal[i].Color := clBlack;
    pnlUnitTactVal[i].Font.Color := clYellow;
    pnlUnitTactVal[i].Font.Size := 12;
    pnlUnitTactVal[i].StyleElements := [];
    pnlUnitTactVal[i].Align := alLeft;

    if Common.SystemInfo.OCType = DefCommon.OCType  then begin

      pnlTackTimes[i].Width := (pnlTackTimesGroup[i].Width -240) div 5 ;
      pnlNowValues[i].Width := (pnlTackTimesGroup[i].Width -240) div 5 ;
      pnlUnitTact[i].Width := (pnlTackTimesGroup[i].Width -240) div 5 ;
      pnlUnitTactVal[i].Width := (pnlTackTimesGroup[i].Width -240) div 5 ;
      pnlDelayTimes[i] := TRzPanel.Create(self);
      pnlDelayTimes[i].Parent := pnlTackTimesGroup[i];
      pnlDelayTimes[i].Top := 1;
      pnlDelayTimes[i].Left := 60;
      pnlDelayTimes[i].Width := 240;
      pnlDelayTimes[i].Caption := 'DLL DelayTime(ms)';
      pnlDelayTimes[i].BorderOuter := TframeStyleEx(fsFlat);
      pnlDelayTimes[i].Font.Size := 12;
      pnlDelayTimes[i].Align := alLeft;

      pnlNowDelayTimes[i] := TPanel.Create(self);
      pnlNowDelayTimes[i].Parent := pnlTackTimesGroup[i];
      pnlNowDelayTimes[i].Top := 1;
      pnlNowDelayTimes[i].Left := 70;
      pnlNowDelayTimes[i].Height := 40;
      pnlNowDelayTimes[i].Width := (pnlTackTimesGroup[i].Width -240) div 5 ;
      pnlNowDelayTimes[i].Caption := '0';
      pnlNowDelayTimes[i].Color := clBlack;
      pnlNowDelayTimes[i].Font.Color := clWhite;
      pnlNowDelayTimes[i].Font.Size := 12;
      pnlNowDelayTimes[i].StyleElements := [];
      pnlNowDelayTimes[i].Align := alLeft;
    end
    else begin
      pnlTackTimes[i].Width := (pnlTackTimesGroup[i].Width) div 4 ;
      pnlNowValues[i].Width := (pnlTackTimesGroup[i].Width) div 4 ;
      pnlUnitTact[i].Width := (pnlTackTimesGroup[i].Width) div 4 ;
      pnlUnitTactVal[i].Width := (pnlTackTimesGroup[i].Width) div 4 ;
      pnlDelayTimes[i] := TRzPanel.Create(self);
      pnlDelayTimes[i].Parent := pnlDelayTimesGroup[i];
      pnlDelayTimes[i].Top := 1;
      pnlDelayTimes[i].Left := 60;
      pnlDelayTimes[i].Width := 240;
      pnlDelayTimes[i].Caption := 'DLL DelayTime(ms)';
      pnlDelayTimes[i].BorderOuter := TframeStyleEx(fsFlat);
      pnlDelayTimes[i].Font.Size := 12;
      pnlDelayTimes[i].Align := alLeft;

      pnlNowDelayTimes[i] := TPanel.Create(self);
      pnlNowDelayTimes[i].Parent := pnlDelayTimesGroup[i];
      pnlNowDelayTimes[i].Top := 1;
      pnlNowDelayTimes[i].Left := 70;
      pnlNowDelayTimes[i].Height := 40;
      pnlNowDelayTimes[i].Width := (pnlDelayTimesGroup[i].Width -240);
      pnlNowDelayTimes[i].Caption := '0';
      pnlNowDelayTimes[i].Color := clBlack;
      pnlNowDelayTimes[i].Font.Color := clWhite;
      pnlNowDelayTimes[i].Font.Size := 12;
      pnlNowDelayTimes[i].StyleElements := [];
      pnlNowDelayTimes[i].Align := alLeft;

    end;
  end;

  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin

    //-------------------------------------------- Timer (Aging)
    tmAgingTimer[i] := TTimer.Create(Self);
    tmAgingTimer[i].Interval := 1000;
    tmAgingTimer[i].OnTimer := OnAgingTimer;
    tmAgingTimer[i].Name := Format('AGING_TIME_%d',[i]);
    tmAgingTimer[i].Enabled := False;
    m_nDiscounter[i] := 0;
  end;


  pnlSwitch.Parent := self;   // 화면 뒤에 있지 않도록 Parent를 변경.

  pnlSwitch.Visible := False;
  pnlTestMain.Visible := True;
end;

procedure TfrmTest4ChOC.btnSendHostClick(Sender: TObject);  //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
begin
  PasScr[(Sender as TRzBitBtn).Tag].HostEvntConfirm(1);
end;

procedure TfrmTest4ChOC.btnCancelHostClick(Sender: TObject); //2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
begin
  PasScr[(Sender as TRzBitBtn).Tag].HostEvntConfirm(2);
end;


procedure TfrmTest4ChOC.OnAgingTimer(Sender: TObject);
var
  nCh : Integer;
  sTimer : string;
begin
  for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    sTimer := Format('AGING_TIME_%d',[nCh]);
    if TTimer(Sender).Name = sTimer then begin
      Dec(m_nDiscounter[nCh]);
      pnlAging[nCh].Caption := Format('%d Sec',[m_nDiscounter[nCh]]);
      if m_nDiscounter[nCh] < 1 then begin
        tmAgingTimer[nCh].Enabled := False;
        pnlAging[nCh].Visible := False;
      end;
      Break;
    end;
  end;
end;


procedure TfrmTest4ChOC.OntmCheckIRTemp1(Sender: TObject);
var
sMemo : string;
nCH : Integer;
begin
  sMemo := '';
  nCH := 0;
  Inc(m_nTempIrTact[0]);
  if (FTempIr[0] >= Common.SystemInfo.SetTemperature) or (FTempIr[1] >= Common.SystemInfo.SetTemperature) then begin
    if (not ControlDio.ReadOutSig(DefDio.OUT_CH1_PMIC_FAN_ON)) then begin
      AddLog(format('temp Anomaly - FAN ON Temp 1 : %f 2 : %f ',[FTempIr[0],FTempIr[1]]),0,1);
      ControlDio.WriteDioSig(DefDio.OUT_CH1_PMIC_FAN_ON,false);
      m_bFanOnOff[nCH] := True;
    end;
  end
  else begin
    if (ControlDio.ReadOutSig(DefDio.OUT_CH1_PMIC_FAN_ON)) then begin
      AddLog('temp Normal - FAN OFF' ,0,0);
      ControlDio.WriteDioSig(DefDio.OUT_CH1_PMIC_FAN_ON,True);
      m_bFanOnOff[0] := False;
    end
  end;
  if CSharpDll.m_CurrentBand[nCH] = 1 then  begin     //1band temp 값 저장
    SetLength(m_aTempIr[nCH][1], Length(m_aTempIr[nCH][1]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][1][Length(m_aTempIr[nCH][1]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 2 then  begin     //2band temp 값 저장
    SetLength(m_aTempIr[nCH][2], Length(m_aTempIr[nCH][2]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][2][Length(m_aTempIr[nCH][2]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 6 then  begin     //6band temp 값 저장
    SetLength(m_aTempIr[nCH][3], Length(m_aTempIr[nCH][3]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][3][Length(m_aTempIr[nCH][3]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 24 then  begin    //24band temp 값 저장
    SetLength(m_aTempIr[nCH][4], Length(m_aTempIr[nCH][4]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][4][Length(m_aTempIr[nCH][4]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 29 then  begin    //29band temp 값 저장
    SetLength(m_aTempIr[nCH][5], Length(m_aTempIr[nCH][5]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][5][Length(m_aTempIr[nCH][5]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if (m_nTempIrTact[nCH] mod 12) = 0 then begin
    SetLength(m_aTempIr[nCH][0], Length(m_aTempIr[nCH][0]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][0][Length(m_aTempIr[nCH][0]) - 1] := format('%f',[FTempIr[1]]);
  end;

  SaveCsvTempStatus(0,sMemo,m_bFanOnOff[0]);
end;

procedure TfrmTest4ChOC.OntmCheckIRTemp2(Sender: TObject);
var
sMemo : string;
nCH : Integer;
begin
  sMemo := '';
  nCH := 1;
  Inc(m_nTempIrTact[1]);
  if (FTempIr[2] > Common.SystemInfo.SetTemperature) or (FTempIr[3] > Common.SystemInfo.SetTemperature) then begin
    if (not ControlDio.ReadOutSig(DefDio.OUT_CH2_PMIC_FAN_ON)) then begin
      AddLog(format('temp Anomaly - FAN ON Temp 1 : %f 2 : %f ',[FTempIr[2],FTempIr[3]]),1,1);
      ControlDio.WriteDioSig(DefDio.OUT_CH2_PMIC_FAN_ON,false);
      m_bFanOnOff[1] := True;
    end;
  end
  else begin
    if (ControlDio.ReadOutSig(DefDio.OUT_CH2_PMIC_FAN_ON)) then begin
      AddLog('temp Normal - FAN OFF' ,1,0);
      ControlDio.WriteDioSig(DefDio.OUT_CH2_PMIC_FAN_ON,True);
      m_bFanOnOff[1] := False;
    end
  end;
  if CSharpDll.m_CurrentBand[nCH] = 1 then  begin     //1band temp 값 저장
    SetLength(m_aTempIr[nCH][1], Length(m_aTempIr[nCH][1]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][1][Length(m_aTempIr[nCH][1]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 2 then  begin     //2band temp 값 저장
    SetLength(m_aTempIr[nCH][2], Length(m_aTempIr[nCH][2]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][2][Length(m_aTempIr[nCH][2]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 6 then  begin     //6band temp 값 저장
    SetLength(m_aTempIr[nCH][3], Length(m_aTempIr[nCH][3]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][3][Length(m_aTempIr[nCH][3]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 24 then  begin    //24band temp 값 저장
    SetLength(m_aTempIr[nCH][4], Length(m_aTempIr[nCH][4]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][4][Length(m_aTempIr[nCH][4]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 29 then  begin    //29band temp 값 저장
    SetLength(m_aTempIr[nCH][5], Length(m_aTempIr[nCH][5]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][5][Length(m_aTempIr[nCH][5]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if (m_nTempIrTact[nCH] mod 12) = 0 then begin
    SetLength(m_aTempIr[nCH][0], Length(m_aTempIr[nCH][0]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][0][Length(m_aTempIr[nCH][0]) - 1] := format('%f',[FTempIr[1]]);
  end;
  SaveCsvTempStatus(1,sMemo,m_bFanOnOff[1]);
end;

procedure TfrmTest4ChOC.OntmCheckIRTemp3(Sender: TObject);
var
sMemo : string;
nCH : Integer;
begin
  sMemo := '';
  nCH := 2;
  Inc(m_nTempIrTact[2]);
  if (FTempIr[4] > Common.SystemInfo.SetTemperature) or (FTempIr[5] > Common.SystemInfo.SetTemperature) then begin
    if (not ControlDio.ReadOutSig(DefDio.OUT_CH3_PMIC_FAN_ON)) then begin
      AddLog(format('temp Anomaly - FAN ON Temp 1 : %f 2 : %f ',[FTempIr[4],FTempIr[5]]),2,1);
      ControlDio.WriteDioSig(DefDio.OUT_CH3_PMIC_FAN_ON,false);
      m_bFanOnOff[2] := True;
    end;
  end
  else begin
    if (ControlDio.ReadOutSig(DefDio.OUT_CH3_PMIC_FAN_ON)) then begin
      AddLog('temp Normal - FAN OFF' ,2,0);
      ControlDio.WriteDioSig(DefDio.OUT_CH3_PMIC_FAN_ON,True);
      m_bFanOnOff[2] := False;
    end
  end;
  if CSharpDll.m_CurrentBand[nCH] = 1 then  begin     //1band temp 값 저장
    SetLength(m_aTempIr[nCH][1], Length(m_aTempIr[nCH][1]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][1][Length(m_aTempIr[nCH][1]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 2 then  begin     //2band temp 값 저장
    SetLength(m_aTempIr[nCH][2], Length(m_aTempIr[nCH][2]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][2][Length(m_aTempIr[nCH][2]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 6 then  begin     //6band temp 값 저장
    SetLength(m_aTempIr[nCH][3], Length(m_aTempIr[nCH][3]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][3][Length(m_aTempIr[nCH][3]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 24 then  begin    //24band temp 값 저장
    SetLength(m_aTempIr[nCH][4], Length(m_aTempIr[nCH][4]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][4][Length(m_aTempIr[nCH][4]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 29 then  begin    //29band temp 값 저장
    SetLength(m_aTempIr[nCH][5], Length(m_aTempIr[nCH][5]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][5][Length(m_aTempIr[nCH][5]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if (m_nTempIrTact[nCH] mod 12) = 0 then begin
    SetLength(m_aTempIr[nCH][0], Length(m_aTempIr[nCH][0]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][0][Length(m_aTempIr[nCH][0]) - 1] := format('%f',[FTempIr[1]]);
  end;
  SaveCsvTempStatus(2,sMemo,m_bFanOnOff[2]);
end;

procedure TfrmTest4ChOC.OntmCheckIRTemp4(Sender: TObject);
var
sMemo : string;
nCH : Integer;
begin
  sMemo := '';
  nCH := 3;
  Inc(m_nTempIrTact[3]);
  if (FTempIr[6] > Common.SystemInfo.SetTemperature) or (FTempIr[7] > Common.SystemInfo.SetTemperature) then begin
    if (not ControlDio.ReadOutSig(DefDio.OUT_CH4_PMIC_FAN_ON)) then begin
      AddLog(format('temp Anomaly - FAN ON Temp 1 : %f 2 : %f ',[FTempIr[6],FTempIr[7]]),3,1);
      ControlDio.WriteDioSig(DefDio.OUT_CH4_PMIC_FAN_ON,false);
      m_bFanOnOff[3] := True;
    end;
  end
  else begin
    if (ControlDio.ReadOutSig(DefDio.OUT_CH4_PMIC_FAN_ON)) then begin
      AddLog('temp Normal - FAN OFF' ,3,0);
      ControlDio.WriteDioSig(DefDio.OUT_CH4_PMIC_FAN_ON,True);
      m_bFanOnOff[3] := False;
    end
  end;
  if CSharpDll.m_CurrentBand[nCH] = 1 then  begin     //1band temp 값 저장
    SetLength(m_aTempIr[nCH][1], Length(m_aTempIr[nCH][1]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][1][Length(m_aTempIr[nCH][1]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 2 then  begin     //2band temp 값 저장
    SetLength(m_aTempIr[nCH][2], Length(m_aTempIr[nCH][2]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][2][Length(m_aTempIr[nCH][2]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 6 then  begin     //6band temp 값 저장
    SetLength(m_aTempIr[nCH][3], Length(m_aTempIr[nCH][3]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][3][Length(m_aTempIr[nCH][3]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 24 then  begin    //24band temp 값 저장
    SetLength(m_aTempIr[nCH][4], Length(m_aTempIr[nCH][4]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][4][Length(m_aTempIr[nCH][4]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if CSharpDll.m_CurrentBand[nCH] = 29 then  begin    //29band temp 값 저장
    SetLength(m_aTempIr[nCH][5], Length(m_aTempIr[nCH][5]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][5][Length(m_aTempIr[nCH][5]) - 1] := format('%f',[FTempIr[1]]);
  end;
  if (m_nTempIrTact[nCH] mod 12) = 0 then begin
    SetLength(m_aTempIr[nCH][0], Length(m_aTempIr[nCH][0]) + 1);   // Temp 배열 증가
    m_aTempIr[nCH][0][Length(m_aTempIr[nCH][0]) - 1] := format('%f',[FTempIr[1]]);
  end;
  SaveCsvTempStatus(3,sMemo,m_bFanOnOff[3]);
end;

procedure TfrmTest4ChOC.DioWorkDone(nErrCode: Integer; sErrMsg: string);
var
  i, nStart, nEnd : Integer;
begin
  case nErrCode of
    0 : begin
      if JigLogic[Self.Tag] <> nil then begin
        nStart := Self.Tag*4;
        nEnd   := Pred(nStart+4);
        for i := nStart to nEnd do begin
          PasScr[i].m_nDioErrCode := 0;
          PasScr[i].SetDioEvent;
          PasScr[i].m_bIsProbeBackSig := False;
        end;
      end;
      if  m_bAutoPlcProbeBack then begin
        m_bAutoPlcProbeBack := False;
  //      tmTotalTactTime.Enabled := False;
      end;
    end;
    // PLC ==> No Probe front Mode ---- NG Case.
    2 : begin
      if JigLogic[Self.Tag] <> nil then begin
        nStart := Self.Tag*4;
        nEnd   := Pred(nStart+4);
        for i := nStart to nEnd do begin
          PasScr[i].m_nDioErrCode := 2;
          PasScr[i].SetDioEvent;
          PasScr[i].m_bIsProbeBackSig := False;
        end;
      end;
    end;
  end;
end;



procedure TfrmTest4ChOC.DisplayDio(bIsIn : Boolean);
var
  nMod, nShift , nCh : Integer;
  bIn, bOut, bTurnA, bTurnB, bShutterUp, bShutterDn : boolean;
begin


  if bIsIn then begin
    for nCh := DefCommon.CH1 to DefCommon.CH4 do begin
      if ControlDio <> nil then begin

        if Common.SystemInfo.OCType = DefCommon.OCType  then begin
          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_PROBE_FORWARD_SENSOR + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_PROBE_FORWARD_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiProbeForward[nCh] <> nil then  ledDiProbeForward[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_PROBE_BACKWARD_SENSOR + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_PROBE_BACKWARD_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiProbeBackward[nCh] <> nil then ledDiProbeBackward[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_PROBE_UP_SENSOR + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_PROBE_UP_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiProbeUp[nCh] <> nil then ledDiProbeUp[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_PROBE_DOWN_SENSOR + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_PROBE_DOWN_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiProbeDown[nCh] <> nil then ledDiProbeDown[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_SENSOR + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiDetect[nCh] <> nil then ledDiDetect[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierUnlock1[nCh] <> nil then ledDiCarrierUnlock1[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierUnlock2[nCh] <> nil then ledDiCarrierUnlock2[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierUnlock3[nCh] <> nil then ledDiCarrierUnlock3[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierUnlock4[nCh] <> nil then ledDiCarrierUnlock4[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_LOCK_1 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_LOCK_1 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierlock1[nCh] <> nil then ledDiCarrierlock1[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_LOCK_2 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_LOCK_2 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierlock2[nCh] <> nil then ledDiCarrierlock2[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_LOCK_3 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_LOCK_3 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierlock3[nCh] <> nil then ledDiCarrierlock3[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_CH_1_CARRIER_LOCK_4 + nCh*16);
          if Common.SignalInversion(Defdio.IN_CH_1_CARRIER_LOCK_4 + nCh*16) then bIn := bIn; // Added by sam81 2023-04-24 오후 3:10:06 센서 추가
          if ledDiCarrierlock4[nCh] <> nil then ledDiCarrierlock4[nCh].LedOn := bIn;
        end
        else begin
          bIn     := ControlDio.ReadInSig(Defdio.IN_GIB_CH_1_PINBLOCK_UNLOCK_OF_SENSOR + nCh*8);
          if Common.SignalInversion(Defdio.IN_GIB_CH_1_PINBLOCK_UNLOCK_OF_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiPinBlockUnlockOFF[nCh] <> nil then ledDiPinBlockUnlockOFF[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_GIB_CH_1_PINBLOCK_UNLOCK_ON_SENSOR + nCh*8);
          if Common.SignalInversion(Defdio.IN_GIB_CH_1_PINBLOCK_UNLOCK_ON_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiPinBlockUnlockON[nCh] <> nil then ledDiPinBlockUnlockON[nCh].LedOn := bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_GIB_CH_12_PROBE_UP_SENSOR + (nCh div 2) *4);
          if Common.SignalInversion(Defdio.IN_GIB_CH_12_PROBE_UP_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiProbeUp[nCh] <> nil then ledDiProbeUp[nCh].LedOn := not bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_GIB_CH_12_PROBE_DN_SENSOR + (nCh div 2) *4);
          if Common.SignalInversion(Defdio.IN_GIB_CH_12_PROBE_DN_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiProbeDown[nCh] <> nil then ledDiProbeDown[nCh].LedOn := not bIn;

          bIn     := ControlDio.ReadInSig(Defdio.IN_GIB_CH_1_CARRIER_SENSOR + nCh*8);
          if Common.SignalInversion(Defdio.IN_GIB_CH_1_CARRIER_SENSOR + nCh*16) then bIn := not bIn; // Added by KTS 2023-01-18 오전 9:04:52 반전 신호
          if ledDiDetect[nCh] <> nil then ledDiDetect[nCh].LedOn := bIn;

        end;
      end;
    end;

  end
  else begin
    for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      //nShift := ($01 shl nMod);
      if CommDaeDIO <> nil then begin

        if Common.SystemInfo.OCType = DefCommon.OCType  then begin
          bOut    := (CommDaeDIO.DODataFlush[4+nCh * 2] and $01) > 0;
          if ledDoProbeForward[nCh] <> nil then ledDoProbeForward[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[4+nCh * 2] and $02) > 0;
          if ledDoProbeBackward[nCh] <> nil then ledDoProbeBackward[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[4+nCh * 2] and $04) > 0;
          if ledDoProbeUp[nCh] <> nil then ledDoProbeUp[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[4+nCh * 2] and $08) > 0;
          if ledDoProbeDown[nCh] <> nil then ledDoProbeDown[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[4+nCh * 2] and $10) > 0;
          if ledDoCarrierUnlockSol[nCh] <> nil then ledDoCarrierUnlockSol[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[4+nCh * 2] and $20) > 0;
          if ledDoCarrierLock[nCh] <> nil then ledDoCarrierLock[nCh].LedOn := bOut;
        end
        else begin
          bOut    := (CommDaeDIO.DODataFlush[3+nCh] and $01) > 0;
          if ledDoVaccumON[nCh] <> nil then ledDoVaccumON[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[3+nCh] and $01) = 0;
          if ledDoVaccumOFF[nCh] <> nil then ledDoVaccumOFF[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[3+nCh] and $02) > 0;
          if ledDoPinBlockBackward[nCh] <> nil then ledDoPinBlockBackward[nCh].LedOn := bOut;
          bOut    := (CommDaeDIO.DODataFlush[3+nCh] and $02) = 0;
          if ledDoPinBlockForward[nCh] <> nil then ledDoPinBlockForward[nCh].LedOn := bOut;

        end;
      end;
    end;

  end;

end;

//procedure TfrmTest4ChOC.DisplayLogAllCh(nCh : Integer; bNg: Boolean; sMsg: string);
//var
//  i : Integer;
//begin
//  if nCh < Defcommon.CH1 then begin
//    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//      AddLog(sMsg,i,TernaryOp(bNg = False,i,0));
//    end;
//  end
//  else begin
//    AddLog(sMsg,i,TernaryOp(bNg = False,i,0));
////    mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//  end;
//end;





procedure TfrmTest4ChOC.DisplayPGStatus(nPgNo, nType: Integer; sMsg: string);  //TBD:QSPI?
var
  nCh : Integer;
  sDebug, sTemp : string;
  sDateTime : string;
//btaBuf : TIdBytes;
  wLen : Word;
  {$IFDEF PG_AF9}
  bPgVerMcsNG, bPgVerApiNG : Boolean;
  {$ENDIF}
  {$IFDEF PG_DP860}
  bPgVerAllNG, bPgVerHwNG, bPgVerFwNG, bPgVerSubFwNG, bPgVerFpgaNG, bPgVerPwrNG,bPgVerScriptNG : Boolean;
  {$ENDIF}
  begin
  nCh := nPgNo mod 4;
  try
    case nType of
      DefCommon.PG_CONN_DISCONNECTED : begin
        ledPGStatuses[nCh].FalseColor := clRed;
        ledPGStatuses[nCh].Value := False;
        pnlHwVersion[nCh].Caption := 'PG Disconnedted';

        //TBD:QSPI? PasScr[nCh].StopRuningScript;
        pnlPGStatuses[nCh].Caption := 'PG BOARD DISCONNECT NG';
        pnlPGStatuses[nCh].Font.Size := 15;
        pnlPGStatuses[nCh].Color := clMaroon;
        pnlPGStatuses[nCh].Font.Name := 'Verdana';
        pnlPGStatuses[nCh].Font.Color := clYellow;
        sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'PG BOARD DISCONNECT NG ';
        AddLog(sDebug,nCh,1);

      end;
      DefCommon.PG_CONN_CONNECTED : begin
        ledPGStatuses[nCh].FalseColor := clYellow;
        ledPGStatuses[nCh].Value := False;
        pnlHwVersion[nCh].Caption := 'PG Connedted';
      end;
      DefCommon.PG_CONN_VERSION : begin
      	case Common.SystemInfo.PG_TYPE of
      		{$IFDEF PG_AF9}
      		DefPG.PG_TYPE_AF9 : begin //---------------- AF9
            pnlPgFwVer[nCh].Caption := Format('PG MCS(%d) API(%d)',[PG[nCh].m_PgVer.AF9VerMCS,PG[nCh].m_PgVer.AF9VerAPI]);
            bPgVerMcsNG := (PG[nCh].m_PgVer.AF9VerMCS < Common.TestModelInfoPG.PgVer.AF9VerMCS);
            bPgVerApiNG := (PG[nCh].m_PgVer.AF9VerAPI < Common.TestModelInfoPG.PgVer.AF9VerAPI);
            if bPgVerMcsNG or bPgVerApiNG then begin
              pnlPGStatuses[nCh].Font.Size := 24;
              pnlPGStatuses[nCh].Color := clMaroon;
              pnlPGStatuses[nCh].Font.Name := 'Verdana';
              pnlPGStatuses[nCh].Font.Color := clYellow;
              sTemp := 'AF9-MCS/API Ver NG ';
              pnlPGStatuses[nCh].Caption := sTemp;
              //
              if bPgVerMcsNG then begin
                sTemp := 'AF9-MCS Ver NG '+ Format('(AF9:%0.3d,Model:%0.3d)', [PG[nCh].m_PgVer.AF9VerMCS, Common.TestModelInfoPG.PgVer.AF9VerMCS]);
                sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].SelAttributes.Color := clRed;
//                mmChannelLog[nCh].SelAttributes.Style := [fsBold];
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
              if bPgVerFpgaNG then begin
                sTemp := 'AF9-API Ver NG '+ Format('(DLL:%0.3d,Model:%0.3d)', [PG[nCh].m_PgVer.AF9VerAPI, Common.TestModelInfoPG.PgVer.AF9VerAPI]);
                sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].SelAttributes.Color := clRed;
//                mmChannelLog[nCh].SelAttributes.Style := [fsBold];
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
            end
            else begin
              if Common.SystemInfo.UIType = DefCommon.UI_BLACK then begin
                pnlPGStatuses[nCh].Color := clBlack;
                pnlPGStatuses[nCh].Font.Color := clWhite;
              end
              else begin
                pnlPGStatuses[nCh].Color := clBtnFace;
                pnlPGStatuses[nCh].Font.Color := clBlack;
              end;
              ledPgStatus[nCh].Value     := True;
              pnlPGStatuses[nCh].Caption := 'Ready';
            end;
          end;
          {$ENDIF} //PG_AF9
          {$IFDEF PG_DP860}
      		DefPG.PG_TYPE_DP860 : begin //-------------- DP860
            // HW_1.3_APP_1.0.2_FW_1.02_FPGA_10105(1.6.0)_PWR_1.0 //= HW_APP_SubFW_FPGA_PWR            // HW_1.3_APP_1.0.2_FW_1.02_FPGA_10105(1.6.0)_PWR_1.0 //= HW_APP_SubFW_FPGA_PWR, SCRIPT
            pnlHwVersion[nCh].Caption := Format('DP860 (%s, %s)',[PG[nCh].m_PgVer.VerAll, PG[nCh].m_PgVer.VerScript]);
            Common.SystemInfo.PG_FWVsersion[nCh] := PG[nCh].m_PgVer.VerAll;
            Common.SavesystemInfoFwVersion(nCh, Common.SystemInfo.PG_FWVsersion[nCh]);
            bPgVerAllNG   := False;
            if Common.TestModelInfoPG.PgVer.VerAll <> '' then bPgVerAllNG   := (CompareText(Pg[nCh].m_PgVer.VerAll, Common.TestModelInfoPG.PgVer.VerAll) < 0);
            {$IFDEF DP860_TBD_XXXXX}
            bPgVerHwNG    := False;
            if Common.TestModelInfoPG.PgVer.HW     <> '' then bPgVerHwNG    := (CompareText(Pg[nCh].m_PgVer.HW,   Common.TestModelInfoPG.PgVer.HW)    < 0);
            bPgVerFwNG    := False;
            if Common.TestModelInfoPG.PgVer.FW     <> '' then bPgVerFwNG    := (CompareText(Pg[nCh].m_PgVer.FW,   Common.TestModelInfoPG.PgVer.FW)    < 0);
            bPgVerSubFwNG := False;
            if Common.TestModelInfoPG.PgVer.SubFW  <> '' then bPgVerSubFwNG := (CompareText(Pg[nCh].m_PgVer.SubFW,Common.TestModelInfoPG.PgVer.SubFW) < 0);
            bPgVerFpgaNG  := False;
            if Common.TestModelInfoPG.PgVer.FPGA   <> '' then bPgVerFpgaNG  := (CompareText(Pg[nCh].m_PgVer.FPGA, Common.TestModelInfoPG.PgVer.FPGA)  < 0);
            bPgVerPwrNG   := False;
            if Common.TestModelInfoPG.PgVer.PWR    <> '' then bPgVerPwrNG   := (CompareText(Pg[nCh].m_PgVer.PWR,  Common.TestModelInfoPG.PgVer.PWR)   < 0);
            {$ENDIF}
            bPgVerScriptNG := False;
            if Common.TestModelInfoPG.PgVer.VerScript <> '' then bPgVerScriptNG := (CompareText(Pg[nCh].m_PgVer.VerScript, Common.TestModelInfoPG.PgVer.VerScript) < 0);
            //
            if bPgVerAllNG or bPgVerScriptNG
                {$IFDEF DP860_TBD_XXXXX}
                or bPgVerHwNG or bPgVerFwNG or bPgVerSubFwNG or bPgVerFpgaNG or bPgVerPwrNG
                {$ENDIF}
            then begin
              ledPGStatuses[nCh].Value := False; //2022-03-24
              //
              pnlPGStatuses[nCh].Font.Size  := 24;
              pnlPGStatuses[nCh].Color      := clMaroon;
              pnlPGStatuses[nCh].Font.Name  := 'Verdana';
              pnlPGStatuses[nCh].Font.Color := clYellow;
              pnlPGStatuses[nCh].Caption    := 'PG Version NG';
              //
//              mmChannelLog[nCh].SelAttributes.Color := clRed;
//              mmChannelLog[nCh].SelAttributes.Style := [fsBold];
              sDateTime := FormatDateTime('[HH:MM:SS.zzz] ',now);
              if bPgVerAllNG then begin
                sTemp  := 'PG Version NG '+ Format('(PG:%s,Model:%s)', [PG[nCh].m_PgVer.VerAll, Common.TestModelInfoPG.PgVer.VerAll]);
                sDebug := sDateTime + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
              {$IFDEF DP860_TBD_XXXXX}
              if bPgVerHwNG then begin
                sTemp  := 'PG Version NG - HW '+ Format('(PG:%s,Model:%s)', [PG[nCh].m_PgVer.HW, Common.TestModelInfoPG.PgVer.HW]);
                sDebug := sDateTime + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
              if bPgVerFwNG then begin
                sTemp  := 'PG Version NG - FW '+ Format('(PG:%s,Model:%s)', [PG[nCh].m_PgVer.FW, Common.TestModelInfoPG.PgVer.FW]);
                sDebug := sDateTime + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
              if bPgVerSubFwNG then begin
                sTemp  := 'PG Version NG - SubFW '+ Format('(PG:%s,Model:%s)', [PG[nCh].m_PgVer.SubFW, Common.TestModelInfoPG.PgVer.SubFW]);
                AddLog(sTemp,nCh,1);
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
              if bPgVerFpgaNG then begin
                sTemp  := 'PG Version NG - FPGA '+ Format('(PG:%s,Model:%s)', [PG[nCh].m_PgVer.FPGA, Common.TestModelInfoPG.PgVer.FPGA]);
                sDebug := sDateTime + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
              if bPgVerPwrNG then begin
                sTemp  := 'PG Version NG - POWER '+ Format('(PG:%s,Model:%s)', [PG[nCh].m_PgVer.PWR, Common.TestModelInfoPG.PgVer.PWR]);
                sDebug := sDateTime + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
              {$ENDIF}
              if bPgVerScriptNG then begin
                sTemp  := 'PG Model Script Version NG '+ Format('(PG:%s,Model:%s)', [PG[nCh].m_PgVer.VerScript, Common.TestModelInfoPG.PgVer.VerScript]);
                sDebug := sDateTime + sTemp;
                AddLog(sDebug,nCh,1);
//                mmChannelLog[nCh].Lines.Add(sDebug);
//                mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//                Common.MLog(nCh,sTemp);
              end;
            end
            else begin
              if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
                pnlPGStatuses[nCh].Color      := clBlack;
                pnlPGStatuses[nCh].Font.Color := clWhite;
              end
              else begin
                pnlPGStatuses[nCh].Color      := clBtnFace;
                pnlPGStatuses[nCh].Font.Color := clBlack;
              end;
              pnlPGStatuses[nCh].Caption := 'PG ModelInfo Downloading';
            end;
          end;
          {$ENDIF} //PG_DP860
        end;
      end;
      DefCommon.PG_CONN_READY : begin
        ledPGStatuses[nCh].Value     := True;
        pnlPGStatuses[nCh].Caption := 'Ready';
      end;
    end;
  except
    Common.DebugMessage('>> DisplayPGStatus Exception Error! ' + IntToStr(nPgNo+1));
  end;
end;

procedure TfrmTest4ChOC.DisplayPGStatuses(nCH, nResult: Integer);
begin
  if pnlPGStatuses[nCh] = nil then Exit;
  try
//    pnlPGStatuses[nCh].DisableAlign;
    pnlPGStatuses[nCh].Font.Size := 24;
    pnlPGStatuses[nCh].Font.Name := 'Verdana';
//    DisplayPreviousRet(nCh);
    // NG 처리.
    if nResult <> 0 then  begin
      pnlPGStatuses[nCh].Color := clMaroon;
      pnlPGStatuses[nCh].Font.Color := clYellow;
      pnlPGStatuses[nCh].Caption := Format('%0.3d NG',[nResult]);
    end
    // OK 처리.
    else begin
      pnlPGStatuses[nCh].Color := clLime;
      pnlPGStatuses[nCh].Font.Color := clBlack;
      pnlPGStatuses[nCh].Caption := 'PASS';
    end;

  finally
//    pnlPGStatuses[nCh].EnableAlign;
  end;

end;

//procedure TfrmTest4ChOC.DisplayPGStatus(nPgNo, nType: Integer; sMsg: string);
//var
//  nCh : Integer;
//begin
//  nCh := nPgNo mod 4;
//  try
//    case nType of
//      0 : begin
//        ledPGStatuses[nCh].Value := True;
//      end;
//      1 : pnlHwVersion[nCh].Caption := sMsg;
//      2 : begin
//        ledPGStatuses[nCh].FalseColor := clRed;
//        ledPGStatuses[nCh].Value := False;
//        pnlHwVersion[nCh].Caption := '';
//      end;
//    end;
//  except
//    Common.DebugMessage('>> DisplayPGStatus Exception Error! ' + IntToStr(nPgNo+1));
//  end;
//end;

procedure TfrmTest4ChOC.DisplayPreviousRet(nCh: Integer);
var
  i, nSum: Integer;
  sMsg : string;
begin
  if Common.SystemInfo.NGAlarmCount = 0 then Exit;

  try
    for i := 0 to pred(PasScr[nCh].m_lstPrevRet.Count) do begin
      if i > (Common.SystemInfo.NGAlarmCount -1) then Continue;
      nSum := nSum + PasScr[nCh].m_lstPrevRet.Items[i];
      if PasScr[nCh].m_lstPrevRet.Items[i] = 0 then begin
        pnlPrevResult[nCh,i].Caption  := 'Pass';
        pnlPrevResult[nCh,i].Color    := clLime;
        pnlPrevResult[nCh,i].Font.Color    := clBlack;
      end
      else begin
        pnlPrevResult[nCh,i].Caption  := Format('%0.2d NG',[PasScr[nCh].m_lstPrevRet.Items[i]]);
        pnlPrevResult[nCh,i].Color    := clRed;
        pnlPrevResult[nCh,i].Font.Color    := clBlack;
      end;
    end;
    if (PasScr[nCh].m_lstPrevRet.Count > 0) and (not Common.TestModelInfoFLOW.IDLEMode) then begin
      if (PasScr[nCh].m_lstPrevRet.Items[0] <> 0) and (nSum <> 0) and ((nSum div Common.SystemInfo.NGAlarmCount) = PasScr[nCh].m_lstPrevRet.Items[0])  then begin
        sMsg := format('Same NG Occurrence : NG CODE : %d',[PasScr[nCh].m_lstPrevRet.Items[0]]);
        SendMessageMain(STAGE_MODE_DISPLAY_ALARAM,nCh, ERR_LIST_1_NG_CONUT +nCh, 1, sMsg,nil);
        m_bPassCH[nCh] := True;  // 동일한 NG Count 발생 시 해당 CH 제외
      end;
    end;
  finally

  end;

end;

procedure TfrmTest4ChOC.DisplayPwrData(nPgNo: Integer; PwrData: TPwrData);
begin
  if gridPWRPGs[nPgNo] = nil then  Exit;
  try
//    gridPWRPGs[nPgNo].DisableAlign;
    gridPWRPGs[nPgNo].Cells[1, 1] := Format('%0.3fV', [PwrData.VCC / 1000]);  // VCC/IVCC
    gridPWRPGs[nPgNo].Cells[2, 1] := Format('%dmA',    [PwrData.IVCC]);
    gridPWRPGs[nPgNo].Cells[1, 2] := Format('%0.3fV', [PwrData.VIN / 1000]);  // VIN/IVIN
    gridPWRPGs[nPgNo].Cells[2, 2] := Format('%dmA',    [PwrData.IVIN]);
    {
    gridPWRPGs[nPgNo].Cells[1, 3] := Format('%0.3f', [PwrVal.VDD3 / 1000]); // VDD3/IVDD3
    gridPWRPGs[nPgNo].Cells[2, 3] := Format('%d',    [PwrVal.IVDD3]);
    gridPWRPGs[nPgNo].Cells[4, 1] := Format('%0.3f', [PwrVal.VDD4 / 1000]); // VDD4/IVDD4
    gridPWRPGs[nPgNo].Cells[5, 1] := Format('%d',    [PwrVal.IVDD4]);
    gridPWRPGs[nPgNo].Cells[4, 2] := Format('%0.3f', [PwrVal.VDD5 / 1000]); // VDD5/IVDD5
    gridPWRPGs[nPgNo].Cells[5, 2] := Format('%d',    [PwrVal.IVDD5]);
    }
    AddLog(format('DisplayPwr VCC : %0.3fV VIN : %0.3fV IVCC : %dmA IVIN : %dmA ',[PwrData.VCC / 1000,PwrData.VIN / 1000,PwrData.IVCC,PwrData.IVIN]),nPgNo);

  finally
//    gridPWRPGs[nPgNo].EnableAlign;
  end;

  // voltage.  gridPWRPGs[nPgNo].DisableAlign;


end;

procedure TfrmTest4ChOC.DisplayResult(nCh, nCode, nColorType: Integer; sMsg: String);
begin
  if pnlPGStatuses[nCh] = nil then Exit;
  try
//    pnlPGStatuses[nCh].DisableAlign;
    case nCode of
      -1, -3 : begin  //ShowCurStatus
//        pnlPGStatuses[nCh].Caption := Trim(sMsg);
        pnlPGStatuses[nCh].Font.Size := 18;
        pnlPGStatuses[nCh].Font.Name := 'Tahoma';

        if nColorType = 1 then begin
          pnlPGStatuses[nCh].Color := clLime;
          pnlPGStatuses[nCh].Font.Color := clBlack;
          pnlPGStatuses[nCh].Caption := Trim(sMsg);
        end
        else if nColorType = 2 then begin
          pnlPGStatuses[nCh].Color := clMaroon;
          pnlPGStatuses[nCh].Font.Color := clYellow;
          pnlPGStatuses[nCh].Caption := Trim(sMsg);
        end
        else  begin
          pnlPGStatuses[nCh].Color := clBtnFace;
          pnlPGStatuses[nCh].Font.Color := clBlack;
          pnlPGStatuses[nCh].Caption := Trim(sMsg);
        end;

        if nCode = -3 then begin //로그 저장
          sMsg := Format('[ %s ]',[sMsg]);
          AddLog(sMsg, nCh);
  //        Common.MLog(nCh, sMsg);
        end;

        Exit;
      end;
      // Script Loading NG.
      - 2 : begin
        pnlPGStatuses[nCh].Font.Size := 24;
        pnlPGStatuses[nCh].Font.Name := 'Verdana';
//        DisplayPreviousRet(nCh);
        // NG 처리.
        pnlPGStatuses[nCh].Color := clMaroon;
        pnlPGStatuses[nCh].Font.Color := clYellow;
        pnlPGStatuses[nCh].Caption := 'Script Loading NG';

        Exit;
      end;
    end;

//    pnlPGStatuses[nCh].DisableAlign;
    //sMsg := Format('PD %d NG',[nTemp]);
    pnlPGStatuses[nCh].Font.Size := 24;
    pnlPGStatuses[nCh].Font.Name := 'Verdana';
    DisplayPreviousRet(nCh);
    // NG 처리.
    if nCode <> 0 then  begin
      pnlPGStatuses[nCh].Color := clMaroon;
  //    pnlPGStatuses[nCh].Font.Color := clYellow;
  //    pnlPGStatuses[nCh].Caption := Format('%0.3d NG - %s',[nTemp, Common.GmesInfo[nTemp].sErrMsg]);
      pnlPGStatuses[nCh].Caption := Format('%0.3d NG',[nCode]);
    end
    // OK 처리.
    else begin
      pnlPGStatuses[nCh].Color := clLime;
      pnlPGStatuses[nCh].Font.Color := clBlack;
      pnlPGStatuses[nCh].Caption := 'PASS';
    end;
  //  pnlPGStatuses[nCh].EnableAlign;
  finally
//    pnlPGStatuses[nCh].EnableAlign;
  end;

end;

procedure TfrmTest4ChOC.DisplaySysInfo(nCh : Integer);
begin
  chkChannelUse[nCh].Checked := Common.SystemInfo.UseCh[nCh];
  PasScr[nCh].m_bUse := Common.SystemInfo.UseCh[nCh];
  Common.StatusInfo.UseChannel[nCh]:= Common.SystemInfo.UseCh[nCh];
end;

procedure TfrmTest4ChOC.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin


//  if tmUnitTactTime <> nil then begin
//    tmUnitTactTime.Enabled := False;
//    tmUnitTactTime.Free;
//    tmUnitTactTime := nil;
//  end;
end;

procedure TfrmTest4ChOC.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  m_Rgb_Avr.AvgType := DefCommon.IDX_RGB_AVR_TYPE_NONE;
  m_nCurStatus := DefScript.SEQ_STOP;
  SetLength(pnlPrevResult,DefCommon.MAX_PG_CNT);
  m_NGAlarmCount := Common.SystemInfo.NGAlarmCount;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    m_nOkCnt[i] := 0;
    m_nNgCnt[i] := 0;
    SetLength(pnlPrevResult[i],m_NGAlarmCount);
  end;

//  SetLength(m_nPreSeqFlowIdx,DefCommon.MAX_PG_CNT);
  m_PlcStatus := psReadyPc;
  m_bAutoPlcProbeBack := False;

  m_bInitGetAvr := False;
  m_csBcrRead:= TCriticalSection.Create;
end;

procedure TfrmTest4ChOC.FormDestroy(Sender: TObject);
var
  i,j : Integer;
begin
  m_csBcrRead.Free;

  for I := 0 to DefCommon.MAX_CH do begin
    if tmTotalTactTime[i] <> nil then begin
      tmTotalTactTime[i].Enabled := False;
      tmTotalTactTime[i].Free;
      tmTotalTactTime[i] := nil;
    end;
    if tmUnitTactTime[i] <> nil then begin
      tmUnitTactTime[i].Enabled := False;
      tmUnitTactTime[i].Free;
      tmUnitTactTime[i] := nil;
    end;
    if tmCheckIRTemp[i] <> nil then begin
      tmCheckIRTemp[i].Enabled := False;
      tmCheckIRTemp[i].Free;
      tmCheckIRTemp[i] := nil;
    end;
    for j := 0 to 5 do
     setlength(m_aTempIr[i][j],0);
  end;

//  VirtualBcr.Free;
//  VirtualBcr := nil;

  if CtrlCa410 <> nil then begin
    CtrlCa410.Free;
    CtrlCa410 := nil;
  end;



  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin

//    if gridPWRPGs[i] <> nil then begin
//      for j := 0 to Pred(gridPWRPGs[i].ColCount) do begin
//        gridPWRPGs[i].Cols[j].Clear;
//      end;
//      gridPWRPGs[i].RowCount := 1;
//
//      gridPWRPGs[i].Free;
//      gridPWRPGs[i] := nil;
//    end;
    for j := 0 to m_NGAlarmCount -1 do begin
      if pnlPrevResult[i][j] <> nil then begin
        pnlPrevResult[i][j].free;
        pnlPrevResult[i][j] := nil;
      end;
    end;

    if mmChannelLog[i] <> nil then begin
      mmChannelLog[i].Free;
      mmChannelLog[i] := nil;
    end;
  end;
  if CaSdk2 <> nil then begin
    CaSdk2.Free;
    CaSdk2 := nil;
  end;

  if CsharpDll <> nil then begin
    CsharpDll.Free;
    CsharpDll := nil;
  end;



  if JigLogic[Self.Tag] <> nil then begin
    JigLogic[Self.Tag].Free;
    JigLogic[Self.Tag] := nil;
  end;
end;

procedure TfrmTest4ChOC.getBcrData(sScanData: string);
var
  nJigCh, i : Integer;
  bIsDone : Boolean;
  sDebug, sRemoveCr : string;
  sPCB_ID : string;
begin
  try
    m_csBcrRead.Acquire; // Hand Bcr Thread event UI 컨트롤 방지
//    AddLog( '<HAND-BCR> Read Data ' + sScanData,DefCommon.MAX_SYSTEM_LOG,0);
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, '<HAND-BCR> Read Data ' + sScanData);
    sRemoveCr := StringReplace(sScanData,#$0a,'',[rfReplaceAll]);
    sRemoveCr := StringReplace(sRemoveCr,#$0d,'',[rfReplaceAll]);
//    AddLog(  '<HAND-BCR> Converting Read Data ' + sRemoveCr,DefCommon.MAX_SYSTEM_LOG,0);
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, '<HAND-BCR> Converting Read Data ' + sRemoveCr);
    for i := Defcommon.CH1 to DefCommon.MAX_CH do begin // 중복 채널 사전 검사 해서 빼기
      if pnlSerials[i].Caption = sRemoveCr then begin
        sDebug := Format('<HAND-BCR> Same Data Exsit skip(Ch:%d) data(%s)',[i + 1, sRemoveCr]);
//        AddLog(sDebug,DefCommon.MAX_SYSTEM_LOG,0);
        Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
        if PasScr[i] <> nil then begin // 혹시 모르니까 한번더
          PasScr[i].m_First_Process_DONE := True;
          PasScr[i].g_bIsBcrReady := True;
        end;
        m_csBcrRead.Release;
        Exit;
      end;
    end;
//    if g_CommPLC <> nil then   begin        // GlassData MateriID 비교 하여 해당 CH 로 매칭
//      for nJigCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
//        if (pnlSerials[nJigCh].Caption <> DefCommon.MSG_SCAN_BCR) then begin
//          Continue; // Scan BCR Ready 상태가 아니면 다음 ch로
//        end;
//        if Common.SystemInfo.OCType = DefCommon.PreOCType then  begin
//          sRemoveCr := Copy(sRemoveCr,1,18);
//          sPCB_ID := Copy(g_CommPLC.GlassData[nJigCh].MateriID,1,18);
//        end;
//        sDebug := Format('<HAND-BCR> MateriID Matching sRemoveCr : %s Length : %d sPCB_ID : %s Length : %d ',[sRemoveCr,Length(sRemoveCr),sPCB_ID,Length(sPCB_ID)]);
//        Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
//
//        if Pos(sRemoveCr,sPCB_ID) > 0 then begin   // GlassData MateriID 비교 하여 해당 CH 로 매칭
//          if PasScr[nJigCh] <> nil then begin
//            sDebug := Format('<HAND-BCR> input Data MateriID  Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
//            Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
//            PasScr[nJigCh].TestInfo.SerialNo  := sRemoveCr;
//          end
//          else begin
//            sDebug := Format('<HAND-BCR> Cant not input Data Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
//            Common.MLog(nJigCh,sDebug);
//          end;
//
//          sDebug := Format('<HAND-BCR> Ui display Data MateriID Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
//          Common.MLog(nJigCh,sDebug);
//          Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
//
//          pnlSerials[nJigCh].Caption := sRemoveCr;
//          pnlSerials[nJigCh].Color := $0088AEFF;
//          pnlSerials[nJigCh].Font.Color := clBlack;
//
//          if DongaGmes <> nil then begin
//            sDebug := Format('<HAND-BCR> Send PCHK Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
//            Common.MLog(nJigCh,sDebug);
//            Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
//            DongaGmes.SendHostPchk(sRemoveCr, nJigCh);
//            pnlMESResults[nJigCh].Color      := clBtnFace;
//            pnlMESResults[nJigCh].Font.Color := clBlack;
//            pnlMESResults[nJigCh].Caption    := 'SEND PCHK';
//          end;
//          sDebug := Format('<HAND-BCR> Bcr Data flow End Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
//          Common.MLog(nJigCh,sDebug);
//          Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
//
//          bIsDone := True;
//          if (UpperCase(Common.m_sUserId) = 'PM') then begin
//            bIsDone := True;
//          end;
//
//          if bIsDone then begin
//            if PasScr[nJigCh] <> nil then begin
//              PasScr[nJigCh].m_First_Process_DONE := True;
//              PasScr[nJigCh].g_bIsBcrReady := True;
//            end;
//          end;
//          sDebug := Format('<HAND-BCR> Bcr Data input pasScr Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
//          Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
//          m_csBcrRead.Release;
//          Exit;
//        end;
//      end;
//    end;

    for nJigCh := DefCommon.CH1 to DefCommon.MAX_CH do begin

      if (pnlSerials[nJigCh].Caption <> DefCommon.MSG_SCAN_BCR) then begin
        Continue; // Scan BCR Ready 상태가 아니면 다음 ch로
      end;

      if PasScr[nJigCh] <> nil then begin
        sDebug := Format('<HAND-BCR> input Data Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
        AddLog(sDebug,nJigCh,0);
//        Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
        PasScr[nJigCh].TestInfo.SerialNo  := sRemoveCr;
      end
      else begin
        sDebug := Format('<HAND-BCR> Cant not input Data Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
        AddLog(sDebug,nJigCh,0);
//        Common.MLog(nJigCh,sDebug);
      end;

      if (g_CommPLC <> nil) and (Common.StatusInfo.AutoMode) then begin
        if Common.SystemInfo.OCType = DefCommon.PreOCType then  begin
          sRemoveCr := Copy(sRemoveCr,1,18);
          sPCB_ID := Copy(g_CommPLC.GlassData[nJigCh].MateriID,1,18);
        end;

        sDebug := Format('<HAND-BCR> MateriID Matching sRemoveCr : %s Length : %d sPCB_ID : %s Length : %d ',[sRemoveCr,Length(sRemoveCr),sPCB_ID,Length(sPCB_ID)]);
        AddLog(sDebug,nJigCh,0);
//        Common.MLog(nJigCh, sDebug);
        if Pos(sRemoveCr,sPCB_ID) = 0 then begin

        end;
      end;


      sDebug := Format('<HAND-BCR> Ui display Data Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
      AddLog(sDebug,nJigCh,0);
//      Common.MLog(nJigCh,sDebug);
//      Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);

      pnlSerials[nJigCh].Caption := sRemoveCr;
      pnlSerials[nJigCh].Color := $0088AEFF;
      pnlSerials[nJigCh].Font.Color := clBlack;

      if DongaGmes <> nil then begin
        sDebug := Format('<HAND-BCR> Send PCHK Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
        AddLog(sDebug,nJigCh,0);
//        Common.MLog(nJigCh,sDebug);
//        Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
        DongaGmes.SendHostPchk(sRemoveCr, nJigCh,'');
        pnlMESResults[nJigCh].Color      := clBtnFace;
        pnlMESResults[nJigCh].Font.Color := clBlack;
        pnlMESResults[nJigCh].Caption    := 'SEND PCHK';
      end;
      sDebug := Format('<HAND-BCR> Bcr Data flow End Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
      AddLog(sDebug,nJigCh,0);
//      Common.MLog(nJigCh,sDebug);
//      Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
      Break;
    end;
    if nJigCh = 4 then begin
      sDebug := Format('<HAND-BCR> NO have to Any Ready Ch BcrData:%s Exit',[sRemoveCr]);
//      AddLog(sDebug,DefCommon.MAX_SYSTEM_LOG,0);
      Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
      m_csBcrRead.Release;
      Exit;
    end
    else if nJigCh > 4 then begin
      m_csBcrRead.Release;
      Exit;
    end;
    bIsDone := True;
    if (UpperCase(Common.m_sUserId) = 'PM') then begin
      bIsDone := True;
    end;

    if bIsDone then begin
      if PasScr[nJigCh] <> nil then begin
        PasScr[nJigCh].m_First_Process_DONE := True;
        PasScr[nJigCh].g_bIsBcrReady := True;
      end;
    end;
    sDebug := Format('<HAND-BCR> Bcr Data input pasScr Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
//    AddLog(sDebug,DefCommon.MAX_SYSTEM_LOG,0);
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
  finally
    m_csBcrRead.Release;
  end;
end;

procedure TfrmTest4ChOC.getBcrData2(sScanData: string);
var
  nJigCh, i : Integer;
  bIsDone : Boolean;
  sDebug, sRemoveCr,sPCB_ID : string;
begin
  try
    sRemoveCr := StringReplace(sScanData,#$0a,'',[rfReplaceAll]);
    sRemoveCr := StringReplace(sRemoveCr,#$0d,'',[rfReplaceAll]);
//    AddLog('<HAND-BCR> Converting Read Data ' + sRemoveCr,DefCommon.MAX_SYSTEM_LOG,0);
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, '<HAND-BCR> Read Data ' + sScanData);
  // 중복 채널 사전 검사 해서 빼기
    for i := Defcommon.CH1 to DefCommon.MAX_CH do begin
      if pnlSerials[i].Caption = sRemoveCr then begin
        sDebug := Format('<HAND-BCR> Same Data Exsit skip(Ch:%d) data(%s)',[i + 1, sRemoveCr]);
        AddLog(sDebug,i,0);
        Exit;
      end;
    end;


    for nJigCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
      //To-do: Carrier Detect 확인 추가 필요

      if (pnlSerials[nJigCh].Caption = DefCommon.MSG_SCAN_BCR) then begin
        if PasScr[nJigCh] <> nil then begin
          sDebug := Format('<HAND-BCR> input Data Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
          AddLog(sDebug,nJigCh,0);
          PasScr[nJigCh].TestInfo.SerialNo  := sRemoveCr;
          PasScr[nJigCh].m_First_Process_DONE := True;
          PasScr[nJigCh].g_bIsBcrReady := True;

          if (g_CommPLC <> nil) and (Common.StatusInfo.AutoMode) then begin   // ECC MateriID 와 BCR data 비교 하여 다르면 NG
            if Common.SystemInfo.OCType = DefCommon.PreOCType then  begin
              sRemoveCr := Copy(sRemoveCr,1,18);
              sPCB_ID := Copy(g_CommPLC.GlassData[nJigCh].MateriID,1,18);
            end;

            sDebug := Format('<HAND-BCR> MateriID Matching sRemoveCr : %s Length : %d sPCB_ID : %s Length : %d ',[sRemoveCr,Length(sRemoveCr),sPCB_ID,Length(sPCB_ID)]);
            AddLog(sDebug,nJigCh,0);
            if Pos(sRemoveCr,sPCB_ID) = 0 then begin
              pnlSerials[nJigCh].Caption := sRemoveCr;
              pnlSerials[nJigCh].Color := clRed;
              pnlSerials[nJigCh].Font.Color := clBlack;
              sDebug := Format('<HAND-BCR> MateriID and ECRDATA DIFFERENT!! MateriID : %s BCR_Data : %s ',[sPCB_ID,sRemoveCr]);
              AddLog(sDebug,nJigCh,0);
              ShowNgMessage(Format('CH : %d MateriID(%s) and BCRData(%s) DIFFERENT!!',[nJigCh + 1,sPCB_ID,sRemoveCr]));
              Exit;
            end;
          end;

          sDebug := Format('<HAND-BCR> Ui display Data Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
          AddLog(sDebug,nJigCh,0);
//          Common.MLog(nJigCh,sDebug);
//          Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);

          pnlSerials[nJigCh].Caption := sRemoveCr;
          pnlSerials[nJigCh].Color := $0088AEFF;
          pnlSerials[nJigCh].Font.Color := clBlack;

          if DongaGmes <> nil then begin
            sDebug := Format('<HAND-BCR> Send PCHK Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
            AddLog(sDebug,nJigCh,0);
//            Common.MLog(nJigCh,sDebug);
//            Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
            if (Common.PLCInfo.InlineGIB) and (Common.SystemInfo.OCType = DefCommon.PreOCType)  then begin
              DongaGmes.SendHostLpir(sRemoveCr, nJigCh);
              pnlMESResults[nJigCh].Color      := clBtnFace;
              pnlMESResults[nJigCh].Font.Color := clBlack;
              pnlMESResults[nJigCh].Caption    := 'SEND LPIR';

              DongaGmes.SendHostIns_Pchk(sRemoveCr, nJigCh,'');
              pnlMESResults[nJigCh].Color      := clBtnFace;
              pnlMESResults[nJigCh].Font.Color := clBlack;
              pnlMESResults[nJigCh].Caption    := 'SEND INS PCHK';
            end
            else begin
              DongaGmes.SendHostPchk(sRemoveCr, nJigCh,'');
              pnlMESResults[nJigCh].Color      := clBtnFace;
              pnlMESResults[nJigCh].Font.Color := clBlack;
              pnlMESResults[nJigCh].Caption    := 'SEND PCHK';
            end;
          end;
          sDebug := Format('<HAND-BCR> Bcr Data flow End Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
          AddLog(sDebug,nJigCh,0);
//          Common.MLog(nJigCh,sDebug);
//          Common.MLog(DefCommon.MAX_SYSTEM_LOG, sDebug);
        end
        else begin
          sDebug := Format('<HAND-BCR> Cant not input Data Ch:%d BcrData:%s',[nJigCh + 1 ,sRemoveCr]);
          AddLog(sDebug,nJigCh,0);
//          Common.MLog(nJigCh,sDebug);
        end;
        break; //Exit;
      end;
    end;
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, '<HAND-BCR> Finish');
//    AddLog('<HAND-BCR> Finish',DefCommon.MAX_SYSTEM_LOG,0);
  except
    on E: Exception do begin
//      AddLog( 'getBcrData Exception: ' + E.Message,DefCommon.MAX_SYSTEM_LOG,1);
//      Common.MLog(DefCommon.MAX_SYSTEM_LOG, 'getBcrData Exception: ' + E.Message);
    end;
  end;
end;

function TfrmTest4ChOC.GetNGCode_ByErroCode(sErrorCode: string): Integer;
var
  nCount: Integer;
  i: Integer;
begin
  nCount := Length(Common.GmesInfo);
  Result:= 3181; //없을 경우 Other로 처리
  for i := 0 to Pred(nCount) do begin
    if Common.GmesInfo[i].sErrCode = sErrorCode then begin
      Result:= i;
      Break;
    end;
  end;
end;

procedure TfrmTest4ChOC.GetRgbAvgFromFile;
var
  slRgbData, slRgbFile : TStringList;
  sFileName, sData, sModelType, sDebug : String;
  i, j, nCnt, nAvrCnt, nAvrColCnt, nSumR, nSumG, nSumB : Integer;
  RgbAvgLogfile : TextFile;
begin
  Common.m_RgbAvr[self.Tag].IsReady := False;
  sModelType := Common.GetModelType(2,Common.SystemInfo.TestModel);
  sFileName := Common.Path.OtpCfg + format('JIG_%X_%s_PASS_RGB_DATA.txt',[Self.Tag + 10,sModelType]);
  m_Rgb_Avr.NgCode := 0;
  if not FileExists(sFileName) then begin
    m_Rgb_Avr.NgCode := 1;
    Exit;
  end;
  nCnt := 0;  nAvrCnt := 0; nAvrColCnt := 0;
  try
    slRgbFile := TStringList.Create;
    slRgbFile.LoadFromFile(sFileName);
    SetLength(m_RGB_Avr_Data,slRgbFile.Count); // Avr Data Count.

    for i := 0 to Pred(slRgbFile.Count) do begin
      try
        sData := slRgbFile[i];
        if Trim(sData) = '' then Continue;
        slRgbData := TStringList.Create;
        ExtractStrings([','],[],PChar(sData),slRgbData);
        // slRgbData[0] ==> 검사한 Channel 정보.
        nAvrColCnt := m_Rgb_Avr.Band * m_Rgb_Avr.GrayStep *3 + 1; // Band x Graylevel x r,g,b + channelNo.
        if slRgbData.Count < nAvrColCnt then Continue;   // 설마.... Band x Gray Step이 10보다 작은 경우는 없겠지.
        nAvrColCnt := slRgbData.Count;
        nCnt := slRgbData.Count div 3;
        SetLength(m_RGB_Avr_Data[nAvrCnt],nCnt);
        for j := 0 to pred(nCnt) do begin
          m_RGB_Avr_Data[nAvrCnt,j].R := StrToIntDef(slRgbData[j*3+1],0);
          m_RGB_Avr_Data[nAvrCnt,j].G := StrToIntDef(slRgbData[j*3+2],0);
          m_RGB_Avr_Data[nAvrCnt,j].B := StrToIntDef(slRgbData[j*3+3],0);
        end;
        Inc(nAvrCnt);
      finally
        slRgbData.Free;
      end;
    end;

  finally
    slRgbFile.Free;
  end;
  case m_Rgb_Avr.AvgType of
    DefCommon.IDX_RGB_AVR_TYPE_A : begin
      if m_Rgb_Avr.AvgRowCnt < nAvrCnt then nAvrCnt := m_Rgb_Avr.AvgRowCnt;
    end;
    DefCommon.IDX_RGB_AVR_TYPE_B : begin
      if m_Rgb_Avr.AvgRowCnt > nAvrCnt then m_Rgb_Avr.NgCode := 2;
    end;
    DefCommon.IDX_RGB_AVR_TYPE_C : begin

    end;
  end;


  if m_Rgb_Avr.AvgColCnt > nAvrColCnt then m_Rgb_Avr.NgCode := 3;
  if nCnt = 0 then m_Rgb_Avr.NgCode := 4;
  if m_Rgb_Avr.NgCode <> 0 then Exit;
  Common.m_RgbAvr[self.Tag].IsReady := True;
  SetLength(m_Rgb_Avr.AvgGamma,nCnt);
  for i := 0 to Pred(nCnt) do begin
    nSumR := 0; nSumG := 0; nSumB :=0;
    for j := 0 to Pred(nAvrCnt) do begin
      nSumR := nSumR + m_RGB_Avr_Data[j,i].R; // i, j 순서 주의 !!!
      nSumG := nSumG + m_RGB_Avr_Data[j,i].G; // i, j 순서 주의 !!!
      nSumB := nSumB + m_RGB_Avr_Data[j,i].B; // i, j 순서 주의 !!!
    end;
    m_Rgb_Avr.AvgGamma[i].R := nSumR div nAvrCnt;
    m_Rgb_Avr.AvgGamma[i].G := nSumG div nAvrCnt;
    m_Rgb_Avr.AvgGamma[i].B := nSumB div nAvrCnt;
    Common.m_RgbAvr[self.Tag].Gamma[i].R := m_Rgb_Avr.AvgGamma[i].R;
    Common.m_RgbAvr[self.Tag].Gamma[i].G := m_Rgb_Avr.AvgGamma[i].G;
    Common.m_RgbAvr[self.Tag].Gamma[i].B := m_Rgb_Avr.AvgGamma[i].B;
  end;
//  // for Debug...
//  sDebug := Format('%d',[nCnt]);
//  for i := 0 to Pred(nCnt) do begin
//    sDebug := sDebug + Format(',%d',[Common.m_RgbAvr[self.Tag].Gamma[i].R]);
//    sDebug := sDebug + Format(',%d',[Common.m_RgbAvr[self.Tag].Gamma[i].G]);
//    sDebug := sDebug + Format(',%d',[Common.m_RgbAvr[self.Tag].Gamma[i].B]);
//  end;
//  sFileName := Common.Path.OtpCfg + format('JIG_%X_%s_PASS_RGB_Avg_Log.txt',[Self.Tag + 10,sModelType]);
//  try
//    try
//      AssignFile(RgbAvgLogfile, sFileName);
//      if not FileExists(sFileName) then
//        Rewrite(RgbAvgLogfile)
//      else
//        Append(RgbAvgLogfile);
//      sDebug := FormatDateTime('(hh:mm:ss.zzz) : ', Now) + sDebug;
//      WriteLn(RgbAvgLogfile, sDebug);
//    except
//    end;
//  finally
//    CloseFile(RgbAvgLogfile);
//  end;
end;

procedure TfrmTest4ChOC.MakeOpticPassRgb(nCh: Integer);
var
  i, j : Integer;
  sData : string;
  sFileName, sModelType : String;
  slRgb                : TStringList;
begin
  // comma(,)에 주의 하자... Script에서 반드시 ,R,G,B 형태로 입력 되어야만 한다.
  sData := Format('%d',[nCh+1]);
  for i := 0 to Pred(pasScr[nCh].m_RgbAvrInfo.RgbPass.FBandCnt) do begin
    for j := 0 to Pred(pasScr[nCh].m_RgbAvrInfo.RgbPass.FGrayStep) do begin
      sData := sData + Trim(PasScr[nCh].m_RgbAvrInfo.RgbPass.Data[i,j]);
    end;
  end;

  // file로 저장 하자.
  sModelType := Common.GetModelType(2,Common.SystemInfo.TestModel);
  sFileName := Common.Path.OtpCfg + format('JIG_%X_%s_PASS_RGB_DATA.txt',[Self.Tag + 10,sModelType]);
  slRgb := TStringList.Create;
  try
    if FileExists(sFileName) then begin
      slRgb.LoadFromFile(sFileName);
    end;
    slRgb.Insert(0,sData);
    while slRgb.Count > m_Rgb_Avr.AvgRowCnt do begin
      slRgb.Delete(slRgb.Count-1);
    end;
    slRgb.SaveToFile(sFileName);
  finally
    slRgb.Free;
  end;
end;

procedure TfrmTest4ChOC.MakeUserEvent(nCh, nIdxErr: Integer; sErrMessage : string);
var
  nPgNo : integer;
begin
  nPgNo := Self.Tag*4 + nCh;
//  AddLog(Format('MakeUserEvent %d',[nPgNo]),nPgNo,0);
  common.MLog(nPgNo,Format('MakeUserEvent %d',[nPgNo]));
  PasScr[nPgNo].MakeTEndEvt(nIdxErr,sErrMessage);
end;

procedure TfrmTest4ChOC.MakeUserEvent1(nCh, nIdxErr: Integer; sErrMessage : string);
var
  nPgNo : integer;
begin
  nPgNo := self.Tag*4 + nCh;
//  AddLog(Format('MakeUserEvent %d',[nPgNo]),nPgNo,0);
  common.MLog(nPgNo,Format('MakeUserEvent %d',[nPgNo]));
  PasScr[nPgNo].MakeTEndEvt(nIdxErr,sErrMessage);
end;

procedure TfrmTest4ChOC.OnTotalTimer(Sender: TObject);
var
  nSec, nMin,nPopupMsgTime : Integer;
begin

  Inc(m_nTotalTact[DefCommon.CH1]);
  nSec := m_nTotalTact[DefCommon.CH1] mod 60;
  nMin := (m_nTotalTact[DefCommon.CH1] div 60);
//  nMin := m_nTotalTact;
  pnlNowValues[DefCommon.CH1].Caption := Format('%0.3d : %0.2d',[nMin, nSec]);
//  nPopupMsgTime := Common.SystemInfo.PopupMsgTime;
//  if (nPopupMsgTime <> 0) and (not PasScr[DefCommon.CH1].m_bIDLE) then begin
//    if (m_nTotalTact[DefCommon.CH1] = nPopupMsgTime) and (Common.SystemInfo.OCType = DefCommon.PreOCType) and (m_nUnitTact[DefCommon.CH1] = 0) then   // 30초때PopUp 창
//      ShowNgMessage(format('CH : %d been %d seconds!!',[1,nPopupMsgTime]));
//  end;
end;

procedure TfrmTest4ChOC.OnUnitTimer(Sender: TObject);
var
  nSec, nMin : Integer;
begin
  Inc(m_nUnitTact[DefCommon.CH1]);
  nSec := m_nUnitTact[DefCommon.CH1] mod 60;
  nMin := (m_nUnitTact[DefCommon.CH1] div 60);
  //  nMin := m_nTotalTact;
  pnlUnitTactVal[DefCommon.CH1].Caption := Format('%0.3d : %0.2d',[nMin, nSec]);

end;


function TfrmTest4ChOC.PGPowerReset(nCh: Integer): Integer;
var
i : Integer;
begin
  Result := 1;
  if PG[nCh] = nil  then Exit(0);
  if (Common.SystemInfo.PGResetTotalConut = 0) or (StrToInt(pnlTotalValues[nCh].Caption) = 0) then Exit(0);
  if (StrToInt(pnlTotalValues[nCh].Caption) mod Common.SystemInfo.PGResetTotalConut) = 0 then  begin
    PG[nCh].tmConnCheck.Enabled  := False;
    ControlDio.PowerResetPG_CH(nCh);
    PG[nCh].tmConnCheck.Enabled  := true;
  end;
  Result := 0;
end;

procedure TfrmTest4ChOC.PGUseStatus(nCH: Integer; bOnOff: Boolean);
begin
//  chkChannelUse[nCH].DisableAlign;
  try
    chkChannelUse[nCH].Checked := bOnOff;
    if chkChannelUse[nCH].Checked then  chkChannelUse[nCH].Font.Color := clGreen
    else                              chkChannelUse[nCH].Font.Color := clRed;
    PasScr[nCH].m_bUse := chkChannelUse[nCH].Checked;
    if PasScr[nCH].m_bUse THEN
      AddLog(Format('m_bUse - ON CH: %d' ,[nCH]),nCH)
    else AddLog(Format('m_bUse - OFF CH: %d' ,[nCH]),nCH);

    Common.StatusInfo.UseChannel[nCH]:= chkChannelUse[nCH].Checked;
  finally
//    chkChannelUse[nCH].EnableAlign;
  end;
end;

procedure TfrmTest4ChOC.pnlSerials1DblClick(Sender: TObject);
var
nCH : Integer;
begin
  nCH := (Sender as TPanel).Tag;
  if pnlSerials[nCh].Caption = DefCommon.MSG_SCAN_BCR then Exit;

  if MessageDlg(#13#10 + format('Are you sure you want to clear the following [%s] serial numbers?',[pnlSerials[nCH].Caption]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    pnlSerials[nCh].Caption := DefCommon.MSG_SCAN_BCR;
    pnlSerials[nCh].Color := clBlue;
    pnlSerials[nCh].Font.Color := clYellow;
  end;
end;



procedure TfrmTest4ChOC.OnTotal2Timer(Sender: TObject);
var
  nSec, nMin,nPopupMsgTime : Integer;
begin
  Inc(m_nTotalTact[DefCommon.CH2]);
  nSec := m_nTotalTact[DefCommon.CH2] mod 60;
  nMin := (m_nTotalTact[DefCommon.CH2] div 60);
//  nMin := m_nTotalTact;
  pnlNowValues[DefCommon.CH2].Caption := Format('%0.3d : %0.2d',[nMin, nSec]);

//  nPopupMsgTime := Common.SystemInfo.PopupMsgTime;
//  if (nPopupMsgTime <> 0) and (not PasScr[DefCommon.CH2].m_bIDLE) then begin
//    if (m_nTotalTact[DefCommon.CH2] = nPopupMsgTime) and (Common.SystemInfo.OCType = DefCommon.PreOCType) and (m_nUnitTact[DefCommon.CH2] = 0)  then   // 30초때PopUp 창
//      ShowNgMessage(format('CH : %d been %d seconds!!',[2,nPopupMsgTime]));
//  end;
end;

procedure TfrmTest4ChOC.OnTotal3Timer(Sender: TObject);
var
  nSec, nMin,nPopupMsgTime : Integer;
begin
  Inc(m_nTotalTact[DefCommon.CH3]);
  nSec := m_nTotalTact[DefCommon.CH3] mod 60;
  nMin := (m_nTotalTact[DefCommon.CH3] div 60);
//  nMin := m_nTotalTact;
  pnlNowValues[DefCommon.CH3].Caption := Format('%0.3d : %0.2d',[nMin, nSec]);
//  nPopupMsgTime := Common.SystemInfo.PopupMsgTime;
//  if (nPopupMsgTime <> 0) and (not PasScr[DefCommon.CH3].m_bIDLE) then begin
//    if (m_nTotalTact[DefCommon.CH3] = nPopupMsgTime) and (Common.SystemInfo.OCType = DefCommon.PreOCType) and (m_nUnitTact[DefCommon.CH3] = 0)  then   // 30초때PopUp 창
//      ShowNgMessage(format('CH : %d been %d seconds!!',[3,nPopupMsgTime]));
//  end;
end;

procedure TfrmTest4ChOC.OnTotal4Timer(Sender: TObject);
var
  nSec, nMin,nPopupMsgTime : Integer;
begin
  Inc(m_nTotalTact[DefCommon.CH4]);
  nSec := m_nTotalTact[DefCommon.CH4] mod 60;
  nMin := (m_nTotalTact[DefCommon.CH4] div 60);
//  nMin := m_nTotalTact;
  pnlNowValues[DefCommon.CH4].Caption := Format('%0.3d : %0.2d',[nMin, nSec]);
//  nPopupMsgTime := Common.SystemInfo.PopupMsgTime;
//  if (nPopupMsgTime <> 0) and (not PasScr[DefCommon.CH4].m_bIDLE) then begin
//    if (m_nTotalTact[DefCommon.CH4] = nPopupMsgTime) and (Common.SystemInfo.OCType = DefCommon.PreOCType) and (m_nUnitTact[DefCommon.CH4] = 0)  then   // 30초때PopUp 창
//      ShowNgMessage(format('CH : %d been %d seconds!!',[4,nPopupMsgTime]));
//  end;
end;

procedure TfrmTest4ChOC.OnUnit2Timer(Sender: TObject);
var
  nSec, nMin : Integer;
begin
  Inc(m_nUnitTact[DefCommon.CH2]);

  nSec := m_nUnitTact[DefCommon.CH2] mod 60;
  nMin := (m_nUnitTact[DefCommon.CH2] div 60) mod 60;
  pnlUnitTactVal[DefCommon.CH2].Caption := Format('%0.2d : %0.2d',[nMin, nSec]);
end;

procedure TfrmTest4ChOC.OnUnit3Timer(Sender: TObject);
var
  nSec, nMin : Integer;
begin
  Inc(m_nUnitTact[DefCommon.CH3]);

  nSec := m_nUnitTact[DefCommon.CH3] mod 60;
  nMin := (m_nUnitTact[DefCommon.CH3] div 60) mod 60;
  pnlUnitTactVal[DefCommon.CH3].Caption := Format('%0.2d : %0.2d',[nMin, nSec]);
end;

procedure TfrmTest4ChOC.OnUnit4Timer(Sender: TObject);
var
  nSec, nMin : Integer;
begin
  Inc(m_nUnitTact[DefCommon.CH4]);

  nSec := m_nUnitTact[DefCommon.CH4] mod 60;
  nMin := (m_nUnitTact[DefCommon.CH4] div 60) mod 60;
  pnlUnitTactVal[DefCommon.CH4].Caption := Format('%0.2d : %0.2d',[nMin, nSec]);
end;


function TfrmTest4ChOC.StartScript(nCH,nSeq: Integer): Boolean;
var
   i : Integer;
  sLog : string;
  bFirst_Process : Boolean;
begin
  // Script가 돌고 있으면 시작 하지 말자.
  if PasScr[nCh].ScriptRunning(nSeq) then begin
    Exit(False);
  end;

  PasScr[nCH].TestInfo.NgCode := 0;
  PasScr[nCH].RunSeq(nSeq);
  PasScr[nCH].m_bIsProbeBackSig := False;

  Result := True;
end;

function TfrmTest4ChOC.EndtScript(nCH,nSeq: Integer): Boolean;
var
   i : Integer;
  sLog : string;
  bFirst_Process : Boolean;
begin
  // Script가 돌고 있으면 시작 하지 말자.
  if PasScr[nCh].ScriptRunning(nSeq) then begin
    Exit(False);
  end;
  PasScr[nCH].RunSeq(nSeq);
  PasScr[nCH].m_bIsProbeBackSig := False;

  Result := True;
end;



procedure TfrmTest4ChOC.AutoLogicStart(nCH : integer);
var
  sDebug : string;
  i: Integer;
begin
//  AddLog(Format('AutoLogicStart CH : %d',[nCH]),DefCommon.MAX_SYSTEM_LOG,0);
  Common.MLog(DefCommon.MAX_SYSTEM_LOG,Format('AutoLogicStart CH : %d',[nCH]));

  if (Common.PLCInfo.InlineGIB) then begin
    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      ClearChData(nCH);
      PasScr[nCH].TestInfo.StartTime := now;
      AddLog(Format('AutoLogicStart Process : %d',[nCH]),nCH,0);
      g_CommPLC.SaveGlassData_CH(nCh,Common.Path.Ini +Format('GlassData_CH%d.dat',[nCH+1]));
      frmTest4ChOC[0].SetIonizer(nCH div 2,True);  //// 검사 종료 시 SetIonizer ON

      ControlDio.LampOnOff(nCH div 2,false); // Added by KTS 2023-01-02 오후 5:39:50 시작 전 Lamp 제어
      CSharpDll.m_bIsProcessDone[nCH] := False;
      StartScript(nCH,DefScript.SEQ_KEY_START);
    end
    else begin
      if (nCH div 2) = 0 then begin
        PasScr[DefCommon.CH1].TestInfo.StartTime := now;
        PasScr[DefCommon.CH2].TestInfo.StartTime := now;
        ClearChData(DefCommon.CH1);
        ClearChData(DefCommon.CH2);
        g_CommPLC.SaveGlassData_CH(0,Common.Path.Ini +Format('GlassData_CH%d.dat',[1]));
        g_CommPLC.SaveGlassData_CH(1,Common.Path.Ini +Format('GlassData_CH%d.dat',[2]));
        frmTest4ChOC[0].SetIonizer(nCH div 2,True);  //// 검사 종료 시 SetIonizer ON

        ControlDio.LampOnOff(nCH div 2,false); // Added by KTS 2023-01-02 오후 5:39:50 시작 전 Lamp 제어

        CSharpDll.m_bIsProcessDone[DefCommon.CH1] := False;
        CSharpDll.m_bIsProcessDone[DefCommon.CH2] := False;
        JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_START);
      end
      else begin
        PasScr[DefCommon.CH3].TestInfo.StartTime := now;
        PasScr[DefCommon.CH4].TestInfo.StartTime := now;
        ClearChData(DefCommon.CH3);
        ClearChData(DefCommon.CH4);
        g_CommPLC.SaveGlassData_CH(2,Common.Path.Ini +Format('GlassData_CH%d.dat',[3]));
        g_CommPLC.SaveGlassData_CH(3,Common.Path.Ini +Format('GlassData_CH%d.dat',[4]));
        frmTest4ChOC[0].SetIonizer(nCH div 2,True);  //// 검사 종료 시 SetIonizer ON

        ControlDio.LampOnOff(nCH div 2,false); // Added by KTS 2023-01-02 오후 5:39:50 시작 전 Lamp 제어

        CSharpDll.m_bIsProcessDone[DefCommon.CH3] := False;
        CSharpDll.m_bIsProcessDone[DefCommon.CH4] := False;
        JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_START);
      end

    end;
  end
  else begin
    if JigLogic[self.Tag] <> nil then begin

      //채널 UI 클리어
      if nCH = DefCommon.CH_TOP then begin
        PasScr[DefCommon.CH1].TestInfo.StartTime := now;
        PasScr[DefCommon.CH2].TestInfo.StartTime := now;
        ClearChData(DefCommon.CH1);
        ClearChData(DefCommon.CH2);
      end
      else if nCH = DefCommon.CH_BOTTOM then begin
        PasScr[DefCommon.CH3].TestInfo.StartTime := now;
        PasScr[DefCommon.CH4].TestInfo.StartTime := now;
        ClearChData(DefCommon.CH3);
        ClearChData(DefCommon.CH4);
      end
      else if nCH = DefCommon.CH_ALL then begin
        for I := 0 to MAX_CH do begin
          ClearChData(i);
          PasScr[i].TestInfo.StartTime := now;
        end;
      end;


      frmTest4ChOC[0].SetIonizer(nCH,True);  //// 검사 종료 시 SetIonizer ON
      ///

      ControlDio.LampOnOff(nCH,false); // Added by KTS 2023-01-02 오후 5:39:50 시작 전 Lamp 제어
      if nCH = DefCommon.CH_TOP then begin
        CSharpDll.m_bIsProcessDone[0] := False;
        CSharpDll.m_bIsProcessDone[1] := False;
        g_CommPLC.SaveGlassData_CH(0,Common.Path.Ini +Format('GlassData_CH%d.dat',[1]));
        g_CommPLC.SaveGlassData_CH(1,Common.Path.Ini +Format('GlassData_CH%d.dat',[2]));
        JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_START);

      end
      else if nCH = DefCommon.CH_BOTTOM then  begin
        CSharpDll.m_bIsProcessDone[2] := False;
        CSharpDll.m_bIsProcessDone[3] := False;
        g_CommPLC.SaveGlassData_CH(2,Common.Path.Ini +Format('GlassData_CH%d.dat',[3]));
        g_CommPLC.SaveGlassData_CH(3,Common.Path.Ini +Format('GlassData_CH%d.dat',[4]));
        JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_START);
      end

      else begin
        for I := 0 to 3 do begin
          CSharpDll.m_bIsProcessDone[i] := False;
          g_CommPLC.SaveGlassData_CH(i,Common.Path.Ini +Format('GlassData_CH%d.dat',[i+1]));
        end;
        JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_START);
        JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_START);
      end;
    end;
  end;
end;

procedure TfrmTest4ChOC.btnAutoClick(Sender: TObject);
var
  nCH : Integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then
        JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_1)
  else  JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_1);

end;

procedure TfrmTest4ChOC.btnCh2Click(Sender: TObject);
var
  nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_8)
  else            JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_8);
end;

procedure TfrmTest4ChOC.btnCh4Click(Sender: TObject);
var
nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_7)
  else            JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_7);
end;

procedure TfrmTest4ChOC.btnChAutoStartClick(Sender: TObject);
var
  nCH : Integer;
begin
  nCH := (Sender as TButton).Tag;
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;
  SendMessageMain(STAGE_MODE_TEST_START, nCH, 0, 0, '', nil);
  frmMain_OC.Execute_AutoStart(nCH);
end;

procedure TfrmTest4ChOC.btnChStopClick(Sender: TObject);
var
  i,nCH: Integer;
begin
  nCH := (Sender as TButton).Tag;
  if Common.StatusInfo.AutoMode then begin
    Application.MessageBox('Can not Excute On Auto Mode', 'Confirm', MB_OK+MB_ICONSTOP);
    Exit;
  end;
//  tmTotalTactTime.Enabled := False;
  SendMessageMain(STAGE_MODE_TEST_STOP, nCH, 0, 0, '', nil);

  JigLogic[Self.Tag].StopIspdCh(nCH);
  pnlPGStatuses[nCH].Color := clBtnFace;
  pnlPGStatuses[nCH].Font.Color := clBlack;
  pnlPGStatuses[nCH].Font.Size := 24;
  pnlPGStatuses[nCH].Caption := 'Stop';
end;

procedure TfrmTest4ChOC.RzBitBtn2Click(Sender: TObject);
var
nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_4)
  else            JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_4);

end;

procedure TfrmTest4ChOC.RzBitBtn7Click(Sender: TObject);
var
nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_5)
  else            JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_5)
end;

procedure TfrmTest4ChOC.RzBitBtn8Click(Sender: TObject);
var
nCH : integer;
begin
  nCH := (Sender as TRzButton).Tag;

  if nCH = 0 then JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_KEY_6)
  else            JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_KEY_6);
end;

procedure TfrmTest4ChOC.SetPlcStatus(IoPlc: Integer);
var
  nCh, i: Integer;
  dwTemp : DWORD;
begin

end;

procedure TfrmTest4ChOC.SetProbeAutoControl;
begin
{$IFDEF  ADLINK_DIO}
  case Self.Tag of
    DefCommon.JIG_A : AxDio.DoneAutoControl1 := DioWorkDone;
    DefCommon.JIG_B : AxDio.DoneAutoControl2 := DioWorkDone;
  end;
{$ENDIF}
end;

procedure TfrmTest4ChOC.SetTime_StageTurn(nType: Integer; dtTime: TDateTime);
var
  i: Integer;
begin
    if nType = 0 then begin
      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        PasScr[i + Self.Tag*4].TestInfo.TurnTime_CAM:= dtTime;
      end;
    end
    else begin
      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        PasScr[i + Self.Tag*4].TestInfo.TurnTime_Unload:= dtTime;
      end;
    end;
end;

procedure TfrmTest4ChOC.ScriptLog(nCh: Integer; sDebug: string; isNg: Boolean);
begin
  try
//    mmChannelLog[nCh].DisableAlign;

    sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sDebug;
    AddLog(sDebug,nCh,TernaryOp(isNg = True,1,0));

  finally
//    mmChannelLog[nCh].EnableAlign;
  end;
end;

procedure TfrmTest4ChOC.SetBcrData;
var
I : integer;
begin
//  DongaHandBcr.OnRevBcrData := getBcrData;
  DongaHandBcr.OnRevBcrData := getBcrData2;
end;


procedure TfrmTest4ChOC.SetConfig;
var
 I : Integer;
begin
//  DisplaySeq;
 for I := DefCommon.CH1 to DefCommon.CH4 do
  DisplaySysInfo(i);
end;


procedure TfrmTest4ChOC.SetHandleAgain(hMain: HWND);
begin
  JigLogic[Self.Tag].SetHandleAgain(hMain, Self.Handle);
end;

procedure TfrmTest4ChOC.SetHostConnShow(bHostOn : Boolean);
var
  i : Integer;
begin
//  if bHostOn then begin
//    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//      pnlSerials[i].Color := $00AACCE8;
//      pnlSerials[i].Font.Color := clBlack;
//    end;
//
//  end
//  else begin
//    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//         pnlSerials[i].Color := clBlack;
//          pnlSerials[i].Font.Color := clYellow;
//      end
//      else begin
//        pnlSerials[i].Color := clBtnFace;
//         pnlSerials[i].Font.Color := clBlack;
//      end;
//      //$00FF80FF;//clBtnFace;
//    end;
//  end;


end;

procedure TfrmTest4ChOC.SetIonizer(nCH: Integer; bIsOnOff: Boolean);
begin
  if bIsOnOff then begin
    ControlDio.SetIonizer(nCH,False);
      if DaeIonizer[nCH] <> nil then
      DaeIonizer[nCH].SendRun;
  end
  else begin
    ControlDio.SetIonizer(nCH,True);
    if DaeIonizer[nCH] <> nil then
      DaeIonizer[nCH].SendStop;
  end;
end;

//procedure TfrmTest4Ch.SetLanguage(nIdx: Integer);
//var
//  i : Integer;
//begin
//  btnStartTest.Caption := 'bắt đầu (START)';
//  btnStopTest.Caption := 'Dừng lại (STOP)';
//  btnVirtualKey.Caption := 'phím ảo (Virtual Key)';
//  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//    chkChannelUse[i].Caption := Format('kênh (Channel) %d',[i+1+self.Tag*4]);//Format('Channel %d',[i+1+self.Tag*4]);
//    pnlTotalNames[i].Caption := 'Total';//'Product';
//  end;
//end;

//procedure TfrmTest4Ch.ShowAgingTime(nTime: Integer);
//var
//  nSec, nTemp, nMin, nHour : Integer;
//  sTime : string;
//begin
//  nSec  := nTime mod 60;  // 60초를 나눈 나머지가 Sec.
//  nTemp := nTime div 60;  // 60초를 나눈값 ==> Min.
//  nMin  := nTemp   mod 60;  //
//  nHour := nTemp   div 60;  //
//  sTime := Format('%0.2d : %0.2d : %0.2d',[nHour, nMin, nSec]);
//  pnlAging.Caption := sTime;
//end;

procedure TfrmTest4ChOC.ShowGui(hMain : HWND);
var
  sCh : string;
  i : Integer;
  CaSetupInfo : TCaSetupInfo;
  aTask : TThread;
  sSourceFileName,sDestinationFileName : string;
begin
  CreateGui;
  frmMain_OC.MessageHandle:= self.Handle;
  JigLogic[Self.Tag] := TJig.Create(Self.Tag,hMain,Self.Handle, self);

  LogAccumulateCount:= 30;
  LogAccumulateSecond:= 10;

  sCh := '';
  sSourceFileName := Common.Path.LGDDLL + format('LGD_OC_%s.dll',[Common.TestModelInfoFLOW.ModelTypeName]);
  sDestinationFileName := Common.Path.LGDDLL + 'LGD_OC_X2146.dll';

  if FileExists(sSourceFileName) then
    CopyFile(PChar(sSourceFileName), PChar(sDestinationFileName), True);

//  CsharpDll := TCSharpDll.Create(hMain,Self.Handle,ExtractFilePath(Application.ExeName),'OC_Converter.dll');

  CsharpDll := TCSharpDll.Create(hMain,Self.Handle,Common.Path.LGDDLL,'OC_Converter.dll');

  CsharpDll.Create_Test;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    PG[i].m_hTest := Self.Handle;
    m_bPassCH[i] := False; //CH PASS 초기화
  end;
  CsharpDll.Initialize(Common.TestModelInfoFLOW.ModelTypeName); // Added by KTS 2022-11-23 오후 1:34:17  DLL 설정
  CaSdk2 := TCA_SDK2.Create(hMain,Self.Handle, Common.TestModelInfoFLOW.Ca410MemCh+1,True);
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    CaSetupInfo.SelectIdx     := Common.SystemInfo.Com_Ca310[i];// CaSetupInfo;
    CaSetupInfo.DeviceId      := Common.SystemInfo.Com_Ca310_DevieId[i];
    CaSetupInfo.SerialNo      := Common.SystemInfo.Com_Ca310_SERIAL[i];
    CaSdk2.SetupPort[i]       := CaSetupInfo;
  end;

  CaSdk2.ManualConnect;

  CtrlCa410 := TControlCa410.Create(hMain,Self.Handle,Common.TestModelInfoFLOW.Ca410MemCh+1);

  SetConfig;
  if Common.SystemInfo.OCType = DefCommon.OCType then begin
  end
  else if Common.SystemInfo.OCType = Defcommon.PreOCType then begin
    btnCh4.Caption := '';
    btnCh2.Caption := '';
    btnCh4_2.Caption := '';
    btnCh2_2.Caption := '';
  end;
//  UpdatePtList;
end;

procedure TfrmTest4ChOC.ShowPlcNgMeg(nJigCh : Integer;sErrMsg: string);
var
  sDebug : string;
begin
  pnlPGStatuses[nJigCh].Font.Size := 24;
  pnlPGStatuses[nJigCh].Font.Name := 'Verdana';

  pnlPGStatuses[nJigCh].Caption := 'Carrier Detact NG';
  pnlPGStatuses[nJigCh].Color := clMaroon;
  pnlPGStatuses[nJigCh].Font.Color := clYellow;
  sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'Carrier Detact NG : '+ sErrMsg;
  AddLog(sDebug,nJigCh,1);
end;

procedure TfrmTest4ChOC.ShowNgMessage(sMessage: string);
begin
  if frmNgMsg = nil then begin
    frmNgMsg  := TfrmNgMsg.Create(nil);
  end;

  frmNgMsg.lblShow.Caption := sMessage;
  frmNgMsg.Show; //ShowModal;
end;

procedure TfrmTest4ChOC.StopTotalTimer(Sender: TObject; nJigCh, nTimerType : Integer);
var
  i : Integer;
  bRet : boolean;
begin
  bRet := True;

  case nTimerType of
    1 : if  PasScr[nJigCh].m_bTotalTact then     bRet := True;
    2 : if  PasScr[nJigCh].m_bUnitiTact then     bRet := True;
  end;
  if bRet then begin
    (Sender as TTimer).Enabled := False;
//    tmTotalTactTime.Enabled := False;
  end;
end;

procedure TfrmTest4ChOC.SyncJigUnload(nCh: integer);
var
  i : Integer;
  bRet : Boolean;
  sDebug : string;
  nStartCh, nEndCh : integer;
begin
  bRet := True;

  sDebug := '[Sync Run Jig]';
  if nCh in [0..1] then begin
    nStartCh := DefCommon.CH1;
    nEndCh   := Defcommon.CH2;
    sDebug := sDebug + ' A JIG ';
  end
  else if nCh in [2..3] then begin
    nStartCh := DefCommon.CH3;
    nEndCh   := Defcommon.CH4;
    sDebug := sDebug + ' B JIG ';
  end;


  for i := nStartCh to nEndCh do begin
    sDebug := sDebug + Format(', Ch%d_ScriptDone(%d)_',[Self.Tag*4 + i+1, Integer(PasScr[Self.Tag*4 + i].m_bIsScriptWork)]);
    sDebug := sDebug + Format('InsStatus(%d)_',[integer(PasScr[Self.Tag*4 + i].m_InsStatus)]);
    sDebug := sDebug + Format('SyncSeq(%d)',[integer(PasScr[Self.Tag*4 + i].m_bIsSyncSeq)]);
    if (PasScr[Self.Tag*4 + i].m_InsStatus <> TInsStatus.isRun) then Continue;
    // 한놈이라도 움직이고 있으면 빠지자...
    if PasScr[Self.Tag*4 + i].m_bIsScriptWork then begin
      bRet := False;
      Break;
    end;
  end;
  sDebug := Format('bRet(%d)',[Integer(bRet)]) + sDebug;
  Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);

  if bRet then begin
    sDebug := 'RUN : ';
    for i := nStartCh to nEndCh do begin
      if (PasScr[Self.Tag*4 + i].m_InsStatus <> TInsStatus.isRun) then Continue;
//      PasScr[Self.Tag*4 + i].RunSeq(SEQ_KEY_START);
      PasScr[Self.Tag*4 + i].RunSeq(DefScript.SEQ_UNLOAD_ZONE);
      sDebug := sDebug + Format('Ch%d Start, ',[i+1+self.Tag*4]);

    end;
    Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  end;
end;



procedure TfrmTest4ChOC.SyncProbeBack(nJigCh, nParam1, nNgCode: Integer);
var
  i, nPgNo : Integer;
  bRet : Boolean;
begin
  bRet := True;
  PasScr[Self.Tag*4 + nJigCh].m_bIsProbeBackSig := True;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    nPgNo := Self.Tag*4 + i;
    if not PasScr[nPgNo].m_bUse then Continue;
    if Pg[nPgNo].StatusPG in [pgDisconn] then Continue;

    if PasScr[nPgNo].m_bIsProbeBackSig then Continue;
    bRet := False;
  end;
end;

procedure TfrmTest4ChOC.SyncRunScrpt(nIdxKey: Integer);
var
  i : Integer;
  bRet : Boolean;
  sDebug : string;
begin
  bRet := True;

  sDebug := '[Sync Run TEST]';
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    sDebug := sDebug + Format(', Ch%d_ScriptDone(%d)_',[Self.Tag*4 + i+1, Integer(PasScr[Self.Tag*4 + i].m_bIsScriptWork)]);
    sDebug := sDebug + Format('InsStatus(%d)_',[integer(PasScr[Self.Tag*4 + i].m_InsStatus)]);
    sDebug := sDebug + Format('SyncSeq(%d)',[integer(PasScr[Self.Tag*4 + i].m_bIsSyncSeq)]);
    if (PasScr[Self.Tag*4 + i].m_InsStatus <> TInsStatus.isRun) then Continue;
    // 한놈이라도 움직이고 있으면 빠지자...
    if PasScr[Self.Tag*4 + i].m_bIsScriptWork then begin
      bRet := False;
      Break;
    end;
  end;
  sDebug := Format('bRet(%d)',[Integer(bRet)]) + sDebug;
  Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);

  if bRet then begin
    sDebug := 'RUN : ';
    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      if (PasScr[Self.Tag*4 + i].m_InsStatus <> TInsStatus.isRun) then Continue;
      PasScr[Self.Tag*4 + i].RunSeq(SEQ_KEY_START);
      sDebug := sDebug + Format('Ch%d Start, ',[i+1+self.Tag*4]);

    end;
    Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  end;
end;

procedure TfrmTest4ChOC.SendMessageMain(nMsgMode, nCh: Integer; nParam, nParam2: Integer; sMsg: String; pData:Pointer);
var
  cds         : TCopyDataStruct;
  GUIMessage : TGUIMessage;
begin
  GUIMessage.MsgType := MSG_TYPE_STAGE;
  GUIMessage.Channel := nCh;
  GUIMessage.Mode    := nMsgMode;
  GUIMessage.Param   := nParam;
  GUIMessage.Param2  := nParam2;
  GUIMessage.Msg     := sMsg;
  GUIMessage.pData   := pData;

  cds.dwData      := 0;
  cds.cbData      := SizeOf(GUIMessage);
  cds.lpData      := @GUIMessage;
  SendMessage(MessageHandle, WM_COPYDATA, 0, LongInt(@cds));
end;

procedure TfrmTest4ChOC.tmrDisplayOffTimer(Sender: TObject);
begin
  tmrDisplayOff.Enabled := False;
  pnlErrAlram.Visible := False;
end;

procedure TfrmTest4ChOC.UnloadScriptStart(nCH : Integer);
var
 nPairCh : Integer;
begin
  if (Common.PLCInfo.InlineGIB) then  begin
    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      CSharpDll.m_bIsProcessDone[nCH] := False;
      frmTest4ChOC[0].SetIonizer(nCH div 2,false);  //// 검사 종료 시 SetIonizer ON
      EndtScript(nCH,DefScript.SEQ_UNLOAD_ZONE);
    end
    else begin
      if (CSharpDll.m_bIsProcessDone[(nCH div 2)* 2]) and (CSharpDll.m_bIsProcessDone[(nCH div 2)* 2 +1]) then begin
        CSharpDll.m_bIsProcessDone[(nCH div 2)* 2] := False;
        CSharpDll.m_bIsProcessDone[(nCH div 2)* 2 + 1] := False;
        frmTest4ChOC[0].SetIonizer(nCH div 2,false);  //// 검사 종료 시 SetIonizer ON
        EndtScript((nCH div 2)* 2,DefScript.SEQ_UNLOAD_ZONE);
        EndtScript((nCH div 2)* 2 + 1,DefScript.SEQ_UNLOAD_ZONE);
      end
      else begin
        if nCH mod 2 = 1 then
          nPairCh :=  nCH - 1
        else nPairCh :=  nCH + 1;

        if (CSharpDll.m_bIsProcessDone[nCH]) and (not ControlDio.IsDetected(nPairCh)) then begin
          CSharpDll.m_bIsProcessDone[nCH] := False;
          frmTest4ChOC[0].SetIonizer(nCH div 2,false);  //// 검사 종료 시 SetIonizer ON
          EndtScript(nCH,DefScript.SEQ_UNLOAD_ZONE);
        end;
      end;
    end;
  end
  else begin
    if nCH = DefCommon.CH_TOP  then  begin
      CSharpDll.m_bIsProcessDone[0] := False;
      CSharpDll.m_bIsProcessDone[1] := False;
      frmTest4ChOC[0].SetIonizer(nCH,false);  // 검사 종료 시 SetIonizer OFF
      JigLogic[Self.Tag].StartIspd_TOP(DefScript.SEQ_UNLOAD_ZONE);
    end;
    if nCH = DefCommon.CH_BOTTOM  then begin
      CSharpDll.m_bIsProcessDone[2] := False;
      CSharpDll.m_bIsProcessDone[3] := False;
      frmTest4ChOC[0].SetIonizer(nCH,false);  // 검사 종료 시 SetIonizer OFF
      JigLogic[Self.Tag].StartIspd_BOTTOM(DefScript.SEQ_UNLOAD_ZONE);
    end;

  end;

end;

procedure TfrmTest4ChOC.UpdatePtList;
var
  nCh, i : Integer;
  PatGrp : TPatterGroup;
  nJigCnt : Integer;
begin
  PatGrp := Common.LoadPatGroup(Common.EdModelInfoFLOW.PatGrpName);
  nJigCnt :=  DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//    nCh := Self.Tag * (nJigCnt) + i;
//    PasScr[nCh].GetPatGrp := PatGrp;
    PasScr[nCh].InitialScript;
  end;
end;




procedure TfrmTest4ChOC.WMCopyData_LOGIC(var WmMsg: TMessage);
var
  nMode, nPg, nCh, nParam, nParam2, i, j, nPatType : Integer;
  sMsg, sDebug, sTemp : string;
begin
  nMode   := PGuiLog(PCopyDataStruct(WmMsg.LParam)^.lpData)^.Mode;
  nCh     := PGuiLog(PCopyDataStruct(WmMsg.LParam)^.lpData)^.Channel;
  nParam  := PGuiLog(PCopyDataStruct(WmMsg.LParam)^.lpData)^.nParam;
  sMsg    := Trim(PGuiLog(PCopyDataStruct(WmMsg.LParam)^.lpData)^.Msg);

  case nMode of

    DefCommon.MSG_MODE_WORKING : begin

      try
        sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
//        mmChannelLog[nCh].DisableAlign;

        mmChannelLog[nCh].Lines.Add(sDebug);
        CalcLogScroll(nCh, Length(sDebug));
//        mmChannelLog[nCh].EnableAlign;
        Common.MLog(nCh + self.Tag * 4, sMsg);
      except
      end;

    end;

    else begin
      Common.MLog(nCh,'<TestCh> CH'+IntToStr(nCh+1)+': TYPE_LOGIC, UnknownMODE('+IntToStr(nMode)+')');
    end;
  end;
end;

procedure TfrmTest4ChOC.WMCopyData_PG(var CopyMsg: TMessage);
var
  nType, nMode, nCh, i, nTemp, nTemp2, nPgNo, nLines: Integer;
  nParam, nPatType : Integer;
  bTemp: Boolean;
  sMsg, sDebug: string;
begin
  nCh   := PGuiPg2Test(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.PgNo;
  nTemp := PGuiPg2Test(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.Param;
  sMsg  := PGuiPg2Test(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.sMsg;

  nMode := PGuiPg2Test(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.Mode;
  case nMode of
    DefCommon.MSG_MODE_DISPLAY_VOLCUR: begin
      DisplayPwrData(nCh, PGuiPg2Test(PCopyDataStruct(CopyMsg.LParam)^.lpData)^.PwrData);
    end;
    DefCommon.MSG_MODE_DISPLAY_ALARM: begin
      pnlPGStatuses[nCh].Font.Size := 24;
      pnlPGStatuses[nCh].Color := clMaroon;
      pnlPGStatuses[nCh].Font.Name := 'Verdana';
      pnlPGStatuses[nCh].Font.Color := clYellow;
      pnlPGStatuses[nCh].Caption := 'POWER LIMIT NG';
      sDebug := FormatDateTime('[HH:MM:SS.zzz] ', now) + 'POWER LIMIT NG : ' + sMsg;
      AddLog(sDebug,nCh,1);
      SendMessageMain(STAGE_MODE_DISPLAY_ALARAM,nCh, ERR_LIST_1_POWER_LIMIT_NG +nCh, 1, sMsg,nil);

    end;
    DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
      DisplayPGStatus(nCh,nTemp,sMsg);
    end;

    DefCommon.MSG_MODE_WORKING: begin
      try
//        sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
//        mmChannelLog[nCh].DisableAlign;
        if nTemp = DefCommon.LOG_TYPE_NG then begin
          AddLog(sMsg,nCh,1);
//          mmChannelLog[nCh].EnableAlign;
          Exit;
        end;
        AddLog(sMsg,nCh,10);
//        mmChannelLog[nCh].EnableAlign;
      except
      end;
    end;
  end;
end;

function TfrmTest4ChOC.WriteR2RData(nCh : Integer): integer;
var
  cdCal : LibCa410Option.TCalValue;
  sRet,sReturn,sEods_data : string;
  saReturn : TArray<String>;
  i : Integer;
begin
  try
    Result := 1;
    if DongaGmes.R2RMachine <> Common.SystemInfo.EQPId then begin
      AddLog('EODS machine information and EQP ID different',nCh);
      Exit;
    end;
    if PasScr[nCh].FR2R_Old_MmcTxnID_Data = PasScr[nCH].FR2R_MmcTxnID_Data then begin
      AddLog('Receive the same MmcTxnID!!',nCh);
      Exit;
    end;
    for I := 0 to 23 do begin
      if PasScr[nCH].FR2R_Old_OC_Data[i] = PasScr[nCH].FR2ROC_Data[i] then begin
        AddLog('EODS SAME DATA RECEIVED!!',nCh);
        Exit;
      end;
    end;

    AddLog('CA410 CAL START',nCh);
    Common.R2RLog(nCh,'CA410 CAL START');
    cdCal.W_X := StrToFloatDef(PasScr[nCH].FR2ROC_Data[0],0);
    cdCal.W_Y := StrToFloatDef(PasScr[nCH].FR2ROC_Data[1],0);
    cdCal.W_Z := StrToFloatDef(PasScr[nCH].FR2ROC_Data[2],0);
    cdCal.W_Lv := StrToFloatDef(PasScr[nCH].FR2ROC_Data[12],0);
    cdCal.W_xx := StrToFloatDef(PasScr[nCH].FR2ROC_Data[13],0);
    cdCal.W_yy := StrToFloatDef(PasScr[nCH].FR2ROC_Data[14],0);

    cdCal.R_X := StrToFloatDef(PasScr[nCH].FR2ROC_Data[3],0);
    cdCal.R_Y := StrToFloatDef(PasScr[nCH].FR2ROC_Data[4],0);
    cdCal.R_Z := StrToFloatDef(PasScr[nCH].FR2ROC_Data[5],0);
    cdCal.R_Lv := StrToFloatDef(PasScr[nCH].FR2ROC_Data[15],0);
    cdCal.R_xx := StrToFloatDef(PasScr[nCH].FR2ROC_Data[16],0);
    cdCal.R_yy := StrToFloatDef(PasScr[nCH].FR2ROC_Data[17],0);

    cdCal.G_X := StrToFloatDef(PasScr[nCH].FR2ROC_Data[6],0);
    cdCal.G_Y := StrToFloatDef(PasScr[nCH].FR2ROC_Data[7],0);
    cdCal.G_Z := StrToFloatDef(PasScr[nCH].FR2ROC_Data[8],0);
    cdCal.G_Lv := StrToFloatDef(PasScr[nCH].FR2ROC_Data[18],0);
    cdCal.G_xx := StrToFloatDef(PasScr[nCH].FR2ROC_Data[19],0);
    cdCal.G_yy := StrToFloatDef(PasScr[nCH].FR2ROC_Data[20],0);

    cdCal.B_X := StrToFloatDef(PasScr[nCH].FR2ROC_Data[9],0);
    cdCal.B_Y := StrToFloatDef(PasScr[nCH].FR2ROC_Data[10],0);
    cdCal.B_Z := StrToFloatDef(PasScr[nCH].FR2ROC_Data[11],0);
    cdCal.B_Lv := StrToFloatDef(PasScr[nCH].FR2ROC_Data[21],0);
    cdCal.B_xx := StrToFloatDef(PasScr[nCH].FR2ROC_Data[22],0);
    cdCal.B_yy := StrToFloatDef(PasScr[nCH].FR2ROC_Data[23],0);
    CtrlCa410.CDCal := cdCal;

    sReturn := CtrlCa410.TestExample(nCh,StrToIntDef(Common.SystemInfo.CA410_MemoryCh[nCh],0),sRet); // 0 is channel num.

    saReturn:= sReturn.Split([',']);
    if Length(saReturn) > 4 then  begin
      if saReturn[5] = 'OK00' then
        Result := 0;
    end;
    if Result = 0 then begin
      sEods_data := '';
      for i := Low(PasScr[nCH].FR2ROC_Data) to High(PasScr[nCH].FR2ROC_Data) do
      begin
        PasScr[nCH].FR2R_Old_OC_Data[i] := PasScr[nCH].FR2ROC_Data[i];
        sEods_data := sEods_data + PasScr[nCH].FR2ROC_Data[i];
        if i <> High(PasScr[nCH].FR2ROC_Data) then
          sEods_data := sEods_data + ',';
      end;
      PasScr[nCH].FR2R_Old_MmcTxnID_Data := PasScr[nCH].FR2R_MmcTxnID_Data;
      AddLog(format('R2R - Save User Cal Data : CH %d',[nCh]),nCh);
      Common.SystemInfo.R2REODS_Data[nCH] := sEods_data;
      Common.SystemInfo.R2RMmcTxnID_Data[nCh] := DongaGmes.R2RMmcTxnID[nCH];
      Common.SaveSystemInfo;
      AddLog(format('SaveSystemInfo - Save Done User Cal Data : CH %d',[nCh]),nCh);
    end;

  finally
    AddLog('----------------',nCh);
    AddLog('CA410 CAL END',nCh);
    Common.R2RLog(nCh,'CA410 CAL END');
  end;

end;

function GetTimeDiffSec(StartTimne,EndTime: TDateTime): Integer;
var
  diffmsec : Integer;
begin
  diffmsec := SecondsBetween(StartTimne,EndTime);
  RESULT := diffmsec;
end;


procedure TfrmTest4ChOC.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, i, nTemp, nTemp2, nPgNo, nLines, nPair : Integer;
  bTemp : Boolean;
  sMsg, sDebug, sTemp,sVer,sSerialNumber,sEquipment,sPID : string;
  aTask : TThread;
begin
  nType := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := (PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel) mod 4;

  case nType of
    DefCommon.MSG_TYPE_LOGIC   : WMCopyData_LOGIC(Msg);
    DefCommon.MSG_TYPE_MAIN    : begin
      nMode := PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      nCh   := PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
      nTemp := PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData)^.Param;

      case nMode of
        DefCommon.MSG_MODE_ADDLOG_CHANNEL : begin
          sMsg := Trim(PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          if nTemp = 10 then begin
            Common.MLog(nCh+self.Tag*4,sMsg);
            Exit;
          end;
          if nCh < DefCommon.MAX_SYSTEM_LOG then
            AddLog('[MAIN] ' + sMsg, nCh, nTemp)
          else
            Common.MLog(nCh,sMsg);
        end;

        DefCommon.MSG_MODE_DISPLAY : begin
          sMsg := Trim(PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          DisplayResult(nCH, nTemp, 0, sMsg);
        end;
      end;

    end;
    DefCommon.MSG_TYPE_DLL : begin
      nMode := PGuiDLL(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      nCh   := PGuiDLL(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
      nTemp := PGuiDLL(PCopyDataStruct(Msg.LParam)^.lpData)^.Param;
      case nMode of
        DefCommon.MSG_MODE_LOG_REPGM : begin
          case nTemp of
            0: begin
              sSerialNumber := PasScr[nCh].TestInfo.SerialNo;
              if DongaGmes <> nil then
                sPID :=  DongaGmes.MesData[nCh].PchkRtnPID
              else sPID := 'NULL';
              Common.RePGMLog(nCh,sPID,sSerialNumber);
            end;
            1: begin
              sSerialNumber := PasScr[nCh].TestInfo.SerialNo;
              if DongaGmes <> nil then
                sPID :=  DongaGmes.MesData[nCh].PchkRtnPID
              else sPID := 'NULL';
              Common.Shutdown_FaultLog(nCh,sPID,sSerialNumber);
            end;
          end;

        end;

        DefCommon.MSG_MODE_LOG_HWCID : begin
          sSerialNumber := PasScr[nCh].TestInfo.SerialNo;
          if DongaGmes <> nil then
            sPID :=  DongaGmes.MesData[nCh].PchkRtnPID
          else sPID := 'NULL';
          sMsg := Trim(PGuiDLL(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          Common.HWCIDLogLog(nCh,sPID,sSerialNumber,sMsg);
        end;

        DefCommon.MSG_MODE_DELAY_TIME : begin
          pnlNowDelayTimes[nCh].Caption := Trim(PGuiDLL(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg)
        end;

        DefCommon.MSG_MODE_WORK_DONE : begin
          if Pg[nCh].m_bChkShutdown_Fault then begin
            sTemp := 'PXXG';
            PasScr[nCh].m_nNgCode:= GetNGCode_ByErroCode(sTemp);
            Pg[nCh].m_bChkShutdown_Fault := False;
          end
          else begin
            sTemp := CSharpDll.MainOC_GetSummaryLogData(nCh,'DEFECT_CODE');   // ERROR CODE 불러오기
          end;

          if 'XXXX' <> sTemp then
            PasScr[nCh].m_nNgCode:= GetNGCode_ByErroCode(sTemp)
          else PasScr[nCh].m_nNgCode:= 0;
          AddLog(format('GetSummaryLogData : %s GetNGCode_ByErroCode: %d',[sTemp,PasScr[nCh].m_nNgCode]),nCh);

          if DongaGmes <> nil then begin
            if DongaGmes.m_bDoneEODS[nCH] then begin   // R2R Data Down 확인 후
              DongaGmes.SendR2REoda(nCh,WriteR2RData(nCH));
            end
            else begin
              Common.MLog(nCh,'R2R m_bDoneEODS : OFF');
            end;
          end;

          pnlNowDelayTimes[nCh].Caption := '0'; // DLL Delay Time 0 표시
          PG[nCH].DP860_SendOcOnOff(0{end},2000,0); //2023-03-28 jhhwang (for T/T Test)
//          PG[nCH].SetCyclicTimer(True); //2023-03-28 jhhwang (for T/T Test)
          CSharpDll.m_bIsProcessDone[nCH] := true;    // CH 종료 확인
          PasScr[nCH].m_First_Process_DONE := false;  //Pre OC First_Process 진행 여부 확인 초기화
          AddLog(format('DLL DONE : %d, NG Code=%d', [nCH +1, PasScr[nCh].m_nNgCode]), nCH, 0);
          PasScr[nCH].TestInfo.EdUnitTact := Now;
          StopTotalTimer(tmUnitTactTime[nCh],nCh,2);
          AddLog(format('Measure Tact Time : End!!! [%ds]',[GetTimeDiffSec(PasScr[nCH].TestInfo.StUnitTact,PasScr[nCH].TestInfo.EdUnitTact)]),nCH, 0);

          ControlIRTemp(nCh,0); //IRTemp 기록 종료

          DisplayPGStatuses(nCh,PasScr[nCh].m_nNgCode); // 종료 시 바로 결과 Display

//          PGPowerReset(nCH); //종료 후 PG Reset 진행


          case nCH of
            0,1 :
            begin
              if (Common.PLCInfo.InlineGIB)  then begin
                SendMessageMain(STAGE_MODE_UNLOAD,nCH, 2,0, 'OC Flow Process_Finish',nil);
                if Common.SystemInfo.OCType = DefCommon.OCType then
                  CSharpDll.m_bIsProcessDone[nCH] := false;
              end
              else begin
                for I := DefCommon.CH1 to DefCommon.CH2 do  begin
                  if not PasScr[i].m_bUse then CSharpDll.m_bIsProcessDone[i] := true;
                end;
                if CSharpDll.m_bIsProcessDone[DefCommon.CH1] and CSharpDll.m_bIsProcessDone[DefCommon.CH2] then  begin

                  SendMessageMain(STAGE_MODE_UNLOAD,0, 2,0, 'OC Flow Process_Finish',nil);

                  CSharpDll.m_bIsProcessDone[DefCommon.CH1] := false;
                  CSharpDll.m_bIsProcessDone[DefCommon.CH2] := false;
                end;
                if COmmon.SystemInfo.OCType = DefCommon.PreOCType then begin
                  if (nCh mod 2) = 0 then begin
                    nPair:= nCh + 1;
                  end
                  else begin
                    nPair:= nCh - 1;
                  end;
                  if not PasScr[nPair].TestInfo.OCDllCall then begin
                    SendMessageMain(STAGE_MODE_UNLOAD,0, 2,0, 'OC Flow Process_Finish(2)',nil);
                    CSharpDll.m_bIsProcessDone[nCh] := false;
                    CSharpDll.m_bIsProcessDone[nPair] := false;
                  end;
                end;
              end;

            end;
            2,3 :
            begin
              if (Common.PLCInfo.InlineGIB) then begin
                SendMessageMain(STAGE_MODE_UNLOAD, nCH, 2,0, 'OC Flow Process_Finish',nil);
                if Common.SystemInfo.OCType = DefCommon.OCType then
                  CSharpDll.m_bIsProcessDone[nCH] := false;
              end
              else begin
                for I := DefCommon.CH3 to DefCommon.CH4 do  begin
                  if not PasScr[i].m_bUse then CSharpDll.m_bIsProcessDone[i] := true;
                end;
                if CSharpDll.m_bIsProcessDone[DefCommon.CH3] and CSharpDll.m_bIsProcessDone[DefCommon.CH4] then begin
                  SendMessageMain(STAGE_MODE_UNLOAD, 1, 2,0, 'OC Flow Process_Finish',nil);

                  CSharpDll.m_bIsProcessDone[DefCommon.CH3] := false;
                  CSharpDll.m_bIsProcessDone[DefCommon.CH4] := false;
                end;
                if COmmon.SystemInfo.OCType = DefCommon.PreOCType then begin
                  if (nCh mod 2) = 0 then begin
                    nPair:= nCh + 1;
                  end
                  else begin
                    nPair:= nCh - 1;
                  end;
                  if not PasScr[nPair].TestInfo.OCDllCall then begin
                    SendMessageMain(STAGE_MODE_UNLOAD,1, 2,0, 'OC Flow Process_Finish(2)',nil);
                    CSharpDll.m_bIsProcessDone[nCh] := false;
                    CSharpDll.m_bIsProcessDone[nPair] := false;
                  end;
                end;
              end;
            end;

          end;

        end;

        DefCommon.MSG_MODE_WORKING : begin
          sMsg := Trim(PGuiDLL(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          if nTemp = 10 then begin
            Common.MLog(nCh+self.Tag*4,sMsg);
            Exit;
          end;

          AddLog('[DLL] ' + sMsg, nCh, nTemp);

          if Pos('OC PGM Ver',sMsg) > 0 then begin
            sVer := Copy(sMsg,Pos('OC PGM Ver',sMsg),length(sMsg));
            SendMessageMain(MSG_TYPE_DLL, nCh, 0,0, sVer,nil);
          end;

        end;
      end;
    end;

    DefCommon.MSG_TYPE_SCRIPT : begin
      nMode := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      nCh   := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
      case nMode of
        DefCommon.MSG_MODE_CH_CLEAR : begin
          ClearChData(nCh);
        end;

        DefCommon.MSG_MODE_VIRTUAL_CAPTION : begin   //VIRTUAL Key Caption 변경
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          case nTemp of
            1 : begin
              btnAuto.Caption := sMsg;
              btnAuto_2.Caption := sMsg;
            end;
            2 : begin
              btnSWCancel1.Caption := sMsg;
              btnSWCancel1_2.Caption := sMsg;
            end;
            3 : begin
              btnRepeat.Caption := sMsg;
              btnRepeat_2.Caption := sMsg;
            end;
            4 : begin
              RzBitBtn2.Caption := sMsg;
              RzBitBtn2_2.Caption := sMsg;
            end;
            5 : begin
              RzBitBtn7.Caption := sMsg;
              RzBitBtn7_2.Caption := sMsg;
            end;
            6 : begin
              RzBitBtn8.Caption := sMsg;
              RzBitBtn8_2.Caption := sMsg;
            end;
            7 : begin
              btnCh4.Caption := sMsg;
              btnCh4_2.Caption := sMsg;
            end;
            8 : begin
              btnCh2.Caption := sMsg;
              btnCh2_2.Caption := sMsg;
            end;
            9 : begin
              btnSWNext1.Caption := sMsg;
              btnSWNext1_2.Caption := sMsg;
            end;
          end;

        end;

        DefCommon.MSG_MODE_SHOW_CONFIRM_EICR : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          Common.MLog(nCh,format('MSG_MODE_SHOW_CONFIRM_EICR : %d',[nTemp]));
          if nTemp > 0 then begin
            pnlMesConfirm[nCh].Visible := True;
            Common.MLog(nCh,format('pnlMesConfirm[%d].Visible : True',[nCh]));
          end
          else begin
            pnlMesConfirm[nCh].Visible := False;
            Common.MLog(nCh,format('pnlMesConfirm[%d].Visible : false',[nCh]));
            PasScr[nCh].HostEvntConfirm(2);
          end;
        end;

        DefCommon.MSG_MODE_IRTEMP : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          ControlIRTemp(nCh,nTemp);
        end;

        DefCommon.MSG_MODE_ANGING_TIME : begin
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          pnlAging[nCh].Caption := sMsg;
          if nTemp = 0 then begin
            pnlAging[nCh].Visible := False;
            tmAgingTimer[nCh].Enabled := False;
          end
          else              pnlAging[nCh].Visible := True;
          if nTemp = 3 then begin
            m_nDiscounter[nCh] := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam2 div 1000;
            tmAgingTimer[nCh].Enabled := True;
          end;
        end;


        DefCommon.MSG_MODE_BARCODE_READY : begin
//          DongaHandBcr.OnRevBcrData := getBcrData;
          if nTemp = 1 then begin
            pnlSerials[nCh].Caption := DefCommon.MSG_SCAN_BCR;
            pnlSerials[nCh].Color := clBlue;
            pnlSerials[nCh].Font.Color := clYellow;
          end
          else begin
            pnlSerials[nCh].Caption := '';
            if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
              pnlSerials[nCh].Color := clBlack;
              pnlSerials[nCh].Font.Color := clYellow;
            end
            else begin
              pnlSerials[nCh].Color := clBtnFace;
              pnlSerials[nCh].Font.Color := clYellow;
            end;
          end;
        end;
        DefCommon.MSG_MODE_WORKING : begin
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          if nTemp = 10 then begin
            Common.MLog(nCh+self.Tag*4,sMsg);
            Exit;
          end;

          AddLog(sMsg, nCh, nTemp);

        end;

        DefCommon.MSG_MODE_LOG_REPGM : begin
          sPID := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          sSerialNumber := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg2);

          Common.RePGMLog(nCh,sPID,sSerialNumber);

        end;
        DefCommon.MSG_MODE_TACT_START : begin
          m_nTotalTact[nCh] := 0;
          tmTotalTactTime[nCh].Enabled := True;
        end;
        DefCommon.MSG_MODE_TACT_END : begin
          StopTotalTimer(tmTotalTactTime[nCh],nCh,1);
        end;
        DefCommon.MSG_MODE_UNIT_TT_START : begin
          m_nUnitTact[nCh] := 0;
          tmUnitTactTime[nCh].Enabled := True;
        end;
        DefCommon.MSG_MODE_UNIT_TT_END : begin
          StopTotalTimer(tmUnitTactTime[nCh],nCh,2);
        end;
        DefCommon.MSG_MODE_POWER_ON : begin
//          tmTotalTactTime.Enabled := False;
        end;
        DefCommon.MSG_MODE_POWER_OFF : begin

        end;
        DefGmes.MES_PCHK : begin  //JHHWANG-GMES: 2018-06-20
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChPocb.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1)); //IMSI
          pnlMESResults[nCh].Color      := clBtnFace;
          pnlMESResults[nCh].Font.Color := clBlack;
          pnlMESResults[nCh].Caption    := 'SEND PCHK';
				end;
        DefGmes.MES_LPIR : begin
          pnlMESResults[nCh].Color      := clBtnFace;
          pnlMESResults[nCh].Font.Color := clBlack;
          pnlMESResults[nCh].Caption    := 'SEND LPIR';
		    end;
        DefGmes.MES_INS_PCHK : begin
          pnlMESResults[nCh].Color      := clBtnFace;
          pnlMESResults[nCh].Font.Color := clBlack;
          pnlMESResults[nCh].Caption    := 'SEND INS_PCHK';
        end;
        DefGmes.MES_SGEN : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND SGEN';
        end;
        DefGmes.MES_EICR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND EICR';
        end;
        DefGmes.MES_RPR_EIJR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND RPR_EIJR';
        end;
        DefGmes.MES_APDR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND MES APDR';
        end;
        DefGmes.EAS_APDR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND EAS APDR';
        end;
        DefCommon.MSG_MODE_CH_RESULT : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          case nTemp of
            -1, -3 : begin  //ShowCurStatus
              sMsg := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
              pnlPGStatuses[nCh].Caption := Trim(sMsg);
              pnlPGStatuses[nCh].Font.Size := 18;
              pnlPGStatuses[nCh].Font.Name := 'Tahoma';
              if nTemp = -3 then begin
                sDebug := Format('[ %s ]',[sMsg]);
                Common.MLog(nCh+self.Tag*4,sDebug);
              end;
              nTemp2 := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam2;
              if nTemp2 = 1 then begin
                pnlPGStatuses[nCh].Color := clLime;
                pnlPGStatuses[nCh].Font.Color := clBlack;
                pnlPGStatuses[nCh].Caption := sMsg;
              end
              else if nTemp2 = 2 then begin
                pnlPGStatuses[nCh].Color := clMaroon;
                pnlPGStatuses[nCh].Font.Color := clYellow;
                pnlPGStatuses[nCh].Caption := sMsg;
              end
              else  begin
                pnlPGStatuses[nCh].Color := clBtnFace;
                pnlPGStatuses[nCh].Font.Color := clBlack;
                pnlPGStatuses[nCh].Caption := sMsg;
              end;
              Exit;
            end;
            // Script Loading NG.
            - 2 : begin
//              pnlPGStatuses[nCh].DisableAlign;
              pnlPGStatuses[nCh].Font.Size := 24;
              pnlPGStatuses[nCh].Font.Name := 'Verdana';
//              DisplayPreviousRet(nCh);
              // NG 처리.
              pnlPGStatuses[nCh].Color := clMaroon;
              pnlPGStatuses[nCh].Font.Color := clYellow;
              pnlPGStatuses[nCh].Caption := 'Script Loading NG';

//              pnlPGStatuses[nCh].EnableAlign;
              Exit;
            end;
          end;

          DisplayPreviousRet(nCh);
//          pnlPGStatuses[nCh].DisableAlign;
          //sMsg := Format('PD %d NG',[nTemp]);
          pnlPGStatuses[nCh].Font.Size := 24;
          pnlPGStatuses[nCh].Font.Name := 'Verdana';
          // NG 처리.
          if nTemp <> 0 then  begin
            pnlPGStatuses[nCh].Color := clMaroon;
            pnlPGStatuses[nCh].Font.Color := clYellow;
            pnlPGStatuses[nCh].Caption := Format('%0.3d NG - %s',[nTemp, Common.GmesInfo[nTemp].sErrMsg]);
            pnlPGStatuses[nCh].Caption := Format('%0.3d NG',[nTemp]);
            pnlPGStatuses[nCh].Caption := Format('%0.2d NG-%s',[nTemp, PasScr[nCh + Tag*4].TestInfo.ERR_Code]);
          end
          // OK 처리.
          else begin
            pnlPGStatuses[nCh].Color := clLime;
            pnlPGStatuses[nCh].Font.Color := clBlack;
            pnlPGStatuses[nCh].Caption := 'PASS';
          end;
//          pnlPGStatuses[nCh].EnableAlign;

          modDB.UpdateNGTypeCount(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel+1, nTemp); //DB에 NG Ratio 갱신
        end;

        DefCommon.MSG_MODE_SYNC_WORK : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam; //Sync 종류
          nTemp2 := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam2; //스크립트 Zone 함수
          case nTemp of
            1 : SyncProbeBack(nCh,nTemp,nTemp2);
            2 : SyncRunScrpt(nTemp2);

            3 : begin
              //스크립트 종료 - ScriptThreadIsDone
              if Common.StatusInfo.Closing then begin
                //종료 시 무시
                Exit;
              end;
//              if Common.StatusInfo.AutoMode then begin
                case nTemp2 of

                  DefScript.SEQ_KEY_START: begin
                    Common.MLog(nCh, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_KEY_START) ' + inttostr(nCh));
                    //모든 스크립트가 종료 시 Turn 처리
                    //모든 채널이 종료 검사
//                    for i := (nCh div 2) *2 to (nCh div 2) *2 + 1 do begin
                    if PasScr[nCh].m_bIsScriptWork then begin
                      Exit;
                    end;
//                  end;
                    if  PasScr[nCh].TestInfo.NgCode <> 0 then begin
                      CSharpDll.m_bIsProcessDone[nCh] := True;
                      if (Common.PLCInfo.InlineGIB) then begin
                        if (Common.SystemInfo.OCType = DefCommon.OCType)  then begin
                          Common.MLog(nCh, '<TestForm> GIB MSG_MODE_SYNC_WORK(SEQ_KEY_START) ' + inttostr(nCh));
                          SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, nCh , nCh , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
                          CSharpDll.m_bIsProcessDone[nCH] := false;
                        end
                        else begin
                          case nCH of
                            0, 1 :
                            begin
                              if CSharpDll.m_bIsProcessDone[DefCommon.CH1] and CSharpDll.m_bIsProcessDone[DefCommon.CH2] then  begin
    //                        SendMessageMain(STAGE_MODE_UNLOAD,0, 2,0, 'OC Flow Process_Finish',nil);
//                                ControlDio.MovingAll(0,true);   // Probe and Shutter  UP
                                PG[0].SetCyclicTimer(True);
                                PG[1].SetCyclicTimer(True);
                                SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH1 , DefCommon.CH1 , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
//                                Sleep(100);
                                SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH2 , DefCommon.CH2 , nTemp2, '', nil);
                                CSharpDll.m_bIsProcessDone[DefCommon.CH1] := false;
                                CSharpDll.m_bIsProcessDone[DefCommon.CH2] := false;
                              end;
                            end;
                            2,3 :
                            begin
                              if CSharpDll.m_bIsProcessDone[DefCommon.CH3] and CSharpDll.m_bIsProcessDone[DefCommon.CH4] then begin
        //                        SendMessageMain(STAGE_MODE_UNLOAD, 1, 2,0, 'OC Flow Process_Finish',nil);
//                                ControlDio.MovingAll(1,true);   // Probe and Shutter  UP
                                PG[2].SetCyclicTimer(True);
                                PG[3].SetCyclicTimer(True);
                                SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH3 , DefCommon.CH3 , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
//                                Sleep(100);
                                SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH4 , DefCommon.CH4 , nTemp2, '', nil);
                                CSharpDll.m_bIsProcessDone[DefCommon.CH3] := false;
                                CSharpDll.m_bIsProcessDone[DefCommon.CH4] := false;
                              end;
                            end;
                          end;
                        end;
                      end
                      else begin
                        case nCH of
                          0, 1 :
                          begin
                            if CSharpDll.m_bIsProcessDone[DefCommon.CH1] and CSharpDll.m_bIsProcessDone[DefCommon.CH2] then  begin
  //                        SendMessageMain(STAGE_MODE_UNLOAD,0, 2,0, 'OC Flow Process_Finish',nil);
//                              ControlDio.MovingAll(0,true);   // Probe and Shutter  UP
                              SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, 0 , 0 , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
                              PG[0].SetCyclicTimer(True);
                              PG[1].SetCyclicTimer(True);
                              CSharpDll.m_bIsProcessDone[DefCommon.CH1] := false;
                              CSharpDll.m_bIsProcessDone[DefCommon.CH2] := false;
                            end;
                          end;
                          2,3 :
                          begin
                            if CSharpDll.m_bIsProcessDone[DefCommon.CH3] and CSharpDll.m_bIsProcessDone[DefCommon.CH4] then begin
      //                        SendMessageMain(STAGE_MODE_UNLOAD, 1, 2,0, 'OC Flow Process_Finish',nil);
//                              ControlDio.MovingAll(1,true);   // Probe and Shutter  UP
                              SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, 1 , 1 , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
                              PG[2].SetCyclicTimer(True);
                              PG[3].SetCyclicTimer(True);
                              CSharpDll.m_bIsProcessDone[DefCommon.CH3] := false;
                              CSharpDll.m_bIsProcessDone[DefCommon.CH4] := false;
                            end;

                          end;
                        end;
                      end;

                    end;
                    if  PasScr[nCh].TestInfo.NgCode = 0 then begin
                    {$IFDEF SIMULATOR}
                       PasScr[nCh].TestInfo.SerialNo := Format('TEST1234567890_%d',[nCh]);
                    {$ENDIF}
                    end;
                  end;
                  DefScript.SEQ_UNLOAD_ZONE: begin
                    CSharpDll.m_bIsProcessDone[nCh] := True;
                    Common.MLog(nCh, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) ' + inttostr(nCh),True);
                    //Exchange 요청(Unload/Load)

                    if (Common.PLCInfo.InlineGIB)  then  begin
                      if (Common.SystemInfo.OCType = DefCommon.OCType) then begin
                        if PasScr[nCh].m_bIsScriptWork then Exit;
                        SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, nCh , nCh , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
                      end
                      else begin
                        case nCH of
                          0, 1 :
                          begin
                            for i := DefCommon.CH1 to DefCommon.CH2 do begin
                              if PasScr[i].m_bIsScriptWork then begin
                                Common.MLog(nCH, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                                Exit;
                              end;
                            end;
                            PG[0].SetCyclicTimer(True);
                            PG[1].SetCyclicTimer(True);
//                            ControlDio.MovingAll(0,true);   // Probe and Shutter  UP
                            if ControlDio.IsDetected(0) then begin
                              SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH1 , DefCommon.CH1 , nTemp2, '', nil);
                              CSharpDll.m_bIsProcessDone[DefCommon.CH1] := false;
                            end;
                            if ControlDio.IsDetected(1) then begin
                              SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH2 , DefCommon.CH2 , nTemp2, '', nil);
                              CSharpDll.m_bIsProcessDone[DefCommon.CH2] := false;
                            end;

                          end;
                          2,3 :
                          begin
                            for i := DefCommon.CH3 to DefCommon.CH4 do begin
                              if PasScr[i].m_bIsScriptWork then begin
                                Common.MLog(nCH, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                                Exit;
                              end;
                            end;
                            PG[2].SetCyclicTimer(True);
                            PG[3].SetCyclicTimer(True);
//                            ControlDio.MovingAll(1,true);   // Probe and Shutter  UP
                            if ControlDio.IsDetected(2) then begin
                              SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH3 , DefCommon.CH3 , nTemp2, '', nil);
                              CSharpDll.m_bIsProcessDone[DefCommon.CH3] := false;
                            end;
                            if ControlDio.IsDetected(3) then begin
                              SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, DefCommon.CH4 , DefCommon.CH4 , nTemp2, '', nil);
                              CSharpDll.m_bIsProcessDone[DefCommon.CH4] := false;
                            end;

                          end;
                        end;


                      end;

                    end
                    else begin

                      case nCH of
                        0, 1 :
                        begin
                          for i := DefCommon.CH1 to DefCommon.CH2 do begin
                            if PasScr[i].m_bIsScriptWork then begin
                              Common.MLog(nCh, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                              Exit;
                            end;
                          end;
                          PG[0].SetCyclicTimer(True);
                          PG[1].SetCyclicTimer(True);
//                          if CSharpDll.m_bIsProcessDone[DefCommon.CH1] and CSharpDll.m_bIsProcessDone[DefCommon.CH2] then  begin
//                        SendMessageMain(STAGE_MODE_UNLOAD,0, 2,0, 'OC Flow Process_Finish',nil);
//                          ControlDio.MovingAll(0,true);   // Probe and Shutter  UP
                          if NOT Common.AutoReStart  then  begin
                            SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, 0 , 0 , nTemp2, '', nil);
                          end
                          else begin
                            SendMessageMain(STAGE_MODE_TEST_START, 0, 0, 0, '', nil);
                            AutoLogicStart(0);
                          end;
//                            SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, 0 , 0 , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35

                            CSharpDll.m_bIsProcessDone[DefCommon.CH1] := false;
                            CSharpDll.m_bIsProcessDone[DefCommon.CH2] := false;
//                          end;
                        end;
                        2,3 :
                        begin
                          for i := DefCommon.CH3 to DefCommon.CH4 do begin
                            if PasScr[i].m_bIsScriptWork then begin
                              Common.MLog(nCH, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                              Exit;
                            end;
                          end;
                          PG[2].SetCyclicTimer(True);
                          PG[3].SetCyclicTimer(True);
//                          if CSharpDll.m_bIsProcessDone[DefCommon.CH3] and CSharpDll.m_bIsProcessDone[DefCommon.CH4] then begin
    //                        SendMessageMain(STAGE_MODE_UNLOAD, 1, 2,0, 'OC Flow Process_Finish',nil);
//                          ControlDio.MovingAll(1,true);   // Probe and Shutter  UP
                          if NOT Common.AutoReStart  then  begin
                            SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, 1 , 1 , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
                          end
                          else begin
                            SendMessageMain(STAGE_MODE_TEST_START, 1, 0, 0, '', nil);
                            AutoLogicStart(1);
                          end;
                            CSharpDll.m_bIsProcessDone[DefCommon.CH3] := false;
                            CSharpDll.m_bIsProcessDone[DefCommon.CH4] := false;
//                          end;

                        end;
                      end;

//                      SendMessageMain(STAGE_MODE_SCRIPT_DONE_UNLOAD, nCh div 2 , nCh div 2 , nTemp2, '', nil); // Added by KTS 2023-04-03 오후 3:00:35
                    end;
                  end
                end;
              end;//if Common.StatusInfo.AutoMode then begin
            10 : begin
              case nCH of
                0, 1 :
                begin
                  for i := DefCommon.CH1 to DefCommon.CH2 do begin
                    if PasScr[i].m_bIsScriptWork then begin
                      Common.MLog(nCh, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                      Exit;
                    end;
                  end;

                  JigLogic[0].StartIspd_TOP(DefScript.SEQ_KEY_4);

                end;
                2,3 :
                begin
                  for i := DefCommon.CH3 to DefCommon.CH4 do begin
                    if PasScr[i].m_bIsScriptWork then begin
                      Common.MLog(nCh, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                      Exit;
                    end;
                  end;
                  JigLogic[0].StartIspd_BOTTOM(DefScript.SEQ_KEY_4);

                end;
              end;
            end;
            11 : begin
              case nCH of
                0, 1 :
                begin
                  for i := DefCommon.CH1 to DefCommon.CH2 do begin
                    if PasScr[i].m_bIsScriptWork then begin
                      Common.MLog(nCh, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                      Exit;
                    end;
                  end;

                  JigLogic[0].StartIspd_TOP(DefScript.SEQ_KEY_9);

                end;
                2,3 :
                begin
                  for i := DefCommon.CH3 to DefCommon.CH4 do begin
                    if PasScr[i].m_bIsScriptWork then begin
                      Common.MLog(nCh, '<TestForm> MSG_MODE_SYNC_WORK(SEQ_UNLOAD_ZONE) - m_bIsScriptWork ' + inttostr(i));
                      Exit;
                    end;
                  end;
                  JigLogic[0].StartIspd_BOTTOM(DefScript.SEQ_KEY_9);

                end;
              end;
            end;
            5 : begin // Added by sam81 2023-05-08 오전 11:14:03  PRE OC Only AJIG , BJIG
              SyncJigUnload(nCh);
            end;
          end;
        end;
        DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER : begin
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          pnlSerials[nCh].Caption := sMsg;
          AddLog('Serial NUM:'+sMsg, nCh, 0);
        end;
        DefCommon.MSG_MODE_FOR_RTY_MAKE_ALL_NG : begin
          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            PasScr[Self.Tag*4 + i].m_bIsRetryContact := True;
            //Common.MLog(Self.Tag*4+i,'Retry Contact signal On.');
          end;
        end;
        DefCommon.MSG_MODE_PRODUCT_CNT : begin
          nTemp2 := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam2;
          pnlTotalValues[nCh].Caption := Format('%d',[nTemp+nTemp2]);
          pnlOKValues[nCh].Caption := Format('%d',[nTemp]);
          pnlNGValues[nCh].Caption := Format('%d',[nTemp2]);
        end;
        DefCommon.MSG_MODE_PASS_RGB : begin
          MakeOpticPassRgb(nCh+self.Tag*4);
          GetRgbAvgFromFile;
        end;
        DefCommon.MSG_MODE_GET_AVG_RGB : begin
          if not m_bInitGetAvr then begin
            m_bInitGetAvr := True;
            m_Rgb_Avr.AvgType   := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.AvrType;
            m_Rgb_Avr.AvgRowCnt := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.AvrCnt;
            m_Rgb_Avr.Band      := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.BandCnt;
            m_Rgb_Avr.GrayStep  := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.GrayStep;
            m_Rgb_Avr.AvgColCnt := m_Rgb_Avr.Band * m_Rgb_Avr.GrayStep * 3 + 1;
            GetRgbAvgFromFile;
          end;
        end;
      end;
    end;

    DefCommon.MSG_TYPE_PG : begin
       WMCopyData_PG(Msg);   //= MSG_TYPE_AF9FPGA
    end;
    DefCommon.MSG_TYPE_JIG : begin
      nMode := PGuiJigData(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
//        DefCommon.MSG_MODE_CH_CLEAR : begin
//          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//            ClearChData(i);
//          end;
//        end;

        DefCommon.MSG_MODE_WORKING : begin
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          nTemp := (PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam);
          if nTemp = 10 then begin
            Common.MLog(nCh+self.Tag*4,sMsg);
            Exit;
          end;

          AddLog(sMsg, nCh, nTemp);

        end;

      end;
    end;

    DefCommon.MSG_TYPE_HOST : begin
      bTemp := PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.bError;
      sMsg  := PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
      nCh := PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
      if (nCh < DefCommon.CH1) or (nCh > DefCommon.CH4) then  Exit;

      case PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgMode of
        DefCommon.MSG_MODE_WORKING : begin
          Common.MLog(nCh,sMsg);
        end;
        DefGmes.MES_PCHK : begin  //JHHWANG-GMES: 2018-06-20
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChPocb.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1)); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'PCHK NG';

            PasScr[Self.Tag*4 + nCh].g_bIsBcrReady := False;

            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'PCHK OK';
            PasScr[Self.Tag*4 + nCh].g_bIsBcrReady := True;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnPID := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnPID;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkModel := DongaGMes.MesData[Self.Tag*4 + nCh].Model;

      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
				end;


        DefGmes.R2R_LOG :
        begin
          AddLog(sMsg, nCh, 0);
          Common.R2RLog(nCh,sMsg);       //R2R LOG 추가
        end;

        DefGmes.R2R_EODS : begin
          if frmMainter <> nil then
            frmMainter.GetR2RData(nCh);
				end;

        DefGmes.R2R_EODA : begin
          AddLog(format('R2R_EODA START!! DLL IsAlive : %d',[CSharpDll.MainOC_GetOCFlowIsAlive(nCh)]),nCh);
          Common.R2RLog(nCh,format('R2R_EODA START!! DLL IsAlive : %d',[CSharpDll.MainOC_GetOCFlowIsAlive(nCh)]));
          if (CSharpDll.MainOC_GetOCFlowIsAlive(nCh) = 0) or (CSharpDll.MainOC_GetOCFlowIsAlive(nCh) = 2)  then begin
            if DongaGmes <> nil then
              DongaGmes.SendR2REoda(nCh,WriteR2RData(nCh));
          end
          else begin
            AddLog('Currently measuring the corresponding CH',nCh);
            Common.R2RLog(nCh,'Currently measuring the corresponding CH');
          end;

				end;

        DefGmes.MES_LPIR : begin
          if bTemp then begin
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'LPIR NG';

            AddLog(sMsg, nCh, 1);

            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'LPIR OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_nMesLpirProcessCode := DongaGMes.MesData[Self.Tag*4 + nCh].LpirProcessCode;

    			finally
      			//TBD
    			end;
				end;
        DefGmes.MES_INS_PCHK : begin  //JHHWANG-GMES: 2018-06-20
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChPocb.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1)); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'INS_PCHK NG';

            AddLog(sMsg, nCh, 1);

            PasScr[nCh+self.Tag*4].g_bIsBcrReady := False;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'INS_PCHK OK';

            AddLog(sMsg, nCh, 0);
            PasScr[nCh+self.Tag*4].g_bIsBcrReady := True;

            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnPID := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnPID;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkModel := DongaGMes.MesData[Self.Tag*4 + nCh].Model;
      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
				end;
        DefGmes.MES_EICR : begin
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChPocb.WMCopyData: MSG_TYPE_HOST, MES_EICR'); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'EICR NG';

            AddLog(sMsg, nCh, 1);

            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'EICR OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;
    			try
            PasScr[nCh].m_sMesEicrRtnCode := DongaGMes.MesData[nCh].EicrRtnCode;
      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_EICR);
    			finally
      			//TBD
    			end;
        end;
        DefGmes.MES_RPR_EIJR : begin
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChPocb.WMCopyData: MSG_TYPE_HOST, MES_EICR'); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'RPR_EIJR NG';

            AddLog(sMsg, nCh, 1);

            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'RPR_EIJR OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;
    			try
            PasScr[nCh].m_sMesEicrRtnCode := DongaGMes.MesData[nCh].EicrRtnCode;

      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_EICR);
    			finally
      			//TBD
    			end;
        end;
        DefGmes.MES_APDR : begin  //JHHWANG-GMES: 2018-06-20
      		if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR MES NG';

            AddLog(sMsg, nCh, 1);

            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR MES OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;

      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
				end;
        DefGmes.MES_SGEN : begin
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChPocb.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1)); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'SGEN NG';

            AddLog(sMsg, nCh, 1);

            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'SGEN OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;

    			finally
      			//TBD
    			end;
				end;
        DefGmes.EAS_APDR : begin
      		if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR EAS NG';
            AddLog(sMsg, nCh, 1);
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR EAS OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;
      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
        end;
      end;
    end;
    DefCommon.MSG_TYPE_CA410 : begin
      nMode := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgMode;
      nCh := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
      nTemp := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      sMsg := Trim(PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      bTemp := PSyncCa(PCopyDataStruct(Msg.LParam)^.lpData)^.bError;

      case nMode of
        DefCommon.MSG_MODE_WORKING : begin
          if bTemp then
            AddLog(sMsg, nCh, 1)
          else AddLog(sMsg, nCh, 0);
        end;
        Defcommon.MSG_MODE_CAX10_MEM_CH_NO : begin
          if nTemp > -1 then begin
            chkChannelUse[nCh].Caption := Format('kênh (Channel) %d / CA410 Memory Channel(%d)',[nCh + 1,nTemp]);
            Common.SystemInfo.CA410_MemoryCh[nCh] := IntToStr(nTemp);
            Common.SavesystemInfoCA410Memory(nCh, Common.SystemInfo.CA410_MemoryCh[nCh]);
          end;
        end;

        DefGmes.R2R_LOG : begin
          Common.R2RLog(nCh,sMsg);       //R2R LOG 추가
        end;
      end;
    end;

    DefCommon.MSG_TYPE_COMM_ECS: begin
      nMode := PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      //nTemp := PGUIMessage(PCopyDataStruct(Msg.LParam)^.lpData)^.Param;
      nTemp := PGuiCamData(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      sMsg := Trim(PGuiCamData(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      case nMode of
        COMMPLC_MODE_LOG_ECS : begin
          AddLog(sMsg, nCh, nTemp);
        end;
        COMMPLC_MODE_SHOW_MES : begin
          if nTemp <> 0 then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := sMsg;
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := sMsg;
          end;
        end;
      end;
    end;
    DefCommon.MSG_TYPE_IONIZER : begin
      nMode := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp  := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      nCh := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
      case nMode of
        CommIonizer.MSG_TESTFORM_IONIZER_STATUS : begin
          if nTemp = 0 then begin
            if DaeIonizer[nCh].IonizerStatus = IonStop then begin
              btnSetIonizer[nCh].Caption := 'Ionizer On';
            end;
          end
          else begin
            if DaeIonizer[nCh].IonizerStatus = Ionrun then begin
              btnSetIonizer[nCh].Caption := 'Ionizer OFF';
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmTest4ChOC.aTaskThreadIsDone(Sender: TObject);
begin
  m_bTheadIsTerminated := False;
end;


end.


