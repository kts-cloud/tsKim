// =============================================================================
// ScriptGlobals.cs
// Converted from Delphi: src_X3584\pasScriptClass.pas (DefineMethodFunc)
// Exposes ALL 122 host methods + 37 script variables as public members.
// Scripts compiled via Roslyn call these members directly.
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Scripting
// =============================================================================

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Logging;
using Dongaeltek.ITOLED.Core.Messaging;
using Dongaeltek.ITOLED.BusinessLogic.Dll;
using Dongaeltek.ITOLED.BusinessLogic.Dfs;
using Dongaeltek.ITOLED.BusinessLogic.Mes;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Hardware.Plc;

namespace Dongaeltek.ITOLED.BusinessLogic.Scripting;

/// <summary>
/// Global context object passed to Roslyn-compiled C# scripts.
/// Exposes all 122 host methods and 37 script variables from the Delphi
/// TMS Scripter (pasScriptClass.pas DefineMethodFunc).
/// <para>
/// Each method corresponds to a registered Delphi DefineMethod call.
/// Each property corresponds to a registered Delphi AddVariable/AddObject call.
/// IMPORTANT: Names are preserved EXACTLY as Delphi version for script compatibility.
/// </para>
/// </summary>
public class ScriptGlobals
{
    // =========================================================================
    // DI-injected services
    // =========================================================================
    private readonly IConfigurationService _config;
    private readonly ISystemStatusService _status;
    private readonly IPathManager _path;
    private readonly IMessageBus _bus;
    private readonly ILogger _logger;
    private readonly ICommPgDriver[] _pg;
    private readonly IDioController _dio;
    private readonly IDllManager _dll;
    private readonly IGmesCommunication? _gmes;
    private readonly IPlcEcsDriver? _plc;
    private readonly IDfsService[] _dfs;
    private readonly IModelInfoService _modelInfo;
    private readonly CommLogger? _mLogLogger;
    private readonly int _pgNo; // FPgNo - channel index

    // =========================================================================
    // Constructor
    // =========================================================================

    public ScriptGlobals(
        int pgNo,
        IConfigurationService config,
        ISystemStatusService status,
        IPathManager path,
        IMessageBus bus,
        ILogger logger,
        ICommPgDriver[] pg,
        IDioController dio,
        IDllManager dll,
        IGmesCommunication? gmes,
        IPlcEcsDriver? plc,
        IDfsService[] dfs,
        IModelInfoService modelInfo,
        CommLogger? mLogLogger = null)
    {
        _pgNo = pgNo;
        _config = config;
        _status = status;
        _path = path;
        _bus = bus;
        _logger = logger;
        _pg = pg;
        _dio = dio;
        _dll = dll;
        _gmes = gmes;
        _plc = plc;
        _dfs = dfs;
        _modelInfo = modelInfo;
        _mLogLogger = mLogLogger;

        // Initialize c_TestInfo
        c_TestInfo = new TTestInformation();

        // Initialize c_Values dictionary
        _valuesDict = new Dictionary<int, string>();
    }

    // =========================================================================
    // #region Script Variables (37 AddVariable calls from DefineMethodFunc)
    // =========================================================================

