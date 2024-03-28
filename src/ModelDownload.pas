unit ModelDownload;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzButton, Vcl.ExtCtrls, DefCommon, RzPrgres, RzPanel, RzCommon,
  {LogicVh,} CommonClass, {UdpServerClient,}CommPG,
  {$IFDEF ISPD_POCB}
    CommCameraRadiant,
  {$ENDIF}
  DefPG, DefScript;

type
  TfrmModelDownload = class(TForm)
    pnlErrorDisplay: TPanel;
    tmrDisplayOffMessage: TTimer;
    tmrFrmclose: TTimer;
    pnl2: TPanel;
    pnlManualFusing: TPanel;
    pnl1: TPanel;
    pnlDpcConfigSet: TPanel;
    pnl4: TPanel;
    pnl5: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure tmrDisplayOffMessageTimer(Sender: TObject);
    procedure tmrFrmcloseTimer(Sender: TObject);
  private
    { Private declarations }
    pnlDownLoadStatus     : array[DefCommon.CH1 .. DefCommon.MAX_CH] of TRzPanel;
    pgbDownload           : array[DefCommon.CH1 .. DefCommon.MAX_CH] of TRzProgressBar;

    pnlCamStatus          : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TRzPanel;
    procedure SetCamModel;
  public
    { Public declarations }
  end;

var
  frmModelDownload: TfrmModelDownload;

implementation

{$R *.dfm}

procedure TfrmModelDownload.FormCreate(Sender: TObject);
var
  i, nHeight : Integer;
  SetPatGrp           : TPatterGroup;
  sTemp : string;
  fileTrans           : TArray<TFileTranStr>; // init1, init2, init3, oprg
  nTotalSize          : Integer;
  dChecksum           : dword;
  getFileData         : TArray<System.Byte>;
  nTotalDownCnt       : Integer;
  slCodes             : TStringList;
//  bCheckConn          : boolean;
begin
  nHeight := (pnlManualFusing.Height div (DefCommon.MAX_PG_CNT)); // camera Channel Info 추가.
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    pnlDownLoadStatus[i] := TRzPanel.Create(nil);
    pnlDownLoadStatus[i].Parent := pnlManualFusing;
    pnlDownLoadStatus[i].Top    := i*(nHeight+2);
    pnlDownLoadStatus[i].Height := nHeight;
    pnlDownLoadStatus[i].Width  := pnlManualFusing.Width;
    pnlDownLoadStatus[i].Color  := clSkyBlue;//clMaroon;
    pnlDownLoadStatus[i].Font.Size  := 10;
    pnlDownLoadStatus[i].BorderOuter := TframeStyleEx(fsFlat);
    pnlDownLoadStatus[i].Caption := '';
    pnlDownLoadStatus[i].Visible := True;
    pnlDownLoadStatus[i].Font.Color := clBlack;
    pnlDownLoadStatus[i].Caption := Format('PG CH %d',[i+1]);
    pnlDownLoadStatus[i].AlignmentVertical := avTop;
    pgbDownload[i] := TRzProgressBar.Create(nil);
    pgbDownload[i].Visible := False;
    pgbDownload[i].Parent := pnlDownLoadStatus[i];
    pgbDownload[i].Top := nHeight - (nHeight  div 2); // 0;
    pgbDownload[i].Left := 0;
    pgbDownload[i].Font.Size := 8;
    pgbDownload[i].Height := pnlDownLoadStatus[i].Height div 2;//pnlDownLoadStatus[i].Height div 4;
    pgbDownload[i].Width  := pnlDownLoadStatus[i].Width;
    pgbDownload[i].Visible := True;
  end;

  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if common.SystemInfo.ChCountUsed > i then begin
      pnlDownLoadStatus[i].Visible := True;
      pgbDownload[i].Visible := True;
    end
    else begin
      pnlDownLoadStatus[i].Visible := False;
      pgbDownload[i].Visible := False;
    end;
  end;
  //pnlManualFusing.Height := nHeight * common.SystemInfo.ChCountUsed + 20;

  SetPatGrp := Common.LoadPatGroup(string(Common.TempModelInfo2.PatGrpName));
  // 해당 pattern File이 있는지 확인.
  for i := 0 to Pred(SetPatGrp.PatCount) do begin
    case SetPatGrp.PatType[i] of
      DefCommon.PTYPE_NORMAL : begin
        Continue;
