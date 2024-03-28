unit SwitchBtn;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,  System.Classes, VaComm, Vcl.Dialogs,
  DefRs232, DefCommon;
type

  InSwEvent = procedure(nCH: Integer; sGetData : String) of object;

  PGuiSwitch  = ^RGuiSwitch;
  RGuiSwitch = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param1  : Integer;
    Msg     : string;
  end;

  TSerialSwitch = class(TObject)
		ComSw : TVaComm;
  private
    m_hMain     : THandle;
    m_nGroup    : integer;
    FReadySwData: Integer;
    FOnRevSwData: InSwEvent;
    procedure SetOnRevSwData(const Value: InSwEvent);
    procedure ReadVaCom(Sender: TObject; Count: Integer);
    procedure SendMainGuiDisplay(nGuiMode, nConnect : integer; sMsg : string);
  public

    constructor Create(hMain :HWND; nGroup: Integer); virtual;
    destructor Destroy; override;
    procedure SendSwitchMsg(sData : string);
    property ReadyHandSw : Integer read FReadySwData write FReadySwData;
    property OnRevSwData : InSwEvent read FOnRevSwData write SetOnRevSwData;
    procedure ChangePort( nPort : Integer);
  end;

//var
//  DongaSwitch   : TSerialSwitch;

implementation

{ TSerialSwitch }

procedure TSerialSwitch.ChangePort(nPort: Integer);
var
  sTemp : string;
begin

  if nPort <> 0 then begin
    try
//      OnRevSwData(Format('1%d',[nPort]),True);
//      sTemp := Format('%d%d',[m_nJig,nPort]);
      sTemp := Format('COM%d',[nPort]);
      ComSw.Close;
      ComSw.Name := Format('ComSw%d',[nPort]);
      ComSw.PortNum := nPort;
      ComSw.Parity   := paNone;
      ComSw.Databits := db8;
      ComSw.BaudRate := br115200;
      ComSw.StopBits           := sb1;
      ComSw.EventChars.EofChar := DefRs232.STX;//DefSerialComm.ETX; // Enter 가 오면 Event 발생하도록..
      ComSw.OnRxChar  := ReadVaCom;

      ComSw.Open;

      SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_CONNECTION,1,sTemp);
    except
      // 0 : disconnect, 1 : Connect , 2 : NONE;
      SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_CONNECTION,0,sTemp);
//    except on E : Exception do
//      CodeSite.SendException(E);
//      OnRevSwData(Format('0%d',[nPort]),True);
    end;
  end
  else begin
//    sTemp := Format('0%d',[nPort]);
//    OnRevSwData(sTemp ,True);

    SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_CONNECTION,2,'NONE');

    if ComSw is TVaComm then begin
      ComSw.Close;
    end;
  end;

end;

constructor TSerialSwitch.Create(hMain :HWND; nGroup: Integer);
begin
  FReadySwData := 0;
  m_hMain := hMain;
  m_nGroup := nGroup;
  ComSw := TVaComm.Create(nil);
//  ChangePort(nPort);

end;

destructor TSerialSwitch.Destroy;
begin
  if ComSw is TVaComm then begin
    ComSw.Close;
    ComSw.Free;
    ComSw := nil;
  end;
  inherited;
end;

procedure TSerialSwitch.ReadVaCom(Sender: TObject; Count: Integer);
var
  sData : string;
begin
  sData := string(ComSw.ReadText);
//  CodeSite.Send(sData);
//  SendMainGuiDisplay(DefPocb.MSG_MODE_DISPLAY_RCBDATA,m_nJig,sData);
  OnRevSwData(m_nGroup,sData);
end;

procedure TSerialSwitch.SendMainGuiDisplay(nGuiMode, nConnect: integer; sMsg: string);
var
  ccd         : TCopyDataStruct;
  GuiSwitchData :  RGuiSwitch;
begin

  GuiSwitchData.MsgType := DefCommon.MSG_TYPE_SWITCH;
  GuiSwitchData.Channel := m_nGroup;
  GuiSwitchData.Mode    := nGuiMode;
  GuiSwitchData.Param1  := nConnect;
  GuiSwitchData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiSwitchData);
  ccd.lpData      := @GuiSwitchData;
  SendMessage(m_hMain,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TSerialSwitch.SendSwitchMsg(sData: string);
var
  sSendData : AnsiString;
begin
  sSendData := AnsiChar(DefRs232.STX) + AnsiChar(DefRs232.SF5) + AnsiChar(DefRs232.SF1) + AnsiString(sSendData) + AnsiChar(DefRs232.ETX);
  ComSw.WriteText(sSendData);
end;

procedure TSerialSwitch.SetOnRevSwData(const Value: InSwEvent);
begin
	FOnRevSwData := Value;
end;

end.
