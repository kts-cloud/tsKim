// PG 통신 관련 Define.
///	<summary>
///	  LGD GMES 관련 Define class
///	</summary>
unit DefGmes;

interface
  const
    // MES MESSAGE INDEX
    MES_UNKNOWN      = 0;   //JHHWANG-GMES: 2018-06-20
    MES_EAYT         = 101;
    MES_UCHK         = 102;
    MES_EDTI         = 103;
    MES_FLDR         = 104;
    MES_PCHK         = 105;
		MES_EICR         = 106;
    MES_EQCC         = 107;
    MES_LPHI         = 108;
    MES_REPN         = 109;
		MES_APDR         = 110;
    MES_INS_PCHK     = 111;
		MES_RPR_VSIR     = 112;
		MES_RPR_EIJR     = 113;
		MES_EIJR         = 114;
    MES_ZSET         = 115;
    MES_SGEN         = 116;
    //  EAS MESSAGE INDEX
    EAS_APDR         = 201;
    EAS_EICR         = 202;

    R2R_EODS         = 301; // Added by KTS 2023-02-24 오전 11:32:59 R2R 관련 추가
    R2R_EODS_R       = 302; // Added by KTS 2023-02-24 오전 11:32:59 R2R 관련 추가
    R2R_EODA         = 303; // Added by KTS 2023-02-24 오전 11:32:59 R2R 관련 추가

    PREFIX_COMBI      = 'C_YT_ASSY_Module_China_';
    PREFIX_DEFECT     = 'TOTAL_DEFECT_CODE_';
    PREFIX_FULL_DEF   = 'TOTAL_DEFECT_CODE_FULL_';
    PREFIX_REPAIR     = 'TOTAL_REPAIR_CODE_';
    PREFIX_FULL_REP   = 'TOTAL_REPAIR_CODE_FULL_';

    COMBI_FILE        = 0;
    DEFECT_FILE       = 1;
    DEFECT_FULL_FILE  = 2;
    REPAIR_FILE       = 3;
    REPAIR_FULL_FILE  = 4;

		PCHK_OK_MSG       = 'PCHK OK!';
		EICR_OK_MSG       = 'EICR OK!';
		APDR_OK_MSG       = 'APDR OK!';
		RPR_EIJR_OK_MSG   = 'RPR_EIJR OK!';

implementation

end.
