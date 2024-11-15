import riscv_pkg::*;
// `include "lagarto_ka.vh" //constants, entities, config

module cov_csr(
    input               i_clk,
    input               i_rsn, 
    input               i_csr_exception,
    input   [63:0]      i_csr_cause,
    input   [5:0]       i_csr_rw_cmd,
    input               i_csr_eret,
    input               i_csr_stall,
    input   [63:0]      i_csr_interrupt_cause,
    input               i_csr_interrupt,
    input   [1 : 0]     i_priv_lvl
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

    covergroup  cg_csr @(posedge i_clk);
        //[TOCHECK if these are all the possible exceptions]
        cp_csr_exception_cause : coverpoint i_csr_cause iff( i_rsn && i_csr_exception ){
            bins xcpt_INST_ADDRESS_MISALIGNED     = {EXCEPTION_INST_ADDRESS_MISALIGNED};
            bins xcpt_INST_ACCESS_FAULT           = {EXCEPTION_INST_ACCESS_FAULT};
            bins xcpt_ILLEGAL_INST                = {EXCEPTION_ILLEGAL_INST};
            bins xcpt_BREAKPOINT                  = {EXCEPTION_BREAKPOINT};
            bins xcpt_LOAD_ADDRESS_MISALIGNED     = {EXCEPTION_LOAD_ADDRESS_MISALIGNED};
            bins xcpt_LOAD_ACCESS_FAULT           = {EXCEPTION_LOAD_ACCESS_FAULT};
            bins xcpt_STORE_AMO_ADDRESS_MISALIGNED= {EXCEPTION_STORE_AMO_ADDRESS_MISALIGNED};
            bins xcpt_STORE_AMO_ACCESS_FAULT      = {EXCEPTION_STORE_AMO_ACCESS_FAULT};
            bins xcpt_ENV_CALL_USER               = {EXCEPTION_ENV_CALL_USER};
            bins xcpt_ENV_CALL_SUPERVISOR         = {EXCEPTION_ENV_CALL_SUPERVISOR};
            bins xcpt_ENV_CALL_HYPERVISOR         = {EXCEPTION_ENV_CALL_HYPERVISOR};
            bins xcpt_ENV_CALL_MACHINE            = {EXCEPTION_ENV_CALL_MACHINE};
            bins xcpt_INST_PAGE_FAULT             = {EXCEPTION_INST_PAGE_FAULT};
            bins xcpt_LOAD_PAGE_FAULT             = {EXCEPTION_LOAD_PAGE_FAULT};
            bins xcpt_STORE_AMO_PAGE_FAULT        = {EXCEPTION_STORE_AMO_PAGE_FAULT};
        }
        
        cp_csr_rw_command : coverpoint i_csr_rw_cmd iff( i_rsn && i_csr_exception ){
            bins write = { 3'b001 };
            bins set = { 3'b010 };
            bins clear = { 3'b011 };
            bins read = { 3'b101 };            
        }

        cp_csr_eret : coverpoint i_csr_eret iff( i_rsn );
        cp_csr_stall: coverpoint i_csr_stall iff( i_rsn );

        //[TOCHECK] if these are all possible interrupts
        cp_csr_interrupt : coverpoint i_csr_interrupt_cause iff( i_rsn && i_csr_interrupt ){
            bins external_interrupt = { M_EXT_INTERRUPT };
            bins sw_interrupt = {M_SW_INTERRUPT };
            bins timer_interrupt = {M_TIMER_INTERRUPT };
        }

        cp_priv_lvl : coverpoint i_priv_lvl iff( i_rsn ){
            bins lvl_m = { riscv_pkg::PRIV_LVL_M };
            bins lvl_s = { riscv_pkg::PRIV_LVL_S };
            bins lvl_u = { riscv_pkg::PRIV_LVL_U };
        }

    endgroup :  cg_csr

 
    cg_csr u_cg_csr;


    initial
    begin
        u_cg_csr = new();
    end

/*
FSM
xt1 for exception or interruption
xAll possible exception causes
xt5 data move
xt7 data write
xCSR is stalled (csrh_lock_i)
xCSR is flushed (csrh_flush_i)
xAll possible exception causes (csr_cause_o) when csr_xcpt_o is high (and also csr_exception_o)
xAll possible CSR commands (csr_rw_cmd_o) when csr_exception_o is high
xException return occurs (csr_eret_i)
xA CSR stall happens (csr_stall_i)

Interface
xWhen csr_exception_o, check every possible exception cause (csr_cause_o)
xWhen csr_interrupt_i, check every possible interruption cause (csr_interrupt_cause_i)
*/
endmodule
