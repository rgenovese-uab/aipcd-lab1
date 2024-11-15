//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_base_test
// File          : core_base_test.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_test. This class instantiates the
//                 testcase is fully dedicated for specific data mentioned in sequence.
//                 Also override the spike.
//----------------------------------------------------------------------
`ifndef CORE_BASE_TEST_SV
`define CORE_BASE_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// Class: core_base_test
class core_base_test extends uvm_test;
    `uvm_component_utils(core_base_test)

    // Group: Variables

    // Variable: m_env
    // Handler to the UVM top environment.
    core_env m_env;

    // Variable: m_env_cfg
    // Handler to the configuration of the UVM top environment.
    core_env_cfg m_env_cfg;

    // Variable: enabled_tohost_sentinel
    bit enabled_mem_tohost_sentinel = 1;

    // Variable: enabled_csr_tohost_sentinel
    bit enabled_csr_tohost_sentinel = 1;

    // Variable: pool
    uvm_event_pool pool = uvm_event_pool::get_global_pool();

    // Variable: end_test_tohost
    uvm_event end_test_tohost = pool.get("end_test_tohost");

    // Variable: end_test_sentinel
    uvm_event end_test_sentinel = pool.get("end_test_sentinel");

    // Variable: end_csr_tohost
    uvm_event end_csr_tohost = pool.get("end_csr_tohost");

    // Group: Functions

    // Function: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Function: build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Set default sequence for the interrupt agent (depending on configuration?)
        // ................

        set_type_override_by_type(core_iss_wrapper::get_type(), core_spike::get_type());
        `uvm_info(get_type_name(),"Overriding ISS to Spike", UVM_LOW)

        // Set default sequence for the instruction sequence (generator/binary)
        // ....................

        if (!uvm_config_db #(core_env_cfg)::get(this, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end

        m_env = core_env::type_id:: create("m_env", this);
        m_env.m_cfg = m_env_cfg;

    endfunction : build_phase

    // Function: end_of_elaboration_phase
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    // Function: run_phase
    virtual task run_phase(uvm_phase phase);
        int mem_tohost_check, csr_tohost_check;
        core_int_seq seq;
        core_icache_seq icache_seq;
        core_dcache_seq dcache_seq;

        phase.raise_objection(this);
        mem_tohost_check = 0;
        csr_tohost_check = 0;

        seq = core_int_seq::type_id::create("seq");
        icache_seq = core_icache_seq::type_id::create("icache_seq");
        dcache_seq = core_dcache_seq::type_id::create("dcache_seq");

        if (enabled_mem_tohost_sentinel) begin
            fork
            begin
                end_test_tohost.wait_trigger;
                mem_tohost_check = 1;
                `uvm_info(get_type_name(), "UVM exiting, tohost memory position was written", UVM_LOW)
            end
            join_none
        end
        if (enabled_csr_tohost_sentinel) begin
            fork
            begin
                end_csr_tohost.wait_trigger;
                csr_tohost_check = 1;
                `uvm_info(get_type_name(), "UVM exiting, tohost CSR was written", UVM_LOW)
            end
            join_none
        end

        fork
        begin
            seq.start(m_env.m_int_agent.m_seqr);
        end
        begin
            icache_seq.start(m_env.m_icache_agent.m_seqr);
        end
        begin
            dcache_seq.start(m_env.m_dcache_agent.m_seqr);
        end
        join_none

        wait (mem_tohost_check == 1 || csr_tohost_check == 1);

        phase.drop_objection(this);
    endtask : run_phase

endclass : core_base_test

`endif
