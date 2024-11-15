//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_dcache_trans
// File          : core_dcache_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence_item.
//                 This class instantiates the dcache transaction.
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_TRANS_SV
`define CORE_DCACHE_TRANS_SV

import hpdcache_pkg::*;

class core_dcache_trans extends uvm_sequence_item;
    `uvm_object_utils(core_dcache_trans)

    function new(string name = "core_dcache_trans");
        super.new(name);
    endfunction : new

    logic           dcache_req_valid ;
    logic           dcache_req_ready ;
    hpdcache_req_t  dcache_req       ;
    logic           dcache_resp_valid;
    hpdcache_rsp_t  dcache_resp      ;
    logic           wbuf_empty       ;
    int unsigned    ttl              ; // Cycles left to serve the request
    bit             error = 0        ;
    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
    endfunction : do_print

endclass : core_dcache_trans

`endif
