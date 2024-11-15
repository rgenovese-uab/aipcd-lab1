//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : ka_uvm_pkg
// File          : ka_uvm_pkg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This is pakage file. This include all the env file
//                 necessary for sync. Also In pkg file order must be maintain
//                 in "bottom to top manner" otherwise errors will be there.
//----------------------------------------------------------------------
`ifndef KA_UVM_PKG
`define KA_UVM_PKG

package ka_uvm_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import dut_pkg::*;

    `include "ref_model/ka_spike.sv"

    `include "ka_env.sv"
    `include "../tests/verif_tests/ka_bin_test.sv"

endpackage : ka_uvm_pkg

`endif
