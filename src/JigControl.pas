unit JigControl;

interface
{$I Common.inc}
uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, DefCommon,NgMsg, {CodeSiteLogging,}
  CommonClass, GMesCom, LogicVh, pasScriptClass, DefScript,Forms,CommPLC_ECS, {UdpServerClient,}CommPG,DefPG,  DefDio
{$IFDEF CA310_USE}
  , Ca310
{$ENDIF}
  ;

type

  TJigStatus     = (jsReady, jsLoadReq, jsLoadComplete, jsOutputReq);
  TJigPosition   = (jsLoadZone, jsCameraZone);
  PGuiJigData  = ^RGuiJigData;
  RGuiJigData = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    nParam  : Integer;
    nParam1 : Integer;
    nParam2 : Integer;
  end;

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

  TJig = class(TObject)

    private
      m_nCurJig : Integer;
      m_nCurChStart : Integer;
      m_hMain : HWND;
      m_hTest : HWND;
      m_nIdxPatContact : Integer;
      m_bIsCa310Working : boolean;
      m_nShotCa310Ready : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of boolean;
//      m_hHostEvnt : HWND;
//      m_bIsHostEvent : boolean;
//      procedure SetCamConnection;
//      procedure SendMainGuiDisplay(nGuiMode: Integer; nP1: Integer = 0);
//      procedure SendTestGuiDisplay(nGuiMode: Integer; nP1: Integer = 0; nP2: Integer = 0; nP3: Integer = 0);
      procedure SendMainGuiDisplay(nMsgMode, nCh, nParam, nParam2: Integer; sMsg: String; pData:Pointer=nil);
      procedure SendTestGuiDisplay(nGuiMode,nCh : Integer; sMsg: string = ''; sMsg2: string = ''; nParam: Integer = 0; nParam2 : Integer = 0);
//      procedure MakeUserEvent(nCh, nIdxErr : Integer);
//      procedure MakeUserEvent1(nCh, nIdxErr : Integer);
      function CheckPgConnect(nGroup : integer) : Boolean; // 한개라도 연결 안되면 False Return.
      function CheckScript(nGroup,nKeyIdx : Integer) : Boolean;
//      procedure SendHostResult;
//      procedure SendThreadHost;
//      function CheckHostAck(Task : TProc; nSid, nDelay, nRetry : Integer) : DWORD;
//      procedure SetMesResult(nMsgType, nPg: Integer; bError : Boolean; sErrMsg : string);
    public
      m_bKeyLock : boolean;
      m_JigStatus :      TJigStatus;
      constructor Create(nJigIdx : Integer ; hMain, hTest : HWND; AOwner : TComponent); virtual;
      destructor Destroy; override;
//      procedure StopPowerMeasure;
//      procedure TestFunc;

      function StartIspd_TOP(nSeq : Integer = 1) : Boolean;
      procedure StopIspd_TOP;
      function StartIspd_BOTTOM(nSeq : Integer = 1) : Boolean;
      procedure StopIspd_BOTTOM;
      procedure StopIspdCh(nCh : Integer);
      function IsScriptRunning : Boolean;
      // 화면 UI가 바뀌면서 Handle값이 바뀌어 재 설정.
      procedure SetHandleAgain(hMain, hTest : HWND);

  end;

var
  JigLogic : array[DefCommon.JIG_A .. DefCommon.JIG_B] of TJig;

implementation

uses

  ControlDio_OC;
{ TJig }
{$R+}

//function TJig.CheckHostAck(Task: TProc; nSid, nDelay, nRetry: Integer): DWORD;
//var
//	nRet  : DWORD;
//	i     : Integer;
//	sEvnt : WideString;
//begin
//	try
//		sEvnt := Format('SendHost%x0.4',[nSid]);
//		m_hHostEvnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
//    m_bIsHostEvent := True;     // Create Event 했는지 확인 하는 Flag.
//		for i := 1 to nRetry do begin
//			Task;
////			if Status in [pgForceStop,pgDisconnect] then Break;
////      FRxData.NgOrYes := DefPG.CMD_READY;
//			nRet := WaitForSingleObject(m_hHostEvnt,nDelay);
//      if nRet <> WAIT_TIMEOUT then begin
//        Break;
//      end;
//		end;
//	finally
//		CloseHandle(m_hHostEvnt);
//    m_bIsHostEvent := False;
//	end;
//  Result := nRet
//end;


