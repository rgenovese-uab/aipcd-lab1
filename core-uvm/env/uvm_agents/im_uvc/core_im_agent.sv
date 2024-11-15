//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_im_agent 
// File          : core_im_agent.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_agent. 
//                 This class instantiates the im agent and its 
//                 UVC (Universal Verification Component) which is parent
//                 for all sub-component like fetch_monitor and completed_monitor. 
//----------------------------------------------------------------------
`ifndef CORE_IM_AGENT_SV
`define CORE_IM_AGENT_SV

// Instruction management agent
class core_im_agent extends uvm_agent;
`uvm_component_utils(core_im_agent)

    // Variable: m_cfg
    core_im_agent_cfg m_cfg;

    // Variable: vif
    virtual interface core_fetch_if fetch_if;
    virtual interface core_regfile_if reg_if;
    virtual interface core_completed_if completed_if;
    // Variable: fetch_monitor
    core_fetch_monitor fetch_monitor;
    // Variable: completed_monitor
    core_completed_monitor completed_monitor;
    // Variable: hb_event
    uvm_event hb_event;

    // Variable: hb
    uvm_heartbeat hb;

    // Variable: heartbeat_objection
    uvm_callbacks_objection heartbeat_objection;

    // Variable: heartbeat_timeout
    int heartbeat_timeout;

    // Variable: hb_comps
    // List mantaining components to monitor in heartbeat
    uvm_component hb_comps[$];

    uvm_analysis_port #(core_fetch_trans) fetch_analysis_port;
    uvm_analysis_port #(core_completed_trans) completed_analysis_port;
    uvm_analysis_port #(core_store_trans) store_port;

    function new(string name = "core_im_agent", uvm_component parent);
        super.new(name,parent);
        fetch_analysis_port = new("fetch_analysis_port", this);
        completed_analysis_port = new("completed_analysis_port", this);
        store_port = new("store_port", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fetch_monitor = core_fetch_monitor::type_id::create("fetch_monitor", this);
        completed_monitor = core_completed_monitor::type_id::create("completed_monitor", this);
        // Heartbeat mechanism configuration
        heartbeat_objection = new("heartbeat_objection");
        hb_event = new("hb_event");
        hb = new("hb", this, heartbeat_objection);
        void'(hb.set_mode(UVM_ALL_ACTIVE));
        hb.set_heartbeat(hb_event, hb_comps);
        hb.add(fetch_monitor);
        hb.add(completed_monitor);

        fetch_monitor.heartbeat_objection = this.heartbeat_objection;
        completed_monitor.heartbeat_objection = this.heartbeat_objection;

        if (!uvm_config_db#(virtual core_regfile_if)::get(this,"","reg_if", reg_if))
            `uvm_fatal("RAM_READ_AGENT", "reg_if - The virtual interface get failed");
        if (!uvm_config_db#(virtual core_fetch_if)::get(this,"","fetch_if", fetch_if))
            `uvm_fatal("RAM_READ_AGENT", "fetch_if - The virtual interface get failed");
        if (!uvm_config_db#(virtual core_completed_if)::get(this,"","completed_if", completed_if))
            `uvm_fatal("RAM_READ_AGENT", "completed_if - The virtual interface get failed");
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        fetch_monitor.analysis_port.connect(fetch_analysis_port);
        completed_monitor.analysis_port.connect(completed_analysis_port);
        completed_monitor.store_port.connect(store_port);

        fetch_monitor.vif = fetch_if;
        completed_monitor.completed_vif = completed_if;
        completed_monitor.reg_vif = reg_if;
    endfunction : connect_phase

    // Task: run_phase
    virtual task run_phase(uvm_phase phase);
    endtask : run_phase

endclass

`endif


