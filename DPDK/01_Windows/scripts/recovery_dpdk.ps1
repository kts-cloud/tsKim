<#
.SYNOPSIS
    DPDK 설정 롤백 스크립트 (부팅 실패 복구용)
.DESCRIPTION
    DPDK 설정 후 Windows 부팅이 불가능해진 경우,
    Safe Mode에서 이 스크립트를 실행하여 DPDK 관련 설정을 모두 롤백합니다.

    롤백 항목:
    1. 현재 상태 진단 출력
    2. BCD 백업 파일 복원 (있는 경우)
    3. TestSigning 비활성화 (bcdedit)
    4. netuio 드라이버 제거 (pnputil)
    5. DPDK 자체서명 인증서 제거 (certutil)
    6. SeLockMemoryPrivilege 복구
    7. 디바이스 재스캔 (원본 드라이버 복원)

    * Safe Mode에서 관리자 권한으로 실행하세요.
    * 진입 방법: 부팅 시 F8 또는 복구 환경 → 고급 옵션 → Safe Mode (명령 프롬프트)
.NOTES
    Date: 2026-02-27 (Safety Enhanced)
#>

$ErrorActionPreference = "Continue"

# 관리자 권한 확인
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: 관리자 권한으로 실행해야 합니다." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "   DPDK 설정 롤백 스크립트 (부팅 실패 복구용)" -ForegroundColor Yellow
Write-Host "   Safe Mode 또는 정상 모드에서 관리자로 실행" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host ""

$steps = 0
$errors = 0
$totalSteps = 7

# ============================================================
# [0/7] WinRE 복구 방법 안내
# ============================================================
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "   [참고] Windows 복구 환경(WinRE) 진입이 필요한 경우" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "   부팅이 완전히 불가능하면 아래 방법을 시도하세요:" -ForegroundColor White
Write-Host ""
Write-Host "   방법 1: 자동 복구 환경 진입" -ForegroundColor Cyan
Write-Host "   - PC 전원 ON → Windows 로고 표시 시 전원 버튼 길게 눌러 강제 종료" -ForegroundColor White
Write-Host "   - 이 과정을 3회 반복 → 자동 복구 환경 진입" -ForegroundColor White
Write-Host "   - '문제 해결' → '고급 옵션' → '명령 프롬프트' 선택" -ForegroundColor White
Write-Host ""
Write-Host "   방법 2: Windows 설치 미디어 사용" -ForegroundColor Cyan
Write-Host "   - USB 설치 미디어로 부팅" -ForegroundColor White
Write-Host "   - '컴퓨터 복구' → '문제 해결' → '명령 프롬프트'" -ForegroundColor White
Write-Host ""
Write-Host "   방법 3: Safe Mode 진입" -ForegroundColor Cyan
Write-Host "   - 위 방법으로 복구 환경 진입 후" -ForegroundColor White
Write-Host "   - '문제 해결' → '고급 옵션' → '시작 설정' → '다시 시작'" -ForegroundColor White
Write-Host "   - 4번 또는 F4 (안전 모드) 또는 5번/F5 (네트워킹 포함)" -ForegroundColor White
Write-Host ""
Write-Host "   WinRE 명령 프롬프트에서 수동 복구:" -ForegroundColor Yellow
Write-Host "   bcdedit /set {default} testsigning off" -ForegroundColor Gray
Write-Host "   bcdedit /set {default} safeboot minimal" -ForegroundColor Gray
Write-Host "   (위 명령 후 재부팅 → Safe Mode로 부팅 → 이 스크립트 실행)" -ForegroundColor Gray
Write-Host ""
Write-Host "   BCD 백업 파일로 복원 (백업이 있는 경우):" -ForegroundColor Yellow
Write-Host "   bcdedit /import D:\Dongaeltek\_Project\05_DPDK\01_Windows\_backup_system\bcd_backup_*.bak" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""

# ============================================================
# [1/7] 현재 상태 진단
# ============================================================
Write-Host "[1/$totalSteps] 현재 시스템 상태 진단..." -ForegroundColor Cyan
Write-Host ""

