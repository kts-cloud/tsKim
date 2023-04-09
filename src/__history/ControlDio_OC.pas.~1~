unit ControlDio_OC;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,  System.Classes, VaComm, Vcl.Controls, Vcl.Dialogs,
  CommDIO_DAE, DefDio, DefCommon, CommonClass, Vcl.ExtCtrls, CommIonizer, DoorOpenAlarmMsg;


const
  MSG_MODE_DISPLAY_START  = CommDIO_DAE.COMMDIO_MSG_MAX;
  MSG_MODE_DISPLAY_ALARAM = MSG_MODE_DISPLAY_START + 1;
  MSG_MODE_SYSTEM_ALARAM  = MSG_MODE_DISPLAY_START + 2;
  MSG_MODE_DISPLAY_IO     = MSG_MODE_DISPLAY_START + 3;
  MSG_MODE_STAGE_TURN  = MSG_MODE_DISPLAY_START + 4;

  CONTROLDIO_ALARM_NONE  = 0;
  CONTROLDIO_ALARM_LIGHT = 1;
  CONTROLDIO_ALARM_HEAVY = 2;
type

  TLoadZoneStage = (lzsNone, lzsA, lzsB);

  TControlDio = class(TObject)
  private
    m_nMsgType : Integer;
    m_hMain : HWND;
    tmrCycle : TTimer;
    m_PreLoadZoneStage : TLoadZoneStage;
    m_bIoThreadWork : boolean;
    m_nStageToFront : Integer;
    m_bConnected: Boolean; // A jig front 방향 ==> None(0). A jig Front (1), B Jig front 2.
    m_bDoorOpen : Boolean;
    m_nTowerLampState: Integer;
    m_nTowerLampTick: Cardinal;

    function ErrorCheck : Integer;
    function CheckAlarm: Integer;
    function CheckState: Integer;
    function WriteCheck(nIdx : Integer) : Integer;
    procedure SendMsgMain(nMsgMode: Integer; nParam, nParam2: Integer; sMsg: String; pData:Pointer=nil);
    procedure SetAlarmMsg(nIdx : Integer; bIsDisplayMessage : Boolean = True);
    procedure SendAlarm(nType, nIndex, nValue: Integer; sMsg:String='');
    function CheckDi(nIdx : Integer) : Boolean;


    procedure tmrCycleTimer(Sender : TObject);
    procedure TaskThread(task : TProc);
    procedure TaskThreadTerminiate(Sender : TObject);
    procedure CommDIONotify(Sender: TObject; pDataMessage: PGuiDaeDio);
    procedure Process_ChangedDI(pDataMessage: PGuiDaeDio);
    function WaitSignal(nIndex, nValue: Byte; nWaitTime: Cardinal): Cardinal;


  public
    DioAlarmData : array[0 .. DefDio.MAX_ALARM_DATA_SIZE] of Integer;
    LastNgMsg : string;
    LoadZoneStage : TLoadZoneStage;
    UseTowerLamp: Boolean;
    MelodyOn: Boolean;
    // 0 : Loading(first Start) ==> 1 : Camera ==> 2 : Unloading ==> 1 : Camera.
    //ZoneStatus : array[DefCommon.JIG_A .. DefCommon.JIG_B] of Integer;
    constructor Create(hMain :HWND; nMsgType : Integer); virtual;
    destructor Destroy; override;

    procedure RefreshIo;
    procedure ResetError(nIdx : Integer);

    procedure BackgroundErrorCheck;
    /// <summary> Load Clamp & Shutter up ==> OK ==> Turn Stage ==> Arrived the Stage ==> Unload Clamp & Shuttern Dn </summary>
    /// <param name='bIsAStage'> True : A Stage , False : B Stage</param>
//    function TurnStage(bIsAStage: Boolean) : Integer;
    /// <summary> Clamp Down - Clamp Down Ok - Pogo Up - Pogo Up Ok </summary>
    /// <param name='nCh'> Channel (1~8) , 9( A Stage ) , 10 ( B Stage ) (SendMessage)</param>
    /// <param name='bCheckClampDn'> Default : False, Clamp Down 신호만 Check : True </param>
//    function ContactUp(nCh : Integer; bCheckClampDn : Boolean = False) : Integer;
    /// <summary> Pogo Down - Pogo Down Ok - Clamp Up - Clamp Up Ok </summary>
    /// <param name='nCh'> Channel (1~8)  (SendMessage)</param>
//    function ContactDown(nCh : Integer) : Integer;
//    function ClampDown(nCh : Integer) : Integer;
//    function ClampUp(nCh : Integer) : Integer;
//    function PogoDown(nCh : Integer) : Integer;
//    function PogoUp(nCh : Integer) : Integer;

    function UnlockCarrier(nCh: Integer; bMainter : Boolean): Integer; // Added by KTS 2022-10-26 오전 10:17:58   OC UnlockCarrier Flow
    function LockCarrier(nCh: Integer; bMainter : Boolean): Integer;   // Added by KTS 2022-10-26 오전 10:33:47   OC LockCarrier Flow
    function ProbeForward(nCh: Integer): Integer; // Added by KTS 2022-10-28 오전 11:41:06    OC ProbeForward FLow
    function ProbeBackward(nCh: Integer): Integer; // Added by KTS 2022-11-14 오전 9:54:19    OC ProbeBackward Flow

    function MovingProbe(nGroup: Integer; bIsUp : Boolean): Integer; // Added by KTS 2022-10-28 오전 11:41:06         Pre OC ProbeUP FLow
    function UnlockPinBlock(nCh: Integer): Integer;// Added by KTS 2022-11-28 오후 2:24:14  Pre OC Pinblack backward flow
    function LockPinBlock(nCh: Integer): Integer;// Added by KTS 2022-11-28 오후 2:24:14  Pre OC Pinblack backward flow
    function CLOSE_Up_PinBlock(nCh: Integer): Integer;
    function CLOSE_Dn_PinBlock(nCh: Integer): Integer;
    function VaccumON(nCh: Integer): Integer;
    function VaccumOFF(nCh: Integer): Integer;
    function LampOnOff(nGroup : integer;  bIsOnOff : Boolean): Integer;
    function CheckDIO_Start(nCH: Integer): Boolean;
    /// <summary> Shutter Up & Down </summary>
    /// <param name='bIsUp'> True : Up, False : Down. (SendMessage)</param>
    function MovingShutter(nGroup : Integer; bIsUp : Boolean) : Integer;      // Added by KTS 2022-10-31 오전 10:12:19
    /// <summary> Side Door 잠금해제 </summary>
    function UnlockDoorOpen(nch: Integer; bUnlock: Boolean): Boolean;
    /// <summary> DO OUT signal to write </summary>
    /// <param name='nSignal'> 0~64. </param>
    /// <param name='bIsRemove'> True : Remove the signal, False : Add the signal, Default is False. </param>
    function WriteDioSig(nSignal : Integer; bIsRemove : Boolean = False) : Integer;
    procedure ClearOutDioSig(nSig : Integer);
    /// <summary> DI In signal to write </summary>
    /// <param name='nSignal'> 0~64. </param>
    function ReadInSig(nSignal : Integer) : Boolean;
    function ReadOutSig(nSignal : Integer) : Boolean;
    function IsDetected(nCH: Integer): Boolean;
//    procedure ThreadTurnStage;
    procedure DisplayIo;
    procedure Set_AlarmData(nIndex, nValue: Integer);
    procedure Set_TowerLampState(nState: Integer);
    procedure test;
    property Connected : Boolean read m_bConnected;
  end;


var
  ControlDio: TControlDio;

implementation
uses pasScriptClass;

{ TControlDio }

procedure TControlDio.BackgroundErrorCheck;
var
  thBG : TThread;
begin
  thBG := TThread.CreateAnonymousThread(procedure begin
    ErrorCheck;
  end);
  thBG.Start;
end;

function TControlDio.CheckAlarm: Integer;
var
  nRet,i : Integer;
  nAlarmNo: Integer;
  bDoorOpen : Boolean;
begin
  nRet := DefDio.ERR_LIST_START;
  // Reset... Clear 되더라도 누적 되면 ...
  if not CommDaeDIO.Connected then begin
    LastNgMsg := 'Disconnected DIO Card....';
    SendMsgMain(ControlDio_OC.MSG_MODE_SYSTEM_ALARAM, ERR_LIST_DIO_CARD_DISCONNECTED,0,LastNgMsg);
    m_bConnected := False;
    Exit(DefDio.ERR_LIST_DIO_CARD_DISCONNECTED);
  end;

  // Check Input IO.

  if Common.SystemInfo.OCType = DefCommon.OCType  then begin

    nAlarmNo:= DefDio.IN_MC_MONITORING;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;
  //
    nAlarmNo:= DefDio.IN_EMO_SWITCH;
    if CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;
    // Door Open Alarm Message Check.
    nAlarmNo:= DefDio.IN_CH_1_2_DOOR_LEFT_OPEN;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 2);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 2);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_CH_3_4_DOOR_LEFT_OPEN;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 2);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 2);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;



    nAlarmNo:= DefDio.IN_CYL_PRESSURE_GAUGE;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_TEMPERATURE_ALARM;
    if CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST+1;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST+2;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST+3;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;
  end
  else begin

    nAlarmNo:= DefDio.IN_GIB_CH_12_EMO_SWITCH;
    if  CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_GIB_CH_34_EMO_SWITCH;
    if  CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST+1;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST+2;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_FAN_1_EXHAUST+3;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo := DefDio.IN_GIB_CH_12_LIGHTCURTAIN;
    if (not CheckDi(DefDio.IN_GIB_CH_12_LIGHTCURTAIN)) and (not CheckDi(DefDio.IN_GIB_CH_12_MUTING_LAMP)) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_DISPLAY_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_DISPLAY_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo := DefDio.IN_GIB_CH_34_LIGHTCURTAIN;
    if not CheckDi(DefDio.IN_GIB_CH_34_LIGHTCURTAIN) and (not CheckDi(DefDio.IN_GIB_CH_34_MUTING_LAMP)) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_DISPLAY_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_DISPLAY_ALARAM, nAlarmNo, 0);
    end;


    nAlarmNo:= DefDio.IN_GIB_CH_12_MC_MONITORING;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_GIB_CH_34_MC_MONITORING;
    if not CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_GIB_TEMPERATURE_ALARM;
    if CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

    nAlarmNo:= DefDio.IN_GIB_CYL_PRESSURE_GAUGE;
    if CheckDi(nAlarmNo) then begin
      nRet := nAlarmNo;
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 1);
    end
    else begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, nAlarmNo, 0);
    end;

  end;


  Result := nRet;
end;

function TControlDio.CheckDi(nIdx: Integer): Boolean;
var
  nDiv, nMod : Integer;
begin
  nDiv := nIdx div 8; nMod := nIdx mod 8;
  Result :=  (CommDaeDIO.DIData[nDiv] and (1 shl nMod)) > 0;
end;



function TControlDio.CheckState: Integer;
begin
//  if ReadInSig(DefDio.IN_B_STAGE_IN_CAM) then  begin
//    LoadZoneStage := lzsA;
//    if not ReadInSig(DefDio.IN_MORTOR_STOP_SENSOR) then begin
//      ClearOutDioSig(OUT_A_STAGE_FRONT);
//      ClearOutDioSig(OUT_B_STAGE_FRONT);
//    end;
//  end
//  else if ReadInSig(DefDio.IN_A_STAGE_IN_CAM) then  begin
//    LoadZoneStage := lzsB;
//    if not ReadInSig(DefDio.IN_MORTOR_STOP_SENSOR) then begin
//      ClearOutDioSig(OUT_A_STAGE_FRONT);
//      ClearOutDioSig(OUT_B_STAGE_FRONT);
//    end;
//  end
//  else begin
//    LoadZoneStage:= lzsNone;
//  end;
//
//  if not ReadInSig(DefDio.IN_MORTOR_STOP_SENSOR) and ReadInSig(DefDio.IN_A_STAGE_IN_CAM) then begin
//    ClearOutDioSig(OUT_A_STAGE_FRONT);
//    ClearOutDioSig(OUT_B_STAGE_FRONT);
//  end;
//
//  if not ReadInSig(DefDio.IN_MORTOR_STOP_SENSOR) and ReadInSig(DefDio.IN_B_STAGE_IN_CAM) then begin
//    ClearOutDioSig(OUT_A_STAGE_FRONT);
//    ClearOutDioSig(OUT_B_STAGE_FRONT);
//  end;

//  if ReadInSig(DefDio.IN_SHUTTER_UP_SENSOR) then begin
//    ClearOutDioSig(OUT_SHUTTER_UP_SOL);
//  end;
//
//  if ReadInSig(DefDio.IN_SHUTTER_DN_SNENSOR) then begin
//    ClearOutDioSig(OUT_SHUTTER_DN_SOL);
//  end;
end;