//        sTemp := Common.Path.Pattern + Trim(string(SetPatGrp.PatName[i]));
      end;
      DefCommon.PTYPE_BITMAP : begin
        sTemp := Common.Path.BMP + Trim(string(SetPatGrp.PatName[i]));
      end;
    end;
    if not FileExists(sTemp) then begin
      pnlErrordisplay.caption := Format('Please Check Pattern File(%s)',[sTemp]);
      pnlErrordisplay.Visible := True;
      tmrDisplayOffMessage.Interval := 3000;
      tmrDisplayOffMessage.Enabled := True;
      exit;
    end;
  end;

  nTotalDownCnt := Defscript.CODE_MAX + SetPatGrp.PatCount;//  5 + SetPatGrp.PatCount;  Pattern Count 추가. otp write/
  SetLength(fileTrans,nTotalDownCnt);
  for i := 0 to Pred(nTotalDownCnt) do begin
    fileTrans[i].filePath := AnsiString(Common.Path.ModelCode);
    fileTrans[i].TransMode  := DefCommon.DOWNLOAD_TYPE_PRG;
    // set file Name.
    case i of
      0 : fileTrans[i].fileName  := AnsiString(Common.SystemInfo.TestModel + '.mpt');
      1 : fileTrans[i].fileName  := AnsiString(Common.SystemInfo.TestModel + '.mion');
      2 : fileTrans[i].fileName  := AnsiString( Common.SystemInfo.TestModel + '.mioff');
      3 : fileTrans[i].fileName  := AnsiString( Common.SystemInfo.TestModel + '.pwon');
      4 : fileTrans[i].fileName  := AnsiString( Common.SystemInfo.TestModel + '.pwoff');
      5 : fileTrans[i].fileName  := AnsiString( Common.SystemInfo.TestModel + '.miau');
      6 : fileTrans[i].fileName  := AnsiString( Common.SystemInfo.TestModel + '.otpw');
      7 : fileTrans[i].fileName  := AnsiString( Common.SystemInfo.TestModel + '.otpr');
      8 : fileTrans[i].fileName  := AnsiString( Common.SystemInfo.TestModel + '.misc')
      else begin
        fileTrans[i].fileName   := AnsiString(StringReplace(string(SetPatGrp.PatName[i-Defscript.CODE_MAX]),'.bmp','.raw', [rfReplaceAll, rfIgnoreCase]));
        if SetPatGrp.PatType[i-Defscript.CODE_MAX] = PTYPE_BITMAP then begin
          fileTrans[i].filePath   := AnsiString(Common.Path.BMP);
        end
        else begin
          fileTrans[i].filePath   := AnsiString(Common.Path.Pattern);
        end;
      end;
    end;
    // 자동 misc file 생성.
    if i = 8 then begin
      if not FileExists(fileTrans[i].filePath+fileTrans[i].fileName) then begin
        try
          slCodes := TStringList.create;
          slCodes.Add('');
          slCodes.SaveToFile(fileTrans[i].filePath+fileTrans[i].fileName);
        finally
          slCodes.Free;
        end;
      end;
    end;

    if (i in [0..(Defscript.CODE_MAX-1)]) and (not FileExists(fileTrans[i].filePath+fileTrans[i].fileName)) then begin
      pnlErrordisplay.caption := Format('MODEL DOWNLOAD ERROR!!  File (%s) is not exist',[fileTrans[i].fileName]);
      pnlErrordisplay.Visible := True;
      tmrDisplayOffMessage.Interval := 3000;
      tmrDisplayOffMessage.Enabled := True;
      Exit;
    end;
    // set trans type.

    case i of
      0 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_TXIC;
      1 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_MODULE_ON;
      2 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_MODULE_OFF;
      3 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_PWR_ON;
      4 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_PWR_OFF;
      5 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_PWR_ON_AUTO;
      6 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_OTP_WRITE;
      7 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_OTP_READ;
      8 : fileTrans[i].TransType  := DefPG.TRANS_TYPE_SCREEN_CODE
      else begin
        fileTrans[i].TransType  := DefPG.TRANS_TYPE_PAT_INFO;
      end;
    end;
    dChecksum := 0;
    if i in [0 .. (DefScript.CODE_MAX-1)] then begin
      Common.LoadCheckSumNData(string(fileTrans[i].filePath+fileTrans[i].fileName),dChecksum,nTotalSize,getFileData);
    end
    else begin
      Common.MakePatternData(i-Defscript.CODE_MAX,SetPatGrp,dChecksum,nTotalSize,getFileData);
    end;

    fileTrans[i].CheckSum   := dChecksum;
    fileTrans[i].TotalSize  := nTotalSize;
    SetLength(fileTrans[i].Data, nTotalSize);
    CopyMemory(@fileTrans[i].Data[0],@getFileData[0],nTotalSize);
  end;
  Common.TestModelInfo := Common.TempModelInfo;
