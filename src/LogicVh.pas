unit LogicVh;

interface

uses
  Winapi.Windows,  System.SysUtils,  System.Classes, Vcl.Dialogs, DefCommon, Winapi.Messages, {UdpServerClient,}CommPG, DefScript,
  ScriptClass, CommonClass, DefPG, System.DateUtils, GMesCom, DefGmes, {CodeSiteLogging,} system.threading,
  atScript, Vcl.ScripterInit, atpascal,IdGlobal;


type

  TInspectionStatus = (IsStop, IsReady, IsRun);   // IsStop : Ready or Stop, IsReady : get Serial Info., IsRun : Running for inspection.


  TInspectionInfo = record
    PowerOn       : Boolean;
    IsScanned     : Boolean;
    IsReport      : Boolean;
    IsLoaded      : Boolean;
    Fail_Message  : string;
    Full_name     : string;
    KeyIn         : string;
    CarrierId     : string;
    SerialNo      : string;
    ZigId         : string;
    Result        : string;
    csvHeader     : string;
    csvData       : string;
    uniformity    : Double;
    TimeStart     : TDateTime;
    TimeEnd       : TDateTime;
  end;

  TRevNvmData = record
    Cmd   : Byte;
    Data  : array of Byte;
  end;

  PGuiData  = ^RGuiData;
  RGuiData = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    DataLen : Integer;
    Data    : array[1..Defcommon.MAX_GUI_DATA_CNT] of Integer;
    Msg     : string;
  end;

  PGuiLog = ^RGuiLog;
  RGuiLog = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    nParam  : Integer;
    Msg     : string;
  end;

  RGridDisplay = record
    Data  : Integer;
    IsNg  : Boolean;
  end;

  PDataView  = ^RDataView;
  RDataView = packed record
    MsgType     : Integer;
    Channel     : Integer;
    Option      : Integer;
    Len         : Integer;
    Start       : Boolean;
    CellMerage  : boolean;
    Result      : Boolean;
    DataType    : Integer;
    MinVal      : Integer;
    MaxVal      : Integer;
//    GridData    : array[0..DefPocb.MAX_FRAME_SIZE] of Integer;
//    IsNg        : array[0..DefPocb.MAX_FRAME_SIZE] of Boolean;
    Msg         : string;
  end;

//  RDataTransform = record
//    IsRefStart  : boolean;
//    TempData    : array[0..MAX_FRAME_SIZE] of Integer; // 임시로 데이터 저장 하기 위한 현재 Frame 버퍼.
//    PreTempData : array[0..MAX_FRAME_SIZE] of Integer; // 임시로 데이터 저장 하기 위한 이전 Frame 버퍼.
//
//    Min, Max, P2P2, Diff, Average : array[0..MAX_FRAME_SIZE] of Integer;
//    AvrJiter, SlopRow, SlopCol    : array[0..MAX_FRAME_SIZE] of Integer;
//    RawCsOpen1, RawCsOpen2, SumData   : array[0..MAX_FRAME_SIZE] of Integer;
//  end;

  TLogic = class(TObject)

  private
    FPgNo : Integer;
    FhDisplay : THandle;
    FLockThread : Boolean;
    FGuiData    : RGuiData;
//    FDataView   : RDataView;
    m_MainHandle : HWND;
    m_TestHandle : HWND;
    FbStopKeyLock : boolean;
//    //DTF ==> Data TransForm.
//    DTF : RDataTransform;
    m_nEERepeat : Integer;
    m_hCamEvnt     : HWND;
    m_nCamRet      : Integer;
    m_bCamEvnt     : Boolean;
//    m_nRevEvnt     : Integer;
    m_bLogicLock   : boolean;
    m_sConfigData  : string;
    m_nCurPat      : Integer;
    FPatGrp: TPatterGroup;

    procedure ThreadTask(task : TProc);
    procedure SendMainGuiDisplay(nGuiMode : Integer; nP1: Integer = 0; nP2: Integer = 0; nP3 : Integer = 0);
    procedure SendTestGuiDisplay(nGuiMode : Integer; sMsg : string = ''; nParam : Integer = 0);
    procedure SendDisplayGuiDisplay(nGuiMode : Integer; nParam : Integer = 0);
    procedure SetPatGrp(const Value: TPatterGroup);
