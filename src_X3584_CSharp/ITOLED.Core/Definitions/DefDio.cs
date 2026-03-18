// DefDio.cs
// Converted from Delphi: src_X3584\DefDio.pas
// DIO (Digital I/O) signal definitions for the ITOLED OC inspection system.
// Build target: INSPECTOR_OC (96-channel configuration)

namespace Dongaeltek.ITOLED.Core.Definitions
{
    /// <summary>
    /// DAE DIO device configuration constants.
    /// </summary>
    public static class DioConfig
    {
        // ----- DAE DIO I/O counts (INSPECTOR_OC = 96-channel) -----

        /// <summary>Maximum total I/O count.</summary>
        public const int MaxIoCnt = 96;

        /// <summary>Maximum input channel count.</summary>
        public const int MaxInCnt = 96;

        /// <summary>Maximum output channel count.</summary>
        public const int MaxOutCnt = 96;

        // ----- DAE DIO device connection -----

        /// <summary>DAE I/O device IP address.</summary>
        public const string DaeIoDeviceIp = "192.168.0.99";

        /// <summary>DAE I/O device TCP port.</summary>
        public const int DaeIoDevicePort = 6989;

        /// <summary>DAE I/O device polling interval (ms).</summary>
        public const int DaeIoDeviceInterval = 200;

        /// <summary>DAE I/O device count (INSPECTOR_OC = 12 devices).</summary>
        public const int DaeIoDeviceCount = 12;
    }

    /// <summary>
    /// Inspector type constants.
    /// </summary>
    public static class InspectorType
    {
        /// <summary>Normal inspector type.</summary>
        public const int TypeNormal = 0;

        /// <summary>GIB inspector type.</summary>
        public const int TypeGib = 1;
    }

    /// <summary>
    /// Channel selection constants.
    /// </summary>
    public static class ChannelSelect
    {
        /// <summary>All channels.</summary>
        public const int AllCh = 0;

        /// <summary>Top channel only.</summary>
        public const int TopCh = 1;

        /// <summary>Bottom channel only.</summary>
        public const int BottomCh = 2;
    }

    // =========================================================================
    //  OC (128-channel) Input Signal Definitions
    // =========================================================================

    /// <summary>
    /// DIO input signal index constants for the OC (128-channel) configuration.
    /// </summary>
    public static class DioInput
    {
        // ----- Fan Signals (0..7) -----

        /// <summary>FAN 1 exhaust signal. Normal: High, Fault: Low.</summary>
        public const int Fan1Exhaust = 0;

        /// <summary>FAN 2 intake signal. Normal: High, Fault: Low.</summary>
        public const int Fan2Intake = 1;

        /// <summary>FAN 3 exhaust signal. Normal: High, Fault: Low.</summary>
        public const int Fan3Exhaust = 2;

        /// <summary>FAN 4 intake signal. Normal: High, Fault: Low.</summary>
        public const int Fan4Intake = 3;

        /// <summary>Undefined input 4.</summary>
        public const int Undefined4 = 4;

        /// <summary>Undefined input 5.</summary>
        public const int Undefined5 = 5;

        /// <summary>Undefined input 6.</summary>
        public const int Undefined6 = 6;

        /// <summary>Undefined input 7.</summary>
        public const int Undefined7 = 7;

        // ----- Safety / Door Signals (8..15) -----

        /// <summary>EMO switch. EMO OFF: High, Fault: Low.</summary>
        public const int EmoSwitch = 8;

        /// <summary>CH 1-2 left door open sensor. Open: Low, Closed: High.</summary>
        public const int Ch12DoorLeftOpen = 9;

        /// <summary>CH 1-2 right door open sensor. Open: Low, Closed: High.</summary>
        public const int Ch12DoorRightOpen = 10;

        /// <summary>CH 3-4 left door open sensor. Open: Low, Closed: High.</summary>
        public const int Ch34DoorLeftOpen = 11;

        /// <summary>CH 3-4 right door open sensor. Open: Low, Closed: High.</summary>
        public const int Ch34DoorRightOpen = 12;

        /// <summary>MC monitoring. High: normal, Low on EMO/door fault.</summary>
        public const int McMonitoring = 13;

        /// <summary>Undefined input 14.</summary>
        public const int Undefined14 = 14;

        /// <summary>Undefined input 15.</summary>
        public const int Undefined15 = 15;

        // ----- Temperature / Misc (16..23) -----

        /// <summary>Temperature alarm. High when over 40 degrees.</summary>
        public const int TemperatureAlarm = 16;

        /// <summary>Undefined input 17.</summary>
        public const int Undefined17 = 17;

        /// <summary>Undefined input 18.</summary>
        public const int Undefined18 = 18;

        /// <summary>Undefined input 19.</summary>
        public const int Undefined19 = 19;

        /// <summary>Undefined input 20.</summary>
        public const int Undefined20 = 20;

        /// <summary>Undefined input 21.</summary>
        public const int Undefined21 = 21;

        /// <summary>Undefined input 22.</summary>
        public const int Undefined22 = 22;

        /// <summary>Undefined input 23.</summary>
        public const int Undefined23 = 23;

        // ----- Pressure (24..31) -----

        /// <summary>Cylinder pressure gauge sensor.</summary>
        public const int CylPressureGauge = 24;

        /// <summary>Undefined input 25.</summary>
        public const int Undefined25 = 25;

        /// <summary>Undefined input 26.</summary>
        public const int Undefined26 = 26;

        /// <summary>Undefined input 27.</summary>
        public const int Undefined27 = 27;

