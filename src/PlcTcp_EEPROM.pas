unit PlcTcp_EEPROM;

interface

uses
  Winapi.Windows, System.Classes, Vcl.ExtCtrls, System.SysUtils, Vcl.Dialogs, system.threading,
  ActUtlTypeLib_TLB, DefPlc, DefCommon , CommonClass
{$IFDEF DEBUG}
  ,CodeSiteLogging
{$ENDIF}
  ;

const

  PLCMAP_INDEXPOS_ADDR : array[1.. Defplc.MAX_EEPROM_EQP_NO] of Integer =
    ( 1000, 1050 );
	PLCMAP_BCRDATA : array[1..Defplc.MAX_EEPROM_EQP_NO, 1..Defplc.MAX_EEPROM_POSITION_NO, 1..Defplc.MAX_EEPROM_CH_NO] of Integer =
	(
		(	// IDX1
			( 2000, 2100, 2200, 2300 ),	// POSITION1: D2000, D2100, D2200, D2300
			( 2400, 2500, 2600, 2700 ), // POSITION2
			( 2800, 2900, 3000, 3100 ),	// POSITION3
			( 3200, 3300, 3400, 3500 )	// POSITION4
		),
		(	// IDX2
			( 2050, 2150, 2250, 2350 ),	// POSITION1: D2050, D2150, D2250, D2350
			( 2450, 2550, 2650, 2750 ),	// POSITION2
			( 2850, 2950, 3050, 3150 ),	// POSITION3
			( 3250, 3350, 3450, 3550 )	// POSITION4
		)
	);

	PLCMAP_BCRLEN : array[1..Defplc.MAX_EEPROM_EQP_NO] of Integer =
  	( 3600, 3700 );

type

  TBcrDataInfo = record
    Length    : Smallint;
    Barcode   : String;
  end;

  InPlcConnEvent = procedure(nRet : Integer; sMsg : String) of object;
  InPlcCycReadEvent = procedure(naPlcCycRead : array of Smallint) of object;
  InPlcBcrReadEvent = procedure(nIndexPos: Smallint; naPlcBcrLen: array of Integer; naPlcBcrData: array of string) of object;
  InPlcMaintBcrReadEvent = procedure(nIndexPos: Smallint; naPlcBcrLen: array of Integer; naPlcBcrData: array of string) of object;

  TEepromPlc = class(TObject)
    private
      ActUtlFx      : TActUtlType;
      FOnPlcConnect : InPlcConnEvent;
      FOnPlcCycRead : InPlcCycReadEvent;
      FOnPlcBcrRead : InPlcBcrReadEvent;
      FOnPlcMaintBcrRead : InPlcMaintBcrReadEvent;
      FIsMaintOn    : Boolean;
      tmCheckPlc    : TTimer;

      m_bStopPlc          : Boolean;
      m_bInitReadDone     : Boolean;
      m_bWaitCylinderMove : Boolean;
      m_bGetPlcBcrData    : Boolean;

      PLCCTL_CYCREAD_STARTADDR : Integer;   // Creator에서  설정 (e.g., D550)
      PLCCTL_WRITE_STARTADDR   : Integer;   // Creator에서  설정 (e.g., D550)

      m_PlcCycReadOldBuff : array[0..Pred(PLCCTL_CYCREAD_WCNT)] of Smallint;
      m_PlcWriteOldBuff   : array[0..Pred(PLCCTL_WRITE_WCNT)] of Smallint;

      procedure CheckPlcAlive(Sender: TObject);
      procedure ReadCyclic;
      procedure SetOnPlcConnect(const Value: InPlcConnEvent);
      procedure SetOnPlcCycRead(const Value: InPlcCycReadEvent);
      procedure SetOnPlcBcrRead(const Value: InPlcBcrReadEvent);
      procedure SetOnPlcMaintBcrRead(const Value: InPlcMaintBcrReadEvent);
      procedure SetIsMaintOn(const Value: Boolean);

    public

      m_bConnect          : Boolean;
      //TBD m_nWriteData : Integer;
      //TBD m_bDisplay   : Boolean;
      //TBD m_naModelInfo : array[0..2] of Integer;
      //TBD m_nUseCh     : Integer;
      //TBD m_nVacuuExt  : Integer;

      m_PlcCycReadBuff    : array[0..Pred(PLCCTL_CYCREAD_WCNT)] of Smallint;
      m_PlcWriteBuff      : array[0..Pred(PLCCTL_WRITE_WCNT)] of Smallint;

      m_PlcIndexPos       : Integer;
      m_PlcBcrLenBuff     : array[0..Pred(PLCCTL_BCRREAD_LEN_WCNT)] of Smallint;
      m_PlcBcrDataBuff    : array[0..Pred(PLCCTL_BCRREAD_DATA_WCNT)] of Smallint;

      m_naBcrLen          : array[1..MAX_EEPROM_CH_NO] of Integer;  //TBD(Move to ???)
      m_saBcrData         : array[1..MAX_EEPROM_CH_NO] of string;
      //
      constructor Create(hMainHandle : THandle); virtual;
      destructor Destroy; override;

      property OnPlcConnect : InPlcConnEvent read FOnPlcConnect write SetOnPlcConnect;
      property OnPlcCycRead : InPlcCycReadEvent read FOnPlcCycRead write SetOnPlcCycRead;
      property OnPlcBcrRead : InPlcBcrReadEvent read FOnPlcBcrRead write SetOnPlcBcrRead;
      property OnPlcMaintBcrRead : InPlcMaintBcrReadEvent read FOnPlcMaintBcrRead write SetOnPlcMaintBcrRead;
      property IsMaintOn : Boolean read FIsMaintOn write SetIsMaintOn;
      //
      procedure SetPlcMapAddr (LoaderIndexNo : Integer);
      function ReadFromPLC(nReadAddr: Integer; nReadWCnt: Integer; var aReadBuff: array of Smallint): Integer;
      function WriteToPLC(nWriteAddr: Integer; nWriteWCnt: Integer; aWriteBuff: array of Smallint): Integer;
      //
      procedure SetCylinderUpDown(nUpperLower: Integer; nCh: Integer; nUpDown: Integer);
      function GetCylinderStatus(nUpperLower: Integer; nCh: Integer): Integer;
      function SetBcrDataRead: Integer;
      function ReadPlcIndexPos(var nIndexPos: Integer): Integer;
      function ReadPlcBcrLength(nIndexPos: Integer; var aBcrLenBuff: array of Smallint): Integer;
      function ReadPlcBcrData(nIndexPos: Integer; var aBcrDataBuff: array of Smallint): Integer;
  end;

