using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// External DLL events (Delphi MSG_TYPE_DLL = 16).
/// Published by dllClass when external DLL function calls
/// complete or produce results.
/// </summary>
public sealed class DllEventMessage : AppMessage;
