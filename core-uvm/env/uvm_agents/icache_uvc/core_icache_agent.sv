//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_icache_agent 
// File          : core_icache_agent.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_agent. 
//                 This class instantiates the icache agent and its 
//                 UVC (Universal Verification Component) which is parent
//                 for all three sub-component like icache_driver, icache_sequencer
//                 and icache_monitor. 
//----------------------------------------------------------------------
`ifndef CORE_ICACHE_AGENT_SV
`define CORE_ICACHE_AGENT_SV

// Class: core_icache_agent
class core_icache_agent extends uvm_agent;
    `uvm_component_utils(core_icache_agent)

    // Variable: m_cfg
    core_icache_cfg m_cfg;

    // Variable: icache_if
    virtual interface icache_if ic_if;

    // Variable: m_monitor
    core_icache_monitor m_monitor;

    // Variable: m_driver
    core_icache_driver m_driver;

    // Variable: m_seqr
    core_icache_seqr m_seqr;

    core_iss_wrapper m_iss;

    uvm_tlm_analysis_fifo #(core_icache_trans) fifo_h1;   ////////////////////////////FIFO1

    function new(string name = "core_icache_agent", uvm_component parent);
        super.new(name, parent);
        fifo_h1 = new("fifo_h1", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_monitor = core_icache_monitor::type_id::create("m_monitor", this);
        m_monitor.m_cfg = m_cfg;
        if (m_cfg.active == UVM_ACTIVE) begin
            m_driver = core_icache_driver::type_id::create("m_driver", this);
            m_driver.m_cfg = m_cfg;
            m_driver.m_iss = m_iss;
            m_seqr = core_icache_seqr::type_id::create("core_icache_seqr", this);
        end
	    if (!uvm_config_db#(virtual icache_if)::get(this,"","icache_if", ic_if))
	        `uvm_fatal("CORE_ICACHE_AGENT", "The virtual interface get failed");
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (m_cfg.active == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_seqr.seq_item_export);
	        m_driver.ic_dr_if = ic_if;
            m_monitor.rd_dut_req_ap.connect(fifo_h1.analysis_export);
            m_driver.dut_req_ap.connect(fifo_h1.get_export);
        end
	    m_monitor.ic_mon_if = ic_if;
    endfunction : connect_phase

endclass : core_icache_agent

`endif
