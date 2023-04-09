unit InternalScriptClass;

interface

uses
  Winapi.Windows, System.SysUtils, System.Generics.Collections,  CommonClass, DefCommon, System.Math;

type
  //==============================================================================
  TDeltaERecord = record
    Lx		: Single;		// = input x
    Ly		: Single;		// = input y
    LvY		: Single;		// = input Y
    X			: Single;		// outpuy =x/y*Y
    Y			: Single;		// output =Y
    Z			: Single;		// output =(1-x-y)/y*Y
    L			: Single;		// output =IF(Y/Yw>0.008856, 116*((Y/Yw)^0.33333333)-16, 903.3*Y/Yw)
    XdivXw: Single;		// output =IF(X/Xw>0.008856,(X/Xw)^0.33333333,7.787*(X/Xw)+16/116)
    YdivYw: Single;		// output =IF(Y/Yw>0.008856,(Y/Yw)^0.33333333,7.787*(Y/Yw)+16/116)
    ZdivZw: Single;		// output =IF(Z/Zw>0.008856,(X/Zw)^0.33333333,7.787*(Z/Zw)+16/116)
    a     : Single;		// output =500*(XdivXw-YdivYw)
    b     : Single;		// output =500*(ZdivYw-YdivZw)
    DeltaE: Single;		// output 1)DeltaEw=MAX(DeltaE(22)~DeltaE(255)) 2)DeltaEGray=(a^2+b^2)^(1/2)
  end;

  TRgbAvr = record
    R : TList<Integer>;
    G : TList<Integer>;
    B : TList<Integer>;
  end;

  TOcGammaCmd = class
  private
    FB: Integer;
    FG: Integer;
    FR: Integer;
      procedure SetB(const Value: Integer);
      procedure SetG(const Value: Integer);
      procedure SetR(const Value: Integer);
    public
      constructor Create;
      destructor Destroy; override;
      property R : Integer read FR write SetR;
      property G : Integer read FG write SetG;
      property B : Integer read FB write SetB;
  end;

  TOcGammaVal = class
  private
    FLv: Single;
    FX: Single;
    FY: Single;
    procedure SetLv(const Value: Single);
    procedure SetX(const Value: Single);
    procedure SetY(const Value: Single);

  public
    constructor Create;
    destructor Destroy; override;
    property X : Single read FX write SetX;
    property Y : Single read FY write SetY;
    property Lv : Single read FLv write SetLv;
  end;
  TOcParamsWR = class
    private
      FRec  : TOcParams;
