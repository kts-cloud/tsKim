unit Test4Ch;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzPanel, ALed, RzButton, Vcl.ExtCtrls, RzRadChk,
  Vcl.StdCtrls, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, RzCommon, LogicVh, SwitchBtn, JigControl,
  UdpServerClient, CommonClass, ScriptClass, DefScript, DefPG, DefCommon,
  CodeSiteLogging, AdvPanel, Vcl.ComCtrls, AdvListV, Vcl.Mask, RzEdit, DongaPattern, RzGrids, AdvUtil, RzLine,
  HandBCR, GMesCom, pasScriptClass, AutoBCRClient, DefGmes, Vcl.Buttons, AXDioLib;

type
  TfrmTest4Ch = class(TForm)
    imgCheckBox: TImage;
    tmrDisplayOff: TTimer;
    pnlSwitch: TAdvPanel;
    btnSWNext1: TRzBitBtn;
    btnSWCancel1: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    btnAuto: TRzBitBtn;
    btnCh4: TRzBitBtn;
    btnRepeat: TRzBitBtn;
    btnCh2: TRzBitBtn;
    RzBitBtn7: TRzBitBtn;
    RzBitBtn8: TRzBitBtn;
    RzPanel1: TRzPanel;
    RzPanel2: TRzPanel;
    RzPanel3: TRzPanel;
    grpPPreview: TRzGroupBox;
    RzPanel17: TRzPanel;
    DongaPat: TDongaPat;
    grpResiPList: TRzGroupBox;
    HdrTimes: THeader;
    lnSigoff1: TRzLine;
    lnSigoff2: TRzLine;
    pnlPatGrp: TPanel;
    pnlPatternName: TPanel;
    pnlAging: TPanel;
    tmAging: TTimer;
    gridPatternList: TAdvStringGrid;
    btnVirSerial: TBitBtn;
    pnlErrAlram: TAdvPanel;
    pnlErrAlramMsg: TPanel;
    pnl2: TPanel;
    RzPanel4: TRzPanel;
    btnErrorDisplay: TRzButton;
    btnRetry: TRzButton;
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnErrorDisplayClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCh2Click(Sender: TObject);
    procedure RzBitBtn7Click(Sender: TObject);
    procedure RzBitBtn8Click(Sender: TObject);
    procedure btnSWCancel1Click(Sender: TObject);
    procedure btnSWNext1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrDisplayOffTimer(Sender: TObject);
    procedure gridPatternListClick(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
    procedure btnAutoClick(Sender: TObject);
    procedure btnRepeatClick(Sender: TObject);
    procedure btnCh4Click(Sender: TObject);
    procedure btnVirSerialClick(Sender: TObject);
    procedure btnRetryClick(Sender: TObject);
  private
    { Private declarations }

    m_nCurStatus   : Integer;

    pnlJig         : TRzPanel;
    m_nOkCnt, m_nNgCnt : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of integer;
    m_nTotalTact   :  Integer;
    tmTotalTactTime  :  TTimer;
    pnlJigInform   :  TRzPanel;

    btnStartTest   :  TRzBitBtn;
    btnStopTest    :  TRzBitBtn;
    btnVirtualKey  :  TRzBitBtn;
    // tact time.
    pnlTackTimes   :  TRzPanel;
    pnlNowValues   :  TPanel;
//    pnlAvgNames    :  TRzPanel;
//    pnlAvgValues   :  TPanel;


    lstPwrView     : TAdvListView;

    mmChannelLog   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of   TMemo;

    // OK NG count.
    pnlTotalNames  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlTotalValues : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlOKNames     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlOKValues    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlNGNames     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlNGValues    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlChGrp       : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    ledPGStatuses  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of ThhALed;
    pnlHwVersion   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    chkChannelUse  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzCheckBox;
    pnlSerials     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    pnlSerials2    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    pnlMESResults  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlPGStatuses  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlTimeNResult : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;

    gridPWRPGs     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TAdvStringGrid;



    procedure CreateGui(nChCount : Integer);
    procedure OnTotalTimer(Sender : TObject);
    procedure BtnStartTestClick(Sender: TObject);
    procedure BtnStopTestClick(Sender: TObject);
    procedure btnVirtualKeyClick(Sender : TObject);
    procedure chkPgClick(Sender: TObject);
    procedure RevSwDataJig(sGetData : String);
    procedure DisplayPGStatus(nPgNo, nType : Integer; sMsg : string);
    procedure DisplayPwrData(nPgNo: Integer; PwrData: ReadVoltCurr);
//    procedure DisplaySeq;
    procedure getBcrData(sScanData : string);
    procedure getAutoBcrData(sOriginalBcr : string; wCh : Word);
    procedure ClearChData(nCh : Integer);
    Function DisplayPatList(sPatGrpName : string) : TPatterGroup;
    procedure UpdatePtList;

//    procedure ShowAgingTime(nTime : Integer);
  public
    { Public declarations }
    pnlJigTact     : TPanel;
    DongaSwitch     : TSerialSwitch;
    procedure ShowGui(hMain : HWND);
    procedure SetHandleAgain(hMain : HWND);
    procedure DisplaySysInfo;
    procedure SetConfig;
    procedure SetBcrData;
    procedure SetAutoBcrData;
//    procedure SetLanguage(nIdx : Integer);
  end;

var
  frmTest4Ch: TfrmTest4Ch;

implementation

{$R *.dfm}
{$R+}

{ TfrmTest4Ch }

procedure TfrmTest4Ch.btnErrorDisplayClick(Sender: TObject);
begin
  pnlErrAlram.Visible := False;
end;

procedure TfrmTest4Ch.btnRepeatClick(Sender: TObject);
begin
//  JigLogic[Self.Tag].StartIspd_A_Repeat;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_3);
end;

procedure TfrmTest4Ch.btnRetryClick(Sender: TObject);
begin
  // Power Off 하고 Next Button 누른 동작 해야하는데
  // Next가 안됨...

  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_STOP);
  Common.Delay(3000);
  Common.MLog(0,'Retry Start');
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_9);
  pnlErrAlram.Visible := False;
end;

procedure TfrmTest4Ch.BtnStartTestClick(Sender: TObject);
begin
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_START);

end;

procedure TfrmTest4Ch.BtnStopTestClick(Sender: TObject);
begin
  JigLogic[Self.Tag].StopIspd_A;
end;

procedure TfrmTest4Ch.btnSWCancel1Click(Sender: TObject);
begin
  JigLogic[Self.Tag].StopIspd_A;
end;

procedure TfrmTest4Ch.btnSWNext1Click(Sender: TObject);
begin
//  pnlErrAlram.Visible := True;
//  Pg[0].TestFunc;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_9);
end;

procedure TfrmTest4Ch.btnVirSerialClick(Sender: TObject);
var
  sTempBcr : string;
  sTempPID : string;
  i : integer;
begin
  sTempBcr := '';
  sTempPID := '';
//  for i := 1 to 200 do begin
//    sTempPID := sTempPID + 'A';//chr(i);
//  end;

  // MES Test 진행했던 PID,ZIG ID
  sTempPID := 'FXT813155XRJJLQ6U+12020107711164075835760913+GH38196000GHYC43W+E2EH830S08A1000Z1AV1+81850076HYC532NC1MC1GJ6811409H0J68W1M8301S733A3DTWQ130089VJK6X2A0R300F441M358136YGVSCC84B03A1GC0G4N81530475300000000';
  if Common.SystemInfo.UseAutoBCR then sTempBcr := 'HND818P200003819'
  else                                 sTempBcr := 'HND818P2000036640000';

  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if not Logic[i].m_bUse then Continue;
    if (pnlSerials[i].Caption <> '') then Continue;
    Break;
  end;

  if Common.SystemInfo.UseAutoBCR then begin
    if sTempBcr <> '' then begin
      getAutoBcrData(sTempBcr,UPPER_AUTO_BCR);
    end;
    if sTempPID <> '' then begin
      getAutoBcrData(sTempPID,LOWER_AUTO_BCR);
    end;
  end
  else begin
    if sTempBcr <> '' then getBcrData(sTempBcr);
  end;
end;

procedure TfrmTest4Ch.btnVirtualKeyClick(Sender: TObject);
begin
  pnlSwitch.Visible := not pnlSwitch.Visible;
  pnlSwitch.Left := btnVirtualKey.Left;
  pnlSwitch.Top  := btnVirtualKey.Top + btnVirtualKey.Height;
