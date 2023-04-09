unit SelectDetect;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.ImageList, Vcl.ImgList, RzButton,
  Vcl.ExtCtrls;

type
  TfrmSelectDetect = class(TForm)
    ImageList1: TImageList;
    btnOk: TRzBitBtn;
    btnNo: TRzBitBtn;
    btnCancel: TRzBitBtn;
    pnlCaption: TPanel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSelectDetect: TfrmSelectDetect;

implementation

{$R *.dfm}

procedure TfrmSelectDetect.FormCreate(Sender: TObject);
begin
  pnlCaption.StyleElements:= [];
  btnOk.StyleElements:= [];
  btnNo.StyleElements:= [];
  btnCancel.StyleElements:= [];
end;

end.
