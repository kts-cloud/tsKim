<#
.SYNOPSIS
    Toggle Intel X550 NIC between DPDK (netuio) and default Intel driver.
.DESCRIPTION
    - Bind: Switch X550 to netuio driver (for DPDK packet processing)
    - Unbind: Remove netuio and restore original Intel driver (for normal networking)

    * Must run as Administrator!
.EXAMPLE
    .\toggle_x550.ps1 -Mode Bind
    .\toggle_x550.ps1 -Mode Unbind
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Bind", "Unbind")]
    [string]$Mode
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$X550_HWID = 'PCI\VEN_8086&DEV_1563'
$X550_HWID_MATCH = '*VEN_8086*DEV_1563*'
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

function Show-X550-Status {
    Write-Host ""
    Write-Host "--- Intel X550 Status ---" -ForegroundColor Gray
    $devices = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
        $_.HardwareID -like $X550_HWID_MATCH
    }
    if ($devices) {
        foreach ($dev in $devices) {
            Write-Host "    Device  : $($dev.FriendlyName)"
            Write-Host "    Class   : $($dev.Class)"
            Write-Host "    Status  : $($dev.Status)"
            Write-Host "    Instance: $($dev.InstanceId)"
        }
    } else {
        Write-Host "    X550 device not found." -ForegroundColor Yellow
    }
    Write-Host "-------------------------" -ForegroundColor Gray
    Write-Host ""
}

function Bind-Driver {
    Write-Host ">>> [BIND] Switching X550 to netuio (DPDK mode)..." -ForegroundColor Cyan

    if (-not (Test-Path $DriverInfPath)) {
        Write-Error "Driver INF not found: $DriverInfPath"
    }

    Show-X550-Status

    # 1. Try Devcon
    $Devcon = Find-Devcon
    if ($Devcon) {
        Write-Host "    [1] Updating driver via Devcon..."
        Write-Host "    Devcon: $Devcon"
        $devconArgs = 'update "' + $DriverInfPath + '" "' + $X550_HWID + '"'
        $proc = Start-Process -FilePath $Devcon -ArgumentList $devconArgs -Wait -NoNewWindow -PassThru

        Start-Sleep -Seconds 2

        if ($proc.ExitCode -eq 0) {
            $dev = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
                $_.HardwareID -like $X550_HWID_MATCH -and $_.Class -eq "Windows UIO"
            }
            if ($dev) {
                Write-Host "    [OK] X550 is now using netuio driver." -ForegroundColor Green
                Show-X550-Status
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
        $_.HardwareID -like $X550_HWID_MATCH -and $_.Class -eq "Windows UIO"
    }
    if ($dev) {
        Write-Host "    [OK] X550 is now using netuio driver." -ForegroundColor Green
    } else {
        Write-Host "    [FAIL] Auto-bind failed." -ForegroundColor Red
        Write-Host "    Manual steps:" -ForegroundColor Yellow
        Write-Host "    1. Open Device Manager (devmgmt.msc)"
        Write-Host "    2. Find Intel X550 under Network Adapters"
        Write-Host "    3. Right-click -> Update Driver -> Browse my computer"
        Write-Host "    4. Select: $([System.IO.Path]::GetDirectoryName($DriverInfPath))"
    }

    Show-X550-Status
}

function Unbind-Driver {
    Write-Host ">>> [UNBIND] Restoring original Intel driver..." -ForegroundColor Cyan

    Show-X550-Status

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
        $_.HardwareID -like $X550_HWID_MATCH
    }
    if ($dev) {
        if ($dev.Class -ne "Windows UIO") {
            Write-Host "    [OK] Original driver restored (Class: $($dev.Class))." -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] netuio may still be active. Try rebooting." -ForegroundColor Yellow
        }
    }

    Show-X550-Status
}

# --- Main ---
Assert-Admin

if ($Mode -eq "Bind") { Bind-Driver }
elseif ($Mode -eq "Unbind") { Unbind-Driver }
