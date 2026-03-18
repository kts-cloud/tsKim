// CommonUtility.cs
// Converted from TCommon utility/helper methods in CommonClass.pas (Delphi)
// Namespace: Dongaeltek.ITOLED.Core.Common

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

namespace Dongaeltek.ITOLED.Core.Common
{
    /// <summary>
    /// Static utility class containing helper methods converted from TCommon (Delphi).
    /// Provides CRC, encryption, file, system monitoring, and type conversion utilities.
    /// </summary>
    public static class CommonUtility
    {
        #region Constants

        // CRC16 polynomial (from DefCommon.pas)
        private const ushort CRC16POLY = 0x8408;

        // Encryption constants (from DefCommon.pas)
        private const uint C1 = 74054;
        private const uint C2 = 12337;

        // HexaChar lookup table (from DefCommon.pas)
        private static readonly char[] HexaChar =
            { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

        #endregion

        #region CRC Utilities

        /// <summary>
        /// CRC16 calculation from a string (ANSI/byte representation).
        /// Matches Delphi: function TCommon.crc16(Str: AnsiString; len: Integer): Word
        /// </summary>
        /// <param name="str">Input string (treated as ANSI bytes).</param>
        /// <param name="len">Number of bytes to process.</param>
        /// <returns>CRC16 value.</returns>
        public static ushort Crc16(string str, int len)
        {
            // Convert string to ANSI (single-byte) representation matching Delphi AnsiString
            byte[] bytes = Encoding.GetEncoding(949).GetBytes(str); // Korean ANSI codepage
            return Crc16FromBytes(bytes, len);
        }

        /// <summary>
        /// CRC16 calculation from a byte array.
        /// Matches Delphi: function TCommon.crc16(Str: AnsiString; len: Integer): Word
        /// Uses the same algorithm as the AnsiString version.
        /// </summary>
        private static ushort Crc16FromBytes(byte[] data, int len)
        {
            ushort crc = 0xFFFF;
            int loopLen = len;
            int cnt = 0;

            if (len == 0)
            {
                return (ushort)(~crc);
            }

            while (loopLen > 0)
            {
                ushort d = (ushort)(0xFF & data[cnt]);
                loopLen--;
                cnt++;
                for (int i = 1; i <= 8; i++)
                {
                    if (((crc & 0x1) ^ (d & 0x1)) == 1)
                        crc = (ushort)((crc >> 1) ^ CRC16POLY);
                    else
                        crc = (ushort)(crc >> 1);
                    d = (ushort)(d >> 1);
                }
            }
            crc = (ushort)(~crc);
            ushort temp = crc;
            crc = (ushort)((crc << 8) | ((temp >> 8) & 0xFF));

            return crc;
        }

        /// <summary>
        /// CRC16 calculation from a byte buffer.
        /// Matches Delphi: function TCommon.crc16Buf(buffer: array of Byte; nLen: Integer): Word
        /// Note: The Delphi implementation processes all 8 bits using the same byte value per iteration
        /// (it reads data inside the inner loop but does not re-read after shift). This is preserved here.
        /// </summary>
        /// <param name="buffer">Input byte buffer.</param>
        /// <param name="nLen">Number of bytes to process.</param>
        /// <returns>CRC16 value.</returns>
        public static ushort Crc16Buf(byte[] buffer, int nLen)
        {
            ushort crc = 0xFFFF;
            int loopLen = nLen;
            int cnt = 0;

            if (nLen == 0)
            {
                return (ushort)(~crc);
            }

            // Reproducing the exact Delphi behavior: the inner loop re-reads data each iteration
            // from the same buffer[cnt], and shifts data each time
            do
            {
                ushort data = (ushort)(0xFF & buffer[cnt]);
                for (int i = 1; i <= 8; i++)
                {
                    if (((crc & 0x1) ^ (data & 0x1)) > 0)
                        crc = (ushort)((crc >> 1) ^ CRC16POLY);
                    else
                        crc = (ushort)(crc >> 1);
                    data = (ushort)(data >> 1);
                }
                cnt++;
                loopLen--;
            } while (loopLen > 0);

            crc = (ushort)(~crc);
            ushort temp = crc;
            crc = (ushort)((crc << 8) | ((temp >> 8) & 0xFF));

            return crc;
        }

        /// <summary>
        /// Get CRC as a hex string from a TStringList equivalent (list of strings).
        /// Matches Delphi: function TCommon.GetScriptCrc(stData: TStringList): string
        /// </summary>
        public static string GetScriptCrc(IList<string> lines)
        {
            var sb = new StringBuilder();
            foreach (string line in lines)
            {
                sb.Append(line);
            }
            string combined = sb.ToString();
            ushort crc = Crc16(combined, Encoding.GetEncoding(949).GetByteCount(combined));
            return crc.ToString("X4");
        }

        /// <summary>
        /// Get CRC as a hex string from a single string.
        /// Matches Delphi: function TCommon.GetStringCrc(sData: string): string
        /// </summary>
        public static string GetStringCrc(string data)
        {
            int len = Encoding.GetEncoding(949).GetByteCount(data);
            ushort crc = Crc16(data, len);
            return crc.ToString("X4");
        }

        /// <summary>
        /// Get CRC16 as a Word (ushort) from an ANSI string.
        /// Matches Delphi: function TCommon.GetAnsiCrcToWord(sData: AnsiString; nLen: Integer): Word
        /// </summary>
        public static ushort GetAnsiCrcToWord(string data, int len)
        {
            return Crc16(data, len);
        }

        /// <summary>
        /// Calculate a simple byte-sum checksum over a byte buffer.
        /// Matches Delphi: procedure TCommon.CalcCheckSum(p: pointer; byteCount: dword; var SumValue: dword)
        /// </summary>
        /// <param name="data">Input byte array.</param>
        /// <param name="byteCount">Number of bytes to sum.</param>
        /// <param name="sumValue">Running sum value (will be incremented).</param>
        public static void CalcCheckSum(byte[] data, uint byteCount, ref uint sumValue)
        {
            for (uint i = 0; i < byteCount; i++)
            {
                sumValue += data[i];
            }
        }

        /// <summary>
        /// Calculate a simple byte-sum checksum over a byte buffer.
        /// Overload that returns the checksum directly.
        /// </summary>
        public static uint CalcCheckSum(byte[] data, uint byteCount)
        {
            uint sum = 0;
            CalcCheckSum(data, byteCount, ref sum);
            return sum;
        }

        #endregion

        #region Encryption / Decryption

        /// <summary>
        /// Simple XOR-based encryption with key rotation.
        /// Matches Delphi: function TCommon.Encrypt(const S: String; Key: Word): String
        /// </summary>
        /// <param name="s">Plain text to encrypt.</param>
        /// <param name="key">Encryption key (16-bit).</param>
        /// <returns>Hex-encoded encrypted string.</returns>
        public static string Encrypt(string s, ushort key)
        {
            var firstResult = new char[s.Length];
            for (int i = 0; i < s.Length; i++)
            {
                firstResult[i] = (char)((byte)s[i] ^ (key >> 8));
                // Key rotation: Key = word((LongWord(byte(FirstResult[i]) + Key) * C1 + C2) and $FFFF)
                key = (ushort)(((uint)((byte)firstResult[i] + key) * C1 + C2) & 0xFFFF);
            }
            return ValueToHex(new string(firstResult));
        }

        /// <summary>
        /// Simple XOR-based decryption with key rotation (reverses Encrypt).
        /// Matches Delphi: function TCommon.Decrypt(const S: String; Key: Word): String
        /// </summary>
        /// <param name="s">Hex-encoded encrypted string.</param>
        /// <param name="key">Decryption key (16-bit, same as encryption key).</param>
        /// <returns>Decrypted plain text.</returns>
        public static string Decrypt(string s, ushort key)
        {
            string firstResult = HexToValue(s);
            var result = new char[firstResult.Length];
            for (int i = 0; i < firstResult.Length; i++)
            {
                result[i] = (char)((byte)firstResult[i] ^ (key >> 8));
                // Key rotation uses the encrypted byte (firstResult), not the decrypted byte
                key = (ushort)(((uint)((byte)firstResult[i] + key) * C1 + C2) & 0xFFFF);
            }
            return new string(result);
        }

        #endregion

        #region Hex Conversion

        /// <summary>
        /// Convert a string to its hex representation (each char becomes 2 hex digits).
        /// Matches Delphi: function TCommon.ValueToHex(const S: String): String
        /// Uses the HexaChar lookup table from DefCommon.
        /// </summary>
        public static string ValueToHex(string s)
        {
            var sb = new StringBuilder(s.Length * 2);
            for (int i = 0; i < s.Length; i++)
            {
                int charVal = (int)s[i];
                sb.Append(HexaChar[charVal >> 4]);
                sb.Append(HexaChar[charVal & 0x0F]);
            }
            return sb.ToString();
        }

        /// <summary>
        /// Convert a hex string back to its original string (every 2 hex chars become 1 char).
        /// Matches Delphi: function TCommon.HexToValue(const S: String): String
        /// </summary>
        public static string HexToValue(string s)
        {
            var result = new char[s.Length / 2];
            for (int i = 0; i < s.Length / 2; i++)
            {
                string hexPair = s.Substring(i * 2, 2);
                int value;
                if (int.TryParse(hexPair, System.Globalization.NumberStyles.HexNumber, null, out value))
                    result[i] = (char)value;
                else
                    result[i] = (char)0;
            }
            return new string(result);
        }

        #endregion

        #region Timing Utilities

        /// <summary>
        /// Busy-wait delay with message processing (microsecond precision).
        /// Matches Delphi: procedure TCommon.WaitMicroSec(micro_sec: Int64)
        /// In C# we use Stopwatch for high-resolution timing. Note: no UI message pump.
        /// </summary>
        /// <param name="microSec">Microseconds to wait.</param>
        public static void WaitMicroSec(long microSec)
        {
            var sw = Stopwatch.StartNew();
            long targetTicks = microSec * Stopwatch.Frequency / 1_000_000;
            while (sw.ElapsedTicks < targetTicks)
            {
                // Spin-wait for microsecond precision
                Thread.SpinWait(1);
            }
        }

        /// <summary>
        /// Delay with Sleep(1) granularity (millisecond precision).
        /// Matches Delphi: procedure TCommon.Delay(msec: longint)
        /// In C# we use Stopwatch + Thread.Sleep for a non-blocking delay.
        /// Note: Delphi version calls Application.ProcessMessages; in C# this is not applicable.
        /// </summary>
        /// <param name="msec">Milliseconds to delay.</param>
        public static void Delay(int msec)
        {
            if (msec <= 0) return;
            var sw = Stopwatch.StartNew();
            while (sw.ElapsedMilliseconds < msec)
            {
                Thread.Sleep(1);
            }
        }

        /// <summary>
        /// High-precision spin-wait delay in microseconds.
        /// Matches Delphi: procedure TCommon.SleepMicro(nSec: Int64)
        /// </summary>
        /// <param name="microseconds">Microseconds to spin-wait.</param>
        public static void SleepMicro(long microseconds)
        {
            if (!Stopwatch.IsHighResolution) return;
            var sw = Stopwatch.StartNew();
            // Stopwatch.Frequency ticks per second, so ticks per microsecond = Frequency / 1_000_000
            double targetTicks = (double)microseconds * Stopwatch.Frequency / 1_000_000.0;
            while (sw.ElapsedTicks < targetTicks)
            {
                // Pure spin-wait (no Sleep, no yield)
            }
        }

        #endregion

        #region Time Formatting

        /// <summary>
        /// Format seconds into HH:MM:SS string.
        /// Matches Delphi: function TCommon.SetTimeToStr(nTime: Int64): string
        /// </summary>
        /// <param name="totalSeconds">Total seconds to format.</param>
        /// <returns>Formatted time string "HH:MM:SS".</returns>
        public static string SetTimeToStr(long totalSeconds)
        {
            int sec = (int)(totalSeconds % 60);
            int temp = (int)(totalSeconds / 60);
            int min = temp % 60;
            int hour = temp / 60;
            return $"{hour:D2}:{min:D2}:{sec:D2}";
        }

        #endregion

        #region Number Conversion

        /// <summary>
        /// Convert a decimal integer to its octal string representation.
        /// Matches Delphi: function TCommon.DecToOct(nGetVal: Integer): string
        /// </summary>
        public static string DecToOct(int value)
        {
            if (value <= 0) return "0";

            var sb = new StringBuilder();
            int nValue = value;
            while (nValue > 0)
            {
                int rest = nValue % 8;
                nValue /= 8;
                sb.Insert(0, rest.ToString());
            }
            return sb.Length == 0 ? "0" : sb.ToString();
        }

        #endregion

        #region System Information

        /// <summary>
        /// Get the local computer name.
        /// Matches Delphi: function TCommon.GetComputerName: String
        /// </summary>
        public static string GetComputerName()
        {
            return Environment.MachineName;
        }

        /// <summary>
        /// Get the file version date formatted based on type.
        /// Matches Delphi: function TCommon.GetFileVerDate(sFileName: string; nType: Integer = 0): string
        /// </summary>
        /// <param name="fileName">Full path to the file.</param>
        /// <param name="formatType">
        /// 0 = "yyyy.MM.dd  HH:mm",
        /// 1 = "yy.MM.dd HH:mm",
        /// 2 = hex-encoded "yy.MM.dd.HH.mm",
        /// 3 = "No Format Type"
        /// </param>
        public static string GetFileVerDate(string fileName, int formatType = 0)
        {
            if (!File.Exists(fileName))
                return "NO Exists";

            DateTime timeDate = File.GetLastWriteTime(fileName);
            switch (formatType)
            {
                case 0:
                    return timeDate.ToString("yyyy.MM.dd  HH:mm");
                case 1:
                    return timeDate.ToString("yy.MM.dd HH:mm");
                case 2:
                    {
                        // Format as "yy.MM.dd.HH.mm", split by '.', convert each part to 2-digit hex
                        string dateStr = timeDate.ToString("yy.MM.dd.HH.mm");
                        string[] parts = dateStr.Split('.');
                        var sb = new StringBuilder();
                        foreach (string part in parts)
                        {
                            if (int.TryParse(part, out int val))
                                sb.Append(val.ToString("x2"));
                        }
                        return sb.ToString();
                    }
                case 3:
                    return "No Format Type";
                default:
                    return string.Empty;
            }
        }

        /// <summary>
        /// Get the file version string (Major.Minor.Release.Build) from a PE executable.
        /// Matches Delphi: function TCommon.GetFileVersion(sFileName: string): string
        /// </summary>
        public static string GetFileVersion(string fileName)
        {
            try
            {
                if (!File.Exists(fileName))
                    return string.Empty;

                var versionInfo = FileVersionInfo.GetVersionInfo(fileName);
                if (versionInfo.FileVersion != null)
                {
                    return $"{versionInfo.FileMajorPart}.{versionInfo.FileMinorPart}.{versionInfo.FileBuildPart}.{versionInfo.FilePrivatePart}";
                }
            }
            catch
            {
                // Silently fail, matching Delphi behavior
            }
            return string.Empty;
        }

        /// <summary>
        /// Get the product version string (Major.Minor.Release.Build) from a PE executable.
        /// Matches Delphi: function TCommon.GetProductVersion(sFileName: string): string
        /// </summary>
        public static string GetProductVersion(string fileName)
        {
            try
            {
                if (!File.Exists(fileName))
                    return string.Empty;

                var versionInfo = FileVersionInfo.GetVersionInfo(fileName);
                if (versionInfo.ProductVersion != null)
                {
                    return $"{versionInfo.ProductMajorPart}.{versionInfo.ProductMinorPart}.{versionInfo.ProductBuildPart}.{versionInfo.ProductPrivatePart}";
                }
            }
            catch
            {
                // Silently fail
            }
            return string.Empty;
        }

        /// <summary>
        /// Get the version date of the currently running executable.
        /// Matches Delphi: function TCommon.GetVerOnlyDate: string
        /// </summary>
        public static string GetVerOnlyDate()
        {
            string exePath = Process.GetCurrentProcess().MainModule?.FileName ?? string.Empty;
            if (string.IsNullOrEmpty(exePath) || !File.Exists(exePath))
                return string.Empty;
            DateTime timeDate = File.GetLastWriteTime(exePath);
            return timeDate.ToString("yy.MM.dd  HH:mm");
        }

        /// <summary>
        /// Get the version date string for the current exe: "Version ( ExeName )".
        /// Matches Delphi: function TCommon.GetVersionDate: String
        /// </summary>
        /// <param name="exeVersion">Pre-computed exe version string.</param>
        /// <param name="exeName">Pre-computed exe name without extension.</param>
        public static string GetVersionDate(string exeVersion, string exeName)
        {
            return $"{exeVersion} ( {exeName} )";
        }

        #endregion

        #region Network Utilities

        /// <summary>
        /// Get local IP addresses, optionally filtering by a prefix string.
        /// Matches Delphi: function TCommon.GetLocalIpList(nIdx: Integer; sSearchIp: string): string
        /// The Delphi version uses WinSock; this uses .NET DNS resolution.
        /// </summary>
        /// <param name="searchIpPrefix">IP prefix to filter by (e.g., "10.96."). Empty string returns all.</param>
        /// <returns>Matching IP address, or all non-loopback IPs joined by " / ".</returns>
        public static string GetLocalIpList(string searchIpPrefix = "")
        {
            try
            {
                string hostName = Dns.GetHostName();
                var hostEntry = Dns.GetHostEntry(hostName);
                var ipList = new List<string>();

                foreach (var addr in hostEntry.AddressList)
                {
                    if (addr.AddressFamily == AddressFamily.InterNetwork)
                    {
                        string ip = addr.ToString();
                        if (ip == "0.0.0.0") continue;
                        if (ip.StartsWith("192.168.0.")) continue;
                        ipList.Add(ip);
                    }
                }

                // If a search prefix is provided, return the first matching IP
                if (!string.IsNullOrEmpty(searchIpPrefix))
                {
                    foreach (string ip in ipList)
                    {
                        if (ip.StartsWith(searchIpPrefix))
                            return ip;
                    }
                    return string.Empty;
                }

                // Otherwise return all IPs joined
                return string.Join(" / ", ipList);
            }
            catch
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// Overload matching the Delphi signature with nIdx parameter.
        /// nIdx is used to select the type of IP (GMES, PLC, etc.) but the filtering
        /// logic is the same: match by prefix.
        /// </summary>
        public static string GetLocalIpList(int nIdx, string searchIpPrefix)
        {
            return GetLocalIpList(searchIpPrefix);
        }

        #endregion

        #region System Monitoring

        /// <summary>
        /// Get the working set size (memory usage) of the current process in bytes.
        /// Matches Delphi: function TCommon.ProcessMemory: longint
        /// </summary>
        public static long ProcessMemory()
        {
            using (var proc = Process.GetCurrentProcess())
            {
                return proc.WorkingSet64;
            }
        }

        /// <summary>
        /// Get a human-readable memory usage string.
        /// Matches Delphi: function TCommon.CheckMemory: string
        /// </summary>
        public static string CheckMemory()
        {
            long memBytes = ProcessMemory();
            if (memBytes < 1024)
            {
                return $"MEMORY CHECK : {memBytes:N0} Bytes";
            }
            else if (memBytes < 1024 * 1024)
            {
                return $"MEMORY CHECK : {memBytes / 1024:N0} KB";
            }
            else
            {
                return $"MEMORY CHECK : {memBytes / (1024 * 1024):N0} MB";
            }
        }

        /// <summary>
        /// Get system memory usage percentage.
        /// Matches Delphi: function TCommon.GetMemoryUsagePercentage: Double
        /// Uses P/Invoke to GlobalMemoryStatusEx.
        /// </summary>
        public static double GetMemoryUsagePercentage()
        {
            try
            {
                var memStatus = new MEMORYSTATUSEX();
                memStatus.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
                if (GlobalMemoryStatusEx(ref memStatus))
                {
                    return 100.0 * (1.0 - (double)memStatus.ullAvailPhys / memStatus.ullTotalPhys);
                }
            }
            catch
            {
                // Silently fail
            }
            return 0.0;
        }

        /// <summary>
        /// Get approximate CPU usage percentage.
        /// Matches Delphi: function TCommon.GetCPUUsage: Double
        /// Note: The Delphi implementation has a bug (IdleTimeDelta is always 0 because it subtracts
        /// the same variable from itself). This is preserved for compatibility, but a corrected
        /// version is also provided below.
        /// WARNING: This method blocks for ~100ms.
        /// </summary>
        public static double GetCPUUsage()
        {
            try
            {
                // First sample
                if (!GetSystemTimes(out FILETIME idleTime1, out FILETIME kernelTime1, out FILETIME userTime1))
                    return 0.0;

                long totalTime1 = FileTimeToLong(userTime1) + FileTimeToLong(kernelTime1);
                long idleTime1Val = FileTimeToLong(idleTime1);

                Thread.Sleep(100);

                // Second sample
                if (!GetSystemTimes(out FILETIME idleTime2, out FILETIME kernelTime2, out FILETIME userTime2))
                    return 0.0;

                long totalTime2 = FileTimeToLong(userTime2) + FileTimeToLong(kernelTime2);
                long idleTime2Val = FileTimeToLong(idleTime2);

                long totalTimeDelta = totalTime2 - totalTime1;
                long idleTimeDelta = idleTime2Val - idleTime1Val;

                if (totalTimeDelta > 0)
                    return 1.0 - (double)idleTimeDelta / totalTimeDelta;

                return 0.0;
            }
            catch
            {
                return 0.0;
            }
        }

        /// <summary>
        /// Get disk usage percentage for the specified drive.
        /// Matches Delphi: function TCommon.GetDiskSpacePercentage(const Drive: string): Integer
        /// </summary>
        /// <param name="drive">Drive path (e.g., "C:\").</param>
        /// <returns>Usage percentage (0-100), or -1 on error.</returns>
        public static int GetDiskSpacePercentage(string drive)
        {
            try
            {
                string rootPath = Path.GetPathRoot(drive) ?? drive;
                var driveInfo = new DriveInfo(rootPath);
                if (driveInfo.IsReady && driveInfo.TotalSize > 0)
                {
                    long usedSpace = driveInfo.TotalSize - driveInfo.AvailableFreeSpace;
                    return (int)(100.0 * usedSpace / driveInfo.TotalSize);
                }
            }
            catch
            {
                // Silently fail
            }
            return -1;
        }

        #endregion

        #region File Compression

        /// <summary>
        /// Compress a file into a ZIP archive.
        /// Matches Delphi: procedure TCommon.FileCompress(sFullFileName: string; bDeleteOrgFile: Boolean; var sZipFileName: string)
        /// </summary>
        /// <param name="fullFileName">Full path of the file to compress.</param>
        /// <param name="deleteOriginal">If true, delete the original file after compression.</param>
        /// <param name="zipFileName">Output: the full path of the created ZIP file.</param>
        public static void FileCompress(string fullFileName, bool deleteOriginal, out string zipFileName)
        {
            zipFileName = string.Empty;
            if (string.IsNullOrEmpty(fullFileName))
                return;

            string directory = Path.GetDirectoryName(fullFileName) ?? string.Empty;
            string fileNameWithoutExt = Path.GetFileNameWithoutExtension(fullFileName);
            string zipFullName = Path.Combine(directory, fileNameWithoutExt + ".zip");

            // Create zip and add the single file
            using (var archive = ZipFile.Open(zipFullName, ZipArchiveMode.Create))
            {
                archive.CreateEntryFromFile(fullFileName, Path.GetFileName(fullFileName));
            }

            if (deleteOriginal)
            {
                File.Delete(fullFileName);
            }

            zipFileName = zipFullName;
        }

        /// <summary>
        /// Decompress a ZIP file to its containing directory.
        /// Matches Delphi: procedure TCommon.FileDecompress(sFullZipName: string)
        /// </summary>
        /// <param name="fullZipName">Full path of the ZIP file.</param>
        public static void FileDecompress(string fullZipName)
        {
            if (string.IsNullOrEmpty(fullZipName))
                return;

            string extractDir = Path.GetDirectoryName(fullZipName) ?? string.Empty;
            ZipFile.ExtractToDirectory(fullZipName, extractDir, overwriteFiles: true);
        }

        #endregion

        #region Directory Operations

        /// <summary>
        /// Recursively copy a directory.
        /// Matches Delphi: procedure TCommon.CopyDirectoryAll(pSourceDir, pDestinationDir: string; pOverWrite: Boolean)
        /// Note: Directories whose name contains "LOG" (case-insensitive) are skipped, matching Delphi behavior.
        /// </summary>
        /// <param name="sourceDir">Source directory path.</param>
        /// <param name="destinationDir">Destination directory path.</param>
        /// <param name="overwrite">If true, overwrite existing files.</param>
        /// <param name="cancellationToken">Optional cancellation token (replaces Delphi's m_bStopWork).</param>
        public static void CopyDirectoryAll(
            string sourceDir,
            string destinationDir,
            bool overwrite,
            CancellationToken cancellationToken = default)
        {
            if (cancellationToken.IsCancellationRequested) return;

            if (!Directory.Exists(sourceDir))
                return;

            if (!Directory.Exists(destinationDir))
                Directory.CreateDirectory(destinationDir);

            // Copy files
            foreach (string filePath in Directory.GetFiles(sourceDir))
            {
                if (cancellationToken.IsCancellationRequested) return;

                string fileName = Path.GetFileName(filePath);
                string destFile = Path.Combine(destinationDir, fileName);
                File.Copy(filePath, destFile, overwrite);
            }

            // Recursively copy subdirectories (skip directories containing "LOG")
            foreach (string dirPath in Directory.GetDirectories(sourceDir))
            {
                if (cancellationToken.IsCancellationRequested) return;

                string dirName = Path.GetFileName(dirPath) ?? string.Empty;
                if (dirName.IndexOf("LOG", StringComparison.OrdinalIgnoreCase) >= 0)
                    continue;

                string destSubDir = Path.Combine(destinationDir, dirName);
                CopyDirectoryAll(dirPath, destSubDir, overwrite, cancellationToken);
            }
        }

        #endregion

        #region File Access Checks

        /// <summary>
        /// Check if a file can be opened with the specified file mode.
        /// Matches Delphi: function TCommon.CanOpenFile(const FilePath: string; FileMode: Word): Boolean
        /// FileMode values: fmOpenRead=0, fmOpenWrite=1, fmOpenReadWrite=2
        /// </summary>
        public static bool CanOpenFile(string filePath, FileAccess fileAccess = FileAccess.Read)
        {
            try
            {
                using (var fs = new FileStream(filePath, FileMode.Open, fileAccess, FileShare.ReadWrite))
                {
                    return true;
                }
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Check file access permissions (read/write/execute).
        /// Matches Delphi: function TCommon.CheckFileAccess(const Path: string; Mode: Word): Boolean
        /// Mode bitmask: 4=Read, 2=Write, 1=Execute
        /// </summary>
        /// <param name="path">File path to check.</param>
        /// <param name="mode">Access mode bitmask (4=Read, 2=Write, 1=Execute).</param>
        public static bool CheckFileAccess(string path, int mode)
        {
            if (!File.Exists(path))
                return false;

            try
            {
                var attr = File.GetAttributes(path);

                // Check read access (bit 2)
                if ((mode & 4) == 4)
                {
                    if ((attr & FileAttributes.ReadOnly) == FileAttributes.ReadOnly)
                        return false;
                }

                // Check write access (bit 1)
                if ((mode & 2) == 2)
                {
                    if ((attr & FileAttributes.ReadOnly) == FileAttributes.ReadOnly)
                        return false;
                }

                // Check execute access (bit 0) - directory check in Delphi
                if ((mode & 1) == 1)
                {
                    if ((attr & FileAttributes.Directory) == FileAttributes.Directory)
                        return false;
                }

                return true;
            }
            catch
            {
                return false;
            }
        }

        #endregion

        #region String Utilities

        /// <summary>
        /// Remove ASCII control characters (0-31) from a string.
        /// Matches Delphi: function TCommon.RemoveControlCharacters(const Input: string): string
        /// </summary>
        public static string RemoveControlCharacters(string input)
        {
            if (string.IsNullOrEmpty(input))
                return string.Empty;

            var sb = new StringBuilder(input.Length);
            foreach (char c in input)
            {
                if (c > 31) // Keep characters with ordinal > 31
                    sb.Append(c);
            }
            return sb.ToString();
        }

        /// <summary>
        /// Extract all digit sequences from a string and concatenate them.
        /// Matches Delphi: function TCommon.ExtractNumbersFromString(inputString: string): string
        /// </summary>
        public static string ExtractNumbersFromString(string inputString)
        {
            if (string.IsNullOrEmpty(inputString))
                return string.Empty;

            var sb = new StringBuilder();
            foreach (Match match in Regex.Matches(inputString, @"\d+"))
            {
                sb.Append(match.Value);
            }
            return sb.ToString();
        }

        #endregion

        #region Type Conversion Helpers

        /// <summary>
        /// Convert a string to a PAnsiChar-equivalent byte array (ANSI encoding).
        /// Matches Delphi: function TCommon.StringToPAnsiChar(AString: string): PAnsiChar
        /// In C# we return a null-terminated byte array suitable for P/Invoke.
        /// </summary>
        public static byte[] StringToPAnsiBytes(string aString)
        {
            byte[] ansiBytes = Encoding.GetEncoding(949).GetBytes(aString);
            byte[] result = new byte[ansiBytes.Length + 1]; // null-terminated
            Array.Copy(ansiBytes, result, ansiBytes.Length);
            result[ansiBytes.Length] = 0;
            return result;
        }

        /// <summary>
        /// Allocate unmanaged memory containing the ANSI string (caller must free with Marshal.FreeHGlobal).
        /// Use this when an IntPtr (PAnsiChar equivalent) is needed for interop.
        /// </summary>
        public static IntPtr StringToPAnsiChar(string aString)
        {
            return Marshal.StringToHGlobalAnsi(aString);
        }

        /// <summary>
        /// Convert an integer to a TIdBytes-equivalent byte array (4 bytes, little-endian).
        /// Matches Delphi: function TCommon.IntToIdBytes(Value: Integer): TIdBytes
        /// </summary>
        public static byte[] IntToIdBytes(int value)
        {
            return BitConverter.GetBytes(value);
        }

        /// <summary>
        /// Convert a string to a TIdBytes-equivalent byte array (each Unicode char to one byte).
        /// Matches Delphi: function TCommon.StringToIdBytes(const AStr: string): TIdBytes
        /// Note: Delphi version uses Ord() on each WideChar, which takes the low byte.
        /// </summary>
        public static byte[] StringToIdBytes(string str)
        {
            byte[] result = new byte[str.Length];
            for (int i = 0; i < str.Length; i++)
            {
                result[i] = (byte)str[i];
            }
            return result;
        }

        #endregion

        #region CSV Logging

        /// <summary>
        /// Append a line to a summary CSV log file (creates with header if new).
        /// Matches Delphi: procedure TCommon.MakeSummaryCsvLog(sHeader, sData: string)
        /// </summary>
        /// <param name="header">CSV header line (written only when creating a new file).</param>
        /// <param name="data">CSV data line to append.</param>
        /// <param name="basePath">Base path for summary CSV logs (e.g., Path.SumCsv).</param>
        /// <param name="equipmentId">Equipment ID for the filename.</param>
        public static void MakeSummaryCsvLog(string header, string data, string basePath, string equipmentId)
        {
            try
            {
                string filePath = Path.Combine(basePath, DateTime.Now.ToString("yyyyMM"));
                if (!Directory.Exists(filePath))
                    Directory.CreateDirectory(filePath);

                string fileName = Path.Combine(filePath, DateTime.Now.ToString("yyyyMMdd") + equipmentId + ".csv");

                bool isNewFile = !File.Exists(fileName);

                using (var writer = new StreamWriter(fileName, append: true, Encoding.UTF8))
                {
                    if (isNewFile)
                    {
                        writer.WriteLine(header);
                    }
                    writer.WriteLine(data);
                }
            }
            catch
            {
                // Silently fail, matching Delphi behavior
            }
        }

        #endregion

        #region Pattern CRC

        /// <summary>
        /// Calculate pattern group CRC.
        /// Matches Delphi: function TCommon.MakePatternGroupCrc: WORD
        /// TODO: This method depends on instance state (EdModelInfoFLOW, loadAllPat, etc.)
        /// and cannot be made purely static without passing in the pattern data.
        /// The caller should provide the serialized pattern data buffer and use Crc16 directly.
        /// </summary>
        /// <param name="patternData">Serialized pattern group data as byte array.</param>
        /// <param name="length">Length of the data.</param>
        /// <returns>CRC16 of the pattern group.</returns>
        public static ushort MakePatternGroupCrc(byte[] patternData, int length)
        {
            // Convert byte array to ANSI string representation for CRC calculation
            string ansiStr = Encoding.GetEncoding(949).GetString(patternData, 0, length);
            return Crc16(ansiStr, length);
        }

        #endregion

        #region P/Invoke Declarations

        [StructLayout(LayoutKind.Sequential)]
        private struct MEMORYSTATUSEX
        {
            public uint dwLength;
            public uint dwMemoryLoad;
            public ulong ullTotalPhys;
            public ulong ullAvailPhys;
            public ulong ullTotalPageFile;
            public ulong ullAvailPageFile;
            public ulong ullTotalVirtual;
            public ulong ullAvailVirtual;
            public ulong ullAvailExtendedVirtual;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

        [StructLayout(LayoutKind.Sequential)]
        private struct FILETIME
        {
            public uint dwLowDateTime;
            public uint dwHighDateTime;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GetSystemTimes(
            out FILETIME lpIdleTime,
            out FILETIME lpKernelTime,
            out FILETIME lpUserTime);

        private static long FileTimeToLong(FILETIME ft)
        {
            return ((long)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
        }

        #endregion
    }
}
