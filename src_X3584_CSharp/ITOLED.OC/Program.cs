// =============================================================================
// Program.cs — .NET 8 WinForms + BlazorWebView entry point
// Replaces Delphi Main_OC.pas application startup with single-instance Mutex.
// =============================================================================

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Components.WebView.WindowsForms;
using System.Globalization;
using Dongaeltek.ITOLED.Core.Common;
using Dongaeltek.ITOLED.Core.Configuration;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Logging;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.Hardware.PatternGenerator;
using Dongaeltek.ITOLED.Hardware.Dio;
using Dongaeltek.ITOLED.Hardware.Colorimeter;
using Dongaeltek.ITOLED.Hardware.Mes;
using HwNet;
using Dongaeltek.ITOLED.BusinessLogic.Mes;
using Dongaeltek.ITOLED.BusinessLogic.Dfs;
using Dongaeltek.ITOLED.BusinessLogic.Dll;
using Dongaeltek.ITOLED.BusinessLogic.Scripting;
using Dongaeltek.ITOLED.BusinessLogic.Inspection;
using Dongaeltek.ITOLED.BusinessLogic.Database;
using Dongaeltek.ITOLED.Messaging;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
using Dongaeltek.ITOLED.OC.Services;
using MudBlazor.Services;
using IAppLogger = Dongaeltek.ITOLED.Core.Interfaces.ILogger;

namespace Dongaeltek.ITOLED.OC;

public class Program
{
    private static Mutex? _singleInstanceMutex;

    /// <summary>DPDK NIC coordinator for FTP exclusive access (null when Socket mode).</summary>
    internal static IDpdkNicCoordinator? NicCoordinator { get; private set; }

