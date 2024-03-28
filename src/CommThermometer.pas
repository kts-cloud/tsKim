unit CommThermometer;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,  System.Classes, VaComm, SyncObjs, Vcl.ExtCtrls;
const
  COMMTHERMOMETER_CONNECT = 0;
  COMMTHERMOMETER_UPDATE = 1;
  COMMTHERMOMETER_ADDLLOG = 100;

type
  {$IFNDEF GUIMessage}
    {$DEFINE GUIMessage}
    /// <summary> GUI Message for WM_COPYDATA </summary>
    TGUIMessage = packed record
      MsgType : Integer;
      Channel : Integer;
      Mode    : Integer;
      Param  : Integer;
      Param2 : Integer;
      Msg     : string;
      pData   : PBYTE; //Pointer; //Length = Param2
    end;
    PGUIMessage = ^TGUIMessage;
  {$ENDIF}

  TModbuQueryHeader = record
    SlaveAddress: BYTE;
    Func: BYTE;
    StartAddr: WORD;
    Count: WORD;
  end;

  TModbuResponseHeader = record
    SlaveAddress: BYTE;
    Func: BYTE;
    Count: WORD;
  end;

  ///<summary>
  /// 온도 센서 Autonix TK 시리즈 통신 클래스by kg.jo 20220711
  /// 장비: T 시리즈
  /// 프로토콜문서: TK 통신메뉴얼.pdf. modbus 통신 기반
  ///  온도 값 영역 301001(03E8) 현재 측정 값
  ///</summary>
  TCommThermometer = class
  private
    m_VaComm : TVaComm;
    m_tmrCycle: TTimer;
    m_SendHeader: TModbuQueryHeader; //보내 데이터 헤더 값 저장- 수신 시 비교
    m_hMain: THandle;
    m_nMsgType: Integer;
    m_nTimeoutCount: Integer; //데이터 응답 없음

    procedure VaCommRxChar(Sender: TObject; Count: Integer);
    procedure tmrCycleTimer(Sender: TObject);
    procedure SendMessageMain(nMode, nParam, nParam2: Integer; sMsg: String);
    procedure AddLog(sLog: String);
  public
    Connected: Boolean; //연결 여부
    CurrentValue : Double; //읽은 값
    State: Byte; //현재 상태
  public
    constructor Create(hMain :THandle; nMsgType: Integer; nInterval: Integer); virtual;
    destructor Destroy; override;
    function Connect(nPort: Integer): boolean;
    procedure Disconnect;
    procedure QueryData;
    function SendBuf(AData: array of Byte; ASize: Integer): Integer;
  end;

var
  g_CommThermometer: TCommThermometer;

  function CalcCRC16(const AData: array of Byte; ASize: Integer): Word;
  function GetCRC16(const AData:pointer; ASize:integer):word; overload;
  function GetCRC16(const AText:string):word; overload;
  function BufferToHex(const AData: Pointer; nCount: Integer): String;

implementation

{ TCommThermometer }

procedure TCommThermometer.AddLog(sLog: String);
begin
  //SendMessageMain(COMMTHERMOMETER_ADDLLOG, 0, 0, sLog);
end;

constructor TCommThermometer.Create(hMain :THandle; nMsgType: Integer; nInterval: Integer);
begin
  m_hMain:= hMain;
  m_nMsgType:= nMsgType;

  m_VaComm := TVaComm.Create(nil);
  m_VaComm.Baudrate:= br9600; //br19200; //
  m_VaComm.Parity:= paNone;
  m_VaComm.Databits:= db8;
  m_VaComm.Stopbits:= sb2; //sb1;
  //m_VaComm.EventChars.EofChar := #13;
  //m_VaComm.EventChars.EventChar := #13;
  m_VaComm.SyncThreads:= False;  //Not GUI Sync

  m_VaComm.OnRxChar:= VaCommRxChar;

  m_tmrCycle:= TTimer.Create(nil);
  m_tmrCycle.Enabled:= False;
  m_tmrCycle.OnTimer:= tmrCycleTimer;
  m_tmrCycle.Interval:= nInterval;

  Connected:= False;
  AddLog('Create');
end;

destructor TCommThermometer.Destroy;
begin
  Disconnect;

  m_tmrCycle.Free;
  FreeAndNil(m_VaComm);
  inherited;
  AddLog('Destroy');
end;

