unit pasScriptClass;

interface
{$I Common.inc}
uses
  Winapi.Windows, Winapi.Messages,  System.SysUtils, System.DateUtils,  System.Classes, System.Variants, Vcl.Dialogs,
   Vcl.ScripterInit, atpascal, atScript, ScrMemo, ScrMps, atScriptDebug,InternalScriptClass, ap_Classes ,
  System.Generics.Collections, ControlDio_OC, CommPLC_ECS,UserUtils,CommThermometerMulti,
  DefCommon, {UdpServerClient,}CommPG, DefScript, uSystemLibrary, IdGlobal, Vcl.Forms,
  CommonClass, DefPG, GMesCom, DefGmes, {LogicVh,} DefDio, System.Math,System.SyncObjs
  , CommCameraRadiant,dllClass,AF9_FPGA,RegularExpressions , CommDIO_DAE, CommIonizer,LogicVh
{$IFDEF CA410_USE}
    , CA_SDK2
{$ENDIF}


{$IFDEF USE_DFS}
  ,DfsFtp
{$ENDIF}
  ; {CodeSiteLogging,}
type

  TSeqStatus = (ssNone, ssSeq1, ssSeq2, ssSeq3, ssSeq4, ssSeq5, ssSeq6, ssSeq7, ssSeq8, ssSeq9, ssSeq10,
                        ssSeq11, ssSeq12, ssSeq13, ssSeq14, ssSeq15, ssSeq16, ssSeq17, ssSeq18, ssSeq19,
                        ssScan, ssStop, ssPreStop, ssSeqReport);


  TSeqProcess = ( spNormal, spStop, spRepeat);
  TInsStatus = (isReady = 0, isRun, isStop);

  PGuiScript = ^RGuiScript;
  RGuiScript = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    nParam  : Integer;
    nParam2 : Integer;
    Msg     : string;
    Msg2    : string;
  end;

  PDataView  = ^RDataView;
  RDataView = packed record
    MsgType     : Integer;
    Channel     : Integer;
    Option      : Integer;
    Len         : Integer;
    Start       : Boolean;
    CellMerage  : boolean;
    Result      : Boolean;
    DataType    : Integer;
    MinVal      : Integer;
    MaxVal      : Integer;
//    GridData    : array[0..DefPG.MAX_FRAME_SIZE] of Integer;
//    IsNg        : array[0..DefPG.MAX_FRAME_SIZE] of Boolean;
    Msg         : string;
  end;
(*
  TTestRetInfo = record
    PowerOn       : Boolean;
    IsScanned     : Boolean;
    IsReport      : Boolean;
    IsLoaded      : Boolean;
    CanSendApdr   : Boolean;
    CarrierId     : string;
    SerialNo      : string;
    nSerialType   : Integer;
    Before_OtpCnt : Integer;
    After_OtpCnt  : Integer;
    Fail_Message  : string;
    Full_name     : string;
    KeyIn         : string;
    ERR_Message   : string;
    Result        : string;
    PlcRet        : Integer;
    csvHeader     : string;
    csvSubHead1   : string;
    csvSubHead2   : string;
    csvData       : string;
    csvFileName   : string;
    uniformity    : Double;
    StartTime     : TDateTime;
    EndTime       : TDateTime;
    StUnitTact    : TDateTime;
    EdUnitTact    : TDateTime;
    OcSTime, OcETime : TDateTime;

    CsvHeaderCnt  : Integer;
    InsCsv        : TInsCsv;
    InsApdr       : TInsApdr;
    ApdrData      : string;
    ApdrLogHeader : string;
  end;
 *)
  TTestInformation = class
    PG_Ver: string;
    SW_Ver: string;
    DLL_Ver : string;
    OC_Con_ver : string;
    EQPId: string;
    Model: string;
    ModelConfig: String;
    Ch: Integer;
    UserID: String;
    PowerOn       : Boolean;
    IsScanned     : Boolean;
    IsReport      : Boolean;
    IsLoaded      : Boolean;
    CanSendApdr   : Boolean;
    AutoMode      : Boolean;
    AABMode       : Boolean;
    Login         : Boolean;
    OCDllCall     : Boolean;  // Added by sam81 2023-04-29 오전 11:45:48  OC Dll 호출 했는지 여부
    Use_MES       : Boolean;
    Use_ECS       : Boolean;
    Use_DFS       : Boolean;
    Use_GIB       : Boolean;
    Use_FFCData   : Boolean;
    Use_StainData : Boolean;
    Use_FTPUpload : Boolean;
    Use_TemplateData  : Boolean;
    PreOcReStart  : Boolean; // Added by KTS 2023-06-09 오후 4:18:16 PreOc NG  발생 시 재 시작 여부
    ZAxis_Target  : Integer;
    ZAxis_Current : Integer;
    CarrierId     : string;
    SerialNo      : string;
    MateriID      : string;
    PID           : string;
    RTN_PID       : string;
    RTN_MODEL     : string;
    LCM_ID        : string;
    GlassID       : string;
    Process_Code  : string; //LPIR Process_Code 추가
    RetryValue    : Integer;
    nSerialType   : Integer;
    Before_OtpCnt : Integer;
    After_OtpCnt  : Integer;
    Fail_Message  : string;
    Full_name     : string;
    KeyIn         : string;
    ERR_Code      : string;
    ERR_Message   : string;
    MES_Code      : String;
    NgCode        : Integer;
    NG_EICR       : Boolean;
    NGAlarmCount  : Integer;
    RetryCount  : Integer;
    AlarmNGCode   : Integer;
    Result        : string;
    OKCount      : Integer; //OK 개수
    NGCount      : Integer; //NG 개수
    PlcRet        : Integer;
    csvHeader     : string;
    csvSubHead1   : string;
    csvSubHead2   : string;
    csvData       : string;
    csvFileName   : string;
    uniformity    : Double;
    StartTime     : TDateTime;
    EndTime       : TDateTime;
    PreEndTime    : TDateTime;
    StUnitTact    : TDateTime;
    EdUnitTact    : TDateTime;
    TurnTime_CAM  : TDateTime;
    TurnTime_Unload: TDateTime;
    OcSTime, OcETime : TDateTime;
    Log_WritePOCB : Boolean;
    Test_Repeat   : Boolean; //테스트용 자동 회전
    CsvHeaderCnt  : Integer;
    InsCsv        : TInsCsv;
    InsApdr       : TInsApdr;
    ApdrData      : string;
    ApdrLogHeader : string;
    FFCData       : array [0..50] of Double;
    INFOData      : array [0..150] of Double; //INFO Data
    CCD_TEMP      : Double;
    SIM_Use_PG    : Boolean;
    SIM_Use_DIO    : Boolean;
    SIM_Use_PLC   : Boolean;
    SIM_Use_CAM   : Boolean;
    Final_x      : Double;
    Final_y      : Double;
    Final_Lv      : Double;
    nPwrVCC : Integer;
    nPwrVIN : Integer;
    function Get_MeasureTime: Integer;
    property MeasureTime: Integer read Get_MeasureTime;
  end;

  RRgbAvrInfo    = record
    AvrType       : Integer;
    AvrCnt        : Integer;
    Option1       : Integer;
    BandCnt,GrayStep : Integer;
    RgbPass       : TInsRgbPass;
  end;

//  RDataTransform = record
//    IsRefStart  : boolean;
//    TempData    : array[0..MAX_FRAME_SIZE] of Integer; // 임시로 데이터 저장 하기 위한 현재 Frame 버퍼.
//    PreTempData : array[0..MAX_FRAME_SIZE] of Integer; // 임시로 데이터 저장 하기 위한 이전 Frame 버퍼.
//
//    Min, Max, P2P2, Diff, Average : array[0..MAX_FRAME_SIZE] of Integer;
//    AvrJiter, Jitter_Delta        : array[0..MAX_FRAME_SIZE] of Integer;
//    SlopRow, SlopCol              : array[0..MAX_FRAME_SIZE] of Integer;
//    RawCsOpen1, RawCsOpen2, SumData   : array[0..MAX_FRAME_SIZE] of Integer;
//  end;

  RGridDisplay = record
    Data  : Integer;
    IsNg  : Boolean;
  end;

  RSeqStatus     = record
    Status  : TSeqStatus;
    Process : TSeqProcess;
  end;

  TLimitStr = record
    LimitType   : Integer;
    FramePos    : Integer;
    DataPos     : Integer; // -1 이면 All.
    bRange      : Boolean;
    StPos       : Integer;
    EdPos       : Integer;
    Limit       : string[50];
  end;
  TTouchInfo = record
    SeqNum      : Integer;
    ProtocolIdx : Integer;
    Freq        : Integer;
    Frame       : Integer;
    DataType    : Integer;
    RetyCnt     : Integer;
    RefIdx      : Integer;
    DefectCode  : string[10];
    TestName    : string[100];
    LimitCnt    : Integer;
    LimitInfo   : array of TLimitStr;
  end;

  TCameraOtpData = record
    TotalSize : Integer;
    FiledUpSize : Integer;
    Data      : TIdBytes;
  end;
//  TRectWrapper = class(TatRecordWrapper)
//  published
////    v: Variant;
//  end;
  PTestRecord = ^TTestRecord;
  TTestRecord = record
    a : Integer;
    b : string;
    c : array of Integer;
  end;

  TRgbAvr = record
    AvrCnt            : Integer;
    AvrR, AvrG, AvrB  : Integer;
    R, G, B           : TList<Integer>;
  end;

  TNgRatio = record
    Ok, Ng : Integer;
  end;

  TScrCls = class(TObject)
  private
    FPgNo : Integer;
    m_MainHandle : HWND ;
    m_TestHandle : HWND ;
    m_bToMaint   : boolean;
    m_TouchInfo  : TTouchInfo;
    m_hCa310Evnt : HWND;
    m_hBCREvnt    : HWND;
    m_hDioEvnt    : HWND;
    m_bIsCaEvent : Boolean;
    m_bIsBCREvent : Boolean;

    m_bIsDioEvent : Boolean;

    m_hConfirmHostEvent: HWND; // 2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
    m_bIsWaitConfirmHostEvent: Boolean;

{$IFDEF CA310_USE}
    m_Ca310Data: TBrightValue;
{$ENDIF}
{$IFDEF CA410_USE}
    m_Ca410Data: TBrightValue;
{$ENDIF}

    m_bIsSyncEvent : Boolean;
//    m_bIsSyncSeq   : Boolean;
    m_hSyncEvnet   : HWND;


    atPasScrpt: TatPascalScripter;
    atScrDebug: TatScriptDebugger;
    atPasScrptMaint : TatPascalScripter;
    atScrDebugMaint : TatScriptDebugger;
    SeqStatus : array[DefScript.SEQ_STOP .. DefScript.SEQ_MAX] of RSeqStatus;
    FhDisplay: HWND;
    m_nCurPat : Integer;
    FGetPatGrp: TPatterGroup;
    FDataView   : RDataView;
//    FRxData : TRxData;
    m_bLockThread : Boolean;
    m_bTheadIsTerminated : Boolean;
    m_bCallTerminate  : Boolean;
    m_sEmNo           : string;
    m_nHostResult     : Integer;

    m_dtInitialData : TDateTime;
    m_OcParam         :  TOcParamsWR;
    m_hCamEvnt     : HWND;
    m_nCamRet      : Integer;
    m_bCamEvnt     : Boolean;
    m_CamOptData   : TCameraOtpData;
//    m_LoadOcParam    : array of TInternalScript;
//    m_LoadOcVerify   : array of TInternalScript;
    m_MESItemValue: TMESItemValue;

    procedure PgToComm_Proc(AMachine:TatVirtualMachine);
    procedure PgReset_Proc(AMachine:TatVirtualMachine);
    procedure PowerMeasure_Proc(AMachine:TatVirtualMachine);
    procedure GetConfigVer_Proc(AMachine: TatVirtualMachine);
    procedure GpioPanel_IRQ_Proc(AMachine: TatVirtualMachine);
    procedure GPIOSet_Proc(AMachine:TatVirtualMachine);   // Added by KTS 2022-12-14 오전 9:38:56 기능 확인
    procedure ConfirmHost_Proc(AMachine: TatVirtualMachine); // Added by KTS 2023-06-09 오후 2:01:26 NG 시 EICR 보고 여부
    procedure TactTime_Proc(AMachine:TatVirtualMachine);
    procedure Sleep_Proc(AMachine:TatVirtualMachine);
    procedure NextStep_Proc(AMachine:TatVirtualMachine);
    procedure CheckRetry_Proc(AMachine:TatVirtualMachine);
    procedure ReadPairNgCode_Proc(AMachine:TatVirtualMachine);

    //OC DLL FLOW
    procedure OCFlowStart_Proc(AMachine:TatVirtualMachine);
    procedure OCFlowStop_Proc(AMachine:TatVirtualMachine);
    procedure OCVerifyStart_Proc(AMachine:TatVirtualMachine);
    procedure OCThreadStateCheck_Proc(AMachine:TatVirtualMachine);
    procedure OCThreadFlash_READ_Proc(AMachine: TatVirtualMachine);
    procedure OCThreadFlash_Write_Proc(AMachine: TatVirtualMachine);
    procedure SetAgingTm_Proc(AMachine: TatVirtualMachine);
    //OC CA410
    procedure ReadCA410_Proc(AMachine: TatVirtualMachine);

    procedure LogM_Proc(AMachine:TatVirtualMachine);
    procedure SetCaptionName_Proc(AMachine: TatVirtualMachine);
    procedure LogRePGM_NG_Proc(AMachine:TatVirtualMachine);
    procedure LogPwr_Proc(AMachine:TatVirtualMachine);
    procedure LogPcd_Proc(AMachine:TatVirtualMachine);
    procedure ShowResult_Proc(AMachine:TatVirtualMachine);
    procedure ShowCurStaus_Proc(AMachine:TatVirtualMachine);
    procedure ShowSerial_Proc(AMachine: TatVirtualMachine);

    procedure GetSummaryLogData_Froc(AMachine: TatVirtualMachine);

    procedure RemakeSerialLog_Proc(AMachine:TatVirtualMachine);
    procedure MakeCsv_Proc(AMachine:TatVirtualMachine);
    procedure MakeCsvSummary_Proc(AMachine:TatVirtualMachine);
    procedure MakeCsvApdr_Proc(AMachine:TatVirtualMachine);
    procedure MakeOpticCsv_Proc(AMachine:TatVirtualMachine);
    procedure MakePassRGB_Proc(AMachine:TatVirtualMachine);
    procedure SetCurJigChForPass_Proc(AMachine:TatVirtualMachine);
    procedure Set_Cam_Cmd_Proc(AMachine:TatVirtualMachine);
    procedure SendLightCommand_Proc(AMachine: TatVirtualMachine);
    procedure LoadPassRgbAvr_Proc(AMachine:TatVirtualMachine);
    procedure LoadFileData_Proc(AMachine:TatVirtualMachine);
    procedure SendPocbHexFile_Proc(AMachine:TatVirtualMachine);
    procedure SendPocbHexFile2_Proc(AMachine:TatVirtualMachine);
    procedure SendPocbDataWrite_Proc(AMachine:TatVirtualMachine);
    procedure SendEraseCodeType_Proc(AMachine:TatVirtualMachine);

    procedure SetInit_Proc(AMachine:TatVirtualMachine);
    procedure SendTouchInfo_Proc(AMachine:TatVirtualMachine);
    procedure SendTouchResult_Proc(AMachine:TatVirtualMachine);
    procedure ReadDio_Proc(AMachine:TatVirtualMachine);
    procedure WriteDio_Proc(AMachine:TatVirtualMachine);
    procedure SetDio64_Proc(AMachine:TatVirtualMachine);   //GIB-OPTIC:DIO
    procedure GetDio64_Proc(AMachine:TatVirtualMachine);   //GIB-OPTIC:DIO
    procedure SetHandBcr_Proc(AMachine:TatVirtualMachine); //GIB-OPTIC:HANDBCR 2018-08-05
    procedure ControlDio_Proc(AMachine:TatVirtualMachine);
    procedure SetConfirmRty_Proc(AMachine:TatVirtualMachine);
    procedure GetPlcInfo_Proc(AMachine:TatVirtualMachine);
    procedure IonizerOn_Proc(AMachine:TatVirtualMachine);

    procedure ReadBcr_Proc(AMachine:TatVirtualMachine);
    procedure SendPCHK_Proc(AMachine:TatVirtualMachine);
    procedure SendLPIR_Proc(AMachine:TatVirtualMachine);
    procedure SendINSPCHK_Proc(AMachine:TatVirtualMachine);
    procedure SendEICR_Proc(AMachine:TatVirtualMachine);
    procedure SendEIJR_Proc(AMachine:TatVirtualMachine);
    procedure SendApdr_Proc(AMachine:TatVirtualMachine);
    procedure SendApdr_EAS_Proc(AMachine:TatVirtualMachine);
    procedure SendSGEN_Proc(AMachine:TatVirtualMachine);
    procedure GetBcrData_Proc(AMachine:TatVirtualMachine);
    procedure StrReplace_Proc(AMachine:TatVirtualMachine);
    procedure GetInfo_Proc(AMachine:TatVirtualMachine);
    procedure GetPatName_Proc(AMachine:TatVirtualMachine);
    procedure GetCameraFFCData_Proc(AMachine:TatVirtualMachine);
    procedure GetCameraINFOData_Proc(AMachine:TatVirtualMachine);
    procedure GetCameraINFOName_Proc(AMachine:TatVirtualMachine);
    procedure ChangeBuff_Proc(AMachine:TatVirtualMachine);
    procedure I2CWrite_Proc(AMachine:TatVirtualMachine);
    procedure ProgrammingWrite_Proc(AMachine:TatVirtualMachine);
    procedure I2CRead_Proc(AMachine:TatVirtualMachine);
    procedure MIPIWrite_Proc(AMachine:TatVirtualMachine);
    procedure MIPIWriteHS_Proc(AMachine: TatVirtualMachine);
    procedure MIPI_ICWrite_Proc(AMachine:TatVirtualMachine);
    procedure MIPI_ClkBps_Proc(AMachine:TatVirtualMachine);

    procedure NVMWrite_Froc(AMachine:TatVirtualMachine);
    procedure NVMRead_Froc(AMachine:TatVirtualMachine);
    procedure NVMVerify_Froc(AMachine: TatVirtualMachine);
//    procedure SetCamOtpData_Proc(AMachine:TatVirtualMachine);
    procedure MIPIRead_Proc(AMachine:TatVirtualMachine);
    procedure ReadCA310_Proc(AMachine:TatVirtualMachine);
    procedure GetOcParam_Proc(AMachine:TatVirtualMachine);
    procedure GetOcVerify_Proc(AMachine:TatVirtualMachine);
    procedure OtpWrite_Proc( AMachine:TatVirtualMachine);
    procedure OtpRead_Proc( AMachine:TatVirtualMachine);
    procedure GetOffSetTable_Proc( AMachine:TatVirtualMachine);
    procedure GetGammaOffSetTable_Proc( AMachine:TatVirtualMachine);
    procedure RecordTest_Proc(AMachine:TatVirtualMachine);
    procedure SetCa310MemoryCh_Proc(AMachine:TatVirtualMachine);

    procedure CELYufeng_Proc(AMachine:TatVirtualMachine);
    procedure GrayScale_Proc(AMachine: TatVirtualMachine);
    procedure DBVtracking_Proc(AMachine: TatVirtualMachine);
//    procedure EraseFlash_RM_D_Proc(AMachine: TatVirtualMachine);
//    procedure ReadFlash_GammaData_Proc(AMachine:TatVirtualMachine);
//    procedure ReadFlash_OTP_Data_Proc(AMachine: TatVirtualMachine);
//    procedure ReadFlash_Text_Proc(AMachine:TatVirtualMachine);

//    function SendPocbHexFile_D84X(nPacketSize, nFirstAddr, nNormalAddr: Integer; var sHexCS: String): Integer;
//    procedure WriteFlash_Mipi2SRAM_Proc(AMachine: TatVirtualMachine);
    procedure ReadFlash_PUC_HexFile_RM_D(var naPUC_Data  : TIdBytes);
    // Added by Clint 2020-12-30 오전 3:10:27

//    procedure ChangeVoltSet_Proc(AMachine: TatVirtualMachine);
//    procedure EnableVoltSet_Proc(AMachine: TatVirtualMachine);  // Added by KTS 2022-12-14 오전 9:38:15 기능 확인

    procedure SendMainGuiDisplay(nGuiMode : Integer; nP1: Integer = 0; nP2: Integer = 0; nP3 : Integer = 0);
    procedure SendTestGuiDisplay(nGuiMode : Integer; sMsg: string = ''; sMsg2: string = ''; nParam: Integer = 0; nParam2 : Integer = 0);   overload;
    procedure SendTestGuiDisplay(nMsgType,nGuiMode : Integer; sMsg: string = ''; sMsg2: string = ''; nParam: Integer = 0; nParam2 : Integer = 0); overload;
    procedure SendDisplayGuiDisplay(nGuiMode : Integer; nParam : Integer = 0;sMsg : string = '');

    function CheckLastIndexStop(nIndex : integer) : Boolean;
    procedure SethDisplay(const Value: HWND);
    procedure SetGetPatGrp(const Value: TPatterGroup);
//    procedure SetRxData(const Value: TRxData);
    procedure ResetScriptStatus;
    procedure GetMathSqrt_Proc(AMachine:TatVirtualMachine);   //GIB_OPTIC
    procedure GetMathPower_Proc(AMachine:TatVirtualMachine);  //GIB_OPTIC
    procedure GetTimeDiffMsec_Proc(AMachine:TatVirtualMachine);   //GIB_OPTIC
    procedure GetTimeDiffSec_Proc(AMachine:TatVirtualMachine);

    procedure ScriptThread(sScriptFunc : string ; nFirstParam : Integer);
    procedure ScriptThreadIsDone(Sender: TObject);
    procedure DfsUpload_Proc(AMachine:TatVirtualMachine);
    procedure Get_PropValues_Proc(AMachine:TatVirtualMachine);
    procedure Set_PropValues_Proc(AMachine:TatVirtualMachine);

    procedure InsertDataToFile(sInputData : string;var nCnt : Integer; var sData : TStringList);
    function CheckCA310CmdAck(task : TProc; nDelay, nRetry : Integer) : DWORD;
    function CheckBCRCmdAck(nDelay, nRetry : Integer) : DWORD;

    function CheckDIOCmdAck(nDelay, nRetry : Integer) : DWORD;
    function MakeApdrData : string;
    function MakeApdrData_EAS : string;
    function CheckMsgCamWork(nWaitSec : Integer) : DWORD;
    procedure ScriptLog(sLog : string);
//    function MIPI_ICWrite(sCommand: String): DWORD;
//    function MIPIRead(sCommand: String; naReadData: TBytes): DWORD;
//    function MIPIWrite(sCommand: String): DWORD;
    function ConvertBufferToHex(var naBuff: TIdBytes; nStart, nEnd: Integer; sPrefix: String='0x'; sDelimiter: String =' '): String;
    procedure FileExists_Proc(AMachine: TatVirtualMachine);
    procedure DirectoryExists_Proc(AMachine: TatVirtualMachine);
    procedure ForceDirectories_Proc(AMachine: TatVirtualMachine);
    procedure ECS_PCHK_Proc(AMachine: TatVirtualMachine);
    procedure ECS_APDR_Proc(AMachine: TatVirtualMachine);
    procedure ECS_EICR_Proc(AMachine: TatVirtualMachine);
    procedure ECS_ZSET_Proc(AMachine: TatVirtualMachine);
    procedure ECS_SetGlassData_Proc(AMachine: TatVirtualMachine);
    procedure ECS_NotifyEvent(ItemValue: TMESItemValue);
    procedure SetMESCODE_Proc(AMachine: TatVirtualMachine);
    procedure Convert_VariantToAscii_Proc(AMachine: TatVirtualMachine);
    procedure Convert_VariantToHex_Proc(AMachine: TatVirtualMachine);
    procedure PowerSet_Proc(AMachine: TatVirtualMachine);
    procedure PowerBistSet_Proc(AMachine: TatVirtualMachine);
    function CheckConfirmHostAck: DWORD;


//    function SendPocbHexFile_D84X_Template(nPacketSize, nFirstAddr, nNormalAddr: Integer; var sHexCS: String): Integer;
//    procedure SetRxData(const Value: TRxData);


  public
    m_bUse : Boolean;
    m_bPlcDetect : Boolean;
    m_nDioErrCode    : Integer; // for PLC LOCK.
    m_bIsProbeBackSig : boolean;
    m_bComfileCheck : boolean;
    m_bIsSyncSeq   : Boolean;
    m_bIDLE : Boolean;
    nSyncMode      : integer;
    m_bIsRetryContact : Boolean;
    g_bIsBcrReady     : boolean;
    m_bCEL_Stop : Boolean;
//    m_ShowGrid  : array[0..defPg.MAX_FRAME_SIZE] of RGridDisplay;
    //m_TestRet : TTestRetInfo;
    m_RgbAvrInfo : RRgbAvrInfo;
    m_sFileCsv        : string;
    m_sApdrCsv        : string;
    m_sMateriID       : string;
    m_nScriptPgNo   : Integer;      // FPgNo
    m_First_Process_DONE  : Boolean; // First_Process 체크
    m_sCarrierId          : String; // EEPROM Carrier Id (set by Script)
    m_sMesPchkRtnCode     : String; // PCHK_R.RTN_CD (set by PAS)
    m_sMesPchkRtnPID      : String; // PCHK_R.RTN_PID (set by PAS)
    m_sMesPchkModel       : string;
    m_sMesPchkRtnSerialNo : String; // PCHK_R.RTN_SERIAL_NO (Set by PAS)
    m_sMesEicrRtnCode     : String; // EICR_R.RTN_CD (set by PAS)
    m_nMesLpirProcessCode : string; // LPIR_R.PROCESS_CODE
    m_bMesPMMode          : Boolean;// TBD JHHWANG-GMES: 2018-06-20
    m_nNgCode    : Integer; // Script내에서 사용.
    m_nConfirmHostRet: Integer; // Added by KTS 2023-06-21 오전 8:15:30 검사 후 완공보고 여부 재검사 Flow 사용
    m_sNgMsg              : string;
    m_nCamNgCode          : Integer;
    m_InsStatus           : TInsStatus;
    m_bIsScriptWork       : Boolean;
    m_bTotalTact      : Boolean;
    m_bUnitiTact      : Boolean;

    m_bIsReProgramming : Boolean; //ReProgramming OKNG 여부

    m_bMaintWindowOn  : Boolean;  //2018-07-31 JHHWANG
    m_nGibOpticNo     : Integer;  //2018-08-06 JHHWANG
    m_lstPrevRet      : TList<Integer>;
    m_nPlcReadData    : Integer;
    m_InspectResult   : array of TNgRatio;
    PairCh            : integer;
    CurrentSEQ: Integer;
    TestInfo: TTestInformation;

    FR2ROC_EODSName  : array [0..23] of string;
    FR2ROC_EODSData  : array [0..23] of string;
    FR2ROC_Data  : array [0..23] of string;
    FR2R_Old_OC_Data  : array [0..23] of string;
    FR2R_MmcTxnID_Data  : string;
    FR2R_Old_MmcTxnID_Data  : string;
    procedure DefineMethodFunc(SetPaScript : TatPascalScripter);
    constructor Create(nPgNo : Integer; hMain, hTest : HWND; AOwner : TComponent); virtual;
    destructor Destroy; override;
    procedure DebugCheck;
    procedure LoadSource(stData : TStrings);
    procedure InitialScript;
    procedure FinishScript;
    procedure TerminateScript;
    procedure InitialData;
    function RunSeq(nIdx : Integer) : Integer;
    procedure StopMaintScript;
    procedure StopManualKey;
    function ScriptRunning(nKeyIdx : Integer) : Boolean;
    function IsScriptRun : boolean;
    procedure RunMaintScript(hDisplay : HWND; stSource : TScrMemo);
    function ExecFunction(oScript : TatPascalScripter; sScriptFunc: string):string;
       function CheckSyncCmdAck(taskPro : TProc; nDelay, nREtry : Integer) : DWORD;
    ///<summary>임시 함수 실행.
    /// - Main 스크립터가 아니라 별개의 스크립터로 실행.
    /// - 스크립트 자체 전역변수 공유 안됨.
    ///</summary>
    function ExecExtraFunction(sScriptFunc: string): string;
    function ExecExtraFunction2(sScriptFunc: string): string;
    procedure HostEvntConfirm(nRet: Integer);
  {$IFDEF CA310_USE}
    procedure SetCa310Data( Data : TBrightValue);
  {$ENDIF}

    procedure SetBCRData;
    procedure SetDioEvent;
    procedure SetHostEvent(nRet : Integer);
    procedure SetHandleAgain(hMain, hTest: HWND);
    procedure MakeTEndEvt(nIdxErr : Integer; sErrMessage : string);
    // Test , Main 이 아니 Handle로 사용하기 위함. ex> Model Info, Mainter.
    property hDisplay : HWND read FhDisplay write SethDisplay;
    property GetPatGrp : TPatterGroup read FGetPatGrp write SetGetPatGrp;
//    property TouchData : TRxData read FRxData write SetRxData;
  end;
var
  PasScr : array[defCommon.CH1 .. defCommon.MAX_CH] of TScrCls;

implementation
uses
Test4ChOC;

{ TScrCls }

constructor TScrCls.Create(nPgNo: Integer; hMain, hTest: HWND; AOwner : TComponent );
var
  sEventName: String;
begin
  FPgNo := nPgNo;
  if (nPgNo mod 2) = 0 then begin
    PairCh:= nPgNo + 1;
  end
  else begin
    PairCh:= nPgNo - 1;
  end;
  m_bIsCaEvent := False;
  m_bIsBCREvent := False;
  m_bPlcDetect  := True;
  m_nScriptPgNo := nPgNo;  //
//  m_nGibOpticNo := Common.SystemInfo.GibOpticNo;  //2018-08-06 JHHWANG (SystemConfig.ini: GIB_OPTIC_NO)
  m_bMaintWindowOn := False;  //2018-07-31 JHHWANG
  m_bToMaint := False;
  m_MainHandle := hMain;
  m_TestHandle := hTest;
  m_InsStatus  := isReady;
  m_bIsSyncEvent := False;
  m_bIsSyncSeq   := False;
  nSyncMode      := 0;
  m_bTotalTact   := False;
  m_bUnitiTact   := False;
  m_nConfirmHostRet := 0;
  m_sNgMsg := '';

  m_bIDLE := False;

  m_nCurPat  := 0;
  m_bLockThread := False;
  ResetScriptStatus;

  m_lstPrevRet := TList<Integer>.Create;
  m_lstPrevRet.Clear;
  CurrentSEQ:= DefScript.SEQ_STOP;
  TestInfo:= TTestInformation.Create;
  TestInfo.OKCount:= 0;
  TestInfo.NgCode:= 0;
  TestInfo.nPwrVCC := Common.TestModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VCC];
  TestInfo.nPwrVIN := Common.TestModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VIN];
  TestInfo.StartTime := Now;

  SetLength(m_InspectResult,Common.m_nGmesInfoCnt);

  m_bIsScriptWork := False;
  m_bTheadIsTerminated := False;
  m_bCallTerminate:= True;

  atPasScrpt:= TatPascalScripter.Create(nil);
  atScrDebug := TatScriptDebugger.Create(nil);
  atPasScrpt.LibOptions.UseScriptFiles := False;

  // for Maint.
  atPasScrptMaint := TatPascalScripter.Create(nil);
  atScrDebugMaint := TatScriptDebugger.Create(nil);

  DefineMethodFunc(atPasScrpt);
  DefineMethodFunc(atPasScrptMaint);

  m_MESItemValue.Channel:= FPgNo;
  sEventName:= 'SCRIPT.MESEvent.WaitForSingleObject' + IntToStr(FPgNo);
  m_MESItemValue.EventHandle:= CreateEvent(nil, False, False, PWideChar(sEventName));

//{$IFDEF ISPD_L_OPTIC}
//  // Load Param.
//  SetLength(m_LoadOcParam,Common.m_OcParam.IdxOcPCnt);
//  SetLength(m_LoadOcVerify,Common.m_OcParam.IdxOcVCnt);
//
//  for i := 0 to Pred(Common.m_OcParam.IdxOcPCnt) do begin
//    m_LoadOcParam[i] := TInternalScript.Create;
//    m_LoadOcParam[i].OcParam := Common.m_OcParam.OcParam[i];
//  end;
//
//  for i := 0 to Pred(Common.m_OcParam.IdxOcVCnt) do begin
//    m_LoadOcVerify[i] := TInternalScript.Create;
//    m_LoadOcVerify[i].OcParam := Common.m_OcParam.OcVerify[i];
//  end;
//{$ENDIF}

end;

procedure TScrCls.DebugCheck;
begin
  atScrDebug.Scripter := atPasScrpt;
  atScrDebug.Execute;
end;


procedure TScrCls.DefineMethodFunc(SetPaScript : TatPascalScripter);

var
  sParamHint : string;
  nValue : integer;
