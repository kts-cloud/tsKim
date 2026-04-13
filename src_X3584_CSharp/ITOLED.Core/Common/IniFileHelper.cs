// =============================================================================
// IniFileHelper.cs
// Simple INI file helper using text parsing (no P/Invoke needed).
// Replaces Delphi TIniFile usage throughout CommonClass.pas.
// Namespace: Dongaeltek.ITOLED.Core.Common
// =============================================================================

using System.Globalization;
using System.Text;

namespace Dongaeltek.ITOLED.Core.Common;

/// <summary>
/// Lightweight INI file reader/writer that parses INI text directly.
/// Supports read/write of string, integer, boolean, and float values
/// with section/key organization. Thread-safe for concurrent reads
/// when no writes are occurring.
/// <para>Replaces Delphi's TIniFile (which uses kernel32 GetPrivateProfileString
/// under the hood).</para>
/// </summary>
public class IniFileHelper : IDisposable
{
    private readonly string _filePath;
    private readonly Dictionary<string, Dictionary<string, string>> _sections;
    private bool _modified;
    private bool _disposed;

    /// <summary>
    /// Gets the full path of the INI file.
    /// </summary>
    public string FilePath => _filePath;

    /// <summary>
    /// Creates a new IniFileHelper instance and loads the specified INI file.
    /// If the file does not exist, an empty configuration is created in memory.
    /// </summary>
    /// <param name="filePath">Full path to the INI file.</param>
    public IniFileHelper(string filePath)
    {
        _filePath = filePath ?? throw new ArgumentNullException(nameof(filePath));
        _sections = new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);
        _modified = false;