end;

procedure TfrmTest4Ch.chkPgClick(Sender: TObject);
var
  i : integer;
  wCh : word;
  sTemp : string;
begin
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if Sender = chkChannelUse[i] then begin
      if chkChannelUse[i].Checked then  chkChannelUse[i].Font.Color := clGreen
      else                              chkChannelUse[i].Font.Color := clRed;
      Logic[i+self.Tag*4].m_bUse := chkChannelUse[i].Checked;
      PasScr[i+self.Tag*4].m_bUse := chkChannelUse[i].Checked;
      Break;
    end;
  end;

  if JigLogic[Self.Tag] <> nil then begin
    sTemp := '';
    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      if Common.SystemInfo.ChCountUsed < (i+1) then Continue;

      if chkChannelUse[i].Checked then sTemp := sTemp + Format('%d',[i+1]);

    end;
//    JigLogic[Self.Tag].EnableChannels := sTemp;
  end;
  wCh := 0;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if Logic[i] = nil then Exit;
    if Logic[i].m_bUse then wCh := wCh + (1 shl i);
  end;
//  if PlcCtl <> nil then  PlcCtl.m_nUseCh := wCh;

end;

procedure TfrmTest4Ch.ClearChData(nCh: Integer);
var
  i: Integer;
begin

  pnlSerials[nCh].Caption := '';
  pnlSerials2[nCh].Caption := '';
  pnlMESResults[nCh].Caption := '';
  pnlPGStatuses[nCh].Caption := 'Ready';
  if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
    pnlMESResults[nCh].Color := clBlack;
    pnlPGStatuses[nCh].Color := clBlack;
  end
  else begin
    pnlMESResults[nCh].Color := clBtnFace;
    pnlPGStatuses[nCh].Color := clBtnFace;
  end;

  gridPWRPGs[nCh].ClearAll;
  gridPWRPGs[nCh].ColumnHeaders.Add('');
  gridPWRPGs[nCh].ColumnHeaders.Add('Voltage');
  gridPWRPGs[nCh].ColumnHeaders.Add('Current');
  gridPWRPGs[nCh].ColumnHeaders.Add('');
  gridPWRPGs[nCh].ColumnHeaders.Add('Voltage');
  gridPWRPGs[nCh].ColumnHeaders.Add('Current');
  gridPWRPGs[nCh].Cells[0,1] := 'VCI';
  gridPWRPGs[nCh].Cells[0,2] := 'DVDD';
  gridPWRPGs[nCh].Cells[0,3] := 'VDD';
  gridPWRPGs[nCh].Cells[0,4] := 'VPP';
  gridPWRPGs[nCh].Cells[0,5] := 'VBAT';
  gridPWRPGs[nCh].Cells[0,6] := 'VNEG';

//  gridPWRPGs[nCh].Cells[3,1] := 'VCI';
//  gridPWRPGs[nCh].Cells[3,2] := 'VDDEL';
//  gridPWRPGs[nCh].Cells[3,3] := 'VSSEL';
//  gridPWRPGs[nCh].Cells[3,4] := 'DDVDH';
  mmChannelLog[nCh].Clear;

  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    FillChar(Logic[i].m_Inspect, SizeOf(TInspectionInfo), 0);
  end;
end;

procedure TfrmTest4Ch.CreateGui(nChCount : Integer);
var
  i, nItemHeight, nItemWidth : Integer;
  nFontSize : Integer;
  sTemp : string;
begin

  // Main Jig form Create.
  pnlJig         := TRzPanel.Create(self);
  pnlJig.Align   := alLeft;
  pnlJig.Parent  := RzPanel2;
  pnlJig.Font.Name := 'Tahoma';
  pnlJig.BorderOuter := TframeStyleEx(fsFlat);
  pnlJig.DisableAlign;
  pnlJig.Width   := 200;

  pnlJig.Visible := False;

  nItemHeight := 26;

//  // tact time을 위한 timer.
  m_nTotalTact:= 0;
  tmTotalTactTime := TTimer.Create(Self);
  tmTotalTactTime.Interval := 1000;
  tmTotalTactTime.OnTimer := OnTotalTimer;
  tmTotalTactTime.Enabled := False;
//  m_nUnitTact := 0;
//  tmUnitTactTime := TTimer.Create(Self);
//  tmUnitTactTime.Interval := 1000;
//  tmUnitTactTime.OnTimer  := OnUnitTimer;
//  tmUnitTactTime.Enabled := False;

  // Jig 정보를 위한 Panel.
  pnlJigInform := TRzPanel.Create(self);
  pnlJigInform.Parent := pnlJig;
  pnlJigInform.Top := 2;
  pnlJigInform.Left := 0;
  pnlJigInform.Height := pnlJig.Height;
  pnlJigInform.Width := 190;// pnlJig[nJig].Width div nMaxCh;
  pnlJigInform.Font.Size := 8;
  pnlJigInform.Align := alLeft;
  pnlJigInform.Font.Color  := clBlack;
  pnlJigInform.Alignment := taRightJustify;
  pnlJigInform.Caption := '';
  pnlJigInform.BorderOuter := TframeStyleEx(fsFlat);



  // Jig 정보를 위한 Panel.
