#define INIT_TEST \
    _start: \
    li x19, 0x800000000024112d; \
    csrw misa, x19; \
    la x2, user_stack_start; \
    trap_vec_init:    \
                  la x7, mmode_exception_handler; \
                  ori x7, x7, 0; \
                  csrw 0x305, x7; \
    _finish_loop_init_mem: \
        li x7, 0xa01883e00; \
        csrw 0x300, x7; \
        li x7, 0x0; \
        csrw 0x304, x7; \

#define END_TEST \
    .globl mmode_exception_handler; \
    .type  mmode_exception_handler, @function; \
    .align           2; \
    mmode_exception_handler: \
        csrr x7, mepc; \
        csrr x7, mcause; \
        li x4, 0x3; \
        beq x7, x4, ebreak_handler; \
        li x4, 0x8; \
        beq x7, x4, ecall_handler; \
        li x4, 0x9; \
        beq x7, x4, ecall_handler; \
        li x4, 0xb; \
        beq x7, x4, ecall_handler; \
        li x4, 0x1; \
        beq x7, x4, instr_fault_handler; \
        li x4, 0x5; \
        beq x7, x4, load_fault_handler; \
        li x4, 0x7; \
        beq x7, x4, store_fault_handler; \
        li x4, 0xc; \
        beq x7, x4, pt_fault_handler; \
        li x4, 0xd; \
        beq x7, x4, pt_fault_handler; \
        li x4, 0xf; \
        beq x7, x4, pt_fault_handler; \
        li x4, 0x2; \
        beq x7, x4, illegal_instr_handler; \
        csrr x4, mtval; \
        jal x1, test_done; \
    ecall_handler: \
        la x7, _start; \
        sd x0, 0(x7); \
        sd x1, 8(x7); \
        sd x2, 16(x7); \
        sd x3, 24(x7); \
        sd x4, 32(x7); \
        sd x5, 40(x7); \
        sd x6, 48(x7); \
        sd x7, 56(x7); \
        sd x8, 64(x7); \
        sd x9, 72(x7); \
        sd x10, 80(x7); \
        sd x11, 88(x7); \
        sd x12, 96(x7); \
        sd x13, 104(x7); \
        sd x14, 112(x7); \
        sd x15, 120(x7); \
        sd x16, 128(x7); \
        sd x17, 136(x7); \
        sd x18, 144(x7); \
        sd x19, 152(x7); \
        sd x20, 160(x7); \
        sd x21, 168(x7); \
        sd x22, 176(x7); \
        sd x23, 184(x7); \
        sd x24, 192(x7); \
        sd x25, 200(x7); \
        sd x26, 208(x7); \
        sd x27, 216(x7); \
        sd x28, 224(x7); \
        sd x29, 232(x7); \
        sd x30, 240(x7); \
        sd x31, 248(x7); \
        j write_tohost; \
    instr_fault_handler: \
        csrw  mepc, x7; \
        csrrw x5, mscratch, x5; \
    load_fault_handler: \
        csrw vstart, 0; \
        csrr  x7, mepc; \
        addi  x7, x7, 4; \
        csrw  mepc, x7; \
        csrrw x5, mscratch, x5; \
        mret; \
    store_fault_handler: \
        csrw vstart, 0; \
        csrr  x7, mepc; \
        addi  x7, x7, 4; \
        csrw  mepc, x7; \
        csrw  mepc, x7; \
        csrrw x5, mscratch, x5; \
    ebreak_handler: \
        csrr  x7, mepc; \
        addi  x7, x7, 4; \
        csrw  mepc, x7; \
        csrw  mepc, x7; \
        csrrw x5, mscratch, x5; \
    illegal_instr_handler: \
        csrr  x7, mepc; \
        addi  x7, x7, 4; \
        csrw  mepc, x7; \
        csrrw x5, mscratch, x5; \
        mret; \
    pt_fault_handler: \
        nop; \
        csrw  mepc, x7; \
        csrrw x5, mscratch, x5; \
    test_done: \
        li gp, 1; \
        ecall; \
    write_tohost: \
        sw gp, tohost, t5; \
    _exit: \
        j write_tohost; \
    .pushsection .tohost,"aw",@progbits; \
    .align 6; .global tohost; tohost: .dword 0; \
    .align 6; .global fromhost; fromhost: .dword 0; \

#define RVTEST_DATA(data_allocation...) \
    .data; \
    .align 8; \
    init_region: \
        data_allocation; \
    work_region: \
        data_allocation

#define MASK_XLEN(x) ((x) & ((1 << (__riscv_xlen - 1) << 1) - 1))

#define TEST_PermInst_OP(testnum, inst, rd, vs2, rs1) \
    test_ ## testnum: \
    li x8, MASK_XLEN(rs1); \
    inst rd, vs2, x8;

