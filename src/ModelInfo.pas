unit ModelInfo;

interface
{$I Common.inc}

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvMemo, AdvmPS, AdvCodeList,  ExPat,
  Vcl.StdCtrls, Vcl.ComCtrls,  Vcl.Imaging.pngimage, DefPG, AdvMemoActions,
  Vcl.ExtCtrls, Vcl.Mask, System.Generics.Collections, System.UITypes, ZAxisConfig, System.IOUtils, OutlookGroupedList, RzShellDialogs,
  atScriptDebug, ScrMemo, ScrMps, atScript, atPascal, DongaPattern, Vcl.Grids, RzGrids, AdvPanel, AdvOutlookList, Vcl.Buttons, RzSpnEdt, RzSplit, RzLabel,
  RzEdit, RzCmboBx, RzRadChk, RzPanel, RzButton, RzLstBox, AdvOfficePager,
  IdWinsock2, CommonClass, DefCommon, DefScript, ScriptClass, {UdpServerClient,}CommPG, RzPrgres,
   AdvObj, BaseGrid, AdvGrid, Winapi.ShlObj,System.Types,
  {ModelDownload,}  pasScriptClass;

const
  MAX_DELAY_CNT = 7;
  MAX_WAVE      = 5;
  MAX_TG_CNT    = 6;

  MAX_DELAY_TIME= 10000;  //10Sec
  STEP1_VALUE   = 50;
  STEP2_VALUE   = 500;
  STEP1_STEP    = 1;
  STEP2_STEP    = 10;
  STEP3_STEP    = 100;

  MIN_CYCLE_TIME   = 50;
  MAX_CYCLE_TIME   = 600;
  TOP_MARGIN_VALUE = 20;
  BOM_MARGIN_VALUE = 10;

  RISING         = 0;
  FALLING        = 1;
  ALL_H          = 2;
  ALL_L          = 3;
  DATA           = 4;

  RST            = 0;
  WR             = 1;
  RD             = 2;
  WAIT           = 3;
  PIO            = 4;
  PIXEL          = 5;
  ED             = 6;
  MAX_CMD_NO     = ED;
