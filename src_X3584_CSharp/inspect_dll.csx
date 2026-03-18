using System.Reflection;

var dllPath = @"D:\Dongaeltek\_Project\04_VHOLED\_Project\SW\ITOLED_OC\IT_OLED_OC_X3584_CSharp\TIBCO_ECS_Converter.dll";
var asm = Assembly.LoadFrom(dllPath);
Console.WriteLine($"Assembly: {asm.FullName}");
foreach (var t in asm.GetExportedTypes())
{
    Console.WriteLine($"\nType: {t.FullName}");
    foreach (var m in t.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly))
    {
        var ps = string.Join(", ", m.GetParameters().Select(p => $"{p.ParameterType.Name} {p.Name}"));
        Console.WriteLine($"  {(m.IsStatic?"static ":"")}{m.ReturnType.Name} {m.Name}({ps})");
    }
    foreach (var p in t.GetProperties())
    {
        Console.WriteLine($"  prop {p.PropertyType.Name} {p.Name}");
    }
}
