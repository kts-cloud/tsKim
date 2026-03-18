// dotnet-script: dotnet run GenDriversDat.cs
// Generates drivers.dat from rte_*.dll + hwio.dll with AES-256-CBC encryption
using System;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;

string baseDir = args.Length > 0 ? args[0] : @"\\10.10.5.35\d";
string libDir = Path.Combine(baseDir, @"DPDK\01_Windows\dpdk-src\build\lib");
string drvDir = Path.Combine(baseDir, @"DPDK\01_Windows\dpdk-src\build\drivers");
string hwioPath = Path.Combine(baseDir, @"DPDK\01_Windows\_build\hwio.dll");
string outPath = Path.Combine(baseDir, @"IT_OLED_OC_X3584_CSharp\drivers.dat");

// Collect DLLs
var dlls = new Dictionary<string, string>();
foreach (var dir in new[] { libDir, drvDir })
{
    foreach (var f in Directory.GetFiles(dir, "*-26.dll"))
        dlls[Path.GetFileName(f)] = f;
}
dlls["hwio.dll"] = hwioPath;

Console.WriteLine($"Total DLLs: {dlls.Count}");

// ZIP
using var zipMs = new MemoryStream();
using (var archive = new ZipArchive(zipMs, ZipArchiveMode.Create, leaveOpen: true))
{
    foreach (var kv in dlls.OrderBy(x => x.Key))
    {
        var entry = archive.CreateEntry(kv.Key, CompressionLevel.Optimal);
        using var es = entry.Open();
        using var fs = File.OpenRead(kv.Value);
        fs.CopyTo(es);
    }
}
byte[] zipData = zipMs.ToArray();
Console.WriteLine($"ZIP: {zipData.Length / 1024}KB");

// AES-256-CBC
byte[] key = {
    0x4F, 0x43, 0x49, 0x4E, 0x53, 0x50, 0x5F, 0x48,
    0x57, 0x4E, 0x45, 0x54, 0x5F, 0x4B, 0x45, 0x59,
    0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
    0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
};

using var aes = Aes.Create();
aes.Key = key;
aes.Mode = CipherMode.CBC;
aes.Padding = PaddingMode.PKCS7;
aes.GenerateIV();

using var encryptor = aes.CreateEncryptor();
byte[] ct = encryptor.TransformFinalBlock(zipData, 0, zipData.Length);

using var outFs = File.Create(outPath);
outFs.Write(aes.IV);
outFs.Write(ct);

Console.WriteLine($"drivers.dat: {(aes.IV.Length + ct.Length) / 1024}KB -> {outPath}");
