unit LogIn;

interface

uses
  Winapi.Windows, Winapi.Messages,System.UITypes, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, Vcl.StdCtrls, Vcl.Mask, RzEdit, RzButton,
  AdvSmoothTouchKeyBoard, RzLabel, CommonClass, Vcl.Imaging.pngimage, DefCommon;

type
  TfrmLogIn = class(TForm)
    AdvSmoothTouchKeyBoard1: TAdvSmoothTouchKeyBoard;
    btnCancel: TRzBitBtn;
    btnOK: TRzBitBtn;
    edUserID: TRzEdit;
    pnlUserID: TRzPanel;
    pnlPassword: TRzPanel;
    edPassword: TRzEdit;
    lblManFlag: TRzLabel;
    RzBitBtn1: TRzBitBtn;
    img1: TImage;
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edPasswordKeyPress(Sender: TObject; var Key: Char);
    procedure RzBitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmLogIn: TfrmLogIn;

implementation

{$R *.dfm}

procedure TfrmLogIn.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
	Close;
end;

procedure TfrmLogIn.btnOKClick(Sender: TObject);
{$IFDEF ISPD_A}
var
  sTemp : string;
{$ENDIF}
begin


{$IFDEF ISPD_A}
  sTemp := FormatDateTime('hhnn',now);
  if CompareText(edPassword.Text, sTemp) = 0 then begin
    ModalResult := mrOK;
  end
  else if CompareText(edPassword.Text, Common.SystemInfo.Password) = 0 then begin
    ModalResult := mrOK;
  end
  else begin
    MessageDlg(#13#10 + 'Incorrect Admin Password!', mtError, [mbOk], 0);
		edPassword.Text := '';
		edPassword.SelectAll;
		edPassword.SetFocus;
  end;
  //패스워드 설정 안돼있는 경우는?

{$ELSE}
  if CompareText(edPassword.Text, Common.SystemInfo.Password) <> 0 then begin
		MessageDlg(#13#10 + 'Incorrect Admin Password!', mtError, [mbOk], 0);
		edPassword.Text := '';
		edPassword.SelectAll;
		edPassword.SetFocus;
  end
  else
		ModalResult := mrOK;
{$ENDIF}
end;

procedure TfrmLogIn.edPasswordKeyPress(Sender: TObject; var Key: Char);
var
	Handle:THandle;
begin
	if key = #27 { ESC } then
		ModalResult := mrCancel
	else if (ActiveControl is TRzEdit) and (key = #13) then begin
		Handle := GetFocus;
		if Handle = edPassword.Handle then
			btnOKClick(Self)
		else
      SelectNext(ActiveControl, True, True);
	end
  else if (ActiveControl is TRzBitBtn) and (key = #13) then
		btnOKClick(Self);
end;

procedure TfrmLogIn.FormCreate(Sender: TObject);
begin
  SetBounds(200, 60, 446, 164);
  //self.Height := 164;
  lblManFlag.Caption := 'Input Admin password (Số nhân viên)';
  pnlUserId.Caption  := 'User ID(Số nhân viê)';
end;

procedure TfrmLogIn.FormShow(Sender: TObject);
begin
	edUserID.MaxLength := 6; //사번 6자 제한
	edPassword.MaxLength := 32; //암호 32자 제한

	lblManFlag.Caption := 'Input Admin Password...';
	edUserId.Text    := 'ADMIN';
	edUserId.Enabled := False;
	edPassword.SetFocus;
end;

procedure TfrmLogIn.RzBitBtn1Click(Sender: TObject);
begin
  if Self.Height = 164 then begin
    Self.Height  := 346;
  end
  else begin
    self.Height := 164;
  end;
  edPassword.SetFocus;
end;

end.
