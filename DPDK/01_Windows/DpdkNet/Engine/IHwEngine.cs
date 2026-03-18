namespace HwNet.Engine
{
    public interface IHwEngine : IDisposable
    {
        bool IsRunning { get; }
        string? LastError { get; }
        void Stop();
    }
}
