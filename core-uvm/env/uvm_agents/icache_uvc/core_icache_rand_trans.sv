//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_icache_rand_trans 
// File          : core_icache_rand_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence_item. This class 
//                 This class instantiates the icache transaction.
//----------------------------------------------------------------------
`ifndef CORE_ICACHE_RAND_TRANS_SV
`define CORE_ICACHE_RAND_TRANS_SV

class core_icache_rand_trans extends uvm_sequence_item;
    `uvm_object_utils(core_icache_rand_trans)

    function new(string name = "core_icache_rand_trans");
        super.new(name);
    endfunction : new

    `ifndef HIT_MISS_RAND 
        logic    hit_miss_flag = 1'b1  ;
    `else
        rand logic hit_miss_flag;
    `endif

    rand int       delay;

    constraint exp {delay inside {[0:10]};}

    //---------------------------------------------------------------------------------------------
    // I-CACHE INTERFACE - //new
    //---------------------------------------------------------------------------------------------
    // output logic [27:0]     io_tlb_req_bits_vpn     ,
    // output logic            io_tlb_req_valid        ,
                                                    
    // input logic             io_ptwinvalidate        , 
    // input logic             io_tlb_resp_miss        ,
    // input logic             io_tlb_resp_xcpt_if     ,
    // input logic  [19:0]     io_itlb_resp_ppn_i      ,
    // input logic             io_iptw_resp_valid      ,

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
        //printer.print_icache("icache", icache, $bits(icache));
        //printer.print_icache("icache_cause", icache_cause, $bits(icache_cause));
    endfunction : do_print 

endclass : core_icache_rand_trans

`endif