//    procedure DisplayReadData(nIdx : Integer;bRet : Boolean; sMsg : string);
//    procedure makeDetailCsvData;



    // for Script.

  public
    m_Inspect   : TInspectionInfo;
    m_InsStatus : TInspectionStatus;
    m_bUse      : boolean;
    m_IsSWStart : Boolean;
    m_FlashAllData : TFlashData; //#m_FlashData (CommPG -> Logic:inspector-specific)

    constructor Create(nPgNo : Integer; hMain, hTest : HWND); virtual;
    destructor Destroy; override;
//    procedure DisplayContactPat(nIdx : Integer; sPatName : string);
//    procedure EnablePocb(bEnable : Boolean);
    procedure InitialData;

    function StartBcrScan : Boolean;
//    function FlashReadSerialNo(var sSerialNo: string): Boolean;
    function FlashRead(nStartAddr,nFlashReadSize : integer): Integer;

    procedure StopInspect;
    procedure StopPlcWork;
    procedure ReportInspection;
    procedure StopFromAlarm;
    procedure StopPowerMeasureTimer;
    procedure SendModelInfoDownLoad(hDisplayHandle : THandle;nSendDataCnt: Integer; const fileTransRec: TArray<TFileTranStr>);
    procedure GetCsvData(var sHead : string; var sData : string; nTactTime : Integer);
    procedure MakeTEndEvt(nIdxErr : Integer);

    function PgConnection : Boolean;
    property PatGrp         : TPatterGroup read FPatGrp write SetPatGrp;



    // for ISPD A.
    procedure StartSeq(nIdx : Integer);


  end;
var
  Logic : array[defCommon.CH1 .. defCommon.MAX_CH] of TLogic;

implementation

{ TLogic }
{$r+} // memory range check.
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$WARN IMPLICIT_STRING_CAST OFF}

constructor TLogic.Create(nPgNo : Integer; hMain, hTest : HWND);
begin
  m_bLogicLock := False;
  FPgNo := nPgNo;
  m_MainHandle := hMain;
  m_TestHandle := hTest;
  Pg[nPgNo].m_hTest := hTest;
  FLockThread := False;
  FbStopKeyLock := False;
  InitialData;

//  ScriptLogic := TatPascalScripter.Create(nil);

end;

destructor TLogic.Destroy;
begin
//  ScriptLogic.Free;
//  ScriptLogic := nil;

  if m_bCamEvnt then SetEvent(m_hCamEvnt);
  Sleep(10);
  inherited;
end;


procedure TLogic.GetCsvData(var sHead, sData: string;nTactTime : Integer);
var
  sTemp1, sTemp2, sTemp3 : string;
begin

  m_Inspect.TimeEnd := now;
//  // for Header.
//  sHead := format(',%s,%s',['S/W_VER', 'Script_VER']);
//  sHead := sHead+ Format('%s,%s,%s',['EQP_ID','Model_Name','Channel']);
//
//  sHead := sHead+ format(',%s,%s',['PG_FW/PG_BOOT/PG_FPGA/PWR/FW_IMG/FW_HEX','Serial_Number']);
//  sHead := sHead+ format(',%s,%s,%s,%s,%s',['Start_Date','Start_Time','End_Time','Tact_Time','Final_Pass_Failed']);
//  sHead := sHead+ format(',%s',['Failed_Message']);
//
//  // for data.
//  sTemp1 := Format('%d',[self.FPgNo+1]);
//  sData := format('%s,%s,%s',[ common.SystemInfo.Station, Common.SystemInfo.TestModel,sTemp1]);
//
//  sData := sData+ format(',%s,%s',[DefPocb.PROGRAM_VER, Script.m_sScriptVer]);
//  sData := sData+ format(',%s,%s',[sPgVer,m_Inspect.SerialNo]);
//
//  sTemp1 := FormatDateTime('YYYY/MM/DD', m_Inspect.TimeStart);
//  sData := sData+ format(',%s',[sTemp1]);
//
//  sTemp1 := FormatDateTime('hh:nn:ss', m_Inspect.TimeStart);
//  sTemp2 := FormatDateTime('hh:nn:ss', m_Inspect.TimeEnd);
//  sTemp3 := Format('%d',[SecondsBetween(m_Inspect.TimeStart,m_Inspect.TimeEnd)]);    // for tact time
//  sData := sData+ format(',%s,%s,%s,%s',[sTemp1,sTemp2,sTemp3,m_Inspect.Result]);
//  sData := sData+ format(',%s',[m_Inspect.Fail_Message]);

  // SW Version, HW VERSION.
  sHead := 'S/W_VER,Script_VER';
  sData := format('%s,%s',[common.GetVersionDate, Script.m_sScriptVer]);
  // PG version.
  sHead := sHead + ',PG F/W,PG BOOT,PG FPGA,POWER';
