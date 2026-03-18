using DpdkSetupTool.Controls;

namespace DpdkSetupTool.Steps;

public abstract class SetupStepBase : ISetupStep
{
    public abstract string Name { get; }
    public abstract string Description { get; }
    public StepStatus Status { get; set; } = StepStatus.Pending;
    public virtual bool CanSkip => true;

    protected LogPanel? Log { get; private set; }
    protected Panel? ContentPanel { get; private set; }

    public Control CreateContent()
    {
        var container = new Panel { Dock = DockStyle.Fill };

        // Description label
        var descLabel = new Label
        {
            Text = Description,
            Dock = DockStyle.Top,
            AutoSize = false,
            Height = 40,
            Padding = new Padding(8, 8, 8, 0),
            Font = new Font("Segoe UI", 10f)
        };
        container.Controls.Add(descLabel);

        // Step-specific content area
        ContentPanel = new Panel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(8, 4, 8, 4)
        };
        container.Controls.Add(ContentPanel);
        ContentPanel.BringToFront();

        // Log panel at bottom
        Log = new LogPanel { Dock = DockStyle.Bottom, Height = 200 };
        container.Controls.Add(Log);

        OnCreateContent(ContentPanel);
        return container;
    }

    /// <summary>
    /// Override to add step-specific controls to the content panel.
    /// </summary>
    protected virtual void OnCreateContent(Panel panel) { }

    public abstract Task ExecuteAsync(CancellationToken ct);

    protected void LogInfo(string message) => Log?.AppendLog(message, Color.White);
    protected void LogSuccess(string message) => Log?.AppendLog(message, Color.LimeGreen);
    protected void LogWarning(string message) => Log?.AppendLog(message, Color.Yellow);
    protected void LogError(string message) => Log?.AppendLog(message, Color.OrangeRed);

    /// <summary>
    /// Get the project root directory (parent of Dpdk_Setup_Tool).
    /// </summary>
    public static string GetProjectRoot()
    {
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        // Navigate up from bin/Debug/net9.0-windows/ to project root, then to parent
        var dir = new DirectoryInfo(baseDir);
        while (dir != null && !File.Exists(Path.Combine(dir.FullName, "Dpdk_Setup_Tool.csproj")))
            dir = dir.Parent;
        return dir?.Parent?.FullName ?? Path.GetDirectoryName(baseDir)!;
    }
}
