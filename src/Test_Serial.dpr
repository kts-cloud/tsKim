program Test_Serial;

uses
  Vcl.Forms,
  SerialTest in 'SerialTest.pas' {Form1},
  CommIonizer in 'CommIonizer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
