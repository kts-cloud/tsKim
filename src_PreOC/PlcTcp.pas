unit PlcTcp;

interface

{$I common.inc}
uses
  Winapi.Windows, System.Classes, Vcl.ExtCtrls, System.SysUtils, Vcl.Dialogs, DefPlc,
//{$IFDEF NEW_PROCESS}
  AXDioLib, DefDio, DefCommon,
//{$ENDIF}
  ActUtlTypeLib_TLB, system.threading;

  type

  InPlcReadEvnt = procedure(nJig, nLen : Integer; naReadData : array of Integer) of object;
  InPlcConnEvnt = procedure(nRet : Integer; sMsg : String) of object;
  InPlcAutoEvent = procedure(nJig, nJigCh : Integer; sNgMsg : string) of object;
//  InPlcWriteEvt = (nData : Integer; bRemove : Boolean = False) of object;

  TPlc = class(TObject)

    private
//      m_hMain : THandle;
      ActUtlFx     : TActUtlType;
      FOnPlcRead: InPlcReadEvnt;
      FOnPlcConnect: InPlcConnEvnt;
      tmCheckPlc  : TTimer;
//      m_nReadType : Integer;
      m_bStopPlc  : Boolean;
      m_bConnect : Boolean;
      m_naWBuff, m_naPreWBuff, m_naWBuff2, m_naPreWBuff2 : array[0..pred(DefPlc.MAX_WRITE_DATA_SIZE)] of Integer;
      FOnPlcAutoFlow: InPlcAutoEvent;

      procedure SetOnPlcConnect(const Value: InPlcConnEvnt);
      procedure SetOnPlcRead(const Value: InPlcReadEvnt);
      procedure ReadData(sAddr1, sAddr2, sWAddr1, sWAddr2 : string);
      procedure CheckPlcAlive(Sender: TObject);
      procedure ConnectSignal;
      procedure DetectIoSignal(nJig : Integer;naBuff : array of Integer);
    procedure SetOnPlcAutoFlow(const Value: InPlcAutoEvent);
    public
      m_nWriteData : Integer;
      m_nReadSig1, m_nReadSig2 : Integer;
      m_nWriteSig11, m_nWriteSig12, m_nWriteSig21 , m_nWriteSig22 : Integer;
      m_bDisplay   : Boolean;
      m_naModelInfo : array[0..2] of Integer;
      m_nUseCh     : Integer;
//{$IFDEF NEW_PROCESS}
      m_bInsStart  : array[DefCommon.JIG_A .. DefCommon.JIG_B] of boolean;
//{$ENDIF}
      constructor Create(hMainHandle : THandle;sAddr1, sAddr2,sWAddr1, sWAddr2 : string); virtual;
      destructor Destroy; override;

      property OnPlcRead : InPlcReadEvnt read FOnPlcRead write SetOnPlcRead;
      property OnPlcConnect : InPlcConnEvnt read FOnPlcConnect write SetOnPlcConnect;
      property OnPlcAutoFlow : InPlcAutoEvent read FOnPlcAutoFlow write SetOnPlcAutoFlow;
      procedure writePlc(nJig,nIdx,nData : Integer; bRemove : Boolean = False);

  end;

var
  PlcCtl : TPlc;

implementation

{$R+}

procedure TPlc.CheckPlcAlive(Sender: TObject);
begin
//{$IFNDEF NEW_PROCESS}
  ConnectSignal;
//{$ENDIF}
end;

procedure TPlc.ConnectSignal;
begin
   if (DefPlc.OUT_BLINK_PC and m_naWBuff[0]) <> 0 then begin
    m_naWBuff[0] := m_naWBuff[0] and ((not DefPlc.OUT_BLINK_PC) and $ffffffff);
  end
  else begin
    m_naWBuff[0] := m_naWBuff[0] or DefPlc.OUT_BLINK_PC;
  end;
  if (DefPlc.OUT_BLINK_PC and m_naWBuff2[0]) <> 0 then begin
    m_naWBuff2[0] := m_naWBuff2[0] and ((not DefPlc.OUT_BLINK_PC) and $ffffffff);
  end
  else begin
    m_naWBuff2[0] := m_naWBuff2[0] or DefPlc.OUT_BLINK_PC;
  end;
