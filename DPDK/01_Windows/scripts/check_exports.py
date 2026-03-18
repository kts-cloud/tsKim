import subprocess
import sys

dll_path = r"D:\DPDK\01_Windows\Dpdk_Test_Tool\bin\Debug\net9.0-windows\rte_eal-26.dll"

# Use dumpbin from VS2022
import glob
dumpbin_paths = glob.glob(r"C:\Program Files\Microsoft Visual Studio\2022\*\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe")
dumpbin_paths += glob.glob(r"C:\Program Files (x86)\Microsoft Visual Studio\2022\*\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe")

# Also check BuildTools
dumpbin_paths += glob.glob(r"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe")
dumpbin_paths += glob.glob(r"C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe")

if dumpbin_paths:
    dumpbin = dumpbin_paths[0]
    print(f"Using: {dumpbin}")
    result = subprocess.run([dumpbin, "/exports", dll_path], capture_output=True, text=True)
    for line in result.stdout.split('\n'):
        if 'lcore' in line.lower():
            print(line)
    # Count total exports
    exports = [l for l in result.stdout.split('\n') if '  ' in l and 'rte_' in l]
    print(f"\nTotal rte_* exports: {len(exports)}")
    print("First 5:", exports[:5] if exports else "none")
else:
    print("dumpbin not found, trying alternative...")
    # Try to list exports using ctypes
    import ctypes
    import ctypes.wintypes
    try:
        dll = ctypes.WinDLL(dll_path)
        # Try specific function
        try:
            f = dll['rte_lcore_id_get']
            print("FOUND: rte_lcore_id_get")
        except:
            print("NOT FOUND: rte_lcore_id_get")
        try:
            f = dll['rte_lcore_id_set']
            print("FOUND: rte_lcore_id_set")
        except:
            print("NOT FOUND: rte_lcore_id_set")
        try:
            f = dll['rte_eal_init']
            print("FOUND: rte_eal_init")
        except:
            print("NOT FOUND: rte_eal_init")
    except Exception as e:
        print(f"Error: {e}")
