// =============================================================================
// LibAfmInterop.cs
// Converted from Delphi: src_X3584\dllClass.pas (compute_afm external declaration)
// P/Invoke wrapper for libafm.dll — AFM (Advanced Flicker Measurement) computation.
// Namespace: Dongaeltek.ITOLED.Hardware.Fpga
// =============================================================================

using System.Runtime.InteropServices;

namespace Dongaeltek.ITOLED.Hardware.Fpga;

/// <summary>
/// P/Invoke wrapper for <c>libafm.dll</c> — AFM (Advanced Flicker Measurement) computation.
/// <para>The native function computes flicker metrics from waveform data captured by
/// the FPGA acquisition subsystem. It accepts paired time/value arrays and returns
/// a flicker measurement value for the specified harmonic.</para>
/// <para>Delphi origin: <c>dllClass.pas</c> —
/// <c>function compute_afm(waveform_T: PDouble; waveformData: PDouble;
/// measureAmount: Integer; dev_type: Double; apodize: Integer;
/// harmonic_ind: Integer): Double; cdecl; external 'libafm.dll';</c></para>
/// </summary>
public static class LibAfmInterop
{
    private const string DllName = "libafm.dll";

    /// <summary>
    /// Computes the AFM (Advanced Flicker Measurement) value from waveform data.
    /// </summary>
    /// <param name="waveformT">
    /// Array of time-axis sample points (length = <paramref name="measureAmount"/>).
    /// </param>
    /// <param name="waveformData">
    /// Array of measured waveform amplitude values (length = <paramref name="measureAmount"/>).
    /// </param>
    /// <param name="measureAmount">Number of samples in the waveform arrays.</param>
    /// <param name="devType">Device type parameter (measurement configuration).</param>
    /// <param name="apodize">Apodization window type selector (0 = none, etc.).</param>
    /// <param name="harmonicInd">Harmonic index to compute (e.g., 1 for fundamental).</param>
    /// <returns>Computed flicker measurement value for the specified harmonic.</returns>
    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern double compute_afm(
        [In] double[] waveformT,
        [In] double[] waveformData,
        int measureAmount,
        double devType,
        int apodize,
        int harmonicInd);
}
