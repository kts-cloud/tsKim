unit UdpServerClient;

interface
uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Dialogs,IdSocketHandle, DefPG, DefCommon, IdUDPServer,
  Vcl.ExtCtrls, Winapi.Messages, CommonClass, Winapi.WinSock,AF9_FPGA
{$IFDEF DEBUG}
  , CodeSiteLogging
{$ENDIF}
  , IdGlobal, IdUDPClient, system.threading,
  DongaPattern;
{$I Common.inc}
type
  TPgStatus = (pgDisconnect, pgConnect, pgWait, pgDone, pgForceStop);


  PReadVoltC = ^RealVoltC;
  RealVoltC = record
    VCI      : Single;    // 1 = 1mV
    DVDD     : Single;    // 1 = 1mV
    VDD      : Single;    // 1 = 1mV
    VPP      : Single;    // 1 = 1mV
    VBAT     : Single;    // 1 = 1mV
    VNEG     : Single;    // 1 = 1mV
    {    VPNL      : Double;
    VDDI      : Double;
    T_AV      : Double;
    VPP       : Double;
    VBAT      : Double;
    VCI       : Double;
    VDDEL     : Double;
    VSSEL     : Double;
    DDVHD     : Double;}
    // 12
    IVCI     : Single; // 1 = 1uA
    IDVDD    : Single; // 1 = 1uA
    IVDD     : Single; // 1 = 1uA
    IVPP     : Single; // 1 = 1uA
    IVBAT    : Single; // 1 = 1uA
    IVNEG    : Single; // 1 = 1uA
    // 24, 36
    ELVDD    : Single;    // 1 = 1mV
    ELVSS    : Single;    // 1 = 1mV
    DDVDH    : Single;    // 1 = 1mV
    // 6, 42
    IELVDD   : Single; // 1 = 1uA
    IELVSS   : Single; // 1 = 1uA
    IDDVDH   : Single; // 1 = 1uA
    // 12, 54
  end;
  ReadVoltCurr = packed record
    VCI      : word;    // 1 = 1mV    // V
    DVDD     : word;    // 1 = 1mV
    VDD      : word;    // 1 = 1mV
    VPP      : word;    // 1 = 1mV
    VBAT     : word;    // 1 = 1mV
    VNEG     : word;    // 1 = 1mV
    // 12
    IVCI     : Longword; // 1 = 1uA
    IDVDD    : Longword; // 1 = 1uA
    IVDD     : Longword; // 1 = 1uA
    IVPP     : Longword; // 1 = 1uA
    IVBAT    : Longword; // 1 = 1uA
    IVNEG    : Longword; // 1 = 1uA
    // 24, 36
    ELVDD    : word;    // 1 = 1mV
    ELVSS    : word;    // 1 = 1mV
    DDVDH    : word;    // 1 = 1mV
    // 6, 42
    IELVDD   : Longword; // 1 = 1uA
    IELVSS   : Longword; // 1 = 1uA
    IDDVDH   : Longword; // 1 = 1uA
    // 12, 54
	end;

  PTransVoltage = ^TransVoltage;
  TransVoltage = record
    MsgType : Integer;
    PgNo    : Integer;
    Mode    : Integer;
    nParam  : Integer;
    sMsg    : string;
    ReadPwrData : ReadVoltCurr;

  end;

  InPgConnectEvnt = procedure (nPgNo,nType : Integer;sMessage : string) of object;
  InPwrReadEvnt = procedure (nPgNo : Integer;PwrData : ReadVoltCurr) of object;
  InMaintEvnt = procedure (nPgNo : Integer; nLength : Integer; RevData : array of byte) of object;


  TFileTranStr = record
    TransMode : Integer;
    TransType : Integer;
    TransSigId : Word;
    TotalSize : Integer;
    DataSize  : Integer;
    fileName  : string[80];
    filePath  : string[100];
    CheckSum  : DWORD;
    Data      : array of Byte;
  end;

  TRxData   = record
		NgOrYes   : Integer;
    RootCause : Integer;
    DataLen   : Word;
    Data      : array of Byte;
	end;

  TRxFrame  = record
    IsRev   : Boolean;
    RevLen  : Integer;
    Frame   : array[0..(DefPg.MAX_FRAME_SIZE*2)] of byte; // 혹시 한개 버퍼에 2개가 들어오면을 대비 하자.
  end;

  TRxTouchData = record
    NgOrYes   : Integer;
    FrameCnt  : Integer;
    RevFrameCnt : Integer;
    Data      : array[0..DefPg.MAX_FRAME_COUNT] of TRxFrame;
  end;

  // for GUI.
  PTranStatus  = ^RTranStatus;
  RTranStatus = packed record
    MsgType : Integer;
    PgNo    : Integer;
    Mode    : Integer;
    Total   : Integer;
    CurPos  : Integer;
    IsDone  : Boolean;
    sMsg    : string;//[100];
  end;

  TPatInfoStruct  = record
    PatInfo         : array[0..MAX_PATTERN_CNT-1] of TPatternInfo
  end;

  TDongaPG = class(TObject)
  private
    m_ABinding      : TIdSocketHandle;
    tmAliveCheck    : TTimer;
    tmPowerMeasure  : TTimer;
    m_nConnectCheck : Integer;
    m_nPgNo         : Integer;
    m_bThreadLock   : Boolean;
    m_bMeasureTmr   : boolean;
    m_nTickSendData : Cardinal;
    FDisPatStruct: TPatInfoStruct;

    procedure AliveCheckTimer(Sender: TObject);
    procedure MeasurePowerTimer(Sender: TObject);
    procedure SendData(TxBuf : TIdBytes; bDebug : Boolean = True);
    procedure SendConnectionCheckReq;
    procedure SendFwVersionCheckReq;
    procedure SendPatternVersionCheckReq;
    procedure SendResetReq;
    procedure SendSinglePatReq(nR,nG,nB : Integer);
    procedure SendPocbDownReq( nMode, wIdx , wTxLen : Word; TxBuf : TIdBytes);
    procedure SendDisplayReq(nIdx : Integer);
    procedure SendPocbFuncReq(nMode, nErrCnt, nTimeOut:Integer);
    procedure SendPocbFunc2Req(nMode : Integer; wLen : Word; nbData : TArray<System.Byte>);
    procedure SendChannelOffReq;
    procedure SendModelInfoReq;
    procedure SendOtpWriteReq;
    procedure SendOtpReadReq;
    procedure SendTouchFwDownReq;
    procedure SendTouchIDUpdateReq;
    procedure SendFileTransReq(wSigId,wType,wMode,wIdx,wTxLen : Word;TxBuffer : array of Byte);
    procedure SendPatInfoTransReq(wSigId,wCrc,wTxLen : Word;TxBuffer : array of Byte);
    procedure SendPowerMeasureReq;
    procedure SendPowerSetReq(nSet: Byte);
    Procedure SendI2CWriteReq(buff : TIdBytes; nDataLen : Integer);
    Procedure SendI2CReadReq(buff : TIdBytes; nDataLen : Integer);
    Procedure SendMIPIWriteReq(buff : TIdBytes; nDataLen : Integer);
    procedure SendMIPIWriteHSReq(buff: TIdBytes; nDataLen: Integer);
    procedure SendMIPI_ICWriteReq(buff : TIdBytes; nDataLen : Integer);
    Procedure SendMIPIReadReq(buff : TIdBytes; nDataLen : Integer);
    Procedure SendMIPI_clkReq(nClk : Integer);
    Procedure SendPatternRollReq(nSet, nFrame : Integer);
    procedure SendErrFlagReq(nSet, nFrame, nStart, nEnd : Integer);
    Procedure SendGPIOSetReq(nSet, nSelect : Integer);

//    function Send_NVM_FullReadReq(nLen : Word; NvmBuf : TArray<System.Byte>) : Integer;
    function SendFlashReadReq(nAddress, nLen : Integer) : Integer;
    function CheckTouchCmdAck(Task : TProc; nSid, nDelay, nRetry : Integer) : DWORD;
    function CheckPwrCmdAck(Task : TProc; nSid, nDelay, nRetry : Integer) : DWORD;
    function CheckCmdAck(Task : TProc; nSid, nDelay, nRetry : Integer) : DWORD;
    function CheckPocbCmdAck(Task : TProc; nSid, nDelay, nRetry : Integer) : DWORD;
    procedure ShowDownLoadStatus(nGuiType,curPos, total: Integer; sMsg : string;bIsDone : Boolean = False);

    procedure ThreadTask(task : TProc);
//    procedure DebugPgLog(sDebug : string);
    function GetAlarmStr(alarm_no : Integer; nCurVal : Integer = -1) : String;
    procedure SetDisPatStruct(const Value: TPatInfoStruct);
    procedure ShowMainWindow(nGuiMode: Integer; sMsg: string);
    procedure ShowTestWindow(nGuiMode: Integer; nParam : Integer; sMsg : string);
    function SendPocbFunc2(nMode: Integer; wLen: Word;
      nbData: TArray<System.Byte>): DWORD;
    function SendTouchIDUpdate: Integer;
    procedure ModelCrcChecking(nLen : Integer; buffer : TIdBytes);
    procedure SendPocbDataWriteReq(nMode, nDataSize, nFirst_Addr, nNormal_Addr,nEmSpaceData : Integer);
    function BufferToStr(buffer : TIdBytes; nStart, nEnd: Integer): String;

	public
    IP           : String;
		PORT         : Integer;
    Status       : TPgStatus;
    m_sFwVer, m_sFpgaVer     : string;
    m_hEvnt      : HWND;
    m_hPwEvent   : HWND;
    m_hPocbEvent   : HWND;
    m_hTouchEvnt, m_hMipiReadEvnt : HWND;
    m_bIsPwrEvent : Boolean;
    m_bIsEvent   : Boolean;
    m_bIsPocbEvent   : Boolean;
    m_bIsTouchEvent : Boolean;
    m_hTrans     : HWND;
    m_hMain      : HWND;
    m_hTestFrm   : HWND;
    FForceStop   : Boolean;
    FRxData      : TRxData;
    FRxTouchData : TRxTouchData;
    m_ReadVoltCurr  : ReadVoltCurr;
    m_ReadVoltC  : RealVoltC;
		m_pgTest_Ack : Boolean;
		bThreadBreak  : Boolean;
		bManualTest		: Boolean;
		bReadyNextFlow : Boolean;

    function SendPocbDown( nMode, wIdx , wTxLen, nWaitTime : Word; TxBuf : TIdBytes) : DWORD;
    procedure SendPowerReq(nMode : Integer);
    function LoadIpStatus(ABinding  : TIdSocketHandle) : Boolean;
    procedure ThreadGetData(const str: TIdBytes);
    procedure ReadData(const str: TIdBytes);
    procedure SendTransData(nTransDataCnt : Integer;const transData : TArray<TFileTranStr>);
    function SendBuffData(const transData : TFileTranStr) : Boolean;
    function SendPocbData(const transData : TFileTranStr) : Integer;
    procedure SendPatGrpData(SetPatGrp : TPatterGroup);
    function SendPgReset : DWORD;
    procedure GetFwVersion;
    constructor Create(nPgNo : Integer;hMain : THandle); virtual;
    destructor Destroy; override;
    function SendPowerOn (nMode : Integer; nWait : Integer = 3000; nRty : Integer = 1) : DWORD;
    function SendSinglePat (nR, nG, nB : Integer; nWait : Integer = 3000; nRty : Integer = 1) : DWORD;
    function SendChannelOff : DWORD;
    function SendPowerMeasure : DWORD;
    function SendPowerSet(nSet: Byte) : DWORD;
    function SendDisplayPat ( nIdx : Integer; nWait : Integer = 2000; nRty : Integer = 1) : DWORD;
    function SendPocbFunc(nMode,nErrCnt,nTimeOut : Integer) : DWORD;
    function SendPocbhIDUpdate : Integer;
    function SendToucFunc2(nMode : Integer; wLen : Word; nbData : TArray<System.Byte>) : DWORD;
    function SendTouchRead(nIdx, nFreq, nFrame : Integer) : Integer;
    procedure SendTouchReq(nIdx,nFreq,nFrame:Integer);
//    function Send_NVM_FullRead(nLen : Word; NvmBuf : TArray<System.Byte>) : Integer;
    function SendFlashRead(nAddress, nLen : Integer) : DWORD;
    function SendTouchFwDown : Integer;
    function SendI2CWrite (buff : TIdBytes; nDataLen : Integer; nWait : Integer = 3000) : DWORD;
    function SendI2CRead  (buff : TIdBytes; nDataLen : Integer; nWait : Integer = 3000) : DWORD;
    function SendMIPIWrite(buff : TIdBytes; nDataLen : Integer; nWait : Integer = 3000; nRty : Integer = 2) : DWORD;
    function SendMIPIWriteHS(buff: TIdBytes; nDataLen: Integer; nWait: Integer = 3000; nRty : Integer = 2): DWORD;
    function SendMIPI_ICWrite(buff : TIdBytes; nDataLen : Integer; nWait : Integer = 3000) : DWORD;
    function SendMIPI_clk( nClk : Integer; nWait : Integer = 3000) : DWORD;
    function SendPocbDataWrite(nMode, nDataSize, nFirst_Addr, nNormal_Addr,nEmSpaceData : Integer) : DWORD;
    function SendMIPIRead (buff : TIdBytes; nDataLen : Integer; nWait : Integer = 3000) : DWORD;
    function SendOtpWrite(nWait : Integer = 30000) : DWORD;
    function SendOtpRead(nWait : Integer = 20000) : DWORD;
    function SendPatternRoll (nSet, nFrame : Integer; nWait : Integer = 3000) : DWORD;
    function SendErrorFlag   (nSet, nFrame, nStart, nEnd : Integer; nWait : Integer = 3000) : DWORD;

    function SendGPIOSet (nSet, nSelect : Integer; nWait : Integer = 3000) : DWORD;

    procedure SetPowerMeasureTimer(bEnable : Boolean; nInterval : Integer = 0);
    function SendModelInfo : DWORD;
    procedure SetCamEvent;
    // Added by Clint 2020-12-30 오전 3:07:48
    function SendChangeVoltSet(nSet, nSelect, nValue: Integer; nWait : Integer = 2000; nRty : Integer = 1): DWORD;
    function SendEnableVoltSet(nSet, nSelect: Integer; nWait : Integer = 2000; nRty : Integer = 1): DWORD;

    procedure SendByteData(buff : TIdBytes; nDataLen : Integer);
    procedure ThreadRead(RevData : TIdBytes);
    property DisPatStruct : TPatInfoStruct read FDisPatStruct write SetDisPatStruct;
    procedure TestFunc;
    function PocbEraseType(nType : Integer; nParam1 : Integer = 0; nParam2 : Integer = 0) : Integer;
    function MipiWrite(sData : string) : Integer;
    function Mipi_Ic_Write(sData : string) : Integer;
    function MipiRead(sData : string ; var RevData : TIdbytes) : Integer;
    function CheckFWVersion : Boolean;
    procedure EnableAlive(bEnable: Boolean);
    {PTransVoltage}
	end;

//  TJobProcThread = class (TThread)
//  public
//    RecvBuff  : array[0..DefPG.UDP_BUF_SIZE] of AnsiChar;
//    pData : pointer;
//    tLen  : integer;
//  protected
//    procedure Execute; override;
//    procedure ReadRecvPacket;
//  end;

  TUdpServerVh = class(TObject)
  private

//    RecvJobThread : TJobProcThread;
    udpSvr        : TIdUDPServer;
    FOnRevPgConnection: InPgConnectEvnt;
    FOnPwrReadEvent: InPwrReadEvnt;
    FIsMainter: Boolean;

    FOnRevDataForMaint: InMaintEvnt;
    procedure udpSvrUDPErr(AThread: TIdUDPListenerThread; ABinding: TIdSocketHandle; const AMessage: String; const AExceptionClass: TClass);
    /// for DX3
		//procedure udpSvrUDPClsRead(AThread: TIdUDPListenerThread; AData: array of byte; ABinding: TIdSocketHandle);
    procedure udpSvrUDPClsRead(AThread: TIdUDPListenerThread;const AData: TIdBytes; ABinding: TIdSocketHandle);

    function IpToPgNo ( sPeerIp : string ) : Integer;
    procedure SetOnRevPgConnection(const Value: InPgConnectEvnt);
    procedure SetOnPwrReadEvent(const Value: InPwrReadEvnt);
    procedure SetIsMainter(const Value: Boolean);
    procedure SetOnRevDataForMaint(const Value: InMaintEvnt);

  public
    FIsReadyToRead : Boolean;
    constructor Create(hHandle : THandle; nPgCnt : Integer); virtual;
    destructor Destroy; override;
    property OnRevPgConnection : InPgConnectEvnt read FOnRevPgConnection write SetOnRevPgConnection;
    property OnPwrReadEvent : InPwrReadEvnt read FOnPwrReadEvent write SetOnPwrReadEvent;
    property IsMainter : Boolean read FIsMainter write SetIsMainter;
    property OnRevDataForMaint : InMaintEvnt read FOnRevDataForMaint write SetOnRevDataForMaint;
  end;
