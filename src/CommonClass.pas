unit CommonClass;

interface

uses

  Winapi.Windows, Winapi.ShellAPI, System.Classes, System.UITypes, System.SysUtils,
  Vcl.Forms,Vcl.Dialogs, Winapi.WinSock, Vcl.StdCtrls, psAPI,System.IOUtils,IdGlobal,
  System.IniFiles,  CodeSiteLogging, StrUtils,  DefCommon, system.zip,DefPG, TLHelp32, ComObj, Variants,PdhExample,

  System.Threading, {FlexCel.Core, FlexCel.XlsAdapter,}System.Diagnostics,System.TimeSpan,RegularExpressions,

  Graphics,  IdSocketHandle, DateUtils, Winapi.ActiveX, System.Generics.Collections,
  Winapi.Messages,DongaPattern,Registry, SyncObjs,Vcl.Imaging.pngimage, Vcl.Imaging.jpeg,Math; //, AdvGrid, AdvObj, AdvGridWorkbook, , ScrMemo; //, DefScript;
{$I Common.inc}

const
  R2REODSNAME :  array[0..23] of string = ('OC_W600_X','OC_W600_Y','OC_W600_Z','OC_R600_X','OC_R600_Y','OC_R600_Z','OC_G600_X','OC_G600_Y','OC_G600_Z','OC_B600_X','OC_B600_Y','OC_B600_Z',
  'MPO_W600_L','MPO_W600_X','MPO_W600_Y','MPO_R600_L','MPO_R600_X','MPO_R600_Y','MPO_G600_L','MPO_G600_X','MPO_G600_Y','MPO_B600_L','MPO_B600_X','MPO_B600_Y');

  NVMWriteSequence = 0;
  VERSION_DLL = '3.1.7.1';   // OC_CON.DLL 적용 Ver 확인
type


  TArrayChannelString = array[0..DefCommon.MAX_CH] of String;
  TArrayChannelInteger = array[0..DefCommon.MAX_CH] of Integer;
  TArrayChannelDouble = array[0..DefCommon.MAX_CH] of Double;
  TArrayChannelBoolean = array[0..DefCommon.MAX_CH] of Boolean;

  PMsgJncd = ^RMsgJncd;
  RMsgJncd = packed record
    MsgType : Integer;
    Channel : Integer;
    Cmd     : Integer;
    Param1  : Integer;
    Msg     : string;
  end;
  PSWVer = ^TSWVer;
  TSWVer = packed record
    ConfigVer : string;
    SWVer  : string;
    DLLVer : string;
  end;

  PSystemInfo = ^TSystemInfo;
  TSystemInfo = record
    DAELoadWizardPath   : string; // Added by KTS 2022-12-27 오후 2:40:16 DAELoadWizard 설치 경로
    Password            : String;
    SupervisorPassword  : string;
    TestModel           : String;   // Test Model & ÆíÁý¿ë
    PatGrp              : string;
    LGD_DLLVER_Name      : string;
    OC_Converter_Name   : string;
    IPAddr              : TArrayChannelString; //array[0..DefCommon.MAX_CH] of String;  //PG-0
    ProbAddr            : TArrayChannelString; //array[0..DefCommon.MAX_CH] of String;
    //TestMode   : Integer; //MODE1, MODE2, MODE3, MODE4
    Com_HandBCR         : array[0..pred(Defcommon.MAX_BCR_CNT)] of Integer;  //0:None 1:COM1, 2:COM2...
    Com_RCB             : array[0..pred(Defcommon.MAX_SWITCH_CNT)] of Integer;
    Z_Motor             : Integer;
    Com_CamLight        : Integer;
    CamDelay            : Integer;
    Com_IrTempSensor    : Integer;
    SetTemperature      : Integer;
    IonizerCnt          : Integer;
    Com_Ionizer         : array[0..pred(Defcommon.MAX_IONIZER_CNT)] of Integer;
    Model_Ionizer       : array[0..pred(Defcommon.MAX_IONIZER_CNT)] of Integer;
//    Com_Ca310           : array[DefCommon.JIG_A .. Defcommon.JIG_B] of Integer;
    PGMemorySize        : Integer; // PG Memory 128Mb, 256Mb, 512Mb
    UIType              : Integer; // 0:Normal 1:Black
    OCType              : Integer;  // Added by KTS 2022-11-25 오후 2:17:39  OC/ Pre OC 구분
    ChCountUsed         : Integer;
    AutoStart           : Boolean; //자동 시작 여부
    OcManualType        : Boolean;
    ServicePort         : String;
    Network             : String;
    DaemonPort          : String;
    LocalSubject        : String;
    RemoteSubject       : String;
    EqccInterval        : String;
    EQPId_Type          : Integer;
    EQPId	  						: String;  //선택된 EQP ID
    EQPId_INLINE				: String;  //조립라인 EQP ID
    EQPId_MGIB					: String;  //MGIB EQP ID
    EQPId_PGIB					: String;  //PGIB EQP ID
    EQPId_MGIB_Process_Code : string; // LPIR 관련 Process_Code
    EQPId_PGIB_Process_Code : string; // LPIR 관련 Process_Code


    PIDLengthLimit      : Integer;
    ZIGLengthLimit      : Integer;
    Eas_Service         : string;
    Eas_Network         : string;
    Eas_DeamonPort      : string;
    Eas_LocalSubject    : string;
    Eas_RemoteSubject   : string;
    R2R_Service         : string;
    R2R_Network         : string;
    R2R_DeamonPort      : string;
    R2R_LocalSubject    : string;
    R2R_RemoteSubject   : string;
    Service_Cnt : integer;
    MES_CODE_Cnt : Integer;
    PopupMsgTime : Integer;
    PGResetDelayTime : Integer;
    PGResetTotalConut : Integer;

    MesModelInfo        : string; //PCHK에서 Model_Info 값에  사용할 모델 이름. 혼입 방지용  - LH606WF2
//    Language						: Integer;
    Loader_Index				: string;
    PowerLog						: Boolean;
    UseCh               : TArrayChannelBoolean; //array[DefCommon.CH1 .. DefCommon.MAX_CH] of Boolean;
    OffSet_Ch           : TArrayChannelDouble; //array[DefCommon.CH1 .. DefCommon.MAX_CH] of Double;
    HOST_FTP_IPAddr     : string;
    HOST_FTP_User       : string;
    HOST_FTP_Passwd     : string;
    HOST_FTP_CombiPath  : string;
    AutoBackupUse       : Boolean;
    AutoBackupList      : string;
    AutoLGDLogBackup    : Boolean;
    DLLVerInterlock     : Boolean;
    SWVerInterlock      : string;
    DLLVerInterlockList : string;
    LocalIP_GMES        : string;
    LocalIP_PLC         : string;
    PlcConfigPath       : string;
    UseManualSerial     : Boolean;
    SystemLogUse        : Boolean;
    UseAutoBCR          : Boolean;
    UseEQCC             : Boolean;
    UseTouchTest        : Boolean;
    DIOType             : Integer;
    IndexMotor_Timeout  : Integer;
    ScriptVer           : string;
    ScriptCrc           : string;
    RobotRevA           : string;
    RobotRevB           : string;
    RobotOutA           : string;
    RobotOutB           : string;
    nPwrVer             : TArrayChannelInteger; //array[DefCommon.CH1 .. DefCommon.MAX_CH] of Integer;
    FwVer, FpgaVer      : string;
    ProcessName         : string;
    InspectionType      : integer;
    NGAlarmCount        : integer; //NG 발생 횟수 초과 시 Alarm 발생
    RetryCount          : integer; //Contact Retry 횟수
    RetryCount_WritePOCB:  integer; //Write POCB Retry 횟수
    ECS_Timeout         : integer; //ECS 타임아웃 설정
    MIPILog             : Boolean;
    Use_ECS             : Boolean; //생산 보고 ECS 사용 여부 - UCHK, PCHK, EICR, APDR
    Use_MES             : Boolean; //생산 보고 MES 사용 여부 - UCHK, PCHK, EICR, APDR
    Use_GIB             : Boolean; //생산 보고 MES 사용 시 GIB 여부 - INSPCHK, EIJR
    CAM_FFCData         : Boolean; //카메라에 FFC 측정 프로세스 처리  여부
    CAM_StainData       : Boolean; //카메라에 Stain(얼룩검사)  프로세스 처리 여부
    CAM_FTPUpload       : Boolean; //카메라에 FTP로 이미지 업로드처리  여부
    CAM_ResultType      : Integer; //카메라에 Result 종류 선택
    CAM_CallbackChangePattern  : Boolean; //카메라에서 ChangePattern을 스크립트 함수 호출 여부
    CAM_TemplateData        : Boolean; //카메라에서 Template Data 여부
    AutoLoginID         : string; //자동 로그인 ID
    Test_Repeat         : Boolean; //테스트용 자동 회전
    UseNoExchange       : Boolean; //캐리어 감지 시 Exchange 사용 여부
    UseNoPogo           : Boolean; //Contact 시 POGO 사용 안함 여부
//    Ca410MemCh          : Integer;
    {$IFDEF CA410_USE}
    Com_Ca310           : array[DefCommon.CH1 .. Defcommon.MAX_CH] of Integer;
    Com_Ca310_DevieId   : array[DefCommon.CH1 .. Defcommon.MAX_CH] of Integer;
    Com_Ca310_SERIAL    : array[DefCommon.CH1 .. Defcommon.MAX_CH] of string;
    Com_CaDeviceList    : array[0..pred(MAX_CA_DRIVE_CNT)] of string;
    {$ENDIF}
    DebugLogLevelConfig : Integer; //2020-09-16 DEBUG_LOG
    PG_TYPE             : Integer;  //AF9, DP860
    UseITOMode          : Boolean;
    SaveEnergy          : Integer;
    CHReversal          : Boolean; // 라인 반전으로 1 2 CH 반전 되어 들어오는 경우 처리
    SignalInversion     : string; // Added by KTS 2023-01-17 오후 5:14:33 B접점 반전 해야되는 신호 목록
    PG_WriteReadPassAddr : string;
    PG_TconWriteLogDisplay    : Boolean; //2023-03-28 jhhwang (for T/T Test)
    PG_TconWriteCmdType       : Integer; //2023-03-28 jhhwang (for T/T Test) //0(all tcon.ocwrite), 1(all tcon.write), 2(defaul tcon.ocwrite + tcon.write only if SyncAddr)
    PG_TconReadCmdType        : Integer;
    PG_TconOcWriteDelayMsec   : Integer; //2023-03-28 jhhwang (for T/T Test)
    PG_TconOcWriteSyncAddrStr : string;  //2023-03-30 jhhwang (for T/T Test)
    PG_ToonOcWriteSyncAddrArr : array of Integer; //2023-03-30 jhhwang (for T/T Test)
    PG_GpioReadHpdBeforeMeasure   : Boolean; //2023-03-30 jhhwang (for T/T Test)
    PG_WaitAckAfterContOcWriteCnt : Integer; //2023-03-31 jhhwang (for T/T Test)
    PG_TconReadBeforeDelayMsec    : Integer; //2023-04-24 jhhwang (for T/T Test)
    PG_TconOcWriteDelayLoopCnt    : Integer; //2023-04-24 jhhwang (for T/T Test)
    PG_TconOcWriteDelayMicroSec   : Integer; //2023-04-24 jhhwang (for T/T Test)

    PG_FWVsersion                : array[DefCommon.CH1 .. Defcommon.MAX_CH] of string; // Added by sam81 2023-04-28 오후 2:14:38
    CA410_MemoryCh               : array[DefCommon.CH1 .. Defcommon.MAX_CH] of string; // Added by sam81 2023-04-28 오후 2:14:38
    ConfigVer : array of TSWVer;
    ConfigVerCount : Integer;
    R2RCa410MemCh : Integer;
  end;



  PPLCInfo = ^TPLCInfo;
  TPLCInfo = record
    EQP_ID              : Integer;
    StationNO           : Integer;
    PollingInterval     : Integer;
    Timeout_Connection  : Integer;
    Timeout_ECS         : Integer;
    Address_ECS         : string;
    Address_ROBOT       : string;
    Address_EQP         : string;
    Address_ECS_W       : string;
    Address_ROBOT_W     : string;
    Address_EQP_W       : string;
    ComputerName        : string;
    Address_ROBOT2      : string;
    Address_ROBOT_W2    : string;
    Address_DoorOpen    : string;
    Use_Simulation      : Boolean;
    InlineGIB           : Boolean;  //InlineGIB용으로 사용 여부- PLC 메모리가 다르다.
    Zone: Integer;
  end;

  TSimulateInfo = record
    Use_PG     : boolean;
    Use_DIO    : boolean;
    Use_PLC    : boolean;
    Use_CAM    : boolean;
    PG_BasePort : integer;
    CAM_IP      : string;
    DIO_IP     : String;
    DIO_PORT   : Integer;
  end;
  TBmpAddInfo = record //
    BmpDownNum   : integer;       //AF9:API:BMP#
    DotPatType   : integer;       //AF9:API: 0(NoDotPat),1(DotPatRGB),2(LineDotPatRGB)
    FR,FG,FB, BR,BG,BB : Integer; //AF9:API: (DotPatType=1) APSDotPatternRGBSet|MULTI_APSDotPatternRGBSet:FR,FG,FB,BR,BG,BB
                                  //         (DotPatType=2) APSLineDotPatternRGBSet|MULTI_APSLineDotPatternRGBSet:FR,FG,FB,BR,BG,BB
  end;

  TModelParamSerialNoFlash = record
    nAddr   : DWORD;
    nLength : DWORD;
  end;

  TPatternGroup = record
    GroupName : String;
    PatCount  : Integer;
    PatType   : array of Integer; //0:Pattern, 1:BMP
    VSync     : array of Integer; // SignB에서는 필요 없으나 다른 Project를 위하여 정리.
    LockTime  : array of Integer; // SignB에서는 필요 없으나 다른 Project를 위하여 정리.
    Dimming   : array of Integer; //2019-10-11 DIMMING
    Option    : array of Integer; // SignB에서는 필요 없으나 다른 Project를 위하여 정리.
    PatName   : array of String[50];
    BmpDownNum: array of integer; // Added by KTS 2022-03-16 오후 1:37:34 ITO Model 패턴 번호

    BmpAddInfo : array of TBmpAddInfo; //AF9-FPGA //2022-06-14
  end;

  TStatusInfo = record
    AutoMode   : boolean; //Robot(PLC) 연동 여부
    LogIn      : Boolean; //ECS(MES) Login 여부
    Closing    : boolean; //프로그램 닫는 중
    Loading    : boolean; //Robot(PLC) 연동 패널 로딩 중
    AlarmOn    : Boolean; //Alarm 발생 여부
    RobotDoorOpened: Boolean; //Robot(물류) Door Open 상태
    StageStep: array [0..2]of Integer; //0=None, 1=Loading(Exchange), 2=LoadComplete, 3=LoadingZone, 4=Turnning, 5=CamZone, 6=UnloadZone, 7=Unload
    LastProduct: Boolean; //마지막 Glass 여부
    StageTurnning: Boolean; //Turn 중
    AABMode    : Boolean; //AAB Mode 여부
    UseChannel : array [0..3] of Boolean; //각 채널 사용 체크 정보
    AlarmData: array [0..150] of Byte; //알람 리스트
    AlarmMsg: array [0..150] of String; //알람 메시지
    Test_AutoRepeat: Boolean; //자동 반복테스트 중
    LoadUnloadFlowData : array [DefCommon.CH1 .. DefCommon.MAX_CH] of array [0..50] of Integer;  // 현재CH 별 Load/Unload 신호 위치 저장
  end;

  TVer = record
    psu_Date : string;
    psu_Crc  : string;
    isu_Date : string;
    isu_Crc  : string;
    HwVer    : array[DefCommon.CH1 .. DefCommon.MAX_CH] of string;
    OcParam  : string;
    OcVerify : string;
    OtpTable : string;
    OcOffSet : string;
    MES_CSV  : string;
    CRC_miau : Word;
    CRC_mioff : Word;
    CRC_mion  : Word;
    CRC_mpt   : Word;
    CRC_otpr  : Word;
    CRC_otpw  : Word;
    CRC_pwoff : Word;
    CRC_pwon  : Word;
    CRC_misc  : Word;
    CRC_Pat   : Word; //Pattern Group CRC
  end;
  TCalVal = record
    x : string;
    y : string;
    Lv : string;
  end;
  TOcInfo = record
    CalModelType   : Integer;
    CalDataSel     : string;
    CalTarget      : array[0 .. pred(Defcommon.MAX_CA310_CAL_ITEM)] of TCalVal;
    CalMemCh       : array[DefCommon.CH1 .. pred(Defcommon.MAX_CA310_CAL_ITEM)] of Integer;
    CalAgingTime   : Integer;
    CalRgbwAgingTm : Integer;
    CalRetryCnt    : Integer;
  end;

  PGammaVal = ^TGammaVal;
  TGammaVal = record
    x : Single;
    y : Single;
    Lv : Single;
  end;

  TGammaCmd = record
    R : Integer;
    G : Integer;
    B : Integer;
  end;

  TGammaAvg = record
    AvgType       : Integer;
    NgCode        : Integer; // 0: OK, 1 : File Load NG, 2 :
    AvgRowCnt     : Integer;
    AvgColCnt     : Integer; // Band x GrayStep + Channel number.
    Band, GrayStep : Integer;
    AvgGamma : array of TGammaCmd;
  end;
  POcParam = ^TOcParam;
  TOcParam = record
    ItemName : string;
    Idx      : Integer;
    Gamma    : TGammaCmd;
    Target   : TGammaVal;
    Limit    : TGammaVal;
    Ratio    : TGammaVal;

  end;
  TOcParams = record
    IdxOcPCnt  : Integer;
    IdxOcVCnt : Integer;
    OcParam  : array of TOcParam;
    OcVerify : array of TOcParam;
  end;
  TRgbAvgData = record
    IsReady   : boolean;
    IdxOcPCnt : Integer;
    Gamma     : array of TGammaCmd;
  end;
  TOtpReadData = record
    MipiCommand : Integer;
    DataLen     : Integer;
    Section     : Integer;
    OtpData     : string;
  end;
  TOtpRead     = record
    CommandCnt : Integer;
    Data       : array of TOtpReadData;
  end;
  TOffsetTable = record
    nIdx      : Integer;
    R,G,B     : Integer;
    OffSet    : Integer;
    Tx, Ty, TL : Single;
    Lx, Ly, LLv : Single;
  end;
  TFrame = record
    RawData  : array of Byte;
    DataLength	 : Integer;
  end;

  TLGD_DGMA_Parameter = packed record
    nIdx : Integer;       // 1
    Band : string;    //
    Tap : integer;
    Gray  : Integer;    //
    Gamma_R : string;    //
    Gamma_G : string;    //
    Gamma_B : string;    //
    Target_x : string;
    Target_y : string;
    Target_Lv : string;
  end;

  //1,Optical Compensation ,Optical Defect,OD01,EEPROM Read Fail,A06-B01-G78
  TGmesCode = packed record
    nIdx : Integer;       // 1
    sErrCode : string;    // OD01
    sErrMsg  : string;    // EEPROM Read Fail.
    MES_Code : string;    // A06-B01-G78
  end;

  TModelInfo = packed record
    SigType  		 : Byte;   // 0:3-3-2 1:4-4-4 2:5-6-5 3:6-6-6 4:8-8-8
    Freq         : Longword;
    H_Active     : Word;
    H_BP         : Word;
    H_Width      : Word;
    H_FP         : Word;

    V_Active     : Word;
    V_BP         : Word;
    V_Width      : Word;
    V_FP         : Word;

    ELVDD        : Word;
    ELVSS        : Word;
    DDVDH        : Word;
    dummy        : Byte;

    PWR_VOL      : array[0..5] of Word; // 1 = 10mV, 0~1200 = 0~12V
    PWR_CUR_HL   : array[0..5] of Word; // CURRENT HIGH LIMIT.  1 = 1mA, 0~10000 = 0~10A
    PWR_CUR_LL   : array[0..5] of Word; // CURRENT LOW LIMIT.   1 = 1mA, 0~10000 = 0~10A
    PWR_VOL_HL   : array[0..5] of Word; // Voltage High Limit.  1 = 10mV, 0~1200 = 0~12V
    PWR_VOL_LL   : array[0..5] of Word; // Voltage Low Limit.   1 = 10mV, 0~1200 = 0~12V

    PWR_VOL_HL2  : array[0..2] of Word; // 1 = 1mA
    PWR_VOL_LL2  : array[0..2] of Word; // 1 = 1mA
    PWR_CUR_HL2  : array[0..2] of Word; // 1 = 10mV
    PWR_CUR_LL2  : array[0..2] of Word; // 1 = 10mV
	
    Reverse      : array[0..15] of Byte;

//    CRC16        : Word;  //CRC´Â Àü¼Û Á÷Àü¿¡ °è»ê
  end;

  TModelInfo2 = record
//    useOcParam, useOcVerify : boolean;
//    useOtpTable, useOcOffset : boolean;
//    Ca310MemCh      : Integer;
    PatGrpName      : string;
    ConfigName      : string;
    CheckSum        : string;
//    OcParamPath     : string;
//    OcVerifyPath    : string;
//    OtpTablePath    : string;
//    OffSetTablePath : string;
    Zxis            : Integer;
  end;
  // for Pattern Group Download.
  TPatToolInfo = record
    ToolId      : Byte;
    Direction   : byte;
    Level       : Word;
    Sx,Sy,Ex,Ey : Word;
    Mx,My,R,G,B : Word;
  end;
  TPatternData = record
    PatNo     : Byte;
    PatType   : Byte;
    ToolCnt   : Byte;
    ToolInfo  : array of TPatToolInfo;
    CRC       : Word;
  end;
  // for save & display patter group.
  TPatterGroup = record
    GroupName : String;
    PatCount  : Integer;
    PatType   : array of Integer; //0:Pattern, 1:BMP
    VSync     : array of Integer; // SignB에서는 필요 없으나 다른 Project를 위하여 정리.
    LockTime  : array of Integer; // SignB에서는 필요 없으나 다른 Project를 위하여 정리.
    Option    : array of Integer; // SignB에서는 필요 없으나 다른 Project를 위하여 정리.
    PatName   : array of String;
  end;

  PDfsConfInfo = ^TDfsConfInfo;
  TDfsConfInfo = record
    bUseDfs             : Boolean;
    bDfsHexCompress     : Boolean;
    bDfsHexDelete       : Boolean;  // valid if only bDfsHexCompress is True
    sDfsServerIP        : string;
    sDfsUserName        : string;
    sDfsPassword        : string;
    bUseCombiDown       : Boolean;
    sCombiDownPath      : string;
    sProcessName        : string;
  end;

  TCombiCodeData = record
    sINIFileName : string;
    sINIDownTime : string; // for FLDR
    sVersion     : string;
    nGridCol     : Integer;
    nGridRow     : Integer;
    nOrigin      : Integer;
    sRcpName     : string;   // 모델 레시피 이름
    sProcessNo   : string;   // 공정번호
    nRouterNo    : Integer;
	  nOrigin2      : Integer;
    sRcpName2     : string;   // 모델 레시피 이름
    sProcessNo2   : string;   // 공정번호
    nRouterNo2    : Integer;
    MainButton   : array [0..4] of string;
    DefectMat    : array [0..4] of array [0..99] of string; // 최대 100개
    Color        : array [0..4] of Integer;
    GibOK        : array of array of string;
    Priority     : array [0..4] of string;
    Origin       : Integer;
    bAuthority   : Boolean;
    DefectCnt    : Integer;
  end;

  TPath = record
    RootSW   		 : string;
    Ini 		     : string;
    IMAGE        : string; // OC or Pre OC Layout 볼러오기 경로
    Spc          : string;
    Pattern 		 : string;
    PATTERNGROUP : string;
    BMP     		 : string;
    DATA         : string;
    CB_DATA      : string;
    MODEL   		 : string;
    MODEL_CUR    : string;
    ModelCode    : string;
    LOG     		 : string;
    FLASH         : string;
    FLASHBackup  : string;
    LGDDLL       : string;
    LGDSet       : string;
    LGDPara      : string;
    LGDReProgramming : string;
    LGD_LOG_BK      : string;
    Gamma        : string;
    CEL          : string;
    GMES     		 : string; //Host
    EAS          : string;
    R2R          : string;
    MLOG     		 : string; //Mlog
    R2RLOG       : string; //R2RLOG
    DebugLog     : string;     //DebugLog  //2020-09-16 DEBUG_LOG
    DIOLog       : string; // Added by sam81 2023-04-24 오후 4:06:54
//    CommPG       : string;
    PCDLog       : string; // PCD Log
    RePGMLog     : string;
    Shutdown_Fault_Log : string;
    HWCIDLog     : string;
	  Sensing      : string; // I Sensing Log
    PocbData     : string;
    SumCsv   		 : string; //Summary
    ApdrCsv      : string;
    TouchLog     : string;
    UserCalLog   : string;
    PwrEE   		 : string; //EE
    PG_FW				 : string;
    PG_FPGA 		 : string;
    TOUCH_FW     : string;
    IF_FW  			 : string;
    Panel_Fw     : string;
    PANEL_img		 : string;
    PANEL_hex		 : string;
//    OcSpec       : string;
    UserCal      : string;
    Maint        : string;
    // File
    SysInfo     : string;
    PGInfo      : string; //PGSetting.ini
    SWVersionInfo   : string; //SWVersion.ini

    OcInfo      : string;
    PatGrp      : string;
    OtpCfg      : string; // for RGB Average - oc Parameter only pass panel.

    PowerCali   : string; //Power Calibarion ini File Path
    TempCsv      : string;
    QualityCode   : string;
    CombiCode     : string;
    CombiBackUp   : string;
    DfsDefect     : string; // LocalPC DFS Log Path for DFS DEFECT (default: C:\DEFECT)
    DfsHex        : string; // LocalPC DFS Log Path for DFS HEX (default: C:\DEFECT\HEX)
    DfsHexIndex   : string; // LocalPC DFS Log Path for DFS HEX (default: C:\DEFECT\HEX_INDEX)
	  DfsSense      : string; // LocalPC DFS Log Path for DFS SENSE (default: C:\DEFECT\SENSE)
    DfsSenseIndex : string; // LocalPC DFS Log Path for DFS SENSE (default: C:\DEFECT\SENSE_INDEX)
  end;

  //Power 보정 값 저장
  TPowerCalibaration = record
    VPNL      : Integer;
    VDDI      : Integer;
    T_AV      : Integer;
    VPP       : Integer;
    VBAT      : Integer;
    VCI       : Integer;
    VDDEL     : Integer;
    VSSEL     : Integer;
    DDVHD     : Integer;
  end;


  TInterlockInfo = packed record
    Use: Boolean;
    Version_SW     : String;
    Version_Script : string;
    Version_FW     : string;
    Version_FPGA   : string;
    Version_Power  : string;
    Version_DLL    : string;
    Version_LGDDLL : string;
  end;
  TModelInfoPG = record
		//-------------- DP860,AF9
		PgVer       : TPgVer;          // PgVer
		PgModelConf : TPgModelConf;    // ModelConfig
		//-------------- DP860
    {$IFDEF PG_DP860}
		PgPwrData   : TPgModelPwrData; // Power Setting/Limit
		PgPwrSeq 	  : TPgModelPwrSeq;  // Power Sequence
    {$ENDIF}
  end;
  TModelParamPucDataFlash = record
    PucDataGetAddr : DWORD; //Valid if ParamCsvInfo.FormatType is 0(BeforeDevBuild)
    PucDataAddr    : DWORD; //Valid if ParamCsvInfo.FormatType is 1(DevBuild)
    PucDataSize    : DWORD; //
    //TBD
  end;
    //-------------------------------------------- MODELINFO_FLOW
  TModelInfoFLOW = record
    UsePwmPatDisp : Boolean;  //2019-10-11 DIMMING //2022-01-04 (UsePwm->UsePwmPatDisp)
    UsePwmAuxDPCD : Boolean;  //2022-01-04 DP200|DP201:DPCD_PWM:EDNA

    SerialNoFlashInfo   : TModelParamSerialNoFlash;

    UseDutDetect : Boolean;
    PwrOffOnDelay : Integer;
    BcrLength : Integer;
    ProcessName : string;
    PatGrpName   : string;
    ModelType : Integer;
    ModelTypeName : string;
    Ca410MemCh : Integer;
    UseNvmInit : integer; // Added by KTS 2023-06-13 오후 12:32:10

    IDLEMode : Boolean;

    IdleModeDTime : Integer;

    UseCheckVer : Boolean; // Added by KTS 2023-07-13 오전 8:30:17 Config별 SW / DLL Version Interlock
    UseCheckReProgramming : Boolean;
    UseCkNVMWriteSequence : Integer;
    UseTconWriteChecksum : Boolean;
    GetDLLBin : string;
    Is_3200NitDOE : Boolean;

    UseIonOnOff     : Boolean;  // Added by KTS 2022-03-18 오전 11:10:37 Ionizer On/Off
{$IFDEF FEATURE_EDID}
    EdidVerifyUse    : Boolean;
    EdidI2cDa        : Integer;
    Edidi2cRa        : Integer;
    EdidI2cLen       : Integer;
    // EDID Standard file  //2020-03-02 EDID
    EdidStdFileUse   : Boolean;
    EdidStdFilePath  : String;
{$ENDIF}
{$IFDEF FEATURE_POCB_ONOFF}
    PocbOnOffUse        : Boolean;
    PocbOnOffI2cDa      : Integer;
    PocbOnOffI2cRa      : Integer;
    PocbOnOffI2cOnVal   : Integer;
    PocbOnOffI2cOffVal  : Integer;
{$ENDIF}
{$IFDEF FEATURE_GRAY_CHANGE}
    GrayChangeUse       : Boolean;
    GrayChangeUnitButton: Integer;  //0~255 //2020-08-12 GRAY_CHANGE_UNIT (for Switch Button)
    GrayChangeUnitKbd   : Integer;  //0~255 //2020-08-12 GRAY_CHANGE_UNIT (for Keyboard)
{$ENDIF}
{$IFDEF FEATURE_DIMMING_STEP}
    DimmingStepUse      : Boolean;
    DimmingStep1        : Integer;  //0~100
    DimmingStep2        : Integer;  //0~100
    DimmingStep3        : Integer;  //0~100
    DimmingStep4        : Integer;  //0~100
{$ENDIF}
{$IFDEF FEATURE_PSR_ONOFF}
    PSROnOffUse         : Boolean;
{$ENDIF}

  end;
  TLogItem = record
    CH : Integer;
    FileName: string;
    Msg: string;
  end;


  TCommon = class(TObject)

    EdModelInfoPG,    TestModelInfoPG   : TModelInfoPG;   //PG
    EdModelInfoFLOW,  TestModelInfoFLOW : TModelInfoFLOW; //Depends on Insepctor Flow

    m_csReadCsvLog: TCriticalSection;
    m_csWriteCsvLog: TCriticalSection;
    m_csvLine, m_csvFile : Integer;
    m_nCurPosZAxis : Integer;
    m_hMainFrm : THandle;
    m_hLogFrm : array[0.. DefCommon.MAX_CH] of THandle;
    m_EERepeat : Integer;
    m_sUserId : string;
    m_bStopWork : boolean;
    SystemInfo   : TSystemInfo;
    PLCInfo      : TPLCInfo;
    InterlockInfo: TInterlockInfo;
    SimulateInfo : TSimulateInfo;
    OpticInfo    : TOcInfo;
    ModelInfo    : TMODELINFO;

//    ModelInfo2   : TModelInfo2;
    PatGrpInfo   : TPatterGroup;
//    TempModelInfo  : TMODELINFO;
//    TempModelInfo2  : TMODELINFO2;
//    TestModelInfo  : TMODELINFO; // Download 하기위한 buffer.
//    TestModelInfo2 :  TMODELINFO2;
  //	TestScriptInfo  : TSCRIPTINFO;

    SupervisorMode : Boolean;

    nPatInfoSize : Integer;
    _lcid     : LCID;
    PatternData  : array [0.. DefCommon.MAX_CH] of TPATTERNDATA;
    dis_pattern_dat      : array[0.. DefCommon.MAX_CH] of TPATTERNDATA;
    Conn_Chk_Cnt  : array[0.. DefCommon.MAX_CH] of Integer;
    m_nGmesInfoCnt : Integer;
    GmesInfo      : array of TGmesCode;
    DGMA_Para     : array of array of TLGD_DGMA_Parameter;
    Path : TPath;
  //	g_DisplayPG      : Integer; //Display Current PG Index
  //	g_VoltagePG      : Integer; //Volt Display Current PG Index
    download_pattern_cnt : array[0.. DefCommon.MAX_CH] of Word;
    errorDisplayCount, connCheckCount : Integer;
    {$IFDEF CA410_USE}
    Ca410MemCh : Integer;
    {$ENDIF}

  private

    m_nCsvFileCnt : Integer;
    m_nCsvLineCnt : Integer;
    m_bModelInfoNg : Boolean;

    m_sFileName : array [DefCommon.CH1..MAX_PG_CNT] of string;
    m_slLog : array [DefCommon.CH1..MAX_PG_CNT] of TStringList;
    m_dtSaveLog :array [DefCommon.CH1..MAX_PG_CNT] of TDateTime;
    m_csLog : array [DefCommon.CH1..MAX_PG_CNT] of TCriticalSection;

    /// <summary> Log 누적 라인 수 - 초과 될 경우 저장</summary>
    LogAccumulateCount : Integer;
    /// <summary> Log 누적 시간(초단위) - 초과 될 경우 저장</summary>
    LogAccumulateSecond : Integer;
    m_bExecuteOncePerDay: Boolean;
    procedure SetResolution(nH, nV : Word);
    procedure LoadOcTables(nIdxOcTables : Integer);
    function LoadMesCode : Integer;
    function IsExcelProcess(const ProcessID: DWORD): Boolean;
    procedure SaveMLog(nCh : Integer; dtSave: TDateTime);
//    procedure SaveLog(nCH : Integer; dtSave: TDateTime);

    procedure LogWorker;
    procedure ProcessCycle;

  public
//    FLogQueue:  TQueue<TLogItem>;
    FLogThread:  TThread;

    AutoReStart : Boolean;
    loadAllPat    : TDongaPat;
    actual_resolution_hv : array[0..1] of Word;
    scrSequnce      : TStringList;
    m_OcParam     : TOcParams;
    m_RgbAvr      : array[DefCommon.JIG_A .. DefCommon.JIG_B] of TRgbAvgData;
    m_OtpRead     : TOtpRead;
    m_bIsChanged  : Boolean;
    m_OffsetTable : array of TOffsetTable;
    m_Ver         : TVer;
    m_naZAxis     : array[0..100] of Integer;
    m_DLLReProgrammingData : array of integer;
    m_DLLReProgrammingCRC : string;

    m_GetDBV : array[0..31] of Integer;
    ExeVersion   : String;
    ComputerName : String;
    DLLVersion   : string;
    ProductVersion : string;

    PGWriteReadPassAddr : array of integer;

    CombiCodeData   : TCombiCodeData;
    DfsConfInfo     : TDfsConfInfo;
    TempDfsConfInfo : TDfsConfInfo;
    StatusInfo      : TStatusInfo;
    m_nDebugLogLevelActive : Integer;  // init(SystemConfig.ini) + change by SetDebugLogLevel() from script //2020-09-16 DEBUG_LOG