function TCommThermometer.Connect(nPort: Integer): boolean;
begin
  Result:= False;
  if nPort = 0 then begin
    SendMessageMain(COMMTHERMOMETER_CONNECT, 3, 0, 'NONE');
    Exit;
  end;

  if m_VaComm.Active then begin
    Exit;
  end;

  AddLog('Connecting...');
  try
    m_VaComm.Close;
    m_VaComm.PortNum:= nPort;
    m_VaComm.Open;

    m_tmrCycle.Enabled:= True;
    Connected:= True;
    Result:= Connected;
    m_nTimeoutCount:= 0;
    SendMessageMain(COMMTHERMOMETER_CONNECT, 1, 0, 'COM' + IntToStr(nPort));

    QueryData;
  except
    on E : Exception do begin
      SendMessageMain(COMMTHERMOMETER_CONNECT, 2, 0, E.Message);
    end;
  end;
end;

procedure TCommThermometer.Disconnect;
begin
  m_tmrCycle.Enabled:= False;
  m_VaComm.Close;
  Connected:= False;
  SendMessageMain(COMMTHERMOMETER_CONNECT, 0, 0, 'Disconnected');
end;

procedure TCommThermometer.QueryData;
var
  Buff: array [0..100]of Byte;
  wCrc: Word;
begin
  if not Connected then begin
    Exit;
  end;


  Buff[0]:= $01; //Slave Address
  Buff[1]:= $04; //Function - Read Input Register (func04 = 04H)
  Buff[2]:= $03; //Starting Address(Hi)
  Buff[3]:= $E8; //Starting Address(Lo)
  Buff[4]:= $00;  //Count (Hi)
  Buff[5]:= $02;  //Count (Lo)
  wCrc:= CalcCRC16(Buff, 6);

  Buff[6]:= Lo(wCrc); //$F1; //Lo(wCrc);  //CRC16 (Lo)
  Buff[7]:= Hi(wCrc); //$BB; //hi(wCrc);  //CRC16 (Hi)

(*
  Buff[0]:= $01; //Slave Address
  Buff[1]:= $04; //Function - Read Input Register (func04 = 04H)
  Buff[2]:= $00; //Starting Address(Hi)
  Buff[3]:= $66; //Starting Address(Lo)
  Buff[4]:= $00;  //Count (Hi)
  Buff[5]:= $0C;  //Count (Lo)
  wCrc:= CalcCRC16(Buff, 6);

  Buff[6]:= Hi(wCrc); //$F1; //Lo(wCrc);  //CRC16 (Lo)
  Buff[7]:= Lo(wCrc); //$BB; //hi(wCrc);  //CRC16 (Hi)
*)
(*
  Buff[0]:= $01; //Slave Address
  Buff[1]:= $03; //Function - Read Input Register (func04 = 04H)
  Buff[2]:= $00; //Starting Address(Hi)
  Buff[3]:= $00; //Starting Address(Lo)
  Buff[4]:= $00;  //Count (Hi)
  Buff[5]:= $03;  //Count (Lo)
  wCrc:= GetCRC16(@Buff[0], 6);

  Buff[6]:= Hi(wCrc); //$F1; //Lo(wCrc);  //CRC16 (Lo)
  Buff[7]:= Lo(wCrc); //$BB; //hi(wCrc);  //CRC16 (Hi)
*)

  AddLog('Send: ' + BufferToHex(@Buff[0], 8));
  m_VaComm.PurgeWrite;
  m_VaComm.WriteBuf(Buff, 8);
end;

procedure TCommThermometer.VaCommRxChar(Sender: TObject; Count: Integer);
var
  Buff: array [0..100]of Byte;
  wCrc: Word;
  wRecvCrc: Word;
  wValue: Word;
  wDigit: Word;
  nCount: Byte;
  sTemp: string;
begin
  m_VaComm.ReadBuf(Buff, Count);
  AddLog('Recv: ' + BufferToHex(@Buff[0], Count));

  //Validation
  if (Buff[0] = $01) and (Buff[1] = $04) then begin
    nCount:= Buff[2];
    wCrc:= CalcCRC16(Buff, nCount + 3);
    CopyMemory(@wRecvCrc, @Buff[nCount + 3], 2);
    if wRecvCrc <> wCrc then begin
      //CRC 에러
      sTemp:= format('CRC Error: Recv %02x: Calc %02x', [wRecvCrc, wCrc]);
      AddLog(sTemp);
      SendMessageMain(COMMTHERMOMETER_CONNECT, 2, 0, sTemp);
      Exit;
    end;

    //정상 패킷
    wValue:= Buff[3] * 256 + Buff[4];
    CurrentValue:= wValue * 0.1; //소숫점 자리수 처리. 기기설정에서 1로 설정(301002(03E9) 값 )
    m_nTimeoutCount:= 0;
    SendMessageMain(COMMTHERMOMETER_UPDATE, wValue, 0, '');
  end
  else begin
    //이상 패킷
    AddLog('Packet mismatch: ' + BufferToHex(@Buff[0], Count));
  end;

  //SetEvent(m_hRecvEvent);
  //if Assigned(m_DataEvent) then m_DataEvent(sRecv);
