program ControlEtc;

uses
  Vcl.Forms,
  MainControlEtc in 'MainControlEtc.pas' {frmMainControlEtc},
  DioDisplayAlarm in 'DioDisplayAlarm.pas' {frmDisplayAlarm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMainControlEtc, frmMainControlEtc);
  Application.Run;
end.
