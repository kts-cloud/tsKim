// =============================================================================
// ScriptDataTypes.cs
// C# equivalents of the Delphi record types used in Pascal scripts.
// Converted from Delphi: src_X3584\pasScriptClass.pas + CommonClass.pas
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Scripting
// =============================================================================

using System.Collections.Generic;

namespace Dongaeltek.ITOLED.BusinessLogic.Scripting;

#region Enumerations

/// <summary>
/// Sequence status enumeration.
/// <para>Delphi origin: TSeqStatus (pasScriptClass.pas line 23)</para>
/// </summary>
public enum SeqStatus
{
    None = 0,
    Seq1, Seq2, Seq3, Seq4, Seq5, Seq6, Seq7, Seq8, Seq9, Seq10,
    Seq11, Seq12, Seq13, Seq14, Seq15, Seq16, Seq17, Seq18, Seq19,
    Scan, Stop, PreStop, SeqReport
}

/// <summary>
/// Sequence process mode.
/// <para>Delphi origin: TSeqProcess (pasScriptClass.pas line 28)</para>
/// </summary>
public enum SeqProcess
{
    Normal = 0,
    Stop,
    Repeat
}

/// <summary>
/// Inspection status.
/// <para>Delphi origin: TInsStatus (pasScriptClass.pas line 29)</para>
/// </summary>
public enum InsStatus
{
    Ready = 0,
    Run,
    Stop
}

#endregion

#region Script-exposed record types

/// <summary>
/// GUI script message record.
/// <para>Delphi origin: RGuiScript (pasScriptClass.pas line 32)</para>
/// </summary>
public class RGuiScript
{
    public int MsgType { get; set; }
    public int Channel { get; set; }
    public int Mode { get; set; }
    public int nParam { get; set; }
    public int nParam2 { get; set; }
    public string Msg { get; set; } = string.Empty;
    public string Msg2 { get; set; } = string.Empty;
}

/// <summary>
/// Data view display record.
/// <para>Delphi origin: RDataView (pasScriptClass.pas line 42)</para>
/// </summary>
public class RDataView
{
    public int MsgType { get; set; }
    public int Channel { get; set; }
    public int Option { get; set; }
    public int Len { get; set; }
    public bool Start { get; set; }
    public bool CellMerage { get; set; }
    public bool Result { get; set; }
    public int DataType { get; set; }
    public int MinVal { get; set; }
    public int MaxVal { get; set; }
    public string Msg { get; set; } = string.Empty;
}

/// <summary>
/// Limit specification for touch test.
/// <para>Delphi origin: TLimitStr (pasScriptClass.pas line 225)</para>
/// </summary>
public class TLimitStr
{
    public int LimitType { get; set; }
    public int FramePos { get; set; }
    public int DataPos { get; set; } // -1 means All
    public bool bRange { get; set; }
    public int StPos { get; set; }
    public int EdPos { get; set; }
    public string Limit { get; set; } = string.Empty;
}

/// <summary>
/// Touch test information record.
/// <para>Delphi origin: TTouchInfo (pasScriptClass.pas line 234)</para>
/// </summary>
public class TTouchInfo
{
    public int SeqNum { get; set; }
    public int ProtocolIdx { get; set; }
    public int Freq { get; set; }
    public int Frame { get; set; }
    public int DataType { get; set; }
    public int RetyCnt { get; set; }
    public int RefIdx { get; set; }
    public string DefectCode { get; set; } = string.Empty;
    public string TestName { get; set; } = string.Empty;
    public int LimitCnt { get; set; }
    public List<TLimitStr> LimitInfo { get; set; } = new();
}

/// <summary>
/// Camera OTP data buffer.
/// <para>Delphi origin: TCameraOtpData (pasScriptClass.pas line 248)</para>
/// </summary>
public class TCameraOtpData
{
    public int TotalSize { get; set; }
    public int FiledUpSize { get; set; }
    public byte[] Data { get; set; } = [];
}

/// <summary>
/// RGB average measurement.
/// <para>Delphi origin: TRgbAvr (pasScriptClass.pas line 264)</para>
/// </summary>
public class TRgbAvr
{
    public int AvrCnt { get; set; }
    public int AvrR { get; set; }
    public int AvrG { get; set; }
    public int AvrB { get; set; }
    public List<int> R { get; set; } = new();
    public List<int> G { get; set; } = new();
    public List<int> B { get; set; } = new();
}

/// <summary>
/// NG ratio tracking (OK/NG counts).
/// <para>Delphi origin: TNgRatio (pasScriptClass.pas line 270)</para>
/// </summary>
public class TNgRatio
{
    public int Ok { get; set; }
    public int Ng { get; set; }
}

