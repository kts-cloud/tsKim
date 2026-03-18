<#
.SYNOPSIS
    Toggle Intel I226 NIC between DPDK (netuio) and default Intel driver.
.DESCRIPTION
    - Bind: Switch I226-V to netuio driver (for DPDK packet processing)
    - Unbind: Remove netuio and restore original Intel driver (for normal networking)

    * Must run as Administrator!
.EXAMPLE
    .\toggle_i226.ps1 -Mode Bind
    .\toggle_i226.ps1 -Mode Unbind
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Bind", "Unbind")]
    [string]$Mode
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
# Intel I226-V (DEV_125C). I226-LM (DEV_125B) is left for normal networking.
$NIC_HWID = 'PCI\VEN_8086&DEV_125C'
$NIC_HWID_MATCH = '*VEN_8086*DEV_125C*'
$NIC_NAME = "Intel I226-V"
$DriverInfPath = "$PSScriptRoot\dpdk-kmods\windows\netuio\x64\Release\netuio\netuio.inf"
# ---------------------

function Assert-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script requires Administrator privileges."
    }
}

function Find-Devcon {
    $searchBase = "C:\Program Files (x86)\Windows Kits\10\Tools"
    if (Test-Path $searchBase) {
        $found = Get-ChildItem $searchBase -Recurse -Filter "devcon.exe" -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -like "*x64*" } |
                 Sort-Object FullName |
                 Select-Object -Last 1 -ExpandProperty FullName
        if ($found) { return $found }
    }
    return $null
}

function Show-NIC-Status {
    Write-Host ""
    Write-Host "--- $NIC_NAME Status ---" -ForegroundColor Gray
    $devices = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
        $_.HardwareID -like $NIC_HWID_MATCH
    }
    if ($devices) {
        foreach ($dev in $devices) {
            Write-Host "    Device  : $($dev.FriendlyName)"
            Write-Host "    Class   : $($dev.Class)"
            Write-Host "    Status  : $($dev.Status)"
            Write-Host "    Instance: $($dev.InstanceId)"
            Write-Host ""
        }
    } else {
        Write-Host "    $NIC_NAME device not found." -ForegroundColor Yellow
    }
    Write-Host "-------------------------" -ForegroundColor Gray
    Write-Host ""
}

function Bind-Driver {
    Write-Host ">>> [BIND] Switching $NIC_NAME to netuio (DPDK mode)..." -ForegroundColor Cyan

    if (-not (Test-Path $DriverInfPath)) {
        Write-Error "Driver INF not found: $DriverInfPath"
    }

    Show-NIC-Status

    # 1. Try Devcon
    $Devcon = Find-Devcon
    if ($Devcon) {
        Write-Host "    [1] Updating driver via Devcon..."
        Write-Host "    Devcon: $Devcon"
        $devconArgs = 'update "' + $DriverInfPath + '" "' + $NIC_HWID + '"'
        $proc = Start-Process -FilePath $Devcon -ArgumentList $devconArgs -Wait -NoNewWindow -PassThru

        Start-Sleep -Seconds 2

        if ($proc.ExitCode -eq 0) {
            $dev = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
                $_.HardwareID -like $NIC_HWID_MATCH -and $_.Class -eq "Windows UIO"
            }
            if ($dev) {
                Write-Host "    [OK] $NIC_NAME is now using netuio driver." -ForegroundColor Green
                Show-NIC-Status
                return
            }
        }
        Write-Host "    Devcon failed (ExitCode: $($proc.ExitCode)), trying fallback..." -ForegroundColor Yellow
    } else {
        Write-Host "    Devcon not found. Using fallback method." -ForegroundColor Yellow
    }

    # 2. Fallback: pnputil install
    Write-Host "    [2] Installing netuio via pnputil..."
    pnputil /add-driver "$DriverInfPath" /install
    pnputil /scan-devices
    Start-Sleep -Seconds 3

    # 3. Verify
    $dev = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
        $_.HardwareID -like $NIC_HWID_MATCH -and $_.Class -eq "Windows UIO"
    }
    if ($dev) {
        Write-Host "    [OK] $NIC_NAME is now using netuio driver." -ForegroundColor Green
    } else {
        Write-Host "    [FAIL] Auto-bind failed." -ForegroundColor Red
        Write-Host "    Manual steps:" -ForegroundColor Yellow
        Write-Host "    1. Open Device Manager (devmgmt.msc)"
        Write-Host "    2. Find $NIC_NAME under Network Adapters"
        Write-Host "    3. Right-click -> Update Driver -> Browse my computer"
        Write-Host "    4. Select: $([System.IO.Path]::GetDirectoryName($DriverInfPath))"
    }

    Show-NIC-Status
}

function Unbind-Driver {
    Write-Host ">>> [UNBIND] Restoring original Intel driver..." -ForegroundColor Cyan

    Show-NIC-Status

    # 1. Remove all netuio driver packages
    Write-Host "    [1] Removing netuio driver packages..."
    $drvOutput = pnputil /enum-drivers 2>&1
    $lines = "$drvOutput" -split "`n"

    $currentOem = $null
    foreach ($line in $lines) {
        if ($line -match "(oem\d+\.inf)") {
            $currentOem = $matches[1]
        }
        if ($line -match "netuio" -and $currentOem) {
            Write-Host "    Removing: $currentOem"
            pnputil /delete-driver $currentOem /uninstall /force 2>&1 | Out-Null
            $currentOem = $null
        }
    }

    # 2. Rescan hardware
    Write-Host "    [2] Rescanning hardware..."
    pnputil /scan-devices
    Start-Sleep -Seconds 3

    # 3. Verify
    $dev = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
        $_.HardwareID -like $NIC_HWID_MATCH
    }
    if ($dev) {
        if ($dev.Class -ne "Windows UIO") {
            Write-Host "    [OK] Original driver restored (Class: $($dev.Class))." -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] netuio may still be active. Try rebooting." -ForegroundColor Yellow
        }
    }

    Show-NIC-Status
}

# --- Main ---
Assert-Admin

if ($Mode -eq "Bind") { Bind-Driver }
elseif ($Mode -eq "Unbind") { Unbind-Driver }