//    m_csLog: array [DefCommon.CH1 .. DefCommon.MAX_PG_CNT] of TCriticalSection;
//    m_dtSaveLog: array [DefCommon.CH1 .. DefCommon.MAX_PG_CNT] of TDateTime;
//    m_slLog : array [DefCommon.CH1 .. DefCommon.MAX_PG_CNT] of TStringList;
    constructor Create;
    destructor Destroy; override;
    function MakeModelData(model_name : String) : AnsiString;
    procedure Make_Bmp_List;
    procedure LoadBaseData;
    procedure LoadPsuFile;
    procedure LoadOcData;
    procedure LoadCompiledFiles;
    procedure LoadPLCInfo;
    procedure ReadSystemInfo;
    function ReadPGSettingInfo : Boolean;
    function ReadSWVer : Boolean;
    function ReadDLLSet : Boolean;
    procedure ReadOpticInfo;

    function LoadLGDDGMA_Parameter: Integer;

    procedure LoadPGWriteReadPassAddr;

    function CheckPGWriteReadPassAddr(nAddr : Integer): Integer;

    function ReadLGDDLLSummaryLog(sPid,sSn,sDate : string; nCh : Integer) : string;
    function ReadLGDDLLSummaryLog_New(sPid,sSn,sDate : string; nCh : Integer) : string;
//    function ReadLGDDLLSummaryLog_New_1(sPid,sSn,sDate : string; nCh : Integer) : string;

    function CheckFileAccess(const Path: string; Mode: Word): Boolean;
    function CanOpenFile(const FilePath: string; FileMode: Word = fmOpenRead): Boolean;
    function FindLGDSummaryCsvFile(sFolderPath : String; sData : string):String;
    function SignalInversion(nSignal : Integer): Boolean;
    function LoadPatGroup(SelPatGroupName : string) : TPatterGroup;
    procedure SavePatGroup(sPatGroup : string; SavePatGrp : TPatterGroup);
    procedure InitSystemInfo;
    procedure SaveSystemInfo;
    procedure SavesystemInfoFwVersion(nCh : Integer; sData : string);
    procedure SavesystemInfoCA410Memory(nCh : Integer; sData : string);
    procedure UpdateSystemInfo_Runtime;
    procedure SaveLocalIpToSys(nIdx : Integer);
    procedure SaveOpticInfo(nModelType : Integer);
    function GetComputerName: String;
    function GetVersionDate : String;
    function GetVerOnlyDate : string;
    function GetFileVersion(sFileName : string) : string;
    function GetProductVersion(sFileName : string) : string;

    function GetFileVerDate(sFileName : string;nType : Integer = 0) : string;
    function GetScriptCrc(stData : TStringList): string;
    function GetStringCrc(sData : string) : string;
    function GetAnsiCrcToWord(sData : AnsiString; nLen : Integer) : Word;
    function  LoadModelInfo(fName: String): Boolean;
    function GetPatGroup(fModel : string) : string;
    function BmpGetSectionList : TStringList;
    function BmpGetKeyValueList(section : String) : TStringList;
    procedure Delay(msec: longint);
    procedure WaitMicroSec(micro_sec : Int64);
    procedure SleepMicro(nSec : Int64);
    procedure DebugMessage(const str: String);
    procedure InitPath;
    procedure SetCodeLog;
    function  GetFilePath(FName: String; Path: Integer): String;
    procedure SaveModelInfo(fName: String);
    procedure SaveModelInfoDLL(fName: String);
    procedure SaveModelInfo2(fName: String);
//    procedure MLog(nCh : Integer;const Msg : String);
    procedure MLog(nCh : Integer; const sLog: String; bSave: Boolean = False);


    procedure R2RLog(nCh: Integer; const Msg: String);
    procedure RePGMLog(nCh : Integer;const sPID,sSN: String);
    procedure Shutdown_FaultLog(nCh : Integer;const sPID,sSN: String);

    procedure HWCIDLogLog(nCh : Integer;const sPID,sSN,sData: String);
    procedure MLogWaveformData(nCh : Integer;const Msg: String);
    procedure EELog(const pg_no : Integer);
//    procedure CheckModelDownload(fname: String);
    procedure DelateBmpRawFile;
    function CheckDir(sPath: string): Boolean;
    function SetTimeToStr(nTime: Int64): string;
    /// <summary> Pattern Group의 CRC 계산 </summary>
    function MakePatternGroupCrc: WORD;
    procedure  MakePatternData(nIdx : Integer;makePatGrp : TPatterGroup; var dCheckSum: dword; var nTotalSize: Integer; var Data: TArray<System.Byte>);
    function crc16(Str: AnsiString; len: Integer) : Word;
    function crc16Buf(buffer : array of Byte; nLen : Integer) : Word;
//    function CheckEndTime(const aging_time : String): Longint;
    function Decrypt(const S: String; Key: Word): String;
    function Encrypt(const S: String; Key: Word): String;
    function ValueToHex(const S: String): String;
    function HexToValue(const S: String): String;
    procedure LoadCheckSumNData(sFileName : string; var dCheckSum : dword;var TotalSize : Integer; var Data : TArray<System.Byte> );
    procedure CalcCheckSum(p: pointer; byteCount:dword; var SumValue:dword);
    procedure MakeSummaryCsvLog(sHeader, sData : string);
    function DecToOct(nGetVal : Integer) : string;
    procedure TaskBar(bHide: Boolean);
    function GetLocalIpList(nIdx : Integer = DefCommon.IP_LOCAL_ALL; sSearchIp : string = '') : string;
    procedure CopyDirectoryAll(pSourceDir, pDestinationDir: string; pOverWrite: Boolean);
    function GetConfigInfo(sARev, sASend, sBRev, sBSend : string) : boolean;
    function GetModelConfig(sModel : string) : string;
    function ProcessMemory: longint;
    function GetDiskSpacePercentage(const Drive: string): Integer;
    function GetModelType(nIdx: Integer; sModelName : string): string;

    procedure FileCompress (sFullFileName: string; bDeleteOrgFile: Boolean;var sZipFileName : string);
    procedure FileDecompress (sFullZipName: string);
    procedure LoadCombiFile;
    procedure CheckAuthority(sID, sPassword: string);
    procedure GetZ_AxisData;
    procedure DebugLog(nCh, nMsgType: Integer; sRTX: string; sLocal,sRemote: string; sMsg: string);
    procedure ThreadTask(task: TProc);
    function GetDrawPosPG(sPos: string): word;
    function SetScreenSave(TimeOut: Integer): Boolean;
    function StringToPAnsiChar(AString: string): PAnsiChar;
    function GetHexLog(sFilename: string; nSize: DWORD; const pBuffer: PByte): DWORD;
    procedure SaveHexLog(sFilename: string; nSize: DWORD; pDataBuf: PByte);
    procedure GetReProgrammingData;
    function IntToIdBytes(Value: Integer): TIdBytes;
    procedure ConnectNetworkDrive(const driveLetter, networkPath: string);
    function IsNetworkDriveConnected(const driveLetter: Char): Boolean;
    function FetchNetworkFile(const networkPath, localPath: string): Boolean;
    function StringToIdBytes(const AStr: string): TIdBytes;

    procedure LoadDeleteFile;
    procedure SearchForFilesWithText(sdirectoryPath,sSearchText : string);
    function Make_reference_All_DBV_Gray_Data(fDBV: Double): TArray<Double>;
    function Find_Gray_index_Near_Target(fDBV, Target_Lv: Double): TArray<Double>;
    procedure SaveCsvMeasureLog(nCh: Integer; sFileCsv,sSerialNo,sDataHeader,sData : string);
    procedure GetBoxPtnSizeinfo(nModel,mBand : Integer; var nStartX,nStartY,nEndX,nEndY : Integer);
    function GetMemoryUsagePercentage: Double;
    function GetCPUUsage: Double;
    procedure CheckAndTerminateExcel(sExcelFileName : string);
    function IfVersionIsLessThan(const currentVersion, targetVersion: string): Integer;
    procedure CompressAndDeleteFolders(const sourceFolder, targetFolder: string);
    procedure ScheduledTask;
    function ExtractNumbersFromString(inputString: string): string;
//    procedure AddMLog(nCh : Integer; sLog: String; bSave: Boolean);


  end;

var
  Common : TCommon;
 //    {$IFDEF WIN64} µµ ÀÖÀ½.
 {$IFDEF WIN32}
  procedure ShowCodeSetDlg(nSite: Integer); cdecl; external 'IntegrationCode.dll' name 'ShowCodeSetDlg';  //delayed
  function  ShowMainDlg(nSite: Integer): PAnsiChar;cdecl; external 'IntegrationCode.dll' name 'ShowMainDlg';
  procedure CloseResultDlg(); cdecl; external 'IntegrationCode.dll'  name 'CloseResultDlg';
 {$ENDIF}

implementation

uses DefScript;
{ TCommon }




function TCommon.BmpGetKeyValueList(section: String): TStringList;
var
  iniF : TIniFile;
  image_fn : String;
  dList : TStringList;
  Rslt      : Integer;
  sr : TSearchrec;
begin
  dList := TStringList.Create;
  if section = 'ALL' then begin
    image_fn := PATH.BMP + '*.bmp';
    Rslt := FindFirst(image_fn, faAnyFile, sr);
    while Rslt = 0 do begin
      if Length(sr.Name) > 4 then dList.Add(sr.Name);
      Rslt := FindNext(sr);
    end;
    FindClose(sr);
  end
  else begin
    image_fn := PATH.BMP + 'image.lst';
    iniF := TIniFile.Create(image_fn);
    try
      iniF.ReadSections(dList);
      iniF.ReadSection(section, dList);
    finally
      iniF.Free;
    end;
  end;

  Result := dList;
end;

function TCommon.BmpGetSectionList: TStringList;
var
  iniF : TIniFile;
  image_fn : String;
  dList : TStringList;
begin
  image_fn := Path.BMP + 'image.lst';

  dList := TStringList.Create;
  iniF := TIniFile.Create(image_fn);
  try
    iniF.ReadSections(dList);
    dList.Insert(0, 'ALL');
  finally
    iniF.Free;
  end;

  Result := dList;
end;


procedure TCommon.CalcCheckSum(p: pointer; byteCount: dword; var SumValue: dword);
var
  i: dword;
  q: ^byte;
begin
  q := p;
  for i  := 0 to byteCount-1 do begin
    inc(SumValue, q^);
    inc(q);
  end;
end;




function TCommon.CanOpenFile(const FilePath: string; FileMode: Word): Boolean;
var
  FileHandle: THandle;
begin
  Result := False;

  // 파일 열기 시도
  FileHandle := FileOpen(FilePath, FileMode);
  try
    // 파일 열기에 성공하면 True 반환
    Result := FileHandle <> THandle(-1);
  finally
    // 파일 핸들 닫기
    if Result then
      FileClose(FileHandle);
  end;
end;

procedure TCommon.CheckAuthority(sID, sPassword: string);
var
  sIniFile : string;
  fSys : TIniFile;
  sTemp : string;
begin
  CombiCodeData.bAuthority := False;
  if (sID = '') or (sPassword = '') then Exit;
  sIniFile := Path.CombiCode + CombiCodeData.sINIFileName;
  if FileExists(sIniFile) then begin
    fSys := TIniFile.Create(sIniFile);
    try
      sTemp := fSys.ReadString('AUTHORITY', sID, '');
      if sPassword = sTemp then begin
        CombiCodeData.bAuthority := True;
      end
      else begin
        CombiCodeData.bAuthority := False;
      end;
    finally
      fSys.Free;
    end;
  end;
  if (sID = '123123') and (sPassword = '1234') then begin
    CombiCodeData.bAuthority := True;
  end;
end;

//procedure TCommon.AddMLog(nCh : Integer; sLog: String; bSave: Boolean);
//var
//  dtNow: TDateTime;
//begin
//
//  dtNow:= Now;
//  Common.m_csLog[nCh].Enter;
//
//  if HourOf(Common.m_dtSaveLog[nCh]) <> HourOf(dtNow) then Common.SaveLog(nCH,Common.m_dtSaveLog[nCh]); //시간 변경된 경우 이전 File로 저장
//  if bSave and (sLog = '') then begin
//    //단순 저장 요청
//  end else begin
//    //저장 요청이 아닌 경우Log 추가
//    Common.m_slLog[nCH].Add(FormatDateTime('HH:NN:SS.ZZZ => ', dtNow) + sLog);
//  end;
//
//
//  //로그 라인수가 누적 라인수 초과이거나누적시간(초) 초과인 경우File로 저장
//  if (Common.m_slLog[nCh].Count > LogAccumulateCount) or (SecondsBetween(dtNow, Common.m_dtSaveLog[nCh]) > LogAccumulateSecond) or bSave then begin
//    Common.SaveLog(nCH,dtNow);
//  end;
//  Common.m_csLog[nCh].Leave;
//end;

//procedure TCommon.SaveLog(nCH : Integer; dtSave: TDateTime);
//var
//  sFileName: String;
//  sDir,sDate,sFilePath,sFileDate,FileName: String;
//  logFile: TextFile;
//begin
//  if m_slLog[nCH].Count = 0 then Exit;
//
//  if (nCh < DefCommon.CH1) or (nCh > MAX_PLC_LOG) then  nCh := DefCommon.MAX_SYSTEM_LOG;
//
//
//    sDate := FormatDateTime('yyyymmdd', dtSave);
//    sFilePath := Path.MLOG + sDate + '\';
//    ForceDirectories(sFilePath);
//    sFileDate := FormatDateTime('yyyymmdd_AM/PM', dtSave);
//
//    case nCh of
//      DefCommon.MAX_SYSTEM_LOG: FileName := sFilePath + Format('SystemLog_%s_%s.txt',[systemInfo.EQPId,sFileDate]);
//      DefCommon.MAX_PLC_LOG: FileName :=  sFilePath + Format('PLC_%s_%s.txt',[systemInfo.EQPId,sFileDate])
//      else
//        FileName := sFilePath + Format('MLog_%s_%s_Ch%d.txt',[systemInfo.EQPId,sFileDate,nCh + 1]);
//    end;
//
//  AssignFile(logFile, FileName);
//  try
//    try
//      {$I-}
//      if FileExists(FileName) then Append(logFile) else Rewrite(logFile);
//
//      WriteLn(logFile, Trim(m_slLog[nCH].Text));
//
//      //m_csLog.Acquire;
//      m_slLog[nCH].Clear;
//      //m_csLog.Release;
//      m_dtSaveLog[nCH]:= dtSave;
//      {$I+}
//    except
//    end;
//  finally
//    CloseFile(logFile);
//  end;
//end;



function TCommon.GetDrawPosPG(sPos: string): word;
var
  totval: double;
	//internal var
	iTag, iToken, iLeft, iRight : Integer;
	aToken: array[1..100] of String;
  op_str : string;
	function GetToken(st: String) : Integer;
	var
		i: Integer;
		s: String;
	begin
		Result := 0; iTag := 0; s := '';
		st := Trim(st) + '+';
		for i:= 1 to Length(st) do begin
			inc(iTag);
			aToken[iTag] := Copy(st, i, 1);
		end;
		for i:= 1 to iTag do begin
			if (aToken[i] = '(') or (aToken[i] = ')') or
				(aToken[i] = '*') or (aToken[i] = '/') or
				(aToken[i] = '+') or (aToken[i] = '-') then begin
        if s <> '' then begin
          aToken[i-1] := s;
          s:= '';
				end;
      end
      else begin
        s := s + aToken[i];
        aToken[i] := '';
      end;
		end; //for...
		for i := 1 to iTag-1 do begin
			if aToken[i] <> '' then begin
				inc(Result);
				aToken[Result] := aToken[i];
			end;
    end;
	end; //function

	function Left_Position: Integer;
	var
    i: Integer;
	begin
		Result := 0;
		for i := 1 to iToken do
			if (aToken[i] = '(') then Result := i;
	end;

	function Right_Position(iLeft: Integer) : Integer;
	var
    i: Integer;
	begin
		Result := 0;
		for i := 1 + iLeft to iToken do
			if (aToken[i] = ')') then begin
				Result := i;
				Break;
			end;
	end;

	procedure Process_Calculator;
	var
		isDataExist: Boolean;
		sTemp: String;
		i,j, iMin, iMax: Integer;
	begin
		iLeft := Left_Position;
		iRight := Right_Position(iLeft);
		if iToken = 1 then Exit;
		if (iRight - iLeft) = 2 then begin
			aToken[iLeft] := ' ';
			aToken[iRight] := ' ';
			sTemp := '';
			for i := 1 to iToken do sTemp := sTemp + aToken[i];
			iToken := GetToken(sTemp);
			Exit;
		end;
		if iLeft = 0 then begin
			iMin := 1;
			iMax := iToken;
		end
		else begin
			iMin := iLeft + 1;
			iMax := iRight - 1;
		end;
		isDataExist := True;
		for i := iMin to iMax do begin
			if (aToken[i] = '*') or (aToken[i] = '/') then begin
				if aToken[i] = '*' then
					aToken[i] := FloatToStr(StrToFloat(aToken[i-1]) * StrToFloat(aToken[i+1]))
				else if aToken[i] = '/' then
					aToken[i] := FloatToStr(StrToFloat(aToken[i-1]) / StrToFloat(aToken[i+1]));
				aToken[i-1] := ' ';
				aToken[i+1] := ' ';
				sTemp := '';
				for j := 1 to iToken do sTemp := sTemp + aToken[j];
				iToken := GetToken(sTemp);
				isDataExist := False;
				Break;
			end;
		end;
		if not isDataExist then Exit;
		for i := iMin to iMax do begin
			if (aToken[i] = '+') OR (aToken[i] = '-') then begin
				if aToken[i] = '+' then
					aToken[i] := FloatToStr(StrToFloat(aToken[i-1]) + StrToFloat(aToken[i+1]))
				else
					aToken[i] := FloatToStr(StrToFloat(aToken[i-1]) - StrToFloat(aToken[i+1]));
				aToken[i-1] := ' ';
				aToken[i+1] := ' ';
				sTemp := '';
				for j := 1 to iToken do sTemp := sTemp + aToken[j];
				iToken := GetToken(sTemp);
				Break;
			end;
		end;
	end; //fuinction...
begin
	Result := 0;
	if length(sPos) = 0 then Exit;

	op_str := StringReplace(sPos, ' ', '', [rfReplaceAll]);

	op_str := StringReplace(op_str, 'H', IntToStr(actual_resolution_hv[0]), [rfReplaceAll]);
	op_str := StringReplace(op_str, 'V', IntToStr(actual_resolution_hv[1]), [rfReplaceAll]);


	iToken := GetToken(op_str);
	Repeat
		Process_Calculator;
	until iToken = 1;
	totval := StrToFloat(aToken[1]);
	Result := Trunc(totval);
end;



function TCommon.SetScreenSave(TimeOut: Integer): Boolean;
const
  SixtySeconds = 60 ;
var
  Reg:TRegistry ;
  bRet : boolean;
begin
  bRet := True;

  Reg := TRegistry.Create ;
  Reg.RootKey := HKEY_CURRENT_USER ;
  try
    with Reg do begin
      if OpenKey('Control Panel\Desktop',False) then begin
//        WriteString('SCRNSAVE.EXE', Name) ;
        WriteString('ScreenSaverIsSecure','0') ;
        CloseKey ;
      end
      else begin
        Result := False ;
        exit(False) ;
      end ;
    end ;
  finally
    Reg.Free ;
  end ;

  if TimeOut = 0 then begin
    SystemParametersInfo(SPI_SETSCREENSAVEACTIVE,0,nil,SPIF_SENDWININICHANGE);
  end
  else begin
    SystemParametersInfo(SPI_SETSCREENSAVEACTIVE,1,nil,SPIF_SENDWININICHANGE);
    SystemParametersInfo(SPI_SETSCREENSAVETIMEOUT,SixtySeconds * TimeOut, nil,SPIF_SENDWININICHANGE);
  end;

  Result := True ;
end;

function TCommon.CheckDir(sPath: string): Boolean;
var
  bRtn : Boolean;
