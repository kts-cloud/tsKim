unit PlcSimluateForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, SyncObjs,
  System.AnsiStrings,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, AdvObj, BaseGrid, AdvGrid;

const
  MAX_PLC_MEMORY_SIZE  = $F100; //8192; //4096; //2048; //255;

type

  /// <summary> ECS Glass Data Structure. 실처리 보고나 Load/Unload 시 전달정보. 참조 Melsec사양 4.1</summary>
  TECSGlassData = record
    //Glass Data 는 48 Word로 구성된다.
    LOT_ID: String; //8 Word( 16 Char)
    ProcessingCode: String; //4 Word( 8 Char)
    LOTSpecificData: array [0..3] of Integer;
    RecipeNumber: Integer;
    GlassType: Integer;
    GlassCode: Integer;
    GlassID: String; //8 Word( 16 Char)
    GlassJudge: Integer;  //'P'/'F'
    GlassSpecificData: array [0..3] of Integer;
//    GlassAddData: array [0..5] of Integer;
    PreviousUnitProcessing: array [0..7] of Integer;
    GlassProcessingStatus: array [0..7] of Integer;
//    GlassRoutingData: array [0..2] of Integer;
    PCZTCode: Integer;
    PCZTID: String; //8 Word( 16 Char)
  end;

  TfrmPlcSimulate = class(TForm)
    pnPLC: TPanel;
    grdPLCMemory: TAdvStringGrid;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    cboAddr: TComboBox;
    btnGotoAddr: TButton;
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    rgDataType: TRadioGroup;
    edtWriteAddr: TEdit;
    btnWriteAddr: TButton;
    edtWriteValue: TEdit;
    lblSelectedAddr: TLabel;
    pnLog: TPanel;
    mmoLog: TMemo;
    Panel3: TPanel;
    btnClearLog_PG: TButton;
    Label28: TLabel;
    cboPLC_CommandList: TComboBox;
    chkPLCExec_On: TCheckBox;
    btnPLCExec_Command: TButton;
    tmrCycle: TTimer;
    edtAddr: TEdit;
    Label4: TLabel;
    btnGotoPrev: TButton;
    btnGotoNext: TButton;
    chkAutoStart: TCheckBox;
    chkPauseProcess: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGotoAddrClick(Sender: TObject);
    procedure btnPLCExec_CommandClick(Sender: TObject);
    procedure btnWriteAddrClick(Sender: TObject);
    procedure grdPLCMemoryDblClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure grdPLCMemoryGetCellColor(Sender: TObject; ARow, ACol: Integer;
      AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
    procedure btnClearLog_PGClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure tmrCycleTimer(Sender: TObject);
    procedure btnGotoPrevClick(Sender: TObject);
    procedure btnGotoNextClick(Sender: TObject);
    procedure edtAddrKeyPress(Sender: TObject; var Key: Char);
  private
    m_bOpened: Boolean;
    m_bOpenedAXDIO: Boolean;
    //frmPlcSimulateActive: integer;
    m_nTableTurnType: integer;
    m_nStep_TableTurn: integer;
    m_nDisplayAddr: Integer;
    m_nDisplayDevice: Integer;
    m_csWrite: TCriticalSection;
    m_sLog: String;
    m_thMonitoring: TThread;
    ///<summary>로그에 추가</summary>
    ///<param>sMsg: 추가할 로그</param>
    procedure AddLog(sMsg: string; bSync: Boolean=False);
    procedure DoSync;
    ///<summary>초기화, 메모리 초기화 등</summary>
    procedure Init;
    ///<summary>PLC 명령 셋 초기화</summary>
    procedure Init_PLCCommnad;
    ///<summary>그리드에 메모리 내용 표시</summary>
    procedure Display_Memory;
    ///<summary>자동 시작 요청 셋</summary>
    ///<param>nValue: 설정/해제</param>
    procedure AutoStartReq(nValue: Integer);
    ///<summary>비트 값 가져오기</summary>
    function Get_Bit(var nData: Word; nLoc: Word): Word;
    ///<summary>비트 값 쓰기</summary>
    function Set_Bit(var nData: Word; nLoc, Value: Word): Word;
    ///<summary>DWord 비트 값 쓰기</summary>
    function Set_Bit_DWord(var nData: DWord; nLoc, Value: DWord): DWord;
    ///<summary>화면 그리드의 메모리 값 갱신</summary>
    procedure UpdataPLC;
    function GetDeviceMemory(const szDevice: String; out pwMemory:PWORD): Integer;
    procedure Thread_Monitoring;
    procedure Process_Monitoring_EQP(nAddr, nData: Integer);
    procedure Process_LinkTest;
    procedure Process_UCHK(nData: Integer);
    procedure Process_PCHK(nCh, nData: Integer);
    procedure Process_EICR(nCh, nData: Integer);
    procedure Process_EICR_ACK(nCh, nData: Integer);
    procedure Process_APDR(nData: Integer);
    procedure Process_Load_GlassData(nCh: Integer);
    procedure Process_Load_Enable(nCh: Integer);
    procedure Process_Load_CompleteConfirm(nCh: Integer);
    procedure Process_Unload_Enable(nCh: Integer);
    procedure Process_Unload_CompleteConfirm(nCh: Integer);
    procedure Process_ReadyToStart(nCh: Integer);
    procedure Process_InspectionStart_Confirm(nCh: Integer);
    procedure Process_ZSET(nCh: Integer);
    procedure ConvertGlassDataToBlock(var AGlassData: TECSGlassData; var naGlassData: array of Integer);
    function ConvertStrFromPLC(nLen: Integer; naData: array of Integer): String;
    procedure ConvertStrToPLC(sData: string; nLen: Integer; var naData: array of Integer);
    procedure ConvertBlockToGlassData(var naGlassData: array of Integer; var AGlassData: TECSGlassData);


    { Private declarations }
  public
    m_bStopMonitoring: Boolean;
    { Public declarations }
    ///<summary>B0 - Bit</summary>
    Memory_B0: array [0..MAX_PLC_MEMORY_SIZE] of Word;
    ///<summary>W0 - Word</summary>
    Memory_W0: array [0..MAX_PLC_MEMORY_SIZE] of Word;
    Memory_D0: array [0..MAX_PLC_MEMORY_SIZE] of Word;
    Memory_BPre: array [0..MAX_PLC_MEMORY_SIZE] of Word;
    Memory_WPre: array [0..MAX_PLC_MEMORY_SIZE] of Word;
    Memory_DPre: array [0..MAX_PLC_MEMORY_SIZE] of Word;

    /// <summary> EQP ID 장비 번호</summary>
    EQP_ID: Integer;
    /// <summary> PLC 시작 주소- EQP</summary>
    StartAddr_EQP: Integer;
    /// <summary> PLC 시작 주소- ECS</summary>
    StartAddr_ECS: Integer;
    /// <summary> PLC 시작 주소- ROBOT</summary>
    StartAddr_ROBOT: Integer;
    /// <summary> PLC 시작 주소Word- EQP</summary>
    StartAddr_EQP_W: Integer;
    /// <summary> PLC 시작 주소Word- ROBOT</summary>
    StartAddr_ROBOT_W: Integer;
    /// <summary> PLC 시작 주소Word- ECS</summary>
    StartAddr_ECS_W: Integer;

    ///<summary>Delay 잠시 대기 UI Freez 방지  </summary>
    procedure Delay(nTickTime: integer);
    ///<summary>활성화 여부 : 주로 종료 시 AddLog 사용 문제 방지</summary>
    procedure SetActive(nValue: integer);
    ///<summary>PLC Open</summary>
    function OpenPLC(): Integer;
    ///<summary>PLC Close</summary>
    function ClosePLC(): Integer;
    ///<summary>메모리 데이터 단일 읽기</summary>
    ///<param>szDevice: 메모리 주소, B200, W200 </param>
    ///<param>lplData: 메모리 읽을 데이터 반환 변수</param>
    function GetDevice(const szDevice: WideString; out lplData: Integer): Integer;
    ///<summary>메모리 데이터 단일 쓰기</summary>
    ///<param>szDevice: 메모리 주소, B200, W200</param>
    ///<param>nData: 메모리 쓰기 데이터 변수</param>
    function SetDevice(const szDevice: WideString; nData: Integer): Integer;
    ///<summary>메모리 데이터 읽기</summary>
    ///<param>szDevice: 메모리 주소, D1300, D1310, D1320 </param>
    ///<param>lSize: 메모리 읽을 개수, 배열 개수 </param>
    ///<param>lplData: 메모리 읽을 데이터 반환 배열</param>
    function ReadDeviceBlock(const szDevice: String; lSize: Integer; out lplData: Integer): integer;
    ///<summary>메모리 데이터 쓰기</summary>
    ///<param>szDevice: 메모리 주소, D1200</param>
    ///<param>lSize: 메모리 쓰기 개수, 배열 개수 </param>
    ///<param>lplData: 메모리 쓰기 데이터 배열</param>
    function WriteDeviceBlock(const szDevice: String; lSize: Integer; var lplData: Integer): integer;
    /// <summary> 시간 데이터 읽기 </summary>
    function GetClockData(out lpsYear: Smallint; out lpsMonth: Smallint; out lpsDay: Smallint;
                          out lpsDayOfWeek: Smallint; out lpsHour: Smallint;
                          out lpsMinute: Smallint; out lpsSecond: Smallint): Integer;
    procedure PulseDevice(const szDevice: String; nDelay: Integer=1000);
    /// <summary> 일정 시간 지연 후 데이터 쓰기. </summary>
    procedure SetDeviceDelay(const szDevice: String; nData, nDelay: Integer);
    /// <summary> Buffer 읽기. 아직 준비되지 않음 </summary>
    function ReadBuffer(lStartIO: Integer; lAddress: Integer; lSize: Integer; out lpsData: Smallint): Integer;
    /// <summary> Buffer 쓰기. 아직 준비되지 않음 </summary>
    function WriteBuffer(lStartIO: Integer; lAddress: Integer; lSize: Integer; var lpsData: Smallint): Integer;

  end;

var
  frmPlcSimulate: TfrmPlcSimulate;

implementation

{$R *.dfm}
//const
//  StartAddr_EQP   = $0;
//  StartAddr_ROBOT = $100;
//  StartAddr_ECS   = $200;
//
//  StartAddr_EQP_W   = $0;
//  StartAddr_ROBOT_W = $100;
//  StartAddr_ECS_W   = $200;

var
  frmPlcSimulateActive: Integer;

{ TfrmPlcSimulate }
procedure TfrmPlcSimulate.AddLog(sMsg: string; bSync: Boolean);
begin
  if frmPlcSimulateActive = 0 then exit;

  m_sLog := Format('%s %s', [FormatDateTime('HH:NN:SS.ZZZ', Now()), sMsg]);
  if frmPlcSimulateActive = 0 then exit;

  if bSync then begin
    TThread.Synchronize(TThread.CurrentThread, DoSync);
  end
  else begin
    DoSync;
  end;
end;

procedure TfrmPlcSimulate.DoSync;
begin
  try
    if mmoLog.Lines.Count > 1000 then mmoLog.Lines.Clear;
    mmoLog.Lines.Add(m_sLog);
  Except

  end;
end;

procedure TfrmPlcSimulate.edtAddrKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then begin
    btnGotoAddrClick(Sender);
    Key:= #0;
  end;
end;

procedure TfrmPlcSimulate.FormCreate(Sender: TObject);
begin
  Tag:= 0;
  m_nTableTurnType:= 0; //테이블 턴 방향 0: 1234, 1:5678
  m_nStep_TableTurn:= 0;
  m_nDisplayAddr:= 0;
  m_nDisplayDevice:= 0;
  mmoLog.Clear;
  m_bOpened:= false;
  m_csWrite:= TCriticalSection.Create;

//  SetLength(Memory_B0, MAX_PLC_MEMORY_SIZE);
//  SetLength(Memory_W0, MAX_PLC_MEMORY_SIZE);
//  SetLength(Memory_BPre, MAX_PLC_MEMORY_SIZE);
//  SetLength(Memory_WPre, MAX_PLC_MEMORY_SIZE);

  Init();
  SetActive(1);

  m_bStopMonitoring:= False;
  TThread.CreateAnonymousThread(Thread_Monitoring).Start;


  tmrCycle.Interval:= 1000;
  tmrCycle.Enabled:= true;
end;


procedure TfrmPlcSimulate.FormShow(Sender: TObject);
begin
  Tag:= 1;
  //btnGotoAddrClick(nil);
end;

procedure TfrmPlcSimulate.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //Tag:= 102;
  //tmrCycle.Enabled:= false;

end;


procedure TfrmPlcSimulate.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  m_bStopMonitoring:= True;
  //Tag:= 101;
  //ClosePLC();
  //SetActive(0);
end;

procedure TfrmPlcSimulate.FormDestroy(Sender: TObject);
begin
  SetActive(0);
  Tag:= 103;
  m_bStopMonitoring:= True;
  tmrCycle.Enabled:= false;
  if m_csWrite <> nil then begin
    m_csWrite.Free;
    m_csWrite:= nil;
  end;

//  m_bStopMonitoring:= True;
end;

procedure TfrmPlcSimulate.AutoStartReq(nValue: Integer);
begin
  //Auto Start 정지
  AddLog(Format('Auto Start Req: %d', [nValue]));
  //Set_Bit(Memory_D1300[0], 8, nValue);
end;

procedure TfrmPlcSimulate.btnClearLog_PGClick(Sender: TObject);
begin
  mmoLog.Clear();
end;

procedure TfrmPlcSimulate.btnGotoAddrClick(Sender: TObject);
var
  nValue: Word;
  sMsg: String;
begin
  nValue:=  StrToInt( '$' + edtAddr.Text);
  if nValue mod 16 <> 0 then begin
    Application.MessageBox('주소는 16의 배수여야 합니다.', '확인', MB_OK+MB_ICONSTOP);
    Exit;
  end;
  if cboAddr.ItemIndex = 0 then begin //Bit
    if nValue > (MAX_PLC_MEMORY_SIZE*16) then begin
      sMsg:= format('주소가 범위(%d)를 넘었습니다.', [MAX_PLC_MEMORY_SIZE*16]);
      Application.MessageBox(PChar(sMsg), '확인', MB_OK+MB_ICONSTOP);
      Exit;
    end;
  end
  else begin
    if nValue > (MAX_PLC_MEMORY_SIZE) then begin
      sMsg:= format('주소가 범위(%d)를 넘었습니다.', [MAX_PLC_MEMORY_SIZE]);
      Application.MessageBox(PChar(sMsg), '확인', MB_OK+MB_ICONSTOP);
      Exit;
    end;
  end;
  m_nDisplayAddr:= nValue;
  edtAddr.Text:= IntToHex(m_nDisplayAddr, 3);
  m_nDisplayDevice:= cboAddr.ItemIndex;
  lblSelectedAddr.Caption:= cboAddr.Text + edtAddr.Text;

  Display_Memory();
end;

procedure TfrmPlcSimulate.btnGotoNextClick(Sender: TObject);

begin
  //if m_nDisplayAddr < (MAX_PLC_MEMORY_SIZE div 16)  then begin
    edtAddr.Text:= IntToHex(m_nDisplayAddr+ $10, 3);
    btnGotoAddrClick(Sender);
  //end;
end;

procedure TfrmPlcSimulate.btnGotoPrevClick(Sender: TObject);
var
  nValue: Word;
  sMsg: String;
begin
  if m_nDisplayAddr > 0  then begin
    edtAddr.Text:= IntToHex(m_nDisplayAddr- $10, 3);
    btnGotoAddrClick(Sender);
  end;
end;

procedure TfrmPlcSimulate.tmrCycleTimer(Sender: TObject);
begin
  if Tag > 100 then exit;

  UpdataPLC();
end;

procedure TfrmPlcSimulate.Init();
begin

  FillChar(Memory_B0, sizeof(Memory_B0), 0);
  FillChar(Memory_W0, sizeof(Memory_W0), 0);
  FillChar(Memory_D0, sizeof(Memory_D0), 0);
  FillChar(Memory_BPre, sizeof(Memory_BPre), 0);
  FillChar(Memory_WPre, sizeof(Memory_WPre), 0);
  FillChar(Memory_DPre, sizeof(Memory_DPre), 0);


  Init_PLCCommnad();

  cboAddr.ItemIndex:= 0;
  cboPLC_CommandList.ItemIndex:= 0;
  btnGotoAddrClick(nil);  //메모리 갱신
end;

procedure TfrmPlcSimulate.Init_PLCCommnad();
begin
  cboPLC_CommandList.Clear;
  cboPLC_CommandList.Items.Add('None');
end;

procedure TfrmPlcSimulate.btnPLCExec_CommandClick(Sender: TObject);
begin
  if cboPLC_CommandList.ItemIndex < 0 then Exit;

  case cboPLC_CommandList.ItemIndex of
    0:
      begin

      end;
  else

  end;
  Display_Memory();
end;


procedure TfrmPlcSimulate.grdPLCMemoryDblClickCell(Sender: TObject; ARow, ACol: Integer);
var
  nValue: Word;
  nAddr, nBitLoc:Integer;
begin
  //...
  if (ARow < 1) or (ACol < 1) then exit;
  if (ARow < 0) or (ACol > 19) then exit;

  if (ACol > 16) then
  begin
    //숫자 입력
    edtWriteAddr.Text:= grdPLCMemory.Cells[0, ARow];
    edtWriteValue.Text:= grdPLCMemory.Cells[19, ARow].Substring(0, 4);
    exit;
  end;

  //비트 처리
  nValue:= grdPLCMemory.Ints[ACol, ARow];
  if nValue = 0 then
    nValue:= 1
  else
    nValue:= 0;

  m_csWrite.Enter;
  case m_nDisplayDevice of
    0: begin
      nAddr:= (m_nDisplayAddr div 16) + (ARow-1);
      nBitLoc:= ACol-1;
      Set_Bit(Memory_B0[nAddr], nBitLoc, nValue);
      AddLog(format('Write Bit: Addr=%x, nBitLoc=%x, Value=%x', [nAddr, nBitLoc, nValue]));
    end;
  else begin
    Set_Bit(Memory_W0[m_nDisplayAddr + ARow-1], ACol-1, nValue);
    AddLog(format('Write Bit: Addr=%x, nBitLoc=%x, Value=%x', [m_nDisplayAddr + ARow-1, ACol-1, nValue]));
  end;
  end;
  m_csWrite.Leave;

  Display_Memory();
end;

procedure TfrmPlcSimulate.btnWriteAddrClick(Sender: TObject);
var
  nIndex: integer;
  nValue: Word;
begin
  nIndex:= StrToIntDef('$' + edtWriteAddr.Text, 0);
//  if (nIndex < 0) or (nIndex > 9) then
//  begin
//    Application.MessageBox('Addr은 0 ~ 15 이어야 합니다.', 'Error', MB_OK + MB_ICONERROR);
//    Exit;
//  end;

  nValue:= 0;
  case rgDataType.ItemIndex of
    0: nValue:= StrToIntDef( '$' + edtWriteValue.Text, 0);
    1: nValue:= StrToIntDef(edtWriteValue.Text, 0);
    2: if Length(edtWriteValue.Text) > 1 then
      begin
        nValue:= ord(edtWriteValue.Text[1]) * 256 + ord(edtWriteValue.Text[2]);
      end else
      begin
        Application.MessageBox('ASCII 값은 2자리여야 합니다.', 'Error', MB_OK + MB_ICONERROR);
        exit;
      end;
  end;

  m_csWrite.Enter;
  case m_nDisplayDevice of
    //0: Memory_B0[m_nDisplayAddr + nIndex]:= nValue;
    0: begin
      Memory_B0[nIndex div 16]:= nValue;
      AddLog(format('Write Value: Addr=%x, Value=%x', [(nIndex div 16) * 16, nValue]));
    end;
    else begin
      Memory_W0[nIndex]:= nValue; //Memory_W0[m_nDisplayAddr + nIndex]:= nValue;
      AddLog(format('Write Value: Addr=%x, Value=%x', [nIndex, nValue]));
    end;
  end;
  m_csWrite.Leave;

  Display_Memory();
end;

function TfrmPlcSimulate.OpenPLC: Integer;
begin
  m_bOpened:= true;
  Result:= 0;
end;

procedure TfrmPlcSimulate.PulseDevice(const szDevice: String; nDelay: Integer);
var
  sDevice: String;
begin
  //급 종료 시 오류 발생 가능성 있음 - 메모리 릭(szDevice)
  if szDevice[1] <> 'B' then Exit;
  sDevice:= szDevice;
  TThread.CreateAnonymousThread(
    procedure begin
      SetDevice(sDevice, 1);
      Sleep(nDelay);
      if frmPlcSimulateActive = 0 then Exit;
      SetDevice(sDevice, 0);
    end
  ).Start;
end;

procedure TfrmPlcSimulate.SetDeviceDelay(const szDevice: String; nData, nDelay: Integer);
begin
  ///if szDevice[1] <> 'B' then Exit;
  TThread.CreateAnonymousThread(
    procedure begin
      Sleep(nDelay);
      if frmPlcSimulateActive = 0 then Exit;
      AddLog(format('SetDeviceDelay: %s=%d', [szDevice, nData]));
      SetDevice(szDevice, nData);
    end
  ).Start;
end;


procedure TfrmPlcSimulate.ConvertBlockToGlassData(var naGlassData: array of Integer; var AGlassData: TECSGlassData);
begin
  AGlassData.LOT_ID:= ConvertStrFromPLC(16, naGlassData[0]);
  AGlassData.ProcessingCode:= ConvertStrFromPLC(8, naGlassData[8]);

  CopyMemory(@AGlassData.LOTSpecificData[0], @naGlassData[12], 4*sizeof(Integer));
  AGlassData.RecipeNumber:= naGlassData[16];
  AGlassData.GlassType:= naGlassData[17];
  AGlassData.GlassCode:= naGlassData[18];
  AGlassData.GlassID:= ConvertStrFromPLC(16, naGlassData[19]);
  AGlassData.GlassJudge:= naGlassData[27];

  CopyMemory(@AGlassData.GlassSpecificData[0], @naGlassData[28], 4*sizeof(Integer));
//  CopyMemory(@AGlassData.GlassAddData[0], @naGlassData[32], 6*sizeof(Integer));
  CopyMemory(@AGlassData.PreviousUnitProcessing[0], @naGlassData[32], 8*sizeof(Integer));
  CopyMemory(@AGlassData.GlassProcessingStatus[0], @naGlassData[40], 8*sizeof(Integer));
//  CopyMemory(@AGlassData.GlassRoutingData[0], @naGlassData[45], 3*sizeof(Integer));

  AGlassData.PCZTCode:= naGlassData[64];
//  AGlassData.PCZTID:= ConvertStrFromPLC(16, naGlassData[49]);
end;

procedure TfrmPlcSimulate.ConvertGlassDataToBlock(var AGlassData: TECSGlassData; var naGlassData: array of Integer);
begin
  ConvertStrToPLC(AGlassData.LOT_ID, 16, naGlassData[0]); //문자는 Word당 2글자
  ConvertStrToPLC(AGlassData.ProcessingCode, 8, naGlassData[8]);

  CopyMemory(@naGlassData[12], @AGlassData.LOTSpecificData[0], 4*sizeof(Integer));
  naGlassData[16]:=AGlassData.RecipeNumber;
  naGlassData[17]:=AGlassData.GlassType;
  naGlassData[18]:=AGlassData.GlassCode;
  ConvertStrToPLC(AGlassData.GlassID, 16, naGlassData[19]);
  naGlassData[27]:=AGlassData.GlassJudge;

  CopyMemory(@naGlassData[28], @AGlassData.GlassSpecificData[0], 4*sizeof(Integer));
//  CopyMemory(@naGlassData[32], @AGlassData.GlassAddData[0], 6*sizeof(Integer));
  CopyMemory(@naGlassData[32], @AGlassData.PreviousUnitProcessing[0], 8*sizeof(Integer));
  CopyMemory(@naGlassData[40], @AGlassData.GlassProcessingStatus[0], 8*sizeof(Integer));
//  CopyMemory(@naGlassData[45], @AGlassData.GlassRoutingData[0], 3*sizeof(Integer));

  naGlassData[64]:=AGlassData.PCZTCode;
//  ConvertStrToPLC(AGlassData.PCZTID, 16, naGlassData[49]); //문자는 Word당 2글자
end;

function TfrmPlcSimulate.ConvertStrFromPLC(nLen: Integer; naData: array of Integer): String;
var
	i     : Integer;
  szStr  : array[0..1023] of AnsiChar;
  sRslt : String;
begin
  if nLen <= 0 then Exit('');

  FillChar(szStr, SizeOf(szStr), #0);

  for i := 0 to (nLen-1) do begin
		CopyMemory(@szStr[(i*2)], @naData[i], 2);
	end;
  sRslt   := String(System.AnsiStrings.StrPas(szStr));

  Result  := sRslt;
end;

procedure TfrmPlcSimulate.ConvertStrToPLC(sData: string; nLen: Integer;var naData: array of Integer);
var
	i     : Integer;
  szStr  : array[0..1023] of AnsiChar;
begin
  if nLen <= 0 then Exit;
  FillChar(szStr, SizeOf(szStr), #0);
  System.AnsiStrings.StrPCopy(szStr, AnsiString(sData));

  for i := 0 to (nLen div 2) do begin
		naData[i] := Ord(szStr[(i*2)]) + Ord(szStr[(i*2+1)])*256;
	end;
end;

procedure TfrmPlcSimulate.Process_APDR(nData: Integer);
begin
  if nData <> 0  then begin
    AddLog('Process_APDR');
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$0+$1, 3), 1); //APDR ACK
  end
  else begin
    AddLog('Process_APDR Off');
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$0+$1, 3), 0); //APDR ACK
  end;
