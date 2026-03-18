# DPDK Windows Setup UI Tool - 구현 계획

## Context

현재 DPDK 환경 설정은 21개의 PowerShell/Batch 스크립트를 특정 순서로 실행해야 합니다. 문제점:
- 하드코딩된 WDK 버전 경로 (`10.0.26100.0`, `10.0.22621.0`)
- 하드코딩된 프로젝트 경로 (`D:\DPDK\01_Windows`)
- WDK choco 설치 자주 실패 (무시됨)
- 사전 검증 부재 (디스크 공간, RAM, Windows 에디션, Hyper-V 충돌)
- secedit 결과 미검증, 스크립트 간 의존성 미문서화

**목표**: 단일 C# WinForms 마법사 앱으로 전체 프로세스를 안내, 검증, 자동화

## 생성 폴더/파일

```
D:\DPDK\01_Windows\Dpdk_Setup_Tool\
├── Dpdk_Setup_Tool.csproj
├── app.manifest                    # requireAdministrator UAC
├── Program.cs
├── SetupWizardForm.cs              # 메인 마법사 폼
├── Steps/
│   ├── ISetupStep.cs               # 스텝 인터페이스 + StepStatus enum
│   ├── SetupStepBase.cs            # 공통 기반 클래스
│   ├── SystemCheckStep.cs          # 0. 시스템 사전 점검
│   ├── SoftwareInstallStep.cs      # 1. 소프트웨어 설치
│   ├── SystemConfigStep.cs         # 2. 시스템 설정 (재부팅 필요)
│   ├── DpdkBuildStep.cs            # 3. DPDK 소스 빌드
│   ├── ShimBuildStep.cs            # 4. dpdk_shim.dll 빌드
│   ├── DriverInstallStep.cs        # 5. netuio/virt2phys 드라이버
│   ├── NicBindingStep.cs           # 6. NIC 바인딩
│   └── DeployVerifyStep.cs         # 7. 배포 & 검증
├── Utils/
│   ├── ProcessRunner.cs            # 외부 프로세스 실행 + 실시간 출력
│   ├── SystemInfo.cs               # 시스템 정보 조회 (WMI, 레지스트리)
│   ├── WdkLocator.cs               # WDK 동적 경로 탐색
│   ├── NicDetector.cs              # NIC 열거 + DPDK 지원 판별
│   └── SetupState.cs               # JSON 상태 저장 (재부팅 복원용)
├── Controls/
│   ├── StepListPanel.cs            # 좌측 스텝 목록 패널
│   ├── LogPanel.cs                 # 컬러 로그 출력 (RichTextBox)
│   └── ChecklistPanel.cs          # 체크리스트 (Step 0용)
└── plan.md                         # 이 계획 문서
```

총 19개 소스 파일 + plan.md

## UI 레이아웃

```
+-------------------------------------------------------+
| DPDK Windows Setup Tool              [최소화] [닫기]   |
+------------+------------------------------------------+
|            |                                          |
| 스텝 목록   |   현재 스텝 콘텐츠 패널                    |
| (200px)    |   (스텝별 교체)                           |
|            |                                          |
|  ● 시스템  |   ┌─ 설명 라벨 ─────────────────────┐    |
|  ○ 설치    |   │ 현재 스텝의 상세 UI               │    |
|  ○ 설정    |   │ (체크리스트 / 진행바 / 선택 등)    │    |
|  ○ DPDK   |   └────────────────────────────────┘    |
|  ○ Shim   |   ┌─ 로그 패널 ─────────────────────┐    |
|  ○ 드라이버|   │ [10:15:01] EAL 초기화 완료        │    |
|  ○ NIC    |   │ [10:15:02] 포트 설정 완료          │    |
|  ○ 배포    |   └────────────────────────────────┘    |
|            |   [▶ 실행] [⏭ 건너뛰기] [■ 취소]       |
+------------+------------------------------------------+
| [=============================        ] Step 3/7: ... |
+-------------------------------------------------------+
```

