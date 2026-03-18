// =============================================================================
// OcFactoryConfig.cs
// JSON configuration model for OC_Factory_Config.json entries.
// Each entry maps a DLL index to a Factory DLL path and entry-point class name.
// =============================================================================

namespace Dongaeltek.ITOLED.BusinessLogic.Dll;

/// <summary>
/// Configuration entry for a single Factory DLL (e.g. LGD_OC_X3584.dll).
/// Deserialized from OC_Factory_Config.json.
/// </summary>
public class OcFactoryConfig
{
    /// <summary>Factory DLL index (0, 1, 2, ...).</summary>
    public int Id { get; set; }

    /// <summary>Relative path to the Factory DLL from LGDDLL directory.</summary>
    public string DllPath { get; set; } = "";

    /// <summary>Fully-qualified class name of the CompensationFlow type.</summary>
    public string ClassName { get; set; } = "";

    /// <summary>Subscriber type (0 = OCRM, 1 = MTO, etc.).</summary>
    public int SubscriberType { get; set; }
}
