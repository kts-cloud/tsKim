// =============================================================================
// IDfsService.cs
// Converted from Delphi: src_X3584\DfsFtp.pas
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Dfs
//
// Defines the contract for DFS (Data File Server) file transfers via FTP.
// Original Delphi class: TDfsFtp — wraps Indy TIdFTP with DFS hash-path
// routing, HEX_INDEX management, COMBI code download, and GUI notifications.
// =============================================================================

namespace Dongaeltek.ITOLED.BusinessLogic.Dfs;

/// <summary>
/// Result information returned after a DFS HEX file download.
/// <para>Original Delphi: TDfsRetInfo (DfsFtp.pas line 29)</para>
/// </summary>
public class DfsReturnInfo
{
    /// <summary>
    /// Local path of the downloaded HEX file.
    /// <para>Delphi field: HexFileName : String (DFS_HEX)</para>
    /// </summary>
    public string HexFileName { get; set; } = string.Empty;

    /// <summary>
    /// Number of defects detected.
    /// <para>Delphi field: nDefectCnt : Integer (DFS_DEFECT)</para>
    /// </summary>
    public int DefectCount { get; set; }

    /// <summary>
    /// Number of pre-process defects.
    /// <para>Delphi field: nPreDefectCnt : Integer (DFS_DEFECT)</para>
    /// </summary>
    public int PreDefectCount { get; set; }

    /// <summary>
    /// Whether final defect is NG.
    /// <para>Delphi field: FinalDftNG : Boolean (DFS_DEFECT)</para>
    /// </summary>
    public bool FinalDefectNg { get; set; }

    /// <summary>
    /// Final defect name.
    /// <para>Delphi field: FinalDftName : string (DFS_DEFECT)</para>
    /// </summary>
    public string FinalDefectName { get; set; } = string.Empty;

    /// <summary>
    /// Final defect code.
    /// <para>Delphi field: FinalDftCode : string (DFS_DEFECT)</para>
    /// </summary>
    public string FinalDefectCode { get; set; } = string.Empty;

    /// <summary>
    /// Defect file name on disk.
    /// <para>Delphi field: DefectFileName : string (DFS_DEFECT)</para>
    /// </summary>
    public string DefectFileName { get; set; } = string.Empty;

    /// <summary>
    /// Lot ID.
    /// <para>Delphi field: LotID : string (DFS_DEFECT)</para>
    /// </summary>
    public string LotId { get; set; } = string.Empty;
}

/// <summary>
/// Error codes returned by <see cref="IDfsService.UploadHexFilesAsync"/>.
/// <para>Maps to the integer return values from Delphi TDfsFtp.DfsHexFilesUpload.</para>
/// </summary>
public enum DfsUploadResult
{
    /// <summary>Upload succeeded (Delphi return 0).</summary>
    Success = 0,

    /// <summary>Panel ID is empty (Delphi return 1).</summary>
    EmptyPanelId = 1,

    /// <summary>Local HEX file does not exist (Delphi return 2).</summary>
    HexFileNotFound = 2,

    /// <summary>Cannot connect to DFS FTP server (Delphi return 3).</summary>
    ConnectionFailed = 3,

    /// <summary>HEX_INDEX upload failed (Delphi return 4).</summary>
    HexIndexUploadFailed = 4,

    /// <summary>HEX file upload failed (Delphi return 5).</summary>
    HexUploadFailed = 5,
}

/// <summary>
/// Service contract for DFS (Data File Server) file transfer operations via FTP.
/// <para>Original Delphi: TDfsFtp class (DfsFtp.pas, 976 lines)</para>
/// <para>
/// The Delphi implementation maintained per-channel FTP connections
/// (<c>DfsFtpCh[CH1..MAX_CH]</c>) plus a shared <c>DfsFtpCommon</c> for
/// combi-code downloads. This C# interface preserves that channel-based
/// design, with the channel index passed to each method.
/// </para>
/// </summary>
public interface IDfsService : IDisposable
{
    // =========================================================================
    // Connection State
    // =========================================================================

    /// <summary>
    /// Whether the FTP connection for the specified channel is currently active.
    /// <para>Delphi: DfsFtpCh[channel].IsConnected</para>
    /// </summary>
    bool IsConnected(int channel);

    /// <summary>
    /// Whether any FTP connection has successfully connected.
    /// <para>Delphi: DfsFtpConnOK global flag</para>
    /// </summary>
    bool AnyConnectionOk { get; }

    /// <summary>
    /// Per-channel DFS return info (populated by download/upload operations).
    /// <para>Delphi: DfsFtpCh[channel].m_DfsRetInfo</para>
    /// </summary>
    DfsReturnInfo GetReturnInfo(int channel);

    // =========================================================================
    // Connection Management
    // =========================================================================

