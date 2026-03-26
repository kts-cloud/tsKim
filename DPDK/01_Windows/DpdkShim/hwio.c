#include <stdio.h>
#define WIN32_LEAN_AND_MEAN
#define _WINSOCKAPI_
#include <windows.h>
#include <psapi.h>
#include <intrin.h>  /* _mm_pause, _InterlockedExchange */

/* timeBeginPeriod/timeEndPeriod — runtime load to avoid winmm.lib link dependency */
typedef UINT (WINAPI *PFN_timeBeginPeriod)(UINT);
typedef UINT (WINAPI *PFN_timeEndPeriod)(UINT);
static PFN_timeBeginPeriod pfn_timeBeginPeriod;
static PFN_timeEndPeriod   pfn_timeEndPeriod;
#include <rte_common.h>
#include <rte_eal.h>
#include <rte_mbuf.h>
#include <rte_ethdev.h>
#include <rte_errno.h>
#include <rte_version.h>
#include <rte_pause.h>
#include <rte_spinlock.h>
#include <rte_ring.h>
#include <rte_mempool.h>
#include "hw_ring_ops.h"  // AFTER DPDK headers: overrides alloc/free/rx/tx at call sites

// Windows DLL Export Macro
#define DPDK_API __declspec(dllexport)

// ─── Legacy spill buffer (kept for backward compat, will be removed) ───
static struct rte_ring *g_spill_ring = NULL;
static rte_spinlock_t g_rx_lock = RTE_SPINLOCK_INITIALIZER;
static volatile int g_ftp_active = 0;

// Track EAL init state for DllMain safety net
static volatile int g_eal_initialized = 0;

// ═══════════════════════════════════════════════════════════════════
// NIC Owner Thread Architecture — 크래시 근본 해결
//
// 핵심 원칙: rte_eth_rx_burst, rte_eth_tx_burst, lwIP 전체를
// 단일 스레드(NIC Owner)에서만 호출. 다른 스레드는 Command Ring을
// 통해 요청을 제출하고 완료를 대기.
//
// 이것으로 해결되는 문제:
// 1. lwIP NO_SYS=1 멀티스레드 호출 → TCP PCB 손상
// 2. mbuf pool 동시 접근 → ixgbe descriptor corruption
// 3. SPSC ring 다수 consumer → 정의되지 않은 동작
// ═══════════════════════════════════════════════════════════════════

// --- Command types ---
typedef enum {
    NIC_CMD_REQRESP = 0,   // UDP request/response
    NIC_CMD_FTP_CONNECT,   // FTP connect + login
    NIC_CMD_FTP_DOWNLOAD,  // FTP RETR
    NIC_CMD_FTP_UPLOAD,    // FTP STOR
    NIC_CMD_FTP_DISCONNECT,// FTP QUIT + disconnect
    NIC_CMD_SHUTDOWN,      // Stop NIC thread
} nic_cmd_type_t;

// --- Command structure (pre-allocated, no malloc) ---
typedef struct {
    nic_cmd_type_t type;
    volatile int   done;       // 0=pending, 1=complete (set by NIC thread)
    int            result;     // command result

    // REQRESP fields
    uint16_t       port_id;
    struct rte_mempool *pool;
    uint8_t        template_pkt[2048];
    uint16_t       pkt_len;
    uint16_t       packet_id;
    uint32_t       expected_src_ip;
    uint16_t       expected_dst_port;
    int            timeout_ms;
    uint8_t        local_mac[6];
    uint32_t       local_ip;
    hw_reqresp_result_t rr_result;
    uint8_t        resp_buf[4096];
    uint16_t       resp_buf_size;

    // FTP fields
    int            ftp_session_id;
    char           ftp_server_ip[64];
    uint16_t       ftp_port;
    char           ftp_user[64];
    char           ftp_pass[64];
    char           ftp_path[512];
    uint8_t       *ftp_buf;
    int            ftp_buf_size;
    int            ftp_timeout_ms;
    const uint8_t *ftp_upload_data;
    int            ftp_upload_len;
    int            ftp_out_len;
} nic_cmd_t;

#define NIC_CMD_POOL_SIZE 8
static nic_cmd_t g_nic_cmd_pool[NIC_CMD_POOL_SIZE];
static struct rte_ring *g_nic_cmd_ring = NULL;   // MPSC: 여러 스레드 → NIC thread
static struct rte_ring *g_nic_cmd_free = NULL;   // MPMC: free slot 반환
static struct rte_ring *g_udp_rx_ring = NULL;    // SPSC: NIC thread → C# RxPollLoop
static HANDLE g_nic_thread = NULL;
static volatile int g_nic_running = 0;
static uint16_t g_nic_port_id = 0;
static struct rte_mempool *g_nic_pool = NULL;

// DPDK 전용 코어 격리: 프로세스의 다른 스레드가 이 코어를 사용하지 못하도록 예약
static int g_dpdk_core = -1;           // 격리된 코어 번호 (-1 = 미설정)
static DWORD_PTR g_original_affinity;  // 원래 프로세스 affinity 백업

// Debug log path — resolved once from DLL location
static char g_dbg_path[MAX_PATH] = {0};

static void hw_dbg_init_path(HINSTANCE hDll) {
    if (g_dbg_path[0] != '\0') return;  // already set
    DWORD len = GetModuleFileNameA(hDll, g_dbg_path, MAX_PATH);
    if (len == 0) {
        // Fallback: use current working directory
        GetCurrentDirectoryA(MAX_PATH, g_dbg_path);
        strcat_s(g_dbg_path, MAX_PATH, "\\hw_diag.log");
        return;
    }
    // Replace DLL filename with hw_diag.log
    char *last_sep = strrchr(g_dbg_path, '\\');
    if (last_sep) *(last_sep + 1) = '\0';
    else g_dbg_path[0] = '\0';
    strcat_s(g_dbg_path, MAX_PATH, "hw_diag.log");
}

// Write to debug file (in the same directory as hwio.dll / exe)
static void hw_dbg(const char *fmt, ...) {
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    // If path not yet initialized, use fallback
    const char *path = (g_dbg_path[0] != '\0') ? g_dbg_path : "hw_diag.log";
    HANDLE h = CreateFileA(path,
        FILE_APPEND_DATA, FILE_SHARE_READ|FILE_SHARE_WRITE,
        NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h != INVALID_HANDLE_VALUE) {
        DWORD w;
        WriteFile(h, buf, (DWORD)strlen(buf), &w, NULL);
        CloseHandle(h);
    }
}

/* SEH exception filter — captures crash address for diagnostics */
static LONG hw_seh_filter(EXCEPTION_POINTERS *ep) {
    DWORD code = ep->ExceptionRecord->ExceptionCode;
    void *instr_addr = ep->ExceptionRecord->ExceptionAddress;
    void *fault_addr = NULL;
    ULONG_PTR rw_flag = 0;
    if (code == 0xC0000005 && ep->ExceptionRecord->NumberParameters >= 2) {
        rw_flag = ep->ExceptionRecord->ExceptionInformation[0]; /* 0=read, 1=write */
        fault_addr = (void*)ep->ExceptionRecord->ExceptionInformation[1];
    }
    hw_dbg("[HW] SEH EXCEPTION! code=0x%08lX\n", code);
    hw_dbg("[HW]   instruction at  : %p\n", instr_addr);
    hw_dbg("[HW]   fault address   : %p (%s)\n", fault_addr,
        rw_flag == 0 ? "READ" : rw_flag == 1 ? "WRITE" : "DEP");

    /* Log which module contains the crash address */
    HMODULE hMod = NULL;
    if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                           GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                           (LPCSTR)instr_addr, &hMod)) {
        char modName[MAX_PATH] = {0};
        GetModuleFileNameA(hMod, modName, MAX_PATH);
        ptrdiff_t offset = (char*)instr_addr - (char*)hMod;
        hw_dbg("[HW]   crash module   : %s + 0x%llX\n", modName, (unsigned long long)offset);
    }
    return EXCEPTION_EXECUTE_HANDLER;
}

/* Clean stale DPDK runtime files from previous session */
static void clean_dpdk_runtime(void) {
    /* DPDK Windows runtime dir: %TEMP%\dpdk\rte or C:\var\run\dpdk */
    char runtime_dir[MAX_PATH];
    const char *temp = getenv("TEMP");
    if (temp) {
        snprintf(runtime_dir, sizeof(runtime_dir), "%s\\dpdk\\rte", temp);
    } else {
        snprintf(runtime_dir, sizeof(runtime_dir), "C:\\var\\run\\dpdk\\rte");
    }

    WIN32_FIND_DATAA fd;
    char pattern[MAX_PATH];
    snprintf(pattern, sizeof(pattern), "%s\\*", runtime_dir);
    HANDLE hFind = FindFirstFileA(pattern, &fd);
    if (hFind == INVALID_HANDLE_VALUE) return;

    int cleaned = 0;
    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        char filepath[MAX_PATH];
        snprintf(filepath, sizeof(filepath), "%s\\%s", runtime_dir, fd.cFileName);
        if (DeleteFileA(filepath)) cleaned++;
    } while (FindNextFileA(hFind, &fd));
    FindClose(hFind);

    if (cleaned > 0)
        hw_dbg("[HW] cleaned %d stale runtime files from %s\n", cleaned, runtime_dir);
}

// EAL init wrapper — enables SeLockMemory, sets working set, then inits EAL
DPDK_API int hw_eal_init(int argc, char **argv) {

    /* Truncate debug log on first call (clean per-session log) */
    static int s_first_call = 1;
    if (s_first_call) {
        s_first_call = 0;
        const char *path = (g_dbg_path[0] != '\0') ? g_dbg_path : "hw_diag.log";
        HANDLE h = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
            NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        if (h != INVALID_HANDLE_VALUE) CloseHandle(h);
    }

    /* Guard against double initialization — DPDK doesn't support re-init */
    if (g_eal_initialized) {
        hw_dbg("[HW] WARNING: hw_eal_init called again (already initialized). Returning -98.\n");
        return -98;
    }

    /* Log received args for debugging */
    hw_dbg("[HW] hw_eal_init called with argc=%d\n", argc);
    for (int i = 0; i < argc; i++)
        hw_dbg("[HW]   argv[%d] = \"%s\"\n", i, argv[i] ? argv[i] : "(null)");

    /* Clean stale DPDK runtime files from previous crashed session */
    clean_dpdk_runtime();

    /* Enable SeLockMemoryPrivilege for VirtualAlloc2 + MEM_LARGE_PAGES */
    HANDLE hToken = NULL;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) {
        TOKEN_PRIVILEGES tp;
        tp.PrivilegeCount = 1;
        tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
        if (LookupPrivilegeValueA(NULL, "SeLockMemoryPrivilege", &tp.Privileges[0].Luid)) {
            BOOL adj_ok = AdjustTokenPrivileges(hToken, FALSE, &tp, 0, NULL, NULL);
            DWORD adj_err = GetLastError();
            hw_dbg("[HW] AdjustTokenPrivileges(SeLockMemory) ok=%d err=%lu\n", adj_ok, adj_err);
        } else {
            hw_dbg("[HW] LookupPrivilegeValue FAIL err=%lu\n", GetLastError());
        }
        CloseHandle(hToken);
    } else {
        hw_dbg("[HW] OpenProcessToken FAIL err=%lu\n", GetLastError());
    }

    /* Check current working set limits */
    SIZE_T cur_min = 0, cur_max = 0;
    GetProcessWorkingSetSize(GetCurrentProcess(), &cur_min, &cur_max);
    hw_dbg("[HW] current WS min=%zu max=%zu\n", cur_min, cur_max);

    /* Dynamic working set: 2x/4x of requested EAL memory (parse -m arg) */
    SIZE_T requested_bytes = 0;
    for (int i = 0; i < argc - 1; i++) {
        if (strcmp(argv[i], "-m") == 0) {
            requested_bytes = (SIZE_T)atoi(argv[i + 1]) * 1024 * 1024;
            break;
        }
    }
    SIZE_T ws_min = requested_bytes > 0 ? requested_bytes * 2 : (SIZE_T)400 * 1024 * 1024;
    SIZE_T ws_max = ws_min * 2;
    /* Ensure minimum 512MB/1GB */
    if (ws_min < (SIZE_T)512 * 1024 * 1024) ws_min = (SIZE_T)512 * 1024 * 1024;
    if (ws_max < (SIZE_T)1024 * 1024 * 1024) ws_max = (SIZE_T)1024 * 1024 * 1024;

    BOOL ws_ok = SetProcessWorkingSetSizeEx(GetCurrentProcess(), ws_min, ws_max,
            QUOTA_LIMITS_HARDWS_MIN_ENABLE);
    hw_dbg("[HW] SetProcessWorkingSetSizeEx(%zu,%zu) = %d err=%lu\n",
        ws_min, ws_max, ws_ok, ws_ok ? 0 : GetLastError());

    /* Pass C# args directly to EAL (SEH protected with detailed crash info) */
    int ret;
    hw_dbg("[HW] calling rte_eal_init...\n");
    __try {
        ret = rte_eal_init(argc, argv);
    } __except(hw_seh_filter(GetExceptionInformation())) {
        g_eal_initialized = 1;
        return -99;
    }
    hw_dbg("[HW] rte_eal_init returned %d\n", ret);

    // Resolve rte_eth_fp_ops via GetProcAddress (dllimport workaround)
    _hw_init_fp_ops();
    hw_dbg("[HW] dllimport fix: fp_ops=%p\n", (void*)_hw_fp_ops);

    // 성공/실패 모두 1로 설정 — 실패 시에도 부분 할당된 hugepage를 cleanup하기 위함
    g_eal_initialized = 1;

    if (ret >= 0) {
        /* ── 시스템 튜닝 (EAL 초기화 성공 후) ── */

        /* Windows 타이머 해상도 → 1ms (기본 15.6ms → Sleep 정밀도 개선) */
        {
            HMODULE hWinmm = LoadLibraryA("winmm.dll");
            if (hWinmm) {
                pfn_timeBeginPeriod = (PFN_timeBeginPeriod)GetProcAddress(hWinmm, "timeBeginPeriod");
                pfn_timeEndPeriod   = (PFN_timeEndPeriod)GetProcAddress(hWinmm, "timeEndPeriod");
                if (pfn_timeBeginPeriod) pfn_timeBeginPeriod(1);
            }
        }

        /* 프로세스 우선순위: HIGH + 동적 부스트 비활성화 (지터 감소) */
        SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);
        SetProcessPriorityBoost(GetCurrentProcess(), TRUE);

        /* CPU 코어 격리: 마지막 코어를 DPDK reqresp 전용으로 예약
         * 프로세스의 다른 스레드(UI, .NET GC, lwIP 등)가 이 코어를 사용하지 못하도록
         * 프로세스 affinity에서 제외. reqresp 스레드만 이 코어에 고정. */
        {
            SYSTEM_INFO si;
            GetSystemInfo(&si);
            DWORD num_cores = si.dwNumberOfProcessors;
            if (num_cores >= 4) {
                /* 마지막 코어를 DPDK 전용으로 사용 (예: 8코어 → core 7) */
                g_dpdk_core = (int)(num_cores - 1);
                DWORD_PTR dpdk_mask = (DWORD_PTR)1 << g_dpdk_core;
                DWORD_PTR proc_mask, sys_mask;
                if (GetProcessAffinityMask(GetCurrentProcess(), &proc_mask, &sys_mask)) {
                    g_original_affinity = proc_mask;
                    /* 프로세스에서 DPDK 코어 제외 */
                    DWORD_PTR new_mask = proc_mask & ~dpdk_mask;
                    if (new_mask != 0) {
                        SetProcessAffinityMask(GetCurrentProcess(), new_mask);
                        hw_dbg("[HW] CPU isolation: core %d reserved for DPDK (process mask: 0x%llx → 0x%llx)\n",
                               g_dpdk_core, (unsigned long long)proc_mask, (unsigned long long)new_mask);
                    }
                }
            }
        }

        hw_dbg("[HW] system tuning: timeBeginPeriod(1), HIGH_PRIORITY_CLASS, boost disabled\n");
    }

    return ret;
}

