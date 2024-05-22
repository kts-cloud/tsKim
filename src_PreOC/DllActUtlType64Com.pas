unit DllActUtlType64Com;

interface

uses Winapi.Windows, System.Classes, System.SysUtils,Vcl.ExtCtrls,
   Messages, Vcl.Dialogs,DefCommon;


type


  PGuiDLL = ^RGuiDLL;
  RGuiDLL = packed record
    MsgType : Integer;
    Channel : Integer;
    Mode    : Integer;
    nParam  : Integer;
    nParam2 : Integer;
    Msg     : string;
  end;


  TDLLActUtlType64 = class(TObject)
    private
      m_hDll  : HWND;
      FNgMsg : string;

      m_Create_ActTpye64 : procedure; cdecl;
      m_SetActLogicalStationNumber : procedure (nLogicalStationNumber : integer); cdecl;
      m_Open : function : integer; cdecl;
      m_Close : function : integer; cdecl;
      m_GetDevice : procedure(sDeviceName : PAnsiChar;const arrDeviceValue : PInteger; var nReturnCode : Integer); cdecl;
      m_SetDevice : procedure(sDeviceName : PAnsiChar; const arrDeviceValue : PInteger; var nReturnCode : Integer); cdecl;
      m_ReadDeviceBlock : procedure(sDeviceName : PAnsiChar; iNumberOfData : Integer; const  arrDeviceValue : PInteger; var nReturnCode : Integer); cdecl;
      m_WriteDeviceBlock : procedure(sDeviceName : PAnsiChar; iNumberOfData : Integer; const arrDeviceValue : PInteger; var nReturnCode : Integer); cdecl;
      m_ReadBuffer : procedure(lStartIO: Integer; lAddress: Integer; lSize: Integer;const  lpsData: PSmallint; var nReturnCode : Integer); cdecl;
      m_WriteBuffer : procedure(lStartIO: Integer; lAddress: Integer; lSize: Integer; const lpsData: PSmallint; var nReturnCode : Integer); cdecl;
      m_GetClockData : procedure (out lpsYear, lpsMonth, lpsDay, lpsDayOfWeek,lpsHour, lpsMinute, lpsSecond: Smallint; var nReturnCode : Integer); cdecl;




      procedure SetFunction;


      procedure SendTestGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
      function StringToPAnsiChar(AString: string): PAnsiChar;

    public
      m_MainHandle : HWND;
      m_TestHandle : HWND;

      constructor Create(hMain: HWND;sDLLPath, sFileName: string);

      destructor Destroy; override;
      procedure Create_ActTpye64;
      procedure SetActLogicalStationNumber(nLogicalStationNumber : Integer);
      function open: Integer;
      function Close: Integer;
      procedure GetDevice( sDeviceName : string; var arrDeviceValue : Integer; var nReturnCode : Integer);
      procedure SetDevice( sDeviceName : string; var arrDeviceValue : Integer; var nReturnCode : Integer);
      procedure ReadDeviceBlock( sDeviceName : string; iNumberOfData : Integer;var arrDeviceValue,nReturnCode :Integer);
      procedure WriteDeviceBlock( sDeviceName : string; iNumberOfData : Integer; var arrDeviceValue,nReturnCode : Integer);
      procedure ReadBuffer(lStartIO: Integer; lAddress: Integer; lSize: Integer;  var lpsData: Smallint; var nReturnCode : Integer);
      procedure WriteBuffer(lStartIO: Integer; lAddress: Integer; lSize: Integer; var lpsData: Smallint; var nReturnCode : Integer);
      procedure GetClockData(out lpsYear, lpsMonth, lpsDay, lpsDayOfWeek,lpsHour, lpsMinute, lpsSecond: Smallint; var nReturnCode : Integer);
 end;





implementation


uses
Test4ChOC;





constructor TDLLActUtlType64.Create(hMain: HWND; sDLLPath, sFileName: string);
var
sDllFile : string;
begin
  sDllFile := sDLLPath+sFileName;
  m_MainHandle := hMain;

  m_hDll := 0;
  if FileExists(sDllFile) then m_hDll := LoadLibrary(PChar(sDllFile))
  else                         FNgMsg := '[' + sDLLPath + ']' + #13#10 + ' Cannot find the file.!';
  if m_hDll = 0 then begin
    FNgMsg := ' loadlibrary returns 0';
    Exit;
  end;
  SetFunction;


