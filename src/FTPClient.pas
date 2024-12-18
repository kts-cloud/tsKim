unit FTPClient;

interface
{$I Common.inc}

uses
  Winapi.Windows, Winapi.Messages,SyncObjs,
  System.Classes, System.SysUtils, System.Variants,
  DateUtils, IOUtils, StrUtils, System.Diagnostics,

  IdFTP, IdFTPCommon, IdFTPListParseWindowsNT, IdFTPList,
  DefCommon, CommonClass,System.Threading, Vcl.ExtCtrls,
  UserUtils, CodeSiteLogging;

const
  SFTP_PORT_DEFAULT = 22;

  PATH_DELIMETER_WINDOWS = '\\';
  PATH_DELIMETER_LINUX   = '/';

  SFTP_ERR_OK = 0;
  SFTP_ERR_NOT_CONNECTED = 1;

type

  //============================================================================
  //
  InFtpConnEvnt = procedure(bConnected : Boolean) of object;
  InFtpErrMsg = procedure(sMsg: string) of object;

  TFTPClient = class
    procedure FtpConnection(Sender : TObject);
    procedure FtpDisConnection(Sender : TObject);
  private
    FIsConnected: Boolean;
    FOnConnectedSetup: InFtpConnEvnt;
    FOnConnected: InFtpConnEvnt;
    FOnErrMsg: InFtpErrMsg;
    FIsConnectCheck: Boolean;
    MonitorTask: ITask;
    FIsTerminating : boolean;
    FTPMutex: TMutex;
    FMonitorTask: ITask;
    TerminationEvent: TEvent; // 모니터 작업 종료를 위한 이벤트 추가
    procedure SetIsConnected(const Value: Boolean);
    procedure SetOnConnected(const Value: InFtpConnEvnt);
    procedure SetOnErrMsg(const Value: InFtpErrMsg);
    procedure SetIsConnectCheck(const Value: Boolean);
    procedure HandleException(const E: Exception; const Action: string);
    function IsFtpStillConnected: Boolean;
    procedure MonitorTimerEvent;
  public
    FFTP : TIdFTP;
    m_WorkDir : string;
    constructor Create(sHost, sUserName, sPassword: string); overload;
    constructor Create(sHost, sUserName, sPassword: string; OnError: InFtpErrMsg); overload;
    destructor Destroy; override;
    function Connect: string;
    procedure Disconnect;
    function ChangeDir(sDir: string): string;
    function ChangeDirUp: string;
    function DeleteFile(sFile: string): string;
    function Get(sSourceFile, sDestFile: string): string;
    function List(var sList: TStringList;  sFile : string): string;
    function MakeDir(sPath: string): string;
    function MakeAndChangeDir(sDir: string): string;
    function Put(sSourceFile, sDestFile: string): string;
    function RetrieveCurrentDir(var sPath: string): string;
    function Size(sFileName: string; var nSize: integer): string;
    procedure StartMonitorTask;
    procedure StopMonitorTask;

    property IsConnectCheck : Boolean read FIsConnectCheck write SetIsConnectCheck;
    property IsConnected : Boolean read FIsConnected write SetIsConnected;
    property OnConnected : InFtpConnEvnt read FOnConnected write SetOnConnected;
    property OnErrMsg : InFtpErrMsg read FOnErrMsg write SetOnErrMsg;
  end;

implementation

{ TFTPClient }

constructor TFTPClient.Create(sHost, sUserName, sPassword: string);
begin
  FTPMutex := TMutex.Create;

  TerminationEvent := TEvent.Create; // 이벤트 생성
  FFTP := TIdFTP.Create(nil);

  with FFTP do begin
    Host     := sHost;
    Port     := 21;
    Username := sUserName;
    Password := sPassword;
    AutoIssueFEAT := True;
    ReadTimeout   := 60000;
    ConnectTimeout := 30000;
    Passive       := True;
    TransferType  := ftBinary;
    OnAfterClientLogin := FTPConnection;
    OnDisconnected     := FTPDisConnection;
  end;
  FIsTerminating := False;
end;


procedure TFTPClient.MonitorTimerEvent;
begin
  try
    if not IsFtpStillConnected then
    begin
      Connect;
    end;
  except
    on E: Exception do
    begin
      HandleException(E, 'MonitorTimerEvent');
    end;
  end;
end;

//procedure TFTPClient.StartMonitorTask;
//begin
//  if Assigned(FMonitorTask) and (FMonitorTask.Status = TTaskStatus.Running) then
//    Exit;
//
//  FMonitorTask := TTask.Run(procedure
//  begin
//    while not FIsTerminating do
//    begin
//      MonitorTimerEvent;
//      Sleep(2000); // 2초 간격
//    end;
//  end);
//end;