type
         {
// Define Class.
  DefScr  = class(TatScripterLibrary) //class public
    const
    // Protocol을 위한 기본 SID
    SIG_CONNECTION_ACK      = $0001;
    SIG_CONNECT_REQUEST     = $0004;
    SIG_OPMODEL_PWR_SEQ     = $0010;
    SIG_START_PG            = $0020;
    SIG_STOP_PG             = $0022;
    SIG_SEQ_START           = $0024;
    SIG_SEQ_STOP            = $0026;
    SIG_SEQ_END_REPORT      = $0030;
    SIG_SEQ_PWR_RETRY       = $0032;
    SIG_SEQ_FINAL_RTY       = $0034;
    SIG_PWR_MODE_REPORT     = $0036;
    SIG_SET_COLOR_PALLET    = $0040;
  end;  }

  TfrmModelInfo = class(TForm)
    pnlPanel_Header: TRzPanel;
    AdvPascalMemoStyler1: TAdvPascalMemoStyler;
    tmrDisplayOffMessage: TTimer;
    Page_Registration: TAdvOfficePager;
    pgProgramInfo: TAdvOfficePage;
    pgPatGrp: TAdvOfficePage;
    RzGroupBox18: TRzGroupBox;
    cboPatGrpFuse: TRzComboBox;
    Ca: TRzPanel;
    grpPGrpSelection: TRzGroupBox;
    grpPGrpName: TRzGroupBox;
    edPGrpName: TRzEdit;
    grpPGrpList: TRzGroupBox;
    lstPGrplist: TRzListBox;
    grpResiPCnt: TRzGroupBox;
    pnlPCnt: TRzPanel;
    edPCnt: TRzEdit;
    btnPGrpNew: TRzBitBtn;
    btnPGrpReName: TRzBitBtn;
    btnPGrpCopy: TRzBitBtn;
    btnPGrpDel: TRzBitBtn;
    grpPInfo: TRzGroupBox;
    grpResiPList: TRzGroupBox;
    HdrTimes: THeader;
    gridPatternList: TRzStringGrid;
    grpPName: TRzGroupBox;
    cboPName: TRzComboBox;
    grpVSync: TRzGroupBox;
    edVSync: TRzEdit;
    pnlHz: TRzPanel;
    chkVSync: TRzCheckBox;
    btnPInfoAdd: TRzBitBtn;
    btnPInfoModify: TRzBitBtn;
    btnPInfoUp: TRzBitBtn;
    btnPInfoDown: TRzBitBtn;
    btnPInfoDel: TRzBitBtn;
    grpPType: TRzGroupBox;
    cboPType: TRzComboBox;
    grpTime: TRzGroupBox;
    pnlSec: TRzPanel;
    edTime: TRzEdit;
    chkTime: TRzCheckBox;
    cboResolution: TRzComboBox;
    grpPPreview: TRzGroupBox;
    RzPanel17: TRzPanel;
    imgPPreview: TDongaPat;
    btnSPC: TRzBitBtn;
    btnSavePatGrp: TRzBitBtn;
    RzBitBtn8: TRzBitBtn;
    cboPatGrpList: TRzComboBox;
    RzPanel35: TRzPanel;
    pnlModelNameInfo: TPanel;
    pgSeqInfo: TAdvOfficePage;
    RzSplitter2: TRzSplitter;
    RzPanel1: TRzPanel;
    btn1: TRzBitBtn;
    btn2: TRzBitBtn;
    btnCompileScript: TRzBitBtn;
    btn4: TRzBitBtn;
    RzPanel52: TRzPanel;
    btnOpenPro: TRzRapidFireButton;
    btnSavePro: TRzRapidFireButton;
    btn5: TRzBitBtn;
    cboCompileList: TRzComboBox;
    mmProgramAll: TAdvMemo;
    RzPanel2: TRzPanel;
    btn6: TRzBitBtn;
    btn7: TRzBitBtn;
    RzPanel55: TRzPanel;
    lstComplie: TRzListBox;
    lstGrpCompile: TAdvOutlookList;
    btn8: TRzBitBtn;
    atPascalScripter1: TatPascalScripter;
    ScrPascalMemoStyler1: TScrPascalMemoStyler;
    atScriptDebugger1: TatScriptDebugger;
    AdvPanel1: TAdvPanel;
    btnCompilePsu: TRzBitBtn;
    btnCompileChecking: TRzBitBtn;
    btnDebug: TRzBitBtn;
    btn9: TRzBitBtn;
    cboScriptSeqId: TRzComboBox;
    mmo1: TMemo;
    ScrMemo1: TScrMemo;
    dlgOpenOcParam: TRzOpenDialog;
    AdvMemoFindDialog1: TAdvMemoFindDialog;
    AdvMemoFindDialog2: TAdvMemoFindDialog;
    AdvPascalMemoStyler2: TAdvPascalMemoStyler;
    ScrPascalMemoStyler2: TScrPascalMemoStyler;
    pgModelSetPG: TAdvOfficePage;
    rzgrpModelSetPGModelSel: TRzGroupBox;
    RagrpModelSetPgModelName: TRzGroupBox;
    edModelSetPgModelName: TRzEdit;
    btnSaveModelSetPG: TRzBitBtn;
    btnCloseModelSetPG: TRzBitBtn;
    RzgrpPgModelConfig: TRzGroupBox;
    RzgrpModelTiming: TRzGroupBox;
    RzpnlModelConfig_link_rate_Range: TRzPanel;
    RzpnlALPDP_Vsync: TRzPanel;
    RzpnlModelConfig_link_rate: TRzPanel;
    RzpnlModelConfig_lane: TRzPanel;
    cboModelConfig_lane: TRzComboBox;
    RzpnlModelConfig_ALPM_mode: TRzPanel;
    cboModelConfig_ALPM_mode: TRzComboBox;
    RzpnlModelConfig_RGBFormat: TRzPanel;
    edModelConfig_RGBFormat: TRzEdit;
    RzpnlModelConfig_Vsync_Range: TRzPanel;
    RzpnlModelConfig_vfb_offset: TRzPanel;
    edModelConfig_vfb_offset: TRzNumericEdit;
    edModelConfig_link_rate: TRzNumericEdit;
    edModelConfig_Vsync: TRzNumericEdit;
    RzgrpPanelRes: TRzGroupBox;
    RapnlPanelRes: TRzPanel;
    RapnlPanelResActiveArea: TRzPanel;
    RapnlPanelResBP: TRzPanel;
    RapnlPanelResSA: TRzPanel;
    RapnlPanelResFP: TRzPanel;
    RapnlPanelResH: TRzPanel;
    RapnlPanelResV: TRzPanel;
    edPanelResH_Active: TRzNumericEdit;
    edPanelResH_BP: TRzNumericEdit;
    edPanelResH_FP: TRzNumericEdit;
    edPanelResH_SA: TRzNumericEdit;
    edPanelResV_Active: TRzNumericEdit;
    edPanelResV_BP: TRzNumericEdit;
    edPanelResV_FP: TRzNumericEdit;
    edPanelResV_SA: TRzNumericEdit;
    RzgrpALPDP: TRzGroupBox;
    RzpnlALPDP_Tps: TRzPanel;
    RzpnlALPDP_H_FDP: TRzPanel;
    RzpnlALPDP_H_SDP: TRzPanel;
    RzpnlALPDP_VB_SLEEP: TRzPanel;
    RzpnlALPDP_VB_N5B: TRzPanel;
    RzpnlALPDP_VB_N7: TRzPanel;
    RzpnlALPDP_VB_N5A: TRzPanel;
    RzpnlALPDP_VB_N4: TRzPanel;
    RzpnlALPDP_VB_N3: TRzPanel;
    RzpnlALPDP_VB_N2: TRzPanel;
    RzpnlALPDP_xdelay: TRzPanel;
    RzpnlALPDP_h_mg: TRzPanel;
    RzpnlALPDP_n_vid: TRzPanel;
    RzpnlALPDP_m_vid: TRzPanel;
    RzpnlALPDP_V_blank: TRzPanel;
    RzpnlALPDP_NoAux_Sel: TRzPanel;
    RzpnlALPDP_NoAux_Sleep: TRzPanel;
    RzpnlALPDP_misc_0: TRzPanel;
    RzpnlALPDP_misc_1: TRzPanel;
    RzpnlALPDP_Chop_Interval: TRzPanel;
    RzpnlALPDP_Chop_Enable: TRzPanel;
    RzpnlALPDP_Chop_Size: TRzPanel;
    RzpnlALPDP_H_PCNT: TRzPanel;
    cboALPDP_Chop_Enable: TRzComboBox;
    cboALPDP_xpol: TRzComboBox;
    RzpnlALPDP_xpol: TRzPanel;
    edALPDP_H_FDP: TRzNumericEdit;
    edALPDP_H_SDP: TRzNumericEdit;
    edALPDP_H_PCNT: TRzNumericEdit;
    edALPDP_VB_N2: TRzNumericEdit;
    edALPDP_VB_N3: TRzNumericEdit;
    edALPDP_VB_N4: TRzNumericEdit;
    edALPDP_VB_N5A: TRzNumericEdit;
    edALPDP_VB_N5B: TRzNumericEdit;
    edALPDP_m_vid: TRzNumericEdit;
    edALPDP_misc_0: TRzNumericEdit;
    edALPDP_misc_1: TRzNumericEdit;
    edALPDP_n_vid: TRzNumericEdit;
    edALPDP_NoAux_Sel: TRzNumericEdit;
    edALPDP_NoAux_Sleep: TRzNumericEdit;
    edALPDP_h_mg: TRzNumericEdit;
    edALPDP_VB_N7: TRzNumericEdit;
    edALPDP_VB_SLEEP: TRzNumericEdit;
    edALPDP_xdelay: TRzNumericEdit;
    edALPDP_Chop_Size: TRzNumericEdit;
    edALPDP_Chop_Interval: TRzNumericEdit;
    edALPDP_NoAux_Active: TRzNumericEdit;
    RzpnlALPDP_NoAux_Active: TRzPanel;
    edALPDP_Critical_Section: TRzNumericEdit;
    RzpnlALPDP_CriticalSection: TRzPanel;
    RzgrpPowerSeq: TRzGroupBox;
    RzlblPowerSeqOffSeq1: TRzLabel;
    RzlblPowerSeqOffSeq2: TRzLabel;
    RzlblPowerSeqOffSeq3: TRzLabel;
    RzlblPowerSeqOnSeq1: TRzLabel;
    RzlblPowerSeqOnSeq2: TRzLabel;
    RzlblPowerSeqOnSeq3: TRzLabel;
    cboPowerSeqType: TRzComboBox;
    RzpnlPowerSeqOff: TRzPanel;
    RzpnlPowerSeqOn: TRzPanel;
    edPowerSeqOnSeq2: TRzNumericEdit;
    edPowerSeqOnSeq1: TRzNumericEdit;
    edPowerSeqOffSeq3: TRzNumericEdit;
    edPowerSeqOffSeq2: TRzNumericEdit;
    edPowerSeqOnSeq3: TRzNumericEdit;
    edPowerSeqOffSeq1: TRzNumericEdit;
    RzgrpPwrLimit: TRzGroupBox;
    RzpnlPwrLimitVolVDD1Range: TRzPanel;
    RzpnlPwrLimitVol: TRzPanel;
    RzpnlPwrLimitVolVDD1: TRzPanel;
    RzpnlPwrLimitVolL: TRzPanel;
    edPwrLimit_VDD1_L: TRzNumericEdit;
    RzpnlPwrLimitVolVDD2: TRzPanel;
    edPwrLimit_VDD2_L: TRzNumericEdit;
    RzpnlPwrLimitVolVDD2Range: TRzPanel;
    RzpnlPwrLimitVolH: TRzPanel;
    edPwrLimit_VDD1_H: TRzNumericEdit;
    edPwrLimit_VDD2_H: TRzNumericEdit;
    RzpnlPwrLimitCurVDD4Range: TRzPanel;
    RzpnlPwrLimitCur: TRzPanel;
    RzpnlPwrLimitCurVDD1: TRzPanel;
    RzpnlPwrLimitCurL: TRzPanel;
    edPwrLimit_IVDD1_L: TRzNumericEdit;
    RzpnlPwrLimitCurVDD2: TRzPanel;
    edPwrLimit_IVDD2_L: TRzNumericEdit;
    RzpnlPwrLimitCurH: TRzPanel;
    edPwrLimit_IVDD1_H: TRzNumericEdit;
    edPwrLimit_IVDD2_H: TRzNumericEdit;
    RzpnlPwrLimitVolVDD3: TRzPanel;
    edPwrLimit_VDD3_L: TRzNumericEdit;
    edPwrLimit_VDD3_H: TRzNumericEdit;
    RzpnlPwrLimitVolVDD3Range: TRzPanel;
    RzpnlPwrLimitVolVDD4: TRzPanel;
    edPwrLimit_VDD4_L: TRzNumericEdit;
    edPwrLimit_VDD4_H: TRzNumericEdit;
    RzpnlPwrLimitVolVDD4Range: TRzPanel;
    RzpnlPwrLimitVolVDD5: TRzPanel;
    edPwrLimit_VDD5_L: TRzNumericEdit;
    edPwrLimit_VDD5_H: TRzNumericEdit;
    RzpnlPwrLimitVolVDD5Range: TRzPanel;
    RzpnlPwrLimitCurVDD4: TRzPanel;
    edPwrLimit_IVDD4_L: TRzNumericEdit;
    edPwrLimit_IVDD4_H: TRzNumericEdit;
    RzpnlPwrLimitCurVDD5Range: TRzPanel;
    RzpnlPwrLimitCurVDD3Range: TRzPanel;
    edPwrLimit_IVDD3_H: TRzNumericEdit;
    edPwrLimit_IVDD3_L: TRzNumericEdit;
    RzpnlPwrLimitCurVDD3: TRzPanel;
    RzpnlPwrLimitCurVDD2Range: TRzPanel;
    RzpnlPwrLimitCurVDD1Range: TRzPanel;
    edPwrLimit_IVDD5_H: TRzNumericEdit;
    edPwrLimit_IVDD5_L: TRzNumericEdit;
    RzpnlPwrLimitCurVDD5: TRzPanel;
    RzgrpVolSet: TRzGroupBox;
    RzpnlVolSetVCCRange: TRzPanel;
    RzpnlPanelVolSet: TRzPanel;
    RzpnlVolSetVDD1: TRzPanel;
    RzpnlPanelVolValue: TRzPanel;
    edVolSet_VDD1: TRzNumericEdit;
    RzpnlVolSetVDD2: TRzPanel;
    edVolSet_VDD2: TRzNumericEdit;
    RzpnlVolSetVINRange: TRzPanel;
    RzpnlVolSetVDD3: TRzPanel;
    edVolSet_VDD3: TRzNumericEdit;
    RzpnlVolSetVDD3Range: TRzPanel;
    RzpnlVolSetVDD5: TRzPanel;
    edVolSet_VDD5: TRzNumericEdit;
    RzpnlVolSetVDD5Range: TRzPanel;
    RzpnlVolSetVDD4: TRzPanel;
    edVolSet_VDD4: TRzNumericEdit;
    RzpnlVolSetVDD4Range: TRzPanel;
    RzpnlVolSetSlopeSet: TRzPanel;
    edVolSet_SlopeSet: TRzNumericEdit;
    RzpnlVolSetSlopeRange: TRzPanel;
    pgModelInfo: TAdvOfficePage;
    RzGroupBox3: TRzGroupBox;
    grp2: TRzGroupBox;
    edModelName: TRzEdit;
    grp3: TRzGroupBox;
    lstModelList: TRzListBox;
    btnModelNewScript: TRzBitBtn;
    btnModelCopyScript: TRzBitBtn;
    btnModelRenameScript: TRzBitBtn;
    btnModelDelScript: TRzBitBtn;
    btnSaveModelInfo: TRzBitBtn;
    RzBitBtn6: TRzBitBtn;
    RzGroupBox4: TRzGroupBox;
    RzPanel3: TRzPanel;
    edSerialNoLength: TRzEdit;
    cbFlowOptIonizerOnOff: TRzCheckBox;
    RzGroupBox5: TRzGroupBox;
    RzComboBox2: TRzComboBox;
    RzPanel4: TRzPanel;
    RzGroupBox12: TRzGroupBox;
    RzPanel22: TRzPanel;
    edPgVerAF9MCS: TRzEdit;
    edPgVerAF9API: TRzEdit;
    RzPanel23: TRzPanel;
    edPgVerAll: TRzEdit;
    RzPanel24: TRzPanel;
    pnlErrorDisplay: TPanel;
    RzpnlALPDP_tps_Range: TRzPanel;
    RzpnlALPDP_v_blank_Range: TRzPanel;
    edALPDP_tps: TRzNumericEdit;
    edALPDP_v_blank: TRzNumericEdit;
    RzGrpLimitSetting: TRzGroupBox;
    RzPnlLimitSettingValues: TRzPanel;
    RzPnlLimitSettingLow: TRzPanel;
    RzPnlLimitSettingHigh: TRzPanel;
    edLimitSettingIdd_Low: TRzEdit;
    edLimitSettingIdd_High: TRzEdit;
    RzPnlLimitSettingIdd: TRzPanel;
    RzPnlLimitSettingIcc: TRzPanel;
    RzPnlLimitSettingVdd: TRzPanel;
    RzPnlLimitSettingVcc: TRzPanel;
    edLimitSettingVcc_Low: TRzNumericEdit;
    edLimitSettingVdd_High: TRzNumericEdit;
    edLimitSettingVdd_Low: TRzNumericEdit;
    edLimitSettingVcc_High: TRzNumericEdit;
    edLimitSettingIcc_High: TRzEdit;
    edLimitSettingIcc_Low: TRzEdit;
    RzGrpInputVoltage: TRzGroupBox;
    RzPnlInputVoltageVcc: TRzPanel;
    RzPnlInputVoltageVdd: TRzPanel;
    RzPnlInputVoltagePower: TRzPanel;
    RzpnlInputVotageValues: TRzPanel;
    edInputVoltageVcc: TRzNumericEdit;
    edInputVoltageVdd: TRzNumericEdit;
    RzPnlInputVoltageVBR: TRzPanel;
    edInputVoltageVBR: TRzNumericEdit;
    RzgrpVoltageOffset: TRzGroupBox;
    RzpnlVoltageOffsetVcc: TRzPanel;
    RzpnlVoltageOffsetVdd: TRzPanel;
    RzpnlVoltageOffsetTitle: TRzPanel;
    RzpnlVoltageOffsetValues: TRzPanel;
    edVoltageOffsetVcc: TRzNumericEdit;
    edVoltageOffsetVdd: TRzNumericEdit;
    cbFlowOptUseDutDetect: TRzCheckBox;
    RzPanel5: TRzPanel;
    edSerialNoAddr: TRzEdit;
    RzGroupBox1: TRzGroupBox;
    RzPanel6: TRzPanel;
    cboModelType: TRzComboBox;
    cboCa310Channel: TRzComboBox;
    RzPanel7: TRzPanel;
    procedure mmProgramAllDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure btnCompileScriptClick(Sender: TObject);
    procedure ReverseColorErrorLine(nIdxTab, nLine: Integer; bErrflag: Boolean);
    procedure lstModelListClick(Sender: TObject);
    procedure btnSaveModelInfoClick(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnModelDelScriptClick(Sender: TObject);
    procedure btn6Click(Sender: TObject);
    procedure btn7Click(Sender: TObject);
    procedure btnManualFusing_ScriptClick(Sender: TObject);
    procedure tmrDisplayOffMessageTimer(Sender: TObject);
    procedure WMCopyData(var Msg : TMessage); message WM_COPYDATA;
    procedure btnModelNewScriptClick(Sender: TObject);
    procedure btnModelCopyScriptClick(Sender: TObject);
    procedure btnModelRenameScriptClick(Sender: TObject);
    procedure btnPInfoAddClick(Sender: TObject);
    procedure btnPInfoModifyClick(Sender: TObject);
    procedure btnPInfoUpClick(Sender: TObject);
    procedure btnPInfoDownClick(Sender: TObject);
    procedure btnPInfoDelClick(Sender: TObject);
    procedure gridPatternListClick(Sender: TObject);
    procedure cboPTypeChange(Sender: TObject);
    procedure btnSPCClick(Sender: TObject);
    procedure lstPGrplistClick(Sender: TObject);
//    procedure imgPowerSeqMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//    procedure imgPowerSeqMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
//    procedure imgPowerSeqMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure edVoltageDelayChange(Sender: TObject);
    procedure edModelNameKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edCheckVddChange(Sender : TObject);
    procedure btnPGrpNewClick(Sender: TObject);
    procedure btnPGrpCopyClick(Sender: TObject);
    procedure btnPGrpReNameClick(Sender: TObject);
    procedure btnPGrpDelClick(Sender: TObject);
    procedure btnSavePatGrpClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnCompilePsuClick(Sender: TObject);
    procedure btnDebugClick(Sender: TObject);
    procedure btnCompileCheckingClick(Sender: TObject);
    procedure mmProgramAllKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseModelSetPGClick(Sender: TObject);
    procedure RzBitBtn6Click(Sender: TObject);

  private
    g_bNewModel  : Boolean;
    g_bCopyModel : Boolean;
    g_bRenModel  : Boolean;

    g_bNewPatGr: Boolean;
    g_bRenPatGr: Boolean;
    g_bCopyPatGr : Boolean;

    EditPatGrp    : TPatterGroup;

    pnlDownLoadStatus     : array[DefCommon.CH1 .. DefCommon.MAX_CH] of TRzPanel;
    pgbDownload           : array[DefCommon.CH1 .. DefCommon.MAX_CH] of TRzProgressBar;
    // for Power Seq.
//    m_nSstartX, m_nSstartY, m_nSstepX1, m_nSstepX2, m_nSoffsetY, m_nSstepY, m_nSendX, m_nSendY : Integer;
//    m_nMpoint   : Integer;
    m_bDelay_use          : array[0..MAX_DELAY_CNT-1] of Boolean;
//    m_bSelected : Boolean;
    m_nDelay_value        : array[0..MAX_DELAY_CNT-1] of Integer;
//    m_nDelay_position     : array[0..MAX_DELAY_CNT-1] of Integer;
//    m_nDelay_old_position : array[0..MAX_DELAY_CNT-1] of Integer;

    procedure CheckAndCopyModelData(oldName, newName : String);
    procedure CheckAndDeleteModelData(fName : String);
    procedure RemoveDirAll(sDir : string);
    function CheckSyntex(lstResource : TStringList; nOriNumbers : array of Integer) : Integer;
    procedure PatInfoBtnControl;
    procedure Display_PatGroup_data(DisplayPatGrp : TPatterGroup);

    procedure DisplayModelInfo(sModelName: string);
    function CheckInputVal : Boolean;
    function SaveModelInfoBuf : Boolean;
    procedure SaveModelInfoBuf2;
//    procedure DrawPowerSequence(bType : Boolean = True);
//    function CheckMouseOnLine(X, Y: Integer): Boolean;
//    procedure DrawSeq(Bitmap : TBitmap; nIdx : Integer; bType : Boolean);
//    procedure DrawLine(BitmapCanvas: TCanvas; const x, xsize, y, ysize: Integer);
//    procedure DisplayVddDelayValue(nIdx: Integer; bModel: Boolean);
//    procedure GetDelayPosition(nIdx: Integer);
//    procedure GetDelayValue(nIdx: Integer);
  public
    procedure Load_data_model;
    procedure Load_data_pat(PatName : string);
    procedure Display_Script_data(sModelname : string);
    procedure AddAndFindItemToListbox(tList: TRzListbox; sItem: string; bAdd, bFind: Boolean);
    procedure AddAndFindItemToCombobox(tCombo: TRzCombobox; sItem: string; bAdd, bFind: Boolean);
  end;

var
  frmModelInfo: TfrmModelInfo;
implementation

{$R *.dfm}

//uses ModelDownload;

{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$WARN IMPLICIT_STRING_CAST OFF}

procedure TfrmModelInfo.AddAndFindItemToCombobox(tCombo: TRzCombobox; sItem: string; bAdd, bFind: Boolean);
var
  i : Integer;
begin
  if bAdd then begin
    tCombo.Sorted := False;
    tCombo.Items.Add(sItem);
    tCombo.Sorted := True;
  end;

  if bFind then begin
    for i := 0 to tCombo.Items.Count - 1 do begin
      if tCombo.Items.Strings[i] = sItem then begin
        tCombo.ItemIndex := i;
        Break;
      end;
    end;
  end;
end;

procedure TfrmModelInfo.AddAndFindItemToListbox(tList: TRzListbox; sItem: string; bAdd, bFind: Boolean);
var
  i : Integer;
begin
  if bAdd then begin
    tList.Sorted := False;
    tList.Items.Add(sItem);
    tList.Sorted := True;
  end;

  if bFind then begin
    if sItem = '' then begin
      tList.ItemIndex := 0;
    end
    else begin
      for i := 0 to tList.Items.Count - 1 do begin
        if tList.Items.Strings[i] = sItem then begin
          tList.ItemIndex := i;
          Break;
        end;
      end;
    end;
  end;
end;



procedure TfrmModelInfo.btnDebugClick(Sender: TObject);
begin
  PasScr[0].DebugCheck;
end;

procedure TfrmModelInfo.btn3Click(Sender: TObject);
begin
  if Common.m_bIsChanged then begin
    btnManualFusing_ScriptClick(Self);
    Common.Delay(50);
  end;
  Close;
end;

procedure TfrmModelInfo.btnCloseModelSetPGClick(Sender: TObject);
begin
  if Common.m_bIsChanged then begin
    btnManualFusing_ScriptClick(Self);
    Common.Delay(50);
  end;
  Close;
end;

procedure TfrmModelInfo.btnCompileCheckingClick(Sender: TObject);
begin
  try
//    PasScr[0].LoadSource(ScrMemo1.Lines);
//    PasScr[0].RunSeq(cboScriptSeqId.ItemIndex);
    atPascalScripter1.SourceCode := ScrMemo1.Lines;
    //PasScr[0].DefineMethodFunc(atPascalScripter1);
    atPascalScripter1.Compile;
//    ScrMemo1.Lines.SaveToFile(Common.Path.MODEL + trim(edModelName.Text) +'.pas');
    mmo1.Lines.Add('Compile is OK...');

  except
    on E : Exception do
        mmo1.Lines.Add(E.Message);
  end;
end;

procedure TfrmModelInfo.btnCompileScriptClick(Sender: TObject);
var
  i, nCmt, nOriCnt  : Integer;
  sData     : string;
  sltData : TStringList;
  anOriNum  : array of integer;
begin
  sltData := TStringList.Create; // for data list except commant.
  try
    SetLength(anOriNum,SizeOf(Integer) * mmProgramAll.Lines.Count);
    nOriCnt := 0;
    // sltData에 주석을 제외한 데이터 입력 하자.
    for i := 0 to Pred(mmProgramAll.Lines.Count) do begin
      nCmt := Pos('//',mmProgramAll.Lines[i]); // 주석의 시작 위치 찾기.
      mmProgramAll.BreakPoint[i] := False;
      if nCmt <> 0 then begin
        sData := Trim(Copy(mmProgramAll.Lines.Strings[i],1,nCmt-1));
      end
      else begin
        sData := Trim(mmProgramAll.Lines.Strings[i]);
      end;
      if sData = '' then Continue;
      sltData.Add(sData);
      anOriNum[nOriCnt] := i;
      Inc(nOriCnt);
    end;
    // 구문 체크.
    if CheckSyntex(sltData,anOriNum) = DefScript.ERR_ST_NONE then begin
      Script.AnalizeScriptForCode(Trim(edModelName.Text),sltData);
    end;
    mmProgramAll.Lines.SaveToFile(Common.Path.MODEL_CUR+trim(edModelName.Text)+'.isu');
    Common.m_bIsChanged := True;
  finally
    sltData.Free;
  end;
end;

procedure TfrmModelInfo.btnCompilePsuClick(Sender: TObject);
begin
  try
    PasScr[0].LoadSource(ScrMemo1.Lines);
//    PasScr[0].RunSeq(DefScript.SEQ_1);
    mmo1.Lines.Add('Compile is OK...');
    ScrMemo1.Lines.SaveToFile(Common.Path.MODEL_CUR + trim(edModelName.Text) +'.psu');
    Common.m_bIsChanged := True;
  except
    on E : Exception do
        mmo1.Lines.Add(E.Message);
  end;
end;

procedure TfrmModelInfo.btnManualFusing_ScriptClick(Sender: TObject);
var
  i   : Integer;
  bPwr : boolean;
  sInitCode, sPatGrp : string;
  sTemp               : string;
  SetPatGrp           : TPatterGroup;
begin
  bPwr := False;
  pnlErrordisplay.Top := 455;
  pnlErrorDisplay.Left := 331;

  if bPwr then begin
		pnlErrordisplay.caption := 'Please All Channel Power off!';
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;


  sPatGrp := Common.Path.PATTERNGROUP + Common.EdModelInfoFLOW.PatGrpName + '.grp';
	if not FileExists(sPatGrp) then begin
		pnlErrordisplay.caption := Format('Please Check Pattern Group File(%s)',[Common.EdModelInfoFLOW.PatGrpName]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.mpt';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(mpt)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.mion';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(mion)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.mioff';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(mioff)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.pwon';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(pwon)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.pwoff';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(pwoff)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.miau';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(miau)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.otpw';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(otpw)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.otpr';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(otpr)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  sInitCode := Common.Path.ModelCode + Common.SystemInfo.TestModel + '.misc';
	if not FileExists(sInitCode) then begin
		pnlErrordisplay.caption := Format('Please Check Model File(%s)(misc)',[Common.SystemInfo.TestModel]);
		pnlErrordisplay.Visible := True;
    tmrDisplayOffMessage.Interval := 3000;
    tmrDisplayOffMessage.Enabled := True;
		exit;
	end;

  SetPatGrp := Common.LoadPatGroup(Common.EdModelInfoFLOW.PatGrpName);
  // 해당 pattern File이 있는지 확인.
  for i := 0 to Pred(SetPatGrp.PatCount) do begin
    case SetPatGrp.PatType[i] of
      DefCommon.PTYPE_NORMAL : begin
        Continue;
//        sTemp := Common.Path.Pattern + Trim(string(SetPatGrp.PatName[i]));
      end;
      DefCommon.PTYPE_BITMAP : begin
        sTemp := Common.Path.BMP + Trim(string(SetPatGrp.PatName[i]));
      end;
    end;
    if not FileExists(sTemp) then begin
      pnlErrordisplay.caption := Format('Please Check Pattern File(%s)',[sTemp]);
      pnlErrordisplay.Visible := True;
      tmrDisplayOffMessage.Interval := 3000;
      tmrDisplayOffMessage.Enabled := True;
      exit;
    end;
  end;


//  frmModelDownload := TfrmModelDownload.Create(Self);
//  try
//    frmModelDownload.ShowModal;
//  finally
//    frmModelDownload.Free;
//    frmModelDownload := nil;
//  end;
end;

procedure TfrmModelInfo.btnModelCopyScriptClick(Sender: TObject);
begin
  edModelName.ReadOnly := False;
  edModelName.SelectAll;
  edModelName.SetFocus;
  g_bCopyModel := True;
end;
procedure TfrmModelInfo.btnModelDelScriptClick(Sender: TObject);
var
  idx : Integer;
begin
  if lstModelList.ItemIndex < 0 then Exit;

  if MessageDlg(#13#10 + 'Are you sure to DELETE this Model?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
//		LBox_Model.ItemIndex := lstModelList.ItemIndex;
    idx := lstModelList.ItemIndex;
    if idx > -1 then begin
      DeleteFile(Common.GetFilePath(lstModelList.Items.Strings[idx], DefCommon. MODEL_PATH));
      CheckAndDeleteModelData(lstModelList.Items.Strings[idx]);
      lstModelList.Items.Delete(idx);
      lstModelList.ItemIndex := idx - 1;
      if (lstModelList.ItemIndex = -1) and (lstModelList.Items.Count > 0) then
        lstModelList.ItemIndex := 0;
      lstModelListClick(nil);

    end;
  end;
end;

procedure TfrmModelInfo.btnModelNewScriptClick(Sender: TObject);
begin
  edModelName.ReadOnly := False;
  edModelName.Text := '';
  edModelName.SetFocus;
  g_bNewModel := True;
end;

procedure TfrmModelInfo.btnModelRenameScriptClick(Sender: TObject);
begin
  edModelName.ReadOnly := False;
  edModelName.SelectAll;
  edModelName.SetFocus;
  g_bRenModel := True;
end;

procedure TfrmModelInfo.btnPGrpCopyClick(Sender: TObject);
begin
  edPGrpName.ReadOnly := False;
  edPGrpName.SelectAll;
  edPGrpName.SetFocus;

  g_bCopyPatGr := True;
end;

procedure TfrmModelInfo.btnPGrpDelClick(Sender: TObject);
var
  idx : Integer;
begin
	if lstPGrplist.ItemIndex < 0 then Exit;

  if MessageDlg(#13#10 + 'Are you sure to DELETE this Pattern Group?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    idx := lstPGrplist.ItemIndex;
		if idx > -1 then begin
			DeleteFile(Common.GetFilePath(lstPGrplist.Items.Strings[idx], PATGR_PATH));
			lstPGrplist.Items.Delete(idx);
			lstPGrplist.ItemIndex := idx - 1;
			if (lstPGrplist.ItemIndex = -1) and (lstPGrplist.Items.Count > 0) then
        lstPGrplist.ItemIndex := 0;
      lstPGrplistClick(nil);

      if lstPGrplist.Items.Count < 1 then begin
        edPGrpName.Text := '';
        cboPType.Text := 'Pattern';
        cboPTypeChange(nil);
        ChkVSync.Checked := False;
        ChkTime.Checked := True;
        edVSync.Text := 'None';
        edTime.Text := 'None';
        gridPatternList.RowCount := 1;
        gridPatternList.Rows[0].Clear;
      end;
    end;
  end;
end;

procedure TfrmModelInfo.btnPGrpNewClick(Sender: TObject);
begin
  edPGrpName.ReadOnly := False;
  edPGrpName.SelectAll;
  edPGrpName.SetFocus;

  g_bNewPatGr := True;
end;

procedure TfrmModelInfo.btnPGrpReNameClick(Sender: TObject);
begin
  edPGrpName.ReadOnly := False;
  edPGrpName.SelectAll;
  edPGrpName.SetFocus;

  g_bRenPatGr := True;
end;

procedure TfrmModelInfo.btnPInfoAddClick(Sender: TObject);
var
  idx : Integer;
begin
  if cboPType.Text = '' then begin
    MessageDlg(#13#10 + 'Input Error! Pattern Type is Empty.', mtError, [mbOK], 0);
    cboPType.SetFocus;
    Exit;
  end;

  if cboPName.Text = '' then begin
    MessageDlg(#13#10 + 'Input Error! Pattern Name is Empty.', mtError, [mbOK], 0);
    cboPName.SetFocus;
    Exit;
  end;

  if chkVSync.Checked then begin
    if (StrToIntDef((edVSync.Text),0) < 20) or (StrToIntDef(edVSync.Text,200) > 180) then begin
      MessageDlg(#13#10 + 'Input Error! Vertical Frequency Range : [20 ~ 180 Hz].', mtError, [mbOK], 0);
      edVSync.SelectAll;
      edVSync.SetFocus;
      Exit;
    end;
  end;

  if chkTime.Checked then begin
    if (StrToIntDef(edTime.Text,-1) < 0) or (StrToIntDef(edTime.Text,100) > 60) then begin
      MessageDlg(#13#10 + 'Input Error! Pattern Display Time Range : [0 ~ 60 Sec].', mtError, [mbOK], 0);
      edTime.SelectAll;
      edTime.SetFocus;
      Exit;
    end;
  end;

  if gridPatternList.RowCount = 1 then begin
    if gridPatternList.Cells[0, 0] = '' then begin
      idx := 0;
    end
    else begin
      gridPatternList.RowCount := 2;
      idx := 1;
    end;
  end
  else begin
    gridPatternList.RowCount := gridPatternList.RowCount + 1;
    idx := gridPatternList.RowCount - 1;
  end;

  gridPatternList.Cells[0, idx] := cboPType.Text;
  gridPatternList.Cells[1, idx] := cboPName.Text;
  if chkVSync.Checked then  gridPatternList.Cells[2, idx] := edVSync.Text
  else                      gridPatternList.Cells[2, idx] := 'None';

  if chkTime.Checked then gridPatternList.Cells[3, idx] := edTime.Text
  else                    gridPatternList.Cells[3, idx] := '0';

  gridPatternList.Row := idx;
  edPCnt.Text := IntToStr(gridPatternList.RowCount);
  PatInfoBtnControl;
end;

procedure TfrmModelInfo.btnPInfoDelClick(Sender: TObject);
var
  idx, i : Integer;
begin
  idx := gridPatternList.Row;

  gridPatternList.Rows[idx].Clear;

  if idx < gridPatternList.RowCount - 1 then begin
    for i := gridPatternList.Row to gridPatternList.RowCount - 2 do begin
      gridPatternList.Cells[0, i] := gridPatternList.Cells[0, i + 1];
      gridPatternList.Cells[1, i] := gridPatternList.Cells[1, i + 1];
      gridPatternList.Cells[2, i] := gridPatternList.Cells[2, i + 1];
      gridPatternList.Cells[3, i] := gridPatternList.Cells[3, i + 1];
    end;
  end;

  gridPatternList.RowCount := gridPatternList.RowCount - 1;
  gridPatternListClick(nil);

  if gridPatternList.RowCount = 1 then begin
    if gridPatternList.Cells[0, 0] = '' then
      edPCnt.Text := '0'
    else
      edPCnt.Text := '1';
  end
  else
    edPCnt.Text := IntToStr(gridPatternList.RowCount);

  PatInfoBtnControl;
end;

procedure TfrmModelInfo.btnPInfoDownClick(Sender: TObject);
var
  idx : Integer;
  sTempType, sTempName, sTempVSync, sTempTime, sTempPn : String;
begin
  idx := gridPatternList.Row;

  if idx > gridPatternList.RowCount - 2 then Exit;

  sTempType   := gridPatternList.Cells[0, idx];
  sTempName   := gridPatternList.Cells[1, idx];
  sTempVSync  := gridPatternList.Cells[2, idx];
  sTempTime   := gridPatternList.Cells[3, idx];
  sTempPn     := gridPatternList.Cells[4, idx];

  gridPatternList.Cells[0, idx] := gridPatternList.Cells[0, idx + 1];
  gridPatternList.Cells[1, idx] := gridPatternList.Cells[1, idx + 1];
  gridPatternList.Cells[2, idx] := gridPatternList.Cells[2, idx + 1];
  gridPatternList.Cells[3, idx] := gridPatternList.Cells[3, idx + 1];
  gridPatternList.Cells[4, idx] := gridPatternList.Cells[4, idx + 1];

  gridPatternList.Cells[0, idx + 1] := sTempType;
  gridPatternList.Cells[1, idx + 1] := sTempName;
  gridPatternList.Cells[2, idx + 1] := sTempVSync;
  gridPatternList.Cells[3, idx + 1] := sTempTime;
  gridPatternList.Cells[4, idx + 1] := sTempPn;

  gridPatternList.Row := idx + 1;

  PatInfoBtnControl;
end;

procedure TfrmModelInfo.btnPInfoModifyClick(Sender: TObject);
var
  idx : Integer;
begin
  if cboPType.Text = '' then begin
    MessageDlg(#13#10 + 'Input Error! Pattern Type is Empty.', mtError, [mbOK], 0);
    cboPType.SetFocus;
    Exit;
  end;

  if cboPName.Text = '' then begin
    MessageDlg(#13#10 + 'Input Error! Pattern Name is Empty.', mtError, [mbOK], 0);
    cboPName.SetFocus;
    Exit;
  end;

  if chkVSync.Checked then begin
    if (StrToIntDef(edVSync.Text,0) < 20) or (StrToIntDef(edVSync.Text,200) > 180) then begin
      MessageDlg(#13#10 + 'Input Error! Vertical Frequency Range : [20 ~ 180 Hz].', mtError, [mbOK], 0);
      edVSync.SelectAll;
      edVSync.SetFocus;
      Exit;
    end;
  end;

  if chkTime.Checked then begin
    if (StrToIntDef(edTime.Text,-1) < 0) or (StrToIntDef(edTime.Text,100) > 60) then begin
      MessageDlg(#13#10 + 'Input Error! Pattern Display Time Range : [0 ~ 60 Sec].', mtError, [mbOK], 0);
      edTime.SelectAll;
      edTime.SetFocus;
      Exit;
    end;
  end;

  idx := gridPatternList.Row;
  gridPatternList.Cells[0, idx] := cboPType.Text;
  gridPatternList.Cells[1, idx] := cboPName.Text;
  if chkVSync.Checked then gridPatternList.Cells[2, idx] := edVSync.Text
  else                    gridPatternList.Cells[2, idx] := 'None';
  if chkTime.Checked then gridPatternList.Cells[3, idx] := edTime.Text
  else                    gridPatternList.Cells[3, idx] := '0';
end;

procedure TfrmModelInfo.btnPInfoUpClick(Sender: TObject);
var
  idx : Integer;
  sTempType, sTempName, sTempVSync, sTempTime : String;
begin
  idx := gridPatternList.Row;

  if idx < 1 then Exit;

  sTempType   := gridPatternList.Cells[0, idx];
  sTempName   := gridPatternList.Cells[1, idx];
  sTempVSync  := gridPatternList.Cells[2, idx];
  sTempTime   := gridPatternList.Cells[3, idx];

  gridPatternList.Cells[0, idx] := gridPatternList.Cells[0, idx - 1];
  gridPatternList.Cells[1, idx] := gridPatternList.Cells[1, idx - 1];
  gridPatternList.Cells[2, idx] := gridPatternList.Cells[2, idx - 1];
  gridPatternList.Cells[3, idx] := gridPatternList.Cells[3, idx - 1];

  gridPatternList.Cells[0, idx - 1] := sTempType;
  gridPatternList.Cells[1, idx - 1] := sTempName;
  gridPatternList.Cells[2, idx - 1] := sTempVSync;
  gridPatternList.Cells[3, idx - 1] := sTempTime;

  gridPatternList.Row := idx - 1;

  PatInfoBtnControl;
end;

procedure TfrmModelInfo.btnSaveModelInfoClick(Sender: TObject);
var
  i	: Integer;
  sOldName, sNewName : String;
begin

  if edModelName.Text = '' then begin
    MessageDlg(#13#10 + 'Input Error! Please Insert the Model name.', mtError, [mbOK], 0);
    edModelName.SetFocus;

    Exit;
  end;

  if (not g_bRenModel) and (not g_bCopyModel) then begin
    Common.Path.ModelCode := Common.Path.MODEL_CUR + 'compiled\';
    if not DirectoryExists(Common.Path.ModelCode) then begin
       MessageDlg(#13#10 + 'Input Error! Must compile it first', mtError, [mbOK], 0);
      edModelName.SetFocus;

      Exit;
    end;
  end;

  if g_bNewModel or g_bRenModel or g_bCopyModel then begin
//		if FileExists(CmmYT.GetFilePath(Trim(Edit_ModelName.Text), MODEL_PATH)) then begin
    if FileExists(Common.GetFilePath(Trim(edModelName.Text), MODEL_PATH)) then begin
//			MessageDlg(#13#10 + 'Input Error! Model Name [' + Trim(Edit_ModelName.Text) + '] is already Exist!', mtError, [mbOk], 0);
      MessageDlg(#13#10 + 'Input Error! Model Name [' + Trim(edModelName.Text) + '] is already Exist!', mtError, [mbOk], 0);
      edModelName.SelectAll;
      edModelName.SetFocus;

      Exit;
    end;



    if g_bCopyModel then begin   // 새로운 Model일 경우 List에 추가한다.
    // COPY MODEL일 경우 prg 파일도 같?? 변경하도록 요구함 (BOE)
      sOldName := lstModelList.Items.Strings[lstModelList.ItemIndex];
      sNewName := Trim(edModelName.Text);
      // 리스트에 동일한 내용이 있으면 저장 하지 말자.
      if MessageDlg(#13#10 + format('Do you want to copy model [%s] to model [%s]?',[sOldName,sNewName]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
        for i := 0 to Pred(lstModelList.Items.Count) do begin
          if lstModelList.Items.Strings[i] = sNewName then begin
            MessageDlg(#13#10 + 'Input Error! Model Name [' + Trim(edModelName.Text) + '] is already Exist!', mtError, [mbOk], 0);
            Exit;
          end;
        end;
      end
      else Exit;


      CheckAndCopyModelData(sOldName,sNewName);
    end;
  end;

  if g_bRenModel then begin
//		sOldName := LBox_Model.Items.Strings[LBox_Model.ItemIndex];
    sOldName := lstModelList.Items.Strings[lstModelList.ItemIndex];
//		sNewName := Trim(Edit_ModelName.Text);
    sNewName := Trim(edModelName.Text);
(*
    if not RenameFile(Common.GetFilePath(sOldName, MODEL_PATH), Common.GetFilePath(sNewName, MODEL_PATH)) then begin
      edModelName.SelectAll;
      edModelName.SetFocus;

      Exit;
    end;
    if not RenameFile(Common.GetFilePath(sOldName, SCRIPT_PATH_ISU), Common.GetFilePath(sNewName, SCRIPT_PATH_ISU)) then begin
      edModelName.SelectAll;
      edModelName.SetFocus;
      Exit;
    end;
    if not RenameFile(Common.GetFilePath(sOldName, SCRIPT_PATH_PSU), Common.GetFilePath(sNewName, SCRIPT_PATH_PSU)) then begin
      edModelName.SelectAll;
      edModelName.SetFocus;
      Exit;
    end;
*)
    // 폴더 이름 변경이 쉽지 않아서. Copy하고 이전 데이터 삭제하기.
    CheckAndCopyModelData(sOldName,sNewName);
    CheckAndDeleteModelData(sOldName);

  end;
  //-----------------------------------------------------------------------------------

  if g_bNewModel or g_bCopyModel then begin   // 새로운 Model일 경우 List에 추가한다.
//		AddAndFindItemToListbox(LBox_Model, Edit_ModelName.Text, True, True);
    AddAndFindItemToListbox(lstModelList, edModelName.text, True, True);
  end;

  if g_bRenModel then begin
    lstModelList.Sorted := False;
    lstModelList.Items.Strings[lstModelList.ItemIndex] := sNewName;
    lstModelList.Sorted := True;
    AddAndFindItemToListbox(lstModelList, sNewName, False, True);
    //g_bRenModel := False;
  end
  else begin
    //mmProgramAll.Lines.SaveToFile(Common.Path.MODEL_CUR + (Trim(edModelName.Text))+'.isu');
  end;

  if not SaveModelInfoBuf then Exit;
  Common.SystemInfo.TestModel := edModelName.Text;


  //Edit_ModelName.ReadOnly := True;
  if g_bNewModel or g_bCopyModel or g_bRenModel then begin
    lstModelListClick(nil);
  end;
  Common.SaveModelInfo(Trim(edModelName.Text));
  Common.SaveModelInfoDLL(Trim(edModelName.Text));
  Common.SaveSystemInfo;
  Script.LoadScript(Common.Path.MODEL_CUR + (Trim(edModelName.Text))+'.isu');

  btnCompileScriptClick(Self);
  btnCompilePsuClick(Self);

  Common.m_bIsChanged := True;
  MessageDlg(#13#10 + 'Model Information File Saving OK!', mtInformation, [mbOk], 0);
end;


procedure TfrmModelInfo.btnSPCClick(Sender: TObject);
begin
  frmExPat := TfrmExPat.Create(nil);
  try
    frmExPat.ShowModal;
  finally
    Freeandnil(frmExPat);
  end;
end;

procedure TfrmModelInfo.cboPTypeChange(Sender: TObject);
var
  Rslt, i: Integer;
  sFindFile, sPatName: string;
  SearchRec: TSearchRec;
begin
  if cboPType.Text = '' then begin
    cboPName.Items.Clear;
    Exit;
  end;

  cboPName.Sorted := False;
  cboPName.Items.Clear;

  if cboPType.ItemIndex = PTYPE_NORMAL then begin
    cboResolution.Visible := False;
    sFindFile := Common.Path.Pattern + '*.pat';
    for i :=0 to MAX_PATTERN_CNT -1 do begin
      if imgPPreview.InfoPat[i].pat.Info.isRegistered then begin
        sPatName := string(imgPPreview.InfoPat[i].pat.Data.PatName);
        cboPName.Items.Add(sPatName) ;
      end;
    end;
  end
  else if cboPType.ItemIndex = PTYPE_BITMAP then begin
    cboResolution.Visible := True;
    if cboResolution.ItemIndex = 0 then begin
      sFindFile := Common.Path.BMP + '*.bmp';
    end;

  end;

  Rslt := FindFirst(sFindFile, faAnyFile, SearchRec);
  cboPName.DisableAlign;
  while Rslt = 0 do  begin   // Pattern Folder에서 Pattern Name을 검색하여 ComboBox 에 삽입
    if Length(SearchRec.Name) > 4 then begin
      if cboResolution.Visible then begin
        if cboPType.ItemIndex = 0 then    sPatName := Copy(SearchRec.Name, 1, Length(SearchRec.Name) - 4)
        else                              sPatName := SearchRec.Name;
      end
      else begin
         sPatName := SearchRec.Name;
      end;
      cboPName.Items.Add(sPatName);      // ComboBox에 Pattern Name 추가
    end;
    Rslt := FindNext(Searchrec);
  end;
  FindClose(SearchRec);
  cboPName.EnableAlign;
//      cboResolutionChange(Sender);
  cboPName.ItemIndex := 0;
end;

procedure CopyFolder(Source, Dest: string);
var
  F: TSearchRec;
  sSourceFile, sDestFile, sSourceDir, sDestDir: string;
begin
  if not DirectoryExists(Dest) then
    ForceDirectories(Dest);
  if FindFirst(Source + '\*.*', faAnyFile, F) = 0 then
  begin
    try
      repeat
        if (F.Name = '.') or (F.Name = '..') then
          Continue;
        sSourceFile := Source + '\' + F.Name;
        sDestFile := Dest + '\' + F.Name;
        if (F.Attr and faDirectory) = faDirectory then
        begin
          if not DirectoryExists(sDestFile) then
            ForceDirectories(sDestFile);
          CopyFolder(sSourceFile, sDestFile);
        end
        else
          CopyFile(PChar(sSourceFile), PChar(sDestFile), False);
      until FindNext(F) <> 0;
    finally
      FindClose(F);
    end;
  end;
end;


//function TfrmModelInfo.CopyFolder(const SourcePath, DestinationPath: string): Boolean;
//var
//  Files: TStringDynArray;
//  FileName, SourceFile, DestFile: string;
//begin
//  Result := False;
//
//  // 소스 폴더가 존재하는지 확인
//  if not TDirectory.Exists(SourcePath) then
//    Exit;
//
//  // 대상 폴더 생성
//  TDirectory.CreateDirectory(DestinationPath);
//
//  // 폴더 내 파일들을 복사
//  Files := TDirectory.GetFiles(SourcePath);
//  for FileName in Files do
//  begin
//    SourceFile := System.IOUtils.TPath.Combine(SourcePath, FileName);
//    DestFile := System.IOUtils.TPath.Combine(DestinationPath, FileName);
//    TFile.Copy(SourceFile, DestFile);
//  end;
//
//  // 폴더 내 하위 폴더들을 재귀적으로 복사
//  Files := TDirectory.GetDirectories(SourcePath);
//  for FileName in Files do
//  begin
//    SourceFile := System.IOUtils.TPath.Combine(SourcePath, FileName);
//    DestFile := System.IOUtils.TPath.Combine(DestinationPath, FileName);
//    CopyFolder(SourceFile, DestFile);
//  end;
//
//  Result := True;
//end;


procedure TfrmModelInfo.CheckAndCopyModelData(oldName, newName: String);
var
  sNewModeDir, sOldModeDir, sNewCompiled, sOldCompiled : string;
begin

  sNewModeDir := Common.Path.MODEL + newName + '\';
  sOldModeDir := Common.Path.MODEL + oldName + '\';
  Common.CheckDir(sNewModeDir);

  sNewCompiled := sNewModeDir + 'compiled\';
  sOldCompiled := sOldModeDir + 'compiled\';
  Common.CheckDir(sNewCompiled);

  sNewCompiled := sNewModeDir + 'Setting\';
  sOldCompiled := sOldModeDir + 'Setting\';
  Common.CheckDir(sNewCompiled);
  CopyFolder(sOldCompiled,sNewCompiled);

  if FileExists(sOldModeDir + 'LGD_OC_AstractPlatForm.dll') then
    CopyFile(PChar(sOldModeDir + 'LGD_OC_AstractPlatForm.dll'), PChar(sNewModeDir +'LGD_OC_AstractPlatForm.dll'), False);

  if FileExists(sOldModeDir + 'LGD_OC_Observers.dll') then
    CopyFile(PChar(sOldModeDir + 'LGD_OC_Observers.dll'), PChar(sNewModeDir +'LGD_OC_Observers.dll'), False);
  if FileExists(sOldModeDir + 'OC_Converter.dll') then
    CopyFile(PChar(sOldModeDir + 'OC_Converter.dll'), PChar(sNewModeDir +'OC_Converter.dll'), False);
  if FileExists(sOldModeDir + 'LGD_OC_Standard_InitAlgorithm.dll') then
    CopyFile(PChar(sOldModeDir + 'LGD_OC_Standard_InitAlgorithm.dll'), PChar(sNewModeDir +'LGD_OC_Standard_InitAlgorithm.dll'), False);
  if FileExists(sOldModeDir + 'LGD_OC_Standard_SearchingAlgorithm.dll') then
    CopyFile(PChar(sOldModeDir + 'LGD_OC_Standard_SearchingAlgorithm.dll'), PChar(sNewModeDir +'LGD_OC_Standard_SearchingAlgorithm.dll'), False);
  if FileExists(sOldModeDir + 'LGD_OC_X2146.dll') then
    CopyFile(PChar(sOldModeDir + 'LGD_OC_X2146.dll'), PChar(sNewModeDir +'LGD_OC_X2146.dll'), False);
   if FileExists(sOldModeDir + 'AFM_DLL.dll') then
    CopyFile(PChar(sOldModeDir + 'AFM_DLL.dll'), PChar(sNewModeDir +'AFM_DLL.dll'), False);
  if FileExists(sOldModeDir + 'libfftw3-3.dll') then
    CopyFile(PChar(sOldModeDir + 'libfftw3-3.dll'), PChar(sNewModeDir +'libfftw3-3.dll'), False);
  if FileExists(sOldModeDir + 'libfftw3f-3.dll') then
    CopyFile(PChar(sOldModeDir + 'libfftw3f-3.dll'), PChar(sNewModeDir +'libfftw3f-3.dll'), False);
  if FileExists(sOldModeDir + 'libfftw3l-3.dll') then
    CopyFile(PChar(sOldModeDir + 'libfftw3l-3.dll'), PChar(sNewModeDir +'libfftw3l-3.dll'), False);
  if FileExists(sOldModeDir + 'MTOOptimization.dll') then
    CopyFile(PChar(sOldModeDir + 'MTOOptimization.dll'), PChar(sNewModeDir +'MTOOptimization.dll'), False);
  if FileExists(sOldModeDir + 'Owf.Controls.DigitalDisplayControl.dll') then
    CopyFile(PChar(sOldModeDir + 'Owf.Controls.DigitalDisplayControl.dll'), PChar(sNewModeDir +'Owf.Controls.DigitalDisplayControl.dll'), False);


  if FileExists(sOldModeDir + oldName + '.mcf') then
    CopyFile(PChar(sOldModeDir + oldName + '.mcf'), PChar(sNewModeDir + newName + '.mcf'), False);

  if FileExists(sOldModeDir + oldName + '.isu') then
    CopyFile(PChar(sOldModeDir + oldName + '.isu'), PChar(sNewModeDir + newName + '.isu'), False);

  if FileExists(sOldModeDir + oldName + '.psu') then
    CopyFile(PChar(sOldModeDir + oldName + '.psu'), PChar(sNewModeDir + newName + '.psu'), False);

{$IFDEF ISPD_L_OPTiC}
  if chkUseOcparam.Checked then begin
    if FileExists(sOldModeDir + oldName + '_oc_param.csv') then
      CopyFile(PChar(sOldModeDir + oldName + '_oc_param.csv'), PChar(sNewModeDir + newName + '_oc_param.csv'), False);
  end;
  if chkUseOcVerify.Checked then begin
    if FileExists(sOldModeDir + oldName + '_oc_verify.csv') then
      CopyFile(PChar(sOldModeDir + oldName + '_oc_verify.csv'), PChar(sNewModeDir + newName + '_oc_verify.csv'), False);
  end;
  if chkUseOcOffset.Checked then begin
    if FileExists(sOldModeDir + oldName + '_oc_offset.csv') then
      CopyFile(PChar(sOldModeDir + oldName + '_oc_offset.csv'), PChar(sNewModeDir + newName + '_oc_offset.csv'), False);
  end;
  if chkUseOtpTable.Checked then begin
    if FileExists(sOldModeDir + oldName + '_otp_table.csv') then
      CopyFile(PChar(sOldModeDir + oldName + '_otp_table.csv'), PChar(sNewModeDir + newName + '_otp_table.csv'), False);
  end;
{$ENDIF}

  if FileExists(sOldCompiled + oldName + '.miau') then
    CopyFile(PChar(sOldCompiled + oldName + '.miau'), PChar(sNewCompiled + newName + '.miau'), False);

  if FileExists(sOldCompiled + oldName + '.mioff') then
    CopyFile(PChar(sOldCompiled + oldName + '.mioff'), PChar(sNewCompiled + newName + '.mioff'), False);

  if FileExists(sOldCompiled + oldName + '.mion') then
    CopyFile(PChar(sOldCompiled + oldName + '.mion'), PChar(sNewCompiled + newName + '.mion'), False);

  if FileExists(sOldCompiled + oldName + '.mtp') then
    CopyFile(PChar(sOldCompiled + oldName + '.mtp'), PChar(sNewCompiled + newName + '.mtp'), False);

  if FileExists(sOldCompiled + oldName + '.otpr') then
    CopyFile(PChar(sOldCompiled + oldName + '.otpr'), PChar(sNewCompiled + newName + '.otpr'), False);

  if FileExists(sOldCompiled + oldName + '.otpw') then
    CopyFile(PChar(sOldCompiled + oldName + '.otpw'), PChar(sNewCompiled + newName + '.otpw'), False);

  if FileExists(sOldCompiled + oldName + '.pwoff') then
    CopyFile(PChar(sOldCompiled + oldName + '.pwoff'), PChar(sNewCompiled + newName + '.pwoff'), False);

  if FileExists(sOldCompiled + oldName + '.pwon') then
    CopyFile(PChar(sOldCompiled + oldName + '.pwon'), PChar(sNewCompiled + newName + '.pwon'), False);

  if FileExists(sOldCompiled + oldName + '.misc') then
    CopyFile(PChar(sOldCompiled + oldName + '.misc'), PChar(sNewCompiled + newName + '.misc'), False);
end;

procedure TfrmModelInfo.CheckAndDeleteModelData(fName: String);
var
  sDirPath : string;
begin
  sDirPath := Common.Path.MODEL + fName;// + '\';
  RemoveDirAll( sDirPath );
end;


function TfrmModelInfo.CheckInputVal: Boolean;
var
  bRet : Boolean;
  nTemp : Integer;
begin
  bRet := False;
  Common.EdModelInfoPG.PgModelConf.link_rate     := StrToIntDef(Trim(edModelConfig_link_rate.Text), 0);

  if (Common.EdModelInfoPG.PgModelConf.link_rate > 8100) or
     (Common.EdModelInfoPG.PgModelConf.link_rate < 0)  then begin
    ShowMessage(Format('Link Rate range is 0 ~ 8100 Gbps : Input (%s)',[edModelConfig_link_rate.Text]));
    edModelConfig_link_rate.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgModelConf.Vsync > 999) or
     (Common.EdModelInfoPG.PgModelConf.Vsync < 0)  then begin
    ShowMessage(Format('VSync Range is 0 ~ 999 Hz : Input (%s)',[edModelConfig_Vsync.Text]));
    edModelConfig_Vsync.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgPwrData.PWR_SLOPE > 2000) or
     ((Common.EdModelInfoPG.PgPwrData.PWR_SLOPE < 500) and (Common.EdModelInfoPG.PgPwrData.PWR_SLOPE <> 0))  then begin
    ShowMessage(Format('VSync Range is 500 ~ 2000 us : Input (%s)',[edVolSet_SlopeSet.Text]));
    edVolSet_SlopeSet.SetFocus;
    Exit(bRet);
  end;

  // Voltage checking.
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD1] > 4900) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD1] < 0)  then begin
    ShowMessage(Format('VCC Range is 0 ~ 4.9 V : Input (%s)',[edVolSet_VDD1.Text]));
    edVolSet_VDD1.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD2] > 6500) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD2] < 0)  then begin
    ShowMessage(Format('VIN Range is 0 ~ 6.5 V : Input (%s)',[edVolSet_VDD2.Text]));
    edVolSet_VDD2.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD3] > 1800) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD3] < 0)  then begin
    ShowMessage(Format('VDD3 Range is 0 ~ 1.8 V : Input (%s)',[edVolSet_VDD3.Text]));
    edVolSet_VDD3.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD4] > 9900) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD4] < 0)  then begin
    ShowMessage(Format('VDD4 Range is 0 ~ 9.9 V : Input (%s)',[edVolSet_VDD4.Text]));
    edVolSet_VDD4.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD5] > 9900) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL[DefPG.PWR_VDD5] < 0)  then begin
    ShowMessage(Format('VDD5 Range is 0 ~ 9.9 V : Input (%s)',[edVolSet_VDD5.Text]));
    edVolSet_VDD5.SetFocus;
    Exit(bRet);
  end;


  // Voltage Low limit checking.
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD1] > 4900)  then begin
    ShowMessage(Format('VCC low limit Range is 0 ~ 4.9 V : Input (%s)',[edPwrLimit_VDD1_L.Text]));
    edPwrLimit_VDD1_L.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD2] > 6500)  then begin
    ShowMessage(Format('VIN low limit Range is 0 ~ 6.5 V : Input (%s)',[edPwrLimit_VDD2_L.Text]));
    edPwrLimit_VDD2_L.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD3] > 1800)  then begin
    ShowMessage(Format('VDD3 low limit Range is 0 ~ 1.8 V : Input (%s)',[edPwrLimit_VDD3_L.Text]));
    edPwrLimit_VDD3_L.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD4] > 9900)  then begin
    ShowMessage(Format('VDD4 low limit Range is 0 ~ 9.9 V : Input (%s)',[edPwrLimit_VDD4_L.Text]));
    edPwrLimit_VDD4_L.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD5] > 9900)   then begin
    ShowMessage(Format('VDD5 low limit Range is 0 ~ 9.9 V : Input (%s)',[edPwrLimit_VDD5_L.Text]));
    edPwrLimit_VDD5_L.SetFocus;
    Exit(bRet);
  end;

  // Voltage High limit checking.
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD1] > 4900) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD1] < Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD1])  then begin
    ShowMessage(Format('VCC high limit Range is %s ~ 4.9 V : Input (%s)',[edPwrLimit_VDD1_L.Text,edPwrLimit_VDD1_H.Text]));
    edPwrLimit_VDD1_H.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD2] > 6500) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD2] < Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD2])  then begin
    ShowMessage(Format('VIN high limit Range is %s ~ 6.5 V : Input (%s)',[edPwrLimit_VDD2_L.Text,edPwrLimit_VDD2_H.Text]));
    edPwrLimit_VDD2_H.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD3] > 1800) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD3] < Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD3])  then begin
    ShowMessage(Format('VDD3 high limit Range is %s ~ 1.8 V : Input (%s)',[edPwrLimit_VDD3_L.Text,edPwrLimit_VDD3_H.Text]));
    edPwrLimit_VDD3_H.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD4] > 9900) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD4] < Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD4])  then begin
    ShowMessage(Format('VDD4 high limit Range is %s ~ 9.9 V : Input (%s)',[edPwrLimit_VDD4_L.Text,edPwrLimit_VDD4_H.Text]));
    edPwrLimit_VDD4_H.SetFocus;
    Exit(bRet);
  end;

  if (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD5] > 9900) or
     (Common.EdModelInfoPG.PgPwrData.PWR_VOL_HL[DefPG.PWR_VDD5] < Common.EdModelInfoPG.PgPwrData.PWR_VOL_LL[DefPG.PWR_VDD5])  then begin
    ShowMessage(Format('VDD5 high limit Range is %s ~ 9.9 V : Input (%s)',[edPwrLimit_VDD5_L.Text,edPwrLimit_VDD5_H.Text]));
    edPwrLimit_VDD5_H.SetFocus;
    Exit(bRet);
  end;

  // Current Low limit checking.
  if (Common.EdModelInfoPG.PgPwrData.PWR_CUR_LL[DefPG.PWR_VDD1] > 4000)  then begin
    ShowMessage(Format('IVCC low limit Range is %s ~ 4000 mA : Input (%s)',[edPwrLimit_IVDD1_L.Text]));
    edPwrLimit_IVDD1_L.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_CUR_LL[DefPG.PWR_VDD2] > 6000)  then begin
    ShowMessage(Format('IVIN low limit Range is %s ~ 6000 mA : Input (%s)',[edPwrLimit_IVDD2_L.Text]));
    edPwrLimit_IVDD2_L.SetFocus;
    Exit(bRet);
  end;


  // Current High limit checking.
  if (Common.EdModelInfoPG.PgPwrData.PWR_CUR_HL[DefPG.PWR_VDD1] > 4000) or
     (Common.EdModelInfoPG.PgPwrData.PWR_CUR_HL[DefPG.PWR_VDD1] < Common.EdModelInfoPG.PgPwrData.PWR_CUR_LL[DefPG.PWR_VDD1])  then begin
    ShowMessage(Format('IVCC high limit Range is %s ~ 4000 mA : Input (%s)',[edPwrLimit_IVDD1_L.Text, edPwrLimit_IVDD1_H.Text]));
    edPwrLimit_IVDD1_H.SetFocus;
    Exit(bRet);
  end;
  if (Common.EdModelInfoPG.PgPwrData.PWR_CUR_HL[DefPG.PWR_VDD2] > 6000) or
     (Common.EdModelInfoPG.PgPwrData.PWR_CUR_HL[DefPG.PWR_VDD2] < Common.EdModelInfoPG.PgPwrData.PWR_CUR_LL[DefPG.PWR_VDD2])  then begin
    ShowMessage(Format('IVIN high limit Range is %s ~ 6000 mA : Input (%s)',[edPwrLimit_IVDD1_L.Text, edPwrLimit_IVDD2_H.Text]));
    edPwrLimit_IVDD2_H.SetFocus;
    Exit(bRet);
  end;

  bRet := True;
  Result := bRet;
