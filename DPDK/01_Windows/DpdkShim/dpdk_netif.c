/*
 * dpdk_netif.c — lwIP network interface driver for DPDK
 *
 * Bridges lwIP's netif with DPDK rx_burst/tx_burst.
 * - TX: pbuf → rte_mbuf → rte_eth_tx_burst
 * - RX: rte_eth_rx_burst → rte_mbuf → pbuf → ethernet_input
 */

#include <string.h>
#define WIN32_LEAN_AND_MEAN
#define _WINSOCKAPI_
#include <windows.h>

#include <rte_common.h>
#include <rte_mbuf.h>
#include <rte_ethdev.h>
#include <rte_pause.h>

#include "lwip/init.h"
#include "lwip/netif.h"
#include "lwip/etharp.h"
#include "lwip/pbuf.h"
#include "lwip/timeouts.h"
#include "netif/ethernet.h"

/* --- Globals (set by shim_lwip_init) --- */
static struct netif g_netif;
static uint16_t g_port_id;
static struct rte_mempool *g_pool;
static volatile int g_lwip_running;
static volatile int g_lwip_external_rx;  /* 1 = dispatcher feeds packets, skip internal rx_burst */

/* ============================================================
 * sys_now() — required by lwIP timers (NO_SYS=1)
 * Returns milliseconds since system boot.
 * ============================================================ */
u32_t sys_now(void)
{
    return (u32_t)GetTickCount64();
}

/* ============================================================
 * TX path: lwIP pbuf → rte_mbuf → NIC
 * Called by lwIP when it has a frame to send.
 * ============================================================ */
static err_t dpdk_netif_linkoutput(struct netif *netif, struct pbuf *p)
{
    (void)netif;

    struct rte_mbuf *mbuf = rte_pktmbuf_alloc(g_pool);
    if (!mbuf)
        return ERR_MEM;

    /* Copy pbuf chain into contiguous rte_mbuf */
    uint16_t total_len = p->tot_len;
    char *data = rte_pktmbuf_append(mbuf, total_len);
    if (!data) {
        rte_pktmbuf_free(mbuf);
        return ERR_MEM;
    }

    uint16_t offset = 0;
    for (struct pbuf *q = p; q != NULL; q = q->next) {
        memcpy(data + offset, q->payload, q->len);
        offset += q->len;
    }

    /* Send */
    struct rte_mbuf *tx[1] = { mbuf };
    if (rte_eth_tx_burst(g_port_id, 0, tx, 1) == 0) {
        rte_pktmbuf_free(mbuf);
        return ERR_IF;
    }

    return ERR_OK;
}

/* ============================================================
 * netif init callback
 * ============================================================ */
static err_t dpdk_netif_init(struct netif *netif)
{
    netif->name[0] = 'd';
    netif->name[1] = 'k';
    netif->output     = etharp_output;
    netif->linkoutput  = dpdk_netif_linkoutput;
    netif->mtu         = 1500;
    netif->flags       = NETIF_FLAG_BROADCAST | NETIF_FLAG_ETHARP |
                         NETIF_FLAG_LINK_UP | NETIF_FLAG_UP;
    netif->hwaddr_len  = 6;
    /* hwaddr is set by caller before netif_add */

    return ERR_OK;
}

/* ============================================================
 * RX poll: rte_eth_rx_burst → pbuf → lwIP
 * Returns number of packets processed.
 * ============================================================ */
int dpdk_netif_poll(void)
{
    /* When external dispatcher is active, skip internal rx_burst.
     * The dispatcher (shim_dispatch_poll) feeds TCP/ARP packets via
     * dpdk_netif_input_mbuf() and calls sys_check_timeouts(). */
    if (g_lwip_external_rx) return 0;

    struct rte_mbuf *rx_pkts[32];
    uint16_t nb_rx = rte_eth_rx_burst(g_port_id, 0, rx_pkts, 32);

    for (uint16_t i = 0; i < nb_rx; i++) {
        uint8_t *data = rte_pktmbuf_mtod(rx_pkts[i], uint8_t *);
        uint16_t len  = rte_pktmbuf_data_len(rx_pkts[i]);

        /* Allocate lwIP pbuf and copy data */
        struct pbuf *p = pbuf_alloc(PBUF_RAW, len, PBUF_POOL);
        if (p) {
            pbuf_take(p, data, len);
            /* Feed into lwIP (ethernet_input handles ARP + IP) */
            if (g_netif.input(p, &g_netif) != ERR_OK)
                pbuf_free(p);
        }

        rte_pktmbuf_free(rx_pkts[i]);
    }

    return (int)nb_rx;
}

