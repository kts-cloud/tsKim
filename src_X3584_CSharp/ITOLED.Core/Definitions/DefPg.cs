// =============================================================================
// DefPg.cs
// Converted from Delphi: DefPG.pas
// Pattern Generator definitions for ITOLED inspection system.
// Covers both PG_AF9 (USB) and PG_DP860 (TCP/IP) pattern generators.
// =============================================================================

using System.Runtime.InteropServices;

namespace Dongaeltek.ITOLED.Core.Definitions
{
    /// <summary>
    /// Pattern Generator type identifiers.
    /// <para>Delphi: PG_TYPE_DP860, PG_TYPE_AF9</para>
    /// </summary>
    public static class PgType
    {
        /// <summary>Delphi: PG_TYPE_DP860 = 0</summary>
        public const int Dp860 = 0;

        /// <summary>Delphi: PG_TYPE_AF9 = 1</summary>
        public const int Af9 = 1;
    }

    /// <summary>
    /// PG cyclic timer intervals and wait times (milliseconds).
    /// <para>Delphi: PG_CMD_WAITACK_DEF, PG_CONNCHECK_INTERVAL, etc.</para>
    /// </summary>
    public static class PgTimerDefaults
    {
        /// <summary>Delphi: PG_CMD_WAITACK_DEF = 200 (msec)</summary>
        public const int CmdWaitAckDefault = 200;

        /// <summary>Delphi: PG_CONNCHECK_INTERVAL = 2000 (msec)</summary>
        public const int ConnCheckInterval = 2000;

        /// <summary>Delphi: PG_PWRMEASURE_INTERVAL_DEF = 2000 (msec)</summary>
        public const int PwrMeasureIntervalDefault = 2000;

        /// <summary>Delphi: PG_PWRMEASURE_INTERVAL_MIN = 1000 (msec)</summary>
        public const int PwrMeasureIntervalMin = 1000;

        /// <summary>Delphi: PG_PWRMEASURE_WAITACK_DEF = 1000 (msec)</summary>
        public const int PwrMeasureWaitAckDefault = 1000;
    }

    /// <summary>
    /// General PG command parameters.
    /// <para>Delphi: PG_CMDID_UNKNOWN, CMD_POWER_OFF/ON, CMD_DISPLAY_OFF/ON</para>
    /// </summary>
    public static class PgCommandParam
    {
        /// <summary>Delphi: PG_CMDID_UNKNOWN = 0</summary>
        public const int CmdIdUnknown = 0;

        /// <summary>Delphi: PG_CMDSTR_UNKNOWN = 'UnknownPgCommand'</summary>
        public const string CmdStrUnknown = "UnknownPgCommand";

        /// <summary>Delphi: CMD_POWER_OFF = 0</summary>
        public const int PowerOff = 0;

        /// <summary>Delphi: CMD_POWER_ON = 1</summary>
        public const int PowerOn = 1;

        /// <summary>Delphi: CMD_DISPLAY_OFF = 0</summary>
        public const int DisplayOff = 0;

        /// <summary>Delphi: CMD_DISPLAY_ON = 1</summary>
        public const int DisplayOn = 1;
    }

    /// <summary>
    /// Flash memory size and timing constants.
    /// <para>Delphi: MAX_FLASH_SIZE_BYTE, FLASH_ERASE_WAITMS_MINIMUM, etc.</para>
    /// </summary>
    public static class PgFlashConstants
    {
        /// <summary>Delphi: MAX_FLASH_SIZE_BYTE = 16*1024*1024 (16 MB)</summary>
        public const int MaxFlashSizeByte = 16 * 1024 * 1024;

        /// <summary>Delphi: MAX_FLASH_GAMMA_SIZE_BYTE = 1*1024*1024 (1 MB)</summary>
        public const int MaxFlashGammaSizeByte = 1 * 1024 * 1024;

        /// <summary>Delphi: MAX_FLASH_PUCPARA_SIZE_BYTE = 1*1024*1024 (1 MB)</summary>
        public const int MaxFlashPucParaSizeByte = 1 * 1024 * 1024;

        /// <summary>Delphi: MAX_FLASH_PUCDATA_SIZE_BYTE = 8*1024*1024 (8 MB)</summary>
        public const int MaxFlashPucDataSizeByte = 8 * 1024 * 1024;

        /// <summary>Delphi: FLASH_ERASE_WAITMS_MINIMUM = 5*1000 (5 sec)</summary>
        public const int FlashEraseWaitMsMinimum = 5 * 1000;

        /// <summary>Delphi: FLASH_READ_WAITMS_MINIMUM = 5*1000 (5 sec)</summary>
        public const int FlashReadWaitMsMinimum = 5 * 1000;

        /// <summary>Delphi: FLASH_WRITE_WAITMS_MINIMUM = 10*1000 (10 sec)</summary>
        public const int FlashWriteWaitMsMinimum = 10 * 1000;

        /// <summary>Delphi: FLASH_SIZE_KB_DEF = 8192 (8 MB)</summary>
        public const int FlashSizeKbDefault = 8192;

        /// <summary>Delphi: FLASH_READ_KBperSEC_DEF = 80</summary>
        public const int FlashReadKbPerSecDefault = 80;

        /// <summary>Delphi: FLASH_WRITE_KBperSEC_DEF = 7</summary>
        public const int FlashWriteKbPerSecDefault = 7;

        /// <summary>Delphi: FLASH_ERASE_KBperSEC_DEF = 20</summary>
        public const int FlashEraseKbPerSecDefault = 20;
    }

    /// <summary>
    /// Power rail index constants.
    /// <para>Delphi: PWR_VDD1..PWR_VDD5, PWR_MAX, PWR_SEQ_MAX</para>
    /// </summary>
    public static class PgPowerIndex
    {
        /// <summary>Delphi: PWR_VDD1 = 0 (alias PWR_VCC)</summary>
        public const int Vdd1 = 0;

        /// <summary>Delphi: PWR_VCC = PWR_VDD1</summary>
        public const int Vcc = Vdd1;

        /// <summary>Delphi: PWR_VDD2 = 1 (alias PWR_VIN)</summary>
        public const int Vdd2 = 1;

        /// <summary>Delphi: PWR_VIN = PWR_VDD2</summary>
        public const int Vin = Vdd2;

        /// <summary>Delphi: PWR_VDD3 = 2</summary>
        public const int Vdd3 = 2;

        /// <summary>Delphi: PWR_VDD4 = 3</summary>
        public const int Vdd4 = 3;

        /// <summary>Delphi: PWR_VDD5 = 4</summary>
        public const int Vdd5 = 4;

        /// <summary>Delphi: PWR_MAX = PWR_VDD5</summary>
        public const int Max = Vdd5;

