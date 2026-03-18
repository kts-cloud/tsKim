// =============================================================================
// Af9FpgaDriver.cs
// Converted from Delphi: src_X3584\AF9_FPGA.pas (TAF9Fpga class)
// AF9 FPGA pattern generator driver for ITOLED inspection system.
// Namespace: Dongaeltek.ITOLED.Hardware.Fpga
// =============================================================================

using System.Diagnostics;
using System.Runtime.InteropServices;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Fpga;

// =============================================================================
// Record Types (Delphi packed records -> C# structs/records)
// =============================================================================

/// <summary>
/// Received data from PG.
/// <para>Delphi: <c>TRxDataPg</c></para>
/// </summary>
public class RxDataPg
{
    /// <summary>Delphi: NgOrYes : Integer</summary>
    public int NgOrYes { get; set; }

    /// <summary>Delphi: DataLen : Word</summary>
    public ushort DataLen { get; set; }

    /// <summary>Delphi: Data : array [0..8191] of Byte</summary>
    public byte[] Data { get; } = new byte[8192];
}

/// <summary>
/// PG power value record.
/// <para>Delphi: <c>RPwrValPg</c></para>
/// </summary>
public struct PwrValPg
{
    /// <summary>VCC voltage (mV)</summary>
    public int Vcc;

    /// <summary>VEL voltage (mV)</summary>
    public int Vel;

    /// <summary>ICC current (mA)</summary>
    public int Icc;

    /// <summary>IEL current (mA)</summary>
    public int Iel;
}

/// <summary>
/// GUI message data from AF9 to Main window.
/// <para>Delphi: <c>RGuiAF92Main</c> packed record</para>
/// </summary>
public sealed record GuiAf9ToMain(
    int MsgType,
    int PgNo,
    int Mode,
    int Param,
    string Message);

/// <summary>
/// GUI message data from AF9 to Test window.
/// <para>Delphi: <c>RGuiAF92Test</c> packed record</para>
/// </summary>
public sealed record GuiAf9ToTest(
    int MsgType,
    int PgNo,
    int Mode,
    int Param,
    string Message,
    PwrValPg PwrValPg);

/// <summary>
/// GUI BMP download progress data.
/// <para>Delphi: <c>TGuiPgDownData</c> packed record</para>
/// </summary>
public sealed record GuiPgDownData(
    int MsgType,
    int PgNo,
    int Mode,
    int Total,
    int CurPos,
    int Param,
    bool IsDone,
    string Message);

/// <summary>
/// Current pattern display status.
/// <para>Delphi: <c>RPatDispStatus</c></para>
/// </summary>
public class PatternDisplayStatus
{
    /// <summary>Delphi: bPowerOn</summary>
    public bool PowerOn { get; set; }

    /// <summary>Delphi: bPatternOn</summary>
    public bool PatternOn { get; set; }

    /// <summary>Delphi: nCurrPatNum</summary>
    public int CurrentPatternNumber { get; set; }

    /// <summary>Delphi: nCurrAllPatIdx (index of AllPat)</summary>
    public int CurrentAllPatIndex { get; set; }

    /// <summary>Delphi: bSimplePat</summary>
    public bool SimplePattern { get; set; }

    /// <summary>Delphi: nGrayOffset (Gray Change Offset, -255..255)</summary>
    public int GrayOffset { get; set; }

    /// <summary>Delphi: bGrayChangeR</summary>
    public bool GrayChangeR { get; set; }

    /// <summary>Delphi: bGrayChangeG</summary>
    public bool GrayChangeG { get; set; }

    /// <summary>Delphi: bGrayChangeB</summary>
    public bool GrayChangeB { get; set; }

    /// <summary>Delphi: nCurrPwmDuty (0..100)</summary>
    public int CurrentPwmDuty { get; set; }

    /// <summary>Delphi: nCurrDimmingStep (1..4)</summary>
    public int CurrentDimmingStep { get; set; }
}

/// <summary>
/// BMP file transfer structure.
/// <para>Delphi: <c>TFileTranStr</c></para>
/// </summary>
public class FileTranStr
{
    /// <summary>Delphi: TransMode : Integer</summary>
    public int TransMode { get; set; }

    /// <summary>Delphi: TransType : Integer</summary>
    public int TransType { get; set; }

    /// <summary>Delphi: TransSigId : Word</summary>
    public ushort TransSigId { get; set; }

    /// <summary>Delphi: TotalSize : Integer</summary>
    public int TotalSize { get; set; }

    /// <summary>Delphi: fileName : string[80]</summary>
    public string FileName { get; set; } = string.Empty;

    /// <summary>Delphi: filePath : string[200]</summary>
    public string FilePath { get; set; } = string.Empty;

    /// <summary>Delphi: CheckSum : DWORD</summary>
    public uint CheckSum { get; set; }

    /// <summary>Delphi: BmpWidth : DWORD</summary>
    public uint BmpWidth { get; set; }

    /// <summary>Delphi: Data : array of Byte</summary>
    public byte[] Data { get; set; } = Array.Empty<byte>();
}

/// <summary>
/// PG power data record (raw hardware values).
/// <para>Delphi: <c>TPwrDataPg</c></para>
/// </summary>
[StructLayout(LayoutKind.Sequential, Pack = 1)]
public struct PwrDataPg
{
    /// <summary>VCC in mV</summary>
    public ushort Vcc;

    /// <summary>VDD/VEL (ELVDD) in mV</summary>
    public ushort VddVel;

    /// <summary>VBRa in mV</summary>
    public ushort Vbr;

    /// <summary>ICC in mA</summary>
    public ushort Icc;

    /// <summary>IDD/IEL (ELIDD) in mA</summary>
    public ushort IddIel;

    /// <summary>VddXXX byte</summary>
    public byte VddXxx;

    public byte Dummy1;
    public byte Dummy2;
    public byte Dummy3;
    public byte Dummy4;

    /// <summary>0xFF means All OK</summary>
    public byte Ng;
}

/// <summary>
/// Flash data buffer.
/// <para>Delphi: <c>TFlashData</c></para>
/// </summary>
public class FlashData
{
    /// <summary>Delphi: StartAddr : DWORD</summary>
    public uint StartAddr { get; set; }

    /// <summary>Delphi: Size : DWORD</summary>
    public uint Size { get; set; }

    /// <summary>Delphi: Data : array[0..(MAX_FLASHSIZE_BYTE-1)] of Byte</summary>
    public byte[] Data { get; } = new byte[DefAf9Constants.MaxFlashSizeByte];

    /// <summary>Delphi: Checksum : UInt32</summary>
    public uint Checksum { get; set; }

    /// <summary>Delphi: bValid : Boolean</summary>
    public bool Valid { get; set; }
}

/// <summary>
/// Flash read type enumeration.
/// <para>Delphi: <c>TFlashReadType</c></para>
/// </summary>
public enum FlashReadType
{
    /// <summary>Delphi: flashReadNone = 0</summary>
    None = 0,

    /// <summary>Delphi: flashReadUnit = 1</summary>
    Unit = 1,

    /// <summary>Delphi: flashReadGamma = 2 (= flashReadAll)</summary>
    Gamma = 2,