//      GammaCmd : array of TGammaCmd;
      GammaCmd : array of TGammaCmd;
      NewGammaVal : array of TGammaVal;
      FGrayStep: Integer;

      procedure SetGrayStep(const Value: Integer);

    public
      FCurJig : Integer;
      FCurCh  : Integer;
      constructor Create;
      destructor Destroy; override;
      function OcGamma(nBand, nGray : Integer) : TGammaCmd;
      function OcSpec(nBand, nGray : Integer) : TOcParam;    // because of oc param...
      function GetItemName(nBand,nGray : Integer) : string;
      function OcTarget(nBand, nGray : Integer) : TGammaVal;
      function OcNewTarget(nBand, nGray : Integer) : TGammaVal;
      function OcLimit(nBand, nGray : Integer) : TGammaVal;
      function OcRatio(nBand, nGray : Integer) : TGammaVal;
      procedure ResetGammaData;
      procedure SetFindGamma(nBand,nGray : Integer; FindGamma : TOcGammaCmd);
      // Added by Clint_Park 2019-08-03 오후 3:57:04 New Target. for F2 model.
      procedure SetNewTarget(nBand,nGray : Integer; NewTarget : TOcGammaVal);
      property GrayStep: Integer read FGrayStep write SetGrayStep;
  end;

  TOcVerify = class
    private
      FRec  : TOcParams;
    public
      constructor Create;
      destructor Destroy; override;
      function OcSpec(sSpecName : string) : TOcParam;
      function OcTarget(sSpecName : string) : TGammaVal;
      function OcLimit(sSpecName : string) : TGammaVal;
  end;

  TUserArray = class
  private
    FocGamma : array of TOcGammaVal;
    function  GetItem(Index: Integer): TOcGammaVal;
    procedure SetItem(Index: Integer; const Value: TOcGammaVal);
  public
    constructor Create(nLen : Integer);
    destructor destroy; override;
    property  Items[Index: Integer]: TOcGammaVal read GetItem write SetItem; default;
  end;

  TOtpTableArray = class
    private
      FOtpData : TOtpRead;
      function  GetItem(Index: Integer): TOtpReadData;
      procedure SetItem(Index: Integer; const Value: TOtpReadData);
    public
      constructor Create;
      destructor destroy; override;
      function  GetItemCount : Integer;
      property  Items[idxItem: Integer]: TOtpReadData read GetItem write SetItem; default;
  end;

  TOcDeltaE = class
    private
      FOcDelta : array of TDeltaERecord;
      FGrayCount : Integer;
      FDeltaMaxCnt : Integer;
      procedure CalDeltaERecordWhite (Lx,Ly,LvY : Single; var deltaE: TDeltaERecord);
      procedure CalDeltaERecordGray (Lx,Ly,LvY, Yw, Xw, Zw: Single; var deltaE: TDeltaERecord);
    public
      constructor Create(GrayCount, nDeltaMaxCnt : Integer);
      destructor destroy; override;
      procedure SetMeasureVal(nIdx : Integer; x, y, Lv : Single);
      function GetCalData(nIdx : Integer): TDeltaERecord;
      function GetDeltaData(nIdx : Integer) : Single;
      function GetMaxDelta : Single;
  end;

  TInsApdr = class
  private
    ApdrVal         : array of array of string;
    function GetData(nRow,nCol : Integer) : string;
    procedure SetData(nRow, nCol : Integer; const Value : string);
  public
    FRowCnt        : Integer;
    FColCnt        : Integer;
    constructor Create(nRowCnt, DataLen : Integer);
    destructor Destroy; override;
    property Data[nRow, nCol : Integer] : string read GetData write SetData;
  end;

  TInsCsv = class
  private
    CsvVal         : array of array of string;
    function GetData(nRow,nCol : Integer) : string;
    procedure SetData(nRow, nCol : Integer; const Value : string);
  public
    FRowCnt        : Integer;
    FColCnt        : Integer;
    constructor Create(nRowCnt, DataLen : Integer);
    destructor Destroy; override;
    property Data[nRow, nCol : Integer] : string read GetData write SetData;
  end;
  TInsRgbPass = class
  private
    PassRgbVal         : array of array of string;
    function GetData(nBand, nGray : Integer) : string;
    procedure SetData(nBand, nGray : Integer; const Value : string);
  public
    FBandCnt, FGrayStep        : Integer;
    // nColCnt = Band Count X Gray Level Count.
    constructor Create(nBand, nGrayStep : Integer);
    destructor Destroy; override;
    property Data[nBand, nGray : Integer] : string read GetData write SetData;
  end;

  TMath = class

  public
    constructor Create;
    destructor Destroy; override;
    function Sqrt(x : Extended) : Extended;
    function Sqr(x : Extended) : Extended;
    function Pow(x,y : Extended) : Extended;
    function Abs(x : Extended) : Extended;
    function Trunc(x : Extended) : Integer;
    function OpNot(x : Integer) : Integer;
    function ColorAngle(mU,mV,tU,tV : Double) : Extended;
    function ColorAngle2(mU,mV,tU,tV : Double) : Extended;
    function ColorDelta(mU,mV,tU,tV : Double) : Extended;
  end;
implementation

{ TOcParamsWR }

constructor TOcParamsWR.Create;
var
  i : Integer;
begin
  SetLength(GammaCmd,Common.m_OcParam.IdxOcPCnt);
  SetLength(NewGammaVal,Common.m_OcParam.IdxOcPCnt);
  for i := 0 to Pred(Common.m_OcParam.IdxOcPCnt) do begin
    GammaCmd[i] := Common.m_OcParam.OcParam[i].Gamma;
    //NewGammaVal[i] := Common.m_OcParam.OcParam[i].Target;
  end;
  FCurJig := 0;
  FCurCh  := 0;
  FRec := Common.m_OcParam;

  FRec.IdxOcPCnt := Common.m_OcParam.IdxOcPCnt;
  FRec.IdxOcVCnt := Common.m_OcParam.IdxOcVCnt;


//  SetLength(FRec.OcParam,FRec.IdxOcPCnt);
//  SetLength(FRec.OcVerify,FRec.IdxOcVCnt);
//  CopyMemory(@FRec.OcParam[0],@Common.m_OcParam.OcParam[0],FRec.IdxOcPCnt);
//  CopyMemory(@FRec.OcVerify[0],@Common.m_OcParam.OcVerify[0],FRec.IdxOcVCnt);
end;

