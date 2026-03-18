// =============================================================================
// ModelTypes.cs
// Converted from Delphi: src_X3584\CommonClass.pas
// Contains: TModelInfo (line 420), TModelInfo2 (line 454), TModelInfoPG (line 646),
//           TModelInfoFLOW (line 663), TPatternGroup (line 249), TPatternData (line 475),
//           TPatToolInfo (line 468), TPatterGroup (line 483)
// =============================================================================

using System.Collections.Generic;
using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// BMP additional information for AF9-FPGA pattern configuration.
    /// <para>Original Delphi: TBmpAddInfo = record (CommonClass.pas line 237)</para>
    /// </summary>
    public class BmpAddInfo
    {
        /// <summary>
        /// AF9 API BMP number.
        /// <para>Delphi field: BmpDownNum : integer</para>
        /// </summary>
        public int BmpDownNum { get; set; }

        /// <summary>
        /// AF9 API dot pattern type: 0=NoDotPat, 1=DotPatRGB, 2=LineDotPatRGB.
        /// <para>Delphi field: DotPatType : integer</para>
        /// </summary>
        public int DotPatType { get; set; }

        /// <summary>Foreground red value. <para>Delphi field: FR : Integer</para></summary>
        public int FR { get; set; }

        /// <summary>Foreground green value. <para>Delphi field: FG : Integer</para></summary>
        public int FG { get; set; }

        /// <summary>Foreground blue value. <para>Delphi field: FB : Integer</para></summary>
        public int FB { get; set; }

        /// <summary>Background red value. <para>Delphi field: BR : Integer</para></summary>
        public int BR { get; set; }

        /// <summary>Background green value. <para>Delphi field: BG : Integer</para></summary>
        public int BG { get; set; }

        /// <summary>Background blue value. <para>Delphi field: BB : Integer</para></summary>
        public int BB { get; set; }
    }

    /// <summary>
    /// Serial number flash parameter (address and length).
    /// <para>Original Delphi: TModelParamSerialNoFlash = record (CommonClass.pas line 244)</para>
    /// </summary>
    public class ModelParamSerialNoFlash
    {
        /// <summary>
        /// Flash address for serial number.
        /// <para>Delphi field: nAddr : DWORD</para>
        /// </summary>
        public uint Address { get; set; }

        /// <summary>
        /// Data length.
        /// <para>Delphi field: nLength : DWORD</para>
        /// </summary>
        public uint Length { get; set; }
    }

    /// <summary>
    /// Primary model information (resolution, timing, power settings for the PG hardware).
    /// <para>Original Delphi: TModelInfo = packed record (CommonClass.pas line 420)</para>
    /// </summary>
    public class ModelInfo
    {
        /// <summary>
        /// Signal type: 0=3-3-2, 1=4-4-4, 2=5-6-5, 3=6-6-6, 4=8-8-8.
        /// <para>Delphi field: SigType : Byte</para>
        /// </summary>
        public byte SigType { get; set; }

        /// <summary>
        /// Pixel clock frequency.
        /// <para>Delphi field: Freq : Longword</para>
        /// </summary>
        public uint Freq { get; set; }

        /// <summary>
        /// Horizontal active pixels.
        /// <para>Delphi field: H_Active : Word</para>
        /// </summary>
        public ushort HActive { get; set; }

        /// <summary>
        /// Horizontal back porch.
        /// <para>Delphi field: H_BP : Word</para>
        /// </summary>
        public ushort HBP { get; set; }

        /// <summary>
        /// Horizontal sync width.
        /// <para>Delphi field: H_Width : Word</para>
        /// </summary>
        public ushort HWidth { get; set; }

        /// <summary>
        /// Horizontal front porch.
        /// <para>Delphi field: H_FP : Word</para>
        /// </summary>
        public ushort HFP { get; set; }

        /// <summary>
        /// Vertical active lines.
        /// <para>Delphi field: V_Active : Word</para>
        /// </summary>
        public ushort VActive { get; set; }

        /// <summary>
        /// Vertical back porch.
        /// <para>Delphi field: V_BP : Word</para>
        /// </summary>
        public ushort VBP { get; set; }

        /// <summary>
        /// Vertical sync width.
        /// <para>Delphi field: V_Width : Word</para>
        /// </summary>
        public ushort VWidth { get; set; }

        /// <summary>
        /// Vertical front porch.
        /// <para>Delphi field: V_FP : Word</para>
        /// </summary>
        public ushort VFP { get; set; }

        /// <summary>
        /// ELVDD voltage.
        /// <para>Delphi field: ELVDD : Word</para>
        /// </summary>
        public ushort ELVDD { get; set; }

        /// <summary>
        /// ELVSS voltage.
        /// <para>Delphi field: ELVSS : Word</para>
        /// </summary>
        public ushort ELVSS { get; set; }

        /// <summary>
        /// DDVDH voltage.
        /// <para>Delphi field: DDVDH : Word</para>
        /// </summary>
        public ushort DDVDH { get; set; }

        /// <summary>
        /// Dummy/padding byte.
        /// <para>Delphi field: dummy : Byte</para>
        /// </summary>
        public byte Dummy { get; set; }

        /// <summary>
        /// Power voltage settings (6 rails). 1 = 10mV, range 0~1200 = 0~12V.
        /// <para>Delphi field: PWR_VOL : array[0..5] of Word</para>
        /// </summary>
        public ushort[] PwrVol { get; set; } = new ushort[6];

        /// <summary>
        /// Power current high limits (6 rails). 1 = 1mA, range 0~10000 = 0~10A.
        /// <para>Delphi field: PWR_CUR_HL : array[0..5] of Word</para>
        /// </summary>
        public ushort[] PwrCurHL { get; set; } = new ushort[6];

        /// <summary>
        /// Power current low limits (6 rails). 1 = 1mA, range 0~10000 = 0~10A.
        /// <para>Delphi field: PWR_CUR_LL : array[0..5] of Word</para>
        /// </summary>
        public ushort[] PwrCurLL { get; set; } = new ushort[6];

        /// <summary>
        /// Power voltage high limits (6 rails). 1 = 10mV, range 0~1200 = 0~12V.
        /// <para>Delphi field: PWR_VOL_HL : array[0..5] of Word</para>
        /// </summary>
        public ushort[] PwrVolHL { get; set; } = new ushort[6];

        /// <summary>
        /// Power voltage low limits (6 rails). 1 = 10mV, range 0~1200 = 0~12V.
        /// <para>Delphi field: PWR_VOL_LL : array[0..5] of Word</para>
        /// </summary>
        public ushort[] PwrVolLL { get; set; } = new ushort[6];

        /// <summary>
        /// Secondary power voltage high limits (3 rails). 1 = 1mA.
        /// <para>Delphi field: PWR_VOL_HL2 : array[0..2] of Word</para>
        /// </summary>
        public ushort[] PwrVolHL2 { get; set; } = new ushort[3];

        /// <summary>
        /// Secondary power voltage low limits (3 rails). 1 = 1mA.
        /// <para>Delphi field: PWR_VOL_LL2 : array[0..2] of Word</para>
        /// </summary>
        public ushort[] PwrVolLL2 { get; set; } = new ushort[3];

        /// <summary>
        /// Secondary power current high limits (3 rails). 1 = 10mV.
        /// <para>Delphi field: PWR_CUR_HL2 : array[0..2] of Word</para>
        /// </summary>
        public ushort[] PwrCurHL2 { get; set; } = new ushort[3];

        /// <summary>
        /// Secondary power current low limits (3 rails). 1 = 10mV.
        /// <para>Delphi field: PWR_CUR_LL2 : array[0..2] of Word</para>
        /// </summary>
        public ushort[] PwrCurLL2 { get; set; } = new ushort[3];

        /// <summary>
        /// Reserved bytes.
        /// <para>Delphi field: Reverse : array[0..15] of Byte</para>
        /// </summary>
        public byte[] Reserved { get; set; } = new byte[16];
    }

    /// <summary>
    /// Secondary model info (pattern group, config name, checksum).
    /// <para>Original Delphi: TModelInfo2 = record (CommonClass.pas line 454)</para>
    /// </summary>
    public class ModelInfo2
    {
        /// <summary>
        /// Pattern group name.
        /// <para>Delphi field: PatGrpName : string</para>
        /// </summary>
        public string PatGrpName { get; set; } = string.Empty;

        /// <summary>
        /// Configuration name.
        /// <para>Delphi field: ConfigName : string</para>
        /// </summary>
        public string ConfigName { get; set; } = string.Empty;

        /// <summary>
        /// Checksum string.
        /// <para>Delphi field: CheckSum : string</para>
        /// </summary>
        public string CheckSum { get; set; } = string.Empty;

        /// <summary>
        /// Z-axis configuration value.
        /// <para>Delphi field: Zxis : Integer</para>
        /// </summary>
        public int ZAxis { get; set; }
    }

    /// <summary>
    /// Pattern tool information for pattern group download.
    /// <para>Original Delphi: TPatToolInfo = record (CommonClass.pas line 468)</para>
    /// </summary>
    public class PatToolInfo
    {
        /// <summary>
        /// Tool identifier.
        /// <para>Delphi field: ToolId : Byte</para>
        /// </summary>
        public byte ToolId { get; set; }

        /// <summary>
        /// Direction.
        /// <para>Delphi field: Direction : byte</para>
        /// </summary>
        public byte Direction { get; set; }

        /// <summary>
        /// Level.
        /// <para>Delphi field: Level : Word</para>
        /// </summary>
        public ushort Level { get; set; }

        /// <summary>
        /// Start X coordinate.
        /// <para>Delphi field: Sx : Word</para>
        /// </summary>
        public ushort Sx { get; set; }

        /// <summary>
        /// Start Y coordinate.
        /// <para>Delphi field: Sy : Word</para>
        /// </summary>
        public ushort Sy { get; set; }

        /// <summary>
        /// End X coordinate.
        /// <para>Delphi field: Ex : Word</para>
        /// </summary>
        public ushort Ex { get; set; }

        /// <summary>
        /// End Y coordinate.
        /// <para>Delphi field: Ey : Word</para>
        /// </summary>
        public ushort Ey { get; set; }

        /// <summary>
        /// Middle X coordinate.
        /// <para>Delphi field: Mx : Word</para>
        /// </summary>
        public ushort Mx { get; set; }

        /// <summary>
        /// Middle Y coordinate.
        /// <para>Delphi field: My : Word</para>
        /// </summary>
        public ushort My { get; set; }

        /// <summary>
        /// Red value.
        /// <para>Delphi field: R : Word</para>
        /// </summary>
        public ushort R { get; set; }

        /// <summary>
        /// Green value.
        /// <para>Delphi field: G : Word</para>
        /// </summary>
        public ushort G { get; set; }

        /// <summary>
        /// Blue value.
        /// <para>Delphi field: B : Word</para>
        /// </summary>
        public ushort B { get; set; }
    }

    /// <summary>
    /// Pattern data for pattern group download.
    /// <para>Original Delphi: TPatternData = record (CommonClass.pas line 475)</para>
    /// </summary>
    public class PatternData
    {
        /// <summary>
        /// Pattern number.
        /// <para>Delphi field: PatNo : Byte</para>
        /// </summary>
        public byte PatNo { get; set; }

        /// <summary>
        /// Pattern type.
        /// <para>Delphi field: PatType : Byte</para>
        /// </summary>
        public byte PatType { get; set; }

        /// <summary>
        /// Tool count.
        /// <para>Delphi field: ToolCnt : Byte</para>
        /// </summary>
        public byte ToolCnt { get; set; }

        /// <summary>
        /// Tool information list.
        /// <para>Delphi field: ToolInfo : array of TPatToolInfo</para>
        /// </summary>
        public List<PatToolInfo> ToolInfo { get; set; } = new List<PatToolInfo>();

        /// <summary>
        /// CRC checksum.
        /// <para>Delphi field: CRC : Word</para>
        /// </summary>
        public ushort CRC { get; set; }
    }

    /// <summary>
    /// Pattern group configuration with extended BMP add info.
    /// <para>Original Delphi: TPatternGroup = record (CommonClass.pas line 249)</para>
    /// </summary>
    public class PatternGroup
    {
        /// <summary>
        /// Group name.
        /// <para>Delphi field: GroupName : String</para>
        /// </summary>
        public string GroupName { get; set; } = string.Empty;

        /// <summary>
        /// Pattern count in this group.
        /// <para>Delphi field: PatCount : Integer</para>
        /// </summary>
        public int PatCount { get; set; }

        /// <summary>
        /// Pattern types (0=Pattern, 1=BMP).
        /// <para>Delphi field: PatType : array of Integer</para>
        /// </summary>
        public List<int> PatType { get; set; } = new List<int>();

        /// <summary>
        /// VSync values per pattern.
        /// <para>Delphi field: VSync : array of Integer</para>
        /// </summary>
        public List<int> VSync { get; set; } = new List<int>();

        /// <summary>
        /// Lock time values per pattern.
        /// <para>Delphi field: LockTime : array of Integer</para>
        /// </summary>
        public List<int> LockTime { get; set; } = new List<int>();

        /// <summary>
        /// Dimming values per pattern (2019-10-11 DIMMING).
        /// <para>Delphi field: Dimming : array of Integer</para>
        /// </summary>
        public List<int> Dimming { get; set; } = new List<int>();

        /// <summary>
        /// Option values per pattern.
        /// <para>Delphi field: Option : array of Integer</para>
        /// </summary>
        public List<int> Option { get; set; } = new List<int>();

        /// <summary>
        /// Pattern names (max 50 chars each, from ShortString[50]).
        /// <para>Delphi field: PatName : array of String[50]</para>
        /// </summary>
        public List<string> PatName { get; set; } = new List<string>();

        /// <summary>
        /// BMP download numbers per pattern. Added by KTS 2022-03-16 for ITO model.
        /// <para>Delphi field: BmpDownNum : array of integer</para>
        /// </summary>
        public List<int> BmpDownNum { get; set; } = new List<int>();

        /// <summary>
        /// BMP additional info per pattern (AF9-FPGA, 2022-06-14).
        /// <para>Delphi field: BmpAddInfo : array of TBmpAddInfo</para>
        /// </summary>
        public List<BmpAddInfo> BmpAddInfoList { get; set; } = new List<BmpAddInfo>();
    }

    /// <summary>
    /// Pattern group for save and display (simplified, no BMP add info).
    /// <para>Original Delphi: TPatterGroup = record (CommonClass.pas line 483)</para>
    /// <para>Note: Delphi source uses "TPatterGroup" (single 'n') as the type name.</para>
    /// </summary>
    public class PatterGroup
    {
        /// <summary>
        /// Group name.
        /// <para>Delphi field: GroupName : String</para>
        /// </summary>
        public string GroupName { get; set; } = string.Empty;

        /// <summary>
        /// Pattern count.
        /// <para>Delphi field: PatCount : Integer</para>
        /// </summary>
        public int PatCount { get; set; }

        /// <summary>
        /// Pattern types (0=Pattern, 1=BMP).
        /// <para>Delphi field: PatType : array of Integer</para>
        /// </summary>
        public List<int> PatType { get; set; } = new List<int>();

        /// <summary>
        /// VSync values per pattern.
        /// <para>Delphi field: VSync : array of Integer</para>
        /// </summary>
        public List<int> VSync { get; set; } = new List<int>();

        /// <summary>
        /// Lock time values per pattern.
        /// <para>Delphi field: LockTime : array of Integer</para>
        /// </summary>
        public List<int> LockTime { get; set; } = new List<int>();

        /// <summary>
        /// Option values per pattern.
        /// <para>Delphi field: Option : array of Integer</para>
        /// </summary>
        public List<int> Option { get; set; } = new List<int>();

        /// <summary>
        /// Pattern names.
        /// <para>Delphi field: PatName : array of String</para>
        /// </summary>
        public List<string> PatName { get; set; } = new List<string>();
    }

    /// <summary>
    /// PG model information combining version and configuration.
    /// <para>Original Delphi: TModelInfoPG = record (CommonClass.pas line 646)</para>
    /// <para>References PG types from DefPg.cs: PgVersion (TPgVer), PgModelConfig (TPgModelConf),
    /// PgModelPowerData (TPgModelPwrData), PgModelPowerSequence (TPgModelPwrSeq).</para>
    /// </summary>
    public class ModelInfoPG
    {
        /// <summary>
        /// PG version information (common for DP860 and AF9).
        /// <para>Delphi field: PgVer : TPgVer</para>
        /// </summary>
        public PgVersion PgVer { get; set; } = new PgVersion();

        /// <summary>
        /// PG model configuration (resolution and timing).
        /// <para>Delphi field: PgModelConf : TPgModelConf</para>
        /// </summary>
        public PgModelConfig PgModelConf { get; set; } = new PgModelConfig();

        /// <summary>
        /// DP860 power data settings (voltage/current and limits). DP860-only.
        /// <para>Delphi field: PgPwrData : TPgModelPwrData ({$IFDEF PG_DP860})</para>
        /// </summary>
        public PgModelPowerData PgPwrData { get; set; } = new PgModelPowerData();

        /// <summary>
        /// DP860 power sequence configuration (on/off timing). DP860-only.
        /// <para>Delphi field: PgPwrSeq : TPgModelPwrSeq ({$IFDEF PG_DP860})</para>
        /// </summary>
        public PgModelPowerSequence PgPwrSeq { get; set; } = new PgModelPowerSequence();
    }

    /// <summary>
    /// Model information for inspection flow control.
    /// <para>Original Delphi: TModelInfoFLOW = record (CommonClass.pas line 663)</para>
    /// <para>Includes conditionally compiled EDID, POCB, GrayChange, DimmingStep, and PSR features
    /// based on Common.inc defines. Active defines for X3584: FEATURE_GRAY_CHANGE.</para>
    /// </summary>
    public class ModelInfoFlow
    {
        /// <summary>
        /// Use PWM pattern display (2019-10-11 DIMMING, 2022-01-04 renamed UsePwm to UsePwmPatDisp).
        /// <para>Delphi field: UsePwmPatDisp : Boolean</para>
        /// </summary>
        public bool UsePwmPatDisp { get; set; }

        /// <summary>
        /// Use PWM Aux DPCD (2022-01-04 DP200|DP201:DPCD_PWM:EDNA).
        /// <para>Delphi field: UsePwmAuxDPCD : Boolean</para>
        /// </summary>
        public bool UsePwmAuxDPCD { get; set; }

        /// <summary>
        /// Serial number flash info (address and length).
        /// <para>Delphi field: SerialNoFlashInfo : TModelParamSerialNoFlash</para>
        /// </summary>
        public ModelParamSerialNoFlash SerialNoFlashInfo { get; set; } = new ModelParamSerialNoFlash();

        /// <summary>
        /// DUT detection enabled.
        /// <para>Delphi field: UseDutDetect : Boolean</para>
        /// </summary>
        public bool UseDutDetect { get; set; }

        /// <summary>
        /// Power off/on delay (ms).
        /// <para>Delphi field: PwrOffOnDelay : Integer</para>
        /// </summary>
        public int PwrOffOnDelay { get; set; }

        /// <summary>
        /// BCR barcode length.
        /// <para>Delphi field: BcrLength : Integer</para>
        /// </summary>
        public int BcrLength { get; set; }

        /// <summary>
        /// Process name.
        /// <para>Delphi field: ProcessName : string</para>
        /// </summary>
        public string ProcessName { get; set; } = string.Empty;

        /// <summary>
        /// Pattern group name.
        /// <para>Delphi field: PatGrpName : string</para>
        /// </summary>
        public string PatGrpName { get; set; } = string.Empty;

        /// <summary>
        /// Model type identifier.
        /// <para>Delphi field: ModelType : Integer</para>
        /// </summary>
        public int ModelType { get; set; }

        /// <summary>
        /// Model type name.
        /// <para>Delphi field: ModelTypeName : string</para>
        /// </summary>
        public string ModelTypeName { get; set; } = string.Empty;

        /// <summary>
        /// Model file name.
        /// <para>Delphi field: ModelFileName : string</para>
        /// </summary>
        public string ModelFileName { get; set; } = string.Empty;

        /// <summary>
        /// CA410 memory channel.
        /// <para>Delphi field: Ca410MemCh : Integer</para>
        /// </summary>
        public int Ca410MemCh { get; set; }

        /// <summary>
        /// NVM initialization mode. Added by KTS 2023-06-13.
        /// <para>Delphi field: UseNvmInit : integer</para>
        /// </summary>
        public int UseNvmInit { get; set; }

        /// <summary>
        /// IDLE mode enabled.
        /// <para>Delphi field: IDLEMode : Boolean</para>
        /// </summary>
        public bool IdleMode { get; set; }

        /// <summary>
        /// IDLE mode display time (ms).
        /// <para>Delphi field: IdleModeDTime : Integer</para>
        /// </summary>
        public int IdleModeDTime { get; set; }

        /// <summary>
        /// Check version per config. Added by KTS 2023-07-13.
        /// <para>Delphi field: UseCheckVer : Boolean</para>
        /// </summary>
        public bool UseCheckVer { get; set; }

        /// <summary>
        /// Check reprogramming enabled.
        /// <para>Delphi field: UseCheckReProgramming : Boolean</para>
        /// </summary>
        public bool UseCheckReProgramming { get; set; }

        /// <summary>
        /// NVM write sequence check mode.
        /// <para>Delphi field: UseCkNVMWriteSequence : Integer</para>
        /// </summary>
        public int UseCkNVMWriteSequence { get; set; }

        /// <summary>
        /// TCON write checksum verification enabled.
        /// <para>Delphi field: UseTconWriteChecksum : Boolean</para>
        /// </summary>
        public bool UseTconWriteChecksum { get; set; }

        /// <summary>
        /// Get DLL bin file path.
        /// <para>Delphi field: GetDLLBin : string</para>
        /// </summary>
        public string GetDLLBin { get; set; } = string.Empty;

        /// <summary>
        /// 3200 Nit DOE flag.
        /// <para>Delphi field: Is_3200NitDOE : Boolean</para>
        /// </summary>
        public bool Is3200NitDOE { get; set; }

        /// <summary>
        /// Ionizer on/off control enabled. Added by KTS 2022-03-18.
        /// <para>Delphi field: UseIonOnOff : Boolean</para>
        /// </summary>
        public bool UseIonOnOff { get; set; }

        // ---- FEATURE_GRAY_CHANGE (active for X3584) ----

        /// <summary>
        /// Gray change feature enabled.
        /// <para>Delphi field: GrayChangeUse : Boolean ({$IFDEF FEATURE_GRAY_CHANGE})</para>
        /// </summary>
        public bool GrayChangeUse { get; set; }

        /// <summary>
        /// Gray change unit for switch button (0~255).
        /// <para>Delphi field: GrayChangeUnitButton : Integer ({$IFDEF FEATURE_GRAY_CHANGE})</para>
        /// </summary>
        public int GrayChangeUnitButton { get; set; }

        /// <summary>
        /// Gray change unit for keyboard (0~255).
        /// <para>Delphi field: GrayChangeUnitKbd : Integer ({$IFDEF FEATURE_GRAY_CHANGE})</para>
        /// </summary>
        public int GrayChangeUnitKbd { get; set; }
    }

    /// <summary>
    /// Log item record for channel-based logging.
    /// <para>Original Delphi: TLogItem = record (CommonClass.pas line 725)</para>
    /// </summary>
    public class LogItem
    {
        /// <summary>
        /// Channel number.
        /// <para>Delphi field: CH : Integer</para>
        /// </summary>
        public int Channel { get; set; }

        /// <summary>
        /// Log file name.
        /// <para>Delphi field: FileName : string</para>
        /// </summary>
        public string FileName { get; set; } = string.Empty;

        /// <summary>
        /// Log message.
        /// <para>Delphi field: Msg : string</para>
        /// </summary>
        public string Msg { get; set; } = string.Empty;
    }

    /// <summary>
    /// JNCD inter-component message record.
    /// <para>Original Delphi: RMsgJncd = packed record (CommonClass.pas line 32)</para>
    /// </summary>
    public class MsgJncd
    {
        /// <summary>
        /// Message type identifier.
        /// <para>Delphi field: MsgType : Integer</para>
        /// </summary>
        public int MsgType { get; set; }

        /// <summary>
        /// Channel number.
        /// <para>Delphi field: Channel : Integer</para>
        /// </summary>
        public int Channel { get; set; }

        /// <summary>
        /// Command identifier.
        /// <para>Delphi field: Cmd : Integer</para>
        /// </summary>
        public int Cmd { get; set; }

        /// <summary>
        /// First parameter.
        /// <para>Delphi field: Param1 : Integer</para>
        /// </summary>
        public int Param1 { get; set; }

        /// <summary>
        /// Message text.
        /// <para>Delphi field: Msg : string</para>
        /// </summary>
        public string Msg { get; set; } = string.Empty;
    }
}
