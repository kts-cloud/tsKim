unit DioDisplayAlarm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls, DefDio, ControlDio_OC, CommonClass,
  Vcl.StdCtrls, RzButton,DefCommon;

type
  ///<summary>Alarm 발생 시 알람 발생한 위치 표시</summary>
  TfrmDisplayAlarm = class(TForm)
    imgEquipment: TImage;
    shpDi22NG: TShape;
    shpDi24NG: TShape;
    shpDi21NG: TShape;
    shpDi06NG: TShape;
    shpDi08NG: TShape;
    shpDi23NG: TShape;
    shpDi01NG: TShape;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    mmoMessage: TMemo;
    pnImage: TPanel;
    tmrFlickering: TTimer;
    pnAlarmMessage: TPanel;
    lblTitle: TLabel;
    shpDi07NG: TShape;
    shpDi09NG: TShape;
    shpDi16NG: TShape;
    shpDi25: TShape;
    shpDi181NG: TShape;
    shpDi182NG: TShape;
    shpDi14NG: TShape;
    btnResetError: TRzBitBtn;
    btnExit: TRzBitBtn;
    btnStopBuzzer: TRzBitBtn;
    shpDi183NG: TShape;
    shpDi184NG: TShape;
    shppPreOCDi04: TShape;
    shppPreOCDi05: TShape;
    shppPreOCDi10: TShape;
    shppPreOCDi11: TShape;
    shppPreOCDi16NG: TShape;
    shppPreOCDi58NG: TShape;
    shppPreOCDi59NG: TShape;
    shppPreOCDi60NG: TShape;
    shppPreOCDi61NG: TShape;
    shppPreOCDi03NG: TShape;
    shppPreOCDi02NG: TShape;
    shppPreOCDi00NG: TShape;
    shppPreOCDi01NG: TShape;
    shppPreOCDi64NG: TShape;
    shppPreOCDi65NG: TShape;
    shppPreOCDi68NG: TShape;
    shppPreOCDi69NG: TShape;
    shppOCDi40NG: TShape;
    shppOCDi41NG: TShape;
    Shape3: TShape;
    Shape4: TShape;
    shppOCDi53NG: TShape;
    shppOCDi54NG: TShape;
    shppOCDi27NG: TShape;
    shppOCDi28NG: TShape;
    shppOCDi14NG: TShape;
    shppOCDi15NG: TShape;
    procedure FormCreate(Sender: TObject);
    procedure tmrFlickeringTimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnExitClick(Sender: TObject);
    procedure btnResetErrorClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnStopBuzzerClick(Sender: TObject);
  private
    { Private declarations }
    ///<summary>Alarm Data List Array</summary>
    m_naAlarmData: array [0.. DefDio.MAX_ALARM_DATA_SIZE] of Integer;
    ///<summary>알람 영역 깜빡임 처리</summary>
    procedure FlickeringShape(AStyle: TBrushStyle);
    ///<summary>해당 위치의 Bit값을 반환한다.</summary>
    ///<param> nData: Alarm Flag Data </param>
    ///<param> nLoc: 읽을 비트의 위치 값</param>
    function Get_Bit(var nData: Integer; nLoc: Integer): Integer;
    function Get_Pos(nDef : Integer) : Boolean;
  public
    { Public declarations }
    ///<summary>Alarm Data Set</summary>
    ///<param> naAlarmData: 알람 비트 값을 가지는 배열</param>
    procedure SetAlarmData(naAlarmData: array of Integer);
    procedure RefreshDisplay;
  end;

var
  frmDisplayAlarm: TfrmDisplayAlarm;

implementation

{$R *.dfm}

uses Main_OC;

{ TDispAlarmForm }


procedure ScaleImageToResolution(Image: TImage);
var
  ScreenWidth, ScreenHeight: Integer;
  ScaleFactor: Double;
  ScaledWidth, ScaledHeight: Integer;
  Bitmap: TBitmap;
begin
  // 현재 화면 해상도를 가져옵니다.
  ScreenWidth := Screen.Width;
  ScreenHeight := Screen.Height;

  // 해상도에 따른 스케일 팩터를 계산합니다.
  if ScreenWidth > 1920 then
    ScaleFactor := 1.5
