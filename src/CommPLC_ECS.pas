unit CommPLC_ECS;
{
  MELSEC PLC 통신
  ActUtlType 라이브러리 사용(ActUtlType.dll)
  실제 PLC 데이터 통신 처리는 여기에서 처리
  GUI 관련 사항만 MSG를 수신한 GUI에서 처리한다.
  *** Simulator 사용 가능;
  ECS 연동 기능
    ECS-Equipment Communication Specification_MELSEC for Module_Korean_v0.4(3).pdf
    ECS-Equipment Interlock Specification for Module_Korean_v0.1(3).pdf
  20201202 - kg.jo
}
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,DefCommon,  System.Classes, System.AnsiStrings
  , SyncObjs, System.DateUtils, Vcl.Forms, {DllActUtlType64Com,} CommTCP_PLC, IdTCPClient,IdTCPServer, Generics.Collections,CommonClass;

{$I Common.inc}
const
  MSGTYPE_COMMPLC = 200;

  COMMPLC_MODE_NONE          = 2000;
  COMMPLC_MODE_CONNECT       = COMMPLC_MODE_NONE + 1;
  COMMPLC_MODE_HEARTBEAT     = COMMPLC_MODE_NONE + 2;
  COMMPLC_MODE_CHANGE_ROBOT  = COMMPLC_MODE_NONE + 3;
  COMMPLC_MODE_CHANGE_ECS    = COMMPLC_MODE_NONE + 4;
  COMMPLC_MODE_EVENT_ROBOT   = COMMPLC_MODE_NONE + 5;
  COMMPLC_MODE_EVENT_ECS     = COMMPLC_MODE_NONE + 6;
  COMMPLC_MODE_LOG_ROBOT     = COMMPLC_MODE_NONE + 7;
  COMMPLC_MODE_LOG_ECS       = COMMPLC_MODE_NONE + 8;
  COMMPLC_MODE_LOGIN         = COMMPLC_MODE_NONE + 9;
  COMMPLC_MODE_SHOW_MES      = COMMPLC_MODE_NONE + 10;

  COMMPLC_PARAM_NONE = 0;
  COMMPLC_PARAM_LOADCOMPLETE     = COMMPLC_PARAM_NONE+ 1;
  COMMPLC_PARAM_GALSSDATA_REPORT = COMMPLC_PARAM_NONE + 2;
  COMMPLC_PARAM_LOADGLASSDATA    = COMMPLC_PARAM_NONE + 3;
  COMMPLC_PARAM_LOADBUSY         = COMMPLC_PARAM_NONE+ 4;


  COMMPLC_PARAM_UNLOADCOMPLETE   = COMMPLC_PARAM_NONE + 11;
  //COMMPLC_PARAM_UNLOADCOMPLETE_OFF = COMMPLC_PARAM_NONE + 12;
  COMMPLC_PARAM_UNLOADBUSY       = COMMPLC_PARAM_NONE + 13;

  COMMPLC_PARAM_INSPECTION_START = 100;
  COMMPLC_PARAM_RESET_COUNT = 101;
  COMMPLC_PARAM_LAST_PRODUCT = 102;
  COMMPLC_PARAM_DOOR_OPENED = 103;
  COMMPLC_PARAM_AAB_MODE    = 104;
  COMMPLC_PARAM_ADDLOG = 200;
  COMMPLC_PARAM_INTERFACE_ERROR = 201;


  COMMPLC_ROBOT_DATASIZE = 4; //Polling Data Size
  COMMPLC_ECS_DATASIZE   = 3; //Polling Data Size

{$IFDEF INSPECTOR_OC}
  COMMPLC_EQP_DATASIZE   = 16; //Polling Data Size
{$ELSE}
  COMMPLC_EQP_DATASIZE   = 22; //Polling Data Size // ROBOT 연결 영역 때문에
{$ENDIF}
  COMMPLC_CV_DATASIZE   = 1; //Polling Data Size
  COMMPLC_COMMON_DATASIZE = 1;

  COMMPLC_UNIT_STATE_ONLINE = 0;
  COMMPLC_UNIT_STATE_AUTO = 5;
  COMMPLC_UNIT_STATE_BCR = 6;
  COMMPLC_UNIT_STATE_RUN = 8;
  COMMPLC_UNIT_STATE_IDLE = 9;
  COMMPLC_UNIT_STATE_DOWN = 10;
  COMMPLC_UNIT_STATE_GLASS_PROCESS = 11;
  COMMPLC_UNIT_STATE_GLASS_EXIST = 12;
  COMMPLC_UNIT_STATE_PREVIOUS_TRANSFER_ENABLE = 13;

  COMMPLC_MES_KIND_PCHK = 0;
  COMMPLC_MES_KIND_EICR = 1;
  COMMPLC_MES_KIND_APDR = 2;
  COMMPLC_MES_KIND_ZSET = 3;

  COMMPLC_ALARM_LIGHT = 0;
  COMMPLC_ALARM_HEAVY = 1;

  COMMPLC_CH_12 = 0;
  COMMPLC_CH_34 = 1;

  COMPLC_SIG_BUSY_LOAD1 = 0;
  COMPLC_SIG_BUSY_LOAD2 = 0;
  COMPLC_SIG_BUSY_UNLOAD1 = 0;
  COMPLC_SIG_BUSY_UNLOAD2 = 0;
type

{$IFNDEF GUIMESSAGE}
  {$DEFINE GUIMESSAGE}
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

  TECSReply = (erNone=0, erCarrierID, erPCHK, erAPDR); //ECS 응답 대기 종류

  /// <summary> ECS Glass Data Structure. 참조 Melsec사양 4.1 - ReadDeviceBlock이 Integer라 사용 못함</summary>
  TECSGlassBuff = record
    //Glass Data 는 48 Word로 구성된다.
    LOT_ID: array [0..7] of WORD; //8 Word( 16 Char)
    ProcessingCode: array [0..3] of WORD; //4 Word( 8 Char)
    LOTSpecificData: array [0..3] of WORD;
    RecipeNumber: WORD;
    GlassType: WORD;
    GlassCode: WORD;
    GlassID: array [0..7] of WORD; //8 Word( 16 Char)
    GlassJudge: WORD;  //'P'/'F'
    GlassSpecificData: array [0..3] of WORD;
//    GlassAddData: array [0..5] of WORD;
//    PreviousUnitProcessing: array [0..3] of WORD;
    PreviousUnitProcessing: array [0..7] of WORD;
    GlassProcessingStatus: array [0..7] of WORD;
//    GlassRoutingData: array [0..2] of WORD;
    PCZTCode: WORD;
    PCZTID: array [0..7] of WORD; //8 Word( 16 Char)
  end;

  /// <summary> ECS Glass Data Structure. 실처리 보고나 Load/Unload 시 전달정보. 참조 Melsec사양 4.1</summary>
  TECSGlassData = record
    //Glass Data 는 48 Word로 구성된다.
    CarrierID: String; //8 Word( 16 Char)
    ProcessingCode: String; //4 Word( 8 Char)
    LOTSpecificData: array [0..3] of Integer;
    RecipeNumber: Integer;
    GlassType: Integer;
    GlassCode: Integer;
    GlassID: String; //8 Word( 16 Char)
    GlassJudge: Integer;  //'G'/'N' 'S'
    GlassSpecificData: array [0..3] of Integer;
    //    GlassAddData: array [0..5] of WORD;
//    PreviousUnitProcessing: array [0..3] of WORD;
    PreviousUnitProcessing: array [0..7] of Integer;
    GlassProcessingStatus: array [0..7] of Integer;
//    GlassRoutingData: array [0..2] of WORD;
//    GlassAddData: array [0..5] of Integer;
//    PreviousUnitProcessing: array [0..3] of Integer;
//    GlassProcessingStatus: array [0..2] of Integer;
//    GlassRoutingData: array [0..2] of Integer;
    MateriID : String;
    LCM_ID: String;
    PCZTCode: Integer;
    //PCZTID: String; //8 Word( 16 Char)
  end;

  /// <summary> ECS Timer Data</summary>
  TECSTimeData = record
    Year, Month, Day, Hour, Minute, Second: WORD;
  end;

  /// <summary> ECS Alarm Que Item</summary>
  TAlarmItem = record
    AlarmType: Integer;
    AlarmCode: Integer;
    AlarmValue: Integer;
  end;


  /// <summary> ECS MES Item Value</summary>
  TMESItemValue = record
    Channel: Integer;
    SerialNo: String;
    CarrierID: String;
    ErrorCode: String;
    InspectionResult: String;
    BondingType: Integer;
    PcbID: String;
    Time_Start: TDateTime;
    Time_End: TDateTime;
    TactTime: Integer;
    SendData: String;
    LCM_ID: String; //PCHK 응답 코드
    //Return
    Ack: Integer; //0=OK, other NG
    EventHandle: HWND;
  end;

  TMESNotifyEvent = procedure(item: TMESItemValue) of object;

  /// <summary> ECS MES Que Item</summary>
  TMESItem= record
    Kind: Integer;
    NotifyEvent: TMESNotifyEvent;
    Value: TMESItemValue;
  end;

  /// <summary> ECS Alarm List (Que)</summary>
  TThreadSafeQue<T> = class
  private
    m_Queue: TQueue<T>;
    //m_Lock: TObject;
  public
    Working: Boolean; //현재 큐 아이템 진행 중.
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Enqueue(const aItem: T);
    function Dequeue: T; overload;
    function Dequeue(out aItem: T): boolean; overload;
    function ItemCount: Integer;
    function IsEmpty: boolean;
    function Lock: TQueue<T>;
    procedure Unlock;
  end;



  /// <summary> PLC 통신 쓰레드</summary>
  TCommPLCThread = class(TThread)
  private
    m_ResultRobot : integer;
    m_ResultECS   : integer;
    m_ResultEQP    : Integer;
    m_ResultCV    : Integer;
    m_szDevice : string;
    m_nSize: Integer;
    m_lplData : Integer;

//    m_ActUtl: TActUtlType64;
    //m_ActUtl :TDLLActUtlType64;
    m_ActUtl : TCommTCP;
    m_nStationNumber: Integer;
    m_bOpend: Boolean;
    m_hECSEvent: HWND;
    m_csWrite: TCriticalSection;
    m_csLog: TCriticalSection;
    m_nStop: Integer;
    m_slLog: TStringList;
    m_dtSaveLog: TDateTime;
    m_sLogPath: String;
    m_TimeDataECS: TECSTimeData;
    m_AlarmQue: TThreadSafeQue<TAlarmItem>;
    m_MESQue: TThreadSafeQue<TMESItem>;
    m_nLastAlarmTick: Cardinal;
    m_nLastMESTick: Cardinal;
    m_nLinkTestTick: Cardinal;
    m_nRobotDataSize : Integer; // GIB 및 OC ROBOT 영역 Size 가변적
    //m_aGlassData: array [0..7] of TECSGlassData; //채널별 GlassData 저장
    procedure AddLog(sLog: String; bSave: Boolean=false);
    procedure SaveLog(dtSave: TDateTime);
    procedure SendMessageMain(nMsgMode, nCh, nParam, nParam2: Integer; sMsg: String; pData:Pointer=nil);
    procedure SendMessageTest(nMsgMode, nCh, nParam, nParam2: Integer; sMsg: String; pData: Pointer=nil);
    procedure OpenPLC;
    procedure ClosePLC;
    function WriteData: Integer;
    procedure Set_LogPath(sValue: String);
    function GetDataValue(inx: Integer): Integer;
    procedure Read_PollingData;
    procedure Process_RobotData;
    procedure Process_CVData;
    procedure Process_ECSData;

    procedure Read_ECS_GlassData(nCh: Integer);
    /// <summary> 로봇의 Glass Data를 읽어서 배열에 저장</summary>
    procedure Read_ROBOT_GlassData(nCh: Integer);
    procedure Process_ROBOT_GlassData_Report(nCh: Integer);
    procedure Process_ROBOT_LoadComplete(nCh: Integer);
    procedure Process_ROBOT_LoadComplete_Off(nCh: Integer);
    procedure Process_ROBOT_LoadBusy_On(nCh: Integer);
    procedure Process_ROBOT_LoadBusy_Off(nCh: Integer);
    procedure Process_ROBOT_UnloadComplete(nCh: Integer);
    procedure Process_ROBOT_UnloadComplete_Off(nCh: Integer);
    procedure Process_ROBOT_UnloadBusy_On(nCh: Integer);
    procedure Process_ROBOT_UnloadBusy_Off(nCh: Integer);
    procedure Process_ROBOT_InspectionStart(nCh, nValue: Integer);
    procedure Process_ROBOT_ResetCount(nCh, nValue: Integer);
    procedure Process_ROBOT_LastProduct(nCh, nValue: Integer);
    procedure Process_ROBOT_Normal_Off(nCh, nValue: Integer);

    procedure Process_AlarmQue;
    procedure Process_MESQue;
    function ConvertStrFromPLC(nLen: Integer; var naData: array of Integer): String;
    procedure ConvertStrToPLC(sData: string; nLen: Integer; var naData: array of Integer);
    procedure ConvertBlockToGlassData(var naGlassData: array of Integer; var AGlassData: TECSGlassData);
    procedure ConvertGlassDataToBlock(var AGlassData: TECSGlassData; var naGlassData: array of Integer);
    procedure PulseDevice(const szDevice: String; nDelay: Integer);
    procedure PulseDeviceBit(const szDevice: String; nBitLoc, nDelay: Integer);
    function WaitSignal(const szDevice: String; nValue: Integer; nWaitTime: Cardinal): Cardinal;
    function WaitSignalBit(const szDevice: String; nBitLoc, nValue: Integer; nWaitTime: Cardinal): Cardinal;
    /// <summary> PLC HeartBeat 처리</summary>
    procedure WriteHeatBeat;
    /// <summary> ECS에서 시간 값을 읽어 시간 동기화</summary>
    procedure ReadTimeData;
    procedure CreatePLC;

  protected
    procedure DoEvent;
    /// <summary> Synchronize Main Thread </summary>
    procedure SyncThread;
    procedure Execute; override;
  public
    /// <summary> SendMessage에서 사용할 Handle</summary>
    MessageHandle: THandle;
    MessageHandleTest1: THandle;
    MessageHandleTest2: THandle;
    /// <summary> SendMessage에서 사용할 MsgType</summary>
    MessageType: Int64;
    /// <summary> 폴링 간격. Runtime 변경 가능</summary>
    PollingInterval: Int64;
    /// <summary> PLC에서 폴링한 데이터. Read only </summary>
    PollingData: array of Integer;
    /// <summary> PLC에서 폴링한 이전  데이터. Read only </summary>
    PollingDataPre: array of Integer;
    /// <summary> PLC에서 폴링한 데이터. Read only </summary>
    PollingECS: array of Integer;
    /// <summary> PLC에서 폴링한 이전  데이터. Read only </summary>
    PollingECSPre: array of Integer;
    /// <summary> PLC에서 폴링한 데이터. Read only </summary>
    PollingEQP: array of Integer;
    /// <summary> PLC에서 폴링한 이전  데이터. Read only </summary>
    PollingEQPPre: array of Integer;

    /// <summary> PLC에서 폴링한 데이터. Read only </summary>
    PollingCV: array of Integer;
    /// <summary> PLC에서 폴링한 이전  데이터. Read only </summary>
    PollingCVPre: array of Integer;
    /// <summary> Robot Door Opend 검사 </summary>
    PollingDoorOpened: Int64;
    /// <summary> 실제 PLC 대신 내분 Simulation 창을 이용한 데이터 처리</summary>
    UseSimulator: Boolean;

    /// <summary> EQP ID 장비 번호. 33 부터 시작</summary>
    EQP_ID: Integer;
    /// <summary> PLC 시작 주소Bit - EQP</summary>
    StartAddr_EQP: Integer;
    /// <summary> PLC 시작 주소Bit- ECS</summary>
    StartAddr_ECS: Integer;
    /// <summary> PLC 시작 주소Bit- ROBOT</summary>
    StartAddr_ROBOT: Integer;
    /// <summary> PLC 시작 주소Word - EQP</summary>
    StartAddr_EQP_W: Integer;
    /// <summary> PLC 시작 주소Word - ROBOT</summary>
    StartAddr_ROBOT_W: Integer;
    /// <summary> PLC 시작 주소Word - ECS</summary>
    StartAddr_ECS_W: Integer;
    /// <summary> /// Door Open 주소 /// </summary>
    StartAddr_ROBOT_DOOR_BIT : Integer;

    /// <summary> PLC 시작 주소Bit- EQP2</summary>
    StartAddr2_EQP: Integer;
    /// <summary> PLC 시작 주소Bit- ECS2</summary>
    StartAddr2_ECS: Integer;
    /// <summary> PLC 시작 주소Bit- ROBOT2</summary>
    StartAddr2_ROBOT: Integer;
    /// <summary> PLC 시작 주소Word - EQP2</summary>
    StartAddr2_EQP_W: Integer;
    /// <summary> PLC 시작 주소Word - ROBOT2</summary>
    StartAddr2_ROBOT_W: Integer;
    /// <summary> PLC 시작 주소Word - ECS2</summary>
    StartAddr2_ECS_W: Integer;

    /// <summary> 연결 시도 실패 Timeout</summary>
    ConnectionTimeout: Cardinal;
    /// <summary> ECS 명령(PCHK, EICR 등) Timeout</summary>
    ECS_Timeout: Cardinal;
    /// <summary> 연결 시도 실패 발생</summary>
    ConnectionError: Boolean;

    /// <summary> Log 누적 라인 수 - 초과 될 경우 저장</summary>
    LogAccumulateCount : Integer;
    /// <summary> Log 누적 시간(초단위) - 초과 될 경우 저장</summary>
    LogAccumulateSecond : Integer;
    /// <summary>Stage 번호로  Main에서 Turn 완료 후 설정 </summary>


    StageNo: Integer;
    GlassData: array [0..8] of TECSGlassData;
    ECS_GlassData: array [0..8] of TECSGlassData; //채널별 GlassData 저장
    ECS_LCM_ID: array [0..7] of String; //채널별 LCMID 저장
    UnloadOnly: array [0..3] of Boolean; //이번 과정이Unload만 한 경우
    RequestState_Load: array [0..3] of Integer;
    RequestState_Unload: array [0..3] of Integer;
    Logined: Boolean; //로그인 여부
    IgnoreConnect: Boolean; //PLC 연결 무시 모드 여부 - 연결 재시도 여부
    InlineGIB: Boolean; //Inline GIB 장비 여부
    constructor Create(hMsgHandle : THandle; nMsgType, nStationNumber: Integer; bUseSimulator: Boolean=False);
    destructor Destroy; override;
    /// <summary> Simulation 사용 시 창 보이기</summary>
    procedure ShowSimulator;
    procedure ShowModalSimulator;
    procedure StopThread;
    procedure SetEQPID(nEQP_ID: Integer);
    procedure SetStartAddress(nStartAddr_EQP, nStartAddr_ECS, nStartAddr_ROBOT, nStartAddr_ROBOT2,
      nStartAddr_EQP_W, nStartAddr_ECS_W, nStartAddr_ROBOT_W, nStartAddr_ROBOT_W2, nStartAddr_ROBOT_DOOR: Int64);
    /// <summary> PLC에서  데이터 읽기 </summary>
    procedure SaveGlassData(sFileName: String);
    procedure LoadGlassData(sFileName: String);



    function ReadDevice( szDevice: String; var lplData: Integer; bSaveLog : Boolean = True): integer;
    /// <summary> PLC에 데이터 쓰기</summary>
    function WriteDevice( szDevice: String;  nData: Integer; bSaveLog : Boolean = True): integer;


    /// <summary> PLC에서 비트 값 읽기</summary>
    function ReadDeviceBit( szDevice: String; nBitLoc:Integer; var lplData: Integer): integer;
    /// <summary> PLC에 비트 값 쓰기</summary>
    function WriteDeviceBit( szDevice: String; nBitLoc, nValue: Integer; bSaveLog : Boolean = True): integer;
    /// <summary> PLC에서 블럭 데이터 읽기 </summary>
//    function ReadDeviceBlock(const szDevice: String; lSize: Integer; out lplData: Integer): integer;
    function ReadDeviceBlock( szDevice: String; lSize: Integer;var  lplData,nReturn: Integer; bSaveLog : Boolean = True): Integer;
    /// <summary> PLC에 블럭 쓰기</summary>
    function WriteDeviceBlock( szDevice: String; lSize: Integer; var lplData: Integer): integer;
  /// <summary> PLC에서 문자열 데이터 읽기 </summary>
    function ReadString( szDevice: String; nAddress, nLen: Integer): String;
    /// <summary> PLC에 문자열 데이터 쓰기 </summary>
    function WriteString( szDevice: String; sValue: String): Integer;
    /// <summary> PLC에서 버퍼읽기 - 아직 준비되지 않음</summary>
    function ReadBuffer(lStartIO: Integer; lAddress: Integer; lSize: Integer; var lpsData: Smallint): Integer;
    /// <summary> PLC에 버퍼쓰기 - 아직 준비되지 않음</summary>
    function WriteBuffer(lStartIO: Integer; lAddress: Integer; lSize: Integer; var lpsData: Smallint): Integer;
    /// <summary> PLC에 GlassData 쓰기</summary>
    function WriteGlassData( szDevice: String; var AGlassData: TECSGlassData):Integer;

    /// <summary> PLC에서 TactTime 값 읽기 </summary>
    function ReadTactTime(nChannel: Integer): Integer;
    /// <summary> PLC에서 현재 시간읽기- 시간 동기화에 사용 </summary>
    function ReadClockData(out lpsYear: Smallint; out lpsMonth: Smallint; out lpsDay: Smallint;
                          out lpsDayOfWeek: Smallint; out lpsHour: Smallint;
                          out lpsMinute: Smallint; out lpsSecond: Smallint): Integer;



    /// <summary>Glass Data 쓰기</summary>
    function ECS_GlassData_Report(nCH : Integer; var AGlassData: TECSGlassData): Integer;
    /// <summary> ECS를 통해 UCHK 데이터 읽기</summary>
    function ECS_UCHK(sUserID: String): Integer;
    /// <summary> ECS를 통해 PCHK 데이터 읽기</summary>
    function ECS_PCHK(nCh: Integer; sSerial: String): Integer;
    /// <summary> ECS를 통해 ZSET 데이터 읽기</summary>
    function ECS_ZSET(nCh: Integer; nBondingType: Integer; sZigID, sPID, sPcbID: String; out lplData: Integer): Integer;
    /// <summary> ECS를 통해 Defect Code 보고</summary>
    function ECS_DEFECT_CODE(sPID, sGLSCode, sGLSJudge, sCode, sComment: String; out sValue: String): Integer;
    /// <summary> ECS를 통해 Defect Code 보고</summary>
    function ECS_EICR(nCh: Integer; sLCM_ID, sErrorCode: String; sInpResult:String): Integer;
    /// <summary> ECS를 통해 APD 데이터 보고</summary>
    function ECS_APDR(nCh: Integer; sInspectionResult: String): Integer;
    /// <summary> 큐에 Alarm을 추가. - 쓰레드에서 Alarm Report 처리</summary>
    function ECS_Alarm_Add(nAlarmType, nAlarmCode, nOnOff:Integer): Integer;
    /// <summary> ECS를 통해 Alarm Report</summary>
    function ECS_Alarm_Report(nAlarmType, nAlarmCode, nOnOff:Integer): Integer;
    /// <summary> ECS에 장비 상태(mode) 보고</summary>
    function ECS_Unit_Status(nMode:Integer; nValue: Integer): Integer;
    /// <summary> ECS에 Stage 위치</summary>
    ///

    function ECS_TakeOutReport(nCH : Integer; sPanelID: String): Integer;
    function ECS_NormalOperation(sGlassID: String): Integer;
    function ECS_Stage_Position(nStage:Integer): Integer;
    function ECS_Accessory_Unit_Status(nStage, nValue, nAlarmCode: Integer): Integer;
    function ECS_MES_AddItem(item: TMESItem): Integer;
    function ECS_IonizerStatus(nIndex: Integer; nValue: Integer): Integer;
    function ECS_ModelChange_Request(nIndex: Integer): Integer;
    /// <summary> ECS에 장비의 존재 여부</summary>
    function ECS_Glass_Position(nCh: Integer; bExist: Boolean): Integer;
    function ECS_Glass_PositionAll(naExists: array of Integer): Integer;
    function ECS_Glass_Processing(bProcessing: Boolean): Integer;
    function ECS_Glass_Exist(nExistCount, nUseCount: Integer): Integer;
    function ECS_Lost_Glass_Request(sGlassID: String; nGlassCode, nRequestOption: Integer; nCh : integer = DefCommon.CH1): Integer;
    function ECS_Change_Glass_Report(AGlassData: TECSGlassData): Integer;
    function ECS_Scrap_Glass_Report(AGlassData: TECSGlassData; sScrapCode: String): Integer;
    function ECS_Status_Mode(nMode:Integer; nValue: Integer): Integer;

    function ECS_ECSRestart_Test: Integer;
    function ECS_Link_Test: Integer;
    function ECS_WriteTactTime(nTactTimeMS: Integer): Integer;
    function ITC_AllChNormalStatusOnOff(nOnOff : Integer):integer;

    /// <summary> Robot측에 Load 요청</summary>
    function ROBOT_Load_Request(nCh: Integer): Integer;
    /// <summary> Robot측에 Unload 요청</summary>
    function ROBOT_Unload_Request(nCh: Integer): Integer;
    /// <summary> Robot측에 Exchange 요청</summary>
    ///  <param>nCh 0 = ch 1,2, 1= ch 3,4 </param>
    function ROBOT_Exchange_Request(nCh: Integer): Integer;
    // Added by sam81 2023-05-04 오후 1:33:49
    function EQP_UnloadBeforeCh(nJig, nCh, nOnOff : integer) : integer;
    // Added by sam81 2023-05-04 오후 1:33:53
    function EQP_SkipCh(nJig, nCh, nSkip : Integer):integer;
    function ROBOT_ReadyToStart_Request(nCh, nReady: Integer): Integer;
    /// <summary> Robot측의 Glass데이터를 Unload영역으로 복사. 2 channel</summary>
    function ROBOT_Copy_GlassData: Integer;
    /// <summary> ECS측에 보고하는 데이터 클리어</summary>
    function EQP_Clear_ECS_Area: Integer;
    /// <summary> Robot측에 요청하는 데이터 클리어. Normal만 살아 있도록</summary>
    function EQP_Clear_ROBOT_Request(nCH : Integer): Integer;
    /// <summary> 각 장비의 처리 후 검사 채널 번호와 호기 번호를 갱신
    /// </summary>
    function SetGlassData_Previous_Unit_Processing(var GlassData: TECSGlassData; nValue: Integer): Integer;
    function SetGlassData_Previous_Unit_Processing_GIB(var GlassData: TECSGlassData; nCH,nABBCount: Integer): Integer;

    /// <summary> 각 장비의 처리 결과를 나타내는 것으로 처리 결과가 NG일 경우 상태 Bit를 ‘On’시킨다.
    /// Bit ~ 8 Bit : 진행 EQP No. (Bit 4개 조합 : 1~15)
    /// POCB COMPENSATION #1 ~ #12
    ///  nSeq: 1차검사, 2차검사, 3차검사
    /// </summary>
    function SetGlassData_Processing_Status(var GlassData: TECSGlassData; nSeq: Integer; nBitCount: Integer = 4): Integer;
    function SetGlassData_Processing_Status_GIB(var GlassData: TECSGlassData; nCH,nABBCount: Integer): Integer;
    function SetGlassData_ContactNG(var GlassData: TECSGlassData; nValue: Integer): Integer;
    function SetGlassData_CheckRLogistics(var GlassData: TECSGlassData; nValue: Integer): Integer;
    function SetGlassData_JudgCode(var GlassData: TECSGlassData; nValue: Integer): Integer;
    function GetGlassDataString(var AGlassData: TECSGlassData): String;
    function GetGlassData_Processing_Status(var GlassData: TECSGlassData; var nSeq: Integer; nBitCount: Integer = 4): Integer;
    function IsBitOn(var nData: Integer; nLoc: Integer): Boolean; overload;
    function IsBitOn(nDivision, nIndex, nBitLoc: Integer): Boolean; overload;

    function IsBitOn_EQP(nIndex: Integer): Boolean;
    function IsBitOn_Robot(nIndex: Integer): Boolean;
    function IsBitOn_ECS(nIndex: Integer): Boolean;
    function IsBusy_Robot(nCH : Integer): Boolean;
    function IsBusy_Robot_Each(nCH : Integer): Boolean;
    function IsRequest_Robot: Boolean;
    function IsGlassData_Robot(nCH : integer) : Boolean;