function TControlDio.LampOnOff(nGroup: integer; bIsOnOff: Boolean): Integer;
begin
  case nGroup of
    DefCommon.CH_TOP : begin
      WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,bIsOnOff);
      if Common.SystemInfo.OCType = DefCommon.OCType then  WriteDioSig(DefDio.OUT_CH_1_2_BACK_DOOR_LAMPON,bIsOnOff);
    end;

    DefCommon.CH_BOTTOM : begin
      WriteDioSig(DefDio.OUT_CH_3_4_LAMP_OFF,bIsOnOff);
      if Common.SystemInfo.OCType = DefCommon.OCType then WriteDioSig(DefDio.OUT_CH_3_4_BACK_DOOR_LAMPON,bIsOnOff);
    end;
  end;
end;


function TControlDio.CheckDIO_Start(nCH: Integer): Boolean;
var
bRet : Boolean;
i : Integer;
begin
  Result := True;
  for I := nCH *2  to nCH * 2 +1 do  begin

    if ( ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_OPEN_SENSOR +i*8))  then begin    //Close Dn 조건 확인
      Result := False;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, Format('CheckDIO_Start NG : %d',[i]));
      exit;
    end;

  end;

end;


function TControlDio.LockCarrier(nCh: Integer; bMainter : Boolean): Integer;
var
  i, j, nDiv : Integer;
  bRet : boolean;
  nWaitingCount: Integer;
begin
  Result := 1;
  nWaitingCount:= 80; //100ms * nWaitingCount

  if Common.SystemInfo.OCType <> DefCommon.OCType  then Exit(2);

  case nCh of
    DefCommon.CH_TOPGroup : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Start TOP_CH');

      ClearOutDioSig(DefDio.OUT_CH_1_CARRIER_UNLOCK_SOL );
      ClearOutDioSig(DefDio.OUT_CH_2_CARRIER_UNLOCK_SOL );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH2 do begin

        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +i*16)) then Continue;
        bRet := False;
      end;
      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Finish TOP_CH - Already');
        Exit(0);
      end;

      //Lock Carrier.
      WriteDioSig(DefDio.OUT_CH_1_CARRIER_LOCK_SOL,false );
      WriteDioSig(DefDio.OUT_CH_2_CARRIER_LOCK_SOL,false );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH2 do begin

        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +i*16)) then Continue;
        bRet := False;
      end;

      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH1 to DefCommon.CH2 do begin
            if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +j*16))  then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);
        for j := DefCommon.CH1 to DefCommon.CH2 do begin
          if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +j*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +j*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +j*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +j*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +j*16)) then Continue
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_SENSOR + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_1 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_2 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_3 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_4 + j*16, 1, '');
          Exit(2);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Finish TOP_CH');
    end;
    DefCommon.CH_BOTTOMGroup : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Start - BOTTOM_CH');
      ClearOutDioSig(DefDio.OUT_CH_3_CARRIER_UNLOCK_SOL );
      ClearOutDioSig(DefDio.OUT_CH_4_CARRIER_UNLOCK_SOL );

      bRet := True;
      for i := DefCommon.CH3 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +i*16)) then Continue;
        bRet := False;
      end;

      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Finish BOTTOM_CH - Already');
        Exit(0);
      end;

      // LockCarrier.

      WriteDioSig(DefDio.OUT_CH_3_CARRIER_LOCK_SOL,false );
      WriteDioSig(DefDio.OUT_CH_4_CARRIER_LOCK_SOL,false );

      bRet := True;
      for i := DefCommon.CH3 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +i*16)) then Continue;
        bRet := False;
      end;



      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH3 to DefCommon.CH4 do begin
            if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +j*16)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);

        for j := DefCommon.CH3 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +j*16)) then Continue
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_SENSOR + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_1 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_2 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_3 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_4 + j*16, 1, '');
          Exit(2);
        end;

      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Finish BOTTOM_CH');
    end
    else begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Start Ch=' + IntToStr(nCh));
      //Stage가 검사 존에 있을 경우 처리 안함
      (*
      if ReadInSig(DefDio.IN_A_STAGE_IN_CAM) and (nCh in [0,1,2,3])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      if ReadInSig(DefDio.IN_B_STAGE_IN_CAM) and (nCh in [4,5,6,7])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      *)
      nDiv := nCh;
      ClearOutDioSig(DefDio.OUT_CH_1_CARRIER_UNLOCK_SOL + nCh*16);

      if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +nCh*16)) and
          (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +nCh*16)) and
          (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +nCh*16)) and
          (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +nCh*16)) and
          (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +nCh*16)) then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Finish Ch=' + IntToStr(nCh) + ' - Already');
        Exit(0);
      end;

      //Clamp Down
      WriteDioSig(DefDio.OUT_CH_1_CARRIER_LOCK_SOL + nCh*16,false);

      if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +nCh*16)) and
          (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +nCh*16)) and
          (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +nCh*16)) and
          (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +nCh*16)) and
          (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +nCh*16)) then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +nCh*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +nCh*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +nCh*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +nCh*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +nCh*16)) then Break;
        end;
        Sleep(100);
        bRet := True;
//        if bMainter then begin
//          if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +nCh*16)) then begin
//            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_SENSOR + nCh*16, 1, '');
//            bRet := false;
//          end;
//        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_SENSOR + nCh*16, 1, '');
          bRet := false;
        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_1 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_1 + nCh*16, 1, '');
          bRet := false;
        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_2 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_2 + nCh*16, 1, '');
          bRet := false;
        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_3 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_3 + nCh*16, 1, '');
          bRet := false;
        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_LOCK_4 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_LOCK_4 + nCh*16, 1, '');
          bRet := false;
        end;
        if not bRet then Exit(2);

      end;

      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'LockCarrier Finish Ch=' + IntToStr(nCh));
    end;

  end;

  Result := 0;
end;


function TControlDio.LockPinBlock(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  if Common.SystemInfo.OCType <> DefCommon.PreOCType  then Exit(2);
  nWaitingCount:= 50; //100ms * nWaitingCount
  // Return ==> 0 : OK. 1 ==> NG.


  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'lock PinBlock  Start - CH = '+ IntToStr(nCh));

  bRet := True;

  if (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_UNLOCK_OF_SENSOR +nCh*8))  then     //Lock 조건 확인
   bRet := False;

  if bRet then begin
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'lock PinBlock Finish CH = '+ IntToStr(nCh)+ ' - Already');
    Exit(0);
  end;

  bRet := True;

  WriteDioSig(DefDio.OUT_GIB_CH_1_PINBLOCK_UNLOCK_SOL + nCh*8,false);

  for i := 0 to nWaitingCount do begin
    Sleep(100);
    if ( ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_UNLOCK_OF_SENSOR +nCh*8)) then Break;
  end;
  if  (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_UNLOCK_OF_SENSOR +nCh*8)) then begin
    SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PINBLOCK_UNLOCK_OF_SENSOR + nCh*8, 1, '');
    Exit(1);
  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Unlock PinBlock Finish CH = '+ IntToStr(nCh));

  Result := 0;
end;

function TControlDio.CLOSE_Dn_PinBlock(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  if Common.SystemInfo.OCType <> DefCommon.PreOCType  then Exit(2);
  nWaitingCount:= 50; //100ms * nWaitingCount
  // Return ==> 0 : OK. 1 ==> NG.

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PIN BLOCK CLOSE Prevention Down Start - CH = '+ IntToStr(nCh));

  bRet := True;

  if (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_DN_SENSOR +nCh*8))  then     //Close Dn 조건 확인
   bRet := False;

  if bRet then begin
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PIN BLOCK CLOSE Prevention Down Finish CH = '+ IntToStr(nCh)+ ' - Already');
    Exit(0);
  end;

  bRet := True;

  WriteDioSig(DefDio.OUT_GIB_CH_1_PINBLOCK_CLOSE_SOL + nCh*8,true);

  for i := 0 to nWaitingCount do begin
    Sleep(100);
    if ( ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_DN_SENSOR +nCh*8)) then Break;
  end;
  if  (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_DN_SENSOR +nCh*8)) then begin
    SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PINBLOCK_CLOSE_DN_SENSOR + nCh*8, 1, '');
    Exit(1);
  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PIN BLOCK CLOSE Prevention Down Finish CH = '+ IntToStr(nCh));

  Result := 0;
end;

function TControlDio.CLOSE_up_PinBlock(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  if Common.SystemInfo.OCType <> DefCommon.PreOCType  then Exit(2);
  nWaitingCount:= 50; //100ms * nWaitingCount
  // Return ==> 0 : OK. 1 ==> NG.
  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PIN BLOCK CLOSE Prevention Up Start - CH = '+ IntToStr(nCh));

  for i := 0 to nWaitingCount do begin
    Sleep(100);
    if  (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_OPEN_SENSOR +nCh*8)) then begin  // 제품 미감지 시 NG 발생

      SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PINBLOCK_OPEN_SENSOR + nCh*8, 1, '');
      Exit(1);
    end;
  end;

  bRet := True;

  if (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_UP_SENSOR +nCh*8))  then     //Close Dn 조건 확인
   bRet := False;

  if bRet then begin
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PIN BLOCK CLOSE Prevention Up Finish CH = '+ IntToStr(nCh)+ ' - Already');
    Exit(0);
  end;

  bRet := True;

  WriteDioSig(DefDio.OUT_GIB_CH_1_PINBLOCK_CLOSE_SOL + nCh*8,false);

  for i := 0 to nWaitingCount do begin
    Sleep(100);
    if ( ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_UP_SENSOR +nCh*8)) then Break;
  end;
  if  (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_UP_SENSOR +nCh*8)) then begin
    SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PINBLOCK_CLOSE_UP_SENSOR + nCh*8, 1, '');
    Exit(1);
  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PIN BLOCK CLOSE Prevention UP Finish CH = '+ IntToStr(nCh));

  Result := 0;
end;

function TControlDio.UnLockCarrier(nCh: Integer; bMainter : Boolean): Integer;
var
  i, j, nDiv : Integer;
  bRet : boolean;
  nWaitingCount: Integer;
begin
  Result := 1;
  if ControlDio = nil then Exit(1);
  nWaitingCount:= 80; //100ms * nWaitingCount
  if Common.SystemInfo.OCType <> DefCommon.OCType  then Exit(2);

  case nCh of
    DefCommon.CH_TOPGroup : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Start TOP_CH');

      ClearOutDioSig(DefDio.OUT_CH_1_CARRIER_LOCK_SOL );
      ClearOutDioSig(DefDio.OUT_CH_2_CARRIER_LOCK_SOL );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH2 do begin

        if  {(not ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +i*16)) and}
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +i*16)) then Continue;
        bRet := False;
      end;
      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish TOP_CH - Already');
        Exit(0);
      end;

      //Lock Carrier.
      WriteDioSig(DefDio.OUT_CH_1_CARRIER_UNLOCK_SOL,false);
      WriteDioSig(DefDio.OUT_CH_2_CARRIER_UNLOCK_SOL,false);

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH2 do begin
        if  {(not ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +i*16)) and}
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +i*16)) then Continue;
        bRet := False;
      end;

      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH1 to DefCommon.CH2 do begin
            if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);
        for j := DefCommon.CH1 to DefCommon.CH2 do begin
          if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then Continue
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) then SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_1 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) then SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_2 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) then SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_3 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_4 + j*16, 1, '');
          Exit(2);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish TOP_CH');
    end;
    DefCommon.CH_BOTTOMGroup : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Start - BOTTOM_CH');
      ClearOutDioSig(DefDio.OUT_CH_3_CARRIER_LOCK_SOL );
      ClearOutDioSig(DefDio.OUT_CH_4_CARRIER_LOCK_SOL );

      bRet := True;
      for i := DefCommon.CH3 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +i*16)) then Continue;
        bRet := False;
      end;

      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish BOTTOM_CH - Already');
        Exit(0);
      end;

      // LockCarrier.

      WriteDioSig(DefDio.OUT_CH_3_CARRIER_UNLOCK_SOL,false );
      WriteDioSig(DefDio.OUT_CH_4_CARRIER_UNLOCK_SOL,false );

      bRet := True;
      for i := DefCommon.CH3 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +i*16)) then Continue;
        bRet := False;
      end;



      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH3 to DefCommon.CH4 do begin
            if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);

        for j := DefCommon.CH3 to DefCommon.CH4 do begin
          if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then Continue
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_1 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_2 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_3 + j*16, 1, '')
          else if (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_4 + j*16, 1, '');

          Exit(2);
        end;

      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish BOTTOM_CH');
    end;
    DefCommon.CH_ALLGroup : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Start ALL_CH');

      ClearOutDioSig(DefDio.OUT_CH_1_CARRIER_LOCK_SOL );
      ClearOutDioSig(DefDio.OUT_CH_2_CARRIER_LOCK_SOL );
      ClearOutDioSig(DefDio.OUT_CH_3_CARRIER_LOCK_SOL );
      ClearOutDioSig(DefDio.OUT_CH_4_CARRIER_LOCK_SOL );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH4 do begin

        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +i*16)) then Continue;
        bRet := False;
      end;
      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish ALL_CH - Already');
        Exit(0);
      end;

      //Lock Carrier.
      WriteDioSig(DefDio.OUT_CH_1_CARRIER_UNLOCK_SOL,false);
      WriteDioSig(DefDio.OUT_CH_2_CARRIER_UNLOCK_SOL,false);
      WriteDioSig(DefDio.OUT_CH_3_CARRIER_UNLOCK_SOL,false);
      WriteDioSig(DefDio.OUT_CH_4_CARRIER_UNLOCK_SOL,false);

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +i*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +i*16)) then Continue;
        bRet := False;
      end;

      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH1 to DefCommon.CH4 do begin
            if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) and
                (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH1 to DefCommon.CH4 do begin
          if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +j*16)) and
            (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +j*16)) then Continue
          else begin
            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_SENSOR + j*16, 1, '');
            bRet := False;
          end;
        end;
        if not bRet  then
          Exit(2);
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish ALL_CH');
    end

    else begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Start Ch=' + IntToStr(nCh));

      nDiv := nCh;
      ClearOutDioSig(DefDio.OUT_CH_1_CARRIER_LOCK_SOL + nCh*16);

      if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +nCh*16)) and
          (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +nCh*16)) and
          (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +nCh*16)) and
          (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +nCh*16)) then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish Ch=' + IntToStr(nCh) + ' - Already');
        Exit(0);
      end;

      //Clamp Down
      WriteDioSig(DefDio.OUT_CH_1_CARRIER_UNLOCK_SOL + nCh*16,false);

      if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +nCh*16)) and
          (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +nCh*16)) and
          (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +nCh*16)) and
          (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +nCh*16)) then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if  (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +nCh*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +nCh*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +nCh*16)) and
              (ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +nCh*16)) then Break;
        end;
        Sleep(100);
        bRet := True;