## 각 스텝 상세

### Step 0: 시스템 사전 점검 (SystemCheckStep.cs)

기존 스크립트의 산재된 검증을 통합. ChecklistPanel에 결과 표시.

| 점검 항목 | 소스 | 방법 |
|----------|------|------|
| 관리자 권한 | 모든 스크립트 | app.manifest로 자동 보장 |
| Windows 에디션 (Pro/Enterprise) | 신규 | Registry `EditionID` |
| Secure Boot OFF | `setup_new_pc_master.ps1` | PS `Confirm-SecureBootUEFI` |
| Hyper-V 비활성화 | 신규 | PS `Get-WindowsOptionalFeature` |
| 디스크 공간 ≥ 20GB | 신규 | `DriveInfo.AvailableFreeSpace` |
| RAM ≥ 8GB | 신규 | WMI `Win32_PhysicalMemory` |
| 도구 존재: git, python, clang, meson, ninja, dotnet | `setup_dpdk_windows.ps1` | PATH 검색 |
| WDK 설치 여부 | `install_netuio_complete.ps1` | `WdkLocator.IsInstalled()` |
| TestSigning 상태 | `install_netuio_complete.ps1:121` | `bcdedit /enum` 파싱 |
| SeLockMemoryPrivilege | `setup_new_pc_master.ps1:111` | `secedit /export` 파싱 |

### Step 1: 소프트웨어 설치 (SoftwareInstallStep.cs)

소스: `setup_new_pc_master.ps1`, `setup_x550_oneclick.ps1`

서브스텝 (각각 개별 진행):
1. **Chocolatey** — `choco` 없으면 설치 (`setup_new_pc_master.ps1:78`)
2. **git, python, llvm** — `choco install git python llvm -y`
3. **VS2022 Build Tools** — `choco install visualstudio2022buildtools -y --package-parameters "..."` (`setup_new_pc_master.ps1:96`)
4. **WDK** — 3단계 fallback:
   - `choco install windows-driver-kit -y` (자주 실패)
   - `winget install -e --id Microsoft.WindowsDriverKit`
   - 수동 다운로드 링크 표시 + "설치 완료" 버튼
5. **Python 패키지** — `pip install meson ninja pyelftools`
6. **.NET SDK** — `choco install dotnet-sdk -y`

각 설치 후 PATH 재로드: `SystemInfo.ReloadEnvironmentPath()` (Machine+User PATH 재읽기)

### Step 2: 시스템 설정 (SystemConfigStep.cs)

소스: `setup_new_pc_master.ps1:Configure-System-Settings`

1. **SeLockMemoryPrivilege** — `secedit /export` → 수정 → `secedit /configure /areas USER_RIGHTS` (`setup_new_pc_master.ps1:111-133`)
2. **시스템 복원 지점** — `Checkpoint-Computer` (실패 시 비치명적)
3. **BCD 백업** — `bcdedit /export <경로>` → 경로를 SetupState에 저장
4. **TestSigning 활성화** — Secure Boot OFF 재확인 → `bcdedit /set testsigning on`
5. **재부팅 안내** — "재부팅 필요" 배너 + [지금 재부팅] / [나중에] 버튼

재부팅 처리:
- SetupState에 `CurrentStep = 3` 저장
- `HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce`에 `--resume` 등록
- `shutdown /r /t 10`

### Step 3: DPDK 소스 빌드 (DpdkBuildStep.cs)

소스: `setup_dpdk_windows.ps1`

1. **도구 확인** — python, clang, meson, ninja PATH 검증
2. **DPDK 클론** — `dpdk-src/` 없으면 `git clone http://dpdk.org/git/dpdk dpdk-src`
3. **Meson 설정** — `CC=clang`, `meson setup build --default-library=shared`
4. **Ninja 빌드** — `ninja -C build` (15-30분)
   - 실시간 출력 스트리밍
   - `[123/4567]` 패턴 파싱으로 진행률 표시
   - 취소 버튼 (Process.Kill)

