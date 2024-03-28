unit EcsStatus;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, Vcl.StdCtrls, Vcl.ExtCtrls, RzPanel;

type
  TfrmEcsStatus = class(TForm)
    AdvStringGrid1: TAdvStringGrid;
    pnlMainter: TRzPanel;
    RzPanel1: TRzPanel;
    AdvStringGrid3: TAdvStringGrid;
    RzPanel2: TRzPanel;
    AdvStringGrid2: TAdvStringGrid;
    Memo1: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmEcsStatus: TfrmEcsStatus;

implementation

{$R *.dfm}

end.
