# DPDK Communication Architecture — ITOLED_OC

> DP860 Pattern Generator 통신을 위한 커널 바이패스 아키텍처 상세 문서
> Last updated: 2026-03-30

---

## 1. 개요

ITOLED_OC는 DP860 Pattern Generator(PG)와 UDP 기반으로 통신한다. 3가지 전송 모드를 지원하며, INI 설정에 따라 자동 선택된다.

### 전체 레이어 구조

```
┌──────────────────────────────────────────────────────────┐
│  C# Application (Blazor Server)                          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │ CommPgDriver │  │ DllManager   │  │ ScriptEngine    │ │
│  │ (per-CH)     │  │ (OC Flow)    │  │ (Inspection)    │ │
│  └──────┬───────┘  └──────┬───────┘  └────────┬────────┘ │
│         │                 │                    │          │
│  ┌──────▼─────────────────▼────────────────────▼────────┐│
│  │              IPgTransport (Interface)                 ││
│  │  ┌──────────────┬────────────────┬─────────────────┐ ││
│  │  │ PgDpdkServer │ PgPipelineServer│ PgUdpServer    │ ││
│  │  │ (DPDK)       │ (NetCoreServer) │ (UdpClient)    │ ││
│  │  └──────┬───────┴────────┬───────┴────────┬────────┘ ││
│  └─────────┼────────────────┼────────────────┼──────────┘│
└────────────┼────────────────┼────────────────┼───────────┘
             │                │                │
     ┌───────▼───────┐  ┌────▼─────┐   ┌──────▼──────┐
     │  HwNet.dll    │  │NetCore   │   │ Windows     │
     │  (C# wrapper) │  │Server    │   │ Kernel UDP  │
     ├───────────────┤  │(.NET)    │   │ Stack       │
     │  hwio.dll     │  └────┬─────┘   └──────┬──────┘
     │  (C / DPDK)   │       │                 │
     ├───────────────┤  ┌────▼─────────────────▼──────┐
     │  DPDK EAL     │  │       Windows Kernel        │
     │  (hugepage)   │  │     (NDIS / Winsock)        │
     └───────┬───────┘  └────────────┬────────────────┘
             │                       │
     ┌───────▼───────────────────────▼────────────────┐
     │              NIC Hardware (Intel i225 등)       │
     └────────────────────┬───────────────────────────┘
                          │
                   DP860 Pattern Generator
```

### 전송 모드 비교

| 항목 | DPDK | Pipeline | Socket |
|------|------|----------|--------|
| **구현 클래스** | `PgDpdkServer` | `PgPipelineServer` | `PgUdpServer` |
| **커널 경유** | No (bypass) | Yes | Yes |
| **RTT** | ~0.1–0.3 ms | ~1–5 ms | ~1–5 ms |
| **Throughput** | ~10M+ pps | ~3–5M pps | ~1M pps |
| **FTP 지원** | Yes (lwIP) | No | No |
| **NuGet 의존성** | HwNet.dll (local) | NetCoreServer 8.0.7 | 없음 (.NET 내장) |
| **Hugepage 필요** | Yes (2GB+) | No | No |
| **RX 방식** | Polling (dedicated thread) | Async event → Channel | await ReceiveAsync |

---

## 2. 전송 모드 선택

### INI 설정 (SystemInfo)

| 설정 | INI 키 | 기본값 | 설명 |
|------|--------|--------|------|
| `UsePipeline` | `USE_PIPELINE` | `false` | Pipeline 모드 활성화 |
| `UseDpdk` | `USE_DPDK` | `false` | DPDK 모드 활성화 |
| `DpdkCoreMask` | `DPDK_CORE_MASK` | `"auto"` | EAL CPU 코어 마스크 |
| `DpdkMemoryMb` | `DPDK_MEMORY_MB` | `256` | Hugepage 메모리 (MB) |
| `DpdkPortId` | `DPDK_PORT_ID` | `0` | DPDK NIC 포트 ID |
| `PGEnableDpdkWarmup` | `PG_EnableDpdkWarmup` | `true` | 64 dummy 패킷 워밍업 |

