    
package common_params_pkg;

    localparam INSTR_WIDTH          = 32;
    localparam RI_WIDTH             = 8;    //ROB INDEX
    localparam FFLAG_WIDTH          = 5;
    localparam XREG_WIDTH           = 64;   //SCALAR CORE REGISTER WIDTH
    localparam NLS                  = 4;    //numboer of inflight loads and stores


    localparam N_LANES              = EPI_pkg::N_LANES;
    localparam MAX_ELEN_LANE        = EPI_pkg::MAX_ELEN_LANE;
    localparam MAX_64BIT_BLOCKS     = EPI_pkg::MAX_64BIT_BLOCKS;
    localparam ELEN                 = EPI_pkg::ELEN;
    localparam MAX_VLEN             = EPI_pkg::MAX_VLEN;
    localparam MIN_SEW              = EPI_pkg::MIN_SEW;
    // TODO remove
    localparam SB_WIDTH             = EPI_pkg::SB_WIDTH;

    // RISC-V INSTRUCTION BIT MAP
    localparam INSTR_OPCODE_START   = 0;  //  [6:0]
    localparam INSTR_OPCODE_WIDTH   = 7;
    localparam INSTR_OPCODE_END     = INSTR_OPCODE_START+INSTR_OPCODE_WIDTH-1;
    localparam INSTR_VDST_START     = 7; //  [11:7]
    localparam INSTR_VDST_WIDTH     = 5;
    localparam INSTR_VDST_END       = INSTR_VDST_START+INSTR_VDST_WIDTH-1;
    localparam INSTR_FUNCT3_START   = 12; //  [14:12]
    localparam INSTR_FUNCT3_WIDTH   = 3;
    localparam INSTR_FUNCT3_END     = INSTR_FUNCT3_START+INSTR_FUNCT3_WIDTH-1;
    localparam INSTR_VSRC1_START    = 15; //  [19:15]
    localparam INSTR_VSRC1_WIDTH    = 5;
    localparam INSTR_VSRC1_END      = INSTR_VSRC1_START+INSTR_VSRC1_WIDTH-1;
    localparam INSTR_VSRC2_START    = 20; //  [24:20]
    localparam INSTR_VSRC2_WIDTH    = 5;
    localparam INSTR_VSRC2_END      = INSTR_VSRC2_START+INSTR_VSRC2_WIDTH-1;
    localparam INSTR_MASK_BIT       = 25; //  [25]
    localparam INSTR_FUNCT6_START   = 26; //  [31:26]
    localparam INSTR_FUNCT6_WIDTH   = 6;
    localparam INSTR_FUNCT6_END     = INSTR_FUNCT6_START+INSTR_FUNCT6_WIDTH-1;
    localparam INSTR_MOP_START      = 26;
    localparam INSTR_MOP_WIDTH      = 3;
    localparam INSTR_MOP_END        = INSTR_MOP_START+INSTR_MOP_WIDTH-1;
    localparam INSTR_LUMOP_START    = 20;
    localparam INSTR_LUMOP_WIDTH    = 5;
    localparam INSTR_LUMOP_END      = INSTR_LUMOP_START+INSTR_LUMOP_WIDTH-1;
    localparam INSTR_SUMOP_START    = 20;
    localparam INSTR_SUMOP_WIDTH    = 5;
    localparam INSTR_SUMOP_END      = INSTR_SUMOP_START+INSTR_SUMOP_WIDTH-1;
    // CSR BITS-MAP
    localparam CSR_VSTART_WIDTH     = 14;
    localparam CSR_VLEN_WIDTH       = 15;
    localparam CSR_VXRM_WIDTH       = 2;
    localparam CSR_FRM_WIDTH        = 3;
    localparam CSR_VLMUL_WIDTH      = 2;
    localparam CSR_VSEW_WIDTH       = 2;
    localparam CSR_VILL_WIDTH       = 1;
    //SEQ ID
    // TODO remove
    localparam EL_ID_WIDTH          = $clog2(MAX_VLEN/MIN_SEW); // EREG: change it whenever the UVM value is set properly
    localparam V_REG_WIDTH          = 5;
    localparam DATA_PATH_WIDTH      = 64;
    localparam MEM_DATA_WIDTH       = DATA_PATH_WIDTH*N_LANES; // 512 BITS
    localparam EL_OFFSET_WIDTH      = $clog2(MEM_DATA_WIDTH/MIN_SEW);
    localparam EL_COUNT_WIDTH       = $clog2(MEM_DATA_WIDTH/MIN_SEW+1);
    localparam SEQ_ID_WIDTH         = (SB_WIDTH+EL_COUNT_WIDTH+EL_OFFSET_WIDTH+EL_ID_WIDTH+V_REG_WIDTH);

    
endpackage