function TJig.CheckPgConnect(nGroup : Integer) : Boolean;
var
  nCh : Integer;
  bRet : boolean;
begin
  bRet := False;
  for nCh := nGroup * 2 to nGroup * 2 + 1 do begin
    if not PasScr[nCh].m_bUse then Continue;
    if Pg[nCh].StatusPg in [pgReady] then begin
      bRet := True;
      Break;
    end;
  end;
  Result := bRet;
end;


function TJig.CheckScript(nGroup,nKeyIdx : Integer): Boolean;
var
  nCh, nChCnt : Integer;
  bRet : boolean;
begin
  bRet := False;

  for nCh := DefCommon.CH1 + nGroup * 2 to DefCommon.CH2 + nGroup * 2 do begin
    if PasScr[nCh].ScriptRunning(nKeyIdx) then begin
      bRet := True;
      Break;
    end;
  end;
  Result := bRet;
end;

constructor TJig.Create(nJigIdx: Integer; hMain, hTest : HWND; AOwner : TComponent);
var
  nCh, nChCnt : Integer;
begin
  m_bKeyLock := False;
  nChCnt        := DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
  m_nCurJig     := nJigIdx;
  m_nCurChStart :=  nJigIdx * nChCnt ;
  for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    Logic[nCh] := TLogic.Create(nCh, hMain,hTest);
    PasScr[nCh] := TScrCls.Create(nCh, hMain,hTest,AOwner);
    PasScr[nCh].LoadSource(Common.scrSequnce);;

  end;
  for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    m_nShotCa310Ready[nCh] := False;
  end;
  m_hMain := hMain;
  m_hTest := hTest;
  m_nIdxPatContact := -1;
  m_JigStatus := jsReady;

end;

destructor TJig.Destroy;
var
  nCh, nChCnt : Integer;
begin
  nChCnt        := DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
  for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//    Logic[nCh].Free;
//    Logic[nCh] := nil;

    PasScr[nCh].Free;
    PasScr[nCh] := nil;
  end;
  inherited;
end;

function TJig.IsScriptRunning: Boolean;
var
  nCh, nChCnt : Integer;
  bRet : boolean;
begin
  bRet := False;
  nChCnt        := DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
  for nCh := m_nCurChStart to Pred(m_nCurChStart + nChCnt) do begin
    if PasScr[nCh].IsScriptRun then begin
      bRet := True;
      Break;
    end;
  end;
  Result := bRet;
end;


//procedure TJig.MakeUserEvent(nCh, nIdxErr: Integer);
//var
//  nPgNo : integer;
//begin
//  nPgNo := m_nCurJig*4 + nCh;
////  CodeSite.Send(csmRed,Format('MakeUserEvent %d',[nPgNo]));
//  Logic[nPgNo].MakeTEndEvt(nIdxErr);
//end;
//
//procedure TJig.MakeUserEvent1(nCh, nIdxErr: Integer);
//var
//  nPgNo : integer;
//begin
//  nPgNo := m_nCurJig*4 + nCh;
////  CodeSite.Send(csmRed,Format('MakeUserEvent %d',[nPgNo]));
//  Logic[nPgNo].MakeTEndEvt(nIdxErr);
//end;

//procedure TJig.SendMainGuiDisplay(nGuiMode, nP1: Integer);
//var
//  ccd         : TCopyDataStruct;
//  SendData    : RGuiJigData;
//begin
//  SendData.MsgType := DefCommon.MSG_TYPE_JIG;
//  SendData.Channel := m_nCurJig;
//  SendData.Mode    := nGuiMode;
//  SendData.nParam  := nP1;
//  ccd.dwData      := 0;
//  ccd.cbData      := SizeOf(SendData);
//  ccd.lpData      := @SendData;
//  SendMessage(m_hMain,WM_COPYDATA,0, LongInt(@ccd));
//end;

//procedure TJig.SendHostResult;
//var
//  nCh, nChCnt, nChStr : Integer;
//  sSerial : string;
//begin

