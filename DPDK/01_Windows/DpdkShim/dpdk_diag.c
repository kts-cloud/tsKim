#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <rte_common.h>
#include <rte_eal.h>
#include <rte_ethdev.h>
#include <rte_mbuf.h>
#include <rte_mempool.h>
/* rte_bus_pci.h not in default include path - skip */

/* Windows LoadLibrary for PMD driver preloading */
#include <windows.h>

static void preload_pmd_drivers(void)
{
    const char *drivers[] = {
        "rte_bus_pci-26.dll",
        "rte_bus_vdev-26.dll",
        "rte_mempool_ring-26.dll",
        "rte_mempool_stack-26.dll",
        "rte_net_ixgbe-26.dll",
        "rte_net_e1000-26.dll",
        "rte_net_i40e-26.dll",
        "rte_net_iavf-26.dll",
        "rte_net_ice-26.dll",
        NULL
    };

    fprintf(stderr, "[0] Preloading PMD drivers...\n");
    int loaded = 0;
    for (int i = 0; drivers[i]; i++) {
        HMODULE h = LoadLibraryA(drivers[i]);
        if (h) {
            fprintf(stderr, "   [OK] %s\n", drivers[i]);
            loaded++;
        } else {
            fprintf(stderr, "   [--] %s (not found)\n", drivers[i]);
        }
    }
    fprintf(stderr, "   Loaded %d drivers\n", loaded);
    fflush(stderr);
}

/*
 * Standalone DPDK diagnostic tool (no C#/CLR)
 * Tests EAL init, port setup, and dev_start to diagnose crash.
 */

