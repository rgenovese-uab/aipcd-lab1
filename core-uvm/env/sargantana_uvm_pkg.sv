//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : sargantana_uvm_pkg
// File          : sargantana_uvm_pkg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This is pakage file. This include all the env file
//                 necessary for sync. Also In pkg file order must be maintain
//                 in "bottom to top manner" otherwise errors will be there.
//----------------------------------------------------------------------
`ifndef SARGANTANA_UVM_PKG
`define SARGANTANA_UVM_PKG

package sargantana_uvm_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import dut_pkg::*;

    `include "ref_model/sargantana_spike.sv"

    `include "sargantana_env.sv"
    `include "../tests/verif_tests/sargantana_bin_test.sv"

endpackage : sargantana_uvm_pkg

`endif
