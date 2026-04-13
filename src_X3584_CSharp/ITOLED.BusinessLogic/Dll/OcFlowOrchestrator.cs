// =============================================================================
// OcFlowOrchestrator.cs
// Replaces CallTestClass from OC_Converter_X3584.dll.
//
// Loads Factory DLLs (LGD_OC_X3584.dll, etc.) via FactoryAssemblyLoadContext,
// creates CompensationFlow instances via reflection, and manages their lifecycle.
//
// The ICompensationFlow interface (from LGD_OC_AstractPlatForm, Default ALC)
// is shared across all Factory ALCs, ensuring type identity for casts.
// =============================================================================

using System.Reflection;
using System.Runtime.InteropServices;
using System.Text.Json;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using LGD_OC_AstractPlatForm;

namespace Dongaeltek.ITOLED.BusinessLogic.Dll;

/// <summary>
/// Manages CompensationFlow lifecycle: load Factory DLLs, create flows via
/// reflection, run them on background threads, and query results via
/// <see cref="ICompensationFlow"/>.
/// </summary>
public sealed class OcFlowOrchestrator : IDisposable
{
    private readonly ILogger _logger;

    // factoryId → (ALC, loaded Assembly, config)
    private readonly Dictionary<int, (FactoryAssemblyLoadContext Alc, Assembly Asm, OcFactoryConfig Config)>
        _loadedFactories = new();

    // (dllType, channel) → flow instance
    private readonly Dictionary<(int type, int ch), ICompensationFlow> _flows = new();

    // (dllType, channel) → flow thread
    private readonly Dictionary<(int type, int ch), Thread> _threads = new();

    // (dllType, channel) → run MethodInfo (cached after first discovery)
    private readonly Dictionary<int, MethodInfo?> _runMethods = new();

    // Per-channel: HardwareBridge instances
    private HardwareBridge[]? _bridges;

    // Per-channel: hidden RichTextBox (required by X2146_API base constructor)
    private System.Windows.Forms.RichTextBox[]? _richTextBoxes;

    // Per-channel: OcMeasurementBridge instances
    private OcMeasurementBridge[]? _measurements;

    private string _lgdDllDir = "";
    private string _modelName = "";
    private int _channelCount;
    private List<OcFactoryConfig> _configs = new();
    private bool _disposed;

    // STA message pump for RichTextBox controls (required by Factory DLL's Invoke/BeginInvoke)
    private Action<int, string>? _logCallback;
    private Thread? _rtbPumpThread;
    private System.Windows.Forms.ApplicationContext? _rtbAppContext;
    private int[]? _rtbPreviousLength;

    // GC pinning — LGD DLL (.NET Framework 4.8 CLR) 이 delegate/객체 포인터를 내부 캐시하므로
    // GC가 이동/수집하면 dangling pointer → Access Violation 크래시 발생.
    // GCHandle.Alloc(Normal)로 GC root를 유지하여 수집 방지.
    private readonly List<GCHandle> _gcRoots = new();
    private EventHandler[]? _textChangedHandlers;

    public OcFlowOrchestrator(ILogger logger)
    {
        _logger = logger;
    }

    // =========================================================================
    // Initialize
    // =========================================================================