### 선택 우선순위 (`Program.cs` lines 718–891)

```
UsePipeline=true?  ──Yes──▶ PgPipelineServer ──실패──▶ ┐
       │No                                              │
       ▼                                                │
UseDpdk=true?  ──Yes──▶ HwManager.InitializeAsync       │
       │No              ──성공──▶ PgDpdkServer           │
       │                ──실패──▶ ┐                      │
       ▼                          ▼                      ▼
                          PgUdpServer (Socket 폴백)
```

### UI 표시

| 상태 | `UiUpdateService.PgTransportMode` |
|------|-----------------------------------|
| DPDK 성공 | `"DPDK"` |
| Pipeline 성공 | `"Pipeline"` |
| Socket (정상) | `"Socket"` |
| DPDK 실패 → Socket | `"Socket (DPDK 실패)"` |
| 전체 실패 | `"PG 미연결"` |

---

## 3. DPDK 초기화 시퀀스

```
App Startup
  │
  ├─ 1. HwManager.InitializeAsync(options)
  │     ├─ SeLockMemoryPrivilege 획득
  │     ├─ Hugepage 검증 (hw_check_hugepage)
  │     ├─ EAL Init (hw_eal_init) — auto memory reduction 재시도
  │     ├─ Mempool 생성 (hw_pktmbuf_pool_create_safe, cache_size=0)
  │     ├─ Port Setup (hw_simple_port_setup) — RX/TX 큐 256 desc, promiscuous
  │     └─ Link Status Polling (최대 10초 대기)
  │
  ├─ 2. PgDpdkServer 생성자
  │     ├─ Local MAC/IP 캐시
  │     ├─ Per-PG port 매핑 (_localPorts[i] = PcPortBase + 1 + i)
  │     ├─ ARP Resolution (ResolveAllPgMacs)
  │     │   ├─ Gratuitous ARP 전송
  │     │   ├─ ARP Request → 3회 재시도, 3초 타임아웃
  │     │   └─ MAC 캐시: _pgMacCache[pgIndex]
  │     ├─ DPDK Warmup (64 dummy 패킷 — NIC DMA/CPU 캐시 프라이밍)
  │     └─ RxPollLoop 스레드 시작 (ThreadPriority.Highest)
  │
  ├─ 3. DpdkNicCoordinator 생성
  │     └─ EnableLwipMode() → SetLwipExternalRx(true) — 앱 수명 동안 1회
  │
  └─ 4. Per-CH 바인딩
        ├─ pg.SetTransport(pgDpdkServer)
        ├─ pg.SetDpdkFtpAccess(coordinator, hwManager)
        └─ pg.SetCyclicTimer(true) — pg.status 주기 시작
```

---

## 4. TX 데이터 흐름

### Path A: Fire-and-forget (비동기 전송, ACK 불필요)

```
CommPgDriver.Dp860SendCmd(command, waitMs=0)
  │
  ▼
IPgTransport.Send(bindIdx, pgIndex, data)
  │
  ▼ [PgDpdkServer.Send()]
  ├─ lock (_txLock)                    // TX 큐 직렬화
  ├─ BuildUdpPacket()                  // L2→L4 패킷 조립
  │   ├─ Ethernet: dst=_pgMacCache[pg], src=_localMac
  │   ├─ IPv4: src=_localIpNet, dst=pgIpNet, proto=UDP(17)
  │   ├─ UDP: src=_localPorts[pg], dst=pgIpPort
  │   └─ Payload: ASCII command (e.g., "pg.status\r")
  ├─ AllocMbuf() → AppendMbuf()       // DPDK mbuf 할당 + 데이터 기록
  ├─ TxBurst(txPkts, 1)               // NIC TX 링에 큐잉
  └─ FreeMbuf() if failed
  │
  ▼
  NIC DMA → Physical Cable → DP860 PG
```