//  nChCnt := DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
//  nChStr := m_nCurJig * nChCnt ;
////  DongaGmes.OnResultEvt := SetMesResult;
//  for nCh := nChStr to Pred(nChStr + nChCnt) do begin
//    sSerial := Trim(Logic[nCh].m_Inspect.SerialNo);
//    if sSerial = '' then Continue;
//    if Logic[nCh].m_Inspect.Fail_Message <> '' then Continue;
//    SendTestGuiDisplay(DefCommon.MSG_MODE_HOST_RESULT,nCh,DefCommon.MSG_PARAM_RESULT_READY);
//    if CheckHostAck(procedure begin DongaGmes.SendHostEijr(sSerial,nCh); end,nCh,3000,1) <> WAIT_OBJECT_0 then begin
//      SendTestGuiDisplay(DefCommon.MSG_MODE_HOST_RESULT,nCh,DefCommon.MSG_PARAM_RESULT_NG);
//    end
//    else begin
//      SendTestGuiDisplay(DefCommon.MSG_MODE_HOST_RESULT,nCh,DefCommon.MSG_PARAM_RESULT_OK);
//    end;
////    Sleep(1000);
//  end;

//end;

procedure TJig.SendMainGuiDisplay(nMsgMode, nCh: Integer; nParam, nParam2: Integer; sMsg: String; pData:Pointer);
var
  ccd         : TCopyDataStruct;
  SendData    : TGUIMessage;