    /// <summary>
    /// Initializes the orchestrator: creates per-channel hardware bridges and
    /// loads Factory DLLs via custom ALC.
    /// </summary>
    public void Initialize(
        string lgdDllDir,
        int channelCount,
        string modelName,
        List<OcFactoryConfig> configs,
        ICommPgDriver[] pgs,
        ICaSdk2Driver caSdk2,
        Action<int, string> logCallback)
    {
        _lgdDllDir = lgdDllDir;
        _channelCount = channelCount;
        _modelName = modelName;
        _configs = configs;
        _logCallback = logCallback;
        // GC root로 고정 — LGD DLL이 delegate 포인터를 내부 캐시하므로 GC 이동/수집 방지
        _gcRoots.Add(GCHandle.Alloc(logCallback));

        var afmLock = new object();
        _bridges = new HardwareBridge[channelCount];
        _richTextBoxes = new System.Windows.Forms.RichTextBox[channelCount];
        _measurements = new OcMeasurementBridge[channelCount];
        _rtbPreviousLength = new int[channelCount];
        _textChangedHandlers = new EventHandler[channelCount];

        // 1. Create RichTextBoxes on a dedicated STA thread with Win32 message pump.
        //    The Factory DLL (CompensationFlow) writes progress logs to these controls
        //    via X2146_API base class using Invoke/BeginInvoke, which requires a
        //    message loop on the owning thread. TextChanged events capture the new
        //    text and forward it to the per-channel log display.
        var rtbReady = new ManualResetEventSlim(false);
        _rtbPumpThread = new Thread(() =>
        {
            try
            {
                for (int i = 0; i < channelCount; i++)
                {
                    int ch = i; // capture for closure
                    var rtb = new System.Windows.Forms.RichTextBox { Visible = false };
                    _ = rtb.Handle; // force HWND creation on this STA thread

                    // TextChanged 핸들러를 필드에 보관 → GC 수집 방지
                    _textChangedHandlers![ch] = (_, _) =>
                    {
                        try
                        {
                            var currentText = rtb.Text;
                            var prevLen = _rtbPreviousLength![ch];

                            if (currentText.Length > prevLen)
                            {
                                var newText = currentText.Substring(prevLen);
                                _rtbPreviousLength[ch] = currentText.Length;

                                // Forward each new line to the log callback
                                var lines = newText.Split(new[] { "\r\n", "\n" },
                                    StringSplitOptions.RemoveEmptyEntries);
                                foreach (var line in lines)
                                {
                                    var trimmed = line.TrimEnd();
                                    if (!string.IsNullOrEmpty(trimmed))
                                        _logCallback?.Invoke(ch, trimmed);
                                }
                            }
                            else if (currentText.Length < prevLen)
                            {
                                // Text was cleared/reset by DLL — track from new position
                                _rtbPreviousLength[ch] = currentText.Length;
                            }
                        }
                        catch { /* must not crash the message pump */ }
                    };
                    rtb.TextChanged += _textChangedHandlers[ch];

                    _richTextBoxes![i] = rtb;
                }

                rtbReady.Set();
                _rtbAppContext = new System.Windows.Forms.ApplicationContext();
                System.Windows.Forms.Application.Run(_rtbAppContext);
            }
            catch
            {
                rtbReady.Set(); // unblock caller even on failure
            }
        });
        _rtbPumpThread.SetApartmentState(ApartmentState.STA);
        _rtbPumpThread.IsBackground = true;
        _rtbPumpThread.Name = "OcFlowRtbPump";
        _rtbPumpThread.Start();

        if (!rtbReady.Wait(10_000))
            _logger.Warn("RichTextBox STA thread initialization timed out");
        rtbReady.Dispose();

        // 2. Per-channel: MeasurementBridge + HardwareBridge (uses RTBs from STA thread)
        //    GCHandle로 고정 — LGD DLL이 X2146_API 파생 객체를 내부 참조하므로 GC 이동 방지
        for (int ch = 0; ch < channelCount; ch++)
        {
            _measurements[ch] = new OcMeasurementBridge(ch, caSdk2, afmLock, logCallback);
            _bridges[ch] = new HardwareBridge(
                _richTextBoxes[ch], _measurements[ch],
                ch < pgs.Length ? pgs[ch] : pgs[0],
                ch, logCallback);
            _gcRoots.Add(GCHandle.Alloc(_bridges[ch]));
            _gcRoots.Add(GCHandle.Alloc(_measurements[ch]));
            _gcRoots.Add(GCHandle.Alloc(_richTextBoxes[ch]));
        }

        // 2. Per-config: load Factory DLL via custom ALC
        foreach (var config in configs)
        {
            if (_loadedFactories.ContainsKey(config.Id))
                continue;

            try
            {
                // Resolve full path relative to root (parent of LGDDLL)
                var fullPath = Path.GetFullPath(Path.Combine(lgdDllDir, "..", config.DllPath));
                if (!File.Exists(fullPath))
                {
                    _logger.Warn($"Factory DLL not found: {fullPath} (config Id={config.Id})");
                    continue;
                }

                var dllDir = Path.GetDirectoryName(fullPath)!;
                var alc = new FactoryAssemblyLoadContext($"Factory_{config.Id}", dllDir);
                var asm = alc.LoadFromAssemblyPath(fullPath);
                _loadedFactories[config.Id] = (alc, asm, config);

                _logger.Info($"Loaded Factory DLL Id={config.Id}: {fullPath}");
            }
            catch (Exception ex)
            {
                _logger.Error($"Failed to load Factory DLL Id={config.Id}: {config.DllPath}", ex);
            }
        }
    }

