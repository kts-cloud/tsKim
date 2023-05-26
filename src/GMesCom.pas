unit GMesCom;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Dialogs,  Generics.Collections,
{$IFDEF WIN32}
  ModuleECS_CommTibRV_TLB ,
{$ENDIF}
{$IFDEF WIN64}
  DllMesCom ,
{$ENDIF}


  Winapi.WinSock, DefCommon, IdFTPCommon,
  Vcl.OleServer, Vcl.ExtCtrls, DefGmes, IdFTPList, IdFTP, System.SysUtils, Winapi.Messages, CommonClass;
{$I Common.inc}  // JHHWANG-GMES: 2018-06-20

type
  TKeyValue = record
    Key: string;
    Value: string;
  end;
type

  TGmesDataPack = record
    Registry  : Boolean;
    DataSend  : Boolean;
    bPCHK     : Boolean;
    bLPIR     : Boolean;
    LotNo     : string;

    SerialNo  : string;
    Model     : string;
    Pf        : string;
    Rwk       : string;
    Tact      : String;
    DefectPat : string;
    MesPendingMsg : Integer;  // JHHWANG-GMES: 2018-06-20
    MesSentMsg    : Integer;  // JHHWANG-GMES: 2018-06-20
    MesSendRcvWaitTick : Integer;  // JHHWANG-GMES 2018-06-26
    ApdrData  : string;
    CarrierId       : String;
    PchkSendNg      : Boolean;// JHHWANG-GMES 2018-06-26
    PchkRtnCode     : String; // PCHK_R.RTN_CD
    PchkRtnPID      : String; // PCHK_R.RTN_PID
    PchkRtnSerialNo : String; // PCHK_R.RTN_SERIAL_NO
    EicrSendNg      : Boolean;// JHHWANG-GMES 2018-06-26
    EicrRtnCode     : String; // EICR_R.RTN_CD
    LpirSendNg      : Boolean;// JHHWANG-GMES 2018-06-26
    LpirRtnCode     : String; // EICR_R.RTN_CD
    ApdrRtnCode     : String; // PCHK_R.RTN_CD
    ApdrRtnSerialNo : String; // PCHK_R.RTN_SERIAL_NO
    LpirProcessCode : string; // LPIR Process Code
  end;

  PSyncHost = ^RSyncHost;
  RSyncHost = record
    MsgType : Integer;
    Channel	: Integer;
    MsgMode : Integer;
    bError  : Boolean;
    Msg     : string;
  end;

  TGmesEvent = procedure(nMsgType, nPg: Integer; bError : Boolean; sErrMsg : string) of object;

  TGmes = class(TObject)
{$IFDEF WIN32}
  mesCommTibRv : TCommTibRv;
  R2RCommTibRv : TCommTibRv;
  {$IFDEF EAS_USE}
  easCommTibRv : TCommTibRv;
  {$ENDIF}
{$ENDIF}



  private
    FMesErrMsgEn   : string;
    FPmMode        : Boolean;
    FEayt          : Boolean;
    FCanUseHost    : Boolean;
    FCanUseEas     : Boolean;
    FCanUseR2R     : Boolean;
    FMesModel      : string;
    FMesModelInfo  : string;
    FMesRtnCd      : string;
    FMesRtnPID     : string;
    FMesErrMsgLc   : string;

    //LPIR
    FMesProsessCode : string;


    //R2R Scenario
    FR2RUnit        : string;
    FR2RMmcTxnID   : string;
    FR2RDatainfo   : string;
    FR2ROC_EODSName  : array [0..11] of string;
    FR2ROC_EODSData  : array [0..11] of string;

    m_sLocal       : string;
    m_sRemote      : string;
    m_sEasLocal   : string;
    m_sEasRemote   : string;
    m_sR2RLocal   : string;
    m_sR2RRemote   : string;
    m_sServicePort : string;

    FSystemNo_MGIB : string;
    FSystemNo_PGIB : string;
    FSystemNo      : string;
    FUserId        : string;
    FHost_Date     : string;

    FMesSerialNo   : string;
    FMesLabelID    : string;
    FMesPf         : string;
    FMesPid        : string;
    FMesFogId      : string;

//    tmCheckNoRes   : TTimer;

    m_bCombiDown      : Boolean;
    m_bDefectDown     : Boolean;
    m_bFullDefectDown : Boolean;
    m_bRepairDown     : Boolean;
    m_bFullRepairDown : Boolean;
    FFtpPass: string;
    FFtpUser: string;
    FFtpAddr: string;

//    tmEqcc  : TTimer;
    FMesUserName: string;
    FMesPg: Integer;
    FMesApdrPg: Integer;
//    FMesPatInfo: string;
    FOnGmsEvent: TGmesEvent;
    FFtpCombiPath: string;

    tmGmesChMsg     : TTimer;   // JHHWANG-GMES 2018-06-26
    tmGmesResponse  : TTimer;
//    SearchRec      : TSearchRec;
    // 내부적으로 Serial Number를 이용하여 PG Idx를 구하자.
    m_sPgSerial : array [DefCommon.CH1..DefCommon.MAX_CH] of string;
    FMesSerialType: Integer;

    function GetLocalIp : string;

    procedure SetDateTime(Year, Month, Day, Hour, Minu, Sec, MSec: Word);
    procedure SetOnGmsEvent(const Value: TGmesEvent);
    procedure SetMesSerialType(const Value: Integer);
    property Host_Date : string read FHost_Date write FHost_Date;

    procedure ReadMsgHost(ASender: TObject; const sMessage: WideString) ;
    procedure ReadMsgEas(ASender: TObject; const sMessage: WideString) ;


//    procedure OntmCheckNoResMsg(Sender: TObject);

    procedure SeperateData(sMsg : string; var nChNo : Integer);
    procedure SeperateR2RData(sMsg: string);// Added by KTS 2023-02-24 오후 5:03:58 R2R Data 분리
    procedure parse_EAYT; // 상위 통신 시작
    procedure parse_UCHK; // 사용자 로그인
    procedure parse_EDTI; // 검사기 시간 동기화.
    procedure parse_SGEN(nCh : Integer;sMsg : string);
    procedure parse_EQCC;
    procedure parse_PCHK(nCh : Integer;sMsg : string);
    procedure parse_EICR(nCh : Integer;sMsg : string);
    procedure parse_EIJR(nCh : Integer;sMsg : string);
    procedure parse_RPR_EIJR(nCh : Integer;sMsg : string);
    procedure parse_INS_PCHK(nCh : Integer;sMsg : string);
    procedure parse_LPIR(nCh : Integer;sMsg : string);

//    procedure parse_FLDR;
    procedure parse_LPHI;
    procedure parse_REPN;
    procedure parse_APDR(nCh : Integer;sMsg : string; bMes : Boolean = True);
    procedure parse_ZSET;
    procedure parse_EODS;

    procedure CheckFLDRProcess;
    function ExtractOCValues(const AInput: string): TDictionary<string, string>;
    function SplitString(const AInput: string; ADelimiter: Char): TArray<string>;
//    procedure SetFTP(FTP: TIdFTP);
    procedure SEND_MESG2HOST(const nMsgType: Integer; sSerialNo: string = ''; sZigId : string = ''; nPg : Integer = 0; bIsDelayed : Boolean = False);  //JHHWANG-GMES: 2018-06-20

//    function GetHostPatInfo(nPGNum, nUnit : Integer) : string;
//    function GetHostApdrInfo(nUnit : Integer) : string;
//    procedure OnEqccTimer(Sender: TObject);
//    function FindChannel(nPg : Integer;sSerialNo : string) : Integer;
    procedure ReturnDataToTestForm(nMode,nPg : Integer; bError : Boolean; sMsg : string);
    procedure OnGmesChMsgTimer(Sender : TObject);   // JHHWANG-GMES 2018-06-27
    procedure OnGemsResponseTimer(Sender : TObject);
    { Private declarations }
  public
    { Public declarations }

    MesData       : array[0 .. MAX_PG_CNT-1] of TGmesDataPack;
    hMainHandle   : HWND;
    hTestHandle1  : HWND;
    hTestHandle2  : HWND;
    m_sLotNo      : string;
    FEiJRSend     : Boolean;
//		NGCodeFTP: TIdFTP;
    m_sCombiDownFile, m_sCombiDownDate   : String;
    m_sDefectDownFile, m_sDefectDownDate : String;
    m_sFullDefectDownFile, m_sFullDefectDownDate : String;
    m_sRepairDownFile, m_sRepairDownDate : String;
    m_sFullRepairDownFile, m_sFullRepairDownDate : String;

    constructor Create(AOwner : TComponent; MainHandle : HWND); virtual;
    destructor Destroy; override;

{$IFDEF WIN64}
    procedure ReadMsgHost64(sMessage: string);
    procedure ReadMsgR2R64(sMessage: string);

    procedure ReadMsgEas64(sMessage: string);

{$ENDIF}

    procedure GetHostData(sMsg : string);
    procedure GetEasData(sMsg : string);
    procedure GetR2RData(sMsg: string);
    procedure SendHostEicr(sSerialNo : string; nPg : Integer; sJigId : string; bIsDelayed : Boolean = False);  //JHHWANG-GMES: 2018-06-20
    procedure SendHostEijr(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);
    procedure SendHostIns_Pchk(sSerialNo : string;nPg : Integer; bIsDelayed : Boolean = False);
    procedure SendHostRPr_Eijr(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);
    procedure SendHostRpr_Vsir(sSerialNo : string;nPg : Integer);
    procedure SendHostRePn(sSerialNo: string; nPg: Integer); // Added by modong 2014-06-20 Label Print 통신 추가
    procedure SendHostEayt;
    procedure SendHostUchk;
    procedure SendHostEqcc;
    procedure SendHostZset(sPid, sZigId : string);
    procedure SendHostSGEN(sSerialNo: string; nPg: Integer; bIsDelayed: Boolean= False);
    procedure SendHostPchk(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);  //JHHWANG-GMES: 2018-06-20
    procedure SendHostLpir(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);
    procedure SendHostFldr(sMsg : string);
    procedure SendHostApdr(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);
    procedure SendEasApdr(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);
    procedure SendR2REods;
    procedure SendR2REodsTest;
    procedure SendR2REoda(nPg,nAACK : Integer);

    function HOST_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath : string) : Boolean;
    // Added by ClintPark 2018-11-13 오후 1:01:05  EAS function.
    function Eas_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath : string) : Boolean;
    function R2R_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath : string) : Boolean;
    function IsMesWaiting(bIsChMsg : Boolean; nThisPgNo : Integer): Boolean;  //JHHWANG-GMES: 2018-06-20
    procedure SendHostStart;
    //DEL!!! procedure SendDelayedMesMsg;  //JHHWANG-GMES: 2018-06-20

//    function  ConnectFTP: Boolean;
//    procedure DisConnectFTP;
    procedure FindAndMoveFile(nFileType: Integer);

    property MesPmMode : Boolean read FPmMode write FPmMode default False;
    property MesEayt   : Boolean read FEayt write FEayt default False;
    property CanUseHost : Boolean read FCanUseHost write FCanUseHost default False;
    property MesRtnCd : string read FMesRtnCd write FMesRtnCd;
    property MesErrMsgEn  : string read FMesErrMsgEn write FMesErrMsgEn;
    property MesErrMsgLc  : string read FMesErrMsgLc write FMesErrMsgLc;
    property MesModel : string read FMesModel write FMesModel;
    property MesModelInfo : string read FMesModelInfo write FMesModelInfo;
    property MesSystemNo : string read FSystemNo write FSystemNo;
    property MesSystemNo_MGIB : string read FSystemNo_MGIB write FSystemNo_MGIB;
    property MesSystemNo_PGIB : string read FSystemNo_PGIB write FSystemNo_PGIB;
    property MesUserId   : string read FUserId write FUserId;
    property MesSerialNo  : string read FMesSerialNo write FMesSerialNo;
    property MesLabelID   : string read FMesLabelID write FMesLabelID;
    property MesUserName  : string read FMesUserName write FMesUserName;
    property MesPID       : string read FMesPid write FMesPid;
    property MesPg        : Integer read FMesPg write FMesPg;
    property MesApdrPg    : Integer read FMesApdrPg write FMesApdrPg;
    property MesSerialType : Integer read FMesSerialType write SetMesSerialType;
    property MesFogId     : string read FMesFogId write FMesFogId;
    property  FtpAddr     : string read FFtpAddr write FFtpAddr;
    property  FtpUser     : string read FFtpUser write FFtpUser;
    property  FtpPass     : string read FFtpPass write FFtpPass;
    property  FtpCombiPath  : string read FFtpCombiPath write FFtpCombiPath;


    property OnGmsEvent   : TGmesEvent read FOnGmsEvent write SetOnGmsEvent;
  end;
var
  DongaGmes : TGmes;

implementation
uses
pasScriptClass;

function TGmes.HOST_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath: string): Boolean;
var
  nCh : Integer;
begin
{$IFDEF WIN32}
  mesCommTibRv.IS_LOG := True;
  mesCommTibRv.IS_LOG_PATH := sPath;
  FCanUseHost := mesCommTibRv.Init(sServicePort, sNetwork, sDemonPort, sLocal, sRemote);
{$ENDIF}

{$IFDEF WIN64}
  CommTibRv.bISLOG := True;
  CommTibRv.sLogPath := sPath;
  FCanUseHost := CommTibRv.Initialize(TIBServer_MES,sServicePort, sNetwork, sDemonPort, sLocal, sRemote);
{$ENDIF}



  m_sLocal  := sLocal;
  m_sRemote := sRemote;
  m_sServicePort  := sServicePort;

//m_MesPendingMsg := MES_UNKNOWN;  //JHHWANG-GMES: 2018-06-20
  for nCh := DefCommon.CH1 to DefCommon.MAX_CH do begin
    MesData[nCh].MesPendingMsg := MES_UNKNOWN;
  end;
//  Common.MLog(DefCommon.MAX_SYSTEM_LOG,'<HOST> HOST_Initial!');
  // 전역변수는 Send할때 쓰임
  Result := FCanUseHost;
end;

procedure TGmes.parse_APDR(nCh : Integer;sMsg : string; bMes : Boolean);
var
	ErrMsg, sSerialNo, sDebug : string;
  i, nPgNo: Integer;
