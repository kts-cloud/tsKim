using Microsoft.Win32;

namespace DpdkSetupTool.Utils;

public static class SystemInfo
{
    /// <summary>
    /// Check if running as Administrator.
    /// </summary>
    public static bool IsAdmin()
    {
        using var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
        var principal = new System.Security.Principal.WindowsPrincipal(identity);
        return principal.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator);
    }

    /// <summary>
    /// Get Windows edition (Pro, Enterprise, Home, etc.)
    /// </summary>
    public static string GetWindowsEdition()
    {
        try
        {
            using var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion");
            return key?.GetValue("EditionID")?.ToString() ?? "Unknown";
        }
        catch { return "Unknown"; }
    }

    /// <summary>
    /// Check if Secure Boot is enabled.
    /// Returns null if cannot determine.
    /// </summary>
    public static async Task<bool?> IsSecureBootEnabled()
    {
        var result = await ProcessRunner.RunPowerShellAsync(
            "try { Confirm-SecureBootUEFI } catch { Write-Output 'UNSUPPORTED' }");
        if (result.Output.Trim().Equals("True", StringComparison.OrdinalIgnoreCase)) return true;
        if (result.Output.Trim().Equals("False", StringComparison.OrdinalIgnoreCase)) return false;
        return null; // UNSUPPORTED (legacy BIOS)
    }

    /// <summary>
    /// Check if Hyper-V is enabled.
    /// </summary>
    public static async Task<bool> IsHyperVEnabled()
    {
        var result = await ProcessRunner.RunPowerShellAsync(
            "(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State");
        return result.Output.Trim().Equals("Enabled", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Get available disk space in GB for the given drive.
    /// </summary>
    public static double GetAvailableDiskSpaceGB(string driveLetter = "C")
    {
        var drive = new DriveInfo(driveLetter);
        return drive.AvailableFreeSpace / (1024.0 * 1024 * 1024);
    }

    /// <summary>
    /// Get total physical RAM in GB.
    /// </summary>
    public static async Task<double> GetTotalRamGB()
    {
        var result = await ProcessRunner.RunPowerShellAsync(
            "(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum");
        if (double.TryParse(result.Output.Trim(), out double bytes))
            return bytes / (1024.0 * 1024 * 1024);
        return 0;
    }

    /// <summary>
    /// Check if TestSigning is enabled via bcdedit.
    /// </summary>
    public static async Task<bool> IsTestSigningEnabled()
    {
        var result = await ProcessRunner.RunAsync("bcdedit.exe", "/enum {current}");
        return result.Output.Contains("testsigning", StringComparison.OrdinalIgnoreCase) &&
               result.Output.Contains("Yes", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Check if SeLockMemoryPrivilege is granted to the current user.
    /// </summary>
    public static async Task<(bool granted, string details)> CheckSeLockMemoryPrivilege()
    {
        string tempCfg = Path.Combine(Path.GetTempPath(), $"secedit_{Guid.NewGuid():N}.cfg");
        try
        {
            var result = await ProcessRunner.RunAsync("secedit.exe",
                $"/export /cfg \"{tempCfg}\" /areas USER_RIGHTS");
            if (!result.Success) return (false, "secedit export failed");

            string content = File.ReadAllText(tempCfg);
            var line = content.Split('\n')
                .FirstOrDefault(l => l.Contains("SeLockMemoryPrivilege", StringComparison.OrdinalIgnoreCase));

            if (line == null) return (false, "SeLockMemoryPrivilege not found in policy");

            string currentUser = Environment.UserName;
            string currentSid = System.Security.Principal.WindowsIdentity.GetCurrent().User?.Value ?? "";

            bool granted = line.Contains($"*{currentSid}", StringComparison.OrdinalIgnoreCase) ||
                           line.Contains(currentUser, StringComparison.OrdinalIgnoreCase);

            return (granted, line.Trim());
        }
        finally
        {
            if (File.Exists(tempCfg)) File.Delete(tempCfg);
        }
    }

    /// <summary>
    /// Reload PATH environment variable from registry.
    /// </summary>
    public static void ReloadEnvironmentPath()
    {
        ProcessRunner.ReloadEnvironmentPath();
    }
}