//  pnlJigTitle := TPanel.Create(self);
//  pnlJigTitle.Parent := pnlJigInform;
//  pnlJigTitle.Top := 2;
//  pnlJigTitle.Left := 2;
//  pnlJigTitle.Height := 40;
//  pnlJigTitle.Width := 140;// pnlJig[nJig].Width div nMaxCh;
//  pnlJigTitle.Font.Size := 16;
//  pnlJigTitle.Color := clBlack;
//  pnlJigTitle.Font.Color  := clAqua;
//  pnlJigTitle.Alignment := taLeftJustify;
//  pnlJigTitle.Caption := Format(' Stage %d',[1+Self.Tag]);
////  if Common.SystemInfo.UIType = DefCommon.UI_BLACK then begin
//    pnlJigTitle.StyleElements := [];
////  end
////  else begin
////    pnlJigTitle.StyleElements := [seFont, seClient, seBorder];
////  end;

  // button for start testing.
  btnStartTest := TRzBitBtn.Create(self);
  btnStartTest.Parent := pnlJigInform;
  btnStartTest.Top := 2;    //pnlJigTitle.Top + pnlJigTitle.Height + 1;//
  btnStartTest.Left := 2;//100;
  btnStartTest.Height := 60;
  btnStartTest.Width := 90;// pnlJig[nJig].Width div nMaxCh;
  btnStartTest.Font.Size := 12;
  btnStartTest.Cursor := crHandPoint;
  btnStartTest.HotTrack := True;
  btnStartTest.Caption := 'bắt đầu (START)';
  btnStartTest.OnClick := BtnStartTestClick;

  // button for start testing.
  btnStopTest := TRzBitBtn.Create(self);
  btnStopTest.Parent := pnlJigInform;
  btnStopTest.Top := 2; //pnlJigTitle.Top + pnlJigTitle.Height + 1;//
  btnStopTest.Left := 94;//200;
  btnStopTest.Height := 60;
  btnStopTest.Width := 90;// pnlJig[nJig].Width div nMaxCh;
  btnStopTest.Font.Size := 12;
  btnStopTest.HotTrack := True;
  btnStopTest.Caption := 'Dừng lại (STOP)';
  btnStopTest.OnClick := BtnStopTestClick;
  btnStopTest.Cursor := crHandPoint;

  // for Jig Information.
  pnlTackTimes := TRzPanel.Create(self);
  pnlTackTimes.Parent := pnlJigInform;
  pnlTackTimes.Top := btnStartTest.Top + btnStartTest.Height + 1;//pnlPGStatuses[nJig].Top + pnlPGStatuses[nJig].Height;
  pnlTackTimes.Left := 2;
  pnlTackTimes.Height := nItemHeight;
  pnlTackTimes.Width := 90;//66;
  pnlTackTimes.Caption := 'Total Tact';
  pnlTackTimes.BorderOuter := TframeStyleEx(fsFlat);
  pnlTackTimes.Font.Size := 12;

  pnlNowValues := TPanel.Create(self);
  pnlNowValues.Parent := pnlJigInform;
  pnlNowValues.Top := pnlTackTimes.Top;
  pnlNowValues.Left := pnlTackTimes.Left + pnlTackTimes.Width + 1;
  pnlNowValues.Height := nItemHeight;
  pnlNowValues.Width := 90;
  pnlNowValues.Caption := '00 : 00';
  pnlNowValues.Color := clBlack;
  pnlNowValues.Font.Color := clLime;
  pnlNowValues.Font.Size := 12;
  pnlNowValues.StyleElements := [];

  // button for start testing.
  btnVirtualKey := TRzBitBtn.Create(self);
  btnVirtualKey.Parent := pnlJigInform;
  btnVirtualKey.Top := pnlNowValues.Top + pnlNowValues.Height + 1;//2;
  btnVirtualKey.Left := 2;//200;
  btnVirtualKey.Height := 30;
  btnVirtualKey.Width := 180;// pnlJig[nJig].Width div nMaxCh;
  btnVirtualKey.Font.Size := 12;
  btnVirtualKey.Caption := 'phím ảo (Virtual Key)';
  btnVirtualKey.OnClick := btnVirtualKeyClick;
  btnVirtualKey.Cursor := crHandPoint;
  btnVirtualKey.HotTrack := True;

  lstPwrView := TAdvListView.Create(self);
  lstPwrView.Parent := pnlJigInform;
  lstPwrView.Top := btnVirtualKey.Top +  btnVirtualKey.Height + 1;
  lstPwrView.Left := 2;
  lstPwrView.Height := nItemHeight*5;
  lstPwrView.Width := 180;
  lstPwrView.Font.Size := 8;
  lstPwrView.ViewStyle := vsReport;
  lstPwrView.Columns.Add.Caption := 'Power';
  lstPwrView.Columns.Add.Caption := 'Voltage';
  lstPwrView.Columns[0].Width := 60;
  lstPwrView.Columns[1].Width := 100;
  with lstPwrView do begin
    with Items.Add do begin
      Caption := 'VCI';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VCI] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'DVDD';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_DVDD] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VDD';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VDD] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VPP';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VPP] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VBAT';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VBAT] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VNEG';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VNEG] / 100]);
      SubItems.Add(sTemp);
    end;
  end;
  if nChCount < 3 then begin
    nItemWidth := RzPanel2.Width div 2;
  end
  else begin
    nItemWidth := RzPanel2.Width div (nChCount);
  end;

  // detailed items for each channel.
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    pnlChGrp[i] := TRzPanel.Create(self);
    pnlChGrp[i].Parent := RzPanel1;
    pnlChGrp[i].Top := 2;
    pnlChGrp[i].Height := pnlJig.Height;
    pnlChGrp[i].Width := nItemWidth;
    pnlChGrp[i].Font.Size := 8;
    pnlChGrp[i].Left := nItemWidth * i + pnlJigInform.Width;
    pnlChGrp[i].Align := alLeft;
    pnlChGrp[i].Font.Color  := clBlack;
    pnlChGrp[i].Alignment := taRightJustify;
    pnlChGrp[i].Caption := '';
    pnlChGrp[i].BorderOuter := TframeStyleEx(fsFlat);
    pnlChGrp[i].Visible := False;

    pnlHwVersion[i] := TRzPanel.Create(self);
    pnlHwVersion[i].Parent := pnlChGrp[i];
    pnlHwVersion[i].Top := 2;
    pnlHwVersion[i].Height := nItemHeight;
    pnlHwVersion[i].Font.Size := 8;
    pnlHwVersion[i].Align := alTop;
    pnlHwVersion[i].Font.Color  := clBlack;
    pnlHwVersion[i].Alignment := taRightJustify;
    pnlHwVersion[i].Caption := '';
    pnlHwVersion[i].BorderOuter := TframeStyleEx(fsFlat);

    ledPGStatuses[i] := ThhALed.Create(self);
    ledPGStatuses[i].Parent := pnlHwVersion[i];
    ledPGStatuses[i].LEDStyle := LEDSqLarge;
    ledPGStatuses[i].Blink    := False;
    ledPGStatuses[i].Top := 3;
    ledPGStatuses[i].Left := 4;

    chkChannelUse[i] := TRzCheckBox.Create(self);
    chkChannelUse[i].Parent := pnlChGrp[i];
    chkChannelUse[i].CustomGlyphs.Assign(imgCheckBox.Picture.Bitmap);// := bmp;
    chkChannelUse[i].Top := pnlHwVersion[i].Top + pnlHwVersion[i].Height;
    chkChannelUse[i].Height := nItemHeight;
    chkChannelUse[i].Align := alTop;
    chkChannelUse[i].AutoSize := False;
    chkChannelUse[i].OnClick := chkPgClick;
    chkChannelUse[i].Caption := Format('kênh (Channel) %d',[i+1+self.Tag*4]);//Format('Channel %d',[i+1+self.Tag*4]);
    chkChannelUse[i].AlignmentVertical := TAlignmentVertical(avCenter);
    chkChannelUse[i].Font.Size := 12;
//    chkChannelUse[i].State := cbChecked;
    chkChannelUse[i].Font.Color := clGreen;
    chkChannelUse[i].Cursor := crHandPoint;

    pnlSerials[i] := TRzPanel.Create(self);
    pnlSerials[i].Parent := pnlChGrp[i];
    pnlSerials[i].Top := chkChannelUse[i].Top + chkChannelUse[i].Height;
    pnlSerials[i].Height := nItemHeight;
    pnlSerials[i].Align := alTop;
    pnlSerials[i].Color := clBtnFace;
    pnlSerials[i].Hint  := 'Serial Number';
    pnlSerials[i].ShowHint  := True;
    pnlSerials[i].Alignment := taCenter;
    pnlSerials[i].WordWrap  := True;
    pnlSerials[i].Font.Name := 'Tahoma';
    pnlSerials[i].Caption := '';//Format('23020218LN36A308416900A2%sC231369V16A3169WFB0000%d',[chr(10),i]);
    pnlSerials[i].BorderOuter := TframeStyleEx(fsFlat);

    if Common.SystemInfo.UseAutoBCR then begin
      pnlSerials2[i] := TRzPanel.Create(self);
      pnlSerials2[i].Parent := pnlChGrp[i];
      pnlSerials2[i].Top := pnlChGrp[i].Height;
      pnlSerials2[i].Height := nItemHeight;
      pnlSerials2[i].Align := alTop;
      pnlSerials2[i].Color := clBtnFace;
      pnlSerials2[i].Hint  := 'Serial Number2';
      pnlSerials2[i].ShowHint  := True;
      pnlSerials2[i].Alignment := taCenter;
      pnlSerials2[i].WordWrap  := True;
      pnlSerials2[i].Font.Name := 'Tahoma';
      pnlSerials2[i].Caption := '';//Format('23020218LN36A308416900A2%sC231369V16A3169WFB0000%d',[chr(10),i]);
      pnlSerials2[i].BorderOuter := TframeStyleEx(fsFlat);
    end;

    pnlMESResults[i] := TPanel.Create(self);
    pnlMESResults[i].Parent := pnlChGrp[i];
//    pnlMESResults[i].Top := pnlSerials[i].Top + pnlSerials[i].Height;
    pnlMESResults[i].Top := pnlChGrp[i].Height;
    pnlMESResults[i].Height := nItemHeight;
    pnlMESResults[i].Align := alTop;
    pnlMESResults[i].Caption := '';
    pnlMESResults[i].Hint := 'MES Result';
    pnlMESResults[i].ShowHint := True;
    pnlMESResults[i].Font.Size := 10;
    pnlMESResults[i].ParentBackground := False;
    pnlMESResults[i].StyleElements := [];
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlMESResults[i].Color := clBlack;
      pnlMESResults[i].Font.Color := clWhite;
    end
    else begin
      pnlMESResults[i].Font.Color := clBlack;
    end;
//    pnlMESResults[i].BorderOuter := TframeStyleEx(fsFlat);

    pnlPGStatuses[i] := TPanel.Create(Self);
    pnlPGStatuses[i].Parent := pnlChGrp[i];
//    pnlPGStatuses[i].Top := pnlMESResults[i].Top + pnlMESResults[i].Height;
    pnlPGStatuses[i].Top := pnlChGrp[i].Height;
    pnlPGStatuses[i].Align := alTop;
    pnlPGStatuses[i].Caption := 'Ready';
    pnlPGStatuses[i].Hint := 'PG Status';
    pnlPGStatuses[i].ShowHint := True;
    pnlPGStatuses[i].Color := clBtnFace;
    pnlPGStatuses[i].Font.Size := 14;
    pnlPGStatuses[i].ParentBackground := False;
    pnlPGStatuses[i].StyleElements := [];
