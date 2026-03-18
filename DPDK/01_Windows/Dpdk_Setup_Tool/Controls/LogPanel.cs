namespace DpdkSetupTool.Controls;

public class LogPanel : Panel
{
    private readonly RichTextBox _rtb;

    public LogPanel()
    {
        BorderStyle = BorderStyle.FixedSingle;

        _rtb = new RichTextBox
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            BackColor = Color.FromArgb(30, 30, 30),
            ForeColor = Color.White,
            Font = new Font("Consolas", 9f),
            WordWrap = false,
            ScrollBars = RichTextBoxScrollBars.Both
        };

        Controls.Add(_rtb);
    }

    public void AppendLog(string message, Color color)
    {
        if (_rtb.InvokeRequired)
        {
            _rtb.BeginInvoke(() => AppendLogInternal(message, color));
            return;
        }
        AppendLogInternal(message, color);
    }

    private void AppendLogInternal(string message, Color color)
    {
        string timestamp = DateTime.Now.ToString("HH:mm:ss");
        string line = $"[{timestamp}] {message}\n";

        _rtb.SelectionStart = _rtb.TextLength;
        _rtb.SelectionLength = 0;
        _rtb.SelectionColor = color;
        _rtb.AppendText(line);
        _rtb.ScrollToCaret();
    }

    public void Clear()
    {
        if (_rtb.InvokeRequired)
        {
            _rtb.BeginInvoke(() => _rtb.Clear());
            return;
        }
        _rtb.Clear();
    }
}
