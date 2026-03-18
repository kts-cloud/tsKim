// =============================================================================
// ActUtlTypeTcp.cs
// TCP-based implementation of IActUtlType for PLC communication.
// Converted from Delphi: CommTCP_PLC.pas (TCommTCP + TSocketReadThread).
//
// Architecture:
//   App (this TCP client) → ActUtilTCPServer.exe (TCP server, port 3888)
//                         → Mitsubishi PLC via ActUtlType.dll
//
// The Delphi original uses TIdTCPClient (Indy) for TCP and Win32 events for
// synchronisation. This C# version uses System.Net.Sockets.TcpClient and
// ManualResetEventSlim for the same pattern.
//
// Namespace: Dongaeltek.ITOLED.Hardware.Plc
// =============================================================================

using System.Net.Sockets;
using Dongaeltek.ITOLED.Core.Interfaces;

namespace Dongaeltek.ITOLED.Hardware.Plc;

/// <summary>
/// TCP-based PLC communication driver implementing <see cref="IActUtlType"/>.
/// <para>
/// Communicates with ActUtilTCPServer.exe (a separate process that wraps
/// the Mitsubishi ActUtlType.dll) using a custom binary protocol.
/// </para>
/// <para>Delphi origin: TCommTCP (CommTCP_PLC.pas)</para>
/// </summary>
public sealed class ActUtlTypeTcp : IActUtlType
{
    // =========================================================================
    // Constants
    // =========================================================================

    /// <summary>Header size: "PLC"(3) + Command(1) + Count(1) + Device(10) = 15 bytes.</summary>
    private const int HeaderSize = 15;

    /// <summary>Maximum data elements (Delphi: Data: array[0..100] of Integer).</summary>
    private const int MaxDataCount = 101;

    // =========================================================================
    // TCP connection
    // =========================================================================

    private TcpClient? _tcpClient;
    private NetworkStream? _stream;
    private readonly string _host;
    private readonly int _port;
    private readonly int _connectTimeoutMs;

    // =========================================================================
    // Auto-reconnect background thread
    // =========================================================================

    private Thread? _readThread;
    private volatile bool _active;     // Delphi: m_bActive (controls reconnect)
    private volatile bool _disposed;

    // =========================================================================
    // Command synchronisation (Delphi: m_hEventCommand, m_bWorking, m_nAck)
    // =========================================================================

    private readonly ManualResetEventSlim _commandEvent = new(false);
    private readonly object _sendLock = new();
    private volatile bool _working;    // Delphi: m_bWorking
    private volatile byte _ack;        // Delphi: m_nAck
    private readonly int[] _values = new int[MaxDataCount]; // Delphi: m_Values

    // =========================================================================
    // Reconnect timing (Delphi: m_nTick in TSocketReadThread)
    // =========================================================================

    private long _lastReconnectTick;
    private const int ReconnectIntervalMs = 3000;

    // =========================================================================
    // Dependencies
    // =========================================================================

    private readonly IMessageBus _messageBus;
    private readonly ILogger _logger;

    // =========================================================================
    // IActUtlType properties
    // =========================================================================

    /// <inheritdoc />
    public bool IsLoaded => true; // TCP mode is always "loaded"

    /// <inheritdoc />
    public string ErrorMessage { get; private set; } = string.Empty;

    /// <summary>
    /// Whether the TCP connection to ActUtilTCPServer.exe is established.
    /// </summary>
    public bool Connected => _tcpClient?.Connected == true;

    // =========================================================================
    // Constructor
    // =========================================================================

    /// <summary>
    /// Creates the TCP-based PLC communication driver.
    /// <para>Delphi origin: TCommTCP.Create (CommTCP_PLC.pas line 109)</para>
    /// </summary>
    /// <param name="host">TCP server host (default: "127.0.0.1").</param>
    /// <param name="port">TCP server port (default: 3888).</param>
    /// <param name="messageBus">Message bus for GUI notifications.</param>
    /// <param name="logger">Application logger.</param>
    /// <param name="connectTimeoutMs">TCP connect timeout in milliseconds (default: 2000).</param>
    public ActUtlTypeTcp(
        string host,
        int port,
        IMessageBus messageBus,
        ILogger logger,
        int connectTimeoutMs = 2000)
    {
        _host = host;
        _port = port;
        _messageBus = messageBus ?? throw new ArgumentNullException(nameof(messageBus));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _connectTimeoutMs = connectTimeoutMs;

        // Start the background read/reconnect thread (Delphi: TSocketReadThread.Create + Start)
        _readThread = new Thread(ReadThreadProc)
        {
            Name = "ActUtlTypeTcp.ReadThread",
            IsBackground = true
        };
        _readThread.Start();

        _logger.Info($"ActUtlTypeTcp: created (host={host}, port={port})");
    }