**사용 예:** `pg.status`, `pg.init`, `power.read` (no-ack 채널)

### Path B: Synchronous Send-and-Receive (응답 대기)

```
CommPgDriver.Dp860SendCmd(command, waitMs>0)
  │
  ▼
IPgTransport.SendAndReceive(bindIdx, pgIndex, command, timeoutMs)
  │
  ▼ [PgDpdkServer.SendAndReceive()]
  ├─ BuildUdpPacket() (template)
  ├─ lock (_rxExclusiveLock)           // RxPollLoop와 상호 배제
  ├─ _dpdk.ReqRespOnceMc(             // Native C 함수 호출
  │     templatePkt, pktLen, packetId,
  │     expectedSrcIp, expectedDstPort,
  │     timeoutMs, responseBuf, bufLen)
  │   ├─ NIC TX burst (전송)
  │   ├─ NIC RX poll loop (응답 대기)
  │   │   ├─ 5-level 필터: EtherType → IPv4 → UDP → srcIP → dstPort
  │   │   ├─ 비매칭 패킷 → spill ring (lock-free SPSC)
  │   │   └─ 매칭 → 응답 추출
  │   └─ RTT 측정 (QueryPerformanceCounter)
  └─ return (status, response, rttUs)
```

### 패킷 구조 (42+ bytes)

```
 0                   14                  34        42
 ├── Ethernet (14B) ──┼── IPv4 (20B) ────┼─ UDP ──┼── Payload ──────┤
 │ dst_mac  src_mac   │ src_ip  dst_ip   │ 8B     │ ASCII command   │
 │ type=0x0800        │ proto=17 (UDP)   │ src/dst│ "pg.status\r"   │
 └────────────────────┴──────────────────┴─ port ─┴─────────────────┘
```

---

## 5. RX 데이터 흐름

### RxPollLoop (전용 스레드, ThreadPriority.Highest, Core 1 pinned)

```
while (_running):
  │
  ├─ TryEnter(_rxExclusiveLock)        // Non-blocking. 실패 시 skip
  │   (SendAndReceive가 잠그면 이번 iteration skip)
  │
  ├─ hw_dispatch_poll(rxPkts, 32, out lwipCount)
  │   ├─ Spill ring drain (lock-free SPSC dequeue)
  │   ├─ rte_eth_rx_burst (spinlock g_rx_lock 보호)
  │   └─ 패킷 분류:
  │       ├─ ARP (0x0806) → lwIP (running) 또는 HandleArpPacket
  │       ├─ UDP (proto 17) → C# 반환 (out_udp_pkts[])
  │       ├─ TCP/ICMP → lwIP (running) 또는 drop
  │       └─ 기타 → drop
  │
  ├─ for (i = 0; i < nbRx; i++):
  │   ├─ ProcessRxPacket(rxPkts[i])
  │   │   ├─ Marshal.Read* 로 헤더 파싱
  │   │   ├─ _ipToPgMap[srcIpNet] → pgIndex 결정
  │   │   ├─ UDP payload → ASCII string
  │   │   ├─ RTT 계산: (now - _sendTimestamps[pg]) × 1M / Frequency
  │   │   ├─ "RET:" 파싱 (OK/NG/INFO)
  │   │   └─ driver.OnUdpReceived(cmdAck, localPort, peerPort)
  │   └─ FreeMbuf(rxPkts[i])
  │
  └─ Exit(_rxExclusiveLock)
      nbRx==0 → SpinWait(10) (~10μs)
```

### Command ACK 동기화 (CheckCmdAck)

```
CommPgDriver.CheckCmdAck(task, cmdId, waitMs, retry):
  │
  for (attempt = 0..retry):
  │
  ├─ task()                            // TX 전송
  ├─ SpinWait 2ms                      // 대부분 RTT < 1ms 커버
  │   └─ TxRxPg.CmdResult != None? → 즉시 리턴
  ├─ _cmdAckEvent.Wait(remainMs)       // Kernel 대기 (나머지 시간)
  └─ 결과: Ok→0, Ng→1, Timeout→재시도
```