var
  EepromPlcCtl : TEepromPlc;

implementation

{$R+}

//==============================================================================
//
//==============================================================================

//------------------------------------------------------------------------------
constructor TEepromPlc.Create(hMainHandle:THandle);
var
  nCh     : Integer;
  nRet    : Integer;
  sDebug  : string;
  thPlc   : TThread;
begin

  // Init Attributes

  //
  SetPlcMapAddr(Common.SystemInfo.LoaderIndexNo);

  //이하 TBD
  //
  m_bStopPlc  := False;
  m_bConnect  := False;
  m_bInitReadDone     := False;
  m_bWaitCylinderMove := False;

  for nCh := 1 to 4 do begin
    m_naBcrLen[nCh] := 0;
    m_saBcrData[nCh] := '';
  end;

  ActUtlFx := TActUtlType.Create(nil);
  ActUtlFx.ActLogicalStationNumber := 1; // 로직 넘버를 1로 고정. ( MX Componet, Communication Settup에서 정리 )
  tmCheckPlc := TTimer.Create(nil);
  tmCheckPlc.Interval := 500;
  tmCheckPlc.Enabled := False;
  tmCheckPlc.OnTimer := CheckPlcAlive;
  try
    nRet := ActUtlFx.Open;
  except
    nRet := -1;
  end;
  nRet := 0;
  // Connection 되었을때 Read 시작 하자.
  thPlc := TThread.CreateAnonymousThread(procedure begin
    if nRet <> 0 then begin
      sDebug := format('PLC Communication Error! (0x%X)',[nRet]);
    end
    else begin
      sDebug := '';
      m_bConnect := True;
    end;
    if Assigned(OnPlcConnect) then OnPlcConnect(nRet,sDebug);
    if m_bConnect then begin
      ReadCyclic;
    end;
  end);
  thPlc.FreeOnTerminate := True;
  thPlc.Priority := tpHighest;
  thPlc.Start;

  //
  if Assigned(OnPlcConnect) then OnPlcCycRead(m_PlcCycReadBuff);
end;

destructor TEepromPlc.Destroy;
var
sDebug: string;
  i: Integer;
begin
  sDebug := 'TEepromPlc.Destroy ...TBD';
{$IFDEF DEBUG}
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}

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

  if m_bConnect then ActUtlFx.Close;
  ActUtlFx.Free;
  ActUtlFx := nil;
  inherited;
end;

procedure TEepromPlc.SetOnPlcConnect(const Value: InPlcConnEvent);
begin
  FOnPlcConnect := Value;
end;

procedure TEepromPlc.SetOnPlcCycRead(const Value: InPlcCycReadEvent);
begin
  FOnPlcCycRead := Value;
end;

procedure TEepromPlc.SetOnPlcBcrRead(const Value: InPlcBcrReadEvent);
begin
  FOnPlcBcrRead := Value;
end;

procedure TEepromPlc.SetOnPlcMaintBcrRead(const Value: InPlcMaintBcrReadEvent);
begin
  FOnPlcMaintBcrRead := Value;
end;

procedure TEepromPlc.SetIsMaintOn(const Value: Boolean);
begin
  FIsMaintOn := Value;
end;

//==============================================================================
//
//==============================================================================

//------------------------------------------------------------------------------
procedure TEepromPlc.SetPlcMapAddr (LoaderIndexNo : Integer);
var
  sDebug    : string;
