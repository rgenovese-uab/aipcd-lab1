//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : dcache_if
// File          : dcache_if.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This is Interface which used to (dcache related) communicate with DUT.
//----------------------------------------------------------------------
`ifndef DCACHE_IF
`define DCACHE_IF

import sargantana_hpdc_pkg::*;
import hpdcache_pkg::*;
import drac_pkg::*;

// Interface: dcache_if
// Dcache interface, connected to the test harness and getting UVM stimulus
interface dcache_if;

    logic                   clk;
    logic                   rsn;
    logic          dcache_req_valid  [HPDCACHE_NREQUESTERS-1:0];
    logic          dcache_req_ready  [HPDCACHE_NREQUESTERS-1:0];
    hpdcache_req_t dcache_req        [HPDCACHE_NREQUESTERS-1:0];
    logic          dcache_resp_valid [HPDCACHE_NREQUESTERS-1:0];
    hpdcache_rsp_t dcache_resp       [HPDCACHE_NREQUESTERS-1:0];
    logic          wbuf_empty;

    clocking dc_mon_cb @(posedge clk);
        default input #0 output #1;
        input dcache_req_valid;
        input dcache_req_ready;
        input dcache_req;
        input dcache_resp_valid;
        input dcache_resp;
        input wbuf_empty;
    endclocking

    modport DC_MON_CB (clocking dc_mon_cb);

endinterface

`endif
