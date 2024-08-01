unit SystemSetup;

interface
{$I Common.inc}
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, RzEdit, RzPanel, Vcl.ExtCtrls,
  RzTabs, RzRadChk, RzButton, RzCmboBx, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, IniFiles, CommonClass, DefCommon,
  {FileTrans,} PwdChange, RzLstBox, RzShellDialogs, System.UITypes, LogIn, DfsFtp,
  Vcl.Buttons, Vcl.ComCtrls, Vcl.ToolWin, System.ImageList, Vcl.ImgList, AdvUtil, RTTI,
  RzRadGrp,ShellApi
{$IFDEF  CA310_USE}
  , Ca310
{$ENDIF}
{$IFDEF CA410_USE}
,CA_SDK2
{$ENDIF}
  ;

const
  CA410_DISPLAY_ITEM = 'USB ID COMM(%d), SerialNo (%s)';


type
  TfrmSystemSetup = class(TForm)
    pcSysConfig: TRzPageControl;
    TabSheet1: TRzTabSheet;
    grpSystem: TRzGroupBox;
    pnlUIType: TRzPanel;
    pnlLanguage: TRzPanel;
    cboUIType: TRzComboBox;
    cboLanguage: TRzComboBox;
    btnSave: TRzBitBtn;
    btnClose: TRzBitBtn;
    grpSerialSetting: TRzGroupBox;
    pnlBCR: TRzPanel;
    grpIPSetting: TRzGroupBox;
    pnl8: TPanel;
    cboRCB1: TRzComboBox;
    pnlBCR2: TRzPanel;
    cboBCR: TRzComboBox;
    grpCh: TRzGroupBox;
    chkCh1: TRzCheckBox;
    chkCh2: TRzCheckBox;
    chkCh3: TRzCheckBox;
    chkCh4: TRzCheckBox;
    RzBitBtn1: TRzBitBtn;
    chkAutoBackup: TRzCheckBox;
    btnAutoBackup: TRzBitBtn;
    dlgOpen: TRzSelectFolderDialog;
    edAutoBackup: TRzEdit;
    tbEcsSheet: TRzTabSheet;
    grpPlcConfig: TRzGroupBox;
    RzPanel5: TRzPanel;
    RzPanel7: TRzPanel;
    edtStartAddress_ECS: TRzEdit;
    RzPanel9: TRzPanel;
    edtStartAddress_ECS_W: TRzEdit;
    dlgOpenGmes: TRzOpenDialog;
    btnLoadPlcAddress: TRzBitBtn;
    edPlcConfigPath: TRzEdit;
    pnlCamLight: TRzPanel;
    cboCamLight: TRzComboBox;
    tbDfsConfigration: TRzTabSheet;
    il1: TImageList;
    RzgrpDfsFtpFileUpload: TRzGroupBox;
    RzgrpDfsFtpHost: TRzGroupBox;
    RzpnlDfsFtpHostCtrl: TRzPanel;
    tlbDfsFtpHostBtns: TToolBar;
    btnDfsFtpHostDirUp: TToolButton;
    btnDfsFtpHostDirBack: TToolButton;
    btnDfsFtpHostDirHome: TToolButton;
    btnDfsFtpHostNull1: TToolButton;
    btnDfsFtpHostFileDownload: TToolButton;
    btnDfsFtpHostNull2: TToolButton;
    btnDfsFtpHostDirCreate: TToolButton;
    btnDfsFtpHostFileDelete: TToolButton;
    edDfsFtpHostDirNow: TEdit;
    btnDfsFtpHostDirGo: TBitBtn;
    lstDfsFtpHostFiles: TListBox;
    RzgrepDfsFtpLocal: TRzGroupBox;
    RzpnlDfsFtpLocalCtrl: TRzPanel;
    tlbDfsFtpLocalBtns: TToolBar;
    btnDfsFtpLocalDirUp: TToolButton;
    btnDfsFtpLocalDirBack: TToolButton;
    btnDfsFtpLocalDirHome: TToolButton;
    btnDfsFtpLocalNull1: TToolButton;
    btnDfsFtpLocalFileUpload: TToolButton;
    btnDfsFtpLocalNull2: TToolButton;
    btnDfsFtpLocalDirCreate: TToolButton;
    btnDfsFtpLocalFileDelete: TToolButton;
    edDfsFtpLocalDirNow: TEdit;
    btnDfsFtpLocalDirGo: TBitBtn;
    lstDfsFtpLocalFiles: TListBox;
    btnDfsFtpHost2LocalDownload: TRzBitBtn;
    btnDfsFtpLocal2HostUpload: TRzBitBtn;
    RzgrpDfsFtpConfig: TRzGroupBox;
    pnlDfsServerIP: TRzPanel;
    pnlDfsUserName: TRzPanel;
    pnlDfsPW: TRzPanel;
    edDfsServerIP: TRzEdit;
    edDfsUserName: TRzEdit;
    edDfsPW: TRzEdit;
    cbDfsFtpUse: TRzCheckBox;
    btnLoadDfsConfig: TBitBtn;
    cbUseCombiDown: TRzCheckBox;
    RzpnlCombiPath: TRzPanel;
    edCombiDownPath: TRzEdit;
    cbDfsHexCompress: TRzCheckBox;
    cbDfsHexDelete: TRzCheckBox;
    RzPanel18: TRzPanel;
    edProcessName: TRzEdit;
    pnlDfsFtpStatus: TPanel;
    btnDfsFtpDisconnect: TRzBitBtn;
    btnDfsFtpConnect: TRzBitBtn;
    grpGMES: TRzGroupBox;
    pnlServicePort: TRzPanel;
    pnlNetwork: TRzPanel;
    pnlDeamonPort: TRzPanel;
    edServicePort: TRzEdit;
    edNetwork: TRzEdit;
    edDeamonPort: TRzEdit;
    pnlLocalSubject: TRzPanel;
    pnlRemoteSubject: TRzPanel;
    edLocalSubject: TRzEdit;
    edRemoteSubject: TRzEdit;
    pnlEqccInterval: TRzPanel;
    edEqccInterval: TRzEdit;
    pnlMs: TRzPanel;
    RzBitBtn3: TRzBitBtn;
    btnPocbEmNo: TRzBitBtn;
    RzGroupBox1: TRzGroupBox;
    RzPanel1: TRzPanel;
    RzPanel4: TRzPanel;
    RzPanel14: TRzPanel;
    edEasServicePort: TRzEdit;
    edEasNetwork: TRzEdit;
    edEasDeamonPort: TRzEdit;
    RzPanel16: TRzPanel;
    edEasRemoteSubject: TRzEdit;
    chkEQCC: TRzCheckBox;
    pnlTitleIonizer: TRzPanel;
    pnlModelonizer: TRzPanel;
    cboIonizer: TRzComboBox;
    cboIonizerModel: TRzComboBox;
    RzGroupBox2: TRzGroupBox;
    RzPanel24: TRzPanel;
    RzNumericEdit3: TRzNumericEdit;
    RzPanel26: TRzPanel;
    RzPanel3: TRzPanel;
    RzPanel6: TRzPanel;
    RzPanel8: TRzPanel;
    edtStartAddress_EQP: TRzEdit;
    edtStartAddress_EQP_W: TRzEdit;
    RzPanel10: TRzPanel;
    RzPanel11: TRzPanel;
    RzPanel17: TRzPanel;
    edtStartAddress_Robot: TRzEdit;
    edtStartAddress_Robot_W: TRzEdit;
    RzPanel22: TRzPanel;
    edtECS_EQPID: TRzEdit;
    RzPanel23: TRzPanel;
    edtECS_PollingInterval: TRzEdit;
    RzPanel25: TRzPanel;
    edtECS_Timeout_Connection: TRzEdit;
    RzPanel27: TRzPanel;
    edtECS_Timeout_ECS: TRzEdit;
    RzGroupBox4: TRzGroupBox;
    chkInterlock_SW: TRzCheckBox;
    edtVrsion_DLL: TRzEdit;
    RzPanel28: TRzPanel;
    RzPanel29: TRzPanel;
    edtVrsion_Script: TRzEdit;
    RzPanel30: TRzPanel;
    edtVrsion_FW: TRzEdit;
    RzPanel31: TRzPanel;
    edtVrsion_SW: TRzEdit;
    RzPanel32: TRzPanel;
    edtVrsion_LGDDLL: TRzEdit;
    RzGroupBox3: TRzGroupBox;
    rgSelectReport: TRzRadioGroup;
    RzPanel12: TRzPanel;
    edtLoginID: TRzEdit;
    RzPanel13: TRzPanel;
    RzPanel15: TRzPanel;
    cboNGAlarmCount: TComboBox;
    RzGroupBox5: TRzGroupBox;
    RzPanel21: TRzPanel;
    edEQPID_MGIB: TRzEdit;
    RzPanel33: TRzPanel;
    edEQPID_PGIB: TRzEdit;
    pnlEQPID: TRzPanel;
    edEQPID_INLINE: TRzEdit;
    cboEQPId_Type: TComboBox;
    RzPanel20: TRzPanel;
    RzPanel35: TRzPanel;
    edEasLocalSubject: TRzEdit;
    chkInlineGIB: TCheckBox;
    RzPanel37: TRzPanel;
    edtMesModelInfo: TRzEdit;
    TabSheet2: TRzTabSheet;
    grpCa310Set: TRzGroupBox;
    pnl1: TPanel;
    cboCa310_2: TRzComboBox;
    cboCa310_1: TRzComboBox;
    RzPanel38: TRzPanel;
    RzPanel39: TRzPanel;
    RzBitBtn4: TRzBitBtn;
    pnlProbeTitle1: TRzPanel;
    pnlProbeTitle2: TRzPanel;
    RzPanel40: TRzPanel;
    cboCa310_3: TRzComboBox;
    pnlProbeTitle3: TRzPanel;
    RzPanel42: TRzPanel;
    cboCa310_4: TRzComboBox;
    pnlProbeTitle4: TRzPanel;
    cboIonizer2: TRzComboBox;
    RzPanel34: TRzPanel;
    pnlOCType: TRzPanel;
    cboOCType: TRzComboBox;
    cboRCB2: TRzComboBox;
    cboBCR2: TRzComboBox;
    RzGrpOptions: TRzGroupBox;
    chkITOBmpMode: TRzCheckBox;
    grpDebugLogLevel: TRzGroupBox;
    pnlDebugLogPG: TRzPanel;
    cboDebugLogPG: TRzComboBox;
    btnPgFwDownload: TRzBitBtn;
    btnFileOpen: TRzBitBtn;
    edFileName: TRzEdit;
    odglfile: TRzOpenDialog;
    RzGroupBox6: TRzGroupBox;
    RzPanel2: TRzPanel;
    edSaveEnergy: TRzEdit;
    RzGroupBox7: TRzGroupBox;
    RzPanel36: TRzPanel;
    RzPanel41: TRzPanel;
    RzPanel43: TRzPanel;
    edR2RServicePort: TRzEdit;
    edR2RNetwork: TRzEdit;
    edR2RDeamonPort: TRzEdit;
    RzPanel44: TRzPanel;
    edR2RRemoteSubject: TRzEdit;
    RzPanel45: TRzPanel;
    edR2RLocalSubject: TRzEdit;
    edtStartAddress_Robot2: TRzEdit;
    edtStartAddress_Robot_W2: TRzEdit;
    ChkCHReversal: TCheckBox;
    pnl2: TRzPanel;
    edtStartAddress_Robot_B_DoorOpen: TRzEdit;
    RzPanel46: TRzPanel;
    RzPanel47: TRzPanel;
    edPRCS_CD_MGIB: TRzEdit;
    edPRCS_CD_PGIB: TRzEdit;
    RzPanel48: TRzPanel;
    cboIrTempSensor: TRzComboBox;
    RzPanel49: TRzPanel;
    Label2: TLabel;
    edSetTemperature: TRzNumericEdit;
    RzGroupBox9: TRzGroupBox;
    chkVerInterlock: TRzCheckBox;
    edMESCodeCnt: TRzEdit;
    RzPanel50: TRzPanel;
    edPopupMsgTime: TRzEdit;
    RzPanel19: TRzPanel;
    edPGResetDelayTime: TRzEdit;
    RzPanel51: TRzPanel;
    edPGResetTotalConut: TRzEdit;
    chkAutoLGDLogBackup: TRzCheckBox;
    chkInLineAAMode: TRzCheckBox;
    chkOnlyRestartMode: TRzCheckBox;
    RzPanel52: TRzPanel;
    cboDisplayDllCnt: TRzComboBox;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure RzBitBtn1Click(Sender: TObject);
    procedure btnAutoBackupClick(Sender: TObject);
    procedure chkAutoBackupClick(Sender: TObject);
    procedure FindItemToListbox(tList: TRzListbox; sItem: string);
    procedure RzBitBtn3Click(Sender: TObject);
    procedure btnLoadPlcAddressClick(Sender: TObject);
    procedure RzBitBtn4Click(Sender: TObject);
    procedure btnGetEmNoGIBClick(Sender: TObject);
    procedure btnLoadDfsConfigClick(Sender: TObject);
    procedure btnDfsFtpConnectClick(Sender: TObject);
    procedure btnDfsFtpDisconnectClick(Sender: TObject);
    procedure btnDfsFtpHostDirUpClick(Sender: TObject);
    procedure btnDfsFtpLocalDirCreateClick(Sender: TObject);
    procedure btnDfsFtpHostDirBackClick(Sender: TObject);
    procedure btnDfsFtpHostDirHomeClick(Sender: TObject);
    procedure btnDfsFtpHostFileDownloadClick(Sender: TObject);
    procedure btnDfsFtpHostDirCreateClick(Sender: TObject);
    procedure btnDfsFtpLocalDirUpClick(Sender: TObject);
    procedure btnDfsFtpLocalDirBackClick(Sender: TObject);
    procedure btnDfsFtpLocalDirHomeClick(Sender: TObject);
    procedure btnDfsFtpLocalFileUploadClick(Sender: TObject);
    procedure btnDfsFtpHostDirGoClick(Sender: TObject);
    procedure btnDfsFtpHostFileDeleteClick(Sender: TObject);
    procedure btnDfsFtpLocalDirGoClick(Sender: TObject);
    procedure lstDfsFtpHostFilesDblClick(Sender: TObject);
    procedure lstDfsFtpLocalFilesDblClick(Sender: TObject);
    procedure cboCa310_1Click(Sender: TObject);
    procedure cboCa310_2Click(Sender: TObject);
    procedure cboCa310_3Click(Sender: TObject);
    procedure cboCa310_4Click(Sender: TObject);
    procedure btnPgFwDownloadClick(Sender: TObject);
    procedure btnFileOpenClick(Sender: TObject);
  private
    edProbeSerial : array[DefCommon.CH1 .. DefCommon.MAX_CH] of TRzEdit;
    edProbeDevice : array[DefCommon.CH1 .. DefCommon.MAX_CH] of TRzEdit;