end;

constructor TPlc.Create(hMainHandle:THandle; sAddr1, sAddr2, sWAddr1, sWAddr2 : string);
var
  nRet, i : Integer;
  sDebug : string;
  thPlc : TThread;
begin
  m_bStopPlc := False;
  m_bConnect := False;
  m_nReadSig1   := 0;
  m_nReadSig2   := 0;
  m_nWriteSig11 := 0;
  m_nWriteSig12 := 0;
  m_nWriteSig21 := 0;
  m_nWriteSig22 := 0;
//{$IFDEF NEW_PROCESS}
  for i := DefCommon.JIG_A to DefCommon.JIG_B  do begin
    m_bInsStart[i] := False;
  end;
//{$ENDIF}
  ActUtlFx := TActUtlType.Create(nil);
  ActUtlFx.ActLogicalStationNumber := 1; // ·ÎÁ÷ ³Ñ¹ö¸¦ 1·Î °íÁ¤. ( MX Componet, Communication Settup¿¡¼­ Á¤¸® )
  tmCheckPlc := TTimer.Create(nil);
  tmCheckPlc.Interval := 400;
  tmCheckPlc.Enabled := False;
  tmCheckPlc.OnTimer := CheckPlcAlive;
  try
    nRet := ActUtlFx.Open;
  except
    nRet := -1;
  end;
  nRet := 0;
  // Connection µÇ¾úÀ»¶§ Read ½ÃÀÛ ÇÏÀÚ.
  thPlc := TThread.CreateAnonymousThread(procedure begin
    if nRet <> 0 then begin
      sDebug := format('PLC Communication Error! (0x%X)',[nRet]);
    end
    else begin
      sDebug := '';
      m_bConnect := True;
    end;
    if Assigned(OnPlcConnect) then  OnPlcConnect(nRet,sDebug);
    if m_bConnect then ReadData(sAddr1, sAddr2, sWAddr1, sWAddr2);
  end);
  thPlc.FreeOnTerminate := True;
  thPlc.Priority := tpHighest;
  thPlc.Start;
end;


destructor TPlc.Destroy;
var
  i: Integer;
begin
  if tmCheckPlc <> nil then begin
    tmCheckPlc.Enabled := False;
    tmCheckPlc.Free;
    tmCheckPlc := nil;
  end;
  m_bStopPlc := True;
  // Thread가 멈추었는지 확인후 진행 하자.
  for i := 0 to 9 do begin
    if not m_bConnect then Break;
    // Connect가 켜져 있으면 약 500 ms 동안 대기.
    Sleep(50);
  end;


  sleep(50);
  if m_bConnect then ActUtlFx.Close;
  ActUtlFx.Free;
  ActUtlFx := nil;
  inherited;
end;

procedure TPlc.DetectIoSignal(nJig : Integer;naBuff : array of Integer);
var
  bPlcIn : array[0.. Defplc.MAX_INPUT_CNT] of Boolean;
  bPlcOut : array[0.. DefPlc.MAX_OUT_CNT] of Boolean;
  i, nPgNo : Integer;
  bCheck   : Boolean;
  sDebug : string;
  dwTemp : DWORD;