// 1. RX Burst Wrapper — drains spill ring (lock-free) first, then NIC RX ring
DPDK_API uint16_t hw_rx_burst(uint16_t port_id, uint16_t queue_id, struct rte_mbuf **rx_pkts, uint16_t nb_pkts) {
    __try {
        uint16_t total = 0;

        // 1) Drain spill ring (lock-free SPSC dequeue)
        if (g_spill_ring) {
            void *obj;
            while (total < nb_pkts &&
                   rte_ring_sc_dequeue(g_spill_ring, &obj) == 0) {
                rx_pkts[total++] = (struct rte_mbuf *)obj;
            }
        }

        // 2) Fill remaining from NIC (lock protects single-consumer NIC queue)
        if (total < nb_pkts) {
            rte_spinlock_lock(&g_rx_lock);
            uint16_t n = rte_eth_rx_burst(port_id, queue_id,
                                           rx_pkts + total, nb_pkts - total);
            rte_spinlock_unlock(&g_rx_lock);
            total += n;
        }

        return total;
    } __except(hw_seh_filter(GetExceptionInformation())) {
        hw_dbg("[HW] SEH: hw_rx_burst crashed! port=%u queue=%u\n", port_id, queue_id);
        return 0;
    }
}

// 2. TX Burst Wrapper
DPDK_API uint16_t hw_tx_burst(uint16_t port_id, uint16_t queue_id, struct rte_mbuf **tx_pkts, uint16_t nb_pkts) {
    __try {
        return rte_eth_tx_burst(port_id, queue_id, tx_pkts, nb_pkts);
    } __except(hw_seh_filter(GetExceptionInformation())) {
        hw_dbg("[HW] SEH: hw_tx_burst crashed! port=%u queue=%u nb=%u\n", port_id, queue_id, nb_pkts);
        return 0;
    }
}

// 3. Mbuf Data Pointer Wrapper (rte_pktmbuf_mtod)
// C# needs a raw pointer to the packet data
DPDK_API void* hw_pktmbuf_mtod(struct rte_mbuf *m) {
    return rte_pktmbuf_mtod(m, void*);
}

// 4. Mbuf Data Length Wrapper
DPDK_API uint16_t hw_pktmbuf_data_len(struct rte_mbuf *m) {
    return rte_pktmbuf_data_len(m);
}

// 5. Mbuf Free Wrapper (SEH protected)
DPDK_API void hw_pktmbuf_free(struct rte_mbuf *m) {
    __try {
        rte_pktmbuf_free(m);
    } __except(1) {
        hw_dbg("[HW] SEH: hw_pktmbuf_free crashed! m=%p\n", (void*)m);
    }
}

// 6. Mbuf Allocation Wrapper (SEH protected)
DPDK_API struct rte_mbuf* hw_pktmbuf_alloc(struct rte_mempool *mp) {
    __try {
        return rte_pktmbuf_alloc(mp);
    } __except(1) {
        hw_dbg("[HW] SEH: hw_pktmbuf_alloc crashed! pool=%p\n", (void*)mp);
        return NULL;
    }
}

// 7. Mbuf Append Wrapper (SEH protected)
DPDK_API char* hw_pktmbuf_append(struct rte_mbuf *m, uint16_t len) {
    __try {
        return rte_pktmbuf_append(m, len);
    } __except(1) {
        hw_dbg("[HW] SEH: hw_pktmbuf_append crashed! m=%p len=%u\n", (void*)m, len);
        return NULL;
    }
}

// 8. Mbuf Packet Length Wrapper
DPDK_API uint32_t hw_pktmbuf_pkt_len(struct rte_mbuf *m) {
    return rte_pktmbuf_pkt_len(m);
}

// === SEH-Protected Wrappers for Init/Cleanup (prevents process crash) ===

// 9a. Version string (SEH protected)
DPDK_API const char* hw_version(void) {
    __try {
        return rte_version();
    } __except(1) {
        hw_dbg("[HW] rte_version SEH EXCEPTION\n");
        return NULL;
    }
}

// 9b. Available port count (SEH protected)
DPDK_API int hw_eth_dev_count_avail(void) {
    __try {
        return (int)rte_eth_dev_count_avail();
    } __except(1) {
        hw_dbg("[HW] rte_eth_dev_count_avail SEH EXCEPTION\n");
        return -1;
    }
}

// 9c. MAC address get (SEH protected)
DPDK_API int hw_eth_macaddr_get(uint16_t port_id, struct rte_ether_addr *mac_addr) {
    __try {
        return rte_eth_macaddr_get(port_id, mac_addr);
    } __except(1) {
        hw_dbg("[HW] rte_eth_macaddr_get SEH EXCEPTION port=%u\n", port_id);
        return -1;
    }
}

// 9d. Link status get (SEH protected)
DPDK_API int hw_eth_link_get_nowait(uint16_t port_id, struct rte_eth_link *link) {
    __try {
        return rte_eth_link_get_nowait(port_id, link);
    } __except(1) {
        hw_dbg("[HW] rte_eth_link_get_nowait SEH EXCEPTION port=%u\n", port_id);
        if (link) memset(link, 0, sizeof(*link));
        return -1;
    }
}

// Diagnostic: dump mempool ops table state
static void hw_dump_pool_ops(struct rte_mempool *mp, const char *label) {
    if (!mp) { hw_dbg("[HW] %s: pool is NULL\n", label); return; }
    hw_dbg("[HW] %s: pool=%p size=%u cache_size=%u ops_index=%d\n",
        label, (void*)mp, mp->size, mp->cache_size, mp->ops_index);
    __try {
        struct rte_mempool_ops *ops = rte_mempool_get_ops(mp->ops_index);
        hw_dbg("[HW] %s: ops=%p name='%.32s'\n", label, (void*)ops, ops->name);
        hw_dbg("[HW] %s: ops->alloc=%p dequeue=%p enqueue=%p\n",
            label, (void*)(uintptr_t)ops->alloc,
            (void*)(uintptr_t)ops->dequeue,
            (void*)(uintptr_t)ops->enqueue);
        // Raw hex dump of first 96 bytes of ops entry
        unsigned char *raw = (unsigned char*)ops;
        hw_dbg("[HW] %s: raw[0..47]= ", label);
        for (int i = 0; i < 48; i++) hw_dbg("%02X ", raw[i]);
        hw_dbg("\n");
        hw_dbg("[HW] %s: raw[48..95]=", label);
        for (int i = 48; i < 96; i++) hw_dbg("%02X ", raw[i]);
        hw_dbg("\n");
    } __except(1) {
        hw_dbg("[HW] %s: ops access SEH EXCEPTION\n", label);
    }
    // Also dump sizeof for struct verification
    hw_dbg("[HW] %s: sizeof(rte_mempool_ops)=%zu sizeof(rte_mempool)=%zu\n",
        label, sizeof(struct rte_mempool_ops), sizeof(struct rte_mempool));
}

// 9e. Mbuf pool create (SEH protected)
DPDK_API struct rte_mempool* hw_pktmbuf_pool_create_safe(
    const char *name, unsigned int n, unsigned int cache_size,
    uint16_t priv_size, uint16_t data_room_size, int socket_id) {
    __try {
        struct rte_mempool *mp = rte_pktmbuf_pool_create(name, n, cache_size, priv_size, data_room_size, socket_id);
        hw_dump_pool_ops(mp, "pool_create");
        return mp;
    } __except(1) {
        hw_dbg("[HW] rte_pktmbuf_pool_create SEH EXCEPTION\n");
        return NULL;
    }
}

// 9f. Device stop (SEH protected)
DPDK_API int hw_eth_dev_stop(uint16_t port_id) {
    __try {
        return rte_eth_dev_stop(port_id);
    } __except(1) {
        hw_dbg("[HW] rte_eth_dev_stop SEH EXCEPTION port=%u\n", port_id);
        return -1;
    }
}

// 9g. Device close (SEH protected)
DPDK_API int hw_eth_dev_close(uint16_t port_id) {
    __try {
        return rte_eth_dev_close(port_id);
    } __except(1) {
        hw_dbg("[HW] rte_eth_dev_close SEH EXCEPTION port=%u\n", port_id);
        return -1;
    }
}

// 9h. EAL cleanup (SEH protected)
DPDK_API int hw_eal_cleanup(void) {
    if (!g_eal_initialized) return 0;  // 중복 호출 보호
    g_eal_initialized = 0;  // prevent DllMain double-cleanup

    /* 시스템 튜닝 해제 */
    if (pfn_timeEndPeriod) pfn_timeEndPeriod(1);
    if (g_original_affinity)
        SetProcessAffinityMask(GetCurrentProcess(), g_original_affinity);

    // Free spill ring before EAL cleanup
    if (g_spill_ring) {
        // Drain any remaining mbufs
        void *obj;
        while (rte_ring_sc_dequeue(g_spill_ring, &obj) == 0)
            rte_pktmbuf_free((struct rte_mbuf *)obj);
        rte_ring_free(g_spill_ring);
        g_spill_ring = NULL;
    }

    __try {
        return rte_eal_cleanup();
    } __except(1) {
        hw_dbg("[HW] rte_eal_cleanup SEH EXCEPTION\n");
        return -1;
    }
}

// 9i. Eth stats get (SEH protected)
DPDK_API int hw_eth_stats_get(uint16_t port_id, struct rte_eth_stats *stats) {
    __try {
        return rte_eth_stats_get(port_id, stats);
    } __except(1) {
        hw_dbg("[HW] rte_eth_stats_get SEH EXCEPTION port=%u\n", port_id);
        if (stats) memset(stats, 0, sizeof(*stats));
        return -1;
    }
}

// 9j. Eth stats reset (SEH protected)
DPDK_API int hw_eth_stats_reset(uint16_t port_id) {
    __try {
        rte_eth_stats_reset(port_id);
        return 0;
    } __except(1) {
        hw_dbg("[HW] rte_eth_stats_reset SEH EXCEPTION port=%u\n", port_id);
        return -1;
    }
}

