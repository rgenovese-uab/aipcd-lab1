`ifndef KA_VPU_UVM_PKG
`define KA_VPU_UVM_PKG

`include "uvm_macros.svh"

package vpu_uvm_pkg;
    import core_uvm_types_pkg::*;
    import uvm_pkg::*;
    import EPI_pkg::*;

    `include "uvm_macros.svh"

    `include "ovi_cfg.sv"
    typedef uvm_sequencer #(utils_pkg::vpu_ins_tx) vpu_seqr;
    `include "vpu_agent_cfg.sv"
    `include "vpu_monitor_post.sv"
    `include "vpu_isa_scoreboard.sv"
    `include "vpu_agent.sv"
    
endpackage : vpu_uvm_pkg

`endif
