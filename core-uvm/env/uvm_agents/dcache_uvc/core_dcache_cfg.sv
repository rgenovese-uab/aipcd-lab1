//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dcache_cfg 
// File          : core_dcache_cfg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_object. 
//                 This class is common database of config_db for dcache. 
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_CFG_SV
`define CORE_DCACHE_CFG_SV

class core_dcache_cfg extends uvm_object;
    `uvm_object_utils(core_dcache_cfg)

    function new(string name = "");
        super.new(name);
    endfunction : new

    // Variable: active
    uvm_active_passive_enum active = UVM_ACTIVE;

endclass : core_dcache_cfg

`endif
