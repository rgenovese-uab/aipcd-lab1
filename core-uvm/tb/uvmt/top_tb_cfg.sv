//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : top_tb_cfg 
// File          : top_tb_cfg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is TOP config class having configurations which 
//                 can connect the DUT and interface signals. 
//----------------------------------------------------------------------
`ifndef TOP_TB_CFG_SV
`define TOP_TB_CFG_SV

import core_uvm_pkg::*;

class top_tb_cfg extends uvm_object;
    `uvm_object_utils(top_tb_cfg)

    core_env_cfg env_cfg;

    function new(string name = "top_tb_cfg");
        super.new(name);
        env_cfg = core_env_cfg::type_id::create("env_cfg");
    endfunction : new

endclass : top_tb_cfg

`endif
