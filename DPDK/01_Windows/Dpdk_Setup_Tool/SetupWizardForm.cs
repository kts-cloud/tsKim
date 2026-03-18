using HwNet.Utilities;
using DpdkSetupTool.Controls;
using DpdkSetupTool.Steps;
using DpdkSetupTool.Utils;

namespace DpdkSetupTool;

public class SetupWizardForm : Form
{
    private readonly StepListPanel _stepList;
    private readonly Panel _contentPanel;
    private readonly ProgressBar _progressBar;
    private readonly Label _statusLabel;
    private readonly Button _btnRun;
    private readonly Button _btnSkip;
    private readonly Button _btnCancel;

    private readonly List<ISetupStep> _steps;
    private int _currentStepIndex;
    private CancellationTokenSource? _cts;
    private readonly bool _resumeMode;

    public SetupWizardForm(bool resume)
    {
        _resumeMode = resume;
        Text = "DPDK Windows Setup Tool";
        Size = new Size(1000, 700);
        MinimumSize = new Size(800, 600);
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(37, 37, 38);
        ForeColor = Color.White;

        // Step list (left panel)
        _stepList = new StepListPanel();
        _stepList.StepClicked += OnStepClicked;
        Controls.Add(_stepList);

        // Bottom bar
        var bottomBar = new Panel
        {
            Dock = DockStyle.Bottom,
            Height = 60,
            BackColor = Color.FromArgb(45, 45, 48),
            Padding = new Padding(12, 8, 12, 8)
        };
        Controls.Add(bottomBar);

        _progressBar = new ProgressBar
        {
            Dock = DockStyle.Top,
            Height = 18,
            Style = ProgressBarStyle.Continuous
        };
        bottomBar.Controls.Add(_progressBar);

        _statusLabel = new Label
        {
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleLeft,
            Font = new Font("Segoe UI", 9f),
            ForeColor = Color.LightGray
        };
        bottomBar.Controls.Add(_statusLabel);
        _statusLabel.BringToFront();

        var buttonPanel = new FlowLayoutPanel
        {
            Dock = DockStyle.Right,
            FlowDirection = FlowDirection.LeftToRight,
            AutoSize = true,
            WrapContents = false,
            Padding = new Padding(0, 2, 0, 0)
        };
        bottomBar.Controls.Add(buttonPanel);

        _btnRun = new Button
        {
            Text = "\u25B6 실행",
            Width = 90,
            Height = 32,
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(0, 122, 204),
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 9.5f)
        };
        _btnRun.Click += async (_, _) => await RunCurrentStep();
        buttonPanel.Controls.Add(_btnRun);

