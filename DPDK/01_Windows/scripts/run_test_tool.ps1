<#
.SYNOPSIS
    Builds and Runs the DPDK Test Tool (TCP/UDP Tester).
#>

$ErrorActionPreference = "Stop"

# Paths
$ProjDir = "$PSScriptRoot\Dpdk_Test_Tool"
$ShimDll = "$PSScriptRoot\dpdk_shim.dll"

Write-Host ">>> Building DPDK Test Tool..." -ForegroundColor Cyan
dotnet build $ProjDir

$OutDir = "$ProjDir\bin\Debug\net9.0-windows"

# Copy Shim DLL
Write-Host ">>> Copying Shim DLL..."
if (Test-Path $ShimDll) {
    Copy-Item $ShimDll $OutDir -Force
} else {
    Write-Error "Shim DLL not found. Run 'build_shim.ps1' first."
}

# Copy DPDK core DLLs (prefer build directory - has latest exports)
$BuildLib = "$PSScriptRoot\dpdk-src\build\lib"
$BuildBin = "$PSScriptRoot\dpdk-src\build\bin"
if (Test-Path $BuildLib) {
    $LibDlls = Get-ChildItem "$BuildLib\rte_*-26.dll" -ErrorAction SilentlyContinue
    Write-Host ">>> Copying DPDK core DLLs from build/lib ($($LibDlls.Count) files)..." -ForegroundColor Yellow
    Copy-Item $LibDlls $OutDir -Force
}
if (Test-Path $BuildBin) {
    $BinDlls = Get-ChildItem "$BuildBin\*.dll" -ErrorAction SilentlyContinue
    if ($BinDlls) {
        Write-Host ">>> Copying DPDK bin DLLs ($($BinDlls.Count) files)..." -ForegroundColor Yellow
        Copy-Item $BinDlls $OutDir -Force
    }
}
if (-not (Test-Path "$OutDir\rte_eal-26.dll")) {
    # Fallback: try test project
    $DpdkDlls = Get-ChildItem "$PSScriptRoot\Dpdk_Windows_Test\bin\Debug\net9.0\rte_*-26.dll" -ErrorAction SilentlyContinue
    if ($DpdkDlls) {
        Write-Host ">>> Fallback: Copying DPDK DLLs from test project ($($DpdkDlls.Count) files)..." -ForegroundColor Yellow
        Copy-Item $DpdkDlls $OutDir -Force
    } else {
        Write-Warning "DPDK core DLLs not found."
    }
}

# Copy PMD driver DLLs (bus, net, mempool drivers required for NIC detection)
$DriversDir = "$PSScriptRoot\dpdk-src\build\drivers"
if (Test-Path $DriversDir) {
    $PmdDlls = Get-ChildItem "$DriversDir\rte_*-26.dll" -ErrorAction SilentlyContinue
    if ($PmdDlls) {
        Write-Host ">>> Copying PMD driver DLLs ($($PmdDlls.Count) files)..." -ForegroundColor Yellow
        Copy-Item $PmdDlls $OutDir -Force
    } else {
        Write-Warning "No PMD driver DLLs found in $DriversDir"
    }
} else {
    Write-Warning "DPDK drivers directory not found: $DriversDir"
}

Write-Host ">>> Running DPDK Test Tool (Admin Required)..." -ForegroundColor Green
Start-Process -FilePath "cmd.exe" -ArgumentList "/k `"cd /d $OutDir && Dpdk_Test_Tool.exe`"" -Verb RunAs
