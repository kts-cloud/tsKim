<#
.SYNOPSIS
    One-click DPDK setup script for Intel X550 PC.
.DESCRIPTION
    Automates the full DPDK environment setup on a new Windows PC with Intel X550 NIC.
    Phase 1: Install prerequisites (Chocolatey, LLVM, Python, Git, VS Build Tools, .NET, WDK)
    Phase 2: System config (Lock Pages in Memory, TestSigning)
    Phase 3: Build DPDK (Meson + Ninja, Clang)
    Phase 4: Build Shim DLL (dpdk_shim.dll)
    Phase 5: Sign and install netuio driver
    Phase 6: Bind Intel X550 to netuio
    Phase 7: Build C# apps and deploy DLLs

    * Must run as Administrator!
    * Disable Secure Boot in BIOS before running.
.NOTES
    Target NIC: Intel X550 (PCI VEN_8086 DEV_1563)
    Date: 2026-02-12
#>

param(
    [switch]$SkipSoftwareInstall,
    [switch]$SkipDpdkBuild
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$X550_HWID = 'PCI\VEN_8086&DEV_1563'
$X550_HWID_MATCH = '*VEN_8086*DEV_1563*'

# ============================================================
# Utility Functions
# ============================================================

function Write-Step {
    param([string]$Phase, [string]$Message)
    Write-Host ""
    Write-Host ">>> [$Phase] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "    [SKIP] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "    [FAIL] $Message" -ForegroundColor Red
}

function Assert-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator."
    }
}

function Assert-SecureBootOff {
    try {
        if (Confirm-SecureBootUEFI) {
            Write-Host ""
            Write-Host "!!! SECURE BOOT가 활성화되어 있습니다 !!!" -ForegroundColor Red
            Write-Host "    testsigning은 Secure Boot OFF에서만 동작합니다." -ForegroundColor Red
            Write-Host "    Secure Boot ON + testsigning → 부팅 불가 위험!" -ForegroundColor Red
            Write-Host ""
            Write-Host "    BIOS → Security → Secure Boot → Disabled 후 다시 실행하세요." -ForegroundColor Yellow
            exit 1
        }
        Write-Ok "Secure Boot OFF 확인됨"
    } catch {
        # Confirm-SecureBootUEFI 사용 불가 시 (Legacy BIOS 등) 경고만
        Write-Host "    [INFO] Secure Boot 상태 확인 불가 (Legacy BIOS일 수 있음)" -ForegroundColor Gray
    }
}

function Reload-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ============================================================
# Phase 1: Install Prerequisites
# ============================================================

function Install-Prerequisites {
    Write-Step "Phase 1" "Install prerequisites"

    if ($SkipSoftwareInstall) {
        Write-Skip "Software install skipped (-SkipSoftwareInstall)"
        return
    }

    # 1-1. Chocolatey
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "    Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Reload-Path
    } else {
        Write-Ok "Chocolatey already installed"
    }

    # 1-2. Git, Python, LLVM/Clang
    Write-Host "    Installing Git, Python, LLVM..."
    choco install git python llvm -y
    Reload-Path

    # 1-3. Visual Studio 2022 Build Tools
    Write-Host "    Installing VS2022 Build Tools (this may take a while)..."
    choco install visualstudio2022buildtools -y --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    Reload-Path

    # 1-4. .NET 9.0 SDK
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue) -or -not (dotnet --list-sdks | Select-String "9\.0")) {
        Write-Host "    Installing .NET 9.0 SDK..."
        choco install dotnet-sdk -y
        Reload-Path
    } else {
        Write-Ok ".NET SDK already installed"
    }

    # 1-5. Python packages
    Write-Host "    Installing Python packages (Meson, Ninja, Pyelftools)..."
    pip install meson ninja pyelftools

    # 1-6. WDK (for netuio signing)
    Write-Host "    Checking Windows Driver Kit..."
    $wdkInstalled = Test-Path "C:\Program Files (x86)\Windows Kits\10\bin"
    if (-not $wdkInstalled) {
        try {
            Write-Host "    Installing WDK via winget..."
            winget install -e --id Microsoft.WindowsDriverKit --accept-source-agreements --accept-package-agreements
            Write-Ok "WDK installed (winget)"
        } catch {
            Write-Fail "WDK auto-install failed. Manual install: https://go.microsoft.com/fwlink/?linkid=2196230"
        }
    } else {
        Write-Ok "WDK already installed"
    }

    Write-Ok "Phase 1 complete"
}

