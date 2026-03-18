using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// Thermometer communication events (Delphi MSG_TYPE_COMMTHERMOMETER = 104).
/// Published by CommThermometerMulti when temperature readings
/// are received or communication errors occur.
/// </summary>
public sealed class ThermometerEventMessage : AppMessage;
