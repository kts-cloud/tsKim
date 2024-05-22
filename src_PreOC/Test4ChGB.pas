unit Test4ChGB;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzPanel, ALed, RzButton, Vcl.ExtCtrls, RzRadChk,
  Vcl.StdCtrls, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, RzCommon, LogicVh, SwitchBtn, JigControl,
  UdpServerClient, CommonClass, ScriptClass, DefScript, DefPG, DefCommon, Ca310, PlcTcp, defPlc,
  CodeSiteLogging, AdvPanel, Vcl.ComCtrls, AdvListV, Vcl.Mask, RzEdit, DongaPattern, RzGrids, AdvUtil, RzLine,
  HandBCR, GMesCom, pasScriptClass, AutoBCRClient, AdvGlassButton, AXDioLib, DefDio, DefGmes ;

type

  plcStatus = (psReadyPc, psLoadReq, psStartIns, psComplete, psUnloadReq);
  TfrmTest4ChGB = class(TForm)
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
    pnlInputSerial: TRzPanel;
    btnInputSerial: TRzBitBtn;
    pnlInputS1: TRzPanel;
    pnl4: TRzPanel;
    edSerial1: TRzEdit;
    pnlInputS2: TRzPanel;
    pnl5: TRzPanel;
    edSerial2: TRzEdit;
    pnlInputS3: TRzPanel;
    pnl6: TRzPanel;
    edSerial3: TRzEdit;
    btnStopInputS: TRzBitBtn;
    pnlTestMain: TRzPanel;
    tmAging: TTimer;
    pnlErrAlram: TAdvPanel;
    pnlErrAlramMsg: TPanel;
    btnErrorDisplay: TRzButton;
    pnl2: TPanel;
    RzCheckBox1: TRzCheckBox;
    pnlJigInform: TRzPanel;
    tmrRetest: TTimer;
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
    procedure btnInputSerialClick(Sender: TObject);
    procedure btnStopInputSClick(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
    procedure btnAutoClick(Sender: TObject);
    procedure btnRepeatClick(Sender: TObject);
    procedure btnCh4Click(Sender: TObject);
  private
    { Private declarations }

    m_nCurStatus   : Integer;
    m_nOkCnt, m_nNgCnt : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of integer;
    m_nTotalTact, m_nUnitTact   :  Integer;
    tmTotalTactTime  :  TTimer;
    tmUnitTactTime   :  TTimer;
    m_bAutoPlcProbeBack : Boolean;
//    pnlJigInform   :  TRzPanel;
//    pnlJigTitle    :  TPanel;
    btnStartTest   :  TRzBitBtn;
    btnStopTest    :  TRzBitBtn;
//    btnVirtualKey  :  TRzBitBtn;
    // tact time.
    pnlTackTimes   :  TRzPanel;
    pnlNowValues   :  TPanel;
    pnlUnitTact    :  TRzPanel;
    pnlUnitTactVal :  TPanel;


    lstPwrView     : TAdvListView;
    m_PlcStatus    : plcStatus;
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

    pnlGrpDio      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlDioConTactUp  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlDioConTactDn  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlDioDetect   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
    pnlDioPresure  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;

    pnlPrevResult  : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH,0..DefCommon.MAX_PREVIOUS_RESULT] of TPanel;
//    pnlPlcSupply   : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;
//    pnlPlcOut      : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TPanel;

    gridPWRPGs     : array[DefCommon.CH1 .. DefCommon.MAX_JIG_CH] of TAdvStringGrid;
    m_nCheckCa310  : Integer;
    m_RGB_Avr_Data : array of array of TGammaCmd;
    m_Rgb_Avr      : TGammaAvg;
    m_bInitGetAvr  : boolean;

    procedure CreateGui;
    procedure OnTotalTimer(Sender : TObject);
    procedure OnUnitTimer(Sender : TObject);
    procedure BtnStartTestClick(Sender: TObject);
    procedure BtnStopTestClick(Sender: TObject);
    procedure btnVirtualKeyClick(Sender : TObject);
    procedure chkPgClick(Sender: TObject);
    procedure RevSwDataJig(sGetData : String);
    procedure DisplayPGStatus(nPgNo, nType : Integer; sMsg : string);
    procedure DisplayPwrData(nPgNo: Integer; PwrData: ReadVoltCurr);
//    procedure DisplaySeq;
    procedure getBcrData(sScanData : string);
    procedure ClearChData(nCh : Integer);
    procedure UpdatePtList;
    procedure DioWorkDone(nErrCode : Integer; sErrMsg : string);
    procedure SyncProbeBack(nJigCh, nParam1, nNgCode : Integer);
    procedure SyncRunScrpt(nIdxKey : Integer);
    procedure StopTotalTimer(Sender: TObject; nTimerType : Integer);
    procedure DisplayPreviousRet(nCh : Integer);
    procedure CheckCa310MemInfo;
    procedure DisplayLogAllCh(nCh : Integer; bNg : Boolean; sMsg : string);
    procedure MakeOpticPassRgb(nCh: Integer);
    // file을 읽고 OC Parameter의 평균값을 구하자.
    procedure GetRgbAvgFromFile;
    procedure CalcLogScroll(nPg, nLogLen : Integer);
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
    procedure SetProbeAutoControl;
    procedure AutoLogicStart;
    procedure ShowPlcNgMeg(nJigCh : Integer;sErrMsg : string);
    procedure SetComeInOrderPlc(bAllOff : Boolean = False);
    procedure SetComeOutOderPlc;
    procedure SetHostConnShow(bHostOn : Boolean);
    function CheckScriptRun : Boolean;
    procedure SetDioStatus(IoDio : AxIoStatus);
    procedure SetPlcStatus(IoPlc : Integer);
//    procedure SetLanguage(nIdx : Integer);
  end;

var
  frmTest4ChGB: array[defcommon.JIG_A .. DefCommon.JIG_B] of TfrmTest4ChGB;

implementation

{$R *.dfm}
{$R+}

{ TfrmTest4Ch }

procedure TfrmTest4ChGB.btnErrorDisplayClick(Sender: TObject);
begin
  pnlErrAlram.Visible := False;
end;

procedure TfrmTest4ChGB.btnInputSerialClick(Sender: TObject);
var
  i: Integer;
begin

  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if pnlSerials[i].Caption = '' then pnlSerials[i].Color := clBtnFace
    else                               pnlSerials[i].Color := clSkyBlue;

    Logic[i].m_Inspect.SerialNo := Trim(pnlSerials[i].Caption);
//    Logic[i+Self.Tag*4].StartZoneFlow(1);
  end;
//  JigLogic[DefCommon.JIG_A].StartIsfomFlow;
  pnlInputSerial.Visible := False;
  edSerial1.Text := '';
  edSerial2.Text := '';
  edSerial3.Text := '';
end;

procedure TfrmTest4ChGB.btnRepeatClick(Sender: TObject);
begin
//  JigLogic[Self.Tag].StartIspd_A_Repeat;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_3);
end;

procedure TfrmTest4ChGB.BtnStartTestClick(Sender: TObject);
var
  sDebug : string;
begin
  if m_nCheckCa310 <> 0 then begin
    case m_nCheckCa310 of
      DefCommon.CHECK_CA310_NOT_CHECK   :  DisplayLogAllCh(-1,True,'START - NOT CHECK CA310 Status');
      DefCommon.CHECK_CA310_USER_CAL_NG :  DisplayLogAllCh(-1,True,'START - CA310 User Cal Check NG');
      DefCommon.CHECK_CA310_PROBE_NG    :  DisplayLogAllCh(-1,True,'START - CA310 Probe Serial Number Unmatch.');
    end;
    Exit;
  end;
  if m_Rgb_Avr.AvgType <> DefCommon.IDX_RGB_AVR_TYPE_NONE then begin
    if m_Rgb_Avr.NgCode in [2,3,4] then begin
      sDebug := Format('START - RGB AVR File Format NG.(NG CODE:%d)',[m_Rgb_Avr.NgCode]);
      DisplayLogAllCh(-1,True,sDebug);
      Exit;
    end;
  end;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_START);

end;

procedure TfrmTest4ChGB.btnStopInputSClick(Sender: TObject);
begin
  pnlInputSerial.Visible := False;
  edSerial1.Text := '';
  edSerial2.Text := '';
  edSerial3.Text := '';
//  tmTotalTactTime.Enabled := False;
  pnlInputSerial.Visible := False;
end;

procedure TfrmTest4ChGB.BtnStopTestClick(Sender: TObject);
begin
//  tmTotalTactTime.Enabled := False;
  JigLogic[Self.Tag].StopIspd_A;
end;

procedure TfrmTest4ChGB.btnSWCancel1Click(Sender: TObject);
begin
//  tmTotalTactTime.Enabled := False;

  JigLogic[Self.Tag].StopIspd_A;
end;

procedure TfrmTest4ChGB.btnSWNext1Click(Sender: TObject);
begin
//  pnlErrAlram.Visible := True;
//  Pg[0].TestFunc;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_9);
end;

procedure TfrmTest4ChGB.CalcLogScroll(nPg, nLogLen: Integer);
var
  i, nTimes : Integer;
begin
  nTimes := (nLogLen div 68);
  for i := 0 to nTimes do begin
    mmChannelLog[nPg].Perform(EM_SCROLL,SB_LINEDOWN,0);
  end;
end;

procedure TfrmTest4ChGB.CheckCa310MemInfo;
var
  sModelType, sProbe, sDebug, sPath, sFileName,sTarget,sReadData, sTemp : string;
  i, nMemCh, nCh, nRow, nCsvCnt, nRetSearch : Integer;
  MemChInfo, tempMemInfo : TLvXY;
  bRet, bIsOk : boolean;
  GetAllxy : TAllLvXy;
  GetxyLv : TLvXY;
  txtF    : Textfile;
  lstTemp : TStringList;
  TempList : TSearchRec;
  sIdx, sGetSerial : string;
begin
  // Added by Clint 2020-05-18 오후 2:45:37 임시..
  m_nCheckCa310 := DefCommon.CHECK_CA310_OK;
  Exit;

  if DongaCa310[Self.Tag].m_bConnection then begin
    // Target값 Check.
    sModelType := Common.GetModelType(2,Common.SystemInfo.TestModel);
      // 해당 모델에 대한 Folder가 있는지 확인.
    sPath := Common.Path.UserCal+sModelType+'\';
    sDebug := 'UserCal Path Check';
    if not DirectoryExists(sPath) then begin
      sDebug := sDebug +':Fail,'+sPath;
      DisplayLogAllCh(-1,True,sDebug);
      Exit;
    end;
    sDebug := sDebug +' : OK';
    DisplayLogAllCh(-1,False,sDebug);
    // csv file이 1개만 있는지 확인.
    nRetSearch := FindFirst(sPath + '*.csv', faAnyFile, TempList);
    try
      nCsvCnt := 0;
      while nRetSearch = 0 do begin
        Inc(nCsvCnt);
        sTarget := TempList.Name;
        nRetSearch := FindNext(TempList);
      end;
    finally
      FindClose(TempList);
    end;
    sDebug := 'Check Target Csv file Count';
    if nCsvCnt <> 1 then begin
      sDebug := sDebug +':Fail,'+Format('Csv Count is %d',[nCsvCnt]);
      DisplayLogAllCh(-1,True,sDebug);
      Exit;
    end;
    DisplayLogAllCh(-1,False,sDebug+' OK');

    // Load Target Data.  (csv file의 내용이 잘못 되어 있는지 확인.)
    sFileName := sPath + sTarget;
    sDebug := 'Check Target Data file';
    if (not FileExists(sFileName)) or (sTarget = '') then begin
      sDebug := sDebug +':Fail,'+sFileName;
      DisplayLogAllCh(-1,True,sDebug);
      Exit;
    end;
    if IOResult = 0 then begin
      AssignFile(txtF, sFileName);
      try
        Reset(txtF);
        nRow := 0;     bRet := True;
        while not Eof(txtF) do begin
          Readln(txtF, sReadData);
          if nRow = 0 then begin
            Inc(nRow);
            Continue; // 첫값은 Header.
          end;
          if (nRow - 1) > DefCa310.IDX_MAX then Continue;

          lstTemp := TStringList.Create;
          try
            ExtractStrings([','], [], PWideChar(sReadData), lstTemp);
            if lstTemp.Count < 4 then begin
              bRet := False;
              Break;
            end;
