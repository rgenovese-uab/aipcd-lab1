//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_fetch_monitor 
// File          : core_fetch_monitor.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_monitor. This class instantiates 
//                 the fetch_monitor and also monitors the core's mapper module for 
//                 fetched instructions and program counters. And
//                 Sends these to the instruction manager.
//----------------------------------------------------------------------
`ifndef CORE_FETCH_MONITOR
`define CORE_FETCH_MONITOR

class core_fetch_monitor extends uvm_monitor;
    `uvm_component_utils (core_fetch_monitor)

    // Variable: vif
    // Instruction start virtual interface
    virtual interface core_fetch_if vif;

    // Variable: analysis_port
    // Analysis port connecting fetch monitor with Instruction Management Module
    uvm_analysis_port #(core_fetch_trans) analysis_port;

    // Variable: m_fetch_p0
     core_fetch_trans m_fetch, m_fetch_p0, m_fetch_p1;

    // Variable heartbeat_objection
    uvm_callbacks_objection heartbeat_objection;

    core_env_cfg m_env_cfg;

    // Variable pool
    // Pointer to global uvm_event_pool
    uvm_event_pool pool = uvm_event_pool::get_global_pool();
    uvm_event iss_finished = pool.get("iss_finished");

    function new(string name = "core_fetch_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env_cfg = new();
        if (!uvm_config_db #(core_env_cfg)::get(this, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (m_env_cfg.core_type == core_uvm_pkg::SARGANTANA) begin
                if (vif.fetch_valid) begin
                    m_fetch = core_fetch_trans::type_id::create("m_fetch");
                    m_fetch.fetch_pc = vif.fetch_pc;
                    m_fetch.decode_pc = vif.decode_pc;
                    m_fetch.fetch_valid = vif.fetch_valid;
                    m_fetch.decode_valid = vif.decode_valid;
                    m_fetch.decode_is_illegal = vif.decode_is_illegal;
                    m_fetch.decode_is_compressed = vif.decode_is_compressed;
                    m_fetch.invalidate_icache_int = vif.invalidate_icache_int;
                    m_fetch.invalidate_buffer_int = vif.invalidate_buffer_int;
                    m_fetch.retry_fetch = vif.retry_fetch;
                    `uvm_info(get_type_name(), $sformatf("Fetch pc: %h m_fetch: %p", vif.fetch_pc, m_fetch), UVM_DEBUG)
                    analysis_port.write(m_fetch);
                end
            end else if (m_env_cfg.core_type == core_uvm_pkg::LAGARTO_KA) begin // TODO Unify
                if (vif.mapper_id_inst_valid) begin
                    m_fetch_p0 = core_fetch_trans::type_id::create("m_fetch");
                    m_fetch_p1 = core_fetch_trans::type_id::create("m_fetch");

                    // Check if p0 has a valid instr
                    if (vif.mapper_id_inst_valid[0]) begin
                        m_fetch_p0.mapper_id_inst = vif.mapper_id_inst_p0;
                        m_fetch_p0.mapper_id_pc   = vif.mapper_id_pc_p0;
                        m_fetch_p0.is_branch      = vif.mapper_disp_branch_p0;
                        m_fetch_p0.rob_entry      = vif.rob_new_entry_p0;
                        `uvm_info(get_type_name(), $sformatf("Pushing fetch p0: %h instr %h", m_fetch_p0.mapper_id_pc, m_fetch_p0.mapper_id_inst), UVM_HIGH)
                        analysis_port.write(m_fetch_p0);
                    end

                    // Check if p1 has a valid instr
                    if (vif.mapper_id_inst_valid[1]) begin
                        m_fetch_p1.mapper_id_inst = vif.mapper_id_inst_p1;
                        m_fetch_p1.mapper_id_pc   = vif.mapper_id_pc_p1;
                        m_fetch_p1.is_branch      = vif.mapper_disp_branch_p1;
                        m_fetch_p1.rob_entry      = vif.rob_new_entry_p1;
                        `uvm_info(get_type_name(), $sformatf("Pushing fetch p1: %h instr %h", m_fetch_p1.mapper_id_pc, m_fetch_p1.mapper_id_inst), UVM_HIGH)
                        analysis_port.write(m_fetch_p1);
                    end
                end
            end
            if (iss_finished.is_on()) begin
                break;
            end
        end
    endtask : run_phase

endclass

`endif
