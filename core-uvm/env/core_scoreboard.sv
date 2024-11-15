//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_scoreboard 
// File          : core_scoreboard.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_scoreboard. This class instantiates 
//                 the scoreboard and its intended for comparision between main intent (requirements) 
//                 Vs. Actual (DUT output).
//----------------------------------------------------------------------
`ifndef CORE_SCOREBOARD
`define CORE_SCOREBOARD

`include "uvm_macros.svh"
import uvm_pkg::*;
import riscv_pkg::*;

    // Function: scalar_dest_reg
    // Returns 1 if instruction has scalar result, 0 otherwise
    // In RVV-1.0, the instructions are vcpop.m, vfirst.m, vmv.x.s, vfmv.f.s, and all the configuration instructions (vsetvl family of instructions)
    function bit scalar_dest_reg (logic [31:0] inst);
        // TODO localparams from package
        logic [5:0] funct6;
        logic [2:0] funct3;
        op_inst_t opcode;
        logic [4:0] op_vs1;
        funct6 = inst[31:26];
        funct3 = inst[14:12];
        opcode = op_inst_t'(inst[6:0]);
        op_vs1 = inst[19:15];
        if (opcode ==  OP_V) begin
            if (funct3 == 3'b111) return 1'b1; // Config instruction (vset*vl*)
            else if ((funct6 == 6'b010000) && (funct3 == 3'b010)) return (op_vs1 inside {5'b00000, 5'b10000, 5'b10001}); // VWXUNARY0 (vcpop.m, vfirst.m, vmv.x.s)
            else if ((funct6 == 6'b010000) && (funct3 == 3'b001)) return (op_vs1 == 5'b00000); // VWFUNARY0 (vfmv.f.s)
        end
        return 1'b0;
    endfunction : scalar_dest_reg

function int is_floating_instr(logic [31:0] instr);

    logic [6:0] opcode;
    opcode = instr[6:0];

    return  (opcode == 7'h53)                                       || // floating arithmetic
            (opcode == 7'h07)                                       || // floating load
            (opcode == 7'h27)                                       || // floating store
            (opcode == 7'h43)                                       || // fmadd
            (opcode == 7'h47)                                       || // fmsub
            (opcode == 7'h4b)                                       || // fnmadd
            (opcode == 7'h4f);                                         // fnmsub

endfunction : is_floating_instr

function int float_to_int(logic [31:0] instr);

    logic [6:0] opcode;
    logic [6:0] funct7;
    logic [4:0] rs2;
    opcode = instr[6:0];
    funct7 = instr[31:25];
    rs2 = instr[24:20];

    return  (opcode == 7'h53) &&                                         // floating arithmetic
            ((funct7 == 7'b1100000 && (rs2 == 5'h1 || rs2 == 5'h0))  ||  // fcvt.w.s, fcvt.wu.s
            (funct7 == 7'b1110000 && (rs2 == 5'h0))                  ||  // fmv.x.w
            (funct7 == 7'b1010000)                                   ||  // feq.s, flt.s, fle.s
            (funct7 == 7'b1110000 && (rs2 == 5'h0))                  ||  // fclass.s
            (funct7 == 7'b1100000 && (rs2 == 5'h2 || rs2 == 5'h3))   ||  // fcvt.l.s, fcvt.lu.s
            (funct7 == 7'b1100001 && (rs2 == 5'h1 || rs2 == 5'h0))   ||  // fcvt.w.d, fcvt.wu.d
            (funct7 == 7'b1110001 && (rs2 == 5'h0))                  ||  // fmv.x.d
            (funct7 == 7'b1010001)                                   ||  // feq.d, flt.d, fle.d
            (funct7 == 7'b1100001 && (rs2 == 5'h2 || rs2 == 5'h3)));  // fcvt.l.s, fcvt.lu.s

endfunction : float_to_int

function bit fence_or_jump(logic [31:0] instr);

    logic [2:0] funct3;
    op_inst_t opcode;
    funct3 = instr[14:12];
    opcode = op_inst_t'(instr[6:0]);

    return  (opcode == OP_BRANCH) || // branches
            (opcode == OP_JAL) ||
            (opcode == OP_JALR) ||
            (opcode == OP_FENCE && (funct3 == 3'h1 || funct3 == 3'h0));   // fence.i and fence

endfunction : fence_or_jump

function bit mip_read(logic [31:0] instr);

    logic [2:0] funct3;
    op_inst_t opcode;
    logic [11:0] csr;
    bit opcode_system;
    bit funct3_csrr;
    bit dst_mip;
    funct3 = instr[14:12];
    opcode = op_inst_t'(instr[6:0]);
    csr = instr[31:20];

    opcode_system = (opcode == OP_SYSTEM);
    funct3_csrr = funct3[1];
    dst_mip = (csr=='h344);

    return  ( opcode_system && funct3_csrr && dst_mip );

endfunction : mip_read

function int mie_read(logic [31:0] instr);

    logic [2:0] funct3;
    logic [6:0] opcode;
    logic [11:0] csr;
    bit opcode_system;
    bit funct3_csrr;
    bit dst_mie;
    funct3 = instr[14:12];
    opcode = instr[6:0];
    csr = instr[31:20];

    opcode_system = (opcode == 7'b1110011);
    funct3_csrr = funct3[1];
    dst_mie = (csr=='h304);

    return  ( opcode_system && funct3_csrr && dst_mie );
endfunction : mie_read

function bit store_instr(logic [31:0] instr);
    op_inst_t opcode;
    opcode = op_inst_t'(instr[6:0]);
    return  (opcode == OP_STORE || opcode == OP_STORE_FP);
endfunction : store_instr

function bit fp_div_sqrt_cvt(logic [31:0] instr);
    op_inst_t opcode;
    op_func7_fp_t trunc_funct7;
    bit op_fp;
    bit is_fdiv, is_fsqrt, is_fcvt;
    opcode = op_inst_t'(instr[6:0]);
    trunc_funct7 = op_func7_fp_t'(instr[31:27]);
    op_fp = (opcode == OP_FP);
    is_fdiv = op_fp && (trunc_funct7 == F5_FP_FDIV);
    is_fsqrt = op_fp && (trunc_funct7 == F5_FP_FSQRT);
    is_fcvt = op_fp && (trunc_funct7 inside {F5_FP_FCVT_F2I, F5_FP_FCVT_SD});
    return  ( is_fdiv || is_fsqrt || is_fcvt );
endfunction : fp_div_sqrt_cvt

function bit vsetvl_vsetvli_vsetivli(logic [31:0] instr);

    logic [2:0] funct3;
    op_inst_t opcode;
    funct3 = instr[14:12];
    opcode = op_inst_t'(instr[6:0]);

    //opcode = 0x57
    //funct3 = OPVCFG = 0x7
    return  (opcode == OP_V) && (funct3 == 3'h7);

endfunction : vsetvl_vsetvli_vsetivli

function bit inst_dest_valid(logic [31:0] instr);
    op_inst_t opcode;
    logic [2:0] funct3;
    opcode = op_inst_t'(instr[6:0]);
    funct3  = instr[14:12];

    return !(opcode == OP_BRANCH                                   ||   // BEQ Family
             opcode == OP_STORE                                    ||   // Store Family
             opcode == OP_STORE_FP                                 ||
            (opcode == OP_SYSTEM && funct3 == 3'h0)                ||   // ECALL/EBREAK
            (opcode == OP_FENCE && (funct3 == 3'h1 || funct3 == 3'h0))); // fence.i and fence
endfunction : inst_dest_valid

function bit is_plic_load(logic [31:0] instr, logic [63:0] addr );
    op_inst_t opcode;
    opcode = op_inst_t'(instr[6:0]);
    return (opcode == OP_LOAD && (addr[39:24]=='he200) ); //PLIC BASE ADDR[39:24]
endfunction : is_plic_load

function bit is_clint_store(logic [31:0] instr, logic [63:0] addr);
    op_inst_t opcode;
    opcode = op_inst_t'(instr[6:0]);

    return (opcode == OP_STORE) && (addr[39:20] == 'he0105); //CLINT BASE ADDR[39:20]
endfunction : is_clint_store

function bit is_plic_store(logic [31:0] instr, logic [63:0] addr );
    op_inst_t opcode;
    logic [2:0] funct3;
    opcode = op_inst_t'(instr[6:0]);
    funct3  = instr[15:13];
    return (opcode == OP_STORE && (addr[39:24]=='he200) ); //PLIC BASE ADDR[39:24]
endfunction : is_plic_store

class core_scoreboard extends uvm_scoreboard;
`uvm_component_utils(core_scoreboard)

