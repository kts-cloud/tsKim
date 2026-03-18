// =============================================================================
// ActUtlTypeTcpTests.cs — Tests for TCP-based PLC communication driver.
// Tests packet serialization, response parsing, and loopback integration.
// =============================================================================

using System.Net;
using System.Net.Sockets;
using Dongaeltek.ITOLED.Core.Interfaces;
using Dongaeltek.ITOLED.Core.Messaging;
using Dongaeltek.ITOLED.Hardware.Plc;
using Dongaeltek.ITOLED.Messaging;

namespace ITOLED.Tests.Plc;

// ── Minimal ILogger stub for testing ──────────────────────────────────
internal class NullLogger : Dongaeltek.ITOLED.Core.Interfaces.ILogger
{
    public int DebugLogLevel { get; set; }
    public void Debug(string message) { }
    public void Debug(int channel, string message) { }
    public void Info(string message) { }
    public void Info(int channel, string message) { }
    public void Warn(string message) { }
    public void Warn(int channel, string message) { }
    public void Error(string message) { }
    public void Error(string message, Exception exception) { }
    public void Error(int channel, string message) { }
    public void Error(int channel, string message, Exception exception) { }
    public void LogResult(int channel, int logType, string message) { }
}

public class ActUtlTypeTcpTests : IDisposable
{
    private readonly NullLogger _logger = new();
    private readonly MessageBus _bus = new();

    public void Dispose() { }

    // =========================================================================
    // BuildPacket tests — verify packet serialization matches Delphi protocol
    // =========================================================================

    [Fact]
    public void BuildPacket_GetDevice_CorrectHeader()
    {
        // Command=1 (GetDevice), Count=1, Device="D100"
        var packet = ActUtlTypeTcp.BuildPacket(1, 1, "D100", new ReadOnlySpan<int>([0]));

        // Header: "PLC"
        Assert.Equal((byte)'P', packet[0]);
        Assert.Equal((byte)'L', packet[1]);
        Assert.Equal((byte)'C', packet[2]);

        // Command and Count
        Assert.Equal(1, packet[3]); // Command=1
        Assert.Equal(1, packet[4]); // Count=1

        // Device field (10 bytes, null-terminated ASCII)
        Assert.Equal((byte)'D', packet[5]);
        Assert.Equal((byte)'1', packet[6]);
        Assert.Equal((byte)'0', packet[7]);
        Assert.Equal((byte)'0', packet[8]);
        Assert.Equal(0, packet[9]); // null terminator

        // Total size = 15 (header) + 4 (1 int)
        Assert.Equal(19, packet.Length);
    }

    [Fact]
    public void BuildPacket_WriteDevice_DataIncluded()
    {
        // Command=3 (WriteDevice), Count=1, Device="M200", Data[0]=42
        var packet = ActUtlTypeTcp.BuildPacket(3, 1, "M200", new ReadOnlySpan<int>([42]));

        Assert.Equal(3, packet[3]); // Command=3
        Assert.Equal(1, packet[4]); // Count=1

        // Data: int32 42 in little-endian at offset 15
        int dataValue = BitConverter.ToInt32(packet, 15);
        Assert.Equal(42, dataValue);
    }

    [Fact]
    public void BuildPacket_ReadDeviceBlock_CountSet()
    {
        // Command=2 (ReadDeviceBlock), Count=10, Device="B400"
        var packet = ActUtlTypeTcp.BuildPacket(2, 10, "B400", new ReadOnlySpan<int>([0]));

        Assert.Equal(2, packet[3]);  // Command=2
        Assert.Equal(10, packet[4]); // Count=10

        // Send size: 15 + 4 (one int placeholder)
        Assert.Equal(19, packet.Length);
    }

    [Fact]
    public void BuildPacket_WriteDeviceBlock_MultipleData()
    {
        // Command=4 (WriteDeviceBlock), Count=3, Device="D100", Data=[10, 20, 30]
        int[] data = [10, 20, 30];
        var packet = ActUtlTypeTcp.BuildPacket(4, 3, "D100", data.AsSpan());

        Assert.Equal(4, packet[3]); // Command=4
        Assert.Equal(3, packet[4]); // Count=3

        // Total size: 15 + 3*4 = 27
        Assert.Equal(27, packet.Length);

        // Verify data values
        Assert.Equal(10, BitConverter.ToInt32(packet, 15));
        Assert.Equal(20, BitConverter.ToInt32(packet, 19));
        Assert.Equal(30, BitConverter.ToInt32(packet, 23));
    }

