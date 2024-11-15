//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : test_harness 
// File          : test_harness.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is TOP Module which connect the DUT and interface 
//                 signals. This module is top testbench having test_harness module 
//                 which includes all TOP DUT (sargantana + CSR) Plus
//                 all necessary top connection with UVM Environment.
//----------------------------------------------------------------------
`ifndef TOP_TB_SV
`define TOP_TB_SV

import uvm_pkg::*;
import uvmt_pkg::*;
import sargantana_uvm_pkg::*;
`include "uvm_macros.svh"

// Module: top_tb
module top_tb;
    test_harness core_th();
    top_tb_cfg top_config;

    // Variable : timeout_cycles
    // Local parameter with the number of cycles to timeout the simulation
    localparam TIMEOUT_CYCLES = 40000;

    // Variable : cycles_wo_completed
    // Cycles without completed, used for detecting a simulation timeout
    int unsigned cycles_wo_completed;


    initial begin
        top_config = top_tb_cfg::type_id::create("top_config");

        uvm_config_db #(core_uvm_pkg::core_env_cfg)::set(null, "*", "top_cfg.env_cfg", top_config.env_cfg);

        uvm_config_db #(virtual int_if)::set(null, "*", "int_if", core_th.int_if);
        uvm_config_db #(virtual icache_if)::set(null, "*", "icache_if", core_th.ic_if);
        uvm_config_db #(virtual dcache_if)::set(null, "*", "dcache_if", core_th.dc_if);
        uvm_config_db #(virtual core_regfile_if)::set(null, "*", "reg_if", core_th.reg_if);
        uvm_config_db #(virtual core_fetch_if)::set(null, "*", "fetch_if", core_th.fetch_if);
        uvm_config_db #(virtual core_completed_if)::set(null, "*", "completed_if", core_th.completed_if);
        uvm_config_db #(virtual csr_tohost_if)::set(null, "*", "csr_tohost_if", core_th.tohost_if);
        uvm_config_db #(virtual csr_clearmip_if)::set(null, "*", "csr_clearmip_if", core_th.clearmip_if);

        run_test();
    end

    // Timeout logic to end the simulation when the core stalls
    initial begin
        cycles_wo_completed = 0;
    end

    always @(posedge core_th.clock_if.clk) begin
        logic any_valid;
        any_valid = 1'b0;
        for (int i = 0; i < dut_pkg::COMMIT_WIDTH; i++) begin
            any_valid |= core_th.completed_if.valid[i];
        end
        if (any_valid) begin
                cycles_wo_completed = 0;
        end else begin
                cycles_wo_completed++;

        end
        if (cycles_wo_completed == TIMEOUT_CYCLES) begin
            `uvm_fatal("top_tb", "Simulation timeout")
        end
    end
endmodule : top_tb

`endif
