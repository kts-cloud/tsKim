// =============================================================================
// DfsService.cs
// Converted from Delphi: src_X3584\DfsFtp.pas (976 lines)
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Dfs
//
// Implementation of IDfsService using built-in .NET 8 FTP via raw TCP sockets
// (FtpWebRequest is obsolete; we use a minimal FTP client over TcpClient).
//
// Architecture mapping from Delphi:
//   DfsFtpCh[CH1..MAX_CH] -> _channelClients[0..maxCh]   (per-channel FTP)
//   DfsFtpCommon           -> _commonClient                (shared FTP for combi)
//   DfsFtpConnOK           -> AnyConnectionOk property
//   SendMainGuiDisplay     -> IMessageBus.Publish<DfsEventMessage>
//   Common.AddLog          -> ILogger
//   Common.Path.*          -> IPathManager
//   Common.DfsConfInfo     -> IConfigurationService.DfsConfInfo
//   Common.SystemInfo      -> IConfigurationService.SystemInfo
//   Common.CombiCodeData   -> IConfigurationService (accessed at runtime)
// =============================================================================

using System.Net.Sockets;
using System.Text;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Messaging.Messages;

namespace Dongaeltek.ITOLED.BusinessLogic.Dfs;

/// <summary>
/// DFS (Data File Server) file transfer service using FTP protocol.
/// <para>Original Delphi: TDfsFtp (DfsFtp.pas)</para>
/// <para>
/// Uses a minimal FTP client built on <see cref="TcpClient"/> and raw
/// FTP command/response protocol since FtpWebRequest is obsolete in .NET 8.
/// Each channel maintains its own FTP connection. A separate shared connection
/// is used for COMBI file downloads.
/// </para>
/// </summary>
public sealed class DfsService : IDfsService
{
    // =========================================================================
    // Constants
    // =========================================================================

    /// <summary>DFS hash prime seed (Delphi: prSeed := 7919).</summary>
    private const int HashPrimeSeed = 7919;

    /// <summary>FTP default port.</summary>
    private const int FtpPort = 21;

    /// <summary>FTP read timeout in milliseconds.</summary>
    private const int FtpReadTimeoutMs = 5000;

    /// <summary>Delay after directory operations (ms). Delphi: Common.Delay(50).</summary>
    private const int DirectoryOperationDelayMs = 50;

    /// <summary>Delay after connect (ms). Delphi: Common.Delay(1000).</summary>
    private const int PostConnectDelayMs = 1000;

    // =========================================================================
    // Dependencies
    // =========================================================================

    private readonly IConfigurationService _config;
    private readonly IPathManager _pathManager;
    private readonly ILogger _logger;
    private readonly IMessageBus _messageBus;

    // =========================================================================
    // Per-channel FTP state
    // =========================================================================