begin
  //
  // Init Attributes
  //  - PLC_CYCREAD_STARTADDR : EQP_NO(0..1)에 따라, PLC로부터 주기적으로 Read할  주소 초기화 (e.g., 'D550')
  //  - PLC_WRITE_STARTADDR   : EQP_NO(0..1)에 따라, 실린더 제어를 위해 PLC로 Write할 주소 초기화 (e.g., 'D550')
  case Common.SystemInfo.LoaderIndexNo of
    1: begin
        PLCCTL_CYCREAD_STARTADDR := PLCMAP_EQP1_STARTADDR;
        PLCCTL_WRITE_STARTADDR   := PLCMAP_EQP1_STARTADDR;
    end;
    2: begin
        PLCCTL_CYCREAD_STARTADDR := PLCMAP_EQP2_STARTADDR;
        PLCCTL_WRITE_STARTADDR   := PLCMAP_EQP2_STARTADDR;
    end;
    else begin
        PLCCTL_CYCREAD_STARTADDR := 0;
        PLCCTL_WRITE_STARTADDR   := 0;
    end;
  end;
  sDebug := 'TEepromPlc.Create'+':LoaderIndexNo('+IntToStr(Common.SystemInfo.LoaderIndexNo)+'),PlcCycReadStartAddr(D'+IntToStr(PLCCTL_CYCREAD_STARTADDR)+'),PlcWriteStartAddr(D'+IntToStr(PLCCTL_WRITE_STARTADDR)+')';
  Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
{$IFDEF DEBUG}
  CodeSite.Send(sDebug);
{$ENDIF}

end;

//------------------------------------------------------------------------------
function TEepromPlc.ReadFromPLC (nReadAddr: Integer; nReadWCnt: Integer; var aReadBuff: array of Smallint): Integer;
var
  sReadAddr : string;
  sDebug    : string;
  nRetryCnt : Integer;
  tempIdx   : Integer;  //IMSI
begin
  // Init Local Variables
  sReadAddr := 'D'+IntToStr(nReadAddr);
  Result    := -1;
  sDebug    := '';
  nRetryCnt := 0;

  //TBD (Loader Line No가 지정되지 않은 경우)
  if (Common = nil) or
    ((Common.SystemInfo.LoaderIndexNo <> 1) and (Common.SystemInfo.LoaderIndexNo <> 2)) then begin
{$IFDEF DEBUG}
    sDebug := 'TEepromPlc.ReadFromPLC:'+Format(' addr(%s),wsize(%d)  ...unknown LineNo',[sReadAddr,nReadWCnt]);
    //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
    CodeSite.Send(sDebug);
{$ENDIF}
    exit;
  end;

{$IFDEF DEBUG}
  sDebug := 'TEepromPlc.ReadFromPLC:'+Format(' addr(%s),wsize(%d)',[sReadAddr,nReadWCnt]);
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}

  while (not m_bStopPlc) and (Result <> 0) do begin

    // 동작중 Connect 연결 끊어 지면 동작 시키는 내용.
    if not m_bConnect then begin
      try
        Inc(nRetryCnt);
        Result := ActUtlFx.Open;
      except
        Result := -1;
      end;
      if Result <> 0 then begin
        sDebug := format('PLC Communication Error! (0x%X)',[Result]);
        ActUtlFx.Close;
        if nRetryCnt >= PLCCTL_MAX_RW_RETRY then begin
          if Assigned(OnPlcConnect) then OnPlcConnect(Result,sDebug);
          Break;
        end;
      end
      else begin
        sDebug := '';
        m_bConnect := True;
      end;
      Sleep(100);
      //Sleep(50);
      //if m_bStopPlc then Break;
      //Sleep(50);
      //if m_bStopPlc then Break;
      //Sleep(50);
      Continue;
    end;

    Result := ActUtlFx.ReadDeviceBlock2(sReadAddr,nReadWCnt,aReadBuff[0]);
    if Result <> 0 then begin
      Inc(nRetryCnt);
      sDebug := 'TEepromPlc.ReadFromPLC ...NG('+IntToStr(nRetryCnt)+')';
{$IFDEF DEBUG}
      //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
      CodeSite.Send(sDebug);
{$ENDIF}
      if nRetryCnt >= PLCCTL_MAX_RW_RETRY then begin
        m_bConnect := False;
        ActUtlFx.Close;
        if Assigned(OnPlcConnect) then OnPlcConnect(Result,'[PLC] Read Failed!');
        //TBD ????
        Sleep(200);    //TBD
        break;
      end;
      continue;
    end;


{$IFDEF DEBUG}
//  sDebug := 'TEepromPlc.ReadFromPLC ...OK';
//  Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
//  CodeSite.SendMemoryAsHex(sDebug,@aReadBuff[0],nReadWCnt*sizeof(Smallint));
{$ENDIF}

  end;

end;

//------------------------------------------------------------------------------
function TEepromPlc.WriteToPLC (nWriteAddr: Integer; nWriteWCnt: Integer; aWriteBuff: array of Smallint): Integer;
var
  sWriteAddr  : string;
  //
  sDebug      : string;
  nRetryCnt   : Integer;
  tempIdx     : Integer;
