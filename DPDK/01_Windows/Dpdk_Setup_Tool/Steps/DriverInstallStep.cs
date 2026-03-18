using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class DriverInstallStep : SetupStepBase
{
    public override string Name => "드라이버 설치";
    public override string Description => "netuio/virt2phys 커널 드라이버를 서명하고 설치합니다.";
    public override bool CanSkip => true;

    private static readonly string[] TimestampServers =
    {
        "http://timestamp.digicert.com",
        "http://timestamp.sectigo.com",
        "http://timestamp.globalsign.com/tsa/r6advanced/v3",
        "http://sha256timestamp.ws.symantec.com/sha256/timestamp"
    };

    private const string CertName = "DPDK_NetUIO_TestCert";

    private CheckBox? _chkVirt2Phys;

    protected override void OnCreateContent(Panel panel)
    {
        _chkVirt2Phys = new CheckBox
        {
            Text = "virt2phys 드라이버도 설치",
            Checked = true,
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 10f),
            Dock = DockStyle.Top,
            Height = 30,
            Padding = new Padding(4, 4, 0, 0)
        };
        panel.Controls.Add(_chkVirt2Phys);
    }

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        string root = GetProjectRoot();
        string driverDir = Path.Combine(root, "dpdk-kmods", "windows", "netuio", "x64", "Release", "netuio");
        string backupDir = Path.Combine(root, "_backup_netuio");
        Directory.CreateDirectory(backupDir);

        string infPath = Path.Combine(driverDir, "netuio.inf");
        string sysPath = Path.Combine(driverDir, "netuio.sys");
        string catPath = Path.Combine(driverDir, "netuio.cat");
        string cerPath = Path.Combine(driverDir, "netuio.cer");

        // ===== Pre-checks =====
        LogInfo("[사전검증] 드라이버 파일 확인...");

        if (!File.Exists(infPath) || !File.Exists(sysPath))
            throw new Exception($"netuio.inf/sys가 없습니다: {driverDir}");
        LogSuccess("  netuio.inf, netuio.sys 확인됨");

        bool testSign = await SystemInfo.IsTestSigningEnabled();
        if (!testSign)
            LogWarning("  TestSigning 비활성 — 드라이버가 로드되지 않을 수 있음");

        ct.ThrowIfCancellationRequested();

        // ===== Safety: NIC backup =====
        LogInfo("[안전장치] NIC 드라이버 정보 백업...");
        await BackupNicInfo(backupDir, ct);

        ct.ThrowIfCancellationRequested();

        // ===== Step 1: Find WDK tools =====
        LogInfo("[1/5] WDK 도구 찾기...");
        string? inf2cat = WdkLocator.FindTool("Inf2Cat.exe", "x86");
        string? signTool = WdkLocator.FindTool("signtool.exe", "x64");

        if (inf2cat == null || signTool == null)
            throw new Exception("Inf2Cat 또는 SignTool을 찾을 수 없습니다. WDK를 설치하세요.");

        LogInfo($"  Inf2Cat: {inf2cat}");
        LogInfo($"  SignTool: {signTool}");

        ct.ThrowIfCancellationRequested();

        // ===== Step 2: Generate catalog =====
        LogInfo("[2/5] 카탈로그 생성...");
        if (File.Exists(catPath)) File.Delete(catPath);

        var catResult = await ProcessRunner.RunAsync(inf2cat,
            $"/driver:\"{driverDir}\" /os:10_X64",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        if (!File.Exists(catPath))
            throw new Exception("카탈로그 생성 실패 (netuio.cat)");
        LogSuccess("  카탈로그 생성 완료");

        ct.ThrowIfCancellationRequested();

        // ===== Step 3: Certificate =====
        LogInfo("[3/5] 자체서명 인증서 생성...");

        // Clean existing certs
        await ProcessRunner.RunAsync("certutil.exe", $"-delstore Root {CertName}");
        await ProcessRunner.RunAsync("certutil.exe", $"-delstore TrustedPublisher {CertName}");
        await ProcessRunner.RunAsync("certutil.exe", $"-delstore My {CertName}");
        if (File.Exists(cerPath)) File.Delete(cerPath);

        // Create new cert
        var certResult = await ProcessRunner.RunPowerShellAsync(
            $"$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN={CertName}' " +
            $"-CertStoreLocation 'Cert:\\CurrentUser\\My' -NotAfter (Get-Date).AddYears(5); " +
            $"Export-Certificate -Cert $cert -FilePath '{cerPath}' -Type CERT | Out-Null; " +
            $"$cert.Thumbprint",
            onOutputLine: s => LogInfo($"  {s}"),
            ct: ct);

        if (!File.Exists(cerPath))
            throw new Exception("인증서 생성 실패");

        // Register in trusted stores
        await ProcessRunner.RunAsync("certutil.exe", $"-addstore -f Root \"{cerPath}\"",
            onOutputLine: s => LogInfo($"  {s}"), ct: ct);
        await ProcessRunner.RunAsync("certutil.exe", $"-addstore -f TrustedPublisher \"{cerPath}\"",
            onOutputLine: s => LogInfo($"  {s}"), ct: ct);

        LogSuccess("  인증서 생성 및 등록 완료");

        ct.ThrowIfCancellationRequested();

        // ===== Step 4: Sign driver =====
        LogInfo("[4/5] 드라이버 서명...");
        bool signed = false;

        foreach (var tsServer in TimestampServers)
        {
            ct.ThrowIfCancellationRequested();
            LogInfo($"  타임스탬프 서버: {tsServer}");

            var signResult = await ProcessRunner.RunAsync(signTool,
                $"sign /v /a /s My /n \"{CertName}\" /t {tsServer} /fd sha256 \"{sysPath}\" \"{catPath}\"",
                onOutputLine: s => LogInfo($"  {s}"),
                onErrorLine: s => LogWarning($"  {s}"),
                ct: ct);

            if (signResult.Success)
            {
                LogSuccess($"  서명 성공 (서버: {tsServer})");
                signed = true;
                break;
            }
            LogWarning($"  서명 실패, 다음 서버로 재시도...");
        }

        if (!signed)
        {
            // Rollback
            LogError("  모든 타임스탬프 서버 실패 — 롤백 중...");
            await RollbackCerts(cerPath, catPath);
            throw new Exception("드라이버 서명 실패");
        }

        ct.ThrowIfCancellationRequested();

        // ===== Step 5: Install driver =====
        LogInfo("[5/5] 드라이버 설치 (pnputil)...");

        var installResult = await ProcessRunner.RunAsync("pnputil.exe",
            $"/add-driver \"{infPath}\" /install",
            onOutputLine: s => LogInfo($"  {s}"),
            onErrorLine: s => LogWarning($"  {s}"),
            ct: ct);

        // pnputil exit 259 = needs reboot but success
        if (installResult.ExitCode != 0 && installResult.ExitCode != 259)
        {
            LogError($"  pnputil 실패 (exit code: {installResult.ExitCode})");
            throw new Exception("드라이버 설치 실패");
        }

        // Verify
        var verifyResult = await ProcessRunner.RunAsync("pnputil.exe", "/enum-drivers",
            ct: ct);
        if (verifyResult.Output.Contains("netuio", StringComparison.OrdinalIgnoreCase))
            LogSuccess("  netuio 드라이버 설치 확인됨");
        else
            LogWarning("  netuio 드라이버 설치 확인 실패 — 재부팅 후 확인하세요");

        // ===== Optional: virt2phys =====
        if (_chkVirt2Phys?.Checked == true)
        {
            ct.ThrowIfCancellationRequested();
            await InstallVirt2Phys(root, signTool, ct);
        }

        LogSuccess("드라이버 설치 완료!");
    }

    private async Task InstallVirt2Phys(string root, string signTool, CancellationToken ct)
    {
        LogInfo("[추가] virt2phys 드라이버 설치...");

        string v2pDir = Path.Combine(root, "dpdk-kmods", "windows", "virt2phys", "x64", "Release", "virt2phys");
        string v2pInf = Path.Combine(v2pDir, "virt2phys.inf");
        string v2pSys = Path.Combine(v2pDir, "virt2phys.sys");
        string v2pCat = Path.Combine(v2pDir, "virt2phys.cat");

        if (!File.Exists(v2pInf) || !File.Exists(v2pSys))
        {
            LogWarning("  virt2phys 파일이 없습니다. 건너뜁니다.");
            return;
        }

        // Generate catalog
        string? inf2cat = WdkLocator.FindTool("Inf2Cat.exe", "x86");
        if (inf2cat != null)
        {
            if (File.Exists(v2pCat)) File.Delete(v2pCat);
            await ProcessRunner.RunAsync(inf2cat,
                $"/driver:\"{v2pDir}\" /os:10_X64",
                onOutputLine: s => LogInfo($"  {s}"), ct: ct);
        }

        // Sign
        if (File.Exists(v2pSys) && File.Exists(v2pCat))
        {
            foreach (var ts in TimestampServers)
            {
                var signResult = await ProcessRunner.RunAsync(signTool,
                    $"sign /v /a /s My /n \"{CertName}\" /t {ts} /fd sha256 \"{v2pSys}\" \"{v2pCat}\"",
                    ct: ct);
                if (signResult.Success) break;
            }
        }

        // Install via pnputil
        var installResult = await ProcessRunner.RunAsync("pnputil.exe",
            $"/add-driver \"{v2pInf}\" /install",
            onOutputLine: s => LogInfo($"  {s}"), ct: ct);

        // Create device node if needed
        string? devcon = WdkLocator.FindDevcon();
        if (devcon != null)
        {
            await ProcessRunner.RunAsync(devcon,
                "install virt2phys.inf Root\\virt2phys",
                workingDirectory: v2pDir,
                onOutputLine: s => LogInfo($"  {s}"), ct: ct);
        }

        if (installResult.ExitCode == 0 || installResult.ExitCode == 259)
            LogSuccess("  virt2phys 설치 완료");
        else
            LogWarning("  virt2phys 설치 실패 (비치명적)");
    }

    private async Task BackupNicInfo(string backupDir, CancellationToken ct)
    {
        try
        {
            var result = await ProcessRunner.RunPowerShellAsync(
                "Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, DriverFileName, DriverVersion | Format-Table -AutoSize | Out-String",
                ct: ct);
            string backupFile = Path.Combine(backupDir,
                $"nic_backup_{DateTime.Now:yyyyMMdd_HHmmss}.txt");
            await File.WriteAllTextAsync(backupFile, result.Output, ct);
            LogSuccess($"  NIC 정보 백업: {backupFile}");
        }
        catch
        {
            LogWarning("  NIC 정보 백업 실패 (비치명적)");
        }
    }

    private async Task RollbackCerts(string cerPath, string catPath)
    {
        await ProcessRunner.RunAsync("certutil.exe", $"-delstore Root {CertName}");
        await ProcessRunner.RunAsync("certutil.exe", $"-delstore TrustedPublisher {CertName}");
        await ProcessRunner.RunAsync("certutil.exe", $"-delstore My {CertName}");
        if (File.Exists(cerPath)) File.Delete(cerPath);
        if (File.Exists(catPath)) File.Delete(catPath);
        LogInfo("  인증서 롤백 완료");
    }
}
