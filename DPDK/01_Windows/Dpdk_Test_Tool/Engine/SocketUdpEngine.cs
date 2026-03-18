using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Text;
using HwNet.Logging;
using HwNet.Models;
using HwNet.Stats;
using HwNet.Utilities;

namespace DpdkTestTool.Engine
{
    public class SocketUdpTxEngine
    {
        private Thread? _txThread;
        private volatile bool _running;
        private readonly PerformanceCounter _perfCounter;

        public string DstIp { get; set; } = "192.168.0.1";
        public ushort DstPort { get; set; } = 5000;
        public ushort SrcPort { get; set; } = 4000;
        public int PayloadSize { get; set; } = 64;
        public int TargetPps { get; set; } = 0;
        public string? PayloadText { get; set; }
        public string? LastError { get; set; }
        public PacketLogger? Logger { get; set; }

        public ConcurrentQueue<RxPacketInfo> ResponseQueue { get; } = new();

        public SocketUdpTxEngine(PerformanceCounter perfCounter)
        {
            _perfCounter = perfCounter;
        }

        public void Start()
        {
            if (_running) return;
            _running = true;
            _txThread = new Thread(TxLoop) { IsBackground = true, Name = "Socket-UDP-TX", Priority = ThreadPriority.Highest };
            _txThread.Start();
        }

        public void Stop()
        {
            _running = false;
            _txThread?.Join(2000);
            _txThread = null;
        }

        private void TxLoop()
        {
            try
            {
                using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
                socket.Bind(new IPEndPoint(IPAddress.Any, SrcPort));
                socket.ReceiveTimeout = 1;
                socket.SendBufferSize = 1024 * 1024;
                socket.ReceiveBufferSize = 1024 * 1024;

                var dstEp = new IPEndPoint(IPAddress.Parse(DstIp), DstPort);
                uint dstIpNum = NetUtils.IpToUint(DstIp);

                // Build payload
                byte[] payload;
                if (!string.IsNullOrEmpty(PayloadText))
                {
                    byte[] textBytes = Encoding.ASCII.GetBytes(PayloadText);
                    payload = new byte[Math.Max(PayloadSize, textBytes.Length)];
                    Buffer.BlockCopy(textBytes, 0, payload, 0, textBytes.Length);
                }
                else
                {
                    payload = new byte[PayloadSize];
                    for (int i = 0; i < payload.Length; i++)
                        payload[i] = (byte)(i & 0xFF);
                }

                // Rate limiting
                bool rateLimit = TargetPps > 0;
                long ticksPerPacket = rateLimit
                    ? System.Diagnostics.Stopwatch.Frequency / TargetPps
                    : 0;
                long nextSendTick = System.Diagnostics.Stopwatch.GetTimestamp();

                byte[] rxBuf = new byte[2048];
                EndPoint remoteEp = new IPEndPoint(IPAddress.Any, 0);

                while (_running)
                {
                    // Rate limiting
                    if (rateLimit)
                    {
                        long now = System.Diagnostics.Stopwatch.GetTimestamp();
                        if (now < nextSendTick)
                        {
                            Thread.SpinWait(10);
                            continue;
                        }
                    }

                    try
                    {
                        int sent = socket.SendTo(payload, dstEp);
                        _perfCounter.AddTx(1, sent + 42); // +42 for IP+UDP+Ethernet overhead
                        Logger?.LogTx(0, dstIpNum, SrcPort, DstPort, sent, PayloadText);
                        if (rateLimit)
                            nextSendTick += ticksPerPacket;
                    }
                    catch (SocketException)
                    {
                        _perfCounter.AddErrors(1);
                    }

                    // Poll for responses
                    try
                    {
                        while (socket.Available > 0)
                        {
                            int received = socket.ReceiveFrom(rxBuf, ref remoteEp);
                            _perfCounter.AddRx(1, received + 42);

                            var ep = (IPEndPoint)remoteEp;
                            string? text = null;
                            if (received > 0)
                                text = Encoding.ASCII.GetString(rxBuf, 0, received).TrimEnd('\0');

                            Logger?.LogRx(0, 0, (ushort)ep.Port, SrcPort, received, text);
                            if (ResponseQueue.Count < 10000)
                            {
                                ResponseQueue.Enqueue(new RxPacketInfo
                                {
                                    SrcIp = ep.Address.ToString(),
                                    SrcPort = (ushort)ep.Port,
                                    DstIp = "",
                                    DstPort = SrcPort,
                                    DataLen = received,
                                    PayloadText = text
                                });
                            }
                        }
                    }
                    catch (SocketException) { }
                }
            }
            catch (Exception ex)
            {
                LastError = $"Socket TX 예외: {ex.GetType().Name}: {ex.Message}";
            }
        }
    }

