//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : ka_bin_test 
// File          : ka_bin_test.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from core_base_test. This class instantiates the
//                 testcase is fully dedicated for loading the memory_model with 
//                 specific binary data.  
//----------------------------------------------------------------------
`ifndef KA_BIN_TEST_SV
`define KA_BIN_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// Class ka_bin_test
class ka_bin_test extends core_uvm_pkg::core_bin_test;
    `uvm_component_utils(ka_bin_test)

    // Function: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Function: build_phase
    function void build_phase(uvm_phase phase);

        set_type_override_by_type(core_uvm_pkg::core_env::get_type(), ka_env::get_type());
        `uvm_info(get_type_name(),"Overriding core env with Ka env", UVM_LOW)

        // First override, then build. Else the environment has already been created
        super.build_phase(phase);
        set_type_override_by_type(core_uvm_pkg::core_iss_wrapper::get_type(), ka_spike::get_type());
        `uvm_info(get_type_name(),"Overriding ISS to Ka Spike", UVM_LOW)

        m_env.m_cfg.core_type = core_uvm_pkg::LAGARTO_KA;
        m_env.m_cfg.mtimecmp_offset = 'h4008;
    endfunction : build_phase

endclass : ka_bin_test

`endif
