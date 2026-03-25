#ifndef HW_RING_OPS_H
#define HW_RING_OPS_H
/*
 * hw_ring_ops.h — dllimport data-symbol fix for hwio.dll
 *
 * MUST be included AFTER all DPDK headers.
 *
 * Problem:
 *   hwio.dll is built with `clang -shared` outside DPDK's meson build.
 *   DPDK inline functions access data exports (rte_mempool_ops_table,
 *   rte_eth_fp_ops) without __declspec(dllimport).  lld-link auto-import
 *   fails → garbage addresses → SEH crash.
 *
 * Fix:
 *   Override the top-level inline functions that hwio.c calls directly.
 *   #define AFTER headers only affects call sites in .c files, not the
 *   already-preprocessed inline function bodies in the headers.
 *
 *   - rte_pktmbuf_alloc/free: bypass rte_mempool_ops_table entirely
 *     via direct rte_ring dequeue/enqueue (ring is in mp->pool_data).
 *   - rte_eth_rx/tx_burst: resolve rte_eth_fp_ops via GetProcAddress
 *     and call the device's rx/tx function pointer directly.
 */

#include <windows.h>

/* ── mempool: direct ring access (no rte_mempool_ops_table) ──── */

static inline struct rte_mbuf *_hw_pktmbuf_alloc(struct rte_mempool *mp) {
    if (!mp || !mp->pool_data) return NULL;
    void *obj = NULL;
    if (rte_ring_mc_dequeue((struct rte_ring *)mp->pool_data, &obj) != 0)
        return NULL;
    struct rte_mbuf *m = (struct rte_mbuf *)obj;
    rte_pktmbuf_reset(m);
    return m;
}

static inline void _hw_pktmbuf_free(struct rte_mbuf *m) {
    while (m) {
        struct rte_mbuf *next = m->next;
        struct rte_ring *r = (struct rte_ring *)m->pool->pool_data;
        m->next = NULL;
        m->nb_segs = 1;
        rte_ring_mp_enqueue(r, (void *)m);
        m = next;
    }
}

#define rte_pktmbuf_alloc(mp)  _hw_pktmbuf_alloc(mp)
#define rte_pktmbuf_free(m)    _hw_pktmbuf_free(m)

/* ── ethdev: GetProcAddress for rte_eth_fp_ops ───────────────── */

static struct rte_eth_fp_ops *_hw_fp_ops = NULL;

static inline void _hw_init_fp_ops(void) {
    HMODULE h = GetModuleHandleA("rte_ethdev-26.dll");
    if (h) _hw_fp_ops =
        (struct rte_eth_fp_ops *)GetProcAddress(h, "rte_eth_fp_ops");
}

static inline uint16_t _hw_rx_burst(uint16_t port_id, uint16_t queue_id,
        struct rte_mbuf **rx_pkts, uint16_t nb_pkts) {
    if (!_hw_fp_ops) return 0;
    struct rte_eth_fp_ops *p = &_hw_fp_ops[port_id];
    void *qd = p->rxq.data[queue_id];
    if (!p->rx_pkt_burst || !qd) return 0;
    return p->rx_pkt_burst(qd, rx_pkts, nb_pkts);
}

static inline uint16_t _hw_tx_burst(uint16_t port_id, uint16_t queue_id,
        struct rte_mbuf **tx_pkts, uint16_t nb_pkts) {
    if (!_hw_fp_ops) return 0;
    struct rte_eth_fp_ops *p = &_hw_fp_ops[port_id];
    void *qd = p->txq.data[queue_id];
    if (!p->tx_pkt_burst || !qd) return 0;
    return p->tx_pkt_burst(qd, tx_pkts, nb_pkts);
}

#define rte_eth_rx_burst(p,q,r,n)  _hw_rx_burst(p,q,r,n)
#define rte_eth_tx_burst(p,q,t,n)  _hw_tx_burst(p,q,t,n)

#endif /* HW_RING_OPS_H */
