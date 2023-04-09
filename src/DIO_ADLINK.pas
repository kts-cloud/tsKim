unit DIO_ADLINK;

interface

uses
  System.SysUtils, System.Classes, Vcl.Dialogs, Winapi.Windows, Vcl.ExtCtrls, DefDio,
  Winapi.Messages, System.UITypes, Dask, DefCommon, CommonClass;
{$I Common.inc}
type
  PGuiAxDio = ^RGuiAxDio;
  RGuiAxDio = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    nParam  : Integer;
    Msg     : string;
  end;

  ///	<summary>
  ///	  DIO 정의 Class
  ///	</summary>
  ///	<remarks>
  ///	  DIO Card에 사용하는 모든 정의.
  ///	</remarks>

  AdIoStatus = array[0..pred(DefDio.MAX_ADLINK_IO_CNT)] of boolean;
  InDioEvent = procedure(InDio, OutDio : AdIoStatus) of object;
  ///	<summary>
  ///	  동아엘텍에서 사용하는 DIO Class
  ///	</summary>
  TDongaDio = class(TObject)
    tmCheckDio : TTimer;
  private
    { Private declarations }
    m_hMain     : THandle;
    m_nCardId   : Integer;
    m_nDOValue, m_nDIValue, m_nOldDIValue  : Cardinal;
    m_nDIOErr   : Integer;
    FInDioStatus: InDioEvent;
    FIsMaintOn: Boolean;
    FMaintInDioStatus: InDioEvent;

    procedure EndDio;
    procedure GetAllDio;

    procedure SetInDioStatus (const Value: InDioEvent);
    procedure SetIsMaintOn(const Value: Boolean);
    procedure SetMaintInDioStatus(const Value: InDioEvent);

    procedure SendMainGuiDisplay(nGuiMode : Integer; nP1: Integer = 0; sMsg : string = '');
  public
    { Public declarations }
//    m_ReadyForMoterRun : array [1..5] of Boolean;
    //5개 존 모터 턴 Flag
    m_nSetDio,m_nGetDio : AdIoStatus;

    ///	<summary>
    ///	  DIO 설정및 Dio Searching을 위한
    ///	</summary>
    ///	<param name="nCardID">
    ///	  동작 PCI Type Card ID
    ///	</param>
    ///	<param name="nScanTim">
    ///	  Create하면 설정 값대로 Timer가 동작 - ms 단위
    ///	</param>
    constructor Create(hMain: HWND; nCardID, nScanTim : Integer); virtual;

    ///	<summary>
    ///	  초기화
    ///	</summary>
    ///	<remarks>
    ///	  <para>
    ///	    1. Dio Scan Timer Stop.
    ///	  </para>
    ///	  <para>
    ///	    2. Dio Card Release
    ///	  </para>
    ///	</remarks>
    destructor Destroy; override;
    procedure GetDioStatus;
    procedure OntmCheckDioTimer(Sender: TObject);
    function  SetDio(lwSignal : LongWord) : Integer;
    property InAdDioStatus : InDioEvent read FInDioStatus write SetInDioStatus;
    property MaintInAdDioStatus : InDioEvent read FMaintInDioStatus write SetMaintInDioStatus;
    property IsMaintOn : Boolean read FIsMaintOn write SetIsMaintOn;
    // for simulation.
    procedure SetInDioForSimulator;
  end;
var
  ///	<summary>
  ///	  동아엘텍에서 사용하는 DIO Class
  ///	</summary>
  AdLinkDio : TDongaDio;

implementation

{ TDongaDio }

constructor TDongaDio.Create(hMain: HWND; nCardID, nScanTim : Integer);
var
  i : Integer;
  sErrMsg : String;
begin
  m_hMain := hMain;
  m_nCardId     := -1;
{$IFNDEF SIMULATOR_DIO}
  m_nCardId := Register_Card(PCI_7230, DefDio.CARDNUMBER_1);
  if m_nCardId < 0 then begin
