using System.Text.Json;
using DpdkSetupTool.Steps;

namespace DpdkSetupTool.Utils;

public class SetupState
{
    public int CurrentStep { get; set; }
    public Dictionary<int, StepStatus> StepStatuses { get; set; } = new();
    public string ProjectRoot { get; set; } = "";
    public string? WdkPath { get; set; }
    public string? BcdBackupPath { get; set; }
    public List<string> BoundNicInstanceIds { get; set; } = new();

    private static string StatePath =>
        Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "setup_state.json");

    public void Save()
    {
        var json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(StatePath, json);
    }

    public static SetupState? Load()
    {
        if (!File.Exists(StatePath)) return null;
        try
        {
            var json = File.ReadAllText(StatePath);
            return JsonSerializer.Deserialize<SetupState>(json);
        }
        catch
        {
            return null;
        }
    }

    public static void Delete()
    {
        if (File.Exists(StatePath))
            File.Delete(StatePath);
    }

    /// <summary>
    /// Register this app in RunOnce to resume after reboot.
    /// </summary>
    public static void RegisterRunOnce()
    {
        try
        {
            string exePath = Environment.ProcessPath ?? Application.ExecutablePath;
            using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(
                @"Software\Microsoft\Windows\CurrentVersion\RunOnce", true);
            key?.SetValue("DpdkSetupTool", $"\"{exePath}\" --resume");
        }
        catch { }
    }
}
