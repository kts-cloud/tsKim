using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class DpdkNetBuildStep : SetupStepBase
{
    public override string Name => "HwNet 빌드";
    public override string Description => "HwNet.dll (C# 관리 래퍼)을 빌드합니다.";

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        string root = GetProjectRoot();
        string dpdkNetDir = Path.Combine(root, "DpdkNet");
        string csproj = Path.Combine(dpdkNetDir, "DpdkNet.csproj");
        string buildOutputDir = Path.Combine(root, "_build");
        Directory.CreateDirectory(buildOutputDir);

        // 1. Verify DpdkNet project exists
        LogInfo("[1/3] HwNet 프로젝트 확인...");
        if (!File.Exists(csproj))
        {
            throw new Exception(
                $"DpdkNet.csproj를 찾을 수 없습니다.\n" +
                $"HwNet(DpdkNet) 폴더를 현장 PC에 복사하세요:\n" +
                $"  원본: <개발PC>\\DPDK\\01_Windows\\DpdkNet\\\n" +
                $"  대상: {dpdkNetDir}\\");
        }
        LogSuccess("  DpdkNet.csproj 확인됨");

        ct.ThrowIfCancellationRequested();

        // 2. Verify .NET SDK is available
        LogInfo("[2/3] .NET SDK 확인...");
        var sdkCheck = await ProcessRunner.RunAsync("dotnet", "--version",
            workingDirectory: root,
            onOutputLine: s => LogInfo($"  .NET SDK: {s}"),
            onErrorLine: s => { },
            ct: ct);

        if (!sdkCheck.Success)
        {
            throw new Exception(
                "dotnet SDK가 설치되어 있지 않습니다.\n" +
                ".NET 8.0 SDK를 설치하세요: https://dotnet.microsoft.com/download/dotnet/8.0");
        }
        LogSuccess("  .NET SDK 확인됨");

        ct.ThrowIfCancellationRequested();

        // 3. Build HwNet.dll
        LogInfo("[3/3] HwNet.dll 빌드 시작...");
        string outputDir = Path.Combine(buildOutputDir, "DpdkNet");

        var result = await ProcessRunner.RunAsync("dotnet",
            $"publish \"{csproj}\" -c Release -r win-x64 --self-contained false -o \"{outputDir}\"",
            workingDirectory: root,
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        string outDll = Path.Combine(outputDir, "HwNet.dll");

        if (!result.Success || !File.Exists(outDll))
            throw new Exception($"HwNet.dll 빌드 실패 (exit code: {result.ExitCode})");

        var fileInfo = new FileInfo(outDll);
        LogSuccess($"HwNet.dll 빌드 성공 ({fileInfo.Length / 1024} KB)");
        LogInfo($"  출력: {outputDir}");
    }
}