//    function IsLoadRequest_Robot: Boolean;
    function IsLoadRequest_Robot(nCH : integer): Boolean;
//    function IsUnloadRequest_Robot: Boolean;
    function IsUnloadRequest_Robot(nCH :Integer): Boolean;
    function Get_Bit(var nData: Integer; nLoc: Integer): Integer;
    function Set_Bit(var nData: Integer; nLoc, Value: Integer): Integer;

    property DataValue[inx: Integer]: Integer read GetDataValue;
    property Connected: Boolean read m_bOpend;
    property LogPath: String read m_sLogPath write Set_LogPath;
  end;

var
  g_CommPLC: TCommPLCThread;

implementation

uses 
	PlcSimluateForm,ControlDio_OC; //, CommonClass;

const
  COMMPLC_ECS_TIMEOUT = 3000;
{ TCommPLCThread }

procedure TCommPLCThread.AddLog(sLog: String; bSave: Boolean);
var
  dtNow: TDateTime;
begin
  if m_nStop = 1 then Exit;

  dtNow:= Now;
  m_csLog.Enter;

  if HourOf(m_dtSaveLog) <> HourOf(dtNow) then SaveLog(m_dtSaveLog); //시간 변경된 경우 이전 File로 저장
  if bSave and (sLog = '') then begin
    //단순 저장 요청
  end else begin
    //저장 요청이 아닌 경우Log 추가
    m_slLog.Add(FormatDateTime('HH:NN:SS.ZZZ => ', dtNow) + sLog);
  end;


  //로그 라인수가 누적 라인수 초과이거나누적시간(초) 초과인 경우File로 저장
  if (m_slLog.Count > LogAccumulateCount) or (SecondsBetween(dtNow, m_dtSaveLog) > LogAccumulateSecond) or bSave then begin
    SaveLog(dtNow);
  end;
  m_csLog.Leave;
end;

procedure TCommPLCThread.SaveLog(dtSave: TDateTime);
var
  sFileName: String;
  sDir: String;
  logFile: TextFile;
begin
  if m_slLog.Count = 0 then Exit;

  sDir:= m_sLogPath + FormatDateTime('YYYYMMDD', dtSave);
  ForceDirectories(sDir);
  sFileName:=  sDir + '\' + format('CommPLC_%s.txt',[FormatDateTime('YYYYMMDDHH', dtSave)]);
  AssignFile(logFile, sFileName);
  try
    try
      {$I-}
      if FileExists(sFileName) then Append(logFile) else Rewrite(logFile);

      WriteLn(logFile, Trim(m_slLog.Text));

      //m_csLog.Acquire;
      m_slLog.Clear;
      //m_csLog.Release;
      m_dtSaveLog:= dtSave;
      {$I+}
    except
    end;
  finally
    CloseFile(logFile);
  end;
end;

constructor TCommPLCThread.Create(hMsgHandle: THandle; nMsgType, nStationNumber: Integer; bUseSimulator: Boolean);
var
  nRet,ntest: Integer;
  sEventName : WideString;
begin
  MessageHandle:= hMsgHandle;
  MessageType:= nMsgType;
  UseSimulator:= bUseSimulator;
  m_nStationNumber:= nStationNumber;
  m_slLog:= TStringList.Create;
  m_csWrite:= TCriticalSection.Create;
  m_csLog:= TCriticalSection.Create;
  //동기화 작업에 사용할 이벤트
  sEventName:= Format('TCommPLCThread.WaitECSEvent%d', [MessageHandle]);
  m_hECSEvent:= CreateEvent(nil, False, False, PWideChar(sEventName));

  PollingInterval:= 500;
  ConnectionTimeout:= 10000;
  ECS_Timeout:= 10000;
  ConnectionError:= False;
  if Common.PLCInfo.InlineGIB then begin
    m_nRobotDataSize := 8; // GIB는 각 채널 별 interlock 맵 사용
  end
  else begin
    m_nRobotDataSize := 4;
  end;


  //폴링 데이터 배열
  SetLength(PollingData, m_nRobotDataSize);
  SetLength(PollingDataPre, m_nRobotDataSize);
  SetLength(PollingECS, COMMPLC_ECS_DATASIZE+1);
  SetLength(PollingECSPre, COMMPLC_ECS_DATASIZE+1);
  SetLength(PollingEQP, COMMPLC_EQP_DATASIZE);
  SetLength(PollingEQPPre, COMMPLC_EQP_DATASIZE);

  SetLength(PollingCV, COMMPLC_CV_DATASIZE);
  SetLength(PollingCVPre, COMMPLC_CV_DATASIZE);
  if Common.PLCInfo.InlineGIB then begin
    PollingDoorOpened := 1; // B접점
  end
  else begin
    PollingDoorOpened := 0; // A접점
  end;

  m_AlarmQue:= TThreadSafeQue<TAlarmItem>.Create;
  m_MESQue:= TThreadSafeQue<TMESItem>.Create;
  m_nLastAlarmTick:= 0;
  m_nLastMESTick:= 0;

  m_sLogPath:= ExtractFilePath(Application.ExeName) + '\Log\CommPLC\';
  ForceDirectories(m_sLogPath);
  LogAccumulateCount:= 30;
  LogAccumulateSecond:= 10;
  Logined:= False;
  IgnoreConnect:= False;
  InlineGIB:= False;

  AddLog('========================================');
  AddLog(format('[Create] nStationNumber=%d, UseSimulator=%d', [nStationNumber, ord(bUseSimulator)]));
  if UseSimulator then
    CreatePLC;

  AddLog('OpenPLC 2');
  OpenPLC;

  inherited Create(True);
end;

procedure TCommPLCThread.CreatePLC;
begin
  if UseSimulator then
  begin
    if frmPlcSimulate = nil then begin
      frmPlcSimulate:= TfrmPlcSimulate.Create(nil);
    end;
  end
  else begin
    //m_ActUtl:= TActUtlType64.Create(nil);
    m_ActUtl:= TCommTCP.Create('127.0.0.1', 3888);
    if m_ActUtl = nil then begin
      AddLog(format('[Create] nStationNumber=%d, UseSimulator=%d Faile (m_ActUtl=nil)', [m_nStationNumber, ord(UseSimulator)]));
      Exit;
    end;
    //m_ActUtl.Set_ActLogicalStationNumber(m_nStationNumber);
  end;
end;

destructor TCommPLCThread.Destroy;
begin
  StopThread;

  ClosePLC;

  if frmPlcSimulate <> nil then begin
    frmPlcSimulate.SetActive(0);
    frmPlcSimulate.Free;
    frmPlcSimulate:= nil;
  end;

  if m_ActUtl <> nil then begin
    m_ActUtl.Free;
    m_ActUtl:= nil;
  end;

  m_AlarmQue.Free;
  m_MESQue.Free;

  PollingDataPre:= nil;
  PollingData:= nil;
  PollingECS:= nil;
  PollingECSPre:= nil;
  PollingEQP:= nil;
  PollingEQPPre:= nil;
  PollingCV:= nil;
  PollingCVPre:= nil;

  AddLog('[Destroy]', True);

  m_csWrite.Free;
  m_csLog.Free;
  m_slLog.Free;
  CloseHandle(m_hECSEvent);

  inherited;
end;


procedure TCommPLCThread.DoEvent;
begin
  //Call Event
end;


procedure TCommPLCThread.StopThread;
begin
  //InterlockedIncrement(m_nStop);
  m_nStop:= 1;
  Terminate;
end;

procedure TCommPLCThread.SyncThread;
begin
  if not Terminated then
  begin
    Synchronize(DoEvent);
  end;
end;

procedure TCommPLCThread.ReadTimeData;
var
  naValues: array [0..6] of Integer;
  st, stLocal: TSystemTime;
  sTimeValue: String;
  bChanged: Boolean;
  nReturnCode : Integer;
begin
  //ReadDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$00+$0, 3), 6, naValues[0]); //Time Data
//  ReadDeviceBlock('W0000', 6, naValues[0],nReturnCode); //Time Data
//    Synchronize(nil,
//  procedure
//  begin
  ReadDeviceBlock('W0000', 6, naValues[0],nReturnCode); //Time Data
  //Glass Data를 어디에 사용하나?
//   end
//   );
  st.wYear   := naValues[0];
  st.wMonth  := naValues[1];
  st.wDay    := naValues[2];
  st.wHour   := naValues[3];
  st.wMinute := naValues[4];
  st.wSecond := naValues[5];
  st.wMilliseconds:= 0;

  //시간차를 구하여 변경 여부 확인
  GetLocalTime(stLocal);
  bChanged:= False;
  if (st.wYear <> stLocal.wYear)
    or (st.wMonth <> stLocal.wMonth)
    or (st.wDay <> stLocal.wDay)
    or (st.wHour <> stLocal.wHour)
    or (st.wMinute <> stLocal.wMinute) then begin
    //연월일시분이 다른 경우 변경
    if st.wYear > 2000 then begin
      SetLocalTime(st);
      bChanged:= True;
    end;
  end
  else if (st.wSecond <> stLocal.wSecond) then begin
    //연월일시분이 같고 초만 다른 경우
    if (abs(st.wSecond - stLocal.wSecond) > 1) then begin
      //SetSystemTime(st);
      SetLocalTime(st);
      bChanged:= True;
    end;
  end;

  sTimeValue:= format('%d-%d-%d %d:%d:%d.%.3d', [st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds]);
  if bChanged then begin
    AddLog('Read TimeData Changed: ' + sTimeValue);
    SendMessageMain(COMMPLC_MODE_EVENT_ECS,0, 1, 0, sTimeValue, nil);
  end
  else begin
    AddLog('Read TimeData: ' + sTimeValue);
  end;
end;


function TCommPLCThread.GetDataValue(inx: Integer): Integer;
begin
  Result:= PollingData[inx];
end;


procedure TCommPLCThread.SendMessageMain(nMsgMode, nCh: Integer; nParam, nParam2: Integer; sMsg: String; pData:Pointer);
var
  cds         : TCopyDataStruct;
  GUIMessage : TGUIMessage;
begin
  GUIMessage.MsgType := MessageType; //MSGTYPE_COMMPLC;
  GUIMessage.Channel := nCh;
  GUIMessage.Mode    := nMsgMode;
  GUIMessage.Param   := nParam;
  GUIMessage.Param2  := nParam2;
  GUIMessage.Msg     := sMsg;
  GUIMessage.pData   := pData;

  cds.dwData      := 0;
  cds.cbData      := SizeOf(GUIMessage);
  cds.lpData      := @GUIMessage;
  SendMessage(MessageHandle, WM_COPYDATA, 0, LongInt(@cds));
end;

procedure TCommPLCThread.SendMessageTest(nMsgMode, nCh, nParam, nParam2: Integer; sMsg: String; pData:Pointer);
var
  cds         : TCopyDataStruct;
  GUIMessage : TGUIMessage;
begin
  GUIMessage.MsgType := MessageType; //MSGTYPE_COMMPLC;
  GUIMessage.Channel := nCh;
  GUIMessage.Mode    := nMsgMode;
  GUIMessage.Param   := nParam;
  GUIMessage.Param2  := nParam2;
  GUIMessage.Msg     := sMsg;
  GUIMessage.pData   := pData;

  cds.dwData      := 0;
  cds.cbData      := SizeOf(GUIMessage);
  cds.lpData      := @GUIMessage;

  if nCh < 4 then begin
    SendMessage(MessageHandleTest1, WM_COPYDATA, 0, LongInt(@cds));
  end
  else begin
    GUIMessage.Channel := nCh-4;
    SendMessage(MessageHandleTest2, WM_COPYDATA, 0, LongInt(@cds));
  end;
end;


procedure TCommPLCThread.ShowModalSimulator;
begin
  if frmPlcSimulate <> nil then frmPlcSimulate.ShowModal;
end;

procedure TCommPLCThread.ShowSimulator;
begin
  if frmPlcSimulate <> nil then frmPlcSimulate.Show;
end;

//function TCommPLCThread.OpenPLC: Integer;
procedure TCommPLCThread.OpenPLC;
var
  nRet : integer;
  sRet : string;
//  nRet : LongInt;
begin
  nRet:= 1;
  if g_CommPLC = nil then begin  //Thread 안에서 종료 시 검사
    Exit;
  end;

  try
    if UseSimulator then
    begin
      if frmPlcSimulate <> nil then
        nRet:= frmPlcSimulate.OpenPLC()
    end else
    begin
      if m_ActUtl = nil then Exit;
       //nRet := m_ActUtl.Open;
       m_ActUtl.Active:= True;
       nRet:= 0;
       AddLog(' OpenPLC nRet : '+ inttohex(nRet,4));
    end;
  except
    on E: Exception do begin
      AddLog('OpenPLC Exception: ' + E.Message);
      Exit;
    end;
  end;
  //Result:= bRet;

  m_bOpend:= (nRet = 0);
  if m_bOpend then begin
    SendMessageMain(COMMPLC_MODE_CONNECT, 0, 0, 0, 'PLC Connect', nil);
    Exit;
  end
  else begin
    //SendMessageMain(COMMPLC_MODE_CONNECT, 0, 1, 0, 'PLC Connect Fail', nil);
  end;
end;


PROCEDURE TCommPLCThread.ClosePLC;
var
 nReturnCode : Integer;
begin
  if not m_bOpend then Exit;

//  Result:= 1;

  m_bOpend:= False;

  try
    if UseSimulator then
    begin
      if frmPlcSimulate <> nil then
         frmPlcSimulate.ClosePLC()
    end else
    begin
       //nReturnCode := m_ActUtl.Close;
       m_ActUtl.Active:= False;
//       Result := nReturnCode;
//      Result := m_ActUtl.Close;               9
    end;

    if m_nStop <> 0 then Exit; //종료 시 로그 AV이슈(m_csLog) 방지
    AddLog(' ClosePLC nRet : '+ inttohex(nReturnCode,4));

    SendMessageMain(COMMPLC_MODE_CONNECT, 0, 0, 0, 'PLC Disconnect', nil);
  except
    on Exception do begin

    end;
  end;
end;

function TCommPLCThread.WaitSignal(const szDevice: String; nValue: Integer; nWaitTime: Cardinal): Cardinal;
var
  nTick, nStartTick: Cardinal;
  lpData: Integer;
begin
  Result:= 1;
  if nWaitTime = 0 then nWaitTime:= $FFFF;

  nStartTick:= GetTickCount;
  nTick:= nStartTick;

  while (nTick - nStartTick) < nWaitTime  do begin
    if m_nStop <> 0 then Exit;
    if Terminated then Exit;
    ReadDevice(szDevice, lpData);
    if lpData = nValue then begin
      Result:= 0;
      Exit; //break;
    end;
    WaitForSingleObject(self.Handle, 100);
    nTick:= GetTickCount;
  end;
end;

function TCommPLCThread.WaitSignalBit(const szDevice: String; nBitLoc, nValue: Integer; nWaitTime: Cardinal): Cardinal;
var
  nTick, nStartTick: Cardinal;
  lpData: Integer;
begin
  Result:= 1;
  if nWaitTime = 0 then nWaitTime:= $FFFF;

  nStartTick:= GetTickCount;
  nTick:= nStartTick;

  while (nTick - nStartTick) < nWaitTime  do begin
    if m_nStop <> 0 then Exit;
    if Terminated then Exit;
    ReadDeviceBit(szDevice, nBitLoc, lpData);
    if lpData = nValue then begin
      Result:= 0;
      break;
    end;
    WaitForSingleObject(self.Handle, 100);
    nTick:= GetTickCount;
  end;
end;

function TCommPLCThread.ECS_Accessory_Unit_Status(nStage, nValue, nAlarmCode: Integer): Integer;
begin

  if not Connected then Exit(1);
  //HN-M-ECS-AN03-장비운영사양서(조립 Inline)_v0.2.pdf
  //2.2. Accessory Unit Management
  Result:= 0;
  AddLog(format('ECS_Accessory_Unit_Status Stage=%d, Value=%d' , [nStage, nValue]));
  if nValue = 2 then begin
    //Down 시 알람 코드 쓰기
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$0E+nStage, 3), nAlarmCode);
  end
  else begin
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$0E+nStage, 3), 0);
  end;
  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$0D+nStage, 3), nValue);
end;

function TCommPLCThread.ECS_Alarm_Add(nAlarmType, nAlarmCode, nOnOff: Integer): Integer;
var
  item: TAlarmItem;
begin

  if not Connected then Exit(1);
  AddLog(format('ECS_MES_AddItem nAlarmType=%d, nAlarmCode=%d OnOff=%d', [nAlarmType, nAlarmCode, nOnOff ]));
  item.AlarmType:= nAlarmType;
  item.AlarmCode:= nAlarmCode;
  item.AlarmValue:= nOnOff;
  m_AlarmQue.Enqueue(item);
  Result:= 0;
end;

function TCommPLCThread.ECS_Alarm_Report(nAlarmType, nAlarmCode, nOnOff: Integer): Integer;
var
  nValue : integer;
begin
  if not Connected then Exit(1);

  Result:= 0;
  AddLog(format('ECS_Alarm_Report Type=%d, Code=%d, OnOff=%d' , [nAlarmType, nAlarmCode, nOnOff]));
  //참조 MELSEC 사양 6.2 Light/Heavy Alarm Report

//  if nOnOff <> 0 then nAlarmCode:= nAlarmCode or $8000; //On 처리
//  if Common.PLCInfo.InlineGIB then begin
//    ReadDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$D, 3),nValue);
//    if (nValue <> 0) and (nOnOff = 1) then begin // heavy alarm Code가 써 있는 경우 다음 alarm COde를 쓰지 않음 최초 COde만 등록
//      AddLog(format('ECS_Alarm_Report Type=%d, Code=%d, OnOff=%d Skip(before exist Heavy Alarm Code:%d)' , [nAlarmType, nAlarmCode, nOnOff, nValue]));
//      Exit;
//    end;
//  end;
  if nOnOff <> 0 then begin
    if nAlarmType = 0 then begin
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$C, 3), nAlarmCode);
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$C, 3), $C, 1000); //Light Alarm Report
    end
    else begin
      //Heavy Alarm
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$D, 3), nAlarmCode);
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$E, 3), $E, 1000); //Heavy Alarm Report
    end;
  end
  else begin
    if nAlarmType = 0 then begin
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$E, 3), nAlarmCode);
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$D, 3), $D, 1000); //Light Alarm Report
    end
    else begin
      //Heavy Alarm
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$F, 3), nAlarmCode);
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$F, 3), $E, 1000); //Heavy Alarm Report
//      if Common.PLCInfo.InlineGIB then begin
//        WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$D, 3), 0);
//        WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$F, 3), 0);
//      end;
    end;
  end;
end;

function TCommPLCThread.ECS_GlassData_Report(nCH : Integer; var AGlassData: TECSGlassData): Integer;
var
  naGlassData: array [0..64]of Integer;
begin
  if not Connected then Exit(1);

  Result:= 0;
  //참조 Melsec 사양 4.1 Glass Data Structure
  //Glass Data 는 48 Word로 구성된다.
  AddLog('ECS_GlassData_Report');

  ConvertStrToPLC(AGlassData.CarrierID, 16, naGlassData[0]); //문자는 Word당 2글자
  ConvertStrToPLC(AGlassData.ProcessingCode, 8, naGlassData[8]);

  CopyMemory(@naGlassData[12], @AGlassData.LOTSpecificData[0], 4*sizeof(Integer));
  naGlassData[16]:=AGlassData.RecipeNumber;
  naGlassData[17]:=AGlassData.GlassType;
  naGlassData[18]:=AGlassData.GlassCode;
  ConvertStrToPLC(AGlassData.GlassID, 16, naGlassData[19]);
  naGlassData[27]:=AGlassData.GlassJudge + nCH;

  CopyMemory(@naGlassData[28], @AGlassData.GlassSpecificData[0], 4*sizeof(Integer));
  CopyMemory(@naGlassData[32], @AGlassData.PreviousUnitProcessing[0], 8*sizeof(Integer));
  CopyMemory(@naGlassData[40], @AGlassData.GlassProcessingStatus[0], 8*sizeof(Integer));
  ConvertStrToPLC(AGlassData.MateriID, 30, naGlassData[48]); //Ascii 16
  naGlassData[63]:=AGlassData.PCZTCode;
//  ConvertStrToPLC(AGlassData.LCM_ID, 24, naGlassData[48]); //문자는 Word당 2글자

  //WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$01+$0, 3), 48, naGlassData[0]); ///Glass Data
//     Synchronize(nil,
//  procedure
//  begin
//    WriteDeviceBlockPro('W' + IntToHex(StartAddr_EQP_W+$10*$01+$0, 3), 64, naGlassData[0]); ///Glass Data
//  end
//  );
  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + (nCh*$40) , 3), 64, naGlassData[0]); //Unload Glass Data #1

end;

function TCommPLCThread.ECS_Glass_Position(nCh: Integer; bExist: Boolean): Integer;    // Added by KTS 2022-11-14 오전 11:02:42 CH 설정 확인
begin

  if not Connected then Exit(1);

  Result:= 0;
  //참조 - MELSEC 사양 2.3.1 Glass Position Data
  AddLog(format('ECS_Glass_Position Ch=%d, Exist=%d', [nCh, Integer(bExist)]));

  if bExist then begin
    if InlineGIB then begin
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$07+$0+(nCh), 3), GlassData[nCh].GlassCode); //Position Glass Code

      Sleep(10);

      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+(nCh), 3), 1) //Position Glass Exist

    end
    else begin
      if Common.SystemInfo.OCType = DefCommon.OCType  then
        WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$07+$0+(nCh), 3), GlassData[nCh].GlassCode) //Position Glass Code
      else  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$C+$0+(nCh), 3), GlassData[nCh].GlassCode);

      Sleep(10);

      if Common.SystemInfo.OCType = DefCommon.OCType  then
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+(nCh), 3), 1) //Position Glass Exist
      else  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+(nCh), 3), 1); //Position Glass Exist
    end;
  end
  else begin
    if InlineGIB then begin
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$07+$0+(nCh), 3), 0); //Position Glass Code
      Sleep(10);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+(nCh), 3), 0) //Position Glass Exist
    end
    else begin
      if Common.SystemInfo.OCType = DefCommon.OCType  then
        WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$07+$0+(nCh), 3), 0) //Position Glass Code
      else WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$C+$0+(nCh), 3), 0);
      Sleep(10);
      if Common.SystemInfo.OCType = DefCommon.OCType  then
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+(nCh), 3), 0) //Position Glass Exist
      else  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+(nCh), 3), 0); //Position Glass Exist
    end;

  end;
