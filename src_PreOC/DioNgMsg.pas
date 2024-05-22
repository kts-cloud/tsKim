unit DioNgMsg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzButton, Vcl.StdCtrls, RzLabel,
  Vcl.ExtCtrls, DIO_ADLINK;

type
  TfrmDioNgMsg = class(TForm)
    pnlNgMsg: TPanel;
    lblShow: TRzLabel;
    RzBitBtn1: TRzBitBtn;
    procedure RzBitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmDioNgMsg: TfrmDioNgMsg;

implementation

{$R *.dfm}

procedure TfrmDioNgMsg.RzBitBtn1Click(Sender: TObject);
begin
  AdLinkDio.SetAlarmLamp(-1,-1,-1,0);
end;

end.
