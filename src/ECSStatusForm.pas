unit ECSStatusForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.Grids, AdvObj, BaseGrid,
  AdvGrid, Vcl.ExtCtrls, Vcl.StdCtrls,
  CommPLC_ECS, ControlDio_OC;

type
  /// <summary> Status 창과 Maint 겸용으로 사용하는 폼 </summary>
  TfrmECSStatus = class(TForm)
    grdStatus: TAdvStringGrid;
    tmrRefresh: TTimer;
    btnCloses: TButton;
    pnlTest: TPanel;
    GroupBox3: TGroupBox;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    btnECS_PCHK: TButton;
    btnECS_EICR: TButton;
    btnECS_UCHK: TButton;
    btnECS_APDR: TButton;
    edtUserID: TEdit;
    edtSerial: TEdit;
    edtResult: TEdit;
    edtZigID: TEdit;
    edtErrorCode: TEdit;
    GroupBox5: TGroupBox;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    btnAlarm: TButton;
    edtAlarmCode: TEdit;
    GroupBox6: TGroupBox;
    Label12: TLabel;
    Label13: TLabel;
    btnUnitStatus: TButton;
    cboUnitStatus: TComboBox;
    btnECS_ZSET: TButton;
    GroupBox4: TGroupBox;
    btnRobot_Unload: TButton;
    btnRobot_Load: TButton;
    btnRobot_Exchange: TButton;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    edtDevice: TEdit;
    edtValue: TEdit;
    btnReadDevice: TButton;
    btnWriteDevice: TButton;
    btnShowSimulator: TButton;
    GroupBox1: TGroupBox;
    lblStartAddrEQP: TLabel;
    lblStartAddrEQP_W: TLabel;
    lblStartAddrROBOT: TLabel;
    lblStartAddrROBOT_W: TLabel;
    lblStartAddrECS: TLabel;
    lblStartAddrECS_W: TLabel;
    edtStartAddrEQP: TEdit;
    edtStartAddrEQP_W: TEdit;
    edtStartAddrECS: TEdit;
    edtStartAddrECS_W: TEdit;
    edtStartAddrRobot: TEdit;
    edtStartAddrRobot_W: TEdit;
    memoLog: TMemo;
    cboValue_Status: TComboBox;
    cboValue_Alarm: TComboBox;
    cboChannel_Robot: TComboBox;
    Label3: TLabel;
    cboAlarmType: TComboBox;
    gbETC: TGroupBox;
    Label17: TLabel;
    edtParam1: TEdit;
    Label18: TLabel;
    edtParam2: TEdit;
    Label19: TLabel;
    edtParam3: TEdit;
    btnGlassData: TButton;
    btnModelChange: TButton;
    btnGlassPosition: TButton;
    btnLostGlass: TButton;
    btnGlassExist: TButton;
    btnScrapGlass: TButton;
    btnStagePosition: TButton;
    btnAccStatus: TButton;
    btnLinkTest: TButton;
    btnRobot_Clear: TButton;
    btnGlassInProcessing: TButton;
    btnTactTime: TButton;
    btnShowGlassData: TButton;
    pnlGlassData: TPanel;
    grdGlassData: TAdvStringGrid;
    Label4: TLabel;
    btnHideGlassData: TButton;
    Edit3: TEdit;
    Button1: TButton;
    btnTakeOutReport: TButton;
    procedure FormCreate(Sender: TObject);
    procedure tmrRefreshTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnClosesClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnReadDeviceClick(Sender: TObject);
    procedure btnWriteDeviceClick(Sender: TObject);
    procedure btnShowSimulatorClick(Sender: TObject);
    procedure btnECS_UCHKClick(Sender: TObject);
    procedure btnECS_PCHKClick(Sender: TObject);
    procedure btnECS_ZSETClick(Sender: TObject);
    procedure btnECS_EICRClick(Sender: TObject);
    procedure btnECS_APDRClick(Sender: TObject);
    procedure btnGlassDataClick(Sender: TObject);
    procedure btnModelChangeClick(Sender: TObject);
    procedure btnGlassPositionClick(Sender: TObject);
    procedure btnGlassExistClick(Sender: TObject);
    procedure btnLostGlassClick(Sender: TObject);
    procedure btnScrapGlassClick(Sender: TObject);
    procedure btnUnitStatusClick(Sender: TObject);
    procedure btnAlarmClick(Sender: TObject);
    procedure btnRobot_LoadClick(Sender: TObject);
    procedure btnRobot_UnloadClick(Sender: TObject);
    procedure btnRobot_ExchangeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStagePositionClick(Sender: TObject);
    procedure btnAccStatusClick(Sender: TObject);
    procedure btnLinkTestClick(Sender: TObject);
    procedure btnRobot_ClearClick(Sender: TObject);
    procedure btnGlassInProcessingClick(Sender: TObject);
    procedure btnTactTimeClick(Sender: TObject);
    procedure btnHideGlassDataClick(Sender: TObject);
    procedure btnShowGlassDataClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnTakeOutReportClick(Sender: TObject);
  private
    { Private declarations }
    m_aMESItemValue: array [0..8] of TMESItemValue;
    procedure Init_Grid;
    procedure UpdateStatus;
    procedure SetCellState(nCol, nRow, nDivisioin, nIndex, nBitLoc: Integer);
    procedure AddLog(sLog: String);
    procedure Process_Thread_PCHK(nCh: Integer; sSerial: String);
    procedure Process_Thread_EICR(nCh: Integer; sErrorCode, sInspectionResult: String);
    procedure Process_Thread_APDR(nCh: Integer; sInspectionResult: String);
    procedure Process_Thread_ZSET(nCh, nBondingType: Integer; sZigID, sPID, sPcbID: String);

  public
    { Public declarations }
    /// <summary>0=Status Mode, 1=Mainter Mode </summary>
    procedure SetMode(nMode: Integer);
    procedure MESNotifyEvent(ItemValue: TMESItemValue);
  end;

var
  frmECSStatus: TfrmECSStatus;

implementation

{$R *.dfm}

uses DefCommon, CommonClass, Main_OC;

procedure TfrmECSStatus.AddLog(sLog: String);
begin
  if Tag > 0 then Exit;

  if memoLog.Lines.Count > 100 then begin
     memoLog.Lines.Clear;
  end;
  memoLog.Lines.Add(FormatDateTime('HH:NN:SS.ZZZ => ', Now) +  sLog);
end;

procedure TfrmECSStatus.btnAccStatusClick(Sender: TObject);
var
  nStage, nValue, nAlarmCode: Integer;
  nRes: Integer;
begin
  nStage:= StrToInt(edtParam1.Text);
  nValue:= StrToInt(edtParam2.Text);
  nAlarmCode:= StrToInt(edtParam3.Text);

  AddLog(format('ECS_Accessory_Unit_Status: nStage=%d, nValue=%d', [nStage, nValue]));
  nRes:= g_CommPLC.ECS_Accessory_Unit_Status(nStage, nValue, nAlarmCode);
  if nRes <> 0 then begin
    AddLog('ECS_Accessory_Unit_Status NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_Accessory_Unit_Status OK');
  end;
end;

