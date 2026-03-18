# Windows DPDK Driver Installation Script (Complete - Safety Enhanced)
# Includes: Safety Checks, Catalog Generation, Certificate Creation, Signing, and Installation
# Run as Administrator!

param(
    [switch]$Force  # 안전 검증 경고를 무시하고 강제 진행
)

$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================
$WdkBinRoot = "C:\Program Files (x86)\Windows Kits\10\bin"
$DriverDir = "$PSScriptRoot\dpdk-kmods\windows\netuio\x64\Release\netuio"
$InfPath = "$DriverDir\netuio.inf"
$SysPath = "$DriverDir\netuio.sys"
$CatPath = "$DriverDir\netuio.cat"
$CerPath = "$DriverDir\netuio.cer"
$CertName = "DPDK_NetUIO_TestCert"

# 백업/로그 경로
$BackupDir = "$PSScriptRoot\_backup_netuio"
$LogFile = "$BackupDir\install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 타임스탬프 서버 목록 (Fallback)
$TimestampServers = @(
    "http://timestamp.digicert.com",
    "http://timestamp.sectigo.com",
    "http://timestamp.globalsign.com/tsa/r6advanced/v3",
    "http://sha256timestamp.ws.symantec.com/sha256/timestamp"
)

# ============================================================
# Helper Functions
# ============================================================
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$ts] $Message"
    Write-Host $Message -ForegroundColor $Color
    if (Test-Path (Split-Path $LogFile -Parent)) {
        Add-Content -Path $LogFile -Value $logMsg -ErrorAction SilentlyContinue
    }
}

function Get-LatestTool {
    param($Name, $Arch = "x64")
    $tools = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter $Name -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*$Arch*" }
    if (-not $tools) {
        $tools = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\Tools" -Recurse -Filter $Name -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*$Arch*" }
    }
    return $tools | Sort-Object FullName | Select-Object -Last 1 -ExpandProperty FullName
}

function Confirm-Continue {
    param([string]$Message)
    if ($Force) { return $true }
    Write-Host ""
    Write-Host "    $Message" -ForegroundColor Yellow
    $answer = Read-Host "    계속하시겠습니까? (Y/N)"
    return ($answer -eq "Y" -or $answer -eq "y")
}

# ============================================================
# MAIN
# ============================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   NetUIO Driver Setup (Safety Enhanced)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# --- 백업 디렉토리 생성 ---
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}
Write-Log "로그 파일: $LogFile" "Gray"

# ============================================================
# [사전 검증 1] 관리자 권한 확인
# ============================================================
Write-Log "[사전검증 1/4] 관리자 권한 확인..." "Yellow"
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "   [FAIL] 관리자 권한이 필요합니다. 관리자로 다시 실행하세요." "Red"
    exit 1
}
Write-Log "   [OK] 관리자 권한 확인됨" "Green"

# ============================================================
# [사전 검증 2] Secure Boot 상태 확인
# ============================================================
Write-Log "[사전검증 2/4] Secure Boot 상태 확인..." "Yellow"
try {
    $secureBootOn = Confirm-SecureBootUEFI
    if ($secureBootOn) {
        Write-Host ""
        Write-Log "   !!! SECURE BOOT가 활성화되어 있습니다 !!!" "Red"
        Write-Log "   Secure Boot ON + 테스트 서명 드라이버 → 부팅 불가 위험!" "Red"
        Write-Log "   BIOS → Security → Secure Boot → Disabled 후 다시 실행하세요." "Yellow"
        Write-Host ""
        if (-not $Force) {
            exit 1
        }
        Write-Log "   -Force 옵션으로 강제 진행합니다. (위험!)" "Red"
    } else {
        Write-Log "   [OK] Secure Boot OFF 확인됨" "Green"
    }
} catch {
    Write-Log "   [INFO] Secure Boot 상태 확인 불가 (Legacy BIOS일 수 있음)" "Gray"
}

