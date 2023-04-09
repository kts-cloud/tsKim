unit PlcDisplayAlarm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Vcl.StdCtrls;

type
  ///<summary>Alarm 발생 시 알람 발생한 위치 표시</summary>
  TfrmDisplayAlarm = class(TForm)
    imgEquipment: TImage;
    shpDi02: TShape;
    shpDi22: TShape;
    shpDi24: TShape;
    shpDi13: TShape;
    shpDi12: TShape;
    shpDi11: TShape;
    shpDi21: TShape;
    shpDi06: TShape;
    shpDi08: TShape;
    shpDi23: TShape;
    shpDi04: TShape;
    shpDi01: TShape;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    shpDiC1: TShape;
    Label5: TLabel;
    mmoMessage: TMemo;
    pnImage: TPanel;
    tmrFlickering: TTimer;
    pnAlarmMessage: TPanel;
    lblTitle: TLabel;
    Label7: TLabel;
    shpDi10: TShape;
    shpDi07: TShape;
    shpDi09: TShape;
    shpDi17: TShape;
    shpDi05: TShape;
    Label6: TLabel;
    shpDiC7: TShape;
    Label11: TLabel;
    Shape6: TShape;
    Label12: TLabel;
    shpDiC8: TShape;
    Label13: TLabel;
    shpDiC6: TShape;
    Label14: TLabel;
    shpDiC5: TShape;
    shpDiC2: TShape;
    Label8: TLabel;
    shpDiC3: TShape;
    Label9: TLabel;
    shpDiC4: TShape;
    Label10: TLabel;
    shpDi16: TShape;
    shpDi25: TShape;
    shpDi03: TShape;
    shpDi181: TShape;
    shpDi182: TShape;
    shpDi14: TShape;
    shpDi291: TShape;
    shpDi292: TShape;
    procedure FormCreate(Sender: TObject);
    procedure tmrFlickeringTimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    ///<summary>Alarm Data List Array</summary>
    m_naAlarmData: array [0..7] of Integer;
    ///<summary>Alarm Message List Array</summary>
    m_saErrMessage: array [0..7,0..7] of string;
    ///<summary>Alarm Message List 초기화-배열에 문자열 대입</summary>
    procedure Init_ErrMessage;
    procedure RefreshDisplay;
    ///<summary>알람 영역 깜빡임 처리</summary>
    procedure FlickeringShape(AStyle: TBrushStyle);
    ///<summary>해당 위치의 Bit값을 반환한다.</summary>
    ///<param> nData: Alarm Flag Data </param>
    ///<param> nLoc: 읽을 비트의 위치 값</param>
    function Get_Bit(var nData: Integer; nLoc: Integer): Integer;
  public
    { Public declarations }
    ///<summary>Alarm Data Set</summary>
    ///<param> naAlarmData: 알람 비트 값을 가지는 배열</param>
    procedure SetAlarmData(naAlarmData: array of Integer);
  end;

var
  frmDisplayAlarm: TfrmDisplayAlarm;

implementation

{$R *.dfm}

{ TDispAlarmForm }

procedure TfrmDisplayAlarm.FormCreate(Sender: TObject);
begin
  Init_ErrMessage;
  mmoMessage.Lines.Clear;
end;

procedure TfrmDisplayAlarm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  tmrFlickering.Enabled:= False;
end;

procedure TfrmDisplayAlarm.SetAlarmData(naAlarmData:  array of Integer);
begin
  CopyMemory(@m_naAlarmData, @naAlarmData, sizeof(Integer) * 7);
  RefreshDisplay;
end;

procedure TfrmDisplayAlarm.RefreshDisplay;
var
  I, K: Integer;