end;

procedure TfrmPlcSimulate.Process_EICR(nCh, nData: Integer);
var
  lpData: Array [0..100] of Integer;
begin
  AddLog(format('Process_EICR Ch=%d, Value=%d', [nCh, nData]));

  lpData[0]:= 0;
  lpData[1]:= $3433;
  lpData[2]:= $3635;
  lpData[3]:= $3837;
  lpData[4]:= $3039;
  lpData[5]:= $4241;
  lpData[6]:= $4443;
  lpData[7]:= $4645;


  if nData <> 0  then begin
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$02+$0 + nCh, 3), 1); //Inspection Data Report Confirm #1
  end
  else begin
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$02+$0 + nCh, 3), 0); //Inspection Data Report Confirm Off
    SetDevice('W' + IntToHex(StartAddr_ECS_W+$10*$14+$0 + nCh, 3), lpData[0]);
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$02+$1 + nCh, 3), 1); //Inspection Data Confirm
  end;

 (*
  SetDevice('W' + IntToHex(StartAddr_ECS_W+$10*$14+$0 + nCh, 3), lpData[0]);
  //PulseDevice('B' + IntToHex(StartAddr_ECS+$10*$2+$0 + nCh, 3), 3000); //Inspection Data Report Confirm
  SetDevice('B' + IntToHex(StartAddr_ECS+$10*$2+$0 + nCh, 3), 1); //Inspection Data Report Confirm

  SetDevice('B' + IntToHex(StartAddr_ECS+$10*$3+$0 + nCh, 3), 1); //Inspection Data Confirm
*)
end;