        /// <summary>Delphi: PWR_SEQ_MAX = 2</summary>
        public const int SeqMax = 2;
    }

    /// <summary>
    /// PG command state constants.
    /// <para>Delphi: PG_CMDSTATE_NONE..PG_CMDSTATE_RX_ACK</para>
    /// </summary>
    public static class PgCmdState
    {
        /// <summary>Delphi: PG_CMDSTATE_NONE = 0</summary>
        public const int None = 0;

        /// <summary>Delphi: PG_CMDSTATE_TX_NOACK = 1</summary>
        public const int TxNoAck = 1;

        /// <summary>Delphi: PG_CMDSTATE_TX_WAITACK = 2</summary>
        public const int TxWaitAck = 2;

        /// <summary>Delphi: PG_CMDSTATE_RX_ACK = 3</summary>
        public const int RxAck = 3;
    }

    /// <summary>
    /// PG command result constants.
    /// <para>Delphi: PG_CMDRESULT_NONE, PG_CMDRESULT_OK, PG_CMDRESULT_NG</para>
    /// </summary>
    public static class PgCmdResult
    {
        /// <summary>Delphi: PG_CMDRESULT_NONE = 0</summary>
        public const int None = 0;

        /// <summary>Delphi: PG_CMDRESULT_OK = 1</summary>
        public const int Ok = 1;

        /// <summary>Delphi: PG_CMDRESULT_NG = 2</summary>
        public const int Ng = 2;
    }

    /// <summary>
    /// I2C device address constants.
    /// <para>Delphi: TCON_REG_DEVICE, PROGRAMING_DEVICE</para>
    /// </summary>
    public static class PgDeviceAddr
    {
        /// <summary>Delphi: TCON_REG_DEVICE = $A0</summary>
        public const byte TconRegDevice = 0xA0;

        /// <summary>Delphi: PROGRAMING_DEVICE = $14</summary>
        public const byte ProgramingDevice = 0x14;
    }

    // =========================================================================
    //  Records / Structs
    // =========================================================================

    /// <summary>
    /// TCON read/write counters for OC T/T test diagnostics.
    /// <para>Delphi: TTconRWCnt</para>
    /// </summary>
    public class TconRwCount
    {
        /// <summary>Delphi: TconReadDllCall</summary>
        public int TconReadDllCall { get; set; }

        /// <summary>Delphi: TconWriteDllCall</summary>
        public int TconWriteDllCall { get; set; }

        /// <summary>Delphi: TconReadTX</summary>
        public int TconReadTx { get; set; }

        /// <summary>Delphi: TConWriteTX</summary>
        public int TconWriteTx { get; set; }

        /// <summary>Delphi: TConOcWriteTX</summary>
        public int TconOcWriteTx { get; set; }

        /// <summary>Delphi: ContTConOcWrite</summary>
        public int ContTconOcWrite { get; set; }

        /// <summary>Delphi: TconReadArrayDllCall</summary>
        public int TconReadArrayDllCall { get; set; }

        /// <summary>Delphi: TconWriteArrayDllCall</summary>
        public int TconWriteArrayDllCall { get; set; }

        /// <summary>Delphi: TconMultiWriteDllCall</summary>
        public int TconMultiWriteDllCall { get; set; }

        /// <summary>Delphi: TconSeqWriteDllCall</summary>
        public int TconSeqWriteDllCall { get; set; }

        /// <summary>Delphi: TconRetryReadCall</summary>
        public int TconRetryReadCall { get; set; }

        /// <summary>Delphi: TconRetryWriteCall</summary>
        public int TconRetryWriteCall { get; set; }
    }

    /// <summary>
    /// PG TX/RX data container.
    /// <para>Delphi: TPgTxRxData (contains managed strings, so not a struct).</para>
    /// </summary>
    public class PgTxRxData
    {
        /// <summary>Maximum TX/RX buffer size (256 KB + 1 byte). Delphi: array [0..256*1024]</summary>
        public const int BufferSize = 256 * 1024 + 1;

        /// <summary>Delphi: CmdState</summary>
        public int CmdState { get; set; }

        /// <summary>Delphi: CmdResult. Volatile for cross-thread spin-wait visibility.</summary>
        private volatile int _cmdResult;
        public int CmdResult
        {
            get => _cmdResult;
            set => _cmdResult = value;
        }

        // --- TX ---

        /// <summary>Delphi: TxCmdId</summary>
        public int TxCmdId { get; set; }

        /// <summary>Delphi: TxCmdStr</summary>
        public string TxCmdStr { get; set; } = string.Empty;

        /// <summary>Delphi: TxDataLen</summary>
        public int TxDataLen { get; set; }

        /// <summary>Delphi: TxData : array [0..256*1024] of Byte</summary>
        public byte[] TxData { get; set; } = new byte[BufferSize];

        // --- RX ---

        /// <summary>Delphi: RxCmdId</summary>
        public int RxCmdId { get; set; }

        /// <summary>Delphi: RxAckStr</summary>
        public string RxAckStr { get; set; } = string.Empty;

        /// <summary>Delphi: RxDataLen</summary>
        public int RxDataLen { get; set; }

        /// <summary>Delphi: RxData : array [0..256*1024] of Byte</summary>
        public byte[] RxData { get; set; } = new byte[BufferSize];

        /// <summary>Delphi: RxPrevStr</summary>
        public string RxPrevStr { get; set; } = string.Empty;
    }

    /// <summary>
    /// PG firmware/hardware version information.
    /// <para>Delphi: TPgVer</para>
    /// </summary>
    public class PgVersion
    {
        /// <summary>Delphi: VerAll (e.g., AF9: "MCS%0.3d_API%0.3d", DP860: "HW_1.3_APP_1.0.2_...")</summary>
        public string VerAll { get; set; } = string.Empty;

        // --- DP860-specific fields ---

        /// <summary>Delphi: HW (DP860-only)</summary>
        public string HW { get; set; } = string.Empty;

        /// <summary>Delphi: FW (DP860-only)</summary>
        public string FW { get; set; } = string.Empty;

        /// <summary>Delphi: SubFW (DP860-only)</summary>
        public string SubFW { get; set; } = string.Empty;

        /// <summary>Delphi: IP (DP860-only)</summary>
        public string IP { get; set; } = string.Empty;

        /// <summary>Delphi: FPGA (DP860-only)</summary>
        public string FPGA { get; set; } = string.Empty;

        /// <summary>Delphi: PWR (DP860-only)</summary>
        public string PWR { get; set; } = string.Empty;

        /// <summary>Delphi: ITO_APP (DP860-only)</summary>
        public string ItoApp { get; set; } = string.Empty;

        /// <summary>Delphi: VerScript (DP860-only)</summary>
        public string VerScript { get; set; } = string.Empty;

        // --- AF9-specific fields ---

