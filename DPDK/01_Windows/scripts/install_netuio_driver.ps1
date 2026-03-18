# Windows DPDK netuio Driver Installation Script
# Run this script as Administrator

$ErrorActionPreference = "Stop"

function Assert-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "이 스크립트는 관리자 권한으로 실행해야 합니다. PowerShell을 관리자 권한으로 다시 실행해주세요."
        exit 1
    }
}

Assert-Admin

# 경로 설정 (스크립트 위치 기준)
$ScriptDir = $PSScriptRoot
# 빌드된 드라이버 경로 (Relative to Windows_Env or adjusted if run from root)
# Assuming this script is placed in Windows_Env/ 
$DriverDir = Join-Path $ScriptDir "dpdk-kmods\windows\netuio\x64\Release\netuio"
$InfFile = Join-Path $DriverDir "netuio.inf"
$CerFile = Join-Path $DriverDir "netuio.cer"
$SysFile = Join-Path $DriverDir "netuio.sys"

Write-Host ">>> Checking Driver Files..." -ForegroundColor Cyan
if (-not (Test-Path $InfFile) -or -not (Test-Path $CerFile)) {
    Write-Error "드라이버 파일을 찾을 수 없습니다. 경로를 확인하세요:`n$DriverDir"
    exit 1
}
Write-Host "    Found: $InfFile"
Write-Host "    Found: $CerFile"

# 1. TestSigning 확인
Write-Host "`n>>> Checking TestSigning Status..." -ForegroundColor Cyan
$bcd = bcdedit /enum "{current}" | Select-String "testsigning"
if ($bcd -match "Yes") {
    Write-Host "    TestSigning is ON." -ForegroundColor Green
} else {
    Write-Warning "TestSigning이 꺼져있거나 확인할 수 없습니다."
    Write-Warning "드라이버 로드를 위해 'bcdedit /set testsigning on' 실행 후 재부팅이 필요할 수 있습니다."
}

# 2. 인증서 설치
Write-Host "`n>>> Installing Driver Certificate..." -ForegroundColor Cyan
try {
    Write-Host "    Adding to Trusted Root..."
    Import-Certificate -FilePath $CerFile -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    Write-Host "    Adding to Trusted Publishers..."
    Import-Certificate -FilePath $CerFile -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
    Write-Host "    Certificate Installed Successfully!" -ForegroundColor Green
} catch {
    Write-Error "인증서 설치 실패: $_ "
}

# 3. 드라이버 설치 (PnPUtil)
Write-Host "`n>>> Installing Driver via PnPUtil..." -ForegroundColor Cyan
$pnpResult = pnputil /add-driver $InfFile /install
$pnpResult | ForEach-Object { Write-Host "    $_" }

if ($pnpResult -match "Driver package added successfully") {
    Write-Host "`n>>> Driver Installation Complete!" -ForegroundColor Green
    Write-Host "이제 장치 관리자에서 네트워크 어댑터 드라이버를 'netuio'로 수동 업데이트하거나,"
    Write-Host "'devcon'을 사용하여 바인딩할 수 있습니다."
} else {
    Write-Error "드라이버 설치에 실패했습니다. 위의 에러 메시지를 확인하세요."
}

