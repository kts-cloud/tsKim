unit CommDIO_DAE;
{
  DAE DIO(DJ596-DIO) 통신 처리
  CommDIO 클래스는 Polling을 위한 쓰레드로 구성
}
interface
{$I Common.inc}
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,  System.Classes, System.AnsiStrings, SyncObjs, System.DateUtils,
  IdGlobal, IdUDPClient, IdUDPServer, IdContext, IdSocketHandle,Vcl.Forms;

const
{$IFDEF INSPECTOR_OC}
  MAX_DIO_DEVICE_COUNT = 12;
{$ELSE}
  MAX_DIO_DEVICE_COUNT = 8;
{$ENDIF}


  COMMDIO_MSG_NONE        = 100;
  COMMDIO_MSG_CONNECT     = COMMDIO_MSG_NONE + 1;
  COMMDIO_MSG_HEARTBEAT   = COMMDIO_MSG_NONE + 2;
  COMMDIO_MSG_CHANGE_DI   = COMMDIO_MSG_NONE + 3;
  COMMDIO_MSG_CHANGE_DO   = COMMDIO_MSG_NONE + 4;
  COMMDIO_MSG_LOG         = COMMDIO_MSG_NONE + 5;
  COMMDIO_MSG_ERROR       = COMMDIO_MSG_NONE + 100;
  COMMDIO_MSG_MAX         = COMMDIO_MSG_ERROR + 1;

  COMMDIO_LOGSAVEMODE_NONE = 0;
  COMMDIO_LOGSAVEMODE_HOUR = 1;
  COMMDIO_LOGSAVEMODE_DAY  = 2;
type
  /// <summary> GUI Message for WM_COPYDATA </summary>
  PGuiDaeDio = ^RGuiDaeDio;
  RGuiDaeDio = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param  : Integer;
    Param2 : Integer;
    Msg     : string;
    pData   : PBYTE; //Pointer; //Length = Param2
  end;
  TDIONotifyEvent = procedure(Sender: TObject; pDataMessage: PGuiDaeDio) of object;

  /// <summary>DIO 수신 데이터 기본 구조 </summary>
  TDIOHeader = packed record
    ID  : WORD;
    Len : WORD;
    case Integer of
      0: (Ack : WORD; Addr:Byte; Count:Byte);
      1: (Data: array [0..32]of byte);
  end;
  PDIOHeader = ^TDIOHeader;

  /// <summary> DIO Info 및 Version 정보</summary>
  TDIODeviceInfo = packed record
    Ack   : WORD;
    DeviceIP: Cardinal;
    DevicePort: Cardinal;
    ServerIP: Cardinal;
    ServerPort: Cardinal;
    Count : Byte;
    Version : array [0..MAX_DIO_DEVICE_COUNT] of Cardinal;
//    Version : array [0..12] of Cardinal;
  end;
  PDIODeviceInfo = ^TDIODeviceInfo;

  /// <summary> DIO 통신 쓰레드</summary>
  TCommDIOThread = class(TThread)
  private
    m_hMain: THandle;
    m_nDeviceCount: Integer;
    m_nCheckTime : integer;

    m_UDPServer: TIdUDPServer;
    m_UDPClient: TIdUDPClient;
    m_hEventCommand: HWND; //command 응답 확인용 이벤트
    //m_LastCommand: TDIOHeader;
    m_nLastAck: WORD;
    m_nLastTick_Recv: Cardinal;
    m_nLastTick_Send: Cardinal;
    m_pRecvData: PBYTE;
    m_bWaitEvent: Boolean;
    m_bWorking: Boolean; //작업 중
    m_bFirstConnection: Boolean;

    m_bConnected: Boolean;
    m_csWrite: TCriticalSection;
    m_nStop: Integer;
    m_csLog: TCriticalSection;
    m_slLog: TStringList;
    /// <summary> 로그 파일 저장 위치</summary>
    m_sLogPath: String;
    m_dtSaveLog: TDateTime;
    /// <summary> 알림 이벤트</summary>
    m_NotifyEvent: TDIONotifyEvent;
    m_nTowerLampState: Integer;
    m_nTowerLampTick: Cardinal;
    //class var m_Instance:TCommDIOThread;
    procedure AddLog(sLog: String; bSave: Boolean=false);
    procedure SaveLog(dtSave: TDateTime);
    procedure SendMsgMain(nMsgMode: Integer; nParam, nParam2: Integer; sMsg: String; pData:Pointer=nil);
    function ReadPollingData: Integer;
    function WriteFlushData: Integer;
    procedure Set_LogPath(sValue: String);
    function GetDIValue(inx: Integer): byte;
    function GetDOValue(inx: Integer): byte;
    procedure ProcessPollingData;
    procedure ProcessConnection;
    procedure Process_TowerLamp;

    function CalcChecksum(pValue: PByte; nCount: Integer): Integer;
    function SendData(Buff : TIdBytes): Integer;
    /// <summary> HeartBeat 처리</summary>
    function Send_HeatBeat: Integer;
    function Send_EventNotify(nValue: Byte): Integer;
    function Send_ReadDI(nAddr, nCount: Byte): Integer;
    function Send_ReadDO(nAddr, nCount: Byte): Integer;
    function Send_ClearDO(nAddr, nCount: Byte): Integer;
    function Send_WriteDO(nAddr, nCount: Byte; var naValues: TBytes): Integer;
    function Send_WriteBit(nAddr, nCount: Byte; var nData: Byte): Integer;
    function Send_File(nTpye, nMode, nIndex, nCount: Integer; var naValues: TIdBytes): Integer;
    function Send_ReadVerionInfo: Integer;
    /// <summary> 데이터 전송 후 응답 기다리기. Thread에서 사용. default nWaitTime=2000, nRetry=0</summary>
    function WaitForCommandAck(CommandProc: TProc; nWaitTime:Integer=2000; nRetry: Integer=0): Cardinal;

  protected
    procedure DoEvent;
    /// <summary> Synchronize Main Thread </summary>
    procedure SyncMainThread;
    procedure Execute; override;
    procedure StopThread;
    procedure UDPServerUDPException(AThread: TIdUDPListenerThread; ABinding: TIdSocketHandle; const AMessage: String; const AExceptionClass: TClass);
    procedure UDPServerUDPRead(AThread: TIdUDPListenerThread;const AData: TIdBytes; ABinding: TIdSocketHandle);
  public
    /// <summary> SendMessage에서 사용할 MsgType</summary>
    MessageType: Integer;
    /// <summary> 장치 통신 연결 IP</summary>
    DeviceIP: string;
    /// <summary> 장치 통신 연결 Port</summary>
    DevicePort: Integer;
    /// <summary> 폴링 간격. Runtime 변경 가능</summary>
    PollingInterval: Integer;
    /// <summary> DI 갱신 방식. 0=None, 1=Polling, 2=EventNotify, 3=Both(default) </summary>
    PollingMode: Byte;
    /// <summary> Flush Mode에서 쓰기 후 Sleep 후 Read DI처리. 값= 0이면 Read DI하지 않는다 </summary>
    FlushReadInterval: Integer;
    /// <summary> 자체 로그사용 여부 0=사용안함, 1=시간단위파일, 2=일일단위 파일</summary>
    LogSaveMode: Integer;
    /// <summary> Log 수준 설정. 0=Basic(Connection, Disconnection, Error 등, default), 1=Write, 2=Read, 4=Send, 8=Recv, 16=Polling, All=31</summary>
    LogLevel: Integer;
    /// <summary> Log 누적 라인 수 - 초과 될 경우 저장</summary>
    LogAccumulateCount : Integer;
    /// <summary> Log 누적 시간(초단위) - 초과 될 경우 저장</summary>
    LogAccumulateSecond : Integer;
    /// <summary> 연결 만료시간- 최종데이터 수신 후 해당 시간 경과 시 연결 끊김처리 </summary>
    ExpirationPeriod: Cardinal;
    /// <summary> 연결 유지용 데이터 전송 시간- 최종 데이터 수신 후 해당 시간 경과 시 HeartBeat 전송 </summary>
    HeartBeatPeriod: Cardinal;  //HeartBeatPeriod + PollingInterval < 3000 . DIO Timeout 3000이므로

    /// <summary> Simulation 기능으로 동작</summary>
    UseSimulator: Boolean;
    /// <summary> DO 쓰기를 Flush 방식으로 동작. False=Normal Mode, True=Flush Mode</summary>
    UseFlushMode: Boolean;
    /// <summary> Main으로 Log Message 전송 기능 사용</summary>
    UseMainLog: Boolean;
    /// <summary> 폴링한 DI 데이터. Read only </summary>
    DIData: TBytes; //array of Byte;
    /// <summary> 폴링한 DI 이전 데이터. Read only </summary>
    DIDataPre: TBytes; //array of Byte;
    /// <summary> DO 데이터. Read only </summary>
    DOData: TBytes; //array of Byte;
    /// <summary> DO에 쓸 데이터  데이터</summary>
    DODataFlush: TBytes; //array of Byte;
    /// <summary> 장치 설정 정보. Read Only</summary>
    DeviceInfo: TDIODeviceInfo;
    /// <summary> 연결 시도 실패 Timeout</summary>
    ConnectionTimeout: Cardinal;
    /// <summary> 연결 시도 실패 발생</summary>
    ConnectionError: Boolean;

    //class function getInstance: TCommDIOThread; //Singletone
    constructor Create(hMain : THandle; nMsgType: Integer; nServerPort:Integer=6989; nDeviceCount: Integer=1; bFlushMode:Boolean=false; nPollingMode: Integer=1; nLogSaveMode:Integer=0);
    destructor Destroy; override;
    /// <summary> DI  데이터 읽기 </summary>
    /// <param name='bWaitReply'> 명령 전송 후 응답 대기. default=false, GUI에서는 불가(SendMessage)</param>
    function ReadDI(nAddr, nCount: Byte; out naValues: TBytes; bWaitReply: Boolean=false): Integer;
    /// <summary> DO  데이터 읽기 </summary>
    /// <param name='bWaitReply'> 명령 전송 후 응답 대기. default=false, GUI에서는 불가(SendMessage)</param>
    function ReadDO(nAddr, nCount: Byte; bWaitReply: Boolean=false): Integer;
    /// <summary> DO에 데이터 쓰기</summary>
    /// <param name='bWaitReply'> 명령 전송 후 응답 대기. default=false. GUI에서는 불가(SendMessage)</param>
    function ClearDO(nAddr, nCount: Byte; bWaitReply: Boolean=false): Integer;
    /// <summary> DO에 데이터 쓰기</summary>
    /// <param name='bWaitReply'> 명령 전송 후 응답 대기. default=false. GUI에서는 불가(SendMessage)</param>
    function WriteDO(nAddr, nCount: Byte; naValues: TBytes; bWaitReply: Boolean=false): Integer;
    /// <summary> DO에 Bit 쓰기</summary>
    /// <param name='bWaitReply'> 명령 전송 후 응답 대기. default=false, GUI에서는 불가(SendMessage)</param>
    function WriteDO_Bit(nAddr, nBitLoc, nValue: Byte; bWaitReply: Boolean=false): Integer;
    /// <summary> DO Data Flush에 Bit 쓰기</summary>
    function WriteDO_FlushBit(nAddr, nBitLoc, nValue: Byte): Integer;
    /// <summary> Configuration 정보 읽기</summary>
    function ReadConfig(out sDeviceIP, sServerIP: string; out nDevicePort, nServerPort, nDeviceCount: Integer): Integer;
    /// <summary> Configuration 정보 전송</summary>
    function WriteConfig(sDeviceIP, sServerIP: string; nDevicePort, nServerPort, nDeviceCount: Integer): Integer;
    /// <summary> Polling 방식 설정</summary>
    function WriteEventNotify(nValue: Byte): Integer;
    /// <summary> 파일 전송 -  장치에 F/W 다운로드 시 사용</summary>
    function WriteFile(sFileName: string): Integer;
    /// <summary> 바이너리 버퍼 데이터 전송</summary>
    function SendBuffer(naValues: TBytes): Integer;
    /// <summary> 해당 비트 값이 Value가 될때까지 대기</summary>
    function WaitSignal(nAddr, nBitLoc, nValue: Byte; nWaitTime: Cardinal): Cardinal;
    function Get_Bit(nData: byte; nLoc: byte): byte;
    procedure Set_Bit(var nData: byte; nLoc, Value: byte); overload;
    procedure Set_Bit(var nData: byte; nLoc: byte; Value: Boolean); overload;
    /// <summary> Tower Lamp 상태 및 Melody 상태</summary>
    procedure Set_TowerLampState(nState: Integer);
    /// <summary> Bit On 여부</summary>
    function IsBitOn(var nData: byte; nLoc: byte): Boolean;
    /// <summary> 내부 DIData[Addr]의 Bit On 여부</summary>
    function IsDIOn(nAddr, nLoc: byte): Boolean;  overload;
    /// <summary> 내부 DI Index의 On 여부</summary>
    function IsDIOn(nIndex: byte): Boolean; overload;
    /// <summary> 문자열 IP값을 숫자로 변환</summary>
    function IP2Int(sIP: string): UINT;
    /// <summary> 숫자 IP 값을 문자열로 변환</summary>
    function Int2IP(nIP: UINT): String;
    property DIValue[inx: Integer]: byte read GetDIValue;
    property DOValue[inx: Integer]: byte read GetDOValue;
    property Connected: Boolean read m_bConnected;
    property LogPath: String read m_sLogPath write Set_LogPath;
    /// <summary> DIO Event 알림  </summary>
    property OnNotify: TDIONotifyEvent read m_NotifyEvent write m_NotifyEvent;
  end;