        /// <summary>Delphi: AF9VerMCS (AF9-only)</summary>
        public int Af9VerMcs { get; set; }

        /// <summary>Delphi: AF9VerAPI (AF9-only)</summary>
        public int Af9VerApi { get; set; }

        /// <summary>Delphi: sAF9APIType (AF9-only, e.g., "Debug(1CH|MULTI)")</summary>
        public string Af9ApiType { get; set; } = string.Empty;
    }

    /// <summary>
    /// PG model configuration (resolution and timing parameters).
    /// <para>Delphi: TPgModelConf</para>
    /// </summary>
    public class PgModelConfig
    {
        // --- Resolution (common) ---

        /// <summary>Delphi: H_Active</summary>
        public ushort HActive { get; set; }

        /// <summary>Delphi: H_BP</summary>
        public ushort HBp { get; set; }

        /// <summary>Delphi: H_SA (Width)</summary>
        public ushort HSa { get; set; }

        /// <summary>Delphi: H_FP</summary>
        public ushort HFp { get; set; }

        /// <summary>Delphi: V_Active</summary>
        public ushort VActive { get; set; }

        /// <summary>Delphi: V_BP</summary>
        public ushort VBp { get; set; }

        /// <summary>Delphi: V_SA (Width)</summary>
        public ushort VSa { get; set; }

        /// <summary>Delphi: V_FP</summary>
        public ushort VFp { get; set; }

        // --- AF9-specific ---

        /// <summary>Delphi: Bmp2RawType (AF9-only, e.g., 0:Large(X2146), 1:Small(X2381))</summary>
        public int Bmp2RawType { get; set; }

        // --- DP860-specific timing ---

        /// <summary>Delphi: link_rate (DP860-only)</summary>
        public uint LinkRate { get; set; }

        /// <summary>Delphi: lane (DP860-only)</summary>
        public int Lane { get; set; }

        /// <summary>Delphi: Vsync (DP860-only)</summary>
        public int Vsync { get; set; }

        /// <summary>Delphi: RGBFormat (DP860-only)</summary>
        public string RgbFormat { get; set; } = string.Empty;

        /// <summary>Delphi: ALPM_Mode (DP860-only)</summary>
        public int AlpmMode { get; set; }

        /// <summary>Delphi: vfb_offset (DP860-only)</summary>
        public int VfbOffset { get; set; }

        // --- DP860 ALPDP parameters ---

        /// <summary>Delphi: h_fdp</summary>
        public int HFdp { get; set; }

        /// <summary>Delphi: h_sdp</summary>
        public int HSdp { get; set; }

        /// <summary>Delphi: h_pcnt</summary>
        public int HPcnt { get; set; }

        /// <summary>Delphi: vb_n5b</summary>
        public int VbN5b { get; set; }

        /// <summary>Delphi: vb_n7</summary>
        public int VbN7 { get; set; }

        /// <summary>Delphi: vb_n5a</summary>
        public int VbN5a { get; set; }

        /// <summary>Delphi: vb_sleep</summary>
        public int VbSleep { get; set; }

        /// <summary>Delphi: vb_n2</summary>
        public int VbN2 { get; set; }

        /// <summary>Delphi: vb_n3</summary>
        public int VbN3 { get; set; }

        /// <summary>Delphi: vb_n4</summary>
        public int VbN4 { get; set; }

        /// <summary>Delphi: m_vid</summary>
        public int MVid { get; set; }

        /// <summary>Delphi: n_vid</summary>
        public int NVid { get; set; }

        /// <summary>Delphi: misc_0</summary>
        public int Misc0 { get; set; }

        /// <summary>Delphi: misc_1</summary>
        public int Misc1 { get; set; }

        /// <summary>Delphi: xpol</summary>
        public int Xpol { get; set; }

        /// <summary>Delphi: xdelay</summary>
        public int Xdelay { get; set; }

        /// <summary>Delphi: h_mg</summary>
        public int HMg { get; set; }

        /// <summary>Delphi: NoAux_Sel</summary>
        public int NoAuxSel { get; set; }

        /// <summary>Delphi: NoAux_Active</summary>
        public int NoAuxActive { get; set; }

        /// <summary>Delphi: NoAux_Sleep</summary>
        public int NoAuxSleep { get; set; }

        /// <summary>Delphi: critical_section</summary>
        public int CriticalSection { get; set; }

        /// <summary>Delphi: tps</summary>
        public int Tps { get; set; }

        /// <summary>Delphi: v_blank</summary>
        public int VBlank { get; set; }

        /// <summary>Delphi: chop_enable</summary>
        public int ChopEnable { get; set; }

        /// <summary>Delphi: chop_interval</summary>
        public int ChopInterval { get; set; }

        /// <summary>Delphi: chop_size</summary>
        public int ChopSize { get; set; }
    }

    /// <summary>
    /// DP860 power data configuration (voltage/current settings and limits).
    /// <para>Delphi: TPgModelPwrData (DP860-only)</para>
    /// </summary>
    public class PgModelPowerData
    {
        /// <summary>Delphi: PWR_SLOPE (slope_set)</summary>
        public int PwrSlope { get; set; }

        /// <summary>Delphi: PWR_NAME : array[0..PWR_MAX] of String</summary>
        public string[] PwrName { get; set; } = new string[PgPowerIndex.Max + 1];

        /// <summary>Delphi: PWR_VOL : array[0..PWR_MAX] of UInt32 (1=1mV)</summary>
        public uint[] PwrVol { get; set; } = new uint[PgPowerIndex.Max + 1];

        /// <summary>Delphi: PWR_VOL_LL : array[0..PWR_MAX] of UInt32 (1=1mV, low limit)</summary>
        public uint[] PwrVolLl { get; set; } = new uint[PgPowerIndex.Max + 1];

        /// <summary>Delphi: PWR_VOL_HL : array[0..PWR_MAX] of UInt32 (1=1mV, high limit)</summary>
        public uint[] PwrVolHl { get; set; } = new uint[PgPowerIndex.Max + 1];

        /// <summary>Delphi: PWR_CUR_LL : array[0..PWR_MAX] of UInt32 (1=1mA, low limit)</summary>
        public uint[] PwrCurLl { get; set; } = new uint[PgPowerIndex.Max + 1];

        /// <summary>Delphi: PWR_CUR_HL : array[0..PWR_MAX] of UInt32 (1=1mA, high limit)</summary>
        public uint[] PwrCurHl { get; set; } = new uint[PgPowerIndex.Max + 1];

        public PgModelPowerData()
        {
            for (int i = 0; i < PwrName.Length; i++)
                PwrName[i] = string.Empty;
        }
    }

