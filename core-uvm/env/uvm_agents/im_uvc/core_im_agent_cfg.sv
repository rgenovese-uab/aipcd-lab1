//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_im_agent_cfg 
// File          : core_im_agent_cfg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_object. 
//                 This class is common database of im_config_db. 
//----------------------------------------------------------------------
`ifndef CORE_IM_AGENT_CFG_SV
`define CORE_IM_AGENT_CFG_SV

class core_im_agent_cfg extends uvm_object;
    `uvm_object_utils(core_im_agent_cfg)

    function new(string name = "core_im_agent_cfg");
        super.new(name);
    endfunction : new

endclass : core_im_agent_cfg

`endif