destructor TOcParamsWR.Destroy;
var
  i : Integer;
begin
  SetLength(GammaCmd,0);
  SetLength(NewGammaVal,0);
  inherited;
end;

function TOcParamsWR.GetItemName(nBand, nGray: Integer): string;
begin
  Result := Common.m_OcParam.OcParam[(nBand-1) * FGrayStep + nGray ].ItemName;
end;

function TOcParamsWR.OcGamma(nBand, nGray: Integer): TGammaCmd;
//var
//  ocRet : TOcGammaCmd;
begin
//  ocRet.FR := GammaCmd[(nBand-1) * FGrayStep + nGray ].R;
//  ocRet.FG := GammaCmd[(nBand-1) * FGrayStep + nGray ].G;
//  ocRet.FB := GammaCmd[(nBand-1) * FGrayStep + nGray ].B;
  Result := GammaCmd[(nBand-1) * FGrayStep + nGray ];
end;


function TOcParamsWR.OcLimit(nBand, nGray: Integer): TGammaVal;
begin
  Result := Common.m_OcParam.OcParam[(nBand-1) * FGrayStep + nGray ].Limit;
end;

function TOcParamsWR.OcNewTarget(nBand, nGray: Integer): TGammaVal;
begin
  Result := NewGammaVal[(nBand-1) * FGrayStep + nGray ];
end;

function TOcParamsWR.OcRatio(nBand, nGray: Integer): TGammaVal;
begin
  Result := Common.m_OcParam.OcParam[(nBand-1) * FGrayStep + nGray ].Ratio;
end;

function TOcParamsWR.OcSpec(nBand, nGray: Integer): TOcParam;
begin
  Result := Common.m_OcParam.OcParam[(nBand-1) * FGrayStep + nGray ];
end;

function TOcParamsWR.OcTarget(nBand, nGray: Integer): TGammaVal;
begin
  Result := Common.m_OcParam.OcParam[(nBand-1) * FGrayStep + nGray ].Target;
end;

procedure TOcParamsWR.ResetGammaData;
var
  i, j, nTemp, nSum, nAvr : Integer;
  AvrGamma : TGammaCmd;
begin
  if Common.m_RgbAvr[FCurJig].IsReady then begin
    for i := 0 to Pred(Common.m_RgbAvr[FCurJig].IdxOcPCnt) do begin
      GammaCmd[i] := Common.m_RgbAvr[FCurJig].Gamma[i];
    end;
  end
  else begin
    for i := 0 to Pred(Common.m_OcParam.IdxOcPCnt) do begin
      GammaCmd[i] := Common.m_OcParam.OcParam[i].Gamma;
    end;
  end;

  FRec := Common.m_OcParam;

  FRec.IdxOcPCnt := Common.m_OcParam.IdxOcPCnt;
  FRec.IdxOcVCnt := Common.m_OcParam.IdxOcVCnt;
end;

procedure TOcParamsWR.SetFindGamma(nBand, nGray: Integer; FindGamma: TOcGammaCmd);
begin
  GammaCmd[(nBand-1) * FGrayStep + nGray ].R := FindGamma.FR;
  GammaCmd[(nBand-1) * FGrayStep + nGray ].G := FindGamma.FG;
  GammaCmd[(nBand-1) * FGrayStep + nGray ].B := FindGamma.FB;
end;

procedure TOcParamsWR.SetGrayStep(const Value: Integer);
begin
  FGrayStep := Value;
end;


procedure TOcParamsWR.SetNewTarget(nBand, nGray: Integer; NewTarget: TOcGammaVal);
begin
  NewGammaVal[(nBand-1) * FGrayStep + nGray].x := NewTarget.x;
  NewGammaVal[(nBand-1) * FGrayStep + nGray].y := NewTarget.y;
  NewGammaVal[(nBand-1) * FGrayStep + nGray].Lv := NewTarget.Lv;
end;

{ TOcGammaVal }

constructor TOcGammaVal.Create;
begin

end;

destructor TOcGammaVal.Destroy;
begin

  inherited;
end;

procedure TOcGammaVal.SetLv(const Value: Single);
begin
  FLv := Value;
end;

procedure TOcGammaVal.SetX(const Value: Single);
begin
  FX := Value;
end;

procedure TOcGammaVal.SetY(const Value: Single);
begin
  FY := Value;
end;

{ TOcGammaCmd }

constructor TOcGammaCmd.Create;
begin

end;