//    cboIonizer    : array[0 .. pred(DefCommon.MAX_IONIZER_CNT)] of TRzComboBox;
//    cboIonizerModel : array[0 .. pred(DefCommon.MAX_IONIZER_CNT)] of TRzComboBox;

    // For DFS.
    FHostLastDirStack   : TStringList;
    FHostRootDir        : String;
    FLocalLastDirStack  : TStringList;
    FLocalRootDir       : String;

    procedure DisplaySystemInfo;
    procedure SaveBCRPortInfo;
    procedure ReadBCRPortInfo;
    function CheckAdminPasswd : Boolean;
    function CheckChangedSysInfo(pData1, pData2: PSystemInfo) : Boolean;
    function CheckChangedPLCInfo(pData1, pData2: PPLCInfo) : Boolean;
    function CheckChangedDFSInfo(pData1, pData2: PDfsConfInfo) : Boolean;
    function GetSerialNum(nIdx : Integer; sInput: string): string;
  public
    { Public declarations }
    procedure DisplayFTP;
    procedure DisplayLocal;
    procedure FtpConnection(bConn : Boolean);
    procedure ChangeFTPDir(NewDir : String);
    procedure ChangeLocalDir(NewDir: string);
  end;

var
  frmSystemSetup: TfrmSystemSetup;

implementation

{$R *.dfm}

procedure TfrmSystemSetup.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSystemSetup.btnDfsFtpConnectClick(Sender: TObject);
var
  sServerIP, sUserName, sPassword : string;
begin
  // DFS Server
  sServerIP := edDfsServerIP.Text;
  sUserName := edDfsUserName.Text;
  sPassword := edDfsPW.Text;
  if (DfsFtpCommon = nil) then begin
    // in case of PM Mode.
    DfsFtpCommon := TDfsFtp.Create(sServerIP, sUserName, sPassword, -1{nCh:dummy for DfsFtpCommon});
    DfsFtpCommon.IsConnectCheck := False;
  end;
  DfsFtpCommon.OnConnectedSetup := FtpConnection;
  DfsFtpCommon.IsSetUpWindow := True;
  if DfsFtpCommon.IsConnected then DfsFtpCommon.Disconnect;
  DfsFtpCommon.Connect;
  //
  RzgrpDfsFtpFileUpload.Visible := True;
end;

procedure TfrmSystemSetup.btnDfsFtpDisconnectClick(Sender: TObject);
begin
  if DfsFtpCommon <> nil then begin
    DfsFtpCommon.Disconnect;
  end;
  RzgrpDfsFtpFileUpload.Visible := False;
end;

procedure TfrmSystemSetup.btnDfsFtpHostDirBackClick(Sender: TObject);
var
  sTemp : String;
begin
  if FHostLastDirStack.Count > 0 then begin
    sTemp := FHostLastDirStack[FHostLastDirStack.Count -1];
    ChangeFTPDir(sTemp);
    // Delete S
    FHostLastDirStack.Delete(FHostLastDirStack.Count -1);
    // Delete the jump from S
    FHostLastDirStack.Delete(FHostLastDirStack.Count -1);
//    SetControls;
  end;
end;

procedure TfrmSystemSetup.btnDfsFtpHostDirCreateClick(Sender: TObject);
var
  sTemp : String;
begin
  sTemp := 'New Folder';
  if InputQuery('New folder', 'New folder name:', sTemp) then begin
    DfsFtpCommon.MakeDir(sTemp);
    ChangeFTPDir(sTemp);
  end;
end;

procedure TfrmSystemSetup.btnDfsFtpHostDirGoClick(Sender: TObject);
begin
  if (Length(edDfsFtpHostDirNow.Text) < 1) then begin  //2019-02-08
    btnDfsFtpHostDirHomeClick(Sender);
    Exit;
  end;
  if (edDfsFtpHostDirNow.Text[Length(edDfsFtpHostDirNow.Text)] <> '/') then
    edDfsFtpHostDirNow.Text := edDfsFtpHostDirNow.Text + '/';
  ChangeFTPDir(edDfsFtpHostDirNow.Text);
end;

procedure TfrmSystemSetup.btnDfsFtpHostDirHomeClick(Sender: TObject);
begin
  ChangeFTPDir(FHostRootDir);
