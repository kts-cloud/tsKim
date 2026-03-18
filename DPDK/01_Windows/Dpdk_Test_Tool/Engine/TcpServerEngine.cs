using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace DpdkTestTool.Engine
{
    public enum TcpServerMode { Echo, ReceiveOnly }

    public class TcpClientInfo
    {
        public string EndPoint { get; set; } = "";
        public DateTime ConnectedAt { get; set; } = DateTime.Now;
        public long BytesReceived { get; set; }
        public long BytesSent { get; set; }
        public bool IsConnected { get; set; } = true;
    }

    public class TcpServerEngine
    {
        private TcpListener? _listener;
        private CancellationTokenSource? _cts;
        public TcpServerMode Mode { get; set; } = TcpServerMode.Echo;
        public int Port { get; set; } = 7000;

        public ConcurrentDictionary<string, TcpClientInfo> Clients { get; } = new();
        public ConcurrentQueue<string> LogQueue { get; } = new();

        public long TotalBytesReceived { get; private set; }
        public long TotalBytesSent { get; private set; }
        public int MaxLogQueueSize { get; set; } = 5000;

        public async Task StartAsync()
        {
            _cts = new CancellationTokenSource();
            _listener = new TcpListener(IPAddress.Any, Port);
            _listener.Start();
            EnqueueLog($"[서버] 포트 {Port}에서 수신 대기 시작 (모드: {Mode})");

            try
            {
                while (!_cts.Token.IsCancellationRequested)
                {
                    var client = await _listener.AcceptTcpClientAsync(_cts.Token);
                    _ = HandleClientAsync(client, _cts.Token);
                }
            }
            catch (OperationCanceledException) { }
            catch (Exception ex)
            {
                EnqueueLog($"[서버] 오류: {ex.Message}");
            }
        }

        public void Stop()
        {
            _cts?.Cancel();
            _listener?.Stop();
            _listener = null;
            EnqueueLog("[서버] 중지됨");
        }

        private async Task HandleClientAsync(TcpClient client, CancellationToken token)
        {
            string ep = client.Client.RemoteEndPoint?.ToString() ?? "unknown";
            var info = new TcpClientInfo { EndPoint = ep };
            Clients[ep] = info;
            EnqueueLog($"[연결] {ep} 접속");

            try
            {
                using var stream = client.GetStream();
                byte[] buffer = new byte[4096];

                while (!token.IsCancellationRequested && client.Connected)
                {
                    int bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length, token);
                    if (bytesRead == 0) break;

                    info.BytesReceived += bytesRead;
                    TotalBytesReceived += bytesRead;

                    string msg = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                    EnqueueLog($"[수신] {ep}: {msg.TrimEnd()}");

                    if (Mode == TcpServerMode.Echo)
                    {
                        await stream.WriteAsync(buffer, 0, bytesRead, token);
                        info.BytesSent += bytesRead;
                        TotalBytesSent += bytesRead;
                        EnqueueLog($"[에코] {ep}: {msg.TrimEnd()}");
                    }
                }
            }
            catch (OperationCanceledException) { }
            catch (Exception ex)
            {
                EnqueueLog($"[오류] {ep}: {ex.Message}");
            }
            finally
            {
                client.Close();
                info.IsConnected = false;
                EnqueueLog($"[연결해제] {ep}");
            }
        }

        private void EnqueueLog(string message)
        {
            string line = $"[{DateTime.Now:HH:mm:ss.fff}] {message}";
            if (LogQueue.Count < MaxLogQueueSize)
                LogQueue.Enqueue(line);
        }
    }
}
