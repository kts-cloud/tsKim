// =============================================================================
// EcsGridConfigLoader.cs — Loads ECS Status polling grid column/bit definitions
// from INI/EcsStatusGrid.ini. Replaces hardcoded BuildPollingColumns() with a
// configurable INI file matching Delphi Init_Grid + SetCellState patterns.
// =============================================================================

namespace Dongaeltek.ITOLED.OC.Services;

/// <summary>
/// Loads and provides ECS status grid column/bit definitions from an INI file.
/// Each column maps to a PLC polling data source (EQP/Robot/ECS division + array index).
/// Individual bits can override the default data source via BitNN_Src entries.
/// </summary>
public sealed class EcsGridConfigLoader
{
    /// <summary>
    /// Defines a grid column with its data source and 16 bit definitions.
    /// </summary>
    public sealed class GridColumnDef
    {
        public int ColumnNumber { get; init; }
        public string Label { get; init; } = "";
        public string Group { get; init; } = "";      // "EQP", "Robot", "ECS"
        public int DefaultDivision { get; init; }       // 0=EQP, 1=Robot, 2=ECS
        public int DefaultIndex { get; init; }          // Array index into PollingXxx[]
        public BitDef[] Bits { get; init; } = new BitDef[16];
    }

    /// <summary>
    /// Defines a single bit cell: its label (tooltip), and the actual data source to read.
    /// </summary>
    public sealed class BitDef
    {
        public string Label { get; init; } = "";        // Empty = undefined bit
        public int Division { get; init; }              // Data source division
        public int Index { get; init; }                 // Data source array index
        public int BitLoc { get; init; }                // Actual bit position to read
    }

    public List<GridColumnDef> Columns { get; private set; } = new();

    /// <summary>
    /// Loads grid configuration from the specified INI file path.
    /// If the file doesn't exist, Columns remains empty (grid disabled).
    /// </summary>
    public void Load(string iniPath)
    {
        Columns.Clear();

        if (!File.Exists(iniPath))
            return;

        // Parse INI into sections
        var sections = ParseIni(iniPath);

        // Read column count from [Grid]
        int columnCount = 0;
        if (sections.TryGetValue("Grid", out var gridSection))
        {
            if (gridSection.TryGetValue("ColumnCount", out var countStr))
                int.TryParse(countStr, out columnCount);
        }

        // Parse each [Column_NN] section
        for (int colNum = 1; colNum <= columnCount; colNum++)
        {
            var sectionName = $"Column_{colNum:D2}";
            if (!sections.TryGetValue(sectionName, out var colSection))
                continue;

            colSection.TryGetValue("Label", out var label);
            colSection.TryGetValue("Group", out var group);
            colSection.TryGetValue("Division", out var divStr);
            colSection.TryGetValue("Index", out var idxStr);

            int defaultDiv = 0, defaultIdx = 0;
            if (divStr != null) int.TryParse(divStr, out defaultDiv);
            if (idxStr != null) int.TryParse(idxStr, out defaultIdx);

            var bits = new BitDef[16];
            for (int b = 0; b < 16; b++)
            {
                var bitKey = $"Bit{b:D2}";
                colSection.TryGetValue(bitKey, out var bitLabel);

                // Check for source override: BitNN_Src=Division,Index[,BitLoc]
                int srcDiv = defaultDiv;
                int srcIdx = defaultIdx;
                int srcBitLoc = b;

                var srcKey = $"Bit{b:D2}_Src";
                if (colSection.TryGetValue(srcKey, out var srcStr) && !string.IsNullOrEmpty(srcStr))
                {
                    var parts = srcStr.Split(',');
                    if (parts.Length >= 2)
                    {
                        int.TryParse(parts[0].Trim(), out srcDiv);
                        int.TryParse(parts[1].Trim(), out srcIdx);
                    }
                    if (parts.Length >= 3)
                    {
                        int.TryParse(parts[2].Trim(), out srcBitLoc);
                    }
                }

                bits[b] = new BitDef
                {
                    Label = bitLabel ?? "",
                    Division = srcDiv,
                    Index = srcIdx,
                    BitLoc = srcBitLoc
                };
            }

            Columns.Add(new GridColumnDef
            {
                ColumnNumber = colNum,
                Label = label ?? $"Col {colNum}",
                Group = group ?? "EQP",
                DefaultDivision = defaultDiv,
                DefaultIndex = defaultIdx,
                Bits = bits
            });
        }
    }

    /// <summary>
    /// Simple INI parser: returns Dictionary&lt;sectionName, Dictionary&lt;key, value&gt;&gt;.
    /// Supports ; comments and standard [Section] Key=Value format.
    /// </summary>
    private static Dictionary<string, Dictionary<string, string>> ParseIni(string path)
    {
        var result = new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);
        string currentSection = "";

        foreach (var rawLine in File.ReadAllLines(path))
        {
            var line = rawLine.Trim();

            // Skip empty lines and comments
            if (string.IsNullOrEmpty(line) || line.StartsWith(';') || line.StartsWith('#'))
                continue;

            // Section header
            if (line.StartsWith('[') && line.EndsWith(']'))
            {
                currentSection = line[1..^1].Trim();
                if (!result.ContainsKey(currentSection))
                    result[currentSection] = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                continue;
            }

            // Key=Value pair
            var eqIdx = line.IndexOf('=');
            if (eqIdx > 0 && !string.IsNullOrEmpty(currentSection))
            {
                var key = line[..eqIdx].Trim();
                var value = line[(eqIdx + 1)..].Trim();
                if (!result.ContainsKey(currentSection))
                    result[currentSection] = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                result[currentSection][key] = value;
            }
        }

        return result;
    }
}
