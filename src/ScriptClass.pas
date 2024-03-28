unit ScriptClass;

interface

uses
  System.Classes, System.SysUtils, Vcl.Dialogs, DefScript, DefCommon, CommonClass, IdWinsock2;


type

  // NVM Read Items.
  TNvmSkipData = record
    skip : Boolean;
    Data : byte;
  end;

	TNvmCmdData  = record
		NvmCmd      : Byte;
		NvmLen      : Byte;
		Param       : array of TNvmSkipData;
	end;

  TNvmCmdExData = record
    NvmLen      : Byte;
    CParam      : array of Byte;
  end;

// Full Code를 비교하기 위하여 입력 받은 데이터를 구조체 안에 넣도록 한다.
	TNvmReadData  = record
		TotalCmdLen     : Integer;
    CmdEx           : Integer;
    CmdExLen        : Integer;
		NvmCmdData      : array of TNvmCmdData;
    NvmCmdExData    : array [0..10] of TNvmCmdExData;
	end;

  // CG ID matching.
  TModelCgid = record
    ModelName : string;
    Code      : Integer;
  end;
  TTouchCgId = record
    AllCgIdCnt : Integer;
    ModelCgId  : array[1.. Defcommon.MAX_MODEL_CGID_CNT] of TModelCgid
  end;

  // Flash Read Items.
  TFlashRead = record
    Address : Integer;
    Length  : Word;
    CompareLength : Word;
    ComparePos    : Word;
    Result  : Boolean;
    RevData : array of byte;
  end;

  TLimitStr = record
    LimitType   : Integer;
    FramePos    : Integer;
    DataPos     : Integer; // -1 이면 All.
    bRange      : Boolean;
    StPos       : Integer;
    EdPos       : Integer;
    Limit     : string[50];
  end;
  TSeq = record
    SeqId       : string[10];
    TestName    : string[100];
    ProtoclIdx  : Integer;
    Freq        : Integer;
    Frame       : Integer;
    DataType    : Integer;
    RetyCnt     : Integer;
    RefIdx      : Integer;
    LimitCnt    : Integer;
    Limit       : array of TLimitStr;
  end;
  TSeqList  = record
    SeqCount    : Integer;
    SeqReadNg   : boolean;
    Seq         : array of TSeq;
  end;

  TModelInfo = packed record

		SigType  		 : Byte;   // 0:3-3-2 1:4-4-4 2:5-6-5 3:6-6-6 4:8-8-8
		Freq         : Longword;
		H_Active     : Word;
		H_BP         : Word;
		H_Width      : Word;
		H_FP         : Word;

		V_Active     : Word;
		V_BP         : Word;
		V_Width      : Word;
		V_FP         : Word;

		H_Polarity   : Byte;
		V_Polarity   : Byte;

		DE_Polarity  : Byte;
		Dot_edge	   : Byte;

		Pwm_freq     : Word;
		Pwm_duty     : Byte;

		VLCD         : Word;
		VCC          : Word;
		VEXT         : Word;
		VEL          : Word;
		VBAT         : Word;
		VNEG         : Word;

		ILCD_High    : Word;
		ILCD_Low     : Word;
		ICC_High     : Word;
		ICC_Low      : Word;
		IEXT_High    : Word;
		IEXT_Low     : Word;
		IEL_High     : Word;
		IEL_Low      : Word;
		IBAT_High    : Word;
		IBAT_Low     : Word;
		INEG_High    : Word;
		INEG_Low     : Word;

		GPIO         : Byte;
		I2C          : Byte;
		SPI          : Byte;
		SPI_Bit      : Byte;
		SPI_Clock    : Byte;
		I2C_Devadd   : Byte;
		I2C_bit      : Byte;
		Touch_Model  : Byte;

		RES1          : Byte;
		RES2          : Byte;
		RES3          : Byte;
		RES4          : Longword;

		ILCD_Set			: Byte;
		ICC_Set				: Byte;
		IEXT_Set			: Byte;
		IEL_Set				: Byte;
		IBAT_Set			: Byte;
		INEG_Set			: Byte;
	end;



  TScript = class(TObject)

  private
    procedure SaveAnalyzedToolInfo_Script(nIdx: Integer; slst: TStringList; sModelName : string);
  public
    m_slLoadData  : TStringList;
    m_slFlow	    : TStringlist;
    m_slPowerON   : Tstringlist;
    m_slNvm       : TStringList;
    m_slModelMatch  : TStringList;
    m_slFlash     : TStringList;
    m_SeqScript   : TSeqList;
    m_nBarcodeFlow : Integer;

    m_sScriptVer    : string;
    m_sScriptVerDate : string;
    m_sPatGroup    : string;
    Nvm            : TNvmReadData;
    TouchCgid      : TTouchCgId;
    FlashRead      : TFlashRead;

    ModelInfo       : TModelInfo;
    constructor Create(sScriptFile : string); virtual;
    destructor Destroy; override;
    function LoadScript(sFileName : string) : Boolean;
    procedure AnalizeScriptForCode(fname: string; lstScript : TStringList);

  end;