begin
//{$IFDEF NEW_PROCESS}
  for i := 0 to DefPlc.MAX_INPUT_CNT do begin
    dwTemp := 1 shl i;
    if (dwTemp and naBuff[0]) <> 0 then begin
      bPlcIn[i] := True;
    end
    else begin
      bPlcIn[i] := False;
    end;
  end;
  for i := 0 to DefPlc.MAX_OUT_CNT do begin
    dwTemp := 1 shl i;
    if nJig = 0 then begin
      if i > Pred(DefPlc.MAX_INPUT_CNT) then begin
        if (dwTemp and m_naWBuff[DefPlc.IDX_SECOND_WORD]) <> 0 then begin
          bPlcOut[i] := True;
        end
        else begin
          bPlcOut[i] := False;
        end;
      end
      else begin
        if (dwTemp and m_naWBuff[DefPlc.IDX_FIRST_WORD]) <> 0 then begin
          bPlcOut[i] := True;
        end
        else begin
          bPlcOut[i] := False;
        end;
      end;

    end
    else if nJig = 1 then begin
      if i > Pred(DefPlc.MAX_INPUT_CNT) then begin
        if (dwTemp and m_naWBuff2[DefPlc.IDX_SECOND_WORD]) <> 0 then begin
          bPlcOut[i] := True;
        end
        else begin
          bPlcOut[i] := False;
        end;
      end
      else begin
        if (dwTemp and m_naWBuff2[DefPlc.IDX_FIRST_WORD]) <> 0 then begin
          bPlcOut[i] := True;
        end
        else begin
          bPlcOut[i] := False;
        end;
      end;
    end;
  end;
  {m_naWBuff[nIdx] and }

  if AxDio <> nil then begin
    if (not bPlcIn[defPlc.IDX_IN_PAUSE_PROBE]) then begin
        AxDio.m_bProbeFrontStop[nJig] := bPlcOut[DefPlc.IDX_OUT_PC_READY];
    end
    else begin
      if bPlcIn[defPlc.IDX_IN_PAUSE_PROBE] then begin
        AxDio.m_bProbeFrontStop[nJig] := False;
      end;
    end;
//    m_naWBuff2[nIdx]
    // IO Sig Direct로 보내기.
    writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_PROBE_BACK,not AxDio.m_bInDio[DefDio.DIO_IN_BACK_1+nJig]);
    if bPlcOut[DefPlc.IDX_OUT_PC_READY] then begin
      if AxDio.m_bInDio[DefDio.DIO_IN_BACK_1 + nJig] then begin
        for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
          // 제품 감지.
          writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_DETECT_CH1 shl i ,not AxDio.m_bInDio[DefDio.DIO_IN_DETECT_CH1 + nJig*4 + i]);
        end;
      end
      else begin
        for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
          // 제품 공급 완료 신호.
          writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_DETECT_CH1 shl i ,not bPlcIn[defPlc.IDX_IN_COMPLETE_1 + i]);
        end;
      end;
    end
    else begin
      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        // 제품 감지.
        writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_DETECT_CH1 shl i ,not AxDio.m_bInDio[DefDio.DIO_IN_DETECT_CH1 + nJig*4 + i]);
      end;
    end;



    if bPlcOut[defPlc.IDX_OUT_PC_READY] then begin
      // All 배출 완료 신호 이면 Load Req. 캐리어가 감지 되면 Off.
      bCheck := True;
      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        if not bPlcIn[defPlc.IDX_IN_UNLOADED_1 + i] then bCheck := False;
      end;
      if bCheck then begin
        for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
          // 제품 감지.
          if AxDio.m_bInDio[DefDio.DIO_IN_DETECT_CH1 + nJig*4 + i] then bCheck := False;
        end;
        // 제품이 감지가 되면 시작 말자.
        if bCheck then begin
          writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,False);
          writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_UNLOAD,True);
          writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_CONFIRM_DONE,True);
          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl i,True);
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i ,False);
            writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i ,False);
          end;
        end
        else begin
          writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,True);
          for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
            // 제품 감지.
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i ,True);
            writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i ,True);
          end;
        end;
      end
      else begin
        // m_bInsStart[nJig]
        // 한개라도 공급 완료 신호가 들어 오면...   예외 사항.

        // 공급 요청.  Channel 1 기준.
        if bPlcIn[defPlc.IDX_IN_COMPLETE_1] then begin
          if (not m_bInsStart[nJig]) and (not bPlcOut[DefPlc.IDX_OUT_UNLOAD_REQ]) then begin
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,False);
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_UNLOAD,True);
          end;
        end
        // 배출 요청.
        else begin
          // Probe가 Back일 경우에만 Unload 신호 요청 하자.
          if AxDio.m_bInDio[DefDio.DIO_IN_BACK_1 + nJig] then begin
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,True);
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_UNLOAD,False);
          end;


        end;

      end;

    end;

    for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
      if bPlcOut[defPlc.IDX_OUT_LOAD_REQ] then begin
         // 공급 완료신호시 선택, Ready Off.
        if bPlcIn[defPlc.IDX_IN_COMPLETE_1+i] then begin
          if AxDio.m_bInDio[DefDio.DIO_IN_DETECT_CH1 + nJig*4 + i] then begin
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i ,True);
            writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i ,True);
          end
          else begin

          end;

        end
        else if bPlcIn[defPlc.IDX_IN_UNLOADED_1+i] then begin
          if not AxDio.m_bInDio[DefDio.DIO_IN_DETECT_CH1 + nJig*4 + i] then begin
            writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i );
            writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i );
          end;
        end;
      end;
      // 배출 요청 신호 있을때.
      if bPlcOut[defPlc.IDX_OUT_UNLOAD_REQ] then begin
        // 배출 완료 신호시 선택,
        if bPlcIn[defPlc.IDX_IN_UNLOADED_1+i] then begin
          writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i ,True);
          writePlc(nJig,defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i ,True);
        end;
      end;
      if bPlcOut[defPlc.IDX_OUT_COMPLETE] then begin
        nPgNo := nJig*4 + i;
        m_bInsStart[nJig] := False;
        if AxDio.m_bInDio[Defdio.DIO_IN_DETECT_CH1 + nPgNo] then begin
          writePlc(nJig, defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i);
          writePlc(nJig, defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i);
        end
        else begin
          writePlc(nJig, defPlc.IDX_FIRST_WORD,defPlc.OUT_SEL_CH1 shl i,True);
          writePlc(nJig, defPlc.IDX_SECOND_WORD,defPlc.OUT_READY_CH1 shl i, True);
        end;
      end;
    end;

