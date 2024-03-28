unit DoorOpenAlarmMsg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,DefCommon, RzButton, defDio, CommonClass;

type
  TfrmDoorOpenAlarmMsg = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lblWorker: TLabel;
    lblPhone: TLabel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    gbAdminClose: TGroupBox;
    edtPassword: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    btnClose: TRzBitBtn;
    tmrRefresh: TTimer;
    lblTime: TLabel;
    pnlDoor_UpperLeft: TPanel;
    pnlDoor_UpperRight: TPanel;
    pnlDoor_LowerLeft: TPanel;
    pnlDoor_LowerRight: TPanel;
    btnResetError: TRzBitBtn;
    btnStopBuzzer: TRzBitBtn;
    btnShowAlarm: TRzBitBtn;
    procedure FormShow(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure tmrRefreshTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtPasswordKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClick(Sender: TObject);
    procedure btnResetErrorClick(Sender: TObject);
    procedure btnStopBuzzerClick(Sender: TObject);
    procedure btnShowAlarmClick(Sender: TObject);
    procedure Panel1DblClick(Sender: TObject);
  private
    { Private declarations }
    bBypass : Boolean;
    procedure CheckDoor;
  public
    { Public declarations }
    procedure CloseEnable(bEnable: Boolean);
  end;

var
  frmDoorOpenAlarmMsg: TfrmDoorOpenAlarmMsg;

implementation
uses ControlDio_OC,Main_OC;
{$R *.dfm}

procedure TfrmDoorOpenAlarmMsg.btnResetErrorClick(Sender: TObject);
var
  i: Integer;
begin
  ControlDio.Set_TowerLampState(LAMP_STATE_PAUSE);
  for i := 0 to 150 do begin
    Common.StatusInfo.AlarmData[i]:= 0;
  end;
end;

procedure TfrmDoorOpenAlarmMsg.btnShowAlarmClick(Sender: TObject);
begin
  frmMain_OC.tmDioAlarmTimer(Sender);
end;

procedure TfrmDoorOpenAlarmMsg.btnStopBuzzerClick(Sender: TObject);
begin
  ControlDio.MelodyOn:= False;
end;

procedure TfrmDoorOpenAlarmMsg.CheckDoor;
var
  bOpened: Boolean;
begin

  pnlDoor_UpperLeft.Visible := not ControlDio.ReadInSig(DefDio.IN_CH_1_2_DOOR_LEFT_OPEN);
  pnlDoor_UpperRight.Visible := not ControlDio.ReadInSig(DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN);
  pnlDoor_LowerLeft.Visible := not ControlDio.ReadInSig(DefDio.IN_CH_3_4_DOOR_LEFT_OPEN);
  pnlDoor_LowerRight.Visible := not ControlDio.ReadInSig(DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN);

  bOpened:= False;
  if Common.SystemInfo.OCType = DefCommon.OCType then begin
    if not ControlDio.ReadInSig(DefDio.IN_CH_1_2_DOOR_LEFT_OPEN) then begin
      bOpened:= True;
    end;
    if not ControlDio.ReadInSig(DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN) then begin
      bOpened:= True;
    end;
    if not ControlDio.ReadInSig(DefDio.IN_CH_3_4_DOOR_LEFT_OPEN) then begin
      bOpened:= True;
    end;
    if not ControlDio.ReadInSig(DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN) then begin
      bOpened:= True;
    end;
    if frmMain_OC.PollingDoorOpened and (not bBypass) then
      bOpened := True;
  end
  else begin
    if ControlDio.ReadInSig(DefDio.IN_GIB_CH_12_EMO_SWITCH) then begin
    bOpened:= True;
    end;
    if ControlDio.ReadInSig(DefDio.IN_GIB_CH_34_EMO_SWITCH) then begin
      bOpened:= True;
    end;
    if frmMain_OC.PollingDoorOpened and (not bBypass) then
      bOpened := True;

  end;

  CloseEnable(not bOpened);
end;

procedure TfrmDoorOpenAlarmMsg.CloseEnable(bEnable: Boolean);
begin
  gbAdminClose.Visible:= bEnable;
  if bEnable then begin
    edtPassword.SetFocus;
  end;
end;

procedure TfrmDoorOpenAlarmMsg.edtPasswordKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then begin
    btnCloseClick(Sender);
  end;
end;

procedure TfrmDoorOpenAlarmMsg.FormClick(Sender: TObject);
begin
  if gbAdminClose.Visible then begin
    edtPassword.SetFocus;
  end;
end;

procedure TfrmDoorOpenAlarmMsg.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  tmrRefresh.Enabled:= False;
  Action:= caFree;
  frmDoorOpenAlarmMsg:= nil;
end;

procedure TfrmDoorOpenAlarmMsg.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if btnClose.Tag <> 1 then begin
    CanClose:= False;
  end;
end;

procedure TfrmDoorOpenAlarmMsg.FormShow(Sender: TObject);
begin
  CheckDoor;
  bBypass := False;
  tmrRefresh.Enabled:= True;
  if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
    gbAdminClose.Color  := clBlack;
    gbAdminClose.StyleElements := [];
  end;
//  lblPhone.Top := self.Height - 60;
//
//  lblWorker.Top := self.Height - 60;
//  lblWorker.Left := self.Width - 150;
end;

procedure TfrmDoorOpenAlarmMsg.Panel1DblClick(Sender: TObject);
begin
  bBypass := not bBypass;
end;

procedure TfrmDoorOpenAlarmMsg.tmrRefreshTimer(Sender: TObject);
begin
  lblTime.Caption:= FormatDateTime('HH:NN:SS', Now);
  CheckDoor;
end;

procedure TfrmDoorOpenAlarmMsg.btnCloseClick(Sender: TObject);
var
  sPass: String;
begin
  sPass:= FormatDateTime('HHMM', Now);
  if sPass <> edtPassword.Text then begin
    Application.MessageBox('Inconrrect Password', 'Error', MB_OK+MB_ICONSTOP);
    Exit;
  end;
  btnClose.Tag:= 1;
  Close;
end;

end.