var
  Script : TScript;

implementation

{ TScript }


procedure TScript.AnalizeScriptForCode(fname: string; lstScript: TStringList);
var
  i, j 		 : Integer;
  slCodes 		 : TStringList;

  CodeStart, CodeEnd 	 : array [DefScript.CODE_TXICINIT..DefScript.CODE_MAX] of Integer;
  bCodeStart, bCodeEnd : array [DefScript.CODE_TXICINIT..DefScript.CODE_MAX] of Boolean;
begin
  // Definition Init.
  for i := DefScript.CODE_TXICINIT to DefScript.CODE_MAX do begin
    CodeStart[i] := 0;
    CodeEnd[i] := 0;
    bCodeStart[i] := False;
    bCodeEnd[i] := False;
  end;

  for i := 0 to Pred(lstScript.Count) do begin
//    slTemp := TStringList.create;
//    try
      // look for TxIc Init.
      if      Pos(DefScript.func_call_TxIcInit,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_TXICINIT]  := i+2;
        bCodeStart[DefScript.CODE_TXICINIT] := True;
      end
      else if bCodeStart[DefScript.CODE_TXICINIT] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_TXICINIT]    := i-1;
        bCodeStart[DefScript.CODE_TXICINIT] := False;
      end

      // look for Mipi Module On.
      else if Pos(DefScript.func_call_Module_on,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_MODULE_ON]  := i+2;
        bCodeStart[DefScript.CODE_MODULE_ON] := True;
      end
      else if bCodeStart[DefScript.CODE_MODULE_ON] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_MODULE_ON]    := i-1;
        bCodeStart[DefScript.CODE_MODULE_ON] := False;
      end
      // look for Mipi Module Off.
      else if Pos(DefScript.func_call_Module_off,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_MODULE_OFF]  := i+2;
        bCodeStart[DefScript.CODE_MODULE_OFF] := True;
      end
      else if bCodeStart[DefScript.CODE_MODULE_OFF] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_MODULE_OFF]    := i-1;
        bCodeStart[DefScript.CODE_MODULE_OFF] := False;
      end
      // look for Power On.
      else if Pos(DefScript.func_call_Power_On,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_POWER_ON]  := i+2;
        bCodeStart[DefScript.CODE_POWER_ON] := True;
      end
      else if bCodeStart[DefScript.CODE_POWER_ON] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_POWER_ON]    := i-1;
        bCodeStart[DefScript.CODE_POWER_ON] := False;
      end
      // look for Power Off.
      else if Pos(DefScript.func_call_Power_Off,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_POWER_OFF]  := i+2;
        bCodeStart[DefScript.CODE_POWER_OFF] := True;
      end
      else if bCodeStart[DefScript.CODE_POWER_OFF] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_POWER_OFF]    := i-1;
        bCodeStart[DefScript.CODE_POWER_OFF] := False;
      end
      // look for Power on by Auto code
      else if Pos(DefScript.func_call_Power_On_Auto,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_POWER_ON_AUTO]  := i+2;
        bCodeStart[DefScript.CODE_POWER_ON_AUTO] := True;
      end
      else if bCodeStart[DefScript.CODE_POWER_ON_AUTO] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_POWER_ON_AUTO]    := i-1;
        bCodeStart[DefScript.CODE_POWER_ON_AUTO] := False;
      end

      // look for Power on by Auto code
      else if Pos(DefScript.func_call_Otp_Write,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_OTP_WRITE]  := i+2;
        bCodeStart[DefScript.CODE_OTP_WRITE] := True;
      end
      else if bCodeStart[DefScript.CODE_OTP_WRITE] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_OTP_WRITE]    := i-1;
        bCodeStart[DefScript.CODE_OTP_WRITE] := False;
      end

      // look for Power on by Auto code
      else if Pos(DefScript.func_call_Otp_Read,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_OTP_READ]  := i+2;
        bCodeStart[DefScript.CODE_OTP_READ] := True;
      end
      else if bCodeStart[DefScript.CODE_OTP_READ] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_OTP_READ]    := i-1;
        bCodeStart[DefScript.CODE_OTP_READ] := False;
      end

      // look for Power on by Auto code
      else if Pos(DefScript.func_call_ScreenCode,lstScript.Strings[i]) <> 0 then begin
        CodeStart[DefScript.CODE_SCR_CODE]  := i+2;
        bCodeStart[DefScript.CODE_SCR_CODE] := True;
      end
      else if bCodeStart[DefScript.CODE_SCR_CODE] and (Pos(end_func, lstScript.Strings[i]) <> 0 )then begin
        CodeEnd[DefScript.CODE_SCR_CODE]    := i-1;
        bCodeStart[DefScript.CODE_SCR_CODE] := False;
      end;