    /// <summary>
    /// DP860 power sequence configuration (on/off timing).
    /// <para>Delphi: TPgModelPwrSeq (DP860-only)</para>
    /// </summary>
    public class PgModelPowerSequence
    {
        /// <summary>Delphi: SeqOn : array[0..PWR_SEQ_MAX] of Integer</summary>
        public int[] SeqOn { get; set; } = new int[PgPowerIndex.SeqMax + 1];

        /// <summary>Delphi: SeqOff : array[0..PWR_SEQ_MAX] of Integer</summary>
        public int[] SeqOff { get; set; } = new int[PgPowerIndex.SeqMax + 1];
    }

    // =========================================================================
    //  Enums
    // =========================================================================

    /// <summary>
    /// PG connection status states.
    /// <para>Delphi: enumPgStatus</para>
    /// </summary>
    public enum PgStatus
    {
        /// <summary>Delphi: pgDisconn = 0</summary>
        Disconnected = 0,

        /// <summary>Delphi: pgConnect = 1 (Rcv first ConnCheckAck or pg.init)</summary>
        Connected = 1,

        /// <summary>Delphi: pgGetPgVer = 2 (Sending version.all)</summary>
        GetPgVersion = 2,

        /// <summary>Delphi: pgModelDown = 3 (Sending model info)</summary>
        ModelDownload = 3,

        /// <summary>Delphi: pgReady = 4</summary>
        Ready = 4,

        /// <summary>Delphi: pgWait = 5</summary>
        Wait = 5,

        /// <summary>Delphi: pgDone = 6</summary>
        Done = 6,

        /// <summary>Delphi: pgForceStop = 7</summary>
        ForceStop = 7,
    }

    /// <summary>
    /// Power measurement data (voltage in mV, current in mA).
    /// <para>Delphi: TPwrData (VCC~VDD5: 1=1mV, IVCC~iVDD5: 1=1mA)</para>
    /// </summary>
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct PwrData
    {
        // Voltage (mV)

        /// <summary>Delphi: VCC (mV)</summary>
        public uint Vcc;

        /// <summary>Delphi: VIN (mV)</summary>
        public uint Vin;

        /// <summary>Delphi: VDD3 (mV)</summary>
        public uint Vdd3;

        /// <summary>Delphi: VDD4 (mV)</summary>
        public uint Vdd4;

        /// <summary>Delphi: VDD5 (mV)</summary>
        public uint Vdd5;

        // Current (mA)

        /// <summary>Delphi: IVCC (mA)</summary>
        public uint Ivcc;

        /// <summary>Delphi: IVIN (mA)</summary>
        public uint Ivin;

        /// <summary>Delphi: IVDD3 (mA)</summary>
        public uint Ivdd3;

        /// <summary>Delphi: IVDD4 (mA)</summary>
        public uint Ivdd4;

        /// <summary>Delphi: IVDD5 (mA)</summary>
        public uint Ivdd5;
    }

    /// <summary>
    /// Raw power measurement data from PG (voltage in mV, current in uA).
    /// <para>Delphi: TRxPwrData (VCC~VDD5: 1=1mV, IVCC~iVDD5: 1=1uA)</para>
    /// </summary>
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct RxPwrData
    {
        // Voltage (mV)

        /// <summary>Delphi: VCC (mV)</summary>
        public uint Vcc;

        /// <summary>Delphi: VIN (mV)</summary>
        public uint Vin;

        /// <summary>Delphi: VDD3 (mV)</summary>
        public uint Vdd3;

        /// <summary>Delphi: VDD4 (mV)</summary>
        public uint Vdd4;

        /// <summary>Delphi: VDD5 (mV)</summary>
        public uint Vdd5;

        // Current (uA)

        /// <summary>Delphi: IVCC (uA)</summary>
        public uint Ivcc;

        /// <summary>Delphi: IVIN (uA)</summary>
        public uint Ivin;

        /// <summary>Delphi: IVDD3 (uA)</summary>
        public uint Ivdd3;

        /// <summary>Delphi: IVDD4 (uA)</summary>
        public uint Ivdd4;

        /// <summary>Delphi: IVDD5 (uA)</summary>
        public uint Ivdd5;
    }

    /// <summary>
    /// Flash access status.
    /// <para>Delphi: enumPgFlashAccSt</para>
    /// </summary>
    public enum PgFlashAccessStatus
    {
        /// <summary>Delphi: flashAccUnknown = 0</summary>
        Unknown = 0,

        /// <summary>Delphi: flashAccDisabled = 1</summary>
        Disabled = 1,

        /// <summary>Delphi: flashAccEnabled = 2</summary>
        Enabled = 2,
    }

    /// <summary>
    /// Flash read type.
    /// <para>Delphi: enumFlashReadType</para>
    /// </summary>
    public enum FlashReadType
    {
        /// <summary>Delphi: flashReadNone = 0</summary>
        None = 0,

        /// <summary>Delphi: flashReadUnit = 1</summary>
        Unit = 1,

        /// <summary>Delphi: flashReadGamma = 2, flashReadAll = 2</summary>
        GammaOrAll = 2,
    }

    /// <summary>
    /// Flash read operation state and data.
    /// <para>Delphi: TFlashRead</para>
    /// </summary>
    public class FlashRead
    {
        /// <summary>Delphi: FlashAccSt</summary>
        public PgFlashAccessStatus FlashAccessStatus { get; set; }

        /// <summary>Delphi: ReadType</summary>
        public FlashReadType ReadType { get; set; }

        /// <summary>Delphi: ReadSize</summary>
        public int ReadSize { get; set; }

        /// <summary>Delphi: RxSize</summary>
        public int RxSize { get; set; }

        /// <summary>Delphi: RxData : array[0..(MAX_FLASH_SIZE_BYTE-1)] of Byte</summary>
        public byte[] RxData { get; set; } = new byte[PgFlashConstants.MaxFlashSizeByte];

        /// <summary>Delphi: ChecksumRx</summary>
        public uint ChecksumRx { get; set; }

        /// <summary>Delphi: ChecksumCalc</summary>
        public uint ChecksumCalc { get; set; }

        /// <summary>Delphi: bReadDone</summary>
        public bool IsReadDone { get; set; }

        /// <summary>Delphi: SaveFilePath</summary>
        public string SaveFilePath { get; set; } = string.Empty;

        /// <summary>Delphi: SaveFileName</summary>
        public string SaveFileName { get; set; } = string.Empty;
    }

    /// <summary>
    /// Flash R/W data container (inspector-specific).
    /// <para>Delphi: TFlashData</para>
    /// </summary>
    public class FlashData
    {
        /// <summary>Delphi: StartAddr</summary>
        public int StartAddr { get; set; }

        /// <summary>Delphi: Size</summary>
        public int Size { get; set; }

        /// <summary>Delphi: Data : array[0..(MAX_FLASH_SIZE_BYTE-1)] of Byte</summary>
        public byte[] Data { get; set; } = new byte[PgFlashConstants.MaxFlashSizeByte];

