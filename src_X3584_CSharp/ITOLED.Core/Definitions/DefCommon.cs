// =============================================================================
// DefCommon.cs
// Converted from Delphi: src_X3584\DefCommon.pas
// Namespace: Dongaeltek.ITOLED.Core.Definitions
// =============================================================================

using System;

namespace Dongaeltek.ITOLED.Core.Definitions
{
    // =========================================================================
    // Program Information
    // =========================================================================

    /// <summary>
    /// Program version and name constants.
    /// </summary>
    public static class ProgramInfo
    {
        /// <summary>Original Delphi: PROGRAM_VER</summary>
        public const string ProgramVersion = "R1.00";

        /// <summary>Original Delphi: PROGRAM_NAME</summary>
        public const string ProgramName = "Inspector OLED Display OC";

        /// <summary>Original Delphi: MSG_SCAN_BCR</summary>
        public const string MsgScanBcr = "SCAN BCR";
    }

    // =========================================================================
    // TIB Server Constants
    // =========================================================================

    /// <summary>
    /// TIB Server index constants.
    /// Original Delphi: TIBServer_MES, TIBServer_EAS, TIBServer_R2R, TIBServer_MAX
    /// </summary>
    public static class TibServer
    {
        /// <summary>Original Delphi: TIBServer_MES = 0</summary>
        public const int Mes = 0;

        /// <summary>Original Delphi: TIBServer_EAS = 1</summary>
        public const int Eas = 1;

        /// <summary>Original Delphi: TIBServer_R2R = 2</summary>
        public const int R2R = 2;

        /// <summary>Original Delphi: TIBServer_MAX = TIBServer_EAS + 1</summary>
        public const int Max = Eas + 1;
    }

    // =========================================================================
    // Channel and JIG Constants
    // =========================================================================

    /// <summary>
    /// Channel, JIG, and PG-related constants.
    /// </summary>
    public static class ChannelConstants
    {
        /// <summary>Original Delphi: PG_CNT = 4</summary>
        public const int PgCount = 4;

        /// <summary>Original Delphi: OCType = 0</summary>
        public const int OcType = 0;

        /// <summary>Original Delphi: PreOCType = 1</summary>
        public const int PreOcType = 1;

        /// <summary>Original Delphi: MAX_PG_CNT = 4</summary>
        public const int MaxPgCount = 4;

        /// <summary>Original Delphi: CH_TOP = 0</summary>
        public const int ChTop = 0;

        /// <summary>Original Delphi: CH_BOTTOM = 1</summary>
        public const int ChBottom = 1;

        /// <summary>Original Delphi: CH_ALL = 2</summary>
        public const int ChAll = 2;

        /// <summary>Original Delphi: JIG_A = 0</summary>
        public const int JigA = 0;

        /// <summary>Original Delphi: JIG_B = 0</summary>
        public const int JigB = 0;

        /// <summary>Original Delphi: MAX_JIG_CNT = 1</summary>
        public const int MaxJigCount = 1;

        /// <summary>Original Delphi: PG_1 = 0</summary>
        public const int Pg1 = 0;

        /// <summary>Original Delphi: PG_MAX = 3</summary>
        public const int PgMax = 3;

        /// <summary>Original Delphi: CH1 = 0</summary>
        public const int Ch1 = 0;

        /// <summary>Original Delphi: CH2 = 1</summary>
        public const int Ch2 = 1;

        /// <summary>Original Delphi: CH3 = 2</summary>
        public const int Ch3 = 2;

        /// <summary>Original Delphi: CH4 = 3</summary>
        public const int Ch4 = 3;

        /// <summary>Original Delphi: CH5 = 4</summary>
        public const int Ch5 = 4;

        /// <summary>Original Delphi: CH6 = 5</summary>
        public const int Ch6 = 5;

        /// <summary>Original Delphi: CH7 = 6</summary>
        public const int Ch7 = 6;

        /// <summary>Original Delphi: CH8 = 7</summary>
        public const int Ch8 = 7;

        /// <summary>Original Delphi: CH_STAGE_A = 8</summary>
        public const int ChStageA = 8;

        /// <summary>Original Delphi: CH_STAGE_B = 9</summary>
        public const int ChStageB = 9;

        /// <summary>Original Delphi: CH_TOPGroup = 10</summary>
        public const int ChTopGroup = 10;

        /// <summary>Original Delphi: CH_BOTTOMGroup = 11</summary>
        public const int ChBottomGroup = 11;

        /// <summary>Original Delphi: CH_ALLGroup = 12</summary>
        public const int ChAllGroup = 12;

        /// <summary>Original Delphi: CH1_GIB = 0</summary>
        public const int Ch1Gib = 0;

        /// <summary>Original Delphi: CH2_GIB = 1</summary>
        public const int Ch2Gib = 1;

        /// <summary>Original Delphi: CH3_GIB = 2</summary>
        public const int Ch3Gib = 2;

        /// <summary>Original Delphi: CH4_GIB = 3</summary>
        public const int Ch4Gib = 3;

        /// <summary>Original Delphi: MAX_CH = 3</summary>
        public const int MaxCh = 3;

