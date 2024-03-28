unit CommCameraRadiant;

//{$DEFINE COMMPG_A19}

interface
uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.SyncObjs, Winapi.WinSock,
  IdGlobal, IdContext, IdSync, IdComponent, IdTCPServer, IdSocketHandle, Vcl.ExtCtrls,
  CommLightNaratech, DefCam,
{$IFDEF  COMMPG_A19}
  CommPG_A19,
{$ELSE}
//  UdpServerClient,
{$ENDIF}
  CommonClass;

const
  MAX_COUNT_CAMERA = 3;
  GUIMESSAGE_CAMREA = 500;

  MSG_MODE_CONNECT = 100;
  MSG_MODE_WORKING = MSG_MODE_CONNECT+1;
  MSG_MODE_ERROR   = MSG_MODE_CONNECT+2;
  MSG_MODE_ALARM   = MSG_MODE_CONNECT+2;

  COMMCAM_ERR_NONE      = 0;
  COMMCAM_ERR_NAK       = COMMCAM_ERR_NONE + 1;
  COMMCAM_ERR_RESULT    = COMMCAM_ERR_NONE + 2;
  COMMCAM_ERR_TIMEOUT   = COMMCAM_ERR_NONE + 3;
  COMMCAM_ERR_FLASHERASE= COMMCAM_ERR_NONE + 4;
  COMMCAM_ERR_CANCEL    = COMMCAM_ERR_NONE + 5;

  COMMCAM_ERR_SENDFAIL  = COMMCAM_ERR_NONE + 100;
  COMMCAM_ERR_EXCEPTION = COMMCAM_ERR_NONE + 101;
  COMMCAM_ERR_SIZE      = COMMCAM_ERR_NONE + 102;
  COMMCAM_ERR_CHECKSUM  = COMMCAM_ERR_NONE + 103;
  COMMCAM_ERR_CHGPTN    = COMMCAM_ERR_NONE + 104;

type

  PGuiCamData = ^RGuiCamData;
  RGuiCamData = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    nParam  : Integer;
    nParam2 : Integer;
    Msg     : string;
    Msg2    : string;
    Data    : TBytes; //Pointer;
  end;

  PCameraHeader = ^TCameraHeader;
  /// <summary> Camera 수신 명령 </summary>
  TCameraHeader = packed record
    Size     : Integer;
    Checksum : Integer;
    Data     : String;
  end;


  /// <summary> Camera 수신 데이터 저장 </summary>
  TCameraData = record
    FullSize: Integer;
    Size: Integer;
    Data: array of Byte;
  end;

  /// <summary> Camera 전송 명령 처리 정보</summary>
  TCameraCommandData = record
    Step: Integer;  //진행 Process
    Reply: Integer; //응답0=Ack, 1=Nak, 2=Wait, else=ETC
    Event: HWND; //결과 대기 이벤트
    WaitingData: Boolean; //데이터 이어받기 여부
    TemplateData: Boolean; //Template 데이터 여부
    NeedMoreCommand: Boolean; //명령 이어받기
    PID: String; //제품 번호- Start 명령에서 추출
    ErrorMsg: String; //명령 에러 문자열
    RecvData: String; //수신 데이터
    PUCVer: String; //카메라에서 받은 PUC Ver
    TrueTestVer: String; //카메라 프로그램 버전
    //Temperature: Double; //카메라 온도
    //FFCData: array [0..50] of Double; //String; //FFC 측정 수신 데이터
    //INFOName: array [0..150] of String; //INFO Name
    //INFOData: array [0..150] of Double; //INFO Data
  end;

   TCameraInfoData = record
    Temperature: Double; //카메라 온도
    FFCData: array [0..50] of Double;   //FFC 측정 수신 데이터
    INFOName: array [0..150] of String; //INFO Name
    INFOData: array [0..150] of Double; //INFO Data
    StainData: array [0..50] of String; //Stain 측정 수신 데이터
  end;

  TCameraOtpData = record
    Size : Integer;
    Data : TIdBytes;
  end;

  ///<summary>
  /// POCB 카메라(Radiant) 통신 클래스by kg.jo 20201030
  /// TCP Server로 동작, Channel 별 포트 구분
  /// 프로토콜문서: Dooone Protocol 20201023.xlsx
  ///</summary>
  TCommCamera = class (TObject)
  private
    m_hMain: HWND;
    m_nCamType : Integer;

    m_idTCPServer : array [0..MAX_COUNT_CAMERA] of TIdTCPServer;
    //m_bProcessData: array [0..MAX_COUNT_CAMERA] of Boolean;
    //m_nProcessStep: array [0..MAX_COUNT_CAMERA] of Integer;
    //m_ahProcessEvent: array [0..MAX_COUNT_CAMERA] of HWND; //TEvent;
    m_CameraData: array [0..MAX_COUNT_CAMERA] of TCameraData;
    m_nLightState : array[0 .. MAX_COUNT_CAMERA] of integer;

    procedure TCPServerExecute(AContext: TIdContext);
    procedure TCPServerConnect(AContext: TIdContext);
    procedure TCPServerDisconnect(AContext: TIdContext);
    procedure TCPServerException(AContext: TIdContext; AException: Exception);
    procedure TCPServerStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
    //procedure TCPServerListenException(AThread: TIdListenerThread; AException: Exception);
    function  GetChannelByIP(sIP: string): Integer;
    function  GetChannelByPort(nPort: Integer): Integer;

    procedure ProcessData(nCh, nReadBufferLen : Integer; AReadBuffer : TidBytes; const AContext: TIdContext);
    procedure SaveCameraData(nCh: Integer; ACameraData: TCameraData; bTemplate: Boolean=False);
    procedure Parse_FFCData(nCh: Integer; sFFCData: String);
    procedure Parse_INFOData(nCh: Integer; sINFOData: String);
    procedure CheckTimeout(nCh: Integer; nTimeout: Cardinal);
    function BufferToString(ABuffer: TIdBytes; nLimit: Integer): String;
    function CalcChecksum(nSize: Integer): Integer;
    procedure SendMessageMain(nMode: Integer; nCh, NParam, nParam2: Integer; sMsg: String);
    procedure SendMessageTest(nMode: Integer; nCh, NParam, nParam2: Integer; sMsg: String);
    function  CheckLightSourceStateAll(bAllOn: Boolean): Boolean;
    procedure tmrHearBeatTimer(Sender: TObject);
    procedure Parse_StainData(nCh: Integer; sStainData: String);

  public
    JigNo: Integer;
    m_hTest: HWND;
    /// <summary> 전송 명령 처리 정보 </summary>
    CommandData : array [0..MAX_COUNT_CAMERA] of TCameraCommandData;
    InfoData    : array [0..7] of TCameraInfoData;  //채널별 Info 데이터

    m_sSerialNo : array [0..MAX_COUNT_CAMERA] of string;
    m_nSendData : array [0..MAX_COUNT_CAMERA] of Integer;
    m_OtpData   : array [0..MAX_COUNT_CAMERA] of TCameraOtpData;
    m_tmrHeartbeat: TTimer;
    m_nTickLast: Cardinal;
    Use_Template: Boolean;

    constructor Create(hMain : THandle; nCamType, nLightType, nPort : Integer); virtual;
    destructor Destroy; override;
    /// <summary> AContext에 데이터 전송 </summary>
    function SendData(nCh: Integer; sData: string; const AContext: TIdContext): Boolean;
    /// <summary> channel에 데이터 전송 </summary>
    function SendDataByChannel(nCh: Integer; sData: string): Boolean;
    /// <summary> 모든 channel에 데이터 전송 </summary>
    function SendDataAll(sData: string): Boolean;
    /// <summary> POCB Camera에 명령 전송 </summary>
    function SendCommand(nCh: Integer; sCommand : string; nWaitTime : Integer = 3000) : Integer;
    function CancelCommand(nCh: Integer) : Integer;
    function SendBuffer(nCh: Integer; ABuffer: TIdBytes; nWaitTime : Integer = 3000) : boolean;
    function SendModel(sModelName: String): Integer;
    procedure SetBufferForOtpDataAtStartCmd(nCh, nTotalSize : Integer);
  end;

var
  CommCamera: TCommCamera;

implementation

uses pasScriptClass;

const
  BASE_CAMERA_IP = '192.168.';
  BASE_CAMERA_PORT = 2291;
  BASE_CAMERA_INDEX = 1;

  CAM_PROCESS_NONE         = 0;
  CAM_PROCESS_MODELCHG     = CAM_PROCESS_NONE + 1;
  CAM_PROCESS_PING         = CAM_PROCESS_NONE + 2;
  CAM_PROCESS_START        = CAM_PROCESS_NONE + 3;
  CAM_PROCESS_MEASURE      = CAM_PROCESS_NONE + 4;
  CAM_PROCESS_POCBGAMMA    = CAM_PROCESS_NONE + 5;
  CAM_PROCESS_FFCSTART     = CAM_PROCESS_NONE + 6;
  CAM_PROCESS_END          = CAM_PROCESS_NONE + 7;
  CAM_PROCESS_FTPUPLOAD    = CAM_PROCESS_NONE + 8;
  CAM_PROCESS_STAINSTART   = CAM_PROCESS_NONE + 9;
  CAM_PROCESS_CHANGERCB    = CAM_PROCESS_NONE + 10;
  CAM_PROCESS_AFTERSTART   = CAM_PROCESS_NONE + 11;

