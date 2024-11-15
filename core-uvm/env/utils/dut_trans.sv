//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dut_trans 
// File          : core_dut_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_transaction. 
//                 This class instantiates the core_dut_trans transaction. 
//----------------------------------------------------------------------
`ifndef CORE_DUT_TRANS_SV
`define CORE_DUT_TRANS_SV

class core_dut_trans extends uvm_transaction;
    `uvm_object_utils(core_dut_trans)

    function new(string name = "core_dut_trans");
        super.new(name);
    endfunction : new

    dut_state_t dut_state [$];

endclass : core_dut_trans

`endif