//        if not bMainter then begin
//          if  (ReadInSig(DefDio.IN_CH_1_CARRIER_SENSOR +nCh*16)) then begin
//            SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_SENSOR + nCh*16, 1, '');
//            bRet := false;
//          end;
//        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_1 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_1 + nCh*16, 1, '');
          bRet := false;
        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_2 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_2 + nCh*16, 1, '');
          bRet := false;
        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_3 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_3 + nCh*16, 1, '');
          bRet := false;
        end;
        if  (not ReadInSig(DefDio.IN_CH_1_CARRIER_UNLOCK_SENSOR_4 +nCh*16)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_CARRIER_UNLOCK_SENSOR_4 + nCh*16, 1, '');
          bRet := false;
        end;
        if not bRet then Exit(2);

      end;

      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'UnLockCarrier Finish Ch=' + IntToStr(nCh));
    end;

  end;

  Result := 0;
end;


function TControlDio.ProbeBackward(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  Result := 1;
  if Common.SystemInfo.OCType <> DefCommon.OCType  then Exit(2);
  nWaitingCount:= 80;

   SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'MoveProbe  backward Start - CH = '+ IntToStr(nCh));
   ClearOutDioSig(DefDio.OUT_CH_1_PROBE_FORWARD_SOL + nCh*16);
   ClearOutDioSig(DefDio.OUT_CH_1_PROBE_DOWN_SOL + nCh*16);


   bRet := True;

   if  ( ReadInSig(DefDio.IN_CH_1_PROBE_BACKWARD_SENSOR +nCh*16)) or
       ( ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then
    bRet := False;


   if bRet then begin
     SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'MoveProbe backward Finish CH = '+ IntToStr(nCh)+ ' - Already');
     Exit(0);
   end;


   // for  back ward.
   bRet := True;

   if  (not ReadInSig(DefDio.IN_CH_1_PROBE_BACKWARD_SENSOR +nCh*16)) then begin
     if (not ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then  begin
       Exit(0);
     end
     else begin
       WriteDioSig(DefDio.OUT_CH_1_PROBE_UP_SOL + nCh*16,false);

       for i := 0 to nWaitingCount do begin
         Sleep(100);
         if (not ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then Break;
       end;
       if  (ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then begin
         SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_PROBE_UP_SENSOR + nCh*16, 1, '');
         Exit(1);
       end;

     end;

   end
   else begin
     if (ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then begin
       WriteDioSig(DefDio.OUT_CH_1_PROBE_UP_SOL + nCh*16,false);

       for i := 0 to nWaitingCount do begin
         Sleep(100);
         if (not ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then Break;
       end;
       if  (ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then begin
         SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_PROBE_UP_SENSOR + nCh*16, 1, '');
         Exit(1);
       end;

     end;

     WriteDioSig(DefDio.OUT_CH_1_PROBE_BACKWARD_SOL + nCh*16,false);

     for i := 0 to nWaitingCount do begin
         Sleep(100);
         if (not ReadInSig(DefDio.IN_CH_1_PROBE_BACKWARD_SENSOR +nCh*16)) then Break;
     end;
     if  (ReadInSig(DefDio.IN_CH_1_PROBE_BACKWARD_SENSOR +nCh*16)) then begin
         SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_PROBE_BACKWARD_SENSOR + nCh*16, 1, '');
         Exit(1);
     end;


   end;

   SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'MoveProbe backward Finish CH = '+ IntToStr(nCh));
  Result := 0;
end;



function TControlDio.ProbeForward(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  Result := 1;
  if Common.SystemInfo.OCType <> DefCommon.OCType  then Exit(2);
  nWaitingCount:= 80; //100ms * nWaitingCount
  // Return ==> 0 : OK. 1 ==> NG.
  // for forward.

     SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'MoveProbe forward Start - CH = '+ IntToStr(nCh));
     ClearOutDioSig(DefDio.OUT_CH_1_PROBE_BACKWARD_SOL + nCh*16);
     ClearOutDioSig(DefDio.OUT_CH_1_PROBE_UP_SOL + nCh*16);


     bRet := True;

     if  ( ReadInSig(DefDio.IN_CH_1_PROBE_FORWARD_SENSOR +nCh*16)) or
         ( ReadInSig(DefDio.IN_CH_1_PROBE_DOWN_SENSOR +nCh*16)) then
      bRet := False;


     if bRet then begin
       SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'MoveProbe forward Finish CH = '+ IntToStr(nCh)+ ' - Already');
       Exit(0);
     end;


     // for forward.
     bRet := True;

     if  (not ReadInSig(DefDio.IN_CH_1_PROBE_FORWARD_SENSOR +nCh*16)) then begin
       if (not ReadInSig(DefDio.IN_CH_1_PROBE_DOWN_SENSOR +nCh*16)) then  begin
         Exit(0);
       end
       else begin
         WriteDioSig(DefDio.OUT_CH_1_PROBE_DOWN_SOL + nCh*16,false);

         for i := 0 to nWaitingCount do begin
           Sleep(100);
           if (not ReadInSig(DefDio.IN_CH_1_PROBE_DOWN_SENSOR +nCh*16)) then Break;
         end;
         if  (ReadInSig(DefDio.IN_CH_1_PROBE_DOWN_SENSOR +nCh*16)) then begin
           SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_PROBE_DOWN_SENSOR + nCh*16, 1, '');
           Exit(1);
         end;

       end;

     end
     else begin
       if (ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then begin
         WriteDioSig(DefDio.OUT_CH_1_PROBE_UP_SOL + nCh*16,false);

         for i := 0 to nWaitingCount do begin
           Sleep(100);
           if (not ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then Break;
         end;
         if  (ReadInSig(DefDio.IN_CH_1_PROBE_UP_SENSOR +nCh*16)) then begin
           SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_PROBE_UP_SENSOR + nCh*16, 1, '');
           Exit(1);
         end;

       end;

       WriteDioSig(DefDio.OUT_CH_1_PROBE_FORWARD_SOL + nCh*16,false);

       for i := 0 to nWaitingCount do begin
           Sleep(100);
           if (not ReadInSig(DefDio.IN_CH_1_PROBE_FORWARD_SENSOR +nCh*16)) then Break;
       end;
       if  (ReadInSig(DefDio.IN_CH_1_PROBE_FORWARD_SENSOR +nCh*16)) then begin
           SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_PROBE_FORWARD_SENSOR + nCh*16, 1, '');
           Exit(1);
       end;

       WriteDioSig(DefDio.OUT_CH_1_PROBE_DOWN_SOL + nCh*16,false);


       for i := 0 to nWaitingCount do begin
           Sleep(100);
           if (not ReadInSig(DefDio.IN_CH_1_PROBE_DOWN_SENSOR +nCh*16)) then Break;
       end;
       if  (ReadInSig(DefDio.IN_CH_1_PROBE_DOWN_SENSOR +nCh*16)) then begin
           SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CH_1_PROBE_DOWN_SENSOR + nCh*16, 1, '');
           Exit(1);
       end;

     end;

     SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'MoveProbe forward Finish CH = '+ IntToStr(nCh));

  Result := 0;
end;


{


function TControlDio.ClampDown(nCh: Integer): Integer;
var
  i, j, nDiv : Integer;
  bRet : boolean;
  nWaitingCount: Integer;
begin
  nWaitingCount:= 30; //100ms * nWaitingCount

  case nCh of
    DefCommon.CH_STAGE_A : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Start SATGE A');

      ClearOutDioSig(DefDio.OUT_CLAMP_UP_SOL_12CH );
      ClearOutDioSig(DefDio.OUT_CLAMP_UP_SOL_34CH );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH4 do begin
        if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +i*4)) and
            (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +i*4))  then Continue;
        bRet := False;
      end;
      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Finish SATGE A - Already');
        Exit(0);
      end;

      //Clamp Down.
      WriteDioSig(DefDio.OUT_CLAMP_DN_SOL_12CH );
      WriteDioSig(DefDio.OUT_CLAMP_DN_SOL_34CH );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH4 do begin
        if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +i*4)) and
            (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +i*4)) then Continue;
        bRet := False;
      end;

      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH1 to DefCommon.CH4 do begin
            if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +j*4)) and
                (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +j*4)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH1 to DefCommon.CH4 do begin
          if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +j*4)) and
              (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +j*4)) then Continue;
          bRet := False;
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1 + j*4, 1, '');
          Exit(2);
        end;
        if not bRet then  begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1, 1, '');
          Exit(2);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Finish STAGE A');
    end;
    DefCommon.CH_STAGE_B : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Start - SATGE B');
      ClearOutDioSig(DefDio.OUT_CLAMP_UP_SOL_56CH );
      ClearOutDioSig(DefDio.OUT_CLAMP_UP_SOL_78CH );

      bRet := True;
      for i := DefCommon.CH5 to DefCommon.CH8 do begin
        if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +i*4)) and
            (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +i*4)) then Continue;
        bRet := False;
      end;

      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Finish SATGE B - Already');
        Exit(0);
      end;

      // Clamp Down.
      bRet := True;
      for i := DefCommon.CH5 to DefCommon.CH8 do begin
        if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +i*4)) and
            (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +i*4)) then Continue;
        bRet := False;
      end;

      WriteDioSig(DefDio.OUT_CLAMP_DN_SOL_56CH );
      WriteDioSig(DefDio.OUT_CLAMP_DN_SOL_78CH );

      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH5 to DefCommon.CH8 do begin
            if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +j*4)) and
                (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +j*4)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH5 to DefCommon.CH8 do begin
          if  (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +j*4)) and
              (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +j*4)) then Continue;
          bRet := False;
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1 + j*4, 1, '');
          Exit(2);
        end;
        if not bRet then  begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1, 1, '');
          Exit(2);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Finish STAGE B');
    end
    else begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Start Ch=' + IntToStr(nCh));
      //Stage가 검사 존에 있을 경우 처리 안함
      (*
      if ReadInSig(DefDio.IN_A_STAGE_IN_CAM) and (nCh in [0,1,2,3])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      if ReadInSig(DefDio.IN_B_STAGE_IN_CAM) and (nCh in [4,5,6,7])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      *)
      nDiv := nCh div 2;
      ClearOutDioSig(DefDio.OUT_CLAMP_UP_SOL_12CH + nDiv*8);

      if (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 +nCh*4)) and
         (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 +nCh*4)) then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Finish Ch=' + IntToStr(nCh) + ' - Already');
        Exit(0);
      end;

      //Clamp Down
      WriteDioSig(DefDio.OUT_CLAMP_DN_SOL_12CH + nDiv*8);

      if (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4)) or (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4)) then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4)) and
             (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4)) then Break;
        end;
        Sleep(100);
        if (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4, 1, '');
          Exit(2);
        end;
        if (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4, 1, '');
          Exit(3);
        end;
      end;

      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampDown Finish Ch=' + IntToStr(nCh));
    end;

  end;

  Result := 0;
end;

function TControlDio.ClampUp(nCh: Integer): Integer;
var
  i, j, nDiv : Integer;
  bRet : boolean;
  nWaitingCount: Integer;
