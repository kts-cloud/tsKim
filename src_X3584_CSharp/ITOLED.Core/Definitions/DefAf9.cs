// =============================================================================
// DefAf9.cs
// Converted from Delphi: DefAF9.pas + AF9_API.pas
// AF9 pattern generator definitions, P/Invoke DLL imports, power enums,
// and LGD command structures for the ITOLED inspection system.
// =============================================================================

using System.Runtime.InteropServices;

namespace Dongaeltek.ITOLED.Core.Definitions
{
    // =========================================================================
    //  AF9_API.pas - Constants
    // =========================================================================

    /// <summary>
    /// PCA9555 I/O expander Channel 0 power enable/disable bit masks.
    /// <para>Delphi: AF9_API.pas - PCA9555_CH0_* constants</para>
    /// </summary>
    public static class Pca9555Ch0
    {
        /// <summary>Delphi: PCA9555_CH0_LT3086_VDD_SD_EN = $0001 (1 &lt;&lt; 0)</summary>
        public const ushort Lt3086VddSdEn = 0x0001;

        /// <summary>Delphi: PCA9555_CH0_LT3086_VAA_AUX_EN = $0002 (1 &lt;&lt; 1)</summary>
        public const ushort Lt3086VaaAuxEn = 0x0002;

        /// <summary>Delphi: PCA9555_CH0_LTM8002_EN1 = $0004 (1 &lt;&lt; 2)</summary>
        public const ushort Ltm8002En1 = 0x0004;

        /// <summary>Delphi: PCA9555_CH0_LT3086_VCC_AUX_EN = $0008 (1 &lt;&lt; 3)</summary>
        public const ushort Lt3086VccAuxEn = 0x0008;

        /// <summary>Delphi: PCA9555_CH0_LTM8002_EN5 = $0010 (1 &lt;&lt; 4)</summary>
        public const ushort Ltm8002En5 = 0x0010;

        /// <summary>Delphi: PCA9555_CH0_LT3086_VTERM_EN = $0020 (1 &lt;&lt; 5)</summary>
        public const ushort Lt3086VtermEn = 0x0020;

        /// <summary>Delphi: PCA9555_CH0_LT3086_AVDDH_EN = $0040 (1 &lt;&lt; 6)</summary>
        public const ushort Lt3086AvddhEn = 0x0040;

        /// <summary>Delphi: PCA9555_CH0_LT3086_VDDEL_EN = $0080 (1 &lt;&lt; 7)</summary>
        public const ushort Lt3086VddelEn = 0x0080;

        /// <summary>Delphi: PCA9555_CH0_LT3091_VEE_AUX_EN = $0100 (1 &lt;&lt; 8)</summary>
        public const ushort Lt3091VeeAuxEn = 0x0100;

        /// <summary>Delphi: PCA9555_CH0_LT3091_VINI_EN = $0100 (1 &lt;&lt; 8, same as VEE_AUX)</summary>
        public const ushort Lt3091ViniEn = 0x0100;

        /// <summary>Delphi: PCA9555_CH0_LTM8002_EN2 = $0200 (1 &lt;&lt; 9)</summary>
        public const ushort Ltm8002En2 = 0x0200;

        /// <summary>Delphi: PCA9555_CH0_LTM8002_EN3 = $0400 (1 &lt;&lt; 10)</summary>
        public const ushort Ltm8002En3 = 0x0400;

        /// <summary>Delphi: PCA9555_CH0_LTM4651_EN2 = $0800 (1 &lt;&lt; 11)</summary>
        public const ushort Ltm4651En2 = 0x0800;

        /// <summary>Delphi: PCA9555_CH0_LT3091_VSSEL_EN = $1000 (1 &lt;&lt; 12)</summary>
        public const ushort Lt3091VsselEn = 0x1000;

        /// <summary>Delphi: PCA9555_CH0_LTM8002_EN6 = $2000 (1 &lt;&lt; 13)</summary>
        public const ushort Ltm8002En6 = 0x2000;

        /// <summary>Delphi: PCA9555_CH0_LT3086_VGH1_EN = $4000 (1 &lt;&lt; 14)</summary>
        public const ushort Lt3086Vgh1En = 0x4000;
    }

    /// <summary>
    /// PCA9555 I/O expander Channel 1 power enable/disable bit masks.
    /// <para>Delphi: AF9_API.pas - PCA9555_CH1_* constants</para>
    /// </summary>
    public static class Pca9555Ch1
    {
        /// <summary>Delphi: PCA9555_CH1_LT3086_VGH2_EN = $0001 (1 &lt;&lt; 0)</summary>
        public const ushort Lt3086Vgh2En = 0x0001;

        /// <summary>Delphi: PCA9555_CH1_LTM4651_EN3 = $0002 (1 &lt;&lt; 1)</summary>
        public const ushort Ltm4651En3 = 0x0002;

        /// <summary>Delphi: PCA9555_CH1_LT3091_VGL1_EN = $0004 (1 &lt;&lt; 2)</summary>
        public const ushort Lt3091Vgl1En = 0x0004;

