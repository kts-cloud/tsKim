#ifndef LWIPOPTS_H
#define LWIPOPTS_H

/* --- NO_SYS: bare-metal mode (no OS threads) --- */
#define NO_SYS                      1
#define LWIP_SOCKET                 0
#define LWIP_NETCONN                0
#define SYS_LIGHTWEIGHT_PROT        0

/* --- Memory: use C runtime malloc --- */
#define MEM_LIBC_MALLOC             1
#define MEMP_MEM_MALLOC             1
#define MEM_SIZE                    (256 * 1024)

/* --- pbuf pool --- */
#define PBUF_POOL_SIZE              256
#define PBUF_POOL_BUFSIZE           1536

/* --- TCP --- */
#define LWIP_TCP                    1
#define TCP_MSS                     1460
#define TCP_WND                     (16 * TCP_MSS)
#define TCP_SND_BUF                 (8 * TCP_MSS)
#define TCP_SND_QUEUELEN            32
#define MEMP_NUM_TCP_PCB            16
#define MEMP_NUM_TCP_PCB_LISTEN     8
#define MEMP_NUM_TCP_SEG            64
#define TCP_OVERSIZE                TCP_MSS

/* --- UDP (minimal, for DNS etc.) --- */
#define LWIP_UDP                    1

/* --- IP / ICMP / ARP --- */
#define LWIP_IPV4                   1
#define LWIP_ICMP                   1
#define LWIP_ARP                    1
#define LWIP_DHCP                   0
#define LWIP_DNS                    0
#define LWIP_IGMP                   0
#define LWIP_IPV6                   0

/* --- Checksum --- */
#define CHECKSUM_GEN_IP             1
#define CHECKSUM_GEN_TCP            1
#define CHECKSUM_GEN_UDP            1
#define CHECKSUM_GEN_ICMP           1
#define CHECKSUM_CHECK_IP           1
#define CHECKSUM_CHECK_TCP          1
#define CHECKSUM_CHECK_UDP          1

/* --- Misc --- */
#define LWIP_STATS                  0
#define LWIP_DEBUG                  0
#define LWIP_PROVIDE_ERRNO          1
#define LWIP_NETIF_LOOPBACK         0
#define LWIP_HAVE_LOOPIF            0
#define LWIP_NETIF_TX_SINGLE_PBUF   1
#define MEMP_NUM_PBUF               64
#define MEMP_NUM_NETBUF             0
#define MEMP_NUM_NETCONN            0
#define LWIP_ERRNO_STDINCLUDE       0

/* --- Timers (TCP retransmit, etc.) --- */
#define LWIP_TIMERS                 1

#endif /* LWIPOPTS_H */