//    pnlPGStatuses[i].BorderOuter := TframeStyleEx(fsFlat);
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlPGStatuses[i].Color := clBlack;
      pnlPGStatuses[i].Font.Color := clWhite;
//      pnlPGStatuses[i].StyleElements := [];
    end
    else begin
//      pnlPGStatuses[i].StyleElements := [];//[seFont, seClient, seBorder];
      pnlPGStatuses[i].Font.Color := clBlack;
    end;

    // only for result.
    pnlTimeNResult[i] := TRzPanel.Create(self);
    pnlTimeNResult[i].Parent := pnlChGrp[i];
//    pnlTimeNResult[i].Top := pnlPGStatuses[i].Top + pnlPGStatuses[i].Height;
    pnlTimeNResult[i].Top := pnlChGrp[i].Height;
    pnlTimeNResult[i].Height := nItemHeight+4;
    pnlTimeNResult[i].Align := alTop;
    pnlTimeNResult[i].BorderOuter := TframeStyleEx(fsFlat);

    nFontSize := 10;

    pnlTotalNames[i] := TPanel.Create(self);
    pnlTotalNames[i].Parent := pnlTimeNResult[i];
    pnlTotalNames[i].Top := 1;
    pnlTotalNames[i].Left := 2;
    pnlTotalNames[i].Height := pnlTimeNResult[i].Height;
    pnlTotalNames[i].Width := 36;
    pnlTotalNames[i].Caption := 'Total';
    pnlTotalNames[i].Font.Size := 10;
//
    pnlTotalValues[i] := TPanel.Create(self);
    pnlTotalValues[i].Parent := pnlTimeNResult[i];
    pnlTotalValues[i].Top := 1;
    pnlTotalValues[i].Left := pnlTotalNames[i].Left + pnlTotalNames[i].Width + 1;
    pnlTotalValues[i].Height :=  pnlTimeNResult[i].Height-2;
    pnlTotalValues[i].Width := 57;
    pnlTotalValues[i].Caption := '0';
    pnlTotalValues[i].Font.Size := pnlTotalNames[i].Font.Size;
    pnlTotalValues[i].Color := clBlack;
    pnlTotalValues[i].Font.Color := clYellow;
    pnlTotalValues[i].StyleElements := [];


    pnlOKNames[i] := TPanel.Create(Self);
    pnlOKNames[i].Parent := pnlTimeNResult[i];
    pnlOKNames[i].Top := 1;
    pnlOKNames[i].Left := pnlTotalValues[i].Left + pnlTotalValues[i].Width + 1;
    pnlOKNames[i].Height := pnlTimeNResult[i].Height;
    pnlOKNames[i].Width := 30;
    pnlOKNames[i].Caption := 'OK';
    pnlOKNames[i].Font.Size := nFontSize;

    pnlOKValues[i] := TPanel.Create(Self);
    pnlOKValues[i].Parent := pnlTimeNResult[i];
    pnlOKValues[i].Top := 1;
    pnlOKValues[i].Left := pnlOKNames[i].Left + pnlOKNames[i].Width + 1;
    pnlOKValues[i].Height := pnlTimeNResult[i].Height-2;
    pnlOKValues[i].Width := 57;
    pnlOKValues[i].Color := clBlack;
    pnlOKValues[i].Caption := '0';
    pnlOKValues[i].Font.Size := nFontSize;
    pnlOKValues[i].Font.Color := clLime;
    pnlOKValues[i].StyleElements := [];


    pnlNGNames[i] := TPanel.Create(Self);
    pnlNGNames[i].Parent := pnlTimeNResult[i];
    pnlNGNames[i].Top := 1;
    pnlNGNames[i].Left := pnlOKValues[i].Left + pnlOKValues[i].Width + 1;
    pnlNGNames[i].Height := pnlTimeNResult[i].Height;
    pnlNGNames[i].Width := 30;
    pnlNGNames[i].Font.Size := nFontSize;
    pnlNGNames[i].Caption := 'NG';

    pnlNGValues[i] := TPanel.Create(Self);
    pnlNGValues[i].Parent := pnlTimeNResult[i];
    pnlNGValues[i].Top := 1;
    pnlNGValues[i].Left := pnlNGNames[i].Left + pnlNGNames[i].Width + 1;
    pnlNGValues[i].Height := pnlTimeNResult[i].Height-2;
    pnlNGValues[i].Width := 57;
    pnlNGValues[i].Color := clBlack;
    pnlNGValues[i].Caption := '0';
    pnlNGValues[i].Font.Size := nFontSize;
    pnlNGValues[i].Font.Color := clRed;
    pnlNGValues[i].StyleElements := [];

    gridPWRPGs[i] := TAdvStringGrid.Create(self);
    gridPWRPGs[i].Clear;
    gridPWRPGs[i].Parent := pnlChGrp[i];
    gridPWRPGs[i].Font.Name := 'Tahoma';
    gridPWRPGs[i].Top := 275;
    gridPWRPGs[i].Height := 112;//114;//184;
    gridPWRPGs[i].Align := alTop;
    gridPWRPGs[i].ColCount := 3;
    gridPWRPGs[i].RowCount := 6;
    gridPWRPGs[i].FixedCols := 0;
    gridPWRPGs[i].ColumnHeaders.Add('');
    gridPWRPGs[i].ColumnHeaders.Add('V'{'Voltage'});
    gridPWRPGs[i].ColumnHeaders.Add('mA'{'Current'});

    gridPWRPGs[i].ColWidths[0] := 60; //32;
    gridPWRPGs[i].ColWidths[1] := 60;//56;
    gridPWRPGs[i].ColWidths[2] := 60;//56;
    gridPWRPGs[i].Cells[0,1] := 'VCI';
    gridPWRPGs[i].Cells[0,2] := 'DVDD';
    gridPWRPGs[i].Cells[0,3] := 'VDD';
    gridPWRPGs[i].Cells[0,4] := 'VPP';
    gridPWRPGs[i].Cells[0,5] := 'VBAT';

    gridPWRPGs[i].DefaultRowHeight := 18;
    gridPWRPGs[i].DefaultAlignment := taCenter;
    mmChannelLog[i] := TMemo.Create(self);
    mmChannelLog[i].Parent := pnlChGrp[i];
    mmChannelLog[i].Align := alClient;
    mmChannelLog[i].ScrollBars := ssVertical;

    if nChCount > i then begin
      pnlChGrp[i].Visible := True;
    end;


  end;
  pnlErrAlram.Parent := self; // 화면 뒤에 있지 않도록 Parent를 변경.
  pnlSwitch.Parent := self;   // 화면 뒤에 있지 않도록 Parent를 변경.

  btnAuto.Caption := 'Auto';
  btnRepeat.Caption := 'Repeat';

  pnlSwitch.Visible := False;
//  SetLanguage(common.SystemInfo.Language);
  pnlJig.EnableAlign;
  pnlJig.Visible := True;
end;

function TfrmTest4Ch.DisplayPatList(sPatGrpName: string): TPatterGroup;
var
  CurPatGrp   : TPatterGroup;
  i           : Integer;
begin
  gridPatternList.RowCount := 1;
  gridPatternList.ColCount := 3;
//  gridPatternList.Rows[0].Clear;
  gridPatternList.ColWidths[1] := 232;
  gridPatternList.ColWidths[2] := 100;
  gridPatternList.Cols[0].Clear;
  gridPatternList.Cols[1].Clear;
  gridPatternList.Cols[2].Clear;
//  sPatGrpName := DongaYT.ModelInfo.PatGrFuse;
  CurPatGrp   := Common.LoadPatGroup(sPatGrpName);
  gridPatternList.HideColumn(0);
//  gridPatternList.HideColumn(2);
//  gridPatternList.HideColumn(3);
//  gridPatternList.HideColumn(4);

  pnlPatGrp.Caption := sPatGrpName;
  pnlPatGrp.Update;
  if CurPatGrp.PatCount > 0 then begin
    gridPatternList.RowCount := CurPatGrp.PatCount;
    for i := 0 to pred(CurPatGrp.PatCount) do begin
      gridPatternList.Cells[0, i] := Format('%d',[CurPatGrp.PatType[i]]);
      gridPatternList.Cells[1, i] := String(CurPatGrp.PatName[i]);
      gridPatternList.Cells[2, i] := '';//Common.SetTimeToStr(CurPatGrp.LockTime[i]);
    end;
  end;

  gridPatternList.Row := 0;
  Result  := CurPatGrp;