        /// <summary>Original Delphi: MAX_JIG_CH = 3</summary>
        public const int MaxJigCh = 3;
    }

    // =========================================================================
    // CSV Constants
    // =========================================================================

    /// <summary>
    /// CSV header and data row limits.
    /// </summary>
    public static class CsvConstants
    {
        /// <summary>Original Delphi: MAX_CSV_HEADER_ROWS = 3</summary>
        public const int MaxCsvHeaderRows = 3;

        /// <summary>Original Delphi: MAX_CSV_DATA_ROW = 4</summary>
        public const int MaxCsvDataRow = 4;
    }

    // =========================================================================
    // CA (Colorimeter/Analyzer) Constants
    // =========================================================================

    /// <summary>
    /// CA310 and CA drive count constants.
    /// </summary>
    public static class CaConstants
    {
        /// <summary>Original Delphi: MAX_CA_DRIVE_CNT = 10</summary>
        public const int MaxCaDriveCount = 10;

        /// <summary>Original Delphi: MAX_CA310_CAL_ITEM = 4 (White, R, G, B)</summary>
        public const int MaxCa310CalItem = 4;
    }

    // =========================================================================
    // Misc Limit Constants
    // =========================================================================

    /// <summary>
    /// Miscellaneous limit constants for previous results, logs, BCR, switches, ionizers.
    /// </summary>
    public static class LimitConstants
    {
        /// <summary>Original Delphi: MAX_PREVIOUS_RESULT = 2</summary>
        public const int MaxPreviousResult = 2;

        /// <summary>Original Delphi: MAX_SYSTEM_LOG = MAX_PG_CNT</summary>
        public const int MaxSystemLog = ChannelConstants.MaxPgCount;

        /// <summary>Original Delphi: MAX_PLC_LOG = MAX_PG_CNT + 1</summary>
        public const int MaxPlcLog = ChannelConstants.MaxPgCount + 1;

        /// <summary>Original Delphi: MAX_BCR_CNT = 2</summary>
        public const int MaxBcrCount = 2;

        /// <summary>Original Delphi: MAX_SWITCH_CNT = 2</summary>
        public const int MaxSwitchCount = 2;

        /// <summary>Original Delphi: MAX_IONIZER_CNT = 2</summary>
        public const int MaxIonizerCount = 2;

        /// <summary>Original Delphi: MAX_GUI_DATA_CNT = 10</summary>
        public const int MaxGuiDataCount = 10;

        /// <summary>Original Delphi: MAX_MODEL_CGID_CNT = 100</summary>
        public const int MaxModelCgidCount = 100;

        /// <summary>Original Delphi: MAX_TOUCH_DATA_LENGTH_GUI = 36</summary>
        public const int MaxTouchDataLengthGui = 36;
    }

    // =========================================================================
    // RGB Average Type Constants
    // =========================================================================

    /// <summary>
    /// RGB average type constants.
    /// Original Delphi: IDX_RGB_AVR_TYPE_*
    /// </summary>
    public static class RgbAverageType
    {
        /// <summary>Original Delphi: IDX_RGB_AVR_TYPE_NONE = 0 (AVERAGE TYPE NOT USE)</summary>
        public const int None = 0;

        /// <summary>Original Delphi: IDX_RGB_AVR_TYPE_A = 1 (A Type: 1st measurement Average)</summary>
        public const int TypeA = 1;

        /// <summary>Original Delphi: IDX_RGB_AVR_TYPE_B = 2 (B Type: Average Count based)</summary>
        public const int TypeB = 2;

        /// <summary>Original Delphi: IDX_RGB_AVR_TYPE_C = 3 (C Type: Average Count with MIN/MAX exclusion)</summary>
        public const int TypeC = 3;
    }

    // =========================================================================
    // IP Local Constants
    // =========================================================================

    /// <summary>
    /// IP local configuration indices.
    /// </summary>
    public static class IpLocalIndex
    {
        /// <summary>Original Delphi: IP_LOCAL_ALL = 0</summary>
        public const int All = 0;

        /// <summary>Original Delphi: IP_LOCAL_GMES = 1</summary>
        public const int Gmes = 1;

        /// <summary>Original Delphi: IP_LOCAL_PLC = 2</summary>
        public const int Plc = 2;

        /// <summary>Original Delphi: IP_PLC_CONFIG_PATH = 3</summary>
        public const int PlcConfigPath = 3;

        /// <summary>Original Delphi: IP_EM_NUMBER = 4</summary>
        public const int EmNumber = 4;
    }

    // =========================================================================
    // Sequence ID Constants
    // =========================================================================

    /// <summary>
    /// Sequence ID constants for process flow.
    /// </summary>
    public static class SequenceId
    {
        /// <summary>Original Delphi: SEQ_STOP = 0 (Start 1: bcr or power on)</summary>
        public const int Stop = 0;

        /// <summary>Original Delphi: SEQ_2 = 1 (Start 2: bcr or power on)</summary>
        public const int Seq2 = 1;

        /// <summary>Original Delphi: SEQ_3 = 2</summary>
        public const int Seq3 = 2;

        /// <summary>Original Delphi: SEQ_4 = 3</summary>
        public const int Seq4 = 3;

