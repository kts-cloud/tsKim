unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IniFiles,
  CommonClass, CommPLC_ECS, Vcl.ExtCtrls;

type
  TfrmMain = class(TForm)
    memoLog: TMemo;
    tmrReadValue: TTimer;
    tmrInit: TTimer;
    Panel1: TPanel;
    btnShowWindow: TButton;
    GroupBox1: TGroupBox;
    Label4: TLabel;
    edtDeviceString: TEdit;
    edtCountReadString: TEdit;
    btnGetValues: TButton;
    edtWriteString: TEdit;
    btnSetValues: TButton;
    btnGetDateString: TButton;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    edtDevice: TEdit;
    Label3: TLabel;
    edtBitLoc: TEdit;
    Label2: TLabel;
    edtWriteValue: TEdit;
    btnReadBlock: TButton;
    btnReadBit: TButton;
    btnWriteBlock: TButton;
    btnWriteBit: TButton;
    btnReadClockData: TButton;
    Label5: TLabel;
    Label6: TLabel;
    btnReadDevice: TButton;
    btnWriteDevice: TButton;
    btnWriteBit_Thread: TButton;
    GroupBox3: TGroupBox;
    btnECS_PCHK: TButton;
    btnECS_EICR: TButton;
    btnECS_UCHK: TButton;
    btnECS_APDR: TButton;
    GroupBox4: TGroupBox;
    btnRobot_Unload: TButton;
    btnRobot_Load: TButton;
    edtUserID: TEdit;
    edtSerial: TEdit;
    edtResult: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    edtZigID: TEdit;
    Label11: TLabel;
    edtErrorCode: TEdit;
    btnGlassData: TButton;
    GroupBox5: TGroupBox;
    Label14: TLabel;
    edtAlarmType: TEdit;
    Label15: TLabel;
    edtAlarmValue: TEdit;
    btnAlarm: TButton;
    Label16: TLabel;
    edtAlarmCode: TEdit;
    GroupBox6: TGroupBox;
    edtUnitStatusValue: TEdit;
    btnUnitStatus: TButton;
    Label12: TLabel;
    Label13: TLabel;
    cboUnitStatus: TComboBox;
    btnECS_ZSET: TButton;
    lblStartAddrEQP: TLabel;
    lblStartAddrEQP_W: TLabel;
    lblStartAddrROBOT: TLabel;
    lblStartAddrROBOT_W: TLabel;
    lblStartAddrECS: TLabel;
    lblStartAddrECS_W: TLabel;
    edtStartAddrEQP: TEdit;
    edtStartAddrEQP_W: TEdit;
    edtStartAddrRobot_W: TEdit;
    edtStartAddrRobot: TEdit;
    edtStartAddrECS_W: TEdit;
    edtStartAddrECS: TEdit;
    btnModelChange: TButton;
    btnGlassPosition: TButton;
    Label17: TLabel;
    edtParam1: TEdit;
    Label18: TLabel;
    edtParam2: TEdit;
    Label19: TLabel;
    edtParam3: TEdit;
    btnRobot_Exchange: TButton;
    btnLostGlass: TButton;
    btnGlassExist: TButton;
    btnScrapGlass: TButton;
    btnShowStatus: TButton;
    btnClearLog: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure WMUser(var Msg : TMessage); message WM_USER + 1;
    procedure btnShowWindowClick(Sender: TObject);
    procedure btnGetValuesClick(Sender: TObject);
    procedure tmrReadValueTimer(Sender: TObject);
    procedure tmrInitTimer(Sender: TObject);
    procedure btnSetValuesClick(Sender: TObject);
    procedure btnWriteBlockClick(Sender: TObject);
    procedure btnReadBlockClick(Sender: TObject);
    procedure btnGetDateStringClick(Sender: TObject);
    procedure btnReadClockDataClick(Sender: TObject);
    procedure btnWriteBitClick(Sender: TObject);
    procedure btnReadBitClick(Sender: TObject);
    procedure btnReadDeviceClick(Sender: TObject);
    procedure btnWriteDeviceClick(Sender: TObject);
    procedure btnWriteBit_ThreadClick(Sender: TObject);
    procedure btnECS_UCHKClick(Sender: TObject);
    procedure btnECS_PCHKClick(Sender: TObject);
    procedure btnECS_EICRClick(Sender: TObject);
    procedure btnECS_APDRClick(Sender: TObject);
    procedure btnRobot_LoadClick(Sender: TObject);
    procedure btnRobot_UnloadClick(Sender: TObject);
    procedure btnGlassDataClick(Sender: TObject);
    procedure btnUnitStatusClick(Sender: TObject);
    procedure btnAlarmClick(Sender: TObject);
    procedure btnECS_ZSETClick(Sender: TObject);
    procedure btnModelChangeClick(Sender: TObject);
    procedure btnGlassPositionClick(Sender: TObject);
    procedure btnRobot_ExchangeClick(Sender: TObject);
    procedure btnLostGlassClick(Sender: TObject);
    procedure btnGlassExistClick(Sender: TObject);
    procedure btnScrapGlassClick(Sender: TObject);
    procedure btnShowStatusClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    { Private declarations }
    m_nStationNo: Integer;
    m_nEQP_ID: Integer;
    m_nEQP_START: Integer;
    /// <summary> PLC 시작 주소- EQP</summary>
    m_nStartAddr_EQP: Integer;
    /// <summary> PLC 시작 주소- ECS</summary>
    m_nStartAddr_ECS: Integer;
    /// <summary> PLC 시작 주소- ROBOT</summary>
    m_nStartAddr_ROBOT: Integer;
    /// <summary> PLC 시작 주소Word- EQP</summary>
    m_nStartAddr_EQP_W: Integer;
    /// <summary> PLC 시작 주소Word- ROBOT</summary>
    m_nStartAddr_ROBOT_W: Integer;
    /// <summary> PLC 시작 주소Word- ECS</summary>
    m_nStartAddr_ECS_W: Integer;
    m_bUseSimulation: Boolean;
    procedure AddLog(sLog: String);
    procedure UpdatePLC;
    procedure ReadIni;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation
