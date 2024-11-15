import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_ls_queue(
    input               i_clk,
    input               i_rsn, 
   
    input               i_lsq_full,             //lsq_full_o
    input               i_lsq_flush,            //lsq_flush_i
    input               i_lsq_lock,             //lsq_lock_i
    input               i_lsq_rob_memop,        //rob_memop_i

    input               i_dmem_req_valid,       //dmem_req_valid_o
    input   [4:0]       i_dmem_req_cmd,         //dmem_req_cmd_o
    input               i_dmem_invalidate_lr,   //dmem_req_invalidate_lr_o

    input   `pREG       i_lsq_dmem_pdst,        //dmem_pdest_complete_o,
    input               i_lsq_dmem_complete,    //dmem_complete_o
    input   `pREG       i_lsq_psrc1,            //issue_lsq_psrc1_o
    input   `pREG       i_lsq_psrc2,            //issue_lsq_psrc2_o
    input               i_lsq_valid,            //issue_lsq_valid_o

    input   [4:0]       i_lsq_agu_code,         //lagarto_ka_lsq_agu inst_code_int
    input               i_lsq_agu_enable        //lagarto_ka_lsq_agu enable_i

);
      //Load
    localparam LB    = 5'b01000;  // BYTE
    localparam LH    = 5'b01001;  // HALF
    localparam LW    = 5'b01010;  // WORD
    localparam LBU   = 5'b01100;  // BYTE UNSIGNED
    localparam LHU   = 5'b01101;  // HALF UNSIGNED
    localparam LWU   = 5'b01110;  // WORD UNSIGNED
      //Store
    localparam SB    = 5'b10000;  // BYTE
    localparam SH    = 5'b10001;  // HALF
    localparam SW    = 5'b10010;  // WORD
    localparam SD    = 5'b10011;  // DOUBLE

    covergroup  cg_ls_queue @(posedge i_clk);
        cp_lsq_full : coverpoint i_lsq_full iff( i_rsn );
        cp_lsq_flush : coverpoint i_lsq_flush iff( i_rsn );
        cp_lsq_lock : coverpoint i_lsq_lock iff( i_rsn );
        cp_lsq_rob_memop: coverpoint i_lsq_rob_memop iff( i_rsn );

        cp_dmem_cmd : coverpoint i_dmem_req_cmd iff( i_rsn && i_dmem_req_valid){
            bins LR         = {5'b00110};
            bins SC         = {5'b00111};
            bins AMOSWAP    = {5'b00100};
            bins AMOADD     = {5'b01000};
            bins AMOXOR     = {5'b01001};
            bins AMOAND     = {5'b01011};
            bins AMOOR      = {5'b01010};
            bins AMOMIN     = {5'b01100};
            bins AMOMAX     = {5'b01101};
            bins AMOMINU    = {5'b01110};
            bins AMOMAXU    = {5'b01111};
            bins LOAD       = {5'b00000};
            bins STORE      = {5'b00001};
        }

        cp_dmem_invalidate : coverpoint i_dmem_invalidate_lr iff( i_rsn && i_dmem_req_valid );

        cp_lsq_dmem_pdst : coverpoint i_lsq_dmem_pdst iff( i_rsn && i_lsq_dmem_complete );
        cp_lsq_psrc1 : coverpoint i_lsq_psrc1 iff( i_rsn && i_lsq_valid );
        cp_lsq_psrc2 : coverpoint i_lsq_psrc2 iff( i_rsn && i_lsq_valid );

        cp_lsq_agu_code : coverpoint i_lsq_agu_code iff( i_rsn && i_lsq_agu_enable ){
            bins all[] = {LB , LH , LW , LBU, LHU, LWU, SB, SH, SW, SD}; 
        }
           
    endgroup :  cg_ls_queue

 
    cg_ls_queue u_cg_ls_queue;


    initial
    begin
        u_cg_ls_queue = new();
    end

/*
FSM
Queue full
Queue is flushed (lsq_flush_i)
Queue is stalled (lsq_lock_i)
Memop reaches ROB head (rob_memop_i)
All possible physical source and destination registers from CSR instruction (issue_csrh_psrc1_i, issue_csrh_pdest_i)
Exception occurred (dmem_req_invalidate_lr_o)
Physical source registers issued to EXE to detect dependencies (agu_psrc1_o, agu_psrc2_o)
Physical destination register for load (load_pdest_complete_o)
*/
endmodule
