using System.Runtime.InteropServices;

namespace HwNet.Models
{
    /// <summary>
    /// Public result struct for shim_reqresp_once / shim_reqresp_once_mc.
    /// Wraps the internal ShimReqRespResult for external consumers.
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct ReqRespNativeResult
    {
        /// <summary>0 = success, 1 = timeout</summary>
        public int Status;
        /// <summary>Round-trip time in milliseconds.</summary>
        public double RttMs;
        /// <summary>Response payload length.</summary>
        public ushort RespLen;
        /// <summary>Source IP (network byte order).</summary>
        public uint SrcIp;
        /// <summary>Source port (host byte order).</summary>
        public ushort SrcPort;
    }
}