begin
// Define Method.
//  atPasScrpt.DefineMethod('DisplayProgress',2,tkNone,nil,DisplayProgressProc,False,2);
//  method name, number of arguments, Return type, Result class, procedure wrapper, number of default parameters

  SetPaScript.AddLibrary(TatClassesLibrary);
  SetPaScript.AddLibrary(TatSystemLibrary);
  SetPaScript.AllowDLLCalls:= True; //Use DLL

  m_sEmNo := common.SystemInfo.EQPId;

  m_bCallTerminate := True;
  m_bIsRetryContact := False;

  SetPaScript.DefineClassByRTTI(TOcParamsWR);
  SetPaScript.DefineClassByRTTI(TOcGammaVal);
  SetPaScript.DefineClassByRTTI(TOcGammaCmd);
  SetPaScript.DefineClassByRTTI(TOcVerify);
  SetPaScript.DefineClassByRTTI(TUserArray);
  SetPaScript.DefineClassByRTTI(TOtpTableArray);
  SetPaScript.DefineClassByRTTI(TInsCsv);
  SetPaScript.DefineClassByRTTI(TInsApdr);
  SetPaScript.DefineClassByRTTI(TInsRgbPass);
  SetPaScript.DefineClassByRTTI(TOcDeltaE);
  SetPaScript.DefineClassByRTTI(TMath);
  SetPaScript.DefineClassByRTTI(TTestInformation); //해당 클래스를 스크립트 내부에서 사용하려면 정의해야 한다.


  SetPaScript.DefineRecordByRTTI(TypeInfo(TPwrData));
  SetPaScript.DefineRecordByRTTI(TypeInfo(TGammaCmd));
  SetPaScript.DefineRecordByRTTI(TypeInfo(TOcParam));
  SetPaScript.DefineRecordByRTTI(TypeInfo(TGammaVal));
  SetPaScript.DefineRecordByRTTI(TypeInfo(TRxPwrData));
  SetPaScript.DefineRecordByRTTI(TypeInfo(TOtpReadData));
  SetPaScript.DefineRecordByRTTI(TypeInfo(TSWVer));
  //SetPaScript.DefineRecordByRTTI(TypeInfo(TTestRetInfo)); //해당 구조체 타입을 스크립트 내부에서 사용하려면 정의해야 한다.

  // DLL OC DLOW 관련
  SetPaScript.DefineMethod('f_OcFlowStart',      2,tkInteger, nil,OCFlowStart_Proc,False,0);
  SetPaScript.DefineMethod('f_OcFlowStop',      0,tkInteger, nil,OCFlowStop_Proc,False,0);
  SetPaScript.DefineMethod('f_OC_VerifyStart',      0,tkInteger, nil,OCVerifyStart_Proc,False,0);
  SetPaScript.DefineMethod('f_ThreadStateCheck',      0,tkInteger, nil,OCThreadStateCheck_Proc,False,0);
  SetPaScript.DefineMethod('f_Flash_Read_Se_NO',      0,tkInteger, nil,OCThreadFlash_READ_Proc,False,0);
  SetPaScript.DefineMethod('f_Flash_Write_Se_NO',      1,tkInteger, nil,OCThreadFlash_Write_Proc,False,1).SetVarArgs([0]);
  SetPaScript.DefineMethod('f_SetAgingTm',             2, tkNone, nil, SetAgingTm_Proc,False, 2);
  SetPaScript.DefineMethod('f_ReadPairNgCode',         1, tkNone, nil, ReadPairNgCode_Proc,False, 1).SetVarArgs([0]);
  SetPaScript.DefineMethod('f_ReadGpioPanel_IRQ',      1, tkInteger, nil, GpioPanel_IRQ_Proc,False, 1).SetVarArgs([0]);

  SetPaScript.DefineMethod('f_ConfirmHost', 1, tkInteger, nil, ConfirmHost_Proc,
    False); // 2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
  with SetPaScript.DefineMethod('f_ReadCa410', 3, tkInteger, nil,
    ReadCA410_Proc, False) do
  begin
    SetVarArgs([0, 1, 2]);
    // UpdateParameterHints('var x , y, Lv : Single');
  end;

  // AName, AArgCount, AResultDataType, AResultClass, AProc, AIsClassMethod, ADefArgCount
// AArgCount : Max Parameter. ADefArgCount : Min Parameter.
  SetPaScript.DefineMethod('f_PgToComm',      6,tkInteger, nil,PgToComm_Proc,      False,5);
  SetPaScript.DefineMethod('f_PgReset',      0,tkInteger, nil,PgReset_Proc,      False,0);

  SetPaScript.DefineMethod('f_GPIOSet',    3,tkInteger, nil,GPIOSet_Proc,    False, 2);
  SetPaScript.DefineMethod('Sleep',      1,tkNone,    nil,Sleep_Proc,      False);
  SetPaScript.DefineMethod('f_LogM',       2,tkNone,    nil,LogM_Proc,       False,1);
  SetPaScript.DefineMethod('f_SetCaptionName',       2,tkNone,    nil,SetCaptionName_Proc,       False,0);

  SetPaScript.DefineMethod('f_LogRePGM',       1,tkNone,    nil,LogRePGM_NG_Proc,       False,1);
  SetPaScript.DefineMethod('f_NVMWrite',       0,tkInteger,    nil, NVMWrite_Froc,         False,0);
  SetPaScript.DefineMethod('f_NVMRead',       0,tkNone,    nil, NVMRead_Froc,         False,0);
  SetPaScript.DefineMethod('f_NVMVerify',       0,tkInteger,    nil, NVMVerify_Froc,         False,0);

  SetPaScript.DefineMethod('f_Run_Measure_GrayScale',       1,tkNone,    nil, GrayScale_Proc,         False,1);
  SetPaScript.DefineMethod('f_Run_Measure_CEL_NY',       1,tkNone,    nil, CELYufeng_Proc,         False,1);
  SetPaScript.DefineMethod('f_Run_Measure_DBVtracking',       1,tkNone,    nil, DBVtracking_Proc,         False,1);

  SetPaScript.DefineMethod('f_LogPwr',     0,tkNone,    nil,LogPwr_Proc,     False);
  SetPaScript.DefineMethod('f_PowerMeasure',  1,tkInteger, nil,PowerMeasure_Proc, False,1).SetVarArgs([0]);
  SetPaScript.DefineMethod('f_GetConfigVer',  2,tkInteger, nil,GetConfigVer_Proc, False,1).SetVarArgs([0]);
  SetPaScript.DefineMethod('f_PowerSet',   1, tkInteger, nil, PowerSet_Proc, False, 0);
  SetPaScript.DefineMethod('f_PowerSetBist',   1, tkInteger, nil, PowerBistSet_Proc, False, 0);
  SetPaScript.DefineMethod('f_ShowResult', 3,tkNone,    nil,ShowResult_Proc, False,2);
  SetPaScript.DefineMethod('f_ShowCurStaus', 3,tkNone,    nil,ShowCurStaus_Proc, False,2);
  SetPaScript.DefineMethod('f_ShowSerial', 2,tkNone,    nil,ShowSerial_Proc, False,2);
  SetPaScript.DefineMethod('f_MakeCsv',    2,tkNone,    nil,MakeCsv_Proc,  False);
  SetPaScript.DefineMethod('f_MakeOpticCsv', 1,tkNone,  nil,MakeOpticCsv_Proc,  False);
  SetPaScript.DefineMethod('f_MakeSummaryCsv', 2,tkNone,  nil,MakeCsvSummary_Proc,  False);
  SetPaScript.DefineMethod('f_MakeApdrCsv', 1,tkNone,  nil,MakeCsvSummary_Proc,  False);
  SetPaScript.DefineMethod('f_MakePassRGB', 1,tkNone,  nil,MakePassRGB_Proc,  False);
  SetPaScript.DefineMethod('f_SetCurJigChForPass', 1,tkNone,  nil,SetCurJigChForPass_Proc,  False);
  SetPaScript.DefineMethod('f_LoadPassRgbAvr', 5,tkInteger, nil,LoadPassRgbAvr_Proc,      False,5);

  SetPaScript.DefineMethod('f_GetSummaryLogData', 1,tkString, nil,GetSummaryLogData_Froc,False,1);

//  SetPaScript.DefineMethod('f_WriteFlash_Mipi2SRAM', 1,tkInteger, nil,WriteFlash_Mipi2SRAM_Proc,      False);

  // TSTART SERIAL NO, TIME OUT.
  SetPaScript.DefineMethod('f_CAM_CMD', 5,tkInteger, nil,Set_Cam_Cmd_Proc,      False,5).SetVarArgs([4]);
  SetPaScript.DefineMethod('f_LoadFileData', 4,tkInteger, nil,LoadFileData_Proc,      False,3).SetVarArgs([1,2]);
  SetPaScript.DefineMethod('f_SendPocbHexFile', 7,tkInteger,    nil,SendPocbHexFile_Proc, False,7).SetVarArgs([6]);
  SetPaScript.DefineMethod('f_SendPocbHexFile2', 9,tkInteger,    nil,SendPocbHexFile2_Proc, False);
  SetPaScript.DefineMethod('f_SendPocbDataWrite', 5,tkNone,    nil,SendPocbDataWrite_Proc, False);
  SetPaScript.DefineMethod('f_SendEraseCodeType', 3,tkNone,    nil,SendEraseCodeType_Proc, False,1);
  SetPaScript.DefineMethod('f_SendLightCommand', 3,tkInteger, nil, SendLightCommand_Proc, False,0);  //nCh, Value1, Value2

//  SetPaScript.DefineMethod('f_ReadFlash_Text',      5,tkInteger, nil, ReadFlash_Text_Proc,      False, 5).SetVarArgs([4]);
//  SetPaScript.DefineMethod('f_ReadFlash_GammaData', 1,tkInteger, nil, ReadFlash_GammaData_Proc, False, 1).SetVarArgs([0]);
//  SetPaScript.DefineMethod('f_ReadFlash_OTP_Data',  1,tkInteger, nil, ReadFlash_OTP_Data_Proc,  False, 1).SetVarArgs([0]);
//  SetPaScript.DefineMethod('f_EraseFlash_RM_D',     0,tkInteger, nil, EraseFlash_RM_D_Proc,     False);

  SetPaScript.DefineMethod('f_TactTime',   1,tkNone,    nil,TactTime_Proc,   False);
  SetPaScript.DefineMethod('f_RemakeSerialLog', 2,tkNone, nil, RemakeSerialLog_Proc, False);

  SetPaScript.DefineMethod('f_NextStep',   3,tkNone,    nil,NextStep_Proc,   False);
  SetPaScript.DefineMethod('f_SetInit',    1,tkNone,    nil,SetInit_Proc,    False);
  SetPaScript.DefineMethod('f_CheckRetry',    1,tkInteger,    nil,CheckRetry_Proc,    False);


  SetPaScript.DefineMethod('f_SendLPIR',   2,tkInteger, nil,SendLPIR_Proc,   False,1).SetVarArgs([1]);
  SetPaScript.DefineMethod('f_SendSGEN',   1,tkInteger, nil,SendSGEN_Proc,   False,1); //checkmate 20191115
  SetPaScript.DefineMethod('f_SendPCHK',   3,tkInteger, nil,SendPCHK_Proc,   False,1); // JHHWANG-GMES: 2018-06-20
  SetPaScript.DefineMethod('f_SendINSPCHK', 1,tkInteger, nil,SendINSPCHK_Proc, False,1); // checkmate 20191031
  SetPaScript.DefineMethod('f_SendEICR',   2,tkInteger, nil,SendEICR_Proc,   False,1); // JHHWANG-GMES: 2018-06-20
  SetPaScript.DefineMethod('f_SendEIJR',   1,tkInteger, nil,SendEIJR_Proc,   False,1);
  SetPaScript.DefineMethod('f_SendAPDR',   1,tkInteger, nil,SendApdr_Proc,   False,1);
  SetPaScript.DefineMethod('f_SendAPDR_EAS',   1,tkInteger, nil,SendApdr_EAS_Proc,   False,1);
  SetPaScript.DefineMethod('f_SetMESCODE', 1,tkInteger, nil,SetMESCODE_Proc,   False,1);

  SetPaScript.DefineMethod('f_ECS_PCHK',   2,tkInteger, nil,ECS_PCHK_Proc,   False,1);
  SetPaScript.DefineMethod('f_ECS_ZSET',   1,tkInteger, nil,ECS_ZSET_Proc,   False,1);
  SetPaScript.DefineMethod('f_ECS_EICR',   2,tkInteger, nil,ECS_EICR_Proc,   False,1);
  SetPaScript.DefineMethod('f_ECS_APDR',   1,tkInteger, nil,ECS_APDR_Proc,   False,1);
  SetPaScript.DefineMethod('f_ECS_SetGlassData',   1,tkInteger, nil,ECS_SetGlassData_Proc,   False,1);

  SetPaScript.DefineMethod('f_DfsUpload', 3,tkInteger, nil,DfsUpload_Proc, False);

  SetPaScript.DefineMethod('f_ReadBcr',    1,tkInteger, nil,ReadBcr_Proc,    False);
  SetPaScript.DefineMethod('f_GetBcrData', 2,tkInteger, nil,GetBcrData_Proc, False).SetVarArgs([1]);
  SetPaScript.DefineMethod('f_StrReplace', 3,tkString, nil,StrReplace_Proc, False);

  SetPaScript.DefineMethod('f_ReadDio',    2,tkNone,    nil,ReadDio_Proc,    False).SetVarArgs([1]);
  SetPaScript.DefineMethod('f_WriteDio',   3,tkInteger, nil,WriteDio_Proc,   False,2);
  SetPaScript.DefineMethod('f_SetDio64',   3,tkNone,    nil,SetDio64_Proc,   False,2);  //GIB-OPTIC:DIO
  SetPaScript.DefineMethod('f_GetDio64',   2,tkInteger, nil,GetDio64_Proc,   False,1);  //GIB-OPTIC:DIO
  SetPaScript.DefineMethod('f_SetHandBcr', 1,tkNone,    nil,SetHandBcr_Proc, False);  //GIB-OPTIC:HANDBCR 2018-08-05
  SetPaScript.DefineMethod('f_ControlDio', 1,tkInteger, nil,ControlDio_Proc,   False);
  SetPaScript.DefineMethod('f_SetConfirmRty', 1,tkNone, nil,SetConfirmRty_Proc,   False);
  SetPaScript.DefineMethod('f_GetPlcInfo', 1,tkNone, nil,GetPlcInfo_Proc,   False);

  SetPaScript.DefineMethod('f_GetInfo',    2,tkNone,    nil,GetInfo_Proc,    False).SetVarArgs([1]);
  SetPaScript.DefineMethod('f_GetPatName', 2,tkNone,    nil,GetPatName_Proc, False).SetVarArgs([1]);
  SetPaScript.DefineMethod('f_GetCameraFFCData',    1,tkInteger,    nil, GetCameraFFCData_Proc,    False).SetVarArgs([0]);
  SetPaScript.DefineMethod('f_GetCameraINFOData',   1,tkInteger,    nil, GetCameraINFOData_Proc,    False).SetVarArgs([0]);
  SetPaScript.DefineMethod('f_GetCameraINFOName',   1,tkInteger,    nil, GetCameraINFOName_Proc,    False).SetVarArgs([0]);

  SetPaScript.DefineMethod('f_GetMathSqrt', 2,tkNone,    nil,GetMathSqrt_Proc, False).SetVarArgs([1]);  //GIB-OPTIC
  SetPaScript.DefineMethod('f_GetMathPower', 3,tkNone,   nil,GetMathPower_Proc, False).SetVarArgs([2]); //GIB-OPTIC
  SetPaScript.DefineMethod('f_GetTimeDiffMsec', 2,tkInteger, nil,GetTimeDiffMsec_Proc, False); //GIB-OPTIC
  SetPaScript.DefineMethod('f_GetTimeDiffSec', 2,tkInteger, nil,GetTimeDiffSec_Proc, False);

  SetPaScript.DefineMethod('f_OtpWrite', 0,tkInteger,  nil,OtpWrite_Proc,False);
  SetPaScript.DefineMethod('f_OtpRead', 0,tkInteger,  nil,OtpRead_Proc,False);
  SetPaScript.DefineMethod('f_GetOffSetTable', 4,tkNone,  nil,GetOffSetTable_Proc,False).SetVarArgs([1,2,3]);
  SetPaScript.DefineMethod('f_GetGammaOffSetTable', 5,tkNone,  nil,GetGammaOffSetTable_Proc,False).SetVarArgs([1,2,3,4]);
//  SetPaScript.DefineMethod('f_GetCameraOtpData', 3,tkInteger,  nil,SetCamOtpData_Proc,False);
  SetPaScript.DefineMethod('f_FileExists', 1,tkInteger,  nil, FileExists_Proc, False);
  SetPaScript.DefineMethod('f_DirectoryExists', 1,tkInteger,  nil, DirectoryExists_Proc, False);
  SetPaScript.DefineMethod('f_ForceDirectories', 1,tkInteger,  nil, ForceDirectories_Proc, False);
  SetPaScript.DefineMethod('f_Convert_VariantToHex',  5,tkString, nil, Convert_VariantToHex_Proc,  False);
  SetPaScript.DefineMethod('f_Convert_VariantToAscii',  3,tkString, nil, Convert_VariantToAscii_Proc,  False);
  SetPaScript.DefineMethod('f_IonizerOn',        2,tkInteger, nil, IonizerOn_Proc, False);

  // Hint 때문에 Out of Memory 발생.
//  // Parameter Hint for I2CWrite
//  sParamHint := 'Line Select(1 byte),Add Size(1 byte),I2C_Type(1 byte),Device_Add(1 byte),MSB Register_Add(1 byte)';
//  sParamHint := sParamHint + ',LSB Register_Add(1 byte),Data Length(2 byte),DATA[Length]';
  SetPaScript.DefineMethod('f_I2CWrite',   2,tkInteger, nil,I2CWrite_Proc,  False,2).UpdateParameterHints(sParamHint);
  SetPaScript.DefineMethod('f_ProgrammingWrite',   2,tkInteger, nil,ProgrammingWrite_Proc,  False,2);

//  // Parameter Hint for I2CWrite
//  sParamHint := 'Line Select(1 byte),Add Size(1 byte),I2C_Type(1 byte),Device_Add(1 byte),MSB Register_Add(1 byte)';
//  sParamHint := sParamHint + ',LSB Register_Add(1 byte),Data Length(2 byte) / Read Buffer.';
  with SetPaScript.DefineMethod('f_I2CRead', 4, tkVariant, nil, I2CRead_Proc, False,3) do begin
//    UpdateParameterHints(sParamHint);
    SetVarArgs([3]);
  end;

//  // Parameter Hint for Mipi Write
//  sParamHint := 'DSI_Data_Type(1 byte),Address(1 byte),Write Data[n]';
  SetPaScript.DefineMethod('f_MIPIWrite',  2,tkInteger, nil,MIPIWrite_Proc,  False,2);//.UpdateParameterHints(sParamHint);
  SetPaScript.DefineMethod('f_MIPIWriteHS',  2,tkInteger, nil, MIPIWriteHS_Proc,  False,2); //added 2019114
  SetPaScript.DefineMethod('f_MIPI_IC_WRITE',  2,tkInteger, nil,MIPI_ICWrite_Proc,  False,2);
  SetPaScript.DefineMethod('f_MIPI_CLK_BPS',  1,tkInteger, nil,MIPI_ClkBps_Proc,  False);

//  // Parameter Hint for Mipi Read
//  sParamHint := 'Address(1 byte),Command (1 byte), Read Data Size(1 byte)';
  with SetPaScript.DefineMethod('f_MIPIRead', 3, tkVariant, nil,MIPIRead_Proc, False,2) do begin
//    UpdateParameterHints(sParamHint);
    SetVarArgs([1]);
  end;

  // Added by Clint 2020-12-30 오전 3:10:04
//  SetPaScript.DefineMethod('f_ChangeVoltSet',  3,tkInteger,  nil, ChangeVoltSet_Proc, False);
//  SetPaScript.DefineMethod('f_EnableVoltSet',  2,tkInteger,  nil, EnableVoltSet_Proc, False);


  SetPaScript.AddVariable('c_sFileCsv',m_sFileCsv);  // for summary csv.
  SetPaScript.AddVariable('c_sApdrCsv',m_sApdrCsv);  // for Apdr csv.

  SetPaScript.AddVariable('c_bCallTerminate',m_bCallTerminate);
  SetPaScript.AddVariable('c_sEmNo',m_sEmNo);
  SetPaScript.AddVariable('c_nPatNum',m_nCurPat);
  SetPaScript.AddVariable('c_nCurCh',Self.FPgNo);
  SetPaScript.AddVariable('c_nRetryCount_WritePOCB', Common.SystemInfo.RetryCount_WritePOCB);
  SetPaScript.AddVariable('c_sMES_Model',m_sMesPchkModel);
  SetPaScript.AddVariable('c_bMesPMMode',m_bMesPMMode);
  SetPaScript.AddVariable('c_nConfirmHostRet',m_nConfirmHostRet);

  SetPaScript.AddVariable('c_nScriptPgNo',m_nScriptPgNo);
  SetPaScript.AddVariable('c_nGibOpticNo',m_nGibOpticNo);
  SetPaScript.AddVariable('c_bMaintWindowOn',m_bMaintWindowOn);  //2018-07-31 JHHWANG
  SetPaScript.AddVariable('c_sCarrierId',m_sCarrierId);
  SetPaScript.AddVariable('c_sSerialNo',TestInfo.SerialNo);  //checkmate 20191031
  SetPaScript.AddVariable('c_sMesRtnSerialNo', m_sMesPchkRtnSerialNo);  //checkmate 201911115
  SetPaScript.AddVariable('c_sEquipment', Common.SystemInfo.EQPId);  //checkmate 201911115

  SetPaScript.AddVariable('c_nNgCode',m_nNgCode);
  SetPaScript.AddVariable('c_sNgMsg',m_sNgMsg);

  SetPaScript.AddVariable('c_bIsReProgramming',PG[Self.FPgNo].bIsReProgramming);

  SetPaScript.AddVariable('c_bIsRetryContact',m_bIsRetryContact);
  SetPaScript.AddVariable('c_bIsSyncSeq',m_bIsSyncSeq);
  SetPaScript.AddVariable('c_nSyncMode', nSyncMode);
  SetPaScript.AddVariable('c_bIsBcrReady',g_bIsBcrReady);
  SetPaScript.AddVariable('c_sRootDir',Common.Path.RootSW);

  SetPaScript.AddObject('c_TestInfo', TestInfo);
  SetPaScript.AddVariable('c_First_Process_DONE', m_First_Process_DONE);

  SetPaScript.AddVariable('c_bChkSWVer',Common.TestModelInfoFLOW.UseCheckVer);

  SetPaScript.AddVariable('c_nChkSWVerConut',Common.SystemInfo.ConfigVerCount);

  SetPaScript.AddVariable('c_UseCheckReProgramming',Common.TestModelInfoFLOW.UseCheckReProgramming);

  SetPaScript.AddVariable('c_bIDLE',m_bIDLE);

  SetPaScript.AddVariable('c_bCEL_Stop',m_bCEL_Stop);

  SetPaScript.AddVariable('c_NVMWriteSequence',Common.TestModelInfoFLOW.UseCkNVMWriteSequence);

  SetPaScript.AddVariable('c_IdleModeDTime',Common.TestModelInfoFLOW.IdleModeDTime);

  SetPaScript.AddVariable('c_bChkIRA',PG[Self.FPgNo].m_bChkIRA);

  SetPaScript.AddVariable('c_bChkShutdown_Fault',PG[Self.FPgNo].m_bChkShutdown_Fault);


//  SetPaScript.AddVariable('c_NVMWriteSequence',nNVMWriteSequence);
  //문자열 속성 반환 p_Values[0], 필요 시 Get, Set에서 추가
  SetPaScript.DefineProp('c_Values',tkVariant, Get_PropValues_Proc, Set_PropValues_Proc, nil, False, 1); //checkmate 20191030

//{$IFDEF ISPD_L_OPTIC}
//  // Load Param.
//  for i := 0 to Pred(Common.m_OcParam.IdxOcPCnt) do begin
//    sTemp := Format('m_OcParam%d',[i]);
//    SetPaScript.AddObject(sTemp,m_LoadOcParam[i]);
//  end;
//  // Load Verify.
//  for i := 0 to Pred(Common.m_OcParam.IdxOcVCnt) do begin
//    sTemp := Format('m_OcVerify%d',[i]);
//    SetPaScript.AddObject(sTemp,m_LoadOcVerify[i]);
//  end;
//{$ENDIF}

//  SetPaScript.DefineRecordByRTTI(TypeInfo(TTestRecord));
//  with SetPaScript.DefineMethod('RecTest',   1,tkNone, nil,RecordTest_Proc,  False) do begin
//    SetVarArgs([0]);
//  end;



end;

destructor TScrCls.Destroy;
begin
  TerminateScript;
  sleep(1000);
  if atPasScrpt.Running then begin
      atPasScrpt.Halt;
  end;


  if atScrDebugMaint <> nil then begin
    atScrDebugMaint.Free;
    atScrDebugMaint := nil;
  end;

  if atPasScrptMaint <> nil then begin
    atPasScrptMaint.Free;
    atPasScrptMaint := nil;
  end;

  if m_lstPrevRet <> nil then begin
    m_lstPrevRet.Clear;
    m_lstPrevRet.Free;
    m_lstPrevRet := nil;
  end;

  if atScrDebug <> nil then begin
    atScrDebug.Free;
    atScrDebug := nil;
  end;

  if atPasScrpt <> nil then begin
    if atPasScrpt.Running then begin
      atPasScrpt.Halt;
      Sleep(1000);
    end;
    atPasScrpt.Clear;
    atPasScrpt.Free;
    atPasScrpt := nil;
  end;

  if TestInfo <> nil then begin
    TestInfo.Free;
    TestInfo:= nil;
  end;

  CloseHandle(m_MESItemValue.EventHandle);

  inherited;
end;

procedure TScrCls.DfsUpload_Proc(AMachine: TatVirtualMachine);
var
  nConnect, nRet : Integer;
  sSerialNo, sBinFullName : string;
begin
  nRet := -1;
  With AMachine do begin
    if InputArgCount = 3 then begin

{$IFDEF USE_DFS}
      if Common.DfsConfInfo.bUseDfs then begin
        sSerialNo := GetInputArgAsString(0);
        sBinFullName := GetInputArgAsString(1);
        nConnect := GetInputArgAsInteger(2);

        if nConnect in [1,2] then begin
          ScriptLog('<DFS> DFS Server Connect');
          DfsFtpCh[FPgNo].Connect;
        end;
        if DfsFtpCh[FPgNo].IsConnected then begin
          ScriptLog('<DFS> Compensation Data File Upload Start');
          nRet := DfsFtpCh[FPgNo].DfsHexFilesUpload(trim(sSerialNo), TestInfo.StartTime, sBinFullName);
          ScriptLog('<DFS> Compensation Data File Upload Done');
          if nConnect in [0,2] then begin
            DfsFtpCh[FPgNo].Disconnect;
            ScriptLog('<DFS> DFS Server Disconnect');
          end;
        end
        else begin
          ScriptLog('DFS Server is Not Connected');
        end;

      end
      else begin
        ScriptLog('Not Use DFS');
        nRet := 0;
      end;
{$ENDIF};
    end;
    ReturnOutputArg( nRet);
  end;

end;

function TScrCls.ExecFunction(oScript: TatPascalScripter; sScriptFunc: string): string;
var
  sl: TStringList;
  sFuncName: string;
  sParam: string;
  nPos: Integer;
  vaParams: array of Variant;
  i: Integer;
  vResult: Variant;
begin
  if not oScript.Compiled then begin
    Result:= ''; //Not Compiled;
    Exit;
  end;
  //oScript.ExecuteSubroutine(sScriptFunc);
  VarClear(vResult);

  nPos:= Pos(' ', sScriptFunc);
  if nPos > 0 then begin
    sFuncName:= Copy(sScriptFunc, 1, nPos-1);
    sParam:= Copy(sScriptFunc, nPos+1, Length(sScriptFunc));
  end
  else begin
    sFuncName:= sScriptFunc;
    sParam:= '';
  end;

  if sParam <> '' then begin
    sl:= TStringList.Create;
    try
      ExtractStrings([','], [], PWideChar(sParam), sl);

      if (sl.Count > 0) then begin
        SetLength(vaParams, sl.Count);
        for i := 0 to Pred(sl.Count) do  begin
          vaParams[i]:= sl.Strings[i];
        end;
        //VarArrayOf([1,5])
        vResult:= oScript.ExecuteSubroutine(sFuncName, vaParams);
      end
      else begin
        vResult:= oScript.ExecuteSubroutine(sFuncName);
      end;
    finally
      FreeAndNil(sl);
    end;
  end
  else begin
    vResult:= oScript.ExecuteSubroutine(sFuncName);
  end;

  if (VarType(vResult) = varEmpty) or (VarType(vResult) = varNull) then begin
    Result:= '';  //Return 없음
  end
  else begin
    Result:= VarToStr(vResult);
  end;
end;
//
//procedure TScrCls.EnableVoltSet_Proc(AMachine: TatVirtualMachine);
//var
//  dwRet : DWORD;
//  nSet, nSelect : Integer;
//  sSendCmd, sDebug : String;
//begin
//  With AMachine do begin
//    dwRet:= WAIT_FAILED;
//
//    if InputArgCount = 2 then begin
//      nSet:= GetInputArgAsInteger(0);
//      nSelect:= GetInputArgAsInteger(1);
//
//      dwRet:= Pg[FPgNo].SendEnableVoltSet(nSet, nSelect);
//      if dwRet = WAIT_OBJECT_0 then begin
//        sDebug := Format('OK, Set:%d, Select:%d', [nSet, nSelect]);
//      end
//      else begin
//        sDebug := Format('NG, Set:%d, Select:%d', [nSet, nSelect]);
//      end;
//
//      //if common.SystemInfo.DebugLog then Common.MLog(self.FPgNo,'[Source Code] Enable VoltSet ' + sDebug);
//    end;
//    ReturnOutputArg(dwRet);
//  end;
//end;

function TScrCls.ExecExtraFunction(sScriptFunc: string): string;
var
  sl: TStringList;
  sFuncName: string;
  sParam: string;
  nPos: Integer;
  vaParams: array of Variant;
  i: Integer;
  vResult: Variant;
  AStream: TMemoryStream;
begin
  //if atPasScrptMaint.Running then Exit('');

  if not atPasScrpt.Compiled then begin
    Result:= ''; //Not Compiled;
    Exit;
  end;
(*
  AStream:= TMemoryStream.Create;
  try
    atPasScrpt.SaveCodeToStream(AStream);
    AStream.Position:= 0;
    atPasScrptMaint.LoadCodeFromStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
*)
  VarClear(vResult);

  nPos:= Pos(' ', sScriptFunc);
  if nPos > 0 then begin
    sFuncName:= Copy(sScriptFunc, 1, nPos-1);
    sParam:= Copy(sScriptFunc, nPos+1, Length(sScriptFunc));
  end
  else begin
    sFuncName:= sScriptFunc;
    sParam:= '';
  end;

  if sParam <> '' then begin
    sl:= TStringList.Create;
    try
      ExtractStrings([','], [], PWideChar(sParam), sl);
      try
        if (sl.Count > 0) then begin
          SetLength(vaParams, sl.Count);
          for i := 0 to Pred(sl.Count) do  begin
            vaParams[i]:= sl.Strings[i];
          end;
          //VarArrayOf([1,5])
          //vResult:= atPasScrptMaint.ExecuteSubroutine(sFuncName, vaParams);
          vResult:= atPasScrpt.ExecuteSubroutine(sFuncName, vaParams);

        end
        else begin
          //vResult:= atPasScrptMaint.ExecuteSubroutine(sFuncName);
          vResult:= atPasScrpt.ExecuteSubroutine(sFuncName);
        end;
      except
        on E: Exception do begin
          SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,format('Runtime Error ExecExtraFunction "%s": %s ', [sFuncName, E.Message]),'',0);
          vResult:= '';
        end

      end;
    finally
      FreeAndNil(sl);
    end;
  end
  else begin
    try
      //vResult:= atPasScrptMaint.ExecuteSubroutine(sFuncName);
      vResult:= atPasScrpt.ExecuteSubroutine(sFuncName);
    except
      on E: Exception do begin
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,format('Runtime Error ExecExtraFunction "%s": %s ', [sFuncName, E.Message]),'',0);
        vResult:= '';
      end
    end;
  end;

  if (VarType(vResult) = varEmpty) or (VarType(vResult) = varNull) then begin
    Result:= '';  //Return 없음
  end
  else begin
    Result:= VarToStr(vResult);
  end;
end;


function TScrCls.ExecExtraFunction2(sScriptFunc: string): string;
var
  sl: TStringList;
  sFuncName: string;
  sParam: string;
  nPos: Integer;
  vaParams: array of Variant;
  i: Integer;
  vResult: Variant;
  AStream: TMemoryStream;