        /// <summary>Delphi: Checksum</summary>
        public uint Checksum { get; set; }

        /// <summary>Delphi: bValid</summary>
        public bool IsValid { get; set; }
    }

    // =========================================================================
    //  PG_AF9 - AF9 API result constants
    // =========================================================================

    /// <summary>
    /// AF9 API start connection result codes.
    /// <para>Delphi: AF9API_STARTCONN_* constants (PG_AF9 section)</para>
    /// </summary>
    public static class Af9ApiStartConnResult
    {
        /// <summary>Delphi: AF9API_STARTCONN_USB_OPENFAIL = -1</summary>
        public const int UsbOpenFail = -1;

        /// <summary>Delphi: AF9API_STARTCONN_USB_NOTFOUND = 0</summary>
        public const int UsbNotFound = 0;

        /// <summary>Delphi: AF9API_STARTCONN_OK = 1</summary>
        public const int Ok = 1;

        /// <summary>Delphi: AF9API_STARTCONN_DLL_EXCEPTION = 2</summary>
        public const int DllException = 2;
    }

    /// <summary>
    /// AF9 API general result codes.
    /// <para>Delphi: AF9API_RESULT_OK, AF9API_RESULT_NG, AF9API_RESULT_DLL_EXCEPTION</para>
    /// </summary>
    public static class Af9ApiResult
    {
        /// <summary>Delphi: AF9API_RESULT_OK = 1</summary>
        public const int Ok = 1;

        /// <summary>Delphi: AF9API_RESULT_NG = 0</summary>
        public const int Ng = 0;

        /// <summary>Delphi: AF9API_RESULT_DLL_EXCEPTION = 2</summary>
        public const int DllException = 2;
    }

    /// <summary>
    /// AF9-FPGA register device addresses.
    /// <para>Delphi: APS_REG_DEVICE (PG_AF9 section)</para>
    /// </summary>
    public static class Af9RegDevice
    {
        /// <summary>Delphi: APS_REG_DEVICE = $B0 (arbitrary)</summary>
        public const byte ApsRegDevice = 0xB0;
    }

    // =========================================================================
    //  PG_DP860 - Network and Command Constants
    // =========================================================================

    /// <summary>
    /// DP860 network configuration (IP addresses and ports).
    /// <para>Delphi: CommPG_NETWORK_PREFIX, CommPG_PC_*, CommPG_PG_* (PG_DP860 section)</para>
    /// </summary>
    public static class Dp860Network
    {
        /// <summary>Delphi: CommPG_NETWORK_PREFIX = '169.254.199'</summary>
        public const string NetworkPrefix = "169.254.199";

        /// <summary>Delphi: CommPG_PC_IPADDR = CommPG_NETWORK_PREFIX + '.10'</summary>
        public const string PcIpAddr = NetworkPrefix + ".10";

        /// <summary>Delphi: CommPG_PC_PORT_BASE = 8000</summary>
        public const int PcPortBase = 8000;

        /// <summary>Delphi: CommPG_PC_PORT_STATIC = False</summary>
        public const bool PcPortStatic = false;

        /// <summary>Delphi: CommPG_PG_IPADDR_BASE = 11</summary>
        public const int PgIpAddrBase = 11;

        /// <summary>Delphi: CommPG_PG_PORT_BASE = 8001</summary>
        public const int PgPortBase = 8001;
    }

    /// <summary>
    /// DP860 FTP credentials and paths.
    /// <para>Delphi: DP860_FTP_*, DP860_ROOT_* (PG_DP860 section)</para>
    /// </summary>
    public static class Dp860Ftp
    {
        /// <summary>Delphi: DP860_FTP_USERNAME = 'upload'</summary>
        public const string FtpUsername = "upload";

        /// <summary>Delphi: DP860_FTP_PASSWORD = 'upload'</summary>
        public const string FtpPassword = "upload";

        /// <summary>Delphi: DP860_FTP_PATH_UPLOAD = '/home/upload'</summary>
        public const string FtpPathUpload = "/home/upload";

        /// <summary>Delphi: DP860_FTP_PATH_DOWNLOAD = '/home/upload'</summary>
        public const string FtpPathDownload = "/home/upload";

        /// <summary>Delphi: DP860_ROOT_USERNAME = 'root'</summary>
        public const string RootUsername = "root";

        /// <summary>Delphi: DP860_ROOT_PASSWORD = 'insta'</summary>
        public const string RootPassword = "insta";
    }

    /// <summary>
    /// DP860 PG command IDs and command strings.
    /// <para>Delphi: PG_CMDID_* and PG_CMDSTR_* constants (PG_DP860 section)</para>
    /// </summary>
    public static class Dp860Commands
    {
        // ---- Connection / Init ----

        /// <summary>Delphi: PG_CMDID_CONNCHECK = 1</summary>
        public const int CmdIdConnCheck = 1;
        /// <summary>Delphi: PG_CMDSTR_CONNCHECK = 'pg.status'</summary>
        public const string CmdStrConnCheck = "pg.status";

        /// <summary>Delphi: PG_CMDID_PG_INIT = 2</summary>
        public const int CmdIdPgInit = 2;
        /// <summary>Delphi: PG_CMDSTR_PG_INIT = 'pg.init'</summary>
        public const string CmdStrPgInit = "pg.init";

        // ---- Version ----

        /// <summary>Delphi: PG_CMDID_VERSION_ALL = 3</summary>
        public const int CmdIdVersionAll = 3;
        /// <summary>Delphi: PG_CMDSTR_VERSION_ALL = 'version.all'</summary>
        public const string CmdStrVersionAll = "version.all";

        /// <summary>Delphi: PG_CMDID_MODEL_VERSION = 8</summary>
        public const int CmdIdModelVersion = 8;
        /// <summary>Delphi: PG_CMDSTR_MODEL_VERSION = 'model.version'</summary>
        public const string CmdStrModelVersion = "model.version";

        // ---- Module selection and identity ----

        /// <summary>Delphi: PG_CMDID_POWER_OPEN = 10</summary>
        public const int CmdIdPowerOpen = 10;
        /// <summary>Delphi: PG_CMDSTR_POWER_OPEN = 'power.open'</summary>
        public const string CmdStrPowerOpen = "power.open";

        /// <summary>Delphi: PG_CMDID_POWER_SEQ = 11</summary>
        public const int CmdIdPowerSeq = 11;
        /// <summary>Delphi: PG_CMDSTR_POWER_SEQ = 'power.seq'</summary>
        public const string CmdStrPowerSeq = "power.seq";