procedure TfrmPlcSimulate.Process_EICR_ACK(nCh, nData: Integer);
begin
  AddLog(format('Process_EICR_ACK Ch=%d, Value=%d', [nCh, nData]));
  if nData <> 0  then begin
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$02+$1, 3), 0); //Inspection Data Confirm Off
  end
  else begin
    //SetDevice('B' + IntToHex(StartAddr_ECS+$10*$3+$0 + nCh, 3), 1); //Inspection Data Confirm
  end;

end;

procedure TfrmPlcSimulate.Process_PCHK(nCh, nData: Integer);
var
  lpData: Array [0..100] of Integer;
  GlassData: TECSGlassData;
  nRes: Integer;
begin
  if nData <> 0 then begin
    GlassData.LOT_ID:= '1234567890ABCDEF';
    GlassData.ProcessingCode:= '87654321';
    GlassData.LOTSpecificData[0]:= $3231;
    GlassData.LOTSpecificData[1]:= $3433;
    GlassData.LOTSpecificData[2]:= $4241;
    GlassData.LOTSpecificData[3]:= $4443;
    GlassData.RecipeNumber:= $3939;
    GlassData.GlassType:= $3838; //1; //비트 설정 함수 추가 필요 4.1.6
    GlassData.GlassCode:= $3737;//$24;
    GlassData.GlassID:= 'GlassID16Digits ';
    GlassData.GlassJudge:= Ord('P') + $2000;
    GlassData.GlassSpecificData[0]:= $3131;
    GlassData.GlassSpecificData[1]:= $3131;
    GlassData.GlassSpecificData[2]:= $3131;
    GlassData.GlassSpecificData[3]:= $3131;
