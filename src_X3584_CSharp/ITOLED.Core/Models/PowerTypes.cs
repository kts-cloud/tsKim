// =============================================================================
// PowerTypes.cs
// Converted from Delphi: src_X3584\CommonClass.pas
// Contains: TPowerCalibaration (line 606), TFrame (line 378),
//           TModelParamPucDataFlash (line 656), TLGD_DGMA_Parameter (line 383)
// Note: TBmpAddInfo and TModelParamSerialNoFlash are defined in ModelTypes.cs
// =============================================================================

using System.Collections.Generic;

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// Power calibration correction values.
    /// <para>Original Delphi: TPowerCalibaration = record (CommonClass.pas line 606)</para>
    /// </summary>
    public class PowerCalibration
    {
        /// <summary>
        /// VPNL calibration value.
        /// <para>Delphi field: VPNL : Integer</para>
        /// </summary>
        public int VPNL { get; set; }

        /// <summary>
        /// VDDI calibration value.
        /// <para>Delphi field: VDDI : Integer</para>
        /// </summary>
        public int VDDI { get; set; }

        /// <summary>
        /// T_AV calibration value.
        /// <para>Delphi field: T_AV : Integer</para>
        /// </summary>
        public int TAV { get; set; }

        /// <summary>
        /// VPP calibration value.
        /// <para>Delphi field: VPP : Integer</para>
        /// </summary>
        public int VPP { get; set; }

        /// <summary>
        /// VBAT calibration value.
        /// <para>Delphi field: VBAT : Integer</para>
        /// </summary>
        public int VBAT { get; set; }

        /// <summary>
        /// VCI calibration value.
        /// <para>Delphi field: VCI : Integer</para>
        /// </summary>
        public int VCI { get; set; }

        /// <summary>
        /// VDDEL calibration value.
        /// <para>Delphi field: VDDEL : Integer</para>
        /// </summary>
        public int VDDEL { get; set; }

        /// <summary>
        /// VSSEL calibration value.
        /// <para>Delphi field: VSSEL : Integer</para>
        /// </summary>
        public int VSSEL { get; set; }

        /// <summary>
        /// DDVHD calibration value.
        /// <para>Delphi field: DDVHD : Integer</para>
        /// </summary>
        public int DDVHD { get; set; }
    }

    /// <summary>
    /// Raw data frame container.
    /// <para>Original Delphi: TFrame = record (CommonClass.pas line 378)</para>
    /// </summary>
    public class Frame
    {
        /// <summary>
        /// Raw byte data.
        /// <para>Delphi field: RawData : array of Byte</para>
        /// </summary>
        public List<byte> RawData { get; set; } = new List<byte>();

        /// <summary>
        /// Data length.
        /// <para>Delphi field: DataLength : Integer</para>
        /// </summary>
        public int DataLength { get; set; }
    }

    /// <summary>
    /// PUC data flash parameter configuration.
    /// <para>Original Delphi: TModelParamPucDataFlash = record (CommonClass.pas line 656)</para>
    /// </summary>
    public class ModelParamPucDataFlash
    {
        /// <summary>
        /// PUC data get address (valid if ParamCsvInfo.FormatType is 0 - BeforeDevBuild).
        /// <para>Delphi field: PucDataGetAddr : DWORD</para>
        /// </summary>
        public uint PucDataGetAddr { get; set; }

        /// <summary>
        /// PUC data address (valid if ParamCsvInfo.FormatType is 1 - DevBuild).
        /// <para>Delphi field: PucDataAddr : DWORD</para>
        /// </summary>
        public uint PucDataAddr { get; set; }

        /// <summary>
        /// PUC data size.
        /// <para>Delphi field: PucDataSize : DWORD</para>
        /// </summary>
        public uint PucDataSize { get; set; }
    }

    /// <summary>
    /// LGD DGMA parameter record for gamma characterization.
    /// <para>Original Delphi: TLGD_DGMA_Parameter = packed record (CommonClass.pas line 383)</para>
    /// </summary>
    public class LgdDgmaParameter
    {
        /// <summary>
        /// Index.
        /// <para>Delphi field: nIdx : Integer</para>
        /// </summary>
        public int Idx { get; set; }

        /// <summary>
        /// Band name.
        /// <para>Delphi field: Band : string</para>
        /// </summary>
        public string Band { get; set; } = string.Empty;

        /// <summary>
        /// Tap value.
        /// <para>Delphi field: Tap : integer</para>
        /// </summary>
        public int Tap { get; set; }

        /// <summary>
        /// Gray level.
        /// <para>Delphi field: Gray : Integer</para>
        /// </summary>
        public int Gray { get; set; }

        /// <summary>
        /// Gamma red value.
        /// <para>Delphi field: Gamma_R : string</para>
        /// </summary>
        public string GammaR { get; set; } = string.Empty;

        /// <summary>
        /// Gamma green value.
        /// <para>Delphi field: Gamma_G : string</para>
        /// </summary>
        public string GammaG { get; set; } = string.Empty;

        /// <summary>
        /// Gamma blue value.
        /// <para>Delphi field: Gamma_B : string</para>
        /// </summary>
        public string GammaB { get; set; } = string.Empty;

        /// <summary>
        /// Target x coordinate.
        /// <para>Delphi field: Target_x : string</para>
        /// </summary>
        public string TargetX { get; set; } = string.Empty;

        /// <summary>
        /// Target y coordinate.
        /// <para>Delphi field: Target_y : string</para>
        /// </summary>
        public string TargetY { get; set; } = string.Empty;

        /// <summary>
        /// Target luminance value.
        /// <para>Delphi field: Target_Lv : string</para>
        /// </summary>
        public string TargetLv { get; set; } = string.Empty;
    }
}
