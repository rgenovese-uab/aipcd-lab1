import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_int_queue(
    input               i_clk,
    input               i_rsn, 
   
    input               i_q0_full,      //full_asq_b0
    input               i_q1_full,      //full_asq_b1
    input               i_q2_full,      //full_asq_b2
    input               i_q3_full,      //full_asq_b3
    input               i_intq_flush,   //intq_flush_i
    input               i_intq_lock,    //intq_lock_i
    input   `pREG       i_load_pdest,   //load_pdest_i
    input   `pREG       i_fu1_pdest,    //exe_fu1_pdest_i
    input   `pREG       i_fu2_pdest     //exe_fu1_pdest_i

);

    covergroup  cg_int_queue @(posedge i_clk);
        cp_q0_full : coverpoint i_q0_full iff( i_rsn );
        cp_q1_full : coverpoint i_q1_full iff( i_rsn );
        cp_q2_full : coverpoint i_q2_full iff( i_rsn );
        cp_q3_full : coverpoint i_q3_full iff( i_rsn );

        cp_intq_flush : coverpoint i_intq_flush iff( i_rsn );
        cp_intq_lock : coverpoint i_intq_lock iff( i_rsn );

        cp_load_pdest : coverpoint i_load_pdest iff( i_rsn );
        cp_fu1_pdest : coverpoint i_fu1_pdest iff( i_rsn );
        cp_fu2_pdest : coverpoint i_fu2_pdest iff( i_rsn );
        
           
    endgroup :  cg_int_queue

 
    cg_int_queue u_cg_int_queue;


    initial
    begin
        u_cg_int_queue = new();
    end

/*
Each of the 4 blocks is filled (with 8 instructions) - Queue full (intq_full_o) empty (intq_empty_o)
FSM
Integer instruction queue is stalled (intq_flush_i)
Integer instruction queue is flushed (intq_lock_i)
All destinations possible tied to load ops (load_pdest_complete_i)
All physical destinations are used (exe_fu1_pdest_i, exe_fu2_pdest_i)
*/
endmodule