    // =========================================================================
    // IActUtlType — Lifecycle
    // =========================================================================

    /// <inheritdoc />
    /// <remarks>No-op for TCP mode (no COM object to create).</remarks>
    public void CreateActType64()
    {
        // Delphi: TCommTCP doesn't use ActUtlType COM — no-op
    }

    /// <inheritdoc />
    /// <remarks>No-op for TCP mode (station number is handled by ActUtilTCPServer).</remarks>
    public void SetActLogicalStationNumber(int logicalStationNumber)
    {
        // Delphi: TCommTCP doesn't set station number — handled by ActUtilTCPServer.exe
    }

    /// <inheritdoc />
    /// <remarks>
    /// Activates the auto-reconnect thread so it starts attempting TCP connections.
    /// Delphi origin: TCommTCP.Active := True (CommPLC_ECS.pas line 978)
    /// </remarks>
    public int Open()
    {
        _active = true;
        _logger.Info("ActUtlTypeTcp: Open (active=true, reconnect enabled)");
        return 0;
    }

    /// <inheritdoc />
    /// <remarks>
    /// Deactivates the auto-reconnect thread and disconnects TCP.
    /// </remarks>
    public int Close()
    {
        _active = false;
        DisconnectTcp();
        _logger.Info("ActUtlTypeTcp: Close (active=false, disconnected)");
        return 0;
    }

    // =========================================================================
    // IActUtlType — Device I/O
    // =========================================================================

    /// <inheritdoc />
    /// <remarks>
    /// TCP Command=1 (ReadDevice/GetDevice).
    /// Delphi origin: TCommTCP.GetDevice (CommTCP_PLC.pas line 240)
    /// </remarks>
    public void GetDevice(string deviceName, ref int deviceValue, ref int returnCode)
    {
        if (!Connected)
        {
            returnCode = 1;
            return;
        }

        var packet = BuildPacket(command: 1, count: 1, deviceName, stackalloc int[] { 0 });

        int ret = SendCommand(packet);
        if (ret == 0)
        {
            deviceValue = _values[0];
            returnCode = _ack != 0 ? _ack : 0;
        }
        else
        {
            returnCode = ret;
        }
    }

    /// <inheritdoc />
    /// <remarks>
    /// TCP Command=3 (WriteDevice/SetDevice).
    /// Delphi origin: TCommTCP.SetDevice (CommTCP_PLC.pas line 370)
    /// </remarks>
    public void SetDevice(string deviceName, ref int deviceValue, ref int returnCode)
    {
        if (!Connected)
        {
            returnCode = 1;
            return;
        }

        var packet = BuildPacket(command: 3, count: 1, deviceName, stackalloc int[] { deviceValue });

        int ret = SendCommand(packet);
        returnCode = ret == 0 ? (_ack != 0 ? _ack : 0) : ret;
    }

    /// <inheritdoc />
    /// <remarks>
    /// TCP Command=2 (ReadDeviceBlock).
    /// Delphi origin: TCommTCP.ReadDeviceBlock (CommTCP_PLC.pas line 308)
    /// </remarks>
    public void ReadDeviceBlock(string deviceName, int numberOfData, int[] deviceValues, ref int returnCode)
    {
        if (!Connected)
        {
            returnCode = 1;
            return;
        }

        if (numberOfData > MaxDataCount)
        {
            returnCode = -1;
            return;
        }

        // Delphi sends only 1 int in the data section for ReadDeviceBlock
        var packet = BuildPacket(command: 2, count: (byte)numberOfData, deviceName, stackalloc int[] { 0 });

        int ret = SendCommand(packet);
        if (ret == 0)
        {
            // Copy received values to caller's buffer
            int copyCount = Math.Min(numberOfData, deviceValues.Length);
            Array.Copy(_values, 0, deviceValues, 0, copyCount);
            returnCode = _ack != 0 ? _ack : 0;
        }
        else
        {
            returnCode = ret;
        }
    }

    /// <inheritdoc />
    /// <remarks>
    /// TCP Command=4 (WriteDeviceBlock).
    /// Delphi origin: TCommTCP.WriteDeviceBlock (CommTCP_PLC.pas line 401)
    /// </remarks>
    public void WriteDeviceBlock(string deviceName, int numberOfData, int[] deviceValues, ref int returnCode)
    {
        if (!Connected)
        {
            returnCode = 1;
            return;
        }

        if (numberOfData > MaxDataCount)
        {
            returnCode = -1;
            return;
        }

        var packet = BuildPacket(command: 4, count: (byte)numberOfData, deviceName,
            deviceValues.AsSpan(0, numberOfData));

        int ret = SendCommand(packet);
        returnCode = ret == 0 ? (_ack != 0 ? _ack : 0) : ret;
    }