// 10. Simple Port Setup Helper (Simplifies C# P/Invoke)
// Configures 1 RX queue and 1 TX queue, enables Promiscuous mode, and Starts the port.
DPDK_API int hw_simple_port_setup(uint16_t port_id, struct rte_mempool *mbuf_pool,
                                    uint32_t link_speeds) {
    struct rte_eth_conf port_conf;
    const uint16_t rx_rings = 1, tx_rings = 1;
    uint16_t nb_rxd = 256;
    uint16_t nb_txd = 256;
    int retval;
    struct rte_eth_dev_info dev_info;
    struct rte_eth_txconf txconf;

    memset(&port_conf, 0, sizeof(port_conf));
    // Windows: LSC 인터럽트 비활성화 (ixgbe dev_start 크래시 방지)
    port_conf.intr_conf.lsc = 0;
    port_conf.intr_conf.rxq = 0;
    // Link speed: 0 = autoneg, otherwise RTE_ETH_LINK_SPEED_FIXED | speed
    if (link_speeds != 0)
        port_conf.link_speeds = link_speeds;
    hw_dbg("[HW] port_setup start (port=%u, pool=%p, link_speeds=0x%08X)\n",
           port_id, (void*)mbuf_pool, port_conf.link_speeds);

    if (!rte_eth_dev_is_valid_port(port_id)) {
        hw_dbg("[HW] port %u: invalid port\n", port_id);
        return -1;
    }
    hw_dbg("[HW] port %u: [1/7] valid port OK\n", port_id);

    memset(&dev_info, 0, sizeof(dev_info));
    retval = rte_eth_dev_info_get(port_id, &dev_info);
    if (retval != 0) { hw_dbg("[HW] port %u: [2/7] dev_info_get FAIL=%d\n", port_id, retval); return retval; }
    hw_dbg("[HW] port %u: [2/7] dev_info OK (driver=%s, max_rx_q=%u, max_tx_q=%u)\n",
           port_id, dev_info.driver_name ? dev_info.driver_name : "NULL",
           dev_info.max_rx_queues, dev_info.max_tx_queues);

    // Configure the Ethernet device (minimal config, no offloads)
    retval = rte_eth_dev_configure(port_id, rx_rings, tx_rings, &port_conf);
    if (retval != 0) { hw_dbg("[HW] port %u: [3/7] dev_configure FAIL=%d\n", port_id, retval); return retval; }
    hw_dbg("[HW] port %u: [3/7] dev_configure OK\n", port_id);

    retval = rte_eth_dev_adjust_nb_rx_tx_desc(port_id, &nb_rxd, &nb_txd);
    if (retval != 0) { hw_dbg("[HW] port %u: [4/7] adjust_desc FAIL=%d\n", port_id, retval); return retval; }
    hw_dbg("[HW] port %u: [4/7] adjust_desc OK (rxd=%u, txd=%u)\n", port_id, nb_rxd, nb_txd);

    // Windows에서 NUMA 미감지 시 socket_id가 -1이 되므로 0으로 보정
    int socket_id = rte_eth_dev_socket_id(port_id);
    if (socket_id < 0) socket_id = 0;
    hw_dbg("[HW] port %u: socket_id=%d\n", port_id, socket_id);

    // RX queue setup
    retval = rte_eth_rx_queue_setup(port_id, 0, nb_rxd, socket_id, NULL, mbuf_pool);
    if (retval < 0) { hw_dbg("[HW] port %u: [5/7] rx_queue_setup FAIL=%d\n", port_id, retval); return retval; }
    hw_dbg("[HW] port %u: [5/7] rx_queue_setup OK\n", port_id);

    // TX queue setup
    txconf = dev_info.default_txconf;
    txconf.offloads = port_conf.txmode.offloads;
    retval = rte_eth_tx_queue_setup(port_id, 0, nb_txd, socket_id, &txconf);
    if (retval < 0) { hw_dbg("[HW] port %u: [6/7] tx_queue_setup FAIL=%d\n", port_id, retval); return retval; }
    hw_dbg("[HW] port %u: [6/7] tx_queue_setup OK\n", port_id);

    // Start the Ethernet port (Windows SEH로 크래시 보호)
    hw_dbg("[HW] port %u: [7/7] dev_start calling...\n", port_id);
    {
        DWORD _seh_code = 0; void *_seh_addr = NULL; void *_seh_fault = NULL;
        __try {
            retval = rte_eth_dev_start(port_id);
        } __except(
            _seh_code = GetExceptionInformation()->ExceptionRecord->ExceptionCode,
            _seh_addr = (void*)GetExceptionInformation()->ExceptionRecord->ExceptionAddress,
            _seh_fault = GetExceptionInformation()->ExceptionRecord->NumberParameters >= 2
                ? (void*)GetExceptionInformation()->ExceptionRecord->ExceptionInformation[1] : NULL,
            EXCEPTION_EXECUTE_HANDLER) {
            // Identify crash module from instruction address
            HMODULE hMod = NULL; char modName[MAX_PATH] = "unknown";
            if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                   GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                   (LPCSTR)_seh_addr, &hMod)) {
                GetModuleFileNameA(hMod, modName, MAX_PATH);
                char *slash = strrchr(modName, '\\');
                if (slash) memmove(modName, slash+1, strlen(slash+1)+1);
            }
            hw_dbg("[HW] port %u: [7/7] dev_start SEH EXCEPTION! code=0x%08X\n", port_id, _seh_code);
            hw_dbg("[HW]   instruction at : %p\n", _seh_addr);
            hw_dbg("[HW]   fault address  : %p\n", _seh_fault);
            hw_dbg("[HW]   crash module   : %s + 0x%llX\n", modName,
                   (unsigned long long)((char*)_seh_addr - (char*)hMod));
            return -99;
        }
    }
    if (retval < 0) { hw_dbg("[HW] port %u: [7/7] dev_start FAIL=%d\n", port_id, retval); return retval; }
    hw_dbg("[HW] port %u: [7/7] dev_start OK\n", port_id);

    // Enable Promiscuous mode
    rte_eth_promiscuous_enable(port_id);

    // Create lock-free SPSC ring for spill buffer (if not already created)
    if (!g_spill_ring) {
        g_spill_ring = rte_ring_create("spill_ring", 256, socket_id,
                                        RING_F_SP_ENQ | RING_F_SC_DEQ);
        if (g_spill_ring)
            fprintf(stderr, "HW: spill_ring created (256 entries, SPSC)\n");
        else
            fprintf(stderr, "HW: WARNING — spill_ring creation failed!\n");
    }

    fprintf(stderr, "HW: port_setup DONE\n"); fflush(stderr);

    return 0;
}

// === 11. Req/Resp Single-Cycle Function (eliminates per-packet P/Invoke overhead) ===

#include <rte_ether.h>
#include <rte_ip.h>
#include <rte_udp.h>

typedef struct {
    int status;          // 0=success, 1=timeout, -1=alloc_fail, -2=tx_fail
    double rtt_ms;
    uint16_t resp_len;
    uint32_t src_ip;
    uint16_t src_port;
} hw_reqresp_result_t;

// IP header checksum (native, very fast for 20 bytes)
static uint16_t ip_cksum(const void *buf, int len) {
    const uint16_t *p = (const uint16_t *)buf;
    uint32_t sum = 0;
    while (len > 1) { sum += *p++; len -= 2; }
    if (len) sum += *(const uint8_t *)p;
    while (sum >> 16) sum = (sum & 0xFFFF) + (sum >> 16);
    return (uint16_t)~sum;
}

// Ethernet header offsets
#define ETH_HDR_LEN   14
#define IPV4_HDR_LEN  20
#define UDP_HDR_LEN   8
#define ARP_HDR_LEN   28

// Send ARP reply inline (proxy ARP — respond to any ARP request with our MAC)
static void send_arp_reply(uint16_t port_id, struct rte_mempool *pool,
                           const uint8_t *rx_data, uint16_t rx_len,
                           const uint8_t *local_mac)
{
    // ARP header starts at ETH_HDR_LEN (14)
    // ARP layout: hwtype(2) + proto(2) + hwlen(1) + protolen(1) + opcode(2)
    //             + sender_mac(6) + sender_ip(4) + target_mac(6) + target_ip(4) = 28 bytes
    if (rx_len < ETH_HDR_LEN + ARP_HDR_LEN) return;

    uint16_t opcode;
    memcpy(&opcode, rx_data + ETH_HDR_LEN + 6, 2);
    if (opcode != rte_cpu_to_be_16(1)) return; // Not ARP Request

    struct rte_mbuf *reply = rte_pktmbuf_alloc(pool);
    if (!reply) return;
    int reply_len = ETH_HDR_LEN + ARP_HDR_LEN;
    uint8_t *rdata = (uint8_t *)rte_pktmbuf_append(reply, reply_len);
    if (!rdata) { rte_pktmbuf_free(reply); return; }

    const uint8_t *sender_mac = rx_data + ETH_HDR_LEN + 8;  // ARP sender MAC
    const uint8_t *sender_ip  = rx_data + ETH_HDR_LEN + 14; // ARP sender IP
    const uint8_t *target_ip  = rx_data + ETH_HDR_LEN + 24; // ARP target IP

    // Ethernet header: dst=requester MAC, src=our MAC, type=0x0806
    memcpy(rdata + 0, sender_mac, 6);       // dst = requester
    memcpy(rdata + 6, local_mac, 6);        // src = our MAC
    rdata[12] = 0x08; rdata[13] = 0x06;     // ARP

    // ARP header
    rdata[14] = 0x00; rdata[15] = 0x01;     // hwtype = Ethernet
    rdata[16] = 0x08; rdata[17] = 0x00;     // proto = IPv4
    rdata[18] = 6;                           // hwlen
    rdata[19] = 4;                           // protolen
    rdata[20] = 0x00; rdata[21] = 0x02;     // opcode = Reply
    memcpy(rdata + 22, local_mac, 6);       // sender MAC = our MAC
    memcpy(rdata + 28, target_ip, 4);       // sender IP = requested IP (proxy ARP)
    memcpy(rdata + 32, sender_mac, 6);      // target MAC = requester MAC
    memcpy(rdata + 38, sender_ip, 4);       // target IP = requester IP

    struct rte_mbuf *tx[1] = { reply };
    if (rte_eth_tx_burst(port_id, 0, tx, 1) == 0)
        rte_pktmbuf_free(reply);
}

DPDK_API int hw_reqresp_once(
    uint16_t port_id,
    struct rte_mempool *pool,
    const uint8_t *template_pkt,
    uint16_t pkt_len,
    uint16_t packet_id,
    uint32_t expected_src_ip,
    uint16_t expected_dst_port,
    int timeout_ms,
    uint8_t *resp_buf,
    uint16_t resp_buf_size,
    hw_reqresp_result_t *result,
    const uint8_t *local_mac,
    uint32_t local_ip)
{
    static LARGE_INTEGER cached_freq = {0};
    LARGE_INTEGER send_tick, now_tick;
    struct rte_mbuf *rx_pkts[32];
    uint16_t nb_rx;
    int i;

    (void)local_ip; // reserved for future use

    // Cache QPC frequency (never changes, avoid syscall per-packet)
    if (cached_freq.QuadPart == 0)
        QueryPerformanceFrequency(&cached_freq);

    memset(result, 0, sizeof(*result));

    // 1. Alloc mbuf
    struct rte_mbuf *mbuf = rte_pktmbuf_alloc(pool);
    if (!mbuf) {
        result->status = -1;
        return -1;
    }

    // 2. Append space
    char *data = rte_pktmbuf_append(mbuf, pkt_len);
    if (!data) {
        rte_pktmbuf_free(mbuf);
        result->status = -1;
        return -1;
    }

    // 3. Copy template packet
    memcpy(data, template_pkt, pkt_len);

    // 4. Update PacketId + Incremental IP checksum
    //    Only PacketId changes, so use RFC 1624 incremental checksum update
    uint16_t old_id;
    memcpy(&old_id, data + ETH_HDR_LEN + 4, 2);
    uint16_t new_id = rte_cpu_to_be_16(packet_id);
    memcpy(data + ETH_HDR_LEN + 4, &new_id, 2);

    // Incremental checksum: ~new_ck = ~old_ck + ~old_id + new_id
    uint16_t old_ck;
    memcpy(&old_ck, data + ETH_HDR_LEN + 10, 2);
    uint32_t sum = (uint16_t)~old_ck + (uint16_t)~old_id + new_id;
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    uint16_t new_ck = (uint16_t)~sum;
    memcpy(data + ETH_HDR_LEN + 10, &new_ck, 2);

    // 5. TX burst
    struct rte_mbuf *tx_pkts[1] = { mbuf };
    uint16_t sent = rte_eth_tx_burst(port_id, 0, tx_pkts, 1);
    if (sent == 0) {
        rte_pktmbuf_free(mbuf);
        result->status = -2;
        return -2;
    }

    // 6. Start timer
    QueryPerformanceCounter(&send_tick);

    // 7. RX polling loop with rte_pause() for empty polls
    double timeout_sec = timeout_ms / 1000.0;
    int empty_polls = 0;
    uint16_t expected_dst_port_net = rte_cpu_to_be_16(expected_dst_port);
    uint16_t ipv4_ethertype = rte_cpu_to_be_16(0x0800);
    uint16_t arp_ethertype = rte_cpu_to_be_16(0x0806);

    while (1) {
        nb_rx = rte_eth_rx_burst(port_id, 0, rx_pkts, 32);

        if (nb_rx == 0) {
            rte_pause();
            if (++empty_polls < 64) continue;
            empty_polls = 0;
            // Fall through to timeout check
            goto check_timeout;
        }

        for (i = 0; i < nb_rx; i++) {
            /* Prefetch next packets */
            if (i + 1 < nb_rx)
                rte_prefetch0(rte_pktmbuf_mtod(rx_pkts[i + 1], void *));

            uint8_t *rx_data = rte_pktmbuf_mtod(rx_pkts[i], uint8_t *);
            uint16_t rx_len = rte_pktmbuf_data_len(rx_pkts[i]);

            // Check EtherType
            if (rx_len < ETH_HDR_LEN + 2) goto free_pkt;
            uint16_t ether_type;
            memcpy(&ether_type, rx_data + 12, 2);

            // === ARP handling: respond to ARP requests with our MAC ===
            if (ether_type == arp_ethertype) {
                send_arp_reply(port_id, pool, rx_data, rx_len, local_mac);
                goto free_pkt;
            }

            // Need at least ETH + IP + UDP headers for UDP matching
            if (rx_len < ETH_HDR_LEN + IPV4_HDR_LEN + UDP_HDR_LEN)
                goto free_pkt;

            if (ether_type != ipv4_ethertype)
                goto free_pkt;

            // Check IP protocol == 17 (UDP)
            uint8_t proto = rx_data[ETH_HDR_LEN + 9];
            if (proto != 17)
                goto free_pkt;

            // Check SrcAddr == expected_src_ip
            uint32_t rx_src_ip;
            memcpy(&rx_src_ip, rx_data + ETH_HDR_LEN + 12, 4);
            if (rx_src_ip != expected_src_ip)
                goto free_pkt;

            // Check UDP DstPort == expected_dst_port (our port, network byte order)
            uint16_t rx_dst_port;
            memcpy(&rx_dst_port, rx_data + ETH_HDR_LEN + IPV4_HDR_LEN + 2, 2);
            if (rx_dst_port != expected_dst_port_net)
                goto free_pkt;

            // === Match found! ===
            QueryPerformanceCounter(&now_tick);
            result->rtt_ms = (double)(now_tick.QuadPart - send_tick.QuadPart) * 1000.0 / cached_freq.QuadPart;
            result->status = 0;

            // Extract source port
            uint16_t rx_src_port_net;
            memcpy(&rx_src_port_net, rx_data + ETH_HDR_LEN + IPV4_HDR_LEN, 2);
            result->src_port = rte_be_to_cpu_16(rx_src_port_net);
            result->src_ip = rx_src_ip;

            // Copy response payload
            int payload_offset = ETH_HDR_LEN + IPV4_HDR_LEN + UDP_HDR_LEN;
            int payload_len = (int)rx_len - payload_offset;
            if (payload_len < 0) payload_len = 0;
            if (payload_len > resp_buf_size) payload_len = resp_buf_size;
            if (payload_len > 0)
                memcpy(resp_buf, rx_data + payload_offset, payload_len);
            result->resp_len = (uint16_t)payload_len;

            // Free all remaining mbufs
            rte_pktmbuf_free(rx_pkts[i]);
            for (int j = i + 1; j < nb_rx; j++)
                rte_pktmbuf_free(rx_pkts[j]);
            return 0;

        free_pkt:
            rte_pktmbuf_free(rx_pkts[i]);
        }

    check_timeout:
        QueryPerformanceCounter(&now_tick);
        if ((double)(now_tick.QuadPart - send_tick.QuadPart) / cached_freq.QuadPart >= timeout_sec)
            break;
    }

    // Timeout
    result->status = 1;
    result->rtt_ms = (double)timeout_ms;
    return 1;
}

