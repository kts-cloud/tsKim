namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Thread-safe access to system-wide status flags.
/// Replaces Delphi's <c>Common.StatusInfo : TStatusInfo</c> record.
/// </summary>
public interface ISystemStatusService
{
    /// <summary>Auto mode (PLC/robot interlock active). Delphi: StatusInfo.AutoMode</summary>
    bool AutoMode { get; set; }

    /// <summary>ECS/MES login status. Delphi: StatusInfo.LogIn</summary>
    bool IsLoggedIn { get; set; }

    /// <summary>Application is shutting down. Delphi: StatusInfo.Closing</summary>
    bool IsClosing { get; set; }

    /// <summary>Panel loading in progress. Delphi: StatusInfo.Loading</summary>
    bool IsLoading { get; set; }

    /// <summary>Alarm currently active. Delphi: StatusInfo.AlarmOn</summary>
    bool AlarmOn { get; set; }

    /// <summary>Robot door is open. Delphi: StatusInfo.RobotDoorOpened</summary>
    bool RobotDoorOpened { get; set; }

    /// <summary>Last glass flag. Delphi: StatusInfo.LastProduct</summary>
    bool IsLastProduct { get; set; }

    /// <summary>Stage is turning. Delphi: StatusInfo.StageTurnning</summary>
    bool IsStageTurning { get; set; }

    /// <summary>AAB mode active. Delphi: StatusInfo.AABMode</summary>
    bool AabMode { get; set; }

    /// <summary>Auto-repeat test running. Delphi: StatusInfo.Test_AutoRepeat</summary>
    bool AutoRepeatTest { get; set; }

    /// <summary>
    /// Per-channel use flag (4 channels). Delphi: StatusInfo.UseChannel[0..3]
    /// </summary>
    bool GetChannelEnabled(int channel);

    /// <summary>Sets whether a channel is enabled.</summary>
    void SetChannelEnabled(int channel, bool enabled);

    /// <summary>
    /// Stage step per stage index (0..2).
    /// 0=None, 1=Loading, 2=LoadComplete, 3=LoadingZone, 4=Turning,
    /// 5=CamZone, 6=UnloadZone, 7=Unload.
    /// Delphi: StatusInfo.StageStep[0..2]
    /// </summary>
    int GetStageStep(int stageIndex);

    /// <summary>Sets the stage step for a given stage index.</summary>
    void SetStageStep(int stageIndex, int step);

    /// <summary>
    /// Alarm data array (151 bytes). Delphi: StatusInfo.AlarmData[0..150]
    /// </summary>
    byte GetAlarmData(int index);

    /// <summary>Sets alarm data at the given index.</summary>
    void SetAlarmData(int index, byte value);

    /// <summary>
    /// Alarm message for a given index. Delphi: StatusInfo.AlarmMsg[0..150]
    /// </summary>
    string GetAlarmMessage(int index);

    /// <summary>Sets the alarm message at a given index.</summary>
    void SetAlarmMessage(int index, string message);

    /// <summary>
    /// Load/Unload flow data per channel, per step.
    /// Delphi: StatusInfo.LoadUnloadFlowData[CH1..MAX_CH][0..50]
    /// </summary>
    int GetLoadUnloadFlowData(int channel, int stepIndex);

    /// <summary>Sets load/unload flow data for a channel at a step.</summary>
    void SetLoadUnloadFlowData(int channel, int stepIndex, int value);

    /// <summary>Clears all alarm data and alarm messages.</summary>
    void ClearAlarms();

    /// <summary>Resets all status fields to their defaults.</summary>
    void Reset();
}
