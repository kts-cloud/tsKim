using System.IO.Compression;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using Microsoft.Win32.SafeHandles;
using HwNet.Interop;
using HwNet.Models;
using HwNet.Utilities;

namespace HwNet
{
    public sealed class HwManager : IHwContext, IDisposable
    {
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
        private static extern IntPtr LoadLibraryA(string lpFileName);

        [DllImport("kernel32.dll")]
        private static extern bool FreeLibrary(IntPtr hModule);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool SetDllDirectoryW(string? lpPathName);

        [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
        private static extern uint GetModuleFileNameA(IntPtr hModule, byte[] lpFilename, uint nSize);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern SafeFileHandle CreateFileW(
            string lpFileName, uint dwDesiredAccess, uint dwShareMode,
            IntPtr lpSecurityAttributes, uint dwCreationDisposition,
            uint dwFlagsAndAttributes, IntPtr hTemplateFile);

        [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr SetupDiGetClassDevsW(
            ref Guid classGuid, IntPtr enumerator, IntPtr hwndParent, uint flags);

        [DllImport("setupapi.dll", SetLastError = true)]
        private static extern bool SetupDiDestroyDeviceInfoList(IntPtr deviceInfoSet);

        [DllImport("setupapi.dll", SetLastError = true)]
        private static extern bool SetupDiEnumDeviceInterfaces(
            IntPtr deviceInfoSet, IntPtr deviceInfoData, ref Guid interfaceClassGuid,
            uint memberIndex, ref SP_DEVICE_INTERFACE_DATA deviceInterfaceData);

        [StructLayout(LayoutKind.Sequential)]
        private struct SP_DEVICE_INTERFACE_DATA
        {
            public int cbSize;
            public Guid InterfaceClassGuid;
            public int Flags;
            public IntPtr Reserved;
        }

        private static readonly Lazy<HwManager> _instance = new(() => new HwManager());
        public static HwManager Instance => _instance.Value;

        public HwState State { get; private set; } = HwState.NotInitialized;
        public IntPtr MbufPool { get; private set; } = IntPtr.Zero;
        public ushort PortId { get; private set; }
        public byte[] LocalMac { get; private set; } = new byte[6];
        public string? DriverVersion { get; private set; }
        public string? ErrorMessage { get; private set; }

        private readonly List<PortInfo> _ports = new();
        public IReadOnlyList<PortInfo> Ports => _ports;

        public event EventHandler<HwStatusEventArgs>? StatusChanged;
        public event Action? ActivePortChanged;

        private IntPtr _argvPtr = IntPtr.Zero;
        private readonly List<IntPtr> _allocatedPtrs = new();
        private readonly List<IntPtr> _loadedHandles = new();
        private string? _driverTempDir;
        private readonly object _lock = new();

        private HwManager() { }

        private void FreeArgv()
        {
            if (_argvPtr != IntPtr.Zero)
            {
                Marshal.FreeHGlobal(_argvPtr);
                _argvPtr = IntPtr.Zero;
            }
            foreach (var ptr in _allocatedPtrs)
                Marshal.FreeHGlobal(ptr);
            _allocatedPtrs.Clear();
        }

        // 명시적으로 LoadLibraryA 하는 DLL 목록 (로드 순서 중요)
        // 이외의 rte_*.dll은 디렉토리에 존재하되 Windows가 의존성 해석 시 자동 로드
        private static readonly string[] CoreLibs = {
            // EAL 코어 (순서 중요)
            "rte_log-26.dll", "rte_kvargs-26.dll", "rte_argparse-26.dll",
            "rte_telemetry-26.dll", "rte_eal-26.dll",
            "rte_ring-26.dll", "rte_rcu-26.dll",
            "rte_mempool-26.dll", "rte_mbuf-26.dll", "rte_pci-26.dll",
            "rte_net-26.dll", "rte_meter-26.dll", "rte_ethdev-26.dll",
            "rte_hash-26.dll", "rte_security-26.dll",
            "rte_cryptodev-26.dll",  // rte_security 의존성
            // 버스 드라이버
            "rte_bus_pci-26.dll",
            // 메모리풀
            "rte_mempool_ring-26.dll",
            // Intel NIC PMD 드라이버
            "rte_net_ixgbe-26.dll", "rte_net_i40e-26.dll",
            "rte_net_ice-26.dll", "rte_net_iavf-26.dll",
            "rte_net_e1000-26.dll",
        };

        // AES-256 key: "OCINSP_HWNET_KEY1234567890ABCDEFG" (32 bytes)
        private static byte[] DeriveKey()
        {
            byte[] k = {
                0x4F, 0x43, 0x49, 0x4E, 0x53, 0x50, 0x5F, 0x48,
                0x57, 0x4E, 0x45, 0x54, 0x5F, 0x4B, 0x45, 0x59,
                0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
                0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
            };
            return k;
        }

        private static void ExtractEncryptedArchive(string archivePath, string outputDir)
        {
            byte[] key = DeriveKey();
            byte[] encrypted = File.ReadAllBytes(archivePath);

            using var aes = Aes.Create();
            aes.Key = key;
            aes.Mode = CipherMode.CBC;
            aes.Padding = PaddingMode.PKCS7;
            aes.IV = encrypted[..16];

            using var decryptor = aes.CreateDecryptor();
            byte[] zipData = decryptor.TransformFinalBlock(encrypted, 16, encrypted.Length - 16);

            using var zipStream = new MemoryStream(zipData);
            using var archive = new ZipArchive(zipStream, ZipArchiveMode.Read);
            archive.ExtractToDirectory(outputDir);
        }

        private void CleanupStaleDriverDirs()
        {
            try
            {
                string tempBase = Path.GetTempPath();
                foreach (var dir in Directory.GetDirectories(tempBase, "hw_*"))
                {
                    try { Directory.Delete(dir, true); }
                    catch { /* 사용 중이면 무시 */ }
                }
            }
            catch { }
        }

        /// <summary>
        /// netuio 바인딩 사전 확인 — EAL init 전에 device interface 존재 여부 체크.
        /// netuio가 NIC에 바인딩되어 있으면 device interface가 등록됨.
        /// </summary>
        /// <returns>true if netuio device found, false otherwise.</returns>
        private bool CheckNetuioBinding()
        {
            // netuio PCI device interface GUID
            var netuioGuid = new Guid("08336f60-0679-4c6c-85d2-ae7ced65fff7");
            const uint DIGCF_PRESENT = 0x02;
            const uint DIGCF_DEVICEINTERFACE = 0x10;

            try
            {
                IntPtr devInfoSet = SetupDiGetClassDevsW(
                    ref netuioGuid, IntPtr.Zero, IntPtr.Zero,
                    DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);

                if (devInfoSet == IntPtr.Zero || devInfoSet == new IntPtr(-1))
                {
                    RaiseStatus(HwState.Initializing,
                        "[WARN] netuio device interface 조회 실패 (SetupDi)");
                    return false;
                }

                try
                {
                    var interfaceData = new SP_DEVICE_INTERFACE_DATA();
                    interfaceData.cbSize = Marshal.SizeOf(interfaceData);

                    bool found = SetupDiEnumDeviceInterfaces(
                        devInfoSet, IntPtr.Zero, ref netuioGuid, 0, ref interfaceData);

                    if (found)
                    {
                        RaiseStatus(HwState.Initializing,
                            "netuio 바인딩 확인 OK — NIC device interface 발견");
                        return true;
                    }
                    else
                    {
                        RaiseStatus(HwState.Initializing,
                            "[WARN] netuio device interface 없음 — NIC가 netuio에 바인딩되지 않았습니다");
                        return false;
                    }
                }
                finally
                {
                    SetupDiDestroyDeviceInfoList(devInfoSet);
                }
            }
            catch (Exception ex)
            {
                RaiseStatus(HwState.Initializing,
                    $"[WARN] netuio 확인 중 예외: {ex.Message}");
                return false; // 확인 불가 시 계속 진행 (EAL에서 실패하도록)
            }
        }

        private static string GetModulePath(IntPtr hModule)
        {
            var buf = new byte[260];
            uint len = GetModuleFileNameA(hModule, buf, (uint)buf.Length);
            return len > 0 ? System.Text.Encoding.ASCII.GetString(buf, 0, (int)len) : "(unknown)";
        }

        private void PreloadDrivers()
        {
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string archivePath = Path.Combine(baseDir, "drivers.dat");
            bool useEncryptedArchive = File.Exists(archivePath);

            // 이중 로드 방지: drivers.dat 사용 시 앱 폴더의 rte_*.dll 경고
            if (useEncryptedArchive)
            {
                var looseRteDlls = Directory.GetFiles(baseDir, "rte_*-26.dll");
                if (looseRteDlls.Length > 0)
                {
                    RaiseStatus(HwState.Initializing,
                        $"[WARN] 앱 폴더에 rte_*.dll {looseRteDlls.Length}개 + drivers.dat 공존 → 이중 로드 위험!");
                    RaiseStatus(HwState.Initializing,
                        "  drivers.dat 사용 시 앱 폴더의 rte_*.dll을 삭제하세요.");
                    // drivers.dat를 무시하고 앱 폴더 DLL 직접 사용 (이중 로드 방지)
                    useEncryptedArchive = false;
                    RaiseStatus(HwState.Initializing,
                        "  → drivers.dat 무시, 앱 폴더 DLL 직접 로드로 전환");
                }
            }

            // 이전 세션 잔여 temp 폴더 정리
            CleanupStaleDriverDirs();

            string dllDir; // DLL이 위치하는 디렉토리

            if (useEncryptedArchive)
            {
                // 랜덤 temp 폴더에 추출 → 종료 시 삭제
                _driverTempDir = Path.Combine(
                    Path.GetTempPath(), $"hw_{Guid.NewGuid():N}");
                Directory.CreateDirectory(_driverTempDir);
                dllDir = _driverTempDir;

                RaiseStatus(HwState.Initializing, "드라이버 아카이브 추출 중...");
                try
                {
                    ExtractEncryptedArchive(archivePath, _driverTempDir);
                    int count = Directory.GetFiles(_driverTempDir, "*.dll").Length;
                    RaiseStatus(HwState.Initializing, $"  {count}개 DLL 추출 완료 → {_driverTempDir}");
                }
                catch (Exception ex)
                {
                    RaiseStatus(HwState.Initializing, $"[ERROR] 아카이브 추출 실패: {ex.Message}");
                    throw;
                }

                // Windows DLL 검색 경로에 temp 폴더 추가 (P/Invoke 의존성 해석용)
                SetDllDirectoryW(_driverTempDir);
                string currentPath = Environment.GetEnvironmentVariable("PATH") ?? "";
                Environment.SetEnvironmentVariable("PATH", _driverTempDir + ";" + currentPath);
            }
            else
            {
                // drivers.dat 없으면 앱 디렉토리에서 직접 로드 (폴백)
                dllDir = baseDir;
            }

            // 코어 라이브러리 로드 (순서 중요)
            RaiseStatus(HwState.Initializing, $"코어 라이브러리 로드 중... (dllDir={dllDir}, useArchive={useEncryptedArchive})");
            int coreLoaded = 0;
            foreach (string lib in CoreLibs)
            {
                string path = Path.Combine(dllDir, lib);
                if (!File.Exists(path)) continue;
                IntPtr handle = LoadLibraryA(lib);     // 파일명만! SetDllDirectory로 검색 → 단일 인스턴스 보장
                if (handle != IntPtr.Zero)
                {
                    _loadedHandles.Add(handle);
                    coreLoaded++;
                    string loadedFrom = GetModulePath(handle);
                    RaiseStatus(HwState.Initializing, $"  [OK] {lib} → {loadedFrom}");
                }
                else
                {
                    int err = Marshal.GetLastWin32Error();
                    RaiseStatus(HwState.Initializing, $"  [WARN] {lib} 로드 실패 (err={err}, 0x{err:X})");
                }
            }
            RaiseStatus(HwState.Initializing, $"코어 라이브러리 {coreLoaded}개 로드 완료");

            // 나머지 rte_*.dll은 디렉토리에 존재 → Windows가 의존성 해석 시 자동 로드
            // (불필요한 DLL을 명시적 LoadLibraryA하면 tailq 이중 등록 PANIC 발생)

            // hwio.dll 명시적 로드 (P/Invoke 전에 미리 로드)
            // 파일명만으로 LoadLibraryA → SetDllDirectory(dllDir)에서 검색
            // (전체 경로 로드 시 P/Invoke "hwio.dll" 해석과 모듈명 불일치 → DllNotFoundException)
            string hwioFullPath = Path.Combine(dllDir, "hwio.dll");
            if (File.Exists(hwioFullPath))
            {
                IntPtr hwioHandle = LoadLibraryA("hwio.dll");
                if (hwioHandle != IntPtr.Zero)
                {
                    _loadedHandles.Add(hwioHandle);
                    string hwioFrom = GetModulePath(hwioHandle);
                    RaiseStatus(HwState.Initializing, $"  hwio.dll 로드 완료 → {hwioFrom}");
                }
                else
                {
                    int err = Marshal.GetLastWin32Error();
                    RaiseStatus(HwState.Initializing,
                        $"  [ERROR] hwio.dll 로드 실패 (Win32 err={err}, 0x{err:X})");
                }
            }
            else
            {
                RaiseStatus(HwState.Initializing, "  [WARN] hwio.dll이 없습니다");
            }
        }

        public Task InitializeAsync(HwInitOptions options)
        {
            return Task.Run(() => Initialize(options));
        }

        private void Initialize(HwInitOptions options)
        {
            lock (_lock)
            {
                if (State == HwState.Ready || State == HwState.Initializing)
                    return;

                State = HwState.Initializing;
                RaiseStatus(HwState.Initializing, "드라이버 초기화 중...");

                try
                {
                    // netuio 바인딩 사전 확인 — EAL init 크래시 없이 조기 실패 가능
                    if (!CheckNetuioBinding())
                    {
                        SetError("NIC가 netuio에 바인딩되지 않았습니다. " +
                                 "Dpdk_Setup_Tool의 'NIC 바인딩' 스텝을 실행하세요.");
                        return;
                    }

                    PreloadDrivers();

                    try
                    {
                        IntPtr versionPtr = HwInterop.hw_version();
                        if (versionPtr != IntPtr.Zero)
                        {
                            // 포인터 유효성 검증: 상위 비트가 커널 영역이면 무효
                            long addr = versionPtr.ToInt64();
                            if (addr > 0 && addr < 0x7FFFFFFFFFFF)
                                DriverVersion = Marshal.PtrToStringAnsi(versionPtr) ?? "Unknown";
                            else
                                DriverVersion = $"Invalid ptr: 0x{addr:X}";
                        }
                        else
                            DriverVersion = "Unknown (null)";
                        RaiseStatus(HwState.Initializing, $"드라이버 버전: {DriverVersion}");
                    }
                    catch (Exception ex)
                    {
                        DriverVersion = $"Error: {ex.Message}";
                        RaiseStatus(HwState.Initializing, $"[WARN] 버전 확인 실패: {ex.Message}");
                    }

                    // Auto core selection: find least-used CPU core
                    string coreMask = options.CoreMask.Trim().Trim('"', '\'');
                    if (string.Equals(coreMask, "auto", StringComparison.OrdinalIgnoreCase))
                    {
                        try
                        {
                            int bestCore = FindLeastUsedCore();
                            coreMask = bestCore.ToString();
                            RaiseStatus(HwState.Initializing,
                                $"Auto core selection: core {bestCore} (least used)");
                        }
                        catch (Exception ex)
                        {
                            coreMask = "0";
                            RaiseStatus(HwState.Initializing,
                                $"Auto core selection failed ({ex.Message}), fallback to core 0");
                        }
                    }

                    // Hugepage 가용성 사전 확인 (EAL init 전)
                    try
                    {
                        int hpErr = HwInterop.hw_check_hugepage(options.MemoryMb);
                        if (hpErr != 0)
                        {
                            SetError($"Hugepage 사전 확인 실패 (err={hpErr}, 요청={options.MemoryMb}MB). " +
                                     "Large page 풀 부족 — PC 재부팅 필요.");
                            return;
                        }
                        RaiseStatus(HwState.Initializing, $"Hugepage 사전 확인 OK ({options.MemoryMb}MB)");
                    }
                    catch (Exception ex)
                    {
                        RaiseStatus(HwState.Initializing, $"[WARN] Hugepage 사전 확인 건너뜀: {ex.Message}");
                    }

                    // EAL 초기화 — 실패 시 메모리를 줄여서 자동 재시도
                    int ret = -1;
                    int memoryMb = options.MemoryMb;
                    int minMemoryMb = 64; // 최소 64MB까지 시도

                    while (memoryMb >= minMemoryMb)
                    {
                        // 이전 시도의 argv 정리
                        FreeArgv();

                        try
                        {
                            var ealArgList = new List<string> {
                                "ITOLED_OC",
                                "-l", coreMask,
                                "-m", memoryMb.ToString(),
                                $"--log-level={options.LogLevel}"
                            };
                            if (!string.IsNullOrEmpty(options.FilePrefix))
                                ealArgList.AddRange(new[] { "--file-prefix", options.FilePrefix });
                            string[] ealArgs = ealArgList.ToArray();

                            RaiseStatus(HwState.Initializing, $"EAL 초기화 시도 (args: {string.Join(" ", ealArgs)})...");

                            _argvPtr = Marshal.AllocHGlobal(IntPtr.Size * ealArgs.Length);
                            for (int i = 0; i < ealArgs.Length; i++)
                            {
                                IntPtr strPtr = Marshal.StringToHGlobalAnsi(ealArgs[i]);
                                _allocatedPtrs.Add(strPtr);
                                Marshal.WriteIntPtr(_argvPtr, i * IntPtr.Size, strPtr);
                            }

                            ret = HwInterop.hw_eal_init(ealArgs.Length, _argvPtr);
                        }
                        catch (Exception ex)
                        {
                            SetError($"EAL 초기화 중 크래시: {ex.GetType().Name}: {ex.Message}");
                            return;
                        }

                        if (ret >= 0)
                        {
                            if (memoryMb < options.MemoryMb)
                                RaiseStatus(HwState.Initializing,
                                    $"EAL 초기화 완료 (요청 {options.MemoryMb}MB → {memoryMb}MB로 축소 성공)");
                            else
                                RaiseStatus(HwState.Initializing, "EAL 초기화 완료");
                            break;
                        }

                        // SEH crash(-99): 내부 상태 손상, 같은 프로세스에서 재시도 불가
                        if (ret == -99)
                        {
                            RaiseStatus(HwState.Initializing,
                                $"EAL init SEH crash (memory: {memoryMb}MB). 내부 상태 손상 — 재시도 불가.");
                            break;
                        }

                        // 이중 초기화(-98): 이미 초기화됨 — 재시도 불필요
                        if (ret == -98)
                        {
                            RaiseStatus(HwState.Initializing,
                                "EAL 이미 초기화됨 — 중복 호출 감지.");
                            break;
                        }

                        // 일반 실패(-1): cleanup 후 메모리 절반으로 재시도
                        RaiseStatus(HwState.Initializing,
                            $"EAL 초기화 실패 (메모리: {memoryMb}MB). hugepage 정리 후 재시도...");
                        try { HwInterop.hw_eal_cleanup(); } catch { }

                        memoryMb /= 2;
                    }

                    if (ret < 0)
                    {
                        if (ret == -99)
                            SetError("EAL 초기화 중 크래시 발생 (SEH Exception). " +
                                     "hw_diag.log 확인 필요 — PC 재부팅 후 다시 시도하세요.");
                        else if (ret == -98)
                            SetError("EAL 이미 초기화됨 (중복 호출). " +
                                     "프로세스를 완전히 종료한 후 재시작하세요.");
                        else
                            SetError($"EAL 초기화 실패 (ret={ret}). " +
                                     "hugepage 메모리 부족 — PC 재부팅 후 다시 시도하세요.");
                        try { HwInterop.hw_eal_cleanup(); } catch { }
                        return;
                    }

                    int nbPortsResult;
                    try
                    {
                        nbPortsResult = HwInterop.hw_eth_dev_count_avail();
                    }
                    catch (Exception ex)
                    {
                        SetError($"포트 수 확인 중 크래시: {ex.Message}");
                        return;
                    }

                    if (nbPortsResult < 0)
                    {
                        SetError("포트 수 확인 실패 (네이티브 예외 발생)");
                        return;
                    }

                    ushort nbPorts = (ushort)nbPortsResult;
                    RaiseStatus(HwState.Initializing, $"사용 가능 포트 수: {nbPorts}");
                    if (nbPorts == 0)
                    {
                        SetError("포트가 없습니다. NIC가 netuio에 바인딩되었는지 확인하세요.");
                        return;
                    }

                    if (options.PortId >= nbPorts)
                    {
                        SetError($"포트 ID {options.PortId}가 범위를 벗어났습니다. (사용 가능: 0~{nbPorts - 1})");
                        return;
                    }

                    try
                    {
                        // cache_size=0: 비-EAL 스레드(C# main/UI)에서 mbuf 할당 가능
                        // (cache_size>0이면 lcore_id 기반 캐시 접근 → 비-EAL 스레드에서 크래시)
                        MbufPool = HwInterop.hw_pktmbuf_pool_create_safe(
                            "MBUF_POOL", options.MbufPoolSize, 0, 0, 2048 + 128, 0);
                    }
                    catch (Exception ex)
                    {
                        SetError($"Mbuf Pool 생성 중 크래시: {ex.Message}");
                        return;
                    }

                    if (MbufPool == IntPtr.Zero)
                    {
                        SetError("Mbuf Pool 생성 실패");
                        return;
                    }
                    RaiseStatus(HwState.Initializing, "Mbuf Pool 생성 완료");

                    _ports.Clear();
                    ushort firstUpPort = options.PortId;
                    bool anySetup = false;
                    bool selectedPortSetup = false;

                    RaiseStatus(HwState.Initializing, $"포트 {nbPorts}개 설정 시작...");
                    for (ushort p = 0; p < nbPorts; p++)
                    {
                        var macAddr = new RteEtherAddr { addr_bytes = new byte[6] };
                        try { HwInterop.hw_eth_macaddr_get(p, ref macAddr); } catch { }

                        var preLink = new RteEthLink();
                        try { HwInterop.hw_eth_link_get_nowait(p, ref preLink); } catch { }

                        var info = new PortInfo
                        {
                            PortId = p,
                            Mac = (byte[])macAddr.addr_bytes.Clone(),
                            LinkUp = preLink.link_status != 0,
                            LinkSpeed = preLink.link_speed,
                            IsSetup = false
                        };

                        try
                        {
                            int portRet = HwInterop.hw_simple_port_setup(p, MbufPool, options.LinkSpeeds);
                            if (portRet == 0)
                            {
                                info.IsSetup = true;
                                if (!anySetup) { firstUpPort = p; anySetup = true; }
                                if (p == options.PortId) selectedPortSetup = true;

                                Thread.Sleep(500);
                                var postLink = new RteEthLink();
                                try { HwInterop.hw_eth_link_get_nowait(p, ref postLink); } catch { }
                                info.LinkUp = postLink.link_status != 0;
                                info.LinkSpeed = postLink.link_speed;

                                var macPost = new RteEtherAddr { addr_bytes = new byte[6] };
                                try { HwInterop.hw_eth_macaddr_get(p, ref macPost); } catch { }
                                info.Mac = (byte[])macPost.addr_bytes.Clone();

                                string linkStr = info.LinkUp ? $"Link UP ({info.LinkSpeed} Mbps)" : "Link DOWN";
                                RaiseStatus(HwState.Initializing,
                                    $"  포트 {p}: MAC={NetUtils.FormatMac(info.Mac)} | {linkStr} — 설정 완료");
                            }
                            else
                            {
                                RaiseStatus(HwState.Initializing,
                                    $"  포트 {p}: 설정 실패 (ret={portRet})");
                            }
                        }
                        catch (Exception ex)
                        {
                            RaiseStatus(HwState.Initializing, $"  포트 {p}: 설정 중 예외 — {ex.Message}");
                        }

                        _ports.Add(info);
                    }

                    if (!anySetup)
                    {
                        SetError("설정 가능한 포트가 없습니다.");
                        return;
                    }

                    PortId = selectedPortSetup ? options.PortId : firstUpPort;
                    var activePort = _ports.First(p => p.PortId == PortId);
                    LocalMac = (byte[])activePort.Mac.Clone();

                    RaiseStatus(HwState.Initializing,
                        $"활성 포트: {PortId} (MAC: {NetUtils.FormatMac(LocalMac)})");

                    if (!activePort.LinkUp)
                    {
                        RaiseStatus(HwState.Initializing, "링크 상태 확인 중 (최대 10초 대기)...");
                        try
                        {
                            for (int wait = 0; wait < 10; wait++)
                            {
                                Thread.Sleep(1000);
                                var linkCheck = new RteEthLink();
                                HwInterop.hw_eth_link_get_nowait(PortId, ref linkCheck);
                                if (linkCheck.link_status != 0)
                                {
                                    activePort.LinkUp = true;
                                    activePort.LinkSpeed = linkCheck.link_speed;
                                    RaiseStatus(HwState.Initializing, $"링크 UP 감지! ({wait + 1}초 후)");
                                    break;
                                }
                                RaiseStatus(HwState.Initializing, $"링크 대기 중... ({wait + 1}/10초)");
                            }
                        }
                        catch (Exception ex)
                        {
                            RaiseStatus(HwState.Initializing, $"[WARN] 링크 상태 확인 실패: {ex.Message}");
                        }
                    }

                    foreach (var port in _ports)
                    {
                        string linkStatus = port.LinkUp
                            ? $"Link UP ({port.LinkSpeed} Mbps)"
                            : "Link DOWN";
                        string setup = port.IsSetup ? "설정됨" : "미설정";
                        string marker = (port.PortId == PortId) ? " ← [선택됨]" : "";

                        RaiseStatus(HwState.Initializing,
                            $"포트 {port.PortId}: MAC={NetUtils.FormatMac(port.Mac)} | {linkStatus} | {setup}{marker}");
                    }

                    State = HwState.Ready;
                    RaiseStatus(HwState.Ready,
                        $"드라이버 준비 완료 (포트 {PortId}, MAC: {NetUtils.FormatMac(LocalMac)})");
                }
                catch (DllNotFoundException ex)
                {
                    SetError($"DLL 로드 실패: {ex.Message}. DLL이 실행 디렉토리에 있는지 확인하세요.");
                }
                catch (Exception ex)
                {
                    SetError($"초기화 중 예외: {ex.GetType().Name}: {ex.Message}");
                }
                finally
                {
                    // Ready가 아니면 부분 초기화된 EAL/hugepage 즉시 정리
                    // (EAL init 성공 후 mbuf/port 실패 시 hugepage가 잡혀 있으므로 해제 필수)
                    if (State != HwState.Ready && State != HwState.CleanedUp)
                    {
                        foreach (var port in _ports.Where(p => p.IsSetup))
                        {
                            try { HwInterop.hw_eth_dev_stop(port.PortId); } catch { }
                            try { HwInterop.hw_eth_dev_close(port.PortId); } catch { }
                        }
                        _ports.Clear();
                        try { HwInterop.hw_eal_cleanup(); } catch { }
                        FreeArgv();
                        MbufPool = IntPtr.Zero;
                    }
                }
            }
        }

        public bool SwitchPort(ushort newPortId)
        {
            var portInfo = _ports.FirstOrDefault(p => p.PortId == newPortId && p.IsSetup);
            if (portInfo == null) return false;
            if (newPortId == PortId) return true;

            PortId = newPortId;
            LocalMac = (byte[])portInfo.Mac.Clone();
            ActivePortChanged?.Invoke();
            RaiseStatus(HwState.Ready,
                $"활성 포트 전환: 포트 {newPortId} (MAC: {NetUtils.FormatMac(LocalMac)})");
            return true;
        }

        public RteEthStats GetPortStats()
        {
            var stats = new RteEthStats();
            if (State == HwState.Ready)
                HwInterop.hw_eth_stats_get(PortId, ref stats);
            return stats;
        }

        public void ResetPortStats()
        {
            if (State == HwState.Ready)
                HwInterop.hw_eth_stats_reset(PortId);
        }

        public RteEthLink GetLinkInfo()
        {
            var link = new RteEthLink();
            if (State == HwState.Ready)
                HwInterop.hw_eth_link_get_nowait(PortId, ref link);
            return link;
        }

        // =================================================================
        // Public Packet Buffer Management
        // =================================================================

        /// <summary>Allocate a packet mbuf from the pool.</summary>
        public IntPtr AllocMbuf() => HwInterop.hw_pktmbuf_alloc(MbufPool);

        /// <summary>Append data space to an mbuf. Returns data pointer or IntPtr.Zero.</summary>
        public IntPtr AppendMbuf(IntPtr mbuf, ushort len) => HwInterop.hw_pktmbuf_append(mbuf, len);

        /// <summary>Free a packet mbuf.</summary>
        public void FreeMbuf(IntPtr mbuf) => HwInterop.hw_pktmbuf_free(mbuf);

        /// <summary>Get pointer to packet data (mtod).</summary>
        public IntPtr GetMbufData(IntPtr mbuf) => HwInterop.hw_pktmbuf_mtod(mbuf);

        /// <summary>Get packet data length.</summary>
        public ushort GetMbufDataLen(IntPtr mbuf) => HwInterop.hw_pktmbuf_data_len(mbuf);

        // =================================================================
        // Public Packet I/O
        // =================================================================

        /// <summary>Transmit a burst of packets on the active port, queue 0.</summary>
        public ushort TxBurst(IntPtr[] txPkts, ushort count)
            => HwInterop.hw_tx_burst(PortId, 0, txPkts, count);

        /// <summary>Receive a burst of packets from the active port, queue 0.</summary>
        public ushort RxBurst(IntPtr[] rxPkts, ushort maxCount)
            => HwInterop.hw_rx_burst(PortId, 0, rxPkts, maxCount);

        /// <summary>
        /// Unified dispatcher: single rx_burst with protocol demux.
        /// UDP packets returned in outUdpPkts, TCP/ARP fed to lwIP internally.
        /// </summary>
        public ushort DispatchPoll(IntPtr[] outUdpPkts, ushort maxUdp, out int lwipCount)
        {
            lwipCount = 0;
            return HwInterop.hw_dispatch_poll(PortId, 0, outUdpPkts, maxUdp, ref lwipCount);
        }

        /// <summary>
        /// Enable/disable lwIP external RX mode.
        /// When enabled, the unified dispatcher feeds TCP/ARP packets to lwIP,
        /// and netif_poll() skips its own rte_eth_rx_burst.
        /// </summary>
        public void SetLwipExternalRx(bool enabled)
            => LwipHwInterop.hw_lwip_set_external_rx(enabled ? 1 : 0);

        // =================================================================
        // Public Sync Req/Resp (Multi-Channel safe)
        // =================================================================

        /// <summary>
        /// Send a single request and wait for matching response (MC-safe with spill buffer).
        /// </summary>
        /// <returns>0 on success, negative on error.</returns>
        public int ReqRespOnceMc(
            byte[] templatePkt, ushort pktLen, ushort packetId,
            uint expectedSrcIp, ushort expectedDstPort,
            int timeoutMs, byte[] respBuf, ushort respBufSize,
            out ReqRespNativeResult result, byte[] localMac, uint localIp)
        {
            var hwResult = new HwReqRespResult();
            int ret = HwInterop.hw_reqresp_once_mc(
                PortId, MbufPool,
                templatePkt, pktLen, packetId,
                expectedSrcIp, expectedDstPort,
                timeoutMs, respBuf, respBufSize,
                ref hwResult, localMac, localIp);

            result = new ReqRespNativeResult
            {
                Status = hwResult.Status,
                RttMs = hwResult.RttMs,
                RespLen = hwResult.RespLen,
                SrcIp = hwResult.SrcIp,
                SrcPort = hwResult.SrcPort
            };
            return ret;
        }

        /// <summary>
        /// Send a single request and wait for matching response (single-channel, no spill).
        /// </summary>
        /// <returns>0 on success, negative on error.</returns>
        public int ReqRespOnce(
            byte[] templatePkt, ushort pktLen, ushort packetId,
            uint expectedSrcIp, ushort expectedDstPort,
            int timeoutMs, byte[] respBuf, ushort respBufSize,
            out ReqRespNativeResult result, byte[] localMac, uint localIp)
        {
            var hwResult = new HwReqRespResult();
            int ret = HwInterop.hw_reqresp_once(
                PortId, MbufPool,
                templatePkt, pktLen, packetId,
                expectedSrcIp, expectedDstPort,
                timeoutMs, respBuf, respBufSize,
                ref hwResult, localMac, localIp);

            result = new ReqRespNativeResult
            {
                Status = hwResult.Status,
                RttMs = hwResult.RttMs,
                RespLen = hwResult.RespLen,
                SrcIp = hwResult.SrcIp,
                SrcPort = hwResult.SrcPort
            };
            return ret;
        }

        public void Cleanup()
        {
            lock (_lock)
            {
                if (State == HwState.CleanedUp)
                    return;

                foreach (var port in _ports.Where(p => p.IsSetup))
                {
                    try { HwInterop.hw_eth_dev_stop(port.PortId); } catch { }
                    try { HwInterop.hw_eth_dev_close(port.PortId); } catch { }
                }
                _ports.Clear();

                // EAL init 실패 시에도 부분 할당된 hugepage를 해제하기 위해 항상 cleanup 시도
                int cleanupRet = -999;
                try { cleanupRet = HwInterop.hw_eal_cleanup(); } catch { }

                FreeArgv();

                // 로드된 DLL 핸들 해제 (역순)
                for (int i = _loadedHandles.Count - 1; i >= 0; i--)
                {
                    try { FreeLibrary(_loadedHandles[i]); } catch { }
                }
                _loadedHandles.Clear();

                // SetDllDirectory 초기화
                try { SetDllDirectoryW(null); } catch { }

                // drivers.dat에서 추출한 temp 폴더 삭제
                if (_driverTempDir != null && Directory.Exists(_driverTempDir))
                {
                    for (int attempt = 0; attempt < 3; attempt++)
                    {
                        try
                        {
                            Directory.Delete(_driverTempDir, recursive: true);
                            break;
                        }
                        catch { Thread.Sleep(500); }
                    }
                    _driverTempDir = null;
                }

                MbufPool = IntPtr.Zero;
                State = HwState.CleanedUp;
                RaiseStatus(HwState.CleanedUp, $"드라이버 정리 완료 (hw_eal_cleanup ret={cleanupRet})");
            }
        }

        public void Dispose() => Cleanup();

        /// <summary>
        /// Read the tail of hw_diag.log for diagnostic display.
        /// Returns empty string if not available.
        /// </summary>
        public static string ReadDebugLog(int maxBytes = 4096)
        {
            try
            {
                var buf = new byte[maxBytes];
                int len = HwInterop.hw_read_debug_log(buf, buf.Length);
                if (len > 0)
                    return System.Text.Encoding.UTF8.GetString(buf, 0, len);
            }
            catch { }
            return "";
        }

        private void SetError(string message)
        {
            ErrorMessage = message;
            State = HwState.Error;
            RaiseStatus(HwState.Error, message);
        }

        private void RaiseStatus(HwState state, string message)
        {
            StatusChanged?.Invoke(this, new HwStatusEventArgs(state, message));
        }

        /// <summary>
        /// Select a dedicated CPU core for EAL lcore thread.
        /// Avoids core 0 (OS) and core 1 (RX poll).
        /// </summary>
        private static int FindLeastUsedCore()
        {
            int coreCount = Environment.ProcessorCount;
            if (coreCount <= 1) return 0;

            // Core layout:
            //   core 0     — OS scheduler (avoid)
            //   core 1     — PgDpdkServer RX poll thread (reserved)
            //   core N-1   — EAL lcore (this function)
            //   core 2~N-2 — ReqResp / general threads
            // Always pick the last core for EAL to avoid conflict with RX poll (core 1).
            return coreCount - 1;
        }
    }
}