begin
  // Init Local Variables
  Result      := -1;
  sWriteAddr  := 'D'+IntToStr(nWriteAddr);
  sDebug      := '';
  nRetryCnt   := 0;

    //TBD (Loader Line No가 지정되지 않은 경우)
  if (Common = nil) or
    ((Common.SystemInfo.LoaderIndexNo <> 1) and (Common.SystemInfo.LoaderIndexNo <> 2)) then begin
    sDebug := 'TEepromPlc.WriteToPLC'+Format(': addr(D%d),wcnt(%d)  ...unknown LineNo',[nWriteAddr,nWriteWCnt]);
{$IFDEF DEBUG}
    //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
    CodeSite.Send(sDebug);
{$ENDIF}
    Exit;
  end;

  //
  sWriteAddr := 'D'+IntToStr(nWriteAddr);
  sDebug := 'TEepromPlc.WriteToPLC'+format(': addr(%s),wcnt(%d)',[sWriteAddr,nWriteWCnt]);
{$IFDEF DEBUG}
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}

  while not m_bStopPlc and (Result <> 0) do begin

    // 동작중 Connect 연결 끊어 지면 동작 시키는 내용.
    if not m_bConnect then begin
      try
        Inc(nRetryCnt);
        Result := ActUtlFx.Open;
      except
        Result := -1;
      end;
      if Result <> 0 then begin
        sDebug := format('PLC Communication Error! (0x%X)',[Result]);
        ActUtlFx.Close;
        if nRetryCnt >= PLCCTL_MAX_RW_RETRY then begin
          if Assigned(OnPlcConnect) then OnPlcConnect(Result,sDebug);
          Break;
        end;
      end
      else begin
        sDebug := '';
        m_bConnect := True;
      end;
      Sleep(100);
      //Sleep(50);
      //if m_bStopPlc then Break;
      //Sleep(50);
      //if m_bStopPlc then Break;
      //Sleep(50);
      Continue;
    end;

    Result := ActUtlFx.WriteDeviceBlock2(sWriteAddr,nWriteWCnt,aWriteBuff[0]);
    if Result <> 0 then begin
      Inc(nRetryCnt);
      sDebug := 'TEepromPlc.WriteToPLC ...NG('+IntToStr(nRetryCnt)+')';
{$IFDEF DEBUG}
      //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
      CodeSite.Send(sDebug);
{$ENDIF}
      if nRetryCnt >= PLCCTL_MAX_RW_RETRY then begin
        if Assigned(onPlcConnect) then OnPlcConnect(Result,'[PLC] Write Failed!');
        m_bConnect := False;
        ActUtlFx.Close;
        //TBD ????
        Sleep(200); //TBD
        break;
      end;
      continue;
    end;

    sDebug := 'TEepromPlc.WriteToPLC ...OK';
{$IFDEF DEBUG}
    //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
    CodeSite.SendMemoryAsHex(sDebug,@aWriteBuff[0],nWriteWCnt*sizeof(Smallint));
{$ENDIF}

  end;
end;

//==============================================================================
//
//==============================================================================

//------------------------------------------------------------------------------
procedure TEepromPlc.CheckPlcAlive(Sender: TObject);
var
  sDebug : string;
begin
  sDebug := 'TEepromPlc.CheckPlcAlive ...TBD';
{$IFDEF DEBUG}
  Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}

  //TBD: PLC-EEPROM Alive Check
  //SetPlcMapAddr(Common.SystemInfo.LoaderIndexNo);

end;

//------------------------------------------------------------------------------
// TEepromPlc.ReadCyclic
//    Description
//    Input
//    Output
//      -
procedure TEepromPlc.ReadCyclic;  //TBD
var
  sDebug : string;
  nRet   : Integer;
  i      : Integer;
  bRxChanged, bTxChanged : Boolean;
  tempCycReadBuff : array[0..Pred(PLCCTL_CYCREAD_WCNT)] of Smallint;
begin
{$IFDEF DEBUG}
  sDebug := 'TEepromPlc.ReadCyclic: start';
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}

  // Init Local Variables
  sDebug  := '';
  //nRet    := 0;
  //nRetCnt := 0;
  bRxChanged := False;
  bTxChanged := False;

  try
    while not m_bStopPlc do begin

      // 1. Cyclic Read  -------------------------------------------
      // 1.1 Read Cyclic Read Data to TempBuff
      nRet := ReadFromPLC(PLCCTL_CYCREAD_STARTADDR, PLCCTL_CYCREAD_WCNT, tempCycReadBuff);
      if nRet <> 0 then begin   // Read Error: Delay for Next Cyclic Read
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        if m_bStopPlc then Break;
        Sleep(50);
        Continue; //!!!
      end;
      // 1.2 (Read OK) Copy Curr ReadBuff to Old ReadBuff
      CopyMemory(@m_PlcCycReadOldBuff[0],@m_PlcCycReadBuff[0],PLCCTL_CYCREAD_WCNT*sizeof(Smallint));
      // 1.3 (Read OK) Copy New ReadData to ReadBuff
      CopyMemory(@m_PlcCycReadBuff[0],@tempCycReadBuff[0],PLCCTL_CYCREAD_WCNT*sizeof(Smallint));

      // 2. Cyclic Read Data Processing -----------------------------------
      // 2.1 PLC 연결 후 최초 Read인 경우, WriteBuff를 초기화
      if not m_bInitReadDone then begin
        for i := 0 to Pred(PLCCTL_WRITE_WCNT) do begin
          m_PlcWriteBuff[i]    := m_PlcCycReadBuff[i];
          m_PlcWriteOldBuff[i] := m_PlcCycReadBuff[i];
        end;
        m_bInitReadDone := True;
      end;
      // 2.2 (Read OK) Check RX Change
      bRxChanged := False;
      for i := 0 to Pred(PLCCTL_CYCREAD_WCNT) do begin
        if m_PlcCycReadOldBuff[i] <> m_PlcCycReadBuff[i] then begin
{$IFDEF DEBUG}
          sDebug := 'TEepromPlc.ReadCyclic: '+Format('addr(D%d), old(%d), new(%d)',[PLCCTL_CYCREAD_STARTADDR+i,m_PlcCycReadOldBuff[i],m_PlcCycReadBuff[i]]);
          CodeSite.Send(sDebug);
{$ENDIF}
          bRxChanged := True;
          Break;
        end;
      end;
      // 2.3 (Read OK & RxChanged) Check if INSPECTION_READY is changed to 1, and Make Event
      if bRxChanged then begin
        if Assigned(OnPlcCycRead) then OnPlcCycRead(m_PlcCycReadBuff);
        //TBD(EVENT): INSPECTION_READY???
      end;
      // 2.4 (Read OK) Check if Cyclinder Moving is Completed, and Make Event
      if m_bWaitCylinderMove then begin
        for i := 0 to Pred(PLCCTL_WRITE_WCNT) do begin
          if (m_PlcWriteBuff[PLCMAP_OUT_U_CYLINDER_OFFSET+i] <> m_PlcCycReadBuff[PLCMAP_IN_U_CYLINDER_OFFSET+i]) then
            Break;
        end;
        if (i >= PLCCTL_WRITE_WCNT) then begin
          m_bWaitCylinderMove := False;
{$IFDEF DEBUG}
          sDebug := 'TEepromPlc.ReadCyclic: Cylinder Moved';
