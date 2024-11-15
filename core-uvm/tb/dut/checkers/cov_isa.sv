
import riscv_isa_defs::*;

module cov_isa
    #(parameter COMMIT_WIDTH=1) (
    input                                   i_clk,
    input                                   i_rsn, 
    input                                   i_valid[COMMIT_WIDTH-1:0],
    input riscv_isa_defs::instruction_t     i_instruction[COMMIT_WIDTH-1:0]
    );

    riscv_isa_defs::instruction_t instruction; 
    logic valid; 
    integer i;

    // ------------------------------------------------
    //          ALL TYPES OF INSTRUCTIONS
    // ------------------------------------------------

    // R TYPE instructions
    covergroup cg_rv32i_r_type;
        cp_r_opcode: coverpoint instruction.r_type.opcode iff ( i_rsn ){
            bins opcode = {OP}; //opcode corresponds to r_type
        }

        cp_r_funct3: coverpoint instruction.r_type.funct3 iff ( i_rsn ){ //funct3 all possible values
            option.weight = 0;
            bins ADD_SUB    = {F3_ADD_SUB};
            bins SLL        = {F3_SLL};
            bins SLT        = {F3_SLT};
            bins SLTU       = {F3_SLTU};
            bins XOR        = {F3_XOR};
            bins SRL_SRA    = {F3_SRL_SRA};
            bins OR         = {F3_OR};
            bins AND        = {F3_AND};            
        }

        cp_r_funct7: coverpoint instruction.r_type.funct7 iff ( i_rsn ){ //funct7 all possible values
            option.weight = 0;
            bins ARIT       = {F7_ARITH};
            bins LOGIC      = {F7_LOGIC};        
        }

        cp_r_cross_all: cross cp_r_opcode, cp_r_funct3 iff ( i_rsn ) ; //all possible combinations of R opcode and type of operation

        cp_r_cross_arith_logic: cross cp_r_opcode, cp_r_funct3, cp_r_funct7 iff ( i_rsn ){ //for operations that can be arithmetic or logic
            // option.cross_auto_bin_max = 0; //we only care about two, defined below
	    // Note - cross_auto_bins_max was removed from the IEEE LRM in 1800-2005. It was poorly defined. Use ignore_bins instead.
            //OR => bins ADD_SUB = binsof( cp_r_funct3) intersect {(F3_ADD_SUB)};
            //OR => bins ADD_SUB = binsof( cp_r_funct3.ADD_SUB);
            bins ADD_SUB = cp_r_cross_arith_logic with (cp_r_funct3 == F3_ADD_SUB);
            bins SRL_SRA = cp_r_cross_arith_logic with (cp_r_funct3 == F3_SRL_SRA);
            ignore_bins not_legal = cp_r_cross_arith_logic with (cp_r_funct3 != F3_ADD_SUB && cp_r_funct3 != F3_SRL_SRA);
            //OR => ignore_bins not_legal = (binsof( cp_r_funct3) intersect { (F3_SLL) } || binsof( cp_r_funct3) intersect { (F3_SLT) } || binsof( cp_r_funct3) intersect { (F3_SLTU) } || binsof( cp_r_funct3) intersect { (F3_XOR) } || binsof( cp_r_funct3) intersect {(F3_OR) } || binsof( cp_r_funct3) intersect { (F3_AND) });
        }        

    endgroup: cg_rv32i_r_type

    cg_rv32i_r_type u_cg_rv32i_r_type;

    covergroup cg_rv64i_r_type;
        cp_r_opcode: coverpoint instruction.r_type.opcode iff ( i_rsn ){
            bins opcode = {OP_32}; //opcode corresponds to r_type
        }

        cp_r_funct3: coverpoint instruction.r_type.funct3 iff ( i_rsn ){ //funct3 all possible values
            option.weight = 0;
            bins ADDW_SUBW  = {F3_ADD_SUB};
            bins SLLW       = {F3_SLL};
            bins SRLW_SRAW  = {F3_SRL_SRA};
        }

        cp_r_funct7: coverpoint instruction.r_type.funct7 iff ( i_rsn ){ //funct7 all possible values
            option.weight = 0;
            bins ARIT       = {F7_ARITH};
            bins LOGIC      = {F7_LOGIC};        
        }

        cp_r_cross_all: cross cp_r_opcode, cp_r_funct3 iff ( i_rsn ); //all possible combinations of R opcode and type of operation

        cp_r_cross_arith_logic: cross cp_r_opcode, cp_r_funct3, cp_r_funct7 iff ( i_rsn ){ //for operations that can be arithmetic or logic
            // option.cross_auto_bin_max = 0; //we only care about two, defined below
	    // Note - cross_auto_bins_max was removed from the IEEE LRM in 1800-2005. It was poorly defined. Use ignore_bins instead.
            bins ADDW_SUBW = cp_r_cross_arith_logic with (cp_r_funct3 == F3_ADD_SUB);
            bins SRLW_SRAW = cp_r_cross_arith_logic with (cp_r_funct3 == F3_SRL_SRA);
            ignore_bins not_legal = cp_r_cross_arith_logic with (cp_r_funct3 != F3_ADD_SUB && cp_r_funct3 != F3_SRL_SRA);
            //OR => ignore_bins not_legal = binsof( cp_r_funct3) intersect { (F3_SLL) } ;
        }        

    endgroup: cg_rv64i_r_type

    cg_rv64i_r_type u_cg_rv64i_r_type;

    //I TYPE instructions - immediate
    covergroup cg_rv32i_i_type;
        cp_i_opcode: coverpoint instruction.i_type.opcode iff ( i_rsn ){
            bins opcode = {OP_IMM}; //opcode corresponds to i_type
        }

        cp_i_funct3: coverpoint instruction.i_type.funct3 iff ( i_rsn ){ //funct3 all possible values
            option.weight = 0;
            bins ADDI       = {F3_ADD_SUB}; //ADDI
            bins SLLI       = {F3_SLL};     //SLLI
            bins SLTI       = {F3_SLT};     //SLTI
            bins SLTIU      = {F3_SLTU};    //SLTIU
            bins XORI       = {F3_XOR};     //XORI
            bins SRLI_SRAI  = {F3_SRL_SRA}; //SRLI or SRAI
            bins ORI        = {F3_OR};      //ORI
            bins ANDI       = {F3_AND};      //ANDI      
        }

        cp_i_funct7: coverpoint instruction.r_type.funct7 iff ( i_rsn ){ //funct7 all possible values
            option.weight = 0;
            bins ARIT       = {F7_ARITH};   //SRAI
            bins LOGIC      = {F7_LOGIC};   //SRLI     
        }
        
        cp_i_cross_all: cross cp_i_opcode, cp_i_funct3 iff ( i_rsn ); //all possible combinations of I opcode and type of operation

        cp_i_cross_arith_logic: cross cp_i_opcode, cp_i_funct3, cp_i_funct7 iff ( i_rsn ){ //for operations that can be arithmetic or logic
            // option.cross_auto_bin_max = 0; //we only care about two, defined below
	    // Note - cross_auto_bins_max was removed from the IEEE LRM in 1800-2005. It was poorly defined. Use ignore_bins instead.
            bins SRLI_SRAI   = cp_i_cross_arith_logic with (cp_i_funct3 == F3_SRL_SRA);                        
            ignore_bins not_legal = cp_i_cross_arith_logic with (cp_i_funct3 != F3_SRL_SRA);
        }   
    endgroup: cg_rv32i_i_type

    cg_rv32i_i_type u_cg_rv32i_i_type;

    covergroup cg_rv64i_i_type;
        cp_i_opcode_32: coverpoint instruction.i_type.opcode iff ( i_rsn ){
            bins opcode = {OP_IMM_32}; //opcode corresponds to i_type
        }

        cp_i_funct3_32: coverpoint instruction.i_type.funct3 iff ( i_rsn ){ //funct3 all possible values
            option.weight = 0;
            bins ADDIW      = {F3_ADD_SUB}; //ADDIW
            bins SLLIW      = {F3_SLL};     //SLLIw
            bins SRLIW_SRAIW= {F3_SRL_SRA}; //SRLIW or SRAIW
        }

        cp_i_funct7_32: coverpoint instruction.r_type.funct7 iff ( i_rsn ){ //funct7 all possible values
            option.weight = 0;
            bins ARIT       = {F7_ARITH};   //SRAI
            bins LOGIC      = {F7_LOGIC};   //SRLI     
        }
        
        cp_i_cross_all_32: cross cp_i_opcode_32, cp_i_funct3_32 iff ( i_rsn ) ; //all possible combinations of I opcode and type of operation

        cp_i_cross_arith_logic_32: cross cp_i_opcode_32, cp_i_funct3_32, cp_i_funct7_32 iff ( i_rsn ){ //for operations that can be arithmetic or logic
            // option.cross_auto_bin_max = 0; //we only care about two, defined below
	    // Note - cross_auto_bins_max was removed from the IEEE LRM in 1800-2005. It was poorly defined. Use ignore_bins instead.
            bins SRLIW_SRAIW   = cp_i_cross_arith_logic_32 with (cp_i_funct3_32 == F3_SRL_SRA);
            ignore_bins not_legal = cp_i_cross_arith_logic_32 with (cp_i_funct3_32 != F3_SRL_SRA);
        } 

        cp_i_opcode: coverpoint instruction.i_type.opcode iff ( i_rsn ){
            bins opcide = {OP_IMM};
        }  

        cp_i_funct3 : coverpoint instruction.i_type.funct3 iff ( i_rsn ){
            bins SLLI       = {F3_SLL};
            bins SRLI_SRAI  = {F3_SRL_SRA};
        }

        cp_i_imm11_6 : coverpoint instruction.i_type.imm[11:6] iff ( i_rsn ){
            bins ARIT       = {IMM11_6_ARITH};   //SRAI
            bins LOGIC      = {IMM11_6_LOGIC};   //SRLI
        }

        cp_cross_all_64 : cross cp_i_opcode, cp_i_funct3 iff ( i_rsn ) ;
        
        cp_i_cross_arith_logic: cross cp_i_opcode, cp_i_funct3, cp_i_imm11_6 iff ( i_rsn ){ //for operations that can be arithmetic or logic
            // option.cross_auto_bin_max = 0; //we only care about two, defined below
	    // Note - cross_auto_bins_max was removed from the IEEE LRM in 1800-2005. It was poorly defined. Use ignore_bins instead.
            bins SRLI_SRAI   = cp_i_cross_arith_logic with (cp_i_funct3 == F3_SRL_SRA);
            ignore_bins not_legal = cp_i_cross_arith_logic with (cp_i_funct3 != F3_SRL_SRA);
        } 
    endgroup: cg_rv64i_i_type

    cg_rv64i_i_type u_cg_rv64i_i_type;

    //I TYPE instructions - LOAD instructions
    covergroup cg_load_type;
        cp_load_opcode: coverpoint instruction.i_type.opcode iff ( i_rsn ){
            bins opcode = {LOAD};
        }

        cp_load_funct3: coverpoint instruction.i_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins LB     = {F3_LB };
            bins LH     = {F3_LH };
            bins LW     = {F3_LW };
            bins LBU    = {F3_LBU};
            bins LHU    = {F3_LHU};
            bins LWU    = {F3_LWU};
            bins LD     = {F3_LD};
        }

        cp_cross_load_all: cross cp_load_opcode, cp_load_funct3 iff ( i_rsn );
    endgroup: cg_load_type

    cg_load_type u_cg_load_type;

    //I TYPE instructions - JALR instruction
    covergroup cg_jalr_type;
        cp_jalr_opcode: coverpoint instruction.i_type.opcode iff ( i_rsn ){
            bins opcode = {riscv_isa_defs::JALR};
        }        
    endgroup: cg_jalr_type

    cg_jalr_type u_cg_jalr_type;

    //U TYPE instructions
    covergroup cg_u_type;
        cp_u_opcode: coverpoint instruction.u_type.opcode iff ( i_rsn ){
            bins opcode[] = {LUI, AUIPC};
        }
    endgroup: cg_u_type

    cg_u_type u_cg_u_type;

    //J TYPE instructions
    covergroup cg_j_type;
        cp_j_opcode: coverpoint instruction.j_type.opcode iff ( i_rsn ){
            bins opcode = {JAL};
        }
    endgroup: cg_j_type

    cg_j_type u_cg_j_type;

    //B TYPE instructions 
    covergroup cg_b_type;
        cp_b_opcode: coverpoint instruction.b_type.opcode iff ( i_rsn ){
            bins opcode = {riscv_isa_defs::BRANCH};
        }

        cp_b_funct3: coverpoint instruction.b_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins BEQ    = {F3_BEQ };
            bins BNE    = {F3_BNE };
            bins BLT    = {F3_BLT };
            bins BGE    = {F3_BGE };
            bins BLTU   = {F3_BLTU};
            bins BGEU   = {F3_BGEU};
        }

        cp_cross_b_all: cross cp_b_opcode, cp_b_funct3 iff ( i_rsn ); 
    endgroup

    cg_b_type u_cg_b_type;

    //S TYPE instructions
    covergroup cg_s_type;
        cp_s_opcode: coverpoint instruction.s_type.opcode iff ( i_rsn ){
            bins opcode = {STORE};
        }

        cp_s_funct3: coverpoint instruction.s_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins SB     = {F3_SB};
            bins SH     = {F3_SH};
            bins SW     = {F3_SW};
            bins SD     = {F3_SD};
        }

        cp_cross_s_all: cross cp_s_opcode, cp_s_funct3 iff ( i_rsn );
    endgroup

    cg_s_type u_cg_s_type;

    //M Extension
    covergroup cg_m_extension;
        cp_m_opcode_32: coverpoint instruction.r_type.opcode iff ( i_rsn ){
            bins opcode = {OP};
            option.weight = 0;
        }

        cp_m_opcode_64: coverpoint instruction.r_type.opcode iff ( i_rsn ){
            bins opcode = {OP_32};
            option.weight = 0;
        }

        cp_m_funct3: coverpoint instruction.r_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins MUL_MULW   = {F3_MUL_MULW};
            bins MULH       = {F3_MULH};
            bins MULHSU     = {F3_MULHSU};
            bins MULHU      = {F3_MULHU};
            bins DIV_DIVW   = {F3_DIV_DIVW};
            bins DIVU_DIVUW = {F3_DIVU_DIVUW};
            bins REM_REMW   = {F3_REM_REMW};
            bins REMU_REMUW = {F3_REMU_REMUW};
        }

        cp_m_funct7 : coverpoint instruction.r_type.funct7 iff ( i_rsn ){
            option.weight = 0;
            bins F7_M       = {F7_M};
        }

        cp_rv32m : cross cp_m_opcode_32, cp_m_funct7, cp_m_funct3 iff ( i_rsn );
        cp_rv64m : cross cp_m_opcode_64, cp_m_funct7, cp_m_funct3 iff ( i_rsn ){
            // option.cross_auto_bin_max = 0; //we only care about two, defined below
	    // Note - cross_auto_bins_max was removed from the IEEE LRM in 1800-2005. It was poorly defined. Use ignore_bins instead.
            bins MULW   = cp_rv64m with (cp_m_funct3 == F3_MUL_MULW);
            bins DIVW   = cp_rv64m with (cp_m_funct3 == F3_DIV_DIVW);
            bins DUVUW  = cp_rv64m with (cp_m_funct3 == F3_DIVU_DIVUW);
            bins REMW   = cp_rv64m with (cp_m_funct3 == F3_REM_REMW);
            bins REMUW  = cp_rv64m with (cp_m_funct3 == F3_REMU_REMUW);
            ignore_bins not_legal = cp_rv64m with (cp_m_funct3 != F3_MUL_MULW && cp_m_funct3 != F3_DIV_DIVW && cp_m_funct3 != F3_DIVU_DIVUW && cp_m_funct3 != F3_REM_REMW && cp_m_funct3 != F3_REMU_REMUW);
        }
    endgroup

    cg_m_extension u_cg_m_extension;

    //A Extension
    covergroup  cg_a_extension;
        cp_a_opcode: coverpoint instruction.a_type.opcode iff ( i_rsn ){
            // option.weight = 0;
            bins opcode = {AMO};
        }

        cp_a_funct3_32 : coverpoint instruction.a_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins A32 = {F3_A32};
        }

        cp_a_funct3_64 : coverpoint instruction.a_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins A64 = {F3_A64};
        }

        cp_a_funct5 : coverpoint instruction.a_type.funct5 iff ( i_rsn ){
            option.weight = 0;
            bins LR         = {F5_LR};
            bins SC         = {F5_SC};
            bins AMOSWAP    = {F5_AMOSWAP};
            bins AMOADD     = {F5_AMOADD};
            bins AMOXOR     = {F5_AMOXOR};
            bins AMOAND     = {F5_AMOAND};
            bins AMOOR      = {F5_AMOOR};
            bins AMOMIN     = {F5_AMOMIN};
            bins AMOMAX     = {F5_AMOMAX};
            bins AMOMINU    = {F5_AMOMINU};
            bins AMOMAXU    = {F5_AMOMAXU};
        }

        cp_a32: cross cp_a_opcode, cp_a_funct3_32, cp_a_funct5 iff ( i_rsn );
        cp_a64: cross cp_a_opcode, cp_a_funct3_64, cp_a_funct5 iff ( i_rsn );           
    endgroup :  cg_a_extension

    cg_a_extension u_cg_a_extension;
    //MISC_MEM
    covergroup cg_misc_mem;
        cp_opcode : coverpoint instruction.i_type.opcode iff ( i_rsn ){
            option.weight = 0;
            bins opcode = {MISC_MEM};
        }

        cp_funct3 : coverpoint instruction.i_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins FENCE  = {F3_FENCE};
            bins FENCEI = {F3_FENCEI};
        }

        cp_misc_mem : cross cp_opcode, cp_funct3 iff ( i_rsn ) ;
    endgroup : cg_misc_mem

    cg_misc_mem u_cg_misc_mem;

    //SYSTEM/CSR

    covergroup cg_csr;
        cp_opcode : coverpoint instruction.csr_type.opcode iff ( i_rsn ){
            // option.weight = 0;
            bins opcode = {SYSTEM};
        }

        cp_funct3 : coverpoint instruction.csr_type.funct3 iff ( i_rsn ){
            option.weight = 0;
            bins ECALL_EBREAK   = {F3_ECALL_EBREAK};
            bins CSRRW          = {F3_CSRRW };
            bins CSRRS          = {F3_CSRRS };
            bins CSRRC          = {F3_CSRRC };
            bins CSRRWI         = {F3_CSRRWI};
            bins CSRRSI         = {F3_CSRRSI};
            bins CSRRCI         = {F3_CSRRCI};
        }
        
        cp_csr : coverpoint instruction.csr_type.csr iff ( i_rsn ){
            option.weight = 0;
            bins ECALL  = {riscv_isa_defs::ECALL};
            bins EBREAK = {riscv_isa_defs::EBREAK};
        }

        cp_system_csr : cross cp_opcode, cp_funct3 iff ( i_rsn );
        cp_ecall_ebreak : cross cp_opcode, cp_funct3, cp_csr iff ( i_rsn ){
            // option.cross_auto_bin_max = 0; //we only care about two, defined below
	    // Note - cross_auto_bins_max was removed from the IEEE LRM in 1800-2005. It was poorly defined. Use ignore_bins instead.
            bins ecall_ebreak   = cp_ecall_ebreak with (cp_funct3 == F3_ECALL_EBREAK);
            ignore_bins not_legal = cp_ecall_ebreak with (cp_funct3 != F3_ECALL_EBREAK);
        }

    endgroup : cg_csr

    cg_csr u_cg_csr;
    //------------------------------------------------
    //          ALL REGISTERS AS SOURCE AND OPERAND
    //------------------------------------------------

    covergroup cg_registers;
        cp_source1: coverpoint instruction.r_type.rs1 iff ( i_rsn ){
            bins all[] = {[0:31]};
        }

        cp_source2: coverpoint instruction.r_type.rs2 iff ( i_rsn ){
            bins all[] = {[0:31]};
        }

        cp_dest: coverpoint instruction.r_type.rd iff ( i_rsn ){
            bins all[] = {[0:31]};
        }
    endgroup: cg_registers

    cg_registers u_cg_registers;

    initial
    begin
        u_cg_rv32i_r_type   = new();
        u_cg_rv64i_r_type   = new();
        u_cg_rv32i_i_type   = new();
        u_cg_rv64i_i_type   = new();
        u_cg_load_type      = new();
        u_cg_jalr_type      = new();
        u_cg_u_type         = new();
        u_cg_j_type         = new();
        u_cg_b_type         = new();
        u_cg_s_type         = new();
        u_cg_m_extension    = new();
        u_cg_a_extension    = new();
        u_cg_misc_mem       = new();
        u_cg_csr            = new();
        u_cg_registers      = new();
    end

    always @(posedge i_clk) begin
        for(i = 0; i < COMMIT_WIDTH; i++) begin
            if (i_valid[i]) begin
                instruction = i_instruction[i];
                valid = i_valid[i];
                #1;
                u_cg_rv32i_r_type.sample();
                u_cg_rv64i_r_type.sample();
                u_cg_rv32i_i_type.sample();
                u_cg_rv64i_i_type.sample();
                u_cg_load_type.sample();
                u_cg_jalr_type.sample();   
                u_cg_u_type.sample();   
                u_cg_j_type.sample();      
                u_cg_b_type.sample();
                u_cg_s_type.sample();
                u_cg_m_extension.sample();
                u_cg_a_extension.sample();  
                u_cg_misc_mem.sample();   
                u_cg_csr.sample();
                u_cg_registers.sample();      
                #1;  
            end
        end
    end



endmodule : cov_isa