begin
  nWaitingCount:= 30; //100ms * nWaitingCount

  case nCh of
    DefCommon.CH_TOP : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Start SATGE A');

      ClearOutDioSig(DefDio.OUT_CLAMP_DN_SOL_12CH );
      ClearOutDioSig(DefDio.OUT_CLAMP_DN_SOL_34CH );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + i*4)) and
            (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + i*4))  then Continue;
        bRet := False;
      end;

      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Finish SATGE A - Already');
        Exit(0);
      end;

      // Clamp Up.
      WriteDioSig(DefDio.OUT_CLAMP_UP_SOL_12CH );
      WriteDioSig(DefDio.OUT_CLAMP_UP_SOL_34CH );

      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH4 do begin
        if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + i*4)) and
            (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + i*4)) then Continue;
        bRet := False;
      end;

      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH1 to DefCommon.CH4 do begin
            if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + j*4)) and
                (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + j*4)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH1 to DefCommon.CH4 do begin
          if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + j*4)) and
              (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + j*4)) then Continue;
          bRet := False;
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1 + j*4, 1, '');
          Exit(2);
        end;
        if not bRet then  begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1, 1, '');
          Exit(2);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Finish STAGE A');
    end;
    DefCommon.CH_BOTTOM : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Start - SATGE B');
      ClearOutDioSig(DefDio.OUT_CLAMP_DN_SOL_56CH );
      ClearOutDioSig(DefDio.OUT_CLAMP_DN_SOL_78CH );

      bRet := True;
      for i := DefCommon.CH5 to DefCommon.CH8 do begin
        if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + i*4)) and
            (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + i*4)) then Continue;
        bRet := False;
      end;

      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Finish SATGE B - Already');
        Exit(0);
      end;

      bRet := True;
      for i := DefCommon.CH5 to DefCommon.CH8 do begin
        if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + i*4)) and
            (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + i*4)) then Continue;
        bRet := False;
      end;

      // Clamp Up.
      WriteDioSig(DefDio.OUT_CLAMP_UP_SOL_56CH );
      WriteDioSig(DefDio.OUT_CLAMP_UP_SOL_78CH );

      // 1개라도 Up 되어 있지 않으면 up.
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH5 to DefCommon.CH8 do begin
            if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + j*4)) and
                (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + j*4)) then Continue;
            bRet := False;
          end;
          if bRet then Break
        end;
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH5 to DefCommon.CH8 do begin
          if  (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + j*4)) and
              (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + j*4)) then Continue;
          bRet := False;
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1 + j*4, 1, '');
          Exit(2);
        end;
        if not bRet then  begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1, 1, '');
          Exit(2);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Finish STAGE B');
    end
    else begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Start Ch=' + IntToStr(nCh));
      //Stage가 검사 존에 있을 경우 처리 안함
      (*
      if ReadInSig(DefDio.IN_A_STAGE_IN_CAM) and (nCh in [0,1,2,3])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      if ReadInSig(DefDio.IN_B_STAGE_IN_CAM) and (nCh in [4,5,6,7])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      *)
      nDiv := nCh div 2;
      ClearOutDioSig(DefDio.OUT_CLAMP_DN_SOL_12CH + nDiv*8);

      if  ( ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4)) and
          ( ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4)) then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Finish Ch=' + IntToStr(nCh) + ' - Already');
        Exit(0);
      end;

      WriteDioSig(DefDio.OUT_CLAMP_UP_SOL_12CH + nDiv*8);
      // Clamp up.
      if (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4)) or (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4)) then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4)) and
             (ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4)) then Break;
        end;
        Sleep(100);
        if (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_1 + nCh*4, 1, '');
          Exit(2);
        end;
        if (not ReadInSig(DefDio.IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4)) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_CLAMP_UP_SENSOR_1CH_2 + nCh*4, 1, '');
          Exit(3);
        end;
      end;
    end;
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'ClampUp Finish Ch=' + IntToStr(nCh));
  end;

  Result := 0;
end;


function TControlDio.PogoDown(nCh: Integer): Integer;
var
  i, j, nDiv : Integer;
  bRet : boolean;
  nWaitingCount: Integer;
begin
  //if ErrorCheck > 0 then Exit(1);
  nWaitingCount:= 30; //100ms * nWaitingCount

  case nCh of
    DefCommon.CH_STAGE_A : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Start SATGE A');
      ClearOutDioSig(DefDio.OUT_POGO_UP_SOL_12CH );
      ClearOutDioSig(DefDio.OUT_POGO_UP_SOL_34CH );
      bRet := True;
      for i := DefCommon.CH1 to DefCommon.CH4 do begin
        if (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH    +i*4)) then Continue;
        bRet := False;
      end;
      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Finish SATGE A - Already');
        Exit(0);
      end;

      // Pogo Up.
      WriteDioSig(DefDio.OUT_POGO_DN_SOL_12CH );
      WriteDioSig(DefDio.OUT_POGO_DN_SOL_34CH );

      for i := 0 to nWaitingCount do begin
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH1 to DefCommon.CH4 do begin
          if  (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
          bRet := False;
        end;
        if bRet then Break;
      end;
      Sleep(100);
      bRet := True;
      for j := DefCommon.CH1 to DefCommon.CH4 do begin
        if (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
        bRet := False;
        SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH + j*4, 1);
        Exit(3);
      end;
      if not bRet then begin
        SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH, 1);
        Exit(3);
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Finish STAGE A');
    end;
    DefCommon.CH_STAGE_B : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Start - SATGE B');
      ClearOutDioSig(DefDio.OUT_POGO_UP_SOL_56CH );
      ClearOutDioSig(DefDio.OUT_POGO_UP_SOL_78CH );
      bRet := True;
      for i := DefCommon.CH5 to DefCommon.CH8 do begin
        if (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH    +i*4)) then Continue;
        bRet := False;
      end;
      if bRet then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Finish SATGE B - Already');
        Exit(0);
      end;

      WriteDioSig(DefDio.OUT_POGO_DN_SOL_56CH );
      WriteDioSig(DefDio.OUT_POGO_DN_SOL_78CH );

      for i := 0 to nWaitingCount do begin
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH5 to DefCommon.CH8 do begin
          if  (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
          bRet := False;
        end;
        if bRet then Break;
      end;
      Sleep(100);
      bRet := True;
      for j := DefCommon.CH5 to DefCommon.CH8 do begin
        if (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
        bRet := False;
        SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH + j*4, 1, '');
        Exit(3);
      end;
      if not bRet then begin
        SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH, 1, '');
        Exit(3);
      end;

      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Finish STAGE B');
    end
    else begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Start Ch ' + IntToStr(nCh));
      //Stage가 검사 존에 있을 경우 처리 안함
      (*
      if ReadInSig(DefDio.IN_A_STAGE_IN_CAM) and (nCh in [0,1,2,3])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      if ReadInSig(DefDio.IN_B_STAGE_IN_CAM) and (nCh in [4,5,6,7])  then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Ignore ' + IntToStr(nCh));
        Exit(0);
      end;
      *)
      nDiv := nCh div 2;
      ClearOutDioSig(DefDio.OUT_POGO_UP_SOL_12CH + nDiv*8);
      if ( ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH    +nCh*4)) then Exit(0);

      WriteDioSig(DefDio.OUT_POGO_DN_SOL_12CH + nDiv*8);
      // Pogo Down.
      if not ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +nCh*4) then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +nCh*4)) then Break;
        end;
        Sleep(100);
        if not ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +nCh*4) then begin
          //SetAlarmMsg(DefDio.ERR_LIST_POGO_DN_SENSOR+nCh);
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH, 1, '');
          Exit(3);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoDown Finish Ch ' + IntToStr(nCh));
    end;
  end;

  Result := 0;
end;

function TControlDio.PogoUp(nCh: Integer): Integer;
var
  i, nDiv, j, nRet : Integer;
  bRet : boolean;
  nWaitingCount: Integer;
begin
  //nRet := ErrorCheck;
  //if nRet > 0 then Exit(nRet);
  nWaitingCount:= 30; //50ms * nWaitingCount
  case nCh of
    DefCommon.CH_STAGE_A : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoUp Start STAGE A');
      ClearOutDioSig(DefDio.OUT_POGO_DN_SOL_12CH);
      ClearOutDioSig(DefDio.OUT_POGO_DN_SOL_34CH);
      WriteDioSig(DefDio.OUT_POGO_UP_SOL_12CH );
      WriteDioSig(DefDio.OUT_POGO_UP_SOL_34CH );
      // Pogo Up.
      bRet := True;
      for j := DefCommon.CH1 to DefCommon.CH4 do begin
        if  not (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
        bRet := False;
      end;
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH1 to DefCommon.CH4 do begin
            if  not (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
            bRet := False;
          end;
          if bRet then Break;
        end;
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH1 to DefCommon.CH4 do begin
          if not (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
          bRet := False;
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH + j*4, 1, '');
          Exit(3);
        end;
        if not bRet then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH, 1, '');
          Exit(3);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoUp Finish STAGE A');
    end; //DefCommon.CH_STAGE_A : begin

    DefCommon.CH_STAGE_B : begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoUp Start STAGE B');
      // Pogo Up.
      ClearOutDioSig(DefDio.OUT_POGO_DN_SOL_56CH );
      ClearOutDioSig(DefDio.OUT_POGO_DN_SOL_78CH );
      WriteDioSig(DefDio.OUT_POGO_UP_SOL_56CH );
      WriteDioSig(DefDio.OUT_POGO_UP_SOL_78CH );

      bRet := True;
      for j := DefCommon.CH5 to DefCommon.CH8 do begin
        if  not (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
        bRet := False;
      end;
      if not bRet then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          bRet := True;
          for j := DefCommon.CH5 to DefCommon.CH8 do begin
            if  not (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
            bRet := False;
          end;
          if bRet then Break;
        end;
        Sleep(100);
        bRet := True;
        for j := DefCommon.CH5 to DefCommon.CH8 do begin
          if not (ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +j*4)) then Continue;
          bRet := False;
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH +j*4, 1, '');
          Exit(3);
        end;
        if not bRet then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH, 1, '');
          Exit(3);
        end;
      end;
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoUp Finish STAGE B');
    end  //DefCommon.CH_STAGE_B : begin

    else begin
      SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoUp Start Ch ' + IntToStr(nCh));
      nDiv := nCh div 2;

      ClearOutDioSig(DefDio.OUT_POGO_DN_SOL_12CH + nDiv*8);
      WriteDioSig(DefDio.OUT_POGO_UP_SOL_12CH + nDiv*8);
      // Pogo Up.
      if ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +nCh*4) then begin
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if (not ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +nCh*4)) then Break;
        end;
        Sleep(100);
        if ReadInSig(DefDio.IN_POGO_DN_SENSOR_1CH +nCh*4) then begin
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH +nCh*4, 1, '');
          //SetAlarmMsg(DefDio.ERR_LIST_POGO_UP_SENSOR+nCh,False);
          Exit(3);
        end;
      end;
    end;
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'PogoUp Finish Ch ' + IntToStr(nCh));
  end;
  Result := 0;
end;
}

procedure TControlDio.ClearOutDioSig(nSig: Integer);
var
  nIdx, nPos, nValue : integer;
begin
  nIdx := nSig div 8; nPos := nSig mod 8;
  nValue := 0;

  CommDaeDIO.WriteDO_Bit(nIdx,nPos,nValue);
end;

constructor TControlDio.Create(hMain: HWND; nMsgType : Integer);
var
  i : Integer;
begin
  m_nMsgType := nMsgType;
  m_hMain  := hMain;
  m_bConnected := False;

  m_nTowerLampState:= 0;
  m_nTowerLampTick:= GetTickCount;
  UseTowerLamp:= True;
  MelodyOn:= True;
  // Error Message 초기화.
  for i:= 0 to Pred(DefDio.MAX_ALARM_DATA_SIZE) do DioAlarmData[i] := 0;
    // DIO Connect.
  CommDaeDIO:= TCommDIOThread.Create(0,DefCommon.MSG_TYPE_DAEIO, DefDio.DAE_IO_DEVICE_PORT, DefDio.DAE_IO_DEVICE_COUNT + Common.SystemInfo.DioType,True,3,1);
  // Polling Mode 3 ==> Notify & Polling.
  CommDaeDIO.OnNotify := CommDIONotify;
  if Common.SimulateInfo.Use_DIO then begin
    CommDaeDIO.DeviceIP:= Common.SimulateInfo.DIO_IP;
    CommDaeDIO.DevicePort:= Common.SimulateInfo.DIO_PORT;
  end
  else begin
    CommDaeDIO.DeviceIP:= DefDio.DAE_IO_DEVICE_IP;
    CommDaeDIO.DevicePort:= DefDio.DAE_IO_DEVICE_PORT;
  end;
  CommDaeDIO.PollingInterval:= DefDio.DAE_IO_DEVICE_INTERVAL;
  CommDaeDIO.LogPath := Common.Path.LOG;
  CommDaeDIO.LogLevel := 0;
  CommDaeDIO.Start;
