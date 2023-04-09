unit SerialTest;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, RzButton, CommIonizer, RzCmboBx, DefCommon, ALed, Vcl.ExtCtrls, RzPanel, Vcl.ComCtrls, RzEdit;

type
  TForm1 = class(TForm)
    RzBitBtn1: TRzBitBtn;
    cboComport: TRzComboBox;
    RzBitBtn2: TRzBitBtn;
    cboModelType: TRzComboBox;
    RzPanel10: TRzPanel;
    ledIonizer: ThhALed;
    pnlIonizer: TRzPanel;
    mmoSysLog: TRzRichEdit;
    RzBitBtn3: TRzBitBtn;
    procedure RzBitBtn1Click(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure RzBitBtn2Click(Sender: TObject);
    procedure RzBitBtn3Click(Sender: TObject);
  private
    { Private declarations }
    procedure ShowSysLog(sMsg : string; nNgCode : Integer = 0);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.RzBitBtn1Click(Sender: TObject);
var
  i : Integer;
begin
  for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
    DaeIonizer[i] := TIonizer.Create(i,Self.Handle,Self.Handle,DefCommon.MSG_TYPE_IONIZER);
    DaeIonizer[i].IsIgnoreNg := False;
    DaeIonizer[i].ChangePort(cboComport.ItemIndex,cboModelType.ItemIndex);
  end;
end;

procedure TForm1.RzBitBtn2Click(Sender: TObject);
var
  I : Integer;
begin
  for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
    if DaeIonizer[i] <> nil then begin
      DaeIonizer[i].Free;
      DaeIonizer[i] := nil;
    end;
  end;
end;

procedure TForm1.RzBitBtn3Click(Sender: TObject);
begin
  mmoSysLog.Clear;
end;

procedure TForm1.ShowSysLog(sMsg: string; nNgCode: Integer);
var
  sDebug : string;
begin
  mmoSysLog.DisableAlign;
  if nNgCode <> 0 then begin
    mmoSysLog.SelAttributes.Color := clRed;
    mmoSysLog.SelAttributes.Style := [fsBold];
  end;

  sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
  try
    mmoSysLog.Lines.Add(sDebug);
    mmoSysLog.Perform(EM_SCROLL,SB_LINEDOWN,0);
  except
  end;
  mmoSysLog.EnableAlign;
end;

procedure TForm1.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, nTemp : Integer;
  sMsg, sSubMsg, sFileName, sDebug : string;
  sCsvHeader : array [0..2] of string;
  sCsvData : string;
begin
  nType := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
  case nType of
    DefCommon.MSG_TYPE_IONIZER : begin
      nMode := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      sMsg  := string(PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
      nTemp  := PGuiIonizer(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      case nMode of
        CommIonizer.MSG_MODE_IONIZER_CONNECTION : begin
          pnlIonizer.Caption := sMsg;
          case nTemp of
            0 : begin
              ledIonizer.FalseColor := clRed;
              ledIonizer.Value := False;
            end;
            1 : begin
              ledIonizer.Value := True;
            end;
            2 : begin
              ledIonizer.FalseColor := clGray;
              ledIonizer.Value := False;
            end;
          end;
        end;
        CommIonizer.MSG_MODE_IONIZER_ERR_MSG : begin
          //pnlIonizer.Caption := sMsg;
          if nTemp = 1 then begin
            ShowSysLog(sMsg,1);
          end
          else begin
            ShowSysLog(sMsg);
          end;

        end;
        CommIonizer.MSG_MODE_IONIZER_LOG : begin
          ShowSysLog(sMsg);
        end;

      end;
    end;
  end;
end;
end.
