import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_dcache(
    input                               i_clk,
    input                               i_rsn, 
   
    input                               i_dmem_req_valid,       //io_dmem_req_valid
    input   [4      : 0]                i_dmem_req_cmd,         //io_dmem_req_bits_cmd
    input   [39     : 0]                i_dmem_req_addr,        //io_dmem_req_bits_addr
    //input   [3      : 0]                i_dmem_req_op_type,     //io_dmem_req_bits_typ
    input                               i_dmem_invalidate,      //io_dmem_invalidate_lr
    input                               i_dmem_kill,            //io_dmem_req_bits_kill
    input                               i_dmem_reissue,         //io_dmem_resp_bits_nack
    input                               i_dmem_misaligned_store,//io_dmem_xcpt_ma_st
    input                               i_dmem_misaligned_load, //io_dmem_xcpt_ma_ld
    input                               i_dmem_store_page_fault,//io_dmem_xcpt_pf_st
    input                               i_dmem_load_page_fault  //io_dmem_xcpt_pf_ld

);
    
    covergroup  cg_dcache @(posedge i_clk);
        cp_dmem_req_cmd : coverpoint i_dmem_req_cmd iff( i_rsn && i_dmem_req_valid ){
            bins lr         = {5'b00110};
            bins sc         = {5'b00111};
            bins amoswap    = {5'b00100};
            bins amoadd     = {5'b01000};
            bins amoxor     = {5'b01001};
            bins amoand     = {5'b01011};
            bins amoor      = {5'b01010};
            bins amomin     = {5'b01100};
            bins amomax     = {5'b01101};
            bins amominu    = {5'b01110};
            bins amomaxu    = {5'b01111};
            bins load       = {5'b00000};
            bins store      = {5'b00001};
        }

        cp_dmem_invalidate: coverpoint i_dmem_invalidate iff( i_rsn );
        cp_dmem_kill: coverpoint i_dmem_kill iff( i_rsn );
        cp_dmem_reissue: coverpoint i_dmem_reissue iff( i_rsn );
        cp_dmem_misaligned_store: coverpoint i_dmem_misaligned_store iff( i_rsn );
        cp_dmem_misaligned_load: coverpoint i_dmem_misaligned_load iff( i_rsn );
        cp_dmem_store_page_fault: coverpoint i_dmem_store_page_fault iff( i_rsn );
        cp_dmem_load_page_fault: coverpoint i_dmem_load_page_fault iff( i_rsn );
        cp_dmem_access_fault_xcpt : coverpoint i_dmem_req_addr iff( i_rsn && i_dmem_req_valid ){
            illegal_bins access_fault_xcpt = {i_dmem_req_addr[39] != i_dmem_req_addr[38]};      //[TOCHECK]
        }
    endgroup :  cg_dcache

 
    cg_dcache u_cg_dcache;


    initial
    begin
        u_cg_dcache = new();
    end

/*
When dmem_req_valid_o, all possible memory commands occur (dmem_req_cmd_o) and operation type (dmem_op_type_o)
An invalidate occurs (dmem_req_invalidate_lr_o)
A kill occurs (dmem_req_bits_kill_o)
A re-issue (nack event) occurs (dmem_resp_bits_nack_i)
A misaligned store exception occurs (dmem_xcpt_ma_st_i)
A misaligned load exception occurs (dmem_xcpt_ma_ld_i)
A store page fault exception occurs (dmem_xcpt_pf_st_i)
A load page fault exception occurs (dmem_xcpt_pf_ld_i)
An access-fault exception occurs (memory effective address bits 63-39 are not equal to bit 38)
*/
endmodule