end;

function TCommPLCThread.ECS_Glass_PositionAll(naExists: array of Integer): Integer;
var
  naGlassCode: array [0..15] of Integer;
  i: Integer;
  sLog: String;
begin

  if not Connected then Exit(1);

  Result:= 0;
  //참조 - MELSEC 사양 2.3.1 Glass Position Data
  sLog:= 'ECS_Glass_Position: ';
  for i := 0 to 7 do begin
    sLog:= sLog + ' ' + IntToStr(naExists[i]);
    if naExists[i] <> 0 then begin
      naGlassCode[i]:=  GlassData[i].GlassCode;
    end
    else begin
      naGlassCode[i]:= 0;
    end;
  end;
  AddLog(sLog);



  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$1F+$0, 3), 16, naGlassCode[0] ); //Position Glass Code
  WriteDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$0A+$0, 3), 16, naExists[0]); //Position Glass Exist

//  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$1F+$0, 3), 16, naGlassCode[0] ); //Position Glass Code
//  WriteDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$0A+$0, 3), 16, naExists[0]); //Position Glass Exist
end;

function TCommPLCThread.ECS_Glass_Processing(bProcessing: Boolean): Integer;
begin
  Result:= 0;
  AddLog(format('ECS_Glass_Processing  bProcessing=%d', [Integer(bProcessing)]));
  if bProcessing then begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$B, 3), 1);  //Glass In Processing On
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$3, 3), 0);  //Process End Report Off
  end
  else begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$B, 3), 0);  //Glass In Processing Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$3, 3), 1);  //Process End Report On
  end;
end;

function TCommPLCThread.ECS_IonizerStatus(nIndex, nValue: Integer): Integer;
begin
  //참조 - MELSEC 사양2.2.14 Ionizer Status
  Result:= 0;
  AddLog(format('ECS_IonizerStatus  Index=%d, Value=%d', [nIndex, nValue]));
  if nIndex > 15 then WriteDeviceBit('W' + IntToHex(StartAddr_EQP_W+$10*$00+$6, 3), nIndex, nValue)
  else WriteDeviceBit('W' + IntToHex(StartAddr_EQP_W+$10*$00+$7, 3), nIndex, nValue);
end;

function TCommPLCThread.ECS_Link_Test: Integer;
var
  nRet: Cardinal;
begin

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$1, 3), 1);  //Link Test Request
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$30+$1, 3), 1, COMMPLC_ECS_TIMEOUT); //Link Test Response
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$1, 3), 0);  //Link Test Request Off
  if nRet <> 0 then begin
    //오류
    Exit(258);
  end;
  Result:= 0;
end;

function TCommPLCThread.ECS_Lost_Glass_Request(sGlassID: String; nGlassCode, nRequestOption: Integer; nCh : integer): Integer;
var
  nRet: Cardinal;
  lpData,nIndex: Integer;
  lpData2: Integer;
  naGlassData: array [0..64]of Integer;
  AGlassData: TECSGlassData;
  nReturnCode : integer;
  sLog : string;
  bResult : Boolean;
  sEcsBitAddr : string;
begin
  if not Connected then Exit(1);

  //참조 - MESEC 사양 6.6 Lost Glass Data Request
  Result:= 1;
  nIndex := (EQP_ID + 13) mod 16;

  AddLog(format('ECS_Lost_Glass_Request nGlassCode=%d, sGlassID=%s,  nRequestOption=%d, Ch=%d', [nGlassCode, sGlassID, nRequestOption, nCh]));

//  AGlassData.CarrierID:= '98765432';     // 테스트 코드
//  ConvertGlassDataToBlock(AGlassData, naGlassData[0]);
//
//  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$14+$0, 3), 64, naGlassData[0]); ///Glass Data
//  ///
  if Common.SystemInfo.OCType = DefCommon.OCType then  begin
    WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$02+$0, 3), format('%-16s', [sGlassID]));
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$02+$F, 3), nGlassCode);
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$02+$E, 3), nRequestOption);
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 1); //Lost Glass Data Request
  end
  else begin
    WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$08+$0, 3), format('%-16s', [sGlassID]));
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$08+$F, 3), nGlassCode);
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$08+$E, 3), nRequestOption);
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 1); //Lost Glass Data Request

  end;
  //  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$26+$0, 3), 1, 3000); //Lost Glass Data report

//  AddLog(format('ECS_Lost_Glass_Request GlassCode=%d, GlassID=%s, CarrierID=%s', [AGlassData.GlassCode ,AGlassData.GlassID, AGlassData.CarrierID]));
  if COmmon.PLCInfo.InlineGIB then begin
//    sEcsBitAddr :=  'B'+IntToHex(StartAddr_ECS+ $100+nIndex, 3)
    sECSBitAddr := 'B'+IntToHex(StartAddr_ECS+ $10 * $10 +  $01, 3);
  end
  else begin
    sEcsBitAddr := 'B'+IntToHex(StartAddr_ECS+ $100+nIndex, 3);
  end;
  nRet:= WaitSignal(sEcsBitAddr, 1, 3000); //Take Out Report_Confirm
  if nRet <> 0 then begin
    //오류
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 0); //Lost Glass Data Request off
    sleep(1000);
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 1); //Lost Glass Data Request
    nRet := WaitSignal(sEcsBitAddr, 1, 3000);
    if nRet <> 0 then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 0);
      AddLog('ECS_Lost_Glass_Request T3 TIME OUT ');
      sLog := 'ECS_Lost_Glass_Request T3 TIME OUT ';
      SendMessageMain(COMMPLC_MODE_EVENT_ECS, 0, 2, 0, sLog);
      Exit(258);
    end;

  end;
  ReadDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$C+$0 , 3), 64, naGlassData[0],nReturnCode); //Glass Data  else ReadDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$C+$0 , 3), 64, naGlassData[0],nReturnCode); //Glass Data

  ConvertBlockToGlassData(naGlassData[0], GlassData[5]);
  //Glass Data를 어디에 사용하나?
//   end
//   );
  sLog := GetGlassDataString(GlassData[nCh]);
  AddLog(Format('<LostGlass> Before Glass CH:%d Glassdata : %s',[nCh + 1,sLog]));
  ConvertBlockToGlassData(naGlassData[0],AGlassData);
  GlassData[nCh] := AGlassData; // 받은 정보 덮어 쓰기
  sLog := GetGlassDataString(GlassData[nCh]);
  AddLog(Format('<LostGlass> after Glass CH:%d Glassdata : %s',[nCh + 1,sLog]));

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 0); //Lost Glass Data Request off

//  ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$17+$01, 3), lpData);  //Lost Glass Data
  ReadDevice('B' + IntToHex($00+$03, 3), lpData); //Lost Glass Data Ack
  ReadDevice('B' + IntToHex($00+$04, 3), lpData2); //Lost Glass Data Ack

  if lpData = 1 then  begin
    //Ok
    bResult := true;
    Result := 0;
  end;
  if lpData2 = 1 then  begin
    //NG
    bResult := false;
    sLog := format('Lost Glass Data Ack NG GlassID=%s',[sGlassID]);
    SendMessageMain(COMMPLC_MODE_EVENT_ECS, 0, 2, 0, sLog);
    Result := 1;
  end;


  AddLog(format('ECS_Lost_Glass_Request Ok  GlassID=%s', [AGlassData.GlassID]));

  //Test로 Change glass 호출
//  AGlassData.CarrierID:= 'POCBPOCB';
//  nRet:= ECS_Change_Glass_Report(AGlassData);
//  if nRet <> 0  then begin
//    AddLog('ECS_Change_Glass_Report Fail');
//  end;

//  Result:= 0;
//  nIndex := (EQP_ID + 13) mod 16;
//  ConvertStrToPLC(sGlassID, 16, naGlassData[0]); //문자는 Word당 2글자
//  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$2+$0 , 3), 8, naGlassData[0]); //Load #1-1 Glass Data
//  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$2+$0 , 3), 8, naGlassData[0]); //Load #1-1 Glass Data
//
//  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 1); //Take Out Report
//  nRet:= WaitSignal('B'+IntToHex(StartAddr_ECS+ $100+nIndex, 3), 1, COMMPLC_ECS_TIMEOUT); //Take Out Report_Confirm
//  if nRet <> 0 then  begin
//    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 0);  //Take Out Report
//    Sleep(1000);
//    nRet:= WaitSignal('B'+IntToHex(StartAddr_ECS+ $100+nIndex, 3), 1, COMMPLC_ECS_TIMEOUT); //Take Out Report_Confirm
//    if nRet <> 0 then  begin
//      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$0, 3), 0); //Take Out Report
//      AddLog('ECS_TakeOutReport T3 TIME OUT ');
//      sLog := 'ECS_TakeOutReport T3 TIME OUT ';
////      SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
//      Exit;
//    end;
//  end;
//  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$6, 3), 0);  //Take Out Report
//  nRet:= WaitSignal('B'+IntToHex(StartAddr_ECS+ $200+nIndex, 3), 0, COMMPLC_ECS_TIMEOUT); //Take Out Report_Confirm
end;


function TCommPLCThread.ECS_Change_Glass_Report(AGlassData: TECSGlassData): Integer;
var
  naGlassData: array [0..64]of Integer;
begin

  if not Connected then Exit(1);

  //참조 MELSEC 사양 6.7 Glass Data Change Report
  Result:= 0;

  AddLog(format('ECS_Change_Glass_Report CarrierID=%s', [AGlassData.CarrierID]));
  ConvertGlassDataToBlock(AGlassData, naGlassData[0]);
  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$1+$0, 3), 64, naGlassData[0]); ///Glass Data

  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$06+$0, 3), 7); //7 : Glass Data Change Report
  PulseDevice('B' + IntToHex(StartAddr_EQP+$10*$02+$4, 3), 3000); //Glass Data Change Report
end;

function TCommPLCThread.ECS_MES_AddItem(item: TMESItem): Integer;
begin
  if not Connected then Exit(1);
  AddLog(format('ECS_MES_AddItem Ch=%d, Kind=%d', [item.Value.Channel, item.Kind ]));
  m_MESQue.Enqueue(item);
  Result:= 0;
end;

function TCommPLCThread.ECS_ModelChange_Request(nIndex: Integer): Integer;
var
  nRet: Cardinal;
  lpData: Integer;
begin

  if not Connected then Exit(1);

  //참조 MELSEC 사양 12.1.4 Model Change Confirm Request
  AddLog('ECS_ModelChange_Request: Index= ' + IntToStr(nIndex));

  WriteDevice('W' + IntToHex(StartAddr2_EQP_W+$10*$00+$A, 3), nIndex);
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$5, 3), 1); //Model Change Confirm Request
  //nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$B8+$0, 3), 3, 3000); //Model Change Confirm
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$BA+$0, 3), 3, 3000); //Model Change Confirm
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$5, 3), 0); //Model Change Confirm Request
  if nRet <> 0 then begin
    //오류
    Exit(258);
  end;
  ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$30+$1, 3), lpData);
  if lpData <> 0 then begin
    //NG
    AddLog('ECS_ModelChange_Request NG');
    Result:= lpData;
  end
  else begin
    //OK
    AddLog('ECS_ModelChange_Request OK');
    Result:= 0;
  end;
end;



function TCommPLCThread.ECS_NormalOperation(sGlassID: String): Integer;
begin
  if not Connected then Exit(1);

  Result:= 0;

  AddLog(format('ECS_NormalOperation GlassID=%s', [sGlassID]));
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$07+$0, 3), format('%-16s', [sGlassID]));
end;

function TCommPLCThread.ECS_Unit_Status(nMode: Integer; nValue: Integer): Integer;
var
  nEqpAlarmCode : Integer;
  nEqpOnlineMode : Integer;
  nCh : integer;
begin

  if not Connected then Exit(1);

  Result:= 0;
  //참조 - MELSEC 사양 2.1 Operation Mode, 2.2  Equipment Status Data
  //차후에는 Word 단위로 한번에 쓰기 처리하는 방법 연구(Alarm 코드 개별)
  AddLog(format('ECS_Unit_Status Mode=%d, Value=%d', [nMode, nValue]));
  case nMode of
    0:begin //COMMPLC_UNIT_STATE_ONLINE
      if Common.PLCInfo.InlineGIB then begin
        ITC_AllChNormalStatusOnOff(nValue);
        ReadDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$0, 3),nEqpOnlineMode);
        if (nEqpOnlineMode = nValue) then begin // heavy alarm Code가 써 있는 경우 다음 alarm COde를 쓰지 않음 최초 COde만 등록
          AddLog(format('ECS_Unit_Status Mode=%d, Value=%d skip : Same Status=%d', [nMode, nValue,nEqpOnlineMode]));
          Exit;
        end;
      end;
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$0, 3), nValue); //Online State
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$2, 3), $2, 1000); //Online State
      if Common.PLCInfo.InlineGIB then begin
        WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$D, 3), 0);
        WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$F, 3), 0);
      end;
    end;

//    5: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$5, 3), nValue); //Unit Auto State
//    6: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$6, 3), nValue); //OCR(BCR) Status
//    7: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$7, 3), nValue); //Operation Cycle Stop
    8: begin //COMMPLC_UNIT_STATE_RUN
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$3, 3), 1); //Run
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$4, 3), 0); //Down Alarm Code
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$3, 3), $3, 1000); //EQP Status Change Report
//      if Common.PLCInfo.InlineGIB then begin
//        if nValue = 0 then begin
//          for nch := DefCommon.CH1 to Defcommon.MAX_CH do begin
//            WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$4 + (nCh*$20), 3), 0); //Unload Normal Status off
//            WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$4 + (nCh*$20), 3), 0); // Normal Status off
//            sleep(100);
//          end;
//        end
//      end;
    end;
    9: begin //COMMPLC_UNIT_STATE_IDLE
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$3, 3), 2); //Idle
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$4, 3), 0); //Down Alarm Code
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$3, 3), $3, 1000); //EQP Status Change Report
    end;
    10: begin   //COMMPLC_UNIT_STATE_DOWN
      if Common.PLCInfo.InlineGIB then begin
        ITC_AllChNormalStatusOnOff(0);
        ReadDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$4, 3),nEqpAlarmCode);
        if (nEqpAlarmCode <> 0) then begin // heavy alarm Code가 써 있는 경우 다음 alarm COde를 쓰지 않음 최초 COde만 등록
          AddLog(format('ECS_Unit_Status Mode=%d, Value=%d skip : Exsit Alarm Code=%d', [nMode, nValue,nEqpAlarmCode]));
          Exit;
        end;
      end;
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$3, 3), 3); //Down
      WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$4, 3), nValue); //Down Alarm Code
      PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$3, 3), $3, 1000); //EQP Status Change Report
    end;
    11: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$B, 3), nValue); //Glass In Processing  //COMMPLC_UNIT_STATE_GLASS_PROCESS
    12: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$C, 3), nValue); //Glass Exist In Unit   //COMMPLC_UNIT_STATE_GLASS_EXIST
    13: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$D, 3), nValue); //Previous Transfer Enable //COMMPLC_UNIT_STATE_PREVIOUS_TRANSFER_ENABLE

//    14: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$E, 3), nValue); //Light Alarm Report
//    15: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$F, 3), nValue); //Heavy Alarm Report
  else ;

  end;

end;


function TCommPLCThread.ECS_WriteTactTime(nTactTimeMS: Integer): Integer;
var
  nForPLCFormatTact : integer;
begin
  Result:= 0;
  if not Connected then Exit;
  nForPLCFormatTact := nTactTimeMS div 10;  //3.5 => 350
  AddLog(format('ECS_WriteTactTime: TACTTIME=%d', [nForPLCFormatTact]));
  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$0F+$F, 3),nForPLCFormatTact);
  PulseDevice('B' + IntToHex(StartAddr_EQP+$10*$07+$0, 3), COMMPLC_ECS_TIMEOUT); // Tact Time Report
end;

function TCommPLCThread.ECS_UCHK(sUserID: String): Integer;
var
  nRet: Cardinal;
  lplData: Integer;
begin

  if not Connected then Exit(1);

  //참조- MELSEC 사양 11.27 User ID Manual Check
  AddLog(format('ECS_UCHK UID=%s', [sUserID]));
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$0F+$4, 3),format('%-20s', [sUserID]));
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+$F, 3), 1);  //User ID Manual Report

  //nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$7C+ EQP_ID-1, 3), 1, COMMPLC_ECS_TIMEOUT); //User ID Manual Report Confirm
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$1+$1, 3), 1, COMMPLC_ECS_TIMEOUT); //User ID Manual Report Confirm

  if UseSimulator then begin
    //주소가 너무 커서 simulation 모드일 경우 잠시 조정
    //ReadDevice('W' + IntToHex($1F00+EQP_ID-1, 3), lplData); //User ID Data ACK
    ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$14+$F, 3), lplData); ////POCB #1 User ID Confirm
  end
  else begin
    //ReadDevice('W' + IntToHex($10*$132+EQP_ID-1, 3), lplData); //User ID Data ACK
    //ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$0+$A, 3), lplData); //User ID Data Confrim
    ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$14+$F, 3), lplData); //UserID Confirm
  end;

  //읽은 후에 보고 bit 클리어
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+$F, 3), 0);  //User ID Manual Report Off

  if nRet <> 0 then begin
    AddLog('ECS_UCHK NG Response Timeout');
    SendMessageMain(COMMPLC_MODE_LOGIN, 0, 2, 0, 'ECS_UCHK NG Response Timeout', nil);
    //오류
    Exit(258);
  end;

  if lplData <> 0 then begin
    Result:= 100;
    Logined:= False;
    AddLog('ECS_UCHK NG');
    SendMessageMain(COMMPLC_MODE_LOGIN, 0, 0, 0, 'ECS_UCHK NG', nil);
  end
  else begin
    Result:= 0;
    Logined:= True;
    AddLog('ECS_UCHK OK');
    SendMessageMain(COMMPLC_MODE_LOGIN, 0, 1, 0, 'ECS_UCHK OK', nil);
  end;
end;

function TCommPLCThread.ECS_PCHK(nCh: Integer; sSerial: String): Integer;
var
  nRet: Cardinal;
  nValue: Integer;
  naGlassData: array [0..64]of Integer;
  sLog: String;
  nReturnCode : Integer;
begin

  if not Connected then Exit(1);

  //Result:= 0;
  //참조 MELSEC 사양11.1 BCR Reading Data Report
  sLog:= format('ECS_PCHK: Ch=%d, Serial=%s', [nCh, sSerial]);
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
  SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, 'Send ECS_PCHK');

  //시리얼 쓰기 -> 요청 Bit살리기-> 응답 Bit On 확인 -> 응답 데이터 읽기 -> 요청 Bit 지우기
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0, 3), format('%-174s', [sSerial])); //EQP Report Data

  sLog:= 'BCR Read Report';
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$0, 3), 1);  //BCR Data Report On
  //nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$44+EQP_ID-1, 3), 1, COMMPLC_ECS_TIMEOUT); //BCR RD Data Report Confirm
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$03+0, 3), 1, ECS_Timeout); //BCR RD Data Report Confirm  - 5초 대기

  //Read_ECS_GlassData(nCh);
//  Synchronize(nil,
//  procedure
//  begin
    ReadDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$0+$0, 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data

//   end
//   );
//  ReadDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$0+$0, 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
  ConvertBlockToGlassData(naGlassData[0], ECS_GlassData[nCh]);
  //ConvertBlockToGlassData(naGlassData[0], GlassData[nCh]); //무조건 덮어쓰기?

  ECS_LCM_ID[nCh]:= ReadString('W' + IntToHex(StartAddr_ECS_W+$10*$4+$0, 3), 0, 24); //LCM_ID 읽기
//  Synchronize(nil,
//  procedure
//  begin
   nReturnCode :=  ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$04+$F, 3), nValue); //BCR #1 Read Report Confirm Data

//   end
//   );
//  ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$04+$F, 3), nValue); //BCR #1 Read Report Confirm Data

  sLog:= 'BCR Read Report Off';
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$0, 3), 0);  //BCR Data Report Off

  if nRet <> 0 then begin
    //오류- Light Alarm
    sLog:= 'ECS_PCHK NG Response Timeout';
    AddLog(sLog);
    SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
    SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, sLog);
    Exit(258);
  end;

  sLog:= GetGlassDataString(ECS_GlassData[nCh]);
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
  //sLog:= 'LCM_ID=' + ECS_LCM_ID[nCh];
  //AddLog(sLog);
  //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
  if InlineGIB then begin
    if ECS_GlassData[nCh].GlassJudge <> 71 then begin //8263 = 0x2047 = 71 = 'G '
      Result:= 1;
      sLog:= 'GIB ECS_PCHK NG';
      AddLog(sLog);
      //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
      SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 1, 0, sLog);
    end
    else begin
      sLog:= 'GIB ECS_PCHK OK';
      Result:= 0;
      AddLog(sLog);
      //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
      SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, sLog);
    end;

  end
  else begin
    Result:= nValue;
    if nValue <> 0 then  begin
      //AddLog('ECS_PCHK NG ' + IntToStr(nValue));
      sLog:= 'ECS_PCHK NG ' + IntToSTr(nValue);
      AddLog(sLog);
      //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
      SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 1, 0, sLog);
    end
    else begin
      sLog:= 'ECS_PCHK OK';
      AddLog(sLog);
      //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
      SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, sLog);
    end;
  end;
end;

function TCommPLCThread.ECS_ECSRestart_Test: Integer;
var
  nRet: Cardinal;
begin
  AddLog('ECS_ECSRestart_Test');
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$0, 3), 1);  //ECS_ECSRestart Request on
  nRet:= WaitSignal('B000', 0, COMMPLC_ECS_TIMEOUT); //ECS_ECSRestart Response
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$0, 3), 0);  //ECS_ECSRestart Request oFF
  if nRet <> 0 then begin
    //오류
    Exit(258);
  end;

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$2, 3), 1);
  Sleep(1000);
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$2, 3), 0);
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$3, 3), 1);
  Sleep(1000);
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$3, 3), 0);

//  PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$2, 3), $2, 1000); //Online State
//  PulseDeviceBit('B' + IntToHex(StartAddr_EQP+$10*$00+$3, 3), $3, 1000); //EQP Status Change Report

  Result:= 0;
end;

function TCommPLCThread.ECS_EICR(nCh: Integer; sLCM_ID, sErrorCode: String; sInpResult: String): Integer;
var
  nRet: Cardinal;
  lpData: Integer;
  sLog: String;
begin

  if not Connected then Exit(1);

  //참조 MELSEC 사양11.34 Inspection Data Report & Confirm
  //Result:= 0;
  sLog:= format('ECS_EICR Ch=%d, LCM_ID=%s, Result:%s, ErrorCode=%s ', [nCh, sLCM_ID, sInpResult, sErrorCode]);
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
  SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, 'Send ECS_EICR');

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$8, 3), 0); //Inspection Data Confirm ACK Off - 미리 끄고 시작
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$16+$0, 3), format('%-24s', [sLCM_ID])); //sLCM_ID
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$17+$0, 3), format('%-80s', [sErrorCode])); //Error Code
  //WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$15+$0 + (nCh*$20), 3), sZigID); //ZIG/Carrier/Tray ID
  //WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$14+$F + (nCh*$20), 3), StrToInt(sInpResult)); //Inspection Result  '0', NG<>'0'
  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$19+$F, 3), StrToInt(sInpResult)); //Inspection Result
  sLog:= 'Inspection Data Report';
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$4, 3), 1); //Inspection Data Report

(*
  //ECS에서 간소화 처리로 생략 처리- 20210416
  //nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$9A+$6, 3), 1, COMMPLC_ECS_TIMEOUT); //Inspection Data Report Confirm
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$02+$0, 3), 1, ECS_Timeout); //ECS Inspection Data Report Confirm  - 5초 대기

  sLog:= 'Inspection Data Report Off';
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$4, 3), 0); //Inspection Data Report Off

  if nRet <> 0 then begin
    //오류
    sLog:= 'ECS_EICR NG - Inspection Data Report Timeout';
    AddLog(sLog);
    SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
    SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 1, 0, sLog);
    Exit(258);
  end;

  Sleep(200);
*)

  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$02+$1, 3), 1, ECS_Timeout); //ECS Inspection Data Confirm
  if nRet <> 0 then begin
    //오류
    sLog:= 'ECS_EICR NG - Inspection Data Confirm Timeout';
    AddLog(sLog);
    SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
    SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 1, 0, sLog);
    Exit(258);
  end;


  //장비 별로 다를 수 잇음 - POCB, EEPROM
  //EQP ID와 계산해서 주소를 구해야 하는데 애매함
  //ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$8+$3, 3), lpData);
  ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$5+$F, 3), lpData);
  sLog:= 'Inspection Data Confirm ACK';
  AddLog(sLog);
  SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
  //PulseDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$8, 3), COMMPLC_ECS_TIMEOUT); //Inspection Data Confirm ACK
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$4, 3), 0); //Inspection Data Report Off
  //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$8, 3), 1); //Inspection Data Confirm ACK

  if nRet <> 0 then begin
    //오류
    sLog:= 'ECS_EICR NG - Inspection Data Confirm Timeout';
    AddLog(sLog);
    //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
    SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, sLog);
    Exit(258);
  end;

  if lpData <> 0 then begin
    //NG
    sLog:= 'ECS_EICR NG ' + IntToSTr(lpData);
    AddLog(sLog);
    //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
    SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 1, 0, sLog);
    Result:= lpData;
  end
  else begin
    //OK
    sLog:= 'ECS_EICR OK';
    AddLog(sLog);
    //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
    SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, sLog);
    Result:= 0;
  end;

