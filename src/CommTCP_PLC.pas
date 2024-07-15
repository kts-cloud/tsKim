unit CommTCP_PLC;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,  System.Classes, System.AnsiStrings, SyncObjs, System.DateUtils,
    IdBaseComponent, IdGlobal, IdIOHandler, IdComponent, IdTCPConnection, IdTCPClient,
    Vcl.ExtCtrls;
type
  TPLCHeader = packed record
    PLC: array [0..2] of     Byte;
    Command:                 Byte;
    Count:                   Byte;
    Device: array [0..9] of Byte;
    Data: array [0..100] of Integer;
  end;
  PPLCHeader = ^TPLCHeader;

  TDataEvent = procedure(const AReadData: TIdBytes) of object;
  TDataEventStr = procedure(const sReadData: string) of object;

  TSocketReadThread = class(TThread)
  private
    { Private declarations }
    m_OnData: TDataEvent;
    m_OnDataStr: TDataEventStr;
    m_OnAddLog: TDataEventStr;
    m_nTick: Cardinal;
    procedure AddLog(sLog: string);
  protected
    procedure Execute; override;
  public
    TCPClient: TIdTCPClient;
    RxBuf : TIdBytes;
    Active: Boolean;
    constructor Create(AClient: TIdTCPClient);
    property OnData: TDataEvent read m_OnData write m_OnData;
    property OnDataStr: TDataEventStr read m_OnDataStr write m_OnDataStr;
    property OnAddLog: TDataEventStr read m_OnAddLog write m_OnAddLog;
  end;

  TCommTCP = class
  private
    m_TCPClient: TIdTCPClient;
    m_hMsgHandle: THandle;
    m_nIndex: Integer;
    m_nMsgType: Integer;
    m_hEventCommand: HWND; //command 응답 확인용 이벤트
    m_nLastTick_Recv: Cardinal;
    m_nLastTick_Send: Cardinal;
    m_bWorking: Boolean;
    m_sLogPath: string;

    m_ReadThread: TSocketReadThread; //Data Read Thread
    m_RxBuf: TIdBytes;
    m_nRxSize: Integer;
    m_bActive: Boolean;
    m_sSendValue: string; //보낸 명령
    m_sReturnValue: string; //응답 값
    m_sReturnAck: string;  //응답 Ack
    m_nAck: Byte;
    m_ReturnData: TIdBytes; //응답 바이너리 데이터
    m_Values: array [0..100] of Integer;

    procedure SendMsgMain(nMsgMode, nParam, nParam2: Integer; sMsg: String;
      pData: Pointer);
    function WaitForCommandAck(CommandProc: TProc; nWaitTime: Integer; nRetry: Integer= 2): Cardinal;
    function Get_Connected: Boolean;
    function BufferToStr(buffer: TIdBytes; nStart, nCount: Integer): String;
    procedure IdTCPClientConnected(Sender: TObject);
    procedure IdTCPClientDisconnected(Sender: TObject);
    procedure IdTCPClientStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
    procedure IdTCPClientReadData(const AReadData: TIdBytes);
    procedure SetActive(bValue: Boolean);
    procedure SendBuffer(Buff: TIdBytes);
  public
    /// <summary> 장치 통신 연결 IP</summary>
    DeviceIP: string;
    /// <summary> 장치 통신 연결 Port</summary>
    DevicePort: Integer;

    constructor Create(sIP: string; nPort: Integer);
    destructor Destroy; override;
    function SendCommand(Header: PPLCHeader; nSendSize:Integer; nWait: Integer = 5000; nRetry: Integer=0): Cardinal;
    function ReadDevice(const szDevice: AnsiString; out lplData: Integer): Integer;
    function ReadDeviceBlock(const szDevice: AnsiString; lSize: Integer; var lplData: Integer): Integer;
    function WriteDevice(const szDevice: AnsiString; lplData: Integer): Integer;
    function WriteDeviceBlock(const szDevice: AnsiString; lSize: Integer; var lplData: Integer): Integer;
    function GetDevice(const szDevice: AnsiString; out lplData: Integer): Integer;
    function SetDevice(const szDevice: AnsiString; lplData: Integer): Integer;

    property Active: Boolean read m_bActive write SetActive;
    property Connected: Boolean read Get_Connected;
  end;