    /// <inheritdoc />
    /// <remarks>
    /// Not supported via TCP protocol. Returns returnCode = -1.
    /// </remarks>
    public void ReadBuffer(int startIO, int address, int size, short[] data, ref int returnCode)
    {
        returnCode = -1; // Not supported via TCP
    }

    /// <inheritdoc />
    /// <remarks>
    /// Not supported via TCP protocol. Returns returnCode = -1.
    /// </remarks>
    public void WriteBuffer(int startIO, int address, int size, short[] data, ref int returnCode)
    {
        returnCode = -1; // Not supported via TCP
    }

    /// <inheritdoc />
    /// <remarks>
    /// Not supported via TCP protocol. Returns returnCode = -1.
    /// </remarks>
    public void GetClockData(
        out short year, out short month, out short day, out short dayOfWeek,
        out short hour, out short minute, out short second,
        ref int returnCode)
    {
        year = month = day = dayOfWeek = hour = minute = second = 0;
        returnCode = -1; // Not supported via TCP
    }

    // =========================================================================
    // SendCommand (Delphi: TCommTCP.SendCommand, line 438)
    // =========================================================================

    /// <summary>
    /// Sends a command packet and waits for the response.
    /// </summary>
    /// <param name="packet">Complete binary packet to send.</param>
    /// <param name="waitMs">Timeout in milliseconds (default: 5000).</param>
    /// <returns>
    /// 0 = success, 100 = not connected, 102 = busy,
    /// 1000 = PLC not connected (ACK=1), 1001 = error (ACK>=2).
    /// </returns>
    internal int SendCommand(byte[] packet, int waitMs = 5000)
    {
        if (!Connected)
            return 100; // Not connected

        lock (_sendLock)
        {
            if (_working)
                return 102; // Already working

            _working = true;
        }

        try
        {
            _commandEvent.Reset();

            try
            {
                _stream!.Write(packet, 0, packet.Length);
            }
            catch (Exception ex)
            {
                _logger.Error("ActUtlTypeTcp.SendCommand: write failed", ex);
                DisconnectTcp();
                return 100;
            }

            if (!_commandEvent.Wait(waitMs))
            {
                _ack = 3; // Timeout
                return waitMs; // Delphi returns the wait timeout value
            }

            return _ack switch
            {
                0 => 0,         // Success
                1 => 1000,      // PLC not connected
                _ => 1001       // Error
            };
        }
        finally
        {
            lock (_sendLock)
            {
                _working = false;
            }
        }
    }

    // =========================================================================
    // Packet building
    // =========================================================================

    /// <summary>
    /// Builds a TPLCHeader binary packet.
    /// </summary>
    /// <param name="command">Command byte (1-4).</param>
    /// <param name="count">Number of data elements.</param>
    /// <param name="deviceName">PLC device name (e.g. "D100").</param>
    /// <param name="data">Data values to include in packet.</param>
    /// <returns>Complete binary packet ready to send.</returns>
    internal static byte[] BuildPacket(byte command, byte count, string deviceName, ReadOnlySpan<int> data)
    {
        int dataBytes = data.Length * sizeof(int);
        int packetSize = HeaderSize + dataBytes;
        var packet = new byte[packetSize];

        // PLC header: "PLC"
        packet[0] = (byte)'P';
        packet[1] = (byte)'L';
        packet[2] = (byte)'C';

        // Command and Count
        packet[3] = command;
        packet[4] = count;

        // Device name (up to 10 bytes, null-terminated)
        var deviceBytes = System.Text.Encoding.ASCII.GetBytes(deviceName);
        int copyLen = Math.Min(deviceBytes.Length, 10);
        Buffer.BlockCopy(deviceBytes, 0, packet, 5, copyLen);
        // Remaining bytes in Device field are already 0 (from new byte[])

        // Data (int32 array, little-endian)
        for (int i = 0; i < data.Length; i++)
        {
            int offset = HeaderSize + i * sizeof(int);
            BitConverter.TryWriteBytes(packet.AsSpan(offset, sizeof(int)), data[i]);
        }

        return packet;
    }

    // =========================================================================
    // Background read/reconnect thread (Delphi: TSocketReadThread.Execute)
    // =========================================================================

    /// <summary>
    /// Background thread that handles TCP auto-reconnection and response reading.
    /// <para>Delphi origin: TSocketReadThread.Execute (CommTCP_PLC.pas line 531)</para>
    /// </summary>
    private void ReadThreadProc()
    {
        while (!_disposed)
        {
            try
            {
                if (_tcpClient == null || !_tcpClient.Connected)
                {
                    Thread.Sleep(500);

                    // Auto-reconnect every 3 seconds (Delphi: GetTickCount - m_nTick > 3000)
                    if (_active)
                    {
                        long now = Environment.TickCount64;
                        if (now - _lastReconnectTick > ReconnectIntervalMs)
                        {
                            _lastReconnectTick = now;
                            TryConnect();
                        }
                    }
                    continue;
                }

                // Check for available data (Delphi: TCPClient.IOHandler.CheckForDataOnSource(10))
                if (_stream == null || !_stream.DataAvailable)
                {
                    Thread.Sleep(10);
                    continue;
                }

                // Read response
                ReadResponse();
            }
            catch (Exception ex)
            {
                if (!_disposed)
                {
                    _logger.Error("ActUtlTypeTcp.ReadThread: exception", ex);
                    DisconnectTcp();
                }
            }
        }
    }