begin
  bRtn := False;
  // Check & Make the Directorys.
  if not DirectoryExists(sPath) then begin
    if not CreateDir(sPath) then begin
      MessageDlg(#13#10 + 'Cannot make the Path('+sPath+')!!!', mtError, [mbOk], 0);
      bRtn := True;
    end;
  end;
  Result := bRtn;
end;


function TCommon.CheckFileAccess(const Path: string; Mode: Word): Boolean;
var
  FileAttr: Word;
begin
  Result := False;
  // 파일이 존재하는지 검사
  if not FileExists(Path) then
    Exit;
  // 파일 속성을 가져옴
  FileAttr := FileGetAttr(Path);
  // 파일 읽기 권한 검사
  if (Mode and 4) = 4 then
  begin
    if (FileAttr and faReadOnly) = faReadOnly then
      Exit;
  end;
  // 파일 쓰기 권한 검사
  if (Mode and 2) = 2 then
  begin
    if (FileAttr and faReadOnly) = faReadOnly then
      Exit;
  end;
  // 파일 실행 권한 검사
  if (Mode and 1) = 1 then
  begin
    if (FileAttr and faDirectory) = faDirectory then
      Exit;
  end;
  Result := True;
end;

function TCommon.CheckPGWriteReadPassAddr(nAddr: Integer): Integer;
var
i : Integer;
begin
  Result := 1;
  for I := Low(PGWriteReadPassAddr) to High(PGWriteReadPassAddr) do begin
    if nAddr = PGWriteReadPassAddr[i] then begin
      Result := 0;
      Exit;
    end;
  end;
end;

//procedure TCommon.CheckModelDownload(fname: String);
//var
//  pg : Integer;
//begin     {
//  for pg := 0 to MAX_PG_CNT-1 do begin
//    if RunInfo[pg].TestModel = '' then Continue;
//    if AnsiCompareText(fname, RunInfo[pg].TestModel) = 0 then begin
//      RunInfo[pg].SendModelInfo := True; //Model Download
//      RunInfo[pg].SendPatGroup  := True; //Model º¯°æ½Ã PatternGroup ´Ù½Ã Download
//      if LoadModelInfo(RunInfo[pg].TestModel) then begin
//        RunInfo[pg].ActualResol[0]  := TempModelInfo.H_Active;
//        RunInfo[pg].ActualResol[1]  := TempModelInfo.V_Active;
//        RunInfo[pg].SetPowerData[0] := TempModelInfo.VLCD;
//        RunInfo[pg].SetPowerData[1] := TempModelInfo.VCC;
//        RunInfo[pg].SetPowerData[2] := TempModelInfo.VEXT;
//        RunInfo[pg].SetPowerData[3] := TempModelInfo.VEL;
//        RunInfo[pg].SetPowerData[4] := TempModelInfo.VBAT;
//        RunInfo[pg].SetPowerData[5] := TempModelInfo.VNEG;
//      end;
//    end;
//  end;   }
//end;

procedure TCommon.CopyDirectoryAll(pSourceDir, pDestinationDir: string; pOverWrite: Boolean);
var
  TempList : TSearchRec;
begin
  if m_bStopWork then Exit;
  if FindFirst(pSourceDir + '\*', faAnyFile, TempList) = 0 then begin
    if m_bStopWork then Exit;
    if not DirectoryExists(pDestinationDir) then ForceDirectories(pDestinationDir);
    repeat
      if m_bStopWork then Break;

      if ((TempList.attr and faDirectory) = faDirectory) and not (TempList.Name = '.') and not (TempList.Name = '..') then
      begin
        if Pos('LOG',UpperCase(TempList.Name)) > 0 then Continue;

        if DirectoryExists(pSourceDir + '\' + TempList.Name) then begin
           CopyDirectoryAll(pSourceDir + '\' + TempList.Name, pDestinationDir + '\' + TempList.Name, pOverWrite);
        end;
      end
      else begin
        if not pOverWrite then begin
           if FileExists(pSourceDir + '\' + TempList.Name) then begin
              CopyFile(pChar(pSourceDir + '\' + TempList.Name), pChar(pDestinationDir + '\' + TempList.Name), True);
           end;
        end
        else begin
           if FileExists(pSourceDir + '\' + TempList.Name) then begin
              CopyFile(pChar(pSourceDir + '\' + TempList.Name), pChar(pDestinationDir + '\' + TempList.Name), False);
           end;
        end;
       end;
    until FindNext(TempList) <> 0;
  end;
  FindClose(TempList);
end;




function TCommon.crc16(Str: AnsiString; len: Integer): Word;
var
  i, loop_len, cnt: Integer;
  crc, data: word;
begin
  crc := $FFFF;
  loop_len := len;
  cnt := 1;

  if len = 0 then begin
    crc16 := not crc;
    exit;
  end;

  while loop_len > 0 do
  begin
    data := $FF and Byte(Str[cnt]);
    Dec(loop_len);
    inc(cnt);
    for i := 1 to 8 do begin
      if ((crc and $1) xor (data and $1)) = 1 then crc := (crc shr 1) xor DefCommon.CRC16POLY
      else crc := crc shr 1;
      data := data shr 1;
    end;
  end;
  crc := not crc;
  data := crc;
  crc := (crc shl 8) or (data shr 8 and $FF);

  crc16 := crc;
end;

function TCommon.crc16Buf(buffer: array of Byte; nLen: Integer): Word;
var
  i, loop_len, cnt: Integer;
  crc, data: Word;
begin
  crc := $FFFF;
  loop_len := nLen;
  cnt := 0;

  if nLen = 0 then begin
    crc16Buf := not crc;
    exit;
  end;
  repeat
    for i := 1 to 8 do begin
      data := $FF and Byte(buffer[cnt]);

      if ((crc and $1) xor (data and $1))  > 0 then crc := (crc shr 1) xor DefCommon.CRC16POLY
      else crc := crc shr 1;
      data := data shr 1;
    end;
    inc(cnt);
    Dec(loop_len);


  until (loop_len > 0);
//  while loop_len > 0 do
//  begin
//    data := $FF and Byte(buffer[cnt]);
//    Dec(loop_len);
//    inc(cnt);
//    for i := 1 to 8 do begin
//      if ((crc and $1) xor (data and $1)) = 1 then crc := (crc shr 1) xor DefCommon.CRC16POLY
//      else crc := crc shr 1;
//      data := data shr 1;
//    end;
//  end;
  crc := not crc;
  data := crc;
  crc := (crc shl 8) or ((data shr 8) and $FF);

  crc16Buf := crc;

end;

constructor TCommon.Create;
var
  I: Integer;
begin
  m_bModelInfoNg := False;
  _lcid := GetUserDefaultLCID;
  loadAllPat    := TDongaPat.Create(nil);
  scrSequnce      := TStringList.Create;
  LoadBaseData;

  for I := 0 to DefCommon.MAX_PG_CNT do begin
    m_slLog[i]:= TStringList.Create;
    m_csLog[i] := TCriticalSection.Create;
    m_dtSaveLog[i]:= Now;
  end;

  FLogThread := TThread.CreateAnonymousThread(ProcessCycle);
  FLogThread.FreeOnTerminate := False;
  FLogThread.Start;

//  for I := 0 to 5 do begin
//    FLogQueue[i]:= TQueue<TLogItem>.Create;
//    FLogThread[i] := TThread.CreateAnonymousThread(LogWorker);
//    FLogThread[i].FreeOnTerminate := False;
//    FLogThread[i].Start;
//  end;



  m_csvLine :=	0;
  m_csvFile :=	0;
  m_nCurPosZAxis := 0;
  m_bStopWork := False;
  m_bIsChanged := False;
  ExeVersion:= GetFileVersion(Application.ExeName);
  ProductVersion := GetProductVersion(Application.ExeName);
  ComputerName:= GetComputerName;
  m_csReadCsvLog:= TCriticalSection.Create;
  m_csWriteCsvLog := TCriticalSection.Create;

end;

procedure TCommon.DebugLog(nCh, nMsgType: Integer; sRTX, sLocal, sRemote, sMsg: string);
var
//_infile : TextFile;
  sInputData, sFileName, sDate, sFilePath: String;
  nMsgLevel : Integer;
  sDevType  : String;
  sIpText   : string;
begin
//Exit; //ITBD:QSPI? //IMSI-INSERT
  //
  if (Self = nil) then Exit;
  if (Common = nil) then Exit;
  //
  if not (nMsgType in [DEBUG_LOG_MSGTYPE_INSPECT..DEBUG_LOG_MSGTYPE_MAX]) then Exit;
  //
  sDevType := 'PG';
  // check if msg type is higher than active debug log level
  case nMsgType of
    DEBUG_LOG_MSGTYPE_INSPECT:    nMsgLevel := DEBUG_LOG_LEVEL_INSPECT;
    DEBUG_LOG_MSGTYPE_CONNCHECK:  nMsgLevel := DEBUG_LOG_LEVEL_INSPECT_CONNCHECK;
    DEBUG_LOG_MSGTYPE_DOWNDATA:   nMsgLevel := DEBUG_LOG_LEVEL_DOWNDATA;
    else nMsgLevel := DEBUG_LOG_LEVEL_INSPECT;
  end;
  if (m_nDebugLogLevelActive < nMsgLevel) then Exit;
  // write log to file
  if CheckDir(Path.DebugLog) then Exit;
  sDate := FormatDateTime('yyyymmdd', Now);
  sFilePath := Path.DebugLog + sDate + '\';
  if CheckDir(sFilePath) then Exit;
  case nCh of
    DefCommon.CH_ALL: sFileName := sFilePath + Format('DebugLog_%s_%s_%s.txt',[systemInfo.EQPId,sDate,sDevType]);
    else begin
      sFileName := sFilePath + Format('DebugLog_%s_%s_%s_Ch%d.txt',[systemInfo.EQPId,sDate,sDevType,nCh+1]);
    end;
  end;
  //
  sMsg := StringReplace(sMsg, #$0D, '#', [rfReplaceAll]); // change #$0D to '#'
  if sRTX = 'RX' then sIpText := '[RX] '+ sLocal + '<' + sRemote
  else                sIpText := '[TX] '+ sLocal + '>' + sRemote;
  sInputData := FormatDateTime('(hh:mm:ss.zzz): ', Now) + sIpText + ': ' + Trim(sMsg) + #13#10;  //TBD:DP860? Trim?

  try
    TFile.AppendAllText(sFileName, sInputData, TEncoding.UTF8);
  except
  end;
end;


procedure TCommon.DebugMessage(const str: String);
begin
  OutputDebugString(PChar(str));
end;

function TCommon.Decrypt(const S: String; Key: Word): String;

var
  i: byte;
  FirstResult : String;

begin
  FirstResult := HexToValue(S);
  SetLength( Result, Length(FirstResult) );
  for i := 1 to Length(FirstResult) do  begin
    Result[i] := char(byte(FirstResult[i]) xor (Key shr 8));
//    Key := (byte(FirstResult[i]) + Key) * DefCommon.C1 + DefCommon.C2;
    Key := word((LongWord(byte(FirstResult[i]) + Key) * C1 + C2) and $FFFF);

  end;
end;



function TCommon.DecToOct(nGetVal: Integer): string;
var
  sOct : string;
  nRest, nValue : Integer;
begin
  sOct := '';
  nValue := nGetVal;
  while nValue > 0 do begin
    nRest := nValue mod 8;
    nValue := nValue div 8;
    sOct := Format('%d',[nRest]) + sOct;
  end;
  if sOct = '' then sOct := '0';

  Result := sOct;
end;

procedure TCommon.DelateBmpRawFile;
var
  image_fn : String;
  Rslt      : Integer;
  sr : TSearchrec;
begin
  image_fn := Path.BMP + '*.raw';
  Rslt := FindFirst(image_fn, faAnyFile, sr);
  while Rslt = 0 do begin
    DeleteFile(Path.BMP + sr.Name);
    Rslt := FindNext(sr);
  end;
  FindClose(sr);
end;

procedure TCommon.WaitMicroSec(micro_sec : Int64);
var
  StartTick,Freq,EndTick, diff : int64;
begin
  if QueryPerformanceFrequency(Freq) then
  begin
    QueryPerformanceCounter(StartTick);
    repeat
      Application.ProcessMessages;
      QueryPerformanceCounter(EndTick);
      diff := ((EndTick-StartTick) * 1000000) div Freq;
    until diff > micro_sec;
  end;
end;


procedure TCommon.Delay(msec: longint);
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
{var
  StartTick,Freq,EndTick, diff : int64;
begin
  if QueryPerformanceFrequency(Freq) then
  begin
    QueryPerformanceCounter(StartTick);
    repeat
      Application.ProcessMessages;
      QueryPerformanceCounter(EndTick);
      diff := ((EndTick-StartTick) * 1000000) div Freq;
    until diff > micro_sec;
  end;}
end;


destructor TCommon.Destroy;
var
  I: Integer;
begin

  SetLength(m_OcParam.OcParam,0);
  SetLength(m_OcParam.OcVerify,0);
  SetLength(SystemInfo.ConfigVer,0);
  SetLength(PGWriteReadPassAddr,0);
  SetLength(DGMA_Para,0);

  FLogThread.Terminate;
  FLogThread.WaitFor;
  FLogThread.Free;

  for i := 0 to DefCommon.MAX_PG_CNT do begin
    m_csLog[i].Enter;
    SaveMLog(i, Now);
    m_csLog[i].Leave;
    m_slLog[i].Free;
    m_csLog[i].Free;
  end;
//  FLogQueue.Free;

//  for I := 0 to 5 do begin
//    FLogThread[i].Terminate;
//    FLogThread[i].WaitFor;
//    FLogThread[i].Free;
//    FLogQueue[i].Free;
//  end;


  m_Ver.psu_Date := '';
  m_Ver.psu_Crc  := '';
  m_Ver.isu_Date := '';
  m_bStopWork := True;
  m_csReadCsvLog.Free;
  m_csWriteCsvLog.Free;
  Delay(100);  // back ground ÀÛ¾÷½Ã Ãë¼ÒÇÏ´Â ½Ã°£ ÂüÁ¶.

  if loadAllPat <> nil then  begin
    loadAllPat.Free;
    loadAllPat := nil;
  end;
  if scrSequnce <> nil then begin
    scrSequnce.Free;
    scrSequnce := nil;

  end;
  inherited;
end;


procedure TCommon.SaveHexLog(sFilename: string; nSize: DWORD; pDataBuf: PByte);
var
  tmpBuf : TIDBytes;
begin
//  if (not Common.SysInfo.DEBUG.DebugFlashHex) and
//     (not (PG[DefCommon.CH1].IsMainter or PG[DefCommon.CH_2].IsMainter)) then
//    Exit;

  if sFileName = '' then Exit;
  //
  SetLength(tmpBuf,nSize);
  CopyMemory(@tmpBuf[0],pDataBuf,nSize);
  //
  ThreadTask(procedure var i: DWORD; hexFile: TextFile; sHexStr: string;
  begin
    try
      try
        AssignFile(hexFile, sFileName);
        Rewrite(hexFile);
        for i := 0 to (nSize-1) do begin
          sHexStr := Format('%0.2x',[pDataBuf[i]]) + #$0A;
          Write(hexFile, sHexStr);
        end;
      except
        sFileName := sFileName;
      end;
    finally
      CloseFile(hexFile);
    end;
  end);
end;

function TCommon.GetHexLog(sFilename: string; nSize: DWORD; const pBuffer: PByte): DWORD;
var
  txtF  : Textfile;
  sReadLine : string;
  pData  : PByte;
  nData  : DWORD;
  btData : Byte;
begin
  Result := 0;
  if sFileName = '' then Exit;
  //
  if FileExists(sFileName) then begin
    if IOResult = 0 then begin
  		try
        nData := 0;
        pData := pBuffer;
        //
      	AssignFile(txtF, sFileName);
        Reset(txtF);
        while not Eof(txtF) do begin
          //
          Readln(txtF, sReadLine);
  				sReadLine := '$' + sReadline;
          btData := StrToIntDef(sReadLine,0);
          //
          pData^ := btData;
          Inc(pData);
          Inc(nData);
          //
          if (nData >= nSize) then break;
  			end;
        //
        {
        while (nData < nSize) do begin
          pData^ := $00;
          Inc(pData);
          Inc(nData);
        end;
        }
        Result := nData;
  		finally
        CloseFile(txtF);
  		end;
  	end;
  end;
end;

function TCommon.StringToPAnsiChar(AString: string): PAnsiChar;
begin
  Result := PAnsiChar(AnsiString(AString));
end;

procedure TCommon.EELog(const pg_no: Integer);
begin
//
end;

function TCommon.Encrypt(const S: String; Key: Word): String;
var
  i: byte;
  FirstResult : String;
begin
  SetLength(FirstResult, Length(S)); // ¹®ÀÚ¿­ÀÇ Å©±â¸¦ ¼³Á¤
  for i := 1 to Length(S) do begin
    FirstResult[i] := char(byte(S[i]) xor (Key shr 8));
//    Key := word((byte(FirstResult[i]) + Key) * C1 + C2);
    Key := word((LongWord(byte(FirstResult[i]) + Key) * C1 + C2) and $FFFF);

  end;
  Result := ValueToHex(FirstResult);
end;

procedure TCommon.FileCompress(sFullFileName: string; bDeleteOrgFile: Boolean; var sZipFileName: string);
var
  zipFile : TZipFile;
  sPath, sFileName, sZipFullName, sExt : string;
begin
  if Length(sFullFileName) <= 0 then Exit;
  //
  sZipFileName := '';
  zipFile := TZipFile.Create;
  try
    sPath     := ExtractFilePath(sFullFileName);
    sFileName := ExtractFileName(sFullFileName);
    sExt      := ExtractFileExt(sFileName);
    sZipFullName := sPath + '\' + StringReplace(sFileName,sExt,'.zip', [rfReplaceAll, rfIgnoreCase]);
    zipFile.Open(sZipFullName,zmWrite);
    zipFile.Add(sFullFileName);
    zipFile.Close;
    //
    if bDeleteOrgFile then begin
      DeleteFile(sFullFileName);
    end;
    sZipFileName := sZipFullName;
  finally
    zipFile.Free;
  end
end;

procedure TCommon.FileDecompress(sFullZipName: string);
var
  zipFile : TZipFile;
begin
  if Length(sFullZipName) <= 0 then Exit;
  //
  zipFile := TZipFile.Create;
  try
    zipFile.Open(sFullZipName,zmRead);
    zipFile.ExtractAll;
    zipFile.Close;
  finally
    zipFile.Free;
  end;
end;

function TCommon.FindLGDSummaryCsvFile(sFolderPath, sData: string): String;
var
  SearchRec: TSearchRec;
  sResult : String;
begin
  sResult := '';
  try
    // 폴더 경로의 모든 파일 검색
    if FindFirst(sFolderPath + '\*.csv', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          // 파일의 생성일자가 매개변수로 받은 날짜와 같은 경우
          if ContainsStr(SearchRec.Name, sData) then
          begin
            sResult := sFolderPath + '\' + SearchRec.Name;
            break;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  except
  end;
  Result := sResult;
end;

function TCommon.Make_reference_All_DBV_Gray_Data(fDBV: Double): TArray<Double>;
var
  Lv_Gray_per_band: TArray<Double>;
  MAX_Lv: Double;
  nGray: Integer;
begin
  SetLength(Lv_Gray_per_band, 512);

  MAX_Lv := 1680.0;
  if Common.TestModelInfoFLOW.Is_3200NitDOE then
    MAX_Lv := 2100.0;

  for nGray := 0 to 511 do
  begin
    Lv_Gray_per_band[nGray] := MAX_Lv * Power(fDBV / 2047.0, 2.2) * Power(((511.0 - nGray) / 511.0), 2.2);
  end;

  Result := Lv_Gray_per_band; // 수정: 배열을 반환하도록 변경
end;

function TCommon.Find_Gray_index_Near_Target(fDBV, Target_Lv: Double): TArray<Double>;
var
 output : TArray<Double>;
Lv_Gray_per_band: TArray<Double>;
fTop_diff, fBottom_diff: double;
nGray,nIndex_gray: Integer;
begin
  SetLength(Lv_Gray_per_band,512);
  SetLength(output,2);

  Lv_Gray_per_band := Make_reference_All_DBV_Gray_Data(fDBV);

//  CopyMemory(@Lv_Gray_per_band,Make_reference_All_DBV_Gray_Data(fDBV),512*sizeof(Lv_Gray_per_band[0]));
  for nIndex_gray := 0 to 511 do begin
    if Lv_Gray_per_band[nIndex_gray] < Target_Lv then Break;
  end;

  if (nIndex_gray > 0) or (nIndex_gray <= 511) then begin
    fTop_diff := Abs(Lv_Gray_per_band[nIndex_gray - 1] - Target_Lv);
    fBottom_diff := Abs(Target_Lv - Lv_Gray_per_band[nIndex_gray]);
    if fTop_diff >= fBottom_diff then
    else  nIndex_gray := nIndex_gray -1;

    output[0] := nIndex_gray;
    output[1] := Lv_Gray_per_band[nIndex_gray];

    Result := output;

  end
  else begin
    output[0] := 0;
    output[1] := -1;
    Result := output;
  end;
end;

procedure TCommon.GetBoxPtnSizeinfo(nModel,mBand : Integer; var nStartX,nStartY,nEndX,nEndY : Integer);
begin
  if nModel = 0 then begin      //Model X2146
    if mBand = 1 then begin     //APL 40%
      nStartX := 0;
      nStartY := 619;
      nEndX := 688;
      nEndY := 826;
    end
    else if mBand = 2 then begin  // APL 60%
      nStartX := 0;
      nStartY := 412;
      nEndX := 688;
      nEndY := 1239;
    end;
  end
  else if nModel = 1 then begin   //Model X2381
    if mBand = 1 then begin     //APL 40%
      nStartX := 0;
      nStartY := 500;
      nEndX := 605;
      nEndY := 667;
    end
    else if mBand = 2 then begin  // APL 60%
      nStartX := 0;
      nStartY := 334;
      nEndX := 605;
      nEndY := 1001;
    end;
  end;
end;

procedure TCommon.SaveCsvMeasureLog(nCh: Integer; sFileCsv,sSerialNo,sDataHeader,sData : string);
var
  sFilePath, sFileName : String;
  sLine: String;
  txtF                 : Textfile;
  i : integer;
begin
//  m_csWriteCsvLog.Acquire; // 메인에서 sync 처리 되어서 들어옴
  sFilePath := Common.Path.Gamma + FormatDateTime('yymmdd',now) + '\';
  sFileName := sFilePath + sFileCsv;
  if Common.CheckDir(sFilePath) then Exit;
  try
    AssignFile(txtF, sFileName);
    try

      if not FileExists(sFileName) then begin
        //Header 생성
        Rewrite(txtF);
        WriteLn(txtF, sSerialNo);
        WriteLn(txtF, sDataHeader);
      end;

      //Data
      Append(txtF);
      WriteLn(txtF, sData);
    except

    end;
  finally
    CloseFile(txtF); // Close the file

  end;
end;


function TCommon.GetAnsiCrcToWord(sData: AnsiString; nLen : Integer): Word;
begin
  Result :=  crc16(sData,nLen);
end;

function TCommon.GetComputerName: String;
var
  buffer : array [0 .. MAX_COMPUTERNAME_LENGTH + 1] of Char;
  Size : Cardinal;
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  GetComputerNameW(@buffer, Size);
  Result:= StrPas(Buffer);
end;

function TCommon.GetConfigInfo(sARev, sASend, sBRev, sBSend: string): boolean;
var
  txFile : TextFile;
  bRet   : boolean;
  sReadData : string;
  slTemp : TStringList;
begin
  bRet := False;
  if SystemInfo.PlcConfigPath = '' then Exit(bRet);
  if not FileExists(SystemInfo.PlcConfigPath) then  Exit(bRet);
  AssignFile(txFile,SystemInfo.PlcConfigPath);

  try
    Reset(txFile);
    while not Eof(txFile) do begin
      Readln(txFile,sReadData);
      slTemp := TStringList.Create;
      try
        ExtractStrings([','], [], PWideChar(sReadData), slTemp);
        if slTemp.Count > 5 then begin
          if slTemp[1] = SystemInfo.LocalIP_PLC then begin
            if sARev <> slTemp[2] then Break;
            if sASend <> slTemp[3] then Break;
            if sBRev <> slTemp[4] then Break;
            if sBSend <> slTemp[5] then Break;
            if sARev = sBRev  then Break;
            if sASend = sBSend  then Break;

            bRet := True;
            Break;
          end;
        end;
      finally
        slTemp.Free;
      end;
    end;
  finally
    CloseFile(txFile);
  end;
  Result := bRet;
end;


function TCommon.GetFilePath(FName: String; Path: Integer): String;
begin
  case Path of
    DefCommon.MODEL_PATH  : Result := self.Path.MODEL_CUR +''+ FName + '.mcf';
    DefCommon.PATRN_PATH  : Result := self.Path.PATTERN + FName + '.pat';
    DefCommon.PATGR_PATH  : Result := self.Path.PATTERNGROUP + FName + '.grp';
    DefCommon.SCRIPT_PATH_ISU : Result := self.Path.MODEL_CUR+ FName + '.isu';
    DefCommon.SCRIPT_PATH_PSU : Result := self.Path.MODEL_CUR+ FName + '.psu';
  else
    Result := FName;
  end;
end;


function TCommon.GetFileVerDate(sFileName : string; nType : Integer = 0): string;
var
  timeDate : TDateTime;
  sDate, sTemp, sRet    : string;
  slHexa   : TStringList;
  i: Integer;
begin
  if FileExists(sFileName) then begin
    FileAge(sFileName,timeDate);
    case nType of
      0 : begin
        Result := FormatDateTime('yyyy.mm.dd  hh:nn', timeDate);
      end;
      1 : begin
        Result := FormatDateTime('yy.mm.dd hh:nn', timeDate);
      end;
      2 : begin
        sDate := FormatDateTime('yy.mm.dd.hh.nn', timeDate);
        slHexa := TStringList.Create;
        try
          ExtractStrings(['.'], [], PWideChar(sDate), slHexa);
          sRet := '';
          for i := 0 to Pred(slHexa.Count) do begin
            sTemp := Format('%d',[StrToIntDef(slHexa[i],0)]);
            sRet := sRet + Format('%0.2x',[StrToIntDef(sTemp,0)]);
          end;
        finally
          slHexa.Free;
        end;
        Result := sRet;
      end;
      3 : begin
        Result := 'No Format Type';
      end;
    end;
  end
  else begin
    Result := 'NO Exists';
  end;

end;

function TCommon.GetFileVersion(sFileName: string): string;
var
  VerInfoSize: Cardinal;
  VerValueSize: Cardinal;
  dwHandle: Cardinal;
  PVerInfo: Pointer;
  PVerValue: PVSFixedFileInfo;
begin
(* Query
    - CompanyName
    - FileDescription
    - FileVersion
    - InternalName
    - LegalCopyright
    - LegalTrademarks
    - ProductName
    - ProductVersion
*)
  Result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(sFileName), dwHandle);
  GetMem(PVerInfo, VerInfoSize);
  try
    if GetFileVersionInfo(PChar(sFileName), dwHandle, VerInfoSize, PVerInfo) then
    begin
      // get the locale, this determines the default language
//      VerQueryValue(Buf, PChar('\VarFileInfo\Translation'), pData, Len);
//      sLocale := IntToHex(Integer(pData^), 8);
//      sLocale := Copy(sLocale, 5, 4) + Copy(sLocale, 1, 4);
//      VerQueryValue(Buf, PChar('\StringFileInfo\' + sLocale + '\ProductVersion'), Pointer(Value), Len)

      if VerQueryValue(PVerInfo, '\', Pointer(PVerValue), VerValueSize) then
      begin
          Result := Format('%d.%d.%d.%d', [
            HiWord(PVerValue^.dwFileVersionMS), //Major
            LoWord(PVerValue^.dwFileVersionMS), //Minor
            HiWord(PVerValue^.dwFileVersionLS), //Release
            LoWord(PVerValue^.dwFileVersionLS) //Build
            ]);
      end;
    end;
  finally
    FreeMem(PVerInfo, VerInfoSize);
  end;
  //ProductVersion

end;

function TCommon.GetProductVersion(sFileName: string): string;
var
  VerInfoSize: Cardinal;
  VerValueSize: Cardinal;
  dwHandle: Cardinal;
  PVerInfo: Pointer;
  PVerValue: PVSFixedFileInfo;
begin
(* Query
    - CompanyName
    - FileDescription
    - FileVersion
    - InternalName
    - LegalCopyright
    - LegalTrademarks
    - ProductName
    - ProductVersion
*)
  Result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(sFileName), dwHandle);
  GetMem(PVerInfo, VerInfoSize);
  try
    if GetFileVersionInfo(PChar(sFileName), dwHandle, VerInfoSize, PVerInfo) then
    begin
      // get the locale, this determines the default language
//      VerQueryValue(Buf, PChar('\VarFileInfo\Translation'), pData, Len);
//      sLocale := IntToHex(Integer(pData^), 8);
//      sLocale := Copy(sLocale, 5, 4) + Copy(sLocale, 1, 4);
//      VerQueryValue(Buf, PChar('\StringFileInfo\' + sLocale + '\ProductVersion'), Pointer(Value), Len)

      if VerQueryValue(PVerInfo, '\', Pointer(PVerValue), VerValueSize) then
      begin
          Result := Format('%d.%d.%d.%d', [
            HiWord(PVerValue^.dwProductVersionMS), //Major
            LoWord(PVerValue^.dwProductVersionMS), //Minor
            HiWord(PVerValue^.dwProductVersionLS), //Release
            LoWord(PVerValue^.dwProductVersionLS) //Build
            ]);
      end;
    end;
  finally
    FreeMem(PVerInfo, VerInfoSize);
  end;
  //ProductVersion

end;

function TCommon.GetLocalIpList(nIdx : Integer; sSearchIp : string): string;
type
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  phe : PHostEnt;
  pptr : PaPInAddr;
  Buffer : array[0..63] of AnsiChar;
  i : Integer;
  WSAData : TWSAData;
  slIpList : TStringList;
  sIP: String;
  sRet : string;
begin

  WSAStartup(MakeWord(2,2),WSAData);
  try
    slIpList := TStringList.Create ;
    slIpList.Clear;
    gethostname(Buffer, SizeOf(Buffer));
    phe := gethostbyname(buffer);
    if phe = nil then Exit;
    pptr := papinaddr(phe^.h_addr_list);
    i := 0;
    while pptr^[i] <> nil do begin
      slIpList.Add(string(inet_ntoa(pptr^[i]^)));
      Inc(i);
    end;
    WSACleanup;
    sRet := '';
    for i := 0 to Pred(slIpList.Count) do begin
      sIP:= Trim(slIpList[i]);
      if sIP = '0.0.0.0' then Continue;
      if Pos('192.168.0.', sIP) > 0 then Continue;

      case nIdx of
        DefCommon.IP_LOCAL_GMES : begin
          if Pos(sSearchIp, sIP) <> 1 then Continue;
          sRet := sIP;
          Break;
        end;
        DefCommon.IP_LOCAL_PLC : begin
          if Pos(sSearchIp, sIP) <> 1 then Continue;
          sRet := sIP;
          Break;
        end;
      end;
      if sRet <> '' then sRet := sRet + ' / ';
      sRet := sRet + Trim(slIpList[i]);
    end;
  finally
    slIpList.Free;
  end;
  Result := sRet;
end;

// nIdx : 몇번째? ==> H12F-SP-ALPHA-MC .... 3번째 값 가져 올것,.... nIdx = 2.
function TCommon.GetModelConfig(sModel: string): string;
var
  i : Integer;
  sRet : string;
  slstData : TStringList;
begin
  sRet := '';
  slstData:= TStringList.create;
  try

    ExtractStrings(['-'],[],PChar(sModel), slstData);
    if slstData.Count > 4 then begin
      if Pos('-CU-',UpperCase(Common.SystemInfo.TestModel)) > 0 then begin
        sRet := Format('%s-%s',[slstData[2],slstData[3]]);
      end
      else begin
        sRet := Format('%s-%s-%s',[slstData[2],slstData[3],slstData[4]]);
      end;
    end;
  finally
    slstData.Free;
    slstData := nil;
  end;
  result := sRet;
end;

function TCommon.GetModelType(nIdx: Integer; sModelName: string): string;
var
  lstTemp : TStringList;
  sRet : string;
begin
  sRet:= '';
  lstTemp := TStringList.Create;
  try
    ExtractStrings(['-'], [], PWideChar(sModelName), lstTemp);
    if lstTemp.Count < nIdx then sRet := ''
    else begin
      sRet := lstTemp.Strings[nIdx];
    end;
  finally
    lstTemp.Free;
  end;
  Result := sRet;
end;

function TCommon.GetPatGroup(fModel: string): string;
var
  fn, sPatGrp : String;
  modelF : TIniFile;
begin
  fn := Path.MODEL_CUR + fModel + '.mcf';
  FillChar(EdModelInfoFLOW, SizeOf(EdModelInfoFLOW), #0);  //TBD:QSPI? Why?
  sPatGrp := '';
  modelF := TIniFile.Create(fn);
  try
    try
      sPatGrp := modelF.ReadString('MODEL_INFO','Pattern_Group','');
    except
      ShowMessage(fn + 'structure is different,'+#13#10+' Make again.');
    end;
  finally
    modelF.Free;
  end;
  Result := sPatGrp;
end;

function TCommon.GetScriptCrc(stData: TStringList): string;
var
  sData : AnsiString;
  i     : Integer;
begin
  sData := '';
  for i := 0 to Pred(stData.Count) do begin
    sData := sData + AnsiString( stData.Strings[i]);
  end;
  Result :=  Format('%0.4x',[ crc16(sData,Length(sData))]);
{SystemInfo}
end;

function TCommon.GetStringCrc(sData: string): string;
begin
  Result :=  Format('%0.4x',[ crc16(sData,Length(sData))]);
end;

function TCommon.GetVerOnlyDate: string;
var
  timeDate : TDateTime;
begin
  FileAge(Application.ExeName,timeDate);
  Result := FormatDateTime('yy.mm.dd  hh:nn', timeDate);
end;

function TCommon.GetVersionDate: String;
var
  timeDate : TDateTime;
begin
  FileAge(Application.ExeName,timeDate);
  Result := ExeVersion + ' ( '+ ExtractFileName(ParamStr(0)) +  ')';
end;

procedure TCommon.GetZ_AxisData;
var
  i, nCnt, nIdx, nPps: Integer;
  sFileName, sInputData : string;
  _infile : TextFile;
  slTemp : TStringList;
begin
  sFilename := Path.Ini + 'Config_ZAxis.csv';
  for i := 1 to 99 do begin
    m_naZAxis[i] := 0;
  end;

  if FileExists(sFilename) then begin
    try
      AssignFile(_infile, sFileName);
      Reset(_infile);
      while(EOF(_infile) = false) do begin
        ReadLn(_infile, sInputData);
        slTemp := TStringList.Create;
        try
          ExtractStrings([','], [], PWideChar(sInputData), slTemp);
          nIdx := StrToIntDef(slTemp[0],0);
          nPps := StrToIntDef(slTemp[1],0);
          m_naZAxis[nIdx] := nPps;
        finally
          slTemp.Free;
        end;

      end;
    finally
      CloseFile(_infile);
    end;
  end;
end;

function TCommon.HexToValue(const S: String): String;
var
	i : Integer;
	sTemp : string;
begin
	SetLength(sTemp, Length(S) div 2);
	for i := 0 to (Length(S) div 2) - 1 do begin
		sTemp[i+1] := Char(StrToIntDef('$'+Copy(S,(i*2)+1, 2),0));
	end;
	Result := sTemp ;
end;

procedure TCommon.InitPath;
begin
  Path.RootSW		    := ExtractFilePath(Application.ExeName);
  // for system file.
  Path.INI    		    := Path.RootSW + 'INI\';
  Path.PATTERN        := Path.RootSW    + 'pattern\';
  Path.PATTERNGROUP   := Path.PATTERN    + 'group\';
  Path.BMP            := Path.PATTERN    + 'bmp\';
  Path.MODEL      	  := Path.RootSW + 'MODEL\';
  Path.LOG        		:= Path.RootSW + 'LOG\';
  Path.FLASH          := Path.LOG + 'FLASH\';
  Path.FLASHBackup    := Path.FLASH + 'BackUp\';
  Path.IMAGE          := Path.RootSW + 'image\';
  Path.MLOG           := Path.LOG + 'MLog\';
  Path.DebugLog       := Path.LOG + 'DebugLog\'; //2020-09-16 DEBUG_LOG
  Path.DIOLog         := Path.LOG + 'CommDIO\';
//  Path.CommPG         := Path.LOG + 'CommPG\';
  Path.GMES       		:= Path.LOG + 'Mes\';
  Path.EAS            := Path.LOG + 'Eas\';
  Path.R2R           := Path.LOG + 'R2R\';
  Path.TempCsv        := Path.LOG + 'TempCsv\';
  Path.RePGMLog       := Path.LOG + 'ReProgrammingLOG\';
  Path.CEL            := Path.LOG + 'CEL\';
  Path.Shutdown_Fault_Log   := Path.LOG + 'Shutdown_FaultLOG\';
  Path.R2RLOG            := Path.LOG + 'R2RLOG\';
  PATH.DATA 					:= Path.RootSW + 'DATA\';
  Path.PG_FW       		:= Path.DATA + 'PG_FW\';
  Path.PG_FPGA     		:= Path.DATA + 'PG_FPGA\';
  Path.Maint          := Path.RootSW + 'MAINT\';
  Path.LGDDLL         := Path.RootSW + 'LGDDLL\';
  Path.Gamma          := Path.LOG + 'Gamma\';
  Path.LGDSet        := Path.LGDDLL + 'Setting\OCSet\';
  Path.LGDReProgramming := Path.LGDDLL + 'ReProgramming\';
  Path.LGDPara        := Path.LGDDLL + 'Setting\Parameters\';
  Path.LGD_LOG_BK     := Path.LGDDLL + '_bk\';

{$IFDEF CA410_USE}
  Path.UserCal := Path.RootSW + 'USER_CAL\';
  Path.UserCalLog := Path.UserCal + 'User_Cal_Log\';
  Path.OcInfo     := Path.Ini + 'OpticConfig.ini';
{$ENDIF}


  Path.SysInfo        := Path.INI + 'SysTemConfig.ini';
  Path.PGInfo         := Path.Ini + 'PGSetting.ini';
  Path.SWVersionInfo  := Path.Ini + 'SW Version 관리.ini';
  Path.PowerCali      := 'PowerCalibration.ini';
  Path.SumCsv         := Path.LOG + 'SummaryCsv\';
  Path.ApdrCsv        := Path.LOG + 'ApdrCsv\';
  Path.HWCIDLog       := Path.LOG + 'HWCIDLog\';

  CheckDir(Path.INI);
  CheckDir(Path.PATTERN);
  CheckDir(Path.PATTERNGROUP);
  CheckDir(Path.BMP);
  CheckDir(Path.MODEL);
  CheckDir(Path.LOG);
  CheckDir(Path.CEL);
  CheckDir(Path.GMES);
  CheckDir(Path.EAS);
  CheckDir(Path.DATA);
  CheckDir(Path.R2RLOG);
  CheckDir(Path.PG_FW);
  CheckDir(Path.PG_FPGA);
  CheckDir(Path.FLASH);
  CheckDir(Path.FLASHBackup);
  CheckDir(Path.Maint);
  CheckDir(Path.MLOG);
  CheckDir(Path.SumCsv);
  CheckDir(Path.ApdrCsv);
  CheckDir(Path.LGDDLL);
  CheckDir(Path.LGDReProgramming);
  CheckDir(Path.Shutdown_Fault_Log);
  CheckDir(Path.Gamma);
  CheckDir(Path.TempCsv);
  CheckDir(Path.RePGMLog);
  CheckDir(Path.HWCIDLog);
  CheckDir(Path.LGD_LOG_BK);

{$IFDEF ISPD_POCB}
  Path.CB_DATA  := Path.LOG + 'CB_DATA\';
  CheckDir(Path.CB_DATA);

{$ENDIF}

{$IFDEF ISPD_A}
  Path.PCDLog         := Path.LOG     + 'PCD_LOG\';
  CheckDir(Path.PCDLog);
{$ENDIF}
{$IFDEF DFS_HEX}

  Path.QualityCode    := Path.RootSW  + 'Quality Code\';
  Path.CombiCode      := Path.QualityCode + 'Combi Code\';
  Path.CombiBackUp    := Path.QualityCode + 'Backup\';
  Path.DfsDefect      := 'C:\DEFECT\';
  Path.DfsHex         := Path.DfsDefect  + 'HEX\';
  Path.DfsHexIndex    := Path.DfsDefect  + 'HEX_INDEX\';
  CheckDir(Path.QualityCode);
  CheckDir(Path.CombiCode);
  CheckDir(Path.CombiBackUp);
  CheckDir(Path.DfsDefect);
  CheckDir(Path.DfsHex);
  CheckDir(Path.DfsHexIndex);
{$ENDIF}
end;


procedure TCommon.InitSystemInfo;
var
  i : Integer;
begin
  with SystemInfo do begin
    Password       := 'LCD';
    TestModel      := '';
    for i := 0 to MAX_PG_CNT-1 do begin
      IPAddr[i]    := Format('192.168.0.%d',[i+21]);
    end;
    for I := 0 to Pred(DefCommon.MAX_BCR_CNT) do
      Com_HandBCR[i]       := 0;
    for I := 0 to Pred(DefCommon.MAX_SWITCH_CNT) do
      Com_RCB[i]          := 0;
    Z_Motor           := 0;
    PGMemorySize   := 512;//128;
  end;

end;

function TCommon.IntToIdBytes(Value: Integer): TIdBytes;
begin
  SetLength(Result, SizeOf(Integer));
  Move(Value, Result[0], SizeOf(Integer));
end;

function TCommon.SetTimeToStr(nTime: Int64): string;
var
  nSec, nMin, nHour, nTemp : Integer;
  sTime : string;
begin
  nSec  := nTime mod 60;  // 60초를 나눈 나머지가 Sec.
  nTemp := nTime div 60;  // 60초를 나눈값 ==> Min.
  nMin  := nTemp   mod 60;  //
  nHour := nTemp   div 60;  //
  sTime := Format('%0.2d:%0.2d:%0.2d',[nHour, nMin, nSec]);
//  if nTime = (nSecond)  then sRealAging := Format('%0.2d_%0.2d_%0.2d',[nHour, nMin, nSec]);
  Result := sTime;
end;

function TCommon.SignalInversion(nSignal: Integer): Boolean;
var
  slTemp : TStringList;

  sTemp : string;
  i : integer;
begin
  slTemp := TStringList.Create;
  Result := False;

  try
    ExtractStrings([' '], [], PWideChar(Trim(Common.SystemInfo.SignalInversion)), slTemp);
    for I := 0 to Pred(slTemp.Count) do begin
      if IntToStr(nSignal) = slTemp[i]  then  begin
       Result := True;
       Break;
      end;
    end;
  finally
    slTemp.Free;
  end;


end;


procedure TCommon.SleepMicro(nSec: Int64);
var
  mctStartTime,mctEndTime, mctFreq  : TLargeInteger;
  dDiff : Single;
begin
  if QueryPerformanceFrequency(mctFreq) then begin
    QueryPerformanceCounter(mctStartTime);
    repeat
      QueryPerformanceCounter(mctEndTime);
      // 기준값 1초.
      // *1000 ==> 1 mili seconds.
      // *1000*1000 ==> 1 micro Seconds
      dDiff := ((mctEndTime - mctStartTime) / mctFreq*1000*1000);
    until dDiff > nSec;
  end;

end;


procedure TCommon.TaskBar(bHide: Boolean);
var
  TaskHandle: THandle;
  AppBarData : TAppBarData;
begin
  // taskbar 핸들 얻기
  TaskHandle:=FindWindow('Shell_TrayWnd',nil);

  appBarData.cbSize := sizeof(appBarData);
  appBarData.hWnd   := TaskHandle;
  if bHide then begin
    appBarData.lParam := ABS_AUTOHIDE;
  end
  else begin
    appBarData.lParam := ABS_ALWAYSONTOP;
  end;
  SHAppBarMessage(ABM_SETSTATE,appBarData);
end;


procedure TCommon.ThreadTask(task: TProc);
var
  th : TThread;
begin
  th := TThread.CreateAnonymousThread(procedure begin
    task;
  end);
  th.FreeOnTerminate := True;
  th.Start;
end;


procedure TCommon.UpdateSystemInfo_Runtime;
var
  ini : TIniFile;
  sValue, sExeName: string;

begin
  ini := TIniFile.Create(Path.SysInfo);
  try
    with ini do begin
      sValue:= format('%s', [Application.ExeName]);
      WriteString('SYSTEMDATA',  'EXE_FILENAME',  		   	        sValue);
      sValue:= format('%s (%s)', [ExtractFileName(Application.ExeName), ExeVersion]);
      WriteString('SYSTEMDATA',  'TESTING_EXE',  		   	        sValue);
    end; //with ini do begin
  finally
    ini.Free;
  end;
end;

procedure TCommon.LoadBaseData;
begin
  InitPath;
  SetCodeLog;


  ReadSystemInfo;
  if not ReadPGSettingInfo then begin
    ShowMessage('<SYSTEM> Need to PGSetting.ini file. Check INI folder');
  end;


{$IFDEF CA310_USE}
  ReadOpticInfo;
{$ENDIF}
  LoadModelInfo(SystemInfo.TestModel);



//  GetZ_AxisData;

  TestModelInfoPG   := EdModelInfoPG;
  TestModelInfoFLOW := EdModelInfoFLOW;

//  TestModelInfo := TempModelInfo;
//  TestModelInfo2 := TempModelInfo2;
  // load pattern Group file.
  // set path.
  loadAllPat.Visible := False;
  loadAllPat.DongaUseSpc  := False;
  loadAllPat.DongaPatPath := Path.Pattern;
  loadAllPat.DongaBmpPath := Path.BMP;
  loadAllPat.LoadAllPatFile;

//  MakePatternGroupCrc;

  // Added by ClintPark 2018-07-28 오후 9:58:59 Psu file 위치 변경.
  LoadPsuFile;
  // Load OC Param.
  LoadOcData;
  if LoadMesCode < SystemInfo.MES_CODE_Cnt then  // MES CODE 갯수 로
    ShowMessage('<SYSTEM> Please check MES_CODE.CSV');
  //LoadPLCInfo; //임시 주석
//  LoadCompiledFiles;
end;

procedure TCommon.LoadCheckSumNData(sFileName: string; var dCheckSum: dword; var TotalSize: Integer; var Data: TArray<System.Byte>);
var
  Stream: TMemoryStream;
  dGetCheckSum : dword;
begin
  Stream := TMemoryStream.Create;
  dCheckSum := 0;
  TotalSize := 0;
  dGetCheckSum := 0;
  try
    try

      if not FileExists(sFileName) then begin
        Exit;
      end;

      Stream.LoadFromFile(sFileName);
      if Stream.Size > 0 then begin
        CalcCheckSum(Stream.Memory, Stream.Size, dGetCheckSum);
      end;

      dCheckSum := dGetCheckSum;
      TotalSize := Stream.Size;
      SetLength(Data,TotalSize);
      CopyMemory(@Data[0],Stream.Memory,TotalSize);
    except {...} end;
  finally
    Stream.Free;
//    Stream := nil;
  end;
end;

// It is for CRC Data.
procedure TCommon.LoadCombiFile;
var
  i, j, Rslt : Integer;
  sIniFile : string;
  fSys : TIniFile;
  sValue, sTemp, sModel : string;
  sLanguage : string;
  sList,sList2 : TStringList;
  SearchRec : TSearchRec;
  sPriority, sModelInfo : string;
begin
  if FindFirst(Path.CombiCode + '*.ini', faAnyFile, SearchRec) = 0 then begin

//    if SystemInfo.Language = 0 then begin // KOREAN
//      sLanguage := 'KR';
//      sPriority := 'Judge Rank';  //2019-05-16 '판정우선순위' -> 'Judge Rank'
//      sModelInfo := 'Model Info'; //2019-05-16 'Model 정보' -> 'Model Info'
//    end
//    else if SystemInfo.Language = 1 then begin // VIETNAMESE
      sLanguage := 'VN';
      sPriority := 'Judge Rank';  //2019-05-16 'thứ tự phán định ưu tiên' -> 'Judge Rank'
      sModelInfo := 'thông tin Model'; //2019-05-16 'thông tin Model' -> 'Model Info'
//    end;

    Rslt := 0;
    while Rslt = 0 do begin
      // 추후 언어설정에 따른 조건문 필요...
      if (Pos(sLanguage,SearchRec.Name) > 0) then begin
        CombiCodeData.sINIFileName := AnsiString(SearchRec.Name);
        CombiCodeData.sINIDownTime := FormatDateTime('yyyymmddhhnnss', Now);
        Break;
      end;
      Rslt := FindNext(Searchrec);
    end;
  end;
  FindClose(SearchRec);

  sIniFile := Path.CombiCode + CombiCodeData.sINIFileName;
  if not FileExists(sIniFile) then Exit;
  MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi '+sIniFile);
  try
    fSys := TIniFile.Create(sIniFile);
    try
      CombiCodeData.sVersion := fSys.ReadString('VERSION', 'VERSION', '');

      try
        sList := TStringList.Create;
        sTemp := fSys.ReadString('MAIN BUTTON', 'BUTTON', '');
        ExtractStrings(['/'],['/'],PWideChar(sTemp),sList);

        if sList.Count = 5 then begin
          for i := 0 to 4 do begin
            CombiCodeData.MainButton[i] := sList[i];
          end;
        end;
      finally
        sList.Free;
        sList := nil;
      end;

      for i := 0 to 4 do begin
        // 불량명
        for j := 0 to 99 do begin
          sTemp := Format('MATRIX(%d,%d)',[(j div 10)+1, (j mod 10)+1]);
          CombiCodeData.DefectMat[i,j]  := fSys.ReadString(CombiCodeData.MainButton[i],    sTemp,  '');
        end;

        // 우선순위
        sTemp := Format('Rank%.2d',[i+1]);
        CombiCodeData.Priority[i] := fSys.ReadString(sPriority, sTemp, '');

        // Color
        CombiCodeData.Color[i] := fSys.ReadInteger('COLOR', CombiCodeData.MainButton[i], 0);
      end;

      try
        sList := TStringList.Create;

        fSys.ReadSection('GIB OK', sList);
        SetLength(CombiCodeData.GibOK, sList.Count);
        for i := 0 to Pred(sList.Count) do begin
          SetLength(CombiCodeData.GibOK[i], 3);
          sTemp := fSys.ReadString('GIB OK', sList[i], '');
          try
            sList2 := TStringList.Create;
            ExtractStrings(['/'],['/'], PWideChar(sTemp), sList2);
            CombiCodeData.GibOK[i,0] := sList[i];
            CombiCodeData.GibOK[i,1] := sList2[0];
            CombiCodeData.GibOK[i,2] := sList2[1];
          finally
            sList2.Free;
            sList2 := nil;
          end;
        end;
      finally
        sList.Free;
        sList := nil;
      end;

      try
        sList := TStringList.Create;
        sList2 := TStringList.Create;
        ExtractStrings(['-'], ['-'], PWideChar(SystemInfo.TestModel), sList);  //2019-04-07 (POCB: TestModel: e.g., LA177QD1-LT01)
        if sList.Count >= 2 then begin
          sModel := sList[2];   //2019-04-07 (e.g., LA177QD1)
          //MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi '+sModel);
          SystemInfo.ProcessName := DfsConfInfo.sProcessName;   //2019-04-07 ('PC' for POCB)
          sModel := Format('%s_%s',[sModel, SystemInfo.ProcessName]);
          //MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi '+sModel);
          sValue := fSys.ReadString(sModelInfo, sModel, '');
          //MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi '+sModelInfo +','+sValue);
          sTemp:= format('ModelInfo:%s, Value:%s', [sModel, sValue]);
          MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi: '+ sTemp);
          if sValue <> '' then begin
            ExtractStrings(['/'],[], PWideChar(sValue), sList2);
            if sList2.Count > 0 then begin
              CombiCodeData.nRouterNo := StrToIntDef(sList2[0], 0);
              //MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi nRouterNo:'+sList2[0]);
              CombiCodeData.sRcpName := sList2[1];
              //MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi sRcpName: '+sList2[1]);
              CombiCodeData.nOrigin := StrToIntDef(sList2[2], 4);
              //MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi nOrigin: '+sList2[2]);
              if sList2.Count = 4 then begin // 공정번호
                CombiCodeData.sProcessNo := sList2[3];
                //MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi sProcessNo: '+sList2[3]);
              end
              else if sList2.Count = 5 then begin
                if SystemInfo.InspectionType = 0 then begin // 초검
                  CombiCodeData.sProcessNo := sList2[3];
                end
                else if SystemInfo.InspectionType = 1 then begin // 재검
                  CombiCodeData.sProcessNo := sList2[4];
                end;
              end;
              sTemp:= format('nRouterNo:%d, sRcpName:%s, nOrigin:%d, sProcessNo:%s',
                [CombiCodeData.nRouterNo, CombiCodeData.sRcpName, CombiCodeData.nOrigin, CombiCodeData.sProcessNo]);
              MLog(DefCommon.MAX_SYSTEM_LOG,'Load Combi: '+ sTemp);
            end;
          end;
        end;
      finally
        sList.Free;
        sList := nil;
        sList2.Free;
        sList2 := nil;
      end;
    except

    end;
  finally
    fSys.Free;
    fSys := nil;
  end;
end;

procedure TCommon.LoadCompiledFiles;
var
  sFileName : string;
  sCrc : AnsiString;
  i, j, nTotalSize: Integer;
  slCodes : TStringList;
  Stream: TMemoryStream;
  Data : array of Byte;
  wCrc : Word;
begin

  for i := DefScript.CODE_TXICINIT to DefScript.CODE_MAX do begin
    case i of
      DefScript.CODE_TXICINIT     : sFileName := path.ModelCode + SystemInfo.TestModel+ '.mpt';
      DefScript.CODE_MODULE_ON    : sFileName := path.ModelCode + SystemInfo.TestModel+ '.mion';
      DefScript.CODE_MODULE_OFF   : sFileName := path.ModelCode + SystemInfo.TestModel+ '.miOff';
      DefScript.CODE_POWER_ON     : sFileName := path.ModelCode + SystemInfo.TestModel+ '.pwon';
      DefScript.CODE_POWER_OFF    : sFileName := path.ModelCode + SystemInfo.TestModel+ '.pwoff';
      DefScript.CODE_POWER_ON_AUTO : sFileName := path.ModelCode + SystemInfo.TestModel+ '.miau';
      DefScript.CODE_OTP_WRITE    : sFileName := path.ModelCode + SystemInfo.TestModel+ '.otpw';
      DefScript.CODE_OTP_READ     : sFileName := path.ModelCode + SystemInfo.TestModel+ '.otpr';
      DefScript.CODE_SCR_CODE     : sFileName := path.ModelCode + SystemInfo.TestModel+ '.misc';
    end;
    
    if not FileExists(sFileName) then begin
      // if the code is screen code, please make empty code.
      if i = DefScript.CODE_SCR_CODE then begin
        try
          slCodes := TStringList.create;
          slCodes.Add('');
          slCodes.SaveToFile(sFileName);
        finally
          slCodes.Free;
        end;
      end;
    end;
    sCrc := '';  nTotalSize := 0;
    if FileExists(sFileName) then begin
      Stream := TMemoryStream.Create;
      try
        Stream.LoadFromFile(sFileName);
        nTotalSize := Stream.Size;
        SetLength(Data,nTotalSize);
        CopyMemory(@Data[0],Stream.Memory,nTotalSize);
        for j := 0 to Pred(nTotalSize) do begin
          sCrc := sCrc + AnsiChar(Data[j]);
        end;
        wCrc := GetAnsiCrcToWord(sCrc,nTotalSize);//crc16Buf(Data,nTotalSize);
      finally
        Stream.Free;
      end;
    end;
    case i of
      DefScript.CODE_TXICINIT     : m_Ver.CRC_mpt   := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_MODULE_ON    : m_Ver.CRC_mion  := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_MODULE_OFF   : m_Ver.CRC_mioff := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_POWER_ON     : m_Ver.CRC_pwon  := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_POWER_OFF    : m_Ver.CRC_pwoff := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_POWER_ON_AUTO : m_Ver.CRC_miau := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_OTP_WRITE    : m_Ver.CRC_otpw  := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_OTP_READ     : m_Ver.CRC_otpr  := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
      DefScript.CODE_SCR_CODE     : m_Ver.CRC_misc  := wCrc; //GetAnsiCrcToWord(sCrc,nTotalSize);
    end;
  end;
  m_Ver.isu_Crc := Format('%0.2x_',[m_Ver.CRC_mpt]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x_',[m_Ver.CRC_mion]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x_',[m_Ver.CRC_mioff]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x_',[m_Ver.CRC_pwon]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x_',[m_Ver.CRC_pwoff]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x_',[m_Ver.CRC_miau]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x_',[m_Ver.CRC_otpw]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x_',[m_Ver.CRC_otpr]);
  m_Ver.isu_Crc := m_Ver.isu_Crc + Format('%0.2x',[m_Ver.CRC_misc]);
end;

procedure TCommon.LoadPLCInfo;
var
  asPLCInfo: TArray<String>;
  sComputerName: String;
  sFileName: String;
  sLine: String;
  txtFile: TEXTFILE;
  i: Integer;
begin
  sFileName:= Path.Ini + 'PLCInfo.csv';
  if FileExists(sFileName) = false then begin
    //File not Found
    Exit;
  end;

  sComputerName:= GetComputerName;
  AssignFile(txtFile, sFileName);

  try

    Reset(txtFile);

    while not Eof(txtFile) do begin
      ReadLn(txtFile, sLine);
      asPLCInfo:= sLine.Split([',']);

      if Length(asPLCInfo) < 9 then begin
        //잘못된 라인
        continue;
      end;

      if sComputerName = UpperCase(asPLCInfo[8]) then begin
        PLCInfo.EQP_ID              := asPLCInfo[0].ToInteger;
        PLCInfo.StationNO           := asPLCInfo[1].ToInteger;
        PLCInfo.Address_ECS         := asPLCInfo[2];
        PLCInfo.Address_ECS_W       := asPLCInfo[3];
        PLCInfo.Address_EQP         := asPLCInfo[4];
        PLCInfo.Address_EQP_W       := asPLCInfo[5];
        PLCInfo.Address_ROBOT       := asPLCInfo[6];
        PLCInfo.Address_ROBOT_W     := asPLCInfo[7];
        PLCInfo.ComputerName        := asPLCInfo[8];
        //PLCInfo.PollingInterval     := asPLCInfo[2];
        //PLCInfo.Timeout_ECS         := asPLCInfo[3];
        //PLCInfo.Timeout_Connection  := asPLCInfo[4];
        //PLCInfo.Use_Simulation      := asPLCInfo[5];
      end;
    end; //while eof(txtFile) do begin
  finally
    CloseFile(txtFile);
  end;
end;


procedure TCommon.GetReProgrammingData;
var
nRetSearch,nCsvCnt,nRow : Integer;
TempList : TSearchRec;
sTarget, sFileName, sReadData : string;
txtFile: TEXTFILE;
lstCrc : TStringList;
sCrcData : string;
begin
  nRetSearch := FindFirst(Common.Path.LGDReProgramming + '*.Csv', faAnyFile, TempList);
  try
    nCsvCnt := 0;
    while nRetSearch = 0 do begin
      Inc(nCsvCnt);
      sTarget := TempList.Name;
      nRetSearch := FindNext(TempList);
    end;

    if not FileExists(Common.Path.LGDReProgramming + sTarget) then begin
    //File not Found
      Exit;
    end;
    sFileName := Common.Path.LGDReProgramming + sTarget;
    AssignFile(txtFile, sFileName);
    try
      Reset(txtFile);

      nRow := 0;
      lstCrc := TStringList.Create;
      try
        while not Eof(txtFile) do begin
          Readln(txtFile, sReadData);
          if Trim(sReadData) = '' then Continue;
          lstCrc.Add(sReadData);
          Inc(nRow);
        end;

      finally
        lstCrc.Free;
      end;

      SetLength(m_DLLReProgrammingData,nRow);
      nRow := 0;
      Reset(txtFile);

      while not Eof(txtFile) do begin
        ReadLn(txtFile, sReadData);
        sCrcData := sCrcData + sReadData;
        m_DLLReProgrammingData[nRow] := StrToInt('$'+sReadData);
        Inc(nRow);
      end; //while eof(txtFile) do begin
      m_DLLReProgrammingCRC := GetStringCrc(sCrcData);
      MLog(DefCommon.MAX_SYSTEM_LOG,format('Get_DLLReProgrammingData Done Data Length : %d CRC : %s ',[nRow,m_DLLReProgrammingCRC]));
    finally
      CloseFile(txtFile);
    end;

  finally
    FindClose(TempList);
  end;

end;

function TCommon.LoadMesCode : Integer;
var
  sErrMsg, sErrCode, sFileName, sReadData, sCrcData : string;
  txtF    : Textfile;
  lstTemp, lstCrc, lstErrCode : TStringList;
  nRow , nDataCount: Integer;
  i: Integer;
begin
//{$IFDEF ISPD_L_OPTIC}
  Result := 0;
  m_Ver.MES_CSV := '';
  sCrcData := '';
  m_nGmesInfoCnt := 0;
  sFileName := Path.Ini + 'MES_CODE.csv';
  if (not FileExists(sFileName)) or (sFileName = '') then begin
    sErrMsg := #13#10 + 'Input Error! MES CODE File [' + sFileName + '] cannot be loaded!';
    MessageDlg(sErrMsg, mtError, [mbOk], 0);
    m_bModelInfoNg := True;
    Exit;
  end;
  if IOResult = 0 then begin
    AssignFile(txtF, sFileName);
    try
      // ÀüÃ¼ Data ¼³Á¤.
      Reset(txtF);
      nRow := 0;
      lstCrc := TStringList.Create;
      try
        while not Eof(txtF) do begin
          Readln(txtF, sReadData);
          sCrcData := sCrcData + sReadData;
          if Trim(sReadData) = '' then Continue;
          lstCrc.Add(sReadData);
          Inc(nRow);
        end;

      finally
        lstCrc.Free;
      end;
      m_Ver.MES_CSV := GetFileVerDate(sFileName,1) + ' ' + GetStringCrc(sCrcData);
      SetLength(GmesInfo, nRow+1);
      m_nGmesInfoCnt := nRow;
      nRow := 0;
      GmesInfo[nRow].nIdx     := 0;
      GmesInfo[nRow].sErrCode := 'PASS';
      GmesInfo[nRow].sErrMsg  := '';
      GmesInfo[nRow].MES_Code := '';
      Inc(nRow);
      Reset(txtF);

      lstTemp := TStringList.Create;
      lstErrCode := TStringList.Create;
      try
        while not Eof(txtF) do begin
          Readln(txtF, sReadData);
          if Trim(sReadData) = '' then Continue;

          lstTemp.Clear;
          ExtractStrings([','], [], PWideChar(Trim(sReadData)), lstTemp);
          nDataCount := lstTemp.Count;
          if nDataCount < 6  then Continue;
          //1,Optical Compensation ,Optical Defect,OD01,EEPROM Read Fail,A06-B01-G78
          GmesInfo[nRow].nIdx     := StrToIntDef(lstTemp[0], -1);
          if GmesInfo[nRow].nIdx < 00 then Continue; //유효하지 않을 경우

          GmesInfo[nRow].sErrCode := Trim(lstTemp[3]);
          GmesInfo[nRow].sErrMsg  := Trim(lstTemp[4]);
          sErrCode := Trim(lstTemp[5]);

          //자릿수 맞추기:
          //회로-구동-NG : 4 - 8 - 30 유추
          //A06-B01-----IZJ----------------------------
          //A06-B01-IZJ

          lstErrCode.Clear;
          ExtractStrings(['-'], [], PWideChar(sErrCode), lstErrCode);
          //중간에'-'가 다수 있어도 count=3.
          if lstErrCode.Count > 2 then begin
            sErrCode := lstErrCode.Strings[0] + '-';
            sErrCode := sErrCode + lstErrCode.Strings[1] + '-----';
            sErrCode := sErrCode + lstErrCode.Strings[2] + '---------------------------';
          end;
          GmesInfo[nRow].MES_Code := sErrCode;

          Inc(nRow);
        end;
      finally
        lstTemp.Free;
        lstErrCode.Free;
      end;
    finally
      // Close the file
      Result := nRow;
      CloseFile(txtF);
    end;
  end;
end;


procedure TCommon.LoadDeleteFile;
var
  sErrMsg, sErrCode, sFileName, sReadData, sCrcData : string;
  txtF    : Textfile;
  lstTemp, lstCrc, lstErrCode : TStringList;
  nRow , nDataCount: Integer;
  i: Integer;
begin
//{$IFDEF ISPD_L_OPTIC}
  m_Ver.MES_CSV := '';
  sCrcData := '';
  m_nGmesInfoCnt := 0;
  sFileName := Path.Ini + 'MES_CODE.csv';
  if (not FileExists(sFileName)) or (sFileName = '') then begin
    sErrMsg := #13#10 + 'Input Error! MES CODE File [' + sFileName + '] cannot be loaded!';
    MessageDlg(sErrMsg, mtError, [mbOk], 0);
    m_bModelInfoNg := True;
    Exit;
  end;
  if IOResult = 0 then begin
    AssignFile(txtF, sFileName);
    try
      // ÀüÃ¼ Data ¼³Á¤.
      Reset(txtF);
      nRow := 0;
      lstCrc := TStringList.Create;
      try
        while not Eof(txtF) do begin
          Readln(txtF, sReadData);
          sCrcData := sCrcData + sReadData;
          if Trim(sReadData) = '' then Continue;
          lstCrc.Add(sReadData);
          Inc(nRow);
        end;

      finally
        lstCrc.Free;
      end;
      m_Ver.MES_CSV := GetFileVerDate(sFileName,1) + ' ' + GetStringCrc(sCrcData);
      SetLength(GmesInfo, nRow+1);
      m_nGmesInfoCnt := nRow;
      nRow := 0;
      GmesInfo[nRow].nIdx     := 0;
      GmesInfo[nRow].sErrCode := 'PASS';
      GmesInfo[nRow].sErrMsg  := '';
      GmesInfo[nRow].MES_Code := '';
      Inc(nRow);
      Reset(txtF);

      lstTemp := TStringList.Create;
      lstErrCode := TStringList.Create;
      try
        while not Eof(txtF) do begin
          Readln(txtF, sReadData);
          if Trim(sReadData) = '' then Continue;

          lstTemp.Clear;
          ExtractStrings([','], [], PWideChar(Trim(sReadData)), lstTemp);
          nDataCount := lstTemp.Count;
          if nDataCount < 6  then Continue;
          //1,Optical Compensation ,Optical Defect,OD01,EEPROM Read Fail,A06-B01-G78
          GmesInfo[nRow].nIdx     := StrToIntDef(lstTemp[0], -1);
          if GmesInfo[nRow].nIdx < 00 then Continue; //유효하지 않을 경우

          GmesInfo[nRow].sErrCode := Trim(lstTemp[3]);
          GmesInfo[nRow].sErrMsg  := Trim(lstTemp[4]);
          sErrCode := Trim(lstTemp[5]);

          //자릿수 맞추기:
          //회로-구동-NG : 4 - 8 - 30 유추
          //A06-B01-----IZJ----------------------------
          //A06-B01-IZJ

          lstErrCode.Clear;
          ExtractStrings(['-'], [], PWideChar(sErrCode), lstErrCode);
          //중간에'-'가 다수 있어도 count=3.
          if lstErrCode.Count > 2 then begin
            sErrCode := lstErrCode.Strings[0] + '-';
            sErrCode := sErrCode + lstErrCode.Strings[1] + '-----';
            sErrCode := sErrCode + lstErrCode.Strings[2] + '---------------------------';
          end;
          GmesInfo[nRow].MES_Code := sErrCode;

          Inc(nRow);
        end;
      finally
        lstTemp.Free;
        lstErrCode.Free;
      end;
    finally
      // Close the file
      CloseFile(txtF);
    end;
  end;
end;


function TCommon.LoadLGDDGMA_Parameter: Integer;
var
  sErrMsg, sErrCode, sFileName, sReadData, sCrcData : string;
  txtF    : Textfile;
  lstTemp, lstCrc, lstErrCode : TStringList;
  nRow , nDataCount: Integer;
  i,nBand,nTapCnt: Integer;
begin

  Result := 0;
  sCrcData := '';
  sFileName := Path.LGDPara +Common.TestModelInfoFLOW.ModelTypeName + '\DGMA_Parameter.csv';
  if (not FileExists(sFileName)) or (sFileName = '') then begin
    sErrMsg := #13#10 + 'Input Error! DGMA_Parameter File [' + sFileName + '] cannot be loaded!';
    MessageDlg(sErrMsg, mtError, [mbOk], 0);
    Exit;
  end;
  if IOResult = 0 then begin
    AssignFile(txtF, sFileName);
    try
      // ÀüÃ¼ Data ¼³Á¤.
      Reset(txtF);
      nRow := 0;

      SetLength(DGMA_Para, 32);
      for nBand := 0 to 31 do
      SetLength(DGMA_Para[nBand],20);

      nRow := 0;
      nTapCnt := 0;
      nBand := 1;
      Reset(txtF);

      lstTemp := TStringList.Create;
      try
        while not Eof(txtF) do begin
          Readln(txtF, sReadData);
          if Trim(sReadData) = '' then Continue;

          lstTemp.Clear;
          ExtractStrings([','], [], PWideChar(Trim(sReadData)), lstTemp);
          nDataCount := lstTemp.Count;
          if nDataCount < 8  then Continue;
          if StrToIntDef(lstTemp[0],0) = 0 then Continue;

          if nBand <> StrToInt(Trim(lstTemp[0])) then
          begin
            nBand := StrToInt(Trim(lstTemp[0]));
            nTapCnt := 0;
          end;

          DGMA_Para[nBand-1][nTapCnt].nIdx     := nRow+1;
          if DGMA_Para[nBand-1][nTapCnt].nIdx < 00 then Continue; //유효하지 않을 경우

          DGMA_Para[nBand-1][nTapCnt].Band := Trim(lstTemp[0]);

          DGMA_Para[nBand-1][nTapCnt].Tap := -1 + nTapCnt;
          DGMA_Para[nBand-1][nTapCnt].Gray  := StrToIntDef(Trim(lstTemp[1]),0);
          DGMA_Para[nBand-1][nTapCnt].Gamma_R := Trim(lstTemp[2]);
          DGMA_Para[nBand-1][nTapCnt].Gamma_G := Trim(lstTemp[3]);
          DGMA_Para[nBand-1][nTapCnt].Gamma_B := Trim(lstTemp[4]);
          DGMA_Para[nBand-1][nTapCnt].Target_x := Trim(lstTemp[5]);
          DGMA_Para[nBand-1][nTapCnt].Target_y := Trim(lstTemp[6]);
          DGMA_Para[nBand-1][nTapCnt].Target_Lv := Trim(lstTemp[7]);

          Inc(nTapCnt);
          Inc(nRow);
        end;
      finally
        lstTemp.Free;
      end;
    finally
      // Close the file
      Result := nRow;
      CloseFile(txtF);
    end;
  end;
end;

procedure TCommon.CompressAndDeleteFolders(const sourceFolder, targetFolder: string);
var
  zipFileName: string;
begin
  try
    // 현재 날짜 및 시간 기반으로 압축 파일 이름 생성
    zipFileName := System.IOUtils.TPath.Combine(targetFolder, 'OCLog_'+FormatDateTime('yyyymmdd_hhnnss', Now) + '.zip');

    // 폴더 압축
    TZipFile.ZipDirectoryContents(zipFileName, sourceFolder);

    // 폴더 삭제
    TDirectory.Delete(sourceFolder, True);

    MLog(DefCommon.MAX_SYSTEM_LOG,'Compressed and deleted folders.');
  except
    on E: Exception do
      MLog(DefCommon.MAX_SYSTEM_LOG,'Error Occurrence : '+ E.Message);
  end;
end;



procedure TCommon.ScheduledTask;
const
  ExecuteHourStart = 0; // 특정 시작 시간(24시간 형식) 설정
  ExecuteHourEnd = 1;   // 특정 종료 시간(24시간 형식) 설정
var
  CurrentHour : Word;
  sourceFolder : string;

begin
  // 오늘 작업을 실행한 경우, 다음 날에 다시 실행할 수 있도록 플래그 리셋
  if (Trunc(Now) > Trunc(Date)) then
      m_bExecuteOncePerDay := False;
    // 이미 하루에 한 번 실행했는지 여부 확인
  if not m_bExecuteOncePerDay then
  begin
    sourceFolder  := Path.LGDDLL + 'OCLog';
    // 현재 시간 얻기
    CurrentHour := HourOf(Now);

    // 특정 시간대에 작업 수행
    if (CurrentHour >= ExecuteHourStart) and (CurrentHour <= ExecuteHourEnd) then
    begin
      CompressAndDeleteFolders(sourceFolder,Path.LGD_LOG_BK);
      m_bExecuteOncePerDay := True;
    end;
  end;
end;

function TCommon.LoadModelInfo(fName: String): Boolean;
var
  fn, sTemp,sSection : String;
  modelF : TIniFile;
  i : Integer;
begin
//  Result := False;
  Path.MODEL_CUR := Path.MODEL + fName + '\';
  CheckDir(Path.MODEL_CUR);
  Path.ModelCode := Path.MODEL_CUR + 'compiled\';
  CheckDir(Path.ModelCode);
  fn := Path.MODEL_CUR + fName + '.mcf';
//  DebugMessage(Format('[LoadModelInfo] File=%s',[fn]));

  modelF := TIniFile.Create(fn);
  try

    with modelF do begin
      try
        with EdModelInfoPG.PgVer do begin
          sSection := 'PG_VERSION';
          //
          {$IFDEF PG_AF9}
          AF9VerMCS := Word(ReadInteger(sSection, 'AF9VerMCS', 0));
          AF9VerAPI := Word(ReadInteger(sSection, 'AF9VerAPI', 0));
          {$ENDIF}
          {$IFDEF PG_DP860}
          VerAll :=  Trim(ReadString(sSection,'PgVerAll',  ''));
          HW     :=  Trim(ReadString(sSection,'PgVerHW',   ''));
          FW     :=  Trim(ReadString(sSection,'PgVerFW',   ''));
          SubFW  :=  Trim(ReadString(sSection,'PgVerSubFW',''));
          FPGA   :=  Trim(ReadString(sSection,'PgVerFPGA', ''));
          PWR    :=  Trim(ReadString(sSection,'PgVerPWR',  ''));
          {$ENDIF}
        end;
        //------------------------------ ModelConfig
        with EdModelInfoPG.PgModelConf do begin
          // Resolution
          {$IFDEF PG_AF9}
          if SystemInfo.PG_TYPE = DefPG.PG_TYPE_AF9 then begin
            sSection := 'MODEL_DATA';
            // Resolution
            H_Active := ReadInteger(sSection, 'H_Active', 2920);  //ITOLED:X2146
            H_BP     := ReadInteger(sSection, 'H_BP',		  104);
            H_SA     := ReadInteger(sSection, 'H_SA',  	  104);
            H_FP     := ReadInteger(sSection, 'H_FP',		  240);
            V_Active := ReadInteger(sSection, 'V_Active', 1900);  //ITOLED:X2146
            V_BP     := ReadInteger(sSection, 'V_BP',		  292);
            V_SA     := ReadInteger(sSection, 'V_SA',  	  2);
            V_FP     := ReadInteger(sSection, 'V_FP',		  62);
            SetResolution(H_Active,V_Active);
            //
            Bmp2RawType := ReadInteger(sSection, 'Bmp2RawType', 0); // BMP-to-RAW Conversion: 0=Large(X2146), 1=Small(X2381) //2022-07-05
          end;
          {$ENDIF}

          {$IFDEF PG_DP860}
          if SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
            // Resolution
            if ValueExists('MODEL_RESOLUTION','H_Active') then sSection := 'MODEL_RESOLUTION'
            else                                               sSection := 'MODEL_DATA';
            H_Active := ReadInteger(sSection, 'H_Active', 2920);  //ITOLED:X2146
            H_BP     := ReadInteger(sSection, 'H_BP',		  104);
            H_SA     := ReadInteger(sSection, 'H_SA',  	  104);
            H_FP     := ReadInteger(sSection, 'H_FP',		  240);
            V_Active := ReadInteger(sSection, 'V_Active', 1900);  //ITOLED:X2146
            V_BP     := ReadInteger(sSection, 'V_BP',		  292);
            V_SA     := ReadInteger(sSection, 'V_SA',  	  2);
            V_FP     := ReadInteger(sSection, 'V_FP',		  62);
            SetResolution(H_Active,V_Active);
  					// Timing
            sSection := 'MODEL_TIMING';
            //
    				link_rate	 := ReadInteger(sSection, 'link_rate'	 ,0);
  	  			lane	     := ReadInteger(sSection, 'lane'			 ,0);
    				Vsync	     := ReadInteger(sSection, 'Vsync'			 ,0);
    				RGBFormat	 := Trim(ReadString(sSection, 'RGBFormat' ,''));
    				ALPM_Mode	 := ReadInteger(sSection, 'ALPM_Mode'	 ,0);
    				vfb_offset :=	ReadInteger(sSection, 'vfb_offset' ,0);

            // ALPDP
            sSection := 'MODEL_ALPDP';
            // ALPDP
  					h_fdp           := ReadInteger(sSection, 'h_fdp', 	0);
  					h_sdp           := ReadInteger(sSection, 'h_sdp', 	0);
  					h_pcnt          := ReadInteger(sSection, 'h_pcnt', 	0);
  					vb_n5b          := ReadInteger(sSection, 'vb_n5b', 	0);
  					vb_n7           := ReadInteger(sSection, 'vb_n7', 	0);
  					vb_n5a          := ReadInteger(sSection, 'vb_n5a', 	0);
  					vb_sleep        := ReadInteger(sSection, 'vb_sleep',0);
  					vb_n2           := ReadInteger(sSection, 'vb_n2', 	0);
  					vb_n3           := ReadInteger(sSection, 'vb_n3', 	0);
  					vb_n4           := ReadInteger(sSection, 'vb_n4', 	0);
  					//
  					m_vid           := ReadInteger(sSection, 'm_vid', 	0);
  					n_vid           := ReadInteger(sSection, 'n_vid', 	0);
  					misc_0          := ReadInteger(sSection, 'misc_0', 	0);
  					misc_1          := ReadInteger(sSection, 'misc_1', 	0);
  					xpol            := ReadInteger(sSection, 'xpol', 		0);
  					xdelay          := ReadInteger(sSection, 'xdelay', 	0);
  					h_mg            := ReadInteger(sSection, 'h_mg', 		0);
  					NoAux_Sel       := ReadInteger(sSection, 'NoAux_Sel',    0);
  					NoAux_Active    := ReadInteger(sSection, 'NoAux_Active', 0);
  					NoAux_Sleep     := ReadInteger(sSection, 'NoAux_Sleep',  0);
  					//
  					critical_section:= ReadInteger(sSection, 'critical_section', 0);
  					tps             := ReadInteger(sSection, 'tps',          0);
  					v_blank         := ReadInteger(sSection, 'v_blank',      0);
  					chop_enable     := ReadInteger(sSection, 'chop_enable',  0);
  					chop_interval   := ReadInteger(sSection, 'chop_interval',0);
  					chop_size       := ReadInteger(sSection, 'chop_size',    0);
          end;
          {$ENDIF} //PG_TYPE_DP860
        end;

        //------------------------------ PowerData
        {$IFDEF PG_DP860}
        if SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
          with EdModelInfoPG.PgPwrData do begin
            sSection := 'POWER_DATA';
            //
            PWR_SLOPE := ReadInteger(sSection, 'PWR_SLOPE', 0);  // 0:1ms(default), 500~2000:500~2000us
            for i := 0 to DefPG.PWR_MAX do begin
              PWR_NAME[i]   := ReadString(sSection,  Format('PWR_NAME_%d',[i]), '');  // Power Item Name
              if PWR_NAME[i] = '' then begin
                case i of
                  DefPG.PWR_VDD1: PWR_NAME[i] := 'VCC';
                  DefPG.PWR_VDD2: PWR_NAME[i] := 'VIN';
                  DefPG.PWR_VDD3: PWR_NAME[i] := 'VDD3';
                  DefPG.PWR_VDD4: PWR_NAME[i] := 'VDD4';
                  DefPG.PWR_VDD5: PWR_NAME[i] := 'VDD5';
                  else            PWR_NAME[i] := '----';
                end;
              end;
              PWR_VOL[i]    := ReadInteger(sSection, Format('PWR_VOL_%d',[i]),   0); // Voltage Setting - DP860(power.open)
              PWR_VOL_LL[i] := ReadInteger(sSection, Format('PWR_VOL_LL_%d',[i]),0); // Power Limit - DP860(power.limit -> power.open)
              PWR_VOL_HL[i] := ReadInteger(sSection, Format('PWR_VOL_HL_%d',[i]),0);
              PWR_CUR_LL[i] := ReadInteger(sSection, Format('PWR_CUR_LL_%d',[i]),0);
              PWR_CUR_HL[i] := ReadInteger(sSection, Format('PWR_CUR_HL_%d',[i]),0);
            end;
          end;
          //------------------------------ PowerSequence
          with EdModelInfoPG.PgPwrSeq do begin
            sSection := 'POWER_SEQUENCE';
            for i := 0 to DefPG.PWR_SEQ_MAX do begin
//              SeqOn[i]  := ReadInteger(sSection, Format('PWR_SEQ_ON_%d',[i]), 0);
//              SeqOff[i] := ReadInteger(sSection, Format('PWR_SEQ_OFF_%d',[i]),0);
            end;
            SeqOn[0]  := 6;         // Added by KTS 2023-12-05 오후 2:33:17 23/12/05 - 14:17분  우상용 책임 요청 고정
            SeqOff[0] := 58;
            SeqOn[1]  := 10;
            SeqOff[1] := 38;
          end;
        end; //PG_TYPE_DP860
        with EdModelInfoFLOW do begin
          sSection := 'FLOW_DATA';
          //
          ModelType      := Readinteger (sSection, 'MODELTYPE',0);
          ModelTypeName      := ReadString (sSection, 'MODEL_TYPE_NAME','X2146');
          PatGrpName       := ReadString (sSection, 'PatGrpName','');
          UseIonOnOff    := ReadBool   (sSection, 'USE_IONIZER_ON_OFF', False);
          UseDutDetect   := ReadBool   (sSection, 'UseDutDetect', False); //2023-02-02
          SerialNoFlashInfo.nAddr := Readinteger (sSection, 'SERIALNO_ADDR',0);
          SerialNoFlashInfo.nLength := Readinteger (sSection, 'SERIALNO_LENGTH',0);
          Ca410MemCh :=           Readinteger(sSection, 'Ca410MemCh',0);
          UseNvmInit :=           Readinteger(sSection, 'NVMINITMODE',2);
          UseCheckVer :=          ReadBool(sSection, 'USE_CHECK_VERSION', False);
          UseCheckReProgramming := ReadBool(sSection, 'USE_CHECK_ReProgramming',False);
//          UseCkNVMWriteSequence := ReadInteger(sSection, 'USE_CHECK_NVMWriteSequence',0);
          UseCkNVMWriteSequence := NVMWriteSequence;
          UseTconWriteChecksum := ReadBool(sSection, 'USE_CHECK_TCONWRITECHECKSUM',False);

          IdleModeDTime := Readinteger(sSection, 'IDLEMODEDTIME',0);

          IDLEMode := ReadBool(sSection,'IDLE_MODE',False);
          //
        end;
        {$ENDIF}


      except
        ShowMessage(fn + 'structure is different,'+#13#10+' Make again.');
      end;
    end;
  finally
    modelF.Free;
  end;

  Result := True;
end;

procedure TCommon.LoadOcData;
var
  i : Integer;
begin
{$IFDEF ISPD_L_OPTIC}
  m_Ver.OcParam   := '';
  m_Ver.OcVerify  := '';
  m_Ver.OcOffSet  := '';
  m_Ver.OtpTable  := '';

  if TestModelInfo2.useOcParam  then LoadOcTables(DefCommon.OC_TABLE_PARAM);
  if TestModelInfo2.useOcVerify then LoadOcTables(DefCommon.OC_TABLE_VERIFY);
  if TestModelInfo2.useOtpTable then LoadOcTables(DefCommon.OC_OTP_TABLE);
  if TestModelInfo2.useOcOffset then LoadOcTables(DefCommon.OC_OFFSET_TABLE);
  // To calcuate average vaule of rgb data of pass items for takt time faster.
  for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
    m_RgbAvr[i].IsReady := False;
    m_RgbAvr[i].IdxOcPCnt := m_OcParam.IdxOcPCnt;
    SetLength(m_RgbAvr[i].Gamma,m_OcParam.IdxOcPCnt);
  end;

{$ENDIF}
end;

procedure TCommon.LoadOcTables(nIdxOcTables : Integer);
var
  sErrMsg, sFileName, sReadData,sColData, sPreData, sTemp, sTemp2, sCrcData : string;
  txtF    : Textfile;
  lstTemp : TStringList;
  nDataLen, nRow, nCnt, nTemp , nDataCount: Integer;
  i: Integer;
begin
  sCrcData := '';
  case nIdxOcTables of
    // OC Parameter for compensation.
    DefCommon.OC_TABLE_PARAM : begin
      // OC Parameter Checking.
      sFileName := Path.MODEL_CUR + SystemInfo.TestModel + '_oc_param.csv';
//      sFileName := ExtractFilePath(Application.ExeName) + TestModelInfo2.OcParamPath;
      if (not FileExists(sFileName)) or (sFileName = '') then begin
        sErrMsg := #13#10 + 'Input Error! OC Parameter File [' + sFileName + '] cannot be loaded!';
        MessageDlg(sErrMsg, mtError, [mbOk], 0);
        m_bModelInfoNg := True;
        Exit;
      end;
      if IOResult = 0 then begin
        AssignFile(txtF, sFileName);
        try
          Reset(txtF);
          nRow := 0;
          while not Eof(txtF) do begin
            Readln(txtF, sReadData);
            sCrcData := sCrcData + sReadData;
            lstTemp := TStringList.Create;
            try
              ExtractStrings([','], [], PWideChar(sReadData), lstTemp);
              nDataLen :=  lstTemp.Count;
              if nDataLen < 11 then Continue;
              sColData := Trim(lstTemp[0]);
              if Pos('BAND',UpperCase(sColData)) = 0 then Continue;
              Inc(nRow);
            finally
              lstTemp.Free;
            end;
          end;
          m_Ver.OcParam := GetFileVerDate(sFileName,1)+' ' + GetStringCrc(sCrcData);
          {GetFileVerDate(sFileName,1);
    m_Ver.psu_Crc  := GetScriptCrc( scrSequnce);}
          Reset(txtF);
          SetLength(m_OcParam.OcParam,nRow);
          m_OcParam.IdxOcPCnt := nRow;

          nCnt := 0;
          while not Eof(txtF) do begin
            Readln(txtF, sReadData);
            lstTemp := TStringList.Create;
            try
              ExtractStrings([','], [], PWideChar(sReadData), lstTemp);
              //Band1_127	414	403	404	0.2988	0.3158	123.64	0.0025	0.0025	1.236		0.01		0x19E	0x193

              nDataLen :=  lstTemp.Count;
              if nDataLen < 13 then Continue;
              sColData := Trim(lstTemp[0]);
              if Pos('BAND',UpperCase(sColData)) = 0 then Continue;
              m_OcParam.OcParam[nCnt].Idx        := nCnt;
              m_OcParam.OcParam[nCnt].ItemName   := sColData;
              m_OcParam.OcParam[nCnt].Gamma.r    := StrToIntDef(lstTemp[1],0);
              m_OcParam.OcParam[nCnt].Gamma.g    := StrToIntDef(lstTemp[2],0) ;
              m_OcParam.OcParam[nCnt].Gamma.b     := StrToIntDef(lstTemp[3],0);
              m_OcParam.OcParam[nCnt].Target.x   := StrToFloatDef(lstTemp[4],0.0);
              m_OcParam.OcParam[nCnt].Target.y   := StrToFloatDef(lstTemp[5],0.0);
              m_OcParam.OcParam[nCnt].Target.Lv  := StrToFloatDef(lstTemp[6],0.0);
              m_OcParam.OcParam[nCnt].Limit.x    := StrToFloatDef(lstTemp[7],0.0);
              m_OcParam.OcParam[nCnt].Limit.y    := StrToFloatDef(lstTemp[8],0.0);
              m_OcParam.OcParam[nCnt].Limit.Lv   := StrToFloatDef(lstTemp[9],0.0);
              m_OcParam.OcParam[nCnt].Ratio.x    := StrToFloatDef(lstTemp[10],0.0);
              m_OcParam.OcParam[nCnt].Ratio.y    := StrToFloatDef(lstTemp[11],0.0);
              m_OcParam.OcParam[nCnt].Ratio.Lv   := StrToFloatDef(lstTemp[12],0.0);
              Inc(nCnt);
            finally
              lstTemp.Free;
            end;

          end;
        finally
          // Close the file
          CloseFile(txtF);
        end;
      end;
    end;

    DefCommon.OC_TABLE_VERIFY : begin
      // OC Parameter Checking.
//      sFileName := ExtractFilePath(Application.ExeName) + TestModelInfo2.OcVerifyPath;
      sFileName := Path.MODEL_CUR + SystemInfo.TestModel + '_oc_verify.csv';
      if (not FileExists(sFileName)) or (sFileName = '') then begin
        sErrMsg := #13#10 + 'Input Error! OC Verify File [' + sFileName + '] cannot be loaded!';
        MessageDlg(sErrMsg, mtError, [mbOk], 0);
        m_bModelInfoNg := True;
        Exit;
      end;
      if IOResult = 0 then begin
        AssignFile(txtF, sFileName);
        try
          Reset(txtF);
          nRow := 0;
          while not Eof(txtF) do begin
            Readln(txtF, sReadData);
            sCrcData := sCrcData + sReadData;
            lstTemp := TStringList.Create;
            try
              ExtractStrings([','], [], PWideChar(sReadData), lstTemp);

              nDataLen :=  lstTemp.Count;
              if nDataLen < 7 then Continue;
              sColData := lstTemp[0];
              if Pos('BAND',UpperCase(sColData)) = 0 then Continue;
              Inc(nRow);
            finally
              lstTemp.Free;
            end;
          end;
          m_Ver.OcVerify := GetFileVerDate(sFileName,1)+' ' + GetStringCrc(sCrcData);
          Reset(txtF);
          SetLength(m_OcParam.OcVerify,nRow);
          m_OcParam.IdxOcVCnt := nRow;
          nCnt := 0;
          while not Eof(txtF) do begin
            Readln(txtF, sReadData);
            lstTemp := TStringList.Create;
            try
              ExtractStrings([','], [], PWideChar(sReadData), lstTemp);
              nDataLen :=  lstTemp.Count;
              if nDataLen < 7 then Continue;
              sColData := Trim(lstTemp[0]);
              if Pos('BAND',UpperCase(sColData)) = 0 then Continue;

              m_OcParam.OcVerify[nCnt].ItemName   := sColData;
              m_OcParam.OcVerify[nCnt].Target.x   := StrToFloatDef(lstTemp[1],0.0);
              m_OcParam.OcVerify[nCnt].Target.y   := StrToFloatDef(lstTemp[2],0.0);
              m_OcParam.OcVerify[nCnt].Target.Lv  := StrToFloatDef(lstTemp[3],0.0);
              m_OcParam.OcVerify[nCnt].Limit.x    := StrToFloatDef(lstTemp[4],0.0);
              m_OcParam.OcVerify[nCnt].Limit.y    := StrToFloatDef(lstTemp[5],0.0);
              m_OcParam.OcVerify[nCnt].Limit.Lv   := StrToFloatDef(lstTemp[6],0.0);
              Inc(nCnt);
            finally
              lstTemp.Free;
            end;
          end;
        finally
          // Close the file
          CloseFile(txtF);
        end;
      end;
    end;
    OC_OTP_TABLE : begin
      // OTP Parameter Checking.
//      sFileName := ExtractFilePath(Application.ExeName) + TestModelInfo2.OtpTablePath;
      sFileName := Path.MODEL_CUR + SystemInfo.TestModel + '_otp_table.csv';
      if (not FileExists(sFileName)) or (sFileName = '') then begin
        sErrMsg := #13#10 + 'Input Error! OTP Table File [' + sFileName + '] cannot be loaded!';
        MessageDlg(sErrMsg, mtError, [mbOk], 0);
        m_bModelInfoNg := True;
        Exit;
      end;
      if IOResult = 0 then begin
        AssignFile(txtF, sFileName);
        try
          // ÀüÃ¼ Data ¼³Á¤.
          Reset(txtF);
          nRow := 0;
          while not Eof(txtF) do begin
            Readln(txtF, sReadData);
            sCrcData := sCrcData + sReadData;
            if Trim(sReadData) = '' then Continue;

            Inc(nRow);
          end;
          m_Ver.OtpTable := GetFileVerDate(sFileName,1)+' ' + GetStringCrc(sCrcData);
          m_OtpRead.CommandCnt := nRow;
          SetLength(m_OtpRead.Data, nRow);
          nRow := 0;
          Reset(txtF);
          while not Eof(txtF) do begin
            Readln(txtF, sReadData);
            lstTemp := TStringList.Create;
            if Pos('//',Trim(sReadData)) = 1 then Continue;

            try
              if Pos('S',UpperCase(Trim(sReadData))) = 1 then begin
                sTemp2 := StringReplace(sReadData,'S','',[rfReplaceAll,rfIgnoreCase]) ;
                sTemp := StringReplace(sTemp2,'0x','',[rfReplaceAll,rfIgnoreCase]) ;
                ExtractStrings([','], [], PWideChar(Trim(sTemp)), lstTemp);
                nDataLen :=  lstTemp.Count;
                if nDataLen < 2 then Continue;

                if nDataLen > 1 then begin

                  sTemp := '';
                  for i := 2 to Pred(nDataLen) do begin
                    sTemp2 :=  format('%0.2x',[StrToIntDef('$'+Trim(lstTemp[i]),0)]);
                    sTemp := sTemp + ' ' + sTemp2;
                  end;
                  m_OtpRead.Data[nRow].Section  := StrToIntDef('$'+Trim(lstTemp[0]),0);
                  m_OtpRead.Data[nRow].DataLen  := nDataLen-1;
                  m_OtpRead.Data[nRow].MipiCommand := StrToIntDef('$'+Trim(lstTemp[1]),0);
                  m_OtpRead.Data[nRow].OtpData    := Trim(sTemp) ;
                  Inc(nRow);   // ==> Data Length°¡ ÀÖ´Â Command ¼ö.
                end;
              end
              else begin
                sTemp := StringReplace(sReadData,'0x','',[rfReplaceAll,rfIgnoreCase]) ;
                ExtractStrings([','], [], PWideChar(Trim(sTemp)), lstTemp);
                nDataLen :=  lstTemp.Count;
                if nDataLen < 2 then Continue;

                if nDataLen > 1 then begin

                  sTemp := '';
                  for i := 1 to Pred(nDataLen) do begin
                    sTemp2 :=  format('%0.2x',[StrToIntDef('$'+Trim(lstTemp[i]),0)]);
                    sTemp := sTemp + ' ' + sTemp2;
                  end;

                  m_OtpRead.Data[nRow].DataLen  := nDataLen;
                  m_OtpRead.Data[nRow].MipiCommand := StrToIntDef('$'+Trim(lstTemp[0]),0);
                  m_OtpRead.Data[nRow].OtpData    := Trim(sTemp) ;
                  Inc(nRow);   // ==> Data Length°¡ ÀÖ´Â Command ¼ö.
                end;
              end;
            finally
              lstTemp.Free;
            end;
          end;

        finally
          // Close the file
          CloseFile(txtF);
        end;
      end;
    end;
    OC_OFFSET_TABLE : begin
      // OTP Parameter Checking.
//      sFileName := ExtractFilePath(Application.ExeName) + TestModelInfo2.OffSetTablePath;
      sFileName := Path.MODEL_CUR + SystemInfo.TestModel + '_oc_offset.csv';
      if (not FileExists(sFileName)) or (sFileName = '') then begin
        sErrMsg := #13#10 + 'Input Error! OC OffSet File [' + sFileName + '] cannot be loaded!';
        MessageDlg(sErrMsg, mtError, [mbOk], 0);
        m_bModelInfoNg := True;
        Exit;
      end;
      if IOResult = 0 then begin
        AssignFile(txtF, sFileName);
        try
//          // 전체 Data 설정.
//          Reset(txtF);
//          nRow := 0;
//          while not Eof(txtF) do begin
//            Readln(txtF, sReadData);
//            if Trim(sReadData) = '' then Continue;
//            Inc(nRow);
//          end;

          SetLength(m_OffsetTable, 100);
          nRow := 0;
          Reset(txtF);
          while not Eof(txtF) do begin
            Readln(txtF, sReadData);
            sCrcData := sCrcData + sReadData;
            lstTemp := TStringList.Create;
            try
              sTemp := StringReplace(sReadData,'0x','',[rfReplaceAll,rfIgnoreCase]) ;
              ExtractStrings([','], [], PWideChar(Trim(sTemp)), lstTemp);
              nDataLen :=  lstTemp.Count;
              nTemp := StrToIntDef(Trim(lstTemp[0]),0);
              // Gray 6, 7 Off Set.
              if nDataLen > 3 then begin
                // RGB.
                if nTemp in [1..19] then begin
                  m_OffsetTable[nTemp].nIdx := nTemp;
                  m_OffsetTable[nTemp].R := StrToIntDef(Trim(lstTemp[1]),0);
                  m_OffsetTable[nTemp].G := StrToIntDef(Trim(lstTemp[2]),0);
                  m_OffsetTable[nTemp].B := StrToIntDef(Trim(lstTemp[3]),0);
                end;
              end;
              // Band7, G7 Blue OffSet, Band8- 63, Band8 - 31, Band 9 - 63, Band 9 31 Gray
              if nDataLen > 1 then begin
                if nTemp in [21..25] then begin
                  nTemp := StrToIntDef(Trim(lstTemp[0]),0);
                  m_OffsetTable[nTemp].nIdx := nTemp-20;
                  m_OffsetTable[nTemp].OffSet := StrToIntDef(Trim(lstTemp[1]),0);
                end;
              end;
              // Band 7,8,8,9,9 / Gray 7,63,31,63,31 / Target x, y / Limit X, y
              if nDataLen > 4 then begin
                if nTemp in [31..39] then begin
                  nTemp := StrToIntDef(Trim(lstTemp[0]),0);
                  m_OffsetTable[nTemp].nIdx := nTemp-30;
                  m_OffsetTable[nTemp].Tx := StrToFloatDef(Trim(lstTemp[1]),0.0);
                  m_OffsetTable[nTemp].Ty := StrToFloatDef(Trim(lstTemp[2]),0.0);
                  m_OffsetTable[nTemp].Lx := StrToFloatDef(Trim(lstTemp[3]),0.0);
                  m_OffsetTable[nTemp].Ly := StrToFloatDef(Trim(lstTemp[4]),0.0);
                end;
              end;
            finally
              lstTemp.Free;
            end;
          end;
          m_Ver.OcOffSet := GetFileVerDate(sFileName,1)+' ' + GetStringCrc(sCrcData);
        finally
          // Close the file
          CloseFile(txtF);
        end;
      end;
    end;
  end;
end;

function TCommon.LoadPatGroup(SelPatGroupName : string) : TPatterGroup;
var
  PatGrpFile : TIniFile;
  i          : Integer;
  sPatGrpFileName : string;
  TempPatGrp : TPatterGroup;
begin

  sPatGrpFileName := Path.PATTERNGROUP + SelPatGroupName + '.grp';

  if FileExists(sPatGrpFileName) then begin
    PatGrpFile := TIniFile.Create(sPatGrpFileName);
    try
      // Count를 기준으로 Data 읽어 오기.

      TempPatGrp.GroupName  := SelPatGroupName;
      TempPatGrp.PatCount   := PatGrpFile.ReadInteger('PatternData', 'pattern_count', 0);
      if TempPatGrp.PatCount > 0 then begin
        SetLength(TempPatGrp.PatType,TempPatGrp.PatCount);
        SetLength(TempPatGrp.PatName,TempPatGrp.PatCount);
        SetLength(TempPatGrp.VSync,TempPatGrp.PatCount);
        SetLength(TempPatGrp.LockTime,TempPatGrp.PatCount);
        SetLength(TempPatGrp.Option,TempPatGrp.PatCount);
        for i := 0 to Pred(TempPatGrp.PatCount) do begin
          TempPatGrp.PatType[i]   := PatGrpFile.ReadInteger('PatternData', Format('PatType%d',[i]), 0);
          TempPatGrp.PatName[i]   := PatGrpFile.ReadString('PatternData', Format('PatName%d',[i]), '');
          TempPatGrp.VSync[i]   := PatGrpFile.ReadInteger('PatternData', Format('VSync%d',[i]), 0);
          TempPatGrp.LockTime[i]   := PatGrpFile.ReadInteger('PatternData', Format('LockTime%d',[i]), 0);
          TempPatGrp.Option[i]   := PatGrpFile.ReadInteger('PatternData', Format('Option%d',[i]), 0);
        end;
      end;

      {        WriteInteger('PATTERNDATA','PatType'+inttostr(j), PatType[j]);
        WriteString('PATTERNDATA','PatName'+inttostr(j), PatName[j]);}
    finally
      PatGrpFile.Free;
    end;
  end
  else begin // 만약에 Pattern Group File이 없으면 초기화 하자.
    TempPatGrp.GroupName := '';
    TempPatGrp.PatCount := 0;
  end;
  Result := TempPatGrp;
end;


procedure TCommon.LoadPGWriteReadPassAddr;
var
saAddress: TArray<String>;
i : Integer;
begin
  saAddress := SystemInfo.PG_WriteReadPassAddr.Split([',']);
  if Length(saAddress) = 0 then Exit;

  SetLength(PGWriteReadPassAddr,Length(saAddress));
  for I := 0 to Pred(Length(saAddress)) do
    PGWriteReadPassAddr[i]   := StrToIntDef(saAddress[i],0);
end;

procedure TCommon.LoadPsuFile;
var
  sFileName : string;
  i : Integer;
begin
// Load Pascal Script Data.
  sFileName := Path.MODEL_CUR + SystemInfo.TestModel+ '.psu';
  SystemInfo.ScriptVer := '';
  SystemInfo.ScriptCrc := '';
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    SystemInfo.nPwrVer[i] := 0;
  end;
  if FileExists(sFileName) then begin
    scrSequnce.LoadFromFile(sFileName );
    SystemInfo.ScriptVer := GetFileVerDate(sFileName);
    SystemInfo.ScriptCrc := GetScriptCrc( scrSequnce);
    m_Ver.psu_Date := GetFileVerDate(sFileName,1);
    m_Ver.psu_Crc  := GetScriptCrc( scrSequnce);
  end
  else begin
    MessageDlg(#13#10 + '[' + sFileName + '] Cannot find the file.!' , mtError, [mbOk], 0);
    m_bModelInfoNg := True;
  end;

  LoadPGWriteReadPassAddr;
end;



procedure TCommon.LogWorker;
var
  LogItem: TLogItem;
  _infile: TextFile;
  sInputData: string;
  i : Integer;
  dtNow: TDateTime;
begin
  while not TThread.CheckTerminated do
  begin
    
//    for I := DefCommon.CH1 to DefCommon.MAX_PG_CNT do begin
//      dtNow := Now;
//      if m_slLog[i].Count = 0 then break;
//      if (m_slLog[i].Count > 30) or (SecondsBetween(dtNow, m_dtSaveLog[i]) > 10) then begin
//        try
//
//          AssignFile(_infile, m_sFileName[i]);
//          try
//            if not FileExists(m_sFileName[i]) then
//              Rewrite(_infile)
//            else
//              Append(_infile);
//
//            WriteLn(_infile, m_slLog[i].Text);
//            m_slLog[i].Clear;
//            m_dtSaveLog[i]:= now;
//          finally
//            CloseFile(_infile);
//          end;
//
//        except
//          // Handle exceptions as needed
//        end;
//      end;
//    end;
//    Sleep(5);
  end;
end;


//procedure TCommon.LogWorker;
//var
//  LogItem: TLogItem;
//  _infile: TextFile;
//  sInputData: string;
//begin
//  while not TThread.CheckTerminated do
//  begin
//    
//    if FLogQueue = nil then Continue;
//
//    if FLogQueue.Count > 0 then
//    begin
//      LogItem := FLogQueue.Dequeue;
//      try
//        if CheckDir(ExtractFilePath(LogItem.FileName)) then
//          Continue;
//
//        AssignFile(_infile, LogItem.FileName);
//        try
//          if not FileExists(LogItem.FileName) then
//            Rewrite(_infile)
//          else
//            Append(_infile);
//
//          sInputData := format('Queue Cnt : %d ',[FLogQueue.Count])+ LogItem.Msg;
//          WriteLn(_infile, sInputData);
//        finally
//          CloseFile(_infile);
//        end;
//
//      except
//        // Handle exceptions as needed
//      end;
//    end;
//  end;
//end;

function TCommon.MakeModelData(model_name: String): AnsiString;
var
  sModelData : AnsiString;
begin
  sModelData := '';
  {$IFDEF DP860_TBD_XXXX}  //TBD:DP860?
  SetString(sModelData, PAnsiChar(@TestModelInfo.SigType), SizeOf(TestModelInfo));  //TBD:DP860?
  {$ENDIF}
  Result := sModelData;
end;

function TCommon.MakePatternGroupCrc: WORD;
var
  nToolCnt, nCnt : Integer;
  PatGroup           : TPatterGroup;
  i, k, nPatNum              : Integer;
  sBmpName                : string[32];
  sCrcData   , sTemp      : AnsiString;
  sGroupName, sPatName, sLog: string;
  wTemp, wCrc : Word;

  procedure WordToChar(wValue: WORD; pValue: PAnsiChar);
  begin
    pValue^:= AnsiChar(Lo(wValue)); Inc(pValue);
    pValue^:= AnsiChar(Hi(wValue)); Inc(pValue);
  end;

begin
  SetLength(sCrcData, 8000);
  nCnt:= 1;
  sGroupName:= EdModelInfoFLOW.PatGrpName;
  PatGroup := LoadPatGroup(sGroupName);

  for i := 0 to Pred(PatGroup.PatCount) do begin
    sPatName:= PatGroup.PatName[i];

    nToolCnt:= 0;
    sCrcData[nCnt]:= AnsiChar(i);                     Inc(nCnt);
    sCrcData[nCnt]:= AnsiChar(PatGroup.PatType[i]+1); Inc(nCnt);

    case PatGroup.PatType[i] of
      DefCommon.PTYPE_NORMAL : begin
        for k := 0 to pred(MAX_PATTERN_CNT) do begin
          sTemp := string(loadAllPat.InfoPat[k].pat.Data.PatName);
          nPatNum := k;
          if sPatName = sTemp then Break;
        end;

        nToolCnt := loadAllPat.InfoPat[nPatNum].pat.Data.ToolCnt;
        sCrcData[nCnt]:= AnsiChar(Byte(nToolCnt));    Inc(nCnt);

        for k := 0 to Pred(nToolCnt) do begin
          sCrcData[nCnt]:= AnsiChar(loadAllPat.InfoPat[nPatNum].Tool[k].Data.ToolType);     Inc(nCnt); // Tool Type.
          sCrcData[nCnt]:= AnsiChar(loadAllPat.InfoPat[nPatNum].Tool[k].Data.Direction);    Inc(nCnt); // Direction.
          WordToChar(loadAllPat.InfoPat[nPatNum].Tool[k].Data.Level, @sCrcData[nCnt]);      Inc(nCnt, 2);
          sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[k].Data.sx));  //sx
          wTemp := GetDrawPosPG(string(sTemp));
          WordToChar(wTemp, @sCrcData[nCnt]);                                               Inc(nCnt, 2);
          sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[k].Data.sy));  //sy
          wTemp := GetDrawPosPG(string(sTemp));
          WordToChar(wTemp, @sCrcData[nCnt]);                                               Inc(nCnt, 2);
          sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[k].Data.ex));  //ex
          wTemp := GetDrawPosPG(string(sTemp));
          WordToChar(wTemp, @sCrcData[nCnt]);                                               Inc(nCnt, 2);
          sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[k].Data.ey));  //ey
          wTemp := GetDrawPosPG(string(sTemp));
          WordToChar(wTemp, @sCrcData[nCnt]);                                               Inc(nCnt, 2);
          sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[k].Data.mx));  //mx
          wTemp := GetDrawPosPG(string(sTemp));
          WordToChar(wTemp, @sCrcData[nCnt]);                                               Inc(nCnt, 2);
          sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[k].Data.my));  //my
          wTemp := GetDrawPosPG(string(sTemp));
          WordToChar(wTemp, @sCrcData[nCnt]);                                               Inc(nCnt, 2);
          WordToChar(loadAllPat.InfoPat[nPatNum].Tool[k].Data.R, @sCrcData[nCnt]);          Inc(nCnt, 2); //R
          WordToChar(loadAllPat.InfoPat[nPatNum].Tool[k].Data.G, @sCrcData[nCnt]);          Inc(nCnt, 2); //G
          WordToChar(loadAllPat.InfoPat[nPatNum].Tool[k].Data.B, @sCrcData[nCnt]);          Inc(nCnt, 2); //B

        end;

      end;
      DefCommon.PTYPE_BITMAP : begin
        sCrcData[nCnt]:= AnsiChar(Byte(nToolCnt));         Inc(nCnt); //BMP => ToolCount=0
        FillChar(sBmpName[1], 32, 0);
        sBmpName := PatGroup.PatName[i];
        CopyMemory(@sCrcData[nCnt], @sBmpName[0],32);      Inc(nCnt, 32);
      end;
    end;
  end;
  SetLength(sCrcData, nCnt);
  m_Ver.CRC_Pat:= crc16(sCrcData, nCnt-1);
(*
  sLog:= '';
  for i := 1 to Pred(nCnt) do begin
    sLog:= sLog + format('%.2x ', [Byte(sCrcData[i])]);
  end;
  MLog(MAX_SYSTEM_LOG, sLog);

  MLog(MAX_SYSTEM_LOG, format('PatterGroup CRC=%x', [m_Ver.CRC_Pat]));
*)
  Result := m_Ver.CRC_Pat;
end;

function TCommon.ExtractNumbersFromString(inputString: string): string;
var
  regex: TRegEx;
  match: TMatch;
begin
  // 정규 표현식을 사용하여 숫자만 추출
  regex := TRegEx.Create('\d+');
  match := regex.Match(inputString);

  // 추출된 숫자를 모두 결합하여 반환
  Result := '';
  while match.Success do
  begin
    Result := Result + match.Value;
    match := match.NextMatch;
  end;
end;

procedure TCommon.MakePatternData(nIdx : Integer;makePatGrp : TPatterGroup; var dCheckSum: dword; var nTotalSize: Integer; var Data: TArray<System.Byte>);
var
  nToolCnt, nCnt : Integer;
  i, nPatNum              : Integer;
  sBmpName                : string[32];
  sCrcData   , sTemp      : AnsiString;
  sPatName                : string;
  wTemp : Word;
begin
  dCheckSum := 0;
  nTotalSize := 0;
  nPatNum := 0;


  if makePatGrp.PatType[nIdx] = PTYPE_BITMAP then begin
    nToolCnt := 0;
    nTotalSize := 32 ; // Pattern Name.
  end
  else begin
    sTemp := AnsiString(makePatGrp.PatName[nIdx]);
    for i := 0 to pred(MAX_PATTERN_CNT) do begin
      sPatName := string(loadAllPat.InfoPat[i].pat.Data.PatName);
      nPatNum := i;
      if sPatName = string(sTemp) then Break;
    end;
    nToolCnt := loadAllPat.InfoPat[nPatNum].pat.Data.ToolCnt;
    nTotalSize := 22 * nToolCnt;
  end;
  nTotalSize := nTotalSize + 3; // nIdx, pat type, tool count.
  SetLength(Data,nTotalSize);

  nCnt := 0;
  Data[nCnt] := Byte(nIdx);                          Inc(nCnt); // pattern No.
  Data[nCnt] := Byte(makePatGrp.PatType[nIdx]+1);    Inc(nCnt); // Pattern Type : 1 : Complex Pattern, 2 : BMP
  Data[nCnt] := Byte(nToolCnt);                      Inc(nCnt); // Tool Count.
  case makePatGrp.PatType[nIdx] of
    DefCommon.PTYPE_BITMAP : begin
      sBmpName := makePatGrp.PatName[nIdx];
      CopyMemory(@Data[nCnt],@sBmpName[0],32);       // nCnt := nCnt + 32;
    end;
    DefCommon.PTYPE_NORMAL : begin
      for i := 0 to Pred(nToolCnt) do begin
        Data[nCnt] := loadAllPat.InfoPat[nPatNum].Tool[i].Data.ToolType;   Inc(nCnt); // Tool Type.
        Data[nCnt] := loadAllPat.InfoPat[nPatNum].Tool[i].Data.Direction;  Inc(nCnt); // Direction.
        wTemp := loadAllPat.InfoPat[nPatNum].Tool[i].Data.Level;
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // Level

        sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[i].Data.sx));
        wTemp := GetDrawPosPG(string(sTemp));
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // sx

        sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[i].Data.sy));
        wTemp := GetDrawPosPG(string(sTemp));
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // sy

        sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[i].Data.ex));
        wTemp := GetDrawPosPG(string(sTemp));
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // ex

        sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[i].Data.ey));
        wTemp := GetDrawPosPG(string(sTemp));
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // ey

        sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[i].Data.mx));
        wTemp := GetDrawPosPG(string(sTemp));
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // mx

        sTemp := AnsiString(string(loadAllPat.InfoPat[nPatNum].Tool[i].Data.my));
        wTemp := GetDrawPosPG(string(sTemp));
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // my

        wTemp := loadAllPat.InfoPat[nPatNum].Tool[i].Data.R;
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // r

        wTemp := loadAllPat.InfoPat[nPatNum].Tool[i].Data.G;
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // g

        wTemp := loadAllPat.InfoPat[nPatNum].Tool[i].Data.B;
        CopyMemory(@Data[nCnt],@wTemp,2);                               Inc(nCnt); Inc(nCnt); // b
      end;
    end;
  end;

  sCrcData := '';
  for i := 0 to Pred(nTotalSize) do begin
    sCrcData := sCrcData + AnsiChar(Data[i]);
  end;
  dCheckSum := crc16(sCrcData,nTotalSize);