/* ─── Multi-Channel safe Req/Resp (spill non-matching packets) ─── */

DPDK_API int hw_reqresp_once_mc(
    uint16_t port_id,
    struct rte_mempool *pool,
    const uint8_t *template_pkt,
    uint16_t pkt_len,
    uint16_t packet_id,
    uint32_t expected_src_ip,
    uint16_t expected_dst_port,
    int timeout_ms,
    uint8_t *resp_buf,
    uint16_t resp_buf_size,
    hw_reqresp_result_t *result,
    const uint8_t *local_mac,
    uint32_t local_ip)
{
    static LARGE_INTEGER cached_freq_mc = {0};
    static volatile int s_pinned = 0;
    LARGE_INTEGER send_tick, now_tick;
    struct rte_mbuf *rx_pkts[32];
    uint16_t nb_rx;
    int i;

    (void)local_ip;

    if (cached_freq_mc.QuadPart == 0)
        QueryPerformanceFrequency(&cached_freq_mc);

    /* DPDK 전용 코어에 고정 + 최고 우선순위 (1회만 실행) */
    if (!s_pinned) {
        if (g_dpdk_core >= 0) {
            DWORD_PTR dpdk_mask = (DWORD_PTR)1 << g_dpdk_core;
            SetThreadAffinityMask(GetCurrentThread(), dpdk_mask);
            hw_dbg("[HW] reqresp thread pinned to isolated core %d\n", g_dpdk_core);
        }
        SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
        s_pinned = 1;
    }

    memset(result, 0, sizeof(*result));

    // 1. Alloc mbuf
    struct rte_mbuf *mbuf = rte_pktmbuf_alloc(pool);
    if (!mbuf) {
        result->status = -1;
        return -1;
    }

    // 2. Append space
    char *data = rte_pktmbuf_append(mbuf, pkt_len);
    if (!data) {
        rte_pktmbuf_free(mbuf);
        result->status = -1;
        return -1;
    }

    // 3. Copy template packet
    memcpy(data, template_pkt, pkt_len);

    // 4. Update PacketId + Incremental IP checksum
    uint16_t old_id;
    memcpy(&old_id, data + ETH_HDR_LEN + 4, 2);
    uint16_t new_id = rte_cpu_to_be_16(packet_id);
    memcpy(data + ETH_HDR_LEN + 4, &new_id, 2);

    uint16_t old_ck;
    memcpy(&old_ck, data + ETH_HDR_LEN + 10, 2);
    uint32_t sum = (uint16_t)~old_ck + (uint16_t)~old_id + new_id;
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    uint16_t new_ck = (uint16_t)~sum;
    memcpy(data + ETH_HDR_LEN + 10, &new_ck, 2);

    // 5. TX burst (no spinlock needed — TX queue is separate)
    struct rte_mbuf *tx_pkts[1] = { mbuf };
    uint16_t sent = rte_eth_tx_burst(port_id, 0, tx_pkts, 1);
    if (sent == 0) {
        rte_pktmbuf_free(mbuf);
        result->status = -2;
        return -2;
    }

    // 6. Start timer
    QueryPerformanceCounter(&send_tick);

    // 7. RX polling loop with spinlock + spill for non-matching
    double timeout_sec = timeout_ms / 1000.0;
    int empty_polls = 0;
    uint16_t expected_dst_port_net = rte_cpu_to_be_16(expected_dst_port);
    uint16_t ipv4_ethertype = rte_cpu_to_be_16(0x0800);
    uint16_t arp_ethertype = rte_cpu_to_be_16(0x0806);

    while (1) {
        /* FTP/lwIP 활성 시 NIC RX를 건드리지 않고 대기 — mbuf pool 동시 접근 방지 */
        if (g_ftp_active) {
            Sleep(1);
            goto mc_check_timeout;
        }

        rte_spinlock_lock(&g_rx_lock);
        nb_rx = rte_eth_rx_burst(port_id, 0, rx_pkts, 16);
        rte_spinlock_unlock(&g_rx_lock);

        if (nb_rx == 0) {
            rte_pause();
            if (++empty_polls < 64) continue;
            empty_polls = 0;
            goto mc_check_timeout;
        }

        for (i = 0; i < nb_rx; i++) {
            /* Prefetch next packets */
            if (i + 1 < nb_rx)
                rte_prefetch0(rte_pktmbuf_mtod(rx_pkts[i + 1], void *));

            uint8_t *rx_data = rte_pktmbuf_mtod(rx_pkts[i], uint8_t *);
            uint16_t rx_len = rte_pktmbuf_data_len(rx_pkts[i]);

            // Check EtherType
            if (rx_len < ETH_HDR_LEN + 2) goto mc_spill_pkt;
            uint16_t ether_type;
            memcpy(&ether_type, rx_data + 12, 2);

            // ARP → spill (RX thread will handle via HandleArpPacket)
            if (ether_type == arp_ethertype) {
                send_arp_reply(port_id, pool, rx_data, rx_len, local_mac);
                goto mc_free_pkt;
            }

            if (rx_len < ETH_HDR_LEN + IPV4_HDR_LEN + UDP_HDR_LEN)
                goto mc_spill_pkt;

            if (ether_type != ipv4_ethertype)
                goto mc_spill_pkt;

            uint8_t proto = rx_data[ETH_HDR_LEN + 9];
            if (proto != 17)
                goto mc_spill_pkt;

            // Check SrcAddr == expected_src_ip
            uint32_t rx_src_ip;
            memcpy(&rx_src_ip, rx_data + ETH_HDR_LEN + 12, 4);
            if (rx_src_ip != expected_src_ip)
                goto mc_spill_pkt;

            // Check UDP DstPort == expected_dst_port
            uint16_t rx_dst_port;
            memcpy(&rx_dst_port, rx_data + ETH_HDR_LEN + IPV4_HDR_LEN + 2, 2);
            if (rx_dst_port != expected_dst_port_net)
                goto mc_spill_pkt;

            // === Match found! ===
            QueryPerformanceCounter(&now_tick);
            result->rtt_ms = (double)(now_tick.QuadPart - send_tick.QuadPart) * 1000.0 / cached_freq_mc.QuadPart;
            result->status = 0;

            uint16_t rx_src_port_net;
            memcpy(&rx_src_port_net, rx_data + ETH_HDR_LEN + IPV4_HDR_LEN, 2);
            result->src_port = rte_be_to_cpu_16(rx_src_port_net);
            result->src_ip = rx_src_ip;

            int payload_offset = ETH_HDR_LEN + IPV4_HDR_LEN + UDP_HDR_LEN;
            int payload_len = (int)rx_len - payload_offset;
            if (payload_len < 0) payload_len = 0;
            if (payload_len > resp_buf_size) payload_len = resp_buf_size;
            if (payload_len > 0)
                memcpy(resp_buf, rx_data + payload_offset, payload_len);
            result->resp_len = (uint16_t)payload_len;

            // Free matched mbuf, spill remaining (lock-free enqueue)
            rte_pktmbuf_free(rx_pkts[i]);
            for (int j = i + 1; j < nb_rx; j++) {
                if (!g_spill_ring ||
                    rte_ring_sp_enqueue(g_spill_ring, rx_pkts[j]) != 0)
                    rte_pktmbuf_free(rx_pkts[j]);
            }
            return 0;

        mc_spill_pkt:
            if (!g_spill_ring ||
                rte_ring_sp_enqueue(g_spill_ring, rx_pkts[i]) != 0)
                rte_pktmbuf_free(rx_pkts[i]);
            continue;

        mc_free_pkt:
            rte_pktmbuf_free(rx_pkts[i]);
        }

    mc_check_timeout:
        QueryPerformanceCounter(&now_tick);
        if ((double)(now_tick.QuadPart - send_tick.QuadPart) / cached_freq_mc.QuadPart >= timeout_sec)
            break;
    }

    // Timeout
    result->status = 1;
    result->rtt_ms = (double)timeout_ms;
    return 1;
}

/* ─── Batch (pipelined) Req/Resp ─── */

typedef struct {
    uint16_t sent;
    uint16_t received;
    double elapsed_ms;
    double total_rtt_ms;
    double min_rtt_ms;
    double max_rtt_ms;
    double total_rtt_sq_ms;
} hw_batch_stats_t;

DPDK_API int hw_reqresp_batch(
    uint16_t port_id,
    struct rte_mempool *pool,
    const uint8_t *template_pkt,
    uint16_t pkt_len,
    uint16_t start_packet_id,
    uint16_t count,
    uint32_t expected_src_ip,
    uint16_t expected_dst_port,
    int timeout_ms,
    hw_batch_stats_t *stats,
    const uint8_t *local_mac,
    uint32_t local_ip)
{
    static LARGE_INTEGER cached_freq = {0};
    LARGE_INTEGER batch_start, tx_done_tick, now_tick;
    uint16_t expected_dst_port_net = rte_cpu_to_be_16(expected_dst_port);
    uint16_t ipv4_ethertype = rte_cpu_to_be_16(0x0800);
    uint16_t arp_ethertype = rte_cpu_to_be_16(0x0806);

    (void)local_ip;

    if (cached_freq.QuadPart == 0)
        QueryPerformanceFrequency(&cached_freq);

    memset(stats, 0, sizeof(*stats));
    stats->min_rtt_ms = 1e9;

    if (count == 0) return 0;

    /* ── Phase 1: TX — send all packets in rapid succession ── */
    QueryPerformanceCounter(&batch_start);

    struct rte_mbuf *tx_batch[32];
    uint16_t total_sent = 0;
    uint16_t batch_idx = 0;

    for (uint16_t i = 0; i < count; i++) {
        struct rte_mbuf *mbuf = rte_pktmbuf_alloc(pool);
        if (!mbuf) break;

        char *data = rte_pktmbuf_append(mbuf, pkt_len);
        if (!data) { rte_pktmbuf_free(mbuf); break; }

        memcpy(data, template_pkt, pkt_len);

        /* Update PacketId + incremental checksum */
        uint16_t old_id;
        memcpy(&old_id, data + ETH_HDR_LEN + 4, 2);
        uint16_t new_id = rte_cpu_to_be_16((uint16_t)(start_packet_id + i));
        memcpy(data + ETH_HDR_LEN + 4, &new_id, 2);

        uint16_t old_ck;
        memcpy(&old_ck, data + ETH_HDR_LEN + 10, 2);
        uint32_t sum = (uint16_t)~old_ck + (uint16_t)~old_id + new_id;
        sum = (sum >> 16) + (sum & 0xffff);
        sum += (sum >> 16);
        uint16_t new_ck = (uint16_t)~sum;
        memcpy(data + ETH_HDR_LEN + 10, &new_ck, 2);

        tx_batch[batch_idx++] = mbuf;

        /* Flush when batch full or last packet */
        if (batch_idx == 32 || i == count - 1) {
            uint16_t nb_tx = rte_eth_tx_burst(port_id, 0, tx_batch, batch_idx);
            total_sent += nb_tx;
            /* Free unsent mbufs */
            for (uint16_t k = nb_tx; k < batch_idx; k++)
                rte_pktmbuf_free(tx_batch[k]);
            batch_idx = 0;
        }
    }

    /* RTT baseline: right after all TX enqueued to NIC */
    QueryPerformanceCounter(&tx_done_tick);

    stats->sent = total_sent;
    if (total_sent == 0) return -1;

    /* ── Phase 2: RX — collect responses until all received or timeout ── */
    double timeout_sec = timeout_ms / 1000.0;
    uint16_t received = 0;
    int empty_polls = 0;
    struct rte_mbuf *rx_pkts[32];

    while (received < total_sent) {
        uint16_t nb_rx = rte_eth_rx_burst(port_id, 0, rx_pkts, 32);

        if (nb_rx == 0) {
            rte_pause();
            if (++empty_polls < 64) continue;
            empty_polls = 0;
            goto batch_check_timeout;
        }
        empty_polls = 0;

        for (uint16_t j = 0; j < nb_rx; j++) {
            uint8_t *rx_data = rte_pktmbuf_mtod(rx_pkts[j], uint8_t *);
            uint16_t rx_len = rte_pktmbuf_data_len(rx_pkts[j]);

            if (rx_len < ETH_HDR_LEN + 2) goto batch_free_pkt;
            uint16_t ether_type;
            memcpy(&ether_type, rx_data + 12, 2);

            if (ether_type == arp_ethertype) {
                send_arp_reply(port_id, pool, rx_data, rx_len, local_mac);
                goto batch_free_pkt;
            }

            if (rx_len < ETH_HDR_LEN + IPV4_HDR_LEN + UDP_HDR_LEN)
                goto batch_free_pkt;
            if (ether_type != ipv4_ethertype)
                goto batch_free_pkt;
            if (rx_data[ETH_HDR_LEN + 9] != 17)
                goto batch_free_pkt;

            uint32_t rx_src_ip;
            memcpy(&rx_src_ip, rx_data + ETH_HDR_LEN + 12, 4);
            if (rx_src_ip != expected_src_ip)
                goto batch_free_pkt;

            uint16_t rx_dst_port;
            memcpy(&rx_dst_port, rx_data + ETH_HDR_LEN + IPV4_HDR_LEN + 2, 2);
            if (rx_dst_port != expected_dst_port_net)
                goto batch_free_pkt;

            /* Match found — RTT from tx_done (not batch_start) for accuracy */
            QueryPerformanceCounter(&now_tick);
            double rtt = (double)(now_tick.QuadPart - tx_done_tick.QuadPart) * 1000.0 / cached_freq.QuadPart;
            stats->total_rtt_ms += rtt;
            stats->total_rtt_sq_ms += rtt * rtt;
            if (rtt < stats->min_rtt_ms) stats->min_rtt_ms = rtt;
            if (rtt > stats->max_rtt_ms) stats->max_rtt_ms = rtt;
            received++;

        batch_free_pkt:
            rte_pktmbuf_free(rx_pkts[j]);
        }
        continue;

    batch_check_timeout:
        QueryPerformanceCounter(&now_tick);
        if ((double)(now_tick.QuadPart - batch_start.QuadPart) / cached_freq.QuadPart >= timeout_sec)
            break;
    }

    stats->received = received;
    QueryPerformanceCounter(&now_tick);
    stats->elapsed_ms = (double)(now_tick.QuadPart - batch_start.QuadPart) * 1000.0 / cached_freq.QuadPart;
    if (received == 0) stats->min_rtt_ms = 0;

    return (received == total_sent) ? 0 : 1;
}

