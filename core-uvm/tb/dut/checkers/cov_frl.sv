import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_frl(
    input               i_clk,
    input               i_rsn, 
   

    input   `pREG       i_frl_rd_p0,    //lagarto_ka_frl frl_pdest_p0_o
    input   `pREG       i_frl_rd_p1,    //lagarto_ka_frl frl_pdest_p1_o
    input               i_frl_lock,     //lagarto_ka_frl frl_lock_i
    input   `pREG       i_rob_pdst_p0,  //lagarto_ka_frl rob_pdest_p0_i
    input   `pREG       i_rob_pdst_p1   //lagarto_ka_frl rob_pdest_p1_i

);

    covergroup  cg_frl @(posedge i_clk);
        cp_frl_rd_p0 : coverpoint i_frl_rd_p0 iff( i_rsn );
        cp_frl_rd_p1 : coverpoint i_frl_rd_p1 iff( i_rsn );

        cp_frl_lock : coverpoint i_frl_lock iff( i_rsn );

        cp_rob_pdst_p0 : coverpoint i_rob_pdst_p0 iff( i_rsn );
        cp_rob_pdst_p1 : coverpoint i_rob_pdst_p1 iff( i_rsn );
           
    endgroup :  cg_frl

 
    cg_frl u_cg_frl;


    initial
    begin
        u_cg_frl = new();
    end

/*
FSM
Each physical register is used (reaches top of the FIFO)
FRL is stalled (frl_lock)
All physical old destinations 1 and 2 are freed (rob_pdest_p0_i, rob_pdest_p1_i)
All physical destinations 1 and 2 (frl_pdest_p1_o, frl_pdest_p2_o)
*/
endmodule
