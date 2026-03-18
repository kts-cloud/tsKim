// =============================================================================
// PlcEcsDriver.Simulator.cs  (partial)
// Simulator monitoring loop + auto-response handlers.
// Monitors EQP area for bit changes and responds in Robot/ECS areas,
// simulating the actual PLC/Robot/ECS host behavior.
//
// Delphi origin: PlcSimluateForm.pas Thread_Monitoring + Process_* handlers
// =============================================================================

namespace Dongaeltek.ITOLED.Hardware.Plc;

public sealed partial class PlcEcsDriver
{
    // =========================================================================
    // Simulator monitoring fields
    // =========================================================================

    private Task? _simMonitoringTask;
    private volatile bool _simAutoStart;
    private int[] _simEqpPre = Array.Empty<int>(); // EQP snapshot for change detection

    // =========================================================================
    // Simulator public control (called from PlcSimulatePage)
    // =========================================================================

    /// <summary>Auto Start mode: triggers Inspection Start after Load Complete.</summary>
    public bool SimAutoStart
    {
        get => _simAutoStart;
        set => _simAutoStart = value;
    }

    /// <summary>
    /// Injects a bit value directly into simulator memory (for UI event injection).
    /// </summary>
    public void SimInjectBit(string device, int value)
    {
        if (!UseSimulator || _simMemory is null) return;
        _simMemory.SetDevice(device, value);
        AddLog($"[Simulator] Inject: {device} = {value}");
    }

    // =========================================================================
    // Simulator monitoring loop
    // =========================================================================

    /// <summary>
    /// Starts the simulator monitoring loop (EQP bit change detection + auto-response).
    /// Called from Start() when UseSimulator=true.
    /// </summary>
    private void StartSimulatorMonitoring(CancellationToken ct)
    {
        _simEqpPre = new int[_eqpDataSize];
        _simMonitoringTask = Task.Run(() => SimMonitoringLoop(ct));
    }

    /// <summary>
    /// Main monitoring loop: reads packed EQP words every 200ms,
    /// detects bit changes, and dispatches to appropriate handler.
    /// Delphi origin: PlcSimluateForm.Thread_Monitoring
    /// </summary>
    private void SimMonitoringLoop(CancellationToken ct)
    {
        var current = new int[_eqpDataSize];
        AddLog("[Simulator] Monitoring loop started");

        while (!ct.IsCancellationRequested)
        {
            try
            {
                Thread.Sleep(200); // 200ms monitoring interval (Delphi: 200ms)

                // Read EQP area snapshot (packed words)
                _simMemory!.ReadBRange(StartAddrEqp, _eqpDataSize, current);

                // Detect changes
                for (int word = 0; word < _eqpDataSize; word++)
                {
                    if (current[word] == _simEqpPre[word]) continue;

                    for (int bit = 0; bit <= 15; bit++)
                    {
                        int cur = GetBit(current[word], bit);
                        int pre = GetBit(_simEqpPre[word], bit);
                        if (cur == pre) continue;

                        // Dispatch to simulator process handler
                        SimProcessEqpBit(word, bit, cur);
                    }
                    _simEqpPre[word] = current[word];
                }
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex)
            {
                _logger.Error("[Simulator] Monitoring error", ex);
                Thread.Sleep(1000);
            }
        }

        AddLog("[Simulator] Monitoring loop exited");
    }

    // =========================================================================
    // EQP bit change dispatch
    // =========================================================================