# ============================================================
# Phase 2: System Configuration
# ============================================================

function Configure-System {
    Write-Step "Phase 2" "System config (Lock Pages in Memory, TestSigning)"

    # 2-1. Lock Pages in Memory
    Write-Host "    Granting 'Lock pages in memory' privilege..."
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $tmpCfg = "$env:TEMP\secpol_dpdk.cfg"
    $tmpDb = "$env:TEMP\secpol_dpdk.sdb"

    secedit /export /cfg $tmpCfg /quiet
    $content = Get-Content $tmpCfg
    $newLine = "SeLockMemoryPrivilege = *S-1-5-32-544,$user"

    if ($content -match "SeLockMemoryPrivilege") {
        if ($content -match [regex]::Escape($user)) {
            Write-Ok "Lock pages in memory - already granted"
        } else {
            $content = $content -replace "SeLockMemoryPrivilege.*", $newLine
        }
    } else {
        $idx = ($content | Select-String "\[Privilege Rights\]").LineNumber
        if ($idx) {
            $content = $content[0..$idx] + $newLine + $content[($idx+1)..($content.Length-1)]
        }
    }

    Set-Content $tmpCfg $content
    secedit /configure /db $tmpDb /cfg $tmpCfg /areas USER_RIGHTS /quiet
    Remove-Item $tmpCfg -ErrorAction SilentlyContinue
    Remove-Item $tmpDb -ErrorAction SilentlyContinue
    Write-Ok "Lock Pages in Memory configured"

    # 2-2. TestSigning
    Write-Host "    Enabling TestSigning..."

    # 안전 가드: Secure Boot 상태 검사
    Assert-SecureBootOff

    # 안전 가드: 시스템 복원 지점 생성
    Write-Host "    시스템 복원 지점 생성 중..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Before DPDK TestSigning" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Ok "복원 지점 생성 완료"
    } catch {
        Write-Host "    [WARN] 복원 지점 생성 실패: $_" -ForegroundColor Yellow
        Write-Host "    (계속 진행합니다)" -ForegroundColor Yellow
    }

    # TestSigning 설정
    $result = bcdedit /set testsigning on 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "bcdedit 실행 실패: $result"
        Write-Host "    BCD 저장소가 손상되었을 수 있습니다." -ForegroundColor Red
        throw "bcdedit failed"
    }
    Write-Ok "TestSigning enabled (requires reboot)"

    Write-Ok "Phase 2 complete"
}

# ============================================================
# Phase 3: Build DPDK
# ============================================================

function Build-Dpdk {
    Write-Step "Phase 3" "Build DPDK (Meson + Ninja)"

    if ($SkipDpdkBuild) {
        Write-Skip "DPDK build skipped (-SkipDpdkBuild)"
        return
    }

    $DpdkSrc = "$ScriptRoot\dpdk-src"

    if (-not (Test-Path "$DpdkSrc\meson.build")) {
        Write-Host "    Cloning DPDK source..."
        git clone http://dpdk.org/git/dpdk "$DpdkSrc"
    }

    # Clean old build (prevents cross-PC env conflicts)
    $BuildDir = "$DpdkSrc\build"
    if (Test-Path $BuildDir) {
        Write-Host "    Removing old build directory..."
        Remove-Item -Path $BuildDir -Recurse -Force
    }

    $env:CC = "clang"
    $env:CXX = "clang"

    Write-Host "    Running Meson setup..."
    Push-Location $DpdkSrc
    try {
        meson setup build --default-library=shared
        Write-Host "    Compiling (this will take a while)..."
        ninja -C build
        Write-Ok "DPDK build successful"
    } catch {
        Write-Fail "DPDK build failed: $_"
        throw
    } finally {
        Pop-Location
    }

    if (Test-Path "$BuildDir\examples\dpdk-helloworld.exe") {
        Write-Ok "dpdk-helloworld.exe found"
    } else {
        Write-Fail "dpdk-helloworld.exe not found"
    }
}

# ============================================================
# Phase 4: Build Shim DLL
# ============================================================

