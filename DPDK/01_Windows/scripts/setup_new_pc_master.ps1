<#
.SYNOPSIS
    Master Setup Script for Windows DPDK Environment on a New PC.

.DESCRIPTION
    This script automates the installation of all prerequisites for DPDK on Windows:
    1. Installs Chocolatey (Package Manager).
    2. Installs VS2022 Build Tools, LLVM, Git, Python, WDK.
    3. Configures System Policies (Lock Pages in Memory).
    4. Enables TestSigning (with BCD backup).
    5. Installs Python dependencies (Meson, Ninja).

    * RUN AS ADMINISTRATOR!
    * REBOOT IS REQUIRED AFTER COMPLETION.

.PARAMETER Interactive
    각 단계 완료 후 계속 진행 여부를 사용자에게 확인합니다.

.NOTES
    Author: Gemini Agent (Safety Enhanced by Claude)
    Date: 2026-02-27
#>

param(
    [switch]$Interactive  # 단계별 진행 확인 모드
)

$ErrorActionPreference = "Stop"

# 백업 경로
$BackupDir = "$PSScriptRoot\_backup_system"
$BcdBackupFile = "$BackupDir\bcd_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"

# ============================================================
# Helper Functions
# ============================================================
function Assert-SecureBootOff {
    try {
        if (Confirm-SecureBootUEFI) {
            Write-Host ""
            Write-Host "!!! SECURE BOOT가 활성화되어 있습니다 !!!" -ForegroundColor Red
            Write-Host "    testsigning은 Secure Boot OFF에서만 동작합니다." -ForegroundColor Red
            Write-Host "    Secure Boot ON + testsigning → 부팅 불가 위험!" -ForegroundColor Red
            Write-Host ""
            Write-Host "    BIOS → Security → Secure Boot → Disabled 후 다시 실행하세요." -ForegroundColor Yellow
            exit 1
        }
        Write-Host "    [OK] Secure Boot OFF 확인됨" -ForegroundColor Green
    } catch {
        # Confirm-SecureBootUEFI 사용 불가 시 (Legacy BIOS 등) 경고만
        Write-Host "    [INFO] Secure Boot 상태 확인 불가 (Legacy BIOS일 수 있음)" -ForegroundColor Gray
    }
}

function Check-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error ">>> ERROR: This script MUST be run as Administrator."
        exit 1
    }
}

function Confirm-StepContinue {
    param([string]$StepName)
    if (-not $Interactive) { return }
    Write-Host ""
    Write-Host "    [$StepName] 완료. 다음 단계로 진행하시겠습니까? (Y/N)" -ForegroundColor Yellow
    $answer = Read-Host "    "
    if ($answer -ne "Y" -and $answer -ne "y") {
        Write-Host "    사용자가 중단을 요청했습니다." -ForegroundColor Yellow
        exit 0
    }
}

function Install-Chocolatey {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host ">>> Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Reload env vars
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Host ">>> Chocolatey is already installed." -ForegroundColor Green
    }
}

