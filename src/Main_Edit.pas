unit Main_Edit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, AdvOfficePager, AdvOfficePagerStylers, Vcl.StdCtrls, Vcl.ComCtrls,
  RzButton, RzCmboBx, RzLstBox, Vcl.Mask, RzEdit, RzPanel, Vcl.Dialogs, CommonClass, ScrMemo, ScrMps, AdvMemo,
  AdvmPS, OutlookGroupedList, AdvToolBar, AdvToolBarExt, AdvMemoToolBar, AdvOutlookList, DefScript, ScriptClass,
  atScript, atScripter, IDEMain, Vcl.ScripterInit, AdvUtil, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, DefCommon, RzStatus;

type
  TfrmMain_Edit = class(TForm)
    pnlModelNameInfo: TPanel;
    AdvIspdEditor: TAdvOfficePager;
    AdvOfficePager11: TAdvOfficePage;
    AdvOfficePager12: TAdvOfficePage;
    AdvOfficePager13: TAdvOfficePage;
    AdvOfficePagerOfficeStyler1: TAdvOfficePagerOfficeStyler;
    AdvOfficePage1: TAdvOfficePage;
    pnl2: TPanel;
    AdvOfficePage2: TAdvOfficePage;
    pnl3: TPanel;
    RzBitBtn1: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    btnSaveAll: TRzBitBtn;
    redt1: TRichEdit;
    grp1: TRzGroupBox;
    grp3: TRzGroupBox;
    lstModel: TRzListBox;
    pnl4: TPanel;
    grp2: TRzGroupBox;
    edModelName: TRzEdit;
    RzGroupBox4: TRzGroupBox;
    cboModelType: TRzComboBox;
    btnModelDelScript: TRzBitBtn;
    btnModelRenameScript: TRzBitBtn;
    btnModelCopyScript: TRzBitBtn;
    btnModelNewScript: TRzBitBtn;
    pnl5: TPanel;
    pnl6: TPanel;
    pnl7: TPanel;
    pnl8: TPanel;
    pnl9: TPanel;
    pnl10: TPanel;
    ScrPascalMemoStyler2: TScrPascalMemoStyler;
    AdvPascalMemoStyler1: TAdvPascalMemoStyler;
    mmProgramAll: TAdvMemo;
    AdvMemoClipboardRibbonToolBar1: TAdvMemoClipboardRibbonToolBar;
    ScrMemoFindDialog1: TScrMemoFindDialog;
    IDEMemo1: TIDEMemo;
    IDEEngine1: TIDEEngine;
    IDEScripter1: TIDEScripter;
    pnl11: TPanel;
    RzBitBtn5: TRzBitBtn;
    btnFinder: TRzBitBtn;
    edFinder: TEdit;
    lstGrpFinder: TAdvOutlookList;
    pnl12: TPanel;
    pnl13: TPanel;
    grdCsvViewer: TAdvStringGrid;
    pnlCsvName: TPanel;
    cbb1: TComboBox;
    btnCsvSave: TRzBitBtn;
    pnlCsvPath: TPanel;
    lblPath: TLabel;
    AdvOfficePage3: TAdvOfficePage;
    AdvOfficePage4: TAdvOfficePage;
    AdvIsuPage: TAdvOfficePager;
    advPageIsuCompile: TAdvOfficePage;
    AdvIsuPageFind: TAdvOfficePage;
    pnl1: TPanel;
    btnCompileScript: TRzBitBtn;
    btn1: TRzBitBtn;
    btn2: TRzBitBtn;
    pnl14: TPanel;
    RzBitBtn3: TRzBitBtn;
    btnIsuFind: TRzBitBtn;
    edIsuFinder: TEdit;
    lstGrpCompile: TAdvOutlookList;
    lstIsuGrpFinder: TAdvOutlookList;
    RzStatusBar1: TRzStatusBar;
    RzClockStatus1: TRzClockStatus;
    RzKeyStatus1: TRzKeyStatus;
    RzKeyStatus2: TRzKeyStatus;
    RzKeyStatus3: TRzKeyStatus;
    RzResourceStatus1: TRzResourceStatus;
    pnlStatusIpInfo: TRzStatusPane;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure cboModelTypeClick(Sender: TObject);
    procedure lstModelClick(Sender: TObject);
    procedure btnCompileScriptClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure IDEMemo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnFinderClick(Sender: TObject);
    procedure RzBitBtn5Click(Sender: TObject);
    procedure lstGrpFinderItemClick(Sender: TObject; Item: POGLItem; Column: Integer);
    procedure RzBitBtn1Click(Sender: TObject);
    procedure cbb1Change(Sender: TObject);
    procedure edFinderEnter(Sender: TObject);
    procedure btnCsvSaveClick(Sender: TObject);
    procedure btnModelNewScriptClick(Sender: TObject);
    procedure btnModelRenameScriptClick(Sender: TObject);
    procedure btnModelCopyScriptClick(Sender: TObject);
    procedure btnModelDelScriptClick(Sender: TObject);
    procedure mmProgramAllKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edIsuFinderEnter(Sender: TObject);
    procedure btnIsuFindClick(Sender: TObject);
    procedure lstIsuGrpFinderItemClick(Sender: TObject; Item: POGLItem; Column: Integer);
    procedure RzBitBtn3Click(Sender: TObject);
    procedure btnSaveAllClick(Sender: TObject);
  private
    { Private declarations }
    g_bNewModel, g_bCopyModel, g_bRenModel   : Boolean;

    procedure SetModelType;
    procedure Load_Model(nIdx : Integer);
    procedure FindItemToListbox(tList: TRzListbox; sItem: string);
    procedure Display_Script_data(sModelname : string);
    function CheckSyntex(lstResource : TStringList; nOriNumbers : array of Integer) : Integer;
    procedure SetCurMemoLine(Memo : TIDEMemo; Value : integer);
    procedure SetCurMemoLineAdv(Memo : TAdvMemo; Value : integer);
    procedure CheckAndCopyModelData(oldName, newName : String);
    procedure CheckAndDeleteModelData(fName : String);
    procedure RemoveDirAll(sDir : string);
    procedure AddAndFindItemToListbox(tList: TRzListbox; sItem: string; bAdd, bFind: Boolean);
    procedure ComipleIsu;
    procedure DisplayCsvData(sModelname: string;nIdx : Integer);

  public
    { Public declarations }
  end;

