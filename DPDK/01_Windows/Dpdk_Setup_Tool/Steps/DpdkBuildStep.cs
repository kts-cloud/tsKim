using System.Text.RegularExpressions;
using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class DpdkBuildStep : SetupStepBase
{
    public override string Name => "DPDK 빌드";
    public override string Description => "DPDK 소스를 clone하고 meson/ninja로 빌드합니다 (15~30분 소요).";

    private ProgressBar? _buildProgress;
    private Label? _buildLabel;

    protected override void OnCreateContent(Panel panel)
    {
        _buildLabel = new Label
        {
            Dock = DockStyle.Top,
            Height = 30,
            Font = new Font("Segoe UI", 10f),
            ForeColor = Color.LightGray,
            TextAlign = ContentAlignment.MiddleLeft,
            Padding = new Padding(4, 0, 0, 0)
        };
        panel.Controls.Add(_buildLabel);

        _buildProgress = new ProgressBar
        {
            Dock = DockStyle.Top,
            Height = 22,
            Maximum = 100,
            Style = ProgressBarStyle.Continuous
        };
        panel.Controls.Add(_buildProgress);
        _buildProgress.BringToFront();
    }

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        string root = GetProjectRoot();
        string dpdkSrc = Path.Combine(root, "dpdk-src");
        string buildDir = Path.Combine(dpdkSrc, "build");

        // 1. Check tools
        UpdateBuild("도구 확인 중...", 0);
        LogInfo("[1/4] 필수 도구 확인...");

        foreach (var tool in new[] { "python", "clang", "meson", "ninja" })
        {
            ct.ThrowIfCancellationRequested();
            bool exists = await ProcessRunner.CommandExistsAsync(tool);
            if (!exists)
                throw new Exception($"{tool}이 PATH에 없습니다. Step 1 (소프트웨어 설치)을 먼저 실행하세요.");
            LogInfo($"  {tool}: OK");
        }

        ct.ThrowIfCancellationRequested();

        // 2. Clone DPDK
        UpdateBuild("DPDK 소스 확인 중...", 5);
        LogInfo("[2/4] DPDK 소스 코드...");

        if (!Directory.Exists(dpdkSrc))
        {
            LogInfo("  git clone 시작...");
            var cloneResult = await ProcessRunner.RunAsync("git",
                $"clone http://dpdk.org/git/dpdk \"{dpdkSrc}\"",
                workingDirectory: root,
                onOutputLine: s => LogInfo($"  {s}"),
                onErrorLine: s => LogInfo($"  {s}"),
                ct: ct);

            if (!cloneResult.Success)
                throw new Exception("DPDK clone 실패");
            LogSuccess("  Clone 완료");
        }
        else
        {
            LogInfo($"  dpdk-src 폴더 존재 — clone 건너뜀");
        }

        // Verify dpdk-src is valid
        if (!File.Exists(Path.Combine(dpdkSrc, "VERSION")) &&
            !File.Exists(Path.Combine(dpdkSrc, "meson.build")))
        {
            throw new Exception("dpdk-src 폴더가 유효하지 않습니다 (VERSION/meson.build 없음)");
        }

        ct.ThrowIfCancellationRequested();

        // 3. Meson setup
        UpdateBuild("Meson 설정 중...", 10);
        LogInfo("[3/4] Meson 설정...");

        if (Directory.Exists(buildDir))
        {
            LogInfo("  기존 build 폴더 삭제 중...");
            Directory.Delete(buildDir, true);
        }

        var envVars = new Dictionary<string, string>
        {
            ["CC"] = "clang",
            ["CXX"] = "clang"
        };

        var mesonResult = await ProcessRunner.RunAsync("meson",
            "setup build --default-library=shared",
            workingDirectory: dpdkSrc,
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct, envVars: envVars);

        if (!mesonResult.Success)
            throw new Exception("Meson setup 실패");

        LogSuccess("  Meson 설정 완료");

        ct.ThrowIfCancellationRequested();

        // 4. Ninja build
        UpdateBuild("Ninja 빌드 중...", 15);
        LogInfo("[4/4] Ninja 빌드 시작 (시간이 소요됩니다)...");

        var ninjaResult = await ProcessRunner.RunAsync("ninja",
            "-C build",
            workingDirectory: dpdkSrc,
            onOutputLine: s =>
            {
                // Parse ninja progress: [123/4567]
                var match = Regex.Match(s, @"\[(\d+)/(\d+)\]");
                if (match.Success)
                {
                    int current = int.Parse(match.Groups[1].Value);
                    int total = int.Parse(match.Groups[2].Value);
                    int percent = 15 + (int)(85.0 * current / total);
                    UpdateBuild($"빌드 중... [{current}/{total}]", Math.Min(percent, 100));
                }
                LogInfo($"  {s}");
            },
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct, envVars: envVars);

        // Core libraries that we actually need (Shim links against these)
        string libDir = Path.Combine(buildDir, "lib");
        var requiredLibs = new[]
        {
            "rte_eal.lib", "rte_ethdev.lib", "rte_mbuf.lib",
            "rte_mempool.lib", "rte_net.lib"
        };

        if (!ninjaResult.Success)
        {
            // Check if core libraries were built despite test app link failures
            var missingLibs = requiredLibs
                .Where(lib => !File.Exists(Path.Combine(libDir, lib)))
                .ToList();

            if (missingLibs.Count > 0)
            {
                foreach (var lib in missingLibs)
                    LogError($"  누락: {lib}");
                throw new Exception(
                    $"Ninja 빌드 실패 — 핵심 라이브러리 {missingLibs.Count}개 누락 (exit code: {ninjaResult.ExitCode})");
            }

            // Core libs exist — test apps failed (usual_getopt etc.) which is harmless
            LogWarning($"  Ninja exit code: {ninjaResult.ExitCode} (테스트 앱 링크 실패 — 핵심 라이브러리는 정상)");
        }

        // Final verification
        foreach (var lib in requiredLibs)
        {
            string libPath = Path.Combine(libDir, lib);
            if (!File.Exists(libPath))
                throw new Exception($"핵심 라이브러리 누락: {lib}");
        }

        UpdateBuild("빌드 완료!", 100);
        LogSuccess("DPDK 핵심 라이브러리 빌드 성공!");
        foreach (var lib in requiredLibs)
        {
            var fi = new FileInfo(Path.Combine(libDir, lib));
            LogInfo($"  ✓ {lib} ({fi.Length / 1024} KB)");
        }
    }

    private void UpdateBuild(string text, int percent)
    {
        if (_buildProgress?.InvokeRequired == true)
        {
            _buildProgress.BeginInvoke(() =>
            {
                _buildProgress.Value = Math.Min(percent, _buildProgress.Maximum);
            });
            _buildLabel?.BeginInvoke(() => { _buildLabel!.Text = $"  {text}"; });
        }
        else
        {
            if (_buildProgress != null) _buildProgress.Value = Math.Min(percent, _buildProgress.Maximum);
            if (_buildLabel != null) _buildLabel.Text = $"  {text}";
        }
    }
}
