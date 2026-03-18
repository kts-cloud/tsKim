namespace DpdkSetupTool.Controls;

public enum CheckStatus
{
    Pending,
    Checking,
    Passed,
    Warning,
    Failed
}

public class ChecklistItem
{
    public string Name { get; init; } = "";
    public string Detail { get; set; } = "";
    public CheckStatus Status { get; set; } = CheckStatus.Pending;
}

public class ChecklistPanel : Panel
{
    private readonly List<ChecklistItem> _items = new();
    private readonly ListView _listView;

    public ChecklistPanel()
    {
        _listView = new ListView
        {
            Dock = DockStyle.Fill,
            View = View.Details,
            FullRowSelect = true,
            GridLines = true,
            BackColor = Color.FromArgb(30, 30, 30),
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 9.5f),
            HeaderStyle = ColumnHeaderStyle.Nonclickable
        };

        _listView.Columns.Add("상태", 60, HorizontalAlignment.Center);
        _listView.Columns.Add("점검 항목", 280, HorizontalAlignment.Left);
        _listView.Columns.Add("결과", 350, HorizontalAlignment.Left);

        Controls.Add(_listView);
    }

    public void AddItem(ChecklistItem item)
    {
        _items.Add(item);
        var lvi = new ListViewItem(StatusIcon(item.Status));
        lvi.SubItems.Add(item.Name);
        lvi.SubItems.Add(item.Detail);
        lvi.ForeColor = StatusColor(item.Status);
        _listView.Items.Add(lvi);
    }

    public void UpdateItem(int index, CheckStatus status, string detail)
    {
        if (index < 0 || index >= _items.Count) return;

        _items[index].Status = status;
        _items[index].Detail = detail;

        if (_listView.InvokeRequired)
        {
            _listView.BeginInvoke(() => UpdateListViewItem(index, status, detail));
            return;
        }
        UpdateListViewItem(index, status, detail);
    }

    private void UpdateListViewItem(int index, CheckStatus status, string detail)
    {
        var lvi = _listView.Items[index];
        lvi.Text = StatusIcon(status);
        lvi.SubItems[2].Text = detail;
        lvi.ForeColor = StatusColor(status);
    }

    public int ItemCount => _items.Count;
    public ChecklistItem GetItem(int index) => _items[index];

    public bool AllPassed => _items.All(i =>
        i.Status == CheckStatus.Passed || i.Status == CheckStatus.Warning);

    private static string StatusIcon(CheckStatus s) => s switch
    {
        CheckStatus.Passed => "\u2714",   // ✔
        CheckStatus.Warning => "\u26A0",  // ⚠
        CheckStatus.Failed => "\u2716",   // ✖
        CheckStatus.Checking => "\u21BB", // ↻
        _ => "\u25CB"                     // ○
    };

    private static Color StatusColor(CheckStatus s) => s switch
    {
        CheckStatus.Passed => Color.LimeGreen,
        CheckStatus.Warning => Color.Yellow,
        CheckStatus.Failed => Color.OrangeRed,
        CheckStatus.Checking => Color.DodgerBlue,
        _ => Color.White
    };
}