        /// <summary>Undefined input 28.</summary>
        public const int Undefined28 = 28;

        /// <summary>Undefined input 29.</summary>
        public const int Undefined29 = 29;

        /// <summary>Undefined input 30.</summary>
        public const int Undefined30 = 30;

        /// <summary>Undefined input 31.</summary>
        public const int Undefined31 = 31;

        // ----- CH1 Carrier / Probe Sensors (32..47) -----

        /// <summary>CH 1 carrier presence sensor.</summary>
        public const int Ch1CarrierSensor = 32;

        /// <summary>CH 1 probe forward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch1ProbeForwardSensor = 33;

        /// <summary>CH 1 probe backward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch1ProbeBackwardSensor = 34;

        /// <summary>CH 1 probe up sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch1ProbeUpSensor = 35;

        /// <summary>CH 1 probe down sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch1ProbeDownSensor = 36;

        /// <summary>Undefined input 37.</summary>
        public const int Undefined37 = 37;

        /// <summary>Undefined input 38.</summary>
        public const int Undefined38 = 38;

        /// <summary>Undefined input 39.</summary>
        public const int Undefined39 = 39;

        /// <summary>CH 1 carrier unlock sensor 1.</summary>
        public const int Ch1CarrierUnlockSensor1 = 40;

        /// <summary>CH 1 carrier lock sensor 1.</summary>
        public const int Ch1CarrierLock1 = 41;

        /// <summary>CH 1 carrier unlock sensor 2.</summary>
        public const int Ch1CarrierUnlockSensor2 = 42;

        /// <summary>CH 1 carrier lock sensor 2.</summary>
        public const int Ch1CarrierLock2 = 43;

        /// <summary>CH 1 carrier unlock sensor 3.</summary>
        public const int Ch1CarrierUnlockSensor3 = 44;

        /// <summary>CH 1 carrier lock sensor 3.</summary>
        public const int Ch1CarrierLock3 = 45;

        /// <summary>CH 1 carrier unlock sensor 4.</summary>
        public const int Ch1CarrierUnlockSensor4 = 46;

        /// <summary>CH 1 carrier lock sensor 4.</summary>
        public const int Ch1CarrierLock4 = 47;

        // ----- CH2 Carrier / Probe Sensors (48..63) -----

        /// <summary>CH 2 carrier presence sensor.</summary>
        public const int Ch2CarrierSensor = 48;

        /// <summary>CH 2 probe forward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch2ProbeForwardSensor = 49;

        /// <summary>CH 2 probe backward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch2ProbeBackwardSensor = 50;

        /// <summary>CH 2 probe up sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch2ProbeUpSensor = 51;

        /// <summary>CH 2 probe down sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch2ProbeDownSensor = 52;

        /// <summary>Undefined input 53.</summary>
        public const int Undefined53 = 53;

        /// <summary>Undefined input 54.</summary>
        public const int Undefined54 = 54;

        /// <summary>Undefined input 55.</summary>
        public const int Undefined55 = 55;

        /// <summary>CH 2 carrier unlock sensor 1.</summary>
        public const int Ch2CarrierUnlockSensor1 = 56;

        /// <summary>CH 2 carrier lock sensor 1.</summary>
        public const int Ch2CarrierLock1 = 57;

        /// <summary>CH 2 carrier unlock sensor 2.</summary>
        public const int Ch2CarrierUnlockSensor2 = 58;

        /// <summary>CH 2 carrier lock sensor 2.</summary>
        public const int Ch2CarrierLock2 = 59;

        /// <summary>CH 2 carrier unlock sensor 3.</summary>
        public const int Ch2CarrierUnlockSensor3 = 60;

        /// <summary>CH 2 carrier lock sensor 3.</summary>
        public const int Ch2CarrierLock3 = 61;

        /// <summary>CH 2 carrier unlock sensor 4.</summary>
        public const int Ch2CarrierUnlockSensor4 = 62;

        /// <summary>CH 2 carrier lock sensor 4.</summary>
        public const int Ch2CarrierLock4 = 63;

        // ----- CH3 Carrier / Probe Sensors (64..79) -----

        /// <summary>CH 3 carrier presence sensor.</summary>
        public const int Ch3CarrierSensor = 64;

        /// <summary>CH 3 probe forward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch3ProbeForwardSensor = 65;

        /// <summary>CH 3 probe backward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch3ProbeBackwardSensor = 66;

        /// <summary>CH 3 probe up sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch3ProbeUpSensor = 67;

        /// <summary>CH 3 probe down sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch3ProbeDownSensor = 68;

        /// <summary>Undefined input 69.</summary>
        public const int Undefined69 = 69;

        /// <summary>Undefined input 70.</summary>
        public const int Undefined70 = 70;

        /// <summary>Undefined input 71.</summary>
        public const int Undefined71 = 71;

        /// <summary>CH 3 carrier unlock sensor 1.</summary>
        public const int Ch3CarrierUnlockSensor1 = 72;

        /// <summary>CH 3 carrier lock sensor 1.</summary>
        public const int Ch3CarrierLock1 = 73;

        /// <summary>CH 3 carrier unlock sensor 2.</summary>
        public const int Ch3CarrierUnlockSensor2 = 74;

        /// <summary>CH 3 carrier lock sensor 2.</summary>
        public const int Ch3CarrierLock2 = 75;

        /// <summary>CH 3 carrier unlock sensor 3.</summary>
        public const int Ch3CarrierUnlockSensor3 = 76;

        /// <summary>CH 3 carrier lock sensor 3.</summary>
        public const int Ch3CarrierLock3 = 77;

