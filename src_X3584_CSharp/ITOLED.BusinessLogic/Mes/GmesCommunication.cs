// =============================================================================
// GmesCommunication.cs
// Converted from Delphi: src_X3584\GMesCom.pas (TGmes class, 3424 lines)
// Namespace: Dongaeltek.ITOLED.BusinessLogic.Mes
//
// Handles GMES (Manufacturing Execution System) protocol communication:
//   MES: EAYT, UCHK, EDTI, PCHK, INS_PCHK, EICR, EIJR, RPR_EIJR, APDR, LPIR,
//        EQCC, FLDR, REPN, ZSET, SGEN
//   EAS: EAS_APDR
//   R2R: EAYT, EODS, EODS_R, EODA
//
// Uses DllMesCom (IMesCommunication / MesComInterop) for native TIBRv64 transport.
// =============================================================================

using System.Collections.Concurrent;
using System.Net;
using System.Text;
using Dongaeltek.ITOLED.Core.Definitions;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Messaging;
using Dongaeltek.ITOLED.Core.Models;
using Dongaeltek.ITOLED.Hardware.Mes;

namespace Dongaeltek.ITOLED.BusinessLogic.Mes;

#region Supporting types

/// <summary>
/// Key-value pair for MES message parsing.
/// <para>Delphi: TKeyValue = record</para>
/// </summary>
public record struct KeyValue(string Key, string Value);

/// <summary>
/// MES queue item representing a pending MES operation.
/// <para>Delphi: TQueItemValue = record</para>
/// </summary>
public class MesQueueItem
{
    /// <summary>Queue item processing state. Delphi: State</summary>
    public int State { get; set; }

    /// <summary>MES message kind (MES_PCHK, MES_EICR, etc.). Delphi: Kind</summary>
    public int Kind { get; set; }

    /// <summary>Timestamp when item was enqueued/started. Delphi: Tick</summary>
    public long Tick { get; set; }

    /// <summary>Timeout in milliseconds. Delphi: Timeout</summary>
    public long Timeout { get; set; }

    /// <summary>Channel/PG index. Delphi: Channel</summary>
    public int Channel { get; set; }

    /// <summary>Serial number. Delphi: SerialNo</summary>
    public string SerialNo { get; set; } = string.Empty;

    /// <summary>Carrier/JIG ID. Delphi: CarrierID</summary>
    public string CarrierId { get; set; } = string.Empty;

    /// <summary>MES code (RWK code). Delphi: MESCode</summary>
    public string MesCode { get; set; } = string.Empty;

    /// <summary>Error code. Delphi: ErrCode</summary>
    public string ErrCode { get; set; } = string.Empty;

    /// <summary>LPIR process code. Delphi: LpirProcessCode</summary>
    public string LpirProcessCode { get; set; } = string.Empty;

    /// <summary>APDR data payload. Delphi: ApdrData</summary>
    public string ApdrData { get; set; } = string.Empty;

    /// <summary>Tact time. Delphi: Tact</summary>
    public string Tact { get; set; } = string.Empty;

    /// <summary>Retry count. Delphi: RetryCnt</summary>
    public int RetryCnt { get; set; }
}

/// <summary>
/// MES data pack per channel, holding PCHK/EICR/APDR/LPIR results and state.
/// <para>Delphi: TGmesDataPack = record</para>
/// </summary>
public class GmesDataPack
{
    public bool Registry { get; set; }
    public bool DataSend { get; set; }
    public bool PchkResult { get; set; }
    public bool LpirResult { get; set; }
    public string LotNo { get; set; } = string.Empty;
    public string SerialNo { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string Pf { get; set; } = string.Empty;
    public string ErrCode { get; set; } = string.Empty;
    public string Rwk { get; set; } = string.Empty;
    public string Tact { get; set; } = string.Empty;
    public string DefectPat { get; set; } = string.Empty;
    public string GDDefectCode { get; set; } = string.Empty;
    public int Option { get; set; }
    public int EodaAck { get; set; }

    /// <summary>Pending MES message type. Delphi: MesPendingMsg</summary>
    public int MesPendingMsg { get; set; }

    /// <summary>Sent MES message type. Delphi: MesSentMsg</summary>
    public int MesSentMsg { get; set; }

    /// <summary>Send/receive wait tick counter. Delphi: MesSendRcvWaitTick</summary>
    public int MesSendRcvWaitTick { get; set; }

    public string ApdrData { get; set; } = string.Empty;
    public string CarrierId { get; set; } = string.Empty;
    public bool PchkSendNg { get; set; }
    public string PchkRtnCode { get; set; } = string.Empty;
    public string PchkRtnPid { get; set; } = string.Empty;
    public string PchkRtnZigId { get; set; } = string.Empty;
    public string PchkRtnSerialNo { get; set; } = string.Empty;
    public bool EicrSendNg { get; set; }
    public string EicrRtnCode { get; set; } = string.Empty;
    public bool LpirSendNg { get; set; }
    public string LpirRtnCode { get; set; } = string.Empty;
    public string ApdrRtnCode { get; set; } = string.Empty;
    public string ApdrRtnSerialNo { get; set; } = string.Empty;
    public string LpirProcessCode { get; set; } = string.Empty;
    public string LpirLatestInsp { get; set; } = string.Empty;
    public string ErrMsgCd { get; set; } = string.Empty;
    public string ErrMsgLoc { get; set; } = string.Empty;
    public string ErrMsgEng { get; set; } = string.Empty;
}

/// <summary>
/// MES host UI synchronization message published via IMessageBus.
/// Replaces Delphi's RSyncHost + WM_COPYDATA mechanism.
/// <para>Delphi: RSyncHost = record / ReturnDataToTestForm()</para>
/// </summary>
public sealed class GmesMesMessage : AppMessage
{
    /// <summary>Whether this is an error response.</summary>
    public bool IsError { get; init; }
}

#endregion

/// <summary>
/// GMES communication service implementation.
/// Manages MES/EAS/R2R protocol messaging via TIBRv64 native DLL (IMesCommunication).
/// <para>Delphi origin: TGmes class from GMesCom.pas (3424 lines)</para>
/// </summary>
public sealed class GmesCommunication : IGmesCommunication
{
    // =========================================================================
    // Dependencies
    // =========================================================================

    private readonly IConfigurationService _config;
    private readonly ILogger _logger;
    private readonly IMessageBus _messageBus;
    private readonly IMesCommunication _mesCom;

    // =========================================================================
    // Private fields (Delphi TGmes private section)
    // =========================================================================

    private string _mesErrMsgEn = string.Empty;
    private bool _pmMode = true; // Delphi: FPmMode := True
    private bool _eayt;
    private bool _r2rEayt;
    private bool _canUseHost;
    private bool _canUseEas;
    private bool _canUseR2R;
    private string _mesModel = string.Empty;
    private string _mesModelInfo = string.Empty;
    private string _mesRtnCd = string.Empty;
    private string _mesRtnPid = string.Empty;
    private string _mesErrCd = string.Empty;
    private string _mesErrMsgLc = string.Empty;
    private string _mesZigId = string.Empty;
    private string _mesLatestInsp = string.Empty;
    private string _mesCarrierId = string.Empty;
    private string _mesProsessCode = string.Empty;

    // R2R scenario fields
    private string _r2rMachine = string.Empty;
    private string _r2rUnit = string.Empty;
    private string _r2rMmcTxnId = string.Empty;
    private string _r2rDataInfo = string.Empty;
    private readonly string[] _r2rAack;

    // TIB subject strings
    private string _localSubject = string.Empty;
    private string _remoteSubject = string.Empty;
    private string _easLocalSubject = string.Empty;
    private string _easRemoteSubject = string.Empty;
    private string _r2rLocalSubject = string.Empty;
    private string _r2rRemoteSubject = string.Empty;
    private string _servicePort = string.Empty;
    private string _r2rServicePort = string.Empty;

    // System/user identification
    private string _systemNoMgib = string.Empty;
    private string _systemNoPgib = string.Empty;
    private string _systemNo = string.Empty;
    private string _userId = string.Empty;
    private string _hostDate = string.Empty;

    // MES parsed fields
    private string _mesSerialNo = string.Empty;
    private string _mesLabelId = string.Empty;
    private string _mesPf = string.Empty;
    private string _mesPid = string.Empty;
    private string _mesFogId = string.Empty;

    // FTP fields (legacy, mostly commented out in Delphi)
    private string _ftpPass = string.Empty;
    private string _ftpUser = string.Empty;
    private string _ftpAddr = string.Empty;
    private string _ftpCombiPath = string.Empty;

    private string _mesUserName = string.Empty;
    private int _mesPg;
    private int _mesApdrPg;
    private int _mesSerialType;

    // File download state
    private bool _combiDown;
    private bool _defectDown;
    private bool _fullDefectDown;
    private bool _repairDown;
    private bool _fullRepairDown;
    private string _combiDownFile = string.Empty, _combiDownDate = string.Empty;
    private string _defectDownFile = string.Empty, _defectDownDate = string.Empty;
    private string _fullDefectDownFile = string.Empty, _fullDefectDownDate = string.Empty;
    private string _repairDownFile = string.Empty, _repairDownDate = string.Empty;
    private string _fullRepairDownFile = string.Empty, _fullRepairDownDate = string.Empty;

    // Per-channel serial tracking
    private readonly string[] _pgSerial;

    // Message queue (replaces Delphi TQueue<TQueItemValue> + TTimer)
    private readonly ConcurrentQueue<MesQueueItem> _queue = new();
    private MesQueueItem? _currentItem;
    private readonly System.Threading.Timer _queueTimer;
    private readonly System.Threading.Timer _responseTimer;

    private bool _eijrSend;
    private bool _disposed;

    // =========================================================================
    // R2R EODS name constants (from CommonClass.pas)
    // =========================================================================

    private static readonly string[] R2REodsNames =
    {
        "OC_W600_X", "OC_W600_Y", "OC_W600_Z",
        "OC_R600_X", "OC_R600_Y", "OC_R600_Z",
        "OC_G600_X", "OC_G600_Y", "OC_G600_Z",
        "OC_B600_X", "OC_B600_Y", "OC_B600_Z",
        "MPO_W600_L", "MPO_W600_X", "MPO_W600_Y",
        "MPO_R600_L", "MPO_R600_X", "MPO_R600_Y",
        "MPO_G600_L", "MPO_G600_X", "MPO_G600_Y",
        "MPO_B600_L", "MPO_B600_X", "MPO_B600_Y"
    };