//  else if ScreenWidth > 1280 then
//    ScaleFactor := 1.25
  else
    ScaleFactor := 1.0;

  // TImage의 크기를 조절합니다.
  ScaledWidth := Round(Image.Picture.Width * ScaleFactor);
  ScaledHeight := Round(Image.Picture.Height * ScaleFactor);
  Image.Width := ScaledWidth;
  Image.Height := ScaledHeight;

  // 이미지를 스케일링합니다.
  Bitmap := TBitmap.Create;
  try
    Bitmap.SetSize(ScaledWidth, ScaledHeight);
    Bitmap.Canvas.StretchDraw(Rect(0, 0, ScaledWidth, ScaledHeight), Image.Picture.Graphic);
    Image.Picture.Graphic := Bitmap;
  finally
    Bitmap.Free;
  end;
end;

procedure TfrmDisplayAlarm.FormCreate(Sender: TObject);
var
sImageName : string;
begin
  //Init_ErrMessage;
   FormStyle := fsStayOnTop; // 폼을 항상 최상위로 유지
  if Common.SystemInfo.OCType = DefCommon.OCType  then
    sImageName := 'OC.png'
  else sImageName := 'Pre_OC.png';
  imgEquipment.Picture.LoadFromFile(Common.Path.IMAGE +sImageName);

  // 해상도에 따라 이미지를 스케일링합니다.
  ScaleImageToResolution(imgEquipment);
  mmoMessage.Lines.Clear;
end;

procedure TfrmDisplayAlarm.FormShow(Sender: TObject);
begin
//  SetWindowPos(Self.handle, HWND_TOPMOST, Self.Left, Self.Top, Self.Width, Self.Height,0);
  RefreshDisplay;
end;

procedure TfrmDisplayAlarm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:= caFree;
  frmDisplayAlarm:= nil;
end;

procedure TfrmDisplayAlarm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  tmrFlickering.Enabled:= False;
end;

procedure TfrmDisplayAlarm.SetAlarmData(naAlarmData:  array of Integer);
var
  i: Integer;
begin
  CopyMemory(@m_naAlarmData, @naAlarmData, sizeof(Integer) * DefDio.MAX_ALARM_DATA_SIZE);
  // Reset button display.
  btnResetError.Visible := False;
  for i := 3 to 10 do begin
    if m_naAlarmData[I] = 0 then continue;
    btnResetError.Visible := True;
    Break;
  end;
  // Error display.
  RefreshDisplay;
end;

procedure ShapeCheck(Shape : TShape; bOKNG : Boolean);
begin
  Shape.Visible := True;
  if not bOKNG then begin
    Shape.Brush.Color := clLime;
    Shape.Pen.Color   := clLime;
  end
  else begin
    Shape.Brush.Color := clRed;
    Shape.Pen.Color   := clRed;
  end;

end;

procedure TfrmDisplayAlarm.RefreshDisplay;
var
  I: Integer;