{ TCommCamera }

function TCommCamera.BufferToString(ABuffer: TIdBytes; nLimit: Integer): String;
var
  AItem: Byte;
begin
  Result:= '';
  for AItem in ABuffer do
  begin
    Result:= Result + Chr(AItem);
    if Result.Length > nLimit then break;
  end;
end;

function TCommCamera.CalcChecksum(nSize: Integer): Integer;
begin
  Result:= ((nSize shr 24) and $ff) + ((nSize shr 16) and $ff) +
           ((nSize shr 8) and $ff)  + (nSize and $ff);
end;



function TCommCamera.CheckLightSourceStateAll(bAllOn: Boolean): Boolean;
var
  i: integer;
begin
  Result:= True;
  if bAllOn then begin
    //전체 On 검사
    for i := 0 to 3 do begin
      if Common.StatusInfo.UseChannel[i + JigNo*4] then begin
        if (m_nLightState[i] = 0) then begin
          Result:= False;
          Exit;
        end;
      end;
    end;
  end
  else begin
    //전체 Off 검사
    for i := 0 to 3 do begin
      if Common.StatusInfo.UseChannel[i + JigNo*4] then begin
        if (m_nLightState[i] = 1) then begin
          Result:= False;
          Exit;
        end;
      end;
    end;
  end;
end;

procedure TCommCamera.CheckTimeout(nCh: Integer; nTimeout: Cardinal);
begin
  Sleep(nTimeout);
  if CommandData[nCh].WaitingData = True then begin
    //NG
    CommandData[nCh].WaitingData:= False;
    SendDataByChannel(nCh, 'NAK');
  end;
end;

constructor TCommCamera.Create(hMain: THandle;nCamType, nLightType, nPort : Integer);
var
  i: Integer;
  sTemp: String;
begin
  m_hMain := hMain;
  m_nCamType := nCamType;
  for i := 0 to MAX_COUNT_CAMERA do begin
    m_idTCPServer[i] := TIdTCPServer.Create(nil);
    m_idTCPServer[i].OnExecute := TCPServerExecute;
    m_idTCPServer[i].OnConnect:= TCPServerConnect;
    m_idTCPServer[i].OnDisconnect:= TCPServerDisconnect;
    m_idTCPServer[i].OnException:= TCPServerException;
    m_idTCPServer[i].OnStatus:= TCPServerStatus;
    m_idTCPServer[i].Bindings.Clear;
    m_idTCPServer[i].DefaultPort:= BASE_CAMERA_PORT + i;
    m_idTCPServer[i].ReuseSocket:= rsFalse;
    m_idTCPServer[i].Tag:= i;
    m_idTCPServer[i].Active:= True;

    m_nLightState[i]:= 0;  //이물조명상태  초기화

    CommandData[i].WaitingData:= False; //이어받기 아님
    CommandData[i].Step:= 0; //진행 단계 없음
    CommandData[i].Reply:= 0; //Ack
    CommandData[i].RecvData:= '';
    sTemp:= self.ClassName + IntToStr(i);
    CommandData[i].Event:= CreateEvent(nil, False, False, PChar(sTemp));

    ZeroMemory(@InfoData[i].FFCData[0], Sizeof(InfoData[i].FFCData[0]) * Length(InfoData[i].FFCData));
    ZeroMemory(@InfoData[i].INFOData[0], Sizeof(InfoData[i].INFOData[0]) * Length(InfoData[i].INFOData));
  end;

  CommLight:= TCommLight.Create(hMain,nLightType);
  CommLight.Connect(nPort);

  m_tmrHeartbeat:= TTimer.Create(nil); //PING - heartbeat
  m_tmrHeartbeat.OnTimer:= tmrHearBeatTimer;
  m_tmrHeartbeat.Interval:= 60000;
  m_tmrHeartbeat.Enabled:= False;

end;

destructor TCommCamera.Destroy;
var
  i: Integer;
begin
  CommLight.Free;
  CommLight := nil;
  m_tmrHeartbeat.Enabled:= False;
  m_tmrHeartbeat.Free;

  for i := 0 to MAX_COUNT_CAMERA do begin
    m_idTCPServer[MAX_COUNT_CAMERA- i].OnConnect:= nil;
    m_idTCPServer[MAX_COUNT_CAMERA- i].OnDisconnect:= nil;
    m_idTCPServer[MAX_COUNT_CAMERA- i].OnExecute:= nil;
    m_idTCPServer[MAX_COUNT_CAMERA- i].Active:= False;
    FreeAndNil(m_idTCPServer[MAX_COUNT_CAMERA- i]);

    CloseHandle(CommandData[MAX_COUNT_CAMERA- i].Event);
  end;

  inherited;
end;

function TCommCamera.GetChannelByIP(sIP: string): Integer;
var
  sTemp  : string;
  nCh, i: Integer;
begin
  nCh := 0;
  // 채널 검색.
  for i := 0 to MAX_COUNT_CAMERA do begin
    sTemp := BASE_CAMERA_IP + Format('%d.%d',[i+BASE_CAMERA_INDEX,i+BASE_CAMERA_INDEX]);
    if sIP = sTemp then begin
      nCh := i;
      Break;
    end;
  end;
  Result:= nCh;
end;

function TCommCamera.GetChannelByPort(nPort: Integer): Integer;
var
  nTemp: Integer;
  nCh, i: Integer;
begin
  nCh := 0;
  // 채널 검색.
  for i := 0 to MAX_COUNT_CAMERA do begin
    nTemp := BASE_CAMERA_PORT + i;
    if nPort = nTemp then begin
      nCh := i;
      Break;
    end;
  end;
  Result:= nCh;
end;

procedure TCommCamera.Parse_FFCData(nCh: Integer; sFFCData: String);
var
  asData: TArray<String>;
  i, nPos, nIndex: Integer;
  sItem, sValue: String;
  dValue: Double;
  nPgNo: Integer;
begin
  nPgNo:= nCh + JigNo*4;
  asData:= sFFCData.Split([',']);
  for i := 0 to Length(asData)-1 do begin

    nPos:= Pos(':', asData[i]);
    if nPos < 1 then begin
      //Error
      SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, format('Parse_FFCData Data format Error: index=%d:%s', [i, asData[i]]));
      Exit;
    end;
    //CommandData[nCh].FFCData[nIndex]:= asData[i];

    //데이터와 EAS 형식 상이로 값만 처리
    sItem:= copy(asData[i], 1, nPos-1);
    sValue:= copy(asData[i], nPos+1, Length(asData[i]));
    nIndex:= StrToInt(sItem[2]);
    dValue:= StrToFloat(sValue);

    //nIndex:= nIndex + ((ord(sItem[1]) - ord('A')) * 10);

    if sItem[1] = 'A' then begin
      //nIndex:= StrToInt(sItem[2]);
    end
    else if sItem[1] = 'B' then begin
      nIndex:= nIndex + 10;
    end
    else if sItem[1] = 'C' then begin
      nIndex:= nIndex + 20;
    end
    else if sItem[1] = 'D' then begin
      nIndex:= nIndex + 30;
    end
    else if sItem[1] = 'E' then begin
      nIndex:= nIndex + 40;
    end;

    InfoData[nPgNo].FFCData[nIndex]:= dValue;
  end; //for i := 0 to Length(asData) do begin
end;


procedure TCommCamera.Parse_INFOData(nCh: Integer; sINFOData: String);
var
  asData: TArray<String>;
  i: Integer;
  dValue: Double;
  nPgNo: Integer;
