$ErrorActionPreference = "Stop"

$DpdkRoot = "$PSScriptRoot\dpdk-src"
$BuildDir = "$DpdkRoot\build"
$DiagSrc = "$PSScriptRoot\DpdkShim\dpdk_diag.c"
$OutExe = "$PSScriptRoot\dpdk_diag.exe"

Write-Host ">>> Building DPDK Diagnostic Tool..." -ForegroundColor Cyan

# Include paths
$LibIncPaths = Get-ChildItem -Path "$DpdkRoot\lib" -Directory -Recurse | ForEach-Object { "-I$($_.FullName)" }
$WinEalInc = "-I$DpdkRoot\lib\eal\windows\include"
$X86EalInc = "-I$DpdkRoot\lib\eal\x86\include"

$LibPath = "$BuildDir\lib"
$DrvPath = "$BuildDir\drivers"

$ClangArgs = @(
    "-m64",
    "-march=native",
    "-mssse3",
    "-o", "$OutExe",
    "$DiagSrc",
    "-I$BuildDir",
    "-I$BuildDir\include",
    $WinEalInc,
    $X86EalInc,
    "-I$DpdkRoot\config"
)
$ClangArgs += $LibIncPaths

$ClangArgs += @(
    "-D__PCAP_LIB__",
    "-DRTE_MAX_ETHPORTS=32",
    "-D_WIN32",
    "$LibPath\rte_eal.lib",
    "$LibPath\rte_ethdev.lib",
    "$LibPath\rte_mbuf.lib",
    "$LibPath\rte_mempool.lib",
    "$LibPath\rte_net.lib",
    "$LibPath\rte_ring.lib",
    "$DrvPath\rte_bus_pci.lib",
    "$LibPath\rte_pci.lib",
    "$LibPath\rte_kvargs.lib",
    "$LibPath\rte_telemetry.lib",
    "$LibPath\rte_log.lib"
)

Write-Host "    Executing Clang..."
$proc = Start-Process -FilePath "clang" -ArgumentList $ClangArgs -Wait -NoNewWindow -PassThru -RedirectStandardError "$PSScriptRoot\diag_build_err.txt"

if ($proc.ExitCode -eq 0 -and (Test-Path $OutExe)) {
    Write-Host ">>> SUCCESS: $OutExe created." -ForegroundColor Green
} else {
    $errContent = Get-Content "$PSScriptRoot\diag_build_err.txt" -Raw -ErrorAction SilentlyContinue
    Write-Host ">>> BUILD FAILED (Exit Code: $($proc.ExitCode))." -ForegroundColor Red
    if ($errContent) { Write-Host $errContent -ForegroundColor Yellow }
}