        /// <summary>Original Delphi: SEQ_END = 9 (POWER OFF)</summary>
        public const int End = 9;
    }

    // =========================================================================
    // OC Table Constants
    // =========================================================================

    /// <summary>
    /// OC table type constants.
    /// </summary>
    public static class OcTable
    {
        /// <summary>Original Delphi: OC_TABLE_PARAM = 1</summary>
        public const int Param = 1;

        /// <summary>Original Delphi: OC_TABLE_VERIFY = 2</summary>
        public const int Verify = 2;

        /// <summary>Original Delphi: OC_OTP_TABLE = 3</summary>
        public const int Otp = 3;

        /// <summary>Original Delphi: OC_OFFSET_TABLE = 4</summary>
        public const int Offset = 4;
    }

    // =========================================================================
    // CA310 Check Status Constants
    // =========================================================================

    /// <summary>
    /// CA310 check status result constants.
    /// </summary>
    public static class CheckCa310Status
    {
        /// <summary>Original Delphi: CHECK_CA310_OK = 0</summary>
        public const int Ok = 0;

        /// <summary>Original Delphi: CHECK_CA310_NOT_CHECK = 1</summary>
        public const int NotCheck = 1;

        /// <summary>Original Delphi: CHECK_CA310_USER_CAL_NG = 2</summary>
        public const int UserCalNg = 2;

        /// <summary>Original Delphi: CHECK_CA310_PROBE_NG = 3</summary>
        public const int ProbeNg = 3;
    }

    // =========================================================================
    // Log Type Constants
    // =========================================================================

    /// <summary>
    /// Log type constants.
    /// </summary>
    public static class LogType
    {
        /// <summary>Original Delphi: LOG_TYPE_OK = 0</summary>
        public const int Ok = 0;

        /// <summary>Original Delphi: LOG_TYPE_NG = 1</summary>
        public const int Ng = 1;

        /// <summary>Original Delphi: LOG_TYPE_INFO = 2</summary>
        public const int Info = 2;
    }

    // =========================================================================
    // Message Type Constants
    // =========================================================================

    /// <summary>
    /// Message type constants identifying the source/category of a message.
    /// Original Delphi: MSG_TYPE_*
    /// </summary>
    public static class MsgType
    {
        /// <summary>Original Delphi: MSG_TYPE_NONE = 0</summary>
        public const int None = 0;

        /// <summary>Original Delphi: MSG_TYPE_SCRIPT = 1</summary>
        public const int Script = 1;

        /// <summary>Original Delphi: MSG_TYPE_SWITCH = 2</summary>
        public const int Switch = 2;

        /// <summary>Original Delphi: MSG_TYPE_LOGIC = 3</summary>
        public const int Logic = 3;

        /// <summary>Original Delphi: MSG_TYPE_PG = 4</summary>
        public const int Pg = 4;

        /// <summary>Original Delphi: MSG_TYPE_JIG = 5</summary>
        public const int Jig = 5;

        /// <summary>Original Delphi: MSG_TYPE_STAGE = 6</summary>
        public const int Stage = 6;

        /// <summary>Original Delphi: MSG_TYPE_ADLINK = 7</summary>
        public const int Adlink = 7;

        /// <summary>Original Delphi: MSG_TYPE_IONIZER = 8</summary>
        public const int Ionizer = 8;

        /// <summary>Original Delphi: MSG_TYPE_HOST = 9</summary>
        public const int Host = 9;

        /// <summary>Original Delphi: MSG_TYPE_CAMERA = 10</summary>
        public const int Camera = 10;

        /// <summary>Original Delphi: MSG_TYPE_CAM_LIGHT = 11</summary>
        public const int CamLight = 11;

        /// <summary>Original Delphi: MSG_TYPE_FLOW_DATA_VIEW = 12</summary>
        public const int FlowDataView = 12;

        /// <summary>Original Delphi: MSG_TYPE_JNCD_SW = 13</summary>
        public const int JncdSw = 13;

        /// <summary>Original Delphi: MSG_TYPE_DFS = 14</summary>
        public const int Dfs = 14;

        /// <summary>Original Delphi: MSG_TYPE_CA410 = 15</summary>
        public const int Ca410 = 15;

        /// <summary>Original Delphi: MSG_TYPE_DLL = 16</summary>
        public const int Dll = 16;

        /// <summary>Original Delphi: MSG_TYPE_AF9FPGA = 17</summary>
        public const int Af9Fpga = 17;

        /// <summary>Original Delphi: MSG_TYPE_MAIN = 21</summary>
        public const int Main = 21;

        /// <summary>Original Delphi: MSG_TYPE_DAEIO = 101</summary>
        public const int DaeIo = 101;

        /// <summary>Original Delphi: MSG_TYPE_CTL_DIO = 102</summary>
        public const int CtlDio = 102;

        /// <summary>Original Delphi: MSG_TYPE_COMM_ECS = 103</summary>
        public const int CommEcs = 103;

        /// <summary>Original Delphi: MSG_TYPE_COMMTHERMOMETER = 104</summary>
        public const int CommThermometer = 104;

        /// <summary>Original Delphi: MSG_TYPE_EXT_CONTROL = 1001</summary>
        public const int ExtControl = 1001;
    }