end;


procedure TCommThermometer.tmrCycleTimer(Sender: TObject);
begin
  //Send Query
  if Connected then begin
    inc(m_nTimeoutCount);
    if m_nTimeoutCount = 3 then begin
      //Timeout 발생
      SendMessageMain(COMMTHERMOMETER_CONNECT, 2, 0, 'No Response');
    end;
    if m_nTimeoutCount > 100 then begin
      m_nTimeoutCount:= 100;
    end;
    QueryData;
  end;
end;

function TCommThermometer.SendBuf(AData: array of Byte; ASize: Integer): Integer;
begin
  m_VaComm.PurgeWrite;
  AddLog('SendBuf: ' + BufferToHex(@AData[0], ASize));
  m_VaComm.WriteBuf(AData, ASize);
end;

procedure TCommThermometer.SendMessageMain(nMode, nParam, nParam2: Integer; sMsg: String);
var
  cds         : TCopyDataStruct;
  GUIMessage     : TGUIMessage;
begin
  GUIMessage.MsgType := m_nMsgType;
  GUIMessage.Channel := 0;
  GUIMessage.Mode    := nMode;
  GUIMessage.Param  := nParam;
  GUIMessage.Param2 := nParam2;
  GUIMessage.Msg     := sMsg;
  cds.dwData      := 0;
  cds.cbData      := SizeOf(GUIMessage);
  cds.lpData      := @GUIMessage;
  SendMessage(m_hMain, WM_COPYDATA, 0, LongInt(@cds));
end;

const
  CRCTable16: array[0..255] of Word = (
   $0000, $1021, $2042, $3063, $4084, $50A5, $60C6, $70E7,
   $8108, $9129, $A14A, $B16B, $C18C, $D1AD, $E1CE, $F1EF,
   $1231, $0210, $3273, $2252, $52B5, $4294, $72F7, $62D6,
   $9339, $8318, $B37B, $A35A, $D3BD, $C39C, $F3FF, $E3DE,
   $2462, $3443, $0420, $1401, $64E6, $74C7, $44A4, $5485,
   $A56A, $B54B, $8528, $9509, $E5EE, $F5CF, $C5AC, $D58D,
   $3653, $2672, $1611, $0630, $76D7, $66F6, $5695, $46B4,
   $B75B, $A77A, $9719, $8738, $F7DF, $E7FE, $D79D, $C7BC,
   $48C4, $58E5, $6886, $78A7, $0840, $1861, $2802, $3823,
   $C9CC, $D9ED, $E98E, $F9AF, $8948, $9969, $A90A, $B92B,
   $5AF5, $4AD4, $7AB7, $6A96, $1A71, $0A50, $3A33, $2A12,
   $DBFD, $CBDC, $FBBF, $EB9E, $9B79, $8B58, $BB3B, $AB1A,
   $6CA6, $7C87, $4CE4, $5CC5, $2C22, $3C03, $0C60, $1C41,
   $EDAE, $FD8F, $CDEC, $DDCD, $AD2A, $BD0B, $8D68, $9D49,
   $7E97, $6EB6, $5ED5, $4EF4, $3E13, $2E32, $1E51, $0E70,
   $FF9F, $EFBE, $DFDD, $CFFC, $BF1B, $AF3A, $9F59, $8F78,
   $9188, $81A9, $B1CA, $A1EB, $D10C, $C12D, $F14E, $E16F,
   $1080, $00A1, $30C2, $20E3, $5004, $4025, $7046, $6067,
   $83B9, $9398, $A3FB, $B3DA, $C33D, $D31C, $E37F, $F35E,
   $02B1, $1290, $22F3, $32D2, $4235, $5214, $6277, $7256,
   $B5EA, $A5CB, $95A8, $8589, $F56E, $E54F, $D52C, $C50D,
   $34E2, $24C3, $14A0, $0481, $7466, $6447, $5424, $4405,
   $A7DB, $B7FA, $8799, $97B8, $E75F, $F77E, $C71D, $D73C,
   $26D3, $36F2, $0691, $16B0, $6657, $7676, $4615, $5634,
   $D94C, $C96D, $F90E, $E92F, $99C8, $89E9, $B98A, $A9AB,
   $5844, $4865, $7806, $6827, $18C0, $08E1, $3882, $28A3,
   $CB7D, $DB5C, $EB3F, $FB1E, $8BF9, $9BD8, $ABBB, $BB9A,
   $4A75, $5A54, $6A37, $7A16, $0AF1, $1AD0, $2AB3, $3A92,
   $FD2E, $ED0F, $DD6C, $CD4D, $BDAA, $AD8B, $9DE8, $8DC9,
   $7C26, $6C07, $5C64, $4C45, $3CA2, $2C83, $1CE0, $0CC1,
   $EF1F, $FF3E, $CF5D, $DF7C, $AF9B, $BFBA, $8FD9, $9FF8,
   $6E17, $7E36, $4E55, $5E74, $2E93, $3EB2, $0ED1, $1EF0
    );

  //모드버스 프로토콜.
  // High-Order Byte Table
  (* Table of CRC values for high.order byte *)
  abCRCHi: array[0..255] of Byte = (
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40
  );

  // Low-Order Byte Table
  (* Table of CRC values for low.order byte *)
  abCRCLo: array[0..255] of Byte = (
  $00, $C0, $C1, $01, $C3, $03, $02, $C2, $C6, $06, $07, $C7, $05, $C5, $C4, $04,
  $CC, $0C, $0D, $CD, $0F, $CF, $CE, $0E, $0A, $CA, $CB, $0B, $C9, $09, $08, $C8,
  $D8, $18, $19, $D9, $1B, $DB, $DA, $1A, $1E, $DE, $DF, $1F, $DD, $1D, $1C, $DC,
  $14, $D4, $D5, $15, $D7, $17, $16, $D6, $D2, $12, $13, $D3, $11, $D1, $D0, $10,
  $F0, $30, $31, $F1, $33, $F3, $F2, $32, $36, $F6, $F7, $37, $F5, $35, $34, $F4,
  $3C, $FC, $FD, $3D, $FF, $3F, $3E, $FE, $FA, $3A, $3B, $FB, $39, $F9, $F8, $38,
  $28, $E8, $E9, $29, $EB, $2B, $2A, $EA, $EE, $2E, $2F, $EF, $2D, $ED, $EC, $2C,
  $E4, $24, $25, $E5, $27, $E7, $E6, $26, $22, $E2, $E3, $23, $E1, $21, $20, $E0,
  $A0, $60, $61, $A1, $63, $A3, $A2, $62, $66, $A6, $A7, $67, $A5, $65, $64, $A4,
  $6C, $AC, $AD, $6D, $AF, $6F, $6E, $AE, $AA, $6A, $6B, $AB, $69, $A9, $A8, $68,
  $78, $B8, $B9, $79, $BB, $7B, $7A, $BA, $BE, $7E, $7F, $BF, $7D, $BD, $BC, $7C,
  $B4, $74, $75, $B5, $77, $B7, $B6, $76, $72, $B2, $B3, $73, $B1, $71, $70, $B0,
  $50, $90, $91, $51, $93, $53, $52, $92, $96, $56, $57, $97, $55, $95, $94, $54,
  $9C, $5C, $5D, $9D, $5F, $9F, $9E, $5E, $5A, $9A, $9B, $5B, $99, $59, $58, $98,
  $88, $48, $49, $89, $4B, $8B, $8A, $4A, $4E, $8E, $8F, $4F, $8D, $4D, $4C, $8C,
  $44, $84, $85, $45, $87, $47, $46, $86, $82, $42, $43, $83, $41, $81, $80, $40
  );