**하이브리드 대기 전략:** SpinWait(2ms)로 커널 전환 없이 ~70% 응답 처리, 나머지는 ManualResetEventSlim으로 CPU 절약.

---

## 6. FTP / lwIP 통합

### 아키텍처

```
┌─────────────────────────────────────────────────┐
│  CommPgDriver                                   │
│  ├─ EnsureFtpSession()                          │
│  │   ├─ AcquireFtpAccessAsync() ──┐             │
│  │   ├─ HwFtpEngine.InitLwip()    │             │
│  │   └─ HwFtpEngine.ConnectAsync()│             │
│  └─ DisposeFtpSession()           │             │
│      ├─ DisconnectAsync()          │             │
│      ├─ StopLwip()                 │             │
│      └─ Lease.Dispose() ──────┐   │             │
│                                │   │             │
├────────────────────────────────┼───┼─────────────┤
│  DpdkNicCoordinator            │   │             │
│  ├─ AcquireFtpAccessAsync() ◀─┘   │             │
│  │   ├─ _ftpActiveCount++          │             │
│  │   └─ if count==1:               │             │
│  │       PauseRxPolling()          │             │
│  │       ├─ _running=false         │             │
│  │       ├─ _txPaused=true         │             │
│  │       └─ _rxThread.Join(5000)   │  ◀── RX 완전 정지
│  │                                 │             │
│  └─ ReleaseFtpAccess() ◀──────────┘             │
│      ├─ _ftpActiveCount--                        │
│      └─ if count==0:                             │
│          ResumeRxPolling()                        │
│          ├─ _running=true                         │
│          └─ new Thread(RxPollLoop).Start() ◀── RX 재개
│                                                  │
├──────────────────────────────────────────────────┤
│  hwio.dll (Native)                               │
│  ├─ hw_lwip_init_ref()  — reference-counted      │
│  ├─ hw_lwip_stop_ref()  — reference-counted      │
│  ├─ g_lwip_poll_lock    — lwIP timer 보호        │
│  └─ Max 4 concurrent FTP sessions                │
└──────────────────────────────────────────────────┘
```

### 크래시 방지 (2026-03-30 수정)

**문제:** `OnAliveCheckTimer` → `DisposeFtpSession()` → `hw_lwip_stop_ref()` 호출 시, RxPollLoop가 동시에 `hw_dispatch_poll()` 실행 → native 힙 손상 → 크래시

**해결:**
1. `DpdkNicCoordinator.AcquireFtpAccessAsync()`: 첫 lease 획득 시 `PauseRxPolling()` (RX 스레드 Join)
2. `DpdkNicCoordinator.ReleaseFtpAccess()`: 마지막 lease 해제 시 `ResumeRxPolling()` (RX 스레드 재시작)
3. `DisposeFtpSession()`: lease 없이 호출 시 임시 lease 획득하여 RX Pause 보장

```
수정 전 (크래시):
  Timer → DisposeFtpSession() → StopLwip()   ← RX 폴링 동시 실행 (충돌!)

수정 후 (안전):
  Timer → DisposeFtpSession()
    → AcquireFtpAccess() → PauseRxPolling() → RxThread.Join()  ← RX 정지
    → StopLwip()                                                 ← 안전
    → Lease.Dispose() → ResumeRxPolling()                        ← RX 재개
```

### FTP 세션 라이프사이클

