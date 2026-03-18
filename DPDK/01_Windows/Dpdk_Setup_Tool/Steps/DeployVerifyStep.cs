using System.IO.Compression;
using System.Security.Cryptography;
using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class DeployVerifyStep : SetupStepBase
{
    public override string Name => "배포 & 검증";
    public override string Description => "필수 DLL 수집, drivers.dat 암호화 아카이브, HwNet 빌드, dpdk_diag 진단을 수행합니다.";

    // Shared deploy folder path — created in Step 1, used by Step 3 to add HwNet.dll
    private string _deployDir = "";

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        string root = GetProjectRoot();
        string dpdkSrc = Path.Combine(root, "dpdk-src");
        string buildLib = Path.Combine(dpdkSrc, "build", "lib");
        string buildDrivers = Path.Combine(dpdkSrc, "build", "drivers");
        string buildOutputDir = Path.Combine(root, "_build");

        // Create timestamped deploy folder
        string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
        _deployDir = Path.Combine(root, "_build", $"deploy_{timestamp}");
        Directory.CreateDirectory(_deployDir);

        // ===== Step 1: Collect all DLLs into deploy folder =====
        LogInfo("[1/5] DLL 수집 (배포 폴더)...");
        LogInfo($"  배포 폴더: {_deployDir}");

        int collected = 0;

        // Collect from dpdk-src/build/lib or _build (fallback)
        string dllSourceDir;
        if (Directory.Exists(buildLib))
            dllSourceDir = buildLib;
        else if (Directory.Exists(buildOutputDir) && Directory.GetFiles(buildOutputDir, "rte_*.dll").Length > 0)
            dllSourceDir = buildOutputDir;
        else
            throw new Exception($"DLL 소스 폴더가 없습니다.\n  1차: {buildLib}\n  2차: {buildOutputDir}");

        foreach (var dll in Directory.GetFiles(dllSourceDir, "*.dll"))
        {
            File.Copy(dll, Path.Combine(_deployDir, Path.GetFileName(dll)), true);
            collected++;
        }
        LogInfo($"  소스(lib): {dllSourceDir} → {collected}개");

        // Collect from dpdk-src/build/drivers
        if (Directory.Exists(buildDrivers))
        {
            int driverCount = 0;
            foreach (var dll in Directory.GetFiles(buildDrivers, "*.dll"))
            {
                File.Copy(dll, Path.Combine(_deployDir, Path.GetFileName(dll)), true);
                driverCount++;
                collected++;
            }
            LogInfo($"  소스(drivers): {buildDrivers} → {driverCount}개");
        }

        // Copy hwio.dll
        string? shimDll = new[] { Path.Combine(buildOutputDir, "hwio.dll"), Path.Combine(root, "hwio.dll") }
            .FirstOrDefault(File.Exists);
        if (shimDll != null)
        {
            File.Copy(shimDll, Path.Combine(_deployDir, "hwio.dll"), true);
            collected++;
            LogInfo($"  hwio.dll 포함");
        }
        else
        {
            LogWarning("  hwio.dll이 없습니다 — Step 4 (Shim 빌드)를 실행하세요");
        }

        LogSuccess($"  배포 폴더에 {collected}개 DLL 수집 완료");

        ct.ThrowIfCancellationRequested();

        // ===== Step 2: Build & deploy HwNet.dll =====
        LogInfo("[2/5] HwNet.dll 빌드 & 배포...");
        await BuildAndDeployDpdkNet(root, ct);

        ct.ThrowIfCancellationRequested();

        // ===== Step 3: Generate drivers.dat (encrypted archive) =====
        LogInfo("[3/5] drivers.dat 암호화 아카이브 생성...");
        await GenerateDriversDat(root, _deployDir, ct);

        // drivers.dat 생성 완료 → 배포 폴더에서 rte_*.dll 제거 (drivers.dat에 포함됨)
        // hwio.dll, HwNet.dll은 앱 실행에 직접 필요하므로 유지
        int removed = 0;
        foreach (var dll in Directory.GetFiles(_deployDir, "*.dll"))
        {
            string name = Path.GetFileName(dll);
            if (name.Equals("HwNet.dll", StringComparison.OrdinalIgnoreCase) ||
                name.Equals("hwio.dll", StringComparison.OrdinalIgnoreCase))
                continue;
            File.Delete(dll);
            removed++;
        }
        if (removed > 0)
            LogInfo($"  배포 폴더에서 rte_*.dll {removed}개 제거 (drivers.dat에 포함)");

        ct.ThrowIfCancellationRequested();

        // ===== Step 4: Build dpdk_diag.exe =====
        LogInfo("[4/5] dpdk_diag.exe 빌드...");
        await BuildDiag(root, ct);

        ct.ThrowIfCancellationRequested();

        // ===== Step 5: Run diagnostics =====
        LogInfo("[5/5] dpdk_diag 진단 실행...");
        string diagDir = Path.Combine(root, "_build");
        await RunDiag(root, diagDir, ct);

        // Final summary
        LogSuccess("배포 & 검증 완료!");
        LogSuccess($"  ★ 배포 폴더: {_deployDir}");

        // List deploy folder contents
        var deployFiles = Directory.GetFiles(_deployDir);
        long totalSize = deployFiles.Sum(f => new FileInfo(f).Length);
        LogInfo($"  ★ 파일 {deployFiles.Length}개, 총 {totalSize / 1024 / 1024} MB");
        LogInfo($"  ★ 앱 실행 폴더에 drivers.dat + HwNet.dll만 복사하면 됩니다.");
    }

    /// <summary>
    /// Build HwNet.dll and deploy to src_X3584_CSharp/DpdkNet_lib/ and deploy folder.
    /// ITOLED.OC.csproj references ../DpdkNet_lib/HwNet.dll.
    /// </summary>
    private async Task BuildAndDeployDpdkNet(string root, CancellationToken ct)
    {
        string dpdkNetProject = Path.Combine(root, "DpdkNet", "DpdkNet.csproj");

        if (!File.Exists(dpdkNetProject))
        {
            LogWarning($"  DpdkNet.csproj 없음: {dpdkNetProject}");
            return;
        }

        // Build HwNet
        var buildResult = await ProcessRunner.RunAsync("dotnet",
            $"build \"{dpdkNetProject}\" -c Release",
            workingDirectory: root,
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!buildResult.Success)
        {
            LogError($"  HwNet 빌드 실패 (exit: {buildResult.ExitCode})");
            return;
        }

        // Find built DLL — check multiple TFM possibilities
        string? builtDll = new[]
        {
            Path.Combine(root, "DpdkNet", "bin", "Release", "net8.0-windows", "HwNet.dll"),
            Path.Combine(root, "DpdkNet", "bin", "Release", "net9.0-windows", "HwNet.dll"),
        }.FirstOrDefault(File.Exists);

        if (builtDll == null)
        {
            // Fallback: search for any HwNet.dll in Release folder
            string releaseDir = Path.Combine(root, "DpdkNet", "bin", "Release");
            if (Directory.Exists(releaseDir))
                builtDll = Directory.GetFiles(releaseDir, "HwNet.dll", SearchOption.AllDirectories).FirstOrDefault();
        }

        if (builtDll == null)
        {
            LogWarning("  HwNet.dll 빌드 출력을 찾을 수 없습니다.");
            return;
        }

        // Deploy to DpdkNet_lib/
        string? solutionRoot = FindSolutionRoot(root);
        if (solutionRoot != null)
        {
            string dpdkNetLibDir = Path.Combine(solutionRoot, "src_X3584_CSharp", "DpdkNet_lib");
            Directory.CreateDirectory(dpdkNetLibDir);
            File.Copy(builtDll, Path.Combine(dpdkNetLibDir, "HwNet.dll"), true);
            LogSuccess($"  HwNet.dll 배포 완료 → {dpdkNetLibDir}");
        }
        else
        {
            LogWarning("  src_X3584_CSharp 폴더를 찾을 수 없습니다. DpdkNet_lib 배포 건너뜀.");
        }

        // Also copy to deploy folder
        if (!string.IsNullOrEmpty(_deployDir) && Directory.Exists(_deployDir))
        {
            File.Copy(builtDll, Path.Combine(_deployDir, "HwNet.dll"), true);
            LogInfo($"  HwNet.dll → 배포 폴더에도 복사");
        }
    }

    /// <summary>
    /// Find the project solution root (contains src_X3584_CSharp/).
    /// root = DPDK/01_Windows → solution root = root/../../
    /// </summary>
    private static string? FindSolutionRoot(string dpdkRoot)
    {
        // root = .../ITOLED_OC/DPDK/01_Windows → go up 2 levels
        string? candidate = Path.GetDirectoryName(Path.GetDirectoryName(dpdkRoot));
        if (candidate != null && Directory.Exists(Path.Combine(candidate, "src_X3584_CSharp")))
            return candidate;

        // Fallback: search upward
        string? dir = dpdkRoot;
        for (int i = 0; i < 5 && dir != null; i++)
        {
            dir = Path.GetDirectoryName(dir);
            if (dir != null && Directory.Exists(Path.Combine(dir, "src_X3584_CSharp")))
                return dir;
        }

        return null;
    }

    private async Task BuildDiag(string root, CancellationToken ct)
    {
        string shimDir = Path.Combine(root, "DpdkShim");
        string diagSrc = Path.Combine(shimDir, "dpdk_diag.c");
        string buildOutputDir = Path.Combine(root, "_build");
        Directory.CreateDirectory(buildOutputDir);
        string diagExe = Path.Combine(buildOutputDir, "dpdk_diag.exe");
        string dpdkSrc = Path.Combine(root, "dpdk-src");
        string buildDir = Path.Combine(dpdkSrc, "build");
        string libPath = Path.Combine(buildDir, "lib");

        if (!File.Exists(diagSrc))
        {
            LogWarning("  dpdk_diag.c가 없습니다. 건너뜁니다.");
            return;
        }

        // Build include paths
        var includePaths = new List<string>();
        if (Directory.Exists(Path.Combine(dpdkSrc, "lib")))
        {
            foreach (var dir in Directory.GetDirectories(Path.Combine(dpdkSrc, "lib"), "*", SearchOption.AllDirectories))
                includePaths.Add($"-I\"{dir}\"");
        }

        string? wdkLibPath = WdkLocator.FindLibPath("x64");
        string wdkLink = wdkLibPath != null ? $"-L\"{wdkLibPath}\"" : "";

        var args = new List<string>
        {
            "-m64", "-march=native", "-mssse3",
            "-o", $"\"{diagExe}\"",
            $"\"{diagSrc}\"",
            $"-I\"{shimDir}\"",
            $"-I\"{buildDir}\"",
            $"-I\"{Path.Combine(buildDir, "include")}\"",
            $"-I\"{Path.Combine(dpdkSrc, "lib", "eal", "windows", "include")}\"",
            $"-I\"{Path.Combine(dpdkSrc, "lib", "eal", "x86", "include")}\"",
            $"-I\"{Path.Combine(dpdkSrc, "config")}\""
        };
        args.AddRange(includePaths);
        args.AddRange(new[]
        {
            "-D_CRT_SECURE_NO_WARNINGS",
            "-D__PCAP_LIB__", "-DRTE_MAX_ETHPORTS=32", "-D_WIN32",
            $"\"{Path.Combine(libPath, "rte_eal.lib")}\"",
            $"\"{Path.Combine(libPath, "rte_ethdev.lib")}\"",
            $"\"{Path.Combine(libPath, "rte_mbuf.lib")}\"",
            $"\"{Path.Combine(libPath, "rte_mempool.lib")}\"",
            $"\"{Path.Combine(libPath, "rte_net.lib")}\"",
            wdkLink,
            "-lAdvAPI32"
        });

        var result = await ProcessRunner.RunAsync("clang",
            string.Join(" ", args),
            workingDirectory: root,
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (result.Success && File.Exists(diagExe))
            LogSuccess("  dpdk_diag.exe 빌드 성공");
        else
            LogWarning("  dpdk_diag.exe 빌드 실패 (비치명적)");
    }

    /// <summary>
    /// Generate drivers.dat: AES-256-CBC encrypted ZIP of all rte_*.dll + hwio.dll.
    /// Output goes to both _build/ and deploy folder.
    /// </summary>
    private Task GenerateDriversDat(string root, string deployDir, CancellationToken ct)
    {
        // AES-256 key: "OCINSP_HWNET_KEY1234567890ABCDEFG" (must match HwManager.DeriveKey)
        byte[] key = {
            0x4F, 0x43, 0x49, 0x4E, 0x53, 0x50, 0x5F, 0x48,
            0x57, 0x4E, 0x45, 0x54, 0x5F, 0x4B, 0x45, 0x59,
            0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
            0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
        };

        // Collect DLL files from deploy folder (already gathered in Step 1)
        var dllFiles = Directory.GetFiles(deployDir, "*.dll");
        if (dllFiles.Length == 0)
        {
            LogWarning("  배포 폴더에 DLL이 없습니다. drivers.dat 생성 건너뜀.");
            return Task.CompletedTask;
        }

        LogInfo($"  {dllFiles.Length}개 DLL → ZIP 압축...");

        // Create ZIP in memory
        byte[] zipData;
        using (var zipStream = new MemoryStream())
        {
            using (var archive = new ZipArchive(zipStream, ZipArchiveMode.Create, leaveOpen: true))
            {
                foreach (var dll in dllFiles)
                {
                    ct.ThrowIfCancellationRequested();
                    archive.CreateEntryFromFile(dll, Path.GetFileName(dll), CompressionLevel.Optimal);
                }
            }
            zipData = zipStream.ToArray();
        }

        LogInfo($"  ZIP 크기: {zipData.Length / 1024 / 1024} MB → AES-256 암호화...");

        // Encrypt with AES-256-CBC
        using var aes = Aes.Create();
        aes.Key = key;
        aes.GenerateIV();
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        using var encryptor = aes.CreateEncryptor();
        byte[] encrypted = encryptor.TransformFinalBlock(zipData, 0, zipData.Length);

        // Output: [16 bytes IV] + [encrypted data]
        byte[] output = new byte[16 + encrypted.Length];
        Array.Copy(aes.IV, 0, output, 0, 16);
        Array.Copy(encrypted, 0, output, 16, encrypted.Length);

        // Write to _build/ and deploy folder
        string buildOutputDir = Path.Combine(root, "_build");
        Directory.CreateDirectory(buildOutputDir);

        string datPath = Path.Combine(buildOutputDir, "drivers.dat");
        File.WriteAllBytes(datPath, output);
        LogSuccess($"  drivers.dat 생성 완료: {datPath} ({output.Length / 1024 / 1024} MB)");

        // Also copy to deploy folder
        string deployDatPath = Path.Combine(deployDir, "drivers.dat");
        File.Copy(datPath, deployDatPath, true);
        LogInfo($"  drivers.dat → 배포 폴더에도 복사");

        // Deploy to DPDK_lib if solution root exists
        string? solutionRoot = FindSolutionRoot(root);
        if (solutionRoot != null)
        {
            string dpdkLibDir = Path.Combine(solutionRoot, "src_X3584_CSharp", "DPDK_lib");
            Directory.CreateDirectory(dpdkLibDir);
            File.Copy(datPath, Path.Combine(dpdkLibDir, "drivers.dat"), true);

            // 기존 개별 DLL 정리 (drivers.dat로 대체됨)
            int cleaned = 0;
            foreach (var oldDll in Directory.GetFiles(dpdkLibDir, "*.dll"))
            {
                File.Delete(oldDll);
                cleaned++;
            }
            if (cleaned > 0)
                LogInfo($"  DPDK_lib에서 기존 DLL {cleaned}개 제거");
            LogInfo($"  drivers.dat → DPDK_lib에 배포 완료");
        }

        return Task.CompletedTask;
    }

    private async Task RunDiag(string root, string targetDir, CancellationToken ct)
    {
        // Check _build/ first, then root (legacy)
        string? diagExe = new[] { Path.Combine(root, "_build", "dpdk_diag.exe"), Path.Combine(root, "dpdk_diag.exe") }
            .FirstOrDefault(File.Exists);

        if (diagExe == null)
        {
            LogWarning("  dpdk_diag.exe가 없어 진단을 건너뜁니다.");
            return;
        }

        // Ensure DPDK DLLs are in same directory as diag exe
        string diagDir = Path.GetDirectoryName(diagExe) ?? root;
        string buildLib = Path.Combine(root, "dpdk-src", "build", "lib");
        string buildOutputDir2 = Path.Combine(root, "_build");
        string dllDir = Directory.Exists(buildLib) ? buildLib : buildOutputDir2;
        if (Directory.Exists(dllDir))
        {
            foreach (var dll in Directory.GetFiles(dllDir, "*.dll"))
                File.Copy(dll, Path.Combine(diagDir, Path.GetFileName(dll)), true);
        }

        var result = await ProcessRunner.RunAsync(diagExe, "",
            workingDirectory: diagDir,
            onOutputLine: s =>
            {
                if (s.Contains("SUCCESS", StringComparison.OrdinalIgnoreCase))
                    LogSuccess($"  {s}");
                else if (s.Contains("FAIL", StringComparison.OrdinalIgnoreCase) ||
                         s.Contains("CRASH", StringComparison.OrdinalIgnoreCase))
                    LogError($"  {s}");
                else
                    LogInfo($"  {s}");
            },
            onErrorLine: s => LogError($"  {s}"),
            ct: ct);

        if (result.Success)
            LogSuccess("  dpdk_diag 진단 완료 (SUCCESS)");
        else
            LogWarning($"  dpdk_diag 종료 코드: {result.ExitCode}");
    }
}