//  sData := sData + Format('%s',[Pg[FPgNo].m_sFwVer]);    // m_sFwVer 자체적으로 ,가 들어가기 때문에 삭제.


  // EQP ID, CH, Carrier ID, Serial Number
  sHead := sHead + ',EQP_ID,CH,Carrier_Id,SerialNumber';
  sData := sData + Format(',%s,%d,%s,%s',[common.SystemInfo.EQPId, self.FPgNo+1,m_inspect.CarrierId,m_Inspect.SerialNo]);

  //Result, Failed Message.
  sHead := sHead+ format(',%s,%s',['Final_Pass_Failed','Failed_Message']);
  if Trim(m_Inspect.Result) <> '' then begin
    sTemp1  := 'Failed';
  end
  else begin
    sTemp1  := 'Pass';
  end;
  sData := sData+ format(',%s,%s',[sTemp1,m_Inspect.Fail_Message]);

  // Tact Time.
  sHead := sHead+ ',Start_Date,Start_Time,End_Time,Tact_Time';
  sTemp1 := FormatDateTime('YYYY/MM/DD', m_Inspect.TimeStart);
  sData := sData+ format(',%s',[sTemp1]);

  sTemp1 := FormatDateTime('hh:nn:ss', m_Inspect.TimeStart);
  sTemp2 := FormatDateTime('hh:nn:ss', m_Inspect.TimeEnd);
  sTemp3 := Format('%d',[SecondsBetween(m_Inspect.TimeStart,m_Inspect.TimeEnd)]);    // for tact time
  sData := sData+ format(',%s,%s,%s',[sTemp1,sTemp2,sTemp3]);


  sHead := sHead+ ',Jig_Tact';
  sData := sData+ format(',%.1f',[nTactTime / 10]);

  //실 데이터와 구분하자.
  sHead := sHead + ',#';
  sData := sData + ',#';
  // 기타 데이터.
  sHead := sHead + m_Inspect.csvHeader;
  sData   := sData + m_Inspect.csvData;
end;

procedure TLogic.InitialData;
begin
  FillChar(m_Inspect,SizeOf(m_Inspect),0); // 초기화.
  FillChar(FGuiData,SizeOf(FGuiData),0);
  m_Inspect.csvHeader := '';
  m_Inspect.csvData   := '';
  m_Inspect.PowerOn := False;
  m_InsStatus := IsStop;
  FGuiData.Channel := self.FPgNo;
  m_nEERepeat := 0;
  m_nCamRet := -1;
  m_sConfigData := '';
  m_nCurPat  := 0;
end;


//
//procedure TLogic.makeDetailCsvData;
////const
////  MAX_PONIT_CNT = 6;
////var
////  nCamCh, i, j, nSubCnt, nWuAvrIdx : Integer;
////  dMax, dMin, dUniformity, dUniformitySum, dUniformityAvr, dUniformityValue : Double;
//begin
////  nCamCh := FPgNo mod 4;
//  // for summary csv.
////    m_Inspect.csvHeader        := ',,PreLocalCv,PostLocalCv';
////    m_Inspect.csvData          := format(',,%0.4f,%0.4f',[ CamCommTri.m_csvCamData[nCamCh].CvDataPre,CamCommTri.m_csvCamData[nCamCh].CvDataPost]);
//end;


//------------------------------------------------------------------------------
function TLogic.FlashRead(nStartAddr,nFlashReadSize : integer): Integer;
var
  sCamFlow : string;
{$IFDEF PG_DP860}
  bRtn  : Boolean;
{$ELSE}
  dwRtn : DWORD;
{$ENDIF}
begin
  Result := 1;
  //
  sCamFlow :=Format('FLASH Read nStartAddr : 0x%0.4x FlashReadSize : %d ',[nStartAddr,nFlashReadSize]);
  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sCamFlow);

	dwRtn := Pg[FPgNo].SendFlashRead(nStartAddr,nFlashReadSize, @m_FlashAllData.Data[0]);
  if dwRtn <> WAIT_OBJECT_0 then begin
		Exit;
  end;

  m_FlashAllData.StartAddr := nStartAddr;
  m_FlashAllData.Size      := nFlashReadSize;
  m_FlashAllData.bValid    := True;

  Result := 0;