int main(int argc, char *argv[])
{
    int ret;
    uint16_t port_id = 0;
    uint16_t nb_ports;
    struct rte_mempool *mbuf_pool;
    struct rte_eth_conf port_conf;
    struct rte_eth_dev_info dev_info;
    struct rte_eth_txconf txconf;
    uint16_t nb_rxd = 256, nb_txd = 256;

    fprintf(stderr, "=== DPDK Native Diagnostic Tool ===\n");
    fflush(stderr);

    /* Preload PMD drivers (required on Windows) */
    preload_pmd_drivers();

    /* EAL Init */
    char *eal_args[] = {
        "dpdk_diag",
        "-l", "0",
        "-m", "512",
        "--log-level=pmd.net.ixgbe:debug"
    };
    int eal_argc = 6;

    fprintf(stderr, "[1] EAL init...\n"); fflush(stderr);
    ret = rte_eal_init(eal_argc, eal_args);
    if (ret < 0) {
        fprintf(stderr, "[FAIL] EAL init failed: %d\n", ret);
        return 1;
    }
    fprintf(stderr, "[OK] EAL init done (ret=%d)\n", ret); fflush(stderr);

    /* Count ports */
    nb_ports = rte_eth_dev_count_avail();
    fprintf(stderr, "[2] Available ports: %u\n", nb_ports); fflush(stderr);
    if (nb_ports == 0) {
        fprintf(stderr, "[FAIL] No ports available\n");
        rte_eal_cleanup();
        return 1;
    }

    /* Create mbuf pool */
    fprintf(stderr, "[3] Creating mbuf pool...\n"); fflush(stderr);
    mbuf_pool = rte_pktmbuf_pool_create("DIAG_POOL", 8191, 256, 0, 2048 + 128, 0);
    if (!mbuf_pool) {
        fprintf(stderr, "[FAIL] mbuf pool creation failed\n");
        rte_eal_cleanup();
        return 1;
    }
    fprintf(stderr, "[OK] mbuf pool created\n"); fflush(stderr);

    /* Get device info */
    fprintf(stderr, "[4] Getting dev info for port %u...\n", port_id); fflush(stderr);
    memset(&dev_info, 0, sizeof(dev_info));
    ret = rte_eth_dev_info_get(port_id, &dev_info);
    if (ret != 0) {
        fprintf(stderr, "[FAIL] dev_info_get failed: %d\n", ret);
        rte_eal_cleanup();
        return 1;
    }
    fprintf(stderr, "[OK] dev_info: driver=%s, max_rx_q=%u, max_tx_q=%u\n",
            dev_info.driver_name ? dev_info.driver_name : "NULL",
            dev_info.max_rx_queues, dev_info.max_tx_queues); fflush(stderr);

    fflush(stderr);

    /* Configure port */
    fprintf(stderr, "[5] Configuring port %u...\n", port_id); fflush(stderr);
    memset(&port_conf, 0, sizeof(port_conf));
    port_conf.intr_conf.lsc = 0;
    port_conf.intr_conf.rxq = 0;

    ret = rte_eth_dev_configure(port_id, 1, 1, &port_conf);
    if (ret != 0) {
        fprintf(stderr, "[FAIL] dev_configure failed: %d\n", ret);
        rte_eal_cleanup();
        return 1;
    }
    fprintf(stderr, "[OK] dev_configure done\n"); fflush(stderr);

    /* Adjust descriptors */
    ret = rte_eth_dev_adjust_nb_rx_tx_desc(port_id, &nb_rxd, &nb_txd);
    if (ret != 0) {
        fprintf(stderr, "[FAIL] adjust_desc failed: %d\n", ret);
        rte_eal_cleanup();
        return 1;
    }
    fprintf(stderr, "[OK] descriptors adjusted: rxd=%u, txd=%u\n", nb_rxd, nb_txd); fflush(stderr);

    /* Socket ID */
    int socket_id = rte_eth_dev_socket_id(port_id);
    if (socket_id < 0) socket_id = 0;
    fprintf(stderr, "   socket_id=%d\n", socket_id); fflush(stderr);

    /* RX queue setup */
    fprintf(stderr, "[6] RX queue setup...\n"); fflush(stderr);
    ret = rte_eth_rx_queue_setup(port_id, 0, nb_rxd, socket_id, NULL, mbuf_pool);
    if (ret < 0) {
        fprintf(stderr, "[FAIL] rx_queue_setup failed: %d\n", ret);
        rte_eal_cleanup();
        return 1;
    }
    fprintf(stderr, "[OK] rx_queue_setup done\n"); fflush(stderr);

    /* TX queue setup */
    fprintf(stderr, "[7] TX queue setup...\n"); fflush(stderr);
    txconf = dev_info.default_txconf;
    txconf.offloads = port_conf.txmode.offloads;
    ret = rte_eth_tx_queue_setup(port_id, 0, nb_txd, socket_id, &txconf);
    if (ret < 0) {
        fprintf(stderr, "[FAIL] tx_queue_setup failed: %d\n", ret);
        rte_eal_cleanup();
        return 1;
    }
    fprintf(stderr, "[OK] tx_queue_setup done\n"); fflush(stderr);

    /* Test mempool and allocation from main thread before dev_start */
    fprintf(stderr, "\n[PRE-TEST] Mempool diagnostics:\n"); fflush(stderr);
    fprintf(stderr, "  pool ptr = %p\n", (void*)mbuf_pool); fflush(stderr);
    fprintf(stderr, "  pool size = %u\n", mbuf_pool->size); fflush(stderr);
    fprintf(stderr, "  cache_size = %u\n", mbuf_pool->cache_size); fflush(stderr);
    fprintf(stderr, "  ops_index = %d\n", mbuf_pool->ops_index); fflush(stderr);
    fprintf(stderr, "  local_cache ptr = %p\n", (void*)mbuf_pool->local_cache); fflush(stderr);
    fprintf(stderr, "  lcore_id = %u\n", rte_lcore_id()); fflush(stderr);

    /* Manual step-by-step mempool allocation test */
    fprintf(stderr, "[PRE-TEST] Step-by-step alloc test:\n"); fflush(stderr);

    /* Step A: Access local_cache[0] */
    __try {
        struct rte_mempool_cache *cache = &mbuf_pool->local_cache[0];
        fprintf(stderr, "  step A: cache[0] ptr = %p\n", (void*)cache); fflush(stderr);
        fprintf(stderr, "  step A: cache->len = %u\n", cache->len); fflush(stderr);
        fprintf(stderr, "  step A: cache->size = %u\n", cache->size); fflush(stderr);
        fprintf(stderr, "  step A: cache->flushthresh = %u\n", cache->flushthresh); fflush(stderr);
    } __except(1) {
        fprintf(stderr, "  step A: CRASH accessing local_cache[0]!\n"); fflush(stderr);
    }

    /* Step B: Access ops_table */
    __try {
        struct rte_mempool_ops *ops = rte_mempool_get_ops(mbuf_pool->ops_index);
        fprintf(stderr, "  step B: ops ptr = %p\n", (void*)ops); fflush(stderr);
        fprintf(stderr, "  step B: ops->name = %s\n", ops->name); fflush(stderr);
        fprintf(stderr, "  step B: ops->dequeue = %p\n", (void*)ops->dequeue); fflush(stderr);
    } __except(1) {
        fprintf(stderr, "  step B: CRASH accessing ops_table!\n"); fflush(stderr);
    }

    /* Step C: Try the actual allocation */
    fprintf(stderr, "[PRE-TEST] Trying rte_pktmbuf_alloc...\n"); fflush(stderr);
    __try {
        struct rte_mbuf *test_mbuf = rte_pktmbuf_alloc(mbuf_pool);
        if (test_mbuf) {
            fprintf(stderr, "[PRE-TEST] OK: mbuf=%p buf_iova=0x%llx\n",
                    (void*)test_mbuf,
                    (unsigned long long)test_mbuf->buf_iova);
            rte_pktmbuf_free(test_mbuf);
            fprintf(stderr, "[PRE-TEST] Free OK\n");
        } else {
            fprintf(stderr, "[PRE-TEST] WARN: rte_pktmbuf_alloc returned NULL\n");
        }
    } __except(1) {
        fprintf(stderr, "[PRE-TEST] CRASH in rte_pktmbuf_alloc! SEH caught.\n");
    }
    fflush(stderr);

    /* DEV START - this is where the crash happens */
    fprintf(stderr, "\n");
    fprintf(stderr, "============================================\n");
    fprintf(stderr, "[8] >>> rte_eth_dev_start(port=%u) <<<\n", port_id);
    fprintf(stderr, "============================================\n");
    fflush(stderr);

    __try {
        ret = rte_eth_dev_start(port_id);
    } __except(1) {
        fprintf(stderr, "[CRASH] SEH EXCEPTION in rte_eth_dev_start!\n");
        fprintf(stderr, "   This confirms BAR mapping or register access failure.\n");
        fflush(stderr);
        rte_eal_cleanup();
        return 99;
    }

    if (ret < 0) {
        fprintf(stderr, "[FAIL] dev_start failed: %d\n", ret);
        rte_eal_cleanup();
        return 1;
    }

    fprintf(stderr, "[OK] dev_start SUCCESS!\n"); fflush(stderr);

    /* Enable promiscuous mode */
    rte_eth_promiscuous_enable(port_id);

    /* Get MAC address */
    struct rte_ether_addr mac;
    rte_eth_macaddr_get(port_id, &mac);
    fprintf(stderr, "[OK] MAC: %02x:%02x:%02x:%02x:%02x:%02x\n",
            mac.addr_bytes[0], mac.addr_bytes[1], mac.addr_bytes[2],
            mac.addr_bytes[3], mac.addr_bytes[4], mac.addr_bytes[5]);
    fflush(stderr);

    /* Check link status */
    struct rte_eth_link link;
    ret = rte_eth_link_get_nowait(port_id, &link);
    (void)ret;
    fprintf(stderr, "[OK] Link: speed=%u, duplex=%s, status=%s\n",
            link.link_speed,
            link.link_duplex == RTE_ETH_LINK_FULL_DUPLEX ? "full" : "half",
            link.link_status == RTE_ETH_LINK_UP ? "UP" : "DOWN");
    fflush(stderr);

    fprintf(stderr, "\n=== DPDK Diagnostic Complete - SUCCESS ===\n");
    fflush(stderr);

    /* Cleanup */
    rte_eth_dev_stop(port_id);
    rte_eth_dev_close(port_id);
    rte_eal_cleanup();

    return 0;
}
