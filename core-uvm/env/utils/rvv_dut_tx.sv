`ifndef RVV_DUT_TX_SV
`define RVV_DUT_TX_SV

class rvv_dut_tx extends uvm_sequence_item;
    `uvm_object_utils(rvv_dut_tx)

    function new(string name = "rvv_dut_tx");
        super.new(name);
    endfunction : new

    core_uvm_types_pkg::dut_state_t dut_state;

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
            //printer.print_int("iss_state", iss_state, $bits(iss_state.instr));
    endfunction : do_print

endclass : rvv_dut_tx

`endif