function Build-ShimDll {
    Write-Step "Phase 4" "Build dpdk_shim.dll"

    $DpdkRoot = "$ScriptRoot\dpdk-src"
    $BuildDir = "$DpdkRoot\build"
    $ShimSrc = "$ScriptRoot\DpdkShim\dpdk_shim.c"
    $OutDll = "$ScriptRoot\dpdk_shim.dll"

    if (-not (Test-Path "$BuildDir\build.ninja")) {
        Write-Fail "DPDK must be built first"
        return
    }

    if (-not (Test-Path $ShimSrc)) {
        Write-Fail "dpdk_shim.c not found: $ShimSrc"
        return
    }

    $LibIncPaths = Get-ChildItem -Path "$DpdkRoot\lib" -Directory -Recurse | ForEach-Object { "-I$($_.FullName)" }

    $ClangArgs = @(
        "-shared", "-m64", "-march=native", "-mssse3",
        "-o", "$OutDll",
        "$ShimSrc",
        "-I$BuildDir", "-I$BuildDir\include",
        "-I$DpdkRoot\lib\eal\windows\include",
        "-I$DpdkRoot\lib\eal\x86\include",
        "-I$DpdkRoot\config"
    )
    $ClangArgs += $LibIncPaths
    $ClangArgs += @(
        "-D__PCAP_LIB__", "-DRTE_MAX_ETHPORTS=32", "-D_WIN32",
        "$BuildDir\lib\rte_eal.lib",
        "$BuildDir\lib\rte_ethdev.lib",
        "$BuildDir\lib\rte_mbuf.lib",
        "$BuildDir\lib\rte_mempool.lib",
        "$BuildDir\lib\rte_net.lib"
    )

    Write-Host "    Compiling with Clang..."
    $proc = Start-Process -FilePath "clang" -ArgumentList $ClangArgs -Wait -NoNewWindow -PassThru

    if ($proc.ExitCode -eq 0 -and (Test-Path $OutDll)) {
        Write-Ok "dpdk_shim.dll created: $OutDll"
    } else {
        Write-Fail "Shim DLL build failed (Exit Code: $($proc.ExitCode))"
    }
}

# ============================================================
# Phase 5: Sign and Install netuio Driver
# ============================================================

function Install-NetuioDriver {
    Write-Step "Phase 5" "Sign and install netuio driver"

    $DriverDir = "$ScriptRoot\dpdk-kmods\windows\netuio\x64\Release\netuio"
    $InfPath = "$DriverDir\netuio.inf"
    $SysPath = "$DriverDir\netuio.sys"
    $CatPath = "$DriverDir\netuio.cat"
    $CerPath = "$DriverDir\netuio.cer"
    $CertName = "DPDK_NetUIO_TestCert"

    if (-not (Test-Path $SysPath)) {
        Write-Fail "netuio.sys not found: $SysPath"
        Write-Host "    Check that dpdk-kmods folder was copied correctly."
        return
    }

    # Find WDK tools
    function Get-WdkTool {
        param($Name, $Arch="x64")
        $results = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter $Name -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*$Arch*" }
        if (-not $results) {
            $results = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\Tools" -Recurse -Filter $Name -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*$Arch*" }
        }
        if (-not $results) {
            $results = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter $Name -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*$Arch*" }
        }
        return $results | Sort-Object FullName | Select-Object -Last 1 -ExpandProperty FullName
    }

    $Inf2Cat = Get-WdkTool "Inf2Cat.exe" "x86"
    $SignTool = Get-WdkTool "signtool.exe" "x64"
    $MakeCert = Get-WdkTool "makecert.exe" "x64"

    if (-not $Inf2Cat -or -not $SignTool -or -not $MakeCert) {
        Write-Fail "WDK tools not found (Inf2Cat, SignTool, MakeCert)"
        Write-Host "    Install WDK: winget install -e --id Microsoft.WindowsDriverKit"
        return
    }

    Write-Host "    Inf2Cat : $Inf2Cat"
    Write-Host "    SignTool: $SignTool"
    Write-Host "    MakeCert: $MakeCert"

    # Remove old catalog for regeneration
    if (Test-Path $CatPath) { Remove-Item $CatPath -Force }

    # 5-1. Generate catalog
    Write-Host "    Generating catalog file..."
    $inf2catArgs = '/driver:"' + $DriverDir + '" /os:10_X64'
    $proc = Start-Process -FilePath $Inf2Cat -ArgumentList $inf2catArgs -Wait -NoNewWindow -PassThru
    if (-not (Test-Path $CatPath)) {
        Write-Fail "Catalog generation failed"
        return
    }

    # 5-2. Create self-signed certificate
    Write-Host "    Creating self-signed certificate..."
    if (Test-Path $CerPath) { Remove-Item $CerPath -Force }
    $makeCertArgs = '-r -pe -ss My -n "CN=' + $CertName + '" "' + $CerPath + '"'
    Start-Process -FilePath $MakeCert -ArgumentList $makeCertArgs -Wait -NoNewWindow

    if (-not (Test-Path $CerPath)) {
        Write-Fail "Certificate creation failed"
        return
    }

    # 5-3. Trust the certificate
    Write-Host "    Adding certificate to trusted stores..."
    $certUtilArgs1 = '-addstore -f Root "' + $CerPath + '"'
    $certUtilArgs2 = '-addstore -f TrustedPublisher "' + $CerPath + '"'
    Start-Process -FilePath "certutil.exe" -ArgumentList $certUtilArgs1 -Wait -NoNewWindow
    Start-Process -FilePath "certutil.exe" -ArgumentList $certUtilArgs2 -Wait -NoNewWindow

    # 5-4. Sign driver
    Write-Host "    Signing driver files..."
    $signArgs = 'sign /v /a /s My /n "' + $CertName + '" /t http://timestamp.digicert.com /fd sha256 "' + $SysPath + '" "' + $CatPath + '"'
    $proc = Start-Process -FilePath $SignTool -ArgumentList $signArgs -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Fail "Driver signing failed (Exit Code: $($proc.ExitCode))"
        return
    }

    # 5-5. Install driver
    Write-Host "    Installing driver via pnputil..."
    pnputil /add-driver "$InfPath" /install

    Write-Ok "netuio driver installed"
}