    /// <summary>
    /// Connects the specified channel's FTP client to the DFS server.
    /// <para>Delphi: TDfsFtp.Connect</para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    Task ConnectAsync(int channel, CancellationToken cancellationToken = default);

    /// <summary>
    /// Disconnects the specified channel's FTP client.
    /// <para>Delphi: TDfsFtp.Disconnect</para>
    /// </summary>
    /// <param name="channel">Channel index (0-based).</param>
    Task DisconnectAsync(int channel);

    // =========================================================================
    // Basic FTP Operations
    // =========================================================================

    /// <summary>
    /// Changes the working directory on the FTP server.
    /// <para>Delphi: TDfsFtp.ChangeDir</para>
    /// </summary>
    Task ChangeDirAsync(int channel, string path, CancellationToken cancellationToken = default);

    /// <summary>
    /// Moves up one directory level on the FTP server.
    /// <para>Delphi: TDfsFtp.ChangeDirUp</para>
    /// </summary>
    Task ChangeDirUpAsync(int channel, CancellationToken cancellationToken = default);

    /// <summary>
    /// Creates a directory on the FTP server and changes into it.
    /// If the directory already exists, only changes into it.
    /// <para>Delphi: TDfsFtp.MakeAndChangeDir</para>
    /// </summary>
    Task MakeAndChangeDirAsync(int channel, string directory, CancellationToken cancellationToken = default);

    /// <summary>
    /// Downloads a file from the FTP server.
    /// <para>Delphi: TDfsFtp.Get(sSource, sDest)</para>
    /// </summary>
    /// <param name="channel">Channel index.</param>
    /// <param name="remoteFileName">Remote file name to download.</param>
    /// <param name="localFilePath">Local destination file path.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    Task DownloadFileAsync(int channel, string remoteFileName, string localFilePath,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Uploads a file to the FTP server.
    /// <para>Delphi: TDfsFtp.Put(sSource, sDest)</para>
    /// </summary>
    /// <param name="channel">Channel index.</param>
    /// <param name="localFilePath">Local source file path.</param>
    /// <param name="remoteFileName">Remote destination file name.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    Task UploadFileAsync(int channel, string localFilePath, string remoteFileName,
        CancellationToken cancellationToken = default);

    // =========================================================================
    // DFS Hash Path Utilities
    // =========================================================================

    /// <summary>
    /// Computes the DFS hash-based directory path for a panel ID.
    /// Uses the prime-seed hash algorithm (seed = 7919) to distribute
    /// panel files across a two-layer directory structure.
    /// <para>Delphi: TDfsFtp.GetDfsHashPath(sPanelId)</para>
    /// </summary>
    /// <param name="panelId">Panel identifier string.</param>
    /// <returns>
    /// Hash path in the form "00000000\00000000" for 2-layer routing,
    /// or "00000000" for 1-layer routing.
    /// </returns>
    string GetDfsHashPath(string panelId);

    // =========================================================================
    // DFS HEX Operations
    // =========================================================================

    /// <summary>
    /// Downloads HEX_INDEX and HEX files for the specified panel ID.
    /// The downloaded HEX file path is stored in <see cref="GetReturnInfo"/>.
    /// <para>Delphi: TDfsFtp.DfsHexFilesDownload(sPid)</para>
    /// </summary>
    /// <param name="channel">Channel index.</param>
    /// <param name="panelId">Panel ID to look up on the DFS server.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>True if both HEX_INDEX and HEX files were downloaded successfully.</returns>
    Task<bool> DownloadHexFilesAsync(int channel, string panelId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Uploads HEX_INDEX and HEX files for the specified panel ID.
    /// Creates the DFS directory structure, updates the index file,
    /// uploads both files, then cleans up local copies.
    /// <para>Delphi: TDfsFtp.DfsHexFilesUpload(sPid, sStartTime, sBinFullName)</para>
    /// </summary>
    /// <param name="channel">Channel index.</param>
    /// <param name="panelId">Panel ID.</param>
    /// <param name="startTime">Inspection start time (used for date-based directory paths).</param>
    /// <param name="binFullName">Full path to the local binary file to upload.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Upload result code (0 = success).</returns>
    Task<DfsUploadResult> UploadHexFilesAsync(int channel, string panelId, DateTime startTime,
        string binFullName, CancellationToken cancellationToken = default);

    // =========================================================================
    // DFS COMBI Operations
    // =========================================================================

    /// <summary>
    /// Downloads COMBI code .ini files from the DFS server.
    /// Backs up existing combi files before downloading new ones.
    /// Uses the shared (common) FTP connection rather than a per-channel one.
    /// <para>Delphi: TDfsFtp.DownloadCombiFile</para>
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    Task DownloadCombiFilesAsync(CancellationToken cancellationToken = default);
}