end;


//function TfrmModelInfo.CheckInputVal: Boolean;
//var
//  bRet : Boolean;
//  nTemp : Integer;
//begin
//  bRet := False;
//  {$IFDEF DP860_TBD_XXXX} //TBD:DP860?
//  if Common.TestModelInfoPG.PWR_VOL[DefCommon.PWR_VDD1] > 25000 then begin
//    ShowMessage(Format('VDD1 Power Range is 0 ~ 25 V : Input (%s)',[edVDD1.Text]));
//    edVDD1.SetFocus;
//    Exit(bRet);
//  end;
//  if Common.TestModelInfoPG.PWR_VOL_HL[DefCommon.PWR_VDD1] > 25000 then begin
//    edVolVDD1_H(Format('VDD1 High limit Range is 0 ~ 25 V : Input (%s)',[edVolVDD1_H.Text]));
//    edVcc_High.SetFocus;
//    Exit(bRet);
//  end;
//
//  if Common.TestModelInfoPG.PWR_VOL_LL[DefCommon.PWR_VDD] > 25000 then begin
//    ShowMessage(Format('VDD1 low limit Range is 0 ~ 25 V : Input (%s)',[edVolVDD1_L.Text]));
//    edVolVDD1_L.SetFocus;
//    Exit(bRet);
//  end;
//  if Common.TestModelInfoPG.PWR_CUR_HL[DefCommon.PWR_VDD1] > 25000 then begin
//    edVolVDD1_H(Format('IVDD1 High limit Range is 0 ~ 25xxx A : Input (%s)',[edCurVDD1_H.Text]));
//    edCurVDD1_H.SetFocus;
//    Exit(bRet);
//  end;
//
//  if Common.TestModelInfoPG.PWR_CUR__LL[DefCommon.PWR_VDD] > 25000 then begin
//    ShowMessage(Format('IVDD1 low limit Range is 0 ~ 25xxx A : Input (%s)',[edCurVDD1_L.Text]));
//    edCurVDD1_L.SetFocus;
//    Exit(bRet);
//  end;
//  {$ENDIF}
//
//  bRet := True;
//  Result := bRet;
//end;