var
  CommDaeDIO: TCommDIOThread;

implementation

uses CommonClass;

const
  COMMDIO_ID_FIRSTCONNECTION     = 1;
  COMMDIO_ID_CONNECTION          = 2;
  COMMDIO_ID_EVENTNOTIFY         = 4;
  COMMDIO_ID_READ_DI             = $10;
  COMMDIO_ID_READ_DO             = $12;
  COMMDIO_ID_CLEARDO             = $20;
  COMMDIO_ID_WRITE_DO            = $22;
  COMMDIO_ID_WRITE_BIT           = $24;
  COMMDIO_ID_VERSION             = $A0;
  COMMDIO_ID_FILEDOWNLOAD        = $F0;
  COMMDIO_ID_CONFIG              = $F2;



procedure TCommDIOThread.AddLog(sLog: String; bSave: Boolean);
var
  dtNow: TDateTime;
begin
  if m_nStop <> 0 then Exit;
  
  if LogSaveMode = COMMDIO_LOGSAVEMODE_NONE then Exit;  //자체 로그 아니면

  m_csLog.Acquire;
  dtNow:= Now;
  if LogSaveMode = COMMDIO_LOGSAVEMODE_HOUR then begin
    if HourOf(m_dtSaveLog) <> HourOf(dtNow) then SaveLog(m_dtSaveLog); //시간 변경된 경우 이전 File로 저장
  end
  else begin
    if Dayof(m_dtSaveLog) <> Dayof(dtNow) then SaveLog(m_dtSaveLog); //날짜 변경된 경우 이전 File로 저장
  end;

  m_slLog.Add(FormatDateTime('HH:NN:SS.ZZZ ', dtNow) + IntToHex(TThread.CurrentThread.ThreadID, 4) + '=> ' +  sLog);
  //로그 라인수가 누적 라인수 초과이거나누적시간(초) 초과인 경우File로 저장
  if (m_slLog.Count > LogAccumulateCount) or (SecondsBetween(dtNow, m_dtSaveLog) > LogAccumulateSecond) or bSave then begin
    SaveLog(dtNow);
  end;
  m_csLog.Release;
end;

procedure TCommDIOThread.SaveLog(dtSave: TDateTime);
var
  sFileName: String;
  logFile: TextFile;
begin
  if LogSaveMode = COMMDIO_LOGSAVEMODE_HOUR then begin
    sFileName:=  m_sLogPath + format('CommDIO_%s.txt',[FormatDateTime('YYYYMMDDHH', dtSave)]);
  end
  else begin
    sFileName:=  m_sLogPath + format('CommDIO_%s.txt',[FormatDateTime('YYYYMMDD', dtSave)]);
  end;

  AssignFile(logFile, sFileName);
  try
    try
      if FileExists(sFileName) then Append(logFile) else Rewrite(logFile);

      WriteLn(logFile, Trim(m_slLog.Text));

      //m_csLog.Acquire;
      m_slLog.Clear;
      m_dtSaveLog:= dtSave;
      //m_csLog.Release;
    except
    end;
  finally
    CloseFile(logFile);
  end;
end;

constructor TCommDIOThread.Create(hMain: THandle; nMsgType: Integer; nServerPort:Integer; nDeviceCount: Integer; bFlushMode:Boolean; nPollingMode: Integer; nLogSaveMode:Integer);
var
  sEventName : WideString;