destructor TOcGammaCmd.Destroy;
begin

  inherited;
end;

procedure TOcGammaCmd.SetB(const Value: Integer);
begin
  FB := Value;
end;

procedure TOcGammaCmd.SetG(const Value: Integer);
begin
  FG := Value;
end;

procedure TOcGammaCmd.SetR(const Value: Integer);
begin
  FR := Value;
end;

{ TOcVerify }

constructor TOcVerify.Create;
begin
  FRec := Common.m_OcParam;
end;

destructor TOcVerify.Destroy;
var
  i: Integer;
begin
  for i := 0 to Pred(FRec.IdxOcPCnt) do begin
    FRec.OcParam[i].ItemName  := '';
  end;
  SetLength(FRec.OcParam,0);
  SetLength(FRec.OcVerify,0);
  inherited;
end;

function TOcVerify.OcLimit(sSpecName: string): TGammaVal;
var
  i, nIdx: Integer;
begin
  for i := 0 to Pred(Frec.IdxOcVCnt) do begin
    if Uppercase(Trim(FRec.OcVerify[i].ItemName)) = Uppercase(Trim(sSpecName)) then begin
      nIdx := i;
      Break;
    end;
  end;
  Result := FRec.OcVerify[nIdx].Limit;
end;

function TOcVerify.OcSpec(sSpecName : string): TOcParam;
var
  i, nIdx: Integer;
begin
  for i := 0 to Pred(Frec.IdxOcVCnt) do begin
    if Uppercase(Trim(FRec.OcVerify[i].ItemName)) = Uppercase(Trim(sSpecName)) then begin
      nIdx := i;
      Break;
    end;
  end;
  Result := FRec.OcVerify[nIdx];
end;



function TOcVerify.OcTarget(sSpecName: string): TGammaVal;
var
  i, nIdx: Integer;
begin
  for i := 0 to Pred(Frec.IdxOcVCnt) do begin
    if Uppercase(Trim(FRec.OcVerify[i].ItemName)) = Uppercase(Trim(sSpecName)) then begin
      nIdx := i;
      Break;
    end;
  end;
  Result := FRec.OcVerify[nIdx].Target;
end;

{ TUserArray }

constructor TUserArray.Create(nLen: Integer);
begin
  SetLength(FocGamma,nLen);
end;

destructor TUserArray.destroy;
begin

  inherited;
end;

function TUserArray.GetItem(Index: Integer): TOcGammaVal;
begin
  Result := FocGamma[Index];
end;

procedure TUserArray.SetItem(Index: Integer; const Value: TOcGammaVal);
begin
  FocGamma[Index] := Value;
end;

{ TOtpTableArray }

constructor TOtpTableArray.Create;
begin
  FOtpData := common.m_OtpRead;
end;

destructor TOtpTableArray.destroy;
begin
  inherited;
end;

function TOtpTableArray.GetItem(Index: Integer): TOtpReadData;
begin
  Result := FOtpData.Data[Index];
end;

function TOtpTableArray.GetItemCount: Integer;
begin

  Result := FOtpData.CommandCnt;
end;

procedure TOtpTableArray.SetItem(Index: Integer; const Value: TOtpReadData);
begin
  FOtpData.Data[Index] := value
end;


{ TOcDeltaE }

procedure TOcDeltaE.CalDeltaERecordGray(Lx, Ly, LvY, Yw, Xw, Zw : Single; var deltaE: TDeltaERecord);
begin
  //----------------
  deltaE.Lx  := Lx;
  deltaE.Ly  := Ly;
  deltaE.LvY := LvY;
  //----------------
  deltaE.X := Lx/Ly*LvY;
  //----------------
  deltaE.Y := LvY;
  //----------------
  deltaE.Z := (1-Lx-Ly)/Ly*DeltaE.Y;
  //----------------
  if (DeltaE.Y/Yw > 0.008856) then
    deltaE.L := (116*Power((DeltaE.Y/Yw),0.33333333))-16
  else
    deltaE.L := 903.3*DeltaE.Y/Yw;
  //----------------
  if (DeltaE.X/Xw > 0.008856) then
    deltaE.XdivXw := Power((deltaE.X/Xw),0.33333333)
  else
    deltaE.XdivXw := 7.787*(DeltaE.X/Xw)+16/116;
  //----------------
  if (DeltaE.Y/Yw > 0.008856) then
    deltaE.YdivYw := Power((DeltaE.Y/Yw),0.33333333)
  else
    deltaE.YdivYw := 7.787*(DeltaE.Y/Yw)+16/116;
  //----------------
  if (DeltaE.Z/Zw > 0.008856) then
    deltaE.ZdivZw := Power((deltaE.Z/Zw),0.33333333)		//TBD: Power(a,b)???
  else
    deltaE.ZdivZw := 7.787*(deltaE.Z/Zw)+16/116;
  //----------------
  deltaE.a := 500*(deltaE.XdivXw-deltaE.YdivYw) ;
  //----------------
  deltaE.b := 200*(deltaE.YdivYw-deltaE.ZdivZw) ;
  //----------------
  deltaE.DeltaE := Power((Power(deltaE.a,2)+Power(deltaE.b,2)),(1/2));	//TBD: Power(a,b)???