begin

	sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
	sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);

  // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
  if not (nCh in [DefCommon.CH1 .. DefCommon.MAX_CH]) then begin
    // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
    nPgNo := FMesPg;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
  {$IFNDEF ISPD_L_OPTIC}
      if pred(Common.SystemInfo.ChCountUsed) < i then break;
  {$ENDIF}
      if sSerialNo = m_sPgSerial[i] then begin
        nPgNo := i;
        Break;
      end;
    end;
  end
  else begin
    nPgNo := nCh;
  end;
  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    if bMes then sDebug := 'MES REV : '
    else         sDebug := 'EAS REV : ';
    if Length(sMsg) > 600 then begin
      sDebug := sDebug + Copy(sMsg,1,600);
    end
    else begin
      sDebug := sDebug + sMsg;
    end;
    Common.MLog(nPgNo,sDebug);
  end;
  if bMes then begin
    //MES만 처리- EAS는 리턴 기다리지 않음
    MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;   //JHHWANG-COMMON: 2018-06-20
    MesData[nPgNo].ApdrRtnCode     := FMesRtnCd;     // PCHK_R.RTN_CD
    MesData[nPgNo].ApdrRtnSerialNo := sSerialNo;  // PCHK_R.RTN_SERIAL_NO
    MesData[nPgNo].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27
  end;

	if FMesRtnCd = '0' then begin
    if bMes then ReturnDataToTestForm(DefGmes.MES_APDR, nPgNo, False, APDR_OK_MSG)
    else         ReturnDataToTestForm(DefGmes.EAS_APDR, nPgNo, False, APDR_OK_MSG);
	end
	else begin
		ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
    if bMes then ReturnDataToTestForm(DefGmes.MES_APDR, nPgNo, True, ErrMsg)
    else         ReturnDataToTestForm(DefGmes.EAS_APDR, nPgNo, True, ErrMsg);
	end;

end;

procedure TGmes.parse_EAYT;
begin
  if FMesRtnCd = '0' then begin
    FEayt := True;
    SEND_MESG2HOST(DefGmes.MES_UCHK);
    OnGmsEvent(DefGmes.MES_EAYT,0,False,'');
  end
  else begin
  OnGmsEvent(DefGmes.MES_EAYT,0,true,'');
//    OnGmsEvent(DefGmes.MES_EAYT,0,	False,'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
  end;
end;

procedure TGmes.parse_EDTI;
begin
  // Error 처리 할것.
  if FMesRtnCd = '0' then begin
//    Common.Mlog('<HOST> HOST Server Connected Successfully!');
//    CheckFLDRProcess;
    OnGmsEvent(DefGmes.MES_EDTI,0,False,'');
  end
  else begin
   OnGmsEvent(DefGmes.MES_EDTI,0,true,'');
//    OnGmsEvent(DefGmes.MES_EDTI,0,False,'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
  end;
end;

procedure TGmes.parse_EICR(nCh : Integer;sMsg : string);
var
  sSerialNo, ErrMsg : string;
  i, nPgNo               : Integer;
begin
  sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
  sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);
  
  // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
  if not (nCh in [DefCommon.CH1 .. DefCommon.MAX_CH]) then begin
    // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
    nPgNo := FMesPg;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if sSerialNo = m_sPgSerial[i] then begin
        nPgNo := i;
        Break;
      end;
    end;
  end
  else begin
    nPgNo := nCh;
  end;

  MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;   //JHHWANG-GMES: 2018-06-20
  MesData[nPgNo].EicrRtnCode := FMesRtnCd;   // EICR_R.RTN_CD
  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    Common.MLog(nPgNo,'MES REV : ' + sMsg);
  end;

  if FMesRtnCd = '0' then begin
//		MesData[nPgNo].EICR := True;
    ReturnDataToTestForm(DefGmes.MES_EICR,nPgNo,False,EICR_OK_MSG);
  end
  else begin
//		MesData[nPgNo].EICR := False;
    ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
    ReturnDataToTestForm(DefGmes.MES_EICR,nPgNo,True,ErrMsg);
  end;

  MesData[nPgNo].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27
  // When EICR_R received, Call Script Seq_EVENT(EVENT_EICR)

end;

procedure TGmes.parse_EIJR(nCh : Integer;sMsg : string);
var
  sSerialNo, ErrMsg : string;
  i, nPgNo               : Integer;
begin
  sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
  sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);

  nPgNo := FMesPg;
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
//    if pred(Common.SystemInfo.ChCountUsed) < i then break;
    if sSerialNo = m_sPgSerial[i] then begin
      nPgNo := i;
      Break;
    end;
  end;
  MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;   //JHHWANG-GMES: 2018-06-20
  MesData[nPgNo].EicrRtnCode := FMesRtnCd;   // EICR_R.RTN_CD
  FEiJRSend := False;

  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    Common.MLog(nPgNo,sMsg);
  end;

  if FMesRtnCd = '0' then begin
    ReturnDataToTestForm(DefGmes.MES_EIJR,nPgNo,False,EICR_OK_MSG);
  end
  else begin
    ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
    ReturnDataToTestForm(DefGmes.MES_EIJR,nPgNo,True,ErrMsg);
  end;
  MesData[nPgNo].MesSentMsg := MES_UNKNOWN;
end;


procedure TGmes.parse_EODS;
begin
  MesData[FMesPg].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27
  SendR2REods;
end;

procedure TGmes.parse_EQCC;
begin
  if FMesRtnCd <> '0' then begin
    OnGmsEvent(DefGmes.MES_EQCC,0,True,'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
  end;

end;

procedure TGmes.parse_INS_PCHK(nCh : Integer;sMsg: string);
var
	sPModel, sGModel, ErrMsg, sSerialNo : string;
	nPos               : Integer;
  i, nPgNo: Integer;
begin
  sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
  sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);

  if not (nCh in [DefCommon.CH1 .. DefCommon.MAX_CH]) then begin
    // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
    nPgNo := FMesPg;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if sSerialNo = m_sPgSerial[i] then begin
        nPgNo := i;
        Break;
      end;
    end;
  end
  else begin
    nPgNo := nCh;
  end;

//  // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
//  //nPgNo := FMesPg;
//  nPgNo := nCh;
//  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
//{$IFNDEF ISPD_L_OPTIC}
//    if pred(Common.SystemInfo.ChCountUsed) < i then break;
//{$ENDIF}
//    if sSerialNo = m_sPgSerial[i] then begin
//      nPgNo := i;
//      Break;
//    end;
//  end;
  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    Common.MLog(nPgNo,'MES REV : ' + sMsg);
  end;
  MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;   //JHHWANG-COMMON: 2018-06-20
  MesData[nPgNo].PchkRtnCode     := FMesRtnCd;     // PCHK_R.RTN_CD
  MesData[nPgNo].PchkRtnSerialNo := FMesSerialNo;  // PCHK_R.RTN_SERIAL_NO
  MesData[nPgNo].PchkRtnPID := FMesRtnPID;  // PCHK_R.RTN_PID

  // LH588WF1-SD02
  nPos    := Pos('-',FMesModel);
  if nPos <> 0 then begin
    sPModel := Copy(Common.SystemInfo.TestModel, 1, nPos-1);
    sGModel := Copy(FMesModel, 1, nPos-1);
  end;

  MesData[nPgNo].Model := FMesModel;
	if FMesRtnCd = '0' then begin
    MesData[nPgNo].bPCHK := True;
    ReturnDataToTestForm(DefGmes.MES_INS_PCHK, nPgNo, False, PCHK_OK_MSG);
	end
	else begin
		MesData[nPgNo].bPCHK := False;
		ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
		ReturnDataToTestForm(DefGmes.MES_INS_PCHK,nPgNo,True,ErrMsg);
	end;
  MesData[nPgNo].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27
  // When PCHK_R received, Call Script Seq_EVENT(EVENT_EICR)
end;

//procedure TGmes.parse_FLDR;
//begin
//  if FMesRtnCd <> '0' then begin
//    OnGmsEvent(DefGmes.MES_FLDR,0,True,FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
//  end;
//end;

procedure TGmes.parse_LPHI;
begin

end;

procedure TGmes.parse_LPIR(nCh: Integer; sMsg: string);
var
	sPModel, sGModel, ErrMsg, sProcess_Code,sSerialNo : string;
	nPos : Integer;
  i, nPgNo: Integer;
begin
  sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
  sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);

  if not (nCh in [DefCommon.CH1 .. DefCommon.MAX_CH]) then begin
    // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
    nPgNo := FMesPg;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if sSerialNo = m_sPgSerial[i] then begin
        nPgNo := i;
        Break;
      end;
    end;
  end
  else begin
    nPgNo := nCh;
  end;

  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    Common.MLog(nPgNo,'MES REV : ' + sMsg);
  end;
  MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;   //
  MesData[nPgNo].LpirProcessCode     := FMesProsessCode;     // LPIR_R.PROCESS_CODE


  MesData[nPgNo].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27

	if FMesRtnCd = '0' then begin
    MesData[nPgNo].bLPIR := True;
    OnGmsEvent(DefGmes.MES_LPIR,0,False,'');
    ReturnDataToTestForm(DefGmes.MES_LPIR, nPgNo, False, LPIR_OK_MSG);
    SendHostIns_Pchk(sSerialNo, nCh);
	end
	else begin
		MesData[nPgNo].bLPIR := False;
		ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
    OnGmsEvent(DefGmes.MES_LPIR,0,True,'');
		ReturnDataToTestForm(DefGmes.MES_LPIR,nPgNo,True,ErrMsg);
	end;

end;

procedure TGmes.parse_PCHK(nCh : Integer;sMsg : string);
var
	sPModel, sGModel, ErrMsg, sSerialNo : string;
	nPos               : Integer;
  i, nPgNo: Integer;
begin
{$IF Defined(ISPD_POCB)}
	  sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
	  sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);
{$ELSEIF Defined(ISPD_L_OPTIC)}
	  sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
	  sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);
{$ELSE}
  if FMesSerialNo = '' then begin
    FMesSerialNo := FMesPid;
  end;
//  FIsSending := False;
	sSerialNo := StringReplace(FMesSerialNo,#$0a, #$24, [rfReplaceAll]);
	sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);
{$ENDIF}


  if not (nCh in [DefCommon.CH1 .. DefCommon.MAX_CH]) then begin
    // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
    nPgNo := FMesPg;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if sSerialNo = m_sPgSerial[i] then begin
        nPgNo := i;
        Break;
      end;
    end;
  end
  else begin
    nPgNo := nCh;
  end;
  
  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    Common.MLog(nPgNo,'MES REV : ' + sMsg);
  end;
  MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;   //JHHWANG-COMMON: 2018-06-20
  MesData[nPgNo].PchkRtnCode     := FMesRtnCd;     // PCHK_R.RTN_CD
  MesData[nPgNo].PchkRtnSerialNo := FMesSerialNo;  // PCHK_R.RTN_SERIAL_NO
  MesData[nPgNo].PchkRtnPID := FMesRtnPID;  // PCHK_R.RTN_PID

  // LH588WF1-SD02
  nPos    := Pos('-',FMesModel);
  if nPos <> 0 then begin
    sPModel := Copy(Common.SystemInfo.TestModel, 1, nPos-1);
    sGModel := Copy(FMesModel, 1, nPos-1);
  end;

  MesData[nPgNo].Model := FMesModel;
	if FMesRtnCd = '0' then begin
    MesData[nPgNo].bPCHK := True;
    ReturnDataToTestForm(DefGmes.MES_PCHK, nPgNo, False, PCHK_OK_MSG);
	end
	else begin
		MesData[nPgNo].bPCHK := False;
		ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
		ReturnDataToTestForm(DefGmes.MES_PCHK,nPgNo,True,ErrMsg);
	end;
  MesData[nPgNo].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27
  // When PCHK_R received, Call Script Seq_EVENT(EVENT_EICR)
end;


procedure TGmes.parse_SGEN(nCh : Integer;sMsg : string);
var
	sPModel, sGModel, ErrMsg, sSerialNo : string;
	nPos               : Integer;
  i, nPgNo: Integer;
begin
	sSerialNo := StringReplace(FMesPid,#$0a, #$24, [rfReplaceAll]);
	sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);

  if not (nCh in [DefCommon.CH1 .. DefCommon.MAX_CH]) then begin
    // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
    nPgNo := FMesPg;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if sSerialNo = m_sPgSerial[i] then begin
        nPgNo := i;
        Break;
      end;
    end;
  end
  else begin
    nPgNo := nCh;
  end;

  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    Common.MLog(nPgNo,'MES REV : ' + sMsg);
  end;
  MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;
  MesData[nPgNo].PchkRtnCode     := FMesRtnCd;     // SGEN_R.RTN_CD
  MesData[nPgNo].PchkRtnSerialNo := FMesSerialNo;  // SGEN_R.RTN_SERIAL_NO

  if FMesRtnCd = '0' then begin
    MesData[nPgNo].bPCHK := True;
    ReturnDataToTestForm(DefGmes.MES_SGEN, nPgNo, False, 'SGEN OK!');
	end
	else begin
		MesData[nPgNo].bPCHK := False;
		ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
		ReturnDataToTestForm(DefGmes.MES_SGEN,nPgNo,True,ErrMsg);
	end;
  MesData[nPgNo].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27
end;

procedure TGmes.parse_REPN;
begin

end;

procedure TGmes.parse_RPR_EIJR(nCh : Integer;sMsg: string);
var
  sSerialNo, ErrMsg, sDebug : string;
  i, nPgNo               : Integer;
