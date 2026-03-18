<#
.SYNOPSIS
    Builds the DPDK Shim DLL for C# Interop.
.DESCRIPTION
    Compiles dpdk_shim.c using Clang and links against the existing DPDK build.
#>

$ErrorActionPreference = "Stop"

# Paths
$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$DpdkRoot = "$ProjectRoot\dpdk-src"
$BuildDir = "$DpdkRoot\build"
$ShimDir = "$ProjectRoot\DpdkShim"
$ShimSrc = "$ShimDir\hwio.c"
$NetifSrc = "$ShimDir\dpdk_netif.c"
$FtpSrc = "$ShimDir\dpdk_ftp_client.c"
$OutDll = "$ProjectRoot\hwio.dll"

# lwIP paths
$LwipDir = "$ShimDir\lwip-2.2.1\src"

# Check if DPDK is built
if (-not (Test-Path "$BuildDir\build.ninja")) {
    Write-Error "DPDK build not found at $BuildDir. Run setup_dpdk_windows.ps1 first."
}

Write-Host ">>> Building HW IO DLL..." -ForegroundColor Cyan

# Find all include paths dynamically
$LibIncPaths = Get-ChildItem -Path "$DpdkRoot\lib" -Directory -Recurse | ForEach-Object { "-I$($_.FullName)" }
$WinEalInc = "-I$DpdkRoot\lib\eal\windows\include"
$X86EalInc = "-I$DpdkRoot\lib\eal\x86\include"

# Linker Flags (Link against core DPDK libs)
# We need to link against: rte_eal.lib, rte_ethdev.lib, rte_mbuf.lib, rte_mempool.lib
$LibPath = "$BuildDir\lib"

# Gather lwIP source files
$LwipCoreSrcs = Get-ChildItem -Path "$LwipDir\core" -Filter "*.c" -File | ForEach-Object { $_.FullName }
$LwipIpv4Srcs = Get-ChildItem -Path "$LwipDir\core\ipv4" -Filter "*.c" -File | ForEach-Object { $_.FullName }
$LwipNetifSrcs = @("$LwipDir\netif\ethernet.c")

# Construct Argument List safely
$ClangArgs = @(
    "-shared",
    "-m64",
    "-march=native",
    "-mssse3",
    "-Wno-unused-parameter",
    "-Wno-unused-variable",
    "-o", "$OutDll",
    "$ShimSrc",
    "$NetifSrc",
    "$FtpSrc",
    "-I$ShimDir",
    "-I$ShimDir\arch",
    "-I$LwipDir\include",
    "-I$BuildDir",
    "-I$BuildDir\include",
    $WinEalInc,
    $X86EalInc,
    "-I$DpdkRoot\config"
)
$ClangArgs += $LwipCoreSrcs
$ClangArgs += $LwipIpv4Srcs
$ClangArgs += $LwipNetifSrcs
$ClangArgs += $LibIncPaths

$ClangArgs += @(
    "-D_CRT_SECURE_NO_WARNINGS",
    "-DSSIZE_MAX=9223372036854775807LL",
    "-D__PCAP_LIB__",
    "-DRTE_MAX_ETHPORTS=32",
    "-D_WIN32",
    "$LibPath\rte_eal.lib",
    "$LibPath\rte_ethdev.lib",
    "$LibPath\rte_mbuf.lib",
    "$LibPath\rte_mempool.lib",
    "$LibPath\rte_net.lib",
    "$LibPath\rte_ring.lib",
    "-L`"C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\um\x64`"",
    "-lAdvAPI32",
    "-Wl,/DEF:$ShimDir\hwio.def"
)

# Execute Clang
Write-Host "    Executing Clang..."
$proc = Start-Process -FilePath "clang" -ArgumentList $ClangArgs -Wait -NoNewWindow -PassThru

if ($proc.ExitCode -eq 0 -and (Test-Path $OutDll)) {
    Write-Host ">>> SUCCESS: $OutDll created." -ForegroundColor Green
    Write-Host "    Copy this DLL to your C# project's output directory."
} else {
    Write-Error ">>> BUILD FAILED (Exit Code: $($proc.ExitCode))."
}