begin
  //INFO=DUTROTANGLE,0.09,DUTWIDTH,2502,DUTHEIGHT,5415,DUTSHIFTX,-12.5,DUTSHIFTY,-16,MTF,91.04,MTF_CENTER,90.59,MTF_UL,90.46,MTF_UR,90.88,MTF_LL,90.58,MTF_LR,91.45,KeystoneH,0.0162,KeystoneV,0.0246,
  //CCD_G216-1,0.15,CCD_G216-2,0.21,CCD_G216-3,0.04,CCD_G216-4,0.28,CCD_G216-5,0.14,CCD_G216-6,0.13,CCD_G216-7,0.19,CCD_G216-8,0.21,CCD_G216-9,0.08,CCD_G216-10,0.17,
  //CCD_G192-1,0.15,CCD_G192-2,0.23,CCD_G192-3,0.07,CCD_G192-4,0.18,CCD_G192-5,0.11,CCD_G192-6,0.13,CCD_G192-7,0.25,CCD_G192-8,0.22,CCD_G192-9,0.03,CCD_G192-10,0.09,
  //CCD_G36-1,0.69,CCD_G36-2,0.81,CCD_G36-3,0.12,CCD_G36-4,0.70,CCD_G36-5,0.21,CCD_G36-6,0.36,CCD_G36-7,0.33,CCD_G36-8,0.32,CCD_G36-9,0.05,CCD_G36-10,0.35,
  //CCD_G32-1,0.82,CCD_G32-2,0.90,CCD_G32-3,0.18,CCD_G32-4,0.79,CCD_G32-5,0.22,CCD_G32-6,0.35,CCD_G32-7,0.31,CCD_G32-8,0.36,CCD_G32-9,0.09,CCD_G32-10,0.35,
  //CCD_R216-1,0.19,CCD_R216-2,0.09,CCD_R216-3,0.10,CCD_R216-4,0.22,CCD_R216-5,0.20,CCD_R216-6,0.06,CCD_R216-7,0.26,CCD_R216-8,0.17,CCD_R216-9,0.12,CCD_R216-10,0.16,
  //CCD_R192-1,0.17,CCD_R192-2,0.09,CCD_R192-3,0.09,CCD_R192-4,0.25,CCD_R192-5,0.19,CCD_R192-6,0.02,CCD_R192-7,0.24,CCD_R192-8,0.19,CCD_R192-9,0.12,CCD_R192-10,0.17,
  //CCD_R36-1,0.05,CCD_R36-2,0.47,CCD_R36-3,0.28,CCD_R36-4,0.85,CCD_R36-5,0.25,CCD_R36-6,0.54,CCD_R36-7,0.31,CCD_R36-8,0.56,CCD_R36-9,0.16,CCD_R36-10,0.25,
  //CCD_R32-1,0.08,CCD_R32-2,0.56,CCD_R32-3,0.23,CCD_R32-4,1.03,CCD_R32-5,0.18,CCD_R32-6,0.52,CCD_R32-7,0.32,CCD_R32-8,0.64,CCD_R32-9,0.10,CCD_R32-10,0.23,
  //CCD_B216-1,0.11,CCD_B216-2,0.08,CCD_B216-3,0.18,CCD_B216-4,0.09,CCD_B216-5,0.14,CCD_B216-6,0.08,CCD_B216-7,0.11,CCD_B216-8,0.26,CCD_B216-9,0.21,CCD_B216-10,0.04,
  //CCD_B192-1,0.12,CCD_B192-2,0.15,CCD_B192-3,0.19,CCD_B192-4,0.03,CCD_B192-5,0.03,CCD_B192-6,0.11,CCD_B192-7,0.07,CCD_B192-8,0.27,CCD_B192-9,0.22,CCD_B192-10,0.04,
  //CCD_B36-1,0.63,CCD_B36-2,0.34,CCD_B36-3,0.35,CCD_B36-4,0.31,CCD_B36-5,0.08,CCD_B36-6,0.15,CCD_B36-7,0.05,CCD_B36-8,0.26,CCD_B36-9,0.08,CCD_B36-10,0.11,
  //CCD_B32-1,0.72,CCD_B32-2,0.40,CCD_B32-3,0.32,CCD_B32-4,0.37,CCD_B32-5,0.09,CCD_B32-6,0.16,CCD_B32-7,0.12,CCD_B32-8,0.28,CCD_B32-9,0.13,CCD_B32-10,0.16

  nPgNo:= nCh + JigNo*4;

  sINFOData:= copy(sINFOData, 6, Length(sINFOData)); //INFO= 제거

  asData:= sINFOData.Split([',']);
  for i := 0 to (Length(asData) div 2) - 1 do begin
    InfoData[nPgNo].INFOName[i+1]:= asData[i*2];
    dValue:= StrToFloatDef(asData[i*2 + 1], 0.0);
    InfoData[nPgNo].INFOData[i+1]:= dValue;
  end; //for i := 0 to Length(asData) do begin
end;

procedure TCommCamera.Parse_StainData(nCh: Integer; sStainData: String);
var
  asData: TArray<String>;
  i: Integer;
  nPgNo: Integer;
begin
(*
  //각 패턴 별 6개의 데이터
  PatternName, PositionX, PositionY, Width, Height, Area, Contrast,
     G216,           300,    400,        15,      40,       2,       -30.5,
     G192,         NONE, NONE,    NONE, NONE, NONE ,   NONE,
     G63,,,,,
*)

  nPgNo:= nCh + JigNo*4;
  asData:= sStainData.Split([',']);
  for i := 0 to Length(asData)-1 do begin
    InfoData[nPgNo].StainData[i]:= asData[i];
  end; //for i := 0 to Length(asData) do begin
end;

procedure TCommCamera.ProcessData(nCh, nReadBufferLen: Integer; AReadBuffer: TidBytes; const AContext: TIdContext);
var
  sRecvData, sCommand: string;
  sLog: String;
  pHeader: PCameraHeader;
  //nChecksum: Integer;
  nNullPos: Integer;
  nPgNo, i, nLen : Integer;
  asCommand: TArray<String>;
  nRet: Integer;
  sRet: String;
  RemainBuffer: TidBytes;
begin
  nPgNo:= nCh + JigNo*4;

  if CommandData[nCh].WaitingData then begin
    //POCB data 이어받기
    Copymemory(@m_CameraData[nCh].Data[m_CameraData[nCh].Size], @AReadBuffer[0], nReadBufferLen);
    m_CameraData[nCh].Size:= m_CameraData[nCh].Size + nReadBufferLen;
    if m_CameraData[nCh].Size < m_CameraData[nCh].FullSize then begin
      Exit;
    end;

    //이어받기 완료
    SaveCameraData(nCh, m_CameraData[nCh], CommandData[nCh].TemplateData);
    CommandData[nCh].WaitingData:= False;

    SendData(nCh, 'ACK', AContext);
{$IFNDEF COMMPG_A19}
    //START Process 완료 - DP651 대상
    if Common.SystemInfo.CAM_TemplateData then begin
      if CommandData[nCh].TemplateData then begin
        CommandData[nCh].Step:= CAM_PROCESS_NONE; //PID 변경 방지
        CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
        SetEvent(CommandData[nCh].Event); //START 명령에 대한 종료
      end;
    end
    else begin
      CommandData[nCh].Step:= CAM_PROCESS_NONE; //PID 변경 방지
      CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
      SetEvent(CommandData[nCh].Event); //START 명령에 대한 종료
    end;
{$ENDIF}
    Exit;
  end; //if CommandData[nCh].WaitingData then begin

  //일반
  if nReadBufferLen < 8 then begin
    //Not enough Size Error
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, format('Not enough Data Size Error (%d)', [nReadBufferLen]));
    CommandData[nCh].Reply:= COMMCAM_ERR_SIZE;
    SetEvent(CommandData[nCh].Event);
    Exit;
  end;


  pHeader:= PCameraHeader(AReadBuffer);
  //SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, format('Recv BufferSize=%d Size=%d, Checksum=%d', [nReadBufferLen, pHeader.Size, pHeader.Checksum]));

(*
  if nReadBufferLen <> (pHeader.Size) then begin
    //Size Error
    CommandData[nCh].Reply:= COMMCAM_ERR_SIZE;
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, format('Data Size Error (%d:%d)', [nReadBufferLen,  (pHeader.Size)]));
    Exit;
  end;

  //Checksum
  nChecksum:= CalcChecksum(pHeader.Size);

  if nChecksum <> pHeader.Checksum then begin
    //Checksum Error
    CommandData[nCh].Reply:= COMMCAM_ERR_CHECKSUM;
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, format('Checksum Error (%.8x:%.8x)', [nChecksum, pHeader.Checksum]));
      SetEvent(CommandData[nCh].Event);
    Exit;
  end;