uses ECSStatusForm;

{$R *.dfm}

procedure TfrmMain.AddLog(sLog: String);
begin
  if memoLog.Lines.Count > 100 then begin
     memoLog.Lines.Clear;
  end;
  memoLog.Lines.Add(FormatDateTime('HH:NN:SS.ZZZ => ', Now) +  sLog);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Common:= TCommon.Create;

  ReadIni;

  tmrInit.Interval:= 200;
  tmrInit.Enabled:= True;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  //
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  tmrReadValue.Enabled:= False;

  if g_CommPLC <> nil then begin
    //g_CommPLC.Terminate;
    //g_CommPLC.WaitFor;
    g_CommPLC.Free;
    g_CommPLC:= nil;
  end;

  Common.Free;
end;

procedure TfrmMain.ReadIni;
var
  ini: TIniFile;
  sValue: String;
begin
  ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'PLC.ini');
  try
    m_nStationNo:= ini.ReadInteger('Addr', 'StationNo', 1);
    m_nEQP_ID:= ini.ReadInteger('Addr', 'EQP_ID', 0);

    sValue:= ini.ReadString('Addr', 'StartAddr_EQP', '0');
    m_nStartAddr_EQP:= StrToInt('$' + sValue);
    edtStartAddrEQP.Text:= sValue;

    sValue:= ini.ReadString('Addr', 'StartAddr_ROBOT', '0');
    m_nStartAddr_ROBOT:= StrToInt('$' + sValue);
    edtStartAddrRobot.Text:= sValue;

    sValue:= ini.ReadString('Addr', 'StartAddr_ECS', '0');
    m_nStartAddr_ECS:= StrToInt('$' + sValue);
    edtStartAddrECS.Text:= sValue;

    sValue:= ini.ReadString('Addr', 'StartAddr_EQP_W', '0');
    m_nStartAddr_EQP_W:= StrToInt('$' + sValue);
    edtStartAddrEQP_W.Text:= sValue;

    sValue:= ini.ReadString('Addr', 'StartAddr_ROBOT_W', '0');
    m_nStartAddr_ROBOT_W:= StrToInt('$' + sValue);
    edtStartAddrRobot_W.Text:= sValue;

    sValue:= ini.ReadString('Addr', 'StartAddr_ECS_W', '0');
    m_nStartAddr_ECS_W:= StrToInt('$' + sValue);
    edtStartAddrECS_W.Text:= sValue;

    m_bUseSimulation:= ini.ReadBool('ETC', 'UseSimulation' , True);


  finally
    ini.Free;
  end;