//            DisplayLogAllCh(-1,False,sReadData);
//            DisplayLogAllCh(-1,False,lstTemp[0]);
//            DisplayLogAllCh(-1,False,lstTemp[1]);
//            DisplayLogAllCh(-1,False,lstTemp[2]);
//            DisplayLogAllCh(-1,False,lstTemp[3]);
            sTemp := Format('%0.4f',[StrToFloatDef(lstTemp[1],0.0)]);
            GetxyLv.x := StrToFloatDef(sTemp,0.0);
            sTemp := Format('%0.4f',[StrToFloatDef(lstTemp[2],0.0)]);
            GetxyLv.y := StrToFloatDef(sTemp,0.0);
            // Added by ClintPark 2018-11-30 오후 6:29:24 초기 B1 모델에서 User Cal시 소수점 2자리 까지 적용해서 0.1f ==> 0.2f 변경.
            // User Cal시 소수점 한자리로 적용 하기 때문에 상관 없음....
            sTemp := Format('%0.1f',[StrToFloatDef(lstTemp[3],0.0)]);
            GetxyLv.Lv := StrToFloatDef(sTemp,0.0);
            GetAllxy[nRow-1] := GetxyLv;
          finally
            lstTemp.Free;
          end;
          Inc(nRow);
        end;
      finally
        CloseFile(txtF);
      end;
      if nRow < 3 then begin
        sDebug := 'Check File format file - NG:Not enough data';
        DisplayLogAllCh(-1,True,sDebug);
        Exit;
      end;
      if not bRet then begin
        sDebug := 'Check File format file - NG:Check x,y,Lv';
        DisplayLogAllCh(-1,True,sDebug);
        Exit;
      end;
    end;

    // 각 Probe별 Target값 Check.
    bIsOk := True;

    for i := DefCa310.IDX_RED to DefCa310.IDX_MAX do begin
      MemChInfo.x := 0.0; MemChInfo.y := 0.0; MemChInfo.Lv := 0.0;
      tempMemInfo.x := 0.0; tempMemInfo.y := 0.0; tempMemInfo.Lv := 0.0;

      if i = DefCa310.IDX_WHITE then begin
        nMemCh := Common.TestModelInfo2.Ca310MemCh;
      end
      else begin
        nMemCh := Common.TestModelInfo2.Ca310MemCh+i+1;
      end;
      DongaCa310[Self.Tag].RBrightobj.objCa.Memory.ChannelNO :=  nMemCh;
      bRet := False;
      for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        sProbe := Format('P%d',[nCh + 1]);
        if not Common.SystemInfo.UseCh[Self.Tag*4+nCh] then Continue;

        DongaCa310[Self.Tag].RBrightobj.objCa.Memory.GetReferenceColor(sProbe,tempMemInfo.x, tempMemInfo.y, tempMemInfo.Lv);
        sTemp := Format('%0.4f',[tempMemInfo.x]);
        MemChInfo.x := StrToFloatDef(sTemp,0.0);
        sTemp := Format('%0.4f',[tempMemInfo.y]);
        MemChInfo.y := StrToFloatDef(sTemp,0.0);
        sTemp := Format('%0.1f',[tempMemInfo.Lv]);
        MemChInfo.Lv := StrToFloatDef(sTemp,0.0);

        if MemChInfo.x <> GetAllxy[i].x then begin
          sDebug := Format('NG - MemCh(%d):Measure X(%.4f)/Target X(%0.4f)',[nMemCh,MemChInfo.x, GetAllxy[i].x]);
          DisplayLogAllCh(nCh,True,sDebug);
          bRet := True;
        end;

        if MemChInfo.y <> GetAllxy[i].y then begin
          sDebug := Format('NG - MemCh(%d):Measure Y(%.4f)/Target Y(%0.4f)',[nMemCh,MemChInfo.y, GetAllxy[i].y]);
          DisplayLogAllCh(nCh,True,sDebug);
          bRet := True;
        end;

        if MemChInfo.Lv <> GetAllxy[i].Lv then begin
          sDebug := Format('NG - MemCh(%d):Measure Lv(%.1f)/Target Lv(%0.1f)',[nMemCh,MemChInfo.Lv, GetAllxy[i].Lv]);
          DisplayLogAllCh(nCh,True,sDebug);
          bRet := True;
        end;
        if not bRet then begin
          sDebug := Format('OK - MemCh(%d):Measure x,y,Lv(%0.4f,%0.4f,%0.1f)',[nMemCh,MemChInfo.x,MemChInfo.y,MemChInfo.Lv]);
          DisplayLogAllCh(nCh,False,sDebug);
        end;

      end;
      bIsOk := bIsOk and (not bRet);
    end;
    if bIsOk then begin
      sDebug := 'User Cal Check OK';
      DisplayLogAllCh(-1,False,sDebug);
      m_nCheckCa310 := DefCommon.CHECK_CA310_OK;
    end
    else begin
      sDebug := 'User Cal Check NG';
      DisplayLogAllCh(-1,True,sDebug);
      m_nCheckCa310 := DefCommon.CHECK_CA310_USER_CAL_NG;
    end;
    // Check Probe Serial.
    bIsOk := True;
    for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      if Common.SystemInfo.ProbAddr[nCh+Self.Tag*4] <> '' then begin
        sIdx := Format('P%d',[nCh+1]);
        sGetSerial := DongaCa310[Self.Tag].RBrightobj.objCa.OutputProbes.Item[sIdx].SerialNO;
        if Common.SystemInfo.ProbAddr[nCh+Self.Tag*4] <> sGetSerial then begin
          bIsOk := False;
          sDebug := Format('NG - Probe Serial Checking[%s,Target:%s]',[sGetSerial,Common.SystemInfo.ProbAddr[nCh+Self.Tag*4]]);
          DisplayLogAllCh(nCh,True,sDebug);
        end
        else begin
          sDebug := Format('OK - Probe Serial Checking[%s]',[sGetSerial]);
          DisplayLogAllCh(nCh,False,sDebug);
        end;
      end
      else begin
        bIsOk := False
      end;
    end;
    if not bIsOk then begin
      m_nCheckCa310 := DefCommon.CHECK_CA310_PROBE_NG;
    end;
  end;
end;

function TfrmTest4ChGB.CheckScriptRun: Boolean;
var
  bRet : Boolean;
begin
  bRet := False;
  if JigLogic[Self.Tag] <> nil then begin
    bRet := JigLogic[self.Tag].IsScriptRunning;
  end;
  Result := bRet;
end;

procedure TfrmTest4ChGB.btnVirtualKeyClick(Sender: TObject);
begin
  pnlSwitch.Visible := not pnlSwitch.Visible;
  pnlSwitch.Left := pnlUnitTact.Left;
  pnlSwitch.Top  := pnlUnitTact.Top;
end;

procedure TfrmTest4ChGB.chkPgClick(Sender: TObject);
var
  i : integer;
  wCh : word;
  sTemp : string;
  bTemp : boolean;
begin
  bTemp := False;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if Sender = chkChannelUse[i] then begin
      if chkChannelUse[i].Checked then  chkChannelUse[i].Font.Color := clGreen
      else                              chkChannelUse[i].Font.Color := clRed;
      Logic[i+self.Tag*4].m_bUse := chkChannelUse[i].Checked;
      PasScr[i+self.Tag*4].m_bUse := chkChannelUse[i].Checked;
      if PasScr[i+self.Tag*4].m_bUse then bTemp := True;
//        PlcCtl.writePlc(Self.Tag,0,defPlc.OUT_SEL_CH1 shl i ,not (ledPGStatuses[i].Value and chkChannelUse[i].Checked));// (Logic[i+self.Tag*4].m_bUse and ledPGStatuses[i].Value));
//        PlcCtl.writePlc(Self.Tag,1,defPlc.OUT_READY_CH1 shl i ,not (ledPGStatuses[i].Value and chkChannelUse[i].Checked));//(Logic[i+self.Tag*4].m_bUse and ledPGStatuses[i].Value));
      Break;
    end;
  end;
  if bTemp then begin
    if PlcCtl <> nil then begin
      // Main Ready 죽이자.
//      PlcCtl.writePlc(Self.Tag, defPlc.IDX_FIRST_WORD,defPlc.OUT_PC_READY,True);
    end;
  end;
  if JigLogic[Self.Tag] <> nil then begin
    sTemp := '';
    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
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

procedure TfrmTest4ChGB.ClearChData(nCh: Integer);
begin
  pnlSerials[nCh].Caption := '';
  if Common.SystemInfo.OcManualType then begin
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlSerials[nCh].Color := clBlack;
      pnlSerials[nCh].Font.Color := clYellow;
    end
    else begin
      pnlSerials[nCh].Color := clBtnFace;
      pnlSerials[nCh].Font.Color := clBlack;
    end;
  end;


  pnlMESResults[nCh].Caption := '';
  if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
    pnlPGStatuses[nCh].Color := clBlack;
    pnlPGStatuses[nCh].Font.Color := clWhite;
    pnlMESResults[nCh].Color := clBlack;
    pnlMESResults[nCh].Font.Color := clWhite;
  end
  else begin
    pnlPGStatuses[nCh].Color := clBtnFace;
    pnlPGStatuses[nCh].Font.Color := clBlack;
    pnlMESResults[nCh].Color := clBtnFace;
    pnlMESResults[nCh].Font.Color := clYellow;
  end;
  pnlPGStatuses[nCh].Font.Size := 24;
  pnlPGStatuses[nCh].Caption := 'Ready';
  pnlPGStatuses[nCh].Font.Name := 'Verdana';     //Tahoma

  gridPWRPGs[nCh].ClearAll;
  gridPWRPGs[nCh].ColumnHeaders.Add('');
  gridPWRPGs[nCh].ColumnHeaders.Add('Voltage');
  gridPWRPGs[nCh].ColumnHeaders.Add('Current');
  gridPWRPGs[nCh].ColumnHeaders.Add('');
  gridPWRPGs[nCh].ColumnHeaders.Add('Voltage');
  gridPWRPGs[nCh].ColumnHeaders.Add('Current');
  gridPWRPGs[nCh].Cells[0,1] := 'VPNL';
  gridPWRPGs[nCh].Cells[0,2] := 'VDDI';
  gridPWRPGs[nCh].Cells[0,3] := 'T_AVDD';
  gridPWRPGs[nCh].Cells[0,4] := 'VPP';
  gridPWRPGs[nCh].Cells[0,5] := 'VBAT';
  gridPWRPGs[nCh].Cells[0,6] := 'VCI';

  gridPWRPGs[nCh].Cells[3,1] := 'VCI';
  gridPWRPGs[nCh].Cells[3,2] := 'VDDEL';
  gridPWRPGs[nCh].Cells[3,3] := 'VSSEL';
  gridPWRPGs[nCh].Cells[3,4] := 'DDVDH';
  mmChannelLog[nCh].Clear;
end;

procedure TfrmTest4ChGB.CreateGui;
var
  i, nItemHeight, nItemWidth, j : Integer;
  nFontSize : Integer;
  sTemp : string;
begin

  //  // tact time을 위한 timer.
  m_nTotalTact:= 0;
  tmTotalTactTime := TTimer.Create(Self);
  tmTotalTactTime.Interval := 1000;
  tmTotalTactTime.OnTimer := OnTotalTimer;
  tmTotalTactTime.Enabled := False;

  m_nUnitTact := 0;
  tmUnitTactTime := TTimer.Create(Self);
  tmUnitTactTime.Interval := 1000;
  tmUnitTactTime.OnTimer := OnUnitTimer;
  tmUnitTactTime.Enabled := False;

  pnlTestMain.Visible := False;

  nItemWidth := (Self.Width - pnlJigInform.Width - pnlJigInform.Left) div (DefCommon.MAX_JIG_CH +1)-2;
  nItemHeight := 26;
