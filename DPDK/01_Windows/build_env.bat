@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64 >/dev/null 2>&1
echo INCLUDE_VAR=%INCLUDE%
powershell -ExecutionPolicy Bypass -File "D:\Dongaeltek\_Project\04_VHOLED\_Project\SW\ITOLED_OC\DPDK\01_Windows\scripts\build_shim.ps1"
