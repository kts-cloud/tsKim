using System.Text.Json;

namespace DpdkTestTool.Core
{
    public class AppSettings
    {
        // EAL
        public string CoreMask { get; set; } = "0";
        public string Memory { get; set; } = "512";
        public string LogLevel { get; set; } = "*:error";
        public int PortId { get; set; } = 0;
        public int MbufPoolSize { get; set; } = 8191;
        public int LinkSpeed { get; set; } = 0; // 0=Auto, 1=10M, 2=100M, 3=1G, 4=10G

        // TX
        public string DstMac { get; set; } = "FF:FF:FF:FF:FF:FF";
        public string DstIp { get; set; } = "192.168.0.1";
        public int DstPort { get; set; } = 5000;
        public string SrcIp { get; set; } = "192.168.0.2";
        public int SrcPort { get; set; } = 4000;
        public int PayloadSize { get; set; } = 64;
        public int SendRate { get; set; } = 0;
        public string PayloadText { get; set; } = "";

        // Req/Resp
        public int ResponseTimeoutMs { get; set; } = 1000;

        // RX
        public string FilterIp { get; set; } = "";
        public int FilterPort { get; set; } = 0;

        // FTP
        public string FtpServerIp { get; set; } = "192.168.0.1";
        public int FtpServerPort { get; set; } = 21;
        public string FtpUsername { get; set; } = "anonymous";
        public string FtpPassword { get; set; } = "";
        public string FtpLocalIp { get; set; } = "192.168.0.2";
        public string FtpNetmask { get; set; } = "255.255.255.0";
        public string FtpGateway { get; set; } = "192.168.0.1";

        private static readonly string SettingsDir = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory, "settings");
        private static readonly string DefaultFile = Path.Combine(SettingsDir, "last.json");

        public void Save(string? filePath = null)
        {
            string path = filePath ?? DefaultFile;
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            string json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(path, json);
        }

        public static AppSettings Load(string? filePath = null)
        {
            string path = filePath ?? DefaultFile;
            if (!File.Exists(path))
                return new AppSettings();
            string json = File.ReadAllText(path);
            return JsonSerializer.Deserialize<AppSettings>(json) ?? new AppSettings();
        }

        public static string[] GetSavedProfiles()
        {
            if (!Directory.Exists(SettingsDir))
                return Array.Empty<string>();
            return Directory.GetFiles(SettingsDir, "*.json")
                .Select(f => Path.GetFileNameWithoutExtension(f))
                .ToArray();
        }

        public void SaveAs(string profileName)
        {
            Save(Path.Combine(SettingsDir, profileName + ".json"));
        }

        public static AppSettings LoadProfile(string profileName)
        {
            return Load(Path.Combine(SettingsDir, profileName + ".json"));
        }
    }
}
