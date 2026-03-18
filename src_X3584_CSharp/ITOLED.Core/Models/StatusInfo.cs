// =============================================================================
// StatusInfo.cs
// Converted from Delphi: src_X3584\CommonClass.pas (lines 263-279)
// Contains: TStatusInfo
// =============================================================================

using Dongaeltek.ITOLED.Core.Definitions;

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// Runtime status information tracking machine state, alarm, and channel usage.
    /// <para>Original Delphi: TStatusInfo = record (CommonClass.pas line 263)</para>
    /// </summary>
    public class StatusInfo
    {
        /// <summary>
        /// Robot (PLC) auto-mode (interlock) flag.
        /// <para>Delphi field: AutoMode : boolean</para>
        /// </summary>
        public bool AutoMode { get; set; }

        /// <summary>
        /// ECS (MES) login status.
        /// <para>Delphi field: LogIn : Boolean</para>
        /// </summary>
        public bool LogIn { get; set; }

        /// <summary>
        /// Program is shutting down.
        /// <para>Delphi field: Closing : boolean</para>
        /// </summary>
        public bool Closing { get; set; }

        /// <summary>
        /// Robot (PLC) panel loading in progress.
        /// <para>Delphi field: Loading : boolean</para>
        /// </summary>
        public bool Loading { get; set; }

        /// <summary>
        /// Alarm active.
        /// <para>Delphi field: AlarmOn : Boolean</para>
        /// </summary>
        public bool AlarmOn { get; set; }

        /// <summary>
        /// Robot (material flow) door is open.
        /// <para>Delphi field: RobotDoorOpened : Boolean</para>
        /// </summary>
        public bool RobotDoorOpened { get; set; }

        /// <summary>
        /// Stage step state per stage (0=None, 1=Loading(Exchange), 2=LoadComplete, etc.).
        /// <para>Delphi field: StageStep : array[0..2] of Integer</para>
        /// </summary>
        public int[] StageStep { get; set; }

        /// <summary>
        /// Whether this is the last glass panel.
        /// <para>Delphi field: LastProduct : Boolean</para>
        /// </summary>
        public bool LastProduct { get; set; }

        /// <summary>
        /// Stage is currently turning.
        /// <para>Delphi field: StageTurnning : Boolean</para>
        /// </summary>
        public bool StageTurning { get; set; }

        /// <summary>
        /// AAB mode flag.
        /// <para>Delphi field: AABMode : Boolean</para>
        /// </summary>
        public bool AABMode { get; set; }

        /// <summary>
        /// Per-channel usage check flags.
        /// <para>Delphi field: UseChannel : array[0..3] of Boolean</para>
        /// </summary>
        public bool[] UseChannel { get; set; }

        /// <summary>
        /// Alarm data list (byte array, indexed 0..150).
        /// <para>Delphi field: AlarmData : array[0..150] of Byte</para>
        /// </summary>
        public byte[] AlarmData { get; set; }

        /// <summary>
        /// Alarm messages (indexed 0..150).
        /// <para>Delphi field: AlarmMsg : array[0..150] of String</para>
        /// </summary>
        public string[] AlarmMsg { get; set; }

        /// <summary>
        /// Auto-repeat test in progress.
        /// <para>Delphi field: Test_AutoRepeat : Boolean</para>
        /// </summary>
        public bool TestAutoRepeat { get; set; }

        /// <summary>
        /// Per-channel load/unload flow signal positions.
        /// <para>Delphi field: LoadUnloadFlowData : array[CH1..MAX_CH] of array[0..50] of Integer</para>
        /// </summary>
        public int[][] LoadUnloadFlowData { get; set; }

        /// <summary>
        /// Initializes all arrays with proper sizes.
        /// </summary>
        public StatusInfo()
        {
            int chCount = ChannelConstants.MaxCh + 1;

            StageStep = new int[3];
            UseChannel = new bool[4];
            AlarmData = new byte[151];
            AlarmMsg = new string[151];

            for (int i = 0; i < AlarmMsg.Length; i++)
                AlarmMsg[i] = string.Empty;

            LoadUnloadFlowData = new int[chCount][];
            for (int ch = 0; ch < chCount; ch++)
                LoadUnloadFlowData[ch] = new int[51];
        }
    }
}