        /// <summary>Delphi: PCA9555_CH1_LTM8002_EN7 = $0008 (1 &lt;&lt; 3)</summary>
        public const ushort Ltm8002En7 = 0x0008;

        /// <summary>Delphi: PCA9555_CH1_LT3086_LGD_AUX1_EN = $0010 (1 &lt;&lt; 4)</summary>
        public const ushort Lt3086LgdAux1En = 0x0010;

        /// <summary>Delphi: PCA9555_CH1_LT3086_LGD_AUX2_EN = $0020 (1 &lt;&lt; 5)</summary>
        public const ushort Lt3086LgdAux2En = 0x0020;

        /// <summary>Delphi: PCA9555_CH1_LT3091_VGL2_EN = $0040 (1 &lt;&lt; 6)</summary>
        public const ushort Lt3091Vgl2En = 0x0040;

        /// <summary>Delphi: PCA9555_CH1_LTM4651_EN4 = $0080 (1 &lt;&lt; 7)</summary>
        public const ushort Ltm4651En4 = 0x0080;
    }

    /// <summary>
    /// PCA9555 I/O expander Channel 3 power enable/disable bit masks.
    /// <para>Delphi: AF9_API.pas - PCA9555_CH3_* constants</para>
    /// </summary>
    public static class Pca9555Ch3
    {
        /// <summary>Delphi: PCA9555_CH3_LT3086_VOBS1_EN = $0001 (1 &lt;&lt; 0)</summary>
        public const ushort Lt3086Vobs1En = 0x0001;

        /// <summary>Delphi: PCA9555_CH3_LT3086_VOBS2_EN = $0002 (1 &lt;&lt; 1)</summary>
        public const ushort Lt3086Vobs2En = 0x0002;

        /// <summary>Delphi: PCA9555_CH3_LT3091_VAR1_R_EN = $0004 (1 &lt;&lt; 2)</summary>
        public const ushort Lt3091Var1REn = 0x0004;

        /// <summary>Delphi: PCA9555_CH3_LT3091_VAR1_GB_EN = $0008 (1 &lt;&lt; 3)</summary>
        public const ushort Lt3091Var1GbEn = 0x0008;

        /// <summary>Delphi: PCA9555_CH3_LT3091_VAR2_EN = $0010 (1 &lt;&lt; 4)</summary>
        public const ushort Lt3091Var2En = 0x0010;
    }

    /// <summary>
    /// AF9 general enable/disable and I/O constants.
    /// <para>Delphi: AF9_API.pas - AF9_ENABLE, AF9_DISABLE, AF9_ON, AF9_OFF, AF9_EXTENDIO_*, AF9_PWR_*</para>
    /// </summary>
    public static class Af9General
    {
        /// <summary>Delphi: AF9_ENABLE = 1</summary>
        public const int Enable = 1;

        /// <summary>Delphi: AF9_DISABLE = 0</summary>
        public const int Disable = 0;

        /// <summary>Delphi: AF9_ON = 1</summary>
        public const int On = 1;

        /// <summary>Delphi: AF9_OFF = 0</summary>
        public const int Off = 0;

        /// <summary>Delphi: AF9_EXTENDIO_1 = 0</summary>
        public const int ExtendIo1 = 0;

        /// <summary>Delphi: AF9_EXTENDIO_2 = 1</summary>
        public const int ExtendIo2 = 1;

        /// <summary>Delphi: AF9_EXTENDIO_3 = 2</summary>
        public const int ExtendIo3 = 2;

        /// <summary>Delphi: AF9_EXTENDIO_4 = 3</summary>
        public const int ExtendIo4 = 3;

        /// <summary>Delphi: AF9_PWR_PLUS = 1</summary>
        public const int PwrPlus = 1;

        /// <summary>Delphi: AF9_PWR_MINUS = 2</summary>
        public const int PwrMinus = 2;
    }

    // =========================================================================
    //  AF9_API.pas - Power Voltage Enums
    // =========================================================================

    /// <summary>
    /// Power voltage DAC channels - Channel 1.
    /// <para>Delphi: AF9_enumPOWER_CH1</para>
    /// </summary>
    public enum Af9PowerCh1
    {
        /// <summary>Delphi: LTM8002_VDAC1 = 0</summary>
        Ltm8002Vdac1 = 0,

        /// <summary>Delphi: LT3086_VAA_AUX_VDAC</summary>
        Lt3086VaaAuxVdac,

        /// <summary>Delphi: VCC_AUX_VDAC</summary>
        VccAuxVdac,

        /// <summary>Delphi: LT3091_VINI_VDAC</summary>
        Lt3091ViniVdac,

        /// <summary>Delphi: LTM8002_OUT2_VDAC</summary>
        Ltm8002Out2Vdac,

        /// <summary>Delphi: LT3086_VDD_SD_VDAC</summary>
        Lt3086VddSdVdac,