        /// <summary>Delphi: PG_CMDID_MODEL_CONFIG = 12</summary>
        public const int CmdIdModelConfig = 12;
        /// <summary>Delphi: PG_CMDSTR_MODEL_CONFIG = 'model.config'</summary>
        public const string CmdStrModelConfig = "model.config";

        /// <summary>Delphi: PG_CMDID_ALPM_CONFIG = 13</summary>
        public const int CmdIdAlpmConfig = 13;
        /// <summary>Delphi: PG_CMDSTR_ALPM_CONFIG = 'alpm.config'</summary>
        public const string CmdStrAlpmConfig = "alpm.config";

        /// <summary>Delphi: PG_CMDID_SET_MODEL_FILE = 15</summary>
        public const int CmdIdSetModelFile = 15;
        /// <summary>Delphi: PG_CMDSTR_SET_MODEL_FILE = 'model.file'</summary>
        public const string CmdStrSetModelFile = "model.file";

        /// <summary>Delphi: PG_CMDID_GET_MODEL = 16</summary>
        public const int CmdIdGetModel = 16;
        /// <summary>Delphi: PG_CMDSTR_GET_MODEL = 'model'</summary>
        public const string CmdStrGetModel = "model";

        /// <summary>Delphi: PG_CMDID_GET_MODEL_LIST = 17</summary>
        public const int CmdIdGetModelList = 17;
        /// <summary>Delphi: PG_CMDSTR_GET_MODEL_LIST = 'model.list'</summary>
        public const string CmdStrGetModelList = "model.list";

        // ---- Power On/Off ----

        /// <summary>Delphi: PG_CMDID_POWER_ON = 20</summary>
        public const int CmdIdPowerOn = 20;
        /// <summary>Delphi: PG_CMDSTR_POWER_ON = 'power.on'</summary>
        public const string CmdStrPowerOn = "power.on";

        /// <summary>Delphi: PG_CMDID_POWER_OFF = 21</summary>
        public const int CmdIdPowerOff = 21;
        /// <summary>Delphi: PG_CMDSTR_POWER_OFF = 'power.off'</summary>
        public const string CmdStrPowerOff = "power.off";

        /// <summary>Delphi: PG_CMDID_INTERPOSER_ON = 22</summary>
        public const int CmdIdInterposerOn = 22;
        /// <summary>Delphi: PG_CMDSTR_INTERPOSER_ON = 'interposer.init'</summary>
        public const string CmdStrInterposerOn = "interposer.init";

        /// <summary>Delphi: PG_CMDID_INTERPOSER_OFF = 23</summary>
        public const int CmdIdInterposerOff = 23;
        /// <summary>Delphi: PG_CMDSTR_INTERPOSER_OFF = 'interposer.deinit'</summary>
        public const string CmdStrInterposerOff = "interposer.deinit";

        /// <summary>Delphi: PG_CMDID_DUT_DETECT = 24</summary>
        public const int CmdIdDutDetect = 24;
        /// <summary>Delphi: PG_CMDSTR_DUT_DETECT = 'dut.detect'</summary>
        public const string CmdStrDutDetect = "dut.detect";

        /// <summary>Delphi: PG_CMDID_TCON_INFO = 25</summary>
        public const int CmdIdTconInfo = 25;
        /// <summary>Delphi: PG_CMDSTR_TCON_INFO = 'tcon.info'</summary>
        public const string CmdStrTconInfo = "tcon.info";

        /// <summary>Delphi: PG_CMDID_POWER_BIST_ON = 26</summary>
        public const int CmdIdPowerBistOn = 26;
        /// <summary>Delphi: PG_CMDSTR_POWER_BIST_ON = 'power.bist.on'</summary>
        public const string CmdStrPowerBistOn = "power.bist.on";

        /// <summary>Delphi: PG_CMDID_POWER_BIST_OFF = 27</summary>
        public const int CmdIdPowerBistOff = 27;
        /// <summary>Delphi: PG_CMDSTR_POWER_BIST_OFF = 'power.bist.off'</summary>
        public const string CmdStrPowerBistOff = "power.bist.off";

        /// <summary>Delphi: PG_CMDID_BIST_RGB = 28</summary>
        public const int CmdIdBistRgb = 28;
        /// <summary>Delphi: PG_CMDSTR_BIST_RGB = 'bist.rgb'</summary>
        public const string CmdStrBistRgb = "bist.rgb";

        /// <summary>Delphi: PG_CMDID_BIST_RGB_9BIT = 29</summary>
        public const int CmdIdBistRgb9Bit = 29;
        /// <summary>Delphi: PG_CMDSTR_BIST_RGB_9BIT = 'bist.9bit'</summary>
        public const string CmdStrBistRgb9Bit = "bist.9bit";

        // ---- Power measurement ----

        /// <summary>Delphi: PG_CMDID_POWER_READ = 30</summary>
        public const int CmdIdPowerRead = 30;
        /// <summary>Delphi: PG_CMDSTR_POWER_READ = 'power.read all'</summary>
        public const string CmdStrPowerRead = "power.read all";

        /// <summary>Delphi: PG_CMDID_POWER_VOLTAGE = 31</summary>
        public const int CmdIdPowerVoltage = 31;
        /// <summary>Delphi: PG_CMDSTR_POWER_VOLTAGE = 'power.voltage'</summary>
        public const string CmdStrPowerVoltage = "power.voltage";

        /// <summary>Delphi: PG_CMDID_POWER_CURRENT = 32</summary>
        public const int CmdIdPowerCurrent = 32;
        /// <summary>Delphi: PG_CMDSTR_POWER_CURRENT = 'power.current'</summary>
        public const string CmdStrPowerCurrent = "power.current";

        /// <summary>Delphi: PG_CMDID_BIST_APL = 33</summary>
        public const int CmdIdBistApl = 33;
        /// <summary>Delphi: PG_CMDSTR_BIST_APL = 'bist.box.apl'</summary>
        public const string CmdStrBistApl = "bist.box.apl";

        /// <summary>Delphi: PG_CMDID_SYS1V8_ON = 34</summary>
        public const int CmdIdSys1V8On = 34;
        /// <summary>Delphi: PG_CMDSTR_SYS1V8_ON = 'sys1v8.on'</summary>
        public const string CmdStrSys1V8On = "sys1v8.on";

        /// <summary>Delphi: PG_CMDID_SYS1V8_OFF = 35</summary>
        public const int CmdIdSys1V8Off = 35;
        /// <summary>Delphi: PG_CMDSTR_SYS1V8_OFF = 'sys1v8.off'</summary>
        public const string CmdStrSys1V8Off = "sys1v8.off";

        // ---- TCON R/W ----

        /// <summary>Delphi: PG_CMDID_TCON_READ = 40</summary>
        public const int CmdIdTconRead = 40;
        /// <summary>Delphi: PG_CMDSTR_TCON_READ = 'tcon.read'</summary>
        public const string CmdStrTconRead = "tcon.read";