//  // Jig 정보를 위한 Panel.
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
//  pnlJigTitle.Caption := Format(' %X Stage',[10+Self.Tag]);
//  pnlJigTitle.StyleElements := [];

  // button for start testing.
  btnStartTest := TRzBitBtn.Create(self);
  btnStartTest.Parent := pnlJigInform;
  btnStartTest.Top := 2;//pnlJigTitle.Top + pnlJigTitle.Height + 1;//2;
  btnStartTest.Left := 2;//100;
  btnStartTest.Height := 60;
  btnStartTest.Width := pnlJigInform.Width -3;//90;// pnlJig[nJig].Width div nMaxCh;
  btnStartTest.Font.Size := 12;
  btnStartTest.Cursor := crHandPoint;
  btnStartTest.HotTrack := True;
  btnStartTest.Caption := 'bắt đầu   (Start)';
  btnStartTest.Cursor  := crHandPoint;
  btnStartTest.OnClick := BtnStartTestClick;

  // button for start testing.
  btnStopTest := TRzBitBtn.Create(self);
  btnStopTest.Parent := pnlJigInform;
  btnStopTest.Top := btnStartTest.Top + btnStartTest.Height + 1; //pnlJigTitle.Top + pnlJigTitle.Height + 1;//2;
  btnStopTest.Left := 2;// 94;//200;
  btnStopTest.Height := 60;
  btnStopTest.Width := pnlJigInform.Width -3; //90;// pnlJig[nJig].Width div nMaxCh;
  btnStopTest.Font.Size := 12;
  btnStopTest.HotTrack := True;
  btnStopTest.Caption := 'Dừng lại (Stop)';
  btnStopTest.Cursor  := crHandPoint;
  btnStopTest.OnClick := BtnStopTestClick;
  btnStopTest.Cursor := crHandPoint;

  // for Jig Information.
  pnlTackTimes := TRzPanel.Create(self);
  pnlTackTimes.Parent := pnlJigInform;
  pnlTackTimes.Top := btnStopTest.Top + btnStopTest.Height + 1;// btnStartTest.Top + btnStartTest.Height + 1;//pnlPGStatuses[nJig].Top + pnlPGStatuses[nJig].Height;
  pnlTackTimes.Left := 2;
  pnlTackTimes.Height := nItemHeight;
  pnlTackTimes.Width := pnlJigInform.Width -3 ;// 90;//66;
  pnlTackTimes.Caption := 'Total Tact';
  pnlTackTimes.BorderOuter := TframeStyleEx(fsFlat);
  pnlTackTimes.Font.Size := 12;

  pnlNowValues := TPanel.Create(self);
  pnlNowValues.Parent := pnlJigInform;
  pnlNowValues.Top := pnlTackTimes.Top + pnlTackTimes.Height + 1;// pnlTackTimes.Top;
  pnlNowValues.Left := 2;//pnlTackTimes.Left + pnlTackTimes.Width + 1;
  pnlNowValues.Height := nItemHeight*2;
  pnlNowValues.Width := pnlJigInform.Width -3;// 90;
  pnlNowValues.Caption := '00 : 00';
  pnlNowValues.Color := clBlack;
  pnlNowValues.Font.Color := clLime;
  pnlNowValues.Font.Size := 20;
  pnlNowValues.StyleElements := [];

  pnlUnitTact := TRzPanel.Create(self);
  pnlUnitTact.Parent := pnlJigInform;
  pnlUnitTact.Top := pnlNowValues.Top + pnlNowValues.Height + 1;// //pnlTackTimes.Top + pnlTackTimes.Height + 1;
  pnlUnitTact.Left := 2;//pnlNowValues.Left + pnlNowValues.Width+ 1;
  pnlUnitTact.Height := nItemHeight;
  pnlUnitTact.Width := pnlJigInform.Width -3 ;//90;//66;
  pnlUnitTact.Caption := 'OC Tact';
  pnlUnitTact.Font.Size := 8;
  pnlUnitTact.BorderOuter := TframeStyleEx(fsFlat);
  pnlUnitTact.Font.Size := 12;
  pnlUnitTact.OnClick := btnVirtualKeyClick;

  pnlUnitTactVal := TPanel.Create(self);
  pnlUnitTactVal.Parent := pnlJigInform;
  pnlUnitTactVal.Top := pnlUnitTact.Top + pnlUnitTact.Height + 1;
  pnlUnitTactVal.Left := 2;//pnlUnitTact.Left + pnlUnitTact.Width+ 1;
  pnlUnitTactVal.Height := nItemHeight*2;
  pnlUnitTactVal.Width := pnlJigInform.Width -3 ;//90;
  pnlUnitTactVal.Caption := '00 : 00';
  pnlUnitTactVal.Color := clBlack;
  pnlUnitTactVal.Font.Color := clYellow;
  pnlUnitTactVal.Font.Size := 20;
  pnlUnitTactVal.StyleElements := [];


//  // button for start testing.
//  btnVirtualKey := TRzBitBtn.Create(self);
//  btnVirtualKey.Parent := pnlJigInform;
//  btnVirtualKey.Top := pnlUnitTact.Top + pnlUnitTact.Height + 1;//2;
//  btnVirtualKey.Left := 2;//200;
//  btnVirtualKey.Height := 30;
//  btnVirtualKey.Width := 180;// pnlJig[nJig].Width div nMaxCh;
//  btnVirtualKey.Font.Size := 12;
//  btnVirtualKey.Caption := 'Show Virtual Key';
//  btnVirtualKey.OnClick := btnVirtualKeyClick;
//  btnVirtualKey.Cursor := crHandPoint;
//  btnVirtualKey.HotTrack := True;

  lstPwrView := TAdvListView.Create(self);
  lstPwrView.Parent := pnlJigInform;
  lstPwrView.Top := pnlUnitTactVal.Top +  pnlUnitTactVal.Height + 1;
  lstPwrView.Left := 2;
  lstPwrView.Height := nItemHeight*6;
  lstPwrView.Width := pnlJigInform.Width -3 ;//180;
  lstPwrView.Font.Size := 8;
  lstPwrView.ViewStyle := vsReport;
  lstPwrView.Columns.Add.Caption := 'Power';
  lstPwrView.Columns.Add.Caption := 'Voltage';
  lstPwrView.Columns[0].Width := (pnlJigInform.Width -6) div 2 - 1;
  lstPwrView.Columns[1].Width := (pnlJigInform.Width -8) div 2 - 1;
  with lstPwrView do begin
    with Items.Add do begin
      Caption := 'VPNL';//'VCI';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VCI] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VDDI';//'DVDD';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_DVDD] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'T_AVDD';//'VDD';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VDD] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VPP';//'VPP';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VPP] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VBAT';//'VBAT';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VBAT] / 100]);
      SubItems.Add(sTemp);
    end;
    with Items.Add do begin
      Caption := 'VCI';//'VNEG';
      sTemp := Format('%0.2f',[Common.TempModelInfo.PWR_VOL[DefCommon.PWR_VNEG] / 100]);
      SubItems.Add(sTemp);
    end;
  end;
  // detailed items for each channel.
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
    pnlHwVersion[i].Font.Size := 10;
    pnlHwVersion[i].Align := alTop;
    pnlHwVersion[i].Font.Color  := clBlack;
    pnlHwVersion[i].Alignment := taRightJustify;
    pnlHwVersion[i].Caption := '';
    pnlHwVersion[i].Hint    := 'FW , FPGA , MDM , Power Version';
    pnlHwVersion[i].ShowHint := True;
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

    pnlSerials[i] := TPanel.Create(self);
    pnlSerials[i].Parent := pnlChGrp[i];
    pnlSerials[i].Top := chkChannelUse[i].Top + chkChannelUse[i].Height;
    pnlSerials[i].Height := nItemHeight;
    pnlSerials[i].Align := alTop;
    pnlSerials[i].Color := clBtnFace;
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlSerials[i].Color := clBlack;
      pnlSerials[i].Font.Color := clYellow;
    end
    else begin
      pnlSerials[i].Color := clBtnFace;
      pnlSerials[i].Font.Color := clBlack;
    end;
    pnlSerials[i].Hint  := 'Serial Number';
    pnlSerials[i].ShowHint  := True;
    pnlSerials[i].Alignment := taCenter;
    pnlSerials[i].Font.Name := 'Tahoma';
    pnlSerials[i].Caption := '';//Format('23020218LN36A308416900A2%sC231369V16A3169WFB0000%d',[chr(10),i]);
    pnlSerials[i].ParentBackground := False;
    pnlSerials[i].StyleElements := [];
    pnlSerials[i].Font.Size := 10;

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
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlMESResults[i].Color := clBlack;
      pnlMESResults[i].Font.Color := clWhite;
    end
    else begin
      pnlMESResults[i].Color := clBtnFace;
      pnlMESResults[i].Font.Color := clYellow;
    end;

    pnlMESResults[i].Font.Size := 12;
    pnlMESResults[i].ParentBackground := False;
    pnlMESResults[i].StyleElements := [];

    pnlPGStatuses[i] := TPanel.Create(Self);
    pnlPGStatuses[i].Parent := pnlChGrp[i];
//    pnlPGStatuses[i].Top := pnlMESResults[i].Top + pnlMESResults[i].Height;
    pnlPGStatuses[i].Top := pnlChGrp[i].Height;
    pnlPGStatuses[i].Align := alTop;
    pnlPGStatuses[i].Caption := 'Ready';
    pnlPGStatuses[i].Font.Name := 'Verdana';
    pnlPGStatuses[i].Hint := 'Inspection Result';
    pnlPGStatuses[i].ShowHint := True;
    pnlPGStatuses[i].Color := clBtnFace;
    pnlPGStatuses[i].Font.Size := 24;
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

    nFontSize := 12;

    pnlTotalNames[i] := TPanel.Create(self);
    pnlTotalNames[i].Parent := pnlTimeNResult[i];
    pnlTotalNames[i].Top := 1;
    pnlTotalNames[i].Left := 0;
    pnlTotalNames[i].Height := pnlTimeNResult[i].Height;
    pnlTotalNames[i].Width := 90;
    pnlTotalNames[i].Caption := 'sản xuất(Total)';
    pnlTotalNames[i].Font.Size := nFontSize - 4;