var
//  MyQueue       : TGeneralQueue;
  Pg            : array[Defcommon.CH1 .. Defcommon.MAX_CH] of TDongaPG;

  UdpServer       : TUdpServerVh;

implementation

{$r+} // memory range check.
{ TUdpServer }

constructor TUdpServerVh.Create(hHandle : THandle; nPgCnt : Integer);
var
  i: Integer;
begin

// Mainter Mode 에서 임을 확인 Flag.  Mainter Create 시에 True, Close시에 Flase.
  FIsMainter := False;
  FIsReadyToRead := False;

  for i := 0 to Pred(nPgCnt) do begin
    Pg[i] := TDongaPG.Create(i,hHandle);
  end;

//  MyQueue:= TGeneralQueue.Create(100 * nPgCnt); //Queue Size
//  MyQueue.Flush;
//  RecvJobThread := TJobProcThread.Create (True);
//  RecvJobThread.FreeOnTerminate := True;
//  RecvJobThread.Resume;

  udpSvr := TIdUDPServer.Create(nil);
	udpSvr.DefaultPort := DefPG.UDP_DEFAULT_PORT;
	udpSvr.OnUDPException := udpSvrUDPErr;
	udpSvr.OnUDPRead := udpSvrUDPClsRead;
	if not udpSvr.Active then udpSvr.Active := True;

end;

destructor TUdpServerVh.Destroy;
var
  i: Integer;
begin
  if udpSvr.Active then	udpSvr.Active := False;
  if udpsvr <> nil then	begin
    udpSvr.Free;
    udpSvr := nil;
  end;
//  if RecvJobThread.Suspended then RecvJobThread.DoTerminate;
//
//  RecvJobThread.Suspended := True;
//  RecvJobThread := nil;
//  MyQueue.Free;
//  MyQueue := nil;

  for i := Defcommon.CH1 to Defcommon.MAX_CH do begin
    if Pg[i] <> nil then begin
      Pg[i].Free;
      Pg[i] := nil;
    end;
  end;



  inherited;
end;

function TUdpServerVh.IpToPgNo(sPeerIp : string): Integer;
var
  nRet, i : Integer;
begin
  nRet := -1;
  if sPeerIp = '' then Exit(nRet);
  try
    for i := Defcommon.CH1 to Defcommon.MAX_CH do begin
      if Pg[i] = nil then Continue;
      if sPeerIp = Common.SystemInfo.IPAddr[i] then begin
        nRet := i;
        Break;
      end;
//      if sPeerIp = Pg[i].IP then begin
//        Result := i;
//        Break;
//      end;
    end;
  except
    nRet := 0;
  end;
  Result := nRet;
end;

procedure TUdpServerVh.SetIsMainter(const Value: Boolean);
begin
  FIsMainter := Value;
end;

procedure TUdpServerVh.SetOnPwrReadEvent(const Value: InPwrReadEvnt);
begin
  FOnPwrReadEvent := Value;
end;

procedure TUdpServerVh.SetOnRevDataForMaint(const Value: InMaintEvnt);
begin
  FOnRevDataForMaint := Value;
end;

procedure TUdpServerVh.SetOnRevPgConnection(const Value: InPgConnectEvnt);
begin
  FOnRevPgConnection := Value;
end;

procedure TUdpServerVh.udpSvrUDPErr(AThread: TIdUDPListenerThread; ABinding: TIdSocketHandle; const AMessage: String; const AExceptionClass: TClass);
begin

end;

procedure TUdpServerVh.udpSvrUDPClsRead(AThread: TIdUDPListenerThread;const AData: TIdBytes; ABinding: TIdSocketHandle);
var
	nLength, Sig_Id   : Word;
	Buffer2           : TIdBytes;
	wPgNo, nSize      : word;
  nPgNo             : Integer;
	sDebug            : string;
begin
  if not FIsReadyToRead then Exit;

	nSize := SizeOf(AData);
	if nSize = 0 then Exit;
	CopyMemory(@Sig_Id,  @AData[0], 2);
	CopyMemory(@nLength, @AData[2], 2);
  SetLength(Buffer2,nLength + 20);
	try
		if nLength > 0 then CopyMemory(@Buffer2[6], @AData[4], nLength);
{$IFDEF DEBUG}
    if (Sig_Id <> SIG_CONCHECKACK) {and (Sig_Id <> SIG_READ_VOLTCUR_ACK)} then begin
      sDebug := Format('[Read] PG->ip(%s), sig=0x%.4x, len=%d, tot=%d',[ABinding.PeerIP, Sig_Id, nLength, Length(AData)]);
      CodeSite.SendMemoryAsHex(sDebug,@Buffer2[6],nLength);
    end;
{$ENDIF}


		if Sig_Id = SIG_FIRST_CONNREQ then begin //First Connection Inform.
			nPgNo := Byte(Buffer2[6]) - 1;
//			OutputDebugString(PChar(Format('PG_CONNECT PG=%d IP=%s PORT=%d',[nPgNo,ABinding.PeerIP,ABinding.PeerPORT])));
//      CodeSite.SendMsg(Format('PG No : %d',[nPgNo]));
			if Defcommon.MAX_PG_CNT < nPgNo then Exit;  //MAX_PG_CNT를 넘으면 무시한다.
      if Pg[nPgNo] <> nil then begin
//        Pg[nPgNo] := TDongaPG.Create(nPgNo,ABinding);
//      end
//      else begin
        if Pg[nPgNo].LoadIpStatus(ABinding) then begin
          // Main에 Connection 연결됨 표시.
//          OnRevPgConnection(nPgNo,0,'');
          Pg[nPgNo].ShowTestWindow(Defcommon.MSG_MODE_DISPLAY_CONNECTION,0,'');  // param 0 ==> connection. 2 ==> Disconnect
        end;
      end;
		end
		else begin
      if Sig_Id < DefPG.SIG_CONCHECKACK then Exit;

      if Common.SimulateInfo.Use_PG then
        nPgNo:= ABinding.PeerPort - Common.SimulateInfo.PG_BasePort
      else
			  nPgNo := IpToPgNo(ABinding.PeerIP);

			if nPgNo <> -1 then begin
        wPgNo := word(nPgNo);
				CopyMemory(@Buffer2[0], @wPgNo,  2);		// IP를 가지고 PG Num 계산
				CopyMemory(@Buffer2[2], @AData[0], nLength+4);
				//--------------------------------------------------------
//				if (MyQueue.Empty or MyQueue.Full) then MyQueue.Flush;
//				pData := AllocMem(nLength + 6);
//
//				CopyMemory(pData, @Buffer2[0], nLength + 6);
//
//				tmp:= MyQueue.WriteItem(pData,nLength + 6,INFINITE);
//				if tmp <> 0 then
//					OutputDebugString(PChar('PGUDPServer JobProcess Queue Full Error !!'));
        if wPgNo > Defcommon.MAX_CH then Exit;
        if Pg[wPgNo] <> nil then begin
//          Pg[nPgNo].ThreadGetData(Buffer2);
          Pg[wPgNo].ReadData(Buffer2);
        end;
				//--------------------------------------------------------
        if (Sig_Id <> SIG_CONCHECKACK) and FIsMainter then begin
          OnRevDataForMaint(wPgNo,nLength+6,Buffer2);
        end;
			end;
		end;
	except
		OutputDebugString(PChar('>> PGUDPServerUDPRead Exception Error!!'));
	end;
end;

{ TJobProcThread }

//procedure TJobProcThread.Execute;
//var
//  tmp: LongInt;
//begin
//  tmp := BUFF_NO_ERROR;
//  while not Terminated do begin
//    try
//      tmp := MyQueue.ReadItem(pData,tLen,INFINITE);
//    finally
//      if (tmp=BUFF_NO_ERROR) and (not Terminated) then
//      begin
//        CopyMemory(@RecvBuff[0],pData,tLen);
//        FreeMem(pData); // This one is VERY IMPORTANT!
//        pData := nil;
//      end
//      else Terminate;
//    end;
//    if not Terminated then begin
////      Synchronize(ReadRecvPacket);
//      ReadRecvPacket;
//    end;
//  end;
//  inherited;
//
//end;
//
//procedure TJobProcThread.ReadRecvPacket;
//var
//  Temp: array[0..UDP_BUF_SIZE] of Byte;
//  wPgNo : Word;
//begin
//  FillChar(Temp, UDP_BUF_SIZE, #0);
//  Move(RecvBuff[0], Temp, tLen);
//  CopyMemory(@wPgNo,  @RecvBuff[0], 2);
//  if wPgNo > DefCommon.MAX_CH then Exit;
//  Pg[wPgNo].ReadData(Temp);
//end;

{ TDongaPG }

procedure TDongaPG.AliveCheckTimer(Sender: TObject);
var
  nTick: Cardinal;
begin
	try
  {$IFDEF SIMULATOR_PG}
    m_nConnCheckPg := 0; // SIMULATOR_PG  //2020-09-XX
{$ENDIF}
    CodeSite.Send(Format('Alive Check Timer On - Idx (%d)',[m_nConnectCheck]));
    //if m_nConnectCheck > 1 then begin
    if m_nConnectCheck > 2 then begin
      m_nConnectCheck := 0;
      Status := pgDisconnect; // 연결 끊김으로 판단.
//      OnRevPgConnection(nPgNo,0,'');
//      UdpServer.OnRevPgConnection(Self.m_nPgNo,2,'');
      ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_CONNECTION,2,'');  // param 0 ==> connection. 2 ==> Disconnect
//      m_ABinding.Free;
      m_ABinding := nil;
    end
    else begin
      nTick:= GetTickCount;
      if (nTick - m_nTickSendData) > 2000 then begin
        SendConnectionCheckReq;
        Inc(m_nConnectCheck);
      end;
    end;
	except
		OutputDebugString(PChar('>> AliveCheckTimer Exception Error!!'));
	end;
end;

function TDongaPG.BufferToStr(buffer: TIdBytes; nStart, nEnd: Integer): String;
var
  i: Integer;
begin
  Result:= '';
  for i := nStart to nEnd do begin
    Result := Result + Format('%0.2x ',[buffer[i]]);
  end;
end;

function TDongaPG.CheckCmdAck(Task: TProc; nSid, nDelay, nRetry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    // 통신중에 Power Sensing 했을 경우 중복 피하기 위함.
    if m_bMeasureTmr then begin
      Sleep(2);
      tmPowerMeasure.Enabled := False;
    end;

    nRet := CMD_RESULT_NAK;
		sEvnt := Format('SendPG%d%x0.4',[self.m_nPgNo,nSid]);
		m_hEvnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
    m_bIsEvent := True;     // Create Event 했는지 확인 하는 Flag.
		for i := 1 to nRetry do begin
			Task;
			if Status in [pgForceStop,pgDisconnect] then Break;
      FRxData.NgOrYes := DefPG.CMD_READY;
			nRet := WaitForSingleObject(m_hEvnt,nDelay);
			case nRet of
				WAIT_OBJECT_0 : begin
					if FRxData.NgOrYes = DefPg.CMD_RESULT_ACK then Break
					else begin
            Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - NAK : %d)',[nSid]));
						nRet := FRxData.NgOrYes;
					end;
				end;
				WAIT_TIMEOUT  : begin
          Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - TIME OUT : %d)',[nSid]));
				end
				else begin
          Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - ELSE : %d, (%0.2x)',[nSid, nRet]));
					Break;
        end;
			end;
		end;
	finally
		CloseHandle(m_hEvnt);
    m_bIsEvent := False;
    // 통신중에 Power Sensing 했을 경우 중복 피하기 위함.
    if m_bMeasureTmr then begin
      tmPowerMeasure.Enabled := True;
    end;
	end;
  Result := nRet
end;


function TDongaPG.CheckFWVersion: Boolean;
var
  bRet : Boolean;
  dModel, dPg : Double;
  sDebug : string;
begin
  bRet := False;
  sDebug := '';
  dModel := StrToFloatDef(Common.SystemInfo.FwVer,0.0);
  dPg    := StrToFloatDef(m_sFwVer,0.0);
  if (dModel = dPg) then begin
    bRet := True;
  end;
  if (dModel = 0.0) or (dPg = 0.0) then bRet := False;
  if not bRet then begin
    // 2020-04-12 ysea
//    sDebug := Format('[PG FW] Model Info (%0.3f) >  SPI FW (%0.3f)',[dModel, dPg]);
    sDebug := Format('[PG FW] System Info (%0.3f) >  FW (%0.3f)',[dModel, dPg]);
  end;

  if bRet then begin
    dModel := StrToFloatDef(Common.SystemInfo.FpgaVer,0.0);
    dPg    := StrToFloatDef(m_sFpgaVer,0.0);
    if (dModel = dPg) then bRet := True;
    if (dModel = 0.0) or (dPg = 0.0) then bRet := False;
    if not bRet then begin
      // 2020-04-12 ysea
//      sDebug := Format('[PG BOOT] Model Info (%0.1f) >  SPI BOOT (%0.1f)',[dModel, dPg]);
      sDebug := Format('[PG FPGA System Info (%0.1f) >  FPGA (%0.1f)',[dModel, dPg]);
    end;
  end;
  if not bRet then begin
    ShowTestWindow(Defcommon.MSG_MODE_FW_CHECK,0,sDebug);
  end;
  Result := bRet;
end;

function TDongaPG.CheckPocbCmdAck(Task: TProc; nSid, nDelay, nRetry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    nRet := CMD_RESULT_NAK;
		sEvnt := Format('SendPOCBPG%d%x0.4',[self.m_nPgNo,nSid]);
		m_hPocbEvent := CreateEvent(nil, False, False, PWideChar(sEvnt));
    m_bIsPocbEvent := True;     // Create Event 했는지 확인 하는 Flag.
		for i := 1 to nRetry do begin
			if Status in [pgForceStop,pgDisconnect] then Break;
      FRxData.NgOrYes := DefPG.CMD_READY;
      Task;
			nRet := WaitForSingleObject(m_hPocbEvent,nDelay);
			case nRet of
				WAIT_OBJECT_0 : begin
					if FRxData.NgOrYes <> DefPg.CMD_RESULT_ACK then begin
             Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - NAK : %d)',[nSid]));
						nRet := FRxData.NgOrYes;
					end
          else begin
            Break;
          end;
				end;
        WAIT_TIMEOUT  : begin
          Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - TIME OUT : %d)',[nSid]));
				end
				else begin
          Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - ELSE : %d, (%0.2x)',[nSid, nRet]));
					Break;
        end;
			end;
		end;
	finally
		CloseHandle(m_hPocbEvent);
    m_bIsPocbEvent := False;
	end;
  Result := nRet
end;

