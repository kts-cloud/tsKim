# hwio.dll Bug Report — lwIP FTP 반복 사용 시 Heap Corruption

**보고일**: 2026-03-25
**보고자**: ITOLED_OC C# 팀
**심각도**: Critical (프로세스 크래시)
**영향**: OC 검사 flow 중 Flash 데이터 읽기(FTP) 수백 회 반복 시 랜덤 크래시

---

## 1. 증상

OC 보상 flow에서 LGD DLL이 `FlashRead_Data`를 4KB 단위로 수백 회 반복 호출.
각 호출마다 hwio.dll의 FTP API (`hw_ftp_download_sync_ex`)를 사용하여 PG 내장 FTP 서버에서 파일을 다운로드.
**약 50~200회 반복 후 프로세스가 Heap Corruption으로 크래시.**

## 2. 재현 환경

| 항목 | 값 |
|------|-----|
| OS | Windows 10 x64 (19045) |
| .NET | .NET 8.0 (CoreCLR 8.0.2526.11203) |
| hwio.dll | 현재 버전 (체크섬 미확인) |
| DPDK | 현재 버전 |
| PG | DP860 (169.254.199.11~14) |
| FTP 서버 | PG 내장 lwIP FTP (port 21, user: upload) |
| 파일 크기 | 4096 bytes/회 |
| 반복 횟수 | ~200~500회/flow |
| 크래시 빈도 | 1~3 flow마다 1회 (거의 매번) |

## 3. 크래시 덤프 분석 (총 6건)

### 3.1 Heap Corruption (c0000374) — 4건

**공통 스택**:
```
ntdll!RtlReportFatalFailure
ntdll!RtlReportCriticalFailure
ntdll!RtlpHeapHandleError
ntdll!RtlpHpHeapHandleError
ntdll!RtlpLogHeapFailure
```

#### Case A: `hw_ftp_download_sync_ex` 중 메모리 해제 시 감지
**덤프**: `ITOLED.OC.exe.4368.dmp` (2026-03-25 13:55)
```
ntdll!RtlFreeHeap+0x51
hwio!hw_lwip_set_external_rx+0x1e2ac    ← 내부 free() 호출
hwio!hw_lwip_set_external_rx+0xb093     ← lwIP 내부 함수
hwio!hw_lwip_set_external_rx+0x58a      ← lwIP TCP 처리
hwio!hw_ftp_connect_sync_ex+0x296       ← FTP connect 중
hwio!hw_ftp_download_sync_ex+0x46       ← FTP 다운로드 진입
```

#### Case B: `hw_dispatch_poll` 중 메모리 할당 시 감지
**덤프**: `ITOLED.OC.exe.5792.dmp` (2026-03-24 19:49), `ITOLED.OC.exe.1860.dmp` (2026-03-24 09:03)
```
ntdll!RtlpAllocateHeapInternal+0x9a7
hwio!hw_lwip_set_external_rx+0x1e334    ← 내부 malloc() 호출
hwio!hw_lwip_set_external_rx+0xaf49     ← lwIP 내부 함수
hwio!hw_lwip_set_external_rx+0xb09d     ← lwIP TCP 처리
hwio!hw_lwip_set_external_rx+0x58a      ← lwIP dispatch
hwio!hw_dispatch_poll+0x1f5             ← RX 폴링 루프
```

#### Case C: `hw_ftp_connect_sync_ex` 중 감지
**덤프**: `ITOLED.OC.exe.10128.dmp` (2026-03-25 10:40)
```
hwio!hw_lwip_set_external_rx+0x1e2ac
hwio!hw_lwip_set_external_rx+0xb093
hwio!hw_lwip_set_external_rx+0x58a
hwio!hw_ftp_connect_sync_ex+0x296
hwio!hw_ftp_connect_sync_ex+0x149       ← connect 재시도 중
```

### 3.2 Access Violation (c0000005) — 2건

#### Case D: NULL vtable 포인터 역참조
**덤프**: `ITOLED.OC.exe.6564.dmp` (2026-03-23 17:13)
```
coreclr!UMThunkUnwindFrameChainHandler
IP=0xC0000000 (free block — 유효하지 않은 코드 주소)
READ_ADDRESS: 0x40 (NULL + vtable offset)
```
→ 힙 손상으로 인한 2차 피해 — 이미 손상된 메모리를 참조

#### Case E: 보호된 메모리 접근
**덤프**: `ITOLED.OC.exe.3612.dmp` (2026-03-25 13:59)
```
System.AccessViolationException: Attempted to read or write protected memory.
hwio!hw_simple_port_setup+0x1da
```

## 4. 호출 패턴 (C# → hwio.dll)