end;


//function TLogic.FlashReadSerialNo(var sSerialNo: string): Boolean;
//var
// dwRtn  : DWORD;
// sMLog, sTempMLog, sTempFunc : string;
// nAddr, nLength, i : Integer;
// SerialNoInfo : TModelParamSerialNoFlash;
// SerialNoBuf: TIdBytes;
// sAnsiStr : AnsiString;
//
//
//
//function IsAsciiStr(str: AnsiString): Boolean;
// var
// c: AnsiChar;
// begin
// Result := False;
// for c in str do
// if not (InRange(Ord(c), $0020, $007f)) then Exit; //Non-ASCII
// Result := True;
// end;
//
//
//begin
//  Pg[FChNo].SetCyclicTimer(false{bEnable});
//  //
//  Result    := False;
//  sSerialNo := '';
//  //
//  try
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'FLASH SerialNo Read ------');
//    // Get Flash SerialNo Info (Addr,Length)
//    SerialNoInfo := Common.TestModelInfo[FChNo].PARAM.SerialNoFlashInfo;
//    nAddr   := SerialNoInfo.nAddr;
//    nLength := SerialNoInfo.nLength;
//    sTempFunc := Format('<FLASH> READ SerialNo: Addr(0x%x=%d) Len(%d)',[nAddr,nAddr,nLength]);
//    // Check Flash SerialNo Info (Addr,Length)
//    if (nAddr = 0) or (nLength <= 0) then begin
//         sMLog := sTempFunc + Format(': Invalid Flash Addr|Len (Check param.csv)',[nAddr,nLength]);
//      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sMLog, DefCommon.LOG_TYPE_NG);
//      Exit;
//    end;
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sMLog);
//    // Get Flash Data (Addr,Length)
//    SetLength(SerialNoBuf,nLength);
//    sTempFunc := Format('GetFlashData(Addr=%d,Len=%d): ',[nAddr,nLength]);
//    dwRtn := Pg[FChNo].SendFlashRead(nAddr,nLength, @SerialNoBuf[0]);
//    if (dwRtn <> WAIT_OBJECT_0) then begin
//      if dwRtn = WAIT_TIMEOUT then sTempMLog := 'Timeout' else sTempMLog := 'Failed';
//      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'FLASH SerialNo Read '+sTempMLog, DefCommon.LOG_TYPE_NG);
//      Exit;
//    end;
//    //
//    SetString(sAnsiStr, PAnsiChar(@SerialNoBuf[0]), nLength);
//    sAnsiStr  := StringReplace(sAnsiStr, #$FF, '', [rfReplaceAll]); //Remove FF
//    sSerialNo := string(Trim(sAnsiStr));
//    //
//    if Length(sSerialNo) <= 0 then begin
//      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'FLASH SerialNo NG (No SERIAL_NO)', DefCommon.LOG_TYPE_NG);
//        Exit;
//    end;
//    //
//    if not IsAsciiStr(sSerialNo) then begin
//      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'FLASH SerialNo NG(include Non-Ascii)', DefCommon.LOG_TYPE_NG);
//      Exit;
//    end;
//    //
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'FLASH SerialNo Read OK');
//        Result := True;
//    finally
//      Pg[FChNo].SetCyclicTimer(True{bEnable});
//  end;
//end;
procedure TLogic.MakeTEndEvt(nIdxErr : Integer);
begin
  m_nCamRet := nIdxErr;
  if m_bCamEvnt then SetEvent(m_hCamEvnt);
end;


function TLogic.PgConnection: Boolean;
begin
//  if not m_bUse then Exit(True);

  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Result := False
  else                                                    Result := True;
end;