//
    pnlTotalValues[i] := TPanel.Create(self);
    pnlTotalValues[i].Parent := pnlTimeNResult[i];
    pnlTotalValues[i].Top := 1;
    pnlTotalValues[i].Left := pnlTotalNames[i].Left + pnlTotalNames[i].Width + 1;
    pnlTotalValues[i].Height :=  pnlTimeNResult[i].Height-2;
    pnlTotalValues[i].Width := 74;
    pnlTotalValues[i].Caption := '0';
    pnlTotalValues[i].Font.Size := nFontSize + 4;
    pnlTotalValues[i].Color := clBlack;
    pnlTotalValues[i].Font.Color := clYellow;
    pnlTotalValues[i].StyleElements := [];


    pnlOKNames[i] := TPanel.Create(Self);
    pnlOKNames[i].Parent := pnlTimeNResult[i];
    pnlOKNames[i].Top := 1;
    pnlOKNames[i].Left := pnlTotalValues[i].Left + pnlTotalValues[i].Width + 1;
    pnlOKNames[i].Height := pnlTimeNResult[i].Height;
    pnlOKNames[i].Width := 36;
    pnlOKNames[i].Caption := 'OK';
    pnlOKNames[i].Font.Size := nFontSize-2;

    pnlOKValues[i] := TPanel.Create(Self);
    pnlOKValues[i].Parent := pnlTimeNResult[i];
    pnlOKValues[i].Top := 1;
    pnlOKValues[i].Left := pnlOKNames[i].Left + pnlOKNames[i].Width + 1;
    pnlOKValues[i].Height := pnlTimeNResult[i].Height-2;
    pnlOKValues[i].Width := 74;
    pnlOKValues[i].Color := clBlack;
    pnlOKValues[i].Caption := '0';
    pnlOKValues[i].Font.Size := nFontSize + 4;
    pnlOKValues[i].Font.Color := clLime;
    pnlOKValues[i].StyleElements := [];


    pnlNGNames[i] := TPanel.Create(Self);
    pnlNGNames[i].Parent := pnlTimeNResult[i];
    pnlNGNames[i].Top := 1;
    pnlNGNames[i].Left := pnlOKValues[i].Left + pnlOKValues[i].Width + 1;
    pnlNGNames[i].Height := pnlTimeNResult[i].Height;
    pnlNGNames[i].Width := 36;
    pnlNGNames[i].Font.Size := nFontSize-2;
    pnlNGNames[i].Caption := 'NG';

    pnlNGValues[i] := TPanel.Create(Self);
    pnlNGValues[i].Parent := pnlTimeNResult[i];
    pnlNGValues[i].Top := 1;
    pnlNGValues[i].Left := pnlNGNames[i].Left + pnlNGNames[i].Width + 1;
    pnlNGValues[i].Height := pnlTimeNResult[i].Height-2;
    pnlNGValues[i].Width := 70;
    pnlNGValues[i].Color := clBlack;
    pnlNGValues[i].Caption := '0';
    pnlNGValues[i].Font.Size := nFontSize + 4;
    pnlNGValues[i].Font.Color := clRed;
    pnlNGValues[i].StyleElements := [];

    pnlGrpDio[i] := TPanel.Create(Self);
    pnlGrpDio[i].Parent := pnlChGrp[i];
    pnlGrpDio[i].Align := alTop;
    pnlGrpDio[i].Top := 275;
    pnlGrpDio[i].Height := 116;

    gridPWRPGs[i] := TAdvStringGrid.Create(Self);
    gridPWRPGs[i].Clear;
    gridPWRPGs[i].Parent := pnlGrpDio[i];
    gridPWRPGs[i].Font.Name := 'Tahoma';
    gridPWRPGs[i].Top := 275;
    gridPWRPGs[i].Height := 114;
    gridPWRPGs[i].Width  := 300;
    gridPWRPGs[i].Align := alLeft;
    gridPWRPGs[i].ColCount := 6;
    gridPWRPGs[i].RowCount := 6;
    gridPWRPGs[i].FixedCols := 0;
    gridPWRPGs[i].ColumnHeaders.Add('');
    gridPWRPGs[i].ColumnHeaders.Add('V'{'Voltage'});
    gridPWRPGs[i].ColumnHeaders.Add('mA'{'Current'});
    gridPWRPGs[i].ColumnHeaders.Add('');
    gridPWRPGs[i].ColumnHeaders.Add('V'{'Voltage'});
    gridPWRPGs[i].ColumnHeaders.Add('mA'{'Current'});

    pnlDioConTactUp[i] := TPanel.Create(Self);
    pnlDioConTactUp[i].Parent := pnlGrpDio[i];
    pnlDioConTactUp[i].Top := 1;
    pnlDioConTactUp[i].Left := gridPWRPGs[i].Width + 2 ;
    pnlDioConTactUp[i].Height := 18;
    pnlDioConTactUp[i].Width := 85;
    pnlDioConTactUp[i].Font.Size := nFontSize-2;
    pnlDioConTactUp[i].Caption := 'Contact Up';
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlDioConTactUp[i].Color   := clBlack;
      pnlDioConTactUp[i].Font.Color := clWhite;
    end
    else begin
      pnlDioConTactUp[i].Color   := clBtnFace;
      pnlDioConTactUp[i].Font.Color := clBlack;
    end;
    pnlDioConTactUp[i].StyleElements := [];
    pnlDioConTactUp[i].Visible := not common.SystemInfo.OcManualType;

    pnlDioConTactDn[i] := TPanel.Create(Self);
    pnlDioConTactDn[i].Parent := pnlGrpDio[i];
    pnlDioConTactDn[i].Top := pnlDioConTactUp[i].Top + pnlDioConTactUp[i].Height + 1;
    pnlDioConTactDn[i].Left := gridPWRPGs[i].Width + 2 ;
    pnlDioConTactDn[i].Height := 18;
    pnlDioConTactDn[i].Width := 85;
    pnlDioConTactDn[i].Font.Size := nFontSize-2;
    pnlDioConTactDn[i].Caption := 'Contact DN';
    pnlDioConTactDn[i].StyleElements := [];
    pnlDioConTactDn[i].Color   := clBtnFace;
    pnlDioConTactDn[i].Visible := not common.SystemInfo.OcManualType;
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlDioConTactDn[i].Color   := clBlack;
      pnlDioConTactDn[i].Font.Color := clWhite;
    end
    else begin
      pnlDioConTactUp[i].Color   := clBtnFace;
      pnlDioConTactUp[i].Font.Color := clBlack;
    end;

    pnlDioDetect[i] := TPanel.Create(Self);
    pnlDioDetect[i].Parent := pnlGrpDio[i];
    pnlDioDetect[i].Top := pnlDioConTactDn[i].Top + pnlDioConTactDn[i].Height + 1;
    pnlDioDetect[i].Left := gridPWRPGs[i].Width + 2 ;
    pnlDioDetect[i].Height := 18;
    pnlDioDetect[i].Width := 85;
    pnlDioDetect[i].Font.Size := nFontSize-2;
    pnlDioDetect[i].Caption := 'Carrier';
    pnlDioDetect[i].StyleElements := [];
    pnlDioDetect[i].Color   := clBtnFace;
    pnlDioDetect[i].Visible := not common.SystemInfo.OcManualType;
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      pnlDioDetect[i].Color   := clBlack;
      pnlDioDetect[i].Font.Color := clWhite;
    end
    else begin
      pnlDioDetect[i].Color   := clBtnFace;
      pnlDioDetect[i].Font.Color := clBlack;
    end;

    if common.SystemInfo.OcManualType then begin
      pnlDioPresure[i] := TPanel.Create(Self);
      pnlDioPresure[i].Parent := pnlGrpDio[i];
      pnlDioPresure[i].Top := 1;
      pnlDioPresure[i].Left := gridPWRPGs[i].Width + 2 ;
      pnlDioPresure[i].Height := 40;
      pnlDioPresure[i].Width := 85;
      pnlDioPresure[i].Font.Size := nFontSize-2;
      pnlDioPresure[i].Caption := 'Presure Sen';
      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
        pnlDioPresure[i].Color   := clBlack;
        pnlDioPresure[i].Font.Color := clWhite;
      end
      else begin
        pnlDioPresure[i].Color   := clBtnFace;
        pnlDioPresure[i].Font.Color := clBlack;
      end;
      pnlDioPresure[i].StyleElements := [];
      pnlDioPresure[i].Visible := common.SystemInfo.OcManualType;
    end;
    for j := 0 to DefCommon.MAX_PREVIOUS_RESULT do begin
      pnlPrevResult[i,j] := TPanel.Create(Self);
      pnlPrevResult[i,j].Parent := pnlGrpDio[i];
      pnlPrevResult[i,j].Top := pnlDioDetect[i].Top + pnlDioDetect[i].Height + 4 + j*18;
      pnlPrevResult[i,j].Left := gridPWRPGs[i].Width + 2 ;
      pnlPrevResult[i,j].Height := 18;
      pnlPrevResult[i,j].Width := 85;
      pnlPrevResult[i,j].Font.Size := nFontSize-2;
      pnlPrevResult[i,j].Caption := Format('Result %d',[j+1]);
      pnlPrevResult[i,j].StyleElements := [];
      pnlPrevResult[i,j].Color   := clBtnFace;
      pnlPrevResult[i,j].Visible := True;// not common.SystemInfo.OcManualType;
      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
        pnlPrevResult[i,j].Color   := clBlack;
        pnlPrevResult[i,j].Font.Color := clWhite;
      end
      else begin
        pnlPrevResult[i,j].Color   := clBtnFace;
        pnlPrevResult[i,j].Font.Color := clBlack;
      end;
    end;

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
    if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
      mmChannelLog[i].Color := clBlack;
      mmChannelLog[i].Font.Color := clWhite;
//      mmChannelLog[i].StyleElements := [];
    end
    else begin
//      mmChannelLog[i].StyleElements := [];//[seFont, seClient, seBorder];
      mmChannelLog[i].Font.Color := clBlack;
      mmChannelLog[i].Color := clWhite;
    end;

  end;
//  pnlErrAlram.Parent := self; // 화면 뒤에 있지 않도록 Parent를 변경.
  pnlSwitch.Parent := self;   // 화면 뒤에 있지 않도록 Parent를 변경.
//
//  btnAuto.Caption := 'Auto';
//  btnRepeat.Caption := 'Repeat';
//
  pnlSwitch.Visible := False;
////  SetLanguage(common.SystemInfo.Language);
//  pnlInputSerial.Parent := self;
//  pnlInputSerial.Visible := False;
//  pnlJig.EnableAlign;
//  pnlJig.Visible := True;
//  SetHostConnShow(False);
  pnlTestMain.Visible := True;
end;


procedure TfrmTest4ChGB.DioWorkDone(nErrCode: Integer; sErrMsg: string);
var
  i, nStart, nEnd : Integer;
begin
  case nErrCode of
    0 : begin
      if JigLogic[Self.Tag] <> nil then begin
        nStart := Self.Tag*4;
        nEnd   := Pred(nStart+4);
        for i := nStart to nEnd do begin
          PasScr[i].m_nDioErrCode := 0;
          PasScr[i].SetDioEvent;
          PasScr[i].m_bIsProbeBackSig := False;
        end;
      end;
      if  m_bAutoPlcProbeBack then begin
        m_bAutoPlcProbeBack := False;
  //      tmTotalTactTime.Enabled := False;
        if PlcCtl <> nil then begin
          PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_UNLOAD);
  //        PlcCtl.m_bInsStart[self.Tag] := False;
        end;
      end;
    end;
    // PLC ==> No Probe front Mode ---- NG Case.
    2 : begin
      if JigLogic[Self.Tag] <> nil then begin
        nStart := Self.Tag*4;
        nEnd   := Pred(nStart+4);
        for i := nStart to nEnd do begin
          PasScr[i].m_nDioErrCode := 2;
          PasScr[i].SetDioEvent;
          PasScr[i].m_bIsProbeBackSig := False;
        end;
      end;
    end;
  end;
end;

procedure TfrmTest4ChGB.DisplayLogAllCh(nCh : Integer; bNg: Boolean; sMsg: string);
var
  i : Integer;
begin
  if nCh < Defcommon.CH1 then begin
    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      if bNg then begin
        mmChannelLog[i].SelAttributes.Color := clRed;
        mmChannelLog[i].SelAttributes.Style := [fsBold];
      end;
      mmChannelLog[i].Lines.Add(sMsg);
      Common.MLog(i+self.Tag*4,sMsg);
//      mmChannelLog[i].Perform(EM_SCROLL,SB_LINEDOWN,0);
      CalcLogScroll(i,Length(sMsg));
    end;
  end
  else begin
    if bNg then begin
      mmChannelLog[nCh].SelAttributes.Color := clRed;
      mmChannelLog[nCh].SelAttributes.Style := [fsBold];
    end;
    mmChannelLog[nCh].Lines.Add(sMsg);
    Common.MLog(nCh+self.Tag*4,sMsg);
    CalcLogScroll(nCh,Length(sMsg));
//    mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
  end;
end;

procedure TfrmTest4ChGB.DisplayPGStatus(nPgNo, nType: Integer; sMsg: string);
var
  nCh : Integer;
begin
  nCh := nPgNo mod 4;
  try
    case nType of
      0 : begin
        ledPGStatuses[nCh].Value := True;
//        if PlcCtl <> nil then begin
//          PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl nCh ,not Logic[nCh+self.Tag*4].m_bUse);
//          PlcCtl.writePlc(Self.Tag,defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl nCh ,not Logic[nCh+self.Tag*4].m_bUse);
//        end;
      end;
      1 : pnlHwVersion[nCh].Caption := sMsg;
      2 : begin
        ledPGStatuses[nCh].FalseColor := clRed;
        ledPGStatuses[nCh].Value := False;
        pnlHwVersion[nCh].Caption := '';
//        if PlcCtl <> nil then begin
//          PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl nCh ,True);
//          PlcCtl.writePlc(Self.Tag,defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl nCh ,True);
//        end;
      end;
    end;
  except
    Common.DebugMessage('>> DisplayPGStatus Exception Error! ' + IntToStr(nPgNo+1));
  end;
end;

procedure TfrmTest4ChGB.DisplayPreviousRet(nCh: Integer);
var
  i, nPg : Integer;