        /// <summary>CH 3 carrier unlock sensor 4.</summary>
        public const int Ch3CarrierUnlockSensor4 = 78;

        /// <summary>CH 3 carrier lock sensor 4.</summary>
        public const int Ch3CarrierLock4 = 79;

        // ----- CH4 Carrier / Probe Sensors (80..95) -----

        /// <summary>CH 4 carrier presence sensor.</summary>
        public const int Ch4CarrierSensor = 80;

        /// <summary>CH 4 probe forward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch4ProbeForwardSensor = 81;

        /// <summary>CH 4 probe backward sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch4ProbeBackwardSensor = 82;

        /// <summary>CH 4 probe up sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch4ProbeUpSensor = 83;

        /// <summary>CH 4 probe down sensor. Sensor detected: Low, Not detected: High.</summary>
        public const int Ch4ProbeDownSensor = 84;

        /// <summary>Undefined input 85.</summary>
        public const int Undefined85 = 85;

        /// <summary>Undefined input 86.</summary>
        public const int Undefined86 = 86;

        /// <summary>Undefined input 87.</summary>
        public const int Undefined87 = 87;

        /// <summary>CH 4 carrier unlock sensor 1.</summary>
        public const int Ch4CarrierUnlockSensor1 = 88;

        /// <summary>CH 4 carrier lock sensor 1.</summary>
        public const int Ch4CarrierLock1 = 89;

        /// <summary>CH 4 carrier unlock sensor 2.</summary>
        public const int Ch4CarrierUnlockSensor2 = 90;

        /// <summary>CH 4 carrier lock sensor 2.</summary>
        public const int Ch4CarrierLock2 = 91;

        /// <summary>CH 4 carrier unlock sensor 3.</summary>
        public const int Ch4CarrierUnlockSensor3 = 92;

        /// <summary>CH 4 carrier lock sensor 3.</summary>
        public const int Ch4CarrierLock3 = 93;

        /// <summary>CH 4 carrier unlock sensor 4.</summary>
        public const int Ch4CarrierUnlockSensor4 = 94;

        /// <summary>CH 4 carrier lock sensor 4.</summary>
        public const int Ch4CarrierLock4 = 95;

        /// <summary>Maximum input signal index (= Ch4CarrierLock4).</summary>
        public const int Max = Ch4CarrierLock4;
    }

    // =========================================================================
    //  OC (128-channel) Output Signal Definitions
    // =========================================================================

    /// <summary>
    /// DIO output signal index constants for the OC (128-channel) configuration.
    /// </summary>
    public static class DioOutput
    {
        // ----- Lamp / PG Power / LED (0..7) -----

        /// <summary>CH 1-2 lamp off signal.</summary>
        public const int Ch12LampOff = 0;

        /// <summary>CH 3-4 lamp off signal.</summary>
        public const int Ch34LampOff = 1;

        /// <summary>CH 1 PG power off signal.</summary>
        public const int Ch1PgPowerOff = 2;

        /// <summary>CH 2 PG power off signal.</summary>
        public const int Ch2PgPowerOff = 3;

        /// <summary>CH 3 PG power off signal.</summary>
        public const int Ch3PgPowerOff = 4;

        /// <summary>CH 4 PG power off signal.</summary>
        public const int Ch4PgPowerOff = 5;

        /// <summary>Undefined output 6.</summary>
        public const int Undefined6 = 6;

        /// <summary>Start switch LED.</summary>
        public const int StartSwLed = 7;

        // ----- Door Unlock / Reset LED (8..15) -----

        /// <summary>CH 1-2 left door unlock solenoid.</summary>
        public const int Ch12DoorLeftUnlock = 8;

        /// <summary>CH 1-2 right door unlock solenoid.</summary>
        public const int Ch12DoorRightUnlock = 9;

        /// <summary>CH 3-4 left door unlock solenoid.</summary>
        public const int Ch34DoorLeftUnlock = 10;

        /// <summary>CH 3-4 right door unlock solenoid.</summary>
        public const int Ch34DoorRightUnlock = 11;

        /// <summary>Reset switch LED.</summary>
        public const int ResetSwitchLed = 12;

        /// <summary>Undefined output 13.</summary>
        public const int Undefined13 = 13;

        /// <summary>Undefined output 14.</summary>
        public const int Undefined14 = 14;

        /// <summary>Undefined output 15.</summary>
        public const int Undefined15 = 15;

        // ----- Tower Lamp / Buzzer (16..23) -----

        /// <summary>Tower lamp red.</summary>
        public const int TowerLampRed = 16;

        /// <summary>Tower lamp yellow.</summary>
        public const int TowerLampYellow = 17;

        /// <summary>Tower lamp green.</summary>
        public const int TowerLampGreen = 18;

        /// <summary>Buzzer 1.</summary>
        public const int Buzzer1 = 19;

        /// <summary>Buzzer 2.</summary>
        public const int Buzzer2 = 20;

        /// <summary>Buzzer 3.</summary>
        public const int Buzzer3 = 21;

        /// <summary>Buzzer 4.</summary>
        public const int Buzzer4 = 22;

        /// <summary>Undefined output 23.</summary>
        public const int Undefined23 = 23;

        // ----- Ion / Back Door Lamp (24..31) -----

        /// <summary>CH 1-2 ionizer on/off solenoid.</summary>
        public const int Ch12IonOnOffSol = 24;

        /// <summary>CH 3-4 ionizer on/off solenoid.</summary>
        public const int Ch34IonOnOffSol = 25;

        /// <summary>CH 1-2 back door lamp on.</summary>
        public const int Ch12BackDoorLampOn = 26;

