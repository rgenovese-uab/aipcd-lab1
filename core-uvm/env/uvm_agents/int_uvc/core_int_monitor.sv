//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_int_monitor 
// File          : core_int_monitor.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_monitor. This class instantiates 
//                 the int monitor and also monitors the DUT's int data 
//                 from DUT through int_interface. 
//----------------------------------------------------------------------
`ifndef CORE_INT_MONITOR_SV
`define CORE_INT_MONITOR_SV

class core_int_monitor extends uvm_monitor;
    `uvm_component_utils(core_int_monitor)

    // Variable: m_cfg
    core_int_cfg m_cfg;

    // Variable: int_if
    virtual interface int_if int_if;

    // Variable: ap
    uvm_analysis_port #(core_int_trans) ap;

    function new(string name = "core_int_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        int_if.mon_proxy = this;
    endfunction : connect_phase

    function void notify_transaction(core_int_trans item);
        ap.write(item);
    endfunction : notify_transaction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        int_if.monitor();
    endtask : run_phase

endclass : core_int_monitor

`endif