//        Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
          CodeSite.Send(sDebug);
          //TBD(EVENT): ConnectToScript: Contact/UnContact Complete???
        end;
{$ENDIF}
      end;

      // 2. BCR Read if required --------------------------------------
      if m_bGetPlcBcrData = True then begin
        // 1.1 Decide PLCMAP for BCR Data
        // 1.2 Read Index Position No
        nRet := ReadPlcIndexPos(m_PlcIndexPos);
        if nRet <> 0 then begin
          Sleep(50);
          Continue;
        end;
        // 1.3 Read BCR Length(s)
        nRet := ReadPlcBcrLength(m_PlcIndexPos,m_PlcBcrLenBuff);
        if nRet <> 0 then begin
          Sleep(50);
          Continue;
        end;
        // 1.4 Read BCR Data(s)
        nRet := ReadPlcBcrData(m_PlcIndexPos,m_PlcBcrDataBuff);
        if nRet <> 0 then begin
          Sleep(50);
          Continue;
        end;
        // 1.5 Clear m_bGetPlcBcrData and Make Event
        m_bGetPlcBcrData := False;
        if Assigned(OnPlcBcrRead) then OnPlcBcrRead(m_PlcIndexPos,m_naBcrLen,m_saBcrData);
        if (Assigned(OnPlcMaintBcrRead) and IsMaintOn) then OnPlcMaintBcrRead(m_PlcIndexPos,m_naBcrLen,m_saBcrData);
      end;

      // 3. Write to PLC if required -------------------------------------
      // 3.1 Check if Write is required
      bTxChanged := False;
      for i := 0 to Pred(PLCCTL_WRITE_WCNT) do begin
        if m_PlcWriteBuff[i] <> m_PlcWriteOldBuff[i] then begin
          bTxChanged := True;
          Break;
        end;
      end;
      // 3.2 Write to PLC if required
      if bTxChanged then begin
        Sleep(5);
        nRet := WriteToPLC(PLCCTL_WRITE_STARTADDR, PLCCTL_WRITE_WCNT, m_PlcWriteBuff);
        if nRet = 0 then begin // OK
          CopyMemory(@m_PlcWriteOldBuff[0],@m_PlcWriteBuff[0],PLCCTL_WRITE_WCNT*sizeof(Smallint));
        end
      end;

      // 4. Delay for Next Cyclic Read --------------------
      if m_bStopPlc then Break;
      Sleep(50);
      if m_bStopPlc then Break;
      Sleep(50);

      sleep(1800); //TBD(TO-BE-DELETED): 100ms task --> 2000ms task for IMSI-TEST
    end;

  finally
    if m_bConnect then  ActUtlFx.Close;
    m_bConnect := False;
  end;

end;

//------------------------------------------------------------------------------
// TEepromPlc.CylinderUpDown
//    Description
//    Input
//    Output
//      -
procedure TEepromPlc.SetCylinderUpDown(nUpperLower: Integer; nCh: Integer; nUpDown: Integer);
var
  //
  nWriteOffset: Integer;
  nWriteWCnt  : Integer;
  nWriteValue : Integer;
  aWriteData  : array[0..Pred(PLCCTL_WRITE_WCNT)] of Smallint;
  //
  sDebug      : string;
  i           : Integer;
