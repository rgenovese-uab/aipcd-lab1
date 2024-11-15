`ifndef OVI_CFG_SV
`define OVI_CFG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import utils_pkg::*;

localparam MAX_PROB = 999;
localparam MAX_ISSUE_DELAY = 10;
localparam MAX_DISPATCH_DELAY = 10;
localparam MAX_MEMOP_DELAY = 10;
localparam MAX_LOAD_DELAY = 10;

class ovi_cfg extends uvm_object;
    `uvm_object_utils(ovi_cfg)

    rand loads_modes_t loads_mode;
    rand lines_modes_t lines_mode;
    rand int line_change_prob;
    rand exception_modes_t exception_mode;
    rand int exception_prob;

    rand drive_modes_t issue_mode;
    rand int issue_delay;
    rand drive_modes_t dispatch_mode;
    rand int dispatch_delay;
    rand drive_modes_t memop_mode;
    rand int memop_delay;
    rand drive_modes_t load_mode;
    rand int load_delay;

    rand credit_modes_t store_credit_mode;
    rand credit_modes_t mask_credit_mode;

    function new(string name = "ovi_cfg");
        super.new(name);
    endfunction : new

    constraint lc_prob_range { line_change_prob >= 0; line_change_prob < MAX_PROB; };
    constraint exc_prob_range { exception_prob >= 0; exception_prob < MAX_PROB; };
    constraint id_range { issue_delay > 0; issue_delay < MAX_ISSUE_DELAY; };
    constraint dd_range { dispatch_delay > 0; dispatch_delay < MAX_DISPATCH_DELAY; };
    constraint md_range { memop_delay > 0; memop_delay < MAX_MEMOP_DELAY; };
    constraint ld_range { load_delay > 0; load_delay < MAX_LOAD_DELAY; };
    
    // Function: do_print
    // Calls methods of printer in order to print all the configuration information.
    // This function is automatically executed by print function.
    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
        `uvm_info("ovi_cfg", "Printing OVI configuration", UVM_FULL)
        printer.print_string("loads_mode", load_mode.name());
        printer.print_string("lines_mode", lines_mode.name());
        printer.print_int("line_change_prob", line_change_prob, $bits(line_change_prob), UVM_DEC);
        printer.print_string("exception_mode", exception_mode.name());
        printer.print_int("exception_prob", exception_prob, $bits(exception_prob), UVM_DEC);
        printer.print_string("issue_mode", issue_mode.name());
        printer.print_int("dispatch_delay", issue_delay, $bits(issue_delay), UVM_DEC);
        printer.print_string("dispatch_mode", dispatch_mode.name());
        printer.print_int("dispatch_delay", dispatch_delay, $bits(dispatch_delay), UVM_DEC);
        printer.print_string("memop_mode", memop_mode.name());
        printer.print_int("memop_delay", memop_delay, $bits(memop_delay), UVM_DEC);
        printer.print_string("load_mode", load_mode.name());
        printer.print_int("load_delay", load_delay, $bits(load_delay), UVM_DEC);
        printer.print_string("store_credit_mode", store_credit_mode.name());
        printer.print_string("mask_credit_mode", mask_credit_mode.name());
    endfunction : do_print

endclass : ovi_cfg

`endif