/* ============================================================
 * Public API: initialize lwIP + netif
 * ============================================================ */
int dpdk_lwip_init(uint16_t port_id, struct rte_mempool *pool,
                   uint32_t ip_addr, uint32_t netmask, uint32_t gateway,
                   const uint8_t *mac)
{
    g_port_id = port_id;
    g_pool    = pool;

    lwip_init();

    ip4_addr_t ip, mask, gw;
    ip.addr   = ip_addr;
    mask.addr = netmask;
    gw.addr   = gateway;

    /* Set MAC before netif_add */
    memcpy(g_netif.hwaddr, mac, 6);
    g_netif.hwaddr_len = 6;

    netif_add(&g_netif, &ip, &mask, &gw, NULL, dpdk_netif_init, ethernet_input);
    netif_set_default(&g_netif);
    netif_set_up(&g_netif);
    netif_set_link_up(&g_netif);

    g_lwip_running = 1;
    return 0;
}

/* ============================================================
 * Public API: single poll iteration
 * Calls rx poll + lwIP timers. Returns packets processed.
 * ============================================================ */
int dpdk_lwip_poll_once(void)
{
    if (!g_lwip_running) return 0;
    int n = dpdk_netif_poll();
    sys_check_timeouts();
    return n;
}

/* ============================================================
 * Public API: poll loop for up to max_ms milliseconds
 * Used by sync wrappers.
 * ============================================================ */
int dpdk_lwip_poll_ms(int max_ms)
{
    if (!g_lwip_running) return 0;
    DWORD start = (DWORD)GetTickCount64();
    int total = 0;

    while ((int)((DWORD)GetTickCount64() - start) < max_ms) {
        int n = dpdk_netif_poll();
        sys_check_timeouts();
        total += n;
        if (n == 0)
            rte_pause();
    }
    return total;
}

/* ============================================================
 * Public API: stop lwIP
 * ============================================================ */
void dpdk_lwip_stop(void)
{
    g_lwip_running = 0;
    netif_set_down(&g_netif);
    netif_remove(&g_netif);
}

/* ============================================================
 * Feed a pre-fetched rte_mbuf into lwIP stack.
 * Called by the unified dispatcher (shim_dispatch_poll) for
 * TCP/ARP/ICMP packets while UDP goes to PG driver.
 * Returns 1 on success, 0 if lwIP not running, -1 on alloc fail.
 * ============================================================ */
int dpdk_netif_input_mbuf(struct rte_mbuf *mbuf)
{
    if (!g_lwip_running || !mbuf) {
        if (mbuf) rte_pktmbuf_free(mbuf);
        return 0;
    }

    uint8_t *data = rte_pktmbuf_mtod(mbuf, uint8_t *);
    uint16_t len  = rte_pktmbuf_data_len(mbuf);

    struct pbuf *p = pbuf_alloc(PBUF_RAW, len, PBUF_POOL);
    if (!p) {
        rte_pktmbuf_free(mbuf);
        return -1;
    }

    pbuf_take(p, data, len);
    if (g_netif.input(p, &g_netif) != ERR_OK)
        pbuf_free(p);

    rte_pktmbuf_free(mbuf);
    return 1;
}

/* ============================================================
 * Set external RX mode: when enabled, dpdk_netif_poll() skips
 * rte_eth_rx_burst (dispatcher feeds packets instead).
 * ============================================================ */
void dpdk_netif_set_external_rx(int enabled)
{
    g_lwip_external_rx = enabled;
}

/* Accessors for shim layer */
struct netif *dpdk_lwip_get_netif(void) { return &g_netif; }
int dpdk_lwip_is_running(void) { return g_lwip_running; }