//  DisplayIo;
  tmrCycle := TTimer.Create(nil);
  tmrCycle.Interval := 500;
  tmrCycle.OnTimer := tmrCycleTimer;
  tmrCycle.Enabled := True;

  m_bDoorOpen := False;
  m_bIoThreadWork := False;
  m_nStageToFront := 0;
end;

destructor TControlDio.Destroy;
begin
  tmrCycle.Free;
  tmrCycle := nil;

  CommDaeDIO.Free;
  CommDaeDIO := nil;


  inherited;
end;

procedure TControlDio.DisplayIo;
begin
  SendMsgMain(ControlDio_OC.MSG_MODE_DISPLAY_IO, 0,0,'');
end;

function TControlDio.UnlockDoorOpen(nCH : Integer; bUnlock: Boolean): Boolean;
begin
  Result := not bUnlock;
  if Common.SystemInfo.OCType <> DefCommon.OCType  then Exit;
  case  nCH  of
    ALL_CH : begin
      WriteDioSig(DefDio.OUT_CH_1_2_DOOR_LEFT_UNLOCK, not bUnlock);
      WriteDioSig(DefDio.OUT_CH_1_2_DOOR_RIGHT_UNLOCK, not bUnlock);
      WriteDioSig(DefDio.OUT_CH_3_4_DOOR_LEFT_UNLOCK, not bUnlock);
      WriteDioSig(DefDio.OUT_CH_3_4_DOOR_RIGHT_UNLOCK, not bUnlock);
    end;
    TOP_CH : begin
      WriteDioSig(DefDio.OUT_CH_1_2_DOOR_LEFT_UNLOCK, not bUnlock);
      WriteDioSig(DefDio.OUT_CH_1_2_DOOR_RIGHT_UNLOCK, not bUnlock);
    end;
    BOTTOM_CH : begin
      WriteDioSig(DefDio.OUT_CH_3_4_DOOR_LEFT_UNLOCK, not bUnlock);
      WriteDioSig(DefDio.OUT_CH_3_4_DOOR_RIGHT_UNLOCK, not bUnlock);
    end;
  end;
end;

function TControlDio.UnlockPinBlock(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  if Common.SystemInfo.OCType <> DefCommon.PreOCType  then Exit(2);
  nWaitingCount:= 50; //100ms * nWaitingCount
  // Return ==> 0 : OK. 1 ==> NG.

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Unlock PinBlock  Start - CH = '+ IntToStr(nCh));
  ClearOutDioSig(DefDio.OUT_GIB_CH_1_VACCUM_SOL + nCh*8);

  bRet := True;

  if (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_UNLOCK_ON_SENSOR +nCh*8))  then
   bRet := False;


  if bRet then begin
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Unlock PinBlock Finish CH = '+ IntToStr(nCh)+ ' - Already');
    Exit(0);
  end;


  // for Unlock.
  bRet := True;

  WriteDioSig(DefDio.OUT_GIB_CH_1_PINBLOCK_UNLOCK_SOL + nCh*8,true);

  for i := 0 to nWaitingCount do begin
    Sleep(100);
    if ( ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_UNLOCK_ON_SENSOR +nCh*8)) then Break;
  end;
  if  (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_UNLOCK_ON_SENSOR +nCh*8)) then begin
    SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PINBLOCK_UNLOCK_ON_SENSOR + nCh*8, 1, '');
    Exit(1);
  end;

  Sleep(1000); // 웨이팅 Pin Block Open SENSOR

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Unlock PinBlock Finish CH = '+ IntToStr(nCh));

  Result := 0;
end;

function TControlDio.VaccumOFF(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  if Common.SystemInfo.OCType <> DefCommon.PreOCType  then Exit(2);
  nWaitingCount:= 50; //100ms * nWaitingCount
  // Return ==> 0 : OK. 1 ==> NG.
  // for lock.

//    if  (not ReadInSig(DefDio.IN_GIB_CH_1_CARRIER_SENSOR +nCh*8)) then begin  // 제품 미감지 시 NG 발생
//    SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_CARRIER_SENSOR + nCh*8, 1, '');
//    Exit(1);
//  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Vaccum OFF  Start - CH = '+ IntToStr(nCh));

  bRet := True;

  if  ( ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) then
  //Vaccum OFF 조건 확인
   bRet := False;


  if bRet then begin
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Vaccum OFF  Finish CH = '+ IntToStr(nCh)+ ' - Already');
    Exit(0);
  end;

  bRet := True;

  if  (not ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) then begin


  end
  else begin

    WriteDioSig(DefDio.OUT_GIB_CH_1_VACCUM_SOL + nCh*8,true);

    for i := 0 to nWaitingCount do begin
      Sleep(100);
      if (not ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) then Break;
    end;
    if  ( ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) then begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PRESSURE_GUAGE + nCh*8, 1, '');
      Exit(1);
    end;

  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Vaccum OFF Finish CH = '+ IntToStr(nCh));

  Result := 0;
end;

function TControlDio.VaccumON(nCh: Integer): Integer;
var
  i,nWaitingCount: Integer;
  bRet : Boolean;
begin
  if Common.SystemInfo.OCType <> DefCommon.PreOCType  then Exit(2);
  nWaitingCount:= 50; //100ms * nWaitingCount
  // Return ==> 0 : OK. 1 ==> NG.
  // for lock.

    if  (not ReadInSig(DefDio.IN_GIB_CH_1_CARRIER_SENSOR +nCh*8)) then begin  // 제품 미감지 시 NG 발생
    SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_CARRIER_SENSOR + nCh*8, 1, '');
    Exit(1);
  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Vaccum ON  Start - CH = '+ IntToStr(nCh));

  bRet := True;

  if  (not ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) or
      (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_DN_SENSOR +nCh*8))  then     //Vaccum OFF 조건 확인
   bRet := False;


  if bRet then begin
    SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Vaccum ON  Finish CH = '+ IntToStr(nCh)+ ' - Already');
    Exit(0);
  end;

  // for lock.
  bRet := True;

  if  ( ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) then begin

    WriteDioSig(DefDio.OUT_GIB_CH_1_PINBLOCK_CLOSE_SOL + nCh*8,true);

    for i := 0 to nWaitingCount do begin
      Sleep(100);
      if ( ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_UP_SENSOR +nCh*8)) then Break;
    end;
    if  (not ReadInSig(DefDio.IN_GIB_CH_1_PINBLOCK_CLOSE_DN_SENSOR +nCh*8)) then begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PINBLOCK_CLOSE_DN_SENSOR + nCh*8, 1, '');
      Exit(1);
    end;


  end
  else begin

    WriteDioSig(DefDio.OUT_GIB_CH_1_VACCUM_SOL + nCh*8,False);

    for i := 0 to nWaitingCount do begin
      Sleep(100);
      if ( ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) then Break;
    end;
    if  ( ReadInSig(DefDio.IN_GIB_CH_1_PRESSURE_GUAGE +nCh*8)) then begin
      SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_1_PRESSURE_GUAGE + nCh*8, 1, '');
      Exit(1);
    end;
  end;

  SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Vaccum ON Finish CH = '+ IntToStr(nCh));

  Result := 0;
end;

function TControlDio.ErrorCheck: Integer;
var
  nRet : Integer;
  bDoorOpen : Boolean;
begin
  nRet := DefDio.ERR_LIST_START;
  // Reset... Clear 되더라도 누적 되면 ...
  if not CommDaeDIO.Connected then begin
    LastNgMsg := 'Disconnected DIO Card....';
    SendMsgMain(ControlDio_OC.MSG_MODE_SYSTEM_ALARAM, ERR_LIST_DIO_CARD_DISCONNECTED,0,LastNgMsg);
    m_bConnected := False;
    Exit(DefDio.ERR_LIST_DIO_CARD_DISCONNECTED);
  end;
  ResetError(1);
  // Check Input IO.
//  if CheckDi(DefDio.IN_FRONT_EMS) then begin
//    nRet := DefDio.ERR_LIST_FRONT_EMS;
//    SetAlarmMsg(nRet,False);
//  end;
//  if CheckDi(DefDio.IN_SIDE_EMS) then begin
//    nRet := DefDio.ERR_LIST_SIDE_EMS;
//    SetAlarmMsg(nRet,False);
//  end;
//  if CheckDi(DefDio.IN_RIGHT_INNER_EMS) then begin
//    nRet := DefDio.ERR_LIST_SIDE_EMS;
//    SetAlarmMsg(nRet,False);
//  end;
//  if CheckDi(DefDio.IN_LEFT_INNER_EMS) then begin
//    nRet := DefDio.ERR_LIST_SIDE_EMS;
//    SetAlarmMsg(nRet,False);
//  end;
//  if CheckDi(DefDio.IN_REAR_EMS) then begin
//    nRet := DefDio.ERR_LIST_REAR_EMS;
//    SetAlarmMsg(nRet,False);
//  end;
//  if CheckDi(DefDio.IN_LIGHT_CURTAIN) then begin
//    nRet := DefDio.ERR_LIST_LIGHT_CUTAIN;
//    SetAlarmMsg(nRet,False);
//  end;
  if not CheckDi(DefDio.IN_FAN_1_EXHAUST) then begin
    nRet := DefDio.ERR_LIST_FAN_1_OUT;
    SetAlarmMsg(nRet,False);
  end;
  if not CheckDi(DefDio.IN_FAN_2_INTAKE) then begin
    nRet := DefDio.ERR_LIST_FAN_1_OUT + 1;
    SetAlarmMsg(nRet,False);
  end;
  if not CheckDi(DefDio.IN_FAN_3_EXHAUST) then begin
    nRet := DefDio.ERR_LIST_FAN_1_OUT + 2;
    SetAlarmMsg(nRet,False);
  end;
  if not CheckDi(DefDio.IN_FAN_4_INTAKE) then begin
    nRet := DefDio.ERR_LIST_FAN_1_OUT + 3;
    SetAlarmMsg(nRet,False);
  end;

  // Upper DOOR Open Check.
  bDoorOpen := False;
  if CheckDi(DefDio.IN_CH_1_2_DOOR_LEFT_OPEN) then bDoorOpen := True;
  if CheckDi(DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN) then bDoorOpen := True;
  if CheckDi(DefDio.IN_CH_3_4_DOOR_LEFT_OPEN) then bDoorOpen := True;
  if CheckDi(DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN) then bDoorOpen := True;
//  if Common.SystemInfo.DIOType = defDIO.TYPE_GIB then begin
//    if CheckDi(DefDio.IN_AIR_ISOLATOR_LEFT_DOOR) then bDoorOpen := True;
//    if CheckDi(DefDio.IN_AIR_ISOLATOR_RIGHT_DOOR) then bDoorOpen := True;
//  end;
  // Door Open Alarm Message Check.
  if bDoorOpen then begin
    SendMsgMain(MSG_MODE_DISPLAY_ALARAM, -2, 0, 'Door Opened', nil);
  end;

  // Tech Mode에서는 처리 하지 않도록 한다.
  //Teach Mode가 아닐 경우에만 검사
//  if not ((not CheckDi(DefDio.IN_AUTO_MODE_SEL_KEY)) and (CheckDi(DefDio.IN_TEACH_MODE_SEL_KEY)))  then begin
    // Fan Check.
//    if not CheckDi(DefDio.IN_FAN5_IN) then begin
//      nRet := DefDio.ERR_LIST_FAN_1_OUT + 4;
//      SetAlarmMsg(nRet,False);
//    end;
//    if not CheckDi(DefDio.IN_FAN6_IN) then begin
//      nRet := DefDio.ERR_LIST_FAN_1_OUT + 5;
//      SetAlarmMsg(nRet,False);
//    end;
//    if not CheckDi(DefDio.IN_FAN7_OUT) then begin
//      nRet := DefDio.ERR_LIST_FAN_1_OUT + 6;
//      SetAlarmMsg(nRet,False);
//    end;
//    if not CheckDi(DefDio.IN_FAN8_OUT) then begin
//      nRet := DefDio.ERR_LIST_FAN_1_OUT + 7;
//      SetAlarmMsg(nRet,False);
//    end;
//  end;

  if CheckDi(DefDio.IN_CYL_PRESSURE_GAUGE) then begin
    nRet := DefDio.ERR_LIST_MAIN_AIR_PRESURE;
    SetAlarmMsg(nRet,False);
  end;
  if CheckDi(DefDio.IN_TEMPERATURE_ALARM) then begin
    nRet := DefDio.ERR_LIST_TEMPRERATURE;
    SetAlarmMsg(nRet,False);
  end;
//  if CheckDi(DefDio.IN_POWER_HIGH_ALARM) then begin
//    nRet := DefDio.ERR_LIST_POWER_HIGH;
//    SetAlarmMsg(nRet,False);
//  end;

  //Isolator