*)

  nNullPos:= -1;

  if CommandData[nCh].NeedMoreCommand then begin
    //명령어 문자열 이어 받기
    sRecvData:= CommandData[nCh].RecvData;
    for i := 0 to Pred(nReadBufferLen) do begin
      if AReadBuffer[i] = 0 then begin
        nNullPos:= i; //0x00 위치
        Break;
      end;
      sRecvData := sRecvData + Char(AReadBuffer[i]);
    end;
    Common.MLog(nPgNo, 'NULL=' + IntToStr(nNullPos) + ', RecvData:' + sRecvData);
  end
  else begin
    sRecvData:= '';
    for i := 8 to Pred(nReadBufferLen) do begin
      if AReadBuffer[i] = 0 then begin
        nNullPos:= i; //0x00 위치
        Break;
      end;
      sRecvData := sRecvData + Char(AReadBuffer[i]);
    end;
  end;

  CommandData[nCh].RecvData:= sRecvData;

  if nNullPos < 0 then begin
    //문자열 종료(0x00)이 없으면 명령어 다 받지 못함
    //명령어 문자열 이어받기 필요
    Common.MLog(nPgNo, 'NeedMoreCommand RecvData:' + sRecvData);
    CommandData[nCh].NeedMoreCommand:= True;
    Exit;
  end;
    
  CommandData[nCh].NeedMoreCommand:= False;
  if sRecvData = '' then Exit;

  if CommandData[nCh].Step <> CAM_PROCESS_PING then begin  //Ping에 대한 로그 제외
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, '(GPC <== DPC) ' + sRecvData); // + ', Size: ' + IntToStr(nReadBufferLen));
  end;

  asCommand:= sRecvData.Split([' ']);
  sCommand := Trim(asCommand[0]);

  if CommandData[nCh].Step = CAM_PROCESS_NONE then begin
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, 'Not Working (GPC <== DPC) ' + sRecvData);
    SendData(nCh, 'NAK', AContext);
    Exit;
  end;

  if sCommand = 'POCBDATA' then begin
    m_CameraData[nCh].Size:= 0;
    m_CameraData[nCh].FullSize:= StrToInt(asCommand[2]); //Data Size
    SetLength(m_CameraData[nCh].Data, m_CameraData[nCh].FullSize);

    if asCommand[1] <> 'RMD' then begin
      //Mode Error - Only use 'RMD'
    end;

    if asCommand[1] = 'RMTE' then begin
      CommandData[nCh].TemplateData:= True;
    end
    else begin
      CommandData[nCh].TemplateData:= False;
    end;

    Copymemory(@m_CameraData[nCh].Data[m_CameraData[nCh].Size], @AReadBuffer[nNullPos+1], nReadBufferLen - nNullPos);
    m_CameraData[nCh].Size:= m_CameraData[nCh].Size + (nReadBufferLen - nNullPos-1);

    if m_CameraData[nCh].Size < m_CameraData[nCh].FullSize then begin
      CommandData[nCh].WaitingData:= True;

(*
      //이어받기 지연으로 전부 수신하지 못한 경우
      thCheck := TThread.CreateAnonymousThread(
        procedure
        begin
          Sleep(3000);
          if CommandData[nCh].WaitingData = True then begin
            //NG
            CommandData[nCh].WaitingData:= False;
            SendDataByChannel(nCh, 'NAK');
          end;
        end);

      thCheck.FreeOnTerminate := True;
      thCheck.Start;
*)

    end
    else begin
      //데이터 수신 완료
      SaveCameraData(nCh, m_CameraData[nCh], CommandData[nCh].TemplateData);

      CommandData[nCh].WaitingData:= False;
      SendData(nCh, 'ACK', AContext);
{$IFNDEF COMMPG_A19}
      //START Process 완료 - DP651 대상
      if Common.SystemInfo.CAM_TemplateData then begin
        if CommandData[nCh].TemplateData then begin
          CommandData[nCh].Step:= CAM_PROCESS_NONE; //PID 변경 방지
          CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
          SetEvent(CommandData[nCh].Event); //START 명령에 대한 종료
        end;
      end
      else begin
        CommandData[nCh].Step:= CAM_PROCESS_NONE; //PID 변경 방지
        CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
        SetEvent(CommandData[nCh].Event); //START 명령에 대한 종료
      end;
{$ENDIF}
    end;
    Exit;

    SendData(nCh, 'ACK', AContext);
  end; //if sCommand = 'POCBDATA' then begin



  if sCommand = 'CHGPTN' then begin
    if Common.SystemInfo.CAM_CallbackChangePattern then begin
      if CommandData[nCh].Step = CAM_PROCESS_MEASURE then begin
        sRet:= PasScr[nPgNo].ExecExtraFunction('Callback_ChangePattern 1,' + asCommand[1] + ',0,0');
      end
      else if CommandData[nCh].Step = CAM_PROCESS_AFTERSTART then begin
        //AfterStart 측정
        sRet:= PasScr[nPgNo].ExecExtraFunction('Callback_ChangePattern 1,' + asCommand[1] + ',0,0');
      end
      else if CommandData[nCh].Step = CAM_PROCESS_STAINSTART then begin
        //Stain 측정
        sRet:= PasScr[nPgNo].ExecExtraFunction('Callback_ChangePattern 1,' + asCommand[1] + ',0,0');
      end
      else begin
        sRet:= 'Unknown Process CHGPTN NG';
      end;

      if sRet <> '' then begin
        SendData(nCh, 'NAK', AContext);
        CommandData[nCh].ErrorMsg:= sRet; //'CHGPTN ' + asCommand[1] + ' Limit NG';
        CommandData[nCh].Reply:= COMMCAM_ERR_CHGPTN;
        SetEvent(CommandData[nCh].Event); //START 명령에 대한 종료
        Exit;
      end;

      SendData(nCh, 'ACK', AContext);
    end
    else begin
      SendData(nCh, 'NAK', AContext);
      CommandData[nCh].ErrorMsg:= 'Not Support Internal CHGPTN'; //'CHGPTN ' + asCommand[1] + ' Limit NG';
      CommandData[nCh].Reply:= COMMCAM_ERR_CHGPTN;
      SetEvent(CommandData[nCh].Event); //START 명령에 대한 종료
      SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, 'Not Support Internal CHGPTN');
      (*
{$IFDEF COMMPG_A19}
      nRet:= CommPG[nPgNo].SendDisplayPTN(StrToInt(asCommand[1]));
{$ELSE}
      nRet:= Pg[nPgNo].SendDisplayPat(StrToIntDef(asCommand[1],0));
{$ENDIF}
      if nRet <> 0 then begin
        SendData(nCh, 'NAK', AContext);
        CommandData[nCh].ErrorMsg:= 'CHGPTN ' + asCommand[1]; // + ' Limit NG';
        CommandData[nCh].Reply:= COMMCAM_ERR_CHGPTN;
        SetEvent(CommandData[nCh].Event); //START 명령에 대한 종료
        Exit;
      end
      else begin
        SendData(nCh, 'ACK', AContext);
      end;
      *)
    end;
  end

  else if sCommand = 'PGON' then begin
{$IFDEF COMMPG_A19}
    //nRet:= CommPG[nPgNo].SendPowerOn(True);
{$ELSE}
    //nRet := Pg[nPgNo].SendPowerOn(1);
{$ENDIF}
    m_nLightState[nCh]:= 0;  //이물조명 끄기
    sLog := Format('LS: %d %d %d %d',[m_nLightState[0], m_nLightState[1], m_nLightState[2], m_nLightState[3]]);
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, sLog);
    //전체 Off 검사
    if CheckLightSourceStateAll(False) then begin
      CommLight.WriteBrightsAll(0);
      SendDataAll('ACK');
    end;
    //CommLight.WriteBrightTwin(nCh*2, nCh*2+1, 0, 0);
    //SendData(nCh, 'ACK', AContext);
  end

  else if sCommand = 'PGOFF' then begin
{$IFDEF COMMPG_A19}
    //nRet:= CommPG[nPgNo].SendPowerOn(False);
{$ELSE}
    //nRet := Pg[nPgNo].SendPowerOn(0);
{$ENDIF}
    m_nLightState[nCh]:= 1;  //이물조명 켜기
    sLog := Format('LS: %d %d %d %d',[m_nLightState[0], m_nLightState[1], m_nLightState[2], m_nLightState[3]]);
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, sLog);
    //전체 On 검사
