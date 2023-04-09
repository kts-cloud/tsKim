unit PlcTcpPocb;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Dialogs, DefPlc, Vcl.ExtCtrls, ActUtlTypeLib_TLB, system.threading;

  type

  InPlcReadEvnt = procedure(bIn, nConnectCheck : Boolean; nLen : Integer; naReadData : array of Integer) of object;
  InPlcConnEvnt = procedure(nRet : Integer; sMsg : String) of object;
  InPlcAlarm    = procedure(naReadData : array of Integer) of object;
  InPlcTactTime = procedure(nReadData : Integer) of object;
//  InPlcWriteEvt = (nData : Integer; bRemove : Boolean = False) of object;

  TPlcPocb = class(TObject)

    private
      //    m_hMain : THandle;
      ActUtlFx     : TActUtlType;
      FOnPlcRead: InPlcReadEvnt;
      FOnPlcConnect: InPlcConnEvnt;

      //      m_nReadType : Integer;
      m_bStopPlc  : Boolean;
      m_bFirstRead    : Boolean;
      m_bConnect : Boolean;
      FIsMaintMode: Boolean;
      FIsModelInfoMode : Boolean;
      FOnPlcMaintRead: InPlcReadEvnt;
      FPlcType: Integer;
      m_nPreWrite, m_nPreUseCh : Integer;

      FOnPlcModelInfo: InPlcReadEvnt;
      tmCheckPlc  : TTimer;
      FOnPlcAlarm: InPlcAlarm;
      FIsPlcAbbMode: Boolean;
      FIsReadJigTact: Boolean;
      FOnPlcJigTact: InPlcTactTime;


      procedure SetOnPlcConnect(const Value: InPlcConnEvnt);
      procedure SetOnPlcRead(const Value: InPlcReadEvnt);
      procedure ReadData;
      procedure SetIsMaintMode(const Value: Boolean);
      procedure SetOnPlcMaintRead(const Value: InPlcReadEvnt);
      procedure SetPlcType(const Value: Integer);
      procedure SetIsModelInfoMode(const Value: Boolean);
      procedure SetOnPlcModelInfo(const Value: InPlcReadEvnt);
      procedure CheckPlcAlive(Sender: TObject);
      procedure ConnectSignal;
      procedure SetOnPlcAlarm(const Value: InPlcAlarm);
      procedure SetIsPlcAbbMode(const Value: Boolean);
      procedure SetIsReadJigTact(const Value: Boolean);
      procedure SetOnPlcJigTact(const Value: InPlcTactTime);
    public
      m_nWriteData : Integer;
      m_bDisplay   : Boolean;
      m_nUseCh     : Integer;
      m_bJigTact   : Boolean;
      m_nCurJig : Integer;

      constructor Create(hMainHandle : THandle); virtual;
      destructor Destroy; override;
      procedure writePlc(nData : Integer; bRemove : Boolean = False);
      procedure WritePlcTogle(nData : Integer);
      property OnPlcRead : InPlcReadEvnt read FOnPlcRead write SetOnPlcRead;
      property OnPlcConnect : InPlcConnEvnt read FOnPlcConnect write SetOnPlcConnect;
      property OnPlcModelInfo : InPlcReadEvnt read FOnPlcModelInfo write SetOnPlcModelInfo;
      property OnPlcMaintRead : InPlcReadEvnt read FOnPlcMaintRead write SetOnPlcMaintRead;
      property IsMaintMode : Boolean read FIsMaintMode write SetIsMaintMode;
      property IsModelInfoMode : Boolean read FIsModelInfoMode write SetIsModelInfoMode;
      property IsPlcAbbMode    : Boolean read FIsPlcAbbMode write SetIsPlcAbbMode;
      property PlcType : Integer read FPlcType write SetPlcType;
      property OnPlcAlarm : InPlcAlarm read FOnPlcAlarm write SetOnPlcAlarm;
      property OnPlcJigTact : InPlcTactTime read FOnPlcJigTact write SetOnPlcJigTact;
      property IsReadJigTact : Boolean read FIsReadJigTact write SetIsReadJigTact;
  end;

var
  PlcPocb : TPlcPocb;

implementation

//uses OtlTaskControl, OtlParallel;

{$R+}

