unit DfsFtp;

interface
{$I Common.inc}

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdFTP, IdFTPCommon, IdFTPListParseWindowsNT,
  IdFTPList, CommonClass, Math, StrUtils,CommLog,
  Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc, DefCommon, GMesCom;

type

  //============================================================================
  PMainGuiDfsData = ^RMainGuiDfsData;   // to FrmMain //2019-04-09
  RMainGuiDfsData = record
    MsgType   : Integer;
    Channel   : Integer;
    Mode      : Integer;
    Param     : Integer;
    Msg       : string[250];
  end;

  //
  InFtpConnEvnt = procedure(bConnected : Boolean) of object;
  InFtpErrMsg = procedure(nCh: Integer; sMsg: string) of object;

  TDfsRetInfo = record
{$IFDEF DFS_HEX} //REF_ISPD_DFS
    HexFileName     : String;
{$ENDIF}
{$IFDEF DFS_DEFECT} //REF_ISPD_DFS
    nDefectCnt      : Integer;
    nPreDefectCnt   : Integer;
    PreSampling     : array of string; // ¢Æ| ~Dê³µì| ~U Sampling Rate
    PreDftName      : array of string; // ¢Æ| ~Dê³µì| ~U ë¶~H¢Æ~_~Iëª~E
    PreDftCode      : array of string; // ¢Æ| ~Dê³µì| ~U ë¶~H¢Æ~_~Iì½~T¢Æ~S~\
    PreDftLocation  : array of string; // ¢Æ| ~Dê³µì| ~U ë¶~H¢Æ~_~I ¢Æ~\~Dì¹~X
    PreGridMode     : array of string; // ¢Æ| ~Dê³µì| ~U Grid Mode
    PreDftLevel     : array of string; // ¢Æ| ~Dê³µì| ~U ë¶~H¢Æ~_~I ¢Æ~H~Xì¤~@
    PreHando        : array of string; // ¢Æ| ~Dê³µì| ~U ¢Æ~U~\¢Æ~O~D ¢Æ~L~@ë¹~D OK/NG
    bGibReport      : Boolean;
    GibOKName       : array of string; // ¢Æ| ~Dê³µì| ~U GIB OK ¢Æ~]´ì~\|
    GibOKCode       : array [0..99] of string; // ¢Æ| ~Dê³µì| ~U GIB OK ì½~T¢Æ~S~\
    TempDftCode     : array [0..99] of string; // ë¶~H¢Æ~_~I ì½~T¢Æ~S~\ ¢Æ~^~D¢Æ~K~\ ¢Æ| ~@¢Æ~^¢Æ
    DftRsltCode     : array [0..99] of string; // ¢Æ~X~Dê³µì| ~U ë¶~H¢Æ~_~I ì½~T¢Æ~S~\
    DftRsltName     : array of string; // ¢Æ~X~Dê³µì| ~U ë¶~H¢Æ~_~Iëª~E
    DftRsltLocation : array of string; // ¢Æ~X~Dê³µì| ~U ë¶~H¢Æ~_~I¢Æ~\~Dì¹~X
    DftRsltLevel    : array of string; // ¢Æ~X~Dê³µì| ~U ë¶~H¢Æ~_~I¢Æ~H~Xì¤~@
    DftRsltOKNG     : array of string; // ¢Æ~X~Dê³µì| ~U ¢Æ~U~\¢Æ~O~D ¢Æ~L~@ë¹~D OK/NG
    FinalDftNG      : Boolean;
    FinalDftName    : string;
    FinalDftCode    : string;
    DefectFileName  : string;
    LotID           : string;
{$ENDIF}
  end;

  TDfsFtp = class