```csharp
// ninja 진행률 파싱
var match = Regex.Match(line, @"\[(\d+)/(\d+)\]");
if (match.Success) {
    int percent = 100 * int.Parse(match.Groups[1].Value) / int.Parse(match.Groups[2].Value);
    progressUpdate(percent);
}
```

### Step 4: Shim DLL 빌드 (ShimBuildStep.cs)

소스: `build_shim.ps1`

1. **DPDK 빌드 확인** — `dpdk-src/build/build.ninja` 존재 확인
2. **WDK lib 경로 동적 탐색** — `WdkLocator.FindLibPath()` (하드코딩 `10.0.26100.0` 대체)
3. **include 경로 동적 탐색** — `dpdk-src/lib/` 재귀 스캔 (`build_shim.ps1:24-26`과 동일)
4. **clang 컴파일** — `-shared -m64 -march=native -mssse3` + 동적 경로
5. **결과 확인** — `dpdk_shim.dll` 파일 존재 + 크기 표시

핵심: `build_shim.ps1:57`의 하드코딩 경로를 동적 탐색으로 대체:
```
Before: C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64
After:  WdkLocator.FindLibPath() → 최신 버전 자동 선택
```

### Step 5: 드라이버 설치 (DriverInstallStep.cs)

소스: `install_netuio_complete.ps1` (386줄), `install_virt2phys.ps1` (183줄)

가장 복잡한 스텝. 기존 스크립트의 안전 장치를 모두 보존:

1. **사전 점검** — admin, Secure Boot OFF, TestSigning ON, `netuio.sys`+`netuio.inf` 존재
2. **안전 조치** — 복원 지점 + NIC 드라이버 정보 백업 (`_backup_netuio/`)
3. **WDK 도구 탐색** — `WdkLocator.FindTool("Inf2Cat.exe", "x86")`, `FindTool("signtool.exe", "x64")`
4. **카탈로그 생성** — `Inf2Cat /driver:"..." /os:10_X64`
5. **인증서 관리** — 기존 DPDK 인증서 제거 → `New-SelfSignedCertificate` (5년) → Root+TrustedPublisher 등록
6. **드라이버 서명** — 4개 타임스탬프 서버 순차 시도 (DigiCert → Sectigo → GlobalSign → Symantec)
7. **pnputil 설치** — `pnputil /add-driver netuio.inf /install` (exit code 259 = 정상)
8. **검증** — `pnputil /enum-drivers | grep netuio`

실패 시 롤백: 인증서 제거 + .cer/.cat 삭제 (`install_netuio_complete.ps1:296-306`)

옵션: virt2phys 설치 체크박스 (동일 패턴 + `devcon install Root\virt2phys`)

### Step 6: NIC 바인딩 (NicBindingStep.cs)

소스: `toggle_x550.ps1`, `toggle_i226.ps1`, `toggle_netuio.ps1`

3개 토글 스크립트를 통합하는 범용 바인딩 UI:

1. **NIC 자동 감지** — `NicDetector.EnumerateNicsAsync()`
   - `Get-PnpDevice` + WMI `Win32_NetworkAdapter` 결합
   - `netuio.inf` 파싱으로 DPDK 지원 HW ID 목록 동적 구축
2. **NIC 테이블 표시** (DataGridView):
   ```
   | 이름              | Hardware ID          | 현재 드라이버 | DPDK 지원 | 상태 |
   | Intel X550-AT2    | VEN_8086&DEV_1563   | ixgbe        | ✓         | Net  |
   | Intel I226-V      | VEN_8086&DEV_125C   | e1g68x64     | ✓         | Net  |
   ```
3. **바인딩** — devcon 동적 탐색 (`WdkLocator.FindTool("devcon.exe")`) + fallback pnputil
4. **언바인딩** — netuio OEM INF 열거 → `pnputil /delete-driver /uninstall /force`
5. **검증** — `Get-PnpDevice | Where Class -eq "Windows UIO"`