function TDongaPG.CheckPwrCmdAck(Task: TProc; nSid, nDelay, nRetry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    // 통신중에 Power Sensing 했을 경우 중복 피하기 위함.
    if m_bMeasureTmr then begin
      Sleep(2);
      tmPowerMeasure.Enabled := False;
    end;

    nRet := CMD_RESULT_NAK;
		sEvnt := Format('SendPG%d%x0.4',[self.m_nPgNo,nSid]);
    m_bIsPwrEvent := True;     // Create Event 했는지 확인 하는 Flag.
		m_hPwEvent := CreateEvent(nil, False, False, PWideChar(sEvnt));

		for i := 1 to nRetry do begin
			Task;
			if Status in [pgForceStop,pgDisconnect] then Break;
      FRxData.NgOrYes := DefPG.CMD_READY;
			nRet := WaitForSingleObject(m_hPwEvent,nDelay);
			case nRet of
				WAIT_OBJECT_0 : begin
					if FRxData.NgOrYes = DefPg.CMD_RESULT_ACK then Break
					else begin
						nRet := FRxData.NgOrYes;
					end;
				end;
				WAIT_TIMEOUT  : begin
          Common.MLog(Self.m_nPgNo,'PG POWER Measure NG - TIME OUT');
				end
				else begin
					Break;
        end;
			end;
		end;
	finally
		CloseHandle(m_hPwEvent);
    m_bIsPwrEvent := False;
    // 통신중에 Power Sensing 했을 경우 중복 피하기 위함.
    if m_bMeasureTmr then begin
      tmPowerMeasure.Enabled := True;
    end;
	end;
  Result := nRet
end;

function TDongaPG.CheckTouchCmdAck(Task: TProc; nSid, nDelay, nRetry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    // 통신중에 Power Sensing 했을 경우 중복 피하기 위함.
    if m_bMeasureTmr then begin
      tmPowerMeasure.Enabled := False;
      Sleep(2);
    end;
    m_bIsTouchEvent := True;     // Create Event 했는지 확인 하는 Flag.
    nRet := CMD_RESULT_NAK;
		sEvnt := Format('SendTouchPG%d%x0.4',[self.m_nPgNo,nSid]);
    if nSid = SIG_MIPI_READ then begin
      m_hMipiReadEvnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
    end
    else begin
      m_hTouchEvnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
    end;



		for i := 1 to nRetry do begin
      FRxData.NgOrYes := DefPG.CMD_READY;
			Task;
			if Status in [pgForceStop,pgDisconnect] then Break;
      if nSid = SIG_MIPI_READ then begin
        nRet := WaitForSingleObject(m_hMipiReadEvnt,nDelay);
      end
      else begin
        nRet := WaitForSingleObject(m_hTouchEvnt,nDelay);
      end;

			case nRet of
				WAIT_OBJECT_0 : begin
					if FRxData.NgOrYes = DefPg.CMD_RESULT_ACK then Break
					else begin
						nRet := FRxData.NgOrYes;
					end;
				end;
        WAIT_TIMEOUT  : begin
          Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - TIME OUT : SIG=%d, Delay=%d',[nSid, nDelay]));
				end
				else begin
          Common.MLog(Self.m_nPgNo,Format('PG EVENT NG - ELSE : SIG=%d, Ret=%0.2x',[nSid, nRet]));
					Break;
        end;
			end;
		end;
	finally

    if nSid = SIG_MIPI_READ then begin
      CloseHandle(m_hMipiReadEvnt);
    end
    else begin
      CloseHandle(m_hTouchEvnt);
    end;
    m_bIsTouchEvent := False;
    // 통신중에 Power Sensing 했을 경우 중복 피하기 위함.
    if m_bMeasureTmr then begin
      tmPowerMeasure.Enabled := True;
    end;
	end;
  Result := nRet
end;

constructor TDongaPG.Create(nPgNo: Integer;hMain : THandle);
begin
  m_nPgNo   := nPgNo;
  m_sFwVer  := '';
  Status := pgDisconnect;
  m_bIsEvent := False;
  m_bIsPwrEvent := False;
  m_bIsTouchEvent := False;
  // Alive timer
  tmAliveCheck := TTimer.Create(nil);
	tmAliveCheck.OnTimer := AliveCheckTimer;
	tmAliveCheck.Interval := 2000;
	tmAliveCheck.Enabled := False;

  // Power Measure Timer.
  tmPowerMeasure := TTimer.Create(nil);
  tmPowerMeasure.OnTimer := MeasurePowerTimer;
  tmPowerMeasure.Interval := 1700;
	tmPowerMeasure.Enabled := False;

  m_nConnectCheck := 0;
  m_bThreadLock := False;
  m_hMain := hMain;
  FForceStop := False;
end;

//procedure TDongaPG.DebugPgLog(sDebug: string);
//var
//  sFileName, sTime : string;
//  sFilePath        : string;
//
//  _infile : TextFile;
//begin
//  sFilePath := Common.Path.MLOG;
//  Common.CheckDir(sFilePath);
//  sTime := formatDateTime('yyyymmdd',now);
//  sFileName := Format('%s%s_Ch%d.txt',[sFilePath ,sTime ,self.m_nPgNo+1]);
//  try
//    AssignFile(_infile, sFileName);
//		if not FileExists(sFileName) then begin
//			Rewrite(_infile);
//		end
//		else  begin
//			Append(_infile);
//		end;
////    sTime := FormatDateTime('hh:nn:ss', Now);
////    sWriteData := Format('[Time : %s] %s',[sTime,sDebug]);
////    sTime := '';
////    sWriteData := '';
////    if bTimeStemp then begin
////      sTime := FormatDateTime('hh:nn:ss', Now);
////      sWriteData := Format('[Time : %s] %s',[sTime,sData]);
////    end
////    else begin
////      sWriteData := sData;
////    end;
//    WriteLn(_infile, sDebug);
//  finally
//    Close(_infile);
//  end;
//end;

destructor TDongaPG.Destroy;
begin
// Alive timer
  tmAliveCheck.Enabled := False;
  tmAliveCheck.Free;
  tmAliveCheck := nil;

  // Power Measure Timer.
  tmPowerMeasure.Enabled := False;
  tmPowerMeasure.Free;
  tmPowerMeasure := nil;
  inherited;
end;

procedure TDongaPG.EnableAlive(bEnable: Boolean);
begin
  if bEnable then begin
    m_nConnectCheck := 0;
    tmAliveCheck.Enabled := True;
  end
  else begin
    tmAliveCheck.Enabled := False;
  end;

end;

function TDongaPG.GetAlarmStr(alarm_no: Integer; nCurVal : Integer = -1): String;
var
  sRet : string;
  dCur : Double;
  wLimit : Word;
begin
{$IFDEF ISPD_A}
  Case alarm_no of
    101 : sRet := 'PBA FAIL';
    102 : sRet := 'FPGA FAIL';
    210 : sRet := 'POWER NO RESPONSE';

    301 : sRet := 'VPNL HIGH LIMIT FAIL';
    302 : sRet := 'VPNL LOW LIMIT FAIL';
    303 : sRet := 'DVDD HIGH LIMIT FAIL';
    304 : sRet := 'DVDD LOW LIMIT FAIL';
    305 : sRet := 'VDD HIGH LIMIT FAIL';
    306 : sRet := 'VDD LOW LIMIT FAIL';
    307 : sRet := 'VPP HIGH LIMIT FAIL';
    308 : sRet := 'VPP LOW LIMIT FAIL';
    309 : sRet := 'VBAT HIGH LIMIT FAIL';
    310 : sRet := 'VBAT LOW LIMIT FAIL';
    311 : sRet := 'VNEG HIGH LIMIT FAIL';
    312 : sRet := 'VNEG LOW LIMIT FAIL';
    313 : sRet := 'ELVDD HIGH LIMIT FAIL';
    314 : sRet := 'ELVDD LOW LIMIT FAIL';
    315 : sRet := 'ELVSS HIGH LIMIT FAIL';
    316 : sRet := 'ELVSS LOW LIMIT FAIL';
    317 : sRet := 'DDVDH HIGH LIMIT FAIL';
    318 : sRet := 'DDVDH LOW LIMIT FAIL';

    401 : sRet := 'IVCI HIGH LIMIT FAIL';
    402 : sRet := 'IVCI LOW LIMIT FAIL';
    403 : sRet := 'IDVDD HIGH LIMIT FAIL';
    404 : sRet := 'IDVDD LOW LIMIT FAIL';
    405 : sRet := 'IVDD HIGH LIMIT FAIL';
    406 : sRet := 'IVDD LOW LIMIT FAIL';
    407 : sRet := 'IVPP HIGH LIMIT FAIL';
    408 : sRet := 'IVPP LOW LIMIT FAIL';
    409 : sRet := 'IVBAT HIGH LIMIT FAIL';
    410 : sRet := 'IVBAT LOW LIMIT FAIL';
    411 : sRet := 'IVNEG HIGH LIMIT FAIL';
    412 : sRet := 'IVNEG LOW LIMIT FAIL';
    413 : sRet := 'IELVDD HIGH LIMIT FAIL';
    414 : sRet := 'IELVDD LOW LIMIT FAIL';
    415 : sRet := 'IELVSS HIGH LIMIT FAIL';
    416 : sRet := 'IELVSS LOW LIMIT FAIL';
    417 : sRet := 'IDDVDH HIGH LIMIT FAIL';
    418 : sRet := 'IDDVDH LOW LIMIT FAIL';
    509 : sRet := 'VBAT VOLTAGE FAIL';
    else  sRet := 'UNKNOWN ALARM MESSAGE ' + IntTStr(alarm_no) ;
  end;
{$ELSE}
  Case alarm_no of
    101 : sRet := 'PBA FAIL';
    102 : sRet := 'FPGA FAIL';
    210 : sRet := 'POWER NO RESPONSE';

    301 : sRet := 'VPNL HIGH LIMIT FAIL';
    302 : sRet := 'VPNL LOW LIMIT FAIL';
    303 : sRet := 'VDDI HIGH LIMIT FAIL';
    304 : sRet := 'VDDI LOW LIMIT FAIL';
    305 : sRet := 'T_AVDD HIGH LIMIT FAIL';    // LGD 요청 사항 : VIO ==> T_AVDD
    306 : sRet := 'T_AVDD LOW LIMIT FAIL';     // LGD 요청 사항 : VIO ==> T_AVDD
    307 : sRet := 'VPP HIGH LIMIT FAIL';
    308 : sRet := 'VPP LOW LIMIT FAIL';
    309 : sRet := 'VBAT HIGH LIMIT FAIL';
    310 : sRet := 'VBAT LOW LIMIT FAIL';
    311 : sRet := 'VCI HIGH LIMIT FAIL';
    312 : sRet := 'VCI LOW LIMIT FAIL';
    313 : sRet := 'ELVDD HIGH LIMIT FAIL';
    314 : sRet := 'ELVDD LOW LIMIT FAIL';
    315 : sRet := 'ELVSS HIGH LIMIT FAIL';
    316 : sRet := 'ELVSS LOW LIMIT FAIL';
    317 : sRet := 'DDVDH HIGH LIMIT FAIL';
    318 : sRet := 'DDVDH LOW LIMIT FAIL';
    401 : sRet := 'IVPNL HIGH LIMIT FAIL';
    402 : sRet := 'IVPNL LOW LIMIT FAIL';
    403 : sRet := 'IVDDI HIGH LIMIT FAIL';
    404 : sRet := 'IVDDI LOW LIMIT FAIL';
    405 : sRet := 'IT_AVDD HIGH LIMIT FAIL';    // LGD 요청 사항 : VIO ==> T_AVDD
    406 : sRet := 'IT_AVDD LOW LIMIT FAIL';     // LGD 요청 사항 : VIO ==> T_AVDD
    407 : sRet := 'IVPP HIGH LIMIT FAIL';
    408 : sRet := 'IVPP LOW LIMIT FAIL';
    409 : sRet := 'IVBAT HIGH LIMIT FAIL';
    410 : sRet := 'IVBAT LOW LIMIT FAIL';
    411 : sRet := 'IVCI HIGH LIMIT FAIL';
    412 : sRet := 'IVCI LOW LIMIT FAIL';
    413 : sRet := 'IELVDD HIGH LIMIT FAIL';
    414 : sRet := 'IELVDD LOW LIMIT FAIL';
    415 : sRet := 'IELVSS HIGH LIMIT FAIL';
    416 : sRet := 'IELVSS LOW LIMIT FAIL';
    417 : sRet := 'IDDVDH HIGH LIMIT FAIL';
    418 : sRet := 'IDDVDH LOW LIMIT FAIL';
    509 : sRet := 'VBAT VOLTAGE FAIL';
    else  sRet := 'UNKNOWN ALARM MESSAGE: ' + IntToStr(alarm_no);
  end;
{$ENDIF}
  // Current Limit만 Check 하자.
  if nCurVal <> -1 then begin
    dCur := nCurVal / 1000;
    case alarm_no of
      401 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VCI];
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      402 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL[DefCommon.PWR_VCI] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      403 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_DVDD] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      404 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL[DefCommon.PWR_DVDD] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      405 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VDD] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      406 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL[DefCommon.PWR_VDD] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      407 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VPP] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      408 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL[DefCommon.PWR_VPP] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      409 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VBAT] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      410 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL[DefCommon.PWR_VBAT] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      411 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VNEG] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      412 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL[DefCommon.PWR_VNEG] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      413 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL2[DefCommon.PWR_ELVDD] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      414 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL2[DefCommon.PWR_ELVDD] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      415 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL2[DefCommon.PWR_ELVSS] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      416 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL2[DefCommon.PWR_ELVSS] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      417 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_HL2[DefCommon.PWR_DDVDH] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
      418 : begin
        wLimit := Common.TempModelInfo.PWR_CUR_LL2[DefCommon.PWR_DDVDH] ;
        sRet := sRet + Format(' (Limit:%d, Current %.3f mA)',[ wLimit ,dCur]);
      end;
    end;
  end;
//  if alarm_no in [301,302] then begin
//    sRet := sRet + Format('',[]);
//  end;

  Result := sRet;
end;

procedure TDongaPG.GetFwVersion;
begin
  m_sFwVer := '';
  if Self.Status in [pgDisconnect, pgWait] then exit;
  ThreadTask(procedure begin
    Self.Status := pgWait;
    CheckCmdAck(SendFwVersionCheckReq,SIG_FW_VERSION_REQ,1000,2);
    self.Status := pgDone;
  end);
end;

function TDongaPG.LoadIpStatus(ABinding: TIdSocketHandle) : Boolean;
var
  i : Integer;
  sPgIp : string;
begin
  sPgIp := '';
  if Common.SimulateInfo.Use_PG then
  begin
    Self.IP     := ABinding.PeerIP;
    Self.PORT   := ABinding.PeerPort; //DefPG.UDP_DEFAULT_PORT;
    m_ABinding  := ABinding;
    if Status = pgDisconnect then begin
      Status := pgConnect;
    end;
    SendFwVersionCheckReq;
    m_nConnectCheck := 0;
    tmAliveCheck.Enabled := True;
    Result := True;
    Exit(True);
  end;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if m_nPgNo = i then begin
      sPgIp := Common.SystemInfo.IPAddr[i];

      Break;
    end;
  end;
//  CodeSite.SendMsg(Format('PG IP sPGIp(%s), ABinding.PeerIP(%s)',[sPgIp,ABinding.PeerIP]));
  if sPgIp =  ABinding.PeerIP then begin
    Self.IP     := ABinding.PeerIP;
    Self.PORT   := DefPG.UDP_DEFAULT_PORT;
    m_ABinding  := ABinding;
    if Status = pgDisconnect then begin
      Status := pgConnect;
    end;
    SendFwVersionCheckReq;
    m_nConnectCheck := 0;
    tmAliveCheck.Enabled := True;
    Result := True;
  end
  else begin
    Result := False;
  end;
end;

procedure TDongaPG.MeasurePowerTimer(Sender: TObject);
begin
  SendPowerMeasureReq;
end;

function TDongaPG.MipiRead(sData: string; var RevData: TIdbytes): Integer;
var
  wdRet : DWORD;
  i, nWait, nLen : Integer;
  sSendCmd, sDebug : String;
  lstTemp : TStringList;
  buff : TIdBytes;
begin
  sSendCmd := sData;//StringReplace(sData, '0x', '$', [rfReplaceAll]);
  nWait := 1000;
  lstTemp := TStringList.Create;
  try
    ExtractStrings([' '], [], PWideChar(sSendCmd), lstTemp);
    nLen := lstTemp.Count;
    SetLength(buff, nLen);
    for i := 0 to Pred(nLen) do begin
      buff[i] := StrToInt(lstTemp[i]);
    end;
  finally
    lstTemp.Free;
  end;
  wdRet := SendMIPIRead(buff, nLen, nWait);
  sDebug := '';
  if wdRet = WAIT_OBJECT_0 then begin
    SetLength(RevData,FRxData.DataLen);
    for i := 0 to Pred(FRxData.DataLen) do begin
      // byte로 데이터 입력 받음.
//          Common.MLog(FPgNo, 'Data' + IntToStr(i) +' : ' + IntToStr(Pg[FPgNo].FRxData.Data[i]));
      RevData[i] := FRxData.Data[i];
      sDebug := sDebug + Format(' 0x%0.2x',[FRxData.Data[i]]);
    end;
    if Common.SystemInfo.MIPILog then Common.MLog(self.m_nPgNo,'[Source Code] MIPI READ DATA :'+sDebug);
  end
  else begin
    sDebug := Format('NG Code : %d - DataLength (%d)',[wdRet, FRxData.DataLen ]);
    Common.MLog(self.m_nPgNo,'[Source Code] MIPI READ DATA :'+sDebug);
  end;
  Result := wdRet;
end;

function TDongaPG.MipiWrite(sData: string): Integer;
var
  sSendCmd, sDebug : String;
  lstTemp : TStringList;
  buff : TIdBytes;
  i, nLen : Integer;
  wdRet : DWORD;
begin

  sSendCmd := sData;//StringReplace(sData, '0x', '$', [rfReplaceAll]);
  lstTemp := TStringList.Create;
  try
    ExtractStrings([' '], [], PWideChar(sSendCmd), lstTemp);
    nLen := lstTemp.Count;
    SetLength(buff, nLen);
    sDebug := '[Source Code] MIPI Write DATA :';
    for i := 0 to Pred(nLen) do begin
      buff[i] := StrToInt(lstTemp[i]);
      sDebug := sDebug + Format(' 0x%0.2x',[buff[i]]);
    end;
    wdRet := SendMIPIWrite(buff,nLen, 1000);
    Common.MLog(self.m_nPgNo,sDebug);
  finally
    lstTemp.Free;
  end;


  if wdRet <> WAIT_OBJECT_0 then begin
    sDebug := Format('MipiWrite Result is NG : 0x%0.2x ---- ',[wdRet]);
    Common.MLog(self.m_nPgNo,sDebug);
  end;
  Result := wdRet;
end;

function TDongaPG.Mipi_Ic_Write(sData: string): Integer;
var
  sSendCmd, sDebug : String;
  lstTemp : TStringList;
  buff : TIdBytes;
  i, nLen : Integer;
  wdRet : DWORD;
begin

  sSendCmd := sData;//StringReplace(sData, '0x', '$', [rfReplaceAll]);
  lstTemp := TStringList.Create;
  try
    ExtractStrings([' '], [], PWideChar(sSendCmd), lstTemp);
    nLen := lstTemp.Count;
    SetLength(buff, nLen);
    sDebug := '[Source Code] MIPI IC Write DATA :';
    for i := 0 to Pred(nLen) do begin
      buff[i] := StrToInt(lstTemp[i]);
      sDebug := sDebug + Format(' 0x%0.2x',[buff[i]]);
    end;
  finally
    lstTemp.Free;
  end;
  wdRet := SendMIPI_ICWrite(buff,nLen, 1000);
  Common.MLog(self.m_nPgNo,sDebug);
  if wdRet <> WAIT_OBJECT_0 then begin
    sDebug := Format('Mipi_Ic_Write Result is NG : 0x%0.2x ---- ',[wdRet]);
    Common.MLog(self.m_nPgNo,sDebug);
  end;
  Result := wdRet;