begin
  nPg := nCh+self.Tag*4;
  for i := 1 to pred(PasScr[nPg].m_lstPrevRet.Count) do begin
    if i > (Defcommon.MAX_PREVIOUS_RESULT + 1) then Continue;
    if PasScr[nPg].m_lstPrevRet.Items[i] = 0 then begin
      pnlPrevResult[nCh,i-1].Caption  := 'Pass';
      pnlPrevResult[nCh,i-1].Color    := clLime;
      pnlPrevResult[nCh,i-1].Font.Color    := clBlack;
    end
    else begin
      pnlPrevResult[nCh,i-1].Caption  := Format('OD %0.2d',[PasScr[nPg].m_lstPrevRet.Items[i]]);
      pnlPrevResult[nCh,i-1].Color    := clRed;
      pnlPrevResult[nCh,i-1].Font.Color    := clBlack;
    end;
  end;
end;

procedure TfrmTest4ChGB.DisplayPwrData(nPgNo: Integer; PwrData: ReadVoltCurr);
begin
  gridPWRPGs[nPgNo].DisableAlign;
  // voltage.
  gridPWRPGs[nPgNo].Cells[1,1] := Format('%0.3f',[PwrData.VCI / 1000]);
  gridPWRPGs[nPgNo].Cells[1,2] := Format('%0.3f',[PwrData.DVDD / 1000]);
  gridPWRPGs[nPgNo].Cells[1,3] := Format('%0.3f',[PwrData.VDD / 1000]);
  gridPWRPGs[nPgNo].Cells[1,4] := Format('%0.3f',[PwrData.VPP / 1000]);
  gridPWRPGs[nPgNo].Cells[1,5] := Format('%0.3f',[PwrData.VBAT / 1000]);

  gridPWRPGs[nPgNo].Cells[4,1] := Format('%0.3f',[PwrData.VNEG / 1000]);
  gridPWRPGs[nPgNo].Cells[4,2] := Format('%0.3f',[PwrData.ELVDD / 1000]);
  gridPWRPGs[nPgNo].Cells[4,3] := Format('%0.3f',[PwrData.ELVSS / 1000]);
  gridPWRPGs[nPgNo].Cells[4,4] := Format('%0.3f',[PwrData.DDVDH / 1000]);
  // current.
  gridPWRPGs[nPgNo].Cells[2,1] := Format('%0.3f',[PwrData.IVCI / 1000]);
  gridPWRPGs[nPgNo].Cells[2,2] := Format('%0.3f',[PwrData.IDVDD / 1000]);
  gridPWRPGs[nPgNo].Cells[2,3] := Format('%0.3f',[PwrData.IVDD / 1000]);
  gridPWRPGs[nPgNo].Cells[2,4] := Format('%0.3f',[PwrData.IVPP / 1000]);
  gridPWRPGs[nPgNo].Cells[2,5] := Format('%0.3f',[PwrData.IVBAT / 1000]);

  gridPWRPGs[nPgNo].Cells[5,1] := Format('%0.3f',[PwrData.IVNEG / 1000]);
  gridPWRPGs[nPgNo].Cells[5,2] := Format('%0.3f',[PwrData.IELVDD / 1000]);
  gridPWRPGs[nPgNo].Cells[5,3] := Format('%0.3f',[PwrData.IELVSS / 1000]);
  gridPWRPGs[nPgNo].Cells[5,4] := Format('%0.3f',[PwrData.IDDVDH / 1000]);
  gridPWRPGs[nPgNo].EnableAlign;

  {  gridPWRPGs[nPgNo].Cells[1,1] := Format('%0.3f',[PwrData.VCI   / 1000]);
  gridPWRPGs[nPgNo].Cells[1,2] := Format('%0.3f',[PwrData.DVDD  / 1000]);
  gridPWRPGs[nPgNo].Cells[1,3] := Format('%0.3f',[PwrData.VDD   / 1000]);
  gridPWRPGs[nPgNo].Cells[1,4] := Format('%0.3f',[PwrData.VPP   / 1000]);

  gridPWRPGs[nPgNo].Cells[4,1] := Format('%0.3f',[PwrData.VBAT  / 1000]);
  gridPWRPGs[nPgNo].Cells[4,2] := Format('%0.3f',[PwrData.ELVSS / 1000]);
  gridPWRPGs[nPgNo].Cells[4,3] := Format('%0.3f',[PwrData.DDVDH / 1000]);

  // current.
  gridPWRPGs[nPgNo].Cells[2,1] := Format('%0.3f',[PwrData.IVCI   / 1000]);
  gridPWRPGs[nPgNo].Cells[2,2] := Format('%0.3f',[PwrData.IDVDD  / 1000]);
  gridPWRPGs[nPgNo].Cells[2,3] := Format('%0.3f',[PwrData.IVDD   / 1000]);
  gridPWRPGs[nPgNo].Cells[2,4] := Format('%0.3f',[PwrData.IVPP   / 1000]);

  gridPWRPGs[nPgNo].Cells[5,1] := Format('%0.3f',[PwrData.IVBAT  / 1000]);
  gridPWRPGs[nPgNo].Cells[5,2] := Format('%0.3f',[PwrData.IELVSS / 1000]);
  gridPWRPGs[nPgNo].Cells[5,3] := Format('%0.3f',[PwrData.IDDVDH / 1000]);}
end;

procedure TfrmTest4ChGB.DisplaySysInfo;
var
  i, nPgNo: Integer;
begin
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    nPgNo := i+self.Tag * 4;
    chkChannelUse[i].Checked := Common.SystemInfo.UseCh[nPgNo];
    Logic[nPgNo].m_bUse := Common.SystemInfo.UseCh[nPgNo];
    PasScr[nPgNo].m_bUse := Common.SystemInfo.UseCh[nPgNo];
  end;
end;

procedure TfrmTest4ChGB.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin


//  if tmUnitTactTime <> nil then begin
//    tmUnitTactTime.Enabled := False;
//    tmUnitTactTime.Free;
//    tmUnitTactTime := nil;
//  end;
end;

procedure TfrmTest4ChGB.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  m_Rgb_Avr.AvgType := DefCommon.IDX_RGB_AVR_TYPE_NONE;
  m_nCurStatus := DefScript.SEQ_STOP;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    m_nOkCnt[i] := 0;
    m_nNgCnt[i] := 0;
  end;
  m_PlcStatus := psReadyPc;
  m_bAutoPlcProbeBack := False;
  m_nCheckCa310  := DefCommon.CHECK_CA310_NOT_CHECK;

  m_bInitGetAvr := False;
end;

procedure TfrmTest4ChGB.FormDestroy(Sender: TObject);
var
  i : Integer;
begin
  if tmTotalTactTime <> nil then begin
    tmTotalTactTime.Enabled := False;
    tmTotalTactTime.Free;
    tmTotalTactTime := nil;
  end;

  if tmUnitTactTime <> nil then begin
    tmUnitTactTime.Enabled := False;
    tmUnitTactTime.Free;
    tmUnitTactTime := nil;
  end;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin

//    if gridPWRPGs[i] <> nil then begin
//      for j := 0 to Pred(gridPWRPGs[i].ColCount) do begin
//        gridPWRPGs[i].Cols[j].Clear;
//      end;
//      gridPWRPGs[i].RowCount := 1;
//
//      gridPWRPGs[i].Free;
//      gridPWRPGs[i] := nil;
//    end;
    if mmChannelLog[i] <> nil then begin
      mmChannelLog[i].Free;
      mmChannelLog[i] := nil;
    end;
  end;

  if DongaCa310[Self.Tag] <> nil then begin
    DongaCa310[Self.Tag].Free;
    DongaCa310[Self.Tag] := nil;
  end;
  if DongaSwitch <> nil then begin
    DongaSwitch.Free;
    DongaSwitch := nil;
  end;
  if JigLogic[Self.Tag] <> nil then begin
    JigLogic[Self.Tag].Free;
    JigLogic[Self.Tag] := nil;
  end;
end;

procedure TfrmTest4ChGB.getBcrData(sScanData: string);
var
  nJig, nJigCh, nPgCh, i: Integer;
  bIsDone : Boolean;
  sDebug, sRemoveCr : string;