//    GlassData.GlassAddData[0]:= $3232;
//    GlassData.GlassAddData[1]:= $3232;
//    GlassData.GlassAddData[2]:= $3232;
//    GlassData.GlassAddData[3]:= $3232;
//    GlassData.GlassAddData[4]:= $3232;
//    GlassData.GlassAddData[5]:= $3232;
    GlassData.PreviousUnitProcessing[0]:= $3333;
    GlassData.PreviousUnitProcessing[1]:= $3333;
    GlassData.PreviousUnitProcessing[2]:= $3333;
    GlassData.PreviousUnitProcessing[3]:= $3333;
    GlassData.PreviousUnitProcessing[4]:= $3333;
    GlassData.PreviousUnitProcessing[5]:= $3333;
    GlassData.PreviousUnitProcessing[6]:= $3333;
    GlassData.PreviousUnitProcessing[7]:= $3333;
    GlassData.GlassProcessingStatus[0]:= $3434;
    GlassData.GlassProcessingStatus[1]:= $3434;
    GlassData.GlassProcessingStatus[2]:= $3434;
    GlassData.GlassProcessingStatus[3]:= $3434;
    GlassData.GlassProcessingStatus[4]:= $3434;
    GlassData.GlassProcessingStatus[5]:= $3434;
    GlassData.GlassProcessingStatus[6]:= $3434;
    GlassData.GlassProcessingStatus[7]:= $3434;