```
EnsureFtpSession():
  ├─ _ftpEngine != null && _ftpConnected → 재사용
  ├─ AcquireFtpAccessAsync() → FTP lease (RX pause)
  ├─ new HwFtpEngine(hwManager, pgIndex)
  ├─ InitLwip(ftpConfig) → lwIP TCP/IP 스택 초기화
  ├─ ConnectAsync(pgIp, 21, user, pass, 10000)
  └─ _ftpConnected = true

DpdkFtpDownload(remotePath, localFile):
  ├─ EnsureFtpSession()
  ├─ _ftpEngine.DownloadAsync(remoteFile, 30000)
  └─ File.WriteAllBytes(localFile, data)

DpdkFtpUpload(localFile, remotePath):
  ├─ EnsureFtpSession()
  ├─ File.ReadAllBytes(localFile)
  └─ _ftpEngine.UploadAsync(remoteFile, fileData, 30000)

DisposeFtpSession():
  ├─ (lease 없으면) AcquireFtpAccess() → RX Pause 보장
  ├─ DisconnectAsync() → FTP QUIT + TCP close
  ├─ StopLwip() → lwIP 스택 종료
  ├─ Dispose() → HwFtpEngine 해제
  └─ Lease.Dispose() → RX Resume
```

---

## 7. 스레드 모델 & 동기화

### 스레드 목록

| 스레드 | 우선순위 | Core | 역할 | 생명주기 |
|--------|----------|------|------|----------|
| **RxPollLoop** | Highest | 1 (pinned) | NIC RX 폴링, 패킷 분류, CommPgDriver 디스패치 | PgDpdkServer 생성 ~ Dispose (FTP 중 일시정지) |
| **Main (UI)** | Normal | 0 | WinForms message loop, Blazor Server | 앱 전체 |
| **ConnCheckTimer** | (Timer callback) | — | pg.status 주기적 확인 (2초) | CommPgDriver 시작 ~ Dispose |
| **AliveCheckTimer** | (Timer callback) | — | OC flow 완료 감지 (1초) | DLL flow 시작 ~ 완료 |
| **OcFlowOrchestrator** | (ThreadPool) | — | Factory DLL 실행 (WinForms message pump) | Per-flow |

### 동기화 프리미티브 (C# Managed)

```
_txLock (object)
  ├─ 용도: DPDK TX 큐 직렬화 (단일 TX 큐, thread-safe 아님)
  ├─ 보호: AllocMbuf → AppendMbuf → TxBurst → FreeMbuf
  └─ 잡는 스레드: Send() 호출 모든 스레드

_rxExclusiveLock (object)
  ├─ 용도: RxPollLoop ↔ SendAndReceive 상호 배제
  ├─ 보호: DispatchPoll() / ReqRespOnceMc()
  ├─ RxPollLoop: Monitor.TryEnter(timeout=0) — 실패 시 skip
  └─ SendAndReceive: lock() — 블로킹

_pauseLock (object)
  ├─ 용도: RX 스레드 생성/파괴 보호
  └─ 보호: PauseRxPolling() / ResumeRxPolling()

_cmdAckEvent (ManualResetEventSlim)
  ├─ 용도: Command ACK 도착 시그널
  ├─ Set: OnUdpReceived() (RX 스레드)
  └─ Wait: CheckCmdAck() (명령 전송 스레드)

_threadLock (in CommPgDriver)
  ├─ 용도: PG 명령 직렬화 (per-CH)
  └─ 보호: Dp860SendCmd() 전체
```

### 동기화 프리미티브 (Native — hwio.dll)

```
g_rx_lock (rte_spinlock_t)
  ├─ 용도: NIC RX 큐 단일 소비자 보장
  ├─ 보호: rte_eth_rx_burst() 모든 호출
  └─ 잡는 함수: hw_rx_burst, hw_dispatch_poll, hw_reqresp_once, hw_reqresp_batch

g_lwip_poll_lock (rte_spinlock_t)
  ├─ 용도: lwIP 타이머 동시 호출 방지
  ├─ 보호: sys_check_timeouts(), TCP state machine
  └─ 잡는 함수: lwip_poll_once_safe, hw_lwip_init_ref, hw_lwip_stop_ref

g_spill_ring (rte_ring, 256 entries, SPSC)
  ├─ 용도: Multi-channel 비매칭 패킷 보관
  ├─ Producer: hw_reqresp_once_mc() — rte_ring_sp_enqueue
  └─ Consumer: hw_rx_burst(), hw_dispatch_poll() — rte_ring_sc_dequeue
```

