// =============================================================================
// FactoryAssemblyLoadContext.cs
// Custom AssemblyLoadContext for Factory DLLs (LGD_OC_X3584.dll, etc.).
//
// Shared assemblies (LGD_OC_AstractPlatForm, Observers, MathNet, etc.) are
// delegated to the Default ALC to ensure type identity — ICompensationFlow
// loaded in Factory ALC is the same type as ICompensationFlow in Default ALC.
//
// Only the Factory DLL itself (and any private dependencies) are loaded in
// this isolated context.
// =============================================================================

using System.Reflection;
using System.Runtime.Loader;

namespace Dongaeltek.ITOLED.BusinessLogic.Dll;

/// <summary>
/// Isolated ALC for loading Factory DLLs while sharing common type assemblies
/// with the Default ALC.
/// </summary>
public class FactoryAssemblyLoadContext : AssemblyLoadContext
{
    private readonly string _dllDirectory;

    /// <summary>
    /// Assemblies that must be shared with Default ALC for type identity.
    /// These are the base framework DLLs and common dependencies used by
    /// both the main application and the Factory DLLs.
    /// </summary>
    private static readonly HashSet<string> SharedAssemblies = new(StringComparer.OrdinalIgnoreCase)
    {
        "LGD_OC_AstractPlatForm",
        "LGD_OC_Observers",
        "LGD_OC_Standard_InitAlgorithm",
        "LGD_OC_Standard_SearchingAlgorithm",
        "LGD_OC_Standard_SearchingAlgorithm_PCLC",
        "MathNet.Numerics",
        "MathNet.Filtering",
        "MTOOptimization",
        "Newtonsoft.Json",
    };

    public FactoryAssemblyLoadContext(string name, string dllDirectory)
        : base(name, isCollectible: false)
    {
        _dllDirectory = dllDirectory;
    }

    protected override Assembly? Load(AssemblyName assemblyName)
    {
        // Shared assemblies → return null to fall back to Default ALC
        if (SharedAssemblies.Contains(assemblyName.Name ?? ""))
            return null;

        // Try to load from the Factory DLL's directory
        var path = Path.Combine(_dllDirectory, (assemblyName.Name ?? "") + ".dll");
        if (File.Exists(path))
            return LoadFromAssemblyPath(path);

        // Fall back to Default ALC for anything else
        return null;
    }
}