# ============================================================
# [사전 검증 3] TestSigning 활성화 확인
# ============================================================
Write-Log "[사전검증 3/4] TestSigning 상태 확인..." "Yellow"
$bcdOutput = bcdedit /enum "{current}" 2>&1
if ("$bcdOutput" -match "testsigning\s+Yes") {
    Write-Log "   [OK] TestSigning이 활성화되어 있습니다." "Green"
} else {
    Write-Log "   [WARN] TestSigning이 비활성화 상태입니다." "Yellow"
    Write-Log "   setup_new_pc_master.ps1을 먼저 실행하거나, 아래 명령을 실행하세요:" "Yellow"
    Write-Log "   bcdedit /set testsigning on (재부팅 필요)" "Yellow"
    if (-not (Confirm-Continue "TestSigning 없이 계속하면 드라이버가 로드되지 않을 수 있습니다.")) {
        Write-Log "   사용자 취소." "Yellow"
        exit 0
    }
}

# ============================================================
# [사전 검증 4] 드라이버 파일 존재 확인
# ============================================================
Write-Log "[사전검증 4/4] 드라이버 파일 확인..." "Yellow"
if (-not (Test-Path $InfPath) -or -not (Test-Path $SysPath)) {
    Write-Log "   [FAIL] netuio.inf 또는 netuio.sys가 없습니다." "Red"
    Write-Log "   경로: $DriverDir" "Red"
    Write-Log "   dpdk-kmods를 먼저 빌드하세요." "Red"
    exit 1
}
Write-Log "   [OK] netuio.inf, netuio.sys 확인됨" "Green"

# ============================================================
# [안전장치 1] 시스템 복원 지점 생성
# ============================================================
Write-Host ""
Write-Log "[안전장치] 시스템 복원 지점 생성..." "Yellow"
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Before NetUIO Driver Install" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Write-Log "   [OK] 복원 지점 생성 완료" "Green"
} catch {
    Write-Log "   [WARN] 복원 지점 생성 실패: $_" "Yellow"
    if (-not (Confirm-Continue "복원 지점 없이 계속하면 문제 발생 시 수동 복구가 필요합니다.")) {
        Write-Log "   사용자 취소." "Yellow"
        exit 0
    }
}

# ============================================================
# [안전장치 2] 현재 NIC 드라이버 정보 백업
# ============================================================
Write-Log "[안전장치] 현재 NIC 드라이버 정보 백업..." "Yellow"
$nicBackupFile = "$BackupDir\nic_drivers_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
try {
    $nicInfo = @()
    $nicInfo += "=== NIC 드라이버 백업 ($(Get-Date)) ==="
    $nicInfo += ""
    $nicInfo += "--- 네트워크 어댑터 목록 ---"
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
    foreach ($adapter in $adapters) {
        $nicInfo += "이름: $($adapter.Name)"
        $nicInfo += "  설명: $($adapter.InterfaceDescription)"
        $nicInfo += "  상태: $($adapter.Status)"
        $nicInfo += "  MAC: $($adapter.MacAddress)"
        $nicInfo += "  드라이버: $($adapter.DriverFileName) v$($adapter.DriverVersion)"
        $nicInfo += ""
    }
    $nicInfo += "--- PnPUtil 드라이버 목록 (네트워크) ---"
    $pnpDrivers = pnputil /enum-drivers 2>&1
    $nicInfo += $pnpDrivers
    $nicInfo | Set-Content -Path $nicBackupFile -Encoding UTF8
    Write-Log "   [OK] NIC 정보 백업됨: $nicBackupFile" "Green"
} catch {
    Write-Log "   [WARN] NIC 정보 백업 실패: $_" "Yellow"
}

# ============================================================
# Step 1. WDK 도구 찾기
# ============================================================
Write-Host ""
Write-Log "[1/5] WDK 도구 찾는 중..." "Yellow"

$Inf2Cat = Get-LatestTool "Inf2Cat.exe" "x86"
$SignTool = Get-LatestTool "signtool.exe" "x64"

if (-not $Inf2Cat -or -not $SignTool) {
    Write-Log "   표준 경로에서 찾지 못함. 전체 검색 중..." "Gray"
    if (-not $Inf2Cat) { $Inf2Cat = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter "Inf2Cat.exe" | Select-Object -First 1 -ExpandProperty FullName }
    if (-not $SignTool) { $SignTool = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter "signtool.exe" | Where-Object { $_.FullName -like "*x64*" } | Select-Object -First 1 -ExpandProperty FullName }
}