typedef enum bit [2:0] {
    PC_MISMATCH,
    INSTRUCTION_MISMATCH,
    RESULT_MISMATCH,
    MULTIPLE_MISMATCH,
    MIP_MISMATCH,
    EXCEPTION_MISMATCH
} error_type;

    // Variable: pool
    uvm_event_pool pool = uvm_event_pool::get_global_pool();

    uvm_event end_test_sentinel = pool.get("end_test_sentinel");

    uvm_blocking_get_port #(scoreboard_results_t) m_results;

    int executed_ins;

    core_iss_wrapper m_iss;
    core_env_cfg m_env_cfg;

    logic disable_store_checks;

    plic_enable_t plic_enable;

    uvm_event test_clearmip_event = pool.get("test_clearmip");
    uvm_event write_mtime_event = pool.get("write_mtime");

    function new(string name = "core_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_results = new ("m_results", this);
        executed_ins = 0;
        m_env_cfg = new();
        if (!uvm_config_db #(core_env_cfg)::get(this, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end
        disable_store_checks = m_env_cfg.disable_store_checks;
        $display("disable_store_checks: %d", disable_store_checks);
        plic_enable = {default:'0};
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        scoreboard_results_t scoreboard_results = scoreboard_results_t::type_id::create("scoreboard_results");

        // In case of centinels
        //phase.raise_objection(this);

        forever begin
            m_results.get(scoreboard_results);
            compare(scoreboard_results);
        end

        //phase.drop_objection(this);

    endtask : run_phase

    task compare(scoreboard_results_t scoreboard_results);
        dut_state_t dut;
        iss_state_t iss;
        int errors = 0;
        int dest_valid;
        error_type error;
        string mismatch_id;

        dut = scoreboard_results.dut_state;
        iss = scoreboard_results.iss_state;

        dest_valid = inst_dest_valid(dut.scalar_state.ins);

        // check if instruction is centinel
        if (dut.scalar_state.ins == ECALL_SENTINEL) begin
            end_test_sentinel.trigger();
        end

        // check if timeout (ask for this)
        //
        // interrupts ??
        // plic load
        if (is_plic_load(iss.scalar_state.instr, iss.scalar_state.vaddr)) begin
            //$display("IS_PLIC_LOAD ADDR %h RES %h", iss.scalar_state.vaddr, iss.scalar_state.dst_value);
            // TODO remove hardcoded addresses
            if ((iss.scalar_state.vaddr[23:0] == 'h200004 || iss.scalar_state.vaddr[23:0] == 'h201004) && iss.scalar_state.dst_value != 0) begin //PLIC_IRQ_CLAIM_CONTEXT_0 || PLIC_IRQ_CLAIM_CONTEXT_1
                uvm_config_db #(longint)::set(null, "*", "last_cleared_irq_id", iss.scalar_state.dst_value);
                `uvm_info("uvm_scoreboard",$sformatf("PLIC CLAIM INTERRUPT ID %h", iss.scalar_state.dst_value ), UVM_LOW)
                if (m_env_cfg.is_cpu_ss) begin
                    test_clearmip_event.trigger();
                end
            end
        end
        // plic store
        if (is_plic_store( iss.scalar_state.instr, iss.scalar_state.vaddr)) begin
            int nibble = iss.scalar_state.vaddr[4:2];
            int value  = iss.scalar_state.src2_value[31:0];
            //$display("IS_PLIC_STORE ADDR %h RES %h - NIBBLE %h VALUE %h", iss.scalar_state.vaddr, iss.scalar_state.src2_value, nibble, value);
            // TODO remove hardcoding
            if (iss.scalar_state.vaddr[23:0] >= 'h002000 && iss.scalar_state.vaddr[23:0] < 'h002080) begin //ENABLE CONTEXT 0
                plic_enable.m_irq_enable[nibble]=value;
            end else if (iss.scalar_state.vaddr[23:0] >= 'h002080 && iss.scalar_state.vaddr[23:0] < 'h002100) begin //ENABLE CONTEXT 1
                plic_enable.s_irq_enable[nibble]=value;
            end else if (iss.scalar_state.vaddr[23:0] >= 'h002100 && iss.scalar_state.vaddr[23:0] < 'h002180) begin //ENABLE CONTEXT 2
                plic_enable.m_irq_enable[nibble]=value;
            end else if (iss.scalar_state.vaddr[23:0] >= 'h002180 && iss.scalar_state.vaddr[23:0] < 'h002200) begin //ENABLE CONTEXT 3
                plic_enable.s_irq_enable[nibble]=value;
            end else if (iss.scalar_state.vaddr[23:0] >= 'h002200 && iss.scalar_state.vaddr[23:0] < 'h002280) begin //ENABLE CONTEXT 4
                plic_enable.m_irq_enable[nibble]=value;
            end else if (iss.scalar_state.vaddr[23:0] >= 'h002280 && iss.scalar_state.vaddr[23:0] < 'h002300) begin //ENABLE CONTEXT 5
                plic_enable.s_irq_enable[nibble]=value;
            end

            if (iss.scalar_state.vaddr[23:0] >= 'h002000 && iss.scalar_state.vaddr[23:0] < 'h002300) begin //ENABLE ADDR
                uvm_config_db #(plic_enable_t)::set(null, "*", "plic_enable", plic_enable);
            end

        end
        // clint store
        if (is_clint_store( iss.scalar_state.instr, iss.scalar_state.vaddr)) begin
            $display("IS CLINT STORE ADDR %h", iss.scalar_state.vaddr);
            // TODO remove hardcoding
            if (iss.scalar_state.vaddr[15:0] == 'hbff8) begin //MTIME_OFFSET
               `uvm_info("uvm_scoreboard",$sformatf("CLINT MTIME WRITE %h SRC2 VALUE %h", iss.scalar_state.store_data, iss.scalar_state.src2_value ), UVM_LOW) 
               uvm_config_db #(longint)::set(null, "*", "mtime", iss.scalar_state.store_data);
                if (m_env_cfg.is_cpu_ss) begin
                    write_mtime_event.trigger();
                end
            end
            // TODO can it be equal to bff8?
            if (iss.scalar_state.vaddr[15:0] == m_env_cfg.mtimecmp_offset) begin //MTIMECMP0_OFFSET
                `uvm_info("uvm_scoreboard", $sformatf("CLINT MTIMECMP_OFFSET (0x%h) WRITE %h SRC2 VALUE %h", m_env_cfg.mtimecmp_offset, iss.scalar_state.store_data, iss.scalar_state.src2_value), UVM_LOW) 
                uvm_config_db #(longint)::set(null, "*", "mtimecmp_offset", iss.scalar_state.store_data);
            end
        end

        // TODO add generic printing function
        assert (dut.scalar_state.pc === iss.scalar_state.pc) else begin
            `uvm_info("PC MISMATCH", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
            `uvm_info("PC MISMATCH", $sformatf("PC mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
            `uvm_info("PC MISMATCH", $sformatf("      iss: %h", iss.scalar_state.pc), UVM_LOW)
            `uvm_info("PC MISMATCH", $sformatf("     core: %h", dut.scalar_state.pc), UVM_LOW)

            `uvm_info("uvm_scoreboard", $sformatf("Instruction in core %h", dut.scalar_state.core_id), UVM_LOW)
            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.instr), UVM_LOW)
            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.ins), UVM_LOW)
            error = PC_MISMATCH;
            errors++;
        end

        if (dut.scalar_state.exc_bit || iss.scalar_state.exc_bit) begin
            if (dut.scalar_state.exc_bit != iss.scalar_state.exc_bit) begin
                `uvm_info("uvm_scoreboard", $sformatf("Exception mismatch core %h iss %h - ISS Privilege level: %h", dut.scalar_state.exc_bit, iss.scalar_state.exc_bit, m_iss.get_prv_lvl() ), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf(">>> PC: dut 0x%0h iss 0x%0h", dut.scalar_state.pc, iss.scalar_state.pc), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf(">>> Instr: dut 0x%0h iss 0x%0h (%s) ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf(">>> Exception cause core 0x%0h iss scause 0x%0h iss mcause 0x%0h", dut.scalar_state.exc_cause, iss.scalar_state.csr.scause, iss.scalar_state.csr.mcause), UVM_LOW)
                error = EXCEPTION_MISMATCH;
                errors++;
            end else if ((m_iss.get_prv_lvl() == 1) && (dut.scalar_state.exc_cause != iss.scalar_state.csr.scause)) begin // Supervisor mode sets scause
                `uvm_info("uvm_scoreboard",$sformatf("Exception cause mismatch core %h iss %h ISS Privilege level: %h. PC: %x", dut.scalar_state.exc_cause, iss.scalar_state.csr.scause, m_iss.get_prv_lvl(), dut.scalar_state.pc), UVM_LOW)
                error = EXCEPTION_MISMATCH;
                errors++;
            end else if ((m_iss.get_prv_lvl() != 1) && dut.scalar_state.exc_cause != iss.scalar_state.csr.mcause) begin // Machine mode sets mcause. TODO: Update if hypervisor implemented
                `uvm_info("uvm_scoreboard",$sformatf("Exception cause mismatch core %h iss %h ISS Privilege level: %h. PC: %x", dut.scalar_state.exc_cause, iss.scalar_state.csr.mcause, m_iss.get_prv_lvl(), dut.scalar_state.pc), UVM_LOW)
                error = EXCEPTION_MISMATCH;
                errors++;
            end else begin
                `uvm_info("uvm_scoreboard",$sformatf("Exception happened %h cause %h. PC: %x", dut.scalar_state.exc_bit, dut.scalar_state.exc_cause, dut.scalar_state.pc), UVM_LOW)
            end
        end else begin
            assert (dut.scalar_state.ins[31:0] === iss.scalar_state.instr[31:0]) else begin
                `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf("Instruction mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.instr), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.ins), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf("     dut exc bit: %h cause: %h", dut.scalar_state.exc_bit, dut.scalar_state.csr.mcause), UVM_LOW)
                `uvm_info("uvm_scoreboard", $sformatf("     iss exc bit: %h cause: %h iss dst_num: %h", iss.scalar_state.exc_bit, iss.scalar_state.csr.mcause, iss.scalar_state.dst_num), UVM_LOW)
                error = INSTRUCTION_MISMATCH;
                errors++;
            end

            // TODO: separate interrupt from FP correction
            if (store_instr(dut.scalar_state.ins) || (!fence_or_jump(iss.scalar_state.instr) && dest_valid && (iss.scalar_state.dst_num != 'b0 || (is_vector(iss.scalar_state.instr) && !scalar_dest_reg(iss.scalar_state.instr)) || (is_floating_instr(iss.scalar_state.instr) && !float_to_int(iss.scalar_state.instr ))))) begin
                if ( mip_read(iss.scalar_state.instr) ) begin //MIP comparison
                    int interrupt_in_progress = 0;
                    uvm_config_db #(int)::get(null, "*", "interrupt_in_progress", interrupt_in_progress);
                    `uvm_info("uvm_scoreboard", $sformatf("MEIP COMPARISON @%t, DUT VALUE %h ISS VALUE %h - INTERRUPT IN PROGRESS %d", $time(), dut.scalar_state.dst_value, iss.scalar_state.dst_value, interrupt_in_progress), UVM_LOW)
                    if (interrupt_in_progress) begin //external interrupt in progress, compare MEIP, SEIP, UEIP
                        assert( (dut.scalar_state.dst_value[11] && iss.scalar_state.dst_value[11]) || (dut.scalar_state.dst_value[9] && iss.scalar_state.dst_value[9]) ) else begin
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("MIP Result mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("Interrupt in progress %h", interrupt_in_progress), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.dst_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.dst_value), UVM_LOW)
                            error = MIP_MISMATCH;
                            errors++;
                        end
                    end else begin
                        assert (dut.scalar_state.dst_value == iss.scalar_state.dst_value) else begin
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("MIP Result mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("Interrupt in progress %h", interrupt_in_progress), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.dst_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.dst_value), UVM_LOW)
                            error = MIP_MISMATCH;
                            errors++;
                        end
                    end
                end else if (mie_read(iss.scalar_state.instr)) begin //MIE comparison, only bits [12:0]
                    `uvm_info("uvm_scoreboard", $sformatf("MIE COMPARISON @%t, DUT VALUE %h ISS VALUE %h - COMPARING ONLY BITS[12:0]", $time(), dut.scalar_state.dst_value, iss.scalar_state.dst_value), UVM_LOW)
                    assert( (dut.scalar_state.dst_value[12:0]  === iss.scalar_state.dst_value[12:0]) ) else begin
                        `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                        `uvm_info("uvm_scoreboard", $sformatf("MIP Result mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                        `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.dst_value[12:0]), UVM_LOW)
                        `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.dst_value[12:0]), UVM_LOW)
                        error = MIP_MISMATCH;
                        errors++;
                    end
                end else if (fp_div_sqrt_cvt(iss.scalar_state.instr)) begin //fdiv/fsqrt/fcvt last bit mismatch check
                    if (dut.scalar_state.dst_value !== iss.scalar_state.dst_value) begin
                        if (iss.scalar_state.dst_value !== (dut.scalar_state.dst_value+1) &&  iss.scalar_state.dst_value !== (dut.scalar_state.dst_value-1)) begin //compare all bits except last one, if differs then it's really an error
                            `uvm_info("uvm_scoreboard", $sformatf("-----TRUE MISMATCH IN FDIV/FSQRT/FCVT----"), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("Result mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.dst_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.dst_value), UVM_LOW)
                            error = RESULT_MISMATCH;
                            errors++;
                        end else begin //if only the lsb bit differs, update spike results with RTL ones
                            `uvm_info("uvm_scoreboard", $sformatf("-----FALSE MISMATCH IN FDIV/FSQRT/FCVT----"), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("Result mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.dst_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.dst_value), UVM_LOW)
                            //m_iss.set_fp_reg_value(iss.dst_num, dut.dst_value); //now is done in core_im.sv
                        end
                    end
                end else begin
                    if (is_vector(dut.scalar_state.ins) && m_env_cfg.vpu_enabled) begin
                        // don't compare results here but in vpu scoreboard
                        // TODO: Why not check for vsetvl???
                        if (vsetvl_vsetvli_vsetivli(iss.scalar_state.instr)) begin //vsetvli
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("vsetvl/vsetvli/vsetivli in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.dst_value), UVM_LOW)
                        end
                    end else if (is_vector(dut.scalar_state.ins) && !scalar_dest_reg(dut.scalar_state.ins) && !m_env_cfg.vpu_enabled) begin // Else, result is checked in separated VPU scoreboard
                        if (iss.scalar_state.csr.vl != '0) begin
                            logic vector_error_found;
                            vector_error_found = 1'b0;
                            for (int i = 0; !vector_error_found && (i < riscv_pkg::VLEN/64); i++) begin
                                assert (dut.rvv_state.vd[i] == iss.rvv_state.vd[i]) else begin
                                    `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                                    `uvm_info("uvm_scoreboard", $sformatf("Vector Result mismatch in core %h - elen %d", dut.scalar_state.core_id, i), UVM_LOW)
                                    `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.rvv_state.vd[i]), UVM_LOW)
                                    `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.rvv_state.vd[i]), UVM_LOW)
                                    `uvm_info("uvm_scoreboard", $sformatf("     iss exc bit: %h cause: %h iss dst_num: %h", iss.scalar_state.exc_bit, iss.scalar_state.csr.mcause, iss.scalar_state.dst_num), UVM_LOW)
                                    error = RESULT_MISMATCH;
                                    errors++;
                                    vector_error_found = 1'b1; // Only report the first mismatching elen
                                end
                            end
                        end
                  end else if (store_instr(iss.scalar_state.instr) && !disable_store_checks) begin
                        assert ((iss.scalar_state.store_data & iss.scalar_state.store_mask) === (((dut.scalar_state.stored_value & iss.scalar_state.store_mask)))) else begin
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("Store result mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.store_data), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.stored_value & iss.scalar_state.store_mask), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     Store Address: 0x%h", iss.scalar_state.vaddr), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     iss exc bit: %h cause: %h iss dst_num: %h", iss.scalar_state.exc_bit, iss.scalar_state.csr.mcause, iss.scalar_state.dst_num), UVM_LOW)
                            error = RESULT_MISMATCH;
                            errors++;
                        end
                    end else if (iss.scalar_state.instr[6:0] == 7'h2F) begin//7'h2F is the opcode for Amo instructions
                        assert ((dut.scalar_state.dst_value===iss.scalar_state.dst_value)) else begin //TODO: Check in Dcache itself the actual stored value
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("AMO mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss src1: %0x iss mem_addr %0x iss rd: %0x", (iss.scalar_state.src1_value),iss.scalar_state.vaddr, iss.scalar_state.dst_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.stored_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     iss exc bit: %h cause: %h iss dst_num: %h", iss.scalar_state.exc_bit, iss.scalar_state.csr.mcause, iss.scalar_state.dst_num), UVM_LOW)
                            error = RESULT_MISMATCH;
                            errors++;
                        end
                    end else begin
                        assert (dut.scalar_state.dst_value === iss.scalar_state.dst_value) else begin
                            `uvm_info("uvm_scoreboard", $sformatf("PC: %h INSTR %h DISASM: %s ", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("Result mismatch in core %h", dut.scalar_state.core_id), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("      iss: %h", iss.scalar_state.dst_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     core: %h", dut.scalar_state.dst_value), UVM_LOW)
                            `uvm_info("uvm_scoreboard", $sformatf("     iss exc bit: %h cause: %h iss dst_num: %h", iss.scalar_state.exc_bit, iss.scalar_state.csr.mcause, iss.scalar_state.dst_num), UVM_LOW)
                            error = RESULT_MISMATCH;
                            errors++;
                        end
                    end
                end
            end
        end
        if (errors) begin
            uvm_config_db #(dut_scalar_state_t)::set(null, "*", "fail_instr", dut.scalar_state);
            if (errors > 1) error = MULTIPLE_MISMATCH;
            case (error)
                PC_MISMATCH: begin
                    mismatch_id = "uvm_scoreboard_pc";
                end
                INSTRUCTION_MISMATCH: begin
                    mismatch_id = "uvm_scoreboard_ins";
                end
                RESULT_MISMATCH: begin
                    mismatch_id = "uvm_scoreboard_res";
                end
                MULTIPLE_MISMATCH: begin
                    mismatch_id = "uvm_scoreboard_mult";
                end
                EXCEPTION_MISMATCH: begin
                    mismatch_id = "uvm_scoreboard_exc";
                end
                MIP_MISMATCH: begin
                    mismatch_id = "uvm_scoreboard_int";
                end
            endcase
            `uvm_fatal(mismatch_id, $sformatf(" Execution abort due to %d scoreboard mismatches", errors))
        end else begin
            uvm_config_db #(dut_scalar_state_t)::set(null, "*", "last_completed_instr", dut.scalar_state);
            uvm_config_db #(int)::set(null, "*", "executed_ins", executed_ins);
            `uvm_info("uvm_scoreboard", $sformatf("Correct: PC %h, INSTR %h DISASM: %s RESULT: %h", dut.scalar_state.pc, iss.scalar_state.instr, iss.scalar_state.disasm, dut.scalar_state.dst_value), UVM_LOW)
            `uvm_info("uvm_scoreboard", $sformatf("    Result of core: %h", dut.scalar_state.dst_value), UVM_HIGH)
            ++executed_ins;
        end
    endtask : compare
    function void report_phase(uvm_phase phase);
        uvm_coreservice_t cs;
        uvm_report_server svr;
        cs = uvm_coreservice_t::get();
        svr = cs.get_report_server();
        if (svr.get_severity_count(UVM_FATAL) == 0) begin
            int fd = $fopen({getenv("VERIF"), "/sim/build/report.yaml"}, "w");
            string cause_str;
            string report_msg;
            string dasm;
            dut_scalar_state_t last_instr;
            int executed_interrupts;

            cause_str = "SUCCESS";
            `ifndef QUESTA_JTAG_VIP
                if(!uvm_config_db#(dut_scalar_state_t)::get(null,"*", "last_completed_instr", last_instr)) begin
                    `uvm_error(get_type_name(), "No last_completed_instr in the db")
                end
                if(!uvm_config_db#(int)::get(null,"*", "executed_interrupts", executed_interrupts)) begin
                    `uvm_info(get_type_name(), "No executed_interrupts in the db", UVM_HIGH)
                    executed_interrupts = 0;
                end

                dasm = disassemble_insn_str(last_instr.ins);
                report_msg = $sformatf("cause: %0d\nseed: %0d\ninstr:\n    pc: 0x%0h\n    ins: 0x%0h\n    disasm: \"%s\"\n    executed_ins: %d\n    executed_interrupts: %d", cause_str, $get_initial_random_seed(), last_instr.pc, last_instr.ins, dasm, executed_ins, executed_interrupts);
            `else
                report_msg = $sformatf("cause: %0d\nseed: %0d\ninstr:\n    pc: 0x%0h\n    ins: 0x%0h\n    disasm: \"%s\"\n    executed_ins: %d\n    executed_interrupts: %d", cause_str, $get_initial_random_seed(), '0, '0, "Jtag Test Executed", '0, '0);
            `endif
            $fdisplay(fd, report_msg);
            $fclose(fd);
        end
    endfunction : report_phase
endclass : core_scoreboard



`endif