    // Channel constants
    private const int CH1 = ChannelConstants.Ch1;
    private const int MAX_CH = ChannelConstants.MaxCh;
    private const int MAX_PG_CNT = ChannelConstants.MaxPgCount;

    // =========================================================================
    // Constructor / Dispose
    // =========================================================================

    /// <summary>
    /// Creates a new GMES communication service.
    /// <para>Delphi: constructor TGmes.Create(AOwner, MainHandle, nServerCnt)</para>
    /// </summary>
    /// <param name="config">Configuration service (replaces global Common).</param>
    /// <param name="logger">Logger service.</param>
    /// <param name="messageBus">Message bus for UI notifications (replaces WM_COPYDATA).</param>
    /// <param name="mesCom">Native MES TIB communication interop.</param>
    public GmesCommunication(
        IConfigurationService config,
        ILogger logger,
        IMessageBus messageBus,
        IMesCommunication mesCom)
    {
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _mesCom = mesCom ?? throw new ArgumentNullException(nameof(mesCom));

        int chCount = MAX_CH + 1;

        // Initialize MES data per channel
        MesData = new GmesDataPack[MAX_PG_CNT];
        for (int i = 0; i < MAX_PG_CNT; i++)
            MesData[i] = new GmesDataPack();

        DoneEods = new bool[chCount];
        _pgSerial = new string[chCount];
        _r2rAack = new string[chCount];

        for (int i = 0; i < chCount; i++)
        {
            _pgSerial[i] = string.Empty;
            _r2rAack[i] = string.Empty;
        }

        // Delphi: tmGmesChMsg (500ms interval)
        _queueTimer = new System.Threading.Timer(OnQueueTimerElapsed, null, Timeout.Infinite, Timeout.Infinite);

        // Delphi: tmGmesResponse (3000ms interval, currently empty in Delphi)
        _responseTimer = new System.Threading.Timer(OnResponseTimerElapsed, null, Timeout.Infinite, Timeout.Infinite);

        // Register DLL callbacks so MES/EAS/R2R return data flows into this class.
        // Delphi: m_SetCallback_Return_MES(@MyCB_MESReturnMsg), etc.
        _mesCom.SetCallbacks(
            OnMesReturnData,
            OnEasReturnData,
            OnR2RReturnData,
            (msgType, msg) => _logger.Info(ChannelConstants.MaxPgCount, $"[TIB] {msg}"));
    }

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        StopQueueTimer();
        using (var queueWait = new ManualResetEvent(false))
        using (var responseWait = new ManualResetEvent(false))
        {
            _queueTimer.Dispose(queueWait);
            _responseTimer.Dispose(responseWait);
            queueWait.WaitOne(2000);
            responseWait.WaitOne(2000);
        }

        // Clear the queue
        while (_queue.TryDequeue(out _)) { }
        _currentItem = null;
    }

    // =========================================================================
    // IGmesCommunication Properties
    // =========================================================================

    /// <inheritdoc />
    public GmesDataPack[] MesData { get; }

    /// <inheritdoc />
    public bool CanUseHost { get => _canUseHost; set => _canUseHost = value; }

    /// <inheritdoc />
    public bool CanUseEas => _canUseEas;

    /// <inheritdoc />
    public bool CanUseR2R => _canUseR2R;

    /// <inheritdoc />
    public bool MesPmMode { get => _pmMode; set => _pmMode = value; }

    /// <inheritdoc />
    public bool MesEayt { get => _eayt; set => _eayt = value; }

    /// <inheritdoc />
    public string MesRtnCd { get => _mesRtnCd; set => _mesRtnCd = value; }

    /// <inheritdoc />
    public string MesErrMsgEn { get => _mesErrMsgEn; set => _mesErrMsgEn = value; }

    /// <inheritdoc />
    public string MesErrMsgLc { get => _mesErrMsgLc; set => _mesErrMsgLc = value; }

    /// <inheritdoc />
    public string MesModel { get => _mesModel; set => _mesModel = value; }

    /// <inheritdoc />
    public string MesModelInfo { get => _mesModelInfo; set => _mesModelInfo = value; }

    /// <inheritdoc />
    public string MesSystemNo { get => _systemNo; set => _systemNo = value; }

    /// <inheritdoc />
    public string MesSystemNoMgib { get => _systemNoMgib; set => _systemNoMgib = value; }

    /// <inheritdoc />
    public string MesSystemNoPgib { get => _systemNoPgib; set => _systemNoPgib = value; }

    /// <inheritdoc />
    public string MesUserId { get => _userId; set => _userId = value; }

    /// <inheritdoc />
    public string MesSerialNo { get => _mesSerialNo; set => _mesSerialNo = value; }

    /// <inheritdoc />
    public string MesLabelId { get => _mesLabelId; set => _mesLabelId = value; }

    /// <inheritdoc />
    public string MesUserName { get => _mesUserName; set => _mesUserName = value; }

    /// <inheritdoc />
    public string MesPid { get => _mesPid; set => _mesPid = value; }

    /// <inheritdoc />
    public int MesPg { get => _mesPg; set => _mesPg = value; }

    /// <inheritdoc />
    public int MesApdrPg { get => _mesApdrPg; set => _mesApdrPg = value; }

    /// <inheritdoc />
    public int MesSerialType { get => _mesSerialType; set => _mesSerialType = value; }

    /// <inheritdoc />
    public string MesFogId { get => _mesFogId; set => _mesFogId = value; }

    /// <inheritdoc />
    public string R2RMachine => _r2rMachine;

    /// <inheritdoc />
    public string R2RMmcTxnId => _r2rMmcTxnId;

    /// <inheritdoc />
    public string LotNo { get; set; } = string.Empty;

    /// <inheritdoc />
    public bool EijrSend { get => _eijrSend; set => _eijrSend = value; }

    /// <inheritdoc />
    public bool[] DoneEods { get; }

    /// <inheritdoc />
    public int MesQueueCount => _queue.Count + 1;

    /// <inheritdoc />
    public string FtpAddr { get => _ftpAddr; set => _ftpAddr = value; }

    /// <inheritdoc />
    public string FtpUser { get => _ftpUser; set => _ftpUser = value; }

    /// <inheritdoc />
    public string FtpPass { get => _ftpPass; set => _ftpPass = value; }

    /// <inheritdoc />
    public string FtpCombiPath { get => _ftpCombiPath; set => _ftpCombiPath = value; }

    /// <inheritdoc />
    public event Action<int, int, bool, string>? OnGmesEvent;

    // =========================================================================
    // Initialization (HOST_Initial, Eas_Initial, R2R_Initial)
    // =========================================================================

    /// <inheritdoc />
    public bool HostInitial(string servicePort, string network, string daemonPort,
                            string localSubject, string remoteSubject, string logPath)
    {
        // Delphi: CommTibRv.Initialize(TIBServer_MES, ...)
        if (!_mesCom.IsLoaded)
        {
            _logger.Error($"HostInitial: DLL not loaded. {_mesCom.ErrorMessage}");
            return false;
        }

        _mesCom.LogPath = logPath;
        _canUseHost = _mesCom.Initialize(TibServer.Mes, servicePort, network,
                                          daemonPort, localSubject, remoteSubject);

        if (!_canUseHost)
        {
            _logger.Error($"HostInitial: Init_TIB failed. ServicePort={servicePort}, Network={network}, DaemonPort={daemonPort}, Local={localSubject}, Remote={remoteSubject}");
        }

        _localSubject = localSubject;
        _remoteSubject = remoteSubject;
        _servicePort = servicePort;

        for (int ch = CH1; ch <= MAX_CH; ch++)
        {
            MesData[ch].MesPendingMsg = DefGmes.MesUnknown;
        }

        return _canUseHost;
    }

    /// <inheritdoc />
    public bool EasInitial(string servicePort, string network, string daemonPort,
                           string localSubject, string remoteSubject, string logPath)
    {
        _mesCom.LogPath = logPath;
        _easRemoteSubject = remoteSubject;
        _easLocalSubject = localSubject;
        _canUseEas = _mesCom.Initialize(TibServer.Eas, servicePort, network,
                                         daemonPort, localSubject, remoteSubject);

        if (!_canUseEas)
        {
            _logger.Warn("[EAS initialization failure - Confirm HOST environment setup]");
        }

        return _canUseEas;
    }

    /// <inheritdoc />
    public bool R2RInitial(string servicePort, string network, string daemonPort,
                           string localSubject, string remoteSubject, string logPath)
    {
        _mesCom.LogPath = logPath;
        _r2rRemoteSubject = remoteSubject;
        _r2rLocalSubject = localSubject;
        _canUseR2R = _mesCom.Initialize(TibServer.R2R, servicePort, network,
                                         daemonPort, localSubject, remoteSubject);

        _r2rServicePort = servicePort;

        if (!_canUseR2R)
        {
            _logger.Warn("[R2R initialization failure - Confirm HOST environment setup]");
        }

        // Load previous EODS data from config
        var sysInfo = _config.SystemInfo;
        for (int i = CH1; i <= ChannelConstants.Ch4; i++)
        {
            if (!string.IsNullOrEmpty(sysInfo.R2REODSData[i]))
            {
                var eodsData = sysInfo.R2REODSData[i].Split(',');
                if (eodsData.Length == 24)
                {
                    // NOTE: The R2R old OC data would be set on the script objects.
                    // This is a cross-cutting concern handled at a higher level.
                    _logger.Info(i, $"R2R EODS data loaded: {eodsData.Length} items");
                }
            }
        }

        return _canUseR2R;
    }

    // =========================================================================
    // Host Start / R2R Start
    // =========================================================================

    /// <inheritdoc />
    public void SendHostStart()
    {
        // Delphi: procedure TGmes.SendHostStart
        if (!_canUseHost)
        {
            _logger.Warn("[HOST initialization failure - Confirm HOST environment setup]");
        }
        else
        {
            if (!_eayt)
                SendMessage(DefGmes.MesEayt);
            else
                SendMessage(DefGmes.MesUchk);
        }
    }

    /// <inheritdoc />
    public void SendR2RStart()
    {
        if (!_canUseHost)
        {
            _logger.Warn("[HOST initialization failure - Confirm HOST environment setup]");
        }
        else
        {
            if (!_r2rEayt)
                SendMessage(DefGmes.R2rEayt);
        }
    }