end;

procedure TDongaPG.ModelCrcChecking(nLen: Integer; buffer: TIdBytes);
var
  wCrcData, wGetCrc : Word;
  i, nData : Integer;
  sDebug : string;
  sModelData : AnsiString;
  bMcCheck, bMcOk : boolean;
begin
  nData := nLen div 2;
//  sDebug := 'CRC IS ';
  bMcOk := True;
  for i := 0 to Pred(nData) do begin
    CopyMemory(@wCrcData, @buffer[i*2], 2);
    bMcCheck := True;
    sDebug := '';
    case i of
      0 : begin    // model CRC.
        sModelData := Common.MakeModelData(Common.SystemInfo.TestModel);
        wGetCrc    := Common.crc16(sModelData, Length(sModelData));
        sDebug := Format('MODEL CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      1 : begin
        wGetCrc    := Common.m_Ver.CRC_mpt;
        sDebug := Format('mpt CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      2 : begin
        wGetCrc    := Common.m_Ver.CRC_mion;
        sDebug := Format('MION CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      3 : begin
        wGetCrc    := Common.m_Ver.CRC_mioff;
        sDebug := Format('MIOFF CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      4 : begin
        wGetCrc    := Common.m_Ver.CRC_pwon;
        sDebug := Format('PWRON CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      5 : begin
        wGetCrc    := Common.m_Ver.CRC_pwoff;
        sDebug := Format('PWROFF CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      6 : begin
        wGetCrc    := Common.m_Ver.CRC_miau;
        sDebug := Format('MIAU CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      7 : begin
        wGetCrc    := Common.m_Ver.CRC_otpw;
        sDebug := Format('OTPW CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      8 : begin
        wGetCrc    := Common.m_Ver.CRC_otpr;
        sDebug := Format('OTPR CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
      9 : begin
        wGetCrc    := Common.m_Ver.CRC_misc;
        sDebug := Format('SCR CRC IS %0.4x(PG)/%0.4x(File)',[wCrcData,wGetCrc]);
      end;
    end;
    if wGetCrc <> wCrcData then bMcCheck := False;

    if not bMcCheck then begin
      ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,1,sDebug);
    end;
    bMcOk := bMcOk and bMcCheck;
  end;
  if bMcOk then begin
    ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,0,'');
  end;



{        CopyMemory(@rcvCrcData, @str[26], 2);
        if rcvCrcData = 0 then begin
          ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,1,'ERROR!! PG dose not have Model data');
        end
        else begin
          sModelData := Common.MakeModelData(Common.SystemInfo.TestModel);
          crcData := Common.crc16(sModelData, Length(sModelData));
          if rcvCrcData <> crcData then begin
            ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,1,'ERROR!! PG CRC is differnt from Model CRC');
          end
          else begin
            sDebug := Format('DataLen(%d)',[wTotalLen]);
            ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,0,sDebug);
          end;
        end;}
end;

// nType : 1 - DP116, 2 - DP150
function TDongaPG.PocbEraseType(nType: Integer; nParam1 : Integer = 0; nParam2 : Integer = 0): Integer;
var
  i, j, nRet : Integer;
  sCmd, sDebug : string;
  btGetBuf : TIdBytes;
begin
  nRet := 0;
  case nType of
    1 : begin
      MIPIWrite('0x15 0xFF 0x10');
      MIPIWrite('0x05 0x28');//        # Display Off
      sleep(100);

      MIPIWrite('0x05 0x10');//        # Sleep in
      sleep(200);

      MIPIWrite('0x05 0x11');//         # Sleep out
      sleep(200);

      MIPIWrite('0x15 0x6D 0x00');
      sleep(100);

      MIPIWrite('0x15 0xFF 0x2B');
      MIPIWrite('0x39 0x06 0x00 0x00 0x00 0x08 0x00 0x00 0x00 0x00 0x00 0x00 0x00');//            # Initialing
      sleep(1);

      MIPIWrite('0x15 0xFF 0x10');
      MIPIWrite('0x39 0x6E 0x20');
      sleep(100);
      MIPIWrite('0x39 0x6A 0x40');
      sleep(10);
      MIPIWrite('0x39 0x6E 0x80');
      sleep(50);
      for i := 1 to 12 do begin

        MIPIWrite('0x15 0xFF 0x2B');
        MIPIWrite('0x39 0x06 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00');
        sleep(1);
        sCmd := format('0x39 0x06 0xD8 0x00 0x00 0x00 0x%0.2x 0x00 0x00 0x00 0x00 0x00 0x20',[i-1]);
        MIPIWrite(sCmd);
        sleep(500);
        for j := 1 to 27 do begin
          SetLength(btGetBuf,3);
          MIPIWrite('0x15 0xFF 0x10');
          MIPIWrite('0x37 0x01');
          nRet :=    MipiRead('0x06 0x6B 0x01',btGetBuf);
          if nRet <> WAIT_OBJECT_0 then begin
            sDebug := format('MIPI Read NG : 0x%0.4x',[nRet]);
            Common.MLog(Self.m_nPgNo,sDebug);
            Exit(1);
          end
          else begin
            sDebug := format('MIPI Read Data: 0x%0.2x',[btGetBuf[0]]);
            common.MLog(Self.m_nPgNo,sDebug);
          end;
          case btGetBuf[0] of
            4 : begin
              nRet := 0; // next Step.
              break;
            end;
            2 : begin
              sleep(100);
              nRet := 1;
            end
            else begin
              nRet := 2;
              sleep(100);
            end;
          end;
        end;
        if nRet <> 0 then begin
    //        m_nNgCode := 2;
    //        m_sNgMsg := 'Flash Erase Fail';
            break;
        end;
      end;

    end;
    2 : begin
      // 매크로닉스 Erase
      // Flash Erase
      //mipi.video.disable
      Sleep(35);
      MIPI_IC_WRITE('0x40 0x50 0x00'); // hs mode.
      //1 Sleep In
      MIPIWrite('0x05 0x10');
      Sleep(150);

      //3 Sleep out
      MIPIWrite('0x05 0x11');
      Sleep(150);

      // Change MIPI Speed
      //mipi.dsi 4 800 burst continuos dsc frc
      if nParam2 <> 1000 then SendMIPI_clk(nParam2);
      Sleep(250);
      MIPI_IC_WRITE('0x40 0x51 0x00'); // Lp mode.
      // MIPI 12 -> 8UI
      MIPIWrite('0x15 0xB0 188');
      MIPIWrite('0x39 0xE7 0x02');

      Sleep(100);

      MIPIWrite('0x15 0x59 0x03');
      MIPI_IC_WRITE('0x40 0x50 0x00'); // hs mode.
      Sleep(10);
      for i := 1 to 24 do begin
        //4 Write Enable
        MIPIWrite('0x15 0xB0 6');
        MIPIWrite('0x39 0xE1 0xAA 0x06 0x00 0x00 0x00 0x01');
        //5 Clear MAN_Start
        MIPIWrite('0x15 0xB0 6');
        MIPIWrite('0x39 0xE1 0x00 0x00 0x00 0x00 0x00 0x00');
        //6 32KB Block Erase 0x10000
        MIPIWrite('0x15 0xB0 6');
        case i of
          1 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x01 0x00 0x00 0x01');
          2 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x01 0x80 0x00 0x01');
          3 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x02 0x00 0x00 0x01');
          4 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x02 0x80 0x00 0x01');
          5 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x03 0x00 0x00 0x01');
          6 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x03 0x80 0x00 0x01'); //6 32KB Block Erase 0x38000
          7 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x04 0x00 0x00 0x01'); //6 32KB Block Erase 0x40000
          8 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x04 0x80 0x00 0x01'); //6 32KB Block Erase 0x48000
          9 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x05 0x00 0x00 0x01'); //6 32KB Block Erase 0x50000
          10 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x05 0x80 0x00 0x01');//6 32KB Block Erase 0x58000
          11 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x06 0x00 0x00 0x01'); //6 32KB Block Erase 0x60000
          12 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x06 0x80 0x00 0x01'); //6 32KB Block Erase 0x68000
          13 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x07 0x00 0x00 0x01'); //6 32KB Block Erase 0x70000
          14 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x07 0x80 0x00 0x01'); //6 32KB Block Erase 0x78000
          15 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x08 0x00 0x00 0x01'); //6 32KB Block Erase 0x80000
          16 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x08 0x80 0x00 0x01'); //6 32KB Block Erase 0x88000
          17 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x09 0x00 0x00 0x01'); //6 32KB Block Erase 0x90000
          18 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x09 0x80 0x00 0x01'); //6 32KB Block Erase 0x98000
          19 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x0A 0x00 0x00 0x01'); //6 32KB Block Erase 0xA0000
          20 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x0A 0x80 0x00 0x01'); //6 32KB Block Erase 0xA8000
          21 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x0B 0x00 0x00 0x01'); //6 32KB Block Erase 0xB0000
          22 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x0B 0x80 0x00 0x01'); //6 32KB Block Erase 0xB8000
          23 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x0C 0x00 0x00 0x01'); //6 32KB Block Erase 0xC0000
          24 : MIPIWrite('0x39 0xE1 0xAA 0x52 0x0C 0x80 0x00 0x01'); //6 32KB Block Erase 0xC8000
        end;

        Sleep(nParam1);

        //7 Clear MAN_Start
        MIPIWrite('0x15 0xB0 6');
        MIPIWrite('0x39 0xE1 0x00 0x00 0x00 0x00 0x00 0x00');
      end;
      MIPI_IC_WRITE('0x40 0x51 0x00'); // lp mode.
      Sleep(10);
      // Command Mode
      MIPIWrite('0x15 0x59 0x02');
      Sleep(120);
      //////////////////////////////////////////////////////////////////////////////////////////////////

      // Video Mode
      MIPIWrite('0x15 0x59 0x03');
      MIPI_IC_WRITE('0x40 0x50 0x00'); // hs mode.

      MIPIWrite('0x15 0xB0 5');
      MIPIWrite('0x39 0xE1 0x00');
      MIPIWrite('0x15 0xB0 5');
      MIPIWrite('0x39 0xE1 0x01');
      Sleep(500);

      //8 Flash Status Check
      //    Read Status Register
      MIPIWrite('0x39 0xB0 6');
      MIPIWrite('0x39 0xE1 0xAA 0x05 0x00 0x00 0x00 0x01');
      MIPIWrite('0x39 0xDD 0x00 0x00 0x00');
      MIPIWrite('0x39 0xB0 6');
      MIPIWrite('0x39 0xE1 0x00 0x00 0x00 0x00 0x00 0x00');
      Sleep(100);

      // Command Mode
      MIPI_IC_WRITE('0x40 0x51 0x00'); // lp mode.
      Sleep(10);
      MIPIWrite('0x15 0x59 0x02');
      Sleep(10);
      MIPI_IC_WRITE('0x40 0x50 0x00'); // hs mode.

      MIPIWrite('0x39 0xB0 19');

      // NG 발생시 Retry.
      for i := 1 to 4 do begin
        //MIPIWrite('0x15 0x37 0x05');
        SetLength(btGetBuf,10);
        nRet :=    MIPIRead('0x06 0xDD 0x05', btGetBuf);
        if nRet = WAIT_OBJECT_0 then begin
          // 0xF4 0x2C 0xBF 0x20 0x00
          if (btGetBuf[0] = $f4) and (btGetBuf[1] = $2C) and (btGetBuf[2] = $Bf) and (btGetBuf[3] = $20) then begin
            // OK.
            Common.MLog(Self.m_nPgNo, 'Erase Verify OK!');;
            Break;
          end
          else begin
            nRet := 1;
          end;
          //Sleep(50);
        end;
      end;

     // MIPI_IC_WRITE('0x40 0x51 0x00'); // lp mode.
    end;
  end;
  Result := nRet;
end;

procedure TDongaPG.ReadData(const str: TIdBytes);
var
  btFrame : Byte;
  wPgNo, wSigId, wTotalLen, wLen,i : Word;
  sTemp, sDebug, sMsg             : string;
  ReadPwrData                     : ReadVoltCurr;
  wErrNo  ,crcData, rcvCrcData    : Word;
  nCurVal                         : Integer;
  sModelData                      : Ansistring;
  btaBuff                         : TIdBytes;
begin
  CopyMemory(@wPgNo,  @str[0], 2);
  CopyMemory(@wSigId, @str[2], 2);
  CopyMemory(@wTotalLen,   @str[4], 2);
  m_nConnectCheck := 0; //아무Sig_Id나 오면 Clear Count;

//  end;
  case wSigId of
    SIG_CONCHECKACK: begin// Conn Check Ack
      // 초기 실행시 Version없으면 Version 측정 하도록 하자.
      if m_sFwVer = '' then SendFwVersionCheckReq;
    end;

    SIG_FW_VERSION_ACK: begin
      // CRC Check.
      if wTotalLen > 26 then begin
        SetLength(btaBuff,20);
        CopyMemory(@btaBuff[0], @str[26], wTotalLen-20);
        ModelCrcChecking(wTotalLen-20,btaBuff);
      end
      else begin
        CopyMemory(@rcvCrcData, @str[26], 2);
        rcvCrcData := 36772;
        if rcvCrcData = 0 then begin
          ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,1,'ERROR!! PG dose not have Model data');
        end
        else begin
          sModelData := Common.MakeModelData(Common.SystemInfo.TestModel);
          crcData := Common.crc16(sModelData, Length(sModelData));
          if rcvCrcData <> crcData then begin

            //ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,1,'ERROR!! PG CRC is differnt from Model CRC');
            sTemp:= format('ERROR!! PG CRC(%x) is differnt from Model CRC(%x)', [rcvCrcData, crcData]);
            ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,1,sTemp);
          end
          else begin
            sDebug := Format('DataLen(%d)',[wTotalLen]);
            ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL,0,sDebug);
          end;
        end;
      end;

      sTemp := '';
      m_sFwVer := '';
      for i := 1 to DefPG.FW_VER_LEN do begin
        if ((i mod 4) = 1) and (i <> DefPG.FW_VER_LEN) then begin
          sTemp := sTemp + '  ';
          m_sFwVer := m_sFwVer + ',';
        end;
        sTemp := sTemp + Char(str[DefPG.DATA_POS_FIRST+i-1]);
        m_sFwVer := m_sFwVer + Char(str[DefPG.DATA_POS_FIRST+i-1]);
      end;
      sTemp := sTemp + '    ';
      // 강제로 Ack 처리 하자.
      FRxData.NgOrYes := DefPg.CMD_RESULT_ACK;
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
//      UdpServer.OnRevPgConnection(wPgNo,1,sTemp);
      ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_CONNECTION,1,sTemp);  // param 0 ==> connection. 2 ==> Disconnect , 1 FW Version.

      //Common.MLog(Self.m_nPgNo, 'Check Pattern Version CRC');
      //SendPatternVersionCheckReq;

    end;

    SIG_PATTERN_VERSION_ACK: begin
      CopyMemory(@rcvCrcData, @str[6], 2);
      if rcvCrcData <> Common.m_Ver.CRC_Pat then begin
        //sTemp:= format('ERROR!! Pattern CRC(%x) is differnt from Model CRC(%x)', [rcvCrcData, Common.m_Ver.CRC_Pat]);
        sTemp := Format('Pattern CRC IS %0.4x(PG)/%0.4x(File)',[rcvCrcData, Common.m_Ver.CRC_Pat]);
        ShowTestWindow(DefCommon.MSG_MODE_DIFF_MODEL, 1, sTemp);
      end
      else begin

      end;
    end;

    SIG_MODELINFO_ACK:
    begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;

    SIG_PATTERN_LOAD_ACK:
    begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;

    SIG_READ_VOLTCUR_ACK: // VoltCurReadAck
    begin
      CopyMemory(@ReadPwrData, @str[6], SizeOf(ReadPwrData));