//function TfrmModelInfo.CheckMouseOnLine(X, Y: Integer): Boolean;
//var
//  i : Integer;
//begin
//  m_nMpoint := 0;
//  Result := False;
//
//  for i := 1 to MAX_DELAY_CNT do begin //POWER SIG 4->6
//    if (m_nSstartY+m_nSstepY*(i-1)+m_nSoffsetY <= Y) and
//      (m_nSstartY+m_nSstepY*i-m_nSoffsetY >= Y) then begin
//      m_nMpoint := i;
//      break;
//    end;
//  end;
//
//  if m_nMpoint = 0 then Exit;
//  if m_bDelay_use[m_nMpoint-1] = False then Exit;
//
//  if ((m_nDelay_position[i-1] -1) <= X) and ((m_nDelay_position[i-1] + 1) >= X) then
//       Result := True
//  else Result := False;
//end;

function TfrmModelInfo.CheckSyntex(lstResource : TStringList; nOriNumbers : array of Integer) : Integer;
var
  i, nRet, nFinalRet  : Integer;
  sData, sGrpName     : string;
  sCmd                : string;
  nStartSeq           : Integer;
  bGroupNg            : Boolean;
  slTemp              : TStringList;
begin
  lstGrpCompile.ClearGroups;

  // function 내에 들어 가지 않으면 우선 0으로 Set.
  nStartSeq := 0;
  lstGrpCompile.AddGroup('function Checking.');

  bGroupNg := False;
  nFinalRet :=  DefScript.ERR_ST_NONE;
  // 라인별로 잘못된 부분이 있는지 확인.
  for i := 0 to Pred(lstResource.Count) do begin
    sData := Trim(lstResource.Strings[i]);
    if sData = '' then Continue;

    nRet := DefScript.ERR_ST_NONE;
    // Default Start Seq ID : function Checking.
    if nStartSeq = 0 then begin
      // nStart Seq 변경을 위한 시작 단계.
      if Pos(DefScript.FUNC_CALL_START,sData) <> 0 then begin
        sGrpName := StringReplace(sData,DefScript.FUNC_CALL_START,'',[rfReplaceAll]);
        sGrpName := Trim(StringReplace(sGrpName,'()','',[rfReplaceAll]));
        Inc(nStartSeq);
        lstGrpCompile.AddGroup(sGrpName);
        if not bGroupNg then lstGrpCompile.Groups[0].Expanded := False;
        bGroupNg := False;
      end;
    end
    else begin
        if Pos(DefScript.end_func,sData) <> 0 then begin
          nStartSeq := 0; // Function 종료.
          if not bGroupNg then lstGrpCompile.Groups[lstGrpCompile.GroupCount-1].Expanded := False;
          bGroupNg := False;
        end
        else if Pos('{',sData) <> 0 then begin
          continue;
        end
        else begin
          slTemp := TStringList.Create;
          try
            ExtractStrings([' '],[],PChar(sData),slTemp);

            if slTemp.Count < 1 then begin
              nRet :=  DefScript.ERR_ST_SEME;
            end
            else begin
              sCmd := Trim(slTemp.Strings[0]);
              if sCmd = DefScript.CMD_ITEM_1 then  begin

              end
              else if sCmd = DefScript.CMD_ITEM_2 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_3 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_4 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_5 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_6 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_7 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_8 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_9 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_10 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_11 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_12 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_13 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_14 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_15 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_16 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_17 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_18 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_19 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_20 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_21 then begin

              end

              else if sCmd = DefScript.CMD_ITEM_22 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_23 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_24 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_25 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_26 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_27 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_28 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_29 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_30 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_31 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_32 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_33 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_34 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_35 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_36 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_37 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_38 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_39 then begin

              end
              else if sCmd = DefScript.CMD_ITEM_40 then begin

              end
              else begin
                nRet :=  DefScript.ERR_ST_SEME;
              end;
              if nRet <> DefScript.ERR_ST_SEME then begin
                with lstGrpCompile.AddItem(lstGrpCompile.Groups[lstGrpCompile.GroupCount-1]) do begin
                  Add(Format('%d',[nOriNumbers[i]+1])); Add(sData);
                end;
              end;
            end;
          finally
            slTemp.Free;
          end;
        end;

    end;
    if nRet <> DefScript.ERR_ST_NONE then begin
      // Script NG 발생시 오류 처리.
      mmProgramAll.TopLine      := nOriNumbers[i];
      mmProgramAll.BreakPoint[nOriNumbers[i]] := True;
      bGroupNg := True;
      nFinalRet := nRet;