begin
  mmoMessage.Lines.Clear;
  for I := 0 to 6 do begin
    if m_naAlarmData[I] = 0 then continue;  //0일 경우 비교 불필요
    for K := 0 to 15 do begin
      if Get_Bit(m_naAlarmData[I], K) = 1 then begin
        mmoMessage.Lines.Add(m_saErrMessage[I, K]);
      end; //if Get_Bit(naAlarmData[I], K) = 1 then
    end; //for K := 0 to 15 do
  end; //for I := 0 to 5 do

  //알람이 있을 경우 해당 위치에 표시
  //위치 표시 Shape의 이름을 메모리 번지를 이용하여 명명
  shpDi01.Visible := (Get_Bit(m_naAlarmData[0],1) = 1);
  shpDi02.Visible := (Get_Bit(m_naAlarmData[0],2) = 1);
  shpDi03.Visible := (Get_Bit(m_naAlarmData[0],3) = 1);
  shpDi04.Visible := (Get_Bit(m_naAlarmData[0],4) = 1);
  shpDi05.Visible := (Get_Bit(m_naAlarmData[0],5) = 1);

  // 흡기 배기.
  shpDi06.Visible := (Get_Bit(m_naAlarmData[0],6) = 1);
  shpDi07.Visible := (Get_Bit(m_naAlarmData[0],7) = 1);


  shpDi08.Visible := (Get_Bit(m_naAlarmData[1],0) = 1);
  shpDi09.Visible := (Get_Bit(m_naAlarmData[1],1) = 1);
  shpDi10.Visible := (Get_Bit(m_naAlarmData[1],2) = 1);
  shpDi11.Visible := (Get_Bit(m_naAlarmData[1],3) = 1);
  shpDi12.Visible := (Get_Bit(m_naAlarmData[1],4) = 1);
  shpDi13.Visible := (Get_Bit(m_naAlarmData[1],5) = 1);

  // Main Air Pressure.
  shpDi14.Visible := (Get_Bit(m_naAlarmData[1],6) = 1);

  //
  shpDi16.Visible   := (Get_Bit(m_naAlarmData[2],1) = 1);
  shpDi17.Visible   := (Get_Bit(m_naAlarmData[2],1) = 1);
  shpDi181.Visible  := (Get_Bit(m_naAlarmData[2],2) = 1);
  shpDi182.Visible  := (Get_Bit(m_naAlarmData[2],2) = 1);
  shpDi21.Visible   := (Get_Bit(m_naAlarmData[2],5) = 1);
  shpDi22.Visible   := (Get_Bit(m_naAlarmData[2],6) = 1);
  shpDi23.Visible   := (Get_Bit(m_naAlarmData[2],7) = 1);

  shpDi24.Visible   := (Get_Bit(m_naAlarmData[3],0) = 1);
  shpDi25.Visible   := (Get_Bit(m_naAlarmData[3],1) = 1);
  shpDi291.Visible   := (Get_Bit(m_naAlarmData[3],5) = 1);
  shpDi292.Visible   := (Get_Bit(m_naAlarmData[3],5) = 1);

  shpDiC1.Visible := (Get_Bit(m_naAlarmData[4],0) = 1) or (Get_Bit(m_naAlarmData[4],1) = 1) or
                     (Get_Bit(m_naAlarmData[4],2) = 1) or (Get_Bit(m_naAlarmData[4],3) = 1);

  shpDiC2.Visible := (Get_Bit(m_naAlarmData[4],4) = 1) or (Get_Bit(m_naAlarmData[4],5) = 1) or
                     (Get_Bit(m_naAlarmData[4],6) = 1) or (Get_Bit(m_naAlarmData[4],7) = 1);

  shpDiC3.Visible := (Get_Bit(m_naAlarmData[5],0) = 1) or (Get_Bit(m_naAlarmData[5],1) = 1) or
                     (Get_Bit(m_naAlarmData[5],2) = 1) or (Get_Bit(m_naAlarmData[5],3) = 1);

  shpDiC4.Visible := (Get_Bit(m_naAlarmData[5],4) = 1) or (Get_Bit(m_naAlarmData[5],5) = 1) or
                     (Get_Bit(m_naAlarmData[5],6) = 1) or (Get_Bit(m_naAlarmData[5],7) = 1);

  shpDiC5.Visible := (Get_Bit(m_naAlarmData[6],0) = 1) or (Get_Bit(m_naAlarmData[6],1) = 1) or
                     (Get_Bit(m_naAlarmData[6],2) = 1) or (Get_Bit(m_naAlarmData[6],3) = 1);

  shpDiC6.Visible := (Get_Bit(m_naAlarmData[6],4) = 1) or (Get_Bit(m_naAlarmData[6],5) = 1) or
                     (Get_Bit(m_naAlarmData[6],6) = 1) or (Get_Bit(m_naAlarmData[6],7) = 1);

  shpDiC7.Visible := (Get_Bit(m_naAlarmData[7],0) = 1) or (Get_Bit(m_naAlarmData[7],1) = 1) or
                     (Get_Bit(m_naAlarmData[7],2) = 1) or (Get_Bit(m_naAlarmData[7],3) = 1);

  shpDiC8.Visible := (Get_Bit(m_naAlarmData[7],4) = 1) or (Get_Bit(m_naAlarmData[7],5) = 1) or
                     (Get_Bit(m_naAlarmData[7],6) = 1) or (Get_Bit(m_naAlarmData[7],7) = 1);
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

procedure TfrmDisplayAlarm.Init_ErrMessage;
var
  i, j : Integer;