    /// <summary>
    /// Dispatches EQP bit changes to appropriate simulator handler.
    /// Word/bit are relative to the EQP area start.
    /// Delphi origin: Process_Monitoring_EQP
    /// </summary>
    private void SimProcessEqpBit(int word, int bit, int value)
    {
        var (lb, ub) = GetLoadUnloadBases();

        // ── Robot interlock: Load/Unload per channel ──
        for (int ch = 0; ch < 4; ch++)
        {
            int lw = lb + ch * 2; // Load word for this channel
            int uw = ub + ch * 2; // Unload word for this channel

            if (word == lw)
            {
                // Load Enable ON
                if (bit == 0x0 && value != 0) { SimProcessLoadEnable(ch); return; }
                // Glass Data Request ON
                if (bit == 0x1 && value != 0) { SimProcessLoadGlassData(ch); return; }
                // Load Complete Confirm ON
                if (bit == 0x6 && value != 0) { SimProcessLoadCompleteConfirm(ch); return; }
                // Inspection Start Confirm ON
                if (bit == 0xD && value != 0) { SimProcessInspectionStartConfirm(ch); return; }
            }

            if (word == uw)
            {
                // Unload Enable ON
                if (bit == 0x0 && value != 0) { SimProcessUnloadEnable(ch); return; }
                // Unload Complete Confirm ON
                if (bit == 0x6 && value != 0) { SimProcessUnloadCompleteConfirm(ch); return; }
            }
        }

        // ── ECS protocol bits (in EQP area, low words) ──

        // Link Test: EQP word 3, bit 0  (address offset 0x30)
        if (word == 0x03 && bit == 0x0 && value != 0) { SimProcessLinkTest(); return; }

        // PCHK: EQP word 6, bits 0-3  (address offset 0x60+ch)
        if (word == 0x06 && bit <= 0x3 && value != 0) { SimProcessPchk(bit); return; }

        // EICR: EQP word 6, bits 4-7  (address offset 0x64+ch)
        if (word == 0x06 && bit >= 0x4 && bit <= 0x7 && value != 0) { SimProcessEicr(bit - 4); return; }
    }

    // =========================================================================
    // Helper: resolve Robot bit address (handles StartAddrRobot2 for ch >= 2)
    // =========================================================================

    private int SimRobotBitAddr(int ch, int bitOffset)
    {
        if (StartAddrRobot2 != 0 && ch >= 2)
            return StartAddrRobot2 + (ch - 2) * 0x20 + bitOffset;
        return StartAddrRobot + ch * 0x20 + bitOffset;
    }

    // =========================================================================
    // Process handlers: Robot Load cycle
    // =========================================================================

    /// <summary>
    /// Load Enable detected: set Robot Busy, then Load Complete after delay.
    /// Simulates robot arm picking up glass and placing it on stage.
    /// </summary>
    private void SimProcessLoadEnable(int ch)
    {
        AddLog($"[Simulator] Load Enable CH{ch}");

        // Clear Load Noninterference (robot is now busy)
        _simMemory!.SetB(SimRobotBitAddr(ch, 0x04), 0);
        // Set Robot Load Busy
        _simMemory.SetB(SimRobotBitAddr(ch, 0x02), 1);

        // After delay, set Load Complete
        _ = Task.Run(async () =>
        {
            await Task.Delay(500);
            if (_stopped != 0) return;
            _simMemory.SetB(SimRobotBitAddr(ch, 0x03), 1);
            AddLog($"[Simulator] Load Complete CH{ch}");
        });
    }

    /// <summary>
    /// Glass Data Request detected: write fake glass data to W area, set Glass Data Report.
    /// </summary>
    private void SimProcessLoadGlassData(int ch)
    {
        AddLog($"[Simulator] Glass Data Request CH{ch}");

        // Generate and write fake glass data
        if (InlineGib)
        {
            var glassWords = SimGenerateFakeGlassData(ch);
            _simMemory!.WriteWBlock(StartAddrRobotW + ch * 0x40, glassWords, 64);
        }
        else
        {
            // Non-GIB: 2 panels per robot arm (128 words = 2 x 64)
            int wBase;
            if (ch == 1 && StartAddrRobotW2 != 0)
                wBase = StartAddrRobotW2;
            else
                wBase = StartAddrRobotW + ch * 0x80;

            var panel1 = SimGenerateFakeGlassData(ch * 2);
            var panel2 = SimGenerateFakeGlassData(ch * 2 + 1);
            _simMemory!.WriteWBlock(wBase, panel1, 64);
            _simMemory.WriteWBlock(wBase + 0x40, panel2, 64);
        }

        // Set Glass Data Report bit in Robot area (after short delay)
        _ = Task.Run(async () =>
        {
            await Task.Delay(300);
            if (_stopped != 0) return;
            _simMemory!.SetB(SimRobotBitAddr(ch, 0x01), 1);
            AddLog($"[Simulator] Glass Data Report ON CH{ch}");
        });
    }