end;

procedure TfrmTest4Ch.DisplayPGStatus(nPgNo, nType: Integer; sMsg: string);
var
  nCh : Integer;
begin
  nCh := nPgNo mod 4;
  try
    case nType of
      0 : ledPGStatuses[nCh].Value := True;
      1 : pnlHwVersion[nCh].Caption := sMsg;
      2 : begin
        ledPGStatuses[nCh].FalseColor := clRed;
        ledPGStatuses[nCh].Value := False;
        pnlHwVersion[nCh].Caption := '';
      end;
    end;
  except
    Common.DebugMessage('>> DisplayPGStatus Exception Error! ' + IntToStr(nPgNo+1));
  end;
end;

procedure TfrmTest4Ch.DisplayPwrData(nPgNo: Integer; PwrData: ReadVoltCurr);
begin
  gridPWRPGs[nPgNo].DisableAlign;
  // voltage.
  gridPWRPGs[nPgNo].Cells[1,1] := Format('%0.3f',[PwrData.VCI   / 1000]);
  gridPWRPGs[nPgNo].Cells[1,2] := Format('%0.3f',[PwrData.DVDD  / 1000]);
  gridPWRPGs[nPgNo].Cells[1,3] := Format('%0.3f',[PwrData.VDD   / 1000]);
  gridPWRPGs[nPgNo].Cells[1,4] := Format('%0.3f',[PwrData.VPP   / 1000]);
  gridPWRPGs[nPgNo].Cells[1,5] := Format('%0.3f',[PwrData.VBAT  / 1000]);
  gridPWRPGs[nPgNo].Cells[1,6] := Format('%0.3f',[PwrData.VNEG  / 1000]);
  // current.
  gridPWRPGs[nPgNo].Cells[2,1] := Format('%0.3f',[PwrData.IVCI  / 1000]);
  gridPWRPGs[nPgNo].Cells[2,2] := Format('%0.3f',[PwrData.IDVDD / 1000]);
  gridPWRPGs[nPgNo].Cells[2,3] := Format('%0.3f',[PwrData.IVDD  / 1000]);
  gridPWRPGs[nPgNo].Cells[2,4] := Format('%0.3f',[PwrData.IVPP  / 1000]);
  gridPWRPGs[nPgNo].Cells[2,5] := Format('%0.3f',[PwrData.IVBAT / 1000]);
  gridPWRPGs[nPgNo].Cells[2,6] := Format('%0.3f',[PwrData.IVNEG / 1000]);
  gridPWRPGs[nPgNo].EnableAlign;
end;

procedure TfrmTest4Ch.DisplaySysInfo;
var
  i, nPgNo: Integer;
begin
  for i := 0 to Pred(Common.SystemInfo.ChCountUsed) do begin
    nPgNo := i+self.Tag * 4;
    chkChannelUse[i].Checked := Common.SystemInfo.UseCh[nPgNo];
    Logic[nPgNo].m_bUse := Common.SystemInfo.UseCh[nPgNo];
    PasScr[nPgNo].m_bUse := Common.SystemInfo.UseCh[nPgNo];
  end;
end;

procedure TfrmTest4Ch.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if tmTotalTactTime <> nil then begin
    tmTotalTactTime.Enabled := False;
    tmTotalTactTime.Free;
    tmTotalTactTime := nil;
  end;
//  if tmUnitTactTime <> nil then begin
//    tmUnitTactTime.Enabled := False;
//    tmUnitTactTime.Free;
//    tmUnitTactTime := nil;
//  end;
end;

procedure TfrmTest4Ch.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  m_nCurStatus := DefScript.SEQ_STOP;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    m_nOkCnt[i] := 0;
    m_nNgCnt[i] := 0;
  end;
  DongaPat.DongaImgWidth  := DongaPat.Width;
  DongaPat.DongaImgHight  := DongaPat.Height;
  DongaPat.DongaPatPath   := Common.Path.Pattern;// DongaYT.m_sPatFilePath;
  DongaPat.DongaBmpPath   := Common.Path.BMP;// DongaYT.m_sBmpPath;
  DongaPat.LoadPatFile('No Signal');
  DongaPat.LoadAllPatFile;

  if Common.SystemInfo.UIType = DefCommon.UI_WIN10_NOR then begin
    lnSigoff1.Font.Color := clBlack;
    lnSigoff2.Font.Color := clBlack;
  end
  else begin
    lnSigoff1.Font.Color := clYellow;
    lnSigoff2.Font.Color := clYellow;
  end;
end;

procedure TfrmTest4Ch.FormDestroy(Sender: TObject);
begin
  if DongaSwitch <> nil then begin
    DongaSwitch.Free;
    DongaSwitch := nil;
  end;
  if JigLogic[Self.Tag] <> nil then begin
    JigLogic[Self.Tag].Free;
    JigLogic[Self.Tag] := nil;
  end;
end;

procedure TfrmTest4Ch.getAutoBcrData(sOriginalBcr: string; wCh: Word);
begin
  if wCh = UPPER_AUTO_BCR then begin  // JigID
    if (pnlSerials[DefCommon.CH1].Caption = '') and (chkChannelUse[DefCommon.CH1].Checked) then begin
      pnlSerials[DefCommon.CH1].Caption := sOriginalBcr;
      Common.MLog(DefCommon.CH1, 'Zig ID : ' + sOriginalBcr);
      Logic[DefCommon.CH1].m_Inspect.ZigId := sOriginalBcr;
    end;
  end
  else if wCh = LOWER_AUTO_BCR then begin  // PID
    if (pnlSerials2[DefCommon.CH1].Caption = '') and (chkChannelUse[DefCommon.CH1].Checked) then begin
      pnlSerials2[DefCommon.CH1].Caption := sOriginalBcr;
      Common.MLog(DefCommon.CH1, 'Panel ID : ' + sOriginalBcr);
      Logic[DefCommon.CH1].m_Inspect.SerialNo := sOriginalBcr;
    end;
  end;

  // 상부, 하부 둘다 입력 받았는지 확인
  if (Logic[DefCommon.CH1].m_Inspect.ZigId <> '') and (Logic[DefCommon.CH1].m_Inspect.SerialNo <> '') then begin
    // PID barcode 자릿수 체크. 180 혹은 200 일때 OK //
    if (Common.SystemInfo.ZIGLengthLimit > 0) and
       (Logic[DefCommon.CH1].m_Inspect.ZigId.Length <> Common.SystemInfo.ZIGLengthLimit) then begin
      pnlPGStatuses[DefCommon.CH1].Caption := 'ZIG ID Length NG';
      pnlPGStatuses[DefCommon.CH1].Color := clRed;
      pnlPGStatuses[DefCommon.CH1].Font.Color := clBlack;
    end;
    if not (Logic[DefCommon.CH1].m_Inspect.SerialNo.Length in [180,200]) then begin
      pnlPGStatuses[DefCommon.CH1].Caption := 'PID Length NG';
      pnlPGStatuses[DefCommon.CH1].Color := clRed;
      pnlPGStatuses[DefCommon.CH1].Font.Color := clBlack;
      Exit;
    end;

    Logic[DefCommon.CH1].m_Inspect.IsScanned := True;
    pasScr[DefCommon.CH1].SetBCRData;
    if DongaGmes is TGmes then begin
      DongaGmes.SendHostZset(Logic[DefCommon.CH1].m_Inspect.SerialNo, Logic[DefCommon.CH1].m_Inspect.ZigId);
    end
    else begin
    end;
  end;
end;

procedure TfrmTest4Ch.getBcrData(sScanData: string);
var
  i, nLastCh: Integer;
  bTemp : Boolean;
  sDebug, sData : string;