Write-Host "   --- BCD 설정 ---" -ForegroundColor White
try {
    $bcdInfo = bcdedit /enum "{current}" 2>&1
    foreach ($line in $bcdInfo) {
        if ($line -match "testsigning|identifier|description|device") {
            Write-Host "   $line" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   [WARN] BCD 정보 읽기 실패: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "   --- 네트워크 어댑터 ---" -ForegroundColor White
try {
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
    if ($adapters) {
        foreach ($a in $adapters) {
            Write-Host "   $($a.Name): $($a.InterfaceDescription) [$($a.Status)]" -ForegroundColor Gray
        }
    } else {
        Write-Host "   (네트워크 어댑터 정보 없음 - Safe Mode에서는 정상)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   (Get-NetAdapter 사용 불가)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "   --- DPDK 인증서 ---" -ForegroundColor White
try {
    $certRoot = certutil -store Root 2>&1
    $certTP = certutil -store TrustedPublisher 2>&1
    if ("$certRoot" -match "DPDK_NetUIO_TestCert") {
        Write-Host "   Root 저장소: DPDK 인증서 존재" -ForegroundColor Yellow
    } else {
        Write-Host "   Root 저장소: DPDK 인증서 없음" -ForegroundColor Gray
    }
    if ("$certTP" -match "DPDK_NetUIO_TestCert") {
        Write-Host "   TrustedPublisher: DPDK 인증서 존재" -ForegroundColor Yellow
    } else {
        Write-Host "   TrustedPublisher: DPDK 인증서 없음" -ForegroundColor Gray
    }
} catch {
    Write-Host "   (인증서 확인 실패)" -ForegroundColor Gray
}

Write-Host ""
$steps++

# ============================================================
# [2/7] BCD 백업 파일 복원 옵션
# ============================================================
Write-Host "[2/$totalSteps] BCD 백업 파일 확인..." -ForegroundColor Cyan
$bcdBackupDir = "$PSScriptRoot\_backup_system"
$bcdRestored = $false

if (Test-Path $bcdBackupDir) {
    $bcdFiles = Get-ChildItem -Path $bcdBackupDir -Filter "bcd_backup_*.bak" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if ($bcdFiles.Count -gt 0) {
        $latestBcd = $bcdFiles[0].FullName
        Write-Host "      BCD 백업 파일 발견: $latestBcd" -ForegroundColor Yellow
        Write-Host "      (생성일: $($bcdFiles[0].LastWriteTime))" -ForegroundColor Gray
        Write-Host ""
        Write-Host "      BCD를 백업 시점으로 복원하시겠습니까?" -ForegroundColor Yellow
        Write-Host "      (TestSigning 등 BCD 설정이 백업 시점으로 돌아갑니다)" -ForegroundColor Gray
        $answer = Read-Host "      (Y/N, 건너뛰려면 N)"
        if ($answer -eq "Y" -or $answer -eq "y") {
            try {
                $importResult = bcdedit /import $latestBcd 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "      [OK] BCD 복원 완료" -ForegroundColor Green
                    $bcdRestored = $true
                } else {
                    Write-Host "      [WARN] BCD 복원 실패: $importResult" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "      [WARN] BCD 복원 실패: $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "      BCD 복원 건너뜀" -ForegroundColor Gray
        }
    } else {
        Write-Host "      [INFO] BCD 백업 파일이 없습니다." -ForegroundColor Gray
    }
} else {
    Write-Host "      [INFO] 백업 디렉토리가 없습니다: $bcdBackupDir" -ForegroundColor Gray
}
$steps++

# ============================================================
# [3/7] TestSigning 비활성화
# ============================================================
Write-Host "[3/$totalSteps] TestSigning 비활성화..." -ForegroundColor Cyan
if (-not $bcdRestored) {
    try {
        $result = bcdedit /set testsigning off 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      [OK] TestSigning OFF 설정 완료" -ForegroundColor Green
        } else {
            Write-Host "      [WARN] bcdedit 결과: $result" -ForegroundColor Yellow
        }
        $steps++
    } catch {
        Write-Host "      [FAIL] $_" -ForegroundColor Red
        $errors++
    }
} else {
    Write-Host "      [SKIP] BCD가 이미 복원되었으므로 건너뜁니다." -ForegroundColor Gray
    $steps++
}

# ============================================================
# [4/7] netuio 드라이버 제거
# ============================================================
Write-Host "[4/$totalSteps] netuio 드라이버 제거..." -ForegroundColor Cyan
try {
    $drivers = pnputil /enum-drivers 2>&1
    $netuioDrivers = @()
    $currentOem = $null

    foreach ($line in $drivers) {
        if ($line -match "oem\d+\.inf") {
            $currentOem = ($line -replace ".*?(oem\d+\.inf).*", '$1').Trim()
        }
        if ($line -match "netuio" -and $currentOem) {
            $netuioDrivers += $currentOem
            $currentOem = $null
        }
    }

    if ($netuioDrivers.Count -eq 0) {
        Write-Host "      [INFO] netuio 드라이버가 설치되어 있지 않습니다." -ForegroundColor Gray
    } else {
        foreach ($drv in $netuioDrivers) {
            Write-Host "      제거 중: $drv"
            pnputil /delete-driver $drv /uninstall /force 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "      [OK] $drv 제거 완료" -ForegroundColor Green
            } else {
                Write-Host "      [WARN] $drv 제거 실패 (이미 제거되었거나 사용 중)" -ForegroundColor Yellow
            }
        }
    }
    $steps++
} catch {
    Write-Host "      [FAIL] $_" -ForegroundColor Red
    $errors++
}

# ============================================================
# [5/7] DPDK 자체서명 인증서 제거 (Root + TrustedPublisher + My)
# ============================================================
Write-Host "[5/$totalSteps] DPDK 인증서 제거 (모든 저장소)..." -ForegroundColor Cyan
$certStores = @("Root", "TrustedPublisher", "My")
foreach ($store in $certStores) {
    try {
        $certs = certutil -store $store 2>&1
        if ("$certs" -match "DPDK_NetUIO_TestCert") {
            certutil -delstore $store "DPDK_NetUIO_TestCert" 2>&1
            Write-Host "      [OK] $store 저장소에서 인증서 제거 완료" -ForegroundColor Green
        } else {
            Write-Host "      [INFO] $store 저장소에 DPDK 인증서 없음" -ForegroundColor Gray
        }
    } catch {
        Write-Host "      [WARN] $store 저장소 처리 중 오류: $_" -ForegroundColor Yellow
    }
}
$steps++

# ============================================================
# [6/7] SeLockMemoryPrivilege 복구 (기본값으로)
# ============================================================
Write-Host "[6/$totalSteps] SeLockMemoryPrivilege 복구..." -ForegroundColor Cyan
try {
    $tmpCfg = "$env:TEMP\secpol_recovery.cfg"

    # 현재 보안 정책 내보내기
    secedit /export /cfg $tmpCfg /quiet 2>&1

    if (Test-Path $tmpCfg) {
        $content = Get-Content $tmpCfg
        $modified = $false

        # SeLockMemoryPrivilege 행 찾기
        for ($i = 0; $i -lt $content.Length; $i++) {
            if ($content[$i] -match "SeLockMemoryPrivilege") {
                Write-Host "      현재 설정: $($content[$i])" -ForegroundColor Gray
                Write-Host "      SeLockMemoryPrivilege를 제거하시겠습니까?" -ForegroundColor Yellow
                Write-Host "      (Administrators 그룹만 유지 / 완전 제거)" -ForegroundColor Gray
                $answer = Read-Host "      제거(R), Administrators만(A), 건너뛰기(S)"
                if ($answer -eq "R" -or $answer -eq "r") {
                    # 해당 행 제거
                    $content[$i] = ""
                    $modified = $true
                    Write-Host "      [OK] SeLockMemoryPrivilege 제거됨" -ForegroundColor Green
                } elseif ($answer -eq "A" -or $answer -eq "a") {
                    # Administrators 그룹만 유지
                    $content[$i] = "SeLockMemoryPrivilege = *S-1-5-32-544"
                    $modified = $true
                    Write-Host "      [OK] Administrators만 유지" -ForegroundColor Green
                } else {
                    Write-Host "      [SKIP] 건너뜀" -ForegroundColor Gray
                }
                break
            }
        }

        if ($modified) {
            Set-Content $tmpCfg $content
            secedit /configure /db "$env:TEMP\secedit_recovery.sdb" /cfg $tmpCfg /areas USER_RIGHTS /quiet 2>&1
        }

        Remove-Item $tmpCfg -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\secedit_recovery.sdb" -ErrorAction SilentlyContinue
    } else {
        Write-Host "      [WARN] 보안 정책 내보내기 실패" -ForegroundColor Yellow
    }
    $steps++
} catch {
    Write-Host "      [FAIL] $_" -ForegroundColor Red
    $errors++
}

# ============================================================
# [7/7] 디바이스 재스캔 (원본 드라이버 복원)
# ============================================================
Write-Host "[7/$totalSteps] 하드웨어 재스캔 (원본 드라이버 복원)..." -ForegroundColor Cyan
try {
    pnputil /scan-devices 2>&1
    Write-Host "      [OK] 디바이스 재스캔 완료" -ForegroundColor Green
    $steps++
} catch {
    Write-Host "      [FAIL] $_" -ForegroundColor Red
    $errors++
}

# ============================================================
# 결과 요약
# ============================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "   롤백 완료" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "   성공: $steps / $totalSteps 단계" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Yellow" })
if ($errors -gt 0) {
    Write-Host "   실패: $errors 건 (위 로그를 확인하세요)" -ForegroundColor Red
}
Write-Host ""
Write-Host "   다음 단계:" -ForegroundColor Cyan
Write-Host "   1. 컴퓨터를 재부팅하세요 (정상 모드로 진입)" -ForegroundColor White
Write-Host "   2. 정상 부팅 확인 후 네트워크 연결 확인" -ForegroundColor White
Write-Host "   3. DPDK 재설정이 필요하면:" -ForegroundColor White
Write-Host "      - BIOS에서 Secure Boot OFF 확인" -ForegroundColor White
Write-Host "      - setup_new_pc_master.ps1 다시 실행" -ForegroundColor White
Write-Host ""
Write-Host "   완전히 부팅 불가한 경우 WinRE에서 수동 복구:" -ForegroundColor Yellow
Write-Host "   bcdedit /set {default} testsigning off" -ForegroundColor Gray
Write-Host "   bcdedit /deletevalue {default} safeboot" -ForegroundColor Gray
Write-Host ""
Write-Host "   재부팅 하시겠습니까? (Y/N)" -ForegroundColor Yellow
$reboot = Read-Host
if ($reboot -eq "Y" -or $reboot -eq "y") {
    # Safe Mode 해제 (safeboot 값이 설정되어 있으면)
    bcdedit /deletevalue safeboot 2>&1 | Out-Null
    Write-Host "   5초 후 재부팅합니다..." -ForegroundColor Red
    shutdown /r /t 5
} else {
    Write-Host "   수동으로 재부팅하세요: shutdown /r /t 0" -ForegroundColor Yellow
}