implementation

{ TCommTCP }

function TCommTCP.BufferToStr(buffer: TIdBytes; nStart, nCount: Integer): String;
var
  i: Integer;
begin
  Result:= '';
  for i := nStart to  nStart + nCount - 1 do begin
    Result := Result + Format('%0.2x ',[buffer[i]]);
  end;
  Result:= Trim(Result);
end;

constructor TCommTCP.Create(sIP: string; nPort: Integer);
var
  sEventName: string;
begin
  DeviceIP:= sIP; //'127.0.0.1';
  DevicePort:= nPort; //3888
  m_bWorking:= False;
  m_bActive:= False;

  sEventName:= format('TCommPGA19:WaitCommandAck_%d', [m_nIndex]);
  m_hEventCommand:= CreateEvent(nil, False, False, PWideChar(sEventName));

  m_TCPClient := TIdTCPClient.Create(nil);
  m_TCPClient.OnConnected:= IdTCPClientConnected;
  m_TCPClient.OnDisconnected:= IdTCPClientDisconnected;
  m_TCPClient.OnStatus:= IdTCPClientStatus;
  m_TCPClient.ConnectTimeout:= 2000;
  m_TCPClient.Host:= DeviceIP;
  m_TCPClient.Port:= DevicePort;

  //Read Thread 생성- Connect 처리
  m_ReadThread:= TSocketReadThread.Create(m_TCPClient);
  m_ReadThread.OnData:= IdTCPClientReadData;
  //m_ReadThread.OnDataStr:= IdTCPClientReadStr;
  //m_ReadThread.OnAddLog:= OnAddLog;
  m_ReadThread.Active:= m_bActive;
  m_ReadThread.Start;
end;

destructor TCommTCP.Destroy;
begin

  inherited;
end;

function TCommTCP.Get_Connected: Boolean;
begin
  Result:= m_TCPClient.Connected;
end;

procedure TCommTCP.IdTCPClientConnected(Sender: TObject);
begin

end;

procedure TCommTCP.IdTCPClientDisconnected(Sender: TObject);
begin

end;

procedure TCommTCP.IdTCPClientReadData(const AReadData: TIdBytes);
var
  i: Integer;
  sData: String;
  asDataList: TArray<String>;
  asValueList: TArray<String>;
  nValueCount: Integer;
  sCommand: String;
  ReturnCommand: Byte;
  nDataLen: Integer;
  nParamLen: Integer;
  sValue: string;
  pHeader: PPLCHeader;
  sAddress: AnsiString;
  nSize: Integer;
  naValues: array [0..100] of Integer;
begin
  m_nLastTick_Recv:= GetTickCount;

  pHeader:= PPLCHeader(@AReadData[0]);
  if (pHeader.PLC[0] = Ord('P')) and (pHeader.PLC[1] = Ord('L')) and (pHeader.PLC[2] = Ord('C')) then begin
    sAddress:= '';
    for i := 0 to 9 do begin
      if pHeader.Device[i] = 0 then Break;
      sAddress:= sAddress + Chr(pHeader.Device[i]);
    end;
    sAddress:= Trim(sAddress);
    if pHeader.Command > $90 then begin
      ReturnCommand:= pHeader.Command - $90;
      m_nAck:= 1; //연결 안됨
    end
    else if pHeader.Command > $80 then begin
      ReturnCommand:= pHeader.Command - $80;
      m_nAck:= 2; //명령 실해오류
    end
    else begin
      ReturnCommand:= pHeader.Command;
      m_nAck:= 0; //정상
    end;
    CopyMemory(@m_Values[0], @pHeader.Data[0], pHeader.Count*SizeOf(m_Values[0]));

    case ReturnCommand of
      1: begin  //ReadDevice
        SetEvent(m_hEventCommand);
      end;
      2: begin  //ReadDeviceBlock
        SetEvent(m_hEventCommand);
      end;
      3: begin  //WriteDevice
        SetEvent(m_hEventCommand);
      end;
      4: begin  //WriteDeviceBlock
        SetEvent(m_hEventCommand);
      end;
      else begin
        SetEvent(m_hEventCommand);
      end;
    end;
  end
  else begin
    //Error Data
  end;