procedure TPlcPocb.CheckPlcAlive(Sender: TObject);
begin
  if not m_bConnect then Exit;

  if (DefPlc.PLC_WRITE_PC_READY and m_nWriteData) <> 0 then begin
    m_nWriteData := m_nWriteData and ((not DefPlc.PLC_WRITE_PC_READY) and $ffffffff);
  end
  else begin
    m_nWriteData := m_nWriteData or DefPlc.PLC_WRITE_PC_READY;
  end;
end;

procedure TPlcPocb.ConnectSignal;
begin
  if (DefPlc.PLC_WRITE_PC_READY and m_nWriteData) <> 0 then begin
    m_nWriteData := m_nWriteData and ((not DefPlc.PLC_WRITE_PC_READY) and $ffffffff);
  end
  else begin
    m_nWriteData := m_nWriteData or DefPlc.PLC_WRITE_PC_READY;
  end;
end;

constructor TPlcPocb.Create(hMainHandle:THandle);
var
  sDebug : string;
  nRet : Integer;
  thPlc : TThread;
begin
  m_bStopPlc := False;
  FIsPlcAbbMode := False;
  m_bJigTact := False;
  m_bConnect := False;
  FIsMaintMode := False;
  FIsModelInfoMode := False;
  m_nUseCh := -1; // 사용하지 말자는 뜻.
  m_nPreUseCh := m_nUseCh;

  ActUtlFx := TActUtlType.Create(nil);
  ActUtlFx.ActLogicalStationNumber := 1; // 로직 넘버를 1로 고정. ( MX Componet, Communication Settup에서 정리 )

  m_nCurJig := 0; // Default - Stage A.
  m_nWriteData := 0;
  m_nPreWrite  := -1; // 처음 Write 기능 적용을 위해서 임의로 -1, m_WriteData와 다른 값ㅇ.
  m_bDisplay := False;
  try
    nRet := ActUtlFx.Open;
  except
    nRet := -1;
  end;
  // Connection 되었을때 Read 시작 하자.
  thPlc := TThread.CreateAnonymousThread(procedure begin

    if nRet <> 0 then begin
      sDebug := format('PLC Communication Error! (0x%X)',[nRet]);
    end
    else begin
      sDebug := 'PLC Connected';
      m_bConnect := True;
    end;
    sleep(1000);
    if Assigned(OnPlcConnect) then  OnPlcConnect(nRet,sDebug);
    if m_bConnect then ReadData;
  end);
  thPlc.FreeOnTerminate := True;
  thPlc.Priority := tpHigher;//tpHighest;
  thPlc.Start;

  tmCheckPlc := TTimer.Create(nil);
  tmCheckPlc.Interval := 1000;
  tmCheckPlc.Enabled := False;
  tmCheckPlc.OnTimer := CheckPlcAlive;
  tmCheckPlc.Enabled := True;
end;


destructor TPlcPocb.Destroy;
var
  i: Integer;
begin
  tmCheckPlc.Enabled := False;
  tmCheckPlc.Free;
  tmCheckPlc := nil;

  m_bStopPlc := True;
  // Thread가 멈추었는지 확인후 진행 하자.
  for i := 0 to 9 do begin
    if not m_bConnect then Break;
    // Connect가 켜져 있으면 약 500 ms 동안 대기.
    Sleep(50);
  end;

  if m_bConnect then ActUtlFx.Close;
  ActUtlFx.Free;
  ActUtlFx := nil;
  inherited;
end;

procedure TPlcPocb.ReadData;
var
  sDebug : string;
  nRet, nTemp, nTemp2   : Integer;
  naBuff, naPreBuff     : array[0..pred(DefPlc.MAX_NOR_DATA_SIZE)] of Integer;
  naBuffW, naPreBuffW   : array[0..pred(DefPlc.MAX_NOR_DATA_SIZE)] of Integer;
  naBuffM, naPreBuffM   : array[0..pred(DefPlc.MAX_MAINT_DATA_SIZE)] of Integer;
  naBuffA, naPreBuffA   : array[0..pred(Defplc.MAX_ALARM_DATA_SIZE)] of Integer;
  i, nInputData, nRetCnt, nData : Integer;
  bDataChanged, bConnChange : Boolean;