end;

procedure TfrmMain.tmrInitTimer(Sender: TObject);
begin
  tmrInit.Enabled:= False;
  AddLog('CommPLC Create');
  //g_CommPLC:= TCommPLCThread.Create(self.Handle, 0);
  g_CommPLC:= TCommPLCThread.Create(self.Handle, MSGTYPE_COMMPLC, m_nStationNo, m_bUseSimulation);
  g_CommPLC.SetEQPID(m_nEQP_ID);
  g_CommPLC.SetStartAddress(m_nStartAddr_EQP, m_nStartAddr_ECS, m_nStartAddr_ROBOT,
                       m_nStartAddr_EQP_W, m_nStartAddr_ECS_W, m_nStartAddr_ROBOT_W );
  //g_CommPLC.LogPath:= ExtractFilePath(Application.ExeName) + '\Log\CommPLC\'; //default
  //g_CommPLC.PollingInterval:= 500; //default
  //g_CommPLC.ConnectionTimeout:= 10000; //default

  g_CommPLC.Start;

  btnShowWindow.Enabled:= g_CommPLC.UseSimulator;
end;

procedure TfrmMain.btnGetDateStringClick(Sender: TObject);
begin
  edtWriteString.Text:= formatDateTime('YYYY-MM-DD HH:NN:SS', Now);
end;

procedure TfrmMain.btnGetValuesClick(Sender: TObject);
var
  sValue: String;
  nCount: Integer;
begin
  nCount:= StrToInt(edtCountReadString.Text);
  sValue:= g_CommPLC.ReadString(edtDeviceString.Text, 0, nCount);
  AddLog(format('ReadString %s(%d) : %s(%d)', [edtDeviceString.Text, nCount, sValue, Length(sValue)]));
//  tmrReadValue.Enabled:= not tmrReadValue.Enabled;
//  if tmrReadValue.Enabled then begin
//    AddLog('Start Read Value ');
//  end
//  else begin
//    AddLog('Stop Read Value ');
//  end;
end;

procedure TfrmMain.btnGlassDataClick(Sender: TObject);
var
  GlassData: TECSGlassData;
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
  GlassData.GlassAddData[0]:= $3232;
  GlassData.GlassAddData[1]:= $3232;
  GlassData.GlassAddData[2]:= $3232;
  GlassData.GlassAddData[3]:= $3232;
  GlassData.GlassAddData[4]:= $3232;
  GlassData.GlassAddData[5]:= $3232;
  GlassData.PreviousUnitProcessing[0]:= $3333;
  GlassData.PreviousUnitProcessing[1]:= $3333;
  GlassData.PreviousUnitProcessing[2]:= $3333;
  GlassData.PreviousUnitProcessing[3]:= $3333;
  GlassData.GlassProcessingStatus[0]:= $3434;
  GlassData.GlassProcessingStatus[1]:= $3434;
  GlassData.GlassProcessingStatus[2]:= $3434;
  GlassData.GlassRoutingData[0]:= $3535;
  GlassData.GlassRoutingData[1]:= $3535;
  GlassData.GlassRoutingData[2]:= $3535;

  AddLog('ECS_GlassData');
  nRes:= g_CommPLC.ECS_GlassData(GlassData);
  if nRes <> 0 then begin
    AddLog('ECS_GlassData NG');
  end
  else begin
    AddLog('ECS_GlassData OK');
  end;
end;

procedure TfrmMain.btnGlassExistClick(Sender: TObject);
var
  nRes: Integer;
  nExist, nCount: Integer;