//  nTotalSize := nTotalSize + 2; // Total size + crc.
end;


procedure TCommon.MakeSummaryCsvLog(sHeader, sData: string);
var
  sFileName, sFilePath       : string;
//  sTemp1, sTemp2                        : string;
	txtF                                  : Textfile;
//  i, j                        : Integer;
begin
  // csv 파일명은 psu 내부에서 가져오기
{$IFDEF ISPD_A}
//  sFilePath := Path.PCDLog + FormatDateTime('yyyymm',now) + '\';
//  sFileName := sFilePath + Format('%s_%s_%s_PCDlog_%s.csv',[Common.SystemInfo.LineNo,
//                                                            Common.SystemInfo.ProcessName,
//                                                            Common.SystemInfo.EQPId,
//                                                            FormatDateTime('yyyymmdd',now)]);
{$ELSE}
  sFilePath := Path.SumCsv+formatDateTime('yyyymm',now) + '\';
  sFileName := sFilePath + formatDateTime('yyyymmdd',now) + Common.SystemInfo.EQPId + '.csv';
{$ENDIF}
  if CheckDir(sFilePath) then Exit;

//  Inc(m_nCsvLineCnt);
//  if m_nCsvLineCnt > 500 then begin
//    Inc(m_nCsvFileCnt);
//    m_nCsvLineCnt := 0;
//  end;

  if IOResult = 0 then begin
    try
      try
        AssignFile(txtF, sFileName);
        // File Check!
        if not FileExists(sFileName) then begin
          Rewrite(txtF);
          WriteLn(txtF, sHeader);
        end;

        Append(txtF);
        WriteLn(txtF, sData);
      except

      end;
    finally
      // Close the file
      CloseFile(txtF);
    end;
  end;