//    finally
//      slTemp.Free;
//    end;
  end;

  slCodes := TStringList.create;
  try

    for j := DefScript.CODE_TXICINIT to DefScript.CODE_MAX do begin
      for i := CodeStart[j] to CodeEnd[j] do begin
        slCodes.Add(lstScript.Strings[i]);
      end;
      SaveAnalyzedToolInfo_Script(j, slCodes, fname);
      slCodes.clear;
    end;
  finally
    slCodes.Free;
  end;
end;

constructor TScript.Create(sScriptFile : string);
begin
  m_nBarcodeFlow := 0;
  m_sScriptVer := '';
  m_sScriptVerDate := '';
  m_sPatGroup := '';
  if FileExists(sScriptFile) then begin
    LoadScript(sScriptFile);
  end;
end;

destructor TScript.Destroy;
begin

  if m_slNvm <> nil then begin
    m_slNvm.Free;
    m_slNvm := nil;
  end;

  if m_slModelMatch <> nil then begin
    m_slModelMatch.Free;
    m_slModelMatch := nil;
  end;

  if m_slFlash <> nil then begin
    m_slFlash.Free;
    m_slFlash := nil;
  end;

  if m_slPowerON <> nil then begin
    m_slPowerON.Free;
    m_slPowerON := nil;
  end;

  if m_slFlow <> nil then begin
    m_slFlow.Free;
    m_slFlow := nil;
  end;

  if m_slLoadData <> nil then begin
    m_slLoadData.Free;
    m_slLoadData := nil;
  end;

  inherited;
end;

// Return : True - Load OK , False - Fail.
function TScript.LoadScript(sFileName: string): Boolean;

begin

  if not fileExists(sFileName) then begin
    ShowMessage(Format('Cannot Find %s Script Files',[sFileName]));
    exit(False);
  end;

  if m_slLoadData <> nil then begin
    m_slLoadData.Free;
    m_slLoadData := nil;
  end;
  m_slLoadData := TStringList.Create;
  m_slLoadData.LoadFromFile(sFileName);
//  AnalizeScript(m_slLoadData);
  Result := True;
end;


procedure TScript.SaveAnalyzedToolInfo_Script(nIdx: Integer; slst: TStringList; sModelName: string);
var
  sFileName, sSaveFile : string;
begin
  Common.Path.MODEL_CUR := Common.Path.MODEL + sModelName + '\';
  common.Path.ModelCode := Common.Path.MODEL_CUR + 'compiled\';
  Common.CheckDir(common.Path.ModelCode);

  sSaveFile := Common.Path.ModelCode + sModelName;
  case nIdx of
    DefScript.CODE_TXICINIT      : sFileName := sSaveFile +'.mpt';
    DefScript.CODE_MODULE_ON     : sFileName := sSaveFile +'.mion';
    DefScript.CODE_MODULE_OFF    : sFileName := sSaveFile +'.mioff';
    DefScript.CODE_POWER_ON      : sFileName := sSaveFile +'.pwon';
    DefScript.CODE_POWER_OFF     : sFileName := sSaveFile +'.pwoff';
    DefScript.CODE_POWER_ON_AUTO : sFileName := sSaveFile +'.miau';
    DefScript.CODE_OTP_WRITE     : sFileName := sSaveFile +'.otpw';
    DefScript.CODE_OTP_READ      : sFileName := sSaveFile +'.otpr';
    DefScript.CODE_SCR_CODE      : sFileName := sSaveFile +'.misc';
    else begin

      sFileName := '';
    end;
  end;
  if sFileName <> '' then slst.SaveToFile(sFileName);
end;

end.
