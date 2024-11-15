//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_int_trans 
// File          : core_int_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence_item. 
//                 This class instantiates the interrupt transaction.
//----------------------------------------------------------------------
`ifndef CORE_INT_TRANS_SV
`define CORE_INT_TRANS_SV

class core_int_trans extends uvm_sequence_item;

    function new(string name = "core_int_trans");
        super.new(name);
    endfunction : new

    localparam HIGHEST = 1;
    localparam LOWEST = 0;
    localparam PROB_INT = 2;
    localparam MAX_INT = 1;

    rand logic                  interrupt_dist;
    rand logic [64-1:0]         interrupt_cause;
    int                         prv_level;
    // TODO Change 255:1 in cpu-subsystem-uvm
    rand logic [HIGHEST:LOWEST] interrupt;

    `uvm_object_utils_begin(core_int_trans)
        `uvm_field_int( interrupt_dist, UVM_DEFAULT )
        `uvm_field_int( interrupt, UVM_DEFAULT )
        `uvm_field_int( interrupt_cause, UVM_DEFAULT )
    `uvm_object_utils_end

    // TODO use config variables for contraints
    // TODO PROV_INT if no interrupts

    constraint int_dist { interrupt_dist dist { 1:= PROB_INT, 0:= (100-PROB_INT)}; }
    constraint bef {solve interrupt_dist before interrupt; }
    // TODO: MAX_INTERRUPTS = 100 in cpu-subsystem
    constraint int_count { interrupt_dist -> $countones(interrupt) <= MAX_INT; }
    constraint int_no { !interrupt_dist -> $countones(interrupt) == 0; }
    constraint int_no_cause { !interrupt_dist -> interrupt_cause == 0; }
    constraint int_cause { interrupt_cause inside {[0:11]}; }

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_int("interrupt", interrupt, $bits(interrupt));
        printer.print_int("interrupt_cause", interrupt_cause, $bits(interrupt_cause));
    endfunction : do_print

endclass : core_int_trans

`endif