begin
  mmoMessage.Lines.Clear;
  for I := 0 to 150 do begin
    if Common.StatusInfo.AlarmData[I] = 0 then continue;  //0일 경우 비교 불필요
    if Common.StatusInfo.AlarmMsg[I] <> '' then begin
      mmoMessage.Lines.Add(Common.StatusInfo.AlarmMsg[I]);
    end;
  end; //for I := 0 to 5 do

  //알람이 있을 경우 해당 위치에 표시
  //위치 표시 Shape의 이름을 메모리 번지를 이용하여 명명
  if Common.StatusInfo.AlarmData[ERR_LIST_DIO_CARD_DISCONNECTED] <> 0 then   Exit;

  if Common.SystemInfo.OCType = DefCommon.OCType  then  begin

    ShapeCheck(shpDi01NG,Common.StatusInfo.AlarmData[IN_EMO_SWITCH] <> 0);

    ShapeCheck(shpDi06NG,Common.StatusInfo.AlarmData[IN_FAN_1_EXHAUST] <> 0);


    ShapeCheck(shpDi07NG,Common.StatusInfo.AlarmData[IN_FAN_2_INTAKE] <> 0);


    ShapeCheck(shpDi08NG,Common.StatusInfo.AlarmData[IN_FAN_3_EXHAUST] <> 0);


    ShapeCheck(shpDi09NG,Common.StatusInfo.AlarmData[IN_FAN_4_INTAKE] <> 0);


    ShapeCheck(shpDi14NG,Common.StatusInfo.AlarmData[IN_CYL_PRESSURE_GAUGE] <> 0);


    ShapeCheck(shpDi16NG,Common.StatusInfo.AlarmData[IN_TEMPERATURE_ALARM] <> 0);

    ShapeCheck(shppOCDi14NG,Common.StatusInfo.AlarmData[IN_CH_1_PROBE_UP_SENSOR] <> 0);
    ShapeCheck(shppOCDi15NG,Common.StatusInfo.AlarmData[IN_CH_1_PROBE_DOWN_SENSOR] <> 0);
    ShapeCheck(shppOCDi27NG,Common.StatusInfo.AlarmData[IN_CH_2_PROBE_UP_SENSOR] <> 0);
    ShapeCheck(shppOCDi28NG,Common.StatusInfo.AlarmData[IN_CH_2_PROBE_DOWN_SENSOR] <> 0);
    ShapeCheck(shppOCDi40NG,Common.StatusInfo.AlarmData[IN_CH_3_PROBE_UP_SENSOR] <> 0);
    ShapeCheck(shppOCDi41NG,Common.StatusInfo.AlarmData[IN_CH_3_PROBE_DOWN_SENSOR] <> 0);
    ShapeCheck(shppOCDi53NG,Common.StatusInfo.AlarmData[IN_CH_4_PROBE_UP_SENSOR] <> 0);
    ShapeCheck(shppOCDi54NG,Common.StatusInfo.AlarmData[IN_CH_4_PROBE_DOWN_SENSOR] <> 0);

  //  shpDi17.Visible   := Common.StatusInfo.AlarmData[IN_POWER_HIGH_ALARM] <> 0;
    // Light Curtain.
  //  shpDi181.Visible  := Common.StatusInfo.AlarmData[IN_LIGHT_CURTAIN] <> 0;
  //  shpDi182.Visible  := Common.StatusInfo.AlarmData[IN_LIGHT_CURTAIN] <> 0;
    // Door.
    ShapeCheck(shpDi21NG,Common.StatusInfo.AlarmData[IN_CH_1_2_DOOR_LEFT_OPEN] <> 0);
    ShapeCheck(shpDi22NG,Common.StatusInfo.AlarmData[IN_CH_1_2_DOOR_RIGHT_OPEN] <> 0);
    ShapeCheck(shpDi23NG,Common.StatusInfo.AlarmData[IN_CH_3_4_DOOR_LEFT_OPEN] <> 0);
    ShapeCheck(shpDi24NG,Common.StatusInfo.AlarmData[IN_CH_3_4_DOOR_RIGHT_OPEN] <> 0);
    // Reset button
    ShapeCheck(shpDi25,Common.StatusInfo.AlarmData[IN_MC_MONITORING] <> 0);
  end
  else begin
    ShapeCheck(shppPreOCDi00NG,Common.StatusInfo.AlarmData[IN_FAN_1_EXHAUST] <> 0);

    ShapeCheck(shppPreOCDi01NG,Common.StatusInfo.AlarmData[IN_FAN_2_INTAKE] <> 0);

    ShapeCheck(shppPreOCDi02NG,Common.StatusInfo.AlarmData[IN_FAN_3_EXHAUST] <> 0);

    ShapeCheck(shppPreOCDi03NG,Common.StatusInfo.AlarmData[IN_FAN_4_INTAKE] <> 0);

     // shutter error.
    ShapeCheck(shppPreOCDi58NG,Common.StatusInfo.AlarmData[IN_GIB_CH_12_SHUTTER_UP_SENSOR] <> 0);
    ShapeCheck(shppPreOCDi60NG,Common.StatusInfo.AlarmData[IN_GIB_CH_34_SHUTTER_UP_SENSOR] <> 0);
    ShapeCheck(shppPreOCDi59NG,Common.StatusInfo.AlarmData[IN_GIB_CH_12_SHUTTER_DN_SENSOR] <> 0);
    ShapeCheck(shppPreOCDi61NG,Common.StatusInfo.AlarmData[IN_GIB_CH_34_SHUTTER_DN_SENSOR] <> 0);

    // Probe error.
    ShapeCheck(shppPreOCDi64NG,Common.StatusInfo.AlarmData[IN_GIB_CH_12_PROBE_UP_SENSOR] <> 0);
    ShapeCheck(shppPreOCDi65NG,Common.StatusInfo.AlarmData[IN_GIB_CH_12_PROBE_DN_SENSOR] <> 0);
    ShapeCheck(shppPreOCDi68NG,Common.StatusInfo.AlarmData[IN_GIB_CH_34_PROBE_UP_SENSOR] <> 0);
    ShapeCheck(shppPreOCDi69NG,Common.StatusInfo.AlarmData[IN_GIB_CH_34_PROBE_DN_SENSOR] <> 0);


    ShapeCheck(shppPreOCDi04,Common.StatusInfo.AlarmData[IN_GIB_CH_12_EMO_SWITCH] <> 0);
    ShapeCheck(shppPreOCDi05,Common.StatusInfo.AlarmData[IN_GIB_CH_34_EMO_SWITCH] <> 0);
      // Main Air Pressure.
    ShapeCheck(shppPreOCDi16NG,Common.StatusInfo.AlarmData[IN_GIB_CYL_PRESSURE_GAUGE] <> 0);
      // Reset button
    ShapeCheck(shppPreOCDi10,Common.StatusInfo.AlarmData[IN_GIB_CH_12_MC_MONITORING] <> 0);
    ShapeCheck(shppPreOCDi11,Common.StatusInfo.AlarmData[IN_GIB_CH_34_MC_MONITORING] <> 0);