end;


function TCommPLCThread.ECS_APDR(nCh: Integer; sInspectionResult: String): Integer;
var
  nRet: Cardinal;
  naGlassData: array [0..64]of Integer;
  sLog: String;
begin

  if not Connected then Exit(1);

  Result:= 0;
  sLog:= format('ECS_APDR Ch=%d, Result:%s', [nCh, sInspectionResult]);
  AddLog(sLog);

  SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, 'Send ECS_APDR');

  //참조 - MELSEC 사양 6.11 Glass APD Report
  //Scrap Glass Data Report - OFF 확인 //StartAddr_EQP+'20' + 2
  //Recipe Body Data Report - OFF 확인 //StartAddr_EQP+'20' + 8
  //Glass Data Change Report - OFF 확인//StartAddr_EQP+'20' + 4

  //Glass Data 쓰기 -> CEID 쓰기 -> ADPR 쓰기 -> APDR 비트 On
//  ConvertGlassDataToBlock(GlassData[nCh], naGlassData[0]);
//  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$01+$0 , 3), 64, naGlassData[0]); //Glass Data

  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$06+$0, 3), 1); //CEID, 1로 고정

  if UseSimulator then begin
    WriteString('W' + IntToHex($500 + StartAddr_EQP_W+$10*$01+$0, 3), format('%-100s', [sInspectionResult])); //- APDR - LW2(1AC00)영역 쓰기
  end
  else begin
    WriteString('W' + IntToHex($10000 + StartAddr_EQP_W+$10*$01+$0, 3), format('%-556s', [sInspectionResult])); //- APDR - LW2(1AC00)영역 쓰기
  end;

  //Confirm 없음
  //PulseDevice('B' + IntToHex(StartAddr_EQP+$10*$03+$1, 3), 1000); //Glass APD Report - 1초On
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$02+$1, 3), 1); //Glass APD Report

  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$00+$1, 3), 1, 3000); //ECS_Timeout); //APD Report_ACK  - 5초 대기

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$02+$1, 3), 0); //Glass APD Report off

  if nRet <> 0 then begin
    //오류
    sLog:= 'ECS_APDR NG - Inspection Data Confirm Timeout';
    AddLog(sLog);
    //SendMessageTest(COMMPLC_MODE_LOG_ECS, nCh, 0, 0, sLog);
    SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 1, 0, 'ECS_APDR NG');
    Exit(258);
  end;
  SendMessageTest(COMMPLC_MODE_SHOW_MES, nCh, 0, 0, 'ECS_APDR OK');
end;

function TCommPLCThread.ECS_ZSET(nCh: Integer; nBondingType: Integer; sZigID, sPID, sPcbID: String; out lplData: Integer): Integer;
var
  nRet: Cardinal;
begin

  if not Connected then Exit(1);

  //참조- MELSEC 사양 11.29 Bonding Report
  AddLog(format('ECS_ZSET sZigID=%s, sPID=%s, sPcbID=%s', [sZigID, sPID, sPcbID]));

  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + (nCh*$50), 3), sZigID); //LOT(ZIG) ID
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$11+$0 + (nCh*$50), 3), sPID); //Panel ID
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$12+$C + (nCh*$50), 3), sPcbID); //Control PCB ID

  if nBondingType = 0 then
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$13+$F + (nCh*$50), 3), $41) //Bonding Type - 체결
  else
    WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$13+$F + (nCh*$50), 3), $44); //Bonding Type - 해제

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+$A, 3), 1);  //Bonding Report

  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$2+$0 + nCh, 3), 1, COMMPLC_ECS_TIMEOUT); //Bonding Report Confirm

  if nRet <> 0 then begin
    //오류
    Exit(258);
  end;

  //장비 별로 다를 수 잇음 - POCB, EEPROM
  ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$0A+$D + (nCh*$180), 3), lplData); //Bonding Data ACK //OK = ‘0’, NG ≠ ‘0’

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$07+$A, 3), 0);  //Bonding Report off

  Result:= lplData;
  if lplData <> 0 then  begin
    AddLog('ECS_ZSET NG');
  end
  else begin
    AddLog('ECS_ZSET OK');
  end;
end;

function TCommPLCThread.EQP_Clear_ECS_Area: Integer;
var
  lpData: array [0..32] of Integer;
begin

  if not Connected then Exit(1);

  AddLog('EQP_Clear_ECS_Area' );
  FillChar(lpData, 32 * sizeof(Integer), 0);
  Result:= WriteDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$00+$0), 11, lpData[0]);
end;

function TCommPLCThread.EQP_Clear_ROBOT_Request(nCH : Integer): Integer;
var
  lpData: array [0..32] of Integer;
begin

//Common.Delay();
  if not Connected then Exit(1);

  AddLog('EQP_Clear_ROBOT_Request' );
  FillChar(lpData, 32 * sizeof(Integer), 0);
  if Common.PLCInfo.InlineGIB then begin       // 사양서에는 normal status 살아 있음
//    Result:= WriteDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$08+ nCH *$20+$0,3), 2, lpData[0]);
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 0); //Unload Enable off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$1 + (nCh*$20), 3), 0); //Glass Data Report off
//    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$4 + (nCh*$20), 3), 0); //Unload Normal Status off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$5 + (nCh*$20), 3), 0); //Unload Request off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$6 + (nCh*$20), 3), 0); //Unload Complete Confrim off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$0 + (nCh*$20), 3), 0); //Load Enable Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$1 + (nCh*$20), 3), 0); //Glass Data Request off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$5 + (nCh*$20), 3), 0); //Load Request Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$6 + (nCh*$20), 3), 0); //Load Complte Confirm Off
//    Sleep(500);
//    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$4 + (nCh*$20), 3), 0); // Normal Status off
  end
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      Result:= WriteDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$0C+ nCH *$20+$0,3), 2, lpData[0]);
    end
    else if Common.SystemInfo.OCType = DefCommon.PreOCType then begin
      Result:= WriteDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$12+ nCH *$20+$0,3), 2, lpData[0]);
    end;
  end;

//   WriteDevice('B' + IntToHex(StartAddr_EQP++$10*$0C+ nCH *$20+$0,3),
(*
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$1 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$4 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$6 + (nCh*$20), 3), 0); //Unload Enable O
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$1 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$4 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$5 + (nCh*$20), 3), 0); //Load Enable off
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$6 + (nCh*$20), 3), 0); //Load Enable off
*)
  //요청 상태 클리어
  RequestState_Load[nCH]:= 0;
  RequestState_Unload[nCH]:= 0;
end;

function TCommPLCThread.EQP_SkipCh(nJig, nCh, nSkip: Integer): integer;
var
  sMsg : string;
begin
  if not Connected then Exit(1);
  // skip on 상태 , Manual -> auto 갈 때 write
  Result:= 0;
  sMsg := format('EQP_SKIP_CH : Jig=%d Ch=%d SKIP=%d',[nJig,nCh,nSkip]);
  AddLog(sMsg);

  WriteDevice('B' + IntToHex(StartAddr_EQP + $10 * $04 + $08 + nCh , 3), nSkip); // skip ch on  , no skip off
end;

function TCommPLCThread.EQP_UnloadBeforeCh(nJig, nCh, nOnOff: integer): integer;
var
  sMsg : String;
  nTempCh : integer;
begin
  if not Connected then Exit(1);

  Result:= 0;
  sMsg := format('EQP_UNLOAD_CH : Jig=%d Ch=%d OnOff=%d',[nJig,nCh,nOnOff]);
  AddLog(sMsg);
  nTempCh := nCh mod 2;
  if Common.SystemInfo.OCType = Defcommon.OCType then begin

  end
  else if Common.SystemInfo.OCType = Defcommon.PreOCType then begin
    if Common.SystemInfo.CHReversal then begin
      if nTempCh = 0 then begin
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13 + (nJig*$20) + $0B, 3), nOnOff); //Unload Ch Data
      end
      else begin
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13 + (nJig*$20) + $0A, 3), nOnOff); //Unload Ch Data
      end;
    end
    else begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13 + (nJig*$20) + $0A + $01 * nTempCh, 3), nOnOff); //Unload Ch Data
    end;
  end;
end;

function TCommPLCThread.ECS_Glass_Exist(nExistCount, nUseCount: Integer): Integer;
begin

  if not Connected then Exit(1);
  AddLog(format('ECS_Glass_Exist  nExistCount=%d, nUseCount=%d', [nExistCount, nUseCount]));
  Result:= 0;
  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$C, 3), nExistCount); //Glass Count In Unit
  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$00+$D, 3), nUseCount - nExistCount); //Put into Possible Count
  if nExistCount <> 0 then  begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$C, 3), 1); //Glass Exist In Unit
  end
  else begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$C, 3), 0); //Glass Exist In Unit
  end;
end;

function TCommPLCThread.ECS_DEFECT_CODE(sPID, sGLSCode, sGLSJudge, sCode, sComment: String; out sValue: String): Integer;
var
  nRet: Cardinal;
  lpData: Integer;
begin

  if not Connected then Exit(1);

  //참조 MELSEC 사양11.25 DEFECT CODE Data Report
  Result:= 0;
  AddLog('ECS_DEFECT_CODE');
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0, 3), sPID);
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$11+$4, 3), sGLSCode);
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$11+$5, 3), sGLSJudge);
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0, 3), sCode);
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$16+$0, 3), sComment);

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$2, 3), 1); //DEFECT CODE Data Report

  nRet:= WaitSignal('B' + IntToHex(StartAddr_ECS+$10*$A6+ EQP_ID-1, 3), 1, COMMPLC_ECS_TIMEOUT); //DEFECT CODE Data Report Confirm

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$2, 3), 0); //DEFECT CODE Data Report
  if nRet <> 0 then begin
    //오류
    Exit(258);
  end;
  //결과 읽기
  ReadDevice('W' + IntToHex(StartAddr_ECS_W+$10*$30+$0, 3), lpData); //DEFECT CODE Data ACK
  if lpData <> 0 then begin
    Result:= lpData;
  end
  else begin
    //OK
  end;
end;

function TCommPLCThread.ECS_Scrap_Glass_Report(AGlassData: TECSGlassData; sScrapCode: String): Integer;
var
  naGlassData: array [0..64]of Integer;
begin

  if not Connected then Exit(1);
  AddLog('ECS_Scrap_Glass_Report');
  Result:= 0;
//  ConvertGlassDataToBlock(AGlassData, naGlassData[0]);
//  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$01+$0, 3), 64, naGlassData[0]); ///Glass Data

  WriteDevice('W' + IntToHex(StartAddr_EQP_W+$10*$06+$0, 3), 2); //2 : Scrap Glass Data Report
  WriteString('W' + IntToHex(StartAddr_EQP_W+$10*$06+$1, 3), sScrapCode);

  PulseDevice('B' + IntToHex(StartAddr_EQP+$10*$02+$2, 3), 1000); //Scrap Glass Data Report
end;

function TCommPLCThread.ECS_Stage_Position(nStage: Integer): Integer;
begin

  if not Connected then Exit(1);

  //Stage 위치 보고- 사양서에 없음. 맵에 있어서 추가
  AddLog(format('ECS_Stage_Position  Stage=%d', [nStage]));
  Result:= 0;
  if nStage = 0 then begin
    //A Front
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$6, 3), 0); //A Stage Inspection Position
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$7, 3), 1); //A Stage Loading Position
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$8, 3), 1); //B Stage Inspection Position
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$9, 3), 0); //B Stage Loading Position
  end
  else begin
    //B Front
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$6, 3), 1); //A Stage Inspection Position
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$7, 3), 0); //A Stage Loading Position
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$8, 3), 0); //B Stage Inspection Position
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04+$9, 3), 1); //B Stage Loading Position
  end;
end;

function TCommPLCThread.ECS_Status_Mode(nMode: Integer; nValue: Integer): Integer;
begin

  if not Connected then Exit(1);

  Result:= 0;
  AddLog(format('ECS_Status_Mode  Mode=%d, Value=%d', [nMode, nValue]));
  case nMode of
    1: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$6, 3), nValue); //OCR(BCR) Status
    2: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$7, 3), nValue);  //Operation Cycle Stop
    3: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$05+$3, 3), nValue); //PD Down
    4: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$05+$2, 3), nValue); //Loader Emergency Stop
    5: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$8, 3), nValue); //Run
    6: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$9, 3), nValue); //Idle
    7: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$A, 3), nValue); //Down
    8: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$B, 3), nValue); //Glass In Processing
    9: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$C, 3), nValue); //Glass Exist In Unit
    10: WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$D, 3), nValue); //Previous Transfer Enable
    else ;
  end;
end;

function TCommPLCThread.ECS_TakeOutReport(nCH : integer; sPanelID: String): Integer;
var
  naGlassData : array[0..7] of Integer;
  nRet,nIndex : Integer;
  sLog : string;
  sECSBitAddr : string;
begin
  if not Connected then Exit(1);
  Result:= 0;
  nIndex := (EQP_ID + 13) mod 16;
  ConvertStrToPLC(sPanelID, 16, naGlassData[0]); //문자는 Word당 2글자
  if Common.PLCInfo.InlineGIB then begin
    sECSBitAddr := 'B'+IntToHex(StartAddr_ECS+ $10 * $20 + $01, 3);
  end
  else begin
    sECSBitAddr := 'B'+IntToHex(StartAddr_ECS+ $200+nIndex, 3);
  end;

  if Common.SystemInfo.OCType = DefCommon.OCType then begin
    WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$3+$0 , 3), 8, naGlassData[0]); //Load #1-1 Glass Data
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$6, 3), 1); //Take Out Report
  end
  else begin
    WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$9+$0 , 3), 8, naGlassData[0]); //Load #1-1 Glass Data
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$0, 3), 1); //Take Out Report
  end;
  nRet:= WaitSignal(sECSBitAddr, 1, COMMPLC_ECS_TIMEOUT); //Take Out Report_Confirm
  if nRet <> 0 then  begin
    if Common.SystemInfo.OCType = DefCommon.OCType then
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$6, 3), 0)  //Take Out Report
    else WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$0, 3), 0);  //Take Out Report
    Sleep(1000);
    if Common.SystemInfo.OCType = DefCommon.OCType then
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$6, 3), 1) //Take Out Report
    else WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$0, 3), 1);

    nRet:= WaitSignal(sECSBitAddr, 1, COMMPLC_ECS_TIMEOUT); //Take Out Report_Confirm
    if nRet <> 0 then  begin
      if Common.SystemInfo.OCType = DefCommon.OCType then
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$6, 3), 0) //Take Out Report
      else WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$0, 3), 0);
      AddLog('ECS_TakeOutReport T3 TIME OUT ');
      sLog := 'ECS_TakeOutReport T3 TIME OUT ';
      SendMessageMain(COMMPLC_MODE_EVENT_ECS, nCh, 2, 0, sLog);
      Exit;
    end;
  end;
  if Common.SystemInfo.OCType = DefCommon.OCType then
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$6, 3), 0) //Take Out Report
  else WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$0, 3), 0);
  nRet:= WaitSignal(sECSBitAddr, 0, COMMPLC_ECS_TIMEOUT); //Take Out Report_Confirm
end;

function TCommPLCThread.ROBOT_Copy_GlassData: Integer;
var
  naGlassData: array [0..64]of Integer;
  nReturnCode : Integer;
begin

  if not Connected then Exit(1);

  Result:= 0;

  ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0 , 3), 64, naGlassData[0],nReturnCode); //Load #1-1 Glass Data
  WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0, 3), 64, naGlassData[0]); ///Glass Data


  if StartAddr2_ROBOT_W = 0 then  begin
    ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0 + $40 , 3), 64, naGlassData[0],nReturnCode); //Load #1-2 Glass Data
    WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + $40, 3), 64, naGlassData[0]); ///Glass Data
  end
  else begin
    ReadDeviceBlock('W' + IntToHex(StartAddr2_ROBOT_W+$10*$0+$0 + $40 , 3), 64, naGlassData[0],nReturnCode); //Load #1-2 Glass Data
    WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + $40, 3), 64, naGlassData[0]); ///Glass Data
  end;
end;

function TCommPLCThread.ROBOT_Exchange_Request(nCh: Integer): Integer;
var
  nRet: Cardinal;
 naGlassData: array [0..64]of Integer;
begin

  if not Connected then Exit(1);

  //참조 Interlock 사양3.1.1
  //참조 Interlock 사양3.10.1 Type 10 Exchange
  Result:= 0;
  AddLog('ROBOT_Exchange_Request: ' + InttoStr(nCh));

  if Common.PLCInfo.InlineGIB then begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$4 + (nCh*$20), 3), 1); //Unload Normal Status
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$4 + (nCh*$20), 3), 1); //Load Normal Status - 상태 설정에서....

    Sleep(50);

    ConvertGlassDataToBlock(GlassData[nCh], naGlassData[0]);
    WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + (nCh*$40) , 3), 64, naGlassData[0]); //Unload Glass Data #1

    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$1 + (nCh*$20), 3), 1); //Unload Glass Data Report
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$5 + (nCh*$20), 3), 1); //Unload Request

    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$1 + (nCh*$20), 3), 1); //Load Glass Data Request
    RequestState_Unload[nCh]:= 1;
    RequestState_Load[nCh]:= 1;
    //Glass Data Report를 보고 대기
    //기다 렸으니 응답이 왔던 안왔던 OFF 처리
    //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$1 + (nCh*$20), 3), 0); //Load Glass Data Request Off

//    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 1); //Unload Enable

    nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$00+$1 + (nCh*$20), 3), 1, 5000); //Glass Data Report를 보고 대기
    if nRet <> 0 then     WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 1); //Unload Enable

  end
  else begin

    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$4 + (nCh*$20), 3), 1); //Unload Normal Status
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$4 + (nCh*$20), 3), 1); //Load Normal Status - 상태 설정에서....

    Sleep(50);
    if Common.SystemInfo.CHReversal then begin
      ConvertGlassDataToBlock(GlassData[nCh*2 + 1], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + (nCh*$80) , 3), 64, naGlassData[0]); //Unload Glass Data #1

      ConvertGlassDataToBlock(GlassData[nCh*2], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + $40 + (nCh*$80), 3), 64, naGlassData[0]); //Unload Glass Data #2
    end
    else begin
      ConvertGlassDataToBlock(GlassData[nCh*2], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + (nCh*$80) , 3), 64, naGlassData[0]); //Unload Glass Data #1

      ConvertGlassDataToBlock(GlassData[nCh*2+1], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + $40 + (nCh*$80), 3), 64, naGlassData[0]); //Unload Glass Data #2
    end;

    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$1 + (nCh*$20), 3), 1); //Unload Glass Data Report
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$5 + (nCh*$20), 3), 1); //Unload Request

    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$1 + (nCh*$20), 3), 1); //Load Glass Data Request
    RequestState_Unload[nCh]:= 1;
    RequestState_Load[nCh]:= 1;
    //Glass Data Report를 보고 대기
    //기다 렸으니 응답이 왔던 안왔던 OFF 처리
    //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$1 + (nCh*$20), 3), 0); //Load Glass Data Request Off
    if Common.SystemInfo.OCType = DefCommon.OCType then
          WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0 + (nCh*$20), 3), 1) //Unload Enable
    else  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$0 + (nCh*$20), 3), 1); //Unload Enable
    if (nCh = 1) and (StartAddr2_ROBOT <> 0) then  // Addr2 있는 경우
          nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$10*$00+$1 , 3), 1, 2000) //Glass Data Report를 보고 대기
    else  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$00+$1 + (nCh*$20), 3), 1, 2000); //Glass Data Report를 보고 대기

  end;
  if nRet = 0 then begin
    //응답이 있을 경우
    UnloadOnly[nCh]:= False;
    AddLog('ROBOT_Exchange_Request GlassData Report OK');
  end
  else begin
    //Unload Only 모드로 설정
    UnloadOnly[nCh]:= True;
    AddLog('ROBOT_Exchange_Request - No Glass Data Report: Unload  Only');
  end;

  Exit;


  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5, 3), 1); //Load Request
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0, 3), 1); //Load Enable
  //일정 시간안에 Robot Busy가 설정되지 않으면 Alarm
  if (nCh = 1) and (StartAddr2_ROBOT <> 0) then  // Addr2 있는 경우
        nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$10*$01+$2, 3), 1, 3000) //Robot Busy
  else  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$01+$2 + (nCh*$20), 3), 1, 3000); //Robot Busy

  if nRet <> 0 then begin
    //오류- Alarm
    AddLog('ROBOT_Load_Request Timeout - Robot Busy');
    //Exit(258);
  end;

  //언로드 완료(Unload Complete, B[nE]3)  대기 후 - Polling에서 대기 후 처리할 내용
  if(nCh = 1) and (StartAddr2_ROBOT <> 0) then
    nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$3, 3), 1, 30000) //Unload Complete
  else nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+($20*nCh)+$3, 3), 1, 30000); //Unload Complete
  if nRet <> 0 then begin
    //오류
    AddLog('ROBOT_Load_Request Timeout - Unload Complete');
    //Exit(258);
  end;
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$6, 3), 1); //Unload Complete Confrim
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$5, 3), 0); //Unload Request
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$1, 3), 0); //Glass Data Request

  if (nCh = 1) and (StartAddr2_ROBOT <> 0) then
    nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$10*$00+$3, 3), 1, 30000) //Load Complete
  else nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT++$10*$00+$3 + (nCH * $20) , 3), 1, 30000); //Load Complete
  if nRet <> 0 then begin
    //오류
    AddLog('ROBOT_Load_Request Timeout - Load Complete');
    //Exit(258);
  end;
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$6, 3), 1); //Load Complete Confrim
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$1, 3), 0); //Glass Data Request
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5, 3), 0); //Load Request

  if (nCh =1) and (StartAddr2_ROBOT <> 0) then
      nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$10*$00+$0 , 3), 1, 30000) //Unload Noninterference
  else nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0 + (nCH * $20), 3), 1, 30000); //Unload Noninterference
  if nRet <> 0 then begin
    //오류- Alarm
    AddLog('ROBOT_Load_Request Timeout - Unload Noninterference');
    //Exit(258);
  end;

  if (nCh = 1) and (StartAddr2_ROBOT<> 0) then
      nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$10*$01+$2 , 3), 1, 30000) //Unload Robot Busy
  else nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$01+$2 + (nCH * $20), 3), 1, 30000); //Unload Robot Busy
  if nRet <> 0 then begin
    //오류- Alarm
    AddLog('ROBOT_Load_Request Timeout - Unload Robot Busy');
    //Exit(258);
  end;

  if (nCh = 1) and ( StartAddr2_ROBOT <> 0) then
      nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$10*$01+$0 , 3), 1, 30000) //Load Noninterference
  else nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$01+$0 + (nCH * $20), 3), 1, 30000); //Load Noninterference
  if nRet <> 0 then begin
    //오류- Alarm
    AddLog('ROBOT_Load_Request Timeout - Load Noninterference');
    //Exit(258);
  end;

  if (nCh = 1 ) and (StartAddr2_ROBOT <> 0) then
      nRet:= WaitSignal('B' + IntToHex(StartAddr2_ROBOT+$10*$01+$2 , 3), 1, 3000) //Load Robot Busy
  else nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$01+$2 + (nCH * $20), 3), 1, 3000); //Load Robot Busy
  if nRet <> 0 then begin
    //오류- Alarm
    AddLog('ROBOT_Load_Request Timeout - Load Robot Busy');
    //Exit(258);
  end;

  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0, 3), 0); //Unload Enable
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0, 3), 0); //Load Enable
end;

function TCommPLCThread.ROBOT_Load_Request(nCh: Integer): Integer;
var
  nRet: Cardinal;
  naGlassData: array [0..64]of Integer;
  nReturnCode : Integer;
begin

  if not Connected then Exit(1);

  //참조 Interlock 사양3.1.1
  //참조 Interlock 사양3.10.3 Type 10 Load Only
  Result:= 0;
  AddLog('ROBOT_Load_Request: ' + InttoStr(nCh));
  if Common.PLCInfo.InlineGIB then begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$4 + (nCh*$20), 3), 1); //Unload Normal Status
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 0); //Unload Enable
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$1 + (nCh*$20), 3), 0); //Glass Data Report
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$5 + (nCh*$20), 3), 0); //Unload Request
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$6 + (nCh*$20), 3), 0); //Unload Complete Confrim
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$0 + (nCh*$20), 3), 0); //Load Enable Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$5 + (nCh*$20), 3), 0); //Load Request Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$6 + (nCh*$20), 3), 0); //Load Complte Confirm Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$4 + (nCh*$20), 3), 1); //Normal Status - 상태 설정에서....
    Sleep(500);
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$1 + (nCh*$20), 3), 1); //Glass Data Request
  end
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType  then  begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$4 + (nCh*$20), 3), 1); //Unload Normal Status
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0 + (nCh*$20), 3), 0); //Unload Enable
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$1 + (nCh*$20), 3), 0); //Glass Data Report
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$5 + (nCh*$20), 3), 0); //Unload Request
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$6 + (nCh*$20), 3), 0); //Unload Complete Confrim
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0 + (nCh*$20), 3), 0); //Load Enable Off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5 + (nCh*$20), 3), 0); //Load Request Off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$6 + (nCh*$20), 3), 0); //Load Complte Confirm Off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$4 + (nCh*$20), 3), 1); //Normal Status - 상태 설정에서....
      Sleep(500);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$1 + (nCh*$20), 3), 1); //Glass Data Request
    end
    else begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$4 + (nCh*$20), 3), 1); //Unload Normal Status
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$0 + (nCh*$20), 3), 0); //Unload Enable
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$1 + (nCh*$20), 3), 0); //Glass Data Report
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$5 + (nCh*$20), 3), 0); //Unload Request
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$6 + (nCh*$20), 3), 0); //Unload Complete Confrim

      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$0 + (nCh*$20), 3), 0); //Load Enable Off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$5 + (nCh*$20), 3), 0); //Load Request Off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$6 + (nCh*$20), 3), 0); //Load Complte Confirm Off

      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$4 + (nCh*$20), 3), 1); //Normal Status - 상태 설정에서....
      Sleep(500);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$1 + (nCh*$20), 3), 1); //Glass Data Request
    end;
  end;
  RequestState_Load[nCh]:= 1;