begin
  m_bFirstRead := True;
  for i := 0 to Pred(Defplc.MAX_NOR_DATA_SIZE) do begin
    naBuff[i] := 0;
    naPreBuff[i] := 0;

  end;
  for i := 0 to Pred(Defplc.MAX_MAINT_DATA_SIZE) do begin
    naBuffM[i] := 0;
    naPreBuffM[i] := 0;
  end;
  for i := 0 to Pred(Defplc.MAX_ALARM_DATA_SIZE) do begin
    naPreBuffA[i] := 0;
    naBuffA[i] := 0;
  end;


  nRetCnt := 0; // Retry Count.
  try
    while True do begin
      // Read전에 종료시 나가자.
      if m_bStopPlc then Break;
      // 동작중 Connect 연결 끊어 지면 동작 시키는 내용.
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

      if m_bStopPlc then Break;
      Sleep(50);
      if m_bStopPlc then Break;
      Sleep(50);

      // Read Normal Status.
      nRet := ActUtlFx.ReadDeviceBlock(DefPlc.PLC_NOR_ADDR,DefPlc.MAX_NOR_DATA_SIZE,naBuff[0]);
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
        // Retry 해서 정상 동작.
        if nRetCnt > 0 then begin
          if Assigned(OnPlcConnect) then  OnPlcConnect(0,'Rty Connect');
          nRetCnt := 0;
        end;

        bConnChange := False;
        if (naBuff[0] and DefPlc.PLC_READ_PLC_READY) <> (naPreBuff[0] and DefPlc.PLC_READ_PLC_READY) then begin
          bConnChange := True;
        end;

        bDataChanged := False;
        for i := 0 to Pred(DefPlc.MAX_NOR_DATA_SIZE) do begin
          if i = 0 then begin
            if (naBuff[i] or DefPlc.PLC_READ_PLC_READY) <> (naPreBuff[i] or DefPlc.PLC_READ_PLC_READY) then begin
              bDataChanged := True;
              Break;
            end;
          end
          else begin
            if naBuff[i] <> naPreBuff[i] then begin
              bDataChanged := True;
              Break;
            end;
          end;
        end;
        if m_bFirstRead then begin
          m_bFirstRead := False;
          Sleep(50);
          nRet := ActUtlFx.ReadDeviceBlock(DefPlc.PLC_WRITE_ADDR,1,nTemp);
          nTemp2 := $ff00 and nTemp;
          // 감지가 되고 있으면 해당 내용 Write Buffer에 Default 값으로 설정 하도록 한다.
          writePlc(nTemp2);
        end;

        if bDataChanged then begin
          OnPlcRead(True, False, DefPlc.MAX_NOR_DATA_SIZE,naBuff);
          if FIsMaintMode then begin
            if Assigned(OnPlcMaintRead) then OnPlcMaintRead(True,False,DefPlc.MAX_NOR_DATA_SIZE,naBuff);
          end;
        end
        else begin
          if bConnChange then begin
            OnPlcRead(True, True, DefPlc.MAX_NOR_DATA_SIZE,naBuff);
            if FIsMaintMode then begin
              if Assigned(OnPlcMaintRead) then OnPlcMaintRead(True,True,DefPlc.MAX_NOR_DATA_SIZE,naBuff);
            end;
          end;
        end;
        CopyMemory( @naPreBuff[0],@naBuff[0],DefPlc.MAX_NOR_DATA_SIZE*sizeof(naBuff[0]));

        if m_bJigTact then begin
          if m_bStopPlc then Break;
          Sleep(50);
          m_bJigTact := False;
          if m_bStopPlc then Break;

          nRet := ActUtlFx.ReadDeviceBlock(DefPlc.PLC_JIG_TACT,1,nData);
          if nRet = 0 then begin
            OnPlcJigTact(nData);
          end;
        end;
        if (naBuff[0] and DefPlc.PLC_READ_ERROR) > 0 then begin
          nRet := ActUtlFx.ReadDeviceBlock(DefPlc.PLC_ALARM,DefPlc.MAX_ALARM_DATA_SIZE,naBuffA[0]);
          bDataChanged := False;
          for i := 0 to Pred(defplc.MAX_ALARM_DATA_SIZE) do begin
            if naPreBuffA[i] <> naBuffA[i] then begin
              bDataChanged := True;
            end;
            naPreBuffA[i] := naBuffA[i];
            if bDataChanged then OnPlcAlarm(naBuffA);
          end;
        end
        else begin
          // initialize previous buffer.
          for i := 0 to Pred(Defplc.MAX_ALARM_DATA_SIZE) do begin
            naPreBuffA[i] := 0;
          end;
        end;

        // Added by Clint_Park 2019-07-27 오후 12:51:31
        // Incase of not start when Auto Start Signal.
        if not bDataChanged then begin
           // Start Signal.
           if (naBuff[0] or DefPlc.PLC_READ_AUTO_START_REQ) <> 0 then begin
             OnPlcRead(True, False, DefPlc.MAX_NOR_DATA_SIZE,naBuff);
           end;
        end;
      end;

      if m_nWriteData <> m_nPreWrite then begin
        if m_bStopPlc then Break;
        if (m_nWriteData and $fffffffe) <> (m_nPreWrite and $fffffffe) then begin
          if m_bStopPlc then Break;

        end;
        m_nPreWrite := m_nWriteData;
        naBuffW[0]  := m_nWriteData and $0000ffff;
        naBuffW[1]  := (m_nWriteData and $ffff0000) shr 16;
        m_bDisplay := True;
        if m_bStopPlc then Break;
        Sleep(5);
        nRet := ActUtlFx.WriteDeviceBlock(DefPlc.PLC_WRITE_ADDR,2,naBuffW[0]);
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
        OnPlcRead(False, False, DefPlc.MAX_NOR_DATA_SIZE,naBuffW);
        if FIsMaintMode then begin
          if Assigned(OnPlcConnect) then OnPlcMaintRead(False,False,DefPlc.MAX_NOR_DATA_SIZE,naBuffW);
        end;
      end;
      if m_bStopPlc then Break;
      Sleep(50);
      if m_bStopPlc then Break;
      Sleep(50);
    end;
  finally
    if m_bConnect then  ActUtlFx.Close;
    m_bConnect := False;
  end;
