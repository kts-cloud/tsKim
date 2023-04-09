unit NGRatioForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, RzButton,
  Vcl.Grids, RzGrids, CommonClass, AdvUtil, AdvObj, BaseGrid, AdvGrid, Vcl.StdCtrls, RzCmboBx, Vcl.ComCtrls,
  Data.DB, DBModule, System.Math;

type
  TfrmNGRatio = class(TForm)
    Panel_Header: TRzPanel;
    RzPanel1: TRzPanel;
    grdList: TAdvStringGrid;
    RzPanel2: TRzPanel;
    dtpStart: TDateTimePicker;
    pnl1: TPanel;
    dtpEnd: TDateTimePicker;
    cboChannel: TRzComboBox;
    Btn_Export: TRzBitBtn;
    Btn_Close: TRzBitBtn;
    Btn_View: TRzBitBtn;
    Btn_Delete: TRzBitBtn;
    Btn_Today: TRzBitBtn;
    btnTest: TRzBitBtn;
    btnNext: TRzBitBtn;
    btnPrev: TRzBitBtn;
    procedure Btn_CloseClick(Sender: TObject);
    procedure Btn_ExportClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Btn_ViewClick(Sender: TObject);
    procedure Btn_DeleteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Btn_TodayClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
  private
    m_nFDCount : Integer;
    { Private declarations }
    procedure IntiGrid;
    procedure ViewGridQuery;
  public
    { Public declarations }
  end;

var
  frmNGRatio: TfrmNGRatio;

implementation

{$R *.dfm}

uses DefCommon;

procedure TfrmNGRatio.btnNextClick(Sender: TObject);
begin
  dtpStart.DateTime := dtpStart.DateTime + 1;
  dtpEnd.DateTime   := dtpEnd.DateTime + 1;

  ViewGridQuery;
end;

procedure TfrmNGRatio.btnPrevClick(Sender: TObject);
begin
  dtpStart.DateTime := dtpStart.DateTime - 1;
  dtpEnd.DateTime   := dtpEnd.DateTime - 1;

  ViewGridQuery;
end;

procedure TfrmNGRatio.btnTestClick(Sender: TObject);
var
  sQuery, sDate : String;
  i: Integer;
  nRnd: Integer;
begin
  sDate := formatdatetime('YYYYMMDD', now);
  Randomize;

  sQuery:= 'UPDATE TLB_ISPD SET CH1 = 100';
  for i := 2 to modDB.ChannelCount do begin
    nRnd:= Random(20);
    sQuery:= sQuery + format(', CH%d=%d', [i, nRnd]);
  end;
  sQuery:= sQuery +  Format(' WHERE NG_TYPE = 0 and (INSP_DATE = ''%s'');',[sDate]);
//  modDB.SendQueryExec(sQuery);

  sQuery:= 'UPDATE TLB_ISPD SET CH1 = 2';
  for i := 2 to modDB.ChannelCount do begin
    nRnd:= Random(20);
    sQuery:= sQuery + format(', CH%d=%d', [i, nRnd]);
  end;
  sQuery:= sQuery +  Format(' WHERE NG_TYPE = 2 and (INSP_DATE = ''%s'');',[sDate]);
//  modDB.SendQueryExec(sQuery);

  sQuery:= 'UPDATE TLB_ISPD SET CH1 = 3';
  for i := 2 to modDB.ChannelCount do begin
    nRnd:= Random(20);
    sQuery:= sQuery + format(', CH%d=%d', [i, nRnd]);
  end;
  sQuery:= sQuery +  Format(' WHERE NG_TYPE = 5 and (INSP_DATE = ''%s'');',[sDate]);

//  modDB.SendQueryExec(sQuery);
end;

procedure TfrmNGRatio.Btn_CloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmNGRatio.Btn_DeleteClick(Sender: TObject);
var
  sQuery : String;
  sStartDate, sEndDate: string;