begin
  //if atPasScrptMaint.Running then Exit('');

  if not atPasScrpt.Compiled then begin
    Result:= ''; //Not Compiled;
    Exit;
  end;

  AStream:= TMemoryStream.Create;
  try
    atPasScrpt.SaveCodeToStream(AStream);
    AStream.Position:= 0;
    atPasScrptMaint.LoadCodeFromStream(AStream);
  finally
    FreeAndNil(AStream);
  end;

  VarClear(vResult);

  nPos:= Pos(' ', sScriptFunc);
  if nPos > 0 then begin
    sFuncName:= Copy(sScriptFunc, 1, nPos-1);
    sParam:= Copy(sScriptFunc, nPos+1, Length(sScriptFunc));
  end
  else begin
    sFuncName:= sScriptFunc;
    sParam:= '';
  end;

  if sParam <> '' then begin
    sl:= TStringList.Create;
    try
      ExtractStrings([','], [], PWideChar(sParam), sl);
      try
        if (sl.Count > 0) then begin
          SetLength(vaParams, sl.Count);
          for i := 0 to Pred(sl.Count) do  begin
            vaParams[i]:= sl.Strings[i];
          end;
          //VarArrayOf([1,5])
          vResult:= atPasScrptMaint.ExecuteSubroutine(sFuncName, vaParams);
          //vResult:= atPasScrpt.ExecuteSubroutine(sFuncName, vaParams);

        end
        else begin
          vResult:= atPasScrptMaint.ExecuteSubroutine(sFuncName);
          //vResult:= atPasScrpt.ExecuteSubroutine(sFuncName);
        end;
      except
        on E: Exception do begin
          SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,format('Runtime Error ExecExtraFunction "%s": %s ', [sFuncName, E.Message]),'',0);
          vResult:= '';
        end

      end;
    finally
      FreeAndNil(sl);
    end;
  end
  else begin
    try
      vResult:= atPasScrptMaint.ExecuteSubroutine(sFuncName);
      //vResult:= atPasScrpt.ExecuteSubroutine(sFuncName);
    except
      on E: Exception do begin
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,format('Runtime Error ExecExtraFunction "%s": %s ', [sFuncName, E.Message]),'',0);
        vResult:= '';
      end
    end;
  end;

  if (VarType(vResult) = varEmpty) or (VarType(vResult) = varNull) then begin
    Result:= '';  //Return 없음
  end
  else begin
    Result:= VarToStr(vResult);
  end;
end;

procedure TScrCls.HostEvntConfirm(nRet: Integer);
// 2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
begin
  if m_bIsWaitConfirmHostEvent then
  begin
    m_nConfirmHostRet := nRet;
    SetEvent(m_hConfirmHostEvent);
  end;
end;



function IsValidString(const S: string): Boolean;
begin
  Result := TRegEx.IsMatch(S, '^[a-zA-Z0-9+]+$');
end;

procedure TScrCls.GetBcrData_Proc(AMachine: TatVirtualMachine);
var
  sTempBcr,sIsAlphaNumeric : String;
  nTemp : Integer;
begin
  with AMachine do begin
    nTemp := GetInputArgAsInteger(0);
    if nTemp = 0 then begin // panel ID
      sTempBcr := TestInfo.SerialNo
    end
    else if nTemp = 1 then begin // Jig ID
      sTempBcr := TestInfo.CarrierId;
    end
    else if nTemp = 2 then begin // MateriID
     sTempBcr := TestInfo.MateriID;
    end;

    if sTempBcr <> '' then
      SetInputArg(1,sTempBcr);
  end;
end;

function TScrCls.CheckConfirmHostAck: DWORD;

var
  nRet: DWORD;
  i: Integer;
  sEvnt: WideString;
begin
  try
    nRet := 1;
    sEvnt := format('WAIT_EVENT_%d', [FPgNo]);
    ScriptLog('CheckConfirmHostAck Check wait');
    m_bIsWaitConfirmHostEvent := True; // Create Event 했는지 확인 하는 Flag.
    m_hConfirmHostEvent := CreateEvent(nil, False, False, PWideChar(sEvnt));
    nRet := WaitForSingleObject(m_hConfirmHostEvent, INFINITE);
    ScriptLog('CheckConfirmHostAck Check Done');
  finally
    CloseHandle(m_hConfirmHostEvent);
    m_bIsWaitConfirmHostEvent := False;
  end;
  Result := nRet
end;


procedure TScrCls.ConfirmHost_Proc(AMachine: TatVirtualMachine);
// 2020-06-03 CONFIRM_RESULT_REPORT_TO_HOST
var
  nRet: Integer;
begin
  With AMachine do
  begin
    nRet := 1; // Return NG.
    if InputArgCount = 1 then
    begin
      nRet := GetInputArgAsInteger(0);
{$ifdef SIMULATOR}
      if True then
{$ELSE}
      if DongaGmes <> nil then
{$ENDIF}

      begin // CONFIRM_RESULT_REPORT_TO_HOST ??/
        if Common.AutoReStart then begin
         ReturnOutputArg(0);
         exit;
        end;

        if nRet = 0 then
        begin
          SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_CONFIRM_EICR, '', '', 0,
            m_nNgCode);
        end
        else if nRet = 1 then
        begin
          SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_CONFIRM_EICR, '', '', 1,
            m_nNgCode);
          CheckConfirmHostAck;
          SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_CONFIRM_EICR, '', '', 0,
            m_nNgCode);
          nRet := m_nConfirmHostRet;
        end
        else begin
          m_nConfirmHostRet := nRet;
        end;
      end
      else
      begin
        nRet := 0;
      end;
    end;
    ReturnOutputArg(nRet);
  end;
end;

procedure TScrCls.GetGammaOffSetTable_Proc(AMachine: TatVirtualMachine);
var
  nIdx : Integer;
begin
  with AMachine do begin
    nIdx := GetInputArgAsInteger(0);
    if nIdx > 30 then begin
      SetInputArg(1,Common.m_OffsetTable[nIdx].Tx);
      SetInputArg(2,Common.m_OffsetTable[nIdx].Ty);
      SetInputArg(3,Common.m_OffsetTable[nIdx].Lx);
      SetInputArg(4,Common.m_OffsetTable[nIdx].Ly);
    end;
  end;
end;


procedure TScrCls.GetCameraFFCData_Proc(AMachine: TatVirtualMachine);
var
  dRet      : Integer;
  vData : Variant;
  nCamCh: Integer;
  i: Integer;
begin
  With AMachine do begin
    dRet := 0;
    vData := GetInputArg(0);
    vData[0]:= CommCamera.InfoData[FPgNo].FFCData[0]; //camera Temperature;
    for i := 1 to 9 do begin
      vData[i]:= CommCamera.InfoData[FPgNo].FFCData[i]; //TestInfo.FFCData[i];
    end;

    for i := 0 to 9 do begin
      vData[10 + i]:= CommCamera.InfoData[FPgNo].FFCData[10 + i]; //TestInfo.FFCData[10 + i];
    end;

    for i := 1 to 9 do begin
      vData[20 + i]:= CommCamera.InfoData[FPgNo].FFCData[20 + i]; //TestInfo.FFCData[20 + i];
    end;

    for i := 0 to 9 do begin
      vData[30 + i]:= CommCamera.InfoData[FPgNo].FFCData[30 + i]; //TestInfo.FFCData[30 + i];
    end;

    for i := 1 to 9 do begin
      vData[40 + i]:= CommCamera.InfoData[FPgNo].FFCData[40 + i]; //TestInfo.FFCData[40 + i];
    end;

(*
    nCamCh :=  Self.FPgNo mod (DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT); //FPgNo mod 4;
    vData[0]:= CommCamera.CommandData[nCamCh].FFCData[0]; //camera Temperature;
    for i := 1 to 9 do begin
      vData[i]:= CommCamera.CommandData[nCamCh].FFCData[i]; //TestInfo.FFCData[i];
    end;

    for i := 0 to 9 do begin
      vData[10 + i]:= CommCamera.CommandData[nCamCh].FFCData[10 + i]; //TestInfo.FFCData[10 + i];
    end;

    for i := 1 to 9 do begin
      vData[20 + i]:= CommCamera.CommandData[nCamCh].FFCData[20 + i]; //TestInfo.FFCData[20 + i];
    end;

    for i := 0 to 9 do begin
      vData[30 + i]:= CommCamera.CommandData[nCamCh].FFCData[30 + i]; //TestInfo.FFCData[30 + i];
    end;

    for i := 1 to 9 do begin
      vData[40 + i]:= CommCamera.CommandData[nCamCh].FFCData[40 + i]; //TestInfo.FFCData[40 + i];
    end;
*)
    SetInputArg(0, vData); //결과 값 반환
    ReturnOutputArg( dRet);
  end;
end;

procedure TScrCls.GetCameraINFOData_Proc(AMachine: TatVirtualMachine);
var
  dRet      : Integer;
  vData : Variant;
  nCamCh: Integer;
  i: Integer;
begin
  With AMachine do begin
    dRet := 0;
    vData := GetInputArg(0);
    for i := 0 to 150 do begin
      vData[i]:= CommCamera.InfoData[FPgNo].INFOData[i]; //TestInfo.INFOData[i];
    end;
(*
    nCamCh:=  Self.FPgNo mod (DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT); //FPgNo mod 4;
    for i := 0 to 150 do begin
      vData[i]:= CommCamera.CommandData[nCamCh].INFOData[i]; //TestInfo.INFOData[i];
    end;
*)
    SetInputArg(0, vData); //결과 값 반환
    ReturnOutputArg( dRet);
  end;
end;

procedure TScrCls.GetCameraINFOName_Proc(AMachine: TatVirtualMachine);
var
  dRet      : Integer;
  vData : Variant;
  nCamCh: Integer;
  i: Integer;
begin
  With AMachine do begin
    dRet := 0;
    vData := GetInputArg(0);
    nCamCh:=  Self.FPgNo mod (DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT); //FPgNo mod 4;
    for i := 0 to 150 do begin
      vData[i]:= CommCamera.InfoData[nCamCh].INFOName[i]; //TestInfo.INFOData[i];
    end;

    SetInputArg(0, vData); //결과 값 반환
    ReturnOutputArg( dRet);
  end;
end;

procedure TScrCls.GetInfo_Proc(AMachine: TatVirtualMachine);
begin
  With AMachine do begin
		Case InputArgCount of
      2 : begin
        case GetInputArgAsInteger(0) of
          1 : begin
            SetInputArg(1,Self.GetPatGrp.PatCount);
          end;
        end;
      end;
    End;
  end;
end;

procedure TScrCls.GetMathSqrt_Proc(AMachine: TatVirtualMachine);  //GIB_OPTIC
var
  inValue  : Single;
  outValue : Single;
begin
  With AMachine do begin
		Case InputArgCount of
      2 : begin
        inValue  := GetInputArgAsFloat(0);
        outValue := Sqrt(inValue);
        SetInputArg(1,outValue);
      end;
    End;
  end;
end;

procedure TScrCls.GetMathPower_Proc(AMachine: TatVirtualMachine); //GIB_OPTIC
var
  baseValue : Single;
  expValue  : Single;
  outValue  : Single;
begin
  With AMachine do begin
		Case InputArgCount of
      3 : begin
        baseValue := GetInputArgAsFloat(0);
        expValue  := GetInputArgAsFloat(1);
        outValue  := Power(baseValue,expValue);
        SetInputArg(2,outValue);
      end;
    End;
  end;
end;

procedure TScrCls.GetTimeDiffMsec_Proc(AMachine: TatVirtualMachine);  //GIB_OPTIC
var
  time1    : TDateTime;
  time2    : TDateTime;
  diffmsec : Integer;
begin
  With AMachine do begin
		Case InputArgCount of
      2 : begin
        time1 := GetInputArgAsFloat(0);
        time2 := GetInputArgAsFloat(1);
        diffmsec := MilliSecondsBetween(time1,time2);
        ReturnOutputArg(diffmsec)
      end;
    End;
  end;
end;

procedure TScrCls.GetTimeDiffSec_Proc(AMachine: TatVirtualMachine);
var
  time1    : TDateTime;
  time2    : TDateTime;
  diffmsec : Integer;
begin
  With AMachine do begin
		Case InputArgCount of
      2 : begin
        time1 := GetInputArgAsFloat(0);
        time2 := GetInputArgAsFloat(1);
        diffmsec := SecondsBetween(time1,time2);
        ReturnOutputArg(diffmsec);
      end;
    End;
  end;
end;

procedure TScrCls.Get_PropValues_Proc(AMachine: TatVirtualMachine);
var
  inx: integer;
begin
  //필요 시 계속 추가 필요,  Set_PropValues_Proc과 쌍으로 작업
  with AMachine do begin
    inx:= GetArrayIndex(0);

    case inx of
      0: ReturnOutputArg(TestInfo.SerialNo);
      1: ReturnOutputArg(TestInfo.SerialNo); //Probe 상태
      //0: ReturnOutputArg('123234');
    else
      begin
        ReturnOutputArg('');
      end;
    end;

  end;
end;


procedure TScrCls.Set_PropValues_Proc(AMachine: TatVirtualMachine);
var
  inx: integer;
  setValue: string;
begin
  //필요 시 계속 추가 필요,  Get_PropValues_Proc과 쌍으로 작업
  with AMachine do begin
    inx:= GetArrayIndex(0);
    setValue:= GetInputArgAsString(0);
    case inx of
      0: TestInfo.SerialNo:= setValue;
    else
      begin

      end;
    end;

  end;
end;


procedure TScrCls.GetOcParam_Proc(AMachine: TatVirtualMachine);
var
  i, nParamCnt, nRet, nPos : Integer;
  sSearchItem     :  string;
  bSearched       : Boolean;
  Wrapper         : TGenericRecordWrapper;
  OcParamCode     : POcParam;
begin

  with AMachine do begin
    nRet := 1;
    if InputArgCount = 2 then begin
      sSearchItem := GetInputArgAsString(0);
      Wrapper := VarToObject(AMachine.GetInputArg(1)) as TGenericRecordWrapper;
      OcParamCode := POcParam(Wrapper.Rec);

      nParamCnt := Common.m_OcParam.IdxOcPCnt;
      bSearched := False;
      nPos := 0;
      for i := 0 to Pred(nParamCnt) do begin
        if sSearchItem = Common.m_OcParam.OcParam[i].ItemName then begin
          nPos := i;
          nRet := 0;
          bSearched := True;
          Break;
        end;
      end;
      if bSearched then begin
        OcParamCode^ := Common.m_OcParam.OcParam[nPos];
        SetInputArg(1,ObjectToVar(Wrapper) );
        nRet := 0;
      end;
    end;
//    ReturnOutputArg(nRet);
//    if InputArgCount = 13 then begin
//      sSearchItem := GetInputArgAsString(0);
//
//      nParamCnt := Common.m_OcParam.IdxOcPCnt;
//      bSearched := False;
//      nPos := 0;
//      for i := 0 to Pred(nParamCnt) do begin
//        if sSearchItem = Common.m_OcParam.OcParam[i].ItemName then begin
//          nPos := i;
//          nRet := 0;
//          bSearched := True;
//          Break;
//        end;
//      end;
//
//      if bSearched then begin
//        SetInputArg(1,Common.m_OcParam.OcParam[nPos].Gamma.r);
//        SetInputArg(2,Common.m_OcParam.OcParam[nPos].Gamma.g);
//        SetInputArg(3,Common.m_OcParam.OcParam[nPos].Gamma.b);
//        SetInputArg(4,Common.m_OcParam.OcParam[nPos].Target.x);
//        SetInputArg(5,Common.m_OcParam.OcParam[nPos].Target.y);
//        SetInputArg(6,Common.m_OcParam.OcParam[nPos].Target.Lv);
//        SetInputArg(7,Common.m_OcParam.OcParam[nPos].Limit.x);
//        SetInputArg(8,Common.m_OcParam.OcParam[nPos].Limit.y);
//        SetInputArg(9,Common.m_OcParam.OcParam[nPos].Limit.Lv);
//        SetInputArg(10,Common.m_OcParam.OcParam[nPos].Ratio.x);
//        SetInputArg(11,Common.m_OcParam.OcParam[nPos].Ratio.y);
//        SetInputArg(12,Common.m_OcParam.OcParam[nPos].Ratio.Lv);
//      end;
//    end


  end;
end;

procedure TScrCls.GetOcVerify_Proc(AMachine: TatVirtualMachine);
var
  i, nParamCnt, nRet, nPos : Integer;
  sSearchItem  :  string;
  bSearched    : Boolean;
begin

  with AMachine do begin
    nRet := 1;
    if InputArgCount = 7 then begin
      sSearchItem := GetInputArgAsString(0);
      nParamCnt := Common.m_OcParam.IdxOcVCnt;
      bSearched := False;
      nPos := 0;
      for i := 0 to Pred(nParamCnt) do begin
        if sSearchItem = Common.m_OcParam.OcVerify[i].ItemName then begin
          nPos := i;
          nRet := 0;
          bSearched := True;
          Break;
        end;
      end;
      if bSearched then begin
        SetInputArg(1,Common.m_OcParam.OcVerify[nPos].Target.x);
        SetInputArg(2,Common.m_OcParam.OcVerify[nPos].Target.y);
        SetInputArg(3,Common.m_OcParam.OcVerify[nPos].Target.Lv);
        SetInputArg(4,Common.m_OcParam.OcVerify[nPos].Limit.x);
        SetInputArg(5,Common.m_OcParam.OcVerify[nPos].Limit.y);
        SetInputArg(6,Common.m_OcParam.OcVerify[nPos].Limit.Lv);
      end;
    end;
    ReturnOutputArg(nRet);
  end;
end;

procedure TScrCls.GetOffSetTable_Proc(AMachine: TatVirtualMachine);
var
  nIdx : Integer;
begin
  with AMachine do begin
    nIdx := GetInputArgAsInteger(0);
    if nIdx < 20 then begin
      SetInputArg(1,Common.m_OffsetTable[nIdx].R);
      SetInputArg(2,Common.m_OffsetTable[nIdx].G);
      SetInputArg(3,Common.m_OffsetTable[nIdx].B);
    end
    else if nIdx < 30 then begin
      SetInputArg(1,Common.m_OffsetTable[nIdx].OffSet);
      SetInputArg(2,Common.m_OffsetTable[nIdx].OffSet);
      SetInputArg(3,Common.m_OffsetTable[nIdx].OffSet);
    end;
  end;
end;

procedure TScrCls.GetPatName_Proc(AMachine: TatVirtualMachine);
var
  nPatNum : Integer;
begin
  with AMachine do begin
    nPatNum := GetInputArgAsInteger(0);
    SetInputArg(1,String(Self.GetPatGrp.PatName[nPatNum]));
  end;
end;

procedure TScrCls.GetPlcInfo_Proc(AMachine: TatVirtualMachine);
var
  nGet : Integer;
begin
  with AMachine do begin
//    wdRet := WAIT_FAILED;
    nGet := GetInputArgAsInteger(0);
    case nGet of
      1 : begin
      end;
    end;

  end;
end;

procedure TScrCls.GetSummaryLogData_Froc(AMachine: TatVirtualMachine);
var
SummaryLogData,sParameter : string;
begin
  with AMachine do begin
    SummaryLogData := '';
    sParameter := GetInputArgAsString(0);
    SummaryLogData := CSharpDll.MainOC_GetSummaryLogData(Self.FPgNo,sParameter);
    if SummaryLogData <> '' then begin
      ReturnOutputArg(SummaryLogData);
    end
    else ReturnOutputArg('');
  end;

end;

procedure TScrCls.GPIOSet_Proc(AMachine: TatVirtualMachine);
var
  nSet, nSelect, nWait : Integer;
  wdRet   : Integer; //DWORD;
begin
  with AMachine do begin
//    wdRet := WAIT_FAILED;
    nSet := GetInputArgAsInteger(0);
    nSelect := GetInputArgAsInteger(1);
    nWait := 3000;
    if InputArgCount = 3 then nWait := GetInputArgAsInteger(2);
//    wdRet := Pg[FPgNo].SendGPIOSet(nSet, nSelect, nWait);

    ReturnOutputArg(wdRet);
  end;
end;
{UINT8 Line_Select
UINT8 Add_Size
UINT8 I2C_Type
UINT8 Device_Add
UINT8 MSB Register_Add
UINT8 LSB Register_Add
UINT16 Length}

procedure TScrCls.I2CRead_Proc(AMachine: TatVirtualMachine);
var
  nDevAddr, nRegAddr, nDataCnt : Integer;
  getV : Variant;  //var
  bDataLog : Boolean;
  nWaitMS, nRetry : Integer;
  //
  arRData : TIdBytes;
  //
  wdRet   : DWORD;
  sDebug  : string;
  i       : Integer;
begin
  With AMachine do begin
    wdRet := WAIT_FAILED;
    // Get Param ---------------------------------------------------------------
    if InputArgCount < 4 then begin
      ReturnOutputArg(wdRet);
      Exit;
    end;
    nDevAddr     := GetInputArgAsInteger(0);  // arg[0:M] nDevAddr: Integer
    nRegAddr     := GetInputArgAsInteger(1);  // arg[1:M] nRegAddr: Integer
    nDataCnt     := GetInputArgAsInteger(2);  // arg[2:M] nDataCnt: Integer
    getV         := GetInputArg(3);           // arg[3:M] getV:Variant
    if InputArgCount >= 5 then bDataLog := GetInputArgAsBoolean(4)  // arg[5:O] bDataLog: Boolean (default: False)
    else                       bDataLog := False;
    if InputArgCount >= 6 then nWaitMS  := GetInputArgAsInteger(5)*1000  // arg[6:O] nWaitSec: Integer   //TBD?Sec?MS?
    else                       nWaitMS  := 3*1000; //TBD:AF9? I2CCMD_WAIT_TIMESEC;
    if InputArgCount >= 7 then nRetry   := GetInputArgAsInteger(6)  // arg[7:O] nRetry: Integer (default:1:NoRetry)
    else                       nRetry   := 1;
    if nRetry = 0 then nRetry := 1;
    //
//    sDebug := Format('I2C READ: DevAddr(0x%0.2x) RegAddr(0x%0.4x) DataCnt(%d), WaitMS(%d) Retry(%d) ',[nDevAddr,nRegAddr,nDataCnt, nWaitMS,nRetry]);
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug,'',DefCommon.LOG_TYPE_INFO);

    SetLength(arRData,nDataCnt);
    wdRet := Pg[Self.FPgNo].SendI2CRead(nDevAddr,nRegAddr,nDataCnt,arRData, nWaitMS,nRetry);
    case wdRet of
      WAIT_OBJECT_0: begin
        sDebug := 'I2C READ: RX:DATA:';
      //for i := 0 to Pred(Pg[Self.FPgNo].FPgTxRxData.RxDataLen) do begin
        for i := 0 to Pred(nDataCnt) do begin
        //getV[i] := Pg[FPgNo].FPgTxRxData.RxData[i];
        //sDebug := sDebug + Format(' 0x%0.2x',[Pg[Self.FPgNo].FPgTxRxData.RxData[i]]);
          getV[i] := arRData[i];
          sDebug := sDebug + Format(' 0x%0.2x',[arRData[i]]);
        end;
        SetInputArg(3,getV);
      end;
      WAIT_TIMEOUT: sDebug := 'I2C READ NG (Timeout)';
      WAIT_FAILED : sDebug := 'I2C READ NG (Failed)';
      else          sDebug := 'I2C READ NG (Etc)';
    end;
//    SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug,'', TernaryOp((wdRet=WAIT_OBJECT_0),DefCommon.LOG_TYPE_OK,DefCommon.LOG_TYPE_NG));
//    ReturnOutputArg(wdRet);
  end;
end;
//
//procedure TScrCls.I2CRead_Proc(AMachine: TatVirtualMachine);
//var
//  wdRet : Integer;
//  nWait, nLen : Integer;
//  getV : Variant;
//  i : Integer;
//  revStr, sDebug : String;
//  lstTemp : TStringList;
//  buff : TIdBytes;
//  nDataType : Integer;
//  nTemp : Integer;
//begin
//  With AMachine do begin
//    // Default 2개 이상 받아야 함.
//    wdRet := WAIT_FAILED;
//    if InputArgCount > 1 then begin
//
//      nWait := 3000; // 3 sec waitting.
//      revStr := Trim(GetInputArgAsString(0));
//      getV := GetInputArg(1);
//      if InputArgCount = 4 then nWait := GetInputArgAsInteger(3);
//      StringReplace(revStr, '0x', '$', [rfReplaceAll]);
//      lstTemp := TStringList.Create;
//      sDebug := '';
//      try
//        ExtractStrings([' '], [], PWideChar(revStr), lstTemp);
//        nLen :=  lstTemp.Count;
//        SetLength(buff, nLen);
//        for i := 0 to Pred(nLen) do begin
//
//          buff[i] := Byte(StrToIntDef(lstTemp[i],0));
//          sDebug := sDebug  + Format(' %0.2x',[buff[i]]);
//        end;
//      finally
//        lstTemp.Free;
//      end;
//      sDebug := 'Send Cmd : ' + sDebug;
////      Common.MLog(self.FPgNo,sDebug);
//      wdRet := Pg[Self.FPgNo].SendI2CRead(buff,nLen, nWait);
////      sDebug := Format('Read I2C_Data : Ret(%0.2x), Len - %d',[wdRet,Pg[FPgNo].FRxData.DataLen]);
////      Common.MLog(self.FPgNo,sDebug);
//      if wdRet = WAIT_OBJECT_0 then begin
//        nDataType := GetInputArgAsInteger(2);
////        nDataType := 1;
//        sDebug := 'READ DATA : ';
//        // Byte 수 지정해서 Variant에 저장하기
//        case nDataType of
//          1 : begin
//            for i := 0 to Pred(Pg[FPgNo].FRxData.DataLen) do begin
//              getV[i] := Pg[FPgNo].FRxData.Data[i];
//              sDebug := sDebug + Format(' %0.2x',[Pg[FPgNo].FRxData.Data[i]]);
//            end;
//          end;
//          2,4 : begin
//            for i := 0 to Pred(Pg[FPgNo].FRxData.DataLen div nDataType) do begin
//              nTemp := 0;
//              CopyMemory(@nTemp, @Pg[FPgNo].FRxData.Data[i*nDataType], nDataType);
//              getV[i] := nTemp;
//              sDebug := sDebug + Format(' %0.2x',[Pg[FPgNo].FRxData.Data[i]]);
//            end;
//          end;
//          else begin
//            for i := 0 to Pred(Pg[FPgNo].FRxData.DataLen) do begin
//              getV[i] := Pg[FPgNo].FRxData.Data[i];
//              sDebug := sDebug + Format(' %0.2x',[Pg[FPgNo].FRxData.Data[i]]);
//            end;
//          end;
//        end;
////        Common.MLog(self.FPgNo,sDebug);
//        SetInputArg(1,getV);
//      end
//      else begin
//        Common.MLog(self.FPgNo,'wdRet <> WAIT_OBJECT_0');
//      end;
//    end;
//    ReturnOutputArg(wdRet);
//  end;
//end;


procedure TScrCls.I2CWrite_Proc(AMachine: TatVirtualMachine);
var
  nSlaveType, nDevAddr, nRegAddr,nWriteData : Integer;
  sWriteData : string;
  bDataLog : Boolean;
  nWaitSec, nRetry : Integer;
  //
  wdRet      : DWORD;
  sDebug, sTxData : string;
  lstTemp    : TStringList;
  arrData    : TIdBytes;  //TBD? array of Integer?
  nDataCnt, nTemp, i : Integer;
begin
  With AMachine do begin
    wdRet := WAIT_FAILED;
    // Get Param ---------------------------------------------------------------
    if InputArgCount < 2 then begin
      ReturnOutputArg(wdRet);
      Exit;
    end;
    nRegAddr   := GetInputArgAsInteger(0);      // arg[0:M] nRegAddr: Integer
    nWriteData   := GetInputArgAsInteger(1);      // arg[1:M] sWriteData: Integer

    nWaitSec := 200; //2023-04-08 (3000->100->200)
    nRetry  := 0;   //2023-04-08 (0->3->0)
    nDataCnt := 1;
    SetLength(arRData,nDataCnt);
    sTxData := format('0x%0.2x',[nWriteData]);
    arrData[0] := nWriteData;
    bDataLog := True;
//    sDebug := Format('I2C WRITE: RegAddr(0x%0.4x) DataCnt(%d), Data(0x%0.4x) WaitMS(%d) Retry(%d) ',[nRegAddr,nDataCnt,nWriteData, nWaitSec,nRetry]);
//    if bDataLog then SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug,'',DefCommon.LOG_TYPE_INFO)
//    else             Common.MLog(FPgNo,sDebug);
//{$IFNDEF SIMULATOR_PANEL}
    wdRet := Pg[Self.FPgNo].SendI2CWrite(TCON_REG_DEVICE,nRegAddr,nDataCnt,arrData, nWaitSec,nRetry);
//{$ELSE}
//  wdRet := WAIT_OBJECT_0;
//{$ENDIF}
    case wdRet of
      WAIT_OBJECT_0: begin
        sDebug := 'I2C WRITE: TX:DATA: ' + sTxData;
      end;
      WAIT_TIMEOUT: sDebug := 'I2C WRITE NG (Timeout)';
      WAIT_FAILED : sDebug := 'I2C WRITE NG (Failed)';
      else          sDebug := 'I2C WRITE NG (Etc)';
    end;
//    if bDataLog then SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug,'',TernaryOp((wdRet=WAIT_OBJECT_0),DefCommon.LOG_TYPE_OK,DefCommon.LOG_TYPE_NG))
//    else             Common.MLog(FPgNo,sDebug);
    ReturnOutputArg(wdRet);
  end;
end;
//
//procedure TScrCls.I2CWrite_Proc(AMachine: TatVirtualMachine);
//var
//  wdRet : Integer;
//  nWait, nLen : Integer;
//  i : Integer;
//  revStr : String;
//  lstTemp : TStringList;
//  buff : TIdBytes;
//begin
//  With AMachine do begin
//// Default 1개 이상 받아야 함.
//    wdRet := WAIT_FAILED;
//    if InputArgCount > 0 then begin
//
//      nWait := 3000; // 3 sec waitting.
//      revStr := Trim(GetInputArgAsString(0));
//      if InputArgCount = 2 then nWait := GetInputArgAsInteger(1);
//      //revStr := StringReplace(revStr, '0x', '$', [rfReplaceAll]);
//      lstTemp := TStringList.Create;
//      try
//        ExtractStrings([' '], [], PChar(revStr), lstTemp);
//        nLen := lstTemp.Count;
//        SetLength(buff, nLen);
//        for i := 0 to Pred(nLen) do begin
//          buff[i] := StrToIntDef(lstTemp[i],0);
//        end;
//      finally
//        lstTemp.Free;
//      end;
//      wdRet := Pg[Self.FPgNo].SendI2CWrite(buff,nLen, nWait);
//
////      if wdRet = WAIT_OBJECT_0 then begin
////        for i := 0 to Pred(Pg[FPgNo].FRxData.DataLen) do begin
////          // byte로 데이터 입력 받음.
////          getV[i] := Pg[FPgNo].FRxData.Data[i];
////        end;
////        SetInputArg(1,getV);
////      end;
//    end;
//    ReturnOutputArg(wdRet);
//  end;
//end;

procedure TScrCls.InitialData;
var
  i : Integer;
  sPgVer, sSwVer, sDebug : string;
begin
  //FillChar(TestInfo,SizeOf(TestInfo),0); // 초기화.
  FillChar(m_TouchInfo,SizeOf(m_TouchInfo),0); // 초기화.

  if FormatDateTime('YYYY-MM-DD', m_dtInitialData) <> FormatDateTime('YYYY-MM-DD', Now) then begin
    //날짜가 변경될 경우 기록 초기화
    TestInfo.OKCount:= 0;
    TestInfo.NGCount:= 0;
  end;
  m_dtInitialData:= Now;
  m_sMateriID := '';
  m_sMesPchkModel     := '';
  g_bIsBcrReady       := False;
  m_nNgCode           := 0; // Ã³À½¿¡´Â Ç×»ó OK·Î ¼³Á¤ ÇÏÀÚ.
  m_bCEL_Stop := False;
  // Initialize MES Buffer.
  if DongaGmes <> nil then begin
    DongaGmes.MesData[Self.FPgNo].Rwk := '';
    DongaGmes.MesData[Self.FPgNo].LotNo := '';;
    DongaGmes.MesData[Self.FPgNo].Pf := '';
    DongaGmes.MesData[Self.FPgNo].DefectPat := '';
    DongaGmes.MesData[Self.FPgNo].MesPendingMsg := DefGmes.MES_UNKNOWN;
    DongaGmes.MesData[Self.FPgNo].MesSentMsg    := DefGmes.MES_UNKNOWN;
    DongaGmes.MesData[Self.FPgNo].MesSendRcvWaitTick := DefGmes.MES_UNKNOWN;
    DongaGmes.MesData[Self.FPgNo].CarrierId  := '';
    DongaGmes.MesData[Self.FPgNo].PchkSendNg := False;
    DongaGmes.MesData[Self.FPgNo].bPCHK       := False;
    DongaGmes.MesData[Self.FPgNo].bLPIR       := False;
    DongaGmes.MesData[Self.FPgNo].PchkRtnCode := '';
    DongaGmes.MesData[Self.FPgNo].PchkRtnPID  := '';
    DongaGmes.MesData[Self.FPgNo].PchkRtnZig_ID  := '';
    DongaGmes.MesData[Self.FPgNo].PchkRtnSerialNo := '';
    DongaGmes.MesData[Self.FPgNo].Model       := '';
    DongaGmes.MesData[Self.FPgNo].EicrRtnCode := '';
    DongaGmes.MesData[Self.FPgNo].ApdrRtnCode := '';
    DongaGmes.MesData[Self.FPgNo].ApdrData    := '';
    DongaGmes.MesData[Self.FPgNo].ApdrRtnSerialNo := '';
  end;
  sDebug := '[INSPECTION START] Test Model : ' + ' ------------------------------------------------- ' ;
  sDebug := sDebug +Common.SystemInfo.TestModel+' ------------------------------------------------- ';
//  Common.MLog(FPgNo,sDebug);
  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug);
  // Version for MLog.
