using HwNet.Utilities;
using DpdkSetupTool.Controls;
using DpdkSetupTool.Utils;

namespace DpdkSetupTool.Steps;

public class SystemCheckStep : SetupStepBase
{
    public override string Name => "시스템 점검";
    public override string Description => "DPDK 환경 구성에 필요한 시스템 요건을 점검합니다.";
    public override bool CanSkip => false;

    private ChecklistPanel? _checklist;

    protected override void OnCreateContent(Panel panel)
    {
        _checklist = new ChecklistPanel { Dock = DockStyle.Fill };

        _checklist.AddItem(new ChecklistItem { Name = "관리자 권한" });
        _checklist.AddItem(new ChecklistItem { Name = "Windows 에디션 (Pro/Enterprise)" });
        _checklist.AddItem(new ChecklistItem { Name = "Secure Boot OFF" });
        _checklist.AddItem(new ChecklistItem { Name = "Hyper-V 비활성화" });
        _checklist.AddItem(new ChecklistItem { Name = "디스크 공간 ≥ 20GB" });
        _checklist.AddItem(new ChecklistItem { Name = "RAM ≥ 8GB" });
        _checklist.AddItem(new ChecklistItem { Name = "필수 도구: git" });
        _checklist.AddItem(new ChecklistItem { Name = "필수 도구: python" });
        _checklist.AddItem(new ChecklistItem { Name = "필수 도구: clang" });
        _checklist.AddItem(new ChecklistItem { Name = "필수 도구: meson + ninja" });
        _checklist.AddItem(new ChecklistItem { Name = "필수 도구: dotnet SDK" });
        _checklist.AddItem(new ChecklistItem { Name = "WDK 설치 여부" });
        _checklist.AddItem(new ChecklistItem { Name = "TestSigning 상태" });
        _checklist.AddItem(new ChecklistItem { Name = "SeLockMemoryPrivilege" });
        _checklist.AddItem(new ChecklistItem { Name = "전원 관리: 고성능 모드" });

        panel.Controls.Add(_checklist);
    }