begin
  if Application.MessageBox('Do you want to Clear Data?', 'Confirm', MB_YESNO + MB_ICONQUESTION) = IDNO then begin
    Exit;
  end;

  sStartDate := FormatDateTime('YYYYMMDD', dtpStart.DateTime);
  sEndDate := FormatDateTime('YYYYMMDD', dtpEnd.DateTime);

  // UPDATE
  if cboChannel.ItemIndex = 0 then begin  // ALL CH Clear
    sQuery:= 'DELETE FROM TLB_ISPD ';
  end
  else begin
    sQuery := Format('UPDATE TLB_ISPD SET CH%d = 0 ',[cboChannel.ItemIndex]);
    //DELETE FROM TLB_ISPD WHERE CH1 AND INSP_DATE = '20210113';
  end;

  sQuery := sQuery + Format(' WHERE INSP_DATE BETWEEN ''%s'' AND ''%s'' ;',[sStartDate,sEndDate]);

//  modDB.SendQueryExec(sQuery);

  ViewGridQuery;
end;

procedure TfrmNGRatio.Btn_ExportClick(Sender: TObject);
var
  sTemp, sPath : String;
begin
  sTemp := FormatDateTime('YYYYMMDD',now);
  sPath := Common.Path.LOG + 'NGRatio_' + sTemp +'.csv';
  grdList.SaveToCSV(sPath);
  ShowMessage('CSV Save OK ( '+ sPath + ' )');
end;

procedure TfrmNGRatio.Btn_TodayClick(Sender: TObject);
begin
  dtpStart.DateTime := now;
  dtpEnd.DateTime   := now;

  ViewGridQuery;
end;

procedure TfrmNGRatio.Btn_ViewClick(Sender: TObject);
begin
  ViewGridQuery;
end;

procedure TfrmNGRatio.FormCreate(Sender: TObject);
var
  i : Integer;
begin
  dtpStart.DateTime := now;
  dtpEnd.DateTime   := now;

  m_nFDCount := Length(Common.GmesInfo);

  cboChannel.Items.Clear;
  cboChannel.Items.Add('ALL');
  for i := 1 to modDB.ChannelCount do begin
    cboChannel.Items.Add('CH' + IntToStr(i));
  end;
  cboChannel.ItemIndex:= 0;

  IntiGrid;
end;

procedure TfrmNGRatio.FormShow(Sender: TObject);
begin
  ViewGridQuery;
end;

procedure TfrmNGRatio.IntiGrid;
var
  i, k : Integer;
begin
  grdList.ColCount := modDB.ChannelCount + 2;
  grdList.RowCount := m_nFDCount + 3;
//  Height:= grdList.Top + (grdList.RowCount * (grdList.DefaultRowHeight+2));
  Height := 1024;
  if Height > 1024 then Height:= 1024;

  grdList.ClearAll;

  grdList.ColWidths[0]:= 250;
  for i := 1 to modDB.ChannelCount+1 do begin
    grdList.ColWidths[i] := floor((grdList.Width - 250 - 16 - (2*modDB.ChannelCount))/(modDB.ChannelCount+1));
    for k := 1 to m_nFDCount+2 do grdList.Alignments[i, k]:= taRightJustify;
  end;

  grdList.Cells[0, 1] :=  '00: OK';
  for i := 1 to m_nFDCount - 1 do begin
    grdList.Cells[0, i+1] := format('%0.2d: %s', [i, Common.GmesInfo[i].sErrMsg]);; //Common.GmesInfo[i].sErrMsg;
  end;
  grdList.Cells[0, m_nFDCount+1] :=  'NG';
  grdList.Cells[0, m_nFDCount+2] :=  'Total';

   for i := 1 to modDB.ChannelCount do begin
    grdList.Cells[i,0] := 'CH' + IntToStr(i);
  end;
  grdList.Cells[modDB.ChannelCount+1, 0] := 'SUM';
end;