//  sPgVer := Trim(Copy(PG[FPgNo].m_PgVer,2,4));
//  sPgVer := sPgVer + '/' + Trim(Copy(PG[FPgNo].m_sFwVer,7,4));
//  sPgVer := sPgVer + '/' + Trim(Copy(PG[FPgNo].m_sFwVer,12,4));
//  sPgVer := sPgVer + '/' + Trim(Copy(PG[FPgNo].m_sFwVer,17,4));
  sPgVer := Trim(PG[FPgNo].m_PgVer.VerAll);
  sDebug := Format('Version Check : FW(%s), SW(%s)',[sPgVer,Common.GetVersionDate]);
  sDebug := sDebug + Format(', Psu(%s/%s), MES_CODE(%s)',[Common.m_Ver.psu_Date,Common.m_Ver.psu_Crc, Common.m_Ver.MES_CSV]);
  sDebug := sDebug + Format(', OC_ConverterDLL (%s),LGD DLL (%s)',[Common.SystemInfo.OC_Converter_Name,Common.SystemInfo.LGD_DLLVER_Name]);
  //sDebug := sDebug + Format(', Psu(%s/%s), Oc_Param(%s)',[Common.m_Ver.psu_Date,Common.m_Ver.psu_Crc,Common.m_Ver.OcParam]);
  //sDebug := sDebug + Format(', Oc_Verify(%s), Otp_Table(%s)',[Common.m_Ver.OcVerify,Common.m_Ver.OtpTable]);
  //sDebug := sDebug + Format(', Oc_Offset(%s), MES_CODE(%s)',[Common.m_Ver.OcOffSet,Common.m_Ver.MES_CSV]);
//  Common.MLog(FPgNo,sDebug);

  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug);

  sDebug := Format('PGSetting Check : PG_TconWriteLogDisplay(%s), PG_TconWriteCmdType(%d), PG_TconReadCmdType(%d)',[BoolToStr(Common.SystemInfo.PG_TconWriteLogDisplay,True),Common.SystemInfo.PG_TconWriteCmdType,Common.SystemInfo.PG_TconReadCmdType]);
  sDebug := sDebug + Format(', PG_TconOcWriteDelayMsec(%d), PG_TconOcWriteDelayMicroSec(%d)',[Common.SystemInfo.PG_TconOcWriteDelayMsec,Common.SystemInfo.PG_TconOcWriteDelayMicroSec]);
  sDebug := sDebug + Format(', PGResetTotalConut(%d), PGResetDelayTime(%d)',[Common.SystemInfo.PGResetTotalConut,Common.SystemInfo.PGResetDelayTime]);

//  Common.MLog(FPgNo,sDebug);
  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug);

  TestInfo.SW_Ver:= Common.ExeVersion; // Common.GetVersionDate;
  TestInfo.PG_Ver:= sPgVer;
  TestInfo.DLL_Ver := Common.DLLVersion;
  TestInfo.Model:= Common.SystemInfo.TestModel;
  TestInfo.ModelConfig:= Common.GetModelConfig(TestInfo.Model);
  TestInfo.EQPId:= Common.SystemInfo.EQPId;
  TestInfo.Ch:= FPgNo;
  TestInfo.UserID:= Common.m_sUserId;
  TestInfo.AutoMode:= Common.StatusInfo.AutoMode;
  TestInfo.AABMode:= Common.StatusInfo.AABMode;
  TestInfo.Login:= Common.StatusInfo.LogIn;
  TestInfo.Use_ECS:= Common.SystemInfo.Use_ECS;
  TestInfo.Use_MES:= Common.SystemInfo.Use_MES;
  TestInfo.Use_DFS:= Common.DfsConfInfo.bUseDfs;
  TestInfo.Use_GIB:= Common.SystemInfo.Use_GIB;
  TestInfo.Use_FFCData:= Common.SystemInfo.CAM_FFCData;
  TestInfo.Use_StainData:= Common.SystemInfo.CAM_StainData;
  TestInfo.Use_FTPUpload:= Common.SystemInfo.CAM_FTPUpload;
  TestInfo.Use_TemplateData:= Common.SystemInfo.CAM_TemplateData;
  TestInfo.ZAxis_Current:= Common.m_nCurPosZAxis;
  TestInfo.SIM_Use_PG:= Common.SimulateInfo.Use_PG;
  TestInfo.SIM_Use_DIO:= Common.SimulateInfo.Use_DIO;
  TestInfo.SIM_Use_PLC:= Common.SimulateInfo.Use_PLC;
  TestInfo.SIM_Use_CAM:= Common.SimulateInfo.Use_CAM;
  TestInfo.OC_Con_Ver := Common.SystemInfo.OC_Converter_Name;
  TestInfo.DLL_Ver := Common.SystemInfo.LGD_DLLVER_Name;

  TestInfo.Result := '';
  TestInfo.csvHeader := '';
  TestInfo.csvData   := '';
  TestInfo.CarrierId:= '';
  TestInfo.RTN_PID:= '';
  TestInfo.LCM_ID:= '';
  TestInfo.MateriID := '';   // Added by KTS 2023-06-01 오전 7:35:35
  TestInfo.ApdrData := '';
  TestInfo.PowerOn   := False;
  TestInfo.CanSendApdr := False;
  TestInfo.NG_EICR:= False;
  TestInfo.NGAlarmCount:= Common.SystemInfo.NGAlarmCount;
  TestInfo.RetryCount:= Common.SystemInfo.RetryCount;
  TestInfo.AlarmNGCode:= 0;
  TestInfo.PreEndTime:= TestInfo.EndTime; //완공시간을 이전 완공시간으로 설정
  TestInfo.Log_WritePOCB:= Common.SystemInfo.MIPILog;
  TestInfo.RetryValue:= 0;
  TestInfo.Test_Repeat:= Common.SystemInfo.Test_Repeat;
  TestInfo.OCDllCall := False;
  TestInfo.PreOcReStart := False;

  TestInfo.Final_x := 0.0;
  TestInfo.Final_y := 0.0;
  TestInfo.Final_Lv := 0.0;

  if g_CommPLC <> nil then  begin
    TestInfo.CarrierId:= g_CommPLC.GlassData[FPgNo].CarrierID; //GlassData에서 CarrierID를 LOT_ID에 설정
    TestInfo.RTN_PID:= Trim(g_CommPLC.GlassData[FPgNo].GlassID);
    TestInfo.LCM_ID:= g_CommPLC.GlassData[FPgNo].LCM_ID;
    TestInfo.MateriID := g_CommPLC.GlassData[FPgNo].MateriID;
  end;

  // BCR Set.
  if Common.SystemInfo.OcManualType then begin
    SendTestGuiDisplay(DefCommon.MSG_MODE_BARCODE_READY,'','',0);

    if (UpperCase(Common.m_sUserId) = 'PM') then begin
      g_bIsBcrReady := True;
    end;
  end;
end;

procedure TScrCls.InitialScript;
begin
  try
    ScriptThread('Seq_Init',0);
  except
    on E:Exception do begin
      SendTestGuiDisplay(defCommon.MSG_MODE_CH_RESULT,'SCRIPT Initialize NG','',1); // 0: OK, 1 : NG.
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,E.Message,'',1);
    end;
  end;
end;

procedure TScrCls.InsertDataToFile(sInputData: string; var nCnt: Integer; var sData: TStringList);
begin
  sData.Insert(nCnt,sInputData);
  Inc(nCnt);
end;

procedure TScrCls.IonizerOn_Proc(AMachine: TatVirtualMachine);
var
  nRet, i, nOn : Integer;
  nPair : integer;
  nCh : integer;
begin
  nRet := 1; // Fail.
  with AMachine do begin
    if InputArgCount in [1,2] then begin
      nOn := GetInputArgAsInteger(0);
      nCh := GetInputArgAsInteger(1);
      if nOn = 0 then begin
        for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
          if Common.SystemInfo.Com_Ionizer[i] = 0 then Continue;
          if not ((Common.SystemInfo.IonizerCnt-1) < i) then begin
            DaeIonizer[nCh].SendStop;
          end;
        end;
      end
      else begin
        for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
          if Common.SystemInfo.Com_Ionizer[i] = 0 then Continue;
          if not ((Common.SystemInfo.IonizerCnt-1) < i) then begin
            DaeIonizer[nCh].Sendrun;
          end;
        end;
      end;
      nRet := 0;
    end;
    ReturnOutputArg(nRet);
  end;
end;

function TScrCls.IsScriptRun: boolean;
begin
  Result :=  atPasScrpt.Running;
end;

procedure TScrCls.Convert_VariantToAscii_Proc(AMachine: TatVirtualMachine);
var
  i, nLen : Integer;
  nStart, nEnd: Integer;
  sValue: String;
  vData : Variant;
  nByte: Byte;
begin
  With AMachine do begin
    if InputArgCount in [5] then begin
      vData := GetInputArg(0);
      nStart:= GetInputArgAsInteger(1);
      nEnd:= GetInputArgAsInteger(2);

      sValue:= '';
      try
        nLen:= VarArrayHighBound(vData, 1); //Variants의 크기

        for i:=nStart to nEnd do begin
          if i >= nLen then break;
          nByte:= vData[i];
          sValue := sValue + Chr(nByte);
        end;
      except
        on E: Exception do begin
//          Common.MLog(self.FPgNo, 'Runtime Error Convert_VariantToAscii: ' + E.Message);
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'Runtime Error Convert_VariantToAscii: ' + E.Message);
        end;
      end;
    end;

    ReturnOutputArg(sValue);
  end;
end;

procedure TScrCls.Convert_VariantToHex_Proc(AMachine: TatVirtualMachine);
var
  i, nLen : Integer;
  nStart, nEnd: Integer;
  sPrefix, sDelimiter: String;
  sValue: String;
  vData : Variant;
begin
  With AMachine do begin
    if InputArgCount in [5] then begin
      vData := GetInputArg(0);
      nStart:= GetInputArgAsInteger(1);
      nEnd:= GetInputArgAsInteger(2);
      sPrefix:= GetInputArgAsString(3);
      sDelimiter:= GetInputArgAsString(4);

      sValue:= '';
      try
        nLen:= VarArrayHighBound(vData, 1); //Variants의 크기

        for i:=nStart to nEnd do begin
          if i >= nLen then break;
          sValue := sValue + sPreFix + IntToHex(vData[i], 2) + sDelimiter;
        end;
      except
        on E: Exception do begin
//          Common.MLog(self.FPgNo, 'Runtime Error Convert_VariantToHex: ' + E.Message);
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'Runtime Error Convert_VariantToAscii: ' + E.Message);
        end;
      end;
    end;

    ReturnOutputArg(sValue);
  end;
end;

// Mode :  0 (Test Mode), 1 (Pocb Mode)
// Size , Buffer.
procedure TScrCls.LoadFileData_Proc(AMachine: TatVirtualMachine);
var
  nRet, nMode, nSize : Integer;
  sFileName : string;
  txBuf  : array of Byte;
  Stream: TMemoryStream;
  getV : Variant;
  i: Integer;
begin
  nRet := -1;
  With AMachine do begin

    if InputArgCount in [3,4] then begin
      nMode := GetInputArgAsInteger(0);
      getV := GetInputArgAsVariant(2);

      sFileName := '';
      if InputArgCount = 4 then sFileName := GetInputArgAsString(3);
      if nMode = 0 then begin
        if FileExists(sFileName) then begin
          Stream := TMemoryStream.Create;
          try
            Stream.LoadFromFile(sFileName);
            nSize := Stream.Size;
            SetLength(txBuf,nSize);
            CopyMemory(@txBuf[0],Stream.Memory,nSize);
            for i := 0 to Pred(nSize) do begin
              getV[i] := txBuf[i];
            end;
          finally
            Stream.Free;
          end;
          nRet := 0;
        end;
      end;
      SetInputArg(1,nSize);
      SetInputArg(2,getV);
    end;
    ReturnOutputArg( nRet);

  end;
end;

procedure TScrCls.LoadPassRgbAvr_Proc(AMachine: TatVirtualMachine);
begin
  With AMachine do begin
		Case InputArgCount of
      5 : begin
        m_RgbAvrInfo.AvrType  := GetInputArgAsInteger(0);
        m_RgbAvrInfo.AvrCnt   := GetInputArgAsInteger(1);
        m_RgbAvrInfo.BandCnt  := GetInputArgAsInteger(2);
        m_RgbAvrInfo.GrayStep := GetInputArgAsInteger(3);
        m_RgbAvrInfo.Option1  := GetInputArgAsInteger(4);
        SendTestGuiDisplay(defCommon.MSG_MODE_GET_AVG_RGB);
      end;
    End;
  end;
end;

procedure TScrCls.LoadSource(stData: TStrings);
begin
  try
    atPasScrpt.SourceCode.Clear;
    atPasScrpt.SourceCode.AddStrings(stData);// := stData;
    // Define Method.
    DefineMethodFunc(atPasScrpt);
    atPasScrpt.Compile;
  except
    on E:Exception do begin
      SendTestGuiDisplay(defCommon.MSG_MODE_CH_RESULT,'SCRIPT LOAD NG','',-2); // 0: OK, 1 : NG.
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,E.Message,'',1);
    end;
  end;
end;

procedure TScrCls.LogM_Proc(AMachine: TatVirtualMachine);
var
  nOption : Integer;
begin
  With AMachine do begin
		Case InputArgCount of
      1..2 : begin
//        Common.MLog(Self.FPgNo,GetInputArgAsString(0));
        if InputArgCount = 1 then nOption := 0
        else begin
          nOption := GetInputArgAsInteger(1);
        end;

        if m_bToMaint then SendDisplayGuiDisplay(defCommon.MSG_MODE_WORKING, 0,GetInputArgAsString(0))
        else               SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,GetInputArgAsString(0),'',nOption);
      end;
    End;
  end;
end;

procedure TScrCls.SetCaptionName_Proc(AMachine: TatVirtualMachine);
var
  nVIRTUAL : Integer;
  sCaption : string;
begin
  With AMachine do begin
		Case InputArgCount of
      2 : begin
        nVIRTUAL := GetInputArgAsInteger(0);
        sCaption := GetInputArgAsString(1);
        SendTestGuiDisplay(DefCommon.MSG_MODE_VIRTUAL_CAPTION,sCaption,'',nVIRTUAL);
      end;
    End;
  end;
end;

procedure TScrCls.LogRePGM_NG_Proc(AMachine: TatVirtualMachine);
var
sSN,sPID : string;
begin
  With AMachine do begin
		Case InputArgCount of
      1 : begin
        sSN := GetInputArgAsString(0);
        if DongaGmes <> nil then
          sPID :=  DongaGmes.MesData[FPgNo].PchkRtnPID
        else sPID := 'NULL';
        SendTestGuiDisplay(defCommon.MSG_MODE_LOG_REPGM,sPID,sSN,0);
      end;
    End;
  end;
end;

procedure TScrCls.LogPcd_Proc(AMachine: TatVirtualMachine);
var
  nData, nPCD : Integer;
begin
  With AMachine do begin
    nData := GetInputArgAsInteger(0);
    if nData = 0 then nPCD := 0
    else nPCD := nData div 5;

    // LGD 측 요청한 포맷
    // 공정, 검사기 번호, 검사기 채널, 검사날짜, 바코드, HEX2, OHM2
    // 수정 필요.

    TestInfo.csvHeader := Format('%s,%s,%s,%s,%s,%s,%s',['Process','EQP ID','Channel','Date','Barcode','HEX2','OHM2']);

//    TestInfo.csvData := TestInfo.csvData + Format('%s,%s',[Common.SystemInfo.ProcessName, Common.SystemInfo.EQPId]);
    TestInfo.csvData := TestInfo.csvData + Format(',CH%d,%s,%s',[FPgNo+1, FormatDateTime('YYYY-MM-DD HH:MM',now),Self.TestInfo.SerialNo]);
    TestInfo.csvData := TestInfo.csvData + Format(',%x,%x',[nData, nPCD]);

    SendMainGuiDisplay(DefCommon.MSG_MODE_LOG_CSV);
  end;
end;

procedure TScrCls.LogPwr_Proc(AMachine: TatVirtualMachine);
begin
  With AMachine do begin
    SendTestGuiDisplay(DefCommon.MSG_MODE_LOG_PWR);
  end;
end;

function TScrCls.MakeApdrData : string;
var
  sRet, sTemp, sItem : string;
  i, j : Integer;

  sPgVer, sUnitTact, sUi : string;
begin
  Result := ExecExtraFunction('MakeApdrData');
  Exit;

  {$IFDEF ISPD_POCB}
//  atPasScrptMaint.SourceCode.Clear;
//  atPasScrptMaint.SourceCode.AddStrings(atPasScrpt.SourceCode);
//  atPasScrptMaint.Compile;
//  sRet:= ExecFunction(atPasScrptMaint, 'MakeApdrData');

(*
  sRet := 'POCB_RESULT:CARRIER_ID:'+ TestInfo.CarrierId;
  sRet := sRet +  ',POCB_RESULT:CH:' + IntToStr(FPgNo+1);
  sRet := sRet +  ',POCB_RESULT:CONFIG_NAME:';
  sRet := sRet +  ',POCB_RESULT:DESCRIPTION:';
  sRet := sRet +  ',POCB_RESULT:EQP_ID:'+Common.SystemInfo.EQPId;
  sRet := sRet +  ',POCB_RESULT:HW_PG_VER:' + Pg[0].m_sFwVer;
  sRet := sRet +  ',POCB_RESULT:HW_SLOT_VER:';
  sRet := sRet +  ',POCB_RESULT:HW_VIDEO_VER:';
  sRet := sRet +  ',POCB_RESULT:LONG_DESCRIPTION:';
  sTemp := Format('%d',[SecondsBetween(TestInfo.EdUnitTact,TestInfo.StUnitTact)]);
  sRet := sRet +  ',POCB_RESULT:MEASURE_TIME:' + sTemp;
  if Trim(TestInfo.Result) <> 'PASS' then begin
    sRet := sRet +  ',POCB_RESULT:RESULT:Failed';
  end
  else begin
    sRet := sRet +  ',POCB_RESULT:RESULT:PASS';
  end;
  //sRet := sRet +  ',POCB_RESULT:FAILED_MSG:' + TestInfo.Fail_Message;
  sRet := sRet +  ',POCB_RESULT:SCRIPT_NAME:' + Common.SystemInfo.TestModel;
  sRet := sRet +  ',POCB_RESULT:SERIAL_NUMBER:'+ TestInfo.SerialNo;
  sRet := sRet +  ',POCB_RESULT:START_TIME:' + FormatDateTime('YYMMDD HHNNSS',TestInfo.StartTime);
  sRet := sRet +  ',POCB_RESULT:STOP_TIME:' + FormatDateTime('YYMMDD HHNNSS',TestInfo.EndTime);
  sTemp :=  StringReplace(Common.GetVerOnlyDate,'_','',[rfReplaceAll]);
  sRet := sRet +  ',POCB_RESULT:SW_UI_VER:' + sTemp;
  sTemp := Format('%d',[SecondsBetween(TestInfo.StartTime,TestInfo.EndTime)]);
  sRet := sRet +  ',POCB_RESULT:TACT_TIME:' + sTemp;

//  sRet := sRet +  ',POCB_RESULT:HW_SPI_VER:' + Pg[0].m_sFwVerSpi;


  sRet := sRet +  ',POCB_RESULT:USERID:'+Common.m_sUserId;
  Result := sRet;
*)
  {$ELSE}
  // SW Version.
  sUi := StringReplace(Common.GetVerOnlyDate,' ','',[rfReplaceAll]);

  // PG[nCh].m_sFwVer ==> ,P124,F409,M54D,PW21
  sPgVer := Trim(PG[FPgNo].m_PgVer.VerAll);
//  sPgVer := sPgVer + '_' + Trim(Copy(PG[FPgNo].m_sFwVer,7,4));
//  sPgVer := sPgVer + '_' + Trim(Copy(PG[FPgNo].m_sFwVer,12,4));
//  sPgVer := sPgVer + '_' + Trim(Copy(PG[FPgNo].m_sFwVer,17,4));
  // unit tact time.
  sUnitTact := Format('%d',[SecondsBetween(TestInfo.StUnitTact,TestInfo.EdUnitTact)]);

  sRet := '';
  // Data from sw.
  sRet := sRet +  'OPTIC RESULT:UI:'+sUi;
  sRet := sRet + ',OPTIC RESULT:MOD:'+trim(Common.SystemInfo.TestModel);
  sRet := sRet + ',OPTIC RESULT:FW:'+trim(sPgVer);
  sRet := sRet + ',OPTIC RESULT:TACT_TIME:'+sUnitTact;
  sRet := sRet + Format(',OPTIC RESULT:CH:%d',[FPgNo+1]);
  sRet := sRet + ',OPTIC RESULT:CARRIER ID:'+trim(TestInfo.CarrierId);
  if trim(TestInfo.Result) = 'PASS' then begin
    sRet := sRet + ',OPTIC RESULT:RESULT:OK';
  end
  else begin
    sRet := sRet + ',OPTIC RESULT:RESULT:'+trim(TestInfo.Result);
  end;

  // Data from psu file.
  for i := 0 to Pred(TestInfo.InsApdr.FColCnt-1) do begin
    if Trim(TestInfo.InsApdr.Data[1,i]) = '' then Break;
    sRet := sRet + ',';
    sItem := Trim(TestInfo.InsApdr.Data[0,i]);
    sItem := sItem + ':' + Trim(TestInfo.InsApdr.Data[1,i]);
    sItem := sItem + ':' + Trim(TestInfo.InsApdr.Data[2,i]);
    sRet  := sRet + sItem;
  end;
  Result := sRet;
  {$ENDIF}

end;

function TScrCls.MakeApdrData_EAS: string;
begin
  Result := ExecExtraFunction('MakeApdrData_EAS');
end;

procedure TScrCls.MakeCsvApdr_Proc(AMachine: TatVirtualMachine);
begin
  with Amachine do begin
    if InputArgCount = 1 then begin
      TestInfo.ApdrLogHeader   := GetInputArgAsString(0);
      SendMainGuiDisplay(DefCommon.MSG_MODE_LOG_CSV_APDR);
    end;
  end;
end;

procedure TScrCls.MakeCsvSummary_Proc(AMachine: TatVirtualMachine);
begin
  with Amachine do begin
    if InputArgCount = 2 then begin
      TestInfo.InsCsv         := VarToObject(GetInputArg(0)) as TInsCsv;
      TestInfo.CsvHeaderCnt   := GetInputArgAsInteger(1);
      SendMainGuiDisplay(DefCommon.MSG_MODE_LOG_CSV_SUMMARY);
    end;
  end;
end;

procedure TScrCls.MakeCsv_Proc(AMachine: TatVirtualMachine);

begin
  With AMachine do begin

    TestInfo.csvHeader := GetInputArgAsString(0);
    TestInfo.csvData   := GetInputArgAsString(1);

    SendMainGuiDisplay(DefCommon.MSG_MODE_LOG_CSV);
  end;
end;

procedure TScrCls.MakeOpticCsv_Proc(AMachine: TatVirtualMachine);
begin
  with Amachine do begin
    TestInfo.InsCsv         := VarToObject(GetInputArg(0)) as TInsCsv;
    SendMainGuiDisplay(DefCommon.MSG_MODE_LOG_CSV);
  end;
end;


procedure TScrCls.MakePassRGB_Proc(AMachine: TatVirtualMachine);
begin
  with Amachine do begin
    m_RgbAvrInfo.RgbPass           := VarToObject(GetInputArg(0)) as TInsRgbPass;
    SendTestGuiDisplay(DefCommon.MSG_MODE_PASS_RGB);
  end;
end;

procedure TScrCls.MakeTEndEvt(nIdxErr: Integer; sErrMessage : string);
begin
  m_nCamRet := nIdxErr;

  if nIdxErr <> 0 then begin
    m_sNgMsg := sErrMessage;
  end;
  if m_bCamEvnt then SetEvent(m_hCamEvnt);
end;

procedure TScrCls.MIPIRead_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  i, nWait, nLen : Integer;
  sSendCmd, sDebug : String;
  lstTemp : TStringList;
  buff : TIdBytes;
  getV : Variant;
begin
  With AMachine do begin
//    nWait := 3000;
//    if InputArgCount in [2,3] then begin
//      sSendCmd := Trim(GetInputArgAsString(0));
//      if Common.SystemInfo.MIPILog then Common.MLog(self.FPgNo,'[Source Code] MIPI READ CMD : '+sSendCmd);
//      getV := GetInputArg(1);
//      if InputArgCount = 3 then nWait := GetInputArgAsInteger(2);
//      //sSendCmd := StringReplace(sSendCmd, '0x', '$', [rfReplaceAll]);
//      lstTemp := TStringList.Create;
//      try
//        ExtractStrings([' '], [], PWideChar(sSendCmd), lstTemp);
//        nLen := lstTemp.Count;
//        SetLength(buff, nLen);
//        for i := 0 to Pred(nLen) do begin
//          buff[i] := StrToIntDef(lstTemp[i],0);
//        end;
//      finally
//        lstTemp.Free;
//      end;
//      wdRet := Pg[Self.FPgNo].SendMIPIRead(buff, nLen, nWait);
//      sDebug := '';
//      if wdRet = WAIT_OBJECT_0 then begin
//        nLen:= VarArrayHighBound(getV, 1); //Variants의 크기 //VarArrayDimCount(getV); //
//        for i := 0 to Pred(Pg[FPgNo].FRxData.DataLen) do begin
//          if nLen < i then  //주어진 배열보다 클경우오류 방지
//          begin
//             Common.MLog(self.FPgNo,Format('[Source Code] MIPI READ Data Oversize %d:%d' , [nLen, Pg[FPgNo].FRxData.DataLen]));
//             break;
//          end;
//          // byte로 데이터 입력 받음.
////          Common.MLog(FPgNo, 'Data' + IntToStr(i) +' : ' + IntToStr(Pg[FPgNo].FRxData.Data[i]));
//          getV[i] := Integer(Pg[FPgNo].FRxData.Data[i]);
//          sDebug := sDebug + Format(' 0x%0.2x',[Pg[FPgNo].FRxData.Data[i]]);
//        end;
//        if Common.SystemInfo.MIPILog then Common.MLog(self.FPgNo,'[Source Code] MIPI READ DATA :'+sDebug);
//      end
//      else begin
//        sDebug := Format('MIPI READ NG Code : %d - DataLength (%d)',[wdRet, Pg[FPgNo].FRxData.DataLen ]);
//        Common.MLog(self.FPgNo, sDebug);
//      end;
//
//      SetInputArg(1,getV);
//      ReturnOutputArg(wdRet);
//    end;
  end;
end;
{UINT8 DSI_Data_Type
UINT8 Address
n*UINT8 DATA[Length]}
procedure TScrCls.MIPIWrite_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  i, nWait, nLen : Integer;
  sSendCmd, sDebug : String;
  lstTemp : TStringList;
  buff : TIdBytes;
  dwRtn : DWORD;
  nFlashSize, nDataSize : DWORD;
  DataBuf : TIdBytes;
  sTemp, sFileName : string;
  //
  sFileExt : string;
  bIsHexFile : Boolean;
  mtData : TMemoryStream;
  binData : array of Byte;
begin
  With AMachine do begin
//    nWait := 3000;
//
//  try
//    sTemp := '---------- Flash ALL Write';
//    DisplayPgLog(nCh,sTemp);
//    //
//    if Length(edPgFileSend.Text) <= 0 then begin
//      sTemp := sTemp + ' ...Parameter Error(Flash All file is NOT selected) !!!';
//      DisplayPgLog(nCh,sTemp);
//      Exit;
//    end;
//
//    sFileName := Trim(edPgFileSend.Text);
//    sFileExt  := ExtractFileExt(sFileName);
//    if LowerCase(sFileExt) = '.hex'      then bIsHexFile := True
//    else if LowerCase(sFileExt) = '.bin' then bIsHexFile := False
//    else begin
//      sTemp := sTemp + ' ...Parameter Error(the selected file is NOT *.hex|*.bin) !!!';
//      DisplayPgLog(nCh,sTemp);
//      Exit;
//    end;
//    DisplayPgLog(nCh,sTemp+Format(': %s',[sFileName]));
//    //
//    nFlashSize := 8192*1024;  // 8MB
//    //
//    if bIsHexFile then begin
//      nDataSize := Common.GetHexLog(sFileName,nDataSize,@DataBuf[0]);
//    end
//    else begin
//      mtData := TMemoryStream.Create;
//      try
//        mtData.LoadFromFile(sFileName);
//        SetLength(binData,nFlashSize);
//        mtData.Position := 0;
//        mtData.Read(binData[0],mtData.Size);
//        //
//        nDataSize := mtData.Size;
//        SetLength(DataBuf,nDataSize);
//        CopyMemory(@DataBuf[0],@binData[0],Min(nFlashSize,nDataSize));
//      finally
//        mtData.Free;
//      end;
//    end;
//    if nDataSize <= 0  then begin
//      sTemp := sTemp + ' ...Error(Check Flash All hex|bin file data) !!!';
//      DisplayPgLog(nCh,sTemp);
//      Exit;
//    end;
//    if nDataSize <> nFlashSize  then begin
//      sTemp := sTemp + Format(' ...NG(DataCnt:%d, FlashSize=%d) !!!',[nDataSize,nFlashSize]);
//      DisplayPgLog(nCh,sTemp);
//      Exit;
//    end;
//    //
//   	dwRtn :=Pg[nCh].SendFlashWrite(0{nStartAddr},nDataSize, @DataBuf[0]);
//		sTemp := sTemp + TernaryOp((dwRtn = WAIT_OBJECT_0),' OK',' NG');
//    if dwRtn = WAIT_OBJECT_0 then sTemp := sTemp + Format(' [LOG/FLASH/CH%d_FlashAllWrite_A0x0_L%d.bin]',[nCh,nFlashSize]);
//    DisplayPgLog(nCh,sTemp);
//          ReturnOutputArg(wdRet);
//  finally
//  end;

  end;
end;



procedure TScrCls.MIPIWriteHS_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  i, nWait, nLen : Integer;
  sSendCmd, sDebug : String;
  lstTemp : TStringList;
  buff : TIdBytes;
begin
  With AMachine do begin
//    nWait := 3000;
//    if InputArgCount in [1,2] then begin
//      sSendCmd := Trim(GetInputArgAsString(0));
//      sDebug := sSendCmd;
//      if InputArgCount = 2 then nWait := GetInputArgAsInteger(1);
//      lstTemp := TStringList.Create;
//      try
//        ExtractStrings([' '], [], PWideChar(sSendCmd), lstTemp);
//        nLen := lstTemp.Count;
//        SetLength(buff, nLen);
//        for i := 0 to Pred(nLen) do begin
//          buff[i] := StrToIntDef(lstTemp[i],0);
//        end;
//      finally
//        lstTemp.Free;
//      end;
//      wdRet := Pg[Self.FPgNo].SendMIPIWriteHS(buff,nLen, nWait);
//      if Common.SystemInfo.MIPILog then Common.MLog(self.FPgNo,'[Source Code] MIPI WriteHS '+sDebug);
//      ReturnOutputArg(wdRet);
//    end;
  end;
end;

procedure TScrCls.MIPI_ClkBps_Proc(AMachine: TatVirtualMachine);
var
  nClk : Integer;
  wdRet : Integer;
begin
  With AMachine do begin
//    if InputArgCount = 1 then begin
//      nClk := (GetInputArgAsInteger(0));
//      wdRet := Pg[Self.FPgNo].SendMIPI_clk(nClk);
//      ReturnOutputArg(wdRet);
//    end;
  end;
end;

procedure TScrCls.MIPI_ICWrite_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  i, nWait, nLen : Integer;
  sSendCmd, sDebug : String;
  lstTemp : TStringList;
  buff : TIdBytes;
begin
  With AMachine do begin
//    nWait := 3000;
//    if InputArgCount in [1,2] then begin
//      sSendCmd := Trim(GetInputArgAsString(0));
//      sDebug := sSendCmd;
//      if InputArgCount = 2 then nWait := GetInputArgAsInteger(1);
//      //sSendCmd := StringReplace(sSendCmd, '0x', '$', [rfReplaceAll]);
//      lstTemp := TStringList.Create;
//      try
//        ExtractStrings([' '], [], PWideChar(sSendCmd), lstTemp);
//        nLen := lstTemp.Count;
//        SetLength(buff, nLen);
//        for i := 0 to Pred(nLen) do begin
//          buff[i] := StrToIntDef(lstTemp[i],0);
//        end;
//      finally
//        lstTemp.Free;
//      end;
//      wdRet := Pg[Self.FPgNo].SendMIPI_ICWrite(buff,nLen, nWait);
//      if Common.SystemInfo.MIPILog then Common.MLog(self.FPgNo,'[Source Code] MIPI IC Write '+sDebug);
//      ReturnOutputArg(wdRet);
//    end;
  end;
end;

procedure TScrCls.NextStep_Proc(AMachine: TatVirtualMachine);
var
  nParam, nParam2, nParam3 : Integer;
begin
  With AMachine do begin
		Case InputArgCount of
      3 : begin
        nParam  :=  GetInputArgAsInteger(0);
        nParam2 :=  GetInputArgAsInteger(1);
        nParam3 :=  GetInputArgAsInteger(2);
        if nParam = -1 then begin
          ResetScriptStatus;
        end
        else begin
          SeqStatus[nParam].Status := TSeqStatus(nParam2);
          SeqStatus[nParam].Process := TSeqProcess(nParam3);
        end;

      end;
    End;
  end;
end;

procedure TScrCls.NVMVerify_Froc(AMachine: TatVirtualMachine);
var
sTemp : string;
nDataLen,nDataSize : Integer;
dwRtn : DWORD;
bOK : Boolean;
sCrcData : AnsiString;
dReadCheckSum,dFileCheckSum,i : DWORD;
sDirectory,sFileSend,sFileName,sFileExt : string;
bIsHexFile : Boolean;
  DataBuf : TIdBytes;
  mtData : TMemoryStream;
  binData : array of Byte;
