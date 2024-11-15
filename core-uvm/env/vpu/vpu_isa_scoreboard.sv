
`ifndef VPU_ISA_SCOREBOARD
`define VPU_ISA_SCOREBOARD

`include "uvm_macros.svh"
`include "macros.sv"
import uvm_pkg::*;

import core_uvm_pkg::rvv_dut_tx;

class vpu_isa_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(vpu_isa_scoreboard)

    uvm_blocking_get_port #(core_uvm_types_pkg::scoreboard_results_t) m_results;

    int executed_instr;

    uvm_event_pool pool = uvm_event_pool::get_global_pool();
    uvm_event iss_finished = pool.get("iss_finished");

    vpu_agent_cfg m_cfg;

    virtual function custom_checks();

    endfunction: custom_checks

    function new(string name = "vpu_isa_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        executed_instr = 0;
        m_results = new ("m_results", this);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        vpu_ins_tx iss_state;
        rvv_dut_tx dut_state;
        core_uvm_types_pkg::scoreboard_results_t scoreboard_results = core_uvm_types_pkg::scoreboard_results_t::type_id::create("scoreboard_results");
        core_uvm_types_pkg::iss_state_t no_ins = '{default:'0};
        uvm_config_db #(exit_status_code_t)::set(null, "*", "exit_status_code", EXIT_SUCCESS);
        uvm_config_db #(core_uvm_types_pkg::iss_state_t)::set(null, "*", "last_instr", no_ins);

        if(! m_cfg.disable_checks) begin
            //phase.raise_objection(this);

            forever begin
                if (iss_finished.is_on()) begin
                    uvm_config_db #(exit_status_code_t)::set(null, "*", "exit_status_code", EXIT_SUCCESS);
                    break;
                end
                m_results.get(scoreboard_results);
                iss_state = vpu_ins_tx::type_id::create("iss_state");
                dut_state = rvv_dut_tx::type_id::create("dut_state");
                iss_state.iss_state = scoreboard_results.iss_state; //type is iss_rvv_state_t
                dut_state.dut_state = scoreboard_results.dut_state; //type is dut_rvv_state_t

                if (!dut_state.dut_state.rvv_state.ignore) begin
                    compare(dut_state.dut_state, iss_state.iss_state);
                end
                if (dut_state.dut_state.rvv_state.ignore) begin
                    `uvm_info(get_type_name(), $sformatf("Ignoring instruction due to RTL optimization with PC: 0x%0h", scoreboard_results.dut_state.scalar_state.pc), UVM_LOW)
                end
            end
            //$display("VPU SCOREBOARD - ISS FINISHED DROPPING OBJECTION");
            uvm_config_db #(exit_status_code_t)::set(null, "*", "exit_status_code", EXIT_SUCCESS);
            //phase.drop_objection(this);
        end

    endtask : run_phase

    // Function: compare_vector_results
    // Compares the contents of two vectors
    function bit compare_vector_results(int vl, int sew, core_uvm_types_pkg::vec_els_t iss, core_uvm_types_pkg::vec_els_t dut, ref string vreg_results);
        bit error = 0;
        string dut_vector, iss_vector;
        vreg_results = "";

        for (int i = 0; i < vl; ++i) begin
            for (int j = 0; j < sew/BYTE; ++j) begin
                if (!(dut[i*sew/EPI_pkg::ELEN][i*sew%EPI_pkg::ELEN + j*BYTE +: BYTE] === iss[i*sew/EPI_pkg::ELEN][i*sew%EPI_pkg::ELEN + j*BYTE +: BYTE])) begin
                    vreg_results = $sformatf("First element mismatch: %d\n", i);
                    error = 1;
                    break;
                end
            end
            if (error) break;
        end
        print_dvreg(vl, sew, dut_vector, dut);
        print_dvreg(vl, sew, iss_vector, iss);
        vreg_results = {vreg_results, $sformatf("DUT: %s\nISS: %s", dut_vector, iss_vector)};
        return error;

    endfunction : compare_vector_results

    // Function: compare_reduction
    // Compares reduction results
    function bit compare_reduction(core_uvm_types_pkg::iss_state_t iss, core_uvm_types_pkg::vec_els_t dut, ref string vreg_results);
        int vl = (!iss.scalar_state.csr.vl) ? 0 : 1;
        if (widening_instruction(iss.scalar_state.instr))			return compare_vector_results(vl, iss.scalar_state.csr.vsew*2, iss.rvv_state.vd, dut, vreg_results);
        else if (narrowing_instruction(iss.scalar_state.instr))	return compare_vector_results(vl, iss.scalar_state.csr.vsew/2, iss.rvv_state.vd, dut, vreg_results);
        else													return compare_vector_results(vl, iss.scalar_state.csr.vsew, iss.rvv_state.vd, dut, vreg_results);

    endfunction : compare_reduction

    // Function: compare_scalar
    // Compares scalar results
    function bit compare_scalar(int vl, int sew, longint unsigned rd, longint unsigned iss, longint unsigned dut, ref string vreg_results);
        string dut_element, iss_element;
        bit error = 0;

        dut_element = "";
        iss_element = "";
        for (int j = 0; j < sew/BYTE; ++j) begin
            if (!(dut[j*BYTE +: BYTE] === iss[j*BYTE +: BYTE])) error = 1;
            dut_element = {$sformatf("%h", dut[j*BYTE +: BYTE]), dut_element};
            iss_element = {$sformatf("%h", iss[j*BYTE +: BYTE]), iss_element};
        end
        vreg_results = $sformatf("DUT: %s\nISS: %s", dut_element, iss_element);
        if (rd) return error;
        else return 0;

    endfunction : compare_scalar

    function bit compare_illegal( bit iss_illegal,  bit dut_illegal, ref string results );
        if( iss_illegal != dut_illegal ) begin
            results = $sformatf("Illegal instruction mismatch. Spike: %b VPU %b", iss_illegal, dut_illegal);
            return 1;
        end
        return 0;
    endfunction : compare_illegal

    function bit compare_fflags_vxsat(core_uvm_types_pkg::iss_state_t iss, core_uvm_types_pkg::dut_state_t dut, ref string vreg_results);
        bit error = 0;
        string dut_vector, iss_vector;

        if (dut.rvv_state.fflags != iss.scalar_state.csr.fflags) begin
            vreg_results = {vreg_results,$sformatf("Execution abort due to FFlags mismatch: ISS %b VPU %b", iss.scalar_state.csr.fflags, dut.rvv_state.fflags)};
            uvm_config_db #(string)::set(null,"*", "fail_instr_cause", "FFLAGS MISMATCH");
            error = 1;
        end
        else begin
            //`uvm_info("protocol_scoreboard", $sformatf("FFlags: ISS %b VPU %b", iss.scalar_state.csr.fflags, dut.fflags), UVM_LOW)
        end

        if (dut.rvv_state.vxsat != iss.scalar_state.csr.vxsat) begin
            vreg_results = {vreg_results, $sformatf("Execution abort due to vxsat mismatch: ISS %b VPU %b", iss.scalar_state.csr.vxsat, dut.rvv_state.vxsat)};
            uvm_config_db #(string)::set(null,"*", "fail_instr_cause", "VXSAT MISMATCH");
            error |= 1;
        end
        else begin
            //`uvm_info("protocol_scoreboard", $sformatf("vxsat: ISS %b VPU %b", iss.scalar_state.csrvxsat, dut.vxsat), UVM_LOW)
        end
        return error;
    endfunction

    function string format_mask(core_uvm_types_pkg::mask_els mask, int sew);
        int i;
        string resultString = "";

        for (i = 0; i < 2048; i += 4) begin
            resultString = {$sformatf("%h", mask[i+:4]), resultString};
            if ((i + 4)%sew == 0 && i != 0) resultString = {" ", resultString};
        end
        return resultString;

    endfunction : format_mask

    function int iss_mask_string_length(string iss_vd, int vl);
        int i, elem;
        elem = 0;

        for (i = iss_vd.len() - 1; i >= 0; i--) begin
            if (iss_vd[i] == ":") i = i + 2;
            else if (iss_vd[i] == "0") elem++;
            else if (iss_vd[i] == "1") elem++;
            else if (iss_vd[i] == "2") elem++;
            else if (iss_vd[i] == "3") elem++;
            else if (iss_vd[i] == "4") elem++;
            else if (iss_vd[i] == "5") elem++;
            else if (iss_vd[i] == "6") elem++;
            else if (iss_vd[i] == "7") elem++;
            else if (iss_vd[i] == "8") elem++;
            else if (iss_vd[i] == "8") elem++;
            else if (iss_vd[i] == "9") elem++;
            else if (iss_vd[i] == "a") elem++;
            else if (iss_vd[i] == "b") elem++;
            else if (iss_vd[i] == "c") elem++;
            else if (iss_vd[i] == "d") elem++;
            else if (iss_vd[i] == "e") elem++;
            else if (iss_vd[i] == "f") elem++;

            if (elem == vl) break;
        end
        return i;

    endfunction : iss_mask_string_length

    function bit compare_mask_changes(core_uvm_types_pkg::dut_state_t dut, core_uvm_types_pkg::iss_state_t iss, ref string mask_results);
        int i;
        int DLEN = 512;
        bit error = 0;
        string iss_mask;
        int sew = iss.scalar_state.csr.vsew;
        int vl = iss.scalar_state.csr.vl;
        int elements_per_bank = (vl/ELEN/(DLEN/ELEN) > 0) ? vl/ELEN/(DLEN/ELEN) : vl/ELEN;
        string debug = (vl/ELEN/(DLEN/ELEN) > 0) ? " 64b ELEMENTS PER BANK FOR THE MASK" : " 64b ELEMENTS FOR THE MASK IN TOTAL";
        mask_results = "";
        iss_mask = "";

        for (i = 0; i < vl; i++) begin                                                  // Checking that the VL length mask matches
            if (!(dut.rvv_state.mask_data[i] === iss.rvv_state.vd[i/ELEN][i%ELEN])) begin
                mask_results = $sformatf("Element %0d mask mismatch\n", i);
                error = 1;
                break;
            end
        end

        if (!error) mask_results = "mask match ";

        print_iss_mask(iss.scalar_state.csr.vl, iss.scalar_state.csr.vsew, iss_mask, iss.rvv_state.vd);
        mask_results = {mask_results, $sformatf("VL: %0d // %0d ELEMENTS (SEW%0d) // %0d%0s\n\nDUT MRF: %s\n\nISS V0: %s\n", vl, vl/4/(sew/4), sew, elements_per_bank, debug, format_mask(dut.rvv_state.mask_data, iss.scalar_state.csr.vsew), iss_mask)};
        return error;
    endfunction : compare_mask_changes

    function int mem_sew(logic [INSTR_WIDTH-1:0] inst);
        int el_size;
        el_size = 0;
        case (inst[14:12])
            3'b000: el_size = 8;
            3'b101: el_size = 16;
            3'b110: el_size = 32;
            3'b111: el_size = 64;
        endcase
        return el_size;
    endfunction : mem_sew

    function compare(core_uvm_types_pkg::dut_state_t dut, core_uvm_types_pkg::iss_state_t iss);

        int errors = 0;
        int dest_valid;
        string vreg_results = "";
		string mask_results = "";
        string sources = "";

        // Detect special instruction types, compare different
        if (iss.scalar_state.csr.trap_illegal || dut.rvv_state.illegal)      errors = compare_illegal(iss.scalar_state.csr.trap_illegal, dut.rvv_state.illegal, vreg_results );
        else if ((iss.scalar_state.csr.vl == 0) && !(scalar_dest_reg(iss.scalar_state.instr, 0)) && !(scalar_dest_reg(iss.scalar_state.instr, 1))) errors = 0; //Not comparing instructions with VL=0 if not vcpop, vfirst, vmv.x.s, vfmv.f.s
        else if (`IS_STORE(iss.scalar_state.instr))              errors = 0;
        else if (`IS_LOAD(iss.scalar_state.instr))               errors += compare_vector_results(iss.scalar_state.csr.vl, mem_sew(iss.scalar_state.instr), iss.rvv_state.vd, dut.rvv_state.vd, vreg_results);
        else if (scalar_dest_reg(iss.scalar_state.instr, 0))    errors += compare_scalar(iss.scalar_state.csr.vl, iss.scalar_state.csr.vsew, iss.scalar_state.dst_num, iss.scalar_state.dst_value, dut.rvv_state.scalar_dest, vreg_results); // Int scalar reg
        else if (scalar_dest_reg(iss.scalar_state.instr, 1))    errors += compare_scalar(iss.scalar_state.csr.vl, iss.scalar_state.csr.vsew, 1, iss.scalar_state.dst_value, dut.rvv_state.scalar_dest, vreg_results); // FP scalar reg
        else if (vset_instruction(iss.scalar_state.instr))       errors += compare_scalar(iss.scalar_state.csr.vl, iss.scalar_state.csr.vsew, iss.scalar_state.dst_num, iss.scalar_state.dst_value, dut.rvv_state.scalar_dest, vreg_results);
        else if (reduction_instruction(iss.scalar_state.instr))  errors += compare_reduction(iss, dut.rvv_state.vd, vreg_results);
        else if (vwfunary0_vrfunary0(iss.scalar_state.instr))   errors += compare_vector_results(1, iss.scalar_state.csr.vsew, iss.rvv_state.vd, dut.rvv_state.vd, vreg_results); //check for vfmv.s.f and vfmv.f.s instructions
        else if (widening_instruction(iss.scalar_state.instr))   errors += compare_vector_results(iss.scalar_state.csr.vl, iss.scalar_state.csr.vsew, iss.rvv_state.vd, dut.rvv_state.vd, vreg_results);
        else if (narrowing_instruction(iss.scalar_state.instr))  errors += compare_vector_results(iss.scalar_state.csr.vl, iss.scalar_state.csr.vsew, iss.rvv_state.vd, dut.rvv_state.vd, vreg_results);
        else                                        errors += compare_vector_results(iss.scalar_state.csr.vl, iss.scalar_state.csr.vsew, iss.rvv_state.vd, dut.rvv_state.vd, vreg_results);

        errors += compare_fflags_vxsat(iss, dut, vreg_results);
        if (`vdest(iss.scalar_state.instr) == 0 && !(`IS_STORE(iss.scalar_state.instr) || `IS_VWXUNARY0(iss.scalar_state.instr) || `IS_VWFUNARY0(iss.scalar_state.instr))) errors += compare_mask_changes(dut, iss, mask_results);

        print_sources(iss, sources);
        if (errors) begin
            `uvm_info("vpu_isa_scoreboard", $sformatf("Wrong: PC 0x%0h, INSTR 0x%0h DISASM: %s ", iss.scalar_state.pc, iss.scalar_state.instr[31:0], iss.scalar_state.disasm), UVM_LOW)
            `uvm_info("vpu_isa_scoreboard", $sformatf("CSRS: {vsew: %h, vl: %h, rounding mode: %h}", iss.scalar_state.csr.vsew, iss.scalar_state.csr.vl, iss.scalar_state.csr.vxrm), UVM_LOW)
            `uvm_info("vpu_isa_scoreboard", $sformatf("Sources:\n\n%s", sources), UVM_DEBUG)
            `uvm_info("vpu_isa_scoreboard", $sformatf("Results:\n\n%s", vreg_results), UVM_LOW)
			`uvm_info("vpu_isa_scoreboard", $sformatf("Mask:\n\n%s", mask_results), UVM_LOW)
            uvm_config_db #(core_uvm_types_pkg::iss_state_t)::set(null, "*", "fail_instr", iss);
            uvm_config_db #(exit_status_code_t)::set(null, "*", "exit_status_code", EXIT_EXECUTION_ERROR);
            `uvm_fatal("vpu_isa_scoreboard", $sformatf(" Execution abort due to %d scoreboard mismatches", errors))
        end
        else begin
            `uvm_info("vpu_isa_scoreboard", $sformatf("Correct: PC 0x%0h, INSTR 0x%0h DISASM: %s ", iss.scalar_state.pc, iss.scalar_state.instr[31:0], iss.scalar_state.disasm), UVM_LOW)
			`uvm_info("vpu_isa_scoreboard", $sformatf("Sources:\n\n%s", sources), UVM_HIGH)
            `uvm_info("vpu_isa_scoreboard", $sformatf("Results:\n\n%s", vreg_results), UVM_HIGH)
            if (`vdest(iss.scalar_state.instr) == 0 && !(`IS_STORE(iss.scalar_state.instr) || `IS_VWXUNARY0(iss.scalar_state.instr) || `IS_VWFUNARY0(iss.scalar_state.instr))) `uvm_info("vpu_isa_scoreboard", $sformatf("Mask:\n\n%s", mask_results), UVM_LOW)
            uvm_config_db #(int)::set(null, "*", "executed_instr", executed_instr);
            uvm_config_db #(core_uvm_types_pkg::iss_state_t)::set(null, "*", "last_instr", iss);
            ++executed_instr;
        end

    endfunction : compare

    function void report_phase(uvm_phase phase);
        string cause_str;
        string report_msg;
        string dasm;
        core_uvm_types_pkg::iss_state_t last_instr;
        exit_status_code_t exit_code;
        vpu_ins_tx iss_tx;
        uvm_coreservice_t cs;
        uvm_report_server svr;
        int fd; // = $fopen({$value$plusargs("OUTPUT_DIR=%s"), "/report.yaml"}, "w");
        string output_dir;
        if (!$test$plusargs("OUTPUT_DIR"))
            `uvm_warning(get_type_name(), "No OUTPUT_DIR")
        $value$plusargs("OUTPUT_DIR=%s", output_dir);
        fd = $fopen({output_dir, "/report_vpu.yaml"}, "w");

        cs = uvm_coreservice_t::get();
        svr = cs.get_report_server();
        cause_str = "SUCCESS";
        if(! m_cfg.disable_checks) begin
            if(!uvm_config_db#(exit_status_code_t)::get(null,"*", "exit_status_code", exit_code)) begin
                `uvm_error(get_type_name(), "No exit code found")
            end
            else begin
                case (exit_code)
                EXIT_EXECUTION_ERROR: begin
                    if(!uvm_config_db#(core_uvm_types_pkg::iss_state_t)::get(null,"*", "fail_instr", last_instr)) begin
                        `uvm_error(get_type_name(), "No fail_instr in the db")
                    end
                    cause_str = "SB_MISMATCH";
                end
                EXIT_TIMEOUT: begin
                    //if (!iss_results_port.try_get(iss_tx))
                    //    `uvm_fatal(get_type_name(), "No pending ISS state transactions after timeout!")
                    //last_instr = iss_tx.iss_state;
                    cause_str = "TIMEOUT";
                end
                default: begin
                    if(!uvm_config_db#(core_uvm_types_pkg::iss_state_t)::get(null,"*", "last_instr", last_instr)) begin
                        `uvm_error(get_type_name(), "No fail_instr in the db")
                    end
                end
                endcase
            end
        end
        report_msg = $sformatf("cause: %0d\nseed: %0d\nexecuted_instr: %0d\ninstr:\n    pc: 0x%0h\n    ins: 0x%0h\n    disasm: \"%s\"\n    csr:\n        vsew: 0x%0h\n    vlen: 0x%0h\n        vxrm: 0x%0h\n        frm: 0x%0h", cause_str, $get_initial_random_seed(), executed_instr, last_instr.scalar_state.pc, last_instr.scalar_state.instr, last_instr.scalar_state.disasm, last_instr.scalar_state.csr.vsew, last_instr.scalar_state.csr.vl, last_instr.scalar_state.csr.vxrm, last_instr.scalar_state.csr.frm);
            $fdisplay(fd, report_msg);
            $fclose(fd);
    endfunction : report_phase


endclass : vpu_isa_scoreboard

`endif
