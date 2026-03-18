namespace HwNet
{
    public interface IHwContext
    {
        HwState State { get; }
        IntPtr MbufPool { get; }
        ushort PortId { get; }
        byte[] LocalMac { get; }
    }
}