        if (File.Exists(filePath))
        {
            Load();
        }
    }

    // =========================================================================
    // Read Methods
    // =========================================================================

    /// <summary>
    /// Reads a string value from the INI file.
    /// </summary>
    /// <param name="section">Section name (case-insensitive).</param>
    /// <param name="key">Key name (case-insensitive).</param>
    /// <param name="defaultValue">Default value if the key is not found.</param>
    /// <returns>The value associated with the key, or <paramref name="defaultValue"/>.</returns>
    public string ReadString(string section, string key, string defaultValue = "")
    {
        if (_sections.TryGetValue(section, out var keys) &&
            keys.TryGetValue(key, out var value))
        {
            return value;
        }
        return defaultValue;
    }

    /// <summary>
    /// Reads an integer value from the INI file.
    /// </summary>
    /// <param name="section">Section name (case-insensitive).</param>
    /// <param name="key">Key name (case-insensitive).</param>
    /// <param name="defaultValue">Default value if the key is not found or cannot be parsed.</param>
    /// <returns>The integer value, or <paramref name="defaultValue"/>.</returns>
    public int ReadInteger(string section, string key, int defaultValue = 0)
    {
        var s = ReadString(section, key, null!);
        // Use InvariantCulture so the parser is independent of the operator
        // machine's locale (e.g. negative-sign handling on non-en cultures).
        if (s != null && int.TryParse(s.Trim(),
                NumberStyles.Integer, CultureInfo.InvariantCulture, out var result))
            return result;
        return defaultValue;
    }

    /// <summary>
    /// Reads a boolean value from the INI file.
    /// Recognizes "1", "true", "yes" as true (case-insensitive).
    /// </summary>
    /// <param name="section">Section name (case-insensitive).</param>
    /// <param name="key">Key name (case-insensitive).</param>
    /// <param name="defaultValue">Default value if the key is not found or cannot be parsed.</param>
    /// <returns>The boolean value, or <paramref name="defaultValue"/>.</returns>
    public bool ReadBool(string section, string key, bool defaultValue = false)
    {
        var s = ReadString(section, key, null!);
        if (s == null) return defaultValue;
        s = s.Trim();
        // Delphi TIniFile.ReadBool treats "1" and "true" (case-insensitive) as True
        if (s.Equals("1", StringComparison.Ordinal) ||
            s.Equals("true", StringComparison.OrdinalIgnoreCase) ||
            s.Equals("yes", StringComparison.OrdinalIgnoreCase))
            return true;
        if (s.Equals("0", StringComparison.Ordinal) ||
            s.Equals("false", StringComparison.OrdinalIgnoreCase) ||
            s.Equals("no", StringComparison.OrdinalIgnoreCase))
            return false;
        return defaultValue;
    }

    /// <summary>
    /// Reads a double-precision floating point value from the INI file.
    /// </summary>
    /// <param name="section">Section name (case-insensitive).</param>
    /// <param name="key">Key name (case-insensitive).</param>
    /// <param name="defaultValue">Default value if the key is not found or cannot be parsed.</param>
    /// <returns>The double value, or <paramref name="defaultValue"/>.</returns>
    public double ReadFloat(string section, string key, double defaultValue = 0.0)
    {
        var s = ReadString(section, key, null!);
        if (s != null && double.TryParse(s.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var result))
            return result;
        return defaultValue;
    }

    /// <summary>
    /// Reads all key names from a given section.
    /// </summary>
    /// <param name="section">Section name (case-insensitive).</param>
    /// <returns>List of key names, or empty list if section does not exist.</returns>
    public List<string> ReadSection(string section)
    {
        if (_sections.TryGetValue(section, out var keys))
            return new List<string>(keys.Keys);
        return new List<string>();
    }

    /// <summary>
    /// Checks whether a section exists in the INI file.
    /// </summary>
    /// <param name="section">Section name (case-insensitive).</param>
    /// <returns>True if the section exists.</returns>
    public bool SectionExists(string section)
    {
        return _sections.ContainsKey(section);
    }

    // =========================================================================
    // Write Methods
    // =========================================================================

    /// <summary>
    /// Writes a string value to the INI file (in-memory).
    /// Call <see cref="Flush"/> or <see cref="Dispose"/> to persist to disk.
    /// </summary>
    /// <param name="section">Section name (case-insensitive).</param>
    /// <param name="key">Key name (case-insensitive).</param>
    /// <param name="value">Value to write.</param>
    public void WriteString(string section, string key, string value)
    {
        if (!_sections.TryGetValue(section, out var keys))
        {
            keys = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            _sections[section] = keys;
        }
        keys[key] = value ?? string.Empty;
        _modified = true;
    }

    /// <summary>
    /// Writes an integer value to the INI file (in-memory).
    /// </summary>
    /// <param name="section">Section name.</param>
    /// <param name="key">Key name.</param>
    /// <param name="value">Integer value to write.</param>
    public void WriteInteger(string section, string key, int value)
    {
        WriteString(section, key, value.ToString());
    }

    /// <summary>
    /// Writes a boolean value to the INI file (in-memory).
    /// Written as "1" (true) or "0" (false), matching Delphi TIniFile behavior.
    /// </summary>
    /// <param name="section">Section name.</param>
    /// <param name="key">Key name.</param>
    /// <param name="value">Boolean value to write.</param>
    public void WriteBool(string section, string key, bool value)
    {
        WriteString(section, key, value ? "1" : "0");
    }

    /// <summary>
    /// Writes a double-precision floating point value to the INI file (in-memory).
    /// </summary>
    /// <param name="section">Section name.</param>
    /// <param name="key">Key name.</param>
    /// <param name="value">Double value to write.</param>
    public void WriteFloat(string section, string key, double value)
    {
        WriteString(section, key, value.ToString(CultureInfo.InvariantCulture));
    }

    /// <summary>
    /// Removes an entire section from the INI file (in-memory).
    /// </summary>
    /// <param name="section">Section name to erase.</param>
    public void EraseSection(string section)
    {
        if (_sections.Remove(section))
            _modified = true;
    }

    // =========================================================================
    // Persistence
    // =========================================================================

    /// <summary>
    /// Writes any pending changes to disk. Equivalent to Delphi's TIniFile.UpdateFile.
    /// </summary>
    public void Flush()
    {
        if (!_modified) return;
        Save();
        _modified = false;
    }

    /// <summary>
    /// Reloads the INI file from disk, discarding any unsaved in-memory changes.
    /// </summary>
    public void Reload()
    {
        _sections.Clear();
        if (File.Exists(_filePath))
            Load();
        _modified = false;
    }

    /// <summary>
    /// Disposes the helper, flushing any pending changes to disk.
    /// </summary>
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        if (_modified)
        {
            try { Save(); }
            catch { /* swallow during dispose, matching Delphi behavior */ }
        }
        GC.SuppressFinalize(this);
    }

    // =========================================================================
    // Internal Load/Save
    // =========================================================================

    private void Load()
    {
        string? currentSection = null;
        foreach (var rawLine in File.ReadAllLines(_filePath, Encoding.Default))
        {
            var line = rawLine.Trim();

            // Skip empty lines and comments
            if (string.IsNullOrEmpty(line) || line[0] == ';' || line[0] == '#')
                continue;

            // Section header
            if (line[0] == '[')
            {
                int end = line.IndexOf(']');
                if (end > 1)
                {
                    currentSection = line.Substring(1, end - 1).Trim();
                    if (!_sections.ContainsKey(currentSection))
                        _sections[currentSection] = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                }
                continue;
            }

            // Key=Value
            if (currentSection != null)
            {
                int eqPos = line.IndexOf('=');
                if (eqPos > 0)
                {
                    var key = line.Substring(0, eqPos).Trim();
                    var value = line.Substring(eqPos + 1); // Preserve leading spaces in value (Delphi behavior)
                    _sections[currentSection][key] = value;
                }
            }
        }
    }

    private void Save()
    {
        var dir = Path.GetDirectoryName(_filePath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        // If the file already exists, preserve section order and comments
        // For simplicity and correctness, we do a full rewrite
        var sb = new StringBuilder();
        foreach (var section in _sections)
        {
            sb.AppendLine($"[{section.Key}]");
            foreach (var kv in section.Value)
            {
                sb.AppendLine($"{kv.Key}={kv.Value}");
            }
            sb.AppendLine();
        }

        // Atomic write: serialize to a temp file, then rename over the target.
        // Prevents corruption (empty / truncated INI) when the process or host
        // crashes mid-write, which previously made the app unable to restart.
        var tmpPath = _filePath + ".tmp";
        File.WriteAllText(tmpPath, sb.ToString(), Encoding.Default);
        File.Move(tmpPath, _filePath, overwrite: true);
    }
}