begin
  nJig := Self.Tag;
  sRemoveCr := StringReplace(sScanData,#$0a,'',[rfReplaceAll]);
  sRemoveCr := StringReplace(sRemoveCr,#$0d,'',[rfReplaceAll]);

  for nJigCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    sDebug := 'HandBCR: ' + sRemoveCr;
    if pnlSerials[nJigCh].Caption = sRemoveCr then Break;

    if pnlSerials[nJigCh].Caption <> '' then Continue;
    if not chkChannelUse[nJigCh].Checked then Continue;
    nPgCh  := nJig *4 + nJigCh;
    PasScr[nPgCh].m_TestRet.SerialNo  := sRemoveCr;
    sDebug := sDebug + Format(' ... CH %d',[nPgCh + 1]);
    Common.MLog(nPgCh,sDebug);
    pnlSerials[nJigCh].Caption := sRemoveCr;
    pnlSerials[nJigCh].Color := $0088AEFF;
    pnlSerials[nJigCh].Font.Color := clBlack;

    if DongaGmes <> nil then begin
      DongaGmes.SendHostIns_Pchk(sRemoveCr, nPgCh);
      pnlMESResults[nJigCh].Color      := clBtnFace;
      pnlMESResults[nJigCh].Font.Color := clBlack;
      pnlMESResults[nJigCh].Caption    := 'SEND INS_PCHK';
    end;
    Break;
  end;

  bIsDone := True;
  for nJigCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if pnlSerials[nJigCh].Caption <> '' then Continue;
    if not chkChannelUse[nJigCh].Checked then Continue;
    bIsDone := False;
    Break;
  end;
  if (UpperCase(Common.m_sUserId) = 'PM') then begin
    bIsDone := True;
  end;

  // input Barcode for all channels in a jig.
  if bIsDone then begin
    for nJigCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      nPgCh  := nJig *4 + nJigCh;
      PasScr[nPgCh].g_bIsBcrReady := True;
    end;
  end;

end;

procedure TfrmTest4ChGB.GetRgbAvgFromFile;
var
  slRgbData, slRgbFile : TStringList;
  sFileName, sData, sModelType, sDebug : String;
  i, j, nCnt, nAvrCnt, nAvrColCnt, nSumR, nSumG, nSumB : Integer;
  RgbAvgLogfile : TextFile;
begin
  Common.m_RgbAvr[self.Tag].IsReady := False;
  sModelType := Common.GetModelType(2,Common.SystemInfo.TestModel);
  sFileName := Common.Path.OtpCfg + format('JIG_%X_%s_PASS_RGB_DATA.txt',[Self.Tag + 10,sModelType]);
  m_Rgb_Avr.NgCode := 0;
  if not FileExists(sFileName) then begin
    m_Rgb_Avr.NgCode := 1;
    Exit;
  end;
  nCnt := 0;  nAvrCnt := 0; nAvrColCnt := 0;
  try
    slRgbFile := TStringList.Create;
    slRgbFile.LoadFromFile(sFileName);
    SetLength(m_RGB_Avr_Data,slRgbFile.Count); // Avr Data Count.

    for i := 0 to Pred(slRgbFile.Count) do begin
      try
        sData := slRgbFile[i];
        if Trim(sData) = '' then Continue;
        slRgbData := TStringList.Create;
        ExtractStrings([','],[],PChar(sData),slRgbData);
        // slRgbData[0] ==> 검사한 Channel 정보.
        nAvrColCnt := m_Rgb_Avr.Band * m_Rgb_Avr.GrayStep *3 + 1; // Band x Graylevel x r,g,b + channelNo.
        if slRgbData.Count < nAvrColCnt then Continue;   // 설마.... Band x Gray Step이 10보다 작은 경우는 없겠지.
        nAvrColCnt := slRgbData.Count;
        nCnt := slRgbData.Count div 3;
        SetLength(m_RGB_Avr_Data[nAvrCnt],nCnt);
        for j := 0 to pred(nCnt) do begin
          m_RGB_Avr_Data[nAvrCnt,j].R := StrToIntDef(slRgbData[j*3+1],0);
          m_RGB_Avr_Data[nAvrCnt,j].G := StrToIntDef(slRgbData[j*3+2],0);
          m_RGB_Avr_Data[nAvrCnt,j].B := StrToIntDef(slRgbData[j*3+3],0);
        end;
        Inc(nAvrCnt);
      finally
        slRgbData.Free;
      end;
    end;

  finally
    slRgbFile.Free;
  end;
  case m_Rgb_Avr.AvgType of
    DefCommon.IDX_RGB_AVR_TYPE_A : begin
      if m_Rgb_Avr.AvgRowCnt < nAvrCnt then nAvrCnt := m_Rgb_Avr.AvgRowCnt;
    end;
    DefCommon.IDX_RGB_AVR_TYPE_B : begin
      if m_Rgb_Avr.AvgRowCnt > nAvrCnt then m_Rgb_Avr.NgCode := 2;
    end;
    DefCommon.IDX_RGB_AVR_TYPE_C : begin

    end;
  end;


  if m_Rgb_Avr.AvgColCnt > nAvrColCnt then m_Rgb_Avr.NgCode := 3;
  if nCnt = 0 then m_Rgb_Avr.NgCode := 4;
  if m_Rgb_Avr.NgCode <> 0 then Exit;
  Common.m_RgbAvr[self.Tag].IsReady := True;
  SetLength(m_Rgb_Avr.AvgGamma,nCnt);
  for i := 0 to Pred(nCnt) do begin
    nSumR := 0; nSumG := 0; nSumB :=0;
    for j := 0 to Pred(nAvrCnt) do begin
      nSumR := nSumR + m_RGB_Avr_Data[j,i].R; // i, j 순서 주의 !!!
      nSumG := nSumG + m_RGB_Avr_Data[j,i].G; // i, j 순서 주의 !!!
      nSumB := nSumB + m_RGB_Avr_Data[j,i].B; // i, j 순서 주의 !!!
    end;
    m_Rgb_Avr.AvgGamma[i].R := nSumR div nAvrCnt;
    m_Rgb_Avr.AvgGamma[i].G := nSumG div nAvrCnt;
    m_Rgb_Avr.AvgGamma[i].B := nSumB div nAvrCnt;
    Common.m_RgbAvr[self.Tag].Gamma[i].R := m_Rgb_Avr.AvgGamma[i].R;
    Common.m_RgbAvr[self.Tag].Gamma[i].G := m_Rgb_Avr.AvgGamma[i].G;
    Common.m_RgbAvr[self.Tag].Gamma[i].B := m_Rgb_Avr.AvgGamma[i].B;
  end;
//  // for Debug...
//  sDebug := Format('%d',[nCnt]);
//  for i := 0 to Pred(nCnt) do begin
//    sDebug := sDebug + Format(',%d',[Common.m_RgbAvr[self.Tag].Gamma[i].R]);
//    sDebug := sDebug + Format(',%d',[Common.m_RgbAvr[self.Tag].Gamma[i].G]);
//    sDebug := sDebug + Format(',%d',[Common.m_RgbAvr[self.Tag].Gamma[i].B]);
//  end;
//  sFileName := Common.Path.OtpCfg + format('JIG_%X_%s_PASS_RGB_Avg_Log.txt',[Self.Tag + 10,sModelType]);
//  try
//    try
//      AssignFile(RgbAvgLogfile, sFileName);
//      if not FileExists(sFileName) then
//        Rewrite(RgbAvgLogfile)
//      else
//        Append(RgbAvgLogfile);
//      sDebug := FormatDateTime('(hh:mm:ss.zzz) : ', Now) + sDebug;
//      WriteLn(RgbAvgLogfile, sDebug);
//    except
//    end;
//  finally
//    CloseFile(RgbAvgLogfile);
//  end;
end;

procedure TfrmTest4ChGB.MakeOpticPassRgb(nCh: Integer);
var
  i, j : Integer;
  sData : string;
  sFileName, sModelType : String;
  slRgb                : TStringList;
begin
  // comma(,)에 주의 하자... Script에서 반드시 ,R,G,B 형태로 입력 되어야만 한다.
  sData := Format('%d',[nCh+1]);
  for i := 0 to Pred(pasScr[nCh].m_RgbAvrInfo.RgbPass.FBandCnt) do begin
    for j := 0 to Pred(pasScr[nCh].m_RgbAvrInfo.RgbPass.FGrayStep) do begin
      sData := sData + Trim(PasScr[nCh].m_RgbAvrInfo.RgbPass.Data[i,j]);
    end;
  end;

  // file로 저장 하자.
  sModelType := Common.GetModelType(2,Common.SystemInfo.TestModel);
  sFileName := Common.Path.OtpCfg + format('JIG_%X_%s_PASS_RGB_DATA.txt',[Self.Tag + 10,sModelType]);
  slRgb := TStringList.Create;
  try
    if FileExists(sFileName) then begin
      slRgb.LoadFromFile(sFileName);
    end;
    slRgb.Insert(0,sData);
    while slRgb.Count > m_Rgb_Avr.AvgRowCnt do begin
      slRgb.Delete(slRgb.Count-1);
    end;
    slRgb.SaveToFile(sFileName);
  finally
    slRgb.Free;
  end;
end;

procedure TfrmTest4ChGB.OnTotalTimer(Sender: TObject);
var
  nSec, nMin : Integer;
begin

  Inc(m_nTotalTact);
  nSec := m_nTotalTact mod 60;
  nMin := (m_nTotalTact div 60) mod 60;
  pnlNowValues.Caption := Format('%0.2d : %0.2d',[nMin, nSec]);
end;

procedure TfrmTest4ChGB.OnUnitTimer(Sender: TObject);
var
  nSec, nMin : Integer;
begin
  Inc(m_nUnitTact);
  nSec := m_nUnitTact mod 60;
  nMin := (m_nUnitTact div 60) mod 60;
  pnlUnitTactVal.Caption := Format('%0.2d : %0.2d',[nMin, nSec]);
end;

procedure TfrmTest4ChGB.RevSwDataJig(sGetData: String);
var
  nPos: Integer;
begin

  if Length(sGetData) < 4 then Exit;
  nPos := Pos('3',sGetData);

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
  {02 3F 33 4E 03 (02 3F 33 4E 03 )
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

procedure TfrmTest4ChGB.AutoLogicStart;
var
  sDebug : string;
begin
  if JigLogic[self.Tag] <> nil then begin

    if m_nCheckCa310 <> 0 then begin
      case m_nCheckCa310 of
        DefCommon.CHECK_CA310_NOT_CHECK   :  DisplayLogAllCh(-1,True,'START - NOT CHECK CA310 Status');
        DefCommon.CHECK_CA310_USER_CAL_NG :  DisplayLogAllCh(-1,True,'START - CA310 User Cal Check NG');
        DefCommon.CHECK_CA310_PROBE_NG    :  DisplayLogAllCh(-1,True,'START - CA310 Probe Serial Number Unmatch.');
      end;
      Exit;
    end;
    if m_Rgb_Avr.AvgType <> DefCommon.IDX_RGB_AVR_TYPE_NONE then begin
      if m_Rgb_Avr.NgCode in [2,3,4] then begin
        sDebug := Format('START - RGB AVR File Format NG.(NG CODE:%d)',[m_Rgb_Avr.NgCode]);
        DisplayLogAllCh(-1,True,sDebug);
        Exit;
      end;
    end;

    JigLogic[Self.tag].StartIspd_A(DefScript.SEQ_KEY_START);
//    if m_PlcStatus = psLoadReq then begin
//      m_PlcStatus := psStartIns;
//    end;
  end;

end;

procedure TfrmTest4ChGB.btnAutoClick(Sender: TObject);
begin
//  JigLogic[Self.Tag].StartIspd_A_Auto;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_1);
end;

procedure TfrmTest4ChGB.btnCh2Click(Sender: TObject);
//var
//  i : Integer;
begin
//  i := Self.Tag*4 + 1;
//  Logic[i].StartEachCh(i);
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_8);
end;

procedure TfrmTest4ChGB.btnCh4Click(Sender: TObject);
begin
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_7);
end;

procedure TfrmTest4ChGB.RzBitBtn2Click(Sender: TObject);
begin
//  JigLogic[Self.Tag].NextIspd(False);
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_4);
end;

procedure TfrmTest4ChGB.RzBitBtn7Click(Sender: TObject);
//var
//  i : Integer;
begin
//  for i := Self.Tag*4 to Pred(Self.Tag*4 + 4) do begin
//    Logic[i].EnablePocb(True);
//  end;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_5);
end;

procedure TfrmTest4ChGB.RzBitBtn8Click(Sender: TObject);
//var
//  i : Integer;
begin
//  for i := Self.Tag*4 to Pred(Self.Tag*4 + 4) do begin
//    Logic[i].EnablePocb(False);
//  end;
  JigLogic[Self.Tag].StartIspd_A(DefScript.SEQ_KEY_6);
end;

procedure TfrmTest4ChGB.SetPlcStatus(IoPlc: Integer);
var
  nCh, i: Integer;
  dwTemp : DWORD;
begin
  // 공급 요청.
  dwTemp := 1 shl (defPlc.IDX_OUT_LOAD_REQ);
  if (dwTemp and IoPlc) <> 0 then begin
    for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      pnlSerials[nCh].Color := $0088AEFF;
      pnlSerials[nCh].Font.Color := clBlack;
    end;
  end
  else begin
    // 배출 요청.
    dwTemp := 1 shl (defPlc.IDX_OUT_UNLOAD_REQ);
    if (dwTemp and IoPlc) <> 0 then begin
      for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        pnlSerials[nCh].Color := $00FF8686;
        pnlSerials[nCh].Font.Color := clBlack;
      end;
    end
    else begin
      if PlcCtl.m_bInsStart[self.Tag] then begin
        for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            pnlSerials[nCh].Color := clLime;
            pnlSerials[nCh].Font.Color := clBlack;
        end;
      end
      else begin
        for nCh := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
          if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
            pnlSerials[nCh].Color := clBlack;
            pnlSerials[nCh].Font.Color := clYellow;
          end
          else begin
            pnlSerials[nCh].Color := clBtnFace;
            pnlSerials[nCh].Font.Color := clBlack;
          end;
        end;
      end;


    end;
  end;
end;

procedure TfrmTest4ChGB.SetProbeAutoControl;
begin
  case Self.Tag of
    DefCommon.JIG_A : AxDio.DoneAutoControl1 := DioWorkDone;
    DefCommon.JIG_B : AxDio.DoneAutoControl2 := DioWorkDone;
  end;
end;

procedure TfrmTest4ChGB.SetBcrData;
begin
  DongaHandBcr.OnRevBcrData := getBcrData;
end;

procedure TfrmTest4ChGB.SetComeInOrderPlc(bAllOff : Boolean = False);
//var
//  i : Integer;
//  bTemp : boolean;
begin
//  if PlcCtl <> nil then begin
//    if not bAllOff then begin
//      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//        // 상태 Check.
//        bTemp := False;
//        if Pg[Self.Tag*4 + i].Status in [pgForceStop,pgDisconnect] then bTemp := True;
//        bTemp := bTemp or (not Logic[Self.Tag*4 + i].m_bUse);
//    //          bTemp := m_bDioIn[DefDio.dio_in_]
//        PlcCtl.writePlc(Self.Tag, defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i,bTemp);
//        PlcCtl.writePlc(Self.Tag, defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i,bTemp);
//      end;
////{$IFNDEF NEW_PROCESS}
//      PlcCtl.writePlc(Self.tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,False);
////{$ENDIF}
//  //    if m_PlcStatus = psStartIns then
//
//      m_PlcStatus := psLoadReq;
//    end
//    else begin
//      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//        PlcCtl.writePlc(Self.Tag, defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i,True);
//        PlcCtl.writePlc(Self.Tag, defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i,True);
//      end;
//      PlcCtl.writePlc(Self.tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,True);
//    end;
//  end;
end;

procedure TfrmTest4ChGB.SetComeOutOderPlc;
begin

end;

procedure TfrmTest4ChGB.SetConfig;
begin
//  DisplaySeq;
  DisplaySysInfo;
  if DongaSwitch is TSerialSwitch then begin
    if (Self.Tag = 0) then
      DongaSwitch.ChangePort(Common.SystemInfo.Com_RCB1)
    else
      DongaSwitch.ChangePort(Common.SystemInfo.Com_Rcb2);  //GIB-OPTIC
  end;