//    ftp : TIdFTP;
    procedure FtpConnection(Sender : TObject);
    procedure FtpDisConnection(Sender : TObject);
  private
    ftp : TIdFTP;
    m_nCh : Integer;
    prSeed, LayerCount, LayerSize : Integer;
{$IFDEF DFS_DEFECT}    //TBD?
    m_XMLDefectFile : TXMLDocument;
  //iNodeRoot, iNodePanel, iNodeHeader, iNodeBody : IXMLNode;
  //iNodeAPInfo, iNodeDfInfo, iNodeTemp : IXMLNode;
{$ENDIF}
    FIsConnected: Boolean;
    FIsSetUpWindow: Boolean;
    FOnConnectedSetup: InFtpConnEvnt;
    FOnConnected: InFtpConnEvnt;
    FOnErrMsg: InFtpErrMsg;
    FIsConnectCheck: Boolean;
    // Common for FTP
    procedure SetIsConnected(const Value: Boolean);
    procedure SetIsSetUpWindow(const Value: Boolean);
    procedure SetOnConnectedSetup(const Value: InFtpConnEvnt);
    procedure SetOnConnected(const Value: InFtpConnEvnt);
    procedure SetOnErrMsg(const Value: InFtpErrMsg);
    procedure SetIsConnectCheck(const Value: Boolean);
    procedure SendMainGuiDisplay(nGuiMode, nCh: Integer; nParam{0:Disconnected,1:COnnected}: Integer; sMsg: string = ''); //2019-04-09

  public
    m_hMain : HWND;  //2019-04-09
    m_DfsRetInfo : TDfsRetInfo;
    m_DfsFtpServerHome : String;
    //
    property IsSetUpWindow : Boolean read FIsSetUpWindow write SetIsSetUpWindow;
    property IsConnectCheck : Boolean read FIsConnectCheck write SetIsConnectCheck;
    property IsConnected : Boolean read FIsConnected write SetIsConnected;
    property OnConnected : InFtpConnEvnt read FOnConnected write SetOnConnected;
    property OnConnectedSetup : InFtpConnEvnt read FOnConnectedSetup write SetOnConnectedSetup;
    property OnErrMsg : InFtpErrMsg read FOnErrMsg write SetOnErrMsg;
    // Common for FTP
    constructor Create(sIP, sUserName, sPassword : string; nCh : Integer); virtual;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    procedure List(var sList: TStringList);
    function Size(sFileName: string): Integer;
    procedure MakeDir(sPath: string);
    procedure MakeAndChangeDir(sDir: String);
    procedure Delete(sFile: string);
    procedure Get(sSource, sDest: string);
    procedure Put(sSource, sDest: string);
    procedure ChangeDirUp;
    function CheckChangeDir(sAddDir: string): Boolean;
    function RetrieveCurrentDir: string;
    procedure ChangeDir(sPath : string);
{$IFDEF DFS_HEX}
    // DFS COMMON : COMBI, HASH, ...
    function GetDfsHashPath(sPanelId: String): String;
    function GetDfsHashValue(pKeyStr: String) : Integer;
    function TranHashValue2NumberInLayer(hashValue, layerNumber: Integer): Double;
    function GetDfsFullNameFromIdxFile(sIdxFile: string): string; // Defect(INDEX File), Hex(HEX_INDEX file)
    function UpdateDfsIdxFile(sIdxFileName, sAppendFullName: String): String; // Defect(INDEX File), Hex(HEX_INDEX file)
    procedure DownloadCombiFile;
    // DFS_HEX : DEFECT/HEX_INDEX, DEFECT/HEX
    function DfsHexFilesDownload(sPid: string): Boolean;   // (For ¿­È­º¸»ó±â) Download HexIndex and Hex files
    function DfsHexFilesUpload(sPid: String; sStartTime: TDateTime; sBinFullName: String) : Integer;  // (For POCB) Upload HexIndex and Hex files
  //procedure DownloadDfsHexIdxFile;
  //procedure DownloadDfsHexFile;
  //procedure UploadDfsHexIdxFile;  //Upload HexIndex
  //DEL! procedure UploadDfsHexFile;     //Upload Hex
{$ENDIF}
{$IFDEF DFS_DEFECT}
    // DFS_DEFECT : DEFECT/INDEX, DEFECT/INSPECTOR and more?
{$ENDIF}
  end;

var
  DfsFtpCh : array [DefCommon.CH1 .. DefCommon.MAX_CH] of TDfsFtp;
  DfsFtpCommon : TDfsFtp;
  DfsFtpConnOK : Boolean; //if ant FTP connect failed, then False //2019-04-09
//DfsFtpCombi  : TDfsFtp;

implementation

{ TDfsFtp }

//==============================================================================
// Common for FTP
//==============================================================================

procedure TDfsFtp.ChangeDir(sPath: string);
begin
  ftp.ChangeDir(sPath);
end;

procedure TDfsFtp.ChangeDirUp;
begin
  ftp.ChangeDirUp;
end;

function TDfsFtp.CheckChangeDir(sAddDir: string): Boolean;  //TBD? by Clint?
var
  i: Integer;
  slList : TStringList;
  bIsFolder : Boolean;
  sCurDir, sNewDir : string;
begin
  try
    slList := nil;
    try
      sCurDir := ftp.RetrieveCurrentDir + '/';
      slList := TStringList.Create;
      ftp.List(slList, '', False);
      bIsFolder := False;
      for i := 0 to Pred(slList.Count) do begin
        if sAddDir = Trim(slList[i]) then begin
          bIsFolder := True;
          Break;
        end;
      end;
      sNewDir := sCurDir+sAddDir+'/';
      if not bIsFolder then begin
        ftp.MakeDir(sNewDir);
        Sleep(50);
      end;
      ftp.ChangeDir(sNewDir);
      Sleep(50);
    finally
      slList.Free;
    end;
    Result := True;
  except
    Result := False;
  end;

{var

begin
  lstHostFiles.Items.Clear;

end;}
end;

procedure TDfsFtp.Connect;
begin
  try
    if ftp.Connected then ftp.Disconnect;
    if LogCommon <> nil then
      LogCommon.mlog(m_nCh, '<DFS> FTP Connect to ' + ftp.Host);
    ftp.Connect;
    DfsFtpConnOK := True;
    SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_CONNECTION, m_nCh, 1{0:Disconnected,1:Connected}); //2019-04-09
  except
    on E: Exception do begin
      if LogCommon <> nil then
        LogCommon.mlog(m_nCh, '<DFS> FTP Connect Error! E.Message=' + E.Message);
      if Assigned(OnErrMsg) then OnErrMsg(0, '<DFS> FTP Connect Error! E.Message=' + E.Message);
      ftp.DisConnect;
      DfsFtpConnOK := False;
      SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_CONNECTION, m_nCh, 0{0:Disconnected,1:Connected}); //2019-04-09
    end;
  end;
end;

constructor TDfsFtp.Create(sIP, sUserName, sPassword : string; nCh : Integer);
begin
  m_nCh := nCh;
//TBD? {$IF Defined(ISPD_A)}
//TBD?   m_XMLDefectFile := frmMainA.XMLDefectFile;
//TBD? {$ELSEIF Defined(ISPD_L)}
//TBD?   m_XMLDefectFile := frmMainL.XMLDefectFile;
//TBD? {$IFEND}

  ftp := TIdFtp.Create(nil);
  ftp.AUTHCmd := tAuto;
  ftp.AutoIssueFEAT := True;
  ftp.ReadTimeout := 5000;
  ftp.Passive := True;

  ftp.Host := sIP;
  ftp.Port := 21;
  ftp.Username := sUserName;
  ftp.Password := sPassword;
  ftp.OnAfterClientLogin := FtpConnection;
  ftp.TransferType := ftBinary;
  ftp.OnDisconnected := FtpDisConnection;
  //
  m_DfsFtpServerHome := '';