begin
  With AMachine do begin
    try
      if Common.TestModelInfoFLOW.UseCkNVMWriteSequence = 0 then begin
//        Common.MLog(self.FPgNo, 'NVM Verify Sequence - SKIP');
        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING, 'NVM Verify Sequence - SKIP');
        dwRtn := 0;
        Exit;
      end;

      sTemp := '---------- Flash ALL Verify';
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
      nDataLen := 8192*1024;
      dwRtn := Pg[FPgNo].SendFlashRead(0{nStartAddr},nDataLen,@Logic[FPgNo].m_FlashAllData.Data[0]);
      sCrcData := '';
      for i := 0 to Pred(nDataLen) do begin
        sCrcData := sCrcData + AnsiChar(Logic[FPgNo].m_FlashAllData.Data[i]);
      end;
      dReadCheckSum := Common.crc16(sCrcData,nDataLen);
      sTemp := Format('Flash ALL Read dCheckSum : 0x%.2X ',[dReadCheckSum]);
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);

      sDirectory := Common.Path.LGDPara + Common.TestModelInfoFLOW.ModelTypeName + '\Default.bin';
      if not FileExists(sDirectory) then begin
        Exit;
      end;
      sFileSend := sDirectory;

      sTemp := '---------- Bin File ALL Verify';
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
      //
      if Length(sFileSend) <= 0 then begin
        sTemp := sTemp + ' ...Parameter Error(Flash All file is NOT selected) !!!';
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;

      sFileName := Trim(sFileSend);
      sFileExt  := ExtractFileExt(sFileName);
      if LowerCase(sFileExt) = '.hex'      then bIsHexFile := True
      else if LowerCase(sFileExt) = '.bin' then bIsHexFile := False
      else begin
        sTemp := sTemp + ' ...Parameter Error(the selected file is NOT *.hex|*.bin) !!!';
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp+Format(': %s',[sFileName]),'',0);

      //
      if bIsHexFile then begin
        nDataSize := Common.GetHexLog(sFileName,nDataSize,@DataBuf[0]);
      end
      else begin
        mtData := TMemoryStream.Create;
        try
          mtData.LoadFromFile(sFileName);
          SetLength(binData,nDataLen);
          mtData.Position := 0;
          mtData.Read(binData[0],mtData.Size);
          //
          nDataSize := mtData.Size;
          SetLength(DataBuf,nDataSize);
          CopyMemory(@DataBuf[0],@binData[0],Min(nDataLen,nDataSize));
        finally
          mtData.Free;
        end;
      end;
      if nDataSize <= 0  then begin
        sTemp := sTemp + ' ...Error(Check Flash All hex|bin file data) !!!';
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;
      if nDataSize <> nDataLen  then begin
        sTemp := sTemp + Format(' ...NG(DataCnt:%d, FlashSize=%d) !!!',[nDataSize,nDataLen]);
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;

      for i := 0 to Pred(nDataLen) do begin
        sCrcData := sCrcData + AnsiChar(DataBuf[i]);
      end;
      dFileCheckSum := Common.crc16(sCrcData,nDataLen);

      sTemp := Format('Bin File Read dCheckSum : 0x%.2X ',[dFileCheckSum]);
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);


      if dReadCheckSum = dFileCheckSum then
        dwRtn := 0
      else dwRtn := 1;
    finally
      ReturnOutputArg(Integer(dwRtn));
    end;

  end;
end;

procedure TScrCls.NVMRead_Froc(AMachine: TatVirtualMachine);
var
sTemp : string;
nDataLen : Integer;
dwRtn : DWORD;
bOK : Boolean;
sCrcData : AnsiString;
dCheckSum,i : DWORD;
begin
  With AMachine do begin
    sTemp := '---------- Flash ALL Read';
    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
    nDataLen := 8192*1024;
    dwRtn := Pg[FPgNo].SendFlashRead(0{nStartAddr},nDataLen,@Logic[FPgNo].m_FlashAllData.Data[0]);
    sCrcData := '';
    for i := 0 to Pred(nDataLen) do begin
      sCrcData := sCrcData + AnsiChar(Logic[FPgNo].m_FlashAllData.Data[i]);
    end;
    dCheckSum := Common.crc16(sCrcData,nDataLen);
    sTemp := Format('Flash ALL Read dCheckSum : 0x%.2X ',[dCheckSum]);
    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
    sTemp := sTemp + TernaryOp((dwRtn = WAIT_OBJECT_0),' OK',' NG');
    if bOK then sTemp := sTemp + Format(' [LOG/FLASH/CH%d_FlashPucDataRead_A0x0_L%d.hex]',[FPgNo,nDataLen]);
    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
  end;
end;

procedure TScrCls.NVMWrite_Froc(AMachine: TatVirtualMachine);
var

  sFileSend,sTemp,sFileName,sFileExt,sDirectory : string;
  bIsHexFile : Boolean;
  dwRtn : DWORD;
  nFlashSize, nDataSize : DWORD;
  DataBuf : TIdBytes;
  mtData : TMemoryStream;
  binData : array of Byte;
  wdRet : integer;
begin
  With AMachine do begin
    try
      dwRtn := 1;
//      if Common.TestModelInfoFLOW.UseCkNVMWriteSequence = 0 then begin
////        Common.MLog(self.FPgNo, 'NVM Write Sequence - SKIP');
//        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING, 'NVM Write Sequence - SKIP');
//        dwRtn := 0;
//        Exit;
//      end;

      sDirectory := Common.Path.LGDPara + Common.TestModelInfoFLOW.ModelTypeName + '\Default.bin';
      if not FileExists(sDirectory) then begin
        Exit;
      end;
      sFileSend := sDirectory;

      sTemp := '---------- Flash ALL Write';
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
      //
      if Length(sFileSend) <= 0 then begin
        sTemp := sTemp + ' ...Parameter Error(Flash All file is NOT selected) !!!';
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;

      sFileName := Trim(sFileSend);
      sFileExt  := ExtractFileExt(sFileName);
      if LowerCase(sFileExt) = '.hex'      then bIsHexFile := True
      else if LowerCase(sFileExt) = '.bin' then bIsHexFile := False
      else begin
        sTemp := sTemp + ' ...Parameter Error(the selected file is NOT *.hex|*.bin) !!!';
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp+Format(': %s',[sFileName]),'',0);
      //
      nFlashSize := 8192*1024;  // 8MB
      //
      if bIsHexFile then begin
        nDataSize := Common.GetHexLog(sFileName,nDataSize,@DataBuf[0]);
      end
      else begin
        mtData := TMemoryStream.Create;
        try
          mtData.LoadFromFile(sFileName);
          SetLength(binData,nFlashSize);
          mtData.Position := 0;
          mtData.Read(binData[0],mtData.Size);
          //
          nDataSize := mtData.Size;
          SetLength(DataBuf,nDataSize);
          CopyMemory(@DataBuf[0],@binData[0],Min(nFlashSize,nDataSize));
        finally
          mtData.Free;
        end;
      end;
      if nDataSize <= 0  then begin
        sTemp := sTemp + ' ...Error(Check Flash All hex|bin file data) !!!';
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;
      if nDataSize <> nFlashSize  then begin
        sTemp := sTemp + Format(' ...NG(DataCnt:%d, FlashSize=%d) !!!',[nDataSize,nFlashSize]);
        SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
        Exit;
      end;
      //
      dwRtn :=Pg[FPgNo].SendFlashWrite(0{nStartAddr},nDataSize, @DataBuf[0]);
      sTemp := sTemp + TernaryOp((dwRtn = WAIT_OBJECT_0),' OK',' NG');
      if dwRtn = WAIT_OBJECT_0 then sTemp := sTemp + Format(' [LOG/FLASH/CH%d_FlashAllWrite_A0x0_L%d.bin]',[FPgNo,nFlashSize]);
      SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sTemp,'',0);
    finally
      ReturnOutputArg(Integer(dwRtn));
    end;
  end;
end;


function ExtractDifference(const Str1, Str2: string): string;
var
  i: Integer;
begin
  Result := '';

  // 두 문자열 중 작은 길이를 기준으로 반복
  for i := 1 to Min(Length(Str1), Length(Str2)) do
  begin
    // 문자가 다른 경우에만 추가
    if Str1[i] <> Str2[i] then
      Result := Result + Format('%d:%s', [i, Str2[i]]);
  end;

  // 길이가 다른 부분을 추가
  if Length(Str1) > Length(Str2) then
  begin
    for i := Length(Str2) + 1 to Length(Str1) do
      Result := Result + Format('%d:%s', [i, Str1[i]]);
  end
  else if Length(Str2) > Length(Str1) then
  begin
    for i := Length(Str1) + 1 to Length(Str2) do
      Result := Result + Format('%d:%s', [i, Str2[i]]);
  end;
end;



procedure TScrCls.OCFlowStart_Proc(AMachine: TatVirtualMachine);
var
  wdRet,i : integer;
  sPID,sSerialNumber,sEquipment,sUSERID,sDiff : string;
begin
  With AMachine do begin
    wdRet := 3;
//    if not CSharpDll.m_bIsDLLWork[FPgNo] then begin

    PG[FPgNo].DP860_SendOcOnOff(1{start},2000,0); //2023-03-28 jhhwang (for T/T Test)
    PG[FPgNo].SetCyclicTimer(False);


    case InputArgCount of
      2 : begin
        sPID := GetInputArgAsstring(0);
        sSerialNumber := Trim(GetInputArgAsstring(1));

        if Common.SystemInfo.OCType = DefCommon.OCType then begin
          if DongaGmes <> nil then  begin
            sPID :=  DongaGmes.MesData[FPgNo].PchkRtnPID; // Added by KTS 2023-05-19 오후 5:32:48 PCHK 받은 RYN_PID
            if (Pos('TEST_CH',sSerialNumber) = 0) and (Pos('Contact_NG',sSerialNumber) = 0)  then begin     // Contact_NG 가 아닌 경우만
              if (sSerialNumber <> DongaGmes.MesData[FPgNo].PchkRtnSerialNo) or (Length(sSerialNumber) <> Common.TestModelInfoFLOW.SerialNoFlashInfo.nLength) then begin //
                if sSerialNumber <> DongaGmes.MesData[FPgNo].PchkRtnSerialNo then begin
                  sDiff := ExtractDifference(sSerialNumber,DongaGmes.MesData[FPgNo].PchkRtnSerialNo);
                  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('ExtractDifference : %s',[sDiff]),'',1);
                end;
                CSharpDll.m_OCCkSerialNB[FPgNo] := True;
              end
              else begin
                SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'Read SerialNumber and RTN_SERIAL_NO are the same','',0);
              end;
            end;
          end;
        end
        else begin
          if DongaGmes <> nil then
            sPID := DongaGmes.MesData[FPgNo].PchkRtnPID;
        end;
        if Length(sPID) = 0 then sPID := Copy(sSerialNumber,1,3);

        if Common.SystemInfo.OCType = DefCommon.OCType then begin
          if g_CommPLC <> nil then  begin
            if (g_CommPLC.GlassData[FPgNo].MateriID <> '') and ((Pos('TEST_CH',sSerialNumber) > 0) or (Pos('Contact_NG',sSerialNumber) > 0)) then begin
              sSerialNumber := g_CommPLC.GlassData[FPgNo].MateriID;
              m_sMateriID := g_CommPLC.GlassData[FPgNo].MateriID;
            end;
          end;

          SendTestGuiDisplay(DefCommon.MSG_MODE_IRTEMP,'IRTEM : Start','',1);   //Start
        end;
        if Length(sSerialNumber) = 0 then sSerialNumber := 'TEST123456789012345678901';
        sEquipment := Common.SystemInfo.EQPId;
        sUSERID := Common.SystemInfo.AutoLoginID;

        TestInfo.PreOcReStart := False; // Added by KTS 2023-06-09 오후 4:20:10 ReStart 초기화

        wdRet := CSharpDll.MainOC_Start(Self.FPgNo,sPID,sSerialNumber,sUSERID,sEquipment);
      end;
    end;
    ReturnOutputArg( Integer(wdRet));
  end;
end;

procedure TScrCls.OCFlowStop_Proc(AMachine: TatVirtualMachine);
var
wdRet : Integer;
begin
  With AMachine do begin
    PG[Self.FPgNo].DP860_SendOcOnOff(0{end},2000,0); //2023-03-28 jhhwang (for T/T Test)
    PG[Self.FPgNo].SetCyclicTimer(False); //2023-03-28 jhhwang (for T/T Test)

    case FPgNo of
      0: wdRet := CSharpDll.MainOC_Stop_CH1(Self.FPgNo);
      1: wdRet := CSharpDll.MainOC_Stop_CH2(Self.FPgNo);
      2: wdRet := CSharpDll.MainOC_Stop_CH3(Self.FPgNo);
      3: wdRet := CSharpDll.MainOC_Stop_CH4(Self.FPgNo);
    end;

    CSharpDll.m_bIsDLLWork[Self.FPgNo] := False;
    PG[Self.FPgNo].SetCyclicTimer(True); //2023-03-28 jhhwang (for T/T Test)

    ReturnOutputArg( Integer(wdRet));
  end;
end;

procedure TScrCls.OCThreadStateCheck_Proc(AMachine: TatVirtualMachine);
var
wdRet,nStartAddr,nLength,SerialNoBuf: Integer;
begin
  With AMachine do begin
  end;
end;



procedure TScrCls.OCThreadFlash_READ_Proc(AMachine: TatVirtualMachine);
var
wdRet ,nStartAddr,nLength: Integer;
sAnsiStr ,sSerialNo,sIsAlphaNumeric: string;
SerialNoBuf : TIdBytes;
begin
  With AMachine do begin
//    wdRet := CSharpDll.MainOC_Flash_Read(Self.FPgNo);
    case InputArgCount of
    0:
      begin
        wdRet := 1;
        nStartAddr := Common.TestModelInfoFLOW.SerialNoFlashInfo.nAddr;
        nLength :=  Common.TestModelInfoFLOW.SerialNoFlashInfo.nLength;
//        Common.MLog(self.FPgNo,format('OCThreadFlash_READ_Proc nStartAddr : %d nLength : %d ',[nStartAddr,nLength]));
        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('OCThreadFlash_READ_Proc nStartAddr : %d nLength : %d ',[nStartAddr,nLength]));
        SetLength(SerialNoBuf,nLength);
        wdRet :=  Pg[FPgNo].SendFlashRead(nStartAddr,nLength, @SerialNoBuf[0]);
        SetString(sAnsiStr, PAnsiChar(@SerialNoBuf[0]), nLength);
        sAnsiStr := Copy(sAnsiStr,1,nLength);
        sSerialNo := string(Trim(sAnsiStr));
        SetLength(SerialNoBuf,0);

//        {$IFDEF SIMULATOR}
//          sSerialNo := Format('PPPGU500011EEEEEEE000000ABNAA00000S00B12C00000000000000000003XA000000C43GQA0009R00000EL+3+T32LL1GM750D7R00000EN+1GJ6GLL0022B00000EPGJ6GPE0014M00000EQTHAGPG000MT00000EKF3111111112C1LY1GTS255720000273J1LLL3125AJY043010304T0MHU0S00ML341WL013L_%d',[FPgNo]);
//        {$ENDIF}
        sIsAlphaNumeric := Copy(sSerialNo,1,1);
        if not IsValidString(sIsAlphaNumeric) then begin
          sSerialNo := Format('TEST_CH%d',[Self.FPgNo]);
          SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,format('Unable to convert characters CH : %d',[Self.FPgNo]));
        end;
        TestInfo.SerialNo := sSerialNo;
//        Common.MLog(self.FPgNo,format('OCThreadFlash_READ_Proc SerialNo : %s ',[sSerialNo]));
        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('OCThreadFlash_READ_Proc SerialNo : %s ',[sSerialNo]));
      end;
    end;
    ReturnOutputArg( Integer(wdRet));
  end;
end;

procedure TScrCls.OCThreadFlash_Write_Proc(AMachine: TatVirtualMachine);
var
wdRet ,nStartAddr,nLength: Integer;
sAnsiStr ,sSerialNo,sIsAlphaNumeric: string;
SerialNoBuf : TIdBytes;
sLog : string;
begin
  With AMachine do begin
//    wdRet := CSharpDll.MainOC_Flash_Read(Self.FPgNo);
    case InputArgCount of
    1:
      begin
        wdRet := 1;
        if Length(PasScr[FPgNo].TestInfo.SerialNo) > 0 then begin
          nStartAddr := Common.TestModelInfoFLOW.SerialNoFlashInfo.nAddr;
          nLength :=  Common.TestModelInfoFLOW.SerialNoFlashInfo.nLength;
          sLog := format('OCThreadFlash_WRITE_Proc nStartAddr : 0x%x nLength : %d ',[nStartAddr,nLength]);
          sLog := sLog + Format(' SerialNo : %s',[PasScr[FPgNo].TestInfo.SerialNo]);
//          Common.MLog(FPgNo,sLog);
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sLog);

          SerialNoBuf := Common.StringToIdBytes(PasScr[FPgNo].TestInfo.SerialNo);
          if nLength <> Length(SerialNoBuf) then
            nLength := Length(SerialNoBuf);
          wdRet :=  Pg[FPgNo].SendFlashWrite(nStartAddr,nLength, @SerialNoBuf[0]);
          SetInputArg(0,PasScr[FPgNo].TestInfo.SerialNo);
        end
        else begin
          SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, 'SerialNo data not found','',0);
          SetInputArg(0,'');
        end;
      end;
    end;
    ReturnOutputArg(wdRet);
  end;
end;

procedure TScrCls.OCVerifyStart_Proc(AMachine: TatVirtualMachine);
var
wdRet : Integer;
begin
  With AMachine do begin
    PG[Self.FPgNo].SetCyclicTimer(False); //2023-03-28 jhhwang (for T/T Test)

    wdRet := CSharpDll.m_MainOC_VerifyStart(Self.FPgNo);
    wdRet := 0;

    PG[Self.FPgNo].SetCyclicTimer(True); //2023-03-28 jhhwang (for T/T Test)
    ReturnOutputArg( Integer(wdRet));
  end;
end;


procedure TScrCls.ReadCA410_Proc(AMachine: TatVirtualMachine);
{$IFDEF CA410_USE}
var
  wdRet: Integer;
  i: Integer;
  sDebug: string;
{$ENDIF}
begin
{$IFDEF CA410_USE}
  With AMachine do
  begin
    if InputArgCount = 3 then
    begin
      m_Ca410Data.xVal := GetInputArgAsFloat(0);
      m_Ca410Data.yVal := GetInputArgAsFloat(1);
      m_Ca410Data.LvVal := GetInputArgAsFloat(2);
      // for i := 0 to 1000 do begin
      // if not m_bIsCa410_Measure then Break;
      // Sleep(10);
      // end;
      // SendTestGuiDisplay(DefCommon.MSG_MODE_CA310_MEASURE,'','',1);
      // Common.MLog(Self.FPgNo,'CA410 Measure ');
      wdRet := CaSdk2.Measure(Self.FPgNo, m_Ca410Data);
      // sDebug := format('CA410 Measure %d  %0.4f, %0.4f, %0.2f',[wdRet, m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
      // Common.MLog(Self.FPgNo,sDebug);
      // SendTestGuiDisplay(DefCommon.MSG_MODE_CA310_MEASURE,'','',0);
      // 해당 값으로 넘겨 준다.
      SetInputArg(0, m_Ca410Data.xVal);
      SetInputArg(1, m_Ca410Data.yVal);
      SetInputArg(2, m_Ca410Data.LvVal);
      ReturnOutputArg(wdRet);
    end;
  end;
{$ENDIF}
end;

procedure TScrCls.OtpRead_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
begin
  with AMachine do begin
//    wdRet := Pg[Self.FPgNo].SendOtpRead;
//    ReturnOutputArg( Integer(wdRet));
  end;

end;

procedure TScrCls.OtpWrite_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
begin
  with AMachine do begin
//    wdRet := Pg[Self.FPgNo].SendOtpWrite;
//    ReturnOutputArg( Integer(wdRet));
  end;
end;

procedure TScrCls.PgReset_Proc(AMachine: TatVirtualMachine);
var
  pwrData : PRxPwrData;
  wdRet : Integer;
  Wrapper: TGenericRecordWrapper;
//  sDebug : string;
begin
  With AMachine do begin
//    wdRet := Pg[Self.FPgNo].SendPgReset;
//    ReturnOutputArg( Integer(wdRet));
  end;
end;


procedure TScrCls.PgToComm_Proc(AMachine: TatVirtualMachine); //TBD:AF9?
const
  PARAM_SIGID = 1;
  RARAM_WAIT  = 2;
  RARAM_RTY   = 3;
  PARAM_COMMD = 4;
  PARAM_VALUE = 5;
  PARAM_VALUE2 = 6;
  PARAM_VALUE3 = 7;
var
  naParam : array[PARAM_SIGID..PARAM_VALUE3] of Integer;
  wdRet   : DWORD;
  nWaitMS : Integer;
  nRetry  : Integer;
  nDBVBand : Integer;
//  sDebug  : string;
begin
  With AMachine do begin
//    wdRet := WAIT_FAILED;
    nWaitMS := 3000;
    nRetry  := 0;  // No Retry
    wdRet   := 10;
    Case InputArgCount of
      2,3,4,5,6 : begin
        naParam[PARAM_SIGID] :=  GetInputArgAsInteger(0);
        case naParam[PARAM_SIGID] of
          // power on, off.
          1 : begin // Power
            naParam[1] := GetInputArgAsInteger(1); // On/Off
            if InputArgCount >= 3 then nWaitMS := GetInputArgAsInteger(2); // WaitAck (msec)
            if InputArgCount >= 4 then nRetry  := GetInputArgAsInteger(3); // Retry

            if naParam[1] = DefScript.PP_COMMAD_PWR_OFF then begin
            //wdRet := Pg[Self.FPgNo].SendPowerOff(nWaitMS,nRetry);
              wdRet := Pg[Self.FPgNo].SendPowerOn(0{Off},False,nWaitMS,nRetry); //TBD:DP860?
              TestInfo.PowerOn := False;
              SendTestGuiDisplay(DefCommon.MSG_MODE_POWER_OFF,'','',0);
              SendMainGuiDisplay(DefCommon.MSG_MODE_POWER_OFF);
            end
            else if naParam[1] = DefScript.PP_COMMAD_PWR_ON then begin
              TestInfo.PowerOn := True;
//              wdRet := Pg[Self.FPgNo].SendPowerOn(nWaitMS,nRetry);
              wdRet := Pg[Self.FPgNo].SendPowerOn(1{On},False,nWaitMS,nRetry); //TBD:DP860?
              SendTestGuiDisplay(DefCommon.MSG_MODE_POWER_ON,'','',0);
              SendMainGuiDisplay(DefCommon.MSG_MODE_POWER_ON);
            {$IF Defined(INSPECTOR_FI) or Defined(INSPECTOR_OQA)}
              SendTestGuiDisplay(DefCommon.MSG_MODE_PAT_DISPLAY,'','',m_nCurPat);
            {$ENDIF}
            end;
          end;
          // power measurement.
          2 : begin
            naParam[1] := GetInputArgAsInteger(1); // Interval or off : in case of 0 ==> off.
//            if InputArgCount = 3 then nWait := GetInputArgAsInteger(2); // Interval
            if naParam[1] <> 0 then begin
              Pg[Self.FPgNo].SetPwrMeasureTimer(True, naParam[1]);  //TBD:DP860?
            end
            else begin
              Pg[Self.FPgNo].SetPwrMeasureTimer(False, 0); //TBD:DP860?
            end;
          end;
          3 : begin // Pattern display at Pattern Group.
            naParam[1] := GetInputArgAsInteger(1); // Idx at Pattern Group
            if InputArgCount >= 3 then nWaitMS := GetInputArgAsInteger(2); // WaitAck (msec)
            if InputArgCount >= 4 then nRetry  := GetInputArgAsInteger(3); // Retry
            wdRet := Pg[Self.FPgNo].SendDisplayPatPwmNum(naParam[1], nWaitMS,nRetry);  //2019-10-11 DIMMING (SendDisplayPat -> SendDisplayPWMPat)
            if TestInfo.PowerOn then begin
              SendTestGuiDisplay(DefCommon.MSG_MODE_PAT_DISPLAY,'','',naParam[1]);
            end;
          end;
          4 : begin
            naParam[1] := GetInputArgAsInteger(1); // R Value
            naParam[2] := GetInputArgAsInteger(2); // G Value
            naParam[3] := GetInputArgAsInteger(3); // B Value
            if InputArgCount >= 5 then nWaitMS := GetInputArgAsInteger(4); // WaitAck
            if InputArgCount >= 6 then nRetry  := GetInputArgAsInteger(3); // Retry
            wdRet := Pg[Self.FPgNo].SendDisplayPatRGB(naParam[1],naParam[2],naParam[3],nWaitMS,nRetry);
          end;
          5 : begin
            naParam[1] := GetInputArgAsInteger(1); // Dimming
            if naParam[1] < 33 then
                  nDBVBand := Common.m_GetDBV[naParam[1]-1]
            else  nDBVBand := naParam[1];
            if InputArgCount >= 3 then nWaitMS := GetInputArgAsInteger(2); // WaitAck (msec)
            if InputArgCount >= 4 then nRetry  := GetInputArgAsInteger(3); // Retry
            wdRet := Pg[Self.FPgNo].SendDimming(nDBVBand, nWaitMS,nRetry);  //2019-10-11 DIMMING (SendDisplayPat -> SendDisplayPWMPat)

          end;
          6 : begin
            naParam[1] := GetInputArgAsInteger(1); // Dimming
            if naParam[1] < 33 then
                  nDBVBand := Common.m_GetDBV[naParam[1]-1]
            else  nDBVBand := naParam[1];
            if InputArgCount >= 3 then nWaitMS := GetInputArgAsInteger(2); // WaitAck (msec)
            if InputArgCount >= 4 then nRetry  := GetInputArgAsInteger(3); // Retry
            wdRet := Pg[Self.FPgNo].SendDimmingBist(nDBVBand, nWaitMS,nRetry);  //2019-10-11 DIMMING (SendDisplayPat -> SendDisplayPWMPat)

          end;
          7 : begin // Power
            naParam[1] := GetInputArgAsInteger(1); // On/Off
            if InputArgCount >= 3 then nWaitMS := GetInputArgAsInteger(2); // WaitAck (msec)
            if InputArgCount >= 4 then nRetry  := GetInputArgAsInteger(3); // Retry

            if naParam[1] = DefScript.PP_COMMAD_PWR_OFF then begin
            //wdRet := Pg[Self.FPgNo].SendPowerOff(nWaitMS,nRetry);
              wdRet := Pg[Self.FPgNo].SendPowerBistOn(0{Off},False,nWaitMS,nRetry); //TBD:DP860?
              TestInfo.PowerOn := False;
            end
            else if naParam[1] = DefScript.PP_COMMAD_PWR_ON then begin
              TestInfo.PowerOn := True;
//              wdRet := Pg[Self.FPgNo].SendPowerOn(nWaitMS,nRetry);
              wdRet := Pg[Self.FPgNo].SendPowerBistOn(1{On},False,nWaitMS,nRetry); //TBD:DP860?
            end
            else if naParam[1] = DefScript.PP_COMMAD_PWR_OFF_RESET then begin
              TestInfo.PowerOn := True;
//              wdRet := Pg[Self.FPgNo].SendPowerOn(nWaitMS,nRetry);
              wdRet := Pg[Self.FPgNo].SendPowerBistOn(0{Off},True,nWaitMS,nRetry); //TBD:DP860?
            end
            else if naParam[1] = DefScript.PP_COMMAD_PWR_ON_RESET then begin
              TestInfo.PowerOn := True;
//              wdRet := Pg[Self.FPgNo].SendPowerOn(nWaitMS,nRetry);
              wdRet := Pg[Self.FPgNo].SendPowerBistOn(1{On},true,nWaitMS,nRetry); //TBD:DP860?
            end;
          end;

          8 : begin
            naParam[1] := GetInputArgAsInteger(1); // R Value
            naParam[2] := GetInputArgAsInteger(2); // G Value
            naParam[3] := GetInputArgAsInteger(3); // B Value
            if InputArgCount >= 5 then nWaitMS := GetInputArgAsInteger(4); // WaitAck
            if InputArgCount >= 6 then nRetry  := GetInputArgAsInteger(5); // Retry
            wdRet := Pg[Self.FPgNo].SendDisplayPatBistRGB(naParam[1],naParam[2],naParam[3],nWaitMS,nRetry);
          end;
          9 : begin
            naParam[1] := GetInputArgAsInteger(1); // R Value
            naParam[2] := GetInputArgAsInteger(2); // G Value
            naParam[3] := GetInputArgAsInteger(3); // B Value
            if InputArgCount >= 5 then nWaitMS := GetInputArgAsInteger(4); // WaitAck
            if InputArgCount >= 6 then nRetry  := GetInputArgAsInteger(5); // Retry
            wdRet := Pg[Self.FPgNo].SendDisplayPatBistRGB_9Bit(naParam[1],naParam[2],naParam[3],nWaitMS,nRetry);
          end;
        end;
      end;
    end;
    ReturnOutputArg( Integer(wdRet));
  end;
end;


//procedure TScrCls.PgToComm_Proc(AMachine: TatVirtualMachine);
//const
//  PARAM_SIGID = 1;
//  RARAM_WAIT  = 2;
//  RARAM_RTY   = 3;
//  PARAM_COMMD = 4;
//  PARAM_VALUE = 5;
//  PARAM_VALUE2 = 6;
//  PARAM_VALUE3 = 7;
//var
//  naParam : array[PARAM_SIGID..PARAM_VALUE3] of Integer;
//  wdRet   : DWORD;
//  nWait   : Integer;
////  sDebug  : string;
//begin
//  With AMachine do begin
////    wdRet := WAIT_FAILED;
//    nWait := 3000;
//    wdRet := 10;
//    Case InputArgCount of
//      2,3 : begin
//        naParam[PARAM_SIGID] :=  GetInputArgAsInteger(0);
//        case naParam[PARAM_SIGID] of
//          // power on, off.
//          1 : begin // Power
//            naParam[1] := GetInputArgAsInteger(1); // On/Off
//            if InputArgCount = 3 then nWait := GetInputArgAsInteger(2);
//            wdRet := Pg[Self.FPgNo].SendPowerOn(naParam[1],nWait);
//            if naParam[1] = DefScript.PP_COMMAD_PWR_OFF then begin
//              TestInfo.PowerOn := False;
//              SendTestGuiDisplay(DefCommon.MSG_MODE_POWER_OFF,'','',0);
//            end
//            else if naParam[1] in [DefScript.PP_COMMAD_PWR_ON, DefScript.PP_COMMAD_PWR_ON_AUTOCODE] then begin
//              TestInfo.PowerOn := True;
////              TestInfo.StartTime := now;
//              SendTestGuiDisplay(DefCommon.MSG_MODE_POWER_ON,'','',0);
//            end;
//          end;
//          // power measurement.
//          2 : begin
//            naParam[1] := GetInputArgAsInteger(1); // Interval or off : in case of 0 ==> off.
////            if InputArgCount = 3 then nWait := GetInputArgAsInteger(2); // Interval
//            if naParam[1] <> 0 then begin
//              Pg[Self.FPgNo].SetPowerMeasureTimer(True, naParam[1]);
//            end
//            else begin
//              Pg[Self.FPgNo].SetPowerMeasureTimer(False, 0);
//            end;
//          end;
//          3 : begin // Pattern display at Pattern Group.
//            naParam[1] := GetInputArgAsInteger(1); // Idx at Pattern Group
//            if InputArgCount = 3 then nWait := GetInputArgAsInteger(2); // Interval
//            wdRet := Pg[Self.FPgNo].SendDisplayPat(naParam[1],nWait);
//            if TestInfo.PowerOn then begin
//              SendTestGuiDisplay(DefCommon.MSG_MODE_PAT_DISPLAY,'','',naParam[1]);
//            end;
//          end;
//          5 : begin
//
//          end;
//        end;
//      end;
//      // Length가 4 또는 5일 경우.
//      4,5 : begin
//        naParam[PARAM_SIGID] :=  GetInputArgAsInteger(0);
//        case naParam[PARAM_SIGID] of
//          4 : begin
//            naParam[1] := GetInputArgAsInteger(1); // R Value
//            naParam[2] := GetInputArgAsInteger(2); // G Value
//            naParam[3] := GetInputArgAsInteger(3); // B Value
//            if InputArgCount = 5 then nWait := GetInputArgAsInteger(4); // Interval
//            wdRet := Pg[Self.FPgNo].SendSinglePat(naParam[1],naParam[2],naParam[3],nWait);
//          end;
//        end;
//      end;
//    end;
//    ReturnOutputArg( Integer(wdRet));
//  end;
//end;

procedure TScrCls.PowerMeasure_Proc(AMachine: TatVirtualMachine); //TBD:AF9?
var
  wdRet   : Integer;
  PwrData : PPwrData;
  Wrapper : TGenericRecordWrapper;
begin
  With AMachine do begin
    if InputArgCount = 1 then begin
      Wrapper := VarToObject(AMachine.GetInputArg(0)) as TGenericRecordWrapper;
      PwrData  := PPwrData(Wrapper.Rec);
      wdRet   := Pg[Self.FPgNo].SendPowerMeasure(True{bWait});
      if wdRet = WAIT_OBJECT_0 then begin
        CopyMemory(PwrData,@Pg[Self.FPgNo].m_PwrData,SizeOf(Pg[Self.FPgNo].m_PwrData));
      end;
      SetInputArg(0,ObjectToVar(Wrapper));
      ReturnOutputArg(wdRet);
    end;
  end;