begin
  nExist:= StrToInt(edtParam1.Text);
  nCount:= StrToInt(edtParam2.Text);

  AddLog(format('ECS_Glass_Exist: nExist=%d, nCount=%d', [nExist, nCount]));
  nRes:= g_CommPLC.ECS_Glass_Exist(nExist, nCount);
  if nRes <> 0 then begin
    AddLog('ECS_Glass_Exist NG');
  end
  else begin
    AddLog('ECS_Glass_Exist OK');
  end;
end;

procedure TfrmMain.btnGlassPositionClick(Sender: TObject);
var
  nCh, nExist, nCode: Integer;
  nRes: Integer;
begin
  nCh:= StrToInt(edtParam1.Text);
  nExist:= StrToInt(edtParam2.Text);
  nCode:= StrToInt(edtParam3.Text);

  AddLog(format('ECS_Glass_Position: ch=%d, Exist=%d, Code=%d', [nCh, nExist, nCode]));
  nRes:= g_CommPLC.ECS_Glass_Position(nCh, nExist <> 0, nCode);
  if nRes <> 0 then begin
    AddLog('ECS_Glass_Position NG');
  end
  else begin
    AddLog('ECS_Glass_Position OK');
  end;
end;

procedure TfrmMain.btnLostGlassClick(Sender: TObject);
var
  nGlassCode, nRequestOption: Integer;
  nRes: Integer;
begin
  nGlassCode:= StrToInt(edtParam2.Text);
  nRequestOption:= StrToInt(edtParam3.Text);

  AddLog(format('ECS_Lost_Glass_Request: sGlassID=%s, nGlassCode=%d, nRequestOption=%d', [edtParam1.Text, nGlassCode, nRequestOption]));
  nRes:= g_CommPLC.ECS_Lost_Glass_Request(edtParam1.Text, nGlassCode, nRequestOption);
  if nRes <> 0 then begin
    AddLog('ECS_Lost_Glass_Request NG');
  end
  else begin
    AddLog('ECS_Lost_Glass_Request OK');
  end;
end;

procedure TfrmMain.btnModelChangeClick(Sender: TObject);
var
  nModel: Integer;
  nRes: Integer;
begin
  nModel:= StrToInt(edtParam1.Text);
  AddLog(format('ECS_ModelChange_Request: Model=%d', [nModel]));
  nRes:= g_CommPLC.ECS_ModelChange_Request(nModel);
  if nRes <> 0 then begin
    AddLog('ECS_ModelChange_Request NG');
  end
  else begin
    AddLog('ECS_ModelChange_Request OK');
  end;
end;

procedure TfrmMain.btnUnitStatusClick(Sender: TObject);
var
  nMode, nValue: Integer;
begin
  nMode:= StrToInt(Trim(Copy(cboUnitStatus.Text, 1, 2)));
  nValue:= StrToInt(edtUnitStatusValue.Text);
  AddLog(format('ECS_Operation_Mode: Mode=%d, Value=%d', [nMode, nValue]));
  g_CommPLC.ECS_Unit_Status(nMode, nValue);
end;

procedure TfrmMain.btnECS_UCHKClick(Sender: TObject);
var
  nData: Integer;
  sUserID: String;
  nRes: Integer;
begin
  sUserID:= edtUserID.Text;
  AddLog(format('ECS_UCHK %s ', [sUserID]));

  TThread.CreateAnonymousThread( procedure begin
    nRes:= g_CommPLC.ECS_UCHK(sUserID, nData);
    if nRes <> 0 then begin
      AddLog('ECS_UCHK NG');
    end
    else begin
      AddLog(format('ECS_UCHK OK: %d', [nData]));
    end;
  end).Start;
end;

procedure TfrmMain.btnECS_ZSETClick(Sender: TObject);
var
  nData: Integer;
  nUserID: Integer;
  nRes: Integer;
begin
  AddLog(format('ECS_ZSET BondingType=1, sZigID=%s, sPID=%s, sPcbID=%s', [edtZigID.Text, edtSerial.Text, '']));
  TThread.CreateAnonymousThread( procedure begin
    nRes:= g_CommPLC.ECS_ZSET(0, 1, edtZigID.Text, edtSerial.Text, '', nData);
    if nRes <> 0 then begin
      AddLog('ECS_ZSET NG');
    end
    else begin
      AddLog(format('ECS_ZSET OK: %d', [nData]));
    end;
  end).Start;