/* ================================================================
 * lwIP / FTP integration
 * ================================================================ */

/* External declarations: dpdk_netif.c */
extern int  dpdk_lwip_init(uint16_t port_id, struct rte_mempool *pool,
                           uint32_t ip_addr, uint32_t netmask, uint32_t gateway,
                           const uint8_t *mac);
extern void dpdk_lwip_stop(void);
extern int  dpdk_lwip_poll_once(void);
extern int  dpdk_lwip_poll_ms(int max_ms);
extern int  dpdk_netif_input_mbuf(struct rte_mbuf *mbuf);
extern void dpdk_netif_set_external_rx(int enabled);
extern int  dpdk_lwip_is_running(void);

/* --- FTP client types and functions (from dpdk_ftp_client.c) --- */

/* FTP states — must match dpdk_ftp_client.c */
enum {
    FTP_STATE_IDLE = 0,
    FTP_STATE_CONNECTING,
    FTP_STATE_WAIT_WELCOME,
    FTP_STATE_SENDING_USER,
    FTP_STATE_WAIT_USER,
    FTP_STATE_SENDING_PASS,
    FTP_STATE_WAIT_PASS,
    FTP_STATE_READY,
    FTP_STATE_SENDING_PASV,
    FTP_STATE_WAIT_PASV,
    FTP_STATE_DATA_CONNECTING,
    FTP_STATE_SENDING_CMD,
    FTP_STATE_TRANSFERRING,
    FTP_STATE_WAIT_DONE,
    FTP_STATE_ERROR
};

/* Must match dpdk_ftp_client.c exactly */
typedef struct {
    struct tcp_pcb *ctrl_pcb;
    struct tcp_pcb *data_pcb;
    int state;
    int response_code;
    char response_buf[4096];
    int response_len;
    uint8_t *recv_buf;
    uint32_t recv_len;
    uint32_t recv_capacity;
    const uint8_t *send_data;
    uint32_t send_len;
    uint32_t send_offset;
    uint32_t pasv_ip;
    uint16_t pasv_port;
    char pending_cmd[256];
    volatile int op_done;
    int op_result;
    int is_upload;
} ftp_client_t;

/* External FTP functions (dpdk_ftp_client.c) */
extern void ftp_client_init(ftp_client_t *ftp);
extern int  ftp_connect(ftp_client_t *ftp, uint32_t server_ip, uint16_t port);
extern int  ftp_send_cmd(ftp_client_t *ftp, const char *cmd);
extern int  ftp_start_pasv(ftp_client_t *ftp);
extern int  ftp_start_list(ftp_client_t *ftp, uint8_t *buf, uint32_t buf_size);
extern int  ftp_start_retr(ftp_client_t *ftp, const char *path, uint8_t *buf, uint32_t buf_size);
extern int  ftp_start_stor(ftp_client_t *ftp, const char *path, const uint8_t *data, uint32_t len);
extern void ftp_cleanup_data(ftp_client_t *ftp);
extern void ftp_disconnect(ftp_client_t *ftp);
extern int  ftp_get_state(ftp_client_t *ftp);

/* Multi-session FTP client pool (one per channel) */
#define MAX_FTP_SESSIONS 4
static ftp_client_t g_ftp_sessions[MAX_FTP_SESSIONS];
static volatile int g_lwip_ref_count = 0;

/* Backward compat: g_ftp alias for session 0 */
#define g_ftp g_ftp_sessions[0]

/* lwIP poll lock — prevents concurrent sys_check_timeouts from multiple ftp_poll threads */
static rte_spinlock_t g_lwip_poll_lock = RTE_SPINLOCK_INITIALIZER;

static void lwip_poll_once_safe(void) {
    rte_spinlock_lock(&g_lwip_poll_lock);
    dpdk_lwip_poll_once();
    rte_spinlock_unlock(&g_lwip_poll_lock);
}

/* --- Helper: poll until op_done or timeout (per-session) --- */
static int ftp_poll_wait_session(ftp_client_t *ftp, int timeout_ms)
{
    DWORD start = (DWORD)GetTickCount64();
    int last_state = ftp->state;
    while (!ftp->op_done) {
        if ((int)((DWORD)GetTickCount64() - start) >= timeout_ms) {
            hw_dbg("[HW] ftp_poll_wait: TIMEOUT after %dms (state=%d)\n",
                     timeout_ms, ftp->state);
            ftp->op_result = 1; /* timeout */
            return 1;
        }
        lwip_poll_once_safe();
        if (ftp->state != last_state) {
            hw_dbg("[HW] ftp_poll_wait: state %d -> %d\n", last_state, ftp->state);
            last_state = ftp->state;
        }
        Sleep(1); /* CPU 양보 — busy loop 방지 */
    }
    return ftp->op_result;
}

/* Backward compat wrapper */
static int ftp_poll_wait(int timeout_ms) {
    return ftp_poll_wait_session(&g_ftp, timeout_ms);
}

/* --- Helper: parse dotted-decimal IP string to network-order uint32 --- */
static uint32_t parse_ip_str(const char *s)
{
    unsigned int a, b, c, d;
    if (sscanf(s, "%u.%u.%u.%u", &a, &b, &c, &d) != 4)
        return 0;
    return (uint32_t)(a | (b << 8) | (c << 16) | (d << 24));
}

/* ================================================================
 * lwIP pass-through exports
 * ================================================================ */

DPDK_API int hw_lwip_init(uint16_t port_id, void *pool,
    uint32_t ip, uint32_t mask, uint32_t gw, const uint8_t *mac)
{
    return dpdk_lwip_init(port_id, (struct rte_mempool *)pool, ip, mask, gw, mac);
}

DPDK_API void hw_lwip_stop(void)
{
    dpdk_lwip_stop();
}

DPDK_API int hw_lwip_poll(int max_ms)
{
    return dpdk_lwip_poll_ms(max_ms);
}

/* --- lwIP reference-counted init/stop for multi-session FTP --- */
/* Protected by g_lwip_poll_lock to prevent race between concurrent init/stop calls */
DPDK_API int hw_lwip_init_ref(uint16_t port_id, void *pool,
    uint32_t ip, uint32_t mask, uint32_t gw, const uint8_t *mac)
{
    rte_spinlock_lock(&g_lwip_poll_lock);
    if (g_lwip_ref_count == 0) {
        int ret = dpdk_lwip_init(port_id, (struct rte_mempool *)pool, ip, mask, gw, mac);
        if (ret != 0) {
            rte_spinlock_unlock(&g_lwip_poll_lock);
            return ret;
        }
    }
    g_lwip_ref_count++;
    hw_dbg("[HW] lwip_init_ref: ref_count=%d\n", g_lwip_ref_count);
    rte_spinlock_unlock(&g_lwip_poll_lock);
    return 0;
}

DPDK_API void hw_lwip_stop_ref(void)
{
    rte_spinlock_lock(&g_lwip_poll_lock);
    if (g_lwip_ref_count <= 0) {
        rte_spinlock_unlock(&g_lwip_poll_lock);
        return;
    }
    g_lwip_ref_count--;
    hw_dbg("[HW] lwip_stop_ref: ref_count=%d\n", g_lwip_ref_count);
    if (g_lwip_ref_count == 0) {
        dpdk_lwip_stop();
    }
    rte_spinlock_unlock(&g_lwip_poll_lock);
}

/* ================================================================
 * FTP synchronous wrappers (exported for C# P/Invoke)
 * ================================================================ */

DPDK_API int hw_ftp_connect_sync(const char *server_ip, uint16_t port,
    const char *user, const char *pass, int timeout_ms)
{
    ftp_client_init(&g_ftp);

    uint32_t ip = parse_ip_str(server_ip);
    if (ip == 0) {
        hw_dbg("[HW] ftp_connect_sync: invalid IP '%s'\n", server_ip);
        return -1;
    }

    hw_dbg("[HW] ftp_connect_sync: connecting to %s:%u\n", server_ip, port);

    /* Phase 1: TCP connect + wait for 220 welcome */
    if (ftp_connect(&g_ftp, ip, port) != 0)
        return -1;

    if (ftp_poll_wait(timeout_ms) != 0) {
        hw_dbg("[HW] ftp_connect_sync: connect/welcome failed (state=%d)\n", g_ftp.state);
        ftp_disconnect(&g_ftp);
        return -1;
    }

    /* Phase 2: USER */
    {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "USER %s\r\n", user);
        g_ftp.state = FTP_STATE_WAIT_USER;
        if (ftp_send_cmd(&g_ftp, cmd) != 0) {
            ftp_disconnect(&g_ftp);
            return -1;
        }
        if (ftp_poll_wait(timeout_ms) != 0) {
            hw_dbg("[HW] ftp_connect_sync: USER failed\n");
            ftp_disconnect(&g_ftp);
            return -1;
        }
    }

    /* If we got 230 (no password needed), skip PASS and go to TYPE I */
    if (g_ftp.response_code == 230) {
        hw_dbg("[HW] ftp_connect_sync: logged in (no password), setting binary mode\n");
        goto set_binary_mode;
    }

    /* Phase 3: PASS */
    {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "PASS %s\r\n", pass);
        g_ftp.state = FTP_STATE_WAIT_PASS;
        if (ftp_send_cmd(&g_ftp, cmd) != 0) {
            ftp_disconnect(&g_ftp);
            return -1;
        }
        if (ftp_poll_wait(timeout_ms) != 0) {
            hw_dbg("[HW] ftp_connect_sync: PASS failed\n");
            ftp_disconnect(&g_ftp);
            return -1;
        }
    }

set_binary_mode:
    /* Phase 4: TYPE I (binary mode) — MUST be set before any RETR/STOR
     * Without this, FTP defaults to ASCII mode which converts LF<->CRLF,
     * corrupting binary file transfers (.bin, .dat, etc.) */
    {
        g_ftp.state = FTP_STATE_READY;
        if (ftp_send_cmd(&g_ftp, "TYPE I\r\n") != 0) {
            hw_dbg("[HW] ftp_connect_sync: TYPE I send failed\n");
            ftp_disconnect(&g_ftp);
            return -1;
        }
        if (ftp_poll_wait(timeout_ms) != 0) {
            hw_dbg("[HW] ftp_connect_sync: TYPE I timeout\n");
            ftp_disconnect(&g_ftp);
            return -1;
        }
        if (g_ftp.response_code != 200) {
            hw_dbg("[HW] ftp_connect_sync: TYPE I unexpected response %d\n",
                     g_ftp.response_code);
            ftp_disconnect(&g_ftp);
            return -1;
        }
    }

    hw_dbg("[HW] ftp_connect_sync: logged in OK (binary mode)\n");
    return 0;
}

DPDK_API int hw_ftp_disconnect(void)
{
    /* Try to send QUIT gracefully */
    if (g_ftp.ctrl_pcb) {
        g_ftp.op_done = 0;
        g_ftp.op_result = 0;
        ftp_send_cmd(&g_ftp, "QUIT\r\n");
        /* Brief wait for 221 */
        DWORD start = (DWORD)GetTickCount64();
        while (!g_ftp.op_done && (int)((DWORD)GetTickCount64() - start) < 2000)
            dpdk_lwip_poll_once();
    }
    ftp_disconnect(&g_ftp);
    return 0;
}

DPDK_API int hw_ftp_pwd(char *buf, int buf_size)
{
    if (g_ftp.state != FTP_STATE_READY) return -1;

    g_ftp.state = FTP_STATE_READY; /* stay in READY for generic response */
    if (ftp_send_cmd(&g_ftp, "PWD\r\n") != 0)
        return -1;

    if (ftp_poll_wait(10000) != 0)
        return -1;

    if (g_ftp.response_code != 257)
        return -1;

    /* Parse 257 "path" - extract the quoted string */
    const char *q1 = strchr(g_ftp.response_buf, '"');
    if (q1) {
        const char *q2 = strchr(q1 + 1, '"');
        if (q2) {
            int plen = (int)(q2 - q1 - 1);
            if (plen >= buf_size) plen = buf_size - 1;
            memcpy(buf, q1 + 1, plen);
            buf[plen] = '\0';
            return plen;
        }
    }

    /* Fallback: copy raw response */
    int clen = g_ftp.response_len;
    if (clen >= buf_size) clen = buf_size - 1;
    memcpy(buf, g_ftp.response_buf, clen);
    buf[clen] = '\0';
    return clen;
}