end;

procedure TDLLActUtlType64.SendTestGuiDisplay(nCh,nGuiMode: Integer; sMsg: string; nParam: Integer);
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


procedure TDLLActUtlType64.SetActLogicalStationNumber(nLogicalStationNumber : Integer);
begin
  m_SetActLogicalStationNumber(nLogicalStationNumber);
end;


procedure TDLLActUtlType64.Create_ActTpye64;
begin
  m_Create_ActTpye64;
end;

function TDLLActUtlType64.open: Integer;
begin
  Result := m_Open;
end;

function TDLLActUtlType64.Close: Integer;
begin
  Result := m_Close;
end;


procedure TDLLActUtlType64.GetClockData(out lpsYear, lpsMonth, lpsDay, lpsDayOfWeek, lpsHour, lpsMinute, lpsSecond: Smallint; var nReturnCode :Integer );
begin
  m_GetClockData(lpsYear,lpsMonth,lpsDay,lpsDayOfWeek,lpsHour,lpsMinute,lpsSecond,nReturnCode);
end;

procedure TDLLActUtlType64.GetDevice( sDeviceName : string; var arrDeviceValue: Integer; var nReturnCode : Integer);
begin
   m_GetDevice(StringToPAnsiChar(sDeviceName),@arrDeviceValue,nReturnCode);
end;

procedure TDLLActUtlType64.SetDevice( sDeviceName : string; var arrDeviceValue: Integer; var nReturnCode : Integer);
begin
  m_SetDevice(StringToPAnsiChar(sDeviceName),@arrDeviceValue,nReturnCode);
end;

procedure TDLLActUtlType64.ReadDeviceBlock( sDeviceName : string; iNumberOfData : Integer;var arrDeviceValue,nReturnCode : integer);
begin
   m_ReadDeviceBlock(StringToPAnsiChar(sDeviceName),iNumberOfData,@arrDeviceValue,nReturnCode);
end;



procedure TDLLActUtlType64.WriteDeviceBlock( sDeviceName : string; iNumberOfData : Integer; var arrDeviceValue,nReturnCode : Integer);
begin
   m_WriteDeviceBlock(StringToPAnsiChar(sDeviceName),iNumberOfData,@arrDeviceValue,nReturnCode);
end;


procedure TDLLActUtlType64.ReadBuffer(lStartIO, lAddress,lSize: Integer; var lpsData: Smallint; var nReturnCode : integer);
begin
  m_ReadBuffer(lStartIO,lAddress,lSize,@lpsData,nReturnCode);
end;

procedure TDLLActUtlType64.WriteBuffer(lStartIO, lAddress, lSize: Integer; var lpsData: Smallint; var nReturnCode : integer);
begin
  m_WriteBuffer(lStartIO,lAddress,lSize,@lpsData,nReturnCode);
end;




destructor TDLLActUtlType64.Destroy;
begin
  inherited;
end;

function TDLLActUtlType64.StringToPAnsiChar(AString: string): PAnsiChar;
begin
  Result := PAnsiChar(AnsiString(AString));
end;





procedure TDLLActUtlType64.SetFunction;
begin
 @m_Create_ActTpye64 := GetProcAddress(m_hDll, 'Create_ActTpye64');
 @m_SetActLogicalStationNumber := GetProcAddress(m_hDll, 'SetActLogicalStationNumber');
 @m_Open := GetProcAddress(m_hDll, 'Open');
 @m_Close := GetProcAddress(m_hDll, 'Close');
 @m_GetDevice := GetProcAddress(m_hDll, 'GetDevice');
 @m_SetDevice := GetProcAddress(m_hDll, 'SetDevice');
 @m_ReadDeviceBlock := GetProcAddress(m_hDll, 'ReadDeviceBlock');
 @m_WriteDeviceBlock := GetProcAddress(m_hDll, 'WriteDeviceBlock');
 @m_ReadBuffer := GetProcAddress(m_hDll, 'ReadBuffer');
 @m_WriteBuffer := GetProcAddress(m_hDll, 'WriteBuffer');
 @m_GetClockData  := GetProcAddress(m_hDll, 'GetClockData');

end;



end.
