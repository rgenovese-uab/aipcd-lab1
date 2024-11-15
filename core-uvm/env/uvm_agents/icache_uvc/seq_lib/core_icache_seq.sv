//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_icache_seq 
// File          : core_icache_seq.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence. This class 
//                 This class instantiates the icache sequence.
//----------------------------------------------------------------------
`ifndef CORE_ICACHE_SEQ_SV
    `define CORE_ICACHE_SEQ_SV

class core_icache_seq extends uvm_sequence;
    `uvm_object_utils(core_icache_seq)

    function new(string name = "core_icache_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        core_icache_rand_trans rand_trans;

        //repeat(50) begin
	    forever begin
            rand_trans = core_icache_rand_trans::type_id::create("tx", null);
            start_item(rand_trans);
            if (!rand_trans.randomize()) begin
                `uvm_fatal("BASE_TEST", "Could not randomize icache sequence")
            end
            finish_item(rand_trans);
        end
    endtask : body

endclass : core_icache_seq

`endif
