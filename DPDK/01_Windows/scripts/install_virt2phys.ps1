# virt2phys Driver Installation Script for Windows DPDK
# Run as Administrator!
param([switch]$Force)

$ErrorActionPreference = "Stop"

# Configuration
$DriverDir = "$PSScriptRoot\dpdk-kmods\windows\virt2phys\x64\Debug\virt2phys"
$InfPath = "$DriverDir\virt2phys.inf"
$SysPath = "$DriverDir\virt2phys.sys"
$CatPath = "$DriverDir\virt2phys.cat"
$CerPath = "$DriverDir\virt2phys.cer"
$CertName = "DPDK_Virt2Phys_TestCert"

$TimestampServers = @(
    "http://timestamp.digicert.com",
    "http://timestamp.sectigo.com",
    "http://timestamp.globalsign.com/tsa/r6advanced/v3"
)

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

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   virt2phys Driver Setup (VA-to-PA translator)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[FAIL] Administrator privileges required." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Administrator check passed" -ForegroundColor Green

# Check files
if (-not (Test-Path $InfPath) -or -not (Test-Path $SysPath)) {
    Write-Host "[FAIL] virt2phys.inf or virt2phys.sys not found at $DriverDir" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Driver files found" -ForegroundColor Green

# Step 1: Find WDK tools
Write-Host ""
Write-Host "[1/5] Finding WDK tools..." -ForegroundColor Yellow
$Inf2Cat = Get-LatestTool "Inf2Cat.exe" "x86"
$SignTool = Get-LatestTool "signtool.exe" "x64"

if (-not $Inf2Cat -or -not $SignTool) {
    Write-Host "[FAIL] Inf2Cat or SignTool not found. Is WDK installed?" -ForegroundColor Red
    exit 1
}
Write-Host "   Inf2Cat: $Inf2Cat" -ForegroundColor White
Write-Host "   SignTool: $SignTool" -ForegroundColor White

# Step 2: Generate catalog
Write-Host "[2/5] Generating catalog (virt2phys.cat)..." -ForegroundColor Yellow
if (Test-Path $CatPath) {
    Remove-Item $CatPath -Force
    Write-Host "   Removed existing virt2phys.cat" -ForegroundColor Gray
}

$proc = Start-Process -FilePath $Inf2Cat -ArgumentList "/driver:`"$DriverDir`" /os:10_X64" -Wait -NoNewWindow -PassThru
if (-not (Test-Path $CatPath)) {
    Write-Host "[FAIL] Catalog generation failed." -ForegroundColor Red
    exit 1
}
Write-Host "   [OK] Catalog generated" -ForegroundColor Green

# Step 3: Create certificate
Write-Host "[3/5] Creating self-signed certificate..." -ForegroundColor Yellow

# Clean existing certs
$storesCheck = @("Root", "TrustedPublisher", "My")
foreach ($store in $storesCheck) {
    certutil -delstore $store $CertName 2>&1 | Out-Null
}
if (Test-Path $CerPath) { Remove-Item $CerPath -Force }

try {
    $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=$CertName" `
        -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(5)
    Export-Certificate -Cert $cert -FilePath $CerPath -Type CERT | Out-Null
} catch {
    Write-Host "[FAIL] Certificate creation failed: $_" -ForegroundColor Red
    exit 1
}

# Register in trust stores
Start-Process -FilePath "certutil.exe" -ArgumentList "-addstore -f Root `"$CerPath`"" -Wait -NoNewWindow
Start-Process -FilePath "certutil.exe" -ArgumentList "-addstore -f TrustedPublisher `"$CerPath`"" -Wait -NoNewWindow
Write-Host "   [OK] Certificate created and trusted" -ForegroundColor Green

# Step 4: Sign driver files
Write-Host "[4/5] Signing driver files..." -ForegroundColor Yellow
$signed = $false
foreach ($tsServer in $TimestampServers) {
    Write-Host "   Trying timestamp server: $tsServer" -ForegroundColor Gray
    $SignArgs = "sign /v /a /s My /n `"$CertName`" /t $tsServer /fd sha256 `"$SysPath`" `"$CatPath`""
    $proc = Start-Process -FilePath $SignTool -ArgumentList $SignArgs -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host "   [OK] Signed successfully" -ForegroundColor Green
        $signed = $true
        break
    }
    Write-Host "   [WARN] Failed, trying next server..." -ForegroundColor Yellow
}

if (-not $signed) {
    Write-Host "[FAIL] All timestamp servers failed." -ForegroundColor Red
    # Rollback
    foreach ($store in $storesCheck) { certutil -delstore $store $CertName 2>&1 | Out-Null }
    if (Test-Path $CerPath) { Remove-Item $CerPath -Force }
    if (Test-Path $CatPath) { Remove-Item $CatPath -Force }
    exit 1
}

# Step 5: Install driver and create device node
Write-Host "[5/5] Installing driver..." -ForegroundColor Yellow

# Add driver to store
$pnpResult = pnputil /add-driver "$InfPath" /install 2>&1
$pnpExitCode = $LASTEXITCODE
Write-Host "   pnputil result:" -ForegroundColor Gray
foreach ($line in $pnpResult) { Write-Host "   $line" -ForegroundColor Gray }

if ($pnpExitCode -ne 0 -and $pnpExitCode -ne 259) {
    Write-Host "[FAIL] Driver installation failed (exit code: $pnpExitCode)" -ForegroundColor Red
    exit 1
}
Write-Host "   [OK] Driver added to store" -ForegroundColor Green

# For root-enumerated device, we need devcon or manual device creation
# Try devcon first
$devcon = Get-LatestTool "devcon.exe" "x64"
if (-not $devcon) {
    # Try WDK Tools directory
    $devcon = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\Tools" -Recurse -Filter "devcon.exe" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*x64*" } | Select-Object -First 1 -ExpandProperty FullName
}

if ($devcon) {
    Write-Host "   Creating device node with devcon..." -ForegroundColor Gray
    $devconResult = & $devcon install "$InfPath" "Root\virt2phys" 2>&1
    foreach ($line in $devconResult) { Write-Host "   $line" -ForegroundColor Gray }
    Write-Host "   [OK] Device node created" -ForegroundColor Green
} else {
    Write-Host "   [INFO] devcon.exe not found. Trying pnputil /add-device..." -ForegroundColor Yellow
    # Windows 10 20H2+ supports /add-device
    $addResult = pnputil /add-device "Root\virt2phys" 2>&1
    $addExitCode = $LASTEXITCODE
    foreach ($line in $addResult) { Write-Host "   $line" -ForegroundColor Gray }
    if ($addExitCode -ne 0) {
        Write-Host "   [WARN] pnputil /add-device failed. Manual device creation may be needed." -ForegroundColor Yellow
        Write-Host "   Alternative: Install WDK devcon tool, then run:" -ForegroundColor Yellow
        Write-Host "   devcon install $InfPath Root\virt2phys" -ForegroundColor White
    } else {
        Write-Host "   [OK] Device node created" -ForegroundColor Green
    }
}

# Verify
Write-Host ""
Write-Host "[Verify] Checking driver status..." -ForegroundColor Yellow
$svcStatus = sc.exe query virt2phys 2>&1
foreach ($line in $svcStatus) { Write-Host "   $line" -ForegroundColor Gray }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   virt2phys Driver Installation Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
