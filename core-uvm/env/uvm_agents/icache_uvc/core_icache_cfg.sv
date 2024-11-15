//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_icache_cfg 
// File          : core_icache_cfg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_object. 
//                 This class is common database of config_db for icache. 
//----------------------------------------------------------------------
`ifndef CORE_ICACHE_CFG_SV
`define CORE_ICACHE_CFG_SV

class core_icache_cfg extends uvm_object;
    `uvm_object_utils(core_icache_cfg)

    function new(string name = "");
        super.new(name);
    endfunction : new

    // Variable: active
    uvm_active_passive_enum active = UVM_ACTIVE;

endclass : core_icache_cfg

`endif