procedure TFTPClient.StartMonitorTask;
begin
  if Assigned(FMonitorTask) and (FMonitorTask.Status = TTaskStatus.Running) then
    Exit;

  FMonitorTask := TTask.Run(procedure
  begin
    while not FIsTerminating do
    begin
      if TerminationEvent.WaitFor(5000) = wrSignaled then
        Break; // 종료 이벤트가 설정되면 루프 종료
      MonitorTimerEvent;
    end;
  end);
end;

//procedure TFTPClient.StopMonitorTask;
//var
//  MaxWaitTime: Integer;
//  Stopwatch: TStopwatch;
//begin
//  FIsTerminating := True;
//  MaxWaitTime := 2000;
//  Stopwatch := TStopwatch.StartNew;
//
//  if Assigned(FMonitorTask) then
//  begin
//    while (FMonitorTask.Status = TTaskStatus.Running) and (Stopwatch.ElapsedMilliseconds < MaxWaitTime) do
//    begin
//      Sleep(100);
//    end;
//
//    if FMonitorTask.Status <> TTaskStatus.Running then
//      FMonitorTask := nil
//    else
//      CodeSite.Send('#FTP# StopMonitorTask timeout exceeded. Task could not be stopped gracefully.');
//  end;
//
//  Stopwatch.Stop;
//end;

procedure TFTPClient.StopMonitorTask;
var
  MaxWaitTime: Integer;
  Stopwatch: TStopwatch;
begin
  FIsTerminating := True;
  TerminationEvent.SetEvent; // 작업이 중지되도록 이벤트 설정

  MaxWaitTime := 5000; // 최대 대기 시간 5초
  Stopwatch := TStopwatch.StartNew;

  if Assigned(FMonitorTask) then
  begin
    while (FMonitorTask.Status = TTaskStatus.Running) and (Stopwatch.ElapsedMilliseconds < MaxWaitTime) do
    begin
      Sleep(100); // 작업 종료 대기
    end;

    if FMonitorTask.Status <> TTaskStatus.Running then
      FMonitorTask := nil
    else
      CodeSite.Send('#FTP# StopMonitorTask: Monitor task could not be stopped gracefully.');
  end;

  Stopwatch.Stop;
end;


constructor TFTPClient.Create(sHost, sUserName, sPassword: string; OnError: InFtpErrMsg);
begin
  Create(sHost, sUserName, sPassword);
  FOnErrMsg := OnError;
end;

destructor TFTPClient.Destroy;
begin
  FIsTerminating := True;
  StopMonitorTask;
  if FFTP <> nil then begin
    if FFTP.Connected then Disconnect;
    FreeAndNil(FFTP);
  end;
  FreeAndNil(FTPMutex);
  FreeAndNil(TerminationEvent); // 이벤트 해제
  inherited;
end;

procedure TFTPClient.FtpConnection(Sender: TObject);
begin
  FIsConnected := True;
  if FIsConnectCheck then OnConnected(True);
end;

procedure TFTPClient.FtpDisConnection(Sender: TObject);
begin
  FIsConnected := False;
  if FIsConnectCheck then OnConnected(False);
end;

procedure TFTPClient.SetIsConnectCheck(const Value: Boolean);
begin
  FIsConnectCheck := Value;
end;

procedure TFTPClient.SetIsConnected(const Value: Boolean);
begin
  FIsConnected := Value;
end;

procedure TFTPClient.SetOnConnected(const Value: InFtpConnEvnt);
begin
  FOnConnected := Value;
end;

procedure TFTPClient.SetOnErrMsg(const Value: InFtpErrMsg);
begin
  FOnErrMsg := Value;
end;

procedure TFTPClient.HandleException(const E: Exception; const Action: string);
begin
  CodeSite.Send(Format('#FTP# %s Error! E.Message=%s', [Action, E.Message]));
  if Assigned(OnErrMsg) then
    OnErrMsg(Format('<FTP> %s Error! E.Message=%s', [Action, E.Message]));
//  Disconnect;
end;

function TFTPClient.IsFtpStillConnected: Boolean;
begin
  Result := False;
  FTPMutex.Acquire; // 뮤텍스 잠금

  try
    if (FFTP.Connected) then
    begin
      try
        FFTP.Noop;  // 서버에 응답 요청
        Result := True;
      except
        on E: Exception do
        begin
          HandleException(E, 'IsFtpStillConnected');
          Disconnect;
        end;
      end;
    end;
  finally
    FTPMutex.Release; // 뮤텍스 해제
  end;
