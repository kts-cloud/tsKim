// =============================================================================
// CaSdk2Driver.cs
// Converted from Delphi: src\CA_SDK2.pas (TCA_SDK2 class)
// Uses CASDK2Net.dll (Konica Minolta official .NET SDK wrapper)
// Namespace: Dongaeltek.ITOLED.Hardware.Colorimeter
// =============================================================================

using CASDK2;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.Hardware.Colorimeter;

// =============================================================================
// Constants
// =============================================================================

/// <summary>
/// CA-410 SDK constants.
/// Original Delphi: <c>DefCaSdk = class</c> in CA_SDK2.pas
/// </summary>
public static class DefCaSdk
{
    public const int CONNECTION_NONE = 0;
    public const int CONNECTION_OK   = 1;
    public const int CONNECTION_NG   = 2;

    public const int IDX_RED   = 0;
    public const int IDX_GREEN = 1;
    public const int IDX_BLUE  = 2;
    public const int IDX_WHITE = 3;
    public const int IDX_MAX   = 3;

    public const int MAX_CH_CNT = 4;
    public const int MAX_CH     = 4;

    public const int CA310_LvXY  = 0;
    public const int CA310_FLICK = 6;
    public const int CA310_JEITA = 8;

    public const int DISCONNECTION_CODE = 10000;

    /// <summary>
    /// Format string for CA-410 display item.
    /// Original Delphi: <c>CA410_DISPLAY_ITEM = 'COMM(%d)/SerialNo(%s)'</c>
    /// </summary>
    public const string CA410_DISPLAY_ITEM = "COMM({0})/SerialNo({1})";
}

// =============================================================================
// Records (value types)
// =============================================================================

/// <summary>
/// Brightness measurement result (xy + Lv + Flicker).
/// Original Delphi: <c>TBrightValue</c>
/// </summary>
public record struct BrightValue(double X, double Y, double Lv, double Flicker);

/// <summary>
/// Full colorimetric result (xy + u'v' + Lv + delta values).
/// Original Delphi: <c>TLvXYUV</c>
/// </summary>
public record struct LvXyUv(double X, double Y, double U, double V, double Lv, double DUv, double DXy);

/// <summary>
/// Basic colorimetric result (xy + Lv).
/// Original Delphi: <c>TLvXY</c>
/// </summary>
public record struct LvXy(double X, double Y, double Lv);

/// <summary>
/// Connected device information.
/// Original Delphi: <c>TDeviceInfo</c>
/// </summary>
public record DeviceInfo(int DeviceId, string SerialNo, string DllVer);

/// <summary>
/// Per-channel CA-410 setup / assignment information.
/// Original Delphi: <c>TCaSetupInfo</c>
/// </summary>
public sealed class CaSetupInfo
{
    public int SelectIdx { get; set; }
    public int Ca410Ch   { get; set; }
    public int DeviceId  { get; set; }
    public string SerialNo { get; set; } = string.Empty;
}

// =============================================================================
// Interface
// =============================================================================

/// <summary>
/// Abstraction over the CA-410 colorimeter SDK.
/// Mirrors the public surface of Delphi's <c>TCA_SDK2</c>.
/// </summary>
public interface ICaSdk2Driver : IDisposable
{
    /// <summary>Number of detected CA-410 devices after <see cref="ManualConnect"/>.</summary>
    int DeviceCount { get; }

    /// <summary>Per-device info populated after <see cref="ManualConnect"/>.</summary>
    IReadOnlyList<DeviceInfo> Devices { get; }

    /// <summary>Per-channel connection status.</summary>
    bool IsConnected(int channel);

    /// <summary>Per-channel setup configuration.</summary>
    CaSetupInfo GetSetupPort(int index);

    /// <summary>Per-channel setup configuration setter.</summary>
    void SetSetupPort(int index, CaSetupInfo value);

    /// <summary>
    /// Scans USB, enumerates devices, and establishes connections per channel.
    /// Original Delphi: <c>TCA_SDK2.ManualConnect</c>
    /// </summary>
    int ManualConnect();