DPDK_API int hw_ftp_cwd(const char *path)
{
    if (g_ftp.state != FTP_STATE_READY) return -1;

    char cmd[512];
    snprintf(cmd, sizeof(cmd), "CWD %s\r\n", path);

    g_ftp.state = FTP_STATE_READY;
    if (ftp_send_cmd(&g_ftp, cmd) != 0)
        return -1;

    if (ftp_poll_wait(10000) != 0)
        return -1;

    return (g_ftp.response_code == 250) ? 0 : -1;
}

DPDK_API int hw_ftp_list_sync(char *buf, int buf_size, int *out_len, int timeout_ms)
{
    hw_dbg("[HW] ftp_list_sync: state=%d, timeout=%d\n", g_ftp.state, timeout_ms);

    if (g_ftp.state != FTP_STATE_READY) {
        hw_dbg("[HW] ftp_list_sync: NOT READY (state=%d)\n", g_ftp.state);
        return -1;
    }

    if (ftp_start_list(&g_ftp, (uint8_t *)buf, (uint32_t)buf_size) != 0) {
        hw_dbg("[HW] ftp_list_sync: ftp_start_list failed\n");
        return -1;
    }

    hw_dbg("[HW] ftp_list_sync: PASV sent, polling...\n");
    int ret = ftp_poll_wait(timeout_ms);
    hw_dbg("[HW] ftp_list_sync: poll_wait returned %d, state=%d, recv_len=%u\n",
             ret, g_ftp.state, g_ftp.recv_len);

    if (ret != 0) {
        hw_dbg("[HW] ftp_list_sync: FAILED (state=%d, op_result=%d, resp_code=%d)\n",
                 g_ftp.state, g_ftp.op_result, g_ftp.response_code);
        hw_dbg("[HW] ftp_list_sync: response_buf='%.*s'\n",
                 g_ftp.response_len > 200 ? 200 : g_ftp.response_len, g_ftp.response_buf);
        ftp_cleanup_data(&g_ftp);
        return -1;
    }

    if (out_len) *out_len = (int)g_ftp.recv_len;
    /* Null-terminate if space */
    if ((int)g_ftp.recv_len < buf_size)
        buf[g_ftp.recv_len] = '\0';

    return 0;
}

DPDK_API int hw_ftp_download_sync(const char *path, uint8_t *buf, int buf_size,
    int *out_len, int timeout_ms)
{
    if (g_ftp.state != FTP_STATE_READY) {
        hw_dbg("[HW] ftp_download_sync: NOT READY (state=%d)\n", g_ftp.state);
        return -1;
    }

    if (ftp_start_retr(&g_ftp, path, buf, (uint32_t)buf_size) != 0)
        return -1;

    if (ftp_poll_wait(timeout_ms) != 0) {
        hw_dbg("[HW] ftp_download_sync: timeout/error (state=%d, resp=%d)\n",
                 g_ftp.state, g_ftp.response_code);
        ftp_cleanup_data(&g_ftp);
        return -1;
    }

    if (out_len) *out_len = (int)g_ftp.recv_len;
    return 0;
}

DPDK_API int hw_ftp_upload_sync(const char *path, const uint8_t *data, int data_len,
    int timeout_ms)
{
    if (g_ftp.state != FTP_STATE_READY) return -1;

    if (ftp_start_stor(&g_ftp, path, data, (uint32_t)data_len) != 0)
        return -1;

    if (ftp_poll_wait(timeout_ms) != 0) {
        hw_dbg("[HW] ftp_upload_sync: timeout/error (state=%d, resp=%d)\n",
                 g_ftp.state, g_ftp.response_code);
        ftp_cleanup_data(&g_ftp);
        return -1;
    }

    return 0;
}

DPDK_API int hw_ftp_get_state(void)
{
    return g_ftp.state;
}

/* ================================================================
 * Multi-session FTP _ex APIs (session_id = 0..MAX_FTP_SESSIONS-1)
 * ================================================================ */

static ftp_client_t *get_session(int id) {
    if (id < 0 || id >= MAX_FTP_SESSIONS) return NULL;
    return &g_ftp_sessions[id];
}

DPDK_API int hw_ftp_connect_sync_ex(int session_id,
    const char *server_ip, uint16_t port,
    const char *user, const char *pass, int timeout_ms)
{
    ftp_client_t *ftp = get_session(session_id);
    if (!ftp) return -1;

    ftp_client_init(ftp);

    uint32_t ip = parse_ip_str(server_ip);
    if (ip == 0) {
        hw_dbg("[HW] ftp_connect_ex[%d]: invalid IP '%s'\n", session_id, server_ip);
        return -1;
    }

    hw_dbg("[HW] ftp_connect_ex[%d]: connecting to %s:%u\n", session_id, server_ip, port);

    if (ftp_connect(ftp, ip, port) != 0)
        return -1;

    if (ftp_poll_wait_session(ftp, timeout_ms) != 0) {
        hw_dbg("[HW] ftp_connect_ex[%d]: connect/welcome failed (state=%d)\n", session_id, ftp->state);
        ftp_disconnect(ftp);
        return -1;
    }

    /* USER */
    {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "USER %s\r\n", user);
        ftp->state = FTP_STATE_WAIT_USER;
        if (ftp_send_cmd(ftp, cmd) != 0) { ftp_disconnect(ftp); return -1; }
        if (ftp_poll_wait_session(ftp, timeout_ms) != 0) {
            hw_dbg("[HW] ftp_connect_ex[%d]: USER failed\n", session_id);
            ftp_disconnect(ftp);
            return -1;
        }
    }

    if (ftp->response_code == 230)
        goto set_binary_ex;

    /* PASS */
    {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "PASS %s\r\n", pass);
        ftp->state = FTP_STATE_WAIT_PASS;
        if (ftp_send_cmd(ftp, cmd) != 0) { ftp_disconnect(ftp); return -1; }
        if (ftp_poll_wait_session(ftp, timeout_ms) != 0) {
            hw_dbg("[HW] ftp_connect_ex[%d]: PASS failed\n", session_id);
            ftp_disconnect(ftp);
            return -1;
        }
    }

set_binary_ex:
    /* TYPE I (binary mode) */
    {
        ftp->state = FTP_STATE_READY;
        if (ftp_send_cmd(ftp, "TYPE I\r\n") != 0) { ftp_disconnect(ftp); return -1; }
        if (ftp_poll_wait_session(ftp, timeout_ms) != 0) {
            hw_dbg("[HW] ftp_connect_ex[%d]: TYPE I timeout\n", session_id);
            ftp_disconnect(ftp);
            return -1;
        }
        if (ftp->response_code != 200) {
            hw_dbg("[HW] ftp_connect_ex[%d]: TYPE I unexpected %d\n", session_id, ftp->response_code);
            ftp_disconnect(ftp);
            return -1;
        }
    }

    _InterlockedIncrement((volatile long *)&g_ftp_active);
    hw_dbg("[HW] ftp_connect_ex[%d]: logged in OK (binary mode, ftp_active=%d)\n", session_id, g_ftp_active);
    return 0;
}

DPDK_API int hw_ftp_disconnect_ex(int session_id)
{
    ftp_client_t *ftp = get_session(session_id);
    if (!ftp) return -1;

    if (ftp->ctrl_pcb) {
        ftp->op_done = 0;
        ftp->op_result = 0;
        ftp_send_cmd(ftp, "QUIT\r\n");
        DWORD start = (DWORD)GetTickCount64();
        DWORD start = (DWORD)GetTickCount64();
        while (!ftp->op_done && (int)((DWORD)GetTickCount64() - start) < 2000)
            lwip_poll_once_safe();
    }
    ftp_disconnect(ftp);
    _InterlockedDecrement((volatile long *)&g_ftp_active);
    return 0;
}

DPDK_API int hw_ftp_download_sync_ex(int session_id,
    const char *path, uint8_t *buf, int buf_size,
    int *out_len, int timeout_ms)
{
    ftp_client_t *ftp = get_session(session_id);
    if (!ftp) return -1;

    if (ftp->state != FTP_STATE_READY) {
        hw_dbg("[HW] ftp_download_ex[%d]: NOT READY (state=%d)\n", session_id, ftp->state);
        return -1;
    }

    if (ftp_start_retr(ftp, path, buf, (uint32_t)buf_size) != 0)
        return -1;

    if (ftp_poll_wait_session(ftp, timeout_ms) != 0) {
        hw_dbg("[HW] ftp_download_ex[%d]: timeout/error (state=%d, resp=%d)\n",
                 session_id, ftp->state, ftp->response_code);
        ftp_cleanup_data(ftp);
        return -1;
    }

    if (out_len) *out_len = (int)ftp->recv_len;
    return 0;
}

DPDK_API int hw_ftp_upload_sync_ex(int session_id,
    const char *path, const uint8_t *data, int data_len,
    int timeout_ms)
{
    ftp_client_t *ftp = get_session(session_id);
    if (!ftp) return -1;

    if (ftp->state != FTP_STATE_READY) return -1;

    if (ftp_start_stor(ftp, path, data, (uint32_t)data_len) != 0)
        return -1;

    if (ftp_poll_wait_session(ftp, timeout_ms) != 0) {
        hw_dbg("[HW] ftp_upload_ex[%d]: timeout/error (state=%d, resp=%d)\n",
                 session_id, ftp->state, ftp->response_code);
        ftp_cleanup_data(ftp);
        return -1;
    }

    return 0;
}

DPDK_API int hw_ftp_get_state_ex(int session_id)
{
    ftp_client_t *ftp = get_session(session_id);
    if (!ftp) return -1;
    return ftp->state;
}

// ================================================================
// Diagnostic: read debug log file contents (last N bytes)
// ================================================================
DPDK_API int hw_read_debug_log(char *buf, int buf_size) {
    if (buf == NULL || buf_size <= 0) return 0;
    const char *path = (g_dbg_path[0] != '\0') ? g_dbg_path : "hw_diag.log";
    HANDLE h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) { buf[0] = '\0'; return 0; }
    DWORD read_bytes = 0;
    LARGE_INTEGER sz;
    GetFileSizeEx(h, &sz);
    if (sz.QuadPart > (LONGLONG)(buf_size - 1)) {
        LARGE_INTEGER offset;
        offset.QuadPart = sz.QuadPart - (buf_size - 1);
        SetFilePointerEx(h, offset, NULL, FILE_BEGIN);
    }
    ReadFile(h, buf, (DWORD)(buf_size - 1), &read_bytes, NULL);
    CloseHandle(h);
    buf[read_bytes] = '\0';
    return (int)read_bytes;
}

// ================================================================
// Diagnostic: test hugepage availability before EAL init
// Returns 0 on success, or GetLastError() on failure (e.g. 1450 = ERROR_NO_SYSTEM_RESOURCES)
// ================================================================
DPDK_API int hw_check_hugepage(int test_mb) {
    SIZE_T sz = (SIZE_T)test_mb * 1024 * 1024;
    if (sz == 0) sz = 2 * 1024 * 1024;  // minimum 2MB (1 large page)

    /* Need SeLockMemoryPrivilege for MEM_LARGE_PAGES */
    HANDLE hToken = NULL;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) {
        TOKEN_PRIVILEGES tp;
        tp.PrivilegeCount = 1;
        tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
        if (LookupPrivilegeValueA(NULL, "SeLockMemoryPrivilege", &tp.Privileges[0].Luid))
            AdjustTokenPrivileges(hToken, FALSE, &tp, 0, NULL, NULL);
        CloseHandle(hToken);
    }

    void *p = VirtualAlloc(NULL, sz,
        MEM_RESERVE | MEM_COMMIT | MEM_LARGE_PAGES, PAGE_READWRITE);
    if (p == NULL) {
        DWORD err = GetLastError();
        hw_dbg("[HW] hugepage check FAIL: %dMB err=%lu\n", test_mb, err);
        return (int)err;
    }
    VirtualFree(p, 0, MEM_RELEASE);
    hw_dbg("[HW] hugepage check OK: %dMB\n", test_mb);
    return 0;
}

/* DllMain — safety net for hugepage cleanup on process exit/crash.
 * If the app exits without calling hw_eal_cleanup(), this ensures
 * VirtualAlloc2(MEM_LARGE_PAGES) pages are freed back to the OS pool.
 */

/* ============================================================
 * Unified packet dispatcher: single rx_burst → protocol demux
 *
 * - UDP packets → out_udp_pkts (caller processes for PG drivers)
 * - TCP/ARP/ICMP → lwIP via dpdk_netif_input_mbuf()
 * - lwIP timers checked via dpdk_lwip_poll_once() (with external_rx=1, skips rx_burst)
 *
 * Returns: number of UDP packets placed in out_udp_pkts
 * ============================================================ */
