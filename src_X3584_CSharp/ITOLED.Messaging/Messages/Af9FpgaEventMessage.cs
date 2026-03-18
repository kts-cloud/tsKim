using Dongaeltek.ITOLED.Core.Messaging;

namespace Dongaeltek.ITOLED.Messaging.Messages;

/// <summary>
/// AF9 FPGA events (Delphi MSG_TYPE_AF9FPGA = 17).
/// Published by AF9_FPGA when FPGA operations complete,
/// data transfers finish, or errors occur.
/// </summary>
public sealed class Af9FpgaEventMessage : AppMessage;