end;

procedure TfrmMain.btnAlarmClick(Sender: TObject);
var
  nAlarmType, nAlarmCode, nOnOff: Integer;
begin
  nAlarmType:= StrToInt(edtAlarmType.Text);
  nAlarmCode:= StrToInt(edtAlarmCode.Text);
  nOnOff:= StrToInt(edtAlarmValue.Text);
  AddLog(format('ECS_Alarm_Report Type=%d, Code=%d, OnOff=%d' , [nAlarmType, nAlarmCode, nOnOff]));
  g_CommPLC.ECS_Alarm_Report(nAlarmType, nAlarmCode, nOnOff);
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear();
end;

procedure TfrmMain.btnECS_APDRClick(Sender: TObject);
var
  naValues: array [0..10] of Integer;
  nRes: Integer;
  sInspectionResult: String;
begin
  sInspectionResult:= 'POCB_RESULT:RESULT:PASS';
  AddLog(format('ECS_APD_Report %s ', [sInspectionResult]));

  TThread.CreateAnonymousThread( procedure begin
    nRes:= g_CommPLC.ECS_APDR(0, sInspectionResult);
    if nRes <> 0 then begin
      AddLog('ECS_APDR NG');
    end
    else begin
      AddLog('ECS_APDR OK');
    end;
  end).Start;
end;

procedure TfrmMain.btnECS_EICRClick(Sender: TObject);
var
  nRes: Integer;
begin
  AddLog(format('ECS_EICR %s ', [edtSerial.Text]));
  TThread.CreateAnonymousThread( procedure begin
    nRes:= g_CommPLC.ECS_EICR(0, edtSerial.Text, edtErrorCode.Text, edtZigID.Text, edtResult.Text);
    if nRes <> 0 then begin
      AddLog(format('ECS_EICR NG %d ', [nRes]));
    end
    else begin
      AddLog(format('ECS_EICR OK %d', [nRes]));
    end;
  end).Start;
end;

procedure TfrmMain.btnECS_PCHKClick(Sender: TObject);
var
  nData: Integer;
  nRes: Integer;
begin
  AddLog(format('ECS_PCHK %s ', [edtSerial.Text]));
  //Cursor:= crHourGlass;
  TThread.CreateAnonymousThread( procedure begin
    nRes:= g_CommPLC.ECS_PCHK(0, edtSerial.Text);
    if nRes <> 0 then begin
      AddLog(format('ECS_PCHK NG %d ', [nData]));
    end
    else begin
      AddLog(format('ECS_PCHK OK: %d', [nData]));
    end;
  end).Start;
  //Cursor:= crDefault;
end;

procedure TfrmMain.btnRobot_ExchangeClick(Sender: TObject);
var
  nRes: Integer;
begin
  AddLog('ROBOT_Exchange_Request');
  TThread.CreateAnonymousThread(
    procedure begin
      nRes:= g_CommPLC.ROBOT_Exchange_Request(0);
      if nRes <> 0 then begin
        AddLog('ROBOT_Exchange_Request NG');
      end
      else begin
        AddLog('ROBOT_Exchange_Request OK');
      end;
    end).Start;
end;

procedure TfrmMain.btnRobot_LoadClick(Sender: TObject);
var
  nRes: Integer;
begin
  AddLog('ROBOT_Load_Request');
  TThread.CreateAnonymousThread(
    procedure begin
      nRes:= g_CommPLC.ROBOT_Load_Request(0);
      if nRes <> 0 then begin
        AddLog('ROBOT_Load_Request NG');
      end
      else begin
        AddLog('ROBOT_Load_Request OK');
      end;
    end).Start;
end;

procedure TfrmMain.btnRobot_UnloadClick(Sender: TObject);
var
  nRes: Integer;
