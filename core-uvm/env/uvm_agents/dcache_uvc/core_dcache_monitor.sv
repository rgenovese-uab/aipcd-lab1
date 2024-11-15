//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dcache_monitor
// File          : core_dcache_monitor.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_monitor. This class instantiates 
//                 the dcache monitor and also monitors the DUT's dcache data 
//                 from DUT through dcache_interface.
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_MONITOR_SV
    `define CORE_DCACHE_MONITOR_SV

typedef struct {
    string     name;
    longint    addr;
    int        enable;
} watch_t;

import uvm_pkg::*;

class core_dcache_monitor extends uvm_monitor;
    `uvm_component_utils(core_dcache_monitor)

    function automatic hpdcache_pkg::hpdcache_req_addr_t hpdcache_req_addr(input hpdcache_pkg::hpdcache_req_t req);
        return {req.addr_tag, req.addr_offset};
    endfunction

    core_env_cfg m_env_cfg;
    // Variable: m_cfg
    core_dcache_cfg m_cfg;
    // Variable: dcache_if
    virtual interface dcache_if.DC_MON_CB dc_mon_if;

    // Variable: ap
    uvm_analysis_port #(core_dcache_trans) rd_dut_req_ap;

    uvm_event_pool pool = uvm_event_pool::get_global_pool();

    uvm_event end_test_tohost = pool.get("end_test_tohost");

    uvm_event iss_finished = pool.get("iss_finished");

    uvm_event test_clearmip_event = pool.get("test_clearmip");

    watch_t _test_exit;

    watch_t _clear_mip;

    core_iss_wrapper m_iss;

    function new(string name = "core_dcache_monitor", uvm_component parent);
        super.new(name, parent);
        rd_dut_req_ap = new("rd_dut_req_ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(core_env_cfg)::get(this, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end

    endfunction : build_phase

    // Get the address of a symbol in the binary
    function automatic void nm_get(string name_sym, ref watch_t watch);
        longint addr;
        if (get_symbol_addr(name_sym, addr)) begin
            `uvm_info("DCACHE_MONITOR", $sformatf("Symbol %s is being watched in addr %h", name_sym, addr), UVM_DEBUG)
            watch.addr = addr;
            watch.name = name_sym;
            watch.enable = 1;
        end
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // Get addresses for different symbols needed
        nm_get("_test_exit", _test_exit);
        nm_get("write_tohost", _test_exit);
        nm_get("tohost", _test_exit);
        nm_get("dv_clear_mip", _clear_mip);
    endfunction : end_of_elaboration_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            begin
                forever begin
                    monitor();
                end
            end
            begin
                if (_test_exit.enable)
                forever begin
                        check_tohost();
                end
            end
            begin
                if (_clear_mip.enable)
                forever begin
                        check_clear_mip();
                end
            end
        join_none
    endtask : run_phase

    task monitor();
        core_dcache_trans trans;
        @(dc_mon_if.dc_mon_cb) begin
            for (int i=0; i< HPDCACHE_NREQUESTERS; i++) begin
                trans = core_dcache_trans::type_id::create("trans");
                if (dc_mon_if.dc_mon_cb.dcache_req_valid[i]) begin
                    trans.dcache_req_valid =  dc_mon_if.dc_mon_cb.dcache_req_valid[i];
                    trans.dcache_req =  dc_mon_if.dc_mon_cb.dcache_req[i];
                    if (trans.dcache_req.op == HPDCACHE_REQ_LOAD) begin
                    `uvm_info("DCACHE_MONITOR",
                        $sformatf("Recieved load request from core, sending transaction to driver:\n\tsource-id: %h - addr: %h - op: %h ",  
                            trans.dcache_req.sid,
                            hpdcache_req_addr(trans.dcache_req),
                            trans.dcache_req.op),
                        UVM_DEBUG)
                    end else begin
                    `uvm_info("DCACHE_MONITOR",
                        $sformatf("Recieved store/amo request from core, sending transaction to driver:\n\tsource-id: %h - addr: %h data: %h be: %h - op: %h ",
                            trans.dcache_req.sid,
                            hpdcache_req_addr(trans.dcache_req),
                            trans.dcache_req.wdata,
                            trans.dcache_req.be,
                            trans.dcache_req.op),
                        UVM_DEBUG)
                    end
                    //---------------------------------------------------
                    // TODO: Get values from signals from HPDC to transacion
                    // Ex: trans.[signal] = dc_mon_if.dc_mon_cb.[signal];
                    //---------------------------------------------------
                    rd_dut_req_ap.write(trans);
                end
            end
        end
    endtask : monitor

    // Method to check if the tohost symbol has been written
    task check_tohost();
        //TODO: remove for loop as tohost write will always be at port 1 i.e. from core
        @(dc_mon_if.dc_mon_cb) begin
            for (int i=0; i< HPDCACHE_NREQUESTERS; i++) begin
                if (dc_mon_if.dc_mon_cb.dcache_req_valid[i] &&
                    hpdcache_req_addr(dc_mon_if.dc_mon_cb.dcache_req[i]) == _test_exit.addr &&
                    dc_mon_if.dc_mon_cb.dcache_req[i].op == 4'h1) begin
                    `uvm_info("DCACHE_MONITOR",
                        $sformatf("Detected write to tohost: addr = %h", _test_exit.addr),
                        UVM_DEBUG)
                    end_test_tohost.trigger();
                end
            end
        end
    endtask : check_tohost

    // Method to check if the clear_mip symbol has been written
    task check_clear_mip();
        //TODO: remove for loop as tohost write will always be at port 1 i.e. from core
        @(dc_mon_if.dc_mon_cb) begin
            for (int i=0; i< HPDCACHE_NREQUESTERS; i++) begin
                if (dc_mon_if.dc_mon_cb.dcache_req_valid[i] &&
                    hpdcache_req_addr(dc_mon_if.dc_mon_cb.dcache_req[i]) == _clear_mip.addr &&
                    dc_mon_if.dc_mon_cb.dcache_req[i].op == 4'h1) begin
                    `uvm_info("DCACHE_MONITOR",
                        $sformatf("Detected write to clear_mip: addr = %h", _clear_mip.addr),
                        UVM_HIGH)
                    if (!m_env_cfg.is_cpu_ss) begin
                        test_clearmip_event.trigger();
                    end
                end
            end
        end
    endtask : check_clear_mip

endclass : core_dcache_monitor

`endif