---

## 8. Native DLL (hwio.dll) 인터페이스

### 주요 Exported 함수

#### EAL & 디바이스 관리
| 함수 | 설명 |
|------|------|
| `hw_eal_init(argc, argv)` | DPDK EAL 초기화 (hugepage, 코어 바인딩) |
| `hw_eal_cleanup()` | EAL 정리, spill ring drain, mbuf 해제 |
| `hw_version()` | DPDK 버전 문자열 반환 |
| `hw_check_hugepage(testMb)` | Hugepage 가용성 사전 검증 |
| `hw_eth_dev_count_avail()` | 사용 가능 NIC 포트 수 |
| `hw_eth_macaddr_get(port, mac)` | MAC 주소 조회 |
| `hw_simple_port_setup(port, pool, speeds)` | RX/TX 큐 설정 (256 desc), promiscuous |

#### 패킷 I/O
| 함수 | 설명 |
|------|------|
| `hw_pktmbuf_alloc(pool)` | mbuf 할당 (ring dequeue) |
| `hw_pktmbuf_free(mbuf)` | mbuf 해제 (ring enqueue, 체인 지원) |
| `hw_pktmbuf_append(mbuf, len)` | 데이터 공간 확장 |
| `hw_rx_burst(port, queue, pkts, max)` | NIC RX burst (spill ring 우선 drain) |
| `hw_tx_burst(port, queue, pkts, count)` | NIC TX burst |
| `hw_dispatch_poll(port, queue, udp_pkts, max, lwip_count)` | 통합 분류기: UDP→C#, ARP/TCP→lwIP |

#### Request/Response
| 함수 | 설명 |
|------|------|
| `hw_reqresp_once(...)` | 1:1 요청-응답 (비매칭 패킷 drop) |
| `hw_reqresp_once_mc(...)` | Multi-channel safe (비매칭 → spill ring) |
| `hw_reqresp_batch(...)` | 파이프라인 배치: TX all → RX collect |

#### lwIP / FTP
| 함수 | 설명 |
|------|------|
| `hw_lwip_init(port, pool, ip, mask, gw, mac)` | lwIP 스택 초기화 |
| `hw_lwip_init_ref()` / `hw_lwip_stop_ref()` | Reference-counted init/stop |
| `hw_lwip_set_external_rx(enabled)` | 외부 RX 모드 (dispatch_poll이 피딩) |
| `hw_lwip_poll(max_ms)` | lwIP 타이머 + 패킷 처리 |
| `hw_ftp_connect_sync(ip, port, user, pass, timeout)` | FTP 연결 |
| `hw_ftp_download_sync(file, buf, size, timeout)` | FTP 다운로드 |
| `hw_ftp_upload_sync(file, data, len, timeout)` | FTP 업로드 |

### SEH (Structured Exception Handling) 보호

모든 P/Invoke 경계 함수는 `__try / __except`로 래핑:
- 크래시 주소, fault 주소, 모듈명 → `hw_diag.log` 기록
- 프로세스 크래시 방지, 에러 코드 반환 (-99)
- EAL init 실패 시 메모리 자동 축소 재시도 (2GB → 64MB)

### dllimport 데이터 심볼 워크어라운드 (hw_ring_ops.h)

**문제:** DPDK inline 함수가 `rte_mempool_ops_table`, `rte_eth_fp_ops` 데이터 심볼을 `__declspec(dllimport)` 없이 참조 → 가비지 주소 → 크래시

**해결:** `rte_pktmbuf_alloc/free`, `rte_eth_rx/tx_burst` 매크로를 직접 ring/fp_ops 접근으로 오버라이드 (GetProcAddress 런타임 해석)

