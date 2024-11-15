`ifndef MACROS
`define MACROS

    `define IS_LOAD(_ins) \
        (_ins[EPI_pkg::INSTR_OPCODE_WIDTH-1:0] == 7'b0000111)

    `define IS_STORE(_ins) \
        (_ins[EPI_pkg::INSTR_OPCODE_WIDTH-1:0] == 7'b0100111)

    `define IS_MEMOP(_ins) \
        (`IS_LOAD(_ins) || `IS_STORE(_ins))

    `define IS_VLEFF(_ins) \
        (`IS_LOAD(_ins) && `vs2(_ins) == 0'h10)

    `define IS_MASKED(_ins) \
        (!_ins[EPI_pkg::INSTR_MASK_BIT])

    `define IS_UNIT_STRIDED(_ins) \
        (_ins[EPI_pkg::INSTR_MOP_END:EPI_pkg::INSTR_MOP_START] == 2'b00)

    `define IS_STRIDED(_ins) \
        (_ins[EPI_pkg::INSTR_MOP_END:EPI_pkg::INSTR_MOP_START] == 2'b10)

    `define IS_INDEXED(_ins) \
        (_ins[EPI_pkg::INSTR_MOP_END:EPI_pkg::INSTR_MOP_START] == 2'b11)

    `define IS_MASKED_INDEXED(_ins) \
        (`IS_MASKED(_ins) || `IS_INDEXED(_ins))

    `define SUPPORTED_STRIDE(stride) \
        (stride == 1 || stride == 2 || stride == 4 || stride == -1 || stride == -2 || stride == -4)

    `define IS_VWXUNARY0(_ins) \
        ((`vs1(_ins) == 5'b00000 || `vs1(_ins) == 5'b10000 || `vs1(_ins) == 5'b10001) && `funct6(_ins) == 5'b10000)

    `define IS_VWFUNARY0(_ins) \
        (`vs1(_ins) == 5'b00000 && `funct6(_ins) == 5'b010000)

    `define funct6(ins) \
    ins[EPI_pkg::INSTR_FUNCT6_END:EPI_pkg::INSTR_FUNCT6_START]

    `define funct3(ins) \
    ins[EPI_pkg::INSTR_FUNCT3_END:EPI_pkg::INSTR_FUNCT3_START]

    `define opcode(ins) \
    ins[EPI_pkg::INSTR_OPCODE_END:EPI_pkg::INSTR_OPCODE_START]

    `define rs1(ins) \
    ins[EPI_pkg::INSTR_VSRC1_END:EPI_pkg::INSTR_VSRC1_START]

    `define vs1(ins) \
    ins[EPI_pkg::INSTR_VSRC1_END:EPI_pkg::INSTR_VSRC1_START]

    `define vs2(ins) \
    ins[EPI_pkg::INSTR_VSRC2_END:EPI_pkg::INSTR_VSRC2_START]

    `define vs3(ins) \
    ins[EPI_pkg::INSTR_VDST_END:EPI_pkg::INSTR_VDST_START]

    `define vdest(ins) \
    ins[EPI_pkg::INSTR_VDST_END:EPI_pkg::INSTR_VDST_START]

    `define simm5(ins) \
    ins[EPI_pkg::INSTR_VSRC1_END:EPI_pkg::INSTR_VSRC1_START]

    `define IS_VFRED(ins) \
    (`opcode(ins) == 7'b1010111 && `funct3(ins) == 3'b001 && (`funct6(ins) == 6'b000001 || `funct6(ins) == 6'b110001))

`endif
