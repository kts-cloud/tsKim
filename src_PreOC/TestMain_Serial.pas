unit TestMain_Serial;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, RzCmboBx, VaClasses, VaComm, RzButton, DefRs232, Vcl.Mask, RzEdit;

type
  TForm1 = class(TForm)
    RzBitBtn1: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    ComLight: TVaComm;
    cboComport: TRzComboBox;
    edSender: TRzEdit;
    RzMemo1: TRzMemo;
    RzBitBtn3: TRzBitBtn;
    RzBitBtn4: TRzBitBtn;
    procedure RzBitBtn1Click(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
    procedure RzBitBtn3Click(Sender: TObject);
    procedure RzBitBtn4Click(Sender: TObject);
  private
    { Private declarations }
    procedure ReadVaCom (Sender: TObject; Count: Integer);
    function CheckOtpData(nReadData : Integer; var nA, nB, nC : Integer) : Integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function TForm1.CheckOtpData(nReadData: Integer; var nA, nB,  nC: Integer): Integer;
var
  nA_Data, nB_Data, nC_Data, nMax : Integer;
  sTemp : string;
begin
  sTemp := format('%0.2x',[(not nReadData)]);
  ShowMessage(sTemp);
  nA_Data := $03 and (not nReadData);
  nB_Data := ($1C and (not nReadData)) shr 2;
  nC_Data := ($E0 and (not nReadData)) shr 5;
  sTemp := format('%0.2x',[nA_Data]);
  ShowMessage(sTemp);
  sTemp := format('%0.2x',[nB_Data]);
  ShowMessage(sTemp);

  nMax := 0;
  if nA_Data > nMax then nMax := nA_Data;
  if nB_Data > nMax then nMax := nB_Data;
  if nC_Data > nMax then nMax := nC_Data;

  result := nMax;

end;

procedure TForm1.ReadVaCom(Sender: TObject; Count: Integer);
var
  sData, sDebug : string;
  rxBuf : array of byte;
  i: Integer;
begin
  sData := string(ComLight.ReadText);
  SetLength(rxBuf,Count);
  sDebug := ', binary :';
  for i := 0 to Pred(count) do begin
    rxBuf[i] := Byte(sData[i+1]);
    sDebug := sDebug + Format(' %0.2x',[rxBuf[i]]);

  end;
  RzMemo1.Lines.Add('REV Data : ' + sData + sDebug);
end;

procedure TForm1.RzBitBtn1Click(Sender: TObject);
var
  sTemp : string;
  nPort : Integer;
begin
  nPort := cboComport.ItemIndex;
  if nPort <> 0 then begin
    sTemp := Format('COM%d',[nPort]);
    if ComLight.Active then ComLight.Close;
    ComLight.PortNum := nPort;
    ComLight.Parity   := paNone;
    ComLight.Databits := db8;
    ComLight.FlowControl.OutCtsFlow := False;
    ComLight.FlowControl.OutDsrFlow := False;
    ComLight.FlowControl.TxContinueOnXoff := False;
//    ComLight.FlowControl.ControlDtr := ControlDtr.dtrDisabled;// := False;
//    ComLight.FlowControl.ControlRts := rtsDisabled;
    ComLight.FlowControl.XonXoffOut := False;
    ComLight.FlowControl.XonXoffIn := False;
    ComLight.FlowControl.DsrSensitivity := False;


    ComLight.BaudRate := br19200;
    {  TVaBaudrate = (brUser, br110, br300, br600, br1200, br2400, br4800, br9600, br14400,
    br19200, br38400, br56000, br57600, br115200, br128000, br256000);}
    ComLight.StopBits           := sb1;
    ComLight.EventChars.EofChar := DefRs232.LF; // Enter 가 오면 Event 발생하도록..
    ComLight.OnRxChar  := ReadVaCom;
    ComLight.Open;
  end
  else begin
    ComLight.close;
  end;


end;

procedure TForm1.RzBitBtn2Click(Sender: TObject);
var
  sSend : string;
  bRtn : boolean;
begin
  sSend := edSender.text + DefRs232.CR + DefRs232.LF;
  if ComLight.Active then begin
    bRtn := ComLight.WriteText(AnsiString(sSend));
  end;
end;

procedure TForm1.RzBitBtn3Click(Sender: TObject);
var
  nIdx, nTest : Integer;
  sDebug : string;
begin
  nIdx := $100;
  nTest := nIdx shr 8;
  sDebug := Format('%0.4x',[nTest]);
  ShowMessage(sDebug);
  nIdx := nTest shl 7;
  sDebug := Format('%0.4x',[nIdx]);
  ShowMessage(sDebug);

end;

procedure TForm1.RzBitBtn4Click(Sender: TObject);
var
  nReadData: Integer;
  nA, nB,  nC: Integer;
begin
//  ShowMessage('1');
  nReadData := $DA;
  CheckOtpData(nReadData, nA, nB,  nC)
end;

end.