    /// <summary>
    /// Load Complete Confirm detected: clear Load Complete, set Noninterference, clear Busy.
    /// Optionally triggers AutoStart (Inspection Start).
    /// </summary>
    private void SimProcessLoadCompleteConfirm(int ch)
    {
        AddLog($"[Simulator] Load Complete Confirm CH{ch}");

        // Clear Load Complete
        _simMemory!.SetB(SimRobotBitAddr(ch, 0x03), 0);
        // Clear Glass Data Report
        _simMemory.SetB(SimRobotBitAddr(ch, 0x01), 0);

        _ = Task.Run(async () =>
        {
            await Task.Delay(500);
            if (_stopped != 0) return;

            // Set Load Noninterference
            _simMemory.SetB(SimRobotBitAddr(ch, 0x04), 1);

            await Task.Delay(1000);
            if (_stopped != 0) return;

            // Clear Robot Load Busy
            _simMemory.SetB(SimRobotBitAddr(ch, 0x02), 0);

            // AutoStart: trigger Inspection Start after delay
            if (_simAutoStart)
            {
                await Task.Delay(2000);
                if (_stopped != 0) return;
                _simMemory.SetB(SimRobotBitAddr(ch, 0x0D), 1);
                AddLog($"[Simulator] AutoStart: Inspection Start CH{ch}");
            }
        });
    }

    // =========================================================================
    // Process handlers: Robot Unload cycle
    // =========================================================================

    /// <summary>
    /// Unload Enable detected: set Robot Busy, then Unload Complete after delay.
    /// </summary>
    private void SimProcessUnloadEnable(int ch)
    {
        AddLog($"[Simulator] Unload Enable CH{ch}");

        // Clear Unload Noninterference
        _simMemory!.SetB(SimRobotBitAddr(ch, 0x14), 0);
        // Set Robot Unload Busy
        _simMemory.SetB(SimRobotBitAddr(ch, 0x12), 1);

        _ = Task.Run(async () =>
        {
            await Task.Delay(500);
            if (_stopped != 0) return;
            _simMemory.SetB(SimRobotBitAddr(ch, 0x13), 1); // Unload Complete
            AddLog($"[Simulator] Unload Complete CH{ch}");
        });
    }

    /// <summary>
    /// Unload Complete Confirm detected: clear Unload Complete, set Noninterference, clear Busy.
    /// </summary>
    private void SimProcessUnloadCompleteConfirm(int ch)
    {
        AddLog($"[Simulator] Unload Complete Confirm CH{ch}");

        // Clear Unload Complete
        _simMemory!.SetB(SimRobotBitAddr(ch, 0x13), 0);

        _ = Task.Run(async () =>
        {
            await Task.Delay(500);
            if (_stopped != 0) return;
            // Set Unload Noninterference
            _simMemory.SetB(SimRobotBitAddr(ch, 0x14), 1);
            // Clear Robot Unload Busy
            _simMemory.SetB(SimRobotBitAddr(ch, 0x12), 0);
        });
    }

    /// <summary>
    /// Inspection Start Confirm detected: clear Inspection Start bit.
    /// </summary>
    private void SimProcessInspectionStartConfirm(int ch)
    {
        AddLog($"[Simulator] Inspection Start Confirm CH{ch}");
        _simMemory!.SetB(SimRobotBitAddr(ch, 0x0D), 0);
    }

    // =========================================================================
    // Process handlers: ECS protocol simulation
    // =========================================================================