end;

procedure TOcDeltaE.CalDeltaERecordWhite(Lx, Ly, LvY: Single; var deltaE: TDeltaERecord);
var
  Xw,Yw,Zw: Single;
begin
  //----------------
  deltaE.Lx := Lx;
  deltaE.Ly := Ly;
  deltaE.LvY := LvY;
  //----------------
  deltaE.X := Lx/Ly*LvY;
  //----------------
  deltaE.Y := LvY;
  //----------------
  deltaE.Z := (1-Lx-Ly)/Ly*LvY;
  //----------------
  Yw := deltaE.Y; // for White
  if (deltaE.Y/Yw > 0.008856) then
    deltaE.L := 116*(Power((deltaE.Y/Yw),0.33333333))-16
  else
    deltaE.L := 903.3*deltaE.Y/Yw;
  //----------------
  Xw := deltaE.X; // for White
  if (deltaE.X/Xw > 0.008856) then
    deltaE.XdivXw := Power((deltaE.X/Xw),0.33333333)
  else
    deltaE.XdivXw := 7.787*(deltaE.X/Xw)+16/116;
  //----------------
  if (deltaE.Y/Yw > 0.008856) then
    deltaE.YdivYw := Power((deltaE.Y/Yw),0.33333333)
  else
    deltaE.YdivYw := 7.787*(deltaE.Y/Yw)+16/116;
  //----------------
  Zw := deltaE.Z; // for White
  if (deltaE.Z/Zw > 0.008856) then
    deltaE.ZdivZw := Power((deltaE.Z/Zw),0.33333333)		//TBD: Power(a,b)???
  else
    deltaE.ZdivZw := 7.787*(deltaE.Z/Zw)+16/116;
  //----------------
  deltaE.a := 500*(deltaE.XdivXw-deltaE.YdivYw);
  //----------------
  deltaE.b := 200*(deltaE.YdivYw-deltaE.ZdivZw);
end;

constructor TOcDeltaE.Create(GrayCount, nDeltaMaxCnt: Integer);
begin
  SetLength(FOcDelta,GrayCount+10); // 여유롭게 버퍼좀 주자.
  FGrayCount := GrayCount;
  FDeltaMaxCnt := nDeltaMaxCnt;
end;

destructor TOcDeltaE.destroy;
begin
  SetLength(FOcDelta,0);
  inherited;
end;

function TOcDeltaE.GetCalData(nIdx : Integer): TDeltaERecord;
begin
  Result := FOcDelta[nIdx];
end;

function TOcDeltaE.GetDeltaData(nIdx : Integer): Single;
begin
  Result := FOcDelta[nIdx].DeltaE;
end;

function TOcDeltaE.GetMaxDelta: Single;
var
  dMaxVal : Single;
  i : Integer;
begin
  dMaxVal := 0;
  for i := 0 to Pred(FDeltaMaxCnt) do begin
    if FOcDelta[i].DeltaE > dMaxVal then begin
      dMaxVal := FOcDelta[i].DeltaE;
    end;
  end;
  Result := dMaxVal;
end;

procedure TOcDeltaE.SetMeasureVal(nIdx : Integer; x, y, Lv: Single);
begin
  // White.
  if nIdx = 0 then begin
    CalDeltaERecordWhite(x,y,Lv,FOcDelta[nIdx]);
  end
  // Other gray.
  else begin
    CalDeltaERecordGray(x,y,Lv,FOcDelta[0].Y,FOcDelta[0].X,FOcDelta[0].Z,FOcDelta[nIdx]);
  end;

end;

{ TInsCsv }

constructor TInsCsv.Create(nRowCnt, DataLen: Integer);
var
  i: Integer;