#define TEST_vl_OP(testnum, vsew, vlen) \
    test_ ## testnum: \
    li x24, vlen; \
    vsetvli x19, x24, vsew;

#define TEST_RR1_OP(testnum, inst, vd, val1) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    vmv.v.x v3, x8; \
    inst vd, v3;

#define TEST_RR_OP(testnum, inst, vd, val1, val2) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    li x9, MASK_XLEN(val2); \
    vmv.v.x v3, x8; \
    vmv.v.x v4, x9; \
    inst vd, v3, v4;

#define TEST_RR_OP_MASKED(testnum, inst, vd, val1, val2) \
	test_ ## testnum: \
	li x8, MASK_XLEN(val1); \
	li x9, MASK_XLEN(val2); \
	vmv.v.x v3, x8; \
	vmv.v.x v4, x9; \
	inst vd, v3, v4, v0.t;

#define TEST_RR_SRC1_EQ_DEST(testnum, inst, vd, val1, val2) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    li x9, MASK_XLEN(val2); \
    vmv.v.x vd, x8; \
    vmv.v.x v4, x9; \
    inst vd, vd, v4;

#define TEST_RR_SRC2_EQ_DEST(testnum, inst, vd, val1, val2) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    li x9, MASK_XLEN(val2); \
    vmv.v.x v3, x8; \
    vmv.v.x vd, x9; \
    inst vd, v3, vd;

#define TEST_RR_SRC12_EQ_DEST(testnum, inst, vd, val1) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    vmv.v.x vd, x8; \
    inst vd, vd, vd;

#define TEST_RR_ZERO_SRC1(testnum, inst, vd, val2) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val2); \
    vmv.v.x vd, x8; \
    vmv.v.x v31, zero; \
    inst vd, v31, vd;

#define TEST_RR_ZERO_SRC2(testnum, inst, vd, val1) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    vmv.v.x vd, x8; \
    vmv.v.x v31, zero; \
    inst vd, vd, v31;

#define TEST_RR_ZERO_SRC12(testnum, inst, vd) \
    test_ ## testnum: \
    vmv.v.x v31, zero; \
    inst vd, v31, v31;

#define TEST_RX_OP(testnum, inst, vd, val1, val2) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    li x9, MASK_XLEN(val2); \
    vmv.v.x v3, x8; \
    inst vd, v3, x9;

#define TEST_IMM_OP(testnum, inst, vd, val1, imm) \
    test_ ## testnum: \
    li x8, MASK_XLEN(val1); \
    vmv.v.x v3, x8; \
    inst vd, v3, MASK_XLEN(imm);

#define TEST_MEM_US_OP(testnum, inst, vd_vs3, base, masked) TEST_MEM_US_OP_##masked (testnum, inst, vd_vs3, base)

#define TEST_MEM_US_OP_NOTMASKED(testnum, inst, vd_vs3, base) \
    test_ ## testnum: \
    la x1, base; \
    inst vd_vs3, (x1);

#define TEST_MEM_US_OP_MASKED(testnum, inst, vd_vs3, base) \
    test_ ## testnum: \
    la x1, base; \
    inst vd_vs3, (x1), v0.t;

#define TEST_MEM_STR_OP(testnum, inst, vd_vs3, rs2, base, masked) TEST_MEM_STR_OP_## masked (testnum, inst, vd_vs3, rs2, base)

#define TEST_MEM_STR_OP_NOTMASKED(testnum, inst, vd_vs3, rs2, base) \
    test_ ## testnum: \
    la x1, base; \
    li x8, rs2; \
    inst vd_vs3, (x1), x8;

#define TEST_MEM_STR_OP_MASKED(testnum, inst, vd_vs3, rs2, base) \
    test_ ## testnum: \
    la x1, base; \
    li x8, rs2; \
    inst vd_vs3, (x1), x8, v0.t;

#define TEST_MEM_IND_OP(testnum, inst, vd_vs3, vs2, base, masked) TEST_MEM_IND_OP_## masked (testnum, inst, vd_vs3, vs2, base)

#define TEST_MEM_IND_OP_NOTMASKED(testnum, inst, vd_vs3, vs2, base) \
    test_ ## testnum: \
    la x1, base; \
    inst vd_vs3, (x1), vs2;

#define TEST_MEM_IND_MASKED(testnum, inst, vd_vs3, vs2, base) \
    test_ ## testnum: \
    la x1, base; \
    inst vd_vs3, (x1), vs2, v0.t;


#define CHANGE_FRM(val) \
    frcsr x1; \
    li x2, 0xFFFFFFFFFFFFFFFF; \
    li x3, 7; \
    slli x3, x3, 5; \
    xor x2, x2, x3; \
    and x1, x1, x2; \
    li x2, val; \
    slli x2, x2, 5; \
    or x1, x1, x2; \
    fscsr x1, x1;