    /// <summary>Delphi: flashReadAll = 2</summary>
    All = 2,
}

/// <summary>
/// Flash read data.
/// <para>Delphi: <c>TFlashRead</c></para>
/// </summary>
public class FlashRead
{
    public FlashReadType ReadType { get; set; }
    public int ReadSize { get; set; }
    public int RxSize { get; set; }
    public byte[] RxData { get; } = new byte[DefAf9Constants.MaxFlashSizeByte];
    public uint ChecksumRx { get; set; }
    public uint ChecksumCalc { get; set; }
    public bool ReadDone { get; set; }
    public string SaveFilePath { get; set; } = string.Empty;
    public string SaveFileName { get; set; } = string.Empty;
}

// =============================================================================
// Constants
// =============================================================================

/// <summary>
/// Internal message mode constants for AF9 FPGA communication.
/// </summary>
internal static class Af9FpgaMsgMode
{
    /// <summary>Delphi: MSG_MODE_WORKING = 31</summary>
    public const int Working = MsgMode.Working;

    /// <summary>Delphi: MSG_MODE_DISPLAY_CONNECTION = 36</summary>
    public const int DisplayConnection = MsgMode.DisplayConnection;

    /// <summary>Delphi: MSG_MODE_DISPLAY_PATTERN</summary>
    public const int DisplayPattern = MsgMode.PatDisplay;
}

/// <summary>
/// DBV register addresses for dimming control.
/// </summary>
internal static class DbvRegisters
{
    /// <summary>DBV register address 1 (high byte). Delphi: DBV_REG_ADDR1 = 751</summary>
    public const int Addr1 = 751;

    /// <summary>DBV register address 2 (low byte). Delphi: DBV_REG_ADDR2 = 752</summary>
    public const int Addr2 = 752;
}

// =============================================================================
// Interface
// =============================================================================

/// <summary>
/// Abstraction over the AF9 FPGA pattern generator hardware.
/// Mirrors the public surface of Delphi's <c>TAF9Fpga</c>.
/// <para>
/// WM_COPYDATA inter-form messaging is replaced with <see cref="IMessageBus"/>
/// publishing <see cref="Af9FpgaEventMessage"/> instances.
/// </para>
/// </summary>
public interface IAf9FpgaDriver : IDisposable
{
    /// <summary>Channel index (0-based). Delphi: m_nCh</summary>
    int ChannelIndex { get; }

    /// <summary>AF9 channel type. Delphi: m_nAF9Ch</summary>
    Af9ChannelType Af9Channel { get; }

    /// <summary>PG connection status. Delphi: m_PgConnSt</summary>
    Af9PgConnectionStatus ConnectionStatus { get; }

    /// <summary>FPGA firmware version. Delphi: m_nAF9VerFpga</summary>
    int FpgaVersion { get; }

    /// <summary>DLL version. Delphi: m_nAF9VerDll</summary>
    int DllVersion { get; }

    /// <summary>PG firmware version string. Delphi: m_sFwVerPg (Format: FPGA%03d_DLL%03d)</summary>
    string FirmwareVersionString { get; }

    /// <summary>Whether power is currently on. Delphi: m_bPowerOn</summary>
    bool IsPowerOn { get; }

    /// <summary>Whether cyclic timer is enabled. Delphi: m_bCyclicTimer</summary>
    bool IsCyclicTimerEnabled { get; }

    /// <summary>Whether power measurement is active. Delphi: m_bPwrMeasure</summary>
    bool IsPowerMeasureActive { get; }

    /// <summary>PG power values. Delphi: m_PwrValPg</summary>
    PwrValPg PowerValuePg { get; }

    /// <summary>AF9 power values. Delphi: m_PwrValAF9</summary>
    Af9PwrVal PowerValueAf9 { get; }

    /// <summary>Received data from PG. Delphi: FRxDataPg</summary>
    RxDataPg RxData { get; }

    /// <summary>
    /// Whether the PG is ready (connected).
    /// Delphi: <c>TAF9Fpga.IsPgReady</c>
    /// </summary>
    bool IsPgReady { get; }

    /// <summary>Maintenance mode flag. Delphi: FIsMainter</summary>
    bool IsMainter { get; set; }

    // ----- AF9 API Methods -----

    /// <summary>Start USB connection. Delphi: AF9_Start_Connection</summary>
    int Af9StartConnection();

    /// <summary>Stop USB connection. Delphi: AF9_Stop_Connection</summary>
    int Af9StopConnection();

    /// <summary>Check connection status. Delphi: AF9_Connection_Status</summary>
    int Af9ConnectionStatus();

    /// <summary>Read FPGA IP version. Delphi: AF9_SW_Revision</summary>
    int Af9SwRevision();

    /// <summary>Read DLL version. Delphi: AF9_DLL_Revision</summary>
    int Af9DllRevision();

    /// <summary>Set DAC voltage. Delphi: AF9_DAC_SET</summary>
    bool Af9DacSet(int nType, int channel, int voltage, int option);

    /// <summary>Set extended I/O. Delphi: AF9_ExtendIO_Set</summary>
    bool Af9ExtendIoSet(int address, int channel, int enable);

    /// <summary>Turn all power on/off. Delphi: AF9_AllPowerOnOff</summary>
    int Af9AllPowerOnOff(int onOff);

    /// <summary>Set APS pattern RGB. Delphi: AF9_APSPatternRGBSet</summary>
    int Af9ApsPatternRgbSet(int r, int g, int b);

    /// <summary>Set APS box pattern. Delphi: AF9_APSBoxPatternSet</summary>
    int Af9ApsBoxPatternSet(int xOffset, int yOffset, int width, int height,
        int r, int g, int b, int br, int bg, int bb);

    /// <summary>Set LGD register (single). Delphi: AF9_LGDSetReg</summary>
    int Af9LgdSetReg(uint addr, byte data);

    /// <summary>Set LGD registers (batch). Delphi: AF9_LGDSetRegM</summary>
    int Af9LgdSetRegM(Af9LgdCommand[] lgdCommand, int commandCnt);

    /// <summary>Get LGD register. Delphi: AF9_LGDGetReg</summary>
    byte Af9LgdGetReg(uint addr);

    /// <summary>Get LGD registers (range). Delphi: AF9_LGDRangeGetReg</summary>
    byte Af9LgdRangeGetReg(byte[] buffer, uint startAddr, uint endAddr);

    /// <summary>Set APS register. Delphi: AF9_APSSetReg</summary>
    int Af9ApsSetReg(int addr, int data);

    /// <summary>Send hex file CRC. Delphi: AF9_SendHexFileCRC</summary>
    int Af9SendHexFileCrc(ushort crc);

    /// <summary>Send hex file. Delphi: AF9_SendHexFile</summary>
    int Af9SendHexFile(byte[] buffer, int len);

    /// <summary>Send hex file for OC. Delphi: AF9_SendHexFileOC</summary>
    int Af9SendHexFileOc(byte[] buffer, int len);

    /// <summary>Write BMP file (send + view). Delphi: AF9_WriteBMPFile</summary>
    int Af9WriteBmpFile(byte[] buffer, int len);

