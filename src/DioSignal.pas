unit DioSignal;

interface
{$I Common.inc}
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DefDio, Vcl.ExtCtrls, RzPanel, TILed, RzCommon
{$IFDEF AXDIO_USE}
  ,AXDioLib
{$ENDIF}
  ;

type
  TfrmDioSignal = class(TForm)
    grpDioSig: TRzGroupBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }

    pnlIn, pnlOut       : array[0.. DefDio.MAX_IN_CNT] of  TRzPanel;
    pnlInTitle, pnlOutTitle : TRzPanel;
    procedure MakeDioSig;
  public
    ledDioIn, ledDioOut : array[0.. DefDio.MAX_IN_CNT] of  TTILed;
    { Public declarations }
  end;

var
  frmDioSignal: TfrmDioSignal;

implementation

{$R *.dfm}

procedure TfrmDioSignal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmDioSignal.FormCreate(Sender: TObject);
begin
  MakeDioSig;

end;

procedure TfrmDioSignal.FormDestroy(Sender: TObject);
begin
  frmDioSignal := nil;
end;

procedure TfrmDioSignal.FormShow(Sender: TObject);
begin
  AxDio.GetDioStatus;
end;

procedure TfrmDioSignal.MakeDioSig;
const
  arInputNormal : array[0..Pred(DefDio.MAX_IN_CNT)] of string
  = (  ' Probe Up #A'         ,' Probe Up #B'
      ,' Probe Down #A'       ,' Probe Down #B'
      ,' Pusher Up #A'        ,' Pusher Up #B'
      ,' Pusher Down #A'      ,' Pusher Down #B'
      ,' Probe Forword #A'    ,' Probe Forword #B'
      // 10 ~19
      ,' Pusher Backword #A'  ,' Pusher Backword #B'
      ,' Contact Up #1'  ,' Contact Up #2'
      ,' Contact Up #3'  ,' Contact Up #4'
      ,' Contact Up #5'  ,' Contact Up #6'
      ,' Contact Up #7'  ,' Contact Up #8'
      // 20~29
      ,' Contact Down #1',' Contact Down #2'
      ,' Contact Down #3',' Contact Down #4'
      ,' Contact Down #5',' Contact Down #6'
      ,' Contact Down #7',' Contact Down #8'
      ,' Detect Carrier #1'   ,' Detect Carrier #2'
      // 30~39
      ,' Detect Carrier #3'   ,' Detect Carrier #4'
      ,' Detect Carrier #5'   ,' Detect Carrier #6'
      ,' Detect Carrier #7'   ,' Detect Carrier #8'
      ,' EMS #1'              ,' EMS #2'
      ,' Reset #1'            ,' Reset #2'
      // 40~45
      ,' Door Sensor #1'      ,' Door Sensor #2'
      ,' FAN #1'              ,' FAN #2'
      ,' Temp Controller'     ,' Main Regulator'
      ,''  ,''  ,''  ,''  ,''  ,''  ,''  ,''  ,'' , '');
  arOutputNormal : array[0..Pred(DefDio.MAX_OUT_CNT)] of string
  = (  ' Probe Up #A'         ,' Probe Up #B'
      ,' Probe Down #A'       ,' Probe Down #B'
      ,' Pusher Up #A'        ,' Pusher Up #B'
      ,' Pusher Down #A'      ,' Pusher Down #B'
      ,' Probe Forword #A'    ,' Probe Forword #B'
      // 10 ~19
      ,' Probe Backword #A'  ,' Probe Backword #B'
      ,' Contact Up #1'  ,' Contact Up #2'
      ,' Contact Up #3'  ,' Contact Up #4'
      ,' Contact Up #5'  ,' Contact Up #6'
      ,' Contact Up #7'  ,' Contact Up #8'
      // 20~29
      ,' Contact Down #1',' Contact Down #2'
      ,' Contact Down #3',' Contact Down #4'
      ,' Contact Down #5',' Contact Down #6'
      ,' Contact Down #7',' Contact Down #8'
      ,' Ion Bar #A'     ,' Ion Bar #B'
      // 30~39
      ,' '               ,' '
      ,' Red Lamp'       ,' Yellow Lamp'
      ,' Green Lamp'     ,' Buzzer'
      ,' '               ,' '
      ,' '               ,''
      // 40~45
      ,''                ,''
      ,''                ,''
      ,''                ,''
      ,''  ,''  ,''  ,''  ,''  ,''  ,''  ,''  ,'' , '');
var
  i, nDiv : Integer;
  nWidth, nHeight : Integer;