begin
  m_hMain:= hMain;
  m_nCheckTime := 0;
  MessageType:= nMsgType;
  m_nDeviceCount:= nDeviceCount;

  UseFlushMode:= bFlushMode;
  PollingMode:= nPollingMode;
  PollingInterval:= 1000;
  FlushReadInterval:= 50;
  HeartBeatPeriod:= 1000;
  ExpirationPeriod:= 20000;
  ConnectionTimeout:= 7000;
  ConnectionError:= False;

  LogSaveMode:= nLogSaveMode;
  LogLevel:= 0; //1 + 2 + 4 + 8; //Write + Read + Send + Recv // not Polling(16)
  LogAccumulateCount:= 30;
  LogAccumulateSecond:= 10;

  m_slLog:= TStringList.Create;
  m_csLog:= TCriticalSection.Create;
  m_dtSaveLog:= Now;
  m_csWrite:= TCriticalSection.Create;
  UseMainLog:= False;

  m_sLogPath:= ExtractFilePath(Application.ExeName) + '\Log\CommDIO\';
  if LogSaveMode <> COMMDIO_LOGSAVEMODE_NONE then ForceDirectories(m_sLogPath);

  //폴링 데이터 배열
  SetLength(DIData, m_nDeviceCount);  //MAX_DIO_DEVICE_COUNT
  SetLength(DIDataPre, m_nDeviceCount);
  SetLength(DOData, m_nDeviceCount);
  SetLength(DODataFlush, m_nDeviceCount);

  FillChar(DIData[0], m_nDeviceCount, 0);
  FillChar(DIDataPre[0], m_nDeviceCount, 0);
  FillChar(DOData[0], m_nDeviceCount, 0);
  FillChar(DODataFlush[0], m_nDeviceCount, 0);

  //동기화 작업에 사용할 이벤트
  sEventName:= Format('TCommDIOThread.WaitForCommandAck%d', [m_hMain]);
  m_hEventCommand:= CreateEvent(nil, False, False, PWideChar(sEventName));
  m_bWaitEvent:= False;
  m_bWorking:= false; //작업 중 아님
  m_bFirstConnection:= false;

  m_nLastTick_Recv:= GetTickCount;
  m_nLastTick_Send:= GetTickCount;

  m_nTowerLampTick:= GetTickCount;
  m_nTowerLampState:= 0;
  Process_TowerLamp; //tower Lamp 전체 끄기

  DeviceIP:= '192.168.0.99';
  DevicePort:= 6989;

  AddLog('========================================');
  AddLog(format('Create ServerPort=%d, DeviceCount=%d, FlushMode=%d, PollingMode=%d, LogSaveMode=%d', [nServerPort, nDeviceCount, ord(bFlushMode), nPollingMode, nLogSaveMode]));

  try
    m_UDPServer := TIdUDPServer.Create(nil);
    m_UDPServer.DefaultPort := nServerPort;
    m_UDPServer.IPVersion:= Id_IPv4;
    m_UDPServer.ThreadedEvent:= True;
    m_UDPServer.OnUDPException := UDPServerUDPException;
    m_UDPServer.OnUDPRead := UDPServerUDPRead;
    m_UDPServer.Active := True;

    m_UDPClient:= TIdUDPClient.Create(nil);
    m_UDPClient.Active:= True;
  except
    on E: Exception do begin
      //Socket Error # 10048 Address already in use.'.
      AddLog(format('Can not Create: %s', [E.Message]));
      SendMsgMain(COMMDIO_MSG_ERROR, 0, 0, format('%x Can not Create: %s', [TThread.CurrentThread.ThreadID, E.Message]), nil);
    end;

  end;

  inherited Create(True);
end;

destructor TCommDIOThread.Destroy;
begin

    StopThread;
    m_bConnected:= False;

    if m_UDPServer <> nil then begin
      m_UDPServer.OnUDPException := nil;
      m_UDPServer.OnUDPRead:= nil;
      m_UDPServer.Active:= False;
      m_UDPServer.Free;
      m_UDPServer:= nil;
    end;

    if m_UDPClient <> nil then begin
      m_UDPClient.Active:= False;
      FreeAndNil(m_UDPClient);
    end;

    AddLog('Destroy', True);

    DIDataPre:= nil;
    DIData:= nil;
    SetEvent(m_hEventCommand);
    CloseHandle(m_hEventCommand);

    m_csWrite.Free;
    m_csLog.Free;
    m_slLog.Free;

    inherited;

end;

procedure TCommDIOThread.DoEvent;
begin
  //Call Event
end;


procedure TCommDIOThread.StopThread;
begin
  //InterlockedIncrement(m_nStop);
  m_nStop:= 1;

  Terminate;
  WaitFor;

end;

procedure TCommDIOThread.SyncMainThread;
begin
  if not Terminated then
  begin
    Synchronize(DoEvent);
  end;
end;

function TCommDIOThread.CalcChecksum(pValue: PByte; nCount: Integer): Integer;
var
  i: Integer;
begin
  Result:= 0;
  for i := 0 to Pred(nCount) do begin
    Result:= Result + pValue[i];
  end;
end;


procedure TCommDIOThread.UDPServerUDPException(AThread: TIdUDPListenerThread;
  ABinding: TIdSocketHandle; const AMessage: String;
  const AExceptionClass: TClass);
begin
  AddLog('UDP Exception : ' + AMessage);
  SendMsgMain(COMMDIO_MSG_ERROR, 0, 0, format('%x UDP Exception : %s', [TThread.CurrentThread.ThreadID, AMessage]), nil); //쓰레드 이벤트 블럭됨
end;

procedure TCommDIOThread.UDPServerUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  pHeader: PDIOHeader;
  sData: String;
  i: Integer;
  nDataLen: Integer;
  bPolling: Boolean;
begin
  if Terminated then Exit;

  sData:= '';
  nDataLen:= Length(AData);
  for i := 0 to Pred(nDataLen) do begin
    sData:= sData + IntToHex(AData[i], 2) + ' ';
  end;

  pHeader:= PDIOHeader(AData);
  if pHeader.Len <> (nDataLen - 4) then begin
    //데이터 크기 오류
    AddLog(format('Size Mismatch (%d:%d): %s', [pHeader.Len+4, nDataLen, sData]));
    SendMsgMain(COMMDIO_MSG_ERROR, 0, 0, format('%x Size Mismatch (%d:%d): %s', [TThread.CurrentThread.ThreadID, pHeader.Len+4, nDataLen, sData]), nil); //쓰레드 이벤트 블럭됨
    Exit;
  end;

  if pHeader.ID = COMMDIO_ID_FIRSTCONNECTION then begin
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('%x Recv(%d)<= %s', [TThread.CurrentThread.ThreadID, nDataLen, sData]), nil);
    ProcessConnection;
    Exit;
  end;

  if (pHeader.Ack <> 0) and (pHeader.ID <> COMMDIO_ID_FIRSTCONNECTION) then begin
    SetEvent(m_hEventCommand);
    AddLog(format('Recv(%d)<= %s', [nDataLen, sData]));
    AddLog(format('Ack Error ID:%x Ack:(0x%.4x)', [pHeader.ID, pHeader.Ack]));
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('%x Recv(%d)<= %s', [TThread.CurrentThread.ThreadID, nDataLen, sData]), nil);
    SendMsgMain(COMMDIO_MSG_ERROR, 0, 0, format('%x Ack Error ID:%x Ack:(0x%.4x)', [TThread.CurrentThread.ThreadID, pHeader.ID, pHeader.Ack]), nil);
    Exit;
  end;

  m_nLastAck:= pHeader.Ack;
  m_nLastTick_Recv:= GetTickCount;

  m_bConnected:= True; //무언가 수신하면 연결된 것으로한다.

  //CopyMemory(@m_LastCommand, pHeader, SizeOf(m_LastCommand));

  case pHeader.ID of
    COMMDIO_ID_CONNECTION+1: begin //Connection Check
      //Sleep(10); //for debug
    end;

    COMMDIO_ID_EVENTNOTIFY+1: begin
      SetEvent(m_hEventCommand);
    end;

    COMMDIO_ID_READ_DI+1: begin //Read DI
      if m_pRecvData <> nil then  begin
        //Read_DI 로 데이터 읽을 경우
        CopyMemory(m_pRecvData, @pHeader.Data[4], pHeader.Count);
        SetEvent(m_hEventCommand);
      end;

