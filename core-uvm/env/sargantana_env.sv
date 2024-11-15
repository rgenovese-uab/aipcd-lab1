//----------------------------------------------------------------------
// Project       : standalone_sargantana_dv_env
// Unit          : sargantana_env 
// File          : sargantana_env.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_env. This class instantiates the
//                 whole environment and create all main components here. 
//----------------------------------------------------------------------
`ifndef SARGANTANA_ENV_SV
`define SARGANTANA_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// Class: sargantana_env
class sargantana_env extends core_uvm_pkg::core_env;
    `uvm_component_utils(sargantana_env)
    //  Group: Variables

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Function: build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // TODO factory replacement?
    endfunction : build_phase

endclass : sargantana_env

`endif


