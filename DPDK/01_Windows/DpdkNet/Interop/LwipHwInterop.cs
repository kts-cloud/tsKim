using System.Runtime.InteropServices;

namespace HwNet.Interop
{
    internal static class LwipHwInterop
    {
        private const string HwDll = "hwio.dll";

        // === lwIP Stack ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_lwip_init(ushort port_id, IntPtr pool,
            uint ip_addr, uint netmask, uint gateway, byte[] mac);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern void hw_lwip_stop();

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_lwip_poll(int max_ms);

        // === FTP Client ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_connect_sync(
            [MarshalAs(UnmanagedType.LPStr)] string server_ip, ushort port,
            [MarshalAs(UnmanagedType.LPStr)] string username,
            [MarshalAs(UnmanagedType.LPStr)] string password,
            int timeout_ms);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_disconnect();

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_pwd(byte[] buf, int buf_size);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_cwd(
            [MarshalAs(UnmanagedType.LPStr)] string path);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_list_sync(byte[] buf, int buf_size,
            ref int out_len, int timeout_ms);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_download_sync(
            [MarshalAs(UnmanagedType.LPStr)] string remote_path,
            byte[] buf, int buf_size, ref int out_len, int timeout_ms);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_upload_sync(
            [MarshalAs(UnmanagedType.LPStr)] string remote_path,
            byte[] data, int data_len, int timeout_ms);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_get_state();

        // === External RX mode (for unified dispatcher) ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern void hw_lwip_set_external_rx(int enabled);

        // === Multi-session FTP _ex APIs ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_lwip_init_ref(ushort port_id, IntPtr pool,
            uint ip_addr, uint netmask, uint gateway, byte[] mac);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern void hw_lwip_stop_ref();

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_connect_sync_ex(int sessionId,
            [MarshalAs(UnmanagedType.LPStr)] string server_ip, ushort port,
            [MarshalAs(UnmanagedType.LPStr)] string username,
            [MarshalAs(UnmanagedType.LPStr)] string password,
            int timeout_ms);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_disconnect_ex(int sessionId);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_download_sync_ex(int sessionId,
            [MarshalAs(UnmanagedType.LPStr)] string remote_path,
            byte[] buf, int buf_size, ref int out_len, int timeout_ms);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_upload_sync_ex(int sessionId,
            [MarshalAs(UnmanagedType.LPStr)] string remote_path,
            byte[] data, int data_len, int timeout_ms);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_ftp_get_state_ex(int sessionId);
    }
}
