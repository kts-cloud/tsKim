using System.Diagnostics;
using System.Text.RegularExpressions;

namespace HwNet.Utilities
{
    /// <summary>
    /// 드라이버 실행 시 Windows 전원 옵션을 고성능으로 전환하고, 종료 시 원래 설정으로 복원.
    /// - 고성능 전원 관리 옵션 활성화
    /// - 최소 프로세서 상태 100% (C-State 진입 방지)
    /// - PCI Express ASPM 비활성화 (NIC 레이턴시 감소)
    /// </summary>
    public class PowerPlanHelper : IDisposable
    {
        private string? _originalPlanGuid;
        private bool _restored;

        public const string HighPerformanceGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c";

        public string? OriginalPlanGuid => _originalPlanGuid;
        public bool Applied { get; private set; }

        /// <summary>현재 활성 전원 관리 옵션이 고성능인지 확인</summary>
        public static bool IsHighPerformanceActive()
        {
            try
            {
                string? guid = GetActivePlanGuid();
                return guid != null && guid.Equals(HighPerformanceGuid, StringComparison.OrdinalIgnoreCase);
            }
            catch { return false; }
        }

        /// <summary>현재 활성 전원 관리 옵션 이름 반환</summary>
        public static string GetActivePlanName()
        {
            try
            {
                string output = RunPowerCfg("/getactivescheme");
                // "전원 구성표 GUID: xxx  (고성능)" → 괄호 안 이름 추출
                var match = Regex.Match(output, @"\((.+?)\)");
                return match.Success ? match.Groups[1].Value : "Unknown";
            }
            catch { return "Unknown"; }
        }

        /// <summary>고성능 전원 설정 적용</summary>
        public bool ApplyHighPerformance()
        {
            try
            {
                _originalPlanGuid = GetActivePlanGuid();
                if (_originalPlanGuid == null) return false;

                // 고성능 전원 관리 옵션 활성화
                RunPowerCfg($"/setactive {HighPerformanceGuid}");

                // 최소 프로세서 상태 100% (AC 전원)
                RunPowerCfg("/setacvalueindex scheme_current sub_processor PROCTHROTTLEMIN 100");

                // PCI Express 링크 상태 전원 관리 = 끄기 (0)
                RunPowerCfg("/setacvalueindex scheme_current sub_pciexpress ASPM 0");

                // 변경사항 적용
                RunPowerCfg("/setactive scheme_current");

                Applied = true;
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>원래 전원 설정 복원</summary>
        public void Restore()
        {
            if (_restored || _originalPlanGuid == null) return;
            _restored = true;

            try
            {
                RunPowerCfg($"/setactive {_originalPlanGuid}");
            }
            catch { }
        }

        public void Dispose()
        {
            Restore();
        }

        private static string? GetActivePlanGuid()
        {
            string output = RunPowerCfg("/getactivescheme");
            // Output: "전원 구성표 GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (균형 조정)"
            var match = Regex.Match(output, @"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}");
            return match.Success ? match.Value : null;
        }

        private static string RunPowerCfg(string arguments)
        {
            var psi = new ProcessStartInfo
            {
                FileName = "powercfg",
                Arguments = arguments,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using var proc = Process.Start(psi);
            if (proc == null) return "";
            string output = proc.StandardOutput.ReadToEnd();
            proc.WaitForExit(5000);
            return output;
        }
    }
}