//        lstGrpCompile.Groups[lstGrpCompile.GroupCount-1].Expanded := True;
    end
    else begin

    end;
  end;
  Result := nFinalRet;
end;

procedure TfrmModelInfo.DisplayModelInfo(sModelName: string);
var
  nSum: Integer;
//  sErrMsg : string;
begin

//  cboSync.ItemIndex := Common.ModelInfo.

  Common.LoadModelInfo(sModelName);

  with Common.EdModelInfoPG.PgVer do begin

    {$IFDEF PG_DP860}
    if Common.SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
      edPgVerAll.Text := VerAll;
      {$IFDEF DP860_TBD_XXXXX}
      edPgVerHW.Text    := Trim(PgVerFW);   //edPgVerFW.Color    := nColorEdit;
      edPgVerFW.Text    := Trim(PgVerFpga); //edPgVerFW.Color    := nColorEdit;
      edPgVerSubFW.Text := Trim(PgVerFpga); //edPgVerSubFW.Color := nColorEdit;
      edPgVerFPGA.Text  := Trim(PgVerFpga); //edPgVerFPGA.Color  := nColorEdit;
      edPgVerPWR.text   := Trim(PgVerFpga); //edPgVerPWR.Color   := nColorEdit;
      {$ENDIF}
    end;
    {$ENDIF}
  end;


  with Common.EdModelInfoPG.PgModelConf do begin


    {$IFDEF PG_DP860}
    if Common.SystemInfo.PG_TYPE = PG_TYPE_DP860 then begin
      // Resolution
      edPanelResH_Active.Text := Format('%d',[H_Active]);  //edPanelResH_Active.Color := nColorEdit;
      edPanelResH_BP.Text     := Format('%d',[H_BP]);      //edPanelResH_BP.Color     := nColorEdit;
      edPanelResH_SA.Text     := Format('%d',[H_SA]);      //edPanelResH_SA.Color     := nColorEdit;
      edPanelResH_FP.Text     := Format('%d',[H_FP]);      //edPanelResH_FP.Color     := nColorEdit;
      edPanelResV_Active.Text := Format('%d',[V_Active]);  //edPanelResV_Active.Color := nColorEdit;
      edPanelResV_BP.Text     := Format('%d',[V_BP]);      //edPanelResV_BP.Color     := nColorEdit;
      edPanelResV_SA.Text     := Format('%d',[V_SA]);      //edPanelResV_SA.Color     := nColorEdit;
      edPanelResV_FP.Text     := Format('%d',[V_FP]);      //edPanelResV_FP.Color     := nColorEdit;
      // Timing
  		edModelConfig_link_rate.Text  := Format('%d',[link_rate]);  //edModelConfig_link_rate.Color  := nColorEdit;
  		cboModelConfig_lane.ItemIndex	:= lane;                      //edModelConfig_lane.Color       := nColorEdit;
  		edModelConfig_Vsync.Text		  := Format('%d',[Vsync]);      //edModelConfig_Vsync.Color      := nColorEdit;
  		edModelConfig_RGBFormat.Text  := RGBFormat;                 //edModelConfig_RGBFormat.Color  := nColorEdit;
  		cboModelConfig_ALPM_Mode.ItemIndex  := ALPM_Mode;           //cboModelConfig_ALPM_Mode.Color := nColorEdit;
  		edModelConfig_vfb_offset.Text := Format('%d',[vfb_offset]); //edModelConfig_vfb_offset.Color := nColorEdit;
      // ALPDP
      edALPDP_h_fdp.Text      := Format('%d',[h_fdp]);    //edALPDP_h_fdp.Color    := nColorEdit;
      edALPDP_h_sdp.Text      := Format('%d',[h_sdp]);    //edALPDP_h_sdp.Color    := nColorEdit;
      edALPDP_h_pcnt.Text     := Format('%d',[h_pcnt]);   //edALPDP_h_pcnt.Color   := nColorEdit;
      edALPDP_vb_n5b.Text     := Format('%d',[vb_n5b]);   //edALPDP_vb_n5b.Color   := nColorEdit;
      edALPDP_vb_n7.Text      := Format('%d',[vb_n7]);    //edALPDP_vb_n7.Color    := nColorEdit;
      edALPDP_vb_n5a.Text     := Format('%d',[vb_n5a]);   //edALPDP_vb_n5a.Color   := nColorEdit;
      edALPDP_vb_sleep.Text   := Format('%d',[vb_sleep]); //edALPDP_vb_sleep.Color := nColorEdit;
      edALPDP_vb_n2.Text      := Format('%d',[vb_n2]);    //edALPDP_vb_n2.Color    := nColorEdit;
      edALPDP_vb_n3.Text      := Format('%d',[vb_n3]);    //edALPDP_vb_n3.Color    := nColorEdit;
      edALPDP_vb_n4.Text      := Format('%d',[vb_n4]);    //edALPDP_vb_n4.Color    := nColorEdit;
      edALPDP_m_vid.Text      := Format('%d',[m_vid]);    //edALPDP_m_vid.Color    := nColorEdit;
      edALPDP_n_vid.Text      := Format('%d',[n_vid]);    //edALPDP_n_vid.Color    := nColorEdit;
      edALPDP_misc_0.Text     := Format('%d',[misc_0]);   //edALPDP_misc_0.Color   := nColorEdit;
      edALPDP_misc_1.Text     := Format('%d',[misc_1]);   //edALPDP_misc_1.Color   := nColorEdit;
      cboALPDP_xpol.ItemIndex := xpol;                    //cboALPDP_xpol.Color    := nColorEdit;
      edALPDP_xdelay.Text     := Format('%d',[xdelay]);   //edALPDP_xdelay.Color   := nColorEdit;
      edALPDP_h_mg.Text       := Format('%d',[h_mg]);     //edALPDP_h_mg.Color := nColorEdit;
      edALPDP_NoAux_Sel.Text    := Format('%d',[NoAux_Sel]);    //edALPDP_NoAux_Sel.Color    := nColorEdit;
      edALPDP_NoAux_Active.Text := Format('%d',[NoAux_Active]); //edALPDP_NoAux_Active.Color := nColorEdit;
      edALPDP_NoAux_Sleep.Text  := Format('%d',[NoAux_Sleep]);  //edALPDP_NoAux_Sleep.Color  := nColorEdit;
      //
      edALPDP_critical_section.Text  := Format('%d',[critical_section]); //edALPDP_critical_section.Color := nColorEdit;
      edALPDP_tps.Text               := Format('%d',[tps]);
      edALPDP_v_blank.Text           := Format('%d',[v_blank]);                     //cboALPDP_v_blank.Color      := nColorEdit;
      cboALPDP_chop_enable.ItemIndex := chop_enable;                     //cboALPDP_chop_enable.Color  := nColorEdit;
      edALPDP_chop_interval.Text     := Format('%d',[chop_interval]);    //edALPDP_chop_interval.Color := nColorEdit;
      edALPDP_chop_size.Text         := Format('%d',[chop_size]);        //edALPDP_chop_size.Color     := nColorEdit;
    end;
    {$ENDIF}
  end;


  {$IFDEF PG_DP860}
