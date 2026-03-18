<#
.SYNOPSIS
    Packs all DPDK driver DLLs + hwio.dll into an encrypted archive (drivers.dat).
.DESCRIPTION
    1. Collects all DLLs from dpdk-src/build/lib/, dpdk-src/build/drivers/, and hwio.dll
    2. Creates a ZIP archive in memory
    3. Encrypts with AES-256-CBC
    4. Outputs drivers.dat = [16 bytes IV] + [encrypted ZIP data]
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$BuildLib = "$ProjectRoot\dpdk-src\build\lib"
$BuildDrv = "$ProjectRoot\dpdk-src\build\drivers"
$HwioDll = "$ProjectRoot\hwio.dll"
$OutFile = "$ProjectRoot\drivers.dat"

# AES-256 key (32 bytes) — must match C# DeriveKey()
$KeyHex = "4F43494E53505F48574E45545F4B455931323334353637383941424344454647"
$Key = [byte[]]::new(32)
for ($i = 0; $i -lt 32; $i++) {
    $Key[$i] = [Convert]::ToByte($KeyHex.Substring($i * 2, 2), 16)
}

Write-Host ">>> Packing drivers into encrypted archive..." -ForegroundColor Cyan

# Create temp ZIP
$tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
try {
    # Collect all DLL files
    $dlls = @()
    if (Test-Path $BuildLib) {
        $dlls += Get-ChildItem $BuildLib -Filter "*.dll"
    }
    if (Test-Path $BuildDrv) {
        $dlls += Get-ChildItem $BuildDrv -Filter "*.dll"
    }
    if (Test-Path $HwioDll) {
        $dlls += Get-Item $HwioDll
    }

    Write-Host "    Found $($dlls.Count) DLL files"

    # Create ZIP
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($tempZip, 'Create')
    foreach ($dll in $dlls) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $dll.FullName, $dll.Name, 'Optimal') | Out-Null
    }
    $zip.Dispose()

    # Read ZIP bytes
    $zipBytes = [System.IO.File]::ReadAllBytes($tempZip)
    Write-Host "    ZIP size: $([math]::Round($zipBytes.Length / 1MB, 1)) MB"

    # Encrypt with AES-256-CBC
    Add-Type -AssemblyName System.Security
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.GenerateIV()
    $aes.Mode = 'CBC'
    $aes.Padding = 'PKCS7'

    $encryptor = $aes.CreateEncryptor()
    $encrypted = $encryptor.TransformFinalBlock($zipBytes, 0, $zipBytes.Length)

    # Write: [16 bytes IV] + [encrypted data]
    $output = New-Object byte[] (16 + $encrypted.Length)
    [Array]::Copy($aes.IV, 0, $output, 0, 16)
    [Array]::Copy($encrypted, 0, $output, 16, $encrypted.Length)
    [System.IO.File]::WriteAllBytes($OutFile, $output)

    $aes.Dispose()
    $encryptor.Dispose()

    Write-Host ">>> SUCCESS: $OutFile created ($([math]::Round($output.Length / 1MB, 1)) MB)" -ForegroundColor Green
}
finally {
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
}