//    if CheckLightSourceStateAll(True) then begin
//      CommLight.WriteBrightsAll(StrToInt(asCommand[1]));
//      SendDataAll('ACK');
//    end;
    CommLight.WriteBrightTwin(nCh*2, nCh*2+1, StrToInt(asCommand[1]), StrToInt(asCommand[2]));
    SendData(nCh, 'ACK', AContext);
  end

  else if sCommand = 'CHGPTNDONE' then begin
    SendData(nCh, 'ACK', AContext);

    case CommandData[nCh].Step of
      CAM_PROCESS_NONE: begin
        //검사(Start) 영역 프로세스
      end;
      CAM_PROCESS_MEASURE: begin
        //검사(Start) 영역 프로세스로 설정
        //Erase
        sRet:= PasScr[nPgNo].ExecExtraFunction('EraseFlash_POCB');
        if sRet <> 'True' then begin
          //CommandData[nCh].Reply:= COMMCAM_ERR_FLASHERASE;
          //CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
          //SendData(nCh, 'NACK', AContext);
        end;
      end;
      CAM_PROCESS_STAINSTART: begin
        //SetEvent(CommandData[nCh].Event); //STAINSTART 명령 종료
      end;
      CAM_PROCESS_AFTERSTART: begin
        SetEvent(CommandData[nCh].Event); //AFTERSTART 명령 종료
      end;

      else begin
        //Error - Unknown
      end;

    end;

  end

  else if sCommand = 'AFTERDONE' then begin
    SendData(nCh, 'ACK', AContext);

    case CommandData[nCh].Step of
      CAM_PROCESS_NONE: begin
        //검사(Start) 영역 프로세스
      end;
      CAM_PROCESS_AFTERSTART: begin
        SetEvent(CommandData[nCh].Event); //AFTERSTART 명령 종료
      end;

      else begin
        //Error - Unknown
      end;

    end;

  end

  else if sCommand = 'POCBPATH' then begin
    //POCBPATH d:\POCB\210511\ABC.hex
    //POCBPATH E:\POCB\HEX\20220307\D854-CB-P1\GH315160FPH14YF1X_20220307103248\NyPucData_3rd_GH315160FPH14YF1X_PUC_1G2O.hex
    CommandData[nCh].RecvData:= asCommand[1]; //path
    CommandData[nCh].Step:= CAM_PROCESS_NONE; //PID 변경 방지
    SendData(nCh, 'ACK', AContext);

    CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
    SetEvent(CommandData[nCh].Event); //MEASURE 명령에 대한 종료
  end

  else if sCommand = 'PUCVER' then begin
    //PUCVER APPLE_PUC_Meridian_D854_P2_1G2O_V_v8p3_2021
    //3rd PUC 진행 시
    //PUCVER APPLE_PUC_Meridian_D854_P2_1G2O_V_v8p3_2021/APPLE_PUC_Meridian_D854_P2_1G2O_V_v8p3_2021/APPLE_PUC_Meridian_D854_P2_1G2O_V_v8p3_2021
    //어떤 처리를 해야 하나?
    SendData(nCh, 'ACK', AContext);
    CommandData[nCh].PUCVer:= asCommand[1];
  end

  else if sCommand = 'GETVER' then begin
    SendData(nCh, 'ACK', AContext);
    CommandData[nCh].TrueTestVer:= asCommand[1];
  end

  else if sCommand = 'STAINDONE' then begin
    SendData(nCh, 'ACK', AContext);
    Parse_StainData(nCh, asCommand[1]);
    CommandData[nCh].Reply:= COMMCAM_ERR_NONE;

    //Result에서 완료한다.
    //SetEvent(CommandData[nCh].Event); //STAINSTART 명령 종료
  end

  else if sCommand = 'FFCDONE' then begin
    SendData(nCh, 'ACK', AContext);
    //parse
    Parse_FFCData(nCh, asCommand[1]);
    CommandData[nCh].Reply:= COMMCAM_ERR_NONE;

    SetEvent(CommandData[nCh].Event); //FFCSTART 명령 종료
  end

  else if sCommand = 'RESULT' then begin
    SendData(nCh, 'ACK', AContext);

    //CommandData[nCh].RecvData:= Copy(sRecvData, 41, Length(sRecvData));

    if Common.SystemInfo.CAM_ResultType = 0 then begin
      //RESULT NG XX.XX XX.XX XX.XX XX.XX XX.XX Panel NG
      //RESULT OK -1.00 -1.00 -1.00 -1.00 -1.00 NA
      if asCommand[1] <> 'OK' then begin
        CommandData[nCh].ErrorMsg:= Copy(sRecvData, 41, Length(sRecvData));
        CommandData[nCh].Reply:= COMMCAM_ERR_RESULT;
      end
      else begin
        CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
      end;
    end
    else begin
      //RESULT OK -1.00 -1.00 -1.00 -1.00 -1.00 25
      //INFO=DUTROTANGLE,0.01,DUTWIDTH,2501,DUTHEIGHT,5414,DUTSHIFTX,-1,DUTSHIFTY,-31.5,MTF,91.18,MTF_CENTER,91.03,MTF_UL,90.82,MTF_UR,91.23,MTF_LL,89.43,MTF_LR,91.11,KeystoneH,0.0376,KeystoneV,0.0585,
      //CCD_G216-1,0.10,CCD_G216-2,0.07,CCD_G216-3,0.12,CCD_G216-4,0.12,CCD_G216-5,0.02,CCD_G216-6,0.07,CCD_G216-7,0.06,CCD_G216-8,0.14,CCD_G216-9,0.07,CCD_G216-10,0.09,
      //CCD_G192-1,0.11,CCD_G192-2,0.10,CCD_G192-3,0.14,CCD_G192-4,0.12,CCD_G192-5,0.07,CCD_G192-6,0.10,CCD_G192-7,0.14,CCD_G192-8,0.16,CCD_G192-9,0.13,CCD_G192-10,0.03,
      //CCD_G36-1,0.27,CCD_G36-2,0.09,CCD_G36-3,0.22,CCD_G36-4,0.47,CCD_G36-5,0.16,CCD_G36-6,0.07,CCD_G36-7,0.28,CCD_G36-8,0.48,CCD_G36-9,0.23,CCD_G36-10,0.15,
      //CCD_G32-1,0.26,CCD_G32-2,0.08,CCD_G32-3,0.24,CCD_G32-4,0.41,CCD_G32-5,0.16,CCD_G32-6,0.17,CCD_G32-7,0.28,CCD_G32-8,0.49,CCD_G32-9,0.23,CCD_G32-10,0.16,
      //CCD_R216-1,0.19,CCD_R216-2,0.15,CCD_R216-3,0.22,CCD_R216-4,0.13,CCD_R216-5,0.25,CCD_R216-6,0.09,CCD_R216-7,0.30,CCD_R216-8,0.17,CCD_R216-9,0.16,CCD_R216-10,0.36,
      //CCD_R192-1,0.22,CCD_R192-2,0.14,CCD_R192-3,0.26,CCD_R192-4,0.13,CCD_R192-5,0.35,CCD_R192-6,0.09,CCD_R192-7,0.33,CCD_R192-8,0.24,CCD_R192-9,0.18,CCD_R192-10,0.38,
      //CCD_R36-1,0.36,CCD_R36-2,0.50,CCD_R36-3,0.10,CCD_R36-4,0.19,CCD_R36-5,0.51,CCD_R36-6,0.54,CCD_R36-7,0.49,CCD_R36-8,0.39,CCD_R36-9,0.21,CCD_R36-10,0.70,
      //CCD_R32-1,0.36,CCD_R32-2,0.52,CCD_R32-3,0.10,CCD_R32-4,0.27,CCD_R32-5,0.38,CCD_R32-6,0.58,CCD_R32-7,0.55,CCD_R32-8,0.49,CCD_R32-9,0.14,CCD_R32-10,0.61,
      //CCD_B216-1,0.08,CCD_B216-2,0.21,CCD_B216-3,0.09,CCD_B216-4,0.29,CCD_B216-5,0.08,CCD_B216-6,0.12,CCD_B216-7,0.15,CCD_B216-8,0.47,CCD_B216-9,0.17,CCD_B216-10,0.07,
      //CCD_B192-1,0.16,CCD_B192-2,0.17,CCD_B192-3,0.03,CCD_B192-4,0.33,CCD_B192-5,0.09,CCD_B192-6,0.12,CCD_B192-7,0.13,CCD_B192-8,0.44,CCD_B192-9,0.24,CCD_B192-10,0.04,
      //CCD_B36-1,0.14,CCD_B36-2,0.33,CCD_B36-3,0.19,CCD_B36-4,0.46,CCD_B36-5,0.39,CCD_B36-6,0.04,CCD_B36-7,0.40,CCD_B36-8,0.77,CCD_B36-9,0.17,CCD_B36-10,0.23,
      //CCD_B32-1,0.15,CCD_B32-2,0.43,CCD_B32-3,0.25,CCD_B32-4,0.37,CCD_B32-5,0.38,CCD_B32-6,0.12,CCD_B32-7,0.49,CCD_B32-8,0.84,CCD_B32-9,0.15,CCD_B32-10,0.23
      //NY DLL
      nLen:= Length(asCommand);
      if nLen < 10 then begin
        //패킷 이상
        CommandData[nCh].ErrorMsg:= 'RESULT size Error';
        CommandData[nCh].Reply:= COMMCAM_ERR_RESULT;
      end
      else begin
        if asCommand[1] <> 'OK' then begin
          CommandData[nCh].ErrorMsg:= '';
          //Error Message에 빈칸 있을 수 있음
          for i := 9 to nLen - 1 do begin
            CommandData[nCh].ErrorMsg:= CommandData[nCh].ErrorMsg + asCommand[i] + ' ';
          end;
          CommandData[nCh].ErrorMsg:= Trim(CommandData[nCh].ErrorMsg);
          CommandData[nCh].Reply:= COMMCAM_ERR_RESULT;
        end
        else begin
          CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
        end;

        InfoData[nPgNo].Temperature:= StrToFloatDef(asCommand[7], 0.0); //카메라 온도
        InfoData[nPgNo].INFOData[0]:= StrToFloatDef(asCommand[7], 0.0); //카메라 온도를 INFOData[0]에 대입하여 사용
        Parse_INFOData(nCh, asCommand[8]);
      end;
    end;

    SetEvent(CommandData[nCh].Event); //END 명령에 대한 종료 혹은 START, FFCSTART등에서 NG시 종료
  end

  else if sCommand = 'ACK' then begin
    CommandData[nCh].Reply:= COMMCAM_ERR_NONE;
    case CommandData[nCh].Step of
      CAM_PROCESS_NONE: begin
        //검사(Start) 영역 프로세스
      end;
      CAM_PROCESS_MODELCHG: begin
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_PING: begin
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_START: begin
        //START에 대한 응답 -> 다음 진행설정
        CommandData[nCh].Step:=  CAM_PROCESS_MEASURE; //검사(Start) 영역 프로세스로 설정
      end;
      CAM_PROCESS_POCBGAMMA: begin
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_END: begin
        //END에 대한 종료는 RESULT
        if Common.SystemInfo.CAM_StainData then begin
          //Statin에서는 END가 프로세스 종료
          SetEvent(CommandData[nCh].Event);
        end;
      end;
      CAM_PROCESS_FTPUPLOAD: begin
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_CHANGERCB: begin
        //SetEvent(CommandData[nCh].Event);
        CommandData[nCh].Step:=  CAM_PROCESS_MEASURE; //검사(Start) 영역 프로세스로 설정
      end;
      CAM_PROCESS_STAINSTART: begin
        //CommandData[nCh].Step:=  CAM_PROCESS_MEASURE; //검사(Start) 영역 프로세스로 설정
      end;
      CAM_PROCESS_AFTERSTART: begin
        //
      end;
      else begin
        //Error - Unknown
      end;

    end;

  end  //else if sCommand = 'ACK' then begin

  else if sCommand = 'NAK' then begin
    CommandData[nCh].Reply:= COMMCAM_ERR_NAK;
    case CommandData[nCh].Step of
      CAM_PROCESS_NONE: begin
        //검사(Start) 영역 프로세스
      end;
      CAM_PROCESS_MODELCHG: begin
        //Error -
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_PING: begin
        //Error -
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_START: begin
        //Error -
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_POCBGAMMA: begin
        //Error -
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_END: begin
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_FTPUPLOAD: begin
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_CHANGERCB: begin
        SetEvent(CommandData[nCh].Event);
      end;
      CAM_PROCESS_STAINSTART: begin
        SetEvent(CommandData[nCh].Event);
      end;
      else begin
        //Error - Unknown
      end;

    end;
  end //else if sCommand = 'NAK' then begin
  else begin
    //Unknown Command
    Common.MLog(nPgNo, format('Unknown Command: %s', [sCommand]));
    SendData(nCh, 'NAK', AContext);
  end;

  //잔여 데이터 처리
  if nReadBufferLen > pHeader.Size then begin
    nLen:= nReadBufferLen - pHeader.Size;
    Common.MLog(nPgNo, format('Remain RecvSize(%d) - DataSize(%d) = %d', [nReadBufferLen, pHeader.Size, nLen]));
    SetLength(RemainBuffer, nLen);
    CopyMemory(@RemainBuffer[0], @AReadBuffer[nNullPos+1], nLen);
    ProcessData(nCh, nLen, RemainBuffer, AContext);
  end

