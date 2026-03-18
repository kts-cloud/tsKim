@echo off
D:
cd "D:\DPDK\01_Windows\Dpdk_Test_Tool\bin\Debug\net9.0-windows"
"D:\DPDK\01_Windows\Dpdk_Test_Tool\bin\Debug\net9.0-windows\Dpdk_Test_Tool.exe" 2> "D:\DPDK\01_Windows\shim_debug.txt"
echo Exit code: %ERRORLEVEL%
pause