procedure TfrmNGRatio.ViewGridQuery;
var
  sQuery, sSum : String;
  i, k   : Integer;
//  sL     : TStringList;
  nRow, nCol : Integer;
  nNgCode: Integer;
  nValue: Integer;
  nNG,  nTotal : integer;
  naHighlightIdx , naMax : array of Integer;
  fNgRadito : Double;
  sStartDate, sEndDate: string;
begin
  IntiGrid;

  sStartDate := FormatDateTime('YYYYMMDD', dtpStart.DateTime);
  sEndDate := FormatDateTime('YYYYMMDD', dtpEnd.DateTime);

  sQuery :=  'SELECT NG_TYPE ';
  for i := 1 to modDB.ChannelCount do begin
    sQuery:= sQuery + format(', SUM(CH%d)', [i]);
    if i = 1 then sSum:= format('SUM(CH%d)', [i])
    else sSum:= sSum + format('+SUM(CH%d)', [i]);
  end;
  sQuery:= sQuery + ', ' + sSum;
  sQuery:= sQuery +  ' FROM TLB_ISPD ';

  sQuery := sQuery + Format(' WHERE INSP_DATE BETWEEN ''%s'' AND ''%s'' GROUP BY NG_TYPE;',[sStartDate,sEndDate]);

  modDB.SendQueryOpen(sQuery);

  if modDB.SQLQuery.IsEmpty then begin // Date가 없는 경우 Check
//    Application.MessageBox('There is No Data','Confirm', MB_OK + MB_ICONINFORMATION );
    Exit;
  end;

  nCol := modDB.SQLQuery.FieldCount;
  nRow := m_nFDCount;

  SetLength(naHighlightIdx, modDB.ChannelCount);
  SetLength(naMax, modDB.ChannelCount);

  for i := 0 to nCol -1 do begin
    naMax[i-1]:= 0;
    naHighlightIdx[i-1]:= 1;
  end;

  while not modDB.SQLQuery.Eof do begin
    nNgCode:= modDB.SQLQuery.Fields[0].AsInteger;

    for i := 1 to nCol -1 do begin
      nValue:= modDB.SQLQuery.Fields[i].AsInteger;
      grdList.Ints[i, nNgCode + 1] := nValue;

      if (nNgCode > 0)  then begin
        if naMax[i-1] < nValue then begin
          naHighlightIdx[i-1] := nNgCode;
          naMax[i-1] := nValue;
        end;
      end;
    end;

    modDB.SQLQuery.Next;
  end;

  for i := 0 to nCol - 2 do begin
    grdList.Colors[i + 1, naHighlightIdx[i] + 1] := $00149BF0; // clYellow;
  end;

  //summary
  for i := 1 to nCol - 1 do begin
    nNG := 0;
    for k := 2 to nRow do begin
      nNG := nNG + grdList.Ints[i, k];
    end;
    nTotal:= grdList.Ints[i, 1] + nNG;  //OK + NG
    if nTotal > 0  then begin
      fNgRadito:= nNG;
      fNgRadito:= fNgRadito / nTotal * 100.0;
    end
    else begin
      fNgRadito:= 0.0;
    end;
    grdList.Cells[i,nRow + 1] := Format('%d (%.1f%%)',[nNG, fNgRadito]); //NG
    grdList.Ints[i,nRow + 2]:= nTotal; //Total
  end;

  for k := 1 to nRow do begin
    nNG := grdList.Ints[nCol - 1, k];;
//    for i := 1 to nCol - 2 do begin
//      nNG := nNG + grdList.Ints[i, k];
//    end;
    if nTotal > 0  then begin
      fNgRadito:= nNG;
      fNgRadito:= fNgRadito / nTotal * 100.0;
    end
    else begin
      fNgRadito:= 0.0;
    end;
    grdList.Cells[nCol - 1, k] := Format('%d (%.1f%%)',[nNG, fNgRadito]); //NG
  end;
end;

end.