    // =========================================================================
    // Flow Control
    // =========================================================================

    /// <summary>
    /// Creates a CompensationFlow instance via reflection and starts it on a
    /// background thread.
    /// </summary>
    /// <returns>0 = success, 2 = error.</returns>
    public int StartFlow(int dllType, int channel, string parameter, int paramLength, ushort checkSum)
    {
        if (_bridges == null || channel < 0 || channel >= _channelCount)
            return 2;

        if (!_loadedFactories.TryGetValue(dllType, out var factory))
        {
            _logger.Error($"StartFlow: Factory DLL not loaded for dllType={dllType}");
            return 2;
        }

        try
        {
            var config = factory.Config;
            var flowType = factory.Asm.GetType(config.ClassName);
            if (flowType == null)
            {
                _logger.Error($"StartFlow: Type {config.ClassName} not found in assembly {factory.Asm.FullName}");
                return 2;
            }

            // Clear previous DLL log text for this channel
            ClearChannelRtb(channel);

            // Create CompensationFlow instance via reflection
            // parameter = "PID,SerialNumber,UserID,Equipment\0"
            var flow = CreateFlowInstance(flowType, channel, parameter);
            if (flow == null)
            {
                _logger.Error($"StartFlow: Failed to create {config.ClassName} for CH{channel}");
                return 2;
            }

            _flows[(dllType, channel)] = flow;

            // Find the Run/Start method via reflection (cached per dllType)
            var runMethod = FindRunMethod(dllType, flowType);
            if (runMethod == null)
            {
                _logger.Error($"StartFlow: No Run/Start method found on {flowType.FullName}");
                return 2;
            }

            // Start on background thread
            var thread = new Thread(() =>
            {
                try
                {
                    InvokeRunMethod(runMethod, flow, parameter, paramLength, checkSum);
                }
                catch (TargetInvocationException tie)
                {
                    _logger.Error($"CompensationFlow execution error on CH{channel}", tie.InnerException ?? tie);
                }
                catch (Exception ex)
                {
                    _logger.Error($"CompensationFlow thread error on CH{channel}", ex);
                }
            });
            thread.IsBackground = true;
            thread.Name = $"OcFlow_T{dllType}_CH{channel}";
            thread.Start();

            _threads[(dllType, channel)] = thread;
            return 0;
        }
        catch (Exception ex)
        {
            _logger.Error($"StartFlow failed for dllType={dllType} CH{channel}", ex);
            return 2;
        }
    }

    /// <summary>Signals the flow to stop.</summary>
    public void StopFlow(int dllType, int channel)
    {
        if (_flows.TryGetValue((dllType, channel), out var flow))
        {
            try { flow.Set_IsStop(true); }
            catch (Exception ex)
            {
                _logger.Warn($"StopFlow error for dllType={dllType} CH{channel}: {ex.Message}");
            }
        }
    }

    /// <summary>Waits for the flow thread to complete within the given timeout.</summary>
    public bool WaitForFlowComplete(int dllType, int channel, int timeoutMs = 10000)
    {
        if (_threads.TryGetValue((dllType, channel), out var thread) && thread.IsAlive)
        {
            return thread.Join(timeoutMs);
        }
        return true;
    }