/// <summary>
/// Sequence status record.
/// <para>Delphi origin: RSeqStatus (pasScriptClass.pas line 220)</para>
/// </summary>
public class RSeqStatus
{
    public SeqStatus Status { get; set; }
    public SeqProcess Process { get; set; }
}

/// <summary>
/// RGB average info record (used in pass/fail reporting).
/// <para>Delphi origin: RRgbAvrInfo (pasScriptClass.pas line 196)</para>
/// </summary>
public class RRgbAvrInfo
{
    public int AvrType { get; set; }
    public int AvrCnt { get; set; }
    public int Option1 { get; set; }
    public int BandCnt { get; set; }
    public int GrayStep { get; set; }
    public TInsRgbPass RgbPass { get; set; } = new();
}

#endregion

#region Script-exposed class types (used via DefineClassByRTTI)

/// <summary>
/// OC parameters wrapper (exposed to script as class).
/// <para>Delphi origin: TOcParamsWR (CommonClass.pas)</para>
/// </summary>
public class TOcParamsWR
{
    public int IdxOcPCnt { get; set; }
    public int IdxOcVCnt { get; set; }
}

/// <summary>
/// OC gamma value (exposed to script as class).
/// <para>Delphi origin: TOcGammaVal (CommonClass.pas)</para>
/// </summary>
public class TOcGammaVal
{
    public float x { get; set; }
    public float y { get; set; }
    public float Lv { get; set; }
}

/// <summary>
/// OC gamma command (exposed to script as class).
/// <para>Delphi origin: TOcGammaCmd (CommonClass.pas)</para>
/// </summary>
public class TOcGammaCmd
{
    public int r { get; set; }
    public int g { get; set; }
    public int b { get; set; }
}

/// <summary>
/// OC verification parameters (exposed to script as class).
/// <para>Delphi origin: TOcVerify (CommonClass.pas)</para>
/// </summary>
public class TOcVerify
{
    public string ItemName { get; set; } = string.Empty;
    public int Idx { get; set; }
    public TOcGammaVal Target { get; set; } = new();
    public TOcGammaVal Limit { get; set; } = new();
}

/// <summary>
/// User array class (exposed to script).
/// <para>Delphi origin: TUserArray (CommonClass.pas)</para>
/// </summary>
public class TUserArray
{
    public int Count { get; set; }
    public List<int> Data { get; set; } = new();
}

/// <summary>
/// OTP table array (exposed to script).
/// <para>Delphi origin: TOtpTableArray (CommonClass.pas)</para>
/// </summary>
public class TOtpTableArray
{
    public int Count { get; set; }
    public List<string> Data { get; set; } = new();
}

/// <summary>
/// Inspection CSV data container with 2D indexer (exposed to script as class).
/// <para>Delphi origin: TInsCsv (CommonClass.pas) — property Data[nRow, nCol: Integer]: string</para>
/// <para>PSU usage: SummaryCsv.Data[CSV_HEAD, nCnt] → C# CSX: SummaryCsv[CSV_HEAD, nCnt]</para>
/// </summary>
public class TInsCsv
{
    private readonly string[,] _data;
    public int RowCount { get; }
    public int ColCount { get; }
    public string FileName { get; set; } = string.Empty;
    public int HeaderCnt { get; set; }

    public TInsCsv() : this(2, 250) { }

    public TInsCsv(int rows, int cols)
    {
        RowCount = rows;
        ColCount = cols;
        _data = new string[rows, cols];
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                _data[r, c] = string.Empty;
    }

    /// <summary>2D indexer — replaces Delphi property Data[nRow, nCol: Integer]: string</summary>
    public string this[int row, int col]
    {
        get => (row >= 0 && row < RowCount && col >= 0 && col < ColCount) ? _data[row, col] : string.Empty;
        set { if (row >= 0 && row < RowCount && col >= 0 && col < ColCount) _data[row, col] = value; }
    }
}

/// <summary>
/// Inspection APDR data container with 2D indexer (exposed to script as class).
/// <para>Delphi origin: TInsApdr (CommonClass.pas) — property Data[nRow, nCol: Integer]: string</para>
/// <para>PSU usage: InsApdr.Data[row, col] → C# CSX: InsApdr[row, col]</para>
/// </summary>
public class TInsApdr
{
    private readonly string[,] _data;
    public int RowCount { get; }
    public int ColCount { get; }
    public string LogHeader { get; set; } = string.Empty;

    public TInsApdr() : this(3, 450) { }

