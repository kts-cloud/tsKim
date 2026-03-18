namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Service for loading and accessing model (product) configuration.
/// Replaces Delphi's ModelInfo form and CommonClass model-loading logic.
/// </summary>
public interface IModelInfoService
{
    /// <summary>Currently loaded model name.</summary>
    string CurrentModelName { get; }

    /// <summary>Whether a model is currently loaded and valid.</summary>
    bool IsModelLoaded { get; }

    /// <summary>
    /// Loads the specified model's data files from disk.
    /// Returns true on success.
    /// </summary>
    bool LoadModel(string modelName);

    /// <summary>
    /// Reloads the currently loaded model from disk.
    /// Returns true on success.
    /// </summary>
    bool ReloadCurrentModel();

    /// <summary>
    /// Gets a list of available model names from the data directory.
    /// </summary>
    IReadOnlyList<string> GetAvailableModels();

    /// <summary>
    /// Gets a model-specific configuration value as string.
    /// </summary>
    string GetModelValue(string section, string key, string defaultValue = "");

    /// <summary>
    /// Gets a model-specific configuration value as integer.
    /// </summary>
    int GetModelValueInt(string section, string key, int defaultValue = 0);

    /// <summary>
    /// Gets a model-specific configuration value as double.
    /// </summary>
    double GetModelValueDouble(string section, string key, double defaultValue = 0.0);

    /// <summary>
    /// Sets a model-specific configuration value.
    /// </summary>
    void SetModelValue(string section, string key, string value);

    /// <summary>
    /// Saves model configuration changes to disk.
    /// </summary>
    void SaveModelConfig();

    /// <summary>
    /// Fired when a model is successfully loaded or changed.
    /// </summary>
    event EventHandler<ModelLoadedEventArgs>? ModelLoaded;
}

/// <summary>
/// Event data for <see cref="IModelInfoService.ModelLoaded"/>.
/// </summary>
public class ModelLoadedEventArgs : EventArgs
{
    public string ModelName { get; }
    public bool IsReload { get; }

    public ModelLoadedEventArgs(string modelName, bool isReload)
    {
        ModelName = modelName;
        IsReload = isReload;
    }
}
