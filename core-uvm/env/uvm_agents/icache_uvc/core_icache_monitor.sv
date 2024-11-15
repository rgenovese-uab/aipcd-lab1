//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_icache_monitor 
// File          : core_icache_monitor.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_monitor. This class instantiates 
//                 the icache monitor and also monitors the DUT's icache data 
//                 from DUT through icache_interface. 
//----------------------------------------------------------------------
`ifndef CORE_ICACHE_MONITOR_SV
`define CORE_ICACHE_MONITOR_SV

class core_icache_monitor extends uvm_monitor;
    `uvm_component_utils(core_icache_monitor)

    // Variable: m_cfg
    core_icache_cfg m_cfg;

    // Variable: icache_if
    virtual interface icache_if.IC_MON_MP ic_mon_if;

    // Variable: rd_dut_req_ap
    uvm_analysis_port #(core_icache_trans) rd_dut_req_ap; // for driver to know the request situations..

    function new(string name = "core_icache_monitor", uvm_component parent);
        super.new(name, parent);
        rd_dut_req_ap = new("rd_dut_req_ap", this); // for driver to know the request situations..
    endfunction : new

    function void build_phase(uvm_phase phase);
	    super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            monitor();
        end
    endtask : run_phase


    task monitor();
        core_icache_trans item;
        @(ic_mon_if.ic_mon_cb) begin // recording first cycle logic of ready signal from icache to core
            if (ic_mon_if.ic_mon_cb.lagarto_ireq.valid) begin
                item = core_icache_trans::type_id::create("item");
                item.lagarto_ireq.valid = ic_mon_if.ic_mon_cb.lagarto_ireq.valid;
                item.lagarto_ireq.kill = ic_mon_if.ic_mon_cb.lagarto_ireq.kill;
                item.lagarto_ireq.idx = ic_mon_if.ic_mon_cb.lagarto_ireq.idx;
                item.lagarto_ireq.vpn = ic_mon_if.ic_mon_cb.lagarto_ireq.vpn;
                item.csr_en_translation = ic_mon_if.ic_mon_cb.csr_en_translation;
                item.csr_status = ic_mon_if.ic_mon_cb.csr_status;
                item.csr_satp = ic_mon_if.ic_mon_cb.csr_satp;
                item.csr_priv_lvl = ic_mon_if.ic_mon_cb.csr_priv_lvl;
                `uvm_info("ICACHE_MONITOR", $sformatf("idx: %h, vpn: %h - Received icache condition transaction, recording stimulus for driver",item.lagarto_ireq.idx, item.lagarto_ireq.vpn), UVM_DEBUG)
                rd_dut_req_ap.write(item);
            end
        end
    endtask : monitor

endclass : core_icache_monitor

`endif
