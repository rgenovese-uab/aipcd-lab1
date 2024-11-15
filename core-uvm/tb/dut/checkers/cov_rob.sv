import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_rob(
    input                   i_clk,
    input                   i_rsn, 
    input   `pREG           i_rob_odest,     //rob_odest_o
    input   `pREG           i_rob_pdest,     //rob_pdest_o
    input                   i_csr_interrupt,    //csr_interrupt_i
    input                   i_csr_flag,           //rob_csr_p0_o
    input                   i_if_lock,          //if_lock_o
    input                   i_if_flush,         //if_flush_o
    input                   i_pc_flush,         //pc_flush_o
    input                   i_id_flush,         //id_flush_o
    input                   i_bpu_miss,         //bpu_miss_i
    input                   i_bpu_predict,      //bpu_predict_i
    input                   i_rob_branch_flag,    //rob_branch_p0_o
    input   `FETCH_WINDOW   i_id_stall,         //id_stall_req_i
    input   `FETCH_WINDOW   i_id_flush_req,     //id_flush_req_i
    input                   i_frl_empty,        //frl_empty_i
    input                   i_rnm_flush,        //rnm_flush_o
    input                   i_rob_recovery,     //rob_recovery_o
    input   `FETCH_WINDOW   i_disp_inst_valid,  //disp_inst_valid_i
    input                   i_disp_branch_p0,   //disp_branch_p0_i
    input                   i_disp_branch_p1,   //disp_branch_p1_i
    input   `pREG           i_disp_odest_p0,    //disp_odest_p0_i
    input   `pREG           i_disp_odest_p1,    //disp_odest_p1_i
    input   `LSQ_ACTIVE     i_disp_lsq_actv,    //disp_lsq_actv_i
    input                   i_disp_flush,       //disp_flush_o
    input                   i_issue_cond_br_p0, //issue_cpuvec_br_p0_i
    input                   i_issue_cond_br_p1, //issue_cpuvec_br_p1_i
    input                   i_intq_full,        //intq_full_i
    input                   i_intq_flush,       //intq_flush_o
    input                   i_lsq_full,         //lsq_full_i
    input                   i_dmem_complete,    //dmem_complete_i
    input                   i_lsq_flush,        //lsq_flush_o
    input                   i_rob_memory_flag,     //rob_memop_p0_o
    input                   i_rob_csr_p0,       //rob_csr_p0
    input                   i_rob_csr_p1,       //rob_csr_p1
    input                   i_rob_xcpt_p0,      //rob_xcpt_p0
    input                   i_rob_xcpt_p1,      //rob_xcpt_p1
    input   [4  : 0]        i_rob_xcpt_cause,//rob_cause_p0
    input                   i_rob_commit,    //rob_commit_p0_o
    input                   i_exe_fu1_complete, //exe_fu1_complete_i
    input                   i_exe_fu2_complete, //exe_fu2_complete_i
    input                   i_exe_flush,        //exe_flush_o
    input                   i_brob_inflight,    //brob_inflight_i
    input                   i_brob_commit,      //brob_commit_i
    input                   i_brob_nonspec,     //brob_nonspec_i
    input                   i_brob_branch   //rob_branch_p0_o

);
    localparam EXCEPTION_INST_ADDRESS_MISALIGNED          =  {1'b0, 63'd0};
    localparam EXCEPTION_INST_ACCESS_FAULT                =  {1'b0, 63'd1};
    localparam EXCEPTION_ILLEGAL_INST                     =  {1'b0, 63'd2};
    localparam EXCEPTION_BREAKPOINT                       =  {1'b0, 63'd3};
    localparam EXCEPTION_LOAD_ADDRESS_MISALIGNED          =  {1'b0, 63'd4};
    localparam EXCEPTION_LOAD_ACCESS_FAULT                =  {1'b0, 63'd5};
    localparam EXCEPTION_STORE_AMO_ADDRESS_MISALIGNED     =  {1'b0, 63'd6};
    localparam EXCEPTION_STORE_AMO_ACCESS_FAULT           =  {1'b0, 63'd7};
    localparam EXCEPTION_ENV_CALL_USER                    =  {1'b0, 63'd8};
    localparam EXCEPTION_ENV_CALL_SUPERVISOR              =  {1'b0, 63'd9};
    localparam EXCEPTION_ENV_CALL_HYPERVISOR              =  {1'b0, 63'd10};
    localparam EXCEPTION_ENV_CALL_MACHINE                 =  {1'b0, 63'd11};
    localparam EXCEPTION_INST_PAGE_FAULT                  =  {1'b0, 63'd12};
    localparam EXCEPTION_LOAD_PAGE_FAULT                  =  {1'b0, 63'd13};
    localparam EXCEPTION_STORE_AMO_PAGE_FAULT             =  {1'b0, 63'd15};
    localparam XCPT_CAUSE_ZERO                            = {`XCPT_CAUSE_WIDTH{1'b0}};
    
    //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    //              STILL MISSING SPECIFICATIONS            
    //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

    covergroup  cg_rob @(posedge i_clk);
        cp_rob_odest: coverpoint i_rob_odest iff ( i_rsn );

        cp_rob_pdest: coverpoint i_rob_pdest iff ( i_rsn );
        cp_id_flush: coverpoint i_id_flush iff( i_rsn );
        cp_pc_flush: coverpoint i_pc_flush iff( i_rsn );
        cp_rob_recovery : coverpoint i_rob_recovery iff( i_rsn );
    endgroup :  cg_rob


    covergroup cg_rob_csr @(posedge i_clk);
        cp_csr_interrupt: coverpoint i_csr_interrupt iff( i_rsn );
        cp_csr_flag: coverpoint i_csr_flag iff( i_rsn );
        //cp_csr_p1: coverpoint i_csr_p1 iff( i_rsn );
    endgroup : cg_rob_csr

    covergroup cg_rob_fetch @(posedge i_clk);
        cp_if_lock: coverpoint i_if_lock iff( i_rsn );
        cp_if_flush: coverpoint i_if_flush iff( i_rsn );
    endgroup : cg_rob_fetch

    covergroup cg_rob_branch_predict @(posedge i_clk);
        cp_bpu_miss : coverpoint i_bpu_miss iff( i_rsn );
        cp_bpu_predict : coverpoint i_bpu_predict iff( i_rsn );
        cp_rob_branch : coverpoint i_rob_branch_flag iff( i_rsn );
    endgroup : cg_rob_branch_predict

    covergroup cg_rob_decoder @(posedge i_clk);
        cp_id_stall : coverpoint i_id_stall iff( i_rsn ); //[TOCHECK] width
        cp_id_flush_req : coverpoint i_id_flush_req iff( i_rsn ); //[TOCHECK] width
    endgroup : cg_rob_decoder

    covergroup cg_rob_frl @(posedge i_clk);
        cp_frl_empty : coverpoint i_frl_empty iff( i_rsn );
    endgroup : cg_rob_frl

    covergroup cg_rob_rnm @(posedge i_clk);
        co_rnm_flush: coverpoint i_rnm_flush iff( i_rsn );
    endgroup : cg_rob_rnm

    covergroup cg_rob_mapper @(posedge i_clk);
        cp_disp_inst_valid : coverpoint i_disp_inst_valid iff( i_rsn ){
            bins all[] = {2'b00, 2'b01, 2'b11};
            illegal_bins ill = {2'b10};
        }
        cp_disp_branch_p0 : coverpoint i_disp_branch_p0 iff( i_rsn );
        cp_disp_branch_p1 : coverpoint i_disp_branch_p1 iff( i_rsn );
        cp_disp_odest_p0 : coverpoint i_disp_odest_p0 iff( i_rsn );
        cp_disp_odest_p1 : coverpoint i_disp_odest_p1 iff( i_rsn );
        cp_disp_lsq_actv : coverpoint i_disp_lsq_actv iff( i_rsn ){
            bins all[] = {2'b00, 2'b01, 2'b11};
            illegal_bins ill = {2'b10};
        }
        cp_disp_flush : coverpoint i_disp_flush iff( i_rsn );
    endgroup : cg_rob_mapper

    covergroup cg_rob_intq @(posedge i_clk);
        cp_issue_cond_br_p0 : coverpoint i_issue_cond_br_p0 iff( i_rsn );
        cp_issue_cond_br_p1 : coverpoint i_issue_cond_br_p1 iff( i_rsn );
        cp_intq_full : coverpoint i_intq_full iff( i_rsn );
        cp_intq_flush : coverpoint i_intq_flush iff( i_rsn );
    endgroup : cg_rob_intq

    covergroup cg_rob_lsq @(posedge i_clk);
        cp_lsq_full : coverpoint i_lsq_full iff( i_rsn );
        cp_dmem_complete : coverpoint i_dmem_complete iff( i_rsn );
        cp_lsq_flush : coverpoint i_lsq_flush iff( i_rsn );
        cp_rob_memory_flag : coverpoint i_rob_memory_flag iff( i_rsn );
    endgroup : cg_rob_lsq

    covergroup cg_rob_barrier @(posedge i_clk);
        cp_rob_csr_p0 : coverpoint i_rob_csr_p0 iff( i_rsn );
        cp_rob_csr_p1 : coverpoint i_rob_csr_p1 iff( i_rsn );
        cp_rob_xcpt_p0 : coverpoint i_rob_xcpt_p0 iff( i_rsn );
        cp_rob_xcpt_p1 : coverpoint i_rob_xcpt_p1 iff( i_rsn );
        cp_rob_xcpt_cause : coverpoint i_rob_xcpt_cause iff( i_rsn && i_rob_xcpt_p0){
            bins xcpt_INST_ADDRESS_MISALIGNED = {EXCEPTION_INST_ADDRESS_MISALIGNED};
            bins xcpt_INST_ACCESS_FAULT = {EXCEPTION_INST_ACCESS_FAULT};
            bins xcpt_ILLEGAL_INST = {EXCEPTION_ILLEGAL_INST};
            bins xcpt_BREAKPOINT = {EXCEPTION_BREAKPOINT};
            bins xcpt_LOAD_ADDRESS_MISALIGNED = {EXCEPTION_LOAD_ADDRESS_MISALIGNED};
            bins xcpt_LOAD_ACCESS_FAULT = {EXCEPTION_LOAD_ACCESS_FAULT};
            bins xcpt_STORE_AMO_ADDRESS_MISALIGNED = {EXCEPTION_STORE_AMO_ADDRESS_MISALIGNED};
            bins xcpt_STORE_AMO_ACCESS_FAULT = {EXCEPTION_STORE_AMO_ACCESS_FAULT};
            bins xcpt_ENV_CALL_USER = {EXCEPTION_ENV_CALL_USER};
            bins xcpt_ENV_CALL_SUPERVISOR = {EXCEPTION_ENV_CALL_SUPERVISOR};
            bins xcpt_ENV_CALL_HYPERVISOR = {EXCEPTION_ENV_CALL_HYPERVISOR};
            bins xcpt_ENV_CALL_MACHINE = {EXCEPTION_ENV_CALL_MACHINE};
            bins xcpt_INST_PAGE_FAULT = {EXCEPTION_INST_PAGE_FAULT};
            bins xcpt_LOAD_PAGE_FAULT = {EXCEPTION_LOAD_PAGE_FAULT};
            bins xcpt_STORE_AMO_PAGE_FAULT = {EXCEPTION_STORE_AMO_PAGE_FAULT};
        }
        
        cp_rob_commit : coverpoint i_rob_commit iff( i_rsn );
    endgroup : cg_rob_barrier

    covergroup cg_rob_exe @(posedge i_clk);
        cp_exe_fu1_complete : coverpoint i_exe_fu1_complete iff( i_rsn );
        cp_exe_fu2_complete : coverpoint i_exe_fu2_complete iff( i_rsn );
        cp_exe_flush : coverpoint i_exe_flush iff( i_rsn );
    endgroup : cg_rob_exe

    covergroup cg_rob_brob @(posedge i_clk);
        cp_brob_inflight : coverpoint i_brob_inflight iff( i_rsn );
        cp_brob_commit : coverpoint i_brob_commit iff( i_rsn );
        cp_brob_nonspec : coverpoint i_brob_nonspec iff( i_rsn );
        cp_brob_branch : coverpoint i_brob_branch iff( i_rsn );
    endgroup : cg_rob_brob
 
    cg_rob u_cg_rob;
    cg_rob_csr  u_cg_rob_csr;
    cg_rob_fetch    u_cg_rob_fetch;
    cg_rob_branch_predict   u_cg_rob_branch_predict;
    cg_rob_decoder  u_cg_rob_decoder;
    cg_rob_frl  u_cg_rob_frl;
    cg_rob_rnm  u_cg_rob_rnm;
    cg_rob_mapper   u_cg_rob_mapper;
    cg_rob_intq u_cg_rob_intq;
    cg_rob_lsq  u_cg_rob_lsq;
    cg_rob_barrier  u_cg_rob_barrier;
    cg_rob_exe  u_cg_rob_exe;
    cg_rob_brob u_cg_rob_brob;


    initial
    begin
        u_cg_rob = new();
        u_cg_rob_csr = new();
        u_cg_rob_fetch = new();
        u_cg_rob_branch_predict = new();
        u_cg_rob_decoder = new();
        u_cg_rob_frl = new();
        u_cg_rob_rnm = new();
        u_cg_rob_mapper = new();
        u_cg_rob_intq = new();
        u_cg_rob_lsq = new();
        u_cg_rob_barrier = new();
        u_cg_rob_exe = new();
        u_cg_rob_brob = new();
    end

/*
FSM
7-bit structure with old destination registers
7-bit structure with current destination registers
FIFO (full, empty, tail and head goes through every position, which values to cover from inside?)
Commit flags (Non-speculative Flag, Dispatch Flag, Issue Flag, Execute Flag, Memory Access Flag, and Exception Flag)
-CSR
CSR interrupt (csr_interrupt_i)
ROB reaches a CSR instruction (rob_csr_p0) - is there a p1?
-FETCH
if_lock
if_flush
-Branch Predict
Miss (bpu_miss_i)
Detect prediction (bpu_predict_i)
P0 branch (rob_branch_p0_o)
P1 branch (rob_branch_p1_o)
-Decoder
Stall (id_stall_req_i)
Flush (id_flush_req)
-FRL
FRL empty ( frl_empty_i)
ROB old destination freed up, all possible values, P0 (rob_odest_p0_o)
ROB old destination freed up, all possible values, P1 (rob_odest_p1_o)
-RNM
Flush (rnm_flush_o)
-SHADOW REGISTER MECHANISM
ROB recovery (rob_recovery_o)
-MAPPER
Dispatch valid (disp_inst_valid_i, only possible values are 00, 01, 11, define 10 as illegal)
Branch P0 (disp_branch_p0_i)
Branch P1 (disp_branch_p1_i)
Old destination P0 (disp_odest_p0_i)
Old destination P1 (disp_odest_p1_i)
Valid memory access dispatched (disp_lsq_actv_i, valid values are 00,01,11, define 10 as illegal)
Dispatch flush (disp_flush_o)
-INTEGER INSTRUCTION QUEUE
Issue conditional branch P0 (issue_cpuvec_br_p0_i)
Issue conditional branch P1 (issue_cpuvec_br_p1_i)
Instruction queue full (intq_full_i)
Instruction queue flush (intq_flush_o)
- LOAD STORE QUEE
LSQ full (lsq_full_i)
Memory instruction completed (dmem_complete_i)
LSQ flush (lsq_flush_o)
ROB memory access instruction P0 (rob_memop_p0_o)
ROB memory access instruction P0 (rob_memop_p0_o)
- BARRIER CONTROL
ROB reaches system instruction P0 (rob_csr_p0)
ROB reaches system instruction P1 (rob_csr_p1)
ROB reached P0 exception and has to issue to CSR (rob_xcpt_p0)
ROB reached P1 exception and has to issue to CSR (rob_xcpt_p1)
ROB P0 exception cause (rob_cause_p0)
ROB P1 exception cause (rob_cause_p1)
ROB P0 commit (rob_commit_p0)
ROB P1 commit (rob_commit_p1)
- EXECUTE
FU1 completes execution (exe_fu1_complete_i)
FU2 completes execution (exe_fu2_complete_i)
Execute flush (exe_flush_o)
- BRANCH ROB
More than one conditional branch in-flight (brob_inflight_i)
Oldest conditional branch commit (brob_commit_i)
Each instruction is cincluded in a non-speculative datapath (brob_nonspec_i two bit, one hot)
ROB head reaches conditional branch anr BRANCH ROB entry is non speculative - P0 (rob_branch_p0_o)
ROB head reaches conditional branch anr BRANCH ROB entry is non speculative - P1 (rob_branch_p1_o)
*/
endmodule