begin
  sDebug := 'BCR Checking.';
  bTemp := True;
  nLastCh := -1;
  sData := Trim(StringReplace(sScanData,#$A#$D, '', [rfReplaceAll]));
  for i := DefCommon.CH1 to Pred(Common.SystemInfo.ChCountUsed) do begin
    if (pnlSerials[i].Caption = '') and (chkChannelUse[i].Checked) and (Pg[i].Status = pgConnect) then begin
      pnlSerials[i].Caption := sData;
      if Common.SystemInfo.PIDLengthLimit > 0 then begin // 0 이면 Length Check 안함
        if sData.Length <> Common.SystemInfo.PIDLengthLimit then begin
          pnlPGStatuses[i].Caption := 'BCR Length NG';
          pnlPGStatuses[i].Color := clRed;
          pnlPGStatuses[i].Font.Color := clBlack;
          Exit;
        end;
      end;

      Logic[Self.Tag * 4 + i].m_Inspect.SerialNo := sData;
      Logic[Self.Tag * 4 + i].m_Inspect.IsScanned := True;
      bTemp := False;
      nLastCh := Self.Tag * 4 + i;
      Break;
    end;
  end;

  // Scan 됨 확인.
  if DongaGmes is TGmes then begin
    // 방금 Scan 됨을 확인.
    if not bTemp then begin
      if nLastCh > -1 then begin
        DongaGmes.SendHostPchk(sData,nLastCh);
        Exit;
      end;
    end;
  end;
end;

procedure TfrmTest4Ch.gridPatternListClick(Sender: TObject);
var
  nIdx, nPatType : Integer;
begin
  if gridPatternList.RowCount < 2 then begin
    if Trim(gridPatternList.Cells[1, 0]) = '' then Exit;
  end;
  nIdx := gridPatternList.Row;
  nPatType := StrToInt(gridPatternList.Cells[0, nIdx]);
  lnSigoff1.Visible := False;
  lnSigoff2.Visible := False;
  DongaPat.DrawPatAllPat(nPatType, gridPatternList.Cells[1, nIdx]);
  pnlPatternName.Caption := gridPatternList.Cells[1, nIdx];
end;

procedure TfrmTest4Ch.OnTotalTimer(Sender: TObject);
var
  nSec, nMin : Integer;
begin

  Inc(m_nTotalTact);
  nSec := m_nTotalTact mod 60;
  nMin := (m_nTotalTact div 60) mod 60;
  pnlNowValues.Caption := Format('%0.2d : %0.2d',[nMin, nSec]);
end;

procedure TfrmTest4Ch.RevSwDataJig(sGetData: String);
var
  nPos: Integer;
begin

  if Length(sGetData) < 4 then Exit;
  nPos := Pos('3',sGetData);
  CodeSite.Send(sGetData);
  case Byte(sGetData[nPos + 1]) of
    $4E : begin   // Next
//      pnlAging.Caption := '';
//      JigLogic[Self.Tag].StartIspd_A(Self.Handle);
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_9);//
    end;
    $42 : begin
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_8);
    end;
    $31 : begin
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_7);
    end;
    //5
    $33 : begin
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_5);
    end;
    //6
    $45 : begin  // POCB Disable.
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_6);
    end;
    // 1 Key
    $37 : begin
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_1);//.StartIspd_A_Auto;
    end;
    // 2 Key  (ESC)
    $38 : begin

      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_2);//StopIspd_A;
    end;
    // 3 Key
    $35 : begin
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_3);//StartIspd_A_Repeat;
    end;
    // 4 Key (BACK)
    $36 : begin
      // back ---
      JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_4);//NextIspd(False);
    end;
  end;
  // 순서대로 버튼 눌렀을때 데이터.
{
02 3F 33 4E 03 (02 3F 33 4E 03 )
02 3F 33 4E 03 (02 3F 33 4E 03 )
02 3F 33 31 03 (02 3F 33 31 03 )
02 3F 33 42 03 (02 3F 33 42 03 )
02 3F 33 33 03 (02 3F 33 33 03 )
02 3F 33 45 03 (02 3F 33 45 03 )
02 3F 33 35 03 (02 3F 33 35 03 )     //3
02 3F 33 36 03 (02 3F 33 36 03 )     //4
02 3F 33 37 03 (02 3F 33 37 03 )    //1
02 3F 33 38 03 (02 3F 33 38 03 )}   //2
end;

procedure TfrmTest4Ch.btnAutoClick(Sender: TObject);
begin
//  JigLogic[Self.Tag].StartIspd_A_Auto;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_1);
end;

procedure TfrmTest4Ch.btnCh2Click(Sender: TObject);
//var
//  i : Integer;
begin
//  i := Self.Tag*4 + 1;
//  Logic[i].StartEachCh(i);
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_8);
end;

procedure TfrmTest4Ch.btnCh4Click(Sender: TObject);
begin
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_7);
end;

procedure TfrmTest4Ch.RzBitBtn2Click(Sender: TObject);
begin
//  JigLogic[Self.Tag].NextIspd(False);
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_4);
end;

procedure TfrmTest4Ch.RzBitBtn7Click(Sender: TObject);
//var
//  i : Integer;
begin
//  for i := Self.Tag*4 to Pred(Self.Tag*4 + 4) do begin
//    Logic[i].EnablePocb(True);
//  end;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_5);
end;

procedure TfrmTest4Ch.RzBitBtn8Click(Sender: TObject);
//var
//  i : Integer;
begin
//  for i := Self.Tag*4 to Pred(Self.Tag*4 + 4) do begin
//    Logic[i].EnablePocb(False);
//  end;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_6);
end;

procedure TfrmTest4Ch.SetAutoBcrData;
var
  i : integer;
begin
  for i := UPPER_AUTO_BCR to LOWER_AUTO_BCR do begin
    if tcpAutoBCR[i] <> nil then
      tcpAutoBCR[i].OnRevBCRData := getAutoBcrData;
  end;
end;
procedure TfrmTest4Ch.SetBcrData;
begin
  DongaHandBcr.OnRevBcrData := getBcrData;
end;

procedure TfrmTest4Ch.SetConfig;
begin
//  DisplaySeq;
  DisplaySysInfo;
  if DongaSwitch is TSerialSwitch then begin
    DongaSwitch.ChangePort(Common.SystemInfo.Com_RCB1);
  end;
end;

procedure TfrmTest4Ch.SetHandleAgain(hMain: HWND);
begin
  JigLogic[Self.Tag].SetHandleAgain(hMain, Self.Handle);
end;

//procedure TfrmTest4Ch.SetLanguage(nIdx: Integer);
//var
//  i : Integer;
//begin
//  btnStartTest.Caption := 'bắt đầu (START)';
//  btnStopTest.Caption := 'Dừng lại (STOP)';
//  btnVirtualKey.Caption := 'phím ảo (Virtual Key)';
//  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//    chkChannelUse[i].Caption := Format('kênh (Channel) %d',[i+1+self.Tag*4]);//Format('Channel %d',[i+1+self.Tag*4]);
//    pnlTotalNames[i].Caption := 'Total';//'Product';
//  end;
//end;

//procedure TfrmTest4Ch.ShowAgingTime(nTime: Integer);
//var
//  nSec, nTemp, nMin, nHour : Integer;
//  sTime : string;
//begin
//  nSec  := nTime mod 60;  // 60초를 나눈 나머지가 Sec.
//  nTemp := nTime div 60;  // 60초를 나눈값 ==> Min.
//  nMin  := nTemp   mod 60;  //
//  nHour := nTemp   div 60;  //
//  sTime := Format('%0.2d : %0.2d : %0.2d',[nHour, nMin, nSec]);
//  pnlAging.Caption := sTime;
//end;

procedure TfrmTest4Ch.ShowGui(hMain : HWND);
begin
  DongaSwitch := TSerialSwitch.Create(hMain,Self.Tag);
  DongaSwitch.OnRevSwData := RevSwDataJig;
  CreateGui(Common.SystemInfo.ChCountUsed);
  JigLogic[Self.Tag] := TJig.Create(Self.Tag,hMain,Self.Handle, self);
  if DongaGmes is TGmes then begin
    DongaGmes.hMainHandle := Self.Handle;
  end;
  SetConfig;
  UpdatePtList;
end;

procedure TfrmTest4Ch.tmrDisplayOffTimer(Sender: TObject);
begin
  tmrDisplayOff.Enabled := False;
  pnlErrAlram.Visible := False;
end;

procedure TfrmTest4Ch.UpdatePtList;
var
  nCh : Integer;
  PatGrp : TPatterGroup;
begin
  PatGrp := DisplayPatList(Common.TestModelInfo2.PatGrpName);
  CopyMemory(@Pg[Self.Tag].DisPatStruct.PatInfo,@DongaPat.InfoPat,SizeOf(DongaPat.InfoPat));