        /// <summary>Delphi: LT3086_VTERM_VDAC</summary>
        Lt3086VtermVdac,

        /// <summary>Delphi: LTM8002_OUT3_VDAC</summary>
        Ltm8002Out3Vdac,

        /// <summary>Delphi: LT3086_AVDDH_VDAC</summary>
        Lt3086AvddhVdac,

        /// <summary>Delphi: LTM8002_OUT5_VDAC</summary>
        Ltm8002Out5Vdac,

        /// <summary>Delphi: LT3086_VDDEL_VDAC</summary>
        Lt3086VddelVdac,

        /// <summary>Delphi: LTM8002_OUT6_VDAC</summary>
        Ltm8002Out6Vdac,

        /// <summary>Delphi: LT3086_VGH1_VDAC</summary>
        Lt3086Vgh1Vdac,

        /// <summary>Delphi: LT3086_VGH2_VDAC</summary>
        Lt3086Vgh2Vdac,

        /// <summary>Delphi: LTM8002_OUT7_VDAC</summary>
        Ltm8002Out7Vdac,
    }

    /// <summary>
    /// Power voltage DAC channels - Channel 2.
    /// <para>Delphi: AF9_enumPOWER_CH2</para>
    /// </summary>
    public enum Af9PowerCh2
    {
        /// <summary>Delphi: LTM4651_OUT3_VDAC = 100</summary>
        Ltm4651Out3Vdac = 100,

        /// <summary>Delphi: LT3091_VGL1_VDAC</summary>
        Lt3091Vgl1Vdac,

        /// <summary>Delphi: LT3091_VGL2_VDAC</summary>
        Lt3091Vgl2Vdac,

        /// <summary>Delphi: LTM4651_OUT4_VDAC</summary>
        Ltm4651Out4Vdac,

        /// <summary>Delphi: TPS61175_OUT2_VDAC</summary>
        Tps61175Out2Vdac,

        /// <summary>Delphi: LGD_AUX1_VDAC</summary>
        LgdAux1Vdac,

        /// <summary>Delphi: LGD_AUX2_VDAC</summary>
        LgdAux2Vdac,

        /// <summary>Delphi: LTM4651_OUT2_VDAC</summary>
        Ltm4651Out2Vdac,
    }

    /// <summary>
    /// Power voltage DAC channels - Channel 3.
    /// <para>Delphi: AF9_enumPOWER_CH3</para>
    /// </summary>
    public enum Af9PowerCh3
    {
        /// <summary>Delphi: LT3091_VSSEL_VDAC = 200</summary>
        Lt3091VsselVdac = 200,

        /// <summary>Delphi: DAC_VSSEL_OPAMP</summary>
        DacVsselOpamp,

        /// <summary>Delphi: LT3086_VOBS1_VDAC</summary>
        Lt3086Vobs1Vdac,

        /// <summary>Delphi: DAC_VOBS1_OPAMP</summary>
        DacVobs1Opamp,

        /// <summary>Delphi: LT3086_VOBS2_VDAC</summary>
        Lt3086Vobs2Vdac,

        /// <summary>Delphi: DAC_VOBS2_OPAMP</summary>
        DacVobs2Opamp,

        /// <summary>Delphi: DAC_VINI_OPAMP</summary>
        DacViniOpamp,

        /// <summary>Delphi: LT3091_VAR1_VDAC</summary>
        Lt3091Var1Vdac,

        /// <summary>Delphi: DAC_VAR1_OPAMP</summary>
        DacVar1Opamp,

        /// <summary>Delphi: LT3091_VAR2_VDAC</summary>
        Lt3091Var2Vdac,

        /// <summary>Delphi: DAC_VAR2_OPAMP</summary>
        DacVar2Opamp,

        /// <summary>Delphi: LT3091_VAR1_R_VDAC</summary>
        Lt3091Var1RVdac,

        /// <summary>Delphi: LT3091_VAR2_R_VDAC</summary>
        Lt3091Var2RVdac,

        /// <summary>Delphi: LT3091_VAR1_GB_VDAC</summary>
        Lt3091Var1GbVdac,

        /// <summary>Delphi: LT3091_VAR2_GB_VDAC</summary>
        Lt3091Var2GbVdac,
    }

    /// <summary>
    /// Power DAC type classification.
    /// <para>Delphi: AF9_enumPOWER_DAC_TYPE</para>
    /// </summary>
    public enum Af9PowerDacType
    {
        /// <summary>Delphi: LTM8002_TYPE = 0</summary>
        Ltm8002Type = 0,

        /// <summary>Delphi: LT3086_TYPE</summary>
        Lt3086Type,

        /// <summary>Delphi: LTM4651_TYPE</summary>
        Ltm4651Type,

        /// <summary>Delphi: LT3091_TYPE</summary>
        Lt3091Type,

        /// <summary>Delphi: TPS61175</summary>
        Tps61175,

        /// <summary>Delphi: DAC_TYPE</summary>
        DacType,
    }