//  naValues: array [0..10] of Integer;
begin
  AddLog('ROBOT_Unload_Request');
  TThread.CreateAnonymousThread(
    procedure begin
      nRes:= g_CommPLC.ROBOT_Unload_Request(0);
      if nRes <> 0 then begin
        AddLog('ROBOT_Unload_Request NG');
      end
      else begin
        AddLog('ROBOT_Unload_Request OK');
      end;
    end).Start;
end;

procedure TfrmMain.btnScrapGlassClick(Sender: TObject);
var
  sValue: String;
  GlassData: TECSGlassData;
begin
  GlassData.LOT_ID:= '12345678';

  sValue:= edtParam1.Text;
  //sValue:= FormatDateTime('HHNNSS', Now);
  AddLog(format('ECS_Scrap_Glass_Report - %s ', [sValue]));
  g_CommPLC.ECS_Scrap_Glass_Report(GlassData, sValue);
end;

procedure TfrmMain.btnSetValuesClick(Sender: TObject);
var
  sValue: String;
begin
  sValue:= edtWriteString.Text;
  //sValue:= FormatDateTime('HHNNSS', Now);
  AddLog(format('WriteString %s (%d): %s', [edtDeviceString.Text, Length(sValue), sValue]));
  g_CommPLC.WriteString(edtDeviceString.Text, sValue);
end;

procedure TfrmMain.btnShowStatusClick(Sender: TObject);
begin
  frmECSStatus:= TfrmECSStatus.Create(self);
  frmECSStatus.SetMode(1);
  frmECSStatus.Show;
end;

procedure TfrmMain.btnShowWindowClick(Sender: TObject);
begin
  g_CommPLC.ShowSimulator;
end;


procedure TfrmMain.btnReadBitClick(Sender: TObject);
var
  nValue, nBitLoc: Integer;
begin
  nBitLoc:= StrToInt(edtBitLoc.Text);
  nValue:= StrToInt('$' + edtWriteValue.Text);

  g_CommPLC.ReadDeviceBit(edtDevice.Text, nBitLoc, nValue);
  AddLog(format('Read Bit Value %s.%d: %d', [edtDevice.Text, nBitLoc, nValue]));
end;


procedure TfrmMain.btnReadDeviceClick(Sender: TObject);
var
  nValue: Integer;
begin
  g_CommPLC.ReadDevice(edtDevice.Text, nValue);
  AddLog(format('Read Device %s: 0x%.4x (%d)', [edtDevice.Text, nValue, nValue]));
end;

procedure TfrmMain.btnReadBlockClick(Sender: TObject);
var
  naValue: array of Integer;
begin
  SetLength(naValue, 2);
  //naValue[0]:= StrToInt('$' + edtWriteValue.Text);
  g_CommPLC.ReadDeviceBlock(edtDevice.Text, 1, naValue[0]);
  AddLog(format('Read Value %s: 0x%.4x (%d)', [edtDevice.Text, naValue[0], naValue[0]]));
end;

procedure TfrmMain.btnReadClockDataClick(Sender: TObject);
var
  wYear, wMonth, wDay, wWeek, wHour, wMinute, wSecond: SmallInt;
begin
  g_CommPLC.ReadClockData(wYear, wMonth, wDay, wWeek, wHour, wMinute, wSecond);
  AddLog(format('Read Clock Data %4d-%.2d-%.2d %.2d:%.2d:%.2d (%.2d w)', [wYear, wMonth, wDay, wHour, wMinute, wSecond, wWeek]));
end;

procedure TfrmMain.btnWriteBitClick(Sender: TObject);
var
  nValue, nBitLoc: Integer;
begin
  nBitLoc:= StrToInt(edtBitLoc.Text);
  nValue:= StrToInt('$' + edtWriteValue.Text);
  AddLog(format('Write Bit Value %s.%d: %d', [edtDevice.Text, nBitLoc, nValue]));
  g_CommPLC.WriteDeviceBit(edtDevice.Text, nBitLoc, nValue);
end;

procedure TfrmMain.btnWriteBit_ThreadClick(Sender: TObject);
var
  th: array [0..10] of TThread;
  k: Integer;
  nAddr: Integer;
  sKind: String;