//    if bPlcIn[defPlc.IDX_IN_UNLOADED_1] and bPlcIn[defPlc.IDX_IN_UNLOADED_2] and
//       bPlcIn[defPlc.IDX_IN_UNLOADED_3] and bPlcIn[defPlc.IDX_IN_UNLOADED_4] then begin
//      // 배출 완료 하자.
//      writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_UNLOAD,True);
//      writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_CONFIRM_DONE,True);
//      writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_Load);
//      // NG 처리 초기화.
//      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
//        writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_RESULT_NG_CH1 shl i,True);
//      end;
//    end;
    // 작업 시작... ==> 공급 완료 Sig Off.
    // Added by ClintPark 2018-07-29 오후 2:28:55  PLC와 협의 필요.Start 두번 이상 올 경우 있다고 함...
    if bPlcIn[defPlc.IDX_IN_LOT_FINISH] and bPlcIn[DefPlc.IDX_IN_PAUSE_PROBE] then begin
      bCheck := True;
      // 공급 완료와 Detect Sig 미스 매칭시.... 무한 대기.
      for i := DefCommon.CH1 to DefCommon.MAX_JIG_CH do begin
        if bPlcIn[defPlc.IDX_IN_COMPLETE_1+i] then begin
          if not AxDio.m_bInDio[DefDio.DIO_IN_DETECT_CH1 + nJig*4 + i] then begin           
            OnPlcAutoFlow(nJig+2,i,'Robot Load complete but not detect the carrier!!!');
            bCheck := False;
          end;
        end;
      end;
      if bCheck then begin
        writePlc(nJig,defPlc.IDX_FIRST_WORD,defPlc.OUT_REQ_LOAD,True);
        m_bInsStart[nJig] := True;
        OnPlcAutoFlow(nJig,0,'');
      end;
    end;
  end;