var
  frmMain_Edit: TfrmMain_Edit;

implementation

{$R *.dfm}

procedure TfrmMain_Edit.AddAndFindItemToListbox(tList: TRzListbox; sItem: string; bAdd, bFind: Boolean);
var
  i : Integer;
begin
  if bAdd then begin
    tList.Sorted := False;
    tList.Items.Add(sItem);
    tList.Sorted := True;
  end;

  if bFind then begin
    if sItem = '' then begin
      tList.ItemIndex := 0;
    end
    else begin
      for i := 0 to tList.Items.Count - 1 do begin
        if tList.Items.Strings[i] = sItem then begin
          tList.ItemIndex := i;
          Break;
        end;
      end;
    end;
  end;
end;

procedure TfrmMain_Edit.btn1Click(Sender: TObject);
var
  nGrpCnt, i : Integer;
begin
  nGrpCnt := lstGrpCompile.GroupCount;

  for i := 0 to Pred(nGrpCnt) do begin
    lstGrpCompile.Groups[i].Expanded := True;
  end;

end;

procedure TfrmMain_Edit.btn2Click(Sender: TObject);
var
  nGrpCnt, i : Integer;
begin
  nGrpCnt := lstGrpCompile.GroupCount;

  for i := 0 to Pred(nGrpCnt) do begin
    lstGrpCompile.Groups[i].Expanded := False;
  end;
end;

procedure TfrmMain_Edit.btnCompileScriptClick(Sender: TObject);
begin
  ComipleIsu;
end;

procedure TfrmMain_Edit.btnCsvSaveClick(Sender: TObject);
var
  sFileName : string;
begin
  sFileName := Common.Path.MODEL_CUR+ pnlModelNameInfo.Caption;
  //grdCsvViewer.ClearAll;
  case cbb1.ItemIndex of
    0 : sFileName := sFileName + '_oc_param.csv';
    1 : sFileName := sFileName + '_oc_verify.csv';
    2 : sFileName := sFileName + '_oc_offset.csv';
    3 : sFileName := sFileName + '_otp_table.csv'
    else begin
      Exit;
    end;
  end;
  grdCsvViewer.SaveToCSV(sFileName);
  ShowMessage('File Saved!');
  grdCsvViewer.LoadFromCSV(sFileName);
end;

procedure TfrmMain_Edit.btnFinderClick(Sender: TObject);
var
  sFind : string;
  i, GrpIdx     : Integer;