begin
  sKind:= Copy(edtDevice.Text, 1, 1);
  nAddr:= StrToInt('$' + Copy(edtDevice.Text, 2, Length(edtDevice.Text)));
  for k := 0 to 5 do begin
  th[k]:= TThread.CreateAnonymousThread(
    procedure var i, nBitLoc, nValue: Integer; begin

      //nBitLoc:= 3;

      //nValue:= k Mod 2;
      //g_CommPLC.WriteDeviceBit(edtDevice.Text, nBitLoc, nValue);

      //SendMessage(self.Handle, WM_USER + 1, TThread.CurrentThread.ThreadID, (nBitLoc shl 16) + nValue);

      for i := 1 to 9 do begin
        nBitLoc:= Random(15);
        nValue:= i Mod 2;
        //g_CommPLC.WriteDeviceBit(edtDevice.Text, nBitLoc, nValue);
        g_CommPLC.WriteDeviceBit(sKind + IntToHex(nAddr + nBitLoc), nBitLoc, nValue);
        //SendMessage(self.Handle, WM_USER + 1, TThread.CurrentThread.ThreadID, (nBitLoc shl 16) + nValue);
        PostMessage(self.Handle, WM_USER + 1, TThread.CurrentThread.ThreadID, (nBitLoc shl 16) + nValue);
        Sleep(1);
      end;

    end
    );
  end;

  for k := 0 to 5 do begin
    th[k].Start;
  end;
end;

procedure TfrmMain.btnWriteBlockClick(Sender: TObject);
var
  naValue: array of Integer;
begin
  SetLength(naValue, 2);
  naValue[0]:= StrToInt('$' + edtWriteValue.Text);
  AddLog(format('Write Value %s: 0x%.4x (%d)', [edtDevice.Text, naValue[0], naValue[0]]));
  g_CommPLC.WriteDeviceBlock(edtDevice.Text, 1, naValue[0]);
end;


procedure TfrmMain.btnWriteDeviceClick(Sender: TObject);
var
  nValue: Integer;
begin
  nValue:= StrToInt('$' + edtWriteValue.Text);
  AddLog(format('Write Device %s: 0x%.4x (%d)', [edtDevice.Text, nValue, nValue]));
  g_CommPLC.WriteDevice(edtDevice.Text, nValue);
end;


procedure TfrmMain.tmrReadValueTimer(Sender: TObject);
begin
  AddLog('ReadValue: ' + g_CommPLC.DataValue[0].ToString);
end;

procedure TfrmMain.UpdatePLC;
var
  i: Integer;
  //sLog: String;
begin
  //PLC 데이터 변경 GUI 변경
(*
  for k := 0 to Pred(defPlc.MAX_IN_CNT) do begin
    dwTemp := 1 shl k;
    if (dwTemp and g_CommPLC.PollingData[i]) <> 0 then begin
      ledPlcIn[k].LedOn := True;
    end
    else begin
      ledPlcIn[k].LedOn := False;
    end;
  end;
*)
  //sLog:= '';
  for i := 0 to COMMPLC_ROBOT_DATASIZE do begin
    if g_CommPLC.PollingData[i] <> g_CommPLC.PollingDataPre[i] then begin
      AddLog(format('Changed Data Index: %.2d (%.6d <= %.6d)', [i, g_CommPLC.PollingData[i], g_CommPLC.PollingDataPre[i]]));
      //sLog:= sLog + format('Changed Data Index: %.2d (%.6d <= %.6d)', [i, g_CommPLC.PollingData[i], g_CommPLC.PollingDataPre[i]]);
    end;
  end;
  //if sLog <> '' then AddLog(sLog);
end;

procedure TfrmMain.WMCopyData(var Msg: TMessage);
var
  pMsg:PCOPYDATAMessage;
