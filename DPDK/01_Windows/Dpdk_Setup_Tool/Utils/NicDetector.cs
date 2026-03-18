using System.Text.RegularExpressions;

namespace DpdkSetupTool.Utils;

public class NicInfo
{
    public string FriendlyName { get; init; } = "";
    public string HardwareId { get; init; } = "";
    public string CurrentDriver { get; init; } = "";
    public string DeviceClass { get; init; } = "";
    public string InstanceId { get; init; } = "";
    public bool IsDpdkSupported { get; init; }
    public bool IsBoundToNetuio => DeviceClass.Equals("Windows UIO", StringComparison.OrdinalIgnoreCase);

    public string StatusDisplay => IsBoundToNetuio ? "DPDK (netuio)" : "Windows (Net)";
}

public static class NicDetector
{
    private static readonly HashSet<string> _supportedHwIds = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// Parse netuio.inf to load supported hardware IDs dynamically.
    /// </summary>
    public static void LoadSupportedIds(string netuioInfPath)
    {
        _supportedHwIds.Clear();
        if (!File.Exists(netuioInfPath)) return;

        // Match lines like: %netuio_Desc% = netuio_Inst, PCI\VEN_8086&DEV_1563
        var hwIdRegex = new Regex(@"PCI\\(VEN_[0-9A-Fa-f]+&DEV_[0-9A-Fa-f]+)", RegexOptions.IgnoreCase);

        foreach (var line in File.ReadLines(netuioInfPath))
        {
            var match = hwIdRegex.Match(line);
            if (match.Success)
                _supportedHwIds.Add(match.Groups[1].Value.ToUpperInvariant());
        }
    }

    /// <summary>
    /// Check if a hardware ID is supported by netuio.
    /// </summary>
    public static bool IsSupported(string hardwareId)
    {
        if (_supportedHwIds.Count == 0) return false;

        // Extract VEN_xxxx&DEV_xxxx from the full hardware ID
        var match = Regex.Match(hardwareId, @"VEN_([0-9A-Fa-f]+)&DEV_([0-9A-Fa-f]+)", RegexOptions.IgnoreCase);
        if (!match.Success) return false;

        string normalized = $"VEN_{match.Groups[1].Value.ToUpperInvariant()}&DEV_{match.Groups[2].Value.ToUpperInvariant()}";
        return _supportedHwIds.Contains(normalized);
    }

    /// <summary>
    /// Enumerate all network adapters on the system.
    /// </summary>
    public static async Task<List<NicInfo>> EnumerateNicsAsync()
    {
        var nics = new List<NicInfo>();

        // Filter by Class (Net or Windows UIO) and InstanceId containing VEN_ or VID_
        // NOTE: HardwareIds property is always null in Get-PnpDevice on this system,
        // so we use InstanceId for filtering and extract HW ID from it
        var result = await ProcessRunner.RunPowerShellAsync(
            @"Get-PnpDevice -ErrorAction SilentlyContinue | " +
            @"Where-Object { ($_.Class -eq 'Net' -or $_.Class -eq 'Windows UIO') -and ($_.InstanceId -match 'VEN_|VID_') } | " +
            @"Select-Object FriendlyName, InstanceId, Class, @{N='HardwareID';E={ if ($_.HardwareIds) { $_.HardwareIds | Select-Object -First 1 } else { $_.InstanceId -replace '\\[^\\]+$','' }}} | " +
            @"ConvertTo-Json -Compress");

        if (!result.Success || string.IsNullOrWhiteSpace(result.Output)) return nics;

        try
        {
            var output = result.Output.Trim();
            // PowerShell returns single object (not array) when only one result
            if (!output.StartsWith("["))
                output = $"[{output}]";

            var items = System.Text.Json.JsonSerializer.Deserialize<List<PnpDeviceInfo>>(output);
            if (items == null) return nics;

            foreach (var item in items)
            {
                string hwId = item.HardwareID ?? "";
                nics.Add(new NicInfo
                {
                    FriendlyName = item.FriendlyName ?? "Unknown",
                    InstanceId = item.InstanceId ?? "",
                    DeviceClass = item.Class ?? "Net",
                    HardwareId = hwId,
                    CurrentDriver = await GetDriverName(item.InstanceId ?? ""),
                    IsDpdkSupported = IsSupported(hwId)
                });
            }
        }
        catch { }

        return nics;
    }

    private static async Task<string> GetDriverName(string instanceId)
    {
        if (string.IsNullOrEmpty(instanceId)) return "Unknown";

        var result = await ProcessRunner.RunPowerShellAsync(
            $"(Get-PnpDeviceProperty -InstanceId '{instanceId}' -KeyName DEVPKEY_Device_DriverInfPath -ErrorAction SilentlyContinue).Data");

        string driver = result.Output.Trim();
        return string.IsNullOrEmpty(driver) ? "Unknown" : Path.GetFileNameWithoutExtension(driver);
    }

    private class PnpDeviceInfo
    {
        public string? FriendlyName { get; set; }
        public string? InstanceId { get; set; }
        public string? Class { get; set; }
        public string? HardwareID { get; set; }
    }
}