end;

procedure TScrCls.GetConfigVer_Proc(AMachine: TatVirtualMachine);
var
  wdRet   : Integer;
  SWVerData : PSWVer;
  Wrapper : TGenericRecordWrapper;
  nData : Integer;
begin
  With AMachine do begin
    if InputArgCount = 2 then begin
      wdRet := 0;
      Wrapper := VarToObject(AMachine.GetInputArg(0)) as TGenericRecordWrapper;
      nData:= GetInputArgAsInteger(1);
      SWVerData  := PSWVer(Wrapper.Rec);

      CopyMemory(SWVerData,@Common.SystemInfo.ConfigVer[nData],SizeOf(Common.SystemInfo.ConfigVer[nData]));

      SetInputArg(0,ObjectToVar(Wrapper));
      ReturnOutputArg(wdRet);
    end;
  end;
end;

procedure TScrCls.GpioPanel_IRQ_Proc(AMachine: TatVirtualMachine);
var
  wdRet,nData   : Integer;
  PwrData : PPwrData;
  Wrapper : TGenericRecordWrapper;
begin
  With AMachine do begin
    nData:= GetInputArgAsInteger(0);
    wdRet   := Pg[Self.FPgNo].DP860_SendGpioPanel_IRQ(nData);

    SetInputArg(0,nData);
    ReturnOutputArg(wdRet);
  end;
end;




procedure TScrCls.PowerBistSet_Proc(AMachine: TatVirtualMachine);
var
  dwRet : DWORD;
  nSet : Integer;
  sSendCmd, sDebug : String;
begin
  With AMachine do begin
    dwRet:= WAIT_FAILED;

    if InputArgCount = 1 then begin
      nSet:= GetInputArgAsInteger(0);
      if nSet = 1 then       dwRet := Pg[FPgNo].SendPowerBistOn(DefPG.CMD_POWER_ON) // power on
      else   dwRet := Pg[FPgNo].SendPowerBistOn(DefPG.CMD_POWER_OFF); // power on

      if dwRet = WAIT_OBJECT_0 then begin
        sDebug := Format('PowerSet OK, Set:%d', [nSet]);
      end
      else begin
        sDebug := Format('PowerSet NG, Set:%d', [nSet]);
      end;

      //if common.SystemInfo.DebugLog then Common.MLog(self.FPgNo,'[Source Code] ' + sDebug);

    end;
    ReturnOutputArg(dwRet);
  end;
end;



procedure TScrCls.PowerSet_Proc(AMachine: TatVirtualMachine);
var
  dwRet : DWORD;
  nSet : Integer;
  sSendCmd, sDebug : String;
begin
  With AMachine do begin
    dwRet:= WAIT_FAILED;

    if InputArgCount = 1 then begin
      nSet:= GetInputArgAsInteger(0);
      if nSet = 1 then       dwRet := Pg[FPgNo].SendPowerOn(DefPG.CMD_POWER_ON) // power on
      else   dwRet := Pg[FPgNo].SendPowerOn(DefPG.CMD_POWER_OFF); // power on



      if dwRet = WAIT_OBJECT_0 then begin
        sDebug := Format('PowerSet OK, Set:%d', [nSet]);
      end
      else begin
        sDebug := Format('PowerSet NG, Set:%d', [nSet]);
      end;

      //if common.SystemInfo.DebugLog then Common.MLog(self.FPgNo,'[Source Code] ' + sDebug);

    end;
    ReturnOutputArg(dwRet);
  end;
end;


procedure TScrCls.ProgrammingWrite_Proc(AMachine: TatVirtualMachine);
var
  nSlaveType, nDevAddr, nRegAddr,nWriteData : Integer;
  sWriteData : string;
  bDataLog : Boolean;
  nWaitSec, nRetry : Integer;
  //
  wdRet      : DWORD;
  sDebug, sTxData : string;
  lstTemp    : TStringList;
  arrData    : TIdBytes;  //TBD? array of Integer?
  nDataCnt, nTemp, i : Integer;
  sCrcData : string;
begin
  With AMachine do begin
    wdRet := WAIT_FAILED;
    // Get Param ---------------------------------------------------------------
    if InputArgCount < 2 then begin
      ReturnOutputArg(wdRet);
      Exit;
    end;
    nRegAddr   := GetInputArgAsInteger(0);      // arg[0:M] nRegAddr: Integer
    nDataCnt   := GetInputArgAsInteger(1);      // Length
    nWaitSec := 2000; //2023-04-08 (3000->100->200)
    nRetry  := 0;   //2023-04-08 (0->3->0)
    SetLength(arRData,nDataCnt);
    if Length(Common.m_DLLReProgrammingData) < nDataCnt then Exit;

    for I := 0 to nDataCnt -1 do begin
      arrData[i] := Common.m_DLLReProgrammingData[i];
    end;
    bDataLog := True;
    sDebug := Format('ProgrammingWrite: RegAddr(0x%0.4x) DataCnt(%d), CRCData(%s) WaitMS(%d) Retry(%d) ',[nRegAddr,nDataCnt,Common.m_DLLReProgrammingCRC, nWaitSec,nRetry]);
    if bDataLog then SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug,'',DefCommon.LOG_TYPE_INFO)
    else             Common.MLog(FPgNo,sDebug);
    wdRet := Pg[Self.FPgNo].SendReProgramming(PROGRAMING_DEVICE,nRegAddr,nDataCnt,arrData, nWaitSec,nRetry);

    case wdRet of
      WAIT_OBJECT_0: begin
        sDebug := 'Programming WRITE OK';
      end;
      WAIT_TIMEOUT: sDebug := 'Programming WRITE NG (Timeout)';
      WAIT_FAILED : sDebug := 'Programming WRITE NG (Failed)';
      else          sDebug := 'Programming WRITE NG (Etc)';
    end;
    if bDataLog then SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug,'',TernaryOp((wdRet=WAIT_OBJECT_0),DefCommon.LOG_TYPE_OK,DefCommon.LOG_TYPE_NG))
    else             Common.MLog(FPgNo,sDebug);
    ReturnOutputArg(wdRet);
  end;
end;

procedure TScrCls.ReadBcr_Proc(AMachine: TatVirtualMachine);
const
  RTN_OK            = 0;
  RTN_NO_READ_ERROR = 1;
  RTN_MES_ERROR     = 2;
var
  nPos : Integer;
  wdRet : Integer;
//  i: Integer;
begin
  With AMachine do begin
    wdRet := RTN_OK;


    // 사용중인 채널의 Barcode 찍혔는지 확인
    if (PasScr[FPgNo].m_bUse) and (Pg[FPgNo].StatusPG = pgConnect) then begin
//      if (not Logic[FPgNo].m_Inspect.IsScanned) then begin
//        wdRet := RTN_NO_READ_ERROR;
//      end;
    end;

    // 바코드 관련 상위보고 결과 확인. ZSET도 PCHK로 확인하자.
     if (wdRet = RTN_OK) and (DongaGmes is TGmes) then begin
      if (PasScr[FPgNo].m_bUse) and (not DongaGmes.MesData[FPgNo].bPCHK) then begin
        wdRet := RTN_MES_ERROR;
      end;
    end;

    ReturnOutputArg(wdRet);
  end;
end;


procedure TScrCls.ReadCA310_Proc(AMachine: TatVirtualMachine);
{$IFDEF CA310_USE}
var
  wdRet : Integer;
  nUVMode : Integer;
{$ENDIF}
begin
{$IFDEF CA310_USE}
  With AMachine do begin
    if InputArgCount in [3,4] then begin
      m_Ca310Data.ColorValX := GetInputArgAsFloat(0);
      m_Ca310Data.ColorValY := GetInputArgAsFloat(1);
      m_Ca310Data.GrayVal := GetInputArgAsFloat(2);

//      // 현재 Jig와 Channel을 가져 온다.
//      nCurJig :=  Self.FPgNo div (DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT);
       nUVMode := 0;
      // 해당 값으로 넘겨 준다.
      if InputArgCount = 4 then  begin
        nUVMode := GetInputArgAsInteger(3);
      end;

      wdRet := CheckCA310CmdAck(procedure begin
        SendTestGuiDisplay(DefCommon.MSG_MODE_CA310_MEASURE,'','',nUVMode);
      end,   3000,2);


      // 4번째 Parameter가 1면 uv를 넘기도록 하자.
      if nUVMode <> 1 then begin
        SetInputArg(0,m_Ca310Data.ColorValX);
        SetInputArg(1,m_Ca310Data.ColorValY);
      end
      else begin
        SetInputArg(0,m_Ca310Data.ud);
        SetInputArg(1,m_Ca310Data.vd);
      end;
      SetInputArg(2,m_Ca310Data.GrayVal);


      ReturnOutputArg( wdRet);
    end;
  end;
{$ENDIF}
end;

procedure TScrCls.ReadDio_Proc(AMachine: TatVirtualMachine);
var
  nPos, nVal, nCh : Integer;
  wdRet : Integer;
  nCount : Integer;
begin
  With AMAchine do begin
    if CommDaeDIO <> nil then begin
      nPos := GetInputArgAsInteger(0);
      nVal :=  0;
      nCount := nPos div 8;
      nPos   := nPos mod 8;
      nVal := CommDaeDIO.Get_Bit(CommDaeDIO.DIDataPre[nCount],nPos);
      SetInputArg(1,nVal);
    end;
    ReturnOutputArg(wdRet);
  end;
{$IFDEF  AXDIO_USE}
  With AMachine do begin
    wdRet := 1;
		Case InputArgCount of
      2,3 : begin
        nPos := GetInputArgAsInteger(0);
        nVal :=  0;
        nCh := 0;
        if InputArgCount = 3 then begin
          nCh := FPgNo;
        end;
        if AxDio <> nil then begin
          if AxDio.m_bInDio[nPos+nCh] then nVal := 1;
          wdRet := 0; //AxDio.ReadDio(nPos,nVal);
        end;
        // 해당 값으로 넘겨 준다.
        SetInputArg(1,nVal);
      end;
    End;
    ReturnOutputArg( wdRet);
  end;
{$ENDIF}
end;

procedure TScrCls.RecordTest_Proc(AMachine: TatVirtualMachine);
var
  MyRecord: PTestRecord;
  Wrapper: TGenericRecordWrapper;
begin
  //Get the record from the script
  Wrapper := VarToObject(AMachine.GetInputArg(0)) as TGenericRecordWrapper;
  MyRecord := PTestRecord(Wrapper.Rec);
  SetLength(MyRecord^.c,10);
  MyRecord^.a := 2;
  MyRecord^.c[1] := 0;
  AMachine.SetInputArg(0,ObjectToVar(Wrapper) );

end;

procedure TScrCls.RemakeSerialLog_Proc(AMachine: TatVirtualMachine);
var
  sFilePath, sFileName, sNewFileName : string;
  sData, sPgVer : string;
  stlReadData : TStringList;
  i, nCnt : Integer;
  sNgName, sSeqRet : string;
begin
  With AMachine do begin
//    sNgName := GetInputArgAsString(0);
//    sSeqRet := GetInputArgAsString(1);
//
//    sFilePath := Common.Path.TouchLog+ formatDateTime('yyyymmdd',now) + '\';
//    Common.CheckDir(sFilePath);
//    sFileName := Format('%s%s_Ch%d.txt',[sFilePath , Logic[FPgNo].m_Inspect.SerialNo, FPgNo+1]);
//
//    if FileExists(sFileName) = False then begin
//      Exit;
//    end;
//
//    stlReadData := TStringList.Create;
//    try
//      // 기존 Log Read.
//      stlReadData.LoadFromFile(sFileName);
//      DeleteFile(sFileName);
//
//      // 신규 DATA 추가.
//      nCnt := 0;
//      sData := '[Version]';
//      sData := sData + ',Program Version,'+DefCommon.PROGRAM_VER;
//      InsertDataToFile(sData, nCnt, stlReadData);
//
//      sPgVer := Trim(Copy(PG[FPgNo].m_sFwVer,2,4));
//      sPgVer := sPgVer + '/' + Trim(Copy(PG[FPgNo].m_sFwVer,7,4));
//      sPgVer := sPgVer + '/' + Trim(Copy(PG[FPgNo].m_sFwVer,12,4));
//      sPgVer := sPgVer + '/' + Trim(Copy(PG[FPgNo].m_sFwVer,17,4));
//
//      sData := 'PG_FW/FPGA/MDM/PWR,'+sPgVer;
//      InsertDataToFile(sData, nCnt, stlReadData);
//
//      sData := '[Date : ' + FormatDateTime('yyyy-mm-dd',now) + ']';
//      InsertDataToFile(sData, nCnt, stlReadData);
//      sData := '[Time : ' + FormatDateTime('hh:mm:ss',now) + ']';
//      InsertDataToFile(sData, nCnt, stlReadData);
//      if DongaGmes is TGmes then begin
//        sData := '[EQPID],' + DongaGmes.MesSystemNo;
//        InsertDataToFile(sData, nCnt, stlReadData);
//      end;
//      sData := Format('[CH],%d',[FPgNo+1]);
//      InsertDataToFile(sData, nCnt, stlReadData);
//      InsertDataToFile('', nCnt, stlReadData);
//
//      InsertDataToFile('[ModelName]',nCnt, stlReadData);
//      InsertDataToFile(Common.SystemInfo.TestModel, nCnt, stlReadData);
//      InsertDataToFile('', nCnt, stlReadData);
//
//      InsertDataToFile('[DefectCode],[TEST Name],[Result]',nCnt, stlReadData);
//
//      InsertDataToFile(sSeqRet, nCnt, stlReadData);
//      InsertDataToFile('', nCnt, stlReadData);
//
//      // new File.
//      sData := '';
//      if DongaGmes is TGmes then begin
//        sData := '_' + Copy(DongaGmes.MesSystemNo, Length(DongaGmes.MesSystemNo)-5, 6);
//      end;
//      if sNgName <> '' then begin
//        sFileName := Format('%s_%s_Ch%d_%s_%s',[sFilePath, Logic[FPgNo].m_Inspect.SerialNo, FPgNo+1, sNgName, sData]);
//      end
//      else begin
//        sFileName := Format('%s_%s_Ch%d_P%s',[sFilePath, Logic[FPgNo].m_Inspect.SerialNo, FPgNo+1, sData]);
//      end;
//
//      for i := 1 to 2000 do begin
//        sNewFileName := Format('%s_%d.txt',[sFileName,i]);
//        if not FileExists(sNewFileName) then begin
//          Break;
//        end;
//      end;
//      stlReadData.SaveToFile(sNewFileName);
//    finally
//      stlReadData.Free;
//      stlReadData := nil;
//    end;
  end;
end;
procedure TScrCls.ResetScriptStatus;
var
  i : Integer;
begin
  for i := DefScript.SEQ_STOP to DefScript.SEQ_MAX do begin
    SeqStatus[i].Status := ssNone;
    SeqStatus[i].Process  := spNormal;
  end;
  SeqStatus[DefScript.SEQ_STOP].Process := spStop;
end;

function TScrCls.CheckLastIndexStop(nIndex: integer): Boolean;
begin
  if (CurrentSEQ = DefScript.SEQ_KEY_STOP) and (nIndex = DefScript.SEQ_KEY_STOP) then begin
    Result := True;
  end
  else begin
    Result := False;
  end;
end;

procedure TScrCls.RunMaintScript(hDisplay: HWND; stSource: TScrMemo);
var
  thScript : TThread;
begin
  if Pg[Self.FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit;
  if not m_bUse then Exit;
  if atPasScrpt.Running then Exit;
  FhDisplay :=  hDisplay;
  m_bToMaint := True;
  atPasScrptMaint.SourceCode := stSource.Lines;
  try
    atPasScrptMaint.Compile;
    thScript := TThread.CreateAnonymousThread(procedure begin
      atPasScrptMaint.Execute;
    end);
    thScript.FreeOnTerminate := True;
    thScript.Start;
  except
    on E:Exception do begin
      SendTestGuiDisplay(defCommon.MSG_MODE_CH_RESULT,'SCRIPT LOAD NG','',-2); // 0: OK, 1 : NG.
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,E.Message,'',1);
    end;
  end;
end;

function TScrCls.RunSeq(nIdx: Integer) : Integer;
var
  sSeqName, sDebug : string;
  nJigNo, nJigCh : Integer;
begin
{$IFNDEF  SIMENV_NO_PG}
  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit(DefScript.SEQ_ERR_NONE);
{$ENDIF}
(*
{$IFDEF ISPD_POCB}
  if PlcPocb <> nil then begin
    if not PlcPocb.IsPlcAbbMode then begin
      if not m_bUse then Exit(DefScript.SEQ_ERR_NONE);
    end;
    if not m_bPlcDetect then Exit(DefScript.SEQ_ERR_NONE);
  end;
{$ELSE}
  if not m_bUse then Exit(DefScript.SEQ_ERR_NONE);
{$ENDIF}
*)
  if not m_bUse then Exit(DefScript.SEQ_ERR_NONE);

  if atPasScrpt.Running then begin
    if (SeqStatus[nIdx].Process = spRepeat) then begin
      atPasScrpt.Paused := not atPasScrpt.Paused;
      Exit(DefScript.SEQ_ERR_RUNNING);
    end;
    if (DefScript.SEQ_KEY_STOP = nIdx) or (SeqStatus[nIdx].Process = spStop) then begin
      if m_bLockThread and CheckLastIndexStop(nIdx) then begin
        Exit(DefScript.SEQ_ERR_RUNNING);
      end
      else begin
        atPasScrpt.Halt;
        StopManualKey;
        Sleep(100);
      end;

      //Exit(DefScript.SEQ_ERR_RUNNING);
    end;
  end;
  if m_bLockThread then Exit(DefScript.SEQ_ERR_RUNNING);
  m_bToMaint := False;
  SeqStatus[nIdx].Status := ssNone;
  if SeqStatus[nIdx].Status = ssNone then begin
    case nIdx of
      DefScript.SEQ_STOP      : sSeqName := 'Seq_Stop';
      DefScript.SEQ_KEY_START : sSeqName := 'Seq_Key_Start';
      DefScript.SEQ_KEY_STOP  : sSeqName := 'Seq_Key_Stop';
      DefScript.SEQ_KEY_1     : sSeqName := 'Seq_Key_1';
      DefScript.SEQ_KEY_2     : sSeqName := 'Seq_Key_2';
      DefScript.SEQ_KEY_3     : sSeqName := 'Seq_Key_3';
      DefScript.SEQ_KEY_4     : sSeqName := 'Seq_Key_4';
      DefScript.SEQ_KEY_5     : sSeqName := 'Seq_Key_5';
      DefScript.SEQ_KEY_6     : sSeqName := 'Seq_Key_6';
      DefScript.SEQ_KEY_7     : sSeqName := 'Seq_Key_7';
      DefScript.SEQ_KEY_8     : sSeqName := 'Seq_Key_8';
      DefScript.SEQ_KEY_9     : sSeqName := 'Seq_Key_9';
      DefScript.SEQ_Finish    : sSeqName := 'Process_Finish';
      DefScript.SEQ_KEY_SCAN  : sSeqName := 'Seq_Key_Scan';
      DefScript.SEQ_CAM_ZONE  : sSeqName := 'Seq_Cam_Zone';
      DefScript.SEQ_UNLOAD_ZONE : sSeqName := 'Seq_Unload_Zone';
      DefScript.SEQ_MAINT_1   : sSeqName := 'Mainter_1';
      DefScript.SEQ_MAINT_2   : sSeqName := 'Mainter_2';
      DefScript.SEQ_MAINT_3   : sSeqName := 'Mainter_3';
      DefScript.SEQ_MAINT_4   : sSeqName := 'Mainter_4';
      DefScript.SEQ_MAINT_5   : sSeqName := 'Mainter_5';

    end;
    //실행 SEQ 저장
    CurrentSEQ:= nIdx;
  end
  else begin
    case SeqStatus[nIdx].Status of
      ssPreStop     : sSeqName := 'Seq_Pre_Stop';
      ssSeqReport   : sSeqName := 'Seq_Report';
      ssSeq1        : sSeqName := 'Seq_1';
      ssSeq2        : sSeqName := 'Seq_2';
      ssSeq3        : sSeqName := 'Seq_3';
      ssSeq4        : sSeqName := 'Seq_4';
      ssSeq5        : sSeqName := 'Seq_5';
      ssSeq6        : sSeqName := 'Seq_6';
      ssSeq7        : sSeqName := 'Seq_7';
      ssSeq8        : sSeqName := 'Seq_8';
      ssSeq9        : sSeqName := 'Seq_9';
      ssSeq10       : sSeqName := 'Seq_10';
      ssSeq11       : sSeqName := 'Seq_11';
      ssSeq12       : sSeqName := 'Seq_12';
      ssSeq13       : sSeqName := 'Seq_13';
      ssSeq14       : sSeqName := 'Seq_14';
      ssSeq15       : sSeqName := 'Seq_15';
      ssSeq16       : sSeqName := 'Seq_16';
      ssSeq17       : sSeqName := 'Seq_17';
      ssSeq18       : sSeqName := 'Seq_18';
      ssSeq19       : sSeqName := 'Seq_19';
      ssScan        : sSeqName := 'Seq_Scan';
    end;
  end;
  sDebug := Format('Ch%d --- Run Seq : Idx(%d), status(%d) - SCRIPT Implement : procedure Name : (%s)  ',[Self.FPgNo+1,nIdx,Integer(SeqStatus[nIdx].Status),sSeqName ]);
  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,sDebug);
  ScriptThread(sSeqName,nIdx);

  Result := DefScript.SEQ_ERR_NONE;
end;

procedure TScrCls.ScriptLog(sLog: string);
begin
  SendTestGuiDisplay(defCommon.MSG_MODE_WORKING,sLog,'',0);
end;

function TScrCls.ScriptRunning(nKeyIdx : Integer): Boolean;
begin
  // PG°¡ µ¹Áö ¾ÊÀ¸¸é Pass.
  if Pg[FPgNo].StatusPg in [pgForceStop, pgDisconn] then Exit(False);

{$IFDEF ISPD_POCB}
//  if PlcPocb <> nil then begin
//    if not PlcPocb.IsPlcAbbMode then begin
//      if not m_bUse then Exit(False);
//    end;
//  end;
{$ELSE}
  if not m_bUse then Exit(False);
{$ENDIF}
  if (atPasScrpt.Running) and (SeqStatus[nKeyIdx].Process = spNormal) then Exit(True);
//  // ÀÛ¾÷ÁßÀÌ¸é ´ë±â ÇÏµµ·Ï...
//  if m_bLockThread then Exit(True);

  Result := False;
end;

procedure TScrCls.ScriptThread(sScriptFunc: string; nFirstParam: Integer);
var
  thScript : TThread;
begin
  //Scrip 함수 이름 m_sRunFunction: String 추가
  thScript := TThread.CreateAnonymousThread(procedure begin
    try
      m_bTheadIsTerminated := True;
      m_bLockThread := True;
      try
//        Common.MLog(Self.FPgNo,'[PSU Start]');
        m_bIsScriptWork := True;
        atPasScrpt.ExecuteSubroutine(sScriptFunc,nFirstParam);
//        Common.MLog(Self.FPgNo,'[PSU END]');

      except
        on E:Exception do begin
          SendTestGuiDisplay(defCommon.MSG_MODE_CH_RESULT,'SCRIPT LOAD NG','',-2); // 0: OK, 1 : NG.
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,E.Message,'',1);
        end;
      end;

    finally
      m_bLockThread := False;
    end;
  end);
  if sScriptFunc = 'Seq_Cam_Zone' then begin
    thScript.Priority := tpHigher;
  end;
  thScript.FreeOnTerminate := True;
  thScript.OnTerminate := ScriptThreadIsDone;
  thScript.Start;

end;

procedure TScrCls.ScriptThreadIsDone(Sender: TObject);
begin
//  Common.MLog(self.FPgNo,'ScriptThreadIsDone');   \
  //실행 함수에 따른 분기 필요
  m_bTheadIsTerminated := False;
  m_bIsScriptWork := False;
  if m_bIsSyncSeq then begin
    SendTestGuiDisplay(DefCommon.MSG_MODE_SYNC_WORK,'','', nSyncMode, 0);
//    Common.MLog(self.FPgNo,Format('inside -- %d',[Integer(m_InsStatus)]));
    if m_InsStatus = isStop then begin
      m_bIsSyncSeq := False;
    end;
  end;
  if (Common.AutoReStart) and (Common.SystemInfo.OCType = DefCommon.PreOCType) then begin
    if (CurrentSEQ in [SEQ_KEY_9]) or (CurrentSEQ in [SEQ_KEY_START]) then begin
      if CSharpDll.MainOC_GetOCFlowIsAlive(FPgNo) = 0 then begin
        SendTestGuiDisplay(DefCommon.MSG_MODE_SYNC_WORK,'','', 10, CurrentSEQ);
        SendTestGuiDisplay(DefCommon.MSG_MODE_BARCODE_READY,'','',1);
        Sleep(100);
        frmTest4ChOC[0].getBcrData2(FormatDateTime('hh_nn_ss',now)+format('_%d',[FPgNo]));
      end;
    end;
    if CurrentSEQ in [SEQ_KEY_4] then begin
      SendTestGuiDisplay(DefCommon.MSG_MODE_SYNC_WORK,'','', 11, CurrentSEQ);
    end;
  end;

  if ((CurrentSEQ in [SEQ_KEY_9]) or (CurrentSEQ in [SEQ_KEY_START])) and m_bIDLE then begin
    SendTestGuiDisplay(defCommon.MSG_TYPE_DLL,defCommon.MSG_MODE_WORK_DONE,'OKFLOW_END');
  end;


  //Auto Mode일 경우 Load 요청을위한 알림
  //if Common.StatusInfo.AutoMode then begin
    if CurrentSEQ in [SEQ_UNLOAD_ZONE] then begin
      if not TestInfo.PreOcReStart then begin
        SendTestGuiDisplay(DefCommon.MSG_MODE_SYNC_WORK,'','', 3, CurrentSEQ);
      end
      else begin
//        Common.MLog(self.FPgNo, 'SEQ_UNLOAD_ZONE Done - PreOcReStart');
        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'SEQ_UNLOAD_ZONE Done - PreOcReStart');
      end;
    end;
//    if CurrentSEQ in [SEQ_Finish] then begin
//      SendTestGuiDisplay(DefCommon.MSG_MODE_SYNC_WORK,'','', 4, CurrentSEQ);
//    end;
  //end;

end;


procedure TScrCls.SetMESCODE_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  nNgCode: Integer;
begin
  With AMachine do begin
    wdRet:=  1;
		case InputArgCount of
      1 : begin
        nNgCode:= GetInputArgAsInteger(0);
        if nNgCode = 0 then begin
          TestInfo.MES_Code:= '';
          TestInfo.ERR_Message:= '';
          TestInfo.Result:= '0';
        end
        else begin
          TestInfo.MES_Code:= Common.GmesInfo[nNgCode].MES_Code; //sErrorCode;
          TestInfo.ERR_Message:= Common.GmesInfo[nNgCode].sErrMsg;
          TestInfo.Result:= format('%d NG', [nNgCode]);
        end;
        wdRet:= WAIT_OBJECT_0;
      end;
    end;
    ReturnOutputArg(wdRet);
  end;
end;

procedure TScrCls.SendApdr_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  sHeader, sData : string;
begin
  With AMachine do begin
    wdRet := 1;
		Case InputArgCount of
      1 : begin
        if TestInfo.CanSendApdr then begin
          TestInfo.InsApdr         := VarToObject(GetInputArg(0)) as TInsApdr;

          TestInfo.ApdrData := MakeApdrData;

          if not Common.StatusInfo.LogIn then begin
//            Common.MLog(self.FPgNo, 'APDR SKIP - OFF');
            SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'APDR SKIP - OFF');
            ReturnOutputArg(0);
            Exit;
          end;
          //Common.MLog(Self.FPgNo,TestInfo.ApdrData);
          if DongaGmes <> nil then begin
//            wdRet := CheckSyncCmdAck(procedure begin
//              SendMainGuiDisplay(DefGmes.MES_APDR);
//              SendTestGuiDisplay(DefGmes.MES_APDR, '','', 0);
//            end,5000,1);
//            if wdRet = WAIT_OBJECT_0 then begin
            wdRet := CheckSyncCmdAck(procedure begin
              SendMainGuiDisplay(DefGmes.EAS_APDR);
              SendTestGuiDisplay(DefGmes.EAS_APDR, '','', 0);
            end,5000,1);
//              wdRet :=  m_nHostResult;
          end
          else begin
            wdRet := WAIT_OBJECT_0;
          end;
        end
        else begin
          wdRet := WAIT_OBJECT_0;
        end;
      end;
    End;
    ReturnOutputArg( wdRet);
  end;
end;

procedure TScrCls.SendApdr_EAS_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  sHeader, sData : string;
  sSN : string;
begin
  With AMachine do begin
    try
      wdRet := 1;
      Case InputArgCount of
        1 : begin
          sSN := GetInputArgAsString(0);
          if Length(sSN) = 0 then begin
            ReturnOutputArg(0);
            Exit;
          end;
          if not Common.StatusInfo.LogIn then begin
//            Common.MLog(self.FPgNo, 'APDR_EAS SKIP - OFF');
            SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'APDR_EAS SKIP - OFF');
            ReturnOutputArg(0);
            Exit;
          end;
          Common.MLog(FPgNo,'SendApdr_EAS_Proc : Start!!');
          if DongaGmes <> nil then begin
            //EAS ADPR은 응답을 기다리지 않는다.
            SendMainGuiDisplay(DefGmes.EAS_APDR);
            SendTestGuiDisplay(DefGmes.EAS_APDR, '','', 0);
            wdRet := WAIT_OBJECT_0;
          end
          else begin
            wdRet := WAIT_OBJECT_0;
          end;
          Common.MLog(FPgNo,'SendApdr_EAS_Proc : Finish!!');
        end;
      End;
      ReturnOutputArg(wdRet);
    finally
      ReturnOutputArg(wdRet);
    end;
  end;
end;

procedure TScrCls.SendDisplayGuiDisplay(nGuiMode, nParam: Integer;sMsg : string);
var
  ccd         : TCopyDataStruct;
  GuiData     : RGuiScript;
begin
  GuiData.MsgType := defCommon.MSG_TYPE_SCRIPT;
  GuiData.Channel := self.FPgNo;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam  := nParam;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(FhDisplay,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TScrCls.SendEICR_Proc(AMachine: TatVirtualMachine); // JHHWANG-GMES: 2018-06-20
var
  wdRet : Integer;
  sTemp : string;
  nResult : Integer;
  nTactSec: Int64;
  fTact: Double;
begin
  With AMachine do begin
    wdRet := 1;
		Case InputArgCount of
      2 : begin
        // Barcode Scan Type할때는 빼기.
        if not Common.SystemInfo.OcManualType then begin
          TestInfo.SerialNo  := GetInputArgAsString(0);
        end;
        nResult             := GetInputArgAsInteger(1);

        sTemp := '';
        if Trim(TestInfo.CarrierId) <> ''  then begin
          sTemp := Trim(TestInfo.CarrierId) + ' / ';
        end;
        sTemp := sTemp + Trim(TestInfo.CarrierId);

        if not Common.StatusInfo.LogIn then begin
//          Common.MLog(self.FPgNo, 'EICR SKIP - OFF');
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'EICR SKIP - OFF');
          ReturnOutputArg(0);
          Exit;
        end;

//        SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER,TestInfo.CarrierId +' / '+TestInfo.SerialNo);
        Common.MLog(FPgNo,'SendEICR_Proc : Start!!');
        if DongaGmes is TGmes then begin
          DongaGmes.MesData[Self.FPgNo].Rwk := Common.GmesInfo[nResult].MES_Code;
          DongaGmes.MesData[Self.FPgNo].ErrCode := Common.GmesInfo[nResult].sErrCode;
          //EICR용 Tact 계산
          nTactSec:= SecondsBetween(TestInfo.EndTime, TestInfo.PreEndTime); //완공시간 - 이전 완공 시간
          if nTactSec > 3600 then nTactSec:= 3600;  //너무 큰 경우 방지
          fTact:= nTactSec / MAX_PG_CNT;
          DongaGmes.MesData[Self.FPgNo].Tact :=  format('%.2f', [fTact]);

          wdRet := CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(DefGmes.MES_EICR,1);
            SendTestGuiDisplay(DefGmes.MES_EICR, '','', 0);
          end,5000,1);
          if wdRet = WAIT_OBJECT_0 then begin
            wdRet :=  m_nHostResult;
            if m_nHostResult = 0 then  TestInfo.CanSendApdr := True;
          end;
        end
        else begin
          wdRet := WAIT_OBJECT_0;
        end;
        Common.MLog(FPgNo,'SendEICR_Proc : Done!!');
      end;
    End;
    ReturnOutputArg( wdRet);
  end;
end;

procedure TScrCls.SendEIJR_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  nRet  : Integer;
  nTactSec: Int64;
  fTact: Double;
  nValue,nValue2,nSeq,nEQP_ID : Integer;
begin
  With AMachine do begin
    wdRet := 1;
		Case InputArgCount of
      1 : begin
        // NG Code....
        nRet := GetInputArgAsInteger(0);

        if not Common.StatusInfo.LogIn then begin