begin
  pMsg:= PCOPYDATAMessage(PCopyDataStruct(Msg.LParam).lpData);

  case pMsg.MsgType of
    MSGTYPE_COMMPLC: begin
      case pMsg.Mode of
        COMMPLC_MODE_CONNECT: begin
          if pMsg.Param <> 0 then begin
            //연결 할 수 없음 //Error
            AddLog('PLC Connection Fail');
          end
          else begin
            AddLog('PLC Connected');
          end;
        end; //COMMPLC_MODE_CONNECT: begin
        CommPLC_ECS.COMMPLC_MODE_CHANGE_ROBOT: begin
          //데이터 변경
          AddLog(format('ROBOT Changed Data: [%s], Index: %.2d (%.6d <= %.6d)', [pMsg.Msg, pMsg.Param, g_CommPLC.PollingData[pMsg.Param], g_CommPLC.PollingDataPre[pMsg.Param]]));
          //UpdatePLC;
        end; //COMMPLC_MODE_CHANGE_ROBOT: begin
        CommPLC_ECS.COMMPLC_MODE_CHANGE_ECS: begin
          //데이터 변경
          AddLog(format('ECS Changed Data [%s], Index: %.2d (%.6d <= %.6d)', [pMsg.Msg, pMsg.Param, g_CommPLC.PollingData[pMsg.Param], g_CommPLC.PollingDataPre[pMsg.Param]]));
          //UpdatePLC;
        end; //COMMPLC_MODE_CHANGE_ECS: begin
        CommPLC_ECS.COMMPLC_MODE_EVENT_ROBOT: begin
          //Robot 이벤트
          case pMsg.Param of
            COMMPLC_PARAM_LOADGLASSDATA: begin //Glass Data Report
              if pMsg.Param2 <> 0 then begin
                //Erorr
                AddLog('Glass Data Report NG: ' + pMsg.Msg);
              end
              else begin
                AddLog('Glass Data Report OK: ' + pMsg.Msg);
              end;
            end;
            COMMPLC_PARAM_LOADCOMPLETE: begin //Load Complete
              if pMsg.Param2 <> 0 then begin
                //Erorr
                AddLog('Load Complete NG: ' + pMsg.Msg);
              end
              else begin
                AddLog('Load Complete OK: ' + pMsg.Msg);
              end;
            end;
            COMMPLC_PARAM_LOADCOMPLETE_OFF: begin //Load Complete Off
              if pMsg.Param2 <> 0 then begin
                //Erorr
                AddLog('Load Complete Off NG: ' + pMsg.Msg);
              end
              else begin
                AddLog('Load Complete Off OK: ' + pMsg.Msg);
              end;
            end;
            COMMPLC_PARAM_UNLOADCOMPLETE: begin //UnLoad Complete
              if pMsg.Param2 <> 0 then begin
                //Erorr
                AddLog('UnLoad Complete NG: ' + pMsg.Msg);
              end
              else begin
                AddLog('UnLoad Complete OK: ' + pMsg.Msg);
              end;
            end;
            COMMPLC_PARAM_UNLOADCOMPLETE_OFF: begin //UnLoad Complete Off
              if pMsg.Param2 <> 0 then begin
                //Erorr
                AddLog('UnLoad Complete Off NG: ' + pMsg.Msg);
              end
              else begin
                AddLog('UnLoad Complete Off OK: ' + pMsg.Msg);
              end;
            end;
          end; //case pMsg.Param of
        end; //COMMPLC_MODE_EVENT_ROBOT: begin
        else begin
          //Unknown Msg Mode
        end; //else begin
      end; //case pMsg.Mode of
    end; //MSGTYPE_COMMPLC: begin
  end; //case pMsg.MsgType of
end;

procedure TfrmMain.WMUser(var Msg: TMessage);
begin
  case Msg.WParam of
    COMMPLC_MODE_CHANGE_ROBOT:begin
      AddLog(format('ROBOT Changed Data %d (Index:%x, Value=%d)', [Msg.LParam, Msg.LParamLo, Msg.LParamHi]));
    end;
    COMMPLC_MODE_CHANGE_ECS: begin
      AddLog(format('ECS Changed Data %d (Index:%x, Value=%d)', [Msg.LParam, Msg.LParamLo, Msg.LParamHi]));
    end;
    else begin
      AddLog(format('User Message %d: %d (%d.%d)', [Msg.WParam, Msg.LParam, Msg.LParamLo, Msg.LParamHi]));
    end;
  end; //case Msg.WParam of
end;

end.
