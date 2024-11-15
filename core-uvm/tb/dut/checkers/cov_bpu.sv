import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_bpu(
    input               i_clk,
    input               i_rsn,
    input               i_rob_branch_p0,    //rob_branch_p0_i
    input               i_rob_branch_p1,    //rob_branch_p1_i
    input               i_brob_enable,      //brob_enable_i
    input               i_bpu_miss,         //bpu_miss_o
    input               i_bpu_predict       //bpu_predict_o

);

    covergroup cg_bpu @(posedge i_clk);
        cp_brob_enable : coverpoint i_brob_enable iff( i_rsn );
        cp_rob_branch_p0 : coverpoint i_rob_branch_p0 iff( i_rsn );
        cp_rob_branch_p1 : coverpoint i_rob_branch_p1 iff( i_rsn );
        cp_bpu_miss : coverpoint i_bpu_miss iff( i_rsn );
        cp_bpu_predict : coverpoint i_bpu_predict iff( i_rsn );
    endgroup : cg_bpu

    cg_bpu u_cg_bpu;

    initial
    begin
        u_cg_bpu = new();
    end




/*
ROB branches (br_rob_enable_i, rob_branch_p0_i and rob_branch_p1_i)
Branch misprediction (bpu_miss_o)
Branch prediction (bpu_predict_o)
*/
endmodule
