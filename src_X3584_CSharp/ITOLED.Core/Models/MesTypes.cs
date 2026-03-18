// =============================================================================
// MesTypes.cs
// Converted from Delphi: src_X3584\CommonClass.pas
// Contains: TGmesCode (line 397), TAAMode (line 405), TLastestInspInfo (line 412),
//           TCombiCodeData (line 506), TDfsConfInfo (line 494)
// =============================================================================

using System.Collections.Generic;

namespace Dongaeltek.ITOLED.Core.Models
{
    /// <summary>
    /// GMES defect code record.
    /// <para>Original Delphi: TGmesCode = packed record (CommonClass.pas line 397)</para>
    /// <para>Format: 1,Optical Compensation,Optical Defect,OD01,EEPROM Read Fail,A06-B01-G78</para>
    /// </summary>
    public class GmesCode
    {
        /// <summary>
        /// Index (1, 2, 3...).
        /// <para>Delphi field: nIdx : Integer</para>
        /// </summary>
        public int Idx { get; set; }

        /// <summary>
        /// Error code (e.g., "OD01").
        /// <para>Delphi field: sErrCode : string</para>
        /// </summary>
        public string ErrCode { get; set; } = string.Empty;

        /// <summary>
        /// Error message (e.g., "EEPROM Read Fail").
        /// <para>Delphi field: sErrMsg : string</para>
        /// </summary>
        public string ErrMsg { get; set; } = string.Empty;

        /// <summary>
        /// MES code (e.g., "A06-B01-G78").
        /// <para>Delphi field: MES_Code : string</para>
        /// </summary>
        public string MESCode { get; set; } = string.Empty;

        /// <summary>
        /// Option flag for Pre OC MES/ECS transmission.
        /// <para>Delphi field: Option : Integer</para>
        /// </summary>
        public int Option { get; set; }
    }

    /// <summary>
    /// AA (Auto-Adjust) mode configuration per defect code.
    /// <para>Original Delphi: TAAMode = packed record (CommonClass.pas line 405)</para>
    /// </summary>
    public class AAMode
    {
        /// <summary>
        /// Index (1, 2, 3...).
        /// <para>Delphi field: nIdx : Integer</para>
        /// </summary>
        public int Idx { get; set; }

        /// <summary>
        /// Error code (e.g., "OD01").
        /// <para>Delphi field: sErrCode : string</para>
        /// </summary>
        public string ErrCode { get; set; } = string.Empty;

        /// <summary>
        /// DLL inspection type version (1, 2, 3).
        /// <para>Delphi field: nInspectionType : Integer</para>
        /// </summary>
        public int InspectionType { get; set; }

        /// <summary>
        /// DLL inspection count.
        /// <para>Delphi field: nInspectionCnt : Integer</para>
        /// </summary>
        public int InspectionCnt { get; set; }
    }

    /// <summary>
    /// Latest inspection info for defect code to inspection type mapping.
    /// <para>Original Delphi: TLastestInspInfo = packed record (CommonClass.pas line 412)</para>
    /// </summary>
    public class LastestInspInfo
    {
        /// <summary>
        /// Index (1, 2, 3...).
        /// <para>Delphi field: nIdx : Integer</para>
        /// </summary>
        public int Idx { get; set; }

        /// <summary>
        /// Label 1 (e.g., "#OC").
        /// <para>Delphi field: sLabel1 : string</para>
        /// </summary>
        public string Label1 { get; set; } = string.Empty;

        /// <summary>
        /// Label 2 (e.g., "#LGD DLL").
        /// <para>Delphi field: sLabel2 : string</para>
        /// </summary>
        public string Label2 { get; set; } = string.Empty;

        /// <summary>
        /// Defect code (e.g., "#DEFECT_CODE").
        /// <para>Delphi field: sDefectCode : string</para>
        /// </summary>
        public string DefectCode { get; set; } = string.Empty;

        /// <summary>
        /// Type identifier.
        /// <para>Delphi field: nType : Integer</para>
        /// </summary>
        public int Type { get; set; }
    }

    /// <summary>
    /// Combi code data for defect matrix and recipe configuration.
    /// <para>Original Delphi: TCombiCodeData = record (CommonClass.pas line 506)</para>
    /// </summary>
    public class CombiCodeData
    {
        /// <summary>
        /// INI file name.
        /// <para>Delphi field: sINIFileName : string</para>
        /// </summary>
        public string IniFileName { get; set; } = string.Empty;

        /// <summary>
        /// INI download time (for FLDR).
        /// <para>Delphi field: sINIDownTime : string</para>
        /// </summary>
        public string IniDownTime { get; set; } = string.Empty;

        /// <summary>
        /// Version string.
        /// <para>Delphi field: sVersion : string</para>
        /// </summary>
        public string Version { get; set; } = string.Empty;

        /// <summary>
        /// Grid column count.
        /// <para>Delphi field: nGridCol : Integer</para>
        /// </summary>
        public int GridCol { get; set; }

        /// <summary>
        /// Grid row count.
        /// <para>Delphi field: nGridRow : Integer</para>
        /// </summary>
        public int GridRow { get; set; }

        /// <summary>
        /// Origin setting.
        /// <para>Delphi field: nOrigin : Integer</para>
        /// </summary>
        public int Origin { get; set; }

