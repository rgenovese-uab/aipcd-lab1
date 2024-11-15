`ifndef VPU_INS_TX_SV
`define VPU_INS_TX_SV

`include "uvm_macros.svh"

class vpu_ins_tx extends uvm_sequence_item;
    `uvm_object_utils(vpu_ins_tx)

    function new(string name = "vpu_ins_tx");
        super.new(name);
    endfunction : new

    rand core_uvm_types_pkg::iss_state_t iss_state;

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
            //printer.print_int("iss_state", iss_state, $bits(iss_state.instr));
    endfunction : do_print

endclass : vpu_ins_tx

`endif
