// ---------------------------------------------------------------------------
// DefScript.cs
// Converted from Delphi: DefScript.pas
// Sequence IDs, data types, reference indices, limit types,
// function call strings, PG command items, and Pascal Script constants.
// ---------------------------------------------------------------------------

namespace Dongaeltek.ITOLED.Core.Definitions;

/// <summary>
/// Script definition constants used for sequence control, data types,
/// reference indices, limit types, function call identifiers,
/// PG command items, and Pascal Script communication.
/// <para>Delphi source: DefScript.pas</para>
/// </summary>
public static class DefScript
{
    #region Sequence IDs (SEQ_*)

    /// <summary>Sequence stop.</summary>
    public const int SeqStop = 0;

    /// <summary>Key start sequence.</summary>
    public const int SeqKeyStart = 1;

    /// <summary>Key stop sequence.</summary>
    public const int SeqKeyStop = 2;

    public const int SeqKey1 = 3;
    public const int SeqKey2 = 4;
    public const int SeqKey3 = 5;
    public const int SeqKey4 = 6;
    public const int SeqKey5 = 7;
    public const int SeqKey6 = 8;
    public const int SeqKey7 = 9;
    public const int SeqKey8 = 10;
    public const int SeqKey9 = 11;

    /// <summary>Key scan sequence.</summary>
    public const int SeqKeyScan = 12;

    /// <summary>Camera zone sequence.</summary>
    public const int SeqCamZone = 13;

    /// <summary>Unload zone sequence.</summary>
    public const int SeqUnloadZone = 14;

    /// <summary>Pre-stop sequence.</summary>
    public const int SeqPreStop = 15;

    /// <summary>Report sequence.</summary>
    public const int SeqReport = 16;

    public const int Seq1 = 17;
    public const int Seq2 = 18;
    public const int Seq3 = 19;
    public const int Seq4 = 20;
    public const int Seq5 = 21;
    public const int Seq6 = 22;
    public const int Seq7 = 23;
    public const int Seq8 = 24;
    public const int Seq9 = 25;

    /// <summary>Sequence finish. Delphi: SEQ_Finish</summary>
    public const int SeqFinish = 26;

    public const int SeqRestart1 = 27;
    public const int SeqRestart2 = 28;
    public const int SeqRestart3 = 29;

    // Note: 30 is intentionally skipped in the original Delphi source.

    public const int SeqMaint1 = 31;
    public const int SeqMaint2 = 32;
    public const int SeqMaint3 = 33;
    public const int SeqMaint4 = 34;
    public const int SeqMaint5 = 35;

    /// <summary>Maximum sequence ID (= SeqMaint5). Delphi: SEQ_MAX</summary>
    public const int SeqMax = SeqMaint5;

    #endregion

    #region Sequence Error Codes (SEQ_ERR_*)

    public const int SeqErrNone = 0;
    public const int SeqErrRunning = 1;

    #endregion

    #region Data Types (DATA_TYPE_*)

    /// <summary>Delphi: DAYA_NONE (original typo preserved in value).</summary>
    public const int DataNone = 0;

    /// <summary>Hexadecimal data type.</summary>
    public const int DataTypeHex = 1;

    /// <summary>Decimal data type.</summary>
    public const int DataTypeDec = 2;

    /// <summary>Real (floating-point) data type.</summary>
    public const int DataTypeReal = 3;

    /// <summary>String data type.</summary>
    public const int DataTypeStr = 6;

    #endregion

    #region Reference Indices (REF_IDX_*)

    public const int RefIdxNone = 0;
    public const int RefIdxMax = 1;
    public const int RefIdxMin = 2;
    public const int RefIdxDiff = 3;
    public const int RefIdxAvr = 4;

    /// <summary>Peak-to-peak difference. Delphi: REF_IDX_DIFF_P2P2</summary>
    public const int RefIdxDiffP2P2 = 5;

    /// <summary>Average jitter. Delphi: REF_IDX_AVR_JITER</summary>
    public const int RefIdxAvrJiter = 6;

    /// <summary>Slope row. Delphi: REF_IDX_SLOPE_ROW</summary>
    public const int RefIdxSlopeRow = 7;

    /// <summary>Slope column. Delphi: REF_IDX_SLOPE_COL</summary>
    public const int RefIdxSlopeCol = 8;

    /// <summary>Jitter delta. Delphi: REF_IDX_JIT_DELTA</summary>
    public const int RefIdxJitDelta = 9;

    /// <summary>Raw CS open. Delphi: REF_IDX_RAWCS_OPEN</summary>
    public const int RefIdxRawcsOpen = 11;

