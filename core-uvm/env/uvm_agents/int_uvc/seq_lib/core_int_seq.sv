//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_int_seq 
// File          : core_int_seq.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence. 
//                 This class instantiates the interrupt sequence.
//----------------------------------------------------------------------
`ifndef CORE_INT_SEQ_SV
`define CORE_INT_SEQ_SV

class core_int_seq extends uvm_sequence #(core_int_trans);
    `uvm_object_utils(core_int_seq)

    function new(string name = "core_int_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        core_int_trans trans;

        forever begin
            trans = core_int_trans::type_id::create("trans", null);
            start_item(trans);
            if (!trans.randomize()) begin
                `uvm_fatal("BASE_TEST", "Could not randomize interrupt sequence")
            end
            finish_item(trans);
        end
    endtask : body

endclass : core_int_seq

`endif
