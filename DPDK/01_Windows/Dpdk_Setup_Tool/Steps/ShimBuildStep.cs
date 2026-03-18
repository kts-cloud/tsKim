using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class ShimBuildStep : SetupStepBase
{
    public override string Name => "HW IO 빌드";
    public override string Description => "hwio.dll을 clang으로 빌드합니다.";

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        string root = GetProjectRoot();
        string dpdkSrc = Path.Combine(root, "dpdk-src");
        string buildDir = Path.Combine(dpdkSrc, "build");
        string shimDir = Path.Combine(root, "DpdkShim");
        string shimSrc = Path.Combine(shimDir, "hwio.c");
        string netifSrc = Path.Combine(shimDir, "dpdk_netif.c");
        string ftpSrc = Path.Combine(shimDir, "dpdk_ftp_client.c");
        string lwipDir = Path.Combine(shimDir, "lwip-2.2.1", "src");
        string buildOutputDir = Path.Combine(root, "_build");
        Directory.CreateDirectory(buildOutputDir);
        string outDll = Path.Combine(buildOutputDir, "hwio.dll");

        // 1. Verify DPDK build and all source files exist
        LogInfo("[1/3] DPDK 빌드 및 소스 파일 확인...");
        if (!File.Exists(Path.Combine(buildDir, "build.ninja")))
            throw new Exception("DPDK 빌드가 없습니다. Step 3 (DPDK 빌드)을 먼저 실행하세요.");

        var missingFiles = new List<string>();
        if (!File.Exists(shimSrc)) missingFiles.Add(shimSrc);
        if (!File.Exists(netifSrc)) missingFiles.Add(netifSrc);
        if (!File.Exists(ftpSrc)) missingFiles.Add(ftpSrc);
        if (!Directory.Exists(lwipDir))
            missingFiles.Add($"{lwipDir} (lwIP 디렉토리)");

        if (missingFiles.Count > 0)
        {
            foreach (var f in missingFiles)
                LogError($"  누락: {f}");
            throw new Exception(
                $"DpdkShim 소스 파일 {missingFiles.Count}개 누락.\n" +
                $"DpdkShim 폴더 전체를 현장 PC에 복사하세요:\n" +
                $"  원본: <개발PC>\\DPDK\\01_Windows\\DpdkShim\\\n" +
                $"  대상: {shimDir}\\");
        }
        LogSuccess("  DPDK 빌드 및 모든 소스 파일 확인됨");

        ct.ThrowIfCancellationRequested();

        // 2. Find WDK lib path dynamically
        LogInfo("[2/3] WDK lib 경로 탐색...");
        string? wdkLibPath = WdkLocator.FindLibPath("x64");
        if (wdkLibPath == null)
        {
            LogWarning("  WDK lib 경로를 찾을 수 없습니다. AdvAPI32 링크가 실패할 수 있습니다.");
            wdkLibPath = @"C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64";
        }
        LogInfo($"  WDK lib: {wdkLibPath}");

        ct.ThrowIfCancellationRequested();

        // 3. Build include paths dynamically
        LogInfo("[3/3] Clang 빌드 시작...");
        var includePaths = new List<string>();

        // Recursively find all lib subdirs for includes
        if (Directory.Exists(Path.Combine(dpdkSrc, "lib")))
        {
            foreach (var dir in Directory.GetDirectories(Path.Combine(dpdkSrc, "lib"), "*", SearchOption.AllDirectories))
                includePaths.Add($"-I{Quote(dir)}");
        }

        string libPath = Path.Combine(buildDir, "lib");

        // Gather lwIP source files
        var lwipSources = new List<string>();
        string lwipCoreDir = Path.Combine(lwipDir, "core");
        string lwipIpv4Dir = Path.Combine(lwipCoreDir, "ipv4");
        if (Directory.Exists(lwipCoreDir))
        {
            foreach (var f in Directory.GetFiles(lwipCoreDir, "*.c"))
                lwipSources.Add(Quote(f));
        }
        if (Directory.Exists(lwipIpv4Dir))
        {
            foreach (var f in Directory.GetFiles(lwipIpv4Dir, "*.c"))
                lwipSources.Add(Quote(f));
        }
        string lwipEthernet = Path.Combine(lwipDir, "netif", "ethernet.c");
        if (File.Exists(lwipEthernet))
            lwipSources.Add(Quote(lwipEthernet));

        // Build args list (one arg per line for response file)
        var clangArgs = new List<string>
        {
            "-shared",
            "-m64",
            "-march=native",
            "-mssse3",
            "-Wno-unused-parameter",
            "-Wno-unused-variable",
            $"-o {Quote(outDll)}",
            // Source files
            Quote(shimSrc),
            Quote(netifSrc),
            Quote(ftpSrc),
            // Include paths
            $"-I{Quote(shimDir)}",
            $"-I{Quote(Path.Combine(shimDir, "arch"))}",
            $"-I{Quote(Path.Combine(lwipDir, "include"))}",
            $"-I{Quote(buildDir)}",
            $"-I{Quote(Path.Combine(buildDir, "include"))}",
            $"-I{Quote(Path.Combine(dpdkSrc, "lib", "eal", "windows", "include"))}",
            $"-I{Quote(Path.Combine(dpdkSrc, "lib", "eal", "x86", "include"))}",
            $"-I{Quote(Path.Combine(dpdkSrc, "config"))}"
        };

        // lwIP sources
        clangArgs.AddRange(lwipSources);

        // DPDK lib include paths
        clangArgs.AddRange(includePaths);

        clangArgs.AddRange(new[]
        {
            "-D_CRT_SECURE_NO_WARNINGS",
            "-DSSIZE_MAX=9223372036854775807LL",
            "-D__PCAP_LIB__",
            "-DRTE_MAX_ETHPORTS=32",
            "-D_WIN32",
            Quote(Path.Combine(libPath, "rte_eal.lib")),
            Quote(Path.Combine(libPath, "rte_ethdev.lib")),
            Quote(Path.Combine(libPath, "rte_mbuf.lib")),
            Quote(Path.Combine(libPath, "rte_mempool.lib")),
            Quote(Path.Combine(libPath, "rte_net.lib")),
            Quote(Path.Combine(libPath, "rte_ring.lib")),
            $"-L{Quote(wdkLibPath)}",
            "-lAdvAPI32"
        });

        LogInfo($"  소스 파일: 3 + lwIP {lwipSources.Count}개, include 경로: {includePaths.Count}개");

        // Write response file to avoid Windows command line length limit (~8191 chars)
        string rspFile = Path.Combine(buildOutputDir, "clang_args.rsp");
        await File.WriteAllLinesAsync(rspFile, clangArgs, ct);
        LogInfo($"  Response file: {rspFile} ({clangArgs.Count} args)");

        var result = await ProcessRunner.RunAsync("clang", $"@\"{rspFile}\"",
            workingDirectory: root,
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!result.Success || !File.Exists(outDll))
            throw new Exception($"HW IO DLL 빌드 실패 (exit code: {result.ExitCode})");

        var fileInfo = new FileInfo(outDll);
        LogSuccess($"hwio.dll 빌드 성공 ({fileInfo.Length / 1024} KB)");
    }

    private static string Quote(string path) => $"\"{path.Replace('\\', '/')}\"";
}