    private readonly int _maxChannels;
    private readonly FtpClientState[] _channelClients;
    private readonly FtpClientState _commonClient;
    private readonly DfsReturnInfo[] _returnInfos;
    private readonly object _lock = new();
    private bool _anyConnectionOk;
    private bool _disposed;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates the DFS service and initializes per-channel FTP client state.
    /// <para>Delphi origin: TDfsFtp.Create + global DfsFtpCh/DfsFtpCommon initialization.</para>
    /// </summary>
    public DfsService(
        IConfigurationService config,
        IPathManager pathManager,
        ILogger logger,
        IMessageBus messageBus)
    {
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _pathManager = pathManager ?? throw new ArgumentNullException(nameof(pathManager));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));

        _maxChannels = ChannelConstants.MaxCh + 1;

        var dfsConf = _config.DfsConfInfo;

        // Initialize per-channel FTP clients (Delphi: DfsFtpCh[CH1..MAX_CH])
        _channelClients = new FtpClientState[_maxChannels];
        _returnInfos = new DfsReturnInfo[_maxChannels];
        for (int i = 0; i < _maxChannels; i++)
        {
            _channelClients[i] = new FtpClientState(
                dfsConf.DfsServerIP, FtpPort, dfsConf.DfsUserName, dfsConf.DfsPassword);
            _returnInfos[i] = new DfsReturnInfo();
        }

        // Initialize shared FTP client for COMBI downloads (Delphi: DfsFtpCommon)
        _commonClient = new FtpClientState(
            dfsConf.DfsServerIP, FtpPort, dfsConf.DfsUserName, dfsConf.DfsPassword);
    }

    // =========================================================================
    // IDfsService — Connection State
    // =========================================================================

    /// <inheritdoc />
    public bool IsConnected(int channel)
    {
        ValidateChannel(channel);
        return _channelClients[channel].IsConnected;
    }

    /// <inheritdoc />
    public bool AnyConnectionOk
    {
        get { lock (_lock) return _anyConnectionOk; }
    }

    /// <inheritdoc />
    public DfsReturnInfo GetReturnInfo(int channel)
    {
        ValidateChannel(channel);
        return _returnInfos[channel];
    }

    // =========================================================================
    // IDfsService — Connection Management
    // =========================================================================

    /// <inheritdoc />
    public async Task ConnectAsync(int channel, CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);
        var client = _channelClients[channel];

        try
        {
            if (client.IsConnected)
                await DisconnectInternalAsync(client);

            _logger.Info($"<DFS> FTP Connect to {client.Host} (CH{channel + 1})");
            await ConnectInternalAsync(client, cancellationToken);

            lock (_lock) _anyConnectionOk = true;

            PublishConnectionStatus(channel, isConnected: true);
        }
        catch (Exception ex)
        {
            _logger.Error($"<DFS> FTP Connect Error! CH{channel + 1} E.Message={ex.Message}");
            await DisconnectInternalAsync(client);

            lock (_lock) _anyConnectionOk = false;

            PublishConnectionStatus(channel, isConnected: false);
        }
    }

    /// <inheritdoc />
    public async Task DisconnectAsync(int channel)
    {
        ValidateChannel(channel);
        await DisconnectInternalAsync(_channelClients[channel]);
    }

    // =========================================================================
    // IDfsService — Basic FTP Operations
    // =========================================================================

    /// <inheritdoc />
    public async Task ChangeDirAsync(int channel, string path, CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);
        await SendCommandAsync(_channelClients[channel], $"CWD {path}", 250, cancellationToken);
    }

    /// <inheritdoc />
    public async Task ChangeDirUpAsync(int channel, CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);
        await SendCommandAsync(_channelClients[channel], "CDUP", 250, cancellationToken);
    }

    /// <inheritdoc />
    public async Task MakeAndChangeDirAsync(int channel, string directory, CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);
        var client = _channelClients[channel];

        try
        {
            _logger.Debug($"<DFS> DFS FOLDER DIRECTORY MAKE[{directory}]");
            await SendCommandAsync(client, $"MKD {directory}", 257, cancellationToken);
        }
        catch
        {
            // Directory may already exist — ignore MKD failure (Delphi behavior)
        }

        await Task.Delay(DirectoryOperationDelayMs, cancellationToken);

        _logger.Debug($"<DFS> DFS FOLDER DIRECTORY CHANGE[{directory}]");
        await SendCommandAsync(client, $"CWD {directory}", 250, cancellationToken);
        await Task.Delay(DirectoryOperationDelayMs, cancellationToken);
    }

    /// <inheritdoc />
    public async Task DownloadFileAsync(int channel, string remoteFileName, string localFilePath,
        CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);
        var client = _channelClients[channel];

        await SendCommandAsync(client, "TYPE I", 200, cancellationToken);
        var (dataHost, dataPort) = await EnterPassiveModeAsync(client, cancellationToken);

        using var dataClient = new TcpClient();
        await dataClient.ConnectAsync(dataHost, dataPort, cancellationToken);
        await using var dataStream = dataClient.GetStream();

        await SendCommandAsync(client, $"RETR {remoteFileName}", 150, cancellationToken);

        var dir = Path.GetDirectoryName(localFilePath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        await using (var fileStream = new FileStream(localFilePath, FileMode.Create, FileAccess.Write))
        {
            await dataStream.CopyToAsync(fileStream, cancellationToken);
        }

        await ReadResponseAsync(client, 226, cancellationToken);
    }

    /// <inheritdoc />
    public async Task UploadFileAsync(int channel, string localFilePath, string remoteFileName,
        CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);
        var client = _channelClients[channel];

        try
        {
            await SendCommandAsync(client, "TYPE I", 200, cancellationToken);
            var (dataHost, dataPort) = await EnterPassiveModeAsync(client, cancellationToken);

            using var dataClient = new TcpClient();
            await dataClient.ConnectAsync(dataHost, dataPort, cancellationToken);
            await using var dataStream = dataClient.GetStream();

            await SendCommandAsync(client, $"STOR {remoteFileName}", 150, cancellationToken);

            await using (var fileStream = new FileStream(localFilePath, FileMode.Open, FileAccess.Read))
            {
                await fileStream.CopyToAsync(dataStream, cancellationToken);
            }

            // Close data connection to signal transfer complete
            dataClient.Close();

            await ReadResponseAsync(client, 226, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.Error($"<FILE_SVR> FTP PUT Error! E.Message={ex.Message}");
            throw;
        }
    }

    // =========================================================================
    // IDfsService — DFS Hash Path
    // =========================================================================

    /// <inheritdoc />
    public string GetDfsHashPath(string panelId)
    {
        // Delphi: TDfsFtp.GetDfsHashPath
        try
        {
            int prSeed = HashPrimeSeed;
            int layerCount = 1;
            int layerSize;

            if (prSeed <= 157)
            {
                layerSize = prSeed;
            }
            else
            {
                layerCount = 2;
                layerSize = (int)(prSeed / Math.Truncate(Math.Pow(prSeed, 0.5)));
            }

            int hashValue = ComputeHashValue(panelId, prSeed);

            if (layerCount == 1)
            {
                double d = hashValue % layerSize;
                return d.ToString("00000000");
            }
            else
            {
                double d0 = (hashValue / (double)layerSize) - 0.49999;
                double d1 = hashValue % layerSize;
                return ((int)d0).ToString("00000000") + @"\" + ((int)d1).ToString("00000000");
            }
        }
        catch
        {
            return string.Empty;
        }
    }

    // =========================================================================
    // IDfsService — DFS HEX Download
    // =========================================================================

    /// <inheritdoc />
    public async Task<bool> DownloadHexFilesAsync(int channel, string panelId,
        CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);

        // ---- Check PanelId
        if (string.IsNullOrEmpty(panelId))
        {
            _logger.Warn("<DFS> HEX_INDEX File Download Fail (Panel ID is NOT exist) !");
            return false;
        }

        // ---- Compute paths
        string dfsHashPath = GetDfsHashPath(panelId);
        string hexIdxServerPath = @"DEFECT\HEX_INDEX\" + dfsHashPath;
        string hexIdxFileName = panelId.ToUpperInvariant() + ".IDX";
        string hexIdxLocalFullName = Path.Combine(_pathManager.DfsHexIndexDir, hexIdxFileName);

        if (File.Exists(hexIdxLocalFullName))
            File.Delete(hexIdxLocalFullName);

        // ---- Connect DFS FTP server if not connected
        var client = _channelClients[channel];
        if (!client.IsConnected)
        {
            await ConnectAsync(channel, cancellationToken);
            await Task.Delay(PostConnectDelayMs, cancellationToken);
        }

        if (!client.IsConnected)
        {
            _logger.Warn("<DFS> HEX_INDEX and HEX File Download Fail (DFS Server Not Connected)");
            return false;
        }

        try
        {
            // ---- Download HEX_INDEX File
            try
            {
                _logger.Info("<DFS> FTP Directory Change [/DEFECT/HEX_INDEX]");
                await ChangeDirAsync(channel, "DEFECT", cancellationToken);
                await ChangeDirAsync(channel, "HEX_INDEX", cancellationToken);

                // Navigate hash path directories
                string[] hashParts = dfsHashPath.Split('\\', StringSplitOptions.RemoveEmptyEntries);
                foreach (string part in hashParts)
                {
                    await ChangeDirAsync(channel, part, cancellationToken);
                }

                _logger.Info($"<DFS> HEX_INDEX File Downloading ({hexIdxServerPath}\\{hexIdxFileName})");
                await DownloadFileAsync(channel, hexIdxFileName, hexIdxLocalFullName, cancellationToken);
            }
            catch (Exception ex)
            {
                await DisconnectInternalAsync(client);
                _logger.Error($"<DFS> HEX_INDEX File Download Fail (FTP Error: {ex.Message})");
                return false;
            }

            _logger.Info("<DFS> HEX_INDEX File Download OK");

            // ---- Parse HEX_INDEX and Get HEX File Location
            string hexServerFullName = GetFullNameFromIdxFile(hexIdxLocalFullName);
            _logger.Info($"<DFS> HexFileName : {hexServerFullName}");

            if (string.IsNullOrEmpty(hexServerFullName))
            {
                await DisconnectInternalAsync(client);
                _logger.Warn("<DFS> HEX_INDEX File is Empty");
                return false;
            }

            // ---- Download HEX File
            try
            {
                int lastSep = hexServerFullName.LastIndexOf('\\');
                string hexServerPath = hexServerFullName[..lastSep];
                string hexFileName = hexServerFullName[(lastSep + 1)..];

                // Build local HEX path with date/recipe/EQP subdirectories
                var now = DateTime.Now;
                string hexLocalDir = _pathManager.DfsHexDir;
                hexLocalDir = EnsureSubDir(hexLocalDir, now.ToString("MM"));
                hexLocalDir = EnsureSubDir(hexLocalDir, now.ToString("dd"));
                hexLocalDir = EnsureSubDir(hexLocalDir, _config.DfsConfInfo.ProcessName);
                hexLocalDir = EnsureSubDir(hexLocalDir, _config.SystemInfo.EQPId);

                string hexLocalFullName = Path.Combine(hexLocalDir, hexFileName);
                if (File.Exists(hexLocalFullName))
                    File.Delete(hexLocalFullName);

                _returnInfos[channel].HexFileName = hexLocalFullName;

                // Navigate to HEX path on server
                string[] hexPathParts = hexServerPath.Split('\\', StringSplitOptions.RemoveEmptyEntries);
                foreach (string part in hexPathParts)
                {
                    await ChangeDirAsync(channel, part, cancellationToken);
                }

                _logger.Info($"<DFS> HEX File Downloading ({hexServerFullName})");
                await DownloadFileAsync(channel, hexFileName, hexLocalFullName, cancellationToken);
                await DisconnectInternalAsync(client);
            }
            catch (Exception ex)
            {
                await DisconnectInternalAsync(client);
                _logger.Error($"<DFS> HEX File Download Fail (FTP Error: {ex.Message})");
                return false;
            }

            _logger.Info("<DFS> HEX File Download OK");
            return true;
        }
        finally
        {
            if (client.IsConnected)
            {
                await DisconnectInternalAsync(client);
            }
        }
    }

    // =========================================================================
    // IDfsService — DFS HEX Upload
    // =========================================================================

    /// <inheritdoc />
    public async Task<DfsUploadResult> UploadHexFilesAsync(int channel, string panelId,
        DateTime startTime, string binFullName, CancellationToken cancellationToken = default)
    {
        ValidateChannel(channel);

        // ---- Check PanelId
        if (string.IsNullOrEmpty(panelId))
        {
            _logger.Warn("<DFS> HEX_INDEX File Upload Fail (Panel ID is NOT exist) !");
            return DfsUploadResult.EmptyPanelId;
        }

        var dfsConf = _config.DfsConfInfo;
        var sysInfo = _config.SystemInfo;
        string rcpName = GetCombiRcpName();
        string processNo = GetCombiProcessNo();

        // ---- Build HEX_INDEX file paths
        string hexIdxFileName = panelId.ToUpperInvariant() + ".IDX";
        _pathManager.EnsureDirectory(_pathManager.DfsHexIndexDir);
        string hexIdxLocalFullName = Path.Combine(_pathManager.DfsHexIndexDir, hexIdxFileName);
        if (File.Exists(hexIdxLocalFullName))
            File.Delete(hexIdxLocalFullName);

        string dfsHashPath = GetDfsHashPath(panelId);
        string hexIdxServerPath = @"DEFECT\HEX_INDEX\" + dfsHashPath;

        // ---- Build HEX file name and paths
        string hexFileName = panelId + "_" + processNo + "_"
                             + startTime.ToString("yyyyMMdd_HHmmss");
        hexFileName += dfsConf.DfsHexCompress ? ".ZIP" : ("." + sysInfo.EQPId);

        // Build local HEX full path with date/recipe/EQP subdirectories
        string hexLocalDir = _pathManager.DfsHexDir;
        _pathManager.EnsureDirectory(hexLocalDir);
        hexLocalDir = EnsureSubDir(hexLocalDir, startTime.ToString("MM"));
        hexLocalDir = EnsureSubDir(hexLocalDir, startTime.ToString("dd"));
        hexLocalDir = EnsureSubDir(hexLocalDir, rcpName);
        hexLocalDir = EnsureSubDir(hexLocalDir, sysInfo.EQPId);

        string hexLocalFullName = Path.Combine(hexLocalDir, hexFileName);

        // Copy source bin file to local HEX path
        if (File.Exists(binFullName))
        {
            File.Copy(binFullName, hexLocalFullName, overwrite: true);
        }

        if (!File.Exists(hexLocalFullName))
        {
            _logger.Warn("<DFS> HEX File Upload Fail (HEX file is NOT exist) !");
            return DfsUploadResult.HexFileNotFound;
        }

        // Build HEX server full path
        string hexServerFullName = @"DEFECT\HEX\"
                                   + startTime.ToString("MM") + @"\"
                                   + startTime.ToString("dd") + @"\"
                                   + rcpName + @"\" + sysInfo.EQPId + @"\"
                                   + hexFileName;

        // ---- Connect DFS FTP server
        var client = _channelClients[channel];
        if (!client.IsConnected)
        {
            await ConnectAsync(channel, cancellationToken);
            await Task.Delay(PostConnectDelayMs, cancellationToken);
        }

        if (!client.IsConnected)
        {
            _logger.Warn("<DFS> HEX_INDEX and HEX File Upload Fail (DFS Server Not Connected)");
            return DfsUploadResult.ConnectionFailed;
        }

        // ---- Update HexIndex file locally (append server full name)
        UpdateIdxFile(hexIdxLocalFullName, hexServerFullName);

        // ---- Upload HexIndex File
        try
        {
            await ChangeDirAsync(channel, "DEFECT", cancellationToken);
            await ChangeDirAsync(channel, "HEX_INDEX", cancellationToken);

            // Navigate/create hash path directories (2-layer: 8-digit/8-digit)
            string tempDir1 = dfsHashPath.Length >= 8 ? dfsHashPath[..8] : dfsHashPath;
            await MakeAndChangeDirAsync(channel, tempDir1, cancellationToken);

            if (dfsHashPath.Length > 9)
            {
                string tempDir2 = dfsHashPath.Substring(9, Math.Min(8, dfsHashPath.Length - 9));
                await MakeAndChangeDirAsync(channel, tempDir2, cancellationToken);
            }

            _logger.Info($"<DFS> HEX_INDEX File Uploading ({hexIdxServerPath}\\{hexIdxFileName})");
            await UploadFileAsync(channel, hexIdxLocalFullName, hexIdxFileName, cancellationToken);

            // Navigate back up (Delphi: ChangeDirUp x4)
            for (int i = 0; i < 4; i++)
            {
                await ChangeDirUpAsync(channel, cancellationToken);
            }
        }
        catch (Exception ex)
        {
            await DisconnectInternalAsync(client);
            _logger.Error($"<DFS> HEX_INDEX File Upload Fail (FTP Error: {ex.Message})");
            return DfsUploadResult.HexIndexUploadFailed;
        }

        _logger.Info("<DFS> HEX_INDEX File Upload OK");

        // ---- Upload HEX File
        try
        {
            await ChangeDirAsync(channel, "DEFECT", cancellationToken);
            await ChangeDirAsync(channel, "HEX", cancellationToken);

            await MakeAndChangeDirAsync(channel, startTime.ToString("MM"), cancellationToken);
            await MakeAndChangeDirAsync(channel, startTime.ToString("dd"), cancellationToken);
            await MakeAndChangeDirAsync(channel, rcpName, cancellationToken);
            await MakeAndChangeDirAsync(channel, sysInfo.EQPId, cancellationToken);

            _logger.Info($"<DFS> HEX File Uploading ({hexServerFullName})");
            await UploadFileAsync(channel, hexLocalFullName, hexFileName, cancellationToken);

            await DisconnectInternalAsync(client);
        }
        catch (Exception ex)
        {
            await DisconnectInternalAsync(client);
            _logger.Error($"<DFS> HEX File Upload Fail (FTP Error: {ex.Message})");
            return DfsUploadResult.HexUploadFailed;
        }

        _logger.Info("<DFS> HEX File Upload OK");

        // ---- Cleanup: disconnect and delete local temp files
        if (client.IsConnected)
            await DisconnectInternalAsync(client);

        TryDeleteFile(hexIdxLocalFullName);
        TryDeleteFile(hexLocalFullName);

        return DfsUploadResult.Success;
    }

    // =========================================================================
    // IDfsService — COMBI Download
    // =========================================================================

    /// <inheritdoc />
    public async Task DownloadCombiFilesAsync(CancellationToken cancellationToken = default)
    {
        // Uses the shared common FTP connection (Delphi: DfsFtpCommon)
        if (!_commonClient.IsConnected)
        {
            await ConnectInternalAsync(_commonClient, cancellationToken);
        }

        try
        {
            var dfsConf = _config.DfsConfInfo;

            // Navigate to combi download path on server
            string[] pathParts = dfsConf.CombiDownPath.Split(
                new[] { '\\', '/' }, StringSplitOptions.RemoveEmptyEntries);

            foreach (string part in pathParts)
            {
                await SendCommandAsync(_commonClient, $"CWD {part}", 250, cancellationToken);
            }

            // List remote files
            var remoteFiles = await ListFilesAsync(_commonClient, cancellationToken);

            // Backup existing local .ini files
            string combiDir = _pathManager.CombiCodeDir;
            string backupDir = _pathManager.CombiBackupDir;
            _pathManager.EnsureDirectory(combiDir);
            _pathManager.EnsureDirectory(backupDir);

            foreach (string localFile in Directory.GetFiles(combiDir, "*.ini"))
            {
                string destFile = Path.Combine(backupDir, Path.GetFileName(localFile));
                try
                {
                    if (File.Exists(destFile))
                        File.Delete(destFile);
                    File.Move(localFile, destFile);
                }
                catch
                {
                    TryDeleteFile(localFile);
                }
            }

            // Download .ini files from server
            foreach (string remoteFile in remoteFiles)
            {
                if (remoteFile.EndsWith(".ini", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.Info($"<DFS> DOWNLOAD COMBI FILE NAME : {remoteFile}");
                    string localPath = Path.Combine(combiDir, remoteFile);
                    await DownloadFileInternalAsync(_commonClient, remoteFile, localPath, cancellationToken);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.Error($"<DFS> FTP Transmission Error! E.Message={ex.Message}");
            _logger.Error("<DFS> COMBICODE DOWNLOAD FAIL.");
            await DisconnectInternalAsync(_commonClient);
            await Task.Delay(DirectoryOperationDelayMs, cancellationToken);
        }
        finally
        {
            await DisconnectInternalAsync(_commonClient);
            await Task.Delay(DirectoryOperationDelayMs, cancellationToken);
        }
    }

    // =========================================================================
    // Hash Algorithm (Delphi: GetDfsHashValue, TranHashValue2NumberInLayer)
    // =========================================================================

    /// <summary>
    /// Computes a hash value for the panel ID key string.
    /// <para>Delphi: TDfsFtp.GetDfsHashValue(pKeyStr)</para>
    /// </summary>
    private static int ComputeHashValue(string keyStr, int primeSeed)
    {
        if (string.IsNullOrEmpty(keyStr))
            return 0;

        int tmpVal = 0;
        for (int i = 0; i < keyStr.Length; i++)
        {
            long lTemp = tmpVal;
            lTemp = lTemp * 0xFF;
            lTemp = lTemp + (0xFF & keyStr[i]);
            tmpVal = (int)(lTemp % primeSeed);
        }

        return tmpVal;
    }

    // =========================================================================
    // Index File Operations (Delphi: GetDfsFullNameFromIdxFile, UpdateDfsIdxFile)
    // =========================================================================

    /// <summary>
    /// Reads the last non-empty line from an index file.
    /// <para>Delphi: TDfsFtp.GetDfsFullNameFromIdxFile(sIdxFile)</para>
    /// </summary>
    private static string GetFullNameFromIdxFile(string idxFilePath)
    {
        if (!File.Exists(idxFilePath))
            return string.Empty;

        string fullName = string.Empty;
        foreach (string line in File.ReadAllLines(idxFilePath))
        {
            if (!string.IsNullOrEmpty(line))
                fullName = line;
        }

        return fullName;
    }

    /// <summary>
    /// Appends a server full-name entry to an index file.
    /// Creates the file if it does not exist.
    /// <para>Delphi: TDfsFtp.UpdateDfsIdxFile(sIdxFileName, sAppendFullName)</para>
    /// </summary>
    private static void UpdateIdxFile(string idxFilePath, string appendFullName)
    {
        try
        {
            var dir = Path.GetDirectoryName(idxFilePath);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            File.AppendAllLines(idxFilePath, new[] { appendFullName });
            Thread.Sleep(10); // Delphi: Sleep(10)
        }
        catch
        {
            // Delphi: empty except block
        }
    }

    // =========================================================================
    // GUI Notification (Delphi: SendMainGuiDisplay → MessageBus)
    // =========================================================================

    /// <summary>
    /// Publishes a DFS connection status message via the message bus.
    /// <para>Delphi: TDfsFtp.SendMainGuiDisplay(MSG_MODE_DISPLAY_CONNECTION, ch, param)</para>
    /// </summary>
    private void PublishConnectionStatus(int channel, bool isConnected)
    {
        _messageBus.Publish(new DfsEventMessage
        {
            Channel = channel,
            Mode = MsgMode.DisplayConnection,
            Param = isConnected ? 1 : 0  // 0:Disconnected, 1:Connected
        });
    }

    // =========================================================================
    // FTP Protocol Implementation (minimal client over TcpClient)
    // =========================================================================

    /// <summary>
    /// Establishes an FTP connection: TCP connect, read welcome, USER, PASS, set binary, passive.
    /// <para>Delphi: TIdFTP.Create + Connect with Passive=True, TransferType=ftBinary</para>
    /// </summary>
    private async Task ConnectInternalAsync(FtpClientState client, CancellationToken ct)
    {
        await DisconnectInternalAsync(client);

        client.TcpClient = new TcpClient();
        client.TcpClient.ReceiveTimeout = FtpReadTimeoutMs;
        client.TcpClient.SendTimeout = FtpReadTimeoutMs;

        await client.TcpClient.ConnectAsync(client.Host, client.Port, ct);
        client.Stream = client.TcpClient.GetStream();
        client.Reader = new StreamReader(client.Stream, Encoding.ASCII);
        client.Writer = new StreamWriter(client.Stream, Encoding.ASCII) { AutoFlush = true };

        // Read welcome banner (220)
        await ReadResponseAsync(client, 220, ct);

        // Login
        await SendCommandAsync(client, $"USER {client.Username}", 331, ct);
        await SendCommandAsync(client, $"PASS {client.Password}", 230, ct);

        // Set binary mode
        await SendCommandAsync(client, "TYPE I", 200, ct);

        client.IsConnected = true;
    }

    /// <summary>
    /// Safely disconnects and disposes the FTP client resources.
    /// </summary>
    private async Task DisconnectInternalAsync(FtpClientState client)
    {
        if (!client.IsConnected && client.TcpClient == null)
            return;

        try
        {
            if (client.TcpClient?.Connected == true && client.Writer != null)
            {
                await client.Writer.WriteLineAsync("QUIT");
                await client.Writer.FlushAsync();
            }
        }
        catch
        {
            // Ignore errors during disconnect
        }
        finally
        {
            client.Reader?.Dispose();
            client.Writer?.Dispose();
            client.Stream?.Dispose();
            client.TcpClient?.Dispose();
            client.TcpClient = null;
            client.Stream = null;
            client.Reader = null;
            client.Writer = null;
            client.IsConnected = false;
        }
    }

    /// <summary>
    /// Sends an FTP command and validates the response code.
    /// </summary>
    private async Task<string> SendCommandAsync(FtpClientState client, string command,
        int expectedCode, CancellationToken ct)
    {
        if (client.Writer == null || client.Reader == null)
            throw new InvalidOperationException("FTP client is not connected.");

        await client.Writer.WriteLineAsync(command);
        await client.Writer.FlushAsync();
        return await ReadResponseAsync(client, expectedCode, ct);
    }

    /// <summary>
    /// Reads the FTP response and validates the status code.
    /// Handles multi-line responses (code-space vs code-hyphen).
    /// </summary>
    private static async Task<string> ReadResponseAsync(FtpClientState client,
        int expectedCode, CancellationToken ct)
    {
        if (client.Reader == null)
            throw new InvalidOperationException("FTP client is not connected.");

        var sb = new StringBuilder();
        string? line;
        bool complete = false;

        while (!complete)
        {
            ct.ThrowIfCancellationRequested();
            line = await client.Reader.ReadLineAsync(ct);

            if (line == null)
                throw new IOException("FTP connection closed unexpectedly.");

            sb.AppendLine(line);

            // FTP response: "NNN text" for final line, "NNN-text" for continuation
            if (line.Length >= 3
                && int.TryParse(line[..3], out int code))
            {
                // Final line has space after code, or is exactly 3 chars
                if (line.Length == 3 || line[3] == ' ')
                {
                    complete = true;
                    if (code != expectedCode && expectedCode > 0)
                    {
                        // Accept codes in the same class (e.g., 227 for PASV)
                        // or the exact code. Also accept 125/150 for transfer start.
                        if (code / 100 != expectedCode / 100
                            && !(expectedCode == 150 && code == 125))
                        {
                            throw new IOException(
                                $"FTP error: expected {expectedCode}, got {code}. Response: {line}");
                        }
                    }
                }
            }
        }

        return sb.ToString();
    }

    /// <summary>
    /// Enters FTP passive mode and returns the data connection endpoint.
    /// Parses the PASV response "227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)".
    /// </summary>
    private async Task<(string Host, int Port)> EnterPassiveModeAsync(
        FtpClientState client, CancellationToken ct)
    {
        string response = await SendCommandAsync(client, "PASV", 227, ct);

        // Parse (h1,h2,h3,h4,p1,p2)
        int start = response.IndexOf('(');
        int end = response.IndexOf(')');

        if (start < 0 || end < 0)
            throw new IOException($"Cannot parse PASV response: {response}");

        string[] parts = response[(start + 1)..end].Split(',');
        if (parts.Length != 6)
            throw new IOException($"Invalid PASV response format: {response}");

        string host = $"{parts[0]}.{parts[1]}.{parts[2]}.{parts[3]}";
        int port = int.Parse(parts[4]) * 256 + int.Parse(parts[5]);

        return (host, port);
    }

    /// <summary>
    /// Downloads a file using the shared (common) FTP client.
    /// </summary>
    private async Task DownloadFileInternalAsync(FtpClientState client,
        string remoteFileName, string localFilePath, CancellationToken ct)
    {
        await SendCommandAsync(client, "TYPE I", 200, ct);
        var (dataHost, dataPort) = await EnterPassiveModeAsync(client, ct);

        using var dataClient = new TcpClient();
        await dataClient.ConnectAsync(dataHost, dataPort, ct);
        await using var dataStream = dataClient.GetStream();

        await SendCommandAsync(client, $"RETR {remoteFileName}", 150, ct);

        var dir = Path.GetDirectoryName(localFilePath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        await using (var fileStream = new FileStream(localFilePath, FileMode.Create, FileAccess.Write))
        {
            await dataStream.CopyToAsync(fileStream, ct);
        }

        await ReadResponseAsync(client, 226, ct);
    }

    /// <summary>
    /// Lists files in the current FTP directory using the shared client.
    /// Returns a list of file/directory names (NLST).
    /// </summary>
    private async Task<List<string>> ListFilesAsync(FtpClientState client, CancellationToken ct)
    {
        var (dataHost, dataPort) = await EnterPassiveModeAsync(client, ct);

        using var dataClient = new TcpClient();
        await dataClient.ConnectAsync(dataHost, dataPort, ct);
        await using var dataStream = dataClient.GetStream();

        await SendCommandAsync(client, "NLST", 150, ct);

        using var reader = new StreamReader(dataStream, Encoding.ASCII);
        string content = await reader.ReadToEndAsync(ct);

        await ReadResponseAsync(client, 226, ct);

        var files = new List<string>();
        foreach (string line in content.Split('\n', StringSplitOptions.RemoveEmptyEntries))
        {
            string trimmed = line.Trim('\r', ' ');
            if (!string.IsNullOrEmpty(trimmed))
                files.Add(trimmed);
        }

        return files;
    }

    // =========================================================================
    // Helper Methods
    // =========================================================================

    /// <summary>
    /// Validates the channel index is within the valid range.
    /// </summary>
    private void ValidateChannel(int channel)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        if (channel < 0 || channel >= _maxChannels)
            throw new ArgumentOutOfRangeException(nameof(channel),
                $"Channel must be between 0 and {_maxChannels - 1}.");
    }

    /// <summary>
    /// Ensures a subdirectory exists under the given parent and returns the combined path.
    /// <para>Delphi: Common.CheckDir(sHexLocalFullName)</para>
    /// </summary>
    private string EnsureSubDir(string parentDir, string subDir)
    {
        string path = Path.Combine(parentDir, subDir);
        _pathManager.EnsureDirectory(path);
        return path;
    }

    /// <summary>
    /// Safely deletes a file, swallowing any exceptions.
    /// </summary>
    private static void TryDeleteFile(string filePath)
    {
        try
        {
            if (File.Exists(filePath))
                File.Delete(filePath);
        }
        catch
        {
            // Swallow — best effort cleanup
        }
    }

    /// <summary>
    /// Gets the recipe name from the configuration.
    /// <para>Delphi: Common.CombiCodeData.sRcpName</para>
    /// </summary>
    private string GetCombiRcpName()
    {
        // CombiCodeData is read at runtime from the loaded model configuration.
        // The IConfigurationService provides access to DfsConfInfo which holds ProcessName.
        // For RcpName, we fall back to ProcessName when CombiCodeData is not directly available.
        return _config.DfsConfInfo.ProcessName;
    }

    /// <summary>
    /// Gets the process number from the configuration.
    /// <para>Delphi: Common.CombiCodeData.sProcessNo</para>
    /// </summary>
    private string GetCombiProcessNo()
    {
        return _config.DfsConfInfo.ProcessName;
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        // Disconnect and dispose all channel clients
        for (int i = 0; i < _channelClients.Length; i++)
        {
            try
            {
                DisconnectInternalAsync(_channelClients[i]).GetAwaiter().GetResult();
            }
            catch
            {
                // Best effort during disposal
            }
        }

        // Disconnect shared client
        try
        {
            DisconnectInternalAsync(_commonClient).GetAwaiter().GetResult();
        }
        catch
        {
            // Best effort during disposal
        }
    }

    // =========================================================================
    // Inner Types
    // =========================================================================

    /// <summary>
    /// Holds per-connection FTP state (TCP client, streams, credentials).
    /// <para>Replaces Delphi's TIdFTP instance per channel.</para>
    /// </summary>
    private sealed class FtpClientState
    {
        public string Host { get; }
        public int Port { get; }
        public string Username { get; }
        public string Password { get; }

        public TcpClient? TcpClient { get; set; }
        public NetworkStream? Stream { get; set; }
        public StreamReader? Reader { get; set; }
        public StreamWriter? Writer { get; set; }
        public bool IsConnected { get; set; }

        public FtpClientState(string host, int port, string username, string password)
        {
            Host = host;
            Port = port;
            Username = username;
            Password = password;
        }
    }
}
