//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dcache_trans
// File          : core_dcache_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence_item.
//                 This class instantiates the dcache transaction.
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_RAND_TRANS_SV
`define CORE_DCACHE_RAND_TRANS_SV

class core_dcache_rand_trans extends uvm_sequence_item;
    `uvm_object_utils(core_dcache_rand_trans)

    function new(string name = "core_dcache_rand_trans");
        super.new(name);
    endfunction : new

    rand int unsigned ttl;   // Cycles left to serve the request
    rand bit          error; // Decide wether or not to send error

    // TODO: Error sets the ttl to 0, may need to change due to implementations in the interface
    constraint c_ttl {
        solve error before ttl;
        if (error)
            ttl == 0;
        else {
            ttl dist {
                0 := 50,
                [1:53] := 50
            };
        }
    }

    // use this constraint to activate or deactivate the error bit
    constraint c_error {
        error dist {
            0 := 100,
            1 := 0
        };
    }

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
//        printer.print_dcache("dcache", dcache, $bits(dcache));
//        printer.print_dcache("dcache_cause", dcache_cause, $bits(dcache_cause));
    endfunction : do_print

endclass : core_dcache_rand_trans

`endif
