unit SelectDetect;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.ImageList, Vcl.ImgList, RzButton,
  Vcl.ExtCtrls,CommonClass,DefCommon,CommPLC_ECS;

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
  if g_CommPLC <> nil then begin
    if (g_CommPLC.PollingAABMode = 1) and (Common.PLCInfo.InlineGIB) then begin
      btnOk.Caption := 'AAB ¤ÑMODE';
      btnOk.Enabled := False;
    end;
  end;

  if Common.SystemInfo.OCType = DefCommon.OCType then begin
    btnNo.Caption := 'UnLoad';
  end
  else if Common.SystemInfo.OCType = DefCommon.PreOCType then begin
    btnNo.Caption := 'Exchange';
    pnlCaption.Caption := 'Panel Detected'
  end;

  pnlCaption.StyleElements:= [];
  btnOk.StyleElements:= [];
  btnNo.StyleElements:= [];
  btnCancel.StyleElements:= [];
end;

end.