if (-not $Inf2Cat -or -not $SignTool) {
    Write-Log "   [FAIL] Inf2Cat 또는 SignTool을 찾을 수 없습니다." "Red"
    Write-Log "   WDK가 설치되어 있는지 확인하세요." "Red"
    exit 1
}
Write-Log "   Inf2Cat: $Inf2Cat" "White"
Write-Log "   SignTool: $SignTool" "White"

# ============================================================
# Step 2. 카탈로그 파일 생성
# ============================================================
Write-Log "[2/5] 카탈로그 파일 생성 (netuio.cat)..." "Yellow"
# 기존 카탈로그 제거 (재생성을 위해)
if (Test-Path $CatPath) {
    Remove-Item $CatPath -Force
    Write-Log "   기존 netuio.cat 삭제됨" "Gray"
}

$Inf2CatArgs = "/driver:`"$DriverDir`" /os:10_X64"
$proc = Start-Process -FilePath $Inf2Cat -ArgumentList $Inf2CatArgs -Wait -NoNewWindow -PassThru
if (-not (Test-Path $CatPath)) {
    Write-Log "   [FAIL] 카탈로그 생성 실패. netuio.cat이 생성되지 않았습니다." "Red"
    exit 1
}
Write-Log "   [OK] 카탈로그 생성 완료" "Green"

# ============================================================
# Step 3. 인증서 생성 및 신뢰 등록
# ============================================================
Write-Log "[3/5] 자체서명 인증서 생성..." "Yellow"

# 기존 DPDK 인증서 확인 및 정리
$existingCertRoot = certutil -store Root 2>&1
$existingCertTP = certutil -store TrustedPublisher 2>&1
$existingCertMy = certutil -store My 2>&1

if ("$existingCertRoot" -match $CertName -or "$existingCertTP" -match $CertName -or "$existingCertMy" -match $CertName) {
    Write-Log "   기존 DPDK 인증서 발견됨. 정리 후 재생성합니다..." "Gray"
    certutil -delstore Root $CertName 2>&1 | Out-Null
    certutil -delstore TrustedPublisher $CertName 2>&1 | Out-Null
    certutil -delstore My $CertName 2>&1 | Out-Null
    Write-Log "   기존 인증서 정리 완료" "Gray"
}

# 기존 .cer 파일 삭제
if (Test-Path $CerPath) {
    Remove-Item $CerPath -Force
}

# 새 인증서 생성 (New-SelfSignedCertificate 사용 - makecert.exe 대체)
try {
    $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=$CertName" `
        -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(5)
    Export-Certificate -Cert $cert -FilePath $CerPath -Type CERT | Out-Null
} catch {
    Write-Log "   [FAIL] 인증서 생성 실패: $_" "Red"
    exit 1
}

if (-not (Test-Path $CerPath)) {
    Write-Log "   [FAIL] 인증서 파일 생성 실패." "Red"
    exit 1
}
Write-Log "   [OK] 인증서 생성됨: $CerPath" "Green"

# 신뢰 저장소에 등록
Write-Log "   Trusted Root 및 TrustedPublisher에 등록 중..." "Gray"
$procRoot = Start-Process -FilePath "certutil.exe" -ArgumentList "-addstore -f Root `"$CerPath`"" -Wait -NoNewWindow -PassThru
$procTP = Start-Process -FilePath "certutil.exe" -ArgumentList "-addstore -f TrustedPublisher `"$CerPath`"" -Wait -NoNewWindow -PassThru
Write-Log "   [OK] 인증서 신뢰 등록 완료" "Green"

# ============================================================
# Step 4. 드라이버 파일 서명 (타임스탬프 서버 Fallback)
# ============================================================
Write-Log "[4/5] 드라이버 파일 서명 (.sys, .cat)..." "Yellow"

$signed = $false
foreach ($tsServer in $TimestampServers) {
    Write-Log "   타임스탬프 서버 시도: $tsServer" "Gray"
    $SignArgs = "sign /v /a /s My /n `"$CertName`" /t $tsServer /fd sha256 `"$SysPath`" `"$CatPath`""
    $proc = Start-Process -FilePath $SignTool -ArgumentList $SignArgs -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Log "   [OK] 서명 성공 (서버: $tsServer)" "Green"
        $signed = $true
        break
    }
    Write-Log "   [WARN] 서명 실패 (서버: $tsServer). 다음 서버로 재시도..." "Yellow"
}

