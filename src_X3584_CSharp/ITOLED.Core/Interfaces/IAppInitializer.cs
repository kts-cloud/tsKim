// =============================================================================
// IAppInitializer.cs — SW initialization service interface
// Equivalent to Delphi Main_OC.pas: InitialAll + CreateClassData
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Manages full software initialization (stop hardware → reload config → restart hardware).
/// Equivalent to Delphi <c>TfrmMain_OC.InitialAll(True)</c> + <c>CreateClassData</c>.
/// </summary>
public interface IAppInitializer
{
    /// <summary>
    /// Performs full SW initialization: stops all hardware, reloads configuration
    /// from INI/MCF, and restarts hardware with updated settings.
    /// </summary>
    /// <returns>True if initialization completed successfully.</returns>
    Task<bool> InitializeAllAsync();

    /// <summary>
    /// Whether initialization can proceed (not in AutoMode, not currently closing).
    /// </summary>
    bool CanInitialize { get; }
}
