//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : icache_if 
// File          : icache_if.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is Interface which used to (icache related) communicate with DUT. 
//----------------------------------------------------------------------
`ifndef ICACHE_IF
`define ICACHE_IF

import sargantana_icache_pkg::*;

// Interface: icache_if
// Icache interface, connected to the test harness and getting UVM stimulus
interface icache_if;

    logic                   clk;
    logic                   rsn;
    // iCache interface //New connections needds to added through test_harness for icache
    iresp_o_t      icache_resp  ;
    ireq_i_t       lagarto_ireq ;
    // In_futute we can remove if not necessary.. = icache_invalidate_o
    logic          iflush;
    logic          csr_en_translation;
    logic [63:0]   csr_status;
    logic [63:0]   csr_satp;
    logic [1:0]    csr_priv_lvl;
    clocking ic_mon_cb@(posedge clk);
        default input #0 output #1;
	    input lagarto_ireq, csr_en_translation, csr_status, csr_satp, csr_priv_lvl, iflush;
    endclocking

    modport IC_MON_MP (clocking ic_mon_cb); 
endinterface

`endif