//    GlassData.GlassRoutingData[0]:= $3535;
//    GlassData.GlassRoutingData[1]:= $3535;
//    GlassData.GlassRoutingData[2]:= $3535;

    ConvertGlassDataToBlock(GlassData, lpData[0]);
    WriteDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$00+$0, 3), 64, lpData[0]); //Glass Data

    lpData[0]:= $3231;
    lpData[1]:= $3433;
    lpData[2]:= $3635;
    lpData[3]:= $3837;
    lpData[4]:= $3039;
    lpData[5]:= $4241;
    lpData[6]:= $4443;
    lpData[7]:= $4645;
    lpData[8]:= $4241;
    lpData[9]:= $4443;
    lpData[10]:= $4645;
    lpData[11]:= $4443;

    WriteDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$04+$0, 3), 12, lpData[0]); ////ECS LCM_ID

    lpData[0]:= 0;
    SetDevice('W' + IntToHex(StartAddr_ECS_W+$10*$04+$F, 3), lpData[0]); //BCR #1 Read Report Confirm Data
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$03+$0, 3), 1); //BCR RD Data Report Confirm
  end
  else begin
    SetDevice('B' + IntToHex(StartAddr_ECS+$10*$03+$0, 3), 0); //BCR RD Data Report Confirm
  end;

  //PulseDevice('B' + IntToHex(StartAddr_ECS+$10*$0+$3 + nCh, 3), 3000); //BCR RD Data Report Confirm
end;

procedure TfrmPlcSimulate.Process_UCHK(nData: Integer);
var
  lpData: Array [0..100] of Integer;
  szDevice: String;
begin
  AddLog('Process_UCHK ' + IntToStr(nData));
  if nData <> 0 then begin
    lpData[0]:= 0; //OK = 0, NG <> 0
    SetDevice('W' + IntToHex(StartAddr_ECS_W+$10*$14+$F, 3), lpData[0]); //POCB #1 User ID Confirm
    //SetDevice('B' + IntToHex(StartAddr_ECS+$10*$1+$1, 3), 1); //User ID Manual Report Confirm
    PulseDevice('B' + IntToHex(StartAddr_ECS+$10*$1+$1, 3), 3000); //User ID Manual Report Confirm
  end
  else begin
    //SetDevice('B' + IntToHex(StartAddr_ECS+$10*$1+$1, 3), 0); //User ID Manual Report Confirm Off
  end;


end;

procedure TfrmPlcSimulate.Process_ZSET(nCh: Integer);
var
  lpData: Array [0..100] of Integer;
  szDevice: String;
begin
  AddLog('Process_ZSET');
  lpData[0]:= 0; //OK = 0, NG <> 0

  SetDevice('W' + IntToHex(StartAddr_ECS_W+$10*$A+$D + (nCh*$180), 3), lpData[0]); //Bonding Data ACK

  //SetDevice('B' + IntToHex(StartAddr_ECS+$10*$09+$7, 3), 1); //Bonding Report Confirm
  PulseDevice('B' + IntToHex(StartAddr_ECS+$10*$02+$0 + nCh, 3), 3000); //Bonding Report Confirm
end;


procedure TfrmPlcSimulate.Process_Load_GlassData(nCh: Integer);
var
  GlassData: TECSGlassData;
  naGlassData: array [0..64]of Integer;
  nRes: Integer;
begin
  GlassData.LOT_ID:= '1234567890ABCDEF';
  GlassData.ProcessingCode:= '87654321';
  GlassData.LOTSpecificData[0]:= $3231;
  GlassData.LOTSpecificData[1]:= $3433;
  GlassData.LOTSpecificData[2]:= $4241;
  GlassData.LOTSpecificData[3]:= $4443;
  GlassData.RecipeNumber:= $3939;
  GlassData.GlassType:= $3838; //1; //비트 설정 함수 추가 필요 4.1.6
  GlassData.GlassCode:= $3737;//$24;
  GlassData.GlassID:= 'GlassID16Digits ';
  GlassData.GlassJudge:= Ord('P') + $2000;
  GlassData.GlassSpecificData[0]:= $3131;
  GlassData.GlassSpecificData[1]:= $3131;
  GlassData.GlassSpecificData[2]:= $3131;
  GlassData.GlassSpecificData[3]:= $3131;
//  GlassData.GlassAddData[0]:= $3232;
//  GlassData.GlassAddData[1]:= $3232;
//  GlassData.GlassAddData[2]:= $3232;
//  GlassData.GlassAddData[3]:= $3232;
//  GlassData.GlassAddData[4]:= $3232;
//  GlassData.GlassAddData[5]:= $3232;
  GlassData.PreviousUnitProcessing[0]:= $3333;
  GlassData.PreviousUnitProcessing[1]:= $3333;
  GlassData.PreviousUnitProcessing[2]:= $3333;
  GlassData.PreviousUnitProcessing[3]:= $3333;
  GlassData.PreviousUnitProcessing[4]:= $3333;
  GlassData.PreviousUnitProcessing[5]:= $3333;
  GlassData.PreviousUnitProcessing[6]:= $3333;
  GlassData.PreviousUnitProcessing[7]:= $3333;
  GlassData.GlassProcessingStatus[0]:= $3434;
  GlassData.GlassProcessingStatus[1]:= $3434;
  GlassData.GlassProcessingStatus[2]:= $3434;
  GlassData.GlassProcessingStatus[3]:= $3434;
  GlassData.GlassProcessingStatus[4]:= $3434;
  GlassData.GlassProcessingStatus[5]:= $3434;
  GlassData.GlassProcessingStatus[6]:= $3434;
  GlassData.GlassProcessingStatus[7]:= $3434;

//  GlassData.GlassRoutingData[0]:= $3535;
//  GlassData.GlassRoutingData[1]:= $3535;
//  GlassData.GlassRoutingData[2]:= $3535;

  ConvertGlassDataToBlock(GlassData, naGlassData[0]);

  AddLog('Process_Load_GlassData: ' + IntToStr(nCh));

  //WriteDeviceBlock('W' + IntToHex(StartAddr_ROBOT+$10*$30+$1, 3), 1, lpData[0]); //Read Glass Data Report
  WriteDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W,      3), 64, naGlassData[0]); //Load #1 Glass Data

  GlassData.LOT_ID:= 'ABCDEF1234567890';
  ConvertGlassDataToBlock(GlassData, naGlassData[0]);
  WriteDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$40, 3), 64, naGlassData[0]); //Load #2 Glass Data

  //SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$01+$1 + (nCh * $20), 3), 1); //Glass Data Report
  SetDeviceDelay('B' + IntToHex(StartAddr_ROBOT+$10*$00+$1 + (nCh * $20), 3), 1, 300); //Glass Data Report

