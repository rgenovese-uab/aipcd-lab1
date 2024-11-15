import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_mapper(
    input               i_clk,
    input               i_rsn, 
    input   `OPVEC      i_opvec_p0,                     //id_opvec_p0_i
    input   `OPVEC      i_opvec_p1,                     //id_opvec_p1_i
    input               i_disp_lock,                    //disp_lock_i
    input               i_disp_flush,                   //disp_flush_i
    input   `ROB_ADDR   i_rob_entry_p0,                 //rob_new_entry_p0_i
    input   `ROB_ADDR   i_rob_entry_p1,                 //rob_new_entry_p1_i
    input   `BrROB_ADDR i_brob_entry_p0,                //brob_new_entry_p0_i
    input   `BrROB_ADDR i_brob_entry_p1,                //brob_new_entry_p1_i
    input               i_disp_barrier_xcpt_p0,         //disp_barrier_xcpt_p0_o
    input               i_disp_barrier_xcpt_p1,         //disp_barrier_xcpt_p1_o
    input   `XCPT_CAUSE i_disp_barrier_xcpt_cause_p0,   //disp_barrier_cause_p0_o
    input   `XCPT_CAUSE i_disp_barrier_xcpt_cause_p1,   //disp_barrier_cause_p1_o
    input   `pREG       i_disp_odest_p0,                //disp_odest_p0_o
    input   `pREG       i_disp_odest_p1,                //disp_odest_p1_o
    input   `pREG       i_disp_pdest_p0,                //disp_pdest_p0_o
    input   `pREG       i_disp_pdest_p1                 //disp_pdest_p1_o
  

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
    
    covergroup  cg_mapper @(posedge i_clk);
        //cp_p0_vectorial : coverpoint i_opvec_p0[17] iff( i_rsn ); //to check and disable
        //cp_p0_fp : coverpoint i_opvec_p0[16] iff( i_rsn ); //to check and disable
        cp_p0_csr : coverpoint i_opvec_p0[15] iff( i_rsn );
        cp_p0_mem : coverpoint i_opvec_p0[14] iff( i_rsn );
        cp_p0_cpu : coverpoint i_opvec_p0[13] iff( i_rsn );

        //cp_p1_vectorial : coverpoint i_opvec_p1[17] iff( i_rsn ); //to check and disable
        //cp_p1_fp : coverpoint i_opvec_p1[16] iff( i_rsn ); //to check and disable
        cp_p1_csr : coverpoint i_opvec_p1[15] iff( i_rsn );
        cp_p1_mem : coverpoint i_opvec_p1[14] iff( i_rsn );
        cp_p1_cpu : coverpoint i_opvec_p1[13] iff( i_rsn );

        cp_disp_lock : coverpoint i_disp_lock iff( i_rsn );
        cp_disp_flush : coverpoint i_disp_flush iff( i_rsn );

        cp_rob_entry_p0 : coverpoint i_rob_entry_p0 iff( i_rsn );
        cp_rob_entry_p1 : coverpoint i_rob_entry_p1 iff( i_rsn );

        cp_brob_entry_p0 : coverpoint i_brob_entry_p0 iff( i_rsn );
        cp_brob_entry_p1 : coverpoint i_brob_entry_p1 iff( i_rsn );

        cp_xcpt_p0 : coverpoint i_disp_barrier_xcpt_p0 iff( i_rsn );
        cp_xcpt_p1 : coverpoint i_disp_barrier_xcpt_p1 iff( i_rsn );

        cp_xcpt_cause_p0 : coverpoint i_disp_barrier_xcpt_cause_p0 iff( i_rsn && i_disp_barrier_xcpt_p0 ){
            bins illegal_instruction    = {EXCEPTION_ILLEGAL_INST };
            bins exception_breakpoint   = {EXCEPTION_BREAKPOINT};
            bins exception_env_call_machine   = {EXCEPTION_ENV_CALL_MACHINE};
            bins exception_env_call_supervisor   = {EXCEPTION_ENV_CALL_SUPERVISOR};
            bins exception_env_call_user   = {EXCEPTION_ENV_CALL_USER};
            bins exception_env_call_hypervisor   = {EXCEPTION_ENV_CALL_HYPERVISOR};
            bins cause_zero         = {XCPT_CAUSE_ZERO};
        }

        cp_xcpt_cause_p1 : coverpoint i_disp_barrier_xcpt_cause_p1 iff( i_rsn && i_disp_barrier_xcpt_p0 ){
            bins illegal_instruction    = {EXCEPTION_ILLEGAL_INST };
            bins exception_breakpoint   = {EXCEPTION_BREAKPOINT};
            bins exception_env_call_machine   = {EXCEPTION_ENV_CALL_MACHINE};
            bins exception_env_call_supervisor   = {EXCEPTION_ENV_CALL_SUPERVISOR};
            bins exception_env_call_user   = {EXCEPTION_ENV_CALL_USER};
            bins exception_env_call_hypervisor   = {EXCEPTION_ENV_CALL_HYPERVISOR};
            bins cause_zero         = {XCPT_CAUSE_ZERO};
        }

        cp_disp_odest_p0 : coverpoint i_disp_odest_p0 iff( i_rsn );
        cp_disp_odest_p1 : coverpoint i_disp_odest_p1 iff( i_rsn );
        cp_disp_pdest_p0 : coverpoint i_disp_pdest_p0 iff( i_rsn );
        cp_disp_pdest_p1 : coverpoint i_disp_pdest_p1 iff( i_rsn );
    endgroup :  cg_mapper

 
    cg_mapper u_cg_mapper;


    initial
    begin
        u_cg_mapper = new();
    end

/*
MSBs of the operational vector [17] vectorial, [16] floating-point, [15] csr, [14] memory access, [13] cpu
Mapper is stalled (disp_lock_i)
Mapper is flushed (disp_flush_i)
All ROB entries are assigned for instructions 1 and 2 (rob_new_entry_p0_i, rob_new_entry_p1_i)
All branch ROB entries are assigned for instructiosn 1 and 2 (brob_new_entry_p0_i, brob_new_entry_p1_i) 
Dispatch exception (disp_xcpt_p0_o, disp_xcpt_p1_o)
All old physicial destinations are dispatched to the rob (disp_odest_p0_o, disp_odest_p1_o)
All physical destinations are dispatched to the rob (disp_pdest_p0_o, disp_pdest_p1_o)
*/
endmodule
