using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Flow data view update events (Delphi MSG_TYPE_FLOW_DATA_VIEW = 12).
/// Published to request or update flow data visualization on the UI.
/// </summary>
public sealed class FlowDataViewMessage : AppMessage;