//{$ENDIF}
end;

procedure TPlc.ReadData(sAddr1, sAddr2, sWAddr1, sWAddr2 : string);
var
  sDebug : string;
  nRet   : Integer;
  naBuff, naPreBuff, naBuff2, naPreBuff2     : array[0..pred(DefPlc.MAX_NOR_DATA_SIZE)] of Integer;

  i, nRetCnt: Integer;
  bDataChanged : Boolean;
begin
  for i := 0 to Pred(DefPlc.MAX_NOR_DATA_SIZE) do begin
    naBuff[i] := 0;
    naPreBuff[i] := 0;
    naBuff2[i] := 0;
    naPreBuff2[i] := 0;

    m_naWBuff[i] := 0;
    m_naPreWBuff[i] := 0;
    m_naWBuff2[i] := 0;
    m_naPreWBuff2[i] := 0;
  end;
  FillChar(naBuff,DefPlc.MAX_NOR_DATA_SIZE,0);
  FillChar(naPreBuff,DefPlc.MAX_NOR_DATA_SIZE,0);

  FillChar(naBuff2,DefPlc.MAX_NOR_DATA_SIZE,0);
  FillChar(naPreBuff2,DefPlc.MAX_NOR_DATA_SIZE,0);

  FillChar(m_naWBuff,DefPlc.MAX_WRITE_DATA_SIZE,0);
  FillChar(m_naPreWBuff,DefPlc.MAX_WRITE_DATA_SIZE,0);

  FillChar(m_naWBuff2,DefPlc.MAX_WRITE_DATA_SIZE,0);
  FillChar(m_naPreWBuff2,DefPlc.MAX_WRITE_DATA_SIZE,0);
  nRetCnt := 0; // Retry Count.
// Todo....
//  nRet := 0;
//{$IFNDEF NEW_PROCESS}
//  tmCheckPlc.Enabled := True;
//  {$ENDIF}
  try
    while not m_bStopPlc do begin
      // µ¿ÀÛÁß Connect ¿¬°á ²÷¾î Áö¸é µ¿ÀÛ ½ÃÅ°´Â ³»¿ë.
      if not m_bConnect then begin

        try
          nRet := ActUtlFx.Open;
          nRetCnt := 0;
        except
          nRet := -1;
        end;
        if nRet <> 0 then begin
          sDebug := format('PLC Communication Error! (0x%X)',[nRet]);
          ActUtlFx.Close;
        end
        else begin
          sDebug := '';
          m_bConnect := True;
        end;
        if Assigned(OnPlcConnect) then  OnPlcConnect(nRet,sDebug);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        Continue;
      end;
//      {$IFDEF NEW_PROCESS}
        ConnectSignal;
//      {$ENDIF}
      // Read A stage Status.
      nRet := ActUtlFx.ReadDeviceBlock(sAddr1,DefPlc.MAX_NOR_DATA_SIZE,naBuff[0]);
      if nRet <> 0 then begin
        OnPlcConnect(nRet,'[PLC] Read connection Failed!');
        Inc(nRetCnt);
        if nRetCnt > 5 then begin
          m_bConnect := False;
          ActUtlFx.Close;
        end;
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        Continue;
      end
      else begin
        // Retry ÇØ¼­ Á¤»ó µ¿ÀÛ.
        if nRetCnt > 0 then begin
          if Assigned(OnPlcConnect) then  OnPlcConnect(0,'');
          nRetCnt := 0;
        end;
        bDataChanged := False;
        for i := 0 to Pred(DefPlc.MAX_NOR_DATA_SIZE) do begin
          if naBuff[i] <> naPreBuff[i] then begin
            bDataChanged := True;
            Break;
          end;
        end;
        if bDataChanged then begin
