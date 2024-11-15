//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dcache_seq 
// File          : core_dcache_seq.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence. This class 
//                 This class instantiates the dcache sequence.
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_SEQ_SV
`define CORE_DCACHE_SEQ_SV

class core_dcache_seq extends uvm_sequence;
    `uvm_object_utils(core_dcache_seq)

    function new(string name = "core_dcache_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        core_dcache_rand_trans rand_trans;

        forever begin
            rand_trans = core_dcache_rand_trans::type_id::create("rand_trans", null);
            start_item(rand_trans);
            if (!rand_trans.randomize()) begin
                `uvm_fatal("CORE_DCACHE_SEQ", "Could not randomize dcache sequence")
            end
            `uvm_info("CORE_DCACHE_SEQ", $sformatf("Generated transaction with ttl %d", rand_trans.ttl), UVM_DEBUG)
            finish_item(rand_trans);
        end
    endtask : body

endclass : core_dcache_seq

`endif