function CalcCRC16(const AData: array of Byte; ASize: Integer): Word;
var
  bCrcHi, bCrcLo: Byte;
  nInx: Integer;
  i: Integer;
begin
  bCrcHi:= $FF; (* high byte of CRC initialized *)
  bCrcLo:= $FF; (* low byte of CRC initialized *)
  i:= 0;
  while ASize > 0 do begin
    nInx:= bCrcLo xor AData[i];
    bCrcLo:= bCrcHi xor abCRCHi[nInx];
    bCrcHi:= abCRCLo[nInx];
    dec(ASize);
    inc(i);
  end;

  Result:= 0;
  Result:= Result or (bCrcHi shl 8);
  Result:= Result or bCrcLo;
end;

function GetCRC16(const AData: Pointer; ASize: Integer): Word;
var
  p : PBYTE;
begin
  p := PBYTE(AData);
  Result := 0;
  while (ASize > 0) do begin
    Result := (Result shl 8) xor CRCTable16[((Result shr 8) xor p^) and $FF];
    Dec(ASize);
    Inc(p);
  end;
end;

function GetCRC16(const AText:string):word;
var
  ssData : TStringStream;
begin
  ssData := TStringStream.Create(AText);
  try
    Result := GetCRC16(ssData.Memory, ssData.Size);
  finally
    ssData.Free;
  end;
end;

function BufferToHex(const AData: Pointer; nCount: Integer): String;
var
  p : PBYTE;
  i: Integer;
begin
  p := PBYTE(AData);
  Result:= '';
  while (nCount > 0) do begin
    Result := Result + Format('%0.2x ',[p^]);
    Dec(nCount);
    Inc(p);
  end;
end;

end.