    /// <summary>Returns 1 if the flow thread is alive, 0 otherwise.</summary>
    public int GetFlowIsAlive(int dllType, int channel)
    {
        if (_threads.TryGetValue((dllType, channel), out var thread))
            return thread.IsAlive ? 1 : 0;
        return 0;
    }

    // =========================================================================
    // Data Retrieval
    // =========================================================================

    /// <summary>Retrieves summary log data for a flow.</summary>
    public string GetSummaryLogData(int dllType, int channel, string param)
    {
        if (_flows.TryGetValue((dllType, channel), out var flow))
        {
            try { return flow.Get_SummaryLogData(param) ?? ""; }
            catch { return ""; }
        }
        return "";
    }

    /// <summary>Retrieves summary log dictionary as JSON string.</summary>
    public string GetSummaryLogDictionary(int dllType, int channel)
    {
        if (_flows.TryGetValue((dllType, channel), out var flow))
        {
            try
            {
                var dict = flow.Get_SummaryLogDictionary();
                if (dict == null || dict.Count == 0) return "{}";
                return JsonSerializer.Serialize(dict);
            }
            catch { return "{}"; }
        }
        return "{}";
    }

    /// <summary>Gets the OC version from a loaded factory's flow.</summary>
    public string GetOcVersion(int factoryId)
    {
        // Try to find an existing flow for this factory
        foreach (var kvp in _flows)
        {
            if (kvp.Key.type == factoryId)
            {
                try { return kvp.Value.Get_DllVersion() ?? ""; }
                catch { return ""; }
            }
        }

        // No flow running — create a temporary instance to get version
        if (_loadedFactories.TryGetValue(factoryId, out var factory) && _bridges != null)
        {
            try
            {
                var flowType = factory.Asm.GetType(factory.Config.ClassName);
                if (flowType == null) return "";

                var tempFlow = CreateFlowInstance(flowType, 0, null);
                if (tempFlow != null)
                {
                    var version = tempFlow.Get_DllVersion() ?? "";
                    // Dispose if possible
                    (tempFlow as IDisposable)?.Dispose();
                    return version;
                }
            }
            catch (Exception ex)
            {
                _logger.Warn($"GetOcVersion failed for factoryId={factoryId}: {ex.Message}");
            }
        }
        return "";
    }

    /// <summary>Returns the orchestrator's own assembly version.</summary>
    public string GetConverterVersion()
    {
        return GetType().Assembly.GetName().Version?.ToString() ?? "1.0.0.0";
    }

    /// <summary>Gets the model name for a loaded factory's flow.</summary>
    public string GetModelName(int factoryId)
    {
        foreach (var kvp in _flows)
        {
            if (kvp.Key.type == factoryId)
            {
                try { return kvp.Value.Get_ModelName() ?? ""; }
                catch { return ""; }
            }
        }
        return "";
    }

    // =========================================================================
    // Disposal
    // =========================================================================

    public void FormDestroy()
    {
        // Stop all running flows
        foreach (var kvp in _flows)
        {
            try { kvp.Value.Set_IsStop(true); }
            catch { /* ignore */ }
        }

        // Wait for threads to finish (max 3 seconds each)
        foreach (var kvp in _threads)
        {
            try { kvp.Value.Join(3000); }
            catch { /* ignore */ }
        }

        _flows.Clear();
        _threads.Clear();
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        FormDestroy();

        // Stop the STA message pump thread (must happen before RTB disposal)
        try
        {
            _rtbAppContext?.ExitThread();
            _rtbPumpThread?.Join(3000);
        }
        catch { /* ignore */ }

        // Dispose RichTextBoxes
        if (_richTextBoxes != null)
        {
            foreach (var rtb in _richTextBoxes)
            {
                try { rtb?.Dispose(); }
                catch { /* ignore */ }
            }
            _richTextBoxes = null;
        }

        _rtbAppContext = null;
        _rtbPumpThread = null;
        _textChangedHandlers = null;
        _loadedFactories.Clear();

        // GC root 해제
        foreach (var handle in _gcRoots)
        {
            if (handle.IsAllocated)
                handle.Free();
        }
        _gcRoots.Clear();
    }