//          if (DefPlc.IN_PAUSE_PROBE and naBuff[0]) = 0 then OnPlcAutoFlow(2);
//          if (DefPlc.IN_LOT_DONE and naBuff[0]) > 0 then OnPlcAutoFlow(0);
          m_nReadSig1 := naBuff[0];
          OnPlcRead(DefPlc.IDX_PLC_READ_1,DefPlc.MAX_NOR_DATA_SIZE,naBuff);
        end;
        CopyMemory( @naPreBuff[0],@naBuff[0],DefPlc.MAX_NOR_DATA_SIZE*sizeof(Integer));
      end;
      DetectIoSignal(0,naBuff);
      Sleep(50);
      // Read B stage Status.
      nRet := ActUtlFx.ReadDeviceBlock(sAddr2,DefPlc.MAX_NOR_DATA_SIZE,naBuff2[0]);
      if nRet <> 0 then begin
        OnPlcConnect(nRet,'[PLC] Read connection Failed!');
        Inc(nRetCnt);
        if nRetCnt > 5 then begin
          m_bConnect := False;
          ActUtlFx.Close;
        end;
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        Continue;
      end
      else begin
        // Retry ÇØ¼­ Á¤»ó µ¿ÀÛ.
        if nRetCnt > 0 then begin
          if Assigned(OnPlcConnect) then  OnPlcConnect(0,'');
          nRetCnt := 0;
        end;
        bDataChanged := False;
        for i := 0 to Pred(DefPlc.MAX_NOR_DATA_SIZE) do begin
          if naBuff2[i] <> naPreBuff2[i] then begin
            bDataChanged := True;
            Break;
          end;
        end;
        if bDataChanged then begin
//          if ((DefPlc.IN_LOT_DONE and naBuff2[0]) > 0) and ((DefPlc.IN_PAUSE_PROBE and naBuff2[0]) <> 0) then OnPlcAutoFlow(1);
          m_nReadSig2 := naBuff2[0];
          OnPlcRead(DefPlc.IDX_PLC_READ_2,DefPlc.MAX_NOR_DATA_SIZE,naBuff2);
        end;
        CopyMemory( @naPreBuff2[0],@naBuff2[0],DefPlc.MAX_NOR_DATA_SIZE*sizeof(Integer));
      end;
      DetectIoSignal(1,naBuff2);
      Sleep(50);
      // Write. A Stage.
      bDataChanged := False;
      for i := 0 to Pred(DefPlc.MAX_WRITE_DATA_SIZE) do begin
        if m_naWBuff[i] <> m_naPreWBuff[i] then begin
          bDataChanged := True;
          Break;
        end;
      end;
      if bDataChanged then begin
        if m_bStopPlc then Break;
        Sleep(50);
        nRet := ActUtlFx.WriteDeviceBlock(sWAddr1,MAX_WRITE_DATA_SIZE,m_naWBuff[0]);
        if nRet <> 0 then begin
          OnPlcConnect(nRet,'[PLC] Write connection Failed!');
          Inc(nRetCnt);
          if nRetCnt > 5 then begin
            m_bConnect := False;
            ActUtlFx.Close;
          end;
          if m_bStopPlc then Break;
          Sleep(50);
          if m_bStopPlc then Break;
          Sleep(50);
          Continue;
        end;
        for i := 0 to Pred(DefPlc.MAX_WRITE_DATA_SIZE) do begin
          m_naPreWBuff[i] := m_naWBuff[i];
        end;
        OnPlcRead(DefPlc.IDX_PLC_WRITE_1,DefPlc.MAX_WRITE_DATA_SIZE,m_naWBuff);
      end;
      Sleep(50);
      // Write. B Stage.
      bDataChanged := False;
      for i := 0 to Pred(DefPlc.MAX_WRITE_DATA_SIZE) do begin
        if m_naWBuff2[i] <> m_naPreWBuff2[i] then begin
          bDataChanged := True;
          Break;
        end;
      end;
      if bDataChanged then begin
        if m_bStopPlc then Break;
        Sleep(50);
        nRet := ActUtlFx.WriteDeviceBlock(sWAddr2,MAX_WRITE_DATA_SIZE,m_naWBuff2[0]);
        if nRet <> 0 then begin
          OnPlcConnect(nRet,'[PLC] Write connection Failed!');
          Inc(nRetCnt);
          if nRetCnt > 5 then begin
            m_bConnect := False;
            ActUtlFx.Close;
          end;
          if m_bStopPlc then Break;
          Sleep(50);
          if m_bStopPlc then Break;
          Sleep(50);
          Continue;
        end;
        for i := 0 to Pred(DefPlc.MAX_WRITE_DATA_SIZE) do begin
          m_naPreWBuff2[i] := m_naWBuff2[i];
        end;
        OnPlcRead(DefPlc.IDX_PLC_WRITE_2,DefPlc.MAX_WRITE_DATA_SIZE,m_naWBuff2);

      end;
      if m_bStopPlc then Break;
      Sleep(50);
      if m_bStopPlc then Break;
      Sleep(50);
    end;
    Sleep(1);
    m_naWBuff2[0] := 0;      m_naWBuff[0] := 0;
    m_naWBuff2[1] := 0;      m_naWBuff[1] := 0;
    ActUtlFx.WriteDeviceBlock(sWAddr1,DefPlc.MAX_WRITE_DATA_SIZE,m_naWBuff[0]);
    Sleep(2);
    ActUtlFx.WriteDeviceBlock(sWAddr2,DefPlc.MAX_WRITE_DATA_SIZE,m_naWBuff2[0]);
    Sleep(10);
  finally
    if m_bConnect then  ActUtlFx.Close;
    m_bConnect := False;
  end;