//    if (pHeader.ID = COMMDIO_ID_READ_DI+1) and (pHeader.Addr = 0) and (pHeader.Count = m_nDeviceCount) then begin
//      //Polling이면
//    end

      //CopyMemory(@DIDataPre[pHeader.Addr], @@DIData[pHeader.Addr], pHeader.Count);
      CopyMemory(@DIData[pHeader.Addr], @pHeader.Data[4], pHeader.Count);

      ProcessPollingData;
    end;

    COMMDIO_ID_READ_DO+1: begin //Read DO
      if m_pRecvData <> nil then  begin
        //Read_DO 로 데이터 읽을 경우
        CopyMemory(m_pRecvData, @pHeader.Data[2], pHeader.Len-2);
      end else begin
        //SendMsgMain(COMMDIO_MSG_CHANGE_DO, 0, 0, 'DO Data Changed', @DOData[0]);
      end;

      CopyMemory(@DOData[pHeader.Addr], @pHeader.Data[4], pHeader.Count);
      SetEvent(m_hEventCommand);
    end;
    COMMDIO_ID_CLEARDO+1: begin //Clear DO
      FillChar(DOData[0], m_nDeviceCount, 0);
      SetEvent(m_hEventCommand);
    end;
    COMMDIO_ID_WRITE_DO+1: begin //Write DO
      SetEvent(m_hEventCommand);
    end;
    COMMDIO_ID_WRITE_BIT+1: begin //Write DO Bit
      SetEvent(m_hEventCommand);
    end;
    COMMDIO_ID_VERSION+1: begin //Version Info
      CopyMemory(@DeviceInfo, @pHeader.Data[0], 19 + pHeader.Data[18]*4);
      SetEvent(m_hEventCommand);
    end;
    COMMDIO_ID_FILEDOWNLOAD+1: begin //File Download
      SetEvent(m_hEventCommand);
    end;
    COMMDIO_ID_CONFIG+1: begin //Config Setup
      SetEvent(m_hEventCommand);
    end;

    else begin //Unkown

    end;
  end;

  if (LogLevel and $8) = $8 then begin
    bPolling:= (pHeader.ID = COMMDIO_ID_READ_DI+1) and (pHeader.Addr = 0) and (pHeader.Count = m_nDeviceCount); //Polling이면
    bPolling:= bPolling or (pHeader.ID = COMMDIO_ID_CONNECTION+1);
    if (not bPolling) or ((LogLevel and $10) = $10) then begin  //not polling data or Polling Log
      AddLog(format('Recv(%.2d)< %s', [nDataLen, sData]));
    end;
  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('%x Recv(%.2d)<= %s', [TThread.CurrentThread.ThreadID, nDataLen, sData]), nil);
end;

function TCommDIOThread.GetDIValue(inx: Integer): byte;
begin
  if (inx < 0) or (inx > m_nDeviceCount-1) then Exit(0);

  Result:= DIData[inx];
end;


function TCommDIOThread.GetDOValue(inx: Integer): byte;
begin
  if (inx < 0) or (inx > m_nDeviceCount-1) then Exit(0);
  Result:= DOData[inx];
end;

procedure TCommDIOThread.SendMsgMain(nMsgMode: Integer; nParam, nParam2: Integer; sMsg: String; pData:Pointer);
var
  cds         : TCopyDataStruct;
  COPYDATAMessage : RGuiDaeDio;
begin
  if (nMsgMode = COMMDIO_MSG_LOG) and (not UseMainLog) then Exit;

  COPYDATAMessage.MsgType := MessageType; //MSGTYPE_COMMDIO;
  COPYDATAMessage.Channel := 1;
  COPYDATAMessage.Mode    := nMsgMode;
  COPYDATAMessage.Param   := nParam;
  COPYDATAMessage.Param2  := nParam2;
  COPYDATAMessage.Msg     := sMsg;
  COPYDATAMessage.pData   := pData;

  cds.dwData      := 0;
  cds.cbData      := SizeOf(COPYDATAMessage);
  cds.lpData      := @COPYDATAMessage;


  if Assigned( m_NotifyEvent) then  m_NotifyEvent( Self,@COPYDATAMessage);
  if m_hMain <> 0  then  SendMessage(m_hMain,WM_COPYDATA,0, LongInt(@cds));
end;

function TCommDIOThread.SendBuffer(naValues: TBytes): Integer;
begin
  Result:= SendData(TIdBytes(naValues));
end;

function TCommDIOThread.ReadConfig(out sDeviceIP, sServerIP: string; out nDevicePort, nServerPort, nDeviceCount: Integer): Integer;
var
  nRet   : Cardinal;
begin
  if (LogLevel and $2) = $2 then  AddLog('ReadConfig');

  nRet:= WaitForCommandAck(
    procedure begin
      Send_ReadVerionInfo;
    end
    );

  case nRet of
    WAIT_OBJECT_0 : begin
      //정상
      sDeviceIP:= Int2IP(DeviceInfo.DeviceIP);
      sServerIP:= Int2IP(DeviceInfo.ServerIP);
      nDevicePort:= DeviceInfo.DevicePort;
      nServerPort:= DeviceInfo.ServerPort;
      nDeviceCount:= DeviceInfo.Count;
    end;
    WAIT_TIMEOUT  : begin

    end
    else begin

    end;
  end;
  Result:= nRet;
end;

function TCommDIOThread.WriteConfig(sDeviceIP, sServerIP: string; nDevicePort, nServerPort, nDeviceCount: Integer): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
  nIP: UINT;
begin
  AddLog(format('WriteConfig: DeviceIP=%s, DevicePort=%d, ServerIP=%s, ServerPort=%d, DeviceCount=%d',
      [sDeviceIP, nDevicePort, sServerIP, nServerPort, nDeviceCount]));

  SetLength(txBuff, 21);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_CONFIG;
  pHeader.Len:= 17;
  nIP:= IP2Int(sDeviceIP);
  if nIP = 0 then Exit(1); //IP 정보 이상

  CopyMemory(@pHeader.Data[0], @nIP, 4);
  CopyMemory(@pHeader.Data[4], @nDevicePort, 4);

  nIP:= IP2Int(sServerIP);
  if nIP = 0 then Exit(1); //IP 정보 이상
  CopyMemory(@pHeader.Data[8], @nIP, 4);
  CopyMemory(@pHeader.Data[12], @nServerPort, 4);

  pHeader.Data[16]:= nDeviceCount;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.SendData(Buff: TIdBytes): Integer;
var
  i, nCount: Integer;
  nDataCount: Integer;
  sData: string;
  pHeader: PDIOHeader;
  bPolling: Boolean;
begin
  //if not m_bConnected then Exit(1);
  if not (m_nStop = 0) then Exit(1);

  try
    //테스트 프로그램 용- LogLevel 안으로 들어가야 한다.
    sData:= '';
    nCount:= Length(Buff);
    nDataCount:=  nCount;
    if nDataCount > 100 then begin
      nDataCount:= 100;
    end;
    for i := 0 to Pred(nDataCount) do begin
      sData:= sData + IntToHex(Buff[i], 2) + ' ';
    end;

    if (LogLevel and $4) = $4 then begin
      pHeader:= PDIOHeader(Buff);
      bPolling:= (pHeader.ID = COMMDIO_ID_READ_DI) and (pHeader.Data[0] = 0) and (pHeader.Data[1] = m_nDeviceCount); //Polling이면
      bPolling:= bPolling or (pHeader.ID = COMMDIO_ID_CONNECTION);
      if (not bPolling) or ((LogLevel and $10) = $10) then begin  //not polling data or Polling Log
//        sData:= '';
//        nCount:= Length(Buff);
//        nDataCount:=  nCount;
//        if nDataCount > 100 then begin
//          nDataCount:= 100;
//        end;
//        for i := 0 to Pred(nDataCount) do begin
//          sData:= sData + IntToHex(Buff[i], 2) + ' ';
//        end;
        AddLog(format('Send(%.2d)> %s', [nCount, sData]));
      end;
    end;

    m_csWrite.Acquire;
    m_UDPClient.SendBuffer(DeviceIP, DevicePort, Buff);
    m_csWrite.Release;

    m_nLastTick_Send:= GetTickCount;
    //Test App을 위해
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('%.4x Send(%.2d)=> %s', [TThread.CurrentThread.ThreadID, nCount, sData]), nil);
    Result:= 0;
  except
    on E: Exception do begin
      AddLog('Exception in SendData: ' + E.Message);
      SendMsgMain(COMMDIO_MSG_ERROR, 255, 0, 'Exception in SendData: ' + E.Message);
      Result:= 255;
    end;
  end;
end;


function TCommDIOThread.WriteFile(sFileName: string): Integer;
var
  fs: TFileStream;
  TxBuff: TIdBytes;
  nFileSize, nCountPacket: Integer;
  nPackerSize, nModSize: Integer;
  nHeaderSize, nCheckSum: Integer;
  nRetry: Integer;
  nRet: Integer;
  i, k: Integer;
  pHeader: PDIOHeader;
