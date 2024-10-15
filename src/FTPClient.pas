unit FTPClient;

interface
{$I Common.inc}

uses
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.SysUtils, System.Variants,
  DateUtils, IOUtils, StrUtils, System.Diagnostics,

  IdFTP, IdFTPCommon, IdFTPListParseWindowsNT, IdFTPList,
  DefCommon, CommonClass,
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
    procedure SetIsConnected(const Value: Boolean);
    procedure SetOnConnected(const Value: InFtpConnEvnt);
    procedure SetOnErrMsg(const Value: InFtpErrMsg);
    procedure SetIsConnectCheck(const Value: Boolean);
    procedure HandleException(const E: Exception; const Action: string);
  public
    FFTP : TIdFTP;
    m_WorkDir : string;
    property IsConnectCheck : Boolean read FIsConnectCheck write SetIsConnectCheck;
    property IsConnected : Boolean read FIsConnected write SetIsConnected;
    property OnConnected : InFtpConnEvnt read FOnConnected write SetOnConnected;
    property OnErrMsg : InFtpErrMsg read FOnErrMsg write SetOnErrMsg;
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
  end;

implementation

{ TFTPClient }

constructor TFTPClient.Create(sHost, sUserName, sPassword: string);
begin
  FFTP := TIdFTP.Create(nil);
  with FFTP do begin
    Host     := sHost;
    Port     := 21;
    Username := sUserName;
    Password := sPassword;
    AutoIssueFEAT := True;
    ReadTimeout   := 30000;
    ConnectTimeout := 15000;
    Passive       := True;
    TransferType  := ftBinary;
    OnAfterClientLogin := FTPConnection;
    OnDisconnected     := FTPDisConnection;
  end;
end;

constructor TFTPClient.Create(sHost, sUserName, sPassword: string; OnError: InFtpErrMsg);
begin
  Create(sHost, sUserName, sPassword);
  FOnErrMsg := OnError;
end;

destructor TFTPClient.Destroy;
begin
  if FFTP <> nil then begin
    if FFTP.Connected then Disconnect;
    FreeAndNil(FFTP);
  end;
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

function TFTPClient.Connect: string;
var
  sErrMsg: string;
begin
  sErrMsg := '';
  try
    if FFTP.Connected then
      FFTP.Disconnect;
    Sleep(10);
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
      Sleep(100);
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
  FileList: TStringList;
begin
  sErrMsg := '';
  FileList := TStringList.Create;
  try
    try
      // 파일 목록을 가져와서 파일이 있는지 확인
      List(FileList, sFile);
      if FileList.Count > 0 then
      begin
        // 파일이 존재하는 경우 삭제 시도
        FFTP.Delete(sFile);
      end;
    except
      on E: Exception do
      begin
        sErrMsg := Trim(E.Message);
        HandleException(E, 'DeleteFile');
      end;
    end;
  finally
    FileList.Free;
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
  FileList: TStringList;
begin
  sErrMsg := '';
  FileList := TStringList.Create;
  try
    try
      // 파일 목록을 가져와서 파일이 있는지 확인
      List(FileList, sSourceFile);
      if FileList.Count > 0 then
      begin
        // 파일이 존재하는 경우 다운로드 시도
        FFTP.Get(sSourceFile, sDestFile, True);
      end
      else
      begin
        sErrMsg := 'File does not exist on server.';
      end;
    except
      on E: Exception do
      begin
        sErrMsg := Trim(E.Message);
        HandleException(E, 'Get');
      end;
    end;
  finally
    FileList.Free;
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