Exit;



  //Glass Data Report를 보고 대기
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$01+$1 + (nCh*$20) + (EQP_ID * $40), 3), 1, 30000); //Glass Data Report를 보고 대기
  if nRet <> 0 then begin
    //오류
    AddLog('ROBOT_Load_Request Timeout Glass Data Report');
    Exit(258);
  end;

  ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0 +(nCH*$40), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
  ConvertBlockToGlassData(naGlassData[0], GlassData[(StageNo*4)+nCh*2]);

  ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$40+(nCH*$40), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
  ConvertBlockToGlassData(naGlassData[0], GlassData[(StageNo*4)+nCh*2+1]);

  Exit;

//  ROBOT_Copy_GlassData; //Robot 데이터를 EQP 데이터 영역으로 복사

  ReadDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0, 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
//  ConvertBlockToGlassData(naGlassData[0],AGlassData);
  //투임 가능 데이터 판단 필요
  if naGlassData[0] = $3231 then begin
    //
  end;

  ReadDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + $40, 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
  //ConvertBlockToGlassData(naGlassData[0],AGlassData);
  //투임 가능 데이터 판단 필요
  if naGlassData[0] = $3231 then begin
    //
  end;


  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5, 3), 1); //Load Request
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0, 3), 1); //Load Enable
  //일정 시간안에 Robot Busy가 설정되지 않으면 Alarm
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$01+$2 + (nCh*$20) + (EQP_ID * $20), 3), 1, 30000); //Robot Busy
  if nRet <> 0 then begin
    //오류- Alarm
    AddLog('ROBOT_Load_Request Timeout Robot Busy');
    Exit(258);
  end;
  //********************************************************************
  Exit;
(*
  {TODO -okg.jo -cGeneral : 로드 완료(Load Complete, B[nD]3)  대기 후 - Polling에서 대기 후 처리할 내용?. 어차피 대기이므로 여기서 처리?}

  //로드 완료(Load Complete, B[nD]3)  대기 후 - Polling에서 대기 후 처리할 내용
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$0D+$3, 3), 1, 30000); //Load Complete
  if nRet <> 0 then begin
    //오류
    Exit(258);
  end;
  //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$6, 3), 1); //Load Complete Confrim
  //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$1, 3), 0); //Glass Data Request
  //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5, 3), 0); //Load Request
  Process_LoadComplete;

  //Load Complete Off 대기
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$0D+$3, 3), 0, 3000); //Load Complete Off 대기
  if nRet <> 0 then begin
    //오류
    Exit(258);
  end;

  Process_LoadComplete_Off;
*)
end;

function TCommPLCThread.ROBOT_ReadyToStart_Request(nCh, nReady: Integer): Integer;
begin
  //Robot에게Start 준비 알림
  Result:= 0;
  AddLog(format('ROBOT_ReadyToStart_Request nCh=%d, nReady=%d', [nCh, nReady]));
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$D + (nCh*$20), 3), nReady); //Ready To Start - 임의로 선정
end;

function TCommPLCThread.ROBOT_Unload_Request(nCh: Integer): Integer;
var
  naGlassData: array [0..64]of Integer;
begin
  if not Connected then Exit(1);
  //참조 Interlock 사양3.5.1
  //참조 Interlock 사양3.10.2 Type 10 Unload Only
  Result:= 0;
  if not Common.PLCInfo.InlineGIB then begin
    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$4 + (nCh*$20), 3), 1); //UnLoad Normal Status
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$4 + (nCh*$20), 3), 1); //Load Normal Status - 상태 설정에서....
  //  Unload GlassData
      ConvertGlassDataToBlock(GlassData[nCh*2], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + (nCh*$80) , 3), 64, naGlassData[0]); //Unload Glass Data #1

      ConvertGlassDataToBlock(GlassData[nCh*2+1], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + $40 + (nCh*$80), 3), 64, naGlassData[0]); //Unload Glass Data #2

      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$1 + (nCh*$20), 3), 1); //Glass Data Report
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$5 + (nCh*$20), 3), 1); //Unload Request
      Sleep(500);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0 + (nCh*$20), 3), 1); //Unload Enable
      RequestState_Unload[nCh]:= 1;
    end
    else begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$4 + (nCh*$20), 3), 1); //UnLoad Normal Status
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$4 + (nCh*$20), 3), 1); //Load Normal Status - 상태 설정에서....
  //  Unload GlassData
      if Common.SystemInfo.CHReversal then begin
        ConvertGlassDataToBlock(GlassData[nCh*2 + 1], naGlassData[0]);
        WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + (nCh*$80) , 3), 64, naGlassData[0]); //Unload Glass Data #1

        ConvertGlassDataToBlock(GlassData[nCh*2], naGlassData[0]);
        WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + $40 + (nCh*$80), 3), 64, naGlassData[0]); //Unload Glass Data #2
      end
      else begin
        ConvertGlassDataToBlock(GlassData[nCh*2], naGlassData[0]);
        WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + (nCh*$80) , 3), 64, naGlassData[0]); //Unload Glass Data #1

        ConvertGlassDataToBlock(GlassData[nCh*2+1], naGlassData[0]);
        WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$20+$0 + $40 + (nCh*$80), 3), 64, naGlassData[0]); //Unload Glass Data #2
      end;
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$1 + (nCh*$20), 3), 1); //Glass Data Report
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$5 + (nCh*$20), 3), 1); //Unload Request
      Sleep(500);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$0 + (nCh*$20), 3), 1); //Unload Enable
      RequestState_Unload[nCh]:= 1;
    end;
  end
  else begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$4 + (nCh*$20), 3), 1); //UnLoad Normal Status
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$4 + (nCh*$20), 3), 1); //Load Normal Status - 상태 설정에서....
  //  Unload GlassData
      ConvertGlassDataToBlock(GlassData[nCh*2], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + (nCh*$80) , 3), 64, naGlassData[0]); //Unload Glass Data #1

      ConvertGlassDataToBlock(GlassData[nCh*2+1], naGlassData[0]);
      WriteDeviceBlock('W' + IntToHex(StartAddr_EQP_W+$10*$10+$0 + $40 + (nCh*$80), 3), 64, naGlassData[0]); //Unload Glass Data #2

      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$1 + (nCh*$20), 3), 1); //Glass Data Report
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$5 + (nCh*$20), 3), 1); //Unload Request
      Sleep(500);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 1); //Unload Enable
      RequestState_Unload[nCh]:= 1;
    end

  end;
end;


procedure TCommPLCThread.Execute;
var
  nTick, nPreTick,i: Cardinal;
  nValue: Integer;
  nToggle: Integer;
  nTickToggle: Integer;
begin
  inherited;
  m_nStop:= 0;
  nValue:= 0;
  nToggle:= 0;
  if not UseSimulator then
    CreatePLC;

  nPreTick:= GetTickCount;
  m_nLinkTestTick:= nPreTick;
  nTickToggle:= nPreTick;
  //while not Terminated do begin
  while m_nStop = 0 do begin
    nTick:= GetTickCount;

    if not m_bOpend then begin
      //연결 되지 않음 재 연결
      if g_CommPLC = nil then Exit; //Thread 안에서 종료 시 검사

      WaitForSingleObject(self.Handle, PollingInterval); //간혹 CC Link 이상일 경우 읽기 실패로 연속 처리되는 것 방지

      if g_CommPLC = nil then Exit;  //Thread 안에서 종료 시 검사

      //수동 GIB인경우 연결이 필요 없을 수 있다.
      if not IgnoreConnect then begin

//        TThread.Queue(nil, procedure
//          begin
//            OpenPLC;
//          end);

//          Synchronize(OpenPLC); //Thread에서는 안된다. COM+ not Support Thread.
        OpenPLC;
      end;

//
      if not m_bOpend then begin

        if (not ConnectionError) and (nTick > (nPreTick+ConnectionTimeout)) then begin
          ConnectionError:= True;
          AddLog('Can not Connect **********');
          SendMessageMain(COMMPLC_MODE_CONNECT, 0, 1, 0, 'PLC Connect Fail', nil);

        end;

//        WaitForSingleObject(self.Handle, 5000); //재연결 딜레이

        continue;
      end;
    end;


    Read_PollingData;

    if (nTickToggle - nTick) > 1000 then begin
      nTickToggle:= nTick;
      if nToggle = 0 then begin
        nToggle:= 1;
      end
      else begin
        nToggle:= 0;
      end;
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$01+$8, 3), nToggle, False); //자체 Link Test
    end;
    if Common.SystemInfo.OCType <> DefCommon.OCType then begin
      for I := DefCommon.CH_TOP to DefCommon.CH_BOTTOM do begin
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12 + (i * $20) + $E, 3), ControlDio.IsPreOCInterlockPROBE(i), False);
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12 + (i * $20) + $F, 3), ControlDio.IsPreOCInterlockSHUTTER(i), False);
      end;
    end
    else begin
//      for I := DefCommon.CH1 to DefCommon.MAX_CH do begin
//        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$04 + 8 + i, 3), Ord(not Common.StatusInfo.UseChannel[i]) , False);
//      end;
    end;

//    Synchronize(Read_PollingData); //데이터 폴링
(*
    if nTick > (nPreTick + 1000) then begin
      if nValue <> 0 then begin
        nValue:= 0;
      end
      else begin
        nValue:= 1;
      end;
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$03+$0, 3), nValue); //Link Test
      if (not ConnectionError) and (nTick > (m_nLinkTestTick + 3000)) then begin
        //Link Fail
        ConnectionError:= True;
        AddLog('********** Link Test Expired **********');
        SendMessageMain(COMMPLC_MODE_CONNECT, 0, 2, 0, 'PLC Link Test Expired', nil);
      end;
      nPreTick:= nTick;
    end;
 *)

//    if nTick > (nPreTick + 3000) then begin
//      nPreTick:= nTick;
//      //WriteHeatBeat;
//    end;

    //WriteData;

//    Alarm Que에 꺼내어 처리
// alarm 보고 필요 // Added by sam81 2023-05-01 오후 5:12:12
    if Common.PLCInfo.InlineGIB then begin
      Process_AlarmQue;
    end;

    //MES Que에 꺼내어 처리
//    Process_MESQue;

    //Log 저장
    if (SecondsBetween(Now, m_dtSaveLog) > LogAccumulateSecond) then begin
      AddLog('', True); //단순 저장 요청
    end;

    WaitForSingleObject(self.Handle, PollingInterval);
  end;

end;

procedure TCommPLCThread.Read_ECS_GlassData(nCh: Integer);
var
  naGlassData: array [0..64]of Integer;
  nReturnCode : Integer;
begin
  AddLog('Read_ECS_GlassData ' + IntToStr(nCh));

  ReadDeviceBlock('W' + IntToHex(StartAddr_ECS_W+$10*$0+$0, 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
  ConvertBlockToGlassData(naGlassData[0], ECS_GlassData[nCh]);
end;

procedure TCommPLCThread.Read_PollingData;
var
  nRet: int64;
  i: Integer;
  bChanged: Boolean;
  nValue: Integer;
begin
  //PLC: Robot(물류), ECS

//  Result:= 0;
  nValue := 0;
  //PLC Data
  //Robot 데이터

  //Inspection Special - Conveyor Last Product, Inspection Start, Reset Count
  nRet:= 0;
  if InlineGIB = false then begin
    //Inline
//    nRet := ReadDeviceBlock('B' + IntToHex($1EB0, 3), COMMPLC_CV_DATASIZE, PollingCV[0],m_ResultCV); // Added by KTS 2023-01-18 오후 5:20:33 확인
  end;

  if nRet <> 0 then begin
    AddLog('Polling Last Product ReadDeviceBlock Fail');
    ClosePLC;
//    Result:= 1; //읽기 실패
    Exit;
  end;

  if m_nStop <> 0 then Exit;

  if Terminated then Exit;

//
//  //POCB EQP_ID 시작이 33이다. 33이 1번 장비
//  case EQP_ID of
//    12, 13: begin
//      nRet:= ReadDevice('B230D', nValue); //Robot Door #1 - 1, 2호기
//    end;
//    14, 15: begin
//      nRet:= ReadDevice('B236D', nValue); //Robot Door #3 - 3,4 호기
//    end;
//    16, 17: begin
//      nRet:= ReadDevice('B239D', nValue); //Robot Door #4 - 5,6 호기
//    end;
//    18, 19: begin
//      nRet:= ReadDevice('B240D', nValue); //Robot Door #6 - 7,8, 호기
//    end;
//    20, 21: begin
//      nRet:= ReadDevice('B243D', nValue); //Robot Door #7 - 9, 10 호기
//    end;
//    23, 24: begin
//      nRet:= ReadDevice('B249D', nValue); //Robot Door #9 - 11, 12 호기
//    end;
//    25, 26: begin
//      nRet:= ReadDevice('B249D', nValue); //Robot Door #9 - 11, 12 호기
//    end;
//    27, 28: begin
//      nRet:= ReadDevice('B249D', nValue); //Robot Door #9 - 11, 12 호기
//    end;
//    29, 30: begin
//      nRet:= ReadDevice('B249D', nValue); //Robot Door #9 - 11, 12 호기
//    end;
//    else begin
//(*
//      nRet:= ReadDevice('B233D', nValue); //Robot Door #2
//      nRet:= ReadDevice('B23CD', nValue); //Robot Door #5
//      nRet:= ReadDevice('B246D', nValue); //Robot Door #8
//*)
//    end;
//  end;
//  if nRet <> 0 then begin
//    AddLog('Polling Door Open ReadDevice Fail');
//  end;
  if Common.SystemInfo.OCType = DefCommon.OCType then begin
    nRet := ReadDevice('B' + IntToHex(StartAddr_ROBOT_DOOR_BIT,3), nValue , False);
    if nRet <> 0 then begin
      AddLog('Polling Door Open ReadDevice Fail');
    end;
    if PollingDoorOpened <> nValue then begin
      PollingDoorOpened := nValue;
      if Common.PLCInfo.InlineGIB then begin
        if PollingDoorOpened <> 1 then begin
          AddLog(format('Robot_DoorOpened - EQP #%d', [EQP_ID]));
          SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, 0, COMMPLC_PARAM_DOOR_OPENED, PollingDoorOpened, 'Robot_DoorOpened', nil);
        end;
      end
      else begin
        if PollingDoorOpened <> 0 then begin
          AddLog(format('Robot_DoorOpened - EQP #%d', [EQP_ID]));
          SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, 0, COMMPLC_PARAM_DOOR_OPENED, PollingDoorOpened, 'Robot_DoorOpened', nil);
        end;
      end;
    end;
  end;

  //POCB EQP_ID 시작이 33이다. 33이 1번 장비
  bChanged:= False;
  for i := 0 to Pred(COMMPLC_CV_DATASIZE) do begin
    if (PollingCV[i]) <> (PollingCVPre[i]) then begin
      bChanged:= True; //데이터 변경 됨
      //AddLog(format('<< Changed CV Data %d', [i]));
      break;
    end;
  end;

  if bChanged = True then begin
    Process_CVData; //폴링 데이터 처리
    CopyMemory(@PollingCVPre[0], @PollingCV[0], sizeof(PollingCV[0])* COMMPLC_CV_DATASIZE);
  end;
  //Robot - Load, Unload
//
  Sleep(100);
  m_ResultRobot := 0;
//  TThread.Queue(nil, procedure
//  begin
//    ReadDeviceBlockPro('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0, 3), COMMPLC_ROBOT_DATASIZE, PollingData[0],m_ResultRobot);
//  end);

//  Synchronize(nil,
//  procedure
//  begin
//    ReadDeviceBlock('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0, 3), COMMPLC_ROBOT_DATASIZE, PollingData[0],m_ResultRobot);
//  end
//  );
  if StartAddr2_ROBOT <> 0 then begin
    m_ResultRobot := ReadDeviceBlock('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0, 3), 2, PollingData[0],m_ResultRobot, False);
    m_ResultRobot := ReadDeviceBlock('B' + IntToHex(StartAddr2_ROBOT+$10*$00+$0, 3), 2, PollingData[2],m_ResultRobot,False);
  end
  else begin
    m_ResultRobot := ReadDeviceBlock('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0, 3), m_nRobotDataSize, PollingData[0],m_ResultRobot,False);
  end;
  nRet := m_ResultRobot;
//  nRet := ReadDeviceBlock('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0, 3), COMMPLC_ROBOT_DATASIZE, PollingData[0],m_ResultRobot);
  if nRet <> 0 then begin
    AddLog(format('Polling Robot ReadDeviceBlock Fail: %s ERR CODE : %d ', ['B' + IntToHex(StartAddr_ROBOT, 3),nRet]));
//    Synchronize(ClosePLC);
//    Result:= 1; //읽기 실패
//    Exit;
  end;

  if m_nStop <> 0 then Exit;
  if Terminated then Exit;

  bChanged:= False;
  for i := 0 to Pred(m_nRobotDataSize) do begin
    //if (PollingData[i] and $FE) <> (PollingDataPre[i] and $FE) then begin  //Masking
    if (PollingData[i]) <> (PollingDataPre[i]) then begin
      bChanged:= True; //데이터 변경 됨
      AddLog(format('<< Changed Robot Data %d', [i]));
      break;
    end;
  end;

  if bChanged = True then begin
    //AddLog('<< Process_RobotData');
    Process_RobotData; //폴링 데이터 처리

    //Notify GUI 갱신 메시지
    //SendMessageMain(COMMPLC_MODE_CHANGE_ROBOT, 0, 0, 0, 'ROBOT Chnage Data', nil);
    //이전 데이터 저장
//    CopyMemory(@PollingDataPre[0], @PollingData[0], sizeof(PollingData[0])* COMMPLC_ROBOT_DATASIZE);
    CopyMemory(@PollingDataPre[0], @PollingData[0], sizeof(PollingData[0])* m_nRobotDataSize);
  end;
  Sleep(50);
//    Common.Delay(100);
  //ECS 데이터 읽기
   m_ResultECS := 0;
//   TThread.Queue(nil, procedure
//  begin
//    ReadDeviceBlockPro('B000', 1, PollingECS[COMMPLC_ECS_DATASIZE],m_ResultECS); //공동 데이터
//  end);
//  Synchronize(nil,
//  procedure
//  begin
//    ReadDeviceBlock('B000', 1, PollingECS[COMMPLC_ECS_DATASIZE],m_ResultECS); //공동 데이터
//  end
//  );
  m_ResultECS := ReadDeviceBlock('B000', 1, PollingECS[COMMPLC_ECS_DATASIZE],m_ResultECS, False); //공동 데이터

  nRet := m_ResultECS;
    if nRet <> 0 then begin
    AddLog(format('Polling ECS ReadDeviceBlock Re Fail: %s, ERR CODE : %d', ['B' + IntToHex(StartAddr_ECS+$200*$00+$0, 3),m_ResultECS]));
//    Synchronize(ClosePLC);
////    Result:= 1; //읽기 실패
//    Exit;


  end;

  Sleep(50);

//    Common.Delay(100);
  m_ResultECS :=0;
//  TThread.Queue(nil, procedure
//  begin
//    ReadDeviceBlockPro('B' + IntToHex(StartAddr_ECS+$10*$00+$0, 3), 1, PollingECS[0],m_ResultECS);  // Link Test Request
//  end);
//    Synchronize(nil,
//  procedure
//  begin
//    ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$10*$00+$0, 3), 1, PollingECS[0],m_ResultECS);  // Link Test Request
//  end
//  );
    m_ResultECS := ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$10*$00+$0, 3), 1, PollingECS[0],m_ResultECS, False);  // Link Test Request

  nRet := m_ResultECS;
    if nRet <> 0 then begin
     AddLog(format('Polling ECS ReadDeviceBlock Fail: %s  ERR CODE : %d', ['B'  +IntToHex(StartAddr_ECS+$10*$00+$0, 3),m_ResultECS]));
//    Synchronize(ClosePLC);
////    Result:= 1; //읽기 실패
//    Exit;
  end;
  Sleep(50);

//    Common.Delay(100);
  m_ResultECS :=0;
//     TThread.Queue(nil, procedure
//  begin
//    ReadDeviceBlockPro('B' + IntToHex(StartAddr_ECS+$100+$10*$00+$0, 3), 1, PollingECS[1],m_ResultECS);  // Lost Panel Data Report
//  end);
//    Synchronize(nil,
//  procedure
//  begin
//    ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$100+$10*$00+$0, 3), 1, PollingECS[1],m_ResultECS);  // Lost Panel Data Report
//  end
//  );
    m_ResultECS := ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$100+$10*$00+$0, 3), 1, PollingECS[1],m_ResultECS, False);  // Lost Panel Data Report

  nRet := m_ResultECS;
    if nRet <> 0 then begin
      AddLog(format('Polling ECS ReadDeviceBlock Fail: %s ERR CODE : %d', ['B' + IntToHex(StartAddr_ECS+$200*$00+$0, 3),m_ResultECS]));
//    Synchronize(ClosePLC);
////    Result:= 1; //읽기 실패
//    Exit;

  end;
  Sleep(50);

//    Common.Delay(100);
   m_ResultECS := 0;
//   TThread.Queue(nil, procedure
//  begin
//    ReadDeviceBlockPro('B' + IntToHex(StartAddr_ECS+$200+$10*$00+$0, 3), 1, PollingECS[2],m_ResultECS);  // Take Out Report_Confirm
//  end);
//    Synchronize(nil,
//  procedure
//  begin
//    ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$200+$10*$00+$0, 3), 1, PollingECS[2],m_ResultECS);  // Take Out Report_Confirm
//  end
//  );
   m_ResultECS :=  ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$200+$10*$00+$0, 3), 1, PollingECS[2],m_ResultECS, False);  // Take Out Report_Confirm

  nRet := m_ResultECS;

  if nRet <> 0 then begin
     AddLog(format('Polling ECS ReadDeviceBlock Fail: %s  ERR CODE : %d', ['B' + IntToHex(StartAddr_ECS+$200*$00+$0, 3),m_ResultECS]));
//    Synchronize(ClosePLC);
////    Result:= 1; //읽기 실패
//    Exit;
  end;




//  nRet := ReadDeviceBlock('B000', 1, PollingECS[COMMPLC_ECS_DATASIZE],m_ResultECS); //공동 데이터
//  nRet := ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$10*$00+$0, 3), 1, PollingECS[0],m_ResultECS);  // Link Test Request
//  nRet := ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$100+$10*$00+$0, 3), 1, PollingECS[1],m_ResultECS);  // Lost Panel Data Report
//  nRet := ReadDeviceBlock('B' + IntToHex(StartAddr_ECS+$200+$10*$00+$0, 3), 1, PollingECS[2],m_ResultECS);  // Take Out Report_Confirm
//  if nRet <> 0 then begin
//    AddLog(format('Polling ECS ReadDeviceBlock Fail: %s', ['B' + IntToHex(StartAddr_ECS+$200*$00+$0, 3)]));
//    Synchronize(ClosePLC);
////    Result:= 1; //읽기 실패
//    Exit;
//  end;

  if m_nStop <> 0 then Exit;
  if Terminated then Exit;
  bChanged:= False;
  for i := 0 to COMMPLC_ECS_DATASIZE do begin
    if PollingECS[i] <> PollingECSPre[i] then begin
      bChanged:= True; //데이터 변경 됨
      AddLog(format('<< Changed ECS Data %d', [i]));
      break;
    end;
  end;

  if bChanged = True then begin
    Process_ECSData;

    //SendMessageMain(COMMPLC_MODE_CHANGE_ECS, 0, 0, 0, 'ECS Chnage Data', nil);
    //이전 데이터 저장
    CopyMemory(@PollingECSPre[0], @PollingECS[0], sizeof(PollingECS[0])* (COMMPLC_ECS_DATASIZE+1));
  end;

  Sleep(50);
  //EQP - 상태 표시를 위해 읽기만 한다.
//  for I := 0 to Pred(COMMPLC_EQP_DATASIZE) do begin
//    m_szDevice := 'B' + IntToHex(StartAddr_EQP+$10*i + $00, 3);      // Link Test Request
//    m_nSize := 1;
//    m_lplData :=  0;
//    Synchronize(ReadDeviceBlockProcedre);
//    PollingEQP[i] := m_lplData;
//  end;

//    Common.Delay(100);
  m_ResultEQP := 0;
