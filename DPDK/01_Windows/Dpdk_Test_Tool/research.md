# DPDK Test Tool - 코드 분석 리서치 문서

## 1. 프로젝트 개요

**DPDK Test Tool**은 DPDK(Data Plane Development Kit) 기반 UDP 통신 가속화 테스트 도구로, Windows 환경에서 DPDK를 활용한 고성능 패킷 송수신과 일반 Socket 기반 통신을 동일 UI에서 비교 테스트할 수 있는 .NET WinForms 애플리케이션이다.

### 핵심 목적
- DPDK를 통한 커널 바이패스 UDP 패킷 고속 송수신
- 일반 Socket API와의 성능 비교 (PPS, RTT, Mbps)
- Request/Response 패턴의 지연시간(RTT) 측정
- ARP 자동 해석을 통한 L2 통신 지원
- TCP 클라이언트/서버 테스트 기능
- HTML 성능 비교 리포트 내보내기 (PC 사양, 테스트 설정 포함)

### 기술 스택
| 항목 | 기술 |
|------|------|
| 런타임 | .NET 9.0 (Windows) |
| UI | Windows Forms |
| DPDK 래퍼 라이브러리 | DpdkNet.dll (C# 클래스 라이브러리) |
| 네이티브 인터페이스 | P/Invoke (dpdk_shim.dll) — DpdkNet 내부에서 사용 |
| DPDK 버전 | 26.x (DLL 이름 기준: `rte_*-26.dll`) |
| 언어 | C# |
| 설정 저장 | System.Text.Json |

---

## 2. 솔루션 구조 (2-프로젝트)

### 프로젝트 분리
기존에는 단일 프로젝트였으나, 현재는 **DpdkNet**(라이브러리)과 **Dpdk_Test_Tool**(UI)로 분리되었다.

```
01_Windows/
├── DpdkNet/                        # C# 클래스 라이브러리 (DPDK 래핑)
│   ├── DpdkNet.csproj              # net9.0-windows 클래스 라이브러리
│   ├── Core/                       # DPDK 생명주기, 상태, 포트 관리
│   │   ├── DpdkManager.cs          # 싱글톤 DPDK 생명주기 관리
│   │   ├── DpdkState.cs            # 상태 열거형
│   │   ├── DpdkStatusEventArgs.cs  # 상태 변경 이벤트 인자
│   │   ├── DpdkInitOptions.cs      # EAL 초기화 옵션
│   │   ├── IDpdkContext.cs         # DPDK 컨텍스트 인터페이스
│   │   ├── PortInfo.cs             # 포트 정보 클래스
│   │   └── PacketStructs.cs        # 네트워크 프로토콜 헤더 구조체
│   ├── Interop/                    # P/Invoke 바인딩 (internal)
│   │   ├── DpdkInterop.cs          # dpdk_shim.dll P/Invoke 선언
│   │   └── NativeStructs.cs        # 네이티브 결과 구조체
│   ├── Engine/                     # DPDK 패킷 엔진
│   │   ├── IDpdkEngine.cs          # 엔진 인터페이스
│   │   ├── DpdkUdpTxEngine.cs      # DPDK UDP 송신
│   │   ├── DpdkUdpRxEngine.cs      # DPDK UDP 수신
│   │   ├── DpdkEchoEngine.cs       # DPDK UDP 에코
│   │   └── DpdkUdpReqRespEngine.cs # DPDK UDP Request/Response + ARP
│   ├── Stats/                      # 성능 통계
│   │   ├── PerformanceCounter.cs   # 실시간 PPS/Mbps 카운터
│   │   ├── StatsSnapshot.cs        # 시점별 통계 스냅샷
│   │   └── RttStats.cs             # RTT 통계 (Lock-free)
│   ├── Config/                     # 엔진 설정 클래스
│   │   ├── TxConfig.cs             # TX 설정
│   │   ├── RxConfig.cs             # RX 설정
│   │   └── ReqRespConfig.cs        # Req/Resp 설정
│   ├── Models/                     # 데이터 모델
│   │   ├── RxPacketInfo.cs         # 수신 패킷 정보
│   │   └── ReqRespResult.cs        # Req/Resp 결과
│   ├── Logging/                    # 패킷 로깅
│   │   └── PacketLogger.cs         # CSV 패킷 로거
│   └── Utilities/                  # 유틸리티
│       ├── NetUtils.cs             # 바이트 오더, 체크섬, MAC/IP 유틸
│       └── PowerPlanHelper.cs      # Windows 전원 관리 (고성능 모드)
│
├── Dpdk_Test_Tool/                 # WinForms UI 애플리케이션
│   ├── Dpdk_Test_Tool.csproj       # net9.0-windows WinExe (DpdkNet 참조)
│   ├── Program.cs                  # 엔트리포인트
│   ├── Core/                       # 앱 설정
│   │   └── AppSettings.cs          # JSON 프로필 설정 관리
│   ├── Engine/                     # Socket/TCP 엔진 (비-DPDK)
│   │   ├── SocketUdpEngine.cs      # Socket UDP 엔진 5종
│   │   ├── TcpClientEngine.cs      # TCP 클라이언트
│   │   └── TcpServerEngine.cs      # TCP 서버
│   ├── Export/                     # HTML 리포트 내보내기
│   │   ├── HtmlReportGenerator.cs  # HTML 리포트 생성기
│   │   └── PerformanceReportData.cs # 리포트 데이터 모델
│   └── UI/                         # 사용자 인터페이스
│       ├── MainForm.cs             # 메인 폼 (탭 컨트롤 호스트)
│       ├── DpdkUdpTab.cs           # DPDK UDP 탭
│       ├── SocketUdpTab.cs         # Socket UDP 탭
│       ├── TcpTestTab.cs           # TCP 테스트 탭
│       ├── PerformanceTab.cs       # 성능 모니터 탭 + HTML 내보내기
│       └── SettingsTab.cs          # DPDK 설정 탭 + CPU 사용량 모니터
│
├── DpdkShim/                       # C 네이티브 shim 소스
│   ├── dpdk_shim.c                 # SEH 보호 래퍼 (P/Invoke 대상)
│   └── dpdk_diag.c                 # 네이티브 진단 도구
│
├── scripts/                        # 빌드/배포 스크립트
│   ├── build_shim.ps1              # dpdk_shim.dll 빌드
│   ├── build_diag.ps1              # dpdk_diag.exe 빌드
│   └── copy_dlls.ps1               # DLL 복사
│
├── docs/                           # 문서
│   ├── DpdkNet_Guide.html          # DpdkNet 라이브러리 가이드
│   └── dpdk_vs_socket_comparison.html # DPDK vs Socket 비교 문서
│
└── dpdk-src/                       # DPDK 26.03.0-rc0 소스 + 빌드
```

### 의존성 관계
```
Dpdk_Test_Tool (.csproj)
  └─ ProjectReference → DpdkNet (.csproj)
                            └─ P/Invoke → dpdk_shim.dll (runtime)
                                             └─ links → DPDK DLLs (rte_*-26.dll)
```

**핵심**: Dpdk_Test_Tool에는 `DllImport`나 `dpdk_shim` 참조가 전혀 없음. 모든 네이티브 호출은 DpdkNet 내부 `DpdkInterop` (internal)을 통해 수행.

### 소스 파일 요약

| 프로젝트 | 레이어 | 파일 수 | 주요 파일 |
|----------|--------|---------|-----------|
| DpdkNet | Core | 7 | DpdkManager, DpdkState, PacketStructs, PortInfo, IDpdkContext, DpdkInitOptions, DpdkStatusEventArgs |
| DpdkNet | Interop | 2 | DpdkInterop (internal), NativeStructs (internal) |
| DpdkNet | Engine | 5 | IDpdkEngine, DpdkUdpTxEngine, DpdkUdpRxEngine, DpdkEchoEngine, DpdkUdpReqRespEngine |
| DpdkNet | Stats | 3 | PerformanceCounter, StatsSnapshot, RttStats |
| DpdkNet | Config | 3 | TxConfig, RxConfig, ReqRespConfig |
| DpdkNet | Models | 2 | RxPacketInfo, ReqRespResult |
| DpdkNet | Logging | 1 | PacketLogger |
| DpdkNet | Utilities | 2 | NetUtils, PowerPlanHelper |
| Dpdk_Test_Tool | Entry | 1 | Program.cs |
| Dpdk_Test_Tool | Core | 1 | AppSettings |
| Dpdk_Test_Tool | Engine | 3 | SocketUdpEngine, TcpClientEngine, TcpServerEngine |
| Dpdk_Test_Tool | Export | 2 | HtmlReportGenerator, PerformanceReportData |
| Dpdk_Test_Tool | UI | 6 | MainForm, DpdkUdpTab, SocketUdpTab, TcpTestTab, PerformanceTab, SettingsTab |

---

## 3. 빌드 시스템

### Dpdk_Test_Tool 프로젝트 (`Dpdk_Test_Tool.csproj`)
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net9.0-windows</TargetFramework>
    <Nullable>enable</Nullable>
    <UseWindowsForms>true</UseWindowsForms>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\DpdkNet\DpdkNet.csproj" />
  </ItemGroup>
</Project>
```

### DpdkNet 프로젝트 (`DpdkNet.csproj`)
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0-windows</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <RootNamespace>DpdkNet</RootNamespace>
    <AssemblyName>DpdkNet</AssemblyName>
  </PropertyGroup>
</Project>
```

- DpdkNet은 **클래스 라이브러리** (OutputType 없음 = dll)
- 외부 NuGet 패키지: 없음 (순수 .NET 기본 라이브러리만 사용)

### 런타임 의존성
빌드 출력 디렉토리에 다음 네이티브 DLL이 필요:
- `dpdk_shim.dll` — C P/Invoke 브릿지 (SEH 보호 래퍼)
- DPDK 코어: `rte_eal-26.dll`, `rte_mbuf-26.dll`, `rte_ethdev-26.dll` 등 14개
- PMD 드라이버: `rte_net_ixgbe-26.dll` (X550), `rte_net_e1000-26.dll` (I210), `rte_net_i40e-26.dll` (X710), `rte_net_iavf-26.dll`, `rte_net_ice-26.dll` (E810)
- 버스 드라이버: `rte_bus_pci-26.dll`, `rte_bus_vdev-26.dll`

### dpdk_shim.dll 빌드 (`build_shim.ps1`)
- Clang으로 빌드, `-march=native` (CPU 최적화)
- **새 PC마다 재빌드 필요**: CPU별 최적화 + 로컬 DPDK 빌드에 의존

---

## 4. 아키텍처

### 2-프로젝트 레이어 구조

```
┌─────────────────────────────────────────────────────────┐
│  Dpdk_Test_Tool (WinForms App)                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  UI Layer                                        │    │
│  │  MainForm → DpdkUdpTab, SocketUdpTab, TcpTestTab │    │
│  │             PerformanceTab, SettingsTab           │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  App Engine Layer (Socket/TCP)                   │    │
│  │  SocketUdpEngine (5종), TcpClient, TcpServer     │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  Export Layer                                    │    │
│  │  HtmlReportGenerator, PerformanceReportData      │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  App Core                                        │    │
│  │  AppSettings (JSON 프로필)                        │    │
│  └─────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│  DpdkNet.dll (클래스 라이브러리, ProjectReference)       │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Public API                                      │    │
│  │  DpdkManager, IDpdkContext, PortInfo, DpdkState   │    │
│  │  Config (TxConfig, RxConfig, ReqRespConfig)       │    │
│  │  Models (RxPacketInfo, ReqRespResult)              │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  Engine Layer (DPDK)                             │    │
│  │  IDpdkEngine, TX, RX, Echo, ReqResp              │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  Stats Layer                                     │    │
│  │  PerformanceCounter, StatsSnapshot, RttStats      │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  Utilities                                       │    │
│  │  NetUtils, PowerPlanHelper, PacketLogger          │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  Interop (internal — 외부 노출 안됨)              │    │
│  │  DpdkInterop (P/Invoke) → dpdk_shim.dll           │    │
│  │  NativeStructs (ShimReqRespResult, ShimBatchStats)│    │
│  └─────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│  dpdk_shim.dll (C 네이티브)                             │
│  SEH 보호 래퍼, rte_eal_init, rte_eth_*, rte_mbuf_* 등  │
├─────────────────────────────────────────────────────────┤
│  DPDK 26.x DLLs                                        │
│  rte_eal-26.dll, rte_ethdev-26.dll, rte_mbuf-26.dll 등  │
└─────────────────────────────────────────────────────────┘
```

### 의존성 흐름
```
Dpdk_Test_Tool UI
    ├→ DpdkNet.DpdkManager (초기화/클린업)
    ├→ DpdkNet.Engine.* (DPDK 엔진 생성/시작/정지)
    ├→ DpdkNet.Stats.* (성능 카운터 읽기)
    ├→ SocketUdpEngine / TcpEngine (Socket 엔진 — Dpdk_Test_Tool 자체)
    └→ Export.HtmlReportGenerator (HTML 리포트 생성)

DpdkNet Engine
    ├→ DpdkNet.Core.DpdkManager (포트/풀 접근)
    ├→ DpdkNet.Interop.DpdkInterop (P/Invoke, internal)
    ├→ DpdkNet.Stats.* (성능 카운터 기록)
    └→ DpdkNet.Utilities.NetUtils (패킷 구성)

DpdkNet.Interop.DpdkInterop (internal)
    └→ dpdk_shim.dll (DllImport, CallingConvention.Cdecl)
```

---

## 5. DpdkNet — Interop 레이어 상세

### 5.1 DpdkInterop.cs — P/Invoke 바인딩 (internal)

`dpdk_shim.dll`에 대한 C# 바인딩. 모든 함수는 `CallingConvention.Cdecl`.
**접근 제한**: `internal static class` — DpdkNet 외부에서 직접 호출 불가.

#### EAL (Environment Abstraction Layer)
| 함수 | 설명 |
|------|------|
| `shim_eal_init(int argc, IntPtr argv)` | EAL 초기화 (SEH 보호) |
| `shim_eal_cleanup()` | EAL 정리 |
| `shim_version()` | DPDK 버전 문자열 반환 |

#### Ethdev (이더넷 장치)
| 함수 | 설명 |
|------|------|
| `shim_eth_dev_count_avail()` | 사용 가능 포트 수 |
| `shim_eth_macaddr_get(port, ref mac)` | MAC 주소 조회 |
| `shim_eth_link_get_nowait(port, ref link)` | 링크 상태 (비차단) |
| `shim_eth_stats_get(port, ref stats)` | HW 통계 조회 |
| `shim_eth_stats_reset(port)` | HW 통계 초기화 |
| `shim_eth_dev_stop(port)` | 포트 중지 |
| `shim_eth_dev_close(port)` | 포트 닫기 |
| `shim_simple_port_setup(port, pool, speeds)` | 포트 설정+시작 (SEH 보호) |

#### Mbuf (메모리 버퍼)
| 함수 | 설명 |
|------|------|
| `shim_pktmbuf_pool_create_safe(...)` | Mbuf 풀 생성 (SEH 보호) |
| `shim_pktmbuf_alloc(pool)` | Mbuf 할당 |
| `shim_pktmbuf_free(mbuf)` | Mbuf 해제 |
| `shim_pktmbuf_append(mbuf, len)` | Mbuf에 데이터 공간 추가 |
| `shim_pktmbuf_mtod(mbuf)` | Mbuf 데이터 포인터 |
| `shim_pktmbuf_data_len(mbuf)` | 데이터 길이 |
| `shim_pktmbuf_pkt_len(mbuf)` | 패킷 전체 길이 |

#### Packet I/O (핫 패스 — SEH 오버헤드 없음)
| 함수 | 설명 |
|------|------|
| `shim_rx_burst(port, queue, pkts[], nb)` | RX 배치 수신 |
| `shim_tx_burst(port, queue, pkts[], nb)` | TX 배치 송신 |

#### Req/Resp (네이티브 전체 사이클)
| 함수 | 설명 |
|------|------|
| `shim_reqresp_once(...)` | 단일 요청-응답 (ARP 처리 포함) |
| `shim_reqresp_batch(...)` | 파이프라인 배치 요청-응답 |

### 5.2 NativeStructs.cs — 네이티브 결과 구조체 (internal)

```csharp
// 단일 Req/Resp 결과
[StructLayout(LayoutKind.Sequential)]
internal struct ShimReqRespResult {
    int Status;        // 0=success, 1=timeout, -1=alloc_fail, -2=tx_fail
    double RttMs;
    ushort RespLen;
    uint SrcIp;
    ushort SrcPort;
}

// 배치 Req/Resp 결과
[StructLayout(LayoutKind.Sequential)]
internal struct ShimBatchStats {
    ushort Sent, Received;
    double ElapsedMs, TotalRttMs, MinRttMs, MaxRttMs, TotalRttSqMs;
}
```

---

## 6. DpdkNet — Core 레이어 상세

### 6.1 DpdkManager.cs — 싱글톤 DPDK 생명주기 관리

**네임스페이스**: `DpdkNet`
**패턴**: `Lazy<T>` 기반 싱글톤 (`DpdkManager.Instance`), `IDpdkContext` 및 `IDisposable` 구현

#### 상태 머신 (DpdkState)
```
NotInitialized → Initializing → Ready
                      ↓
                    Error
Ready → CleanedUp
```

#### 초기화 시퀀스 (`InitializeAsync` → `Initialize`)
1. **PMD 드라이버 사전 로드** (`PreloadDrivers`)
   - Windows DPDK는 Linux와 달리 PMD DLL을 자동 로드하지 않음
   - `kernel32.dll!LoadLibraryA`로 명시적 로드
   - 1단계: 코어 라이브러리 14개 (rte_eal, rte_mbuf, rte_ethdev 등)
   - 2단계: PMD 드라이버 9개 (ixgbe, e1000, i40e, iavf, ice, bus_pci, bus_vdev, mempool_ring, mempool_stack)
2. **DPDK 버전 확인** (`shim_version`)
3. **EAL 초기화** (`shim_eal_init`) — C#에서 전달한 Core Mask, Memory, Log Level 파라미터를 그대로 전달
4. **포트 수 확인** (`shim_eth_dev_count_avail`)
5. **Mbuf Pool 생성** — 기본 8191 엔트리, 캐시 256, 데이터룸 2176B (2048+128)
6. **모든 포트 설정** — MAC 조회, 링크 확인, `shim_simple_port_setup`, 재확인
7. **활성 포트 결정** — 사용자 지정 포트 우선, 첫 번째 설정된 포트 폴백
8. **링크 업 대기** — 최대 10초 (10G NIC용)

#### dpdk_shim.c CoreMask 버그 수정 (중요)
기존에는 `shim_eal_init()`에서 C#이 전달하는 argc/argv를 무시하고 하드코딩된 `-l 0 -m 128`을 사용했으나, 현재는 C#에서 전달한 인자를 그대로 `rte_eal_init(argc, argv)`에 전달하도록 수정됨. 디버그 로깅도 추가됨.

#### 런타임 포트 전환
```csharp
public bool SwitchPort(ushort newPortId)  // 재초기화 없이 활성 포트 변경
```

#### 클린업 순서
1. 모든 설정된 포트 `dev_stop` → `dev_close`
2. EAL 정리 (`shim_eal_cleanup`)
3. 관리 메모리 해제 (argv 포인터, 문자열 포인터)

#### 주요 프로퍼티
| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `State` | `DpdkState` | 현재 상태 |
| `MbufPool` | `IntPtr` | Mbuf 풀 핸들 |
| `PortId` | `ushort` | 활성 포트 ID |
| `LocalMac` | `byte[6]` | 활성 포트 MAC |
| `Ports` | `IReadOnlyList<PortInfo>` | 전체 포트 정보 |
| `DpdkVersion` | `string?` | DPDK 버전 |
| `ErrorMessage` | `string?` | 에러 메시지 |

#### 이벤트
| 이벤트 | 시그니처 | 용도 |
|--------|----------|------|
| `StatusChanged` | `EventHandler<DpdkStatusEventArgs>` | 초기화 진행/상태 변경 알림 |
| `ActivePortChanged` | `Action` | 활성 포트 변경 알림 |

### 6.2 IDpdkContext — DPDK 컨텍스트 인터페이스

```csharp
public interface IDpdkContext {
    DpdkState State { get; }
    IntPtr MbufPool { get; }
    ushort PortId { get; }
    byte[] LocalMac { get; }
}
```

### 6.3 DpdkInitOptions — EAL 초기화 옵션

```csharp
public class DpdkInitOptions {
    string CoreMask = "0";
    int MemoryMb = 512;
    string LogLevel = "*:error";
    ushort PortId = 0;
    uint MbufPoolSize = 8191;
    uint LinkSpeeds = 0;
}
```

### 6.4 PacketStructs.cs — 네트워크 프로토콜 헤더 구조체

모든 구조체는 `[StructLayout(LayoutKind.Sequential, Pack = 1)]`으로 네이티브 메모리 레이아웃과 1:1 대응.

#### 프로토콜 헤더
| 구조체 | 크기 | 필드 |
|--------|------|------|
| `EtherHdr` | 14B | Dst[6], Src[6], EtherType |
| `Ipv4Hdr` | 20B | VersionIhl, TOS, TotalLength, PacketId, FragOff, TTL, NextProtoId, Checksum, SrcAddr, DstAddr |
| `UdpHdr` | 8B | SrcPort, DstPort, Len, Cksum |
| `ArpHdr` | 28B | HwType, ProtoType, HwLen, ProtoLen, Opcode, SenderMac[6], SenderIp, TargetMac[6], TargetIp |

#### DPDK 통계/정보 구조체
| 구조체 | 용도 |
|--------|------|
| `RteEthStats` | HW 통계 (ipackets, opackets, ibytes, obytes, imissed, ierrors, oerrors, rx_nombuf) |
| `RteEtherAddr` | 6바이트 MAC 주소 |
| `RteEthLink` | 링크 상태 (speed, duplex, autoneg, status — C 비트필드 매핑) |

#### `RteEthLink` 비트필드 매핑
```csharp
public ushort link_duplex  => (ushort)(_bitfield & 1);        // bit 0
public ushort link_autoneg => (ushort)((_bitfield >> 1) & 1); // bit 1
public ushort link_status  => (ushort)((_bitfield >> 2) & 1); // bit 2
```

### 6.5 NetUtils.cs — 바이트 오더, 체크섬, MAC/IP 유틸리티

**네임스페이스**: `DpdkNet.Utilities`

#### 바이트 오더 변환
```csharp
Htons(ushort) / Ntohs(ushort)  // 16비트 호스트↔네트워크 변환
Htonl(uint) / Ntohl(uint)      // 32비트 호스트↔네트워크 변환
```

#### IP 주소 변환
```csharp
IpToUint("192.168.0.1") → uint  // 문자열 → 리틀엔디안 uint (네트워크 바이트 순서)
UintToIp(uint) → "192.168.0.1"  // 역변환
```

#### MAC 주소
```csharp
ParseMac("AA:BB:CC:DD:EE:FF") → byte[6]  // ':' 또는 '-' 구분자 지원
FormatMac(byte[]) → "AA:BB:CC:DD:EE:FF"
```

#### IP 체크섬 (`ComputeIpChecksum`)
- RFC 1071 방식: 16비트 워드 합산 → carry 접기 → 1의 보수

#### UDP 체크섬 (`ComputeUdpChecksum`)
- Pseudo-header 포함: SrcIp + DstIp + Protocol(17) + UDP Length
- RFC 768 준수: 결과 0이면 0xFFFF 반환

### 6.6 PowerPlanHelper.cs — Windows 전원 관리

**네임스페이스**: `DpdkNet.Utilities`

DPDK 실행 시 자동으로 Windows 전원 옵션을 고성능으로 전환:
- 고성능 전원 관리 옵션 활성화
- 최소 프로세서 상태 100% (C-State 진입 방지)
- PCI Express ASPM 비활성화 (NIC 레이턴시 감소)
- `IDisposable` — 종료 시 원래 설정으로 복원

### 6.7 PacketLogger.cs — CSV 패킷 로거

**네임스페이스**: `DpdkNet.Logging`

- 백그라운드 스레드로 CSV 파일에 패킷 로그 기록
- TX/RX/ReqResp 방향별 로깅
- `ConcurrentQueue` 기반 Producer-Consumer 패턴
- 1초 간격 배치 플러시 (최대 10,000건)
- 출력 경로: `{실행 디렉토리}/logs/pkt_{engineName}_{timestamp}.csv`
- CSV 컬럼: `Elapsed_ms,Direction,SrcIP,DstIP,SrcPort,DstPort,DataLen,Data,RTT_ms,Status`

---

## 7. DpdkNet — Config/Models 레이어

### 7.1 Config 클래스 (DpdkNet.Config)

#### TxConfig
```csharp
byte[] DstMac, string DstIp, ushort DstPort,
string SrcIp, ushort SrcPort, int PayloadSize,
int TargetPps, string? PayloadText
```

#### RxConfig
```csharp
ushort FilterPort, string? FilterIp, int MaxQueueSize = 10000
```

#### ReqRespConfig
```csharp
byte[] DstMac, string DstIp/DstPort, string SrcIp/SrcPort,
int PayloadSize, string? PayloadText,
int TimeoutMs = 1000, int RepeatCount = 0 (무한),
int WindowSize = 1 (동기), bool EnableWarmup = true
```

### 7.2 Models (DpdkNet.Models)

#### RxPacketInfo
```csharp
byte[] SrcMac, DstMac; string SrcIp, DstIp;
ushort SrcPort, DstPort; int DataLen;
string? PayloadText; DateTime Timestamp;
```

#### ReqRespResult
```csharp
uint SeqNumber; bool Success; double RttMs;
string? ResponsePayload; string SrcIp; ushort SrcPort;
DateTime Timestamp;
```

---

## 8. DpdkNet — Engine 레이어 상세

### 8.1 IDpdkEngine 인터페이스

```csharp
public interface IDpdkEngine : IDisposable {
    bool IsRunning { get; }
    string? LastError { get; }
    void Stop();
}
```

### 8.2 DPDK 엔진 4종

모든 DPDK 엔진은 전용 백그라운드 `Thread` 위에서 폴링 루프를 실행하며, `DpdkManager.Instance`를 통해 포트와 Mbuf 풀에 접근한다.

#### 8.2.1 DpdkUdpTxEngine — DPDK UDP 송신

**핫 루프** (`TxLoopInner`):
1. **속도 제한**: `Stopwatch.Frequency` 기반 tick 계산, `SpinWait(10)` 대기
2. **배치 구성** (BatchSize=32):
   - `shim_pktmbuf_alloc` → `shim_pktmbuf_append` → `shim_pktmbuf_mtod`
   - Ethernet/IPv4/UDP 헤더 `Marshal.StructureToPtr`로 직접 기록
   - IP 체크섬 계산 후 기록
   - 페이로드: 텍스트 모드(ASCII) 또는 바이너리 패턴(0x00~0xFF)
3. **배치 전송**: `shim_tx_burst` → 미전송 Mbuf 해제
4. **RX 폴링**: `PollRxResponses`로 응답 패킷 수신 → `ResponseQueue`에 저장

**속도 제한 없는 경우**: 32개씩 배치 전송 (최대 속도)
**속도 제한 있는 경우**: 1개씩 전송, tick 기반 정밀 제어

#### 8.2.2 DpdkUdpRxEngine — DPDK UDP 수신

**수신 루프** (`RxLoop`):
1. `shim_rx_burst` (BatchSize=32) 폴링
2. 수신 없으면 `SpinWait(10)` (busy-wait)
3. 각 패킷:
   - EtherType 0x0800 확인 → IPv4 파싱 → Protocol 17 확인 → UDP 파싱
   - **필터 적용**: `FilterPort`, `FilterIp`
   - 페이로드 ASCII 추출
   - `PacketQueue` (ConcurrentQueue, 최대 10,000개)에 `RxPacketInfo` 저장
4. Mbuf 해제 (finally 블록)

#### 8.2.3 DpdkEchoEngine — DPDK UDP 에코

**특징**: 제로카피 — 수신 Mbuf를 재활용하여 바로 송신 (새 할당 없음)
- MAC 스왑, IP 스왑, Port 스왑 → IP 체크섬 재계산 → TX burst

#### 8.2.4 DpdkUdpReqRespEngine — DPDK UDP Request/Response

가장 복잡한 엔진으로, ARP 프로토콜 구현과 두 가지 동작 모드를 포함.

**초기화 시퀀스**:
1. **CPU 코어 고정**: `SetThreadAffinityMask`로 코어 1에 고정
2. **ARP 자동 탐색**: DstMac이 00:...:00 또는 FF:...:FF이면 ARP Request 전송
3. **Gratuitous ARP**: 3회 반복
4. **템플릿 패킷 생성**: GCHandle.Pinned로 고정
5. **NIC/DMA 워밍업**: 더미 64패킷 전송 + RX drain

**동기 모드** (WindowSize ≤ 1): `shim_reqresp_once`
**파이프라인 모드** (WindowSize > 1): `shim_reqresp_batch`

---

## 9. DpdkNet — Stats 레이어

### 9.1 PerformanceCounter (`DpdkNet.Stats`)

**원자적 카운터** (`Interlocked`):
```
_txPackets, _rxPackets, _txBytes, _rxBytes, _errors, _dropped
```

**인터페이스**:
```csharp
AddTx(packets, bytes)   // 엔진에서 TX 기록
AddRx(packets, bytes)   // 엔진에서 RX 기록
TakeSnapshot()          // 현재 시점 스냅샷 (초당 변화량 계산)
Reset()                 // 전체 초기화
```

**피크 추적**: `PeakTxPps`, `PeakRxPps`, `PeakTxMbps`, `PeakRxMbps`

### 9.2 RttStats (`DpdkNet.Stats`)

Req/Resp 전용 RTT 통계. **Lock-free CAS 알고리즘**.

**카운터**: `Sent`, `Received`, `Timeouts`, `RxOther`
**RTT 통계**: `MinRtt`, `MaxRtt`, `AvgRtt`, `StdDev` (ms)

```csharp
// double을 int64 비트로 변환하여 CAS 수행
do {
    oldBits = Interlocked.Read(ref _minRttBits);
    if (rttMs >= BitConverter.Int64BitsToDouble(oldBits)) break;
    newBits = BitConverter.DoubleToInt64Bits(rttMs);
} while (Interlocked.CompareExchange(ref _minRttBits, newBits, oldBits) != oldBits);
```

---

## 10. Dpdk_Test_Tool — App Core

### 10.1 AppSettings.cs — JSON 프로필 설정 관리

**네임스페이스**: `DpdkTestTool.Core`

#### 설정 필드
| 카테고리 | 필드 | 기본값 | 설명 |
|----------|------|--------|------|
| EAL | `CoreMask` | `"0"` | DPDK 코어 마스크 |
| EAL | `Memory` | `"512"` | 할당 메모리(MB) |
| EAL | `LogLevel` | `"*:error"` | DPDK 로그 레벨 |
| EAL | `PortId` | `0` | 기본 포트 ID |
| EAL | `MbufPoolSize` | `8191` | Mbuf 풀 크기 |
| EAL | `LinkSpeed` | `0` | 0=Auto, 1=10M, 2=100M, 3=1G, 4=10G |
| TX | `DstMac` | `"FF:FF:FF:FF:FF:FF"` | 목적지 MAC |
| TX | `DstIp` | `"192.168.0.1"` | 목적지 IP |
| TX | `DstPort` | `5000` | 목적지 포트 |
| TX | `SrcIp` | `"192.168.0.2"` | 소스 IP |
| TX | `SrcPort` | `4000` | 소스 포트 |
| TX | `PayloadSize` | `64` | 페이로드 크기(바이트) |
| TX | `SendRate` | `0` | PPS (0=최대속도) |
| TX | `PayloadText` | `""` | 텍스트 페이로드 |
| R/R | `ResponseTimeoutMs` | `1000` | 응답 타임아웃(ms) |
| RX | `FilterIp` | `""` | 수신 필터 IP |
| RX | `FilterPort` | `0` | 수신 필터 포트 |

#### 파일 경로
```
{실행 디렉토리}/settings/last.json     ← 자동 저장/로드
{실행 디렉토리}/settings/{프로필명}.json ← 사용자 프로필
```

---

## 11. Dpdk_Test_Tool — Export 레이어

### 11.1 PerformanceReportData.cs

HTML 리포트에 사용되는 데이터 모델:

```csharp
public class PerformanceReportData {
    DateTime GeneratedAt;
    ComparisonData? Dpdk, Socket;           // 성능 비교 데이터
    List<TimeSeriesPoint> DpdkTimeSeries, SocketTimeSeries;  // 시계열
    HwStatsData? HwStats;                   // DPDK HW 통계
    SystemInfoData? SystemInfo;             // PC 사양
    TestConfigData? TestConfig;             // 테스트 설정
}

public class SystemInfoData {
    string OsVersion, MachineName, ProcessorName;
    int ProcessorCount;
    double TotalRamGB;
}

public class TestConfigData {
    string DstIp, SrcIp, DstMac, PayloadText;
    int DstPort, SrcPort, PayloadSize, SendRate, TimeoutMs, RepeatCount, WindowSize;
}

public class ComparisonData {
    double AvgPps, PeakPps, AvgRtt, MinRtt, MaxRtt, StdDevRtt;
    long Sent, Received, Timeouts;
    double ElapsedSec;
}

public class TimeSeriesPoint {
    string Time; double TxPps, RxPps, TxMbps, RxMbps;
    long TxPackets, RxPackets, Errors, Dropped;
}

public class HwStatsData {
    long Ipackets, Opackets, Ibytes, Obytes, Imissed, Ierrors, Oerrors, RxNombuf;
}
```

### 11.2 HtmlReportGenerator.cs

**성능 비교 HTML 리포트 생성기**:
- `Generate(PerformanceReportData)` → 완전한 HTML 문자열 반환
- 다크 테마 CSS, Chart.js 인라인 포함 (자체 완결형 HTML)
- 섹션 구성:
  1. **헤더** — 제목 + 생성 시간
  2. **테스트 환경** — PC 사양 (이름, OS, CPU, 코어, RAM) + 테스트 설정 (IP, 포트, 페이로드, 전송률, 타임아웃, 전송 횟수)
  3. **성능 비교 요약** — DPDK vs Socket 테이블
  4. **차트** — Chart.js 시계열 (PPS, Mbps)
  5. **히스토리 테이블** — 시점별 상세 데이터
  6. **HW 통계** — DPDK NIC 카운터

**PC 사양 수집** (`PerformanceTab.CollectSystemInfo`):
- CPU 이름: `Registry.LocalMachine\HARDWARE\DESCRIPTION\System\CentralProcessor\0\ProcessorNameString`
- RAM: `GC.GetGCMemoryInfo().TotalAvailableMemoryBytes`

---

## 12. Dpdk_Test_Tool — Socket/TCP 엔진

### 12.1 Socket 엔진 5종

**파일**: `Engine/SocketUdpEngine.cs` (하나의 파일에 5개 클래스)

| 엔진 | 핵심 동작 |
|------|-----------|
| `SocketUdpTxEngine` | `Socket.SendTo` + Stopwatch PPS 제한 + 응답 폴링 |
| `SocketUdpRxEngine` | `Socket.ReceiveFrom` (Timeout=100ms) + IP 필터 |
| `SocketEchoEngine` | `ReceiveFrom` → `SendTo` (동일 데이터) |
| `SocketUdpServerEngine` | 수신 + 자동 응답 + 수동 전송 큐 |
| `SocketUdpReqRespEngine` | 동기식 Send→Receive + Stopwatch RTT + RttStats |

### 12.2 TCP 엔진 2종

| 엔진 | 핵심 동작 |
|------|-----------|
| `TcpClientEngine` | async/await 비동기 TCP, `ConnectAsync` → `ReceiveLoopAsync` |
| `TcpServerEngine` | `TcpListener` 다중 클라이언트, Echo/ReceiveOnly 모드 |

---

## 13. UI 레이어

### 탭 구성 (5개)

```
┌────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│ DPDK UDP   │ Socket UDP   │ TCP 테스트    │ 성능 모니터   │ DPDK 설정    │
├────────────┴──────────────┴──────────────┴──────────────┴──────────────┤
│  [탭 콘텐츠 영역]                                                       │
└──────────────────────────────────────────────────────────────────────────┘
```

### 13.1 MainForm
- 700×700, 5개 탭 호스트
- 설정 연동: `CollectAllSettings` / `ApplyAllSettings`
- 재시작: 관리자 권한(`runas`)으로 재시작
- 종료: 설정 저장 → 엔진 정지 → DPDK Cleanup

### 13.2 DpdkUdpTab
- **모드 4종**: TX, RX, Echo, Req/Resp
- UI 타이머 200ms, 로그 5,000줄 제한
- ReqResp 완료 시 자동 정지

### 13.3 SocketUdpTab
- **모드 5종**: TX, RX, Echo, Server, Req/Resp
- DstMac 불필요, DPDK 초기화 없이 사용 가능

### 13.4 TcpTestTab
- **모드 2종**: Server, Client
- 자동 전송 (200ms 간격) 체크박스

### 13.5 PerformanceTab
- DPDK HW 통계, 링크 상태, 실시간 성능 (DPDK + Socket 나란히)
- 성능 비교 테이블 (7항목), 자동/수동 캡처
- 세션 히스토리 (최대 500개)
- **HTML 리포트 내보내기** — PC 사양 + 테스트 설정 포함

### 13.6 SettingsTab
- **EAL 파라미터**: Core Mask, Memory, Log Level
- **CPU 사용량 모니터**:
  - "CPU 확인" 버튼 → 코어별 CPU 사용률 패널 토글
  - `PerformanceCounter("Processor Information", "% Processor Utility")` 사용 (1초 샘플링)
  - 색상 코딩: `<15%` 여유(추천), `<50%` 보통, `<80%` 높음, `>=80%` 과부하
  - "선택 적용" 버튼: 선택한 코어 → CoreMask 자동 입력
- **포트 설정**: Port ID, Mbuf Pool Size, Link Speed
- **프로필 관리**: 저장/불러오기/삭제
- **초기화 제어**: DPDK 초기화, 재시작, 상태 표시
- **DPDK 정보**: 버전, MAC, 활성 포트 선택

---

## 14. 패킷 구성 및 전송 흐름

### DPDK TX 패킷 구성 흐름

```
1. shim_pktmbuf_alloc(pool)     → Mbuf 할당
2. shim_pktmbuf_append(mbuf, N) → N바이트 데이터 공간 확보
3. shim_pktmbuf_mtod(mbuf)      → 데이터 시작 포인터
4. Marshal.StructureToPtr(eth)  → Ethernet 헤더 (14B)
5. Marshal.StructureToPtr(ip)   → IPv4 헤더 (20B)
6. Marshal.StructureToPtr(udp)  → UDP 헤더 (8B)
7. Marshal.WriteByte(payload)   → 페이로드
8. shim_tx_burst(port, 0, mbufs, N) → 배치 전송
```

### 패킷 메모리 레이아웃

```
offset  0: +--[Ethernet Header (14B)]--+
offset 14: +--[IPv4 Header (20B)]------+
offset 34: +--[UDP Header (8B)]--------+
offset 42: +--[Payload (N B)]----------+
총 크기: 42 + PayloadSize 바이트
```

---

## 15. ARP 프로토콜 구현

`DpdkUdpReqRespEngine` (DpdkNet)에 구현. DPDK는 커널 바이패스이므로 ARP 직접 처리.

### 15.1 ARP Request (`ResolveDestMac`)
- 트리거: DstMac이 00:...:00 또는 FF:...:FF
- 최대 3회 시도, 1초간 RX 폴링

### 15.2 Gratuitous ARP
- 3회 반복 (100ms 간격), 상대 ARP 캐시 등록

### 15.3 Proxy ARP
- 수신 중 모든 ARP Request에 응답

### 15.4 바이트 오더 주의사항
```csharp
HardwareType = 0x0100,  // 0x0001 Big Endian
ProtocolType = 0x0008,  // 0x0800 Big Endian
EtherType = 0x0608      // 0x0806 Big Endian
```

---

## 16. 스레딩 모델 및 동기화

### 스레드 구성

| 스레드 | 우선순위 | 프로젝트 | 역할 |
|--------|----------|----------|------|
| UI Thread | Normal | Dpdk_Test_Tool | WinForms 이벤트 루프 |
| DPDK-TX | Highest | DpdkNet | TX 송신 |
| DPDK-RX | Highest | DpdkNet | RX 수신 |
| DPDK-Echo | Highest | DpdkNet | 에코 루프 |
| DPDK-ReqResp | Highest | DpdkNet | Req/Resp + ARP |
| PktLog-* | BelowNormal | DpdkNet | CSV 패킷 로깅 |
| Socket-UDP-* | Highest | Dpdk_Test_Tool | Socket 엔진들 |

### 동기화 메커니즘

| 메커니즘 | 사용처 | 용도 |
|----------|--------|------|
| `volatile bool _running` | 모든 엔진 | 정지 신호 |
| `Interlocked.Add/Read` | PerformanceCounter | Lock-free 카운터 |
| `Interlocked.CompareExchange` | RttStats | Lock-free CAS |
| `ConcurrentQueue<T>` | 엔진↔UI | Producer-Consumer |
| `lock (_lock)` | DpdkManager | 초기화/클린업 직렬화 |
| `Control.Invoke` | UI 탭 | 크로스스레드 UI |

### CPU 코어 고정 (ReqResp 전용)
```csharp
IntPtr mask = new IntPtr(1 << 1); // 코어 1에 고정
SetThreadAffinityMask(GetCurrentThread(), mask);
```

---

## 17. 에러 처리 및 클린업

### 에러 처리 계층
1. **SEH** — dpdk_shim.dll 네이티브 크래시 보호
2. **C# 예외** — DpdkManager, 엔진 루프 try/catch
3. **P/Invoke** — 반환값/IntPtr.Zero 확인

### 리소스 클린업 순서
```
앱 종료: AppSettings.Save → 엔진 Stop → DpdkManager.Cleanup
DpdkManager.Cleanup: dev_stop/close → eal_cleanup → 메모리 해제 → CleanedUp
```

### 큐 오버플로 방지
- PacketQueue/ResponseQueue/ResultQueue: 10,000개
- LogQueue: 5,000개
- RichTextBox: 5,000줄 초과 시 초기화
- ListView History: 500개 초과 시 제거

---

## 부록: 주요 상수

| 상수 | 값 | 사용처 |
|------|-----|--------|
| Mbuf Pool Cache | 256 | DpdkManager |
| Mbuf Data Room | 2176B (2048+128) | DpdkManager |
| RX/TX Batch Size | 32 | 모든 DPDK 엔진 |
| SpinWait Count | 10 | RX 유휴 시 |
| UI Timer Interval | 200ms | DpdkUdpTab, SocketUdpTab |
| Perf Timer Interval | 1000ms | PerformanceTab |
| TCP UI Timer | 300ms | TcpTestTab |
| Max Log Lines | 5,000 | RichTextBox 로그 |
| Max Queue Size | 10,000 | 패킷/결과 큐 |
| Warmup Packets | 64 | ReqResp 워밍업 |
| Gratuitous ARP Count | 3 | ReqResp 시작 시 |
| ARP Retry Count | 3 | MAC 탐색 |
| Link Wait Max | 10초 | DpdkManager 초기화 |
| Thread Join Timeout | 2,000~3,000ms | 엔진 Stop |
| Socket Buffer Size | 1MB | Socket 엔진 |
| IPv4 TTL | 64 | 패킷 구성 |
| UDP Checksum | 0 (비활성) | DPDK TX |
| CSV Flush Interval | 1,000ms | PacketLogger |
| CSV Batch Size | 10,000 | PacketLogger |
