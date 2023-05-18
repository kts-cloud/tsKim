unit FTPClient;

interface
{$I Common.inc}

uses
  Winapi.Windows, Winapi.Messages, 
	System.Classes, System.SysUtils, System.Variants,
	DateUtils, IOUtils, StrUtils, 

	IdFTP, IdFTPCommon, IdFTPListParseWindowsNT, IdFTPList, 
//IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
//IdExplicitTLSClientServerBase, 
	DefCommon, CommonClass,
  UserUtils, CodeSiteLogging;

const
	SFTP_PORT_DEFAULT = 22;

	PATH_DELIMETER_WINDOWS = '\';
	PATH_DELIMETER_LINUX   = '/';


  SFTP_ERR_OK = 0;
  SFTP_ERR_NOT_CONNECTED = 1;

type

  //============================================================================
  //
  InFtpConnEvnt = procedure(bConnected : Boolean) of object;
  InFtpErrMsg = procedure(nCh: Integer; sMsg: string) of object;

  TFTPClient = class
    procedure FtpConnection(Sender : TObject);
    procedure FtpDisConnection(Sender : TObject);
  private
    FIsConnected: Boolean;
  //FIsSetUpWindow: Boolean;
    FOnConnectedSetup: InFtpConnEvnt;
    FOnConnected: InFtpConnEvnt;
    FOnErrMsg: InFtpErrMsg;
    FIsConnectCheck: Boolean;
    // Common for FTP
    procedure SetIsConnected(const Value: Boolean);
  //procedure SetIsSetUpWindow(const Value: Boolean);
  //procedure SetOnConnectedSetup(const Value: InFtpConnEvnt);
    procedure SetOnConnected(const Value: InFtpConnEvnt);
    procedure SetOnErrMsg(const Value: InFtpErrMsg);
    procedure SetIsConnectCheck(const Value: Boolean);
  //procedure SendMainGuiDisplay(nGuiMode, nCh: Integer; nParam{0:Disconnected,1:COnnected}: Integer; sMsg: string = ''); //2019-04-09

  public
		FFTP : TIdFTP;
		//
    m_WorkDir : string;  //TBD?
    //
  //property IsSetUpWindow : Boolean read FIsSetUpWindow write SetIsSetUpWindow;
    property IsConnectCheck : Boolean read FIsConnectCheck write SetIsConnectCheck;
    property IsConnected : Boolean read FIsConnected write SetIsConnected;
    property OnConnected : InFtpConnEvnt read FOnConnected write SetOnConnected;
  //property OnConnectedSetup : InFtpConnEvnt read FOnConnectedSetup write SetOnConnectedSetup;
    property OnErrMsg : InFtpErrMsg read FOnErrMsg write SetOnErrMsg;
    //
		constructor Create(sHost, sUserName, sPassword: string); //TBD: m_nCh?
		destructor Destroy; override;
		//
		function Connect: string;
		procedure Disconnect;
		//
    function ChangeDir(sDir: string): string;
    function ChangeDirUp: string;
		function DeleteFile(sFile: string): string;
    function Get(sSourceFile, sDestFile: string): string;
		function List(var sList: TStringList): string;
		function MakeDir(sPath: string): string;
		function MakeAndChangeDir(sDir: string): string;
    function Put(sSourceFile, sDestFile: string): string;
		function RetrieveCurrentDir(var sPath: string): string;
		function Size(sFileName: string; var nSize: integer): string;
  end;

implementation

{ TFTPClient }

//==============================================================================
// TFTPClient Create/Destory
//		- 
//		- destructor TFTPClient.Destroy;
//==============================================================================

