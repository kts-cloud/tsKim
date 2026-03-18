// =============================================================================
// TestInitializer.cs — Module initializer for test assembly
// Registers encoding provider needed for Korean codepage 949 (ANSI).
// =============================================================================

using System.Runtime.CompilerServices;
using System.Text;

namespace ITOLED.Tests;

internal static class TestInitializer
{
    [ModuleInitializer]
    internal static void Initialize()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
    }
}
