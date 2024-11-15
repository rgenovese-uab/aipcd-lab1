//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dcache_agent 
// File          : core_dcache_agent.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_agent. 
//                 This class instantiates the dcache agent and its 
//                 UVC (Universal Verification Component) which is parent
//                 for all three sub-component like dcache_driver, dcache_sequencer
//                 and dcache_monitor. 
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_AGENT_SV
`define CORE_DCACHE_AGENT_SV

// Class: core_dcache_agent
class core_dcache_agent extends uvm_agent;
    `uvm_component_utils(core_dcache_agent)

    // Variable: m_cfg
    core_dcache_cfg m_cfg;

    // Variable: m_monitor
    core_dcache_monitor m_monitor;
    // Variable: m_driver
    core_dcache_driver m_driver;

    // Variable: m_seqr
    core_dcache_seqr m_seqr;

    // Variable: dcache_if
    virtual interface dcache_if dc_if;

    // Variable: ap
    uvm_tlm_analysis_fifo #(core_dcache_trans) fifo_h1;

    core_iss_wrapper m_iss;

    function new(string name = "core_dcache_agent", uvm_component parent);
        super.new(name, parent);
        fifo_h1 = new("fifo_h1", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_monitor = core_dcache_monitor::type_id::create("m_monitor", this);
        m_monitor.m_cfg = m_cfg;
        m_monitor.m_iss = m_iss;
        if (m_cfg.active == UVM_ACTIVE) begin
            m_driver = core_dcache_driver::type_id::create("m_driver", this);
            m_driver.m_cfg = m_cfg;
            m_driver.m_iss = m_iss;
            m_seqr = core_dcache_seqr::type_id::create("core_dcache_seqr", this);
        end
        if (!uvm_config_db#(virtual dcache_if)::get(this,"","dcache_if", dc_if))
            `uvm_fatal("CORE_DCACHE_AGENT", "The virtual interface get failed");
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (m_cfg.active == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_seqr.seq_item_export);
            m_driver.dc_dr_if = dc_if;
            m_driver.dcache_ref.dc_dr_if = dc_if;
            m_monitor.rd_dut_req_ap.connect(fifo_h1.analysis_export);
            m_driver.dut_req_ap.connect(fifo_h1.get_export);
        end
        m_monitor.dc_mon_if = dc_if;
    endfunction : connect_phase

endclass : core_dcache_agent

`endif