        /// <summary>Delphi: PG_CMDID_TCON_WRITE = 41</summary>
        public const int CmdIdTconWrite = 41;
        /// <summary>Delphi: PG_CMDSTR_TCON_WRITE = 'tcon.write'</summary>
        public const string CmdStrTconWrite = "tcon.write";

        /// <summary>Delphi: PG_CMDID_TCON_OCWRITE = 42</summary>
        public const int CmdIdTconOcWrite = 42;
        /// <summary>Delphi: PG_CMDSTR_TCON_OCWRITE = 'tcon.ocwrite'</summary>
        public const string CmdStrTconOcWrite = "tcon.ocwrite";

        /// <summary>Delphi: PG_CMDID_TCON_MULTIWRITE = 43</summary>
        public const int CmdIdTconMultiWrite = 43;
        /// <summary>Delphi: PG_CMDSTR_TCON_MULTIWRITE = 'tcon.multiwrite'</summary>
        public const string CmdStrTconMultiWrite = "tcon.multiwrite";

        /// <summary>Delphi: PG_CMDID_TCON_SEQWRITE = 44</summary>
        public const int CmdIdTconSeqWrite = 44;
        /// <summary>Delphi: PG_CMDSTR_TCON_SEQWRITE = 'tcon.seqwrite'</summary>
        public const string CmdStrTconSeqWrite = "tcon.seqwrite";

        /// <summary>Delphi: PG_CMDID_TCON_WRITEREAD = 45</summary>
        public const int CmdIdTconWriteRead = 45;
        /// <summary>Delphi: PG_CMDSTR_TCON_WRITEREAD = 'tcon.writeread'</summary>
        public const string CmdStrTconWriteRead = "tcon.writeread";

        /// <summary>Delphi: PG_CMDID_TCON_BYTEREAD = 46</summary>
        public const int CmdIdTconByteRead = 46;
        /// <summary>Delphi: PG_CMDSTR_TCON_BYTEREAD = 'tcon.byteread'</summary>
        public const string CmdStrTconByteRead = "tcon.byteread";

        // ---- I2C R/W ----

        /// <summary>Delphi: PG_CMDID_I2C_READ = 47</summary>
        public const int CmdIdI2cRead = 47;
        /// <summary>Delphi: PG_CMDSTR_I2C_READ = 'i2c.read'</summary>
        public const string CmdStrI2cRead = "i2c.read";

        // ---- NVM (FLASH) R/W ----

        /// <summary>Delphi: PG_CMDID_NVM_INIT = 50</summary>
        public const int CmdIdNvmInit = 50;
        /// <summary>Delphi: PG_CMDSTR_NVM_INIT = 'nvm.init'</summary>
        public const string CmdStrNvmInit = "nvm.init";

        /// <summary>Delphi: PG_CMDID_NVM_ERASE = 51</summary>
        public const int CmdIdNvmErase = 51;
        /// <summary>Delphi: PG_CMDSTR_NVM_ERASE = 'nvm.erase'</summary>
        public const string CmdStrNvmErase = "nvm.erase";

        /// <summary>Delphi: PG_CMDID_NVM_READ = 52</summary>
        public const int CmdIdNvmRead = 52;
        /// <summary>Delphi: PG_CMDSTR_NVM_READ = 'nvm.read'</summary>
        public const string CmdStrNvmRead = "nvm.read";

        /// <summary>Delphi: PG_CMDID_NVM_READFILE = 54</summary>
        public const int CmdIdNvmReadFile = 54;
        /// <summary>Delphi: PG_CMDSTR_NVM_READFILE = 'nvm.readfile'</summary>
        public const string CmdStrNvmReadFile = "nvm.readfile";

        /// <summary>Delphi: PG_CMDID_NVM_WRITEFILE = 55</summary>
        public const int CmdIdNvmWriteFile = 55;
        /// <summary>Delphi: PG_CMDSTR_NVM_WRITEFILE = 'nvm.writefile'</summary>
        public const string CmdStrNvmWriteFile = "nvm.writefile";

        /// <summary>Delphi: PG_CMDID_NVM_READASCII = 56</summary>
        public const int CmdIdNvmReadAscii = 56;
        /// <summary>Delphi: PG_CMDSTR_NVM_READASCII = 'nvm.read_ascii'</summary>
        public const string CmdStrNvmReadAscii = "nvm.read_ascii";

        // ---- Pattern Display: RGB ----

        /// <summary>Delphi: PG_CMDID_IMAGE_RGB = 70</summary>
        public const int CmdIdImageRgb = 70;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_RGB = 'image.rgb'</summary>
        public const string CmdStrImageRgb = "image.rgb";

        // ---- Pattern Display: BMP ----

        /// <summary>Delphi: PG_CMDID_IMAGE_FILE = 72</summary>
        public const int CmdIdImageFile = 72;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_FILE = 'image.file'</summary>
        public const string CmdStrImageFile = "image.file";

        // ---- Pattern Display: Lookup Table ----

        /// <summary>Delphi: PG_CMDID_IMAGE_DISPLAY = 74</summary>
        public const int CmdIdImageDisplay = 74;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_DISPLAY = 'image.display'</summary>
        public const string CmdStrImageDisplay = "image.display";

        // ---- Pattern Tool ----

        /// <summary>Delphi: PG_CMDID_IMAGE_BOX = 80</summary>
        public const int CmdIdImageBox = 80;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_BOX = 'image.box'</summary>
        public const string CmdStrImageBox = "image.box";

        /// <summary>Delphi: PG_CMDID_IMAGE_EMPTYBOX = 81</summary>
        public const int CmdIdImageEmptyBox = 81;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_EMPTYBOX = 'image.emptybox'</summary>
        public const string CmdStrImageEmptyBox = "image.emptybox";

        /// <summary>Delphi: PG_CMDID_IMAGE_CIRCLE = 82</summary>
        public const int CmdIdImageCircle = 82;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_CIRCLE = 'image.circle'</summary>
        public const string CmdStrImageCircle = "image.circle";

        /// <summary>Delphi: PG_CMDID_IMAGE_LINE = 83</summary>
        public const int CmdIdImageLine = 83;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_LINE = 'image.line'</summary>
        public const string CmdStrImageLine = "image.line";

        /// <summary>Delphi: PG_CMDID_IMAGE_DOT = 84</summary>
        public const int CmdIdImageDot = 84;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_DOT = 'image.dot'</summary>
        public const string CmdStrImageDot = "image.dot";

        /// <summary>Delphi: PG_CMDID_IMAGE_HGRAY = 85</summary>
        public const int CmdIdImageHGray = 85;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_HGRAY = 'image.hgray'</summary>
        public const string CmdStrImageHGray = "image.hgray";

