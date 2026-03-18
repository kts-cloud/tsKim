$targetDir = "D:\DPDK\01_Windows\Dpdk_Test_Tool\bin\Debug\net9.0-windows"
$dpdkBuildLib = "D:\DPDK\01_Windows\dpdk-src\build\lib"
$dpdkBuildDrv = "D:\DPDK\01_Windows\dpdk-src\build\drivers"
$shimDll = "D:\DPDK\01_Windows\hwio.dll"

# Copy shim
Copy-Item $shimDll $targetDir -Force
Write-Host "[OK] hwio.dll copied"

# Copy all DPDK DLLs from build/lib
$dllCount = 0
Get-ChildItem $dpdkBuildLib -Filter "*.dll" | ForEach-Object {
    Copy-Item $_.FullName $targetDir -Force
    $dllCount++
}
Write-Host "[OK] $dllCount DPDK lib DLLs copied"

# Copy driver DLLs
$drvCount = 0
Get-ChildItem $dpdkBuildDrv -Filter "*.dll" | ForEach-Object {
    Copy-Item $_.FullName $targetDir -Force
    $drvCount++
}
Write-Host "[OK] $drvCount driver DLLs copied"