    /// <summary>
    /// Attempts to connect to ActUtilTCPServer.exe.
    /// </summary>
    private void TryConnect()
    {
        try
        {
            _tcpClient?.Dispose();

            _tcpClient = new TcpClient();
            _tcpClient.ReceiveTimeout = 5000;
            _tcpClient.SendTimeout = 5000;

            var connectTask = _tcpClient.ConnectAsync(_host, _port);
            if (!connectTask.Wait(_connectTimeoutMs))
            {
                // Connect timeout
                _tcpClient.Dispose();
                _tcpClient = null;
                return;
            }

            if (_tcpClient.Connected)
            {
                _stream = _tcpClient.GetStream();
                _logger.Info($"ActUtlTypeTcp: connected to {_host}:{_port}");
            }
        }
        catch
        {
            // Connection failed — will retry on next interval
            _tcpClient?.Dispose();
            _tcpClient = null;
            _stream = null;
        }
    }

    /// <summary>
    /// Reads and parses a response from the TCP stream.
    /// <para>Delphi origin: TCommTCP.IdTCPClientReadData (line 159)</para>
    /// </summary>
    private void ReadResponse()
    {
        // Read the full response into a buffer
        // Delphi reads all available data at once via InputBuffer.ExtractToBytes
        var headerBuf = new byte[HeaderSize];
        int bytesRead = ReadExact(_stream!, headerBuf, 0, HeaderSize);
        if (bytesRead < HeaderSize)
        {
            DisconnectTcp();
            return;
        }

        // Validate "PLC" magic
        if (headerBuf[0] != (byte)'P' || headerBuf[1] != (byte)'L' || headerBuf[2] != (byte)'C')
        {
            // Invalid header — discard
            _logger.Warn("ActUtlTypeTcp: invalid response header (not 'PLC')");
            return;
        }

        byte commandByte = headerBuf[3];
        byte count = headerBuf[4];

        // Read data section: count * sizeof(int) bytes
        int dataSize = count * sizeof(int);
        if (dataSize > 0)
        {
            var dataBuf = new byte[dataSize];
            int dataRead = ReadExact(_stream!, dataBuf, 0, dataSize);
            if (dataRead < dataSize)
            {
                DisconnectTcp();
                return;
            }

            // Copy data to _values (Delphi: CopyMemory(@m_Values[0], @pHeader.Data[0], ...))
            int copyCount = Math.Min((int)count, MaxDataCount);
            for (int i = 0; i < copyCount; i++)
            {
                _values[i] = BitConverter.ToInt32(dataBuf, i * sizeof(int));
            }
        }

        // Parse ACK from command byte (Delphi: IdTCPClientReadData, line 186-197)
        if (commandByte > 0x90)
        {
            _ack = 1; // PLC not connected
        }
        else if (commandByte > 0x80)
        {
            _ack = 2; // Error occurred
        }
        else
        {
            _ack = 0; // Success
        }

        // Signal the waiting SendCommand (Delphi: SetEvent(m_hEventCommand))
        _commandEvent.Set();
    }

    /// <summary>
    /// Reads exactly <paramref name="count"/> bytes from the stream.
    /// Returns the number of bytes actually read.
    /// </summary>
    private static int ReadExact(NetworkStream stream, byte[] buffer, int offset, int count)
    {
        int totalRead = 0;
        while (totalRead < count)
        {
            int n = stream.Read(buffer, offset + totalRead, count - totalRead);
            if (n == 0) return totalRead; // Connection closed
            totalRead += n;
        }
        return totalRead;
    }

    /// <summary>
    /// Disconnects the TCP client safely.
    /// </summary>
    private void DisconnectTcp()
    {
        try
        {
            _stream?.Dispose();
            _tcpClient?.Dispose();
        }
        catch { /* swallow */ }
        finally
        {
            _stream = null;
            _tcpClient = null;
        }
    }

    // =========================================================================
    // IDisposable
    // =========================================================================

    /// <inheritdoc />
    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        _active = false;

        // Wake up any waiting SendCommand
        _commandEvent.Set();

        // Wait for read thread to exit
        _readThread?.Join(2000);
        _readThread = null;

        DisconnectTcp();
        _commandEvent.Dispose();
    }
}