    // stderr 리다이렉트용 P/Invoke (DPDK 내부 로그 캡처)
    [DllImport("ucrtbase.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr __acrt_iob_func(int index);

    [DllImport("ucrtbase.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    private static extern IntPtr freopen(string path, string mode, IntPtr stream);

    [DllImport("ucrtbase.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern int fflush(IntPtr stream);

    // ── Native crash diagnostics ──────────────────────────────────────
    [DllImport("kernel32.dll")]
    private static extern IntPtr SetUnhandledExceptionFilter(IntPtr lpTopLevelExceptionFilter);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetCurrentProcess();

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentProcessId();

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("dbghelp.dll", SetLastError = true)]
    private static extern bool MiniDumpWriteDump(
        IntPtr hProcess, uint processId, IntPtr hFile,
        uint dumpType, IntPtr exceptionParam,
        IntPtr userStreamParam, IntPtr callbackParam);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int UnhandledExceptionFilterDelegate(IntPtr exceptionPointers);

    // prevent GC collection of the delegate
    private static UnhandledExceptionFilterDelegate? _nativeFilterDelegate;

    [StructLayout(LayoutKind.Sequential)]
    private struct MINIDUMP_EXCEPTION_INFORMATION
    {
        public uint ThreadId;
        public IntPtr ExceptionPointers;
        public int ClientPointers;
    }

    private static void WriteMiniDump(IntPtr exceptionPointers)
    {
        try
        {
            var dumpDir = Path.Combine(AppContext.BaseDirectory, "LOG", "CrashDump");
            Directory.CreateDirectory(dumpDir);
            var dumpPath = Path.Combine(dumpDir, $"crash_{DateTime.Now:yyyyMMdd_HHmmss}.dmp");

            using var fs = new FileStream(dumpPath, FileMode.Create, FileAccess.Write, FileShare.None);

            // MiniDumpWithDataSegs | MiniDumpWithHandleData | MiniDumpWithThreadInfo
            const uint dumpType = 0x00000001 | 0x00000004 | 0x00001000;

            if (exceptionPointers != IntPtr.Zero)
            {
                var mei = new MINIDUMP_EXCEPTION_INFORMATION
                {
                    ThreadId = GetCurrentThreadId(),
                    ExceptionPointers = exceptionPointers,
                    ClientPointers = 0
                };
                var meiPtr = Marshal.AllocHGlobal(Marshal.SizeOf(mei));
                try
                {
                    Marshal.StructureToPtr(mei, meiPtr, false);
                    MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(),
                        fs.SafeFileHandle.DangerousGetHandle(), dumpType, meiPtr, IntPtr.Zero, IntPtr.Zero);
                }
                finally
                {
                    Marshal.FreeHGlobal(meiPtr);
                }
            }
            else
            {
                MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(),
                    fs.SafeFileHandle.DangerousGetHandle(), dumpType, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero);
            }
        }
        catch { /* 덤프 실패 시 무시 — 크래시 핸들러 내에서 2차 예외 방지 */ }
    }

    private static int NativeExceptionFilter(IntPtr exceptionPointers)
    {
        try
        {
            WriteMiniDump(exceptionPointers);

            var crashDir = Path.Combine(AppContext.BaseDirectory, "LOG", "DebugLog");
            Directory.CreateDirectory(crashDir);
            var msg = $"\n{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\n" +
                      $"[FATAL] Native SEH Exception (Access Violation / Stack Overflow)\n" +
                      $"ExceptionPointers=0x{exceptionPointers:X}\n" +
                      $"ThreadId={GetCurrentThreadId()}\n" +
                      $"MiniDump saved to LOG/CrashDump/\n";
            File.AppendAllText(
                Path.Combine(crashDir, $"CrashLog_{DateTime.Now:yyyyMMdd}.txt"), msg);
        }
        catch { /* 파일 쓰기 실패 시 무시 */ }

        return 0; // EXCEPTION_CONTINUE_SEARCH — WER에 전달
    }

    [STAThread]
    public static void Main(string[] args)
    {
        // ── Native SEH exception filter — 가장 먼저 등록 (DPDK/DLL Access Violation 캐치) ──
        _nativeFilterDelegate = NativeExceptionFilter;
        SetUnhandledExceptionFilter(
            Marshal.GetFunctionPointerForDelegate(_nativeFilterDelegate));

        // Single-instance check (replaces Delphi's CreateMutex)
        const string mutexName = "Global\\ITOLED_OC_BLAZOR_INSTANCE";
        _singleInstanceMutex = new Mutex(true, mutexName, out bool createdNew);
        if (!createdNew)
        {
            MessageBox.Show("Another instance of ITOLED_OC is already running.",
                "ITOLED OC", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        SplashForm? splash = null;
        IServiceProvider? sp = null;
        System.Threading.Timer? heartbeatTimer = null;
        IPgTransport? pgTransport = null;
        try
        {
            // Register Korean ANSI codepage (949) for MES TIB communication
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);

            // Unhandled exception 핸들러 — 크래시 원인을 파일에 기록
            AppDomain.CurrentDomain.UnhandledException += (_, e) =>
            {
                var ex = e.ExceptionObject as Exception;
                var msg = $"[FATAL] UnhandledException IsTerminating={e.IsTerminating}\n{ex}";
                try
                {
                    WriteMiniDump(IntPtr.Zero);
                    var crashDir = Path.Combine(AppContext.BaseDirectory, "LOG", "DebugLog");
                    Directory.CreateDirectory(crashDir);
                    File.AppendAllText(
                        Path.Combine(crashDir, $"CrashLog_{DateTime.Now:yyyyMMdd}.txt"),
                        $"\n{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\n{msg}\nMiniDump saved to LOG/CrashDump/\n");
                }
                catch { /* 파일 쓰기도 실패하면 포기 */ }
            };

            // Unobserved Task exceptions (fire-and-forget Task.Run) —
            // 핸들러 없으면 GC 시 프로세스 종료됨 (CrashLog 미생성)
            TaskScheduler.UnobservedTaskException += (_, e) =>
            {
                e.SetObserved(); // 프로세스 종료 방지
                var msg = $"[ERROR] UnobservedTaskException\n{e.Exception}";
                try
                {
                    var crashDir = Path.Combine(AppContext.BaseDirectory, "LOG", "DebugLog");
                    Directory.CreateDirectory(crashDir);
                    File.AppendAllText(
                        Path.Combine(crashDir, $"CrashLog_{DateTime.Now:yyyyMMdd}.txt"),
                        $"\n{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\n{msg}\n");
                }
                catch { /* 파일 쓰기도 실패하면 포기 */ }
            };

            Application.ThreadException += (_, e) =>
            {
                var msg = $"[FATAL] ThreadException\n{e.Exception}";
                try
                {
                    WriteMiniDump(IntPtr.Zero);
                    var crashDir = Path.Combine(AppContext.BaseDirectory, "LOG", "DebugLog");
                    Directory.CreateDirectory(crashDir);
                    File.AppendAllText(
                        Path.Combine(crashDir, $"CrashLog_{DateTime.Now:yyyyMMdd}.txt"),
                        $"\n{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\n{msg}\nMiniDump saved to LOG/CrashDump/\n");
                }
                catch { /* 파일 쓰기도 실패하면 포기 */ }
            };

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.SetHighDpiMode(HighDpiMode.SystemAware);

            // ── Configuration ─────────────────────────────────────────────
            var configuration = new ConfigurationBuilder()
                .SetBasePath(AppContext.BaseDirectory)
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
                .Build();

            var appConfig = configuration
                .GetSection("AppConfiguration")
                .Get<AppConfiguration>() ?? new AppConfiguration();

            // ── LGDDLL Assembly Resolver ─────────────────────────────────
            // LGD base DLLs (LGD_OC_AstractPlatForm, Observers, MathNet, etc.)
            // reside in LGDDLL\ subdirectory. Register a resolver so the Default
            // ALC can load them. Factory DLLs are loaded by FactoryAssemblyLoadContext.
            {
                var rootDir = !string.IsNullOrWhiteSpace(appConfig.RootDirectory)
                    ? appConfig.RootDirectory
                    : AppContext.BaseDirectory;
                var lgdDir = Path.Combine(rootDir, "LGDDLL");

                System.Runtime.Loader.AssemblyLoadContext.Default.Resolving +=
                    (context, name) =>
                    {
                        // Skip satellite/resource assemblies
                        if (!string.IsNullOrEmpty(name.CultureName))
                            return null;

                        var dllPath = Path.Combine(lgdDir, name.Name + ".dll");
                        if (File.Exists(dllPath))
                            return context.LoadFromAssemblyPath(dllPath);

                        return null;
                    };
            }

            // ── TIBCO Assembly Resolver ────────────────────────────────────
            // TIBCO_ECS_Converter.dll depends on TIBrvDriver64.dll and
            // TIBCO.Rendezvous.dll, which reside in the root directory.
            {
                var tibcoRootDir = !string.IsNullOrWhiteSpace(appConfig.RootDirectory)
                    ? appConfig.RootDirectory
                    : AppContext.BaseDirectory;

                System.Runtime.Loader.AssemblyLoadContext.Default.Resolving +=
                    (context, name) =>
                    {
                        if (!string.IsNullOrEmpty(name.CultureName))
                            return null;

                        var tibcoDll = Path.Combine(tibcoRootDir, name.Name + ".dll");
                        if (File.Exists(tibcoDll))
                            return context.LoadFromAssemblyPath(tibcoDll);

                        return null;
                    };
            }

            // ── DI Container ──────────────────────────────────────────────
            var services = new ServiceCollection();

            // Blazor WebView
            services.AddWindowsFormsBlazorWebView();
#if DEBUG
            services.AddBlazorWebViewDeveloperTools();
#endif
            services.AddMudServices();

            // Configuration
            services.AddSingleton<IConfiguration>(configuration);
            services.AddSingleton(appConfig);

            // Logging
            services.AddLogging(builder =>
            {
                builder.SetMinimumLevel(LogLevel.Debug);
            });

            // ── Core services ─────────────────────────────────────────────
            services.AddSingleton<IMessageBus, MessageBus>();
            services.AddSingleton<ISystemStatusService, SystemStatusService>();
            services.AddSingleton<IPathManager>(sp =>
            {
                // Use RootDirectory from appsettings.json if configured,
                // otherwise fall back to exe directory (AppContext.BaseDirectory).
                var pm = !string.IsNullOrWhiteSpace(appConfig.RootDirectory)
                    ? new PathManager(appConfig.RootDirectory)
                    : new PathManager();
                pm.InitializePaths();
                return pm;
            });

            // Custom ILogger bridge → Microsoft.Extensions.Logging
            services.AddSingleton<IAppLogger, AppLogger>();

            // ConfigurationService (reads/writes SystemConfig.ini)
            services.AddSingleton<IConfigurationService>(sp =>
                new ConfigurationService(
                    sp.GetRequiredService<IPathManager>(),
                    sp.GetRequiredService<AppConfiguration>()));

            // ── Hardware drivers ───────────────────────────────────────────

            // PLC ECS Driver — uses TCP connection to ActUtilTCPServer.exe
            // (Delphi: TCommPLCThread.Create(..., Common.PLCInfo.Use_Simulation) in Main_OC.pas line 6207)
            // When PlcInfo.UseSimulation=true, actUtl is null → PlcEcsDriver enters simulator mode.
            services.AddSingleton<IPlcEcsDriver>(sp =>
            {
                IActUtlType? actUtl = null;
                var bus = sp.GetRequiredService<IMessageBus>();
                var log = sp.GetRequiredService<IAppLogger>();
                var cfgSvc = sp.GetRequiredService<IConfigurationService>();

                if (!cfgSvc.PlcInfo.UseSimulation)
                {
                    // Real PLC mode: TCP client to ActUtilTCPServer.exe on localhost:3888
                    actUtl = new ActUtlTypeTcp("127.0.0.1", 3888, bus, log);
                }

                return new PlcEcsDriver(
                    actUtl,
                    bus,
                    log,
                    cfgSvc,
                    sp.GetRequiredService<ISystemStatusService>());
            });

            // IPlcService resolved via PlcEcsDriver
            services.AddSingleton<IPlcService>(sp =>
                sp.GetRequiredService<IPlcEcsDriver>());

            // DaeDioDriver (DAE DJ596-DIO UDP driver)
            // deviceCount must match DioConfig.DaeIoDeviceCount (12) for 96-channel OC.
            // useFlushMode=true: buffered DO writes via polling loop (matches Delphi behaviour).
            services.AddSingleton<IDaeDioDriver>(sp =>
                new DaeDioDriver(
                    sp.GetRequiredService<IMessageBus>(),
                    sp.GetRequiredService<IAppLogger>(),
                    deviceCount: DioConfig.DaeIoDeviceCount,
                    useFlushMode: true));

            // DIO Controller
            services.AddSingleton<IDioController>(sp =>
                new DioController(
                    sp.GetRequiredService<IMessageBus>(),
                    sp.GetRequiredService<IAppLogger>(),
                    sp.GetRequiredService<IConfigurationService>(),
                    sp.GetRequiredService<ISystemStatusService>(),
                    sp.GetRequiredService<IPlcService>(),
                    sp.GetRequiredService<IDaeDioDriver>()));

            // PG DebugLog — CommLogger for PG communication logs per channel
            // Delphi: PGLogger := TLogger.Create(4096, MAX_PG_CNT, sFileNames, 10*1024*1024)
            // Files: LOG\DebugLog\{yyyyMMdd}\DebugLog_{EQPID}_{date}_Ch{N}.txt
            services.AddSingleton<CommLogger>(sp =>
            {
                var pm = sp.GetRequiredService<IPathManager>();
                var cfg = sp.GetRequiredService<IConfigurationService>();
                var eqpId = cfg.SystemInfo?.EQPId ?? "OC";
                var debugLogger = new CommLogger(4, pm.DebugLogDir, eqpId);
                debugLogger.LogPrefix = "DebugLog_";
                debugLogger.SystemLogPrefix = "DebugLog_System_";
                return debugLogger;
            });

            // CommPgDriver — 4 instances (CH1~CH4), matching Delphi PG[CH1..MAX_CH]
            // Each channel has its own IP (169.254.199.11~14) and port (8001~8004)
            services.AddSingleton<ICommPgDriver[]>(sp =>
            {
                var bus = sp.GetRequiredService<IMessageBus>();
                var logger = sp.GetRequiredService<IAppLogger>();
                var cfg = sp.GetRequiredService<IConfigurationService>();
                var status = sp.GetRequiredService<ISystemStatusService>();
                var debugLogger = sp.GetRequiredService<CommLogger>();
                var drivers = new ICommPgDriver[4];
                for (int i = 0; i < 4; i++)
                    drivers[i] = new CommPgDriver(i, string.Empty, bus, logger, cfg, status,
                        debugLogger: debugLogger);
                return drivers;
            });

            // Backward-compatible single ICommPgDriver — resolves to CH1 (index 0)
            services.AddSingleton<ICommPgDriver>(sp =>
                sp.GetRequiredService<ICommPgDriver[]>()[0]);

            // CA-SDK2 (colorimeter)
            // Delphi: Test4ChOC.pas lines 4242-4250 — create, configure per-channel, connect
            services.AddSingleton<ICaSdk2Driver>(sp =>
            {
                var bus = sp.GetRequiredService<IMessageBus>();
                var cfgSvc = sp.GetRequiredService<IConfigurationService>();
                var modelSvc = sp.GetRequiredService<IModelInfoService>();

                // Memory channel: Delphi uses Ca410MemCh+1 (1-based)
                int memCh = modelSvc.GetModelValueInt("FLOW_DATA", "Ca410MemCh", 0) + 1;
                var driver = new CaSdk2Driver(bus, memChannel: memCh, auto: true);

                // Configure per-channel setup from SystemInfo INI
                var sysInfo = cfgSvc.SystemInfo;
                if (sysInfo != null)
                {
                    for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
                    {
                        driver.SetSetupPort(i, new CaSetupInfo
                        {
                            SelectIdx = sysInfo.ComCa310[i],
                            DeviceId  = sysInfo.ComCa310DeviceId[i],
                            SerialNo  = sysInfo.ComCa310Serial[i]
                        });
                    }
                }

                // Scan USB and connect (Delphi: CaSdk2.ManualConnect)
                driver.ManualConnect();

                return driver;
            });

            // MES Communication (TIBCO_ECS_Converter.dll via DllImport P/Invoke)
            services.AddSingleton<IMesCommunication>(sp =>
            {
                var pm = sp.GetRequiredService<IPathManager>();
                return new MesComManaged(
                    sp.GetRequiredService<IAppLogger>(),
                    pm.RootDir,
                    serverCount: 2);
            });

            // ── Business logic services ────────────────────────────────────

            // GMES Communication
            services.AddSingleton<IGmesCommunication>(sp =>
                new GmesCommunication(
                    sp.GetRequiredService<IConfigurationService>(),
                    sp.GetRequiredService<IAppLogger>(),
                    sp.GetRequiredService<IMessageBus>(),
                    sp.GetRequiredService<IMesCommunication>()));

            // DFS Service
            services.AddSingleton<IDfsService, DfsService>();

            // DLL Manager (direct Factory DLL management via OcFlowOrchestrator)
            services.AddSingleton<IDllManager>(sp =>
            {
                var pm = sp.GetRequiredService<IPathManager>();
                return new DllManager(
                    sp.GetRequiredService<IConfigurationService>(),
                    sp.GetRequiredService<IAppLogger>(),
                    sp.GetRequiredService<IMessageBus>(),
                    sp.GetRequiredService<ICaSdk2Driver>(),
                    dllPath: pm.LgdDllDir,
                    pathManager: pm,
                    pg: sp.GetRequiredService<ICommPgDriver[]>());
            });

            // ── Script Engine — 4 instances (CH1~CH4), matching Delphi PasScr[CH1..MAX_CH]
            services.AddSingleton<IScriptRunner[]>(sp =>
            {
                // MLog CommLogger — per-channel inspection logs
                // Files: LOG\MLog\{yyyyMMdd}\MLog_{EQPID}_{date}_{AM/PM}_Ch{N}.txt
                var pm = sp.GetRequiredService<IPathManager>();
                var cfgSvc = sp.GetRequiredService<IConfigurationService>();
                var eqpId = cfgSvc.SystemInfo?.EQPId ?? "OC";
                var mLogLogger = new CommLogger(4, pm.MLogDir, eqpId);

                var runners = new IScriptRunner[4];
                for (int i = 0; i < 4; i++)
                    runners[i] = new ScriptEngine(
                        i,
                        cfgSvc,
                        sp.GetRequiredService<ISystemStatusService>(),
                        pm,
                        sp.GetRequiredService<IMessageBus>(),
                        sp.GetRequiredService<IAppLogger>(),
                        sp.GetRequiredService<ICommPgDriver[]>(),
                        sp.GetRequiredService<IDioController>(),
                        sp.GetRequiredService<IDllManager>(),
                        sp.GetService<IGmesCommunication>(),
                        sp.GetService<IPlcEcsDriver>(),
                        new[] { sp.GetRequiredService<IDfsService>() },
                        sp.GetRequiredService<IModelInfoService>(),
                        mLogLogger);
                return runners;
            });

            // ── Model Info Service ─────────────────────────────────────────
            services.AddSingleton<IModelInfoService>(sp =>
                new ModelInfoService(
                    sp.GetRequiredService<IPathManager>(),
                    sp.GetRequiredService<IConfigurationService>()));

            // ── App Services ──────────────────────────────────────────────
            services.AddSingleton<IAppInitializer, AppInitializer>();

            // ── Flow Completion Coordinator ───────────────────────────────
            // DLL WorkDone → JIG pair check → Process_Finish script execution
            services.AddSingleton<FlowCompletionCoordinator>();

            // ── Database Service (SQLite NG ratio tracking) ─────────────────
            // Delphi origin: DBModule.pas (TDBModule_Sqlite)
            services.AddSingleton<IDatabaseService>(sp =>
            {
                var pm = sp.GetRequiredService<IPathManager>();
                var dbPath = Path.Combine(pm.RootDir, "ISPD_DATA.db");
                return new DatabaseService(
                    dbPath,
                    sp.GetRequiredService<IAppLogger>());
            });

            // ── UI Services ────────────────────────────────────────────────
            services.AddSingleton<UiUpdateService>();

            // ── Build & Run ────────────────────────────────────────────────
            // NOTE: UiUpdateService NG alarm threshold is set after config load (below)
            sp = services.BuildServiceProvider();

            // Enable file logging (LOG\DebugLog\AppLog_yyyyMMdd_AM/PM.txt)
            var appLogger = sp.GetRequiredService<IAppLogger>();
            if (appLogger is AppLogger fileLogger)
            {
                var pathMgr = sp.GetRequiredService<IPathManager>();
                fileLogger.EnableFileLogging(pathMgr.DebugLogDir);
            }

            // ── Splash Screen ────────────────────────────────────────────
            splash = new SplashForm();
            splash.Show();

            // Load INI configuration (SysTemConfig.ini) at startup
            // Delphi equivalent: TCommon.ReadSystemInfo in FormCreate
            splash.UpdateProgress("Loading configuration...", 5);
            var configSvc = sp.GetRequiredService<IConfigurationService>();
            configSvc.Reload();

            // Load MES_CODE.csv for GMES defect code mapping
            // Delphi: TCommon.LoadMesCode in ReadModelInfo
            configSvc.ReadGmesCsvFile();

            // Set NG alarm threshold from config (Delphi: SystemInfo.NGAlarmCount)
            var uiService = sp.GetRequiredService<UiUpdateService>();
            uiService.SetNgAlarmThreshold(configSvc.SystemInfo?.NGAlarmCount ?? 0);

            // Load current model MCF at startup (Delphi: ReadModelInfo in FormCreate)
            splash.UpdateProgress("Loading model...", 15);
            var modelSvc = sp.GetRequiredService<IModelInfoService>();
            var testModel = configSvc.SystemInfo?.TestModel;
            if (!string.IsNullOrEmpty(testModel))
                modelSvc.LoadModel(testModel);

            // Load CSX script into ScriptEngines
            // Delphi: TCommon.LoadPsuFile → scrSequnce.LoadFromFile
            //         TJig.Create → PasScr[nCh].LoadSource(Common.scrSequnce)
            splash.UpdateProgress("Compiling scripts...", 25);
            var scriptRunners = sp.GetRequiredService<IScriptRunner[]>();
            var scriptFailedChannels = new HashSet<int>();
            var scriptErrors = new List<string>();
            if (!string.IsNullOrEmpty(testModel))
            {
                var pathMgr = sp.GetRequiredService<IPathManager>();
                var csxPath = pathMgr.GetFilePath(testModel, PathIndex.ScriptCsx);
                System.Diagnostics.Debug.WriteLine($"[CSX] Path resolved: {csxPath}");
                System.Diagnostics.Debug.WriteLine($"[CSX] File exists: {File.Exists(csxPath)}");
                if (File.Exists(csxPath))
                {
                    var scriptLines = File.ReadAllLines(csxPath, Encoding.UTF8);
                    System.Diagnostics.Debug.WriteLine($"[CSX] Loaded {scriptLines.Length} lines, compiling for {scriptRunners.Length} channels...");
                    for (int ri = 0; ri < scriptRunners.Length; ri++)
                    {
                        try
                        {
                            scriptRunners[ri].LoadSource(scriptLines);
                            System.Diagnostics.Debug.WriteLine($"[CSX] CH{ri} compile OK");
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine($"[CSX] CH{ri} compile FAIL: {ex.Message}");
                            scriptErrors.Add($"CH{ri + 1} compile: {ex.Message}");
                            scriptFailedChannels.Add(ri);
                        }
                    }

                    // Delphi: Main_OC.pas:5992-5994 — PasScr[i].InitialScript
                    // Calls Seq_INIT(0) to initialize script-level variables
                    for (int ri = 0; ri < scriptRunners.Length; ri++)
                    {
                        if (scriptFailedChannels.Contains(ri)) continue;
                        try
                        {
                            scriptRunners[ri].InitialScript();
                            System.Diagnostics.Debug.WriteLine($"[CSX] CH{ri} InitialScript OK");
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine($"[CSX] CH{ri} InitialScript FAIL: {ex.Message}");
                            scriptErrors.Add($"CH{ri + 1} init: {ex.Message}");
                            scriptFailedChannels.Add(ri);
                        }
                    }
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine($"[CSX] File NOT found — script loading skipped");
                    scriptErrors.Add($"Script file not found: {csxPath}");
                }
            }

            // Sync USE_CH flags from INI → runtime status service
            // (Delphi: CommonClass ReadSystemInfo → StatusInfo.UseChannel)
            splash.UpdateProgress("Syncing channel settings...", 40);
            var statusSvc = sp.GetRequiredService<ISystemStatusService>();
            if (configSvc.SystemInfo != null)
            {
                for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
                    statusSvc.SetChannelEnabled(i, configSvc.SystemInfo.UseCh[i]);

                // Sync USE_CH → ScriptRunner.IsInUse
                // (Delphi: Test4ChOC.pas:3032 — PasScr[nCh].m_bUse := Common.SystemInfo.UseCh[nCh])
                for (int i = ChannelConstants.Ch1; i <= ChannelConstants.MaxCh; i++)
                {
                    if (i < scriptRunners.Length)
                        scriptRunners[i].IsInUse = configSvc.SystemInfo.UseCh[i];
                }
            }

            // Disable channels that failed script compilation and notify user
            foreach (var failedCh in scriptFailedChannels)
            {
                if (failedCh < scriptRunners.Length)
                    scriptRunners[failedCh].IsInUse = false;
            }
            if (scriptErrors.Count > 0)
            {
                var errorMsg = "스크립트 오류:\n\n" +
                    string.Join("\n", scriptErrors) +
                    "\n\n해당 채널은 비활성화됩니다.";
                MessageBox.Show(errorMsg, "ITOLED OC — Script Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }

            // Initialize OC DLL with model type name
            // (Delphi: Test4ChOC.pas:4232 — CsharpDll.Initialize(Common.TestModelInfoFLOW.ModelTypeName))
            splash.UpdateProgress("Initializing OC DLL...", 50);
            var dllManager = sp.GetRequiredService<IDllManager>();
            if (dllManager.IsLoaded && modelSvc is ModelInfoService mis2)
            {
                var modelTypeName = mis2.FlowData.ModelTypeName;
                if (!string.IsNullOrEmpty(modelTypeName))
                {
                    dllManager.Initialize(modelTypeName);
                    System.Diagnostics.Debug.WriteLine($"[DLL] DllManager.Initialize('{modelTypeName}') completed");
                }
            }

            // Initialize SQLite database for NG ratio tracking
            // Delphi: DBModule.CheckAndCreateTable in FormCreate
            var dbService = sp.GetRequiredService<IDatabaseService>();
            dbService.Initialize();

            // Eagerly resolve FlowCompletionCoordinator so its DllEventMessage
            // subscription activates (DLL WorkDone → JIG pair → Process_Finish)
            _ = sp.GetRequiredService<FlowCompletionCoordinator>();

            // Eagerly resolve hardware singletons so their constructors run
            // (DioController.ctor calls _dioDriver.Start() to begin UDP polling)
            splash.UpdateProgress("Starting DIO controller...", 60);
            _ = sp.GetRequiredService<IDioController>();

            // Initialize PG UDP Server for DP860 communication (4-channel)
            // (Delphi: CreateClassData → UdpServerPG := TUdpServerPG.Create with PG[CH1..MAX_CH])
            splash.UpdateProgress("Setting up PG communication...", 70);
            var pgDrivers = sp.GetRequiredService<ICommPgDriver[]>();
            var concretePgArray = pgDrivers.OfType<CommPgDriver>().ToArray();
            if (concretePgArray.Length > 0)
            {
                // Update model type on all PG instances
                if (modelSvc is ModelInfoService mis)
                {
                    foreach (var pg in concretePgArray)
                        pg.UpdateModelType(mis.FlowData.ModelTypeName, mis.FlowData.ModelFileName);
                }

                // Flush logs before PG transport setup (crash 방지)
                if (appLogger is AppLogger al0) al0.Flush();

                // Create PG transport — DPDK or Socket UDP based on config
                var pgLogger = sp.GetRequiredService<IAppLogger>();
                bool useDpdk = configSvc.SystemInfo?.UseDpdk ?? false;

                bool dpdkFailed = false;
                string? dpdkFailReason = null;

                if (useDpdk)
                {
                    try
                    {
                        splash.UpdateProgress("DPDK 초기화 중...", 68);
                        pgLogger.Info("[DPDK] Step 1: HwManager.InitializeAsync 시작...");
                        if (HwManager.Instance.State != HwState.Ready)
                        {
                            var sysInfo = configSvc.SystemInfo!;
                            pgLogger.Info($"[DPDK] Step 1a: CoreMask={sysInfo.DpdkCoreMask}, MemoryMb={sysInfo.DpdkMemoryMb}, PortId={sysInfo.DpdkPortId}");

                            // DPDK stderr 로그를 파일로 캡처 (bus scan 디버깅)
                            string dpdkLogPath = Path.Combine(AppContext.BaseDirectory, "dpdk_bus_debug.log");
                            try
                            {
                                IntPtr stderr = __acrt_iob_func(2);
                                freopen(dpdkLogPath, "w", stderr);
                                pgLogger.Info($"[DPDK] stderr → {dpdkLogPath} 리다이렉트 완료");
                            }
                            catch (Exception ex)
                            {
                                pgLogger.Info($"[DPDK] stderr 리다이렉트 실패: {ex.Message}");
                            }

                            // StatusChanged 이벤트 구독하여 초기화 진행 상황 로깅
                            HwManager.Instance.StatusChanged += (_, e) =>
                                pgLogger.Info($"[DPDK] Status: [{e.State}] {e.Message}");

                            HwManager.Instance.InitializeAsync(new HwInitOptions
                            {
                                CoreMask = sysInfo.DpdkCoreMask,
                                MemoryMb = sysInfo.DpdkMemoryMb,
                                PortId = sysInfo.DpdkPortId,
                                LogLevel = "8"  // 임시: PCI bus debug 로그 필요
                            }).GetAwaiter().GetResult();

                            // stderr flush + 복원 후 DPDK 내부 로그 AppLog에 기록
                            try
                            {
                                IntPtr stderrPtr = __acrt_iob_func(2);
                                fflush(stderrPtr);
                                freopen("NUL", "w", stderrPtr); // stderr 복원 (파일 잠금 해제)
                                string dpdkBusLog = Path.Combine(AppContext.BaseDirectory, "dpdk_bus_debug.log");
                                if (File.Exists(dpdkBusLog))
                                {
                                    string content = File.ReadAllText(dpdkBusLog);
                                    if (!string.IsNullOrWhiteSpace(content))
                                    {
                                        foreach (var line in content.Split('\n', StringSplitOptions.RemoveEmptyEntries))
                                            pgLogger.Info($"[DPDK-BUS] {line.TrimEnd()}");
                                    }
                                    else
                                    {
                                        pgLogger.Info("[DPDK-BUS] (로그 파일 비어있음 — stderr 캡처 실패 가능)");
                                    }
                                }
                            }
                            catch (Exception ex)
                            {
                                pgLogger.Info($"[DPDK-BUS] 로그 읽기 실패: {ex.Message}");
                            }

                            pgLogger.Info($"[DPDK] Step 1b: InitializeAsync 완료 — State={HwManager.Instance.State}, Error={HwManager.Instance.ErrorMessage ?? "none"}");
                        }
                        else
                        {
                            pgLogger.Info("[DPDK] Step 1: HwManager already Ready, 건너뜀");
                        }

                        if (HwManager.Instance.State != HwState.Ready)
                        {
                            var errMsg = HwManager.Instance.ErrorMessage ?? "Unknown error";
                            pgLogger.Error($"[DPDK] DPDK 초기화 실패 (State={HwManager.Instance.State}): {errMsg}");

                            // Read eal_debug.txt for diagnostic info
                            string debugLog = HwManager.ReadDebugLog(4096);
                            if (!string.IsNullOrEmpty(debugLog))
                                pgLogger.Error($"[DPDK] EAL Debug Log:\n{debugLog}");

                            dpdkFailed = true;
                            dpdkFailReason = errMsg;
                        }
                        else
                        {
                            pgLogger.Info("[DPDK] Step 2: PgDpdkServer 생성 시작...");
                            pgTransport = new PgDpdkServer(pgLogger, concretePgArray,
                                HwManager.Instance, configSvc.SystemInfo?.UseCh,
                                configSvc.SystemInfo?.PGEnableDpdkWarmup ?? true);
                            pgLogger.Info("[DPDK] Step 3: PgDpdkServer 생성 완료 — PG transport: DPDK (kernel bypass)");
                        }
                    }
                    catch (Exception ex)
                    {
                        pgLogger.Error($"[DPDK] 예외: {ex.GetType().Name}: {ex.Message}");
                        pgLogger.Error($"[DPDK] StackTrace: {ex.StackTrace}");
                        dpdkFailed = true;
                        dpdkFailReason = ex.Message;
                    }
                }

                // DPDK 미사용 또는 실패 시 Socket UDP 폴백
                if (!useDpdk || dpdkFailed)
                {
                    if (dpdkFailed)
                        pgLogger.Error($"[DPDK] DPDK 실패: {dpdkFailReason} — Socket UDP 폴백 시도");

                    try
                    {
                        pgLogger.Info("[Socket] PgUdpServer 생성 시작...");
                        pgTransport = new PgUdpServer(pgLogger, concretePgArray);
                        pgLogger.Info("[Socket] PgUdpServer 생성 완료 — PG transport: Socket UDP");
                        uiService.PgTransportMode = dpdkFailed ? "Socket (DPDK 실패)" : "Socket";
                        uiService.IsDpdkFallback = dpdkFailed;
                    }
                    catch (Exception ex)
                    {
                        pgLogger.Error($"[Socket] PgUdpServer 생성 실패: {ex.Message}");
                        uiService.PgTransportMode = "PG 미연결";
                        uiService.IsDpdkFallback = true;
                    }
                }
                else if (pgTransport != null)
                {
                    uiService.PgTransportMode = "DPDK";
                }

                // Connect each driver to the shared transport and start monitoring
                // For DPDK mode: create NIC coordinator for exclusive FTP access
                IDpdkNicCoordinator? nicCoordinator = null;
                if (pgTransport is PgDpdkServer dpdkServer)
                {
                    nicCoordinator = new DpdkNicCoordinator(dpdkServer, pgLogger);
                    NicCoordinator = nicCoordinator;
                }

                var flashDir = sp.GetRequiredService<IPathManager>().FlashDir;
                foreach (var pg in concretePgArray)
                {
                    pg.SetTransport(pgTransport);
                    pg.SetFlashDir(flashDir);
                    if (nicCoordinator != null && pgTransport is PgDpdkServer dpdk)
                        pg.SetDpdkFtpAccess(nicCoordinator, dpdk.Dpdk);
                    pg.SetCyclicTimer(true);
                }
            }

            // Initialize CA-410 colorimeter connection
            // (Delphi: Test4ChOC.pas FormCreate → CaSdk2 setup + ManualConnect)
            splash.UpdateProgress("Connecting CA-410 colorimeter...", 80);
            _ = sp.GetRequiredService<ICaSdk2Driver>();

            // Configure and start PLC driver (Delphi: FormCreate → g_CommPLC setup)
            splash.UpdateProgress("Starting PLC communication...", 90);
            var plcDriver = sp.GetRequiredService<IPlcEcsDriver>();
            var plcInfo = configSvc.PlcInfo;
            plcDriver.SetEqpId(plcInfo.EQPId);
            plcDriver.SetStartAddress(
                ParseHexAddress(plcInfo.AddressEQP),
                ParseHexAddress(plcInfo.AddressECS) + (plcInfo.EQPId / 19) * 0x10,
                ParseHexAddress(plcInfo.AddressRobot),
                ParseHexAddress(plcInfo.AddressRobot2),
                ParseHexAddress(plcInfo.AddressEQPWrite),
                ParseHexAddress(plcInfo.AddressECSWrite),
                ParseHexAddress(plcInfo.AddressRobotWrite),
                ParseHexAddress(plcInfo.AddressRobotWrite2),
                ParseHexAddress(plcInfo.AddressDoorOpen));
            if (plcInfo.PollingInterval > 0)
                plcDriver.PollingInterval = plcInfo.PollingInterval;
            if (plcInfo.TimeoutConnection > 0)
                plcDriver.ConnectionTimeout = (uint)plcInfo.TimeoutConnection;
            if (configSvc.SystemInfo?.ECSTimeout > 0)
                plcDriver.EcsTimeout = (uint)configSvc.SystemInfo.ECSTimeout;
            plcDriver.Start();

            splash.UpdateProgress("Loading user interface...", 98);
            splash.Close();
            splash.Dispose();
            splash = null;

            // Flush all logs before MainForm — WebView2 초기화 중 크래시 대비
            appLogger.Info("[Startup] MainForm 생성 및 Application.Run 진입...");
            if (appLogger is AppLogger al1) al1.Flush();

            // ── Heartbeat timer — 30초마다 프로세스 상태 기록 (크래시 시점 특정용) ──
            var heartbeatDir = Path.Combine(AppContext.BaseDirectory, "LOG", "DebugLog");
            Directory.CreateDirectory(heartbeatDir);
            heartbeatTimer = new System.Threading.Timer(_ =>
            {
                try
                {
                    var proc = System.Diagnostics.Process.GetCurrentProcess();
                    var line = $"{DateTime.Now:HH:mm:ss.fff} alive " +
                               $"threads={proc.Threads.Count} " +
                               $"mem={proc.WorkingSet64 / 1024 / 1024}MB " +
                               $"handles={proc.HandleCount}\n";
                    File.AppendAllText(
                        Path.Combine(heartbeatDir, $"Heartbeat_{DateTime.Now:yyyyMMdd}.txt"), line);
                }
                catch { /* 하트비트 실패 시 무시 */ }
            }, null, TimeSpan.Zero, TimeSpan.FromSeconds(30));

            Application.Run(new MainForm(sp));
            appLogger.Info("[Startup] Application.Run 정상 종료");
        }
        catch (Exception ex)
        {
            // 초기화 또는 실행 중 예외 — 크래시 로그 기록
            var crashMsg = $"[FATAL] Program.Main 예외: {ex.GetType().Name}: {ex.Message}\n{ex.StackTrace}";
            try
            {
                if (sp?.GetService<IAppLogger>() is AppLogger logger)
                {
                    logger.Error(crashMsg);
                }
                var crashDir = Path.Combine(AppContext.BaseDirectory, "LOG", "DebugLog");
                Directory.CreateDirectory(crashDir);
                File.AppendAllText(
                    Path.Combine(crashDir, $"CrashLog_{DateTime.Now:yyyyMMdd}.txt"),
                    $"\n{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\n{crashMsg}\n");
            }
            catch { /* 로깅 실패 시 무시 */ }
        }
        finally
        {
            heartbeatTimer?.Dispose();

            // ── DPDK 정리 (DI dispose 전에 수행) ──
            // 순서: PgDpdkServer(RX 스레드 정지) → HwManager(ETH stop/close + EAL cleanup + hugepage 해제)
            try { pgTransport?.Dispose(); }
            catch { /* PG transport 정리 실패 시 무시 */ }

            try
            {
                if (HwManager.Instance.State == HwState.Ready ||
                    HwManager.Instance.State == HwState.Error)
                {
                    HwManager.Instance.Cleanup();
                }
            }
            catch { /* DPDK cleanup 실패 시 무시 */ }

            if (splash is { IsDisposed: false })
            {
                splash.Close();
                splash.Dispose();
            }
            (sp as IDisposable)?.Dispose(); // Dispose all singleton services (FlowCoordinator, etc.)
            _singleInstanceMutex?.ReleaseMutex();
            _singleInstanceMutex?.Dispose();
        }
    }

    /// <summary>
    /// Parses a PLC address hex string (e.g. "400" → 0x400).
    /// PLCInfo address fields store hex numbers without prefix.
    /// </summary>
    private static long ParseHexAddress(string? addr)
    {
        if (string.IsNullOrWhiteSpace(addr)) return 0;
        return long.TryParse(addr, NumberStyles.HexNumber, null, out var v) ? v : 0;
    }
}
