//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : test_harness
// File          : test_harness.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This module includes all TOP DUT (lagarto_ka_core + CSR).
//----------------------------------------------------------------------
`include "uvm_macros.svh"
import uvm_pkg::*;
import uvmt_pkg::*;
import mmu_pkg::*;
import hpdcache_pkg::*;
import drac_pkg::*;
import core_uvm_pkg::*;
import core_uvm_types_pkg::*;
import dut_pkg::*;

module test_harness;

// Interfaces

    // Variable: regfile_if
    // Core registers virtual interface
    core_regfile_if  reg_if();

    // Variable: fetch_if
    // Instruction start virtual interface
    core_fetch_if fetch_if();

    core_completed_if completed_if();

    // Variable: clock_if
    // Clock virtual interface
    clock_if clock_if();

    // Variable: reset_if
    // Reset virtual interface
    reset_if reset_if();

    // Variable: int_if
    // DUT interrupt interface
    int_if int_if();

    // Variable: icache_if
    // DUT intruction_cache interface
    icache_if ic_if();

    // Variable: dcache_if
    // DUT data_cache interface
    dcache_if dc_if();

    // Variable: csr_tohost_if
    // CSR TOHOST if
    csr_tohost_if tohost_if();

    // Variable: clearmip_if
    // CSR CLEARMIP if
    csr_clearmip_if clearmip_if();

// Variables

    uint64_t io_reset_address;
    logic [1:0] csr_priv_lvl, ld_st_priv_lvl;

    logic [drac_pkg::CSR_ADDR_SIZE-1:0] addr_csr_hpm;
    logic [63:0]              data_csr_hpm, data_hpm_csr;
    logic                     we_csr_hpm;

    logic [31:0]              mcountinhibit_hpm;

    // PMU
    to_PMU_t       pmu_flags;
    logic count_ovf_int_req;
    logic [HPM_NUM_COUNTERS+3-1:3] mhpm_ovf_bits;
    logic [HPM_NUM_EVENTS:1] hpm_events;

    // Response CSR Interface to datapath
    resp_csr_cpu_t resp_csr_interface_datapath;

    logic [2:0] fcsr_rm;
    logic [1:0] fcsr_fs;
    logic en_ld_st_translation;
    logic en_translation;
    logic [42:0] vpu_csr;

    // Response Interface icache to datapath
    resp_icache_cpu_t resp_icache_interface_datapath;

    // Request Datapath to Icache interface
    req_cpu_icache_t req_datapath_icache_interface;

    // Response Interface dcache to datapath
    resp_dcache_cpu_t resp_dcache_interface_datapath;

    // Request Datapath to Dcache interface
    req_cpu_dcache_t req_datapath_dcache_interface;

    // Request Datapath to CSR
    drac_pkg::req_cpu_csr_t req_datapath_csr_interface;

    logic          req_icache_ready;
    mmu_pkg::tlb_cache_comm_t dtlb_core_comm; //TODO: find package for these
    mmu_pkg::cache_tlb_comm_t core_dtlb_comm;

    // struct debug input/output
    debug_reg_in_t debug_reg_in;
    debug_contr_in_t debug_cntr_in;

    // RVV
    drac_pkg::sew_t sew;
    logic [VMAXELEM_LOG:0] vl;
    logic vnarrow_wide_en;
    logic vill;
    vxrm_t vxrm;
    logic [1:0] vcsr_vs;

    pmu_interface_t pmu_interface; // TODO connect with icache, dcache, itlb info

    mmu_pkg::csr_ptw_comm_t csr_ptw_comm;
    logic [31:0] csr_satp_ppn;
    logic [63:0] csr_satp;

    // Page Table Walker - dTLB - dCache Connections
    tlb_ptw_comm_t dtlb_ptw_comm;
    ptw_tlb_comm_t ptw_dtlb_comm;

    ptw_dmem_comm_t ptw_dmem_comm;
    dmem_ptw_comm_t dmem_ptw_comm;

    // Constant inputs
    assign debug_reg_in = '{default: 1'b0};
    assign debug_cntr_in = '{default: 1'b0};
    assign pmu_interface = '{default: '0};

    // Connect PTW to dcache
    assign dmem_ptw_comm.dmem_ready = dc_if.dcache_req_ready[0];
    assign dmem_ptw_comm.resp.valid = dc_if.dcache_resp_valid[0];
    assign dmem_ptw_comm.resp.data = (HPDCACHE_REQ_WORDS == 1) ? dc_if.dcache_resp[0].rdata :
                                     dc_if.dcache_resp[0].rdata[ptw_dmem_comm.req.addr[$clog2(HPDCACHE_REQ_WORDS)+(HPDCACHE_REQ_WORDS==1)+2:3]]; // Copied from sargantana_tile repo - top_tile.sv

    assign csr_ptw_comm.satp = {32'b0, csr_satp_ppn}; // PTW expects 64 bits
    assign csr_satp = csr_inst.satp_q;
    assign sew = drac_pkg::sew_t'(vpu_csr[38:37]); // TODO: Must match whatever the csr does. Ideally it would return a struct
    assign vl = vpu_csr[14 +: (VMAXELEM_LOG+1)];

    assign vnarrow_wide_en = vpu_csr[13];           //Enable vector instructions that use SEW*2
    assign vill = vpu_csr[42];                      //Illegal configuration of vtype
    assign vxrm = vxrm_t'(vpu_csr[30:29]);          //Vector Fixed-Point rounding mode

    assign hpm_events[1]  = pmu_flags.branch_miss;
    assign hpm_events[2]  = pmu_flags.is_branch;
    assign hpm_events[3]  = pmu_flags.branch_taken;
    assign hpm_events[4]  = pmu_interface.exe_store;
    assign hpm_events[5]  = pmu_interface.exe_load;
    assign hpm_events[6]  = pmu_interface.icache_req;
    assign hpm_events[7]  = pmu_interface.icache_kill;
    assign hpm_events[8]  = pmu_flags.stall_if;
    assign hpm_events[9]  = pmu_flags.stall_id;
    assign hpm_events[10] = pmu_flags.stall_rr;
    assign hpm_events[11] = pmu_flags.stall_exe;
    assign hpm_events[12] = pmu_flags.stall_wb;
    assign hpm_events[13] = pmu_interface.icache_miss_l2_hit;
    assign hpm_events[14] = pmu_interface.icache_miss_kill;
    assign hpm_events[15] = pmu_interface.icache_busy;
    assign hpm_events[16] = pmu_interface.icache_miss_time;
    assign hpm_events[17] = pmu_flags.load_store;
    assign hpm_events[18] = pmu_flags.data_depend;
    assign hpm_events[19] = pmu_flags.struct_depend;
    assign hpm_events[20] = pmu_flags.grad_list_full;
    assign hpm_events[21] = pmu_flags.free_list_empty;
    assign hpm_events[22] = pmu_interface.itlb_access;
    assign hpm_events[23] = pmu_interface.itlb_miss;
    assign hpm_events[24] = pmu_interface.dtlb_access;
    assign hpm_events[25] = pmu_interface.dtlb_miss;
    assign hpm_events[26] = pmu_interface.ptw_buffer_hit;
    assign hpm_events[27] = pmu_interface.ptw_buffer_miss;
    assign hpm_events[28] = pmu_interface.itlb_stall;

    // Module instantiation
    // TODO: replace with subtop

    hpm_counters #(
        .HPM_NUM_EVENTS(HPM_NUM_EVENTS),
        .HPM_NUM_COUNTERS(HPM_NUM_COUNTERS)
    ) hpm_counters_inst (
        .clk_i(clock_if.clk),
        .rstn_i(reset_if.rsn),

        // Access interface
        .addr_i(addr_csr_hpm),
        .we_i(we_csr_hpm),
        .data_i(data_csr_hpm),
        .data_o(data_hpm_csr),
        .mcountinhibit_i(mcountinhibit_hpm),
        .priv_lvl_i(csr_priv_lvl),

        // Events
        .events_i(hpm_events),
        .count_ovf_int_req_o(count_ovf_int_req),
        .mhpm_ovf_bits_o(mhpm_ovf_bits)
    );

    datapath datapath_inst(
        .clk_i                              (clock_if.clk),
        .rstn_i                             (reset_if.rsn),
        .reset_addr_i                       (io_reset_address),
        // Input datapath
        .resp_icache_cpu_i                  (resp_icache_interface_datapath), 
        .resp_dcache_cpu_i                  (resp_dcache_interface_datapath), // dcache interface file dc_if.sv is not yet updated for hpdc+sargantana, its just placeholder
        .resp_csr_cpu_i                     (resp_csr_interface_datapath),
        .csr_frm_i                          (fcsr_rm),
        .csr_fs_i                           (fcsr_fs),
        .csr_vs_i                           (vcsr_vs),
        .en_translation_i                   ( en_translation ), 
        .en_ld_st_translation_i             (en_ld_st_translation),
        .debug_reg_i                        (debug_reg_in),
        .debug_contr_i                       (debug_cntr_in),
        .csr_priv_lvl_i                     (ld_st_priv_lvl),
        .req_icache_ready_i                 (req_icache_ready), // see if icache if supports ready signal
        .sew_i                              (sew),//.sew_i(CSR_SEW),
        .vl_i                               (vl),
        .vnarrow_wide_en_i                  (vnarrow_wide_en),
        .vill_i                             (vill),
        .vxrm_i                             (vxrm),
        .dtlb_comm_i                        (dtlb_core_comm), // decide if we want to instantiate dtlb or we want to use spike functions for address translate
        // Output datapath
        .req_cpu_dcache_o                   (req_datapath_dcache_interface), // dcache interface file dc_if.sv is not yet updated for hpdc+sargantana, its just placeholder
        .req_cpu_icache_o                   (req_datapath_icache_interface),
        .req_cpu_csr_o                      (req_datapath_csr_interface),
        .debug_reg_o                        (debug_reg_out),
        .debug_contr_o                      (debut_cntr_out),
        .debug_csr_halt_ack_o               (),
        .visa_o                             (),
        .dtlb_comm_o                        (core_dtlb_comm),
        //PMU                                                   
        .pmu_flags_o                        (pmu_flags)
    );

    dcache_interface #(
        .DracCfg(drac_pkg::DracDefaultConfig) // TODO: Or whatever is used to instatiate the tile in CincoRanch
    ) dcache_interface_inst(
        .clk_i(clock_if.clk),
        .rstn_i(reset_if.rsn),

        // CPU Interface
        .req_cpu_dcache_i(req_datapath_dcache_interface),
        .resp_dcache_cpu_o(resp_dcache_interface_datapath),

        // dCache Interface
        .dcache_ready_i(dc_if.dcache_req_ready[1]),
        .dcache_valid_i(dc_if.dcache_resp_valid[1]),
        .core_req_valid_o(dc_if.dcache_req_valid[1]),
        .req_dcache_o(dc_if.dcache_req[1]),
        .rsp_dcache_i(dc_if.dcache_resp[1]),
        .wbuf_empty_i(dc_if.wbuf_empty),

        // PMU
        .dmem_is_store_o ( exe_store_pmu ),
        .dmem_is_load_o  ( exe_load_pmu  )
    );

    icache_interface icache_interface_inst(
        .clk_i(clock_if.clk),
        .rstn_i(reset_if.rsn),

        // Inputs ICache
        .icache_resp_datablock_i    ( ic_if.icache_resp.data  ),
        .icache_resp_valid_i        ( ic_if.icache_resp.valid ),
        .icache_req_ready_i         ( ic_if.icache_resp.ready ), 
        .tlb_resp_xcp_if_i          ( ic_if.icache_resp.xcpt  ),
        .en_translation_i           ( en_translation ), 
       
        // Outputs ICache
        .icache_invalidate_o    ( ic_if.iflush             ), 
        .icache_req_bits_idx_o  ( ic_if.lagarto_ireq.idx   ), 
        .icache_req_kill_o      ( ic_if.lagarto_ireq.kill  ), 
        .icache_req_valid_o     ( ic_if.lagarto_ireq.valid ),
        .icache_req_bits_vpn_o  ( ic_if.lagarto_ireq.vpn   ), 

        // Fetch stage interface - Request packet from fetch_stage
        .req_fetch_icache_i(req_datapath_icache_interface),
        
        // Fetch stage interface - Response packet icache to fetch
        .resp_icache_fetch_o(resp_icache_interface_datapath),
        .req_fetch_ready_o(req_icache_ready)
    );


    csr_bsc csr_inst (
        .clk_i(clock_if.clk),
        .rstn_i(reset_if.rsn),
        .core_id_i('0), // TODO configurable
        `ifdef PITON_CINCORANCH
        .boot_main_id_i('0), // TODO configurable
        `endif  // Custom for CincoRanch
        .rw_addr_i(req_datapath_csr_interface.csr_rw_addr),                  //read and write address form the core
        .rw_cmd_i(req_datapath_csr_interface.csr_rw_cmd),                   //specific operation to execute from the core 
        .w_data_core_i(req_datapath_csr_interface.csr_rw_data),              //write data from the core
        .r_data_core_o(resp_csr_interface_datapath.csr_rw_rdata),              // read data to the core, address specified with the rw_addr_i

        .ex_i(req_datapath_csr_interface.csr_exception),                       // exception produced in the core
        .ex_cause_i(req_datapath_csr_interface.csr_xcpt_cause),                 //cause of the exception
        .ex_origin_i(req_datapath_csr_interface.csr_xcpt_origin),                //origin of the exception
        .pc_i(req_datapath_csr_interface.csr_pc),                       //pc were the exception is produced

        .retire_i(req_datapath_csr_interface.csr_retire),                   // shows if a instruction is retired from the core.
        .time_irq_i(int_if.time_irq), // TODO FIX                // timer interrupt
        .irq_i(int_if.irq), // TODO FIX                     // external interrupt in
        .m_soft_irq_i(int_if.m_soft_irq), // TODO check
        .interrupt_o(resp_csr_interface_datapath.csr_interrupt),                // Inerruption wire to the core
        .interrupt_cause_o(resp_csr_interface_datapath.csr_interrupt_cause),          // Interruption cause

        .time_i('0), // TODO FIX                    // time passed since the core is reset

        .freg_modified_i(req_datapath_csr_interface.freg_modified),
        .fcsr_flags_valid_i(req_datapath_csr_interface.csr_retire),
        .fcsr_flags_bits_i(req_datapath_csr_interface.fp_status),
        .fcsr_rm_o(fcsr_rm),
        .fcsr_fs_o(fcsr_fs),

        .vcsr_vs_o(vcsr_vs),
        .vxsat_i(req_datapath_csr_interface.csr_vxsat),

        .csr_replay_o(resp_csr_interface_datapath.csr_replay),               // replay send to the core because there are some parts that are bussy
        .csr_stall_o(resp_csr_interface_datapath.csr_stall),                // The csr are waiting a resp and de core is stalled
        .csr_xcpt_o(resp_csr_interface_datapath.csr_exception),                 // Exeption pproduced by the csr   
        .csr_xcpt_cause_o(resp_csr_interface_datapath.csr_exception_cause),           // Exception cause
        .csr_tval_o(resp_csr_interface_datapath.csr_tval),                 // Value written to the tval registers
        .eret_o(resp_csr_interface_datapath.csr_eret),

        .status_o(csr_ptw_comm.mstatus),                   //actual mstatus of the core
        .priv_lvl_o(csr_priv_lvl),                 // actual privialge level of the core
        .ld_st_priv_lvl_o(ld_st_priv_lvl),
        .en_ld_st_translation_o(en_ld_st_translation),
        .en_translation_o(en_translation),

        .satp_ppn_o(csr_satp_ppn),                 // Page table base pointer for the PTW

        .evec_o(resp_csr_interface_datapath.csr_evec),                      // virtual address of the PC to execute after a Interrupt or exception

        .flush_o(csr_ptw_comm.flush),                    // the core is executing a sfence.vm instruction and a tlb flush is needed
        .vpu_csr_o(vpu_csr),

        .perf_addr_o(addr_csr_hpm),                // read/write address to performance counter module
        .perf_data_o(data_csr_hpm),                // write data to performance counter module
        .perf_data_i(data_hpm_csr),                // read data from performance counter module
        .perf_we_o(we_csr_hpm),
        .perf_mcountinhibit_o(mcountinhibit_hpm),
        .perf_count_ovf_int_req_i(count_ovf_int_req),
        .perf_mhpm_ovf_bits_i(mhpm_ovf_bits),

        .debug_halt_req_i   ('0),
        .debug_halt_ack_i   ('0),
        .debug_resume_ack_i ('0),
        .debug_ebreak_o(resp_csr_interface_datapath.debug_ebreak),
        .debug_step_o(resp_csr_interface_datapath.debug_step)
    );

    tlb dtlb (
        .clk_i(clock_if.clk),
        .rstn_i(reset_if.rsn),
        .cache_tlb_comm_i(core_dtlb_comm),
        .tlb_cache_comm_o(dtlb_core_comm),
        .ptw_tlb_comm_i(ptw_dtlb_comm),
        .tlb_ptw_comm_o(dtlb_ptw_comm),
        .pmu_tlb_access_o(pmu_dtlb_access),
        .pmu_tlb_miss_o(pmu_dtlb_miss)
    );

    ptw ptw_inst (
        .clk_i(clock_if.clk),
        .rstn_i(reset_if.rsn),

        // dTLB request-response
        .dtlb_ptw_comm_i(dtlb_ptw_comm),
        .ptw_dtlb_comm_o(ptw_dtlb_comm),

        // dmem request-response
        .dmem_ptw_comm_i(dmem_ptw_comm),
        .ptw_dmem_comm_o(ptw_dmem_comm),

        // csr interface
        .csr_ptw_comm_i(csr_ptw_comm),

        // pmu interface
        .pmu_ptw_hit_o(pmu_ptw_hit),
        .pmu_ptw_miss_o(pmu_ptw_miss)
    );

// Interface connections
    assign fetch_if.clk = clock_if.clk;
    assign fetch_if.rsn = reset_if.rsn;
    assign reset_if.clk = clock_if.clk;

    assign completed_if.clk = clock_if.clk;
    assign completed_if.rsn = reset_if.rsn;
    assign dc_if.clk = clock_if.clk;
    assign dc_if.rsn = reset_if.rsn;
    assign ic_if.clk = clock_if.clk;
    assign ic_if.rsn = reset_if.rsn;
    assign int_if.clk = clock_if.clk;
    assign int_if.rsn = reset_if.rsn;
    assign reg_if.clk = clock_if.clk;

// TODO Use sub-top to simplify and unify this part with RTL
    assign fetch_if.fetch_pc = datapath_inst.pc_if1;
    assign fetch_if.decode_pc = datapath_inst.pc_id;
    assign fetch_if.fetch_valid = datapath_inst.valid_if1;
    assign fetch_if.decode_valid = datapath_inst.valid_id;
    assign fetch_if.decode_is_illegal = datapath_inst.id_decode_inst.xcpt_illegal_instruction_int;
    assign fetch_if.decode_is_compressed = 1'b0; // sargantana doesn't support compressed instruction, TBC
    assign fetch_if.invalidate_icache_int = datapath_inst.invalidate_icache_int;
    assign fetch_if.invalidate_buffer_int = datapath_inst.invalidate_buffer_int;
    assign fetch_if.retry_fetch = datapath_inst.retry_fetch;

    assign int_if.interrupt         = datapath_inst.resp_csr_cpu_i.csr_interrupt;
    assign int_if.interrupt_cause   = datapath_inst.resp_csr_cpu_i.csr_interrupt_cause;


    assign ic_if.csr_en_translation = en_translation;
    assign ic_if.csr_status = csr_ptw_comm.mstatus;
    assign ic_if.csr_satp = csr_satp;
    assign ic_if.csr_priv_lvl = csr_priv_lvl;

    assign dc_if.dcache_req_valid[0] = ptw_dmem_comm.req.valid;
    assign dc_if.dcache_req[0].addr_offset = ptw_dmem_comm.req.addr[(HPDCACHE_OFFSET_WIDTH+HPDCACHE_SET_WIDTH)-1:0],
       dc_if.dcache_req[0].op = ((ptw_dmem_comm.req.cmd == 5'b01010) ? HPDCACHE_REQ_AMO_OR : HPDCACHE_REQ_LOAD),
       dc_if.dcache_req[0].size = ptw_dmem_comm.req.typ[2:0],
       dc_if.dcache_req[0].sid = '0,
       dc_if.dcache_req[0].tid = '0,
       dc_if.dcache_req[0].need_rsp = 1'b1,
       dc_if.dcache_req[0].phys_indexed = 1'b1,
       dc_if.dcache_req[0].addr_tag = ptw_dmem_comm.req.addr[SIZE_VADDR:(HPDCACHE_OFFSET_WIDTH+HPDCACHE_SET_WIDTH)],
       dc_if.dcache_req[0].pma.io = 1'b0, 
       dc_if.dcache_req[0].pma.uncacheable = 1'b0;

    if (HPDCACHE_REQ_WORDS == 1) begin
        assign dc_if.dcache_req[0].wdata = ptw_dmem_comm.req.data;
        assign dc_if.dcache_req[0].be = (ptw_dmem_comm.req.cmd == 5'b01010) ? 8'hff : 8'h00;
    end else begin
        always_comb begin
            for (int i = 0; i < HPDCACHE_REQ_WORDS; ++i) begin
                if ((ptw_dmem_comm.req.addr[$clog2(HPDCACHE_REQ_WORDS)+2:0] == (3'(i) << 3))) begin
                    dc_if.dcache_req[0].wdata[i] = ptw_dmem_comm.req.data;
                    dc_if.dcache_req[0].be[i] = (ptw_dmem_comm.req.cmd == 5'b01010) ? 8'hff : 8'h00;
                end else begin 
                    dc_if.dcache_req[0].wdata[i] = '0;
                    dc_if.dcache_req[0].be[i] = 8'h00;
                end 
            end
        end
    end

// TODO remove
    assign tohost_if.csr_tohost_valid = (req_datapath_csr_interface.csr_rw_addr == riscv_pkg::TO_HOST) && (req_datapath_csr_interface.csr_rw_cmd == 4'b1000);
    assign clearmip_if.csr_clearmip_valid = (|csr_inst.mip_q) & !(|csr_inst.mip_d);

    always_comb begin 
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            completed_if.valid[i] = datapath_inst.commit_valid[i];
            completed_if.pc[i] = datapath_inst.commit_data[i].pc;
            completed_if.result[i] = datapath_inst.commit_data[i].data;
            completed_if.result_valid[i] = datapath_inst.commit_data[i].reg_wr_valid;
            completed_if.pdest[i] = datapath_inst.commit_data[i].dst;
            completed_if.xcpt_cause[i] = datapath_inst.commit_data[i].xcpt ? datapath_inst.commit_data[i].xcpt_cause : datapath_inst.commit_data[i].csr_xcpt_cause;
            completed_if.rob_head[i] = '0;
            completed_if.instr[i] = datapath_inst.commit_data[i].inst;
            completed_if.vd[i] = datapath_inst.commit_data[i].data;
            completed_if.store_data[i] = '0;
            completed_if.rob_entry_miss[i] = '0;
            completed_if.store_valid[i] = '0;
            completed_if.xcpt[i] = datapath_inst.commit_data[i].xcpt | datapath_inst.commit_data[i].csr_xcpt;
            completed_if.core_req_valid[i] = '0;
            completed_if.branch[i] = '0;
            completed_if.fault[i] = '0;
            completed_if.mem_req_rob_entry[i] = '0;
        end
    end

// Bootstrap
    initial begin
        io_reset_address = 64'h1000; // Default
        if ($test$plusargs("RESET_VECTOR")) begin
            $value$plusargs("RESET_VECTOR=0x%x", io_reset_address);
        end
    end

// Assertions
`ifdef ASSERT
    sva_csr u_sva_csr(
        .clk_i                  ( clock_if.clk                          ),
        .rsn_i                  ( reset_if.rsn                          ),
        .csr_priv_lvl_i         ( csr_priv_lvl_o              ),
        .csr_rw_rdata_i         ( resp_csr_interface_datapath.csr_r_data_core           ),
        .csr_csr_stall_i        ( resp_csr_interface_datapath.csr_stall             ),
        .csr_xcpt_i             ( resp_csr_interface_datapath.csr_xcpt              ),
        .csr_xcpt_cause_i       ( resp_csr_interface_datapath.csr_xcpt_cause        ),
        .csr_eret_i             ( resp_csr_interface_datapath.csr_eret                  ),
        .csr_evec_i             ( resp_csr_interface_datapath.csr_epc           ),
        .csr_interrupt_i        ( resp_csr_interface_datapath.csr_interrupt             ),
        .csr_interrupt_cause_i  ( resp_csr_interface_datapath.csr_interrupt_cause       ),
        .csr_csr_replay_i       ( resp_csr_interface_datapath.csr_replay            ),
        .csr_tval_i             ( resp_csr_interface_datapath.csr_tval              ),
        .csr_rw_addr_o          ( req_datapath_csr_interface.csr_rw_addr         ),
        .csr_rw_cmd_o           ( req_datapath_csr_interface.csr_rw_cmd          ),
        .csr_rw_wdata_o         ( req_datapath_csr_interface.csr_rw_wdata        ),
        .csr_exception_o        ( req_datapath_csr_interface.csr_exception       ),
        .csr_cause_o            ( req_datapath_csr_interface.csr_cause           ),
        .csr_pc_o               ( req_datapath_csr_interface.csr_pc     ),
        .csr_retire_o           ( req_datapath_csr_interface.csr_retire          )
    );
`endif

// Coverage
`ifdef COVERAGE
    cov_isa #(.COMMIT_WIDTH(2)) u_cov_isa (
        .i_clk                      (clock_if.clk               ),
        .i_rsn                      (reset_if.rsn               ),
        .i_valid                    (completed_if.commit_valid  ),
        .i_instruction              (completed_if.instr         )
    );
    cov_priv_isa u_cov_priv_isa(
        .i_clk                      (clock_if.clk),
        .i_rsn                      (reset_if.rsn),
        .i_mstatus                  (csr_inst.mstatus_d),
        .i_mcause                   (csr_inst.mcause_d),
        .i_scause                   (csr_inst.scause_d),
        .i_mtvec                    (csr_inst.mtvec_d),
        .i_stvec                    (csr_inst.stvec_d),
        .i_mideleg                  (csr_inst.mideleg_d),
        .i_medeleg                  (csr_inst.medeleg_d),
        .i_csr_addr                 (csr_inst.rw_addr_i),
        .i_csr_cmd                  (csr_inst.rw_cmd_i),
        .i_priv_lvl                 (csr_inst.priv_lvl_o),
        .i_pipeline_exc             (csr_inst.ex_i),
        .i_csr_exc                  (csr_inst.csr_xcpt_o)
    ); 
`endif // COVERAGE

endmodule : test_harness