end;

procedure TCommon.Make_Bmp_List;
var
  iniF : TIniFile;
  image_fn : string;
  bList, sList, dList : TStringList;
  sr : TSearchrec;
  rslt, i : Integer;
  bmp1 : TBitmap;
begin

  image_fn := Path.BMP + 'image.lst';
  if FileExists(image_fn) then DeleteFile(image_fn);

  bList := TStringList.Create;
  sList := TStringList.Create;
  try
    rslt := FindFirst(Path.BMP + '*.bmp', FaanyFile, sr);
    while rslt = 0 do begin
     bList.Add(sr.Name);
     rslt := FindNext(sr);
    end;
    FindClose(sr);
    bmp1 := TBitmap.Create;
    try
      for i := 0 to bList.Count -1 do begin
         try
           bmp1.LoadFromFile(Path.BMP + bList[i]);
           if bmp1.PixelFormat = pf24bit then
             sList.Add(Format('%dx%d,%s',[bmp1.Width,bmp1.Height, bList[i]]));
         except end;
         Delay(2);
      end;
    finally
      bmp1.Free;
    end;
    sList.Sort;

    //Make Imagefile list
    iniF := TIniFile.Create(image_fn);
    try
      with iniF do begin
        dList := TStringList.Create;
        for i := 0 to sList.Count -1 do begin
          //DebugMessage(Format('bmpList %d: %s',[i, sList[i]]));
          dList.CommaText := sList[i];
          WriteString(dList[0], dList[1], '');
        end;
        dList.Free;

      end;
    finally
      iniF.Free;
      WritePrivateProfileString(nil, nil, nil, PChar(image_fn));
    end;
  finally
    sList.Free;
    bList.Free;
  end;
end;


function TCommon.IsExcelProcess(const ProcessID: DWORD): Boolean;
var
  FSWbemLocator: Variant;
  FWMIService: Variant;
  FWbemObjectSet: Variant;
  FWbemObject: Variant;
begin
  Result := False;
  try
    FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMv2', '', '');
    FWbemObjectSet := FWMIService.ExecQuery(Format('SELECT * FROM Win32_Process WHERE ProcessId = %d', [ProcessID]), 'WQL', 0);
    if not VarIsNull(FWbemObjectSet) and (FWbemObjectSet.Count > 0) then
    begin
      FWbemObject := FWbemObjectSet.ItemIndex(0);
      if not VarIsNull(FWbemObject) then
        Result := Pos('EXCEL.EXE', UpperCase(FWbemObject.Caption)) > 0;
    end;
  except
    // Handle exception as needed
  end;
end;




function IsProcessRunning(const ProcessName: string): Boolean;
var
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := False;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  if Process32First(FSnapshotHandle, FProcessEntry32) then
  begin
    repeat
      if SameText(ExtractFileName(FProcessEntry32.szExeFile), ProcessName) then
      begin
        Result := True;
        Break;
      end;
    until not Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure TerminateProcessesByFileName(const FileName: string);
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    if SameText(ExtractFileName(FProcessEntry32.szExeFile), FileName) then
    begin
//      ShowMessage(Format('Terminating process (PID: %d)...', [FProcessEntry32.th32ProcessID]));
      TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), FProcessEntry32.th32ProcessID), 0);
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;



procedure TCommon.CheckAndTerminateExcel(sExcelFileName : string);
begin
    TerminateProcessesByFileName(sExcelFileName);
end;



function TCommon.IfVersionIsLessThan(const currentVersion, targetVersion: string): Integer;
var
  currentVersionList, targetVersionList: TStringList;
  i: Integer;
