// =============================================================================
// InspectionTypes.cs
// Converted from Delphi: src_X3584\CommonClass.pas
// Contains: TOcInfo (line 309), TOcParam (line 341), TOcParams (line 350),
//           TGammaVal (line 320), TGammaCmd (line 326), TGammaAvg (line 332),
//           TRgbAvgData (line 356), TOtpRead (line 367), TOtpReadData (line 361),
//           TOffsetTable (line 371), TCalVal (line 304)
// =============================================================================

using System.Collections.Generic;
using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// Calibration value (x, y, Lv as strings).
    /// <para>Original Delphi: TCalVal = record (CommonClass.pas line 304)</para>
    /// </summary>
    public class CalVal
    {
        /// <summary>
        /// CIE x chromaticity coordinate.
        /// <para>Delphi field: x : string</para>
        /// </summary>
        public string X { get; set; } = string.Empty;

        /// <summary>
        /// CIE y chromaticity coordinate.
        /// <para>Delphi field: y : string</para>
        /// </summary>
        public string Y { get; set; } = string.Empty;

        /// <summary>
        /// Luminance value (Lv).
        /// <para>Delphi field: Lv : string</para>
        /// </summary>
        public string Lv { get; set; } = string.Empty;
    }

    /// <summary>
    /// Optic (colorimeter) calibration configuration.
    /// <para>Original Delphi: TOcInfo = record (CommonClass.pas line 309)</para>
    /// </summary>
    public class OcInfo
    {
        /// <summary>
        /// Calibration model type.
        /// <para>Delphi field: CalModelType : Integer</para>
        /// </summary>
        public int CalModelType { get; set; }

        /// <summary>
        /// Calibration data selection string.
        /// <para>Delphi field: CalDataSel : string</para>
        /// </summary>
        public string CalDataSel { get; set; } = string.Empty;

        /// <summary>
        /// Calibration targets (White, R, G, B).
        /// <para>Delphi field: CalTarget : array[0..pred(MAX_CA310_CAL_ITEM)] of TCalVal</para>
        /// </summary>
        public CalVal[] CalTarget { get; set; }

        /// <summary>
        /// Calibration memory channel assignments.
        /// <para>Delphi field: CalMemCh : array[CH1..pred(MAX_CA310_CAL_ITEM)] of Integer</para>
        /// </summary>
        public int[] CalMemCh { get; set; }

        /// <summary>
        /// Calibration aging time.
        /// <para>Delphi field: CalAgingTime : Integer</para>
        /// </summary>
        public int CalAgingTime { get; set; }

        /// <summary>
        /// Calibration RGBW aging time.
        /// <para>Delphi field: CalRgbwAgingTm : Integer</para>
        /// </summary>
        public int CalRgbwAgingTime { get; set; }

        /// <summary>
        /// Calibration retry count.
        /// <para>Delphi field: CalRetryCnt : Integer</para>
        /// </summary>
        public int CalRetryCount { get; set; }

        /// <summary>
        /// Initializes arrays with proper sizes based on DefCommon constants.
        /// </summary>
        public OcInfo()
        {
            CalTarget = new CalVal[CaConstants.MaxCa310CalItem];
            for (int i = 0; i < CalTarget.Length; i++)
                CalTarget[i] = new CalVal();

            // CalMemCh: CH1 to pred(MAX_CA310_CAL_ITEM) = 0 to 3
            CalMemCh = new int[CaConstants.MaxCa310CalItem];
        }
    }

    /// <summary>
    /// Gamma measurement value (x, y, Lv as floats).
    /// <para>Original Delphi: TGammaVal = record (CommonClass.pas line 320)</para>
    /// </summary>
    public class GammaVal
    {
        /// <summary>
        /// CIE x chromaticity coordinate.
        /// <para>Delphi field: x : Single</para>
        /// </summary>
        public float X { get; set; }

        /// <summary>
        /// CIE y chromaticity coordinate.
        /// <para>Delphi field: y : Single</para>
        /// </summary>
        public float Y { get; set; }

        /// <summary>
        /// Luminance value (Lv).
        /// <para>Delphi field: Lv : Single</para>
        /// </summary>
        public float Lv { get; set; }
    }

    /// <summary>
    /// Gamma RGB command (R, G, B integer values).
    /// <para>Original Delphi: TGammaCmd = record (CommonClass.pas line 326)</para>
    /// </summary>
    public class GammaCmd
    {
        /// <summary>
        /// Red value.
        /// <para>Delphi field: R : Integer</para>
        /// </summary>
        public int R { get; set; }

        /// <summary>
        /// Green value.
        /// <para>Delphi field: G : Integer</para>
        /// </summary>
        public int G { get; set; }

        /// <summary>
        /// Blue value.
        /// <para>Delphi field: B : Integer</para>
        /// </summary>
        public int B { get; set; }
    }

    /// <summary>
    /// Gamma average data configuration.
    /// <para>Original Delphi: TGammaAvg = record (CommonClass.pas line 332)</para>
    /// </summary>
    public class GammaAvg
    {
        /// <summary>
        /// Average type.
        /// <para>Delphi field: AvgType : Integer</para>
        /// </summary>
        public int AvgType { get; set; }

        /// <summary>
        /// NG code: 0=OK, 1=File Load NG, 2=...
        /// <para>Delphi field: NgCode : Integer</para>
        /// </summary>
        public int NgCode { get; set; }

        /// <summary>
        /// Average row count.
        /// <para>Delphi field: AvgRowCnt : Integer</para>
        /// </summary>
        public int AvgRowCnt { get; set; }

        /// <summary>
        /// Average column count (Band x GrayStep + Channel number).
        /// <para>Delphi field: AvgColCnt : Integer</para>
        /// </summary>
        public int AvgColCnt { get; set; }

        /// <summary>
        /// Band count.
        /// <para>Delphi field: Band : Integer</para>
        /// </summary>
        public int Band { get; set; }

        /// <summary>
        /// Gray step count.
        /// <para>Delphi field: GrayStep : Integer</para>
        /// </summary>
        public int GrayStep { get; set; }

        /// <summary>
        /// Average gamma command data.
        /// <para>Delphi field: AvgGamma : array of TGammaCmd</para>
        /// </summary>
        public List<GammaCmd> AvgGamma { get; set; } = new List<GammaCmd>();
    }

    /// <summary>
    /// OC parameter item (target, limit, ratio for a named inspection item).
    /// <para>Original Delphi: TOcParam = record (CommonClass.pas line 341)</para>
    /// </summary>
    public class OcParam
    {
        /// <summary>
        /// Item name.
        /// <para>Delphi field: ItemName : string</para>
        /// </summary>
        public string ItemName { get; set; } = string.Empty;

        /// <summary>
        /// Item index.
        /// <para>Delphi field: Idx : Integer</para>
        /// </summary>
        public int Idx { get; set; }

        /// <summary>
        /// Gamma RGB command.
        /// <para>Delphi field: Gamma : TGammaCmd</para>
        /// </summary>
        public GammaCmd Gamma { get; set; } = new GammaCmd();

        /// <summary>
        /// Target values (x, y, Lv).
        /// <para>Delphi field: Target : TGammaVal</para>
        /// </summary>
        public GammaVal Target { get; set; } = new GammaVal();

        /// <summary>
        /// Limit values (x, y, Lv).
        /// <para>Delphi field: Limit : TGammaVal</para>
        /// </summary>
        public GammaVal Limit { get; set; } = new GammaVal();

        /// <summary>
        /// Ratio values (x, y, Lv).
        /// <para>Delphi field: Ratio : TGammaVal</para>
        /// </summary>
        public GammaVal Ratio { get; set; } = new GammaVal();
    }

    /// <summary>
    /// Collection of OC parameters and verification parameters.
    /// <para>Original Delphi: TOcParams = record (CommonClass.pas line 350)</para>
    /// </summary>
    public class OcParams
    {
        /// <summary>
        /// OC parameter count.
        /// <para>Delphi field: IdxOcPCnt : Integer</para>
        /// </summary>
        public int IdxOcPCnt { get; set; }

        /// <summary>
        /// OC verify parameter count.
        /// <para>Delphi field: IdxOcVCnt : Integer</para>
        /// </summary>
        public int IdxOcVCnt { get; set; }

        /// <summary>
        /// OC parameter list.
        /// <para>Delphi field: OcParam : array of TOcParam</para>
        /// </summary>
        public List<OcParam> OcParamList { get; set; } = new List<OcParam>();

        /// <summary>
        /// OC verification parameter list.
        /// <para>Delphi field: OcVerify : array of TOcParam</para>
        /// </summary>
        public List<OcParam> OcVerify { get; set; } = new List<OcParam>();
    }

    /// <summary>
    /// RGB average measurement data.
    /// <para>Original Delphi: TRgbAvgData = record (CommonClass.pas line 356)</para>
    /// </summary>
    public class RgbAvgData
    {
        /// <summary>
        /// Whether data is ready for use.
        /// <para>Delphi field: IsReady : boolean</para>
        /// </summary>
        public bool IsReady { get; set; }

        /// <summary>
        /// OC parameter count.
        /// <para>Delphi field: IdxOcPCnt : Integer</para>
        /// </summary>
        public int IdxOcPCnt { get; set; }

        /// <summary>
        /// Gamma command data.
        /// <para>Delphi field: Gamma : array of TGammaCmd</para>
        /// </summary>
        public List<GammaCmd> Gamma { get; set; } = new List<GammaCmd>();
    }

    /// <summary>
    /// Single OTP read command data.
    /// <para>Original Delphi: TOtpReadData = record (CommonClass.pas line 361)</para>
    /// </summary>
    public class OtpReadData
    {
        /// <summary>
        /// MIPI command value.
        /// <para>Delphi field: MipiCommand : Integer</para>
        /// </summary>
        public int MipiCommand { get; set; }

        /// <summary>
        /// Data length.
        /// <para>Delphi field: DataLen : Integer</para>
        /// </summary>
        public int DataLen { get; set; }

        /// <summary>
        /// Section identifier.
        /// <para>Delphi field: Section : Integer</para>
        /// </summary>
        public int Section { get; set; }

        /// <summary>
        /// OTP data string.
        /// <para>Delphi field: OtpData : string</para>
        /// </summary>
        public string OtpData { get; set; } = string.Empty;
    }

    /// <summary>
    /// OTP read configuration with multiple commands.
    /// <para>Original Delphi: TOtpRead = record (CommonClass.pas line 367)</para>
    /// </summary>
    public class OtpRead
    {
        /// <summary>
        /// Number of OTP commands.
        /// <para>Delphi field: CommandCnt : Integer</para>
        /// </summary>
        public int CommandCnt { get; set; }

        /// <summary>
        /// OTP read data entries.
        /// <para>Delphi field: Data : array of TOtpReadData</para>
        /// </summary>
        public List<OtpReadData> Data { get; set; } = new List<OtpReadData>();
    }

    /// <summary>
    /// Offset table entry (RGB values with target and limit coordinates).
    /// <para>Original Delphi: TOffsetTable = record (CommonClass.pas line 371)</para>
    /// </summary>
    public class OffsetTable
    {
        /// <summary>
        /// Index.
        /// <para>Delphi field: nIdx : Integer</para>
        /// </summary>
        public int Idx { get; set; }

        /// <summary>
        /// Red value.
        /// <para>Delphi field: R : Integer</para>
        /// </summary>
        public int R { get; set; }

        /// <summary>
        /// Green value.
        /// <para>Delphi field: G : Integer</para>
        /// </summary>
        public int G { get; set; }

        /// <summary>
        /// Blue value.
        /// <para>Delphi field: B : Integer</para>
        /// </summary>
        public int B { get; set; }

        /// <summary>
        /// Offset value.
        /// <para>Delphi field: OffSet : Integer</para>
        /// </summary>
        public int Offset { get; set; }

        /// <summary>
        /// Target x coordinate.
        /// <para>Delphi field: Tx : Single</para>
        /// </summary>
        public float Tx { get; set; }

        /// <summary>
        /// Target y coordinate.
        /// <para>Delphi field: Ty : Single</para>
        /// </summary>
        public float Ty { get; set; }

        /// <summary>
        /// Target luminance.
        /// <para>Delphi field: TL : Single</para>
        /// </summary>
        public float TL { get; set; }

        /// <summary>
        /// Limit x coordinate.
        /// <para>Delphi field: Lx : Single</para>
        /// </summary>
        public float Lx { get; set; }

        /// <summary>
        /// Limit y coordinate.
        /// <para>Delphi field: Ly : Single</para>
        /// </summary>
        public float Ly { get; set; }

        /// <summary>
        /// Limit luminance value.
        /// <para>Delphi field: LLv : Single</para>
        /// </summary>
        public float LLv { get; set; }
    }
}
