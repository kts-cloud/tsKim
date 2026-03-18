namespace DpdkSetupTool;

static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();

        bool resume = args.Any(a => a.Equals("--resume", StringComparison.OrdinalIgnoreCase));
        Application.Run(new SetupWizardForm(resume));
    }
}