begin
  currentVersionList := TStringList.Create;
  targetVersionList := TStringList.Create;
  try
    // '.'을 기준으로 버전 정보를 나눕니다.
    ExtractStrings(['.'], [], PChar(currentVersion), currentVersionList);
    ExtractStrings(['.'], [], PChar(targetVersion), targetVersionList);

    // 각 부분별로 비교하여 버전을 확인합니다.
    for i := 0 to Min(currentVersionList.Count - 1, targetVersionList.Count - 1) do
    begin
      if StrToIntDef(currentVersionList[i],0) < StrToIntdef(targetVersionList[i],1) then
      begin
        Exit(1);
      end
      else if StrToIntDef(currentVersionList[i],0) > StrToIntDef(targetVersionList[i],0) then
        Break; // 현재 버전이 타겟 버전보다 높으면 더 이상 비교할 필요 없음
    end;

    // 모든 부분이 같거나 현재 버전이 더 높음
    Result := 0;
  finally
    currentVersionList.Free;
    targetVersionList.Free;
  end;
end;

function TCommon.GetMemoryUsagePercentage: Double;
var
  MemoryStatus: TMemoryStatusEx;
begin
  // TMemoryStatusEx 구조체를 초기화
  ZeroMemory(@MemoryStatus, SizeOf(TMemoryStatusEx));
  MemoryStatus.dwLength := SizeOf(TMemoryStatusEx);

  // GlobalMemoryStatusEx 함수를 사용하여 메모리 정보 가져오기
  if GlobalMemoryStatusEx(MemoryStatus) then
  begin
    // 전체 물리 메모리와 사용 가능한 물리 메모리의 비율 계산
    Result := 100.0 * (1.0 - MemoryStatus.ullAvailPhys / MemoryStatus.ullTotalPhys);
  end
  else
  begin
    Result := 0.0; // 정보를 가져오지 못한 경우 0으로 설정
  end;
end;


function TCommon.GetCPUUsage: Double;
var
  IdleTime, KernelTime, UserTime: FILETIME;
  SystemTime: TDateTime;
  TotalTime, IdleTimeDelta, TotalTimeDelta: Int64;
begin
  // 초기 CPU 시간 정보 얻기
  if not GetSystemTimes(IdleTime, KernelTime, UserTime) then
    RaiseLastOSError;

  // 초기 전체 CPU 시간 계산
  TotalTime := Int64(UserTime) + Int64(KernelTime);

  // 짧은 지연 후 CPU 시간 다시 얻기
  Sleep(100);
  if not GetSystemTimes(IdleTime, KernelTime, UserTime) then
    RaiseLastOSError;

  // 전체 CPU 시간 및 유휴 시간 간격 계산
  TotalTimeDelta := (Int64(UserTime) + Int64(KernelTime)) - TotalTime;
  IdleTimeDelta := Int64(IdleTime) - Int64(IdleTime);

  // CPU 사용량 계산
  if TotalTimeDelta > 0 then
    Result := 1.0 - IdleTimeDelta / TotalTimeDelta
  else
    Result := 0.0;
end;



procedure TCommon.R2RLog(nCh: Integer; const Msg: String);
var
  sDate,sFilePath,sFileName,sMsg : string;
  _infile: TextFile;
begin
  try
    // Enqueue log item for asynchronous processing
    if CheckDir(Path.R2RLOG) then
      Exit;

    sDate := FormatDateTime('yyyymmdd', Now);
    sFilePath := Path.R2RLOG + sDate + '\';

    if CheckDir(sFilePath) then
      Exit;
    sFileName := sFilePath + Format('R2RLog_%s_%s_Ch%d.txt', [systemInfo.EQPId, FormatDateTime('mmdd', Now), nCh + 1]);

    sMsg := FormatDateTime('(hh:mm:ss.zzz) : ', Now) + Msg;
    AssignFile(_infile, sFileName);

    try
      if not FileExists(sFileName) then
        Rewrite(_infile)
      else
        Append(_infile);

      WriteLn(_infile, sMsg);
    finally
      CloseFile(_infile);
    end;

  except
    on E: Exception do
    begin
      Sleep(10); //MLog 충돌 방지- IO 103
    end;
  end;
end;

procedure TCommon.ProcessCycle;
var
  dtNow: TDateTime;
  nCh: Integer;
begin
  while not TThread.CheckTerminated do begin
    try
     dtNow:= Now;
    //MLog 저장 확인
      for nCh := DefCommon.CH1 to DefCommon.MAX_SYSTEM_LOG do begin
        m_csLog[nCh].Enter;

        try
          if (m_slLog[nCh].Count > 0) then begin
            if  DayOf(m_dtSaveLog[nCh]) <> DayOf(dtNow) then begin
              SaveMLog(nCh, m_dtSaveLog[nCh]); //날짜가 변경된 경우 이전날짜 File로 저장
            end
            else if (m_slLog[nCh].Count > LogAccumulateCount) or (SecondsBetween(dtNow, m_dtSaveLog[nCh]) > LogAccumulateSecond) then begin
              SaveMLog(nCh, dtNow);
            end;
          end;
        finally
          m_csLog[nCh].Leave;
        end;
      end;
      Sleep(1000);
    finally
    end;
  end;
 
  //종료 시 마지막 저장
  dtNow:= Now;
  for nCh := DefCommon.CH1 to DefCommon.MAX_SYSTEM_LOG do begin
    m_csLog[nCh].Enter;
    SaveMLog(nCh, dtNow);
    m_csLog[nCh].Leave;
  end;

end;

procedure TCommon.SaveMLog(nCh : Integer; dtSave: TDateTime);
var
  sDate, sFilePath, sFileName,sFileDate: String;
  sDir: String;
  logFile: TextFile;
begin
  if m_slLog[nCh].Count = 0 then Exit;
 
  sDate := FormatDateTime('yyyymmdd', dtSave);
  sFilePath := Path.MLOG + sDate + '\';
  ForceDirectories(sFilePath);

  sFileDate := FormatDateTime('yyyymmdd_AM/PM', dtSave);
 
  case nCh of
    DefCommon.MAX_SYSTEM_LOG  : sFileName := sFilePath + Format('SystemLog_%s_%s.txt',[systemInfo.EQPId,sFileDate]);
    DefCommon.MAX_PLC_LOG     : sFileName := sFilePath + Format('PLC_%s_%s.txt',[systemInfo.EQPId,sFileDate])
    else begin
      sFileName := sFilePath + Format('MLog_%s_%s_Ch%d.txt',[systemInfo.EQPId,sFileDate,nCh + 1]);
    end;
  end;
 
  AssignFile(logFile, sFileName);
  try
    try
      {$I-}
      if FileExists(sFileName) then Append(logFile) else Rewrite(logFile);
 
      WriteLn(logFile, Trim(m_slLog[nCh].Text));
 
      m_slLog[nCh].Clear;
      m_dtSaveLog[nCh]:= Now; //dtSave;
      {$I+}
    except
      on E: Exception do  begin
        Sleep(10); //MLog 충돌 방지- IO 103
        if nCh <> MAX_SYSTEM_LOG then begin
          MLog(MAX_SYSTEM_LOG, format('Exception On SaveMLog Ch=%d, Err=%s', [nCh, E.Message]));
        end;
      end;
    end;
  finally
    CloseFile(logFile);
  end;
end;

procedure TCommon.MLog(nCh : Integer; const sLog: String; bSave: Boolean);
var
  dtNow: TDateTime;
begin
  if (nCh < DefCommon.CH1) or (nCh > DefCommon.MAX_PG_CNT) then nCh := DefCommon.MAX_SYSTEM_LOG;

  dtNow:= Now;
  m_csLog[nCh].Enter;
  if (m_slLog[nCh].Count > 0) and (DayOf(m_dtSaveLog[nCh]) <> DayOf(dtNow)) then begin
    SaveMLog(nCh, m_dtSaveLog[nCh]); //날짜가 변경된 경우 이전 File로 저장
  end;
 
  if bSave and (sLog = '') then begin
    //단순 저장 요청 - 프로그램 종료 시나 즉시 저장이 필요할 경우
    SaveMLog(nCh, dtNow);
  end
  else begin
    //저장 요청이 아닌 경우Log 추가
    m_slLog[nCh].Add(FormatDateTime('HH:NN:SS.ZZZ => ', dtNow) + sLog);
  end;
 
  //로그 라인수가 누적 라인수 초과이거나누적시간(초) 초과인 경우File로 저장
  if (m_slLog[nCh].Count > LogAccumulateCount) or (SecondsBetween(dtNow, m_dtSaveLog[nCh]) > LogAccumulateSecond) or bSave then begin
    SaveMLog(nCh, dtNow);
  end;
  m_csLog[nCh].Leave;
 
end;

//procedure TCommon.MLog(nCh: Integer; const Msg: String);
//var
//  sDate,sFilePath,sFileDate,sFileName : string;
//begin
//  try
//
//    if (nCh < DefCommon.CH1) or (nCh > MAX_PLC_LOG) then  nCh := DefCommon.MAX_SYSTEM_LOG;
//
//    if CheckDir(Path.MLOG) then
//      Exit;
//
//    sDate := FormatDateTime('yyyymmdd', Now);
//    sFilePath := Path.MLOG + sDate + '\';
//
//    sFileDate := FormatDateTime('yyyymmdd_AM/PM', Now);
//
//    if CheckDir(sFilePath) then
//      Exit;
//
//    case nCh of
//      DefCommon.MAX_SYSTEM_LOG: sFileName := sFilePath + Format('SystemLog_%s_%s.txt',[systemInfo.EQPId,sFileDate]);
//      DefCommon.MAX_PLC_LOG: sFileName :=  sFilePath + Format('PLC_%s_%s.txt',[systemInfo.EQPId,sFileDate])
//      else
//        sFileName := sFilePath + Format('MLog_%s_%s_Ch%d.txt',[systemInfo.EQPId,sFileDate,nCh + 1]);
//    end;
//    m_sFileName[nCh] := sFileName;
//    m_slLog[nCh].Add(FormatDateTime('(hh:mm:ss.zzz) : ', Now) + Msg);
//  except
//    // Handle exceptions as needed
//  end;
//end;


//procedure TCommon.MLog(nCh: Integer; const Msg: String);
//var
//  LogItem: TLogItem;
//  sDate,sFilePath,sFileDate : string;
//begin
//  try
//    // Enqueue log item for asynchronous processing
//
////    AddMLog(nCh,Msg,True);
////    Exit;
//
//    if (nCh < DefCommon.CH1) or (nCh > MAX_PLC_LOG) then  nCh := DefCommon.MAX_SYSTEM_LOG;
//
//    if CheckDir(Path.MLOG) then
//      Exit;
//
//    sDate := FormatDateTime('yyyymmdd', Now);
//    sFilePath := Path.MLOG + sDate + '\';
//
//    sFileDate := FormatDateTime('yyyymmdd_AM/PM', Now);
//
//    if CheckDir(sFilePath) then
//      Exit;
//
//    case nCh of
//      DefCommon.MAX_SYSTEM_LOG: LogItem.FileName := sFilePath + Format('SystemLog_%s_%s.txt',[systemInfo.EQPId,sFileDate]);
//      DefCommon.MAX_PLC_LOG: LogItem.FileName :=  sFilePath + Format('PLC_%s_%s.txt',[systemInfo.EQPId,sFileDate])
//      else
//        LogItem.FileName := sFilePath + Format('MLog_%s_%s_Ch%d.txt',[systemInfo.EQPId,sFileDate,nCh + 1]);
//    end;
//    LogItem.Msg :=FormatDateTime('(hh:mm:ss.zzz) : ', Now) + Msg;
//    FLogQueue.Enqueue(LogItem);
//  except
//    // Handle exceptions as needed
//  end;
//end;


// MLog 함수 개선
//procedure TCommon.MLog(nCh: Integer; const Msg: String);
//var
//  _infile: TextFile;
//  sInputData, sFileName, sDate, sFilePath,sFileDate: String;
//  MyClass: TComponent;
//begin
//
//  try
//    if CheckDir(Path.MLOG) then
//      Exit;
//
//    sDate := FormatDateTime('yyyymmdd', Now);
//    sFilePath := Path.MLOG + sDate + '\';
//
//    sFileDate := FormatDateTime('yyyymmdd_AM/PM', Now);
//
//    if CheckDir(sFilePath) then
//      Exit;
//
//    case nCh of
//      DefCommon.MAX_SYSTEM_LOG: sFileName := sFilePath + Format('SystemLog_%s_%s.txt',[systemInfo.EQPId,sFileDate]);
//      DefCommon.MAX_PLC_LOG: sFileName :=  sFilePath + Format('PLC_%s_%s.txt',[systemInfo.EQPId,sFileDate])
//      else
//        sFileName := sFilePath + Format('MLog_%s_%s_Ch%d.txt',[systemInfo.EQPId,sFileDate,nCh + 1]);
//    end;
//
//    AssignFile(_infile, sFileName);
//
//    try
//      if not FileExists(sFileName) then
//        Rewrite(_infile)
//      else
//        Append(_infile);
//
//      sInputData := FormatDateTime('(hh:mm:ss.zzz) : ', Now) + Msg;
//      WriteLn(_infile, sInputData);
//    finally
//      CloseFile(_infile);
//    end;
//
//  except
//    on E: Exception do
//    begin
//      Sleep(10); //MLog 충돌 방지- IO 103
//    end;
//  end;
//
//end;

//procedure TCommon.MLog(nCh : Integer;const Msg: String);
//var
//  _infile : TextFile;
//  sInputData, sFileName, sDate,sFileDate, sFilePath: String;
////  nCurTime, nFreq : Int64;
////	dElapse : Double;
//begin
////  try
//
//    if CheckDir(Path.MLOG) then begin
//      Exit;
//    end;
//    sDate := FormatDateTime('yyyymmdd', Now);
//    sFileDate := FormatDateTime('yyyymmdd_AM/PM', Now);
//
//    sFilePath := Path.MLOG + sDate + '\';
//    if CheckDir(sFilePath) then begin
//      Exit;
//    end;
//    case nCh of
//      DefCommon.MAX_SYSTEM_LOG  : sFileName := sFilePath + Format('SystemLog_%s_%s.txt',[systemInfo.EQPId,sFileDate]);
//      DefCommon.MAX_PLC_LOG     : sFileName := sFilePath + Format('PLC_%s_%s.txt',[systemInfo.EQPId,sFileDate])
//      else begin
//        sFileName := sFilePath + Format('MLog_%s_%s_Ch%d.txt',[systemInfo.EQPId,sFileDate,nCh + 1]);
//      end;
//    end;
//
//    try
//      sInputData := FormatDateTime('(hh:mm:ss.zzz) : ', Now) + Msg + #13#10;
//      TFile.AppendAllText(sFileName, sInputData, TEncoding.UTF8);
//    except
//    end;
//
////    try
////      AssignFile(_infile, sFileName);
////      if not FileExists(sFileName) then
////        Rewrite(_infile)
////      else
////        Append(_infile);
////      sInputData := FormatDateTime('(hh:mm:ss.zzz) : ', Now) + Msg;
////      WriteLn(_infile, sInputData);
////    except
////      on E: Exception do  begin
////        Sleep(10); //MLog 충돌 방지- IO 103
////        end;
////      end;
////    end;
////  finally
////    CloseFile(_infile);
////  end;
//end;

procedure TCommon.HWCIDLogLog(nCh : Integer;const sPID,sSN, sData: String);
var
  _infile : TextFile;
  sInputData, sFileName, sDate, sFilePath,sLine: String;

begin
  if CheckDir(Path.HWCIDLog) then begin
    Exit;
  end;
  sDate := FormatDateTime('yyyymm', Now);
  sFilePath := Path.HWCIDLog + sDate + '\';
  if CheckDir(sFilePath) then begin
    Exit;
  end;

  sFileName := sFilePath + Format('HWCID_Log_%s_%s.csv',[systemInfo.EQPId,FormatDateTime('yymmdd', Now)]);

  try
    try
      AssignFile(_infile, sFileName);
      try

        if not FileExists(sFileName) then begin
          //Header 생성
          Rewrite(_infile);
          sLine:= 'Date,Equipment ID,Equip_Ch,Panel ID,Serial Num,Bundle Value(HEX),Board ID Value(HEX),HWCID Read(0x74),HWCID Read(0x7C),HWCID Value(HEX)';
          WriteLn(_infile, sLine);
        end;

        //Data
        Append(_infile);
        sLine := FormatDateTime('hh:mm:ss.zzz, ', Now)+ Format('%s,%d,%s,%s,',[systemInfo.EQPId,nCh+1,sPID,sSN]);
        sLine := sLine + sData;
        WriteLn(_infile, sLine);
      except
//        m_csWriteCsvLog.Release;
      end;
    finally
      CloseFile(_infile); // Close the file
//      m_csWriteCsvLog.Release;
    end;
  except
//    m_csWriteCsvLog.Release;
  end;
end;


procedure TCommon.RePGMLog(nCh : Integer;const sPID,sSN: String);
var
  _infile : TextFile;
  sInputData, sFileName, sDate, sFilePath,sLine: String;
//  nCurTime, nFreq : Int64;
//	dElapse : Double;
begin
//  DebugMessage('[MLog] ' + Msg);
  if CheckDir(Path.RePGMLog) then begin
    Exit;
  end;
  sDate := FormatDateTime('yyyymmdd', Now);
  sFilePath := Path.RePGMLog + sDate + '\';
  if CheckDir(sFilePath) then begin
    Exit;
  end;

  sFileName := sFilePath + Format('RePGM_NG_Log_%s_%s_Ch%d.csv',[systemInfo.EQPId,sDate,nCh + 1]);

  try
    try
      AssignFile(_infile, sFileName);
      try

        if not FileExists(sFileName) then begin
          //Header 생성
          Rewrite(_infile);
          sLine:= 'TIME,PID,SN';
          WriteLn(_infile, sLine);
        end;

        //Data
        Append(_infile);
        sLine := FormatDateTime('hh:mm:ss.zzz, ', Now)+ Format('%s,%s,',[sPID,sSN]);
        WriteLn(_infile, sLine);
      except
//        m_csWriteCsvLog.Release;
      end;
    finally
      CloseFile(_infile); // Close the file
//      m_csWriteCsvLog.Release;
    end;
  except
//    m_csWriteCsvLog.Release;
  end;
end;

procedure TCommon.Shutdown_FaultLog(nCh : Integer;const sPID,sSN: String);
var
  _infile : TextFile;
  sInputData, sFileName, sDate, sFilePath,sLine: String;
//  nCurTime, nFreq : Int64;
//	dElapse : Double;
begin
//  DebugMessage('[MLog] ' + Msg);
  if CheckDir(Path.Shutdown_Fault_Log) then begin
    Exit;
  end;
  sDate := FormatDateTime('yyyymmdd', Now);
  sFilePath := Path.Shutdown_Fault_Log + sDate + '\';
  if CheckDir(sFilePath) then begin
    Exit;
  end;

  sFileName := sFilePath + Format('Shutdown_Fault_NG_Log_%s_%s_Ch%d.csv',[systemInfo.EQPId,sDate,nCh + 1]);

  try
    try
      AssignFile(_infile, sFileName);
      try

        if not FileExists(sFileName) then begin
          //Header 생성
          Rewrite(_infile);
          sLine:= 'TIME,PID,SN';
          WriteLn(_infile, sLine);
        end;

        //Data
        Append(_infile);
        sLine := FormatDateTime('hh:mm:ss.zzz, ', Now)+ Format('%s,%s,',[sPID,sSN]);
        WriteLn(_infile, sLine);
      except
//        m_csWriteCsvLog.Release;
      end;
    finally
      CloseFile(_infile); // Close the file
//      m_csWriteCsvLog.Release;
    end;
  except
//    m_csWriteCsvLog.Release;
  end;
end;

procedure TCommon.MLogWaveformData(nCh : Integer;const Msg: String);
var
  _infile : TextFile;
  sInputData, sFileName, sDate, sFilePath: String;
//  nCurTime, nFreq : Int64;
//	dElapse : Double;
begin
//  DebugMessage('[MLog] ' + Msg);
  if CheckDir(Path.MLOG) then begin
    Exit;
  end;
  sDate := FormatDateTime('yyyymmdd', Now);
  sFilePath := Path.MLOG + sDate + '\';
  if CheckDir(sFilePath) then begin
    Exit;
  end;
  case nCh of
    DefCommon.MAX_SYSTEM_LOG  : sFileName := sFilePath + Format('SystemLog_%s_%s.txt',[systemInfo.EQPId,sDate]);
    DefCommon.MAX_PLC_LOG     : sFileName := sFilePath + Format('PLC_%s_%s.txt',[systemInfo.EQPId,sDate])
    else begin
      sFileName := sFilePath + Format('MLogWaveformData_%s_%s_Ch%d.txt',[systemInfo.EQPId,sDate,nCh + 1]);
    end;
  end;

  try
    try
      AssignFile(_infile, sFileName);
      if not FileExists(sFileName) then
        Rewrite(_infile)
      else
        Append(_infile);
      sInputData := FormatDateTime('(hh:mm:ss.zzz) : ', Now) + Msg;
      WriteLn(_infile, sInputData);
    except
      on E: Exception do  begin
        Sleep(10); //MLog 충돌 방지- IO 103
        if nCh <> MAX_SYSTEM_LOG then begin
          MLog(MAX_SYSTEM_LOG, format('Exception On Mlog Ch=%d, Err=%s', [nCh, E.Message]));
        end;
      end;
    end;
  finally
    CloseFile(_infile);
  end;
end;



function TCommon.GetDiskSpacePercentage(const Drive: string): Integer;
var
  RootPath: string;
  SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters: DWORD;
  FreeSpace, TotalSpace: Int64;
begin
  Result := -1; // Default value in case of an error

  // Build the root path for the specified drive
  RootPath := ExtractFileDrive(Drive);

  // Call GetDiskFreeSpace to get disk space information
  if GetDiskFreeSpace(PChar(RootPath), SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters) then
  begin
    FreeSpace := Int64(SectorsPerCluster) * BytesPerSector * FreeClusters;
    TotalSpace := Int64(SectorsPerCluster) * BytesPerSector * TotalClusters;

    if TotalSpace > 0 then
      Result := 100 - Trunc((FreeSpace / TotalSpace) * 100);
  end;
end;


function TCommon.ProcessMemory: longint;
var
  pmc: PPROCESS_MEMORY_COUNTERS;
  cb: Integer;
begin
  // Get the used memory for the current process
  cb := SizeOf(TProcessMemoryCounters);
  GetMem(pmc, cb);
  pmc^.cb := cb;
  if GetProcessMemoryInfo(GetCurrentProcess(), pmc, cb) then
     Result:= Longint(pmc^.WorkingSetSize);

  FreeMem(pmc);
end;


procedure ReadCSVFileReverse(const FileName: string; var Lines: TStringList);
var
  FileStream: TFileStream;
  Line: string;
  Buffer: array[0..1023] of Char;
  BufferSize, NewLinePos: Integer;
begin
  Lines.Clear;

  if not FileExists(FileName) then
    Exit;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    BufferSize := 0;

    // 파일을 뒤에서부터 읽어오기 위해 파일 크기를 알아냅니다.
    FileStream.Seek(0, soFromEnd);
    while FileStream.Position > 0 do
    begin
      // 파일 포인터를 뒤로 이동하면서 읽기
      FileStream.Seek(-SizeOf(Buffer), soCurrent);
      BufferSize := FileStream.Read(Buffer[0], SizeOf(Buffer));

      // 버퍼 내에서 역순으로 줄 바꿈 문자('\n')를 찾습니다.
      NewLinePos := BufferSize - 1;
      while (NewLinePos >= 0) and (Buffer[NewLinePos] <> #10) do
        Dec(NewLinePos);

      // 줄을 추출하여 문자열 리스트에 추가합니다.
      Line := Copy(Buffer, NewLinePos + 1, BufferSize - NewLinePos - 1);
      Lines.Insert(0, Line);
    end;
  finally
    FileStream.Free;
  end;
end;



//function TCommon.ReadLGDDLLSummaryLog_New(sPid, sSn, sDate: string; nCh: Integer): string;
//var
//  asSummaryHeader, asSummaryGroupHeader, asSummaryAPDRData, asSummaryData: TArray<String>;
//  sFileName, sCopyFileName: string;
//  sLine, sResult: string;
//  BufferedFileStream: TFileStream;
//  i,Total, nlineCount: Integer;
//  sw : TStopwatch;
//  ch : Char;
//begin
//  sw := TStopwatch.StartNew;
//  Result := '';
//  sResult := '';
//  sFileName := System.IOUtils.TPath.Combine(Common.Path.LGDDLL, Format('Oclog\SummaryLog\%s_Summary_Log_%s.csv', [Common.SystemInfo.EQPId, sDate]));
//
//  if not TFile.Exists(sFileName) then
//    Exit;
//
//  sCopyFileName := System.IOUtils.TPath.Combine(Common.Path.LGDDLL, Format('Oclog\SummaryLog\%s_Summary_Log_%s_%d.csv', [Common.SystemInfo.EQPId, sDate, nCh]));
//  TFile.Copy(sFileName, sCopyFileName, False);
//
//  if not TFile.Exists(sCopyFileName) then
//    Exit;
//
//  try
//    asSummaryAPDRData := nil;
//
//    try
//      BufferedFileStream := TBufferedFileStream.Create(sCopyFileName, fmOpenRead);
//      sLine := '';
//      Total := 0;
//      while BufferedFileStream.Read(ch, 1) = 1 do
//      begin
//        sLine := sLine + ch;
//        if (ch = #13) or (ch = #10) then begin
//          asSummaryData := sLine.Split([',']);
//          if asSummaryData[0] = 'BIN_VER' then
//            asSummaryHeader := asSummaryData
//          else if asSummaryData[0] = 'BIN' then
//            asSummaryGroupHeader := asSummaryData
//          else if (sPid = asSummaryData[4]) or (sSn = asSummaryData[5]) then
//            asSummaryAPDRData := asSummaryData;
//          sLine := '';
//        end;
//      end;
//    finally
//      sw.Stop;
//      MLog(MAX_SYSTEM_LOG, 'TBufferedFileStream msec : ' + sw.ElapsedMilliseconds.ToString);
//      BufferedFileStream.Free;
//    end;
//
//    if Length(asSummaryAPDRData) = 0 then
//      Exit;
//
//    // StringBuilder 사용
//    with TStringBuilder.Create do
//    begin
//      try
//        sw := TStopwatch.StartNew;
//        for i := 0 to High(asSummaryAPDRData) do
//        begin
//          if Common.SystemInfo.OCType = DefCommon.PreOCType then
//          begin
//            if System.Length(asSummaryGroupHeader[i]) = 0 then
//              asSummaryGroupHeader[i] := 'OC';
//
//            Append(asSummaryGroupHeader[i])
//              .Append(':')
//              .Append(asSummaryHeader[i])
//              .Append(':')
//              .Append(asSummaryAPDRData[i]);
//          end
//          else
//          begin
//            asSummaryGroupHeader[i] := 'OC';
//
//            if asSummaryAPDRData = nil then
//              Exit;
//
//            Append(asSummaryGroupHeader[i])
//              .Append(':')
//              .Append(asSummaryHeader[i])
//              .Append(':')
//              .Append(asSummaryAPDRData[i]);
//          end;
//
//          if i < High(asSummaryAPDRData) then
//            Append(',');
//        end;
//
//        sResult := ToString;
//      finally
//        Free;
//      end;
//    end;
//
//  finally
//    // 파일 삭제
//    if TFile.Exists(sCopyFileName) then
//      TFile.Delete(sCopyFileName);
//  end;
//
//  Result := sResult;
//end;



function TCommon.ReadLGDDLLSummaryLog_New(sPid, sSn, sDate: string; nCh: Integer): string;
var
  asSummaryHeader, asSummaryGroupHeader, asSummaryAPDRData, asSummaryData: TArray<String>;
  sFileName, sCopyFileName: String;
  sLine, sResult: String;
  txtFile: TEXTFILE;
  i, nlineCount: Integer;
  sw : TStopwatch;
begin
  try
    Result := '';
    sResult := '';
    sFileName := Common.Path.LGDDLL + format('Oclog\SummaryLog\%s_Summary_Log_', [Common.SystemInfo.EQPId]) + sDate + '.csv';

    if not FileExists(sFileName) then
      Exit;

    sCopyFileName := Common.Path.LGDDLL + format('Oclog\SummaryLog\%s_Summary_Log_%s_%d.csv', [Common.SystemInfo.EQPId, sDate, nCh]);
    CopyFile(PChar(sFileName), Pchar(sCopyFileName), False);

    if not FileExists(sCopyFileName) then
      Exit;


    try
      AssignFile(txtFile, sCopyFileName);
      sw := TStopwatch.StartNew;
      Reset(txtFile);
      nlineCount := 0;

      // 초기화를 한번만 수행하도록 수정
      asSummaryAPDRData := nil;

      while not Eof(txtFile) do
      begin
        ReadLn(txtFile, sLine);
        asSummaryData := sLine.Split([',']);
        Inc(nlineCount);

        if asSummaryData[0] = 'BIN_VER' then
          asSummaryHeader := sLine.Split([','])
        else if asSummaryData[0] = 'BIN' then
          asSummaryGroupHeader := sLine.Split([','])
        else if (sPid = asSummaryData[4]) or (sSn = asSummaryData[5]) then
          asSummaryAPDRData := sLine.Split([',']);
      end;


      if Length(asSummaryAPDRData) = 0 then
        Exit;

      // StringBuilder 사용
      with TStringBuilder.Create do
      begin
        try
          for i := 0 to System.Length(asSummaryAPDRData) -1 do
          begin
            if Common.SystemInfo.OCType = DefCommon.PreOCType then
            begin
              if System.Length(asSummaryGroupHeader[i]) = 0 then
                asSummaryGroupHeader[i] := 'OC';

              Append(asSummaryGroupHeader[i])
                .Append(':')
                .Append(asSummaryHeader[i])
                .Append(':')
                .Append(asSummaryAPDRData[i]);

            end
            else
            begin
              asSummaryGroupHeader[i] := 'OC';

              if asSummaryAPDRData = nil then
                Exit;

              Append(asSummaryGroupHeader[i])
                .Append(':')
                .Append(asSummaryHeader[i])
                .Append(':')
                .Append(asSummaryAPDRData[i]);
            end;

            if i < System.Length(asSummaryAPDRData) - 1 then
              Append(',');
          end;

          sResult := ToString;
        finally
          Free;
        end;
      end;

    finally
      sw.Stop;
      MLog(nCh, 'ReadLGDDLLSummaryLog msec : ' + sw.ElapsedMilliseconds.ToString);
      CloseFile(txtFile);
      // 파일 삭제
      if FileExists(sCopyFileName) then
        DeleteFile(sCopyFileName);
    end;

  finally
    Result := sResult;
  end;
end;





function TCommon.ReadLGDDLLSummaryLog(sPid,sSn,sDate : string; nCh : Integer) : string;
var
  asSummaryHeader,asSummaryGroupHeader,asSummaryAPDRData,asSummaryData: TArray<String>;
  sComputerName: String;
  sFileName , sCopyFileName: String;
  sLine,sResult: String;
  txtFile: TEXTFILE;
  i,nlineCount: Integer;
  nStartTick, nEndTick : Cardinal;
  Lines: TStringList;
const
//  GroupName = 'AFM_VRR_OPTIMUM:';
  GroupName = 'OC';
begin
//  m_csReadCsvLog.Acquire; // 동시 접근 방지
//  sDate := FormatDateTime('yymmdd', PasScr[nCh].TestInfo);
  try
    Result := '';
    sResult := '';
    sFileName:= Common.Path.LGDDLL +format('Oclog\SummaryLog\%s_Summary_Log_',[Common.SystemInfo.EQPId]) + sDate +'.csv';
    if not FileExists(sFileName) then begin
      //File not Found
      Exit;
    end;
    sCopyFileName := Common.Path.LGDDLL +format('Oclog\SummaryLog\%s_Summary_Log_%s_%d.csv',[Common.SystemInfo.EQPId, sDate, nCh]);
    CopyFile(PChar(sFileName),Pchar(sCopyFileName),False);

    if FileExists(sCopyFileName) = false then begin
      //File not Found
      Exit;
    end;
    AssignFile(txtFile, sCopyFileName);

    Reset(txtFile);
    nlineCount := 0;
    while not Eof(txtFile) do begin
      ReadLn(txtFile, sLine);
      asSummaryData:= sLine.Split([',']);
      Inc(nlineCount); // 현재 처리 중인 라인 카운트 증가
      if asSummaryData[0] = 'BIN_VER' then begin
        asSummaryHeader:= sLine.Split([',']);   //SummaryLog Header 저장
      end;
      if asSummaryData[0] = 'BIN' then begin
        asSummaryGroupHeader:= sLine.Split([',']);   //SummaryLog Group Header 저장
      end;
      if (sPid = asSummaryData[4]) or (sSn = asSummaryData[5]) then begin
        asSummaryAPDRData := sLine.Split([',']);
      end;
    end;
    if Length(asSummaryAPDRData) = 0 then Exit;

    for I := 0 to Length(asSummaryAPDRData) do begin
      if Common.SystemInfo.OCType = DefCommon.PreOCType then begin
        if Length(asSummaryGroupHeader[i]) = 0 then asSummaryGroupHeader[i] := GroupName;
        if i = Length(asSummaryAPDRData)  then sResult := sResult + asSummaryGroupHeader[i] + ':' + asSummaryHeader[i] + ':' + asSummaryAPDRData[i]
        else sResult := sResult + asSummaryGroupHeader[i] + ':' + asSummaryHeader[i] + ':' + asSummaryAPDRData[i]+ ',';
      end
      else begin
        asSummaryGroupHeader[i] := GroupName;
        if asSummaryAPDRData = nil  then Exit;

        if i = Length(asSummaryAPDRData)  then sResult := sResult + GroupName + ':' + asSummaryHeader[i] + ':' + asSummaryAPDRData[i]
        else sResult := sResult + GroupName + ':' + asSummaryHeader[i] + ':' + asSummaryAPDRData[i]+ ',';
      end;

    end;

  finally
    Result := sResult;
//    m_csReadCsvLog.Release; //copy하면 상관없음
    CloseFile(txtFile);
     //지우기
    if FileExists(sCopyFileName) = True then begin
      DeleteFile(sCopyFileName)
    end;

  end;
end;


function FindFilesWithText(const directoryPath, searchText: string; fileExtensions: TArray<string>): TStringList;
var
  searchResult: TStringList;
  searchOption: TSearchOption;
  filePath: string;
  fileExt: string;
  fileContent: TStringList;
  i: Integer;
  files: TArray<string>;
  fileSearch: TSearchRec;
begin
  searchResult := TStringList.Create;
  try
    searchOption := TSearchOption.soAllDirectories;
    if not TDirectory.Exists(directoryPath) then
      Exit;

    for fileExt in fileExtensions do
    begin
      if Length(TDirectory.GetFiles(directoryPath, '*.' + fileExt, searchOption)) = 0 then
        Continue;

      if FindFirst(directoryPath + '*.' + fileExt, faAnyFile, fileSearch) = 0 then
      begin
        repeat
          filePath := System.IOUtils.TPath.Combine(directoryPath, fileSearch.Name);
          fileContent := TStringList.Create;
          try
            if Pos(searchText, filePath) > 0 then
            begin
              searchResult.Add(filePath);
            end;
          finally
            fileContent.Free;
          end;
        until FindNext(fileSearch) <> 0;

        FindClose(fileSearch);
      end;
    end;

    Result := searchResult;
  except
    searchResult.Free;
    raise;
  end;
end;

procedure TCommon.SearchForFilesWithText(sDirectoryPath,sSearchText : string);
var
  fileExtensions: TArray<string>;
  foundFiles: TStringList;
  filePath: string;
begin

  fileExtensions := ['dll']; // 검색할 파일 확장자

  foundFiles := FindFilesWithText(sDirectoryPath, sSearchText, fileExtensions);
  try
    for filePath in foundFiles do
      DeleteFile(filePath);
  finally
    foundFiles.Free;
  end;
end;


procedure TCommon.ReadOpticInfo;
var
  fSys        : TIniFile;
  i : Integer;
begin
  fSys := TIniFile.Create(Path.OcInfo);
  try
    OpticInfo.CalModelType := fSys.ReadInteger('CA310_CALIBRATION', 'CAL_MODEL_TYPE',  0);
  finally
    fSys.Free;
  end;
end;

Function TCommon.ReadPGSettingInfo : Boolean;
var
  fSys        : TIniFile;
  i : Integer;
  arTemp   : TArray<string>; //2023-03-28 jhhwang (for T/T Test)
begin
  if not FileExists(Path.PGInfo) then begin
    Result := False;
    Exit;
  end
  else begin
    fSys := TIniFile.Create(Path.PGInfo);
    try
//      SystemInfo.DebugLogLevelConfig := fSys.ReadInteger('DEBUG', 'DEBUG_LOG_LEVEL_PG', 0); //TBD:DP860?
//      m_nDebugLogLevelActive := SystemInfo.DebugLogLevelConfig;

      //2023-03-30 jhhwang (for T/T Test)
      SystemInfo.PG_TconWriteLogDisplay    := fSys.ReadBool   ('DEBUG', 'PG_TconWriteLogDisplay', False); //2023-03-28 jhhwang (for T/T Test)
      SystemInfo.PG_TconWriteCmdType       := fSys.ReadInteger('DEBUG', 'PG_TconWriteCmdType',    0);     //2023-03-30 jhhwang (for T/T Test)
      SystemInfo.PG_TconReadCmdType       := fSys.ReadInteger('DEBUG', 'PG_TconReadCmdType',    0);     //2023-03-30 jhhwang (for T/T Test)
      SystemInfo.PG_TconOcWriteDelayMsec   := fSys.ReadInteger('DEBUG', 'PG_TconOcWriteDelayMsec',1);     //2023-03-28 jhhwang (for T/T Test) (valid if PgOcWriteAckUse=False)
      SystemInfo.PG_TconOcWriteSyncAddrStr := Trim(fSys.ReadString('DEBUG', 'PG_TconOcWriteSyncAddrStr','1727,6926,6928,6930,6936,10260')); //2023-03-30 jhhwang (for T/T Test)
      SetLength(SystemInfo.PG_ToonOcWriteSyncAddrArr,0);
			if SystemInfo.PG_TconOcWriteSyncAddrStr <> '' then begin  //2023-03-30 jhhwang (for T/T Test)
        arTemp := SystemInfo.PG_TconOcWriteSyncAddrStr.Split([',']);
        SetLength(SystemInfo.PG_ToonOcWriteSyncAddrArr,Length(arTemp));
        for i := 0 to Length(arTemp)-1 do begin
          SystemInfo.PG_ToonOcWriteSyncAddrArr[i] := StrToIntDef(arTemp[i],0);
        end;
			end;
      SystemInfo.PG_GpioReadHpdBeforeMeasure   := fSys.ReadBool   ('DEBUG', 'PG_GpioReadHpdBeforeMeasure',   True); //2023-03-30 jhhwang (for T/T Test)
      SystemInfo.PG_WaitAckAfterContOcWriteCnt := fSys.ReadInteger('DEBUG', 'PG_WaitAckAfterContOcWriteCnt', 0);     //2023-03-31 jhhwang (for T/T Test)
      SystemInfo.PG_TconReadBeforeDelayMsec    := fSys.ReadInteger('DEBUG', 'PG_TconReadBeforeDelayMsec',    0);     //2023-04-24 jhhwang (for T/T Test)
      SystemInfo.PG_TconOcWriteDelayLoopCnt    := fSys.ReadInteger('DEBUG', 'PG_TconOcWriteDelayLoopCnt',    0);     //2023-04-24 jhhwang (for T/T Test)
      SystemInfo.PG_TconOcWriteDelayMicroSec   := fSys.ReadInteger('DEBUG', 'PG_TconOcWriteDelayMicroSec',    0);     //2023-04-24 jhhwang (for T/T Test)
    finally
      fSys.Free;
    end;
  end;
  Result := True;
end;


function TCommon.StringToIdBytes(const AStr: string): TIdBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(AStr));
  for I := 1 to Length(AStr) do
    Result[I - 1] := Ord(AStr[I]);
