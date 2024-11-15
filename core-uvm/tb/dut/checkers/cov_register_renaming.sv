import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_register_renaming(
    input               i_clk,
    input               i_rsn, 
    input               i_en_src1_p0,   //lagarto_ka_renaming_rat rs1_ena_p0_i
    input   `vREG       i_src1_p0,      //lagarto_ka_renaming_rat rs1_addr_p0_i
    input               i_en_src2_p0,   //lagarto_ka_renaming_rat rs2_ena_p0_i
    input   `vREG       i_src2_p0,      //lagarto_ka_renaming_rat rs2_addr_p0_i
    input               i_en_dst_p0,    //lagarto_ka_renaming_rat rdst_ena_p0_i
    input   `vREG       i_dst_p0,       //lagarto_ka_renaming_rat rdst_addr_p0_i
    input               i_en_src1_p1,   //lagarto_ka_renaming_rat rs1_ena_p1_i
    input   `vREG       i_src1_p1,      //lagarto_ka_renaming_rat rs1_addr_p1_i
    input               i_en_src2_p1,   //lagarto_ka_renaming_rat rs2_ena_p1_i
    input   `vREG       i_src2_p1,      //lagarto_ka_renaming_rat rs2_addr_p1_i
    input               i_en_dst_p1,    //lagarto_ka_renaming_rat rdst_ena_p1_i
    input   `vREG       i_dst_p1,       //lagarto_ka_renaming_rat rdst_addr_p1_i

    input   `pREG       i_rat_src1_p0,  //lagarto_ka_renaming_rat rat_psrc1_p0_o
    input   `pREG       i_rat_src2_p0,  //lagarto_ka_renaming_rat rat_psrc2_p0_o
    input   `pREG       i_rat_dst_p0,   //lagarto_ka_renaming_rat rat_odest_p0_o
    input   `pREG       i_rat_src1_p1,  //lagarto_ka_renaming_rat rat_psrc1_p1_o
    input   `pREG       i_rat_src2_p1,  //lagarto_ka_renaming_rat rat_psrc2_p1_o
    input   `pREG       i_rat_dst_p1,   //lagarto_ka_renaming_rat rat_odest_p1_o

    input   `pREG       i_frl_dst_p0,   //lagarto_ka_frl frl_pdest_p0_o
    input   `pREG       i_frl_dst_p1,   //lagarto_ka_frl frl_pdest_p0_o
    input               i_rnm_lock,     //lagarto_ka_renaming_unit rnm_lock_i
    input               i_rnm_flush,    //lagarto_ka_renaming_unit rnm_flush_i

    input   `pREG       i_rnm_src1_p0,  //lagarto_ka_renaming_unit rnm_psrc1_p0_o
    input   `pREG       i_rnm_src2_p0,  //lagarto_ka_renaming_unit rnm_psrc2_p0_o
    input   `pREG       i_rnm_odst_p0,  //lagarto_ka_renaming_unit rnm_odest_p0_o

    input   `pREG       i_rnm_src1_p1,  //lagarto_ka_renaming_unit rnm_psrc1_p1_o
    input   `pREG       i_rnm_src2_p1,  //lagarto_ka_renaming_unit rnm_psrc2_p1_o
    input   `pREG       i_rnm_odst_p1   //lagarto_ka_renaming_unit rnm_odest_p1_o


);

    covergroup cg_rat @(posedge i_clk);

        cp_src1_p0 : coverpoint i_src1_p0 iff( i_rsn && i_en_src1_p0 ); //0-31
        cp_src2_p0 : coverpoint i_src2_p0 iff( i_rsn && i_en_src2_p0 ); //0-31
        cp_dst_p0 : coverpoint i_dst_p0 iff( i_rsn && i_en_dst_p0 );    //0-31

        cp_src1_p1 : coverpoint i_src1_p1 iff( i_rsn && i_en_src1_p1 ); //0-31
        cp_src2_p1 : coverpoint i_src2_p1 iff( i_rsn && i_en_src2_p1 ); //0-31
        cp_dst_p1 : coverpoint i_dst_p1 iff( i_rsn && i_en_dst_p1 );    //0-31

        cp_rat_src1_p0: coverpoint i_rat_src1_p0 iff( i_rsn && i_en_src1_p0);   //0-127
        cp_rat_src2_p0: coverpoint i_rat_src2_p0 iff( i_rsn && i_en_src2_p0);   //0-127
        cp_rat_dst_p0: coverpoint i_rat_dst_p0 iff( i_rsn && i_en_dst_p0);      //0-127

        cp_rat_src1_p1: coverpoint i_rat_src1_p1 iff( i_rsn && i_en_src1_p1);   //0-127
        cp_rat_src2_p1: coverpoint i_rat_src2_p1 iff( i_rsn && i_en_src2_p1);   //0-127
        cp_rat_dst_p1: coverpoint i_rat_dst_p1 iff( i_rsn && i_en_dst_p1);      //0-127

        cp_src1_p0_renaming : cross cp_src1_p0, cp_rat_src1_p0;
        cp_src2_p0_renaming : cross cp_src2_p0, cp_rat_src2_p0;
        cp_dst_p0_renaming : cross cp_dst_p0, cp_rat_dst_p0;

        cp_src1_p1_renaming : cross cp_src1_p1, cp_rat_src1_p1;
        cp_src2_p1_renaming : cross cp_src2_p1, cp_rat_src2_p1;
        cp_dst_p1_renaming : cross cp_dst_p1, cp_rat_dst_p1;
       
    endgroup : cg_rat

    covergroup  cg_frl @(posedge i_clk);
        cp_frl_dst_p0 : coverpoint i_frl_dst_p0 iff ( i_rsn );  //0-127
        cp_frl_dst_p1 : coverpoint i_frl_dst_p0 iff ( i_rsn );  //0-127
           
    endgroup :  cg_frl

    covergroup cg_rnm @(posedge i_clk);
        cp_rnm_lock: coverpoint i_rnm_lock iff( i_rsn );
        cp_rnm_flush: coverpoint i_rnm_flush iff( i_rsn );

        cp_rnm_src1_p0 : coverpoint i_rnm_src1_p0 iff( i_rsn );
        cp_rnm_src2_p0 : coverpoint i_rnm_src2_p0 iff( i_rsn );
        cp_rnm_odst_p0 : coverpoint i_rnm_odst_p0 iff( i_rsn );

        cp_rnm_src1_p1 : coverpoint i_rnm_src1_p1 iff( i_rsn );
        cp_rnm_src2_p1 : coverpoint i_rnm_src2_p1 iff( i_rsn );
        cp_rnm_odst_p1 : coverpoint i_rnm_odst_p1 iff( i_rsn );
           
    endgroup : cg_rnm

    cg_rat u_cg_rat;
    cg_frl u_cg_frl;
    cg_rnm u_cg_rnm;

    initial
    begin
        u_cg_rat = new();
        u_cg_frl = new();
        u_cg_rnm = new();
    end




/*
Each logical source register is renamed to each physical source register
Each logical destination register is renamed to each physical destination register
Each physical destination register is in the free register list
Destination renaming FSM
True dependency check FSM
Early-old destination check FSM
Renaming stalled (rnm_lock_i)
Renaming flush (rnm_flush_i)
All possible physical destination registers (frl_pdest_p0_i, frl_pdest_p1_i)
All possible logical source 1 and 2 (id_rs1_addr_p0_i, id_rs2_addr_p0_i, id_rs1_addr_p1_i, id_rs2_addr_p1_i)
All possible logical destination registers 1 and 2 (id_rdst_addr_p0_i. id_rdst_addr_p1_i)
All possible physical source 1 and 2 (rnm_psrc1_p0_o, rnm_psrc2_p0_o, rnm_psrc1_p1_o, rnm_psrc2_p1_o)
All possible physical old destination 1 and 2 (rnm_odest_p0_o,rnm_odest_p1_o)
*/
endmodule
