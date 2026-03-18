namespace DpdkSetupTool.Utils;

public static class WdkLocator
{
    private static readonly string WdkRoot =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
            "Windows Kits", "10");

    /// <summary>
    /// Check if WDK is installed.
    /// </summary>
    public static bool IsInstalled()
    {
        string binDir = Path.Combine(WdkRoot, "bin");
        return Directory.Exists(binDir) && GetInstalledVersions().Length > 0;
    }

    /// <summary>
    /// Get all installed WDK versions, sorted descending (newest first).
    /// </summary>
    public static string[] GetInstalledVersions()
    {
        string binDir = Path.Combine(WdkRoot, "bin");
        if (!Directory.Exists(binDir)) return Array.Empty<string>();

        return Directory.GetDirectories(binDir)
            .Select(d => Path.GetFileName(d))
            .Where(n => n.StartsWith("10."))
            .OrderByDescending(v => v)
            .ToArray();
    }

    /// <summary>
    /// Find a WDK tool by name and architecture.
    /// Searches all installed versions, returns the newest match.
    /// </summary>
    public static string? FindTool(string toolName, string arch = "x64")
    {
        string binDir = Path.Combine(WdkRoot, "bin");
        if (!Directory.Exists(binDir)) return null;

        var versions = GetInstalledVersions();
        foreach (var ver in versions)
        {
            string toolPath = Path.Combine(binDir, ver, arch, toolName);
            if (File.Exists(toolPath)) return toolPath;
        }

        // Fallback: recursive search
        try
        {
            return Directory.GetFiles(binDir, toolName, SearchOption.AllDirectories)
                .Where(f => f.Contains(arch, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(f => f)
                .FirstOrDefault();
        }
        catch { return null; }
    }

    /// <summary>
    /// Find WDK lib path for linking (e.g., um\x64).
    /// Replaces hard-coded "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"
    /// </summary>
    public static string? FindLibPath(string arch = "x64")
    {
        string libDir = Path.Combine(WdkRoot, "Lib");
        if (!Directory.Exists(libDir)) return null;

        var versions = Directory.GetDirectories(libDir)
            .Select(d => Path.GetFileName(d))
            .Where(n => n.StartsWith("10."))
            .OrderByDescending(v => v)
            .ToArray();

        foreach (var ver in versions)
        {
            string umPath = Path.Combine(libDir, ver, "um", arch);
            if (Directory.Exists(umPath)) return umPath;
        }

        return null;
    }

    /// <summary>
    /// Find devcon.exe — checks WDK Tools directory.
    /// Replaces hard-coded "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.22621.0\x64\devcon.exe"
    /// </summary>
    public static string? FindDevcon()
    {
        string toolsDir = Path.Combine(WdkRoot, "Tools");
        if (Directory.Exists(toolsDir))
        {
            // Direct path: Tools\x64\devcon.exe (no version subfolder)
            string directPath = Path.Combine(toolsDir, "x64", "devcon.exe");
            if (File.Exists(directPath)) return directPath;

            // Versioned path: Tools\10.0.xxxxx\x64\devcon.exe
            var versions = Directory.GetDirectories(toolsDir)
                .Select(d => Path.GetFileName(d))
                .Where(n => n.StartsWith("10."))
                .OrderByDescending(v => v)
                .ToArray();

            foreach (var ver in versions)
            {
                string devconPath = Path.Combine(toolsDir, ver, "x64", "devcon.exe");
                if (File.Exists(devconPath)) return devconPath;
            }

            // Recursive fallback within Tools
            try
            {
                var found = Directory.GetFiles(toolsDir, "devcon.exe", SearchOption.AllDirectories)
                    .FirstOrDefault(f => f.Contains("x64", StringComparison.OrdinalIgnoreCase));
                if (found != null) return found;
            }
            catch { }
        }

        // Fallback: search bin directory
        return FindTool("devcon.exe", "x64");
    }

    /// <summary>
    /// Get the WDK root path.
    /// </summary>
    public static string GetWdkRoot() => WdkRoot;
}
