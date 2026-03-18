// =============================================================================
// VersionInfo.cs
// Converted from Delphi: src_X3584\CommonClass.pas (lines 39-44, 281-303, 619-645)
// Contains: TSWVer, TVer, TInterlockInfo, TOnLineInterlockInfo
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// Software version information.
    /// <para>Original Delphi: TSWVer = packed record (CommonClass.pas line 40)</para>
    /// </summary>
    public class SWVersion
    {
        /// <summary>
        /// Configuration version string.
        /// <para>Delphi field: ConfigVer : string</para>
        /// </summary>
        public string ConfigVer { get; set; } = string.Empty;

        /// <summary>
        /// Software version string.
        /// <para>Delphi field: SWVer : string</para>
        /// </summary>
        public string SWVer { get; set; } = string.Empty;

        /// <summary>
        /// DLL version string.
        /// <para>Delphi field: DLLVer : string</para>
        /// </summary>
        public string DLLVer { get; set; } = string.Empty;
    }

    /// <summary>
    /// Version tracking record for firmware, scripts, CRC values, and OC parameter files.
    /// <para>Original Delphi: TVer = record (CommonClass.pas line 281)</para>
    /// </summary>
    public class VersionRecord
    {
        /// <summary>
        /// PSU date string.
        /// <para>Delphi field: psu_Date : string</para>
        /// </summary>
        public string PsuDate { get; set; } = string.Empty;

        /// <summary>
        /// PSU CRC string.
        /// <para>Delphi field: psu_Crc : string</para>
        /// </summary>
        public string PsuCrc { get; set; } = string.Empty;

        /// <summary>
        /// ISU date string.
        /// <para>Delphi field: isu_Date : string</para>
        /// </summary>
        public string IsuDate { get; set; } = string.Empty;

        /// <summary>
        /// ISU CRC string.
        /// <para>Delphi field: isu_Crc : string</para>
        /// </summary>
        public string IsuCrc { get; set; } = string.Empty;

        /// <summary>
        /// Hardware version per channel (CH1..MAX_CH).
        /// <para>Delphi field: HwVer : array[DefCommon.CH1 .. DefCommon.MAX_CH] of string</para>
        /// </summary>
        public string[] HwVer { get; set; }

        /// <summary>
        /// OC parameter version string.
        /// <para>Delphi field: OcParam : string</para>
        /// </summary>
        public string OcParam { get; set; } = string.Empty;

        /// <summary>
        /// OC verify version string.
        /// <para>Delphi field: OcVerify : string</para>
        /// </summary>
        public string OcVerify { get; set; } = string.Empty;

        /// <summary>
        /// OTP table version string.
        /// <para>Delphi field: OtpTable : string</para>
        /// </summary>
        public string OtpTable { get; set; } = string.Empty;

        /// <summary>
        /// OC offset version string.
        /// <para>Delphi field: OcOffSet : string</para>
        /// </summary>
        public string OcOffset { get; set; } = string.Empty;

        /// <summary>
        /// MES CSV version string.
        /// <para>Delphi field: MES_CSV : string</para>
        /// </summary>
        public string MesCsv { get; set; } = string.Empty;

        /// <summary>
        /// AA Mode CSV version string.
        /// <para>Delphi field: AA_MODE_CSV : string</para>
        /// </summary>
        public string AAModeCsv { get; set; } = string.Empty;

        /// <summary>
        /// CRC for miau file.
        /// <para>Delphi field: CRC_miau : Word</para>
        /// </summary>
        public ushort CrcMiau { get; set; }

        /// <summary>
        /// CRC for mioff file.
        /// <para>Delphi field: CRC_mioff : Word</para>
        /// </summary>
        public ushort CrcMioff { get; set; }

        /// <summary>
        /// CRC for mion file.
        /// <para>Delphi field: CRC_mion : Word</para>
        /// </summary>
        public ushort CrcMion { get; set; }

        /// <summary>
        /// CRC for mpt file.
        /// <para>Delphi field: CRC_mpt : Word</para>
        /// </summary>
        public ushort CrcMpt { get; set; }

        /// <summary>
        /// CRC for otpr file.
        /// <para>Delphi field: CRC_otpr : Word</para>
        /// </summary>
        public ushort CrcOtpr { get; set; }

        /// <summary>
        /// CRC for otpw file.
        /// <para>Delphi field: CRC_otpw : Word</para>
        /// </summary>
        public ushort CrcOtpw { get; set; }

        /// <summary>
        /// CRC for pwoff file.
        /// <para>Delphi field: CRC_pwoff : Word</para>
        /// </summary>
        public ushort CrcPwoff { get; set; }

        /// <summary>
        /// CRC for pwon file.
        /// <para>Delphi field: CRC_pwon : Word</para>
        /// </summary>
        public ushort CrcPwon { get; set; }

        /// <summary>
        /// CRC for misc file.
        /// <para>Delphi field: CRC_misc : Word</para>
        /// </summary>
        public ushort CrcMisc { get; set; }

        /// <summary>
        /// CRC for Pattern Group.
        /// <para>Delphi field: CRC_Pat : Word</para>
        /// </summary>
        public ushort CrcPat { get; set; }

        /// <summary>
        /// Initializes arrays with proper sizes based on DefCommon constants.
        /// </summary>
        public VersionRecord()
        {
            HwVer = new string[ChannelConstants.MaxCh + 1];
            for (int i = 0; i < HwVer.Length; i++)
                HwVer[i] = string.Empty;
        }
    }

    /// <summary>
    /// Interlock version information for offline verification.
    /// <para>Original Delphi: TInterlockInfo = packed record (CommonClass.pas line 619)</para>
    /// </summary>
    public class InterlockInfo
    {
        /// <summary>
        /// Whether version interlock is enabled.
        /// <para>Delphi field: Use : Boolean</para>
        /// </summary>
        public bool Use { get; set; }

        /// <summary>
        /// Software version for interlock.
        /// <para>Delphi field: Version_SW : String</para>
        /// </summary>
        public string VersionSW { get; set; } = string.Empty;

        /// <summary>
        /// Script version for interlock.
        /// <para>Delphi field: Version_Script : string</para>
        /// </summary>
        public string VersionScript { get; set; } = string.Empty;

        /// <summary>
        /// Firmware version for interlock.
        /// <para>Delphi field: Version_FW : string</para>
        /// </summary>
        public string VersionFW { get; set; } = string.Empty;

        /// <summary>
        /// FPGA version for interlock.
        /// <para>Delphi field: Version_FPGA : string</para>
        /// </summary>
        public string VersionFPGA { get; set; } = string.Empty;

        /// <summary>
        /// Power version for interlock.
        /// <para>Delphi field: Version_Power : string</para>
        /// </summary>
        public string VersionPower { get; set; } = string.Empty;

        /// <summary>
        /// DLL version for interlock.
        /// <para>Delphi field: Version_DLL : string</para>
        /// </summary>
        public string VersionDLL { get; set; } = string.Empty;

        /// <summary>
        /// LGD DLL version for interlock.
        /// <para>Delphi field: Version_LGDDLL : string</para>
        /// </summary>
        public string VersionLGDDLL { get; set; } = string.Empty;
    }

    /// <summary>
    /// Online interlock version information (LPIR-related).
    /// <para>Original Delphi: TOnLineInterlockInfo = packed record (CommonClass.pas line 630)</para>
    /// </summary>
    public class OnLineInterlockInfo
    {
        /// <summary>
        /// Whether online interlock is enabled.
        /// <para>Delphi field: Use : Boolean</para>
        /// </summary>
        public bool Use { get; set; }

        /// <summary>
        /// Process code for LPIR.
        /// <para>Delphi field: Process_Code : String</para>
        /// </summary>
        public string ProcessCode { get; set; } = string.Empty;

        /// <summary>
        /// Process index.
        /// <para>Delphi field: Process_Index : Integer</para>
        /// </summary>
        public int ProcessIndex { get; set; }

        /// <summary>
        /// INI file name.
        /// <para>Delphi field: sINIFileName : String</para>
        /// </summary>
        public string IniFileName { get; set; } = string.Empty;

        /// <summary>
        /// INI download time.
        /// <para>Delphi field: sINIDownTime : String</para>
        /// </summary>
        public string IniDownTime { get; set; } = string.Empty;

        /// <summary>
        /// Software version.
        /// <para>Delphi field: Version_SW : String</para>
        /// </summary>
        public string VersionSW { get; set; } = string.Empty;

        /// <summary>
        /// Software version name.
        /// <para>Delphi field: Version_SW_Name : string</para>
        /// </summary>
        public string VersionSWName { get; set; } = string.Empty;

        /// <summary>
        /// Model version.
        /// <para>Delphi field: Version_Model : string</para>
        /// </summary>
        public string VersionModel { get; set; } = string.Empty;

        /// <summary>
        /// Firmware version.
        /// <para>Delphi field: Version_FW : string</para>
        /// </summary>
        public string VersionFW { get; set; } = string.Empty;

        /// <summary>
        /// FPGA version.
        /// <para>Delphi field: Version_FPGA : string</para>
        /// </summary>
        public string VersionFPGA { get; set; } = string.Empty;

        /// <summary>
        /// Power version.
        /// <para>Delphi field: Version_Power : string</para>
        /// </summary>
        public string VersionPower { get; set; } = string.Empty;

        /// <summary>
        /// DLL version.
        /// <para>Delphi field: Version_DLL : string</para>
        /// </summary>
        public string VersionDLL { get; set; } = string.Empty;

        /// <summary>
        /// LGD DLL version.
        /// <para>Delphi field: Version_LGDDLL : string</para>
        /// </summary>
        public string VersionLGDDLL { get; set; } = string.Empty;

        /// <summary>
        /// Script version.
        /// <para>Delphi field: Version_Script : string</para>
        /// </summary>
        public string VersionScript { get; set; } = string.Empty;
    }
}
