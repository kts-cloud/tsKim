unit WaitMsg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, Ca310;

type
  TfrmWaitCa210 = class(TForm)
    pnlShow: TRzPanel;
    tmShowMsg: TTimer;
    procedure tmShowMsgTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    procedure CreateSub;
    procedure OnThreadAutoTerminate(Sender: TObject);
  public
    m_nIdx : Integer;
    m_sTemp : string;
    m_RBrightobj  : RBrightObjects;
    m_nPort, m_nChNum : Integer;
    m_sCh             : string;
    { Public declarations }
  end;

var
  frmWaitCa210: TfrmWaitCa210;

implementation
//uses
//    OtlTaskControl, OtlParallel;
{$R *.dfm}

procedure TfrmWaitCa210.CreateSub;
begin
  if m_nPort in [10, 11] then begin
    m_RBrightobj.objca200.SetConfiguration(m_nPort - 9,m_sCh,m_nPort - 10,38400) //3번째 인자 0이면 USB , 1이면 COM1
  end
  else begin
    m_RBrightobj.objca200.SetConfiguration(1,m_sCh,m_nPort,38400) //3번째 인자 0이면 USB , 1이면 COM1
  end;
end;

procedure TfrmWaitCa210.FormCreate(Sender: TObject);
begin
  m_sTemp := '';
  tmShowMsg.Interval  := 1000;
  tmShowMsg.Enabled := True;

  m_RBrightobj.objCa200 := nil;
  m_RBrightobj.objCa := nil;
end;

procedure TfrmWaitCa210.FormShow(Sender: TObject);
var
  th1 : TThread;
begin
  th1 := TThread.CreateAnonymousThread(createSub);
  th1.OnTerminate := OnThreadAutoTerminate;
  th1.FreeOnTerminate := True;
  th1.Start;

//  Parallel.Async(createSub,
//  Parallel.TaskConfig.OnTerminated(
//    procedure (const task: IOmniTaskControl)
//    begin
//      Close;
//    end) );
end;

procedure TfrmWaitCa210.OnThreadAutoTerminate(Sender: TObject);
begin
  Close;
end;

procedure TfrmWaitCa210.tmShowMsgTimer(Sender: TObject);
begin
  m_sTemp := m_sTemp + '.';
  if Length(m_sTemp) > 4 then  m_sTemp := '';
  pnlShow.Caption := 'Searching Ca310 channels .' + m_sTemp;

end;

end.