end;


procedure TDfsFtp.Delete(sFile: string);
begin
  ftp.Delete(sFile);
end;

destructor TDfsFtp.Destroy;
begin
  if ftp <> nil then begin
    if ftp.Connected then ftp.Disconnect;
    ftp.Free;
    ftp := nil;
  end;
  inherited;
end;

procedure TDfsFtp.DisConnect;
begin
  if ftp.Connected then ftp.Disconnect;
end;

procedure TDfsFtp.FtpConnection(Sender: TObject);
begin
  FIsConnected := True;
  if FIsConnectCheck then OnConnected(True);
  if FIsSetUpWindow then Self.OnConnectedSetup(True);
end;

procedure TDfsFtp.FtpDisConnection(Sender: TObject);
begin
  FIsConnected := False;
  if FIsConnectCheck then OnConnected(False);
  if FIsSetUpWindow then Self.OnConnectedSetup(False);
//  if FIsSetUpWindow then Self.OnConnectedSetup(False)
//  else                   Self.OnConnected(False);
end;

procedure TDfsFtp.Get(sSource, sDest: string);
begin
  ftp.Get(sSource, sDest, True);
end;

procedure TDfsFtp.List(var sList: TStringList);
begin
  ftp.List(sList, '', False);
end;

procedure TDfsFtp.MakeAndChangeDir(sDir: String);
begin
  try
    if LogCommon <> nil then
      LogCommon.mlog(m_nCh, '<DFS> DFS FOLDER DIRECTORY MAKE[' + sDir + ']');
    DfsFtpCh[m_nCh].MakeDir(sDir);
    Common.Delay(50);

    if LogCommon <> nil then
      LogCommon.mlog(m_nCh, '<DFS> DFS FOLDER DIRECTORY CHANGE[' + sDir + ']');
    DfsFtpCh[m_nCh].ChangeDir(sDir);
    Common.Delay(50);
  except
    on E: Exception do begin
      if LogCommon <> nil then
        LogCommon.mlog(m_nCh, '<FILE_SVR> FTP MakeAndChangeDir Control Error! E.Message=' + E.Message);
      DfsFtpCh[m_nCh].ChangeDir(sDir);
      Common.Delay(50);
    end;
  end;
end;

procedure TDfsFtp.MakeDir(sPath: string);
begin
  ftp.MakeDir(sPath);
end;

procedure TDfsFtp.Put(sSource, sDest: string);
begin
  try
    ftp.Put(sSource, sDest);
  except  //2019-02-08
    on E: Exception do begin
      if LogCommon <> nil then
        LogCommon.mlog(0, '<FILE_SVR> FTP PUT Error! E.Message=' + E.Message);
    end;
  end;
end;

function TDfsFtp.RetrieveCurrentDir: string;
begin
  Result := ftp.RetrieveCurrentDir;
end;

procedure TDfsFtp.SetIsConnectCheck(const Value: Boolean);
begin
  FIsConnectCheck := Value;
end;

procedure TDfsFtp.SetIsConnected(const Value: Boolean);
begin
  FIsConnected := Value;
end;

procedure TDfsFtp.SetIsSetUpWindow(const Value: Boolean);
begin
  FIsSetUpWindow := Value;
end;

procedure TDfsFtp.SetOnConnected(const Value: InFtpConnEvnt);
begin
  FOnConnected := Value;
end;

procedure TDfsFtp.SetOnConnectedSetup(const Value: InFtpConnEvnt);
begin
  FOnConnectedSetup := Value;
end;

procedure TDfsFtp.SetOnErrMsg(const Value: InFtpErrMsg);
begin
  FOnErrMsg := Value;
end;

function TDfsFtp.Size(sFileName: string): Integer;
begin
  Result := ftp.Size(sFileName);
end;

{$IFDEF DFS_HEX}
//==============================================================================
// DFS COMMON : COMBI, HASH, ...
//==============================================================================
procedure TDfsFtp.DownloadCombiFile;
var
  i : Integer;
  sList, sList2 : TStringList;
  Rslt : Integer;
  SearchRec : TSearchRec;
