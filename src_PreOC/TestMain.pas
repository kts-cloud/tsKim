unit TestMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, system.zip, Vcl.Dialogs, Vcl.StdCtrls,  CommonClass,
  Vcl.Controls, Vcl.ExtCtrls, RzPanel, System.Classes, Vcl.Buttons, Vcl.Forms, RzButton, RzShellDialogs,
  RzEdit, Vcl.Mask, system.math;

type
  TfrmTestMain = class(TForm)
    btn4: TBitBtn;
    btn6: TButton;
    btn7: TButton;
    dlgOpen1: TOpenDialog;
    RzOpenDialog1: TRzOpenDialog;
    RzBitBtn1: TRzBitBtn;
    Button1: TButton;
    RzEdit1: TRzEdit;
    RzEdit2: TRzEdit;
    RzMemo1: TRzMemo;
    RzBitBtn2: TRzBitBtn;
    procedure btn6Click(Sender: TObject);
    procedure btn7Click(Sender: TObject);
    procedure RzBitBtn1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
  private
    { Private declarations }
    m_Zip          : TZipFile;

  public
    { Public declarations }
  end;

var
  frmTestMain: TfrmTestMain;

implementation

{$R *.dfm}

procedure TfrmTestMain.btn6Click(Sender: TObject);
var
  sFileName, sExt : string;
begin
  dlgOpen1.DefaultExt := '.bin';
  dlgOpen1.InitialDir := ExtractFilePath(Application.ExeName);
  if dlgOpen1.Execute then begin

    m_Zip := TZipFile.Create;
    try
      sFileName  := ExtractFileName(dlgOpen1.FileName);
      sExt       := ExtractFileExt(dlgOpen1.FileName);
      sFileName  := StringReplace(sFileName,sExt,'.zip', [rfReplaceAll, rfIgnoreCase]);
      m_Zip.Open(sFileName,zmWrite);
      m_Zip.Add(dlgOpen1.FileName);
      m_Zip.Close;
    finally
      m_Zip.Free;
    end;
  end;
end;

procedure TfrmTestMain.btn7Click(Sender: TObject);

begin
  dlgOpen1.InitialDir := ExtractFilePath(Application.ExeName);
  if dlgOpen1.Execute then begin

    m_Zip := TZipFile.Create;
    try
      m_Zip.Open(dlgOpen1.FileName,zmRead);
      m_Zip.ExtractAll;
      m_Zip.Close;
    finally
      m_Zip.Free;
    end;
  end;
end;

procedure TfrmTestMain.Button1Click(Sender: TObject);
var
  sTemp : string;
  dA, dB, b, dRet, dRet2 : Double;
  dtemp1, dTemp2 : Double;
begin
//     // COS(RADIANS($E5))
  dA := (0.50524 - 0.4964); //mu-tu
  dB := (0.52345 - 0.5255); //mu-tu
  dtemp1 := dB / dA;
  b := System.math.DegToRad(1);
  dRet := ArcTan(dtemp1) / b;

//  0.50524	0.52345	0.4964	0.5255
//0.0894	0.5806	0.0986	0.5777

  dRet2 := System.math.ArcTan2(dB,dA) * 180 / PI;
  sTemp := format('RED %0.6f,%0.6f,%0.6f, %0.6f,(%0.6f)',[b,ArcTan2(dA, dB),dtemp1, dRet,dRet2]);
  ShowMessage(sTemp);


    dA := (0.0894-0.0986);
  dB := (0.5806-0.5777);
  dtemp1 := dB / dA;
  b := System.math.DegToRad(1);
  dRet2 := System.math.ArcTan2(dB, dA)*180/PI;

  //dRet := System.math.ArcTan2(dA, dB) / b;
  sTemp := format('g %0.6f,%0.6f,%0.6f, %0.6f',[b,ArcTan2(dA, dB),dtemp1, dRet2]);
  ShowMessage(sTemp);


  dA := -0.01451;
  dB := -0.01471;
  dtemp1 := dB / dA;
  b := System.math.DegToRad(1);
  dRet := ArcTan(dtemp1) / b;
  dRet2 := System.math.RadToCycle(System.math.ArcTan2(dA, dB) / b);
  sTemp := format('b %0.6f,%0.6f,%0.6f, %0.6f, (%0.6f)',[b,ArcTan2(dA, dB),dtemp1, dRet,dRet2]);
  ShowMessage(sTemp);
end;

procedure TfrmTestMain.RzBitBtn1Click(Sender: TObject);
var
  txFile : TextFile;
  sReadData, sFileName : string;
  txBuff : array of byte;
  nTemp, nCnt : Integer;
  fi : TFileStream;
begin
  if RzOpenDialog1.Execute then begin

    if not FileExists(RzOpenDialog1.FileName) then  Exit;
    AssignFile(txFile,RzOpenDialog1.FileName);

    try
      Reset(txFile);
      nCnt := 0;
      while not Eof(txFile) do begin
        Readln(txFile,sReadData);
        Inc(nCnt);
      end;
    finally
      CloseFile(txFile);
    end;
    SetLength(txBuff,nCnt);
    try
      Reset(txFile);
      nCnt := 0;
      while not Eof(txFile) do begin
        Readln(txFile,sReadData);
        nTemp := StrToIntDef('$'+sReadData,0);
        txBuff[nCnt] := Byte(nTemp);
        Inc(nCnt);
      end;
    finally
      CloseFile(txFile);
    end;

  sFileName := 'Test.bin';
  fi := TFileStream.Create(sFileName, fmCreate);
  try
    fi.WriteBuffer(txBuff[0],nCnt);
  finally
    fi.Free;
  end;
  end;
end;

procedure TfrmTestMain.RzBitBtn2Click(Sender: TObject);
begin
  RzMemo1.Lines.Clear;
end;

end.
