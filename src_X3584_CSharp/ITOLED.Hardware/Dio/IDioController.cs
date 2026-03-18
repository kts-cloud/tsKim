// =============================================================================
// IDioController.cs
// Interface for the DIO controller orchestrating digital I/O operations.
// Converted from Delphi: src_X3584\ControlDio_OC.pas (TControlDio public API)
// Namespace: Dongaeltek.ITOLED.Hardware.Dio
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Hardware.Dio;

/// <summary>
/// DIO controller orchestrator for the ITOLED OC inspection system.
/// Manages carrier lock/unlock, probe movement, shutter control, pin-block operations,
/// vacuum, tower lamp, alarm checking, and signal I/O through the DAE DIO hardware.
/// <para>Delphi origin: <c>TControlDio</c> in ControlDio_OC.pas</para>
/// </summary>
public interface IDioController : IDisposable
{
    // =========================================================================
    // Properties
    // =========================================================================

    /// <summary>
    /// Whether the DIO device is currently connected.
    /// <para>Delphi origin: TControlDio.Connected</para>
    /// </summary>
    bool Connected { get; }

    /// <summary>
    /// Alarm data bit-array (indexed by DioError constants, packed into bytes).
    /// <para>Delphi origin: TControlDio.DioAlarmData[0..MAX_ALARM_DATA_SIZE]</para>
    /// </summary>
    int[] DioAlarmData { get; }

    /// <summary>
    /// Last NG (no-good) error message text.
    /// <para>Delphi origin: TControlDio.LastNgMsg</para>
    /// </summary>
    string LastNgMsg { get; }

    /// <summary>
    /// Current load-zone stage (None, A, B).
    /// <para>Delphi origin: TControlDio.LoadZoneStage</para>
    /// </summary>
    LoadZoneStage LoadZoneStage { get; set; }

    /// <summary>
    /// Whether the tower lamp control is enabled.
    /// <para>Delphi origin: TControlDio.UseTowerLamp</para>
    /// </summary>
    bool UseTowerLamp { get; set; }

    /// <summary>
    /// Whether the melody/buzzer is enabled.
    /// <para>Delphi origin: TControlDio.MelodyOn</para>
    /// </summary>
    bool MelodyOn { get; set; }

    // =========================================================================
    // Carrier Operations (OC type only)
    // =========================================================================

    /// <summary>
    /// Locks the carrier for the specified channel or group.
    /// Verifies 4 lock sensors per channel after engaging the lock solenoid.
    /// <para>Delphi origin: TControlDio.LockCarrier(nCh, bMainter)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3) or group constant (ChTopGroup=10, ChBottomGroup=11).</param>
    /// <param name="isMaintenanceMode">True if called from maintenance screen.</param>
    /// <returns>0=OK, 1=NG, 2=not applicable or sensor timeout.</returns>
    int LockCarrier(int channel, bool isMaintenanceMode);

    /// <summary>
    /// Unlocks the carrier for the specified channel or group.
    /// Verifies 4 unlock sensors per channel after engaging the unlock solenoid.
    /// <para>Delphi origin: TControlDio.UnlockCarrier(nCh, bMainter)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3) or group constant (ChTopGroup=10, ChBottomGroup=11, ChAllGroup=12).</param>
    /// <param name="isMaintenanceMode">True if called from maintenance screen.</param>
    /// <returns>0=OK, 1=NG, 2=not applicable or sensor timeout.</returns>
    int UnlockCarrier(int channel, bool isMaintenanceMode);

    // =========================================================================
    // Probe Operations (OC type only)
    // =========================================================================

    /// <summary>
    /// Moves the probe forward (down then forward sequence) for a specific channel.
    /// <para>Delphi origin: TControlDio.ProbeForward(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int ProbeForward(int channel);

    /// <summary>
    /// Moves the probe backward (up then backward sequence) for a specific channel.
    /// <para>Delphi origin: TControlDio.ProbeBackward(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int ProbeBackward(int channel);

    // =========================================================================
    // Shutter / Probe / Combined Operations (PreOC/GIB type)
    // =========================================================================

    /// <summary>
    /// Moves the shutter up or down for the specified group.
    /// Includes robot sensor and PLC interlock checks for shutter down.
    /// <para>Delphi origin: TControlDio.MovingShutter(nGroup, bIsUp)</para>
    /// </summary>
    /// <param name="group">Group (ChTop=0, ChBottom=1, ChAll=2).</param>
    /// <param name="isUp">True=up, False=down.</param>
    /// <returns>0=OK, 2=NG/timeout, 3=interlock blocked.</returns>
    int MovingShutter(int group, bool isUp);

    /// <summary>
    /// Moves the probe up or down for the specified group.
    /// Includes robot sensor, tilting sensor, and PLC interlock checks.
    /// <para>Delphi origin: TControlDio.MovingProbe(nGroup, bIsUp)</para>
    /// </summary>
    /// <param name="group">Group (ChTop=0, ChBottom=1).</param>
    /// <param name="isUp">True=up, False=down.</param>
    /// <returns>0=OK, 2=NG/timeout, 3=interlock blocked.</returns>
    int MovingProbe(int group, bool isUp);

