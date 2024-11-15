`ifndef KA_INTERFACE_SV
`define KA_INTERFACE_SV

`include "uvm_macros.svh"
`include "lagarto_ka.vh"
import core_uvm_pkg::*;
import core_uvm_types_pkg::*;
import EPI_pkg::*;
import lagarto_ka_pkg::*;

// Interface: clock_if
// Clock Interface

parameter CORE_INSTR = INSTR_WIDTH;
parameter CORE_DATA = XREG_WIDTH;
parameter BANK_SIZE = 256;

//Interface: renaming_logic_if
//VPU internal renaming unit interface
interface renaming_unit_if ();
    logic [EPI_pkg::VSEW_WIDTH-1:0]                      commit_vsew_i;                            //vector standard element width
    logic [EPI_pkg::VLEN_WIDTH-1:0]                      commit_vlen_i;
    logic [EPI_pkg::VSTART_WIDTH-1:0]                    roll_back_vstart_o;
    logic                                       is_nop;
endinterface : renaming_unit_if

// Interface: vreg_if
// VPU VREG Interface
interface vreg_if ();
    logic [EPI_pkg::VADDR_WIDTH:0] rename_vdest;
    logic [EPI_pkg::MAX_VLEN-1:0] wb_data;
    logic [EPI_pkg::VLEN_WIDTH-1:0] vl;
    logic incomplete;
endinterface : vreg_if

// Interface: mrf_if
// VPU MRF Interface
interface mrf_if ();
    logic [MAX_VLEN/MIN_SEW-1:0] mask_data; // defined for worst common case LMUL = 1 & SEW = 8 --> 2048 elements --> 2048 mask bits
    logic [EPI_pkg::VLEN_WIDTH-1:0] vl;
    // extra fields for LMUL > 1
endinterface : mrf_if

// Interface: restore_vstart_if
// Interface that contains the signals involved in operations with vstart != 0
interface restore_vstart_if ();
    bit restore_event;
    bit enable;
    bit commit;
endinterface : restore_vstart_if

// Interface: ovi_if
// VPU OVI Interface
interface ovi_if ();

    logic                           clk;
    logic                           rsn;
    logic                           issue_valid;
    logic   [CORE_INSTR-1:0]        issue_instr;
    logic   [CORE_DATA-1:0]         issue_data;
    logic   [SB_WIDTH-1:0]          issue_sb_id;
    logic   [EPI_pkg::CSR_WIDTH-1:0]         issue_csr;
    logic                           issue_credit;
    logic                           dispatch_nxt_sen;
    logic                           dispatch_kill;
    logic   [SB_WIDTH-1:0]          dispatch_sb_id;
    logic                           completed_valid;
    logic   [SB_WIDTH-1:0]          completed_sb_id;
    logic                           completed_illegal;
    logic   [CSR_VLEN_START-1:0]    completed_vstart;
    logic   [XREG_WIDTH-1:0]        completed_dst_reg;
    logic   [FFLAG_WIDTH-1:0]       completed_fflags;
    logic                           completed_vxsat;
    logic                           memop_sync_start;
    logic   [SB_WIDTH-1:0]          memop_start_sb_id;
    logic                           memop_sync_end;
    logic   [SB_WIDTH-1:0]          memop_sb_id;
    logic   [EPI_pkg::CSR_VLEN_WIDTH-1:0]    memop_vstart_vlfof;
    logic                           load_valid;
    logic   [MEM_DATA_WIDTH-1:0]    load_data;
    logic   [SEQ_ID_WIDTH-1:0]      load_seq_id;
    logic                           load_mask_valid;
    logic   [LOAD_MASK-1:0]         load_mask;
    logic                           load_finish_valid;
    logic   [SB_WIDTH-1:0]          load_finish_sb_id;
    logic                           load_finish_no_retry;
    logic                           store_valid;
    logic   [MEM_DATA_WIDTH-1:0]    store_data;
    logic   [SB_WIDTH-1:0]          store_sb_id;
    logic                           store_credit;
    logic                           mask_idx_valid;
    logic   [ITEM_WIDTH-1:0]        mask_idx_item;
    logic                           mask_idx_last_idx;
    logic   [SB_WIDTH-1:0]          mask_idx_sb_id;
    logic                           mask_idx_credit;
    logic                           dbg_re_i;
    logic                           dbg_we_i;
    logic   [DBG_ADDR_WIDTH-1:0]    dbg_address_i;
    logic   [DBG_DATA_WIDTH-1:0]    dbg_write_data_i;
    logic   [DBG_DATA_WIDTH-1:0]    dbg_read_data_o;

`ifdef GLS
    clocking cb @(posedge clk);
        default input #1step output #`IN_DELAY;
        inout clk;
        output issue_valid, issue_instr, issue_data, issue_sb_id, issue_csr;
        input issue_credit;
        output dispatch_sb_id, dispatch_nxt_sen, dispatch_kill;
        input completed_sb_id, completed_fflags, completed_valid, completed_vxsat, completed_dst_reg, completed_vstart, completed_illegal;
        input memop_sync_start, memop_start_sb_id;
        inout memop_sync_end, memop_sb_id, memop_vstart_vlfof;
        output load_valid, load_data, load_seq_id, load_mask_valid, load_mask;
        input load_finish_valid, load_finish_sb_id, load_finish_no_retry;
        inout store_credit;
        input store_valid, store_data, store_sb_id;
        inout mask_idx_credit;
        input mask_idx_valid, mask_idx_item, mask_idx_last_idx, mask_idx_sb_id;
    endclocking
`endif

endinterface : ovi_if

interface vpu_if (ovi_if ovi, renaming_unit_if renaming_unit_if, vreg_if vreg_if, restore_vstart_if restore_vstart_if);
`include "oviProtocol.sv"
protocol m_protocol_class = new();

endinterface : vpu_if
`endif
