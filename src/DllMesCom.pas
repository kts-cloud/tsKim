unit DllMesCom;

interface

uses Winapi.Windows, System.Classes, System.SysUtils,  IdGlobal,Vcl.ExtCtrls,
   Messages, Vcl.Dialogs,DefCommon;



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
    nParam  : Integer;
    nParam2 : Integer;
    Msg     : string;
  end;


  TCommTibRv64 = class(TObject)
    private
      m_hDll  : HWND;
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


      procedure SendTestGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
      function StringToPAnsiChar(AString: string): PAnsiChar;

    public
      m_MainHandle : HWND;
      m_TestHandle : HWND;
      bISLOG : Boolean;
      sLogPath : string;
      constructor Create(hMain: HWND;sDLLPath, sFileName: string);

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

constructor TCommTibRv64.Create(hMain: HWND; sDLLPath, sFileName: string);
var
sDllFile : string;
begin
  sDllFile := sDLLPath+sFileName;
  bISLOG := false;
  m_MainHandle := hMain;


  m_hDll := 0;
  if FileExists(sDllFile) then m_hDll := LoadLibrary(PChar(sDllFile))
  else                         FNgMsg := '[' + sDLLPath + ']' + #13#10 + ' Cannot find the file.!';
  if m_hDll = 0 then begin
    FNgMsg := ' loadlibrary returns 0';
    Exit;
  end;
  SetFunction;

  m_Create_TIB(TIBServer_MAX); // Added by KTS 2023-02-01 ¿ÀÀü 8:07:59

end;

procedure TCommTibRv64.SendTestGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiDLL;
begin
  GuiData.MsgType := MSG_TYPE_NONE;
  GuiData.Channel := nCh;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam := nParam;
  GuiData.Msg     := sMsg;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_MainHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TCommTibRv64.LOG(nMsgTpye : integer; sMLOG : string);
var
  th : TThread;
  sLog : string;
begin
  SendTestGuiDisplay(0,MSG_MODE_ADDLOG,sMLOG,nMsgTpye);
end;



procedure MyCB_Log(nMsgTpye : integer; sAddedText : PAnsiChar);
begin
  CommTibRv.LOG(nMsgTpye,PAnsiChar(sAddedText));
end;


procedure MyCB_MESReturnMsg(sAddedText : PAnsiChar);
begin
  if DongaGmes <> nil then
    DongaGmes.ReadMsgHost64(PAnsiChar(sAddedText));
end;


procedure MyCB_EasReturnMsg(sAddedText : PAnsiChar);
begin
  if DongaGmes <> nil then
    DongaGmes.ReadMsgEas64(PAnsiChar(sAddedText));
end;

procedure MyCB_R2RReturnMsg(sAddedText : PAnsiChar);
begin
  if DongaGmes <> nil then
    DongaGmes.ReadMsgR2R64(PAnsiChar(sAddedText));
end;


destructor TCommTibRv64.Destroy;
begin
  inherited;
end;

function TCommTibRv64.StringToPAnsiChar(AString: string): PAnsiChar;
begin
  Result := PAnsiChar(AnsiString(AString));
end;

procedure TCommTibRv64.Terminate;
var
i : Integer;
begin
  for I := 0 to Pred(TIBServer_MAX) do
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
begin
  Result := m_Send_Data(nCH,StringToPAnsiChar(sMsg));
end;

procedure TCommTibRv64.SetFunction;
begin
 @m_Create_TIB := GetProcAddress(m_hDll, 'Create_TIB');
 @m_Initialize := GetProcAddress(m_hDll, 'Init_TIB');
 @m_SetCallback_Log := GetProcAddress(m_hDll, 'Callback_Log');
 @m_Send_Data := GetProcAddress(m_hDll, 'Send_Data');
 @m_SetCallback_Return_MES := GetProcAddress(m_hDll, 'Callback_ReturnMsgMES');
 @m_SetCallback_Return_EAS := GetProcAddress(m_hDll, 'Callback_ReturnMsgEAS');
 @m_SetCallback_Return_R2R := GetProcAddress(m_hDll, 'Callback_ReturnMsgR2R');
 @m_Terminate := GetProcAddress(m_hDll, 'Terminate');

end;



end.