procedure TLogic.ReportInspection;
begin
{$IFNDEF SIMULATOR_PG}
  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
{$ENDIF}
  if not m_bUse then Exit;

  if FbStopKeyLock then Exit;
  FbStopKeyLock := True;
  // 동작중이면 강제 종료 하자.
  if FLockThread then begin
    Pg[FPgNo].StatusPG := pgForceStop;
    FLockThread := False; // 강제로 Thread에 들어 가도록 Lock 풀자.
    //혹시 동작중인 Event 가 있으면 강제로 풀고.
    if Pg[FPgNo].m_bWaitEvent then  SetEvent(Pg[FPgNo].m_hEvent);
    ThreadTask(procedure var bTemp : Boolean; i     : Integer; begin
      sleep(10); // 10ms 가량 Lock을 푸는 시간을 가진 후.
      Pg[FPgNo].SendPowerOn(0);
      if m_Inspect.IsReport then begin
        SendMainGuiDisplay(defCommon.MSG_MODE_MAKE_SUMMARY_CSV);
        if DongaGmes <> nil then begin
          bTemp := True;
          for i := 0 to 2000 do begin   // 최대 20초 기다려 보자. 그래도 응답없으면 오류 처리.
            if not DongaGmes.FEiJRSend then begin
              // Thread로 동시에 보낼경우 Tib Driver가 충돌날 경우 방지.
              SendMainGuiDisplay(defCommon.MSG_MODE_SEND_GMES);
              bTemp := False;
              break;
            end;
            sleep(10);
          end;
          if bTemp then SendMainGuiDisplay(defCommon.MSG_MODE_SEND_GMES); // 20 Seconds 후에도 자리가 없으면 강제로 보내자.
        end;
      end;
//      ChangeFileToNgName(m_Inspect.TcNgCode);
      FbStopKeyLock := False;
      Pg[FPgNo].StatusPg := pgDone;
      SendMainGuiDisplay(defCommon.MSG_MODE_FLOW_STOP_REPORT);
    end);
  end
  else begin
    ThreadTask(procedure var bTemp : Boolean; i     : Integer; begin
      sleep(10); // 10ms 가량 Lock을 푸는 시간을 가진 후.
      Pg[FPgNo].SendPowerOn(0);
      if m_Inspect.IsReport then begin
        SendMainGuiDisplay(defCommon.MSG_MODE_MAKE_SUMMARY_CSV);
        if DongaGmes <> nil then begin
          bTemp := True;
          for i := 0 to 2000 do begin   // 최대 20초 기다려 보자. 그래도 응답없으면 오류 처리.
            if not DongaGmes.FEiJRSend then begin
              // Thread로 동시에 보낼경우 Tib Driver가 충돌날 경우 방지.
              SendMainGuiDisplay(defCommon.MSG_MODE_SEND_GMES);
              bTemp := False;
              break;
            end;
            sleep(10);
          end;
          if bTemp then SendMainGuiDisplay(defCommon.MSG_MODE_SEND_GMES); // 20 Seconds 후에도 자리가 없으면 강제로 보내자.
        end;
      end;
//      ChangeFileToNgName(m_Inspect.TcNgCode);
      FbStopKeyLock := False;
      Pg[FPgNo].StatusPg := pgDone;
      SendMainGuiDisplay(defCommon.MSG_MODE_FLOW_STOP_REPORT);
    end);
  end;
  m_IsSWStart := False;
end;
procedure TLogic.SendMainGuiDisplay(nGuiMode: Integer; nP1: Integer = 0; nP2: Integer = 0; nP3 : Integer = 0);
var
  ccd         : TCopyDataStruct;
