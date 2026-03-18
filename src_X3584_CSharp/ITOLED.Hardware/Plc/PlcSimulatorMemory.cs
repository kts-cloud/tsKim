// =============================================================================
// PlcSimulatorMemory.cs
// In-memory PLC memory model for simulator mode.
// B-device: bit-level storage (each address = one bit, 0 or 1).
//           ReadBlock packs 16 consecutive bits into each word (Mitsubishi behavior).
// W-device: word-level storage (each address = one 16-bit word).
// D-device: double-word storage (each address = one 32-bit value).
//
// Delphi origin: PlcSimluateForm.pas Memory_B0/W0/D0 arrays.
// =============================================================================

namespace Dongaeltek.ITOLED.Hardware.Plc;

/// <summary>
/// In-memory PLC memory model for simulator mode.
/// Thread-safe via a single lock object.
/// </summary>
public sealed class PlcSimulatorMemory
{
    private const int MemorySize = 0x10000; // 65536 — covers B0000-BFFFF, W0000-WFFFF

    private readonly int[] _memoryB = new int[MemorySize]; // Bit storage (0 or 1 per address)
    private readonly int[] _memoryW = new int[MemorySize]; // Word storage (16-bit per address)
    private readonly int[] _memoryD = new int[MemorySize]; // Double-word storage
    private readonly object _lock = new();

    // =========================================================================
    // Single device read/write (maps to ReadDevice / WriteDevice)
    // =========================================================================

    /// <summary>
    /// Reads a single PLC device value.
    /// B-device returns the bit value (0 or 1).
    /// W/D-device returns the word/dword value.
    /// </summary>
    public int GetDevice(string device)
    {
        lock (_lock)
        {
            var (mem, addr) = ParseDevice(device);
            return (addr >= 0 && addr < mem.Length) ? mem[addr] : 0;
        }
    }

    /// <summary>
    /// Writes a single PLC device value.
    /// B-device stores 0 or 1 at the bit address.
    /// W/D-device stores the full value.
    /// </summary>
    public void SetDevice(string device, int value)
    {
        lock (_lock)
        {
            var (mem, addr) = ParseDevice(device);
            if (addr >= 0 && addr < mem.Length)
                mem[addr] = value;
        }
    }

    // =========================================================================
    // Block read/write (maps to ReadDeviceBlock / WriteDeviceBlock)
    // Mitsubishi B-device: packs 16 consecutive bits into each returned word.
    // =========================================================================

    /// <summary>
    /// Reads a block of PLC devices.
    /// For B-device: reads <paramref name="size"/> packed words, each = 16 consecutive bits.
    /// For W/D-device: reads <paramref name="size"/> consecutive values.
    /// </summary>
    public void ReadBlock(string device, int size, int[] data)
    {
        lock (_lock)
        {
            char type = GetDeviceType(device);
            int baseAddr = GetDeviceAddress(device);

            if (type == 'B' || type == 'M')
            {
                // B-device: pack 16 consecutive bits into each word
                int[] mem = _memoryB;
                for (int w = 0; w < size; w++)
                {
                    int word = 0;
                    for (int b = 0; b < 16; b++)
                    {
                        int addr = baseAddr + w * 16 + b;
                        if (addr >= 0 && addr < mem.Length && mem[addr] != 0)
                            word |= (1 << b);
                    }
                    data[w] = word;
                }
            }
            else
            {
                // W/D-device: read consecutive values
                int[] mem = (type == 'D') ? _memoryD : _memoryW;
                for (int i = 0; i < size; i++)
                {
                    int addr = baseAddr + i;
                    data[i] = (addr >= 0 && addr < mem.Length) ? mem[addr] : 0;
                }
            }
        }
    }

