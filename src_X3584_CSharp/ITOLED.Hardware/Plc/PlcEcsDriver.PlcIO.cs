// =============================================================================
// PlcEcsDriver.PlcIO.cs  (partial)
// PLC Device I/O, Wait/Pulse, String conversion, HeartBeat, ClockData.
// Converted from Delphi: CommPLC_ECS.pas lines 4500-5050
// =============================================================================

using System.Text;

namespace Dongaeltek.ITOLED.Hardware.Plc;

public sealed partial class PlcEcsDriver
{
    // =========================================================================
    // ReadDevice / WriteDevice
    // =========================================================================

    /// <inheritdoc />
    public int ReadDevice(string device, out int value, bool saveLog = true)
    {
        value = 0;
        int rc = 0;

        lock (_writeLock)
        {
            if (UseSimulator)
            {
                value = _simMemory!.GetDevice(device);
                return 0;
            }

            if (!_opened) return -1;

            try
            {
                _actUtl.GetDevice(device, ref value, ref rc);
            }
            catch (Exception ex)
            {
                _logger.Error($"ReadDevice({device}) exception", ex);
                rc = -1;
            }
        }

        if (saveLog)
            AddLog($"ReadDevice({device}) = {value}, rc={rc}");

        if (rc != 0)
            AddLog($"ReadDevice({device}) ERROR rc={rc}");

        return rc;
    }

    /// <inheritdoc />
    public int WriteDevice(string device, int value, bool saveLog = true)
    {
        int rc = 0;

        lock (_writeLock)
        {
            if (UseSimulator)
            {
                _simMemory!.SetDevice(device, value);
                return 0;
            }

            if (!_opened) return -1;

            try
            {
                int v = value;
                _actUtl.SetDevice(device, ref v, ref rc);
            }
            catch (Exception ex)
            {
                _logger.Error($"WriteDevice({device}, {value}) exception", ex);
                rc = -1;
            }
        }

        if (saveLog)
            AddLog($"WriteDevice({device}, {value}), rc={rc}");

        if (rc != 0)
            AddLog($"WriteDevice({device}, {value}) ERROR rc={rc}");

        return rc;
    }

    // =========================================================================
    // ReadDeviceBit / WriteDeviceBit
    // =========================================================================

    /// <inheritdoc />
    public int ReadDeviceBit(string device, int bitLoc, out int value)
    {
        value = 0;

        // B-device: direct read (each B address is a single bit)
        if (device.StartsWith('B') || device.StartsWith('b'))
        {
            int rc = ReadDevice(device, out int raw, false);
            value = raw;
            return rc;
        }

        // Word device: read full word then extract bit
        int ret = ReadDevice(device, out int wordVal, false);
        value = GetBit(wordVal, bitLoc);
        return ret;
    }

    /// <inheritdoc />
    public int WriteDeviceBit(string device, int bitLoc, int value, bool saveLog = true)
    {
        // B-device: direct write
        if (device.StartsWith('B') || device.StartsWith('b'))
        {
            return WriteDevice(device, value, saveLog);
        }

        // Word device: read-modify-write
        int rc = ReadDevice(device, out int wordVal, false);
        if (rc != 0) return rc;

        int newVal = wordVal;
        SetBit(ref newVal, bitLoc, value);
        return WriteDevice(device, newVal, saveLog);
    }

    // =========================================================================
    // ReadDeviceBlock / WriteDeviceBlock
    // =========================================================================

    /// <inheritdoc />
    public int ReadDeviceBlock(string device, int size, int[] data, out int returnCode, bool saveLog = true)
    {
        returnCode = 0;

        lock (_writeLock)
        {
            if (UseSimulator)
            {
                _simMemory!.ReadBlock(device, size, data);
                returnCode = 0;
                return 0;
            }

            if (!_opened)
            {
                returnCode = -1;
                return -1;
            }

            try
            {
                _actUtl.ReadDeviceBlock(device, size, data, ref returnCode);
            }
            catch (Exception ex)
            {
                _logger.Error($"ReadDeviceBlock({device}, {size}) exception", ex);
                returnCode = -1;
            }
        }

        if (saveLog)
            AddLog($"ReadDeviceBlock({device}, {size}), rc={returnCode}");

        return returnCode;
    }

