unit CommLightNaratech;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,  System.Classes, VaComm, SyncObjs;

const
  MAX_LIGHTCOUNT = 8;
  COMM_CAM_LIGHT_CONNECTION  = 100;
type

  ///<summary>8채널 광량 값(0..7)</summary>
  TLightBrights = array [0..MAX_LIGHTCOUNT-1] of Byte;

  PGuiCommLight  = ^RGuiCommLight;
  RGuiCommLight = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param  : Integer;
    Msg     : string;
  end;

  ///<summary>
  /// 이물 조명 제어 클래스by kg.jo 20201116
  /// 장비: Naratech PD3000. RS-232 통신
  /// 프로토콜문서: PD300사양서.pdf
  ///</summary>
  TCommLight = class
  private
    m_VaComm : TVaComm;
    m_nType : Integer;
    procedure CommLightRxChar(Sender: TObject; Count: Integer);
    function CalcChecksum(brights: TLightBrights): Byte;
    procedure SendMessageMain(nMode: Integer; nCh, NParam, nParam2: Integer; sMsg: String);
  public
    Connected: Boolean; //연결 여부
    BrightList: TLightBrights;
    m_hMain : HWND;
  public
    IsMaint : Boolean;
    constructor Create(hMain : HWND;nLightType : Integer); virtual;
    destructor Destroy; override;
    function Connect(nPort: Integer): boolean;
    procedure Disconnect;
    ///<summary>8채널 광량 변경</summary>
    procedure WriteBrights(brights: TLightBrights);
    ///<summary>1채널 광량 변경</summary>
    procedure WriteBrightOne(nCh: Byte; nBright: Byte);
    ///<summary>2채널 광량 변경</summary>
    procedure WriteBrightTwin(nCh1, nCh2, nBright1, nBright2: Byte);
    ///<summary>8채널 광량 켜기 (0)</summary>
    procedure WriteBrightsAll(nBright: Byte);
    ///<summary>8채널 광량 메모리에 저장</summary>
    procedure SaveBrights;
    ///<summary>8채널 광량 메모리에서 로드</summary>
    procedure LoadBrights;
  end;

var
  CommLight: TCommLight;

implementation

{ TCommLightNaratech }

constructor TCommLight.Create(hMain : HWND; nLightType : Integer);
begin
  m_VaComm := TVaComm.Create(nil);
  m_VaComm.Baudrate:= br19200; // br9600;
  m_VaComm.Parity:= paNone;
  m_VaComm.Databits:= db8;
  m_VaComm.Stopbits:= sb1;
  m_VaComm.EventChars.EofChar := #13;
  m_VaComm.EventChars.EventChar := #13;
  m_VaComm.SyncThreads:= False;  //Not GUI Sync

  m_VaComm.OnRxChar:= CommLightRxChar;

  Connected:= False;
  Fillchar(BrightList, MAX_LIGHTCOUNT, 0);
  m_hMain := hMain;
  m_nType := nLightType;
end;

destructor TCommLight.Destroy;
begin
  Disconnect;

  FreeAndNil(m_VaComm);
  inherited;
end;

function TCommLight.Connect(nPort: Integer): boolean;
begin
  Result:= False;
  if nPort = 0 then begin
    SendMessageMain(CommLightNaratech.COMM_CAM_LIGHT_CONNECTION,0,2,0,'NONE');
    Exit(False);
  end;

  if m_VaComm.Active then begin
    Exit;
  end;

  try
    m_VaComm.Close;
    m_VaComm.PortNum:= nPort;
    m_VaComm.Open;

    //WriteBrightsAll(0); //전체 조명 끄기
    Connected:= True;
    Result:= True;
  except
    on E : Exception do begin
      //E.Message
    end;
  end;
  if Connected then SendMessageMain(CommLightNaratech.COMM_CAM_LIGHT_CONNECTION,0,1,0,Format('COM %d',[nPort]))
  else              SendMessageMain(CommLightNaratech.COMM_CAM_LIGHT_CONNECTION,0,0,0,Format('COM %d',[nPort]));

end;

procedure TCommLight.Disconnect;
begin
  m_VaComm.Close;
  Connected:= False;
end;

function TCommLight.CalcChecksum(brights: TLightBrights): Byte;
begin
  Result:= brights[0] xor brights[1] xor brights[2] xor brights[3] xor brights[4]
        xor brights[5] xor brights[6] xor brights[7];
  Result:= Result and $FF;
end;

procedure TCommLight.CommLightRxChar(Sender: TObject; Count: Integer);
begin
  //
end;


procedure TCommLight.WriteBrightOne(nCh, nBright: Byte);
var
  buff: TBytes;
  sBright: String;
begin
  if m_VaComm.Active then begin
      SetLength(buff, 7);
      buff[0]:= $4C;
      buff[1]:= $30 + nCh;
      sBright:= format('%.3d', [nBright]);
      buff[2]:= ord(sBright[1]);
      buff[3]:= ord(sBright[2]);
      buff[4]:= ord(sBright[3]);
      buff[5]:= $0D;
      buff[6]:= $0A;
      m_VaComm.WriteBuf(buff[0], 7);
      BrightList[nCh]:= nBright;
  end;