//      UdpServer.OnPwrReadEvent(wPgNo,ReadPwrData);
      m_ReadVoltCurr := ReadPwrData;

      if m_bIsPwrEvent then begin
        m_ReadVoltC.VCI   := m_ReadVoltCurr.VCI   / 1000;
        m_ReadVoltC.DVDD  := m_ReadVoltCurr.DVDD  / 1000;
        m_ReadVoltC.VDD   := m_ReadVoltCurr.VDD   / 1000;
        m_ReadVoltC.VPP   := m_ReadVoltCurr.VPP   / 1000;
        m_ReadVoltC.VBAT  := m_ReadVoltCurr.VBAT  / 1000;
        m_ReadVoltC.VNEG  := m_ReadVoltCurr.VNEG  / 1000;

        m_ReadVoltC.IVCI   := (m_ReadVoltCurr.IVCI   / 1000);
        m_ReadVoltC.IDVDD  := (m_ReadVoltCurr.IDVDD  / 1000);
        m_ReadVoltC.IVDD   := (m_ReadVoltCurr.IVDD   / 1000);
        m_ReadVoltC.IVPP   := (m_ReadVoltCurr.IVPP   / 1000);
        m_ReadVoltC.IVBAT  := (m_ReadVoltCurr.IVBAT  / 1000);
        m_ReadVoltC.IVNEG  := m_ReadVoltCurr.IVNEG  / 1000;

        m_ReadVoltC.ELVDD := m_ReadVoltCurr.ELVDD  / 1000;
        m_ReadVoltC.ELVSS := m_ReadVoltCurr.ELVSS  / 1000;
        m_ReadVoltC.DDVDH := m_ReadVoltCurr.DDVDH  / 1000;

        m_ReadVoltC.IELVDD := (m_ReadVoltCurr.IELVDD  / 1000);
        m_ReadVoltC.IELVSS := (m_ReadVoltCurr.IELVSS  / 1000);
        m_ReadVoltC.IDDVDH := (m_ReadVoltCurr.IDDVDH  / 1000);

        sMsg := sMsg + format(' VCI(%0.3f) IVCI(%0.3f)',    [m_ReadVoltC.VCI,  m_ReadVoltC.IVCI]);
        sMsg := sMsg + format(' DVDD(%0.3f) IDVDD(%0.3f)',  [m_ReadVoltC.DVDD, m_ReadVoltC.IDVDD]);
        sMsg := sMsg + format(' VDD(%0.3f) IVDD(%0.3f)',    [m_ReadVoltC.VDD,  m_ReadVoltC.IVDD]);
        sMsg := sMsg + format(' VPP(%0.3f) IVPP(%0.3f)',    [m_ReadVoltC.VPP,  m_ReadVoltC.IVPP]);
        sMsg := sMsg + format(' VBAT(%0.3f) IVBAT(%0.3f)',  [m_ReadVoltC.VBAT, m_ReadVoltC.IVBAT]);
        //sMsg := sMsg + format(' VNEG(%0.3f) IVNEG(%0.3f)',   [m_ReadVoltC.VNEG,  m_ReadVoltC.IVNEG]);
        //sMsg := sMsg + format(' ELVDD(%0.3f) IELVDD(%0.3f)', [m_ReadVoltC.ELVDD, m_ReadVoltC.IELVDD]);
        //sMsg := sMsg + format(' ELVSS(%0.3f) IELVSS(%0.3f)', [m_ReadVoltC.ELVSS, m_ReadVoltC.IELVSS]);
        //sMsg := sMsg + format(' DDVDH(%0.3f) IDDVDH(%0.3f)', [m_ReadVoltC.DDVDH, m_ReadVoltC.IDDVDH]);
        Common.MLog(Self.m_nPgNo, '[Measure Power] ' + sMsg);

        FRxData.NgOrYes := DefPg.CMD_RESULT_ACK;
    // 12, 54
        SetEvent(m_hPwEvent);
      end;
      ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_VOLCUR,0,'');
    end;
(*  //remove by checkmate 20191115: for using SIG_MIPI_WRITE_HS_ACK (0x7F)
    SIG_FLASH_READ_ACK : begin
//      FRxData.NgOrYes := DefPg.CMD_RESULT_ACK;
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);  // NAK or ACK.
      if PG[wPgNo].FRxData.NgOrYes = DefPg.CMD_RESULT_ACK then begin
        // 4 byte : Flash Read Address.          // ord(str[7])
        // 2 byte : Flash Read Length.           // ord(str[11]);
        // ~ : Data.                             // ord(str[13]);
        CopyMemory(@wLen,@Str[11],2);
        PG[wPgNo].FRxData.DataLen := wLen;
        SetLength(FRxData.Data,wLen);
        CopyMemory(@FRxData.Data[0],@Str[13],wLen);

      end;
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
*)
    SIG_TOUCH_ACK : begin
      PG[wPgNo].FRxTouchData.NgOrYes := ord(str[6]);
      // NG 발생시 Retry를 위하여 바로 Error 처리 하자.
      if PG[wPgNo].FRxTouchData.NgOrYes <> DefPG.CMD_RESULT_ACK then begin
        SetEvent(PG[wPgNo].m_hEvnt);
      end
      else begin
//        CopyMemory(@btModel,  @str[7], 1);
//        Copymemory(@btIdx,    @str[8], 1);
//        Copymemory(@btFreq,   @str[9], 1);
        Copymemory(@btFrame,  @str[10], 1);
        Copymemory(@wLen,     @str[11], 2);
        PG[wPgNo].FRxTouchData.Data[btFrame].IsRev   := True;
        PG[wPgNo].FRxTouchData.Data[btFrame].RevLen  := wLen;
        Copymemory(@PG[wPgNo].FRxTouchData.Data[btFrame].Frame[0], @str[13], wLen);
        // 원하는 Frame을 다받으면 해당 데이터를 가지고 계산 할 수 있도록 Event 발생하도록 하자.
        if PG[wPgNo].FRxTouchData.FrameCnt = PG[wPgNo].FRxTouchData.RevFrameCnt then begin
          SetEvent(PG[wPgNo].m_hEvnt);
        end;
        Inc(PG[wPgNo].FRxTouchData.RevFrameCnt);
      end;
    end;
    SIG_POCB_DOWN_ACK : begin
      FRxData.NgOrYes := str[6];

      FRxData.DataLen := wTotalLen-1;
//      sDebug := Format('FRxData.NgOrYes (%d), Len(%d) : ',[FRxData.NgOrYes,FRxData.DataLen]);
//      for i := 0 to (6+FRxData.DataLen) do begin
//        sDebug := sDebug + Format('%0.2x ',[str[i]]);
//      end;
//      Common.MLog(0,sDebug);
      if FRxData.DataLen > 0 then begin
        SetLength(FRxData.Data,wTotalLen);
        CopyMemory(@FRxData.Data[0],@Str[7],FRxData.DataLen);
      end;
      if m_bIsPocbEvent then SetEvent(m_hPocbEvent);
    end;
    SIG_PWR_ON_ACK : begin
      FRxData.NgOrYes := DefPg.CMD_RESULT_ACK;
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
//
    SIG_DISPLAY_PATTERN_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_SINGLE_PATTERN_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_ALARM_REPORT: //$a1 AlarmReport HW->PC
    begin
      CopyMemory(@wErrNo,  @str[7], 2);
      nCurVal := 0;
      // 이전 버젼과 호환성 맞게 하기 위하여 길이 Check. Total Data size 14 bytes
//      if wTotalLen > 9 then begin
        CopyMemory(@nCurVal,  @str[9], 4);
        sTemp := GetAlarmStr(wErrNo,nCurVal);
//      end
//      else begin
//        sTemp := GetAlarmStr(wErrNo);
//      end;
//      SendPowerReq(0); // PG에서 끄기로 함.
      Self.SetPowerMeasureTimer(False);
      ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_ALARM,0,sTemp);
    end;
    SIG_FUSING_ACK: begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;

    SIG_FW_DOWNLOAD_ACK: begin
      FRxData.NgOrYes := ord(str[6]);
      if FRxData.DataLen > 0 then begin
        SetLength(FRxData.Data,wTotalLen);
        CopyMemory(@FRxData.Data[0],@Str[7],wTotalLen-1);
      end;
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_POCB_DATA_W_REV : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_PG_RESET_ACK: begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_POCB_FUNC_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      PG[wPgNo].FRxData.RootCause := ord(str[7]);
      SetLength(FRxData.Data,wTotalLen);
      FRxData.DataLen := wTotalLen;
      if FRxData.DataLen > 0 then CopyMemory(@FRxData.Data[0],@Str[6],wTotalLen);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_POCB_FUNC2_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
//      PG[wPgNo].FRxData.RootCause := ord(str[7]);
      SetLength(FRxData.Data,wTotalLen-1);
      FRxData.DataLen := wTotalLen-1;
      if FRxData.DataLen > 0 then CopyMemory(@FRxData.Data[0],@Str[7],wTotalLen-1);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_CHANNEL_ONOFF_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_TOUCH_FW_DOWN_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_ID_UPDATE_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_PATTERN_ROLL_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_GPIO_SET_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;

    // Touch검사와 화상검사의 병렬진행을 위하여 다른 이벤트 사용
    SIG_I2C_WRITE_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsTouchEvent then SetEvent(PG[wPgNo].m_hTouchEvnt);
    end;
    SIG_I2C_READ_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      //Save data
      SetLength(FRxData.Data,wTotalLen);
      sTemp := Format('[READ I2C DATA] RET(%d)',[PG[wPgNo].FRxData.NgOrYes]);

      FRxData.DataLen := wTotalLen-1;
      if FRxData.DataLen > 0 then CopyMemory(@FRxData.Data[0],@Str[7],wTotalLen-1);
      for i := 0 to Pred(FRxData.DataLen) do begin
        sTemp := sTemp + Format(' 0x%0.2x',[FRxData.Data[i]]);
      end;
//      Common.MLog(wPgNo,sTemp);
      if m_bIsTouchEvent then SetEvent(PG[wPgNo].m_hTouchEvnt);
    end;
    SIG_MIPI_IC_WRITE_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsTouchEvent then SetEvent(PG[wPgNo].m_hTouchEvnt);
    end;
    SIG_MIPI_CLK_REV : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsTouchEvent then SetEvent(PG[wPgNo].m_hTouchEvnt);
    end;
    SIG_MIPI_WRITE_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsTouchEvent then SetEvent(PG[wPgNo].m_hTouchEvnt);
    end;
    SIG_MIPI_WRITE_HS_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsTouchEvent then SetEvent(PG[wPgNo].m_hTouchEvnt);
    end;
    SIG_MIPI_READ_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      //Save data
      SetLength(FRxData.Data,wTotalLen);
      FRxData.DataLen := wTotalLen-1;
      if FRxData.DataLen > 0 then CopyMemory(@FRxData.Data[0],@Str[7],wTotalLen-1);
      if m_bIsTouchEvent then SetEvent(PG[wPgNo].m_hMipiReadEvnt);
    end;
    SIG_OTP_WRITE_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_OTP_READ_ACK : begin
      PG[wPgNo].FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(PG[wPgNo].m_hEvnt);
    end;
    SIG_POWERCMD_SET_ACK,
    SIG_CHANGE_VOLTSET_ACK,
    SIG_ENABLE_VOLTSET_ACK: begin
      FRxData.NgOrYes := ord(str[6]);
      if m_bIsEvent then SetEvent(m_hEvnt);
    end;
  end;
end;

function TDongaPG.SendBuffData(const transData: TFileTranStr) : Boolean;
var
//  TxBuff : TArray<System.Byte>;
  TxBuff : array[0..DefPG.PACKET_SIZE] of Byte;
  j, nFileSize, nTransType       : Integer;
  nDiv, nMod                  : Integer;

  cdCheckSum, nRet                : LongWord;
  sFileName                         : AnsiString;
//  nTotalCnt                : Integer;
  sTemp                             : string;
//  btTemp                            : Byte;
begin
//  nTotalCnt := 0;
//  nCurCnt   := 0;
  tmAliveCheck.Enabled := False;

  Self.Status := pgWait;

  nFileSize := transData.TotalSize;

  FillChar(TxBuff,DefPG.PACKET_SIZE,0);
  sFileName := AnsiString(Trim(string(transData.fileName)));
  nFileSize := transData.TotalSize;

  TxBuff[0] :=  Byte(Length(sFileName));
  CopyMemory(@TxBuff[0],@sfileName[1],32);
  CopyMemory(@TxBuff[32],@nFileSize,4);
  nTransType := transData.TransType;


  nRet := CheckCmdAck(procedure begin SendFileTransReq(SIG_FW_DOWNLOAD,nTransType,DefPG.FUSING_MODE_START,0,36,TxBuff);end,
                SIG_FW_DOWNLOAD,5000,2);
  if  nRet <> WAIT_OBJECT_0 then begin
//    CodeSite.Send('Error1');
    m_nConnectCheck := 0;
    tmAliveCheck.Enabled := True;
    Self.Status := pgDone;
    // SendFileTrans(wType,wMode,wIdx,wTxLen : Word; TxBuffer: array of Byte);
    // nSid, nDelay, nRetry: Integer)
//    ShowDownLoadStatus(DefPG.MSG_TYPE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,format('Fail..%0.02x',[nRet]),True);
    Exit(False);
  end;
  Sleep(100);
//  Inc(nCurCnt);
//  sTemp := Format('Start ...%s',[sfileName]);
//  ShowDownLoadStatus(DefPG.MSG_TYPE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,sTemp);

  nDiv := nFileSize div DefPG.PACKET_SIZE;
  nMod := nFileSize mod DefPG.PACKET_SIZE;
//  Sleep(350);
  for j := 1 to nDiv do begin
//    CodeSite.SendMsg('[POCBWRT Download] Start');
    CopyMemory(@TxBuff[0],@transData.Data[(j-1)*DefPG.PACKET_SIZE],DefPG.PACKET_SIZE);
//    CodeSite.SendMsg('[POCBWRT Download] SendData');
    SendFileTransReq(SIG_FW_DOWNLOAD,nTransType,DefPG.FUSING_MODE_DOWNLOAD,0,DefPG.PACKET_SIZE,TxBuff);
    Sleep(7);
//    Inc(nCurCnt);
//    if nFileSize > 1024 then
//      sTemp := Format('%dKB/%dKB...(%d/%d)',[(j*DefPG.PACKET_SIZE) div 1024,nFileSize div 1024,1,1])
//    else
//      sTemp := Format('%d Bytes/%d Bytes...(%d/%d)',[(j*DefPG.PACKET_SIZE),nFileSize,1,1]);

//    ShowDownLoadStatus(DefPG.MSG_TYPE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,sTemp);
//    Sleep(50);
    if self.Status = pgForceStop then Exit(False);
  end;
  if nMod > 0 then begin
    FillChar(TxBuff,DefPG.PACKET_SIZE,0);
    CopyMemory(@TxBuff[0],@transData.Data[nDiv*DefPG.PACKET_SIZE],nMod);
    SendFileTransReq(SIG_FW_DOWNLOAD,nTransType,DefPG.FUSING_MODE_DOWNLOAD,0,nMod,TxBuff);
    Sleep(7);
//      if transData[i].TransMode = DefCommon.DOWNLOAD_TYPE_BMP then begin
//        Common.SleepMicro(650);
//      end
//      else begin
//        Sleep(200);
//      end;
//    Inc(nCurCnt);
    if self.Status = pgForceStop then Exit(False);
//    if nFileSize > 1024 then
//      sTemp := Format('%d Bytes/%d Bytes...(%d/%d)',[nFileSize div 1024,nFileSize div 1024,1,1])
//    else
//      sTemp := Format('%d Bytes/%d Bytes...(%d/%d)',[nFileSize,nFileSize,1,1]);
//    ShowDownLoadStatus(DefPG.MSG_TYPE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,sTemp);
  end;
  Sleep(100);
  FillChar(TxBuff,DefPG.PACKET_SIZE,0);
  sFileName := AnsiString(Trim(string(transData.fileName)));
  nFileSize := transData.TotalSize;
  cdCheckSum := transData.CheckSum;
  CopyMemory(@TxBuff[0],@sfileName[1],32);
  CopyMemory(@TxBuff[32],@cdCheckSum,4);
  nTransType := transData.TransType;

  sTemp := Format('%d images',[1]);
  if CheckCmdAck(procedure begin SendFileTransReq(SIG_FW_DOWNLOAD,nTransType,DefPG.FUSING_MODE_END,0,36,TxBuff);end,
                  SIG_FW_DOWNLOAD,5000,2) <> WAIT_OBJECT_0 then begin
      sTemp := 'Fail to download '+ sTemp;
//      CodeSite.Send('Error2');
      m_nConnectCheck := 0;
      tmAliveCheck.Enabled := True;
      Self.Status := pgDone;
    Exit(False);
  end
  else begin
//    Inc(nCurCnt);
    sTemp := 'Success to download '+ sTemp;
    if self.Status = pgForceStop then Exit(False);
  end;

//  ShowDownLoadStatus(DefPG.MSG_TYPE_TRANS_DOWNLOAD_STATUS,nTotalCnt,nTotalCnt,sTemp,True);
  m_nConnectCheck := 0;
  tmAliveCheck.Enabled := True;
  Self.Status := pgDone;

  Result := True;
end;

procedure TDongaPG.SendByteData(buff: TIdBytes; nDataLen: Integer);
begin  
  SendData(buff);
end;

function TDongaPG.SendChangeVoltSet(nSet, nSelect, nValue, nWait, nRty: Integer): DWORD;
begin
  Result := CheckCmdAck(
    procedure
    var
      TxBuf : TIdBytes;
      Sig_Id, nLen : Word;
    begin
      nLen := 4;                   
      SetLength(TxBuf, nLen + 4);
      Sig_Id := SIG_CHANGE_VOLTSET;
      CopyMemory(@TxBuf[0], @Sig_Id, 2);
      CopyMemory(@TxBuf[2], @nLen, 2);
      TxBuf[4]  := nSet;
      TxBuf[5]  := nSelect;
      CopyMemory(@TxBuf[6], @nValue, 2);
      SendData(TxBuf);      
    end,
    SIG_CHANGE_VOLTSET, nWait, nRty);