begin
  sFind := edFinder.Text;
  lstGrpFinder.CollapseAll;
  if lstGrpFinder.GroupCount = 0 then begin
    lstGrpFinder.AddGroup(sFind);
    GrpIdx := 0;
  end
  else begin
    GrpIdx := -1;
    for i := 0 to Pred(lstGrpFinder.GroupCount) do begin
      if lstGrpFinder.Groups[i].Caption = sFind then begin
        GrpIdx := i;
        lstGrpFinder.DeleteGroup(i);
        Break;
      end;
      if GrpIdx = -1 then begin
        lstGrpFinder.AddGroup(sFind);
        GrpIdx := Pred(lstGrpFinder.GroupCount);
      end;
    end;
  end;

  for i := 0 to Pred(IDEMemo1.Lines.Count) do begin
    if Pos(sFind,IDEMemo1.Lines[i]) <> 0 then begin
      with lstGrpFinder.AddItem(lstGrpFinder.Groups[GrpIdx]) do begin
        Add(Format('%d',[i])); Add(IDEMemo1.Lines[i]);
      end;
    end;
  end;
end;

procedure TfrmMain_Edit.btnIsuFindClick(Sender: TObject);
var
  sFind : string;
  i, GrpIdx     : Integer;
begin
  sFind := edIsuFinder.Text;
  lstIsuGrpFinder.CollapseAll;
  if lstIsuGrpFinder.GroupCount = 0 then begin
    lstIsuGrpFinder.AddGroup(sFind);
    GrpIdx := 0;
  end
  else begin
    GrpIdx := -1;
    for i := 0 to Pred(lstIsuGrpFinder.GroupCount) do begin
      if lstIsuGrpFinder.Groups[i].Caption = sFind then begin
        GrpIdx := i;
        lstIsuGrpFinder.DeleteGroup(i);
        Break;
      end;
      if GrpIdx = -1 then begin
        lstIsuGrpFinder.AddGroup(sFind);
        GrpIdx := Pred(lstIsuGrpFinder.GroupCount);
      end;
    end;
  end;

  for i := 0 to Pred(mmProgramAll.Lines.Count) do begin
    if Pos(sFind,mmProgramAll.Lines[i]) <> 0 then begin
      with lstIsuGrpFinder.AddItem(lstIsuGrpFinder.Groups[GrpIdx]) do begin
        Add(Format('%d',[i])); Add(mmProgramAll.Lines[i]);
      end;
    end;
  end;
end;

procedure TfrmMain_Edit.btnModelCopyScriptClick(Sender: TObject);
begin
  edModelName.ReadOnly := False;
  edModelName.SelectAll;
  edModelName.SetFocus;
  g_bCopyModel := True;
end;

procedure TfrmMain_Edit.btnModelDelScriptClick(Sender: TObject);
var
  idx : Integer;