    /// <summary>Send BMP file to numbered slot. Delphi: AF9_BMPFileSend</summary>
    int Af9BmpFileSend(byte[] buffer, int len, int num);

    /// <summary>View stored BMP by number. Delphi: AF9_BMPFileView</summary>
    int Af9BmpFileView(int num);

    /// <summary>Read from SPI flash. Delphi: AF9_FLASHRead</summary>
    byte Af9FlashRead(byte[] buffer, uint startAddr, uint endAddr);

    /// <summary>FRR set. Delphi: AF9_FrrSet</summary>
    int Af9FrrSet(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptn1, byte ptn2, byte ptn3, byte ptn4, byte ptn5, byte ptn6, int hz);

    /// <summary>Initialize AF9 API. Delphi: AF9_InitAF9API</summary>
    bool Af9InitApi();

    /// <summary>Free AF9 API resources. Delphi: AF9_FreeAF9API</summary>
    bool Af9FreeApi();

    /// <summary>Validate USB handler. Delphi: AF9_IsVaildUSBHandler</summary>
    bool Af9IsValidUsbHandler();

    /// <summary>Set display resolution. Delphi: AF9_SetResolution</summary>
    int Af9SetResolution(int resHRes, int resHBp, int resHSa, int resHFp,
        int resVRes, int resVBp, int resVSa, int resVFp);

    /// <summary>Set frequency change. Delphi: AF9_SetFreqChange</summary>
    int Af9SetFreqChange(byte[] buffer, int len, int hzCnt, int nRepeat);

    /// <summary>APS FRR set. Delphi: AF9_APSFrrSet</summary>
    int Af9ApsFrrSet(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptnCnt, uint ptn);

    /// <summary>APS FRR set 2 (with Hz). Delphi: AF9_APSFrrSet2</summary>
    int Af9ApsFrrSet2(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptnCnt, uint ptn, int hz);

    /// <summary>APS SFR set. Delphi: AF9_APSSFRSet</summary>
    int Af9ApsSfrSet(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptnCnt, uint ptn, int hz);

    // ----- PG-level methods -----

    /// <summary>Send power on/off command. Delphi: SendPowerOn</summary>
    uint SendPowerOn(int mode, int waitMs = 10000, int tryCnt = 1);

    /// <summary>Send I2C read. Delphi: SendI2CRead</summary>
    uint SendI2CRead(int devAddr, int regAddr, int dataCnt, int waitMs = 2000, int tryCnt = 1);

    /// <summary>Send I2C write. Delphi: SendI2CWrite</summary>
    uint SendI2CWrite(int devAddr, int regAddr, int dataCnt, int[] data, int waitMs = 2000, int tryCnt = 1);

    /// <summary>Send dimming. Delphi: SendDimming</summary>
    uint SendDimming(int dimming, int tryCnt = 1);

    /// <summary>Send display pattern. Delphi: SendDisplayPat</summary>
    uint SendDisplayPat(int idx, int waitMs = 3000, int tryCnt = 1);

    /// <summary>Send display PWM pattern. Delphi: SendDisplayPwmPat</summary>
    uint SendDisplayPwmPat(int idx, int waitMs = 3000, int tryCnt = 1);

    /// <summary>Set color RGB. Delphi: SendSetColorRGB</summary>
    int SendSetColorRgb(int r, int g, int b);

    /// <summary>Display on/off. Delphi: SendDisplayOnOff</summary>
    uint SendDisplayOnOff(bool on);

    /// <summary>Get cached flash data. Delphi: GetFlashData</summary>
    uint GetFlashData(uint addr, uint len, byte[] buffer);

    /// <summary>Update cached flash data. Delphi: UpdateFlashData</summary>
    uint UpdateFlashData(uint addr, uint len, byte[] buffer);

    /// <summary>Write flash data. Delphi: SendFlashWrite</summary>
    uint SendFlashWrite(uint addr, uint size, byte[] data, int waitMs = 100000, int retry = 0);

    /// <summary>Send BMP data. Delphi: SendBmpData</summary>
    void SendBmpData(int transDataCnt, FileTranStr[] transData);

    /// <summary>Send model info. Delphi: SendModelInfo</summary>
    uint SendModelInfo();

    /// <summary>Download a single BMP file. Delphi: PgDownBmpFile</summary>
    bool PgDownBmpFile(FileTranStr transData, bool selfTestForceNg = false);

    /// <summary>Download multiple BMP files. Delphi: PgDownBmpFiles</summary>
    bool PgDownBmpFiles(int fileCnt, FileTranStr[] transData);

    /// <summary>Send power measurement command. Delphi: SendPowerMeasure</summary>
    uint SendPowerMeasure();

    /// <summary>Check power limits. Delphi: CheckPowerLimit</summary>
    bool CheckPowerLimit(Af9PwrVal pwrVal);

    /// <summary>Enable/disable cyclic timer. Delphi: SetCyclicTimer</summary>
    void SetCyclicTimer(bool enable, int disableSec = 0);

    /// <summary>Enable/disable power measure timer. Delphi: SetPowerMeasureTimer</summary>
    void SetPowerMeasureTimer(bool enable, int intervalMs = 1000);

    /// <summary>Maintenance TX event. Delphi: OnTxMaintEvent</summary>
    event Action<int, string>? TxMaintEvent;

    /// <summary>Maintenance RX event. Delphi: OnRxMaintEvent</summary>
    event Action<int, string>? RxMaintEvent;
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// AF9 FPGA pattern generator driver.
/// Replaces Delphi's <c>TAF9Fpga</c> class.
/// <para>
/// WM_COPYDATA inter-form messaging is replaced with <see cref="IMessageBus"/>
/// publishing <see cref="Af9FpgaEventMessage"/> instances.
/// </para>
/// </summary>
public sealed class Af9FpgaDriver : IAf9FpgaDriver
{
    // =====================================================================
    // Win32 constants used as return values
    // =====================================================================
    private const uint WAIT_OBJECT_0 = 0x00000000;
    private const uint WAIT_FAILED = 0xFFFFFFFF;

    // =====================================================================
    // Fields
    // =====================================================================

    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;
    private readonly AppConfiguration _config;
    private readonly object _lock = new();

    private Timer? _connCheckTimer;
    private Timer? _pwrMeasureTimer;

    private int _connCheckNgCount;
    private string _af9ApiType;
    private bool _disposed;

    // =====================================================================
    // Properties
    // =====================================================================

    /// <inheritdoc />
    public int ChannelIndex { get; }

    /// <inheritdoc />
    public Af9ChannelType Af9Channel { get; }

    /// <inheritdoc />
    public Af9PgConnectionStatus ConnectionStatus { get; private set; } = Af9PgConnectionStatus.Disconnected;

    /// <inheritdoc />
    public int FpgaVersion { get; private set; }

    /// <inheritdoc />
    public int DllVersion { get; private set; }

    /// <inheritdoc />
    public string FirmwareVersionString => $"FPGA{FpgaVersion:D3}_DLL{DllVersion:D3}";

    /// <inheritdoc />
    public bool IsPowerOn { get; private set; }

    /// <inheritdoc />
    public bool IsCyclicTimerEnabled { get; private set; }