//  if Common.SystemInfo.DIOType = defDIO.TYPE_GIB then begin
//    if CheckDi(IN_AIR_ISOLATOR_SENSOR1) then begin
//
//    end;
//    if CheckDi(IN_AIR_ISOLATOR_SENSOR2) then begin
//
//    end;
//    if CheckDi(IN_AIR_ISOLATOR_SENSOR3) then begin
//
//    end;
//    if CheckDi(IN_AIR_ISOLATOR_SENSOR4) then begin
//
//    end;
//  end;


  if nRet <> DefDio.ERR_LIST_START then begin
    SetAlarmMsg(nRet);
    ClearOutDioSig(DefDio.OUT_RESET_SWITCH_LED);
    Exit(nRet);
  end
  else begin
    if not CheckDi(DefDio.IN_MC_MONITORING) then nRet := DefDio.ERR_LIST_MC_MONITOR;
    if nRet <> DefDio.ERR_LIST_START then begin
      tmrCycle.Enabled := True;
      SetAlarmMsg(nRet);
      Exit(nRet);
    end;
  end;
  tmrCycle.Enabled := False;
  ResetError(2);
//  ClearOutDioSig(DefDio.OUT_RESET_SW_LED);
  Result := 0;
end;

function TControlDio.IsDetected(nCH: Integer): Boolean;
begin
  Result:= False;
  if Common.SystemInfo.OCType = DefCommon.OCType  then begin
    if nCH = 0 then begin
      if ControlDio.ReadInSig(IN_CH_1_CARRIER_SENSOR)
        or ControlDio.ReadInSig(IN_CH_1_CARRIER_SENSOR+16) then
      begin
        Result:= True;
      end;
    end
    else begin
      if ControlDio.ReadInSig(IN_CH_3_CARRIER_SENSOR)
        or ControlDio.ReadInSig(IN_CH_3_CARRIER_SENSOR+16) then
      begin
        Result:= True;
      end;
    end;
  end
  else begin
      if nCH = 0 then begin
      if ControlDio.ReadInSig(IN_GIB_CH_1_CARRIER_SENSOR)
        or ControlDio.ReadInSig(IN_GIB_CH_1_CARRIER_SENSOR+8) then
      begin
        Result:= True;
      end;
    end
    else begin
      if ControlDio.ReadInSig(IN_GIB_CH_3_CARRIER_SENSOR)
        or ControlDio.ReadInSig(IN_GIB_CH_3_CARRIER_SENSOR+8) then
      begin
        Result:= True;
      end;
    end;

  end;
end;
{

}

function TControlDio.MovingProbe(nGroup: Integer; bIsUp: Boolean): Integer;
var
  i: Integer;
  nWaitingCount: Integer;
  sCH : string;
begin
  if Common.SystemInfo.OCType <> DefCommon.PreOCType  then Exit(2);
  //if ErrorCheck > 0 then Exit(1);
  nWaitingCount:= 100; //100ms * nWaitingCount
  if nGroup = DefCommon.CH_TOP  then sCH := ' CH 1,2 '
                                else sCH := 'CH 3,4 ';

      if bIsUp then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Probe UP Start ' + sCH);
        ClearOutDioSig(DefDio.OUT_GIB_CH_12_PROBE_DN_SOL + nGroup *4);
        if not ReadInSig(DefDio.IN_GIB_CH_12_PROBE_UP_SENSOR + nGroup *4) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Probe UP Finish %s - Already', [sCH]));
          Exit(0);
        end;
        WriteDioSig(DefDio.OUT_GIB_CH_12_PROBE_UP_SOL + nGroup *4);

        // Turn 돌기전 Work Lamp Off.
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if not ReadInSig(DefDio.IN_GIB_CH_12_PROBE_UP_SENSOR + nGroup *4) then begin
            SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format(sCH + 'Probe UP OK. Step=%d', [i]));
            break;
          end;
        end;

        //Retry
        if ReadInSig(DefDio.IN_GIB_CH_12_PROBE_UP_SENSOR + nGroup *4) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Wait Probe UP again');
          ClearOutDioSig(DefDio.OUT_GIB_CH_12_PROBE_DN_SOL + nGroup *4);
          Sleep(300);
          WriteDioSig(DefDio.OUT_GIB_CH_12_PROBE_UP_SOL + nGroup *4);

          for i := 0 to nWaitingCount do begin
            Sleep(100);
            if not ReadInSig(DefDio.IN_GIB_CH_12_PROBE_UP_SENSOR + nGroup *4) then begin
              SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Probe UP OK. Step=%d', [i]));
              break;
            end;
          end;
        end;

        if  ReadInSig(DefDio.IN_GIB_CH_12_PROBE_UP_SENSOR + nGroup *4) then begin
          //SetAlarmMsg(DefDio.ERR_LIST_SHUTTER_UP_SENSOR);
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_12_PROBE_UP_SENSOR + nGroup *4, 1, '');
          Exit(2);
        end;
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Probe UP Finish ' + sCH);
      end
      else begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Probe DN Start ' + sCH);
        ClearOutDioSig(DefDio.OUT_GIB_CH_12_PROBE_UP_SOL + nGroup *4);
        if not ReadInSig(DefDio.IN_GIB_CH_12_PROBE_DN_SENSOR + nGroup *4) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Probe DN Finish %s - Already', [sCH]));
          Exit(0);
        end;
        WriteDioSig(DefDio.OUT_GIB_CH_12_PROBE_DN_SOL + nGroup *4);

        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if not ReadInSig(DefDio.IN_GIB_CH_12_PROBE_DN_SENSOR + nGroup *4) then begin
            SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Probe DN OK. Step=%d', [i]));
            break;
          end;
        end;

        //Retry
        if  ReadInSig(DefDio.IN_GIB_CH_12_PROBE_DN_SENSOR + nGroup *4) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Wait Probe DN again');
          ClearOutDioSig(DefDio.OUT_GIB_CH_12_PROBE_UP_SOL + nGroup *4);
          Sleep(300);
          WriteDioSig(DefDio.OUT_GIB_CH_12_PROBE_DN_SOL + nGroup *4);

          for i := 0 to nWaitingCount do begin
            Sleep(100);
            if not ReadInSig(DefDio.IN_GIB_CH_12_PROBE_DN_SENSOR + nGroup *4) then begin
              SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Probe DN OK. Step=%d', [i]));
              break;
            end;
          end;
        end;

//        ClearOutDioSig(OUT_GIB_CH_12_SHUTTER_DN_SOL);

        if  ReadInSig(DefDio.IN_GIB_CH_12_PROBE_DN_SENSOR + nGroup *4) then begin
          //SetAlarmMsg(DefDio.ERR_LIST_SHUTTER_DN_SENSOR);
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_12_PROBE_DN_SENSOR + nGroup *4, 1, '');
          Exit(3);
        end;
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Probe DN Finish ' + sCH);
      end;



  Result := 0;
end;

function TControlDio.MovingShutter(nGroup : Integer; bIsUp: Boolean): Integer;
var
  i: Integer;
  nWaitingCount: Integer;
  sCH : string;
begin
  //if ErrorCheck > 0 then Exit(1);
  nWaitingCount:= 100; //100ms * nWaitingCount
  if nGroup = DefCommon.CH_TOP then sCH := 'CH 1,2'
  else                              sCH := 'CH 3,4';

  case nGroup of
    DefCommon.CH_TOP : begin
      if bIsUp then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0,'Shutter UP Start '+ sCH);
        ClearOutDioSig(DefDio.OUT_GIB_CH_12_SHUTTER_DN_SOL);
        if not ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_UP_SENSOR) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0,Format('Shutter UP Finish %s- Already',[sCH]));
          Exit(0);
        end;
        WriteDioSig(DefDio.OUT_GIB_CH_12_SHUTTER_UP_SOL,False);

        // Turn 돌기전 Work Lamp Off.
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if not ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_UP_SENSOR) then begin
            SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Shutter UP OK. %s Step=%d', [sCH,i]));
            break;
          end;
        end;

        if ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_UP_SENSOR) then begin
          //SetAlarmMsg(DefDio.ERR_LIST_SHUTTER_UP_SENSOR);
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_12_SHUTTER_UP_SENSOR, 1, '');
          Exit(2);
        end;
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Shutter UP Finish ' + sCH);
      end
      else begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Shutter DN Start ' + SCH);
        ClearOutDioSig(DefDio.OUT_GIB_CH_12_SHUTTER_UP_SOL);
        if not ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_DN_SENSOR) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0,Format('Shutter DN Finish %s - Already',[sCH]));
          Exit(0);
        end;
        WriteDioSig(DefDio.IN_GIB_CH_12_SHUTTER_DN_SENSOR,false);

        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if not ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_DN_SENSOR) then begin
            SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Shutter DN OK. %s Step=%d', [sCH,i]));
            break;
          end;
        end;

        if ReadInSig(DefDio.IN_GIB_CH_12_SHUTTER_DN_SENSOR) then begin
          //SetAlarmMsg(DefDio.ERR_LIST_SHUTTER_DN_SENSOR);
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_12_SHUTTER_DN_SENSOR, 1, '');
          Exit(3);
        end;
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Shutter DN Finish ' + sCH);
      end;


    end;
    DefCommon.CH_BOTTOM : begin
      if bIsUp then begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0,'Shutter UP Start ' + sCH);
        ClearOutDioSig(DefDio.OUT_GIB_CH_34_SHUTTER_DN_SOL);
        if not ReadInSig(DefDio.IN_GIB_CH_34_SHUTTER_UP_SENSOR) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Shutter UP Finish %s - Already', [sCh]));
          Exit(0);
        end;
        WriteDioSig(DefDio.OUT_GIB_CH_34_SHUTTER_UP_SOL,false);

        // Turn 돌기전 Work Lamp Off.
        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if not ReadInSig(DefDio.IN_GIB_CH_34_SHUTTER_UP_SENSOR) then begin
            SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Shutter UP OK.%s Step=%d', [sCH, i]));
            break;
          end;
        end;

        if ReadInSig(DefDio.IN_GIB_CH_34_SHUTTER_UP_SENSOR) then begin
          //SetAlarmMsg(DefDio.ERR_LIST_SHUTTER_UP_SENSOR);
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_12_SHUTTER_UP_SENSOR, 1, '');
          Exit(2);
        end;
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Shutter UP Finish ' + sCH);
      end
      else begin
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Shutter DN Start ' + sCH);
        ClearOutDioSig(DefDio.OUT_GIB_CH_34_SHUTTER_UP_SOL);
        if not ReadInSig(DefDio.IN_GIB_CH_34_SHUTTER_DN_SENSOR) then begin
          SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Shutter DN Finish %s - Already', [sCH]));
          Exit(0);
        end;
        WriteDioSig(DefDio.IN_GIB_CH_34_SHUTTER_DN_SENSOR,false);

        for i := 0 to nWaitingCount do begin
          Sleep(100);
          if not ReadInSig(DefDio.IN_GIB_CH_34_SHUTTER_DN_SENSOR) then begin
            SendMsgMain(COMMDIO_MSG_LOG, 0, 0, format('Shutter DN OK. %s Step=%d', [sCH, i]));
            break;
          end;
        end;

        if ReadInSig(DefDio.IN_GIB_CH_34_SHUTTER_DN_SENSOR) then begin
          //SetAlarmMsg(DefDio.ERR_LIST_SHUTTER_DN_SENSOR);
          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_GIB_CH_34_SHUTTER_DN_SENSOR, 1, '');
          Exit(3);
        end;
        SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Shutter DN Finish ' + sCH);
      end;

    end;
  end;

  Result := 0;
end;



procedure TControlDio.tmrCycleTimer(Sender: TObject);
var
  bOn : Boolean;
  nIdx, nPos : Integer;
  nTick: Cardinal;
  nTowerLamp_R,nTowerLamp_G,nTowerLamp_Y,nTowerLamp_B1,nTowerLamp_B2 : Integer;
begin
  if not m_bConnected then Exit;


  if Common.SystemInfo.OCType = DefCommon.OCType  then begin
    if not ReadInSig(DefDio.IN_MC_MONITORING) then begin
      nIdx := DefDio.OUT_RESET_SWITCH_LED div 8;
      nPos := DefDio.OUT_RESET_SWITCH_LED mod 8;
      bOn := ((CommDaeDIO.DODataFlush[nIdx] and (1 shl nPos)) > 0);
      WriteDioSig(DefDio.OUT_RESET_SWITCH_LED,bOn);