    /// <summary>
    /// AF9 USB channel type.
    /// <para>Delphi: AF9_enumCHANNEL_TYPE</para>
    /// </summary>
    public enum Af9ChannelType
    {
        /// <summary>Delphi: AF9CH_ALL = 0</summary>
        All = 0,

        /// <summary>Delphi: AF9CH_1</summary>
        Ch1,

        /// <summary>Delphi: AF9CH_2</summary>
        Ch2,
    }

    /// <summary>
    /// LGD command structure for batch register writes.
    /// <para>Delphi: AF9_TLGDCommand (packed record: Addr:DWORD + Data:Byte)</para>
    /// </summary>
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct Af9LgdCommand
    {
        /// <summary>Delphi: Addr : DWORD (unsigned long)</summary>
        public uint Addr;

        /// <summary>Delphi: Data : Byte (unsigned char)</summary>
        public byte Data;
    }

    // =========================================================================
    //  DefAF9.pas - Constants
    // =========================================================================

    /// <summary>
    /// AF9 API constants specific to ITOLED.
    /// <para>Delphi: DefAF9.pas constants section</para>
    /// </summary>
    public static class DefAf9Constants
    {
        /// <summary>Delphi: AF9API_STARTCONN_USB_OPENFAIL = -1</summary>
        public const int StartConnUsbOpenFail = -1;

        /// <summary>Delphi: AF9API_STARTCONN_USB_NOTFOUND = 0</summary>
        public const int StartConnUsbNotFound = 0;

        /// <summary>Delphi: AF9API_STARTCONN_OK = 1</summary>
        public const int StartConnOk = 1;

        /// <summary>Delphi: AF9API_RESULT_OK = 1</summary>
        public const int ResultOk = 1;

        /// <summary>Delphi: AF9API_RESULT_NG = 0</summary>
        public const int ResultNg = 0;

        /// <summary>Delphi: CMD_DISPLAY_OFF = 0</summary>
        public const int DisplayOff = 0;

        /// <summary>Delphi: CMD_DISPLAY_ON = 1</summary>
        public const int DisplayOn = 1;

        /// <summary>Delphi: LGD_REG_DEVICE = $A0 (arbitrary I2C address for T-CON)</summary>
        public const byte LgdRegDevice = 0xA0;

        /// <summary>Delphi: APS_REG_DEVICE = $B0 (arbitrary I2C address for APS registers)</summary>
        public const byte ApsRegDevice = 0xB0;

        /// <summary>Delphi: PG_TYPE_AF9 = 9</summary>
        public const int PgTypeAf9 = 9;

        /// <summary>Delphi: MAX_FLASHSIZE_BYTE = 4*1024*1024 (4 MB)</summary>
        public const int MaxFlashSizeByte = 4 * 1024 * 1024;
    }

    // =========================================================================
    //  DefAF9.pas - Enums
    // =========================================================================

    /// <summary>
    /// AF9 PG connection status.
    /// <para>Delphi: enumPgConnSt</para>
    /// </summary>
    public enum Af9PgConnectionStatus
    {
        /// <summary>Delphi: pgConnStDisconn = 0</summary>
        Disconnected = 0,

        /// <summary>Delphi: pgConnStStart = 1 (Start_Connection called)</summary>
        Started = 1,

        /// <summary>Delphi: pgConnStConn = 2 (Conn_Status OK, SW_Revision done)</summary>
        Connected = 2,
    }

    /// <summary>
    /// AF9 power value record.
    /// <para>Delphi: RPwrValAF9 / RPwrVal</para>
    /// </summary>
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct Af9PwrVal
    {
        /// <summary>Delphi: A : integer</summary>
        public int A;
    }

    // =========================================================================
    //  DefAF9.pas - AF9 API DLL P/Invoke Declarations
    //  Native DLL: AF9_API2.dll
    // =========================================================================

    /// <summary>
    /// P/Invoke wrapper for AF9_API2.dll - single channel (1CH) API functions.
    /// <para>Delphi: AF9API_* function declarations with 'external AF9API_DLL'</para>
    /// </summary>
    public static class Af9Api
    {
        /// <summary>Delphi: AF9API_DLL = 'AF9_API2.dll'</summary>
        public const string DllName = "AF9_API2.dll";

        // =====================================================================
        //  1CH API
        // =====================================================================

        /// <summary>
        /// Start the USB connection.
        /// <para>Delphi: AF9API_Start_Connection -> DLL 'Start_Connection'</para>
        /// </summary>
        /// <returns>-1: USB library open fail, 0: No USB device found, 1: USB device found and connect ok.</returns>
        [DllImport(DllName, EntryPoint = "Start_Connection", CallingConvention = CallingConvention.StdCall)]
        public static extern int StartConnection();

        /// <summary>
        /// Stop the USB connection.
        /// <para>Delphi: AF9API_Stop_Connection -> DLL 'Stop_Connection'</para>
        /// </summary>
        /// <returns>0: USB device stop fail, 1: USB device stop and USB device release.</returns>
        [DllImport(DllName, EntryPoint = "Stop_Connection", CallingConvention = CallingConvention.StdCall)]
        public static extern int StopConnection();