end;

procedure TCommCamera.SaveCameraData(nCh: Integer; ACameraData: TCameraData; bTemplate: Boolean);
var
  fs: TFileStream;
  sFileName, sFilePath: String;
  nPgNo: Integer;
begin
  //프로토콜 문서와 다르게 수신 데이터는 hex가 아닌 binary 데이터이다.
  sFilePath := Common.Path.CB_DATA  + FormatDateTime('YYYYMMDD', Now) + '\';
  Common.CheckDir(sFilePath);

  if bTemplate then begin
    sFileName := sFilePath + FormatDateTime('YYYYMMDDHHNNSS_', Now) + CommandData[nCh].PID + Format('_CH%d_Template.bin',[nCh+1]);
  end
  else begin
    sFileName := sFilePath + FormatDateTime('YYYYMMDDHHNNSS_', Now) + CommandData[nCh].PID + Format('_CH%d.bin',[nCh+1]);
  end;

  fs:= TFileStream.Create(sFileName, fmCreate);
  try
    fs.Write(ACameraData.Data[0], ACameraData.Size);
  finally
    fs.Free;
  end;

  if bTemplate then begin
    sFileName := Common.Path.CB_DATA + Format('CH%d_Template.bin',[nCh+1]);
  end
  else begin
    sFileName := Common.Path.CB_DATA + Format('CH%d.bin',[nCh+1]);
  end;

  nPgNo:= nCh + JigNo*4;
  Common.MLog(nPgNo, format('SaveCameraData: %s', [sFileName]));
  fs:= TFileStream.Create(sFileName, fmCreate);
  try
    fs.Write(ACameraData.Data[0], ACameraData.Size);
  finally
    fs.Free;
  end;
end;

function TCommCamera.SendBuffer(nCh: Integer; ABuffer: TIdBytes; nWaitTime: Integer): boolean;
var
  nPort: Integer;
  AContext: TIdContext;
  nSize : Int64;
  i: Integer;
begin
  Result:= False;
  nPort:= BASE_CAMERA_PORT + nCh;
  nSize:= Length(ABuffer);
  try
    with m_idTCPServer[nCh].Contexts.LockList do begin
      for i:= 0 to Count - 1 do begin
        AContext:= Items[i];
        if AContext.Connection.Socket.Binding.Port = nPort then begin
          AContext.Connection.IOHandler.Write(ABuffer, nSize);
          Result:= True;
          SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, '(GPC ==> DPC) Buffer Size:' + BufferToString(ABuffer, 100));
          Break;
        end;
      end;
    end;

  finally
    m_idTCPServer[nCh].Contexts.UnlockList;
  end;
end;

function TCommCamera.CancelCommand(nCh: Integer): Integer;
var
  i: Integer;
begin
  if nCh > 3 then begin
    for i := 0 to 3 do begin
      CommandData[i].Reply:= COMMCAM_ERR_CANCEL;
      SetEvent(CommandData[i].Event);
    end;
  end
  else begin
    CommandData[nCh].Reply:= COMMCAM_ERR_CANCEL;
    SetEvent(CommandData[nCh].Event);
  end;
  Result:= 0;
end;

function TCommCamera.SendCommand(nCh: Integer; sCommand: string; nWaitTime: Integer): Integer;
var
  asCommand: TArray<String>;
  sCmd: String;
  dwRet: DWORD;
  bRet : boolean;