begin
  if lstModel.ItemIndex < 0 then Exit;

  if MessageDlg(#13#10 + 'Are you sure to DELETE this Model?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
//		LBox_Model.ItemIndex := lstModel.ItemIndex;
    idx := lstModel.ItemIndex;
    if idx > -1 then begin
      //DeleteFile(Common.GetFilePath(lstModel.Items.Strings[idx], DefCommon.MODEL_PATH));
      CheckAndDeleteModelData(lstModel.Items.Strings[idx]);
      lstModel.Items.Delete(idx);
      lstModel.ItemIndex := idx - 1;
      if (lstModel.ItemIndex = -1) and (lstModel.Items.Count > 0) then  lstModel.ItemIndex := 0;
      lstModelClick(nil);
    end;
  end;
end;

procedure TfrmMain_Edit.btnModelNewScriptClick(Sender: TObject);
begin
  edModelName.ReadOnly := False;
  edModelName.Text := '';
  edModelName.SetFocus;
  g_bNewModel := True;
end;

procedure TfrmMain_Edit.btnModelRenameScriptClick(Sender: TObject);
begin
  edModelName.ReadOnly := False;
  edModelName.SelectAll;
  edModelName.SetFocus;
  g_bRenModel := True;
end;

procedure TfrmMain_Edit.btnSaveAllClick(Sender: TObject);
var
  i	: Integer;
  sOldName, sNewName : String;
begin
  if AdvIspdEditor.ActivePageIndex <> 0 then AdvIspdEditor.ActivePageIndex := 0;

  if edModelName.Text = '' then begin
    MessageDlg(#13#10 + 'Input Error! Please Insert the Model name.', mtError, [mbOK], 0);
    if True then

    edModelName.SetFocus;
    Exit;
  end;

  if (not g_bRenModel) and (not g_bCopyModel) then begin
    Common.Path.ModelCode := Common.Path.MODEL_CUR + 'compiled\';
    if not DirectoryExists(Common.Path.ModelCode) then begin
       MessageDlg(#13#10 + 'Input Error! Must compile it first', mtError, [mbOK], 0);
      edModelName.SetFocus;

      Exit;
    end;
  end;

  if g_bNewModel or g_bRenModel or g_bCopyModel then begin
//		if FileExists(CmmYT.GetFilePath(Trim(Edit_ModelName.Text), MODEL_PATH)) then begin
    if FileExists(Common.GetFilePath(Trim(edModelName.Text), MODEL_PATH)) then begin
//			MessageDlg(#13#10 + 'Input Error! Model Name [' + Trim(Edit_ModelName.Text) + '] is already Exist!', mtError, [mbOk], 0);
      MessageDlg(#13#10 + 'Input Error! Model Name [' + Trim(edModelName.Text) + '] is already Exist!', mtError, [mbOk], 0);
      edModelName.SelectAll;
      edModelName.SetFocus;

      Exit;
    end;

    if g_bCopyModel or g_bRenModel then begin   // 새로운 Model일 경우 List에 추가한다.
    // COPY MODEL일 경우 prg 파일도 같?? 변경하도록 요구함 (BOE)
      sOldName := lstModel.Items.Strings[lstModel.ItemIndex];
      sNewName := Trim(edModelName.Text);
      // 리스트에 동일한 내용이 있으면 저장 하지 말자.
      for i := 0 to Pred(lstModel.Items.Count) do begin
        if lstModel.Items.Strings[i] = sNewName then begin
          MessageDlg(#13#10 + 'Input Error! Model Name [' + Trim(edModelName.Text) + '] is already Exist!', mtError, [mbOk], 0);
          Exit;
        end;
      end;
      CheckAndCopyModelData(sOldName,sNewName);
      if g_bRenModel then CheckAndDeleteModelData(sOldName);

      if g_bNewModel or g_bCopyModel then begin   // 새로운 Model일 경우 List에 추가한다.
        AddAndFindItemToListbox(lstModel, edModelName.text, True, True);
      end;
      Common.Path.MODEL_CUR := Common.Path.MODEL + sNewName + '\';
      if g_bRenModel then begin
        lstModel.Sorted := False;
        lstModel.Items.Strings[lstModel.ItemIndex] := sNewName;
        lstModel.Sorted := True;
        AddAndFindItemToListbox(lstModel, sNewName, False, True);
      end;
      IDEMemo1.Lines.SaveToFile(Common.Path.MODEL_CUR + (Trim(edModelName.Text))+'.psu');
    end;
    ComipleIsu;
    lstModelClick(nil);


  end;
  Common.SystemInfo.TestModel := edModelName.Text;
  Common.SaveModelInfo(Trim(edModelName.Text));
  Common.SaveSystemInfo;
  Script.LoadScript(Common.Path.MODEL_CUR + (Trim(edModelName.Text))+'.isu');
  btnCompileScriptClick(Self);

  MessageDlg(#13#10 + 'Model Information File Saving OK!', mtInformation, [mbOk], 0);
end;

procedure TfrmMain_Edit.cbb1Change(Sender: TObject);
begin
  DisplayCsvData(lstModel.Items[lstModel.ItemIndex],cbb1.ItemIndex);
end;

procedure TfrmMain_Edit.cboModelTypeClick(Sender: TObject);
begin
  Load_Model(cboModelType.ItemIndex);
end;

procedure TfrmMain_Edit.CheckAndCopyModelData(oldName, newName: String);
var
  sNewModeDir, sOldModeDir, sNewCompiled, sOldCompiled : string;
begin

  sNewModeDir := Common.Path.MODEL + newName + '\';
  sOldModeDir := Common.Path.MODEL + oldName + '\';
  Common.CheckDir(sNewModeDir);

  sNewCompiled := sNewModeDir + 'compiled\';
  sOldCompiled := sOldModeDir + 'compiled\';
  Common.CheckDir(sNewCompiled);

  if FileExists(sOldModeDir + oldName + '.mcf') then
    CopyFile(PChar(sOldModeDir + oldName + '.mcf'), PChar(sNewModeDir + newName + '.mcf'), False);

  if FileExists(sOldModeDir + oldName + '.isu') then
    CopyFile(PChar(sOldModeDir + oldName + '.isu'), PChar(sNewModeDir + newName + '.isu'), False);

  if FileExists(sOldModeDir + oldName + '.psu') then
    CopyFile(PChar(sOldModeDir + oldName + '.psu'), PChar(sNewModeDir + newName + '.psu'), False);

  if FileExists(sOldModeDir + oldName + '_oc_param.csv') then
    CopyFile(PChar(sOldModeDir + oldName + '_oc_param.csv'), PChar(sNewModeDir + newName + '_oc_param.csv'), False);

  if FileExists(sOldModeDir + oldName + '_oc_verify.csv') then
    CopyFile(PChar(sOldModeDir + oldName + '_oc_verify.csv'), PChar(sNewModeDir + newName + '_oc_verify.csv'), False);

  if FileExists(sOldModeDir + oldName + '_oc_offset.csv') then
    CopyFile(PChar(sOldModeDir + oldName + '_oc_offset.csv'), PChar(sNewModeDir + newName + '_oc_offset.csv'), False);

  if FileExists(sOldModeDir + oldName + '_otp_table.csv') then
    CopyFile(PChar(sOldModeDir + oldName + '_otp_table.csv'), PChar(sNewModeDir + newName + '_otp_table.csv'), False);


  if FileExists(sOldCompiled + oldName + '.miau') then
    CopyFile(PChar(sOldCompiled + oldName + '.miau'), PChar(sNewCompiled + newName + '.miau'), False);

  if FileExists(sOldCompiled + oldName + '.mioff') then
    CopyFile(PChar(sOldCompiled + oldName + '.mioff'), PChar(sNewCompiled + newName + '.mioff'), False);

  if FileExists(sOldCompiled + oldName + '.mion') then
    CopyFile(PChar(sOldCompiled + oldName + '.mion'), PChar(sNewCompiled + newName + '.mion'), False);

  if FileExists(sOldCompiled + oldName + '.mtp') then
    CopyFile(PChar(sOldCompiled + oldName + '.mtp'), PChar(sNewCompiled + newName + '.mtp'), False);

  if FileExists(sOldCompiled + oldName + '.otpr') then
    CopyFile(PChar(sOldCompiled + oldName + '.otpr'), PChar(sNewCompiled + newName + '.otpr'), False);

  if FileExists(sOldCompiled + oldName + '.otpw') then
    CopyFile(PChar(sOldCompiled + oldName + '.otpw'), PChar(sNewCompiled + newName + '.otpw'), False);

  if FileExists(sOldCompiled + oldName + '.pwoff') then
    CopyFile(PChar(sOldCompiled + oldName + '.pwoff'), PChar(sNewCompiled + newName + '.pwoff'), False);

  if FileExists(sOldCompiled + oldName + '.pwon') then
    CopyFile(PChar(sOldCompiled + oldName + '.pwon'), PChar(sNewCompiled + newName + '.pwon'), False);

  if FileExists(sOldCompiled + oldName + '.misc') then
    CopyFile(PChar(sOldCompiled + oldName + '.misc'), PChar(sNewCompiled + newName + '.misc'), False);
end;

procedure TfrmMain_Edit.CheckAndDeleteModelData(fName: String);
var
  sDirPath : string;
begin
  sDirPath := Common.Path.MODEL + fName;// + '\';
  RemoveDirAll( sDirPath );
end;

function TfrmMain_Edit.CheckSyntex(lstResource: TStringList; nOriNumbers: array of Integer): Integer;
var
  i, nRet, nFinalRet  : Integer;
  sData, sGrpName     : string;
  sCmd                : string;
  nStartSeq           : Integer;
  bGroupNg            : Boolean;
  slTemp              : TStringList;
begin
  lstGrpCompile.ClearGroups;

  // function 내에 들어 가지 않으면 우선 0으로 Set.
  nStartSeq := 0;
  lstGrpCompile.AddGroup('function Checking.');

  bGroupNg := False;
  nFinalRet :=  DefScript.ERR_ST_NONE;
  // 라인별로 잘못된 부분이 있는지 확인.
  for i := 0 to Pred(lstResource.Count) do begin
    sData := Trim(lstResource.Strings[i]);
    if sData = '' then Continue;

    nRet := DefScript.ERR_ST_NONE;
    // Default Start Seq ID : function Checking.
    if nStartSeq = 0 then begin
      // nStart Seq 변경을 위한 시작 단계.
      if Pos(DefScript.FUNC_CALL_START,sData) <> 0 then begin
        sGrpName := StringReplace(sData,DefScript.FUNC_CALL_START,'',[rfReplaceAll]);
        sGrpName := Trim(StringReplace(sGrpName,'()','',[rfReplaceAll]));
        Inc(nStartSeq);
        lstGrpCompile.AddGroup(sGrpName);
        if not bGroupNg then lstGrpCompile.Groups[0].Expanded := False;
        bGroupNg := False;
      end;
    end
    else begin
        if Pos(DefScript.end_func,sData) <> 0 then begin
          nStartSeq := 0; // Function 종료.
          if not bGroupNg then lstGrpCompile.Groups[lstGrpCompile.GroupCount-1].Expanded := False;
          bGroupNg := False;
        end
        else if Pos('{',sData) <> 0 then begin
          continue;
        end
        else begin
          slTemp := TStringList.Create;
          try
            ExtractStrings([' '],[],PChar(sData),slTemp);

            if slTemp.Count < 1 then begin
              nRet :=  DefScript.ERR_ST_SEME;
            end
            else begin
              sCmd := Trim(slTemp.Strings[0]);
              if sCmd = DefScript.CMD_ITEM_1 then  begin

              end
              else if sCmd = DefScript.CMD_ITEM_2 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_3 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_4 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_5 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_6 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_7 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_8 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_9 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_10 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_11 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_12 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_13 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_14 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_15 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_16 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_17 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_18 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_19 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_20 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_21 then begin

              end

              else if sCmd = DefScript.CMD_ITEM_22 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_23 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_24 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_25 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_26 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_27 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_28 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_29 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_30 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_31 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_32 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_33 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_34 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_35 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_36 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_37 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_38 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_39 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_40 then begin

              end
              else begin
                nRet :=  DefScript.ERR_ST_SEME;
              end;
              if nRet <> DefScript.ERR_ST_SEME then begin
                with lstGrpCompile.AddItem(lstGrpCompile.Groups[lstGrpCompile.GroupCount-1]) do begin
                  Add(Format('%d',[nOriNumbers[i]+1])); Add(sData);
                end;
              end;
            end;
          finally
            slTemp.Free;
          end;
        end;

    end;
    if nRet <> DefScript.ERR_ST_NONE then begin
      // Script NG 발생시 오류 처리.
      mmProgramAll.TopLine      := nOriNumbers[i];
      mmProgramAll.BreakPoint[nOriNumbers[i]] := True;
      bGroupNg := True;
      nFinalRet := nRet;
//    lstGrpCompile.Groups[lstGrpCompile.GroupCount-1].Expanded := True;
    end
    else begin

    end;
  end;
  Result := nFinalRet;
end;

procedure TfrmMain_Edit.ComipleIsu;
var
  i, nCmt, nOriCnt  : Integer;
  sData     : string;
  sltData : TStringList;
  anOriNum  : array of integer;
begin
  sltData := TStringList.Create; // for data list except commant.
  try
    SetLength(anOriNum,SizeOf(Integer) * mmProgramAll.Lines.Count);
    nOriCnt := 0;
    // sltData에 주석을 제외한 데이터 입력 하자.
    for i := 0 to Pred(mmProgramAll.Lines.Count) do begin
      nCmt := Pos('//',mmProgramAll.Lines[i]); // 주석의 시작 위치 찾기.
      mmProgramAll.BreakPoint[i] := False;
      if nCmt <> 0 then begin
        sData := Trim(Copy(mmProgramAll.Lines.Strings[i],1,nCmt-1));
      end
      else begin
        sData := Trim(mmProgramAll.Lines.Strings[i]);
      end;
      if sData = '' then Continue;
      sltData.Add(sData);
      anOriNum[nOriCnt] := i;
      Inc(nOriCnt);
    end;
    // 구문 체크.
    if CheckSyntex(sltData,anOriNum) = DefScript.ERR_ST_NONE then begin
      Script.AnalizeScriptForCode(Trim(edModelName.Text),sltData);
    end;
    mmProgramAll.Lines.SaveToFile(Common.Path.MODEL_CUR+trim(edModelName.Text)+'.isu');
    Common.m_bIsChanged := True;
  finally
    sltData.Free;
  end;
end;

procedure TfrmMain_Edit.DisplayCsvData(sModelname: string;nIdx: Integer);
var
  sFileName : string;
begin
  sFileName := Common.Path.MODEL_CUR+ sModelname;
  grdCsvViewer.ClearAll;
  case nIdx of
    0 : sFileName := sFileName + '_oc_param.csv';
    1 : sFileName := sFileName + '_oc_verify.csv';
    2 : sFileName := sFileName + '_oc_offset.csv';
    3 : sFileName := sFileName + '_otp_table.csv';
  end;
  if FileExists(sFileName) then begin
    grdCsvViewer.LoadFromCSV(sFileName);
    grdCsvViewer.AutoSize := True;
    pnlCsvName.Caption := ExtractFileName(sFileName) ;
    lblPath.Caption    := ExtractFilePath(sFileName);
  end;
end;

procedure TfrmMain_Edit.Display_Script_data(sModelname: string);
var
  FileName : string;
begin

  edModelName.Text := sModelname;
  FileName := Common.Path.MODEL_CUR+sModelname+'.isu';

  mmProgramAll.Lines.Clear;
  if FileExists(FileName) then begin
    mmProgramAll.Lines.LoadFromFile(FileName);
  end;

//  scrPasMemo.Lines.Clear;
  FileName := Common.Path.MODEL_CUR + sModelname +'.psu';
  if FileExists(FileName) then begin
//    scrPasMemo.Lines.LoadFromFile(FileName);
    IDEMemo1.Lines.LoadFromFile(FileName);
    IDEScripter1.SourceCode.Clear;
    IDEScripter1.SourceCode.AddStrings(IDEMemo1.Lines);
  end;
end;

procedure TfrmMain_Edit.edFinderEnter(Sender: TObject);
begin
  btnFinder.Click;
end;

procedure TfrmMain_Edit.edIsuFinderEnter(Sender: TObject);
begin
  btnIsuFind.Click;
end;

procedure TfrmMain_Edit.FindItemToListbox(tList: TRzListbox; sItem: string);
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

procedure TfrmMain_Edit.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  sMsg, sDebug : string;
  i    : Integer;
begin
   sMsg := #13#10 + 'bạn có muốn thóat chương trình không?';
  sMsg := sMsg + #13#10 + '(Are you sure you want to Exit Program?)';
  if MessageDlg(sMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    if Script <> nil then begin
      Script.Free;
      Script := nil;
    end;

    if Common <> nil then begin
      Common.Free;
      Common := nil;
    end;
    CanClose := True;
  end
  else
    CanClose := False;
end;

procedure TfrmMain_Edit.FormCreate(Sender: TObject);
begin
  // Create....
  Common := TCommon.Create;
  Common.m_sUserId := 'PM';
  SetModelType;
  Load_Model(cboModelType.ItemIndex);
  pnlModelNameInfo.Caption := Common.SystemInfo.TestModel;
  Display_Script_data(Common.SystemInfo.TestModel);
  Common.LoadModelInfo(Common.SystemInfo.TestModel);
  DisplayCsvData(Common.SystemInfo.TestModel,0);
  g_bNewModel := False;
  g_bCopyModel:= False;
  g_bRenModel := False;

  // Grid Set.
  grdCsvViewer.Navigation.AllowClipboardAlways := True;
  grdCsvViewer.Navigation.AllowFmtClipboard := True;
  pnlStatusIpInfo.Caption := 'Local IP : '+Common.GetLocalIpList;;
  Script := TScript.Create(Common.Path.MODEL_CUR + Common.SystemInfo.TestModel + '.isu');
end;

procedure TfrmMain_Edit.IDEMemo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift = [ssCtrl] then begin
    if Key in [ord('F'),ord('f')] then begin
      //ScrMemoFindDialog1.Execute;
      edFinder.Text :=  IDEMemo1.Selection;
      edFinder.SetFocus;
    end;
  end;
end;

procedure TfrmMain_Edit.Load_Model(nIdx: Integer);
var
  nRstD    : Integer;
  srD      : TSearchrec;
  sModel, sModelType, sTarget  : string;
begin
  lstModel.Clear;
  lstModel.DisableAlign;

  sTarget := cboModelType.Items[nIdx];
  nRstD := FindFirst(Common.Path.MODEL+ '*.*',faDirectory, srD);
  while nRstD = 0 do begin
    if not ((Trim(srD.Name) = '.') or (Trim(srD.Name) = '..') or ( (srD.Attr and faDirectory) = 0)) then begin
//      lstModel.Items.Add(Copy(srD.Name, 1, pos('.', srD.Name) - 1));
      sModel  := srD.Name;
      if nIdx <> 0 then begin
        sModelType := Common.GetModelType(2,sModel);
        if sTarget = sModelType then lstModel.Items.Add(sModel);
      end
      else begin
        lstModel.Items.Add(sModel);
      end;
    end;
    nRstD := FindNext(srD);
  end;
  FindClose(srD);
  lstModel.Sorted := True;

  if lstModel.Items.Count > 0 then begin
    FindItemToListbox(lstModel, Common.SystemInfo.TestModel);
    edModelName.Text := Common.SystemInfo.TestModel;
  end;
  lstModel.EnableAlign;
end;

procedure TfrmMain_Edit.lstGrpFinderItemClick(Sender: TObject; Item: POGLItem; Column: Integer);
var
  sTemp : string;
  nMoveLine : Integer;
begin
//  sTemp := Format('Item %d / Column %d',[Item.Index, Column]);
  sTemp :=  lstGrpFinder.ItemGroup(Item).ChildItem[Item.Index].Strings[0];
  nMoveLine := StrToIntDef(sTemp,-1);
  if nMoveLine < 0 then Exit;
  SetCurMemoLine(IDEMemo1,nMoveLine);

end;

procedure TfrmMain_Edit.lstIsuGrpFinderItemClick(Sender: TObject; Item: POGLItem; Column: Integer);
var
  sTemp : string;
  nMoveLine : Integer;
begin
//  sTemp := Format('Item %d / Column %d',[Item.Index, Column]);
  sTemp :=  lstIsuGrpFinder.ItemGroup(Item).ChildItem[Item.Index].Strings[0];
  nMoveLine := StrToIntDef(sTemp,-1);
  if nMoveLine < 0 then Exit;
  SetCurMemoLineAdv(mmProgramAll,nMoveLine);
end;

procedure TfrmMain_Edit.lstModelClick(Sender: TObject);
var
  idx, i : Integer;
  sPtGrp : string;
begin
  edModelName.ReadOnly := True;
  g_bNewModel := False;
  g_bCopyModel:= False;
  g_bRenModel := False;

  idx := lstModel.ItemIndex;
  if idx > -1 then begin
    if Common.LoadModelInfo(lstModel.Items.Strings[idx]) then begin
      pnlModelNameInfo.Caption := lstModel.Items.Strings[idx];
      Display_Script_data(lstModel.Items.Strings[idx]);
      Common.LoadModelInfo(lstModel.Items.Strings[idx]);
    end;
  end;
end;

procedure TfrmMain_Edit.mmProgramAllKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift = [ssCtrl] then begin
    if Key in [ord('F'),ord('f')] then begin
      //ScrMemoFindDialog1.Execute;
//      AdvIsuFindPage.ActivePage;
      AdvIsuPage.ActivePageIndex := 1;
      edIsuFinder.Text :=  mmProgramAll.Selection;
      edIsuFinder.SetFocus;
    end;
  end;
end;

procedure TfrmMain_Edit.RemoveDirAll(sDir: string);
var
  tmpList : TSearchRec;
begin
  try
    if FindFirst(sDir + '\*',faAnyFile,tmpList) = 0 then begin
      repeat
        if ((tmpList.attr and faDirectory) = faDirectory) and (not (tmpList.Name = '.')) and (not (tmpList.Name = '..')) then begin
          if DirectoryExists(sDir + '\' + tmpList.Name) then begin
             RemoveDirAll(sDir + '\' + tmpList.Name);
          end;
        end
        else begin
          if FileExists(sDir + '\' + tmpList.Name) then begin
             DeleteFile(sDir + '\' + tmpList.Name);
          end;
        end;
      until FindNext(tmpList) <> 0;
    end;
    if DirectoryExists(sDir) then  RemoveDir(sDir);
  finally
    FindClose(tmpList);
  end;


end;

procedure TfrmMain_Edit.RzBitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain_Edit.RzBitBtn3Click(Sender: TObject);
begin
  lstIsuGrpFinder.ClearGroups;
end;

procedure TfrmMain_Edit.RzBitBtn5Click(Sender: TObject);
begin
  lstGrpFinder.ClearGroups;
end;

procedure TfrmMain_Edit.SetCurMemoLine(Memo: TIDEMemo; Value: integer);
begin
   if Value < 0 then Value := 0;
   if Value > Memo.Lines.Count then Value := Memo.Lines.Count;
   Memo.ActiveLine := Value;
//   Memo.SelLength := 1;
//   Memo.SelStart := Value;//Memo.Perform(EM_LINEINDEX, Value, 0);
end;

procedure TfrmMain_Edit.SetCurMemoLineAdv(Memo: TAdvMemo; Value: integer);
begin
   if Value < 0 then Value := 0;
   if Value > Memo.Lines.Count then Value := Memo.Lines.Count;
   Memo.ActiveLine := Value;

end;

procedure TfrmMain_Edit.SetModelType;
var
  srD       : TSearchrec;
  nRstD, i     : Integer;
  sModelType    : string;
  bCheck        : boolean;
begin
  cboModelType.Clear;
  cboModelType.Items.Add('ALL Model');

  nRstD := FindFirst(Common.Path.MODEL+ '*.*',faDirectory, srD);
  try
    while nRstD = 0 do begin
      if not ((Trim(srD.Name) = '.') or (Trim(srD.Name) = '..') or ( (srD.Attr and faDirectory) = 0)) then begin
  //      lstModel.Items.Add(Copy(srD.Name, 1, pos('.', srD.Name) - 1));
        sModelType :=  Common.GetModelType(2,srD.Name);
        if Trim(sModelType) <> '' then begin

          bCheck := True;
          for i := 1 to Pred(cboModelType.Items.Count) do begin
            if Trim(cboModelType.Items[i]) = sModelType  then begin
              bCheck := False;
              Break;
            end;
          end;
          // 중복되는 Type이 없으면 내용 추가 하자.
          if bCheck then cboModelType.Items.Add(sModelType);
        end;
      end;
      nRstD := FindNext(srD);
    end;
  finally
    FindClose(srD);
  end;
  sModelType := Common.GetModelType(2,Common.SystemInfo.TestModel);
  for i := 1 to Pred(cboModelType.Items.Count) do begin
    if cboModelType.Items[i] = sModelType then begin
      cboModelType.ItemIndex := i;
      Break;
    end;
  end;
end;

end.