//          Common.MLog(self.FPgNo, 'EIJR SKIP - OFF');
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'EIJR SKIP - OFF');
          ReturnOutputArg(0);
          Exit;
        end;
        if g_CommPLC <> nil then begin
          if nRet <> 0 then begin
            if g_CommPLC.PollingAABMode = 1 then begin
              nValue := g_CommPLC.GlassData[FPgNo].GlassProcessingStatus[0];
              nValue2:= g_CommPLC.GlassData[FPgNo].GlassProcessingStatus[1];
              if (Common.PLCInfo.EQP_ID - 6) = 1 then
                nEQP_ID := 1
              else nEQP_ID := 2;
              if nEQP_ID = 1 then begin
                if nValue and $7 = 0 then begin
//                  Common.MLog(self.FPgNo, 'AABMode - A Mode- EIJR SKIP');
                  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'AABMode - A Mode- EIJR SKIP');
                  wdRet := 0;
                  Exit;
                end;
//                if nValue and $38 = 0 then  begin
////                  Common.MLog(self.FPgNo, 'AABMode - AA Mode EIJR SKIP');
//                  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'AABMode - AA Mode EIJR SKIP');
//                  Exit;
//                end;
              end
              else begin

                if nValue and $1C00 = 0 then begin
//                  Common.MLog(self.FPgNo, 'AABMode - A Mode- EIJR SKIP');
                  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'AABMode - A Mode- EIJR SKIP');
                  wdRet := 0;
                  Exit;
                end;
//                if nValue and $E000 = 0 then  begin
////                  Common.MLog(self.FPgNo, 'AABMode - AA Mode EIJR SKIP');
//                  SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'AABMode - AA Mode EIJR SKIP');
//                  Exit;
//                end;

              end;

            end;
          end;
        end;


//        SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER,TestInfo.SerialNo);
        if DongaGmes is TGmes then begin
          DongaGmes.MesData[Self.FPgNo].Rwk := Common.GmesInfo[nRet].MES_Code;

          //EICR용 Tact 계산
          nTactSec:= SecondsBetween(TestInfo.EndTime, TestInfo.PreEndTime); //완공시간 - 이전 완공 시간
          if nTactSec > 3600 then nTactSec:= 3600;  //너무 큰 경우 방지
          fTact:= nTactSec / MAX_PG_CNT;
          DongaGmes.MesData[Self.FPgNo].Tact :=  format('%.2f', [fTact]);

          wdRet := CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(DefGmes.MES_RPR_EIJR,1);
            SendTestGuiDisplay(DefGmes.MES_RPR_EIJR, '','', 0);
          end,5000,1);
          if wdRet = WAIT_OBJECT_0 then begin
            wdRet :=  m_nHostResult;
            if m_nHostResult = 0 then  TestInfo.CanSendApdr := True;
          end;
        end
        else begin
          wdRet := WAIT_OBJECT_0;
        end;
      end;
    End;
    ReturnOutputArg( wdRet);
  end;
end;
procedure TScrCls.SendEraseCodeType_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  nCodeType, nParam1, nParam2  : Integer;
begin
  With AMachine do begin
    wdRet := 1;
    if InputArgCount = 3 then begin
      nCodeType := GetInputArgAsInteger(0);
      nParam1 := GetInputArgAsInteger(1);
      nParam2 := GetInputArgAsInteger(2);
//{$IFDEF ISPD_POCB}
//      if CommCamera <> nil then begin
//        CommCamera.m_nEraseType := nCodeType;
//        CommCamera.m_nEraseParam1 := nParam1;
//        CommCamera.m_nEraseParam2 := nParam2;
//      end;
//{$ENDIF}
    end;


		Case InputArgCount of
      1 : begin
        // NG Code....
        nCodeType := GetInputArgAsInteger(0);

      end;
    End;
    ReturnOutputArg( wdRet);
  end;
end;



procedure TScrCls.SendPCHK_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  sTemp : string;
begin
  With AMachine do begin
    wdRet := 1;
		Case InputArgCount of
      2,3 : begin
        TestInfo.SerialNo  := GetInputArgAsString(0);
        TestInfo.CarrierId := GetInputArgAsString(1);
        // Default.
        TestInfo.nSerialType := 0;      // 0: FOG ID, 1 :PID
        if InputArgCount = 3 then TestInfo.nSerialType := GetInputArgAsInteger(2);

//        sTemp := '';
//        if Trim(TestInfo.CarrierId) <> ''  then begin
//          sTemp := Trim(TestInfo.CarrierId) + ' / ';
//        end;
//        sTemp := sTemp + Trim(TestInfo.CarrierId);

        SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER,TestInfo.SerialNo);

        if not Common.StatusInfo.LogIn then begin
//          Common.MLog(self.FPgNo, 'PCHK SKIP - OFF');
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'PCHK SKIP - OFF');
          ReturnOutputArg(0);
          Exit;
        end;

        m_bMesPMMode := True;
        if DongaGmes <> nil then begin
          m_bMesPMMode := False;
          wdRet := CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(DefGmes.MES_PCHK,1);
            SendTestGuiDisplay(DefGmes.MES_PCHK, '','', 0);
          end,5000,1);
          if wdRet = WAIT_OBJECT_0 then begin
            wdRet :=  m_nHostResult;
            //TestInfo.RTN_PID:= m_sMesPchkRtnPID;
            TestInfo.RTN_PID:= DongaGMes.MesData[Self.FPgNo].PchkRtnPID;
            TestInfo.RTN_MODEL:= DongaGMes.MesData[Self.FPgNo].Model;
            TestInfo.CarrierId := DongaGMes.MesData[Self.FPgNo].PchkRtnZig_ID;
          end;

        end
        else begin
          wdRet := WAIT_OBJECT_0;
        end;
      end;
    End;
    ReturnOutputArg( wdRet);
  end;
end;


procedure TScrCls.SendINSPCHK_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  sTemp : string;
begin
  With AMachine do begin
    wdRet := 1;
    TestInfo.SerialNo  := GetInputArgAsString(0);
{$IFDEF ISPD_POCB}
    if CommCamera <> nil then begin
      CommCamera.m_sSerialNo[Self.FPgNo mod 4] := TestInfo.SerialNo;
    end;
{$ENDIF}

    SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER, TestInfo.SerialNo);

    if not Common.StatusInfo.LogIn then begin
//      Common.MLog(self.FPgNo, 'INSPCHK SKIP - OFF');
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'INSPCHK SKIP - OFF');
      ReturnOutputArg(0);
      Exit;
    end;

    m_bMesPMMode := True;
    if DongaGmes <> nil then begin
      m_bMesPMMode := False;
      wdRet := CheckSyncCmdAck(procedure begin
        SendMainGuiDisplay(DefGmes.MES_INS_PCHK, 1);
        SendTestGuiDisplay(DefGmes.MES_INS_PCHK, '','', 0);
      end,5000,1);
      if wdRet = WAIT_OBJECT_0 then begin
        wdRet :=  m_nHostResult;
        //TestInfo.RTN_PID:= m_sMesPchkRtnPID;
        TestInfo.RTN_PID:= DongaGMes.MesData[Self.FPgNo].PchkRtnPID;
        TestInfo.RTN_MODEL:= DongaGMes.MesData[Self.FPgNo].Model;
      end;

    end
    else begin
      wdRet := WAIT_OBJECT_0;
    end;

    ReturnOutputArg( wdRet);
  end;
end;


procedure TScrCls.SendSGEN_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  sTemp : string;
begin
  With AMachine do begin
    wdRet := 1;
		Case InputArgCount of
      1 : begin
        TestInfo.SerialNo  := GetInputArgAsString(0); //Main에서 TestInfo.SerialNo를 사용

        m_bMesPMMode := True;
        if DongaGmes <> nil then begin
          m_bMesPMMode := False;
          wdRet := CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(DefGmes.MES_SGEN,1);
            SendTestGuiDisplay(DefGmes.MES_SGEN, '','', 0);
          end,5000,1);
          if wdRet = WAIT_OBJECT_0 then begin
            wdRet :=  m_nHostResult;
          end;

        end
        else begin
          wdRet := WAIT_OBJECT_0;
        end;
      end;
    End;
    ReturnOutputArg( wdRet);
  end;
end;

procedure TScrCls.ECS_NotifyEvent(ItemValue: TMESItemValue);
var
  nCh:Integer;
begin
  //AddLog(format('MESNotifyEvent Ch=%d ', [ItemValue.Channel]));
  nCh:= ItemValue.Channel;
  //m_MESItemValue.Ack := ItemValue.Ack;
  m_MESItemValue := ItemValue;
  SetEvent(ItemValue.EventHandle);
end;

procedure TScrCls.ECS_PCHK_Proc(AMachine: TatVirtualMachine);
var
  item: TMESItem;
  nRet: Integer;
  sGlassData: String;
begin
  With AMachine do begin
    if g_CommPLC = nil then begin
      ReturnOutputArg(0);
      Exit;
    end;
		case InputArgCount of
      2 : begin
        TestInfo.SerialNo  := GetInputArgAsString(0);
        TestInfo.CarrierId := GetInputArgAsString(1);

        SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER,TestInfo.CarrierId +' / '+TestInfo.SerialNo);

        if not Common.StatusInfo.LogIn then begin
//          Common.MLog(self.FPgNo, 'ECS_PCHK SKIP - OFF');
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'ECS_PCHK SKIP - OFF');
          ReturnOutputArg(0);
          Exit;
        end;

        //ECS MES 관련은 순차적으로 처리
        item.Kind:= COMMPLC_MES_KIND_PCHK;
        item.NotifyEvent:= ECS_NotifyEvent;

        item.Value.Channel:= FPgNo;
        ResetEvent(m_MESItemValue.EventHandle); //아이템 이벤트 초기화
        item.Value.EventHandle:= m_MESItemValue.EventHandle;
        item.Value.SerialNo:= TestInfo.SerialNo;
        item.Value.CarrierID:= TestInfo.CarrierId;

        g_CommPLC.ECS_MES_AddItem(item);

        nRet := WaitForSingleObject(m_MESItemValue.EventHandle, 30000);
        case nRet of
          WAIT_OBJECT_0 : begin
            //OK
            if m_MESItemValue.Ack = 0 then begin
//              Common.MLog(self.FPgNo, 'ECS_PCHK OK');
              SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'ECS_PCHK OK');
              //TestInfo.CarrierId:= Trim(g_CommPLC.ECS_GlassData[FPgNo].CarrierID);
              TestInfo.RTN_PID:= Trim(g_CommPLC.ECS_GlassData[FPgNo].GlassID);
              TestInfo.LCM_ID:= Trim(g_CommPLC.ECS_GlassData[FPgNo].LCM_ID);
              //TestInfo.LCM_ID:= m_MESItemValue.LCM_ID;
              //TestInfo.LCM_ID:= g_CommPLC.ECS_GlassData[FPgNo].LCM_ID;
            end
            else begin
              nRet:= m_MESItemValue.Ack;
              SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('ECS_PCHK NG %d ', [m_MESItemValue.Ack]));
//              Common.MLog(self.FPgNo, format('ECS_PCHK NG %d ', [m_MESItemValue.Ack]));
            end;
          end;
          WAIT_TIMEOUT  : begin
            Common.MLog(self.FPgNo, 'ECS_PCHK Timeout');
          end
          else begin
            Common.MLog(self.FPgNo, format('ECS_PCHK Fail Ret:%d ', [nRet]));
          end;
        end;
      end;
    end; //case InputArgCount of

    ReturnOutputArg(nRet);
  end;
end;

procedure TScrCls.ECS_SetGlassData_Proc(AMachine: TatVirtualMachine);
var
  nNgCode: Integer;
  nStation: Integer;
  nSeq,wdRet,nGIBSeq,nEQP_ID: Integer;
begin

  With AMachine do begin
    try
      wdRet := 1;
      if g_CommPLC = nil then begin
        ReturnOutputArg(0);
        Exit;
      end;
      nNgCode := GetInputArgAsInteger(0);
//      Common.MLog(self.FPgNo, 'ECS_SetGlassData NgCode=' + IntToStr(nNgCode),True);
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'ECS_SetGlassData NgCode=' + IntToStr(nNgCode));
      if (Common.PLCInfo.InlineGIB) and (Common.SystemInfo.OCType = DefCommon.OCType) then begin
        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'SetGlassData_CheckRLogistics NgCode=' + IntToStr(nNgCode));
        g_CommPLC.SetGlassData_CheckRLogistics(FPgNo,g_CommPLC.GlassData[FPgNo],0);
      end;

//      if g_CommPLC.GlassData[FPgNo].RecipeNumber = 0 then begin
//        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'ECS_SetGlassData RecipeNumber: 0 - Skip');
//        ReturnOutputArg(0);
//        Exit;
//      end;

      if (not Common.SystemInfo.Use_GIB) and (Common.SystemInfo.OCType = DefCommon.PreOCType) then  begin
        if (Common.GmesInfo[nNgCode].sErrCode <> 'AXXX') then begin
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('Pre OC Change Error Code:  %d -> 0',[nNgCode]));
          nNgCode := 0;
        end;
      end;

      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('SetGlassData : 1 %d',[FPgNo]),'',10);
      if nNgCode = 0 then begin
        g_CommPLC.SetGlassData_JudgCode(g_CommPLC.GlassData[FPgNo], ord('G'));
      end
      else begin

        g_CommPLC.SetGlassData_JudgCode(g_CommPLC.GlassData[FPgNo], ord('N'));

        if (Common.SystemInfo.Use_GIB) then begin //GIB구분- Auto이고 GIB 모드이면 Inline GIB
          if (Common.SystemInfo.OCType = DefCommon.OCType) then  begin
            if (Common.PLCInfo.EQP_ID - 6) = 1 then
              nEQP_ID := 1
            else nEQP_ID := 2;
            nStation:= g_CommPLC.GetGlassData_Processing_Status(g_CommPLC.GlassData[FPgNo],nEQP_ID, nSeq, 16);
            g_CommPLC.SetGlassData_Processing_Status_GIB(g_CommPLC.GlassData[FPgNo],nEQP_ID, FPgNo,nSeq);
          end
          else begin
            g_CommPLC.SetGlassData_Processing_Status(g_CommPLC.GlassData[FPgNo], 0, 2);
          end;
        end
        else begin
          if Common.SystemInfo.OCType = DefCommon.OCType then
          begin
            nStation:= g_CommPLC.GetGlassData_Processing_Status(g_CommPLC.GlassData[FPgNo],1, nSeq , 6);
            g_CommPLC.SetGlassData_Processing_Status(g_CommPLC.GlassData[FPgNo], 1, 6);
          end
          else if Common.SystemInfo.OCType = DefCommon.PreOCType then
          begin
            g_CommPLC.SetGlassData_Processing_Status(g_CommPLC.GlassData[FPgNo], 1, 5);
          end;
        end;
      end;
      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('SetGlassData : 2 %d',[FPgNo]),'',10);
      if (Common.SystemInfo.Use_GIB) then begin //GIB구분- Auto이고 GIB 모드이면 Inline GIB
        if (Common.SystemInfo.OCType = DefCommon.OCType) then begin
          if (Common.PLCInfo.EQP_ID - 6) = 1 then
              nEQP_ID := 1
          else nEQP_ID := 2;
          nStation:= g_CommPLC.GetGlassData_PreviousUnitProcessing(g_CommPLC.GlassData[FPgNo],nEQP_ID, nSeq, 16);
          g_CommPLC.SetGlassData_Previous_Unit_Processing_GIB(g_CommPLC.GlassData[FPgNo],nEQP_ID,FPgNo,nSeq);
        end
        else begin
          if (Common.PLCInfo.EQP_ID - 6) = 1 then
              nEQP_ID := 1
          else nEQP_ID := 4;
          g_CommPLC.SetGlassData_Previous_Unit_Processing(g_CommPLC.GlassData[FPgNo],nEQP_ID);
        end;
      end
      else begin
        if Common.SystemInfo.OCType = DefCommon.OCType then
          g_CommPLC.SetGlassData_Previous_Unit_Processing(g_CommPLC.GlassData[FPgNo], g_CommPLC.EQP_ID-10)
        else if Common.SystemInfo.OCType = DefCommon.PreOCType then
          g_CommPLC.SetGlassData_Previous_Unit_Processing(g_CommPLC.GlassData[FPgNo], g_CommPLC.EQP_ID-13);
      end;
      wdRet := 0;
      Common.MLog(self.FPgNo,format('SetGlassData : Finish %d',[FPgNo]),True);
//      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('SetGlassData : 3 %d',[FPgNo]),'',10);
//      g_CommPLC.SaveGlassData_CH(FPgNo,Common.Path.Ini + format('GlassData_CH%d.dat',[FPgNo +1]));
//      SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,format('SetGlassData : 4 %d',[FPgNo]),'',10);
      ReturnOutputArg(wdRet);
    except
      ReturnOutputArg(wdRet);
    end;
  end;
end;

procedure TScrCls.ECS_EICR_Proc(AMachine: TatVirtualMachine);
var
  item: TMESItem;
  nRet: Integer;
  nNgCode: Integer;
begin
  With AMachine do begin
    if g_CommPLC = nil then begin
      ReturnOutputArg(0);
      Exit;
    end;
		case InputArgCount of
      2 : begin
        try
          TestInfo.SerialNo  := GetInputArgAsString(0);

          if not Common.StatusInfo.LogIn then begin
            Common.MLog(self.FPgNo, 'ECS_EICR SKIP - OFF');
            ReturnOutputArg(0);
            Exit;
          end;

          nNgCode:= GetInputArgAsInteger(1);

          //MES 관련은 순차적으로 처리
          item.Kind:= COMMPLC_MES_KIND_EICR;
          item.NotifyEvent:= ECS_NotifyEvent;

          item.Value.Channel:= FPgNo;
          ResetEvent(m_MESItemValue.EventHandle);
          item.Value.EventHandle:= m_MESItemValue.EventHandle;
          item.Value.SerialNo:= TestInfo.SerialNo;
          item.Value.ErrorCode:= TestInfo.MES_Code;
          item.Value.InspectionResult:= IntToStr(nNgCode); //TestInfo.Result;

          g_CommPLC.ECS_MES_AddItem(item);

          nRet := WaitForSingleObject(m_MESItemValue.EventHandle, 30000);
          //TestInfo.NG_EICR:= True;
          case nRet of
            WAIT_OBJECT_0 : begin
              //OK
              if m_MESItemValue.Ack = 0 then begin
                //TestInfo.NG_EICR:= False;
                Common.MLog(self.FPgNo, 'ECS_EICR OK');
              end
              else begin
                Common.MLog(self.FPgNo, format('ECS_EICR NG %d ', [m_MESItemValue.Ack]));
                nRet:= m_MESItemValue.Ack;
              end;
            end;
            WAIT_TIMEOUT  : begin
              Common.MLog(self.FPgNo, 'ECS_EICR Timeout');
            end
            else begin
              Common.MLog(self.FPgNo, format('ECS_EICR Fail Ret:%d ', [nRet]));
            end;
          end;
        except on E : Exception do begin
            Common.MLog(Self.FPgNo,'ECS_EICR Exception: ' + E.Message);
            nRet := 1;
          end
        end;
        //nRet:= g_CommPLC.ECS_EICR(FPgNo, TestInfo.SerialNo, TestInfo.MES_Code, TestInfo.CarrierId, TestInfo.Result);
      end  //2 : begin
      else begin
        nRet := WAIT_OBJECT_0;
      end;
    end;
    ReturnOutputArg(nRet);
  end;
end;

procedure TScrCls.ECS_APDR_Proc(AMachine: TatVirtualMachine);
var
  nRet: Integer;
  sTemp : string;
  item: TMESItem;
  nNgCode: Integer;
begin
  With AMachine do begin
    if g_CommPLC = nil then begin
      ReturnOutputArg(0);
      Exit;
    end;
		case InputArgCount of
      1 : begin
        //TestInfo.InsApdr         := VarToObject(GetInputArg(0)) as TInsApdr;
        TestInfo.ApdrData := MakeApdrData;
        //TestInfo.ApdrData := ExecExtraFunction('MakeApdrData');

         if not Common.StatusInfo.LogIn then begin
          Common.MLog(self.FPgNo, 'ECS_APDR SKIP - OFF');
          ReturnOutputArg(0);
          Exit;
        end;

        //MES 관련은 순차적으로 처리
        item.Kind:= COMMPLC_MES_KIND_APDR;
        item.NotifyEvent:= ECS_NotifyEvent;

        item.Value.Channel:= FPgNo;
        ResetEvent(m_MESItemValue.EventHandle);
        item.Value.EventHandle:= m_MESItemValue.EventHandle;
        //item.Value.SerialNo:= TestInfo.SerialNo;
        //item.Value.ErrorCode:= TestInfo.MES_Code;

        //item.Value.InspectionResult:= StringReplace(TestInfo.ApdrData, ' ', '_', [rfReplaceAll]);
        item.Value.InspectionResult:= TestInfo.ApdrData;

        g_CommPLC.ECS_MES_AddItem(item);
        nRet := WAIT_OBJECT_0; //응답 기다리지 않음

        (*
        nRet := WaitForSingleObject(m_MESItemValue.EventHandle, 30000);
        case nRet of
          WAIT_OBJECT_0 : begin
            //OK
            if m_MESItemValue.Ack = 0 then begin
              Common.MLog(self.FPgNo, 'ECS_APDR OK');
            end
            else begin
              Common.MLog(self.FPgNo, format('ECS_APDR NG %d ', [m_MESItemValue.Ack]));
              nRet:= m_MESItemValue.Ack;
            end;
          end;
          WAIT_TIMEOUT  : begin
            Common.MLog(self.FPgNo, 'ECS_APDR Timeout');
          end
          else begin
            Common.MLog(self.FPgNo, format('ECS_APDR Fail Ret:%d ', [nRet]));
          end;
        end;
        *)
      end //1 : begin
      else begin
        nRet := WAIT_OBJECT_0;
      end;
    end;
    ReturnOutputArg(nRet);
  end;
end;

procedure TScrCls.ECS_ZSET_Proc(AMachine: TatVirtualMachine);
var
  nRet: Integer;
  sTemp : string;
begin
  With AMachine do begin
		case InputArgCount of
      1 : begin
        TestInfo.SerialNo  := GetInputArgAsString(0);
        if g_CommPLC <> nil then begin
          //nRet:= g_CommPLC.ECS_ZSET(TestInfo.SerialNo, sValue);
        end
        else begin
          nRet := WAIT_OBJECT_0;
        end;
      end;
    end;
    ReturnOutputArg(nRet);
  end;
end;

procedure TScrCls.SendPocbDataWrite_Proc(AMachine: TatVirtualMachine);
var
  nRet, nMode, nSize, nParam1, nParam2, nParam3 : Integer;
begin
  nRet := -1;
  With AMachine do begin
//
//    if InputArgCount = 5 then begin
//      nMode := GetInputArgAsInteger(0);
//      nSize := GetInputArgAsInteger(1);
//      nParam1 := GetInputArgAsInteger(2);
//      nParam2 := GetInputArgAsInteger(3);
//      nParam3 := GetInputArgAsInteger(4);
//      nRet := Pg[FPgNo].SendPocbDataWrite(nMode, nSize, nParam1, nParam2, nParam3 );
//    end;
//    ReturnOutputArg( nRet);
  end;

end;

procedure TScrCls.SendPocbHexFile2_Proc(AMachine: TatVirtualMachine);
var
  nRet, nMode, nSize, nSubSize, nSubIdx, nParam1, nParam2, nParam3, nParam4, nParam5 : Integer;
  sFileName, sDebug : string;
  txBuf, rxBuf, rxSubBuf  : TIdBytes;
  Stream: TMemoryStream;
  i, j, nDiv, nTotalSize, nMod, nTotalMod : Integer;
  wdRet : Integer;
  fi : TFileStream;
begin
  nRet := -1;
  With AMachine do begin
  end;
end;

procedure TScrCls.SendPocbHexFile_Proc(AMachine: TatVirtualMachine);
var
  nRet, nMode, nSize, nParam1, nParam2, nParam3, nParam4 : Integer;
  sFileName, sDebug : string;
  sHexCS: string;
  txBuf, rxBuf  : TIdBytes;
  Stream: TMemoryStream;
  i, nDiv, nTotalSize, nMod : Integer;
  fi : TFileStream;
begin
  nRet := -1;
end;

procedure TScrCls.SendMainGuiDisplay(nGuiMode, nP1, nP2, nP3: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData     : RGuiScript;
begin
  GuiData.MsgType := DefCommon.MSG_TYPE_SCRIPT;
  GuiData.Channel := self.FPgNo;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam  := nP1;
  GuiData.nParam2 := nP2;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_MainHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TScrCls.SendTestGuiDisplay(nGuiMode: Integer; sMsg, sMsg2: string; nParam, nParam2: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiScript;
begin
  GuiData.MsgType := defCommon.MSG_TYPE_SCRIPT;
  GuiData.Channel := self.FPgNo;
  GuiData.Mode    := nGuiMode;
  GuiData.Msg     := sMsg;
  GuiData.Msg2    := sMsg2;
  GuiData.nParam  := nParam;
  GuiData.nParam2 := nParam2;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_TestHandle,WM_COPYDATA,0, LongInt(@ccd));
end;


procedure TScrCls.SendTestGuiDisplay(nMsgType, nGuiMode: Integer; sMsg, sMsg2: string; nParam, nParam2: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiScript;
begin
  GuiData.MsgType := nMsgType;
  GuiData.Channel := self.FPgNo;
  GuiData.Mode    := nGuiMode;
  GuiData.Msg     := sMsg;
  GuiData.Msg2    := sMsg2;
  GuiData.nParam  := nParam;
  GuiData.nParam2 := nParam2;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_TestHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TScrCls.SendTouchInfo_Proc(AMachine: TatVirtualMachine);
var
  nSeq : Integer;
  sTD, sName : String;
begin
  With AMachine do begin
    nSeq  := GetInputArgAsInteger(0);
    sTd   := GetInputArgAsString(1);
    sName := GetInputArgAsString(2);
    SendTestGuiDisplay(DefCommon.MSG_MODE_TOUCH_INFO, sTd, sName, nSeq);
  end;
end;

procedure TScrCls.SendTouchResult_Proc(AMachine: TatVirtualMachine);
var
  nSeq, nResult : Integer;
begin
  With AMachine do begin
    nSeq    := GetInputArgAsInteger(0);
    nResult := GetInputArgAsInteger(1);
    SendTestGuiDisplay(DefCommon.MSG_MODE_TOUCH_RESULT,'','', nSeq, nResult);
  end;
end;



procedure TScrCls.SetAgingTm_Proc(AMachine: TatVirtualMachine);
var
  nTimerType, nTime: Integer;
  nMM, nSS: Integer;
  sMsg: string;
begin
  With AMachine do
  begin
    // nTimerType : 0 ==> Display Off. 1 ==> Counter, 2 ==> Timer.
    nTimerType := GetInputArgAsInteger(0);
    nTime := GetInputArgAsInteger(1);
    sMsg := '';
    case nTimerType of
      1:
        sMsg := format('%d', [nTime]);
      2:
        begin
          nSS := nTime mod 60;
          nMM := nTime div 60;
          sMsg := format(' %0.2d : %0.2d', [nMM, nSS]);
        end;
    end;
    SendTestGuiDisplay(DefCommon.MSG_MODE_ANGING_TIME, sMsg, '', nTimerType);
  end;
end;

procedure TScrCls.SetBCRData;
begin
  if m_bIsBCREvent then begin
    SetEvent(m_hBCREvnt);
  end;
end;

// 1 : Set Memory Ch, 2, Display R or G or B(0: Black, 1 : White, 2 : Red, 3 : Green, 4 : Blue)
// 3 : Delay time from display patten To Measurement of CA310.
// 4,5,6 : x, y, Lv to output.
procedure TScrCls.SetCa310MemoryCh_Proc(AMachine: TatVirtualMachine);
var
  nMemCh, wdRet : Integer;
  nJig : Integer;
  sDebug : string;
begin
  With AMachine do begin
    wdRet := 1;
{$IFDEF ISPD_L_OPTIC}
    if InputArgCount = 1 then begin
      nMemCh  :=  GetInputArgAsInteger(0);
      nJig := Self.FPgNo div 4;
      DongaCa310[nJig].SetMemCh(nMemCh);
      sDebug := Format('Set CA310 Memory Channel as %d',[nMemCh]);
      common.MLog(self.FPgNo,sDebug);
    end;
{$ENDIF}
    ReturnOutputArg( Integer(wdRet));
  end;
end;


procedure TScrCls.SetConfirmRty_Proc(AMachine: TatVirtualMachine);
begin
  With AMachine do begin
    if InputArgCount = 1 then begin
      SendTestGuiDisplay(DefCommon.MSG_MODE_FOR_RTY_MAKE_ALL_NG,'');
    end;
  end;
end;

procedure TScrCls.SetCurJigChForPass_Proc(AMachine: TatVirtualMachine);
begin
  with Amachine do begin
    m_OcParam         := VarToObject(GetInputArg(0)) as TOcParamsWR;
    m_OcParam.FCurJig := Self.FPgNo div 4;
    m_OcParam.FCurCh  := Self.FPgNo;
  end;
end;


procedure TScrCls.SetDioEvent;
begin
  if m_bIsDioEvent then begin
    SetEvent(m_hDioEvnt);
  end;
end;

procedure TScrCls.SetGetPatGrp(const Value: TPatterGroup);
begin
  FGetPatGrp := Value;
end;

procedure TScrCls.SetHandleAgain(hMain, hTest: HWND);
begin
  m_MainHandle := hMain;
  m_TestHandle := hTest;
end;

procedure TScrCls.SethDisplay(const Value: HWND);
begin
  FhDisplay := Value;
end;

procedure TScrCls.SetHostEvent(nRet : Integer);
begin
  if m_bIsSyncEvent then begin
    m_nHostResult := nRet;
    SetEvent(m_hSyncEvnet);
  end;
end;

procedure TScrCls.SetInit_Proc(AMachine: TatVirtualMachine);
var
  nParam : Integer;
begin
  With AMachine do begin
		Case InputArgCount of
      1 : begin
        m_InsStatus := isRun;
        nParam :=  GetInputArgAsInteger(0);
        case nParam of
          1 : InitialData;
          2 : SendTestGuiDisplay(DefCommon.MSG_MODE_CH_CLEAR);
          3 : begin
            InitialData;
            SendTestGuiDisplay(DefCommon.MSG_MODE_CH_CLEAR);
          end;
          4 : m_InsStatus := isStop;
        end;
        m_bIsSyncEvent := False;
      end;
    End;
  end;
end;

//procedure TScrCls.SetRxData(const Value: TRxData);
//begin
//  FRxData := Value;
//end;

procedure TScrCls.Set_Cam_Cmd_Proc(AMachine: TatVirtualMachine);
var
  dRet      : Integer;
  sCmd        : String;
  nWait, nDisconnect       : Integer;
  nIgnoreWait : Integer;
  nCamCh      : Integer;
  sRecvData, sFFCData: String;

begin
  With AMachine do begin
    dRet := -1;
    if InputArgCount in [3,4,5] then begin
      sCmd := Trim(GetInputArgAsString(0));
      nWait := GetInputArgAsInteger(1) * 1000;      //3,0,1
      nDisconnect := GetInputArgAsInteger(2);  // 0 : not disconnect, 1 : disconnect.
      nIgnoreWait := 0;
      if InputArgCount = 4 then nIgnoreWait := GetInputArgAsInteger(3);

      nCamCh :=  Self.FPgNo mod (DefCommon.MAX_PG_CNT div DefCommon.MAX_JIG_CNT);
{$IFDEF ISPD_POCB}
      dRet := CommCamera.SendCommand(nCamCh,sCmd,nWait);
      if dRet <> 0 then begin
        m_sNgMsg:= StringReplace(CommCamera.CommandData[nCamCh].ErrorMsg, ',', '/', [rfReplaceAll]);
      end;

      //if InputArgCount > 4 then begin
        sRecvData:= StringReplace(CommCamera.CommandData[nCamCh].RecvData, ',', '/', [rfReplaceAll]);
        SetInputArg(4, sRecvData); //결과 값 반환
      //end;
{$ENDIF}
    end;
    ReturnOutputArg( dRet);
  end;
end;


procedure TScrCls.SendLightCommand_Proc(AMachine: TatVirtualMachine);
var
  nCh, nValue1, nValue2: Integer;
  bResult: Boolean;
  sMsg: string;
begin
  bResult:= False;
  With AMachine do begin
    if InputArgCount in [3] then begin

      nCh := GetInputArgAsInteger(0);  //nCh
      nValue1 := GetInputArgAsInteger(1); //조명1 밝기. 0 ~ 255
      nValue2 := GetInputArgAsInteger(2); //조명2 밝기. 0 ~ 255

//{$IFDEF ISPD_POCB}
//      bResult:= CamComm.SendLightCommand(nCh, nValue1, nValue2);
//{$ENDIF}
    end;
    if bResult then
      sMsg:= Format('SendLightCommand: OK, Ch:%d, Value1:%d, Value2:%d', [nCh, nValue1, nValue2])
    else
      sMsg:= Format('SendLightCommand: NG, Ch:%d, Value1:%d, Value2:%d', [nCh, nValue1, nValue2]);
    SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, sMsg,'',0);

    ReturnOutputArg( bResult);
  end;
end;


procedure TScrCls.SendLPIR_Proc(AMachine: TatVirtualMachine);
var
  wdRet : Integer;
  sTemp,sProcesssCode : string;
begin
  With AMachine do begin
    wdRet := 1;
		Case InputArgCount of
      2 : begin
        TestInfo.SerialNo  := GetInputArgAsString(0);
        sProcesssCode := GetInputArgAsString(1);
        SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER,TestInfo.SerialNo);

        if not Common.StatusInfo.LogIn then begin
