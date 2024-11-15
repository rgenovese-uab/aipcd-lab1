//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_uvm_pkg
// File          : core_uvm_pkg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This is pakage file. This include all the env file 
//                 necessary for sync. Also In pkg file order must be maintain 
//                 in "bottom to top manner" otherwise errors will be there.
//----------------------------------------------------------------------
`ifndef CORE_UVM_PKG
`define CORE_UVM_PKG

package core_uvm_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import dut_pkg::*;
    import core_uvm_types_pkg::*;
    localparam ECALL_SENTINEL = 32'h00000073;

    typedef enum {SARGANTANA, LAGARTO_KA, LAGARTO_OX} core_type_t;

    `include "uvm_agents/im_uvc/fetch_trans.sv"
    `include "uvm_agents/im_uvc/completed_trans.sv"
    `include "uvm_agents/im_uvc/core_store_trans.sv"
    `include "utils/dut_trans.sv"
    `include "utils/iss_trans.sv"
    `include "utils/rvv_dut_tx.sv"

     `include "uvm_agents/im_uvc/core_completed_item.sv"

    // Config
    `include "uvm_agents/im_uvc/core_im_agent_cfg.sv"
    `include "uvm_agents/icache_uvc/core_icache_cfg.sv"
    `include "uvm_agents/dcache_uvc/core_dcache_cfg.sv"
    `include "uvm_agents/int_uvc/core_int_cfg.sv"
    `include "core_env_cfg.sv"

    // Monitors
    `include "uvm_agents/im_uvc/core_fetch_monitor.sv"
    `include "uvm_agents/im_uvc/core_completed_monitor.sv"
    `include "core_csr_monitor.sv"

    `include "uvm_agents/im_uvc/core_im_agent.sv"

    `include "ref_model/core_iss_wrapper.sv"
    `include "ref_model/core_spike.sv"

    // Catcher
    `include "core_catcher.sv"

    // Instruction Management
    `include "uvm_agents/im_uvc/core_im.sv"
    //Scoreboard
    `include "core_scoreboard.sv"

    `include "memory_model/core_mem_model.sv"

    // Env with icache
    `include "uvm_agents/icache_uvc/core_icache_trans.sv"
    `include "uvm_agents/icache_uvc/core_icache_rand_trans.sv"
    typedef uvm_sequencer #(core_icache_rand_trans) core_icache_seqr;
    `include "uvm_agents/icache_uvc/seq_lib/core_icache_seq.sv"
    `include "uvm_agents/icache_uvc/core_icache_monitor.sv"
    `include "uvm_agents/icache_uvc/core_icache_driver.sv"
    `include "uvm_agents/icache_uvc/core_icache_agent.sv"

    // Env with dcache
    `include "uvm_agents/dcache_uvc/core_dcache_trans.sv"
    `include "uvm_agents/dcache_uvc/core_dcache_rand_trans.sv"
    `include "uvm_agents/dcache_uvc/core_dcache_store_trans.sv"
    typedef uvm_sequencer #(core_dcache_rand_trans) core_dcache_seqr;
    `include "uvm_agents/dcache_uvc/seq_lib/core_dcache_seq.sv"
    `include "ref_model/core_dcache_ref_model.sv"
    `include "uvm_agents/dcache_uvc/core_dcache_monitor.sv"
    `include "uvm_agents/dcache_uvc/core_dcache_driver.sv"
    `include "uvm_agents/dcache_uvc/core_dcache_agent.sv"

    // Env with interrupt agent
    `include "uvm_agents/int_uvc/core_int_trans.sv"
    typedef uvm_sequencer #(core_int_trans) core_int_seqr;
    `include "uvm_agents/int_uvc/seq_lib/core_int_seq.sv"
    `include "uvm_agents/int_uvc/core_int_monitor.sv"
    `include "uvm_agents/int_uvc/core_int_driver.sv"
    `include "uvm_agents/int_uvc/core_int_agent.sv"

    `include "core_env.sv"

    `include "../tests/verif_tests/core_base_test.sv"
    `include "../tests/verif_tests/core_bin_test.sv"

endpackage : core_uvm_pkg

`endif
