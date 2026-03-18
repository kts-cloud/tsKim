# Windows DPDK 안전 설정 및 복구 가이드

> **목적**: DPDK 환경 설정 시 부팅 불가 등 치명적 문제를 예방하고, 문제 발생 시 복구하기 위한 종합 가이드

---

## 1. 사전 준비 체크리스트

설정을 시작하기 전에 아래 항목을 **반드시** 확인하세요.

### BIOS 설정

| 항목 | 필수 상태 | 확인 방법 | 위험 |
|------|----------|----------|------|
| **Secure Boot** | **OFF (Disabled)** | BIOS → Security → Secure Boot | ON + TestSigning → **부팅 불가** |
| VT-d / IOMMU | ON (권장) | BIOS → Advanced → VT-d | DPDK 성능 관련 |
| Hyper-V | OFF (권장) | BIOS 또는 Windows 기능 | DPDK와 충돌 가능 |

### 하드웨어 확인

| 항목 | 요구사항 | 비고 |
|------|---------|------|
| NIC 타입 | **PCI/PCIe 기반** | USB NIC는 DPDK 미지원 |
| 네트워크 어댑터 | 최소 2개 | 1개는 관리용(인터넷), 1개는 DPDK용 |
| 메모리 | 8GB 이상 권장 | Hugepages 사용을 위해 |

### 소프트웨어 확인

- [ ] Windows 10/11 Pro 이상 (Home 에디션은 gpedit.msc 미지원)
- [ ] 관리자 계정으로 로그인
- [ ] Windows 업데이트 최신 상태
- [ ] 중요 데이터 백업 완료

---

## 2. 단계별 설정 절차

### 설정 순서도

```
[BIOS 설정 확인]
    ↓ Secure Boot OFF 확인
[setup_new_pc_master.ps1 실행]
    ↓ Chocolatey, VS Build Tools, LLVM, WDK 설치
    ↓ SeLockMemory 권한 부여
    ↓ BCD 백업 → TestSigning ON
    ↓
[재부팅]
    ↓
[setup_dpdk_windows.ps1 실행]
    ↓ DPDK 소스 클론, Meson/Ninja 빌드
    ↓
[build_shim.ps1 실행]
    ↓ dpdk_shim.dll 생성
    ↓
[install_netuio_complete.ps1 실행]
    ↓ 안전 검증 → 복원 지점 → 인증서 → 서명 → 드라이버 설치
    ↓
[NIC 바인딩]
    ↓ toggle_netuio.ps1 또는 장치 관리자
    ↓
[테스트 실행]
    ↓ run_echo.ps1 또는 C# 앱 실행
```

### 2.1 기본 환경 설치

```powershell
# 관리자 PowerShell에서 실행
cd D:\DPDK\01_Windows
.\setup_new_pc_master.ps1

# 단계별 확인이 필요하면 Interactive 모드 사용
.\setup_new_pc_master.ps1 -Interactive
```

**이 단계에서 수행되는 것:**
- Chocolatey 패키지 관리자 설치
- Git, Python, LLVM(Clang), VS2022 Build Tools, WDK 설치
- `SeLockMemoryPrivilege` 권한 부여 (Hugepages용)
- **BCD 백업** → TestSigning 활성화

**⚠️ 주의사항:**
- Secure Boot가 ON이면 스크립트가 자동 중단됨
- BCD 백업 파일 위치: `01_Windows\_backup_system\bcd_backup_*.bak`
- **반드시 재부팅 필요**

### 2.2 DPDK 빌드

```powershell
# 재부팅 후
.\setup_dpdk_windows.ps1
.\build_shim.ps1
```

### 2.3 netuio 드라이버 설치

```powershell
.\install_netuio_complete.ps1

# 안전 검증을 건너뛰려면 (비권장)
.\install_netuio_complete.ps1 -Force
```