//          Common.MLog(self.FPgNo, 'LPIR SKIP - OFF');
          SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'LPIR SKIP - OFF');
          ReturnOutputArg(0);
          Exit;
        end;

        m_bMesPMMode := True;
        if DongaGmes <> nil then begin
          m_bMesPMMode := False;
          wdRet := CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(DefGmes.MES_LPIR,1);
            SendTestGuiDisplay(DefGmes.MES_LPIR, '','', 0);
          end,5000,1);
          if wdRet = WAIT_OBJECT_0 then begin
            wdRet :=  m_nHostResult;
            //TestInfo.RTN_PID:= m_sMesPchkRtnPID;
            TestInfo.Process_Code:= DongaGMes.MesData[Self.FPgNo].LpirProcessCode;
            SetInputArg(1,TestInfo.Process_Code);
          end;

        end
        else begin
          wdRet := WAIT_OBJECT_0;
        end;
      end;
    End;
    ReturnOutputArg( wdRet);
  end;
end;

procedure TScrCls.ShowSerial_Proc(AMachine: TatVirtualMachine);
var
  sSerialNo: String;
begin
  With AMachine do begin
		Case InputArgCount of
      1 : begin
        sSerialNo  := GetInputArgAsString(0);
        SendTestGuiDisplay(DefCommon.MSG_MODE_SHOW_SERIAL_NUMBER, sSerialNo);
      end;
    end;
  end;
end;

procedure TScrCls.ShowCurStaus_Proc(AMachine: TatVirtualMachine);
var
  nResult, nDefault, nLog : Integer;
  sMsg : String;
begin
  With AMachine do begin
    if InputArgCount in [1,2, 3] then begin
      sMsg := GetInputArgAsString(0);
      nDefault := 0;
      if InputArgCount >= 2 then begin
        nDefault := GetInputArgAsInteger(1);
        if nDefault = 3 then begin
          //Show Process_Error
          nDefault:= 2; //clMaroon 강조. Error
          sMsg:= Format('%0.2d NG-%s',[m_nNgCode, Common.GmesInfo[m_nNgCode].sErrCode]);
        end;
      end;
      if InputArgCount >= 3 then begin
        nLog:= GetInputArgAsInteger(2);
        if nLog = 10 then begin
          SendDisplayGuiDisplay(defCommon.MSG_MODE_WORKING, 10, sMsg);  //저장만 남김
        end
        else begin
          SendDisplayGuiDisplay(defCommon.MSG_MODE_WORKING, 1, sMsg);  //로그 남기고 저장
        end
      end;
      SendTestGuiDisplay(defCommon.MSG_MODE_CH_RESULT, sMsg,'', -1, nDefault); // 0: OK, 1 : NG, -1 : Just Display current testing status.
    end;
  end;
end;

procedure TScrCls.ShowResult_Proc(AMachine: TatVirtualMachine);
var
  nResult, nSkipResult : Integer;
  i: integer;
  sRet, sParam: String;
  sMsg : String;
begin
  With AMachine do begin
    nResult := GetInputArgAsInteger(0); //NgCode
    sMsg := GetInputArgAsString(1);
//    nSkipResult := 0 ;
    if InputArgCount = 3 then nSkipResult := GetInputArgAsInteger(2);

    m_InsStatus := isStop;


    TestInfo.NgCode:= nResult;

    m_lstPrevRet.Insert(0, nResult);
    if m_lstPrevRet.Count > Common.SystemInfo.NGAlarmCount then
      m_lstPrevRet.Delete(Common.SystemInfo.NGAlarmCount);

    if nResult <> 0 then begin
      TestInfo.Result :=  Format('%0.2d NG', [nResult]); //Common.GmesInfo[nResult].sErrCode; //Format('PD%0.2d',[nResult]);// 'FAIL';

      TestInfo.ERR_Code:= Common.GmesInfo[nResult].sErrCode;
      TestInfo.ERR_Message := Common.GmesInfo[nResult].sErrMsg+ ' ('+m_sNgMsg+')';
      TestInfo.MES_Code := Common.GmesInfo[nResult].MES_Code;

//      if nSkipResult = 0 then begin
//        //SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'mes code : '+ Common.GmesInfo[nResult].MES_Code,'',10 );
//        //SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'Ng code : '+ IntToStr(nResult),'',10 );
//        //SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,'Ng Message : '+ Common.GmesInfo[nResult].sErrMsg,'',10 );
//        SendTestGuiDisplay(DefCommon.MSG_MODE_WORKING,Format('NG Code:%d, ErrCode:%s, MES Code:%s, Message:%s',[nResult, TestInfo.ERR_Code, Common.GmesInfo[nResult].MES_Code, TestInfo.ERR_Message]),'', 10 );
      Inc(TestInfo.NGCount);

//      end;

    end
    else begin
      TestInfo.Result := 'PASS';
      TestInfo.ERR_Code:= '';
      TestInfo.ERR_Message := '';
      TestInfo.MES_Code := '';

//      if nSkipResult = 0 then begin
      Inc(TestInfo.OKCount);
//      end;

    end;
    SendTestGuiDisplay(defCommon.MSG_MODE_CH_RESULT, sMsg,'', nResult);  // 0: OK, 0 < nResult : NG.
    SendTestGuiDisplay(DefCommon.MSG_MODE_PRODUCT_CNT,'','',TestInfo.OKCount, TestInfo.NGCount);
  end;

end;

procedure TScrCls.Sleep_Proc(AMachine: TatVirtualMachine);
var
  nMili : Integer;
begin
  With AMachine do begin
		Case InputArgCount of
      1 : begin
        nMili :=  GetInputArgAsInteger(0);
        if nMili > 0 then Sleep(nMili);
      end;
    End;
  end;
end;

procedure TScrCls.FileExists_Proc(AMachine: TatVirtualMachine);
var
  sParam: String;
begin
  With AMachine do begin
    sParam:= GetInputArgAsString(0);

    if FileExists(sParam) then begin
      ReturnOutputArg(0);
    end
    else begin
      ReturnOutputArg(1);
    end;
  end;
end;

procedure TScrCls.FinishScript;
begin
  RunSeq(DefScript.SEQ_UNLOAD_ZONE);
end;

procedure TScrCls.DirectoryExists_Proc(AMachine: TatVirtualMachine);
var
  sParam: String;
begin
  With AMachine do begin
    sParam:= GetInputArgAsString(0);

    if DirectoryExists(sParam) then begin
      ReturnOutputArg(0);
    end
    else begin
      ReturnOutputArg(1);
    end;
  end;
end;

procedure TScrCls.ForceDirectories_Proc(AMachine: TatVirtualMachine);
var
  sParam: String;
begin
  With AMachine do begin
    sParam:= GetInputArgAsString(0);

    if ForceDirectories(sParam) then begin
      ReturnOutputArg(0);
    end
    else begin
      ReturnOutputArg(1);
    end;
  end;
end;

procedure TScrCls.StopMaintScript;
begin
  if atPasScrptMaint.Running then begin
    atPasScrptMaint.Halt;
  end;
end;

procedure TScrCls.StopManualKey;
begin
  m_InsStatus := isStop;
  ResetScriptStatus;
end;

procedure TScrCls.StrReplace_Proc(AMachine: TatVirtualMachine);
var
  nParam : Integer;
  sData, sDataFrom, sDataTo, sResult : string;
begin
  sResult := '';
  With AMachine do begin
    if InputArgCount = 3 then begin
      sData :=  GetInputArgAsString(0);
      sDataFrom :=  GetInputArgAsString(1);
      sDataTo :=  GetInputArgAsString(2);

      sResult := StringReplace(sData, sDataFrom, sDataTo, [rfReplaceAll]);
    end;
    ReturnOutputArg( sResult);
  end;
end;

function GetTimeDiffSec(StartTimne,EndTime: TDateTime): Integer;
var
  diffmsec : Integer;
begin
  diffmsec := SecondsBetween(StartTimne,EndTime);
  RESULT := diffmsec;
end;



procedure TScrCls.TactTime_Proc(AMachine: TatVirtualMachine);
var
  nParam : Integer;
begin
  With AMachine do begin
		Case InputArgCount of
      1 : begin
        nParam := GetInputArgAsInteger(0);
        case nParam of
          1 : begin
              TestInfo.StartTime  := Now;
              TestInfo.StUnitTact := 0;   // 초기화
              TestInfo.EdUnitTact := 0;
              //TestInfo.StartTime:= Now;
              SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, 'Total Tact Time : Start!!! [0s]','',0);
            end;
          2 : begin
              TestInfo.EndTime    := Now;
              SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, format('Total Tact Time : End!!! [%ds]',[GetTimeDiffSec(TestInfo.StartTime,TestInfo.EndTime)]),'',0);
              //TestInfo.EndTime:= Now;
            end;
          3 : begin
              TestInfo.StUnitTact := Now;
              SendTestGuiDisplay(defCommon.MSG_MODE_WORKING, 'Measure Tact Time : Start!!! [0s]','',0);
              //TestInfo.StUnitTact:= Now;
            end;
          4 : begin
              TestInfo.EdUnitTact := Now;
              //TestInfo.EdUnitTact:= Now;
            end;
        end;

        case nParam of
          1 : m_bTotalTact   := True;
          2 : m_bTotalTact   := False;
          3 : m_bUnitiTact   := True;
          4 : m_bUnitiTact   := False;
        end;

        case nParam of
          1 : SendTestGuiDisplay(DefCommon.MSG_MODE_TACT_START);
          2 : SendTestGuiDisplay(DefCommon.MSG_MODE_TACT_END);
          3 : SendTestGuiDisplay(DefCommon.MSG_MODE_UNIT_TT_START);
          4 : SendTestGuiDisplay(DefCommon.MSG_MODE_UNIT_TT_END);
        end;

      end;
    End;
  end;
end;

procedure Delay(msec: longint);
var
  FirstTickCount: longint;
  LastTickCount : longint;
begin
  if msec <= 0 then Exit;
  FirstTickCount := GetTickCount;
  repeat
    Application.ProcessMessages;
    Sleep(1);
    LastTickCount := GetTickCount;
  until ((LastTickCount-FirstTickCount) >= msec);
end;

procedure TScrCls.TerminateScript;
var
  i: Integer;
begin
  m_bIsSyncSeq := False;
  if m_bCallTerminate then begin
    ScriptThread('Seq_Terminate',0);
  end;
  for i := 0 to 200 do begin
    Delay(10);
//    Sleep(10);
    if not m_bTheadIsTerminated then Break;
  end;
end;

procedure TScrCls.WriteDio_Proc(AMachine: TatVirtualMachine);
var
  nPos, nVal,nCh : Integer;
  wdRet  : DWORD;
  bOff : boolean;
  nCount : Integer;
begin
  bOff := False;
  With AMachine do begin
    wdRet := 1 ; // Return NG.
		Case InputArgCount of
      2,3 : begin
        nPos :=  GetInputArgAsInteger(0);
        nVal :=  GetInputArgAsInteger(1);
        if CommDaeDIO <> nil then begin
          nCount := nPos div 8;
          nPos   := nPos mod 8;
          wdRet := CommDaeDIO.WriteDO_Bit(nCount,nPos,nVal);
        end;

//      {$IFDEF ISPD_A}
//        if (nPos = 4) and (nVal = 1) then Logic[FPgNo].m_InsStatus := IsRun;
//        // DIO Open 신호는 Test Form에서 처리
//        if (nPos in [0, 7]) and (nVal = 1) then begin
//          SendTestGuiDisplay(DefCommon.MSG_MODE_DIO_CONTROL, '','', nPos);
//          Exit; // Test Form에 Message 보내고 나가기
//        end;
//      {$ENDIF}
      end;
    End;
    ReturnOutputArg(wdRet);
  end;
end;

procedure TScrCls.SetDio64_Proc(AMachine: TatVirtualMachine);
var
  nPos, nCh : Integer;
  bVal  : Boolean;
  wdRet : Integer;
begin
  With AMachine do begin
    wdRet := 1 ; // Return NG
    nCh   := 0;
		Case InputArgCount of
      2,3 : begin
        nPos :=  GetInputArgAsInteger(0);
        bVal :=  GetInputArgAsBoolean(1);
        if (InputArgCount = 3) then nCh := GetInputArgAsInteger(2);
{$IFDEF DIO_60CH}
        wdRet := AxDio.SetDio64(nPos,bVal);  //OPTIC-GIB
{$ENDIF}
        Sleep(10);
      end;
    End;
    ReturnOutputArg(wdRet);
  end;
end;

procedure TScrCls.GetDio64_Proc(AMachine: TatVirtualMachine);
var
  nPos, nCh : Integer;
  nVal  : Integer;
  //wdRet : Integer;
begin

  With AMachine do begin
    nCh   := 0;
		Case InputArgCount of
      1, 2 : begin
        nPos :=  GetInputArgAsInteger(0);
        if (InputArgCount = 2) then nCh := GetInputArgAsInteger(1);
        nVal := 0;
{$IFDEF DIO_60CH}
        if (AxDio.m_bInDio[nPos]) then nVal := 1
        else                           nVal := 0;
{$ENDIF}
      end;
    End;
    ReturnOutputArg(nVal);
  end;
end;

// e.g, SetHandBCR(BindType#);  // BindType#: 0(Ignore) 1(Receive from Ch0)
procedure TScrCls.SetHandBCR_Proc(AMachine: TatVirtualMachine);  //GIB-OPTIC:HANDBCR 2018-08-05
var
  nJig, nBind, nCh : Integer;
  wdRet  : DWORD;
begin
  With AMachine do begin
    nBind := GetInputArgAsInteger(0); // 0:Ignore, 1:Receive from Ch0
    nJig := Self.FPgNo div 4;
    SendTestGuiDisplay(DefCommon.MSG_MODE_BARCODE_READY,'','',nBind, 0);
  end;

end;

procedure TScrCls.GrayScale_Proc(AMachine: TatVirtualMachine);
var
i,nDBVValue,nWaitMS,nRetry,wdRet,mBand_Count : Integer;
m_Ca410Data: TBrightValue;
sFilePath,sFileCsv : string;
sDataHeader, sData,sSerialNo : string;
nSX,nSy,nEX,nEY : Integer;

begin
  With AMachine do begin
    mBand_Count := GetInputArgAsInteger(0);
    sFileCsv :=  format('%s_CH%d_%dband_GrayScale_',[Common.SystemInfo.EQPId,FPgNo+1,mBand_Count]) + formatDateTime('yyMMddHHmmss',now) + '.csv';
    sSerialNo := TestInfo.SerialNo;
    sSerialNo := Format('sSerialNo : %s',[sSerialNo]);
    sDataHeader := 'DBV,GRAY,x,y,LV,';

    nWaitMS := 3000;
    nRetry  := 0;  // No Retry
  //  Sleep(1000);
  //  nDBVValue := BandDBV[mBand_Count-1];
  //  wdRet := Pg[nFPgNo].SendDimmingBist(BandDBV[mBand_Count-1], nWaitMS,nRetry);  //2019-10-11 DIMMING (SendDisplayPat -> SendDisplayPWMPat)
    Sleep(1000);
    for I := 511 downto 1 do begin
      if m_bCEL_Stop then exit;

      if (mBand_Count = 1) or (mBand_Count = 2) then begin
        Common.GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,mBand_Count,nSX,nSy,nEX,nEY);
        wdRet := Pg[FPgNo].DP860_SendBistAPL(i,i,i,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
        if i = 511 then begin
           wdRet := Pg[FPgNo].SendDimmingBist(Common.m_GetDBV[mBand_Count-1], nWaitMS,nRetry);
        end;
      end
      else begin
       wdRet := Pg[FPgNo].SendDisplayPatBistRGB_9Bit(i,i,i,nWaitMS,nRetry);
        if i = 511 then begin
           wdRet := Pg[FPgNo].SendDimmingBist(Common.m_GetDBV[mBand_Count-1], nWaitMS,nRetry);
        end;
      end;
      Sleep(100);
      wdRet := CaSdk2.Measure(FPgNo, m_Ca410Data);

      if m_bCEL_Stop then exit;
      sData := Format('%d,%d,%4.4f,%4.4f,%4.4f,',[Common.m_GetDBV[mBand_Count-1],i,m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
      Common.SaveCsvMeasureLog(FPgNo,sFileCsv,sSerialNo,sDataHeader,sData);
    end;
  end;

end;

procedure TScrCls.DBVtracking_Proc(AMachine: TatVirtualMachine);
var
i,nDBVValue,nWaitMS,nRetry,wdRet,nRGBIdx : Integer;
m_Ca410Data: TBrightValue ;
sFilePath : string;
sDataHeader, sData,sSerialNo,sFileCsv : string;
nSX,nSy,nEX,nEY : Integer;
begin
  With AMachine do begin
    nRGBIdx := GetInputArgAsInteger(0);
    sFileCsv :=  format('%s_CH%d_Gray_%d_DBVtracking_',[Common.SystemInfo.EQPId,FPgNo+1,nRGBIdx]) + formatDateTime('yyMMddHHmmss',now) + '.csv';
    sSerialNo := TestInfo.SerialNo;
    sSerialNo := Format('sSerialNo : %s',[sSerialNo]);
    sDataHeader := 'Gray,DBV,x,y,LV,';

    nWaitMS := 3000;
    nRetry  := 0;  // No Retry
    wdRet := Pg[FPgNo].SendDimmingBist(180, nWaitMS,nRetry); // DBV 값 초기화
    for I := 2047 downto 1 do begin
      if m_bCEL_Stop then exit;
      if i = 2047 then       //APL 40%  1Band
      begin
        Common.GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,1,nSX,nSy,nEX,nEY);
        wdRet := Pg[FPgNo].DP860_SendBistAPL(nRGBIdx,nRGBIdx,nRGBIdx,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
      end
      else if i = 1850 then //APL 60% 2Band
      begin
        Common.GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,2,nSX,nSy,nEX,nEY);
        wdRet := Pg[FPgNo].DP860_SendBistAPL(nRGBIdx,nRGBIdx,nRGBIdx,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
      end
      else if i = 1644 then
      begin
        wdRet := Pg[FPgNo].SendDisplayPatBistRGB_9Bit(nRGBIdx,nRGBIdx,nRGBIdx,nWaitMS,nRetry);
      end;
      Sleep(100);

      wdRet := Pg[FPgNo].SendDimmingBist(i, nWaitMS,nRetry);
      Sleep(100);
      wdRet := CaSdk2.Measure(FPgNo, m_Ca410Data);
      if m_bCEL_Stop then exit;
      sData := Format('%d,%d,%4.4f,%4.4f,%4.4f,',[nRGBIdx,i,m_Ca410Data.xVal,m_Ca410Data.yVal,m_Ca410Data.LvVal]);
      Common.SaveCsvMeasureLog(FPgNo,sFileCsv,sSerialNo,sDataHeader,sData);
    end;

  end;
end;




procedure TScrCls.CELYufeng_Proc(AMachine: TatVirtualMachine);
var
sSerialNo,sDataHeader,sData,sFileCsv : string;
output : TArray<Double>;
nDBV,nFind_Gray_index,nGray,nSearch_Lv : Integer;
nSX,nSy,nEX,nEY,nWaitMS,nRetry,wdRet : integer;
m_Ca410Data: TBrightValue ;
fIdeal_Target_Lv,fSearch_Lv : Double;

begin
  With AMachine do begin
    nSearch_Lv := GetInputArgAsInteger(0);
    fSearch_Lv := nSearch_Lv/10;
    sSerialNo := TestInfo.SerialNo;
    sFileCsv :=  format('%s_CH%d_CEL_NY_%f_GrayScale_',[copy(sSerialNo,1,25),FPgNo+1,fSearch_Lv]) + formatDateTime('yyMMddHHmmss',now) + '.csv';
    sSerialNo := Format('sSerialNo : %s',[sSerialNo]);
    sDataHeader := 'DBV,DBV_Nits,Gray,Measure_Lv,x,y';


    nWaitMS := 3000;
    nRetry  := 0;  // No Retry

    SetLength(output,2);

    wdRet := Pg[FPgNo].SendDimmingBist(180, nWaitMS,nRetry); // DBV 값 초기화

    for nDBV := 180 to 2047 do begin
      if m_bCEL_Stop then exit;
      output := Common.Find_Gray_index_Near_Target(nDBV,fSearch_Lv);
      if output[1] = -1 then continue;
      nFind_Gray_index := Trunc(output[0]);
      fIdeal_Target_Lv := output[1];

      nGray := 511 - nFind_Gray_index;

      if nDBV < 1645 then       //APL 100%  1Band
      begin
        wdRet := Pg[FPgNo].SendDisplayPatBistRGB_9Bit(nGray,nGray,nGray,nWaitMS,nRetry);
      end
      else if nDBV <= 1850 then //APL 60% 2Band
      begin
        Common.GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,2,nSX,nSy,nEX,nEY);
        wdRet := Pg[FPgNo].DP860_SendBistAPL(nGray,nGray,nGray,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
      end
      else
      begin
        Common.GetBoxPtnSizeinfo(Common.TestModelInfoFLOW.ModelType,1,nSX,nSy,nEX,nEY);
        wdRet := Pg[FPgNo].DP860_SendBistAPL(nGray,nGray,nGray,nSX,nSy,nEX,nEY,nWaitMS,nRetry);
      end;
      wdRet := Pg[FPgNo].SendDimmingBist(nDBV, nWaitMS,nRetry);
      Sleep(50);
      wdRet := CaSdk2.Measure(FPgNo, m_Ca410Data);
      if m_bCEL_Stop then exit;

      sData := Format('%d,%4.4f,%d,%4.4f,%4.4f,%4.4f,',[nDBV,fIdeal_Target_Lv,nGray,m_Ca410Data.LvVal,m_Ca410Data.xVal,m_Ca410Data.yVal]);
      Common.SaveCsvMeasureLog(FPgNo,sFileCsv,sSerialNo,sDataHeader,sData);

    end;
  end;
end;

procedure TScrCls.ChangeBuff_Proc(AMachine: TatVirtualMachine);
var
  getV : Variant;
  buf : array[0..11] of Byte;
  i: Integer;
  nTemp : Integer;
begin
  with AMachine do begin

    for i := 0 to 11 do begin
      buf[i] := i;
    end;

    getV := GetInputArg(0);

    for i := 0 to 2 do begin
      nTemp := 0;
      CopyMemory(@nTemp, @buf[i*4], 4);
      getV[i] := nTemp;
    end;

    SetInputArg(0,getV);
  end;
end;


function TScrCls.CheckBCRCmdAck(nDelay, nRetry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    nRet := WAIT_FAILED;
		sEvnt := Format('BCR%d',[FPgNo]);
    m_bIsBCREvent := True;     // Create Event 했는지 확인 하는 Flag.
		m_hBCREvnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
		for i := 1 to nRetry do begin
			nRet := WaitForSingleObject(m_hBCREvnt,nDelay);
      if nRet = WAIT_OBJECT_0 then Break;
		end;
	finally
		CloseHandle(m_hBCREvnt);
    m_bIsBCREvent := False;
	end;
  Result := nRet
end;

function TScrCls.CheckCA310CmdAck(task : TProc; nDelay, nRetry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    nRet := WAIT_FAILED;
		sEvnt := Format('CA310%d',[FPgNo]);
    m_bIsCaEvent := True;     // Create Event 했는지 확인 하는 Flag.
		m_hCa310Evnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
		for i := 1 to nRetry do begin
      task;
			nRet := WaitForSingleObject(m_hCa310Evnt,nDelay);
      if nRet = WAIT_OBJECT_0 then Break;
		end;
	finally
		CloseHandle(m_hCa310Evnt);
    m_bIsCaEvent := False;
	end;
  Result := nRet
end;

function TScrCls.CheckDIOCmdAck(nDelay, nRetry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    nRet := WAIT_FAILED;
		sEvnt := Format('DIO%d',[FPgNo]);
    m_bIsDioEvent := True;     // Create Event 했는지 확인 하는 Flag.
		m_hDioEvnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
		for i := 1 to nRetry do begin
			nRet := WaitForSingleObject(m_hDioEvnt,nDelay);
      if nRet = WAIT_OBJECT_0 then begin
        if m_nDioErrCode = 2 then nRet := 2;
        Break;
      end;
		end;
	finally
		CloseHandle(m_hDioEvnt);
    m_bIsDioEvent := False;
	end;
  Result := nRet
end;

  

function TScrCls.CheckMsgCamWork(nWaitSec: Integer): DWORD;
var
	nRet  : DWORD;
	sEvnt : WideString;
begin
	try
		sEvnt := Format('SendCAM%d',[FPgNo]);
    m_nCamRet := 2;
		m_hCamEvnt := CreateEvent(nil, False, False, PWideChar(sEvnt));
    m_bCamEvnt := True;     // Create Event 했는지 확인 하는 Flag.
    nRet := WaitForSingleObject(m_hCamEvnt,nWaitSec*1000);
    if m_nCamRet = 0 then begin
      nRet := WAIT_OBJECT_0;
    end
    else begin
      nRet := m_nCamRet;
    end;
	finally
		CloseHandle(m_hCamEvnt);
    m_bCamEvnt := False;
	end;
  Result := nRet ;
end;

procedure TScrCls.CheckRetry_Proc(AMachine: TatVirtualMachine);
var
  nParam, nJigNo, nWriteData, i     : Integer;
  bFront, bLoadCarrier : Boolean;
  wdRet : Integer;
  sDebug : string;
  nStage, nPair: Integer;
begin

  With AMachine do begin
    wdRet := 0 ;
    if (FPgNo mod 2) = 0 then begin
      nPair:= FPgNo + 1;
    end
    else begin
      nPair:= FPgNo - 1;
    end;

		if InputArgCount = 1 then begin
      nParam :=  GetInputArgAsInteger(0);
      TestInfo.RetryValue:= nParam;

      if TestInfo.RetryValue = 0 then begin
        //초기화
        wdRet := 0;
        //ReturnOutputArg( wdRet);
        ReturnOutputArg( TestInfo.RetryValue + PasScr[nPair].TestInfo.RetryValue);
        Exit;
      end;

      //Retry 진행 여부 검사
      if PasScr[nPair].m_bIsScriptWork then begin  //Pair가 실행인 경우
        if (TestInfo.RetryValue = 1) and (PasScr[nPair].TestInfo.RetryValue = 1) then begin
          //둘다 OK인 경우 - Pass
          wdRet:= 2;
        end
        else if (TestInfo.RetryValue + PasScr[nPair].TestInfo.RetryValue) > 2 then begin
          //둘다 끝났고 하나라도 NG인경우 - Retry
          wdRet:= 3;
        end
        else begin
          //둘 중 하나만 끝난 경우Pair 대기
          wdRet:= 1;
        end;
      end
      else begin
        //단독 실행 - Pair 실행 안된 경우
        if (TestInfo.RetryValue = 2) then begin
          //자신이 NG인 경우 Retry
          wdRet:= 3;
        end
        else begin
          wdRet:= 2;
        end;
      end;
    end;
    ReturnOutputArg( wdRet);
  end;
end;

function TScrCls.CheckSyncCmdAck(taskPro : TProc; nDelay, nREtry: Integer): DWORD;
var
	nRet  : DWORD;
	i     : Integer;
	sEvnt : WideString;
begin
	try
    nRet := WAIT_FAILED;
		sEvnt := Format('SYNC%d',[FPgNo]);
    m_bIsSyncEvent := True;     // Create Event 했는지 확인 하는 Flag.
		m_hSyncEvnet := CreateEvent(nil, False, False, PWideChar(sEvnt));
		for i := 1 to nRetry do begin
      taskPro;
			nRet := WaitForSingleObject(m_hSyncEvnet,nDelay);
      if nRet = WAIT_OBJECT_0 then Break;
		end;
	finally
		CloseHandle(m_hSyncEvnet);
    m_bIsSyncEvent := False;
	end;
  Result := nRet;
end;

procedure TScrCls.ControlDio_Proc(AMachine: TatVirtualMachine);
var
  nParam, nJigNo, nWriteData, i,nGroup     : Integer;
  bFront, bLoadCarrier : Boolean;
  wdRet : Integer;
  sDebug : string;
begin

  With AMachine do begin
    try

      wdRet := 1 ; // Return NG.
      if InputArgCount = 1 then begin
        nParam :=  GetInputArgAsInteger(0);
        wdRet := 2;

        if Self.FPgNo <= DefCommon.CH2  then  // Added by KTS 2022-11-29 오전 11:38:59 Pre OC MovingProbeㅅgroup 설정
        nGroup := CH_TOP
        else nGroup := CH_BOTTOM;
        case nParam of

          1 : wdRet := ControlDio.UnlockCarrier(Self.FPgNo,false);
          2 : wdRet := ControlDio.lockCarrier(Self.FPgNo,false);

          3 : wdRet := ControlDio.ProbeForward(Self.FPgNo);
          4 : wdRet := ControlDio.ProbeBackward(Self.FPgNo);

          5: wdRet := ControlDio.MovingProbe(nGroup,true);
          6: wdRet := ControlDio.MovingProbe(nGroup,false);

          7: wdRet := ControlDio.UnlockPinBlock(Self.FPgNo);
          8: wdRet := ControlDio.LockPinBlock(Self.FPgNo);

          9 : wdRet := ControlDio.MovingShutter(nGroup,true);
          10 :wdRet := ControlDio.MovingShutter(nGroup,false);

          11 :wdRet := ControlDio.VaccumON(Self.FPgNo);
          12 :wdRet := ControlDio.VaccumOFF(Self.FPgNo);

          13 :wdRet := ControlDio.LampOnOff(Self.FPgNo,False);
          14 :wdRet := ControlDio.LampOnOff(Self.FPgNo,True);

          15 :wdRet := ControlDio.CLOSE_Up_PinBlock(Self.FPgNo);
          16 :wdRet := ControlDio.CLOSE_DN_PinBlock(Self.FPgNo);

          17 : wdRet := ControlDio.MovingAll(nGroup,True);
          18 : wdRet := ControlDio.MovingAll(nGroup,False);
        end;

        ReturnOutputArg( wdRet);
      end;
    except
      wdRet := 2;
      ReturnOutputArg( wdRet);
    end;
  end;

end;




function TScrCls.ConvertBufferToHex(var naBuff  : TIdBytes; nStart, nEnd: Integer; sPrefix, sDelimiter:String): String;
var
  i: Integer;
begin
  Result:= '';
  for i := nStart to nEnd do begin
    Result:= Result + sPrefix + IntToHex(naBuff[i], 2) +  sDelimiter;
  end;
end;




procedure TScrCls.ReadFlash_PUC_HexFile_RM_D(var naPUC_Data  : TIdBytes);
var
  sLine: String;
  i: Integer;
  cnt: Integer;
  txtFile : TextFile;
  //vMCS_Data, vNLA_Data, vIRA_Data, vPUC_Data, vCheckSum: VARIANT;
begin
(*
  vMCS_Data := VarArrayCreate([0, 3634], 12);
  vNLA_Data := VarArrayCreate([0, 1408], 12);
  vIRA_Data := VarArrayCreate([0, 3648], 12);
  vPUC_Data := VarArrayCreate([0, 506752], 12);
  vCheckSum := VarArrayCreate([0, 8], 12);
*)
  AssignFile(txtFile, 'NY.hex');
  Reset(txtFile);

  cnt:= 0;
  while(EOF(txtFile) = false) do begin
    //sLine:= ReadLn(txtFile);
    ReadLn(txtFile, sLine);
    if sLine = '' then continue;

    if cnt < 3634 then begin
      //if cnt < 30 then f_LogM(format('vMCS_Data[%d]=%s', [cnt,sLine]));
      //vMCS_Data[cnt]:= StrToInt('0x' + sLine);
    end
    else if (cnt >= $1000) and (cnt < 5504) then begin
      //vNLA_Data[cnt - $1000]:= StrToInt('0x' + sLine);
    end
    else if (cnt >= $2000) and (cnt < 11840) then begin
      //vIRA_Data[cnt - $2000]:= StrToInt('0x' + sLine);
    end
    else if (cnt >= $3000) and (cnt < 519040) then begin
      //if cnt < $3010 then f_LogM(format('vPUC_Data[%d]=%s', [cnt-$3000,sLine]));
      naPUC_Data[cnt - $3000]:= StrToInt('0x' + sLine);
    end
    else if (cnt >= 519040) then begin
      //vCheckSum[cnt - 519040]:= StrToInt('0x' + sLine);
      //f_LogM(format('vCheckSum[%d]=%s', [cnt - 519040, sLine]));
    end;
    inc(cnt);
  end;

  //f_LogM('ReadFlash_PUC_HexFile_RM_D Finish: ' + IntToStr(cnt) + ', Checksum=' + convert_VariantToHex(vCheckSum, 0, 7, ' '));
  //txtFile.Free;
  CloseFile(txtFile);
end;


procedure TScrCls.ReadPairNgCode_Proc(AMachine: TatVirtualMachine);
var
  nPairCh : integer;
begin
  With AMachine do begin
    if (FPgNo mod 2) = 0 then begin
      nPairCh:= FPgNo + 1;
    end
    else begin
      nPairCh:= FPgNo - 1;
    end;
    SetInputArg(0,PasScr[nPairCh].m_nNgCode);
  end;
end;


function TTestInformation.Get_MeasureTime: Integer;
begin
  Result:= SecondsBetween(OcSTime, OcETime);
end;

end.