if (-not $signed) {
    Write-Log "   [FAIL] 모든 타임스탬프 서버에서 서명 실패." "Red"
    Write-Log "   네트워크 연결을 확인하세요." "Red"

    # 롤백: 인증서 정리
    Write-Log "   롤백: 생성한 인증서를 제거합니다..." "Yellow"
    certutil -delstore Root $CertName 2>&1 | Out-Null
    certutil -delstore TrustedPublisher $CertName 2>&1 | Out-Null
    certutil -delstore My $CertName 2>&1 | Out-Null
    if (Test-Path $CerPath) { Remove-Item $CerPath -Force }
    if (Test-Path $CatPath) { Remove-Item $CatPath -Force }
    Write-Log "   롤백 완료. 인증서 및 카탈로그 정리됨." "Yellow"
    exit 1
}

# ============================================================
# Step 5. 드라이버 설치
# ============================================================
Write-Log "[5/5] PnPUtil로 드라이버 설치..." "Yellow"
Write-Log "   (주의: /install은 드라이버 저장소에만 추가합니다. NIC 바인딩은 별도)" "Gray"

$pnpResult = pnputil /add-driver "$InfPath" /install 2>&1
$pnpExitCode = $LASTEXITCODE

Write-Log "   pnputil 결과:" "Gray"
foreach ($line in $pnpResult) {
    Write-Log "   $line" "Gray"
}

# exit code 259 (ERROR_NO_MORE_ITEMS)는 드라이버가 정상 추가된 후 발생하는 정상 코드
if ($pnpExitCode -ne 0 -and $pnpExitCode -ne 259) {
    Write-Log "   [FAIL] 드라이버 설치 실패 (exit code: $pnpExitCode)" "Red"

    # 롤백
    Write-Log "   롤백: 인증서를 제거합니다..." "Yellow"
    certutil -delstore Root $CertName 2>&1 | Out-Null
    certutil -delstore TrustedPublisher $CertName 2>&1 | Out-Null
    certutil -delstore My $CertName 2>&1 | Out-Null
    if (Test-Path $CerPath) { Remove-Item $CerPath -Force }
    if (Test-Path $CatPath) { Remove-Item $CatPath -Force }
    Write-Log "   롤백 완료." "Yellow"
    exit 1
}

if ($pnpExitCode -eq 259) {
    Write-Log "   [OK] 드라이버 등록 완료 (exit code 259: 정상 - 추가 항목 없음)" "Green"
}

# ============================================================
# [설치 후 검증] 드라이버 등록 확인
# ============================================================
Write-Host ""
Write-Log "[검증] 드라이버 설치 결과 확인..." "Yellow"

$verifyDrivers = pnputil /enum-drivers 2>&1
$netuioFound = $false
$currentOem = $null
foreach ($line in $verifyDrivers) {
    if ($line -match "(oem\d+\.inf)") {
        $currentOem = $Matches[1]
    }
    if ($line -match "netuio" -and $currentOem) {
        $netuioFound = $true
        Write-Log "   [OK] netuio 드라이버 등록 확인됨: $currentOem" "Green"
        $currentOem = $null
    }
}

if (-not $netuioFound) {
    Write-Log "   [WARN] netuio 드라이버가 pnputil 목록에서 확인되지 않음" "Yellow"
    Write-Log "   수동 확인 필요: pnputil /enum-drivers" "Yellow"
}

# ============================================================
# 완료 메시지
# ============================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   NetUIO 드라이버 설치 완료!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Log "   NIC 드라이버 백업: $nicBackupFile" "White"
Write-Log "   설치 로그: $LogFile" "White"
Write-Host ""
Write-Host "   다음 단계:" -ForegroundColor Cyan
Write-Host "   1. 장치 관리자에서 대상 NIC을 netuio 드라이버로 전환" -ForegroundColor White
Write-Host "   2. 또는 toggle_netuio.ps1 사용" -ForegroundColor White
Write-Host ""
Write-Host "   문제 발생 시:" -ForegroundColor Yellow
Write-Host "   - recovery_dpdk.ps1 실행 (Safe Mode에서)" -ForegroundColor White
Write-Host "   - 시스템 복원 사용 (복원 지점: 'Before NetUIO Driver Install')" -ForegroundColor White
Write-Host ""