//if Common.SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
  with Common.EdModelInfoPG.PgPwrData do begin
    // Voltage Setting
    edVolSet_VDD1.Text := Format('%0.3f',[PWR_VOL[DefPG.PWR_VDD1] / 1000]); //edVolSet_VDD1.Color := nColorEdit; //VCC
    edVolSet_VDD2.Text := Format('%0.3f',[PWR_VOL[DefPG.PWR_VDD2] / 1000]); //edVolSet_VDD2.Color := nColorEdit; //VIN
    edVolSet_VDD3.Text := Format('%0.3f',[PWR_VOL[DefPG.PWR_VDD3] / 1000]); //edVolSet_VDD3.Color := nColorEdit; //VDD3
    edVolSet_VDD4.Text := Format('%0.3f',[PWR_VOL[DefPG.PWR_VDD4] / 1000]); //edVolSet_VDD4.Color := nColorEdit; //VDD4
    edVolSet_VDD5.Text := Format('%0.3f',[PWR_VOL[DefPG.PWR_VDD5] / 1000]); //edVolSet_VDD5.Color := nColorEdit; //VDD5
    // Voltage Setting - Slope Set
    edVolSet_SlopeSet.Text := Format('%d',[PWR_SLOPE]); //edVolSet_SlopeSet.Color := nColorEdit; //Slope_Set
    // Power Limit - Voltage
    edPwrLimit_VDD1_L.Text  := Format('%0.3f',[PWR_VOL_LL[DefPG.PWR_VDD1] / 1000]); //edPwrLimit_VDD1_L.Color := nColorEdit; //VCC
    edPwrLimit_VDD1_H.Text  := Format('%0.3f',[PWR_VOL_HL[DefPG.PWR_VDD1] / 1000]); //edPwrLimit_VDD1_H.Color := nColorEdit;
    edPwrLimit_VDD2_L.Text  := Format('%0.3f',[PWR_VOL_LL[DefPG.PWR_VDD2] / 1000]); //edPwrLimit_VDD2_L.Color := nColorEdit; //VIN
    edPwrLimit_VDD2_H.Text  := Format('%0.3f',[PWR_VOL_HL[DefPG.PWR_VDD2] / 1000]); //edPwrLimit_VDD2_H.Color := nColorEdit;
    edPwrLimit_VDD3_L.Text  := Format('%0.3f',[PWR_VOL_LL[DefPG.PWR_VDD3] / 1000]); //edPwrLimit_VDD3_L.Color := nColorEdit; //VDD3
    edPwrLimit_VDD3_H.Text  := Format('%0.3f',[PWR_VOL_HL[DefPG.PWR_VDD3] / 1000]); //edPwrLimit_VDD3_H.Color := nColorEdit;
    edPwrLimit_VDD4_L.Text  := Format('%0.3f',[PWR_VOL_LL[DefPG.PWR_VDD4] / 1000]); //edPwrLimit_VDD4_L.Color := nColorEdit; //VDD4
    edPwrLimit_VDD4_H.Text  := Format('%0.3f',[PWR_VOL_HL[DefPG.PWR_VDD4] / 1000]); //edPwrLimit_VDD4_H.Color := nColorEdit;
    edPwrLimit_VDD5_L.Text  := Format('%0.3f',[PWR_VOL_LL[DefPG.PWR_VDD5] / 1000]); //edPwrLimit_VDD5_L.Color := nColorEdit; //VDD5
    edPwrLimit_VDD5_H.Text  := Format('%0.3f',[PWR_VOL_HL[DefPG.PWR_VDD5] / 1000]); //edPwrLimit_VDD5_H.Color := nColorEdit;
    // Power Limit - Current
    edPwrLimit_IVDD1_L.Text := Format('%d',[PWR_CUR_LL[DefPG.PWR_VDD1]]); //edPwrLimit_IVDD1_L.Color := nColorEdit; //VCC
    edPwrLimit_IVDD1_H.Text := Format('%d',[PWR_CUR_HL[DefPG.PWR_VDD1]]); //edPwrLimit_IVDD1_H.Color := nColorEdit;
    edPwrLimit_IVDD2_L.Text := Format('%d',[PWR_CUR_LL[DefPG.PWR_VDD2]]); //edPwrLimit_IVDD2_L.Color := nColorEdit; //VIN
    edPwrLimit_IVDD2_H.Text := Format('%d',[PWR_CUR_HL[DefPG.PWR_VDD2]]); //edPwrLimit_IVDD2_H.Color := nColorEdit;
    edPwrLimit_IVDD3_L.Text := Format('%d',[PWR_CUR_LL[DefPG.PWR_VDD3]]); //edPwrLimit_IVDD3_L.Color := nColorEdit; //VDD3
    edPwrLimit_IVDD3_H.Text := Format('%d',[PWR_CUR_HL[DefPG.PWR_VDD3]]); //edPwrLimit_IVDD3_H.Color := nColorEdit;
    edPwrLimit_IVDD4_L.Text := Format('%d',[PWR_CUR_LL[DefPG.PWR_VDD4]]); //edPwrLimit_IVDD4_L.Color := nColorEdit; //VDD4
    edPwrLimit_IVDD4_H.Text := Format('%d',[PWR_CUR_HL[DefPG.PWR_VDD4]]); //edPwrLimit_IVDD4_H.Color := nColorEdit;
    edPwrLimit_IVDD5_L.Text := Format('%d',[PWR_CUR_LL[DefPG.PWR_VDD5]]); //edPwrLimit_IVDD5_L.Color := nColorEdit; //VDD5
    edPwrLimit_IVDD5_H.Text := Format('%d',[PWR_CUR_HL[DefPG.PWR_VDD5]]); //edPwrLimit_IVDD5_H.Color := nColorEdit;
  end;

  with Common.EdModelInfoPG.PgPwrSeq do begin
  //cboPowerSeqType.ItemIndex  := SeqType;              //cboPowerSeqType.Color  := nColorEdit;  //obsoleted!!!
    //
    edPowerSeqOnSeq1.Text  := Format('%d',[SeqOn[0]]);  //edPowerSeqOnSeq1.Color  := nColorEdit;
    edPowerSeqOnSeq2.Text  := Format('%d',[SeqOn[1]]);  //edPowerSeqOnSeq2.Color  := nColorEdit;
    edPowerSeqOnSeq3.Text  := Format('%d',[SeqOn[2]]);  //edPowerSeqOnSeq3.Color  := nColorEdit;
    //
    edPowerSeqOffSeq1.Text := Format('%d',[SeqOff[0]]); //edPowerSeqOffSeq1.Color := nColorEdit;
    edPowerSeqOffSeq2.Text := Format('%d',[SeqOff[1]]); //edPowerSeqOffSeq2.Color := nColorEdit;
    edPowerSeqOffSeq3.Text := Format('%d',[SeqOff[2]]); //edPowerSeqOffSeq3.Color := nColorEdit;
  end;
    {$ENDIF}
  with Common.EdModelInfoFLOW do begin
    //
    cboModelType.ItemIndex := ModelType;
    cbFlowOptIonizerOnOff.Checked := UseIonOnOff;
    cbFlowOptUseDutDetect.Checked := UseDutDetect;

    edSerialNoAddr.Text := format('0x%0.4x',[SerialNoFlashInfo.nAddr]);
    edSerialNoLength.Text := format('%d',[SerialNoFlashInfo.nLength]);
    cboCa310Channel.ItemIndex := Ca410MemCh;
    //

  end;

//  chkUseOcparam.Checked   := Common.TempModelInfo2.useOcParam;
//  chkUseOcVerify.Checked  := Common.TempModelInfo2.useOcVerify;
//  chkUseOtpTable.Checked  := Common.TempModelInfo2.useOtpTable;
//  chkUseOcOffset.Checked  := Common.TempModelInfo2.useOcOffset;
//
//  cboCa310Channel.ItemIndex := common.TempModelInfo2.Ca310MemCh;



  //edZxis.Text             := Format('%d',[common.TempModelInfo2.Zxis]);
end;

//procedure TfrmModelInfo.DisplayVddDelayValue(nIdx: Integer; bModel: Boolean);
//var
//  sTarget : string;
//begin
//  if nIdx = -1 then Exit;
//
//  case nIdx of
//    0 : sTarget := 'edDelayIpnl';
//    1 : sTarget := 'edDelayIddi';
//    2 : sTarget := 'edDelayIio';
//    3 : sTarget := 'edDelayIpp';
//    4 : sTarget := 'edDelayIbat';
//    5 : sTarget := 'edDelayIci';
//    6 : sTarget := 'edDelayReset';
//  end;
//  if m_bDelay_use[nIdx] = False then
//
//    (FindComponent(sTarget) as TRzEdit).Text := '0'
//  else begin
//    if bModel = False then
//      if (FindComponent(sTarget) as TRzEdit).Text <> '0' then
//        m_nDelay_value[nIdx] := StrToInt((FindComponent(sTarget) as TRzEdit).Text);
//    if (m_nDelay_value[nIdx] >=0) and (m_nDelay_value[nIdx] <= MAX_DELAY_TIME) then
//      (FindComponent(sTarget) as TRzEdit).Text := IntToStr(m_nDelay_value[nIdx])
//    else
//      (FindComponent(sTarget) as TRzEdit).Text := '0';
//  end;
//end;

procedure TfrmModelInfo.Display_PatGroup_data(DisplayPatGrp: TPatterGroup);
var
  i: Integer;
begin
  gridPatternList.RowCount := 1;
  gridPatternList.Rows[0].Clear;
  edPGrpName.Text := string(DisplayPatGrp.GroupName);
  edPCnt.Text := Format('%d',[DisplayPatGrp.PatCount]);

  if DisplayPatGrp.PatCount > 0 then begin
    gridPatternList.RowCount := DisplayPatGrp.PatCount;
    for i := 0  to Pred(DisplayPatGrp.PatCount) do begin
      gridPatternList.Cells[1, i] := DisplayPatGrp.PatName[i];
      case DisplayPatGrp.PatType[i] of
        DefCommon.PTYPE_NORMAL  : gridPatternList.Cells[0, i] := 'Pattern';
        DefCommon.PTYPE_BITMAP  : gridPatternList.Cells[0, i] := 'Bitmap';
      end;
      if DisplayPatGrp.VSync[i] = 0 then  gridPatternList.Cells[2, i] := 'None'
      else                                gridPatternList.Cells[2, i] := Format('%d',[DisplayPatGrp.VSync[i]]);
      gridPatternList.Cells[3, i] := Format('%d',[DisplayPatGrp.LockTime[i]]);
    end;
  end;
  gridPatternList.Row := 0;

end;

procedure TfrmModelInfo.Display_Script_data(sModelname: string);
var
  FileName : string;
begin

  edModelName.Text := sModelname;
  FileName := Common.Path.MODEL_CUR+sModelname+'.isu';

  mmProgramAll.Lines.Clear;
  if FileExists(FileName) then begin
    mmProgramAll.Lines.LoadFromFile(FileName);
  end;

  ScrMemo1.Lines.Clear;
  FileName := Common.Path.MODEL_CUR + sModelname +'.psu';
  if FileExists(FileName) then begin
    ScrMemo1.Lines.LoadFromFile(FileName);
  end;


end;

//procedure TfrmModelInfo.DrawLine(BitmapCanvas: TCanvas; const x, xsize, y, ysize: Integer);
//begin
//  BitmapCanvas.MoveTo(x,y);
//  BitmapCanvas.LineTo(xsize,ysize);
//end;

//procedure TfrmModelInfo.DrawPowerSequence(bType: Boolean);
//var
//  Bitmap:  TBitmap;
//  i : Integer;
//begin
//  Bitmap := TBitmap.Create;
//  try
//    Bitmap.PixelFormat := pf24bit;
//    Bitmap.Height := imgPowerSeq.Height;
//    Bitmap.Width := imgPowerSeq.Width;
//
//    Bitmap.Canvas.Brush.Color := $ffffdd; //clWhite;
//    Bitmap.Canvas.FillRect(Bitmap.Canvas.ClipRect);
//
//    Bitmap.Canvas.Pen.Width := 1;
//    Bitmap.Canvas.Pen.Style := psSolid;
//    Bitmap.Canvas.Pen.Color := RGB(255,0,0);
//
//    DrawLine(Bitmap.Canvas,0,0,0,imgPowerSeq.Height-1);
//    DrawLine(Bitmap.Canvas,0,imgPowerSeq.Width-1,0,0);
//    DrawLine(Bitmap.Canvas,0,imgPowerSeq.Width-1,imgPowerSeq.Height-1,imgPowerSeq.Height-1);
//    DrawLine(Bitmap.Canvas,imgPowerSeq.Width-1,imgPowerSeq.Width-1,imgPowerSeq.Height-1,0);
//
//    m_nSoffsetY  := 10;
//    m_nSstepY := 40;                     //POWER SIG 50->40
//    m_nSstartX := 20; //x start point
//    m_nSstartY := 40; //y start point
//    m_nSendX := imgPowerSeq.Width - 23;
//    m_nSendY := imgPowerSeq.Height - 10;
//    m_nSstepX1 := m_nSstartX + 100;
//    m_nSstepX2 := m_nSstepX1 + 135;
//
//    Bitmap.Canvas.Pen.Color := RGB(0,0,255);
//    DrawLine(Bitmap.Canvas,m_nSstartX,m_nSstartX,m_nSstartY-8,m_nSendY);
//    DrawLine(Bitmap.Canvas,m_nSstepX1,m_nSstepX1,m_nSstartY-8,m_nSendY);
//    DrawLine(Bitmap.Canvas,m_nSstepX2,m_nSstepX2,m_nSstartY-8,m_nSendY);
//    DrawLine(Bitmap.Canvas,m_nSendX,m_nSendX,m_nSstartY,m_nSendY);
//
//    Bitmap.Canvas.Brush.Color := clLime;
//    Bitmap.Canvas.Font.Style := [];
//    Bitmap.Canvas.Font.size := 8;
//    Bitmap.Canvas.TextOut(m_nSstartX-5,m_nSstartY-25,'Start');
//    Bitmap.Canvas.TextOut(m_nSstepX1-10,m_nSstartY-25,'50ms');
//    Bitmap.Canvas.TextOut(m_nSstepX2-15,m_nSstartY-25,'500ms');
//    Bitmap.Canvas.TextOut(m_nSendX-20,m_nSstartY-25,'5Sec');
//
//    Bitmap.Canvas.Brush.Color := $ffffdd; //clWhite;
//    Bitmap.Canvas.TextOut(m_nSstartX + 20 ,m_nSstartY-15,'step    (1ms)');
//    Bitmap.Canvas.TextOut((m_nSstepX2-m_nSstepX1) div 2 + m_nSstepX1 - 15,m_nSstartY-15,'(10ms)');
//    Bitmap.Canvas.TextOut((m_nSendX-m_nSstepX2) div 2 + m_nSstepX2 - 20,m_nSstartY-15,'(100ms)');
//
//    Bitmap.Canvas.Pen.Color := RGB(0,0,0);
//    Bitmap.Canvas.Pen.Width := 2;
//
//    for i := 1 to MAX_DELAY_CNT do DrawSeq(Bitmap, i, bType); //POWER SIG 4->6
//
//
//    imgPowerSeq.Picture.Bitmap.FreeImage;
//    imgPowerSeq.Picture.Bitmap.Assign(Bitmap);
//  Finally
//    Bitmap.Free
//  end;
//end;

//procedure TfrmModelInfo.DrawSeq(Bitmap: TBitmap; nIdx: Integer; bType: Boolean);
//begin
//  Bitmap.Canvas.MoveTo(m_nSstartX,m_nSstartY+nIdx*m_nSstepY-m_nSoffsetY);
//  Bitmap.Canvas.LineTo(m_nSstartX,m_nSstartY+nIdx*m_nSstepY-m_nSoffsetY);
//  if m_bDelay_use[nIdx-1] then begin
//    if bType then GetDelayPosition(nIdx) // draw by delay_value
//    else GetDelayValue(nIdx); // draw by delay_position
//
//    if m_nDelay_position[nIdx-1] = m_nSstartX then begin
//      Bitmap.Canvas.LineTo(m_nDelay_position[nIdx-1],m_nSstartY+m_nSstepY*(nIdx-1)+m_nSoffsetY);
//      Bitmap.Canvas.LineTo(m_nSendX+15,m_nSstartY+m_nSstepY*(nIdx-1)+m_nSoffsetY);
//    end
//    else if (m_nDelay_position[nIdx-1] > m_nSstartX) and (m_nDelay_position[nIdx-1] <= m_nSendX) then begin
//      Bitmap.Canvas.LineTo(m_nDelay_position[nIdx-1],m_nSstartY+m_nSstepY*nIdx-m_nSoffsetY);
//      Bitmap.Canvas.LineTo(m_nDelay_position[nIdx-1],m_nSstartY+m_nSstepY*(nIdx-1)+m_nSoffsetY);
//      Bitmap.Canvas.LineTo(m_nSendX+15,m_nSstartY+m_nSstepY*(nIdx-1)+m_nSoffsetY);
//    end;
//  end
//  else begin
//    Bitmap.Canvas.Pen.Style := psDot;
//    Bitmap.Canvas.LineTo(m_nSstartX,m_nSstartY+m_nSstepY*nIdx-m_nSoffsetY);
//    Bitmap.Canvas.LineTo(m_nSendX,m_nSstartY+m_nSstepY*nIdx-m_nSoffsetY);
//    Bitmap.Canvas.Pen.Style := psSolid;
//    Bitmap.Canvas.LineTo(m_nSendX+15,m_nSstartY+m_nSstepY*nIdx-m_nSoffsetY);
//  end;
//end;

procedure TfrmModelInfo.edVoltageDelayChange(Sender: TObject);
var
  nVolNo : Integer;
begin
  nVolNo := (Sender as TRzEdit).Tag; //0 ~
  m_nDelay_value[nVolNo] := StrToIntDef( (Sender as TRzEdit).Text, 0);
  if m_nDelay_value[nVolNo] > MAX_DELAY_TIME then m_nDelay_value[nVolNo] := 0; //MAX_DELAY_TYPE=5000

  (Sender as TRzEdit).Text := IntToStr(m_nDelay_value[nVolNo]);
//  DrawPowerSequence;

end;

procedure TfrmModelInfo.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmModelInfo.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
//  if PlcCtl <> nil then
//    PlcCtl.IsModelInfoMode := False;
end;

procedure TfrmModelInfo.FormCreate(Sender: TObject);
var
  i : Integer;
  sl: TStringList;
  sErrMsg, sApp,sTemp : string;
begin
  // model Information.
  g_bNewPatGr := False;
  g_bRenPatGr := False;
  g_bCopyPatGr := False;
  g_bNewModel := False;
  g_bCopyModel:= False;
  g_bRenModel := False;
  cboCa310Channel.Items.Clear;
  for i := 1 to 99 do begin
    sTemp := Format('%d',[i]);
    cboCa310Channel.Items.Add(sTemp);
  end;

//  cboCa310Channel.Items.Clear;
//  for i := 0 to 99 do cboCa310Channel.Items.Add(Format('%d',[i]));
//  cboZAxis.Items.Clear;
//  for i := 0 to 99 do cboZAxis.Items.Add(Format('%d',[i]));



  Load_data_model;
  for i := 0 to Pred(lstPGrplist.Count) do begin
    if lstModelList.Items[i] = Common.SystemInfo.TestModel then begin
      lstModelList.ItemIndex := i;
      lstModelList.OnClick(nil);
      Break;
    end;
  end;


   // pattern infomation
  // Form 항상 중앙 위치
  Self.Left := (Screen.Width - Self.Width) div 2;
  Self.Top := (Screen.Height - Self.Height) div 2;

