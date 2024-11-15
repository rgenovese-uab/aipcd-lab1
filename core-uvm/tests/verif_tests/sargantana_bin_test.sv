//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : sargantana_bin_test
// File          : sargantana_bin_test.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_test. This class instantiates the
//                 testcase is fully dedicated for specific data mentioned in sequence.
//                 Also override the spike.
//----------------------------------------------------------------------
`ifndef SARGANTANA_BIN_TEST_SV
`define SARGANTANA_BIN_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import sargantana_uvm_pkg::*;

// Class: sargantana_bin_test
class sargantana_bin_test extends core_uvm_pkg::core_bin_test;
    `uvm_component_utils(sargantana_bin_test)

    // Function: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Function: build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        set_type_override_by_type(core_uvm_pkg::core_iss_wrapper::get_type(), sargantana_spike::get_type());
        `uvm_info(get_type_name(),"Overriding ISS to Sargantana Spike", UVM_LOW)

        set_type_override_by_type(core_uvm_pkg::core_env::get_type(), sargantana_env::get_type());
        `uvm_info(get_type_name(),"Overriding core env with Sargantana env", UVM_LOW)

        m_env.m_cfg.core_type = core_uvm_pkg::SARGANTANA;
        m_env.m_cfg.mtimecmp_offset = 'h4000;
    endfunction : build_phase

endclass : sargantana_bin_test

`endif
