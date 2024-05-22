unit FileTrans;

interface

uses
  Winapi.Windows, Winapi.Messages,  System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,System.SysUtils, RzCommon, Vcl.StdCtrls, RzCmboBx, RzLstBox, RzChkLst,
  RzTabs, Vcl.Mask, RzEdit, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, RzLabel, RzPanel, RzButton, System.UITypes,
  Vcl.ExtCtrls, IdSocketHandle, AdvUtil, {UdpServerClient,}CommPG, DefCommon, CommonClass, system.threading;

type
  TfrmFileTrans = class(TForm)
    pnlHeader: TRzPanel;
    pnlTail: TRzPanel;
    btnClose: TRzBitBtn;
    pnlDownload: TRzPanel;
    grpDownStatus: TRzGroupBox;
    lblmsec: TRzLabel;
    lblWaitTime: TRzLabel;
    btnSelAllIP: TRzBitBtn;
    btnClearIP: TRzBitBtn;
    gridPGList: TAdvStringGrid;
    edTime: TRzNumericEdit;
    tcDownType: TRzTabControl;
    pnlListCtrl: TRzPanel;
    grpPCFilelist: TRzGroupBox;
    lstPCFileList: TRzCheckList;
    btnSelAllPC: TRzBitBtn;
    btnClearPC: TRzBitBtn;
    btnDeletePC: TRzBitBtn;
    pnlScreenPanel: TRzPanel;
    btnDownload: TRzBitBtn;
    grpSplitOption: TRzGroupBox;
    pnlHoriValue: TRzPanel;
    edHorDmy: TRzNumericEdit;
    pnlVertiValue: TRzPanel;
    edVerDmy: TRzNumericEdit;
    cboSplitBit: TRzComboBox;
    pnlBitType: TRzPanel;
    grpBMPResolution: TRzGroupBox;
    cboResolution: TRzComboBox;
    RzFrameController1: TRzFrameController;
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tcDownTypeChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnSelAllPCClick(Sender: TObject);
    procedure btnClearPCClick(Sender: TObject);
    procedure btnSelAllIPClick(Sender: TObject);
    procedure btnClearIPClick(Sender: TObject);
    procedure btnDeletePCClick(Sender: TObject);
    procedure gridPGListSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure gridPGListCheckBoxClick(Sender: TObject; ACol, ARow: Integer; State: Boolean);
    procedure cboResolutionChange(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
  private
    m_bLockUI : array[DefCommon.CH1 .. DefCommon.MAX_CH] of Boolean;
    RawBgrData : array of byte;
    RawData : array of Byte;
    Timer_ConnCheck    : TTimer;
    m_sDownList  : TStringList;
    sCurrPath     : String;  //Current Path Directory
    Image_Pat1    : TImage;

    procedure MakeDownList;
    procedure ConnCheckTimer(Sender: TObject);
    function  IsCheckPGList : Boolean;
    function  CheckedPGCount : Integer;
    procedure ConvertBmp2RawFile;
    procedure Clear_StringGrid_PGList;
    procedure SaveRawFile(fName : String);
    procedure MakeRawFile(fName : String);
    procedure DeleteDataFilePC(fName: String);
    procedure StartDataDownload(nPgNo, nSendDataCnt : Integer; const fileTransRec : TArray<TFileTranStr>);
    procedure ThreadTask(task : TProc);
    procedure unLockGui(nPg : Integer);
  public
    procedure SetDownLoadEnd(bSet : Boolean);
    procedure RefreshScreen;
  end;
var
  frmFileTrans: TfrmFileTrans;

implementation

uses DefPG;

{$R *.dfm}


procedure TfrmFileTrans.btnClearIPClick(Sender: TObject);

begin
  gridPGList.UnCheckAll(0);
  Clear_StringGrid_PGList;
end;

procedure TfrmFileTrans.btnClearPCClick(Sender: TObject);
begin
  lstPCFileList.UncheckAll;
end;

procedure TfrmFileTrans.btnCloseClick(Sender: TObject);
begin
	Common.DelateBmpRawFile;
  Close;
end;

procedure TfrmFileTrans.btnDeletePCClick(Sender: TObject);
var
  i : Integer;
  Rslt : Integer;
begin
  if lstPCFileList.ItemsChecked < 1 then begin
    MessageDlg(#13#10 + 'Not Selected Any Files to Delete!', mtError, [mbOk], 0);
    Exit;
  end;

  if MessageDlg(#13#10 + 'Are you sure to Delete Selected Files?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;

  Rslt := mrNo;
  for i := 0 to lstPCFileList.Items.Count - 1 do begin
    if lstPCFileList.ItemChecked[i] then begin
      if Rslt <> mrYesToAll then begin
        Rslt := MessageDlg(#13#10 + 'File [' + lstPCFileList.Items[i] + '] Delete?', mtConfirmation,
                           [mbYesToAll, mbYes, mbAbort, mbCancel], 0);
        if      Rslt = mrAbort  then Continue
        else if Rslt = mrCancel then Break;
      end;
      DeleteDataFilePC(lstPCFileList.Items[i]);
    end;
  end;
  RefreshScreen;
end;

procedure TfrmFileTrans.btnDownloadClick(Sender: TObject);
var
  i   : Integer;
  //f_indx : array[0..MAX_PG_CNT-1] of Integer;
  isChecked, isStart  : Boolean;
  sFileName : AnsiString;
  fileTrans           : TArray<TFileTranStr>;
  nTotalSize          : Integer;
  dChecksum           : dword;
  getFileData         : TArray<System.Byte>;
begin
  if not IsCheckPGList then begin
    MessageDlg(#13#10 + 'Not Selected Any PG to Download!', mtError, [mbOk], 0);
    Exit;
  end;

  if lstPCFileList.Items.Count = 0 then begin
    MessageDlg(#13#10 + 'No Files to Download!', mtError, [mbOk], 0);
    Exit;
  end;

  if lstPCFileList.ItemsChecked < 1 then begin
    MessageDlg(#13#10 + 'Not Selected Any Files to Download!', mtError, [mbOk], 0);
    Exit;
  end;

  if CheckedPGCount > DefCommon.MAX_PG_CNT then begin
    MessageDlg(#13#10 + 'PG count to download a maximum number of 10.!', mtError, [mbOk], 0);
    Exit;
  end;

  SetDownLoadEnd(False);
  MakeDownList;

  if tcDownType.TabIndex = DOWNLOAD_TYPE_BMP then begin
    ConvertBmp2RawFile;
  end;

  Clear_StringGrid_PGList;

  SetLength(fileTrans,SizeOf(fileTrans)*m_sDownList.Count);
  for i := 0 to Pred(m_sDownList.Count) do begin
    fileTrans[i].TransMode := tcDownType.TabIndex;
    sFileName := AnsiString(m_sDownList.Strings[i]);
    case fileTrans[i].TransMode of
      // BMP Download.
      DefCommon.DOWNLOAD_TYPE_BMP : begin
        fileTrans[i].fileName := AnsiString(StringReplace(string(sFileName),'.bmp','.raw', [rfReplaceAll, rfIgnoreCase]));
        fileTrans[i].filePath := AnsiString(Common.Path.BMP);
        fileTrans[i].TransType  := DefPG.TRANS_TYPE_BMP;
      end;
      // Initial Code Download.
      DefCommon.DOWNLOAD_TYPE_PRG : begin
        fileTrans[i].filePath := AnsiString(Common.Path.ModelCode);
        if ExtractFileExt(string(sFileName))      = '.mpt'    then fileTrans[i].TransType  := DefPG.TRANS_TYPE_TXIC
        else if ExtractFileExt(string(sFileName)) = '.mion'   then fileTrans[i].TransType  := DefPG.TRANS_TYPE_MODULE_ON
        else if ExtractFileExt(string(sFileName)) = '.mioff'  then fileTrans[i].TransType  := DefPG.TRANS_TYPE_MODULE_OFF
        else if ExtractFileExt(string(sFileName)) = '.pwon'   then fileTrans[i].TransType  := DefPG.TRANS_TYPE_PWR_ON
        else if ExtractFileExt(string(sFileName)) = '.pwoff'  then fileTrans[i].TransType  := DefPG.TRANS_TYPE_PWR_OFF
        else if ExtractFileExt(string(sFileName)) = '.miau'   then fileTrans[i].TransType  := DefPG.TRANS_TYPE_PWR_ON_AUTO
        else if ExtractFileExt(string(sFileName)) = '.otpw'   then fileTrans[i].TransType  := DefPG.TRANS_TYPE_OTP_WRITE
        else if ExtractFileExt(string(sFileName)) = '.otpr'   then fileTrans[i].TransType  := DefPG.TRANS_TYPE_OTP_READ
        else if ExtractFileExt(string(sFileName)) = '.misc'   then fileTrans[i].TransType  := DefPG.TRANS_TYPE_SCREEN_CODE;
        fileTrans[i].fileName := sFileName;
      end;
      DefCommon.DOWNLOAD_TYPE_PG_FPGA : begin
        fileTrans[i].filePath := AnsiString(Common.Path.PG_FPGA);
        fileTrans[i].TransType  := DefPG.FUSING_TYPE_PG_FPGA;
        fileTrans[i].fileName := sFileName;
      end;
      DefCommon.DOWNLOAD_TYPE_PG_FW : begin
        fileTrans[i].filePath := AnsiString(Common.Path.PG_FW);
        fileTrans[i].TransType  := DefPG.FUSING_TYPE_PG_FW;
        fileTrans[i].fileName := sFileName;
      end;
      DefCommon.DOWNLOAD_TYPE_TOUCH_FW : begin
        fileTrans[i].filePath := AnsiString(Common.Path.TOUCH_FW);
        fileTrans[i].TransType  := DefPG.FUSING_TYPE_TOUCH_FW;
        fileTrans[i].fileName := sFileName;
      end;
    end;
    dChecksum := 0;
    Common.LoadCheckSumNData(string(fileTrans[i].filePath+fileTrans[i].fileName),dChecksum,nTotalSize,getFileData);
    fileTrans[i].CheckSum   := dChecksum;
    fileTrans[i].TotalSize  := nTotalSize;
    SetLength(fileTrans[i].Data, nTotalSize);
    CopyMemory(@fileTrans[i].Data[0],@getFileData[0],nTotalSize);
  end;
//  nTotalSize, nChecksum : Integer;
//  getFileData         : array of byte;
  isStart := False;
  // PG List.
  for i := 1 to Pred(gridPGList.RowCount) do begin
    if gridPGList.Cells[0,i] = '' then Continue;
    isChecked := False;
    gridPGList.GetCheckBoxState(0, i, isChecked);
    if isChecked then begin
      isStart := True;
      gridPGList.AddProgressFormatted(2,i,clLime,clBlack,clInfoBk,clBlue,'%d%%',0, 100);
      m_bLockUI[i-1] := True;
      StartDataDownload(i-1,m_sDownList.Count,fileTrans);
    end;
  end;
  // Start 못했을때 UI Lock 풀어 주자.
  if not isStart then begin
    SetDownLoadEnd(True);
  end;
end;

procedure TfrmFileTrans.btnSelAllIPClick(Sender: TObject);
begin
  gridPGList.CheckAll(0);
  Clear_StringGrid_PGList;
end;

procedure TfrmFileTrans.btnSelAllPCClick(Sender: TObject);
begin
  lstPCFileList.CheckAll;
end;

procedure TfrmFileTrans.cboResolutionChange(Sender: TObject);
var
  sl : TStringList;
begin
  lstPCFileList.Clear;
  lstPCFileList.Sorted := False;
  sl := Common.BmpGetKeyValueList(cboResolution.Text);
  try
    lstPCFileList.Items.Assign(sl);
  finally
   sl.Free;
  end;
end;

function TfrmFileTrans.CheckedPGCount: Integer;
var
  i, num : Integer;
  State : Boolean;
begin
  num := 0;
  for i := 1 to gridPGList.RowCount-1 do begin
    if gridPGList.GetCheckBoxState(0, i, State) then
      if State then inc(num)
  end;
  Result := num;
end;

procedure TfrmFileTrans.Clear_StringGrid_PGList;
var
  i : Integer;
begin
  for i := 1 to gridPGList.RowCount-1 do begin
    gridPGList.Ints [2,i] := 0;
    gridPGList.Cells[3,i] := '';
  end;
end;

procedure TfrmFileTrans.ConnCheckTimer(Sender: TObject);
var
  i : Integer;
begin
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if pg[i] <> nil then begin

      if pg[i].Status <> pgDisconnect then begin
        gridPGList.Cells[1,i+1] := 'CONNECT';
        gridPGList.RowColor[i+1] := clWindow;
        gridPGList.Cells[0,i+1]  := Common.SystemInfo.IPAddr[i];//PG[i].IP;
      end
      else begin
        gridPGList.Cells[1,i+1] := 'DISCONNECT';
        gridPGList.RowColor[i+1] := clGray;
        gridPGList.Cells[0,i+1]  := '';
      end;
    end;
  end;
end;

procedure TfrmFileTrans.ConvertBmp2RawFile;
var
  i : Integer;
begin
  // BMP 파일을 RAW파일로 변경
  for i := 0 to m_sDownList.Count -1 do begin
    MakeRawFile(m_sDownList.Strings[i]);
    SaveRawFile(m_sDownList.Strings[i]);
  end;
end;

procedure TfrmFileTrans.DeleteDataFilePC(fName: String);
begin
  try
    DeleteFile(sCurrPath + fName);
  except
    MessageDlg(#13#10 + 'File Delete Error! [' + sCurrPath + fName + ']', mtError, [mbOk], 0);
    Exit;
  end;
end;

procedure TfrmFileTrans.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmFileTrans.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  i : Integer;
  bWait : Boolean;
begin
  Timer_ConnCheck.Enabled         := False;
  Timer_ConnCheck.Free;
  Timer_ConnCheck := nil;

  m_sDownList.Free;
  Image_Pat1.Free;

  bWait := False;
  // 동작중 강제 종료 하자.
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if PG[i].Status = pgWait then begin
      PG[i].Status := pgForceStop;
      bWait := True;
    end;
  end;
  // 강제 종료 한다면 기다렸다가 끄자.
  if bWait then Common.Delay(1000);
end;

procedure TfrmFileTrans.FormCreate(Sender: TObject);
var
  i : Integer;
  sl : TStringList;
begin
  sCurrPath := '';

  m_sDownList   := TStringList.Create;
  Image_Pat1  := TImage.Create(Self);
//	CommonAging.ReadSystemInfo;

  gridPGList.RowCount  := DefCommon.MAX_PG_CNT+1;
  gridPGList.ProgressAppearance.CompletionSmooth := False;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    gridPGList.AddCheckBox(0,i+1, False, False);
    gridPGList.Cells[0,i+1]  := Common.SystemInfo.IPAddr[i];//PG[i].IP; //old-SystemInfo.IPAddr[i-1];
    if pg[i].Status <> pgDisconnect then begin
      gridPGList.Cells[1,i+1] := 'CONNECT';
      gridPGList.RowColor[i+1] := clWindow;
    end
    else begin
      gridPGList.Cells[1,i+1] := 'DISCONNECT';
      gridPGList.RowColor[i+1] := clGray;
    end;

    gridPGList.Cells[1,i+1] := '';
    gridPGList.AddProgress(2,i+1, clLime, clWhite);
    gridPGList.Ints [2,i+1] := 0;
    gridPGList.Cells[3,i+1] := '';
    m_bLockUI[i] := False;
  end;
  // 연결상태 확인.
  Timer_ConnCheck := TTimer.Create(self);
  Timer_ConnCheck.OnTimer := ConnCheckTimer;
  Timer_ConnCheck.Interval := 1000;
  Timer_ConnCheck.Enabled   := True;

  gridPGList.DoubleBuffered := True;

  cboResolution.Items.Clear;
  sl := Common.BmpGetSectionList;
  try
   cboResolution.Items.Assign(sl);
  finally
   sl.Free;
  end;
  cboResolution.ItemIndex := 0;
end;

procedure TfrmFileTrans.FormDestroy(Sender: TObject);
begin
  frmFileTrans := nil;
end;

procedure TfrmFileTrans.FormShow(Sender: TObject);
begin
  tcDownType.TabIndex := DOWNLOAD_TYPE_BMP;
  tcDownTypeChange(nil);
end;

procedure TfrmFileTrans.gridPGListCheckBoxClick(Sender: TObject; ACol, ARow: Integer; State: Boolean);
var
  i : Integer;
  isChecked: Boolean;
begin

  for i := 1 to gridPGList.RowCount-1 do begin
    isChecked := False;
    gridPGList.GetCheckBoxState(0, i, isChecked);
    if isChecked then Break;
  end;
  if isChecked = False then btnClearIPClick(nil);
end;
procedure TfrmFileTrans.gridPGListSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  if (ACol = 0)then
    gridPGList.Options := gridPGList.Options + [goEditing]
  else
    gridPGList.Options := gridPGList.Options - [goEditing];
end;

function TfrmFileTrans.IsCheckPGList: Boolean;
var
  i : Integer;
  isChecked: Boolean;
begin
  for i := 1 to gridPGList.RowCount-1 do begin
    isChecked := False;
    gridPGList.GetCheckBoxState(0, i, isChecked);
    if isChecked then Break;
  end;
  Result := isChecked;
end;


procedure TfrmFileTrans.MakeDownList;
var
  i : Integer;
begin
  m_sDownList.Clear;
  for i := 0 to lstPCFileList.Items.Count - 1 do begin
    if lstPCFileList.ItemChecked[i] then begin
        m_sDownList.Add(lstPCFileList.Items.Strings[i]);
    end;
  end;
end;

procedure TfrmFileTrans.MakeRawFile(fName: String);
var
  i,j, nTemp, nType : Integer;
  nHeight, nWidth : Integer;
begin
  SetLength(RawData,0);    //Initial
  SetLength(RawBgrData,0); //Initial
  Image_Pat1.Picture := nil;
  try //Type에 맞지않는 Bitmap인 경우 처리
    Image_Pat1.Picture.LoadFromFile(sCurrPath + fName);
//		Image_Pat1.Picture.LoadFromFile(fName);
  except end;
//  if Image_Pat1.Picture.Bitmap.PixelFormat < pf24bit then begin
//    ShowMessage( 'Image Pixel Format is below 24 bit ---- Check Image format size.');
//    Exit;
//  end;

  nHeight := Image_Pat1.Picture.Bitmap.Height;
  nWidth  := Image_Pat1.Picture.Bitmap.Width;
  if nWidth <= 2048 then begin
    nType := 2048;
    SetLength(RawData,   (nHeight*nWidth*3));
    SetLength(RawBgrData,(nType*3*nHeight));
    for i := 0 to Pred(nHeight) do begin
      CopyMemory(@RawData[i*nWidth*3],Image_Pat1.Picture.Bitmap.ScanLine[i],nWidth*3);
    end;
    for i := 0 to Pred(nHeight) do begin
      nTemp := i*nType*3;
      for j := 0 to Pred(nType) do begin
        if nWidth > j then begin
          RawBgrData[nTemp+j] :=  RawData[nWidth*i*3+j*3];              // B
          RawBgrData[nTemp + nType+j] :=  RawData[nWidth*i*3+j*3+1];    // G
          RawBgrData[nTemp + nType*2 +j] :=  RawData[nWidth*i*3+j*3+2]; // R
        end
        else begin
          RawBgrData[nTemp+j] :=  0;            // B
          RawBgrData[nTemp + nType+j] :=  0;    // G
          RawBgrData[nTemp + nType*2 +j] :=  0; // R
        end;
      end;
    end;
  end
  else begin
    nType := 4096;
    SetLength(RawData,   (nHeight*nWidth*3));
    SetLength(RawBgrData,(nType*3*nHeight));
    for i := 0 to Pred(nHeight) do begin
      CopyMemory(@RawData[i*nWidth*3],Image_Pat1.Picture.Bitmap.ScanLine[i],nWidth*3);
//			CopyMemory(@RawData[i*2048*3],Image_Pat1.Picture.Bitmap.ScanLine[i],2048*3);
//			CopyMemory(@RawData[i*2049*3],Image_Pat1.Picture.Bitmap.ScanLine[i],2048*3);
    end;
    for i := 0 to Pred(nHeight) do begin
      nTemp := i*nType*3;
      for j := 0 to Pred(nType) do begin
        if nWidth > j then begin
          RawBgrData[nTemp+j] :=  RawData[nWidth*i*3+j*3];              // B
          RawBgrData[nTemp + nType+j] :=  RawData[nWidth*i*3+j*3+1];    // G
          RawBgrData[nTemp + nType*2 +j] :=  RawData[nWidth*i*3+j*3+2]; // R
        end
        else begin
          RawBgrData[nTemp+j] :=  0;            // B
          RawBgrData[nTemp + nType+j] :=  0;    // G
          RawBgrData[nTemp + nType*2 +j] :=  0; // R
        end;
      end;
    end;
  end;
end;

procedure TfrmFileTrans.RefreshScreen;
begin
  tcDownTypeChange(nil);
end;

procedure TfrmFileTrans.SaveRawFile(fName: String);
var
  fi : TFileStream;
  saveFName : String;
begin
  saveFName := sCurrPath + StringReplace(fName,'.bmp','.raw', [rfReplaceAll, rfIgnoreCase]);
//	saveFName := StringReplace(fName,'.bmp','.raw', [rfReplaceAll, rfIgnoreCase]);
  if FileExists(saveFname) then
    fi := TFileStream.Create(saveFName, fmOpenWrite or fmShareDenyNone)
  else
    fi := TFileStream.Create(saveFName, fmCreate);
  try
    if Image_Pat1.Picture.Bitmap.Width <= 2048 then begin
      fi.WriteBuffer(RawBgrData[0],Image_Pat1.Picture.Bitmap.Height*2048*3)
    end
    else begin
      fi.WriteBuffer(RawBgrData[0],Image_Pat1.Picture.Bitmap.Height*4096*3)
    end;
  finally
    fi.Free;
  end;
end;

// bSet : True - Set Enable, False - Disable.
procedure TfrmFileTrans.SetDownLoadEnd(bSet : Boolean);
begin
  tcDownType.Enabled     := bSet;
  pnlListCtrl.Enabled    := bSet;
  grpDownStatus.Enabled  := bSet;
  btnClose.Enabled       := bSet;
end;

procedure TfrmFileTrans.StartDataDownload(nPgNo, nSendDataCnt: Integer;const fileTransRec: TArray<TFileTranStr>);
begin
  if Pg[nPgNo].Status = pgDisconnect then begin
    unLockGui(nPgNo);
    Exit;
  end;
//  nMode := fileTransRec[0].TransMode;
  ThreadTask(procedure begin
    Pg[nPgNo].m_hTrans  := Self.Handle;
    PG[nPgNo].SendTransData(nSendDataCnt,fileTransRec);
  end);
end;

procedure TfrmFileTrans.tcDownTypeChange(Sender: TObject);
var
  Rslt      : Integer;
  sFindFile : String;
  sr : TSearchrec;
begin
  sFindFile := '';
  grpBMPResolution.Visible := False;

  case tcDownType.TabIndex of
    DOWNLOAD_TYPE_BMP :
    begin
      sCurrPath := Common.Path.BMP;
      sFindFile := Common.Path.BMP + '*.bmp';
      grpBMPResolution.Visible := True;
    end;
    DOWNLOAD_TYPE_PRG :
    begin
      sCurrPath := Common.Path.ModelCode;
      sFindFile := Common.Path.ModelCode + '*.*prg*';
    end;
    DOWNLOAD_TYPE_PG_FPGA :
    begin
      sCurrPath := Common.Path.PG_FPGA;
      sFindFile := Common.Path.PG_FPGA + '*.rbf';
    end;
    DOWNLOAD_TYPE_PG_FW :
    begin
      sCurrPath := Common.Path.PG_FW;
      sFindFile := Common.Path.PG_FW + '*.bin';
    end;
    DOWNLOAD_TYPE_PALLET_FPGA :
    begin
//			sCurrPath := Pallet_FpgaFilePath;
//			sFindFile := Pallet_FpgaFilePath + '*.rbf';
    end;
    DOWNLOAD_TYPE_PALLET_FW :
    begin
//			sCurrPath := Common.Path.IF_FW;
//			sFindFile := Common.Path.IF_FW + '*.*';
    end;
    DOWNLOAD_TYPE_TOUCH_FW :
    begin
      sCurrPath := Common.Path.TOUCH_FW;
      sFindFile := Common.Path.TOUCH_FW + '*.img';
    end;
  end;

  lstPCFileList.Clear;
  lstPCFileList.Sorted := False;

  Rslt := FindFirst(sFindFile, faAnyFile, sr);
  while Rslt = 0 do begin   // Pattern Folder에서 Pattern Name을 검색하여 ComboBox 에 삽입
    if Length(sr.Name) > 4 then
      lstPCFileList.Items.Add(sr.Name);      // ComboBox에 Pattern Name 추가

    Rslt := FindNext(sr);
  end;
  FindClose(sr);

  lstPCFileList.ItemIndex := -1;
end;

procedure TfrmFileTrans.ThreadTask(task: TProc);
var
  th1 : TThread;
begin
  th1 := TThread.CreateAnonymousThread(Task);
  th1.FreeOnTerminate := True;
  th1.Start;
//  Parallel.Async( procedure begin
//      task;
//    end,
//    Parallel.TaskConfig.OnTerminated(
//      procedure (const task: IOmniTaskControl)
//      begin
//      end
//    )
//  );
end;

procedure TfrmFileTrans.unLockGui(nPg : Integer);
var
  i : Integer;
  bLockUi : Boolean;
begin
  m_bLockUI[nPg] := False;
  bLockUi := False;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if m_bLockUI[i] then bLockUi := True;
  end;
  if not bLockUi then begin
    SetDownLoadEnd(True);
  end;
end;

procedure TfrmFileTrans.WMCopyData(var Msg: TMessage);
var
  nType, nPg, nMode : Integer;
  nTotal, nCur : Integer;
  sMessage : string;
  bIsDone : boolean;
begin
  nType := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nPg   := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.PgNo;
  case nType of
    DefCommon.MSG_TYPE_PG : begin
      nMode := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS : begin
          nTotal  := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Total;
          nCur    := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.CurPos;
          sMessage := string(PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg);
          bIsDone := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.IsDone;
          gridPGList.Cells[3,nPg+1] := sMessage;
          gridPGList.Ints[2,nPg+1] := (nCur * 100) div nTotal;

          if bIsDone then begin
            unLockGui(nPg);
          end;
        end;
      end;

    end;
  end;

end;

end.