begin
  Result:= 1;
  if not FileExists(sFileName) then begin
    //File not Found
    Exit;
  end;
  nPackerSize:= 1024;
  nHeaderSize:= 6;
  nRetry:= 1;
  nRet:= 0;
  fs:= TFileStream.Create(sFileName, fmOpenRead + fmShareDenyWrite);

  try
    nFileSize:= Integer(fs.Size);
    nCountPacket:= nFileSize div nPackerSize;
    nModSize:= nFileSize mod nPackerSize;

    AddLog(format('WriteFile FileSize=%d, ModeSize=%d, PacketCount=%d, %s',
        [nFileSize, nModSize, nCountPacket, sFileName]));

    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('%.4x WriteFile FileSize=%d, ModeSize=%d, PacketCount=%d, %s',
        [TThread.CurrentThread.ThreadID, nFileSize, nModSize, nCountPacket, sFileName]), nil);
    //////////////////////////////////////////////////////
    //Polling Stop
    m_bWorking:= True;
    //////////////////////////////////////////////////////
    //Send Start
    SetLength(TxBuff, 4 + nHeaderSize);

    pHeader:= PDIOHeader(TxBuff);
    pHeader.ID:= COMMDIO_ID_FILEDOWNLOAD;
    pHeader.Len:= nHeaderSize;
    pHeader.Data[0] := 0; //Type
    pHeader.Data[1] := ord('S'); //Mode
    CopyMemory(@pHeader.Data[2], @nFileSize, 4); //sizeof(nFileSize));
    for k := 0 to nRetry do begin
      nRet:= WaitForCommandAck(
        procedure begin
          SendData(TxBuff);
        end
      );

      if nRet = WAIT_OBJECT_0 then begin
        break; //for k
      end;
    end;
    if nRet <> WAIT_OBJECT_0 then begin
        Result:= nRet;
        m_bWorking:= False;
        Exit;
    end;

    //////////////////////////////////////////////////////
    //Send File Data
    nCheckSum:= 0;
    SetLength(TxBuff, 4 + nHeaderSize + nPackerSize);
    pHeader:= PDIOHeader(TxBuff);
    pHeader.ID:= COMMDIO_ID_FILEDOWNLOAD;
    pHeader.Len:= nHeaderSize + nPackerSize; //8 + 1024 = 1034
    pHeader.Data[0] := 0; //Type
    pHeader.Data[1] := ord('D');

    for i := 0 to Pred(nCountPacket) do begin
      CopyMemory(@pHeader.Data[2], @i, 4); //Index

      fs.Read(pHeader.Data[6], nPackerSize);
      nCheckSum:= nCheckSum + CalcChecksum(@pHeader.Data[6], nPackerSize);
      for k := 0 to nRetry do begin
        nRet:= WaitForCommandAck(
          procedure begin
            SendData(TxBuff);
          end
        );
        if nRet = WAIT_OBJECT_0 then begin
          break; //for k
        end;
      end;
      if nRet <> WAIT_OBJECT_0 then begin
        break; //for i
      end;
    end; //for i := 0 to Pred(nCountPacket) do begin
    if nRet <> WAIT_OBJECT_0 then begin
      Result:= nRet;
      m_bWorking:= False;
      Exit;
    end;

    //////////////////////////////////////////////////////
    //Send Mod Data
    if nModSize > 0 then begin
      SetLength(TxBuff, 4 + nHeaderSize + nModSize);
      pHeader:= PDIOHeader(TxBuff);
      pHeader.ID:= COMMDIO_ID_FILEDOWNLOAD;
      pHeader.Len:= nHeaderSize + nModSize;
      pHeader.Data[0] := 0; //Type
      pHeader.Data[1] := ord('D');
      CopyMemory(@pHeader.Data[2], @nCountPacket, 4); //Index

      fs.Read(pHeader.Data[6], nModSize);
      nCheckSum:= nCheckSum + CalcChecksum(@pHeader.Data[6], nModSize);

      for k := 0 to nRetry do begin
        nRet:= WaitForCommandAck(
          procedure begin
            SendData(TxBuff);
          end
        );
        if nRet = WAIT_OBJECT_0 then begin
          break; //for k
        end;
      end;
    end;
    if nRet <> WAIT_OBJECT_0 then begin
      Result:= nRet;
      m_bWorking:= False;
      Exit;
    end;

    //////////////////////////////////////////////////////
    //Send End;
    SetLength(TxBuff, 4 + nHeaderSize);
    pHeader:= PDIOHeader(TxBuff);
    pHeader.ID:= COMMDIO_ID_FILEDOWNLOAD;
    pHeader.Len:= nHeaderSize;
    pHeader.Data[0] := 0; //Type
    pHeader.Data[1] := ord('E');
    CopyMemory(@pHeader.Data[2], @nCheckSum, 4); //Check sum

    for k := 0 to nRetry do begin
      nRet:= WaitForCommandAck(
        procedure begin
          SendData(TxBuff);
        end
      );

      if nRet = WAIT_OBJECT_0 then begin
        break; //for k
      end;
    end;
    //////////////////////////////////////////////////////
    //Polling Restart
    m_bWorking:= False;
    Result:= 0;
  finally
    fs.Free;
    //Polling Restart
    m_bWorking:= False;
  end;
end;

function TCommDIOThread.Send_HeatBeat: Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(txBuff, 4);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_CONNECTION;
  pHeader.Len:= 0;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_ClearDO(nAddr, nCount: Byte): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(txBuff, 6);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_CLEARDO;
  pHeader.Len:= 2;
  pHeader.Data[0]:= nAddr;
  pHeader.Data[1]:= nCount;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_EventNotify(nValue: Byte): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(txBuff, 5);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_EVENTNOTIFY;
  pHeader.Len:= 1;
  pHeader.Data[0]:= nValue;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_File(nTpye, nMode, nIndex, nCount: Integer; var naValues: TIdBytes): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(TxBuff, 6 + nCount);
  pHeader:= PDIOHeader(TxBuff);
  pHeader.ID:= COMMDIO_ID_FILEDOWNLOAD;
  pHeader.Len:= nCount + 2;
  pHeader.Data[0]:= nTpye;
  pHeader.Data[1]:= nMode;
  CopyMemory(@pHeader.Data[2], @naValues[0], nCount);

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_ReadDI(nAddr, nCount: Byte): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(txBuff, 6);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_READ_DI;
  pHeader.Len:= 2;
  pHeader.Data[0]:= nAddr;
  pHeader.Data[1]:= nCount;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_ReadDO(nAddr, nCount: Byte): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(txBuff, 6);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_READ_DO;
  pHeader.Len:= 2;
  pHeader.Data[0]:= nAddr;
  pHeader.Data[1]:= nCount;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_ReadVerionInfo: Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(txBuff, 4);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_VERSION;
  pHeader.Len:= 0;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_WriteBit(nAddr, nCount: Byte; var nData: Byte): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(txBuff, 7);
  pHeader:= PDIOHeader(txBuff);
  pHeader.ID:= COMMDIO_ID_WRITE_BIT;
  pHeader.Len:= 3;
  pHeader.Data[0]:= nAddr;
  pHeader.Data[1]:= nCount;
  pHeader.Data[2]:= nData;

  Result:= SendData(TxBuff);
end;

function TCommDIOThread.Send_WriteDO(nAddr, nCount: Byte; var naValues: TBytes): Integer;
var
  TxBuff: TIdBytes;
  pHeader: PDIOHeader;
begin
  SetLength(TxBuff, 6 + nCount);
  pHeader:= PDIOHeader(TxBuff);
  pHeader.ID:= COMMDIO_ID_WRITE_DO;
  pHeader.Len:= nCount + 2;
  pHeader.Data[0]:= nAddr;
  pHeader.Data[1]:= nCount;
  CopyMemory(@pHeader.Data[2], @naValues[0], nCount);

  Result:= SendData(TxBuff);
end;

procedure TCommDIOThread.Execute;
var
  nTick: Cardinal;
  nRet: Integer;
begin
  inherited;
  m_nStop:= 0;
  nTick := 0;
