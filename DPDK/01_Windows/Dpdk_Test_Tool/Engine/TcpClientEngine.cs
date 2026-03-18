using System.Collections.Concurrent;
using System.Diagnostics;
using System.Net.Sockets;
using System.Text;

namespace DpdkTestTool.Engine
{
    public class TcpClientEngine
    {
        private TcpClient? _client;
        private NetworkStream? _stream;
        private CancellationTokenSource? _cts;

        public string ServerIp { get; set; } = "127.0.0.1";
        public int ServerPort { get; set; } = 7000;
        public bool IsConnected => _client?.Connected == true;

        public double ConnectTimeMs { get; private set; }
        public double LastRttMs { get; private set; }
        public long TotalBytesSent { get; private set; }
        public long TotalBytesReceived { get; private set; }

        public ConcurrentQueue<string> LogQueue { get; } = new();
        public int MaxLogQueueSize { get; set; } = 5000;

        public async Task<bool> ConnectAsync()
        {
            try
            {
                _cts = new CancellationTokenSource();
                _client = new TcpClient();

                var sw = Stopwatch.StartNew();
                await _client.ConnectAsync(ServerIp, ServerPort);
                sw.Stop();
                ConnectTimeMs = sw.Elapsed.TotalMilliseconds;

                _stream = _client.GetStream();
                EnqueueLog($"[연결] {ServerIp}:{ServerPort} (연결시간: {ConnectTimeMs:F2}ms)");

                // Start receive loop
                _ = ReceiveLoopAsync(_cts.Token);
                return true;
            }
            catch (Exception ex)
            {
                EnqueueLog($"[오류] 연결 실패: {ex.Message}");
                return false;
            }
        }

        public void Disconnect()
        {
            _cts?.Cancel();
            _stream?.Close();
            _client?.Close();
            _client = null;
            _stream = null;
            EnqueueLog("[연결해제]");
        }

        public async Task<bool> SendAsync(string message)
        {
            if (_stream == null || !IsConnected) return false;

            try
            {
                byte[] data = Encoding.UTF8.GetBytes(message);
                var sw = Stopwatch.StartNew();
                await _stream.WriteAsync(data, 0, data.Length);
                sw.Stop();

                TotalBytesSent += data.Length;
                LastRttMs = sw.Elapsed.TotalMilliseconds;
                EnqueueLog($"[송신] {message.TrimEnd()} ({data.Length}B, {LastRttMs:F2}ms)");
                return true;
            }
            catch (Exception ex)
            {
                EnqueueLog($"[오류] 송신 실패: {ex.Message}");
                return false;
            }
        }

        private async Task ReceiveLoopAsync(CancellationToken token)
        {
            byte[] buffer = new byte[4096];
            try
            {
                while (!token.IsCancellationRequested && _stream != null)
                {
                    int bytesRead = await _stream.ReadAsync(buffer, 0, buffer.Length, token);
                    if (bytesRead == 0) break;

                    TotalBytesReceived += bytesRead;
                    string msg = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                    EnqueueLog($"[수신] {msg.TrimEnd()} ({bytesRead}B)");
                }
            }
            catch (OperationCanceledException) { }
            catch (Exception ex)
            {
                if (!token.IsCancellationRequested)
                    EnqueueLog($"[오류] 수신: {ex.Message}");
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