end;

procedure TfrmPlcSimulate.Process_Load_Enable(nCh: Integer);
var
  lpData: Array [0..100] of Integer;
begin
  AddLog('Process_Load_Enable: ' + IntToStr(nCh));
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0 + (nCh * $20), 3), 0); ////Load Noninterference
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$2 + (nCh * $20), 3), 1); //Robot Busy
  //Sleep(500);

  //SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$01+$3 + (nCh * $20), 3), 1); //Load Complete
  SetDeviceDelay('B' + IntToHex(StartAddr_ROBOT+$10*$00+$3 + (nCh * $20), 3), 1, 300); //Load Complete
end;

procedure TfrmPlcSimulate.Process_LinkTest;
begin
  AddLog('Process_LinkTest');
  //Sleep(100);
  //SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0, 3), 1); //Link Test Response
  PulseDevice('B' + IntToHex(StartAddr_ECS+$10*$00+$0, 3), 3000); //Link Test Response

end;

procedure TfrmPlcSimulate.Process_Load_CompleteConfirm(nCh: Integer);
var
  lpData: Array [0..100] of Integer;
begin
  AddLog('Process_Load_CompleteConfirm: ' + IntToStr(nCh));
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$3 + (nCh * $20), 3), 0); //Load Complete off
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$1 + (nCh * $20), 3), 0); //Glass Data Report off
  Sleep(1000);
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0 + (nCh * $20), 3), 1); //load Noninterference
  //Sleep(300);
  SetDeviceDelay('B' + IntToHex(StartAddr_ROBOT+$10*$00+$2 + (nCh * $20), 3), 0, 3000); //Robot Busy off

  if chkAutoStart.Checked and (nCh = 1) then begin
    //자동 시작 체크 되었을 경우
    Sleep(3000);
    SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$D + (nCh * $20), 3), 1); //Inspection Start
  end;

end;


procedure TfrmPlcSimulate.Process_Unload_Enable(nCh: Integer);
var
  lpData: Array [0..100] of Integer;
begin
  AddLog('Process_Unload_Enable: ' + IntToStr(nCh));

  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$01+$0 + (nCh * $20), 3), 0); ////Unload Noninterference
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$01+$2 + (nCh * $20), 3), 1); //Robot Busy
//  Sleep(300);
  //SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$3 + (nCh * $20), 3), 1); //Unload Complete
  SetDeviceDelay('B' + IntToHex(StartAddr_ROBOT+$10*$01+$3 + (nCh * $20), 3), 1, 300); //Unload Complete

end;

procedure TfrmPlcSimulate.Process_Unload_CompleteConfirm(nCh: Integer);
var
  lpData: Array [0..100] of Integer;
begin
  AddLog('Process_Unload_CompleteConfirm: ' + IntToStr(nCh));
  Sleep(2000);
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$01+$3 + (nCh * $20), 3), 0); //Unload Complete Off
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$01+$0 + (nCh * $20), 3), 1); //Unload Noninterference
  //Sleep(300);
  SetDeviceDelay('B' + IntToHex(StartAddr_ROBOT+$10*$01+$2 + (nCh * $20), 3), 0, 500); //Robot Busy


end;

procedure TfrmPlcSimulate.Process_ReadyToStart(nCh: Integer);
begin
  //SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$3+$D + (nCh * $20), 3), 0); //Inspection Start
  AddLog('Process_ReadyToStart: ' + IntToStr(nCh));
  if nCh = 1 then begin
    //SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$1+$D , 3), 1); //Inspection Start
    SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$3+$D , 3), 1); //Inspection Start
  end;
end;

procedure TfrmPlcSimulate.Process_InspectionStart_Confirm(nCh: Integer);
begin
  AddLog('Process_InspectionStart_Confirm: ' + IntToStr(nCh));
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$1+$D, 3), 0); //Inspection Start Off
  SetDevice('B' + IntToHex(StartAddr_ROBOT+$10*$3+$D, 3), 0); //Inspection Start Off
end;

function TfrmPlcSimulate.ClosePLC: Integer;
begin
  m_bOpened:= false;
  Result:= 0;
end;

procedure TfrmPlcSimulate.SetActive(nValue: integer);
begin
  //활성화 여부 : 주로 종료 시 AddLog 사용 문제 방지
  frmPlcSimulateActive:= nValue;
  if frmPlcSimulateActive = 0 then Tag:= 101;

end;


function TfrmPlcSimulate.GetDeviceMemory(const szDevice: String; out pwMemory: PWORD): Integer;
var
  nAddr: Word;
  sType: string;
begin
  //sType:= szDevice.Substring(0,1);
  nAddr:= StrToIntDef('$' + Copy(szDevice,2, 10), 0);

  sType:= UpperCase(szDevice[1]);
  Result:= nAddr;
  if sType = 'B' then begin
    if nAddr mod 16 <> 0 then Exit(-1); //B주소는 16 배수여야 한다(Block).
    nAddr:= nAddr div 16;
    if nAddr > MAX_PLC_MEMORY_SIZE then Exit(-255);
    pwMemory:= @Memory_B0[nAddr];
  end
  else if sType = 'W' then begin
    if nAddr > MAX_PLC_MEMORY_SIZE then Exit(-255);
    pwMemory:= @Memory_W0[nAddr];
  end
  else if sType = 'D' then begin
    if nAddr > MAX_PLC_MEMORY_SIZE then Exit(-255);
    pwMemory:= @Memory_D0[nAddr];
  end
  else begin
    Result:= -1;
    Exit;
  end;
end;

function TfrmPlcSimulate.GetDevice(const szDevice: WideString; out lplData: Integer): Integer;
var
  pw: PWORD;
  nAddr, nBitLoc:Integer;
  sType: string;
begin
  if Tag > 100 then exit(1);

  Result:= 0;
  if not m_bOpened then exit(1); //닫혀 있는 상태이면 실패

  sType:= UpperCase(szDevice[1]);

  if sType = 'B' then begin
    nAddr:= StrToIntDef('$' + Copy(szDevice,2, 10), 0);
    nBitLoc:= nAddr mod 16;
    nAddr:= nAddr div 16;
    lplData:= Get_Bit(Memory_B0[nAddr], nBitLoc);
  end
  else begin
  //else if sType = 'W' then begin
    GetDeviceMemory(szDevice, pw);
    lplData:= pw^;
  end
end;

function TfrmPlcSimulate.SetDevice(const szDevice: WideString; nData: Integer): Integer;
var
  pw: PWORD;
  nAddr, nBitLoc: Integer;
  sType: string;
