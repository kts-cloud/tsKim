unit DllMesCom;

interface

uses Winapi.Windows, System.Classes, System.SysUtils,  IdGlobal,Vcl.ExtCtrls,
   Messages, Vcl.Dialogs,DefCommon,CommonClass,AnsiStrings;



type
  TCallBackSend_Data =  procedure (sMsg : PAnsiChar); cdecl;
  TCallBackReturn_Data =  procedure (sMsg : PAnsiChar); cdecl;
  TCallBackLog =  procedure (nMsgTpye : integer; sMsg : PAnsiChar); cdecl;
  TCommTibRvMessageReceive = procedure(ASender: TObject; const sMessage: WideString) of object;

  PGuiDLL = ^RGuiDLL;
  RGuiDLL = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    Param  : Integer;
    Param2 : Integer;
    Msg     : string;
    pData   : PBYTE; //Pointer; //Length = Param2
  end;





  TCommTibRv64 = class(TObject)
    private
      m_hDll  : HWND;
      m_nServer_Cnt : integer;
      FNgMsg : string;
      FReturnMsg: string;
      bReady : Boolean;
      sService : string;
      sNetwork : string;
      sDaemon  : string;
      sLocal   : string;
      sRemote  : string;
      sSend_Msg : string;

      sSend_Mode : string;
      bAck_Return : Boolean;
      Return_Msg  : string;


      m_Create_TIB : function(nCount : Integer): Boolean;
      m_Initialize : function (nCh : integer;  sAddr: PAnsiChar) : Boolean ; cdecl;
      m_Send_Data : function (nCh : integer; sMsg: PAnsiChar): Boolean; cdecl;
      m_Send_Data_New : function (nCh,nLength,CheckSum : integer; sMsg: PAnsiChar): Boolean; cdecl;
      m_SetCallback_Return_MES : procedure ( CaallbackFunction : TCallBackReturn_Data);cdecl;
      m_SetCallback_Return_EAS : procedure ( CaallbackFunction : TCallBackReturn_Data);cdecl;
      m_SetCallback_Return_R2R : procedure ( CaallbackFunction : TCallBackReturn_Data);cdecl;

      m_SetCallback_Log : procedure (CaallbackFunction : TCallBackLog);cdecl;
      m_Terminate : procedure(nCH : integer) ; cdecl;


      CB_Send_Data          : TCallBackSend_Data;
      CB_Return_Data        : TCallBackReturn_Data;
      CB_Log                : TCallBackLog;
      procedure SetFunction;
      procedure LOG(nMsgTpye : Integer; sMLOG : string);
      procedure SendMainGuiDisplay(nGuiMode: Integer; sMsg: string; nParam: Integer);
      function StringToPAnsiChar(AString: string): PAnsiChar;

    public
      m_MainHandle : HWND;
      m_TestHandle : HWND;
      bISLOG : Boolean;
      sLogPath : string;
      constructor Create(hMain: HWND;sDLLPath, sFileName: string;  nServerCnt : integer);

      destructor Destroy; override;
      function Initialize(nCh : integer; ServicePort,Network,Deamon_Port,Local_Subject,Remote_Subject : string): Boolean;
      function Send_Data(nCH : Integer; sMsg : string): Boolean;
      procedure SetCallBack;
      procedure Terminate;


  end;

    procedure MyCB_Log(nMsgTpye : integer; sAddedText : PAnsiChar);
    procedure MyCB_MESReturnMsg(sAddedText : PAnsiChar);
    procedure MyCB_EasReturnMsg(sAddedText : PAnsiChar);
    procedure MyCB_R2RReturnMsg(sAddedText : PAnsiChar);
  var
    CommTibRv :TCommTibRv64;



implementation



uses GMesCom;

{ TCommTibRv64 }

constructor TCommTibRv64.Create(hMain: HWND; sDLLPath, sFileName: string; nServerCnt : integer);
var
sDllFile : string;
begin
  sDllFile := sDLLPath+sFileName;
  bISLOG := false;
  m_MainHandle := hMain;

  m_nServer_Cnt := nServerCnt;

  m_hDll := 0;
  if FileExists(sDllFile) then m_hDll := LoadLibrary(PChar(sDllFile))
  else                         FNgMsg := '[' + sDLLPath + ']' + #13#10 + ' Cannot find the file.!';
  if m_hDll = 0 then begin
    FNgMsg := ' loadlibrary returns 0';
    Exit;
  end;
  SetFunction;

  m_Create_TIB(nServerCnt); // Added by KTS 2023-02-01 ¿ÀÀü 8:07:59

end;

