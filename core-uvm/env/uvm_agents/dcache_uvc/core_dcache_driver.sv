//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dcache_driver 
// File          : core_dcache_driver.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_driver. This class instantiates 
//                 the dcache driver and also drives the dcache_sequence's data 
//                 from dcache_sequencer to DUT through dcache_interface. 
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_DRIVER_SV
`define CORE_DCACHE_DRIVER_SV

class core_dcache_driver extends uvm_driver #(core_dcache_rand_trans);
    `uvm_component_utils(core_dcache_driver)

    // Variable: m_cfg
    core_dcache_cfg m_cfg;

    // Variable: dcache_if
    virtual interface dcache_if dc_dr_if;

    // Variable: dut_req_ap
    uvm_blocking_get_port #(core_dcache_trans) dut_req_ap;


    // Variable: trans
    core_dcache_trans trans;
    // Variable: rand_trans
    core_dcache_rand_trans rand_trans;
    // Variable: dcache_ref
    core_dcache_ref_model dcache_ref;
    // Variable: m_iss
    core_iss_wrapper m_iss;

    function new(string name = "core_dcache_driver", uvm_component parent);
        super.new(name, parent);
        dut_req_ap = new("dut_req_ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        `uvm_info("DCACHE_DRIVER", "Creating dcache reference model.", UVM_DEBUG)
        super.build_phase(phase);
        dcache_ref = core_dcache_ref_model::type_id::create("dcache_ref", this);
        dcache_ref.m_iss = m_iss;
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            // Get request block
            begin
                forever begin
                    `uvm_info("DCACHE_DRIVER", "Waiting for next request item.", UVM_DEBUG)
                    seq_item_port.get_next_item(rand_trans); // Get random transaction
                    dut_req_ap.get(trans); // Get next transaction from the monitor
                    dcache_ref.request(rand_trans, trans); // Send the request to the reference model
                    seq_item_port.item_done();
                end
            end
            // Drive block
            begin
                forever begin
                    @(posedge dc_dr_if.clk) begin
                        if (!dc_dr_if.rsn) begin
                            dcache_ref.rst_signals();
                        end
                        else begin
                            dcache_ref.set_signals();
                            dcache_ref.check_requests();
                        end
                        dcache_ref.drive_signals();
                    end
                end
            end
        join_none
    endtask : run_phase

endclass : core_dcache_driver

`endif