    /// <summary>
    /// Writes a block of PLC devices.
    /// For B-device: unpacks 16 bits per word into individual bit addresses.
    /// For W/D-device: writes consecutive values.
    /// </summary>
    public void WriteBlock(string device, int size, int[] data)
    {
        lock (_lock)
        {
            char type = GetDeviceType(device);
            int baseAddr = GetDeviceAddress(device);

            if (type == 'B' || type == 'M')
            {
                // B-device: unpack 16 bits per word into individual bits
                for (int w = 0; w < size; w++)
                {
                    for (int b = 0; b < 16; b++)
                    {
                        int addr = baseAddr + w * 16 + b;
                        if (addr >= 0 && addr < _memoryB.Length)
                            _memoryB[addr] = (data[w] >> b) & 1;
                    }
                }
            }
            else
            {
                int[] mem = (type == 'D') ? _memoryD : _memoryW;
                for (int i = 0; i < size; i++)
                {
                    int addr = baseAddr + i;
                    if (addr >= 0 && addr < mem.Length)
                        mem[addr] = data[i];
                }
            }
        }
    }

    // =========================================================================
    // Direct B-array access (for simulator monitoring + handlers)
    // =========================================================================

    /// <summary>Sets a single B-device bit value directly by address.</summary>
    public void SetB(int addr, int value)
    {
        lock (_lock)
        {
            if (addr >= 0 && addr < _memoryB.Length)
                _memoryB[addr] = value;
        }
    }

    /// <summary>Gets a single B-device bit value directly by address.</summary>
    public int GetB(int addr)
    {
        lock (_lock)
        {
            return (addr >= 0 && addr < _memoryB.Length) ? _memoryB[addr] : 0;
        }
    }

    /// <summary>
    /// Reads packed words from B-array for EQP area monitoring.
    /// Each word = 16 consecutive bits packed into a 16-bit value.
    /// <paramref name="startAddr"/> is the bit-level base address.
    /// </summary>
    public void ReadBRange(int startAddr, int wordCount, int[] dest)
    {
        lock (_lock)
        {
            for (int w = 0; w < wordCount; w++)
            {
                int word = 0;
                for (int b = 0; b < 16; b++)
                {
                    int addr = startAddr + w * 16 + b;
                    if (addr >= 0 && addr < _memoryB.Length && _memoryB[addr] != 0)
                        word |= (1 << b);
                }
                dest[w] = word;
            }
        }
    }

    /// <summary>W-memory block write (for glass data injection).</summary>
    public void WriteWBlock(int startAddr, int[] data, int count)
    {
        lock (_lock)
        {
            for (int i = 0; i < count && (startAddr + i) < _memoryW.Length; i++)
                _memoryW[startAddr + i] = data[i];
        }
    }

    // =========================================================================
    // Device string parsing
    // =========================================================================

    private static char GetDeviceType(string device)
    {
        if (string.IsNullOrEmpty(device) || device.Length < 2) return 'B';
        return char.ToUpper(device[0]);
    }

    private static int GetDeviceAddress(string device)
    {
        if (string.IsNullOrEmpty(device) || device.Length < 2) return 0;
        char type = char.ToUpper(device[0]);
        string addrStr = device[1..];

        try
        {
            return type switch
            {
                'D' => int.TryParse(addrStr, out int dec) ? dec : 0,
                _ => Convert.ToInt32(addrStr, 16) // B, W, M are hex
            };
        }
        catch
        {
            return 0;
        }
    }

    private (int[] mem, int addr) ParseDevice(string device)
    {
        if (string.IsNullOrEmpty(device) || device.Length < 2)
            return (_memoryB, 0);

        char type = char.ToUpper(device[0]);
        string addrStr = device[1..];

        try
        {
            return type switch
            {
                'B' => (_memoryB, Convert.ToInt32(addrStr, 16)),
                'W' => (_memoryW, Convert.ToInt32(addrStr, 16)),
                'D' => (_memoryD, int.TryParse(addrStr, out int d) ? d : 0),
                'M' => (_memoryB, Convert.ToInt32(addrStr, 16)),
                _ => (_memoryB, 0)
            };
        }
        catch
        {
            return (_memoryB, 0);
        }
    }
}
