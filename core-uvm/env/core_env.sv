//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_env 
// File          : core_env.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_env. This class instantiates the
//                 whole environment and create all main components here. 
//----------------------------------------------------------------------
`ifndef CORE_ENV_SV
`define CORE_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// Class: core_env
class core_env extends uvm_env;
    `uvm_component_utils(core_env)
    //  Group: Variables

    //  Variable: m_cfg
    core_env_cfg m_cfg;
    virtual interface csr_tohost_if m_tohost_if;
    virtual interface csr_clearmip_if m_clearmip_if;

    //  Variable: m_mem_model_wrapper
    core_mem_model#(64, 128) m_mem_model;

    //  Variable: m_iss_wrapper
    core_iss_wrapper m_iss;
    //  Variable: Instruction management unit
    core_im m_im;
    //  Variable: Instruction management agent
    core_im_agent m_im_agent;

    //  Variable Instruction management agent configuration
    core_im_agent_cfg m_im_agent_cfg;
    //  Variable: m_fifo
    uvm_tlm_fifo #(scoreboard_results_t) m_fifo;

    //  Variable: m_scoreboard
    core_scoreboard m_scoreboard;
    //  Variable: m_catcher
    core_catcher m_catcher;
    //  Variable: m_csr_monitor
    core_csr_monitor m_csr_monitor;

    //  Variable: core_int_agent
    //  Interrupt agent
    core_int_agent m_int_agent;

    //  Variable: core_icache_agent
    //  Instruction cache agent
    core_icache_agent m_icache_agent;

    //// Variable: core_dcache_agent
    //// Data cache agent
    core_dcache_agent m_dcache_agent;

    //// Variable: analysis_imp
    //// Callback of interrupts
    uvm_analysis_imp #(core_int_trans, core_env) analysis_imp;

    // Group: Functions
    // Function: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_imp = new("analysis_imp", this);
    endfunction : new

    // Function: build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // TODO replace with plusargs check?
        `ifdef OPENPITON_UVM
            m_cfg = core_env_cfg::type_id::create("m_cfg", this);
            m_cfg.is_cpu_ss = 1'b1;
        `endif
        // Else it is created in testbench, passed to here through the test
        m_im = core_im::type_id::create("m_im", this);
        m_im_agent = core_im_agent::type_id::create("m_im_agent", this);
        m_im_agent.m_cfg = m_cfg.imu_agent_cfg;

        m_iss = core_iss_wrapper::type_id::create("m_iss");
        m_im.m_iss = m_iss;
        m_mem_model = core_mem_model#(64, 128)::create_instance();
        m_mem_model.m_iss = m_iss;
        m_scoreboard = core_scoreboard::type_id::create("m_scoreboard", this);
        m_fifo = new("m_fifo", this);
        m_scoreboard.m_iss = m_iss;

        m_catcher = new();
        m_catcher.m_iss = m_iss;
        uvm_report_cb::add(null, m_catcher);
        m_im_agent.heartbeat_timeout = m_cfg.heartbeat_timeout;
        if (!uvm_config_db#(virtual csr_tohost_if)::get(this,"","csr_tohost_if", m_tohost_if))
            `uvm_fatal("CORE_ENV", "The virtual interface get failed for m_tohost_if");
        if (!uvm_config_db#(virtual csr_clearmip_if)::get(this,"","csr_clearmip_if", m_clearmip_if))
            `uvm_fatal("CORE_ENV", "The virtual interface get failed for m_clearmip_if");

        m_csr_monitor = core_csr_monitor::type_id::create("m_csr_monitor", this);

        m_int_agent = core_int_agent::type_id::create("m_int_agent", this);
        m_int_agent.m_cfg = m_cfg.int_cfg;
        m_int_agent.m_iss = m_iss;
        m_icache_agent = core_icache_agent::type_id::create("m_icache_agent", this);
        m_icache_agent.m_cfg = m_cfg.ic_cfg;
        m_icache_agent.m_iss = m_iss;
        m_dcache_agent = core_dcache_agent::type_id::create("m_dcache_agent", this);
        m_dcache_agent.m_cfg = m_cfg.dc_cfg;
        m_dcache_agent.m_iss = m_iss;
        if (m_cfg.is_cpu_ss) begin
            m_int_agent.m_cfg.active = UVM_ACTIVE;
            m_icache_agent.m_cfg.active = UVM_PASSIVE;
            m_dcache_agent.m_cfg.active = UVM_PASSIVE;
        end
    endfunction : build_phase

    // Function: connect_phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_scoreboard.m_results.connect(m_fifo.get_export);
        m_im.scoreboard_results.connect(m_fifo.put_export);
        `ifndef QUESTA_JTAG_VIP
            m_im_agent.completed_analysis_port.connect(m_im.completed_port);
            m_im_agent.fetch_analysis_port.connect(m_im.fetch_fifo.analysis_export);
        `endif
        m_im_agent.completed_analysis_port.connect(m_im.completed_port);
        m_im_agent.fetch_analysis_port.connect(m_im.fetch_fifo.analysis_export);
        m_im_agent.store_port.connect(m_im.store_fifo.analysis_export);
        m_int_agent.ap.connect(analysis_imp);
        //VPU
        m_csr_monitor.tohost_if = m_tohost_if;
        m_csr_monitor.clearmip_if = m_clearmip_if;
    endfunction : connect_phase

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        m_iss.setup();
    endfunction : start_of_simulation_phase

    // Function: mem_model_write
    function void mem_model_write(bit [63:0] addr, bit [7:0] data);
        m_mem_model.write_byte(addr, data);
    endfunction : mem_model_write

    // Function: mem_model_write
    function void mem_model_write_word(bit [63:0] addr, bit [31:0] data);
        m_mem_model.write(addr, data);
    endfunction : mem_model_write_word

    // Function: write
    virtual function void write(core_int_trans trans);
        //m_iss.set_interrupt(trans.interrupt_cause);
    endfunction : write

endclass : core_env

`endif