    /// <inheritdoc />
    public int WriteDeviceBlock(string device, int size, int[] data)
    {
        int rc = 0;

        lock (_writeLock)
        {
            if (UseSimulator)
            {
                _simMemory!.WriteBlock(device, size, data);
                return 0;
            }

            if (!_opened) return -1;

            try
            {
                _actUtl.WriteDeviceBlock(device, size, data, ref rc);
            }
            catch (Exception ex)
            {
                _logger.Error($"WriteDeviceBlock({device}, {size}) exception", ex);
                rc = -1;
            }
        }

        AddLog($"WriteDeviceBlock({device}, {size}), rc={rc}");
        return rc;
    }

    // =========================================================================
    // ReadString / WriteString
    // =========================================================================

    /// <inheritdoc />
    public string ReadString(string device, int address, int length)
    {
        int wordCount = (length + 1) / 2; // 2 chars per word
        var data = new int[wordCount];
        int rc;
        ReadDeviceBlock(device, wordCount, data, out rc, false);
        if (rc != 0) return string.Empty;
        return ConvertStrFromPlc(length, data);
    }

    /// <inheritdoc />
    public int WriteString(string device, string value)
    {
        int wordCount = (value.Length + 1) / 2;
        var data = new int[wordCount];
        ConvertStrToPlc(value, value.Length, data);
        return WriteDeviceBlock(device, wordCount, data);
    }

    // =========================================================================
    // ReadBuffer / WriteBuffer
    // =========================================================================

    /// <inheritdoc />
    public int ReadBuffer(int startIo, int address, int size, short[] data)
    {
        int rc = 0;
        lock (_writeLock)
        {
            if (!_opened) return -1;
            try
            {
                _actUtl.ReadBuffer(startIo, address, size, data, ref rc);
            }
            catch (Exception ex)
            {
                _logger.Error($"ReadBuffer exception", ex);
                rc = -1;
            }
        }
        return rc;
    }

    /// <inheritdoc />
    public int WriteBuffer(int startIo, int address, int size, short[] data)
    {
        int rc = 0;
        lock (_writeLock)
        {
            if (!_opened) return -1;
            try
            {
                _actUtl.WriteBuffer(startIo, address, size, data, ref rc);
            }
            catch (Exception ex)
            {
                _logger.Error($"WriteBuffer exception", ex);
                rc = -1;
            }
        }
        return rc;
    }

    // =========================================================================
    // WriteGlassData / ReadTactTime / ReadClockData
    // =========================================================================

    /// <inheritdoc />
    public int WriteGlassData(string device, EcsGlassData glassData)
    {
        // Stub - returns 0 (Delphi original also returns 0)
        return 0;
    }

    /// <inheritdoc />
    public int ReadTactTime(int channel)
    {
        // Stub - returns 0
        return 0;
    }

    /// <inheritdoc />
    public int ReadClockData(out short year, out short month, out short day, out short dayOfWeek,
        out short hour, out short minute, out short second)
    {
        year = month = day = dayOfWeek = hour = minute = second = 0;

        if (UseSimulator)
        {
            var now = DateTime.Now;
            year = (short)(now.Year % 100);
            month = (short)now.Month;
            day = (short)now.Day;
            dayOfWeek = (short)now.DayOfWeek;
            hour = (short)now.Hour;
            minute = (short)now.Minute;
            second = (short)now.Second;
            return 0;
        }

        if (_actUtl is null) return -1;

        int rc = 0;
        try
        {
            _actUtl.GetClockData(out year, out month, out day, out dayOfWeek,
                                 out hour, out minute, out second, ref rc);
        }
        catch (Exception ex)
        {
            _logger.Error("ReadClockData exception", ex);
            rc = -1;
        }
        return rc;
    }

    // =========================================================================
    // WaitSignal / WaitSignalBit
    // =========================================================================

    /// <summary>
    /// Polls a PLC device until it equals the expected value or times out.
    /// <para>Delphi origin: function WaitSignal (line 1036)</para>
    /// </summary>
    private int WaitSignal(string device, int expectedValue, uint waitTimeMs)
    {
        long start = Environment.TickCount64;
        while (Environment.TickCount64 - start < waitTimeMs)
        {
            if (_stopped == 1) return -1;

            ReadDevice(device, out int val, false);
            if (val == expectedValue)
                return 0;

            Thread.Sleep(100);
        }
        AddLog($"WaitSignal TIMEOUT: {device} expected={expectedValue} waitMs={waitTimeMs}");
        return -1; // timeout
    }

