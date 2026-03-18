// =============================================================================
// IPlcService.cs
// Abstraction for PLC communication used by DioController.
// Converted from Delphi: src_X3584\CommPLC_ECS.pas (g_CommPLC global)
// Namespace: Dongaeltek.ITOLED.Core.Interfaces
// =============================================================================

namespace Dongaeltek.ITOLED.Core.Interfaces;

/// <summary>
/// Provides PLC communication methods required by the DIO controller.
/// Abstracts Delphi's <c>g_CommPLC : TCommPLC_ECS</c> global.
/// <para>Only the methods actually referenced by ControlDio_OC are declared here.
/// The full PLC service will be expanded when CommPLC_ECS.pas is converted.</para>
/// </summary>
public interface IPlcService
{
    /// <summary>
    /// Checks whether the robot is busy for the given group.
    /// <para>Delphi origin: g_CommPLC.IsBusy_Robot(nGroup)</para>
    /// </summary>
    /// <param name="group">Channel group (0=TOP, 1=BOTTOM).</param>
    /// <returns>True if the robot is currently busy.</returns>
    bool IsBusyRobot(int group);

    /// <summary>
    /// Checks whether a specific robot bit is ON at the given address.
    /// <para>Delphi origin: g_CommPLC.IsBitOn_Robot(address)</para>
    /// </summary>
    /// <param name="address">PLC bit address (e.g., 0x0F, 0x2F).</param>
    /// <returns>True if the bit is ON.</returns>
    bool IsBitOnRobot(int address);

    /// <summary>
    /// Clears the robot request signal for a channel/group.
    /// <para>Delphi origin: g_CommPLC.EQP_Clear_ROBOT_Request(index)</para>
    /// </summary>
    /// <param name="index">Channel or group index.</param>
    void ClearRobotRequest(int index);
}