        /// <summary>Delphi: PG_CMDID_IMAGE_VGRAY = 86</summary>
        public const int CmdIdImageVGray = 86;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_VGRAY = 'image.vgray'</summary>
        public const string CmdStrImageVGray = "image.vgray";

        /// <summary>Delphi: PG_CMDID_IMAGE_CHECKER = 87</summary>
        public const int CmdIdImageChecker = 87;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_CHECKER = 'image.checker'</summary>
        public const string CmdStrImageChecker = "image.checker";

        /// <summary>Delphi: PG_CMDID_IMAGE_TILE = 88</summary>
        public const int CmdIdImageTile = 88;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_TILE = 'image.tile'</summary>
        public const string CmdStrImageTile = "image.tile";

        /// <summary>Delphi: PG_CMDID_IMAGE_TOOL = 89</summary>
        public const int CmdIdImageTool = 89;
        /// <summary>Delphi: PG_CMDSTR_IMAGE_TOOL = 'image.tool'</summary>
        public const string CmdStrImageTool = "image.tool";

        // ---- DBV / Programming ----

        /// <summary>Delphi: PG_CMDID_ALPDP_DBV = 101</summary>
        public const int CmdIdAlpdpDbv = 101;
        /// <summary>Delphi: PG_CMDSTR_ALPDP_DBV = 'alpdp.dbv'</summary>
        public const string CmdStrAlpdpDbv = "alpdp.dbv";

        /// <summary>Delphi: PG_CMDID_BIST_DBV = 102</summary>
        public const int CmdIdBistDbv = 102;
        /// <summary>Delphi: PG_CMDSTR_BIST_DBV = 'bist.dbv'</summary>
        public const string CmdStrBistDbv = "bist.dbv";

        /// <summary>Delphi: PG_CMDID_REPROGRAMING = 103</summary>
        public const int CmdIdReprograming = 103;
        /// <summary>Delphi: PG_CMDSTR_REPROGRAMING = 'programming.write'</summary>
        public const string CmdStrReprograming = "programming.write";

        /// <summary>Delphi: PG_CMDID_CHK_ENABLE = 104</summary>
        public const int CmdIdChkEnable = 104;
        /// <summary>Delphi: PG_CMDSTR_CHK_ENABLE = 'chk.enable'</summary>
        public const string CmdStrChkEnable = "chk.enable";

        // ---- System Commands ----

        /// <summary>Delphi: PG_CMDID_GET_BMP_LIST = 110</summary>
        public const int CmdIdGetBmpList = 110;
        /// <summary>Delphi: PG_CMDSTR_GET_BMP_LIST = 'bmp'</summary>
        public const string CmdStrGetBmpList = "bmp";

        /// <summary>Delphi: PG_CMDID_RESET = 119</summary>
        public const int CmdIdReset = 119;
        /// <summary>Delphi: PG_CMDSTR_RESET = 'reset'</summary>
        public const string CmdStrReset = "reset";

        /// <summary>Delphi: PG_CMDID_SYSTEM = 120</summary>
        public const int CmdIdSystem = 120;
        /// <summary>Delphi: PG_CMDSTR_SYSTEM = 'system'</summary>
        public const string CmdStrSystem = "system";

        /// <summary>Delphi: PG_CMDID_HELP = 121</summary>
        public const int CmdIdHelp = 121;
        /// <summary>Delphi: PG_CMDSTR_HELP = 'help'</summary>
        public const string CmdStrHelp = "help";

        // ---- OC T/T Test ----

        /// <summary>Delphi: PG_CMDID_OC_ONOFF = 130</summary>
        public const int CmdIdOcOnOff = 130;
        /// <summary>Delphi: PG_CMDSTR_OC_ONOFF = 'oc.onoff'</summary>
        public const string CmdStrOcOnOff = "oc.onoff";

        /// <summary>Delphi: PG_CMDID_GPIO_READ = 131</summary>
        public const int CmdIdGpioRead = 131;
        /// <summary>Delphi: PG_CMDSTR_GPIO_READ = 'gpio.read'</summary>
        public const string CmdStrGpioRead = "gpio.read";

        /// <summary>Delphi: PG_CMDID_GPIO_PANEL_IRQ = 132</summary>
        public const int CmdIdGpioPanelIrq = 132;
        /// <summary>Delphi: PG_CMDSTR_GPIO_PANEL_IRQ = 'gpio.read,panel_irq'</summary>
        public const string CmdStrGpioPanelIrq = "gpio.read,panel_irq";
    }

    /// <summary>
    /// DP860 power rail signal name constants.
    /// <para>Delphi: PGSIG_POWER_RAIL_* (PG_DP860 section)</para>
    /// </summary>
    public static class Dp860PowerRail
    {
        /// <summary>Delphi: PGSIG_POWER_RAIL_VDD1 = 'VCC'</summary>
        public const string Vdd1 = "VCC";

        /// <summary>Delphi: PGSIG_POWER_RAIL_VDD2 = 'VIN'</summary>
        public const string Vdd2 = "VIN";

        /// <summary>Delphi: PGSIG_POWER_RAIL_VDD3 = 'VDD3'</summary>
        public const string Vdd3 = "VDD3";

        /// <summary>Delphi: PGSIG_POWER_RAIL_VDD4 = 'VDD4'</summary>
        public const string Vdd4 = "VDD4";

        /// <summary>Delphi: PGSIG_POWER_RAIL_VDD5 = 'VDD5'</summary>
        public const string Vdd5 = "VDD5";
    }

    /// <summary>
    /// DP860 gradation direction constants.
    /// <para>Delphi: PGSIG_GRADATION_DIR_* (PG_DP860 section)</para>
    /// </summary>
    public static class Dp860GradationDir
    {
        /// <summary>Delphi: PGSIG_GRADATION_DIR_H_INC = 0 (0 left to 255 right)</summary>
        public const int HorizontalIncreasing = 0;

        /// <summary>Delphi: PGSIG_GRADATION_DIR_H_DEC = 1 (255 left to 0 right)</summary>
        public const int HorizontalDecreasing = 1;

        /// <summary>Delphi: PGSIG_GRADATION_DIR_V_INC = 0 (0 top to 255 bottom)</summary>
        public const int VerticalIncreasing = 0;

        /// <summary>Delphi: PGSIG_GRADATION_DIR_V_DEC = 1 (255 top to 0 bottom)</summary>
        public const int VerticalDecreasing = 1;
    }

    /// <summary>
    /// DP860 packet size constant.
    /// <para>Delphi: PG_PACKET_SIZE = 1024 (PG_DP860 section)</para>
    /// </summary>
    public static class Dp860Packet
    {
        /// <summary>Delphi: PG_PACKET_SIZE = 1024</summary>
        public const int PacketSize = 1024;
    }
}
