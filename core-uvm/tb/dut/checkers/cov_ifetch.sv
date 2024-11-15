import lagarto_pkg::*;
`include "lagarto_ka.vh" //constants, entities, config


module cov_ifetch(
    input               i_clk,
    input               i_rsn,
    input `vADDR        i_pc_req_int,       //pc_req_int
    input `vADDR        i_pc_offset,        //next_pc_offset_int
    input               i_invalidate,       //barrier_icache_invalidate_i
    input               i_kill,             //icache_req_bits_kill_o
    input               i_valid_response,   //datablock_valid_int
    input               i_id_jal_p0,        //id_jal_p0_i
    input               i_id_jal_p1,        //id_jal_p1_i
    input               i_issue_jalr_p0,    //issue_jalr_p0_i
    input               i_issue_jalr_p1,    //issue_jalr_p1_i
    input               i_bpu_miss,         //bpu_miss_i
    input               i_bpu_predict,      //bpu_predict_i
    input               i_rob_recovery,     //rob_recovery_i
    input               i_pc_lock,          //pc_lock_i
    input               i_if_lock,          //if_lock_i
    input               i_if_flush,         //if_flush_i
    input               i_id_fence,         //barrier_icache_invalidate_i
    input               i_if_xcpt,          //if_xcpt_o
    input `XCPT_CAUSE   i_if_xcpt_cause,    //if_xcpt_cause_o
    input               i_tlb_xcpt          //tlb_resp_xcpt_if_i

);

    covergroup cg_if @(posedge i_clk);
        cp_number_instructions : coverpoint i_pc_req_int[3:0] iff ( i_rsn ){
            bins two_lsb   = {4'b0000};
            bins two_mid   = {4'b0100};
            bins two_msb   = {4'b1000};
            bins one_zero  = {4'b1100};
            bins two_zero  = {4'b0001, 4'b0010, 4'b0011, 4'b0101, 4'b0110, 4'b0111,
                           4'b1001, 4'b1010, 4'b1011, 4'b1101, 4'b1110, 4'b1111};
        }

        cp_pc_increment : coverpoint i_pc_offset iff ( i_rsn ){
            bins eigth = {8};
            bins four  = {4};
            illegal_bins ill = default;
        }

        cp_invalidate : coverpoint i_invalidate iff( i_rsn );
        cp_kill : coverpoint i_kill iff ( i_rsn );
        cp_valid_response: coverpoint i_valid_response iff( i_rsn );
        cp_recovery : coverpoint i_rob_recovery iff( i_rsn );
        cp_pc_lock : coverpoint i_pc_lock iff( i_rsn );
        cp_if_lock : coverpoint i_if_lock iff( i_rsn );
        cp_if_flush : coverpoint i_if_flush iff( i_rsn );
        cp_id_fence : coverpoint i_id_fence iff( i_rsn );
        cp_if_xcpt : coverpoint i_if_xcpt iff( i_rsn );
        cp_if_xcpt_cause : coverpoint i_if_xcpt_cause iff( i_rsn && i_if_xcpt){
            bins fault_fetch        = {`FAULT_FETCH };
            bins misaligned_fetch   = {`MISALIGNED_FETCH};
            bins cause_zero         = {`XCPT_CAUSE_ZERO};

        }
        cp_tlb_xcpt : coverpoint i_tlb_xcpt iff( i_rsn );

    endgroup : cg_if

    covergroup cg_jump_branch @(posedge i_clk);
        cp_jal_0 : coverpoint i_id_jal_p0 iff( i_rsn );
        cp_jal_1 : coverpoint i_id_jal_p1 iff( i_rsn );
        cp_jalr_0 : coverpoint i_issue_jalr_p0 iff( i_rsn );
        cp_jalr_1 : coverpoint i_issue_jalr_p1 iff( i_rsn );
        cp_miss : coverpoint i_bpu_miss iff( i_rsn );
        cp_predict : coverpoint i_bpu_predict iff( i_rsn );
    endgroup : cg_jump_branch

    cg_if u_cg_if;
    cg_jump_branch u_cg_jump_branch;

    initial
    begin
        u_cg_if = new();
        u_cg_jump_branch = new();
    end

/*
Fill instruction fetch queue (full/empty) -> can't find queue
Fetch 1 to 4 instructions (sending NOPs to fill the fetch-window gaps) -> cp_number_instructions
PC values (only increased by 8 or 4, define other values as illegal)
Cover FSM states -> no FSM
Cover transtion t3 for each possible cause (kill, invalidation or response)
Jump/Branch control signals (id_jal_p0_i, id_jal_p1_i, issue_jalr_p0_i, issue_jalr_p1_i, bpu_miss_i, bpu_predict_i)
A recovery context happens (rob_recovery_i)
PC is stalled (pc_lock_i)
Fetch is stalled (if_lock_i)
Fetch is flushed (if_flush_i)
A fence occurred (id_fence_i)
An exception occurred (rob_xcpt_i)
Fetch exception (if_xcpt_o) and its cause (if_xcpt_cause_o)
Instruction cache miss (icache_miss_i)
TLB miss (tlb_resp_miss_i) and exception (tlb_resp_xcpt_if_i)
*/
endmodule
