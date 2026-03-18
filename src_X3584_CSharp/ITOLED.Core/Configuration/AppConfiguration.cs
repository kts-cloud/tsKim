namespace Dongaeltek.ITOLED.Core.Configuration;

/// <summary>
/// Runtime replacement for Delphi's Common.inc conditional compilation.
/// Loaded from appsettings.json at startup.
/// </summary>
public class AppConfiguration
{
    /// <summary>
    /// Application root directory override.
    /// When set, used as the base for INI, LOG, DATA, MODEL, etc. directories
    /// instead of the default <c>AppContext.BaseDirectory</c> (exe location).
    /// <para>Example: <c>"D:\\Dongaeltek\\_Project\\...\\IT_OLED_OC_X3584_CSharp"</c></para>
    /// </summary>
    public string? RootDirectory { get; set; }

    /// <summary>Inspector variant: OC, PreOC</summary>
    public InspectorType Inspector { get; set; } = InspectorType.OC;

    /// <summary>Pattern generator hardware: DP860 or AF9</summary>
    public PgType PatternGenerator { get; set; } = PgType.DP860;

    /// <summary>Colorimeter hardware: CA410 or CA310</summary>
    public ColorimeterType Colorimeter { get; set; } = ColorimeterType.CA410;

    /// <summary>AF9 API mode: SingleChannel or Multi</summary>
    public Af9ApiMode Af9Api { get; set; } = Af9ApiMode.SingleChannel;

    /// <summary>Simulator flags (combinable)</summary>
    public SimulatorFlags Simulator { get; set; } = SimulatorFlags.None;

    /// <summary>Enable gray level offset feature</summary>
    public bool FeatureGrayChange { get; set; } = true;

    /// <summary>Enable flash memory access feature</summary>
    public bool FeatureFlashAccess { get; set; } = true;

    /// <summary>Use DFS (Data File Server) for file transfer</summary>
    public bool UseDfs { get; set; } = true;

    /// <summary>Use EAS (Equipment Automation System)</summary>
    public bool UseEas { get; set; } = true;

    /// <summary>DFS hex mode (requires UseDfs = true)</summary>
    public bool DfsHex { get; set; } = true;

    /// <summary>DFS offline mode (requires UseDfs = true)</summary>
    public bool DfsOffline { get; set; } = true;

    /// <summary>Use ADLINK DIO card</summary>
    public bool UseAdlinkDio { get; set; }

    /// <summary>Use AXDIO</summary>
    public bool UseAxDio { get; set; }

    /// <summary>Use touch screen mode</summary>
    public bool UseTouch { get; set; }

    /// <summary>60-channel DIO mode (false = 96 channel)</summary>
    public bool Dio60Channel { get; set; }

    /// <summary>
    /// Maximum number of PG (pattern generator) instances.
    /// Used by CommPgDriver for UDP server base-port binding.
    /// <para>Delphi: MAX_PG_CNT constant, here configurable at runtime.</para>
    /// </summary>
    public int MaxPgCount { get; set; } = 4;

    /// <summary>Check if running in any simulator mode</summary>
    public bool IsSimulator => Simulator != SimulatorFlags.None;
}

public enum InspectorType
{
    OC,
    PreOC
}

public enum PgType
{
    DP860,
    AF9
}

public enum ColorimeterType
{
    CA410,
    CA310
}

public enum Af9ApiMode
{
    SingleChannel,
    Multi
}

[Flags]
public enum SimulatorFlags
{
    None = 0,
    Dio = 1 << 0,
    Pg = 1 << 1,
    Bcr = 1 << 2,
    Cax10 = 1 << 3,
    Gmes = 1 << 4,
    All = Dio | Pg | Bcr | Cax10 | Gmes
}