end;

procedure TPlcPocb.SetIsMaintMode(const Value: Boolean);
begin
  FIsMaintMode := Value;
end;

procedure TPlcPocb.SetIsModelInfoMode(const Value: Boolean);
begin
  FIsModelInfoMode := Value;
end;

procedure TPlcPocb.SetIsPlcAbbMode(const Value: Boolean);
begin
  FIsPlcAbbMode := Value;
end;

procedure TPlcPocb.SetIsReadJigTact(const Value: Boolean);
begin
  FIsReadJigTact := Value;
end;

procedure TPlcPocb.SetOnPlcAlarm(const Value: InPlcAlarm);
begin
  FOnPlcAlarm := Value;
end;

procedure TPlcPocb.SetOnPlcConnect(const Value: InPlcConnEvnt);
begin
  FOnPlcConnect := Value;
end;

procedure TPlcPocb.SetOnPlcJigTact(const Value: InPlcTactTime);
begin
  FOnPlcJigTact := Value;
end;

procedure TPlcPocb.SetOnPlcMaintRead(const Value: InPlcReadEvnt);
begin
  FOnPlcMaintRead := Value;
end;

procedure TPlcPocb.SetOnPlcModelInfo(const Value: InPlcReadEvnt);
begin
  FOnPlcModelInfo := Value;
end;

procedure TPlcPocb.SetOnPlcRead(const Value: InPlcReadEvnt);
begin
  FOnPlcRead := Value;
end;

procedure TPlcPocb.SetPlcType(const Value: Integer);
begin
  FPlcType := Value;
end;


procedure TPlcPocb.writePlc(nData: Integer;bRemove : Boolean = False);
var
  nRevItem : Integer;
begin
  if bRemove then begin
    nRevItem := m_nWriteData and nData;
    m_nWriteData := m_nWriteData - nRevItem;
  end
  else begin
    m_nWriteData := m_nWriteData or nData;
  end;

end;

procedure TPlcPocb.WritePlcTogle(nData: Integer);
var
  nRevItem : Integer;
begin
  nRevItem := m_nWriteData and (1 shl nData);
  if nRevItem > 0  then begin
    m_nWriteData := m_nWriteData - nRevItem;
  end
  else begin
    m_nWriteData := m_nWriteData or (1 shl nData);
  end;
end;

end.
