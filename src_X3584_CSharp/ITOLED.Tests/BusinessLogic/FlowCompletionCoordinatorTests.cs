using Dongaeltek.ITOLED.BusinessLogic.Inspection;
using Dongaeltek.ITOLED.BusinessLogic.Dll;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Models;
using Dongaeltek.ITOLED.Messaging;
using Dongaeltek.ITOLED.Messaging.Messages;
using ITOLED.Tests.Plc;

namespace ITOLED.Tests.BusinessLogic;

public class FlowCompletionCoordinatorTests : IDisposable
{
    private readonly MessageBus _bus = new();
    private readonly StubDllManager _dll = new();
    private readonly StubScriptRunner[] _scripts;
    private readonly StubConfigService _config = new();
    private readonly FlowCompletionCoordinator _coordinator;

    public FlowCompletionCoordinatorTests()
    {
        _scripts = [new(), new(), new(), new()];
        foreach (var s in _scripts) s.IsInUse = true;
        _coordinator = new FlowCompletionCoordinator(
            _bus, _dll, _scripts, _config,
            new NullLogger());
    }

    public void Dispose() => _coordinator.Dispose();

    [Fact]
    public void WorkDone_InlineGIB_TriggersFinishImmediately()
    {
        _config.PlcInfoValue.InlineGIB = true;
        _dll.SetProcessDone(0, true);

        _bus.Publish(new DllEventMessage { Channel = 0, Mode = MsgMode.WorkDone, Param = 0 });

        Assert.Contains(DefScript.SeqFinish, _scripts[0].SequencesRun);
    }

    [Fact]
    public void WorkDone_PairMode_WaitsForBothChannels()
    {
        _config.PlcInfoValue.InlineGIB = false;
        _dll.SetProcessDone(0, true);
        // CH1 not done yet

        _bus.Publish(new DllEventMessage { Channel = 0, Mode = MsgMode.WorkDone, Param = 0 });

        // CH0 done but CH1 not -> no finish yet
        Assert.DoesNotContain(DefScript.SeqFinish, _scripts[0].SequencesRun);
    }

    [Fact]
    public void WorkDone_PairMode_BothDone_TriggersFinish()
    {
        _config.PlcInfoValue.InlineGIB = false;
        _dll.SetProcessDone(0, true);
        _dll.SetProcessDone(1, true);

        _bus.Publish(new DllEventMessage { Channel = 0, Mode = MsgMode.WorkDone, Param = 0 });

        Assert.Contains(DefScript.SeqFinish, _scripts[0].SequencesRun);
        Assert.Contains(DefScript.SeqFinish, _scripts[1].SequencesRun);
    }

    [Fact]
    public void WorkDone_InvalidChannel_NoException()
    {
        _bus.Publish(new DllEventMessage { Channel = -1, Mode = MsgMode.WorkDone });
        _bus.Publish(new DllEventMessage { Channel = 99, Mode = MsgMode.WorkDone });
        // Should not throw
    }

    // ---- Stub implementations ----

    private class StubDllManager : IDllManager
    {
        private readonly bool[] _processDone = new bool[4];
        private readonly bool[] _processUnloadDone = new bool[4];

