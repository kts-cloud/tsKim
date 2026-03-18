using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// DFS (Data File Server) events (Delphi MSG_TYPE_DFS = 14).
/// Published by DfsFtp when file transfer operations
/// start, progress, complete, or fail.
/// </summary>
public sealed class DfsEventMessage : AppMessage;