begin
  Result:= COMMCAM_ERR_EXCEPTION;
  CommandData[nCh].ErrorMsg:= '';

  asCommand:= sCommand.Split([' ']);
  sCmd := Trim(asCommand[0]);

  if sCmd = 'START' then begin
    CommandData[nCh].Step:= CAM_PROCESS_START;
    CommandData[nCh].WaitingData:= False; //이어 받기 아님
    m_nLightState[0]:= 0;
    m_nLightState[1]:= 0;
    m_nLightState[2]:= 0;
    m_nLightState[3]:= 0;
  end
  else if sCmd = 'MODELCHG' then begin
    CommandData[nCh].Step:= CAM_PROCESS_MODELCHG;
  end
  else if sCmd = 'PING' then begin
    CommandData[nCh].Step:= CAM_PROCESS_PING;
  end
  else if sCmd = 'POCBGAMMA' then begin
    CommandData[nCh].Step:= CAM_PROCESS_POCBGAMMA;
  end
  else if sCmd = 'FFCSTART' then begin
    CommandData[nCh].Step:= CAM_PROCESS_FFCSTART;
  end
  else if sCmd = 'END' then begin
    CommandData[nCh].Step:= CAM_PROCESS_END;
  end
  else if sCmd = 'FTPUPLOAD' then begin
    CommandData[nCh].Step:= CAM_PROCESS_FTPUPLOAD;
  end
  else if sCmd = 'STAINSTART' then begin
    CommandData[nCh].Step:= CAM_PROCESS_STAINSTART;
  end
  else if sCmd = 'CHGRCB' then begin
    CommandData[nCh].Step:= CAM_PROCESS_CHANGERCB;
  end
  else if sCmd = 'AFTERSTART' then begin
    CommandData[nCh].Step:= CAM_PROCESS_AFTERSTART;
  end
  else if sCmd = 'CLEARDATA' then begin
    //ZeroMemory(@CommandData[nCh + JigNo*4].FFCData[0], Sizeof(CommandData[nCh].FFCData[0]) * Length(CommandData[nCh].FFCData));
    //ZeroMemory(@CommandData[nCh + JigNo*4].INFOData[0], Sizeof(CommandData[nCh].INFOData[0]) * Length(CommandData[nCh].INFOData));
    ZeroMemory(@InfoData[nCh + JigNo*4].FFCData[0], Sizeof(InfoData[nCh + JigNo*4].FFCData[0]) * Length(InfoData[nCh + JigNo*4].FFCData));
    ZeroMemory(@InfoData[nCh + JigNo*4].INFOData[0], Sizeof(InfoData[nCh + JigNo*4].INFOData[0]) * Length(InfoData[nCh + JigNo*4].INFOData));
    Result:= COMMCAM_ERR_NONE;
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, 'Camera Command: CLEARDATA OK');
    Exit;
  end
  else begin
    //Unknown Error
    CommandData[nCh].ErrorMsg:= 'Camera Command: Unknown Command : ' + sCmd;
    Exit;
  end;

  //SendMessageMain(MSG_MODE_WORKING, nCh, 0, 0, 'Server -> CAM: ' + sCmd);
  CommandData[nCh].RecvData:= '';
  CommandData[nCh].NeedMoreCommand:= False;

  ResetEvent(CommandData[nCh].Event);
  bRet := SendDataByChannel(nCh, sCommand);
  if bRet then begin
    //Wait Reply
    dwRet:= WaitForSingleObject(CommandData[nCh].Event, nWaitTime);

    if dwRet = WAIT_OBJECT_0 then begin
      case CommandData[nCh].Reply of
        COMMCAM_ERR_NONE: begin
          CommandData[nCh].ErrorMsg:= 'Camera Command: OK ' + sCmd;
        end;
        COMMCAM_ERR_NAK: begin
          CommandData[nCh].ErrorMsg:= 'Camera Command: NAK ' + sCmd;
        end;
        COMMCAM_ERR_FLASHERASE: begin
          CommandData[nCh].ErrorMsg:= 'Camera Command: Flash Erase Error';
        end;
        COMMCAM_ERR_CANCEL: begin
          CommandData[nCh].ErrorMsg:= 'Camera Command: Cancel ' + sCmd;
        end;
        COMMCAM_ERR_CHGPTN: begin
          //CommandData[nCh].ErrorMsg:= 'Camera Command: CHGPTN Limit';
        end;
        COMMCAM_ERR_EXCEPTION: begin
          CommandData[nCh].ErrorMsg:= 'Camera Command: EXCEPTION';
        end;
        COMMCAM_ERR_RESULT: begin
          //CommandData[nCh].ErrorMsg:= CommandData[nCh].RecvData;
          //CommandData[nCh].ErrorMsg:= Copy(CommandData[nCh].RecvData, 41, Length(CommandData[nCh].RecvData));
        end;
        else begin
          CommandData[nCh].ErrorMsg:= 'Camera Command: NG';
        end;
      end;
      Result:= CommandData[nCh].Reply;
      if CommandData[nCh].Step <> CAM_PROCESS_PING then begin //Ping에 대한 로그 제외
        SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, CommandData[nCh].ErrorMsg);
      end;
    end
    else if dwRet = WAIT_TIMEOUT then begin
      if CommandData[nCh].NeedMoreCommand then begin
        Common.MLog(nCh, 'MoreCommand:' + CommandData[nCh].RecvData);
      end;

      CommandData[nCh].ErrorMsg:= 'Camera Command: Time out ' + sCmd;
      Result:= COMMCAM_ERR_TIMEOUT;
      SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, CommandData[nCh].ErrorMsg);

    end
    else begin
      CommandData[nCh].ErrorMsg:= 'Camera Command: ERROR';
      Result:= COMMCAM_ERR_EXCEPTION;
      SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, CommandData[nCh].ErrorMsg);
    end;
  end
  else begin
    CommandData[nCh].ErrorMsg:= 'Camera Command: Send Fail';
    Result:= COMMCAM_ERR_SENDFAIL;
    SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, CommandData[nCh].ErrorMsg);
  end;

  CommandData[nCh].Step:= CAM_PROCESS_NONE; //명령 받지 않음 - NAK
end;

function TCommCamera.SendData(nCh: Integer; sData: string; const AContext: TIdContext): Boolean;
var
  ABuffer : TIdBytes;
  nSize, nCheckSum, nPos, i : Integer;
  nLenData: Integer;
  sCmd : AnsiString;
  sDebug, sLog : string;
  asCommand: TArray<String>;
  sCommand: String;
  nDataSize: Integer;
begin
  Result := False;
  m_nTickLast:= GetTickCount;

  if (AContext = nil) or (not AContext.Connection.Connected) then Exit;

  if (CommandData[nCh].Step = CAM_PROCESS_START) then  begin
    //START 명령일 경우 hex OTP Data를 바이트로 변경하여 전송한다. '0x01 0x02 ...' -> [1, 2...]
    nPos:= Pos(#0, sData);
    sCommand:= Copy(sData, 1, nPos-1);
    asCommand:= sCommand.Split([' ']);
    if Length(asCommand) < 3 then begin
      SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, 'CAM_PROCESS_START Data Error');
      Result:= False;
      Exit;
    end;

    nSize:= Length(sCommand) + 1; //#0
    CommandData[nCh].PID:= asCommand[1];
    nDataSize:= StrToInt(Trim(asCommand[2]));
    SetLength(ABuffer, 8 + nSize + nDataSize);

    //ascii 부분 처리 - 'START PID4321 0005'
    sCmd:= AnsiString(sCommand) + #$00;
    CopyMemory(@ABuffer[8], @sCmd[1], nSize);

    //OTP Data 처리 - hex OTP Data를 바이트로 변경하여 전송한다. '0x01 0x02 ...' -> [1, 2...]
    for i:= 0 to nDataSize-1 do begin
      //sCommand:= Copy(sData, nPos + 1 + (i*5), 4);
      //ABuffer[8 + nSize + i]:= StrToInt(sCommand);
      sCommand:= Copy(sData, nPos + 1 + (i*3), 2);
      ABuffer[8 + nSize + i]:= StrToInt('0x' + sCommand);
    end;
    //Size, Checksum
    nSize:= 8 + nSize + nDataSize;
    nCheckSum:= CalcChecksum(nSize); // check sum.
    CopyMemory(@ABuffer[0], @nSize, 4);
    CopyMemory(@ABuffer[4], @nCheckSum, 4);
  end
  else if (CommandData[nCh].Step = CAM_PROCESS_POCBGAMMA) then  begin
    nPos:= Pos(#0, sData);
    sCommand:= Copy(sData, 1, nPos-1);
    asCommand:= sCommand.Split([' ']);
    if Length(asCommand) < 2 then begin
      SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, 'CAM_PROCESS_POCBGAMMA Data Error');
      Result:= False;
      Exit;
    end;


    nSize:= Length(sCommand) + 1; //#0
    nDataSize:= StrToInt(Trim(asCommand[1]));
(*
    nLenData:= Length(sData) - nSize;
    if (nLenData div 3) < nDataSize  then begin
      Result:= False;
      Exit;
    end;
*)
    SetLength(ABuffer, 8 + nSize + nDataSize);

    //ascii 부분 처리 - 'POCBGAMMA 25344'
    sCmd:= AnsiString(sCommand) + #$00;
    CopyMemory(@ABuffer[8], @sCmd[1], nSize);

    //POCBGAMMA 처리 - hex POCBGAMMA를 바이트로 변경하여 전송한다. '0x01 0x02 ...' -> [1, 2...]
    for i:= 0 to nDataSize-1 do begin
      //sCommand:= Copy(sData, nPos + 1 + (i*5), 4);
      //ABuffer[8 + nSize + i]:= StrToInt(sCommand);
      sCommand:= Copy(sData, nPos + 1 + (i*3), 2);
      ABuffer[8 + nSize + i]:= StrToInt('0x' + sCommand);
    end;
    //Size, Checksum
    nSize:= 8 + nSize + nDataSize;
    nCheckSum:= CalcChecksum(nSize); // check sum.
    CopyMemory(@ABuffer[0], @nSize, 4);
    CopyMemory(@ABuffer[4], @nCheckSum, 4);
  end