    /// <summary>
    /// Moves both probe and shutter simultaneously up or down.
    /// <para>Delphi origin: TControlDio.MovingAll(nGroup, bIsUp)</para>
    /// </summary>
    /// <param name="group">Group (ChTop=0, ChBottom=1).</param>
    /// <param name="isUp">True=up, False=down.</param>
    /// <returns>0=OK, 2=NG/timeout, 3=interlock blocked.</returns>
    int MovingAll(int group, bool isUp);

    // =========================================================================
    // Pin-Block Operations (PreOC type only)
    // =========================================================================

    /// <summary>
    /// Locks the pin-block for the specified channel.
    /// <para>Delphi origin: TControlDio.LockPinBlock(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int LockPinBlock(int channel);

    /// <summary>
    /// Unlocks the pin-block for the specified channel.
    /// <para>Delphi origin: TControlDio.UnlockPinBlock(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int UnlockPinBlock(int channel);

    /// <summary>
    /// Moves the pin-block close prevention mechanism upward.
    /// <para>Delphi origin: TControlDio.CLOSE_Up_PinBlock(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int CloseUpPinBlock(int channel);

    /// <summary>
    /// Moves the pin-block close prevention mechanism downward.
    /// <para>Delphi origin: TControlDio.CLOSE_Dn_PinBlock(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int CloseDnPinBlock(int channel);

    /// <summary>
    /// Checks pin-block open/close status.
    /// <para>Delphi origin: TControlDio.CheckOpenPinBlock(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=open, 1=closed.</returns>
    int CheckOpenPinBlock(int channel);

    // =========================================================================
    // Vacuum Operations (PreOC type only)
    // =========================================================================

    /// <summary>
    /// Turns vacuum ON for the specified channel.
    /// <para>Delphi origin: TControlDio.VaccumON(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int VacuumOn(int channel);

    /// <summary>
    /// Turns vacuum OFF for the specified channel.
    /// <para>Delphi origin: TControlDio.VaccumOFF(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG/timeout, 2=not applicable.</returns>
    int VacuumOff(int channel);

    // =========================================================================
    // PG Power Reset
    // =========================================================================

    /// <summary>
    /// Resets PG power for all channels.
    /// <para>Delphi origin: TControlDio.PowerResetPG</para>
    /// </summary>
    /// <returns>0=OK, 1=NG.</returns>
    int PowerResetPg();

    /// <summary>
    /// Resets PG power for a specific channel.
    /// <para>Delphi origin: TControlDio.PowerResetPG_CH(nCH)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=NG.</returns>
    int PowerResetPgChannel(int channel);

    // =========================================================================
    // Signal I/O
    // =========================================================================

    /// <summary>
    /// Writes a digital output signal.
    /// <para>Delphi origin: TControlDio.WriteDioSig(nSignal, bIsRemove)</para>
    /// </summary>
    /// <param name="signal">Output signal index (0-95).</param>
    /// <param name="isRemove">True to clear (OFF), False to set (ON).</param>
    /// <returns>0=OK.</returns>
    int WriteDioSig(int signal, bool isRemove = false);

    /// <summary>
    /// Clears (turns OFF) a digital output signal.
    /// <para>Delphi origin: TControlDio.ClearOutDioSig(nSig)</para>
    /// </summary>
    /// <param name="signal">Output signal index (0-95).</param>
    void ClearOutDioSig(int signal);

    /// <summary>
    /// Reads a digital input signal state.
    /// <para>Delphi origin: TControlDio.ReadInSig(nSignal)</para>
    /// </summary>
    /// <param name="signal">Input signal index (0-95).</param>
    /// <returns>True if the signal is high.</returns>
    bool ReadInSig(int signal);

    /// <summary>
    /// Reads a digital output signal state from the flush buffer.
    /// <para>Delphi origin: TControlDio.ReadOutSig(nSignal)</para>
    /// </summary>
    /// <param name="signal">Output signal index (0-95).</param>
    /// <returns>True if the output signal is high.</returns>
    bool ReadOutSig(int signal);

    // =========================================================================
    // Detection and Interlock
    // =========================================================================

    /// <summary>
    /// Checks whether a carrier is detected for the specified jig/group.
    /// <para>Delphi origin: TControlDio.IsDetected(nCH)</para>
    /// </summary>
    /// <param name="channel">Jig index (0=TOP, 1=BOTTOM).</param>
    /// <returns>True if a carrier is detected.</returns>
    bool IsDetected(int channel);

    /// <summary>
    /// Checks PreOC probe interlock for a group.
    /// <para>Delphi origin: TControlDio.IsPreOCInterlockPROBE(nCH)</para>
    /// </summary>
    /// <param name="channel">Group index (0=TOP, 1=BOTTOM).</param>
    /// <returns>1 if interlock condition met, 0 otherwise.</returns>
    int IsPreOcInterlockProbe(int channel);

    /// <summary>
    /// Checks PreOC probe interlock for a specific channel.
    /// <para>Delphi origin: TControlDio.IsPreOCInterlockPROBE_CH(nCH)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>1 if interlock condition met, 0 otherwise.</returns>
    int IsPreOcInterlockProbeChannel(int channel);

