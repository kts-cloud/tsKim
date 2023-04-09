unit HandBCR;

interface
uses
  System.SysUtils,  System.Classes, VaComm, Vcl.Dialogs, {CodeSiteLogging,} Winapi.Windows,
  DefRs232;
type

  InBcrEvnt = procedure(sGetData : String) of object;
  InBcrConn = procedure(bConnected : Boolean; sMsg : string) of object;
  TSerialBcr = class(TObject)
		comHandBcr : TVaComm;
  private
    m_nGroup     : integer;
    FReadyHandBcr: Integer;
    FOnRevBcrData: InBcrEvnt;
    FOnRevBcrConn: InBcrConn;
    FOnRevBcrDataMaint: InBcrEvnt;
    procedure SetOnRevBcrData(const Value: InBcrEvnt);
    procedure ReadVaCom(Sender: TObject; Count: Integer);
    procedure SetOnRevBcrConn(const Value: InBcrConn);
    procedure SetOnRevBcrDataMaint(const Value: InBcrEvnt);
  public
    m_sAllRxBcr   : String;
    m_bBcrConnection : boolean;
    constructor Create(AOwner: TComponent); virtual;
    destructor Destroy; override;
    procedure ChangePort(nPort: Integer);
    property ReadyHandBcr : Integer read FReadyHandBcr write FReadyHandBcr;
    property OnRevBcrData : InBcrEvnt read FOnRevBcrData write SetOnRevBcrData;
    property OnRevBcrDataMaint : InBcrEvnt read FOnRevBcrDataMaint write SetOnRevBcrDataMaint;
    property OnRevBcrConn : InBcrConn read FOnRevBcrConn write SetOnRevBcrConn;
  end;

var
  DongaHandBcr   :  TSerialBcr;

implementation
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$WARN IMPLICIT_STRING_CAST OFF}
{ TSerialBcr }

procedure TSerialBcr.ChangePort(nPort: Integer);
begin
  if nPort <> 0 then begin
    try
      comHandBcr.Name := 'HandBcr';
      comHandBcr.PortNum := nPort;
      comHandBcr.Parity   := paNone;
      comHandBcr.Databits := db8;
      comHandBcr.BaudRate := br115200;
      comHandBcr.StopBits           := sb1;
      comHandBcr.EventChars.EofChar := DefRs232.CR; // Enter 가 오면 Event 발생하도록..

      comHandBcr.OnRxChar  := ReadVaCom;
      m_sAllRxBcr := '';
      comHandBcr.Open;
      m_bBcrConnection := True;
      OnRevBcrConn(True,Format('COM%d',[nPort]));
    except on E : Exception do
      OnRevBcrConn(False,Format('COM%d',[nPort]));
    end;
  end
  else begin
    m_bBcrConnection := False;
    if comHandBcr is TVaComm then begin
      comHandBcr.Close;
    end;
    OnRevBcrConn(False,'NONE');
  end;
end;

constructor TSerialBcr.Create(AOwner: TComponent);
begin
  FReadyHandBcr := 0;
  comHandBcr := TVaComm.Create(AOwner);
end;

destructor TSerialBcr.Destroy;
begin
  if comHandBcr is TVaComm then begin
    comHandBcr.Close;
    comHandBcr.Free;
    comHandBcr := nil;
  end;
  inherited;
end;

procedure TSerialBcr.ReadVaCom(Sender: TObject; Count: Integer);
var
  sData : string;
begin
  sData := comHandBcr.ReadText;
  if Assigned(OnRevBcrData) then OnRevBcrData(sData);
  if Assigned(OnRevBcrDataMaint) then OnRevBcrDataMaint(sData);

end;

procedure TSerialBcr.SetOnRevBcrConn(const Value: InBcrConn);
begin
  FOnRevBcrConn := Value;
end;

procedure TSerialBcr.SetOnRevBcrData(const Value: InBcrEvnt);
begin
	FOnRevBcrData := Value;
end;

procedure TSerialBcr.SetOnRevBcrDataMaint(const Value: InBcrEvnt);
begin
  FOnRevBcrDataMaint := Value;
end;

end.