        /// <summary>CH 3-4 back door lamp on.</summary>
        public const int Ch34BackDoorLampOn = 27;

        /// <summary>Undefined output 28.</summary>
        public const int Undefined28 = 28;

        /// <summary>Undefined output 29.</summary>
        public const int Undefined29 = 29;

        /// <summary>Undefined output 30.</summary>
        public const int Undefined30 = 30;

        /// <summary>Undefined output 31.</summary>
        public const int Undefined31 = 31;

        // ----- CH1 Probe / Carrier Solenoids (32..47) -----

        /// <summary>CH 1 probe forward solenoid.</summary>
        public const int Ch1ProbeForwardSol = 32;

        /// <summary>CH 1 probe backward solenoid.</summary>
        public const int Ch1ProbeBackwardSol = 33;

        /// <summary>CH 1 probe up solenoid.</summary>
        public const int Ch1ProbeUpSol = 34;

        /// <summary>CH 1 probe down solenoid.</summary>
        public const int Ch1ProbeDownSol = 35;

        /// <summary>CH 1 carrier unlock solenoid.</summary>
        public const int Ch1CarrierUnlockSol = 36;

        /// <summary>CH 1 carrier lock solenoid.</summary>
        public const int Ch1CarrierLockSol = 37;

        /// <summary>Undefined output 38.</summary>
        public const int Undefined38 = 38;

        /// <summary>Undefined output 39.</summary>
        public const int Undefined39 = 39;

        /// <summary>CH 1 PMIC laser point.</summary>
        public const int Ch1PmicLaserPoint = 40;

        /// <summary>CH 1 center laser point.</summary>
        public const int Ch1CenterLaserPoint = 41;

        /// <summary>CH 1 PMIC fan on.</summary>
        public const int Ch1PmicFanOn = 42;

        /// <summary>Undefined output 43.</summary>
        public const int Undefined43 = 43;

        /// <summary>Undefined output 44.</summary>
        public const int Undefined44 = 44;

        /// <summary>Undefined output 45.</summary>
        public const int Undefined45 = 45;

        /// <summary>Undefined output 46.</summary>
        public const int Undefined46 = 46;

        /// <summary>Undefined output 47.</summary>
        public const int Undefined47 = 47;

        // ----- CH2 Probe / Carrier Solenoids (48..63) -----

        /// <summary>CH 2 probe forward solenoid.</summary>
        public const int Ch2ProbeForwardSol = 48;

        /// <summary>CH 2 probe backward solenoid.</summary>
        public const int Ch2ProbeBackwardSol = 49;

        /// <summary>CH 2 probe up solenoid.</summary>
        public const int Ch2ProbeUpSol = 50;

        /// <summary>CH 2 probe down solenoid.</summary>
        public const int Ch2ProbeDownSol = 51;

        /// <summary>CH 2 carrier unlock solenoid.</summary>
        public const int Ch2CarrierUnlockSol = 52;

        /// <summary>CH 2 carrier lock solenoid.</summary>
        public const int Ch2CarrierLockSol = 53;

        /// <summary>Undefined output 54.</summary>
        public const int Undefined54 = 54;

        /// <summary>Undefined output 55.</summary>
        public const int Undefined55 = 55;

        /// <summary>CH 2 PMIC laser point.</summary>
        public const int Ch2PmicLaserPoint = 56;

        /// <summary>CH 2 center laser point.</summary>
        public const int Ch2CenterLaserPoint = 57;

        /// <summary>CH 2 PMIC fan on.</summary>
        public const int Ch2PmicFanOn = 58;

        /// <summary>Undefined output 59.</summary>
        public const int Undefined59 = 59;

        /// <summary>Undefined output 60.</summary>
        public const int Undefined60 = 60;

        /// <summary>Undefined output 61.</summary>
        public const int Undefined61 = 61;

        /// <summary>Undefined output 62.</summary>
        public const int Undefined62 = 62;

        /// <summary>Undefined output 63.</summary>
        public const int Undefined63 = 63;

        // ----- CH3 Probe / Carrier Solenoids (64..79) -----

        /// <summary>CH 3 probe forward solenoid.</summary>
        public const int Ch3ProbeForwardSol = 64;

        /// <summary>CH 3 probe backward solenoid.</summary>
        public const int Ch3ProbeBackwardSol = 65;

        /// <summary>CH 3 probe up solenoid.</summary>
        public const int Ch3ProbeUpSol = 66;

        /// <summary>CH 3 probe down solenoid.</summary>
        public const int Ch3ProbeDownSol = 67;

        /// <summary>CH 3 carrier unlock solenoid.</summary>
        public const int Ch3CarrierUnlockSol = 68;

        /// <summary>CH 3 carrier lock solenoid.</summary>
        public const int Ch3CarrierLockSol = 69;

        /// <summary>Undefined output 70.</summary>
        public const int Undefined70 = 70;

        /// <summary>Undefined output 71.</summary>
        public const int Undefined71 = 71;

        /// <summary>CH 3 PMIC laser point.</summary>
        public const int Ch3PmicLaserPoint = 72;

        /// <summary>CH 3 center laser point.</summary>
        public const int Ch3CenterLaserPoint = 73;

        /// <summary>CH 3 PMIC fan on.</summary>
        public const int Ch3PmicFanOn = 74;

        /// <summary>Undefined output 75.</summary>
        public const int Undefined75 = 75;

        /// <summary>Undefined output 76.</summary>
        public const int Undefined76 = 76;

        /// <summary>Undefined output 77.</summary>
        public const int Undefined77 = 77;