//     TThread.Queue(nil, procedure
//  begin
//    ReadDeviceBlockPro('B' + IntToHex(StartAddr_EQP+$10*$00+$0, 3), COMMPLC_EQP_DATASIZE, PollingEQP[0],m_ResultEQP);
//  end);
//  Synchronize(nil,
//  procedure
//  begin
//    ReadDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$00+$0, 3), COMMPLC_EQP_DATASIZE, PollingEQP[0],m_ResultEQP);
//  end
//  );

  m_ResultEQP :=  ReadDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$00+$0, 3), COMMPLC_EQP_DATASIZE, PollingEQP[0],m_ResultEQP, False);

  nRet := m_ResultEQP;

  if nRet <> 0 then begin
      AddLog(format('Polling EQP ReadDeviceBlock Fail: %s  ERR CODE : %d', ['B' + IntToHex(StartAddr_EQP+$10*$00+$0, 3),m_ResultEQP]));
//   Synchronize(ClosePLC);
////    Result:= 1; //읽기 실패
//    Exit;

  end;



////  nRet := ReadDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$00+$0, 3), COMMPLC_EQP_DATASIZE, PollingEQP[0],m_ResultEQP);
//  if nRet <> 0 then begin
//    AddLog(format('Polling EQP ReadDeviceBlock Fail: %s', ['B' + IntToHex(StartAddr_EQP, 3)]));
//    Synchronize(ClosePLC);
////    Result:= 1; //읽기 실패
//    Exit;
//  end;

end;

function TCommPLCThread.WriteData: Integer;
begin
  Result:= 0;
  if Terminated then Exit;

end;


procedure TCommPLCThread.Process_RobotData;
var
  i, k: Integer;
  nValue: Integer;
  nIndex: Integer;
begin
  //폴링한 데이터 처리
try
  for i := 0 to Pred(m_nRobotDataSize) do begin
//    AddLog(format('<< COMMPLC_ROBOT_DATASIZE  %d', [ i]),True);
    if  PollingData[i] = PollingDataPre[i] then continue;

    for k := 0 to 15 do begin
      nValue:= Get_Bit(PollingData[i], k);
      if nValue <> Get_Bit(PollingDataPre[i], k) then begin
        nIndex:= i*16 + k;
        AddLog(format('<< ChangedDevice ROBOT %s: %d', ['B' + IntToHex(StartAddr_ROBOT+nIndex, 3), nValue]), True);

        case nIndex of
          $01: begin //Galss Data Report
            if nValue <> 0 then Process_ROBOT_GlassData_Report(0)
          end;
          $21: begin //Galss Data Report
            if nValue <> 0 then Process_ROBOT_GlassData_Report(1)
          end;

          $41: begin //Galss Data Report
            if nValue <> 0 then Process_ROBOT_GlassData_Report(2)
          end;
          $61: begin //Galss Data Report
            if nValue <> 0 then Process_ROBOT_GlassData_Report(3)
          end;

          $03: begin //Load Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_LoadComplete(0)
            else  Process_ROBOT_LoadComplete_Off(0);
          end;
          $23: begin //Load Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_LoadComplete(1)
            else  Process_ROBOT_LoadComplete_Off(1);
          end;

          $43: begin //Load Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_LoadComplete(2)
            else  Process_ROBOT_LoadComplete_Off(2);
          end;
          $63: begin //Load Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_LoadComplete(3)
            else  Process_ROBOT_LoadComplete_Off(3);
          end;

          $13: begin //UnLoad Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_UnloadComplete(0)
            else  Process_ROBOT_UnloadComplete_Off(0);
          end;
          $33: begin //UnLoad Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_UnloadComplete(1)
            else  Process_ROBOT_UnloadComplete_Off(1);
          end;

          $53: begin //UnLoad Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_UnloadComplete(2)
            else  Process_ROBOT_UnloadComplete_Off(2);
          end;
          $73: begin //UnLoad Complete
            //조건 검사 필요
            if nValue <> 0 then Process_ROBOT_UnloadComplete(3)
            else  Process_ROBOT_UnloadComplete_Off(3);
          end;

          $12: begin  //Robot Unload Busy
            if nValue = 0 then Process_ROBOT_UnloadBusy_Off(0)
            else Process_ROBOT_UnloadBusy_On(0)
          end;
          $32: begin  //Robot Unload Busy
            if nValue = 0 then Process_ROBOT_UnloadBusy_Off(1)
            else Process_ROBOT_UnloadBusy_On(1)
          end;
          $52: begin  //Robot Unload Busy
            if nValue = 0 then Process_ROBOT_UnloadBusy_Off(2)
            else Process_ROBOT_UnloadBusy_On(2)
          end;
          $72: begin  //Robot Unload Busy
            if nValue = 0 then Process_ROBOT_UnloadBusy_Off(3)
            else Process_ROBOT_UnloadBusy_On(3)
          end;


          $02: begin //Robot Load Busy
            if nValue = 0 then Process_ROBOT_LoadBusy_Off(0)
            else Process_ROBOT_LoadBusy_On(0);
          end;
          $22: begin //Robot Load Busy
            if nValue = 0 then Process_ROBOT_LoadBusy_Off(1)
            else Process_ROBOT_LoadBusy_On(1);
          end;

          $42: begin //Robot Load Busy
            if nValue = 0 then Process_ROBOT_LoadBusy_Off(2)
            else Process_ROBOT_LoadBusy_On(2);
          end;
          $62: begin //Robot Load Busy
            if nValue = 0 then Process_ROBOT_LoadBusy_Off(3)
            else Process_ROBOT_LoadBusy_On(3);
          end;
          $04, $14, $24, $34: begin
            if nValue = 0 then Process_Robot_Normal_Off(nIndex div 10, nValue);
          end;

          $1D: begin //Robot Inspection Start
            //Process_ROBOT_InspectionStart(0, nValue);
          end;
          $3D: begin //Robot Inspection Start
            //Process_ROBOT_InspectionStart(1, nValue);
          end;

          $1E: begin //Robot Reset Count
            //Process_ROBOT_ResetCount(0, nValue);
          end;
          $3E: begin //Robot Reset Count
            //Process_ROBOT_ResetCount(1, nValue);
          end;

          $1F: begin //Robot Last Product
            //Process_ROBOT_LastProduct(0, nValue);
          end;
          $3F: begin //Robot Last Product
            //Process_ROBOT_LastProduct(1, nValue);
//            if InlineGIB = True then begin
//              //Inline GIB - 조립라인은 시작 주소가 5600부터- 궁여지책
//              AddLog(format('Process_ROBOT_LastProduct Index=%d, Value=%d', [nIndex, nValue]));
//              nIndex:= (EQP_ID - 33) div 4; //Zone 구분을 위한 계산  0=A Zone, 1=B Zone, 2=C zone
//              SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nIndex, COMMPLC_PARAM_LAST_PRODUCT, nValue, 'Process_ROBOT_LastProduct', nil);
//            end;
          end;

          else begin
            //SendMessageMain(COMMPLC_MODE_CHANGE_ROBOT, 0, nIndex, 0, 'ROBOT Chnage Data', nil);
            //PostMessage(MessageHandle, WM_USER + 1, COMMPLC_MODE_CHANGE_ROBOT, nIndex + nValue*65536);
          end;
        end; //case nIndex of
      end; //if nValue <> Get_Bit(PollingDataPre[i], k) then begin
    end; //for k := 0 to 15 do begin
  end; //for i := 0 to Pred(COMMPLC_ROBOT_DATASIZE) do begin

Except
  on E: Exception do begin
    AddLog(format('Exception On Process_RobotData - %s', [E.Message]), True);
  end;
end;
end;


procedure TCommPLCThread.Process_CVData;
var
  i, k: Integer;
  nValue: Integer;
  nIndex: Integer;
begin
  for i := 0 to Pred(COMMPLC_CV_DATASIZE) do begin
    if  PollingCV[i] = PollingCVPre[i] then continue;

    for k := 4 to 15 do begin
      nValue:= Get_Bit(PollingCV[i], k);
      if nValue <> Get_Bit(PollingCVPre[i], k) then begin
        nIndex:= i*16 + k;
        AddLog(format('<< ChangedDevice CV %s: %d', ['B' + IntToHex($1EB0 + nIndex, 3), nValue]), True);

        case nIndex of
          $06, $07, $08: begin //Last Product - 잔량 처리 6=A Zone, 7=B Zone, 8=C zone
//            AddLog(format('Process_CV_LastProduct Index=%d, Value=%d', [nIndex, nValue]));
//            SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nIndex-6, COMMPLC_PARAM_LAST_PRODUCT, nValue, 'Process_CV_LastProduct', nil);
          end;

          $20 .. $3D: begin
            //Reset Count - 아직 사용 안함
          end;

          $3F: begin
            //Inspection All Count Reset - 아직 사용 안함
          end;
        end;
      end;
    end;
  end;
end;

procedure TCommPLCThread.Process_AlarmQue;
var
  item: TAlarmItem;
  nTick: Cardinal;
begin
  if m_AlarmQue.IsEmpty then Exit;
  nTick:= GetTickCount;
  if nTick - m_nLastAlarmTick < 1000 then Exit;

  item:= m_AlarmQue.Dequeue;
  Synchronize(nil,
  procedure
  begin
    ECS_Alarm_Report(item.AlarmType, item.AlarmCode, item.AlarmValue);
  end
  );
//  ECS_Alarm_Report(item.AlarmType, item.AlarmCode, item.AlarmValue);
  m_nLastAlarmTick:= nTick;
end;

procedure TCommPLCThread.Process_MESQue;
var
  Item: TMESItem;
  nTick: Cardinal;
  nValue: Integer;
  nRet: Integer;
begin
  if m_MESQue.IsEmpty then Exit;
  if m_MESQue.Working then Exit; //현재 아이템 진행 중이면


  // 명령의 응답을 기다려야 하므로 개별 쓰레드로 동작 해야 한다. 아닐 경우 응답 데이터 인지 못함
  TThread.CreateAnonymousThread( procedure begin
    nTick:= GetTickCount;
    if nTick - m_nLastMESTick < 1000 then Exit;

    m_MESQue.Working:= True;
    Item:= m_MESQue.Dequeue;
    case Item.Kind of
      COMMPLC_MES_KIND_PCHK: begin
        nRet:= ECS_PCHK(Item.Value.Channel, Item.Value.SerialNo);
        if nRet <> 0 then begin
          AddLog(format('ECS_PCHK NG - %d', [nRet]));
        end
        else begin
          //Item.Value.LCM_ID:= ECS_LCM_ID[Item.Value.Channel];
          Item.Value.LCM_ID:= ECS_GlassData[Item.Value.Channel].LCM_ID;
        end;
      end;

      COMMPLC_MES_KIND_EICR: begin
        //nRet:= ECS_EICR(Item.Value.Channel, ECS_LCM_ID[Item.Value.Channel], Item.Value.ErrorCode, Item.Value.InspectionResult);
        nRet:= ECS_EICR(Item.Value.Channel, ECS_GlassData[Item.Value.Channel].LCM_ID, Item.Value.ErrorCode, Item.Value.InspectionResult);
        if nRet <> 0 then begin
          AddLog(format('ECS_EICR NG - %d', [nRet]));
        end
        else begin

        end;
      end;

      COMMPLC_MES_KIND_APDR: begin
        nRet:= ECS_APDR(Item.Value.Channel, Item.Value.InspectionResult);
        if nRet <> 0 then begin
          AddLog(format('ECS_APDR NG - %d', [nRet]));
        end
        else begin

        end;
      end;

      COMMPLC_MES_KIND_ZSET: begin
        nRet:= ECS_ZSET(Item.Value.Channel, Item.Value.BondingType, Item.Value.CarrierID, Item.Value.SerialNo, Item.Value.PcbID, nValue);
        if nRet <> 0 then begin
          AddLog(format('ECS_ZSET NG - %d', [nRet]));
        end
        else begin

        end;
      end;
      else begin

      end;

      if nRet <> 0 then begin

      end
      else begin

      end;

    end; //case Item.Kind of
    //응답 처리
    Item.Value.Ack:= nRet;
    if Assigned(Item.NotifyEvent) then Item.NotifyEvent(Item.Value);
    //SetEvent(Item.EventHandle);
    m_nLastMESTick:= GetTickCount;
    m_MESQue.Working:= False;
  end).Start;
end;

procedure TCommPLCThread.Process_ECSData;
var
  i, k: Integer;
  nValue: Integer;
  nIndex: Integer;
begin
  //폴링한 데이터 처리
  for i := 0 to COMMPLC_ECS_DATASIZE do begin   //공용 데이터 포함이므로 Pred 안함
    if  PollingECS[i] = PollingECSPre[i] then continue;

    for k := 0 to 15 do begin
      nValue:= Get_Bit(PollingECS[i], k);
      if nValue <> Get_Bit(PollingECSPre[i], k) then begin
        nIndex:= i*16 + k;
        if i = COMMPLC_ECS_DATASIZE then begin
          AddLog(format('<< ChangedDevice ECS Common %s:: %d', ['B' + IntToHex(0, 3), nValue]), True);
        end
        else begin
          AddLog(format('<< ChangedDevice ECS %s: %d', ['B' + IntToHex(StartAddr_ECS+nIndex, 3), nValue]), True);
        end;
        if Common.SystemInfo.OCType = DefCommon.OCType then begin
          if Common.PLCInfo.InlineGIB then begin
            if nIndex = (EQP_ID + 10) mod 16 then  begin
               WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$1, 3), nValue); //Link Test
               m_nLinkTestTick:= GetTickCount;
            end;
          end
          else begin
            if nIndex = (EQP_ID + 13) mod 16 then  begin
               WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$1, 3), nValue); //Link Test
               m_nLinkTestTick:= GetTickCount;
            end;
          end;
        end
        else begin
          if nIndex = (EQP_ID + 13) mod 16 then  begin
             WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$00+$1, 3), nValue); //Link Test
             m_nLinkTestTick:= GetTickCount;
          end;
        end;


        case nIndex of



          $01: ; //Take-Out Report ACK

          $0F: begin  //AAB Mode
//            SendMessageMain(COMMPLC_MODE_EVENT_ECS, nIndex, COMMPLC_PARAM_AAB_MODE, nValue, 'AAB Mode Changed', nil);
          end;

          $10: begin  //APD Report_ACK

          end;
          $11: begin  //User ID Check Request
            //
          end;
          $20: begin  //Inspection Data Report Confirm #1
            //
          end;
          $21: begin  //Inspection Data  Confirm #1
            //
          end;
//          $30: begin  //BCR #1 Read Report Confirm
//            if nValue = 1 then WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$06+$8, 3), 0); ////Inspection Data Confirm ACK Off
//          end;

          $30: begin  //공통 데이터 - ECS Restart(2 sec)
            TThread.CreateAnonymousThread(
              procedure begin
                g_CommPLC.ECS_ECSRestart_Test;

              end
              ).Start;
          end;


          $31: begin  //공통 데이터 - Time Data Send
//            if not UseSimulator then begin
//              if nValue = 1 then ReadTimeData;
//            end;
            if nValue = 1 then ReadTimeData;
          end;
//          $31: begin  //공통 데이터 - ECS Start
//          end;

          $3D: begin  //AAB Mode
            //SendMessageMain(COMMPLC_MODE_EVENT_ECS, nIndex, COMMPLC_PARAM_AAB_MODE, nValue, 'AAB Mode Changed', nil);
          end;

          else begin
            //SendMessageMain(COMMPLC_MODE_CHANGE_ECS, 0, nIndex, 0, 'ECS Chnage Data', nil);

            PostMessage(MessageHandle, WM_USER + 1, COMMPLC_MODE_CHANGE_ECS, nIndex + nValue*65536);
          end;
        end; //case nIndex of
      end; //if nValue <> Get_Bit(PollingDataPre[i], k) then begin
    end; //for k := 0 to 15 do begin
  end; //for i := 0 to Pred(COMMPLC_ECS_DATASIZE) do begin
end;

procedure TCommPLCThread.Read_ROBOT_GlassData(nCh: Integer);
var
  naGlassData: array [0..64]of Integer;
  nReturnCode : Integer;
begin
  AddLog('Process_ROBOT_GlassData_Read ' + IntToStr(nCh));
  if InlineGIB then begin
//    ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0 +(nCH * $80), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data  end
    ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0 +(nCH * $40), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data  end
    ConvertBlockToGlassData(naGlassData[0], GlassData[nCh]);
  end
  else begin
    if (nCh = 1 ) and (StartAddr2_ROBOT_W <> 0) then
      ReadDeviceBlock('W' + IntToHex(StartAddr2_ROBOT_W+$10*$0+$0 , 3), 64, naGlassData[0],nReturnCode) //Load #1 Glass Data  end
    else
      ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0 +(nCH * $80), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data  end

    if Common.SystemInfo.CHReversal then
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2+1])                 // Added by KTS 2023-03-23 오후 6:14:43
    else
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2]);

    if (nCh =1 ) and (StartAddr2_ROBOT_W <> 0) then
      ReadDeviceBlock('W' + IntToHex(StartAddr2_ROBOT_W+$10*$0+$40 , 3), 64, naGlassData[0],nReturnCode) //Load #1 Glass Data
    else
      ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$40 + (nCh * $80), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data

    if Common.SystemInfo.CHReversal then
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2])                 // Added by KTS 2023-03-23 오후 6:14:43
    else
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2+1]);
  end;
end;

procedure TCommPLCThread.Process_ROBOT_GlassData_Report(nCh: Integer);
var
  naGlassData: array [0..64]of Integer;
  nReturnCode : Integer;
begin

  RequestState_Load[nCh]:= 2; //Request

  AddLog('Process_ROBOT_GlassData_Report ' + IntToStr(nCh));
  if Common.PLCInfo.InlineGIB then begin
    ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0+(nCh *$40), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
    ConvertBlockToGlassData(naGlassData[0], GlassData[nCh]);
    AddLog('ROBOT_Load Request ' + IntToStr(nCh));
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$5 + (nCh*$20), 3), 1); //Load Request
//    Sleep(100);
    Sleep(100);
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 1); //UnLoad Enable

    Sleep(100);
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$0 + (nCh*$20), 3), 1); //Load Enable

    RequestState_Load[nCh]:= 2; //Load Enable
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_GALSSDATA_REPORT, 0,
    format('%s (%s)', [GlassData[nCh*2].CarrierID, GlassData[nCh*2].GlassID]), nil);
  end
  else begin
    if (nCh =1) and (StartAddr2_ROBOT_W <> 0) then
      ReadDeviceBlock('W' + IntToHex(StartAddr2_ROBOT_W+$10*$0+$0, 3), 64, naGlassData[0],nReturnCode) //Load #1 Glass Data
    else
      ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$0+(nCh *$80), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
    if Common.SystemInfo.CHReversal then
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2+1])                 // Added by KTS 2023-03-23 오후 6:14:43
    else
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2]);
    if (nCh =1) and (StartAddr2_ROBOT_W <> 0) then
      ReadDeviceBlock('W' + IntToHex(StartAddr2_ROBOT_W+$10*$0+$40, 3), 64, naGlassData[0],nReturnCode) //Load #1 Glass Data
    else
      ReadDeviceBlock('W' + IntToHex(StartAddr_ROBOT_W+$10*$0+$40+(nCh *$80), 3), 64, naGlassData[0],nReturnCode); //Load #1 Glass Data
    if Common.SystemInfo.CHReversal then
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2])                 // Added by KTS 2023-03-23 오후 6:14:43
    else
      ConvertBlockToGlassData(naGlassData[0], GlassData[nCh*2+1]);
    AddLog('ROBOT_Load Request ' + IntToStr(nCh));

    if Common.SystemInfo.OCType = DefCommon.OCType then  begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5 + (nCh*$20), 3), 1); //Load Request
      Sleep(100);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0 + (nCh*$20), 3), 1); //Load Enable
    end
    else begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$5 + (nCh*$20), 3), 1); //Load Request
      Sleep(100);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$0 + (nCh*$20), 3), 1); //Load Enable
    end;
    RequestState_Load[nCh]:= 2; //Load Enable

    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_GALSSDATA_REPORT, 0,
    format('%s (%s), %s (%s)', [GlassData[nCh*2].CarrierID, GlassData[nCh*2].GlassID, GlassData[nCh*2+1].CarrierID, GlassData[(StageNo*4)+nCh*2+1].GlassID]), nil);
  end;

(*
  //일정 시간안에 Robot Busy가 설정되지 않으면 Alarm
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$01+$2 + (nCh*$20), 3), 1, 30000); //Robot Busy
  if nRet <> 0 then begin
    //오류- Alarm
    AddLog('ROBOT_Load_Request Timeout Robot Busy');
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADGLASSDATA, 1, 'Process_GlassData_Report', nil);
  end
  else begin
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADGLASSDATA, 0, 'Process_GlassData_Report', nil);
  end;
*)
end;


procedure TCommPLCThread.Process_ROBOT_LastProduct(nCh, nValue: Integer);
begin
  AddLog(format('Process_ROBOT_LastProduct Ch=%d, Value=%d', [nCh, nValue]));
  if nValue <> 0 then begin
    //EQP_Clear_ROBOT_Request;
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$F, 3), 1); //Last Product Confirm On
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0E+$F, 3), 1); //Last Product Confirm On
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LAST_PRODUCT, 0, 'Process_ROBOT_LastProduct', nil);
  end
  else begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$F, 3), 0); //Last Product Confirm Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0E+$F, 3), 0); //Last Product Confirm Off
  end;
end;

procedure TCommPLCThread.Process_ROBOT_InspectionStart(nCh, nValue: Integer);
begin
  AddLog(format('Process_ROBOT_InspectionStart Ch=%d, Value=%d', [nCh, nValue]));
  if nValue <> 0 then begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$D, 3), 0); //Ready To Start Off #1
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0E+$D, 3), 0); //Ready To Start Off #2
    //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$D + (nCh*$20), 3), 1); //Inspection Start Confirm
    (*
    ReadDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$D + (nCh*$20), 3), lpData);
    if lpData <> 1 then begin
      AddLog('Write Fail - Inspection Start Confirm');
    end;
    *)
//    if WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$D + (nCh*$20), 3), 1) <> 0 then begin  //Inspection Start Confirm
//
//    end;

    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_INSPECTION_START, 0, 'Process_ROBOT_InspectionStart', nil);
  end
  else begin
    //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$D, 3), 0); //Inspection Start Confirm Off #1
    //WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0E+$D, 3), 0); //Inspection Start Confirm Off #2
  end;
end;

procedure TCommPLCThread.Process_ROBOT_LoadComplete(nCh: Integer);
begin
  AddLog('Process_ROBOT_LoadComplete ' + IntToStr(nCh));
  //Glass Data 읽어 변수에 저장
  Read_ROBOT_GlassData(nCh);   // Added by KTS 2023-03-23 오후 8:21:15
  if InlineGIB then begin
    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$1 + (nCh*$20), 3), 0); //Glass Data Request off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$5 + (nCh*$20), 3), 0); //Load Request off
      Sleep(100);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$6 + (nCh*$20), 3), 1); //Load Complete Confrim
    end;
  end
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$1 + (nCh*$20), 3), 0); //Glass Data Request off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$5 + (nCh*$20), 3), 0); //Load Request off
      Sleep(100);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$6 + (nCh*$20), 3), 1); //Load Complete Confrim
    end
    else begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$1 + (nCh*$20), 3), 0); //Glass Data Request off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$5 + (nCh*$20), 3), 0); //Load Request off
      Sleep(100);
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$6 + (nCh*$20), 3), 1); //Load Complete Confrim
    end;
  end;
  RequestState_Load[nCh]:= 3; //Load Complete Confrim

  SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADCOMPLETE, 1, 'Process_ROBOT_LoadComplete ' + IntToStr(nCh), nil);
end;

procedure TCommPLCThread.Process_ROBOT_LoadComplete_Off(nCh: Integer);
begin
  AddLog('Process_ROBOT_LoadComplete_Off ' + IntToStr(nCh));
  if InlineGIB then begin
    if Common.SystemInfo.OCType = DefCommon.OCType then
          WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$6 + (nCh*$20), 3), 0) //Load Complete Confrim off
    else  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$6 + (nCh*$20), 3), 0); //Load Complete Confrim off
  end
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then
          WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$6 + (nCh*$20), 3), 0) //Load Complete Confrim off
    else  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$6 + (nCh*$20), 3), 0); //Load Complete Confrim off
  end;
  SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADCOMPLETE, 0, 'Process_ROBOT_LoadComplete_Off ' + IntToStr(nCh), nil);
end;

procedure TCommPLCThread.Process_ROBOT_Normal_Off(nCh, nValue: Integer);
begin
  if nValue = 0 then begin
    if (RequestState_Unload[0] = 1) or (RequestState_Load[0] = 1)
      or (RequestState_Unload[1] = 1) or (RequestState_Load[1] = 1) then begin
      //Interface 중 Normal Off됨 //Alarm
      SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_INTERFACE_ERROR, 1, 'Process_ROBOT_Normal_Off', nil);
    end;
  end;
end;

procedure TCommPLCThread.Process_ROBOT_ResetCount(nCh, nValue: Integer);
begin
  AddLog(format('Process_ROBOT_ResetCount Ch=%d, Value=%d', [nCh, nValue]));
  if nValue <> 0 then begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$E + (nCh*$20), 3), 1); //ResetCount Confirm
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_RESET_COUNT, 0, 'Process_ROBOT_ResetCount', nil);
  end
  else begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$E + (nCh*$20), 3), 0); //ResetCount Confirm Off
  end;
end;