end;

procedure TCommTCP.IdTCPClientStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
  if AStatus = hsConnected then begin
    //AddLog('Connected: ThreadID=' + IntToStr(TThread.CurrentThread.ThreadID));
  end
  else if AStatus = hsDisconnected then begin
    m_TCPClient.Disconnect;
    //AddLog('Disconnected: ThreadID=' + IntToStr(TThread.CurrentThread.ThreadID));
  end
  else begin
    if AStatus <> hsConnecting then begin
      //Connecting은 로그 제외
      //AddLog(Format('Status:%d, Text:%s', [ord(AStatus), AStatusText]));
    end;
  end;
end;

function TCommTCP.GetDevice(const szDevice: AnsiString; out lplData: Integer): Integer;
var
  nRet: Integer;
  Header: TPLCHeader;
  ABuffer : TIdBytes;
  nSendSize: Integer;
  sAddress: AnsiString;
begin
  if not Connected then Exit(1);
  nRet:= 0;
  Header.PLC[0]:= ord('P');
  Header.PLC[1]:= ord('L');
  Header.PLC[2]:= ord('C');
  Header.Command:= 1;

  FillChar(Header.Device[0], 10, 0);
  CopyMemory(@Header.Device[0], @szDevice[1], Length(szDevice));
  CopyMemory(@Header.Data[0], @lplData, sizeof(Integer));
  Header.Count:= 1;

  nSendSize:= 15 + sizeof(lplData);
  SetLength(ABuffer, nSendSize);
  CopyMemory(@ABuffer[0], @Header.PLC[0], nSendSize);

  Result:= SendCommand(@Header, nSendSize);
  if Result = 0 then begin
    if m_nAck <> 0 then begin

    end;
    CopyMemory(@lplData, @m_Values[0], sizeof(Integer));
  end;

end;

function TCommTCP.ReadDevice(const szDevice: AnsiString; out lplData: Integer): Integer;
var
  nRet: Integer;
  Header: TPLCHeader;
  ABuffer : TIdBytes;
  nSendSize: Integer;
  sAddress: AnsiString;
begin
  if not Connected then Exit(1);
  nRet:= 0;
  Header.PLC[0]:= ord('P');
  Header.PLC[1]:= ord('L');
  Header.PLC[2]:= ord('C');
  Header.Command:= 1;

  FillChar(Header.Device[0], 10, 0);
  CopyMemory(@Header.Device[0], @szDevice[1], Length(szDevice));
  CopyMemory(@Header.Data[0], @lplData, sizeof(Integer));
  Header.Count:= 1;

  nSendSize:= 15 + sizeof(lplData);
  SetLength(ABuffer, nSendSize);
  CopyMemory(@ABuffer[0], @Header.PLC[0], nSendSize);

  Result:= SendCommand(@Header, nSendSize);
  if Result = 0 then begin
    if m_nAck <> 0 then begin

    end;
    CopyMemory(@lplData, @m_Values[0], sizeof(Integer));
  end;

end;

function TCommTCP.ReadDeviceBlock(const szDevice: AnsiString; lSize: Integer; var lplData: Integer): Integer;
var
  nRet: Integer;
  Header: TPLCHeader;
  ABuffer : TIdBytes;
  nSendSize: Integer;
  sAddress: AnsiString;
