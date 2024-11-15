`ifndef RISCV_ISA_DEFS_SV
`define RISCV_ISA_DEFS_SV

package riscv_isa_defs;

    parameter       NB_WORD         = 32;
    parameter       NB_BYTE         = 8;
    parameter       N_REGISTERS     = 32;
    parameter       NB_OPCODE       = 7;
    parameter       NB_OPERAND      = 5;
    
    parameter       NB_FUNCT7       = 7;
    parameter       NB_FUNCT5       = 5;
    parameter       NB_FUNCT3       = 3;
    parameter       NB_I_IMM        = 12;
    parameter       NB_I_IMM_11_6   = 6;
    parameter       NB_S_UIMM       = 7;
    parameter       NB_S_LIMM       = 5;

    parameter       NB_B_UUIMM      = 1;
    parameter       NB_B_ULIMM      = 6;
    parameter       NB_B_LUIMM      = 4;
    parameter       NB_B_LLIMM      = 1;

    parameter       NB_U_IMM        = 20;

    parameter       NB_J_UUIMM      = 1;
    parameter       NB_J_ULIMM      = 10;
    parameter       NB_J_LUIMM      = 1;
    parameter       NB_J_LLIMM      = 8;

    parameter       NB_CSR          = 12;

    

    typedef struct packed{
        logic   [NB_FUNCT7  - 1 : 0]    funct7;
        logic   [NB_OPERAND - 1 : 0]    rs2;   
        logic   [NB_OPERAND - 1 : 0]    rs1;   
        logic   [NB_FUNCT3  - 1 : 0]    funct3;
        logic   [NB_OPERAND - 1 : 0]    rd;    
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } r_type_t;

    typedef struct packed{
        logic   [NB_I_IMM   - 1 : 0]    imm;        
        logic   [NB_OPERAND - 1 : 0]    rs1;
        logic   [NB_FUNCT3  - 1 : 0]    funct3;
        logic   [NB_OPERAND - 1 : 0]    rd;
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } i_type_t;

    typedef struct packed{
        logic   [NB_S_UIMM  - 1 : 0]    upper_imm;
        logic   [NB_OPERAND - 1 : 0]    rs2;
        logic   [NB_OPERAND - 1 : 0]    rs1;
        logic   [NB_FUNCT3  - 1 : 0]    funct3;
        logic   [NB_S_LIMM  - 1 : 0]    lower_imm;
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } s_type_t;

    typedef struct packed{
        logic   [NB_B_UUIMM - 1 : 0]    imm12;
        logic   [NB_B_ULIMM - 1 : 0]    imm10_5;
        logic   [NB_OPERAND - 1 : 0]    rs2;
        logic   [NB_OPERAND - 1 : 0]    rs1;
        logic   [NB_FUNCT3  - 1 : 0]    funct3;
        logic   [NB_B_LUIMM - 1 : 0]    imm4_1;
        logic   [NB_B_LLIMM - 1 : 0]    imm11;
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } b_type_t;

    typedef struct packed{
        logic   [NB_U_IMM   - 1 : 0]    imm;
        logic   [NB_OPERAND - 1 : 0]    rd;
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } u_type_t;

    typedef struct packed{
        logic   [NB_J_UUIMM - 1 : 0]    imm20;
        logic   [NB_J_ULIMM - 1 : 0]    imm10_1;
        logic   [NB_J_LUIMM - 1 : 0]    imm11;
        logic   [NB_J_LLIMM - 1 : 0]    imm19_12;
        logic   [NB_OPERAND - 1 : 0]    rd;
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } j_type_t;

    typedef struct packed{
        logic   [NB_FUNCT5  - 1 : 0]    funct5;
        logic                           aq;
        logic                           rl;
        logic   [NB_OPERAND - 1 : 0]    rs2;   
        logic   [NB_OPERAND - 1 : 0]    rs1;   
        logic   [NB_FUNCT3  - 1 : 0]    funct3;
        logic   [NB_OPERAND - 1 : 0]    rd;    
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } a_type_t;

    typedef struct packed{
        logic   [NB_CSR     - 1 : 0]    csr;
        logic   [NB_OPERAND - 1 : 0]    rs1;   
        logic   [NB_FUNCT3  - 1 : 0]    funct3;
        logic   [NB_OPERAND - 1 : 0]    rd;    
        logic   [NB_OPCODE  - 1 : 0]    opcode;
    } csr_type_t;

    typedef union packed{
        logic   [NB_WORD    - 1 : 0]    instruction;
        r_type_t                        r_type;
        i_type_t                        i_type;
        s_type_t                        s_type;
        b_type_t                        b_type;
        u_type_t                        u_type;
        j_type_t                        j_type;
        a_type_t                        a_type;
        csr_type_t                      csr_type;
    } instruction_t;

    typedef enum logic[NB_OPCODE - 1 : 0]{
        LUI         = 7'b0110111,
        AUIPC       = 7'b0010111,
        JAL         = 7'b1101111,
        JALR        = 7'b1100111,
        BRANCH      = 7'b1100011,
        LOAD        = 7'b0000011,
        STORE       = 7'b0100011,
        OP_IMM      = 7'b0010011,
        OP          = 7'b0110011,
        OP_IMM_32   = 7'b0011011,
        OP_32       = 7'b0111011,
        AMO         = 7'b0101111,
        MISC_MEM    = 7'b0001111,
        SYSTEM      = 7'b1110011
        
    } opcodes;

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_BEQ      = 3'b000,
        F3_BNE      = 3'b001,
        F3_BLT      = 3'b100,
        F3_BGE      = 3'b101,
        F3_BLTU     = 3'b110,
        F3_BGEU     = 3'b111
    } branch_funct3;

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_LB       = 3'b000,
        F3_LH       = 3'b001,
        F3_LW       = 3'b010,
        F3_LBU      = 3'b100,
        F3_LHU      = 3'b101,
        F3_LWU      = 3'b110,
        F3_LD       = 3'b011
    } load_funct3;

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_SB       = 3'b000,
        F3_SH       = 3'b001,
        F3_SW       = 3'b010,
        F3_SD       = 3'b011
    } store_funct3;

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_ADD_SUB  = 3'b000,
        F3_SLL      = 3'b001,
        F3_SLT      = 3'b010,
        F3_SLTU     = 3'b011,
        F3_XOR      = 3'b100,
        F3_SRL_SRA  = 3'b101,        
        F3_OR       = 3'b110,
        F3_AND      = 3'b111       
    } i_r_funct3;


    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_JALR     = 3'b000                
    } jalr_funct3;

    typedef enum logic[NB_FUNCT7 - 1 : 0]{
        F7_ARITH    = 7'b0100000,
        F7_LOGIC    = 7'b0000000
    } i_r_funct7;

    typedef enum logic[NB_I_IMM_11_6 - 1 : 0]{
        IMM11_6_ARITH    = 6'b010000,
        IMM11_6_LOGIC    = 6'b000000
    } i_i_funct7;    

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_MUL_MULW    = 3'b000,
        F3_MULH        = 3'b001,
        F3_MULHSU      = 3'b010,
        F3_MULHU       = 3'b011,
        F3_DIV_DIVW    = 3'b100,
        F3_DIVU_DIVUW  = 3'b101,
        F3_REM_REMW    = 3'b110,
        F3_REMU_REMUW  = 3'b111
    } m_funct3;

    typedef enum logic[NB_FUNCT7 - 1 : 0]{
        F7_M    = 7'b0000001
    } m_funct7;

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_A32  = 3'b010,
        F3_A64  = 3'b011
    } a_funct3;

    typedef enum logic[NB_FUNCT5 - 1 : 0]{
        F5_LR       = 5'b00010,
        F5_SC       = 5'b00011,
        F5_AMOSWAP  = 5'b00001,
        F5_AMOADD   = 5'b00000,
        F5_AMOXOR   = 5'b00100,
        F5_AMOAND   = 5'b01100,
        F5_AMOOR    = 5'b01000,
        F5_AMOMIN   = 5'b10000,
        F5_AMOMAX   = 5'b10100,
        F5_AMOMINU  = 5'b11000,
        F5_AMOMAXU  = 5'b11100
    } m_funct5;

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_FENCE    = 3'b000,
        F3_FENCEI   = 3'b001
    } mism_mem_funct3;

    typedef enum logic[NB_CSR   - 1 : 0]{
        ECALL       = 12'b000000000000,
        EBREAK      = 12'b000000000001
    } system_csr;

    typedef enum logic[NB_FUNCT3 - 1 : 0]{
        F3_ECALL_EBREAK = 3'b000,
        F3_CSRRW        = 3'b001,
        F3_CSRRS        = 3'b010,
        F3_CSRRC        = 3'b011,
        F3_CSRRWI       = 3'b101,
        F3_CSRRSI       = 3'b110,
        F3_CSRRCI       = 3'b111
    } csr_funct3;

endpackage

`endif