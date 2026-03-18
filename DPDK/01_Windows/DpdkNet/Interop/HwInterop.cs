using System.Runtime.InteropServices;

namespace HwNet.Interop
{
    internal static class HwInterop
    {
        private const string HwDll = "hwio.dll";

        // === EAL ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eal_init(int argc, IntPtr argv);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eal_cleanup();

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr hw_version();

        // === Ethdev ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eth_dev_count_avail();

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eth_macaddr_get(ushort port_id, ref RteEtherAddr mac_addr);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eth_link_get_nowait(ushort port_id, ref RteEthLink link);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eth_stats_get(ushort port_id, ref RteEthStats stats);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eth_stats_reset(ushort port_id);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eth_dev_stop(ushort port_id);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_eth_dev_close(ushort port_id);

        // === Mbuf ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr hw_pktmbuf_pool_create_safe(
            string name, uint n, uint cache_size,
            ushort priv_size, ushort data_room_size, int socket_id);

        // === Port Setup ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_simple_port_setup(ushort port_id, IntPtr mbuf_pool,
            uint link_speeds);

        // === Packet I/O ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern ushort hw_rx_burst(ushort port_id, ushort queue_id,
            IntPtr[] rx_pkts, ushort nb_pkts);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern ushort hw_tx_burst(ushort port_id, ushort queue_id,
            IntPtr[] tx_pkts, ushort nb_pkts);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr hw_pktmbuf_mtod(IntPtr mbuf);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern ushort hw_pktmbuf_data_len(IntPtr mbuf);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern void hw_pktmbuf_free(IntPtr mbuf);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr hw_pktmbuf_alloc(IntPtr mempool);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr hw_pktmbuf_append(IntPtr mbuf, ushort len);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern uint hw_pktmbuf_pkt_len(IntPtr mbuf);

        // === Req/Resp ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_reqresp_once(
            ushort port_id, IntPtr pool,
            byte[] template_pkt, ushort pkt_len, ushort packet_id,
            uint expected_src_ip, ushort expected_dst_port,
            int timeout_ms,
            byte[] resp_buf, ushort resp_buf_size,
            ref HwReqRespResult result,
            byte[] local_mac, uint local_ip);

        // === Multi-Channel safe Req/Resp (spills non-matching packets instead of dropping) ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_reqresp_once_mc(
            ushort port_id, IntPtr pool,
            byte[] template_pkt, ushort pkt_len, ushort packet_id,
            uint expected_src_ip, ushort expected_dst_port,
            int timeout_ms,
            byte[] resp_buf, ushort resp_buf_size,
            ref HwReqRespResult result,
            byte[] local_mac, uint local_ip);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_reqresp_batch(
            ushort port_id, IntPtr pool,
            byte[] template_pkt, ushort pkt_len,
            ushort start_packet_id, ushort count,
            uint expected_src_ip, ushort expected_dst_port,
            int timeout_ms,
            ref HwBatchStats stats,
            byte[] local_mac, uint local_ip);

        // === Unified Dispatcher ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern ushort hw_dispatch_poll(
            ushort port_id, ushort queue_id,
            [In, Out] IntPtr[] out_udp_pkts, ushort max_udp,
            ref int out_lwip_count);

        // === Diagnostics ===
        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_read_debug_log(byte[] buf, int bufSize);

        [DllImport(HwDll, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int hw_check_hugepage(int testMb);
    }
}