    public TInsApdr(int rows, int cols)
    {
        RowCount = rows;
        ColCount = cols;
        _data = new string[rows, cols];
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                _data[r, c] = string.Empty;
    }

    /// <summary>2D indexer — replaces Delphi property Data[nRow, nCol: Integer]: string</summary>
    public string this[int row, int col]
    {
        get => (row >= 0 && row < RowCount && col >= 0 && col < ColCount) ? _data[row, col] : string.Empty;
        set { if (row >= 0 && row < RowCount && col >= 0 && col < ColCount) _data[row, col] = value; }
    }
}

/// <summary>
/// Inspection RGB pass data (exposed to script as class).
/// <para>Delphi origin: TInsRgbPass (CommonClass.pas)</para>
/// </summary>
public class TInsRgbPass
{
    public int BandCnt { get; set; }
    public int GrayStep { get; set; }
    public List<int> R { get; set; } = new();
    public List<int> G { get; set; } = new();
    public List<int> B { get; set; } = new();
}

/// <summary>
/// OC Delta-E calculation data (exposed to script as class).
/// <para>Delphi origin: TOcDeltaE (CommonClass.pas)</para>
/// </summary>
public class TOcDeltaE
{
    public float DeltaE { get; set; }
    public float L { get; set; }
    public float a { get; set; }
    public float b { get; set; }
}

/// <summary>
/// Math helper (exposed to script as class).
/// <para>Delphi origin: TMath (CommonClass.pas)</para>
/// </summary>
public class TMath
{
    public double Value { get; set; }
    public double Result { get; set; }
}

#endregion

#region Script-exposed record types (used via DefineRecordByRTTI)

/// <summary>
/// Power measurement data record.
/// <para>Delphi origin: TPwrData (DefPG.pas)</para>
/// </summary>
public class TPwrData
{
    public int[] PWR_VOL { get; set; } = new int[8];
    public int[] PWR_CUR { get; set; } = new int[8];
}

/// <summary>
/// Gamma command record.
/// <para>Delphi origin: TGammaCmd (CommonClass.pas)</para>
/// </summary>
public class TGammaCmd
{
    public int R { get; set; }
    public int G { get; set; }
    public int B { get; set; }
}

/// <summary>
/// OC parameter record.
/// <para>Delphi origin: TOcParam (CommonClass.pas)</para>
/// </summary>
public class TOcParam
{
    public string ItemName { get; set; } = string.Empty;
    public int Idx { get; set; }
    public TGammaCmd Gamma { get; set; } = new();
    public TOcGammaVal Target { get; set; } = new();
    public TOcGammaVal Limit { get; set; } = new();
    public TOcGammaVal Ratio { get; set; } = new();
}

/// <summary>
/// Gamma value record.
/// <para>Delphi origin: TGammaVal (CommonClass.pas)</para>
/// </summary>
public class TGammaVal
{
    public float x { get; set; }
    public float y { get; set; }
    public float Lv { get; set; }
}

/// <summary>
/// Received power data record.
/// <para>Delphi origin: TRxPwrData (DefPG.pas)</para>
/// </summary>
public class TRxPwrData
{
    public int[] Vol { get; set; } = new int[8];
    public int[] Cur { get; set; } = new int[8];
}

/// <summary>
/// OTP read data record.
/// <para>Delphi origin: TOtpReadData (CommonClass.pas)</para>
/// </summary>
public class TOtpReadData
{
    public int MipiCommand { get; set; }
    public int DataLen { get; set; }
    public int Section { get; set; }
    public string OtpData { get; set; } = string.Empty;
}

/// <summary>
/// SW version record.
/// <para>Delphi origin: TSWVer (CommonClass.pas)</para>
/// </summary>
public class TSWVer
{
    public string Name { get; set; } = string.Empty;
    public string Version { get; set; } = string.Empty;
    public string Date { get; set; } = string.Empty;

    // PSU-compatible property names (Delphi original uses these)
    public string ConfigVer { get; set; } = string.Empty;
    public string SWVer { get; set; } = string.Empty;
    public string DLLVer { get; set; } = string.Empty;
}

#endregion

#region TTestInformation (full class)