    /// <summary>
    /// Polls a PLC device bit until it equals the expected value or times out.
    /// <para>Delphi origin: function WaitSignalBit (line 1060)</para>
    /// </summary>
    private int WaitSignalBit(string device, int bitLoc, int expectedValue, uint waitTimeMs)
    {
        long start = Environment.TickCount64;
        while (Environment.TickCount64 - start < waitTimeMs)
        {
            if (_stopped == 1) return -1;

            ReadDeviceBit(device, bitLoc, out int val);
            if (val == expectedValue)
                return 0;

            Thread.Sleep(100);
        }
        AddLog($"WaitSignalBit TIMEOUT: {device} bit={bitLoc} expected={expectedValue} waitMs={waitTimeMs}");
        return -1;
    }

    // =========================================================================
    // PulseDevice / PulseDeviceBit
    // =========================================================================

    /// <summary>
    /// Writes 1, waits delay, writes 0 (fire and forget on Task.Run).
    /// <para>Delphi origin: procedure PulseDevice (line 4443)</para>
    /// </summary>
    private void PulseDevice(string device, int delayMs)
    {
        _ = Task.Run(() =>
        {
            WriteDevice(device, 1);
            Thread.Sleep(delayMs);
            WriteDevice(device, 0);
        });
    }

    /// <summary>
    /// Sets a bit to 1, waits delay, clears to 0 (fire and forget).
    /// For B-device: direct write. For word device: read-modify-write.
    /// <para>Delphi origin: procedure PulseDeviceBit (line 4459)</para>
    /// </summary>
    private void PulseDeviceBit(string device, int bitLoc, int delayMs)
    {
        _ = Task.Run(() =>
        {
            WriteDeviceBit(device, bitLoc, 1);
            Thread.Sleep(delayMs);
            WriteDeviceBit(device, bitLoc, 0);
        });
    }

    // =========================================================================
    // WriteHeatBeat / ReadTimeData
    // =========================================================================

    /// <summary>
    /// Toggles heartbeat bit 0 in the EQP area.
    /// <para>Delphi origin: procedure WriteHeatBeat (line 4735)</para>
    /// </summary>
    private void WriteHeartBeat()
    {
        if (!_opened) return;

        ReadDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x0:X3}", out int val, false);
        int newVal = (val == 0) ? 1 : 0;
        WriteDevice($"B{StartAddrEqp + 0x10 * 0x00 + 0x0:X3}", newVal, false);
    }

    /// <summary>
    /// Reads time data from ECS and synchronizes local clock reference.
    /// <para>Delphi origin: procedure ReadTimeData</para>
    /// </summary>
    private void ReadTimeData()
    {
        // Stub - time sync not critical for C# version
    }

    // =========================================================================
    // String conversion: PLC words <-> ASCII string
    // =========================================================================

    /// <summary>
    /// Converts PLC word array to string (2 ASCII chars per word, little-endian).
    /// <para>Delphi origin: function ConvertStrFromPLC (line 4797)</para>
    /// </summary>
    private static string ConvertStrFromPlc(int charLen, int[] data)
    {
        var sb = new StringBuilder(charLen);
        int wordCount = (charLen + 1) / 2;

        for (int i = 0; i < wordCount; i++)
        {
            int word = data[i];
            char lo = (char)(word & 0xFF);
            char hi = (char)((word >> 8) & 0xFF);

            if (sb.Length < charLen && lo != 0) sb.Append(lo);
            if (sb.Length < charLen && hi != 0) sb.Append(hi);
        }
        return sb.ToString().TrimEnd('\0');
    }

    /// <summary>
    /// Converts string to PLC word array (2 ASCII chars per word, little-endian).
    /// <para>Delphi origin: procedure ConvertStrToPLC (line 4833)</para>
    /// </summary>
    private static void ConvertStrToPlc(string data, int charLen, int[] output)
    {
        // Pad the string to the required length
        string padded = data.PadRight(charLen, '\0');
        int wordCount = (charLen + 1) / 2;

        for (int i = 0; i < wordCount; i++)
        {
            int idx = i * 2;
            int lo = (idx < padded.Length) ? (byte)padded[idx] : 0;
            int hi = (idx + 1 < padded.Length) ? (byte)padded[idx + 1] : 0;
            output[i] = lo + (hi << 8); // Ord(c1) + Ord(c2)*256
        }
    }
}