end;

function TDongaPG.SendChannelOff: DWORD;
var
  nRtn : DWORD;
begin
  tmPowerMeasure.Enabled := False;
  nRtn := CheckCmdAck(SendChannelOffReq, SIG_CHANNEL_ONOFF,500,1);

  Result := nRtn;
end;

// channel Off시 사용. Power off. 왜그런지 모르겠으나 사정이 있겠지.. 자세한 내용은 장인석 수석...
procedure TDongaPG.SendChannelOffReq;
var
	TxBuf : TIdBytes;
	Sig_Id, nLen, wPwr : Word;
begin
	setLength(TxBuf, 8);
	nLen := 4;
	Sig_Id := SIG_CHANNEL_ONOFF;
	CopyMemory(@TxBuf[0], @Sig_Id, 2);
	CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4] := 0;  // 0 : power off, 1 : power on.
  TxBuf[5] := Byte(m_nPgNo);
  wPwr := $ffff;
  CopyMemory(@TxBuf[6], @wPwr, 2);
  SendData(TxBuf);
end;

procedure TDongaPG.SendConnectionCheckReq;
var
	TxBuf : TIdBytes;
	Sig_Id, nLen : Word;
begin
	setLength(TxBuf, 4);
	nLen := 0;
	Sig_Id := SIG_CONCHECKREQ;
	CopyMemory(@TxBuf[0], @Sig_Id, 2);
	CopyMemory(@TxBuf[2], @nLen, 2);
  SendData(TxBuf,False);
end;

procedure TDongaPG.SendData(TxBuf : TIdBytes; bDebug : Boolean = True);
var
  sTemp : string;
  wSigId, wLen : Word;
  TxBuffer : TIdBytes;
begin
  m_nTickSendData:= GetTickCount; //최종 전송 시간

  SetLength(TxBuffer,Length(TxBuf));
  CopyMemory(@TxBuffer[0],@TxBuf[0],Length(TxBuf));
//  m_ABinding.SendTo(Self.IP, UDP_DEFAULT_PORT, TxBuffer);


//  if m_ABinding = nil then Exit;
//  if Status = pgDisconnect then Exit;

	try

  if Common.SimulateInfo.Use_PG then
  begin
    //UdpServer.udpSvr.SendBuffer(Self.IP, Common.SimulateInfo.PG_BasePort + m_nPgNo, TxBuf);
    UdpServer.udpSvr.SendBuffer(Self.IP, PORT, TxBuf);
  end else
  begin
    m_ABinding.SendTo(Self.IP, UDP_DEFAULT_PORT, TxBuffer);
  end;
	except
//    CodeSite.Send('[PC->PG] Data Sending Exception Error! PG NO :' + IntToStr(Self.m_nPgNo));
//		OutputDebugString(PChar(('[PC->PG] Data Sending Exception Error! PG NO :' + IntToStr(Self.m_nPgNo))));
	end;
{$IFDEF DEBUG}
  if bDebug then begin
    CopyMemory(@wSigId,@TxBuf[0],2);
    CopyMemory(@wLen,@TxBuf[2],2);
    sTemp := format('[Send] : PG(%d), Id(%0.2x), Len (%d)',[Self.m_nPgNo+1,wSigId,wLen]);
//    OutputDebugString(PChar(sTemp));
    CodeSite.SendMemoryAsHex(sTemp,@TxBuf[0],wLen+4);
  end;
{$ENDIF}
end;

procedure TDongaPG.SendDisplayReq(nIdx: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id, nLen, wIdx, wTemp  : Word;
begin
  nLen := 5;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_DISPLAY_PATTERN;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4]  := 1; // 0 : display off, 1 : display on.
  wIdx := nIdx;
  CopyMemory(@TxBuf[5], @wIdx, 2);
  wTemp := $ffff;
  CopyMemory(@TxBuf[7], @wTemp, 2);
  SendData(TxBuf);
end;

function TDongaPG.SendEnableVoltSet(nSet, nSelect, nWait, nRty: Integer): DWORD;
begin
  Result := CheckCmdAck(
    procedure
    var
      TxBuf : TIdBytes;
      Sig_Id, nLen : Word;
    begin
      nLen := 2;
      SetLength(TxBuf, nLen + 4);
      Sig_Id := SIG_ENABLE_VOLTSET;
      CopyMemory(@TxBuf[0], @Sig_Id, 2);
      CopyMemory(@TxBuf[2], @nLen, 2);
      TxBuf[4]  := nSet;
      TxBuf[5]  := nSelect;
      SendData(TxBuf);
    end,
    SIG_ENABLE_VOLTSET, nWait, nRty);

end;

procedure TDongaPG.SendErrFlagReq(nSet, nFrame, nStart, nEnd: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : word;
  nDataLen : Integer;
begin
  nDataLen := 4;
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_ERR_FLAG_CHECK;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  TxBuf[4] := Byte(nSet);
  TxBuf[5] := Byte(nFrame);
  TxBuf[6] := Byte(nStart);
  TxBuf[7] := Byte(nEnd);
  SendData(TxBuf);
end;

function TDongaPG.SendErrorFlag(nSet, nFrame, nStart, nEnd, nWait: Integer): DWORD;
begin
  Result := CheckCmdAck(procedure begin SendErrFlagReq(nSet, nFrame,nStart, nEnd); end, SIG_ERR_FLAG_CHECK, nWait, 1);

end;

function TDongaPG.SendDisplayPat(nIdx, nWait,nRty: Integer): DWORD;
begin
  Result := CheckCmdAck(procedure begin SendDisplayReq(nIdx);end, SIG_DISPLAY_PATTERN,nWait,nRty);
end;

procedure TDongaPG.SendFileTransReq(wSigId,wType,wMode,wIdx,wTxLen : Word; TxBuffer: array of Byte);
var
  TxBuf : TIdBytes;
  nSigId, nLen : Integer;
//  sDebug : string;
  i: Integer;
begin
  // for debuging.
//  sDebug := 'SendData:';
  if wMode in [FUSING_MODE_START, FUSING_MODE_END] then begin
    nLen  := 40;
    nSigId := wSigId;
    setlength(TxBuf, nLen+4);
    CopyMemory(@TxBuf[0], @nSigId, 2);
    CopyMemory(@TxBuf[2], @nLen, 2);
    TxBuf[4] := Byte(wType);
  end
  else begin
    setlength(TxBuf, wTxLen);
  end;
  case wMode of
    DefPG.FUSING_MODE_START : begin
      TxBuf[5] := Byte('S');
      CopyMemory(@TxBuf[6], @wIdx, 2);
      CopyMemory(@TxBuf[8], @TxBuffer[0], wTxLen);
//      for i := 0 to 43 do begin
//        sDebug := sDebug + Format('%0.2x ',[TxBuf[i]]);
//      end;
      SendData(TxBuf);
    end;
    DefPG.FUSING_MODE_END : begin
      TxBuf[5] := Byte('E');
      CopyMemory(@TxBuf[6], @wIdx, 2);
      CopyMemory(@TxBuf[8], @TxBuffer[0], wTxLen);
      SendData(TxBuf);
//      for i := 0 to 43 do begin
//        sDebug :=  sDebug + Format('%0.2x ',[TxBuf[i]]);
//      end;
    end
    else begin
      CopyMemory(@TxBuf[0], @TxBuffer, wTxLen);
      SendData(TxBuf,False);
//      for i := 0 to Pred(wTxLen) do begin
//        sDebug :=  sDebug + Format('%0.2x ',[TxBuf[i]]);
//      end;
    end;
  end;
//  DebugPgLog(sDebug);

end;

function TDongaPG.SendFlashRead(nAddress, nLen: Integer): DWORD;
begin
  Result := CheckCmdAck(procedure begin SendFlashReadReq(nAddress, nLen); end,SIG_FLASH_READ ,3000,2);
end;

function TDongaPG.SendFlashReadReq(nAddress, nLen: Integer): Integer;
var
	TxBuf : TIdBytes;
	Sig_Id, nTotalLen, wTemp : Word;
//	i : Integer;
//	sDebug: string;
//	nFlashAddr : Integer;
begin
  try
    nTotalLen := 6;
    SetLength(TxBuf, nTotalLen+4);
    Sig_Id := SIG_FLASH_READ;
    CopyMemory(@TxBuf[0], @Sig_Id,2);
    CopyMemory(@TxBuf[2], @nTotalLen, 2);

    CopyMemory(@TxBuf[4],@nAddress , 4);

    wTemp := word(nLen);
    CopyMemory(@TxBuf[8], @wTemp, 2);
    SendData(TxBuf);
    Result := 0;
  except
    Result := -1;
  end;

end;

procedure TDongaPG.SendFwVersionCheckReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 0;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_FW_VERSION_REQ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  SendData(TxBuf);
end;

procedure TDongaPG.SendPatternVersionCheckReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 0;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_PATTERN_VERSION_REQ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  SendData(TxBuf);
end;

function TDongaPG.SendGPIOSet(nSet, nSelect, nWait: Integer): DWORD;
begin
  Result := CheckCmdAck(procedure begin SendGPIOSetReq(nSet, nSelect); end, SIG_GPIO_SET, nWait, 1);
end;

procedure TDongaPG.SendGPIOSetReq(nSet, nSelect: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : word;
  nDataLen : Integer;
begin
  nDataLen := 2;
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_GPIO_SET;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @nSet, 1);
  CopyMemory(@TxBuf[5], @nSelect, 1);
  SendData(TxBuf);
end;
function TDongaPG.SendI2CWrite(buff : TIdBytes; nDataLen : Integer;nWait: Integer): DWORD;
begin
  Result := CheckTouchCmdAck(procedure begin SendI2CWriteReq(buff,nDataLen); end, SIG_I2C_WRITE, nWait, 1);
end;

{0:I2C0, 1:I2C1, 2:I2C2
0:1byte, 1:2byte
0:Normal
Device Address
MSB Register Address (Add_size:0 => 0x00)
LSB Register Address
Write Data Length
n개 Write Data}
procedure TDongaPG.SendI2CWriteReq(buff : TIdBytes;nDataLen : Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : word;
begin
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_I2C_WRITE;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @buff[0], nDataLen);
  SendData(TxBuf);
end;

function TDongaPG.SendI2CRead(buff : TIdBytes;nDataLen, nWait: Integer): DWORD;
begin
  Result := CheckTouchCmdAck(procedure begin SendI2CReadReq(buff,nDataLen); end, SIG_I2C_READ, nWait, 2);
end;

procedure TDongaPG.SendI2CReadReq(buff : TIdBytes; nDataLen : Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : Integer;
begin
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_I2C_READ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @buff[0], nDataLen);
  SendData(TxBuf);
end;

function TDongaPG.SendMIPIWrite(buff : TIdBytes; nDataLen : Integer; nWait: Integer; nRty : Integer): DWORD;
begin
  Result := CheckTouchCmdAck(procedure begin SendMIPIWriteReq(buff, nDataLen); end, SIG_MIPI_WRITE, nWait, nRty);
end;

procedure TDongaPG.SendMIPIWriteReq(buff : TIdBytes; nDataLen : Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : Word;
begin
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_MIPI_WRITE;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @buff[0], nDataLen);
  SendData(TxBuf);
end;

function TDongaPG.SendMIPIWriteHS(buff : TIdBytes; nDataLen : Integer; nWait: Integer; nRty : Integer): DWORD;
begin
  Result := CheckTouchCmdAck(procedure begin SendMIPIWriteHSReq(buff, nDataLen); end, SIG_MIPI_WRITE_HS, nWait, nRty);
end;

procedure TDongaPG.SendMIPIWriteHSReq(buff : TIdBytes; nDataLen : Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : Word;
begin
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_MIPI_WRITE_HS;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @buff[0], nDataLen);
  SendData(TxBuf);
end;

function TDongaPG.SendMIPI_clk(nClk, nWait: Integer): DWORD;
begin
  Result := CheckTouchCmdAck(procedure begin SendMIPI_clkReq(nClk); end, SIG_MIPI_CLK_REQ, nWait, 2);
end;

procedure TDongaPG.SendMIPI_clkReq(nClk: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id, wData, wDataLen : Word;
begin
  wDataLen := 2;
  Setlength(TxBuf, wDataLen + 4);
  Sig_Id := SIG_MIPI_CLK_REQ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @wDataLen, 2);
  wData := word(nClk);
  CopyMemory(@TxBuf[4], @wData, 2);
  SendData(TxBuf);
end;

function TDongaPG.SendMIPI_ICWrite(buff: TIdBytes; nDataLen, nWait: Integer): DWORD;
begin
  Result := CheckTouchCmdAck(procedure begin SendMIPI_ICWriteReq(buff, nDataLen); end, SIG_MIPI_IC_WRITE_REQ, nWait, 2);
end;

procedure TDongaPG.SendMIPI_ICWriteReq(buff: TIdBytes; nDataLen: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : Word;
begin
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_MIPI_IC_WRITE_REQ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @buff[0], nDataLen);
  SendData(TxBuf);
end;

function TDongaPG.SendMIPIRead(buff : TIdBytes;nDataLen : Integer; nWait: Integer): DWORD;
begin
  Result := CheckTouchCmdAck(procedure begin SendMIPIReadReq(buff,nDataLen); end, SIG_MIPI_READ, nWait, 2);
end;

procedure TDongaPG.SendMIPIReadReq(buff : TIdBytes; nDataLen : Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : Integer;
begin
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_MIPI_READ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @buff[0], nDataLen);
  SendData(TxBuf);
end;

function TDongaPG.SendModelInfo : DWORD;
begin
  Result := CheckCmdAck(SendModelInfoReq, SIG_MODELINFO,1000,2);
end;

procedure TDongaPG.SendModelInfoReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen, nDataLen, crc16_dat  : Word;
  sModuleData : Ansistring;
begin
  sModuleData := Common.MakeModelData(Common.SystemInfo.TestModel);
  nDataLen := Length(sModuleData);
  nLen := nDataLen + 2; // + CRC
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_MODELINFO;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  CopyMemory(@TxBuf[4], @sModuleData[1], nDataLen);
  crc16_dat := Common.crc16(sModuleData,nDataLen);
  CopyMemory(@TxBuf[4+nDataLen], @crc16_dat, 2);
  SendData(TxBuf);
end;

function TDongaPG.SendOtpRead(nWait: Integer): DWORD;
begin
  Result := CheckCmdAck(SendOtpReadReq, SIG_OTP_READ, nWait, 1);
end;

procedure TDongaPG.SendOtpReadReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 0;
  setlength(TxBuf, nLen + 5);
  Sig_Id := DefPG.SIG_OTP_READ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4] := 0;
  SendData(TxBuf);
end;

function TDongaPG.SendOtpWrite(nWait: Integer): DWORD;
begin
  tmAliveCheck.Enabled := False;  //2018-08-06 (OTP Write 동안 Check 하지 않음)
  m_nConnectCheck := 0;
  Result := CheckCmdAck(SendOtpWriteReq, SIG_OTP_WRITE, nWait, 1);
  tmAliveCheck.Enabled := True;   //2018-08-06 (OTP Write 후 다시 Check)
end;

procedure TDongaPG.SendOtpWriteReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 0;
  setlength(TxBuf, nLen + 4);
  Sig_Id := DefPG.SIG_OTP_WRITE;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  SendData(TxBuf);
end;

procedure TDongaPG.SendPowerReq(nMode: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 1;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_PWR_ON;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4]  := nMode; // 0 : power off, 1 : power on.
  SendData(TxBuf);
  // Power On 하면 Arrive Signal Check 끄자.
//  tmAliveCheck.Enabled := False;
end;

procedure TDongaPG.SendPatGrpData(SetPatGrp: TPatterGroup);
begin

end;

procedure TDongaPG.SendPatInfoTransReq(wSigId, wCrc, wTxLen: Word; TxBuffer: array of Byte);
var
  TxBuf : TIdBytes;
  wLen : Word;
begin
  wLen  := wTxLen+2;
  setlength(TxBuf, wLen+4);
  CopyMemory(@TxBuf[0], @wSigId, 2);
  CopyMemory(@TxBuf[2], @wLen, 2);
  CopyMemory(@TxBuf[4], @TxBuffer[0], wTxLen);
  CopyMemory(@TxBuf[4+wTxLen], @wCrc, 2);

  SendData(TxBuf);
end;

function TDongaPG.SendPatternRoll(nSet, nFrame, nWait: Integer): DWORD;
begin
  Result := CheckCmdAck(procedure begin SendPatternRollReq(nSet, nFrame); end, SIG_PATTERN_ROLL, nWait, 1);
end;

procedure TDongaPG.SendPatternRollReq(nSet, nFrame: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id : word;
  nDataLen : Integer;
begin
  nDataLen := 2;
  Setlength(TxBuf, nDataLen + 4);
  Sig_Id := SIG_PATTERN_ROLL;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nDataLen, 2);
  CopyMemory(@TxBuf[4], @nSet, 1);
  CopyMemory(@TxBuf[5], @nFrame, 1);
  SendData(TxBuf);