    /// <summary>
    /// Measures xy + Lv on the specified channel.
    /// Original Delphi: <c>TCA_SDK2.Measure</c>
    /// </summary>
    int Measure(int channel, out BrightValue result);

    /// <summary>
    /// Measures xy + u'v' + Lv (two-step: UV then XY).
    /// Original Delphi: <c>TCA_SDK2.MeasureAllData</c>
    /// </summary>
    int MeasureAllData(int channel, out LvXyUv result);

    /// <summary>
    /// Measures xy + u'v' + Lv + dUv in a single call.
    /// Original Delphi: <c>TCA_SDK2.MeasureData</c>
    /// </summary>
    int MeasureData(int channel, out LvXyUv result);

    /// <summary>Reads the current memory channel from the device.</summary>
    int GetMemCh(int channel, out int memChannel);

    /// <summary>Sets the memory channel on the device.</summary>
    int SetMemCh(int channel, int memChannel);

    /// <summary>Initializes (resets) a memory channel to defaults.</summary>
    int SetDefaultMemCh(int channel, int memChannel);

    /// <summary>Reads stored calibration data for a memory channel (R/G/B/W Lv, x, y).</summary>
    int GetMemInfo(int channel, int memChannel,
        out double rLv, out double rX, out double rY,
        out double gLv, out double gX, out double gY,
        out double bLv, out double bX, out double bY,
        out double wLv, out double wX, out double wY);

    /// <summary>Sets the sync mode for the specified channel.</summary>
    int SetSyncMode(int channel, int syncMode, double frequency, int integrationTime);

    /// <summary>Sets the V-Sync frame count.</summary>
    int SetVsyncFrame(int channel, int frame, out string retMsg);

    /// <summary>Sends a raw command string to the CA-410.</summary>
    int SetCommandCa410(int channel, string command, out string retMsg);

    /// <summary>Prepares the device for user calibration on a target memory channel.</summary>
    int UsrCalReady(int channel, int memChannel);

    /// <summary>Performs a user calibration measurement.</summary>
    int UsrCalMeasure(int channel, int colorType, out double x, out double y, out double lv);

    /// <summary>Sets the Lv/xy calibration target data for a color.</summary>
    int UsrCalSetCalData(int channel, int colorType, double targetX, double targetY, double targetLv);

    /// <summary>Performs zero calibration on the specified channel.</summary>
    int CalZero(int channel);

    /// <summary>Resets the Lv calibration mode.</summary>
    int ResetCalMode(int channel);

    /// <summary>Commits the user calibration matrix (Enter).</summary>
    int CasdkEnter(int channel);

    /// <summary>
    /// Measures and retrieves waveform data.
    /// Returns measurement time in seconds.
    /// </summary>
    double GetWaveformData(int channel, double[] waveformT, double[] waveformData, int measureAmount);

    /// <summary>
    /// Disconnects from all CA-410 devices without disposing the driver.
    /// Call <see cref="ManualConnect"/> afterwards to reconnect.
    /// </summary>
    void Disconnect();
}

// =============================================================================
// Implementation
// =============================================================================

/// <summary>
/// CA-410 colorimeter driver using the CASDK2Net.dll official .NET SDK wrapper.
/// Replaces Delphi's <c>TCA_SDK2</c> class.
/// <para>
/// WM_COPYDATA inter-form messaging is replaced with <see cref="IMessageBus"/>
/// publishing <see cref="Ca410EventMessage"/> instances.
/// </para>
/// </summary>
public sealed class CaSdk2Driver : ICaSdk2Driver
{
    // CASDK2Net display mode constants
    private const int MODE_Lvxy = 0;
    private const int MODE_Waveform2 = 13;

    private readonly IMessageBus _messageBus;
    private readonly int _memChannel;
    private readonly int _autoMode;
    private readonly CaSetupInfo[] _setupList = new CaSetupInfo[DefCaSdk.MAX_CH_CNT];
    private readonly bool[] _connection = new bool[DefCaSdk.MAX_CH_CNT];
    private readonly List<DeviceInfo> _devices = [];
    private bool _disposed;