# ============================================================
# Phase 6: Bind Intel X550 to netuio
# ============================================================

function Bind-X550 {
    Write-Step "Phase 6" "Bind Intel X550 to netuio driver"

    $DriverInfPath = "$ScriptRoot\dpdk-kmods\windows\netuio\x64\Release\netuio\netuio.inf"

    # Detect X550 devices
    Write-Host "    Searching for Intel X550..."
    $x550Devices = Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | Where-Object {
        $_.HardwareID -like $X550_HWID_MATCH
    }

    if (-not $x550Devices) {
        $allDevices = pnputil /enum-devices /class Net 2>&1
        if ("$allDevices" -match "1563") {
            Write-Host "    X550 found (pnputil)"
        } else {
            Write-Fail "Intel X550 not found."
            Write-Host "    Check Device Manager. Manual bind: .\toggle_x550.ps1 -Mode Bind"
            return
        }
    } else {
        foreach ($dev in $x550Devices) {
            Write-Host "    Found: $($dev.FriendlyName) [$($dev.InstanceId)]"
        }
    }

    # Find devcon.exe
    $Devcon = $null
    $devconSearchBase = "C:\Program Files (x86)\Windows Kits\10\Tools"
    if (Test-Path $devconSearchBase) {
        $Devcon = Get-ChildItem $devconSearchBase -Recurse -Filter "devcon.exe" -ErrorAction SilentlyContinue |
                  Where-Object { $_.FullName -like "*x64*" } |
                  Sort-Object FullName |
                  Select-Object -Last 1 -ExpandProperty FullName
    }

    if ($Devcon) {
        Write-Host "    Devcon: $Devcon"
        Write-Host "    Binding to netuio..."
        $devconArgs = 'update "' + $DriverInfPath + '" "' + $X550_HWID + '"'
        $proc = Start-Process -FilePath $Devcon -ArgumentList $devconArgs -Wait -NoNewWindow -PassThru

        if ($proc.ExitCode -eq 0) {
            Write-Ok "X550 bound to netuio successfully"
            return
        } else {
            Write-Host "    Devcon failed (ExitCode: $($proc.ExitCode)), trying pnputil..." -ForegroundColor Yellow
        }
    }

    # Fallback: pnputil
    Write-Host "    Trying pnputil install..."
    pnputil /add-driver "$DriverInfPath" /install
    pnputil /scan-devices

    Start-Sleep -Seconds 3

    # Verify
    $uioDevices = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
        $_.HardwareID -like $X550_HWID_MATCH -and $_.Class -eq "Windows UIO"
    }
    if ($uioDevices) {
        Write-Ok "X550 bound to netuio successfully"
    } else {
        Write-Fail "Auto-bind failed. Update driver manually in Device Manager."
        Write-Host "    Right-click X550 NIC -> Update Driver -> Browse -> select netuio folder"
    }
}

