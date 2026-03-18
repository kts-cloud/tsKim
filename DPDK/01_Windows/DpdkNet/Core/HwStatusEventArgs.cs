namespace HwNet
{
    public class HwStatusEventArgs : EventArgs
    {
        public HwState State { get; }
        public string Message { get; }
        public HwStatusEventArgs(HwState state, string message)
        {
            State = state;
            Message = message;
        }
    }
}