DPDK_API uint16_t hw_dispatch_poll(
    uint16_t port_id, uint16_t queue_id,
    struct rte_mbuf **out_udp_pkts, uint16_t max_udp,
    int *out_lwip_count)
{
  __try {
    struct rte_mbuf *rx_pkts[64];
    uint16_t udp_count = 0;
    int lwip_count = 0;

    /* 1. Drain spill ring (lock-free SPSC dequeue) */
    if (g_spill_ring) {
        void *obj;
        while (udp_count < max_udp &&
               rte_ring_sc_dequeue(g_spill_ring, &obj) == 0) {
            out_udp_pkts[udp_count++] = (struct rte_mbuf *)obj;
        }
    }

    /* 2. Burst from NIC (trylock — reqresp_once_mc has priority over dispatch) */
    /* reqresp가 NIC을 사용 중이면 이번 poll은 spill ring만 처리하고 skip */
    uint16_t nb_rx = 0;
    if (rte_spinlock_trylock(&g_rx_lock)) {
        nb_rx = rte_eth_rx_burst(port_id, queue_id, rx_pkts, 64);
        rte_spinlock_unlock(&g_rx_lock);
    }

    /* 3. Classify each packet by protocol (with prefetch) */
    for (uint16_t i = 0; i < nb_rx; i++) {
        /* Prefetch next packets into L1 cache while processing current */
        if (i + 1 < nb_rx)
            rte_prefetch0(rte_pktmbuf_mtod(rx_pkts[i + 1], void *));
        if (i + 2 < nb_rx)
            rte_prefetch0(rte_pktmbuf_mtod(rx_pkts[i + 2], void *));

        uint8_t *data = rte_pktmbuf_mtod(rx_pkts[i], uint8_t *);
        uint16_t len  = rte_pktmbuf_data_len(rx_pkts[i]);

        if (len < 14) {
            rte_pktmbuf_free(rx_pkts[i]);
            continue;
        }

        uint16_t eth_type = (uint16_t)((data[12] << 8) | data[13]);

        if (eth_type == 0x0806) {
            /* ARP → lwIP when running, otherwise return to C# for HandleArpPacket */
            if (dpdk_lwip_is_running()) {
                dpdk_netif_input_mbuf(rx_pkts[i]);
                lwip_count++;
            } else {
                /* lwIP not running — pass ARP to C# so HandleArpPacket can reply */
                if (udp_count < max_udp)
                    out_udp_pkts[udp_count++] = rx_pkts[i];
                else
                    rte_pktmbuf_free(rx_pkts[i]);
            }
        }
        else if (eth_type == 0x0800 && len >= 34) {
            /* IPv4 — check IP protocol at offset ETH(14) + 9 = 23 */
            uint8_t ip_proto = data[23];

            if (ip_proto == 17) {
                /* UDP → PG driver */
                if (udp_count < max_udp)
                    out_udp_pkts[udp_count++] = rx_pkts[i];
                else
                    rte_pktmbuf_free(rx_pkts[i]);
            }
            else {
                /* TCP(6), ICMP(1), etc. → lwIP */
                if (dpdk_lwip_is_running()) {
                    dpdk_netif_input_mbuf(rx_pkts[i]);
                    lwip_count++;
                } else {
                    rte_pktmbuf_free(rx_pkts[i]);
                }
            }
        }
        else {
            /* Other EtherTypes (IPv6, etc.) → drop */
            rte_pktmbuf_free(rx_pkts[i]);
        }
    }

    /* 4. Process lwIP timers (with external_rx=1, dpdk_netif_poll returns 0) */
    /* Must use lwip_poll_once_safe() to prevent concurrent sys_check_timeouts
     * with FTP threads — race condition causes TCP state corruption → heap damage */
    if (dpdk_lwip_is_running())
        lwip_poll_once_safe();

    if (out_lwip_count)
        *out_lwip_count = lwip_count;

    return udp_count;
  } __except(hw_seh_filter(GetExceptionInformation())) {
    hw_dbg("[HW] SEH: hw_dispatch_poll crashed! port=%u queue=%u\n", port_id, queue_id);
    if (out_lwip_count) *out_lwip_count = 0;
    return 0;
  }
}

/* ============================================================
 * Enable/disable external RX mode for lwIP.
 * When enabled, dpdk_netif_poll() skips rte_eth_rx_burst —
 * the unified dispatcher feeds packets instead.
 * ============================================================ */
DPDK_API void hw_lwip_set_external_rx(int enabled)
{
    dpdk_netif_set_external_rx(enabled);
    hw_dbg("[HW] lwip_set_external_rx: %d\n", enabled);
}

/* ============================================================ */

/* ═══════════════════════════════════════════════════════════════════
 * NIC Owner Thread — 모든 rte_eth_rx/tx_burst + lwIP를 독점
 * ═══════════════════════════════════════════════════════════════════ */

// --- Command slot alloc/free ---
static nic_cmd_t *nic_cmd_alloc(void) {
    void *obj;
    for (int i = 0; i < 100000; i++) {
        if (rte_ring_mc_dequeue(g_nic_cmd_free, &obj) == 0)
            return (nic_cmd_t *)obj;
        rte_pause();
    }
    return NULL;
}

// --- Route packet: UDP → g_udp_rx_ring, TCP/ARP → lwIP ---
static void nic_route_packet(struct rte_mbuf *pkt) {
    uint8_t *data = rte_pktmbuf_mtod(pkt, uint8_t *);
    uint16_t len = rte_pktmbuf_data_len(pkt);

    if (len < 14) { rte_pktmbuf_free(pkt); return; }

    uint16_t eth_type = (uint16_t)((data[12] << 8) | data[13]);

    if (eth_type == 0x0800 && len >= 34 && data[23] == 17) {
        /* UDP → C# RxPollLoop via ring */
        if (rte_ring_sp_enqueue(g_udp_rx_ring, pkt) != 0)
            rte_pktmbuf_free(pkt);
    }
    else if (eth_type == 0x0806 ||
             (eth_type == 0x0800 && len >= 34 && data[23] != 17)) {
        /* ARP / TCP / ICMP → lwIP (same thread = safe) */
        if (dpdk_lwip_is_running())
            dpdk_netif_input_mbuf(pkt);
        else
            rte_pktmbuf_free(pkt);
    }
    else {
        rte_pktmbuf_free(pkt);
    }
}

// --- Execute REQRESP on NIC thread (sole NIC owner) ---
static void nic_execute_reqresp(nic_cmd_t *cmd) {
    LARGE_INTEGER freq, send_tick, now_tick;
    QueryPerformanceFrequency(&freq);

    memset(&cmd->rr_result, 0, sizeof(cmd->rr_result));

    // Alloc + build TX packet
    struct rte_mbuf *mbuf = rte_pktmbuf_alloc(cmd->pool);
    if (!mbuf) { cmd->rr_result.status = -1; return; }

    char *pkt_data = rte_pktmbuf_append(mbuf, cmd->pkt_len);
    if (!pkt_data) { rte_pktmbuf_free(mbuf); cmd->rr_result.status = -1; return; }
    memcpy(pkt_data, cmd->template_pkt, cmd->pkt_len);

    // Update IP ID + UDP checksum (same as hw_reqresp_once_mc)
    if (cmd->pkt_len >= 42) {
        pkt_data[18] = (char)(cmd->packet_id >> 8);
        pkt_data[19] = (char)(cmd->packet_id & 0xFF);
        pkt_data[40] = 0; pkt_data[41] = 0; // zero UDP checksum
    }

    // TX (no lock needed — sole owner)
    struct rte_mbuf *tx[1] = { mbuf };
    if (rte_eth_tx_burst(cmd->port_id, 0, tx, 1) == 0) {
        rte_pktmbuf_free(mbuf);
        cmd->rr_result.status = -2;
        return;
    }

    QueryPerformanceCounter(&send_tick);

    // RX poll loop (sole consumer — no lock, no race)
    double timeout_sec = cmd->timeout_ms / 1000.0;
    uint16_t expected_port_net = rte_cpu_to_be_16(cmd->expected_dst_port);
    uint16_t ipv4_type = rte_cpu_to_be_16(0x0800);
    uint16_t arp_type = rte_cpu_to_be_16(0x0806);
    struct rte_mbuf *rx_pkts[32];
    int empty_polls = 0;

    while (1) {
        uint16_t nb_rx = rte_eth_rx_burst(cmd->port_id, 0, rx_pkts, 32);

        if (nb_rx == 0) {
            rte_pause();
            if (++empty_polls < 64) continue;
            empty_polls = 0;
            goto reqresp_check_timeout;
        }
        empty_polls = 0;

        for (int i = 0; i < nb_rx; i++) {
            uint8_t *rx_data = rte_pktmbuf_mtod(rx_pkts[i], uint8_t *);
            uint16_t rx_len = rte_pktmbuf_data_len(rx_pkts[i]);

            // Check: IPv4 UDP, matching src IP + dst port
            if (rx_len >= 42) {
                uint16_t eth_type;
                memcpy(&eth_type, rx_data + 12, 2);

                if (eth_type == ipv4_type && rx_data[23] == 17) {
                    uint32_t src_ip;
                    memcpy(&src_ip, rx_data + 26, 4);
                    uint16_t dst_port;
                    memcpy(&dst_port, rx_data + 36, 2);

                    if (src_ip == cmd->expected_src_ip && dst_port == expected_port_net) {
                        // Match! Fill result
                        QueryPerformanceCounter(&now_tick);
                        cmd->rr_result.status = 0;
                        cmd->rr_result.rtt_ms = (double)(now_tick.QuadPart - send_tick.QuadPart)
                                                * 1000.0 / freq.QuadPart;
                        uint16_t payload_off = 42;
                        uint16_t payload_len = rx_len - payload_off;
                        cmd->rr_result.resp_len = payload_len;
                        if (payload_len > 0 && payload_len <= cmd->resp_buf_size)
                            memcpy(cmd->resp_buf, rx_data + payload_off, payload_len);
                        rte_pktmbuf_free(rx_pkts[i]);
                        // Route remaining packets
                        for (int j = i + 1; j < nb_rx; j++)
                            nic_route_packet(rx_pkts[j]);
                        return;
                    }
                }

                // ARP auto-reply (same as hw_reqresp_once_mc)
                if (eth_type == arp_type && rx_len >= 42) {
                    uint16_t arp_op;
                    memcpy(&arp_op, rx_data + 20, 2);
                    if (rte_be_to_cpu_16(arp_op) == 1) {
                        uint32_t target_ip;
                        memcpy(&target_ip, rx_data + 38, 4);
                        if (target_ip == cmd->local_ip) {
                            // Build ARP reply (same as existing code)
                            struct rte_mbuf *arp_reply = rte_pktmbuf_alloc(cmd->pool);
                            if (arp_reply) {
                                char *arp_data = rte_pktmbuf_append(arp_reply, 42);
                                if (arp_data) {
                                    memcpy(arp_data, rx_data + 6, 6);
                                    memcpy(arp_data + 6, cmd->local_mac, 6);
                                    arp_data[12] = 0x08; arp_data[13] = 0x06;
                                    arp_data[14] = 0; arp_data[15] = 1;
                                    arp_data[16] = 0x08; arp_data[17] = 0;
                                    arp_data[18] = 6; arp_data[19] = 4;
                                    arp_data[20] = 0; arp_data[21] = 2;
                                    memcpy(arp_data + 22, cmd->local_mac, 6);
                                    memcpy(arp_data + 28, &cmd->local_ip, 4);
                                    memcpy(arp_data + 32, rx_data + 22, 6);
                                    memcpy(arp_data + 38, rx_data + 28, 4);
                                    struct rte_mbuf *arp_tx[1] = { arp_reply };
                                    if (rte_eth_tx_burst(cmd->port_id, 0, arp_tx, 1) == 0)
                                        rte_pktmbuf_free(arp_reply);
                                } else {
                                    rte_pktmbuf_free(arp_reply);
                                }
                            }
                        }
                    }
                }
            }

            // Non-matching packet → route
            nic_route_packet(rx_pkts[i]);
        }

    reqresp_check_timeout:
        // Run lwIP timers during wait (keeps TCP alive for FTP)
        if (dpdk_lwip_is_running())
            dpdk_lwip_poll_once();

        QueryPerformanceCounter(&now_tick);
        if ((double)(now_tick.QuadPart - send_tick.QuadPart) / freq.QuadPart >= timeout_sec)
            break;
    }

    cmd->rr_result.status = 1; // timeout
    cmd->rr_result.rtt_ms = (double)cmd->timeout_ms;
}

// --- Execute FTP command on NIC thread ---
static int nic_ftp_poll_inline(ftp_client_t *ftp, int timeout_ms) {
    DWORD start = (DWORD)GetTickCount64();
    struct rte_mbuf *rx_pkts[32];

    while (!ftp->op_done) {
        if ((int)((DWORD)GetTickCount64() - start) >= timeout_ms) {
            ftp->op_result = 1;
            return 1;
        }
        // RX + route (sole owner)
        uint16_t nb_rx = rte_eth_rx_burst(g_nic_port_id, 0, rx_pkts, 32);
        for (uint16_t i = 0; i < nb_rx; i++)
            nic_route_packet(rx_pkts[i]);
        // lwIP timers (sole owner)
        if (dpdk_lwip_is_running())
            dpdk_lwip_poll_once();
        if (nb_rx == 0)
            SwitchToThread();
    }
    return ftp->op_result;
}