    // CASDK2Net managed SDK objects
    private CASDK2Ca200? _ca200;
    private readonly List<CASDK2Ca> _allCaDevices = new();
    private readonly CASDK2Ca?[] _caDevices = new CASDK2Ca?[DefCaSdk.MAX_CH_CNT];
    private readonly CASDK2Probe?[] _probes = new CASDK2Probe?[DefCaSdk.MAX_CH_CNT];
    private readonly CASDK2Memory?[] _memories = new CASDK2Memory?[DefCaSdk.MAX_CH_CNT];

    /// <summary>
    /// Creates a new CA-410 driver instance.
    /// Original Delphi: <c>TCA_SDK2.Create(hMain, hTest: HWND; nMemCh: Integer; bAuto: Boolean)</c>
    /// </summary>
    /// <param name="messageBus">Message bus replacing WM_COPYDATA for UI notifications.</param>
    /// <param name="memChannel">Initial memory channel number.</param>
    /// <param name="auto">Whether to use auto integration mode (maps to autoMode=2).</param>
    public CaSdk2Driver(IMessageBus messageBus, int memChannel = 0, bool auto = true)
    {
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _memChannel = memChannel;
        // Original Delphi: both branches set m_nAutoMode := 2
        _autoMode = 2;

        for (var i = 0; i < DefCaSdk.MAX_CH_CNT; i++)
        {
            _connection[i] = false;
            _setupList[i] = new CaSetupInfo();
        }

        // Log SDK version
        var version = "unknown";
        try
        {
            int vA = 0, vB = 0, vC = 0, vD = 0;
            GlobalFunctions.CASDK2_GetVersion(ref vA, ref vB, ref vC, ref vD);
            version = $"{vA}.{vB}.{vC}.{vD}";
        }
        catch { /* SDK DLLs may not be present at compile/test time */ }

        var versionMsg = $"CA SDK Version : {version}";
        for (var i = 0; i < DefCaSdk.MAX_CH; i++)
        {
            PublishTestForm(MsgMode.Working, i, isError: false, versionMsg);
        }
    }

    // =====================================================================
    // Properties
    // =====================================================================

    /// <inheritdoc />
    public int DeviceCount => _devices.Count;

    /// <inheritdoc />
    public IReadOnlyList<DeviceInfo> Devices => _devices;

    /// <inheritdoc />
    public bool IsConnected(int channel) => _connection[channel];

    /// <inheritdoc />
    public CaSetupInfo GetSetupPort(int index) => _setupList[index];

    /// <inheritdoc />
    public void SetSetupPort(int index, CaSetupInfo value) => _setupList[index] = value;

    // =====================================================================
    // ManualConnect
    // =====================================================================

    /// <inheritdoc />
    public int ManualConnect()
    {
        _ca200 = new CASDK2Ca200();
        var err = _ca200.AutoConnect();

        _devices.Clear();
        _allCaDevices.Clear();

        // Get COM port numbers via CASDK2Discovery (same as Delphi CASDK2_DAE.dll GetProbeInfo)
        CASDK2DeviceData[]? usbDevices = null;
        try
        {
            CASDK2Discovery.SearchAllUSBDevices(ref usbDevices);
        }
        catch { /* SDK DLLs may not be present */ }

        CASDK2Cas? cas = null;
        _ca200.get_Cas(ref cas);

        int deviceCount = 0;
        cas?.get_Count(ref deviceCount);

        for (var i = 1; i <= deviceCount; i++)
        {
            CASDK2Ca? ca = null;
            cas!.get_Item(i, ref ca);
            if (ca == null) continue;

            string serialNo = "";
            ca.get_SerialNO(ref serialNo);

            // Match port number from USB discovery by serial number
            // Delphi: pResultArray[i].lPortNo via CASDK2_DAE.dll GetProbeInfo
            int deviceId = i; // fallback to SDK index
            if (usbDevices != null)
            {
                foreach (var dev in usbDevices)
                {
                    if (dev.strSerialNo == serialNo)
                    {
                        deviceId = (int)dev.lPortNo;
                        break;
                    }
                }
            }

            _allCaDevices.Add(ca);
            _devices.Add(new DeviceInfo(deviceId, serialNo ?? string.Empty, "CASDK2Net"));
        }

        // Check connection for each channel
        for (var ch = 0; ch < DefCaSdk.MAX_CH_CNT; ch++)
        {
            CheckConnect(ch);
        }

        return err;
    }