//      WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,true);
//      WriteDioSig(DefDio.OUT_CH_3_4_LAMP_OFF,true);
    end
    else begin
        if ReadOutSig(DefDio.OUT_RESET_SWITCH_LED) then begin
          WriteDioSig(DefDio.OUT_RESET_SWITCH_LED, True);
        end;
        if ReadInSig(DefDio.IN_CH_1_2_DOOR_LEFT_OPEN) and ReadInSig(DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN) then
          WriteDioSig(DefDio.OUT_CH_1_2_BACK_DOOR_LAMPON,False)
        else  WriteDioSig(DefDio.OUT_CH_1_2_BACK_DOOR_LAMPON,True);


        if ReadInSig(DefDio.IN_CH_3_4_DOOR_LEFT_OPEN) and ReadInSig(DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN) then
          WriteDioSig(DefDio.OUT_CH_3_4_BACK_DOOR_LAMPON,False)
         else  WriteDioSig(DefDio.OUT_CH_3_4_BACK_DOOR_LAMPON,True);
//        WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,false);
//        WriteDioSig(DefDio.OUT_CH_3_4_LAMP_OFF,false);
    end;


    nTowerLamp_R :=  DefDio.OUT_TOWER_LAMP_RED;
    nTowerLamp_Y :=  DefDio.OUT_TOWER_LAMP_YELLOW;
    nTowerLamp_G :=  DefDio.OUT_TOWER_LAMP_GREEN;
    nTowerLamp_B1 :=  DefDio.OUT_BUZZER_1;
    nTowerLamp_B2 :=  DefDio.OUT_BUZZER_2;
  end
  else begin
    if not ReadInSig(DefDio.IN_GIB_CH_12_MC_MONITORING) then begin
      nIdx := DefDio.OUT_CH_12_RESET_SWTCH_LED div 8;
      nPos := DefDio.OUT_CH_12_RESET_SWTCH_LED mod 8;
      bOn := ((CommDaeDIO.DODataFlush[nIdx] and (1 shl nPos)) > 0);
      WriteDioSig(DefDio.OUT_CH_12_RESET_SWTCH_LED,bOn);
//      WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,true);
    end
    else begin
      if ReadOutSig(DefDio.OUT_CH_12_RESET_SWTCH_LED) then begin
        WriteDioSig(DefDio.OUT_CH_12_RESET_SWTCH_LED, True);
      end;
//      WriteDioSig(DefDio.OUT_CH_1_2_LAMP_OFF,false);
    end;
    if not ReadInSig(DefDio.IN_GIB_CH_34_MC_MONITORING) then begin
      nIdx := DefDio.OUT_CH_34_RESET_SWTCH_LED div 8;
      nPos := DefDio.OUT_CH_34_RESET_SWTCH_LED mod 8;
      bOn := ((CommDaeDIO.DODataFlush[nIdx] and (1 shl nPos)) > 0);
      WriteDioSig(DefDio.OUT_CH_34_RESET_SWTCH_LED,bOn);
//      WriteDioSig(DefDio.OUT_CH_3_4_LAMP_OFF,true);
    end
    else begin
      if ReadOutSig(DefDio.OUT_CH_34_RESET_SWTCH_LED) then begin
        WriteDioSig(DefDio.OUT_CH_34_RESET_SWTCH_LED, True);
      end;
//      WriteDioSig(DefDio.OUT_CH_3_4_LAMP_OFF,false);
    end;

    nTowerLamp_R :=  DefDio.OUT_GIB_TOWER_LAMP_RED;
    nTowerLamp_Y :=  DefDio.OUT_GIB_TOWER_LAMP_YELLOW;
    nTowerLamp_G :=  DefDio.OUT_GIB_TOWER_LAMP_GREEN;
    nTowerLamp_B1 :=  DefDio.OUT_GIB_BUZZER_1;
    nTowerLamp_B2 :=  DefDio.OUT_GIB_BUZZER_2;
  end;




  //사용하지 않을 경우 갱신 안함
  if not UseTowerLamp then Exit;
  //알람에 따른 경광등 및 멜로디 처리
  nTick:= GetTickCount;

  case m_nTowerLampState of
    LAMP_STATE_NONE: begin
      //전체 끄기
      if ReadOutSig(nTowerLamp_R)    then WriteDioSig(nTowerLamp_R, True);
      if ReadOutSig(nTowerLamp_Y)    then WriteDioSig(nTowerLamp_Y, True);
      if ReadOutSig(nTowerLamp_G)    then WriteDioSig(nTowerLamp_G, True);
      if ReadOutSig(nTowerLamp_B1)    then WriteDioSig(nTowerLamp_B1, True);
      //if ReadOutSig(DefDio.OUT_MELODY_2)    then WrinTowerLamp_GteDioSig(DefDio.OUT_MELODY_2, True);
      //if ReadInSig(DefDio.OUT_MELODY_3) then WriteDinTowerLamp_BoSig(DefDio.OUT_MELODY_3, True);
      //if ReadInSig(DefDio.OUT_MELODY_4) then WriteDioSig(DefDio.OUT_MELODY_4, True);
    end;

    LAMP_STATE_MANUAL: begin
      //운전 준비 전, 수동/Pass Mode  - 황색 On .  적색 On-현장에서 아니라고 함
      if ReadOutSig(nTowerLamp_R)      then WriteDioSig(nTowerLamp_R, True);
      if not ReadOutSig(nTowerLamp_Y)  then WriteDioSig(nTowerLamp_Y, False);
      if ReadOutSig(nTowerLamp_G)      then WriteDioSig(nTowerLamp_G, True);
      if ReadOutSig(nTowerLamp_B1)      then WriteDioSig(nTowerLamp_B1, True);
      //if ReadOutSig(DefDio.OUT_MELODY_2)     then WriteDioSig(DefDio.OUT_MELODY_2, True);
    end;

    LAMP_STATE_PAUSE: begin
      //운전 준비 완료 정지 중- 녹색 점멸
      if ReadOutSig(nTowerLamp_R)     then WriteDioSig(nTowerLamp_R, True);
      if ReadOutSig(nTowerLamp_Y)     then WriteDioSig(nTowerLamp_Y, True);
      //if ReadOutSig(DefDio.OUT_GREEN_LAMP)   then WriteDioSig(DefDio.OUT_GREEN_LAMP, True);
      if (nTick - m_nTowerLampTick > 450) then begin
        if ReadOutSig(nTowerLamp_G) then begin
          WriteDioSig(nTowerLamp_G, True); //Off
        end
        else begin
          WriteDioSig(nTowerLamp_G, False); //On
        end;
        m_nTowerLampTick:= nTick;
      end;
      if ReadOutSig(nTowerLamp_B1)     then WriteDioSig(nTowerLamp_B1, True);
      if ReadOutSig(nTowerLamp_B2)     then WriteDioSig(nTowerLamp_B2, True);
    end;

    LAMP_STATE_AUTO: begin
      //운전 준비 완료 중- 녹색 On
      if ReadOutSig(nTowerLamp_R)        then WriteDioSig(nTowerLamp_R, True);
      if ReadOutSig(nTowerLamp_Y)     then WriteDioSig(nTowerLamp_Y, True);
      if not ReadOutSig(nTowerLamp_G)  then WriteDioSig(nTowerLamp_G, false);
      if ReadOutSig(nTowerLamp_B1)        then WriteDioSig(nTowerLamp_B1, True);
      //if ReadOutSig(DefDio.OUT_MELODY_2)        then WriteDioSig(DefDio.OUT_MELODY_2, True);
    end;

    LAMP_STATE_REQUEST: begin
      //원자재 투입/취출 요구- 황색 점멸, 멜로디 사용
      if ReadOutSig(nTowerLamp_R)        then WriteDioSig(nTowerLamp_R, True);
            //if ReadOutSig(DefDio.OUT_YELLOW_LAMP)     then WriteDioSig(DefDio.OUT_YELLOW_LAMP, True);
      if (nTick - m_nTowerLampTick > 450) then begin
        if ReadOutSig(nTowerLamp_Y) then begin
          WriteDioSig(nTowerLamp_Y, True);
        end
        else begin
          WriteDioSig(nTowerLamp_Y, False);
        end;
        m_nTowerLampTick:= nTick;
      end;
      if ReadOutSig(nTowerLamp_G)      then WriteDioSig(nTowerLamp_G, True);
      if MelodyOn then begin
        if not ReadOutSig(nTowerLamp_B1)    then WriteDioSig(nTowerLamp_B1);
        //if ReadOutSig(DefDio.OUT_MELODY_2)        then WriteDioSig(DefDio.OUT_MELODY_2, True);
      end
      else begin
        if ReadOutSig(nTowerLamp_B1)    then WriteDioSig(nTowerLamp_B1, True);
      end;
    end;

    LAMP_STATE_ERROR: begin
      //Error 발생중 - 적색 점멸, 멜로디
      //if ReadOutSig(DefDio.OUT_RED_LAMP)        then WriteDioSig(DefDio.OUT_RED_LAMP, False);
      if (nTick - m_nTowerLampTick > 450) then begin
        if ReadOutSig(nTowerLamp_R) then begin
          WriteDioSig(nTowerLamp_R, True);
        end
        else begin
          WriteDioSig(nTowerLamp_R, False);
        end;
        m_nTowerLampTick:= nTick;
      end;
      if ReadOutSig(nTowerLamp_Y)     then WriteDioSig(nTowerLamp_Y, True);
      if ReadOutSig(nTowerLamp_G)      then WriteDioSig(nTowerLamp_G, True);
      if MelodyOn then begin
        if not ReadOutSig(nTowerLamp_B1)    then WriteDioSig(nTowerLamp_B1, False);
        //if ReadOutSig(DefDio.OUT_MELODY_2)        then WriteDioSig(DefDio.OUT_MELODY_2, True);
      end
      else begin
        if ReadOutSig(nTowerLamp_B1)    then WriteDioSig(nTowerLamp_B1, True);
      end;
    end;

    LAMP_STATE_EMEGENCY: begin
      //비상 정지 - 적색 On, 멜로디
      if not ReadOutSig(nTowerLamp_R)    then WriteDioSig(nTowerLamp_R, False);
      if ReadOutSig(nTowerLamp_Y)     then WriteDioSig(nTowerLamp_Y, True);
      if ReadOutSig(nTowerLamp_G)      then WriteDioSig(nTowerLamp_G, True);
      if MelodyOn then begin
        if not ReadOutSig(nTowerLamp_B1)    then WriteDioSig(nTowerLamp_B1, False);
        //if ReadOutSig(DefDio.OUT_MELODY_2)        then WriteDioSig(DefDio.OUT_MELODY_2, True);
      end
      else begin
        if ReadOutSig(nTowerLamp_B1)    then WriteDioSig(nTowerLamp_B1, True);
      end;
    end;
    else begin

    end;
  end;
end;

procedure TControlDio.Process_ChangedDI(pDataMessage: PGuiDaeDio);
var
  saIems: TArray<String>;
  i, k, nIndex, nValue: Integer;
  nPos: Integer;
begin
  //변경 값 검사
  saIems:= pDataMessage.Msg.Split([',']);
  for i := 0 to Length(saIems)-1 do begin
    nPos:= Pos('=', saIems[i]);
    if nPos < 1 then Continue;

    nIndex:= StrToInt(Copy(saIems[i], 1, nPos-1));
    nValue:= StrToInt(Copy(saIems[i], nPos+1, 5));
    case nIndex of
      0: //START Switch
      begin
        if nValue <> 1 then begin
          //Auto Mode일 경우 제외
          if not Common.StatusInfo.AutoMode then begin
            SendMsgMain(COMMDIO_MSG_LOG, 0, 0, 'Press Turn Start Switch');

            for k:= DefCommon.CH1 to DefCommon.MAX_CH do begin
              if PasScr[k].m_bIsScriptWork then begin
                Exit;
              end;
            end;

            ClearOutDioSig(OUT_START_SW_LED); //시작 스위치 끄기

            //Turn
//            ThreadTurnStage;

          end;  //if not Common.StatusInfo.AutoMode then begin
        end;
      end; //IN_START_SW: //START Switch

      else begin

      end;
    end; //case nIndex of
  end; //for i := 0 to Length(saIems) do begin
end;

function TControlDio.ReadInSig(nSignal: Integer): Boolean;
var
  nIdx, nPos : Integer;
begin
  if nSignal > 95  then begin
    Result := false;
    Exit;
  end;
  nIdx := nSignal div 8; nPos := nSignal mod 8;
  Result := (CommDaeDIO.DIData[nIdx] and (1 shl nPos)) > 0;
end;

function TControlDio.ReadOutSig(nSignal: Integer): Boolean;
var
  nIdx, nPos : Integer;
begin
  if nSignal > 95  then begin
   Result := false;
   Exit
  end;
  nIdx := nSignal div 8; nPos := nSignal mod 8;
  Result := (CommDaeDIO.DODataFlush[nIdx] and (1 shl nPos)) > 0;
end;

procedure TControlDio.RefreshIo;
var
  nMode : Integer;
  bStageACam, bStageBCam : Boolean;
begin

  //ErrorCheck;