(*
  m_UDPServer := TIdUDPServer.Create(nil);
  m_UDPServer.ThreadedEvent:= True;
  m_UDPServer.DefaultPort := Port;
  m_UDPServer.IPVersion:= Id_IPv4;
  m_UDPServer.OnUDPException := UDPServerUDPException;
  m_UDPServer.OnUDPRead := UDPServerUDPRead;
  m_UDPServer.Active := True;

  m_UDPClient:= TIdUDPClient.Create(nil);
  m_UDPClient.Active:= True;
*)

  //while not Terminated do begin
  while m_nStop = 0 do begin
    if not m_UDPServer.Active then begin
      //연결 되지 않음 재 연결
      m_UDPServer.Active:= true;
      WaitForSingleObject(self.Handle, PollingInterval); //재연결 딜레이
      continue;
    end;

    nTick:= GetTickCount;

    if not m_bFirstConnection then begin
      if (not ConnectionError) and (nTick  > (m_nLastTick_Recv + ConnectionTimeout)) then begin
        AddLog('Can not Connect **********');
        SendMsgMain(COMMDIO_MSG_ERROR, 100, 0, format('%.4x Can not Connect (%s)', [TThread.CurrentThread.ThreadID, FormatDateTime('HH:NN:SS.ZZZ', Now)]), nil);
        ConnectionError:= True;
        //m_nLastTick_Recv:= nTick; //동일 간격으로 계속 알람 전송
      end;
      WaitForSingleObject(self.Handle, PollingInterval);
      continue; //첫 연결처리 전에는 폴링 안함
    end;

    if not m_bConnected then begin
      WaitForSingleObject(self.Handle, PollingInterval);
      continue;
    end;

    if m_bWorking then begin
      WaitForSingleObject(self.Handle, PollingInterval);
      continue; //다른 작업이 진행 중일 경우 폴링 안함- Write File
    end;

    if nTick > (m_nLastTick_Send + HeartBeatPeriod) then begin
      Send_HeatBeat; //일정 시간 동안 통신이 없을 경우 HeartBeat 전송
    end;

    if nTick > (m_nLastTick_Recv + ExpirationPeriod) then begin
      //lost Connection
      AddLog('Lost Connection **********: ' + IntToStr(abs(nTick - m_nLastTick_Recv)));
      m_bConnected:= False;
//      m_bFirstConnection:= false;
      SendMsgMain(COMMDIO_MSG_CONNECT, 0, 0, format('%.4x Lost Connection (%s)', [TThread.CurrentThread.ThreadID, FormatDateTime('HH:NN:SS.ZZZ', Now)]), nil); //쓰레드 이벤트 블럭됨
    end;

    //타워 램프 처리
    //Process_TowerLamp;

    nRet:= 0;
    //Flush Mode일 경우  쓰기 처리
    if UseFlushMode then begin
      nRet:= WriteFlushData;
      //쓰기 후 읽기 대기
      if (nRet <> 0) and (FlushReadInterval <> 0) then begin
        Sleep(FlushReadInterval);
        //ReadPollingData;
      end;
    end;

    if (nRet <> 0) or ((PollingMode and $01) = $01) then begin //Polling 방식일 경우
      ReadPollingData; //데이터 폴링
    end;

    WaitForSingleObject(self.Handle, PollingInterval);
  end;
(*
  if m_UDPServer <> nil then begin
    m_UDPServer.OnUDPException := nil;
    m_UDPServer.OnUDPRead:= nil;
    m_UDPServer.Active:= False;
    FreeAndNil(m_UDPServer);
  end;

  if m_UDPClient <> nil then begin
    m_UDPClient.Active:= False;
    FreeAndNil(m_UDPClient);
  end;
*)
end;

function TCommDIOThread.ReadPollingData: Integer;
begin
  if not m_bConnected then Exit(1);
  Result:= Send_ReadDI(0, m_nDeviceCount);
end;

function TCommDIOThread.WriteFlushData: Integer;
var
  i: Integer;
  bChange: Boolean;
begin
  Result:= 0;
  if Terminated then Exit;
  bChange:= False;
  for i := 0 to Pred(m_nDeviceCount) do begin
    if DODataFlush[i] <>  DOData[i] then begin
      bChange:= True;
      break;
    end;
  end;

  if bChange then begin
    CopyMemory(@DOData[0], @DODataFlush[0], m_nDeviceCount);

    Send_WriteDO(0, m_nDeviceCount, DODataFlush);

    SendMsgMain(COMMDIO_MSG_CHANGE_DO, 0, 0, 'DO Data Changed', @DODataFlush[0]);
    //PostMessage(m_hMain,WM_USER+1, MSGTYPE_COMMDIO, COMMDIO_MSG_CHANGE_DO);
//    //쓰기 후 한번 읽기 처리
//    if FlushReadInterval <> 0 then begin
//      Sleep(FlushReadInterval);
//      //ReadPollingData;
//    end;
    Result:= 1; //Changed
  end;
end;


procedure TCommDIOThread.ProcessConnection;
var
  nRet: Integer;
  nValue: Byte;
begin
  AddLog('Process Connection **********');
  //Device 연결 시 처리//버전 정보 요청 및 연결 유지
  TThread.CreateAnonymousThread(
    procedure begin
      Send_HeatBeat;

      Sleep(50);

      nRet:= WaitForCommandAck(
        procedure begin
          Send_ReadVerionInfo;
        end
      );
      Sleep(50);
      nRet:= WaitForCommandAck(
        procedure begin
          //Send_ClearDO(0, m_nDeviceCount);
          Send_ReadDO(0, m_nDeviceCount);
        end
      );
      Sleep(50);
      nValue:= ord((PollingMode and $02) = $02);
      nRet:= WaitForCommandAck(
          procedure begin
            Send_EventNotify(nValue);
          end
        );
      Sleep(50);
      nRet:= WaitForCommandAck(
        procedure begin
          Send_ReadDI(0, m_nDeviceCount);
        end
      );
      //ReadPollingData; //처음 한번은 무조건 DI 읽기
      //Sleep(500);
      CopyMemory(@DODataFlush[0], @DOData[0], m_nDeviceCount);
      //버전 검사
//      for i:= 1 to Pred(DeviceInfo.Count) do begin
//        if DeviceInfo.Version[0] <> DeviceInfo.Version[i] then begin
//          //버전 일치 오류
//          SendMsgMain(COMMDIO_MSG_CONNECT, 1, 1, format('%x Device Version Mismatch %x: %x)', [TThread.CurrentThread.ThreadID, DeviceInfo.Version[0], DeviceInfo.Version[i]]), nil); //쓰레드 이벤트 블럭됨
//          break;
//        end;
//      end;

      AddLog('Connected **********');
      SendMsgMain(COMMDIO_MSG_CONNECT, 1, 0, format('%.4x Connected (%s)', [TThread.CurrentThread.ThreadID, FormatDateTime('HH:NN:SS.ZZZ', Now)]), nil); //쓰레드 이벤트 블럭됨

      m_bFirstConnection:= True;
    end).Start;
end;

procedure TCommDIOThread.ProcessPollingData;
var
  i, k: Integer;
  bChanged: Boolean;
  sChangedList: String;
  nValue: Byte;

begin

  if m_nStop <> 0 then Exit;
  if Terminated then Exit;

  bChanged:= False;
  sChangedList:= '';
  Inc(m_nCheckTime);
  for i := 0 to Pred(m_nDeviceCount) do begin
    if DIData[i] <> DIDataPre[i] then begin
      for k := 0 to 7 do begin
        nValue:= Get_Bit(DIData[i], k);
        if nValue <> Get_Bit(DIDataPre[i], k) then begin
          if sChangedList = '' then sChangedList:= sChangedList + format('%d=%d', [i*8+k, nValue])
          else sChangedList:= sChangedList + format(',%d=%d', [i*8+k, nValue]);
        end;
      end;
      bChanged:= True; //데이터 변경 됨
    end;
  end;
  if m_nCheckTime > 60 then bChanged:= True;


  if  bChanged then begin
    m_nCheckTime := 0;
    AddLog('Changed DI: ' + sChangedList);
    //if m_bFirstConnection then begin
      SendMsgMain(COMMDIO_MSG_CHANGE_DI, 0, 0, sChangedList, @DIDataPre[0]);
    //end;
    CopyMemory(@DIDataPre[0], @DIData[0], sizeof(DIData[0])* m_nDeviceCount);
  end;

end;


procedure TCommDIOThread.Process_TowerLamp;
var
  nTick: Cardinal;