```
[반복 200~500회]
  hw_ftp_connect_sync_ex(ip, port, user, pass, timeout)  ← 1회 (세션 시작)
  hw_ftp_download_sync_ex(filename, timeout)              ← 200~500회 반복
  hw_ftp_disconnect_sync()                                ← 1회 (세션 종료)

[앱 시작 시 1회]
  hw_lwip_set_external_rx(true)

[앱 종료 시 1회]
  hw_lwip_set_external_rx(false)
```

**주의**: `hw_lwip_set_external_rx` 토글은 앱 수명 동안 2회만 호출.
FTP connect/download/disconnect만 반복.

## 5. 관련 오프셋 분석

모든 크래시에서 `hwio!hw_lwip_set_external_rx` 기준 오프셋이 동일:

| 오프셋 | 추정 함수 | 설명 |
|--------|----------|------|
| +0x58a | lwIP core (tcp_input 또는 유사) | TCP 패킷 처리 |
| +0xaf49 / +0xb093 / +0xb09d | lwIP pbuf/memp 관리 | 버퍼 할당/해제 |
| +0x1e2ac / +0x1e334 | CRT malloc/free wrapper | 힙 할당/해제 |

**참고**: `hw_lwip_set_external_rx`가 스택에 나타나는 이유는 lwIP 코드가 이 함수와 같은 오브젝트 파일에 링크되어 있기 때문 (심볼이 가장 가까운 export 함수 기준으로 표시됨).

## 6. 원인 추정

### 가설 1: lwIP pbuf/memp 풀 오버플로우
FTP 다운로드를 수백 회 반복하면서 lwIP 내부 pbuf 또는 memp 풀이 고갈/오버플로우되어 프로세스 힙을 손상시킴.

### 가설 2: lwIP TCP PCB 누수
FTP 세션 유지 중 내부적으로 TCP PCB (Protocol Control Block)가 누적되어 메모리 관리 불일치 발생.

### 가설 3: FTP 데이터 연결 리소스 누수
FTP PASV 모드에서 데이터 연결(port 20)이 다운로드마다 생성/해제되면서 내부 리소스가 제대로 정리되지 않음.

## 7. 확인 요청 사항

1. **lwIP 메모리 설정 확인**: `MEMP_NUM_*`, `PBUF_POOL_SIZE` 등이 수백 회 FTP 반복에 충분한지?
2. **FTP 데이터 연결 정리**: `hw_ftp_download_sync_ex` 완료 후 데이터 소켓/PCB가 완전히 해제되는지?
3. **lwIP heap 모드**: lwIP가 프로세스 힙(`malloc/free`)을 직접 사용하는지, 별도 풀을 사용하는지?
4. **동시성**: `hw_dispatch_poll`과 `hw_ftp_download_sync_ex`가 서로 다른 스레드에서 실행될 때 경합 조건은 없는지?

## 8. 임시 완화 방안 (C# 쪽)

현재 적용 중:
- `SetLwipExternalRx` 토글을 앱 시작/종료 시 1회로 제한
- FTP 세션을 DLL flow 단위로 유지 (connect 1회 → download N회 → disconnect 1회)
- 다운로드 실패 시 세션 재생성

검토 중:
- FTP 대신 Socket FTP (RFC 959 over TCP) 사용하여 lwIP 완전 우회
- FTP 대신 UDP NVM read (256바이트 단위) 사용

## 9. 덤프 파일 위치

```
\\10.10.5.35\d\CrashDumps\
├── ITOLED.OC.exe.4368.dmp   (2026-03-25 13:55, c0000374, hw_ftp_download_sync_ex)
├── ITOLED.OC.exe.10128.dmp  (2026-03-25 10:40, c0000374, hw_ftp_connect_sync_ex)
├── ITOLED.OC.exe.5792.dmp   (2026-03-24 19:49, c0000374, hw_dispatch_poll)
├── ITOLED.OC.exe.1860.dmp   (2026-03-24 09:03, c0000374, hw_dispatch_poll)
├── ITOLED.OC.exe.6564.dmp   (2026-03-23 17:13, c0000005, vtable corruption)
└── ITOLED.OC.exe.3612.dmp   (2026-03-25 13:59, c0000005, hw_simple_port_setup)
```

## 10. AppLog (크래시 직전)

FTP 다운로드가 정상적으로 반복되다가 로그가 갑자기 중단됨 (관리 예외 없이 프로세스 종료):
```
10:40:01.420 [INFO] [CH0] <PG> FTP FileDownload: FlashR_A0x5a9000_L4096.bin
10:40:01.420 [INFO] [CH0] <PG> FTP session refresh (after 50 downloads)
10:40:01.422 [INFO] [NicCoordinator] FTP 해제 (activeCount=0)
10:40:01.422 [INFO] [NicCoordinator] external RX 비활성화
10:40:01.422 [INFO] [NicCoordinator] FTP 활성화 (activeCount=1)
10:40:01.422 [INFO] [NicCoordinator] external RX 활성화
← 여기서 프로세스 크래시 (이후 로그 없음)
```
