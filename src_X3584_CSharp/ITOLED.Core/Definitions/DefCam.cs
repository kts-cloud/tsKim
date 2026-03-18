// ---------------------------------------------------------------------------
// DefCam.cs
// Converted from Delphi: DefCam.pas
// Camera TCP communication constants: IP addresses, ports, channels,
// buffer sizes, return codes, and connection status values.
// ---------------------------------------------------------------------------

namespace Dongaeltek.ITOLED.Core.Definitions;

/// <summary>
/// Camera definition constants for TCP server/client IP configuration,
/// port assignments, channel counts, buffer sizes, return codes,
/// and connection status values.
/// <para>Delphi source: DefCam.pas</para>
/// </summary>
public static class DefCam
{
    #region TCP Server/Client IP Configuration

    /// <summary>Base TCP server IP address. Delphi: BASE_TCP_SERVER_IP</summary>
    public const string BaseTcpServerIp = "192.168.0.11";

    /// <summary>Base TCP client IP prefix (channel index appended). Delphi: BASE_TCP_CLINT_IP</summary>
    public const string BaseTcpClientIp = "192.168.0.";

    /// <summary>Base TCP client index suffix. Delphi: BASE_TCP_CLINT_INDEX</summary>
    public const int BaseTcpClientIndex = 31;

    #endregion

    #region TCP Port Configuration

    /// <summary>G Server port. Delphi: BASE_SERVER_PORT</summary>
    public const int BaseServerPort = 2291;

    /// <summary>D Server port. Delphi: BASE_CLINT_PORT</summary>
    public const int BaseClientPort = 1961;

    #endregion

    #region Camera Channels

    /// <summary>First camera channel index (0-based). Delphi: CAM_CH1</summary>
    public const int CamCh1 = 0;

    /// <summary>Maximum camera channel count. Delphi: MAX_CAM_CH</summary>
    public const int MaxCamCh = 3;

    #endregion

    #region TCP Channels and Buffer

    /// <summary>Maximum TCP channel count. Delphi: MAX_TCP_CH</summary>
    public const int MaxTcpCh = 4;

    /// <summary>TCP receive buffer size in bytes. Delphi: TCP_BUFF_SIZE</summary>
    public const int TcpBuffSize = 700000;

    #endregion

    #region Receive Event Return Codes (RET_*)

    /// <summary>No return / none. Delphi: RET_NONE</summary>
    public const int RetNone = 1;

    /// <summary>Acknowledgement received. Delphi: RET_ACK</summary>
    public const int RetAck = 2;

    /// <summary>Negative acknowledgement received. Delphi: RET_NAK</summary>
    public const int RetNak = 3;

    #endregion

    #region Camera Connection Status (CAM_CONNECT_*)

    /// <summary>First successful connection. Delphi: CAM_CONNECT_FIRST_OK</summary>
    public const int CamConnectFirstOk = 0;

    /// <summary>Connection OK (reconnection). Delphi: CAM_CONNECT_OK</summary>
    public const int CamConnectOk = 1;

    /// <summary>Connection failed. Delphi: CAM_CONNECT_NG</summary>
    public const int CamConnectNg = 2;

    #endregion
}