begin
  if not Connected then Exit(1);
  nRet:= 0;
  Header.PLC[0]:= ord('P');
  Header.PLC[1]:= ord('L');
  Header.PLC[2]:= ord('C');
  Header.Command:= 2;
  Header.Count:= lSize;

  FillChar(Header.Device[0], 10, 0);
  CopyMemory(@Header.Device[0], @szDevice[1], Length(szDevice));
  CopyMemory(@Header.Data[0], @lplData, sizeof(Integer));


  nSendSize:= 15 + sizeof(Integer);
  SetLength(ABuffer, nSendSize);
  CopyMemory(@ABuffer[0], @Header.PLC[0], nSendSize);

  Result:= SendCommand(@Header, nSendSize);
  if Result = 0 then begin
    CopyMemory(@lplData, @m_Values[0], lSize*sizeof(Integer));
  end;
end;

function TCommTCP.WriteDevice(const szDevice: AnsiString; lplData: Integer): Integer;
var
  nRet: Integer;
  Header: TPLCHeader;
  ABuffer : TIdBytes;
  nSendSize: Integer;
  sAddress: AnsiString;
begin
  if not Connected then Exit(1);
  nRet:= 0;
  Header.PLC[0]:= ord('P');
  Header.PLC[1]:= ord('L');
  Header.PLC[2]:= ord('C');
  Header.Command:= 3;
  Header.Count:= 1;

  FillChar(Header.Device[0], 10, 0);
  CopyMemory(@Header.Device[0], @szDevice[1], Length(szDevice));
  CopyMemory(@Header.Data[0], @lplData, sizeof(lplData));


  nSendSize:= 15 + sizeof(lplData);
  SetLength(ABuffer, nSendSize);
  CopyMemory(@ABuffer[0], @Header.PLC[0], nSendSize);

  Result:= SendCommand(@Header, nSendSize);
  if Result = 0 then begin

  end;
end;

function TCommTCP.SetDevice(const szDevice: AnsiString; lplData: Integer): Integer;
var
  nRet: Integer;
  Header: TPLCHeader;
  ABuffer : TIdBytes;
  nSendSize: Integer;
  sAddress: AnsiString;
begin
  if not Connected then Exit(1);
  nRet:= 0;
  Header.PLC[0]:= ord('P');
  Header.PLC[1]:= ord('L');
  Header.PLC[2]:= ord('C');
  Header.Command:= 3;
  Header.Count:= 1;

  FillChar(Header.Device[0], 10, 0);
  CopyMemory(@Header.Device[0], @szDevice[1], Length(szDevice));
  CopyMemory(@Header.Data[0], @lplData, sizeof(lplData));


  nSendSize:= 15 + sizeof(lplData);
  SetLength(ABuffer, nSendSize);
  CopyMemory(@ABuffer[0], @Header.PLC[0], nSendSize);

  Result:= SendCommand(@Header, nSendSize);
  if Result = 0 then begin

  end;
end;

function TCommTCP.WriteDeviceBlock(const szDevice: AnsiString; lSize: Integer; var lplData: Integer): Integer;
var
  nRet: Integer;
  Header: TPLCHeader;
  ABuffer : TIdBytes;
  nSendSize: Integer;
  sAddress: AnsiString;
begin
  if not Connected then Exit(1);
  nRet:= 0;
  Header.PLC[0]:= ord('P');
  Header.PLC[1]:= ord('L');
  Header.PLC[2]:= ord('C');
  Header.Command:= 4;
  Header.Count:= lSize;

  FillChar(Header.Device[0], 10, 0);
  CopyMemory(@Header.Device[0], @szDevice[1], Length(szDevice));
  CopyMemory(@Header.Data[0], @lplData, lSize*sizeof(Integer));


  nSendSize:= 15 + lSize*sizeof(Integer);
  SetLength(ABuffer, nSendSize);
  CopyMemory(@ABuffer[0], @Header.PLC[0], nSendSize);

  Result:= SendCommand(@Header, nSendSize);
  if Result = 0 then begin

  end;