procedure TfrmECSStatus.btnAlarmClick(Sender: TObject);
var
  nRes: Integer;
  nAlarmType, nAlarmCode, nOnOff: Integer;
begin
  nAlarmType:= cboAlarmType.ItemIndex;
  nAlarmCode:= StrToInt(edtAlarmCode.Text);
  nOnOff:= cboValue_Alarm.ItemIndex; //StrToInt(edtAlarmValue.Text);
  AddLog(format('ECS_Alarm_Report Type=%d, Code=%d, OnOff=%d' , [nAlarmType, nAlarmCode, nOnOff]));
  nRes:= g_CommPLC.ECS_Alarm_Report(nAlarmType, nAlarmCode, nOnOff);
  if (nAlarmType = 1) and (nOnOff = 1) then    nRes:= g_CommPLC.ECS_Unit_Status(10, nAlarmCode);
  if (nAlarmType = 1) and (nOnOff = 0) then    nRes:= g_CommPLC.ECS_Unit_Status(9, nAlarmCode);
  if nRes <> 0 then begin
    AddLog('ECS_Alarm_Report NG');
  end
  else begin
    AddLog('ECS_Alarm_Report OK');
  end;
end;

procedure TfrmECSStatus.btnClosesClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmECSStatus.btnECS_APDRClick(Sender: TObject);
var
  nRes: Integer;
  nCh: Integer;
  sInspectionResult: String;
begin
  nCh:= 2;

  g_CommPLC.GlassData[nCh].GlassID:= 'ABCDEFGHIJKL';
  g_CommPLC.GlassData[nCh].GlassCode:= 1234;
  g_CommPLC.GlassData[nCh].GlassType:= 0;

  sInspectionResult:=                     format('%-12s', ['1HMAMAL46201']);  //EQP_ID
  sInspectionResult:= sInspectionResult + format('%2d', [nCh]);  //CH
  sInspectionResult:= sInspectionResult + format('%-16s', [Copy('3.0.2103.501', 12)]); //S/W_UI_VER
  sInspectionResult:= sInspectionResult + format('%-20s', ['4160/F409/M54D/PW22']); //H/W_PG_VER
  sInspectionResult:= sInspectionResult + format('%-2s', ['5']);  //H/W_VIDEO_VER
  sInspectionResult:= sInspectionResult + format('%-2s', ['6']);   //H/W_SLOT_VER
  sInspectionResult:= sInspectionResult + format('%-34s', ['725F-SP-D846-CB-SIM-210305-DA-T01']); //SCRIPT_NAME
  sInspectionResult:= sInspectionResult + format('%-2s', ['8']); ////PUC_DLL
  sInspectionResult:= sInspectionResult + format('%-12s', ['902xxx']); //USER_ID
  sInspectionResult:= sInspectionResult + format('%-174s', ['10303350PMQPR5R16+P1D1060105A128621LA2+GLD02751LB2Q8HC3D+08007245000135001148605263+0000000000000000000000000000000000000000000000000000000000000000000HSJH30109MLHKB40011111']); //Seriall
  sInspectionResult:= sInspectionResult + format('%-16s', ['11D878E100000656']); //CarrierId
  sInspectionResult:= sInspectionResult + format('%-4s', ['122']); //Config
  sInspectionResult:= sInspectionResult + format('%-20s', ['13AXC46P20FQA502G9A']); //D-Flex
  sInspectionResult:= sInspectionResult + format('%-56s', ['1480_0x20_0x00_0x00_0x00_0x00_0x00_0x00_0x00_0x00_0x00_0x00_0x16_0xFB_0x28_0x83_0x00_0x00_0x3E_0xC0_0x4C_0xFA_0x0D_0xDC_0x16_0xFB_0x28_0x83_']); //VerifyCS
  sInspectionResult:= sInspectionResult + format('%-2s', ['15']); //Result
  sInspectionResult:= sInspectionResult + format('%-12s', ['166-B01-47A']); //MES_CODE
  sInspectionResult:= sInspectionResult + format('%-40s', ['17PROM_Read_Fail']); //Description
  sInspectionResult:= sInspectionResult + format('%-80s', ['18RROR]_EEPROM_Read_Fail(Timeout)']); //Long_Description
  sInspectionResult:= sInspectionResult + format('%6d', [930000]); //ZAxis-Cur
  sInspectionResult:= sInspectionResult + format('%6d', [930000]); //ZAxis-Target
  sInspectionResult:= sInspectionResult + format('%-10s', [formatDateTime('21YYMMDD', Now)]); //Date
  sInspectionResult:= sInspectionResult + format('%-6s', [formatDateTime('22MMSS', Now)]);  //StartTime
  sInspectionResult:= sInspectionResult + format('%-6s', [formatDateTime('23MMSS', Now)]); //EndTime
  sInspectionResult:= sInspectionResult + format('%8d', [80 * 100]); //ms
  sInspectionResult:= sInspectionResult + format('%8d', [160 * 100]); //ms

  //sInspectionResult:= StringReplace(sInspectionResult, ' ', '_', [rfReplaceAll]);
  AddLog(format('ECS_APDR %s ', [sInspectionResult]));

  Process_Thread_APDR(nCh, sInspectionResult);
  Exit;

TThread.CreateAnonymousThread( procedure begin

//  nRes:= g_CommPLC.ECS_APDR(nCh, sInspectionResult);  // Added by KTS 2023-03-24 오후 9:02:00
  if nRes <> 0 then begin
    AddLog('ECS_APDR NG');
  end
  else begin
    AddLog('ECS_APDR OK');
  end;
end).Start;
end;

procedure TfrmECSStatus.btnECS_EICRClick(Sender: TObject);
var
  nRes: Integer;
  nCh: Integer;
  i: Integer;
begin
  nCh:= 0;
  for i := 0 to 3 do begin
    AddLog(format('ECS_EICR Ch=%d, Result=%s ', [i, edtResult.Text]));
    //큐를 이용한 순차 처리
    g_CommPLC.ECS_LCM_ID[i]:= '123456789012345678901234';  //24자리
    g_CommPLC.ECS_GlassData[i].LCM_ID:= '123456789012345678901234';  //24자리
    Process_Thread_EICR(i, edtErrorCode.Text, edtResult.Text);
  end;
  Exit;

  TThread.CreateAnonymousThread( procedure begin
    nRes:= g_CommPLC.ECS_EICR(nCh, g_CommPLC.ECS_LCM_ID[nCh], edtErrorCode.Text, edtResult.Text);
    if nRes <> 0 then begin
      AddLog(format('ECS_EICR NG %d ', [nRes]));
    end
    else begin
      AddLog(format('ECS_EICR OK %d', [nRes]));
    end;
  end).Start;
end;

procedure TfrmECSStatus.btnECS_PCHKClick(Sender: TObject);
var
  //item: TMESItem;
  i:Integer;
begin

  for i := 0 to 3 do begin
    AddLog(format('ECS_PCHK Ch=%d, Serial=%s ', [i, edtSerial.Text]));
    //큐를 이용한 순차 처리
    Process_Thread_PCHK(i+4, edtSerial.Text);
  end;
end;