(*
  // Added by Clint 2021-01-03 오후 5:06:08 START 명령어 OTP Read Data 안쓸경우 대비.
  if (CommandData[nCh].Step = CAM_PROCESS_START) and (m_OtpData[nCh].Size <> 0) then  begin
    // 8: Size, Checksum, 5 : Size 4 digit + space, 1 : #00
    nSize:= 8 + Length(sData) + 5 + 1 + m_OtpData[nCh].Size;

    SetLength(ABuffer,nSize);
    sSize := Format(' %0.4d',[m_OtpData[nCh].Size]);
    sCmd := AnsiString(sData)+AnsiString(sSize)+#$00;

    nCheckSum:= CalcChecksum(nSize); // check sum.
    CopyMemory(@ABuffer[0], @nSize, 4);
    CopyMemory(@ABuffer[4], @nCheckSum, 4);
    CopyMemory(@ABuffer[8],@sCmd[1],Length(sCmd));
    CopyMemory(@ABuffer[8+Length(sCmd)],@m_OtpData[nCh].Data[0],m_OtpData[nCh].Size);
  end
*)
  else begin
    nSize := 8+Length(sData)+1; //Header(8) + Length(?) + #00(1)
    SetLength(ABuffer,nSize);
    sCmd := AnsiString(sData)+#$00;

    nCheckSum:= CalcChecksum(nSize); // check sum.
    CopyMemory(@ABuffer[0],@nSize,4);
    CopyMemory(@ABuffer[4],@nCheckSum,4);
    CopyMemory(@ABuffer[8],@sCmd[1],Length(sCmd));
  end;

  try
      AContext.Connection.IOHandler.Write(ABuffer,nSize);
      Result := True;
      nPos := Pos(#$00, sData);
      if nPos > 0 then
        sLog := Copy(sData,1,nPos)
      else
        sLog := sData;

      if CommandData[nCh].Step <> CAM_PROCESS_PING then begin //Ping에 대한 로그 제외
        SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, '(GPC ==> DPC) '+sLog);
      end;

//      nPos := Pos('START',sData);
//      if nPos > 0 then begin
//        sDebug := '';
//        for i := 0 to 7 do begin
//          sDebug := sDebug + Format('%0.2x ',[ABuffer[i]]);
//        end;
//        sDebug := sDebug + sData;
//        SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, '[Debug] '+sDebug);
//      end;
  except
    try
      //오류 시 재시도
      Sleep(1000);
      AContext.Connection.IOHandler.Write(ABuffer,nSize);
      Result := True;
    except
      sDebug := '(GPC ==> DPC) Send Data Failed! '+sLog;
      SendMessageTest(MSG_MODE_WORKING, nCh, 0, 0, sDebug);
      Result := False;
    end;
  end;
end;

function TCommCamera.SendDataAll(sData: string): Boolean;
var
  i: Integer;
begin
  Result:= True;
  for i := 0 to MAX_COUNT_CAMERA do begin
    if SendDataByChannel(i, sData) <> True then Result:= False;
  end;
end;

function TCommCamera.SendDataByChannel(nCh: Integer; sData: string): Boolean;
var
  nPort: Integer;
  AContext: TIdContext;
  i: Integer;
begin
  Result:= False;
  nPort:= BASE_CAMERA_PORT + nCh;
  try
    with m_idTCPServer[nCh].Contexts.LockList do begin
      for i:= 0 to Count - 1 do begin
        AContext:= Items[i];
        if AContext.Connection.Socket.Binding.Port = nPort then begin
          Result:= SendData(nCh, sData, AContext);
          Break;
        end;
      end;
    end;
  finally
    m_idTCPServer[nCh].Contexts.UnlockList;
  end;
end;

procedure TCommCamera.SendMessageMain(nMode, nCh, nParam, nParam2: Integer; sMsg: String);
var
  cds         : TCopyDataStruct;
  GUIMessage     : RGuiCamData;
begin
  GUIMessage.MsgType := m_nCamType;
  GUIMessage.Channel := nCh;
  GUIMessage.Mode    := nMode;
  GUIMessage.nParam  := nParam;
  GUIMessage.nParam2 := nParam2;
  GUIMessage.Msg     := sMsg;
  GUIMessage.Msg2    := '';
  cds.dwData      := 0;
  cds.cbData      := SizeOf(GUIMessage);
  cds.lpData      := @GUIMessage;
  SendMessage(m_hMain, WM_COPYDATA, 0, LongInt(@cds));

  //TThread.Queue(TThread.CurrentThread.ThreadID, AMethod);
end;

procedure TCommCamera.SendMessageTest(nMode, nCh, NParam, nParam2: Integer; sMsg: String);
var
  cds         : TCopyDataStruct;
  GUIMessage     : RGuiCamData;
begin
  GUIMessage.MsgType := m_nCamType;
  GUIMessage.Channel := nCh;
  GUIMessage.Mode    := nMode;
  GUIMessage.nParam  := nParam;
  GUIMessage.nParam2 := nParam2;
  GUIMessage.Msg     := sMsg;
  GUIMessage.Msg2    := '';
  cds.dwData      := 0;
  cds.cbData      := SizeOf(GUIMessage);
  cds.lpData      := @GUIMessage;
  SendMessage(m_hTest, WM_COPYDATA, 0, LongInt(@cds));
end;

function TCommCamera.SendModel(sModelName: String): Integer;
var
  bRet: Boolean;
  i: Integer;
begin
  Result:= 0;
  for i := 0 to MAX_COUNT_CAMERA do begin
    CommandData[i].Step:= CAM_PROCESS_MODELCHG; //NAK 응답 방지
//    Result:= SendCommand(i, 'MODELCHG ' + sModelName);
//    if Result <> 0 then begin
//        SendMessageTest(MSG_MODE_WORKING, i, 0, 0, 'Send Data Fail');
//      //Exit;
//    end;
  end;
  bRet:= SendDataAll('MODELCHG ' + sModelName);
  if not bRet then Result:= 1;
end;

procedure TCommCamera.SetBufferForOtpDataAtStartCmd(nCh, nTotalSize: Integer);
begin
  m_OtpData[nCh].Size  := nTotalSize;
  SetLength(m_OtpData[nCh].Data,nTotalSize);
end;

procedure TCommCamera.TCPServerConnect(AContext: TIdContext);
var
  nCh: Integer;
begin
  AContext.Connection.IOHandler.ReadTimeout:= 3000;
  AContext.Connection.IOHandler.ConnectTimeout:= 3000;
  //nCh:= GetChannelByIP(AContext.Connection.Socket.Binding.PeerIP);
  nCh:= GetChannelByPort(AContext.Connection.Socket.Binding.Port);
  CommandData[nCh].WaitingData:= False;
  SendMessageMain(MSG_MODE_CONNECT, nCh, DefCam.CAM_CONNECT_OK, 0, 'Client Connected');
end;

procedure TCommCamera.TCPServerDisconnect(AContext: TIdContext);
var
  nCh: Integer;
begin
  //nCh:= GetChannelByIP(AContext.Connection.Socket.Binding.PeerIP);
  nCh:= GetChannelByPort(AContext.Connection.Socket.Binding.Port);
  try
    with m_idTCPServer[nCh].Contexts.LockList do begin
      if IndexOf(AContext) <> -1 then begin
        try
          AContext.Connection.Disconnect;
          //AContext.Connection.DisconnectNotifyPeer;
        except

        end;
      end;
    end;
    m_idTCPServer[nCh].Contexts.Clear
  finally
    m_idTCPServer[nCh].Contexts.UnlockList;
  end;

  CommandData[nCh].WaitingData:= False;
  SendMessageMain(MSG_MODE_CONNECT, nCh, DefCam.CAM_CONNECT_NG, 0, 'Client Disconnected');
end;

procedure TCommCamera.TCPServerException(AContext: TIdContext; AException: Exception);
var
  nCh: Integer;
begin
  nCh:= GetChannelByPort(AContext.Connection.Socket.Binding.Port);
  SendMessageTest(MSG_MODE_WORKING, nCh, 1, 0, AException.Message);
end;

procedure TCommCamera.TCPServerExecute(AContext: TIdContext);
var
  nCh: Integer;
  ReadBuffer: TidBytes;
begin
  if AContext.Connection.IOHandler.InputBufferIsEmpty then begin
    AContext.Connection.IOHandler.CheckForDataOnSource(1000);
  end;
  if not AContext.Connection.IOHandler.InputBufferIsEmpty then begin
    //nCh:= GetChannelByIP(AContext.Connection.Socket.Binding.PeerIP);
    //Sleep(100); //Wait Long Payload
    nCh:= GetChannelByPort(AContext.Connection.Socket.Binding.Port);

    AContext.Connection.IOHandler.InputBuffer.ExtractToBytes(ReadBuffer);
    ProcessData(nCh, Length(ReadBuffer), ReadBuffer, AContext);
  end
end;


procedure TCommCamera.TCPServerStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
  //nCh:= GetChannelByPort(AContext.Connection.Socket.Binding.Port);
  //SendMessageTest(MSG_MODE_WORKING, 0, 0, 0, AStatusText);
  SendMessageMain(MSG_MODE_WORKING, 0, 0, 0, AStatusText);
end;

procedure TCommCamera.tmrHearBeatTimer(Sender: TObject);
var
  i: Integer;
begin
  if (GetTickCount - m_nTickLast) > 10000 then begin
    for i := 0 to MAX_COUNT_CAMERA do begin
      SendCommand(i, 'PING');
    end;
    //SendDataAll('PING');
  end;
end;

end.