begin
  sSerialNo := StringReplace(FMesFogId,#$0a, #$24, [rfReplaceAll]);
  sSerialNo := StringReplace(sSerialNo,#$0d, #$25, [rfReplaceAll]);

  if not (nCh in [DefCommon.CH1 .. DefCommon.MAX_CH]) then begin
    // 보내고 받는 중간에 다른 데이터가 치고 들어 올때 PG Idx 꼬일수 밖에 없음.
    nPgNo := FMesPg;
    for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
  {$IFNDEF ISPD_L_OPTIC}
      if pred(Common.SystemInfo.ChCountUsed) < i then break;
  {$ENDIF}
      if sSerialNo = m_sPgSerial[i] then begin
        nPgNo := i;
        Break;
      end;
    end;
  end
  else begin
    nPgNo := nCh;
  end;

  if nPgNo in [DefCommon.CH1 .. DefCommon.MAX_CH] then begin
    Common.MLog(nPgNo,'MES REV : '+sMsg);
  end;
  FEiJRSend := False;
  MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;   //JHHWANG-COMMON: 2018-06-20
  MesData[nPgNo].EicrRtnCode     := FMesRtnCd;     // PCHK_R.RTN_CD
  MesData[nPgNo].SerialNo       := sSerialNo;  // PCHK_R.RTN_SERIAL_NO

  MesData[nPgNo].MesSentMsg := MES_UNKNOWN; // JHHWANG-GMES 2018-06-27

  if FMesRtnCd = '0' then begin
    ReturnDataToTestForm(DefGmes.MES_RPR_EIJR,nPgNo,False,RPR_EIJR_OK_MSG);
  end
  else begin
    ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
    ReturnDataToTestForm(DefGmes.MES_RPR_EIJR,nPgNo,True,ErrMsg);
  end;
end;

procedure TGmes.parse_UCHK;
begin
  if trim(FMesRtnCd) = '0' then begin
    Host_Date := FHost_Date;
    fPMMode := False;
    SEND_MESG2HOST(DefGmes.MES_EDTI);
    OnGmsEvent(DefGmes.MES_UCHK,0,False,'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
  end
  else begin
    OnGmsEvent(DefGmes.MES_UCHK,0,True,'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
  end;
end;

procedure TGmes.parse_ZSET;
var
  ErrMsg : String;
begin
  ErrMsg := 'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')';
  if trim(FMesRtnCd) = '0' then begin // OK
    MesData[DefCommon.CH1].bPCHK := True;
    ReturnDataToTestForm(DefGmes.MES_ZSET,0,False,ErrMsg);
//    OnGmsEvent(DefGmes.MES_ZSET,0,False,'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
  end
  else begin  // NG
    MesData[DefCommon.CH1].bPCHK := False;
    ReturnDataToTestForm(DefGmes.MES_ZSET,0,True,ErrMsg);
//    OnGmsEvent(DefGmes.MES_ZSET,0,True,'Error code:'+FMesRtnCd+' : '+FMesErrMsgLc + '('+ FMesErrMsgEn + ')');
  end;
end;

function TGmes.R2R_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath: string): Boolean;
var
  nCh : Integer;
begin
{$IFDEF WIN32}
  {$IFDEF EAS_USE}
  R2RCommTibRv.IS_LOG := True;
  R2RCommTibRv.IS_LOG_PATH := sPath;
  m_sR2RRemote := sRemote;
  m_sR2RLocal:= sLocal;
  FCanUseEas := R2RCommTibRv.Init(sServicePort, sNetwork, sDemonPort, sLocal, sRemote);
  {$ENDIF}
{$ENDIF}
{$IFDEF WIN64}
  CommTibRv.bISLOG := True;
  CommTibRv.sLogPath := sPath;
  m_sR2RRemote := sRemote;
  m_sR2RLocal:= sLocal;
  FCanUseR2R := CommTibRv.Initialize(TIBServer_R2R,sServicePort, sNetwork, sDemonPort, sLocal, sRemote);
{$ENDIF}
  if not FCanUseR2R then begin
    ShowMessage('[R2R initialization failure - Confirm HOST environment setup]');
  end;

  Result := FCanUseR2R;
end;


procedure TGmes.ReadMsgEas(ASender: TObject; const sMessage: WideString);
begin
  GetEasData(sMessage);
end;

procedure TGmes.ReadMsgHost(ASender: TObject; const sMessage: WideString);
//var
//  sMsg : WideString;
begin
//  sMsg := StringReplace(sMessage,#$0a, #$24, [rfReplaceAll]);
//  sMsg := StringReplace(sMsg,#$0d, #$25, [rfReplaceAll]);
  GetHostData(UTF8ToString(sMessage));
end;

{$IFDEF WIN64}

procedure TGmes.ReadMsgHost64(sMessage: string);
begin
  GetHostData(UTF8ToString(sMessage));
end;


procedure TGmes.ReadMsgEas64(sMessage: string);
begin
  GetEasData(UTF8ToString(sMessage));
end;


procedure TGmes.ReadMsgR2R64(sMessage: string);
begin
  GetR2RData(UTF8ToString(sMessage));
end;
{$ENDIF}



procedure TGmes.ReturnDataToTestForm(nMode, nPg: Integer; bError: Boolean; sMsg: string);
var
  ccd         : TCopyDataStruct;
  HostUiMsg   : RSyncHost;
  nJig        : Integer;
begin
  HostUiMsg.MsgType := MSG_TYPE_HOST;
  HostUiMsg.MsgMode := nMode;
  HostUiMsg.Channel	:= nPg;
  HostUiMsg.bError  := bError;
  HostUiMsg.Msg     := sMsg;
  ccd.dwData        :=   0;
  ccd.cbData        := SizeOf(HostUiMsg);
  ccd.lpData        := @HostUiMsg;
  nJig := nPg div 4;
  if nJig = 0 then begin
    SendMessage(hTestHandle1 ,WM_COPYDATA,0, LongInt(@ccd));
  end
  else begin
    SendMessage(hTestHandle2 ,WM_COPYDATA,0, LongInt(@ccd));
  end;
end;

{ TGmes }

//procedure TGmes.OnEqccTimer(Sender: TObject);
//begin
//  SEND_MESG2HOST(DefGmes.MES_EQCC);
//end;
//
//procedure TGmes.OntmCheckNoResMsg(Sender: TObject);
//begin
////	tmCheckNoRes.Enabled  := False;
//{var
//  ErrMsg : string;
//begin
//  Timer_HostTimeoutCheck.Enabled := False;
//  Timer_HostTimeoutCheck.Interval := 10000;
//  if not m_bRvMsg then begin
//    if m_nSendMsg = MES_EICR then begin
//      ErrMsg := GetAlarmStr(m_nSendMsg);
//      ErrToMes(ErrMsg,gnEICRCnt);
//      (FindComponent('Edit_PanelID'+IntToStr(gnEICRCnt)) as TRzEdit).Text := '';// dragonbin 20100607
//      (FindComponent('pnlSubResult'+IntToStr(gnEICRCnt)) as TRzPanel).Caption := '<HOST> No Response Message !';
//    end
//    else if m_nSendMsg = MES_PCHK then begin
//      ErrMsg := GetAlarmStr(m_nSendMsg);
//      ErrToMes(ErrMsg,gnPCHKCnt);
//      (FindComponent('Edit_PanelID'+IntToStr(gnPCHKCnt)) as TRzEdit).Text := '';// dragonbin 20100607
//      (FindComponent('pnlSubResult'+IntToStr(gnPCHKCnt)) as TRzPanel).Caption := '<HOST> No Response Message !';
//
//      if SystemInfo.TestMode = INLINE_OPTICS then begin
//        Set_DIO(DIO_OUT_LAMP);
//        ConfirmMsg('HOST PCHK NG - No Response Message !');
//        ShowErrMessage(305,'');
//        Set_DIO(DIO_OUT_LAMP);
//        AutoTestEnable(False);
//      end;
//    end
//    else if m_nSendMsg = MES_APDR then begin
//      ErrMsg := GetAlarmStr(m_nSendMsg);
//      ErrToMes(ErrMsg,gnAPDRCnt);
//      (FindComponent('Edit_PanelID'+IntToStr(gnAPDRCnt)) as TRzEdit).Text := '';// dragonbin 20100607
//      (FindComponent('pnlSubResult'+IntToStr(gnAPDRCnt)) as TRzPanel).Caption := '<HOST> No Response Message !';
//      if SystemInfo.TestMode = INLINE_OPTICS then begin
//        AutoTestEnable(False);
//        Set_DIO(DIO_OUT_LAMP);
//        ShowErrMessage(305,'');
//        Set_DIO(DIO_OUT_LAMP);
//      end;
//    end
//    else if m_nSendMsg = MES_REPN then begin
//      ErrMsg := GetAlarmStr(m_nSendMsg);
//      ErrToMes(ErrMsg,Cbox_LabelCh.ItemIndex + 1);
//      (FindComponent('Edit_PanelID'+IntToStr(Cbox_LabelCh.ItemIndex + 1)) as TRzEdit).Text := '';// dragonbin 20100607
//      (FindComponent('pnlSubResult'+IntToStr(Cbox_LabelCh.ItemIndex + 1)) as TRzPanel).Caption := '<HOST> No Response Message !';
//    end
//    else begin
//      ErrMsg := GetAlarmStr(m_nSendMsg);
//      ShowErrMessage(326,ErrMsg);
//    end;
//  end;
//  MLog(0, '<HOST> No Response Message !');}
//end;

procedure TGmes.CheckFLDRProcess;
//var
//  s1, s2, s3, s4, s5 : TStrings;
//  sDownFile : String;
//  i, iLast : Integer;
//  ARecord : TIdFTPListItem;
begin
  m_bCombiDown      := False;
  m_bDefectDown     := False;
  m_bFullDefectDown := False;
  m_bRepairDown     := False;
  m_bFullRepairDown := False;

//	if DongaYT.SysInfo.HOST_FTP_CombiPath = '' then begin
//		DongaYT.Mlog('<HOST> No FTP Path!');
////    ShowErrMessage(320, '');
//	end
//	else begin
//		if ConnectFTP then begin
//			DongaYT.Mlog('<HOST> Conncet FTP!');
//			NGCodeFtp.ChangeDir(DongaYT.SysInfo.HOST_FTP_CombiPath);
//
//			sList := TStringList.Create; s1    := TStringList.Create;
//			s2    := TStringList.Create; s3    := TStringList.Create;
//			s4    := TStringList.Create; s5    := TStringList.Create;
//			sList.Clear;                 s1.Clear;
//			s2.Clear;                    s3.Clear;
//      s4.Clear;                    s5.Clear;
//			try
//        NGCodeFtp.List(sList,'',False);
//
//        for i := 0 to sList.Count - 1 do begin
////          if Pos('.TXT', UpperCase(sList.Strings[i])) = 0 then Exit;
//          if sList.Strings[i] = '.' then Continue;
//          if sList.Strings[i] = '..' then Continue;
//          if Pos('\', UpperCase(sList.Strings[i])) <> 0 then Continue;   // folder는 뺍시다.
//
////          ARecord := NGCodeFtp.DirectoryListing.Items[i];
////          if not (ARecord.ItemType = ditDirectory) then begin
//          if Pos(DefGmes.PREFIX_COMBI, UpperCase(sList.Strings[i])) > 0 then
//						s1.Add(sList.Strings[i]);
//          if (Pos(DefGmes.PREFIX_DEFECT, UpperCase(sList.Strings[i])) > 0) and (Pos(DefGmes.PREFIX_FULL_DEF, UpperCase(sList.Strings[i])) = 0) then
//            s2.Add(sList.Strings[i]);
//          if Pos(DefGmes.PREFIX_FULL_DEF, UpperCase(sList.Strings[i])) > 0 then
//						s3.Add(sList.Strings[i]);
//          if (Pos(DefGmes.PREFIX_REPAIR, UpperCase(sList.Strings[i])) > 0) and (Pos(DefGmes.PREFIX_FULL_REP, UpperCase(sList.Strings[i])) = 0) then
//            s4.Add(sList.Strings[i]);
//          if Pos(DefGmes.PREFIX_FULL_REP, UpperCase(sList.Strings[i])) > 0 then
//						s5.Add(sList.Strings[i]);
////          end;
//        end;
//
//				// Combi File Check and Download
//				sDownFile := '';
//				if s1.Count = 0 then begin
////          MLog(0,'<HOST> File Download Fail! Not Exist COMBI File on FTP Server!');
////          ShowErrMessage(321, '');
//				end
//				else if s1.Count = 1 then begin
//          sDownFile := s1.Strings[0];
//        end
//				else if s1.Count > 1 then begin
//          iLast := 0;
//          for i := 0 to s1.Count - 2 do begin
//            if StrToFloat(Copy(s1.Strings[i+1], Length(s1.Strings[i])-17, 14)) > StrToFloat(Copy(s1.Strings[i], Length(s1.Strings[i])-17, 14)) then
//              iLast := i+1;
//					end;
//          sDownFile := s1.Strings[iLast];
//        end;
//
//        if sDownFile <> '' then begin
//					if not FileExists(DongaYT.m_sCombi + sDownFile) then begin
//            FindAndMoveFile(DefGmes.COMBI_FILE);
//            try
//              NGCodeFtp.Get(sDownFile, DongaYT.m_sCombi + sDownFile, True, False);
//							m_bCombiDown     := True;
//              m_sCombiDownFile := sDownFile;
//              m_sCombiDownDate := FormatDateTime('YYYYMMDDHHNNSS', Now);
//						except
//            end;
//          end
//					else begin
//            DongaYT.Mlog('<HOST> Same COMBI File aleady exist!');
//          end;
//
//        end;
//
//				// Defect File Check and Download
//        sDownFile := '';
//        if s2.Count = 0 then begin
////          MLog(0,'<HOST> File Download Fail! Not Exist DEFECT File on FTP Server!');
////          ShowErrMessage(322, '');
//        end
//				else if s2.Count = 1 then begin
//          sDownFile := s2.Strings[0];
//        end
//				else if s2.Count > 1 then begin
//          iLast := 0;
//          for i := 0 to s2.Count - 2 do begin
//						if StrToFloat(Copy(s2.Strings[i+1], Length(s2.Strings[i])-17, 14)) > StrToFloat(Copy(s2.Strings[i], Length(s2.Strings[i])-17, 14)) then
//              iLast := i+1;
//          end;
//					sDownFile := s2.Strings[iLast];
//        end;
//
//				if sDownFile <> '' then begin
//          if not FileExists(DongaYT.m_sDefect + sDownFile) then begin
//            FindAndMoveFile(DEFECT_FILE);
//						try
//              NGCodeFtp.Get(sDownFile, DongaYT.m_sDefect + sDownFile, True, False);
//              m_bDefectDown     := True;
//							m_sDefectDownFile := sDownFile;
//              m_sDefectDownDate := FormatDateTime('YYYYMMDDHHNNSS', Now);
//            except
//						end;
//          end
//          else
//						DongaYT.MLog('<HOST> Same DEFECT File aleady exist!');
//        end;
//
//				// Full Defect File Check and Download
//        sDownFile := '';
//        if s3.Count = 0 then begin
////          MLog(0,'<HOST> File Download Fail! Not Exist FULL_DEFECT File on FTP Server!');
////          ShowErrMessage(323, '');
//        end
//				else if s3.Count = 1 then begin
//          sDownFile := s3.Strings[0];
//        end
//				else if s3.Count > 1 then begin
//          iLast := 0;
//          for i := 0 to s3.Count - 2 do begin
//						if StrToFloat(Copy(s3.Strings[i+1], Length(s3.Strings[i])-17, 14)) > StrToFloat(Copy(s3.Strings[i], Length(s3.Strings[i])-17, 14)) then
//              iLast := i+1;
//          end;
//					sDownFile := s3.Strings[iLast];
//        end;
//
//				if sDownFile <> '' then begin
//          if not FileExists(DongaYT.m_sDefect + sDownFile) then begin
//            FindAndMoveFile(DEFECT_FULL_FILE);
//						try
//              NGCodeFtp.Get(sDownFile, DongaYT.m_sDefect + sDownFile, True, False);
//              m_bFullDefectDown     := True;
//							m_sFullDefectDownFile := sDownFile;
//              m_sFullDefectDownDate := FormatDateTime('YYYYMMDDHHNNSS', Now);
//            except
//						end;
//          end
//          else
//						DongaYT.MLog('<HOST> Same FULL_DEFECT File aleady exist!');
//        end;
//
//				// Repair File Check and Download
//        sDownFile := '';
//        if s4.Count = 0 then begin
//					DongaYT.MLog('<HOST> File Download Fail! Not Exist REPAIR File on FTP Server!');
////          ShowErrMessage(324, '');
//        end
//				else if s4.Count = 1 then begin
//          sDownFile := s4.Strings[0];
//        end
//				else if s4.Count > 1 then begin
//          iLast := 0;
//          for i := 0 to s4.Count - 2 do begin
//						if StrToFloat(Copy(s4.Strings[i+1], Length(s4.Strings[i])-17, 14)) > StrToFloat(Copy(s4.Strings[i], Length(s4.Strings[i])-17, 14)) then
//              iLast := i+1;
//          end;
//					sDownFile := s4.Strings[iLast];
//        end;
//
//				if sDownFile <> '' then begin
//          if not FileExists(DongaYT.m_sRepair + sDownFile) then begin
//            FindAndMoveFile(REPAIR_FILE);
//						try
//              NGCodeFtp.Get(sDownFile, DongaYT.m_sRepair + sDownFile, True, False);
//              m_bRepairDown     := True;
//							m_sRepairDownFile := sDownFile;
//              m_sRepairDownDate := FormatDateTime('YYYYMMDDHHNNSS', Now);
//            except
//						end;
//          end
//          else
//						DongaYT.MLog('<HOST> Same REPAIR File aleady exist!');
//        end;
//
//				// Full Repair File Check and Download
//        sDownFile := '';
//        if s5.Count = 0 then begin
//					DongaYT.MLog('<HOST> File Download Fail! Not Exist FULL_REPAIR File on FTP Server!');
////          ShowErrMessage(325, '');
//        end
//				else if s5.Count = 1 then begin
//          sDownFile := s5.Strings[0];
//        end
//				else if s5.Count > 1 then begin
//          iLast := 0;
//          for i := 0 to s5.Count - 2 do begin
//						if StrToFloat(Copy(s5.Strings[i+1], Length(s5.Strings[i])-17, 14)) > StrToFloat(Copy(s5.Strings[i], Length(s5.Strings[i])-17, 14)) then
//              iLast := i+1;
//          end;
//					sDownFile := s5.Strings[iLast];
//        end;
//
//				if sDownFile <> '' then begin
//					if not FileExists(DongaYT.m_sRepair + sDownFile) then begin
//						FindAndMoveFile(REPAIR_FULL_FILE);
//						try
//							NGCodeFtp.Get(sDownFile, DongaYT.m_sRepair + sDownFile, True, False);
//							m_bFullRepairDown     := True;
//							m_sFullRepairDownFile := sDownFile;
//							m_sFullRepairDownDate := FormatDateTime('YYYYMMDDHHNNSS', Now);
//						except
//						end;
//          end
//					else
//						DongaYT.MLog('<HOST> Same FULL_REPAIR File aleady exist!');
//				end;
//
//			finally
//				sList.Free;
//				s1.Free;
//				s2.Free;
//				s3.Free;
//				s4.Free;
//				s5.Free;
//				DisConnectFTP;
//			end;
//		end;
//  end;

  if m_bCombiDown then begin
    SEND_MESG2HOST(DefGmes.MES_FLDR, 'COMBI');
    Sleep(100);
  end;

  if m_bDefectDown then begin
    SEND_MESG2HOST(DefGmes.MES_FLDR, 'DEFECT');
    Sleep(100);
  end;

  if m_bFullDefectDown then begin
    SEND_MESG2HOST(DefGmes.MES_FLDR, 'FULL_DEFECT');
    Sleep(100);
  end;

  if m_bRepairDown then begin
    SEND_MESG2HOST(DefGmes.MES_FLDR, 'REPAIR');
    Sleep(100);
  end;

  if m_bFullRepairDown then begin
    SEND_MESG2HOST(DefGmes.MES_FLDR, 'FULL_REPAIR');
    Sleep(100);
  end;

end;

//function TGmes.ConnectFTP: Boolean;
//var
//	bRtn  : Boolean;
//begin
//	bRtn := False;
//	SetFTP(NGCodeFtp);
//	try
//    NGCodeFtp.Connect;
//    except on E:Exception do begin
//      Exit(bRtn);
//    end;
//  end;
//  Sleep(100);
//  if NGCodeFtp.Connected then begin
//    bRtn := True;
//  end
//  else begin
//    MessageDlg(#13#10 + 'FTP Connection Fail!', mtError, [mbOK], 0);
//    bRtn := False;
//  end;
//  Result := bRtn;
//end;

constructor TGmes.Create(AOwner : TComponent; MainHandle : HWND);
begin
{$IFDEF WIN32}
  mesCommTibRv := TCommTibRv.Create(AOwner);
  mesCommTibRv.OnMessageReceive := ReadMsgHost;
{$IFDEF EAS_USE}
  easCommTibRv :=  TCommTibRv.Create(AOwner);
  easCommTibRv.OnMessageReceive := ReadMsgEas;
{$ENDIF}

{$ENDIF}

{$IFDEF WIN64}
  CommTibRv := TCommTibRv64.Create(MainHandle,Common.Path.RootSW,'TIBCO_ECS_Converter.dll');
  CommTibRv.SetCallBack;
{$IFDEF EAS_USE}
//  easCommTibRv := TCommTibRv64.Create(MainHandle,MainHandle,Common.Path.RootSW,'TIBCO_ECS_Converter.dll');
//  easCommTibRv.SetCallBack;

{$ENDIF}

{$ENDIF}


//

  FEiJRSend := False;

  FMesErrMsgEn    := '';
  FPmMode         := True;  //TBD  JHHWANG-GNES: 2018-06-20 False->True
  FEayt           := False;
  FCanUseHost     := False;
  FMesModel       := '';
  FMesRtnCd       := '';
  FMesErrMsgLc    := '';

  FMesPg          := 0;
  FMesApdrPg      := 0;
  FMesFogId       := '';

  // GMES PCHK/EICR timer
  tmGmesChMsg := TTimer.Create(nil);
  tmGmesChMsg.Interval := 500;  // 100 msec  -? 500 변경
  tmGmesChMsg.OnTimer := OnGmesChMsgTimer;
  tmGmesChMsg.Enabled := False;

  // about time out.
  tmGmesResponse := TTimer.Create(nil);
  tmGmesResponse.Interval := 3000;  // 100 msec
  tmGmesResponse.OnTimer := OnGemsResponseTimer;
  tmGmesResponse.Enabled := False;

end;

destructor TGmes.Destroy;
begin
  // Timer 해제.
//  tmCheckNoRes.Enabled := False;
//  tmCheckNoRes.Free;
//  tmCheckNoRes := nil;

//	tmEqcc.Enabled  := False;
//  tmEqcc.Free;
//  tmEqcc := nil;

//  NGCodeFTP.Free;
//  NGCodeFTP := nil;
  // Tib Driver 해제.
  if tmGmesChMsg <> nil then begin
    tmGmesChMsg.Enabled := False;
    tmGmesChMsg.Free;
    tmGmesChMsg := nil;
  end;

  if tmGmesResponse <> nil then begin
    tmGmesResponse.Enabled := False;
    tmGmesResponse.Free;
    tmGmesResponse := nil;
  end;



{$IFDEF WIN32}
{$IFDEF EAS_USE}
  easCommTibRv.Terminate;
  easCommTibRv.Free;
  easCommTibRv := nil;
{$ENDIF}

  mesCommTibRv.Terminate;
  mesCommTibRv.Free;
  mesCommTibRv := nil;
{$ENDIF}
{$IFDEF WIN64}
{$IFDEF EAS_USE}
//  easCommTibRv.Terminate;
//  easCommTibRv.Free;
//  easCommTibRv := nil;
{$ENDIF}


  CommTibRv.Terminate;
  CommTibRv.Free;
  CommTibRv := nil;
{$ENDIF}



  inherited Destroy;
end;


function TGmes.Eas_Initial(sServicePort, sNetwork, sDemonPort, sLocal, sRemote, sPath: string): Boolean;
var
  nCh : Integer;
begin
{$IFDEF WIN32}
  {$IFDEF EAS_USE}
  easCommTibRv.IS_LOG := True;
  easCommTibRv.IS_LOG_PATH := sPath;
  m_sEasRemote := sRemote;
  m_sEasLocal:= sLocal;
  FCanUseEas := easCommTibRv.Init(sServicePort, sNetwork, sDemonPort, sLocal, sRemote);
  {$ENDIF}
{$ENDIF}
{$IFDEF WIN64}
  CommTibRv.bISLOG := True;
  CommTibRv.sLogPath := sPath;
  m_sEasRemote := sRemote;
  m_sEasLocal:= sLocal;
  FCanUseEas := CommTibRv.Initialize(TIBServer_EAS,sServicePort, sNetwork, sDemonPort, sLocal, sRemote);
{$ENDIF}
  if not FCanUseEas then begin
    ShowMessage('[EAS initialization failure - Confirm HOST environment setup]');
  end;

  Result := FCanUseEas;
end;

//procedure TGmes.DisConnectFTP;
//begin
//	if NGCodeFtp.Connected then begin
//		try
//      NGCodeFtp.Quit;
//      m_bFtpConnect := False;
//    except on E:Exception do
//    end;
//  end;
//end;

procedure TGmes.FindAndMoveFile(nFileType: Integer);
//var
//  Rslt : Integer;
//  sSrcFilePath, sDestFilePath, sPrefix : String;
//  sr  : TSearchRec;
begin
//  case nFileType of
//    DefGmes.COMBI_FILE : begin
//      sSrcFilePath  := DongaYT.m_sCombi ;
//      sDestFilePath := DongaYT.m_sBackCombi;
//      sPrefix       := DefGmes.PREFIX_COMBI;
//    end;
//
//    DefGmes.DEFECT_FILE : begin
//      sSrcFilePath  :=  DongaYT.m_sDataPath;
//      sDestFilePath :=  DongaYT.m_sBackDefect;
//      sPrefix       := DefGmes.PREFIX_DEFECT;
//    end;
//
//    DefGmes.DEFECT_FULL_FILE :  begin
//      sSrcFilePath  := DongaYT.m_sDataPath;
//      sDestFilePath := DongaYT.m_sBackDefect;
//      sPrefix       := DefGmes.PREFIX_FULL_DEF;
//    end;
//
//    DefGmes.REPAIR_FILE :      begin
//      sSrcFilePath  := DongaYT.m_sRepair;;
//      sDestFilePath := DongaYT.m_sBackRepair;
//      sPrefix       := DefGmes.PREFIX_REPAIR;
//    end;
//
//    DefGmes.REPAIR_FULL_FILE : begin
//      sSrcFilePath  := DongaYT.m_sRepair;
//      sDestFilePath := DongaYT.m_sBackRepair;
//      sPrefix       := DefGmes.PREFIX_FULL_REP;
//    end;
//  end;
//
//  Rslt := FindFirst(sSrcFilePath + sPrefix + '*.*', faAnyFile, sr);
//  while Rslt = 0 do begin
//    MoveFile(PChar(sSrcFilePath + sr.Name), PChar(sDestFilePath + sr.Name));
//    Rslt := FindNext(sr);
//  end;
//  FindClose(sr);
end;

//function TGmes.FindChannel(nPg : Integer; sSerialNo: string): Integer;
//var
//	i, nCh  : Integer;
//	sDebug  : string;
//begin
//	nCh := 0;
//
//	for i := 1 to DefDonga.MAX_CH_CNT do begin
//		if MesData[nPg,i].SerialNo = '' then Continue; // 사용하지 않는 Channel.
//		sDebug := Format('[Find Channel] Ch%d RevData(%s)',[i,sSerialNo]);
//		if MesData[nPg,i].SerialNo = sSerialNo  then begin
//			if MesData[nPg,i].Registry then begin
//				MesData[nPg,i].Registry := False;
//				nCh := i;
//				Break;
//			end;
//		end;
//	end;
////  DongaYT.Mlog(sDebug,nPg);
//	Result := nCh;
//end;

//function TGmes.GetHostApdrInfo(nUnit: Integer): string;
//begin
//
//end;



procedure TGmes.GetR2RData(sMsg: string);
var
  sMode   : string;
  sDebug  : string;
  nCh     : Integer;
begin
  if Length(sMsg) < 6 then Exit;
  {$IFDEF SIMULATOR_GMES}
  sMode := Copy(sMsg,1,6);
  {$ELSE}
  sMode := Copy(sMsg,1,4);
  {$ENDIF}
  SeperateR2RData(sMsg);

  {$IFDEF SIMULATOR_GMES}
  if CompareStr(sMode,'EODS_R') = 0 then parse_EODS;
  {$ELSE}
  if CompareStr(sMode,'EODS') = 0 then parse_EODS;
  {$ENDIF}

end;
procedure TGmes.GetEasData(sMsg: string);
var
  sMode   : string;
  sDebug  : string;
  nCh     : Integer;
begin
  if Length(sMsg) < 6 then Exit;
  sMode := Copy(sMsg,1,6);
  SeperateData(sMsg,nCh);

//  sDebug := StringReplace(sMsg,#$0a, #$24, [rfReplaceAll]);
//  sDebug := StringReplace(sDebug,#$0d, #$25, [rfReplaceAll]);
//  if (sMode = 'APDR_R') then begin
//    Common.Mlog(Format('[HOST] Recv Msg: %s PG : %d', [sDebug, FMesPg]));
//  end
//  else begin
//    Common.Mlog(Format('[HOST] Recv Msg: %s PG : %d', [sDebug, FMesPg]));
//  end;

  if CompareStr(sMode,'APDR_R') = 0 then parse_APDR(nCh,sMsg,False);
end;

procedure TGmes.GetHostData(sMsg: string);
var
  sMode   : string;
  sDebug  : string;
  nCh     : Integer;
begin
  if Length(sMsg) < 6 then Exit;
  sMode := Copy(sMsg,1,6);
  SeperateData(sMsg,nCh);

  sDebug := StringReplace(sMsg,#$0a, #$24, [rfReplaceAll]);
  sDebug := StringReplace(sDebug,#$0d, #$25, [rfReplaceAll]);
//  if (sMode = 'APDR_R') then begin
//    Common.Mlog(Format('[HOST] Recv Msg: %s PG : %d', [sDebug, FMesPg]));
//  end
//  else begin
//    Common.Mlog(Format('[HOST] Recv Msg: %s PG : %d', [sDebug, FMesPg]));
//  end;

  if      CompareStr(sMode,'EAYT_R') = 0 then	parse_EAYT
  else if CompareStr(sMode,'UCHK_R') = 0 then	parse_UCHK
  else if CompareStr(sMode,'SGEN_R') = 0 then	parse_SGEN(nCh,sMsg)
  else if CompareStr(sMode,'EDTI_R') = 0 then	parse_EDTI
  else if CompareStr(sMode,'EQCC_R') = 0 then	parse_EQCC
  else if CompareStr(sMode,'PCHK_R') = 0 then	parse_PCHK(nCh,sMsg)
  else if CompareStr(sMode,'INS_PC') = 0 then	parse_INS_PCHK(nCh,sMsg)  //RPR_PC
  else if CompareStr(sMode,'LPHI_R') = 0 then parse_LPHI
  else if CompareStr(sMode,'REPN_R') = 0 then parse_REPN
  else if CompareStr(sMode,'APDR_R') = 0 then parse_APDR(nCh,sMsg)
  else if CompareStr(sMode,'ZSET_R') = 0 then parse_ZSET
  else if CompareStr(sMode,'LPIR_R') = 0 then parse_LPIR(nCh, sMsg)
  else if CompareStr(sMode,'EICR_R') = 0 then	begin
    parse_EICR(nCh,sMsg);
  end
  else if CompareStr(sMode,'RPR_EI') = 0 then	begin
    parse_RPR_EIJR(nCh,sMsg);
  end
  else if CompareStr(sMode,'EIJR_R') = 0 then	begin
    parse_EIJR(nCh,sMsg);
  end;
//	else if CompareStr(sMode,'RPR_VS') = 0 then	begin //RPR_VSIR
//		parse_EICR;
//	end
//	else if CompareStr(sMode,'FLDR_R') = 0 then	parse_FLDR;

  //DEL!!! SendDelayedMesMsg;  //JHHWANG-GMES 2018-06-20

end;

//function TGmes.GetHostPatInfo(nPGNum, nUnit: Integer): string;
//begin
//
//end;

function TGmes.GetLocalIp: string;
var
  pHostInfo : pHostEnt;
  pszHostName : array[0..40] of AnsiChar;
begin
  GetHostName(pszHostName, 40);
  pHostInfo := GetHostByName(pszHostName);
  if Assigned(pHostInfo) then
  begin
    Result := IntToStr(ord(pHostInfo.h_addr_list^[0])) + '.' +
              IntToStr(ord(pHostInfo.h_addr_list^[1])) + '.' +
              IntToStr(ord(pHostInfo.h_addr_list^[2])) + '.' +
              IntToStr(ord(pHostInfo.h_addr_list^[3]));
  end;
end;

procedure TGmes.SendEasApdr(sSerialNo: string; nPg: Integer; bIsDelayed : Boolean = False);
var
  sConvertSerial : string;
begin
  FMesApdrPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  SEND_MESG2HOST(DefGmes.EAS_APDR,sConvertSerial,'',nPg, bIsDelayed);  //JHHWANG-GMES 2018-06-20
end;

procedure TGmes.SendHostApdr(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);
var
  sConvertSerial : string;
begin
  FMesApdrPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  SEND_MESG2HOST(DefGmes.MES_APDR,sConvertSerial,'',nPg, bIsDelayed);  //JHHWANG-GMES 2018-06-20
end;

procedure TGmes.SendHostEayt;
begin
  FMesPg          := 0;
  FMesApdrPg      := 0;
  SEND_MESG2HOST(DefGmes.MES_EAYT);
end;

procedure TGmes.SendHostEicr(sSerialNo : string; nPg : Integer; sJigId : string; bIsDelayed : Boolean = False);  //JHHWANG-GMES 2018-06-20
var
  sConvertSerial : string;
  sConvertJig    : string;
begin
  FMesPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);

  if Length(sJigId) = 0 then
    sConvertJig := sConvertSerial;
  sConvertJig := StringReplace(sJigId,#$24, #$0a, [rfReplaceAll]);
  sConvertJig := StringReplace(sConvertJig,#$25,#$0d , [rfReplaceAll]);
  SEND_MESG2HOST(DefGmes.MES_EICR,sConvertSerial,sConvertJig,nPg,bIsDelayed);  //JHHWANG-GMES: 2018-06-20
  Common.Delay(40);
end;

procedure TGmes.SendHostEijr(sSerialNo : string; nPg : Integer;bIsDelayed : Boolean = False);
var
  sConvertSerial : string;
begin
  FMesPg  := nPg;
  FEiJRSend := True;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  m_sPgSerial[nPg] := sConvertSerial;
  SEND_MESG2HOST(DefGmes.MES_EIJR,sConvertSerial,'',nPg, bIsDelayed);  //JHHWANG-GMES: 2018-06-20

//  Common.Delay(40);
end;


procedure TGmes.SendHostEqcc;
begin
  SEND_MESG2HOST(DefGmes.MES_EQCC);
end;

procedure TGmes.SendHostFldr(sMsg : string);
begin
  SEND_MESG2HOST(DefGmes.MES_FLDR, sMsg);
end;

procedure TGmes.SendHostSGEN(sSerialNo: string; nPg: Integer; bIsDelayed: Boolean = False);
var
  sConvertSerial : string;
begin
  if Length(sSerialNo) = 0 then
    Exit;
  FMesPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  m_sPgSerial[nPg] := sConvertSerial;
  SEND_MESG2HOST(DefGmes.MES_SGEN, sConvertSerial,'',nPg, bIsDelayed);
end;

procedure TGmes.SendHostPchk(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);  //JHHWANG-GMES: 2018-06-20
var
  sConvertSerial : string;
begin
  if Length(sSerialNo) = 0 then
    Exit;
  FMesPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  m_sPgSerial[nPg] := sConvertSerial;
  SEND_MESG2HOST(DefGmes.MES_PCHK,sConvertSerial,'',nPg, bIsDelayed);  //JHHWANG-GMES: 2018-06-20);
end;

procedure TGmes.SendHostLpir(sSerialNo : string; nPg : Integer; bIsDelayed : Boolean = False);
var
  sConvertSerial : string;
begin
  if Length(sSerialNo) = 0 then
    Exit;
  FMesPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  m_sPgSerial[nPg] := sConvertSerial;
  SEND_MESG2HOST(DefGmes.MES_LPIR,sConvertSerial,'',nPg, bIsDelayed);  //JHHWANG-GMES: 2018-06-20);
end;

procedure TGmes.SendHostIns_Pchk(sSerialNo: string; nPg: Integer; bIsDelayed : Boolean = False);
var
  sConvertSerial : string;
begin
  FMesPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]); // 24 -> $
  sConvertSerial := StringReplace(sConvertSerial,#$25, #$0d , [rfReplaceAll]);  // 25 -> %
  m_sPgSerial[nPg] := sConvertSerial;
  SEND_MESG2HOST(DefGmes.MES_INS_PCHK,sConvertSerial,'',nPg,bIsDelayed);  //JHHWANG-GMES: 2018-06-20);
end;

procedure TGmes.SendHostRpr_Vsir(sSerialNo: string; nPg: Integer);
var
  sConvertSerial : string;
begin
  FMesPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  SEND_MESG2HOST(DefGmes.MES_RPR_VSIR,sConvertSerial,'',nPg);  //JHHWANG-GMES: 2018-06-20);
  Common.Delay(40);
end;

procedure TGmes.SendHostStart;
begin
  if not FCanUseHost then begin
    ShowMessage('[HOST initialization failure - Confirm HOST environment setup]');
  end
  else begin
//    Common.MLog(DefCommon.MAX_SYSTEM_LOG,'<HOST> FCanUseHost is True!');
    if not fEAYT then SEND_MESG2HOST(DefGmes.MES_EAYT)
    else              SEND_MESG2HOST(DefGmes.MES_UCHK);
    //EAYT 가 처음 INITIAL 하고 테스트 하는 쪽인듯?
  end;
end;

procedure TGmes.SendHostRePn(sSerialNo: string; nPg: Integer); // Added by modong 2014-06-20 Label Print 통신 추가
var
  sConvertSerial : string;
begin
  FMesPg  := nPg;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  SEND_MESG2HOST(DefGmes.MES_REPN,sConvertSerial,'',nPg);  //JHHWANG-GMES: 2018-06-20);
//  DongaYT.Delay(40);
end;

procedure TGmes.SendHostRPr_Eijr(sSerialNo: string; nPg: Integer; bIsDelayed : Boolean = False);
var
  sConvertSerial : string;
begin
  FMesPg  := nPg;
  FEiJRSend := True;
  sConvertSerial := StringReplace(sSerialNo,#$24, #$0a, [rfReplaceAll]);
  sConvertSerial := StringReplace(sConvertSerial,#$25,#$0d , [rfReplaceAll]);
  m_sPgSerial[nPg] := sConvertSerial;
//  common.MLog(nPg,'[SendHostRPr_Eijr] : '+sConvertSerial);
  SEND_MESG2HOST(DefGmes.MES_RPR_EIJR,sConvertSerial,'',nPg,bIsDelayed);
end;

procedure TGmes.SendHostUchk;
begin
  FMesPg          := 0;
  FMesApdrPg      := 0;
  SEND_MESG2HOST(DefGmes.MES_UCHK);
end;

procedure TGmes.SendHostZset(sPid, sZigId : string);
begin
  SEND_MESG2HOST(DefGmes.MES_ZSET, sPid, sZigId);
end;

procedure TGmes.SendR2REoda(nPg, nAACK: Integer);
begin
  SEND_MESG2HOST(DefGmes.R2R_EODA,'','',nPg);
end;

procedure TGmes.SendR2REodsTest;
begin
  SEND_MESG2HOST(DefGmes.R2R_EODS,'','',1);
end;

procedure TGmes.SendR2REods;
begin
  SEND_MESG2HOST(DefGmes.R2R_EODS_R,'','',0,true);
end;

procedure TGmes.SEND_MESG2HOST(const nMsgType: Integer; sSerialNo: string; sZigId : string; nPg : Integer; bIsDelayed : Boolean); //JHHWANG-GMES: 2018-06-20
var
  sSendMsg, sOldDate    : string;
  yyyy,mm,dd, hh,nn, ss : Word;
//  nUnitId               : Integer;
  bRtn                  : Boolean;
  // for FLDR.
  sFldrFile, sFldrType    : string;
  sDownTime, sDebug  : string;
  bIsChMsg : Boolean;     //JHHWANG-GMES: 2018-06-20
begin
  //Common.Mlog(nPg, Format('[HOST] MsgType: %d, PG : %d, Serial: %s', [nMsgType, nPg, sSerialNo]));
  bIsChMsg := False;   //JHHWANG-GMES: 2018-06-20
  case nMsgType of
    DefGmes.MES_PCHK : begin
      sSendMsg := 'PCHK';
			sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      if Common.PLCInfo.InlineGIB then begin
        if FMesProsessCode = Common.SystemInfo.EQPId_MGIB_Process_Code then
          sSendMsg := sSendMsg  + ' EQP=' + Common.SystemInfo.EQPId_MGIB
        else if FMesProsessCode = Common.SystemInfo.EQPId_PGIB_Process_Code then
          sSendMsg := sSendMsg  + ' EQP=' + Common.SystemInfo.EQPId_PGIB
        else  sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      end
      else begin
			  sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      end;
      (*
      case FMesSerialType of
        0 : begin
          sSendMsg := sSendMsg  + ' FOG_ID='+sSerialNo;
          sSendMsg := sSendMsg  + ' PID=';
          sSendMsg := sSendMsg  + ' SERIAL_NO=';
        end;
        1 : begin
          sSendMsg := sSendMsg  + ' FOG_ID=';
          sSendMsg := sSendMsg  + ' PID='+sSerialNo;
          sSendMsg := sSendMsg  + ' SERIAL_NO=';
        end;
        2 : begin
          sSendMsg := sSendMsg  + ' FOG_ID=';
          sSendMsg := sSendMsg  + ' PID=';
          sSendMsg := sSendMsg  + ' SERIAL_NO='+sSerialNo;
        end;
      end;
      *)
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        sSerialNo := Trim(Copy(sSerialNo,1,Common.TestModelInfoFLOW.SerialNoFlashInfo.nLength)); // length 변경
        sSendMsg := sSendMsg  + ' PID=';
        sSendMsg := sSendMsg  + ' SERIAL_NO='+sSerialNo;
      end
      else begin
        sSerialNo := Trim(Copy(sSerialNo,1,30));
        sSendMsg := sSendMsg  + ' PID=';
        sSendMsg := sSendMsg  + ' PCB_ID='+sSerialNo;
//        sSendMsg := sSendMsg  + ' SERIAL_NO=';
      end;
      //sSendMsg := sSendMsg  + ' SERIAL_NO=';
      sSendMsg := sSendMsg  + ' COVER_GLASS_ID=';
      sSendMsg := sSendMsg  + ' LCM_ID=';
      sSendMsg := sSendMsg  + ' BLID=[]';
      sSendMsg := sSendMsg  + format(' INSPCHANEL_A=%d',[nPg]);
			sSendMsg := sSendMsg  + ' PPALLET=';
			sSendMsg := sSendMsg  + ' SKD_BOX_ID=';
			sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
			sSendMsg := sSendMsg  + ' MODE=AUTO';
			sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
			sSendMsg := sSendMsg  + ' COMMENT=[]';
      sSendMsg := sSendMsg  + ' MODEL_INFO=' + FMesModelInfo;
      //
      bIsChMsg := True;   //JHHWANG-GMES: 2018-06-20
    end;
    DefGmes.MES_LPIR : begin
      sSendMsg := 'LPIR';
			sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
			sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      (*
      case FMesSerialType of
        0 : begin
          sSendMsg := sSendMsg  + ' FOG_ID='+sSerialNo;
          sSendMsg := sSendMsg  + ' PID=';
          sSendMsg := sSendMsg  + ' SERIAL_NO=';
        end;
        1 : begin
          sSendMsg := sSendMsg  + ' FOG_ID=';
          sSendMsg := sSendMsg  + ' PID='+sSerialNo;
          sSendMsg := sSendMsg  + ' SERIAL_NO=';
        end;
        2 : begin
          sSendMsg := sSendMsg  + ' FOG_ID=';
          sSendMsg := sSendMsg  + ' PID=';
          sSendMsg := sSendMsg  + ' SERIAL_NO='+sSerialNo;
        end;
      end;
      *)
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        sSerialNo := Trim(Copy(sSerialNo,1,Common.TestModelInfoFLOW.SerialNoFlashInfo.nLength));
        sSendMsg := sSendMsg  + ' PID=';
        sSendMsg := sSendMsg  + ' SERIAL_NO='+sSerialNo;
      end
      else begin
        sSerialNo := Trim(Copy(sSerialNo,1,30));
        sSendMsg := sSendMsg  + ' PID=';
        sSendMsg := sSendMsg  + ' PCB_ID='+sSerialNo;
//        sSendMsg := sSendMsg  + ' SERIAL_NO=';
      end;
      //sSendMsg := sSendMsg  + ' SERIAL_NO=';
      sSendMsg := sSendMsg  + ' COVER_GLASS_ID=';
      sSendMsg := sSendMsg  + ' LCM_ID=';
      sSendMsg := sSendMsg  + ' BLID=[]';
      sSendMsg := sSendMsg  + format(' INSPCHANEL_A=%d',[nPg]);
			sSendMsg := sSendMsg  + ' PPALLET=';
			sSendMsg := sSendMsg  + ' SKD_BOX_ID=';
			sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
			sSendMsg := sSendMsg  + ' MODE=AUTO';
			sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
			sSendMsg := sSendMsg  + ' COMMENT=[]';
      sSendMsg := sSendMsg  + ' MODEL_INFO=' + FMesModelInfo;
      //
      bIsChMsg := True;   //JHHWANG-GMES: 2018-06-20
    end;
    DefGmes.MES_INS_PCHK : begin
      sSendMsg := 'INS_PCHK';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      if Common.PLCInfo.InlineGIB then begin
        if FMesProsessCode = Common.SystemInfo.EQPId_MGIB_Process_Code then
          sSendMsg := sSendMsg  + ' EQP=' + Common.SystemInfo.EQPId_MGIB
        else if FMesProsessCode = Common.SystemInfo.EQPId_PGIB_Process_Code then
          sSendMsg := sSendMsg  + ' EQP=' + Common.SystemInfo.EQPId_PGIB
        else  sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      end
      else begin
  			sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      end;
//      case FMesSerialType of
//        0 : begin
//          sSendMsg := sSendMsg  + ' PID=';
//          sSendMsg := sSendMsg  + ' FOG_ID='+sSerialNo;
//        end;
//        1 : begin
//          sSendMsg := sSendMsg  + ' PID='+sSerialNo;
//          sSendMsg := sSendMsg  + ' FOG_ID=';
//        end;
//      end;
      //sSendMsg := sSendMsg  + ' SERIAL_NO=';
//      sSendMsg := sSendMsg  + ' PID=';
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        sSerialNo := Trim(Copy(sSerialNo,1,Common.TestModelInfoFLOW.SerialNoFlashInfo.nLength)); // length 변경
        sSendMsg := sSendMsg  + ' PID=';
        sSendMsg := sSendMsg  + ' SERIAL_NO='+sSerialNo;
      end
      else begin
//        sSerialNo := Trim(Copy(sSerialNo,0,30));
        sSendMsg := sSendMsg  + ' PID=';
        sSendMsg := sSendMsg  + ' PCB_ID=' + sSerialNo;
//        sSendMsg := sSendMsg  + ' SERIAL_NO=';
      end;
      sSendMsg := sSendMsg  + ' LCM_ID=';
			sSendMsg := sSendMsg  + ' BLID=[]';
      sSendMsg := sSendMsg  + ' COVER_GLASS_ID=';
      sSendMsg := sSendMsg  + ' ZIG_ID=';
      sSendMsg := sSendMsg  + ' PCB_ID=';
      sSendMsg := sSendMsg  + format(' INSPCHANEL_A=%d',[nPg]);
			sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
			sSendMsg := sSendMsg  + ' MODE=AUTO';
			sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
			sSendMsg := sSendMsg  + ' COMMENT=[]';
      sSendMsg := sSendMsg  + ' MODEL_INFO=' + FMesModelInfo;
      //
      bIsChMsg := True;   //JHHWANG-GMES: 2018-06-20
    end;
    DefGmes.MES_EAYT : begin
    // 장비 ID 등록
      sSendMsg := 'EAYT';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      sSendMsg := sSendMsg  + ' NET_IP=' + Common.SystemInfo.LocalIP_GMES + ' NET_PORT=' + m_sServicePort;//' NET_IP=' + GetLocalIP + ' NET_PORT=' + m_sServicePort;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
    end;
    DefGmes.MES_UCHK : begin
    // USER ID 등록 -> RETURN으로 USER NAME RECEIVE
      sSendMsg := 'UCHK';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
    end;
    DefGmes.MES_SGEN : begin
    // Serial No Generate
    //SGEN ADDR=M2.G3.EQP.MOD.172_23_23_23,M2.G3.EQP.MOD.172_23_23_23 EQP=3AIPKA10 PID=6MC44DD16GBB3 SERIAL_NO= FOG_ID= LCM_ID= REPRINT_FLAG=N PRT_MAKER=ZEBRA PRT_RESOLUTION=600 PRT_QTY=1 PRT_MARGIN_H=0 PRT_MARGIN_V=0 LABEL_ROTATION_FLAG=N  USER_ID=1589456 MODE=AUTO CLIENT_DATE=20070910010101
      sSendMsg := 'SGEN';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      sSendMsg := sSendMsg  + ' PID=' + sSerialNo;
      //sSendMsg := sSendMsg  + ' SERIAL_NO=' + sSerialNo;
      sSendMsg := sSendMsg  + ' PRT_MAKER=ZEBRA';
      sSendMsg := sSendMsg  + ' PRT_RESOLUTION=600';
      sSendMsg := sSendMsg  + ' PRT_QTY=1';
      sSendMsg := sSendMsg  + ' LABEL_ROTATION_FLAG=N';
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
    end;
    DefGmes.MES_EDTI : begin
      sOldDate := FormatDateTime('yyyymmddhhnnss', Now);
      // Make Host data.
      yyyy := StrToInt(Copy(FHost_Date,1,4));
      mm := StrToInt(Copy(FHost_Date,5,2));
      dd := StrToInt(Copy(FHost_Date,7,2));
      hh := StrToInt(Copy(FHost_Date,9,2));
      nn := StrToInt(Copy(FHost_Date,11,2));
      ss := StrToInt(Copy(FHost_Date,13,2));
      SetDateTime(yyyy,mm,dd,hh,nn,ss,0);

      sSendMsg := 'EDTI' ;
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
      sSendMsg := sSendMsg  + ' OLD_DATE=' + sOldDate;
      sSendMsg := sSendMsg  + ' NEW_DATE=' + FormatDateTime('yyyymmddhhnnss', Now) ;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
    end;
    DefGmes.MES_FLDR : begin
      if sSerialNo = 'COMBI' then begin
        sFldrFile := m_sCombiDownFile;
        sFldrType := 'DEFECT';
        sDownTime := m_sCombiDownDate;
      end
      else if sSerialNo = 'DEFECT' then begin
        sFldrFile := m_sDefectDownFile;
        sFldrType := 'DEFECT';
        sDownTime := m_sDefectDownDate;
      end
      else if sSerialNo = 'FULL_DEFECT' then begin
        sFldrFile := m_sFullDefectDownFile;
        sFldrType := 'DEFECT';
        sDownTime := m_sFullDefectDownDate;
      end
      else if sSerialNo = 'REPAIR' then begin
        sFldrFile := m_sRepairDownFile;
        sFldrType := 'DEFECT';
        sDownTime := m_sRepairDownDate;
      end
      else begin
        sFldrFile := m_sFullRepairDownFile;
        sFldrType := 'DEFECT';
        sDownTime := m_sFullRepairDownDate;
      end;
      sSendMsg := 'FLDR';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      sSendMsg := sSendMsg  + ' FILE_NAME=[' + sFldrFile + ']';
      sSendMsg := sSendMsg  + ' FILE_TYPE=' + sFldrType;
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' DOWNLOAD_TIME=' + sDownTime;
      sSendMsg := sSendMsg  + ' CLIENT_DATE=' + FormatDateTime('yyyymmddhhnnss', Now);
      sSendMsg := sSendMsg  + ' COMMENT=[]';
    end;
    DefGmes.MES_EQCC : begin
      sSendMsg := 'EQCC';
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
    end;
// Optic.
//EICR ADDR=HM.G3.EQP.MOD.10.119.205.78,HM.G3.EQP.MOD.10.119.205.78
//EQP=HMAMAL23KA01 PID= FOG_ID=6HE83DD15DACG-503S45V223 SERIAL_NO= CGID= BLID=[] JIG_ID=[VH2FH0303394_5]
//LOT= PF=P RWK_CD= PPALLET= EXPECTED_RWK= PATTERN_INFO=[] DEFECT_PATTERN= OVERHAUL_FALG= MODE=AUTO
//CLIENT_DATE=20180523061638 USER_ID=602462 COMMENT=[]
//06:16:38.454 [RECV] EICR_R ADDR=HM.G3.EQP.MOD.10.119.205.78,HM.G3.EQP.MOD.10.119.205.78  EQP=HMAMAL23KA01 PID= FOG_ID=6HE83DD15DACG-503S45V223 SERIAL_NO= CGID= BLID=[] JIG_ID=[VH2FH0303394_5] LOT= PF=P RWK_CD= PPALLET= EXPECTED_RWK= PATTERN_INFO=[] DEFECT_PATTERN= OVERHAUL_FALG= MODE=AUTO CLIENT_DATE=20180523061638 USER_ID=602462 COMMENT=[] RTN_CD=0 ERR_MSG_LOC=[] ERR_MSG_ENG=[] HOST_DATE=20180523061639  RTN_BOX_ID= BOX_MAX_QTY=0 BOX_IN_QTY=0 CLOSE_FLAG= LABEL_PRT_CODE=[] USD=[]
//06:16:38.454 [SEND]
    DefGmes.MES_EICR : begin
      //Common.Mlog(nPg, Format('[HOST] EICR MsgType: %d, PG : %d, Serial: %s', [nMsgType, nPg, sSerialNo]));
      sSendMsg := 'EICR';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      {*
      case FMesSerialType of
        0 : begin
          sSendMsg := sSendMsg  + ' PID=';
          sSendMsg := sSendMsg  + ' FOG_ID='+sSerialNo;
        end;
        1 : begin
          sSendMsg := sSendMsg  + ' PID='+sSerialNo;
          sSendMsg := sSendMsg  + ' FOG_ID=';
        end;
      end;
      *
      }
      //sSendMsg := sSendMsg  + ' SERIAL_NO=';
      if Common.SystemInfo.OCType = DefCommon.OCType then begin
        sSendMsg := sSendMsg  + ' SERIAL_NO='+sSerialNo;
      end
      else begin
        sSendMsg := sSendMsg  + ' PID=';
        sSendMsg := sSendMsg  + ' PCB_ID='+sSerialNo;
      end;
      sSendMsg := sSendMsg  + ' CGID=';

      sSendMsg := sSendMsg  + ' BLID=[]';
      sSendMsg := sSendMsg  + ' JIG_ID=[]';   //TBD
      sSendMsg := sSendMsg  + format(' INSPCHANEL_A=%d',[nPg]);
      sSendMsg := sSendMsg  + ' LOT='+ MesData[FMesPg].LotNo;  //TBD
      // PF가 없는 경우가 있어 방어 코드.
      if Trim(MesData[FMesPg].Pf) = '' then begin
        if MesData[FMesPg].Rwk = '' then MesData[FMesPg].Pf := 'P'
        else                             MesData[FMesPg].Pf := 'F'
      end;
      sSendMsg := sSendMsg  + ' PF='+ MesData[FMesPg].Pf;
      sSendMsg := sSendMsg  + ' RWK_CD='+ MesData[FMesPg].Rwk; //TBD
      sSendMsg := sSendMsg  + ' PPALLET=';
      sSendMsg := sSendMsg  + ' EXPECTED_RWK=';
      sSendMsg := sSendMsg  + ' PATTERN_INFO=[]';
      sSendMsg := sSendMsg  + ' DEFECT_PATTERN=';
      sSendMsg := sSendMsg  + ' OVERHAUL_FLAG=';
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
      sSendMsg := sSendMsg  + ' TACT=' + MesData[FMesPg].Tact; //2021-09-17
      sSendMsg := sSendMsg  + ' USER_ID='+ FUserId;
      sSendMsg := sSendMsg  + ' COMMENT=[]';
      bIsChMsg := True;   //JHHWANG-GMES: 2018-06-20
    end;

    DefGmes.MES_EIJR : begin
      sSendMsg := 'EIJR';
			sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
			sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
//      if Length(sSerialNo) = 46 then begin
//        sSendMsg := sSendMsg  + ' PID=' ;
//        sSendMsg := sSendMsg  + ' SERIAL_NO='+ sSerialNo;
//      end
//      else begin
//        sSendMsg := sSendMsg  + ' PID=' + sSerialNo;
//        sSendMsg := sSendMsg  + ' SERIAL_NO=';
//      end;
      sSendMsg := sSendMsg  + ' SERIAL_NO='+ sSerialNo;
			sSendMsg := sSendMsg  + ' LCM_ID=';
			sSendMsg := sSendMsg  + ' FOG_ID=';
			sSendMsg := sSendMsg  + ' BLID=[]';
			if  MesData[FMesPg].Rwk = '' then begin
				sSendMsg := sSendMsg  + ' SUBJUDGE_INFO=[TOUCH:P]';
			end
			else begin
				sSendMsg := sSendMsg  + ' SUBJUDGE_INFO=[TOUCH:F:' + MesData[FMesPg].Rwk + ']';
			end;
      // PF가 없는 경우가 있어 방어 코드.
      if Trim(MesData[FMesPg].Pf) = '' then begin
        if MesData[FMesPg].Rwk = '' then MesData[FMesPg].Pf := 'P'
        else                             MesData[FMesPg].Pf := 'F';
      end;
			sSendMsg := sSendMsg  + ' PF='+ MesData[FMesPg].Pf;
			sSendMsg := sSendMsg  + ' PPALLET=';
			sSendMsg := sSendMsg  + ' EDID=N';
			sSendMsg := sSendMsg  + ' OVERHAUL_FLAG=';
			sSendMsg := sSendMsg  + ' MODE=AUTO';
			sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
      sSendMsg := sSendMsg  + ' TACT=' + MesData[FMesPg].Tact;
			sSendMsg := sSendMsg  + ' USER_ID='+ FUserId;
			sSendMsg := sSendMsg  + ' COMMENT=[]';
      bIsChMsg := True;   //JHHWANG-GMES: 2018-06-20
    end;
    DefGmes.MES_RPR_EIJR : begin
//      Common.MLog(nPg,'SEND_MESG2HOST2 : ' + sSerialNo);
      sSendMsg := 'RPR_EIJR';
			sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      if Common.PLCInfo.InlineGIB then begin
        if FMesProsessCode = Common.SystemInfo.EQPId_MGIB_Process_Code then
          sSendMsg := sSendMsg  + ' EQP=' + Common.SystemInfo.EQPId_MGIB
        else if FMesProsessCode = Common.SystemInfo.EQPId_PGIB_Process_Code then
          sSendMsg := sSendMsg  + ' EQP=' + Common.SystemInfo.EQPId_PGIB
        else  sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      end
      else begin
  			sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      end;
      sSendMsg := sSendMsg  + ' PID=';
      sSendMsg := sSendMsg  + ' SERIAL_NO='+ sSerialNo;
      //sSendMsg := sSendMsg  + ' FOG_ID=' + sSerialNo;
      sSendMsg := sSendMsg  + ' FOG_ID=';
			sSendMsg := sSendMsg  + ' LCM_ID=';
      sSendMsg := sSendMsg  + ' CGID=';
      sSendMsg := sSendMsg  + ' ZIG_ID=';
      sSendMsg := sSendMsg  + ' PCB_ID=';
      sSendMsg := sSendMsg  + format(' INSPCHANEL_A=%d',[nPg]);
      // PF가 없는 경우가 있어 방어 코드.
      if Trim(MesData[FMesPg].Pf) = '' then begin
        if MesData[FMesPg].Rwk = '' then MesData[FMesPg].Pf := 'P'
        else                             MesData[FMesPg].Pf := 'F';
      end;
      (*
			if  MesData[FMesPg].Rwk = '' then begin
				sSendMsg := sSendMsg  + ' SUBJUDGE_INFO=[GB:P:]';
			end
			else begin
				sSendMsg := sSendMsg  + ' SUBJUDGE_INFO=[GB:F:' + MesData[FMesPg].Rwk + ']';
			end;
      *)
      if  MesData[FMesPg].Rwk = '' then begin
				sSendMsg := sSendMsg  + ' SUBJUDGE_INFO=[GB:P:]';
			end
			else begin
				sSendMsg := sSendMsg  + ' SUBJUDGE_INFO=[GB:F:' + MesData[FMesPg].Rwk + ']';
			end;

      sSendMsg := sSendMsg  + ' USER_ID='+ FUserId;
			sSendMsg := sSendMsg  + ' MODE=AUTO';
			sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
			sSendMsg := sSendMsg  + ' COMMENT=[]';
      bIsChMsg := True;
//      Common.MLog(nPg,'SEND_MESG2HOST2 : Send Msg :  ' + sSendMsg);
    end;
    DefGmes.MES_ZSET : begin
      sSendMsg := 'ZSET';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' PID=' + sSerialNo;
      sSendMsg := sSendMsg  + ' ZIG_ID=' + sZigID;
      sSendMsg := sSendMsg  + ' ACT_FLAG=A';
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' COMMENT=[]';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
      bIsChMsg := False;   //JHHWANG-GMES: 2018-06-20
    end;
    DefGmes.MES_APDR : begin
      sSendMsg := 'APDR';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sLocal + ',' + m_sLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      if Common.SystemInfo.OCType = DefCommon.OCType then
        sSendMsg := sSendMsg  + ' SERIAL_NO='+ sSerialNo
      else sSendMsg := sSendMsg  + ' PCB_ID='+ sSerialNo;
      //sSendMsg := sSendMsg  + ' FOG_ID='+sSerialNo;
      sSendMsg := sSendMsg  + format(' INSPCHANEL_A=%d',[nPg]);
      sSendMsg := sSendMsg  + ' MODEL='+MesData[FMesApdrPg].Model;

      sSendMsg := sSendMsg  + ' APD_INFO=['+ MesData[FMesApdrPg].ApdrData+']';
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
      sSendMsg := sSendMsg  + ' COMMENT=[]';
      bIsChMsg := True;
//      Common.MLog(nPg,'SEND_MESG2HOST2 : Send Msg :  ' + sSendMsg);
    end;
    DefGmes.EAS_APDR : begin
      //Common.Mlog(nPg, Format('[HOST] EAS_APDR MsgType: %d, PG : %d, Serial: %s', [nMsgType, nPg, sSerialNo]));
      sSendMsg := 'APDR';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sEasLocal + ',' + m_sEasLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      if Common.SystemInfo.OCType = DefCommon.OCType then
        sSendMsg := sSendMsg  + ' SERIAL_NO='+ sSerialNo
      else sSendMsg := sSendMsg  + ' PCB_ID='+ sSerialNo;
      //sSendMsg := sSendMsg  + ' FOG_ID='+sSerialNo;
      sSendMsg := sSendMsg  + format(' INSPCHANEL_A=%d',[nPg]);
      //sSendMsg := sSendMsg  + ' MODEL='+MesData[FMesApdrPg].Model; //' MODEL=LH542WF1-EDA1-VM1-S';

      sSendMsg := sSendMsg  + ' APD_INFO=['+ MesData[FMesApdrPg].ApdrData+']';
      sSendMsg := sSendMsg  + ' USER_ID=' + FUserId ;
      sSendMsg := sSendMsg  + ' MODE=AUTO';
      sSendMsg := sSendMsg  + ' CLIENT_DATE='+FormatDateTime('yyyymmddhhnnss', Now);
      sSendMsg := sSendMsg  + ' COMMENT=[]';
      sSendMsg := sSendMsg  + ' START_TIME='+FormatDateTime('yyyymmddhhnnss', PasScr[nPg].TestInfo.StartTime);
      sSendMsg := sSendMsg  + ' END_TIME='+FormatDateTime('yyyymmddhhnnss', PasScr[nPg].TestInfo.EndTime);
      bIsChMsg := True;
      Common.MLog(nPg,'SEND_MESG2HOST2 : Send Msg :  ' + sSendMsg);
    end;
    DefGmes.R2R_EODS : begin
      sSendMsg := 'EODS';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sR2RLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;
      sSendMsg := sSendMsg  + ' UNIT=' + IntToStr(nPg +1);

      sSendMsg := sSendMsg  + ' DATAINFO=[::::[OC_W650_X#677.2256^OC_W650_Y#716.7414^OC_W650_Z#769.7799^OC_R650_X#420.4322^OC_R650_Y#192.6249^OC_R650_Z#0.3449^'
                            + 'OC_G650_X#183.3476^OC_G650_Y#553.7119^OC_G650_Z#27.5488^OC_B650_X#133.9259^OC_B650_Y#46.0480^OC_B650_Z#795.0201^MP9_W650_L#730.1678^'
                            +  'MP9_W650_X#0.3120^MP9_W650_Y#0.3309^MP9_R650_L#195.1299^MP9_R650_X#0.6853^MP9_R650_Y#0.3142^MP9_G650_L#564.8961^MP9_G650_X#0.2401^'
                            + 'MP9_G650_Y#0.7239^MP9_B650_L#47.1118^MP9_B650_X#0.1373^MP9_B650_Y#0.0472]]';
      sSendMsg := sSendMsg  + ' MMC_TXN_ID=20200705060026387HNAMAL42IB16';
      bIsChMsg := True;


    end;

    DefGmes.R2R_EODS_R : begin
      sSendMsg := 'EODS_R';
      sSendMsg := sSendMsg  + ' ADDR=' + m_sR2RLocal;
      sSendMsg := sSendMsg  + ' EQP=' + FSystemNo;

      sSendMsg := sSendMsg  + ' MMC_TXN_ID=' + FR2RMmcTxnID;
      bIsChMsg := True;
    end;
  end;
  if FCanUseHost then begin

    if MesData[nPg].MesSentMsg <> MES_UNKNOWN then begin
      Common.Mlog(nPg, Format('[HOST] MES_UNKNOWN MsgType: %d, PG : %d, Serial: %s', [nMsgType, nPg, sSerialNo]));
      // 2018-06-28:OPTIC:BCR Retry하면서 2번 보내는 경우 2번쨰 무시하기 위함
      Exit;
    end;
    if (not bIsDelayed) and IsMesWaiting(bIsChMsg,nPg) then begin  //JHHWANG-GMES 2018-06-20
      if bIsChMsg then begin
        if (nPg >= DefCommon.CH1) and (nPg <= DefCommon.MAX_CH) then begin
          MesData[nPg].MesPendingMsg := nMsgType;
          MesData[nPg].MesSentMsg := MES_UNKNOWN;
          MesData[nPg].SerialNo := sSerialNo;
          MesData[nPg].CarrierId := sZigId;
          MesData[nPg].MesSendRcvWaitTick := 0;   //  1 tick = 100 msec
          if not tmGmesChMsg.Enabled then begin
             tmGmesChMsg.Enabled := True;
          end;
        end;
      end;
      Exit;
    end;
{$IFDEF WIN32}
    if bIsChMsg then begin  //JHHWANG-GMES 2018-06-20
      if nMsgType <> DefGmes.EAS_APDR then begin
        MesData[nPg].MesSentMsg := nMsgType;
        MesData[nPg].MesPendingMsg := MES_UNKNOWN;
      end
      else begin
        //EAS APDR은 전송하고 응답을 기다리지 않는다.
        MesData[nPg].MesSentMsg := MES_UNKNOWN;
        MesData[nPg].MesPendingMsg := MES_UNKNOWN;
      end;
      MesData[nPg].SerialNo := sSerialNo;
      MesData[nPg].CarrierId := sZigId;
      MesData[nPg].MesSendRcvWaitTick := 0;   //  1 tick = 100 msec
      if not tmGmesChMsg.Enabled then begin
        tmGmesChMsg.Enabled := True;
      end;
      //sDebug := Format('TGmes.OnGmesChMsgTimer:PG(%d): ...sent',[nPg]); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
    end;
    if nMsgType <> DefGmes.EAS_APDR then begin
      bRtn := mesCommTibRv.MessageSend(sSendMsg, m_sRemote);
    end
    else begin
      {$IFDEF EAS_USE}
      bRtn := easCommTibRv.MessageSend(sSendMsg, m_sEasRemote);
      {$ENDIF}
    end;

    if bIsChMsg then begin
      sDebug := sSendMsg;
      if Length(sSendMsg) > 500 then begin
        sDebug := Copy(sSendMsg,1,500);
      end;
      case nMsgType of
        DefGmes.EAS_APDR : sDebug := 'EAS SEND :  ' + sDebug
        else               sDebug := 'MES SEND :  ' + sDebug;
      end;
      Common.MLog(nPg,sDebug);
    end;
{$ENDIF}


{$IFDEF WIN64}
    if bIsChMsg then begin  //JHHWANG-GMES 2018-06-20

      if (nMsgType <> DefGmes.EAS_APDR) and (nMsgType <> DefGmes.R2R_EODS_R) and (nMsgType <> DefGmes.R2R_EODA) then begin
        MesData[nPg].MesSentMsg := nMsgType;
        MesData[nPg].MesPendingMsg := MES_UNKNOWN;
      end
      else begin
        //EAS APDR은 전송하고 응답을 기다리지 않는다.
        MesData[nPg].MesSentMsg := MES_UNKNOWN;
        MesData[nPg].MesPendingMsg := MES_UNKNOWN;
      end;
      MesData[nPg].SerialNo := sSerialNo;
      MesData[nPg].CarrierId := sZigId;
      MesData[nPg].MesSendRcvWaitTick := 0;   //  1 tick = 100 msec
      if not tmGmesChMsg.Enabled then begin
        tmGmesChMsg.Enabled := True;
      end;
      //sDebug := Format('TGmes.OnGmesChMsgTimer:PG(%d): ...sent',[nPg]); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug); //IMSI
    end;
    if (nMsgType = DefGmes.R2R_EODS) or (nMsgType = DefGmes.R2R_EODS_R) or(nMsgType = DefGmes.R2R_EODA)   then
      bRtn := CommTibRv.Send_Data(TIBServer_R2R,sSendMsg)
    else if nMsgType <> DefGmes.EAS_APDR then begin
      bRtn := CommTibRv.Send_Data(TIBServer_MES,sSendMsg);
    end
    else begin
      {$IFDEF EAS_USE}
      bRtn := CommTibRv.Send_Data(TIBServer_EAS,sSendMsg);
      {$ENDIF}
    end;

    if bIsChMsg then begin
      sDebug := sSendMsg;
      if Length(sSendMsg) > 500 then begin
        sDebug := Copy(sSendMsg,1,500);
      end;
      case nMsgType of
        DefGmes.EAS_APDR : sDebug := 'EAS SEND :  ' + sDebug
        else               sDebug := 'MES SEND :  ' + sDebug;
      end;
      Common.MLog(nPg,sDebug);
    end;
{$ENDIF}
    if bIsChMsg then begin  //JHHWANG-GMES 2018-06-20
      if (nMsgType <> DefGmes.EAS_APDR) and (nMsgType <> DefGmes.R2R_EODS_R) and (nMsgType <> DefGmes.R2R_EODA) then begin
        MesData[nPg].MesSentMsg := nMsgType;
        MesData[nPg].MesPendingMsg := MES_UNKNOWN;
      end
      else begin
        //EAS APDR은 전송하고 응답을 기다리지 않는다.
        MesData[nPg].MesSentMsg := MES_UNKNOWN;
        MesData[nPg].MesPendingMsg := MES_UNKNOWN;
        //ReturnDataToTestForm(DefGmes.EAS_APDR, nPg, False, APDR_OK_MSG);
      end;
      MesData[nPg].SerialNo := sSerialNo;
      MesData[nPg].CarrierId := sZigId;
      MesData[nPg].MesSendRcvWaitTick := 0;   //  1 tick = 100 msec
      if not tmGmesChMsg.Enabled then begin
        tmGmesChMsg.Enabled := True;
      end;
    end;
//    else begin
//      m_MesPendingMsg := nMsgType;
//    end;
  end
  else begin
    Common.Mlog(nPg, Format('[HOST] Can not USE Host MsgType: %d, PG : %d, Serial: %s', [nMsgType, nPg, sSerialNo]));
    bRtn := False;
  end;

(*
  sDebug := StringReplace(sSendMsg,#$0a, #$24, [rfReplaceAll]);
  sDebug := StringReplace(sDebug,#$0d, #$25, [rfReplaceAll]);
  Common.Mlog(nPg, Format('[HOST] Send Msg: %s PG : %d', [sDebug, FMesPg]));
*)

//  Common.Mlog(Format('[HOST] Send Msg: %s PG : %d', [sDebug, FMesPg]));
//
  if not bRtn then begin
    //TBD
    if not tmGmesChMsg.Enabled then begin
      tmGmesChMsg.Enabled := True;
    end;
//    Common.Mlog('<HOST> CommTibRv.MessageSend MSG... ERROR!');
  end;
end;


function PosEx(const SubStr, Str: string; Offset: Integer = 1): Integer;
var
  I, L1, L2,j: Integer;
  Found: Boolean;
begin
  L1 := Length(Str);
  L2 := Length(SubStr);
  Found := False;
  if (L2 = 0) or (Offset < 1) or (Offset > L1) then
    Exit(0);
  for I := Offset to L1 - L2 + 1 do
  begin
    if Str[I] = SubStr[1] then
    begin
      Found := True;
      for  J := 2 to L2 do
        if Str[I + J - 1] <> SubStr[J] then
        begin
          Found := False;
          Break;
        end;
      if Found then
        Exit(I);
    end;
  end;
  Result := 0;
end;


function TGmes.SplitString(const AInput: string; ADelimiter: Char): TArray<string>;
var
  StartIdx, EndIdx: Integer;
begin
  SetLength(Result, 0);
  StartIdx := 1;
  EndIdx := Pos(ADelimiter, AInput);
  while EndIdx > 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Copy(AInput, StartIdx, EndIdx - StartIdx);
    StartIdx := EndIdx + 1;
    EndIdx := PosEx(ADelimiter, AInput, StartIdx);
  end;
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := Copy(AInput, StartIdx, Length(AInput) - StartIdx + 1);
end;

function SplitStringToKeyValue(const AInput: string; ADelimiter: Char): TArray<TKeyValue>;
var
  StartIdx, EndIdx: Integer;
begin
  SetLength(Result, 0);
  StartIdx := 1;
  EndIdx := Pos(ADelimiter, AInput);
  while EndIdx > 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Key := Copy(AInput, StartIdx, EndIdx - StartIdx);
    StartIdx := EndIdx + 1;
    EndIdx := PosEx(ADelimiter, AInput, StartIdx);
  end;
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)].Key := Copy(AInput, StartIdx, Length(AInput) - StartIdx + 1);
end;





function TGmes.ExtractOCValues(const AInput: string): TDictionary<string, string>;
var
  KeyValues: TArray<string>;
  KeyValue: string;
  Key, Value: string;
begin
  Result := TDictionary<string, string>.Create;
  KeyValues := SplitString(AInput, '^');
  for KeyValue in KeyValues do
  begin
    if Pos('OC_', KeyValue) > 0 then
    begin
      Key := Copy(KeyValue, Pos('OC_', KeyValue) + Length('OC_'), Pos('#', KeyValue) - Pos('OC_', KeyValue) - Length('OC_'));
      Value := Copy(KeyValue, Pos('#', KeyValue) + 1, Length(KeyValue) - Pos('#', KeyValue) - 1);
      Result.Add(Key, Value);
    end;
  end;
end;


procedure TGmes.SeperateR2RData(sMsg: string);
var
  i : integer;
  Key: string;
  Value: string;
  Dict: TDictionary<string, string>;
begin
  Dict := ExtractOCValues(sMsg);  // 문자열을 분할하여 TDictionary<string, string> 유형의 배열로 변환

  for i := 0 to Dict.Count - 1 do
  begin
    FR2ROC_EODSname[i] := Dict.Keys.ToArray[i];
    FR2ROC_EODSData[i] := Dict.Values.ToArray[i];
  end;

end;

procedure TGmes.SeperateData(sMsg: string; var nChNo : Integer);
var
  nSpacePos, nEqPos               : Integer;
  sMsgId,sMsgCont, sNext, sMode   : string;// AnsiString;
  sSubMsg, sChRet                 : string; //WideString;
begin
  sMode := Copy(sMsg,1,6);
  sSubMsg := trim(Copy(sMsg,7,Length(sMsg)-6));
  nEqPos := pos('=',sSubMsg);
  nSpacePos := pos(' ',sSubMsg);
  nChNo := -1;  sChRet := '';
  repeat
    sMsgId := Copy(sSubMsg,1,nEqPos-1);
    sMsgCont := Copy(sSubMsg,nEqPos+1,nSpacePos-nEqPos-1);
    sSubMsg := trim(Copy(sSubMsg,Length(sMsgCont) + 2 + Length(sMsgId) ,Length(sSubMsg)-Length(sMsgCont)-1 - Length(sMsgId)));
    nEqPos := pos('=',sSubMsg);
    if nEqPos = 0 then sMsgCont := sMsgCont +' '+ sSubMsg;
    nSpacePos := pos(' ',sSubMsg);
    while (nEqPos > nSpacePos) and (nSpacePos > 0) do begin
      sNext := Copy(sSubMsg,1,nSpacePos-1);
      sMsgCont := sMsgCont +' '+ sNext;
      sSubMsg := Copy(sSubMsg,Length(sNext)+2,Length(sSubMsg)-Length(sNext));
      nEqPos := pos('=',sSubMsg);
      nSpacePos := pos(' ',sSubMsg);
    end;
    if      Uppercase(string(sMsgId))= 'RTN_CD'         then FMesRtnCd        := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'PID'            then FMesPid          := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'RTN_PID'        then FMesRtnPID       := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'RTN_SERIAL_NO'  then FMesSerialNo     := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'LABEL_ID'       then FMesLabelID      := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'PF'             then FMesPf           := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'USER_NAME'      then FMesUserName     := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'RTN_LOT'        then m_sLotNo         := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'HOST_DATE'      then FHost_Date       := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'ERR_MSG_LOC'    then FMesErrMsgLc     := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'ERR_MSG_ENG'    then FMesErrMsgEn     := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'MODEL'          then FMesModel     		:= Trim(string(sMsgCont))
    else if UpperCase(string(sMsgId))= 'INSPCHANEL_A'   then sChRet           := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'FOG_ID'         then FMesFogId     		:= Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'SERIAL_NO'      then FMesFogId     		:= Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'UNIT'           then FR2RUnit         := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'MMC_TXN_ID'     then FR2RMmcTxnID     := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'DATAINFO'       then FR2RDatainfo     := Trim(string(sMsgCont))
    else if Uppercase(string(sMsgId))= 'PROCESS_CODE'   then FMesProsessCode  := Trim(string(sMsgCont)) //LPIR 추가m-GIB p-GIB 구분 코드

    //    else if CompareStr(Uppercase(sMsgId), 'RWK_PID')  = 0     then begin
//      RtnLotID[StrToInt(m_sGetUID)-1]       := sMsgCont;
//    end
    ;
  Until nEqPos = 0 ;
  if sChRet <> '' then begin
    nChNo := StrToIntDef(sChRet, -1);
  end;
  // 영어 Error Message가 정상적으로 뜨지 않아 수동으로 재정리.
  nEqPos := Pos('ERR_MSG_ENG',sMsg)+1+Length('ERR_MSG_ENG');
  if nEqPos <> 0 then begin
    sSubMsg := Copy(sMsg,nEqPos,Length(sMsg)-nEqPos);
    nSpacePos := Pos(']', sSubMsg);
    FMesErrMsgEn := Copy(sSubMsg,2,nSpacePos-2);
  end
  else
    FMesErrMsgEn := '';
  FMesErrMsgEn := StringReplace(FMesErrMsgEn,'[','', [rfReplaceAll]);
  FMesErrMsgEn := StringReplace(FMesErrMsgEn,']','', [rfReplaceAll]);
  FMesErrMsgLc := StringReplace(FMesErrMsgLc,'[','', [rfReplaceAll]);
  FMesErrMsgLc := StringReplace(FMesErrMsgLc,']','', [rfReplaceAll]);
end;


procedure TGmes.SetDateTime(Year, Month, Day, Hour, Minu, Sec, MSec: Word);
var
  NewDateTime: TSystemTime;
begin
  try
    FillChar(NewDateTime, SizeOf(NewDateTime), #0);
    NewDateTime.wYear := Year;
    NewDateTime.wMonth := Month;
    NewDateTime.wDay := Day;
    NewDateTime.wHour := Hour;
    NewDateTime.wMinute := Minu;
    NewDateTime.wSecond := Sec;
    NewDateTime.wMilliseconds := MSec;

    SetLocalTime(NewDateTime);
  except
    OutputDebugString(PChar('Exception Error in SetDateTime()'));
  end;
end;


procedure TGmes.SetMesSerialType(const Value: Integer);
begin
  FMesSerialType := Value;
end;

//procedure TGmes.SetFTP(FTP: TIdFTP);
//begin
//  FTP.Host      := FFtpAddr;
//  FTP.Port      := 21;
//  FTP.Username  := FFtpUser;
//  FTP.Password  := FFtpPass;
//  FTP.UseHOST   := False;
//  FTP.UseMLIS   := True;
//  FTP.TransferType  := ftBinary;
//  {    Dp101Ftp[i].Username    := DefPg.FTP_ID;
//    Dp101Ftp[i].Password    := DefPg.FTP_PassWd;
//    Dp101Ftp[i].Port        := DefPg.FTP_Port;
//    Dp101Ftp[i].Host        := sysinfo.PgIp[i];
//    Dp101Ftp[i].Passive     := False;
//    Dp101Ftp[i].TransferType  := ftBinary;
//    Dp101Ftp[i].ReadTimeout := 0;
//    // UseHST Default값이 True.  ==> 연결시 Connection Closed Gracefully Error 발생.
//    // UseHost는 Greeting Message를 받고 Connection을 요청하기 때문에 Greeting이 없으면 Connetion 오류 발생.
//    Dp101Ftp[i].UseHOST     := False;}
//end;




procedure TGmes.SetOnGmsEvent(const Value: TGmesEvent);
begin
  FOnGmsEvent := Value;
end;

procedure TGmes.OnGemsResponseTimer(Sender: TObject);
begin

end;

procedure TGmes.OnGmesChMsgTimer(Sender: TObject);
var
  nPg : Integer;
  bWaitResponse  : Boolean;
  bStopTimer : Boolean;
  sDebug : string;
begin
  // Check MES Timer Tick for each PG
  bWaitResponse := False;
  for nPg := DefCommon.CH1 to DefCommon.MAX_CH do begin
    //
    if MesData[nPg].MesSentMsg <> MES_UNKNOWN then begin
      Inc(MesData[nPg].MesSendRcvWaitTick);
    //
      if MesData[nPg].MesSendRcvWaitTick > 5*10 then begin  //TBD: 5sec
        if (MesData[nPg].MesSentMsg = MES_PCHK) or (MesData[nPg].MesPendingMsg = MES_PCHK) then begin
          MesData[nPg].PchkSendNg:= True;
          MesData[nPg].bPCHK     := False;
          ReturnDataToTestForm(DefGmes.MES_PCHK, nPg, False, 'PCHK_NG');
        end
        else if (MesData[nPg].MesSentMsg = MES_EICR) or (MesData[nPg].MesPendingMsg = MES_EICR) then begin
          MesData[nPg].EicrSendNg  := True;
          ReturnDataToTestForm(DefGmes.MES_EICR, nPg, False, 'EICR_NG');
        end
        else if (MesData[nPg].MesSentMsg = MES_LPIR) or (MesData[nPg].MesPendingMsg = MES_LPIR) then begin
          MesData[nPg].LpirSendNg  := True;
          MesData[nPg].bLPIR := false;
          ReturnDataToTestForm(DefGmes.MES_LPIR, nPg, False, 'LPIR_NG');
        end;
        MesData[nPg].MesSendRcvWaitTick:= 0;
        MesData[nPg].MesPendingMsg := MES_UNKNOWN;  //here!!!
        MesData[nPg].MesSentMsg    := MES_UNKNOWN;  //here!!!
        //sDebug := Format('TGmes.OnGmesChMsgTimer: PG(%d) timeout ...TBD',[nPG]); Common.MLog(DefCommon.MAX_SYSTEM_LOG,sDebug);
        Continue;
      end;
    end;
    //
    if MesData[nPg].MesSentMsg <> MES_UNKNOWN then
      bWaitResponse := True;
  end;
  if bWaitResponse then begin
    //Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TGmes.OnGmesChMsgTimer: WaitResponse ...Exit');
    Exit;
  end;

  // Send MES Message if exist
  for nPg := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if MesData[nPg].MesPendingMsg <> MES_UNKNOWN then begin
      case MesData[nPg].MesPendingMsg of
        DefGmes.MES_PCHK : begin
          SendHostPChk(MesData[nPg].SerialNo, nPg, True);
          Break;
        end;
        DefGmes.MES_EICR : begin
          SendHostEicr(MesData[nPg].SerialNo, nPg, MesData[nPg].CarrierId, True);
          Break;
        end;
        DefGmes.MES_INS_PCHK : begin
          SendHostIns_Pchk(MesData[nPg].SerialNo, nPg,True);
          Break;
        end;
        DefGmes.MES_RPR_EIJR : begin
          SendHostRPr_Eijr(MesData[nPg].SerialNo, nPg,True);
          Break;
        end;
        DefGmes.MES_APDR : begin
          SendHostApdr(MesData[nPg].SerialNo, nPg,True);
          Break;
        end;
        DefGmes.EAS_APDR : begin
          SendEasApdr(MesData[nPg].SerialNo, nPg,True);
          Break; 
        end;
      end;
    end;
  end;

  // STOP if no more MES message send/receive
  bStopTimer := True;
  for nPg := DefCommon.CH1 to DefCommon.MAX_CH do begin
    if (MesData[nPg].MesPendingMsg = MES_UNKNOWN) and (MesData[nPg].MesSentMsg = MES_UNKNOWN) then
      MesData[nPg].MesSendRcvWaitTick := 0
    else begin
      bStopTimer := False;
      Break;
    end;
  end;
  if bStopTimer then begin
    tmGmesChMsg.Enabled := False;
    //Common.MLog(DefCommon.MAX_SYSTEM_LOG,'TGmes.OnGmesChMsgTimer: STOP TImer');
  end;
end;

function TGmes.IsMesWaiting(bIsChMsg : Boolean; nThisPgNo : Integer): Boolean;    //JHHWANG-GMES: 2018-06-20
var
  nPgNo : Integer;
  nRet : Boolean;
begin
  nRet := False;

//if m_MesPendingMsg <> MES_UNKNOWN then  //TBD
//  nRet := True
//else begin
  if bIsChMsg then begin
    for nPgNo := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if {2018-06-28:GB:Bcr Read Retry에 따라 2번 발생 (nPgNo <> nThisPgNo) and} (MesData[nPgNo].MesSentMsg <> MES_UNKNOWN) then
        nRet := True;
    end;
  end;
//end;

  Result := nRet;
end;

{
procedure TGMes.SendDelayedMesMsg;  //JHHWANG-GMES 2018-06-20
var
  nPgNo : Integer;
  nMsgType : Integer;
begin
//  if m_MesPendingMsg <> MES_UNKNOWN then begin
//
//  end
//  else begin
    for nPgNo := DefCommon.CH1 to DefCommon.MAX_CH do begin
      if MesData[nPgNo].MesPendingMsg <> MES_UNKNOWN then begin
        nMsgType :=  MesData[nPgNo].MesPendingMsg;
        MesData[nPgNo].MesPendingMsg := MES_UNKNOWN;
        case nMsgType of
          DefGmes.MES_PCHK : begin
            SendHostPChk(MesData[nPgNo].SerialNo, nPgNo, True);
            Exit;
          end;
          DefGmes.MES_EICR : begin
            SendHostEicr(MesData[nPgNo].SerialNo, nPgNo, MesData[nPgNo].CarrierId, True);
            Exit;
          end;
        end;
      end;
    end;
//  end;

end;
}
end.
