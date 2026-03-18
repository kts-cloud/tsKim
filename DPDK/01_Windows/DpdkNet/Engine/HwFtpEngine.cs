using System.Collections.Concurrent;
using System.Text;
using HwNet.Config;
using HwNet.Interop;
using HwNet.Models;
using HwNet.Utilities;

namespace HwNet.Engine
{
    public class HwFtpEngine : IHwEngine
    {
        private readonly IHwContext _dpdk;
        private readonly int _sessionId;
        private volatile bool _running;
        private bool _lwipInitialized;

        public bool IsRunning => _running;
        public string? LastError { get; set; }

        public ConcurrentQueue<FtpEvent> EventQueue { get; } = new();
        public ConcurrentQueue<string> LogQueue { get; } = new();

        public HwFtpEngine(IHwContext dpdk, int sessionId = 0)
        {
            _dpdk = dpdk;
            _sessionId = sessionId;
        }

        public bool InitLwip(FtpConfig config)
        {
            if (_lwipInitialized) return true;
            if (_dpdk.State != HwState.Ready)
            {
                LastError = "DPDK가 Ready 상태가 아닙니다.";
                EnqueueEvent(FtpEventType.Error, LastError);
                return false;
            }

            uint ip = IpToUint(config.LocalIp);
            uint mask = IpToUint(config.Netmask);
            uint gw = IpToUint(config.Gateway);

            LogQueue.Enqueue($"[lwIP] 초기화 중... IP={config.LocalIp} Mask={config.Netmask} GW={config.Gateway}");

            int ret = LwipHwInterop.hw_lwip_init_ref(
                _dpdk.PortId, _dpdk.MbufPool,
                ip, mask, gw, _dpdk.LocalMac);

            if (ret != 0)
            {
                LastError = $"lwIP 초기화 실패 (ret={ret})";
                EnqueueEvent(FtpEventType.Error, LastError);
                return false;
            }

            _lwipInitialized = true;
            LogQueue.Enqueue("[lwIP] 초기화 완료");
            EnqueueEvent(FtpEventType.Info, "lwIP 스택 초기화 완료");
            return true;
        }

        public Task<bool> ConnectAsync(string host, ushort port, string user, string pass, int timeoutMs)
        {
            return Task.Run(() =>
            {
                _running = true;
                LogQueue.Enqueue($"[FTP] 연결 중... {host}:{port} (user={user})");

                int ret = LwipHwInterop.hw_ftp_connect_sync_ex(_sessionId, host, port, user, pass, timeoutMs);

                if (ret == 0)
                {
                    LogQueue.Enqueue("[FTP] 연결 및 로그인 성공");
                    EnqueueEvent(FtpEventType.Connected, $"{host}:{port} 연결됨");
                    EnqueueEvent(FtpEventType.LoginOk, $"사용자 '{user}' 로그인 성공");
                    return true;
                }
                else
                {
                    string msg = $"FTP 연결 실패 (ret={ret})";
                    LastError = msg;
                    LogQueue.Enqueue($"[FTP] {msg}");
                    EnqueueEvent(FtpEventType.LoginFailed, msg);
                    return false;
                }
            });
        }

        public Task DisconnectAsync()
        {
            return Task.Run(() =>
            {
                LogQueue.Enqueue("[FTP] 연결 해제 중...");
                int ret = LwipHwInterop.hw_ftp_disconnect_ex(_sessionId);
                _running = false;

                if (ret == 0)
                {
                    LogQueue.Enqueue("[FTP] 연결 해제 완료");
                    EnqueueEvent(FtpEventType.Disconnected, "FTP 연결 해제됨");
                }
                else
                {
                    string msg = $"FTP 연결 해제 실패 (ret={ret})";
                    LogQueue.Enqueue($"[FTP] {msg}");
                    EnqueueEvent(FtpEventType.Error, msg);
                }
            });
        }

        public Task<string?> PwdAsync()
        {
            return Task.Run(() =>
            {
                byte[] buf = new byte[512];
                int ret = LwipHwInterop.hw_ftp_pwd(buf, buf.Length);
                if (ret >= 0)
                {
                    string path = Encoding.UTF8.GetString(buf, 0, ret).TrimEnd('\0');
                    LogQueue.Enqueue($"[FTP] PWD: {path}");
                    return (string?)path;
                }
                else
                {
                    string msg = $"PWD 실패 (ret={ret})";
                    LogQueue.Enqueue($"[FTP] {msg}");
                    EnqueueEvent(FtpEventType.Error, msg);
                    return null;
                }
            });
        }

        public Task<bool> CwdAsync(string path)
        {
            return Task.Run(() =>
            {
                LogQueue.Enqueue($"[FTP] CWD: {path}");
                int ret = LwipHwInterop.hw_ftp_cwd(path);
                if (ret == 0)
                {
                    LogQueue.Enqueue($"[FTP] 디렉토리 변경 완료: {path}");
                    return true;
                }
                else
                {
                    string msg = $"CWD 실패 (ret={ret})";
                    LogQueue.Enqueue($"[FTP] {msg}");
                    EnqueueEvent(FtpEventType.Error, msg);
                    return false;
                }
            });
        }