begin
  //알람에 따른 경관 등 및 멜로디 처리
  nTick:= GetTickCount;

  case m_nTowerLampState of
    0: begin
      //전체 끄기
      if Get_Bit(DOData[0], 3) <> 0 then WriteDO_Bit(0, 3, 0); //RED Lamp
      if Get_Bit(DOData[0], 4) <> 0 then WriteDO_Bit(0, 4, 0); //Yellow Lamp
      if Get_Bit(DOData[0], 5) <> 0 then WriteDO_Bit(0, 5, 0); //Green Lamp
      if Get_Bit(DOData[0], 6) <> 0 then WriteDO_Bit(0, 6, 0); //Melody #1
      if Get_Bit(DOData[0], 7) <> 0 then WriteDO_Bit(0, 7, 0); //Melody #2
      //if Get_Bit(DOData[1], 0) <> 0 then WriteDO_Bit(1, 0, 0); //Melody #3
      //if Get_Bit(DOData[1], 1) <> 0 then WriteDO_Bit(1, 1, 0); //Melody #4
    end;
    2: begin
      //운전 준비 전, 수동/Pass Mode  - 적색 On
      if Get_Bit(DOData[0], 3) <> 1 then WriteDO_Bit(0, 3, 1); //RED Lamp
      if Get_Bit(DOData[0], 4) <> 0 then WriteDO_Bit(0, 4, 0); //Yellow Lamp
      if Get_Bit(DOData[0], 5) <> 0 then WriteDO_Bit(0, 5, 0); //Green Lamp
      if Get_Bit(DOData[0], 6) <> 0 then WriteDO_Bit(0, 6, 0); //Melody #1
      if Get_Bit(DOData[0], 7) <> 0 then WriteDO_Bit(0, 7, 0); //Melody #2
    end;
    4: begin
      //운전 준비 완료 정지 중- 녹색 점멸
      if Get_Bit(DOData[0], 3) <> 0 then WriteDO_Bit(0, 3, 0); //RED Lamp
      if Get_Bit(DOData[0], 4) <> 0 then WriteDO_Bit(0, 4, 0); //Yellow Lamp
      //이전 시간 차가 500ms 이상이면
      if (nTick - m_nTowerLampTick > 450) then begin
        if Get_Bit(DOData[0], 3) <> 0 then begin
          WriteDO_Bit(0, 5, 0); //Green Lamp
        end
        else begin
          WriteDO_Bit(0, 5, 1); //Green Lamp
        end;
        m_nTowerLampTick:= nTick;
      end;
      if Get_Bit(DOData[0], 6) <> 0 then WriteDO_Bit(0, 6, 0); //Melody #1
      if Get_Bit(DOData[0], 7) <> 0 then WriteDO_Bit(0, 7, 0); //Melody #2
    end;
    8: begin
      //운전 준비 완료 중- 녹색 On
      if Get_Bit(DOData[0], 3) <> 0 then WriteDO_Bit(0, 3, 0); //RED Lamp
      if Get_Bit(DOData[0], 4) <> 0 then WriteDO_Bit(0, 4, 0); //Yellow Lamp
      if Get_Bit(DOData[0], 5) <> 1 then WriteDO_Bit(0, 5, 1); //Green Lamp
      if Get_Bit(DOData[0], 6) <> 0 then WriteDO_Bit(0, 6, 0); //Melody #1
      if Get_Bit(DOData[0], 7) <> 0 then WriteDO_Bit(0, 7, 0); //Melody #2
    end;
    16: begin
      //원자재 투입/취출 요구- 황색 점멸, 멜로디 사용
      if Get_Bit(DOData[0], 3) <> 0 then WriteDO_Bit(0, 3, 0); //RED Lamp
      if (nTick - m_nTowerLampTick > 450) then begin
        if Get_Bit(DOData[0], 4) <> 0 then begin
          WriteDO_Bit(0, 4, 0); //Yellow Lamp
        end
        else begin
          WriteDO_Bit(0, 4, 1); //Yellow Lamp
        end;
        m_nTowerLampTick:= nTick;
      end;
      //if Get_Bit(DOData[0], 4) <> 0 then WriteDO_Bit(0, 4, 0); //Yellow Lamp
      if Get_Bit(DOData[0], 5) <> 0 then WriteDO_Bit(0, 5, 1); //Green Lamp
      if Get_Bit(DOData[0], 6) <> 1 then WriteDO_Bit(0, 6, 0); //Melody #1
      if Get_Bit(DOData[0], 7) <> 0 then WriteDO_Bit(0, 7, 0); //Melody #2
    end;
    32: begin
      //Error 발생중 - 적색 점멸, 멜로디
      if (nTick - m_nTowerLampTick > 450) then begin
        if Get_Bit(DOData[0], 3) <> 0 then begin
          WriteDO_Bit(0, 3, 0); //RED Lamp
        end
        else begin
          WriteDO_Bit(0, 3, 1); //RED Lamp
        end;
        m_nTowerLampTick:= nTick;
      end;
      //if Get_Bit(DOData[0], 3) <> 0 then WriteDO_Bit(0, 3, 0); //RED Lamp
      if Get_Bit(DOData[0], 4) <> 0 then WriteDO_Bit(0, 4, 0); //Yellow Lamp
      if Get_Bit(DOData[0], 5) <> 0 then WriteDO_Bit(0, 5, 1); //Green Lamp
      if Get_Bit(DOData[0], 6) <> 1 then WriteDO_Bit(0, 6, 1); //Melody #1
      if Get_Bit(DOData[0], 7) <> 0 then WriteDO_Bit(0, 7, 0); //Melody #2
    end;
    64: begin
      //비상 정지 - 적색 On, 멜로디
      if Get_Bit(DOData[0], 3) <> 1 then WriteDO_Bit(0, 3, 0); //RED Lamp
      if Get_Bit(DOData[0], 4) <> 0 then WriteDO_Bit(0, 4, 0); //Yellow Lamp
      if Get_Bit(DOData[0], 5) <> 0 then WriteDO_Bit(0, 5, 1); //Green Lamp
      if Get_Bit(DOData[0], 6) <> 1 then WriteDO_Bit(0, 6, 0); //Melody #1
      if Get_Bit(DOData[0], 7) <> 0 then WriteDO_Bit(0, 7, 0); //Melody #2
    end;
    else begin

    end;
  end;
end;

function TCommDIOThread.ReadDI(nAddr, nCount: Byte; out naValues: TBytes; bWaitReply: Boolean): Integer;
var
  nRet   : Cardinal;
begin
  if not m_bConnected then Exit(1);
  if nAddr > m_nDeviceCount-1 then Exit(2);

  if (LogLevel and $2) = $2 then  AddLog(format('ReadDI: Addr=%d, Count=%d', [nAddr, nCount]));


  if not bWaitReply then begin
    nRet:= Send_ReadDI(nAddr, nCount);
  end
  else begin
    m_pRecvData:= @naValues;
    nRet:= WaitForCommandAck(
      procedure begin
        Send_ReadDI(nAddr, nCount);
      end
      );

    case nRet of
      WAIT_OBJECT_0 : begin
        //정상
      end;
      WAIT_TIMEOUT  : begin

      end
      else begin

      end;
    end;
  end;
  Result:= nRet;
  m_pRecvData:= nil;
end;


function TCommDIOThread.ReadDO(nAddr, nCount: Byte; bWaitReply: Boolean): Integer;
var
  nRet   : Cardinal;
begin
  if not m_bConnected then Exit(1);
  if nAddr > m_nDeviceCount-1 then Exit(2);

  if (LogLevel and $2) = $2 then  AddLog(format('ReadDO: Addr=%d, Count=%d', [nAddr, nCount]));

  if not bWaitReply then begin
    nRet:= Send_ReadDO(nAddr, nCount);
  end
  else begin
    nRet:= WaitForCommandAck(
      procedure begin
        Send_ReadDO(nAddr, nCount);
      end
      );

    case nRet of
      WAIT_OBJECT_0 : begin
        //정상
      end;
      WAIT_TIMEOUT  : begin

      end
      else begin

      end;
    end;
  end;
  Result:= nRet;
end;


function TCommDIOThread.ClearDO(nAddr, nCount: Byte; bWaitReply: Boolean): Integer;
var
  nRet   : Cardinal;
begin
  if not m_bConnected then Exit(1);
  if nAddr > m_nDeviceCount-1 then Exit(2);

  if (LogLevel and $1) = $1 then  AddLog(format('ClearDO: Addr=%d, Count=%d', [nAddr, nCount]));

  if UseFlushMode then begin
    m_csWrite.Acquire;
    FillChar(DODataFlush[nAddr], nCount, 0);
    m_csWrite.Release;
    Exit(0);
  end;

  if not bWaitReply then begin
    nRet:= Send_ClearDO(nAddr, nCount);
    if nRet = 0 then begin
      FillChar(DOData[nAddr], nCount, 0);
    end;
  end
  else begin
    nRet:= WaitForCommandAck(
      procedure begin
        Send_ClearDO(nAddr, nCount);
      end
      );
    if m_nLastAck <> 0 then begin

    end;

    case nRet of
      WAIT_OBJECT_0 : begin
        //정상
        FillChar(DOData[nAddr], nCount, 0);
      end;
      WAIT_TIMEOUT  : begin

      end
      else begin

      end;
    end;
  end;
  Result:= nRet;
end;

function TCommDIOThread.WriteDO(nAddr, nCount: Byte; naValues: TBytes; bWaitReply: Boolean): Integer;
var
  nRet   : Cardinal;
  sData: String;
  i: Integer;