end;

function TCommon.ReadSWVer: Boolean;
var
  fSys        : TIniFile;
  i : Integer;
  arTemp   : TArray<string>; //2023-03-28 jhhwang (for T/T Test)
  KeyList: TStrings;
  sKey,sVer : string;

begin
  if not FileExists(Path.SWVersionInfo) then begin
    Result := False;
    Exit;
  end
  else begin
    fSys := TIniFile.Create(Path.SWVersionInfo);
    KeyList := TStringList.Create;
    try
      fSys.ReadSection('OC', KeyList);
      SetLength(SystemInfo.ConfigVer,KeyList.Count);

      for i := 0 to KeyList.Count - 1 do
      begin
        sKey := KeyList[i];
        sVer := fSys.ReadString   ('OC', sKey, '');
        arTemp := sVer.Split([':']);
        SystemInfo.ConfigVer[i].ConfigVer := sKey;
        if Length(arTemp) > 1 then begin
          SystemInfo.ConfigVer[i].SWVer := arTemp[0];
          SystemInfo.ConfigVer[i].DLLVer := arTemp[1];
        end;
        // 가져온 키명에 대해 필요한 작업을 수행합니다.
      end;
      SystemInfo.ConfigVerCount := KeyList.Count;
    finally
      KeyList.Free;
      fSys.Free;
    end;
  end;
  Result := True;
end;

function TCommon.ReadDLLSet: Boolean;
var
  fSys        : TIniFile;
  i : Integer;
  arTemp   : TArray<string>;
  sKey,sVer : string;
  sDirectory : string;
begin
  sDirectory := Path.LGDSet + Common.TestModelInfoFLOW.ModelTypeName + '\Optimum_Setting.ini';
  if not FileExists(sDirectory) then begin
    Result := False;
    Exit;
  end
  else begin
    fSys := TIniFile.Create(sDirectory);
    try
      Common.TestModelInfoFLOW.GetDLLBin    := fSys.ReadString('OC', 	'BIN_File_version','');
      Common.TestModelInfoFLOW.Is_3200NitDOE    := SameText('TRUE',fSys.ReadString('OC', 	'Is_3200NitDOE',''));
    finally
      fSys.Free;
    end;
  end;
  Result := True;
end;

procedure TCommon.ReadSystemInfo;
var
  fSys        : TIniFile;
  i : Integer;
  arTemp   : TArray<string>; //2023-03-28 jhhwang (for T/T Test)
begin
  if not FileExists(Path.SysInfo) then begin
    InitSystemInfo;
    SaveSystemInfo;
  end
  else begin
    fSys := TIniFile.Create(Path.SysInfo);
    try

      SystemInfo.Password             := Decrypt(fSys.ReadString('SYSTEMDATA', 'PASSWORD', Encrypt('LED', 17307)), 17307);
      SystemInfo.SupervisorPassword   := Decrypt(fSys.ReadString('SYSTEMDATA', 'SUPERVISORPASSWORD', Encrypt('LED', 18307)), 18307);
      SystemInfo.DAELoadWizardPath    := fSys.ReadString('SYSTEMDATA', 	'DAELoadWizardPath','');
      SystemInfo.TestModel            := fSys.ReadString('SYSTEMDATA', 	'TESTING_MODEL','');
      SystemInfo.Com_IrTempSensor     := fSys.ReadInteger('SYSTEMDATA', 'COM_IR_TEMP_SENSOR',0);
      SystemInfo.SetTemperature       := fSys.ReadInteger('SYSTEMDATA', 'Set_IR_TEMP',0);
      SystemInfo.UseITOMode           := fSys.ReadBool   ('SYSTEMDATA', 'USE_ITOMODE', False);  // Added by KTS 2022-03-25 오후 1:09:57
      SystemInfo.PG_TYPE   := fSys.ReadInteger('SYSTEMDATA', 'PG_TYPE', DefPG.PG_TYPE_DP860);
      SystemInfo.CHReversal :=        fSys.ReadBool   ('SYSTEMDATA', 'CHReversal', False);  // Added by KTS 2022-03-25 오후 1:09:57
      SystemInfo.PG_TYPE   := fSys.ReadInteger('SYSTEMDATA', 'PG_TYPE', DefPG.PG_TYPE_DP860);
      SystemInfo.SaveEnergy           := fSys.ReadInteger('SYSTEMDATA',    'SAVE_ENERGY', 0);
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        SystemInfo.IPAddr[i]          := fSys.ReadString('SYSTEMDATA', 	'IP_ADDR'+IntToStr(i),Format('192.168.0.%d',[i+21]));
        if trim(SystemInfo.IPAddr[i]) = '' then SystemInfo.IPAddr[i] :=  Format('192.168.0.%d',[i+21]);
        SystemInfo.UseCh[i]           := fSys.ReadBool('SYSTEMDATA',Format('USE_CH_%d',[i+1]),True);

      end;
      for i := DefCommon.CH1 to Pred(DefCommon.MAX_BCR_CNT) do begin
        SystemInfo.Com_HandBCR[i]             := fSys.ReadInteger('SYSTEMDATA', 'COM_HandBCR'+IntToStr(i+1),0);
      end;
      for i := DefCommon.CH1 to Pred(DefCommon.MAX_SWITCH_CNT) do begin
        SystemInfo.Com_RCB[i]             := fSys.ReadInteger('SYSTEMDATA', 'COM_RCB'+IntToStr(i+1),0);
      end;

      SystemInfo.Z_Motor              := fSys.ReadInteger('SYSTEMDATA', 'COM_Z_AXIS',0);
      SystemInfo.Com_CamLight         := fSys.ReadInteger('SYSTEMDATA', 'COM_CAM_LIGHT',0);

      SystemInfo.IonizerCnt         := 2;//fSys.ReadInteger('SYSTEMDATA',    'IONIZER_CNT', 0);
      for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
        SystemInfo.Com_Ionizer[i]             := fSys.ReadInteger('SYSTEMDATA', Format('COM_IONIZER_%d',[i+1]),0);
        SystemInfo.Model_Ionizer[i]           := fSys.ReadInteger('SYSTEMDATA', Format('MODEL_IONIZER_%d',[i+1]),0);
      end;
//      for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
//        SystemInfo.Com_Ca310[i]      := fSys.ReadInteger('SYSTEMDATA', Format('COM_CA310%d',[i]),0);
//      end;

      SystemInfo.PGMemorySize         := fSys.ReadInteger('SYSTEMDATA', 'PG_MEMORY_SIZE',512);
      SystemInfo.UIType         			:= fSys.ReadInteger('SYSTEMDATA', 'UI_TYPE',0);
      SystemInfo.OCType         			:= fSys.ReadInteger('SYSTEMDATA', 'OC_TYPE',0);

      SystemInfo.PIDLengthLimit       := fsys.ReadInteger('SYSTEMDATA', 'PID_LENGTH',0);
      SystemInfo.ZIGLengthLimit       := fsys.ReadInteger('SYSTEMDATA', 'ZIG_LENGTH',0);
      SystemInfo.EQPId_Type					  := fSys.ReadInteger('SYSTEMDATA', 'EQPId_Type', 0);
      SystemInfo.EQPId					   		:= fSys.ReadString('SYSTEMDATA',  'EQPID',             '');
      SystemInfo.EQPId_INLINE				 	:= fSys.ReadString('SYSTEMDATA',  'EQPID_INLINE',             '');
      SystemInfo.EQPId_MGIB					 	:= fSys.ReadString('SYSTEMDATA',  'EQPID_MGIB',      '');
      SystemInfo.EQPId_PGIB			   		:= fSys.ReadString('SYSTEMDATA',  'EQPID_PGIB',             '');
      SystemInfo.	EQPId_MGIB_Process_Code				 	:= fSys.ReadString('SYSTEMDATA',  'EQPID_MGIB_PROCESS_CODE',      '');
      SystemInfo.	EQPId_PGIB_Process_Code		   		:= fSys.ReadString('SYSTEMDATA',  'EQPID_PGIB_PROCESS_CODE',      '');
      SystemInfo.Test_Repeat		   		:= fSys.Readbool('SYSTEMDATA',    'TEST_REPEAT',             False);
      SystemInfo.UseNoExchange		   	:= fSys.Readbool('SYSTEMDATA',    'UseNoExchange',             False);
      SystemInfo.UseNoPogo		   	    := fSys.Readbool('SYSTEMDATA',    'UseNoPogo',             False);

      SystemInfo.R2RCa410MemCh        := fSys.ReadInteger('SYSTEMDATA',  'R2RCa410MemCh',0);
      SystemInfo.DLLVerInterlock      := fSys.ReadBool('SYSTEMDATA',    'DLL_VER_INTERLOCK',False);
      SystemInfo.DLLVerInterlockList  := fSys.ReadString('SYSTEMDATA',  'DLL_VER_INTERLOCK_PATH','');

      SystemInfo.PGResetDelayTime     := fSys.ReadInteger('SYSTEMDATA','PG_RESET_DELAY_TIME',0);
      SystemInfo.PGResetTotalConut    := fSys.ReadInteger('SYSTEMDATA','PG_RESET_TOTAL_COUNT',0);

      //임시 - 기존 소스 호환용
      if SystemInfo.EQPId_INLINE = '' then begin
        SystemInfo.EQPId_INLINE:= SystemInfo.EQPId;
      end;

      if SystemInfo.EQPId = '' then begin
        case SystemInfo.EQPId_Type of
          0: SystemInfo.EQPId:= SystemInfo.EQPId_INLINE;
          1: SystemInfo.EQPId:= SystemInfo.EQPId_MGIB;
          2: SystemInfo.EQPId:= SystemInfo.EQPId_PGIB;
        end;
      end;
//      SystemInfo.Language	 						:= fSys.ReadInteger('SYSTEMDATA', 'LANGUAGE',     0);
      SystemInfo.ServicePort		 			:= fSys.ReadString('SYSTEMDATA',  'MES_SERVICEPORT',       '28451');
      SystemInfo.Network				 			:= fSys.ReadString('SYSTEMDATA',  'MES_NETWORK', 		 	     ';239.28.4.51;');
      SystemInfo.DaemonPort		   			:= fSys.ReadString('SYSTEMDATA',  'MES_DAEMONPORT', 	     'tcp:10.119.211.150:28401');
      SystemInfo.LocalSubject	  			:= fSys.ReadString('SYSTEMDATA',  'MES_LOCALSUBJECT',      'HN.G3.EQP.MOD.');
      SystemInfo.RemoteSubject	 			:= fSys.ReadString('SYSTEMDATA',  'MES_REMOTESUBJECT',     'HN.G1.EIFsvr.MOD');
      SystemInfo.EqccInterval 	 			:= fSys.ReadString('SYSTEMDATA',  'MES_EQCC_INTERVAL',     '60000');
      SystemInfo.MesModelInfo	 	      := fSys.ReadString('SYSTEMDATA',  'MES_MODELINFO',         '');
      SystemInfo.Loader_Index	 			  := fSys.ReadString('SYSTEMDATA',  'LOADER_INDEX',          '');
      SystemInfo.PowerLog             := fSys.Readbool('SYSTEMDATA', 		'PWRLOG',  False);

      SystemInfo.Eas_Service		 			:= fSys.ReadString('SYSTEMDATA',  'EAS_SERVICEPORT',       '28481');
      SystemInfo.Eas_Network		 			:= fSys.ReadString('SYSTEMDATA',  'EAS_NETWORK', 		 	     ';239.28.4.81;');
      SystemInfo.Eas_DeamonPort		 		:= fSys.ReadString('SYSTEMDATA',  'EAS_DAEMONPORT', 	     'tcp:28401');
      SystemInfo.Eas_LocalSubject	 	  := fSys.ReadString('SYSTEMDATA',  'EAS_LOCALSUBJECT',      'HN.G3.EQP.HN.');
      SystemInfo.Eas_RemoteSubject	 	:= fSys.ReadString('SYSTEMDATA',  'EAS_REMOTESUBJECT',     'HN.G1.DIFsvr.HN');
      SystemInfo.Service_Cnt          := 2;
      SystemInfo.R2R_Service		 			:= fSys.ReadString('SYSTEMDATA',  'R2R_SERVICEPORT',       '28481');
      SystemInfo.R2R_Network		 			:= fSys.ReadString('SYSTEMDATA',  'R2R_NETWORK', 		 	     ';239.28.4.81;');
      SystemInfo.R2R_DeamonPort		 		:= fSys.ReadString('SYSTEMDATA',  'R2R_DAEMONPORT', 	     'tcp:28401');
      SystemInfo.R2R_LocalSubject	 	  := fSys.ReadString('SYSTEMDATA',  'R2R_LOCALSUBJECT',      'HN.G3.EQP.HN.');
      SystemInfo.R2R_RemoteSubject	 	:= fSys.ReadString('SYSTEMDATA',  'R2R_REMOTESUBJECT',     'HN.G1.DIFsvr.HN');
      if Length(SystemInfo.R2R_Service) > 0 then
        SystemInfo.Service_Cnt := SystemInfo.Service_Cnt + 1;

      SystemInfo.FwVer             	:= fSys.ReadString('SYSTEMDATA',  'FW_VER','');
      SystemInfo.FpgaVer           	:= fSys.ReadString('SYSTEMDATA',  'FPGA_VER','');


      SystemInfo.RobotRevA  	 			  := fSys.ReadString('SYSTEMDATA',  'ROBOT_REV_A_ADDR',          '');
      SystemInfo.RobotRevB  	 			  := fSys.ReadString('SYSTEMDATA',  'ROBOT_REV_B_ADDR',          '');
      SystemInfo.RobotOutA  	 			  := fSys.ReadString('SYSTEMDATA',  'ROBOT_OUT_A_ADDR',          '');
      SystemInfo.RobotOutB  	 			  := fSys.ReadString('SYSTEMDATA',  'ROBOT_OUT_B_ADDR',          '');

      SystemInfo.OcManualType         := fSys.Readbool('SYSTEMDATA', 		'OC_MANUAL_TYPE',  False);

      SystemInfo.AutoBackupUse        := fSys.Readbool('SYSTEMDATA', 		'AUTOBACKUP_USE',  False);
      SystemInfo.AutoBackupList      	:= fSys.ReadString('SYSTEMDATA',  'AUTOBACKUP_PATH','');

      SystemInfo.AutoLGDLogBackup     := fSys.ReadBool('SYSTEMDATA','AUTO_LGDLOG_BACKUP_USE',false);

      SystemInfo.SystemLogUse         := fSys.Readbool('SYSTEMDATA', 		'SYSTEM_LOG_USE',  False);
      LogAccumulateCount              := fsys.ReadInteger('SYSTEMDATA', 'LogAccumulateCount', 10);
      LogAccumulateSecond             := fsys.ReadInteger('SYSTEMDATA', 'LogAccumulateSecond', 10);
      SystemInfo.MIPILog              := fSys.Readbool('SYSTEMDATA', 		'MIPI_LOG_USE',  False);
      SystemInfo.NGAlarmCount         := fsys.ReadInteger('SYSTEMDATA', 'NGAlarmCount', 3);
      SystemInfo.RetryCount           := fsys.ReadInteger('SYSTEMDATA', 'RetryCount', 1);
      SystemInfo.ECS_Timeout          := fsys.ReadInteger('SYSTEMDATA', 'ECS_Timeout', 10000);
      SystemInfo.RetryCount_WritePOCB := fsys.ReadInteger('SYSTEMDATA', 'RetryCount_WritePOCB', 2);

      SystemInfo.Use_ECS              := fSys.Readbool('SYSTEMDATA', 		'USE_ECS',  True);
      SystemInfo.Use_MES              := fSys.Readbool('SYSTEMDATA', 		'USE_MES',  False);
      SystemInfo.Use_GIB              := fSys.Readbool('SYSTEMDATA', 		'USE_GIB',  False);
      SystemInfo.CAM_FFCData          := fSys.Readbool('SYSTEMDATA', 		'CAM_FFCData',  False);
      SystemInfo.CAM_StainData        := fSys.Readbool('SYSTEMDATA', 		'CAM_STAINDATA',  False);
      SystemInfo.CAM_FTPUpload        := fSys.Readbool('SYSTEMDATA', 		'CAM_FTPUPLOAD',  False);
      SystemInfo.CAM_TemplateData     := fSys.Readbool('SYSTEMDATA', 		'CAM_TemplateData',  False);
      SystemInfo.CAM_CallbackChangePattern := fSys.Readbool('SYSTEMDATA', 		'CAM_CALLBACK_CHANGEPATTERN',  False);
      SystemInfo.CAM_ResultType       := fSys.ReadInteger('SYSTEMDATA', 		'CAM_ResultType',  0);

      SystemInfo.MES_CODE_Cnt         := fSys.ReadInteger('SYSTEMDATA', 		'MES_CODE_Cnt',  3181);  // MES_code 갯수 불러오기

      SystemInfo.PopupMsgTime         := fSys.ReadInteger('SYSTEMDATA',     'POPUPMSGTIME',0);

      {$IFDEF CA410_USE}
//      SystemInfo.Ca410MemCh := fsys.ReadInteger('SYSTEMDATA', 'CA410_CH', 3);
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        SystemInfo.Com_Ca310[i]      := fSys.ReadInteger('SYSTEMDATA', Format('COM_CA310%d',[i]),0);
        SystemInfo.Com_Ca310_SERIAL[i]  := fSys.ReadString('SYSTEMDATA', Format('COM_CA310%d_SERIAL',[i]),'');
        SystemInfo.Com_Ca310_DevieId[i] := fSys.ReadInteger('SYSTEMDATA', Format('COM_CA310%d_DEVICE_ID',[i]),0);
      end;
      for i := 0 to Pred(DefCommon.MAX_CA_DRIVE_CNT) do begin
        SystemInfo.Com_CaDeviceList[i]  := fSys.ReadString('SYSTEMDATA', Format('COM_CA_DEIVCE%d_List',[i]),'');
      end;
      {$ENDIF}

      SystemInfo.AutoLoginID          := fSys.ReadString('SYSTEMDATA',  'AUTOLOGINID','602462');

{$IFDEF ISPD_L_OPTIC}
      SystemInfo.ChCountUsed          := DefCommon.MAX_PG_CNT;
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        SystemInfo.ProbAddr[i] := fSys.ReadString('SYSTEMDATA',  Format('PROBE_SERIAL_%d',[i]), '');
      end;
{$ELSE}
      SystemInfo.ChCountUsed          := fSys.ReadInteger('SYSTEMDATA', 'USED_CH_COUNT',     DefCommon.MAX_PG_CNT);
{$ENDIF}
{$IFDEF DFS_HEX}
		  DfsConfInfo.bUseDfs         := fSys.Readbool('DFSDATA', 	 'USE_DFS',  False);
		  DfsConfInfo.bDfsHexCompress := fSys.Readbool('DFSDATA', 	 'USE_HEX_COMPRESS', False);
		  DfsConfInfo.bDfsHexDelete   := fSys.Readbool('DFSDATA',  'USE_HEX_DELETE', False);
      DfsConfInfo.sDfsServerIP    := fSys.ReadString('DFSDATA',  'DFS_SERVER_IP','');
      DfsConfInfo.sDfsUserName    := fSys.ReadString('DFSDATA',  'DFS_USER_NAME','');
      DfsConfInfo.sDfsPassword    := fSys.ReadString('DFSDATA',  'DFS_PASSWORD','');
      //
      DfsConfInfo.bUseCombiDown   := fSys.Readbool('DFSDATA', 	  'USE_COMBI_DOWN',  False);
      DfsConfInfo.sCombiDownPath  := fSys.ReadString('DFSDATA',  'COMBI_DOWN_PATH','');
      DfsConfInfo.sProcessName    := fSys.ReadString('DFSDATA',  'PROCESS_NAME','');

{$ENDIF}
      SystemInfo.LocalIP_GMES      	:= fSys.ReadString('SYSTEMDATA',  'LocalIP_GMES','');
      SystemInfo.LocalIP_PLC      	:= fSys.ReadString('SYSTEMDATA',  'LocalIP_PLC','');
      SystemInfo.PlcConfigPath        := fSys.ReadString('SYSTEMDATA',  'PLC_CONFIG_PATH','');
      SystemInfo.UseManualSerial      := fSys.Readbool('SYSTEMDATA', 		'MANUAL_SERAIL_INPUT',  False);
      SystemInfo.UseAutoBCR           := fSys.ReadBool('SYSTEMDATA',    'USE_AUTO_BCR', False);
      SystemInfo.UseEQCC              := fSys.ReadBool('SYSTEMDATA',    'USE_EQCC', False);
      SystemInfo.UseTouchTest         := fSys.ReadBool('SYSTEMDATA',    'USE_TOUCH_TEST', False);
      SystemInfo.DioType              := fSys.ReadInteger('SYSTEMDATA',    'DIO_TYPE', 0);
      SystemInfo.IndexMotor_Timeout   := fsys.ReadInteger('SYSTEMDATA', 'IndexMotor_Timeout', 25);
      SystemInfo.CamDelay	 						:= fSys.ReadInteger('SYSTEMDATA', 'CAMERA_MC_DELAY',     7);
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        SystemInfo.OffSet_Ch[i] := fSys.ReadFloat('WHITE_UNIFORMITY','OFFSET_'+systemInfo.TestModel + Format('_CH%d',[i+1]),0.0)
      end;

      SystemInfo.SignalInversion	 		:= fSys.ReadString('SYSTEMDATA', 'SIGNAL_INVERSION_OC',    '0');

      SystemInfo.PG_WriteReadPassAddr	 		:= fSys.ReadString('SYSTEMDATA', 'PG_WRTIEREAD_PASS_ADDR',    '');


      PLCInfo.EQP_ID              := fSys.ReadInteger('PLC',    'EQP_ID', 0);
      PLCInfo.PollingInterval     := fSys.ReadInteger('PLC',    'PollingInterval', 500);
      PLCInfo.Timeout_ECS         := fSys.ReadInteger('PLC',    'Timeout_ECS', 5000);
      PLCInfo.Timeout_Connection  := fSys.ReadInteger('PLC',    'Timeout_Connection', 10000);
      PLCInfo.Use_Simulation      := fSys.ReadBool('PLC',       'USE_SIMULATION', False);
      PLCInfo.InlineGIB           := fSys.ReadBool('PLC',       'InlineGIB', False);
      PLCInfo.Address_EQP         := fSys.ReadString('PLC', 'Address_EQP', '0');
      PLCInfo.Address_ROBOT       := fSys.ReadString('PLC', 'Address_ROBOT', '0');
      PLCInfo.Address_ECS         := fSys.ReadString('PLC', 'Address_ECS', '0');
      PLCInfo.Address_EQP_W       := fSys.ReadString('PLC', 'Address_EQP_W', '0');
      PLCInfo.Address_ROBOT_W     := fSys.ReadString('PLC', 'Address_ROBOT_W', '0');
      PLCInfo.Address_ECS_W       := fSys.ReadString('PLC', 'Address_ECS_W', '0');
      PLCInfo.Address_ROBOT2       := fSys.ReadString('PLC', 'Address_ROBOT2', '0');
      PLCInfo.Address_ROBOT_W2     := fSys.ReadString('PLC', 'Address_ROBOT_W2', '0');
      PLCInfo.Address_DoorOpen     := fSys.ReadString('PLC', 'Address_DOOROPEN', '0');


      //Zone 설정
      PLCInfo.Zone:= (PLCInfo.EQP_ID - 33) div 4; //시작 번호 33

      InterlockInfo.Use               := fSys.ReadBool  ('Interlock',       'USE', False);
      InterlockInfo.Version_SW        := fSys.ReadString('Interlock', 'Version_SW', '-');
      InterlockInfo.Version_Script    := fSys.ReadString('Interlock', 'Version_Script', '-');
      InterlockInfo.Version_FW        := fSys.ReadString('Interlock', 'Version_FW', '-');
      InterlockInfo.Version_FPGA      := fSys.ReadString('Interlock', 'Version_FPGA', '-');
      InterlockInfo.Version_Power     := fSys.ReadString('Interlock', 'Version_Power', '-');
      InterlockInfo.Version_DLL       := fSys.ReadString('Interlock', 'Version_DLL', '');
      InterlockInfo.Version_LGDDLL       := fSys.ReadString('Interlock', 'Version_LGDDLL', '');


      SimulateInfo.Use_PG              := fSys.ReadBool('SimulateInfo',    'USE_PG', False);
      SimulateInfo.Use_PLC             := fSys.ReadBool('SimulateInfo',    'USE_PLC', False);
      SimulateInfo.Use_DIO             := fSys.ReadBool('SimulateInfo',    'USE_DIO', False);
      SimulateInfo.Use_CAM             := fSys.ReadBool('SimulateInfo',    'USE_CAM', False);
      SimulateInfo.PG_BasePort         := fSys.ReadInteger('SimulateInfo',    'PG_BASEPORT', 8000);
      SimulateInfo.CAM_IP              := fSys.ReadString('SimulateInfo',    'CAM_IP', '127.0.0.1');
      SimulateInfo.DIO_IP              := fSys.ReadString('SimulateInfo',    'DIO_IP', '127.0.0.1');
      SimulateInfo.DIO_PORT            := fSys.ReadInteger('SimulateInfo',    'DIO_PORT', 6988);

      SystemInfo.DebugLogLevelConfig := fSys.ReadInteger('DEBUG', 'DEBUG_LOG_LEVEL_PG', 0); //TBD:DP860?
      m_nDebugLogLevelActive := SystemInfo.DebugLogLevelConfig;

      //2023-03-30 jhhwang (for T/T Test)
      SystemInfo.PG_TconWriteLogDisplay    := fSys.ReadBool   ('DEBUG', 'PG_TconWriteLogDisplay', False); //2023-03-28 jhhwang (for T/T Test)
      SystemInfo.PG_TconWriteCmdType       := fSys.ReadInteger('DEBUG', 'PG_TconWriteCmdType',    0);     //2023-03-30 jhhwang (for T/T Test)
      SystemInfo.PG_TconReadCmdType       := fSys.ReadInteger('DEBUG', 'PG_TconReadCmdType',    0);
      SystemInfo.PG_TconOcWriteDelayMsec   := fSys.ReadInteger('DEBUG', 'PG_TconOcWriteDelayMsec',1);     //2023-03-28 jhhwang (for T/T Test) (valid if PgOcWriteAckUse=False)
      SystemInfo.PG_TconOcWriteSyncAddrStr := Trim(fSys.ReadString('DEBUG', 'PG_TconOcWriteSyncAddrStr','1727,6926,6928,6930,6936,10260')); //2023-03-30 jhhwang (for T/T Test)
      SetLength(SystemInfo.PG_ToonOcWriteSyncAddrArr,0);
			if SystemInfo.PG_TconOcWriteSyncAddrStr <> '' then begin  //2023-03-30 jhhwang (for T/T Test)
        arTemp := SystemInfo.PG_TconOcWriteSyncAddrStr.Split([',']);
        SetLength(SystemInfo.PG_ToonOcWriteSyncAddrArr,Length(arTemp));
        for i := 0 to Length(arTemp)-1 do begin
          SystemInfo.PG_ToonOcWriteSyncAddrArr[i] := StrToIntDef(arTemp[i],0);
        end;
			end;
      SystemInfo.PG_GpioReadHpdBeforeMeasure   := fSys.ReadBool   ('DEBUG', 'PG_GpioReadHpdBeforeMeasure',   True); //2023-03-30 jhhwang (for T/T Test)
      SystemInfo.PG_WaitAckAfterContOcWriteCnt := fSys.ReadInteger('DEBUG', 'PG_WaitAckAfterContOcWriteCnt', 0);     //2023-03-31 jhhwang (for T/T Test)
      SystemInfo.PG_TconReadBeforeDelayMsec    := fSys.ReadInteger('DEBUG', 'PG_TconReadBeforeDelayMsec',    0);     //2023-04-24 jhhwang (for T/T Test)
      SystemInfo.PG_TconOcWriteDelayLoopCnt    := fSys.ReadInteger('DEBUG', 'PG_TconOcWriteDelayLoopCnt',    0);     //2023-04-24 jhhwang (for T/T Test)
      SystemInfo.PG_TconOcWriteDelayMicroSec   := fSys.ReadInteger('DEBUG', 'PG_TconOcWriteDelayMicroSec',    0);     //2023-04-24 jhhwang (for T/T Test)
    finally
      fSys.Free;
    end;
  end;

end;

procedure TCommon.SaveLocalIpToSys(nIdx: Integer);
var
  fSys        : TIniFile;
begin
  fSys := TIniFile.Create(Path.SysInfo);
  try
    case nIdx of
      DefCommon.IP_LOCAL_GMES : begin
        fSys.WriteString('SYSTEMDATA',  'LocalIP_GMES'  , SystemInfo.LocalIP_GMES);
      end;
      DefCommon.IP_LOCAL_PLC : begin
        fSys.WriteString('SYSTEMDATA',  'LocalIP_PLC'  , SystemInfo.LocalIP_PLC);
      end;
      DefCommon.IP_PLC_CONFIG_PATH : begin
        fSys.WriteString('SYSTEMDATA',  'PLC_CONFIG_PATH'  , SystemInfo.PlcConfigPath);
      end;
      DefCommon.IP_EM_NUMBER : begin
        fSys.WriteString('SYSTEMDATA',  'EQPID',  		   	 	 		  SystemInfo.EQPId);
      end;
    end;
  finally
    fSys.Free;
  end;
end;

procedure TCommon.SaveModelInfo(fName: String);
var
  fn,sSection : String;
//  fi : TFileStream;
  modelF : TIniFile;
  i : Integer;