begin
{$IFDEF DEBUG}
  sDebug := 'TEepromPlc.SetCylinderUpDown'+format(':Upper1/Lower2(%d),Ch(%d)...Up1/Down2(%d)',[nUpperLower,nCh,nUpDown]);
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}

  // Check Control Arguments
  if (nUpperLower <> PLCCTL_UPPER_CYLINDER) and (nUpperLower <> PLCCTL_LOWER_CYLINDER) then begin
    //TBD(LOG)
    Exit;
  end;
  if (nCh < 0) or (nCh > MAX_EEPROM_CH_NO) then begin
    //TBD(LOG)
    Exit
  end;
  if (nUpDown <> PLCCTL_CYLINDER_UP) and (nUpDown <> PLCCTL_CYLINDER_DOWN) then begin
    //TBD(LOG)
    Exit
  end;

  // Write Addr and Data 결정
  if nUpperLower = PLCCTL_UPPER_CYLINDER then begin
    case nCh of
      0: begin nWriteOffset := PLCMAP_OUT_U_CYLINDER_OFFSET;   nWriteWCnt := 4; end;
      1: begin nWriteOffset := PLCMAP_OUT_U_CYLINDER_OFFSET;   nWriteWCnt := 1; end;
      2: begin nWriteOffset := PLCMAP_OUT_U_CYLINDER_OFFSET+1; nWriteWCnt := 1; end;
      3: begin nWriteOffset := PLCMAP_OUT_U_CYLINDER_OFFSET+2; nWriteWCnt := 1; end;
      4: begin nWriteOffset := PLCMAP_OUT_U_CYLINDER_OFFSET+3; nWriteWCnt := 1; end;
      else Exit;
    end;
    if nUpDown = PLCCTL_CYLINDER_DOWN then
      nWriteValue := 1
    else
      nWriteValue := 0;
  end
  else begin  // PLCCTL_LOWER_CYLINDER:
    case nCh of
      0:  begin nWriteOffset := PLCMAP_OUT_L_CYLINDER_OFFSET;   nWriteWCnt := 2; end;
      1,2:begin nWriteOffset := PLCMAP_OUT_L_CYLINDER_OFFSET;   nWriteWCnt := 1; end;
      3,4:begin nWriteOffset := PLCMAP_OUT_L_CYLINDER_OFFSET+1; nWriteWCnt := 1; end;
      else Exit;
    end;
    if nUpDown = PLCCTL_CYLINDER_UP then
      nWriteValue := 1
    else
      nWriteValue := 0;
  end;

  // Write to PLC Write Buffer (이후 CyclicRead 처리에서 Read 후에 Write 처리됨)
  for i := 0 to Pred(nWriteWCnt) do begin
    m_PlcWriteBuff[nWriteOffset+i] := nWriteValue;
  end;

  // Read and Wait Cylinder 상태 (PLCMAP IN: 실린더 상태)
  m_bWaitCylinderMove := True;
end;

//------------------------------------------------------------------------------
// TEepromPlc.GetCylinderStatus
//    Description
//    Input
//    Output
//      -
function TEepromPlc.GetCylinderStatus(nUpperLower: Integer; nCh: Integer): Integer;
var
  //
  nOutOffset    : Integer;
  nInOffset     : Integer;
  nCompareWCnt  : Integer;
  //
  sDebug      : string;
  i           : Integer;
begin
  //
  Result := PLCCTL_CYLINDER_UNKNOWN;

  // Check Control Arguments
  if (nUpperLower <> PLCCTL_UPPER_CYLINDER) and (nUpperLower <> PLCCTL_LOWER_CYLINDER)
      and (nUpperLower <> PLCCTL_ALL_CYLINDER) then begin
    //TBD(LOG)
    Exit;
  end;
  if (nCh < 0) or (nCh > MAX_EEPROM_CH_NO) then begin
    //TBD(LOG)
    Exit
  end;

  // Cylinder Compare Addr and Data 결정
  if nUpperLower = PLCCTL_ALL_CYLINDER then begin
      nOutOffset := PLCMAP_OUT_U_CYLINDER_OFFSET; nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET; nCompareWCnt := 7;
  end
  else if nUpperLower = PLCCTL_UPPER_CYLINDER then begin
    case nCh of
      0: begin nOutOffset := PLCMAP_OUT_U_CYLINDER_OFFSET;   nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET;   nCompareWCnt := 4; end;
      1: begin nOutOffset := PLCMAP_OUT_U_CYLINDER_OFFSET;   nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET;   nCompareWCnt := 1; end;
      2: begin nOutOffset := PLCMAP_OUT_U_CYLINDER_OFFSET+1; nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET+1; nCompareWCnt := 1; end;
      3: begin nOutOffset := PLCMAP_OUT_U_CYLINDER_OFFSET+2; nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET+2; nCompareWCnt := 1; end;
      4: begin nOutOffset := PLCMAP_OUT_U_CYLINDER_OFFSET+3; nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET+3; nCompareWCnt := 1; end;
      else Exit;
    end;
  end
  else if nUpperLower = PLCCTL_LOWER_CYLINDER then begin  // PLCCTL_LOWER_CYLINDER:
    case nCh of
      0:  begin nOutOffset := PLCMAP_OUT_L_CYLINDER_OFFSET;   nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET;   nCompareWCnt := 2; end;
      1,2:begin nOutOffset := PLCMAP_OUT_L_CYLINDER_OFFSET;   nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET;   nCompareWCnt := 1; end;
      3,4:begin nOutOffset := PLCMAP_OUT_L_CYLINDER_OFFSET+1; nInOffset := PLCMAP_IN_U_CYLINDER_OFFSET+1; nCompareWCnt := 1; end;
      else Exit;
    end;
  end;

  //
  for i := 0 to Pred(nCompareWCnt) do begin
    if m_PlcWriteBuff[nOutOffset+i] <> m_PlcCycReadBuff[nInOffset+i] then begin
      Result := PLCCTL_CYLINDER_MOVING;
      break;
    end;
  end;

  //
  if Result <> PLCCTL_CYLINDER_MOVING then begin
    for i := 0 to Pred(nCompareWCnt) do begin
      if i = 0 then begin
        if nUpperLower = PLCCTL_UPPER_CYLINDER then begin
          if m_PlcCycReadBuff[i] = 0 then
            Result := PLCCTL_CYLINDER_UP
          else
            Result := PLCCTL_CYLINDER_DOWN
        end
        else begin
          if m_PlcCycReadBuff[i] = 0 then
            Result := PLCCTL_CYLINDER_DOWN
          else
            Result := PLCCTL_CYLINDER_UP
        end;
      end
      else begin
        if m_PlcCycReadBuff[nInOffset] <> m_PlcCycReadBuff[nInOffset+i] then begin
          Result := PLCCTL_CYLINDER_MIXED;
          break;
        end;
      end

    end;

  end;