        /// <summary>Undefined output 78.</summary>
        public const int Undefined78 = 78;

        /// <summary>Undefined output 79.</summary>
        public const int Undefined79 = 79;

        // ----- CH4 Probe / Carrier Solenoids (80..95) -----

        /// <summary>CH 4 probe forward solenoid.</summary>
        public const int Ch4ProbeForwardSol = 80;

        /// <summary>CH 4 probe backward solenoid.</summary>
        public const int Ch4ProbeBackwardSol = 81;

        /// <summary>CH 4 probe up solenoid.</summary>
        public const int Ch4ProbeUpSol = 82;

        /// <summary>CH 4 probe down solenoid.</summary>
        public const int Ch4ProbeDownSol = 83;

        /// <summary>CH 4 carrier unlock solenoid.</summary>
        public const int Ch4CarrierUnlockSol = 84;

        /// <summary>CH 4 carrier lock solenoid.</summary>
        public const int Ch4CarrierLockSol = 85;

        /// <summary>Undefined output 86.</summary>
        public const int Undefined86 = 86;

        /// <summary>Undefined output 87.</summary>
        public const int Undefined87 = 87;

        /// <summary>CH 4 PMIC laser point.</summary>
        public const int Ch4PmicLaserPoint = 88;

        /// <summary>CH 4 center laser point.</summary>
        public const int Ch4CenterLaserPoint = 89;

        /// <summary>CH 4 PMIC fan on.</summary>
        public const int Ch4PmicFanOn = 90;

        /// <summary>Undefined output 91.</summary>
        public const int Undefined91 = 91;

        /// <summary>Undefined output 92.</summary>
        public const int Undefined92 = 92;

        /// <summary>Undefined output 93.</summary>
        public const int Undefined93 = 93;

        /// <summary>Undefined output 94.</summary>
        public const int Undefined94 = 94;

        /// <summary>Undefined output 95.</summary>
        public const int Undefined95 = 95;

        /// <summary>Maximum output signal index (= Undefined95).</summary>
        public const int Max = Undefined95;
    }

    // =========================================================================
    //  Pre_OC (GIB) Input Signal Definitions
    // =========================================================================

    /// <summary>
    /// DIO input signal index constants for the Pre_OC / GIB configuration.
    /// These constants share the same signal index space and are used when the
    /// inspector type is <see cref="InspectorType.TypeGib"/>.
    /// </summary>
    public static class DioInputGib
    {
        // ----- Safety Signals -----

        /// <summary>CH 1-2 EMO switch.</summary>
        public const int Ch12EmoSwitch = 4;

        /// <summary>CH 3-4 EMO switch.</summary>
        public const int Ch34EmoSwitch = 5;

        /// <summary>CH 1-2 light curtain.</summary>
        public const int Ch12LightCurtain = 6;

        /// <summary>CH 3-4 light curtain.</summary>
        public const int Ch34LightCurtain = 7;

        // ----- Monitoring / Robot Sensors -----

        /// <summary>CH 1-2 muting lamp.</summary>
        public const int Ch12MutingLamp = 8;

        /// <summary>CH 3-4 muting lamp.</summary>
        public const int Ch34MutingLamp = 9;

        /// <summary>CH 1-2 MC monitoring.</summary>
        public const int Ch12McMonitoring = 10;

        /// <summary>CH 3-4 MC monitoring.</summary>
        public const int Ch34McMonitoring = 11;

        /// <summary>Temperature alarm.</summary>
        public const int TemperatureAlarm = 12;

        /// <summary>CH 1-2 robot sensor.</summary>
        public const int Ch12RobotSensor = 13;

        /// <summary>CH 3-4 robot sensor.</summary>
        public const int Ch34RobotSensor = 14;

        // ----- Pressure -----

        /// <summary>Cylinder pressure gauge.</summary>
        public const int CylPressureGauge = 16;

        // ----- CH1 GIB Carrier / Pin-block Sensors (24..31) -----

        /// <summary>CH 1 carrier presence sensor.</summary>
        public const int Ch1CarrierSensor = 24;

        /// <summary>CH 1 tilting sensor.</summary>
        public const int Ch1TiltingSensor = 25;

        /// <summary>CH 1 pin-block open sensor.</summary>
        public const int Ch1PinblockOpenSensor = 26;

        /// <summary>CH 1 pressure gauge.</summary>
        public const int Ch1PressureGauge = 27;

        /// <summary>CH 1 pin-block unlock off sensor.</summary>
        public const int Ch1PinblockUnlockOfSensor = 28;

        /// <summary>CH 1 pin-block unlock on sensor.</summary>
        public const int Ch1PinblockUnlockOnSensor = 29;

        /// <summary>CH 1 pin-block close up sensor.</summary>
        public const int Ch1PinblockCloseUpSensor = 30;

        /// <summary>CH 1 pin-block close down sensor.</summary>
        public const int Ch1PinblockCloseDnSensor = 31;

        // ----- CH2 GIB Carrier / Pin-block Sensors (32..39) -----

        /// <summary>CH 2 carrier presence sensor.</summary>
        public const int Ch2CarrierSensor = 32;

        /// <summary>CH 2 tilting sensor.</summary>
        public const int Ch2TiltingSensor = 33;

        /// <summary>CH 2 pin-block open sensor.</summary>
        public const int Ch2PinblockOpenSensor = 34;

        /// <summary>CH 2 pressure gauge.</summary>
        public const int Ch2PressureGauge = 35;

        /// <summary>CH 2 pin-block unlock off sensor.</summary>
        public const int Ch2PinblockUnlockOfSensor = 36;