begin
  if Tag > 100 then exit(1);
  Result:= 0;
  if not m_bOpened then exit(1); //닫혀 있는 상태이면 실패
  //AddLog(format('SetDevice: %s=%d', [szDevice, nData]));
  sType:= UpperCase(szDevice[1]);
  if sType = 'B' then begin
    nAddr:= StrToIntDef('$' + Copy(szDevice,2, 10), 0);
    nBitLoc:= nAddr mod 16;
    nAddr:= nAddr div 16;
    if nAddr > MAX_PLC_MEMORY_SIZE then begin
      //주소가 너무 큼
      Result:= 255;
      Exit;
    end;
    Set_Bit(Memory_B0[nAddr], nBitLoc, nData);
    (*
    TThread.CreateAnonymousThread(
      procedure begin
        Process_SetDevice(szDevice, nData); //Bit 쓰기 시 이벤트 처리
      end
    ).Start;
    *)
  end
  else begin
  //else if sType = 'W' then begin
    if GetDeviceMemory(szDevice, pw) < 0 then Exit(1);
    pw^:= nData;
  end
end;

function TfrmPlcSimulate.ReadDeviceBlock(const szDevice: String; lSize: Integer; out lplData: Integer): integer;
var
  pw: PWORD;
  pi: PInteger;
  i: integer;
  nAddr, nBitLoc: Integer;
begin
  if Tag > 100 then exit(1);
  if not m_bOpened then exit(1); //닫혀 있는 상태이면 실패

  if GetDeviceMemory(szDevice, pw) < 0 then Exit(1);

  //CopyMemory(@lplData, pw, lSize); //Word Data대상이므로 Integer에 복사하면 안됨,
  pi:= @lplData;
  for i := 0 to lSize-1 do
  begin
    pi^:= pw^;
    inc(pw);
    inc(pi);
  end;

  //AddLog(Format('ReadDeviceBlock: %s, size:%04d => %4x(%d)', [szDevice, lSize, lplData, lplData]));

  Result:= 0;
end;

function TfrmPlcSimulate.WriteDeviceBlock(const szDevice: String; lSize: Integer; var lplData: Integer): integer;
var
  pw: PWORD;
  pi: PInteger;
  sType: string;
  nAddr: Word;
  nBitLoc: Word;
  nValue: Word;
  i, k, nCount : integer;
  PreD1200: array [0..2] of Word;
  PreR1400: array [0..2] of Word;
  PreR1410: array [0..2] of Word;
  bitValue, bitValue2: Word;
begin
  if Tag > 100 then exit(1);
  if not m_bOpened then exit(1); //닫혀 있는 상태이면 실패

  sType:= UpperCase(szDevice.Substring(0,1));
  nAddr:= GetDeviceMemory(szDevice, pw);
  if nAddr < 0 then  Exit(1);

  AddLog(format('WriteDeviceBlock: %s, size=%d', [szDevice, lSize]));

  //제어 처리 부분이전 데이터 저장
  if sType = 'B' then begin
    CopyMemory(@Memory_BPre, @Memory_B0, sizeof(Word) * MAX_PLC_MEMORY_SIZE);
    //Block 쓰기는 16배수 주소만 가능
    nAddr:= StrToIntDef('$' + Copy(szDevice,2, 10), 0);
    nAddr:= nAddr div 16;
    nCount:= lSize div 16;
    pi:= @lplData;
    for i := 0 to nCount-1 do begin
      for k := 0 to 15 do begin
        nValue:=  pi^;
        Set_Bit(Memory_B0[nAddr+i], k, nValue);
        inc(pi);
      end;
    end;
    Exit(0);
  end
  else if sType = 'W' then begin
    CopyMemory(@Memory_WPre, @Memory_W0, sizeof(Word) * MAX_PLC_MEMORY_SIZE);
  end;

  m_csWrite.Enter;
  pi:= @lplData;
  for i := 0 to lSize-1 do
  begin
    pw^:= pi^;
    inc(pw);
    inc(pi);
  end;
  m_csWrite.Leave;

  //AddLog(Format('WriteDeviceBlock: %s, size:%04d => %4x(%d)', [szDevice, lSize, lplData, lplData]));
  Result:= 0;
  //UpdataPLC();

  //////////////////////////////////////////////////////////////////////////////
  // 쓰기 시 변경된 데이터  인지 처리
  if nAddr < 127 then begin

  end;

end;


function TfrmPlcSimulate.GetClockData(out lpsYear, lpsMonth, lpsDay,
  lpsDayOfWeek, lpsHour, lpsMinute, lpsSecond: Smallint): Integer;
var
  Cur: TDateTime;
  wYear, wMonth, wDay, wWeek, wHour, wMinute, wSecond, wMS: Word;
begin
  Cur:= Now;
  DecodeTime(Cur, wHour, wMinute, wSecond, wMS);
  DecodeDateFully(Cur, wYear, wMonth, wDay, wWeek);
  //DecodeDate(Cur, wYear, wMonth, wDay);
  //wWeek:= DayOfWeek(Cur);
  lpsYear:= wYear;
  lpsMonth:= wMonth;
  lpsDay:= wDay;
  lpsDayOfWeek:= wWeek-1;
  lpsHour:= wHour;
  lpsMinute:= wMinute;
  lpsSecond:= wSecond;
  Result:= 0;
end;


function TfrmPlcSimulate.Get_Bit(var nData: Word; nLoc: Word): Word;
begin
  Result := (nData shr nLoc) and $01;
end;

function TfrmPlcSimulate.Set_Bit(var nData: Word; nLoc, Value: Word): Word;
begin
  if Value and $01 = 0 then
  begin
    nData := (nData and not (1 shl nLoc));
  end else
  begin
    nData := nData or (1 shl nLoc);
  end;
  Result:= nData;
end;

function TfrmPlcSimulate.Set_Bit_DWord(var nData: DWord; nLoc, Value: DWord): DWord;
begin
  if Value and $01 = 0 then
  begin
    nData := (nData and not (1 shl nLoc));
  end else
  begin
    nData := nData or (1 shl nLoc);
  end;
  Result:= nData;
end;

procedure TfrmPlcSimulate.Thread_Monitoring;
var
  i, k: Integer;
  nAddr, nBitLoc, nValue: Integer;
  bChanged: Boolean;
begin

  while not m_bStopMonitoring do begin
    bChanged:= False;
    if chkPauseProcess.Checked then begin
      WaitForSingleObject(0, 1000);
      Continue;
    end;

    for i := 0 to 15 do begin
      if m_bStopMonitoring then Exit;


      nAddr:= (StartAddr_EQP div 16)+i;
      if Memory_B0[nAddr] <> Memory_BPre[nAddr] then begin
        for k := 0 to 15 do begin
          if m_bStopMonitoring then Exit;

          nBitLoc:= k;
          nValue:= Get_Bit(Memory_B0[nAddr], nBitLoc);
          if nValue <> Get_Bit(Memory_BPre[nAddr], nBitLoc) then begin
            Process_Monitoring_EQP(nAddr*$10 + nBitLoc, nValue);
          end;
        end;
        bChanged:= True;
      end; //if Memory_B0[nAddr] <> Memory_BPre[nAddr] then begin
    end; //for i := 0 to 15 do begin

    nAddr:= StartAddr_EQP div 16;
    if bChanged then begin
      CopyMemory(@Memory_BPre[nAddr], @Memory_B0[nAddr], 32);
    end;
    WaitForSingleObject(0, 200);
  end; //while m_bStopMonitoring do begin
end;

procedure TfrmPlcSimulate.Process_Monitoring_EQP(nAddr, nData: Integer);
var
  i: Integer;