{$IFDEF DEBUG}
  sDebug := 'TEepromPlc.GetCylinderStatus'+format(':Upper1/Lower2(%d),Ch(%d): Unknown0/Up1/Down2/Moving3(%d)',[nUpperLower,nCh,Result]);
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}

end;

function TEepromPlc.SetBcrDataRead: Integer;
var
  sDebug : string;
  aReadBuff   : Smallint;
begin
  //TBD(확인해야 할 것들?)
  m_bGetPlcBcrData := True;
  //
  Result := 0;
end;
//------------------------------------------------------------------------------
// TEepromPlc.ReadIndexPos
//    Description
//    Input
//    Output
//      -
function TEepromPlc.ReadPlcIndexPos(var nIndexPos: Integer): Integer;
var
  sDebug : string;
  nReadAddr   : Integer;
  nReadWSize  : Integer;
  aReadBuff   : Smallint;
begin
  // Init Variables
  Result  := -1;
  sDebug  := '';

  // Check Arguments
  if (Common.SystemInfo.LoaderIndexNo < 1) or (Common.SystemInfo.LoaderIndexNo > 2) then begin
{$IFDEF DEBUG}
    sDebug := 'TEepromPlc.ReadPlcIndexPos'+format(': LineNo(%d) ...Invalid LineNo',[Common.SystemInfo.LoaderIndexNo]);
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}
    Exit;
  end;

  // Read Index Position from PLC
  nReadWSize  := PLCMAP_INDEXPOS_LEN;
  nReadAddr   := PLCMAP_INDEXPOS_ADDR[Common.SystemInfo.LoaderIndexNo];
  Result := ReadFromPLC(nReadAddr, nReadWSize, aReadBuff);
  if Result = 0 then begin
    nIndexPos := aReadBuff;
    if (nIndexPos < 1) or (nIndexPos > 4) then begin
{$IFDEF DEBUG}
      sDebug := 'TEepromPlc.ReadPlcIndexPos'+format(': Pos(%d) ...Invalid Position',[nIndexPos]);
    //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
      CodeSite.Send(sDebug);
{$ENDIF}
      Result := -1;
    end;
  end
  else begin
    //TBD
  end;

end;

function TEepromPlc.ReadPlcBcrLength(nIndexPos: Integer; var aBcrLenBuff: array of Smallint): Integer;
var
  sDebug  : string;
  tempIdx : Integer; //IMSI
  buffIdx : Integer;
  nCh     : Integer;
  //
  nReadAddr   : Integer;
  nReadWSize  : Integer;
//  aReadBuff   : array[0..Pred(PLCCTL_BCRREAD_LEN_WCNT)] of Smallint;
  aReadBuff   : array of Smallint;