    /// <inheritdoc />
    public bool IsPowerMeasureActive { get; private set; }

    /// <inheritdoc />
    public PwrValPg PowerValuePg { get; private set; }

    /// <inheritdoc />
    public Af9PwrVal PowerValueAf9 { get; private set; }

    /// <inheritdoc />
    public RxDataPg RxData { get; } = new();

    /// <inheritdoc />
    public bool IsPgReady => ConnectionStatus == Af9PgConnectionStatus.Connected;

    /// <inheritdoc />
    public bool IsMainter { get; set; }

    /// <summary>Previous pattern number. Delphi: m_nPatNumPrev</summary>
    public int PatternNumberPrev { get; private set; }

    /// <summary>Current pattern number. Delphi: m_nPatNumNow</summary>
    public int PatternNumberNow { get; private set; }

    /// <summary>Flash data cache. Delphi: m_FlashData</summary>
    public FlashData FlashDataCache { get; } = new();

    /// <inheritdoc />
    public event Action<int, string>? TxMaintEvent;

    /// <inheritdoc />
    public event Action<int, string>? RxMaintEvent;

    // =====================================================================
    // Constructor
    // =====================================================================

    /// <summary>
    /// Creates a new AF9 FPGA driver instance.
    /// <para>Delphi: <c>TAF9Fpga.Create(hMain, hTest: THandle; nCh: Integer)</c></para>
    /// </summary>
    /// <param name="channelIndex">Channel index (0-based). Delphi: nCh</param>
    /// <param name="messageBus">Message bus for inter-component communication.</param>
    /// <param name="logger">Logger instance.</param>
    /// <param name="config">Application configuration.</param>
    public Af9FpgaDriver(
        int channelIndex,
        IMessageBus messageBus,
        ILogger logger,
        AppConfiguration config)
    {
        ChannelIndex = channelIndex;
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _config = config ?? throw new ArgumentNullException(nameof(config));

        // Delphi: if m_nCh = 0 then m_nAF9Ch := AF9CH_1 else m_nAF9Ch := AF9CH_2
        Af9Channel = channelIndex == 0 ? Af9ChannelType.Ch1 : Af9ChannelType.Ch2;

        // ---- AF9-Specific initialization ----
        ConnectionStatus = Af9PgConnectionStatus.Disconnected;
        FpgaVersion = 0;
        DllVersion = 0;

        // ---- Timers ----
        IsCyclicTimerEnabled = false;
        _connCheckNgCount = 0;

        // ConnCheckTimer: Delphi TTimer -> System.Threading.Timer
        _connCheckTimer = new Timer(ConnCheckTimerCallback, null, Timeout.Infinite, Timeout.Infinite);

        // PwrMeasureTimer: Delphi TTimer -> System.Threading.Timer
        IsPowerMeasureActive = false;
        _pwrMeasureTimer = new Timer(PwrMeasureTimerCallback, null, Timeout.Infinite, Timeout.Infinite);

        // ---- Other state ----
        IsPowerOn = false;
        PatternNumberPrev = 0;
        PatternNumberNow = 0;
        IsMainter = false;

        // Delphi: {$IFDEF SIMULATOR_PG} m_sAF9APIType := '<AF9_SIM> '; {$ELSE} '<AF9_API> '
        _af9ApiType = _config.Simulator.HasFlag(SimulatorFlags.Pg)
            ? "<AF9_SIM> "
            : "<AF9_API> ";
    }

    // =====================================================================
    // IDisposable
    // =====================================================================

    /// <summary>
    /// Dispose and release all resources.
    /// <para>Delphi: <c>TAF9Fpga.Destroy</c></para>
    /// </summary>
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        try
        {
            Af9StopConnection();
        }
        catch (Exception ex)
        {
            _logger.Error(ChannelIndex, "Error during AF9 stop connection on dispose", ex);
        }

        // Stop and dispose timers
        if (_connCheckTimer != null)
        {
            _connCheckTimer.Change(Timeout.Infinite, Timeout.Infinite);
            _connCheckTimer.Dispose();
            _connCheckTimer = null;
        }

        if (_pwrMeasureTimer != null)
        {
            _pwrMeasureTimer.Change(Timeout.Infinite, Timeout.Infinite);
            _pwrMeasureTimer.Dispose();
            _pwrMeasureTimer = null;
        }
    }

    // #####################################################################
    //
    // AF9_API Methods (1CH and MULTI)
    //
    // #####################################################################

