//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_int_cfg 
// File          : core_int_cfg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_object. 
//                 This class is common database of config_db for interrupt. 
//----------------------------------------------------------------------
`ifndef CORE_INT_CFG_SV
`define CORE_INT_CFG_SV

class core_int_cfg extends uvm_object;
    `uvm_object_utils(core_int_cfg)

    function new(string name = "");
        super.new(name);
    endfunction : new

    // Variable: active
    uvm_active_passive_enum active = UVM_ACTIVE;

endclass : core_int_cfg

`endif
