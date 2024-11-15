//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_im
// File          : core_im.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This is instruction_management file. Providing instruction 
//                 related data to scoreboard for comparision.
//----------------------------------------------------------------------
`ifndef CORE_IM_CLASS_SV
`define CORE_IM_CLASS_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import riscv_pkg::*;

class core_im extends uvm_component;
`uvm_component_utils(core_im)
`uvm_analysis_imp_decl(_completed)

    uvm_tlm_analysis_fifo #(core_fetch_trans) fetch_fifo;
    uvm_analysis_imp_completed #(core_completed_trans, core_im) completed_port;
    uvm_tlm_analysis_fifo #(core_store_trans) store_fifo;

    uvm_nonblocking_put_port #(scoreboard_results_t) scoreboard_results;
    uvm_nonblocking_put_port #(scoreboard_results_t) vpu_scoreboard_results;

    uvm_nonblocking_get_port #(rvv_dut_tx) vpu_results_port;

    // Variable: m_iss
    core_iss_wrapper m_iss;
    core_env_cfg m_env_cfg;


    // Variable: pool
    // Pointer to global uvm_event_pool
    uvm_event_pool pool = uvm_event_pool::get_global_pool();

    // Variable: rob_recovery_event
    uvm_event rob_recovery_event = pool.get("rob_recovery_event");

    uvm_event iss_finished = pool.get("iss_finished");

    function new(string name = "core_im", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scoreboard_results = new("scoreboard_results", this);
        m_env_cfg = new();
        if (!uvm_config_db #(core_env_cfg)::get(this, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end
        if (m_env_cfg.core_type == core_uvm_pkg::LAGARTO_KA) begin
            vpu_scoreboard_results = new("vpu_scoreboard_results", this);
            vpu_results_port = new("vpu_results_port", this);
        end
        store_fifo = new("store_fifo", this);
        completed_port = new("completed_port", this);
        fetch_fifo = new("fetch_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
        core_fetch_trans tmp;
        core_completed_trans branch_pc;
        if (m_env_cfg.core_type == core_uvm_pkg::LAGARTO_KA) begin
            forever begin
                rob_recovery_event.wait_trigger();
                if (iss_finished.is_on()) begin
                    break;
                end
                $cast(branch_pc, rob_recovery_event.get_trigger_data());
                `uvm_info(get_type_name(),$sformatf("Receiving rob_recovery event on PC %h with fault %h", branch_pc.pc, branch_pc.fault), UVM_HIGH)
                `uvm_info("core_im", $sformatf("ROB recovery event\n    rob_pc: %h\n    xcpt  : %h\n    intr  : %h\n    fault : %h", branch_pc.pc, branch_pc.xcpt, branch_pc.ext_intr, branch_pc.fault), UVM_LOW)

                if (!branch_pc.fault) begin
                    if (branch_pc.xcpt) begin
                        rvv_dut_tx vpu_state;
                       `uvm_info("core_im", $sformatf("Flushing fetch FIFO"), UVM_HIGH)
                       fetch_fifo.flush();
                       m_iss.step(1);
                       if (vpu_results_port.try_get(vpu_state)) begin
                           `uvm_info("core_im", $sformatf("Discarding VPU completed instr (sb_id 0x%0h) due to exception", vpu_state.dut_state.rvv_state.sb_id), UVM_HIGH)
                       end
                    end else begin
                        flush_to_next_branch(branch_pc.rob_entry_miss, branch_pc.rob_head);
                    end
                end else begin
                    `uvm_info("core_im", $sformatf("Flushing fetch FIFO"), UVM_HIGH)
                    fetch_fifo.flush();
                    m_iss.step(1);
                end
            end
            rob_recovery_event.reset();
        end
    endtask : run_phase

    function void flush_to_next_branch(logic[6:0] rob_entry_miss, rob_addr_t rob_head);
        core_fetch_trans aux_fetch_fifo[$];
        core_fetch_trans fetch_trans;
        `uvm_info("core_im", $sformatf("Initial fetch_fifo size: %0d", fetch_fifo.size()), UVM_DEBUG)
        `uvm_info("core_im", $sformatf("rob_entry_miss: %h", rob_entry_miss), UVM_DEBUG)
        while (!fetch_fifo.is_empty()) begin
            void'(fetch_fifo.try_get(fetch_trans));
            aux_fetch_fifo.push_back(fetch_trans);
            `uvm_info("core_im", $sformatf("Original fetch_trans: PC: %h, instr: %h, rob_entry: %h, is_branch: %h", fetch_trans.mapper_id_pc, fetch_trans.mapper_id_inst, fetch_trans.rob_entry, fetch_trans.is_branch), UVM_HIGH)
        end
        foreach(aux_fetch_fifo[i]) begin
            `uvm_info("core_im", $sformatf("rob_entry: %h, rob_head: %h, rob_entry_miss: %h", aux_fetch_fifo[i].rob_entry, rob_head, rob_entry_miss), UVM_HIGH)
            `uvm_info("core_im", $sformatf("rob_entry - rob_head = %h, rob_entry_miss - rob_head = %h", (aux_fetch_fifo[i].rob_entry - rob_head), (rob_entry_miss - rob_head)), UVM_HIGH)
            if ((aux_fetch_fifo[i].rob_entry - rob_head) <= (rob_entry_miss - rob_head)) begin
                void'(fetch_fifo.try_put(aux_fetch_fifo[i]));
                `uvm_info("core_im", $sformatf("Final fetch_trans: PC: %h, instr: %h, rob_entry: %h, is_branch: %h", aux_fetch_fifo[i].mapper_id_pc, aux_fetch_fifo[i].mapper_id_inst, aux_fetch_fifo[i].rob_entry, aux_fetch_fifo[i].is_branch), UVM_HIGH)
            end
        end
        `uvm_info("core_im", $sformatf("Final fetch_fifo size: %0d", fetch_fifo.size()), UVM_DEBUG)
    endfunction : flush_to_next_branch

    function bit vestvl_vsetvli(logic [31:0] instr);
        logic [2:0] funct3;
        op_inst_t opcode;
        funct3 = instr[14:12];
        opcode = op_inst_t'(instr[6:0]);
        return  (opcode == OP_V) && (funct3 == 3'h7);
    endfunction : vestvl_vsetvli

    function bit is_store(logic [31:0] instr);
        op_inst_t opcode;
        opcode = op_inst_t'(instr[6:0]);
        return (opcode == OP_STORE || opcode == OP_STORE_FP);
    endfunction : is_store

    function bit is_vector_store(logic [31:0] instr);
        logic [2:0] width;
        op_inst_t opcode;
        width = instr[14:12];
        opcode = op_inst_t'(instr[6:0]);
        return (opcode == OP_STORE_FP &&
                (width == 3'b000 ||
                 width == 3'b101 ||
                 width == 3'b110 ||
                 width == 3'b111));
    endfunction : is_vector_store

    function void write_completed(core_completed_trans completed_trans);
        core_fetch_trans fetch_trans, next_fetch_trans;
        dut_scalar_state_t next_instr;
        core_store_trans store_trans, next_store_trans;
        scoreboard_results_t core_results = scoreboard_results_t::type_id::create("core_results", this);

        `uvm_info("core_im", $sformatf("Final fetch_fifo size: %0d", fetch_fifo.size()), UVM_DEBUG)
        if(!fetch_fifo.try_get(fetch_trans))
            `uvm_fatal(get_type_name(), $sformatf("No fetch element - completed_trans PC 0x%0hp", completed_trans.pc))

        core_results.dut_state.scalar_state.core_id = 0;
        core_results.dut_state.scalar_state.pc = completed_trans.pc;
        core_results.dut_state.scalar_state.dst_value = completed_trans.result;
        core_results.dut_state.scalar_state.dst_valid = completed_trans.dest_valid;
        core_results.dut_state.scalar_state.exc_bit = completed_trans.xcpt;
        if (m_env_cfg.core_type == core_uvm_pkg::SARGANTANA) begin
            core_results.dut_state.scalar_state.stored_value = completed_trans.stored_value;
            core_results.dut_state.scalar_state.ins = completed_trans.instr;
            core_results.dut_state.scalar_state.exc_cause = completed_trans.xcpt_cause;
            for (int i = 0; i < riscv_pkg::VLEN/64; i++) begin
                core_results.dut_state.rvv_state.vd[i] = completed_trans.vd[i];
            end
            if (fetch_fifo.try_peek(next_fetch_trans)) begin
                `uvm_info("core_im", $sformatf("Putting pc %h as next_instr", next_fetch_trans.fetch_pc), UVM_DEBUG)
                next_instr.pc = next_fetch_trans.fetch_pc;
                uvm_config_db#(dut_scalar_state_t)::set(null, "*", "next_instr", next_instr);
            end
        end else begin
            assert (completed_trans.pc == fetch_trans.mapper_id_pc) else begin
                uvm_config_db#(int)::set(null, "*", "next_pc", fetch_trans.mapper_id_pc);
                `uvm_info("core_im", $sformatf("Mapper PC: %h", fetch_trans.mapper_id_pc), UVM_LOW)
                `uvm_info("core_im", $sformatf("ROB    PC: %h", completed_trans.pc), UVM_LOW)
                `uvm_fatal("core_im", "ROB PC does not match fetched PC from mapper")
            end

            if (is_store(fetch_trans.mapper_id_inst) && !is_vector_store(fetch_trans.mapper_id_inst)) begin
                if (!store_fifo.try_get(store_trans))
                    `uvm_fatal(get_type_name(), $sformatf("No store remaining in fifo for committed instruction with rob entry: 0x%h, pc: 0x%h, inst: 0x%h", completed_trans.rob_head, completed_trans.pc, fetch_trans.mapper_id_inst))
                if (store_trans.rob_entry != completed_trans.rob_head)
                    `uvm_warning(get_type_name(), $sformatf("Store data and commited instruction have wrong rob entry value: store: 0x%h - commit: 0x%h", store_trans.rob_entry, completed_trans.rob_head))
                core_results.dut_state.scalar_state.stored_value = store_trans.store_data;
            end
            core_results.dut_state.scalar_state.ins = fetch_trans.mapper_id_inst;

            if(fetch_fifo.try_peek(next_fetch_trans)) begin
                `uvm_info("core_im", $sformatf("Putting %h with pc %h as next_instr", next_fetch_trans.mapper_id_inst, next_fetch_trans.mapper_id_pc), UVM_DEBUG)
                next_instr.pc = next_fetch_trans.mapper_id_pc;
                next_instr.ins = next_fetch_trans.mapper_id_inst;
                uvm_config_db#(dut_scalar_state_t)::set(null, "*", "next_instr", next_instr);
            end
            
        end

        `uvm_info("core_im", "Running run_and_retrieve_results", UVM_DEBUG)
        m_iss.run_and_retrieve_results(core_results.dut_state.scalar_state.ins, core_results.iss_state);
        if (fp_div_sqrt_cvt(core_results.dut_state.scalar_state.ins) && !core_results.dut_state.scalar_state.exc_bit) begin
            if (core_results.dut_state.scalar_state.dst_value !== core_results.iss_state.scalar_state.dst_value) begin
                if (core_results.iss_state.scalar_state.dst_value === (core_results.dut_state.scalar_state.dst_value+1) ||  core_results.iss_state.scalar_state.dst_value === (core_results.dut_state.scalar_state.dst_value-1)) begin
                    m_iss.set_fp_reg_value( core_results.iss_state.scalar_state.dst_num, core_results.dut_state.scalar_state.dst_value);
                    core_results.iss_state.scalar_state.dst_value = core_results.dut_state.scalar_state.dst_value;
                    `uvm_info("core_im", $sformatf("-----FALSE MISMATCH IN FDIV/FSQRT/FCVT----"), UVM_LOW)
                    `uvm_info("core_im", $sformatf("INSTRUCTION W/PC %h IS FP DIV/SQRT/FCVT, RESULT DIFFERED IN +/-1 AND ISS FPR[%d] VALUE WAS UPDATED = %h", core_results.dut_state.scalar_state.pc, core_results.iss_state.scalar_state.dst_num, core_results.dut_state.scalar_state.dst_value), UVM_LOW);
                end
            end
            void'(scoreboard_results.try_put(core_results));
        end else if (fp_cvt_to_int(core_results.dut_state.scalar_state.ins) && !core_results.dut_state.scalar_state.exc_bit) begin
            if (core_results.dut_state.scalar_state.dst_value !== core_results.iss_state.scalar_state.dst_value) begin
                if (core_results.iss_state.scalar_state.dst_value === (core_results.dut_state.scalar_state.dst_value+1) ||  core_results.iss_state.scalar_state.dst_value === (core_results.dut_state.scalar_state.dst_value-1)) begin
                    m_iss.set_destination_reg_value(core_results.iss_state.scalar_state.dst_num, core_results.dut_state.scalar_state.dst_value);
                    core_results.iss_state.scalar_state.dst_value = core_results.dut_state.scalar_state.dst_value;
                    `uvm_info("core_im", $sformatf("-----FALSE MISMATCH IN FCVT_TO_INT----"), UVM_LOW)
                    `uvm_info("core_im", $sformatf("INSTRUCTION W/PC %h IS FP CVT, RESULT DIFFERED IN +/-1 AND ISS VALUE WAS UPDATED = %h", core_results.dut_state.scalar_state.pc, core_results.dut_state.scalar_state.dst_value), UVM_LOW);
                end
            end
            void'(scoreboard_results.try_put(core_results));
        end else if (read_csrChecker(core_results.dut_state.scalar_state.ins,riscv_pkg::CSR_TIME)) begin
            if (core_results.dut_state.scalar_state.dst_value !== core_results.iss_state.scalar_state.dst_value) begin
                `uvm_info("core_im", $sformatf("-----Inside First Check----"), UVM_LOW)
                `uvm_info("core_im", $sformatf("ISS-SCALAR_STATE DESTINATION ADDRESS = %h along with the Value = %h", core_results.iss_state.scalar_state.dst_num, core_results.dut_state.scalar_state.dst_value), UVM_LOW);
                core_results.iss_state.scalar_state.dst_value = core_results.dut_state.scalar_state.dst_value;
                m_iss.set_destination_reg_value(core_results.iss_state.scalar_state.dst_num, core_results.dut_state.scalar_state.dst_value);
                `uvm_info("core_im", $sformatf("-----FALSE MISMATCH IN TIMER-CSR----"), UVM_LOW)
                `uvm_info("core_im", $sformatf("INSTRUCTION W/PC %h IS CSRR-TIMER, RESULT DIFFERED AND ISS VALUE WAS UPDATED = %h", core_results.dut_state.scalar_state.pc, core_results.dut_state.scalar_state.dst_value), UVM_LOW);
            end
            void'(scoreboard_results.try_put(core_results));
        end else if(read_csrChecker(core_results.dut_state.scalar_state.ins,riscv_pkg::CSR_MCYCLE)) begin
            if (core_results.dut_state.scalar_state.dst_value !== core_results.iss_state.scalar_state.dst_value) begin
                `uvm_info("core_im", $sformatf("-----Inside First Check----"), UVM_LOW)
                `uvm_info("core_im", $sformatf("ISS-SCALAR_STATE DESTINATION ADDRESS = %h along with the Value = %h", core_results.iss_state.scalar_state.dst_num, core_results.dut_state.scalar_state.dst_value), UVM_LOW);
                core_results.iss_state.scalar_state.dst_value = core_results.dut_state.scalar_state.dst_value;
                m_iss.set_destination_reg_value(core_results.iss_state.scalar_state.dst_num, core_results.dut_state.scalar_state.dst_value);
                `uvm_info("core_im", $sformatf("-----FALSE MISMATCH IN TIMER-CSR----"), UVM_LOW)
                `uvm_info("core_im", $sformatf("INSTRUCTION W/PC %h IS CSRR-TIMER, RESULT DIFFERED AND ISS VALUE WAS UPDATED = %h", core_results.dut_state.scalar_state.pc, core_results.dut_state.scalar_state.dst_value), UVM_LOW);
            end
            void'(scoreboard_results.try_put(core_results));
        end else if (m_env_cfg.core_type == core_uvm_pkg::LAGARTO_KA) begin
            if (! m_iss.is_vector_ins(core_results.dut_state.scalar_state.ins) || vestvl_vsetvli(core_results.dut_state.scalar_state.ins) ) begin
                void'(scoreboard_results.try_put(core_results));
            end else begin
                rvv_dut_tx dut_state;
                //take vpu results from monitor_post() method (completed_instr from oviProtocol)
                //(should we check that the completed instruction corresponds to the latest issued one?)
                //and send to vpu_scoreboard, which receives:
                // -vpu_ins_tx containing only a vpu_iss_state_t (scalar_state + vpu_results - should be return by run_and_retrieve_results)
                // -rvv_dut_tx containing only a vpu_dut_state_t
                if (vpu_results_port.try_get(dut_state)) begin
                    core_results.dut_state.rvv_state = (dut_state.dut_state.rvv_state);
                    void'(vpu_scoreboard_results.try_put(core_results));
                end
            end
        end else begin
            void'(scoreboard_results.try_put(core_results));
        end
    endfunction : write_completed

    function bit read_csrChecker(logic [31:0] instr, logic [11:0] ADDRESS);
        logic [6:0] opcode;
        logic [11:0] csr_addr;
        bit op_csr, csr_read;
        bit is_read;
        bit is_timer_addr;
        opcode      = instr[6:0];
        op_csr      = (opcode == 7'b1110011);
        csr_addr    = instr[31:20];
        is_read     = (instr[14:12] == 3'b010);
        csr_read    = op_csr && is_read;
        is_timer_addr = (csr_addr == ADDRESS);
        `uvm_info(get_type_name(),$sformatf("The current CSR Address is: %0h",csr_addr),UVM_DEBUG)
        `uvm_info(get_type_name(),$sformatf("The current instruction is: %0h, with csr read operation is: %0h, and csr_addr is: %0h with Timer Address is: %0h",instr, csr_read,is_timer_addr,ADDRESS),UVM_DEBUG)
        return (csr_read && is_timer_addr);
    endfunction : read_csrChecker

    function bit fp_div_sqrt_cvt(logic [31:0] instr);
        logic [6:0] opcode;
        logic [6:0] funct7;
        bit op_fp;
        bit fdiv_s, fdiv_d, fdiv_q, fsqrt_s, fsqrt_d, fsqrt_q, fcvt_s_w, fcvt_s_d, fcvt_d_s, fcvt_d_w;
        bit is_fdiv, is_fsqrt, is_fcvt;
        opcode   = instr[6:0];
        funct7   = instr[31:25];
        op_fp    = (opcode==7'b1010011);
        fdiv_s   = (funct7 == 7'b0001100);
        fdiv_d   = (funct7 == 7'b0001101);
        fdiv_q   = (funct7 == 7'b0001111);
        fsqrt_s  = (funct7 == 7'b0101100);
        fsqrt_d  = (funct7 == 7'b0101101);
        fsqrt_q  = (funct7 == 7'b0101111);
        fcvt_s_w = (funct7 == 7'b1101000);
        fcvt_s_d = (funct7 == 7'b0100000);
        fcvt_d_s = (funct7 == 7'b0100001);
        fcvt_d_w = (funct7 == 7'b1101001);
        is_fdiv  = op_fp && ( fdiv_s || fdiv_d || fdiv_q);
        is_fsqrt = op_fp && ( fsqrt_s || fsqrt_d || fsqrt_q);
        is_fcvt  = op_fp && (fcvt_s_w || fcvt_s_d || fcvt_d_s || fcvt_d_w);
        return  (is_fdiv || is_fsqrt || is_fcvt);
    endfunction : fp_div_sqrt_cvt

    function bit fp_cvt_to_int(logic [31:0] instr);
        logic [6:0] opcode;
        logic [6:0] funct7;
        bit op_fp;
        bit fcvt_w_s, fcvt_w_d;
        bit is_fcvt;
        opcode   = instr[6:0];
        funct7   = instr[31:25];
        op_fp    = (opcode==7'b1010011);
        fcvt_w_s = (funct7 == 7'b1100000);
        fcvt_w_d = (funct7 == 7'b1100001);
        is_fcvt  = op_fp && (fcvt_w_s || fcvt_w_d);
        return is_fcvt;
    endfunction : fp_cvt_to_int

endclass : core_im

`endif