    /// <inheritdoc />
    public int Af9StartConnection()
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? "MULTI_Start_Connection"
            : "Start_Connection";
        sApiFunc = _af9ApiType + sApiFunc;

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.StartConnOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiStartConnection();
        }
        else
        {
            result = Af9Api.StartConnection();
        }

        sApiFunc = _af9ApiType + sApiFunc + $":({result}) ";
        sApiFunc += result switch
        {
            1 => "OK",
            0 => "NG(USB Device Not Found)",
            -1 => "NG(USB Library Open Fail)",
            _ => "NG(Unknown Result)",
        };

        PublishTestWindow(Af9FpgaMsgMode.Working, result == DefAf9Constants.ResultOk ? 0 : 1, sApiFunc);
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        // Delphi: Result := AF9API_STARTCONN_OK; //2022-03-24
        result = DefAf9Constants.StartConnOk;
        return result;
    }

    /// <inheritdoc />
    public int Af9StopConnection()
    {
        var sApiFunc = "Stop_Connection";
        sApiFunc = _af9ApiType + sApiFunc;

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else
        {
            result = Af9Api.StopConnection();
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        PublishTestWindow(Af9FpgaMsgMode.Working, result == DefAf9Constants.ResultOk ? 0 : 1, sApiFunc);
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9ConnectionStatus()
    {
        var sApiFunc = "Connection_Status";
        sApiFunc = _af9ApiType + sApiFunc;

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiConnectionStatus((int)Af9Channel);
        }
        else
        {
            result = Af9Api.ConnectionStatus();
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        PublishTestWindow(Af9FpgaMsgMode.Working, result == DefAf9Constants.ResultOk ? 0 : 1, sApiFunc);
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9SwRevision()
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_SW_Revision[CH{(int)Af9Channel}]"
            : "SW_Revision";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = 123;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiSwRevision((int)Af9Channel);
        }
        else
        {
            result = Af9Api.SwRevision();
        }

        sApiFunc = _af9ApiType + sApiFunc + $":({result}) ";
        PublishTestWindow(Af9FpgaMsgMode.Working, 0, sApiFunc);
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9DllRevision()
    {
        var sApiFunc = "DLL_Revision";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = 456;
        }
        else
        {
            result = Af9Api.DllRevision();
        }

        sApiFunc = _af9ApiType + sApiFunc + $":({result}) ";
        PublishTestWindow(Af9FpgaMsgMode.Working, 0, sApiFunc);
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public bool Af9DacSet(int nType, int channel, int voltage, int option)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_DAC_SET[CH{(int)Af9Channel}]"
            : "DAC_SET";
        sApiFunc = _af9ApiType + sApiFunc + $"(type={nType},channel={channel},voltage={voltage},option={option})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        bool result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = true;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiDacSet(nType, channel, voltage, option, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.DacSet(nType, channel, voltage, option);
        }

        sApiFunc += result ? "OK" : "NG";
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public bool Af9ExtendIoSet(int address, int channel, int enable)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_ExtendIO_Set[CH{(int)Af9Channel}]"
            : "ExtendIO_Set";
        sApiFunc = _af9ApiType + sApiFunc + $"(addr={address},channel={channel},enable={enable})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        bool result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = true;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiExtendIoSet(address, channel, enable, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.ExtendIoSet(address, channel, enable);
        }

        sApiFunc += $":({result}) " + (result ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9AllPowerOnOff(int onOff)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_AllPowerOnOff[CH{(int)Af9Channel}]"
            : "AllPowerOnOff";
        sApiFunc = _af9ApiType + sApiFunc + $"(OnOff={onOff})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiAllPowerOnOff(onOff, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.AllPowerOnOff(onOff);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9ApsPatternRgbSet(int r, int g, int b)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_APSPatternRGBSet[CH{(int)Af9Channel}]"
            : "APSPatternRGBSet";
        sApiFunc = _af9ApiType + sApiFunc + $"(R={r},G={g},B={b})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiApsPatternRgbSet(r, g, b, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.ApsPatternRgbSet(r, g, b);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9ApsBoxPatternSet(int xOffset, int yOffset, int width, int height,
        int r, int g, int b, int br, int bg, int bb)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_APSBoxPatternSet[CH{(int)Af9Channel}]"
            : "APSBoxPatternSet";
        sApiFunc = _af9ApiType + sApiFunc +
            $"(X={xOffset},Y={yOffset}, W={width},H={height}, R={r}G={g}B={b}, BR={br},BG={bg},BB={bb})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiApsBoxPatternSet(xOffset, yOffset, width, height, r, g, b, br, bg, bb, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.ApsBoxPatternSet(xOffset, yOffset, width, height, r, g, b, br, bg, bb);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9LgdSetReg(uint addr, byte data)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_LGDSetReg[CH{(int)Af9Channel}]"
            : "LGDSetReg";
        sApiFunc = _af9ApiType + sApiFunc + $"(addr={addr},data=0x{data:X2})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiLgdSetReg(addr, data, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.LgdSetReg(addr, data);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9LgdSetRegM(Af9LgdCommand[] lgdCommand, int commandCnt)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_LGDSetRegM[CH{(int)Af9Channel}]"
            : "LGDSetRegM";
        sApiFunc = _af9ApiType + sApiFunc + $"(CmdCnt={commandCnt})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiLgdSetRegM(lgdCommand, commandCnt, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.LgdSetRegM(lgdCommand, commandCnt);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public byte Af9LgdGetReg(uint addr)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_LGDGetReg[CH{(int)Af9Channel}]"
            : "LGDGetReg";
        sApiFunc = _af9ApiType + sApiFunc + $"(addr={addr})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        byte result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = 0; // Simulator returns 0
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiLgdGetReg(addr, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.LgdGetReg(addr);
        }

        sApiFunc += $":(0x{result:X2})";
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public byte Af9LgdRangeGetReg(byte[] buffer, uint startAddr, uint endAddr)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_LGDRangeGetReg[CH{(int)Af9Channel}]"
            : "LGDRangeGetReg";
        sApiFunc = _af9ApiType + sApiFunc + $"(start={startAddr},end={endAddr})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        byte result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = 1; // Simulator returns success
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiLgdRangeGetReg(buffer, startAddr, endAddr, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.LgdRangeGetReg(buffer, startAddr, endAddr);
        }

        // Build debug string with read data
        var count = (int)(endAddr - startAddr + 1);
        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        sApiFunc += "(";
        for (var i = 0; i < count && i < buffer.Length; i++)
        {
            sApiFunc += $"0x{buffer[i]:X2} ";
        }
        sApiFunc += ")";
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9ApsSetReg(int addr, int data)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_APSSetReg[CH{(int)Af9Channel}]"
            : "APSSetReg";
        sApiFunc = _af9ApiType + sApiFunc + $"(addr={addr},data=0x{data:X2})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiApsSetReg(addr, data, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.ApsSetReg(addr, data);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        PublishTestWindow(Af9FpgaMsgMode.Working, result == DefAf9Constants.ResultOk ? 0 : 1, sApiFunc);
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9SendHexFileCrc(ushort crc)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_SendHexFileCRC[CH{(int)Af9Channel}]"
            : "SendHexFileCRC";
        sApiFunc = _af9ApiType + sApiFunc + $"(CRC=0x{crc:X})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiSendHexFileCrc(crc, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.SendHexFileCrc(crc);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9SendHexFileOc(byte[] buffer, int len)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_SendHexFileOC[CH{(int)Af9Channel}]"
            : "SendHexFileOC";
        sApiFunc = _af9ApiType + sApiFunc + $"(Len={len})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiSendHexFileOc(buffer, len, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.SendHexFileOc(buffer, len);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9SendHexFile(byte[] buffer, int len)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_SendHexFile[CH{(int)Af9Channel}]"
            : "SendHexFile";
        sApiFunc = _af9ApiType + sApiFunc + $"(Len={len})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiSendHexFile(buffer, len, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.SendHexFile(buffer, len);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9WriteBmpFile(byte[] buffer, int len)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_WriteBMPFile[CH{(int)Af9Channel}]"
            : "WriteBMPFile";
        sApiFunc = _af9ApiType + sApiFunc + $"(len={len})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiWriteBmpFile(buffer, len, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.WriteBmpFile(buffer, len);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9BmpFileSend(byte[] buffer, int len, int num)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_BMPFileSend[CH{(int)Af9Channel}]"
            : "BMPFileSend";
        sApiFunc = _af9ApiType + sApiFunc + $"(len={len},num={num})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiBmpFileSend(buffer, len, num, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.BmpFileSend(buffer, len, num);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9BmpFileView(int num)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_BMPFileView[CH{(int)Af9Channel}]"
            : "BMPFileView";
        sApiFunc = _af9ApiType + sApiFunc + $"(num={num})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiBmpFileView(num, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.BmpFileView(num);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        // Delphi: Result := 1; //AF9API_RESULT_OK
        result = DefAf9Constants.ResultOk;
        return result;
    }

    /// <inheritdoc />
    public byte Af9FlashRead(byte[] buffer, uint startAddr, uint endAddr)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_FLASHRead[CH{(int)Af9Channel}]"
            : "FLASHRead";
        sApiFunc = _af9ApiType + sApiFunc + $"(Start={startAddr},End={endAddr})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        byte result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            // In simulator mode, return NG (no physical flash)
            result = (byte)DefAf9Constants.ResultNg;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiFlashRead(buffer, startAddr, endAddr, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.FlashRead(buffer, startAddr, endAddr);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9FrrSet(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptn1, byte ptn2, byte ptn3, byte ptn4, byte ptn5, byte ptn6, int hz)
    {
        var sApiFunc = _config.Af9Api == Af9ApiMode.Multi
            ? $"MULTI_FrrSet[CH{(int)Af9Channel}]"
            : "FrrSet";
        sApiFunc = _af9ApiType + sApiFunc +
            $"(FrrStart={frrStart}, R={r},G={g},B={b}, BR={br},BG={bg},BB={bb}, " +
            $"PTN1={ptn1},PTN2={ptn2},PTN3={ptn3},PTN4={ptn4},PTN5={ptn5},PTN6={ptn6}, Hz={hz})";
        if (IsMainter) TxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else if (_config.Af9Api == Af9ApiMode.Multi)
        {
            result = Af9Api.MultiFrrSet(frrStart, r, g, b, br, bg, bb, ptn1, ptn2, ptn3, ptn4, ptn5, ptn6, hz, (int)Af9Channel);
        }
        else
        {
            result = Af9Api.FrrSet(frrStart, r, g, b, br, bg, bb, ptn1, ptn2, ptn3, ptn4, ptn5, ptn6, hz);
        }

        sApiFunc += $":({result}) " + (result == DefAf9Constants.ResultOk ? "OK" : "NG");
        if (IsMainter) RxMaintEvent?.Invoke(ChannelIndex, sApiFunc);

        return result;
    }

    // ----- Utility / Legacy API -----

    /// <inheritdoc />
    public bool Af9InitApi()
    {
        // Delphi: TBD:AF9:v2.02? AF9API_InitAF9API;
        return true;
    }

    /// <inheritdoc />
    public bool Af9FreeApi()
    {
        // Delphi: TBD:AF9:v2.02? AF9API_FreeAF9API;
        return true;
    }

    /// <inheritdoc />
    public bool Af9IsValidUsbHandler()
    {
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
            return true;

        return Af9Api.IsValidUsbHandler();
    }

    /// <inheritdoc />
    public int Af9SetResolution(int resHRes, int resHBp, int resHSa, int resHFp,
        int resVRes, int resVBp, int resVSa, int resVFp)
    {
        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else
        {
            result = Af9Api.SetResolution(resHRes, resHBp, resHSa, resHFp, resVRes, resVBp, resVSa, resVFp);
        }

        var sApiFunc = _af9ApiType + "SetResolution" +
            $"(H={resHRes},HBP={resHBp},HSA={resHSa},HFP={resHFp}, V={resVRes},VBP={resVBp},VSA={resVSa},VFP={resVFp})";
        _logger.Debug(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9SetFreqChange(byte[] buffer, int len, int hzCnt, int nRepeat)
    {
        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else
        {
            result = Af9Api.SetFreqChange(buffer, len, hzCnt, nRepeat);
        }

        // Delphi note: called twice (second call overwrites) - preserving single call behavior
        var sApiFunc = _af9ApiType + "SetFreqChange" + $"(Len={len},HzCnt={hzCnt},Repeat={nRepeat})";
        _logger.Debug(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9ApsFrrSet(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptnCnt, uint ptn)
    {
        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else
        {
            result = Af9Api.ApsFrrSet(frrStart, r, g, b, br, bg, bb, ptnCnt, ptn);
        }

        var sApiFunc = _af9ApiType + "APSFrrSet" +
            $"(FrrStart={frrStart}, R={r},G={g},B={b}, BR={br},BG={bg},BB={bb}, PtnCnt={ptnCnt},PTN={ptn})";
        _logger.Debug(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9ApsFrrSet2(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptnCnt, uint ptn, int hz)
    {
        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else
        {
            result = Af9Api.ApsFrrSet2(frrStart, r, g, b, br, bg, bb, ptnCnt, ptn, hz);
        }

        var sApiFunc = _af9ApiType + "APSFrrSet2" +
            $"(FrrStart={frrStart}, R={r},G={g},B={b}, BR={br},BG={bg},BB={bb}, PtnCnt={ptnCnt},PTN={ptn}, Hz={hz})";
        _logger.Debug(ChannelIndex, sApiFunc);

        return result;
    }

    /// <inheritdoc />
    public int Af9ApsSfrSet(int frrStart, byte r, byte g, byte b, byte br, byte bg, byte bb,
        byte ptnCnt, uint ptn, int hz)
    {
        int result;
        if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
        {
            result = DefAf9Constants.ResultOk;
        }
        else
        {
            result = Af9Api.ApsSfrSet(frrStart, r, g, b, br, bg, bb, ptnCnt, ptn, hz);
        }

        var sApiFunc = _af9ApiType + "APSSFRSet" +
            $"(FrrStart={frrStart}, R={r},G={g},B={b}, BR={br},BG={bg},BB={bb}, PtnCnt={ptnCnt},PTN={ptn}, Hz={hz})";
        _logger.Debug(ChannelIndex, sApiFunc);

        return result;
    }

    // #####################################################################
    //
    // Timer Callbacks
    //
    // #####################################################################

    /// <summary>
    /// Connection check timer callback.
    /// <para>Delphi: <c>TAF9Fpga.ConnCheckTimer</c></para>
    /// </summary>
    private void ConnCheckTimerCallback(object? state)
    {
        try
        {
            // Start Connection if Disconnected
            if (ConnectionStatus == Af9PgConnectionStatus.Disconnected)
            {
                IsCyclicTimerEnabled = true;
                var nRtnAf9 = Af9StartConnection();
                if (nRtnAf9 == DefAf9Constants.StartConnOk)
                {
                    ConnectionStatus = Af9PgConnectionStatus.Started;
                }
                else
                {
                    return;
                }
            }

            // Exit if timers disabled
            if (!IsCyclicTimerEnabled) return;
            if (IsPowerMeasureActive && _pwrMeasureTimer != null) return;

            // Check Connection Status (direct API call to avoid extra logging)
            int nRtn;
            if (_config.Simulator.HasFlag(SimulatorFlags.Pg))
            {
                nRtn = Af9ConnectionStatus();
            }
            else if (_config.Af9Api == Af9ApiMode.Multi)
            {
                nRtn = Af9Api.MultiConnectionStatus((int)Af9Channel);
            }
            else
            {
                nRtn = Af9Api.ConnectionStatus();
            }

            if (nRtn == DefAf9Constants.ResultOk)
            {
                // Connected
                if (ConnectionStatus == Af9PgConnectionStatus.Started ||
                    FpgaVersion == 0 || DllVersion == 0)
                {
                    FpgaVersion = Af9SwRevision();
                    DllVersion = Af9DllRevision();
                    ConnectionStatus = Af9PgConnectionStatus.Connected;

                    // Change ConnCheck interval
                    _connCheckTimer?.Change(2000, 2000);
                }
                _connCheckNgCount = 0;
            }
            else
            {
                // Disconnected
                _connCheckNgCount++;
                if (ConnectionStatus != Af9PgConnectionStatus.Disconnected && _connCheckNgCount >= 1)
                {
                    ConnectionStatus = Af9PgConnectionStatus.Disconnected;
                    FpgaVersion = 0;
                    DllVersion = 0;

                    // Change ConnCheck interval
                    _connCheckTimer?.Change(1000, 1000);

                    // Disable PwrMeasure timer
                    _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);
                    IsPowerMeasureActive = false;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.Error(ChannelIndex, "ConnCheckTimer exception", ex);
            System.Diagnostics.Debug.WriteLine($">> ConnCheckTimer Exception Error!! {ex.Message}");
        }
    }

    /// <summary>
    /// Power measurement timer callback.
    /// <para>Delphi: <c>TAF9Fpga.PwrMeasureTimer</c></para>
    /// </summary>
    private void PwrMeasureTimerCallback(object? state)
    {
        if (!IsCyclicTimerEnabled) return;
        if (!IsPowerMeasureActive) return;

        try
        {
            // TBD:AF9? - power measurement implementation placeholder
        }
        catch (Exception ex)
        {
            _logger.Error(ChannelIndex, "PwrMeasureTimer exception", ex);
            System.Diagnostics.Debug.WriteLine($">> PwrMeasureTimer Exception Error!! {ex.Message}");
        }
    }

    /// <inheritdoc />
    public void SetCyclicTimer(bool enable, int disableSec = 0)
    {
        if (IsCyclicTimerEnabled == enable) return; // Already in desired state

        IsCyclicTimerEnabled = enable;
        if (enable)
        {
            _connCheckTimer?.Change(2000, 2000);
            if (IsPowerMeasureActive)
                _pwrMeasureTimer?.Change(3000, 3000);
        }
        else
        {
            _connCheckTimer?.Change(Timeout.Infinite, Timeout.Infinite);
            if (IsPowerMeasureActive)
                _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);
        }
        _connCheckNgCount = 0;

        // If disabling with a timeout, re-enable after the specified duration
        if (!enable && disableSec > 0)
        {
            Task.Run(async () =>
            {
                for (var cnt = 1; cnt <= disableSec; cnt++)
                {
                    if (IsCyclicTimerEnabled) return;
                    await Task.Delay(1000);
                }
                // Enable after disableSec expired
                IsCyclicTimerEnabled = true;
                _connCheckTimer?.Change(2000, 2000);
                if (IsPowerMeasureActive)
                    _pwrMeasureTimer?.Change(3000, 3000);
            });
        }
    }

    // #####################################################################
    //
    // PG-level methods (Send*, Get*, Update*, etc.)
    //
    // #####################################################################

    /// <inheritdoc />
    public uint GetFlashData(uint addr, uint len, byte[] buffer)
    {
        if (!FlashDataCache.Valid) return WAIT_FAILED;
        if (addr < FlashDataCache.StartAddr) return WAIT_FAILED;
        if (addr + len > FlashDataCache.StartAddr + FlashDataCache.Size) return WAIT_FAILED;

        Buffer.BlockCopy(FlashDataCache.Data, (int)addr, buffer, 0, (int)len);
        return WAIT_OBJECT_0;
    }

    /// <inheritdoc />
    public uint UpdateFlashData(uint addr, uint len, byte[] buffer)
    {
        if (!FlashDataCache.Valid) return WAIT_FAILED;
        if (addr < FlashDataCache.StartAddr) return WAIT_FAILED;
        if (addr + len > FlashDataCache.StartAddr + FlashDataCache.Size) return WAIT_FAILED;

        Buffer.BlockCopy(buffer, 0, FlashDataCache.Data, (int)addr, (int)len);
        return WAIT_OBJECT_0;
    }

    /// <inheritdoc />
    public bool PgDownBmpFile(FileTranStr transData, bool selfTestForceNg = false)
    {
        // TBD:AF9? - BMP download implementation placeholder
        return false;
    }

    /// <inheritdoc />
    public bool PgDownBmpFiles(int fileCnt, FileTranStr[] transData)
    {
        // TBD:AF9? - BMP multi-download implementation placeholder
        return false;
    }

    /// <inheritdoc />
    public uint SendDisplayPat(int idx, int waitMs = 3000, int tryCnt = 1)
    {
        // TBD: Pattern display - requires pattern info structures
        // Delphi: SendPatDisplayReq(1, nIdx)
        // Placeholder: return success for now
        return WAIT_FAILED;
    }

    /// <inheritdoc />
    public uint SendDisplayPwmPat(int idx, int waitMs = 3000, int tryCnt = 1)
    {
        // This is OC inspector - INSPECTOR_FI/OQA sections are skipped
        // Delphi: SendPatDisplayReq(1, nIdx)
        return WAIT_FAILED;
    }

    /// <inheritdoc />
    public bool CheckPowerLimit(Af9PwrVal pwrVal)
    {
        // TBD:AF9? - power limit checking placeholder
        return false;
    }

    /// <inheritdoc />
    public uint SendDimming(int dimming, int tryCnt = 1)
    {
        uint result = WAIT_OBJECT_0;
        var sFunc = $"DIMMING(PWM={dimming}): ";

        // nDimming(0~100) --> DBV(0~2047)
        // [REF] AF9_TEST_EXE (v1.11) - DBV
        //   writeData = (inputData << 5) | 31;
        //   LGDSetReg(751, (writeData & 0xFF00) >> 8);
        //   LGDSetReg(752, (writeData & 0xFF));
        int dbv;
        if (dimming == 0) dbv = 0;
        else if (dimming == 100) dbv = 2047;
        else dbv = (dimming * 2048) / 100;

        var writeValue = (dbv << 5) | 0x1F;
        var btValue1 = (byte)((writeValue >> 8) & 0xFF); // high
        var btValue2 = (byte)(writeValue & 0xFF);         // low

        var sDebug = sFunc +
            $"DBV({dbv}), Value(0x{writeValue:X4}), Reg({DbvRegisters.Addr1}:0x{btValue1:X2}, {DbvRegisters.Addr2}:0x{btValue2:X2})";
        _logger.Debug(ChannelIndex, sDebug);

        for (var nTry = 1; nTry <= tryCnt; nTry++)
        {
            // DBV_REG_ADDR1 - Write
            var nApiRtn = Af9LgdSetReg((uint)DbvRegisters.Addr1, btValue1);
            if (nApiRtn != DefAf9Constants.ResultOk)
            {
                result = WAIT_FAILED;
                sDebug = sFunc + $"AF9_API: LGDSetReg(Addr={DbvRegisters.Addr1},Value=0x{btValue1:X2}) Failed";
                _logger.Debug(ChannelIndex, sDebug);
                continue;
            }

            // DBV_REG_ADDR1 - Verify
            var btRead = Af9LgdGetReg((uint)DbvRegisters.Addr1);
            if (btRead != btValue1)
            {
                result = WAIT_FAILED;
                sDebug = sFunc + $"AF9_API LGDGetReg(Addr={DbvRegisters.Addr1}): Value(0x{btRead:X2}) <> Write(0x{btValue1:X2})";
                _logger.Debug(ChannelIndex, sDebug);
                continue;
            }

            // DBV_REG_ADDR2 - Write
            nApiRtn = Af9LgdSetReg((uint)DbvRegisters.Addr2, btValue2);
            if (nApiRtn != DefAf9Constants.ResultOk)
            {
                result = WAIT_FAILED;
                sDebug = sFunc + $"AF9_API: LGDSetReg(Addr={DbvRegisters.Addr2},Value=0x{btValue2:X2}) Failed";
                _logger.Debug(ChannelIndex, sDebug);
                continue;
            }

            // DBV_REG_ADDR2 - Verify
            btRead = Af9LgdGetReg((uint)DbvRegisters.Addr2);
            if (btRead != btValue2)
            {
                result = WAIT_FAILED;
                sDebug = sFunc + $"AF9_API: LGDGetReg(Addr={DbvRegisters.Addr2}): Value(0x{btRead:X2}) <> Write(0x{btValue2:X2})";
                _logger.Debug(ChannelIndex, sDebug);
                continue;
            }

            // Both registers verified successfully
            result = WAIT_OBJECT_0;
            break;
        }

        if (result != WAIT_OBJECT_0)
        {
            sDebug = sFunc + "...NG";
            _logger.Warn(ChannelIndex, sDebug);
        }

        return result;
    }

    /// <inheritdoc />
    public uint SendPowerOn(int mode, int waitMs = 10000, int tryCnt = 1)
    {
        uint result = WAIT_OBJECT_0;

        if (mode == 1)
        {
            // Power ON
            Af9AllPowerOnOff(1);
            IsPowerOn = true;
        }
        else
        {
            // Power OFF
            Af9AllPowerOnOff(0);
            IsPowerOn = false;
        }

        return result;
    }

    /// <inheritdoc />
    public uint SendPowerMeasure()
    {
        if (IsPowerMeasureActive)
            _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);

        uint result = WAIT_FAILED;
        // TBD:AF9? - power measurement placeholder

        if (IsPowerMeasureActive)
            _pwrMeasureTimer?.Change(3000, 3000);

        return result;
    }

    /// <inheritdoc />
    public void SetPowerMeasureTimer(bool enable, int intervalMs = 1000)
    {
        IsPowerMeasureActive = enable;
        if (enable && intervalMs > 0)
        {
            _pwrMeasureTimer?.Change(intervalMs, intervalMs);
        }
        else
        {
            _pwrMeasureTimer?.Change(Timeout.Infinite, Timeout.Infinite);
        }
    }

    /// <inheritdoc />
    public uint SendI2CRead(int devAddr, int regAddr, int dataCnt, int waitMs = 2000, int tryCnt = 1)
    {
        uint result = WAIT_FAILED;

        if (devAddr == DefAf9Constants.LgdRegDevice)
        {
            if (dataCnt == 1)
            {
                var btData = Af9LgdGetReg((uint)regAddr);
                RxData.DataLen = 1;
                RxData.Data[0] = btData;
                result = WAIT_OBJECT_0;
            }
            else
            {
                var btaData = new byte[dataCnt];
                Af9LgdRangeGetReg(btaData, (uint)regAddr, (uint)(regAddr + dataCnt - 1));
                RxData.DataLen = (ushort)dataCnt;
                for (var i = 0; i < dataCnt; i++)
                {
                    RxData.Data[i] = btaData[i];
                }
                result = WAIT_OBJECT_0;
            }
        }
        else
        {
            // AF9_API: Not support APS Reg Read (2022-02-25)
            return result;
        }

        return result;
    }

    /// <inheritdoc />
    public uint SendI2CWrite(int devAddr, int regAddr, int dataCnt, int[] data, int waitMs = 2000, int tryCnt = 1)
    {
        uint result = WAIT_FAILED;

        if (devAddr == DefAf9Constants.LgdRegDevice)
        {
            for (var i = 0; i < dataCnt; i++)
            {
                var nApiRtn = Af9LgdSetReg((uint)(regAddr + i), (byte)(data[i] & 0xFF));
                if (nApiRtn != DefAf9Constants.ResultOk) return result;
            }
            result = WAIT_OBJECT_0;
        }
        else
        {
            var nApiRtn = Af9ApsSetReg(regAddr, data[0] & 0xFF);
            if (nApiRtn != DefAf9Constants.ResultOk) return result;
            result = WAIT_OBJECT_0;
        }

        return result;
    }

    /// <inheritdoc />
    public int SendSetColorRgb(int r, int g, int b)
    {
        var nApiRtn = Af9ApsPatternRgbSet(r, g, b);
        if (nApiRtn != DefAf9Constants.ResultOk)
            return unchecked((int)WAIT_FAILED);

        return unchecked((int)WAIT_OBJECT_0);
    }

    /// <inheritdoc />
    public uint SendDisplayOnOff(bool on)
    {
        // TBD:AF9? - display on/off placeholder (this is OC, not POCB)
        return WAIT_OBJECT_0;
    }

    /// <inheritdoc />
    public uint SendFlashWrite(uint addr, uint size, byte[] data, int waitMs = 100000, int retry = 0)
    {
        uint result = WAIT_FAILED;

        // Calc SumCRC
        ushort calcCrc = 0;
        for (var i = 0; i < size; i++)
        {
            calcCrc = (ushort)((calcCrc + data[i]) & 0xFFFF);
        }

        var sFunc = $"SendFlashWrite(Size={size},Retry={retry})(CRC=0x{calcCrc:X})";
        _logger.Debug(ChannelIndex, sFunc);

        // Send CRC + HEX
        for (var nTry = 0; nTry <= retry; nTry++)
        {
            // Send CRC
            var crcRtn = Af9SendHexFileCrc(calcCrc);
            if (crcRtn == DefAf9Constants.ResultOk)
            {
                Thread.Sleep(20); // Required delay per Delphi original
                // Send HEX
                var hexRtn = Af9SendHexFile(data, (int)size);
                if (hexRtn == DefAf9Constants.ResultOk)
                {
                    result = WAIT_OBJECT_0;
                    break;
                }
            }
        }

        if (result != WAIT_OBJECT_0)
        {
            var sDebug = sFunc + "...NG";
            _logger.Warn(ChannelIndex, sDebug);
        }

        return result;
    }

    /// <inheritdoc />
    public void SendBmpData(int transDataCnt, FileTranStr[] transData)
    {
        // TBD:AF9? - BMP data send placeholder
    }

    /// <inheritdoc />
    public uint SendModelInfo()
    {
        // TBD:AF9? - model info send placeholder
        return WAIT_FAILED;
    }

    // #####################################################################
    //
    // GUI Messaging (replaces WM_COPYDATA)
    //
    // #####################################################################

    /// <summary>
    /// Publishes a message to the Main window via the message bus.
    /// <para>Delphi: <c>TAF9Fpga.ShowMainWindow</c> (WM_COPYDATA with RGuiAF92Main)</para>
    /// </summary>
    private void PublishMainWindow(int guiMode, int param, string msg)
    {
        _messageBus.Publish(new Af9FpgaEventMessage
        {
            Channel = ChannelIndex,
            Mode = guiMode,
            Param = param,
            Message = msg,
        });
    }

    /// <summary>
    /// Publishes a message to the Test window via the message bus.
    /// <para>Delphi: <c>TAF9Fpga.ShowTestWindow</c> (WM_COPYDATA with RGuiAF92Test)</para>
    /// </summary>
    private void PublishTestWindow(int guiMode, int param, string msg)
    {
        _messageBus.Publish(new Af9FpgaEventMessage
        {
            Channel = ChannelIndex,
            Mode = guiMode,
            Param = param,
            Message = msg,
        });
    }
}
