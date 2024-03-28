unit TestMain2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, RzShellDialogs, Vcl.StdCtrls, Vcl.Mask, RzEdit, Vcl.Grids, AdvObj,
  Algrithm_Jncd, BaseGrid, AdvGrid, RzButton, RzCmboBx, RzPanel, Vcl.ExtCtrls, CommonClass, DefCommon, AngleViewAlgorithm_TLB;

type
  TForm2 = class(TForm)
    dlgOpenPro: TRzOpenDialog;
    RzGroupBox12: TRzGroupBox;
    RzPanel12: TRzPanel;
    cboSelectCh: TRzComboBox;
    btnStartJNCDMeasure: TRzBitBtn;
    RzGroupBox14: TRzGroupBox;
    RzBitBtn9: TRzBitBtn;
    AdvStringGrid2: TAdvStringGrid;
    RzGroupBox13: TRzGroupBox;
    grdMeasureWRGB: TAdvStringGrid;
    btnJncd: TRzBitBtn;
    btnJncdAlgFile: TRzBitBtn;
    edJncdPath: TRzEdit;
    btnJnCdAlgoTest: TRzBitBtn;
    RzGroupBox15: TRzGroupBox;
    RzBitBtn10: TRzBitBtn;
    grdMeasureData: TAdvStringGrid;
    RzBitBtn11: TRzBitBtn;
    procedure btnJncdAlgFileClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure RzBitBtn11Click(Sender: TObject);
    procedure btnJnCdAlgoTestClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.btnJncdAlgFileClick(Sender: TObject);
begin
  dlgOpenPro.InitialDir :=  Common.Path.OcSpec;
  dlgOpenPro.Filter     := 'Jncd Spec Files (*.csv)|*.csv';
  if dlgOpenPro.Execute then begin
    try
      Jncd.LoadAngleViewRecipe(dlgOpenPro.FileName);
      edJncdPath.Text := dlgOpenPro.FileName;
    except
      edJncdPath.Text := 'Cannot load files.'
    end;
  end;
end;

procedure TForm2.btnJnCdAlgoTestClick(Sender: TObject);
var
  i : Integer;
  r, g, b : ST_XYLv;
begin
  for i := 1 to 4 do begin
    r.x   := StrToFloatDef(grdMeasureData.Cells[1,i],0.0);
    r.y   := StrToFloatDef(grdMeasureData.Cells[2,i],0.0);
    r.Lv  := StrToFloatDef(grdMeasureData.Cells[3,i],0.0);

    g.x   := StrToFloatDef(grdMeasureData.Cells[4,i],0.0);
    g.y   := StrToFloatDef(grdMeasureData.Cells[5,i],0.0);
    g.Lv  := StrToFloatDef(grdMeasureData.Cells[6,i],0.0);

    b.x   := StrToFloatDef(grdMeasureData.Cells[7,i],0.0);
    b.y   := StrToFloatDef(grdMeasureData.Cells[8,i],0.0);
    b.Lv  := StrToFloatDef(grdMeasureData.Cells[9,i],0.0);


    Jncd.AngleViewAlgorithm_value(i-1,r,g,b);

    grdMeasureData.Cells[10,i] := Jncd.m_stAngleRet[i-1].sResult;
  end;
end;

procedure TForm2.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Jncd <> nil then begin

    JnCd.Free;
    JnCd := nil;
  end;
  if Common <> nil then begin
    Common.Free;
    Common := nil;
  end;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Common := TCommon.Create;
  Jncd := TJncd.Create;
end;

procedure TForm2.RzBitBtn11Click(Sender: TObject);
begin
  grdMeasureData.RowCount   := 5;
  grdMeasureData.Cells[1,1] := '0.6817';
  grdMeasureData.Cells[1,2] := '0.6923';
  grdMeasureData.Cells[1,3] := '0.6818';
  grdMeasureData.Cells[1,4] := '0.6860';

  grdMeasureData.Cells[2,1] := '0.3183';
  grdMeasureData.Cells[2,2] := '0.3077';
  grdMeasureData.Cells[2,3] := '0.3182';
  grdMeasureData.Cells[2,4] := '0.3240';

  grdMeasureData.Cells[3,1] := '38.2';
  grdMeasureData.Cells[3,2] := '48.9';
  grdMeasureData.Cells[3,3] := '40.2';
  grdMeasureData.Cells[3,4] := '190.8';

  grdMeasureData.Cells[4,1] := '0.2413';
  grdMeasureData.Cells[4,2] := '0.2405';
  grdMeasureData.Cells[4,3] := '0.2533';
  grdMeasureData.Cells[4,4] := '0.2404';

  grdMeasureData.Cells[5,1] := '0.7216';
  grdMeasureData.Cells[5,2] := '0.7246';
  grdMeasureData.Cells[5,3] := '0.7126';
  grdMeasureData.Cells[5,4] := '0.7376';

  grdMeasureData.Cells[6,1] := '181.0';
  grdMeasureData.Cells[6,2] := '228.6';
  grdMeasureData.Cells[6,3] := '223.5';
  grdMeasureData.Cells[6,4] := '461.7';

  grdMeasureData.Cells[7,1] := '0.1404';
  grdMeasureData.Cells[7,2] := '0.1398';
  grdMeasureData.Cells[7,3] := '0.1388';
  grdMeasureData.Cells[7,4] := '0.1465';

  grdMeasureData.Cells[8,1] := '0.0482';
  grdMeasureData.Cells[8,2] := '0.0485';
  grdMeasureData.Cells[8,3] := '0.0487';
  grdMeasureData.Cells[8,4] := '0.0509';

  grdMeasureData.Cells[9,1] := '13.3';
  grdMeasureData.Cells[9,2] := '17.7';
  grdMeasureData.Cells[9,3] := '14.4';
  grdMeasureData.Cells[9,4] := '14.3';
end;

end.
