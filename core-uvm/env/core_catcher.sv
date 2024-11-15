//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_catcher 
// File          : core_catcher.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_report_catcher. This class instantiates the
//                 core_catcher and also monitors and taken care of error related things 
//                 (Catch messages issued by the uvm report server.).  
//----------------------------------------------------------------------
`include "uvm_macros.svh"
import uvm_pkg::*;
import riscv_pkg::*;

import "DPI-C" function string getenv(input string env_name);
import "DPI-C" function string disassemble_insn_str(input longint instruction);

class core_catcher extends uvm_report_catcher;
    core_iss_wrapper m_iss;
    core_env_cfg m_env_cfg;

    function new(string name = "core_catcher");
        super.new(name);
    endfunction

    virtual function action_e catch();
        m_env_cfg = new();
        if (!uvm_config_db #(core_env_cfg)::get(null, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end
        if (get_severity() == UVM_FATAL) begin
            int fd;
            int next_pc;
            string report_msg;
            string cause_str;
            string dasm;
            dut_scalar_state_t last_instr;
            iss_state_t vpu_last_instr;
            int executed_ins;
            int executed_interrupts;
            iss_state_t iss_last_instr;

            fd = $fopen({getenv("VERIF"), "/sim/build/report.yaml"}, "w");
            if (!m_env_cfg.jtag_test) begin
                if(!uvm_config_db#(int)::get(null,"*", "executed_ins", executed_ins)) begin
                    `uvm_error(get_type_name(), "No instruction committed")
                end

                if(!uvm_config_db#(int)::get(null,"*", "executed_interrupts", executed_interrupts)) begin
                    `uvm_info(get_type_name(), "No executed_interrupts in the db", UVM_HIGH)
                    executed_interrupts = 0;
                end

                if (get_id() == "uvm_scoreboard_pc") begin
                    cause_str = "PC MISMATCH";
                    if(!uvm_config_db#(dut_scalar_state_t)::get(null,"*", "fail_instr", last_instr)) begin
                        `uvm_error(get_type_name(), "No fail_instr to report")
                        last_instr.pc = 'hDEAD;
                        last_instr.ins = 'hDEAD;
                    end
                end else if (get_id() == "uvm_scoreboard_ins") begin
                    cause_str = "INSTRUCTION MISMATCH";
                    if(!uvm_config_db#(dut_scalar_state_t)::get(null,"*", "fail_instr", last_instr)) begin
                        `uvm_error(get_type_name(), "No fail_instr to report")
                        last_instr.pc = 'hDEAD;
                        last_instr.ins = 'hDEAD;
                    end
                end else if (get_id() == "uvm_scoreboard_res") begin
                    cause_str = "RESULT MISMATCH";
                    if(!uvm_config_db#(dut_scalar_state_t)::get(null,"*", "fail_instr", last_instr)) begin
                        `uvm_error(get_type_name(), "No fail_instr to report")
                        last_instr.pc = 'hDEAD;
                        last_instr.ins = 'hDEAD;
                    end
                end else if (get_id() == "uvm_scoreboard_exc") begin
                    cause_str = "EXCEPTION MISMATCH";
                    if(!uvm_config_db#(dut_scalar_state_t)::get(null,"*", "fail_instr", last_instr)) begin
                        `uvm_error(get_type_name(), "No fail_instr to report")
                        last_instr.pc = 'hDEAD;
                        last_instr.ins = 'hDEAD;
                    end
                end else if (get_id() == "uvm_scoreboard_mult") begin
                    cause_str = "MULTIPLE MISMATCH";
                    if(!uvm_config_db#(dut_scalar_state_t)::get(null,"*", "fail_instr", last_instr)) begin
                        `uvm_error(get_type_name(), "No fail_instr to report")
                        last_instr.pc = 'hDEAD;
                        last_instr.ins = 'hDEAD;
                    end
                end else if (get_id() == "top_tb") begin
                    cause_str = "TIMEOUT";
                    m_iss.run_and_retrieve_results(iss_last_instr.scalar_state.instr, iss_last_instr);
                    last_instr.pc = iss_last_instr.scalar_state.pc;
                    last_instr.ins = iss_last_instr.scalar_state.instr;
                end else if (get_id() == "core_im") begin
                    cause_str = "ROB_FAULT";
                    if(!uvm_config_db#(int)::get(null,"*", "next_pc", next_pc)) begin
                        `uvm_error(get_type_name(), $sformatf("%s:No next_instr to report", cause_str))
                    end
                    last_instr.pc = 'hDEAD;
                    last_instr.ins = 'hDEAD;
                end else if (get_id() == "uvm_scoreboard_int") begin
                    cause_str = "MIP_MISMATCH";
                    if(!uvm_config_db#(int)::get(null,"*", "next_pc", next_pc)) begin
                        `uvm_error(get_type_name(), $sformatf("%s:No next_instr to report", cause_str))
                    end
                    last_instr.pc = 'hDEAD;
                    last_instr.ins = 'hDEAD;
                end else if (m_env_cfg.vpu_enabled) begin
                    last_instr.pc = vpu_last_instr.scalar_state.pc;
                    last_instr.ins = vpu_last_instr.scalar_state.instr;
                end else begin
                    if (!uvm_config_db#(dut_scalar_state_t)::get(null,"*", "next_instr", last_instr)) begin
                       `uvm_error(get_type_name(), "No next_instr to report")
                       last_instr.pc = 'hDEAD;
                       last_instr.ins = 'hDEAD;
                    end
                end
                dasm = disassemble_insn_str(last_instr.ins);
                report_msg = $sformatf("cause: %0d\nseed: %0d\ninstr:\n    pc: 0x%0h\n    ins: 0x%0h\n    disasm: \"%s\"\n    executed_ins: %d\n    executed_interrupts: %d\n    csr:\n        vsew: 0x%0h\n        vlen: 0x%0h\n        vxrm: 0x%0h\n        frm: 0x%0h", cause_str, $get_initial_random_seed(), last_instr.pc, last_instr.ins, dasm, executed_ins, executed_interrupts, last_instr.csr.vsew, last_instr.csr.vl, last_instr.csr.vxrm, last_instr.csr.frm );
            end else begin
                report_msg = $sformatf("cause: %0d\nseed: %0d\ninstr:\n    pc: 0x%0h\n    ins: 0x%0h\n    disasm: \"%s\"\n    executed_ins: %d\n    executed_interrupts: %d\n    csr:\n        vsew: 0x%0h\n        vlen: 0x%0h\n        vxrm: 0x%0h\n        frm: 0x%0h", cause_str, $get_initial_random_seed(), '0, '0, "JTAG TEST BEING EXECUTED",'0,'0,'0,'0,'0,'0);
            end
            $fdisplay(fd, report_msg);
            $fclose(fd);
        end
        return THROW;
    endfunction : catch
endclass