    // =========================================================================
    // Private — RichTextBox helpers
    // =========================================================================

    /// <summary>
    /// Clears the RichTextBox for the given channel and resets text tracking.
    /// Called at the start of each new OC flow to prevent stale log accumulation.
    /// </summary>
    private void ClearChannelRtb(int channel)
    {
        if (_richTextBoxes == null || channel >= _richTextBoxes.Length)
            return;

        var rtb = _richTextBoxes[channel];
        if (rtb == null || !rtb.IsHandleCreated)
            return;

        try
        {
            rtb.Invoke(new Action(() => rtb.Clear()));
        }
        catch { /* ignore — RTB may already be disposed */ }

        if (_rtbPreviousLength != null && channel < _rtbPreviousLength.Length)
            _rtbPreviousLength[channel] = 0;
    }

    // =========================================================================
    // Private — Reflection helpers
    // =========================================================================

    /// <summary>
    /// Creates a CompensationFlow instance by discovering the best-matching
    /// constructor via reflection.
    /// </summary>
    private ICompensationFlow? CreateFlowInstance(Type flowType, int channel, string? parameter)
    {
        if (_bridges == null) return null;

        var bridge = _bridges[channel];
        var ctors = flowType.GetConstructors(BindingFlags.Public | BindingFlags.Instance);

        // parameter = "PID,SerialNumber,UserID,Equipment\0" → 분해
        // Delphi 생성자: (X2146_API api, int channel_num, string _PID, string _SerialNumber,
        //                 string _User_ID, string _Model_Name, string _Equipment)
        var paramParts = parameter?.TrimEnd('\0').Split(',') ?? Array.Empty<string>();
        string pid = paramParts.Length > 0 ? paramParts[0] : "";
        string serialNumber = paramParts.Length > 1 ? paramParts[1] : "";
        string userId = paramParts.Length > 2 ? paramParts[2] : "";
        string equipment = paramParts.Length > 3 ? paramParts[3] : "";

        // Log available constructors for debugging
        foreach (var c in ctors)
        {
            var paramNames = string.Join(", ", c.GetParameters().Select(p => $"{p.ParameterType.Name} {p.Name}"));
            _logger.Debug($"  Constructor: ({paramNames})");
        }

        // Strategy 1: Find ctor(X2146_API, ...) — bridge IS-A X2146_API
        foreach (var ctor in ctors.OrderByDescending(c => c.GetParameters().Length))
        {
            var prms = ctor.GetParameters();
            if (prms.Length == 0) continue;

            // First param must be assignable from X2146_API (our HardwareBridge)
            if (!prms[0].ParameterType.IsAssignableFrom(typeof(HardwareBridge)))
                continue;

            var args = new object?[prms.Length];
            args[0] = bridge;

            // Fill remaining parameters — match by name for string params
            // Delphi ctor: (api, channel_num, _PID, _SerialNumber, _User_ID, _Model_Name, _Equipment)
            bool canCreate = true;
            int stringIdx = 0;
            for (int i = 1; i < prms.Length; i++)
            {
                var pt = prms[i].ParameterType;
                var name = prms[i].Name?.ToLowerInvariant() ?? "";

                if (pt == typeof(string))
                {
                    // 이름 기반 매칭 → 순서 기반 폴백
                    if (name.Contains("pid"))
                        args[i] = pid;
                    else if (name.Contains("serial"))
                        args[i] = serialNumber;
                    else if (name.Contains("user"))
                        args[i] = userId;
                    else if (name.Contains("model"))
                        args[i] = _modelName ?? "";
                    else if (name.Contains("equip"))
                        args[i] = equipment;
                    else
                    {
                        // 순서 기반: PID, SerialNumber, UserID, ModelName, Equipment
                        args[i] = stringIdx switch
                        {
                            0 => pid,
                            1 => serialNumber,
                            2 => userId,
                            3 => _modelName ?? "",
                            4 => equipment,
                            _ => ""
                        };
                    }
                    stringIdx++;
                }
                else if (pt == typeof(int))
                    args[i] = channel;
                else if (pt == typeof(bool))
                    args[i] = false;
                else if (pt.IsValueType)
                    args[i] = Activator.CreateInstance(pt);
                else if (prms[i].HasDefaultValue)
                    args[i] = prms[i].DefaultValue;
                else
                {
                    args[i] = null;
                    _logger.Warn($"CreateFlowInstance: unknown param {prms[i].Name} of type {pt.FullName}");
                }
            }

            if (!canCreate) continue;

            try
            {
                var instance = ctor.Invoke(args);
                if (instance is ICompensationFlow flow)
                    return flow;

                _logger.Warn($"CreateFlowInstance: {flowType.FullName} does not implement ICompensationFlow");
                return null;
            }
            catch (Exception ex)
            {
                var inner = ex is System.Reflection.TargetInvocationException tie ? tie.InnerException : ex;
                _logger.Warn($"CreateFlowInstance: Constructor failed for {flowType.FullName}: {ex.Message}");
                _logger.Error($"CreateFlowInstance: InnerException: {inner?.Message}\n{inner?.StackTrace}");
            }
        }

        // Strategy 2: Try parameterless constructor
        try
        {
            var instance = Activator.CreateInstance(flowType);
            if (instance is ICompensationFlow flow)
                return flow;
        }
        catch { /* not available */ }

        _logger.Error($"CreateFlowInstance: No suitable constructor found for {flowType.FullName}");
        return null;
    }

