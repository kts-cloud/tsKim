namespace HwNet.Config
{
    public class FtpConfig
    {
        public string ServerIp { get; set; } = "192.168.0.1";
        public ushort ServerPort { get; set; } = 21;
        public string Username { get; set; } = "anonymous";
        public string Password { get; set; } = "user@hw.local";
        public string LocalIp { get; set; } = "192.168.0.2";
        public string Netmask { get; set; } = "255.255.255.0";
        public string Gateway { get; set; } = "192.168.0.1";
        public int TimeoutMs { get; set; } = 10000;
    }
}
