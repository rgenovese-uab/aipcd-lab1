import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_idecode#(
    parameter FETCH_WIDTH      = 2,
    parameter XCPT_CAUSE_WIDTH = 64,
    parameter PCK_XCPT_CAUSE   = FETCH_WIDTH * XCPT_CAUSE_WIDTH
    )(
    input                               i_clk,
    input                               i_rsn,
    input   [FETCH_WIDTH    - 1 : 0]    i_if_inst_val,  //if_inst_val_i
    input                               i_if_xcpt,      //if_xcpt_i
    input                               i_id_illegal,   //id_illegal
    input                               i_id_flush,     //id_flush_i
    input                               i_id_lock,      //id_lock_i
    input   [FETCH_WIDTH    - 1 : 0]    i_id_stall_req, //id_stall_req
    input   [FETCH_WIDTH    - 1 : 0]    i_id_flush_req, //id_flush_req
    input   [FETCH_WIDTH    - 1 : 0]    i_id_xcpt,      //id_xcpt_o
    input   [PCK_XCPT_CAUSE - 1 : 0]    i_id_xcpt_cause,//id_xcpt_cause_o
    input                               i_csr_interrupt //csr_interrupt_i

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


    covergroup cg_idecode @(posedge i_clk);
        cp_if_inst_val : coverpoint i_if_inst_val iff ( i_rsn ){ //only 1 2 3
            bins all[] = {0,1,3};
        } 
        cp_if_xcpt : coverpoint i_if_xcpt iff( i_rsn );
        cp_id_illegal : coverpoint i_id_illegal iff ( i_rsn );
        cp_id_flush : coverpoint i_id_flush iff ( i_rsn );
        cp_id_lock  : coverpoint i_id_lock  iff( i_rsn );
        cp_id_stall_req  : coverpoint i_id_stall_req  iff( i_rsn );
        cp_id_flush_req  : coverpoint i_id_flush_req  iff( i_rsn );
        cp_id_xcpt_0  : coverpoint i_id_xcpt[0]  iff( i_rsn );
        cp_id_xcpt_1  : coverpoint i_id_xcpt[1]  iff( i_rsn );
        cp_id_xcpt_cause_0 : coverpoint i_id_xcpt_cause[XCPT_CAUSE_WIDTH - 1 : 0] iff( i_rsn && i_id_xcpt[0]){
            bins illegal_instruction    = {EXCEPTION_ILLEGAL_INST };
            bins exception_breakpoint   = {EXCEPTION_BREAKPOINT};
            bins exception_env_call_machine   = {EXCEPTION_ENV_CALL_MACHINE};
            bins exception_env_call_supervisor   = {EXCEPTION_ENV_CALL_SUPERVISOR};
            bins exception_env_call_user   = {EXCEPTION_ENV_CALL_USER};
            bins exception_env_call_hypervisor   = {EXCEPTION_ENV_CALL_HYPERVISOR};
            bins cause_zero         = {XCPT_CAUSE_ZERO};

        }

        cp_id_xcpt_cause_1 : coverpoint i_id_xcpt_cause[XCPT_CAUSE_WIDTH*2 - 1 : XCPT_CAUSE_WIDTH] iff( i_rsn && i_id_xcpt[1]){
            bins illegal_instruction    = {EXCEPTION_ILLEGAL_INST };
            bins exception_breakpoint   = {EXCEPTION_BREAKPOINT};
            bins exception_env_call_machine   = {EXCEPTION_ENV_CALL_MACHINE};
            bins exception_env_call_supervisor   = {EXCEPTION_ENV_CALL_SUPERVISOR};
            bins exception_env_call_user   = {EXCEPTION_ENV_CALL_USER};
            bins exception_env_call_hypervisor   = {EXCEPTION_ENV_CALL_HYPERVISOR};
            bins cause_zero         = {XCPT_CAUSE_ZERO};

        }
        cp_csr_interrupt  : coverpoint i_csr_interrupt  iff( i_rsn );

    endgroup : cg_idecode

    cg_idecode u_cg_idecode;

    initial
    begin
        u_cg_idecode = new();
    end




/*
Cover FSM states (define others as illegal)
Cover t1 for valid instruction or exception
Cover t5 for illegal instrucion, ecall, break
Cover t8 for flush
Decode is stalled (id_lock_i)
Decode is flushed (id_flush_i)
Request ROB to stall (id_stall_req_o)
Reques ROB to flush (id_flush_req_o)
Decode exception (id_xcpt_o) and its cause (id_xcpt_cause_o)
CSR interrupt (csr_interrupt_i)
*/
endmodule