# ============================================================
# Phase 7: Build C# Apps
# ============================================================

function Build-CSharpApps {
    Write-Step "Phase 7" "Build C# apps and deploy DLLs"

    $DpdkBuildLib = "$ScriptRoot\dpdk-src\build\lib"
    $ShimDll = "$ScriptRoot\dpdk_shim.dll"

    $projects = @(
        @{ Name = "Dpdk_Windows_Test"; Path = "$ScriptRoot\Dpdk_Windows_Test\Dpdk_Windows_Test.csproj"; OutSuffix = "net9.0" },
        @{ Name = "Dpdk_Echo_App"; Path = "$ScriptRoot\Dpdk_Echo_App\Dpdk_Echo_App.csproj"; OutSuffix = "net9.0" },
        @{ Name = "Dpdk_Gui_Tester"; Path = "$ScriptRoot\Dpdk_Gui_Tester\Dpdk_Gui_Tester.csproj"; OutSuffix = "net9.0-windows" }
    )

    foreach ($proj in $projects) {
        if (-not (Test-Path $proj.Path)) {
            Write-Skip "$($proj.Name) project not found"
            continue
        }

        Write-Host "    Building $($proj.Name)..."
        try {
            dotnet build $proj.Path --configuration Debug
            $projDir = [System.IO.Path]::GetDirectoryName($proj.Path)
            $outDir = Join-Path $projDir ("bin\Debug\" + $proj.OutSuffix)

            # Copy DPDK DLLs
            if (Test-Path $DpdkBuildLib) {
                Copy-Item "$DpdkBuildLib\*.dll" $outDir -Force -ErrorAction SilentlyContinue
            }

            # Copy Shim DLL
            if (Test-Path $ShimDll) {
                Copy-Item $ShimDll $outDir -Force
            }

            Write-Ok "$($proj.Name) built and DLLs deployed"
        } catch {
            Write-Fail "$($proj.Name) build failed: $_"
        }
    }
}

# ============================================================
# Main Execution
# ============================================================

Assert-Admin

$startTime = Get-Date

Write-Host ""
Write-Host "========================================================" -ForegroundColor Magenta
Write-Host "   Intel X550 PC - DPDK One-Click Setup" -ForegroundColor Magenta
Write-Host "   Target NIC: Intel X550-T1/T2 (10GBASE-T)" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta
Write-Host ""

# Check if TestSigning is already active
$tsStatus = bcdedit /enum 2>&1 | Select-String "testsigning"
$needReboot = $false

# --- Phase 1 ---
Install-Prerequisites

# --- Phase 2 ---
Configure-System

if (-not ("$tsStatus" -match "Yes")) {
    $needReboot = $true
}

# --- Phase 3 ---
Build-Dpdk

# --- Phase 4 ---
Build-ShimDll

# --- Phase 5 ---
Install-NetuioDriver

# --- Phase 6 ---
Bind-X550

# --- Phase 7 ---
Build-CSharpApps

# ============================================================
# Summary
# ============================================================

$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "   SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "   Elapsed: $($elapsed.ToString('hh\:mm\:ss'))"
Write-Host ""

if ($needReboot) {
    Write-Host "   ** REBOOT REQUIRED **" -ForegroundColor Red
    Write-Host "   TestSigning and Lock Pages in Memory need reboot to take effect." -ForegroundColor Red
    Write-Host ""
    Write-Host "   After reboot:" -ForegroundColor Yellow
    Write-Host "   1. Check Device Manager: X550 should be under 'Windows UIO'" -ForegroundColor Yellow
    Write-Host "   2. If not: .\toggle_x550.ps1 -Mode Bind" -ForegroundColor Yellow
    Write-Host "   3. Test: .\run_echo.ps1" -ForegroundColor Yellow
} else {
    Write-Host "   Test echo server: .\run_echo.ps1" -ForegroundColor Yellow
    Write-Host "   Toggle NIC: .\toggle_x550.ps1 -Mode Bind or Unbind" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
