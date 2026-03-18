@echo off
D:
cd "D:\DPDK\01_Windows"

echo === Copying DPDK DLLs ===
copy /Y "dpdk-src\build\lib\*.dll" "." >nul 2>&1
copy /Y "dpdk-src\build\drivers\*.dll" "." >nul 2>&1
echo Done.

echo.
echo === Running DPDK Diagnostic (native, no CLR) ===
echo.
"D:\DPDK\01_Windows\dpdk_diag.exe" > "D:\DPDK\01_Windows\diag_output.txt" 2>&1
echo Exit code: %ERRORLEVEL% >> "D:\DPDK\01_Windows\diag_output.txt"
echo Exit code: %ERRORLEVEL%
echo.
echo Output saved to D:\DPDK\01_Windows\diag_output.txt
type "D:\DPDK\01_Windows\diag_output.txt"
pause