    /// <summary>
    /// Finds the Run/Start method on the CompensationFlow type.
    /// Caches the result per dllType.
    /// </summary>
    private MethodInfo? FindRunMethod(int dllType, Type flowType)
    {
        if (_runMethods.TryGetValue(dllType, out var cached))
            return cached;

        // Search for common method names in order of likelihood
        string[] methodNames = { "Run", "Start", "MainOC_START", "Execute", "RunFlow", "StartFlow" };

        foreach (var name in methodNames)
        {
            var methods = flowType.GetMethods(BindingFlags.Public | BindingFlags.Instance)
                .Where(m => m.Name.Equals(name, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(m => m.GetParameters().Length)
                .ToArray();

            foreach (var m in methods)
            {
                _runMethods[dllType] = m;
                _logger.Info($"Found run method: {flowType.Name}.{m.Name}({string.Join(", ", m.GetParameters().Select(p => $"{p.ParameterType.Name} {p.Name}"))})");
                return m;
            }
        }

        // Fallback: any public method with parameter + paramLength + checkSum style args
        var fallback = flowType.GetMethods(BindingFlags.Public | BindingFlags.Instance)
            .Where(m => !m.IsSpecialName && m.DeclaringType == flowType)
            .Where(m => m.GetParameters().Length >= 2)
            .FirstOrDefault();

        if (fallback != null)
        {
            _logger.Info($"Fallback run method: {flowType.Name}.{fallback.Name}");
        }

        _runMethods[dllType] = fallback;
        return fallback;
    }

    /// <summary>
    /// Invokes the discovered run method with the appropriate parameters.
    /// </summary>
    private void InvokeRunMethod(MethodInfo method, ICompensationFlow flow,
        string parameter, int paramLength, ushort checkSum)
    {
        var prms = method.GetParameters();
        var args = new object?[prms.Length];

        for (int i = 0; i < prms.Length; i++)
        {
            var pt = prms[i].ParameterType;
            var name = prms[i].Name?.ToLowerInvariant() ?? "";

            if (pt == typeof(string))
                args[i] = parameter;
            else if (pt == typeof(int) && name.Contains("len"))
                args[i] = paramLength;
            else if (pt == typeof(int) && name.Contains("check"))
                args[i] = (int)checkSum;
            else if (pt == typeof(ushort))
                args[i] = checkSum;
            else if (pt == typeof(int))
                args[i] = paramLength;
            else if (pt == typeof(bool))
                args[i] = false;
            else if (pt.IsValueType)
                args[i] = Activator.CreateInstance(pt);
            else
                args[i] = null;
        }

        method.Invoke(flow, args);
    }
}