        /// <summary>CH 2 pin-block unlock on sensor.</summary>
        public const int Ch2PinblockUnlockOnSensor = 37;

        /// <summary>CH 2 pin-block close up sensor.</summary>
        public const int Ch2PinblockCloseUpSensor = 38;

        /// <summary>CH 2 pin-block close down sensor.</summary>
        public const int Ch2PinblockCloseDnSensor = 39;

        // ----- CH3 GIB Carrier / Pin-block Sensors (40..47) -----

        /// <summary>CH 3 carrier presence sensor.</summary>
        public const int Ch3CarrierSensor = 40;

        /// <summary>CH 3 tilting sensor.</summary>
        public const int Ch3TiltingSensor = 41;

        /// <summary>CH 3 pin-block open sensor.</summary>
        public const int Ch3PinblockOpenSensor = 42;

        /// <summary>CH 3 pressure gauge.</summary>
        public const int Ch3PressureGauge = 43;

        /// <summary>CH 3 pin-block unlock off sensor.</summary>
        public const int Ch3PinblockUnlockOfSensor = 44;

        /// <summary>CH 3 pin-block unlock on sensor.</summary>
        public const int Ch3PinblockUnlockOnSensor = 45;

        /// <summary>CH 3 pin-block close up sensor.</summary>
        public const int Ch3PinblockCloseUpSensor = 46;

        /// <summary>CH 3 pin-block close down sensor.</summary>
        public const int Ch3PinblockCloseDnSensor = 47;

        // ----- CH4 GIB Carrier / Pin-block Sensors (48..55) -----

        /// <summary>CH 4 carrier presence sensor.</summary>
        public const int Ch4CarrierSensor = 48;

        /// <summary>CH 4 tilting sensor.</summary>
        public const int Ch4TiltingSensor = 49;

        /// <summary>CH 4 pin-block open sensor.</summary>
        public const int Ch4PinblockOpenSensor = 50;

        /// <summary>CH 4 pressure gauge.</summary>
        public const int Ch4PressureGauge = 51;

        /// <summary>CH 4 pin-block unlock off sensor.</summary>
        public const int Ch4PinblockUnlockOfSensor = 52;

        /// <summary>CH 4 pin-block unlock on sensor.</summary>
        public const int Ch4PinblockUnlockOnSensor = 53;

        /// <summary>CH 4 pin-block close up sensor.</summary>
        public const int Ch4PinblockCloseUpSensor = 54;

        /// <summary>CH 4 pin-block close down sensor.</summary>
        public const int Ch4PinblockCloseDnSensor = 55;

        // ----- Probe / Shutter Sensors (56..63) -----

        /// <summary>CH 1-2 probe up sensor.</summary>
        public const int Ch12ProbeUpSensor = 56;

        /// <summary>CH 1-2 probe down sensor.</summary>
        public const int Ch12ProbeDnSensor = 57;

        /// <summary>CH 1-2 shutter up sensor.</summary>
        public const int Ch12ShutterUpSensor = 58;

        /// <summary>CH 1-2 shutter down sensor.</summary>
        public const int Ch12ShutterDnSensor = 59;

        /// <summary>CH 3-4 probe up sensor.</summary>
        public const int Ch34ProbeUpSensor = 60;

        /// <summary>CH 3-4 probe down sensor.</summary>
        public const int Ch34ProbeDnSensor = 61;

        /// <summary>CH 3-4 shutter up sensor.</summary>
        public const int Ch34ShutterUpSensor = 62;

        /// <summary>CH 3-4 shutter down sensor.</summary>
        public const int Ch34ShutterDnSensor = 63;
    }

    // =========================================================================
    //  Pre_OC (GIB) Output Signal Definitions
    // =========================================================================

    /// <summary>
    /// DIO output signal index constants for the Pre_OC / GIB configuration.
    /// </summary>
    public static class DioOutputGib
    {
        // ----- Reset Switch LEDs -----

        /// <summary>CH 1-2 reset switch LED.</summary>
        public const int Ch12ResetSwitchLed = 6;

        /// <summary>CH 3-4 reset switch LED.</summary>
        public const int Ch34ResetSwitchLed = 7;

        // ----- Tower Lamp / Buzzer (8..14) -----

        /// <summary>Tower lamp red.</summary>
        public const int TowerLampRed = 8;

        /// <summary>Tower lamp yellow.</summary>
        public const int TowerLampYellow = 9;

        /// <summary>Tower lamp green.</summary>
        public const int TowerLampGreen = 10;

        /// <summary>Buzzer 1.</summary>
        public const int Buzzer1 = 11;

        /// <summary>Buzzer 2.</summary>
        public const int Buzzer2 = 12;

        /// <summary>Buzzer 3.</summary>
        public const int Buzzer3 = 13;

        /// <summary>Buzzer 4.</summary>
        public const int Buzzer4 = 14;

        // ----- Ion Solenoids -----

        /// <summary>CH 1-2 ionizer on/off solenoid.</summary>
        public const int Ch12IonOnOffSol = 16;

        /// <summary>CH 3-4 ionizer on/off solenoid.</summary>
        public const int Ch34IonOnOffSol = 17;

        // ----- CH1 Vacuum / Pin-block Solenoids -----

        /// <summary>CH 1 vacuum solenoid.</summary>
        public const int Ch1VacuumSol = 24;

        /// <summary>CH 1 pin-block unlock solenoid.</summary>
        public const int Ch1PinblockUnlockSol = 25;

        /// <summary>CH 1 pin-block close solenoid.</summary>
        public const int Ch1PinblockCloseSol = 26;

