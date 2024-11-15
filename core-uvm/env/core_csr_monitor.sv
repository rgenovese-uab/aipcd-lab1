//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_csr_monitor 
// File          : core_csr_monitor.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_monitor. This class instantiates the
//                 core_csr_monitor and also monitors and taken care of ending of test simulation.  
//----------------------------------------------------------------------
`ifndef CORE_CSR_MONITOR
`define CORE_CSR_MONITOR

// Class: core_csr_monitor
// Monitors if tohost signal is activated.
class core_csr_monitor extends uvm_monitor;
    `uvm_component_utils(core_csr_monitor)

    // Variable: tohost_if
    virtual interface csr_tohost_if tohost_if;

    virtual interface csr_clearmip_if clearmip_if;

    // Variable: pool
    // Pointer to global uvm_event_pool
    uvm_event_pool pool = uvm_event_pool::get_global_pool();

    // Variable: csr_tohost_event
    uvm_event csr_tohost_event = pool.get("end_csr_tohost");

    // Variable: csr_clearmip_event
    uvm_event csr_clearmip_event = pool.get("csr_clearmip");

    function new(string name = "core_csr_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        fork
            begin
                forever begin
                    @(posedge tohost_if.csr_tohost_valid);
                    csr_tohost_event.trigger();
                end
            end
            begin
                forever begin
                    @(posedge clearmip_if.csr_clearmip_valid)
                    csr_clearmip_event.trigger();
                end
            end
        join
    endtask : run_phase

endclass : core_csr_monitor

`endif