procedure TCommPLCThread.Process_ROBOT_LoadBusy_On(nCh: Integer);
begin
  if RequestState_Load[nCh] < 1 then begin
    //요청이 없는데 들어오는 경우 방지
    AddLog('Process_ROBOT_LoadBusy_On Error - Not Request Ch ' + IntToStr(nCh));
    //Alarm
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_INTERFACE_ERROR, 1, 'Process_ROBOT_LoadBusy_On Error - Not Request Ch ' + IntToStr(nCh), nil);
    Exit;
  end;
  AddLog('Process_ROBOT_LoadBusy_On ' + IntToStr(nCh));
  SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADBUSY, 1, 'Process_ROBOT_LoadBusy_On ' + IntToStr(nCh), nil);
end;

procedure TCommPLCThread.Process_ROBOT_LoadBusy_Off(nCh: Integer);
begin
  AddLog('Process_ROBOT_LoadBusy_Off ' + IntToStr(nCh), True);

  if Common.PLCInfo.InlineGIB then begin
  if not IsBusy_Robot_Each(nCh) then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$0 + (nCh*$20), 3), 0); //Load Enable off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 0); //Unload Enable Off
    end;
  end
  else begin
    if not IsBusy_Robot(nCh) then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0 + (nCh*$20), 3), 0); //Load Enable off
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0 + (nCh*$20), 3), 0); //Unload Enable Off
      end
      else begin
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$0 + (nCh*$20), 3), 0); //Load Enable off
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$0 + (nCh*$20), 3), 0); //Unload Enable Off
      end;
    end;
  end;

  RequestState_Load[nCh]:= 0;
//  AddLog('SendMessageMain COMMPLC_PARAM_LOADBUSY SendMessageMain ' + IntToStr(nCh), True);
  if Common.PLCInfo.InlineGIB then begin
    if ControlDio.IsDetected(nCh) then
      SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADBUSY, 0, 'Process_ROBOT_LoadBusy_Off ' + IntToStr(nCh), nil);
  end
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then
      SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADBUSY, 0, 'Process_ROBOT_LoadBusy_Off ' + IntToStr(nCh), nil)
    else begin
      if ControlDio.IsDetected(nCh) then
        SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_LOADBUSY, 0, 'Process_ROBOT_LoadBusy_Off ' + IntToStr(nCh), nil);
    end;
  end;
//  AddLog('SendMessageMain COMMPLC_PARAM_LOADBUSY SendMessageMain Done ' + IntToStr(nCh), True);

end;

procedure TCommPLCThread.Process_ROBOT_UnloadComplete(nCh: Integer);
begin
  AddLog('Process_ROBOT_UnloadComplete ' + IntToStr(nCh));
  if Common.SystemInfo.OCType = DefCommon.PreOCType then begin
    Sleep(300);
  end;
  if Common.PLCInfo.InlineGIB then begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$6 + (nCh*$20), 3), 1); //Unload Complete Confrim
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$5 + (nCh*$20), 3), 0); //Unload Request Off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$1 + (nCh*$20), 3), 0); //Glass Data Request Off
  end
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$6 + (nCh*$20), 3), 1); //Unload Complete Confrim
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$5 + (nCh*$20), 3), 0); //Unload Request Off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$1 + (nCh*$20), 3), 0); //Glass Data Request Off
    end
    else begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$6 + (nCh*$20), 3), 1); //Unload Complete Confrim
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$5 + (nCh*$20), 3), 0); //Unload Request Off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$1 + (nCh*$20), 3), 0); //Glass Data Request Off
    end;
  end;
  SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_UNLOADCOMPLETE, 1, 'Process_ROBOT_UnloadComplete ' + IntToStr(nCh), nil);
end;

procedure TCommPLCThread.Process_ROBOT_UnloadComplete_Off(nCh: Integer);
begin
  AddLog('Process_ROBOT_UnloadComplete_Off ' + IntToStr(nCh));
  if Common.PLCInfo.InlineGIB then
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$6 + (nCh*$20), 3), 0) //Unload Complete Confrim Off

  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$6 + (nCh*$20), 3), 0) //Unload Complete Confrim Off
    else  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$6 + (nCh*$20), 3), 0); //Unload Complete Confrim Off
  end;
  SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_UNLOADCOMPLETE, 0, 'Process_ROBOT_UnloadComplete_Off ' + IntToStr(nCh), nil);
(*
  //nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$0E+$2, 3), 0, 3000); //Robot Busy - 불간섭만 확인해도 될 듯
  nRet:= WaitSignal('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0 + (nCh*$20), 3), 1, 30000); //Unload Noninterference
  if nRet <> 0 then begin
    //오류
    AddLog('Process_UnloadComplete NG ' + IntToStr(nCh));
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_UNLOADCOMPLETE_OFF, 1, 'Process_UnloadComplete_Off NG ' + IntToStr(nCh), nil);
    Exit;
  end;
  WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0 + (nCh*$20), 3), 0); //Unload Enable
  AddLog('Process_UnloadComplete OK ' + IntToStr(nCh));
  SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_UNLOADCOMPLETE_OFF, 0, 'Process_UnloadComplete_Off OK ' + IntToStr(nCh), nil);
*)
end;

procedure TCommPLCThread.Process_ROBOT_UnloadBusy_On(nCh: Integer);
begin
  if RequestState_Unload[nCh] < 1 then begin
    AddLog('Process_ROBOT_UnloadBusy_On Error - Not Request Ch=' + IntToStr(nCh), True);
    //Alarm
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_INTERFACE_ERROR, 1, 'Process_ROBOT_UnloadBusy_On Error - Not Request Ch ' + IntToStr(nCh), nil);
    Exit;
  end;
  AddLog('Process_ROBOT_UnloadBusy_On ' + IntToStr(nCh));
  SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_UNLOADBUSY, 1, 'Process_ROBOT_UnloadBusy_On ' + IntToStr(nCh), nil);
end;

procedure TCommPLCThread.Process_ROBOT_UnloadBusy_Off(nCh: Integer);
begin
  AddLog('Process_ROBOT_UnloadBusy_Off ' + IntToStr(nCh), True);
  if Common.PLCInfo.InlineGIB then begin
    if IsBusy_Robot_Each(nCH) then begin
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$0 + (nCh*$20), 3), 0); //Load Enable off
      WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$0 + (nCh*$20), 3), 0); //Unload Enable Off
    end;
  end
  else begin
    if not IsBusy_Robot(nCh) then begin
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0C+$0 + (nCh*$20), 3), 0); //Load Enable off
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$0D+$0 + (nCh*$20), 3), 0); //Unload Enable Off
      end
      else begin
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$12+$0 + (nCh*$20), 3), 0); //Load Enable off
        WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$13+$0 + (nCh*$20), 3), 0); //Unload Enable Off
      end;
    end;
  end;
  RequestState_Unload[nCh]:= 0;

  AddLog('SendMessageMain COMMPLC_PARAM_UNLOADBUSY ' + IntToStr(nCh), True);
  if Common.SystemInfo.OCType = DefCommon.OCType then
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_UNLOADBUSY, 0, 'Process_ROBOT_UnloadBusy_Off ' + IntToStr(nCh), nil)
  else begin
   if not ControlDio.IsDetected(nCh) then
    SendMessageMain(COMMPLC_MODE_EVENT_ROBOT, nCh, COMMPLC_PARAM_UNLOADBUSY, 0, 'Process_ROBOT_UnloadBusy_Off ' + IntToStr(nCh), nil)
  end;
  AddLog('SendMessageMain COMMPLC_PARAM_UNLOADBUSY Done ' + IntToStr(nCh), True);
  end;

procedure TCommPLCThread.PulseDevice(const szDevice: String; nDelay: Integer);
begin
  if szDevice[1] <> 'B' then Exit;
  TThread.CreateAnonymousThread(
    procedure begin
      WriteDevice(szDevice, 1);
      WaitForSingleObject(self.Handle, nDelay);
      WriteDevice(szDevice, 0);
    end).Start;
end;

procedure TCommPLCThread.PulseDeviceBit(const szDevice: String; nBitLoc, nDelay: Integer);
begin
  if szDevice[1] = 'B' then begin
    AddLog(format('WritePluseDevice Addr=%s On -> Off (Delay=%d)', [szDevice, nDelay]));
    TThread.CreateAnonymousThread(
      procedure begin
        WriteDevice(szDevice, 1 ,false);
        WaitForSingleObject(self.Handle, nDelay);
        WriteDevice(szDevice, 0, false);
      end).Start;
  end
  else begin
    AddLog(format('WritePluseDeviceBit Addr=%s On -> Off (Delay=%d)', [szDevice, nDelay]));
    TThread.CreateAnonymousThread(
      procedure begin
        WriteDeviceBit(szDevice, nBitLoc, 1, false);
        WaitForSingleObject(self.Handle, nDelay);
        WriteDeviceBit(szDevice, nBitLoc, 0, false);
      end).Start;
  end;
end;
//
//function TCommPLCThread.ReadDevice(szDevice: string; var lplData: integer): integer;
//var
//  nReturnCode: integer;
//begin
//  Result := 1;
//  nReturnCode := 0;
//
//  try
//    if UseSimulator then
//    begin
//      if frmPlcSimulate <> nil then
//        Result := frmPlcSimulate.GetDevice(szDevice, lplData);
//    end
//    else
//    begin
//      Synchronize(
//        procedure
//        var
//          localData: integer;
//        begin
//          m_ActUtl.GetDevice(szDevice, localData, nReturnCode);
//          lplData := localData;
//        end);
//      Result := nReturnCode;
//    end;
//  except
//    on E: Exception do
//    begin
//      AddLog(Format('Exception On ReadDevice - %s', [E.Message]), True);
//    end;
//  end;
//end;

//
//function TCommPLCThread.ReadDevice( szDevice: String; var lplData: integer): integer;
//
//var
//nReturnCode : Integer;
//nTEst : Int64;
//
//begin
//
////  if not Connected then Exit(1);
//
//  Result:= 1;
//  nReturnCode := 0;
//  //m_csWrite.Enter;
//  try
//    try
//      if UseSimulator then
//      begin
//        if frmPlcSimulate <> nil then
//            Result:= frmPlcSimulate.GetDevice(szDevice, lplData);
//      end else
//      begin
//        Synchronize(nil,
//        procedure
//         var
//          localData: Integer; // 로컬 변수를 선언하여 lplData 변수를 캡처함
//          begin
//            m_ActUtl.GetDevice(szDevice, localData,nReturnCode);
//            lplData := localData;
//          end
//        );
//        Result := nReturnCode;
////        Result := m_ActUtl.GetDevice(szDevice, lplData);
////       Result := m_ActUtl.GetDevice(szDevice, lplData,nReturnCode);
////        AddLog(Format('szDevice : %s lplData : %s',[szDevice,IntToHex(lplData)] ));
//      end;
//    except
//      ON E: Exception do begin
//        AddLog(format('Exception On ReadDevice - %s', [E.Message]), True);
//      end;
//    end;
//  finally
//    //m_csWrite.Leave;
//  end;
//end;



function TCommPLCThread.ReadDevice( szDevice: String; var lplData: integer; bSaveLog : Boolean): integer;
var
  nReturnCode,localData: Integer;
begin
  Result := 1;
  nReturnCode := 0;
  localData := 0;
  try
    if UseSimulator then
    begin
      if frmPlcSimulate <> nil then
        Result := frmPlcSimulate.GetDevice(szDevice, lplData);
    end else
    begin
//      Synchronize(nil,
//        procedure
//        begin
//          m_ActUtl.GetDevice(szDevice, lplData, nReturnCode);
//        end
//      );
//      lplData := localData;
      m_csWrite.Enter;
      try
        nReturnCode:= m_ActUtl.GetDevice(szDevice, lplData);
      finally
        m_csWrite.Leave;
      end;
      Result := nReturnCode;
      if bSaveLog then begin // Polling 시에 Log 안남김
        AddLog(format('ReadDevice Addr=%s Data=%d: - Result=%d', [szDevice, lplData, Result]));
      end;

    end;
  except
    on E: Exception do begin
      AddLog(format('Exception On ReadDevice - %s', [E.Message]), True);
    end;
  end;
end;



function TCommPLCThread.ReadDeviceBit( szDevice: String; nBitLoc: Integer; var lplData: Integer): Integer;
var
  nData:  Integer;
begin
  Result:= 0;

//  if not Connected then Exit(1);
  try
    if szDevice[1] = 'B' then begin
      Result:= ReadDevice(szDevice, lplData);
    end
    else begin
      Result:= ReadDevice(szDevice, nData);
      //Result:= ReadDeviceBlock(szDevice, 1, nData);
      lplData:= Get_Bit(nData, nBitLoc);
    end;
  except
    ON E: Exception do begin
      AddLog(format('Exception On ReadDeviceBit - %s', [E.Message]), True);
    end;
  end;
end;


function TCommPLCThread.WriteDevice(szDevice: String; nData: Integer; bSaveLog : boolean): integer;
var
  nReturnCode,localData: Integer;
begin
  Result := 1;
  nReturnCode := 0;
//  m_csWrite.Enter;
  try
    try
      if UseSimulator then
      begin
        if frmPlcSimulate <> nil then
          Result := frmPlcSimulate.SetDevice(szDevice, nData);
      end else
      begin
  //      Synchronize(nil,
  //        procedure
  //        begin
//            m_ActUtl.SetDevice(szDevice, nData, nReturnCode);
  //        end
  //      );
  //      nData := localData;
        m_csWrite.Enter;
        try
          nReturnCode:= m_ActUtl.SetDevice(szDevice, nData);
        finally
          m_csWrite.Leave;
        end;
        Result := nReturnCode;
        if bSaveLog then begin
          AddLog(format('WriteDevice Addr=%s Data=%d - Result=%d', [szDevice, nData, Result]));
        end;

      end;
    except
      on E: Exception do begin
        AddLog(format('Exception On ReadDevice - %s', [E.Message]), True);
      end;
    end;
  finally
//    m_csWrite.Leave;
  end;
end;


function TCommPLCThread.WriteDeviceBit( szDevice: String; nBitLoc, nValue: Integer; bSaveLog : Boolean): Integer;
var
  nData:  Integer;
  //inx: Integer;
  //sAddr: String;
begin
  Result:= 0;

  if not Connected then Exit(1);
  try
    if szDevice[1] = 'B' then begin
      Result:= WriteDevice(szDevice, nValue);
    end
    else begin
      ReadDevice(szDevice, nData);
      //ReadDeviceBlock(szDevice, 1, nData);
      Set_Bit(nData, nBitLoc, nValue);
      Result:= WriteDevice(szDevice, nData);
      //Result:= WriteDeviceBlock(szDevice,1, nData);
    end;
    if bSaveLog then begin
      AddLog(format('WriteDeviceBit Addr=%s Data=%d - Result=%d', [szDevice, nValue, Result]));
    end;
  except
    ON E: Exception do begin
      AddLog(format('Exception On WriteDeviceBit - %s', [E.Message]), True);
    end;
  end;
end;



function TCommPLCThread.ReadDeviceBlock( szDevice: String; lSize: Integer;var lplData,nReturn: Integer; bSaveLog : Boolean): Integer;
var
localData,nReturnCode : Integer;
begin
  if not Connected then Exit(1);
  localData := 0;
  nReturnCode := 0;
  Result:= 1;
  try
    if UseSimulator then
    begin
      if frmPlcSimulate <> nil then
        Result:= frmPlcSimulate.ReadDeviceBlock(szDevice, lSize, lplData);
    end else
    begin
//          Result := m_ActUtl.ReadDeviceBlock(szDevice, lSize, lplData);
//      Result := m_ActUtl.ReadDeviceBlock(szDevice, lSize, lplData);
//      Synchronize(nil,
//        procedure
//        begin
//          m_ActUtl.ReadDeviceBlock(szDevice, lSize, lplData,nReturnCode);
//        end
//      );
      m_csWrite.Enter;
      try
        nReturnCode:= m_ActUtl.ReadDeviceBlock(szDevice, lSize, lplData);
      finally
        m_csWrite.Leave;
      end;
      Result := nReturnCode;
      if bSaveLog then begin   // Polling 시에 Log 안남김
        AddLog(format('ReadDeviceBlock %s: Size=%d - Result=%d', [szDevice, lSize, Result]));
      end;

    end;
  except
    ON E: Exception do begin
      AddLog(format('Exception On ReadDeviceBlock - %s', [E.Message]), True);
    end;
  end;
end;




//procedure TCommPLCThread.ReadDevicePro(szDevice: String; var lplData, nReturnCode: integer);
//var
//  localData: Integer;
//begin
////  Result := 1;
//  nReturnCode := 0;
//  localData := 0;
//  try
//    if UseSimulator then
//    begin
//      if frmPlcSimulate <> nil then
//         frmPlcSimulate.GetDevice(szDevice, lplData);
//    end else
//    begin
////      Synchronize(nil,
////        procedure
////        begin
//          m_ActUtl.GetDevice(szDevice, lplData, nReturnCode);
////        end
////      );
////      lplData := localData;
////      Result := nReturnCode;
//    end;
//  except
//    on E: Exception do begin
//      AddLog(format('Exception On ReadDevice - %s', [E.Message]), True);
//    end;
//  end;
//end;


function TCommPLCThread.WriteDeviceBlock( szDevice: String; lSize: Integer; var lplData: Integer): Integer;
var
nReturnCode,localData : integer;
begin

  if not Connected then Exit(1);
  nReturnCode := 0;
  localData := 0;
  Result:= 1;
  localData := lplData;
//  m_csWrite.Enter;
  try
    try
      if UseSimulator then
      begin
        if frmPlcSimulate <> nil then
            Result:= frmPlcSimulate.WriteDeviceBlock(szDevice, lSize, lplData);
      end else
      begin
//        Result := m_ActUtl.WriteDeviceBlock(szDevice, lSize, lplData);
//        Synchronize(nil,
//        procedure
//        begin
//          m_ActUtl.WriteDeviceBlock(szDevice, lSize, lplData,nReturnCode);
//        end
//        );
//      lplData := localData;
        m_csWrite.Enter;
        try
          nReturnCode:= m_ActUtl.WriteDeviceBlock(szDevice, lSize, lplData);
        finally
          m_csWrite.Leave;
        end;
        Result := nReturnCode;

//      nReturn := nReturnCode;
//        Result := m_ActUtl.WriteDeviceBlock(szDevice, lSize, lplData);
      end;
      AddLog(format('WriteDeviceBlock %s: Size=%d - Result=%d', [szDevice, lSize, Result]));
    except
      ON E: Exception do begin
        AddLog(format('Exception On WriteDeviceBlock - %s', [E.Message]), True);
      end;
    end;
  finally
//    m_csWrite.Leave;
  end;

end;






function TCommPLCThread.WriteGlassData( szDevice: String; var AGlassData: TECSGlassData): Integer;
var
  naGlassData: array [0..64]of Integer;
begin
  Result:= 0;
//  ConvertGlassDataToBlock(AGlassData, naGlassData[0]);
//  WriteDeviceBlock(szDevice, 64, naGlassData[0]); ///Glass Data
end;

procedure TCommPLCThread.WriteHeatBeat;
var
  nData: Integer;
  nBit: Integer;
begin
  nData:= PollingData[0];
  nBit:= Get_Bit(nData, 0);
  if nBit = 0 then nBit:= 1 else nBit:= 0;
  //Set_Bit(nData, 0, nBit);
  //WriteDeviceBlock(StartAddr_ROBOT, 1, nData);
  WriteDevice('B' + IntToHex(StartAddr_ROBOT+$10*$00+$0, 3), nBit);
end;

function TCommPLCThread.ReadBuffer(lStartIO, lAddress, lSize: Integer; var lpsData: Smallint): Integer;
var
  nReturnCode : Integer;
  localData : Smallint;
begin
  Result:= 1;
  if UseSimulator then
  begin
    if frmPlcSimulate <> nil then
      Result:= frmPlcSimulate.ReadBuffer(lStartIO, lAddress, lSize, lpsData);
  end else
  begin
//      Result := m_ActUtl.ReadBuffer(lStartIO, lAddress, lSize, lpsData);
//        Synchronize(nil,
//        procedure
//        begin
//          m_ActUtl.ReadBuffer(lStartIO, lAddress, lSize, localData,nReturnCode);
//        end
//        );
      lpsData := localData;
      Result := nReturnCode;
//    Result := m_ActUtl.ReadBuffer(lStartIO, lAddress, lSize, lpsData);
  end;
end;


function TCommPLCThread.WriteBuffer(lStartIO, lAddress, lSize: Integer; var lpsData: Smallint): Integer;
var
 localData : Smallint;
 nReturnCode : Integer;
begin
  Result:= 1;

  //m_csWrite.Enter;
  try
    if UseSimulator then
    begin
      if frmPlcSimulate <> nil then
          Result:= frmPlcSimulate.WriteBuffer(lStartIO, lAddress, lSize, lpsData);
    end else
    begin
//        Result := m_ActUtl.WriteBuffer(lStartIO, lAddress, lSize, lpsData);
//      Synchronize(nil,
//        procedure
//        begin
//          m_ActUtl.WriteBuffer(lStartIO, lAddress, lSize, localData,nReturnCode);
//        end
//        );
      lpsData := localData;
      Result := nReturnCode;
//      Result := m_ActUtl.WriteBuffer(lStartIO, lAddress, lSize, lpsData);
    end;
  finally
    //m_csWrite.Leave;
  end;
end;

function TCommPLCThread.ReadClockData(out lpsYear, lpsMonth, lpsDay, lpsDayOfWeek,
     lpsHour, lpsMinute, lpsSecond: Smallint): Integer;
begin

  if not Connected then Exit(1);

  Result:= 1;
  if UseSimulator then
  begin
    if frmPlcSimulate <> nil then
      Result:= frmPlcSimulate.GetClockData(lpsYear, lpsMonth, lpsDay, lpsDayOfWeek, lpsHour, lpsMinute, lpsSecond);
  end else
  begin
//    Result := m_ActUtl.GetClockData(lpsYear, lpsMonth, lpsDay, lpsDayOfWeek, lpsHour, lpsMinute, lpsSecond);
//    Result := m_ActUtl.GetClockData(lpsYear, lpsMonth, lpsDay, lpsDayOfWeek, lpsHour, lpsMinute, lpsSecond);
  end;
end;

function TCommPLCThread.ReadString( szDevice: String; nAddress, nLen: Integer): String;
var
  naData: array of Integer;
  nCount,nReturnCode: Integer;
begin
  if not Connected then Exit('');
  if nLen <= 0 then Exit('');

  nCount:= (nLen+1) div 2;
  SetLength(naData, nCount);
//  Synchronize(nil,
//  procedure
//  begin
  ReadDeviceBlock(szDevice, nCount, naData[0],nReturnCode);
//   end
//  );
//  ReadDeviceBlock(szDevice, nCount, naData[0],nReturnCode);
  Result:= ConvertStrFromPLC(nCount, naData);
end;


function TCommPLCThread.WriteString( szDevice: String; sValue: String): Integer;
var
  naData: array of Integer;
  nLen: Integer;
  nCount: Integer;
begin

  if not Connected then Exit(1);

  nLen:= Length(sValue);
  if nLen <= 0 then Exit(0);
  AddLog(format('WriteString %s: %s', [szDevice, sValue]));
  nCount:= (nLen+1) div 2;
  SetLength(naData, nCount+1);
  ConvertStrToPLC(sValue, nLen, naData);
//  Synchronize(nil,
//  procedure
//  begin
    Result :=  WriteDeviceBlock(szDevice, nCount, naData[0]);
//  WriteDeviceBlockPro('W' + IntToHex(StartAddr_EQP_W+$10*$1F+$0, 3), 16, naGlassCode[0] ); //Position Glass Code
//  WriteDeviceBlock('B' + IntToHex(StartAddr_EQP+$10*$0A+$0, 3), 16, naExists[0]); //Position Glass Exist
//  end
//  );
//  Result:= WriteDeviceBlock(szDevice, nCount, naData[0]);
end;

function TCommPLCThread.ReadTactTime(nChannel: Integer): Integer;
begin
  Result:= 0;
end;

procedure TCommPLCThread.ConvertBlockToGlassData(var naGlassData: array of Integer; var AGlassData: TECSGlassData);
var
  sMsg : string;
begin
  AGlassData.CarrierID:= ConvertStrFromPLC(8, naGlassData[0]); //Ascii 16
  AGlassData.ProcessingCode:= ConvertStrFromPLC(4, naGlassData[8]); //Ascii 8

  CopyMemory(@AGlassData.LOTSpecificData[0], @naGlassData[12], 4*sizeof(Integer));
  AGlassData.RecipeNumber:= naGlassData[16];
  AGlassData.GlassType:= naGlassData[17];
  AGlassData.GlassCode:= naGlassData[18];
  AGlassData.GlassID:= ConvertStrFromPLC(8, naGlassData[19]); //Ascii 16
  AGlassData.GlassJudge:= naGlassData[27] and $00FF;

  CopyMemory(@AGlassData.GlassSpecificData[0], @naGlassData[28], 4*sizeof(Integer));
//  CopyMemory(@AGlassData.GlassAddData[0], @naGlassData[32], 6*sizeof(Integer));
  CopyMemory(@AGlassData.PreviousUnitProcessing[0], @naGlassData[32], 8*sizeof(Integer));
  CopyMemory(@AGlassData.GlassProcessingStatus[0], @naGlassData[40], 8*sizeof(Integer));
  AGlassData.MateriID := ConvertStrFromPLC(30, naGlassData[48]);