//  // 주의. signal type은 시작이 1 부터임. 데이턴는 0으로 되어 있음.
//  Common.TestModelInfo.SigType := Common.TempModelInfo.SigType + 1;
//  Common.TestModelInfo.SPI_Bit := Common.TempModelInfo.SPI_Bit + 1;
//  Common.TestModelInfo.I2C_bit := Common.TempModelInfo.I2C_bit + 1;
//  if Common.TempModelInfo.SPI_Clock = 0 then Common.TestModelInfo.SPI_Clock := 50
//  else if Common.TempModelInfo.SPI_Clock = 1 then Common.TestModelInfo.SPI_Clock := 100;
//  if Common.TempModelInfo.Model_Type < 11 then Common.TempModelInfo.Model_Type := 10
//  else                                         Common.TestModelInfo.Model_Type := Common.TempModelInfo.Model_Type;
  Common.TestModelInfo.Freq := Common.TempModelInfo.Freq;
//  bCheckConn := False;
	for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if not (Pg[i].Status in [pgForceStop, pgDisconnect]) then begin


//      bCheckConn := True;
      pnlDownLoadStatus[i].Color := clSkyBlue;
      pnlDownLoadStatus[i].Font.Color := clBlack;
//      Logic[i].SendModelInfoDownLoad(Self.Handle,nTotalDownCnt,fileTrans);
    end
    else begin
      pnlDownLoadStatus[i].Color := clMaroon;
      pnlDownLoadStatus[i].Font.Color := clYellow;
      pnlDownLoadStatus[i].Caption := Format('CH%d - PG Disconnected',[i+1]);
    end;
	end;

  Common.TestModelInfo2 := Common.TempModelInfo2;
  Self.Height := 461;
{$IFDEF ISPD_POCB}
//  Self.Height := 613;
//  nHeight := (pnlDpcConfigSet.Height div (DefCommon.MAX_JIG_CH + 1)) - 2; // camera Channel Info 추가.
//  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//    pnlCamStatus[i] := TRzPanel.Create(nil);
//    pnlCamStatus[i].Parent := pnlDpcConfigSet;
//    pnlCamStatus[i].Top    := i*(nHeight+2);
//    pnlCamStatus[i].Height := nHeight;
//    pnlCamStatus[i].Width  := pnlDpcConfigSet.Width;
//    pnlCamStatus[i].Color  := clMoneyGreen;//clMaroon;
//    pnlCamStatus[i].Font.Color := clBlack;
//    pnlCamStatus[i].Font.Size  := 10;
//    pnlCamStatus[i].BorderOuter := TframeStyleEx(fsFlat);
//    pnlCamStatus[i].Caption := '';
//    pnlCamStatus[i].Visible := True;
//    pnlCamStatus[i].Caption := Format('DPC CH %d',[i+1]);
//  end;
//
//  SetCamModel;
{$ENDIF}
end;

procedure TfrmModelDownload.SetCamModel;
var
  sa: TArray<String>;
  sModel: String;
begin
{$IFDEF ISPD_POCB}
  sa:= Common.SystemInfo.TestModel.Split(['-']);
  if Length(sa) > 4 then begin
    sModel:= format('%s-%s-%s', [sa[2], sa[3], sa[4]]);
  end
  else begin
    sModel:= Common.SystemInfo.TestModel;
  end;

  CommCamera.SendModel(sModel); //카메라에 모델명 전송
//    CamCommT.m_hTest := Self.Handle;
//    CamCommTri.SetModelSet;
{$ENDIF}
end;

procedure TfrmModelDownload.tmrDisplayOffMessageTimer(Sender: TObject);
begin
  tmrDisplayOffMessage.Enabled := False;
  pnlErrorDisplay.Visible := False;
end;

procedure TfrmModelDownload.tmrFrmcloseTimer(Sender: TObject);
begin
  tmrFrmclose.Enabled := False;
  close;
end;

procedure TfrmModelDownload.WMCopyData(var Msg: TMessage);
var
  nType, nPg, nMode, nParam : Integer;
  bTemp : boolean;
  sMsg : string;
  i, nTotal, nCur: Integer;
begin
  nType := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nPg   := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
//  sMsg  := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
  case nType of
    DefCommon.MSG_TYPE_LOGIC : begin
      nMode := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_MODEL_DOWN_START : begin
