//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : interface 
// File          : interface.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This file include all interfaces required to communicate 
//                 with DUT.
//----------------------------------------------------------------------
`ifndef CORE_INTERFACE_SV
`define CORE_INTERFACE_SV

import dut_pkg::*;
import core_uvm_pkg::*;
import core_uvm_types_pkg::*;
// Interface: clock_if
// Clock Interface
interface clock_if;
    logic clk;
    logic rsn;

    // Cycle counter for performance counters
    longint unsigned cycles = 0;

    initial begin
        clk = 1'b0;
        cycles = 0;
        forever #1 clk = ~clk;
    end

endinterface : clock_if

// Interface: reset_if
// Reset Interface
interface reset_if;

    // Variable: clk
    logic clk;

    // Variable: rsn
    logic rsn;

    // Task : wait_for_reset_start
    task automatic wait_for_reset_start();
        @(negedge rsn);
    endtask : wait_for_reset_start

    // Task : wait_for_reset_end
    task automatic wait_for_reset_end();
        @(posedge rsn);
        endtask : wait_for_reset_end

    initial begin
        rsn = 1'b0;
        repeat (5) @(posedge clk);
        rsn = 1'b1;
    end

endinterface : reset_if

// Interface: completed_if
// Completed interface, connected to the ROB observing outgoing instructions
interface core_completed_if;
    logic                   clk;
    logic                   rsn;
    logic valid[COMMIT_WIDTH-1:0];
    logic [63:0]            pc[COMMIT_WIDTH-1:0];
    logic [31:0]            instr[COMMIT_WIDTH-1:0];
    logic [63:0]            result[COMMIT_WIDTH-1:0];
    logic                   result_valid[COMMIT_WIDTH-1:0];
    logic                   xcpt[COMMIT_WIDTH-1:0];
    logic [63:0]            xcpt_cause[COMMIT_WIDTH-1:0];
    dut_pkg::rob_addr_t     rob_head[COMMIT_WIDTH-1:0];
    dut_pkg::rob_addr_t     rob_entry_miss[COMMIT_WIDTH-1:0];
    logic                   core_req_valid[COMMIT_WIDTH-1:0];
    logic                   branch[COMMIT_WIDTH-1:0];
    logic                   fault[COMMIT_WIDTH-1:0];
    logic [PADDR_WIDTH-1:0] pdest[COMMIT_WIDTH-1:0];
    logic [dut_pkg::VLEN-1:0] vd[COMMIT_WIDTH-1:0];
    logic [63:0]            store_data[COMMIT_WIDTH-1:0];
    logic                   store_valid[COMMIT_WIDTH-1:0];
    logic [63:0]            mem_req_rob_entry; // TODO 64 bits??
endinterface

// Interface: regfile_if
// Regfile interface, directly connected to the physical register file, contains its values
interface core_regfile_if;
    logic clk;
    uint64_t regfile [REGFILE_DEPTH-1:0];
endinterface

// Interface: fetch_if
// Fetch interface, connected to the mapper observing incoming instructions
interface core_fetch_if;
    logic                   clk;
    logic                   rsn;
//    SARGANTANA
        logic [63:0]    fetch_pc;
        logic [63:0]    decode_pc;
        logic           fetch_valid;
        logic           decode_valid;
        logic           decode_is_illegal;
        logic           decode_is_compressed;
        logic           invalidate_icache_int;
        logic           invalidate_buffer_int;
        logic           retry_fetch;
// LAGARTO_KA TODO: Polymorphism
        logic [FETCH_WIDTH-1:0] mapper_id_inst_valid;   // id_inst_valid_i from lagarto_ka_mapper.v
        uint32_t                mapper_id_inst_p0;      // id_inst_p0_i from lagarto_ka_mapper.v
        uint32_t                mapper_id_inst_p1;      // id_inst_p1_i from lagarto_ka_mapper.v
        uint64_t                mapper_id_pc_p0;        // id_pc_p0_i from lagarto_ka_mapper.v
        uint64_t                mapper_id_pc_p1;        // id_pc_p1_i from lagarto_ka_mapper.v
        logic xcpt;
        logic branch;
        logic [6:0]             rob_new_entry_p0;
        logic [6:0]             rob_new_entry_p1;
        logic                   mapper_disp_branch_p0;
        logic                   mapper_disp_branch_p1;
endinterface

// Interface: csr_tohost_if
interface csr_tohost_if;
    logic csr_tohost_valid;
endinterface

// Interface: csr_clearmip_if
interface csr_clearmip_if;
    logic csr_clearmip_valid;
endinterface

interface brom_if;
    dut_pkg::brom_req_t          req;
    dut_pkg::brom_resp_t         resp;
endinterface
`endif