end;

procedure TCommTCP.SendBuffer(Buff: TIdBytes);
begin
  m_nLastTick_Send:= GetTickCount;
  m_TCPClient.IOHandler.Write(Buff, Length(Buff));
end;

function TCommTCP.SendCommand(Header: PPLCHeader; nSendSize:Integer; nWait, nRetry: Integer): Cardinal;
var
  Buff: TIdBytes;
  nRet: Cardinal;
  i: Integer;
  naValues: array [0..1024] of Integer;
  //Header: TPLCHeader;
  ABuffer : TIdBytes;
  //nSendSize: Integer;
begin
  if not m_TCPClient.Connected then begin
    //m_sReturnAck:= 'Not Connected';
    Result:= 100; //연결 안됨
    Exit;
  end;

  if m_bWorking then begin
    //m_sReturnAck:= 'Working';
    Result:= 102; //작업 중
    Exit;
  end;
  m_bWorking:= True;

  try
    //nSendSize:= 15 + Header.Count;
    SetLength(Buff, nSendSize);
    CopyMemory(@Buff[0], @Header.PLC[0], nSendSize);

    nRet:= 100;
    Result:= nRet;
    try
      ResetEvent(m_hEventCommand);

      SendBuffer(Buff);

      nRet := WaitForSingleObject(m_hEventCommand, nWait);

      case nRet of
        WAIT_OBJECT_0 : begin
          //정상
          if m_nAck <> 0 then begin
            case m_nAck of
              1: nRet:= 1000; //Not Connected //연결 안됨
            else
              nRet:= 1001; //NG - NACK, ERROR //명령 실패
            end;
          end;
        end;
        WAIT_TIMEOUT  : begin
          m_nAck:= 3;
        end
        else begin
          m_nAck:= 4;
        end;
      end;
      Result:= nRet;
    except
      //on E: Exception do AddLog('Exception: SendCommand ' + E.Message);
    end;
  finally
    m_bWorking:= False;
  end;
end;

procedure TCommTCP.SendMsgMain(nMsgMode, nParam, nParam2: Integer; sMsg: String; pData: Pointer);
begin

end;

procedure TCommTCP.SetActive(bValue: Boolean);
begin
  m_ReadThread.Active:= bValue;
end;

function TCommTCP.WaitForCommandAck(CommandProc: TProc; nWaitTime, nRetry: Integer): Cardinal;
begin

end;

{ TSocketReadThread }

procedure TSocketReadThread.AddLog(sLog: string);
begin

end;

constructor TSocketReadThread.Create(AClient: TIdTCPClient);
begin
  inherited Create(True);
  m_nTick:= 0;
  TCPClient:= AClient;
end;

procedure TSocketReadThread.Execute;
begin
  inherited;
  while not Terminated do begin
    if (TCPClient = nil) then begin
      Sleep(100);
    end
    else if not TCPClient.Connected then begin
      try
        Sleep(500);

        if Active then begin
          if GetTickCount - m_nTick > 3000 then begin
            m_nTick:= GetTickCount;
            TCPClient.Connect;
          end;
        end;
      except
        on E: Exception do begin
          //연결 실패
        end;
      end;
    end
    else begin
      try
        TCPClient.IOHandler.CheckForDataOnSource(10);
        if not TCPClient.IOHandler.InputBufferIsEmpty then begin
          TCPClient.IOHandler.InputBuffer.ExtractToBytes(RxBuf);
          if Assigned(m_OnData) then m_OnData(RxBuf);
          SetLength(RxBuf, 0);
        end;
      except
        on E: Exception do begin
          AddLog('Exception: ' + E.Message);
          TCPClient.IOHandler.InputBuffer.Clear;
          TCPClient.Disconnect;
        end;
      end;
    end;
  end;
end;

end.