//    MessageDlg('Cannot Find DIO Card(PCI) !', mtError, [mbOk], 0);//
    sErrMsg := 'Register Error!';
    SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_CONNECTION, 1, sErrMsg);
  end
  else begin
    SendMainGuiDisplay(DefCommon.MSG_MODE_DISPLAY_CONNECTION, 0, 'Connected');
  end;
{$ELSE}
  m_nCardId := 0;
{$ENDIF}
  m_nDOValue    := 0;
  m_nDIValue    := 0;
  m_nOldDIValue := 0;
  m_nDIOErr     := 0;
  for i := 0 to Pred(DefDio.MAX_ADLINK_IO_CNT) do begin
    m_nSetDio[i] := False;
    m_nGetDio[i] := False;
  end;
  tmCheckDio := TTimer.Create(nil);
  tmCheckDio.Enabled  := False;
  tmCheckDio.Interval := nScanTim;
  tmCheckDio.OnTimer  := OntmCheckDioTimer;
end;

destructor TDongaDio.Destroy;
begin

  if tmCheckDio <> nil then begin
    tmCheckDio.Enabled  := False;
    tmCheckDio.Free;
    tmCheckDio := nil;
  end;
  EndDio;
  inherited;
end;

procedure TDongaDio.EndDio;
begin
  if m_nCardId >=0 then Release_Card(m_nCardId);
//  if m_nCardId_2 >=0 then Release_Card(m_nCardId_2);
end;


procedure TDongaDio.GetAllDio;
var
  cdTemp  : Cardinal;
  i       : Integer;
  wTemp   : Word;
begin
  cdTemp := m_nDIValue;
{$IFNDEF SIMULATOR_DIO}
  m_nDIOErr := DI_ReadPort(word(m_nCardId),word(DefDio.DIPORT),cdTemp);
  m_nDIValue := cdTemp;
{$ENDIF}
  for i := 0 to Pred(defDio.MAX_ADLINK_IO_CNT) do begin
    wTemp := 1 shl i;
    if (wTemp and cdTemp) <> 0  then m_nGetDio[i] := True
    else                             m_nGetDio[i] := False;
  end;
  if m_nDIValue <> m_nOldDIValue then begin
    if Assigned(InAdDioStatus) then InAdDioStatus(m_nGetDio, m_nSetDio);
    if Assigned(MaintInAdDioStatus) and IsMaintOn then MaintInAdDioStatus(m_nGetDio, m_nSetDio);
//    InDioStatus_1(m_nGetDio_1, m_nSetDio_1);
  end;
  m_nOldDIValue := cdTemp;
end;


//procedure TDongaDio.GetAllDio_2;
//var
//  cdTemp  : Cardinal;
//  i       : Integer;
//  wTemp   : Word;
//begin
//	cdTemp := m_nDIValue_2;
//  m_nDIOErr_2 := DI_ReadPort(word(m_nCardId_2),word(DefDio.DIPORT),cdTemp);
//
//  m_nDIValue_2 := cdTemp;
//  for i := 0 to Pred(defDio.MAX_IO_CNT) do begin
//    wTemp := 1 shl i;
//    if (wTemp and cdTemp) <> 0  then m_nGetDio_2[i] := True
//    else                             m_nGetDio_2[i] := False;
//  end;
//  if m_nDIValue_2 <> m_nOldDIValue_2 then begin
//    InDioStatus_2(m_nGetDio_2,m_nSetDio_2);
//  end;
//  m_nOldDIValue_2 := cdTemp;
//end;

//function TDongaDio.GetDio(wSignal: Word): Boolean;
//var
//  cdTemp : Cardinal;
//begin
//  cdTemp := m_nDIValue;
//  m_nDIOErr := DI_ReadPort(word(m_nCardId),word(DefDio.DIPORT),cdTemp);
//  m_nDIValue := cdTemp;
//
//  if ((m_nDIValue and wSignal) = $0) then result := False
//  else  result := True;
//end;

procedure TDongaDio.GetDioStatus;
begin
    tmCheckDio.Enabled := True;
end;

procedure TDongaDio.OntmCheckDioTimer(Sender: TObject);
begin
//	tmCheckDio_1.Enabled := False;
  GetAllDio;
