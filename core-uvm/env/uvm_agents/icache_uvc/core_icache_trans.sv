//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_icache_trans 
// File          : core_icache_trans.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_sequence_item. This class 
//                 This class instantiates the icache transaction.
//----------------------------------------------------------------------
`ifndef CORE_ICACHE_TRANS_SV
`define CORE_ICACHE_TRANS_SV
import sargantana_icache_pkg::*;
class core_icache_trans extends uvm_transaction;
    `uvm_object_utils(core_icache_trans)

    function new(string name = "core_icache_trans");
        super.new(name);
    endfunction : new

    // iCache interface //New connections needds to added through test_harness for icache
    iresp_o_t           icache_resp  ;
    ireq_i_t            lagarto_ireq ;
    logic           iflush; // In_futute we can remove if not necessary.. = icache_invalidate_o
    logic           csr_en_translation;
    logic [63:0]    paddr;
    logic [63:0]    csr_status;
    logic [63:0]    csr_satp;
    logic [1:0]     csr_priv_lvl;
    logic           drive;
    logic [63:0]    data;
    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
    endfunction : do_print 

endclass : core_icache_trans

`endif