    // =========================================================================
    // Message Mode Constants
    // =========================================================================

    /// <summary>
    /// Message mode constants used in GUI message passing.
    /// Original Delphi: MSG_MODE_*
    /// </summary>
    public static class MsgMode
    {
        /// <summary>Original Delphi: MSG_MODE_LOAD = 1</summary>
        public const int Load = 1;

        /// <summary>Original Delphi: MSG_MODE_CAL = 2</summary>
        public const int Cal = 2;

        /// <summary>Original Delphi: MSG_MODE_ADDLOG = 3</summary>
        public const int AddLog = 3;

        /// <summary>Original Delphi: MSG_MODE_ADDLOG_CHANNEL = 4</summary>
        public const int AddLogChannel = 4;

        /// <summary>Original Delphi: MSG_MODE_RESET_ALARM = 5</summary>
        public const int ResetAlarm = 5;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY = 6</summary>
        public const int Display = 6;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_CHANNEL = 0</summary>
        public const int DisplayChannel = 0;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_VOLCUR = 1</summary>
        public const int DisplayVolCur = 1;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_ALARM = 2</summary>
        public const int DisplayAlarm = 2;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_MODELINFO = 3</summary>
        public const int DisplayModelInfo = 3;

        /// <summary>Original Delphi: MSG_MODE_CONTINUETIMER_ENABLE = 4</summary>
        public const int ContinueTimerEnable = 4;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_RCBDATA = 5</summary>
        public const int DisplayRcbData = 5;

        /// <summary>Original Delphi: MSG_MODE_SWITCH_ONOFF = 7</summary>
        public const int SwitchOnOff = 7;

        /// <summary>Original Delphi: MSG_MODE_TEST_HOST = 8</summary>
        public const int TestHost = 8;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_FLOW = 9</summary>
        public const int DisplayFlow = 9;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_RESULT = 10</summary>
        public const int DisplayResult = 10;

        /// <summary>Original Delphi: MSG_MODE_CH_CLEAR = 11</summary>
        public const int ChClear = 11;

        /// <summary>Original Delphi: MSG_MODE_BARCODE_READY = 12</summary>
        public const int BarcodeReady = 12;

        /// <summary>Original Delphi: MSG_MODE_TACT_START = 13</summary>
        public const int TactStart = 13;

        /// <summary>Original Delphi: MSG_MODE_TACT_END = 14</summary>
        public const int TactEnd = 14;

        /// <summary>Original Delphi: MSG_MODE_FLOW_START = 15</summary>
        public const int FlowStart = 15;

        /// <summary>Original Delphi: MSG_MODE_FLOW_STOP = 16</summary>
        public const int FlowStop = 16;

        /// <summary>Original Delphi: MSG_MODE_POWER_ON = 17</summary>
        public const int PowerOn = 17;

        /// <summary>Original Delphi: MSG_MODE_POWER_OFF = 18</summary>
        public const int PowerOff = 18;

        /// <summary>Original Delphi: MSG_MODE_NG_CNT = 19</summary>
        public const int NgCount = 19;

        /// <summary>Original Delphi: MSG_MODE_BTN_ENABLE = 20</summary>
        public const int BtnEnable = 20;

        /// <summary>Original Delphi: MSG_MODE_BTN_DISABLE = 21</summary>
        public const int BtnDisable = 21;

        /// <summary>Original Delphi: MSG_MODE_MODEL_DOWN_START = 22</summary>
        public const int ModelDownStart = 22;

        /// <summary>Original Delphi: MSG_MODE_MODEL_DOWN_END = 23</summary>
        public const int ModelDownEnd = 23;

        /// <summary>Original Delphi: MSG_MODE_MODEL_DOWNLOADING = 24</summary>
        public const int ModelDownloading = 24;

        /// <summary>Original Delphi: MSG_MODE_FLOW_STOP_REPORT = 25</summary>
        public const int FlowStopReport = 25;

        /// <summary>Original Delphi: MSG_MODE_FLOW_DATA_VIEW = 26</summary>
        public const int FlowDataView = 26;

        /// <summary>Original Delphi: MSG_MODE_MAKE_SUMMARY_CSV = 27</summary>
        public const int MakeSummaryCsv = 27;

        /// <summary>Original Delphi: MSG_MODE_SEND_GMES = 28</summary>
        public const int SendGmes = 28;

        /// <summary>Original Delphi: MSG_MODE_SEND_RSTDONE = 29</summary>
        public const int SendRstDone = 29;

        /// <summary>Original Delphi: MSG_MODE_WORK_DONE = 30</summary>
        public const int WorkDone = 30;

        /// <summary>Original Delphi: MSG_MODE_WORKING = 31</summary>
        public const int Working = 31;

        /// <summary>Original Delphi: MSG_MODE_LOG_PWR = 32</summary>
        public const int LogPwr = 32;

        /// <summary>Original Delphi: MSG_MODE_LOG_CSV = 33</summary>
        public const int LogCsv = 33;

        /// <summary>Original Delphi: MSG_MODE_LOG_REPGM = 34</summary>
        public const int LogRepgm = 34;

        /// <summary>Original Delphi: MSG_MODE_LOG_ON_GUI = 35</summary>
        public const int LogOnGui = 35;