    /// <summary>Raw CS open 2. Delphi: REF_IDX_RAWCS_OPEN2</summary>
    public const int RefIdxRawcsOpen2 = 12;

    /// <summary>Get calibration. Delphi: REF_IDX_GET_CAL</summary>
    public const int RefIdxGetCal = 20;

    /// <summary>Download firmware. Delphi: REF_IDX_DOWN_FW</summary>
    public const int RefIdxDownFw = 30;

    /// <summary>ID update. Delphi: REF_IDX_ID_UPDATE</summary>
    public const int RefIdxIdUpdate = 31;

    /// <summary>Retry modify. Delphi: REF_IDX_RTY_MODIFY</summary>
    public const int RefIdxRtyModify = 300;

    #endregion

    #region Limit Types (LIMIT_TYPE_*)

    public const int LimitTypeNg = 0;
    public const int LimitTypeIs = 1;
    public const int LimitTypeIsNot = 2;
    public const int LimitTypeMin = 3;
    public const int LimitTypeMax = 4;
    public const int LimitTypeMaxMin = 5;
    public const int LimitTypeMaxMinFloat = 6;
    public const int LimitTypeMaxSubMin = 7;
    public const int LimitTypeStr = 8;
    public const int LimitTypeLog = 9;
    public const int LimitTypeFwVer = 10;

    #endregion

    #region Function Call Strings (func_call_*)

    /// <summary>Function call prefix. Delphi: FUNC_CALL_START</summary>
    public const string FuncCallStart = "Func_call::";

    /// <summary>TxIcInit (.mpt). Delphi: func_call_TxIcInit</summary>
    public const string FuncCallTxIcInit = "Func_call::TxIcInit()";

    /// <summary>Module On (.mion). Delphi: func_call_Module_on</summary>
    public const string FuncCallModuleOn = "Func_call::ModuleOn()";

    /// <summary>Module Off (.miOff). Delphi: func_call_Module_off</summary>
    public const string FuncCallModuleOff = "Func_call::ModuleOff()";

    /// <summary>Power On Full Init (.pwon). Delphi: func_call_Power_On</summary>
    public const string FuncCallPowerOn = "Func_call::PwrOn()";

    /// <summary>Power Off (.pwoff). Delphi: func_call_Power_Off</summary>
    public const string FuncCallPowerOff = "Func_call::PwrOff()";

    /// <summary>Power On Auto (.miau). Delphi: func_call_Power_On_Auto</summary>
    public const string FuncCallPowerOnAuto = "Func_call::PwrOn_Auto()";

    /// <summary>OTP Write (.otpw). Delphi: func_call_Otp_Write</summary>
    public const string FuncCallOtpWrite = "Func_call::OtpWrite()";

    /// <summary>OTP Read (.otpr). Delphi: func_call_Otp_Read</summary>
    public const string FuncCallOtpRead = "Func_call::OtpRead()";

    /// <summary>Screen Code (.misc). Delphi: func_call_ScreenCode</summary>
    public const string FuncCallScreenCode = "Func_call::ScreenCode()";

    #endregion

    #region Code IDs (CODE_*)

    public const int CodeTxIcInit = 1;
    public const int CodeModuleOn = 2;
    public const int CodeModuleOff = 3;
    public const int CodePowerOn = 4;
    public const int CodePowerOff = 5;
    public const int CodePowerOnAuto = 6;
    public const int CodeOtpWrite = 7;
    public const int CodeOtpRead = 8;
    public const int CodeScrCode = 9;

    /// <summary>Maximum code ID (= CodeScrCode). Delphi: CODE_MAX</summary>
    public const int CodeMax = CodeScrCode;

    #endregion

    #region Command Items (CMD_ITEM_*)

    public const string CmdItem1 = "delay.ms";
    public const string CmdItem2 = "mipiic.write";
    public const string CmdItem3 = "mipi.write";
    public const string CmdItem4 = "vbat.on";
    public const string CmdItem5 = "vneg.on";
    public const string CmdItem6 = "vext.on";
    public const string CmdItem7 = "vcc.on";
    public const string CmdItem8 = "vlcd.on";
    public const string CmdItem9 = "mdm.reset";
    public const string CmdItem10 = "lcm.reset";
    public const string CmdItem11 = "gpio.on";
    public const string CmdItem12 = "gpio.off";
    public const string CmdItem13 = "mdm.init";
    public const string CmdItem14 = "mipi.on";
    public const string CmdItem15 = "vbat.off";
    public const string CmdItem16 = "vneg.off";
    public const string CmdItem17 = "vext.off";
    public const string CmdItem18 = "vcc.off";
    public const string CmdItem19 = "vlcd.off";
    public const string CmdItem20 = "mipi.read";
    public const string CmdItem21 = "mipiic.read";
    public const string CmdItem22 = "vel.on";
    public const string CmdItem23 = "vel.off";
    public const string CmdItem24 = "mdm.deinit";
    public const string CmdItem25 = "vci.on";
    public const string CmdItem26 = "dvdd.on";
    public const string CmdItem27 = "vdd.on";
    public const string CmdItem28 = "vpp.on";