end;
function TDongaPG.SendPgReset : DWORD;
var
  nRtn : DWORD;
begin
  // 15초간 대기.
  nRtn := CheckCmdAck(SendResetReq, SIG_PG_RESET,30000,1);
//  Result := WAIT_OBJECT_0;
  Result := nRtn;
end;

function TDongaPG.SendPowerMeasure : DWORD;
begin
  Result := CheckPwrCmdAck(SendPowerMeasureReq, SIG_READ_VOLTCUR,3000,1);
end;

procedure TDongaPG.SendPowerMeasureReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 1;
	SetLength(TxBuf, nLen+4);
	Sig_Id := SIG_READ_VOLTCUR;
	CopyMemory(@TxBuf[0], @Sig_Id, 2);
	CopyMemory(@TxBuf[2], @nLen, 2);
{$IFDEF ISPD_A}
  TxBuf[4] := Byte(0);
{$ELSE}
  TxBuf[4] := Byte(1);
{$ENDIF}
  SendData(TxBuf);
end;

function TDongaPG.SendPowerOn(nMode, nWait, nRty: Integer): DWORD;
var
  nRtn : DWORD;
begin
//  SendPowerReq(nMode);
//  sleep(100);
  nRtn := CheckCmdAck(procedure begin SendPowerReq(nMode);end, SIG_PWR_ON,nWait,nRty);
//  Result := WAIT_OBJECT_0;
  Result := nRtn;

end;

function TDongaPG.SendPowerSet(nSet: Byte): DWORD;
begin
  Result := CheckCmdAck(procedure begin SendPowerSetReq(nSet);end, SIG_POWERCMD_SET,3000,1);
end;

procedure TDongaPG.SendPowerSetReq(nSet: Byte);
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 1;
	SetLength(TxBuf, nLen+4);
	Sig_Id := SIG_POWERCMD_SET;
	CopyMemory(@TxBuf[0], @Sig_Id, 2);
	CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4] := Byte(nSet);
  SendData(TxBuf);
end;

procedure TDongaPG.SendResetReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 0;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_PG_RESET;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  SendData(TxBuf);
end;

function TDongaPG.SendSinglePat(nR, nG, nB, nWait, nRty: Integer): DWORD;
var
  nRtn : DWORD;
begin
  nRtn := CheckCmdAck(procedure begin SendSinglePatReq(nR, nG, nB);end, SIG_SINGLE_PATTERN,nWait,nRty);
  Result := nRtn;
end;

procedure TDongaPG.SendSinglePatReq(nR, nG, nB: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id, nLen, wTemp  : Word;
  wConvert : Word;
  bCheck : Boolean;
begin
  bCheck := False;
  if tmAliveCheck.Enabled then begin
    bCheck := True;
    tmAliveCheck.Enabled := False;
  end;


  nLen := 6;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_SINGLE_PATTERN;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);

  wConvert := nR shl 4;
  if wConvert < 0 then wConvert := 0;
  if wConvert > 4095 then wConvert := 4095;
  wTemp := htons( wConvert);
  CopyMemory(@TxBuf[4], @wTemp, 2);

  wConvert := nG shl 4;
  if wConvert < 0 then wConvert := 0;
  if wConvert > 4095 then wConvert := 4095;
  wTemp := htons(wConvert);
  CopyMemory(@TxBuf[6], @wTemp, 2);

  wConvert := nB shl 4;
  if wConvert < 0 then wConvert := 0;
  if wConvert > 4095 then wConvert := 4095;
  wTemp := htons(wConvert);
  CopyMemory(@TxBuf[8], @wTemp, 2);
  SendData(TxBuf);
  tmAliveCheck.Enabled := bCheck;
end;

function TDongaPG.SendToucFunc2(nMode: Integer; wLen: Word;
  nbData: TArray<System.Byte>): DWORD;
begin

end;

function TDongaPG.SendTouchFwDown: Integer;
var
  nRtn : Integer;
begin
  nRtn := CheckCmdAck(SendTouchFwDownReq, SIG_TOUCH_FW_DOWN,30000,2);
  Result := nRtn;
end;

procedure TDongaPG.SendTouchFwDownReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 1;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_TOUCH_FW_DOWN;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4] := 0;
  SendData(TxBuf);
end;

function TDongaPG.SendTouchIDUpdate: Integer;
var
  nRtn : integer;
begin
  nRtn := CheckCmdAck(SendTouchIDUpdateReq, SIG_TOUCH_REQ,5000,2);
  Result := nRtn;
end;

procedure TDongaPG.SendTouchIDUpdateReq;
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 1;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_ID_UPDATE;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4] := 0;
  SendData(TxBuf);
end;

function TDongaPG.SendTouchRead(nIdx, nFreq, nFrame: Integer): Integer;
var
  nRtn, i   : Integer;
  nWaitTime : Integer;
begin
//  Sleep(500);
  // Frame 개수가 많으면 받는시간이 꽤 오래 걸림. 더 기다리도록 하자.
  if nFrame < 10 then begin
    nWaitTime := 18000;
  end
  else if nFrame < 30 then begin
    nWaitTime := 20000;
  end
  else begin
    nWaitTime := 30000;
  end;
  // Touch Data를 위한 초기화.
  for i := 0 to DefPG.MAX_FRAME_COUNT do begin
//    FRxData.Data[i].IsRev   := False;
//    FRxData.Data[i].RevLen  := 0;
  end;
//  FRxData.FrameCnt := nFrame;

  nRtn := CheckCmdAck(procedure begin SendTouchReq(nIdx, nFreq, nFrame);end, SIG_TOUCH_REQ,nWaitTime,1);
  Result := nRtn;
end;

procedure TDongaPG.SendTouchReq(nIdx, nFreq, nFrame: Integer);
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 3;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_TOUCH_REQ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4] := Byte(nIdx);
  TxBuf[5] := Byte(nFreq);
  TxBuf[6] := Byte(nFrame);
  SendData(TxBuf);
end;
// Return Error : 0 : OK, 1 : Start Mode NG, 2 : Download NG, 3 : Index Not Match NG.
function TDongaPG.SendPocbData(const transData: TFileTranStr): Integer;
const
  START_MODE = 1;
  END_MODE   = 2;
  DATA_MODE  = 3;
var
  TxBuff : TIdBytes;
  i, nFileSize, nTransType    : Integer;
  nDiv, nMod                  : Integer;
  dwRet                       : DWORD;
  wTemp                       : Word;

  cdCheckSum                  : LongWord;
  sFileName                         : AnsiString;
  sTemp, sDebug                     : string;
  bRet : boolean;
begin
  tmAliveCheck.Enabled := False;
  Self.Status := pgWait;
  nFileSize := transData.TotalSize;
  SetLength(TxBuff,DefPG.PACKET_SIZE);
  CopyMemory(@TxBuff[0],@nFileSize,4);
  dwRet   := SendPocbDown(START_MODE,0,40,5000,TxBuff);  // start Mode, Pocb Down Index, FileSize
  if dwRet <> WAIT_OBJECT_0 then begin
    m_nConnectCheck := 0;
    tmAliveCheck.Enabled := True;
    Self.Status := pgDone;
    Exit(1);
  end;
  Sleep(10);

  nDiv := nFileSize div DefPG.PACKET_SIZE;
  nMod := nFileSize mod DefPG.PACKET_SIZE;
//  Sleep(350);
  bRet := False; // No NG.
  for i := 0 to Pred(nDiv) do begin
    CopyMemory(@TxBuff[0],@transData.Data[i*DefPG.PACKET_SIZE],DefPG.PACKET_SIZE);
    dwRet   := SendPocbDown(DATA_MODE,i,DefPG.PACKET_SIZE+4,400,TxBuff);
    if dwRet <> WAIT_OBJECT_0 then begin
      dwRet   := SendPocbDown(DATA_MODE,i,DefPG.PACKET_SIZE+4,400,TxBuff);
      if dwRet <> WAIT_OBJECT_0 then begin
        m_nConnectCheck := 0;
        tmAliveCheck.Enabled := True;
        Self.Status := pgDone;
        sDebug := Format('RetValue : 0x%0.2x',[dwRet]);
        common.MLog(Self.m_nPgNo,sDebug);
        Exit(2);
      end;
    end;
    if FRxData.DataLen < 2 then  Exit(3);
    CopyMemory(@wTemp,@FRxData.Data[0],2);
    if i <> wTemp then Exit(4);
  end;
  if nMod > 0 then begin
    CopyMemory(@TxBuff[0],@transData.Data[nDiv*DefPG.PACKET_SIZE],nMod);
    dwRet   := SendPocbDown(DATA_MODE,nDiv,nMod+4,400,TxBuff);
    if dwRet <> WAIT_OBJECT_0 then begin
      dwRet   := SendPocbDown(DATA_MODE,nDiv,nMod+4,400,TxBuff);
      if dwRet <> WAIT_OBJECT_0 then begin
        m_nConnectCheck := 0;
        tmAliveCheck.Enabled := True;
        Self.Status := pgDone;
        sDebug := Format('RetValue : 0x%0.2x',[dwRet]);
        common.MLog(Self.m_nPgNo,sDebug);
        Exit(2);
      end;
    end;
    if FRxData.DataLen < 2 then  Exit(3);
    CopyMemory(@wTemp,@FRxData.Data[0],2);
    if i <> wTemp then Exit(4);
  end;
  Sleep(10);
  cdCheckSum := transData.CheckSum;
  CopyMemory(@TxBuff[0],@cdCheckSum,4);
  dwRet   := SendPocbDown(END_MODE,0,8,5000,TxBuff);  // start Mode, Pocb Down Index, FileSize
  if dwRet <> WAIT_OBJECT_0 then begin
    m_nConnectCheck := 0;
    tmAliveCheck.Enabled := True;
    Self.Status := pgDone;
    Exit(5);
  end;
  m_nConnectCheck := 0;
  tmAliveCheck.Enabled := True;
  Self.Status := pgDone;

  Result := 0;
end;

function TDongaPG.SendPocbDataWrite(nMode, nDataSize, nFirst_Addr, nNormal_Addr, nEmSpaceData: Integer): DWORD;
begin
  Result := CheckPocbCmdAck(procedure begin SendPocbDataWriteReq(nMode, nDataSize, nFirst_Addr, nNormal_Addr, nEmSpaceData);end, DefPG.SIG_POCB_DATA_W_REQ,30000,1);
end;

procedure TDongaPG.SendPocbDataWriteReq(nMode, nDataSize, nFirst_Addr, nNormal_Addr, nEmSpaceData: Integer);
var
  TxBuffer : TIdBytes;
  Sig_Id, wTxLen  : Word;
begin
  wTxLen := 5;
  setlength(TxBuffer, wTxLen + 4);  // sig ID + total Length + tototal data
  Sig_Id := DefPG.SIG_POCB_DATA_W_REQ;
  CopyMemory(@TxBuffer[0], @Sig_Id, 2);
  CopyMemory(@TxBuffer[2], @wTxLen, 2);
  TxBuffer[4] := Byte(nMode);
  TxBuffer[5] := Byte(nDataSize);
  TxBuffer[6] := Byte(nFirst_Addr);
  TxBuffer[7] := Byte(nNormal_Addr);
  TxBuffer[8] := Byte(nEmSpaceData);
  SendData(TxBuffer);
end;

function TDongaPG.SendPocbDown(nMode, wIdx, wTxLen, nWaitTime: Word; TxBuf: TIdBytes) : DWORD;
begin
  Result := CheckPocbCmdAck(procedure begin SendPocbDownReq(nMode, wIdx, wTxLen,TxBuf);end, DefPG.SIG_POCB_DOWN_REQ,nWaitTime,1);
end;

procedure TDongaPG.SendPocbDownReq(nMode, wIdx, wTxLen: Word; TxBuf: TIdBytes);
var
  TxBuffer : TIdBytes;
  Sig_Id  : Word;
  sFileName : AnsiString;
begin
  setlength(TxBuffer, wTxLen + 4);  // sig ID + total Length + tototal data
  Sig_Id := DefPG.SIG_POCB_DOWN_REQ;
  CopyMemory(@TxBuffer[0], @Sig_Id, 2);
  CopyMemory(@TxBuffer[2], @wTxLen, 2);
  TxBuffer[4] := 0;
  TxBuffer[5] := 0;
  CopyMemory(@TxBuffer[6], @wIdx, 2);
  case nMode of
    1 : begin
      TxBuffer[5] := Byte(Ord('S'));
      sFileName := 'POCB_File.bin';
      CopyMemory(@TxBuffer[8], @sFileName[1], Length(sFileName));
      CopyMemory(@TxBuffer[40], @TxBuf[0], 4);
    end;
    2 : begin
      TxBuffer[5] := Byte(Ord('E'));
      CopyMemory(@TxBuffer[8], @TxBuf[0], 4);
    end;
    3 : begin
      TxBuffer[5] := Byte(Ord('D'));
      CopyMemory(@TxBuffer[8], @TxBuf[0], wTxLen-4);
    end;
  end;
  SendData(TxBuffer);
end;

function TDongaPG.SendPocbFunc(nMode,nErrCnt,nTimeOut : Integer): DWORD;
var
  nRtn   : DWORD;
  nWaitTime : Integer;
begin
  if (nErrCnt = 0) or (nTimeOut = 0) then begin
    nWaitTime := 20000; // Default 21 sec 대기.
  end
  else begin
    nWaitTime := nErrCnt * nTimeOut * 1000 + 2000;
  end;
  nRtn := CheckCmdAck(procedure begin SendPocbFuncReq(nMode,nErrCnt,nTimeOut);end, SIG_POCB_FUNC_REQ,nWaitTime,1);
  Result := nRtn;
end;

function TDongaPG.SendPocbFunc2(nMode: Integer; wLen : Word; nbData: TArray<System.Byte>): DWORD;
var
  nRtn   : DWORD;
begin
  nRtn := CheckCmdAck(procedure begin SendPocbFunc2Req(nMode,wLen,nbData);end, SIG_POCB_FUNC2_REQ,1000,1);
  Result := nRtn;
end;

procedure TDongaPG.SendPocbFunc2Req(nMode: Integer; wLen: Word; nbData: TArray<System.Byte>);
var
  TxBuf : TIdBytes;
  Sig_Id, wTotalLen  : Word;
begin
  wTotalLen := wLen + 3;    // Length 2 byte + mode 1 byte + n.
  setlength(TxBuf, wTotalLen + 4);  // sig ID + total Length + tototal data
  Sig_Id := SIG_POCB_FUNC2_REQ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @wTotalLen, 2);
  TxBuf[4] := Byte(nMode);
	CopyMemory(@TxBuf[5], @wLen, 2);
  if wLen <> 0 then begin
    CopyMemory(@TxBuf[7], @nbData[0], wLen);
  end;

  SendData(TxBuf);
end;

procedure TDongaPG.SendPocbFuncReq(nMode, nErrCnt, nTimeOut:Integer);
var
  TxBuf : TIdBytes;
  Sig_Id, nLen  : Word;
begin
  nLen := 3;
  setlength(TxBuf, nLen + 4);
  Sig_Id := SIG_POCB_FUNC_REQ;
  CopyMemory(@TxBuf[0], @Sig_Id, 2);
  CopyMemory(@TxBuf[2], @nLen, 2);
  TxBuf[4] := Byte(nMode);
	TxBuf[5] := Byte(nErrCnt);
	TxBuf[6] := Byte(nTimeOut);
  SendData(TxBuf);
end;

function TDongaPG.SendPocbhIDUpdate: Integer;
begin

end;

/// <summary>
/// Case 1. Model 정보 Download. ( .mpt, .mion, .mioff, .pwon, .pwoff , pattern files.)
/// Case 2. BMP, FW, FPGA Download.
/// </summary>
/// <param name="nTransDataCnt"></param>
/// <param name="transData"></param>
procedure TDongaPG.SendTransData(nTransDataCnt : Integer;const transData: TArray<TFileTranStr>);
var
//  TxBuff : TArray<System.Byte>;
  TxBuff                            :  array[0..DefPG.PACKET_SIZE] of Byte;
  i, j, nFileSize, nTransType       : Integer;
  nDiv, nMod, nDelayTm              : Integer;
  wRet                              : DWORD;
  cdCheckSum, wSigID                : LongWord;
  sFileName                         : AnsiString;
  nTotalCnt, nCurCnt                : Integer;
  sTemp                             : string;
  btTemp                            : Byte;
begin
  nTotalCnt := 0;
  nCurCnt   := 0;
  tmAliveCheck.Enabled := False;
  if not (nTransDataCnt > 0) then exit; //  transData[0].TransMode 에 대한 방어 코드.

  Self.Status := pgWait;

  for i := 0 to Pred(nTransDataCnt) do begin
//    if transData[i].TransType < DefCommon.DOWNLOAD_TYPE_PG_FPGA then begin
    nFileSize := transData[i].TotalSize;
    nTotalCnt := nTotalCnt + 2; // Start + End.
    nDiv := nFileSize div DefPG.PACKET_SIZE;
    nMod := nFileSize mod DefPG.PACKET_SIZE;
    nTotalCnt := nTotalCnt + nDiv;

    if nMod > 0 then begin
      nTotalCnt := nTotalCnt + 1;
    end;
