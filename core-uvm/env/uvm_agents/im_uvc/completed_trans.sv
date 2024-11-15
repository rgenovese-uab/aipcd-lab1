//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_completed_trans 
// File          : core_completed_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_transaction. 
//                 This class instantiates the core_completed_trans transaction. 
//----------------------------------------------------------------------
`ifndef CORE_COMPLETED_TRANS
`define CORE_COMPLETED_TRANS

class core_completed_trans extends uvm_transaction;

        // TODO Polymorphism
        uint64_t pc;
        uint64_t pdest;
        logic dest_valid;
        uint64_t result;
        uint64_t instr; // 32?
        logic xcpt;
        logic [63:0] xcpt_cause;
        // Sargantana
        logic    commit_branchTaken;
        vec_els_t vd;
        // Lagarto Ka
        uint64_t stored_value;
        logic fault;
        logic ext_intr;
        logic timer_intr;
        logic sw_intr;
        logic [6:0] rob_entry_miss;
        logic [6:0] rob_head;

    `uvm_object_utils_begin(core_completed_trans)
            `uvm_field_int(pc, UVM_ALL_ON)
            `uvm_field_int(result, UVM_ALL_ON)
            `uvm_field_int(instr, UVM_ALL_ON)
            `uvm_field_int(xcpt_cause, UVM_ALL_ON)
            `uvm_field_int(dest_valid, UVM_ALL_ON)
            `uvm_field_int(pdest, UVM_ALL_ON)
            `uvm_field_int(commit_branchTaken, UVM_ALL_ON)
            `uvm_field_int(xcpt, UVM_ALL_ON)
            `uvm_field_int(fault, UVM_ALL_ON)
            `uvm_field_int(ext_intr, UVM_ALL_ON)
            `uvm_field_int(timer_intr, UVM_ALL_ON)
            `uvm_field_int(sw_intr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "core_completed_trans");
        super.new(name);
    endfunction : new

endclass : core_completed_trans

`endif