begin
  if nAddr = (StartAddr_EQP + $10*$03+$0) then begin
    //Link Test
    if nData <> 0 then Process_LinkTest;
  end

  else if nAddr = (StartAddr_EQP + $10*$07+$F) then begin
    //UCHK
    Process_UCHK(nData);
  end

  else if nAddr = (StartAddr_EQP + $10*$06+$0) then begin
    //PCHK(BCR Report)
    Process_PCHK(0, nData);
  end
  else if nAddr = (StartAddr_EQP + $10*$06+$1) then begin
    //PCHK(BCR Report)
    Process_PCHK(1, nData);
  end
  else if nAddr = (StartAddr_EQP + $10*$06+$2) then begin
    //PCHK(BCR Report)
    Process_PCHK(2, nData);
  end
  else if nAddr = (StartAddr_EQP + $10*$06+$3) then begin
    //PCHK(BCR Report)
    Process_PCHK(3, nData);
  end

  else if nAddr = (StartAddr_EQP + $10*$6+$4) then begin
    //EICR
    Process_EICR(0, nData);
  end
   else if nAddr = (StartAddr_EQP + $10*$6+$4+1) then begin
    //EICR
    Process_EICR(1, nData);
  end
   else if nAddr = (StartAddr_EQP + $10*$6+$4+2) then begin
    //EICR
    Process_EICR(2, nData);
  end
   else if nAddr = (StartAddr_EQP + $10*$6+$4+3) then begin
    //EICR
    Process_EICR(3, nData);
  end

  else if nAddr = (StartAddr_EQP + $10*$03+$1) then begin
    //APDR
    Process_APDR(nData);
  end

  else if nAddr = (StartAddr_EQP + $10*$6+$8) then begin
    Process_EICR_ACK(0, nData);
  end
   else if nAddr = (StartAddr_EQP + $10*$6+$8+1) then begin
    Process_EICR_ACK(1, nData);
  end
   else if nAddr = (StartAddr_EQP + $10*$6+$8+2) then begin
    Process_EICR_ACK(2, nData);
  end
   else if nAddr = (StartAddr_EQP + $10*$6+$8+3) then begin
    Process_EICR_ACK(3, nData);
  end

  ////////////////////////////////////////////////////////////
  else if nAddr = (StartAddr_EQP + $10*$7+$A) then begin
    //ZSET(Bonding Report)
    if nData <> 0 then Process_ZSET(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$7+$B) then begin
    //ZSET(Bonding Report)
    if nData <> 0 then Process_ZSET(1);
  end

  else if nAddr = (StartAddr_EQP + $10*$0C+$0) then begin
    //Robot - Load Enable - 1
    if nData <> 0 then Process_Load_Enable(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$0E+$0) then begin
    //Robot - Load Enable - 2
    if nData <> 0 then Process_Load_Enable(1);
  end
  else if nAddr = (StartAddr_EQP + $10*$0C+$1) then begin
    //Robot - Glass Data Requst - 1
    if nData <> 0 then Process_Load_GlassData(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$0E+$1) then begin
    //Robot - Glass Data Requst - 2
    if nData <> 0 then Process_Load_GlassData(1);
  end
  else if nAddr = (StartAddr_EQP + $10*$0C+$6) then begin
    //Robot - Complete Confirm
    if nData <> 0 then Process_Load_CompleteConfirm(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$0E+$6) then begin
    //Robot - Complete Confirm
    if nData <> 0 then Process_Load_CompleteConfirm(1);
  end

  else if nAddr = (StartAddr_EQP + $10*$0D+$0) then begin
    //Robot - UnLoad Enable - 1
    if nData <> 0 then Process_Unload_Enable(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$0F+$0) then begin
    //Robot - UnLoad Enable - 2
    if nData <> 0 then Process_Unload_Enable(1);
  end

  else if nAddr = (StartAddr_EQP + $10*$0D+$6) then begin
    //Robot - Complete Confirm
    if nData <> 0 then Process_Unload_CompleteConfirm(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$0F+$6) then begin
    //Robot - Complete Confirm
    if nData <> 0 then Process_Unload_CompleteConfirm(1);
  end

  else if nAddr = (StartAddr_EQP + $10*$0C+$C) then begin
    //Robot - Ready To Start
    //if nData <> 0 then Process_ReadyToStart(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$0E+$C) then begin
    //Robot - Ready To Start
    if nData <> 0 then Process_ReadyToStart(1);
  end

  else if nAddr = (StartAddr_EQP + $10*$0C+$D) then begin
    //Robot - Complete Confirm
    if nData <> 0 then Process_InspectionStart_Confirm(0);
  end
  else if nAddr = (StartAddr_EQP + $10*$0E+$D) then begin
    //Robot - Complete Confirm
    if nData <> 0 then Process_InspectionStart_Confirm(0);
  end
  ;
end;

procedure TfrmPlcSimulate.grdPLCMemoryGetCellColor(Sender: TObject; ARow,
  ACol: Integer; AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
begin
  if (ACol < 1) or (ACol > 16) then Exit;
  if ARow < 1 then Exit;

  if grdPLCMemory.Cells[ACol, ARow] = '0' then
  begin
    ABrush.Color:= clWhite;
  end else
  begin
    ABrush.Color:= clLime;
  end;
end;

procedure TfrmPlcSimulate.UpdataPLC;
begin
  Display_Memory();
end;

procedure TfrmPlcSimulate.Delay(nTickTime: integer);
  var
  preTick: Cardinal;
begin
  preTick := GetTickCount();
  repeat
    Application.ProcessMessages;
  Until integer(GetTickCount() - preTick) >= nTickTime;
end;

procedure TfrmPlcSimulate.Display_Memory();
var
  i, k: integer;
  value: Word;
  pw: PWord;
  nAddr: Word;
begin
  if Tag > 100 then exit;

  case m_nDisplayDevice of
    0: pw:= @Memory_B0[m_nDisplayAddr div 16];
    1: pw:= @Memory_W0[m_nDisplayAddr];
  else
    Exit;
  end;

  //grdPLCMemory.BeginUpdate;
  for i := 0 to 15 do
  begin
    case m_nDisplayDevice of
      0: grdPLCMemory.Cells[0, i+1]:= IntToHex(m_nDisplayAddr + i*16, 1); //Bit
    else grdPLCMemory.Cells[0, i+1]:= IntToHex(m_nDisplayAddr + i, 1); //Word
    end;
    //grdPLCMemory.Cells[0, i+1]:= IntToHex(i, 1);
    value:= pw^;
    for k := 0 to 15 do
    begin
       if Tag > 100 then exit;
       grdPLCMemory.Ints[k+1, i+1] :=  Get_Bit(value, k);
    end;
    grdPLCMemory.Cells[17, i+1]:= Format('%02s (%d)', [IntToHex(Lo(value), 2), Lo(value)]);
    grdPLCMemory.Cells[18, i+1]:= Format('%02s (%d)', [IntToHex(Hi(value), 2), Hi(value)]);
    grdPLCMemory.Cells[19, i+1]:= Format('%04s (%d)', [IntToHex(value, 4), value]);
    inc(pw);
  end;
  //grdPLCMemory.EndUpdate;
end;


function TfrmPlcSimulate.ReadBuffer(lStartIO, lAddress, lSize: Integer; out lpsData: Smallint): Integer;
begin
  //if Tag > 100 then exit(1);
  if not m_bOpened then exit(1); //닫혀 있는 상태이면 실패

  Result:= 0;

end;

function TfrmPlcSimulate.WriteBuffer(lStartIO, lAddress, lSize: Integer; var lpsData: Smallint): Integer;
begin
  //if Tag > 100 then exit(1);
  if not m_bOpened then exit(1); //닫혀 있는 상태이면 실패

  Result:= 0;
end;

end.
