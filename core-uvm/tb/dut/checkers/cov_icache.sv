`include "uvm_macros.svh"
import uvm_pkg::*;
import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config
import sargantana_icache_pkg::*;

module cov_icache(
    input                               i_clk,
    input                               i_rsn, 
   
    input   iresp_o_t                   i_icache_resp,          //ICACHE  -> LAGARTO
    input   ireq_i_t                    i_lagarto_ireq,         //LAGARTO -> ICACHE
    input   sargantana_icache_pkg::ifill_resp_i_t              i_ifill_resp,           //L2      -> ICACHE
    input   sargantana_icache_pkg::ifill_req_o_t               i_ifill_req,            //ICACHE  -> L2
    input   tresp_i_t                   i_tlb_tresp,            //MMU     -> ICACHE
    input   treq_o_t                    i_tlb_treq,             //ICACHE  -> MMU
    input                               i_icache_invalidate,    //iflush
    input                               i_icache_ptw_invalidate,//io_ptwinvalidate
    input                               i_icache_l1_hit,        //icache_ctrl is_hit
    input                               i_icache_l1_miss,       //icache_ctrl miss_o
    input   [2 : 0]                     i_icache_tl_a_type      //io_mem_acquire_bits_a_type
   

);
    typedef enum logic[2 : 0]{
        GET             = 3'b000,   //PROBE_COPY
        GET_BLOCK       = 3'b001,   //PROBE_COPY
        GET_PREFETCH    = 3'b101,   //PROBE_COPY
        PUT             = 3'b010,   //PROBE_INVALIDATE
        PUT_BLOCK       = 3'b011,   //PROBE_INVALIDATE
        PUT_PREFETCH    = 3'b110,   //PROBE_INVALIDATE
        PUT_ATOMIC      = 3'b100,   //PROBE_INVALIDATE
        AINVALID        = 3'b111
    } a_type_msg;

    covergroup  cg_icache @(posedge i_clk);
        cp_req_kill : coverpoint i_lagarto_ireq.kill iff( i_rsn );
        cp_invalidate: coverpoint i_icache_invalidate iff( i_rsn ){
            bins one = {1};
            bins zero = {0};
        }
        cp_icache_xcpt: coverpoint i_icache_resp.xcpt iff( i_rsn && i_icache_resp.valid );
        cp_tlb_xcpt: coverpoint i_tlb_tresp.xcpt iff( i_rsn );
        cp_ptw_invalidate: coverpoint i_icache_ptw_invalidate iff( i_rsn );
        cp_l1_is_hit: coverpoint i_icache_l1_hit iff( i_rsn );
        cp_l1_is_miss: coverpoint i_icache_l1_miss iff( i_rsn );
        cp_tlb_miss: coverpoint i_tlb_tresp.miss iff( i_rsn );
        cp_req: coverpoint i_lagarto_ireq.valid iff( i_rsn ){
            bins one = {1};
            bins zero = {0};
        }

        cp_cross_req_invalidate: cross cp_req, cp_invalidate iff( i_rsn ){
            illegal_bins failure = binsof (cp_req.one) && binsof (cp_invalidate.one );
        }
        cp_tlb_miss_resolved : coverpoint i_tlb_tresp.ptw_v iff( i_rsn );

        cp_tl_a_type : coverpoint i_icache_tl_a_type iff( i_rsn && i_ifill_req.valid ){
            bins get = {GET};
            bins get_block = {GET_BLOCK};
            bins get_prefetch = {GET_PREFETCH};
            illegal_bins illegal = {PUT, PUT_ATOMIC, PUT_PREFETCH, PUT_BLOCK};
        }
    endgroup :  cg_icache

 
    cg_icache u_cg_icache;


    initial
    begin
        u_cg_icache = new();
    end

endmodule