end;

procedure TCommLight.WriteBrightTwin(nCh1, nCh2, nBright1, nBright2: Byte);
var
  buff: TBytes;
  sBright: String;
begin
  if m_VaComm.Active then begin
    SetLength(buff, 7);
    Sleep(50);
    buff[0]:= $4C;
    buff[1]:= $30 + nCh1;
    sBright:= format('%.3d', [nBright1]);
    buff[2]:= ord(sBright[1]);
    buff[3]:= ord(sBright[2]);
    buff[4]:= ord(sBright[3]);
    buff[5]:= $0D;
    buff[6]:= $0A;

    m_VaComm.WriteBuf(buff[0], 7);
    BrightList[nCh1]:= nBright1;
    Sleep(100);

    buff[0]:= $4C;
    buff[1]:= $30 + nCh2;
    sBright:= format('%.3d', [nBright2]);
    buff[2]:= ord(sBright[1]);
    buff[3]:= ord(sBright[2]);
    buff[4]:= ord(sBright[3]);
    buff[5]:= $0D;
    buff[6]:= $0A;
    Sleep(50);
    m_VaComm.WriteBuf(buff[0], 7);
    BrightList[nCh2]:= Byte(nBright2);
  end;
end;

procedure TCommLight.WriteBrights(brights: TLightBrights);
var
  buff : TBytes;
  crc : Byte;
begin
  if m_VaComm.Active then begin
    SetLength(buff, 14);
    buff[0]:= $3A;
    buff[1]:= $3A;
    buff[2]:= 0; //전체
    CopyMemory(@buff[3], @brights[0], MAX_LIGHTCOUNT);

    crc:= CalcChecksum(brights);
    buff[11]:= crc and $FF;
    buff[12]:= $EE;
    buff[13]:= $EE;
    m_VaComm.WriteBuf(buff[0], 14);
    CopyMemory(@BrightList[0], @brights[0], MAX_LIGHTCOUNT);
  end;
end;

procedure TCommLight.WriteBrightsAll(nBright: Byte);
var
  buff: TBytes;
  crc: Byte;
  brights: TLightBrights;
begin
  if m_VaComm.Active then begin
      SetLength(buff, 14);
      buff[0]:= $3A;
      buff[1]:= $3A;
      buff[2]:= 0; //전체
      FillChar(BrightList[0], MAX_LIGHTCOUNT, nBright);
      CopyMemory(@buff[3], @BrightList[0], MAX_LIGHTCOUNT);

      crc:= CalcChecksum(BrightList);
      buff[11]:= crc and $FF;
      buff[12]:= $EE;
      buff[13]:= $EE;
      m_VaComm.WriteBuf(buff[0], 14);
  end;
end;

procedure TCommLight.SaveBrights;
var
  buff: TBytes;
  crc: Byte;
  brights: TLightBrights;
begin
  if m_VaComm.Active then begin
      SetLength(buff, 14);
      buff[0]:= $3A;
      buff[1]:= $3A;
      buff[2]:= ord('W');
      FillChar(brights, MAX_LIGHTCOUNT, $FF);
      //CopyMemory(@buff[3], @BrightList[0], MAX_LIGHTCOUNT);
      CopyMemory(@buff[3], @brights[0], MAX_LIGHTCOUNT);
      crc:= CalcChecksum(brights);
      buff[11]:= crc and $FF;
      buff[12]:= $EE;
      buff[13]:= $EE;
      m_VaComm.WriteBuf(buff[0], 14);
  end;
end;

procedure TCommLight.SendMessageMain(nMode, nCh, nParam, nParam2: Integer; sMsg: String);
var
  cds         : TCopyDataStruct;
  GUIMessage     : RGuiCommLight;
begin
  GUIMessage.MsgType := m_nType;
  GUIMessage.Channel := nCh;
  GUIMessage.Mode    := nMode;
  GUIMessage.Param   := nParam;
  GUIMessage.Msg     := sMsg;
  cds.dwData      := 0;
  cds.cbData      := SizeOf(GUIMessage);
  cds.lpData      := @GUIMessage;
  SendMessage(m_hMain, WM_COPYDATA, 0, LongInt(@cds));
end;

procedure TCommLight.LoadBrights;
var
  buff: TBytes;
  crc: Byte;
begin
  if m_VaComm.Active then begin
      SetLength(buff, 13);
      buff[0]:= $3A;
      buff[1]:= $3A;
      buff[2]:= ord('R');
      CopyMemory(@buff[3], @BrightList[0], MAX_LIGHTCOUNT);

      crc:= CalcChecksum(BrightList);
      buff[11]:= crc and $FF;
      buff[12]:= $EE;
      buff[13]:= $EE;
      m_VaComm.WriteBuf(buff[0], 14);
  end;
end;

end.
