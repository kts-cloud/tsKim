unit UiChecking;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, DefCommon, Vcl.StdCtrls, Vcl.ComCtrls, ALed,
  RzPanel, RzButton, RzRadChk, AdvUtil, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, RzCommon, CommonClass;

type
  TfrmUiChecking = class(TForm)
    pnlTestMain: TPanel;
    pnlJigInform: TPanel;
    imgCheckBox: TImage;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    mmChannelLog   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of  TRichEdit;//  TMemo;

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
    pnlSerials     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlSerials2    : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    pnlMESResults  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlPGStatuses  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlTimeNResult : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;

    gridPWRPGs     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TAdvStringGrid;
  public
    { Public declarations }
  end;

var
  frmUiChecking: TfrmUiChecking;

implementation

{$R *.dfm}

procedure TfrmUiChecking.FormCreate(Sender: TObject);
var
  i, nItemWidth, nItemHeight, nFontSize : Integer;
begin
  nItemWidth := (Self.Width - pnlJigInform.Width - pnlJigInform.Left) div (DefCommon.MAX_JIG_CH +1)-2;
  nItemHeight := 26;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    pnlChGrp[i] := TRzPanel.Create(self);
    pnlChGrp[i].Parent := pnlTestMain;
    pnlChGrp[i].Top := 2;
    pnlChGrp[i].Height := pnlTestMain.Height;
    pnlChGrp[i].Width := nItemWidth;
    pnlChGrp[i].Font.Size := 8;
    pnlChGrp[i].Left := nItemWidth * i + pnlJigInform.Width;
    pnlChGrp[i].Align := alLeft;
    pnlChGrp[i].Font.Color  := clBlack;
    pnlChGrp[i].Alignment := taRightJustify;
//    pnlChGrp[i].Caption := Format('Ch Grp %d',[i+1]);// '';
    pnlChGrp[i].BorderOuter := TframeStyleEx(fsFlat);
//    pnlChGrp[i].Visible := False;

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
    chkChannelUse[i].Caption := Format('kênh (Channel) %d',[i+1+self.Tag*4]);//Format('Channel %d',[i+1+self.Tag*4]);
    chkChannelUse[i].AlignmentVertical := TAlignmentVertical(avCenter);
    chkChannelUse[i].Font.Size := 12;
//    chkChannelUse[i].State := cbChecked;
    chkChannelUse[i].Font.Color := clGreen;
    chkChannelUse[i].Cursor := crHandPoint;

    pnlSerials[i] := TPanel.Create(self);
    pnlSerials[i].Parent := pnlChGrp[i];
    pnlSerials[i].Top := chkChannelUse[i].Top + chkChannelUse[i].Height;
    pnlSerials[i].Height := nItemHeight;
    pnlSerials[i].Align := alTop;
    pnlSerials[i].Color := clBtnFace;
//    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//      pnlSerials[i].Color := clBlack;
//      pnlSerials[i].Font.Color := clYellow;
//    end
//    else begin
//
//    end;
      pnlSerials[i].Color := clBtnFace;
      pnlSerials[i].Font.Color := clBlack;
    pnlSerials[i].Hint  := 'Serial Number';
    pnlSerials[i].ShowHint  := True;
    pnlSerials[i].Alignment := taCenter;
    pnlSerials[i].Font.Name := 'Tahoma';
    pnlSerials[i].Caption := '';//Format('23020218LN36A308416900A2%sC231369V16A3169WFB0000%d',[chr(10),i]);
    pnlSerials[i].ParentBackground := False;
    pnlSerials[i].StyleElements := [];
    pnlSerials[i].Font.Size := 10;

    pnlMESResults[i] := TPanel.Create(self);
    pnlMESResults[i].Parent := pnlChGrp[i];
//    pnlMESResults[i].Top := pnlSerials[i].Top + pnlSerials[i].Height;
    pnlMESResults[i].Top := pnlChGrp[i].Height;
    pnlMESResults[i].Height := nItemHeight;
    pnlMESResults[i].Align := alTop;
    pnlMESResults[i].Caption := '';
    pnlMESResults[i].Hint := 'MES Result';
    pnlMESResults[i].ShowHint := True;
//    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//      pnlMESResults[i].Color := clBlack;
//      pnlMESResults[i].Font.Color := clWhite;
//    end
//    else begin
      pnlMESResults[i].Color := clBtnFace;
      pnlMESResults[i].Font.Color := clYellow;
//    end;

    pnlMESResults[i].Font.Size := 12;
    pnlMESResults[i].ParentBackground := False;
    pnlMESResults[i].StyleElements := [];

    pnlPGStatuses[i] := TPanel.Create(Self);
    pnlPGStatuses[i].Parent := pnlChGrp[i];