    // =====================================================================
    // Measure
    // =====================================================================

    /// <inheritdoc />
    public int Measure(int channel, out BrightValue result)
    {
        result = default;

        if (!_connection[channel])
        {
            var errMsg = $"Channel {channel + 1} CA410 Connection NG";
            PublishMainForm(MsgMode.Ca310Status, channel, isError: true, errMsg);
            PublishTestForm(MsgMode.Working, channel, isError: true, errMsg);
            return DefCaSdk.DISCONNECTION_CODE;
        }

        var ca = _caDevices[channel];
        var probe = _probes[channel];
        if (ca == null || probe == null)
            return DefCaSdk.DISCONNECTION_CODE;

        ca.put_DisplayMode(MODE_Lvxy);
        var ret = ca.Measure();

        if (ret == 0)
        {
            double dX = 0, dY = 0, dLv = 0;
            var getErr = probe.get_sx(ref dX);
            if (getErr != 0)
            {
                var errMsg = $"Ca410 get_sXylvVal NG - NG Code :{getErr:D2}";
                PublishTestForm(MsgMode.Working, channel, isError: true, errMsg);

                errMsg = $"Channel {channel + 1} CA410 get_sXylvVal NG";
                PublishMainForm(MsgMode.Ca310Status, channel, isError: true, errMsg);
                PublishTestForm(MsgMode.Working, channel, isError: true, errMsg);

                result = new BrightValue(0.0, 0.0, 0.0, 0.0);
                return getErr;
            }

            probe.get_sy(ref dY);
            probe.get_Lv(ref dLv);
            result = new BrightValue(dX, dY, dLv, 0.0);
        }
        else
        {
            var errMsg = $"Ca410 Measure NG - NG Code :{ret:D2}";
            PublishTestForm(MsgMode.Working, channel, isError: true, errMsg);

            errMsg = $"Channel {channel + 1} CA410 Connection NG";
            PublishMainForm(MsgMode.Ca310Status, channel, isError: true, errMsg);
            PublishTestForm(MsgMode.Working, channel, isError: true, errMsg);

            result = new BrightValue(0.0, 0.0, 0.0, 0.0);
        }

        return ret;
    }

    /// <inheritdoc />
    public int MeasureAllData(int channel, out LvXyUv result)
    {
        result = default;

        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        var probe = _probes[channel];
        if (ca == null || probe == null)
            return DefCaSdk.DISCONNECTION_CODE;

        ca.put_DisplayMode(MODE_Lvxy);
        var ret = ca.Measure();

        if (ret == 0)
        {
            double dX = 0, dY = 0, dU = 0, dV = 0, dLv = 0;
            probe.get_ud(ref dU);
            probe.get_vd(ref dV);
            probe.get_Lv(ref dLv);
            probe.get_sx(ref dX);
            probe.get_sy(ref dY);
            result = new LvXyUv(dX, dY, dU, dV, dLv, 0.0, 0.0);
        }
        else
        {
            result = new LvXyUv(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        }

        return ret;
    }

    /// <inheritdoc />
    public int MeasureData(int channel, out LvXyUv result)
    {
        result = default;

        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        var probe = _probes[channel];
        if (ca == null || probe == null)
            return DefCaSdk.DISCONNECTION_CODE;

        ca.put_DisplayMode(MODE_Lvxy);
        var ret = ca.Measure();

        if (ret == 0)
        {
            double dX = 0, dY = 0, dU = 0, dV = 0, dLv = 0;
            probe.get_sx(ref dX);
            probe.get_sy(ref dY);
            probe.get_ud(ref dU);
            probe.get_vd(ref dV);
            probe.get_Lv(ref dLv);
            // dUv (delta-uv from Planckian locus) is not directly available
            // from the official SDK probe getters in Lvxy mode.
            result = new LvXyUv(dX, dY, dU, dV, dLv, 0.0, 0.0);
        }
        else
        {
            result = new LvXyUv(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        }

        return ret;
    }

    // =====================================================================
    // Memory channel
    // =====================================================================

    /// <inheritdoc />
    public int GetMemCh(int channel, out int memChannel)
    {
        memChannel = 0;
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var memory = _memories[channel];
        if (memory == null)
            return DefCaSdk.DISCONNECTION_CODE;

        return memory.get_ChannelNO(ref memChannel);
    }

    /// <inheritdoc />
    public int SetMemCh(int channel, int memChannel)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var memory = _memories[channel];
        if (memory == null)
            return DefCaSdk.DISCONNECTION_CODE;

        memory.put_ChannelNO(memChannel);
        return 0;
    }

    /// <inheritdoc />
    public int SetDefaultMemCh(int channel, int memChannel)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var memory = _memories[channel];
        if (memory == null)
            return DefCaSdk.DISCONNECTION_CODE;

        memory.put_ChannelNO(memChannel);
        return memory.InitMemChannelData(memChannel, 1); // lProbe=1 → P1
    }