        // ----- CH2 Vacuum / Pin-block Solenoids -----

        /// <summary>CH 2 vacuum solenoid.</summary>
        public const int Ch2VacuumSol = 32;

        /// <summary>CH 2 pin-block unlock solenoid.</summary>
        public const int Ch2PinblockUnlockSol = 33;

        /// <summary>CH 2 pin-block close solenoid.</summary>
        public const int Ch2PinblockCloseSol = 34;

        // ----- CH3 Vacuum / Pin-block Solenoids -----

        /// <summary>CH 3 vacuum solenoid.</summary>
        public const int Ch3VacuumSol = 40;

        /// <summary>CH 3 pin-block unlock solenoid.</summary>
        public const int Ch3PinblockUnlockSol = 41;

        /// <summary>CH 3 pin-block close solenoid.</summary>
        public const int Ch3PinblockCloseSol = 42;

        // ----- CH4 Vacuum / Pin-block Solenoids -----

        /// <summary>CH 4 vacuum solenoid.</summary>
        public const int Ch4VacuumSol = 48;

        /// <summary>CH 4 pin-block unlock solenoid.</summary>
        public const int Ch4PinblockUnlockSol = 49;

        /// <summary>CH 4 pin-block close solenoid.</summary>
        public const int Ch4PinblockCloseSol = 50;

        // ----- Probe / Shutter Solenoids (56..63) -----

        /// <summary>CH 1-2 probe up solenoid.</summary>
        public const int Ch12ProbeUpSol = 56;

        /// <summary>CH 1-2 probe down solenoid.</summary>
        public const int Ch12ProbeDnSol = 57;

        /// <summary>CH 1-2 shutter up solenoid.</summary>
        public const int Ch12ShutterUpSol = 58;

        /// <summary>CH 1-2 shutter down solenoid.</summary>
        public const int Ch12ShutterDnSol = 59;

        /// <summary>CH 3-4 probe up solenoid.</summary>
        public const int Ch34ProbeUpSol = 60;

        /// <summary>CH 3-4 probe down solenoid.</summary>
        public const int Ch34ProbeDnSol = 61;

        /// <summary>CH 3-4 shutter up solenoid.</summary>
        public const int Ch34ShutterUpSol = 62;

        /// <summary>CH 3-4 shutter down solenoid.</summary>
        public const int Ch34ShutterDnSol = 63;
    }

    // =========================================================================
    //  Tower Lamp State
    // =========================================================================

    /// <summary>
    /// Tower lamp state enumeration for machine status indication.
    /// </summary>
    public enum LampState
    {
        /// <summary>No state / lamp off.</summary>
        None = 0,

        /// <summary>Manual mode.</summary>
        Manual = 1,

        /// <summary>Paused.</summary>
        Pause = 2,

        /// <summary>Auto (running) mode.</summary>
        Auto = 3,

        /// <summary>Request pending (e.g., carrier request).</summary>
        Request = 4,

        /// <summary>Error state.</summary>
        Error = 5,

        /// <summary>Emergency state.</summary>
        Emergency = 6,
    }

    // =========================================================================
    //  DIO Error List
    // =========================================================================

    /// <summary>
    /// DIO error list index constants.
    /// Error codes are 0-based (ERR_LIST_START was -1 in Delphi, so first error = 0).
    /// </summary>
    public static class DioError
    {
        /// <summary>Error list base offset (Delphi ERR_LIST_START = -1).</summary>
        public const int ListStart = -1;

        // ----- EMS / Safety Errors (0..7) -----

        /// <summary>Front EMS error (DI01).</summary>
        public const int FrontEms = 0;            // ERR_LIST_START + 1

        /// <summary>Side EMS error (DI02).</summary>
        public const int SideEms = 1;             // ERR_LIST_START + 2

        /// <summary>Right inner EMS error (DI03).</summary>
        public const int RightInnerEms = 2;       // ERR_LIST_START + 3

        /// <summary>Left inner EMS error (DI04).</summary>
        public const int LeftInnerEms = 3;        // ERR_LIST_START + 4

        /// <summary>Rear EMS error (DI05).</summary>
        public const int RearEms = 4;             // ERR_LIST_START + 5

        /// <summary>Light curtain error (DI18).</summary>
        public const int LightCurtain = 5;        // ERR_LIST_START + 6

        /// <summary>Upper left door error (DI21).</summary>
        public const int UpperLeftDoor = 6;       // ERR_LIST_START + 7

        /// <summary>Upper right door error (DI22).</summary>
        public const int UpperRightDoor = 7;      // ERR_LIST_START + 8

        // ----- Door / Fan Errors (8..10) -----

        /// <summary>Lower left door error (DI23).</summary>
        public const int LowerLeftDoor = 8;       // ERR_LIST_START + 9

        /// <summary>Lower right door error (DI24).</summary>
        public const int LowerRightDoor = 9;      // ERR_LIST_START + 10

        /// <summary>Fan #1 output error (DI06).</summary>
        public const int Fan1Out = 10;            // ERR_LIST_START + 11

        // ----- Pressure / Temperature / Power Errors -----

        /// <summary>Main air pressure NG (DI14).</summary>
        public const int MainAirPressure = 18;    // ERR_LIST_START + 19

        /// <summary>Temperature alarm (DI16).</summary>
        public const int Temperature = 19;        // ERR_LIST_START + 20

        /// <summary>Power high alarm (DI17).</summary>
        public const int PowerHigh = 20;          // ERR_LIST_START + 21