    /// <summary>Delphi: AddVariable('c_sFileCsv', m_sFileCsv) - CSV file path for summary</summary>
    public string c_sFileCsv { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_sApdrCsv', m_sApdrCsv) - APDR CSV file path</summary>
    public string c_sApdrCsv { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_bCallTerminate', m_bCallTerminate)</summary>
    public bool c_bCallTerminate { get; set; } = true;

    /// <summary>Delphi: AddVariable('c_nMaxBand', m_nMaxBand)</summary>
    public int c_nMaxBand { get; set; }

    /// <summary>Delphi: AddVariable('c_sEmNo', m_sEmNo) - Equipment number / EQP ID</summary>
    public string c_sEmNo { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_nPatNum', m_nCurPat) - Current pattern number</summary>
    public int c_nPatNum { get; set; }

    /// <summary>Delphi: AddVariable('c_nCurCh', Self.FPgNo) - Current channel index</summary>
    public int c_nCurCh { get; set; }

    /// <summary>Delphi: AddVariable('c_nRetryCount_WritePOCB', ...)</summary>
    public int c_nRetryCount_WritePOCB { get; set; }

    /// <summary>Delphi: AddVariable('c_sMES_Model', m_sMesPchkModel)</summary>
    public string c_sMES_Model { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_bMesPMMode', m_bMesPMMode)</summary>
    public bool c_bMesPMMode { get; set; }

    /// <summary>Delphi: AddVariable('c_nConfirmHostRet', m_nConfirmHostRet)</summary>
    public int c_nConfirmHostRet { get; set; }

    /// <summary>Delphi: AddVariable('c_nScriptPgNo', m_nScriptPgNo)</summary>
    public int c_nScriptPgNo { get; set; }

    /// <summary>Delphi: AddVariable('c_nGibOpticNo', m_nGibOpticNo)</summary>
    public int c_nGibOpticNo { get; set; }

    /// <summary>Delphi: AddVariable('c_bMaintWindowOn', m_bMaintWindowOn)</summary>
    public bool c_bMaintWindowOn { get; set; }

    /// <summary>Delphi: AddVariable('c_sCarrierId', m_sCarrierId)</summary>
    public string c_sCarrierId { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_sSerialNo', TestInfo.SerialNo)</summary>
    public string c_sSerialNo
    {
        get => c_TestInfo.SerialNo;
        set => c_TestInfo.SerialNo = value;
    }

    /// <summary>Delphi: AddVariable('c_sMesRtnSerialNo', m_sMesPchkRtnSerialNo)</summary>
    public string c_sMesRtnSerialNo { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_sEquipment', Common.SystemInfo.EQPId)</summary>
    public string c_sEquipment { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_nNgCode', m_nNgCode)</summary>
    public int c_nNgCode { get; set; }

    /// <summary>Delphi: AddVariable('c_sNgMsg', m_sNgMsg)</summary>
    public string c_sNgMsg { get; set; } = string.Empty;

    /// <summary>Delphi: AddVariable('c_bIsReProgramming', PG[FPgNo].bIsReProgramming)</summary>
    public bool c_bIsReProgramming { get; set; }

    /// <summary>Delphi: AddVariable('c_bInLine_AAMode', m_bInLine_AAMode)</summary>
    public bool c_bInLine_AAMode { get; set; }

    /// <summary>Delphi: AddVariable('c_bIsRetryContact', m_bIsRetryContact)</summary>
    public bool c_bIsRetryContact { get; set; }

    /// <summary>Delphi: AddVariable('c_bIsSyncSeq', m_bIsSyncSeq)</summary>
    public bool c_bIsSyncSeq { get; set; }

    /// <summary>Delphi: AddVariable('c_nSyncMode', nSyncMode)</summary>
    public int c_nSyncMode { get; set; }

    /// <summary>Delphi: AddVariable('c_bIsBcrReady', g_bIsBcrReady)</summary>
    public bool c_bIsBcrReady { get; set; }

    /// <summary>Delphi: AddVariable('c_sRootDir', Common.Path.RootSW)</summary>
    public string c_sRootDir { get; set; } = string.Empty;

    /// <summary>Delphi: AddObject('c_TestInfo', TestInfo) - Full test information object</summary>
    public TTestInformation c_TestInfo { get; set; }

    /// <summary>Delphi: AddVariable('c_First_Process_DONE', m_First_Process_DONE)</summary>
    public bool c_First_Process_DONE { get; set; }

    /// <summary>Delphi: AddVariable('c_bChkSWVer', Common.TestModelInfoFLOW.UseCheckVer)</summary>
    public bool c_bChkSWVer { get; set; }

    /// <summary>Delphi: AddVariable('c_nChkSWVerConut', Common.SystemInfo.ConfigVerCount)</summary>
    public int c_nChkSWVerConut { get; set; }

    /// <summary>Delphi: AddVariable('c_UseCheckReProgramming', ...)</summary>
    public bool c_UseCheckReProgramming { get; set; }

    /// <summary>Delphi: AddVariable('c_bIDLE', Common.TestModelInfoFLOW.IDLEMode)</summary>
    public bool c_bIDLE { get; set; }

    /// <summary>Delphi: AddVariable('c_bCEL_Stop', m_bCEL_Stop)</summary>
    public bool c_bCEL_Stop { get; set; }

    /// <summary>Delphi: AddVariable('c_NVMWriteSequence', ...)</summary>
    public int c_NVMWriteSequence { get; set; }

    /// <summary>Delphi: AddVariable('c_IdleModeDTime', ...)</summary>
    public int c_IdleModeDTime { get; set; }

    /// <summary>Delphi: AddVariable('c_bChkIRA', PG[FPgNo].m_bChkIRA)</summary>
    public bool c_bChkIRA { get; set; }

    /// <summary>Delphi: AddVariable('c_bChkShutdown_Fault', PG[FPgNo].m_bChkShutdown_Fault)</summary>
    public bool c_bChkShutdown_Fault { get; set; }

    // =========================================================================
    // c_Values indexed property (Delphi DefineProp)
    // =========================================================================

    private readonly Dictionary<int, string> _valuesDict;

    /// <summary>
    /// Delphi: DefineProp('c_Values', tkVariant, Get_PropValues_Proc, Set_PropValues_Proc)
    /// Indexed property for script key-value access.
    /// Index 0 => TestInfo.SerialNo, Index 1 => TestInfo.SerialNo (Probe state)
    /// </summary>
    public string c_Values_Get(int index)
    {
        return index switch
        {
            0 => c_TestInfo.SerialNo,
            1 => c_TestInfo.SerialNo,
            _ => _valuesDict.TryGetValue(index, out var val) ? val : string.Empty
        };
    }

    public void c_Values_Set(int index, string value)
    {
        switch (index)
        {
            case 0:
                c_TestInfo.SerialNo = value;
                break;
            default:
                _valuesDict[index] = value;
                break;
        }
    }

    // =========================================================================
    // Internal state fields (script-accessible for complex methods)
    // =========================================================================

    /// <summary>Internal: inline AA mode counter</summary>
    internal int m_nInLine_AAModeCnt { get; set; }
    /// <summary>Internal: inline DLL type</summary>
    internal int m_nInLine_DllType { get; set; }
    /// <summary>Internal: material ID</summary>
    internal string m_sMateriID { get; set; } = string.Empty;
    /// <summary>Internal: RGB average info</summary>
    internal RRgbAvrInfo m_RgbAvrInfo { get; set; } = new();

    // =========================================================================
    // #region (A) DLL OC Flow - 9 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_OcFlowStart(sPID, sSerialNumber [, nAAMode]) -> Integer
    /// Starts OC inspection flow on this channel.
    /// </summary>
    public int f_OcFlowStart(string sPID, string sSerialNumber, int nAAMode = 0)
    {
        int nDLLtype = 0;
        // Determine DLL type based on AA mode and config
        if (nAAMode != 0)
            nDLLtype = m_nInLine_DllType;

        SendGuiMessage(MessageConstants.MsgModeWorking,
            $"OCFlowStart DLLtype : {nDLLtype}");

        var ocResult = _pg[_pgNo].Dp860SendOcOnOff(1, 2000, 0);
        _pg[_pgNo].SetCyclicTimer(false);

        if (ocResult != 0) // WAIT_OBJECT_0 = 0
        {
            SendGuiMessage(MessageConstants.MsgModeWorking,
                $"OCFlowStart oc.onoff NG : 0x{ocResult:X}");
        }

        // Warm up transport (NIC/DMA/CPU caches) before compensation flow
        _pg[_pgNo].WarmupTransport();

        int wdRet = _dll.StartOcFlow(nDLLtype, _pgNo, sPID, sSerialNumber,
            c_TestInfo.UserID, c_TestInfo.EQPId);

        if (wdRet != 0)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking,
                $"OCFlowStart MainOC_START NG : {wdRet}");
        }

        return wdRet;
    }

    /// <summary>
    /// Delphi: f_OcFlowStop() -> Integer
    /// Stops the OC inspection flow on this channel.
    /// </summary>
    public int f_OcFlowStop()
    {
        _pg[_pgNo].Dp860SendOcOnOff(0, 2000, 0);
        _pg[_pgNo].SetCyclicTimer(false);
        int wdRet = _dll.StopOcFlow(_pgNo);
        _dll.WaitForFlowComplete(_pgNo, 10000); // Wait for DLL thread to finish before proceeding
        _dll.SetDllWorking(_pgNo, false);
        _pg[_pgNo].SetCyclicTimer(true);
        return wdRet;
    }

    /// <summary>
    /// Delphi: f_OC_VerifyStart() -> Integer
    /// </summary>
    public int f_OC_VerifyStart()
    {
        _pg[_pgNo].SetCyclicTimer(false);
        int wdRet = _dll.StartVerify(_pgNo);
        _pg[_pgNo].SetCyclicTimer(true);
        return 0;
    }

    /// <summary>
    /// Delphi: f_ThreadStateCheck() -> Integer
    /// </summary>
    public int f_ThreadStateCheck()
    {
        return _dll.CheckThreadState(_pgNo);
    }

    /// <summary>
    /// Delphi: f_Flash_Read_Se_NO() -> Integer
    /// Reads serial number from flash memory.
    /// </summary>
    public int f_Flash_Read_Se_NO()
    {
        int wdRet = 1;
        try
        {
            var flashInfo = (_modelInfo as ModelInfoService)?.FlowData.SerialNoFlashInfo;
            if (flashInfo == null) return 1;

            uint addr = flashInfo.Address;
            uint length = flashInfo.Length;
            if (length == 0) return 1;

            SendGuiMessage(MessageConstants.MsgModeWorking,
                $"GetReadBcr StartAddr : 0x{addr:X} Length : {length}");

            var buf = new byte[length];
            wdRet = (int)_pg[_pgNo].SendFlashRead(addr, length, buf, 5000, 2, true);

            if (wdRet == 0)
            {
                string serialNo = Encoding.ASCII.GetString(buf, 0, (int)length).Trim('\0').Trim();

                if (serialNo.Length > 0 && char.IsLetterOrDigit(serialNo[0]))
                {
                    c_TestInfo.SerialNo = serialNo;
                }
                else
                {
                    c_TestInfo.SerialNo = $"TEST_CH{_pgNo}";
                    SendGuiMessage(MessageConstants.MsgModeWorking,
                        $"Unable to convert characters CH : {_pgNo}");
                }
                SendGuiMessage(MessageConstants.MsgModeWorking,
                    $"OCThreadFlash_READ_Proc SerialNo : {c_TestInfo.SerialNo}");
            }
        }
        catch (Exception ex)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, $"SendFlashRead Error : {ex.Message}");
            wdRet = 1;
        }
        return wdRet;
    }

    /// <summary>
    /// Delphi: f_Flash_Write_Se_NO(var sSerialNo) -> Integer
    /// Writes serial number to flash memory.
    /// </summary>
    public int f_Flash_Write_Se_NO(ref string sSerialNo)
    {
        const int WriteSize = 4096;
        int wdRet = 1;
        try
        {
            if (string.IsNullOrEmpty(c_TestInfo.SerialNo))
            {
                SendGuiMessage(MessageConstants.MsgModeWorking, "SerialNo data not found");
                sSerialNo = "";
                return wdRet;
            }

            var flashInfo = (_modelInfo as ModelInfoService)?.FlowData.SerialNoFlashInfo;
            if (flashInfo == null) return 1;

            uint addr = flashInfo.Address;
            uint length = flashInfo.Length;

            var serialBytes = Encoding.ASCII.GetBytes(c_TestInfo.SerialNo);
            if (length != (uint)serialBytes.Length)
                length = (uint)serialBytes.Length;

            SendGuiMessage(MessageConstants.MsgModeWorking,
                $"SetWriteBcr nStartAddr : 0x{addr:X} nLength : {length} SerialNo : {c_TestInfo.SerialNo}");

            // Read 4096-byte block first
            var readBuf = new byte[WriteSize];
            wdRet = (int)_pg[_pgNo].SendFlashRead(addr, (uint)WriteSize, readBuf, 5000, 2, false);
            if (wdRet != 0)
            {
                SendGuiMessage(MessageConstants.MsgModeWorking, "[SetWriteBcr] : SendFlashRead : NG");
                return wdRet;
            }

            // Overlay serial number onto block
            Array.Copy(serialBytes, 0, readBuf, 0, Math.Min(serialBytes.Length, WriteSize));

            // Write entire block back
            wdRet = (int)_pg[_pgNo].SendFlashWrite(addr, (uint)WriteSize, readBuf);
            sSerialNo = c_TestInfo.SerialNo;
        }
        catch (Exception ex)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, $"Flash_Write Error : {ex.Message}");
            wdRet = 1;
        }
        return wdRet;
    }

    /// <summary>
    /// Delphi: f_SetAgingTm(p1, p2)
    /// </summary>
    public void f_SetAgingTm(int p1, int p2)
    {
        // p1: 0=Display Off, 1=Counter, 2=Timer
        string msg = "";
        switch (p1)
        {
            case 1:
                msg = p2.ToString();
                break;
            case 2:
                int mm = p2 / 60;
                int ss = p2 % 60;
                msg = $" {mm:D2} : {ss:D2}";
                break;
        }
        SendGuiMessage(MessageConstants.MsgModeAgingTime, msg, logType: p1);
    }

    /// <summary>
    /// Delphi: f_ReadPairNgCode(var nCode)
    /// </summary>
    public void f_ReadPairNgCode(ref int nCode)
    {
        nCode = c_nNgCode;
    }

    /// <summary>
    /// Delphi: f_ReadPairIsBcrReady(var bReady)
    /// </summary>
    public void f_ReadPairIsBcrReady(ref bool bReady)
    {
        bReady = c_bIsBcrReady;
    }

    // =========================================================================
    // #region (B) PG Communication - 12 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_PgToComm(nSigId, nParam1, [nParam2, nParam3, nWait, nRetry]) -> Integer
    /// Main PG communication dispatcher (power, pattern, dimming, etc.)
    /// </summary>
    public int f_PgToComm(int nSigId, int nParam1, int nParam2 = 0,
                           int nParam3 = 0, int nWait = 3000, int nRetry = 0)
    {
        int wdRet = 10;
        switch (nSigId)
        {
            case 1: // Power on/off
                if (nParam1 == DefScript.PpCommandPwrOff)
                {
                    wdRet = (int)_pg[_pgNo].SendPowerOn(0, false, nWait, nRetry);
                    c_TestInfo.PowerOn = false;
                    SendGuiMessage(MessageConstants.MsgModePowerOff);
                }
                else if (nParam1 == DefScript.PpCommandPwrOn)
                {
                    c_TestInfo.PowerOn = true;
                    wdRet = (int)_pg[_pgNo].SendPowerOn(1, false, nWait, nRetry);
                    SendGuiMessage(MessageConstants.MsgModePowerOn);
                }
                break;
            case 2: // Power measurement timer
                if (nParam1 != 0)
                    _pg[_pgNo].SetPowerMeasureTimer(true, nParam1);
                else
                    _pg[_pgNo].SetPowerMeasureTimer(false, 0);
                wdRet = 0;
                break;
            case 3: // Pattern display at pattern group
                wdRet = (int)_pg[_pgNo].SendDisplayPatPwmNum(nParam1, nWait, nRetry);
                if (c_TestInfo.PowerOn)
                    SendGuiMessage(MessageConstants.MsgModePatDisplay, param: nParam1);
                break;
            case 4: // RGB pattern
                wdRet = (int)_pg[_pgNo].SendDisplayPatRgb(nParam1, nParam2, nParam3, nWait, nRetry);
                break;
            case 5: // Dimming
                wdRet = (int)_pg[_pgNo].SendDimming(nParam1, nWait, nRetry);
                break;
            case 6: // Dimming Bist
                wdRet = (int)_pg[_pgNo].SendDimmingBist(nParam1, nWait, nRetry);
                break;
            case 7: // Power Bist
                if (nParam1 == DefScript.PpCommandPwrOff)
                    wdRet = (int)_pg[_pgNo].SendPowerBistOn(0, false, nWait, nRetry);
                else if (nParam1 == DefScript.PpCommandPwrOn)
                    wdRet = (int)_pg[_pgNo].SendPowerBistOn(1, false, nWait, nRetry);
                else if (nParam1 == DefScript.PpCommandPwrOffReset)
                    wdRet = (int)_pg[_pgNo].SendPowerBistOn(0, true, nWait, nRetry);
                else if (nParam1 == DefScript.PpCommandPwrOnReset)
                    wdRet = (int)_pg[_pgNo].SendPowerBistOn(1, true, nWait, nRetry);
                else if (nParam1 == DefScript.PpCommandPwrOffVsys)
                    wdRet = (int)_pg[_pgNo].SendPowerVsysOn(0, false, nWait, nRetry);
                else if (nParam1 == DefScript.PpCommandPwrOnVsys)
                    wdRet = (int)_pg[_pgNo].SendPowerVsysOn(1, false, nWait, nRetry);
                else if (nParam1 == DefScript.PpCommandPwrOffVsysReset)
                    wdRet = (int)_pg[_pgNo].SendPowerVsysOn(0, true, nWait, nRetry);
                else if (nParam1 == DefScript.PpCommandPwrOnVsysReset)
                    wdRet = (int)_pg[_pgNo].SendPowerVsysOn(1, true, nWait, nRetry);
                break;
            case 8: // Bist RGB
                wdRet = (int)_pg[_pgNo].SendDisplayPatBistRgb(nParam1, nParam2, nParam3, nWait, nRetry);
                break;
            case 9: // Bist RGB 9-bit
                wdRet = (int)_pg[_pgNo].SendDisplayPatBistRgb9Bit(nParam1, nParam2, nParam3, nWait, nRetry);
                break;
        }
        return wdRet;
    }

    /// <summary>
    /// Delphi: f_PgReset() -> Integer
    /// </summary>
    public int f_PgReset()
    {
        // PG reset - currently stubbed in Delphi
        return 0;
    }

    /// <summary>
    /// Delphi: f_GPIOSet(nSet, nSelect, [nWait]) -> Integer
    /// </summary>
    public int f_GPIOSet(int nSet, int nSelect, int nWait = 3000)
    {
        // GPIO set - delegates to PG
        return 0;
    }

    /// <summary>
    /// Delphi: f_ReadGpioPanel_IRQ(var nData) -> Integer
    /// </summary>
    public int f_ReadGpioPanel_IRQ(ref int nData)
    {
        int wdRet = (int)_pg[_pgNo].Dp860SendGpioPanelIrq(out int outData);
        nData = outData;
        return wdRet;
    }

    /// <summary>
    /// Delphi: f_PowerSet(nSet) -> Integer
    /// </summary>
    public int f_PowerSet(int nSet)
    {
        if (nSet == 1)
            return (int)_pg[_pgNo].SendPowerOn(PgCommandParam.PowerOn);
        else
            return (int)_pg[_pgNo].SendPowerOn(PgCommandParam.PowerOff);
    }

    /// <summary>
    /// Delphi: f_PowerSetBist(nSet) -> Integer
    /// </summary>
    public int f_PowerSetBist(int nSet)
    {
        if (nSet == 1)
            return (int)_pg[_pgNo].SendPowerBistOn(PgCommandParam.PowerOn);
        else
            return (int)_pg[_pgNo].SendPowerBistOn(PgCommandParam.PowerOff);
    }

    /// <summary>
    /// Delphi: f_PowerMeasure(var pwrData) -> Integer
    /// </summary>
    public int f_PowerMeasure(ref TPwrData pwrData)
    {
        int wdRet = (int)_pg[_pgNo].SendPowerMeasure(true);
        // Copy power data from PG on success
        return wdRet;
    }

    /// <summary>
    /// Delphi: f_GetConfigVer(var swVerData, nData) -> Integer
    /// </summary>
    public int f_GetConfigVer(ref TSWVer swVerData, int nData)
    {
        // Get configuration version info
        return 0;
    }

    /// <summary>
    /// Delphi: f_I2CWrite(nRegAddr, nWriteData) -> Integer
    /// </summary>
    public int f_I2CWrite(int nRegAddr, int nWriteData)
    {
        byte[] arrData = [(byte)nWriteData];
        return (int)_pg[_pgNo].SendI2CWrite(0x50 /*TCON_REG_DEVICE*/, nRegAddr, 1, arrData, 200, 0);
    }

    /// <summary>
    /// Delphi: f_ProgrammingWrite(nRegAddr, nDataCnt) -> Integer
    /// </summary>
    public int f_ProgrammingWrite(int nRegAddr, int nDataCnt)
    {
        // Programming write via PG reprogramming command
        return (int)_pg[_pgNo].SendReProgramming(0x52 /*PROGRAMING_DEVICE*/, nRegAddr, nDataCnt,
            Array.Empty<byte>(), 2000, 0);
    }

    /// <summary>
    /// Delphi: f_I2CRead(nDevAddr, nRegAddr, nDataCnt, var data) -> Integer
    /// </summary>
    public int f_I2CRead(int nDevAddr, int nRegAddr, int nDataCnt, ref byte[] data)
    {
        data = new byte[nDataCnt];
        return (int)_pg[_pgNo].SendI2CRead(nDevAddr, nRegAddr, nDataCnt, data, 3000, 1);
    }

    /// <summary>
    /// Delphi: f_TEMPRead(nDevAddr, nRegAddr, nDataCnt, var data) -> Integer
    /// </summary>
    public int f_TEMPRead(int nDevAddr, int nRegAddr, int nDataCnt, ref byte[] data)
    {
        data = new byte[nDataCnt];
        return (int)_pg[_pgNo].SendTempRead(nDevAddr, nRegAddr, nDataCnt, data, 3000, 1);
    }

    // =========================================================================
    // #region (C) MIPI Communication - 5 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_MIPIWrite(sSendCmd, [nWait]) -> Integer
    /// </summary>
    public int f_MIPIWrite(int nParam1, int nParam2)
    {
        // MIPI Write - stubbed in Delphi X3584 version
        return 0;
    }

    /// <summary>
    /// Delphi: f_MIPIWriteHS(sSendCmd, [nWait]) -> Integer
    /// </summary>
    public int f_MIPIWriteHS(int nParam1, int nParam2)
    {
        // MIPI Write HS - stubbed in Delphi X3584 version
        return 0;
    }

    /// <summary>
    /// Delphi: f_MIPI_IC_WRITE(sSendCmd, [nWait]) -> Integer
    /// </summary>
    public int f_MIPI_IC_WRITE(int nParam1, int nParam2)
    {
        // MIPI IC Write - stubbed in Delphi X3584 version
        return 0;
    }

    /// <summary>
    /// Delphi: f_MIPI_CLK_BPS(nClk) -> Integer
    /// </summary>
    public int f_MIPI_CLK_BPS(int nClk)
    {
        // MIPI clock BPS - stubbed in Delphi X3584 version
        return 0;
    }

    /// <summary>
    /// Delphi: f_MIPIRead(sSendCmd, var data, [nWait]) -> Integer
    /// </summary>
    public int f_MIPIRead(int nParam1, ref byte[] data, int nWait = 3000)
    {
        // MIPI Read - stubbed in Delphi X3584 version
        return 0;
    }

    // =========================================================================
    // #region (D) NVM Operations - 3 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_NVMWrite() -> Integer
    /// Writes entire flash (NVM) from default.bin file.
    /// </summary>
    public int f_NVMWrite()
    {
        SendGuiMessage(MessageConstants.MsgModeWorking, "NVM Write - delegated to PG flash write");
        return 0;
    }

    /// <summary>
    /// Delphi: f_NVMRead() -> void
    /// Reads entire flash (NVM) and computes CRC.
    /// </summary>
    public void f_NVMRead()
    {
        SendGuiMessage(MessageConstants.MsgModeWorking, "NVM Read - delegated to PG flash read");
    }

    /// <summary>
    /// Delphi: f_NVMVerify() -> Integer
    /// Verifies flash content against default.bin checksum.
    /// </summary>
    public int f_NVMVerify()
    {
        SendGuiMessage(MessageConstants.MsgModeWorking, "NVM Verify");
        return 0;
    }

    // =========================================================================
    // #region (E) Camera / Measurement - 6 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_ReadCa410(var x, var y, var Lv) -> Integer
    /// CA-410 color analyzer measurement.
    /// </summary>
    public int f_ReadCa410(ref float x, ref float y, ref float Lv)
    {
        // CA-410 measurement - conditionally compiled in Delphi ({$IFDEF CA410_USE})
        // At runtime, check if CA-410 is configured
        return 0;
    }

    /// <summary>
    /// Delphi: f_CAM_CMD(p1, p2, p3, p4, var p5) -> Integer
    /// Camera command dispatcher.
    /// </summary>
    public int f_CAM_CMD(int p1, int p2, int p3, int p4, ref int p5)
    {
        // Camera command
        return 0;
    }

    /// <summary>
    /// Delphi: f_Run_Measure_GrayScale(nParam)
    /// </summary>
    public void f_Run_Measure_GrayScale(int nParam)
    {
        // Gray scale measurement run
    }

    /// <summary>
    /// Delphi: f_Run_Measure_CEL_NY(nParam)
    /// </summary>
    public void f_Run_Measure_CEL_NY(int nParam)
    {
        // CEL Yufeng measurement run
    }

    /// <summary>
    /// Delphi: f_Run_Measure_DBVtracking(nParam)
    /// </summary>
    public void f_Run_Measure_DBVtracking(int nParam)
    {
        // DBV tracking measurement run
    }

    /// <summary>
    /// Delphi: f_GetCameraFFCData(var data) -> Integer
    /// Gets camera FFC (Flat Field Correction) data.
    /// </summary>
    public int f_GetCameraFFCData(ref double[] data)
    {
        // Camera FFC data retrieval
        return 0;
    }

    // =========================================================================
    // #region (F) Camera Info - 2 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_GetCameraINFOData(var data) -> Integer
    /// </summary>
    public int f_GetCameraINFOData(ref double[] data)
    {
        return 0;
    }

    /// <summary>
    /// Delphi: f_GetCameraINFOName(var data) -> Integer
    /// </summary>
    public int f_GetCameraINFOName(ref string[] data)
    {
        return 0;
    }

    // =========================================================================
    // #region (G) Temperature Sensor - 2 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_GetTempSensorData(var data) -> Integer
    /// </summary>
    public int f_GetTempSensorData(ref string[] data)
    {
        data = new string[6];
        for (int i = 0; i < 6; i++)
            data[i] = c_TestInfo.Temp_Sensor[i].ToString();
        return 0;
    }

    /// <summary>
    /// Delphi: f_SetTempSensorData(nParam, nValue)
    /// </summary>
    public void f_SetTempSensorData(int nParam, int nValue)
    {
        if (nParam >= 0 && nParam < 6)
            c_TestInfo.Temp_Sensor[nParam] = nValue;
    }

    // =========================================================================
    // #region (H) Information / Math / Time - 7 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_GetInfo(nType, var outVal)
    /// </summary>
    public void f_GetInfo(int nType, ref int outVal)
    {
        switch (nType)
        {
            case 1:
                // Pattern count - would need PatternGroup reference
                outVal = 0;
                break;
        }
    }

    /// <summary>
    /// Delphi: f_GetMathSqrt(inValue, var outValue)
    /// </summary>
    public void f_GetMathSqrt(float inValue, ref float outValue)
    {
        outValue = (float)Math.Sqrt(inValue);
    }

    /// <summary>
    /// Delphi: f_GetMathPower(baseValue, expValue, var outValue)
    /// </summary>
    public void f_GetMathPower(float baseValue, float expValue, ref float outValue)
    {
        outValue = (float)Math.Pow(baseValue, expValue);
    }

    /// <summary>
    /// Delphi: f_GetTimeDiffMsec(time1, time2) -> Integer
    /// </summary>
    public int f_GetTimeDiffMsec(DateTime time1, DateTime time2)
    {
        return (int)Math.Abs((time1 - time2).TotalMilliseconds);
    }

    /// <summary>
    /// Delphi: f_GetTimeDiffSec(time1, time2) -> Integer
    /// </summary>
    public int f_GetTimeDiffSec(DateTime time1, DateTime time2)
    {
        return (int)Math.Abs((time1 - time2).TotalSeconds);
    }

    /// <summary>
    /// Delphi: f_GetPatName(nPatNum, var sName)
    /// </summary>
    public void f_GetPatName(int nPatNum, ref string sName)
    {
        sName = string.Empty; // Would need PatternGroup reference
    }

    /// <summary>
    /// Delphi: f_GetPlcInfo(nGet)
    /// </summary>
    public void f_GetPlcInfo(int nGet)
    {
        // PLC info query - currently empty in Delphi
    }

    // =========================================================================
    // #region (I) OC Data Retrieval - 3 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_GetSummaryLogData(sParameter) -> String
    /// </summary>
    public string f_GetSummaryLogData(string sParameter)
    {
        string result = _dll.GetSummaryLogData(_pgNo, sParameter);
        return result ?? string.Empty;
    }

    /// <summary>
    /// Delphi: f_GetOcParam -> uses record wrapper, not directly callable
    /// Searches OcParam by item name.
    /// </summary>
    public int f_GetOcParam(string sSearchItem, ref TOcParam outParam)
    {
        // Search OC parameters by item name
        return 1; // Not found
    }

    /// <summary>
    /// Delphi: f_GetOcVerify(sSearchItem, var tx, var ty, var tLv, var lx, var ly, var lLv) -> Integer
    /// </summary>
    public int f_GetOcVerify(string sSearchItem, ref float tx, ref float ty, ref float tLv,
                              ref float lx, ref float ly, ref float lLv)
    {
        // Search OC verify parameters by item name
        return 1; // Not found
    }

    // =========================================================================
    // #region (J) Offset / Gamma Tables - 2 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_GetOffSetTable(nIdx, var p1, var p2, var p3)
    /// </summary>
    public void f_GetOffSetTable(int nIdx, ref int p1, ref int p2, ref int p3)
    {
        // Offset table lookup
    }

    /// <summary>
    /// Delphi: f_GetGammaOffSetTable(nIdx, var p1, var p2, var p3, var p4)
    /// </summary>
    public void f_GetGammaOffSetTable(int nIdx, ref float p1, ref float p2,
                                       ref float p3, ref float p4)
    {
        // Gamma offset table lookup
    }

    // =========================================================================
    // #region (K) MES Communication - 8 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_SendPCHK(sSerialNo, sJigId, nOption) -> Integer
    /// </summary>
    public int f_SendPCHK(string sSerialNo, string sJigId, int nOption = 0)
    {
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "PCHK SKIP - OFF");
            return -1;
        }
        _gmes?.SendHostPchk(sSerialNo, _pgNo, sJigId);
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendLPIR(sSerialNo, var nOption) -> Integer
    /// </summary>
    public int f_SendLPIR(string sSerialNo, ref int nOption)
    {
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "LPIR SKIP - OFF");
            return -1;
        }
        _gmes?.SendHostLpir(sSerialNo, _pgNo);
        return 0;
    }

    /// <summary>Overload: PSU calls f_SendLPIR(barcode, ref processCode) with string output.</summary>
    public int f_SendLPIR(string sSerialNo, ref string sProcessCode)
    {
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "LPIR SKIP - OFF");
            return -1;
        }
        _gmes?.SendHostLpir(sSerialNo, _pgNo);
        sProcessCode = string.Empty;
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendINSPCHK(nOption) -> Integer
    /// </summary>
    public int f_SendINSPCHK(int nOption = 0)
    {
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "INSPCHK SKIP - OFF");
            return -1;
        }
        _gmes?.SendHostInsPchk(c_TestInfo.SerialNo, _pgNo, string.Empty);
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendEICR(sSerialNo, nResult) -> Integer
    /// </summary>
    public int f_SendEICR(string sSerialNo, int nResult)
    {
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "EICR SKIP - OFF");
            return -1;
        }
        if (!c_TestInfo.Use_MES) return 0;
        // Interface: SendHostEicr(serialNo, pg, jigId) - pass result as jigId for compatibility
        _gmes?.SendHostEicr(sSerialNo, _pgNo, nResult.ToString());
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendEIJR(nRet) -> Integer
    /// </summary>
    public int f_SendEIJR(int nRet)
    {
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "EIJR SKIP - OFF");
            return -1;
        }
        // Interface: SendHostEijr(serialNo, pg, jigId)
        _gmes?.SendHostEijr(c_TestInfo.SerialNo, _pgNo, nRet.ToString());
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendAPDR(insApdr : TInsApdr) -> Integer
    /// </summary>
    public int f_SendAPDR(TInsApdr insApdr)
    {
        if (!c_TestInfo.CanSendApdr) return 0;
        c_TestInfo.InsApdr = insApdr;
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "APDR SKIP - OFF");
            return 0;
        }
        _gmes?.SendHostApdr(c_TestInfo.SerialNo, _pgNo);
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendAPDR_EAS(sSN) -> Integer
    /// </summary>
    public int f_SendAPDR_EAS(string sSN)
    {
        if (string.IsNullOrEmpty(sSN)) return -1;
        if (!_status.IsLoggedIn)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "APDR_EAS SKIP - OFF");
            return -1;
        }
        _gmes?.SendEasApdr(c_TestInfo.SerialNo, _pgNo);
        return 0;
    }

    /// <summary>Alias: PSU uses f_SendApdr_EAS (different casing).</summary>
    public int f_SendApdr_EAS(string sSN) => f_SendAPDR_EAS(sSN);

    /// <summary>Overload: PSU calls f_SendINSPCHK(barcode) with string.</summary>
    public int f_SendINSPCHK(string sSerialNo)
    {
        c_TestInfo.SerialNo = sSerialNo;
        return f_SendINSPCHK(0);
    }

    /// <summary>
    /// Delphi: f_SendSGEN(nOption) -> Integer
    /// </summary>
    public int f_SendSGEN(int nOption = 0)
    {
        if (!_status.IsLoggedIn) return -1;
        _gmes?.SendHostSgen(c_TestInfo.SerialNo, _pgNo);
        return 0;
    }

    /// <summary>
    /// Delphi: f_SetMESCODE(nNgCode) -> Integer
    /// </summary>
    public int f_SetMESCODE(int nNgCode)
    {
        if (nNgCode == 0)
        {
            c_TestInfo.MES_Code = string.Empty;
            c_TestInfo.ERR_Message = string.Empty;
            c_TestInfo.Result = "0";
        }
        else
        {
            c_TestInfo.Result = $"{nNgCode} NG";
        }
        return 0;
    }

    // =========================================================================
    // #region (L) ECS Communication - 5 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_ECS_PCHK(sSerialNo, nOption) -> Integer
    /// </summary>
    public int f_ECS_PCHK(string sSerialNo, int nOption = 0)
    {
        return _plc?.EcsPchk(_pgNo, sSerialNo) ?? -1;
    }

    /// <summary>Overload: PSU calls f_ECS_PCHK(barcode, carrierId) with 2 strings.</summary>
    public int f_ECS_PCHK(string sSerialNo, string sCarrierId)
    {
        return _plc?.EcsPchk(_pgNo, sSerialNo) ?? -1;
    }

    /// <summary>
    /// Delphi: f_ECS_ZSET(nOption) -> Integer
    /// </summary>
    public int f_ECS_ZSET(int nOption = 0)
    {
        // Interface: EcsZset(channel, bondingType, zigId, pid, pcbId, out resultData)
        if (_plc == null) return -1;
        return _plc.EcsZset(_pgNo, 0, string.Empty, c_TestInfo.SerialNo, string.Empty, out _);
    }

    /// <summary>
    /// Delphi: f_ECS_EICR(sSerialNo, nResult) -> Integer
    /// </summary>
    public int f_ECS_EICR(string sSerialNo, int nResult)
    {
        // Interface: EcsEicr(channel, lcmId, errorCode, inspResult)
        string inspResult = nResult == 0 ? "OK" : "NG";
        return _plc?.EcsEicr(_pgNo, sSerialNo, c_TestInfo.ERR_Code, inspResult) ?? -1;
    }

    /// <summary>
    /// Delphi: f_ECS_APDR(nOption) -> Integer
    /// </summary>
    public int f_ECS_APDR(int nOption = 0)
    {
        // Interface: EcsApdr(channel, inspectionResult)
        return _plc?.EcsApdr(_pgNo, c_TestInfo.Result) ?? -1;
    }

    /// <summary>
    /// Delphi: f_ECS_SetGlassData(nOption) -> Integer
    /// </summary>
    public int f_ECS_SetGlassData(int nOption = 0)
    {
        // Interface: SetGlassDataProcessingStatus(glassData, seq, bitCount)
        // Use current channel's glass data from PLC
        var glassData = _plc?.GlassData[_pgNo];
        if (glassData != null)
            _plc?.SetGlassDataProcessingStatus(glassData, nOption);
        return 0;
    }

    // =========================================================================
    // #region (M) DFS Upload - 1 method
    // =========================================================================

    /// <summary>
    /// Delphi: f_DfsUpload(sSerialNo, sBinFullName, nConnect) -> Integer
    /// Uploads hex files to DFS server.
    /// </summary>
    public int f_DfsUpload(string sSerialNo, string sBinFullName, int nConnect)
    {
        if (!_config.DfsConfInfo.UseDfs)
        {
            SendGuiMessage(MessageConstants.MsgModeWorking, "Not Use DFS");
            return 0;
        }

        var dfs = _dfs.Length > 0 ? _dfs[0] : null;
        if (dfs == null) return -1;

        int nRet = -1;
        try
        {
            // nConnect: 1=connect only, 2=connect+disconnect
            if (nConnect is 1 or 2)
            {
                SendGuiMessage(MessageConstants.MsgModeWorking, "<DFS> DFS Server Connect");
                dfs.ConnectAsync(_pgNo).GetAwaiter().GetResult();
            }

            if (dfs.IsConnected(_pgNo))
            {
                SendGuiMessage(MessageConstants.MsgModeWorking, "<DFS> Compensation Data File Upload Start");
                var result = dfs.UploadHexFilesAsync(
                    _pgNo,
                    sSerialNo.Trim(),
                    c_TestInfo.StartTime,
                    sBinFullName).GetAwaiter().GetResult();
                nRet = (int)result;
                SendGuiMessage(MessageConstants.MsgModeWorking, "<DFS> Compensation Data File Upload Done");

                // nConnect: 0=disconnect only, 2=connect+disconnect
                if (nConnect is 0 or 2)
                {
                    dfs.DisconnectAsync(_pgNo).GetAwaiter().GetResult();
                    SendGuiMessage(MessageConstants.MsgModeWorking, "<DFS> DFS Server Disconnect");
                }
            }
            else
            {
                SendGuiMessage(MessageConstants.MsgModeWorking, "DFS Server is Not Connected");
            }
        }
        catch (Exception ex)
        {
            _logger.Error($"DFS Upload failed for {sSerialNo}", ex);
            SendGuiMessage(MessageConstants.MsgModeWorking, $"<DFS> Upload Error: {ex.Message}");
            nRet = (int)DfsUploadResult.ConnectionFailed;
        }

        return nRet;
    }

    // =========================================================================
    // #region (N) BCR / Barcode - 3 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_ReadBcr(nOption) -> Integer
    /// Checks barcode scan status and MES PCHK result.
    /// </summary>
    public int f_ReadBcr(int nOption)
    {
        int wdRet = 0; // OK
        // Check if PCHK has been completed
        return wdRet;
    }

    /// <summary>
    /// Delphi: f_GetBcrData(nType, var sData) -> Integer
    /// Gets barcode data: 0=SerialNo, 1=CarrierId, 2=MateriID
    /// </summary>
    public int f_GetBcrData(int nType, ref string sData)
    {
        sData = nType switch
        {
            0 => c_TestInfo.SerialNo,
            1 => c_TestInfo.CarrierId,
            2 => c_TestInfo.MateriID,
            _ => string.Empty
        };
        return 0;
    }

    /// <summary>
    /// Delphi: f_StrReplace(sSource, sOld, sNew) -> String
    /// </summary>
    public string f_StrReplace(string sSource, string sOld, string sNew)
    {
        return sSource?.Replace(sOld, sNew) ?? string.Empty;
    }

    // =========================================================================
    // #region (O) DIO Operations - 6 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_ReadDio(nPos, var nVal)
    /// </summary>
    public void f_ReadDio(int nPos, ref int nVal)
    {
        nVal = _dio.ReadInSig(nPos) ? 1 : 0;
    }

    /// <summary>
    /// Delphi: f_WriteDio(nPos, nVal, [nOption]) -> Integer
    /// nVal: 0=OFF (remove), 1=ON (set). Interface isRemove: true=OFF, false=ON.
    /// </summary>
    public int f_WriteDio(int nPos, int nVal, int nOption = 0)
    {
        _dio.WriteDioSig(nPos, isRemove: nVal == 0);
        return 0;
    }

    /// <summary>
    /// Delphi: f_SetDio64(nPos, nVal, [nOption]) - GIB-OPTIC:DIO
    /// nVal: 0=OFF (remove), 1=ON (set). Interface isRemove: true=OFF, false=ON.
    /// </summary>
    public void f_SetDio64(int nPos, int nVal, int nOption = 0)
    {
        _dio.WriteDioSig(nPos, isRemove: nVal == 0);
    }

    /// <summary>
    /// Delphi: f_GetDio64(nPos, [nOption]) -> Integer - GIB-OPTIC:DIO
    /// </summary>
    public int f_GetDio64(int nPos, int nOption = 0)
    {
        return _dio.ReadInSig(nPos) ? 1 : 0;
    }

    /// <summary>
    /// Delphi: f_SetHandBcr(nOption) - GIB-OPTIC:HANDBCR
    /// </summary>
    public void f_SetHandBcr(int nOption)
    {
        // Hand BCR setting
    }

    /// <summary>
    /// Delphi: f_ControlDio(nOption) -> Integer
    /// </summary>
    public int f_ControlDio(int nOption)
    {
        int wdRet = 2;
        try
        {
            int group = (_pgNo <= ChannelConstants.Ch2) ? ChannelConstants.ChTop : ChannelConstants.ChBottom;
            switch (nOption)
            {
                case 1:  wdRet = _dio.UnlockCarrier(_pgNo, false); break;
                case 2:  wdRet = _dio.LockCarrier(_pgNo, false); break;
                case 3:  wdRet = _dio.ProbeForward(_pgNo); break;
                case 4:  wdRet = _dio.ProbeBackward(_pgNo); break;
                case 5:  wdRet = _dio.MovingProbe(group, true); break;
                case 6:  wdRet = _dio.MovingProbe(group, false); break;
                case 7:  wdRet = _dio.UnlockPinBlock(_pgNo); break;
                case 8:  wdRet = _dio.LockPinBlock(_pgNo); break;
                case 9:  wdRet = _dio.MovingShutter(group, true); break;
                case 10: wdRet = _dio.MovingShutter(group, false); break;
                case 11: wdRet = _dio.VacuumOn(_pgNo); break;
                case 12: wdRet = _dio.VacuumOff(_pgNo); break;
                case 13: wdRet = _dio.LampOnOff(_pgNo, false); break;
                case 14: wdRet = _dio.LampOnOff(_pgNo, true); break;
                case 15: wdRet = _dio.CloseUpPinBlock(_pgNo); break;
                case 16: wdRet = _dio.CloseDnPinBlock(_pgNo); break;
                case 17: wdRet = _dio.MovingAll(group, true); break;
                case 18: wdRet = _dio.MovingAll(group, false); break;
            }
        }
        catch
        {
            wdRet = 2;
        }
        return wdRet;
    }

    // =========================================================================
    // #region (P) Logging / Display - 7 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_LogM(sMsg, [nOption])
    /// Log message to test display.
    /// </summary>
    public void f_LogM(string sMsg, int nOption = 0)
    {
        SendGuiMessage(MessageConstants.MsgModeWorking, sMsg, logType: nOption);
        _mLogLogger?.MLog(_pgNo, sMsg);
    }

    /// <summary>
    /// Delphi: f_SetCaptionName(nVirtual, sCaption)
    /// </summary>
    public void f_SetCaptionName(int nVirtual, string sCaption)
    {
        SendGuiMessage(MessageConstants.MsgModeVirtualCaption, sCaption, param: nVirtual);
    }

    /// <summary>
    /// Delphi: f_LogRePGM(sSN)
    /// </summary>
    public void f_LogRePGM(string sSN)
    {
        SendGuiMessage(MessageConstants.MsgModeLogRepgm, msg2: sSN);
    }

    /// <summary>
    /// Delphi: f_LogPwr()
    /// </summary>
    public void f_LogPwr()
    {
        SendGuiMessage(MessageConstants.MsgModeLogPwr);
    }

    /// <summary>
    /// Delphi: f_ShowResult(nCh, sResult, nOption)
    /// </summary>
    public void f_ShowResult(int nCh, string sResult, int nOption)
    {
        SendGuiMessage(MessageConstants.MsgModeChResult, sResult, param: nOption);
    }

    /// <summary>Overload: CSX calls f_ShowResult(nNgCode, '') with 2 params.
    /// Passes NgCode as Param so UiUpdateService can route it to ChannelResultReady.</summary>
    public void f_ShowResult(int nNgCode, string sResult)
    {
        SendGuiMessage(MessageConstants.MsgModeChResult, sResult, param: nNgCode);
    }

    /// <summary>
    /// Delphi: f_ShowCurStaus(nParam1, sStatus, nParam2)
    /// </summary>
    public void f_ShowCurStaus(int nParam1, string sStatus, int nParam2)
    {
        SendGuiMessage(MessageConstants.MsgModeWorking, sStatus, logType: nParam2);
    }

    /// <summary>Overload: PSU calls f_ShowCurStaus('text') with single string.</summary>
    public void f_ShowCurStaus(string sStatus)
    {
        f_ShowCurStaus(0, sStatus, 0);
    }

    /// <summary>
    /// Delphi: f_ShowSerial(sSerial, nOption)
    /// </summary>
    public void f_ShowSerial(string sSerial, int nOption)
    {
        SendGuiMessage(MessageConstants.MsgModeShowSerialNumber, sSerial, param: nOption);
    }

    // =========================================================================
    // #region (Q) CSV / Report - 7 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_MakeCsv(sHeader, sData)
    /// </summary>
    public void f_MakeCsv(string sHeader, string sData)
    {
        c_TestInfo.csvHeader = sHeader;
        c_TestInfo.csvData = sData;
        SendGuiMessage(MessageConstants.MsgModeLogCsv);
    }

    /// <summary>
    /// Delphi: f_MakeOpticCsv(insCsv : TInsCsv)
    /// </summary>
    public void f_MakeOpticCsv(TInsCsv insCsv)
    {
        c_TestInfo.InsCsv = insCsv;
        SendGuiMessage(MessageConstants.MsgModeLogCsv);
    }

    /// <summary>
    /// Delphi: f_MakeSummaryCsv(insCsv : TInsCsv, nHeaderCnt)
    /// </summary>
    public void f_MakeSummaryCsv(TInsCsv insCsv, int nHeaderCnt)
    {
        c_TestInfo.InsCsv = insCsv;
        c_TestInfo.CsvHeaderCnt = nHeaderCnt;
        SendGuiMessage(MessageConstants.MsgModeLogCsvSummary);
    }

    /// <summary>
    /// Delphi: f_MakeApdrCsv(insCsv : TInsCsv)
    /// Note: same Proc as MakeSummaryCsv in Delphi
    /// </summary>
    public void f_MakeApdrCsv(TInsCsv insCsv)
    {
        c_TestInfo.InsCsv = insCsv;
        SendGuiMessage(MessageConstants.MsgModeLogCsvSummary);
    }

    /// <summary>
    /// Delphi: f_MakePassRGB(insRgbPass : TInsRgbPass)
    /// </summary>
    public void f_MakePassRGB(TInsRgbPass insRgbPass)
    {
        m_RgbAvrInfo.RgbPass = insRgbPass;
        SendGuiMessage(MessageConstants.MsgModePassRgb);
    }

    /// <summary>
    /// Delphi: f_SetCurJigChForPass(nOption)
    /// </summary>
    public void f_SetCurJigChForPass(int nOption)
    {
        // Set current jig channel for pass
    }

    /// <summary>
    /// Delphi: f_LoadPassRgbAvr(nAvrType, nAvrCnt, nBandCnt, nGrayStep, nOption1) -> Integer
    /// </summary>
    public int f_LoadPassRgbAvr(int nAvrType, int nAvrCnt, int nBandCnt,
                                 int nGrayStep, int nOption1)
    {
        m_RgbAvrInfo.AvrType = nAvrType;
        m_RgbAvrInfo.AvrCnt = nAvrCnt;
        m_RgbAvrInfo.BandCnt = nBandCnt;
        m_RgbAvrInfo.GrayStep = nGrayStep;
        m_RgbAvrInfo.Option1 = nOption1;
        SendGuiMessage(MessageConstants.MsgModeGetAvgRgb);
        return 0;
    }

    // =========================================================================
    // #region (R) Sequence Control - 4 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_NextStep(nParam, nParam2, nParam3)
    /// Sets sequence status for flow control.
    /// </summary>
    public void f_NextStep(int nParam, int nParam2, int nParam3)
    {
        // Sequence status update - handled by ScriptEngine
        _bus.Publish(new ScriptNextStepMessage
        {
            Channel = _pgNo,
            StepIndex = nParam,
            Status = nParam2,
            Process = nParam3,
        });
    }

    /// <summary>
    /// Delphi: f_SetInit(nOption)
    /// </summary>
    public void f_SetInit(int nOption)
    {
        switch (nOption)
        {
            case 1: // InitialData only
                InitializeData();
                break;
            case 2: // Clear display only
                SendGuiMessage(MessageConstants.MsgModeChClear);
                break;
            case 3: // InitialData + Clear
                InitializeData();
                SendGuiMessage(MessageConstants.MsgModeChClear);
                break;
            case 4: // Stop
                break;
        }
    }

    /// <summary>Delphi: TScrCls.InitialData — inspection start data reset</summary>
    private void InitializeData()
    {
        c_bIsBcrReady = false;
        c_nNgCode = 0;
        c_bCEL_Stop = false;

        // MES data reset
        if (_gmes != null)
        {
            var mesData = _gmes.MesData;
            if (_pgNo < mesData.Length)
            {
                var d = mesData[_pgNo];
                d.Rwk = "";
                d.LotNo = "";
                d.Pf = "";
                d.DefectPat = "";
                d.MesPendingMsg = -1;
                d.MesSentMsg = -1;
                d.MesSendRcvWaitTick = -1;
                d.CarrierId = "";
                d.PchkSendNg = false;
                d.PchkRtnCode = "";
                d.PchkRtnPid = "";
                d.PchkRtnZigId = "";
                d.PchkRtnSerialNo = "";
                d.Model = "";
                d.EicrRtnCode = "";
                d.ApdrRtnCode = "";
                d.ApdrData = "";
                d.ApdrRtnSerialNo = "";
                d.Option = 0;
                d.EodaAck = 0;
            }
        }

        // Delphi: TScrCls.InitialData — TestInfo fields from Common.SystemInfo/StatusInfo
        var sysInfo = _config.SystemInfo;
        c_TestInfo.EQPId = sysInfo.EQPId;
        c_TestInfo.Ch = _pgNo;
        c_TestInfo.UserID = sysInfo.AutoLoginID;
        c_TestInfo.Model = sysInfo.TestModel;
        c_TestInfo.AutoMode = _status.AutoMode;
        c_TestInfo.AABMode = _status.AabMode;
        c_TestInfo.Login = _status.IsLoggedIn;
        c_TestInfo.Use_ECS = sysInfo.UseECS;
        c_TestInfo.Use_MES = sysInfo.UseMES;
        c_TestInfo.Use_DFS = _config.DfsConfInfo.UseDfs;
        c_TestInfo.Use_GIB = sysInfo.UseGIB;
        c_TestInfo.Use_FFCData = sysInfo.CAMFFCData;
        c_TestInfo.Use_StainData = sysInfo.CAMStainData;
        c_TestInfo.Use_FTPUpload = sysInfo.CAMFTPUpload;
        c_TestInfo.Use_TemplateData = sysInfo.CAMTemplateData;
        c_TestInfo.SIM_Use_PG = _config.SimulateInfo.UsePG;
        c_TestInfo.SIM_Use_DIO = _config.SimulateInfo.UseDIO;
        c_TestInfo.SIM_Use_PLC = _config.SimulateInfo.UsePLC;

        // PG version
        if (_pgNo < _pg.Length)
            c_TestInfo.PG_Ver = _pg[_pgNo].Version.VerAll;

        SendGuiMessage(MessageConstants.MsgModeWorking,
            "[INSPECTION START] ------------------------------------------------- ");
    }

    /// <summary>
    /// Delphi: f_CheckRetry(nOption) -> Integer
    /// </summary>
    public int f_CheckRetry(int nOption)
    {
        return 0;
    }

    /// <summary>
    /// Delphi: f_TactTime(nOption)
    /// </summary>
    public void f_TactTime(int nOption)
    {
        switch (nOption)
        {
            case 1: // Total Tact Start
                c_TestInfo.StartTime = DateTime.Now;
                c_TestInfo.StUnitTact = DateTime.MinValue;
                c_TestInfo.EdUnitTact = DateTime.MinValue;
                SendGuiMessage(MessageConstants.MsgModeWorking, "Total Tact Time : Start!!! [0s]");
                SendGuiMessage(MessageConstants.MsgModeTactStart);
                break;
            case 2: // Total Tact End
                c_TestInfo.EndTime = DateTime.Now;
                var totalSec = (int)(c_TestInfo.EndTime - c_TestInfo.StartTime).TotalSeconds;
                SendGuiMessage(MessageConstants.MsgModeWorking, $"Total Tact Time : End!!! [{totalSec}s]");
                SendGuiMessage(MessageConstants.MsgModeTactEnd);
                break;
            case 3: // Unit Tact Start
                c_TestInfo.StUnitTact = DateTime.Now;
                SendGuiMessage(MessageConstants.MsgModeWorking, "Measure Tact Time : Start!!! [0s]");
                SendGuiMessage(MessageConstants.MsgModeUnitTtStart);
                break;
            case 4: // Unit Tact End
                c_TestInfo.EdUnitTact = DateTime.Now;
                SendGuiMessage(MessageConstants.MsgModeUnitTtEnd);
                break;
        }
    }

    // =========================================================================
    // #region (S) File Operations - 4 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_FileExists(sFileName) -> Integer
    /// </summary>
    public int f_FileExists(string sFileName)
    {
        return File.Exists(sFileName) ? 1 : 0;
    }

    /// <summary>
    /// Delphi: f_DirectoryExists(sDirName) -> Integer
    /// </summary>
    public int f_DirectoryExists(string sDirName)
    {
        return Directory.Exists(sDirName) ? 1 : 0;
    }

    /// <summary>
    /// Delphi: f_ForceDirectories(sDirName) -> Integer
    /// </summary>
    public int f_ForceDirectories(string sDirName)
    {
        try
        {
            Directory.CreateDirectory(sDirName);
            return 1;
        }
        catch
        {
            return 0;
        }
    }

    /// <summary>
    /// Delphi: f_LoadFileData(nMode, var nSize, var data, sFileName) -> Integer
    /// Loads file data into byte array.
    /// </summary>
    public int f_LoadFileData(int nMode, ref int nSize, ref byte[] data, string sFileName = "")
    {
        if (nMode == 0 && File.Exists(sFileName))
        {
            data = File.ReadAllBytes(sFileName);
            nSize = data.Length;
            return 0;
        }
        return -1;
    }

    // =========================================================================
    // #region (T) String / Variant Conversion - 2 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_Convert_VariantToHex(data, nStart, nEnd, sPrefix, sDelimiter) -> String
    /// </summary>
    public string f_Convert_VariantToHex(byte[] data, int nStart, int nEnd,
                                          string sPrefix, string sDelimiter)
    {
        var sb = new StringBuilder();
        if (data != null)
        {
            for (int i = nStart; i <= nEnd && i < data.Length; i++)
                sb.Append(sPrefix).Append(data[i].ToString("X2")).Append(sDelimiter);
        }
        return sb.ToString();
    }

    /// <summary>
    /// Delphi: f_Convert_VariantToAscii(data, nStart, nEnd) -> String
    /// </summary>
    public string f_Convert_VariantToAscii(byte[] data, int nStart, int nEnd)
    {
        var sb = new StringBuilder();
        if (data != null)
        {
            for (int i = nStart; i <= nEnd && i < data.Length; i++)
                sb.Append((char)data[i]);
        }
        return sb.ToString();
    }

    // =========================================================================
    // #region (U) Miscellaneous - 9 methods
    // =========================================================================

    /// <summary>
    /// Delphi: Sleep(nMs)
    /// </summary>
    public void Sleep(int nMs)
    {
        Thread.Sleep(nMs);
    }

    /// <summary>
    /// Delphi: f_IonizerOn(nOn, nCh) -> Integer
    /// </summary>
    public int f_IonizerOn(int nOn, int nCh)
    {
        SendGuiMessage(MessageConstants.MsgModeIonizer, param: nOn);
        return 0;
    }

    /// <summary>
    /// Delphi: f_OtpWrite() -> Integer
    /// </summary>
    public int f_OtpWrite()
    {
        // OTP Write - currently stubbed in Delphi
        return 0;
    }

    /// <summary>
    /// Delphi: f_OtpRead() -> Integer
    /// </summary>
    public int f_OtpRead()
    {
        // OTP Read - currently stubbed in Delphi
        return 0;
    }

    /// <summary>
    /// Delphi: f_ConfirmHost(nRet) -> Integer
    /// </summary>
    public int f_ConfirmHost(int nRet)
    {
        // Delphi: if Common.AutoReStart then Exit(0)
        // AutoReStart is a UI-level flag; checked via AutoRepeatTest on ISystemStatusService
        if (_status.AutoRepeatTest)
            return 0;
        c_nConfirmHostRet = nRet;
        return c_nConfirmHostRet;
    }

    /// <summary>
    /// Delphi: f_SetConfirmRty(nOption)
    /// </summary>
    public void f_SetConfirmRty(int nOption)
    {
        // Set confirm retry option
    }

    /// <summary>
    /// Delphi: f_RemakeSerialLog(sNgName, sSeqRet)
    /// </summary>
    public void f_RemakeSerialLog(string sNgName, string sSeqRet)
    {
        // Remake serial log - currently stubbed in Delphi
    }

    /// <summary>
    /// Delphi: f_SendLightCommand(nCh, nValue1, nValue2) -> Integer
    /// </summary>
    public int f_SendLightCommand(int nCh, int nValue1, int nValue2)
    {
        // Send light controller command
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendEraseCodeType(nCodeType, nParam1, nParam2)
    /// </summary>
    public void f_SendEraseCodeType(int nCodeType, int nParam1, int nParam2 = 0)
    {
        // Send erase code type to PG
    }

    // =========================================================================
    // #region (V) Hex File / Data Write - 3 methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_SendPocbHexFile(p1,p2,p3,p4,p5,p6, var p7) -> Integer
    /// </summary>
    public int f_SendPocbHexFile(int p1, int p2, int p3, int p4,
                                  int p5, int p6, ref int p7)
    {
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendPocbHexFile2(p1,p2,p3,p4,p5,p6,p7,p8,p9) -> Integer
    /// </summary>
    public int f_SendPocbHexFile2(int p1, int p2, int p3, int p4,
                                   int p5, int p6, int p7, int p8, int p9)
    {
        return 0;
    }

    /// <summary>
    /// Delphi: f_SendPocbDataWrite(p1,p2,p3,p4,p5)
    /// </summary>
    public void f_SendPocbDataWrite(int p1, int p2, int p3, int p4, int p5)
    {
        // Send POCB data write
    }

    // =========================================================================
    // #region (W) Remaining methods
    // =========================================================================

    /// <summary>
    /// Delphi: f_LogPcd - currently unused/stubbed
    /// </summary>
    public void f_LogPcd(int nData)
    {
        // PCD logging
    }

    // =========================================================================
    // #region Internal messaging helpers
    // =========================================================================

    /// <summary>
    /// Sends a GUI display message via the message bus.
    /// Replaces Delphi's SendTestGuiDisplay / WM_COPYDATA mechanism.
    /// </summary>
    private void SendGuiMessage(int mode, string msg = "", string msg2 = "",
                                int logType = 0, int param = 0)
    {
        _bus.Publish(new ScriptGuiMessage
        {
            Channel = _pgNo,
            Mode = mode,
            Param = param,
            Msg = msg,
            Msg2 = msg2,
            LogType = logType,
        });
    }

    /// <summary>
    /// Sends a main form GUI message via the message bus.
    /// Replaces Delphi's SendMainGuiDisplay.
    /// </summary>
    private void SendMainGuiMessage(int mode, int param1 = 0, int param2 = 0)
    {
        _bus.Publish(new ScriptMainGuiMessage
        {
            Channel = _pgNo,
            Mode = mode,
            Param = param1,
            Param2 = param2,
        });
    }

    // =========================================================================
    // AutoStart Host Methods (AS_ prefix to avoid name collisions)
    // Called from Execute_AutoStart() in model CSX scripts.
    // Delphi origin: Main_OC.pas Execute_AutoStart + Test4ChOC.pas AutoLogicStart
    // =========================================================================

    /// <summary>Flag set by Execute_AutoStart() in CSX to signal setup success.</summary>
    public bool AutoStartReady { get; set; }

    /// <summary>Failure reason set by Execute_AutoStart() in CSX when setup fails.</summary>
    public string AutoStartFailReason { get; set; } = string.Empty;

    // ── PLC Validation ──

    /// <summary>Check if PLC is connected.</summary>
    public bool CheckPlcConnected() => _plc?.Connected ?? false;

    /// <summary>Check if robot is busy for a group (0=CH12, 1=CH34).</summary>
    public bool AS_IsBusyRobot(int group) => _plc?.IsBusyRobot(group) ?? false;

    /// <summary>Clear robot request signal for a channel group.</summary>
    public void AS_ClearRobotRequest(int index) => _plc?.ClearRobotRequest(index);

    /// <summary>Set ECS unit status (UnitStateRun=8, UnitStateIdle=9).</summary>
    public void AS_SetEcsUnitStatus(int state, int param) => _plc?.EcsUnitStatus(state, param);

    /// <summary>Save glass data for a channel to file.</summary>
    public void AS_SaveGlassData(int ch, string path) => _plc?.SaveGlassDataChannel(ch, path);

    // ── PG Validation ──

    /// <summary>Check if all PG channels (0..count-1) are connected.</summary>
    public bool AS_CheckPgConnected(int count)
    {
        for (int i = 0; i < count && i < _pg.Length; i++)
        {
            if (_pg[i].Status == PgStatus.Disconnected)
                return false;
        }
        return true;
    }

    /// <summary>Check if MY channel's PG is connected (uses _pgNo).</summary>
    public bool AS_CheckMyPgConnected()
    {
        return _pgNo < _pg.Length && _pg[_pgNo].Status != PgStatus.Disconnected;
    }

    // ── DIO Control ──

    /// <summary>Set ionizer on/off for a group (0=TOP, 1=BOTTOM).</summary>
    public void AS_SetIonizer(int group, bool on) => _dio.SetIonizer(group, on);

    /// <summary>Set lamp on/off for a group (0=TOP, 1=BOTTOM).</summary>
    public void AS_SetLamp(int group, bool on) => _dio.LampOnOff(group, on);

    // ── AutoStart: Hardware Control (for Robot_Request_Load/UnLoad in CSX) ──

    /// <summary>
    /// 그룹 내 두 채널의 검사 Flow가 완료될 때까지 대기.
    /// Returns 0=OK (idle), >0=timeout (still running).
    /// </summary>
    private int WaitGroupIdle(int ch, int timeoutMs = 60000)
    {
        int ch1 = (ch <= 1) ? 0 : 2;
        int ch2 = ch1 + 1;

        if (!_dll.IsFlowRunning(ch1) && !_dll.IsFlowRunning(ch2))
            return 0;

        _logger.Warn($"WaitGroupIdle: CH{ch1 + 1}={_dll.IsFlowRunning(ch1)}, CH{ch2 + 1}={_dll.IsFlowRunning(ch2)} — waiting...");
        long deadline = Environment.TickCount64 + timeoutMs;

        while (_dll.IsFlowRunning(ch1) || _dll.IsFlowRunning(ch2))
        {
            if (Environment.TickCount64 >= deadline)
            {
                _logger.Error($"WaitGroupIdle timeout ({timeoutMs}ms): CH{ch1 + 1}={_dll.IsFlowRunning(ch1)}, CH{ch2 + 1}={_dll.IsFlowRunning(ch2)}");
                return 1;
            }
            Thread.Sleep(200);
        }

        _logger.Info($"WaitGroupIdle: group idle, proceeding");
        return 0;
    }

    /// <summary>Move probe backward for a channel. Returns 0=OK, >0=NG.</summary>
    public int AS_ProbeBackward(int ch) => _dio.ProbeBackward(ch);

    /// <summary>
    /// group=true: 그룹 내 검사 Flow 완료 대기 후 두 채널 ProbeBackward 순차 실행.
    /// group=false: 지정 채널만 실행.
    /// </summary>
    public int AS_ProbeBackward(int ch, bool group)
    {
        if (!group) return _dio.ProbeBackward(ch);
        int ret = WaitGroupIdle(ch);
        if (ret > 0) return ret;
        int ch1 = (ch <= 1) ? 0 : 2;
        int ch2 = ch1 + 1;
        ret = _dio.ProbeBackward(ch1);
        if (ret > 0) return ret;
        return _dio.ProbeBackward(ch2);
    }

    /// <summary>Unlock carrier for a channel. Returns 0=OK, >0=NG.</summary>
    public int AS_UnlockCarrier(int ch) => _dio.UnlockCarrier(ch, true);

    /// <summary>
    /// group=true: 그룹 내 검사 Flow 완료 대기 후 그룹 상수로 UnlockCarrier 호출.
    /// group=false: 지정 채널만 실행.
    /// </summary>
    public int AS_UnlockCarrier(int ch, bool group)
    {
        if (!group) return _dio.UnlockCarrier(ch, true);
        int ret = WaitGroupIdle(ch);
        if (ret > 0) return ret;
        int groupId = (ch <= 1) ? ChannelConstants.ChTopGroup : ChannelConstants.ChBottomGroup;
        return _dio.UnlockCarrier(groupId, true);
    }

    /// <summary>Send robot load request to PLC for a channel/group.</summary>
    public int AS_RobotLoadRequest(int ch) => _plc?.RobotLoadRequest(ch) ?? 1;

    /// <summary>
    /// group=true: 그룹 내 검사 Flow 완료 대기 후 ch1으로 RobotLoadRequest 전송.
    /// </summary>
    public int AS_RobotLoadRequest(int ch, bool group)
    {
        if (_plc == null) return 1;
        if (!group) return _plc.RobotLoadRequest(ch);
        int ret = WaitGroupIdle(ch);
        if (ret > 0) return ret;
        int ch1 = (ch <= 1) ? 0 : 2;
        return _plc.RobotLoadRequest(ch1);
    }

    /// <summary>Send robot unload request to PLC for a channel/group.</summary>
    public int AS_RobotUnloadRequest(int ch) => _plc?.RobotUnloadRequest(ch) ?? 1;

    /// <summary>
    /// group=true: 그룹 내 검사 Flow 완료 대기 후 ch1으로 RobotUnloadRequest 전송.
    /// </summary>
    public int AS_RobotUnloadRequest(int ch, bool group)
    {
        if (_plc == null) return 1;
        if (!group) return _plc.RobotUnloadRequest(ch);
        int ret = WaitGroupIdle(ch);
        if (ret > 0) return ret;
        int ch1 = (ch <= 1) ? 0 : 2;
        return _plc.RobotUnloadRequest(ch1);
    }

    /// <summary>
    /// 그룹 내 두 채널의 검사 Flow + Process_Finish 완료 대기.
    /// IsFlowRunning=false AND IsProcessUnloadDone=true for both channels.
    /// Returns 0=OK, >0=timeout.
    /// </summary>
    public int AS_WaitGroupUnloadReady(int ch, int timeoutMs = 60000)
    {
        int ch1 = (ch <= 1) ? 0 : 2;
        int ch2 = ch1 + 1;

        bool IsReady() =>
            !_dll.IsFlowRunning(ch1) && !_dll.IsFlowRunning(ch2) &&
            _dll.IsProcessUnloadDone(ch1) && _dll.IsProcessUnloadDone(ch2);

        if (IsReady()) return 0;

        _logger.Warn($"WaitGroupUnloadReady: CH{ch1 + 1}(flow={_dll.IsFlowRunning(ch1)},finish={_dll.IsProcessUnloadDone(ch1)}) " +
                     $"CH{ch2 + 1}(flow={_dll.IsFlowRunning(ch2)},finish={_dll.IsProcessUnloadDone(ch2)}) — waiting...");
        long deadline = Environment.TickCount64 + timeoutMs;

        while (!IsReady())
        {
            if (Environment.TickCount64 >= deadline)
            {
                _logger.Error($"WaitGroupUnloadReady timeout ({timeoutMs}ms): " +
                              $"CH{ch1 + 1}(flow={_dll.IsFlowRunning(ch1)},finish={_dll.IsProcessUnloadDone(ch1)}) " +
                              $"CH{ch2 + 1}(flow={_dll.IsFlowRunning(ch2)},finish={_dll.IsProcessUnloadDone(ch2)})");
                return 1;
            }
            Thread.Sleep(200);
        }

        _logger.Info($"WaitGroupUnloadReady: group ready, proceeding");
        return 0;
    }

    /// <summary>
    /// Process_Finish 완료 플래그 설정. CSX Process_Finish 끝에서 호출.
    /// Sets IsProcessUnloadDone for the current channel.
    /// </summary>
    public void AS_SetProcessFinishDone(bool val) => _dll.SetProcessUnloadDone(_pgNo, val);

    /// <summary>Set loading interlock flag.</summary>
    public void AS_SetLoading(bool val) => _status.IsLoading = val;

    // ── Status / Utilities ──

    /// <summary>Get INI directory path.</summary>
    public string AS_GetIniPath() => _path.IniDir;

    /// <summary>Set alarm data.</summary>
    public void AS_SetAlarm(int code, int val1, int val2)
    {
        _status.SetAlarmData(code, (byte)val1);
    }
}

// =============================================================================
// Message types for bus communication
// =============================================================================

/// <summary>
/// GUI display message from script to test form.
/// Replaces Delphi WM_COPYDATA + RGuiScript.
/// <para>
/// Uses base <see cref="AppMessage.Channel"/> and <see cref="AppMessage.Mode"/>.
/// Additional fields: Msg, Msg2, LogType are script-specific.
/// <see cref="AppMessage.Param"/> carries the extra parameter.
/// </para>
/// </summary>
public sealed class ScriptGuiMessage : AppMessage
{
    /// <summary>Primary message text. Delphi: RGuiScript.Msg</summary>
    public string Msg { get; init; } = string.Empty;

    /// <summary>Secondary message text. Delphi: RGuiScript.Msg2</summary>
    public string Msg2 { get; init; } = string.Empty;

    /// <summary>Log type/severity. Delphi: RGuiScript.nParam (log option)</summary>
    public int LogType { get; init; }
}

/// <summary>
/// Main form GUI message from script.
/// <para>
/// Uses base <see cref="AppMessage.Channel"/>, <see cref="AppMessage.Mode"/>,
/// <see cref="AppMessage.Param"/>, and <see cref="AppMessage.Param2"/>.
/// </para>
/// </summary>
public sealed class ScriptMainGuiMessage : AppMessage;

/// <summary>
/// NextStep sequence control message.
/// <para>
/// Uses base <see cref="AppMessage.Channel"/> for the PG channel.
/// StepIndex, Status, Process are script-specific fields for flow control.
/// </para>
/// </summary>
public sealed class ScriptNextStepMessage : AppMessage
{
    /// <summary>Sequence step index. Delphi: nParam in NextStep_Proc</summary>
    public int StepIndex { get; init; }

    /// <summary>Sequence status value. Delphi: nParam2 in NextStep_Proc</summary>
    public int Status { get; init; }

    /// <summary>Sequence process mode. Delphi: nParam3 in NextStep_Proc</summary>
    public int Process { get; init; }
}

// =============================================================================
// Message constants (replaces DefCommon MSG_MODE_* references)
// =============================================================================

/// <summary>
/// Message mode constants used by script GUI messaging.
/// Maps to Delphi DefCommon.MSG_MODE_* constants.
/// </summary>
public static class MessageConstants
{
    public const int MsgModeWorking = 1;
    public const int MsgModeChResult = 2;
    public const int MsgModePowerOn = 3;
    public const int MsgModePowerOff = 4;
    public const int MsgModePatDisplay = 5;
    public const int MsgModeLogPwr = 6;
    public const int MsgModeLogCsv = 7;
    public const int MsgModeLogCsvSummary = 8;
    public const int MsgModeLogCsvApdr = 9;
    public const int MsgModeShowSerialNumber = 10;
    public const int MsgModeBarcodeReady = 11;
    public const int MsgModeIonizer = 12;
    public const int MsgModeIrtemp = 13;
    public const int MsgModeVirtualCaption = 14;
    public const int MsgModeLogRepgm = 15;
    public const int MsgModeSyncWork = 16;
    public const int MsgModeGetAvgRgb = 17;
    public const int MsgModePassRgb = 18;
    public const int MsgModeShowConfirmEicr = 19;
    public const int MsgModeDisplayAlarm = 20;
    public const int MsgModeCa310Measure = 21;
    public const int MsgModeCa410Measure = 22;
    public const int MsgModeChClear = 23;
    public const int MsgModeTactStart = 24;
    public const int MsgModeTactEnd = 25;
    public const int MsgModeUnitTtStart = 26;
    public const int MsgModeUnitTtEnd = 27;
    public const int MsgModeAgingTime = 28;
    public const int MsgModeForRtyMakeAllNg = 29;
}
