`include "lagarto_ka.vh"
`include "uvm_macros.svh"
import uvm_pkg::*;

module sva_csr
(
    input logic clk_i,
    input logic rsn_i,
    input logic `PRIV_LVL   csr_priv_lvl_i,
    input logic `DWORD      csr_rw_rdata_i,
    input logic             csr_csr_stall_i,
    input logic             csr_xcpt_i,
    input logic `XCPT_CAUSE csr_xcpt_cause_i,
    input logic             csr_eret_i,
    input logic `vADDR      csr_evec_i,
    input logic             csr_interrupt_i,
    input logic `XCPT_CAUSE csr_interrupt_cause_i,
    input logic csr_csr_replay_i,
    input logic csr_tval_i,
    input logic [11:0]                csr_rw_addr_o,
    input logic [2:0]                 csr_rw_cmd_o,
    input logic `DWORD                csr_rw_wdata_o,
    input logic                       csr_exception_o,
    input logic `DWORD                csr_cause_o,
    input logic `vADDR                csr_pc_o,
    input logic                       csr_retire_o
);

    `define assertion_level_report(msg) \
        `uvm_fatal("sva_csr", msg)

    `define s_if_a_b_is_known(a, b) \
        a |-> !$isunknown(b)

    property p_reset_csr_in();
        @(posedge rsn_i)
        rsn_i |-> !(
        $isunknown($past(csr_priv_lvl_i))        ||
        $isunknown($past(csr_rw_rdata_i))        ||
        $isunknown($past(csr_csr_stall_i))       ||
        $isunknown($past(csr_xcpt_i))            ||
        $isunknown($past(csr_xcpt_cause_i))      ||
        $isunknown($past(csr_eret_i))            ||
        $isunknown($past(csr_evec_i))            ||
        $isunknown($past(csr_interrupt_i))       ||
        $isunknown($past(csr_interrupt_cause_i)) ||
        $isunknown($past(csr_csr_replay_i))      ||
        $isunknown($past(csr_tval_i)));
    endproperty
    a_reset_csr_in : assert property (disable iff (!rsn_i) p_reset_csr_in()) else `assertion_level_report($sformatf("%d a_reset_csr_in failed", $stime));

    property p_reset_csr_out();
        @(posedge rsn_i)
       rsn_i |-> !(
        $isunknown($past(csr_rw_addr_o))     ||
        $isunknown($past(csr_rw_cmd_o))      ||
        $isunknown($past(csr_rw_wdata_o))    ||
        $isunknown($past(csr_exception_o))   ||
        $isunknown($past(csr_cause_o))       ||
        $isunknown($past(csr_pc_o))          ||
        $isunknown($past(csr_retire_o)));
    endproperty
    a_reset_csr_out : assert property (disable iff (!rsn_i) p_reset_csr_out()) else `assertion_level_report($sformatf("%d a_reset_csr_out failed", $stime));

    // 2.1 Exception not unkown
    // If csr_exception_o is '1', csr_cause_o and csr_pc_o cannot be unknown.
    property p_csr_exc_unk();
        @(posedge clk_i)
        `s_if_a_b_is_known(csr_exception_o, csr_cause_o) and `s_if_a_b_is_known(csr_exception_o, csr_pc_o);
    endproperty
    a_csr_exc_unk : assert property (disable iff (!rsn_i) p_csr_exc_unk()) else `assertion_level_report($sformatf("%d a_csr_exc_unk failed", $stime));

    // 2.2 Exception detected
    // For each csr_exception_o set to '1', from the next cycle on there will be a csr_xcpt_i set to '1'.
    property p_csr_exc_detected();
        @(posedge clk_i)
        csr_xcpt_i |-> csr_exception_o[->1];
    endproperty
    a_csr_exc_detected : assert property (disable iff (!rsn_i) p_csr_exc_detected()) else `assertion_level_report($sformatf("%d a_csr_exc_detected failed", $stime));

    // 2.3 Exception return not unknown
    // If csr_eret_i is '1', csr_evec_i cannot be unknown.
    property p_csr_exc_ret_unk();
        @(posedge clk_i)
        `s_if_a_b_is_known(csr_eret_i, csr_evec_i);
    endproperty
    a_csr_exc_ret_unk : assert property (disable iff (!rsn_i) p_csr_exc_ret_unk()) else `assertion_level_report($sformatf("%d a_csr_exc_ret_unk failed", $time));

    // 2.4 Exception return
    // For each csr_exception_o set to '1', from the next cycle on there will be a csr_eret_i set to '1'.
    property p_csr_exc_ret();
        @(posedge clk_i)
        csr_eret_i |-> csr_exception_o[->1];
    endproperty
    a_csr_exc_ret : assert property (disable iff (!rsn_i) p_csr_exc_ret()) else `assertion_level_report($sformatf("%d a_csr_exc_ret failed", $time));

    // 2.5 Interrupt not unknown
    // If csr_interrupt_i is '1', csr_interrupt_cause_i cannot be unknown.
    property p_csr_int_unk();
        @(posedge clk_i)
        `s_if_a_b_is_known(csr_interrupt_i, csr_interrupt_cause_i);
    endproperty
    a_csr_int_unk : assert property (disable iff (!rsn_i) p_csr_int_unk()) else `assertion_level_report($sformatf("%d a_csr_int_unk failed", $time));

    // 2.6 (need to do it once CSR specifications are finished).
    //
    //
    //
    //

    // 2.7 CSR Operations not unknown
    // At any point in time, the csr_rw_cmd_o, csr_rw_addr_o and csr_rw_wdata_o signals cannot be unknown.
    property p_csr_op_unk();
        @(posedge clk_i)
        !($isunknown(csr_rw_cmd_o) || $isunknown(csr_rw_addr_o) || $isunknown(csr_rw_wdata_o));
    endproperty
    a_csr_op_unk : assert property (disable iff (!rsn_i) p_csr_op_unk()) else `assertion_level_report($sformatf("%d a_csr_op_unk failed", $time));

    // 2.8 Valid privilege level
    // At any point in time, the csr_priv_lvl_i signal must contain a valid value (all except for "10").
    property p_csr_priv_lvl();
        @(posedge clk_i)
        csr_priv_lvl_i != 'b10;
    endproperty
    a_csr_priv_lvl : assert property (disable iff (!rsn_i) p_csr_priv_lvl()) else `assertion_level_report($sformatf("%d a_csr_priv_lvl failed", $time));

endmodule : sva_csr
