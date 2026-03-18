using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class SoftwareInstallStep : SetupStepBase
{
    public override string Name => "소프트웨어 설치";
    public override string Description => "Chocolatey, Git, Python, LLVM, VS2022, WDK, .NET SDK를 설치합니다.";

    private readonly record struct SubStep(string Name, Func<SoftwareInstallStep, CancellationToken, Task> Action);

    private static readonly SubStep[] SubSteps =
    {
        new("Chocolatey 패키지 관리자", (s, ct) => s.InstallChocolatey(ct)),
        new("Git, Python, LLVM", (s, ct) => s.InstallBasics(ct)),
        new("VS2022 Build Tools", (s, ct) => s.InstallVS2022(ct)),
        new("Windows Driver Kit (WDK)", (s, ct) => s.InstallWdk(ct)),
        new("Python 패키지 (meson, ninja)", (s, ct) => s.InstallPythonPackages(ct)),
        new(".NET SDK", (s, ct) => s.InstallDotnetSdk(ct))
    };

    private ProgressBar? _progress;
    private Label? _subStepLabel;

    protected override void OnCreateContent(Panel panel)
    {
        _subStepLabel = new Label
        {
            Dock = DockStyle.Top,
            Height = 30,
            Font = new Font("Segoe UI", 10f),
            ForeColor = Color.LightGray,
            TextAlign = ContentAlignment.MiddleLeft,
            Padding = new Padding(4, 0, 0, 0)
        };
        panel.Controls.Add(_subStepLabel);

        _progress = new ProgressBar
        {
            Dock = DockStyle.Top,
            Height = 22,
            Maximum = SubSteps.Length,
            Style = ProgressBarStyle.Continuous
        };
        panel.Controls.Add(_progress);
        _progress.BringToFront();
    }

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        for (int i = 0; i < SubSteps.Length; i++)
        {
            ct.ThrowIfCancellationRequested();
            var sub = SubSteps[i];

            UpdateSubStep(i, sub.Name);
            LogInfo($"[{i + 1}/{SubSteps.Length}] {sub.Name} 설치 중...");

            try
            {
                await sub.Action(this, ct);
                LogSuccess($"  {sub.Name} 완료");
            }
            catch (OperationCanceledException) { throw; }
            catch (Exception ex)
            {
                LogWarning($"  {sub.Name} 실패 (계속 진행): {ex.Message}");
            }

            SystemInfo.ReloadEnvironmentPath();
        }

        LogSuccess("소프트웨어 설치 완료");
    }

    private void UpdateSubStep(int index, string name)
    {
        if (_progress?.InvokeRequired == true)
        {
            _progress.BeginInvoke(() => { _progress.Value = index; });
            _subStepLabel?.BeginInvoke(() => { _subStepLabel!.Text = $"  [{index + 1}/{SubSteps.Length}] {name}"; });
        }
        else
        {
            if (_progress != null) _progress.Value = index;
            if (_subStepLabel != null) _subStepLabel.Text = $"  [{index + 1}/{SubSteps.Length}] {name}";
        }
    }

    private async Task InstallChocolatey(CancellationToken ct)
    {
        if (await ProcessRunner.CommandExistsAsync("choco"))
        {
            LogInfo("  Chocolatey 이미 설치됨");
            return;
        }

        var result = await ProcessRunner.RunPowerShellAsync(
            "Set-ExecutionPolicy Bypass -Scope Process -Force; " +
            "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; " +
            "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!result.Success)
            throw new Exception($"Chocolatey 설치 실패 (exit {result.ExitCode})");
    }

    private async Task InstallBasics(CancellationToken ct)
    {
        // Check each tool individually
        string[] tools = { "git", "python", "llvm" };
        var toInstall = new List<string>();

        foreach (var tool in tools)
        {
            string checkCmd = tool == "llvm" ? "clang" : tool;
            if (!await ProcessRunner.CommandExistsAsync(checkCmd))
                toInstall.Add(tool);
            else
                LogInfo($"  {tool} 이미 설치됨");
        }

        if (toInstall.Count == 0) return;

        string packages = string.Join(" ", toInstall);
        var result = await ProcessRunner.RunAsync("choco", $"install {packages} -y",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!result.Success)
            throw new Exception($"패키지 설치 실패: {packages}");
    }

    private async Task InstallVS2022(CancellationToken ct)
    {
        // Check if already installed
        var checkResult = await ProcessRunner.RunPowerShellAsync(
            "Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7' -Name '17.0' -ErrorAction SilentlyContinue");
        if (checkResult.Success && checkResult.Output.Contains("17.0"))
        {
            LogInfo("  VS2022 Build Tools 이미 설치됨");
            return;
        }

        var result = await ProcessRunner.RunAsync("choco",
            "install visualstudio2022buildtools -y --package-parameters \"--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended\"",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!result.Success)
            LogWarning("  VS2022 Build Tools 설치 실패 — 수동 설치 필요할 수 있음");
    }

    private async Task InstallWdk(CancellationToken ct)
    {
        if (WdkLocator.IsInstalled())
        {
            LogInfo($"  WDK 이미 설치됨 ({string.Join(", ", WdkLocator.GetInstalledVersions().Take(2))})");
            return;
        }

        // Attempt 1: choco
        LogInfo("  시도 1: Chocolatey로 WDK 설치...");
        var result = await ProcessRunner.RunAsync("choco", "install windows-driver-kit -y",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        SystemInfo.ReloadEnvironmentPath();
        if (WdkLocator.IsInstalled())
        {
            LogSuccess("  WDK choco 설치 성공");
            return;
        }

        // Attempt 2: winget
        LogInfo("  시도 2: winget으로 WDK 설치...");
        if (await ProcessRunner.CommandExistsAsync("winget"))
        {
            result = await ProcessRunner.RunAsync("winget",
                "install -e --id Microsoft.WindowsDriverKit --accept-package-agreements --accept-source-agreements",
                onOutputLine: s => LogInfo($"  {s}"),
                onErrorLine: s => LogWarning($"  {s}"),
                ct: ct);

            SystemInfo.ReloadEnvironmentPath();
            if (WdkLocator.IsInstalled())
            {
                LogSuccess("  WDK winget 설치 성공");
                return;
            }
        }

        // Attempt 3: Manual
        LogWarning("  자동 설치 실패 — 수동 설치 필요:");
        LogWarning("  https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk");
        LogWarning("  설치 후 이 스텝을 다시 실행하세요.");
    }

    private async Task InstallPythonPackages(CancellationToken ct)
    {
        var result = await ProcessRunner.RunAsync("pip", "install meson ninja pyelftools",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!result.Success)
            throw new Exception("Python 패키지 설치 실패");
    }

    private async Task InstallDotnetSdk(CancellationToken ct)
    {
        if (await ProcessRunner.CommandExistsAsync("dotnet"))
        {
            LogInfo("  .NET SDK 이미 설치됨");
            return;
        }

        var result = await ProcessRunner.RunAsync("choco", "install dotnet-sdk -y",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!result.Success)
            throw new Exception(".NET SDK 설치 실패");
    }
}