static void nic_execute_ftp(nic_cmd_t *cmd) {
    ftp_client_t *ftp = get_session(cmd->ftp_session_id);
    if (!ftp) { cmd->result = -1; return; }

    switch (cmd->type) {
    case NIC_CMD_FTP_CONNECT: {
        ftp_client_init(ftp);
        uint32_t ip = parse_ip_str(cmd->ftp_server_ip);
        if (ip == 0) { cmd->result = -1; return; }
        if (ftp_connect(ftp, ip, cmd->ftp_port) != 0) { cmd->result = -1; return; }
        if (nic_ftp_poll_inline(ftp, cmd->ftp_timeout_ms) != 0) { ftp_disconnect(ftp); cmd->result = -1; return; }
        // USER
        { char c[256]; snprintf(c, sizeof(c), "USER %s\r\n", cmd->ftp_user);
          ftp->state = FTP_STATE_WAIT_USER;
          if (ftp_send_cmd(ftp, c) != 0 || nic_ftp_poll_inline(ftp, cmd->ftp_timeout_ms) != 0) { ftp_disconnect(ftp); cmd->result = -1; return; }
        }
        if (ftp->response_code != 230) {
            // PASS
            char c[256]; snprintf(c, sizeof(c), "PASS %s\r\n", cmd->ftp_pass);
            ftp->state = FTP_STATE_WAIT_PASS;
            if (ftp_send_cmd(ftp, c) != 0 || nic_ftp_poll_inline(ftp, cmd->ftp_timeout_ms) != 0) { ftp_disconnect(ftp); cmd->result = -1; return; }
        }
        // TYPE I
        ftp->state = FTP_STATE_READY;
        if (ftp_send_cmd(ftp, "TYPE I\r\n") != 0 || nic_ftp_poll_inline(ftp, cmd->ftp_timeout_ms) != 0) { ftp_disconnect(ftp); cmd->result = -1; return; }
        cmd->result = 0;
        hw_dbg("[HW-NIC] FTP connect OK (session=%d)\n", cmd->ftp_session_id);
        break;
    }
    case NIC_CMD_FTP_DOWNLOAD: {
        if (ftp->state != FTP_STATE_READY) { cmd->result = -1; return; }
        if (ftp_start_retr(ftp, cmd->ftp_path, cmd->ftp_buf, (uint32_t)cmd->ftp_buf_size) != 0) { cmd->result = -1; return; }
        if (nic_ftp_poll_inline(ftp, cmd->ftp_timeout_ms) != 0) { ftp_cleanup_data(ftp); cmd->result = -1; return; }
        cmd->ftp_out_len = (int)ftp->recv_len;
        cmd->result = 0;
        break;
    }
    case NIC_CMD_FTP_UPLOAD: {
        if (ftp->state != FTP_STATE_READY) { cmd->result = -1; return; }
        if (ftp_start_stor(ftp, cmd->ftp_path, cmd->ftp_upload_data, (uint32_t)cmd->ftp_upload_len) != 0) { cmd->result = -1; return; }
        if (nic_ftp_poll_inline(ftp, cmd->ftp_timeout_ms) != 0) { ftp_cleanup_data(ftp); cmd->result = -1; return; }
        cmd->result = 0;
        break;
    }
    case NIC_CMD_FTP_DISCONNECT: {
        if (ftp->ctrl_pcb) {
            ftp->op_done = 0; ftp->op_result = 0;
            ftp_send_cmd(ftp, "QUIT\r\n");
            nic_ftp_poll_inline(ftp, 2000);
        }
        ftp_disconnect(ftp);
        cmd->result = 0;
        hw_dbg("[HW-NIC] FTP disconnect (session=%d)\n", cmd->ftp_session_id);
        break;
    }
    default:
        cmd->result = -1;
        break;
    }
}

// --- NIC Owner Thread main loop ---
static DWORD WINAPI nic_owner_thread_func(LPVOID arg) {
    (void)arg;

    // Pin to isolated core
    if (g_dpdk_core >= 0) {
        SetThreadAffinityMask(GetCurrentThread(), (DWORD_PTR)1 << g_dpdk_core);
        hw_dbg("[HW-NIC] thread pinned to core %d\n", g_dpdk_core);
    }
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
    hw_dbg("[HW-NIC] owner thread started\n");

    struct rte_mbuf *rx_pkts[64];
    int idle_count = 0;

    while (g_nic_running) {
        int did_work = 0;

        // 1. Check command ring
        void *obj;
        if (rte_ring_sc_dequeue(g_nic_cmd_ring, &obj) == 0) {
            nic_cmd_t *cmd = (nic_cmd_t *)obj;
            did_work = 1;

            if (cmd->type == NIC_CMD_SHUTDOWN) {
                _InterlockedExchange((volatile long *)&cmd->done, 1);
                break;
            }
            else if (cmd->type == NIC_CMD_REQRESP) {
                nic_execute_reqresp(cmd);
                _InterlockedExchange((volatile long *)&cmd->done, 1);
            }
            else {
                nic_execute_ftp(cmd);
                _InterlockedExchange((volatile long *)&cmd->done, 1);
            }
        }

        // 2. RX burst (sole consumer — no lock)
        uint16_t nb_rx = rte_eth_rx_burst(g_nic_port_id, 0, rx_pkts, 64);
        if (nb_rx > 0) did_work = 1;

        // 3. Route packets
        for (uint16_t i = 0; i < nb_rx; i++)
            nic_route_packet(rx_pkts[i]);

        // 4. lwIP timers (sole owner)
        if (dpdk_lwip_is_running())
            dpdk_lwip_poll_once();

        // 5. Idle management
        if (!did_work) {
            if (++idle_count < 64)
                rte_pause();
            else {
                idle_count = 0;
                SwitchToThread();
            }
        } else {
            idle_count = 0;
        }
    }

    hw_dbg("[HW-NIC] owner thread exiting\n");
    return 0;
}

// --- Public API: Start/Stop NIC thread ---
DPDK_API int hw_nic_thread_start(uint16_t port_id, void *pool) {
    if (g_nic_running) return 0; // already running

    g_nic_port_id = port_id;
    g_nic_pool = (struct rte_mempool *)pool;

    // Create rings
    g_nic_cmd_ring = rte_ring_create("nic_cmd", 16, 0, RING_F_SC_DEQ); // MPSC
    g_nic_cmd_free = rte_ring_create("nic_free", 16, 0, 0);             // MPMC
    g_udp_rx_ring = rte_ring_create("udp_rx", 2048, 0,
                                     RING_F_SP_ENQ | RING_F_SC_DEQ);    // SPSC

    if (!g_nic_cmd_ring || !g_nic_cmd_free || !g_udp_rx_ring) {
        hw_dbg("[HW-NIC] ring creation failed\n");
        return -1;
    }

    // Pre-populate free pool
    for (int i = 0; i < NIC_CMD_POOL_SIZE; i++) {
        memset(&g_nic_cmd_pool[i], 0, sizeof(nic_cmd_t));
        rte_ring_mp_enqueue(g_nic_cmd_free, &g_nic_cmd_pool[i]);
    }

    g_nic_running = 1;
    g_nic_thread = CreateThread(NULL, 0, nic_owner_thread_func, NULL, 0, NULL);
    if (!g_nic_thread) {
        g_nic_running = 0;
        hw_dbg("[HW-NIC] thread creation failed\n");
        return -1;
    }

    hw_dbg("[HW-NIC] started (port=%u)\n", port_id);
    return 0;
}

DPDK_API void hw_nic_thread_stop(void) {
    if (!g_nic_running) return;

    // Send shutdown command
    nic_cmd_t *cmd = nic_cmd_alloc();
    if (cmd) {
        cmd->type = NIC_CMD_SHUTDOWN;
        cmd->done = 0;
        rte_ring_mp_enqueue(g_nic_cmd_ring, cmd);
    }

    g_nic_running = 0;
    if (g_nic_thread) {
        WaitForSingleObject(g_nic_thread, 5000);
        CloseHandle(g_nic_thread);
        g_nic_thread = NULL;
    }

    // Drain UDP RX ring
    if (g_udp_rx_ring) {
        void *obj;
        while (rte_ring_sc_dequeue(g_udp_rx_ring, &obj) == 0)
            rte_pktmbuf_free((struct rte_mbuf *)obj);
    }

    hw_dbg("[HW-NIC] stopped\n");
}

// --- Public API: Submit REQRESP (called from any thread) ---
DPDK_API int hw_reqresp_submit(
    uint16_t port_id, void *pool,
    const uint8_t *template_pkt, uint16_t pkt_len,
    uint16_t packet_id, uint32_t expected_src_ip,
    uint16_t expected_dst_port, int timeout_ms,
    uint8_t *resp_buf, uint16_t resp_buf_size,
    hw_reqresp_result_t *result,
    const uint8_t *local_mac, uint32_t local_ip)
{
    if (!g_nic_running) {
        // Fallback to legacy direct call if NIC thread not running
        return hw_reqresp_once_mc(port_id, pool, template_pkt, pkt_len,
            packet_id, expected_src_ip, expected_dst_port, timeout_ms,
            resp_buf, resp_buf_size, result, local_mac, local_ip);
    }

    nic_cmd_t *cmd = nic_cmd_alloc();
    if (!cmd) { result->status = -1; return -1; }

    cmd->type = NIC_CMD_REQRESP;
    cmd->port_id = port_id;
    cmd->pool = (struct rte_mempool *)pool;
    memcpy(cmd->template_pkt, template_pkt, pkt_len > 2048 ? 2048 : pkt_len);
    cmd->pkt_len = pkt_len;
    cmd->packet_id = packet_id;
    cmd->expected_src_ip = expected_src_ip;
    cmd->expected_dst_port = expected_dst_port;
    cmd->timeout_ms = timeout_ms;
    cmd->resp_buf_size = resp_buf_size;
    memcpy(cmd->local_mac, local_mac, 6);
    cmd->local_ip = local_ip;
    cmd->done = 0;

    rte_ring_mp_enqueue(g_nic_cmd_ring, cmd);

    // Spin-wait for completion
    while (!cmd->done)
        _mm_pause();

    *result = cmd->rr_result;
    if (result->status == 0 && cmd->rr_result.resp_len > 0) {
        uint16_t copy_len = cmd->rr_result.resp_len;
        if (copy_len > resp_buf_size) copy_len = resp_buf_size;
        memcpy(resp_buf, cmd->resp_buf, copy_len);
    }

    rte_ring_mp_enqueue(g_nic_cmd_free, cmd);
    return result->status;
}

// --- Public API: Drain UDP packets (called from C# RxPollLoop) ---
DPDK_API uint16_t hw_udp_rx_drain(struct rte_mbuf **out_pkts, uint16_t max_pkts) {
    if (!g_udp_rx_ring) return 0;
    uint16_t count = 0;
    void *obj;
    while (count < max_pkts && rte_ring_sc_dequeue(g_udp_rx_ring, &obj) == 0)
        out_pkts[count++] = (struct rte_mbuf *)obj;
    return count;
}

// --- Public API: FTP submit wrappers ---
DPDK_API int hw_ftp_connect_submit(int session_id,
    const char *server_ip, uint16_t port,
    const char *user, const char *pass, int timeout_ms)
{
    if (!g_nic_running)
        return hw_ftp_connect_sync_ex(session_id, server_ip, port, user, pass, timeout_ms);

    nic_cmd_t *cmd = nic_cmd_alloc();
    if (!cmd) return -1;
    cmd->type = NIC_CMD_FTP_CONNECT;
    cmd->ftp_session_id = session_id;
    strncpy(cmd->ftp_server_ip, server_ip, 63);
    cmd->ftp_port = port;
    strncpy(cmd->ftp_user, user, 63);
    strncpy(cmd->ftp_pass, pass, 63);
    cmd->ftp_timeout_ms = timeout_ms;
    cmd->done = 0;
    rte_ring_mp_enqueue(g_nic_cmd_ring, cmd);
    while (!cmd->done) Sleep(1);
    int ret = cmd->result;
    rte_ring_mp_enqueue(g_nic_cmd_free, cmd);
    return ret;
}

DPDK_API int hw_ftp_download_submit(int session_id,
    const char *path, uint8_t *buf, int buf_size,
    int *out_len, int timeout_ms)
{
    if (!g_nic_running)
        return hw_ftp_download_sync_ex(session_id, path, buf, buf_size, out_len, timeout_ms);

    nic_cmd_t *cmd = nic_cmd_alloc();
    if (!cmd) return -1;
    cmd->type = NIC_CMD_FTP_DOWNLOAD;
    cmd->ftp_session_id = session_id;
    strncpy(cmd->ftp_path, path, 511);
    cmd->ftp_buf = buf;
    cmd->ftp_buf_size = buf_size;
    cmd->ftp_timeout_ms = timeout_ms;
    cmd->done = 0;
    rte_ring_mp_enqueue(g_nic_cmd_ring, cmd);
    while (!cmd->done) Sleep(1);
    if (out_len) *out_len = cmd->ftp_out_len;
    int ret = cmd->result;
    rte_ring_mp_enqueue(g_nic_cmd_free, cmd);
    return ret;
}

DPDK_API int hw_ftp_upload_submit(int session_id,
    const char *path, const uint8_t *data, int data_len,
    int timeout_ms)
{
    if (!g_nic_running)
        return hw_ftp_upload_sync_ex(session_id, path, data, data_len, timeout_ms);

    nic_cmd_t *cmd = nic_cmd_alloc();
    if (!cmd) return -1;
    cmd->type = NIC_CMD_FTP_UPLOAD;
    cmd->ftp_session_id = session_id;
    strncpy(cmd->ftp_path, path, 511);
    cmd->ftp_upload_data = data;
    cmd->ftp_upload_len = data_len;
    cmd->ftp_timeout_ms = timeout_ms;
    cmd->done = 0;
    rte_ring_mp_enqueue(g_nic_cmd_ring, cmd);
    while (!cmd->done) Sleep(1);
    int ret = cmd->result;
    rte_ring_mp_enqueue(g_nic_cmd_free, cmd);
    return ret;
}

DPDK_API int hw_ftp_disconnect_submit(int session_id) {
    if (!g_nic_running)
        return hw_ftp_disconnect_ex(session_id);

    nic_cmd_t *cmd = nic_cmd_alloc();
    if (!cmd) return -1;
    cmd->type = NIC_CMD_FTP_DISCONNECT;
    cmd->ftp_session_id = session_id;
    cmd->done = 0;
    rte_ring_mp_enqueue(g_nic_cmd_ring, cmd);
    while (!cmd->done) Sleep(1);
    int ret = cmd->result;
    rte_ring_mp_enqueue(g_nic_cmd_free, cmd);
    return ret;
}

/* ═══════════════════════════════════════════════════════════════════ */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        hw_dbg_init_path(hinstDLL);
    }

    if (fdwReason == DLL_PROCESS_DETACH && g_eal_initialized) {
        hw_dbg("[HW] DllMain DETACH — running eal_cleanup\n");
        g_eal_initialized = 0;
        __try {
            rte_eal_cleanup();
        } __except(1) {
            hw_dbg("[HW] DllMain cleanup SEH exception\n");
        }
    }
    return TRUE;
}