{$IFDEF ISPD_A}
  grpVolLimit2.Visible := False;
  grpCurLimit2.Visible := False;
{$ELSE}
//
//  grpVolLimit2.Visible := True;
//  grpCurLimit2.Visible := True;

  // Power Title. (Power - voltage)

{$ENDIF}

//  grpPocbOption.Visible := True;

  // image preview set.
  imgPPreview.DongaUseSpc  := False;
  imgPPreview.DongaPatPath := Common.Path.Pattern;
  imgPPreview.DongaBmpPath := Common.Path.BMP;
  imgPPreview.DongaImgWidth := imgPPreview.Width;
  imgPPreview.DongaImgHight := imgPPreview.Height;
  imgPPreview.Stretch := True;
  imgPPreview.LoadAllPatFile;

  Load_data_pat(Common.EdModelInfoFLOW.PatGrpName);
  for i := 0 to Pred(lstPGrplist.Count) do begin
    if lstPGrplist.Items[i] = Common.EdModelInfoFLOW.PatGrpName then begin
      edPGrpName.Text := Common.EdModelInfoFLOW.PatGrpName;
      lstPGrplist.ItemIndex := i;
      lstPGrplist.OnClick(nil);
      Break;
    end;
  end;
  for i := 0 to Pred(cboPatGrpList.Items.Count) do begin
    if cboPatGrpList.Items[i] = Common.EdModelInfoFLOW.PatGrpName then begin
      cboPatGrpList.ItemIndex := i;
      Break;
    end;
  end;
  cboResolution.Items.Clear;
  sl := Common.BmpGetSectionList;
  try
    cboResolution.Items.Assign(sl);
  finally
    sl.Free;
  end;
  cboResolution.ItemIndex := 0;


end;

procedure TfrmModelInfo.FormDestroy(Sender: TObject);
var
  i : Integer;
begin
  for i := DefCommon.CH1 to DefCommon.MAX_CH do begin
    pgbDownload[i].Free;
    pgbDownload[i] := nil;
    pnlDownLoadStatus[i].Free;
    pnlDownLoadStatus[i] := nil;
  end;
end;

procedure TfrmModelInfo.FormShow(Sender: TObject);
//var
//  i : Integer;
begin
//  for i := 0 to MAX_PG_CNT-1 do begin
//    Common.RunInfo[i].ModelForm := True;
//  end;
  lstModelListClick(nil)
end;

//procedure TfrmModelInfo.GetDelayPosition(nIdx: Integer);
//begin
//  if (m_nDelay_value[nIdx-1] > 0) and (m_nDelay_value[nIdx-1] <= MAX_DELAY_TIME) then begin
//    if m_nDelay_value[nIdx-1] <= STEP1_VALUE then begin
//      m_nDelay_position[nIdx-1] := (m_nDelay_value[nIdx-1] * 2) + m_nSstartX;
//    end
//    else if m_nDelay_value[nIdx-1] <= STEP2_VALUE then begin
//      m_nDelay_position[nIdx-1] := ((m_nDelay_value[nIdx-1] - STEP1_VALUE) div 10) * 3 + m_nSstepX1;
//    end
//    else begin
//      m_nDelay_position[nIdx-1] := ((m_nDelay_value[nIdx-1] - STEP2_VALUE) div 100) * 3 + m_nSstepX2;
//    end;
//  end
//  else if m_nDelay_value[nIdx-1] = 0 then m_nDelay_position[nIdx-1] := m_nSstartX;
//end;

//procedure TfrmModelInfo.GetDelayValue(nIdx: Integer);
//begin
//  if (m_nDelay_position[nIdx-1] > m_nSstartX) and (m_nDelay_position[nIdx-1] <= m_nSendX) then begin
//    if m_nDelay_position[nIdx-1] <= m_nSstepX1 then begin
//      m_nDelay_value[nIdx-1] := (m_nDelay_position[nIdx-1] - m_nSstartX) div 2;
//    end
//    else if m_nDelay_position[nIdx-1] <= m_nSstepX2 then begin
//      m_nDelay_value[nIdx-1] := ((m_nDelay_position[nIdx-1] - m_nSstepX1) div 3) * STEP2_STEP  + STEP1_VALUE;
//    end
//    else begin
//      m_nDelay_value[nIdx-1] := ((m_nDelay_position[nIdx-1] - m_nSstepX2) div 3) * STEP3_STEP  + STEP2_VALUE;
//    end;
//  end
//  else if m_nDelay_position[nIdx-1] = m_nSstartX then m_nDelay_value[nIdx-1] := 0;
//end;

procedure TfrmModelInfo.gridPatternListClick(Sender: TObject);
var
  idx: Integer;
begin
  if gridPatternList.RowCount < 1 then
    Exit;

  idx := gridPatternList.Row;
  if AnsiCompareText(gridPatternList.Cells[0, idx], 'Pattern') = 0 then
    cboPType.ItemIndex := PTYPE_NORMAL
  else if AnsiCompareText(gridPatternList.Cells[0, idx], 'Bitmap') = 0 then
    cboPType.ItemIndex := PTYPE_BITMAP;
  cboPTypeChange(nil);
  cboPName.FindItem(gridPatternList.Cells[1, idx]);

  if (gridPatternList.Cells[2, idx] = '') or (gridPatternList.Cells[2, idx] = 'None') then begin
    edVSync.Text := 'None';
    chkVSync.Checked := False;
  end
  else begin
    edVSync.Text := gridPatternList.Cells[2, idx];
    chkVSync.Checked := True;
  end;

  if (gridPatternList.Cells[3, idx] = '') or (gridPatternList.Cells[3, idx] = '0') then begin
    edTime.Text := '0';
    chkTime.Checked := False;
  end
  else begin
    edTime.Text := gridPatternList.Cells[3, idx];
    chkTime.Checked := True;
  end;

  PatInfoBtnControl;

  imgPPreview.DrawPatAllPat(cboPType.ItemIndex, gridPatternList.Cells[1, idx]);
end;

//procedure TfrmModelInfo.imgPowerSeqMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//begin
//
//if Button = mbLeft then
//  begin
//    if CheckMouseOnLine(X, Y) then
//    begin
//      //codesite.send('MouseDown...Selected True');
//      Screen.Cursor := crSizeWE;
//      m_bSelected := True;
//      m_nDelay_old_position[m_nMpoint-1] := X - m_nDelay_position[m_nMpoint-1];
//    end
//    else begin
//      //codesite.send('MouseDown...Selected False');
//      Screen.Cursor := crDefault;
//      m_bSelected := False;
//    end;
//  end;
//end;

//procedure TfrmModelInfo.imgPowerSeqMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
//begin
//  if ssLeft in Shift then begin
//    if m_bSelected then begin
//      m_nDelay_position[m_nMpoint-1] := X - m_nDelay_old_position[m_nMpoint-1];
//
//      if m_nDelay_position[m_nMpoint-1] <= m_nSstartX then m_nDelay_position[m_nMpoint-1] := m_nSstartX
//      else if m_nDelay_position[m_nMpoint-1] >= m_nSendX then m_nDelay_position[m_nMpoint-1] := m_nSendX;
//
//      if m_nDelay_position[m_nMpoint-1] <= m_nSstepX1 then begin
//        m_nDelay_position[m_nMpoint-1] := ((m_nDelay_position[m_nMpoint-1] - m_nSstartX) div 2) * 2 + m_nSstartX;
//      end
//      else if m_nDelay_position[m_nMpoint-1] <= m_nSstepX2 then begin
//        m_nDelay_position[m_nMpoint-1] := ((m_nDelay_position[m_nMpoint-1] - m_nSstepX1) div 3) * 3  + m_nSstepX1;
//      end
//      else if m_nDelay_position[m_nMpoint-1] <= m_nSendX then begin
//        m_nDelay_position[m_nMpoint-1] := ((m_nDelay_position[m_nMpoint-1] - m_nSstepX2) div 3) * 3  + m_nSstepX2;
//      end;
//
////      DisplayVddDelayValue(m_nMpoint-1, True);
////      DrawPowerSequence(False);
//    end;
//  end else begin
//    if CheckMouseOnLine(X, Y) then begin
//      Screen.Cursor := crSizeWE;
//    end
//    else begin
//      Screen.Cursor := crDefault;
//    end;
//  end;
//end;

//procedure TfrmModelInfo.imgPowerSeqMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//begin
//  Screen.Cursor := crDefault;
//end;

procedure TfrmModelInfo.Load_data_model;
var
  nRstD : Integer;
  srD  : TSearchRec;

begin
  lstModelList.DisableAlign;
  nRstD := FindFirst(Common.Path.MODEL+ '*.*',faDirectory, srD);
  while nRstD = 0 do begin
    if not ((Trim(srD.Name) = '.') or (Trim(srD.Name) = '..') or ( (srD.Attr and faDirectory) = 0)) then begin
//      lstModelList.Items.Add(Copy(srD.Name, 1, pos('.', srD.Name) - 1));
      lstModelList.Items.Add(srD.Name);
    end;


    nRstD := FindNext(srD);
  end;
  FindClose(srD);
  lstModelList.Sorted := True;

  if lstModelList.Items.Count > 0 then begin
    AddAndFindItemToListbox(lstModelList, Common.SystemInfo.TestModel, False, True);
  end;
  lstModelList.EnableAlign;
end;

procedure TfrmModelInfo.Load_data_pat(PatName : string);
var
  Rslt: Integer;
  sPatGrName: string;
  sr: TSearchRec;
begin
  lstPGrplist.Items.Clear;
  Rslt := FindFirst(Common.Path.PATTERNGROUP + '*.grp', FaanyFile, sr);
  while Rslt = 0 do
  begin
    sPatGrName := Copy(sr.Name, 1, Length(sr.Name) - 4);
    lstPGrplist.Items.Add(sPatGrName);        // ListBox에 Pattern Group Name 추가
    Rslt := FindNext(sr);
  end;
  FindClose(sr);
  if lstPGrplist.Items.Count > 0 then begin
    AddAndFindItemToListbox(lstPGrplist, PatName, False, True);
  end;
end;

procedure TfrmModelInfo.lstModelListClick(Sender: TObject);
var
  idx, i : Integer;
  sPtGrp : string;
begin
  edModelName.ReadOnly := True;
  g_bNewModel := False;
  g_bCopyModel:= False;
  g_bRenModel := False;

  idx := lstModelList.ItemIndex;
  if idx > -1 then begin
    if Common.LoadModelInfo(lstModelList.Items.Strings[idx]) then
    begin
      edModelName.Text := lstModelList.Items.Strings[idx];
      {$IFDEF PG_DP860}
      edModelSetPgModelName.Text := edModelName.Text;
      {$ENDIF}
      pnlModelNameInfo.Caption := lstModelList.Items.Strings[idx];
      Display_Script_data(lstModelList.Items.Strings[idx]);
      Common.LoadModelInfo(lstModelList.Items.Strings[idx]);
      DisplayModelInfo(lstModelList.Items.Strings[idx]);
//      sPtGrp := Common.GetPatGroup(lstModelList.Items.Strings[idx]);
      sPtGrp := Common.EdModelInfoFLOW.PatGrpName;
      Load_data_pat(sPtGrp);
      for i := 0 to Pred(lstPGrplist.Count) do begin
        if lstPGrplist.Items[i] = sPtGrp then begin
          edPGrpName.Text := sPtGrp;
          lstPGrplist.ItemIndex := i;
          lstPGrplist.OnClick(nil);
          Break;
        end;
      end;
    end;
  end;
end;

procedure TfrmModelInfo.lstPGrplistClick(Sender: TObject);
var
  idx, i: Integer;
begin
  edPGrpName.ReadOnly := True;
  g_bNewPatGr := False;
  g_bRenPatGr := False;
  g_bCopyPatGr := False;

  idx := lstPGrplist.ItemIndex;
  if idx > -1 then
  begin
    EditPatGrp :=  Common.LoadPatGroup(lstPGrplist.Items.Strings[idx]);
//    Common.read_pattern_data(lstPGrplist.Items.Strings[idx]);
    Display_PatGroup_data(EditPatGrp);
    if gridPatternList.RowCount > 0 then gridPatternList.Row := 0;
    gridPatternList.OnClick(nil);
  end;
  cboPatGrpList.Clear;
  for i := 0 to Pred(lstPGrplist.Items.Count) do begin
    cboPatGrpList.Items.Add(lstPGrplist.Items.Strings[i]);
  end;
  for i := 0 to Pred(cboPatGrpList.Items.Count) do begin
    if cboPatGrpList.Items[i] = Common.EdModelInfoFLOW.PatGrpName then begin
      cboPatGrpList.ItemIndex := i;
      Break;
    end;
  end;


end;

procedure TfrmModelInfo.mmProgramAllDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := true;
end;

procedure TfrmModelInfo.mmProgramAllKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
//  if (Key = vkF) and (Shift = TShiftState(ssCtrl)) then AdvMemoFindDialog1.Execute;
end;

procedure TfrmModelInfo.PatInfoBtnControl;
begin
  if StrToIntDef(edPCnt.Text,0) > 0 then begin
    btnPInfoModify.Enabled := True;
    btnPInfoDel.Enabled := True;
  end
  else begin
    btnPInfoModify.Enabled := False;
    btnPInfoDel.Enabled := False;
  end;

  if gridPatternList.Row = 0 then  btnPInfoUp.Enabled := False
  else                             btnPInfoUp.Enabled := True;

  if gridPatternList.Row = gridPatternList.RowCount - 1 then  btnPInfoDown.Enabled := False
  else                                                        btnPInfoDown.Enabled := True;
end;

procedure TfrmModelInfo.RemoveDirAll(sDir: string);
var
  tmpList : TSearchRec;
