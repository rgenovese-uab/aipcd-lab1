//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_spike 
// File          : core_spike.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is core_spike class extended from core_iss_wrapper. 
//                 Providing Spike as reference model.
//----------------------------------------------------------------------
`ifndef SARGANTANA_SPIKE_SV
`define SARGANTANA_SPIKE_SV

class sargantana_spike extends core_uvm_pkg::core_spike;
    `uvm_object_utils(sargantana_spike)


    function new(string name = "sargantana_spike");
        super.new(name);
    endfunction : new

    virtual function void setup();
        vlen = riscv_pkg::VLEN; // TODO: get from dut_pkg
        isa = "RV64IMAFDVSscofpmf";
        core_type = "SARGANTANA";
        super.setup();
    endfunction : setup


endclass : sargantana_spike

`endif


