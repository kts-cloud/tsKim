// =============================================================================
// SplashForm.cs — Startup progress splash screen
// Shows initialization progress while services are being configured.
// =============================================================================

namespace Dongaeltek.ITOLED.OC;

/// <summary>
/// Borderless splash form shown during application startup.
/// Displays a progress bar and status message for each initialization step.
/// </summary>
public sealed class SplashForm : Form
{
    private readonly Label _titleLabel;
    private readonly Label _statusLabel;
    private readonly ProgressBar _progressBar;

    public SplashForm()
    {
        // ── Form properties ──────────────────────────────────────
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        TopMost = true;
        Size = new Size(480, 200);
        BackColor = Color.FromArgb(30, 30, 46);
        ShowInTaskbar = false;

        // ── Title ────────────────────────────────────────────────
        _titleLabel = new Label
        {
            Text = "ITOLED OC",
            Font = new Font("Segoe UI", 22f, FontStyle.Bold),
            ForeColor = Color.White,
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Dock = DockStyle.Top,
            Height = 80,
        };

        // ── Status message ───────────────────────────────────────
        _statusLabel = new Label
        {
            Text = "Starting...",
            Font = new Font("Segoe UI", 10f),
            ForeColor = Color.FromArgb(180, 180, 200),
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Dock = DockStyle.Top,
            Height = 40,
        };

        // ── Progress bar ─────────────────────────────────────────
        var barPanel = new Panel
        {
            Dock = DockStyle.Top,
            Height = 36,
            Padding = new Padding(40, 8, 40, 8),
        };
        _progressBar = new ProgressBar
        {
            Dock = DockStyle.Fill,
            Minimum = 0,
            Maximum = 100,
            Value = 0,
            Style = ProgressBarStyle.Continuous,
        };
        barPanel.Controls.Add(_progressBar);

        // ── Version label ────────────────────────────────────────
        var versionLabel = new Label
        {
            Text = $"v{System.Reflection.Assembly.GetExecutingAssembly().GetName().Version}",
            Font = new Font("Segoe UI", 8f),
            ForeColor = Color.FromArgb(100, 100, 120),
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Dock = DockStyle.Fill,
        };

        // ── Layout (Dock order is bottom-up) ─────────────────────
        Controls.Add(versionLabel);   // fills remaining space
        Controls.Add(barPanel);       // docked top (3rd)
        Controls.Add(_statusLabel);   // docked top (2nd)
        Controls.Add(_titleLabel);    // docked top (1st)
    }

    /// <summary>
    /// Updates the progress bar and status message, then pumps the message queue
    /// so the splash remains responsive before <c>Application.Run()</c> is called.
    /// </summary>
    public void UpdateProgress(string message, int percent)
    {
        _statusLabel.Text = message;
        _progressBar.Value = Math.Clamp(percent, 0, 100);
        Application.DoEvents();
    }
}