//  AGlassData.LCM_ID:= ConvertStrFromPLC(12, naGlassData[48]); //Ascii 24
  AGlassData.PCZTCode:= naGlassData[63];
  sMsg := GetGlassDataString(AGlassData);
  AddLog(format('ConvertBlockToGlassData %s', [sMsg]));
  //AGlassData.PCZTID:= ConvertStrFromPLC(8, naGlassData[49]); //Ascii 16
end;

procedure TCommPLCThread.ConvertGlassDataToBlock(var AGlassData: TECSGlassData; var naGlassData: array of Integer);
begin
  ConvertStrToPLC(AGlassData.CarrierID, 16, naGlassData[0]); //Ascii 16 문자는 Word당 2글자
  ConvertStrToPLC(AGlassData.ProcessingCode, 8, naGlassData[8]); //Ascii 8

  CopyMemory(@naGlassData[12], @AGlassData.LOTSpecificData[0], 4*sizeof(Integer));
  naGlassData[16]:=AGlassData.RecipeNumber;
  naGlassData[17]:=AGlassData.GlassType;
  naGlassData[18]:=AGlassData.GlassCode;
  ConvertStrToPLC(AGlassData.GlassID, 16, naGlassData[19]); //Ascii 16
  naGlassData[27]:=AGlassData.GlassJudge;

  CopyMemory(@naGlassData[28], @AGlassData.GlassSpecificData[0], 4*sizeof(Integer));
//  CopyMemory(@naGlassData[32], @AGlassData.GlassAddData[0], 6*sizeof(Integer));
  CopyMemory(@naGlassData[32], @AGlassData.PreviousUnitProcessing[0], 8*sizeof(Integer));
  CopyMemory(@naGlassData[40], @AGlassData.GlassProcessingStatus[0], 8*sizeof(Integer));
//  CopyMemory(@naGlassData[45], @AGlassData.GlassRoutingData[0], 3*sizeof(Integer));

//  ConvertStrToPLC(AGlassData.LCM_ID, 24, naGlassData[48]); ////Ascii 16 문자는 Word당 2글자
  ConvertStrToPLC(AGlassData.MateriID, 30, naGlassData[48]); //Ascii 16
  naGlassData[63]:=AGlassData.PCZTCode;
  //ConvertStrToPLC(AGlassData.PCZTID, 16, naGlassData[49]); ////Ascii 16 문자는 Word당 2글자
end;

function TCommPLCThread.GetGlassDataString(var AGlassData: TECSGlassData): String;
var
  sData: String;
begin
  sData:= format('CarrierID=%s, MateriID=%s, ProcessingCode=%s, LOTSpecificData=%d %d %d %d, RecipeNumber=%d, GlassType=%d, GlassCode=%d, GlassID=%s, GlassJudge=%d',
                [AGlassData.CarrierID,AGlassData.MateriID, AGlassData.ProcessingCode,
                AGlassData.LOTSpecificData[0], AGlassData.LOTSpecificData[1], AGlassData.LOTSpecificData[2], AGlassData.LOTSpecificData[3],
                AGlassData.RecipeNumber, AGlassData.GlassType, AGlassData.GlassCode,
                 AGlassData.GlassID, AGlassData.GlassJudge]);
  Result:= sData;
  sData:= format(', GlassSpecificData=%d %d %d %d, PreviousUnitProcessing=%d %d %d %d %d %d %d %d, GlassProcessingStatus=%d %d %d %d %d %d %d %d',
                 [AGlassData.GlassSpecificData[0], AGlassData.GlassSpecificData[1], AGlassData.GlassSpecificData[2], AGlassData.GlassSpecificData[3],
                  AGlassData.PreviousUnitProcessing[0], AGlassData.PreviousUnitProcessing[1], AGlassData.PreviousUnitProcessing[2],AGlassData.PreviousUnitProcessing[3],
                  AGlassData.PreviousUnitProcessing[4],AGlassData.PreviousUnitProcessing[5],AGlassData.PreviousUnitProcessing[6],AGlassData.PreviousUnitProcessing[7],
                  AGlassData.GlassProcessingStatus[0], AGlassData.GlassProcessingStatus[1], AGlassData.GlassProcessingStatus[2], AGlassData.GlassProcessingStatus[3],
                  AGlassData.GlassProcessingStatus[4], AGlassData.GlassProcessingStatus[5], AGlassData.GlassProcessingStatus[6], AGlassData.GlassProcessingStatus[7]]);
  Result:= Result + sData;
  sData:= format(', PCZTCode=%d ',[AGlassData.PCZTCode]);
  Result:= Result + sData;
end;

function TCommPLCThread.ConvertStrFromPLC(nLen: Integer; var naData: array of Integer): String;
var
	i     : Integer;
  szStr  : array[0..1023] of AnsiChar;
  sRslt : String;
begin
  if nLen <= 0 then Exit('');

  FillChar(szStr, SizeOf(szStr), #0);

  for i := 0 to nLen - 1 do begin
		CopyMemory(@szStr[(i*2)], @naData[i], 2);
	end;
//  for i := 0 to ((nLen+1) div 2) - 1 do begin
//    szStr[i*2]:= AnsiChar(naData[i] and $FF);
//    szStr[i*2+1]:= AnsiChar((naData[i] shr 8) and $FF);
//	end;
  sRslt   := String(System.AnsiStrings.StrPas(szStr));

  Result  := sRslt;
end;

procedure TCommPLCThread.ConvertStrToPLC(sData: string; nLen: Integer; var naData: array of Integer);
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

function TCommPLCThread.IsBitOn(var nData: Integer; nLoc: Integer): Boolean;
begin
  Result := (nData shr nLoc) and $01 = $01;
end;

function TCommPLCThread.Get_Bit(var nData: Integer; nLoc: Integer): Integer;
begin
  Result := (nData shr nLoc) and $01;
end;


function TCommPLCThread.IsBitOn(nDivision, nIndex, nBitLoc: Integer): Boolean;
begin
  if nDivision = 0 then begin  //EQP
    Result:= IsBitOn(PollingEQP[nIndex], nBitLoc);
  end
  else if nDivision = 1 then begin //Robot
    Result:= IsBitOn(PollingData[nIndex], nBitLoc);
  end
  else if nDivision = 2 then begin //ECS
    Result:= IsBitOn(PollingECS[nIndex], nBitLoc);
  end
  else begin
    Result:= IsBitOn(PollingCV[nIndex], nBitLoc);
  end;
end;

function TCommPLCThread.IsBitOn_ECS(nIndex: Integer): Boolean;
var
 nDiv, nBitLoc: Integer;
begin
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;
  Result:= IsBitOn(PollingECS[nDiv], nBitLoc);
end;

function TCommPLCThread.IsBitOn_EQP(nIndex: Integer): Boolean;
var
 nDiv, nBitLoc: Integer;
begin
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;
  Result:= IsBitOn(PollingEQP[nDiv], nBitLoc) ;
end;

function TCommPLCThread.IsBitOn_Robot(nIndex: Integer): Boolean;
var
 nDiv, nBitLoc: Integer;
begin
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;
  Result:= IsBitOn(PollingData[nDiv], nBitLoc);
end;

function TCommPLCThread.IsBusy_Robot(nCH : integer): Boolean;
var
 nIndex, nDiv, nBitLoc: Integer;
begin
  Result:= False;

  //$02: begin  //Robot Unload Busy 0
  //$22: begin  //Robot Unload Busy 1
  //$12: begin //Robot Load Busy 0
  //$32: begin //Robot Load Busy 1

  nIndex:= $02;
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;

  //둘중에 하나라도 On이면 Busy
  if (Get_Bit(PollingData[nDiv + nCH * 2], nBitLoc) = 1) or (Get_Bit(PollingData[nDiv +nCH * 2 + 1], nBitLoc) = 1)then begin
    Result:= True;
  end;
end;



function TCommPLCThread.IsBusy_Robot_Each(nCH: Integer): Boolean;
var
 nIndex, nDiv, nBitLoc: Integer;
begin
  Result:= False;

  //$02: begin  //Robot Unload Busy 0
  //$22: begin  //Robot Unload Busy 1
  //$12: begin //Robot Load Busy 0
  //$32: begin //Robot Load Busy 1

  nIndex:= $02;
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;

  if (Get_Bit(PollingData[nDiv + nCH * 2], nBitLoc) = 1)then begin
    Result:= True;
  end;
end;
function TCommPLCThread.IsGlassData_Robot(nCH : integer): Boolean;
var
 nIndex, nDiv, nBitLoc: Integer;
begin
  Result:= False;

  //$C0: begin  //EQP Load Enable 0
  //$C1: begin  //EQP Glass Data Req 0
  //$C4: begin  //EQP Normal Status 0
  //$E0: begin  //EQP Load Enable 1
  //$E1: begin  //EQP Glass Data Req 1
  //$E4: begin  //EQP Normal Status 1

  nIndex:= $C1;
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;

  //둘중에 하나라도 On이면 Busy
  if (Get_Bit(PollingData[nDiv + nCH * 2], nBitLoc) = 1) or (Get_Bit(PollingData[nDiv +nCH * 2 + 1], nBitLoc) = 1)then begin
    Result:= True;
  end;
end;

function TCommPLCThread.IsRequest_Robot: Boolean;
var
 nIndex, nDiv, nBitLoc: Integer;
begin
  Result:= False;

  //$C0: begin  //EQP Load Enable 0
  //$C1: begin  //EQP Glass Data Req 0
  //$C4: begin  //EQP Normal Status 0
  //$E0: begin  //EQP Load Enable 1
  //$E1: begin  //EQP Glass Data Req 1
  //$E4: begin  //EQP Normal Status 1

  nIndex:= $C0;
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;

  //Glass Data Req나 Normal Status가 On이면 Request 상태
  if (Get_Bit(PollingEQP[nDiv], nBitLoc+1) = 1) or (Get_Bit(PollingEQP[nDiv], nBitLoc+4) = 1)
    or (Get_Bit(PollingEQP[nDiv + 2], nBitLoc+1) = 1) or (Get_Bit(PollingEQP[nDiv + 2], nBitLoc+4) = 1) then begin
    Result:= True;
  end;
end;

function TCommPLCThread.IsLoadRequest_Robot(nCH : integer): Boolean;
var
 nIndex, nDiv, nBitLoc: Integer;
begin
  Result:= False;

  //$C0: begin  //EQP Load Enable 0
  //$C1: begin  //EQP Glass Data Req 0
  //$C4: begin  //EQP Normal Status 0
  //$E0: begin  //EQP Load Enable 1
  //$E1: begin  //EQP Glass Data Req 1
  //$E4: begin  //EQP Normal Status 1
  if Common.PLCInfo.InlineGIB then
    nIndex:= $80
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then
      nIndex:= $C0
    else nIndex:= $120;
  end;
//  nIndex:= $C0;
  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;

  //Glass Data Request On이면 Load Request 상태
  if (Get_Bit(PollingEQP[nDiv + nCH *2], nBitLoc+1) = 1) {or (Get_Bit(PollingEQP[nDiv + 2], nBitLoc+1) = 1)} then begin
    Result:= True;
  end;
end;

function TCommPLCThread.IsUnloadRequest_Robot(nCH :Integer): Boolean;
var
 nIndex, nDiv, nBitLoc: Integer;
begin
  Result:= False;

  //$D0: begin  //EQP UnLoad Enable 0
  //$D1: begin  //EQP Glass Data Report 0
  //$D4: begin  //EQP Normal Status 0
  //$F0: begin  //EQP UnLoad Enable 1
  //$F1: begin  //EQP Glass Data Report 1
  //$F4: begin  //EQP Normal Status 1
  if Common.PLCInfo.InlineGIB then
    nIndex:= $90
  else begin
    if Common.SystemInfo.OCType = DefCommon.OCType then
      nIndex:= $D0
    else nIndex:= $130;
  end;

  nDiv:= nIndex div 16;
  nBitLoc:= nIndex mod 16;

  //Glass Data Report가 On이면 Unload Request 상태
  if (Get_Bit(PollingEQP[nDiv + nCH *2], nBitLoc+1) = 1) {or (Get_Bit(PollingEQP[nDiv + 2], nBitLoc+1) = 1)} then begin
    Result:= True;
  end;
end;

function TCommPLCThread.ITC_AllChNormalStatusOnOff(nOnOff: Integer): integer;
var
  nCh : integer;
begin
  AddLog('ITC_AllChNormalStatusOnOff : ' + InttoStr(nOnOff));
  for nch := DefCommon.CH1 to Defcommon.MAX_CH do begin
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$09+$4 + (nCh*$20), 3), nOnOff); //Unload Normal Status off
    WriteDevice('B' + IntToHex(StartAddr_EQP+$10*$08+$4 + (nCh*$20), 3), nOnOff); // Normal Status off
    sleep(100);
  end;
end;

procedure TCommPLCThread.LoadGlassData(sFileName: String);
var
  fs: TFileStream;
  naGlassData: array [0..64]of Integer;
  i: Integer;
begin
  if not FileExists(sFileName) then exit;

  fs:= TFileStream.Create(sFileName, fmOpenRead);
  try
    for i := 0 to 3 do begin
      fs.Read(naGlassData, Sizeof(naGlassData));
      ConvertBlockToGlassData(naGlassData[0], GlassData[i]);
      //GlassData[i].GlassJudge:= 83; //0x53 'S' - 읽어 들인 것은 임시로 skip 설정
    end;
  finally
    FreeAndNil(fs);
  end;

end;


procedure TCommPLCThread.SaveGlassData(sFileName: String);
var
  fs: TFileStream;
  naGlassData: array [0..64]of Integer;
  i: Integer;
begin
  fs:= TFileStream.Create(sFileName, fmCreate);
  try
    for i := 0 to 3 do begin
      ConvertGlassDataToBlock(GlassData[i], naGlassData[0]);
      fs.Write(naGlassData[0], Sizeof(naGlassData));
    end;
  finally
    FreeAndNil(fs);
  end;
end;


procedure TCommPLCThread.SetEQPID(nEQP_ID : Integer);
begin
  EQP_ID:= nEQP_ID;

  if UseSimulator then
  begin
    if frmPlcSimulate <> nil then begin
      frmPlcSimulate.EQP_ID:= EQP_ID;
    end;
  end
end;

function TCommPLCThread.SetGlassData_ContactNG(var GlassData: TECSGlassData; nValue: Integer): Integer;
begin
  //HN-M-ECS-AN03-장비운영사양서(조립 Inline)_v0.2.pdf
  //2.1.4. Glass Specific Data
  Result:= 0;
  //Connect 연결 이상으로 인한 Panel 정보 미 확인 시, 상류에서 받은 Data에 해당 EQP의 NG Flag를 “ON” 후 배출한다.
  //Contact NG
  Set_Bit(GlassData.GlassSpecificData[0], 2, nValue);
end;

function TCommPLCThread.SetGlassData_CheckRLogistics(var GlassData: TECSGlassData; nValue: Integer): Integer;
begin
//2.2.8 특이 운영
//- 역 물류 존재 (MP0로 부터의 역 물류 - Bit Panel Add Data(2) 2Bit 참고)
//   - > 해당 Panel 작업 이후 배출 시 해당 Bit Off 하여 배출 한다.

  Result:= 0;
  Set_Bit(GlassData.GlassSpecificData[2], 2, nValue);
end;



function TCommPLCThread.SetGlassData_JudgCode(var GlassData: TECSGlassData; nValue: Integer): Integer;
begin
  //HN-M-ECS-AN03-장비운영사양서(조립 Inline)_v0.2.pdf
  //2.1.3. Glass JUDGE
  Result:= 0;
  GlassData.GlassJudge:= nValue;
end;

function TCommPLCThread.SetGlassData_Previous_Unit_Processing(var GlassData: TECSGlassData; nValue: Integer): Integer;
begin
  Result:= 0;
  if Common.SystemInfo.Use_GIB then begin //GIB구분- Auto이고 GIB 모드이면 Inline GIB
      GlassData.PreviousUnitProcessing[0]:= nValue;
      end
  else begin
      GlassData.PreviousUnitProcessing[1]:= nValue;
  end;
//  Set_Bit(GlassData.PreviousUnitProcessing[1], 2, 1);
end;

function TCommPLCThread.SetGlassData_Previous_Unit_Processing_GIB(var GlassData: TECSGlassData; nCH,nABBCount: Integer): Integer;
begin
  Result:= 0;

  case nCH of
    DefCommon.CH1 :
    begin
      Set_Bit(GlassData.PreviousUnitProcessing[0], 0 + 6 *nABBCount,1);
    end;
    DefCommon.CH2 :
    begin
      Set_Bit(GlassData.PreviousUnitProcessing[0], 1 + 6 *nABBCount,1);
    end;
    DefCommon.CH3 :
    begin
      Set_Bit(GlassData.PreviousUnitProcessing[0], 2 + 6 *nABBCount,1);
    end;
    DefCommon.CH4 :
    begin
      Set_Bit(GlassData.PreviousUnitProcessing[0], 3 + 6 *nABBCount,1);
    end;
  end;

//  Set_Bit(GlassData.PreviousUnitProcessing[1], 2, 1);
end;

function TCommPLCThread.SetGlassData_Processing_Status(var GlassData: TECSGlassData; nSeq, nBitCount: Integer): Integer;
var
  nStation: Integer;
begin
  //HN-M-ECS-AN03-장비운영사양서(조립 Inline)_v0.2.pdf
  //2.1.7. Glass Processing Status
  Result:= 0;

  if Common.SystemInfo.Use_GIB then begin //GIB구분- Auto이고 GIB 모드이면 Inline GIB
    nStation:= EQP_ID-6;
  end
  else begin
    nStation:= EQP_ID-10;
  end;

  if nBitCount = 4 then begin
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 5, Get_Bit(nStation, 0));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 6, Get_Bit(nStation, 1));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 7, Get_Bit(nStation, 2));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 8, Get_Bit(nStation, 3));
  end
  else if nBitCount = 6 then begin
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 0, Get_Bit(nStation, 0));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 1, Get_Bit(nStation, 1));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 2, Get_Bit(nStation, 2));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 3, Get_Bit(nStation, 3));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 4, Get_Bit(nStation, 4));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 5, Get_Bit(nStation, 5));
  end

  else if nBitCount = 3 then begin
    //Inline GIB AAB
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 3, Get_Bit(nStation, 0));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 4, Get_Bit(nStation, 1));
    Set_Bit(GlassData.GlassProcessingStatus[nSeq], 5, Get_Bit(nStation, 2));
  end;
end;

function TCommPLCThread.SetGlassData_Processing_Status_GIB(var GlassData: TECSGlassData; nCH,nABBCount: Integer): Integer;
var
  nStation: Integer;
begin
  //HN-M-ECS-AN03-장비운영사양서(조립 Inline)_v0.2.pdf
  //2.1.7. Glass Processing Status
  Result:= 0;
  case nCH of
    DefCommon.CH1 :
    begin
      Set_Bit(GlassData.GlassProcessingStatus[0], 0 + 6 *nABBCount,1);
    end;
    DefCommon.CH2 :
    begin
      Set_Bit(GlassData.GlassProcessingStatus[0], 1 + 6 *nABBCount,1);
    end;
    DefCommon.CH3 :
    begin
      Set_Bit(GlassData.GlassProcessingStatus[0], 2 + 6 *nABBCount,1);
    end;
    DefCommon.CH4 :
    begin
      Set_Bit(GlassData.GlassProcessingStatus[0], 3 + 6 *nABBCount,1);
    end;

  end;
end;

function TCommPLCThread.GetGlassData_Processing_Status(var GlassData: TECSGlassData; var nSeq: Integer; nBitCount: Integer): Integer;
var
  nStation, nValue: Integer;
  i: Integer;
begin
  Result:= 0;
  nStation:= 0;
  for i:= 0 to 7 do begin
    if nBitCount = 4 then begin
      //5,6,7,8 bit Stattion 번호
      nValue:= GlassData.GlassProcessingStatus[i];
      nValue:= nValue shr 5;
      nValue:= nValue and $0F;
      if nValue = 0 then begin
        nSeq:= i;
        Exit;
      end;
      nStation:= nValue;
    end
    else if nBitCount = 16 then begin
      nValue:= GlassData.GlassProcessingStatus[0];

      if nValue and $F000 = 0 then nSeq := 2;
      if nValue and $3C0 = 0 then nSeq := 1;
      if nValue and $F = 0 then nSeq := 0;
      Result:= nValue;
      Exit;

    end
    else if nBitCount = 6 then begin
      //0,1,2,3,4,5 bit Stattion 번호
      nValue:= GlassData.GlassProcessingStatus[1];
//      nValue:= nValue shr 5;
      nValue:= nValue and $3F;
      if nValue = 0 then begin
        nSeq:= i;
        Exit;
      end;
      nStation:= nValue;
    end
    else if nBitCount = 3 then begin
      //3,4,5 bit Stattion 번호
      nValue:= GlassData.GlassProcessingStatus[i];
      nValue:= nValue shr 3;
      nValue:= nValue and $07;
      if nValue = 0 then begin
        nSeq:= i;
        Exit;
      end;
      nStation:= nValue;
    end;
  end;
  nSeq:= 3;
  Result:= nStation;
end;

procedure TCommPLCThread.SetStartAddress(nStartAddr_EQP, nStartAddr_ECS, nStartAddr_ROBOT, nStartAddr_ROBOT2,
    nStartAddr_EQP_W, nStartAddr_ECS_W, nStartAddr_ROBOT_W, nStartAddr_ROBOT_W2, nStartAddr_ROBOT_DOOR : int64);
begin
  StartAddr_EQP:= nStartAddr_EQP;
  StartAddr_ECS:= nStartAddr_ECS;
  StartAddr_ROBOT:= nStartAddr_ROBOT;
  StartAddr_EQP_W:= nStartAddr_EQP_W;
  StartAddr_ECS_W:= nStartAddr_ECS_W;
  StartAddr_ROBOT_W:= nStartAddr_ROBOT_W;
  StartAddr2_ROBOT := nStartAddr_ROBOT2;
  StartAddr2_ROBOT_W := nStartAddr_ROBOT_W2;
  StartAddr_ROBOT_DOOR_BIT := nStartAddr_ROBOT_DOOR;
  AddLog(format('SetStartAddress EQP: %x, ECS: %x, ROBTO: %x,  ROBTO2: %x', [StartAddr_EQP, StartAddr_ECS, StartAddr_ROBOT,StartAddr2_ROBOT]));
  AddLog(format('SetStartAddress EQP_W: %x, ECS_W: %x, ROBTO_W: %x, ROBTO2_W: %x', [StartAddr_EQP_W, StartAddr_ECS_W, StartAddr_ROBOT_W,StartAddr2_ROBOT_W]));

  if UseSimulator then
  begin
    if frmPlcSimulate <> nil then begin
      frmPlcSimulate.StartAddr_EQP:= StartAddr_EQP;
      frmPlcSimulate.StartAddr_ROBOT:= StartAddr_ROBOT;
      frmPlcSimulate.StartAddr_ECS:= StartAddr_ECS;

      frmPlcSimulate.StartAddr_EQP_W:= StartAddr_EQP_W;
      frmPlcSimulate.StartAddr_ROBOT_W:= StartAddr_ROBOT_W;
      frmPlcSimulate.StartAddr_ECS_W:= StartAddr_ECS_W;
    end;
  end
end;

function TCommPLCThread.Set_Bit(var nData: Integer; nLoc, Value: Integer): Integer;
begin
  if Value = 0 then
  begin
    nData := (nData and not (1 shl nLoc));
  end else
  begin
    nData := nData or (1 shl nLoc);
  end;
  Result:= nData;
end;

procedure TCommPLCThread.Set_LogPath(sValue: String);
begin
  if m_sLogPath <> sValue then begin
    m_sLogPath:= sValue;
    ForceDirectories(m_sLogPath);
  end;
end;

{ TThreadSafeQue<T> }

constructor TThreadSafeQue<T>.Create;
begin
  m_Queue := TQueue<T>.Create;
  //m_Lock:= TObject.Create;
end;

destructor TThreadSafeQue<T>.Destroy;
begin
  Lock;
  try
    m_Queue.Free;
    inherited Destroy;
  finally
    Unlock;
    //m_Lock.Free;
  end;
  inherited;
end;

function TThreadSafeQue<T>.Dequeue: T;
begin
  try
    with Lock do begin
      Result:= Dequeue;
    end;
  finally
    Unlock;
  end;
end;

function TThreadSafeQue<T>.Dequeue(out aItem: T): boolean;
begin
  try
    with Lock do begin
      Result:= Count > 0;
      if Result then
        aItem:= Dequeue;
    end;
  finally
    Unlock;
  end;
end;


procedure TThreadSafeQue<T>.Enqueue(const aItem: T);
begin
  try
    with Lock do begin
      Enqueue(aItem);
    end;
  finally
    Unlock;
  end;
end;

function TThreadSafeQue<T>.ItemCount: Integer;
begin
  try
    with Lock do begin
      Result:= Count;
    end;
  finally
    Unlock;
  end;
end;

function TThreadSafeQue<T>.IsEmpty: boolean;
begin
  try
    with Lock do begin
      Result:= Count = 0;
    end;
  finally
    Unlock;
  end;
end;

function TThreadSafeQue<T>.Lock: TQueue<T>;
begin
  system.TMonitor.Enter(self);
  Result:= m_Queue;
end;

procedure TThreadSafeQue<T>.Unlock;
begin
  system.TMonitor.Exit(self);
end;

end.