//    end;
  end;

  ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,'Start!');

  for i := 0 to Pred(nTransDataCnt) do begin
    if transData[i].TransMode < DefCommon.DOWNLOAD_TYPE_PG_FPGA then begin
      wSigID := SIG_FUSING;
    end
    else begin
      wSigID := SIG_FW_DOWNLOAD;
    end;


    // Pattern Info Download for model info or M/C
    if transData[i].TransType = DefPG.TRANS_TYPE_PAT_INFO  then begin
      CopyMemory(@TxBuff[0],@transData[i].Data[0],transData[i].TotalSize);
      // Pattern Download 응답 최고 3 Sec.
      Sleep(100);
      wRet := CheckCmdAck(procedure begin SendPatInfoTransReq(SIG_PATTERN_LOAD,transData[i].CheckSum,transData[i].TotalSize,TxBuff);end,
                    SIG_PATTERN_LOAD,3000,1);
      if  wRet <> WAIT_OBJECT_0 then begin
        // SendFileTrans(wType,wMode,wIdx,wTxLen : Word; TxBuffer: array of Byte);
        // nSid, nDelay, nRetry: Integer)
        ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,i+1,nTransDataCnt,format('Fail..%0.02x',[wRet]),True);
        Break;
      end;
      Inc(nCurCnt);
      sTemp := Format('Downloading ... %s (%d/ %d)',[transData[i].fileName,i, nTransDataCnt]);
      //sTemp := Format('%dKB/%dKB...(%d/%d)',[(j*DefPG.PACKET_SIZE) div 1024,nFileSize div 1024,i+1,nTransDataCnt])
      ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,i,nTransDataCnt,sTemp);
      // 응답을 받고 진행 하기 때문에 Delay 필요 없음.
      Sleep(1);
      Continue;
    end;

    FillChar(TxBuff,DefPG.PACKET_SIZE,0);
    sFileName := AnsiString(Trim(string(transData[i].fileName)));
    nFileSize := transData[i].TotalSize;
    if transData[i].TransMode < DefCommon.DOWNLOAD_TYPE_PG_FPGA then begin
      TxBuff[0] :=  Byte(Length(trim(string(transData[i].fileName))));
      CopyMemory(@TxBuff[1],@sfileName[1],Length(sFileName));
      CopyMemory(@TxBuff[32],@nFileSize,4);
      nTransType := transData[i].TransType;
    end
    else begin
      TxBuff[0] :=  Byte(Length(sFileName));
      CopyMemory(@TxBuff[1],@sfileName[1],Length(sFileName));
      CopyMemory(@TxBuff[32],@nFileSize,4);
      nTransType := transData[i].TransType;
    end;
    Sleep(10);
    wRet := CheckCmdAck(procedure begin SendFileTransReq(wSigID,nTransType,DefPG.FUSING_MODE_START,i,36,TxBuff);end,
                  wSigID,5000,1);
    if  wRet <> WAIT_OBJECT_0 then begin
      // SendFileTrans(wType,wMode,wIdx,wTxLen : Word; TxBuffer: array of Byte);
      // nSid, nDelay, nRetry: Integer)
      ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,format('Fail..%0.02x',[wRet]),True);
      Break;
    end;

    Inc(nCurCnt);
    sTemp := Format('Start ...%s',[sfileName]);
    ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,sTemp);

    nDiv := nFileSize div DefPG.PACKET_SIZE;
    nMod := nFileSize mod DefPG.PACKET_SIZE;

    for j := 1 to nDiv do begin
      CopyMemory(@TxBuff[0],@transData[i].Data[(j-1)*DefPG.PACKET_SIZE],DefPG.PACKET_SIZE);

      SendFileTransReq(wSigID,nTransType,DefPG.FUSING_MODE_DOWNLOAD,i,DefPG.PACKET_SIZE,TxBuff);
      Inc(nCurCnt);

      if not (transData[i].TransMode in [DefCommon.DOWNLOAD_TYPE_BMP, DefCommon.DOWNLOAD_TYPE_PG_FPGA]) then begin

        Sleep(1);
        if transData[i].TransMode = DefCommon.DOWNLOAD_TYPE_PRG then
            ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,string(sFileName) + ':'+sTemp)
          else
            ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,sTemp);
      end
      else begin
        //Sleep(50);
        Common.SleepMicro(500);
        if (j mod 100) = 1 then begin
          if nFileSize > 1024 then
            sTemp := Format('%dKB/%dKB...(%d/%d)',[(j*DefPG.PACKET_SIZE) div 1024,nFileSize div 1024,i+1,nTransDataCnt])
          else
            sTemp := Format('%d Bytes/%d Bytes...(%d/%d)',[(j*DefPG.PACKET_SIZE),nFileSize,i+1,nTransDataCnt]);
  //      CodeSite.SendMsg('[BMP Download] Display GUI');

          if transData[i].TransMode = DefCommon.DOWNLOAD_TYPE_PRG then
            ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,string(sFileName) + ':'+sTemp)
          else
            ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,sTemp);
        end;
      end;

      if self.Status = pgForceStop then Exit;
    end;

    if nMod > 0 then begin
      FillChar(TxBuff,DefPG.PACKET_SIZE,0);
      CopyMemory(@TxBuff[0],@transData[i].Data[nDiv*DefPG.PACKET_SIZE],nMod);
      SendFileTransReq(wSigID,nTransType,DefPG.FUSING_MODE_DOWNLOAD,i,nMod,TxBuff);
//      if transData[i].TransMode = DefCommon.DOWNLOAD_TYPE_BMP then begin
//        Common.SleepMicro(650);
//      end
//      else begin
//        Sleep(200);
//      end;
      if not (transData[i].TransMode in [DefCommon.DOWNLOAD_TYPE_BMP, DefCommon.DOWNLOAD_TYPE_PG_FPGA]) then begin
        Sleep(10);
      end
      else begin
//        Common.SleepMicro(50);
//        Sleep(1);
        Common.SleepMicro(500);
      end;
      Inc(nCurCnt);
      if self.Status = pgForceStop then Exit;
//      if (j mod 1000) = 1 then begin
        if nFileSize > 1024 then
          sTemp := Format('%d Bytes/%d Bytes...(%d/%d)',[nFileSize div 1024,nFileSize div 1024,i+1,nTransDataCnt])
        else
          sTemp := Format('%d Bytes/%d Bytes...(%d/%d)',[nFileSize,nFileSize,i+1,nTransDataCnt]);
        if transData[i].TransMode = DefCommon.DOWNLOAD_TYPE_PRG then
          ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,string(sFileName) + ':'+sTemp)
        else
          ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,sTemp);
//      end;

    end;

    if transData[i].TransMode < DefCommon.DOWNLOAD_TYPE_PG_FPGA then begin
      FillChar(TxBuff,DefPG.PACKET_SIZE,0);
      sFileName := AnsiString(Trim(string(transData[i].fileName)));
      nFileSize := transData[i].TotalSize;
      TxBuff[0] :=  Byte(Length(sFileName));
      CopyMemory(@TxBuff[1],@sfileName[1],Length(sFileName));
      cdCheckSum := transData[i].CheckSum;
      CopyMemory(@TxBuff[32],@cdCheckSum,4);
      nTransType := transData[i].TransType;
    end
    else begin
      FillChar(TxBuff,DefPG.PACKET_SIZE,0);
      cdCheckSum := transData[i].CheckSum;
      CopyMemory(@TxBuff[0],@sfileName[1],Length(sFileName));
      CopyMemory(@TxBuff[32],@cdCheckSum,4);
    end;

    case transData[i].TransMode of
      DefCommon.DOWNLOAD_TYPE_BMP : nDelayTm := 60000;// 30 Sec 15000;  // Max 15 Sec.
      DefCommon.DOWNLOAD_TYPE_PG_FPGA : nDelayTm := 45000; // Max 30 Sec
      DefCommon.DOWNLOAD_TYPE_PG_FW   : nDelayTm := 30000 // Max 2 Sec.  ==> 30 Sec.
      else begin
        nDelayTm := 3000; // etc ... Max 30 mili Sec.
      end;
    end;
//    if not (transData[i].TransMode in [DefCommon.DOWNLOAD_TYPE_BMP, DefCommon.DOWNLOAD_TYPE_PG_FPGA]) then begin
//      nDelayTm := 8000;
//    end
//    else begin
//      nDelayTm := 15000;
//    end;
    Sleep(100);
    if CheckCmdAck(procedure begin SendFileTransReq(wSigID,nTransType,DefPG.FUSING_MODE_END,i,36,TxBuff);end,
                    wSigID,nDelayTm,1) <> WAIT_OBJECT_0 then begin
      if wSigID = SIG_FUSING then begin
        sTemp := 'Fusing NG';
      end
      else begin
        sTemp := 'Fail to download '+ sTemp;
      end;
      Break;
    end;
    Inc(nCurCnt);
    if wSigID = SIG_FUSING then begin
      sTemp := 'Fusing OK';
    end
    else begin
      sTemp := 'Success to download '+ sTemp;
    end;
    if self.Status = pgForceStop then Exit;
  end; //for i := 0 to Pred(nTransDataCnt) do begin

  if (transData[0].TransMode in [DefCommon.DOWNLOAD_TYPE_PG_FPGA, DefCommon.DOWNLOAD_TYPE_PG_FW]) then begin
    ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,'Reset PG');
    if SendPgReset <> WAIT_OBJECT_0 then begin
      ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nTotalCnt,nTotalCnt,'Reset Fail',True);
    end
    else begin
      ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nTotalCnt,nTotalCnt,'Reset OK',True);
    end;
  end
  else begin
    ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nTotalCnt,nTotalCnt,sTemp,True);
  end;

//  if not (wSigID in [SIG_FUSING, SIG_PATTERN_LOAD]) then begin
//    ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nCurCnt,nTotalCnt,'Reset PG');
//    Sleep(500);
//    m_sFwVer := '';
//    if self.Status = pgForceStop then Exit;
//    SendResetReq;
//    Sleep(1000);
//    if self.Status = pgForceStop then Exit;
//    Sleep(1000);
//    if self.Status = pgForceStop then Exit;
//    Sleep(1000);
//    if self.Status = pgForceStop then Exit;
//    Sleep(1000);
//    if self.Status = pgForceStop then Exit;
//    Sleep(1000);
//    if self.Status = pgForceStop then Exit;
//
//    if transData[0].TransMode = DefCommon.DOWNLOAD_TYPE_PG_FW then begin
//      sleep(1000);
//    end;
//    wRet := CheckCmdAck(SendFwVersionCheckReq,SIG_FW_VERSION_REQ,3000,2);
//    if wRet <> WAIT_OBJECT_0 then
////
////    if m_sFwVer <> '' then
//      ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nTotalCnt,nTotalCnt,'Reset Fail',True)
//    else
//      ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nTotalCnt,nTotalCnt,'Reset OK',True);
//  end
//  else begin
//    ShowDownLoadStatus(DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS,nTotalCnt,nTotalCnt,sTemp,True);
//  end;
  m_nConnectCheck := 0;
  tmAliveCheck.Enabled := True;
  Self.Status := pgDone;
end;

//function TDongaPG.Send_NVM_FullRead(nLen : Word; NvmBuf : TArray<System.Byte>): Integer;
//begin
//  Result := CheckCmdAck(procedure begin Send_NVM_FullReadReq(nLen,NvmBuf); end,SIG_MIPI_NVM_FULL_READ ,3000,2);
//end;
//
//function TDongaPG.Send_NVM_FullReadReq(nLen : Word; NvmBuf : TArray<System.Byte>) : Integer;
//var
//  TxBuf : TIdBytes;
//  Sig_Id, wTotalLen  : Word;
//begin
//  try
//    wTotalLen := 3;
//    setlength(TxBuf, wTotalLen + 4);
//
//    wTotalLen := nLen * 2;
//
//    SetLength(TxBuf, wTotalLen+4);
//    Sig_Id := SIG_MIPI_NVM_FULL_READ;
//
//    CopyMemory(@TxBuf[0], @Sig_Id,2);
//
//    CopyMemory(@TxBuf[2], @wTotalLen, 2);
//
//    CopyMemory(@TxBuf[4], @NvmBuf[0], nLen * 2);
//
//    SendData(TxBuf);
//    Result := 0;
//  except
//    Result := -1;
//
//  end;
//
//end;

procedure TDongaPG.SetCamEvent;
begin
//  OnCamTEndEvnt(m_nPgNo);
end;


procedure TDongaPG.SetDisPatStruct(const Value: TPatInfoStruct);
begin
  FDisPatStruct := Value;
end;

procedure TDongaPG.SetPowerMeasureTimer(bEnable: Boolean; nInterval : Integer);
begin
  if nInterval <> 0 then begin
    tmPowerMeasure.Interval := nInterval;
  end;
  tmPowerMeasure.Enabled := bEnable;
  m_bMeasureTmr          := bEnable;
end;

procedure TDongaPG.ShowDownLoadStatus(nGuiType,curPos, total: Integer; sMsg: string;bIsDone : Boolean);
var
  ccd         : TCopyDataStruct;
  SendGui     : RTranStatus;
begin
  SendGui.MsgType := DefCommon.MSG_TYPE_PG;
  SendGui.PgNo      := m_nPgNo;
  SendGui.sMsg    := sMsg;
  SendGui.Mode    := nGuiType;
  SendGui.Total   := total;
  SendGui.CurPos  := curPos;
  SendGui.IsDone  := bIsDone;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(SendGui);
  ccd.lpData      := @SendGui;
  SendMessage(Self.m_hTrans,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TDongaPG.ShowMainWindow(nGuiMode: Integer; sMsg: string);
var
  ccd         : TCopyDataStruct;
  SendGui     : RTranStatus;
begin
  SendGui.MsgType := DefCommon.MSG_TYPE_PG;
  SendGui.Mode    := nGuiMode;
  SendGui.PgNo    := m_nPgNo;
  SendGui.sMsg    := sMsg;

  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(SendGui);
  ccd.lpData      := @SendGui;
  SendMessage(Self.m_hMain,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TDongaPG.ShowTestWindow(nGuiMode, nParam: Integer; sMsg: string);
var
  ccd         : TCopyDataStruct;
  SendGui     : TransVoltage;
begin
  SendGui.MsgType := DefCommon.MSG_TYPE_PG;
  SendGui.Mode    := nGuiMode;
  SendGui.PgNo    := m_nPgNo mod 4;
  SendGui.sMsg    := sMsg;
  SendGui.nParam  := nParam;
  SendGui.ReadPwrData := m_ReadVoltCurr;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(SendGui);
  ccd.lpData      := @SendGui;
  SendMessage(Self.m_hTestFrm,WM_COPYDATA,0, LongInt(@ccd));
{PTransVoltage}

end;

procedure TDongaPG.TestFunc;
var
  wErrNo : Word;
  nCurVal : Integer;
  str : array of Byte;
  sTemp : string;
begin
  SetLength(str, 13);

  str[0] := $01;
  str[1] := $00;
  str[2] := $A1;
  str[3] := $00;
  str[4] := $07;
  str[5] := $00;
  str[6] := $01;
  str[7] := $9A;
  str[8] := $01;
  str[9] := $30;
  str[10] := $85;
  str[11] := $04;
  str[12] := $00;
{A1 00 07 00 01 9A 01 30 85 04 00}

      CopyMemory(@wErrNo,  @str[7], 2);
      nCurVal := 0;
      // 이전 버젼과 호환성 맞게 하기 위하여 길이 Check. Total Data size 14 bytes
//      if wTotalLen > 9 then begin
        CopyMemory(@nCurVal,  @str[9], 4);
        sTemp := GetAlarmStr(wErrNo,nCurVal);
//      end
//      else begin
//        sTemp := GetAlarmStr(wErrNo);
//      end;
//      SendPowerReq(0); // PG에서 끄기로 함.
      Self.SetPowerMeasureTimer(False);
      ShowTestWindow(DefCommon.MSG_MODE_DISPLAY_ALARM,0,sTemp);
end;

procedure TDongaPG.ThreadGetData(const str: TIdBytes);
var
  th5 : TThread;
begin
  th5 := TThread.CreateAnonymousThread(procedure begin
    ReadData(str);
  end);
  th5.FreeOnTerminate := True;
  th5.Start;
end;

procedure TDongaPG.ThreadRead(RevData: TIdBytes);
var
  th1 : TThread;
begin
  th1 := TThread.CreateAnonymousThread(procedure begin
    ReadData(RevData);
  end);
  th1.FreeOnTerminate := True;
  th1.Start;
end;

procedure TDongaPG.ThreadTask(task: TProc);
//var
//  aTask: ITask;
var
  th2 : TThread;
begin
//  Parallel.Async( procedure begin
//      task;
//    end,
//    Parallel.TaskConfig.OnTerminated(
//      procedure (const task: IOmniTaskControl)
//      begin
//      end
//    )
//  );
  th2 := TThread.CreateAnonymousThread(procedure begin
    task;
  end);
  th2.FreeOnTerminate := True;
  th2.Start;
//  aTask := TTask.Create(
//  procedure()
//  begin
//    task;
//  end);
//  aTask.Start;
end;

end.