        public Task<string?> ListAsync(int timeoutMs)
        {
            return Task.Run(() =>
            {
                byte[] buf = new byte[65536];
                int outLen = 0;

                LogQueue.Enqueue("[FTP] LIST 요청 중...");
                int ret = LwipHwInterop.hw_ftp_list_sync(buf, buf.Length, ref outLen, timeoutMs);

                if (ret == 0)
                {
                    string listing = outLen > 0
                        ? Encoding.UTF8.GetString(buf, 0, outLen).TrimEnd('\0')
                        : "";
                    LogQueue.Enqueue($"[FTP] LIST 완료 ({outLen} bytes)");
                    EnqueueEvent(FtpEventType.Listed, $"목록 수신 완료 ({outLen} bytes)");
                    return (string?)listing;
                }
                else
                {
                    string msg = $"LIST 실패 (ret={ret}, len={outLen})";
                    LogQueue.Enqueue($"[FTP] {msg}");
                    EnqueueEvent(FtpEventType.Error, msg);
                    return null;
                }
            });
        }

        public Task<byte[]?> DownloadAsync(string remotePath, int timeoutMs)
        {
            return Task.Run(() =>
            {
                byte[] buf = new byte[64 * 1024 * 1024]; // 64 MB buffer
                int outLen = 0;

                LogQueue.Enqueue($"[FTP] 다운로드 중: {remotePath}");
                int ret = LwipHwInterop.hw_ftp_download_sync_ex(_sessionId, remotePath, buf, buf.Length, ref outLen, timeoutMs);

                if (ret == 0 && outLen > 0)
                {
                    byte[] result = new byte[outLen];
                    Array.Copy(buf, result, outLen);
                    LogQueue.Enqueue($"[FTP] 다운로드 완료: {remotePath} ({outLen} bytes)");
                    EnqueueEvent(FtpEventType.Downloaded, $"{remotePath} 다운로드 완료 ({outLen} bytes)");
                    return (byte[]?)result;
                }
                else
                {
                    string msg = $"다운로드 실패: {remotePath} (ret={ret})";
                    LastError = msg;
                    LogQueue.Enqueue($"[FTP] {msg}");
                    EnqueueEvent(FtpEventType.Error, msg);
                    return null;
                }
            });
        }

        public Task<bool> UploadAsync(string remotePath, byte[] data, int timeoutMs)
        {
            return Task.Run(() =>
            {
                LogQueue.Enqueue($"[FTP] 업로드 중: {remotePath} ({data.Length} bytes)");
                int ret = LwipHwInterop.hw_ftp_upload_sync_ex(_sessionId, remotePath, data, data.Length, timeoutMs);

                if (ret == 0)
                {
                    LogQueue.Enqueue($"[FTP] 업로드 완료: {remotePath}");
                    EnqueueEvent(FtpEventType.Uploaded, $"{remotePath} 업로드 완료 ({data.Length} bytes)");
                    return true;
                }
                else
                {
                    string msg = $"업로드 실패: {remotePath} (ret={ret})";
                    LastError = msg;
                    LogQueue.Enqueue($"[FTP] {msg}");
                    EnqueueEvent(FtpEventType.Error, msg);
                    return false;
                }
            });
        }

        public int GetFtpState()
        {
            return LwipHwInterop.hw_ftp_get_state_ex(_sessionId);
        }

        /// <summary>
        /// FTP 재연결: disconnect → lwIP 재초기화 → 재연결
        /// </summary>
        public async Task<bool> ReconnectAsync(FtpConfig config)
        {
            LogQueue.Enqueue("[FTP] 재연결 시도 중...");

            // 1. 기존 연결 정리
            try { LwipHwInterop.hw_ftp_disconnect_ex(_sessionId); } catch { }
            try { LwipHwInterop.hw_lwip_stop_ref(); } catch { }
            _lwipInitialized = false;

            // 2. lwIP 재초기화
            if (!InitLwip(config))
            {
                LogQueue.Enqueue("[FTP] 재연결 실패: lwIP 초기화 오류");
                return false;
            }

            // 3. FTP 재연결
            bool ok = await ConnectAsync(config.ServerIp, config.ServerPort,
                config.Username, config.Password, config.TimeoutMs);

            if (ok)
                LogQueue.Enqueue("[FTP] 재연결 성공");
            else
                LogQueue.Enqueue("[FTP] 재연결 실패");

            return ok;
        }

        public void StopLwip()
        {
            LogQueue.Enqueue("[lwIP] 스택 정지 중...");
            _running = false;

            try { LwipHwInterop.hw_ftp_disconnect_ex(_sessionId); } catch { }
            try { LwipHwInterop.hw_lwip_stop_ref(); } catch { }

            _lwipInitialized = false;
            LogQueue.Enqueue("[lwIP] 스택 정지 완료");
            EnqueueEvent(FtpEventType.Info, "lwIP 스택 정지 완료");
        }

        public void Stop()
        {
            _running = false;
        }

        public void Dispose()
        {
            if (_lwipInitialized)
                StopLwip();
            GC.SuppressFinalize(this);
        }

        private void EnqueueEvent(FtpEventType type, string message)
        {
            EventQueue.Enqueue(new FtpEvent
            {
                Type = type,
                Message = message,
                Timestamp = DateTime.Now
            });
        }

        /// <summary>
        /// IP 문자열을 네트워크 바이트 오더 uint32로 변환합니다.
        /// 예: "192.168.0.1" → 0x0100A8C0 (little-endian 시스템에서)
        /// </summary>
        public static uint IpToUint(string ip)
        {
            string[] parts = ip.Split('.');
            if (parts.Length != 4)
                throw new ArgumentException($"잘못된 IP 주소 형식: {ip}");

            return (uint)(
                byte.Parse(parts[0]) |
                (byte.Parse(parts[1]) << 8) |
                (byte.Parse(parts[2]) << 16) |
                (byte.Parse(parts[3]) << 24));
        }
    }
}