begin
  //차후변경이 잦을 경우 외부 파일에서 읽어 들이는 방안 연구
  //Error 메세지에 대한 것은 PC Interface_190828.xlsx 파일을 참조하여 작성.
  //D1320 ~ 1324: Equipment Heavy Error
  //D1326: Equipment Light warning

  for i := 0 to 7 do begin
    for j := 0 to 7 do begin
      m_saErrMessage[i,j] := '';
    end;
  end;

  //Addres D1320
  m_saErrMessage[0,1]:= 'FRONT EMS ERROR (DI01)';
  m_saErrMessage[0,2]:= 'SIDE EMS ERROR (DI02)';
  m_saErrMessage[0,3]:= 'RIGHT INNER EMS ERROR (DI03)';
  m_saErrMessage[0,4]:= 'LEFT INNER EMS ERROR (DI04)';
  m_saErrMessage[0,5]:= 'REAR EMS ERROR (DI05)';
  m_saErrMessage[0,6]:= 'FAN #1 IN ERROR (DI06)';
  m_saErrMessage[0,7]:= 'FAN #2 IN ERROR (DI07)';

  m_saErrMessage[1,0]:= 'FAN #3 OUT ERROR (DI08)';
  m_saErrMessage[1,1]:= 'FAN #4 OUT ERROR (DI09)';
  m_saErrMessage[1,2]:= 'FAN #5 IN ERROR (DI10)';
  m_saErrMessage[1,3]:= 'FAN #6 IN ERROR (DI11)';
  m_saErrMessage[1,4]:= 'FAN #7 OUT ERROR (DI12)';
  m_saErrMessage[1,5]:= 'FAN #8 OUT ERROR (DI13)';
  m_saErrMessage[1,6]:= 'MAIN AIR Pressure ERROR(DI14)';


  m_saErrMessage[2,0]:= 'TEMPERATURE ALARM (DI16)';
  m_saErrMessage[2,1]:= 'POWER HIGH ALARM (DI17)';
  m_saErrMessage[2,2]:= 'LIGHT CURTAIN (DI18)';
  m_saErrMessage[2,5]:= 'UPPER LEFT DOOR (DI21)';
  m_saErrMessage[2,6]:= 'UPPER RIGHT DOOR (DI22)';
  m_saErrMessage[2,7]:= 'LOWER LEFT DOOR (DI23)';

  m_saErrMessage[3,0]:= 'LOWER RIGHT DOOR (DI24)';
  m_saErrMessage[3,1]:= 'Need to press Reset button (DI25)';
  m_saErrMessage[3,5]:= 'SHUTTER UP SENSOR NG (DI29)';
  m_saErrMessage[3,6]:= 'SHUTTER DOWN SENSOR NG (DI30)';


  m_saErrMessage[4,0] := '1 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[4,1] := '1 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[4,2] := '1 CH POGO Down Sensor NG';
  m_saErrMessage[4,3] := '1 CH CARRIER DETECT Sensor NG';
  m_saErrMessage[4,4] := '2 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[4,5] := '2 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[4,6] := '2 CH POGO Down Sensor NG';
  m_saErrMessage[4,7] := '2 CH CARRIER DETECT Sensor NG';

  m_saErrMessage[5,0] := '3 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[5,1] := '3 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[5,2] := '3 CH POGO Down Sensor NG';
  m_saErrMessage[5,3] := '3 CH CARRIER DETECT Sensor NG';
  m_saErrMessage[5,4] := '4 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[5,5] := '4 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[5,6] := '4 CH POGO Down Sensor NG';
  m_saErrMessage[5,7] := '4 CH CARRIER DETECT Sensor NG';

  m_saErrMessage[6,0] := '5 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[6,1] := '5 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[6,2] := '5 CH POGO Down Sensor NG';
  m_saErrMessage[6,3] := '5 CH CARRIER DETECT Sensor NG';
  m_saErrMessage[6,4] := '6 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[6,5] := '6 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[6,6] := '6 CH POGO Down Sensor NG';
  m_saErrMessage[6,7] := '6 CH CARRIER DETECT Sensor NG';

  m_saErrMessage[7,0] := '7 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[7,1] := '7 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[7,2] := '7 CH POGO Down Sensor NG';
  m_saErrMessage[7,3] := '7 CH CARRIER DETECT Sensor NG';
  m_saErrMessage[7,4] := '8 CH CLAMP Up Sensor-1 NG';
  m_saErrMessage[7,5] := '8 CH CLAMP Up Sensor-2 NG';
  m_saErrMessage[7,6] := '8 CH POGO Down Sensor NG';
  m_saErrMessage[7,7] := '8 CH CARRIER DETECT Sensor NG';

end;
end.