        /// <summary>
        /// Recipe name (model recipe).
        /// <para>Delphi field: sRcpName : string</para>
        /// </summary>
        public string RcpName { get; set; } = string.Empty;

        /// <summary>
        /// Process number.
        /// <para>Delphi field: sProcessNo : string</para>
        /// </summary>
        public string ProcessNo { get; set; } = string.Empty;

        /// <summary>
        /// Router number.
        /// <para>Delphi field: nRouterNo : Integer</para>
        /// </summary>
        public int RouterNo { get; set; }

        /// <summary>
        /// Secondary origin setting.
        /// <para>Delphi field: nOrigin2 : Integer</para>
        /// </summary>
        public int Origin2 { get; set; }

        /// <summary>
        /// Secondary recipe name.
        /// <para>Delphi field: sRcpName2 : string</para>
        /// </summary>
        public string RcpName2 { get; set; } = string.Empty;

        /// <summary>
        /// Secondary process number.
        /// <para>Delphi field: sProcessNo2 : string</para>
        /// </summary>
        public string ProcessNo2 { get; set; } = string.Empty;

        /// <summary>
        /// Secondary router number.
        /// <para>Delphi field: nRouterNo2 : Integer</para>
        /// </summary>
        public int RouterNo2 { get; set; }

        /// <summary>
        /// Main button labels (5 buttons).
        /// <para>Delphi field: MainButton : array[0..4] of string</para>
        /// </summary>
        public string[] MainButton { get; set; }

        /// <summary>
        /// Defect matrix (5 categories x 100 defects max).
        /// <para>Delphi field: DefectMat : array[0..4] of array[0..99] of string</para>
        /// </summary>
        public string[][] DefectMat { get; set; }

        /// <summary>
        /// Color values for each defect category.
        /// <para>Delphi field: Color : array[0..4] of Integer</para>
        /// </summary>
        public int[] Color { get; set; }

        /// <summary>
        /// GIB OK values (dynamic 2D array).
        /// <para>Delphi field: GibOK : array of array of string</para>
        /// </summary>
        public List<List<string>> GibOK { get; set; } = new List<List<string>>();

        /// <summary>
        /// Priority strings per category.
        /// <para>Delphi field: Priority : array[0..4] of string</para>
        /// </summary>
        public string[] Priority { get; set; }

        /// <summary>
        /// Origin value.
        /// <para>Delphi field: Origin : Integer</para>
        /// </summary>
        public int OriginValue { get; set; }

        /// <summary>
        /// Authority flag.
        /// <para>Delphi field: bAuthority : Boolean</para>
        /// </summary>
        public bool Authority { get; set; }

        /// <summary>
        /// Defect count.
        /// <para>Delphi field: DefectCnt : Integer</para>
        /// </summary>
        public int DefectCnt { get; set; }

        /// <summary>
        /// Initializes arrays with proper sizes.
        /// </summary>
        public CombiCodeData()
        {
            MainButton = new string[5];
            DefectMat = new string[5][];
            Color = new int[5];
            Priority = new string[5];

            for (int i = 0; i < 5; i++)
            {
                MainButton[i] = string.Empty;
                Priority[i] = string.Empty;
                DefectMat[i] = new string[100];
                for (int j = 0; j < 100; j++)
                    DefectMat[i][j] = string.Empty;
            }
        }
    }

    /// <summary>
    /// DFS (Data File Server) configuration.
    /// <para>Original Delphi: TDfsConfInfo = record (CommonClass.pas line 494)</para>
    /// </summary>
    public class DfsConfInfo
    {
        /// <summary>
        /// DFS enabled.
        /// <para>Delphi field: bUseDfs : Boolean</para>
        /// </summary>
        public bool UseDfs { get; set; }

        /// <summary>
        /// DFS HEX compression enabled.
        /// <para>Delphi field: bDfsHexCompress : Boolean</para>
        /// </summary>
        public bool DfsHexCompress { get; set; }

        /// <summary>
        /// DFS HEX deletion enabled (valid only if DfsHexCompress is true).
        /// <para>Delphi field: bDfsHexDelete : Boolean</para>
        /// </summary>
        public bool DfsHexDelete { get; set; }

        /// <summary>
        /// DFS server IP address.
        /// <para>Delphi field: sDfsServerIP : string</para>
        /// </summary>
        public string DfsServerIP { get; set; } = string.Empty;

        /// <summary>
        /// DFS username.
        /// <para>Delphi field: sDfsUserName : string</para>
        /// </summary>
        public string DfsUserName { get; set; } = string.Empty;

        /// <summary>
        /// DFS password.
        /// <para>Delphi field: sDfsPassword : string</para>
        /// </summary>
        public string DfsPassword { get; set; } = string.Empty;

        /// <summary>
        /// Use combi download.
        /// <para>Delphi field: bUseCombiDown : Boolean</para>
        /// </summary>
        public bool UseCombiDown { get; set; }

        /// <summary>
        /// Combi download path.
        /// <para>Delphi field: sCombiDownPath : string</para>
        /// </summary>
        public string CombiDownPath { get; set; } = string.Empty;

        /// <summary>
        /// Process name.
        /// <para>Delphi field: sProcessName : string</para>
        /// </summary>
        public string ProcessName { get; set; } = string.Empty;
    }
}