/// <summary>
/// Full test information class exposed to scripts.
/// <para>Delphi origin: TTestInformation (pasScriptClass.pas line 95)</para>
/// </summary>
public class TTestInformation
{
    public string PG_Ver { get; set; } = string.Empty;
    public string SW_Ver { get; set; } = string.Empty;
    public string SW_Name { get; set; } = string.Empty;
    public string DLL_Ver { get; set; } = string.Empty;
    public string OC_Con_ver { get; set; } = string.Empty;
    public string EQPId { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string ModelConfig { get; set; } = string.Empty;
    public int Ch { get; set; }
    public string UserID { get; set; } = string.Empty;
    public bool PowerOn { get; set; }
    public bool IsScanned { get; set; }
    public bool IsReport { get; set; }
    public bool IsLoaded { get; set; }
    public bool CanSendApdr { get; set; }
    public bool bPchkResult { get; set; }
    public bool AutoMode { get; set; }
    public bool AABMode { get; set; }
    public bool Login { get; set; }
    public bool OCDllCall { get; set; }
    public bool Use_MES { get; set; }
    public bool Use_ECS { get; set; }
    public bool Use_DFS { get; set; }
    public bool Use_GIB { get; set; }
    public bool Use_FFCData { get; set; }
    public bool Use_StainData { get; set; }
    public bool Use_FTPUpload { get; set; }
    public bool Use_TemplateData { get; set; }
    public bool PreOcReStart { get; set; }
    public int ZAxis_Target { get; set; }
    public int ZAxis_Current { get; set; }
    public string CarrierId { get; set; } = string.Empty;
    public string SerialNo { get; set; } = string.Empty;
    public string MateriID { get; set; } = string.Empty;
    public string PID { get; set; } = string.Empty;
    public string RTN_PID { get; set; } = string.Empty;
    public string RTN_MODEL { get; set; } = string.Empty;
    public string LCM_ID { get; set; } = string.Empty;
    public string GlassID { get; set; } = string.Empty;
    public string Process_Code { get; set; } = string.Empty;
    public int RetryValue { get; set; }
    public int nSerialType { get; set; }
    public int Before_OtpCnt { get; set; }
    public int After_OtpCnt { get; set; }
    public string Fail_Message { get; set; } = string.Empty;
    public string Full_name { get; set; } = string.Empty;
    public string KeyIn { get; set; } = string.Empty;
    public string ERR_Code { get; set; } = string.Empty;
    public string ERR_Message { get; set; } = string.Empty;
    public string MES_Code { get; set; } = string.Empty;
    public int NgCode { get; set; }
    public bool NG_EICR { get; set; }
    public int NGAlarmCount { get; set; }
    public int RetryCount { get; set; }
    public int AlarmNGCode { get; set; }
    public string Result { get; set; } = string.Empty;
    public int OKCount { get; set; }
    public int NGCount { get; set; }
    public int PlcRet { get; set; }
    public string csvHeader { get; set; } = string.Empty;
    public string csvSubHead1 { get; set; } = string.Empty;
    public string csvSubHead2 { get; set; } = string.Empty;
    public string csvData { get; set; } = string.Empty;
    public string csvFileName { get; set; } = string.Empty;
    public double uniformity { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public DateTime PreEndTime { get; set; }
    public DateTime StUnitTact { get; set; }
    public DateTime EdUnitTact { get; set; }
    public DateTime TurnTime_CAM { get; set; }
    public DateTime TurnTime_Unload { get; set; }
    public DateTime OcSTime { get; set; }
    public DateTime OcETime { get; set; }
    public bool Log_WritePOCB { get; set; }
    public bool Test_Repeat { get; set; }
    public int CsvHeaderCnt { get; set; }
    public TInsCsv InsCsv { get; set; } = new();
    public TInsApdr InsApdr { get; set; } = new();
    public string ApdrData { get; set; } = string.Empty;
    public string ApdrLogHeader { get; set; } = string.Empty;
    public double[] FFCData { get; set; } = new double[51];
    public double[] INFOData { get; set; } = new double[151];
    public double CCD_TEMP { get; set; }
    public bool SIM_Use_PG { get; set; }
    public bool SIM_Use_DIO { get; set; }
    public bool SIM_Use_PLC { get; set; }
    public bool SIM_Use_CAM { get; set; }
    public double Final_x { get; set; }
    public double Final_y { get; set; }
    public double Final_Lv { get; set; }
    public int GIB_Test { get; set; }
    public int nPwrVCC { get; set; }
    public int nPwrVIN { get; set; }
    public int nPwrVDD3 { get; set; }
    public int[] Temp_Sensor { get; set; } = new int[6];
    public bool IDLEMode { get; set; }

    /// <summary>
    /// Returns measure time in milliseconds (elapsed since StartTime).
    /// <para>Delphi origin: function TTestInformation.Get_MeasureTime: Integer</para>
    /// </summary>
    public int MeasureTime => (int)(DateTime.Now - StartTime).TotalMilliseconds;
}

#endregion