end;

procedure TPlc.SetOnPlcAutoFlow(const Value: InPlcAutoEvent);
begin
  FOnPlcAutoFlow := Value;
end;

procedure TPlc.SetOnPlcConnect(const Value: InPlcConnEvnt);
begin
  FOnPlcConnect := Value;
end;

procedure TPlc.SetOnPlcRead(const Value: InPlcReadEvnt);
begin
  FOnPlcRead := Value;
end;


procedure TPlc.writePlc(nJig,nIdx,nData: Integer;bRemove : Boolean = False);
begin
  if bRemove then begin
    if nJig = 0 then begin
      m_naWBuff[nIdx] := m_naWBuff[nIdx] and ((not nData) and $ffffffff);
      case nIdx of
        DefPlc.IDX_FIRST_WORD   : m_nWriteSig11 := m_naWBuff[nIdx];
        DefPlc.IDX_SECOND_WORD  : m_nWriteSig12 := m_naWBuff[nIdx];
      end;
    end
    else begin
      m_naWBuff2[nIdx] := m_naWBuff2[nIdx] and ((not nData) and $ffffffff);
      case nIdx of
        DefPlc.IDX_FIRST_WORD   : m_nWriteSig21 := m_naWBuff2[nIdx];
        DefPlc.IDX_SECOND_WORD  : m_nWriteSig22 := m_naWBuff2[nIdx];
      end;
    end;
  end
  else begin
    if nJig = 0 then begin
      m_naWBuff[nIdx] := m_naWBuff[nIdx] or nData;
      case nIdx of
        DefPlc.IDX_FIRST_WORD   : m_nWriteSig11 := m_naWBuff[nIdx];
        DefPlc.IDX_SECOND_WORD  : m_nWriteSig12 := m_naWBuff[nIdx];
      end;
    end
    else begin
      m_naWBuff2[nIdx] := m_naWBuff2[nIdx] or nData;
      case nIdx of
        DefPlc.IDX_FIRST_WORD   : m_nWriteSig21 := m_naWBuff2[nIdx];
        DefPlc.IDX_SECOND_WORD  : m_nWriteSig22 := m_naWBuff2[nIdx];
      end;
    end;
  end;
end;

end.
