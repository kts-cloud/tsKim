unit UserId;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics, System.Classes, Winapi.ShellAPI, RzPanel, RzButton,
  RzEdit, Vcl.ImgList, Vcl.Mask, DefCommon, CommonClass, System.ImageList,
  system.uitypes, AdvSmoothTouchKeyBoard  ;

//  Mask, RzEdit,  RzRadChk, Vcl.Buttons, RzSpnEdt, Vcl.ImgList, Vcl.StdCtrls;

type
  TUserIdDlg = class(TForm)
    RzPanel2: TRzPanel;
    Btn_Cancel: TRzBitBtn;
    Btn_OK: TRzBitBtn;
    pnlUserId: TRzPanel;
    UserId: TRzEdit;
    il1: TImageList;
    btn1: TRzBitBtn;
    RzPanel1: TRzPanel;
    Image_Pat1: TImage;
    AdvSmoothPopupTouchKeyBoard1: TAdvSmoothPopupTouchKeyBoard;
    lblLbManFlag: TLabel;
    procedure Btn_OKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Btn_CancelClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UserIdDlg: TUserIdDlg;

implementation


{$R *.DFM}

procedure TUserIdDlg.Btn_OKClick(Sender: TObject);
begin
  if not (Length(UserId.Text) in [5..9]) then begin
    if 'PM' = UpperCase(UserId.Text) then begin
      Common.m_sUserId := UpperCase(Trim(UserId.Text));
      ModalResult := mrOK;
    end
    else begin
      MessageDlg('Retry to input User ID number !', mtWarning, [mbOk], 0);
      UserId.Text := '';
      if UserId.CanFocus then UserId.SetFocus;
      ModalResult := mrNone;
    end;
  end
  else begin
    Common.m_sUserId := Trim(UserId.Text);
    ModalResult := mrOK;
  end;
end;

procedure TUserIdDlg.btn1Click(Sender: TObject);
begin
  AdvSmoothPopupTouchKeyBoard1.Show;
  SelectNext(ActiveControl, True, True);
//  AdvSmoothPopupTouchKeyBoard1.ShowAtXY(self.Top div 2,Self.Left);
end;

procedure TUserIdDlg.Btn_CancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Close;
end;

procedure TUserIdDlg.FormShow(Sender: TObject);
begin
//  UserId.MaxLength := 9;    //사번 9자 제한
  //Password.MaxLength := 32; //암호 32자 제한

//  lblLbManFlag.Caption := 'Input User ID';
  UserId.SetFocus;
//  UserId.Text := '000000'
end;

procedure TUserIdDlg.FormCreate(Sender: TObject);
begin
//  if Common.SystemInfo.Language = DefCommon. then begin
//    lblLbManFlag.Caption := 'Input User ID (사원번호)';
//    pnlUserId.Caption := '사원번호';
//  end
//  else begin
    lblLbManFlag.Caption := 'Input User ID (Số nhân viên)';
    pnlUserId.Caption  := 'USER ID (Số nhân viên)';
//  end;
end;

procedure TUserIdDlg.FormKeyPress(Sender: TObject; var Key: Char);
var
  Handle:THandle;
begin
  if key = #27 { ESC } then
    ModalResult := mrCancel
  else if (ActiveControl is TRzEdit) and (key = #13) then begin
    Handle := GetFocus;
    if Handle = UserId.Handle then
      Btn_OKClick(Self)
    else
      SelectNext(ActiveControl, True, True);
  end
  else if (ActiveControl is TRzBitBtn) and (key = #13) then
    Btn_OKClick(Self);
end;

end.