//  bStageACam := ReadInSig(DefDio.IN_A_STAGE_IN_CAM);
//  bStageBCam := ReadInSig(DefDio.IN_B_STAGE_IN_CAM);
//  if bStageACam then        LoadZoneStage := lzsB
//  else if bStageBCam then   LoadZoneStage := lzsA
//  else                      LoadZoneStage := lzsNone;
//  nMode := CommDIO_DAE.COMMDIO_MSG_CHANGE_DI;
//  SendMsgMain(nMode,0,0,'');
//  nMode := CommDIO_DAE.COMMDIO_MSG_CHANGE_DO;
//  SendMsgMain(nMode,0,0,'');

end;

// nIdx : 0 - All.
// nIdx : 1 - Only Error Check part for In IO. ( <= ERR_LIST_MC_MONITOR )
procedure TControlDio.ResetError(nIdx : Integer);
var
  i, nDiv, nMod : Integer;
  bRet : boolean;
  nTemp : Integer;
begin
  nTemp := 0;
  case  nIdx of
    0 : begin
      for i:= 0 to Pred(DefDio.MAX_ALARM_DATA_SIZE) do DioAlarmData[i] := 0;
    end;
    1 : begin
      nDiv := DefDio.ERR_LIST_MC_MONITOR div 8;
      for i := 0 to nDiv do DioAlarmData[i] := 0;

      for i := 0 to Pred(DefDio.MAX_ALARM_DATA_SIZE) do begin
        nTemp := nTemp + DioAlarmData[i];
      end;
    end;
    2 : begin
      nDiv := DefDio.ERR_LIST_MC_MONITOR div 8;
      for i := 0 to nDiv do DioAlarmData[i] := 0;

      for i := 0 to Pred(DefDio.MAX_ALARM_DATA_SIZE) do begin
        nTemp := nTemp + DioAlarmData[i];
      end;
      // if 화면에 NG 화면 있으면 닫자.
      if nTemp = 0 then SetAlarmMsg(-1,True);
    end;
  end;



  bRet := True;
end;

procedure TControlDio.SendAlarm(nType, nIndex, nValue: Integer; sMsg:String);
begin
  //기존 상태와 동일할 경우 전송하지 않음
  if Common.StatusInfo.AlarmData[nIndex] = nValue then Exit;

  if nType = MSG_MODE_SYSTEM_ALARAM then begin
    SendMsgMain(ControlDio_OC.MSG_MODE_SYSTEM_ALARAM, nIndex, nValue, sMsg);
  end
  else begin
    SendMsgMain(ControlDio_OC.MSG_MODE_DISPLAY_ALARAM, nIndex, nValue, sMsg);
  end;
end;

procedure TControlDio.SendMsgMain(nMsgMode, nParam, nParam2: Integer; sMsg: String; pData: Pointer);
var
  cds         : TCopyDataStruct;
  COPYDATAMessage : RGuiDaeDio;
begin
  COPYDATAMessage.MsgType := m_nMsgType; //MSGTYPE_COMMDIO;
  COPYDATAMessage.Channel := 1;
  COPYDATAMessage.Mode    := nMsgMode;
  COPYDATAMessage.Param   := nParam;
  COPYDATAMessage.Param2  := nParam2;
  COPYDATAMessage.Msg     := sMsg;
  COPYDATAMessage.pData   := pData;

  cds.dwData      := 0;
  cds.cbData      := SizeOf(COPYDATAMessage);
  cds.lpData      := @COPYDATAMessage;
  SendMessage(m_hMain,WM_COPYDATA,0, LongInt(@cds));
end;

procedure TControlDio.SetAlarmMsg(nIdx: Integer; bIsDisplayMessage : Boolean);
var
  nDiv, nMod : Integer;
  nValue: Integer;
  bValue: Boolean;
begin
  if nIdx < 0 then begin
    if bIsDisplayMessage then begin
      SendMsgMain(ControlDio_OC.MSG_MODE_DISPLAY_ALARAM, nIdx,0,'');
    end;
  end
  else begin
    nDiv := nIdx div 8;
    nMod := nIdx mod 8;
    bValue:= (DioAlarmData[nDiv] and ($01 shl nMod)) <> 0;
    if bValue then begin
      //이미 발생한 알람 일경우
      Exit;
    end;

    DioAlarmData[nDiv] := DioAlarmData[nDiv] or (1 shl nMod);
    if bIsDisplayMessage then begin
      SendMsgMain(ControlDio_OC.MSG_MODE_DISPLAY_ALARAM, nIdx,0,'');
    end;
  end;
end;

procedure TControlDio.Set_AlarmData(nIndex, nValue: Integer);
var
  nDiv, nMod : Integer;
  bValue: Boolean;
begin
  nDiv := nIndex div 8;
  nMod := nIndex mod 8;
  if nValue <> 0 then
  begin
    //알람 발생
    DioAlarmData[nDiv]:= DioAlarmData[nDiv] or ($01 shl nMod);
  end else
  begin
    //알람 해제
    DioAlarmData[nDiv]:= DioAlarmData[nDiv] and not ($01 shl nMod);
  end;
end;

procedure TControlDio.Set_TowerLampState(nState: Integer);
begin
  m_nTowerLampState:= nState;
  //CommDaeDIO.Set_TowerLampState(nState);
end;

procedure TControlDio.TaskThread(task: TProc);
var
  th : TThread;
begin
  if m_bIoThreadWork then Exit;
  m_bIoThreadWork := True;
  th := TThread.CreateAnonymousThread(task);
  th.OnTerminate := TaskThreadTerminiate;
  th.Start;
end;
//
//procedure TControlDio.ThreadTurnStage;
//var
//  i, nRet : Integer;
//  sDebug : string;
//begin
//  //Turn 처리
//  TThread.CreateAnonymousThread( procedure begin
//    if LoadZoneStage = lzsB then begin
//      nRet:= TurnStage(True);
//    end
//    else begin
//      nRet:= TurnStage(False);
//    end;
//    if nRet <> 0 then begin
//      //Turn NG - 중알람
//      case nRet of
//        2: begin //ContactUp NG
//          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_POGO_DN_SENSOR_1CH, 1, '');
//        end;
//        3: begin //Shutter Up NG
//          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_SHUTTER_UP_SENSOR, 1, '');
//        end;
//        4, 5: begin //TurnTable  NG
//          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_B_STAGE_IN_CAM, 1, '');
//        end;
//        7: begin //Shutter Down NG
//          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_SHUTTER_DN_SNENSOR, 1, '');
//        end;
//        8: begin //Motor Stop Sensor NG
//          SendAlarm(MSG_MODE_SYSTEM_ALARAM, IN_MORTOR_STOP_SENSOR, 1, '');
//        end;
//      end;
//    end;
//  end).Start;
//end;

procedure TControlDio.TaskThreadTerminiate(Sender: TObject);
begin
  //Finish Turn Thread
  m_bIoThreadWork := False;
end;

procedure TControlDio.test;
begin
  SetAlarmMsg(DefDio.ERR_LIST_CAMP_UP_SENSOR_1);

end;


function TControlDio.WriteCheck(nIdx: Integer): Integer;
var
  nRet, i : Integer;
  bRet : boolean;
begin
  nRet := 0;
//  case nIdx of
//    // Turn 조건.
//    DefDio.OUT_A_STAGE_FRONT, DefDio.OUT_B_STAGE_FRONT : begin
//      // 1. Shutter가 닫혀 있으면 돌지 말자.
////      if CheckDi(DefDio.IN_SHUTTER_DN_SNENSOR) then begin
////        nRet := DefDio.IN_SHUTTER_DN_SNENSOR;
////        SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_SHUTTER_DN_SNENSOR, 1, '');
//////        SetAlarmMsg(nRet,False);
////      end;
//
//
//      if CheckDi(DefDio.IN_CH_1_2_DOOR_LEFT_OPEN) then begin
//        nRet := DefDio.IN_CH_1_2_DOOR_LEFT_OPEN;
//        SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_1_2_DOOR_LEFT_OPEN, 1, '');
//
////        SetAlarmMsg(nRet,False);
//      end;
//      if CheckDi(DefDio.IN_CH_1_2_DOOR_RIGHT_OPEN) then begin
//        nRet := DefDio.IN_CH_1_2_DOOR_LEFT_OPEN;
//        SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_1_2_DOOR_LEFT_OPEN, 1, '');
//
////        SetAlarmMsg(nRet,False);
//      end;
//            if CheckDi(DefDio.IN_CH_3_4_DOOR_LEFT_OPEN) then begin
//        nRet := DefDio.IN_CH_1_2_DOOR_LEFT_OPEN;
//        SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_1_2_DOOR_LEFT_OPEN, 1, '');
//
////        SetAlarmMsg(nRet,False);
//      end;
//      if CheckDi(DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN) then begin
//        nRet := DefDio.IN_CH_3_4_DOOR_RIGHT_OPEN;
//        SendAlarm(MSG_MODE_DISPLAY_ALARAM, IN_CH_3_4_DOOR_RIGHT_OPEN, 1, '');
//
////        SetAlarmMsg(nRet,False);
//      end;
//    end;
//  end;
  Result := nRet;
end;

function TControlDio.WriteDioSig(nSignal: Integer; bIsRemove: Boolean): Integer;
var
  nIdx, nPos, nValue : Integer;
  nRet: Integer;
begin
  if not (nSignal in [DefDio.OUT_RESET_SWITCH_LED,DefDio.OUT_TOWER_LAMP_RED, DefDio.OUT_TOWER_LAMP_YELLOW, DefDio.OUT_TOWER_LAMP_GREEN, DefDio.OUT_BUZZER_1 ]) then  begin
    //if ErrorCheck > 0 then Exit(1);
    if m_bDoorOpen then Exit;
  end;

//  if not bIsRemove then begin
//    nRet:= WriteCheck(nSignal);
//    if ( nRet > 0) then Exit(nRet);
//  end;

//  if nSignal = DefDio.OUT_ION_BAR_SOL then begin
//    DaeIonizer[0].IsIgnoreNg := bIsRemove;
//  end;

  nIdx := nSignal div 8; nPos := nSignal mod 8;
  if bIsRemove then nValue := 0
  else              nValue := 1;

  CommDaeDIO.WriteDO_Bit(nIdx,nPos,nValue);
  DisplayIo;
  Result := 0;
end;


function TControlDio.WaitSignal(nIndex, nValue: Byte; nWaitTime: Cardinal): Cardinal;
var
  nTick, nStartTick: Cardinal;
  nAddr, nBitLoc: Byte;
begin
  Result:= 1;
  nAddr:= nIndex div  8;
  nBitLoc:= nIndex mod 8;
  nStartTick:= GetTickCount;
  nTick:= nStartTick;

  while (nTick - nStartTick) < nWaitTime  do begin
    if CommDaeDIO.Get_Bit(CommDaeDIO.DIData[nAddr], nBitLoc) = nValue then begin
      Result:= 0;
      break;
    end;
    Sleep(10);
    nTick:= GetTickCount;
  end;
end;


procedure TControlDio.CommDIONotify(Sender: TObject; pDataMessage: PGuiDaeDio);
var
  nMode, nParam, nRet : Integer;
  bStageACam, bStageBCam : Boolean;
  i: Integer;
begin
  nMode := pDataMessage^.Mode;
  nRet := 0;

  case nMode of
    CommDIO_DAE.COMMDIO_MSG_CONNECT : begin
      nParam := pDataMessage^.Param;
      if nParam <> 0 then begin
        m_bConnected := True;
//        CheckState; //상태 확인
        CheckAlarm; //알람 확인
      end
      else begin
        m_bConnected := False;
      end;

      PostMessage(m_hMain,WM_USER+1, nMode, nParam); //DIO 갱신 요청
    end;  //CommDIO_DAE.COMMDIO_MSG_CONNECT : begin

    CommDIO_DAE.COMMDIO_MSG_CHANGE_DI : begin
      if m_bConnected then  begin
//        CheckState; //상태 확인
        CheckAlarm; //알람 확인

        //변경된 값 처리
        Process_ChangedDI(pDataMessage);
        PostMessage(m_hMain,WM_USER+1, nMode, 0); //DIO 갱신 요청
      end;
   
    end; //CommDIO_DAE.COMMDIO_MSG_CHANGE_DI : begin

    CommDIO_DAE.COMMDIO_MSG_CHANGE_DO : begin
      PostMessage(m_hMain,WM_USER+1, nMode, 0);
      //ErrorCheck;
    end;
    CommDIO_DAE.COMMDIO_MSG_ERROR : begin
      if pDataMessage.Param = 100 then begin
        LastNgMsg := 'Disconnected DIO Card....';
        SendAlarm(MSG_MODE_SYSTEM_ALARAM, ERR_LIST_DIO_CARD_DISCONNECTED, 1, LastNgMsg);
        m_bConnected := False;
      end;
    end; //CommDIO_DAE.COMMDIO_MSG_ERROR : begin
  end;
  if m_bConnected then begin
    // Main GUI에 상태 Display.
    //SendMsgMain(nMode,pDataMessage^.Param,pDataMessage^.Param2,pDataMessage^.Msg);
  end;
end;

end.