begin
  // Init Variables
  SetLength(aReadBuff,PLCCTL_BCRREAD_LEN_WCNT);
  Result  := -1;
  sDebug  := '';

  // Check Arguments
  if (Common.SystemInfo.LoaderIndexNo < 1) or (Common.SystemInfo.LoaderIndexNo > 2) then begin
    sDebug := 'TEepromPlc.ReadPlcBcrLength'+format(': Pos(%d) ...Invalid Position',[nIndexPos]);
{$IFDEF DEBUG}
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}
    Exit;
  end;

  if (nIndexPos < 1) or (nIndexPos > 4) then begin
{$IFDEF DEBUG}
    sDebug := 'TEepromPlc.ReadPlcBcrLength'+format(': Pos(%d) ...Invalid Position',[nIndexPos]);
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
    CodeSite.Send(sDebug);
{$ENDIF}
    Exit;
  end;

  // Read BCR_LENGTH(s) from PLC
  //  - BCR Length: PLCMAP 결정 (StationNo, nPosition, nCh)
  nReadWSize  := PLCCTL_BCRREAD_LEN_WCNT;
  nReadAddr   := PLCMAP_BCRLEN[Common.SystemInfo.LoaderIndexNo];
  Result := ReadFromPLC(nReadAddr, nReadWSize, aReadBuff);
{$IFDEF DEBUG}
  for tempIdx := 0 to Pred(PLCCTL_BCRREAD_LEN_WCNT) do begin  // IMSI-TEST
    aReadBuff[tempIdx] := 20;
  end;
{$ENDIF}
  if Result = 0 then begin
    CopyMemory(@aBcrLenBuff[0],@aReadBuff[0],nReadWSize*sizeof(Smallint));
    // TBD: Save to Channel Data
    for nCh := 1 to 4 do begin
      buffIdx := (nIndexPos - 1) + ((nCh-1) * PLCMAP_BCRLEN_CH_OFFSET);
      m_naBcrLen[nCh] := aBcrLenBuff[buffIdx];
{$IFDEF DEBUG}
      sDebug := 'IndexPos:'+IntToStr(nIndexPos)+' Ch:'+IntToStr(nCh)+' -- '+IntToStr(buffIdx);
      CodeSite.Send(sDebug);
  //	BCR_LEN:
  //    EQP1:
  //			( 3600, 3604, 3608, 3612 ),	// POSITION1
  //			( 3601, 3605, 3609, 3613 ),	// POSITION2
  //			( 3602, 3606, 3610, 3614 ),	// POSITION3
  //			( 3603, 3607, 3611, 3615 )	// POSITION4
  //    EQP2:
  //			( 3700, 3704, 3708, 3712 ),	// POSITION1
  //			( 3701, 3705, 3709, 3713 ),	// POSITION2
  //			( 3702, 3706, 3710, 3714 ),	// POSITION3
  //			( 3703, 3707, 3711, 3715 )	// POSITION4
{$ENDIF}
    end
  end
  else begin
    //TBD
  end;

end;

function TEepromPlc.ReadPlcBcrData(nIndexPos: Integer; var aBcrDataBuff: array of Smallint): Integer;
var
  sDebug : string;
  tempIdx: Integer; //IMSI
  tempStr: string;  //IMSI
  //
  nCh, buffIdx : Integer;
  nReadAddr   : Integer;
  nReadWSize  : Integer;
  aReadBuff   : array[0..Pred(PLCCTL_BCRREAD_DATA_WCNT)] of Smallint;
begin
  // Init Variables
  Result  := -1;
  sDebug  := '';

  // Check Arguments
  if (Common.SystemInfo.LoaderIndexNo < 1) or (Common.SystemInfo.LoaderIndexNo > 2) then begin
    sDebug := 'TEepromPlc.ReadPlcBcrData'+format(': Pos(%d) ...Invalid Position',[nIndexPos]);
{$IFDEF DEBUG}
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
  CodeSite.Send(sDebug);
{$ENDIF}
    Exit;
  end;

  if (nIndexPos < 1) or (nIndexPos > 4) then begin
    sDebug := 'TEepromPlc.ReadPlcBcrData'+format(': Pos(%d) ...Invalid Position',[nIndexPos]);
{$IFDEF DEBUG}
  //Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
    CodeSite.Send(sDebug);
{$ENDIF}
    Exit;
  end;

  // Read BCR_DATA(s) from PLC
  //  - BCR Data: PLCMAP 결정 (StationNo, nPosition, nCh)
  nReadWSize  := PLCCTL_BCRREAD_DATA_WCNT;
  nReadAddr   := PLCMAP_BCRDATA[Common.SystemInfo.LoaderIndexNo,nIndexPos,1];
  Result := ReadFromPLC(nReadAddr, nReadWSize, aReadBuff);
  if Result = 0 then begin
    CopyMemory(@aBcrDataBuff[0],@aReadBuff[0],nReadWSize*sizeof(Smallint));
    // TBD: Save to Channel Data
    for nCh := 1 to 4 do begin
      buffIdx := (nCh -1) * PLCMAP_BCRDATA_CH_OFFSET;
      SetString(m_saBcrData[nCh],PChar(@aBcrDataBuff[buffIdx]),PLCMAP_BCRDATA_WCNT*sizeof(Smallint));
      //CopyMemory(@m_saBcrData[nCh],@aBcrDataBuff[buffIdx],PLCMAP_BCRDATA_WCNT*sizeof(Smallint));
{$IFDEF DEBUG}
      case nCh of
        1: tempStr := '11111111110123456789';
        2: tempStr := '22222222220123456789';
        3: tempStr := '33333333330123456789';
        4: tempStr := '44444444440123456789';
      end;
      m_saBcrData[nCh] := tempStr;
      sDebug := 'IndexPos:'+IntToStr(nIndexPos)+' Ch:'+IntToStr(nCh)+' -- '+IntToStr(buffIdx);
      CodeSite.Send(sDebug);
  //    EQP1:
  //			( 2000, 2100, 2200, 2300 ),	// POSITION1: D2000, D2100, D2200, D2300
  //			( 2400, 2500, 2600, 2700 ), // POSITION2
  //			( 2800, 2900, 3000, 3100 ),	// POSITION3
  //			( 3200, 3300, 3400, 3500 )	// POSITION4
  //		EQP2:
  //			( 2050, 2150, 2250, 2350 ),	// POSITION1: D2050, D2150, D2250, D2350
  //			( 2450, 2550, 2650, 2750 ),	// POSITION2
  //			( 2850, 2950, 3050, 3150 ),	// POSITION3
  //			( 3250, 3350, 3450, 3550 )	// POSITION4
{$ENDIF}
    end
  end
  else begin
    //TBD
  end;

end;





end.