begin
  Path.MODEL_CUR := Path.MODEL + fName + '\';
  CheckDir(Path.MODEL_CUR);
  fn := Path.MODEL_CUR + fName + '.mcf';
  modelF := TIniFile.Create(fn);
  try

    with modelF do begin
      try
        with EdModelInfoPG.PgVer do begin
          sSection := 'PG_VERSION';
          //
          {$IFDEF PG_AF9}
          if SystemInfo.PG_TYPE = DefPG.PG_TYPE_AF9 then begin
            WriteString (sSection, 'AF9VerMCS', Format('%d',[AF9VerMCS]));
            WriteString (sSection, 'AF9VerAPI', Format('%d',[AF9VerAPI]));
          end;
          {$ENDIF}
          {$IFDEF PG_DP860}
          if SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
            WriteString (sSection, 'PgVerAll',   VerAll);
            {$IFDEF DP860_TBD_XXXXXX}
            WriteString (sSection, 'PgVerHW',    HW);
            WriteString (sSection, 'PgVerFW',    FW);
            WriteString (sSection, 'PgVerSubFW', SubFW);
            WriteString (sSection, 'PgVerFPGA',  FPGA);
            WriteString (sSection, 'PgVerPWR',   PWR);
            {$ENDIF}
          end;
          {$ENDIF}
        end;
        with EdModelInfoPG.PgModelConf do begin
          // Resolution
          if SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then sSection := 'MODEL_RESOLUTION'
          else                                             sSection := 'MODEL_DATA';
          SetResolution(H_Active, V_Active);
          WriteInteger(sSection, 'H_Active', H_Active);
          WriteInteger(sSection, 'H_BP', 		 H_BP);
          WriteInteger(sSection, 'H_SA', 		 H_SA);
          WriteInteger(sSection, 'H_FP', 		 H_FP);
          WriteInteger(sSection, 'V_Active', V_Active);
          WriteInteger(sSection, 'V_BP', 		 V_BP);
          WriteInteger(sSection, 'V_SA', 		 V_SA);
          WriteInteger(sSection, 'V_FP', 		 V_FP);
          {$IFDEF PG_AF9}
        	if SystemInfo.PG_TYPE = DefPG.PG_TYPE_AF9 then begin
            WriteInteger(sSection, 'Bmp2RawType',  Bmp2RawType); // BMP-to-RAW Conversion 0=Large(X2146), 1=Small(X2381) //2022-07-05
          end;
          {$ENDIF}

          {$IFDEF PG_DP860}
          if SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
  					// Timing
            sSection := 'MODEL_TIMING';
  					WriteInteger(sSection, 'link_rate'			 ,link_rate);
  					WriteInteger(sSection, 'lane'						 ,lane);
  					WriteInteger(sSection, 'Vsync'					 ,Vsync);
  					WriteString (sSection, 'RGBFormat'			 ,RGBFormat);
	  				WriteInteger(sSection, 'ALPM_Mode'			 ,ALPM_Mode);
		  			WriteInteger(sSection, 'vfb_offset'			 ,vfb_offset);
            // ALPDP
            sSection := 'MODEL_ALPDP';
  					WriteInteger(sSection, 'h_fdp'           ,h_fdp);
  					WriteInteger(sSection, 'h_sdp'           ,h_sdp);
  					WriteInteger(sSection, 'h_pcnt'          ,h_pcnt);
  					WriteInteger(sSection, 'vb_n5b'          ,vb_n5b);
  					WriteInteger(sSection, 'vb_n7'           ,vb_n7);
  					WriteInteger(sSection, 'vb_n5a'          ,vb_n5a);
  					WriteInteger(sSection, 'vb_sleep'        ,vb_sleep);
  					WriteInteger(sSection, 'vb_n2'           ,vb_n2);
  					WriteInteger(sSection, 'vb_n3'           ,vb_n3);
  					WriteInteger(sSection, 'vb_n4'           ,vb_n4);
	  				//
		  			WriteInteger(sSection, 'm_vid'           ,m_vid);
			  		WriteInteger(sSection, 'n_vid'           ,n_vid);
				  	WriteInteger(sSection, 'misc_0'          ,misc_0);
					  WriteInteger(sSection, 'misc_1'          ,misc_1);
  					WriteInteger(sSection, 'xpol'            ,xpol);
	  				WriteInteger(sSection, 'xdelay'          ,xdelay);
		  			WriteInteger(sSection, 'h_mg'            ,h_mg);
			  		WriteInteger(sSection, 'NoAux_Sel'       ,NoAux_Sel);
				  	WriteInteger(sSection, 'NoAux_Active'    ,NoAux_Active);
					  WriteInteger(sSection, 'NoAux_Sleep'     ,NoAux_Sleep);
  					//
	  				WriteInteger(sSection, 'critical_section',critical_section);
  					WriteInteger(sSection, 'tps'             ,tps);
	  				WriteInteger(sSection, 'v_blank'         ,v_blank);
		  			WriteInteger(sSection, 'chop_enable'     ,chop_enable);
			  		WriteInteger(sSection, 'chop_interval'   ,chop_interval);
				  	WriteInteger(sSection, 'chop_size'       ,chop_size);
          end;
          {$ENDIF}
        {$IFDEF PG_DP860}
        //------------------------------ PowerData
        if SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
          with EdModelInfoPG.PgPwrData do begin
            sSection := 'POWER_DATA';
            WriteInteger(sSection, 'PWR_SLOPE', PWR_SLOPE);  // slope_set - power.open
            for i := 0 to DefPG.PWR_MAX do begin
              WriteString (sSection, Format('PWR_NAME_%d',[i]),   PWR_NAME[i]);
              WriteInteger(sSection, Format('PWR_VOL_%d',[i]),    PWR_VOL[i]);    // Voltage Setting - DP860(power.open)
              WriteInteger(sSection, Format('PWR_VOL_LL_%d',[i]), PWR_VOL_LL[i]); // Power Limit - DP860(power.limit -> power.open)
              WriteInteger(sSection, Format('PWR_VOL_HL_%d',[i]), PWR_VOL_HL[i]);
              WriteInteger(sSection, Format('PWR_CUR_LL_%d',[i]), PWR_CUR_LL[i]);
              WriteInteger(sSection, Format('PWR_CUR_HL_%d',[i]), PWR_CUR_HL[i]);
            end;
          end;
          //------------------------------ PowerSequence
          with EdModelInfoPG.PgPwrSeq do begin
            sSection := 'POWER_SEQUENCE';
          //WriteInteger(sSection, 'PWR_SEQ_TYPE', SeqType); //obsoleted!!!
            for i := 0 to DefPG.PWR_SEQ_MAX do begin
              WriteInteger(sSection, Format('PWR_SEQ_ON_%d',[i]),  SeqOn[i]);
              WriteInteger(sSection, Format('PWR_SEQ_OFF_%d',[i]), SeqOff[i]);
            end;
          end;
        end;
        {$ENDIF}
        end;
        with EdModelInfoFLOW do begin
          sSection := 'FLOW_DATA';
          //
          WriteString (sSection, 'PatGrpName',     PatGrpName);
          WriteInteger(sSection, 'MODELTYPE',     ModelType);
          WriteString (sSection, 'MODEL_TYPE_NAME',     ModelTypeName);
          //
          WriteBool   (sSection, 'USE_IONIZER_ON_OFF', UseIonOnOff); // Added by KTS 2022-03-18 오전 11:18:52 Ionizer On/Off
          WriteBool   (sSection, 'UseDutDetect',       UseDutDetect); //2023-02-02
          WriteInteger(sSection, 'SERIALNO_ADDR',SerialNoFlashInfo.nAddr);
          WriteInteger(sSection, 'SERIALNO_LENGTH',SerialNoFlashInfo.nLength);
          WriteInteger(sSection, 'Ca410MemCh',     Ca410MemCh);
          WriteInteger(sSection, 'NVMINITMODE',     UseNvmInit);
          WriteBool(sSection, 'USE_CHECK_VERSION',     UseCheckVer);
          WriteBool(sSection, 'USE_CHECK_ReProgramming',     UseCheckReProgramming);
          WriteInteger(sSection, 'USE_CHECK_NVMWriteSequence',     UseCkNVMWriteSequence);
          WriteBool(sSection, 'USE_CHECK_TCONWRITECHECKSUM',     UseTconWriteChecksum);

          WriteInteger(sSection, 'IDLEMODEDTIME',     IdleModeDTime);

          WriteBool(sSection, 'IDLE_MODE',IDLEMode);

        end;

//        SetResolution(TempModelInfo.H_Active,TempModelInfo.V_Active);
//        WriteInteger('MODEL_INFO', 'SigType',  			 TempModelInfo.SigType);
//        WriteInteger('MODEL_INFO', 'Freq',  				 TempModelInfo.Freq);
//        WriteInteger('MODEL_INFO', 'H_Active',     	 TempModelInfo.H_Active);
//        WriteInteger('MODEL_INFO', 'H_BP', 					 TempModelInfo.H_BP);
//        WriteInteger('MODEL_INFO', 'H_Width',    		 TempModelInfo.H_Width);
//        WriteInteger('MODEL_INFO', 'H_FP',  				 TempModelInfo.H_FP);
//        WriteInteger('MODEL_INFO', 'V_Active',			 TempModelInfo.V_Active);
//        WriteInteger('MODEL_INFO', 'V_BP',  				 TempModelInfo.V_BP);
//        WriteInteger('MODEL_INFO', 'V_Width', 			 TempModelInfo.V_Width);
//        WriteInteger('MODEL_INFO', 'V_FP',					 TempModelInfo.V_FP);
//
//        for i := 0 to 5 do begin
//          WriteInteger('MODEL_INFO', Format('PWR_VOL_%d',[i]),   	  TempModelInfo.PWR_VOL[i]);
//          WriteInteger('MODEL_INFO', Format('PWR_CUR_HL_%d',[i]),   TempModelInfo.PWR_CUR_HL[i]);
//          WriteInteger('MODEL_INFO', Format('PWR_CUR_LL_%d',[i]),   TempModelInfo.PWR_CUR_LL[i]);
//          WriteInteger('MODEL_INFO', Format('PWR_VOL_HL_%d',[i]),   TempModelInfo.PWR_VOL_HL[i]);
//          WriteInteger('MODEL_INFO', Format('PWR_VOL_LL_%d',[i]),   TempModelInfo.PWR_VOL_LL[i]);
//        end;
//
//        for i := 0 to 2 do begin
//          WriteInteger('MODEL_INFO', Format('PWR_CUR_HL2_%d',[i]),  TempModelInfo.PWR_CUR_HL2[i]);
//          WriteInteger('MODEL_INFO', Format('PWR_CUR_LL2_%d',[i]),  TempModelInfo.PWR_CUR_LL2[i]);
//          WriteInteger('MODEL_INFO', Format('PWR_VOL_HL2_%d',[i]),  TempModelInfo.PWR_VOL_HL2[i]);
//          WriteInteger('MODEL_INFO', Format('PWR_VOL_LL2_%d',[i]),  TempModelInfo.PWR_VOL_LL2[i]);
//        end;
//
//        WriteString('MODEL_INFO','Pattern_Group',TempModelInfo2.PatGrpName);
//        WriteString('MODEL_INFO','SEQ_SCRIPT_CRC',TempModelInfo2.CheckSum);
//
////        WriteString('MODEL_INFO','OC_PARAM_PATH',TempModelInfo2.OcParamPath);
////        WriteString('MODEL_INFO','OC_VERIFY_PATH',TempModelInfo2.OcVerifyPath);
////        WriteString('MODEL_INFO','OTP_TABLE_PATH',TempModelInfo2.OtpTablePath);
////        WriteString('MODEL_INFO','OFFSET_TABLE_PATH',TempModelInfo2.OffSetTablePath);
//
////        WriteInteger('MODEL_INFO2','CA310_CH',TempModelInfo2.Ca310MemCh);
//        WriteInteger('MODEL_INFO2','Z_AXIS',TempModelInfo2.Zxis);

//        WriteBool('MODEL_INFO2','OC_USE_OC_PARAM',TempModelInfo2.useOcParam);
//        WriteBool('MODEL_INFO2','OC_USE_OC_VERIFY',TempModelInfo2.useOcVerify);
//        WriteBool('MODEL_INFO2','OC_USE_OTP_TABLE',TempModelInfo2.useOtpTable);
//        WriteBool('MODEL_INFO2','OC_USE_OC_OFFSET',TempModelInfo2.useOcOffset);
      except
        ShowMessage(fn + ' store was failed!!');
      end;
    end;
  finally
    modelF.Free;
  end;

end;

procedure TCommon.SaveModelInfo2(fName: String);
var
  fn : String;
//  fi : TFileStream;
  modelF : TIniFile;
//  i : Integer;
begin
  Path.MODEL_CUR := Path.MODEL + fName + '\';
  CheckDir(Path.MODEL_CUR);
  fn := Path.MODEL_CUR + fName + '.mcf';
  modelF := TIniFile.Create(fn);
  try

    with modelF do begin
      try
        WriteString('MODEL_INFO','Pattern_Group',Common.EdModelInfoFLOW.PatGrpName);

      except
        ShowMessage(fn + ' store was failed!!');
      end;
    end;
  finally
    modelF.Free;
  end;

end;

procedure TCommon.SaveModelInfoDLL(fName: String);
var
  fn,sSection : String;
//  fi : TFileStream;
  modelF : TIniFile;
  i : Integer;
begin
//  CheckDir( Path.MODEL + fName + '\Setting\OCSet\');
  CheckDir( Path.LGDDLL +'Setting\OCSet\');
  fn := Path.LGDDLL + '\Setting\OCSet\ModelSelection.ini';

  modelF := TIniFile.Create(fn);
  try

    with modelF do begin
      try
        sSection := 'SelectedModel';
        WriteString (sSection, 'Model',EdModelInfoFLOW.ModelTypeName);
      except
        ShowMessage(fn + ' store was failed!!');
      end;
    end;
  finally
    modelF.Free;
  end;

end;


procedure TCommon.SaveOpticInfo(nModelType : Integer);
var
  sysF : TIniFile;
  i : Integer;
begin
  sysF := TIniFile.Create(Path.OcInfo);
  try
    // Set Target.
    sysF.WriteInteger('CA310_CALIBRATION', 'CAL_MODEL_TYPE', nModelType );
  finally
    sysF.Free;
  end;
  WritePrivateProfileString(nil, nil, nil, PChar(Path.SysInfo));
end;

procedure TCommon.SavePatGroup(sPatGroup : string; SavePatGrp : TPatterGroup);
var
  PatGrpFile : TIniFile;
  i : Integer;
  PattName : String;
begin
  DebugMessage('save_pattern_data : ' + sPatGroup);

  PattName := Path.PATTERNGROUP + sPatGroup + '.grp';
  PatGrpFile := TIniFile.Create(PattName);
  try
    try

      if PatGrpFile.SectionExists('PatternData') then PatGrpFile.EraseSection('PatternData');
      PatGrpFile.WriteInteger('PatternData','pattern_count',SavePatGrp.PatCount);
      for i := 0 to Pred(SavePatGrp.PatCount) do begin
        PatGrpFile.WriteInteger('PatternData',Format('PatType%d',[i]),SavePatGrp.PatType[i]);
        PatGrpFile.WriteString('PatternData',Format('PatName%d',[i]),SavePatGrp.PatName[i]);
        PatGrpFile.WriteInteger('PatternData',Format('VSync%d',[i]),SavePatGrp.VSync[i]);
        PatGrpFile.WriteInteger('PatternData',Format('LockTime%d',[i]),SavePatGrp.LockTime[i]);
        PatGrpFile.WriteInteger('PatternData',Format('Option%d',[i]),SavePatGrp.Option[i]);
      end;
      PatGrpFile.UpdateFile;
    except
      if _lcid = 1042 then
        ShowMessage('[SAVE ERROR] '+PattName+' 파일 저장에 실패하였습니다!!')
      else
        ShowMessage('[SAVE ERROR] '+PattName+' failed to save!!');
    end;
  finally
    PatGrpFile.Free;
  end;
end;

procedure TCommon.SaveSystemInfo;
var
  sysF : TIniFile;
  encrypt_passwd : String;
  i: Integer;
begin
  sysF := TIniFile.Create(Path.SysInfo);
  with sysF do begin
    try
      encrypt_passwd := Encrypt(SystemInfo.Password, 17307);
      WriteString ('SYSTEMDATA', 'PASSWORD',      				encrypt_passwd);
      encrypt_passwd := Encrypt(SystemInfo.SupervisorPassword, 18307);
      WriteString ('SYSTEMDATA', 'SUPERVISORPASSWORD',      				encrypt_passwd);

      WriteString ('SYSTEMDATA', 'DAELoadWizardPath',     SystemInfo.DAELoadWizardPath);
      WriteString ('SYSTEMDATA', 'TESTING_MODEL', 				SystemInfo.TestModel);
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        WriteString ('SYSTEMDATA', 'IP_ADDR'+IntToStr(i), SystemInfo.IPAddr[i]);
        WriteBool('SYSTEMDATA',Format('USE_CH_%d',[i+1]), SystemInfo.UseCh[i]);
      end;
      WriteBool   ('SYSTEMDATA','CHReversal',             SystemInfo.CHReversal);
      WriteBool   ('SYSTEMDATA', 'USE_ITOMODE', 		 	 	  SystemInfo.UseITOMode);  // Added by KTS 2022-03-25 오후 1:08:29
      WriteInteger('SYSTEMDATA', 'COM_IR_TEMP_SENSOR',   	SystemInfo.Com_IrTempSensor);
      WriteInteger('SYSTEMDATA', 'Set_IR_TEMP',   	      SystemInfo.SetTemperature);
      WriteInteger('SYSTEMDATA', 'EQPID_TYPE',  					SystemInfo.EQPId_Type);
      WriteString('SYSTEMDATA',  'EQPID',  		   	        SystemInfo.EQPId);
      WriteString('SYSTEMDATA',  'EQPID_INLINE',  		   	SystemInfo.EQPId_INLINE);
      WriteString('SYSTEMDATA',  'EQPID_MGIB',  		   	 	SystemInfo.EQPId_MGIB);
      WriteString('SYSTEMDATA',  'EQPID_PGIB',  		   	 	SystemInfo.EQPId_PGIB);
      WriteString('SYSTEMDATA',  'EQPID_MGIB_PROCESS_CODE',  		   	 	SystemInfo.EQPId_MGIB_Process_Code);
      WriteString('SYSTEMDATA',  'EQPID_PGIB_PROCESS_CODE',  		   	 	SystemInfo.EQPId_PGIB_Process_Code);

      WriteString('SYSTEMDATA',  'MES_SERVICEPORT',  			SystemInfo.ServicePort);
      WriteString('SYSTEMDATA',  'MES_NETWORK',  					SystemInfo.Network);
      WriteString('SYSTEMDATA',  'MES_DAEMONPORT',  			SystemInfo.DaemonPort);
      WriteString('SYSTEMDATA',  'MES_LOCALSUBJECT',  		SystemInfo.LocalSubject);
      WriteString('SYSTEMDATA',  'MES_REMOTESUBJECT',  		SystemInfo.RemoteSubject);
      WriteString('SYSTEMDATA',  'MES_MODELINFO',  		    SystemInfo.MesModelInfo);

      WriteString('SYSTEMDATA',  'EAS_SERVICEPORT',  			SystemInfo.Eas_Service);
      WriteString('SYSTEMDATA',  'EAS_NETWORK',  					SystemInfo.Eas_Network);
      WriteString('SYSTEMDATA',  'EAS_DAEMONPORT',  			SystemInfo.Eas_DeamonPort);
      WriteString('SYSTEMDATA',  'EAS_LOCALSUBJECT',  		SystemInfo.Eas_LocalSubject);
      WriteString('SYSTEMDATA',  'EAS_REMOTESUBJECT',  		SystemInfo.Eas_RemoteSubject);

      WriteString('SYSTEMDATA',  'R2R_SERVICEPORT',  			SystemInfo.R2R_Service);
      WriteString('SYSTEMDATA',  'R2R_NETWORK',  					SystemInfo.R2R_Network);
      WriteString('SYSTEMDATA',  'R2R_DAEMONPORT',  			SystemInfo.R2R_DeamonPort);
      WriteString('SYSTEMDATA',  'R2R_LOCALSUBJECT',  		SystemInfo.R2R_LocalSubject);
      WriteString('SYSTEMDATA',  'R2R_REMOTESUBJECT',  		SystemInfo.R2R_RemoteSubject);



      WriteString('SYSTEMDATA',  'MES_EQCC_INTERVAL',  		SystemInfo.EqccInterval);
      WriteString('SYSTEMDATA',  'LOADER_INDEX',  			  SystemInfo.Loader_Index); // [Q] jhhwang
      for i := 0 to Pred(DefCommon.MAX_BCR_CNT) do begin
        WriteInteger('SYSTEMDATA',Format('COM_HandBCR%d',[i+1]),  				   	SystemInfo.Com_HandBCR[i]);
      end;
      for i := 0 to Pred(DefCommon.MAX_SWITCH_CNT) do begin
        WriteInteger('SYSTEMDATA',Format('COM_RCB%d',[i+1]),  				   	SystemInfo.Com_RCB[i]);
      end;

      WriteInteger('SYSTEMDATA', 'COM_Z_AXIS',  					SystemInfo.Z_Motor);

      WriteInteger('SYSTEMDATA', 'COM_CAM_LIGHT',  			  SystemInfo.Com_CamLight);

//      WriteInteger('SYSTEMDATA','CA410_CH',SystemInfo.Ca410MemCh);
      //WriteInteger('SYSTEMDATA', 'IONIZER_CNT',  				   	SystemInfo.IonizerCnt );

      for i := 0 to Pred(DefCommon.MAX_IONIZER_CNT) do begin
        WriteInteger('SYSTEMDATA', Format('COM_IONIZER_%d',[i+1]),  				   	SystemInfo.Com_Ionizer[i] );
        WriteInteger('SYSTEMDATA', Format('MODEL_IONIZER_%d',[i+1]),  				  SystemInfo.Model_Ionizer[i] );
      end;

//      for i := DefCommon.JIG_A to DefCommon.JIG_B do begin
//        WriteInteger('SYSTEMDATA', Format('COM_CA310%d',[i]), SystemInfo.Com_Ca310[i]);
//      end;

      WriteInteger('SYSTEMDATA', 'PG_MEMORY_SIZE',  			SystemInfo.PGMemorySize);
      WriteInteger('SYSTEMDATA', 'UI_TYPE',  							SystemInfo.UIType);
      WriteInteger('SYSTEMDATA', 'OC_TYPE',  							SystemInfo.OCType);
      WriteInteger('SYSTEMDATA', 'SAVE_ENERGY', 	   	    SystemInfo.SaveEnergy);

      WriteInteger('SYSTEMDATA', 'PID_LENGTH',  		     	SystemInfo.PIDLengthLimit);
      WriteInteger('SYSTEMDATA', 'ZIG_LENGTH',  					SystemInfo.ZIGLengthLimit);
//      WriteInteger('SYSTEMDATA', 'LANGUAGE',  						SystemInfo.Language);
      Writebool('SYSTEMDATA',    'PWRLOG',     						SystemInfo.PowerLog);
      WriteInteger('SYSTEMDATA', 'USED_CH_COUNT',  		 		SystemInfo.ChCountUsed);

      Writebool('SYSTEMDATA',    'AUTOBACKUP_USE', 				SystemInfo.AutoBackupUse);
      Writebool('SYSTEMDATA',    'MANUAL_SERAIL_INPUT', 	SystemInfo.UseManualSerial);

      WriteBool('SYSTEMDATA',    'AUTO_LGDLOG_BACKUP_USE', SystemInfo.AutoLGDLogBackup);

      WriteInteger('SYSTEMDATA', 'NGAlarmCount',  				SystemInfo.NGAlarmCount);
      WriteInteger('SYSTEMDATA', 'RetryCount',			      SystemInfo.RetryCount);
      WriteInteger('SYSTEMDATA', 'ECS_Timeout',			      SystemInfo.ECS_Timeout);
      WriteInteger('SYSTEMDATA', 'RetryCount_WritePOCB',	SystemInfo.RetryCount_WritePOCB);

      Writebool('SYSTEMDATA',    'SYSTEM_LOG_USE', 				SystemInfo.SystemLogUse);
      Writebool('SYSTEMDATA',    'MIPI_LOG_USE', 				  SystemInfo.MIPILog);
      Writebool('SYSTEMDATA',    'USE_ECS', 				      SystemInfo.Use_ECS);
      Writebool('SYSTEMDATA',    'USE_MES', 				      SystemInfo.Use_MES);
      Writebool('SYSTEMDATA',    'USE_GIB', 				      SystemInfo.Use_GIB);

      WriteString('SYSTEMDATA',  'AUTOLOGINID',           SystemInfo.AutoLoginID );
      Writebool('SYSTEMDATA',    'TEST_REPEAT',           SystemInfo.Test_Repeat);
      Writebool('SYSTEMDATA',    'UseNoExchange',         SystemInfo.UseNoExchange);
      Writebool('SYSTEMDATA',    'UseNoPogo',             SystemInfo.UseNoPogo);

      WriteString('SYSTEMDATA',  'AUTOBACKUP_PATH',       SystemInfo.AutoBackupList);
      WriteBool('SYSTEMDATA',    'USE_AUTO_BCR', 				  SystemInfo.UseAutoBCR);
      WriteBool('SYSTEMDATA',    'USE_EQCC', 		 	 	      SystemInfo.UseEQCC);
      WriteBool('SYSTEMDATA',    'USE_TOUCH_TEST', 			  SystemInfo.UseTouchTest);
      WriteBool('SYSTEMDATA',    'OC_MANUAL_TYPE', 			  SystemInfo.OcManualType);
      WriteInteger('SYSTEMDATA', 'DIO_TYPE', 	   	      	SystemInfo.DIOType);
      WriteInteger('SYSTEMDATA', 'IndexMotor_Timeout', 	  SystemInfo.IndexMotor_Timeout);
      WriteInteger('SYSTEMDATA', 'CAM_ResultType', 	   	  SystemInfo.CAM_ResultType);
      Writebool('SYSTEMDATA',    'CAM_FFCData', 				  SystemInfo.CAM_FFCData);
      WriteBool('SYSTEMDATA',    'CAM_STAINDATA', 			  SystemInfo.CAM_StainData);
      WriteBool('SYSTEMDATA',    'CAM_FTPUPLOAD', 			  SystemInfo.CAM_FTPUpload);
      WriteBool('SYSTEMDATA',    'CAM_TemplateData', 			SystemInfo.CAM_TemplateData);
      WriteBool('SYSTEMDATA',    'CAM_CALLBACK_CHANGEPATTERN', 			  SystemInfo.CAM_CallbackChangePattern);

      WriteString('SYSTEMDATA', 'FW_VER',  				   	SystemInfo.FwVer);
      WriteString('SYSTEMDATA', 'FPGA_VER',  				   	SystemInfo.FpgaVer);

      WriteString('SYSTEMDATA',  'ROBOT_REV_A_ADDR',       SystemInfo.RobotRevA);
      WriteString('SYSTEMDATA',  'ROBOT_REV_B_ADDR',       SystemInfo.RobotRevB);
      WriteString('SYSTEMDATA',  'ROBOT_OUT_A_ADDR',       SystemInfo.RobotOutA);
      WriteString('SYSTEMDATA',  'ROBOT_OUT_B_ADDR',       SystemInfo.RobotOutB);
      WriteInteger('SYSTEMDATA', 'CAMERA_MC_DELAY',  			 SystemInfo.CamDelay);

      Writebool('SYSTEMDATA',    'DLL_VER_INTERLOCK', 				SystemInfo.DLLVerInterlock);
      WriteString('SYSTEMDATA',  'DLL_VER_INTERLOCK_PATH',       SystemInfo.DLLVerInterlockList);
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        WriteString('SYSTEMDATA', Format('PROBE_SERIAL_%d',[i]),       SystemInfo.ProbAddr[i]);
      end;
      WriteInteger('SYSTEMDATA','PG_RESET_DELAY_TIME', SystemInfo.PGResetDelayTime);
      WriteInteger('SYSTEMDATA','PG_RESET_TOTAL_COUNT',SystemInfo.PGResetTotalConut);

      WriteString('SYSTEMDATA',  'SIGNAL_INVERSION_OC',  		SystemInfo.SignalInversion); // Added by KTS 2023-01-17 오후 5:12:27 B접점 반전 해야되는 신호 목록
      WriteInteger('SYSTEMDATA',  'R2RCa410MemCh',  		SystemInfo.R2RCa410MemCh); // Added by KTS 2023-01-17 오후 5:12:27 B접점 반전 해야되는 신호 목록

      WriteInteger('SYSTEMDATA',  'MES_CODE_Cnt',  		SystemInfo.MES_CODE_Cnt);

      WriteInteger('SYSTEMDATA',  'POPUPMSGTIME', SystemInfo.PopupMsgTime);

      WriteInteger('DEBUG', 'DEBUG_LOG_LEVEL_PG', SystemInfo.DebugLogLevelConfig);
{$IFDEF DFS_HEX}
      WriteBool  ('DFSDATA', 'USE_DFS',                  DfsConfInfo.bUseDfs);
      WriteBool  ('DFSDATA', 'USE_HEX_COMPRESS',         DfsConfInfo.bDfsHexCompress);
      WriteBool  ('DFSDATA', 'USE_HEX_DELETE',           DfsConfInfo.bDfsHexDelete);
      WriteString('DFSDATA', 'DFS_SERVER_IP',            DfsConfInfo.sDfsServerIP);
      WriteString('DFSDATA', 'DFS_USER_NAME',            DfsConfInfo.sDfsUserName);
      WriteString('DFSDATA', 'DFS_PASSWORD',             DfsConfInfo.sDfsPassword);
      WriteBool  ('DFSDATA', 'USE_COMBI_DOWN',           DfsConfInfo.bUseCombiDown);
      WriteString('DFSDATA', 'COMBI_DOWN_PATH',          DfsConfInfo.sCombiDownPath);
      WriteString('DFSDATA', 'PROCESS_NAME',             DfsConfInfo.sProcessName);
{$ENDIF}
{$IFDEF CA410_USE}
      for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
        WriteInteger('SYSTEMDATA', Format('COM_CA310%d',[i]), SystemInfo.Com_Ca310[i]);
        WriteInteger('SYSTEMDATA', Format('COM_CA310%d_DEVICE_ID',[i]), SystemInfo.Com_Ca310_DevieId[i]);
        WriteString('SYSTEMDATA',  Format('COM_CA310%d_SERIAL',[i]),       SystemInfo.Com_Ca310_SERIAL[i]);
      end;

      for i := 0 to Pred(DefCommon.MAX_CA_DRIVE_CNT) do begin
        WriteString('SYSTEMDATA', Format('COM_CA_DEIVCE%d_List',[i]), SystemInfo.Com_CaDeviceList[i]);
      end;
{$ENDIF}

      WriteInteger('PLC', 'EQP_ID',  			        PLCInfo.EQP_ID);
      WriteInteger('PLC', 'PollingInterval',  		PLCInfo.PollingInterval);
      WriteInteger('PLC', 'Timeout_Connection',  	PLCInfo.Timeout_Connection);
      WriteInteger('PLC', 'Timeout_ECS',  			  PLCInfo.Timeout_ECS);
      WriteBool('PLC', 'USE_SIMULATION',  			  PLCInfo.Use_Simulation);
      WriteBool('PLC', 'InlineGIB',  			        PLCInfo.InlineGIB);
      WriteString('PLC', 'Address_EQP',           PLCInfo.Address_EQP);
      WriteString('PLC', 'Address_ECS',           PLCInfo.Address_ECS);
      WriteString('PLC', 'Address_ROBOT',         PLCInfo.Address_ROBOT);
      WriteString('PLC', 'Address_EQP_W',         PLCInfo.Address_EQP_W);
      WriteString('PLC', 'Address_ECS_W',         PLCInfo.Address_ECS_W);
      WriteString('PLC', 'Address_ROBOT_W',       PLCInfo.Address_ROBOT_W);
      WriteString('PLC', 'Address_ROBOT2',        PLCInfo.Address_ROBOT2);
      WriteString('PLC', 'Address_ROBOT_W2',      PLCInfo.Address_ROBOT_W2);
      WriteString('PLC', 'Address_DOOROPEN',      PLCInfo.Address_DoorOpen );

      WriteBool  ('Interlock', 'USE',                InterlockInfo.Use);
      WriteString('Interlock', 'Version_SW',         InterlockInfo.Version_SW);
      WriteString('Interlock', 'Version_Script',     InterlockInfo.Version_Script);
      WriteString('Interlock', 'Version_FW',         InterlockInfo.Version_FW);
      WriteString('Interlock', 'Version_FPGA',       InterlockInfo.Version_FPGA);
      WriteString('Interlock', 'Version_Power',      InterlockInfo.Version_Power);
      WriteString('Interlock', 'Version_DLL',        InterlockInfo.Version_DLL);
      WriteString('Interlock', 'Version_LGDDLL',        InterlockInfo.Version_LGDDLL);
    except
    end;
  end;
  sysF.Free;
  WritePrivateProfileString(nil, nil, nil, PChar(Path.SysInfo));
end;

procedure TCommon.SavesystemInfoCA410Memory(nCh: Integer; sData: string);
var
  sysF : TIniFile;
begin
  sysF := TIniFile.Create(Path.SysInfo);
  with sysF do begin
    try
      WriteString('SYSTEMDATA', Format('CA410_MEMORY_CH%d',[nCh]),  sData);
    except
    end;
  end;
  sysF.Free;
  WritePrivateProfileString(nil, nil, nil, PChar(Path.SysInfo));
end;

procedure TCommon.SavesystemInfoFwVersion(nCh: Integer; sData: string);
var
  sysF : TIniFile;
begin
  sysF := TIniFile.Create(Path.SysInfo);
  with sysF do begin
    try
      WriteString('SYSTEMDATA', Format('PG_VERSION_CH%d',[nCh]),  sData);
    except
    end;
  end;
  sysF.Free;
  WritePrivateProfileString(nil, nil, nil, PChar(Path.SysInfo));
end;

procedure TCommon.ConnectNetworkDrive(const driveLetter, networkPath: string);
begin
  ShellExecute(0, 'open', PChar('net'), PChar('use ' + driveLetter + ': ' + networkPath), nil, SW_HIDE);
end;

function TCommon.IsNetworkDriveConnected(const driveLetter: Char): Boolean;

begin
  Result := GetDriveType(PChar(driveLetter + ':\')) = DRIVE_REMOTE;
end;


function TCommon.FetchNetworkFile(const networkPath, localPath: string): Boolean;
begin
  try
    // CopyFile 함수를 사용하여 네트워크 파일을 로컬 경로로 복사합니다.
    if CopyFile(PChar(networkPath), PChar(localPath), False) then
    begin
      Result := True;
    end
    else
    begin
      // 오류 처리
      Result := False;
    end;
  except
    // 예외 처리
    Result := False;
  end;
end;

procedure TCommon.SetCodeLog;

//var
//  DestCode : TCodeSiteDestination;
begin
//{$IFDEF USE_CODESITE}CodeSite.EnterMethod( Self, 'FormCreate' );{$ENDIF}
//  DestCode := TCodeSiteDestination.Create(nil);
//  DestCode.LogFile.Active := False;
//  CheckDir(Path.LOG+'\CodeLogs\');
//  DestCode.LogFile.FilePath := Path.LOG + '\CodeLogs\';
//  DestCode.LogFile.FileName := FormatDateTime('yyyymmdd',now) +'_CodeSite.csl';
//  CodeSiteManager.DefaultDestination  := DestCode;
//{$IFDEF USE_CODESITE}CodeSite.ExitMethod( Self, 'FormCreate' );{$ENDIF}
end;

procedure TCommon.SetResolution(nH, nV: Word);
begin
  actual_resolution_hv[0] := nH;
  actual_resolution_hv[1] := nV;
end;

function TCommon.ValueToHex(const S: String): String;
var
  i : Integer;
  sData : string;
begin
  SetLength(sData, Length(S)*2); // 문자열 크기를 설정
  for i := 0 to Length(S)-1 do
  begin
    sData[(i*2)+1] := DefCommon.HexaChar[Integer(S[i+1]) shr 4];
    sData[(i*2)+2] := DefCommon.HexaChar[Integer(S[i+1]) and $0f];
  end;
  Result := sData;
end;





end.


