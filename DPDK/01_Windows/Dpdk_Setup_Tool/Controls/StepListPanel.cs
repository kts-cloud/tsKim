using DpdkSetupTool.Steps;

namespace DpdkSetupTool.Controls;

public class StepListPanel : Panel
{
    private readonly List<StepLabel> _labels = new();
    private int _activeIndex = -1;

    public event Action<int>? StepClicked;

    public StepListPanel()
    {
        BackColor = Color.FromArgb(45, 45, 48);
        Width = 200;
        Dock = DockStyle.Left;
        AutoScroll = true;
        Padding = new Padding(0, 8, 0, 8);
    }

    public void SetSteps(IReadOnlyList<ISetupStep> steps)
    {
        Controls.Clear();
        _labels.Clear();

        for (int i = steps.Count - 1; i >= 0; i--)
        {
            var step = steps[i];
            var lbl = new StepLabel(i, step.Name)
            {
                Dock = DockStyle.Top,
                Height = 36,
                Padding = new Padding(12, 0, 8, 0)
            };
            int index = i;
            lbl.Click += (_, _) => StepClicked?.Invoke(index);
            _labels.Insert(0, lbl);
            Controls.Add(lbl);
        }
    }

    public void SetActiveStep(int index)
    {
        _activeIndex = index;
        Refresh();
    }

    public void UpdateStatus(int index, StepStatus status)
    {
        if (index >= 0 && index < _labels.Count)
            _labels[index].Status = status;
    }

    private class StepLabel : Label
    {
        private readonly int _index;
        [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
        public StepStatus Status { get; set; } = StepStatus.Pending;

        public StepLabel(int index, string name)
        {
            _index = index;
            Text = $"  {name}";
            ForeColor = Color.White;
            Font = new Font("Segoe UI", 9.5f);
            TextAlign = ContentAlignment.MiddleLeft;
            Cursor = Cursors.Hand;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            var parent = Parent as StepListPanel;
            bool isActive = parent?._activeIndex == _index;

            BackColor = isActive ? Color.FromArgb(62, 62, 66) : Color.FromArgb(45, 45, 48);

            // Status indicator
            var indicatorColor = Status switch
            {
                StepStatus.Completed => Color.LimeGreen,
                StepStatus.Running => Color.DodgerBlue,
                StepStatus.Failed => Color.OrangeRed,
                StepStatus.Skipped => Color.Gray,
                _ => Color.FromArgb(100, 100, 100)
            };

            string indicator = Status switch
            {
                StepStatus.Completed => "\u2714",  // ✔
                StepStatus.Running => "\u25B6",     // ▶
                StepStatus.Failed => "\u2716",      // ✖
                StepStatus.Skipped => "\u2500",     // ─
                _ => "\u25CB"                       // ○
            };

            Text = $" {indicator} {_index}. {Text.TrimStart(' ', '\u2714', '\u25B6', '\u2716', '\u2500', '\u25CB', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.')}";
            base.OnPaint(e);
        }
    }
}
