//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_iss_trans 
// File          : core_iss_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_transaction. 
//                 This class instantiates the core_iss_trans transaction. 
//----------------------------------------------------------------------
`ifndef CORE_ISS_TRANS_SV
`define CORE_ISS_TRANS_SV

class core_iss_trans extends uvm_transaction;
    `uvm_object_utils(core_iss_trans)

    function new(string name = "core_iss_trans");
        super.new(name);
    endfunction : new

    iss_scalar_state_t iss_state [$];

endclass : core_iss_trans

`endif


