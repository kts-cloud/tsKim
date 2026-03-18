using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Host (MES/GMES) communication events (Delphi MSG_TYPE_HOST = 9).
/// Published by GMesCom / DllMesCom when host transactions
/// complete or fail.
/// </summary>
public sealed class HostEventMessage : AppMessage;