지원 NIC (netuio.inf에서 파싱):
- Intel X550: `VEN_8086&DEV_1563` (주 대상)
- Intel I226-V: `VEN_8086&DEV_125C`
- Intel X710/XL710: `DEV_1572-1589`
- Intel E810: `DEV_1591-159B`
- Realtek USB: `VID_0BDA&PID_8152` (제한적)
- VMware vmxnet3: `VEN_15AD&DEV_07B0`

### Step 7: 배포 & 검증 (DeployVerifyStep.cs)

소스: `copy_dlls.ps1`, `build_diag.ps1`

대상 프로젝트: `Dpdk_Test_Tool` (유일한 테스트 SW)

1. **DLL 복사** — `Dpdk_Test_Tool.csproj`의 `<TargetFramework>` 파싱으로 출력 경로 동적 결정
   - `dpdk-src/build/lib/*.dll` + `dpdk-src/build/drivers/*.dll` + `dpdk_shim.dll`
   - 대상: `Dpdk_Test_Tool/bin/Debug/<tfm>/` 디렉토리
2. **dpdk_diag.exe 빌드** — `build_diag.ps1` 스크립트 로직으로 진단 도구 빌드
3. **Dpdk_Test_Tool 빌드** — `dotnet build Dpdk_Test_Tool/Dpdk_Test_Tool.csproj --configuration Debug`
4. **진단 실행** — `dpdk_diag.exe` 실행, SUCCESS/CRASH 결과 표시
5. **완료 요약** — 전체 성공/실패 요약

## 핵심 유틸리티 클래스

### ProcessRunner.cs — 프로세스 실행 엔진

```csharp
public static class ProcessRunner
{
    // 프로세스 실행 + 실시간 stdout/stderr 스트리밍
    public static async Task<ProcessResult> RunAsync(
        string fileName, string arguments,
        string? workingDirectory = null,
        Action<string>? onOutputLine = null,    // 줄 단위 콜백
        Action<string>? onErrorLine = null,
        CancellationToken ct = default,
        Dictionary<string, string>? envVars = null);

    // PowerShell 명령 실행 헬퍼
    public static Task<ProcessResult> RunPowerShellAsync(
        string command, ...);
}
```
- `Process.BeginOutputReadLine()` + `OutputDataReceived` 이벤트로 비동기 스트리밍
- `CancellationToken` → `Process.Kill()` 연동
- 모든 스텝에서 사용하는 핵심 유틸리티

### WdkLocator.cs — WDK 동적 경로 탐색

하드코딩 경로 3곳을 모두 대체:

| 기존 하드코딩 | 대체 메서드 |
|-------------|-----------|
| `build_shim.ps1:57` — `Lib\10.0.26100.0\um\x64` | `FindLibPath("x64")` |
| `toggle_netuio.ps1:29` — `Tools\10.0.22621.0\x64\devcon.exe` | `FindTool("devcon.exe")` |
| `install_netuio_complete.ps1` — Inf2Cat, signtool | `FindTool("Inf2Cat.exe", "x86")` |

```csharp
public static class WdkLocator
{
    // C:\Program Files (x86)\Windows Kits\10\ 하위 버전 스캔
    public static string? FindTool(string toolName, string arch = "x64");
    public static string? FindLibPath(string arch = "x64");
    public static bool IsInstalled();
    public static string[] GetInstalledVersions();
}
```

### NicDetector.cs — NIC 열거 + DPDK 지원 판별

```csharp
public class NicInfo
{
    public string FriendlyName { get; init; }
    public string HardwareId { get; init; }
    public string CurrentDriver { get; init; }
    public string DeviceClass { get; init; }      // "Net" or "Windows UIO"
    public bool IsDpdkSupported { get; init; }     // netuio.inf에서 파싱
    public bool IsBoundToNetuio => DeviceClass == "Windows UIO";
}

public static class NicDetector
{
    // netuio.inf 파싱으로 지원 HW ID 로드 (런타임)
    public static void LoadSupportedIds(string netuioInfPath);
    // 전체 NIC 열거
    public static async Task<List<NicInfo>> EnumerateNicsAsync();
}
```