//          if not pnlManualFusing.Visible then pnlManualFusing.Visible := True;
          nParam := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Data[1];
          sMsg := Format('PG %d Start Model Info downloading ...',[nPg+1]);
          if nParam <> 0 then begin
            sMsg := sMsg + '(Download NG) Please Check Model Info or Connection';
            pnlDownLoadStatus[nPg].Color := clMaroon;
            pnlDownLoadStatus[nPg].Font.Color := clYellow;
          end
          else begin
            pnlDownLoadStatus[nPg].Color := clSkyBlue;
            pnlDownLoadStatus[nPg].Font.Color := clBlack;
          end;
          pnlDownLoadStatus[nPg].Visible := True;
          pnlDownLoadStatus[nPg].Caption := sMsg;
          pgbDownload[nPg].Percent := 0;
          pgbDownload[nPg].Visible := True;
        end;
        DefCommon.MSG_MODE_MODEL_DOWN_END : begin
          pgbDownload[nPg].Visible := False;
          pgbDownload[nPg].Percent :=0;
          pnlDownLoadStatus[nPg].Visible := False;
          pnlDownLoadStatus[nPg].Caption := '';
          bTemp := False;
          for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
            if pnlDownLoadStatus[nPg].Visible then begin
              bTemp := True;
              break;
            end;
          end;
          if pnlErrordisplay.Visible then  begin
            Common.Delay(1000);
            bTemp := True;
            //ModalResult:= mrCancel;
            //Exit;
          end;

          if not bTemp then begin
            Common.Delay(1000);
            pnlManualFusing.Visible := False;
            Close;
          end;

        end;
        DefCommon.MSG_MODE_MODEL_DOWNLOADING : begin
          pnlDownLoadStatus[nPg].Caption := sMsg;
        end;

      end;
    end;
    DefCommon.MSG_TYPE_PG : begin
      nMode := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS : begin
          nTotal  := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Total;
          nCur    := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.CurPos;
          sMsg    := string(PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg);
          pnlDownLoadStatus[nPg].Caption := sMsg;
          pgbDownload[nPg].Percent := (nCur * 100) div nTotal;

          bTemp:= PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.IsDone;
          if bTemp then begin  //다운로드 완료일경우
            if (nCur < nTotal)  then begin
              //다운로드 중 Fail 발생
              sMsg:= Format('MODEL DOWNLOAD ERROR!! %s - PG=%d, %d / %d',[sMsg, nPg, nCur, nTotal]);
              common.MLog(nPg, sMsg);
              pnlDownLoadStatus[nPg].Color:= clMaroon;
              pnlErrordisplay.caption := sMsg;
              pnlErrordisplay.Visible := True;
            end;
            if sMsg = 'Fusing NG' then begin
              pnlDownLoadStatus[nPg].Color:= clMaroon;
              common.MLog(nPg, sMsg);
              pnlErrordisplay.caption := sMsg;
              pnlErrordisplay.Visible := True;
            end;

          end;
        end;
      end;

    end;
{$IFDEF ISPD_POCB}
    DefCommon.MSG_TYPE_CAMERA : begin   // Camera.
//      nMode := PGuiCamData(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
//      sMsg := Trim(PGuiCamData(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
//      nParam := PGuiCamData(PCopyDataStruct(Msg.LParam)^.lpData)^.Param1;
      case nMode of
        DefCommon.MSG_MODE_WORKING : begin
        // 주의 ... Camera Ch과 PG Channel 다름.
          if nParam <> 0 then begin  // NG 처리.
            pnlCamStatus[nPg].Color := clMaroon;
            pnlCamStatus[nPg].Font.Color := clYellow;
          end
          else begin
            pnlCamStatus[nPg].Color := clMoneyGreen;
            pnlCamStatus[nPg].Font.Color := clBlack;
          end;
          pnlCamStatus[nPg].caption := Format('[DPC %d] : ',[nPg+1]) + sMsg;
          pnlCamStatus[nPg].Visible := True;

//          tmrDisplayOffMessage.Interval := 10000;
//          tmrDisplayOffMessage.Enabled := True;
        end;
        DefCommon.MSG_MODE_MODEL_DOWN_END : begin
          pnlCamStatus[nPg].Visible := False;
          bTemp := False;
          for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
            if pnlDownLoadStatus[i].Visible then begin
              bTemp := True;
              break;
            end;
          end;

          if not bTemp then begin
            for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
              if pnlCamStatus[i].Visible then begin
                bTemp := True;
                break;
              end;
            end;
          end;
          if not bTemp then begin
            Common.Delay(1000);
            pnlManualFusing.Visible := False;
            Close;
          end;
        end;
      end;
    end;
{$ENDIF}
  end;
end;

end.