//    pnlPGStatuses[i].Top := pnlMESResults[i].Top + pnlMESResults[i].Height;
    pnlPGStatuses[i].Top := pnlChGrp[i].Height;
    pnlPGStatuses[i].Align := alTop;
    pnlPGStatuses[i].Caption := 'Ready';
    pnlPGStatuses[i].Hint := 'Inspection Result';
    pnlPGStatuses[i].ShowHint := True;
    pnlPGStatuses[i].Color := clBtnFace;
    pnlPGStatuses[i].Font.Size := 14;
    pnlPGStatuses[i].Font.Color := clBlack;
    pnlPGStatuses[i].ParentBackground := False;
    pnlPGStatuses[i].StyleElements := [];
////    pnlPGStatuses[i].BorderOuter := TframeStyleEx(fsFlat);
//    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//      pnlPGStatuses[i].Color := clBlack;
//      pnlPGStatuses[i].Font.Color := clWhite;
////      pnlPGStatuses[i].StyleElements := [];
//    end
//    else begin
////      pnlPGStatuses[i].StyleElements := [];//[seFont, seClient, seBorder];
//      pnlPGStatuses[i].Font.Color := clBlack;
//    end;

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

    gridPWRPGs[i] := TAdvStringGrid.Create(Self);
    gridPWRPGs[i].Clear;
    gridPWRPGs[i].Parent := pnlChGrp[i];
    gridPWRPGs[i].Font.Name := 'Tahoma';
    gridPWRPGs[i].Top := 275;
    gridPWRPGs[i].Height := 114;
    gridPWRPGs[i].Align := alTop;
    gridPWRPGs[i].ColCount := 6;
    gridPWRPGs[i].RowCount := 6;
    gridPWRPGs[i].FixedCols := 0;
    gridPWRPGs[i].ColumnHeaders.Add('');
    gridPWRPGs[i].ColumnHeaders.Add('V'{'Voltage'});
    gridPWRPGs[i].ColumnHeaders.Add('mA'{'Current'});
    gridPWRPGs[i].ColumnHeaders.Add('');
    gridPWRPGs[i].ColumnHeaders.Add('V'{'Voltage'});
    gridPWRPGs[i].ColumnHeaders.Add('mA'{'Current'});

    gridPWRPGs[i].ColWidths[0] := 32;
    gridPWRPGs[i].ColWidths[1] := 56;
    gridPWRPGs[i].ColWidths[2] := 56;
    gridPWRPGs[i].ColWidths[3] := 40;
    gridPWRPGs[i].ColWidths[4] := 56;
    gridPWRPGs[i].ColWidths[5] := 56;
//    gridPWRPGs[i].ColWidths[3] := 40;
//    gridPWRPGs[i].ColWidths[4] := 56;
    gridPWRPGs[i].Cells[0,1] := 'VPNL';
    gridPWRPGs[i].Cells[0,2] := 'VDDI';
    gridPWRPGs[i].Cells[0,3] := 'T_AVDD';  // LGD 요청 사항 : VIO ==> T_AVDD
    gridPWRPGs[i].Cells[0,4] := 'VPP';
    gridPWRPGs[i].Cells[0,5] := 'VBAT';

    gridPWRPGs[i].Cells[3,1] := 'VCI';
    gridPWRPGs[i].Cells[3,2] := 'VDDEL';
    gridPWRPGs[i].Cells[3,3] := 'VSSEL';
    gridPWRPGs[i].Cells[3,4] := 'DDVDH';

    gridPWRPGs[i].DefaultRowHeight := 18;
    gridPWRPGs[i].DefaultAlignment := taCenter;
    mmChannelLog[i] := TRichEdit.Create(self);// TMemo.Create(self);
    mmChannelLog[i].Parent := pnlChGrp[i];
//    mmChannelLog[i].Height := 100;
    mmChannelLog[i].Align := alClient;
    mmChannelLog[i].ScrollBars := ssVertical;
    mmChannelLog[i].StyleElements := [];
      mmChannelLog[i].Font.Color := clBlack;
      mmChannelLog[i].Color := clWhite;
//    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//      mmChannelLog[i].Color := clBlack;
//      mmChannelLog[i].Font.Color := clWhite;
////      mmChannelLog[i].StyleElements := [];
//    end
//    else begin
////      mmChannelLog[i].StyleElements := [];//[seFont, seClient, seBorder];
//
//    end;

  end;

  pnlTestMain.Visible := True;
end;

end.