        /// <summary>
        /// Read the connection status of USB.
        /// <para>Delphi: AF9API_Connection_Status -> DLL 'Connection_Status'</para>
        /// </summary>
        /// <returns>0: USB connection is not working, 1: USB connected.</returns>
        [DllImport(DllName, EntryPoint = "Connection_Status", CallingConvention = CallingConvention.StdCall)]
        public static extern int ConnectionStatus();

        /// <summary>
        /// Read the FPGA IP version.
        /// <para>Delphi: AF9API_SW_Revision -> DLL 'SW_Revision'</para>
        /// </summary>
        /// <returns>FPGA IP Version (xxx).</returns>
        [DllImport(DllName, EntryPoint = "SW_Revision", CallingConvention = CallingConvention.StdCall)]
        public static extern int SwRevision();

        /// <summary>
        /// Read the DLL version.
        /// <para>Delphi: AF9API_DLL_Revision -> DLL 'DLL_Revision'</para>
        /// </summary>
        /// <returns>DLL version (x.xx).</returns>
        [DllImport(DllName, EntryPoint = "DLL_Revision", CallingConvention = CallingConvention.StdCall)]
        public static extern int DllRevision();

        /// <summary>
        /// Set the voltage of the power.
        /// <para>Delphi: AF9API_DAC_SET -> DLL 'DAC_SET'</para>
        /// </summary>
        /// <param name="nType">Power type.</param>
        /// <param name="channel">Power channel.</param>
        /// <param name="voltage">Power voltage (mV, absolute value).</param>
        /// <param name="option">Power option (1: plus voltage, 2: minus voltage).</param>
        /// <returns>0: Failed, 1: Success.</returns>
        [DllImport(DllName, EntryPoint = "DAC_SET", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DacSet(int nType, int channel, int voltage, int option);

        /// <summary>
        /// Turn on/off the power.
        /// <para>Delphi: AF9API_ExtendIO_Set -> DLL 'ExtendIO_Set'</para>
        /// </summary>
        /// <param name="address">Power address.</param>
        /// <param name="channel">Power channel.</param>
        /// <param name="enable">Enable/disable.</param>
        /// <returns>0: Failed, 1: Success.</returns>
        [DllImport(DllName, EntryPoint = "ExtendIO_Set", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ExtendIoSet(int address, int channel, int enable);

        /// <summary>
        /// Turn on/off all power and initialize module.
        /// <para>Delphi: AF9API_AllPowerOnOff -> DLL 'AllPowerOnOff'</para>
        /// </summary>
        /// <param name="onOff">ON or OFF.</param>
        /// <returns>0: Failed, 1: Success.</returns>
        [DllImport(DllName, EntryPoint = "AllPowerOnOff", CallingConvention = CallingConvention.StdCall)]
        public static extern int AllPowerOnOff(int onOff);

        /// <summary>
        /// Display RGB Gray pattern.
        /// <para>Delphi: AF9API_APSPatternRGBSet -> DLL 'APSPatternRGBSet'</para>
        /// </summary>
        /// <param name="r">Red color (0-255).</param>
        /// <param name="g">Green color (0-255).</param>
        /// <param name="b">Blue color (0-255).</param>
        /// <returns>0: Display fail, 1: Display success.</returns>
        [DllImport(DllName, EntryPoint = "APSPatternRGBSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsPatternRgbSet(int r, int g, int b);

        /// <summary>
        /// Display BOX RGB Gray pattern.
        /// <para>Delphi: AF9API_APSBoxPatternSet -> DLL 'APSBoxPatternSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "APSBoxPatternSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsBoxPatternSet(int xOffset, int yOffset, int width, int height,
            int r, int g, int b, int br, int bg, int bb);

        /// <summary>
        /// Set LGD internal register (single write).
        /// <para>Delphi: AF9API_LGDSetReg -> DLL 'LGDSetReg'</para>
        /// </summary>
        /// <param name="addr">Register address.</param>
        /// <param name="data">Register data.</param>
        /// <returns>0: Setting fail, 1: Setting success.</returns>
        [DllImport(DllName, EntryPoint = "LGDSetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern int LgdSetReg(uint addr, byte data);

        /// <summary>
        /// Set LGD internal registers (batch write).
        /// <para>Delphi: AF9API_LGDSetRegM -> DLL 'LGDSetRegM'</para>
        /// </summary>
        /// <param name="lgdCommand">Pointer to array of AF9_TLGDCommand.</param>
        /// <param name="commandCnt">Number of commands.</param>
        /// <returns>0: Setting fail, 1: Setting success.</returns>
        [DllImport(DllName, EntryPoint = "LGDSetRegM", CallingConvention = CallingConvention.StdCall)]
        public static extern int LgdSetRegM([In] Af9LgdCommand[] lgdCommand, int commandCnt);

        /// <summary>
        /// Read LGD internal register.
        /// <para>Delphi: AF9API_LGDGetReg -> DLL 'LGDGetReg'</para>
        /// </summary>
        /// <param name="addr">Register address.</param>
        /// <returns>The data value of bytes received.</returns>
        [DllImport(DllName, EntryPoint = "LGDGetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern byte LgdGetReg(uint addr);

        /// <summary>
        /// Read LGD internal registers (range read).
        /// <para>Delphi: AF9API_LGDRangeGetReg -> DLL 'LGDRangeGetReg'</para>
        /// </summary>
        /// <param name="pBuffer">Output buffer.</param>
        /// <param name="startAddr">Start address.</param>
        /// <param name="endAddr">End address.</param>
        /// <returns>0: Read fail, 1: Read success.</returns>
        [DllImport(DllName, EntryPoint = "LGDRangeGetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern byte LgdRangeGetReg([Out] byte[] pBuffer, uint startAddr, uint endAddr);

        /// <summary>
        /// Set APSOLUTION internal register.
        /// <para>Delphi: AF9API_APSSetReg -> DLL 'APSSetReg'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "APSSetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsSetReg(int addr, int data);

        /// <summary>
        /// Send hex file CRC checksum.
        /// <para>Delphi: AF9API_SendHexFileCRC -> DLL 'SendHexFileCRC'</para>
        /// </summary>
        /// <param name="crc">Checksum data (sum of all values and 0xFFFF).</param>
        /// <returns>0: Send fail, 1: Send success.</returns>
        [DllImport(DllName, EntryPoint = "SendHexFileCRC", CallingConvention = CallingConvention.StdCall)]
        public static extern int SendHexFileCrc(ushort crc);

        /// <summary>
        /// Send hex file and write to SPI flash.
        /// <para>Delphi: AF9API_SendHexFile -> DLL 'SendHexFile'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "SendHexFile", CallingConvention = CallingConvention.StdCall)]
        public static extern int SendHexFile([In] byte[] pbyteBuffer, int len);

        /// <summary>
        /// Send hex file for OC and write to SPI flash.
        /// <para>Delphi: AF9API_SendHexFileOC -> DLL 'SendHexFileOC'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "SendHexFileOC", CallingConvention = CallingConvention.StdCall)]
        public static extern int SendHexFileOc([In] byte[] pbyteBuffer, int len);

        /// <summary>
        /// Send BMP file (raw data) and display.
        /// <para>Delphi: AF9API_WriteBMPFile -> DLL 'WriteBMPFile'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "WriteBMPFile", CallingConvention = CallingConvention.StdCall)]
        public static extern int WriteBmpFile([In] byte[] pbyteBuffer, int len);

        /// <summary>
        /// Send BMP file (store in numbered slot).
        /// <para>Delphi: AF9API_BMPFileSend -> DLL 'BMPFileSend'</para>
        /// </summary>
        /// <param name="pbyteBuffer">Raw data buffer.</param>
        /// <param name="len">Buffer length.</param>
        /// <param name="num">Image file number (1-20).</param>
        [DllImport(DllName, EntryPoint = "BMPFileSend", CallingConvention = CallingConvention.StdCall)]
        public static extern int BmpFileSend([In] byte[] pbyteBuffer, int len, int num);

        /// <summary>
        /// Show stored BMP file by number.
        /// <para>Delphi: AF9API_BMPFileView -> DLL 'BMPFileView'</para>
        /// </summary>
        /// <param name="num">Image file number (1-20).</param>
        [DllImport(DllName, EntryPoint = "BMPFileView", CallingConvention = CallingConvention.StdCall)]
        public static extern int BmpFileView(int num);

        /// <summary>
        /// Read data from SPI flash.
        /// <para>Delphi: AF9API_FLASHRead -> DLL 'FLASHRead'</para>
        /// </summary>
        /// <param name="pBuffer">Output buffer.</param>
        /// <param name="startAddr">Start address (align 256 bytes).</param>
        /// <param name="endAddr">End address (align 256 bytes).</param>
        [DllImport(DllName, EntryPoint = "FLASHRead", CallingConvention = CallingConvention.StdCall)]
        public static extern byte FlashRead([Out] byte[] pBuffer, uint startAddr, uint endAddr);

        /// <summary>
        /// FRR (Frame Rate Reduction) function.
        /// <para>Delphi: AF9API_FrrSet -> DLL 'FrrSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "FrrSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int FrrSet(int frrStart,
            byte r, byte g, byte b, byte br, byte bg, byte bb,
            byte ptn1, byte ptn2, byte ptn3, byte ptn4, byte ptn5, byte ptn6,
            int hz);

        /// <summary>
        /// Display RGB Dot patterns.
        /// <para>Delphi: AF9API_APSDotPatternRGBSet -> DLL 'APSDotPatternRGBSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "APSDotPatternRGBSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsDotPatternRgbSet(int fr, int fg, int fb, int br, int bg, int bb);

        /// <summary>
        /// Display RGB Line Dot patterns.
        /// <para>Delphi: AF9API_APSLineDotPatternRGBSet -> DLL 'APSLineDotPatternRGBSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "APSLineDotPatternRGBSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsLineDotPatternRgbSet(int fr, int fg, int fb, int br, int bg, int bb);

        // =====================================================================
        //  MULTI (2CH) API
        // =====================================================================

        /// <summary>
        /// Start the multi USB connection.
        /// <para>Delphi: AF9API_MULTI_Start_Connection -> DLL 'MULTI_Start_Connection'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_Start_Connection", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiStartConnection();

        /// <summary>
        /// Read multi USB connection status.
        /// <para>Delphi: AF9API_MULTI_Connection_Status -> DLL 'MULTI_Connection_Status'</para>
        /// </summary>
        /// <param name="ch">USB device channel (CH1, CH2).</param>
        [DllImport(DllName, EntryPoint = "MULTI_Connection_Status", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiConnectionStatus(int ch);

        /// <summary>
        /// Read multiple FPGA IP versions.
        /// <para>Delphi: AF9API_MULTI_SW_Revision -> DLL 'MULTI_SW_Revision'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_SW_Revision", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiSwRevision(int ch);

        /// <summary>
        /// Set the voltage of multiple power.
        /// <para>Delphi: AF9API_MULTI_DAC_SET -> DLL 'MULTI_DAC_SET'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_DAC_SET", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool MultiDacSet(int nType, int channel, int voltage, int option, int ch);

        /// <summary>
        /// Turn on/off multiple power.
        /// <para>Delphi: AF9API_MULTI_ExtendIO_Set -> DLL 'MULTI_ExtendIO_Set'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_ExtendIO_Set", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool MultiExtendIoSet(int address, int channel, int enable, int ch);

        /// <summary>
        /// Multiple turn on/off all power and initialize module.
        /// <para>Delphi: AF9API_MULTI_AllPowerOnOff -> DLL 'MULTI_AllPowerOnOff'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_AllPowerOnOff", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiAllPowerOnOff(int onOff, int ch);

        /// <summary>
        /// Display multiple RGB Gray patterns.
        /// <para>Delphi: AF9API_MULTI_APSPatternRGBSet -> DLL 'MULTI_APSPatternRGBSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_APSPatternRGBSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiApsPatternRgbSet(int r, int g, int b, int ch);

        /// <summary>
        /// Display multiple BOX RGB Gray pattern.
        /// <para>Delphi: AF9API_MULTI_APSBoxPatternSet -> DLL 'MULTI_APSBoxPatternSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_APSBoxPatternSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiApsBoxPatternSet(int xOffset, int yOffset, int width, int height,
            int r, int g, int b, int br, int bg, int bb, int ch);

        /// <summary>
        /// Multiple set LGD internal register.
        /// <para>Delphi: AF9API_MULTI_LGDSetReg -> DLL 'MULTI_LGDSetReg'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_LGDSetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiLgdSetReg(uint addr, byte data, int ch);

        /// <summary>
        /// Multiple set LGD internal registers (batch).
        /// <para>Delphi: AF9API_MULTI_LGDSetRegM -> DLL 'MULTI_LGDSetRegM'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_LGDSetRegM", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiLgdSetRegM([In] Af9LgdCommand[] lgdCommand, int commandCnt, int ch);

        /// <summary>
        /// Multiple read LGD internal register.
        /// <para>Delphi: AF9API_MULTI_LGDGetReg -> DLL 'MULTI_LGDGetReg'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_LGDGetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern byte MultiLgdGetReg(uint addr, int ch);

        /// <summary>
        /// Multiple read LGD internal registers (range).
        /// <para>Delphi: AF9API_MULTI_LGDRangeGetReg -> DLL 'MULTI_LGDRangeGetReg'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_LGDRangeGetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern byte MultiLgdRangeGetReg([Out] byte[] pBuffer, uint startAddr, uint endAddr, int ch);

        /// <summary>
        /// Multiple set APSOLUTION internal register.
        /// <para>Delphi: AF9API_MULTI_APSSetReg -> DLL 'MULTI_APSSetReg'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_APSSetReg", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiApsSetReg(int addr, int data, int ch);

        /// <summary>
        /// Multiple send hex file CRC.
        /// <para>Delphi: AF9API_MULTI_SendHexFileCRC -> DLL 'MULTI_SendHexFileCRC'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_SendHexFileCRC", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiSendHexFileCrc(ushort crc, int ch);

        /// <summary>
        /// Multiple send hex file and write to SPI flash.
        /// <para>Delphi: AF9API_MULTI_SendHexFile -> DLL 'MULTI_SendHexFile'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_SendHexFile", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiSendHexFile([In] byte[] pbyteBuffer, int len, int ch);

        /// <summary>
        /// Multiple send hex file for OC and write to SPI flash.
        /// <para>Delphi: AF9API_MULTI_SendHexFileOC -> DLL 'MULTI_SendHexFileOC'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_SendHexFileOC", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiSendHexFileOc([In] byte[] pbyteBuffer, int len, int ch);

        /// <summary>
        /// Multiple send BMP file and display.
        /// <para>Delphi: AF9API_MULTI_WriteBMPFile -> DLL 'MULTI_WriteBMPFile'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_WriteBMPFile", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiWriteBmpFile([In] byte[] pbyteBuffer, int len, int ch);

        /// <summary>
        /// Multiple send BMP files (store in numbered slot).
        /// <para>Delphi: AF9API_MULTI_BMPFileSend -> DLL 'MULTI_BMPFileSend'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_BMPFileSend", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiBmpFileSend([In] byte[] pbyteBuffer, int len, int num, int ch);

        /// <summary>
        /// Show multiple BMP file by number.
        /// <para>Delphi: AF9API_MULTI_BMPFileView -> DLL 'MULTI_BMPFileView'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_BMPFileView", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiBmpFileView(int num, int ch);

        /// <summary>
        /// Multiple read data from SPI flash.
        /// <para>Delphi: AF9API_MULTI_FLASHRead -> DLL 'MULTI_FLASHRead'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_FLASHRead", CallingConvention = CallingConvention.StdCall)]
        public static extern byte MultiFlashRead([Out] byte[] pBuffer, uint startAddr, uint endAddr, int ch);

        /// <summary>
        /// Multiple FRR function.
        /// <para>Delphi: AF9API_MULTI_FrrSet -> DLL 'MULTI_FrrSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_FrrSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiFrrSet(int frrStart,
            byte r, byte g, byte b, byte br, byte bg, byte bb,
            byte ptn1, byte ptn2, byte ptn3, byte ptn4, byte ptn5, byte ptn6,
            int hz, int ch);

        /// <summary>
        /// Multiple display RGB Dot patterns.
        /// <para>Delphi: AF9API_MULTI_APSDotPatternRGBSet -> DLL 'MULTI_APSDotPatternRGBSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_APSDotPatternRGBSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiApsDotPatternRgbSet(int fr, int fg, int fb, int br, int bg, int bb, int ch);

        /// <summary>
        /// Multiple display RGB Line Dot patterns.
        /// <para>Delphi: AF9API_MULTI_APSLineDotPatternRGBSet -> DLL 'MULTI_APSLineDotPatternRGBSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "MULTI_APSLineDotPatternRGBSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int MultiApsLineDotPatternRgbSet(int fr, int fg, int fb, int br, int bg, int bb, int ch);

        // =====================================================================
        //  Utility / Legacy API
        // =====================================================================

        /// <summary>
        /// Free AF9 API resources.
        /// <para>Delphi: AF9API_FreeAF9API -> DLL 'FreeAF9API'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "FreeAF9API", CallingConvention = CallingConvention.StdCall)]
        public static extern void FreeAf9Api();

        /// <summary>
        /// Validate USB handler.
        /// <para>Delphi: AF9API_IsVaildUSBHandler -> DLL 'IsVaildUSBHandler'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "IsVaildUSBHandler", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool IsValidUsbHandler();

        /// <summary>
        /// Set display resolution.
        /// <para>Delphi: AF9API_SetResolution -> DLL 'SetResolution'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "SetResolution", CallingConvention = CallingConvention.StdCall)]
        public static extern int SetResolution(int resHRes, int resHBp, int resHSa, int resHFp,
            int resVRes, int resVBp, int resVSa, int resVFp);

        /// <summary>
        /// Set frequency change.
        /// <para>Delphi: AF9API_SetFreqChange -> DLL 'SetFreqChange'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "SetFreqChange", CallingConvention = CallingConvention.StdCall)]
        public static extern int SetFreqChange([In] byte[] pbyteBuffer, int len, int hzCnt, int nRepeat);

        /// <summary>
        /// APS FRR Set (legacy).
        /// <para>Delphi: AF9API_APSFrrSet -> DLL 'APSFrrSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "APSFrrSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsFrrSet(int frrStart,
            byte r, byte g, byte b, byte br, byte bg, byte bb,
            byte ptnCnt, uint ptn);

        /// <summary>
        /// APS FRR Set 2 (with Hz parameter).
        /// <para>Delphi: AF9API_APSFrrSet2 -> DLL 'APSFrrSet2'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "APSFrrSet2", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsFrrSet2(int frrStart,
            byte r, byte g, byte b, byte br, byte bg, byte bb,
            byte ptnCnt, uint ptn, int hz);

        /// <summary>
        /// APS SFR Set.
        /// <para>Delphi: AF9API_APSSFRSet -> DLL 'APSSFRSet'</para>
        /// </summary>
        [DllImport(DllName, EntryPoint = "APSSFRSet", CallingConvention = CallingConvention.StdCall)]
        public static extern int ApsSfrSet(int frrStart,
            byte r, byte g, byte b, byte br, byte bg, byte bb,
            byte ptnCnt, uint ptn, int hz);
    }
}