end;

procedure TfrmTest4ChGB.SetDioStatus(IoDio: AxIoStatus);
var
  i: Integer;

begin
// Only In Status.
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if IoDio[DefDio.DIO_IN_CONTACT_UP_1 + Self.Tag*4 + i] then begin
      if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then begin
        pnlDioConTactUp[i].Color := clLime;
      end
      else begin
        pnlDioConTactUp[i].Color := clGreen;
      end;
      pnlDioConTactUp[i].Font.Color := clBlack;
    end
    else begin
      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
        pnlDioConTactUp[i].Color   := clBlack;
        pnlDioConTactUp[i].Font.Color := clWhite;
      end
      else begin
        pnlDioConTactUp[i].Color   := clBtnFace;
        pnlDioConTactUp[i].Font.Color := clBlack;
      end;
    end;

    if IoDio[DefDio.DIO_IN_CONTACT_DN_1 + Self.Tag*4 + i] then begin
      if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then begin
        pnlDioConTactDn[i].Color := clLime;
      end
      else begin
        pnlDioConTactDn[i].Color := clGreen;
      end;
      pnlDioConTactDn[i].Font.Color := clBlack;
    end
    else begin
      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
        pnlDioConTactDn[i].Color   := clBlack;
        pnlDioConTactDn[i].Font.Color := clWhite;
      end
      else begin
        pnlDioConTactDn[i].Color   := clBtnFace;
        pnlDioConTactDn[i].Font.Color := clBlack;
      end;
    end;

    if IoDio[DefDio.DIO_IN_DETECT_CH1 + Self.Tag*4 + i] then begin
      if Common.SystemInfo.UIType <> DefCommon.UI_WIN10_NOR then begin
        pnlDioDetect[i].Color := clLime;
      end
      else begin
        pnlDioDetect[i].Color := clGreen;
      end;
      pnlDioDetect[i].Font.Color := clBlack;
    end
    else begin
      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
        pnlDioDetect[i].Color   := clBlack;
        pnlDioDetect[i].Font.Color := clWhite;
      end
      else begin
        pnlDioDetect[i].Color   := clBtnFace;
        pnlDioDetect[i].Font.Color := clBlack;
      end;
    end;
  end;
end;

procedure TfrmTest4ChGB.SetHandleAgain(hMain: HWND);
begin
  JigLogic[Self.Tag].SetHandleAgain(hMain, Self.Handle);
end;

procedure TfrmTest4ChGB.SetHostConnShow(bHostOn : Boolean);
var
  i : Integer;
begin
//  if bHostOn then begin
//    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//      pnlSerials[i].Color := $00AACCE8;
//      pnlSerials[i].Font.Color := clBlack;
//    end;
//
//  end
//  else begin
//    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//      if Common.SystemInfo.UIType = DefCommon.UI_WIN10_BLACK then begin
//         pnlSerials[i].Color := clBlack;
//          pnlSerials[i].Font.Color := clYellow;
//      end
//      else begin
//        pnlSerials[i].Color := clBtnFace;
//         pnlSerials[i].Font.Color := clBlack;
//      end;
//      //$00FF80FF;//clBtnFace;
//    end;
//  end;


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

procedure TfrmTest4ChGB.ShowGui(hMain : HWND);
var
  sCh : string;
  i: Integer;
begin
  DongaSwitch := TSerialSwitch.Create(hMain,Self.Tag);
  DongaSwitch.OnRevSwData := RevSwDataJig;
  CreateGui;
  JigLogic[Self.Tag] := TJig.Create(Self.Tag,hMain,Self.Handle, self);
  sCh := '';
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    if Common.SystemInfo.UseCh[Self.Tag*4+i] then sCh := sCh + Format('%d',[i+1]);
  end;

  DongaCa310[Self.Tag] := TDongaCa310.Create(hMain,Self.Tag, Common.SystemInfo.Com_Ca310[Self.Tag],Common.TestModelInfo2.Ca310MemCh,sCh);
  if Common.SystemInfo.Com_Ca310[Self.Tag] = 0 then begin
    m_nCheckCa310 := DefCommon.CHECK_CA310_OK;
  end
  else begin
    CheckCa310MemInfo;
  end;

  SetConfig;
  UpdatePtList;
end;

procedure TfrmTest4ChGB.ShowPlcNgMeg(nJigCh : Integer;sErrMsg: string);
var
  sDebug : string;
begin
  pnlPGStatuses[nJigCh].Font.Size := 24;
  pnlPGStatuses[nJigCh].Font.Name := 'Verdana';

    pnlPGStatuses[nJigCh].Caption := 'Carrier Detact NG';
    pnlPGStatuses[nJigCh].Color := clMaroon;
    pnlPGStatuses[nJigCh].Font.Color := clYellow;
    sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'Carrier Detact NG : '+ sErrMsg;
    mmChannelLog[nJigCh].SelAttributes.Color := clRed;
    mmChannelLog[nJigCh].SelAttributes.Style := [fsBold];
    mmChannelLog[nJigCh].Lines.Add(sDebug);
//    mmChannelLog[nJigCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
    CalcLogScroll(nJigCh,Length(sDebug));
    Common.MLog(nJigCh+self.Tag*4,'Carrier Detact NG NG : '+sErrMsg);
end;

procedure TfrmTest4ChGB.StopTotalTimer(Sender: TObject; nTimerType : Integer);
var
  i : Integer;
  bRet : boolean;
begin
  bRet := True;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    case nTimerType of
      1 : if not PasScr[Self.tag*4 + i].m_bTotalTact then Continue;
      2 : if not PasScr[Self.tag*4 + i].m_bUnitiTact then Continue;
    end;
    bRet := False;
  end;
  if bRet then begin
    (Sender as TTimer).Enabled := False;
//    tmTotalTactTime.Enabled := False;
  end;
end;

procedure TfrmTest4ChGB.SyncProbeBack(nJigCh, nParam1, nNgCode: Integer);
var
  i, nPgNo : Integer;
  bRet : Boolean;
begin
  bRet := True;
  PasScr[Self.tag*4 + nJigCh].m_bIsProbeBackSig := True;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    nPgNo := Self.tag*4 + i;
    if not PasScr[nPgNo].m_bUse then Continue;
    if Pg[nPgNo].Status in [pgDisconnect] then Continue;
	  if not Common.SystemInfo.OcManualType then begin
      if not AxDio.m_bInDio[Defdio.DIO_IN_DETECT_CH1 + nPgNo] then Continue;
	  end;
    if PasScr[nPgNo].m_bIsProbeBackSig then Continue;
    bRet := False;
  end;
//  if PlcCtl <> nil then begin
//    if nNgCode <> 0 then begin
//      PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl nJigCh);
//    end;
//  end;
  if bRet then begin
    if PlcCtl <> nil then begin
      PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_CONFIRM_DONE);

      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        nPgNo := Self.tag*4 + i;
        if not AxDio.m_bInDio[Defdio.DIO_IN_DETECT_CH1 + nPgNo] then Continue;
        PlcCtl.writePlc(Self.Tag, defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i);
        PlcCtl.writePlc(Self.Tag, defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i);
      end;
      PlcCtl.writePlc(Self.tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,True);
    end;
    if Common.SystemInfo.OcManualType then begin
      AxDio.SetAutoManualCtrl(Self.Tag,False);
      AxDio.SetAutoManualOpen(Self.Tag);
    end
    else begin
      AxDio.SetAutoControl(Self.Tag,False);
      SetComeInOrderPlc(True);
    end;
    m_bAutoPlcProbeBack := True;
  end;
end;

procedure TfrmTest4ChGB.SyncRunScrpt(nIdxKey: Integer);
var
  i : Integer;
  bRet : Boolean;
  sDebug : string;
begin
  bRet := True;

  sDebug := '[Sync Run TEST]';
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    sDebug := sDebug + Format(', Ch%d_ScriptDone(%d)_',[Self.tag*4 + i+1, Integer(PasScr[Self.tag*4 + i].m_bIsScriptWork)]);
    sDebug := sDebug + Format('InsStatus(%d)_',[integer(PasScr[Self.tag*4 + i].m_InsStatus)]);
    sDebug := sDebug + Format('SyncSeq(%d)',[integer(PasScr[Self.tag*4 + i].m_bIsSyncSeq)]);
    if (PasScr[Self.tag*4 + i].m_InsStatus <> isRun) then Continue;
    // 한놈이라도 움직이고 있으면 빠지자...
    if PasScr[Self.tag*4 + i].m_bIsScriptWork then begin
      bRet := False;
      Break;
    end;
  end;
  sDebug := Format('bRet(%d)',[Integer(bRet)]) + sDebug;
  Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);

  if bRet then begin
    sDebug := 'RUN : ';
    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      if (PasScr[Self.tag*4 + i].m_InsStatus <> isRun) then Continue;
      PasScr[Self.tag*4 + i].RunSeq(SEQ_KEY_START);
      sDebug := sDebug + Format('Ch%d Start, ',[i+1+self.tag*4]);

    end;
    Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  end;
end;

procedure TfrmTest4ChGB.tmrDisplayOffTimer(Sender: TObject);
begin
  tmrDisplayOff.Enabled := False;
  pnlErrAlram.Visible := False;
end;

procedure TfrmTest4ChGB.UpdatePtList;
var
  nCh, i : Integer;
  PatGrp : TPatterGroup;
  nJigCnt : Integer;
begin
  PatGrp := Common.LoadPatGroup(Common.TestModelInfo2.PatGrpName);
  nJigCnt :=  DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT;
  for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
    nCh := Self.Tag * (nJigCnt) + i;
    Logic[nCh].PatGrp := PatGrp;
    PasScr[nCh].GetPatGrp := PatGrp;
    PasScr[nCh].InitialScript;
  end;
end;

procedure TfrmTest4ChGB.WMCopyData(var Msg: TMessage);
var
  nType, nMode, nCh, i, nTemp, nTemp2, nPgNo, nLines : Integer;
  bTemp : Boolean;
  sMsg, sDebug, sTemp : string;
begin
  nType := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
  nCh   := (PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel) mod 4;

  case nType of
    DefCommon.MSG_TYPE_SCRIPT : begin
      nMode := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
      case nMode of
        DefCommon.MSG_MODE_CH_CLEAR : begin
          ClearChData(nCh);
        end;
        DefCommon.MSG_MODE_BARCODE_READY : begin
          DongaHandBcr.OnRevBcrData := getBcrData;
        end;
        DefCommon.MSG_MODE_WORKING : begin
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          if nTemp = 10 then begin
            Common.MLog(nCh+self.Tag*4,sMsg);
            Exit;
          end;
          mmChannelLog[nCh].DisableAlign;
          if nTemp = 1 then begin
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);

          end;
          sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
          mmChannelLog[nCh].Lines.Add(sDebug);
          CalcLogScroll(nCh,Length(sDebug));
//          nLines := (Length(sDebug) div 60);
//          for i := 0 to nLines do begin
//            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
//          end;


          Common.MLog(nCh+self.Tag*4,sMsg);
          mmChannelLog[nCh].EnableAlign;
        end;
        DefCommon.MSG_MODE_TACT_START : begin
          m_nTotalTact := 0;
          tmTotalTactTime.Enabled := True;
        end;
        DefCommon.MSG_MODE_TACT_END : begin

          StopTotalTimer(tmTotalTactTime,1);
        end;
        DefCommon.MSG_MODE_UNIT_TT_START : begin
          m_nUnitTact := 0;
          tmUnitTactTime.Enabled := True;
        end;
        DefCommon.MSG_MODE_UNIT_TT_END : begin
          StopTotalTimer(tmUnitTactTime,2);
        end;
        DefCommon.MSG_MODE_POWER_ON : begin
//          tmTotalTactTime.Enabled := False;
        end;
        DefCommon.MSG_MODE_POWER_OFF : begin
