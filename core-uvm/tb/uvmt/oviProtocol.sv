import EPI_pkg::*;
`include "uvm_macros.svh"
import uvm_pkg::*;
import core_uvm_types_pkg::*;

`include "macros.sv"

`ifdef GLS
    `define VIF ovi.cb
`else
    `define VIF ovi
`endif

`define ROB_NAME reorder_buffer_inst
 `ifdef VPU_VERSION_EPAC_11_LEGACY
    `define ROB_NAME reorder_buffer
 `elsif VPU_VERSION_EPAC_10
 `ifndef BSC_GLS
 `define ROB_NAME reorder_buffer
 `endif
 `endif

`define RENAMING_VIF renaming_unit_if

    import utils_pkg::protocol_instr_t;
    import utils_pkg::vpu_ins_tx;

class protocol extends utils_pkg::protocol_base_class;

    // Variable: iss_instr
    // Queue that contains the instructions that have been issued, waiting to be retrieved by the monitor_pre
    iss_state_t iss_instr[$];

    // Variable: completed_instr
    // Queue that contains the instructions that have been completed, waiting to be retrieved by the monitor_post
    dut_state_t completed_instr[$];

    // Variable: completed_protocol_instr
    // Queue that contains the instructions that have been completed, waiting to be retrieved by the monitor_protocol
    protocol_instr_t completed_protocol_instr[$];

    // Variable: pending_instr
    // Queue that contains the instructions that are pending to be issued
    protocol_instr_t pending_instr[$];

    // Variable: infl_instr
    // Queue that contains the instructions that have been issued and still haven't completed
    protocol_instr_t infl_instr[$];

    // Variable: to_kill_instr
    // Queue that contains the indexes to the instructions inside infl_instr that must be killed
    int to_kill_instr[$];

    // Variable: m_cfg
    vpu_uvm_pkg::ovi_cfg m_cfg;

    protocol_instr_t ovi_state;

    // Task: wait_for_clk
    // Waits for as many num_cycles cycles in the interface clock
    virtual task wait_for_clk(int unsigned num_cycles = 1);
      repeat (num_cycles)
        @(posedge `VIF.clk);
    endtask

    // Function: drive
    // Pushes the instruction inside the transaction into the pending instructions queue
    virtual function drive (vpu_ins_tx req);
        protocol_instr_t new_instr;
        core_uvm_pkg::iss_state_t iss_state = req.iss_state;

        iss_instr.push_back(iss_state);

        new_instr.valid_sb_id = 0;
        new_instr.iss_state = req.iss_state;
        new_instr.vstart_vlfof = 0;
        pending_instr.push_back(new_instr);
        `uvm_info("ovi_protocol", $sformatf("Pushing instruction %h to pending instructions", req.iss_state.scalar_state.instr), UVM_DEBUG)
    endfunction : drive

    // Function: new_ins_tx
    // Returns whether or not there are new instructions received from the driver
    virtual function bit new_ins_tx();
        return (iss_instr.size() > 0);
    endfunction : new_ins_tx

    // Function: monitor_pre
    // Returns the first pending instruction received from the driver
    virtual function iss_rvv_state_t monitor_pre();
        iss_state_t m_iss_state = iss_instr.pop_front();
        return m_iss_state.rvv_state;
    endfunction : monitor_pre

    // Function: new_dut_tx
    // Returns whether or not there are new completed instructions
    virtual function bit new_dut_tx();
        return (completed_instr.size() > 0);
    endfunction : new_dut_tx

    // Function: monitor_post
    // Returns the first pending completed instruction
    virtual function dut_rvv_state_t monitor_post();
        dut_state_t m_dut_state = completed_instr.pop_front();
        return m_dut_state.rvv_state;
    endfunction : monitor_post

    // Function: new_protocol_tx
    // Returns whether or not there are new completed instructions
    virtual function bit new_protocol_tx();//not used
        return (completed_protocol_instr.size() > 0);
    endfunction : new_protocol_tx

    // Function: monitor_protocol
    // Returns the first pending completed instruction
    virtual function protocol_instr_t monitor_protocol();//not used
        protocol_instr_t m_protocol_instr = completed_protocol_instr.pop_front();
        return m_protocol_instr;
    endfunction : monitor_protocol

    // Function: next_infl_instr
    // Returns the first infl instruction
    virtual function protocol_instr_t next_infl_instr();
        protocol_instr_t m_protocol_instr = infl_instr[0];
        return m_protocol_instr;
    endfunction : next_infl_instr

    `include "oviUtilities.sv"

//    // Function: retrieve_vpu_result
//    // Accesses the vector register signal and creates a vec_els_t with the
//    // content of the register
//    function vec_els_t retrieve_vpu_result;
//        vec_els_t vec_el;
//        int remaining_bits;
//        int vsew_value;
//        case (`RENAMING_VIF.commit_vsew_i)
//            SEW8: vsew_value = 8;
//            SEW16: vsew_value = 16;
//            SEW32: vsew_value = 32;
//            SEW64: vsew_value = 64;
//        endcase
//
//
//        //NEED TO ADD GRANULARITY TO THE RETRIEVING OF THE VECTORS! MAYBE USE
//        //BIT BY BIT OR VSEW
//        if (`RENAMING_VIF.commit_vsew_i == SEW8) begin
//            for (int i = 0 ; i < EPI_pkg::MAX_VLEN; i = i + EPI_pkg::ELEN) begin
//                if (i == (((`RENAMING_VIF.commit_vlen_i - 1) * vsew_value) - (((`RENAMING_VIF.commit_vlen_i - 1) * vsew_value)%EPI_pkg::ELEN))) begin
//                    remaining_bits = ((`RENAMING_VIF.commit_vlen_i * vsew_value)%EPI_pkg::ELEN);
//
//                    if (!remaining_bits)
//                        vec_el[i/EPI_pkg::ELEN] = vreg_if.wb_data[i +: EPI_pkg::ELEN];
//                    else begin
//                        for (int j = 0; j < EPI_pkg::ELEN; j = j + vsew_value) begin
//                           if (j < remaining_bits)
//                               vec_el[i/EPI_pkg::ELEN][j +: 8] = vreg_if.wb_data[(i + j) +: 8];
//                        end
//                        continue;
//                    end
//                end
//                else if ((i < (`RENAMING_VIF.commit_vlen_i - 1) * vsew_value) || (`RENAMING_VIF.roll_back_vstart_o != 0) || ((`RENAMING_VIF.commit_vlen_i) * EPI_pkg::ELEN) == 0)
//                    vec_el[i/EPI_pkg::ELEN] = vreg_if.wb_data[i +: EPI_pkg::ELEN];
//                else
//                    vec_el[i/EPI_pkg::ELEN] = '0;
//            end
//            return vec_el;
//        end
//        else if (`RENAMING_VIF.commit_vsew_i == SEW16) begin
//            for (int i = 0 ; i < EPI_pkg::MAX_VLEN; i = i + EPI_pkg::ELEN) begin
//                if (i == (((`RENAMING_VIF.commit_vlen_i - 1) * vsew_value) - (((`RENAMING_VIF.commit_vlen_i - 1)* vsew_value)%EPI_pkg::ELEN))) begin
//                    remaining_bits = ((`RENAMING_VIF.commit_vlen_i * vsew_value)%EPI_pkg::ELEN);
//
//                    if (!remaining_bits)
//                        vec_el[i/EPI_pkg::ELEN] = vreg_if.wb_data[i +: EPI_pkg::ELEN];
//                    else begin
//                        for (int j = 0; j < EPI_pkg::ELEN; j = j + vsew_value) begin
//                           if (j < remaining_bits)
//                               vec_el[i/EPI_pkg::ELEN][j +: 16] = vreg_if.wb_data[(i + j) +: 16];
//                        end
//                        continue;
//                    end
//                end
//                else if ((i < (`RENAMING_VIF.commit_vlen_i - 1) * vsew_value) || (`RENAMING_VIF.roll_back_vstart_o != 0) || ((`RENAMING_VIF.commit_vlen_i) * EPI_pkg::ELEN) == 0)
//                    vec_el[i/EPI_pkg::ELEN] = vreg_if.wb_data[i +: EPI_pkg::ELEN];
//                else
//                    vec_el[i/EPI_pkg::ELEN] = '0;
//            end
//            return vec_el;
//        end
//        else if (`RENAMING_VIF.commit_vsew_i == SEW32) begin
//            for (int i = 0 ; i < EPI_pkg::MAX_VLEN; i = i + EPI_pkg::ELEN) begin
//                if (i == (((`RENAMING_VIF.commit_vlen_i - 1)* vsew_value) - (((`RENAMING_VIF.commit_vlen_i - 1)* vsew_value)%EPI_pkg::ELEN))) begin
//                    remaining_bits = ((`RENAMING_VIF.commit_vlen_i * vsew_value)%EPI_pkg::ELEN);
//
//                    if (!remaining_bits)
//                        vec_el[i/EPI_pkg::ELEN] = vreg_if.wb_data[i +: EPI_pkg::ELEN];
//                    else begin
//                        for (int j = 0; j < EPI_pkg::ELEN; j = j + vsew_value) begin
//                           if (j < remaining_bits)
//                               vec_el[i/EPI_pkg::ELEN][j +: 32] = vreg_if.wb_data[(i + j) +: 32];
//                        end
//                        continue;
//                    end
//                end
//                else if ((i < (`RENAMING_VIF.commit_vlen_i - 1) * vsew_value) || (`RENAMING_VIF.roll_back_vstart_o != 0) || ((`RENAMING_VIF.commit_vlen_i) * EPI_pkg::ELEN) == 0)
//                    vec_el[i/EPI_pkg::ELEN] = vreg_if.wb_data[i +: EPI_pkg::ELEN];
//                else
//                    vec_el[i/EPI_pkg::ELEN] = '0;
//            end
//            return vec_el;
//        end
//        else if (`RENAMING_VIF.commit_vsew_i == SEW64) begin
//            for (int i = 0 ; i < EPI_pkg::MAX_VLEN; i = i + EPI_pkg::ELEN)
//                if ((i < (`RENAMING_VIF.commit_vlen_i) * EPI_pkg::ELEN) || (`RENAMING_VIF.roll_back_vstart_o != 0) || ((`RENAMING_VIF.commit_vlen_i) * EPI_pkg::ELEN) == 0)
//                    vec_el[i/EPI_pkg::ELEN] = vreg_if.wb_data[i +: EPI_pkg::ELEN];
//                else
//                    vec_el[i/EPI_pkg::ELEN] = 0;
//            return vec_el;
//        end
//    endfunction : retrieve_vpu_result

