<#
.SYNOPSIS
    Builds and Runs the C# DPDK Echo Server.
#>

$ErrorActionPreference = "Stop"

# Paths
$ProjDir = "$PSScriptRoot\Dpdk_Echo_App"
$ShimDll = "$PSScriptRoot\dpdk_shim.dll"
$DpdkBin = "$PSScriptRoot\Dpdk_Windows_Test\bin\Debug\net9.0" # Reuse DLLs from previous build if available

Write-Host ">>> Building C# Echo App..." -ForegroundColor Cyan
dotnet build $ProjDir

$OutDir = "$ProjDir\bin\Debug\net9.0"

# Copy Shim DLL
Write-Host ">>> Copying Shim DLL..."
if (Test-Path $ShimDll) {
    Copy-Item $ShimDll $OutDir -Force
} else {
    Write-Error "Shim DLL not found. Run 'build_shim.ps1' first."
}

# Copy DPDK core DLLs (from build/bin or test project)
$DpdkDlls = Get-ChildItem "$PSScriptRoot\Dpdk_Windows_Test\bin\Debug\net9.0\*.dll" -ErrorAction SilentlyContinue
if ($DpdkDlls) {
    Copy-Item $DpdkDlls $OutDir -Force
} else {
    Write-Warning "DPDK DLLs not found in test project. Fetching from build..."
    Copy-Item "$PSScriptRoot\dpdk-src\build\bin\*.dll" $OutDir -Force
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

Write-Host ">>> Running Echo Server (Admin Required)..." -ForegroundColor Green
Start-Process -FilePath "cmd.exe" -ArgumentList "/k `"cd /d $OutDir && Dpdk_Echo_App.exe`"" -Verb RunAs