constructor TFTPClient.Create(sHost, sUserName, sPassword: string);
begin
  FFTP := TIdFTP.Create(nil);
  with FFTP do begin
  	Host     := sHost;
  	Port     := 21;
  	Username := sUserName;
  	Password := sPassword;
		//
  //AUTHCmd   := tAuto; //2023-02-08 (Do NOT set AUTHCmd to tAuto for PG_DP860) !!!
    AutoIssueFEAT := True;
  	ReadTimeout   := 10000; //TBD? 5000?
  	Passive       := True;
  	TransferType  := ftBinary;
		//
  	OnAfterClientLogin := FTPConnection;
  	OnDisconnected     := FTPDisConnection;

		//?????? TBD?
		//-------------------------------------------- TIdFTP Events
  	//		Name                 	Description
  	//		OnAfterGet            Event handler signalled following completion of data transfer in the Get method.
  	//		OnBannerAfterLogin    Event handler signalled following completion of the FTP protocol exchange in the Login method and receipt of the LoginMsg text.
  	//		OnBannerBeforeLogin   Event handler signalled after receipt of the welcome message, and before logging into the FTP server.
  	//		OnCreateFTPList       Event handler signalled for creation of the structured directory listing for the FTP client.
  	//		OnDataChannelCreate   Event handler signalled following creation of the data channel for data transfer operations.
  	//		OnDataChannelDestroy  Event handler signalled prior to freeing the data channel in the FTP client.
  	//		OnNeedAccount         Derives Account information for the remote FTP Server.
  	//		OnTLSNotAvailable     Event handler signalled when the client has failed to provide implied support for TLS (Transport Layer Security).
	end;
end;

destructor TFTPClient.Destroy;
begin
  if FFTP <> nil then begin
    if FFTP.Connected then FFTP.Disconnect;
    FreeAndNil(FFTP);
  end;
	//
  inherited;
end;

//==============================================================================
// TFTPClient XXXXX
//		-
//		-
//==============================================================================

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

//==============================================================================
// TFTPClient File Connect/Disconnect
//		- procedure TFTPClient.Connect: string;
//		- procedure TFTPClient.DisConnect;
//==============================================================================

function TFTPClient.Connect: string;
var
  sErrMsg : string;
begin
  sErrMsg := '';
  try
    if FFTP.Connected then
      FFTP.Disconnect;
    Sleep(10);
    //
  	FFTP.Connect;
    //
    //DFS DfsFtpConnOK := True;
    //DFS SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_STATUS, m_nCh, 1{0:Disconnected,1:Connected});
  except
    on E: Exception do begin
      sErrMsg := Trim(E.Message);
      CodeSite.Send('#FTP# Connect Error! E.Message=' + E.Message);
    //DFS Common.MLog(m_nCh, '<DFS> FTP Connect Error! E.Message=' + E.Message);
    //DFS if Assigned(OnErrMsg) then OnErrMsg(0, '<DFS> FTP Connect Error! E.Message=' + E.Message);
      FFTP.DisConnect;
    //DFS DfsFtpConnOK := False;
    //DFS SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_STATUS, m_nCh, 0{0:Disconnected,1:Connected});
    end;
  end;
	//
  Result := sErrMsg;
end;

procedure TFTPClient.Disconnect;
begin
  try
  	FFTP.Disconnect;
  except
    on E: Exception do begin
      CodeSite.Send('#FTP# Disonnect Error! E.Message=' + E.Message);
    end;
  end;
end;
//==============================================================================
// TFTPClient File Upload/Download
//		- function TFTPClient.Put(sSourceFile, sDestFile: string): Integer;
//		- procedure TFTPClient.Get
//==============================================================================



//==============================================================================
// XXXXX for TFTPClient
//		-
//		-
//==============================================================================

function TFTPClient.ChangeDir(sDir: string): string;
var
  sWorkDir : string;
  sErrMsg : string;
begin
  sErrMsg := '';
  CodeSite.Send('<FTP> ChangeDir('+sDir+')');
	//
  try
    if sDir <> '' then FFTP.ChangeDir(sDir);
  except
    // ChangeDir
    // 500  Syntax error, command unrecognized. (This may include errors such as command line too long.)
    // 501  Syntax error in parameters or arguments.
    // 502  Command not implemented.
    // 421  Service not available, closing control connection. (This may be a reply to any command if the service knows it must shut down.)
    // 530  Not logged in.
    // 550  Requested action not taken. File unavailable (e.g., file not found, no access).
    on E:Exception do begin
      sErrMsg := 'FTP.ChangeDir NG('+Trim(E.Message)+')';
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.ChangeDirUp: string;
var
  sWorkDir : string;
  sErrMsg  : string;