    [Fact]
    public void BuildPacket_DeviceNameMaxLength_Truncated()
    {
        // Device name longer than 10 chars should be truncated
        var packet = ActUtlTypeTcp.BuildPacket(1, 1, "ABCDEFGHIJKLMN", new ReadOnlySpan<int>([0]));

        // Only first 10 bytes of device name
        Assert.Equal((byte)'A', packet[5]);
        Assert.Equal((byte)'J', packet[14]); // 10th char at offset 5+9=14
        Assert.Equal(19, packet.Length); // 15 header + 4 data
    }

    // =========================================================================
    // Constructor / Dispose tests
    // =========================================================================

    [Fact]
    public void Constructor_SetsIsLoadedTrue()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        Assert.True(tcp.IsLoaded);
        Assert.Empty(tcp.ErrorMessage);
    }

    [Fact]
    public void Dispose_DoesNotThrow()
    {
        var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        var ex = Record.Exception(() => tcp.Dispose());
        Assert.Null(ex);
    }

    [Fact]
    public void Open_SetsActiveMode()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int ret = tcp.Open();
        Assert.Equal(0, ret);
    }

    [Fact]
    public void Close_ReturnsZero()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        tcp.Open();
        int ret = tcp.Close();
        Assert.Equal(0, ret);
    }

    // =========================================================================
    // Not-connected tests — methods should return error when TCP is down
    // =========================================================================

    [Fact]
    public void GetDevice_NotConnected_ReturnsError()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int value = 0, rc = 0;
        tcp.GetDevice("D100", ref value, ref rc);
        Assert.Equal(1, rc); // Not connected
    }

    [Fact]
    public void SetDevice_NotConnected_ReturnsError()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int value = 42, rc = 0;
        tcp.SetDevice("D100", ref value, ref rc);
        Assert.Equal(1, rc);
    }

    [Fact]
    public void ReadDeviceBlock_NotConnected_ReturnsError()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int rc = 0;
        var data = new int[10];
        tcp.ReadDeviceBlock("D100", 10, data, ref rc);
        Assert.Equal(1, rc);
    }

    [Fact]
    public void WriteDeviceBlock_NotConnected_ReturnsError()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int rc = 0;
        var data = new int[] { 1, 2, 3 };
        tcp.WriteDeviceBlock("D100", 3, data, ref rc);
        Assert.Equal(1, rc);
    }

    // =========================================================================
    // Unsupported operations
    // =========================================================================

    [Fact]
    public void ReadBuffer_ReturnsMinusOne()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int rc = 0;
        var data = new short[10];
        tcp.ReadBuffer(0, 0, 10, data, ref rc);
        Assert.Equal(-1, rc);
    }

    [Fact]
    public void WriteBuffer_ReturnsMinusOne()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int rc = 0;
        var data = new short[10];
        tcp.WriteBuffer(0, 0, 10, data, ref rc);
        Assert.Equal(-1, rc);
    }

    [Fact]
    public void GetClockData_ReturnsMinusOne()
    {
        using var tcp = new ActUtlTypeTcp("127.0.0.1", 0, _bus, _logger);
        int rc = 0;
        tcp.GetClockData(out _, out _, out _, out _, out _, out _, out _, ref rc);
        Assert.Equal(-1, rc);
    }

    // =========================================================================
    // Loopback integration test — mock TCP server echoes back responses
    // =========================================================================

    [Fact]
    public async Task GetDevice_WithLoopbackServer_ReadsValue()
    {
        // Start a simple loopback TCP server
        using var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        int port = ((IPEndPoint)listener.LocalEndpoint).Port;

        var serverTask = Task.Run(async () =>
        {
            using var client = await listener.AcceptTcpClientAsync();
            var stream = client.GetStream();

            // Read the request packet (15 header + 4 data = 19 bytes)
            var reqBuf = new byte[19];
            int read = 0;
            while (read < 19)
                read += await stream.ReadAsync(reqBuf.AsMemory(read, 19 - read));

            // Build response: same header with Data[0] = 12345 (success ACK)
            var respBuf = new byte[19];
            Array.Copy(reqBuf, respBuf, 15);
            // Command stays the same (no 0x80/0x90 offset = ACK=0 success)
            respBuf[4] = 1; // Count=1
            BitConverter.TryWriteBytes(respBuf.AsSpan(15), 12345);

            await stream.WriteAsync(respBuf);
            await Task.Delay(100); // Keep connection alive briefly
        });

        // Create TCP client and connect
        using var tcp = new ActUtlTypeTcp("127.0.0.1", port, _bus, _logger, connectTimeoutMs: 3000);
        tcp.Open();

        // Wait for auto-reconnect to establish connection
        await Task.Delay(4000);

        int value = 0, rc = 99;
        tcp.GetDevice("D100", ref value, ref rc);

        // Verify
        Assert.Equal(0, rc);
        Assert.Equal(12345, value);

        await serverTask;
    }

    [Fact]
    public async Task ReadDeviceBlock_WithLoopbackServer_ReadsValues()
    {
        using var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        int port = ((IPEndPoint)listener.LocalEndpoint).Port;

        var serverTask = Task.Run(async () =>
        {
            using var client = await listener.AcceptTcpClientAsync();
            var stream = client.GetStream();

            // Read request: 15 header + 4 data = 19 bytes
            var reqBuf = new byte[19];
            int read = 0;
            while (read < 19)
                read += await stream.ReadAsync(reqBuf.AsMemory(read, 19 - read));

            byte count = reqBuf[4]; // Count from request

            // Build response with count data values
            int respSize = 15 + count * 4;
            var respBuf = new byte[respSize];
            Array.Copy(reqBuf, respBuf, 15);
            // ACK=0 (command byte stays < 0x80)
            for (int i = 0; i < count; i++)
                BitConverter.TryWriteBytes(respBuf.AsSpan(15 + i * 4), (i + 1) * 100);

            await stream.WriteAsync(respBuf);
            await Task.Delay(100);
        });

        using var tcp = new ActUtlTypeTcp("127.0.0.1", port, _bus, _logger, connectTimeoutMs: 3000);
        tcp.Open();
        await Task.Delay(4000);

        int rc = 99;
        var data = new int[5];
        tcp.ReadDeviceBlock("D100", 5, data, ref rc);

        Assert.Equal(0, rc);
        Assert.Equal(100, data[0]);
        Assert.Equal(200, data[1]);
        Assert.Equal(300, data[2]);
        Assert.Equal(400, data[3]);
        Assert.Equal(500, data[4]);

        await serverTask;
    }

    [Fact]
    public async Task GetDevice_ServerReturnsPlcNotConnected_ReturnsAck1()
    {
        using var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        int port = ((IPEndPoint)listener.LocalEndpoint).Port;

        var serverTask = Task.Run(async () =>
        {
            using var client = await listener.AcceptTcpClientAsync();
            var stream = client.GetStream();

            var reqBuf = new byte[19];
            int read = 0;
            while (read < 19)
                read += await stream.ReadAsync(reqBuf.AsMemory(read, 19 - read));

            // Build response with Command > 0x90 → ACK=1 (PLC not connected)
            var respBuf = new byte[19];
            Array.Copy(reqBuf, respBuf, 15);
            respBuf[3] = (byte)(reqBuf[3] + 0x90); // Command + 0x90 → ACK=1
            respBuf[4] = 1;
            BitConverter.TryWriteBytes(respBuf.AsSpan(15), 0);

            await stream.WriteAsync(respBuf);
            await Task.Delay(100);
        });

        using var tcp = new ActUtlTypeTcp("127.0.0.1", port, _bus, _logger, connectTimeoutMs: 3000);
        tcp.Open();
        await Task.Delay(4000);

        int value = 0, rc = 0;
        tcp.GetDevice("D100", ref value, ref rc);

        // ACK=1 → returnCode should be non-zero (the method sets rc = _ack when _ack != 0)
        Assert.NotEqual(0, rc);

        await serverTask;
    }
}