### 메모리 모델 (mbuf lifecycle)

```
1. 할당:  hw_pktmbuf_alloc(pool) → rte_ring_mc_dequeue
2. 리셋:  rte_pktmbuf_reset(m) → nb_segs=1, next=NULL, refcnt=1
3. 기록:  hw_pktmbuf_append(m, len) → 데이터 공간 포인터 반환
4. 전송:  hw_tx_burst() → NIC DMA가 전송 후 해제
5. 수신:  hw_rx_burst() → CPU 소유 mbuf 반환
6. 해제:  rte_pktmbuf_free(m) → rte_ring_mp_enqueue (체인 지원)

Mempool: cache_size=0 (non-EAL 스레드 C# main에서 할당 가능)
Hugepage: Windows VirtualAlloc2 + MEM_LARGE_PAGES
```

---

## 9. 네트워크 상수

### DP860 네트워크 (`DefPg.cs` — Dp860Network)

```
Network Prefix:   169.254.199.0/24 (link-local)
PC IP:            169.254.199.10
PC Base Port:     8000           (pg.status, power.read, pg.init)
PC PG Port[i]:    8001 + i       (per-CH 명령)

PG IP[i]:         169.254.199.(11 + i)
PG Port[i]:       8001 + i
```

**4CH 구성 예:**

| CH | PC 포트 | PG IP | PG 포트 | 용도 |
|----|---------|-------|---------|------|
| Base | 8000 | — | — | pg.status, power.read |
| CH0 | 8001 | 169.254.199.11 | 8001 | PG 명령 |
| CH1 | 8002 | 169.254.199.12 | 8002 | PG 명령 |
| CH2 | 8003 | 169.254.199.13 | 8003 | PG 명령 |
| CH3 | 8004 | 169.254.199.14 | 8004 | PG 명령 |

### FTP 인증 (`DefPg.cs` — Dp860Ftp)

```
Username: upload    Password: upload     경로: /home/upload
Root:     root      Password: insta
```

### 타이밍 상수 (`DefPg.cs` — PgTimerDefaults)

| 상수 | 값 | 설명 |
|------|-----|------|
| `CmdWaitAckDefault` | 200 ms | 일반 명령 타임아웃 |
| `ConnCheckInterval` | 2000 ms | pg.status 주기 |
| `PwrMeasureIntervalDefault` | 2000 ms | 전원 측정 주기 |
| `FlashReadWaitMsMinimum` | 5000 ms | Flash 읽기 최소 대기 |
| `FlashWriteWaitMsMinimum` | 10000 ms | Flash 쓰기 최소 대기 |

### 패킷 상수

| 상수 | 값 | 설명 |
|------|-----|------|
| `MaxRxBurst` | 32 | DispatchPoll 1회 최대 수신 |
| `ArpTimeoutMs` | 3000 | ARP 해석 타임아웃 |
| `ArpRetries` | 3 | ARP 재시도 횟수 |
| `EtherHdr.Size` | 14 bytes | Ethernet 헤더 |
| `Ipv4Hdr.Size` | 20 bytes | IPv4 헤더 |
| `UdpHdr.Size` | 8 bytes | UDP 헤더 |
| `Spill ring` | 256 entries | lock-free SPSC 버퍼 |

---

## 10. 에러 처리 & 폴백

### DPDK 초기화 실패

```
HwManager.InitializeAsync() 실패:
  ├─ EAL init -99 (SEH crash) → 메모리 자동 축소 재시도 (2GB→1GB→...→64MB)
  ├─ EAL init -98 (double-init) → 이미 초기화됨, 경고
  ├─ Hugepage 부족 → dpdkFailed=true
  ├─ NIC 미감지 → dpdkFailed=true
  └─ Link down (10초 타임아웃) → dpdkFailed=true

  → 모든 실패: Socket UDP 자동 폴백
  → UI: "Socket (DPDK 실패)"
  → 진단: hw_diag.log, dpdk_bus_debug.log
```