begin
  nWidth := 140;
  nHeight := 22;

  // Title for In Signal.
  pnlInTitle := TRzPanel.Create(nil);
  pnlInTitle.Parent := grpDioSig;
  pnlInTitle.Left := 3;
  pnlInTitle.Top  := 20;
  pnlInTitle.BevelWidth := 1;
  pnlInTitle.FlatColor := clBlack;
  pnlInTitle.BorderInner  := TframeStyleEx(fsNone);
  pnlInTitle.BorderOuter  := TframeStyleEx(fsFlat);
  pnlInTitle.Width        := (23 + nWidth + 5) *2;
  pnlInTitle.Height       := nHeight;
  pnlInTitle.Caption      := 'In Signal';
  pnlInTitle.Visible      := True;

  // Title for Out Signal.
  pnlOutTitle := TRzPanel.Create(nil);
  pnlOutTitle.Parent := grpDioSig;
  pnlOutTitle.Left := nWidth *3  - 10;
  pnlOutTitle.Top  := 20;
  pnlOutTitle.BevelWidth := 1;
  pnlOutTitle.FlatColor := clBlack;
  pnlOutTitle.BorderInner  := TframeStyleEx(fsNone);
  pnlOutTitle.BorderOuter  := TframeStyleEx(fsFlat);
  pnlOutTitle.Width        := (23 + nWidth + 5) *2;
  pnlOutTitle.Height       := nHeight;
  pnlOutTitle.Caption      := 'Out Signal';
  pnlOutTitle.Visible      := True;

  nDiv := DefDio.MAX_IO_CNT div 2;
  for i := 0 to Pred(DefDio.MAX_IO_CNT) do begin

    // Number.
    pnlIn[i] := TRzPanel.Create(nil);
    pnlIn[i].Parent := grpDioSig;

    if i < nDiv then pnlIn[i].Left   := 3
    else             pnlIn[i].Left   := pnlIn[0].Left  + pnlOut[0].Width + nWidth + 5;
    if i in [0, nDiv] then begin
      pnlIn[i].Top := pnlInTitle.Top + pnlInTitle.Height;
    end
    else begin
      pnlIn[i].Top := pnlIn[i-1].Top + pnlIn[i-1].Height;
    end;

    pnlIn[i].BevelWidth := 1;
    pnlIn[i].FlatColor := clBlack;
    pnlIn[i].BorderInner  := TframeStyleEx(fsNone);
    pnlIn[i].BorderOuter  := TframeStyleEx(fsFlat);
    pnlIn[i].Width        := 23;
    pnlIn[i].Height       := nHeight;
    pnlIn[i].Caption      := Format('%0.2d',[i]);
    pnlIn[i].Visible      := True;
  // Led for In.
    ledDioIn[i] := TTILed.Create(Self);
    ledDioIn[i].Parent := grpDioSig;

    ledDioIn[i].Left := pnlIn[i].Left + pnlIn[i].Width + 2;
    ledDioIn[i].Top  := pnlIn[i].Top;

    ledDioIn[i].Width := nWidth;
    ledDioIn[i].Height := nHeight;
    ledDioIn[i].LedColor := TLedColor(Green);
    ledDioIn[i].StyleElements := [seBorder];
    ledDioIn[i].Caption := '';
//
//
    // number for Out.
    pnlOut[i] := TRzPanel.Create(nil);
    pnlOut[i].Parent := grpDioSig;
//    if (i mod 2) <> 0 then begin
//      pnlOut[i].Left := ledDioOut[i-1].Left + nWidth + 5 ;
//      pnlOut[i].Top  := ledDioOut[i-1].Top;
//    end
//    else begin
//      pnlOut[i].Left := nWidth *3  - 10;
//      pnlOut[i].Top  := + pnlOutTitle.Top + pnlOutTitle.Height+ i*(nHeight div 2);
//    end;
    if i < nDiv then pnlOut[i].Left   := nWidth *3  - 10
    else             pnlOut[i].Left   := pnlOut[0].Left + pnlOut[0].Width + nWidth + 5;
    if i in [0, nDiv] then begin
      pnlOut[i].Top := pnlOutTitle.Top + pnlOutTitle.Height;
    end
    else begin
      pnlOut[i].Top := pnlOut[i-1].Top + pnlOut[i-1].Height;
    end;

    pnlOut[i].BevelWidth := 1;
    pnlOut[i].FlatColor := clBlack;
    pnlOut[i].BorderInner  := TframeStyleEx(fsNone);
    pnlOut[i].BorderOuter  := TframeStyleEx(fsFlat);
    pnlOut[i].Width        := 23;
    pnlOut[i].Height       := nHeight;
    pnlOut[i].Caption      := Format('%0.2d',[i]);
    pnlOut[i].Visible      := True;

    ledDioOut[i] := TTILed.Create(Self);
    ledDioOut[i].Parent := grpDioSig;

    ledDioOut[i].Left := pnlOut[i].Left + pnlOut[i].Width + 2;
    ledDioOut[i].Top  := pnlOut[i].Top;

    ledDioOut[i].Left := 3 + pnlOut[i].Left + pnlOut[i].Width;
    ledDioOut[i].Width := nWidth;
    ledDioOut[i].Height := nHeight;
    ledDioOut[i].LedColor := TLedColor(Yellow);
    ledDioOut[i].StyleElements := [seBorder];
    ledDioOut[i].Caption := '';
  end;

  for i := 0 to Pred(DefDio.MAX_IN_CNT) do begin
    ledDioIn[i].Caption :=  Trim(arInputNormal[i]);
  end;
  for i := 0 to Pred(DefDio.MAX_OUT_CNT) do begin
    ledDioOut[i].Caption :=  Trim(arOutputNormal[i]);
  end;
end;

end.