end;

procedure TfrmSystemSetup.btnDfsFtpHostDirUpClick(Sender: TObject);
begin
  DfsFtpCommon.ChangeDirUp;
  DisplayFTP;
end;

procedure TfrmSystemSetup.btnDfsFtpHostFileDeleteClick(Sender: TObject);
var
  i : Integer;
  sTemp : String;
begin
  try
    i := lstDfsFtpHostFiles.ItemIndex;
  except
    ShowMessage('Please Select File.');
    exit;
  end;
  if i <> -1 then begin
    sTemp := lstDfsFtpHostFiles.Items[i];
    if MessageDlg('Are you sure you want to delete ' + sTemp + '?', mtWarning, [mbYes,mbNo], 0) = mrYes then
      DfsFtpCommon.Delete(sTemp);
    DisplayFTP;
  end
  else
    MessageDlg('You must first select a file or folder to delete from the site.', mtWarning, [mbOK], 0);
end;

procedure TfrmSystemSetup.btnDfsFtpHostFileDownloadClick(Sender: TObject);
var
  i, idx, nSize : Integer;
  //b : boolean;
  sTemp : String;
begin
  idx := -1;
  for i := 0 to Pred(lstDfsFtpHostFiles.Count) do begin
    if lstDfsFtpHostFiles.Selected[i] then begin
      idx := i;
      Break;
    end;
  end;

  if idx <> -1 then begin
    sTemp := lstDfsFtpHostFiles.Items[i];
    nSize := DfsFtpCommon.Size(sTemp);
    if nSize = -1 then
      ChangeFTPDir(sTemp)
    else begin
      if FileExists(edDfsFtpLocalDirNow.Text + sTemp) then
        if MessageDlg('File exists overwrite?', mtWarning, [mbYes,mbNo], 0) = mrYes then
          DeleteFile(edDfsFtpLocalDirNow.Text + sTemp);

      DfsFtpCommon.Get(sTemp, edDfsFtpLocalDirNow.Text + sTemp);
      DisplayLocal;
    end;
  end
  else begin
    MessageDlg('You must first select a file to download from the site.', mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmSystemSetup.btnDfsFtpLocalDirBackClick(Sender: TObject);
var
  sTemp : String;
begin
  if FLocalLastDirStack.Count > 0 then begin
    sTemp := FLocalLastDirStack[FLocalLastDirStack.Count -1];
    ChangeLocalDir(sTemp);
    // Delete S
    FLocalLastDirStack.Delete(FLocalLastDirStack.Count -1);
    // Delete the jump from S
    FLocalLastDirStack.Delete(FLocalLastDirStack.Count -1);
//    SetControls;
  end;
end;

procedure TfrmSystemSetup.btnDfsFtpLocalDirCreateClick(Sender: TObject);
var
  sTemp : String;
begin
  sTemp := 'New Folder';
  if InputQuery('New folder', 'New folder name:', sTemp) then begin
    CreateDir(edDfsFtpLocalDirNow.Text + sTemp + '\');
    ChangeLocalDir(edDfsFtpLocalDirNow.Text + sTemp + '\');
  end;
end;

procedure TfrmSystemSetup.btnDfsFtpLocalDirGoClick(Sender: TObject);
begin
  if (Length(edDfsFtpLocalDirNow.Text) < 1) then begin  //2019-02-08
    btnDfsFtpLocalDirHomeClick(Sender);
    Exit;
  end;
  if (edDfsFtpLocalDirNow.Text[Length(edDfsFtpLocalDirNow.Text)] <> '\') then
    edDfsFtpLocalDirNow.Text := edDfsFtpLocalDirNow.Text + '\';
  DisplayLocal;
end;

procedure TfrmSystemSetup.btnDfsFtpLocalDirHomeClick(Sender: TObject);
begin
  ChangeLocalDir(FLocalRootDir);
end;

procedure TfrmSystemSetup.btnDfsFtpLocalDirUpClick(Sender: TObject);
var
  i : Integer;
  slTemp : TStringList;
  sNewPath : string;
begin
  slTemp := TStringList.Create;
  try
    ExtractStrings(['\'],[], PWideChar(edDfsFtpLocalDirNow.Text), slTemp);
    if slTemp.Count > 0 then begin
      sNewPath := '';
      for i := 0 to (slTemp.Count-2) do begin
        sNewPath := sNewPath + slTemp[i] + '\';
      end;
    end;
    edDfsFtpLocalDirNow.Text := sNewPath;
    DisplayLocal;
  finally
    slTemp.Free;
  //slTemp := nil;
  end;
end;

procedure TfrmSystemSetup.btnDfsFtpLocalFileUploadClick(Sender: TObject);
begin
  ChangeLocalDir(FLocalRootDir);
end;

procedure TfrmSystemSetup.btnFileOpenClick(Sender: TObject);
begin
   odglfile.InitialDir := Common.Path.RootSW;
   odglfile.Filter := 'exe files(*.exe)|*.exe';
   odglfile.FilterIndex := 1;
   if odglfile.Execute then
    begin
      edFileName.Text := odglfile.FileName;
    end;
end;

procedure TfrmSystemSetup.btnGetEmNoGIBClick(Sender: TObject);
var
  txFile : TextFile;
  sReadData,  sLocalIp, sTemp : string;
  slTemp : TStringList;
  i : Integer;
begin
  dlgOpenGmes.InitialDir := Common.Path.Ini;
  dlgOpenGmes.Filter := 'Open EM_No Setup File (*.txt)|*.txt';
  dlgOpenGmes.DefaultExt := dlgOpenGmes.Filter;

  if dlgOpenGmes.Execute then begin
    AssignFile(txFile,dlgOpenGmes.FileName);

    try
      sLocalIp := '';
      Reset(txFile);
      while not Eof(txFile) do begin
        Readln(txFile,sReadData);
        slTemp := TStringList.Create;
        try
          ExtractStrings([','], [], PWideChar(sReadData), slTemp);
          // Ex 1,192.168.112.20,EM_NO.
          if slTemp.Count > 1 then begin
            if Trim(slTemp[0]) = 'IP_SEARCH' then begin
              for i := 1 to pred(slTemp.Count) do begin
                sTemp := Trim(common.GetLocalIpList(DefCommon.IP_LOCAL_GMES,Trim(slTemp[i])));
                // finally find IP.
                if sTemp <> '' then begin
                  sLocalIp := sTemp;
                  Break;
                end;
              end;
            end
            else begin
              if slTemp.Count > 2 then begin
                if slTemp[1] = sLocalIp then begin
                  edEQPID_INLINE.Text      := Trim(slTemp[2]);
                  Break;
                end;
              end;
            end;
          end;
        finally
          slTemp.Free;
        end;
      end;
    finally
      CloseFile(txFile);
    end;
  end;
end;

procedure TfrmSystemSetup.btnLoadDfsConfigClick(Sender: TObject);
var
  txFile : TextFile;
  sReadData, sTemp, sTemp2, sSearchIp : string;
begin
  dlgOpenGmes.InitialDir := Common.Path.Ini;
  dlgOpenGmes.Filter := 'Open DFS Setup File (*.txt)|*.txt';
  dlgOpenGmes.DefaultExt := dlgOpenGmes.Filter;
  if dlgOpenGmes.Execute then begin
    AssignFile(txFile,dlgOpenGmes.FileName);
    sSearchIp := '';
    try
      Reset(txFile);
      while not Eof(txFile) do begin
        Readln(txFile,sReadData);
        if Pos('DFS_SERVER_IP=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'DFS_SERVER_IP=','',[rfReplaceAll]) );
          edDfsServerIP.Text := sTemp;
        end
        else if Pos('DFS_USER_NAME=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'DFS_USER_NAME=','',[rfReplaceAll]) );
          edDfsUserName.Text := sTemp;
        end
        else if Pos('DFS_PASSWORD=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'DFS_PASSWORD=','',[rfReplaceAll]) );
          edDfsPW.Text := sTemp;
        end
        else if Pos('COMBI_DOWN_PATH=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'COMBI_DOWN_PATH=','',[rfReplaceAll]) );
          edCombiDownPath.Text := sTemp;
        end
        else if Pos('PROCESS_NAME=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'PROCESS_NAME=','',[rfReplaceAll]) );
          edProcessName.Text := sTemp;
        end;
      end;
    finally
      CloseFile(txFile);
    end;
  end;
end;

procedure TfrmSystemSetup.btnLoadPlcAddressClick(Sender: TObject);
var
  txFile : TextFile;
  sReadData,  sStationNo, sIndex : string;
  saAddress: TArray<String>;
begin
  sIndex:= '';
  sStationNo:= edtECS_EQPID.Text;

  dlgOpenGmes.InitialDir := Common.Path.Ini;
  dlgOpenGmes.Filter := 'Open PLC Info File (*.csv)|*.csv';
  dlgOpenGmes.DefaultExt := dlgOpenGmes.Filter;

  if dlgOpenGmes.Execute then begin
    AssignFile(txFile, dlgOpenGmes.FileName);

    try
      Reset(txFile);
      while not Eof(txFile) do begin
        Readln(txFile,sReadData);
        saAddress:= sReadData.Split([',']);
        if Length(saAddress) < 8 then begin
          //값 개수 모자름
          Continue;
        end;

        if saAddress[1] = sStationNo then begin
          //StationNo 일치
          sIndex:= saAddress[0];
          edtStartAddress_ECS.Text      := saAddress[2];
          edtStartAddress_ECS_W.Text    := saAddress[3];
          edtStartAddress_EQP.Text      := saAddress[4];
          edtStartAddress_EQP_W.Text    := saAddress[5];
          edtStartAddress_Robot.Text    := saAddress[6];
          edtStartAddress_Robot2.Text   := saAddress[7];
          edtStartAddress_Robot_W.Text  := saAddress[8];
          edtStartAddress_Robot_W2.Text := saAddress[9];
          edtStartAddress_Robot_B_DoorOpen.Text := saAddress[10];
          break;
        end; //if saAddress[1] = sStationNo then begin
      end; //while not Eof(txFile) do begin
      if sIndex = '' then begin
        ShowMessage('Can not find StationNo=' + sStationNo);
      end;
    finally
      CloseFile(txFile);
    end;
  end;
end;
//
//procedure TfrmSystemSetup.btnPgFwDownloadClick(Sender: TObject);
//var
//   SEInfo: TShellExecuteInfo;
//   ExitCode: DWORD;
//   ExecuteFile, ParamString, StartInString: string;
//begin
//
//    ExecuteFile := Common.SystemInfo.DAELoadWizardPath; // 실행하려는 프로그램의 경로 및 파일명 지정
//    ParamString := 'C:\autoexec.bat'; // 프로그램 실행시 인자값을 문자열로 지정
//
//   FillChar(SEInfo, SizeOf(SEInfo), 0) ;
//   SEInfo.cbSize := SizeOf(TShellExecuteInfo) ;
//   with SEInfo do begin
//     fMask := SEE_MASK_NOCLOSEPROCESS;
//     Wnd := Application.Handle;
//     lpFile := PChar(ExecuteFile) ;
////     lpParameters := PChar(ParamString) ;
// // lpDirectory := PChar(StartInString) ; // StartInString 문자열에 실행되고자 하는 디렉토리를 지정할 수 있음. 지정하지 않으면 현재 프로그램 실행 디렉토리가 디폴트로 사용됨
//     nShow := SW_SHOWNORMAL; // 프로그램이 실행되는 윈도우 형태를 지정할 수 있습니다. ACTIVE, 최대화, 최소화 등등...
//   end;
//   if ShellExecuteEx(@SEInfo) then begin
//     repeat
//       Application.ProcessMessages;
//       GetExitCodeProcess(SEInfo.hProcess, ExitCode) ;
//     until (ExitCode <> STILL_ACTIVE) or Application.Terminated;
//     ShowMessage('Shutting down a Program.') ;
//   end
//   else ShowMessage('Failed to run program.') ;
//end;

procedure TfrmSystemSetup.btnPgFwDownloadClick(Sender: TObject);
var
  SEInfo: TShellExecuteInfo;
  ExitCode: DWORD;
  ExecuteFile, ParamString, StartInString: string;
begin
  ExecuteFile := Common.SystemInfo.DAELoadWizardPath; // 실행하려는 프로그램의 경로 및 파일명 지정
  ParamString := 'C:\autoexec.bat'; // 프로그램 실행시 인자값을 문자열로 지정
  StartInString := ExtractFilePath(ExecuteFile); // 실행될 디렉토리 설정

  FillChar(SEInfo, SizeOf(SEInfo), 0);
  SEInfo.cbSize := SizeOf(TShellExecuteInfo);
  with SEInfo do
  begin
    fMask := SEE_MASK_NOCLOSEPROCESS;
    Wnd := Application.Handle;
    lpFile := PChar(ExecuteFile);
    lpParameters := PChar(ParamString);
    lpDirectory := PChar(StartInString);
    nShow := SW_SHOWNORMAL;
  end;

  if ShellExecuteEx(@SEInfo) then
  begin
    repeat
      Application.ProcessMessages;
      GetExitCodeProcess(SEInfo.hProcess, ExitCode);
    until (ExitCode <> STILL_ACTIVE) or Application.Terminated;
    ShowMessage('Program has exited.') ;
  end
  else
    ShowMessage('Failed to run program. Error code: ' + IntToStr(GetLastError));
end;



procedure TfrmSystemSetup.btnSaveClick(Sender: TObject);
var
  i,nLine : Integer;
  OldSysInfo: TSystemInfo;
  OldPLCInfo: TPLCInfo;
  OldDFSInfo: TDfsConfInfo;
begin
  OldSysInfo:= Common.SystemInfo;

  with Common.SystemInfo do begin

    DAELoadWizardPath := edFileName.Text;
    UseITOMode := chkITOBmpMode.Checked;
    AutoLGDLogBackup := chkAutoLGDLogBackup.Checked;

    CHReversal := ChkCHReversal.Checked; // 라인 반전으로 1 2 CH 반전 되어 들어오는 경우 처리

    SaveEnergy      := StrToIntDef(edSaveEnergy.Text,0);

    Com_IrTempSensor := cboIrTempSensor.ItemIndex;
    SetTemperature := StrToIntDef(edSetTemperature.Text,0);

    Com_HandBCR[0]   := cboBCR.ItemIndex;
    Com_HandBCR[1]   := cboBCR2.ItemIndex;

    Com_RCB[0]   := cboRCB1.ItemIndex;
    Com_RCB[1]   := cboRCB2.ItemIndex;
    Com_CamLight := cboCamLight.ItemIndex;

    UIType 		    := cboUIType.itemIndex;
    OCType        := cboOCType.ItemIndex;
    ChCountUsed := DefCommon.MAX_PG_CNT;

    EQPId_Type     := cboEQPId_Type.ItemIndex;
    EQPId_INLINE   := edEQPID_INLINE.Text;
    EQPId_MGIB     := edEQPID_MGIB.Text;
    EQPId_PGIB     := edEQPID_PGIB.Text;
    EQPId_MGIB_Process_Code := edPRCS_CD_MGIB.Text;
    EQPId_PGIB_Process_Code := edPRCS_CD_PGIB.Text;

    MES_CODE_Cnt := StrToIntDef(edMESCodeCnt.Text,0);
    DisplayDLLCnt := cboDisplayDllCnt.ItemIndex;

    PopupMsgTime := StrToIntDef(edPopupMsgTime.Text,0);
    PGResetDelayTime := StrToIntDef(edPGResetDelayTime.Text,0);
    PGResetTotalConut := StrToIntDef(edPGResetTotalConut.Text,0);

    OnlyRestartMode := chkOnlyRestartMode.Checked;


    case EQPId_Type of
      0: begin
        if EQPId_INLINE = '' then begin
          Application.MessageBox('EQP ID Can Not Empty', 'Confirm', MB_OK);
          edEQPID_INLINE.SetFocus;
          Exit;
        end;
        EQPId:= EQPId_INLINE;
      end;
      1: begin
        if EQPId_MGIB = '' then begin
          Application.MessageBox('EQP ID Can Not Empty', 'Confirm', MB_OK);
          edEQPID_MGIB.SetFocus;
          Exit;
        end;
        EQPId:= EQPId_MGIB;
      end;
      2: begin
        if EQPId_PGIB = '' then begin
          Application.MessageBox('EQP ID Can Not Empty', 'Confirm', MB_OK);
          edEQPID_PGIB.SetFocus;
          Exit;
        end;
        EQPId:= EQPId_PGIB;
      end;
      else begin
        Application.MessageBox('Unkonwn EQP ID Type', 'Confirm', MB_OK);
        Exit;
      end;
    end;
    ServicePort    := edServicePort.Text;
    Network        := edNetwork.Text;
    DaemonPort     := edDeamonPort.Text;
    LocalSubject   := edLocalSubject.Text;
    RemoteSubject  := edRemoteSubject.Text;
    EqccInterval   := edEqccInterval.Text;
    Eas_Service    := edEasServicePort.Text;
    Eas_Network     := edEasNetwork.Text;
    Eas_DeamonPort  := edEasDeamonPort.Text;
    Eas_LocalSubject := edEasLocalSubject.Text;
    Eas_RemoteSubject := edEasRemoteSubject.Text;

    R2R_Service    := edR2RServicePort.Text;
    R2R_Network     := edR2RNetwork.Text;
    R2R_DeamonPort  := edR2RDeamonPort.Text;
    R2R_LocalSubject := edR2RLocalSubject.Text;
    R2R_RemoteSubject := edR2RRemoteSubject.Text;
    MesModelInfo      := edtMesModelInfo.Text;
    //FwVer           := Trim(edFwVer.Text);
    //FpgaVer           := Trim(edFpgaVer.Text);

    UseCh[0]      := chkCh1.Checked;
    UseCh[1]      := chkCh2.Checked;
    UseCh[2]      := chkCh3.Checked;
    UseCh[3]      := chkCh4.Checked;

    AutoBackupUse := chkAutoBackup.Checked;
    AutoBackupList := edAutoBackup.Text;

    UseEQCC       := chkEQCC.Checked;
//    MIPILog       := chkMIPILog.Checked;
    NGAlarmCount  := cboNGAlarmCount.ItemIndex;
//    RetryCount    := cboRetryCount.ItemIndex;
//    ECS_Timeout   := StrToIntDef(edtECS_Timeout.Text, 10000);

    Use_MES       := rgSelectReport.ItemIndex = 1;
    Use_ECS       := rgSelectReport.ItemIndex = 0;
    Use_GIB       := EQPId_Type <> 0;

    AutoLoginID   := edtLoginID.Text;

    UseInLine_AAMode := chkInLineAAMode.Checked;

    Com_Ionizer[0] := cboIonizer.ItemIndex;
    Model_Ionizer[0] := cboIonizerModel.ItemIndex;
    Com_Ionizer[1] := cboIonizer2.ItemIndex;
    Model_Ionizer[1] := cboIonizerModel.ItemIndex;
    {$IFDEF CA410_USE}

    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      case i of
       0 : Com_Ca310[i] := cboCa310_1.ItemIndex ;
       1 : Com_Ca310[i] := cboCa310_2.ItemIndex ;
       2 : Com_Ca310[i] := cboCa310_3.ItemIndex ;
       3 : Com_Ca310[i] := cboCa310_4.ItemIndex ;
      end;
      Com_Ca310_SERIAL[i] := edProbeSerial[i].Text;
      Com_Ca310_DevieId[i] := StrToIntDef(Trim(edProbeDevice[i].Text),0);
    end;

    for i := 0 to Pred(DefCommon.MAX_CA_DRIVE_CNT) do Com_CaDeviceList[i] := '';

    for i := 0 to Pred(cboCa310_1.Items.Count) do begin
      Com_CaDeviceList[i] :=  cboCa310_1.Items[i];
    end;

    DebugLogLevelConfig := cboDebugLogPG.ItemIndex;

    {$ENDIF}
  end;

  if CheckChangedSysInfo(@OldSysInfo, @Common.SystemInfo) = True then begin
    //System Info 변경됨
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, 'Changed SystemInfo');
  end;

  with Common.OnLineInterlockInfo do begin
    Use             := chkVerInterlock.Checked;
    nLine := StrToInt(Copy(Common.SystemInfo.EQPId,length(Common.SystemInfo.EQPId)-2,1));
    Process_Code := Format('45100_50%d',[nLine]);
  end;

  OldDFSInfo:= Common.DfsConfInfo;
  with Common.DfsConfInfo do begin
    bUseDfs         := cbDfsFtpUse.Checked;
    bDfsHexCompress := cbDfsHexCompress.Checked;
    bDfsHexDelete   := cbDfsHexDelete.Checked;
    sDfsServerIP    := edDfsServerIP.Text;
    sDfsUserName    := edDfsUserName.Text;
    sDfsPassword    := edDfsPW.Text;
    //
    bUseCombiDown   := cbUseCombiDown.Checked;
    sCombiDownPath  := edCombiDownPath.Text;
    sProcessName    := Trim(edProcessName.Text);

    bUseDfs := Common.OnLineInterlockInfo.Use;        // OnLineInterlockInfo 설정으로 통합
    bUseCombiDown := Common.OnLineInterlockInfo.Use;  // OnLineInterlockInfo 설정으로 통합
  end;


  if CheckChangedDFSInfo(@OldDFSInfo, @Common.DfsConfInfo) = True then begin
    //변경됨
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, 'Changed DFSInfo');
  end;

  OldPLCInfo:= Common.PLCInfo;
  with Common.PLCInfo do begin
    EQP_ID:= StrToInt(edtECS_EQPID.Text);
    PollingInterval:= StrToInt(edtECS_PollingInterval.Text);
    Timeout_Connection:= StrToInt(edtECS_Timeout_Connection.Text);
    Timeout_ECS:= StrToInt(edtECS_Timeout_ECS.Text);

    Address_ECS:= edtStartAddress_ECS.Text;
    Address_EQP:= edtStartAddress_EQP.Text;
    Address_ROBOT:= edtStartAddress_Robot.Text;
    Address_ECS_W:= edtStartAddress_ECS_W.Text;
    Address_EQP_W:= edtStartAddress_EQP_W.Text;
    Address_ROBOT_W:= edtStartAddress_Robot_W.Text;
    Address_ROBOT2  := edtStartAddress_Robot2.Text; // ADDR 주소 떨어진 경우
    Address_ROBOT_W2 := edtStartAddress_Robot_W2.Text; //
    Address_DoorOpen  := edtStartAddress_Robot_B_DoorOpen.Text;

    InlineGIB:=  chkInlineGIB.Checked;
  end;

  if CheckChangedPLCInfo(@OldPLCInfo, @Common.PLCInfo) = True then begin
    //변경됨
    Common.MLog(DefCommon.MAX_SYSTEM_LOG, 'Changed PLCInfo');
  end;

  with Common.InterlockInfo do begin
    Use             := chkInterlock_SW.Checked;
    Version_SW      := edtVrsion_SW.Text;
    Version_Script  := edtVrsion_Script.Text;
    Version_FW      := edtVrsion_FW.Text;
    Version_DLL     := edtVrsion_Dll.Text;
    Version_LGDDLL  := edtVrsion_LGDDll.Text;
  end;

  Common.SaveSystemInfo;

  SaveBCRPortInfo;
  Common.m_bIsChanged := True;
//	SaveRCB2PortInfo;
  MessageDlg('Save OK. Start This Program again.', mtInformation, [mbOk], 0);
end;

function TfrmSystemSetup.GetSerialNum(nIdx : Integer; sInput: string): string;
var
  sTemp : string;
  slTemp : TStringList;
begin
  sTemp := '';
  slTemp := TStringList.Create;
  try                                                                 // 0         1       2         3 4
    ExtractStrings(['(',')'],[],PChar(sInput),slTemp);    //'USB ID COMM(%d), SerialNo (%s)';
    if slTemp.Count > 3 then begin
      sTemp := Trim(slTemp[nIdx]);
    end;
  finally
    slTemp.Free;
  end;
  Result := sTemp;
end;


procedure TfrmSystemSetup.cboCa310_1Click(Sender: TObject);
begin
{$IFDEF CA410_USE}
  edProbeSerial[DefCommon.CH1].Text := GetSerialNum(3,cboCa310_1.Text);
  edProbeDevice[DefCommon.CH1].Text := GetSerialNum(1,cboCa310_1.Text);
{$ENDIF}
end;

procedure TfrmSystemSetup.cboCa310_2Click(Sender: TObject);
begin
  {$IFDEF CA410_USE}
    edProbeSerial[DefCommon.CH2].Text := GetSerialNum(3,cboCa310_2.Text);
    edProbeDevice[DefCommon.CH2].Text := GetSerialNum(1,cboCa310_2.Text);
  {$ENDIF}
end;

procedure TfrmSystemSetup.cboCa310_3Click(Sender: TObject);
begin
{$IFDEF CA410_USE}
  edProbeSerial[DefCommon.CH3].Text := GetSerialNum(3,cboCa310_3.Text);
  edProbeDevice[DefCommon.CH3].Text := GetSerialNum(1,cboCa310_3.Text);
{$ENDIF}
end;

procedure TfrmSystemSetup.cboCa310_4Click(Sender: TObject);
begin
{$IFDEF CA410_USE}
  edProbeSerial[DefCommon.CH4].Text := GetSerialNum(3,cboCa310_4.Text);
  edProbeDevice[DefCommon.CH4].Text := GetSerialNum(1,cboCa310_4.Text);
{$ENDIF}
end;

procedure TfrmSystemSetup.ChangeFTPDir(NewDir: String);
begin
  FHostLastDirStack.Add(DfsFtpCommon.RetrieveCurrentDir);
  DfsFtpCommon.ChangeDir(NewDir);
  DisplayFTP;
end;

procedure TfrmSystemSetup.ChangeLocalDir(NewDir: string);
begin
  FLocalLastDirStack.Add(edDfsFtpLocalDirNow.Text);
  edDfsFtpLocalDirNow.Text := NewDir;
  DisplayLocal;
end;

function TfrmSystemSetup.CheckAdminPasswd: Boolean;
var
  bRet : boolean;
begin
  bRet := False;
  frmLogIn := TfrmLogIn.Create(Nil);
  try
    frmLogIn.Caption := 'Confirm Admin Password';
    if frmLogIn.ShowModal = mrOK then begin
      frmLogIn.Update;
      bRet := True;
    end;
  finally
    frmLogIn.Free;
    frmLogIn := nil;
  end;
  Result := bRet;
end;

function TfrmSystemSetup.CheckChangedDFSInfo(pData1, pData2: PDfsConfInfo): Boolean;
var
  rtype: TRTTIType;
  fields: TArray<TRttiField>;
  i, k: Integer;
  sValue1, sValue2: String;
begin
  Result:= False;
  rtype := TRTTIContext.Create.GetType(TypeInfo(TDfsConfInfo));
  fields := rtype.GetFields;

  for i := 0 to High(fields) do begin
    if fields[i].FieldType = nil then begin
      //배열 같은 경우 안됨 - 타입 지정 안됨 Type 지정 배열 사용 필요
      continue;
    end;
    if fields[i].FieldType.TypeKind = tkArray then begin
      for k := 0 to fields[i].GetValue(pData1).GetArrayLength-1 do begin
        sValue1:= fields[i].GetValue(pData1).GetArrayElement(k).ToString;
        sValue2:= fields[i].GetValue(pData2).GetArrayElement(k).ToString;
        if sValue1 <> sValue2 then begin
          Common.MLog(DefCommon.MAX_SYSTEM_LOG, Format('DFSInfo Changed  %s(%d): %s -> %s', [fields[i].Name, k, sValue1, sValue2]));
          Result:= True;
        end;
      end;
    end
    else begin
      sValue1:= fields[i].GetValue(pData1).ToString;
      sValue2:= fields[i].GetValue(pData2).ToString;
      if sValue1 <> sValue2 then begin
        Common.MLog(DefCommon.MAX_SYSTEM_LOG, Format('DFSInfo Changed  %s: %s -> %s', [fields[i].Name, sValue1, sValue2]));
        Result:= True;
      end;
    end;
  end;
end;

function TfrmSystemSetup.CheckChangedPLCInfo(pData1, pData2: PPLCInfo): Boolean;
var
  rtype: TRTTIType;
  fields: TArray<TRttiField>;
  i, k: Integer;
  sValue1, sValue2: String;
begin
  Result:= False;
  rtype := TRTTIContext.Create.GetType(TypeInfo(TPLCInfo));
  fields := rtype.GetFields;

  for i := 0 to High(fields) do begin
    if fields[i].FieldType = nil then begin
      //배열 같은 경우 안됨 - 타입 지정 안됨 Type 지정 배열 사용 필요
      continue;
    end;
    if fields[i].FieldType.TypeKind = tkArray then begin
      for k := 0 to fields[i].GetValue(pData1).GetArrayLength-1 do begin
        sValue1:= fields[i].GetValue(pData1).GetArrayElement(k).ToString;
        sValue2:= fields[i].GetValue(pData2).GetArrayElement(k).ToString;
        if sValue1 <> sValue2 then begin
          Common.MLog(DefCommon.MAX_SYSTEM_LOG, Format('PLCInfo Changed  %s(%d): %s -> %s', [fields[i].Name, k, sValue1, sValue2]));
          Result:= True;
        end;
      end;
    end
    else begin
      sValue1:= fields[i].GetValue(pData1).ToString;
      sValue2:= fields[i].GetValue(pData2).ToString;
      if sValue1 <> sValue2 then begin
        Common.MLog(DefCommon.MAX_SYSTEM_LOG, Format('PLCInfo Changed  %s: %s -> %s', [fields[i].Name, sValue1, sValue2]));
        Result:= True;
      end;
    end;
  end;
end;

function TfrmSystemSetup.CheckChangedSysInfo(pData1, pData2: PSystemInfo): Boolean;
var
  rtype: TRTTIType;
  fields: TArray<TRttiField>;
  i, k: Integer;
  sValue1, sValue2: String;
begin
  Result:= False;
  rtype := TRTTIContext.Create.GetType(TypeInfo(TSystemInfo));
  fields := rtype.GetFields;

  for i := 0 to High(fields) do begin
    if fields[i].FieldType = nil then begin
      //배열 같은 경우 안됨 - 타입 지정 안됨 Type 지정 배열 사용 필요
      continue;
    end;
    if fields[i].FieldType.TypeKind = tkArray then begin
      for k := 0 to fields[i].GetValue(pData1).GetArrayLength-1 do begin
        sValue1:= fields[i].GetValue(pData1).GetArrayElement(k).ToString;
        sValue2:= fields[i].GetValue(pData2).GetArrayElement(k).ToString;
        if sValue1 <> sValue2 then begin
          Common.MLog(DefCommon.MAX_SYSTEM_LOG, Format('SystemInfo Changed  %s(%d): %s -> %s', [fields[i].Name, k, sValue1, sValue2]));
          Result:= True;
        end;
      end;
    end
    else begin
      sValue1:= fields[i].GetValue(pData1).ToString;
      sValue2:= fields[i].GetValue(pData2).ToString;
      if sValue1 <> sValue2 then begin
        Common.MLog(DefCommon.MAX_SYSTEM_LOG, Format('SystemInfo Changed  %s: %s -> %s', [fields[i].Name, sValue1, sValue2]));
        Result:= True;
      end;
    end;
  end;
end;

procedure TfrmSystemSetup.chkAutoBackupClick(Sender: TObject);
begin
  btnAutoBackup.Enabled := chkAutoBackup.Checked;
  edAutoBackup.Enabled := chkAutoBackup.Checked;
end;

procedure TfrmSystemSetup.DisplayFTP;
var
  i: Integer;
  sTemp : TStringList;
begin
  lstDfsFtpHostFiles.Items.Clear;
  try
    sTemp := TStringList.Create;
    DfsFtpCommon.List(sTemp);
    edDfsFtpHostDirNow.Text := DfsFtpCommon.RetrieveCurrentDir;
    for i := 0 to Pred(sTemp.Count) do begin
      if DfsFtpCommon.Size(sTemp[i]) = -1 then
        lstDfsFtpHostFiles.Items.Add(sTemp[i]);
    end;
    for i := 0 to Pred(sTemp.Count) do begin
      if DfsFtpCommon.Size(sTemp[i]) <> -1 then
        lstDfsFtpHostFiles.Items.Add(sTemp[i]);
    end;
  finally
    sTemp.Free;
    sTemp := nil;
  end;
end;

procedure TfrmSystemSetup.DisplayLocal;
var
  Rslt : Integer;
  SearchRec : TSearchRec;
begin
  lstDfsFtpLocalFiles.Items.Clear;
  Rslt := FindFirst(edDfsFtpLocalDirNow.Text + '*.*', faAnyFile, SearchRec);
  while Rslt = 0 do begin
    if not ((SearchRec.Name = '.') or (SearchRec.Name = '..')) then begin
      lstDfsFtpLocalFiles.Items.Add(SearchRec.Name);
    end;
    Rslt := FindNext(Searchrec);
  end;
  FindClose(SearchRec);
end;

procedure TfrmSystemSetup.DisplaySystemInfo;
var
  i : Integer;
  sTemp : string;
begin
  pcSysConfig.ActivePageIndex := 0;
  ReadBCRPortInfo;
  with Common.SystemInfo do begin
    cboBCR.ItemIndex    := Com_HandBCR[0];
    cboBCR2.ItemIndex    := Com_HandBCR[1];

    cboIrTempSensor.ItemIndex    := Com_IrTempSensor;
    edSetTemperature.Text        := IntToStr(SetTemperature);
    edSaveEnergy.Text := Format('%d',[SaveEnergy]);
    chkITOBmpMode.Checked          := UseITOMode; // Added by KTS 2022-03-25 오후 1:30:55
    edFileName.Text                := DAELoadWizardPath;
    ChkCHReversal.Checked          := CHReversal;
    cboUIType.ItemIndex            := 	 UIType;
    cboOCType.ItemIndex            :=    OCType;
//    cboLanguage.ItemIndex	         :=		 Language;
    cboEQPId_Type.ItemIndex        :=    EQPId_Type;
    edEQPID_INLINE.Text            :=    EQPId_INLINE;
    edEQPID_MGIB.Text              :=    EQPId_MGIB;
    edEQPID_PGIB.Text              :=    EQPId_PGIB;
    edPRCS_CD_MGIB.Text              :=    EQPId_MGIB_Process_Code;
    edPRCS_CD_PGIB.Text              :=    EQPId_PGIB_Process_Code;
    edServicePort.Text             :=    ServicePort;
    edNetwork.Text                 :=    Network;
    edDeamonPort.Text              :=    DaemonPort;
    edLocalSubject.Text            :=    LocalSubject;
    edRemoteSubject.Text           :=    RemoteSubject;
    edEqccInterval.Text            :=    EqccInterval;
//    edLoaderIndex.Text				     :=    Loader_Index;
//    chkPwrLogUse.Checked					 :=    PowerLog;
    edEasServicePort.Text           :=    Eas_Service;
    edEasNetwork.Text               :=    Eas_Network;
    edEasDeamonPort.Text            :=    Eas_DeamonPort;
    edEasLocalSubject.Text          :=    Eas_LocalSubject;
    edEasRemoteSubject.Text         :=    Eas_RemoteSubject;

    edR2RServicePort.Text           :=    R2R_Service;
    edR2RNetwork.Text               :=    R2R_Network;
    edR2RDeamonPort.Text            :=    R2R_DeamonPort;
    edR2RLocalSubject.Text          :=    R2R_LocalSubject;
    edR2RRemoteSubject.Text         :=    R2R_RemoteSubject;
    edtMesModelInfo.Text            := MesModelInfo;

    cboRCB1.ItemIndex               := Com_RCB[0];
    cboRCB2.ItemIndex               := Com_RCB[1];
    cboCamLight.ItemIndex           := Com_CamLight;

    chkAutoLGDLogBackup.Checked     := AutoLGDLogBackup;

    cboDisplayDllCnt.ItemIndex :=   DisplayDLLCnt;

    chkCh1.Checked      := UseCh[0];
    chkCh2.Checked      := UseCh[1];
    chkCh3.Checked      := UseCh[2];
    chkCh4.Checked      := UseCh[3];

    edtLoginID.Text := AutoLoginID;

    chkVerInterlock.Checked := DLLVerInterlock;

    edMESCodeCnt.Text  := IntToStr(MES_CODE_Cnt);

    edPopupMsgTime.Text := IntToStr(PopupMsgTime);
    edPGResetDelayTime.Text := IntToStr(PGResetDelayTime);
    edPGResetTotalConut.Text := IntToStr(PGResetTotalConut);
(*

*)
    edPlcConfigPath.Text  := PlcConfigPath;

    pnlDebugLogPG.visible := True;  cboDebugLogPG.visible := True;
    cboDebugLogPG.ItemIndex := DebugLogLevelConfig;

    btnPocbEmNo.Visible := True;
    tbEcsSheet.TabVisible := True;

    chkAutoBackup.Checked := AutoBackupUse;
    edAutoBackup.Text     := AutoBackupList;

    cboNGAlarmCount.ItemIndex:= NGAlarmCount;

    if Use_ECS then rgSelectReport.ItemIndex:= 0
    else rgSelectReport.ItemIndex:= 1;


    cboCa310_1.Items.Clear;
    cboCa310_2.Items.Clear;
    cboCa310_3.Items.Clear;
    cboCa310_4.Items.Clear;
    for i := 0 to Pred(DefCommon.MAX_CA_DRIVE_CNT) do begin
      if trim(Com_CaDeviceList[i]) = '' then Break;
      cboCa310_1.Items.Add(Com_CaDeviceList[i]);
      cboCa310_2.Items.Add(Com_CaDeviceList[i]);
      cboCa310_3.Items.Add(Com_CaDeviceList[i]);
      cboCa310_4.Items.Add(Com_CaDeviceList[i]);
    end;

    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      case i of
        0: cboCa310_1.ItemIndex := Com_Ca310[i];
        1: cboCa310_2.ItemIndex := Com_Ca310[i];
        2: cboCa310_3.ItemIndex := Com_Ca310[i];
        3: cboCa310_4.ItemIndex := Com_Ca310[i];
      end;
      edProbeSerial[i].Text := Com_Ca310_SERIAL[i];
      edProbeDevice[i].Text := Format('%d',[Com_Ca310_DevieId[i]]);
    end;




      cboIonizer.ItemIndex := Com_Ionizer[0];
      cboIonizerModel.ItemIndex := Model_Ionizer[0];

      cboIonizer2.ItemIndex := Com_Ionizer[1];

      chkInLineAAMode.Checked := UseInLine_AAMode;
      chkOnlyRestartMode.Checked := OnlyRestartMode;

  end;

{$IFDEF DFS_HEX}
  tbDfsConfigration.TabVisible := True;
  with Common.DfsConfInfo do begin
    cbDfsFtpUse.Checked       := bUseDfs;      //2019-02-01 DFS_FTP
    cbDfsHexCompress.Checked  := bDfsHexCompress;
    cbDfsHexDelete.Checked    := bDfsHexDelete;
    edDfsServerIP.Text        := sDfsServerIP;
    edDfsUserName.Text        := sDfsUserName;
    edDfsPW.Text              := sDfsPassword;
    //
    cbUseCombiDown.Checked    := bUseCombiDown;
    edCombiDownPath.Text      := sCombiDownPath;
    edProcessName.Text        := sProcessName;
  end;
{$ELSE}
  tbDfsConfigration.TabVisible := False;
{$ENDIF}
  btnAutoBackup.Enabled := chkAutoBackup.Checked;
  edAutoBackup.Enabled := chkAutoBackup.Checked;



  with Common.PLCInfo do begin
    edtECS_EQPID.Text:= IntToStr(EQP_ID);
    edtECS_PollingInterval.Text:= IntToStr(PollingInterval);
    edtECS_Timeout_Connection.Text:= IntToStr(Timeout_Connection);
    edtECS_Timeout_ECS.Text:= IntToStr(Timeout_ECS);

    edtStartAddress_ECS.Text:= Address_ECS;
    edtStartAddress_EQP.Text:= Address_EQP;
    edtStartAddress_ROBOT.Text:= Address_ROBOT;
    edtStartAddress_ROBOT2.Text:= Address_ROBOT2;
    edtStartAddress_ECS_W.Text:= Address_ECS_W;
    edtStartAddress_EQP_W.Text:= Address_EQP_W;
    edtStartAddress_ROBOT_W.Text:= Address_ROBOT_W;
    edtStartAddress_ROBOT_W2.Text:= Address_ROBOT_W2;
    edtStartAddress_Robot_B_DoorOpen.Text := Address_DoorOpen;
    chkInlineGIB.Checked:= InlineGIB;
  end;

  with Common.InterlockInfo do begin
    chkInterlock_SW.Checked  := Common.InterlockInfo.Use;
    edtVrsion_DLL.Text        := Common.InterlockInfo.Version_DLL;

    edtVrsion_Script.Text    := Common.InterlockInfo.Version_Script;
    edtVrsion_FW.Text        := Common.InterlockInfo.Version_FW;
    edtVrsion_SW.Text      := Common.InterlockInfo.Version_SW;
    edtVrsion_LGDDLL.Text     := Common.InterlockInfo.Version_LGDDLL;
  end;
  with Common.OnLineInterlockInfo do begin
    chkVerInterlock.Checked  := Use;
  end;

end;



procedure TfrmSystemSetup.FindItemToListbox(tList: TRzListbox; sItem: string);
var
  i : Integer;
begin
  for i := 0 to tList.Items.Count - 1 do begin
    if tList.Items.Strings[i] = sItem then begin
      tList.ItemIndex := i;
      Break;
    end;
  end;
end;

procedure TfrmSystemSetup.FormClose(Sender: TObject; var Action: TCloseAction);

begin
;
  cboBCR.Items.Clear;
  cboUIType.Items.Clear;
  cboOCType.Items.Clear;
  cboRCB1.Items.Clear;
  cboRCB2.Items.Clear;

  cboLanguage.Items.Clear;

  Action := caFree;
end;

procedure TfrmSystemSetup.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  FHostLastDirStack := TStringList.Create;
  FLocalLastDirStack := TStringList.Create;


  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin

    edProbeSerial[i] := TRzEdit.Create(Self);
    edProbeSerial[i].Parent := grpCa310Set;
    edProbeSerial[i].Width  := 200;
    edProbeSerial[i].Height := 22;

    edProbeDevice[i] := TRzEdit.Create(Self);
    edProbeDevice[i].Parent := grpCa310Set;
    edProbeDevice[i].Width  := 200;
    edProbeDevice[i].Height := 22;
    edProbeDevice[i].Visible := False;

{$IFDEF CA310_USE}
    edProbeSerial[i].Top    := pnlProbeTitle1.Top + pnlProbeTitle1.Height + 1;
    edProbeSerial[i].Left   := i*edProbeSerial[i].Width + 6 + i;
{$ELSE}
    case i of
      0:
      begin
        edProbeSerial[i].Top    := pnlProbeTitle1.Top + pnlProbeTitle1.Height + 1;
        edProbeSerial[i].Left   := 6;
      end;
      1:
      begin
        edProbeSerial[i].Top    := pnlProbeTitle2.Top + pnlProbeTitle2.Height + 1;
        edProbeSerial[i].Left   := 6;
      end;
      2:
      begin
        edProbeSerial[i].Top    := pnlProbeTitle3.Top + pnlProbeTitle3.Height + 1;
        edProbeSerial[i].Left   := 6;
      end;
      3:
      begin
        edProbeSerial[i].Top    := pnlProbeTitle4.Top + pnlProbeTitle4.Height + 1;
        edProbeSerial[i].Left   := 6;
      end;
    end;

{$ENDIF}
{$IFDEF CA410_USE}
    edProbeSerial[i].Width  := 300;
{$ENDIF}
    edProbeSerial[i].Visible := True;
  end;

  DisplaySystemInfo;
  if (Common.SystemInfo.OCType = DefCommon.OCType) and (Pos('A-',Common.SystemInfo.TestModel) = 0) then
    chkInLineAAMode.Visible := True
  else chkInLineAAMode.Visible := False;

  if Common.SupervisorMode  then begin
    RzGroupBox4.Visible := True;
    RzGroupBox9.Visible := True;
    RzpnlCombiPath.Visible := True;
    edCombiDownPath.Visible := True;
  end
  else begin
    RzGroupBox4.Visible := False;
    RzGroupBox9.Visible := False;
    RzpnlCombiPath.Visible := False;
    edCombiDownPath.Visible := False;
  end;
end;

procedure TfrmSystemSetup.FormDestroy(Sender: TObject);
begin
  if DfsFtpCommon <> nil then begin
    if DfsFtpCommon.IsConnected then DfsFtpCommon.DisConnect;
    DfsFtpCommon.Free;
    DfsFtpCommon := nil;
  end;
  FHostLastDirStack.Free;
  FHostLastDirStack := nil;
  FLocalLastDirStack.Free;
  FLocalLastDirStack := nil;
//  Self := nil;
end;

procedure TfrmSystemSetup.FormShow(Sender: TObject);
begin
//  pcSysConfig.ActivePage := TabSheet1;
end;

procedure TfrmSystemSetup.FtpConnection(bConn: Boolean);
begin
  if bConn then begin
    pnlDfsFtpStatus.Caption := 'Connected';
    pnlDfsFtpStatus.Font.Color := clLime;
    FHostRootDir  := DfsFtpCommon.RetrieveCurrentDir;
    FLocalRootDir := Common.Path.DfsDefect;   //TBD? Common.SystemInfo.ShareFolder;
    edDfsFtpHostDirNow.Text := FHostRootDir;
    if (edDfsFtpHostDirNow.Text[Length(edDfsFtpHostDirNow.Text)] <> '/') then
      edDfsFtpHostDirNow.Text := edDfsFtpHostDirNow.Text + '/';
    edDfsFtpLocalDirNow.Text := FLocalRootDir + '\';  //2019-02-07 DFS_FTP POCB_A2CH
    if (edDfsFtpLocalDirNow.Text[Length(edDfsFtpLocalDirNow.Text)] <> '\') then
      edDfsFtpLocalDirNow.Text := edDfsFtpLocalDirNow.Text + '\';
    DisplayFTP;
    DisplayLocal;
  end
  else begin
    pnlDfsFtpStatus.Caption := 'Disonnected';
    pnlDfsFtpStatus.Font.Color := clRed;
  end;
end;

procedure TfrmSystemSetup.lstDfsFtpHostFilesDblClick(Sender: TObject);
var
  sPath, sSubPath : string;
  i : integer;
begin
//  btnDownloadClick(Sender);
  if DfsFtpCommon = nil then Exit;

  for i := 0 to Pred(lstDfsFtpHostFiles.Items.Count) do begin
    if lstDfsFtpHostFiles.Selected[i] then begin
      sSubPath := Trim(lstDfsFtpHostFiles.Items[i]);
      Break;
    end;
  end;
  if sSubPath = '.' then exit;
  if sSubPath = '' then exit;
  //if sSubPath = '..' then exit;
  if (edDfsFtpHostDirNow.Text[Length(edDfsFtpHostDirNow.Text)] <> '/') then
    edDfsFtpHostDirNow.Text := edDfsFtpHostDirNow.Text + '/';
  edDfsFtpHostDirNow.Text := edDfsFtpHostDirNow.Text + sSubPath + '/';
  sPath := edDfsFtpHostDirNow.Text;
  ChangeFTPDir(sPath);
end;

procedure TfrmSystemSetup.lstDfsFtpLocalFilesDblClick(Sender: TObject);
var
  sPath, sSubPath : string;
  i : integer;
  nFileAttrs : integer;
begin
  if DfsFtpCommon = nil then Exit;

  for i := 0 to Pred(lstDfsFtpLocalFiles.Items.Count) do begin
    if lstDfsFtpLocalFiles.Selected[i] then begin
      sSubPath := Trim(lstDfsFtpLocalFiles.Items[i]);
      Break;
    end;
  end;
  if sSubPath = '.' then exit;
  if sSubPath = '' then exit;
  //if sSubPath = '..' then exit;
  nFileAttrs := FileGetAttr(edDfsFtpLocalDirNow.Text + sSubPath);
  if (nFileAttrs and faDirectory) = 0 then begin // Not Directory
    Exit;
  end;
  if (edDfsFtpLocalDirNow.Text[Length(edDfsFtpLocalDirNow.Text)] <> '/') then
    edDfsFtpLocalDirNow.Text := edDfsFtpLocalDirNow.Text + '\';
  edDfsFtpLocalDirNow.Text := edDfsFtpLocalDirNow.Text + sSubPath + '\';
  sPath := edDfsFtpLocalDirNow.Text;
  ChangeLocalDir(sPath);
end;


procedure TfrmSystemSetup.ReadBCRPortInfo;
var
  MyConfig : TIniFile;
begin
  MyConfig := TIniFile.Create(Common.Path.SysInfo);
  with MyConfig do begin
    // Temp Control Comport
    cboBCR.Text    := ReadString('ComPortBCR', 'Port', 'None');
//    cboBaudRate1.Text    := ReadString('ComPortBCR', 'BaudRate', '9600');
//    cboStopBits1.Text    := ReadString('ComPortBCR', 'StopBits', '1');
//    cboDataBits1.Text    := ReadString('ComPortBCR', 'DataBits', '8');
//    cboParity1.Itemindex := ReadInteger('ComPortBCR', 'Parity', 0);
//    cboFlowControl1.Itemindex := ReadInteger('ComPortBCR', 'FlowControl', 1);
  end;
  MyConfig.Free;
end;

procedure TfrmSystemSetup.RzBitBtn1Click(Sender: TObject);
begin
  if CheckAdminPasswd then begin
    frmChangePassword := TfrmChangePassword.Create(Application);
    try
      frmChangePassword.ShowModal;
    finally
      frmChangePassword.Free;
      frmChangePassword := nil;
    end;
  end;
end;



procedure TfrmSystemSetup.RzBitBtn3Click(Sender: TObject);
var
  txFile : TextFile;
  sReadData, sTemp, sTemp2, sSearchIp : string;
begin
  dlgOpenGmes.InitialDir := Common.Path.Ini;
  dlgOpenGmes.Filter := 'Open GMES Setup File (*.txt)|*.txt';
  dlgOpenGmes.DefaultExt := dlgOpenGmes.Filter;
  if dlgOpenGmes.Execute then begin
    AssignFile(txFile,dlgOpenGmes.FileName);
    sSearchIp := '';
    try
      Reset(txFile);
      while not Eof(txFile) do begin
        Readln(txFile,sReadData);
        if Pos('MES_SERVICEPORT=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'MES_SERVICEPORT=','',[rfReplaceAll]) );
          edServicePort.Text := sTemp;
        end
        else if Pos('MES_NETWORK=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'MES_NETWORK=','',[rfReplaceAll]) );
          edNetwork.Text := sTemp;
        end
        else if Pos('MES_DAEMONPORT=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'MES_DAEMONPORT=','',[rfReplaceAll]) );
          edDeamonPort.Text := sTemp;
        end
        else if Pos('EAS_SERVICEPORT=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'EAS_SERVICEPORT=','',[rfReplaceAll]) );
          edEasServicePort.Text := sTemp;
        end
        else if Pos('EAS_NETWORK=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'EAS_NETWORK=','',[rfReplaceAll]) );
          edEasNetwork.Text := sTemp;
        end
        else if Pos('EAS_DAEMONPORT=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'EAS_DAEMONPORT=','',[rfReplaceAll]) );
          edEasDeamonPort.Text := sTemp;
        end
        else if Pos('EAS_REMOTESUBJECT=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'EAS_REMOTESUBJECT=','',[rfReplaceAll]) );
          edEasRemoteSubject.Text := sTemp;
        end

        else if Pos('LOCAL_MES_IP=',sReadData) <> 0 then begin
          //GMES 셋업 파일에서 MES_LOCALSUBJECT, EAS_LOCALSUBJECT보다LOCAL_MES_IP가 먼저 와야 한다.
          sSearchIp := Trim(StringReplace(sReadData,'LOCAL_MES_IP=','',[rfReplaceAll]) );
        end
        else if Pos('MES_LOCALSUBJECT=',sReadData) <> 0 then begin
          sTemp := Trim(common.GetLocalIpList(DefCommon.IP_LOCAL_GMES,sSearchIp));
          Common.SystemInfo.LocalIP_GMES := sTemp;
          Common.SaveLocalIpToSys(DefCommon.IP_LOCAL_GMES);
          sTemp2 := StringReplace( sTemp,'.','_',[rfReplaceAll] );
          sTemp := Trim(StringReplace(sReadData,'MES_LOCALSUBJECT=','',[rfReplaceAll]) );
          edLocalSubject.Text := sTemp + sTemp2;
        end
        else if Pos('EAS_LOCALSUBJECT=',sReadData) <> 0 then begin
          sTemp := Trim(common.GetLocalIpList(DefCommon.IP_LOCAL_GMES,sSearchIp));
          Common.SystemInfo.LocalIP_GMES := sTemp;
          Common.SaveLocalIpToSys(DefCommon.IP_LOCAL_GMES);
          sTemp2 := StringReplace( sTemp,'.','_',[rfReplaceAll] );
          sTemp := Trim(StringReplace(sReadData,'EAS_LOCALSUBJECT=','',[rfReplaceAll]) );
          edEasLocalSubject.Text := sTemp + sTemp2;
        end
        else if Pos('MES_REMOTESUBJECT=',sReadData) <> 0 then begin
          sTemp := Trim(StringReplace(sReadData,'MES_REMOTESUBJECT=','',[rfReplaceAll]) );
          edRemoteSubject.Text := sTemp;
        end;
      end;
    finally
      CloseFile(txFile);
    end;
  end;
end;

procedure TfrmSystemSetup.RzBitBtn4Click(Sender: TObject);
var
  i, j,nDeviceCnt : Integer;
  sIdx, sGetSerial : string;
begin
{$IFDEF CA410_USE}
  nDeviceCnt := CaSdk2.DeviceCount;
  cboCa310_1.Items.Clear;
  cboCa310_2.Items.Clear;
  cboCa310_3.Items.Clear;
  cboCa310_4.Items.Clear;
  cboCa310_1.Items.Add('NONE');
  cboCa310_2.Items.Add('NONE');
  cboCa310_3.Items.Add('NONE');
  cboCa310_4.Items.Add('NONE');
  for i := 0 to Pred(nDeviceCnt) do begin
    sIdx := Format(CA410_DISPLAY_ITEM{'USB ID (COMM%d), SerialNo (%s)'},[CaSdk2.m_DeviceInfo[i].DeviceId,CaSdk2.m_DeviceInfo[i].SerialNo]);
    cboCa310_1.Items.Add(sIdx);
    cboCa310_2.Items.Add(sIdx);
    cboCa310_3.Items.Add(sIdx);
    cboCa310_4.Items.Add(sIdx);
  end;
{$ENDIF}
{$IFDEF  CA310_USE}
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    if DongaCa310[i] <> nil  then begin
      if DongaCa310[i].m_bConnection then begin
        for j := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
          if not Common.SystemInfo.UseCh[j+4*i] then Continue;
          sIdx := Format('P%d',[j+1]);
          sGetSerial := DongaCa310[i].RBrightobj.objCa.OutputProbes.Item[sIdx].SerialNO;
          edProbeSerial[j+4*i].Text := sGetSerial;
        end;
      end;
    end;

  end;
{$ENDIF}
end;

procedure TfrmSystemSetup.btnAutoBackupClick(Sender: TObject);
begin

//  dlgOpen.InitialDir := 'D:\';

  if dlgOpen.Execute then begin
    edAutoBackup.Text := dlgOpen.SelectedPathName;
  end;
end;

procedure TfrmSystemSetup.SaveBCRPortInfo;
var
    MyConfig : TIniFile;
begin
  MyConfig := TIniFile.Create(Common.Path.SysInfo);
  with MyConfig do begin
    WriteString('ComPortBCR', 'Port',     cboBCR.Text);
//    WriteString('ComPortBCR', 'BaudRate', cboBaudRate1.Text);
//    WriteString('ComPortBCR', 'StopBits', cboStopBits1.Text);
//    WriteString('ComPortBCR', 'DataBits', cboDataBits1.Text );
//    WriteInteger('ComPortBCR', 'Parity',  cboParity1.Itemindex);
//    WriteInteger('ComPortBCR', 'FlowControl', cboFlowControl1.Itemindex);
  end;
  MyConfig.Free;
  WritePrivateProfileString(nil, nil, nil, PChar(Common.Path.SysInfo));
end;

end.