begin
  SendData.MsgType := DefCommon.MSG_TYPE_JIG;
  SendData.Channel := m_nCurJig;
  SendData.Mode    := nMsgMode;
  SendData.Param  := nParam;
  SendData.Param2 := nParam2;
  SendData.Msg     := sMsg;
  SendData.pData   := pData;

  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(SendData);
  ccd.lpData      := @SendData;
  SendMessage(m_hMain,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TJig.SendTestGuiDisplay(nGuiMode,nCh: Integer; sMsg, sMsg2: string; nParam, nParam2: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiScript;
begin
  GuiData.MsgType := defCommon.MSG_TYPE_JIG;
  GuiData.Channel := nCh;
  GuiData.Mode    := nGuiMode;
  GuiData.Msg     := sMsg;
  GuiData.Msg2    := sMsg2;
  GuiData.nParam  := nParam;
  GuiData.nParam2 := nParam2;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_hTest,WM_COPYDATA,0, LongInt(@ccd));
end;

//procedure TJig.SendTestGuiDisplay(nGuiMode, nP1, nP2, nP3: Integer);
//var
//  ccd         : TCopyDataStruct;
//  SendData    : RGuiJigData;
//begin
//  SendData.MsgType := DefCommon.MSG_TYPE_JIG;
//  SendData.Channel := m_nCurJig;
//  SendData.Mode    := nGuiMode;
//  SendData.nParam  := nP1;
//  SendData.nParam1 := nP2;
//  SendData.nParam2 := nP3;
//
//  ccd.dwData      := 0;
//  ccd.cbData      := SizeOf(SendData);
//  ccd.lpData      := @SendData;
//  SendMessage(m_hTest,WM_COPYDATA,0, LongInt(@ccd));
//end;

procedure TJig.SetHandleAgain(hMain, hTest: HWND);
var
  nCh, nChCnt : Integer;
begin

  if m_hMain <> hMain then m_hMain := hMain;
  if m_hTest <> hTest then m_hTest := hTest;

  nChCnt        := DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
  m_nCurChStart :=  m_nCurJig * nChCnt ;
  for nCh := m_nCurChStart to Pred(m_nCurChStart + nChCnt) do begin
    PasScr[nCh].SetHandleAgain(hMain,hTest);
  end;
end;

//procedure TJig.SendThreadHost;
//var
//  thHost : TThread;
//begin
//  thHost := TThread.CreateAnonymousThread(SendHostResult);
//  thHost.FreeOnTerminate := True;
//  thHost.Start;
//end;

//procedure TJig.SetMesResult(nMsgType, nPg: Integer; bError: Boolean; sErrMsg: string);
//begin
//  if m_bIsHostEvent then SetEvent(m_hHostEvnt);
//end;

//procedure TJig.SetCamConnection;
//begin
//  CamCommTri.ConnectCam(Self.m_nCurJig)
//end;


function TJig.StartIspd_TOP(nSeq : Integer) : Boolean;
var
  nCh, i : Integer;
  sLog : string;
  bFirst_Process : Boolean;
begin
{$IFNDEF SIMENV_NO_PG}
  if not CheckPgConnect(0) then Exit(False); // 하나라도 Connection 되지 않으면 시작 하지 말자.
{$ENDIF}
  // Script가 돌고 있으면 시작 하지 말자.
  if CheckScript(0,nSeq) then Exit(False);
  if Common.SystemInfo.OCType = DefCommon.PreOCType then  begin
    //두번째인지 확인 필요
    //if ... then
    bFirst_Process := True;
     if nSeq = DefScript.SEQ_KEY_9 then  begin
      for I := DefCommon.CH1 to DefCommon.CH2 do begin
        if not PasScr[i].m_First_Process_DONE then  begin
          bFirst_Process := False;
          Break;
        end;
      end;
      if bFirst_Process then begin
        if not ControlDio.CheckDIO_Start(0) then begin
          sLog := 'You must close Pinblock to Start CH 1,2';
          SendMainGuiDisplay(DefCommon.MSG_TYPE_CTL_DIO, 0, 2, 0, sLog);
  //        Application.MessageBox('You must close Pinblock to Start', 'Error', MB_OK+MB_ICONEXCLAMATION);
          Exit(False);
        end;
      end
      else begin
        if ControlDio.CheckPreOcPanelDetectJig(0) <> 0 then begin
          sLog := '1,2 Ch not have to Panel. Check Detect Sensor';
          SendMainGuiDisplay(DefCommon.MSG_TYPE_CTL_DIO, 0, 2, 0, sLog);
          Exit(False);
        end;
      end;
      if frmNgMsg <> nil then
        frmNgMsg.FormAutoClose;
      g_CommPLC.EQP_Clear_ROBOT_Request(0);
    end;
  end;
  for i := DefCommon.CH1 to DefCommon.CH2 do begin
//    if ControlDio <> nil then begin
//      if ( ControlDio.ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR+16*i)) and ControlDio.Connected then Continue;
//    end;
    //if not Pg[nCh].CheckFWVersion then Continue;
//    if pos('PASS',PasScr[i].TestInfo.Result)  > 0 then begin
    if COmmon.SystemInfo.OCType = DefCommon.PreOCType then begin
      if Common.StatusInfo.AutoMode then begin
        if PasScr[i].m_nConfirmHostRet  = 1 then begin  // Added by KTS 2023-06-13 오후 10:41:01 EICR 이후 재시작 안되게
          Continue;
        end;
      end;
    end;
    PasScr[i].TestInfo.NgCode := 0;
    PasScr[i].RunSeq(nSeq);
    PasScr[i].m_bIsProbeBackSig := False;
  end;

  Result := True;
end;

procedure TJig.StopIspd_TOP;
var
  nCh, i : Integer;
  sLog : string;
begin
  for i := DefCommon.CH1 to DefCommon.CH2 do begin
    if PasScr[i] <> nil  then begin
      PasScr[i].m_bCEL_Stop := True;
      PasScr[i].m_bIsSyncSeq := False;  // 동기화시 Stop 되지 않는 이슈 때문.
      PasScr[i].RunSeq(DefScript.SEQ_KEY_STOP);
      PasScr[i].m_nConfirmHostRet := 0;
      sLog := Format('ReStart Mode(%d) : Initialization ',[PasScr[i].m_nConfirmHostRet]);
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING, i, sLog);
    end;
  end;
end;


function TJig.StartIspd_BOTTOM(nSeq : Integer) : Boolean;
var
  nCh, i : Integer;
  sLog : string;
  bFirst_Process : Boolean;
