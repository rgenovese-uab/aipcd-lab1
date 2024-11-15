//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_fetch_trans 
// File          : core_fetch_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_transaction. 
//                 This class instantiates the core_fetch_trans transaction. 
//----------------------------------------------------------------------
`ifndef CORE_FETCH_TRANS
`define CORE_FETCH_TRANS

class core_fetch_trans extends uvm_transaction;
    function new(string name = "core_fetch_trans");
        super.new(name);
    endfunction : new
    
        // TODO: polymorphism
        // Sargantana
        logic [63:0]    fetch_pc;
        logic [63:0]    decode_pc;
        logic           fetch_valid;
        logic           decode_valid;
        logic           decode_is_illegal;
        logic           decode_is_compressed;
        logic           invalidate_icache_int;
        logic           invalidate_buffer_int;
        logic           retry_fetch;
        // Ka
        uint64_t    mapper_id_inst;
        uint64_t    mapper_id_pc;
        logic [6:0] rob_entry;
        logic       is_branch;
    
    `uvm_object_utils_begin(core_fetch_trans)
            `uvm_field_int(fetch_pc, UVM_ALL_ON)
            `uvm_field_int(decode_pc, UVM_ALL_ON)
            `uvm_field_int(fetch_valid, UVM_ALL_ON)
            `uvm_field_int(decode_valid, UVM_ALL_ON)
            `uvm_field_int(decode_is_illegal, UVM_ALL_ON)
            `uvm_field_int(decode_is_compressed, UVM_ALL_ON)
            `uvm_field_int(invalidate_icache_int, UVM_ALL_ON)
            `uvm_field_int(invalidate_buffer_int, UVM_ALL_ON)
            `uvm_field_int(retry_fetch, UVM_ALL_ON)
            `uvm_field_int(mapper_id_inst, UVM_ALL_ON)
            `uvm_field_int(mapper_id_pc, UVM_ALL_ON)
            `uvm_field_int(rob_entry, UVM_ALL_ON)
            `uvm_field_int(is_branch, UVM_ALL_ON)
    `uvm_object_utils_end
endclass : core_fetch_trans

`endif