### FTP 세션 에러

```
Download/Upload 실패:
  ├─ DisposeFtpSession() → 세션 완전 해제
  └─ 다음 FTP 호출 시 EnsureFtpSession() → 세션 재생성

ConnectAsync 실패:
  ├─ StopLwip() + Dispose()
  └─ InvalidOperationException 전파

lwIP init 실패:
  ├─ Dispose()
  └─ InvalidOperationException 전파
```

### 명령 재시도

```
Dp860SendCmd(command, waitMs, retry):
  ├─ retry > 0: 최대 retry+1회 시도
  ├─ Status==Disconnected: 즉시 중단
  └─ 각 시도: CheckCmdAck(task, waitMs)
      ├─ WAIT_OBJECT_0 (0) → 성공
      └─ Timeout (1) → 다음 시도
```

---

## 11. 성능 특성

### RTT (Round-Trip Time)

| 모드 | 일반 명령 | pg.status | 비고 |
|------|-----------|-----------|------|
| **DPDK** | 0.1–0.3 ms | 0.3–1.0 ms | 커널 bypass, 폴링 |
| **Pipeline** | 1–5 ms | 1–5 ms | 커널 경유, 이벤트 |
| **Socket** | 1–5 ms | 1–5 ms | 커널 경유, async |

### 스레드 효율

| 항목 | 값 |
|------|-----|
| RX burst size | 최대 32 mbufs/poll |
| TX | 단일 패킷/호출 (배치: warmup 시 32) |
| SpinWait 기간 | 2ms (커널 전환 없이 ~70% 응답 처리) |
| RX idle sleep | ~10μs (SpinWait(10)) |
| RX 스레드 core affinity | Core 1 (SetThreadAffinityMask) |
| Main thread core | Core 0 (reserved) |

### 메모리

| 항목 | 값 |
|------|-----|
| Hugepage | 기본 256MB (최소 64MB) |
| Mempool cache | 0 (non-EAL 스레드 호환) |
| Spill ring | 256 entries (lock-free) |
| FTP 세션 | 최대 4 동시 |
| mbuf 크기 | RTE_MBUF_DEFAULT_BUF_SIZE |

---

## 12. 파일 참조

| 파일 | 역할 | 위치 |
|------|------|------|
| `PgDpdkServer.cs` | DPDK 전송 구현 (1255 lines) | `ITOLED.Hardware/PatternGenerator/` |
| `PgPipelineServer.cs` | Pipeline 전송 (NetCoreServer) | `ITOLED.Hardware/PatternGenerator/` |
| `PgUdpServer.cs` | Socket 전송 (UdpClient) | `ITOLED.Hardware/PatternGenerator/` |
| `IPgTransport.cs` | 전송 추상화 인터페이스 | `ITOLED.Hardware/PatternGenerator/` |
| `CommPgDriver.cs` | PG 드라이버 (명령/FTP/ACK) | `ITOLED.Hardware/PatternGenerator/` |
| `DpdkNicCoordinator.cs` | NIC 접근 조율 (RX pause/resume) | `ITOLED.Hardware/PatternGenerator/` |
| `DefPg.cs` | 네트워크/FTP/타이밍 상수 | `ITOLED.Core/Definitions/` |
| `SystemInfo.cs` | INI 설정 모델 | `ITOLED.Core/Models/` |
| `ConfigurationService.cs` | INI 읽기 | `ITOLED.Core/Common/` |
| `Program.cs` | 전송 모드 선택/초기화 | `ITOLED.OC/` |
| `hwio.c` | Native DPDK wrapper | `DPDK/01_Windows/DpdkShim/` |
| `dpdk_netif.c` | lwIP 네트워크 인터페이스 | `DPDK/01_Windows/DpdkShim/` |
| `HwNet.dll` | C# P/Invoke wrapper | `DPDK/01_Windows/DpdkNet/` |