        public string NgMessage => "";
        public bool IsLoaded => true;
        public string LgdDllName => "";
        public string OcConDllName => "";
        public string OcConverterVersion => "";
        public bool IsFlowRunning(int channel) => false;
        public bool IsDllWorking(int channel) => false;
        public bool IsProcessDone(int channel) => channel >= 0 && channel < 4 && _processDone[channel];
        public bool IsProcessUnloadDone(int channel) => channel >= 0 && channel < 4 && _processUnloadDone[channel];
        public int GetCurrentBand(int channel) => 0;
        public int GetPreActionNg(int channel) => 0;
        public void SetPreActionNg(int channel, int value) { }
        public bool GetSerialNumberCheckFlag(int channel) => false;
        public void SetSerialNumberCheckFlag(int channel, bool value) { }
        public void SetDllWorking(int channel, bool value) { }
        public void SetProcessDone(int channel, bool value) { if (channel >= 0 && channel < 4) _processDone[channel] = value; }
        public void SetProcessUnloadDone(int channel, bool value) { if (channel >= 0 && channel < 4) _processUnloadDone[channel] = value; }
        public void Initialize(string modelName) { }
        public void FormDestroy() { }
        public int StartOcFlow(int dllType, int channel, string pid, string serialNumber, string userId, string equipment) => 0;
        public int StopOcFlow(int channel) => 0;
        public bool WaitForFlowComplete(int channel, int timeoutMs = 10000) => true;
        public int StartVerify(int channel) => 0;
        public int CheckThreadState(int channel) => 0;
        public int FlashRead(int channel) => 0;
        public int GetOcFlowIsAlive(int channel) => 0;
        public string GetSummaryLogData(int channel, string parameter) => "";
        public string GetSummaryLogDictionary(int channel) => "";
        public int ChangeDll(string dllName) => 0;
        public void AddDllLog(int channel, bool clear, string message) { }
        public void Dispose() { }
    }

    private class StubScriptRunner : IScriptRunner
    {
        public bool IsInUse { get; set; } = true;
        public bool FirstProcessDone { get; set; }
        public bool CelStop { get; set; }
        public bool IsSyncSequence { get; set; }
        public int ConfirmHostReturn { get; set; }
        public bool IsProbeBackSignal { get; set; }
        public ScriptTestInfo TestInfo { get; } = new();
        public List<int> SequencesRun { get; } = [];

        public void LoadSource(IEnumerable<string> scriptSource) { }
        public void InitialScript() { }
        public int RunSequence(int sequenceKeyIndex) { SequencesRun.Add(sequenceKeyIndex); return 0; }
        public bool IsSequenceRunning(int sequenceKeyIndex) => false;
        public bool IsScriptRunning() => false;
        public void SetHostEvent(int returnValue) { }
        public void RefreshHandles() { }
        public string? ExecuteAutoStart() => null;
        public bool ExecuteRobotLoad() => true;
        public bool ExecuteRobotUnload() => true;
        public void Dispose() { }
    }

    private class StubConfigService : IConfigurationService
    {
        public PLCInfo PlcInfoValue { get; } = new();
        public AppConfiguration AppConfig => new();
        public SystemInfo SystemInfo => new();
        public PLCInfo PlcInfo => PlcInfoValue;
        public SimulateInfo SimulateInfo => new();
        public InterlockInfo InterlockInfo => new();
        public OnLineInterlockInfo OnlineInterlockInfo => new();
        public DfsConfInfo DfsConfInfo => new();
        public OcInfo OcInfo => new();
        public IReadOnlyList<GmesCode> GmesInfo => [];
        public int GmesInfoCount => 0;
        public int ReadGmesCsvFile() => 0;
        public string GetString(string section, string key, string defaultValue = "") => defaultValue;
        public int GetInt(string section, string key, int defaultValue = 0) => defaultValue;
        public bool GetBool(string section, string key, bool defaultValue = false) => defaultValue;
        public double GetDouble(string section, string key, double defaultValue = 0) => defaultValue;
        public void SetString(string section, string key, string value) { }
        public void SetInt(string section, string key, int value) { }
        public void SetBool(string section, string key, bool value) { }
        public void ReadSystemInfo() { }
        public void SaveSystemInfo() { }
        public bool ReadPgSettingInfo() => false;
        public bool ReadSwVersion() => false;
        public bool ReadDllSettings() => false;
        public void ReadOcInfo() { }
        public void SaveOcInfo(int modelType) { }
        public void UpdateSystemInfoRuntime() { }
        public void SaveLocalIpToSys(int index) { }
        public void SaveSystemInfoFwVersion(int channel, string data) { }
        public void SaveSystemInfoCa410Memory(int channel, string data) { }
        public void Save() { }
        public void Reload() { }
    }
}