procedure TfrmECSStatus.btnECS_UCHKClick(Sender: TObject);
var
  sUserID: String;
  nRes: Integer;
begin
  sUserID:= edtUserID.Text;
  AddLog(format('ECS_UCHK %s ', [sUserID]));

  TThread.CreateAnonymousThread( procedure begin
    nRes:= g_CommPLC.ECS_UCHK(sUserID);
    if nRes <> 0 then begin
      AddLog('ECS_UCHK NG ' + IntToStr(nRes));
    end
    else begin
      AddLog('ECS_UCHK OK');
    end;
  end).Start;
end;

procedure TfrmECSStatus.btnECS_ZSETClick(Sender: TObject);
var
  nData: Integer;
  nRes: Integer;
begin
  AddLog(format('ECS_ZSET BondingType=1, sZigID=%s, sPID=%s, sPcbID=%s', [edtZigID.Text, edtSerial.Text, '']));

//  Process_Thread_ZSET(nCh, 1, edtZigID.Text, edtSerial.Text, '');
//  Exit;

TThread.CreateAnonymousThread( procedure begin
  nRes:= g_CommPLC.ECS_ZSET(0, 1, edtZigID.Text, edtSerial.Text, '', nData);
  if nRes <> 0 then begin
    AddLog('ECS_ZSET NG ' + IntToStr(nRes));
  end
  else begin
    AddLog(format('ECS_ZSET OK: %d', [nData]));
  end;
end).Start;
end;

procedure TfrmECSStatus.btnGlassDataClick(Sender: TObject);
var
  GlassData: TECSGlassData;
  nRes: Integer;
begin
  GlassData.CarrierID:= '1234567890ABCDEF';
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

  AddLog('ECS_GlassData');
  nRes:= g_CommPLC.ECS_GlassData_Report(GlassData);
  if nRes <> 0 then begin
    AddLog('ECS_GlassData_Report NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_GlassData_Report OK');
  end;
end;

procedure TfrmECSStatus.btnGlassExistClick(Sender: TObject);
var
  nRes: Integer;
  nExist, nCount: Integer;
begin
  nExist:= StrToInt(edtParam1.Text);
  nCount:= StrToInt(edtParam2.Text);

  AddLog(format('ECS_Glass_Exist: nExist=%d, nCount=%d', [nExist, nCount]));
  nRes:= g_CommPLC.ECS_Glass_Exist(nExist, nCount);
  if nRes <> 0 then begin
    AddLog('ECS_Glass_Exist NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_Glass_Exist OK');
  end;
end;

procedure TfrmECSStatus.btnGlassInProcessingClick(Sender: TObject);
var
  nValue: Integer;
  nRes: Integer;
begin
  nValue:= StrToInt(edtParam1.Text);

  AddLog(format('ECS_Glass_Processing: Exist=%d', [nValue]));
  nRes:= g_CommPLC.ECS_Glass_Processing(nValue <> 0);
  if nRes <> 0 then begin
    AddLog('ECS_Glass_Processing NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_Glass_Processing OK');
  end;
end;

procedure TfrmECSStatus.btnGlassPositionClick(Sender: TObject);
var
  nCh, nExist: Integer;
  nRes: Integer;
begin
  nCh:= StrToInt(edtParam1.Text);
  nExist:= StrToInt(edtParam2.Text);

  AddLog(format('ECS_Glass_Position: ch=%d, Exist=%d', [nCh, nExist]));
  nRes:= g_CommPLC.ECS_Glass_Position(nCh, nExist <> 0);
  if nRes <> 0 then begin
    AddLog('ECS_Glass_Position NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_Glass_Position OK');
  end;
end;

procedure TfrmECSStatus.btnHideGlassDataClick(Sender: TObject);
begin
  pnlGlassData.Visible:= False;
end;

procedure TfrmECSStatus.btnLinkTestClick(Sender: TObject);
var
  nRes: Integer;
begin
  AddLog('ECS_Link_Test');
  nRes:= g_CommPLC.ECS_Link_Test;
  if nRes <> 0 then begin
    AddLog('ECS_Link_Test NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_Link_Test OK');
  end;
end;

procedure TfrmECSStatus.btnLostGlassClick(Sender: TObject);
var
  nGlassCode, nRequestOption: Integer;
  nRes: Integer;
begin
  nGlassCode:= StrToInt(edtParam2.Text);
  nRequestOption:= StrToInt(edtParam3.Text);

  TThread.CreateAnonymousThread(
  procedure begin

    AddLog(format('ECS_Lost_Glass_Request: sGlassID=%s, nGlassCode=%d, nRequestOption=%d', [edtParam1.Text, nGlassCode, nRequestOption]));
    nRes:= g_CommPLC.ECS_Lost_Glass_Request(edtParam1.Text, nGlassCode, nRequestOption);
    if nRes <> 0 then begin
      AddLog('ECS_Lost_Glass_Request NG ' + IntToStr(nRes));
    end
    else begin
      AddLog('ECS_Lost_Glass_Request OK');
    end;
  end
  ).Start;


end;

procedure TfrmECSStatus.btnModelChangeClick(Sender: TObject);
var
  nModel: Integer;
  nRes: Integer;
begin
  nModel:= StrToInt(edtParam1.Text);
  AddLog(format('ECS_ModelChange_Request: Model=%d', [nModel]));
  nRes:= g_CommPLC.ECS_ModelChange_Request(nModel);
  if nRes <> 0 then begin
    AddLog('ECS_ModelChange_Request NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_ModelChange_Request OK');
  end;
end;

procedure TfrmECSStatus.btnReadDeviceClick(Sender: TObject);
var
  nValue,nResuit,i,nSize: Integer;
  ates : array of Integer;
begin
  if g_CommPLC = nil then Exit;

  nResuit := g_CommPLC.ReadDevice(edtDevice.Text, nValue);
  edtValue.Text := IntToHex(nValue, 1);
  memoLog.Lines.Add(edtValue.Text);

 SetLength(ates,4);
  if nResuit <> 0 then begin
    AddLog('btnReadDeviceClick NG');
  end
  else begin
    AddLog('btnReadDeviceClick OK');
  end;

//   nResuit := g_CommPLC.ReadDeviceBlock(edtDevice.Text,4,ates[0],nResuit);



end;

procedure TfrmECSStatus.btnRobot_ClearClick(Sender: TObject);
var
  nRes: Integer;