begin
  if not DfsFtpCommon.IsConnected then begin
    DfsFtpCommon.Connect;
  end;

  try
    sList := TStringList.Create;
    sList2 := TStringList.Create;
    try
      ExtractStrings(['\'],[],PWideChar(Common.DfsConfInfo.sCombiDownPath),sList);
      for i := 0 to Pred(sList.Count) do begin
        DfsFtpCommon.ChangeDir(sList[i]);
      end;

      DfsFtpCommon.List(sList2);

      Rslt := FindFirst(Common.Path.CombiCode + '*.ini', faAnyFile, SearchRec);
      while Rslt = 0 do begin
        MoveFile(PChar(Common.Path.CombiCode + SearchRec.Name), PChar(Common.Path.CombiBackUp + SearchRec.Name));
        DeleteFile(PChar(Common.Path.CombiCode + SearchRec.Name));
        Rslt := FindNext(SearchRec);
      end;
      FindClose(SearchRec);

      for i := 0 to Pred(sList2.Count) do begin
        if (Pos('.ini',sList2[i]) > 0) then begin
          if LogCommon <> nil then
            LogCommon.mlog(DefCommon.MAX_SYSTEM_LOG, '<DFS> DOWNLOAD COMBI FILE NAME : ' + sList2[i]);
          DfsFtpCommon.Get(sList2[i], Common.Path.CombiCode + sList2[i]);
        end;
      end;

      //Common.LoadCombiFile;
    except
      on E: Exception do begin
        if LogCommon <> nil then
            LogCommon.mlog(m_nCh, '<DFS> FTP Transmission Error! E.Message=' + E.Message);
        if LogCommon <> nil then
          LogCommon.mlog(DefCommon.MAX_SYSTEM_LOG, '<DFS> COMBICODE DOWNLOAD FAIL.');

        DfsFtpCommon.DisConnect;
        Common.Delay(50);
      end;
    end;
  finally
    DfsFtpCommon.DisConnect;
    Common.Delay(50);
    sList.Free;
    sList := nil;
    sList2.Free;
    sList2 := nil;
  end;
end;

function TDfsFtp.GetDfsHashPath(sPanelId: String): String;
var
  IndexFilePath : string;
  dTemp         : Double;
  nDfsHashValue, nTemp : Integer;
begin
  try
    prSeed      := 7919;  // 1021  --> 7919
    LayerCount  := 1;
    if prSeed <= 157 then begin
      LayerSize     := prSeed;
    end
    else begin
      LayerCount  := 2;
      nTemp       := prSeed;
      LayerSize   := Trunc(nTemp / (Trunc(Power(prSeed, 0.5))));
    end;
    //
    nDfsHashValue := GetDfsHashValue(sPanelId);
    if LayerCount = 1 then begin
      dTemp         := TranHashValue2NumberInLayer(nDfsHashValue, 1);
      IndexFilePath := IndexFilePath + FormatFloat('00000000', dTemp);
    end
    else begin
      dTemp         := TranHashValue2NumberInLayer(nDfsHashValue, 0);
      IndexFilePath := IndexFilePath + FormatFloat('00000000', dTemp) + '\';
      dTemp         := TranHashValue2NumberInLayer(nDfsHashValue, 1);
      IndexFilePath := IndexFilePath + FormatFloat('00000000', dTemp);
    end;
    Result := IndexFilePath;
  except
    Result := '';
  end;
end;

function TDfsFtp.GetDfsHashValue(pKeyStr: String): Integer;
var
  i, tmpVal, strLength  : Integer;
  lTemp : Int64;
begin
  strLength := Length(pKeyStr);
  if strLength = 0 then begin
    Result := 0;
    Exit;
  end;
  //
  tmpVal := 0;
  for i := 0 to strLength - 1 do begin
    lTemp   := tmpVal;
    lTemp   := lTemp * $ff;
    lTemp   := lTemp + ($ff and Ord(pKeyStr[i+1]));
    tmpVal  := lTemp mod prSeed;
  end;
  Result := tmpVal;
end;

function TDfsFtp.TranHashValue2NumberInLayer(hashValue, layerNumber: Integer): Double;
var
  functionReturnValue : Double;
begin
  if layerNumber = 0 then begin
    functionReturnValue := hashValue / LayerSize;
    functionReturnValue := functionReturnValue - 0.49999;
  end
  else begin
    functionReturnValue := hashValue mod LayerSize;
  end;

  Result := functionReturnValue;
end;

function TDfsFtp.GetDfsFullNameFromIdxFile(sIdxFile: String): String; // For Defect(INDEX File), Hex(HEX_INDEX file)
var
  fFs : TextFile;
  sFullName, sTemp : String;
begin
  AssignFile(fFs, sIdxFile);
  Reset(fFs);
  sFullName := '';
  try
    while not Eof(fFs) do begin
      ReadLn(fFs, sTemp);
      if sTemp <> '' then begin
        sFullName := sTemp;
      end;
    end;
  finally
    CloseFile(fFs);
  end;
  Result := sFullName;
end;

function TDfsFtp.UpdateDfsIdxFile(sIdxFileName, sAppendFullName: String): String; // For Defect(INDEX File), Hex(HEX_INDEX file)
var
  fFs   : TextFile;
  hFile : Integer;
begin
  try
    if not FileExists(sIdxFileName) then begin
      hFile := FileCreate(sIdxFileName);
      FileClose(hFile);
    end;
    AssignFile(fFs, sIdxFileName);
    Append(fFs);
    WriteLn(fFs, sAppendFullName);
    CloseFile(fFs);
    Sleep(10);  //2019-04-09
  except
  end;
end;
{$ENDIF}

{$IFDEF DFS_HEX}
//==============================================================================
// DFS_HEX : DEFECT/HEX_INDEX, DEFECT/HEX
//    - function DfsHexFilesDownload;      // Download HexIndex & Hex for ¿­È­º¸»ó±â
//    - function DfsHexFilesUpload;        // Upload HexIndex & Hex for POCB
//    - function DownloadDfsHexIdxFile;
//    - function DownloadDfsHexFile;
//    - function UpdateDfsHexIdxFile(sFName, sDfsFilePath: String): String;
//    - function UploadDfsHexFile;     //Upload Hex
// for old ---
//    CreateDfsHexFile
//    DownloadDfsHexIdxFile
//    ParseDfsHexFileDir
//    UpdateDfsIdxFile
//    UploadDefectFile --> UploadDfsHexFile
//==============================================================================
{$IFDEF DFS_IMSI_DELETE}}
procedure TDfsFtp.CreateDefectFile(bNew: Boolean; sDftFName: String);   //CreateDefectFile -->  CreateDfsHexFile    TBD??
var
  sDfsFileName, sDfsFullName : string;
begin
  sDfsFileName := PasScr[m_nCh].TestInfo.RtnPId + '_'
                  + Common.CombiCodeData.sProcessNo
                  + '_' + FormatDateTime('YYYYMMDD_HHNNSS', PasScr[m_nCh].TestInfo.StartTime)
                  + '.ZIP';     // For ZippedHexFile:ZIP, for DefectFile: Common.SystemInfo.EQPId

  sDfsFullName := Common.Path.INSPECTOR + FormatDateTime('MM', PasScr[m_nCh].TestInfo.StartTime) + '\';
  Common.CheckDir(sDfsFullName);
  sDfsFullName := sDfsFullName + FormatDateTime('DD', PasScr[m_nCh].TestInfo.StartTime) + '\';
  Common.CheckDir(sDfsFullName);
  sDfsFullName := sDfsFullName + Common.CombiCodeData.sRcpName + '\';
  Common.CheckDir(sDfsFullName);
  sDfsFullName := sDfsFullName + Common.SystemInfo.EQPId + '\';
  Common.CheckDir(sDfsFullName);
  sDfsFullName := sDfsFullName + sDfsFileName;

  if bNew then begin
    CreateXMLFile(sDfsFileName, sDfsFullName);
  end
  else begin
    RenameFile(PChar(sDftFName), PChar(sDfsFullName));
    OpenXMLFile(sDfsFullName);
  end;
end;
{$ENDIF}

function TDfsFtp.DfsHexFilesDownload(sPid: string): Boolean;
var
  i, nDirIdx : Integer;
  {sPid,} sRootDir, sErrMsg : string;
  sHexIdxServerPath, sDfsHashPath, sHexIdxFileName, sHexIdxServerFullName, sHexIdxLocalFullName : string;
  sHexServerFullName, sHexServerPath, sHexFileName, sHexLocalFullName : string;
//? sDfFileName, sDownDirDFT, sDownFileDFT : string;
  sList, sList2 : TStringList;
begin
  //------------------------------------ Check PanelId
  sErrMsg  := '';
  //sRootDir := '\'
  if sPid = '' then begin
    sErrMsg := '<DFS> HEX_INDEX File Download Fail (Panel ID is NOT exist) !';
    if LogCommon <> nil then
      LogCommon.mlog(m_nCh,sErrMsg);  //TBD:DFS?  OnErrMsg(m_nCh,sErrMsg);
    Exit(False);
  end;

  //------------------------------------ for HEX_INDEX file
  sDfsHashPath         := GetDfsHashPath(sPid);
  sHexIdxServerPath    := 'DEFECT\HEX_INDEX\' + sDfsHashPath;
  sHexIdxFileName      := UpperCase(sPid) + '.IDX';
  sHexIdxServerFullName:= sHexIdxServerPath + '\' + sHexIdxFileName;
  sHexIdxLocalFullName := Common.Path.DfsHexIndex + sHexIdxFileName;
  if FileExists(sHexIdxLocalFullName) then begin
    DeleteFile(sHexIdxLocalFullName);
  end;

  //------------------------------------ Connect DFS FTP server if not connected
  if not DfsFtpCh[m_nCh].IsConnected then begin
    DfsFtpCh[m_nCh].Connect;
    Common.Delay(1000);
  end;
  if not DfsFtpCh[m_nCh].IsConnected then begin
  //DfsFtpCh[m_nCh].DisConnect;
    sErrMsg := '<DFS> HEX_INDEX and HEX File Download Fail (DFS Server Not Connected)';
    if LogCommon <> nil then
      LogCommon.mlog(m_nCh, sErrMsg);
    //TBD? OnErrMsg(m_nCh, sErrMsg);
    Exit(False);
  end;

  try
    //---------------------------------- Download HEX_INDEX File
    try
      //sRootDir := '\';
      if LogCommon <> nil then
        LogCommon.mlog(m_nCh, '<DFS> FTP Directory Change [/DEFECT/HEX_INDEX]');
      DfsFtpCh[m_nCh].ChangeDir('DEFECT');
      DfsFtpCh[m_nCh].ChangeDir('HEX_INDEX');
      sList := TStringList.Create;
      ExtractStrings(['\'],[],PWideChar(sDfsHashPath),sList);
      for i := 0 to Pred(sList.Count) do begin
        DfsFtpCh[m_nCh].ChangeDir(sList[i]);  //Common.Delay(50);
      end;
      if LogCommon <> nil then
        LogCommon.mlog(m_nCh, '<DFS> HEX_INDEX File Downloading (' + sHexIdxServerFullName + ')');
      DfsFtpCh[m_nCh].Get(sHexIdxFileName, sHexIdxLocalFullName); //Common.Delay(50);
    except
      on E: Exception do begin
        DfsFtpCh[m_nCh].Disconnect; //Common.Delay(50);
        sErrMsg := '<DFS> HEX_INDEX File Download Fail (FTP Error: ' + E.Message + ')';
        if LogCommon <> nil then
          LogCommon.mlog(m_nCh, sErrMsg);
        //TBD? OnErrMsg(m_nCh, sErrMsg);
        Exit(False);
      end;
    end;
    if LogCommon <> nil then
      LogCommon.mlog(m_nCh, '<DFS> HEX_INDEX File Download OK ');

    // Parse HEX_INDEX and Get HEX File Location ---------------------
    sHexServerFullName := GetDfsFullNameFromIdxFile(sHexIdxLocalFullName);
    if LogCommon <> nil then
      LogCommon.mlog(m_nCh, '<DFS> HexFileName : ' + sHexServerFullName);
    if sHexServerFullName = '' then begin
      DfsFtpCh[m_nCh].Disconnect; //Common.Delay(50);
      sErrMsg := '<DFS> HEX_INDEX File is Empty';
      if LogCommon <> nil then
      LogCommon.mlog(m_nCh, sErrMsg);
      //TBD? OnErrMsg(m_nCh, sErrMsg);
      Exit(False);
    end;

    // Download HEX File ---------------------
    try
      nDirIdx        := LastDelimiter('\', sHexServerFullName);
      sHexServerPath := Copy(sHexServerFullName, 1, nDirIdx-1);
      sHexFileName   := Copy(sHexServerFullName, nDirIdx+1, Length(sHexServerFullName)-1);
      //
      m_DfsRetInfo.HexFileName := Common.Path.DfsHex + FormatDateTime('MM', now) + '\'; //2019-06-24
      Common.CheckDir(m_DfsRetInfo.HexFileName);
      m_DfsRetInfo.HexFileName := m_DfsRetInfo.HexFileName + FormatDateTime('DD', now) + '\'; //2019-06-24
      Common.CheckDir(m_DfsRetInfo.HexFileName);
      m_DfsRetInfo.HexFileName := m_DfsRetInfo.HexFileName + Common.CombiCodeData.sRcpName + '\';
      Common.CheckDir(m_DfsRetInfo.HexFileName);
      m_DfsRetInfo.HexFileName := m_DfsRetInfo.HexFileName + Common.SystemInfo.EQPId + '\';
      Common.CheckDir(m_DfsRetInfo.HexFileName);
      m_DfsRetInfo.HexFileName := m_DfsRetInfo.HexFileName + sHexFileName;
      if FileExists(m_DfsRetInfo.HexFileName) then begin
        DeleteFile(m_DfsRetInfo.HexFileName);
      end;
      //
      sList2 := TStringList.Create;
      ExtractStrings(['\'],[],PWideChar(sHexServerPath),sList2);
      for i := 0 to Pred(sList2.Count) do begin
        DfsFtpCh[m_nCh].ChangeDir(sList2[i]); //Common.Delay(50);
      end;
      if LogCommon <> nil then
      LogCommon.mlog(m_nCh, '<DFS> HEX File Downloading (' + sHexServerFullName + ')');
      DfsFtpCh[m_nCh].Get(sHexFileName, m_DfsRetInfo.HexFileName); //Common.Delay(50);
      DfsFtpCh[m_nCh].DisConnect; //Common.Delay(50);
    except
      on E: Exception do begin
        DfsFtpCh[m_nCh].DisConnect; //Common.Delay(50);
        sErrMsg := '<DFS> HEX File Download Fail (FTP Error: ' + E.Message + ')';
        if LogCommon <> nil then LogCommon.mlog(m_nCh, sErrMsg); //TBD? OnErrMsg(m_nCh, sErrMsg);
        Exit(False);
      end;
    end;
    if LogCommon <> nil then LogCommon.MLog(m_nCh, '<DFS> HEX File DOwnload OK');
    Result := True;
  finally
    //------------------------------------ Disconnect DFS FTP server if connected

    if DfsFtpCh[m_nCh].IsConnected then begin  //2019-04-09
      DfsFtpCh[m_nCh].Disconnect;
    end;
    sList.Free;
    sList2.Free;
  end;
end;

function TDfsFtp.DfsHexFilesUpload(sPid: string; sStartTime: TDateTime; sBinFullName: String) : Integer;
var
  sHexIdxFileName, sHexIdxLocalFullName, sDfsHashPath, sHexIdxServerPath, sHexIdxServerFullName : String;
  sHexFileName, sHexLocalFullName, sHexServerPath, sHexServerFullName : String;
  {sRootDir,} sTempDir, sTempDir2, sTempDir3, sTempDir4, sErrMsg : String;
  sList, sList2 : TStringList; //2019-04-09
  i : Integer;
  bIsOK, bHexIdxExistOnServer : Boolean;
begin
  sErrMsg  := '';
  //sRootDir := '\';
  // Check PanelId
  if sPid = '' then begin
    sErrMsg := '<DFS> HEX_INDEX File Upload Fail (Panel ID is NOT exist) !';
    if LogCommon <> nil then LogCommon.MLog(m_nCh, sErrMsg);  //OnErrMsg(m_nCh, sErrMsg);
    Exit(1);
  end;

  //------------------------------------ for HEX_INDEX file
  // Make HexIndex filename and LocalPath
  sHexIdxFileName      := UpperCase(sPid) + '.IDX';
  Common.CheckDir(Common.Path.DfsHexIndex);
  sHexIdxLocalFullName := Common.Path.DfsHexIndex + sHexIdxFileName;
  if FileExists(sHexIdxLocalFullName) then begin
    DeleteFile(sHexIdxLocalFullName);
  end;
  // Get DfsHashPath and Make HexIndex ServerPath
  sDfsHashPath         := GetDfsHashPath(sPid);
  sHexIdxServerPath    := 'DEFECT\HEX_INDEX\' + sDfsHashPath;
  sHexIdxServerFullName:= sHexIdxServerPath + '\' + sHexIdxFileName;

  //------------------------------------ for HEX file
  // Make Hex filename
  sHexFileName := sPid + '_' + Common.CombiCodeData.sProcessNo + '_'
                   + FormatDateTime('YYYYMMDD_HHNNSS', sStartTime);
  if Common.DfsConfInfo.bDfsHexCompress then
    sHexFileName := sHexFileName + '.ZIP'
  else
    sHexFileName := sHexFileName + '.' + Common.SystemInfo.EQPId;
  // Make Hex LocalFullName and Check
  sHexLocalFullName := Common.Path.DfsHex;
  Common.CheckDir(sHexLocalFullName);
  sHexLocalFullName := sHexLocalFullName + FormatDateTime('MM',sStartTime) + '\';
  Common.CheckDir(sHexLocalFullName);
  sHexLocalFullName := sHexLocalFullName + FormatDateTime('DD',sStartTime) + '\';
  Common.CheckDir(sHexLocalFullName);
  sHexLocalFullName := sHexLocalFullName + Format('%s\',[Common.CombiCodeData.sRcpName]);
  Common.CheckDir(sHexLocalFullName);
  sHexLocalFullName := sHexLocalFullName + Format('%s\',[Common.SystemInfo.EQPId]);
  Common.CheckDir(sHexLocalFullName);
  sHexLocalFullName := sHexLocalFullName + sHexFileName;
  bIsOK := False; //2019-02-13
  if System.SysUtils.FileExists(sBinFullName) then begin
    bIsOK := CopyFile(PChar(sBinFullName), PChar(sHexLocalFullName), False);
  end;
  if not FileExists(sHexLocalFullName) then begin
    sErrMsg := '<DFS> HEX File Upload Fail (HEX file is NOT exist) !';
    if LogCommon <> nil then LogCommon.MLog(m_nCh, sErrMsg);
  //TBD? OnErrMsg(m_nCh, sErrMsg);
    Exit(2);
  end;
  // Make Hex ServerFullName
  sHexServerFullName := 'DEFECT\HEX\'
                   + FormatDateTime('MM', sStartTime) + '\'
                   + FormatDateTime('DD', sStartTime) + '\'
                   + Format('%s\%s\',[Common.CombiCodeData.sRcpName, Common.SystemInfo.EQPId])
                   + sHexFileName;

  //------------------------------------ Connect DFS FTP server if not connected
  if not DfsFtpCh[m_nCh].IsConnected then begin
    DfsFtpCh[m_nCh].Connect;
    Common.Delay(1000);
  end;
  if not DfsFtpCh[m_nCh].IsConnected then begin
  //DfsFtpCh[m_nCh].DisConnect;
    sErrMsg := '<DFS> HEX_INDEX and HEX File Upload Fail (DFS Server Not Connected)';
    if LogCommon <> nil then LogCommon.MLog(m_nCh, sErrMsg);
    //TBD? OnErrMsg(m_nCh, sErrMsg);
    Exit(3);
  end;
{$IFDEF DFS_FTP_HEX_INDEX_DOWN_TO_TUPLOAD}
  //---------------------------------- Download HEX_INDEX File  //2019-04-09 //TBD:DFS:FTP:UPLOAD_HEX_INDEX?
  try
    Common.MLog(m_nCh, '<DFS> HEX_INDEX File Downloading (' + sHexIdxServerFullName + ')');
  //sRootDir := '\';
  //Common.MLog(m_nCh, '<DFS> FTP Directory Change to download HEX_INDEX file [DEFECT]');
    DfsFtpCh[m_nCh].ChangeDir('DEFECT');  //Common.Delay(50);
{$IFNDEF XXXXX}
  //Common.MLog(m_nCh, '<DFS> FTP Directory Change to download HEX_INDEX file [HEX_INDEX]');
    DfsFtpCh[m_nCh].ChangeDir('HEX_INDEX'); //Common.Delay(50);
    sList := TStringList.Create;
    ExtractStrings(['\'],[],PWideChar(sDfsHashPath),sList);
    for i := 0 to Pred(sList.Count) do begin
    //Common.MLog(m_nCh,'<DFS> FTP Directory Change to Download[' + sList[i] + ']');
      DfsFtpCh[m_nCh].ChangeDir(sList[i]);  //Common.Delay(50);
    end;
    DfsFtpCh[m_nCh].Get(sHexIdxFileName, sHexIdxLocalFullName); //Common.Delay(50);
{$ELSE}
    bHexIdxExistOnServer := True;
    DfsFtpCh[m_nCh].ChangeDir('HEX_INDEX'); //Common.Delay(50);
    sList := TStringList.Create;
    ExtractStrings(['\'],[],PWideChar(sDfsHashPath),sList);
    for i := 0 to Pred(sList.Count) do begin
      try
      //DfsFtpCh[m_nCh].ftp.List(nil, sList[i], False);
        DfsFtpCh[m_nCh].ChangeDir(sList[i]);
        if DfsFtpCh[m_nCh].ftp.LastCmdResult.NumericCode = 450 then begin
        //if (DfsFtpCh[m_nCh].ftp.LastCmdResult.Text.Text has a message like 'No such file or directory' or similar) then begin
          if ContainsText(DfsFtpCh[m_nCh].ftp.LastCmdResult.Text.Text,'No such file or directory') then begin
            bHexIdxExistOnServer := False;
          end;
        end;
      except
      //on E: EIdReplyRFCError do begin
      //  if (e.ErrorCode <> 550) or (ContainsText(e.Message,'Directory not found') then begin
      //    raise;
      //  end;
          bHexIdxExistOnServer := False;
          Break;
      //end;
      end;
    end;
    if bHexIdxExistOnServer then begin
      DfsFtpCh[m_nCh].ftp.List(nil, sHexIdxFileName, True);
      if DfsFtpCh[m_nCh].ftp.LastCmdResult.NumericCode = 450 then begin
      //if (DfsFtpCh[m_nCh].ftp.LastCmdResult.Text.Text has a message like 'No such file or directory' or similar) then begin
        if ContainsText(DfsFtpCh[m_nCh].ftp.LastCmdResult.Text.Text,'No such file or directory') then begin
          bHexIdxExistOnServer := False;
        end;
      end;
      if bHexIdxExistOnServer then begin
        DfsFtpCh[m_nCh].Get(sHexIdxFileName, sHexIdxLocalFullName); //Common.Delay(50);
      end;
    end
    else begin
      Common.MLog(m_nCh, '<DFS> PANEL INDEX FILE IS NOT EXIST. CREATE NEW HEX_INDEX FILE.');
    end;
{$ENDIF}
  except
    on E: Exception do begin
      Common.MLog(m_nCh, '<DFS> PANEL INDEX FILE IS NOT EXIST. CREATE NEW HEX_INDEX FILE.');
      DfsFtpCh[m_nCh].Disconnect;
      Common.Delay(2000);
      if not DfsFtpCh[m_nCh].IsConnected then begin
        DfsFtpCh[m_nCh].Connect;
        Common.Delay(1000);
      end;
    end;
  end;
  Common.MLog(m_nCh, '<DFS> HEX_INDEX File Download or Check OK ');
{$ENDIF}  //DFS_FTP_HEX_INDEX_DOWN_TO_TUPLOAD

  //------------------------------------ Update HexIndex file to upload //2019-04-09
  UpdateDfsIdxFile(sHexIdxLocalFullName, sHexServerFullName);

  //------------------------------------ Upload HexIndex File
  try
    //Common.MLog(m_nCh, '<DFS> FTP Directory Change [/DEFECT/HEX_INDEX]');
    DfsFtpCh[m_nCh].ChangeDir('DEFECT');    //Common.Delay(50);
    DfsFtpCh[m_nCh].ChangeDir('HEX_INDEX'); //Common.Delay(50);
    sTempDir  := Copy(sDfsHashPath, 1, 8);
    MakeAndChangeDir(sTempDir);
    sTempDir2 := Copy(sDfsHashPath, 10, 8);
    MakeAndChangeDir(sTempDir2);
    if LogCommon <> nil then LogCommon.MLog(m_nCh, '<DFS> HEX_INDEX File Uploading (' + sHexIdxServerFullName + ')');
    DfsFtpCh[m_nCh].Put(sHexIdxLocalFullName, sHexIdxFileName); //Common.Delay(50);
    for i := 0 to 3 do begin
      DfsFtpCh[m_nCh].ChangeDirUp; //Common.Delay(50);
    end;
  except
    on E: Exception do begin
      DfsFtpCh[m_nCh].DisConnect; //Common.Delay(50);
      sErrMsg := '<DFS> HEX_INDEX File Upload Fail (FTP Error: ' + E.Message + ')';
      if LogCommon <> nil then LogCommon.MLog(m_nCh, sErrMsg);
      //TBD? OnErrMsg(m_nCh, sErrMsg);
      Exit(4);
    end;
  end;
  if LogCommon <> nil then LogCommon.MLog(m_nCh, '<DFS> HEX_INDEX File Upload OK ');

  //------------------------------------ Upload HEX file
  try
    //Common.MLog(m_nCh, '<DFS> FTP Directory Change [/DEFECT/HEX]');
    DfsFtpCh[m_nCh].ChangeDir('DEFECT'); //Common.Delay(50);
    DfsFtpCh[m_nCh].ChangeDir('HEX'); //Common.Delay(50);
    sTempDir  := FormatDateTime('MM', sStartTime);
    MakeAndChangeDir(sTempDir);
    sTempDir2  := FormatDateTime('DD', sStartTime);
    MakeAndChangeDir(sTempDir2);
    sTempDir3  := Common.CombiCodeData.sRcpName;
    MakeAndChangeDir(sTempDir3);
    sTempDir4  := Common.SystemInfo.EQPId;
    MakeAndChangeDir(sTempDir4);
    if LogCommon <> nil then LogCommon.MLog(m_nCh, '<DFS> HEX File Uploading (' + sHexServerFullName + ')');
    DfsFtpCh[m_nCh].Put(sHexLocalFullName, sHexFileName); //Common.Delay(50);
    DfsFtpCh[m_nCh].DisConnect;
  except
    on E: Exception do begin
      DfsFtpCh[m_nCh].DisConnect; //Common.Delay(50);
      sErrMsg := '<DFS> HEX File Upload Fail (FTP Error: ' + E.Message + ')';
      if LogCommon <> nil then LogCommon.MLog(m_nCh, sErrMsg);
      //TBD? OnErrMsg(m_nCh, sErrMsg);
      Exit(5);
    end;
  end;
  if LogCommon <> nil then LogCommon.MLog(m_nCh, '<DFS> HEX File Upload OK');
  Result := 0;

  //------------------------------------ Disconnect DFS FTP Connection if connected
  if DfsFtpCh[m_nCh].IsConnected then begin  //2019-04-09
    DfsFtpCh[m_nCh].Disconnect;
  end;

  //------------------------------------ Delete HEX_INDEX/HEX file uploaded
  DeleteFile(sHexIdxLocalFullName);
  DeleteFile(sHexLocalFullName);
end;
{$ENDIF}


//******************************************************************************
// procedure/function: DfsFtp-to-FrmMain
//
//******************************************************************************

procedure TDfsFtp.SendMainGuiDisplay(nGuiMode, nCh: Integer; nParam: Integer; sMsg: string = ''); //2019-04-09
var
  ccd : TCopyDataStruct;
  MainGuiDfsData : RMainGuiDfsData;
begin
  //Common.MLog(nCh,'<DFS> SendMainGuiDisplay: Mode('+IntToStr(nGuiMode)+') Ch('+IntToStr(nCh+1)+') Param('+IntToStr(nParam)+')',DefPocb.DEBUG_LEVEL_INFO);
  MainGuiDfsData.MsgType := DefCommon.MSG_TYPE_DFS;
  MainGuiDfsData.Channel := nCh;
  MainGuiDfsData.Mode    := nGuiMode; //
  MainGuiDfsData.Param   := nParam;   // 0:Disconnected, 1:Connected
  MainGuiDfsData.Msg     := sMsg;     //
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(MainGuiDfsData);
  ccd.lpData      := @MainGuiDfsData;
  SendMessage(m_hMain,WM_COPYDATA,0,LongInt(@ccd));  //TBD:A2CH? (nCH->nJig)
end;

//==============================================================================
// DFS_DEFECT : DEFECT/INDEX, DEFECT/INSPECTOR and more?
//==============================================================================

end.