begin
  FGuiData.MsgType := DefCommon.MSG_TYPE_LOGIC;
  FGuiData.Channel := self.FPgNo ;
  FGuiData.Mode    := nGuiMode;
  FGuiData.Data[1] := nP1;
  FGuiData.Data[2] := nP2;
  FGuiData.Data[3] := nP3;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(FGuiData);
  ccd.lpData      := @FGuiData;
  SendMessage(m_MainHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TLogic.SendModelInfoDownLoad(hDisplayHandle: THandle;nSendDataCnt: Integer;const fileTransRec: TArray<TFileTranStr>);
begin
//  if PG[FPgNo].StatusPg in [pgDisconn,pgWait] then Exit;
//
//  FhDisplay := hDisplayHandle;
//  ThreadTask(procedure var dwRet : DWORD;
//  begin
//    Pg[FPgNo].SendPowerOn(0);
//    SendDisplayGuiDisplay(defCommon.MSG_MODE_MODEL_DOWN_START);
//    Pg[FPgNo].m_hTrans := hDisplayHandle;
//    // mcf file.
//    dwRet := Pg[FPgNo].SendModelInfo;
//    if dwRet <> WAIT_OBJECT_0 then begin
//      SendDisplayGuiDisplay(defCommon.MSG_MODE_MODEL_DOWN_START,1);
//    end
//    else begin
//      // Initial code 1,2,3,4,5 & pattern group files.
//      Pg[FPgNo].SendTransData(nSendDataCnt,fileTransRec);
//      // pattern Group.
//      SendDisplayGuiDisplay(defCommon.MSG_MODE_MODEL_DOWN_END);
//    end;
//
//
//  end);
end;

procedure TLogic.SendTestGuiDisplay(nGuiMode: Integer; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiLog;
begin
  FillChar(GuiData,SizeOf(GuiData),#0);
  GuiData.MsgType := defCommon.MSG_TYPE_LOGIC;
  GuiData.Channel := self.FPgNo mod 4;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam := nParam;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_TestHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

//procedure TLogic.SeqBack;
//begin
//  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
//  if not m_bUse then Exit;
//
//  ThreadTask(procedure var sTemp : string; begin
//    Dec(m_nCurPat);
//    Pg[Self.FPgNo].SetPowerMeasureTimer(False);
//    sleep(10);
//    if m_nCurPat < 0 then m_nCurPat := 0;
//    Pg[FPgNo].SendDisplayPat(m_nCurPat);
//    sTemp := Format('Display Pattern %d',[m_nCurPat]) ;
//    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,sTemp);
//    SendTestGuiDisplay(DefCommon.MSG_MODE_PAT_DISPLAY,'',m_nCurPat);
//    Pg[Self.FPgNo].SetPowerMeasureTimer(True, 800);
//  end);
//end;
//
//procedure TLogic.SeqNext;
//begin
//  if Pg[FPgNo].Status in [pgForceStop, pgDisconnect] then Exit;
//  if not m_bUse then Exit;
//
//  ThreadTask(procedure var sTemp : string; begin
//    Pg[Self.FPgNo].SetPowerMeasureTimer(False);
//    sleep(10);
//    inc(m_nCurPat);
//    if (FPatGrp.PatCount) < (m_nCurPat+1) then m_nCurPat := m_nCurPat -1;
//    Pg[FPgNo].SendDisplayPat(m_nCurPat);
//    sTemp := Format('Display Pattern %d / %d',[m_nCurPat, FPatGrp.PatCount]) ;
//    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,sTemp);
//    SendTestGuiDisplay(DefCommon.MSG_MODE_PAT_DISPLAY,'',m_nCurPat);
//    Pg[Self.FPgNo].SetPowerMeasureTimer(True, 800);
//  end);
//end;

procedure TLogic.SetPatGrp(const Value: TPatterGroup);
begin
  FPatGrp := Value;
end;


procedure TLogic.SendDisplayGuiDisplay(nGuiMode: Integer; nParam : Integer = 0);
var
  ccd         : TCopyDataStruct;
begin
  FGuiData.MsgType := defCommon.MSG_TYPE_LOGIC;
  FGuiData.Channel := self.FPgNo;
  FGuiData.Mode    := nGuiMode;
  FGuiData.Data[1] := nParam;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(FGuiData);
  ccd.lpData      := @FGuiData;
  SendMessage(FhDisplay,WM_COPYDATA,0, LongInt(@ccd));
end;

//procedure TLogic.SerialLog(sData: string;bTimeStemp: Boolean);
//var
//  sFileName, sTime : string;
//  sFilePath, sWriteData : string;
//  _infile : TextFile;
//begin
////  sFilePath := Common.Path.Touch+ formatDateTime('yyyymmdd',now) + '\';
//  Common.CheckDir(sFilePath);
//  sFileName := Format('%s%s_Ch%d.txt',[sFilePath , m_Inspect.SerialNo,FPgNo+1]);
//  try
//    AssignFile(_infile, sFileName);
//    if not FileExists(sFileName) then begin
//      Rewrite(_infile);
//    end
//    else  begin
//      Append(_infile);
//    end;
//    sTime := '';
//    sWriteData := '';
//    if bTimeStemp then begin
//      sTime := FormatDateTime('hh:nn:ss', Now);
//      sWriteData := Format('[Time : %s] %s',[sTime,sData]);
//    end
//    else begin
//      sWriteData := sData;
//    end;
//    WriteLn(_infile, sWriteData);
//  finally
//    Close(_infile);
//  end;
//end;





function TLogic.StartBcrScan : Boolean;
begin
  if Pg[FPgNo].StatusPg = pgDisconn then Exit(False);

  ThreadTask(procedure begin
    InitialData; // 초기화를 하고.
    SendMainGuiDisplay(defCommon.MSG_MODE_CH_CLEAR); // Test Form Clear.
    SendMainGuiDisplay(defCommon.MSG_MODE_BARCODE_READY);
  end);

  Result := True;
end;


procedure TLogic.StartSeq(nIdx: Integer);
begin
//  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
//  if not m_bUse then Exit;
//
//  ThreadTask(procedure begin
////    ScriptLogic.ExecuteSubroutine('SEQ_SCR',Self.FPgNo);
//
//
//    // 임시... Power on. display ... .
//    Pg[FPgNo].SendPowerOn(1);
//    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,'Power On');
//
//    Pg[FPgNo].SendDisplayPat(0);
//    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,'Display Pattern 0');
//    m_nCurPat := 0;
//    SendTestGuiDisplay(DefCommon.MSG_MODE_PAT_DISPLAY,'',m_nCurPat);
//    Pg[Self.FPgNo].SetPowerMeasureTimer(True, 800);
//  end);
end;


procedure TLogic.StopFromAlarm;
begin
//  Pg[FPgNo].Status := pgForceStop;
//  FLockThread := False; // 강제로 Thread에 들어 가도록 Lock 풀자.
//  //혹시 동작중인 Event 가 있으면 강제로 풀고.
//  if Pg[FPgNo].m_bIsEvent then  SetEvent(Pg[FPgNo].m_hEvnt);
//  ThreadTask(procedure begin
//    sleep(10); // 10ms 가량 Lock을 푸는 시간을 가진 후.
//    Pg[FPgNo].SendChannelOff;
//    FbStopKeyLock := False;
//  end);
end;

procedure TLogic.StopInspect;
begin
  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
  if not m_bUse then Exit;
  StopPowerMeasureTimer;

  ThreadTask(procedure begin
    Pg[FPgNo].SendPowerOn(0);
    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,'Power Off');
    m_Inspect.PowerOn := False;
    Pg[FPgNo].StatusPg := pgDone;
  end);

end;

procedure TLogic.StopPlcWork;
begin
  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
  if not m_bUse then Exit;
//  m_InsStatus := IsStop; /// WORK DONE 바로 앞에 있어야 WORK DOWN 정상 동작 하니 주의...
//  SendMainGuiDisplay(defCommon.MSG_MODE_WORK_DONE,DefPocb.ZONE_UNLOAD);
//  SendTestGuiDisplay(defCommon.MSG_MODE_WORK_DONE,'',DefPocb.ZONE_UNLOAD);
end;

procedure TLogic.StopPowerMeasureTimer;
begin
//  Pg[Self.FPgNo].SetPowerMeasureTimer(False);
end;

// 한개 Logic에서는 한개의 Thread만 돌수 있도록 하자.
procedure TLogic.ThreadTask(task: TProc);
var
  thLogic : TThread;
begin
  if FLockThread then Exit;
  FLockThread := True;
  thLogic := TThread.CreateAnonymousThread( procedure begin
    try
      task;
    finally
      FLockThread   := False;
      m_bLogicLock  := False;
    end;
  end);
  thLogic.FreeOnTerminate := True;
  thLogic.Start;
//  aTask := TTask.Create(
//  procedure()
//  begin
//    try
//      task;
//    finally
//      FLockThread := False;
//      m_bLogicLock := False;
//    end;
//  end);
//  aTask.Start;

//
//  Parallel.Async( procedure begin
//      try
//        task;
//      finally
//        FLockThread := False;
//        m_bLogicLock := False;
//      end;
//    end,
//    Parallel.TaskConfig.OnTerminated(
//      procedure (const task: IOmniTaskControl)
//      begin
//
//      end
//    )
//  );
end;


end.
