//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : ka_env
// File          : ka_env.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_env. This class instantiates the
//                 whole environment and create all main components here.
//----------------------------------------------------------------------
`ifndef KA_ENV_SV
`define KA_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// Class: ka_env
class ka_env extends core_uvm_pkg::core_env;
    `uvm_component_utils(ka_env)

    //  Variable: m_fifo
    uvm_tlm_fifo #(core_uvm_pkg::scoreboard_results_t) m_vpu_fifo;
    uvm_tlm_fifo #(core_uvm_pkg::rvv_dut_tx) m_vpu_results_fifo;

    vpu_uvm_pkg::vpu_agent m_vpu_agent;

    // Group: Functions
    // Function: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Function: build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_vpu_fifo = new("m_vpu_fifo", this);
        m_vpu_results_fifo = new("m_vpu_results_fifo", this);
        //VPU integration
        m_vpu_agent = vpu_uvm_pkg::vpu_agent::type_id::create("m_vpu_agent", this);
    endfunction : build_phase

    // Function: connect_phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //VPU
        //to/from vpu_scoreboard
        m_im.vpu_scoreboard_results.connect(m_vpu_fifo.put_export);
        m_im.vpu_results_port.connect(m_vpu_results_fifo.get_export);
        m_vpu_agent.m_isa_scoreboard.m_results.connect(m_vpu_fifo.get_export);
        m_vpu_agent.m_monitor_post.dut_results_port.connect(m_vpu_results_fifo.put_export);
    endfunction : connect_phase

endclass : ka_env

`endif