        /// <summary>Original Delphi: MSG_MODE_DISPLAY_CONNECTION = 36</summary>
        public const int DisplayConnection = 36;

        /// <summary>Original Delphi: MSG_MODE_TRANS_DOWNLOAD_STATUS = 37</summary>
        public const int TransDownloadStatus = 37;

        /// <summary>Original Delphi: MSG_MODE_UNIT_TT_START = 38</summary>
        public const int UnitTtStart = 38;

        /// <summary>Original Delphi: MSG_MODE_UNIT_TT_END = 39</summary>
        public const int UnitTtEnd = 39;

        /// <summary>Original Delphi: MSG_MODE_SHOW_SERIAL_NUMBER = 40</summary>
        public const int ShowSerialNumber = 40;

        /// <summary>Original Delphi: MSG_MODE_HOST_RESULT = 41</summary>
        public const int HostResult = 41;

        /// <summary>Original Delphi: MSG_MODE_PAT_DISPLAY = 42</summary>
        public const int PatDisplay = 42;

        /// <summary>Original Delphi: MSG_MODE_CH_RESULT = 43</summary>
        public const int ChResult = 43;

        /// <summary>Original Delphi: MSG_MODE_CA310_STATUS = 44</summary>
        public const int Ca310Status = 44;

        /// <summary>Original Delphi: MSG_MODE_CA310_NG = 45</summary>
        public const int Ca310Ng = 45;

        /// <summary>Original Delphi: MSG_MODE_DIO_SEN_NG = 46</summary>
        public const int DioSenNg = 46;

        /// <summary>Original Delphi: MSG_MODE_DIFF_MODEL = 47</summary>
        public const int DiffModel = 47;

        /// <summary>Original Delphi: MSG_MODE_CA310_MEASURE = 48</summary>
        public const int Ca310Measure = 48;

        /// <summary>Original Delphi: MSG_MODE_DIO_CONTROL = 49</summary>
        public const int DioControl = 49;

        /// <summary>Original Delphi: MSG_MODE_TOUCH_INFO = 50</summary>
        public const int TouchInfo = 50;

        /// <summary>Original Delphi: MSG_MODE_TOUCH_RESULT = 51</summary>
        public const int TouchResult = 51;

        /// <summary>Original Delphi: MSG_MODE_SYNC_WORK = 52</summary>
        public const int SyncWork = 52;

        /// <summary>Original Delphi: MSG_MODE_FOR_RTY_MAKE_ALL_NG = 53</summary>
        public const int ForRtyMakeAllNg = 53;

        /// <summary>Original Delphi: MSG_MODE_PRODUCT_CNT = 54</summary>
        public const int ProductCount = 54;

        /// <summary>Original Delphi: MSG_MODE_CA310_ERROR_MSG = 55</summary>
        public const int Ca310ErrorMsg = 55;

        /// <summary>Original Delphi: MSG_MODE_ANGING_TIME = 57</summary>
        public const int AgingTime = 57;

        /// <summary>Original Delphi: MSG_MODE_PASS_RGB = 60</summary>
        public const int PassRgb = 60;

        /// <summary>Original Delphi: MSG_MODE_GET_AVG_RGB = 61</summary>
        public const int GetAvgRgb = 61;

        /// <summary>Original Delphi: MSG_MODE_SET_SCRIPT_NG = 62</summary>
        public const int SetScriptNg = 62;

        /// <summary>Original Delphi: MSG_MODE_FW_CHECK = 63</summary>
        public const int FwCheck = 63;

        /// <summary>Original Delphi: MSG_MODE_LOG_CSV_SUMMARY = 64</summary>
        public const int LogCsvSummary = 64;

        /// <summary>Original Delphi: MSG_MODE_LOG_CSV_APDR = 65</summary>
        public const int LogCsvApdr = 65;

        /// <summary>Original Delphi: MSG_MODE_CAX10_MEM_CH_NO = 66</summary>
        public const int Cax10MemChNo = 66;

        /// <summary>Original Delphi: MSG_MODE_SHOW_CONFIRM_EICR = 67</summary>
        public const int ShowConfirmEicr = 67;

        /// <summary>Original Delphi: MSG_MODE_LOG_HWCID = 68</summary>
        public const int LogHwcid = 68;

        /// <summary>Original Delphi: MSG_MODE_VIRTUAL_CAPTION = 68 (same value as LogHwcid)</summary>
        public const int VirtualCaption = 68;

        /// <summary>Original Delphi: MSG_MODE_DELAY_TIME = 69</summary>
        public const int DelayTime = 69;

        /// <summary>Original Delphi: MSG_MODE_IRTEMP = 70</summary>
        public const int IrTemp = 70;

        /// <summary>Original Delphi: MSG_MODE_IONIZER = 71</summary>
        public const int Ionizer = 71;
    }

    // =========================================================================
    // Power Constants
    // =========================================================================

    /// <summary>
    /// Power supply index constants.
    /// Original Delphi: PWR_*
    /// </summary>
    public static class PowerIndex
    {
        /// <summary>Original Delphi: PWR_VCI = 0</summary>
        public const int Vci = 0;