    /// <inheritdoc />
    public int GetMemInfo(int channel, int memChannel,
        out double rLv, out double rX, out double rY,
        out double gLv, out double gX, out double gY,
        out double bLv, out double bX, out double bY,
        out double wLv, out double wX, out double wY)
    {
        rLv = rX = rY = 0;
        gLv = gX = gY = 0;
        bLv = bX = bY = 0;
        wLv = wX = wY = 0;

        var memory = _memories[channel];
        if (memory == null)
            return DefCaSdk.DISCONNECTION_CODE;

        memory.put_ChannelNO(memChannel);

        // The official SDK provides composite reference color per probe,
        // not separate R/G/B/W target values like the custom CASDK2_DAE.dll.
        // Return the reference color as the white (W) point.
        double x = 0, y = 0, lv = 0;
        var ret = memory.GetReferenceColor("P1", ref x, ref y, ref lv);
        wLv = lv;
        wX = x;
        wY = y;

        return ret;
    }

    // =====================================================================
    // Sync / Command
    // =====================================================================

    /// <inheritdoc />
    public int SetSyncMode(int channel, int syncMode, double frequency, int integrationTime)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        if (ca == null)
            return DefCaSdk.DISCONNECTION_CODE;

        try
        {
            // integrationTime is not used by the official SDK
            ca.put_SyncMode(syncMode, frequency);
            return 0;
        }
        catch
        {
            return 1;
        }
    }

    /// <inheritdoc />
    public int SetVsyncFrame(int channel, int frame, out string retMsg)
    {
        retMsg = string.Empty;
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        // Not directly supported by the official SDK.
        // The custom CASDK2_DAE.dll provided this; use SetWaveformParams or
        // SetVRRFlickerParams for equivalent functionality if needed.
        return 0;
    }

    /// <inheritdoc />
    public int SetCommandCa410(int channel, string command, out string retMsg)
    {
        retMsg = "Not supported by official SDK";
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        // Raw command passthrough was a custom CASDK2_DAE.dll feature.
        return -1;
    }

    // =====================================================================
    // User calibration
    // =====================================================================

    /// <inheritdoc />
    public int UsrCalReady(int channel, int memChannel)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        var memory = _memories[channel];
        if (ca == null || memory == null)
            return DefCaSdk.DISCONNECTION_CODE;

        memory.put_ChannelNO(memChannel);
        return ca.SetLvxyCalMode();
    }

    /// <inheritdoc />
    public int UsrCalMeasure(int channel, int colorType, out double x, out double y, out double lv)
    {
        x = y = lv = 0.0;
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        var probe = _probes[channel];
        if (ca == null || probe == null)
            return DefCaSdk.DISCONNECTION_CODE;

        var ret = ca.CalibMeasure(colorType);
        if (ret == 0)
        {
            probe.get_sx(ref x);
            probe.get_sy(ref y);
            probe.get_Lv(ref lv);
        }

        return ret;
    }

    /// <inheritdoc />
    public int UsrCalSetCalData(int channel, int colorType, double targetX, double targetY, double targetLv)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        if (ca == null)
            return DefCaSdk.DISCONNECTION_CODE;

        return ca.SetLvxyCalData(colorType, targetX, targetY, targetLv);
    }

    // =====================================================================
    // Calibration
    // =====================================================================

    /// <inheritdoc />
    public int CalZero(int channel)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        if (ca == null)
            return DefCaSdk.DISCONNECTION_CODE;

        return ca.CalZero();
    }

    /// <inheritdoc />
    public int ResetCalMode(int channel)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        if (ca == null)
            return DefCaSdk.DISCONNECTION_CODE;

        return ca.ResetLvxyCalMode();
    }

    /// <inheritdoc />
    public int CasdkEnter(int channel)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        var ca = _caDevices[channel];
        if (ca == null)
            return DefCaSdk.DISCONNECTION_CODE;

        return ca.Enter();
    }

    // =====================================================================
    // Waveform
    // =====================================================================

    /// <inheritdoc />
    public double GetWaveformData(int channel, double[] waveformT, double[] waveformData, int measureAmount)
    {
        if (!_connection[channel])
            return DefCaSdk.DISCONNECTION_CODE;

        try
        {
            var ca = _caDevices[channel];
            var probe = _probes[channel];
            if (ca == null || probe == null)
                return -1;

            // Set waveform display mode and parameters
            ca.put_DisplayMode(MODE_Waveform2);
            // measureAmount = sampling count exponent (e.g. 11 → 2^11 = 2048 samples)
            // sensor = 1 (Y sensor), interval = 1
            ca.SetWaveformParams(measureAmount, 1, 1);

            var ret = ca.Measure();
            if (ret != 0)
                return 0.0;

            uint dataSize = 0;
            probe.get_WaveformDataNumber(ref dataSize);
            if (dataSize == 0)
                return 0.0;

            var tempWfData = new double[dataSize];
            var weightedData = new double[dataSize];
            double observationTime = 0.0;

            probe.GetWaveformData(tempWfData, weightedData, ref dataSize, ref observationTime);

            // Copy waveform data to caller's buffer
            var copyLen = (int)Math.Min(dataSize, (uint)waveformData.Length);
            Array.Copy(tempWfData, waveformData, copyLen);

            // Calculate time array
            var samplingPitch = observationTime / dataSize;
            var timeLen = (int)Math.Min(dataSize, (uint)waveformT.Length);
            for (var i = 0; i < timeLen; i++)
            {
                waveformT[i] = samplingPitch * i;
            }

            return observationTime;
        }
        catch (Exception ex)
        {
            PublishTestForm(MsgMode.Working, channel, isError: false, $"GetWaveformData : Error : {ex.Message}");
            return 0.0;
        }
    }

    // =====================================================================
    // Dispose
    // =====================================================================

    /// <inheritdoc />
    public void Disconnect()
    {
        _devices.Clear();
        _allCaDevices.Clear();
        Array.Clear(_caDevices);
        Array.Clear(_probes);
        Array.Clear(_memories);
        for (int i = 0; i < DefCaSdk.MAX_CH_CNT; i++)
            _connection[i] = false;

        try { _ca200?.AutoDisconnect(); }
        catch { /* ignore disconnect errors */ }
        _ca200 = null;
    }

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        Disconnect();
    }

    // =====================================================================
    // Private helpers
    // =====================================================================

    /// <summary>
    /// Checks connection status for a channel based on its setup configuration.
    /// Original Delphi: <c>TCA_SDK2.CheckConnect</c>
    /// </summary>
    private void CheckConnect(int channel)
    {
        if (_setupList[channel].SelectIdx == DefCaSdk.CONNECTION_NONE)
        {
            PublishMainForm(MsgMode.Ca310Status, channel, isError: false, string.Empty, param: 0);
            _connection[channel] = false;
            return;
        }

        if (_devices.Count == 0)
        {
            var errMsg = $"Channel {channel + 1} CA410 Connection NG";
            PublishMainForm(MsgMode.Ca310Status, channel, isError: true, errMsg);
            PublishTestForm(MsgMode.Working, channel, isError: true, errMsg);
            _connection[channel] = false;
            return;
        }

        // Search for matching serial number
        var found = false;
        var deviceIdx = -1;
        for (var i = 0; i < _devices.Count; i++)
        {
            if (_devices[i].SerialNo == _setupList[channel].SerialNo)
            {
                found = true;
                deviceIdx = i;
                _setupList[channel].Ca410Ch = i;
                break;
            }
        }

        if (!found)
        {
            var errMsg = $"Channel {channel + 1} CA410 Connection NG";
            PublishMainForm(MsgMode.Ca310Status, channel, isError: true, errMsg);
            PublishTestForm(MsgMode.Working, channel, isError: true, errMsg);
            _connection[channel] = false;
            return;
        }

        // Store per-channel SDK objects
        var ca = _allCaDevices[deviceIdx];
        _caDevices[channel] = ca;

        CASDK2Probe? probe = null;
        ca.get_SingleProbe(ref probe);
        _probes[channel] = probe;

        CASDK2Memory? memory = null;
        ca.get_Memory(ref memory);
        _memories[channel] = memory;

        // Connection OK
        PublishMainForm(MsgMode.Ca310Status, channel, isError: false, string.Empty);
        PublishTestForm(MsgMode.Working, channel, isError: false, "CA410 Connect OK");
        _connection[channel] = true;

        // Background initialization (zero cal, averaging mode, memory channel)
        var capturedIdx = deviceIdx;
        var capturedCh = channel;
        Task.Run(() =>
        {
            try
            {
                var chCa = _caDevices[capturedCh];
                var chMemory = _memories[capturedCh];
                if (chCa == null || chMemory == null) return;

                chCa.CalZero();
                PublishTestForm(MsgMode.Working, capturedCh, isError: false, "CA410 ZeroCal");

                chCa.put_AveragingMode(_autoMode);
                chMemory.put_ChannelNO(_memChannel);
                PublishTestForm(MsgMode.Working, capturedCh, isError: false, "CA410 Default Set");

                PublishTestForm(MsgMode.Working, capturedCh, isError: false, "CA410 Get Ca410 MemChannel.");

                var ret = GetMemCh(capturedCh, out var getMemCh);
                if (ret != 0)
                {
                    PublishTestForm(MsgMode.Cax10MemChNo, capturedCh, isError: false, "MEM CH: NG", param: -1);
                    var errMsg = $"Ca410 Memory Channel Read NG - NG Code :{ret:D2}";
                    PublishTestForm(MsgMode.Working, capturedCh, isError: false, errMsg);
                    PublishMainForm(MsgMode.Ca310Status, capturedCh, isError: true, errMsg);
                }
                else
                {
                    var displayItem = string.Format(DefCaSdk.CA410_DISPLAY_ITEM,
                        _devices[capturedIdx].DeviceId, _devices[capturedIdx].SerialNo);
                    PublishTestForm(MsgMode.Cax10MemChNo, capturedCh, isError: false, displayItem, param: getMemCh);

                    var okMsg = $"Get CA410 MEM CH:{getMemCh:D2} - OK";
                    PublishTestForm(MsgMode.Working, capturedCh, isError: false, okMsg);
                }
            }
            catch (Exception ex)
            {
                PublishTestForm(MsgMode.Working, capturedCh, isError: true, $"CheckConnect error: {ex.Message}");
            }
        });
    }

    /// <summary>
    /// Publishes a CA-410 event to the main form via message bus.
    /// Replaces Delphi: <c>TCA_SDK2.ShowMainForm</c> (WM_COPYDATA to m_hMain).
    /// </summary>
    private void PublishMainForm(int mode, int channel, bool isError, string message, int param = 1)
    {
        _messageBus.Publish(new Ca410EventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            IsError = isError,
            Message = message,
        });
    }

    /// <summary>
    /// Publishes a CA-410 event to the test form via message bus.
    /// Replaces Delphi: <c>TCA_SDK2.ShowTestForm</c> (WM_COPYDATA to m_hTest).
    /// </summary>
    private void PublishTestForm(int mode, int channel, bool isError, string message, int param = 1)
    {
        _messageBus.Publish(new Ca410EventMessage
        {
            Channel = channel,
            Mode = mode,
            Param = param,
            IsError = isError,
            Message = message,
        });
    }
}
