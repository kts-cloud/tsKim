unit ZAxisConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, Vcl.ExtCtrls, RzPanel,
  CommonClass, RzButton;

type
  TfrmConfigZAxis = class(TForm)
    pnlMainter: TRzPanel;
    RzPanel1: TRzPanel;
    grdZxis: TAdvStringGrid;
    RzBitBtn1: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure RzBitBtn1Click(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
  private
    { Private declarations }
    procedure DisplayData;
  public
    { Public declarations }
  end;

var
  frmConfigZAxis: TfrmConfigZAxis;

implementation

{$R *.dfm}

{ TForm2 }

procedure TfrmConfigZAxis.DisplayData;
var
  i: Integer;
  sFilename : string;
begin

  sFilename := Common.Path.Ini + 'Config_ZAxis.csv';
  if FileExists(sFilename) then grdZxis.LoadFromCSV(sFilename)
  else begin
    grdZxis.ClearAll;
    grdZxis.RowCount := 100;
    grdZxis.Cells[0,0] := 'Model Idx';
    grdZxis.Cells[0,1] := 'Model Axis [pps]';
    grdZxis.Cells[0,2] := 'Comments';
    for i := 1 to 99 do begin
      grdZxis.Cells[0,i] := Format('%0.3d',[i]);
      grdZxis.Cells[1,i] := '0';
    end;
  end;
end;

procedure TfrmConfigZAxis.FormCreate(Sender: TObject);
begin
  DisplayData;
end;

procedure TfrmConfigZAxis.RzBitBtn1Click(Sender: TObject);
var
  sFilename : string;
begin
  sFilename := Common.Path.Ini + 'Config_ZAxis.csv';
  grdZxis.SaveFixedCells := True;
  grdZxis.SaveFixedCols := True;
  grdZxis.SaveToCSV(sFilename);
  DisplayData;

  Application.MessageBox('Save OK', 'Confirm', MB_OK);
end;

procedure TfrmConfigZAxis.RzBitBtn2Click(Sender: TObject);
begin
  Close;
end;

end.