begin
  AddLog('EQP_Clear_ROBOT_Request');
  nRes:= g_CommPLC.EQP_Clear_ROBOT_Request(cboChannel_Robot.ItemIndex);
  if nRes <> 0 then begin
    AddLog('EQP_Clear_ROBOT_Request NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('EQP_Clear_ROBOT_Request OK');
  end;
end;

procedure TfrmECSStatus.btnRobot_ExchangeClick(Sender: TObject);
var
  nRes: Integer;
begin
  AddLog('ROBOT_Exchange_Request');
  TThread.CreateAnonymousThread(
    procedure begin

//      if ControlDio.LoadZoneStage = lzsA then begin
//        if ControlDio.ContactDown(DefCommon.CH_STAGE_A) <> 0 then Exit;
//      end
//      else begin
//        if ControlDio.ContactDown(DefCommon.CH_STAGE_B) <> 0 then Exit;
//      end;

      nRes:= g_CommPLC.ROBOT_Exchange_Request(cboChannel_Robot.ItemIndex);
      if nRes <> 0 then begin
        AddLog('ROBOT_Exchange_Request NG ' + IntToStr(nRes));
      end
      else begin
        AddLog('ROBOT_Exchange_Request OK');
      end;
    end
  ).Start;
end;

procedure TfrmECSStatus.btnRobot_LoadClick(Sender: TObject);
var
  nRes: Integer;
begin
  AddLog('ROBOT_Load_Request: ' + IntToStr(cboChannel_Robot.ItemIndex));
  TThread.CreateAnonymousThread(
    procedure begin
//      if ControlDio.LoadZoneStage = lzsA then begin
//        if ControlDio.ContactDown(DefCommon.CH_STAGE_A) <> 0 then Exit;
//      end
//      else begin
//        if ControlDio.ContactDown(DefCommon.CH_STAGE_B) <> 0 then Exit;
//      end;
      if not frmMain_OC.CheckProbe(cboChannel_Robot.ItemIndex) then begin
          AddLog('Do not Request - Probe is Running ');
          Exit;
      end;

      if frmMain_OC.CheckEmpty_Pair(0, cboChannel_Robot.ItemIndex) then
        begin
           AddLog('Do not Request - CheckEmpty_Pair');
          Exit;
        end;


      nRes:= g_CommPLC.ROBOT_Load_Request(cboChannel_Robot.ItemIndex);
      if nRes <> 0 then begin
        AddLog('ROBOT_Load_Request NG ' + IntToStr(nRes));
      end
      else begin
        AddLog('ROBOT_Load_Request OK');
      end;
    end
  ).Start;
end;

procedure TfrmECSStatus.btnRobot_UnloadClick(Sender: TObject);
var
  nRes: Integer;
//  naValues: array [0..10] of Integer;
begin
  AddLog('ROBOT_Unload_Request: ' + IntToStr(cboChannel_Robot.ItemIndex));
  TThread.CreateAnonymousThread(
    procedure begin
//      if cboChannel_Robot.ItemIndex = 0 then begin
//        if ControlDio.ContactDown(DefCommon.CH_STAGE_A) <> 0 then Exit;
//      end
//      else begin
//        if ControlDio.ContactDown(DefCommon.CH_STAGE_B) <> 0 then Exit;
//      end;

      if not frmMain_OC.CheckProbe(cboChannel_Robot.ItemIndex) then begin
          AddLog('Do not Request - Probe is Running');
          Exit;
      end;

      nRes:= g_CommPLC.ROBOT_Unload_Request(cboChannel_Robot.ItemIndex);
      if nRes <> 0 then begin
        AddLog('ROBOT_Unload_Request NG ' + IntToStr(nRes));
      end
      else begin
        AddLog('ROBOT_Unload_Request OK');
      end;
    end
  ).Start;
end;

procedure TfrmECSStatus.btnScrapGlassClick(Sender: TObject);
var
  nRes: Integer;
  sValue: String;
  GlassData: TECSGlassData;
begin
  GlassData.CarrierID:= '12345678';
  sValue:= edtParam1.Text;
  //sValue:= FormatDateTime('HHNNSS', Now);
  AddLog(format('ECS_Scrap_Glass_Report - %s ', [sValue]));
  nRes:= g_CommPLC.ECS_Scrap_Glass_Report(GlassData, sValue);
  if nRes <> 0 then begin
    AddLog('ECS_Scrap_Glass_Report NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_Scrap_Glass_Report OK');
  end;
end;

procedure TfrmECSStatus.btnShowGlassDataClick(Sender: TObject);
var
  i: Integer;
begin
  if pnlGlassData.Visible then begin
    pnlGlassData.Visible:= False;
    Exit;
  end;

  for i := 0 to 7 do begin
    grdGlassData.Cells[0, i+1]:= IntToStr(i+1);
    grdGlassData.Cells[1, i+1]:= g_CommPLC.GlassData[i].MateriID;
    grdGlassData.Cells[2, i+1]:= IntToStr(g_CommPLC.GlassData[i].GlassCode);
    grdGlassData.Cells[3, i+1]:= g_CommPLC.GlassData[i].GlassID;
    grdGlassData.Cells[4, i+1]:= IntToStr(g_CommPLC.GlassData[i].GlassJudge);
  end;

  pnlGlassData.Visible:= True;
end;

procedure TfrmECSStatus.btnShowSimulatorClick(Sender: TObject);
begin
  g_CommPLC.ShowSimulator;
  //g_CommPLC.ShowModalSimulator;
end;

procedure TfrmECSStatus.btnStagePositionClick(Sender: TObject);
var
  nModel: Integer;
  nRes: Integer;
begin
  nModel:= StrToInt(edtParam1.Text);
  AddLog(format('ECS_Stage_Position: Model=%d', [nModel]));
  nRes:= g_CommPLC.ECS_Stage_Position(nModel);
  if nRes <> 0 then begin
    AddLog('ECS_ModelChange_Request NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_ModelChange_Request OK');
  end;
end;

procedure TfrmECSStatus.btnTactTimeClick(Sender: TObject);
var
  nRes: Integer;
  nCh, nValue: Integer;
begin
  nCh:= StrToInt(edtParam1.Text);
  nValue:= StrToInt(edtParam2.Text);

  AddLog(format('ECS_WriteTactTime: nCh=%d, nValue=%d', [nCh, nValue]));
  nRes:= g_CommPLC.ECS_WriteTactTime(nValue);
  if nRes <> 0 then begin
    AddLog('ECS_WriteTactTime NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_WriteTactTime OK');
  end;
end;

procedure TfrmECSStatus.btnTakeOutReportClick(Sender: TObject);
var
sPanelID : string;
nRes : Integer;
begin
  sPanelID:= edtParam1.Text;
  AddLog('Take Out Report: ' + sPanelID);
  TThread.CreateAnonymousThread(
    procedure begin

      nRes:= g_CommPLC.ECS_TakeOutReport(0,sPanelID);
      if nRes <> 0 then begin
        AddLog('Take Out Report NG ' + IntToStr(nRes));
      end
      else begin
        AddLog('Take Out Report OK');
      end;
    end
  ).Start;

end;

procedure TfrmECSStatus.btnUnitStatusClick(Sender: TObject);
var
  nRes: Integer;
  nMode, nValue: Integer;
begin
  nMode:= StrToInt(Trim(Copy(cboUnitStatus.Text, 1, 2)));
  nValue:= cboValue_Status.ItemIndex; //StrToInt(edtUnitStatusValue.Text);
  AddLog(format('ECS_Operation_Mode: Mode=%d, Value=%d', [nMode, nValue]));
  nRes:= g_CommPLC.ECS_Unit_Status(nMode, nValue);
  if nRes <> 0 then begin
    AddLog('ECS_Operation_Mode NG ' + IntToStr(nRes));
  end
  else begin
    AddLog('ECS_Operation_Mode OK');
  end;
end;

procedure TfrmECSStatus.btnWriteDeviceClick(Sender: TObject);
var
  nRes: Integer;
  nValue: Integer;
begin
  if g_CommPLC = nil then Exit;

  nValue:= StrToInt('$' + edtValue.Text);
  nRes:= g_CommPLC.WriteDevice(edtDevice.Text, nValue);
  if nRes <> 0 then begin
    AddLog('WriteDevice Failed: ' + edtValue.Text );
  end;

end;

procedure TfrmECSStatus.Button1Click(Sender: TObject);
var
nRes : integer;
begin
  nRes := g_CommPLC.ECS_ECSRestart_Test;
    if nRes <> 0 then begin
    AddLog('ECS_ECSRestart_Test Failed: ');
  end;
end;

procedure TfrmECSStatus.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrRefresh.Enabled:= False;
  //Action:= caFree;
end;

procedure TfrmECSStatus.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  //
end;

procedure TfrmECSStatus.FormCreate(Sender: TObject);
var
  sEventName: String;
  i: Integer;
begin
  if g_CommPLC = nil then begin
    Self.Enabled:= false;
    Exit;
  end;

  for i := 0 to 7 do begin
    m_aMESItemValue[i].Channel:= i;
    sEventName:= 'MESEvent.WaitForSingleObject' + IntToStr(i);
    m_aMESItemValue[i].EventHandle:= CreateEvent(nil, False, False, PWideChar(sEventName));
  end;
  Init_Grid;

  btnShowSimulator.Enabled:= g_CommPLC.UseSimulator;
end;

procedure TfrmECSStatus.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to 7 do begin
    CloseHandle(m_aMESItemValue[i].EventHandle);
  end;

  Tag:= 100;
end;

procedure TfrmECSStatus.FormShow(Sender: TObject);
begin
  if g_CommPLC = nil then Exit;

  edtStartAddrEQP.Text:= IntToHex(g_CommPLC.StartAddr_EQP, 4);
  edtStartAddrEQP_W.Text:= IntToHex(g_CommPLC.StartAddr_EQP_W, 4);
  edtStartAddrRobot.Text:= IntToHex(g_CommPLC.StartAddr_ROBOT, 4);
  edtStartAddrRobot_W.Text:= IntToHex(g_CommPLC.StartAddr_ROBOT_W, 4);
  edtStartAddrECS.Text:= IntToHex(g_CommPLC.StartAddr_ECS, 4);
  edtStartAddrECS_W.Text:= IntToHex(g_CommPLC.StartAddr_ECS_W, 4);

  tmrRefresh.Enabled:= True;
end;

procedure TfrmECSStatus.Init_Grid;
var
  i: Integer;
  nAddr: Integer;
  sAddress : string;
begin
  for i:= 0 to grdStatus.RowCount-1 do  begin
    grdStatus.Cells[0, i]:= IntToStr(i-1);
//    for k:= 0 to grdStatus.ColCount-1 do  begin
//      grdStatus.Alignments[k, i] := taCenter;
//    end;
  end;
  grdStatus.Cells[0, 0] := '';

  nAddr:= StrToInt('$' + Common.PLCInfo.Address_EQP);

  grdStatus.Cells[1, 0] := 'EQP' + #10#13 + '(B' + IntToHex(nAddr, 4) + ')';
  grdStatus.Cells[1, 1] := 'ECS' + sLineBreak + 'Restart_ACK';
  grdStatus.Cells[1, 2] := 'Link Test' + sLineBreak + ' Restart_ACK';
  grdStatus.Cells[1, 3] := 'Control Status' + sLineBreak + 'Change Report';
  grdStatus.Cells[1, 4] := 'EQP Status' + sLineBreak + 'Change Report';

  grdStatus.Cells[1, 13] := 'Light' + sLineBreak + 'Alarm Set';
  grdStatus.Cells[1, 14] := 'Light' + sLineBreak + 'Alarm ReSet';
  grdStatus.Cells[1, 15] := 'Heavy' + sLineBreak + 'Alarm Set';
  grdStatus.Cells[1, 16] := 'Heavy' + sLineBreak + 'Alarm ReSet';

  grdStatus.Cells[2, 0] := 'EQP';
  grdStatus.Cells[2, 1] := 'Lost Glass' + sLineBreak + 'Data Request';

//  grdStatus.Cells[2, 3] := 'Inspection' + sLineBreak + 'Data Report';

//  grdStatus.Cells[2, 5] := 'Material' + sLineBreak + 'Matching Report';
  if Common.SystemInfo.OCType = DefCommon.OCType  then
    grdStatus.Cells[2, 6] := 'Take Out' + sLineBreak + 'Report'
  else grdStatus.Cells[2, 8] := 'Take Out' + sLineBreak + 'Report';

//  grdStatus.Cells[2, 9] := 'APD' + sLineBreak + 'Report';




  grdStatus.Cells[3, 0] := 'EQP';
  grdStatus.Cells[3, 1] := 'Position #1 GlassExist';
  grdStatus.Cells[3, 2] := 'Position #2 GlassExist';
  grdStatus.Cells[3, 3] := 'Position #3 GlassExist';
  grdStatus.Cells[3, 4] := 'Position #4 GlassExist';
  grdStatus.Cells[3, 5] := 'Position #5 GlassExist';
  grdStatus.Cells[3, 6] := 'Position #6 GlassExist';
  grdStatus.Cells[3, 7] := 'Position #7 GlassExist';
  grdStatus.Cells[3, 8] := 'Position #8 GlassExist';
  grdStatus.Cells[3, 9] := 'Position #9 GlassExist';
  grdStatus.Cells[3, 10] := 'Position #10 GlassExist';
  grdStatus.Cells[3, 11] := 'Position #11 GlassExist';
  grdStatus.Cells[3, 12] := 'Position #12 GlassExist';
  grdStatus.Cells[3, 13] := 'Position #13 GlassExist';
  grdStatus.Cells[3, 14] := 'Position #14 GlassExist';
  grdStatus.Cells[3, 15] := 'Position #15 GlassExist';
  grdStatus.Cells[3, 16] := 'Position #16 GlassExist';
//  grdStatus.Cells[3, 1] := 'BCR Read Report #1';
//  //grdStatus.Cells[3, 2] := 'BCR Read Report #2';
//  //grdStatus.Cells[3, 3] := 'BCR Read Report #3';
//  //grdStatus.Cells[3, 4] := 'BCR Read Report #4';
//  grdStatus.Cells[3, 5] := 'Inspection Data Report #1';
//  //grdStatus.Cells[3, 6] := 'Inspection Data Report #2';
//  //grdStatus.Cells[3, 7] := 'Inspection Data Report #3';
//  //grdStatus.Cells[3, 8] := 'Inspection Data Report #4';
//  grdStatus.Cells[3, 9] := 'Inspection Data Confirm Ack #1';
//  //grdStatus.Cells[3, 10] := 'Inspection Data Confirm Ack #2';
//  //grdStatus.Cells[3, 11] := 'Inspection Data Confirm Ack #3';
//  //grdStatus.Cells[3, 12] := 'Inspection Data Confirm Ack #4';
//  grdStatus.Cells[3, 13] := 'Glass APD Report';
//  grdStatus.Cells[3, 16] := 'User ID Report';

//  grdStatus.Cells[4, 0] := 'EQP';

  nAddr:= StrToInt('$' + Common.PLCInfo.Address_EQP);
  if Common.SystemInfo.OCType = DefCommon.OCType  then
    nAddr:= nAddr + $C0
  else nAddr:= nAddr + $12;
  grdStatus.Cells[4, 0] := 'EQP' + #10#13 + '(B' + IntToHex(nAddr, 4) + ')';
  grdStatus.Cells[4, 1] := 'Load' + sLineBreak + 'Enable';
  grdStatus.Cells[4, 2] := 'Glass Data Request';
  grdStatus.Cells[4, 5] := 'Load Normal Status';
  grdStatus.Cells[4, 6] := 'Load Request';
  grdStatus.Cells[4, 7] := 'Load Complete Confirm';
  //grdStatus.Cells[5, 14] := 'Ready To Start';
  //grdStatus.Cells[5, 14] := 'Inspection Start Confirm';
  //grdStatus.Cells[5, 15] := 'Reset Count Confirm';
  //grdStatus.Cells[5, 16] := 'Last Product Confirm';

  //grdStatus.Cells[6, 0] := 'EQP';
  grdStatus.Cells[5, 1] := 'Unload' + sLineBreak + 'Enable';
  grdStatus.Cells[5, 2] := 'Glass Data Report';
  grdStatus.Cells[5, 5] := 'Unload Normal Status';
  grdStatus.Cells[5, 6] := 'Unload Request';
  grdStatus.Cells[5, 7] := 'Unload Complete Confirm';

  //grdStatus.Cells[7, 0] := 'EQP';
  grdStatus.Cells[6, 1] := 'Load' + sLineBreak + 'Enable';
  grdStatus.Cells[6, 2] := 'Glass Data Request';
  grdStatus.Cells[6, 5] := 'Load Normal Status';
  grdStatus.Cells[6, 6] := 'Load Request';
  grdStatus.Cells[6, 7] := 'Load Complete Confirm';
  //grdStatus.Cells[7, 14] := 'Ready To Start';
  //grdStatus.Cells[7, 14] := 'Inspection Start Confirm';
  //grdStatus.Cells[7, 15] := 'Reset Count Confirm';
  //grdStatus.Cells[7, 16] := 'Last Product Confirm';

  //grdStatus.Cells[8, 0] := 'EQP';
  grdStatus.Cells[7, 1] := 'Unload' + sLineBreak + 'Enable';
  grdStatus.Cells[7, 2] := 'Glass Data Report';
  grdStatus.Cells[7, 5] := 'Unload Normal Status';
  grdStatus.Cells[7, 6] := 'Unload Request';
  grdStatus.Cells[7, 7] := 'Unload Complete Confirm';


  //Robot
  nAddr:= StrToInt('$' + Common.PLCInfo.Address_Robot);
  grdStatus.Cells[8, 0] := 'Robot' + #10#13 + 'B(' + IntToHex(nAddr, 4) + ')';
  grdStatus.Cells[8, 1] := 'Load' + sLineBreak + 'Noninterference';
  grdStatus.Cells[8, 2] := 'Glass Data Report';
  grdStatus.Cells[8, 3] := 'Load Robot Busy';
  grdStatus.Cells[8, 4] := 'Load Complete';
  grdStatus.Cells[8, 5] := 'Load Normal Status';

  //grdStatus.Cells[10, 0] := 'Robot';
  grdStatus.Cells[9, 1] := 'Unload' + sLineBreak + 'Noninterference';
  grdStatus.Cells[9, 3] := 'Unload Robot' + sLineBreak + 'Busy';
  grdStatus.Cells[9, 4] := 'Unload Complete';
  grdStatus.Cells[9, 5] := 'Unload Normal Status';

  //grdStatus.Cells[10, 14] := 'Inspection Start';
  //grdStatus.Cells[10, 15] := 'Reset Count';
  //grdStatus.Cells[10, 16] := 'Last Product';

  //grdStatus.Cells[11, 0] := 'Robot';
  if StrToInt('$' + Common.PLCInfo.Address_Robot2) <> 0 then begin
    nAddr:= StrToInt('$' + Common.PLCInfo.Address_Robot2);
    grdStatus.Cells[10, 0] := 'Robot' + #10#13 + 'B(' + IntToHex(nAddr, 4) + ')';
  end;

  grdStatus.Cells[10, 1] := 'Load' + sLineBreak + 'Noninterference';
  grdStatus.Cells[10, 2] := 'Glass Data Report';
  grdStatus.Cells[10, 3] := 'Load Robot Busy';
  grdStatus.Cells[10, 4] := 'Load Complete';
  grdStatus.Cells[10, 5] := 'Load Normal Status';

  grdStatus.Cells[11, 1] := 'Unload' + sLineBreak + 'Noninterference';
  grdStatus.Cells[11, 3] := 'Unload Robot Busy';
  grdStatus.Cells[11, 4] := 'Unload Complete';
  grdStatus.Cells[11, 5] := 'Unload Normal Status';

  //grdStatus.Cells[12, 0] := 'Robot';
  //grdStatus.Cells[12, 14] := 'Inspection Start';
  //grdStatus.Cells[12, 15] := 'Reset Count';

  if Common.PLCInfo.InlineGIB then begin
    nAddr:= StrToInt('$' + Common.PLCInfo.Address_ROBOT);
    nAddr:= nAddr + $3F;
    grdStatus.Cells[12, 16] := 'Last Product'  + #10#13 + '(B' + IntToHex(nAddr, 4) + ')';
  end
  else begin
    nAddr:= StrToInt('$1EB0');
    case Common.PLCInfo.EQP_ID of
      33, 34, 35, 36: nAddr:= nAddr + 6;
      37, 38, 39, 40: nAddr:= nAddr + 7;
      41, 42, 43, 44: nAddr:= nAddr + 8;
    end;
    grdStatus.Cells[12, 16] := 'Last Product'  + #10#13 + '(B' + IntToHex(nAddr, 4) + ')';
  end;

  //ECS
  nAddr:= StrToInt('$000');
  grdStatus.Cells[12, 0] := 'ECS' + #10#13 + '(B' + IntToHex(nAddr, 4) + ')';
  grdStatus.Cells[12, 1] := 'ECS Restart' + sLineBreak + '(2 sec)' ;
  grdStatus.Cells[12, 2] := 'Time Set Request' + sLineBreak + '(2 sec)';
  grdStatus.Cells[12, 3] := 'ECS User Login' + sLineBreak +  'Data Send';
  grdStatus.Cells[12, 4] := 'LostPanel'+ sLineBreak + 'Data Request' + sLineBreak +'ACK OK';
  grdStatus.Cells[12, 5] := 'LostPanel'+ sLineBreak + 'Data Request' + sLineBreak +'ACK NG';

//  grdStatus.Cells[13, 5] := 'User ID Report Confirm';
//  grdStatus.Cells[13, 7] := 'Inspection Data  Confirm #1';
//  grdStatus.Cells[13, 9] := 'BCR #1 Read Report Confirm';
//  grdStatus.Cells[13, 11] := '';//'Inspection Data Report Confirm #4';
//  grdStatus.Cells[13, 16] := 'AAB Mode';

//  grdStatus.Cells[13, 9] := ''; //'Inspection Data  Confirm #1';
//  grdStatus.Cells[13, 10] := ''; //'Inspection Data  Confirm #2';
//  grdStatus.Cells[13, 11] := ''; //'Inspection Data  Confirm #3';
//  grdStatus.Cells[13, 12] := ''; //'Inspection Data  Confirm #4';
//  grdStatus.Cells[13, 16] := ''; //'User ID Report Confirm';

  nAddr:= StrToInt('$' + Common.PLCInfo.Address_ECS)+ ((Common.PLCInfo.EQP_ID -3) div 16)*$10;
  grdStatus.Cells[13, 0] := 'ECS' + #10#13 + '(B' + IntToHex(nAddr, 4) + ')';
  grdStatus.Cells[13, ((Common.PLCInfo.EQP_ID + 13 )mod 16)+1] :=
  Format('OC #%d Link',[Common.PLCInfo.EQP_ID - 10])  + sLineBreak + 'Test Request';


  grdStatus.Cells[14, 0] := 'ECS' + #10#13 + '(B' + IntToHex(nAddr + $100, 4) + ')';
  grdStatus.Cells[14, ((Common.PLCInfo.EQP_ID +13 )mod 16)+1] :=
  Format('OC #%d Lost',[Common.PLCInfo.EQP_ID - 10]) + sLineBreak + 'Panel Data Report';


  grdStatus.Cells[15, 0] := 'ECS' + #10#13 + '(B' + IntToHex(nAddr + $200, 4) + ')';
  grdStatus.Cells[15, ((Common.PLCInfo.EQP_ID + 13 )mod 16)+1] :=
  Format('OC #%d Take',[Common.PLCInfo.EQP_ID - 10]) + sLineBreak + 'Out Report_Confirm';



  grdStatus.MergeCells(1, 0, 3, 1);
  grdStatus.MergeCells(4, 0, 4, 1);
  if StrToInt('$' + Common.PLCInfo.Address_Robot2) <> 0 then begin
    grdStatus.MergeCells(8, 0, 2, 1);
    grdStatus.MergeCells(10, 0, 2, 1);
  end
  else grdStatus.MergeCells(8, 0, 4, 1);
  //grdStatus.MergeCells(13, 0, 2, 1);

end;

procedure TfrmECSStatus.SetCellState(nCol, nRow, nDivisioin, nIndex, nBitLoc: Integer);
var
  bState: Boolean;
  nColorOn, nColorOff: TColor;
begin
  if g_CommPLC <> nil then begin
    nColorOff:= clWindow;
    nColorOn:= clLime;
    if nDivisioin = 0 then begin  //EQP
      bState:= g_CommPLC.IsBitOn(g_CommPLC.PollingEQP[nIndex], nBitLoc);
    end
    else if nDivisioin = 1 then begin //Robot
      bState:= g_CommPLC.IsBitOn(g_CommPLC.PollingData[nIndex], nBitLoc);
      nColorOn:= clYellow;
    end
    else if nDivisioin = 2 then begin //ECS
      bState:= g_CommPLC.IsBitOn(g_CommPLC.PollingECS[nIndex], nBitLoc);
    end
    else begin
      bState:= g_CommPLC.IsBitOn(g_CommPLC.PollingCV[nIndex], nBitLoc);
    end;

    //상태 별 셀 컬러 설정
    if bState then begin
      if grdStatus.CellProperties[nCol, nRow].BrushColor <> nColorOn then
        grdStatus.CellProperties[nCol, nRow].BrushColor:= nColorOn;  //clLime
    end
    else begin
     if grdStatus.CellProperties[nCol, nRow].BrushColor <> nColorOff then
       grdStatus.CellProperties[nCol, nRow].BrushColor:= nColorOff; //clWhite;
    end;
  end;
end;

procedure TfrmECSStatus.SetMode(nMode: Integer);
begin
  if nMode = 0 then begin
    btnCloses.Visible:= True;
    pnlTest.Visible:= False;
    Height:= 768;
  end
  else begin
    btnCloses.Visible:= False;
    pnlTest.Visible:= True;
  end;
end;

procedure TfrmECSStatus.MESNotifyEvent(ItemValue: TMESItemValue);
var
  nCh:Integer;
begin
  AddLog(format('MESNotifyEvent Ch=%d ', [ItemValue.Channel]));
  nCh:= ItemValue.Channel;
  //m_aMESItemValue[nCh].Ack := ItemValue.Ack;
  m_aMESItemValue[nCh] := ItemValue;
  SetEvent(m_aMESItemValue[nCh].EventHandle);
end;

procedure TfrmECSStatus.Process_Thread_PCHK(nCh: Integer; sSerial: String);
var
  item: TMESItem;
  nRet: Cardinal;
begin
  AddLog(format('Process_Thread_PCHK %s ', [edtSerial.Text]));
  TThread.CreateAnonymousThread( procedure begin
    item.Kind:= COMMPLC_MES_KIND_PCHK;
    item.NotifyEvent:= MESNotifyEvent;

    item.Value.Channel:= nCh;
    ResetEvent(m_aMESItemValue[nCh].EventHandle);
    item.Value.EventHandle:= m_aMESItemValue[nCh].EventHandle;
    item.Value.SerialNo:= sSerial;

    g_CommPLC.ECS_MES_AddItem(item);

    nRet := WaitForSingleObject(m_aMESItemValue[nCh].EventHandle, 10000);
    case nRet of
      WAIT_OBJECT_0 : begin
        //OK
        if m_aMESItemValue[nCh].Ack = 0 then begin
          AddLog('Process_Thread_PCHK OK');
          AddLog('LCM_ID: ' + m_aMESItemValue[nCh].LCM_ID);
          //AddLog('LCM_ID: ' + g_CommPLC.ECS_GlassData[nCh].LCM_ID);
          AddLog('CarrierID: ' +g_CommPLC.ECS_GlassData[nCh].CarrierID);
        end
        else begin
          AddLog(format('Process_Thread_PCHK NG %d ', [m_aMESItemValue[nCh].Ack]));
        end;
      end;
      WAIT_TIMEOUT  : begin
        AddLog('Process_Thread_PCHK Timeout');
      end
      else begin
        AddLog(format('Process_Thread_PCHK Fail %d ', [nRet]));
      end;
    end;
  end).Start;
end;

procedure TfrmECSStatus.Process_Thread_ZSET(nCh, nBondingType: Integer; sZigID, sPID, sPcbID: String);
var
  item: TMESItem;
  nRet: Cardinal;
begin
  AddLog(format('Process_Thread_ZSET %s ', [edtSerial.Text]));

  TThread.CreateAnonymousThread( procedure begin
    item.Kind:= COMMPLC_MES_KIND_ZSET;

    item.NotifyEvent:= MESNotifyEvent;

    item.Value.Channel:= nCh;
    ResetEvent(m_aMESItemValue[nCh].EventHandle);
    item.Value.EventHandle:= m_aMESItemValue[nCh].EventHandle;

    item.Value.SerialNo:= sPID;
    item.Value.CarrierID:= sZigID;
    item.Value.BondingType:= nBondingType;
    item.Value.PcbID:= sPcbID;

    g_CommPLC.ECS_MES_AddItem(item);

    nRet := WaitForSingleObject(m_aMESItemValue[nCh].EventHandle, 10000);
    case nRet of
      WAIT_OBJECT_0 : begin
        //OK
        if m_aMESItemValue[nCh].Ack = 0 then begin
          AddLog('Process_Thread_ZSET OK');
        end
        else begin
          AddLog(format('Process_Thread_ZSET NG %d ', [m_aMESItemValue[nCh].Ack]));
        end;
      end;
      WAIT_TIMEOUT  : begin
        AddLog('Process_Thread_ZSET Timeout');
      end
      else begin
        AddLog(format('Process_Thread_ZSET Fail %d ', [nRet]));
      end;
    end;
  end).Start;
end;

procedure TfrmECSStatus.Process_Thread_EICR(nCh: Integer; sErrorCode, sInspectionResult: String);
var
  item: TMESItem;
  nRet: Cardinal;
begin
  AddLog(format('Process_Thread_EICR %s ', [edtSerial.Text]));

  TThread.CreateAnonymousThread( procedure begin
    item.Kind:= COMMPLC_MES_KIND_EICR;

    item.NotifyEvent:= MESNotifyEvent;

    item.Value.Channel:= nCh;
    ResetEvent(m_aMESItemValue[nCh].EventHandle);
    item.Value.EventHandle:= m_aMESItemValue[nCh].EventHandle;

    //item.Value.SerialNo:= sPID;
    item.Value.ErrorCode:= sErrorCode;
    //item.Value.CarrierID:= sZigID;
    item.Value.InspectionResult:= sInspectionResult;

    g_CommPLC.ECS_MES_AddItem(item);

    nRet := WaitForSingleObject(m_aMESItemValue[nCh].EventHandle, 10000);
    case nRet of
      WAIT_OBJECT_0 : begin
        //OK
        if m_aMESItemValue[nCh].Ack = 0 then begin
          AddLog('Process_Thread_EICR OK');
        end
        else begin
          AddLog(format('Process_Thread_EICR NG %d ', [m_aMESItemValue[nCh].Ack]));
        end;
      end;
      WAIT_TIMEOUT  : begin
        AddLog('Process_Thread_EICR Timeout');
      end
      else begin
        AddLog(format('Process_Thread_EICR Fail %d ', [nRet]));
      end;
    end;
  end).Start;
end;

procedure TfrmECSStatus.Process_Thread_APDR(nCh: Integer; sInspectionResult: String);
var
  item: TMESItem;
  nRet: Cardinal;
begin
  AddLog(format('Process_Thread_APDR %s ', [edtSerial.Text]));

  TThread.CreateAnonymousThread( procedure begin
    item.Kind:= COMMPLC_MES_KIND_APDR;
    item.NotifyEvent:= MESNotifyEvent;

    item.Value.Channel:= nCh;
    ResetEvent(m_aMESItemValue[nCh].EventHandle);
    item.Value.EventHandle:= m_aMESItemValue[nCh].EventHandle;
    item.Value.InspectionResult:= sInspectionResult;

    g_CommPLC.ECS_MES_AddItem(item);

    nRet := WaitForSingleObject(m_aMESItemValue[nCh].EventHandle, 10000);
    case nRet of
      WAIT_OBJECT_0 : begin
        //OK
        if m_aMESItemValue[nCh].Ack = 0 then begin
          AddLog('Process_Thread_APDR OK');
        end
        else begin
          AddLog(format('Process_Thread_APDR NG %d ', [m_aMESItemValue[nCh].Ack]));
        end;
      end;
      WAIT_TIMEOUT  : begin
        AddLog('Process_Thread_APDR Timeout');
      end
      else begin
        AddLog(format('Process_Thread_APDR Fail %d ', [nRet]));
      end;
    end;
  end).Start;
end;

procedure TfrmECSStatus.tmrRefreshTimer(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TfrmECSStatus.UpdateStatus;
var
  i: Integer;
begin

  //SetCellState(nCol, nRow, nDivisioin, nIndex, nBitLoc: Integer);
  if Common.SystemInfo.OCType = DefCommon.OCType then begin
    for i := 0 to 15 do begin
      //EQP
      SetCellState(1,  i+1, 0, 0,  i); //Status
      SetCellState(2,  i+1, 0, 1,  i); //Special Equipment
      //SetCellState(2,  i+1, 0, 10, i); //Glass Position
      //SetCellState(4,  i+1, 0, 6,  i); //PCHK, EICR
      SetCellState(4,  i+1, 0, 12, i); //Load 0
      SetCellState(5,  i+1, 0, 13, i); //Unload 0
      SetCellState(6,  i+1, 0, 14, i); //Load 1
      SetCellState(7,  i+1, 0, 15, i); //Unload 1
  //    SetCellState(3,  i+1, 0, 8, i); //Unload 1
    end;

    for i := 0 to 7 do begin
      //EQP - Position
      SetCellState(3,  i+1, 0, 7, i); //Glass Position
    end;
  end
  else begin
    for i := 0 to 15 do begin
      //EQP
      SetCellState(1,  i+1, 0, 0,  i); //Status
      SetCellState(2,  i+1, 0, 1,  i); //Special Equipment
      //SetCellState(2,  i+1, 0, 10, i); //Glass Position
      //SetCellState(4,  i+1, 0, 6,  i); //PCHK, EICR
      SetCellState(4,  i+1, 0, 18, i); //Load 0
      SetCellState(5,  i+1, 0, 19, i); //Unload 0
      SetCellState(6,  i+1, 0, 20, i); //Load 1
      SetCellState(7,  i+1, 0, 21, i); //Unload 1
  //    SetCellState(3,  i+1, 0, 8, i); //Unload 1
    end;

    for I := 0 to 7 do
      SetCellState(2,  i+1, 0, 1,  i); //Special Equipment
    for I := 0 to 7 do
      SetCellState(2,  i+8, 0, 6,  i); //Special Equipment

    for i := 0 to 7 do begin
      //EQP - Position
      SetCellState(3,  i+1, 0, 12, i); //Glass Position
    end;


  end;


  for i := 0 to 15 do begin
    //Robot
    SetCellState(8,  i+1, 1, 0, i);
    SetCellState(9, i+1, 1, 1, i);
    SetCellState(10, i+1, 1, 2, i);
    SetCellState(11, i+1, 1, 3, i);
  end;

  for I := 0 to 4 do
    SetCellState(12, i+1, 2, 3, i);  // ECS Status & Data (ECS → All)
    //Link Test Request
//    (g_CommPLC.EQP_ID - 11)
  for I := 0 to 15 do begin
    SetCellState(13, i+1, 2, 0, i); //Link Test Request
    SetCellState(14, i+1, 2, 1, i); //Link Test Request
    SetCellState(15, i+1, 2, 2, i); //Link Test Request
  end;

end;

end.
