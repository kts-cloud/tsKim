using System.Diagnostics;
using System.Text;

namespace DpdkSetupTool.Utils;

public class ProcessResult
{
    public int ExitCode { get; init; }
    public string Output { get; init; } = "";
    public string Error { get; init; } = "";
    public bool Success => ExitCode == 0;
}

public static class ProcessRunner
{
    /// <summary>
    /// Run a process asynchronously with real-time stdout/stderr streaming.
    /// </summary>
    public static async Task<ProcessResult> RunAsync(
        string fileName, string arguments,
        string? workingDirectory = null,
        Action<string>? onOutputLine = null,
        Action<string>? onErrorLine = null,
        CancellationToken ct = default,
        Dictionary<string, string>? envVars = null)
    {
        var psi = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            WorkingDirectory = workingDirectory ?? ""
        };

        if (envVars != null)
        {
            foreach (var kv in envVars)
                psi.Environment[kv.Key] = kv.Value;
        }

        var sbOut = new StringBuilder();
        var sbErr = new StringBuilder();

        using var process = new Process { StartInfo = psi, EnableRaisingEvents = true };

        var tcsExit = new TaskCompletionSource<int>();
        process.Exited += (_, _) =>
        {
            try { tcsExit.TrySetResult(process.ExitCode); }
            catch { tcsExit.TrySetResult(-999); }
        };

        process.OutputDataReceived += (_, e) =>
        {
            if (e.Data == null) return;
            sbOut.AppendLine(e.Data);
            onOutputLine?.Invoke(e.Data);
        };

        process.ErrorDataReceived += (_, e) =>
        {
            if (e.Data == null) return;
            sbErr.AppendLine(e.Data);
            onErrorLine?.Invoke(e.Data);
        };

        process.Start();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        using var reg = ct.Register(() =>
        {
            try { process.Kill(entireProcessTree: true); } catch { }
        });

        int exitCode = await tcsExit.Task;

        // Small delay for final output flush
        await Task.Delay(50, CancellationToken.None);

        return new ProcessResult
        {
            ExitCode = exitCode,
            Output = sbOut.ToString(),
            Error = sbErr.ToString()
        };
    }

    /// <summary>
    /// Run a PowerShell command.
    /// </summary>
    public static Task<ProcessResult> RunPowerShellAsync(
        string command,
        string? workingDirectory = null,
        Action<string>? onOutputLine = null,
        Action<string>? onErrorLine = null,
        CancellationToken ct = default)
    {
        return RunAsync(
            "powershell.exe",
            $"-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"{command.Replace("\"", "\\\"")}\"",
            workingDirectory, onOutputLine, onErrorLine, ct);
    }

    /// <summary>
    /// Run a PowerShell script file.
    /// </summary>
    public static Task<ProcessResult> RunPowerShellScriptAsync(
        string scriptPath,
        string arguments = "",
        string? workingDirectory = null,
        Action<string>? onOutputLine = null,
        Action<string>? onErrorLine = null,
        CancellationToken ct = default)
    {
        return RunAsync(
            "powershell.exe",
            $"-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"{scriptPath}\" {arguments}",
            workingDirectory, onOutputLine, onErrorLine, ct);
    }

    /// <summary>
    /// Check if a command exists in PATH.
    /// </summary>
    public static async Task<bool> CommandExistsAsync(string command)
    {
        var result = await RunAsync("where.exe", command);
        return result.Success && !string.IsNullOrWhiteSpace(result.Output);
    }

    /// <summary>
    /// Get the path of a command via where.exe.
    /// </summary>
    public static async Task<string?> WhichAsync(string command)
    {
        var result = await RunAsync("where.exe", command);
        if (!result.Success) return null;
        return result.Output.Split('\n', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault()?.Trim();
    }

    /// <summary>
    /// Reload PATH from registry (Machine + User).
    /// </summary>
    public static void ReloadEnvironmentPath()
    {
        string machinePath = Environment.GetEnvironmentVariable("PATH",
            EnvironmentVariableTarget.Machine) ?? "";
        string userPath = Environment.GetEnvironmentVariable("PATH",
            EnvironmentVariableTarget.User) ?? "";
        Environment.SetEnvironmentVariable("PATH", $"{machinePath};{userPath}");
    }
}