        /// <summary>Original Delphi: PWR_DVDD = 1</summary>
        public const int Dvdd = 1;

        /// <summary>Original Delphi: PWR_VDD = 2</summary>
        public const int Vdd = 2;

        /// <summary>Original Delphi: PWR_VPP = 3</summary>
        public const int Vpp = 3;

        /// <summary>Original Delphi: PWR_VBAT = 4</summary>
        public const int Vbat = 4;

        /// <summary>Original Delphi: PWR_VNEG = 5</summary>
        public const int Vneg = 5;

        /// <summary>Original Delphi: PWR_RESET = 6</summary>
        public const int Reset = 6;
    }

    /// <summary>
    /// EL power supply index constants.
    /// Original Delphi: PWR_ELVDD, PWR_ELVSS, PWR_DDVDH
    /// </summary>
    public static class ElPowerIndex
    {
        /// <summary>Original Delphi: PWR_ELVDD = 0</summary>
        public const int Elvdd = 0;

        /// <summary>Original Delphi: PWR_ELVSS = 1</summary>
        public const int Elvss = 1;

        /// <summary>Original Delphi: PWR_DDVDH = 2</summary>
        public const int Ddvdh = 2;
    }

    // =========================================================================
    // Encryption Constants
    // =========================================================================

    /// <summary>
    /// Encryption key constants and hex character lookup.
    /// </summary>
    public static class EncryptionConstants
    {
        /// <summary>Original Delphi: C1 = 74054</summary>
        public const int C1 = 74054;

        /// <summary>Original Delphi: C2 = 12337</summary>
        public const int C2 = 12337;

        /// <summary>Original Delphi: HexaChar : array[0..15] of Char</summary>
        public static readonly char[] HexaChar =
        {
            '0', '1', '2', '3', '4', '5', '6', '7',
            '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
        };
    }

    // =========================================================================
    // PG Connection Constants
    // =========================================================================

    /// <summary>
    /// PG connection status constants.
    /// </summary>
    public static class PgConnection
    {
        /// <summary>Original Delphi: PG_CONN_DISCONNECTED = 0</summary>
        public const int Disconnected = 0;

        /// <summary>Original Delphi: PG_CONN_CONNECTED = 2</summary>
        public const int Connected = 2;

        /// <summary>Original Delphi: PG_CONN_VERSION = 3</summary>
        public const int Version = 3;

        /// <summary>Original Delphi: PG_CONN_READY = 4</summary>
        public const int Ready = 4;
    }

    // =========================================================================
    // Download Type Constants
    // =========================================================================

    /// <summary>
    /// Download type tab control indices.
    /// Original Delphi: DOWNLOAD_TYPE_*
    /// </summary>
    public static class DownloadType
    {
        /// <summary>Original Delphi: DOWNLOAD_TYPE_BMP = 0</summary>
        public const int Bmp = 0;

        /// <summary>Original Delphi: DOWNLOAD_TYPE_PRG = 1</summary>
        public const int Prg = 1;

        /// <summary>Original Delphi: DOWNLOAD_TYPE_PG_FPGA = 2</summary>
        public const int PgFpga = 2;

        /// <summary>Original Delphi: DOWNLOAD_TYPE_PG_FW = 3</summary>
        public const int PgFw = 3;

        /// <summary>Original Delphi: DOWNLOAD_TYPE_PALLET_FPGA = 4</summary>
        public const int PalletFpga = 4;

        /// <summary>Original Delphi: DOWNLOAD_TYPE_PALLET_FW = 5</summary>
        public const int PalletFw = 5;

        /// <summary>Original Delphi: DOWNLOAD_TYPE_TOUCH_FW = 6</summary>
        public const int TouchFw = 6;

        /// <summary>Original Delphi: DOWNLOAD_TYPE_PANEL_FW_hex = 7</summary>
        public const int PanelFwHex = 7;
    }

    // =========================================================================
    // Path Index Constants
    // =========================================================================

    /// <summary>
    /// Path index constants for model/pattern/script file paths.
    /// </summary>
    public static class PathIndex
    {
        /// <summary>Original Delphi: MODEL_PATH = 0</summary>
        public const int Model = 0;

        /// <summary>Original Delphi: PATRN_PATH = 1</summary>
        public const int Pattern = 1;

        /// <summary>Original Delphi: PATGR_PATH = 2</summary>
        public const int PatternGroup = 2;

        /// <summary>Original Delphi: SCRIPT_PATH_ISU = 3</summary>
        public const int ScriptIsu = 3;

        /// <summary>Original Delphi: SCRIPT_PATH_PSU = 4</summary>
        public const int ScriptPsu = 4;

        /// <summary>C# Roslyn script (.csx)</summary>
        public const int ScriptCsx = 5;
    }

    // =========================================================================
    // Pattern Type Constants
    // =========================================================================

    /// <summary>
    /// Pattern type constants.
    /// </summary>
    public static class PatternType
    {
        /// <summary>Original Delphi: PTYPE_NORMAL = 0 (Normal pattern)</summary>
        public const int Normal = 0;

        /// <summary>Original Delphi: PTYPE_BITMAP = 1 (BMP)</summary>
        public const int Bitmap = 1;