        /// <summary>MC monitoring / need to press reset button (DI25).</summary>
        public const int McMonitor = 21;          // ERR_LIST_START + 22

        // ----- Stage / Sensor Errors -----

        /// <summary>A Stage position NG (DI26).</summary>
        public const int AStageSensor = 24;       // ERR_LIST_START + 25

        /// <summary>B Stage position NG (DI27).</summary>
        public const int BStageSensor = 25;       // ERR_LIST_START + 26

        /// <summary>Shutter up sensor NG (DI28).</summary>
        public const int ShutterUpSensor = 26;    // ERR_LIST_START + 27

        /// <summary>Shutter down sensor NG (DI29).</summary>
        public const int ShutterDnSensor = 27;    // ERR_LIST_START + 28

        /// <summary>Clamp up sensor 1 base index (DI32). Add channel offset.</summary>
        public const int ClampUpSensor1 = 28;     // ERR_LIST_START + 29

        /// <summary>Clamp up sensor 2 base index (DI33). Add channel offset.</summary>
        public const int ClampUpSensor2 = 36;     // ERR_LIST_START + 37

        /// <summary>Clamp down sensor 1 base index (DI32). Add channel offset.</summary>
        public const int ClampDnSensor1 = 44;     // ERR_LIST_START + 45

        /// <summary>Clamp down sensor 2 base index (DI33). Add channel offset.</summary>
        public const int ClampDnSensor2 = 52;     // ERR_LIST_START + 53

        /// <summary>Pogo up sensor base index (DI34). Add channel offset.</summary>
        public const int PogoUpSensor = 60;       // ERR_LIST_START + 61

        /// <summary>Pogo down sensor base index (DI34). Add channel offset.</summary>
        public const int PogoDnSensor = 68;       // ERR_LIST_START + 69

        /// <summary>Carrier detect sensor base index (DI35). Add channel offset.</summary>
        public const int CarrierDetectSensor = 76; // ERR_LIST_START + 77

        /// <summary>Motor stop sensor error.</summary>
        public const int MotorStopSensor = 85;    // ERR_LIST_START + 86

        // ----- Step Motor Errors -----

        /// <summary>Step motor disconnected error.</summary>
        public const int StepMotorDisconnected = 89;       // ERR_LIST_START + 90

        /// <summary>Step motor position NG error.</summary>
        public const int StepMotorPositionNg = 90;         // ERR_LIST_START + 91

        /// <summary>Step motor cannot work error.</summary>
        public const int StepMotorCannotWork = 91;         // ERR_LIST_START + 92

        // ----- Device Connection Errors -----

        /// <summary>Ionizer status NG.</summary>
        public const int IonizerStatusNg = 99;             // ERR_LIST_START + 100

        /// <summary>Camera 1 connection NG.</summary>
        public const int Camera1ConnectionNg = 100;        // ERR_LIST_START + 101

        /// <summary>Camera 2 connection NG.</summary>
        public const int Camera2ConnectionNg = 101;        // ERR_LIST_START + 102

        /// <summary>Camera 3 connection NG.</summary>
        public const int Camera3ConnectionNg = 102;        // ERR_LIST_START + 103

        /// <summary>Camera 4 connection NG.</summary>
        public const int Camera4ConnectionNg = 103;        // ERR_LIST_START + 104

        /// <summary>Camera lamp connection NG.</summary>
        public const int CamLampConnectNg = 104;           // ERR_LIST_START + 105

        /// <summary>Robot NG.</summary>
        public const int RobotNg = 105;                    // ERR_LIST_START + 106

        /// <summary>ECS NG.</summary>
        public const int EcsNg = 106;                      // ERR_LIST_START + 107

        /// <summary>DIO card disconnected.</summary>
        public const int DioCardDisconnected = 107;        // ERR_LIST_START + 108

        /// <summary>Ionizer status NG (unit 1).</summary>
        public const int IonizerStatusNg1 = 108;           // ERR_LIST_START + 109

        /// <summary>Ionizer status NG (unit 2).</summary>
        public const int IonizerStatusNg2 = 109;           // ERR_LIST_START + 110

        // ----- Power Limit / NG Count Errors -----

        /// <summary>CH 1 power limit NG.</summary>
        public const int Ch1PowerLimitNg = 120;            // ERR_LIST_START + 121

        /// <summary>CH 2 power limit NG.</summary>
        public const int Ch2PowerLimitNg = 121;            // ERR_LIST_START + 122

        /// <summary>CH 3 power limit NG.</summary>
        public const int Ch3PowerLimitNg = 122;            // ERR_LIST_START + 123

        /// <summary>CH 4 power limit NG.</summary>
        public const int Ch4PowerLimitNg = 123;            // ERR_LIST_START + 124

        /// <summary>CH 1 NG count exceeded.</summary>
        public const int Ch1NgCount = 124;                 // ERR_LIST_START + 125

        /// <summary>CH 2 NG count exceeded.</summary>
        public const int Ch2NgCount = 125;                 // ERR_LIST_START + 126

        /// <summary>CH 3 NG count exceeded.</summary>
        public const int Ch3NgCount = 126;                 // ERR_LIST_START + 127

        /// <summary>CH 4 NG count exceeded.</summary>
        public const int Ch4NgCount = 127;                 // ERR_LIST_START + 128

        /// <summary>Maximum error list index (= Ch4NgCount + 8 = 135).</summary>
        public const int ListMax = Ch4NgCount + 8;         // 135

        /// <summary>Maximum alarm data byte size (= ListMax / 8).</summary>
        public const int MaxAlarmDataSize = ListMax / 8;   // 16
    }
}