    // =========================================================================
    // MES Send Methods (enqueue into message queue)
    // =========================================================================

    /// <inheritdoc />
    public void SendHostEayt()
    {
        _mesPg = 0;
        _mesApdrPg = 0;
        SendMessage(DefGmes.MesEayt);
    }

    /// <inheritdoc />
    public void SendHostUchk()
    {
        _mesPg = 0;
        _mesApdrPg = 0;
        SendMessage(DefGmes.MesUchk);
    }

    /// <inheritdoc />
    public void SendHostEqcc()
    {
        SendMessage(DefGmes.MesEqcc);
    }

    /// <inheritdoc />
    public void SendHostPchk(string serialNo, int pg, string jigId)
    {
        if (string.IsNullOrEmpty(serialNo)) return;

        _mesPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);
        string convertJig = string.IsNullOrEmpty(jigId) ? convertSerial : ConvertSerialForHost(jigId);
        _pgSerial[pg] = convertSerial;

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.MesPchk,
            Timeout = 60000,
            SerialNo = convertSerial,
            CarrierId = convertJig,
            RetryCnt = 0
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendHostLpir(string serialNo, int pg)
    {
        if (string.IsNullOrEmpty(serialNo)) return;

        _mesPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);
        _pgSerial[pg] = convertSerial;

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.MesLpir,
            Timeout = 3000,
            SerialNo = convertSerial,
            RetryCnt = 0
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendHostInsPchk(string serialNo, int pg, string jigId)
    {
        _mesPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);
        string convertJig = string.IsNullOrEmpty(jigId) ? convertSerial : ConvertSerialForHost(jigId);
        _pgSerial[pg] = convertSerial;

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.MesInsPchk,
            Timeout = 60000,
            SerialNo = convertSerial,
            CarrierId = convertJig,
            RetryCnt = 0
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendHostEicr(string serialNo, int pg, string jigId)
    {
        _mesPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);
        string convertJig = string.IsNullOrEmpty(jigId) ? convertSerial : ConvertSerialForHost(jigId);

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.MesEicr,
            Timeout = 60000,
            SerialNo = convertSerial,
            CarrierId = convertJig,
            Tact = MesData[pg].Tact,
            MesCode = MesData[pg].Rwk,
            ErrCode = MesData[pg].ErrCode,
            RetryCnt = 0
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendHostEijr(string serialNo, int pg, string jigId)
    {
        _mesPg = pg;
        _eijrSend = true;
        string convertSerial = ConvertSerialForHost(serialNo);
        _pgSerial[pg] = convertSerial;
        string convertJig = string.IsNullOrEmpty(jigId) ? convertSerial : ConvertSerialForHost(jigId);

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.MesEijr,
            Timeout = 60000,
            SerialNo = convertSerial,
            RetryCnt = 0
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendHostRprEijr(string serialNo, int pg, string jigId)
    {
        _mesPg = pg;
        _eijrSend = true;
        string convertSerial = ConvertSerialForHost(serialNo);
        _pgSerial[pg] = convertSerial;
        string convertJig = string.IsNullOrEmpty(jigId) ? convertSerial : ConvertSerialForHost(jigId);

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.MesRprEijr,
            Timeout = 60000,
            SerialNo = convertSerial,
            CarrierId = convertJig,
            MesCode = MesData[pg].Rwk,
            RetryCnt = 0
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendHostRprVsir(string serialNo, int pg)
    {
        _mesPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);
        SendMessage(DefGmes.MesRprVsir, convertSerial, string.Empty, pg);
        Task.Delay(40).Wait();
    }

    /// <inheritdoc />
    public void SendHostApdr(string serialNo, int pg)
    {
        _mesApdrPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.MesApdr,
            Timeout = 3000,
            SerialNo = convertSerial,
            Tact = MesData[pg].Tact,
            MesCode = MesData[pg].Rwk,
            ApdrData = MesData[pg].ApdrData,
            RetryCnt = 0
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendHostRepn(string serialNo, int pg)
    {
        _mesPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);
        SendMessage(DefGmes.MesRepn, convertSerial, string.Empty, pg);
    }

    /// <inheritdoc />
    public void SendHostFldr(string message)
    {
        SendMessage(DefGmes.MesFldr, message);
    }

    /// <inheritdoc />
    public void SendHostZset(string pid, string zigId)
    {
        SendMessage(DefGmes.MesZset, pid, zigId);
    }

    /// <inheritdoc />
    public void SendHostSgen(string serialNo, int pg)
    {
        if (string.IsNullOrEmpty(serialNo)) return;

        _mesPg = pg;
        string convertSerial = ConvertSerialForHost(serialNo);
        _pgSerial[pg] = convertSerial;
        SendMessage(DefGmes.MesSgen, convertSerial, string.Empty, pg);
    }

    // =========================================================================
    // EAS Send Methods
    // =========================================================================

    /// <inheritdoc />
    public void SendEasApdr(string serialNo, int pg)
    {
        _mesApdrPg = pg;
        _logger.Info(pg, $"SendEasApdr Start!! PID: {serialNo}");
        string convertSerial = ConvertSerialForHost(serialNo);

        var item = new MesQueueItem
        {
            Channel = pg,
            Kind = DefGmes.EasApdr,
            Timeout = 3000,
            SerialNo = convertSerial,
            Tact = MesData[pg].Tact,
            MesCode = MesData[pg].Rwk,
            RetryCnt = 0,
            State = DefGmes.MesUnknown
        };
        EnqueueAndStart(item);
        _logger.Info(pg, "SendEasApdr Done!!");
    }

    // =========================================================================
    // R2R Send Methods
    // =========================================================================

    /// <inheritdoc />
    public void SendR2REayt()
    {
        _mesPg = 0;
        _mesApdrPg = 0;
        SendMessage(DefGmes.R2rEayt);
    }

    /// <inheritdoc />
    public void SendR2REods(int pg)
    {
        var item = new MesQueueItem
        {
            Channel = pg,
            State = 0,
            Kind = DefGmes.R2rEodsR,
            Timeout = 3000,
            ApdrData = string.Empty,
            SerialNo = string.Empty,
            CarrierId = string.Empty
        };
        EnqueueAndStart(item);
    }

    /// <inheritdoc />
    public void SendR2REodsTest(int channel)
    {
        SendMessage(DefGmes.R2rEods, string.Empty, string.Empty, channel);
    }

    /// <inheritdoc />
    public void SendR2REoda(int pg, int aack)
    {
        MesData[pg].MesSentMsg = DefGmes.MesUnknown;
        DoneEods[pg] = false;
        _r2rAack[pg] = aack.ToString();
        MesData[pg].EodaAck = aack;

        var item = new MesQueueItem
        {
            State = 0,
            Channel = pg,
            Kind = DefGmes.R2rEoda,
            Timeout = 3000,
            ApdrData = string.Empty,
            SerialNo = string.Empty,
            CarrierId = string.Empty
        };
        EnqueueAndStart(item);
    }

    // =========================================================================
    // Data Processing (incoming message handlers)
    // =========================================================================

    /// <inheritdoc />
    public void GetHostData(string message)
    {
        // Delphi: procedure TGmes.GetHostData
        if (message.Length < 6) return;

        string mode = message[..6];
        SeperateData(message, out int ch);

        // Route to appropriate parser based on message mode prefix
        if (mode == "EAYT_R") ParseEayt();
        else if (mode == "UCHK_R") ParseUchk();
        else if (mode == "SGEN_R") ParseSgen(ch, message);
        else if (mode == "EDTI_R") ParseEdti();
        else if (mode == "EQCC_R") ParseEqcc();
        else if (mode == "PCHK_R") ParsePchk(ch, message);
        else if (mode == "INS_PC") ParseInsPchk(ch, message);
        else if (mode == "LPHI_R") { /* parse_LPHI - empty in Delphi */ }
        else if (mode == "REPN_R") { /* parse_REPN - empty in Delphi */ }
        else if (mode == "APDR_R") ParseApdr(ch, message, isMes: true);
        else if (mode == "ZSET_R") ParseZset();
        else if (mode == "LPIR_R") ParseLpir(ch, message);
        else if (mode == "EICR_R") ParseEicr(ch, message);
        else if (mode == "RPR_EI") ParseRprEijr(ch, message);
        else if (mode == "EIJR_R") ParseEijr(ch, message);

        // Mark current MES item as complete
        if (_currentItem != null)
            _currentItem.State = DefGmes.MesUnknown;
    }

    /// <inheritdoc />
    public void GetEasData(string message)
    {
        // Delphi: procedure TGmes.GetEasData - mostly commented out
        if (message.Length < 6) return;

        // Current Delphi implementation only clears state
        if (_currentItem != null)
            _currentItem.State = DefGmes.MesUnknown;
    }

    /// <inheritdoc />
    public void GetR2RData(string message)
    {
        // Delphi: procedure TGmes.GetR2RData
        if (message.Length < 4) return;

        string mode = message[..4];

        if (mode == "EODS")
        {
            SeperateData(message, out int ch);

            int r2rUnit = int.TryParse(_r2rUnit, out int u) ? u - 1 : 0;

            string debugMsg = message.Replace("\n", "$").Replace("\r", "%");
            _logger.Info(r2rUnit, $"[R2R] Recv Msg: {debugMsg} PG : {r2rUnit}");

            // Parse R2R data
            SeperateR2RData(r2rUnit, _r2rDataInfo);

            ReturnDataToTestForm(DefGmes.R2rEods, r2rUnit, false, "R2R_DATA");
            DoneEods[r2rUnit] = true;

            _logger.Info(r2rUnit, "Send EODS_R Start");
            ParseEods(r2rUnit);
            _logger.Info(r2rUnit, "Send EODS_R Done");

            ReturnDataToTestForm(DefGmes.R2rEoda, r2rUnit, false, "R2R_DATA");

            if (_currentItem != null)
                _currentItem.State = DefGmes.MesUnknown;
        }
    }

    /// <inheritdoc />
    public string GetEasR2RData(int channel)
    {
        // Delphi: function TGmes.GetEASR2RData
        // NOTE: This method references PasScr[nCH].FR2R_Old_OC_Data which is in the script layer.
        // In C#, this data would need to be provided via a delegate or additional interface.
        // Returning a placeholder format; the caller must provide the actual R2R OC data.
        var sb = new StringBuilder();

        for (int i = 0; i < 24; i++)
        {
            sb.Append("R2R_OFF_SET:")
              .Append(R2REodsNames[i])
              .Append(':')
              .Append(string.Empty) // PasScr[channel].FR2R_Old_OC_Data[i] equivalent
              .Append(',');
        }

        sb.Append("R2R_OFF_SET:MMC_TXN_ID:")
          .Append(string.Empty) // PasScr[channel].FR2R_Old_MmcTxnID_Data equivalent
          .Append(',');
        sb.Append("R2R_OFF_SET:EODA_ACK:")
          .Append(MesData[channel].EodaAck);

        return sb.ToString();
    }

    // =========================================================================
    // Native callback handlers (called from MesComInterop via delegate)
    // =========================================================================

    /// <summary>
    /// Handle MES return data callback from native DLL.
    /// <para>Delphi: procedure ReadMsgHost64(sMessage)</para>
    /// </summary>
    public void OnMesReturnData(string message)
    {
        GetHostData(message);
    }

    /// <summary>
    /// Handle R2R return data callback from native DLL.
    /// <para>Delphi: procedure ReadMsgR2R64(sMessage)</para>
    /// </summary>
    public void OnR2RReturnData(string message)
    {
        GetR2RData(message);
    }

    /// <summary>
    /// Handle EAS return data callback from native DLL.
    /// <para>Delphi: procedure ReadMsgEas64(sMessage)</para>
    /// </summary>
    public void OnEasReturnData(string message)
    {
        _logger.Info(ChannelConstants.MaxPgCount,
            $"[EAS] RECV ThreadID:{Environment.CurrentManagedThreadId:X4}");
    }

    // =========================================================================
    // Private Parse Methods (response handlers)
    // =========================================================================

    /// <summary>Delphi: procedure parse_EAYT</summary>
    private void ParseEayt()
    {
        if (_mesRtnCd == "0")
        {
            _eayt = true;
            SendMessage(DefGmes.MesUchk);
            OnGmesEvent?.Invoke(DefGmes.MesEayt, 0, false, string.Empty);
        }
        else
        {
            OnGmesEvent?.Invoke(DefGmes.MesEayt, 0, true, string.Empty);
        }
    }

    /// <summary>Delphi: procedure parse_UCHK</summary>
    private void ParseUchk()
    {
        if (_mesRtnCd.Trim() == "0")
        {
            _hostDate = _hostDate;
            _pmMode = false;
            SendMessage(DefGmes.MesEdti);
            OnGmesEvent?.Invoke(DefGmes.MesUchk, 0, false,
                $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})");
        }
        else
        {
            OnGmesEvent?.Invoke(DefGmes.MesUchk, 0, true,
                $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})");
        }
    }

    /// <summary>Delphi: procedure parse_EDTI</summary>
    private void ParseEdti()
    {
        if (_mesRtnCd == "0")
        {
            if (_canUseR2R && !_r2rEayt)
            {
                SendMessage(DefGmes.R2rEayt);
            }
            OnGmesEvent?.Invoke(DefGmes.MesEdti, 0, false, string.Empty);
        }
        else
        {
            OnGmesEvent?.Invoke(DefGmes.MesEdti, 0, true, string.Empty);
        }
    }

    /// <summary>Delphi: procedure parse_R2REAYT</summary>
    private void ParseR2REayt()
    {
        if (_mesRtnCd == "0")
        {
            _r2rEayt = true;
            OnGmesEvent?.Invoke(DefGmes.R2rEayt, 0, false, string.Empty);
        }
        else
        {
            OnGmesEvent?.Invoke(DefGmes.R2rEayt, 0, true, string.Empty);
        }
    }

    /// <summary>Delphi: procedure parse_EQCC</summary>
    private void ParseEqcc()
    {
        if (_mesRtnCd != "0")
        {
            OnGmesEvent?.Invoke(DefGmes.MesEqcc, 0, true,
                $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})");
        }
    }

    /// <summary>Delphi: procedure parse_PCHK(nCh, sMsg)</summary>
    private void ParsePchk(int ch, string msg)
    {
        // Convert serial
        string serialNo = _mesFogId.Replace("\n", "$").Replace("\r", "%");

        // If serial is empty, use PID (Delphi non-POCB behavior)
        if (string.IsNullOrEmpty(_mesSerialNo))
            _mesSerialNo = _mesPid;
        serialNo = _mesSerialNo.Replace("\n", "$").Replace("\r", "%");

        int pgNo = ResolvePgNo(ch, serialNo);

        if (IsValidChannel(pgNo))
            _logger.Info(pgNo, $"MES REV : {msg}");

        MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
        MesData[pgNo].PchkRtnCode = _mesRtnCd;
        MesData[pgNo].PchkRtnSerialNo = _mesSerialNo;
        MesData[pgNo].PchkRtnPid = _mesRtnPid;
        MesData[pgNo].PchkRtnZigId = _mesZigId;

        int dashPos = _mesModel.IndexOf('-');
        MesData[pgNo].Model = _mesModel;
        MesData[pgNo].ErrMsgCd = _mesErrCd;
        MesData[pgNo].ErrMsgLoc = _mesErrMsgLc;
        MesData[pgNo].ErrMsgEng = _mesErrMsgEn;

        if (_mesRtnCd == "0")
        {
            MesData[pgNo].PchkResult = true;
            ReturnDataToTestForm(DefGmes.MesPchk, pgNo, false, DefGmes.PchkOkMsg);
        }
        else
        {
            MesData[pgNo].PchkResult = false;
            string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";
            ReturnDataToTestForm(DefGmes.MesPchk, pgNo, true, errMsg);
        }

        MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;
    }

    /// <summary>Delphi: procedure parse_INS_PCHK(nCh, sMsg)</summary>
    private void ParseInsPchk(int ch, string msg)
    {
        string serialNo = _mesFogId.Replace("\n", "$").Replace("\r", "%");
        int pgNo = ResolvePgNo(ch, serialNo);

        if (IsValidChannel(pgNo))
            _logger.Info(pgNo, $"MES REV : {msg}");

        MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
        MesData[pgNo].PchkRtnCode = _mesRtnCd;
        MesData[pgNo].PchkRtnSerialNo = _mesSerialNo;
        MesData[pgNo].PchkRtnPid = _mesRtnPid;
        MesData[pgNo].Model = _mesModel;
        MesData[pgNo].ErrMsgCd = _mesErrCd;
        MesData[pgNo].ErrMsgLoc = _mesErrMsgLc;
        MesData[pgNo].ErrMsgEng = _mesErrMsgEn;

        if (_mesRtnCd == "0")
        {
            MesData[pgNo].PchkResult = true;
            ReturnDataToTestForm(DefGmes.MesInsPchk, pgNo, false, DefGmes.PchkOkMsg);
        }
        else
        {
            MesData[pgNo].PchkResult = false;
            string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";
            ReturnDataToTestForm(DefGmes.MesInsPchk, pgNo, true, errMsg);
        }

        MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;
    }

    /// <summary>Delphi: procedure parse_EICR(nCh, sMsg)</summary>
    private void ParseEicr(int ch, string msg)
    {
        string serialNo = _mesFogId.Replace("\n", "$").Replace("\r", "%");
        int pgNo = ResolvePgNo(ch, serialNo);

        MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
        MesData[pgNo].EicrRtnCode = _mesRtnCd;

        if (IsValidChannel(pgNo))
            _logger.Info(pgNo, $"MES REV : {msg}");

        MesData[pgNo].ErrMsgCd = _mesErrCd;
        MesData[pgNo].ErrMsgLoc = _mesErrMsgLc;
        MesData[pgNo].ErrMsgEng = _mesErrMsgEn;

        if (_mesRtnCd == "0")
        {
            ReturnDataToTestForm(DefGmes.MesEicr, pgNo, false, DefGmes.EicrOkMsg);
        }
        else
        {
            string errMsg = $"Error code:{_mesRtnCd}:{_mesErrCd}:{_mesErrMsgLc} ({_mesErrMsgEn})";
            ReturnDataToTestForm(DefGmes.MesEicr, pgNo, true, errMsg);
        }

        MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;
    }

    /// <summary>Delphi: procedure parse_EIJR(nCh, sMsg)</summary>
    private void ParseEijr(int ch, string msg)
    {
        string serialNo = _mesFogId.Replace("\n", "$").Replace("\r", "%");
        int pgNo = ResolvePgNoBySerial(serialNo);

        MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
        MesData[pgNo].EicrRtnCode = _mesRtnCd;
        _eijrSend = false;

        if (IsValidChannel(pgNo))
            _logger.Info(pgNo, msg);

        MesData[pgNo].ErrMsgCd = _mesErrCd;
        MesData[pgNo].ErrMsgLoc = _mesErrMsgLc;
        MesData[pgNo].ErrMsgEng = _mesErrMsgEn;

        if (_mesRtnCd == "0")
            ReturnDataToTestForm(DefGmes.MesEijr, pgNo, false, DefGmes.EicrOkMsg);
        else
        {
            string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";
            ReturnDataToTestForm(DefGmes.MesEijr, pgNo, true, errMsg);
        }

        MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;
    }

    /// <summary>Delphi: procedure parse_RPR_EIJR(nCh, sMsg)</summary>
    private void ParseRprEijr(int ch, string msg)
    {
        string serialNo = _mesFogId.Replace("\n", "$").Replace("\r", "%");
        int pgNo = ResolvePgNo(ch, serialNo);

        if (IsValidChannel(pgNo))
            _logger.Info(pgNo, $"MES REV : {msg}");

        _eijrSend = false;
        MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
        MesData[pgNo].EicrRtnCode = _mesRtnCd;
        MesData[pgNo].SerialNo = serialNo;
        MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;
        MesData[pgNo].ErrMsgCd = _mesErrCd;
        MesData[pgNo].ErrMsgLoc = _mesErrMsgLc;
        MesData[pgNo].ErrMsgEng = _mesErrMsgEn;

        if (_mesRtnCd == "0")
            ReturnDataToTestForm(DefGmes.MesRprEijr, pgNo, false, DefGmes.RprEijrOkMsg);
        else
        {
            string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";
            ReturnDataToTestForm(DefGmes.MesRprEijr, pgNo, true, errMsg);
        }
    }

    /// <summary>Delphi: procedure parse_APDR(nCh, sMsg, bMes)</summary>
    private void ParseApdr(int ch, string msg, bool isMes)
    {
        string serialNo = _mesFogId.Replace("\n", "$").Replace("\r", "%");
        int pgNo = ResolvePgNo(ch, serialNo);

        if (IsValidChannel(pgNo))
        {
            string prefix = isMes ? "MES REV : " : "EAS REV : ";
            string debug = msg.Length > 600 ? msg[..600] : msg;
            _logger.Info(pgNo, prefix + debug);
        }

        if (isMes)
        {
            MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
            MesData[pgNo].ApdrRtnCode = _mesRtnCd;
            MesData[pgNo].ApdrRtnSerialNo = serialNo;
            MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;
        }

        int mesType = isMes ? DefGmes.MesApdr : DefGmes.EasApdr;

        if (_mesRtnCd == "0")
        {
            ReturnDataToTestForm(mesType, pgNo, false, DefGmes.ApdrOkMsg);
        }
        else
        {
            string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";
            ReturnDataToTestForm(mesType, pgNo, true, errMsg);
        }
    }

    /// <summary>Delphi: procedure parse_SGEN(nCh, sMsg)</summary>
    private void ParseSgen(int ch, string msg)
    {
        string serialNo = _mesPid.Replace("\n", "$").Replace("\r", "%");
        int pgNo = ResolvePgNo(ch, serialNo);

        if (IsValidChannel(pgNo))
            _logger.Info(pgNo, $"MES REV : {msg}");

        MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
        MesData[pgNo].PchkRtnCode = _mesRtnCd;
        MesData[pgNo].PchkRtnSerialNo = _mesSerialNo;

        if (_mesRtnCd == "0")
        {
            MesData[pgNo].PchkResult = true;
            ReturnDataToTestForm(DefGmes.MesSgen, pgNo, false, "SGEN OK!");
        }
        else
        {
            MesData[pgNo].PchkResult = false;
            string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";
            ReturnDataToTestForm(DefGmes.MesSgen, pgNo, true, errMsg);
        }

        MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;
    }

    /// <summary>Delphi: procedure parse_LPIR(nCh, sMsg)</summary>
    private void ParseLpir(int ch, string msg)
    {
        string serialNo = _mesFogId.Replace("\n", "$").Replace("\r", "%");
        int pgNo = ResolvePgNo(ch, serialNo);

        if (IsValidChannel(pgNo))
            _logger.Info(pgNo, $"MES REV : {msg}");

        MesData[pgNo].MesPendingMsg = DefGmes.MesUnknown;
        MesData[pgNo].LpirProcessCode = _mesProsessCode;

        // Extract LPIR Latest_Insp info: [MPO:F:A0G-B01-----DN0-------------------------70M--] -> A0G-B01-DN0
        if (_mesLatestInsp.Length >= 22)
        {
            // Delphi: Copy(FMesLATEST_Insp, 8, 7) + '-' + Copy(FMesLATEST_Insp, 20, 3)
            MesData[pgNo].LpirLatestInsp = _mesLatestInsp.Substring(7, 7) + "-" + _mesLatestInsp.Substring(19, 3);
            _logger.Info(pgNo, $"LPIR Lastest_Insp Extracted: {MesData[pgNo].LpirLatestInsp} (Original: {_mesLatestInsp})");
        }
        else
        {
            MesData[pgNo].LpirLatestInsp = _mesLatestInsp;
        }

        MesData[pgNo].MesSentMsg = DefGmes.MesUnknown;

        if (_mesRtnCd == "0")
        {
            MesData[pgNo].LpirResult = true;
            OnGmesEvent?.Invoke(DefGmes.MesLpir, 0, false, string.Empty);
            ReturnDataToTestForm(DefGmes.MesLpir, pgNo, false, DefGmes.LpirOkMsg);
        }
        else
        {
            MesData[pgNo].LpirResult = false;
            string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";
            OnGmesEvent?.Invoke(DefGmes.MesLpir, 0, true, string.Empty);
            ReturnDataToTestForm(DefGmes.MesLpir, pgNo, true, errMsg);
        }
    }

    /// <summary>Delphi: procedure parse_ZSET</summary>
    private void ParseZset()
    {
        string errMsg = $"Error code:{_mesRtnCd} : {_mesErrMsgLc} ({_mesErrMsgEn})";

        if (_mesRtnCd.Trim() == "0")
        {
            MesData[CH1].PchkResult = true;
            ReturnDataToTestForm(DefGmes.MesZset, 0, false, errMsg);
        }
        else
        {
            MesData[CH1].PchkResult = false;
            ReturnDataToTestForm(DefGmes.MesZset, 0, true, errMsg);
        }
    }

    /// <summary>Delphi: procedure parse_EODS(nCH)</summary>
    private void ParseEods(int ch)
    {
        MesData[ch].MesSentMsg = DefGmes.MesUnknown;
        SendR2REods(ch);
    }

    // =========================================================================
    // SEND_MESG2HOST - Core message building and sending
    // =========================================================================

    /// <summary>
    /// Build and send a MES protocol message to the HOST/EAS/R2R server.
    /// <para>Delphi: procedure SEND_MESG2HOST(nMsgType, sSerialNo, sZigId, nPg, bIsDelayed)</para>
    /// </summary>
    private void SendMessage(int msgType, string serialNo = "", string zigId = "",
                             int pg = 0, bool isDelayed = false)
    {
        string sendMsg;
        bool isChMsg = false;
        var sysInfo = _config.SystemInfo;
        var plcInfo = _config.PlcInfo;
        string now = DateTime.Now.ToString("yyyyMMddHHmmss");

        switch (msgType)
        {
            case DefGmes.MesPchk:
                sendMsg = BuildPchkMessage(serialNo, zigId, pg, sysInfo, plcInfo, now);
                isChMsg = true;
                break;

            case DefGmes.MesLpir:
                sendMsg = BuildLpirMessage(serialNo, pg, sysInfo, now);
                isChMsg = true;
                break;

            case DefGmes.MesInsPchk:
                sendMsg = BuildInsPchkMessage(serialNo, zigId, pg, sysInfo, plcInfo, now);
                isChMsg = true;
                break;

            case DefGmes.MesEayt:
                sendMsg = $"EAYT ADDR={_localSubject},{_localSubject}" +
                          $" EQP={_systemNo}" +
                          $" NET_IP={sysInfo.LocalIPGMES} NET_PORT={_servicePort}" +
                          " MODE=AUTO" +
                          $" CLIENT_DATE={now}";
                break;

            case DefGmes.MesUchk:
                sendMsg = $"UCHK ADDR={_localSubject},{_localSubject}" +
                          $" EQP={_systemNo}" +
                          $" USER_ID={_userId}" +
                          " MODE=AUTO" +
                          $" CLIENT_DATE={now}";
                break;

            case DefGmes.MesSgen:
                sendMsg = $"SGEN ADDR={_localSubject},{_localSubject}" +
                          $" EQP={_systemNo}" +
                          $" PID={serialNo}" +
                          " PRT_MAKER=ZEBRA PRT_RESOLUTION=600 PRT_QTY=1 LABEL_ROTATION_FLAG=N" +
                          $" USER_ID={_userId} MODE=AUTO CLIENT_DATE={now}";
                isChMsg = true;
                break;

            case DefGmes.MesEdti:
                sendMsg = BuildEdtiMessage(sysInfo, now);
                break;

            case DefGmes.MesFldr:
                sendMsg = BuildFldrMessage(serialNo, now);
                break;

            case DefGmes.MesEqcc:
                sendMsg = $"EQCC EQP={_systemNo} USER_ID={_userId} MODE=AUTO CLIENT_DATE={now}";
                break;

            case DefGmes.MesEicr:
                sendMsg = BuildEicrMessage(serialNo, zigId, pg, sysInfo, now);
                isChMsg = true;
                break;

            case DefGmes.MesEijr:
                sendMsg = BuildEijrMessage(serialNo, pg, sysInfo, plcInfo, now);
                isChMsg = true;
                break;

            case DefGmes.MesRprEijr:
                sendMsg = BuildRprEijrMessage(serialNo, pg, sysInfo, plcInfo, now);
                isChMsg = true;
                break;

            case DefGmes.MesZset:
                sendMsg = $"ZSET ADDR={_localSubject},{_localSubject}" +
                          $" PID={serialNo} ZIG_ID={zigId}" +
                          $" ACT_FLAG=A USER_ID={_userId} MODE=AUTO COMMENT=[] CLIENT_DATE={now}";
                break;

            case DefGmes.MesApdr:
                sendMsg = BuildApdrMessage(serialNo, pg, sysInfo, now);
                isChMsg = true;
                break;

            case DefGmes.EasApdr:
                sendMsg = BuildEasApdrMessage(serialNo, pg, sysInfo, plcInfo, now);
                isChMsg = true;
                break;

            case DefGmes.MesRepn:
                sendMsg = $"REPN ADDR={_localSubject},{_localSubject} EQP={_systemNo}" +
                          $" SERIAL_NO={serialNo} USER_ID={_userId} MODE=AUTO CLIENT_DATE={now}";
                break;

            case DefGmes.R2rEayt:
                sendMsg = $"EAYT ADDR={_r2rLocalSubject},{_r2rRemoteSubject}" +
                          $" EQP={_systemNo}" +
                          $" NET_IP={sysInfo.R2RNetwork} NET_PORT={_r2rServicePort}" +
                          $" MODE=AUTO CLIENT_DATE={now}";
                break;

            case DefGmes.R2rEods:
                sendMsg = BuildR2REodsTestMessage(pg, now);
                isChMsg = true;
                break;

            case DefGmes.R2rEoda:
                sendMsg = BuildR2REodaMessage(pg);
                isChMsg = true;
                break;

            case DefGmes.R2rEodsR:
                sendMsg = $"EODS_R ADDR={_r2rLocalSubject},{_r2rRemoteSubject}" +
                          $" EQP={_systemNo}" +
                          $" DATAINFO=[{_r2rMachine}::0]" +
                          $" MMC_TXN_ID="; // PasScr[pg].FR2R_MmcTxnID_Data
                isChMsg = true;
                break;

            default:
                return;
        }

        // Send the message
        if (_canUseHost)
        {
            // Track channel message state
            if (isChMsg && pg >= CH1 && pg <= MAX_CH)
            {
                bool isFireAndForget = msgType == DefGmes.EasApdr ||
                                       msgType == DefGmes.R2rEodsR ||
                                       msgType == DefGmes.R2rEoda ||
                                       msgType == DefGmes.R2rEayt;

                if (!isFireAndForget)
                {
                    MesData[pg].MesSentMsg = msgType;
                    MesData[pg].MesPendingMsg = DefGmes.MesUnknown;
                }
                else
                {
                    MesData[pg].MesSentMsg = DefGmes.MesUnknown;
                    MesData[pg].MesPendingMsg = DefGmes.MesUnknown;
                }

                MesData[pg].SerialNo = serialNo;
                MesData[pg].CarrierId = zigId;
                MesData[pg].MesSendRcvWaitTick = 0;
            }

            // Determine which TIB server to send to
            int tibChannel;
            if (msgType == DefGmes.R2rEods || msgType == DefGmes.R2rEodsR ||
                msgType == DefGmes.R2rEoda || msgType == DefGmes.R2rEayt)
            {
                tibChannel = TibServer.R2R;
            }
            else if (msgType == DefGmes.EasApdr)
            {
                _logger.Info(pg, "CommTibRv.Send_Data Start!!");
                tibChannel = TibServer.Eas;
            }
            else
            {
                tibChannel = TibServer.Mes;
            }

            bool result = _mesCom.SendData(tibChannel, sendMsg);

            // Log sent message
            if (isChMsg)
            {
                string debug = sendMsg.Length > 300 ? sendMsg[..300] + $"->(Cut 300/{sendMsg.Length}) " : sendMsg;
                string prefix = msgType switch
                {
                    DefGmes.EasApdr => "EAS SEND :  ",
                    >= DefGmes.R2rEodsR and <= DefGmes.R2rEoda => "R2R SEND :  ",
                    _ => "MES SEND :  "
                };
                _logger.Info(pg, prefix + debug);
            }

            if (msgType == DefGmes.EasApdr)
                _logger.Info(pg, "CommTibRv.Send_Data Finish!!");
        }
        else
        {
            _logger.Info(pg, $"[HOST] Can not USE Host MsgType: {msgType}, PG : {pg}, Serial: {serialNo}");
        }
    }

    // =========================================================================
    // Message Builders
    // =========================================================================

    private string BuildPchkMessage(string serialNo, string zigId, int pg,
                                     SystemInfo sysInfo, PLCInfo plcInfo, string now)
    {
        var sb = new StringBuilder("PCHK");
        sb.Append($" ADDR={_localSubject},{_localSubject}");

        // EQP selection based on InlineGIB mode
        if (plcInfo.InlineGIB)
        {
            if (MesData[pg].LpirProcessCode == sysInfo.EQPIdMGIBProcessCode)
                sb.Append($" EQP={sysInfo.EQPIdMGIB}");
            else if (MesData[pg].LpirProcessCode == sysInfo.EQPIdPGIBProcessCode)
                sb.Append($" EQP={sysInfo.EQPIdPGIB}");
            else
                sb.Append($" EQP={_systemNo}");
        }
        else
        {
            sb.Append($" EQP={_systemNo}");
        }

        sb.Append($" INSPCHANEL_A={pg}");

        if (sysInfo.OCType == ChannelConstants.OcType)
        {
            sb.Append(" PID=");
            if (serialNo.Contains("TEST_CH"))
                sb.Append($" ZIG_ID={zigId}");
            else
                sb.Append($" SERIAL_NO={serialNo}");
        }
        else
        {
            serialNo = serialNo.TrimEnd().Length > 30 ? serialNo[..30].Trim() : serialNo.Trim();
            sb.Append($" PID= PCB_ID={serialNo}");
        }

        sb.Append(" COVER_GLASS_ID= LCM_ID= BLID=[] PPALLET= SKD_BOX_ID=");
        sb.Append($" USER_ID={_userId} MODE=AUTO CLIENT_DATE={now} COMMENT=[]");
        sb.Append($" MODEL_INFO={_mesModelInfo}");

        return sb.ToString();
    }

    private string BuildLpirMessage(string serialNo, int pg, SystemInfo sysInfo, string now)
    {
        var sb = new StringBuilder("LPIR");
        sb.Append($" ADDR={_localSubject},{_localSubject}");
        sb.Append($" EQP={_systemNo}");
        sb.Append($" INSPCHANEL_A={pg}");

        if (sysInfo.OCType == ChannelConstants.OcType)
        {
            sb.Append($" PID= SERIAL_NO={serialNo}");
        }
        else
        {
            serialNo = serialNo.TrimEnd().Length > 30 ? serialNo[..30].Trim() : serialNo.Trim();
            sb.Append($" PID= PCB_ID={serialNo}");
        }

        sb.Append(" COVER_GLASS_ID= LCM_ID= BLID=[] PPALLET= SKD_BOX_ID=");
        sb.Append($" USER_ID={_userId} MODE=AUTO CLIENT_DATE={now} COMMENT=[]");
        sb.Append($" MODEL_INFO={_mesModelInfo}");

        return sb.ToString();
    }

    private string BuildInsPchkMessage(string serialNo, string zigId, int pg,
                                        SystemInfo sysInfo, PLCInfo plcInfo, string now)
    {
        var sb = new StringBuilder("INS_PCHK");
        sb.Append($" ADDR={_localSubject},{_localSubject}");

        if (plcInfo.InlineGIB)
        {
            if (MesData[pg].LpirProcessCode == sysInfo.EQPIdMGIBProcessCode)
            {
                _logger.Info(pg, $"LpirProcessCode : {MesData[pg].LpirProcessCode} EQPId_MGIB : {sysInfo.EQPIdMGIB} MGIB_Process_Code : {sysInfo.EQPIdMGIBProcessCode}");
                sb.Append($" EQP={sysInfo.EQPIdMGIB}");
            }
            else if (MesData[pg].LpirProcessCode == sysInfo.EQPIdPGIBProcessCode)
            {
                _logger.Info(pg, $"LpirProcessCode : {MesData[pg].LpirProcessCode} EQPId_PGIB : {sysInfo.EQPIdPGIB} PGIB_Process_Code : {sysInfo.EQPIdPGIBProcessCode}");
                sb.Append($" EQP={sysInfo.EQPIdPGIB}");
            }
            else
            {
                _logger.Info(pg, $"Mismatch !! - LpirProcessCode : {MesData[pg].LpirProcessCode} MGIB_Process_Code : {sysInfo.EQPIdMGIBProcessCode} PGIB_Process_Code : {sysInfo.EQPIdPGIBProcessCode}");
                sb.Append($" EQP={_systemNo}");
            }
        }
        else
        {
            sb.Append($" EQP={_systemNo}");
        }

        sb.Append($" INSPCHANEL_A={pg}");

        if (sysInfo.OCType == ChannelConstants.OcType)
        {
            sb.Append(" PID=");
            if (serialNo.Contains("TEST_CH"))
                sb.Append($" ZIG_ID={zigId}");
            else
                sb.Append($" SERIAL_NO={serialNo}");
        }
        else
        {
            sb.Append($" PID= PCB_ID={serialNo}");
        }

        sb.Append(" LCM_ID= BLID=[] COVER_GLASS_ID= ZIG_ID=");
        sb.Append($" USER_ID={_userId} MODE=AUTO CLIENT_DATE={now} COMMENT=[]");
        sb.Append($" MODEL_INFO={_mesModelInfo}");

        return sb.ToString();
    }

    private string BuildEdtiMessage(SystemInfo sysInfo, string now)
    {
        string oldDate = now;

        // Parse host date and set system time (Delphi: SetDateTime)
        if (_hostDate.Length >= 14)
        {
            try
            {
                // Delphi sets the local system time from the host date.
                // In C# we log it but do NOT change system time (requires admin privileges).
                _logger.Info($"[HOST] EDTI: Host date = {_hostDate}, local date = {now}");
            }
            catch (Exception ex)
            {
                _logger.Error("Exception in EDTI date handling", ex);
            }
        }

        return $"EDTI ADDR={_localSubject},{_localSubject}" +
               $" EQP={_systemNo}" +
               $" USER_ID={_userId}" +
               $" OLD_DATE={oldDate}" +
               $" NEW_DATE={DateTime.Now:yyyyMMddHHmmss}" +
               $" MODE=AUTO CLIENT_DATE={DateTime.Now:yyyyMMddHHmmss}";
    }

    private string BuildFldrMessage(string serialNo, string now)
    {
        string fldrFile, fldrType = "DEFECT", downTime;

        switch (serialNo)
        {
            case "COMBI":
                fldrFile = _combiDownFile; downTime = _combiDownDate; break;
            case "DEFECT":
                fldrFile = _defectDownFile; downTime = _defectDownDate; break;
            case "FULL_DEFECT":
                fldrFile = _fullDefectDownFile; downTime = _fullDefectDownDate; break;
            case "REPAIR":
                fldrFile = _repairDownFile; downTime = _repairDownDate; break;
            default:
                fldrFile = _fullRepairDownFile; downTime = _fullRepairDownDate; break;
        }

        return $"FLDR ADDR={_localSubject},{_localSubject}" +
               $" EQP={_systemNo}" +
               $" FILE_NAME=[{fldrFile}]" +
               $" FILE_TYPE={fldrType}" +
               $" USER_ID={_userId}" +
               $" MODE=AUTO DOWNLOAD_TIME={downTime}" +
               $" CLIENT_DATE={now} COMMENT=[]";
    }

    private string BuildEicrMessage(string serialNo, string zigId, int pg,
                                     SystemInfo sysInfo, string now)
    {
        var sb = new StringBuilder("EICR");
        sb.Append($" ADDR={_localSubject},{_localSubject}");
        sb.Append($" EQP={_systemNo}");
        sb.Append($" INSPCHANEL_A={pg}");

        if (sysInfo.OCType == ChannelConstants.OcType)
        {
            sb.Append(" PID=");
            if (serialNo.Contains("TEST_CH"))
                sb.Append($" ZIG_ID={zigId}");
            else
                sb.Append($" SERIAL_NO={serialNo}");
        }
        else
        {
            sb.Append($" PID= PCB_ID={serialNo}");
        }

        sb.Append(" CGID= BLID=[] JIG_ID=[]");
        sb.Append($" LOT={MesData[pg].LotNo}");

        // PF logic
        string gdDefectCode = string.Empty;
        if (sysInfo.OCType == ChannelConstants.PreOcType)
        {
            if (MesData[pg].Option == 1)
            {
                MesData[pg].Pf = string.IsNullOrEmpty(MesData[pg].Rwk) ? "P" : "F";
            }
            else
            {
                gdDefectCode = MesData[pg].Rwk;
                MesData[pg].GDDefectCode = gdDefectCode;
                MesData[pg].Rwk = string.Empty;
                MesData[pg].Pf = "P";
            }
        }
        else
        {
            if (string.IsNullOrWhiteSpace(MesData[pg].Pf))
                MesData[pg].Pf = string.IsNullOrEmpty(MesData[pg].Rwk) ? "P" : "F";
        }

        sb.Append($" PF={MesData[pg].Pf}");
        sb.Append($" RWK_CD={MesData[pg].Rwk}");
        sb.Append(" PPALLET= EXPECTED_RWK= PATTERN_INFO=[] DEFECT_PATTERN= OVERHAUL_FLAG=");
        sb.Append($" MODE=AUTO CLIENT_DATE={now}");
        sb.Append($" TACT={MesData[pg].Tact}");
        sb.Append($" USER_ID={_userId}");
        sb.Append($" GD_DEFECT_CODE={gdDefectCode}");
        sb.Append(" COMMENT=[]");

        return sb.ToString();
    }

    private string BuildEijrMessage(string serialNo, int pg,
                                     SystemInfo sysInfo, PLCInfo plcInfo, string now)
    {
        var sb = new StringBuilder("EIJR");
        sb.Append($" ADDR={_localSubject},{_localSubject}");

        AppendEqpForInlineGib(sb, pg, sysInfo, plcInfo);
        sb.Append($" INSPCHANEL_A={pg}");

        if (sysInfo.OCType == ChannelConstants.OcType)
            sb.Append($" SERIAL_NO={serialNo}");
        else
            sb.Append($" PID= PCB_ID={serialNo}");

        sb.Append(" LCM_ID= FOG_ID= BLID=[]");

        if (string.IsNullOrEmpty(MesData[pg].Rwk))
            sb.Append(" SUBJUDGE_INFO=[TOUCH:P]");
        else
            sb.Append($" SUBJUDGE_INFO=[TOUCH:F:{MesData[pg].Rwk}]");

        if (string.IsNullOrWhiteSpace(MesData[pg].Pf))
            MesData[pg].Pf = string.IsNullOrEmpty(MesData[pg].Rwk) ? "P" : "F";

        sb.Append($" PF={MesData[pg].Pf}");
        sb.Append(" PPALLET= EDID=N OVERHAUL_FLAG=");
        sb.Append($" MODE=AUTO CLIENT_DATE={now}");
        sb.Append($" TACT={MesData[pg].Tact}");
        sb.Append($" USER_ID={_userId} COMMENT=[]");

        return sb.ToString();
    }

    private string BuildRprEijrMessage(string serialNo, int pg,
                                        SystemInfo sysInfo, PLCInfo plcInfo, string now)
    {
        var sb = new StringBuilder("RPR_EIJR");
        sb.Append($" ADDR={_localSubject},{_localSubject}");

        AppendEqpForInlineGib(sb, pg, sysInfo, plcInfo);
        sb.Append($" INSPCHANEL_A={pg}");

        if (sysInfo.OCType == ChannelConstants.OcType)
            sb.Append($" SERIAL_NO={serialNo}");
        else
            sb.Append($" PID= PCB_ID={serialNo}");

        sb.Append(" FOG_ID= LCM_ID= CGID= ZIG_ID=");

        if (string.IsNullOrWhiteSpace(MesData[pg].Pf))
            MesData[pg].Pf = string.IsNullOrEmpty(MesData[pg].Rwk) ? "P" : "F";

        sb.Append($" PF={MesData[pg].Pf}");
        sb.Append($" RWK_CD={MesData[pg].Rwk}");

        if (sysInfo.OCType == ChannelConstants.OcType)
        {
            sb.Append(string.IsNullOrEmpty(MesData[pg].Rwk)
                ? " SUBJUDGE_INFO=[GB:P:]"
                : $" SUBJUDGE_INFO=[GB:F:{MesData[pg].Rwk}]");
        }
        else
        {
            sb.Append(string.IsNullOrEmpty(MesData[pg].Rwk)
                ? " SUBJUDGE_INFO=[PREOC:P:]"
                : $" SUBJUDGE_INFO=[PREOC:F:{MesData[pg].Rwk}]");
        }

        sb.Append($" USER_ID={_userId} MODE=AUTO CLIENT_DATE={now}");
        sb.Append(" DEFECT_COMMENT_CODE= COMMENT=[]");

        return sb.ToString();
    }

    private string BuildApdrMessage(string serialNo, int pg, SystemInfo sysInfo, string now)
    {
        var sb = new StringBuilder("APDR");
        sb.Append($" ADDR={_localSubject},{_localSubject}");
        sb.Append($" EQP={_systemNo}");
        sb.Append($" INSPCHANEL_A={pg}");

        sb.Append(sysInfo.OCType == ChannelConstants.OcType
            ? $" SERIAL_NO={serialNo}"
            : $" PCB_ID={serialNo}");

        sb.Append($" MODEL={MesData[pg].Model}");
        sb.Append($" APD_INFO=[{MesData[pg].ApdrData}]");
        sb.Append($" USER_ID={_userId} MODE=AUTO CLIENT_DATE={now} COMMENT=[]");

        return sb.ToString();
    }

    private string BuildEasApdrMessage(string serialNo, int pg,
                                        SystemInfo sysInfo, PLCInfo plcInfo, string now)
    {
        var sb = new StringBuilder("APDR");
        sb.Append($" ADDR={_easLocalSubject},{_easLocalSubject}");

        AppendEqpForInlineGib(sb, pg, sysInfo, plcInfo);
        sb.Append($" INSPCHANEL_A={pg}");
        sb.Append($" PATH={pg + 1}");

        sb.Append(sysInfo.OCType == ChannelConstants.OcType
            ? $" SERIAL_NO={serialNo}"
            : $" PCB_ID={serialNo}");

        sb.Append($" USER_ID={_userId} MODE=AUTO CLIENT_DATE={now} COMMENT=[]");
        // NOTE: StartTime/EndTime would come from PasScr[pg].TestInfo - handled at higher level
        sb.Append($" APD_INFO=[{MesData[pg].ApdrData}]");

        return sb.ToString();
    }

    private string BuildR2REodsTestMessage(int pg, string now)
    {
        // Simplified R2R EODS test message (Delphi uses hardcoded test values)
        return $"EODS ADDR={_r2rLocalSubject}" +
               $" EQP={_systemNo}" +
               $" MACHINE=H9AMAL515R" +
               $" UNIT={pg + 1}" +
               " LOT=" +
               " DATAINFO=[::::[[test_data]]]";
    }

    private string BuildR2REodaMessage(int pg)
    {
        return $"EODA ADDR={_r2rLocalSubject},{_r2rRemoteSubject}" +
               $" EQP={_systemNo}" +
               $" MACHINE={_r2rMachine}" +
               $" UNIT={pg + 1}" +
               " RECIPE= LOT=" +
               $" AACK={_r2rAack[pg]}" +
               $" MMC_TXN_ID="; // PasScr[pg].FR2R_MmcTxnID_Data
    }

    // =========================================================================
    // Helper: EQP selection for InlineGIB
    // =========================================================================

    private void AppendEqpForInlineGib(StringBuilder sb, int pg, SystemInfo sysInfo, PLCInfo plcInfo)
    {
        if (plcInfo.InlineGIB)
        {
            _logger.Info(pg, $"LpirProcessCode : {MesData[pg].LpirProcessCode} EQPId_MGIB : {sysInfo.EQPIdMGIB} EQPId_PGIB : {sysInfo.EQPIdPGIB}");

            if (MesData[pg].LpirProcessCode == sysInfo.EQPIdMGIBProcessCode)
                sb.Append($" EQP={sysInfo.EQPIdMGIB}");
            else if (MesData[pg].LpirProcessCode == sysInfo.EQPIdPGIBProcessCode)
                sb.Append($" EQP={sysInfo.EQPIdPGIB}");
            else
                sb.Append($" EQP={_systemNo}");
        }
        else
        {
            sb.Append($" EQP={_systemNo}");
        }
    }

    // =========================================================================
    // Message Queue Timer (replaces Delphi tmGmesChMsg)
    // =========================================================================

    private void EnqueueAndStart(MesQueueItem item)
    {
        _queue.Enqueue(item);
        StartQueueTimer();
    }

    private void StartQueueTimer()
    {
        _queueTimer.Change(500, 500);
    }

    private void StopQueueTimer()
    {
        _queueTimer.Change(Timeout.Infinite, Timeout.Infinite);
    }

    /// <summary>
    /// Queue timer callback - processes MES message queue.
    /// <para>Delphi: procedure TGmes.OnGmesChMsgTimer(Sender)</para>
    /// </summary>
    private void OnQueueTimerElapsed(object? state)
    {
        try
        {
            if (_currentItem != null && _currentItem.State != DefGmes.MesUnknown)
            {
                // Current item still processing - check timeout
                long elapsed = Environment.TickCount64 - _currentItem.Tick;
                if (elapsed > _currentItem.Timeout)
                {
                    // Timeout
                    if (_currentItem.Kind is DefGmes.MesEayt or DefGmes.MesEdti or
                        DefGmes.MesEqcc or DefGmes.MesFldr or DefGmes.MesUchk)
                    {
                        OnGmesEvent?.Invoke(_currentItem.Kind, 0, true, "Timeout");
                    }
                    else
                    {
                        MesData[_currentItem.Channel].MesSentMsg = DefGmes.MesUnknown;
                        ReturnDataToTestForm(_currentItem.Kind, _currentItem.Channel, true, "Timeout");
                    }
                    _currentItem.State = DefGmes.MesUnknown;
                    _currentItem = null;
                }
                else if (_currentItem.State == DefGmes.MesStateFail)
                {
                    // Retry on failure
                    _currentItem.State = _currentItem.Kind;
                    SendMessage(_currentItem.Kind, _currentItem.SerialNo,
                               _currentItem.CarrierId, _currentItem.Channel);
                    return;
                }
            }
            else
            {
                // Dequeue next item
                if (_queue.TryDequeue(out var item))
                {
                    _currentItem = item;

                    if (item.Kind == DefGmes.EasApdr)
                    {
                        _logger.Info(item.Channel, $"OnGmesChMsgTimer Start!! CH {item.Channel} SerialNo : {item.SerialNo}");
                    }

                    // EAS_APDR, R2R_EODS_R, R2R_EODA are fire-and-forget
                    bool isFireAndForget = item.Kind == DefGmes.EasApdr ||
                                           item.Kind == DefGmes.R2rEodsR ||
                                           item.Kind == DefGmes.R2rEoda;

                    if (!isFireAndForget)
                        _currentItem.State = item.Kind;

                    _currentItem.Tick = Environment.TickCount64;

                    // Update MesData from queue item
                    if (item.Channel < MAX_PG_CNT)
                    {
                        if (!string.IsNullOrEmpty(item.Tact))
                            MesData[item.Channel].Tact = item.Tact;
                        if (!string.IsNullOrEmpty(item.MesCode))
                            MesData[item.Channel].Rwk = item.MesCode;
                        if (!string.IsNullOrEmpty(item.ErrCode))
                            MesData[item.Channel].ErrCode = item.ErrCode;
                    }

                    SendMessage(item.Kind, item.SerialNo, item.CarrierId, item.Channel);

                    if (item.Kind == DefGmes.EasApdr)
                    {
                        _logger.Info(item.Channel, $"OnGmesChMsgTimer END CH {item.Channel} SerialNo : {item.SerialNo}");
                        MesData[item.Channel].ApdrData = string.Empty;
                    }
                }
                else
                {
                    StopQueueTimer();
                }
            }
        }
        catch (Exception ex)
        {
            _logger.Error("OnQueueTimerElapsed error", ex);
        }
    }

    /// <summary>
    /// Response timer callback (currently empty, matching Delphi).
    /// <para>Delphi: procedure TGmes.OnGemsResponseTimer(Sender)</para>
    /// </summary>
    private void OnResponseTimerElapsed(object? state)
    {
        // Empty in Delphi
    }

    // =========================================================================
    // Private Helper Methods
    // =========================================================================

    /// <summary>
    /// Parse MES response message into individual fields.
    /// <para>Delphi: procedure TGmes.SeperateData(sMsg, var nChNo)</para>
    /// </summary>
    private void SeperateData(string msg, out int chNo)
    {
        string mode = msg.Length >= 6 ? msg[..6] : msg;
        string subMsg = msg.Length > 6 ? msg[6..].Trim() : string.Empty;
        chNo = -1;
        string chRet = string.Empty;

        int eqPos = subMsg.IndexOf('=');
        int spacePos = subMsg.IndexOf(' ');

        while (eqPos > 0)
        {
            string msgId = subMsg[..eqPos];
            string msgCont;

            if (spacePos > eqPos)
            {
                msgCont = subMsg[(eqPos + 1)..spacePos];
            }
            else if (spacePos < 0)
            {
                msgCont = subMsg[(eqPos + 1)..];
            }
            else
            {
                // Space before equals - value contains spaces
                msgCont = subMsg[(eqPos + 1)..];
            }

            // Advance past the current key=value pair
            int consumed = msgId.Length + 1 + msgCont.Length;
            subMsg = consumed < subMsg.Length ? subMsg[consumed..].TrimStart() : string.Empty;

            // Handle multi-word values (space before next '=')
            eqPos = subMsg.IndexOf('=');
            spacePos = subMsg.IndexOf(' ');

            while (eqPos > spacePos && spacePos >= 0)
            {
                string next = spacePos >= 0 ? subMsg[..spacePos] : subMsg;
                msgCont = msgCont + " " + next;
                subMsg = spacePos >= 0 && spacePos + 1 < subMsg.Length
                    ? subMsg[(spacePos + 1)..]
                    : string.Empty;
                eqPos = subMsg.IndexOf('=');
                spacePos = subMsg.IndexOf(' ');
            }

            // Map parsed fields
            string key = msgId.Trim().ToUpperInvariant();
            string val = msgCont.Trim();

            switch (key)
            {
                case "RTN_CD": _mesRtnCd = val; break;
                case "PID": _mesPid = val; break;
                case "RTN_PID": _mesRtnPid = val; break;
                case "RTN_SERIAL_NO": _mesSerialNo = val; break;
                case "LABEL_ID": _mesLabelId = val; break;
                case "PF": _mesPf = val; break;
                case "USER_NAME": _mesUserName = val; break;
                case "RTN_LOT": LotNo = val; break;
                case "HOST_DATE": _hostDate = val; break;
                case "ERR_MSG_LOC": _mesErrMsgLc = val; break;
                case "ERR_MSG_ENG": _mesErrMsgEn = val; break;
                case "MODEL": _mesModel = val; break;
                case "INSPCHANEL_A": chRet = val; break;
                case "FOG_ID": _mesFogId = val; break;
                case "MACHINE": _r2rMachine = val; break;
                case "SERIAL_NO": _mesFogId = val; break;
                case "UNIT": _r2rUnit = val; break;
                case "MMC_TXN_ID": _r2rMmcTxnId = val; break;
                case "DATAINFO": _r2rDataInfo = val; break;
                case "PROCESS_CODE": _mesProsessCode = val; break;
                case "JIG_ID": _mesZigId = val; break;
                case "LATEST_INSP_INFO": _mesLatestInsp = val; break;
            }

            if (string.IsNullOrEmpty(subMsg)) break;
            eqPos = subMsg.IndexOf('=');
            spacePos = subMsg.IndexOf(' ');
        }

        if (!string.IsNullOrEmpty(chRet) && int.TryParse(chRet, out int parsedCh))
        {
            chNo = parsedCh;
        }

        // Extract ERR_MSG_ENG with brackets handling
        int engPos = msg.IndexOf("ERR_MSG_ENG", StringComparison.Ordinal);
        if (engPos >= 0)
        {
            string engSub = msg[(engPos + "ERR_MSG_ENG".Length + 1)..];
            int bracketEnd = engSub.IndexOf(']');
            if (bracketEnd > 0)
                _mesErrMsgEn = engSub[1..bracketEnd]; // Skip leading '['
        }
        else
        {
            _mesErrMsgEn = string.Empty;
        }

        // Clean brackets from error messages and R2R data
        _mesErrMsgEn = _mesErrMsgEn.Replace("[", "").Replace("]", "");
        _mesErrMsgLc = _mesErrMsgLc.Replace("[", "").Replace("]", "");
        _r2rDataInfo = _r2rDataInfo.Replace("[", "").Replace("]", "");
    }

    /// <summary>
    /// Parse R2R EODS data (OC values) from the DATAINFO field.
    /// <para>Delphi: procedure TGmes.SeperateR2RData(nCH, sMsg)</para>
    /// </summary>
    private void SeperateR2RData(int ch, string msg)
    {
        var dict = ExtractOCValues(msg);
        // NOTE: R2R data storage (PasScr[ch].FR2ROC_*) is in the script layer.
        // This method parses the data; the caller is responsible for storing it.
        _logger.Info(ch, $"R2R data parsed: {dict.Count} OC/MPO values");
    }

    /// <summary>
    /// Extract OC/MPO key-value pairs from a '^'-delimited string.
    /// <para>Delphi: function TGmes.ExtractOCValues(AInput): TDictionary</para>
    /// </summary>
    private static Dictionary<string, string> ExtractOCValues(string input)
    {
        var result = new Dictionary<string, string>();
        var keyValues = input.Split('^');

        foreach (string kv in keyValues)
        {
            int hashPos = kv.IndexOf('#');
            if (hashPos < 0) continue;

            if (kv.Contains("OC_") || kv.Contains("MPO_"))
            {
                string prefix = kv.Contains("OC_") ? "OC_" : "MPO_";
                int prefixPos = kv.IndexOf(prefix, StringComparison.Ordinal);
                string key = kv[prefixPos..hashPos];
                string value = hashPos + 1 < kv.Length ? kv[(hashPos + 1)..] : string.Empty;
                // Remove trailing characters if any
                if (value.EndsWith("]"))
                    value = value[..^1];
                result[key] = value;
            }
        }

        return result;
    }

    /// <summary>
    /// Convert serial number for HOST communication ($ -> LF, % -> CR).
    /// Delphi: StringReplace(sSerialNo, #$24, #$0a, [rfReplaceAll])
    /// </summary>
    private static string ConvertSerialForHost(string serial)
    {
        return serial.Replace("$", "\n").Replace("%", "\r");
    }

    /// <summary>
    /// Convert serial number from HOST response (LF -> $, CR -> %).
    /// Delphi: StringReplace(FMesFogId, #$0a, #$24, [rfReplaceAll])
    /// </summary>
    private static string ConvertSerialFromHost(string serial)
    {
        return serial.Replace("\n", "$").Replace("\r", "%");
    }

    /// <summary>
    /// Resolve PG number from channel hint or serial number lookup.
    /// </summary>
    private int ResolvePgNo(int ch, string serialNo)
    {
        if (ch >= CH1 && ch <= MAX_CH)
            return ch;

        int pgNo = _mesPg;
        for (int i = CH1; i <= MAX_CH; i++)
        {
            if (serialNo == _pgSerial[i])
            {
                pgNo = i;
                break;
            }
        }

        return pgNo;
    }

    /// <summary>
    /// Resolve PG number from serial number lookup only.
    /// </summary>
    private int ResolvePgNoBySerial(string serialNo)
    {
        int pgNo = _mesPg;
        for (int i = CH1; i <= MAX_CH; i++)
        {
            if (serialNo == _pgSerial[i])
            {
                pgNo = i;
                break;
            }
        }

        return pgNo;
    }

    private static bool IsValidChannel(int ch) => ch >= CH1 && ch <= MAX_CH;

    /// <summary>
    /// Publish a MES result message to the message bus (replaces WM_COPYDATA / SendMessage).
    /// <para>Delphi: procedure TGmes.ReturnDataToTestForm(nMode, nPg, bError, sMsg)</para>
    /// </summary>
    private void ReturnDataToTestForm(int mode, int pg, bool isError, string msg)
    {
        var message = new GmesMesMessage
        {
            Channel = pg,
            Mode = mode,
            Param = MsgType.Host,
            IsError = isError,
            Message = msg
        };

        _messageBus.Publish(message);
    }
}
