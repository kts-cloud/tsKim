namespace DpdkSetupTool.Steps;

public enum StepStatus
{
    Pending,
    Running,
    Completed,
    Failed,
    Skipped
}

public interface ISetupStep
{
    string Name { get; }
    string Description { get; }
    StepStatus Status { get; set; }

    /// <summary>
    /// Create step-specific UI controls to display in the content panel.
    /// </summary>
    Control CreateContent();

    /// <summary>
    /// Execute this step asynchronously with cancellation support.
    /// </summary>
    Task ExecuteAsync(CancellationToken ct);

    /// <summary>
    /// Whether this step can be skipped by the user.
    /// </summary>
    bool CanSkip { get; }
}