begin
  SetLength(CsvVal,nRowCnt);
  for i := 0 to Pred(nRowCnt) do begin
    SetLength(CsvVal[i],DataLen);
  end;
  FRowCnt := nRowCnt;
  FColCnt := DataLen;
end;

destructor TInsCsv.Destroy;
var
  i : integer;
begin
  for i := 0 to Pred(FRowCnt) do begin
    SetLength(CsvVal[i],0);
  end;
  SetLength(CsvVal,0);
  inherited;
end;

function TInsCsv.GetData(nRow, nCol: Integer): string;
begin
  Result := CsvVal[nRow, nCol];
end;



procedure TInsCsv.SetData(nRow, nCol: Integer; const Value: string);
begin
  CsvVal[nRow, nCol] := Value ;
end;


{ TInsRgbPass }

constructor TInsRgbPass.Create(nBand, nGrayStep: Integer);
var
  i: Integer;
begin
  SetLength(PassRgbVal,nBand);
  for i := 0 to Pred(nBand) do begin
    SetLength(PassRgbVal[i],nGrayStep);
  end;
  FBandCnt := nBand;
  FGrayStep := nGrayStep;
end;

destructor TInsRgbPass.Destroy;
begin

  inherited;
end;

function TInsRgbPass.GetData(nBand, nGray: Integer): string;
begin
  Result := PassRgbVal[nBand, nGray];
end;

procedure TInsRgbPass.SetData(nBand, nGray: Integer; const Value: string);
begin
  PassRgbVal[nBand-1, nGray] := Value ;
end;

{ TInsApdr }

constructor TInsApdr.Create(nRowCnt, DataLen: Integer);
var
  i: Integer;
begin
  SetLength(ApdrVal,nRowCnt);
  for i := 0 to Pred(nRowCnt) do begin
    SetLength(ApdrVal[i],DataLen);
  end;
  FRowCnt := nRowCnt;
  FColCnt := DataLen;
end;

destructor TInsApdr.Destroy;
var
  i : integer;
begin
  for i := 0 to Pred(FRowCnt) do begin
    SetLength(ApdrVal[i],0);
  end;
  SetLength(ApdrVal,0);
  inherited;
end;

function TInsApdr.GetData(nRow, nCol: Integer): string;
begin
  Result := ApdrVal[nRow, nCol];
end;

procedure TInsApdr.SetData(nRow, nCol: Integer; const Value: string);
begin
  ApdrVal[nRow, nCol] := Value ;
end;

{ TMath }

function TMath.Abs(x: Extended): Extended;
begin
  Result := System.Abs(x);
end;

function TMath.ColorAngle(mU, mV, tU, tV : Double): Extended;
var
  deltaA, deltaB, slope, dRio : Double;
begin
  deltaA := mU - tU;
  deltaB := mV - tV;
  slope  :=  deltaB / deltaA;
  dRio   := System.Math.DegToRad(1);
  Result := ArcTan(slope) / dRio;
end;




function TMath.ColorAngle2(mU, mV, tU, tV: Double): Extended;
var
  deltaA, deltaB, slope, dRet : Double;
begin
  deltaA := mU - tU;
  deltaB := mV - tV;
//  slope  :=  deltaB / deltaA;
//  dRio   := System.Math.DegToRad(1);
  dRet := System.math.ArcTan2(deltaB,deltaA) * 180 / PI;
  if dRet < 0 then begin

    dRet := dRet + 360;
  end;
  Result := dRet;
end;

//System.math.ArcTan2(dB,dA) * 180 / PI;

function TMath.ColorDelta(mU, mV, tU, tV : Double): Extended;
var
  deltaA, deltaB : Double;
begin
  deltaA := mU - tU;
  deltaB := mV - tV;
  Result := Sqrt(Sqr(deltaA) + Sqr(deltaB));
end;

constructor TMath.Create;
begin

end;

destructor TMath.Destroy;
begin

  inherited;
end;

// script가 Not 연산자를 지원 못하네....
function TMath.OpNot(x: Integer): Integer;
begin
  Result := not x;
end;

function TMath.Pow(x, y: Extended): Extended;
begin
  Result := System.Math.Power(x,y);
end;

function TMath.Sqr(x: Extended): Extended;
begin
  Result := System.Sqr(x);
end;

function TMath.Sqrt(x: Extended): Extended;
begin
  Result := System.Sqrt(x);
end;

function TMath.Trunc(x: Extended): Integer;
begin
  Result := System.Trunc(x);
end;

end.
