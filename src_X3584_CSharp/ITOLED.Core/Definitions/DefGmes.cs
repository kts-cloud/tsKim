// ---------------------------------------------------------------------------
// DefGmes.cs
// Converted from Delphi: DefGmes.pas
// LGD GMES (MES/EAS/R2R) message indices, file prefixes, and status messages.
// ---------------------------------------------------------------------------

namespace Dongaeltek.ITOLED.Core.Definitions;

/// <summary>
/// GMES (Global MES) definition constants for MES/EAS/R2R message indices,
/// combination/defect/repair file prefixes, file type identifiers, and OK message strings.
/// <para>Delphi source: DefGmes.pas</para>
/// </summary>
public static class DefGmes
{
    #region MES Message Indices (MES_*)

    /// <summary>Unknown MES message. Delphi: MES_UNKNOWN</summary>
    public const int MesUnknown = 0;

    /// <summary>MES state fail. Delphi: MES_STATE_FAIL</summary>
    public const int MesStateFail = 1;

    /// <summary>Equipment Auto/Ready Transition. Delphi: MES_EAYT</summary>
    public const int MesEayt = 101;

    /// <summary>Unit check. Delphi: MES_UCHK</summary>
    public const int MesUchk = 102;

    /// <summary>Equipment Data Transfer Initiation. Delphi: MES_EDTI</summary>
    public const int MesEdti = 103;

    /// <summary>Folder. Delphi: MES_FLDR</summary>
    public const int MesFldr = 104;

    /// <summary>Process check. Delphi: MES_PCHK</summary>
    public const int MesPchk = 105;

    /// <summary>Equipment Inspection Complete Report. Delphi: MES_EICR</summary>
    public const int MesEicr = 106;

    /// <summary>Equipment Quality Check Confirmation. Delphi: MES_EQCC</summary>
    public const int MesEqcc = 107;

    /// <summary>Lot Process History Information. Delphi: MES_LPHI</summary>
    public const int MesLphi = 108;

    /// <summary>Report notification. Delphi: MES_REPN</summary>
    public const int MesRepn = 109;

    /// <summary>Automatic Process Data Report. Delphi: MES_APDR</summary>
    public const int MesApdr = 110;

    /// <summary>Inspection process check. Delphi: MES_INS_PCHK</summary>
    public const int MesInsPchk = 111;

    /// <summary>Repair VSIR. Delphi: MES_RPR_VSIR</summary>
    public const int MesRprVsir = 112;

    /// <summary>Repair EIJR. Delphi: MES_RPR_EIJR</summary>
    public const int MesRprEijr = 113;

    /// <summary>EIJR. Delphi: MES_EIJR</summary>
    public const int MesEijr = 114;

    /// <summary>Z-axis setting. Delphi: MES_ZSET</summary>
    public const int MesZset = 115;

    /// <summary>Serial generation. Delphi: MES_SGEN</summary>
    public const int MesSgen = 116;

    /// <summary>Lot Process Information Report (M-GIB / P_GIB). Delphi: MES_LPIR</summary>
    public const int MesLpir = 117;

    #endregion

    #region EAS Message Indices (EAS_*)

    /// <summary>EAS Automatic Process Data Report. Delphi: EAS_APDR</summary>
    public const int EasApdr = 201;

    /// <summary>EAS Equipment Inspection Complete Report. Delphi: EAS_EICR</summary>
    public const int EasEicr = 202;

    #endregion

    #region R2R Message Indices (R2R_*)

    /// <summary>R2R EODS. Added 2023-02-24. Delphi: R2R_EODS</summary>
    public const int R2rEods = 301;

    /// <summary>R2R EODS response. Added 2023-02-24. Delphi: R2R_EODS_R</summary>
    public const int R2rEodsR = 302;

    /// <summary>R2R EODA. Added 2023-02-24. Delphi: R2R_EODA</summary>
    public const int R2rEoda = 303;

    /// <summary>R2R EAYT. Added 2023-07-17. Delphi: R2R_EAYT</summary>
    public const int R2rEayt = 304;

    /// <summary>R2R LOG. Added 2024-01-10. Delphi: R2R_LOG</summary>
    public const int R2rLog = 305;

    #endregion

    #region File Prefixes (PREFIX_*)

    /// <summary>Combination file prefix. Delphi: PREFIX_COMBI</summary>
    public const string PrefixCombi = "C_YT_ASSY_Module_China_";

    /// <summary>Defect code file prefix. Delphi: PREFIX_DEFECT</summary>
    public const string PrefixDefect = "TOTAL_DEFECT_CODE_";

    /// <summary>Full defect code file prefix. Delphi: PREFIX_FULL_DEF</summary>
    public const string PrefixFullDef = "TOTAL_DEFECT_CODE_FULL_";

    /// <summary>Repair code file prefix. Delphi: PREFIX_REPAIR</summary>
    public const string PrefixRepair = "TOTAL_REPAIR_CODE_";

    /// <summary>Full repair code file prefix. Delphi: PREFIX_FULL_REP</summary>
    public const string PrefixFullRep = "TOTAL_REPAIR_CODE_FULL_";

    #endregion

    #region File Type Identifiers (*_FILE)

    /// <summary>Combination file type. Delphi: COMBI_FILE</summary>
    public const int CombiFile = 0;

    /// <summary>Defect file type. Delphi: DEFECT_FILE</summary>
    public const int DefectFile = 1;

    /// <summary>Full defect file type. Delphi: DEFECT_FULL_FILE</summary>
    public const int DefectFullFile = 2;

    /// <summary>Repair file type. Delphi: REPAIR_FILE</summary>
    public const int RepairFile = 3;

    /// <summary>Full repair file type. Delphi: REPAIR_FULL_FILE</summary>
    public const int RepairFullFile = 4;

    #endregion

    #region OK Message Strings (*_OK_MSG)

    /// <summary>Process check OK. Delphi: PCHK_OK_MSG</summary>
    public const string PchkOkMsg = "PCHK OK!";

    /// <summary>Equipment Inspection Complete Report OK. Delphi: EICR_OK_MSG</summary>
    public const string EicrOkMsg = "EICR OK!";

    /// <summary>Automatic Process Data Report OK. Delphi: APDR_OK_MSG</summary>
    public const string ApdrOkMsg = "APDR OK!";

    /// <summary>Repair EIJR OK. Delphi: RPR_EIJR_OK_MSG</summary>
    public const string RprEijrOkMsg = "RPR_EIJR OK!";

    /// <summary>Lot Process Information Report OK. Delphi: LPIR_OK_MSG</summary>
    public const string LpirOkMsg = "LPIR OK!";

    #endregion
}