begin
{$IFNDEF SIMENV_NO_PG}
  if not CheckPgConnect(1) then Exit(False); // 하나라도 Connection 되지 않으면 시작 하지 말자.
{$ENDIF}
  // Script가 돌고 있으면 시작 하지 말자.
  if CheckScript(1,nSeq) then Exit(False);
  if Common.SystemInfo.OCType = DefCommon.PreOCType then  begin
    //두번째인지 확인 필요
    //if ... then                                                 '
    bFirst_Process := True;
    if nSeq = DefScript.SEQ_KEY_9 then  begin
      for I := DefCommon.CH3 to DefCommon.CH4 do begin
        if not PasScr[i].m_First_Process_DONE then  begin
          bFirst_Process := False;
          Break;
        end;
      end;
      if bFirst_Process then begin
        if not ControlDio.CheckDIO_Start(1) then begin
          sLog := 'You must close Pinblock to Start CH 3,4';
          SendMainGuiDisplay(DefCommon.MSG_TYPE_CTL_DIO, 0, 2, 0, sLog);
  //        Application.MessageBox('You must close Pinblock to Start', 'Error', MB_OK+MB_ICONEXCLAMATION);
          Exit(False);
        end;
      end
      else begin
        if ControlDio.CheckPreOcPanelDetectJig(1) <> 0 then begin
          sLog := '3,4 Ch not have to Panel. Check Detect Sensor';
          SendMainGuiDisplay(DefCommon.MSG_TYPE_CTL_DIO, 0, 2, 0, sLog);
          Exit(False);
        end;
      end;
      if frmNgMsg <> nil then
        frmNgMsg.FormAutoClose;
      g_CommPLC.EQP_Clear_ROBOT_Request(1);
    end;
  end;
  for i := DefCommon.CH3 to DefCommon.Ch4 do begin
//    if ControlDio <> nil then begin
//      if ( ControlDio.ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR+16*i)) and ControlDio.Connected then Continue;
//    end;
    //if not Pg[nCh].CheckFWVersion then Continue;
    if COmmon.SystemInfo.OCType = DefCommon.PreOCType then begin
      if Common.StatusInfo.AutoMode then begin
         if PasScr[i].m_nConfirmHostRet  = 1 then begin  // Added by KTS 2023-06-13 오후 10:41:01 EICR 이후 재시작 안되게
          Continue;
        end;
      end;
    end;
    PasScr[i].TestInfo.NgCode := 0;
    PasScr[i].RunSeq(nSeq);
    PasScr[i].m_bIsProbeBackSig := False;
  end;

  Result := True;
end;

procedure TJig.StopIspdCh(nCh: Integer);
var
sLog : string;
begin
  if PasScr[nCh] <> nil  then begin
    PasScr[nCh].m_bIsSyncSeq := False;  // 동기화시 Stop 되지 않는 이슈 때문.
    PasScr[nCh].m_bCEL_Stop := True;
    PasScr[nCh].RunSeq(DefScript.SEQ_KEY_STOP);
    PasScr[nCh].m_nConfirmHostRet := 0;
    sLog := Format('ReStart Mode(%d) : Initialization ',[PasScr[nCh].m_nConfirmHostRet]);
    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING, nCh, sLog);
  end;
end;

procedure TJig.StopIspd_BOTTOM;
var
  nCh, i : Integer;
  sLog : string;
begin
  for i := DefCommon.CH3 to DefCommon.CH4 do begin
    if PasScr[i] <> nil  then begin
      PasScr[i].m_bIsSyncSeq := False;  // 동기화시 Stop 되지 않는 이슈 때문.
      PasScr[i].RunSeq(DefScript.SEQ_KEY_STOP);
      PasScr[i].m_nConfirmHostRet := 0;
      sLog := Format('ReStart Mode(%d) : Initialization ',[PasScr[i].m_nConfirmHostRet]);
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING, i, sLog);
    end;
  end;
end;

//procedure TJig.StopPowerMeasure;
//var
//  nCh, nChStr, nChCnt : Integer;
//begin
////  m_JigPos := JpNone;
//  nChCnt := DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
//  nChStr := m_nCurJig * nChCnt ;
//  for nCh := nChStr to Pred(nChStr + nChCnt) do begin
////    Logic[nCh].StopPowerMeasureTimer;
//    Pg[nCh].SetPowerMeasureTimer(False);
//  end;
//end;

//procedure TJig.TestFunc;
//begin
//  if Common.SystemInfo.UseManualSerial then SendTestGuiDisplay(DefCommon.MSG_MODE_BARCODE_READY);
//end;

end.