begin
  CodeSite.Send('<FTP> ChangeDirUp');
  sErrMsg := '';
	//
  try
    FFTP.ChangeDirUp;
  except
    // ChangeDir
    // 500  Syntax error, command unrecognized. (This may include errors such as command line too long.)
    // 501  Syntax error in parameters or arguments.
    // 502  Command not implemented.
    // 421  Service not available, closing control connection. (This may be a reply to any command if the service knows it must shut down.)
    // 530  Not logged in.
    // 550  Requested action not taken. File unavailable (e.g., file not found, no access).
    on E:Exception do begin
      sErrMsg := 'FTP.ChangeDirUp NG('+Trim(E.Message)+')';
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.DeleteFile(sFile: string): string;
var
  sErrMsg, sTempErr : string;
begin
  sErrMsg := '';
  try
    FFTP.Delete(sFile); // Removes a file on the FTP server file system
  except
    on E: Exception do begin
      sTempErr := Trim(E.Message);
      if (Pos(LowerCase('File not found'),LowerCase(sTempErr)) <> 0) and
         (Pos(LowerCase('No such file or directory'),LowerCase(sTempErr)) <> 0)
      then begin
        sErrMsg := 'FTP.Delete NG('+Trim(E.Message)+')';
        FFTP.DisConnect;
      end;
    end;
  end;
  Result := sErrMsg;
end;


function TFTPClient.Get(sSourceFile, sDestFile: string): string;
var
  sErrMsg : string;
begin
  sErrMsg := '';
	// Check Connection
//if not FFTP.Connected then Exit;
  // Check and Move Remote (RemotePath)

  // Check Remote (RemoteFile)
  // Check Local (LocalPath)

  // Download File
  try
  	FFTP.Get(sSourceFile, sDestFile, True{bCanOverwrite});
  except
    on E: Exception do begin
      sErrMsg := 'FTP.Get NG('+Trim(E.Message)+')';
      FFTP.DisConnect;
    end;
  end;
  Result := sErrMsg;
end;


function TFTPClient.List(var sList: TStringList): string;
var
  sErrMsg : string;
begin
  sErrMsg := '';
  try
    FFTP.List(sList, '', False);
  except
    on E: Exception do begin
      sErrMsg := 'FTP.List NG('+Trim(E.Message)+')';
      FFTP.DisConnect;
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.MakeDir(sPath: string): string;
var
  sErrMsg : string;
begin
  sErrMsg := '';
  try
    FFTP.MakeDir(sPath);
  except
    on E: Exception do begin
      sErrMsg := 'FTP.MakeDir NG('+Trim(E.Message)+')';
      FFTP.DisConnect;
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.MakeAndChangeDir(sDir: String): string;
var
  sErrMsg : string;
begin
  sErrMsg := '';
  try
    FFTP.MakeDir(sDir);
    Common.Delay(50);
    FFTP.ChangeDir(sDir);
    Common.Delay(50);
  except
    on E: Exception do begin
      if sErrMsg = 'Directory already exists' then begin
      	FFTP.ChangeDir(sDir);
      	Common.Delay(50);
			end
			else begin
        sErrMsg := 'FTP.MakeAndChangeDir NG('+Trim(E.Message)+')';
			end;
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.Put(sSourceFile, sDestFile: string): string;
var
  sErrMsg : string;
begin
  sErrMsg := '';
	// Check Connection
	// Check Local (LocalPath, LocalFilename)
//sLocalFullPath := sLocalPath + PATH_DELIMETER_WINDOWS + sLocalFile;
	// Check and Move Remote (RemotePath)
  try
    FFTP.Put(sSourceFile, sDestFile);
  except
    on E: Exception do begin
      sErrMsg := 'FTP.Put NG('+Trim(E.Message)+')';
      FFTP.DisConnect;
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.RetrieveCurrentDir(var sPath: string): string;
var
  sErrMsg : string;
begin
  sPath   := '';
  //
  sErrMsg := '';
  try
    sPath := FFTP.RetrieveCurrentDir;
  except
    on E: Exception do begin
      sErrMsg := 'FTP.RetrieveCurrentDir NG('+Trim(E.Message)+')';
      FFTP.DisConnect;
    end;
  end;
  Result := sErrMsg;
end;

function TFTPClient.Size(sFileName: string; var nSize: integer): string;
var
  sErrMsg : string;
begin
  nSize := 0;
  //
  sErrMsg := '';
  try
    nSize := FFTP.Size(sFileName);
  except
    on E: Exception do begin
      sErrMsg := 'FTP.Size NG('+Trim(E.Message)+')';
      FFTP.DisConnect;
    end;
  end;
  Result := sErrMsg;
end;

end.