//     Light Curtain.
    ShapeCheck(shpDi181NG,Common.StatusInfo.AlarmData[IN_GIB_CH_12_LIGHTCURTAIN] <> 0);
    ShapeCheck(shpDi182NG,Common.StatusInfo.AlarmData[IN_GIB_CH_12_LIGHTCURTAIN] <> 0);
    ShapeCheck(shpDi183NG,Common.StatusInfo.AlarmData[IN_GIB_CH_34_LIGHTCURTAIN] <> 0);
    ShapeCheck(shpDi184NG,Common.StatusInfo.AlarmData[IN_GIB_CH_34_LIGHTCURTAIN] <> 0);
  end;
end;

procedure TfrmDisplayAlarm.btnResetErrorClick(Sender: TObject);
var
  i: Integer;
begin
//  ControlDio.ResetError(0);
//  ControlDio.Set_TowerLampState(LAMP_STATE_PAUSE);
  for i := 0 to 149 do begin
    Common.StatusInfo.AlarmData[i]:= 0;
  end;

  frmMain_OC.DoAlarmReset;

  Close;
end;

procedure TfrmDisplayAlarm.btnStopBuzzerClick(Sender: TObject);
begin
  ControlDio.MelodyOn:= False;
end;

procedure TfrmDisplayAlarm.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmDisplayAlarm.tmrFlickeringTimer(Sender: TObject);
begin
  if tmrFlickering.Tag = 0 then
  begin
    tmrFlickering.Tag:= 1;
    lblTitle.Color:= clYellow;
    FlickeringShape(bsSolid);
  end else
  begin
    tmrFlickering.Tag:= 0;
    lblTitle.Color:= clRed;
    FlickeringShape(bsBDiagonal);
  end;

end;

procedure TfrmDisplayAlarm.FlickeringShape(AStyle: TBrushStyle);
var
  I: Integer;
begin
  for I := 0 to Pred(pnImage.ControlCount) do  begin
    if pnImage.Controls[I] is TShape then  begin
      if pnImage.Controls[I].Visible then  begin
        //(pnImage.Controls[I] as TShape).Brush.Color:= clRed; //bsClear후에 색상 없어짐 방지
        (pnImage.Controls[I] as TShape).Brush.Style:= AStyle;
      end;
    end;
  end;
end;

function TfrmDisplayAlarm.Get_Bit(var nData: Integer; nLoc: Integer): Integer;
begin
  Result := (nData shr nLoc) and $01;
end;

function TfrmDisplayAlarm.Get_Pos(nDef: Integer): Boolean;
var
  nDev, nMod : Integer;
begin
  nDev := nDef div 8;
  nMod := nDef mod 8;
  Result := (m_naAlarmData[nDev] and (1 shl nMod)) > 0 ;
end;

end.