        /// <summary>Original Delphi: PTYPE_NONE = $ff (Initial/unset)</summary>
        public const int None = 0xFF;
    }

    // =========================================================================
    // CRC Constants
    // =========================================================================

    /// <summary>
    /// CRC polynomial constant.
    /// </summary>
    public static class CrcConstants
    {
        /// <summary>Original Delphi: CRC16POLY = $8408</summary>
        public const int Crc16Poly = 0x8408;
    }

    // =========================================================================
    // UI Theme Constants
    // =========================================================================

    /// <summary>
    /// UI theme constants for Windows 10.
    /// </summary>
    public static class UiTheme
    {
        /// <summary>Original Delphi: UI_WIN10_NOR = 0</summary>
        public const int Win10Normal = 0;

        /// <summary>Original Delphi: UI_WIN10_BLACK = 1</summary>
        public const int Win10Black = 1;
    }

    // =========================================================================
    // Stage Step Constants
    // =========================================================================

    /// <summary>
    /// Stage work step constants.
    /// Original Delphi: STAGE_STEP_*
    /// </summary>
    public static class StageStep
    {
        /// <summary>Original Delphi: STAGE_STEP_NONE = 0</summary>
        public const int None = 0;

        /// <summary>Original Delphi: STAGE_STEP_LOADING = STAGE_STEP_NONE + 1</summary>
        public const int Loading = None + 1;

        /// <summary>Original Delphi: STAGE_STEP_LOADING_FINISH = STAGE_STEP_NONE + 2</summary>
        public const int LoadingFinish = None + 2;

        /// <summary>Original Delphi: STAGE_STEP_LOADZONE = STAGE_STEP_NONE + 3</summary>
        public const int LoadZone = None + 3;

        /// <summary>Original Delphi: STAGE_STEP_LOADZONE_FINISH = STAGE_STEP_NONE + 4</summary>
        public const int LoadZoneFinish = None + 4;

        /// <summary>Original Delphi: STAGE_STEP_TURNING_CAM = STAGE_STEP_NONE + 5</summary>
        public const int TurningCam = None + 5;

        /// <summary>Original Delphi: STAGE_STEP_CAMZONE = STAGE_STEP_NONE + 6</summary>
        public const int CamZone = None + 6;

        /// <summary>Original Delphi: STAGE_STEP_CAMZONE_FINISH = STAGE_STEP_NONE + 7</summary>
        public const int CamZoneFinish = None + 7;

        /// <summary>Original Delphi: STAGE_STEP_TURNING_UNLOAD = STAGE_STEP_NONE + 8</summary>
        public const int TurningUnload = None + 8;

        /// <summary>Original Delphi: STAGE_STEP_UNLOADZONE = STAGE_STEP_NONE + 9</summary>
        public const int UnloadZone = None + 9;

        /// <summary>Original Delphi: STAGE_STEP_UNLOADZONE_FINISH = STAGE_STEP_NONE + 10</summary>
        public const int UnloadZoneFinish = None + 10;

        /// <summary>Original Delphi: STAGE_STEP_UNLOADING = STAGE_STEP_NONE + 11</summary>
        public const int Unloading = None + 11;

        /// <summary>Original Delphi: STAGE_STEP_EXCHANGE = STAGE_STEP_NONE + 12</summary>
        public const int Exchange = None + 12;

        /// <summary>Original Delphi: STAGE_STEP_OTHER_SCRIPT_RUN = STAGE_STEP_NONE + 13</summary>
        public const int OtherScriptRun = None + 13;

        /// <summary>Original Delphi: STAGE_STEP_OTHER_SCRIPT_FINISH = STAGE_STEP_NONE + 14</summary>
        public const int OtherScriptFinish = None + 14;
    }

    // =========================================================================
    // Debug Log Constants
    // =========================================================================

    /// <summary>
    /// Debug log message type constants.
    /// Original Delphi: DEBUG_LOG_MSGTYPE_*
    /// </summary>
    public static class DebugLogMsgType
    {
        /// <summary>Original Delphi: DEBUG_LOG_MSGTYPE_INSPECT = 1</summary>
        public const int Inspect = 1;

        /// <summary>Original Delphi: DEBUG_LOG_MSGTYPE_CONNCHECK = 2</summary>
        public const int ConnCheck = 2;

        /// <summary>Original Delphi: DEBUG_LOG_MSGTYPE_DOWNDATA = 3</summary>
        public const int DownData = 3;

        /// <summary>Original Delphi: DEBUG_LOG_MSGTYPE_MAX = DEBUG_LOG_MSGTYPE_DOWNDATA</summary>
        public const int Max = DownData;
    }

    /// <summary>
    /// Debug log level constants.
    /// Original Delphi: DEBUG_LOG_LEVEL_*
    /// </summary>
    public static class DebugLogLevel
    {
        /// <summary>Original Delphi: DEBUG_LOG_LEVEL_CONFIG_INI = -1 (set to SystemConfig.DEBUG)</summary>
        public const int ConfigIni = -1;

        /// <summary>Original Delphi: DEBUG_LOG_LEVEL_NONE = 0 (None)</summary>
        public const int None = 0;