    /// <summary>
    /// Checks PreOC shutter interlock for a group.
    /// <para>Delphi origin: TControlDio.IsPreOCInterlockSHUTTER(nCH)</para>
    /// </summary>
    /// <param name="channel">Group index (0=TOP, 1=BOTTOM).</param>
    /// <returns>1 if interlock condition met, 0 otherwise.</returns>
    int IsPreOcInterlockShutter(int channel);

    /// <summary>
    /// Checks DIO start conditions for a group.
    /// <para>Delphi origin: TControlDio.CheckDIO_Start(nCH)</para>
    /// </summary>
    /// <param name="channel">Group index.</param>
    /// <returns>True if start conditions are met.</returns>
    bool CheckDioStart(int channel);

    /// <summary>
    /// Checks PreOC panel detect status per channel.
    /// <para>Delphi origin: TControlDio.CheckPreOCPanelDetectCh(nCh, nReverseMode)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <param name="reverseMode">0=normal, 1=reverse logic.</param>
    /// <returns>0=panel present, 1=no panel.</returns>
    int CheckPreOcPanelDetectChannel(int channel, int reverseMode = 0);

    /// <summary>
    /// Checks PreOC panel detect status per jig.
    /// <para>Delphi origin: TControlDio.CheckPreOcPanelDetectJig(nJig)</para>
    /// </summary>
    /// <param name="jig">Jig index (0=TOP, 1=BOTTOM).</param>
    /// <returns>0=panel present, 1=no panel.</returns>
    int CheckPreOcPanelDetectJig(int jig);

    /// <summary>
    /// Checks PreOC unload status for a channel.
    /// <para>Delphi origin: TControlDio.CheckPreOcUnloadStatus(nCh)</para>
    /// </summary>
    /// <param name="channel">Channel index (0-3).</param>
    /// <returns>0=OK, 1=interlock condition.</returns>
    int CheckPreOcUnloadStatus(int channel);

    /// <summary>
    /// Checks if all doors are open (OC type only).
    /// <para>Delphi origin: TControlDio.CheckAllDoorOpen</para>
    /// </summary>
    /// <returns>True if all doors are open.</returns>
    bool CheckAllDoorOpen();

    // =========================================================================
    // Fan / Ionizer / Lamp / Door
    // =========================================================================

    /// <summary>
    /// Sets fan on or off for a specific channel.
    /// <para>Delphi origin: TControlDio.SetFanOnOff(bCH, bIsOnOff)</para>
    /// </summary>
    bool SetFanOnOff(int channel, bool isOnOff);

    /// <summary>
    /// Sets ionizer on or off for a group.
    /// <para>Delphi origin: TControlDio.SetIonizer(nGroup, bIsOnOff)</para>
    /// </summary>
    bool SetIonizer(int group, bool isOnOff);

    /// <summary>
    /// Turns inspection lamp on or off for a group.
    /// <para>Delphi origin: TControlDio.LampOnOff(nGroup, bIsOnOff)</para>
    /// </summary>
    int LampOnOff(int group, bool isOnOff);

    /// <summary>
    /// Unlocks a side door.
    /// <para>Delphi origin: TControlDio.UnlockDoorOpen(nch, bUnlock)</para>
    /// </summary>
    bool UnlockDoorOpen(int channel, bool unlock);

    // =========================================================================
    // Alarm and Tower Lamp
    // =========================================================================

    /// <summary>
    /// Sets alarm data at the given index.
    /// <para>Delphi origin: TControlDio.Set_AlarmData(nIndex, nValue)</para>
    /// </summary>
    void SetAlarmData(int index, int value);

    /// <summary>
    /// Sets the tower lamp state.
    /// <para>Delphi origin: TControlDio.Set_TowerLampState(nState)</para>
    /// </summary>
    void SetTowerLampState(int state);

    // =========================================================================
    // Display and Error Management
    // =========================================================================

    /// <summary>
    /// Sends a display I/O refresh message to the main GUI.
    /// <para>Delphi origin: TControlDio.DisplayIo</para>
    /// </summary>
    void DisplayIo();

    /// <summary>
    /// Refreshes I/O state.
    /// <para>Delphi origin: TControlDio.RefreshIo</para>
    /// </summary>
    void RefreshIo();

    /// <summary>
    /// Resets error state (0=all, 1=IO errors only, 2=IO errors + clear display).
    /// <para>Delphi origin: TControlDio.ResetError(nIdx)</para>
    /// </summary>
    void ResetError(int index);

    /// <summary>
    /// Runs error check on a background thread.
    /// <para>Delphi origin: TControlDio.BackgroundErrorCheck</para>
    /// </summary>
    void BackgroundErrorCheck();
}

/// <summary>
/// Load zone stage enumeration.
/// <para>Delphi origin: TLoadZoneStage = (lzsNone, lzsA, lzsB)</para>
/// </summary>
public enum LoadZoneStage
{
    /// <summary>No stage.</summary>
    None = 0,

    /// <summary>A stage.</summary>
    A = 1,

    /// <summary>B stage.</summary>
    B = 2,
}