begin
  try
    if FindFirst(sDir + '\*',faAnyFile,tmpList) = 0 then begin
      repeat
        if ((tmpList.attr and faDirectory) = faDirectory) and (not (tmpList.Name = '.')) and (not (tmpList.Name = '..')) then begin
          if DirectoryExists(sDir + '\' + tmpList.Name) then begin
             RemoveDirAll(sDir + '\' + tmpList.Name);
          end;
        end
        else begin
          if FileExists(sDir + '\' + tmpList.Name) then begin
             DeleteFile(sDir + '\' + tmpList.Name);
          end;
        end;
      until FindNext(tmpList) <> 0;
    end;
    if DirectoryExists(sDir) then  RemoveDir(sDir);
  finally
    FindClose(tmpList);
  end;
end;

procedure TfrmModelInfo.ReverseColorErrorLine(nIdxTab, nLine: Integer; bErrflag: Boolean);
begin
  if not bErrflag then begin
    mmProgramAll.TopLine := nLine;
    mmProgramAll.BreakPoint[nLine] := bErrflag;
  end;
end;



procedure TfrmModelInfo.RzBitBtn6Click(Sender: TObject);
begin
  if Common.m_bIsChanged then begin
    btnManualFusing_ScriptClick(Self);
    Common.Delay(50);
  end;
  Close;
end;

procedure TfrmModelInfo.btn6Click(Sender: TObject);
var
  i : Integer;
begin
  for i := 0 to Pred(lstGrpCompile.GroupCount) do begin
    lstGrpCompile.Groups[i].Expanded := True;
  end;
end;

procedure TfrmModelInfo.btn7Click(Sender: TObject);
var
  i : Integer;
begin
  for i := 0 to Pred(lstGrpCompile.GroupCount) do begin
    lstGrpCompile.Groups[i].Expanded := False;
  end;
end;

procedure TfrmModelInfo.btnSavePatGrpClick(Sender: TObject);
var
  i : Integer;
  sOldName, sNewName : String;
  SavePatGrp : TPatterGroup;
begin
  if edPGrpName.Text = '' then begin
    MessageDlg(#13#10 + 'Input Error! Please Insert the Pattern Group name.', mtError, [mbOK], 0);
    edPGrpName.ReadOnly := False;
    edPGrpName.SetFocus;
    g_bNewPatGr := True;
    Exit;
  end;

  if g_bNewPatGr or g_bRenPatGr or g_bCopyPatGr then begin
    if FileExists(Common.GetFilePath(Trim(edPGrpName.Text), PATGR_PATH)) then begin
      MessageDlg(#13#10 + 'Input Error! Pattern Group Name [' + Trim(edPGrpName.Text) + '] is already Exist!', mtError, [mbOk], 0);
      edPGrpName.SelectAll;
      edPGrpName.SetFocus;
      Exit;
    end;
    if g_bCopyPatGr then begin   // 새로운 PatGrp일 경우 List에 추가한다.
    // COPY MODEL일 경우 prg 파일도 같이 변경하도록 요구함 (BOE)
      sOldName := lstPGrplist.Items.Strings[lstPGrplist.ItemIndex];
      sNewName := Trim(edPGrpName.Text);
      // 리스트에 동일한 내용이 있으면 저장 하지 말자.
      for i := 0 to Pred(lstPGrplist.Items.Count) do begin
        if lstPGrplist.Items.Strings[i] = sNewName then begin
          MessageDlg(#13#10 + 'Input Error! Model Name [' + Trim(edPGrpName.Text) + '] is already Exist!', mtError, [mbOk], 0);
          Exit;
        end;
      end;
      if FileExists(Common.Path.PATTERNGROUP + soldName + '.grp') then
        CopyFile(PChar(Common.Path.PATTERNGROUP + soldName + '.grp'), PChar(Common.Path.PATTERNGROUP + snewName + '.grp'), False);
    end;
  end;

  if g_bRenPatGr then begin
    sOldName := lstPGrplist.Items.Strings[lstPGrplist.ItemIndex];
    sNewName := Trim(edPGrpName.Text);
    if not RenameFile(Common.GetFilePath(sOldName, PATGR_PATH), Common.GetFilePath(sNewName, PATGR_PATH)) then begin
      edPGrpName.SelectAll;
      edPGrpName.SetFocus;
      Exit;
    end;
  end;


  SavePatGrp.GroupName  := edPGrpName.Text;
  SavePatGrp.PatCount   := StrToIntDef(edPCnt.Text,0);
  if SavePatGrp.PatCount > 0 then begin
    SetLength(SavePatGrp.PatType,SavePatGrp.PatCount);
    SetLength(SavePatGrp.VSync,SavePatGrp.PatCount);
    SetLength(SavePatGrp.LockTime,SavePatGrp.PatCount);
    SetLength(SavePatGrp.Option,SavePatGrp.PatCount);
    SetLength(SavePatGrp.PatName,SavePatGrp.PatCount);
    for i := 0 to Pred(SavePatGrp.PatCount) do begin
      if gridPatternList.Cells[0, i] = 'Pattern' then SavePatGrp.PatType[i] := DefCommon.PTYPE_NORMAL
      else                                            SavePatGrp.PatType[i] := DefCommon.PTYPE_BITMAP;
      SavePatGrp.PatName[i]  := trim(gridPatternList.Cells[1, i]);
      if gridPatternList.Cells[2, i] = 'None' then  SavePatGrp.VSync[i] := 0
      else                                          SavePatGrp.VSync[i] := StrToIntDef(gridPatternList.Cells[2, i],0);
      SavePatGrp.LockTime[i] := StrToIntDef(gridPatternList.Cells[3, i],0);
    end;
  end;

  if g_bNewPatGr or g_bCopyPatGr then begin     // 새로운 Pattern Group 일 경우 List 및 ComboBox에 추가한다.
    AddAndFindItemToListbox(lstPGrplist, edPGrpName.Text, True, True);
    g_bNewPatGr := False;
  end;

  if g_bRenPatGr then begin
    lstPGrplist.Sorted := False;
    lstPGrplist.Items.Strings[lstPGrplist.ItemIndex] := sNewName;
    AddAndFindItemToListbox(lstPGrplist, sNewName, False, True);
    lstPGrplist.Sorted := True;
    g_bRenPatGr := False;
  end;
  Common.SavePatGroup(Trim(edPGrpName.Text),SavePatGrp);
  edPGrpName.ReadOnly := True;

  SaveModelInfoBuf2;
  Common.SaveModelInfo2(Trim(edModelName.Text));
  Common.m_bIsChanged := True;
  MessageDlg(#13#10 + 'Pattern Group Registration File Saving OK!', mtInformation, [mbOk], 0);
end;

procedure TfrmModelInfo.edCheckVddChange(Sender: TObject);
var
  vddNo : Integer;
begin

  if (trim((Sender as TRzComboBox).Text) = '') then Exit;
//  if StrToFloatDef((Sender as TRzComboBox).Text,-1) = -1 then Exit;


  vddNo := (Sender as TRzComboBox).Tag; //1 ~ 7

  if (StrToFloat((Sender as TRzComboBox).Text) = 0.0) then begin
    m_bDelay_use[vddNo] := False;
    m_nDelay_value[vddNo] := 0;
//    DrawPowerSequence(True);
//    DisplayVddDelayValue(vddNo, True);
  end
  else begin
    m_bDelay_use[vddNo] := True;
    m_nDelay_value[vddNo] := 0;
//    DrawPowerSequence(True);
//    DisplayVddDelayValue(vddNo, True);
  end;
  if StrToFloat((Sender as TRzComboBox).Text) > 12.0 then
    (Sender as TRzComboBox).Text := '12.00'
  else if StrToFloat((Sender as TRzComboBox).Text) < 0.0 then
    (Sender as TRzComboBox).Text := '0.00';
end;

procedure TfrmModelInfo.edModelNameKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = vkF8 then begin
//    grpModelPwrSeq.Enabled := True;
//    grpModelInfo.Enabled := True;
    grpPGrpSelection.Enabled := True;
    grpPInfo.Enabled := True;
    RzSplitter2.Enabled := True;
//    grpPocbOption.Enabled := True;
  end;
end;




function TfrmModelInfo.SaveModelInfoBuf : Boolean;
var
  bRet  : Boolean;
  nTemp : Integer;
begin
  bRet := False;

  with Common.EdModelInfoPG.PgVer do begin
    {$IFDEF PG_AF9}
    if Common.SystemInfo.PG_TYPE = DefPG.PG_TYPE_AF9 then begin
      AF9VerMCS := StrToIntDef(Trim(edPgVerAF9MCS.Text),0);
      AF9VerAPI := StrToIntDef(Trim(edPgVerAF9API.Text),0);
    end;
    {$ENDIF}
    {$IFDEF PG_DP860}
    if Common.SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
      VerAll := Trim(edPgVerAll.Text); //DP860_TBD?

      {$IFDEF DP860_TBD_XXXXX}
      HW     := Trim(edPgVerHW.Text);
      FW     := Trim(edPgVerFW.Text);
      SubFW  := Trim(edPgVerSubFW.Text);
      FPGA   := Trim(edPgVerFPGA.Text);
      PWR    := Trim(edPgVerPWR.Text);
      {$ENDIF}
    end;
    {$ENDIF}
  end;

  with Common.EdModelInfoPG.PgModelConf do begin

    {$IFDEF PG_DP860}
    if Common.SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
      // Resolution
      H_Active := StrToIntDef(Trim(edPanelResH_Active.Text),0);
      H_BP     := StrToIntDef(Trim(edPanelResH_BP.Text),0);
      H_SA     := StrToIntDef(Trim(edPanelResH_SA.Text), 0);
      H_FP     := StrToIntDef(Trim(edPanelResH_FP.Text),0);
      V_Active := StrToIntDef(Trim(edPanelResV_Active.Text),0);
      V_BP     := StrToIntDef(Trim(edPanelResV_BP.Text),0);
      V_SA     := StrToIntDef(Trim(edPanelResV_SA.Text), 0);
      V_FP     := StrToIntDef(Trim(edPanelResV_FP.Text),0);
      // Timing
  		link_rate     := StrToIntDef(Trim(edModelConfig_link_rate.Text), 0);
  		lane			    := cboModelConfig_lane.ItemIndex;
  		Vsync			    := StrToIntDef(Trim(edModelConfig_Vsync.Text), 0);
  		RGBFormat     := Trim(edModelConfig_RGBFormat.Text);
  		ALPM_Mode	    := cboModelConfig_ALPM_Mode.ItemIndex;
  		vfb_offset    := StrToIntDef(Trim(edModelConfig_vfb_offset.Text),0);
      // ALPDP
      h_fdp         := StrToIntDef(Trim(edALPDP_h_fdp.Text), 0);
      h_sdp         := StrToIntDef(Trim(edALPDP_h_sdp.Text), 0);
      h_pcnt        := StrToIntDef(Trim(edALPDP_h_pcnt.Text),0);
      vb_n5b        := StrToIntDef(Trim(edALPDP_vb_n5b.Text),0);
      vb_n7         := StrToIntDef(Trim(edALPDP_vb_n7.Text), 0);
      vb_n5a        := StrToIntDef(Trim(edALPDP_vb_n5a.Text),0);
      vb_sleep      := StrToIntDef(Trim(edALPDP_vb_sleep.Text),0);
      vb_n2         := StrToIntDef(Trim(edALPDP_vb_n2.Text), 0);
      vb_n3         := StrToIntDef(Trim(edALPDP_vb_n3.Text), 0);
      vb_n4         := StrToIntDef(Trim(edALPDP_vb_n4.Text), 0);
      m_vid         := StrToIntDef(Trim(edALPDP_m_vid.Text), 0);
      n_vid         := StrToIntDef(Trim(edALPDP_n_vid.Text), 0);
      misc_0        := StrToIntDef(Trim(edALPDP_misc_0.Text),0);
      misc_1        := StrToIntDef(Trim(edALPDP_misc_1.Text),0);
      xpol          := cboALPDP_xpol.ItemIndex;
      xdelay        := StrToIntDef(Trim(edALPDP_xdelay.Text),0);
      h_mg          := StrToIntDef(Trim(edALPDP_h_mg.Text),  0);
      NoAux_Sel     := StrToIntDef(Trim(edALPDP_NoAux_Sel.Text),   0);
      NoAux_Active  := StrToIntDef(Trim(edALPDP_NoAux_Active.Text),0);
      NoAux_Sleep   := StrToIntDef(Trim(edALPDP_NoAux_Sleep.Text), 0);
      //
      critical_section := StrToIntDef(Trim(edALPDP_critical_section.Text),0);
      tps           := StrToIntDef(Trim(edALPDP_tps.Text), 0);
      v_blank       := StrToIntDef(Trim(edALPDP_v_blank.Text), 0);
      chop_enable   := cboALPDP_chop_enable.ItemIndex;
      chop_interval := StrToIntDef(Trim(edALPDP_chop_interval.Text),0);
      chop_size     := StrToIntDef(Trim(edALPDP_chop_size.Text),    0);
    end;
    {$ENDIF}
  end;

  {$IFDEF PG_DP860}
  if Common.SystemInfo.PG_TYPE = DefPG.PG_TYPE_DP860 then begin
    with Common.EdModelInfoPG.PgPwrData do begin  //TBD:DP860? Default!!
  	  // Model Information > Voltage Setting
      PWR_VOL[DefPG.PWR_VDD1] := Round(StrToFloatDef(Trim(edVolSet_VDD1.Text),0.000)*1000); //VCC
      PWR_VOL[DefPG.PWR_VDD2] := Round(StrToFloatDef(Trim(edVolSet_VDD2.Text),0.000)*1000); //VIN
      PWR_VOL[DefPG.PWR_VDD3] := Round(StrToFloatDef(Trim(edVolSet_VDD3.Text),0.000)*1000); //VDD3
      PWR_VOL[DefPG.PWR_VDD4] := Round(StrToFloatDef(Trim(edVolSet_VDD4.Text),0.000)*1000); //VDD4
      PWR_VOL[DefPG.PWR_VDD5] := Round(StrToFloatDef(Trim(edVolSet_VDD5.Text),0.000)*1000); //VDD5
  	  // Model Information > Voltage Setting - Slope_Set
      PWR_SLOPE := StrToIntDef(Trim(edVolSet_SlopeSet.Text),0); //Slope_Set
      // Model Information > Limit Setting > Voltage
      PWR_VOL_LL[DefPG.PWR_VDD1] := Round(StrToFloatDef(Trim(edPwrLimit_VDD1_L.Text),0.000)*1000); //VCC
      PWR_VOL_HL[DefPG.PWR_VDD1] := Round(StrToFloatDef(Trim(edPwrLimit_VDD1_H.Text),0.000)*1000);
      PWR_VOL_LL[DefPG.PWR_VDD2] := Round(StrToFloatDef(Trim(edPwrLimit_VDD2_L.Text),0.000)*1000); //VIN
      PWR_VOL_HL[DefPG.PWR_VDD2] := Round(StrToFloatDef(Trim(edPwrLimit_VDD2_H.Text),0.000)*1000);
      PWR_VOL_LL[DefPG.PWR_VDD3] := Round(StrToFloatDef(Trim(edPwrLimit_VDD3_L.Text),0.000)*1000); //VDD3
      PWR_VOL_HL[DefPG.PWR_VDD3] := Round(StrToFloatDef(Trim(edPwrLimit_VDD3_H.Text),0.000)*1000);
      PWR_VOL_LL[DefPG.PWR_VDD4] := Round(StrToFloatDef(Trim(edPwrLimit_VDD4_L.Text),0.000)*1000); //VDD4
      PWR_VOL_HL[DefPG.PWR_VDD4] := Round(StrToFloatDef(Trim(edPwrLimit_VDD4_H.Text),0.000)*1000);
      PWR_VOL_LL[DefPG.PWR_VDD5] := Round(StrToFloatDef(Trim(edPwrLimit_VDD5_L.Text),0.000)*1000); //VDD5
      PWR_VOL_HL[DefPG.PWR_VDD5] := Round(StrToFloatDef(Trim(edPwrLimit_VDD5_H.Text),0.000)*1000);
      // Model Information > Limit Setting > Current
      PWR_CUR_LL[DefPG.PWR_VDD1] := StrToIntDef(Trim(edPwrLimit_IVDD1_L.Text),0); //VCC
      PWR_CUR_HL[DefPG.PWR_VDD1] := StrToIntDef(Trim(edPwrLimit_IVDD1_H.Text),0);
      PWR_CUR_LL[DefPG.PWR_VDD2] := StrToIntDef(Trim(edPwrLimit_IVDD2_L.Text),0); //VIN
      PWR_CUR_HL[DefPG.PWR_VDD2] := StrToIntDef(Trim(edPwrLimit_IVDD2_H.Text),0);
      PWR_CUR_LL[DefPG.PWR_VDD3] := StrToIntDef(Trim(edPwrLimit_IVDD3_L.Text),0); //VDD3
      PWR_CUR_HL[DefPG.PWR_VDD3] := StrToIntDef(Trim(edPwrLimit_IVDD3_H.Text),0);
      PWR_CUR_LL[DefPG.PWR_VDD4] := StrToIntDef(Trim(edPwrLimit_IVDD4_L.Text),0); //VDD4
      PWR_CUR_HL[DefPG.PWR_VDD4] := StrToIntDef(Trim(edPwrLimit_IVDD4_H.Text),0);
      PWR_CUR_LL[DefPG.PWR_VDD5] := StrToIntDef(Trim(edPwrLimit_IVDD5_L.Text),0); //VDD5
      PWR_CUR_HL[DefPG.PWR_VDD5] := StrToIntDef(Trim(edPwrLimit_IVDD5_H.Text),0);
    end;

    with Common.EdModelInfoPG.PgPwrSeq do begin
    //SeqType := cboPowerSeqType.ItemIndex; //obsoleted!!!
      //
      SeqOn[0]  := StrToIntDef(Trim(edPowerSeqOnSeq1.Text), 0);
      SeqOn[1]  := StrToIntDef(Trim(edPowerSeqOnSeq2.Text), 0);
      SeqOn[2]  := StrToIntDef(Trim(edPowerSeqOnSeq3.Text), 0);
      //
      SeqOff[0] := StrToIntDef(Trim(edPowerSeqOffSeq1.Text),0);
      SeqOff[1] := StrToIntDef(Trim(edPowerSeqOffSeq2.Text),0);
      SeqOff[2] := StrToIntDef(Trim(edPowerSeqOffSeq3.Text),0);
    end;
  end;
  {$ENDIF}

  with Common.EdModelInfoFLOW do begin
    ModelType := cboModelType.ItemIndex;
    ModelTypeName := cboModelType.Text;
    PatGrpName := Trim(cboPatGrpList.Text);
    UseDutDetect  := cbFlowOptUseDutDetect.Checked;
    SerialNoFlashInfo.nAddr := StrToIntDef(edSerialNoAddr.Text,0);
    SerialNoFlashInfo.nLength := StrToIntDef(edSerialNoLength.text,0);
    Ca410MemCh := cboCa310Channel.ItemIndex;
  end;



  // 마지막에 입력값 체크
  if not CheckInputVal then begin
    Exit(bRet);
  end;
  bRet := True;
  Result := bRet;
end;

procedure TfrmModelInfo.SaveModelInfoBuf2;
begin
  Common.EdModelInfoFLOW.PatGrpName := Trim(cboPatGrpList.Text);
end;

procedure TfrmModelInfo.tmrDisplayOffMessageTimer(Sender: TObject);
begin
  tmrDisplayOffMessage.Enabled := False;
  pnlErrorDisplay.Visible := False;
end;

procedure TfrmModelInfo.WMCopyData(var Msg: TMessage);
//var
//  nType, nPg, nMode : Integer;
//  bTemp : boolean;
//  sMsg : string;
//  i, nTotal, nCur: Integer;
begin
//  nType := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.MsgType;
//  nPg   := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Channel;
////  sMsg  := PGuiData(PCopyDataStruct(Msg.LParam)^.lpData)^.Msg;
//  case nType of
//    DefCommon.MSG_TYPE_PG : begin
//      nMode := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Mode;
//      case nMode of
//        DefCommon.MSG_MODE_TRANS_DOWNLOAD_STATUS : begin
//          nTotal  := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.Total;
//          nCur    := PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.CurPos;
//          sMsg    := string(PTranStatus(PCopyDataStruct(Msg.LParam)^.lpData)^.sMsg);
//          pnlDownLoadStatus[nPg].Caption := sMsg;
//          pgbDownload[nPg].Percent := (nCur * 100) div nTotal;
//        end;
//      end;
//
//    end;
//
//  end;
end;

end.