        /// <summary>Original Delphi: DEBUG_LOG_LEVEL_INSPECT = 1 (INSPECT/POWERCHECK)</summary>
        public const int Inspect = 1;

        /// <summary>Original Delphi: DEBUG_LOG_LEVEL_INSPECT_CONNCHECK = 2 (INSPECT/POWERCHECK + CONNCHECK)</summary>
        public const int InspectConnCheck = 2;

        /// <summary>Original Delphi: DEBUG_LOG_LEVEL_DOWNDATA = 3 (N/A)</summary>
        public const int DownData = 3;

        /// <summary>Original Delphi: DEBUG_LOG_LEVEL_MAX = DEBUG_LOG_MSGTYPE_DOWNDATA</summary>
        public const int Max = DebugLogMsgType.DownData;
    }

    // =========================================================================
    // TGUIMessage - GUI Message for WM_COPYDATA
    // =========================================================================

    /// <summary>
    /// GUI Message class for inter-process communication (originally WM_COPYDATA).
    /// <para>Original Delphi: TGUIMessage = packed record</para>
    /// <para>Contains managed string type, so converted to a class rather than struct.</para>
    /// </summary>
    public class GuiMessage
    {
        /// <summary>
        /// Message type identifier.
        /// <para>Original Delphi field: MsgType : Integer</para>
        /// </summary>
        public int MsgType { get; set; }

        /// <summary>
        /// Channel number.
        /// <para>Original Delphi field: Channel : Integer</para>
        /// </summary>
        public int Channel { get; set; }

        /// <summary>
        /// Message mode.
        /// <para>Original Delphi field: Mode : Integer</para>
        /// </summary>
        public int Mode { get; set; }

        /// <summary>
        /// First parameter.
        /// <para>Original Delphi field: Param : Integer</para>
        /// </summary>
        public int Param { get; set; }

        /// <summary>
        /// Second parameter (also used as data length for Data).
        /// <para>Original Delphi field: Param2 : Integer</para>
        /// </summary>
        public int Param2 { get; set; }

        /// <summary>
        /// Message text.
        /// <para>Original Delphi field: Msg : string</para>
        /// </summary>
        public string Msg { get; set; } = string.Empty;

        /// <summary>
        /// Optional raw byte data. Length indicated by <see cref="Param2"/>.
        /// <para>Original Delphi field: pData : PBYTE</para>
        /// </summary>
        public byte[]? Data { get; set; }
    }

    // =========================================================================
    // DefCommon — Bridge class for driver compatibility
    // =========================================================================

    /// <summary>
    /// Convenience facade that maps Delphi-style <c>DefCommon.XXX</c> references
    /// to the correct static-class constants defined elsewhere in this namespace.
    /// Driver code ported from Delphi uses <c>DefCommon.MsgModeDisplayConnection</c>
    /// style references; this class provides those as forwarding constants so the
    /// driver code compiles without modification.
    /// </summary>
    public static class DefCommon
    {
        // ---- MsgMode aliases ----

        /// <summary>Alias for <see cref="MsgMode.DisplayConnection"/>.</summary>
        public const int MsgModeDisplayConnection = MsgMode.DisplayConnection;

        /// <summary>Alias for <see cref="MsgMode.DisplayVolCur"/>.</summary>
        public const int MsgModeDisplayVolCur = MsgMode.DisplayVolCur;

        /// <summary>Alias for <see cref="MsgMode.Working"/>.</summary>
        public const int MsgModeWorking = MsgMode.Working;

        /// <summary>Alias for <see cref="MsgMode.DisplayAlarm"/>.</summary>
        public const int MsgModeDisplayAlarm = MsgMode.DisplayAlarm;

        /// <summary>Alias for <see cref="MsgMode.DisplayChannel"/>.</summary>
        public const int MsgModeDisplayChannel = MsgMode.DisplayChannel;

        /// <summary>Alias for <see cref="MsgMode.AddLog"/>.</summary>
        public const int MsgModeAddLog = MsgMode.AddLog;

        /// <summary>Alias for <see cref="MsgMode.AddLogChannel"/>.</summary>
        public const int MsgModeAddLogChannel = MsgMode.AddLogChannel;

        // ---- PgConnection aliases ----

        /// <summary>Alias for <see cref="PgConnection.Disconnected"/>.</summary>
        public const int PgConnDisconnected = PgConnection.Disconnected;

        /// <summary>Alias for <see cref="PgConnection.Connected"/>.</summary>
        public const int PgConnConnected = PgConnection.Connected;

        /// <summary>Alias for <see cref="PgConnection.Version"/>.</summary>
        public const int PgConnVersion = PgConnection.Version;

        /// <summary>Alias for <see cref="PgConnection.Ready"/>.</summary>
        public const int PgConnReady = PgConnection.Ready;

        // ---- LogType aliases ----

        /// <summary>Alias for <see cref="LogType.Ok"/>.</summary>
        public const int LogTypeOk = LogType.Ok;

        /// <summary>Alias for <see cref="LogType.Ng"/>.</summary>
        public const int LogTypeNg = LogType.Ng;

        /// <summary>Alias for <see cref="LogType.Info"/>.</summary>
        public const int LogTypeInfo = LogType.Info;
    }
}