end;

function TFTPClient.Connect: string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    if FFTP.Connected then
      FFTP.Disconnect;
//    Sleep(10);
    FFTP.Connect;
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'Connect');
    end;
  end;
  Result := sErrMsg;
end;

procedure TFTPClient.Disconnect;
var
  Stopwatch: TStopwatch;
  MaxWaitTime: Integer;
begin
  MaxWaitTime := 5000;
  Stopwatch := TStopwatch.StartNew;
  try
    while FFTP.Connected do
    begin
      try
        FFTP.Disconnect;
      except
        on E: Exception do
          HandleException(E, 'Disconnect');
      end;
      if Stopwatch.ElapsedMilliseconds > MaxWaitTime then
      begin
        CodeSite.Send('#FTP# Disconnect timeout exceeded.');
        Break;
      end;
//      Sleep(100);
    end;
    if not FFTP.Connected then
      CodeSite.Send('#FTP# Disconnected successfully')
    else
      CodeSite.Send('#FTP# Failed to disconnect within the timeout');
  finally
    Stopwatch.Stop;
  end;
end;

function TFTPClient.ChangeDir(sDir: string): string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    if sDir <> '' then FFTP.ChangeDir(sDir);
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'ChangeDir');
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.ChangeDirUp: string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    FFTP.ChangeDirUp;
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'ChangeDirUp');
    end;
  end;
  Result := sErrMsg;
end;


function TFTPClient.DeleteFile(sFile: string): string;
var
  sErrMsg: string;
begin
  sErrMsg := '';

  try
    FFTP.Delete(sFile);
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'DeleteFile');
    end;
  end;
  Result := sErrMsg;
end;

//function TFTPClient.DeleteFile(sFile: string): string;
//var
//  sErrMsg: string;
//begin
//  sErrMsg := '';
//  try
//    FFTP.Delete(sFile);
//  except
//    on E: Exception do
//    begin
//      sErrMsg := Trim(E.Message);
//      HandleException(E, 'DeleteFile');
//    end;
//  end;
//  Result := sErrMsg;
//end;

function TFTPClient.Get(sSourceFile, sDestFile: string): string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  FTPMutex.Acquire; // 뮤텍스 잠금
  try
    try
      // 파일 목록을 가져와서 파일이 있는지 확인
//      List(FileList, sSourceFile);
//      if FileList.Count > 0 then
//      begin
        // 파일이 존재하는 경우 다운로드 시도
        FFTP.Get(sSourceFile, sDestFile, True);
//      end
//      else
//      begin
//        sErrMsg := 'File does not exist on server.';
//      end;
    except
      on E: Exception do
      begin
        sErrMsg := Trim(E.Message);
        HandleException(E, 'Get');
      end;
    end;
  finally
    FTPMutex.Release; // 뮤텍스 해제
//    FileList.Free;
  end;

  Result := sErrMsg;
end;

//
//function TFTPClient.Get(sSourceFile, sDestFile: string): string;
//var
//  sErrMsg: string;
//begin
//  sErrMsg := '';
//  try
//    FFTP.Get(sSourceFile, sDestFile, True);
//  except
//    on E: Exception do
//    begin
//      sErrMsg := Trim(E.Message);
//      HandleException(E, 'Get');
//    end;
//  end;
//  Result := sErrMsg;
//end;

function TFTPClient.List(var sList: TStringList; sFile : string): string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    FFTP.List(sList, sFile, False);
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'List');
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.MakeDir(sPath: string): string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    FFTP.MakeDir(sPath);
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'MakeDir');
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.MakeAndChangeDir(sDir: String): string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    FFTP.MakeDir(sDir);
    FFTP.ChangeDir(sDir);
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      if E.Message = 'Directory already exists' then
        FFTP.ChangeDir(sDir)
      else
        HandleException(E, 'MakeAndChangeDir');
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.Put(sSourceFile, sDestFile: string): string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    FFTP.Put(sSourceFile, sDestFile);
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'Put');
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.RetrieveCurrentDir(var sPath: string): string;
var
  sErrMsg: string;
begin
  sPath := '';
  sErrMsg := '';
  try
    sPath := FFTP.RetrieveCurrentDir;
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'RetrieveCurrentDir');
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.Size(sFileName: string; var nSize: integer): string;
var
  sErrMsg: string;
begin
  nSize := 0;
  sErrMsg := '';
  try
    nSize := FFTP.Size(sFileName);
  except
    on E: Exception do
    begin
      sErrMsg := Trim(E.Message);
      HandleException(E, 'Size');
    end;
  end;
  Result := sErrMsg;
end;

end.