    /// <summary>
    /// ECS Link Test detected: pulse response bit in ECS area.
    /// </summary>
    private void SimProcessLinkTest()
    {
        AddLog("[Simulator] ECS Link Test");

        // Set the link test response bit in ECS area
        int linkTestBit = InlineGib ? (EqpId + 10) % 16 : (EqpId + 13) % 16;

        _ = Task.Run(async () =>
        {
            _simMemory!.SetB(StartAddrEcs + linkTestBit, 1);
            await Task.Delay(3000);
            _simMemory.SetB(StartAddrEcs + linkTestBit, 0);
        });
    }

    /// <summary>
    /// ECS PCHK (BCR reading data report) detected: write fake glass data, set confirm bit.
    /// </summary>
    private void SimProcessPchk(int ch)
    {
        AddLog($"[Simulator] ECS PCHK CH{ch}");

        // Generate fake glass data and write to ECS W area
        var glassWords = SimGenerateFakeGlassData(ch);
        _simMemory!.WriteWBlock(StartAddrEcsW, glassWords, Math.Min(64, glassWords.Length));

        // Set BCR Data Confirm bit (at ECS area + appropriate offset)
        _ = Task.Run(async () =>
        {
            await Task.Delay(300);
            if (_stopped != 0) return;
            // Response bit: StartAddrEcs + 0x60 + ch (same word/bit as request, in ECS area)
            _simMemory.SetB(StartAddrEcs + 0x60 + ch, 1);
        });
    }

    /// <summary>
    /// ECS EICR (inspection data confirm) detected: set confirm bit.
    /// </summary>
    private void SimProcessEicr(int ch)
    {
        AddLog($"[Simulator] ECS EICR CH{ch}");

        _ = Task.Run(async () =>
        {
            await Task.Delay(300);
            if (_stopped != 0) return;
            // Response bit: StartAddrEcs + 0x64 + ch
            _simMemory.SetB(StartAddrEcs + 0x64 + ch, 1);
        });
    }

    // =========================================================================
    // Fake glass data generator
    // =========================================================================

    /// <summary>
    /// Generates 64 words of fake glass data for simulator mode.
    /// Delphi origin: ConvertGlassDataToBlock with dummy data.
    /// </summary>
    private int[] SimGenerateFakeGlassData(int panelIndex)
    {
        var data = new int[64];

        // CarrierId: 8 words = 16 chars (index 0-7)
        SimConvertStrToPlcWords("SIM_LOT_12345678", 16, data, 0);

        // ProcessingCode: 4 words = 8 chars (index 8-11)
        SimConvertStrToPlcWords("SIMCODE1", 8, data, 8);

        // LotSpecificData: 4 words (index 12-15) — zeros

        // RecipeNumber (index 16), GlassType (index 17), GlassCode (index 18)
        data[16] = 1; // RecipeNumber
        data[17] = 0; // GlassType
        data[18] = 0; // GlassCode

        // GlassId: 8 words = 16 chars (index 19-26)
        SimConvertStrToPlcWords($"SIM_GLS_ID_{panelIndex:D4} ", 16, data, 19);

        // GlassJudge (index 27): 'G' = 0x47 with $2000 offset
        data[27] = 0x2047;

        // GlassSpecificData: 4 words (index 28-31) — zeros
        // PreviousUnitProcessing: 8 words (index 32-39) — zeros
        // GlassProcessingStatus: 8 words (index 40-47) — zeros
        // MateriId: 15 words = 30 chars (index 48-62) — leave as zeros
        // PcztCode (index 63) — zero

        return data;
    }

    /// <summary>
    /// Converts a string to PLC word format and writes into data array at specified offset.
    /// </summary>
    private static void SimConvertStrToPlcWords(string value, int charLen, int[] output, int startIndex)
    {
        string padded = value.PadRight(charLen, '\0');
        int wordCount = (charLen + 1) / 2;

        for (int i = 0; i < wordCount && (startIndex + i) < output.Length; i++)
        {
            int idx = i * 2;
            int lo = idx < padded.Length ? (byte)padded[idx] : 0;
            int hi = (idx + 1) < padded.Length ? (byte)padded[idx + 1] : 0;
            output[startIndex + i] = lo + (hi << 8);
        }
    }
}