//  JigLogic[DefCommon.JIG_A].PatGrp := PatGrp;
  for nCh := DefCommon.CH1 to Pred(Common.SystemInfo.ChCountUsed) do begin
    Logic[nCh].PatGrp := PatGrp;
    PasScr[nCh].GetPatGrp := PatGrp;
    PasScr[nCh].InitialScript;
  end;
end;

procedure TfrmTest4Ch.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, i, nTemp, nPatType : Integer;
  nParam, nParam2 : Integer;
  bTemp : Boolean;
  sMsg, sDebug, sTemp : string;
begin
  nType := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := (PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel) mod 4;

  case nType of
    DefCommon.MSG_TYPE_SCRIPT : begin
      nMode := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_CH_CLEAR : begin
          ClearChData(nCh);
        end;
        DefCommon.MSG_MODE_WORKING : begin
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);

          mmChannelLog[nCh].DisableAlign;
          sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
          mmChannelLog[nCh].Lines.Add(sDebug);
          Common.MLog(nCh+self.Tag*4,sMsg);
          mmChannelLog[nCh].EnableAlign;
        end;
        MSG_MODE_LOG_PWR : begin
          sDebug := '';
        {$IFDEF ISPD_A}
          sDebug := sDebug + Format('[%s : %fV, %fmA] ',[gridPWRPGs[nCh].Cells[0,1], StrToFloatDef(gridPWRPGs[nCh].Cells[1,1],0), StrToFloatDef(gridPWRPGs[nCh].Cells[2,1],0)]);
          sDebug := sDebug + Format('[%s : %fV, %fmA] ',[gridPWRPGs[nCh].Cells[0,2], StrToFloatDef(gridPWRPGs[nCh].Cells[1,2],0), StrToFloatDef(gridPWRPGs[nCh].Cells[2,2],0)]);
          sDebug := sDebug + Format('[%s : %fV, %fmA] ',[gridPWRPGs[nCh].Cells[0,3], StrToFloatDef(gridPWRPGs[nCh].Cells[1,3],0), StrToFloatDef(gridPWRPGs[nCh].Cells[2,3],0)]);
          sDebug := sDebug + Format('[%s : %fV, %fmA] ',[gridPWRPGs[nCh].Cells[0,4], StrToFloatDef(gridPWRPGs[nCh].Cells[1,4],0), StrToFloatDef(gridPWRPGs[nCh].Cells[2,4],0)]);
          sDebug := sDebug + Format('[%s : %fV, %fmA] ',[gridPWRPGs[nCh].Cells[0,5], StrToFloatDef(gridPWRPGs[nCh].Cells[1,5],0), StrToFloatDef(gridPWRPGs[nCh].Cells[2,5],0)]);
        {$ENDIF}
          Common.MLog(nCh+self.Tag*4,sDebug);
        end;
        DefCommon.MSG_MODE_POWER_ON : begin
          m_nTotalTact := 0;
          tmTotalTactTime.Enabled := True;
          pnlPGStatuses[nCh].Caption := 'Power On';
        end;
        DefCommon.MSG_MODE_POWER_OFF : begin
          Logic[nCh].m_InsStatus := IsStop;
          lnSigoff1.Visible := True;
          lnSigoff2.Visible := True;
          DongaPat.LoadPatFile('No Signal');
          pnlPatternName.Caption := 'Power Off';
          m_nTotalTact := 0;
          tmTotalTactTime.Enabled := False;
        end;
        DefCommon.MSG_MODE_PAT_DISPLAY : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          if gridPatternList.RowCount < 2 then begin
            if Trim(gridPatternList.Cells[1, 0]) = '' then Exit;
          end;
          if gridPatternList.RowCount < (nTemp+1) then Exit;
//          showmessage(format('%d / %d',[gridPatternList.RowCount , nTemp]));
          gridPatternList.Row := nTemp;
          nPatType := StrToInt(gridPatternList.Cells[0, nTemp]);
          lnSigoff1.Visible := False;
          lnSigoff2.Visible := False;
          DongaPat.DrawPatAllPat(nPatType, gridPatternList.Cells[1, nTemp]);
          pnlPatternName.Caption := gridPatternList.Cells[1, nTemp];

        end;
        DefCommon.MSG_MODE_CH_RESULT : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          pnlPGStatuses[nCh].Caption := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
          // NG 처리.
          pnlTotalValues[nCh].Caption := IntToStr(StrToInt(pnlTotalValues[nCh].Caption) + 1);
          if nTemp <> 0 then  begin
            pnlPGStatuses[nCh].Color := clRed;
            pnlPGStatuses[nCh].Font.Color := clBlack;
            Inc(m_nNgCnt[nCh]);
          end
          // OK 처리.
          else begin
            pnlPGStatuses[nCh].Color := clLime;
            pnlPGStatuses[nCh].Font.Color := clBlack;
            Inc(m_nOKCnt[nCh]);
          end;
          pnlTotalValues[nCh].Caption := Format('%d',[m_nNgCnt[nCh] + m_nOKCnt[nCh]]);
          pnlOKValues[nCh].Caption := Format('%d',[m_nOKCnt[nCh]]);
          pnlNGValues[nCh].Caption := Format('%d',[m_nNgCnt[nCh]]);
        end;
        DefCommon.MSG_MODE_DIO_CONTROL : begin
          if AxDio <> nil then begin
            nParam := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
            if Common.SystemInfo.ChCountUsed = 1 then begin
              Sleep(10);
              AxDio.WriteDio(nParam,1);
            end
            else if Common.SystemInfo.ChCountUsed = 2 then begin
              if (nParam = 0) then begin
                if (Logic[DefCommon.CH1].m_InsStatus = IsStop) and (Logic[DefCommon.CH2].m_InsStatus = IsStop) then begin
                  Sleep(10);
                  AxDio.WriteDio(nParam,1);
                end;
              end;
            end
            else if Common.SystemInfo.ChCountUsed = 4 then begin
              if (nParam = 0) then begin
                if (Logic[DefCommon.CH1].m_InsStatus = IsStop) and (Logic[DefCommon.CH2].m_InsStatus = IsStop) then begin
                  Sleep(10);
                  AxDio.WriteDio(nParam,1);
                end;
              end
              else if (nParam = 7) then begin
                if (Logic[DefCommon.CH3].m_InsStatus = IsStop) and (Logic[DefCommon.CH4].m_InsStatus = IsStop) then begin
                  Sleep(10);
                  AxDio.WriteDio(nParam,1);
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    DefCommon.MSG_TYPE_LOGIC : begin
      nMode := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
