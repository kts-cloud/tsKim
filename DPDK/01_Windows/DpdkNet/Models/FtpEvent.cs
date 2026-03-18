namespace HwNet.Models
{
    public enum FtpEventType { Connected, Disconnected, LoginOk, LoginFailed, Listed, Downloaded, Uploaded, Error, Info }

    public class FtpEvent
    {
        public FtpEventType Type { get; set; }
        public string Message { get; set; } = "";
        public DateTime Timestamp { get; set; } = DateTime.Now;
    }
}
