//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_int_agent 
// File          : core_int_agent.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_agent. 
//                 This class instantiates the int agent and its 
//                 UVC (Universal Verification Component) which is parent
//                 for all three sub-component like int_driver, int_sequencer
//                 and int_monitor. 
//----------------------------------------------------------------------
`ifndef CORE_INT_AGENT_SV
`define CORE_INT_AGENT_SV

// Class: core_int_agent
class core_int_agent extends uvm_agent;
    `uvm_component_utils(core_int_agent)

    // Variable: m_cfg
    core_int_cfg m_cfg;

    // Variable: int_if
    virtual interface int_if int_if;

    // Variable: m_monitor
    core_int_monitor m_monitor;

    // Variable: m_driver
    core_int_driver m_driver;

    // Variable: m_seqr
    core_int_seqr m_seqr;

    core_iss_wrapper m_iss;

    // Variable: ap
    uvm_analysis_port #(core_int_trans) ap;

    function new(string name = "core_int_agent", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual int_if)::get(null,"","int_if", int_if))
            `uvm_fatal("CORE_INT_AGENT", "The virtual interface get failed");

        int_if.setup();
        m_monitor = core_int_monitor::type_id::create("m_monitor", this);
        m_monitor.m_cfg = m_cfg;
        m_monitor.int_if = int_if;

        if (m_cfg.active == UVM_ACTIVE) begin
            m_driver = core_int_driver::type_id::create("m_driver", this);
            m_driver.m_cfg = m_cfg;
            m_driver.m_iss = m_iss;
            m_seqr = core_int_seqr::type_id::create("core_int_seqr", this);
        end
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_monitor.ap.connect(ap);

        if (m_cfg.active == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_seqr.seq_item_export);
            m_driver.int_if = int_if;
        end

    endfunction : connect_phase

endclass : core_int_agent

`endif
