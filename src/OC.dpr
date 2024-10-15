program OC;



uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  Winapi.Windows,
  Main_OC in 'Main_OC.pas' {frmMain_OC},
  Test4ChOC in 'Test4ChOC.pas' {frmTest4ChOC},
  Vcl.Themes,
  Vcl.Styles,
  DefCam in 'DefCam.pas',
  DefPG in 'DefPG.pas',
  Mainter in 'Mainter.pas' {frmMainter},
  pasScriptClass in 'pasScriptClass.pas',
  SystemSetup in 'SystemSetup.pas' {frmSystemSetup},
  DfsFtp in 'DfsFtp.pas',
  DefCommon in 'DefCommon.pas',
  DioDisplayAlarm in 'DioDisplayAlarm.pas' {frmDisplayAlarm},
  DefDio in 'DefDio.pas',
  CommonClass in 'CommonClass.pas',
  ModelInfo in 'ModelInfo.pas' {frmModelInfo},
  CommDIO_DAE in 'CommDIO_DAE.pas',
  ControlDio_OC in 'ControlDio_OC.pas',
  CommIonizer in 'CommIonizer.pas',
  CommLightNaratech in 'CommLightNaratech.pas',
  SwitchBtn in 'SwitchBtn.pas',
  ECSStatusForm in 'ECSStatusForm.pas' {frmECSStatus},
  CommPLC_ECS in 'CommPLC_ECS.pas',
  PlcSimluateForm in 'PlcSimluateForm.pas' {frmPlcSimulate},
  InternalScriptClass in 'InternalScriptClass.pas',
  DoorOpenAlarmMsg in 'DoorOpenAlarmMsg.pas' {frmDoorOpenAlarmMsg},
  LogIn in 'LogIn.pas' {frmLogIn},
  DBModule in 'DBModule.pas' {DBModule_Sqlite: TDataModule},
  NGRatioForm in 'NGRatioForm.pas' {frmNGRatio},
  GMesCom in 'GMesCom.pas',
  SelectDetect in 'SelectDetect.pas' {frmSelectDetect},
  ModelSelect in 'ModelSelect.pas',
  CA_SDK2 in 'CA_SDK2.pas',
  DefGmes in 'DefGmes.pas',
  DefAF9 in 'DefAF9.pas',
  dllClass in 'dllClass.pas',
  UserUtils in 'UserUtils.pas',
  CommPG in 'CommPG.pas',
  DllMesCom in 'DllMesCom.pas',
  DllActUtlType64Com in 'DllActUtlType64Com.pas',
  FTPClient in 'FTPClient.pas',
  JigControl in 'JigControl.pas',
  LogicVh in 'LogicVh.pas',
  VirtualBcrForm in 'VirtualBcrForm.pas' {VirtualBcr},
  CommTCP_PLC in 'CommTCP_PLC.pas',
  ECSRequestForm in 'ECSRequestForm.pas' {ECSTestForm},
  LibCa410Option in 'LibCa410Option.pas',
  LibCommFuncs in 'LibCommFuncs.pas',
  CommThermometerMulti in 'CommThermometerMulti.pas';

{$R *.res}

var
  runOnceMutex: THandle;
  wnd: THandle;
begin
  runOnceMutex:= CreateMutex( nil, TRUE, 'ITOLED OC Should be Run Only One Time!');

    if (GetLastError = ERROR_ALREADY_EXISTS) then begin

      wnd:= FindWindow('TfrmMain_OC', nil);
      if wnd <> 0 then begin
        SetForegroundWindow(wnd);
        //PostMessage(wnd, WM_USER + 1, 0, 0);

        WaitForSingleObject(HWND_BROADCAST, $FFFFFFFF ) ; //wait for "posted notification" flag to clear
        ResetEvent(HWND_BROADCAST); //reset event
      end;

      CloseHandle(runOnceMutex);
      Exit;
    end;


    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    TStyleManager.TrySetStyle('Windows10');
    Application.CreateForm(TfrmMain_OC, frmMain_OC);
    Application.Run;

    CloseHandle(runOnceMutex);



end.
