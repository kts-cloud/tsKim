<#
.SYNOPSIS
    Builds and Runs the C# DPDK GUI Tester.
#>

$ErrorActionPreference = "Stop"

# Paths
$ProjDir = "$PSScriptRoot\Dpdk_Gui_Tester"

Write-host ">>> Building GUI Tester..." -ForegroundColor Cyan
dotnet build $ProjDir

$OutDir = "$ProjDir\bin\Debug\net9.0-windows" # Note: WinForms output path

Write-host ">>> Running GUI Tester..." -ForegroundColor Green
Start-Process -FilePath "$OutDir\Dpdk_Gui_Tester.exe"
