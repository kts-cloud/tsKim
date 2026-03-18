<#
.SYNOPSIS
    Toggles the Realtek USB NIC driver between DPDK (netuio) and Default (Realtek).
    v2.0 - Improved Devcon detection and Aggressive Binding
    
.DESCRIPTION
    - Bind: Forces netuio driver using Devcon. If that fails, temporarily removes the current driver to allow netuio.
    - Unbind: Removes netuio, restoring the original driver.
    
    * Must be run as Administrator.

.EXAMPLE
    .\toggle_netuio.ps1 -Mode Bind
    .\toggle_netuio.ps1 -Mode Unbind
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Bind", "Unbind")]
    [string]$Mode
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$HardwareId = "USB\VID_0BDA&PID_8152"
$DriverInfPath = "$PSScriptRoot\dpdk-kmods\windows\netuio\x64\Release\netuio\netuio.inf"
# Explicit path to Devcon (from your environment)
$DevconPath = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.22621.0\x64\devcon.exe"
# ---------------------

function Check-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script requires Administrator privileges. Please run as Admin."
    }
}

function Get-Active-Driver-Inf {
    param($HwId)
    $dev = pnputil /enum-devices /instanceid $HwId /drivers
    # Parse output to find the active "Original Name" or "Published Name"
    # This is a bit tricky with text parsing, simplifying to find the published name (oemXX.inf)
    if ($dev -match "oem(\d+)\.inf") {
        return "oem$($matches[1]).inf"
    }
    return $null
}

function Bind-Driver {
    Write-Host ">>> [BIND] Switching to DPDK (netuio) mode..." -ForegroundColor Cyan
    
    if (-not (Test-Path $DriverInfPath)) {
        Write-Error "Driver INF file not found at: $DriverInfPath"
    }

    # 1. Try Devcon Update (The standard forced way)
    if (Test-Path $DevconPath) {
        Write-Host "1. Attempting 'devcon update'..." -ForegroundColor Yellow
        $proc = Start-Process -FilePath $DevconPath -ArgumentList "update `"$DriverInfPath`" `"$HardwareId`"" -Wait -NoNewWindow -PassThru
        
        if ($proc.ExitCode -eq 0) {
            Write-Host "   Devcon reported success." -ForegroundColor Green
        } else {
            Write-Warning "   Devcon failed (ExitCode: $($proc.ExitCode))."
        }
    } else {
        Write-Warning "   Devcon.exe not found at $DevconPath. Skipping Devcon attempt."
    }

    # 2. Check Result
    Start-Sleep -Seconds 2
    $devStatus = pnputil /enum-devices /instanceid $HardwareId
    if ($devStatus -match "netuio.inf" -or $devStatus -match "Windows UIO") {
        Write-Host "   SUCCESS: Device is now using netuio driver." -ForegroundColor Green
        return
    }

    # 3. Aggressive Fallback: Uninstall current driver to force netuio
    Write-Host "2. [Fallback] Current driver stubbornly remains. Trying aggressive switch..." -ForegroundColor Magenta
    
    $currentInf = Get-Active-Driver-Inf -HwId $HardwareId
    if ($currentInf -and $currentInf -notlike "*netuio*") {
        Write-Host "   Uninstalling active driver: $currentInf (Don't worry, Windows will restore it later)" -ForegroundColor Yellow
        pnputil /delete-driver $currentInf /uninstall /force
    }

    Write-Host "   Installing netuio..."
    pnputil /add-driver "$DriverInfPath" /install

    Write-Host "   Rescanning hardware..."
    pnputil /scan-devices
    Start-Sleep -Seconds 2

    # 4. Final Check
    $devStatus = pnputil /enum-devices /instanceid $HardwareId
    if ($devStatus -match "netuio.inf" -or $devStatus -match "Windows UIO") {
        Write-Host "   SUCCESS: Device is now using netuio driver." -ForegroundColor Green
    } else {
        Write-Error "   FAILED: Could not force netuio driver. Please update manually in Device Manager."
    }
}

function Unbind-Driver {
    Write-Host ">>> [UNBIND] Restoring Original Driver..." -ForegroundColor Cyan

    Write-Host "1. Removing all netuio drivers..." -ForegroundColor Yellow
    # Capture matches first
    $oemInfs = pnputil /enum-drivers | Select-String "netuio.inf" -Context 5,1
    
    if (-not $oemInfs) {
        Write-Host "   No active netuio driver packages found." -ForegroundColor Green
    }

    foreach ($matchObj in $oemInfs) {
        # PreContext is an array of lines. Iterate to find the line containing "oemXX.inf"
        foreach ($line in $matchObj.Context.PreContext) {
            if ($line -match "(oem\d+\.inf)") {
                $infName = $matches[1]
                Write-Host "   Found package: $infName"
                
                Write-Host "   Removing $infName..."
                pnputil /delete-driver $infName /uninstall /force
            }
        }
    }

    Write-Host "2. Rescanning..."
    pnputil /scan-devices
    Start-Sleep -Seconds 1
    
    $devStatus = pnputil /enum-devices /instanceid $HardwareId
    if ($devStatus -notmatch "netuio.inf") {
        Write-Host "   SUCCESS: Original driver restored." -ForegroundColor Green
    } else {
         Write-Host "   WARNING: netuio might still be active." -ForegroundColor Magenta
    }
}

Check-Admin
if ($Mode -eq "Bind") { Bind-Driver }
elseif ($Mode -eq "Unbind") { Unbind-Driver }