//      nTemp := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Data[1];
      case nMode of
        DefCommon.MSG_MODE_CH_CLEAR : begin
          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            ClearChData(i);
          end;
        end;


        DefCommon.MSG_MODE_WORKING : begin
          sMsg := Trim(PGuiLog(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);

          mmChannelLog[nCh].DisableAlign;
          sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
          mmChannelLog[nCh].Lines.Add(sDebug);
          Common.MLog(nCh+self.Tag*4,sMsg);
          mmChannelLog[nCh].EnableAlign;
        end;
        DefCommon.MSG_MODE_DISPLAY_RESULT : begin
          sMsg := Trim(PGuiLog(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
//          nTemp := PGuiLog(PCopyDataStruct(Msg.LParam)^.lpData).nParam;
//          case nTemp of
//            DefCommon.SEQ_RESULT_FAIL : begin
//              pnlPGStatuses[nCh].Color := clRed;
//              pnlPGStatuses[nCh].Font.Color := clBlack;
//              pnlPGStatuses[nCh].Caption := sMsg;
//            end;
//          end;

        end;


        DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER : begin
          sMsg := Trim(PGuiLog(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          pnlSerials[nCh].Caption := sMsg;
          mmChannelLog[nCh].DisableAlign;
          sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'Serial NUM:'+sMsg;
          mmChannelLog[nCh].Lines.Add(sDebug);
          Common.MLog(nCh+self.Tag*4,sMsg);
          mmChannelLog[nCh].EnableAlign;
        end;
        DefCommon.MSG_MODE_PAT_DISPLAY : begin
          nTemp := PGuiLog(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          if gridPatternList.RowCount < 2 then begin
            if Trim(gridPatternList.Cells[1, 0]) = '' then Exit;
          end;
          if gridPatternList.RowCount < (nTemp+1) then Exit;
//          showmessage(format('%d / %d',[gridPatternList.RowCount , nTemp]));
          gridPatternList.Row := nTemp;
          nPatType := StrToInt(gridPatternList.Cells[0, nTemp]);
          lnSigoff1.Visible := False;
          lnSigoff2.Visible := False;
          DongaPat.DrawPatAllPat(nPatType, gridPatternList.Cells[1, nTemp]);
          pnlPatternName.Caption := gridPatternList.Cells[1, nTemp];
        end;
      end;
    end;
    DefCommon.MSG_TYPE_PG : begin
      nMode := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_VOLCUR : begin
          DisplayPwrData(nCh,PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.ReadPwrData);
        end;
        DefCommon.MSG_MODE_DISPLAY_ALARM : begin
          PasScr[nCh].RunSeq(DefScript.SEQ_KEY_STOP);
          sMsg  := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg;
          pnlErrAlramMsg.Caption := Format('Channel %d, %s',[nCh+1,Trim(sMsg)]);
          pnlErrAlram.Left := 50;
          pnlErrAlram.Top  := 410;
          if Common.SystemInfo.UseAutoBCR then begin
            btnRetry.Visible := True;
          end
          else begin
            btnRetry.Visible := False;
          end;
          pnlErrAlram.Visible := True;
          pnlPGStatuses[nCh].Caption := 'ALARM NG';
          pnlPGStatuses[nCh].Color := clRed;
          pnlPGStatuses[nCh].Font.Color := clBlack;
          sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'ALARM NG '+ sMsg;
          mmChannelLog[nCh].Lines.Add(sDebug);
          Common.MLog(nCh+self.Tag*4,'ALARM NG : '+sMsg);
          // 2018-05-14 ksw : NG Message 작업자가 직접 끄도록 수정 (LGD 테크니션 요청)
//          tmrDisplayOff.Interval := 7000; // 5초 있다가 끄자... 그냥...
//          tmrDisplayOff.Enabled  := True;
        end;
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
          nTemp := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          sMsg  := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg;
          DisplayPGStatus(nCh,nTemp,sMsg);
          // 2018-05-10 ksw : power 버전에 따라서 모델정보 전류 스펙 범위 지정.
          // Pwr Version 2.1  ==> 0~1200
          // Pwr Version 2.2~ ==> 0~1800
          // Model Info 창에서 1800 이상 입력 못함.
          // Pwr Version 2.1 에서는 H/W 정보 받을 때 체크.
          Common.SystemInfo.nPwrVer[nCh] := StrToIntDef(Copy(sMsg,18,2),0);
          for i := DefCommon.CH1 to Pred(Common.SystemInfo.ChCountUsed) do begin
            // version check && setting value 체크
            if (Common.SystemInfo.nPwrVer[i] = 21) then begin
              if (Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VCI]  > 1200) or
                 (Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_DVDD] > 1200) or
                 (Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VDD]  > 1200) or
                 (Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VPP]  > 1200) or
                 (Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VBAT] > 1200) or
                 (Common.TempModelInfo.PWR_CUR_HL[DefCommon.PWR_VNEG] > 1200) then begin

                // NG 나면 Pwr On 안되게 막아야함.. M/C NG도 포함.
                // 언제 초기화 해주지??

                pnlPGStatuses[nCh].Caption := 'Current Limit Value NG';
                pnlPGStatuses[nCh].Color := clRed;
                pnlPGStatuses[nCh].Font.Color := clBlack;
                sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'Current Limit Value NG';
                sDebug := sDebug + #13#10 + 'Please Check Model Infomation (0 ~ 12 A)';
                mmChannelLog[nCh].Lines.Add(sDebug);
                Common.MLog(nCh+self.Tag*4,'Current Limit Value NG');
              end;
            end;
          end;

        end;
        DefCommon.MSG_MODE_DIFF_MODEL : begin
          sMsg  := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg;
          nTemp := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          if nTemp <> 0 then begin
            pnlPGStatuses[nCh].Caption := 'M/C NG';
            pnlPGStatuses[nCh].Color := clRed;
            pnlPGStatuses[nCh].Font.Color := clBlack;
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'M/C NG '+ sMsg;
            mmChannelLog[nCh].Lines.Add(sDebug);
            Common.MLog(nCh+self.Tag*4,'M/C NG : '+sMsg);
          end
          else begin
            if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
              pnlPGStatuses[nCh].Color := clBlack;
              pnlPGStatuses[nCh].Font.Color := clWhite;
            end
            else begin
              pnlPGStatuses[nCh].Color := clBtnFace;
              pnlPGStatuses[nCh].Font.Color := clBlack;
            end;
            pnlPGStatuses[nCh].Caption := 'Ready';
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'Model CRC Check OK ';
            mmChannelLog[nCh].Lines.Add(sDebug);
            Common.MLog(nCh+self.Tag*4,'Model CRC Check OK');
          end;
        end;
      end;
    end;
    DefCommon.MSG_TYPE_JIG : begin
      nMode := PGuiJigData(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_CH_CLEAR : begin
          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            ClearChData(i);
          end;
        end;
//        DefCommon.MSG_MODE_BARCODE_READY : begin
//          bTemp := True;
//          pnlInputSerial.Visible := True;
//          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//            sTemp := Format('edSerial%d',[i+1]);
//            (FindComponent(sTemp) as TRzEdit).Enabled := chkChannelUse[i].Checked;
//            if chkChannelUse[i].Checked and bTemp then begin
//              (FindComponent(sTemp) as TRzEdit).SetFocus;
//              bTemp := False;
//            end;
//
//          end;
//
//        end;
        DefCommon.MSG_MODE_UNIT_TT_START : begin
//          m_nUnitTact := 0;
//          if tmUnitTactTime <> nil then
//            tmUnitTactTime.Enabled := True;
//
//          pnlJigTact.Caption := '0.0';
        end;
//        DefCommon.MSG_TYPE_MODE_AGING_DISP : begin
//          nTemp := PGuiJigData(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
//          ShowAgingTime(nTemp);
//        end;
//        DefCommon.MSG_MODE_DISPLAY_PATTERN : begin
//          nTemp := PGuiJigData(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
//          nPatType := StrToInt(gridPatternList.Cells[0, nTemp]);
//          gridPatternList.Row := nTemp;
//          DongaPat.DrawPatAllPat(nPatType,gridPatternList.Cells[1, nTemp]);
//          lnSigoff1.Visible := False;
//          lnSigoff2.Visible := False;
//        end;
//        DefCommon.MSG_MODE_DISPLAY_ERROR : begin
//          nTemp := PGuiJigData(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
//          sTemp := PGuiJigData(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg;
//          case nTemp of
//            DefCommon.ALL_CH : begin
//              for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//                if not chkChannelUse[i].Checked then Continue;
//
//                mmChannelLog[i].Lines.Add(sTemp);
//              end;
//            end
//            else begin
//              mmChannelLog[nTemp].Lines.Add(sTemp);
//            end;
//          end;
//        end;
//        DefCommon.MSG_MODE_MAIN_CAPTION : begin
//          frmMainIsfom.Caption := DefCommon.ISFOM_TITLE;
//        end;
      end;
    end;
    DefCommon.MSG_TYPE_HOST : begin
      bTemp := PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.bError;
      case PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgMode of
        DefGmes.MES_PCHK : begin
          if bTemp then begin // error
            pnlMESResults[DefCommon.CH1].Color      := clMaroon;
            pnlMESResults[DefCommon.CH1].Font.Color := clRed;
            pnlMESResults[DefCommon.CH1].Caption    := 'PCHK NG';
          end
          else begin
            pnlMESResults[DefCommon.CH1].Color      := clGreen;
            pnlMESResults[DefCommon.CH1].Font.Color := clBlack;
            pnlMESResults[DefCommon.CH1].Caption    := 'PCHK OK';
          end;
        end;

        DefGmes.MES_ZSET : begin
          if bTemp then begin // error
            pnlMESResults[DefCommon.CH1].Color      := clMaroon;
            pnlMESResults[DefCommon.CH1].Font.Color := clRed;
            pnlMESResults[DefCommon.CH1].Caption    := 'ZSET NG';
          end
          else begin
            pnlMESResults[DefCommon.CH1].Color      := clGreen;
            pnlMESResults[DefCommon.CH1].Font.Color := clBlack;
            pnlMESResults[DefCommon.CH1].Caption    := 'ZSET OK';
          end;
        end;
      end;
    end;
  end;
end;

end.