function Install-Software {
    Write-Host ">>> Installing Dependencies via Chocolatey..." -ForegroundColor Cyan
    Write-Host "    (This may take a while. Please wait...)" -ForegroundColor Gray

    # 1. Basics
    choco install git python llvm -y

    # 2. Visual Studio 2022 Build Tools (C++ Desktop Workload)
    Write-Host ">>> Installing Visual Studio Build Tools (C++)..." -ForegroundColor Cyan
    choco install visualstudio2022buildtools -y --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

    # 3. Windows Driver Kit (WDK) - Required for netuio signing
    Write-Host ">>> Installing Windows Driver Kit (WDK)..." -ForegroundColor Cyan
    choco install windows-driver-kit -y

    # Reload environment variables to ensure new tools are found
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Configure-System-Settings {
    Write-Host ">>> Configuring System Settings..." -ForegroundColor Cyan

    # 1. Lock Pages in Memory (Grant SeLockMemoryPrivilege to current user)
    Write-Host "    Granting 'Lock pages in memory' privilege..."
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $tmpCfg = "$env:TEMP\secpol.cfg"

    # Export current security policy
    secedit /export /cfg $tmpCfg /quiet

    # Read and modify
    $content = Get-Content $tmpCfg
    $newLine = "SeLockMemoryPrivilege = *S-1-5-32-544,$user" # Administrators + Current User

    if ($content -match "SeLockMemoryPrivilege") {
        $content = $content -replace "SeLockMemoryPrivilege.*", $newLine
    } else {
        # Append if not exists (in Privilege Rights section)
        $targetIndex = $content.IndexOf("[Privilege Rights]") + 1
        $content = $content[0..$targetIndex] + $newLine + $content[($targetIndex+1)..($content.Length-1)]
    }

    Set-Content $tmpCfg $content

    # Import modified policy
    secedit /configure /db secedit.sdb /cfg $tmpCfg /areas USER_RIGHTS /quiet
    Remove-Item $tmpCfg
    Write-Host "    Done." -ForegroundColor Green

    Confirm-StepContinue "SeLockMemory 설정"

    # 2. Python Dependencies
    Write-Host "    Installing Python packages (Meson, Ninja)..."
    pip install meson ninja pyelftools

    Confirm-StepContinue "Python 패키지 설치"

    # 3. Enable Test Signing
    Write-Host "    Enabling TestSigning (Required for netuio driver)..."

    # 안전 가드: Secure Boot 상태 검사
    Assert-SecureBootOff

    # 안전 가드: 시스템 복원 지점 생성
    Write-Host "    시스템 복원 지점 생성 중..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Before DPDK TestSigning" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "    [OK] 복원 지점 생성 완료" -ForegroundColor Green
    } catch {
        Write-Host "    [WARN] 복원 지점 생성 실패: $_" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "    복원 지점 없이 계속하면 문제 발생 시 수동 복구가 필요합니다." -ForegroundColor Yellow
        $answer = Read-Host "    계속하시겠습니까? (Y/N)"
        if ($answer -ne "Y" -and $answer -ne "y") {
            Write-Host "    사용자가 중단을 요청했습니다." -ForegroundColor Yellow
            exit 0
        }
    }

    # 안전 가드: BCD 백업
    Write-Host "    BCD 설정 백업 중..."
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    try {
        $bcdResult = bcdedit /export $BcdBackupFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] BCD 백업 완료: $BcdBackupFile" -ForegroundColor Green
        } else {
            Write-Host "    [WARN] BCD 백업 실패: $bcdResult" -ForegroundColor Yellow
            Write-Host "    수동 백업: bcdedit /export C:\bcd_backup.bak" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [WARN] BCD 백업 실패: $_" -ForegroundColor Yellow
    }

    # TestSigning 설정
    $result = bcdedit /set testsigning on 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [FAIL] bcdedit 실행 실패: $result" -ForegroundColor Red
        Write-Host "    BCD 저장소가 손상되었을 수 있습니다." -ForegroundColor Red
        if (Test-Path $BcdBackupFile) {
            Write-Host "    BCD 백업 파일: $BcdBackupFile" -ForegroundColor Yellow
            Write-Host "    복원 명령: bcdedit /import `"$BcdBackupFile`"" -ForegroundColor Yellow
        }
        exit 1
    }
    Write-Host "    [OK] TestSigning ON 설정 완료" -ForegroundColor Green
}

# --- Main Execution ---
Check-Admin

Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "   Windows DPDK New PC Setup Script" -ForegroundColor Magenta
if ($Interactive) {
    Write-Host "   (Interactive Mode - 단계별 확인)" -ForegroundColor Yellow
}
Write-Host "=============================================" -ForegroundColor Magenta

Install-Chocolatey
Confirm-StepContinue "Chocolatey 설치"

Install-Software
Confirm-StepContinue "소프트웨어 설치"

Configure-System-Settings

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host "   SETUP COMPLETE!" -ForegroundColor Green
Write-Host "============================================="
Write-Host "1. A SYSTEM REBOOT IS REQUIRED." -ForegroundColor Red
Write-Host "2. After reboot, verify you are in '01_Windows' folder and run:"
Write-Host "   .\setup_dpdk_windows.ps1   (To build DPDK)"
Write-Host "   .\install_netuio_complete.ps1 (To install driver)"
if (Test-Path $BcdBackupFile) {
    Write-Host ""
    Write-Host "   BCD 백업 파일: $BcdBackupFile" -ForegroundColor Cyan
    Write-Host "   (부팅 실패 시 복구에 사용)" -ForegroundColor Cyan
}
Write-Host "============================================="