    public override async Task ExecuteAsync(CancellationToken ct)
    {
        if (_checklist == null) return;
        int idx = 0;

        // 0. Admin
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        bool isAdmin = SystemInfo.IsAdmin();
        _checklist.UpdateItem(idx++, isAdmin ? CheckStatus.Passed : CheckStatus.Failed,
            isAdmin ? "관리자 권한으로 실행 중" : "관리자 권한 필요 (app.manifest로 자동 보장)");
        LogInfo($"관리자 권한: {isAdmin}");

        ct.ThrowIfCancellationRequested();

        // 1. Windows Edition
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        string edition = SystemInfo.GetWindowsEdition();
        bool editionOk = edition.Contains("Professional", StringComparison.OrdinalIgnoreCase) ||
                         edition.Contains("Enterprise", StringComparison.OrdinalIgnoreCase) ||
                         edition.Contains("Education", StringComparison.OrdinalIgnoreCase) ||
                         edition.Contains("Pro", StringComparison.OrdinalIgnoreCase);
        _checklist.UpdateItem(idx++, editionOk ? CheckStatus.Passed : CheckStatus.Failed,
            $"Windows {edition}");
        LogInfo($"Windows Edition: {edition}");

        ct.ThrowIfCancellationRequested();

        // 2. Secure Boot
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        var secureBoot = await SystemInfo.IsSecureBootEnabled();
        if (secureBoot == null)
            _checklist.UpdateItem(idx++, CheckStatus.Warning, "확인 불가 (Legacy BIOS)");
        else if (secureBoot == false)
            _checklist.UpdateItem(idx++, CheckStatus.Passed, "Secure Boot OFF");
        else
            _checklist.UpdateItem(idx++, CheckStatus.Failed, "Secure Boot ON — BIOS에서 비활성화 필요");
        LogInfo($"Secure Boot: {(secureBoot == null ? "N/A" : secureBoot.ToString())}");

        ct.ThrowIfCancellationRequested();

        // 3. Hyper-V
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        bool hyperV = await SystemInfo.IsHyperVEnabled();
        _checklist.UpdateItem(idx++, hyperV ? CheckStatus.Warning : CheckStatus.Passed,
            hyperV ? "Hyper-V 활성화됨 — DPDK와 충돌 가능" : "Hyper-V 비활성화");
        LogInfo($"Hyper-V: {(hyperV ? "Enabled" : "Disabled")}");

        ct.ThrowIfCancellationRequested();

        // 4. Disk space
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        string drive = Path.GetPathRoot(GetProjectRoot())?.TrimEnd('\\', '/') ?? "C:";
        double diskGB = SystemInfo.GetAvailableDiskSpaceGB(drive.Substring(0, 1));
        _checklist.UpdateItem(idx++, diskGB >= 20 ? CheckStatus.Passed : CheckStatus.Failed,
            $"{diskGB:F1} GB 사용 가능 ({drive})");
        LogInfo($"Disk: {diskGB:F1} GB");

        ct.ThrowIfCancellationRequested();

        // 5. RAM
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        double ramGB = await SystemInfo.GetTotalRamGB();
        _checklist.UpdateItem(idx++, ramGB >= 8 ? CheckStatus.Passed : CheckStatus.Warning,
            $"{ramGB:F1} GB");
        LogInfo($"RAM: {ramGB:F1} GB");

        ct.ThrowIfCancellationRequested();

        // 6-10. Tools
        string[] tools = { "git", "python", "clang", "meson", "dotnet" };
        string[] toolNames = { "git", "python", "clang", "meson + ninja", "dotnet SDK" };
        for (int i = 0; i < tools.Length; i++)
        {
            _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
            ct.ThrowIfCancellationRequested();

            bool exists = await ProcessRunner.CommandExistsAsync(tools[i]);
            string path = exists ? (await ProcessRunner.WhichAsync(tools[i]) ?? "found") : "not found";

            // For meson, also check ninja
            if (tools[i] == "meson" && exists)
            {
                bool ninjaExists = await ProcessRunner.CommandExistsAsync("ninja");
                if (!ninjaExists)
                {
                    _checklist.UpdateItem(idx++, CheckStatus.Warning, "meson OK, ninja 미설치");
                    LogWarning("meson found but ninja missing");
                    continue;
                }
            }

            _checklist.UpdateItem(idx++, exists ? CheckStatus.Passed : CheckStatus.Warning,
                exists ? path : "미설치 — Step 1에서 설치 가능");
            LogInfo($"{toolNames[i]}: {(exists ? "OK" : "Not found")}");
        }

        ct.ThrowIfCancellationRequested();

        // 11. WDK
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        bool wdkOk = WdkLocator.IsInstalled();
        string wdkVersions = wdkOk ? string.Join(", ", WdkLocator.GetInstalledVersions().Take(3)) : "미설치";
        _checklist.UpdateItem(idx++, wdkOk ? CheckStatus.Passed : CheckStatus.Warning,
            wdkOk ? $"설치됨 ({wdkVersions})" : "미설치 — Step 1에서 설치 가능");
        LogInfo($"WDK: {(wdkOk ? wdkVersions : "Not installed")}");

        ct.ThrowIfCancellationRequested();

        // 12. TestSigning
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        bool testSign = await SystemInfo.IsTestSigningEnabled();
        _checklist.UpdateItem(idx++, testSign ? CheckStatus.Passed : CheckStatus.Warning,
            testSign ? "활성화됨" : "비활성화 — Step 2에서 설정 가능");
        LogInfo($"TestSigning: {testSign}");

        ct.ThrowIfCancellationRequested();

        // 13. SeLockMemory
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        var (seLockOk, seLockDetail) = await SystemInfo.CheckSeLockMemoryPrivilege();
        _checklist.UpdateItem(idx++, seLockOk ? CheckStatus.Passed : CheckStatus.Warning,
            seLockOk ? "권한 부여됨" : "미부여 — Step 2에서 설정 가능");
        LogInfo($"SeLockMemory: {seLockOk} — {seLockDetail}");

        ct.ThrowIfCancellationRequested();

        // 14. Power Plan
        _checklist.UpdateItem(idx, CheckStatus.Checking, "확인 중...");
        bool isHighPerf = PowerPlanHelper.IsHighPerformanceActive();
        if (isHighPerf)
        {
            _checklist.UpdateItem(idx++, CheckStatus.Passed, "고성능 모드 활성화됨");
            LogInfo("전원 관리: 고성능 모드 활성화됨");
        }
        else
        {
            string currentPlan = PowerPlanHelper.GetActivePlanName();
            LogWarning($"전원 관리: 현재 '{currentPlan}' — 고성능으로 변경 중...");
            bool applied = new PowerPlanHelper().ApplyHighPerformance();
            if (applied)
            {
                _checklist.UpdateItem(idx++, CheckStatus.Passed, $"고성능 모드 적용 완료 (이전: {currentPlan})");
                LogSuccess("전원 관리: 고성능 모드 적용 완료");
            }
            else
            {
                _checklist.UpdateItem(idx++, CheckStatus.Warning, $"적용 실패 (현재: {currentPlan})");
                LogWarning("전원 관리: 고성능 모드 적용 실패 — 수동 설정 필요");
            }
        }

        // Summary
        if (_checklist.AllPassed)
        {
            LogSuccess("시스템 점검 완료 — 모든 항목 통과");
        }
        else
        {
            bool hasFailed = false;
            for (int i = 0; i < _checklist.ItemCount; i++)
            {
                if (_checklist.GetItem(i).Status == CheckStatus.Failed)
                    hasFailed = true;
            }
            if (hasFailed)
            {
                LogError("필수 항목 실패 — 해결 후 재실행하세요");
                throw new Exception("시스템 요건 미충족 (Failed 항목 존재)");
            }
            else
            {
                LogWarning("경고 항목이 있지만 진행 가능합니다. 이후 스텝에서 설치/설정됩니다.");
            }
        }
    }
}