**이 단계의 안전 장치:**
1. Secure Boot 상태 확인 → ON이면 중단
2. TestSigning 활성화 확인
3. 시스템 복원 지점 생성
4. NIC 드라이버 정보 백업 (`01_Windows\_backup_netuio\`)
5. 기존 인증서 정리 후 재생성
6. 타임스탬프 서버 장애 시 자동 Fallback (4개 서버)
7. 설치 실패 시 자동 롤백 (인증서·카탈로그 정리)
8. 설치 후 드라이버 등록 검증

### 2.4 NIC 바인딩

```powershell
.\toggle_netuio.ps1
```

---

## 3. 각 단계별 위험 요소

| 단계 | 위험 요소 | 결과 | 대응 |
|------|----------|------|------|
| TestSigning 활성화 | Secure Boot ON 상태에서 실행 | **부팅 불가** | Secure Boot OFF 후 실행 |
| 인증서 생성 | 중복 인증서로 인한 서명 충돌 | 드라이버 로드 실패 | 자동 정리 후 재생성 |
| 드라이버 서명 | 타임스탬프 서버 장애 | 서명 실패 | 4개 서버 자동 Fallback |
| pnputil 설치 | INF에 잘못된 HW ID | 관리 NIC가 netuio로 교체 | NIC 백업으로 확인·복구 |
| NIC 바인딩 | 관리용 NIC에 바인딩 | 네트워크 연결 손실 | unbind 또는 장치 관리자 복구 |

---

## 4. 부팅 실패 시 복구 방법

### 방법 1: Safe Mode 복구 (권장)

Safe Mode로 부팅 가능한 경우 가장 간편합니다.

**Safe Mode 진입:**
1. PC 전원 ON → Windows 로고 나타날 때 전원 버튼 길게 눌러 강제 종료
2. 3회 반복 → "자동 복구" 화면 진입
3. **문제 해결** → **고급 옵션** → **시작 설정** → **다시 시작**
4. **4번** (안전 모드) 또는 **5번** (네트워킹 포함 안전 모드) 선택

**복구 스크립트 실행:**
```powershell
# Safe Mode에서 관리자 PowerShell 열기
cd D:\Dongaeltek\_Project\05_DPDK\01_Windows
.\recovery_dpdk.ps1
```

### 방법 2: WinRE 명령 프롬프트 복구

Safe Mode로도 진입 불가한 경우입니다.

**WinRE 진입:**
1. 강제 종료 3회 반복 → 자동 복구 환경
2. **문제 해결** → **고급 옵션** → **명령 프롬프트**

**수동 복구 명령어:**
```cmd
:: 1. TestSigning 비활성화
bcdedit /set {default} testsigning off

:: 2. Safe Mode로 부팅 설정 (정상 모드가 안 되면)
bcdedit /set {default} safeboot minimal

:: 3. 재부팅
exit
```

Safe Mode로 부팅되면 `recovery_dpdk.ps1` 실행 후:
```cmd
:: Safe Mode 해제
bcdedit /deletevalue {default} safeboot
```

### 방법 3: Windows 설치 미디어 복구

WinRE도 진입 불가한 최악의 경우입니다.

1. 다른 PC에서 Windows 설치 USB 생성 (Microsoft 공식 도구)
2. USB로 부팅
3. **컴퓨터 복구** 클릭
4. **문제 해결** → **명령 프롬프트**
5. 방법 2의 수동 복구 명령어 실행

**BCD 백업이 있는 경우:**
```cmd
:: 디스크 확인 (D:가 아닐 수 있음)
dir C:\
dir D:\
dir E:\

:: 백업 파일 찾기
dir D:\Dongaeltek\_Project\05_DPDK\01_Windows\_backup_system\

:: BCD 복원
bcdedit /import "D:\Dongaeltek\_Project\05_DPDK\01_Windows\_backup_system\bcd_backup_XXXXXXXX_XXXXXX.bak"
```

### 방법 4: 시스템 복원 사용

1. WinRE → **문제 해결** → **고급 옵션** → **시스템 복원**
2. 복원 지점 선택: "Before NetUIO Driver Install" 또는 "Before DPDK TestSigning"
3. 복원 진행 → 자동 재부팅

---

## 5. BCD 수동 복구 명령어 모음

```cmd
:: 현재 BCD 설정 확인
bcdedit /enum

:: TestSigning 비활성화
bcdedit /set {default} testsigning off

:: Safe Mode 설정/해제
bcdedit /set {default} safeboot minimal    (설정)
bcdedit /deletevalue {default} safeboot     (해제)

:: BCD 백업/복원
bcdedit /export C:\bcd_backup.bak
bcdedit /import C:\bcd_backup.bak

:: BCD 저장소 재생성 (최후 수단)
bootrec /rebuildbcd
bootrec /fixmbr
bootrec /fixboot

:: 특정 BCD 값 삭제
bcdedit /deletevalue {default} testsigning
```

---

## 6. FAQ & 트러블슈팅

### Q: "부팅 시 블루스크린(BSOD)이 발생합니다"

**가능한 원인:**
- Secure Boot ON + TestSigning → 서명 검증 실패
- netuio 드라이버가 시스템 필수 NIC에 바인딩됨

**해결:**
1. WinRE → 명령 프롬프트에서 `bcdedit /set {default} testsigning off`
2. 재부팅 → Safe Mode → `recovery_dpdk.ps1` 실행

### Q: "TestSigning ON 후 바탕화면 우하단에 워터마크가 보입니다"

정상입니다. TestSigning이 활성화되면 화면 우측 하단에 "테스트 모드" 워터마크가 표시됩니다. DPDK를 사용하지 않을 때는 `bcdedit /set testsigning off` 후 재부팅하면 사라집니다.

### Q: "install_netuio_complete.ps1에서 Secure Boot 경고가 나옵니다"

BIOS에 진입하여 Secure Boot를 비활성화하세요:
1. PC 재부팅 → BIOS 진입 (DEL, F2, 또는 F12)
2. Security → Secure Boot → Disabled
3. 저장 후 재부팅

### Q: "pnputil로 드라이버 설치 후 네트워크가 끊어졌습니다"

`pnputil /add-driver`는 드라이버 저장소에 추가만 합니다. NIC에 자동 바인딩되지는 않지만, INF의 하드웨어 ID가 시스템 NIC와 일치하면 자동 교체될 수 있습니다.

**복구:**
```powershell
# 장치 관리자 → 해당 NIC → 드라이버 업데이트 → 이전 드라이버로 롤백
# 또는
pnputil /delete-driver oem##.inf /uninstall /force
pnputil /scan-devices
```

### Q: "Hugepages 관련 오류가 발생합니다"

`SeLockMemoryPrivilege` 권한이 필요합니다:
1. `Win+R` → `gpedit.msc`
2. 컴퓨터 구성 → Windows 설정 → 보안 설정 → 로컬 정책 → 사용자 권한 할당
3. **메모리에 페이지 잠금** → 현재 사용자 추가
4. **재부팅 필요**

### Q: "recovery_dpdk.ps1이 Safe Mode에서 실행되지 않습니다"

PowerShell 실행 정책이 제한되어 있을 수 있습니다:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\recovery_dpdk.ps1
```

### Q: "bcdedit 명령이 '요소를 찾을 수 없습니다' 오류를 반환합니다"

BCD 저장소가 손상되었을 수 있습니다. 백업 파일이 있으면 복원하세요:
```cmd
bcdedit /import "path\to\bcd_backup_*.bak"
```
백업이 없으면 Windows 설치 미디어에서 `bootrec /rebuildbcd`를 시도하세요.

---

## 7. 백업 파일 위치 정리

| 파일 | 위치 | 생성 시점 |
|------|------|----------|
| BCD 백업 | `01_Windows\_backup_system\bcd_backup_*.bak` | `setup_new_pc_master.ps1` 실행 시 |
| NIC 드라이버 백업 | `01_Windows\_backup_netuio\nic_drivers_backup_*.txt` | `install_netuio_complete.ps1` 실행 시 |
| 설치 로그 | `01_Windows\_backup_netuio\install_*.log` | `install_netuio_complete.ps1` 실행 시 |
| 시스템 복원 지점 | Windows 시스템 복원 | 두 스크립트 모두 |

---

## 8. 스크립트 요약

| 스크립트 | 용도 | 주요 옵션 |
|---------|------|----------|
| `setup_new_pc_master.ps1` | 새 PC 전체 환경 설정 | `-Interactive` |
| `install_netuio_complete.ps1` | netuio 드라이버 설치 | `-Force` |
| `recovery_dpdk.ps1` | DPDK 설정 전체 롤백 | - |
| `toggle_netuio.ps1` | NIC ↔ netuio 바인딩 전환 | - |
| `setup_dpdk_windows.ps1` | DPDK 소스 빌드 | - |
| `build_shim.ps1` | dpdk_shim.dll 빌드 | - |
| `run_echo.ps1` | Echo 서버 실행 | - |