procedure TCommTibRv64.SendMainGuiDisplay(nGuiMode: Integer; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiDLL;
begin
  GuiData.MsgType := MSG_TYPE_NONE;
  GuiData.Channel := 4;
  GuiData.Mode    := nGuiMode;
  GuiData.Param := nParam;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_MainHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TCommTibRv64.LOG(nMsgTpye : integer; sMLOG : string);
begin
  if Length(sMLOG) > 600 then
    sMLOG := Copy(sMLOG,1,600);
  SendMainGuiDisplay(MSG_MODE_ADDLOG,sMLOG,nMsgTpye);
end;


procedure MyCB_Log(nMsgTpye : integer; sAddedText : PAnsiChar);
var
sMLOG : string;
begin
//  if Length(PAnsiChar(sAddedText)) > 600 then
//    sMLOG := Copy(PAnsiChar(sAddedText),1,600)
//  else sMLOG := PAnsiChar(sAddedText);
//  CommTibRv.LOG(nMsgTpye,sMLOG);
end;


procedure MyCB_MESReturnMsg(sAddedText : PAnsiChar);
begin
  if DongaGmes <> nil then
    DongaGmes.ReadMsgHost64(sAddedText);
end;


procedure MyCB_EasReturnMsg(sAddedText : PAnsiChar);
begin
  if DongaGmes <> nil then
    DongaGmes.ReadMsgEas64(sAddedText);
end;

procedure MyCB_R2RReturnMsg(sAddedText : PAnsiChar);
begin
  if DongaGmes <> nil then
    DongaGmes.ReadMsgR2R64(sAddedText);
end;


destructor TCommTibRv64.Destroy;
begin
  inherited;
end;

function TCommTibRv64.StringToPAnsiChar(AString: string): PAnsiChar;
var
MyPAnsiChar: PAnsiChar;
begin

  Result := PAnsiChar(AnsiString(AString));
end;

procedure TCommTibRv64.Terminate;
var
i : Integer;
begin
  for I := 0 to Pred(m_nServer_Cnt) do
    m_Terminate(i);
end;

procedure TCommTibRv64.SetCallBack;
begin
  m_SetCallback_Log(@MyCB_Log);
  m_SetCallback_Return_MES(@MyCB_MESReturnMsg);
  m_SetCallback_Return_EAS(@MyCB_EasReturnMsg);
  m_SetCallback_Return_R2R(@MyCB_R2RReturnMsg);

end;

function TCommTibRv64.Initialize(nCh : integer; ServicePort, Network, Deamon_Port, Local_Subject, Remote_Subject: string): Boolean;
var
sAddr : string;
begin
  sAddr := ServicePort + ',' + Network + ',' + Deamon_Port+ ',' +Local_Subject + ',' +Remote_Subject + ',' + sLogPath;
  Result :=  m_Initialize(nCh, StringToPAnsiChar(sAddr));
end;

function TCommTibRv64.Send_Data(nCH : integer; sMsg: string): Boolean;
var
bRet : boolean;
dCheckSum: dword;
begin
  if @m_Send_Data_New <> nil then begin
    dCheckSum := Common.crc16(sMsg,Length(sMsg));
    bRet := m_Send_Data_New(nCH,sMsg.Length,dCheckSum, StringToPAnsiChar(sMsg));
    if not bRet then
      bRet := m_Send_Data_New(nCH,sMsg.Length,dCheckSum, StringToPAnsiChar(sMsg));
    Result := bRet;
  end
  else begin
    bRet := m_Send_Data(nCH, StringToPAnsiChar(sMsg));
    if not bRet then
      bRet := m_Send_Data(nCH, StringToPAnsiChar(sMsg));
    Result := bRet;
  end;
end;

procedure TCommTibRv64.SetFunction;
begin
 @m_Create_TIB := GetProcAddress(m_hDll, 'Create_TIB');
 @m_Initialize := GetProcAddress(m_hDll, 'Init_TIB');
 @m_SetCallback_Log := GetProcAddress(m_hDll, 'Callback_Log');
 @m_Send_Data := GetProcAddress(m_hDll, 'Send_Data');
 @m_Send_Data_New := GetProcAddress(m_hDll, 'Send_Data_New');
 @m_SetCallback_Return_MES := GetProcAddress(m_hDll, 'Callback_ReturnMsgMES');
 @m_SetCallback_Return_EAS := GetProcAddress(m_hDll, 'Callback_ReturnMsgEAS');
 @m_SetCallback_Return_R2R := GetProcAddress(m_hDll, 'Callback_ReturnMsgR2R');
 @m_Terminate := GetProcAddress(m_hDll, 'Terminate');

end;



end.