### SetupState.cs — 재부팅 복원용 상태

```csharp
public class SetupState
{
    public int CurrentStep { get; set; }
    public Dictionary<int, StepStatus> StepStatuses { get; set; }
    public string ProjectRoot { get; set; }
    public string? WdkPath { get; set; }
    public string? BcdBackupPath { get; set; }
    public List<string> BoundNicInstanceIds { get; set; }

    public void Save();               // setup_state.json
    public static SetupState Load();
}
```

## 기존 스크립트에서 발견된 문제점 및 해결

| 문제 | 스크립트 | 해결 |
|------|---------|------|
| WDK 버전 하드코딩 (`10.0.26100.0`) | `build_shim.ps1:57` | `WdkLocator.FindLibPath()` 동적 탐색 |
| devcon 경로 하드코딩 (`10.0.22621.0`) | `toggle_netuio.ps1:29` | `WdkLocator.FindTool()` 동적 탐색 |
| 절대 경로 하드코딩 (`D:\DPDK\01_Windows`) | `copy_dlls.ps1` 전체 | `AppDomain.BaseDirectory` 기반 상대 경로 |
| WDK choco 자주 실패 | `setup_new_pc_master.ps1` | choco → winget → 수동 3단계 fallback |
| 디스크/RAM 미검증 | 전체 | Step 0에서 사전 점검 |
| Windows 에디션 미검증 | 전체 | Step 0에서 Pro/Enterprise 확인 |
| Hyper-V 충돌 미검증 | 전체 | Step 0에서 Hyper-V 비활성화 확인 |
| secedit 결과 미검증 | `setup_new_pc_master.ps1` | 적용 후 재export로 검증 |
| 인증서 만료 미경고 | `install_netuio_complete.ps1` | 6개월 이내 만료 시 경고 표시 |
| dpdk-src 유효성 미검증 | `setup_dpdk_windows.ps1` | `dpdk-src/VERSION` 파일 확인 |
| toggle 실패 시 exit 0 | `toggle_netuio.ps1` | 최종 검증 실패 시 StepStatus.Failed |

## 구현 순서

### Phase A: 프로젝트 기반 (파일 1-4)
1. `Dpdk_Setup_Tool.csproj` + `app.manifest` + `Program.cs`
2. `ISetupStep.cs` + `SetupStepBase.cs`
3. `SetupState.cs`
4. `ProcessRunner.cs`

### Phase B: UI 프레임워크 (파일 5-7)
5. `LogPanel.cs`
6. `StepListPanel.cs`
7. `SetupWizardForm.cs` (placeholder 스텝)

### Phase C: 유틸리티 (파일 8-10)
8. `SystemInfo.cs`
9. `WdkLocator.cs`
10. `NicDetector.cs`

### Phase D: 스텝 구현 (파일 11-19)
11. `ChecklistPanel.cs` + `SystemCheckStep.cs` (Step 0)
12. `SoftwareInstallStep.cs` (Step 1)
13. `SystemConfigStep.cs` (Step 2)
14. `DpdkBuildStep.cs` (Step 3)
15. `ShimBuildStep.cs` (Step 4)
16. `DriverInstallStep.cs` (Step 5)
17. `NicBindingStep.cs` (Step 6)
18. `DeployVerifyStep.cs` (Step 7)

### Phase E: 통합/검증
19. 재부팅 복원 플로우 테스트
20. 에러 핸들링 엣지 케이스
21. `dotnet build` 성공 확인

## 검증 방법

1. `dotnet build Dpdk_Setup_Tool.csproj` 빌드 성공
2. 앱 실행 → Step 0 시스템 점검 → 모든 항목 표시 확인
3. 각 스텝 개별 실행 가능 확인
4. 재부팅 후 `--resume`로 Step 3부터 재개 확인
5. NIC 감지 → 바인딩/언바인딩 정상 동작 확인