//	tmCheckDio_1.Enabled := True;
end;

//procedure TDongaDio.OntmCheckDioTimer_2(Sender: TObject);
//begin
//  GetAllDio_2;
//end;

//procedure TDongaDio.OnTmControlDioTimer(Sender: TObject);
//begin
//
//end;

procedure TDongaDio.SendMainGuiDisplay(nGuiMode, nP1: Integer; sMsg: string);
var
  ccd         : TCopyDataStruct;
  GuiData     : RGuiAxDio;
begin
  GuiData.MsgType := DefCommon.MSG_TYPE_ADLINK;
  GuiData.Channel := 0 ;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam  := nP1;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_hMain,WM_COPYDATA,0, LongInt(@ccd));
end;

function TDongaDio.SetDio(lwSignal: LongWord): Integer;
var
  nRet : Integer;
begin
  if ((m_nDOValue shr lwSignal) and $01) > 0 then begin
    m_nDOValue := m_nDOValue - (1 shl lwSignal);
    m_nSetDio[lwSignal] := False;
    nRet :=0;
  end
  else begin
    m_nDOValue := m_nDOValue + (1 shl lwSignal);
    m_nSetDio[lwSignal] := True;
    nRet :=1;
  end;
{$IFNDEF SIMULATOR_DIO}
  m_nDIOErr := DO_WritePort(m_nCardId, DefDio.DOPORT, m_nDOValue);
{$ELSE}
  m_nDIOErr := 0;
{$ENDIF}
  if m_nDIOErr > 0 then Result := 2
  else begin
    if Assigned(InAdDioStatus) then InAdDioStatus(m_nGetDio, m_nSetDio);
    if Assigned(MaintInAdDioStatus) and IsMaintOn then MaintInAdDioStatus(m_nGetDio, m_nSetDio);
//    InDioStatus_1(m_nGetDio_1,m_nSetDio_1);
    Result := nRet;
  end;
end;

//function TDongaDio.SetDio_2(lwSignal: LongWord): Integer;
//var
//	nRet : Integer;
//begin
//	if ((m_nDOValue_2 shr lwSignal) and $01) > 0 then begin
//		m_nDOValue_2 := m_nDOValue_2 - (1 shl lwSignal);
//		m_nSetDio_2[lwSignal] := False;
//		nRet :=0;
//	end
//	else begin
//		m_nDOValue_2 := m_nDOValue_2 + (1 shl lwSignal);
//		m_nSetDio_2[lwSignal] := True;
//		nRet :=1;
//	end;
//	m_nDIOErr_2 := DO_WritePort(m_nCardId_2, DefDio.DOPORT, m_nDOValue_2);
//	if m_nDIOErr_2 > 0 then Result := 2
//	else begin
//		InDioStatus_2(m_nGetDio_2,m_nSetDio_2);
//		Result := nRet;
//	end;
//end;
procedure TDongaDio.SetInDioForSimulator;
var
  i , nTemp: Integer;
  wTemp : word;
begin
  wTemp := 0;
  nTemp := 0;
	for i := 0 to Pred(defDio.MAX_IO_CNT) do begin
    if m_nGetDio[i] then wTemp := 1 shl i;
    nTemp := nTemp or wTemp;
	end;
  m_nDIValue := nTemp;
end;

procedure TDongaDio.SetInDioStatus(const Value: InDioEvent);
begin
  FInDioStatus := Value;
end;

procedure TDongaDio.SetIsMaintOn(const Value: Boolean);
begin
  FIsMaintOn := Value;
end;

procedure TDongaDio.SetMaintInDioStatus(const Value: InDioEvent);
begin
  FMaintInDioStatus := Value;
end;

//procedure TDongaDio.SetInDioStatus_2(const Value: InDioEvnt_2);
//begin
//	FInDioStatus_2 := Value;
//end;

//procedure TDongaDio.SetIsJigStop(const Value: Boolean);
//begin
//  FIsJigStop := m_nGetDio[DefDio.IN_JIG_TURN] or m_nGetDio[DefDio.IN_JIG_RETRUN];
//end;

end.
