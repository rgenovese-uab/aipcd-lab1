//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : uvmt_pkg 
// File          : uvmt_pkg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is pakage file. This include all the dut related 
//                 necessary things for sync.
//----------------------------------------------------------------------
`ifndef UVMT_PKG
`define UVMT_PKG

package uvmt_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "top_tb_cfg.sv"

endpackage : uvmt_pkg

`endif
