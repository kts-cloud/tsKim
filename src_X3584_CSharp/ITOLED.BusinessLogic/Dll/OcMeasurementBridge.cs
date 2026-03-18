// =============================================================================
// OcMeasurementBridge.cs
// Implements LGD_OC_AstractPlatForm.NY_IT.CommonAPI.IMeasurement by
// delegating to ICaSdk2Driver. Bridges the Factory DLL's measurement
// calls to the application's CA-410 colorimeter driver.
//
// Replaces DllManager callback methods:
//   OnCbMeasureXyl, OnCbSetSync, OnCbGetWaveformData, OnCbGetWaveformData2
// =============================================================================

using System.Runtime.InteropServices;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using LGD_OC_AstractPlatForm.NY_IT.CommonAPI;

namespace Dongaeltek.ITOLED.BusinessLogic.Dll;

/// <summary>
/// P/Invoke for libafm.dll (compute_afm).
/// Original Delphi: <c>function compute_afm(...): Double; cdecl; external 'libafm.dll';</c>
/// </summary>
internal static partial class LibAfmInterop
{
    [DllImport("libafm.dll", CallingConvention = CallingConvention.Cdecl)]
    internal static extern double compute_afm(
        IntPtr waveformT,
        IntPtr waveformData,
        int measureAmount,
        double devType,
        int apodize,
        int harmonicInd);
}

/// <summary>
/// Bridges the Factory DLL's <c>IMeasurement</c> interface to the application's
/// <see cref="ICaSdk2Driver"/> singleton.
/// </summary>
public class OcMeasurementBridge : IMeasurement
{
    private readonly int _channel;
    private readonly ICaSdk2Driver _caSdk2;
    private readonly object _afmLock;
    private readonly Action<int, string>? _logCallback;

    public OcMeasurementBridge(int channel, ICaSdk2Driver caSdk2, object afmLock,
        Action<int, string>? logCallback = null)
    {
        _channel = channel;
        _caSdk2 = caSdk2;
        _afmLock = afmLock;
        _logCallback = logCallback;
    }

    public double[] measure_XYL(int channel_num)
    {
        var ret = _caSdk2.Measure(_channel, out var bright);
        if (ret != 0)
            _logCallback?.Invoke(_channel, $"CA410 measure NG CH : {_channel}");
        return new[] { bright.X, bright.Y, bright.Lv };
    }

    public double[] measure_UVL(int channel_num)
    {
        // Not used in current OC flow — return zeros
        return new double[] { 0, 0, 0 };
    }

    public unsafe double measure_AFM(out double[] waveform_T, out double[] waveformData,
        int RR, int measureAmount, int comb, int channel)
    {
        waveform_T = new double[Math.Max(measureAmount, 1)];
        waveformData = new double[Math.Max(measureAmount, 1)];

        if (measureAmount <= 0)
            return 0.0;

        try
        {
            _caSdk2.GetWaveformData(_channel, waveform_T, waveformData, measureAmount);

            // Compute AFM with synchronization
            lock (_afmLock)
            {
                fixed (double* pWaveform = waveform_T)
                fixed (double* pData = waveformData)
                {
                    return LibAfmInterop.compute_afm(
                        (IntPtr)pWaveform, (IntPtr)pData,
                        measureAmount, -1017.0, 1, 1);
                }
            }
        }
        catch (Exception ex)
        {
            _logCallback?.Invoke(_channel, $"measure_AFM error: {ex.Message}");
            return 0.0;
        }
    }

    public void SetSync(int CA_SyncMode, int CA_Hz, int channel_num)
    {
        _caSdk2.SetSyncMode(_channel, CA_SyncMode, CA_Hz, 0);
    }

    public void Set_CA_CAl_Channel(int cal_channel, int channel_num)
    {
        // Not used in current OC flow
    }
}
