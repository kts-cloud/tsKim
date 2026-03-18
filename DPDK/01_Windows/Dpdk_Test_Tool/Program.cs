using HwNet;

namespace DpdkTestTool
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            // 비정상 종료 시에도 DPDK hugepage 메모리 해제
            AppDomain.CurrentDomain.ProcessExit += (s, e) =>
            {
                try { HwManager.Instance.Cleanup(); } catch { }
            };

            // 전역 예외 핸들러 — 미처리 예외로 인한 강제종료 방지
            Application.ThreadException += (s, e) =>
            {
                try
                {
                    System.IO.File.AppendAllText(
                        System.IO.Path.Combine(AppContext.BaseDirectory, "crash_log.txt"),
                        $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] ThreadException: {e.Exception}\n\n");
                }
                catch { }
                MessageBox.Show(
                    $"오류가 발생했습니다:\n{e.Exception.Message}\n\n상세 로그: crash_log.txt",
                    "오류", MessageBoxButtons.OK, MessageBoxIcon.Error);
            };

            AppDomain.CurrentDomain.UnhandledException += (s, e) =>
            {
                try
                {
                    var ex = e.ExceptionObject as Exception;
                    System.IO.File.AppendAllText(
                        System.IO.Path.Combine(AppContext.BaseDirectory, "crash_log.txt"),
                        $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] UnhandledException (IsTerminating={e.IsTerminating}): {ex}\n\n");
                    HwManager.Instance.Cleanup();
                }
                catch { }
            };

            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
            Application.SetHighDpiMode(HighDpiMode.SystemAware);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new UI.MainForm());
        }
    }
}