    /// <summary>Note: same value as CmdItem5. Delphi: CMD_ITEM_29 = 'vneg.on'</summary>
    public const string CmdItem29 = "vneg.on";

    /// <summary>Note: same value as CmdItem11. Delphi: CMD_ITEM_30 = 'gpio.on'</summary>
    public const string CmdItem30 = "gpio.on";

    /// <summary>Note: same value as CmdItem12. Delphi: CMD_ITEM_31 = 'gpio.off'</summary>
    public const string CmdItem31 = "gpio.off";

    /// <summary>Note: same value as CmdItem14. Delphi: CMD_ITEM_32 = 'mipi.on'</summary>
    public const string CmdItem32 = "mipi.on";

    public const string CmdItem33 = "vci.off";
    public const string CmdItem34 = "dvdd.off";
    public const string CmdItem35 = "vdd.off";
    public const string CmdItem36 = "vpp.off";
    public const string CmdItem37 = "mipi.off";
    public const string CmdItem38 = "touch.model";
    public const string CmdItem39 = "mipi.wpacket";
    public const string CmdItem40 = "voltage.limit";

    #endregion

    #region PG Communication - Pascal Script Signal IDs (PP_SIGID_*)

    /// <summary>Power signal. Delphi: PP_SIGID_1</summary>
    public const int PpSigIdPower = 1;

    /// <summary>Pattern display signal. Delphi: PP_SIGID_2</summary>
    public const int PpSigIdPatternDisplay = 2;

    /// <summary>Signal 3. Delphi: PP_SIGID_3</summary>
    public const int PpSigId3 = 3;

    #endregion

    #region PG Communication - Pascal Script Commands (PP_COMMAD_*)

    /// <summary>Power off command. Delphi: PP_COMMAD_PWR_OFF</summary>
    public const int PpCommandPwrOff = 0;

    /// <summary>Power on command. Delphi: PP_COMMAD_PWR_ON</summary>
    public const int PpCommandPwrOn = 1;

    /// <summary>Power on with auto-code. Delphi: PP_COMMAD_PWR_ON_AUTOCODE</summary>
    public const int PpCommandPwrOnAutoCode = 2;

    /// <summary>Power off with reset. Delphi: PP_COMMAD_PWR_OFF_RESET</summary>
    public const int PpCommandPwrOffReset = 3;

    /// <summary>Power on with reset. Delphi: PP_COMMAD_PWR_ON_RESET</summary>
    public const int PpCommandPwrOnReset = 4;

    /// <summary>Power off VSYS. Delphi: PP_COMMAD_PWR_OFF_VSYS</summary>
    public const int PpCommandPwrOffVsys = 5;

    /// <summary>Power on VSYS. Delphi: PP_COMMAD_PWR_ON_VSYS</summary>
    public const int PpCommandPwrOnVsys = 6;

    /// <summary>Power off VSYS with reset. Delphi: PP_COMMAD_PWR_OFF_VSYS_RESET</summary>
    public const int PpCommandPwrOffVsysReset = 7;

    /// <summary>Power on VSYS with reset. Delphi: PP_COMMAD_PWR_ON_VSYS_RESET</summary>
    public const int PpCommandPwrOnVsysReset = 8;

    /// <summary>Measurement off. Delphi: PP_COMMAD_MES_OFF</summary>
    public const int PpCommandMesOff = 0;

    /// <summary>Measurement on. Delphi: PP_COMMAD_MES_ON</summary>
    public const int PpCommandMesOn = 1;

    /// <summary>Pattern group. Delphi: PP_COMMAD_PAT_GRP</summary>
    public const int PpCommandPatGrp = 0;

    /// <summary>Pattern single. Delphi: PP_COMMAD_PAT_SNG</summary>
    public const int PpCommandPatSng = 1;

    #endregion

    #region Misc

    /// <summary>End-of-function marker. Delphi: end_func</summary>
    public const string EndFunc = "}_end_func";

    /// <summary>No error state. Delphi: ERR_ST_NONE</summary>
    public const int ErrStNone = 0;

    /// <summary>Semi error state. Delphi: ERR_ST_SEME</summary>
    public const int ErrStSeme = 1;

    #endregion
}