//          lnSigoff1.Visible := True;
//          lnSigoff2.Visible := True;
//          DongaPat.LoadPatFile('No Signal');
//          pnlPatternName.Caption := 'Power Off';
//          m_nTotalTact := 0;
//          tmTotalTactTime.Enabled := Fa
        end;
        DefGmes.MES_PCHK : begin  //JHHWANG-GMES: 2018-06-20
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChGB.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1)); //IMSI
          pnlMESResults[nCh].Color      := clBtnFace;
          pnlMESResults[nCh].Font.Color := clBlack;
          pnlMESResults[nCh].Caption    := 'SEND PCHK';
				end;
        DefGmes.MES_INS_PCHK : begin
          pnlMESResults[nCh].Color      := clBtnFace;
          pnlMESResults[nCh].Font.Color := clBlack;
          pnlMESResults[nCh].Caption    := 'SEND INS_PCHK';
        end;
        DefGmes.MES_EICR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND EICR';
        end;
        DefGmes.MES_RPR_EIJR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND RPR_EIJR';
        end;
        DefGmes.MES_APDR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND MES APDR';
        end;
        DefGmes.EAS_APDR : begin
          pnlMESResults[nCh].Color      := clGreen;
          pnlMESResults[nCh].Font.Color := clYellow;
          pnlMESResults[nCh].Caption    := 'SEND EAS APDR';
        end;
        DefCommon.MSG_MODE_CH_RESULT : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          if nTemp = -1 then begin
            sMsg := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
            pnlPGStatuses[nCh].Caption := Trim(sMsg);
            pnlPGStatuses[nCh].Font.Size := 18;
            pnlPGStatuses[nCh].Font.Name := 'Tahoma';
            sDebug := Format('[ %s ]',[sMsg]);
            Common.MLog(nCh+self.Tag*4,sDebug);
            Exit;
          end;
          pnlPGStatuses[nCh].DisableAlign;
          sMsg := Format('OD %d NG',[nTemp]);
          pnlPGStatuses[nCh].Font.Size := 24;
          pnlPGStatuses[nCh].Font.Name := 'Verdana';
          DisplayPreviousRet(nCh);
          // NG 처리.
          if nTemp <> 0 then  begin
            pnlPGStatuses[nCh].Color := clMaroon;
            pnlPGStatuses[nCh].Font.Color := clYellow;
            pnlPGStatuses[nCh].Caption := Format('OD %0.3d NG',[nTemp]); // 'OC'+ PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg + ' NG';
            if PlcCtl <> nil then begin
              PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl nCh,False);
              PasScr[Self.Tag*4 + nCh].m_TestRet.PlcRet := 1;
            end;
          end
          // OK 처리.
          else begin
            pnlPGStatuses[nCh].Color := clLime;
            pnlPGStatuses[nCh].Font.Color := clBlack;
            pnlPGStatuses[nCh].Caption := 'PASS';
            if PlcCtl <> nil then begin
              PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl nCh,True);
              PasScr[Self.Tag*4 + nCh].m_TestRet.PlcRet := 0;
            end;
          end;
          pnlPGStatuses[nCh].EnableAlign;
        end;
        DefCommon.MSG_MODE_CA310_MEASURE : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          JigLogic[Self.Tag].Measure_xyLv(nCh,nTemp);
        end;
        DefCommon.MSG_MODE_SYNC_WORK : begin
          nTemp := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          nTemp2 := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam2;
          case nTemp of
            1 : SyncProbeBack(nCh,nTemp,nTemp2);
            2 : SyncRunScrpt(nTemp2);
          end;
        end;
        DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER : begin
          sMsg := Trim(PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg);
          pnlSerials[nCh].Caption := sMsg;
          mmChannelLog[nCh].DisableAlign;
          sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'Serial NUM:'+sMsg;
          mmChannelLog[nCh].Lines.Add(sDebug);
          mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
          Common.MLog(nCh+self.Tag*4,sMsg);
          mmChannelLog[nCh].EnableAlign;
        end;
        DefCommon.MSG_MODE_FOR_RTY_MAKE_ALL_NG : begin
          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            PasScr[Self.Tag*4 + i].m_bIsRetryContact := True; 
            //Common.MLog(Self.Tag*4+i,'Retry Contact signal On.');
          end;
        end;
        DefCommon.MSG_MODE_PRODUCT_CNT : begin
          nTemp2 := PGuiScript(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam2;
          pnlTotalValues[nCh].Caption := Format('%d',[nTemp+nTemp2]);
          pnlOKValues[nCh].Caption := Format('%d',[nTemp]);
          pnlNGValues[nCh].Caption := Format('%d',[nTemp2]);
        end;
        DefCommon.MSG_MODE_PASS_RGB : begin
          MakeOpticPassRgb(nCh+self.Tag*4);
          GetRgbAvgFromFile;
        end;
        DefCommon.MSG_MODE_GET_AVG_RGB : begin
          if not m_bInitGetAvr then begin
            m_bInitGetAvr := True;
            m_Rgb_Avr.AvgType   := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.AvrType;
            m_Rgb_Avr.AvgRowCnt := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.AvrCnt;
            m_Rgb_Avr.Band      := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.BandCnt;
            m_Rgb_Avr.GrayStep  := PasScr[nCh+self.Tag*4].m_RgbAvrInfo.GrayStep;
            m_Rgb_Avr.AvgColCnt := m_Rgb_Avr.Band * m_Rgb_Avr.GrayStep * 3 + 1;
            GetRgbAvgFromFile;
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
          mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
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
      end;
    end;
    DefCommon.MSG_TYPE_PG : begin
      nMode := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
      case nMode of
        DefCommon.MSG_MODE_DISPLAY_VOLCUR : begin
          DisplayPwrData(nCh,PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.ReadPwrData);
        end;
        DefCommon.MSG_MODE_DISPLAY_ALARM : begin
          sMsg  := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg;
          pnlErrAlramMsg.Caption := Format('Channel %d, %s',[nCh+1,Trim(sMsg)]);
          pnlErrAlram.Left := 300;
          pnlErrAlram.Top  := 410;
          pnlErrAlram.Visible := True;
          pnlPGStatuses[nCh].Caption := 'ALARM NG';
          pnlPGStatuses[nCh].Font.Size := 24;
          pnlPGStatuses[nCh].Color := clMaroon;
          pnlPGStatuses[nCh].Font.Name := 'Verdana';
          pnlPGStatuses[nCh].Font.Color := clYellow;
          sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'ALARM NG '+ sMsg;
          mmChannelLog[nCh].SelAttributes.Color := clRed;
          mmChannelLog[nCh].SelAttributes.Style := [fsBold];
          mmChannelLog[nCh].Lines.Add(sDebug);
          mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
          Common.MLog(nCh+self.Tag*4,'ALARM NG : '+sMsg);
          tmrDisplayOff.Interval := 7000; // 5초 있다가 끄자... 그냥...
          tmrDisplayOff.Enabled  := True;
        end;
        DefCommon.MSG_MODE_DISPLAY_CONNECTION : begin
          nTemp := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          sMsg  := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg;
          DisplayPGStatus(nCh,nTemp,sMsg);
        end;
        DefCommon.MSG_MODE_DIFF_MODEL : begin
          sMsg  := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg;
          nTemp := PTransVoltage(PCopyDataStruct(Msg.LParam)^.lpData)^.nParam;
          pnlPGStatuses[nCh].Font.Size := 24;
          pnlPGStatuses[nCh].Font.Name := 'Verdana';
          if nTemp <> 0 then begin
            pnlPGStatuses[nCh].Caption := 'M/C NG';
            pnlPGStatuses[nCh].Color := clMaroon;
            pnlPGStatuses[nCh].Font.Color := clYellow;
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + 'M/C NG '+ sMsg;
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
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
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg+ ' Model CRC Check OK ';
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
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
      sMsg  := PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
      case PSyncHost(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgMode of
        DefGmes.MES_PCHK : begin  //JHHWANG-GMES: 2018-06-20
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChGB.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1)); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'PCHK NG';

            mmChannelLog[nCh].DisableAlign;
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            Common.MLog(nCh+self.Tag*4,sMsg);
            mmChannelLog[nCh].EnableAlign;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'PCHK OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkModel := DongaGMes.MesData[Self.Tag*4 + nCh].Model;


      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
				end;
        DefGmes.MES_INS_PCHK : begin  //JHHWANG-GMES: 2018-06-20
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChGB.WMCopyData: MSG_TYPE_HOST, MES_PCHK, PG'+IntToStr(nCh+1)); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'INS_PCHK NG';

            mmChannelLog[nCh].DisableAlign;
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            Common.MLog(nCh+self.Tag*4,sMsg);
            mmChannelLog[nCh].EnableAlign;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'INS_PCHK OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;

      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
				end;
        DefGmes.MES_EICR : begin
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChGB.WMCopyData: MSG_TYPE_HOST, MES_EICR'); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'EICR NG';
            mmChannelLog[nCh].DisableAlign;
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            Common.MLog(nCh+self.Tag*4,sMsg);
            mmChannelLog[nCh].EnableAlign;
            if PlcCtl <> nil then begin
              PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl nCh,False);
              PasScr[Self.Tag*4 + nCh].m_TestRet.PlcRet := 1;
            end;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'EICR OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;
    			try
            PasScr[nCh].m_sMesEicrRtnCode := DongaGMes.MesData[nCh].EicrRtnCode;
      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_EICR);
    			finally
      			//TBD
    			end;
        end;
        DefGmes.MES_RPR_EIJR : begin
      		//Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TfrmTest4ChGB.WMCopyData: MSG_TYPE_HOST, MES_EICR'); //IMSI
          if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'RPR_EIJR NG';
            mmChannelLog[nCh].DisableAlign;
            sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            Common.MLog(nCh+self.Tag*4,sMsg);
            mmChannelLog[nCh].EnableAlign;
            if PlcCtl <> nil then begin
              PlcCtl.writePlc(Self.Tag,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl nCh,False);
              PasScr[Self.Tag*4 + nCh].m_TestRet.PlcRet := 1;
            end;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'RPR_EIJR OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;
    			try
            PasScr[nCh].m_sMesEicrRtnCode := DongaGMes.MesData[nCh].EicrRtnCode;

      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_EICR);
    			finally
      			//TBD
    			end;
        end;
        DefGmes.MES_APDR : begin  //JHHWANG-GMES: 2018-06-20
      		if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR MES NG';

            mmChannelLog[nCh].DisableAlign;
            if Length(sMsg) > 100 then begin
              sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + Copy(sMsg,1,100);
            end
            else begin
              sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
            end;
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].EnableAlign;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR MES OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;

      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
				end;
        DefGmes.EAS_APDR : begin
      		if bTemp then begin // error
            pnlMESResults[nCh].Color      := clMaroon;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR EAS NG';

            mmChannelLog[nCh].DisableAlign;
            mmChannelLog[nCh].SelAttributes.Color := clRed;
            mmChannelLog[nCh].SelAttributes.Style := [fsBold];
            if Length(sMsg) > 200 then begin
              sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + Copy(sMsg,1,200);
              Common.MLog(nCh+self.Tag*4,Copy(sMsg,1,100));
            end
            else begin
              sDebug := FormatDateTime('[HH:MM:SS.zzz] ',now) + sMsg;
              Common.MLog(nCh+self.Tag*4,sMsg);
            end;
            mmChannelLog[nCh].Lines.Add(sDebug);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].Perform(EM_SCROLL,SB_LINEDOWN,0);
            mmChannelLog[nCh].EnableAlign;
            PasScr[Self.Tag*4 + nCh].SetHostEvent(1);
          end
          else begin
            pnlMESResults[nCh].Color      := clGreen;
            pnlMESResults[nCh].Font.Color := clYellow;
            pnlMESResults[nCh].Caption    := 'APDR EAS OK';
            PasScr[Self.Tag*4 + nCh].SetHostEvent(0);
          end;

    			try
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnCode := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnCode;
            PasScr[Self.Tag*4 + nCh].m_sMesPchkRtnSerialNo := DongaGMes.MesData[Self.Tag*4 + nCh].PchkRtnSerialNo;

      			//EEPROM-ONLY  PasScr[nCh].RunEventSeq(DefScript.SEQ_EVENT, EEPROM_EVENTCODE_MES_PCHK);
    			finally
      			//TBD
    			end;
        end;
      end;
    end

  end;
end;

end.