        _btnSkip = new Button
        {
            Text = "\u23ED 건너뛰기",
            Width = 100,
            Height = 32,
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(80, 80, 80),
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 9.5f)
        };
        _btnSkip.Click += (_, _) => SkipCurrentStep();
        buttonPanel.Controls.Add(_btnSkip);

        _btnCancel = new Button
        {
            Text = "\u25A0 취소",
            Width = 80,
            Height = 32,
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(180, 50, 50),
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 9.5f),
            Enabled = false
        };
        _btnCancel.Click += (_, _) => CancelCurrentStep();
        buttonPanel.Controls.Add(_btnCancel);

        // Content panel (center)
        _contentPanel = new Panel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(4)
        };
        Controls.Add(_contentPanel);
        _contentPanel.BringToFront();

        // Initialize steps
        _steps = new List<ISetupStep>
        {
            new SystemCheckStep(),
            new SoftwareInstallStep(),
            new SystemConfigStep(),
            new DpdkBuildStep(),
            new ShimBuildStep(),
            new DpdkNetBuildStep(),
            new DriverInstallStep(),
            new NicBindingStep(),
            new DeployVerifyStep()
        };

        _stepList.SetSteps(_steps);

        new PowerPlanHelper().ApplyHighPerformance();
    }

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);

        int startStep = 0;

        if (_resumeMode)
        {
            var state = SetupState.Load();
            if (state != null)
            {
                startStep = state.CurrentStep;
                foreach (var kv in state.StepStatuses)
                {
                    if (kv.Key < _steps.Count)
                    {
                        _steps[kv.Key].Status = kv.Value;
                        _stepList.UpdateStatus(kv.Key, kv.Value);
                    }
                }
            }
        }

        NavigateToStep(startStep);
    }

    private void NavigateToStep(int index)
    {
        if (index < 0 || index >= _steps.Count) return;

        _currentStepIndex = index;
        _stepList.SetActiveStep(index);

        _contentPanel.Controls.Clear();
        var content = _steps[index].CreateContent();
        content.Dock = DockStyle.Fill;
        _contentPanel.Controls.Add(content);

        UpdateButtons();
        UpdateStatus();
    }

    private void OnStepClicked(int index)
    {
        if (_cts != null) return; // Don't navigate while running
        NavigateToStep(index);
    }

    private void UpdateButtons()
    {
        var step = _steps[_currentStepIndex];
        bool isRunning = _cts != null;

        _btnRun.Enabled = !isRunning && step.Status != StepStatus.Running;
        _btnSkip.Enabled = !isRunning && step.CanSkip;
        _btnCancel.Enabled = isRunning;
    }

    private void UpdateStatus()
    {
        int completed = _steps.Count(s => s.Status == StepStatus.Completed || s.Status == StepStatus.Skipped);
        _progressBar.Maximum = _steps.Count;
        _progressBar.Value = completed;
        _statusLabel.Text = $"Step {_currentStepIndex}/{_steps.Count - 1}: {_steps[_currentStepIndex].Name}";
    }

    private async Task RunCurrentStep()
    {
        var step = _steps[_currentStepIndex];
        _cts = new CancellationTokenSource();

        step.Status = StepStatus.Running;
        _stepList.UpdateStatus(_currentStepIndex, StepStatus.Running);
        UpdateButtons();

        try
        {
            await step.ExecuteAsync(_cts.Token);
            step.Status = StepStatus.Completed;
            _stepList.UpdateStatus(_currentStepIndex, StepStatus.Completed);

            // Auto-advance to next step
            if (_currentStepIndex < _steps.Count - 1)
                NavigateToStep(_currentStepIndex + 1);
        }
        catch (OperationCanceledException)
        {
            step.Status = StepStatus.Pending;
            _stepList.UpdateStatus(_currentStepIndex, StepStatus.Pending);
        }
        catch (Exception ex)
        {
            step.Status = StepStatus.Failed;
            _stepList.UpdateStatus(_currentStepIndex, StepStatus.Failed);
            MessageBox.Show($"스텝 실패: {ex.Message}", "오류",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally
        {
            _cts.Dispose();
            _cts = null;
            UpdateButtons();
            UpdateStatus();
            SaveState();
        }
    }

    private void SkipCurrentStep()
    {
        var step = _steps[_currentStepIndex];
        step.Status = StepStatus.Skipped;
        _stepList.UpdateStatus(_currentStepIndex, StepStatus.Skipped);
        SaveState();

        if (_currentStepIndex < _steps.Count - 1)
            NavigateToStep(_currentStepIndex + 1);
    }

    private void CancelCurrentStep()
    {
        _cts?.Cancel();
    }

    private void SaveState()
    {
        var state = new SetupState
        {
            CurrentStep = _currentStepIndex,
            ProjectRoot = SetupStepBase.GetProjectRoot(),
            StepStatuses = new Dictionary<int, StepStatus>()
        };
        for (int i = 0; i < _steps.Count; i++)
            state.StepStatuses[i] = _steps[i].Status;
        state.Save();
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (_cts != null)
        {
            var result = MessageBox.Show("진행 중인 스텝이 있습니다. 정말 종료하시겠습니까?",
                "확인", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
            if (result == DialogResult.No)
            {
                e.Cancel = true;
                return;
            }
            _cts.Cancel();
        }
        base.OnFormClosing(e);
    }
}