    public class SocketUdpRxEngine
    {
        private Thread? _rxThread;
        private volatile bool _running;
        private readonly PerformanceCounter _perfCounter;
        public ConcurrentQueue<RxPacketInfo> PacketQueue { get; } = new();

        public ushort ListenPort { get; set; } = 5000;
        public string? FilterIp { get; set; }
        public PacketLogger? Logger { get; set; }

        public SocketUdpRxEngine(PerformanceCounter perfCounter)
        {
            _perfCounter = perfCounter;
        }

        public void Start()
        {
            if (_running) return;
            _running = true;
            _rxThread = new Thread(RxLoop) { IsBackground = true, Name = "Socket-UDP-RX", Priority = ThreadPriority.Highest };
            _rxThread.Start();
        }

        public void Stop()
        {
            _running = false;
            _rxThread?.Join(2000);
            _rxThread = null;
        }

        private void RxLoop()
        {
            try
            {
                using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
                socket.Bind(new IPEndPoint(IPAddress.Any, ListenPort));
                socket.ReceiveTimeout = 100;
                socket.ReceiveBufferSize = 1024 * 1024;

                byte[] buf = new byte[2048];
                EndPoint remoteEp = new IPEndPoint(IPAddress.Any, 0);

                while (_running)
                {
                    try
                    {
                        int received = socket.ReceiveFrom(buf, ref remoteEp);
                        var ep = (IPEndPoint)remoteEp;

                        // Filter
                        if (!string.IsNullOrEmpty(FilterIp) && ep.Address.ToString() != FilterIp)
                            continue;

                        _perfCounter.AddRx(1, received + 42);

                        string? text = null;
                        if (received > 0)
                            text = Encoding.ASCII.GetString(buf, 0, received).TrimEnd('\0');

                        Logger?.LogRx(0, 0, (ushort)ep.Port, ListenPort, received, text);
                        if (PacketQueue.Count < 10000)
                        {
                            PacketQueue.Enqueue(new RxPacketInfo
                            {
                                SrcIp = ep.Address.ToString(),
                                SrcPort = (ushort)ep.Port,
                                DstIp = "",
                                DstPort = ListenPort,
                                DataLen = received,
                                PayloadText = text
                            });
                        }
                    }
                    catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
                    {
                        // Normal timeout, continue
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Socket RX 예외: {ex.Message}");
            }
        }
    }

    public class SocketUdpServerEngine
    {
        private Thread? _thread;
        private volatile bool _running;
        private readonly PerformanceCounter _perfCounter;
        public ConcurrentQueue<RxPacketInfo> PacketQueue { get; } = new();
        public ConcurrentQueue<string> SendQueue { get; } = new();

        public ushort ListenPort { get; set; } = 8001;
        public string? AutoResponse { get; set; }
        public string? LastError { get; set; }
        public PacketLogger? Logger { get; set; }

        public SocketUdpServerEngine(PerformanceCounter perfCounter)
        {
            _perfCounter = perfCounter;
        }

        public void Start()
        {
            if (_running) return;
            _running = true;
            _thread = new Thread(ServerLoop) { IsBackground = true, Name = "Socket-UDP-Server", Priority = ThreadPriority.Highest };
            _thread.Start();
        }

        public void Stop()
        {
            _running = false;
            _thread?.Join(2000);
            _thread = null;
        }

        private void ServerLoop()
        {
            try
            {
                using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
                socket.Bind(new IPEndPoint(IPAddress.Any, ListenPort));
                socket.ReceiveTimeout = 50;
                socket.ReceiveBufferSize = 1024 * 1024;
                socket.SendBufferSize = 1024 * 1024;

                byte[] buf = new byte[2048];
                EndPoint remoteEp = new IPEndPoint(IPAddress.Any, 0);
                EndPoint lastSender = new IPEndPoint(IPAddress.Any, 0);

                while (_running)
                {
                    // Receive
                    try
                    {
                        int received = socket.ReceiveFrom(buf, ref remoteEp);
                        _perfCounter.AddRx(1, received + 42);
                        lastSender = new IPEndPoint(((IPEndPoint)remoteEp).Address, ((IPEndPoint)remoteEp).Port);

                        var ep = (IPEndPoint)remoteEp;
                        string? text = null;
                        if (received > 0)
                            text = Encoding.ASCII.GetString(buf, 0, received).TrimEnd('\0');

                        Logger?.LogRx(0, 0, (ushort)ep.Port, ListenPort, received, text);
                        if (PacketQueue.Count < 10000)
                        {
                            PacketQueue.Enqueue(new RxPacketInfo
                            {
                                SrcIp = ep.Address.ToString(),
                                SrcPort = (ushort)ep.Port,
                                DstIp = "",
                                DstPort = ListenPort,
                                DataLen = received,
                                PayloadText = text
                            });
                        }

                        // Auto response
                        if (!string.IsNullOrEmpty(AutoResponse))
                        {
                            byte[] resp = Encoding.ASCII.GetBytes(AutoResponse);
                            socket.SendTo(resp, remoteEp);
                            _perfCounter.AddTx(1, resp.Length + 42);
                            Logger?.LogTx(0, 0, ListenPort, (ushort)ep.Port, resp.Length, AutoResponse);
                        }
                    }
                    catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
                    {
                    }

                    // Manual send queue
                    while (SendQueue.TryDequeue(out var msg))
                    {
                        if (((IPEndPoint)lastSender).Port != 0)
                        {
                            try
                            {
                                byte[] data = Encoding.ASCII.GetBytes(msg);
                                socket.SendTo(data, lastSender);
                                _perfCounter.AddTx(1, data.Length + 42);
                            }
                            catch (SocketException) { _perfCounter.AddErrors(1); }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LastError = $"Server 예외: {ex.GetType().Name}: {ex.Message}";
            }
        }
    }

    public class SocketEchoEngine
    {
        private Thread? _thread;
        private volatile bool _running;
        private readonly PerformanceCounter _perfCounter;

        public ushort ListenPort { get; set; } = 5000;
        public PacketLogger? Logger { get; set; }

        public SocketEchoEngine(PerformanceCounter perfCounter)
        {
            _perfCounter = perfCounter;
        }

        public void Start()
        {
            if (_running) return;
            _running = true;
            _thread = new Thread(EchoLoop) { IsBackground = true, Name = "Socket-UDP-Echo", Priority = ThreadPriority.Highest };
            _thread.Start();
        }

        public void Stop()
        {
            _running = false;
            _thread?.Join(2000);
            _thread = null;
        }

        private void EchoLoop()
        {
            try
            {
                using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
                socket.Bind(new IPEndPoint(IPAddress.Any, ListenPort));
                socket.ReceiveTimeout = 100;
                socket.ReceiveBufferSize = 1024 * 1024;
                socket.SendBufferSize = 1024 * 1024;

                byte[] buf = new byte[2048];
                EndPoint remoteEp = new IPEndPoint(IPAddress.Any, 0);

                while (_running)
                {
                    try
                    {
                        int received = socket.ReceiveFrom(buf, ref remoteEp);
                        _perfCounter.AddRx(1, received + 42);
                        string? echoText = received > 0 ? Encoding.ASCII.GetString(buf, 0, received).TrimEnd('\0') : null;
                        Logger?.LogRx(0, 0, (ushort)((IPEndPoint)remoteEp).Port, ListenPort, received, echoText);

                        socket.SendTo(buf, 0, received, SocketFlags.None, remoteEp);
                        _perfCounter.AddTx(1, received + 42);
                        Logger?.LogTx(0, 0, ListenPort, (ushort)((IPEndPoint)remoteEp).Port, received, echoText);
                    }
                    catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
                    {
                        // Normal timeout
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Socket Echo 예외: {ex.Message}");
            }
        }
    }

    public class SocketUdpReqRespEngine
    {
        private Thread? _thread;
        private volatile bool _running;
        private readonly PerformanceCounter _perfCounter;

        public string DstIp { get; set; } = "192.168.0.1";
        public ushort DstPort { get; set; } = 5000;
        public ushort SrcPort { get; set; } = 4000;
        public int PayloadSize { get; set; } = 64;
        public string? PayloadText { get; set; }
        public int TimeoutMs { get; set; } = 1000;
        public int RepeatCount { get; set; } = 0; // 0 = 무한 반복
        public string? LastError { get; set; }

        public PacketLogger? Logger { get; set; }
        public ConcurrentQueue<ReqRespResult> ResultQueue { get; } = new();
        public RttStats Stats { get; } = new();
        public bool IsCompleted { get; private set; }

        public SocketUdpReqRespEngine(PerformanceCounter perfCounter)
        {
            _perfCounter = perfCounter;
        }

        public void Start()
        {
            if (_running) return;
            Stats.Reset();
            IsCompleted = false;
            _running = true;
            _thread = new Thread(ReqRespLoop) { IsBackground = true, Name = "Socket-UDP-ReqResp", Priority = ThreadPriority.Highest };
            _thread.Start();
        }

        public void Stop()
        {
            _running = false;
            _thread?.Join(3000);
            _thread = null;
        }

        private void ReqRespLoop()
        {
            try
            {
                using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
                socket.Bind(new IPEndPoint(IPAddress.Any, SrcPort));
                socket.ReceiveTimeout = TimeoutMs;
                socket.SendBufferSize = 1024 * 1024;
                socket.ReceiveBufferSize = 1024 * 1024;

                var dstEp = new IPEndPoint(IPAddress.Parse(DstIp), DstPort);
                uint dstIpNum = NetUtils.IpToUint(DstIp);

                // Build payload
                byte[] payload;
                if (!string.IsNullOrEmpty(PayloadText))
                {
                    byte[] textBytes = Encoding.ASCII.GetBytes(PayloadText);
                    payload = new byte[Math.Max(PayloadSize, textBytes.Length)];
                    Buffer.BlockCopy(textBytes, 0, payload, 0, textBytes.Length);
                }
                else
                {
                    payload = new byte[PayloadSize];
                    for (int i = 0; i < payload.Length; i++)
                        payload[i] = (byte)(i & 0xFF);
                }

                byte[] rxBuf = new byte[2048];
                EndPoint remoteEp = new IPEndPoint(IPAddress.Any, 0);
                uint seqNum = 0;
                int repeatCount = RepeatCount;

                while (_running)
                {
                    // 반복 횟수 체크 (0 = 무한)
                    if (repeatCount > 0 && seqNum >= (uint)repeatCount)
                    {
                        IsCompleted = true;
                        break;
                    }

                    try
                    {
                        long sendTick = System.Diagnostics.Stopwatch.GetTimestamp();
                        socket.SendTo(payload, dstEp);
                        _perfCounter.AddTx(1, payload.Length + 42);
                        Stats.AddSent();
                        seqNum++;

                        // Wait for response
                        bool gotResponse = false;
                        try
                        {
                            int received = socket.ReceiveFrom(rxBuf, ref remoteEp);
                            long rttTicks = System.Diagnostics.Stopwatch.GetTimestamp() - sendTick;
                            double rttMs = rttTicks * 1000.0 / System.Diagnostics.Stopwatch.Frequency;

                            _perfCounter.AddRx(1, received + 42);
                            Stats.AddReceived(rttMs);

                            string? respText = received > 0
                                ? Encoding.ASCII.GetString(rxBuf, 0, received).TrimEnd('\0')
                                : null;
                            Logger?.LogReqResp(0, dstIpNum, SrcPort, DstPort,
                                payload.Length, PayloadText, rttMs, 0,
                                respText, received);

                            gotResponse = true;
                        }
                        catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
                        {
                            // Timeout
                        }

                        if (!gotResponse)
                        {
                            Stats.AddTimeout();
                            Logger?.LogReqResp(0, dstIpNum, SrcPort, DstPort,
                                payload.Length, PayloadText, TimeoutMs, 1);
                            if (ResultQueue.Count < 10000)
                            {
                                ResultQueue.Enqueue(new ReqRespResult
                                {
                                    SeqNumber = seqNum,
                                    Success = false,
                                    RttMs = TimeoutMs
                                });
                            }
                        }
                    }
                    catch (SocketException)
                    {
                        _perfCounter.AddErrors(1);
                    }
                }
            }
            catch (Exception ex)
            {
                LastError = $"Socket ReqResp 예외: {ex.GetType().Name}: {ex.Message}";
            }
        }
    }
}