begin
  if not m_bConnected then Exit(1);
  if nAddr > m_nDeviceCount-1 then Exit(2);

  if (LogLevel and $1) = $1 then begin
    sData:= '';
    for i := 0 to High(naValues) do begin
      sData:= sData + ' ' + IntToStr(naValues[i]);
    end;
    AddLog(format('WriteDO: Addr=%d, nCount=%d, Data=%s', [nAddr, nCount, sData]));
  end;

  if UseFlushMode then begin
    m_csWrite.Acquire;
    CopyMemory(@DODataFlush[nAddr], @naValues[0], nCount);
    m_csWrite.Release;
    Exit(0);
  end;

  if not bWaitReply then begin
    nRet:= Send_WriteDO(nAddr, nCount, naValues);
    if nRet = 0 then begin
      CopyMemory(@DOData[nAddr], @naValues[0], nCount); //읽지 않고 변수 갱신
    end;
  end
  else begin
    nRet:= WaitForCommandAck(
      procedure begin
        Send_WriteDO(nAddr, nCount, naValues);
      end
      );
    if m_nLastAck <> 0 then begin

    end;

    case nRet of
      WAIT_OBJECT_0 : begin
        //정상
        CopyMemory(@DOData[nAddr], @naValues[0], nCount); //읽지 않고 변수 갱신
      end;
      WAIT_TIMEOUT  : begin

      end
      else begin

      end;
    end;
  end;
  Result:= nRet;
end;

function TCommDIOThread.WriteDO_Bit(nAddr, nBitLoc, nValue: Byte; bWaitReply: Boolean): Integer;
var
  nRet   : Cardinal;
begin
  if not m_bConnected then Exit(1);
  if nAddr > m_nDeviceCount-1 then Exit(2);
  if nBitLoc > 7 then Exit(3);

  if (LogLevel and $1) = $1 then  AddLog(format('WriteDO_Bit: Addr=%d, BitLoc=%d, Data=%d', [nAddr, nBitLoc, nValue]));

  if UseFlushMode then begin
    m_csWrite.Acquire;
    Set_Bit(DODataFlush[nAddr], nBitLoc, nValue);
    m_csWrite.Release;
    Exit(0);
  end;

  if not bWaitReply then begin
    nRet:= Send_WriteBit(nAddr, nBitLoc, nValue);
    if nRet = 0 then begin
      Set_Bit(DOData[nAddr], nBitLoc, nValue); //쓰기 데이터에 반영
    end;
  end
  else begin
    nRet:= WaitForCommandAck(
      procedure begin
        Send_WriteBit(nAddr, nBitLoc, nValue);
      end
      );
    if m_nLastAck <> 0 then begin

    end;

    case nRet of
      WAIT_OBJECT_0 : begin
        //정상
        Set_Bit(DOData[nAddr], nBitLoc, nValue); //쓰기 데이터에 반영
      end;
      WAIT_TIMEOUT  : begin

      end
      else begin

      end;
    end;
  end;
  Result:= nRet;
end;

function TCommDIOThread.WriteDO_FlushBit(nAddr, nBitLoc, nValue: Byte): Integer;
begin
  if not m_bConnected then Exit(1);
  if nAddr > m_nDeviceCount-1 then Exit(2);
  if nBitLoc > 7 then Exit(3);
  if not UseFlushMode then Exit(4);

  if (LogLevel and $1) = $1 then  AddLog(format('WriteDO_FlushBit: Addr=%d, BitLoc=%d, Data=%d', [nAddr, nBitLoc, nValue]));

  Result:= 0;
  m_csWrite.Acquire;
  Set_Bit(DODataFlush[nAddr], nBitLoc, nValue);
  m_csWrite.Release;
end;

function TCommDIOThread.WriteEventNotify(nValue: Byte): Integer;
var
  nRet   : Cardinal;
begin
  if not m_bConnected then Exit(1);
  nRet:= Send_EventNotify(nValue);
  if nRet = 0 then begin
    Set_Bit(PollingMode, 1, nValue); //Notify 비트 설정
  end;

  Result:= nRet;
end;

function TCommDIOThread.Get_Bit(nData, nLoc: byte): byte;
begin
  Result := (nData shr nLoc) and $01;
end;

procedure TCommDIOThread.Set_Bit(var nData: byte; nLoc, Value: byte);
begin
  if Value = 0 then
  begin
    nData := (nData and not (1 shl nLoc));
  end else
  begin
    nData := nData or (1 shl nLoc);
  end;
end;

procedure TCommDIOThread.Set_Bit(var nData: byte; nLoc: byte; Value: Boolean);
begin
  if Value = False then
  begin
    nData := (nData and not (1 shl nLoc));
  end else
  begin
    nData := nData or (1 shl nLoc);
  end;
end;


function TCommDIOThread.IsBitOn(var nData: byte; nLoc: byte): Boolean;
begin
  Result := (nData shr nLoc) and $01 = $01;
end;

function TCommDIOThread.IsDIOn(nAddr, nLoc: byte): Boolean;
begin
  if nAddr >= m_nDeviceCount then  Exit(False);
  if nLoc > 7 then  Exit(False);

  Result := (DIData[nAddr] shr nLoc) and $01 = $01;
end;

function TCommDIOThread.IsDIOn(nIndex: byte): Boolean;
begin
  Result := IsDIOn(nIndex div 8, nIndex mod 8);
end;


procedure TCommDIOThread.Set_LogPath(sValue: String);
begin
  if m_sLogPath <> sValue then begin
    m_sLogPath:= sValue;
    ForceDirectories(m_sLogPath);
  end;
end;

procedure TCommDIOThread.Set_TowerLampState(nState: Integer);
begin
  m_nTowerLampState:= nState;
  Process_TowerLamp;
end;

function TCommDIOThread.Int2IP(nIP: UINT): String;
var
  nValue: UINT;
begin
  Result:= '';
  if nIP >= 4294967295 then begin
    Result:= '255.255.255.255';
  end
  else begin
    nValue:= (nIP shr 24) and $FF;
    Result:= IntToStr(nValue);
    nValue:= (nIP shr 16) and $FF;
    Result:= Result + '.' + IntToStr(nValue);
    nValue:= (nIP shr 8) and $FF;
    Result:= Result + '.' + IntToStr(nValue);
    nValue:= nIP and $FF;
    Result:= Result + '.' + IntToStr(nValue);
(*
    Result:= IntToStr((nIP shr 24) and $FF) + '.'
      + IntToStr((nIP shr 16) and $FF) + '.'
      + IntToStr((nIP shr 8) and $FF) + '.'
      + IntToStr(nIP  and $FF);
*)
  end;
end;


function TCommDIOThread.IP2Int(sIP: string): UINT;
var
  sa: TArray<String>;
  i: Integer;
  nValue, nIP: UINT;
begin
  Result:= 0;
  sa:= sIP.Split(['.']);
  if Length(sa) <> 4 then Exit;
  nIP:= 0;
  for i := 0 to 3 do begin
    nValue:= StrToIntDef(sa[i], 256);
    if (nValue > 255) then Exit;
    nValue:=  nValue shl ((3-i)*8); //for Byte Order
    nIP:= nIP + nValue;
  end;
  Result:= nIP;
end;

function TCommDIOThread.WaitForCommandAck(CommandProc: TProc; nWaitTime, nRetry: Integer): Cardinal;
var
  nRet   : Cardinal;
  i      : Integer;
begin
  nRet := WAIT_FAILED;

  //m_bWorking:= True;
  //m_bWaitEvent:= True;
  for i := 0 to nRetry do begin

    ResetEvent(m_hEventCommand);

    CommandProc; //실제 작업

    nRet := WaitForSingleObject(m_hEventCommand, nWaitTime);

    case nRet of
      WAIT_OBJECT_0 : begin
        break;
      end;
      WAIT_TIMEOUT  : begin

      end
      else begin

      end;
    end;
  end;

  //m_bWorking:= False;
  //m_bWaitEvent:= False;
  Result:= nRet;
end;

function TCommDIOThread.WaitSignal(nAddr, nBitLoc, nValue: Byte; nWaitTime: Cardinal): Cardinal;
var
  nTick, nStartTick: Cardinal;
begin
  Result:= 1;
  nStartTick:= GetTickCount;
  nTick:= nStartTick;

  while (nTick - nStartTick) < nWaitTime  do begin
    if Get_Bit(DIData[nAddr], nBitLoc) = nValue then begin
    //if IsDIOn(nAddr, nBitLoc) = nValue then begin
      Result:= 0;
      break;
    end;
    Sleep(1);
    nTick:= GetTickCount;
  end;
end;

end.