// ***This was at the oviProtocol.sv and we moved it here without actually testing/using this function
    // Function: retrieve_vpu_result
    // Accesses the vector register signal and creates a vec_els_t with the
    // content of the register
    virtual function vec_els_t retrieve_data(int vsew);
        vec_els_t vec_el;
        int remaining_bits;
        `uvm_info("oviProtocol:retrieve_data", $sformatf("vsew: %d commit_vl: %d rollback_vstart: %d is_nop: %d", vsew, `RENAMING_VIF.commit_vlen_i, `RENAMING_VIF.roll_back_vstart_o, `RENAMING_VIF.is_nop), UVM_HIGH)
        for (int i = 0 ; i < MAX_VLEN; i = i + ELEN) begin
            if (`RENAMING_VIF.commit_vlen_i * ELEN == 0) begin
                vec_el[i/ELEN] = (`RENAMING_VIF.is_nop) ? vreg_if.wb_data[i +: ELEN] : '1;
            end else if (i == (((`RENAMING_VIF.commit_vlen_i - 1) * vsew) - (((`RENAMING_VIF.commit_vlen_i - 1) * vsew)%ELEN))) begin
                remaining_bits = ((`RENAMING_VIF.commit_vlen_i * vsew)%ELEN);
                if (!remaining_bits)
                    vec_el[i/ELEN] = vreg_if.wb_data[i +: ELEN];
                else begin
                    for (int j = 0; j < ELEN; j = j + vsew) begin
                        if (j < remaining_bits)
                            for (int k = j; k <= j + vsew; ++k)
                                vec_el[i/ELEN][k] = vreg_if.wb_data[(i + k)];
                        else
                            for(int l = 0; l<= vsew; ++l)
                                vec_el[i/ELEN][j+l] = 1;
                    end
                    continue;
                end
            end else if ((i < (`RENAMING_VIF.commit_vlen_i - 1) * vsew) || (`RENAMING_VIF.roll_back_vstart_o != 0)) begin
                vec_el[i/ELEN] = vreg_if.wb_data[i +: ELEN]; end
            else begin
                vec_el[i/ELEN] = '1;
            end
        end
        return vec_el;
    endfunction : retrieve_data

    virtual function vec_els_t retrieve_vpu_result;

        case (`RENAMING_VIF.commit_vsew_i)
            SEW8:  return retrieve_data(8);
            SEW16: return retrieve_data(16);
            SEW32: return retrieve_data(32);
            SEW64: return retrieve_data(64);
        endcase
    endfunction : retrieve_vpu_result


    virtual function mask_els retrieve_vpu_mask();
        logic [MAX_VLEN/MIN_SEW-1:0] mask_d;
        for (int i = 0; i < MAX_VLEN/MIN_SEW; i++) begin
            mask_d[i] = mrf_if.mask_data[i];
        end
        `uvm_info("ovi_protocol", $sformatf("mask_d: %h ", mask_d), UVM_DEBUG)
        return mask_d;
    endfunction : retrieve_vpu_mask

    // Task: vstart_result
    // Contains a specific delay to tackle completed_vstart results
    // Must wait before commit signal goes down and up before retrieving the
    // vreg values
    virtual task vstart_result (input protocol_instr_t instr);

        wait(!restore_vstart_if.commit);
        wait(restore_vstart_if.commit);
        instr.vreg_data = retrieve_vpu_result();
        completed_protocol_instr.push_back(instr);

    endtask : vstart_result

    // Task: completed
    // Observes the completed subinterface and retrieves results, if necessary
    // enqueues the structures to be compared at the scoreboard and prepares
    // the instruction to be reissued, if applies.
    virtual task completed;
        dut_state_t m_dut_state;
        int masks_item;
        string vstart_msg = "";
        int masked_layout = 0;

        forever begin
            @(posedge `VIF.clk);
            if (`VIF.completed_valid) begin
                m_dut_state.rvv_state.vd = retrieve_vpu_result(); //infl_instr[0].vreg_data;
				m_dut_state.rvv_state.mask_data = retrieve_vpu_mask();
                m_dut_state.rvv_state.scalar_dest = `VIF.completed_dst_reg;
                m_dut_state.rvv_state.ignore = 0;
                m_dut_state.rvv_state.sb_id = `VIF.completed_sb_id;
                if( `VIF.completed_vstart == 0) begin
                    if (`VIF.completed_illegal) begin
                        `uvm_info("ovi_protocol", $sformatf("Ignoring instruction in Scoreboard due to illegal. Completed instruction with SB_ID: 0x%h\n", `VIF.completed_sb_id), UVM_HIGH)
                        m_dut_state.rvv_state.ignore = 1;
                    end
                    else begin
                        `uvm_info("ovi_protocol", $sformatf("Completed instruction SB_ID: %h wb_data[0] = %x mdata[0] = %x\n", `VIF.completed_sb_id, m_dut_state.rvv_state.vd[0], m_dut_state.rvv_state.mask_data[0 +: 64]), UVM_HIGH)
                        completed_instr.push_back(m_dut_state);
                    end
                end
            end
        end

    endtask : completed

    virtual task show_vreg;
        vec_els_t vreg;
        forever begin
            @(posedge `VIF.clk);
            vreg = retrieve_vpu_result();

            for (int i=0; i<30; i++) $display("time %t displaying pos %d %h", $time, i, vreg[i]);
        end

    endtask : show_vreg

    // Task: do_protocol
    // Runs the specific protocol of the interface to stimulate the DUT
    virtual task do_protocol;
        fork
            completed();
        join_none
    endtask : do_protocol

endclass : protocol
