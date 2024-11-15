/* -----------------------------------------------------------
* Project Name  : MEEP
* Organization  : Barcelona Supercomputing Center
* Email         : zeeshan.ali@bsc.es-
* Description   : To code uArchitectural functional coverpoints and cover properties
                : for backend of the core (exu/lsu, wb/commit/CSR stages)
* ------------------------------------------------------------*/
import drac_pkg::*;
import riscv_pkg::*;
import ariane_pkg::*;
import wt_cache_pkg::*;
import EPI_pkg::*;
import cov_core_defs::*;

module cov_backend (
    input logic                         clk_i,
    input logic                         rsn_i,
    input resp_dcache_cpu_t             resp_dcache_cpu_i,
    input logic                         en_translation_i, // translation for PC is enabled if SATP.MODE = Sv39 && current_priv_mode != MACHINE
    input logic                         en_ld_st_translation_i,  // if (stap.mode == sv39  && priv_mode != MACHINE) OR (priv_mode == MACHINE && mstatus.mprv ==1 && mstatus.mpp == SUPERVISOR/USER && satp.mode == sv39)
    input rr_exe_instr_t                from_rr_i,
    input exe_wb_instr_t                to_wb_o,
    input logic                         csr_interrupt_i,
    input exe_wb_instr_t                exe_to_wb_wb,
    input logic                         daccess_err,
    input riscv::priv_lvl_t             ld_st_priv_lvl_i,
    input ariane_pkg::exception_t       lsu_exception_o,
    input logic                         dtlb_hit_q,
    input logic                         lsu_req_q,
    input logic                         lsu_is_store_q,
    input riscv::pte_t                  dtlb_pte_q,
    input logic                         ptw_active,
    input logic                         walking_instr,
    input logic                         ptw_error,
    input logic                         pte_lookup,
    input logic                         data_rvalid_q,
    input riscv::pte_t                  pte,
    input logic                         lsu_is_store_i,
    input  logic                        mxr_i,
    input logic                         ptw_lvl_1, ptw_lvl_2, ptw_lvl_3,
    input tlb_tags_q_t                  dtlb_tags_q,
    input logic                         dtlb_flush,
    input logic                         itlb_access_i,
    input logic                         dtlb_access_i,
    input logic                         itlb_hit,
    input logic                         dtlb_hit,
    input logic [TLB_ENTRIES-1:0]       dtlb_lu_hit,
    input  logic                        dcache_en_i,
    input  logic [Dcache_Ports-1:0]     paddr_is_nc,
    input exe_cu_t                      exe_cu_i,
    input pipeline_ctrl_t               pipeline_ctrl_int,
    input logic                         correct_branch_pred_i,
    input id_cu_t                       id_cu_i,
    input bus64_t                       csr_cause,
    input logic                         csr_excpt_intrpt,
    input logic                         icache_flush,
    input logic                         interrupt_pending,
    input logic [Dcache_Ports-1:0]      miss_req,
    input logic [DCACHE_SET_ASSOC-1:0]  rd_hit_oh,
    input logic [Dcache_Ports-1:0]      dcache_rd_req,
    input logic                         mem_rtrn_vld_i,
    input logic                         dtlb_miss,
    input logic                         dtlb_fill_return,
    input to_PMU_t                      pmu_flags_o,
    input logic                         stall_mul,
    input logic                         stall_div,
    input logic                         stall_mem,
    input logic                         stall_fpu,
    input logic                         stall_o,
    input wb_exe_instr_t                from_wb_i,
    input pipeline_flush_t              pipeline_flush_o
    );


    /* ----- Declare internal signals & develop internal logic for coverage here -----*/ 
    logic canonical_violation;
    logic load_page_fault;
    logic store_amo_page_fault;
    logic interrupt_blocked;    // if there is a pending memory operation in-flight, block the incoming interrupt (keep it pending instead of directly making it valid)
    logic machine_external_intrpt_valid;
    logic machine_software_intrpt_valid;
    logic machine_timer_intrpt_valid;
    logic supervisor_external_intrpt_valid;
    logic supervisor_software_intrpt_valid;
    logic supervisor_timer_intrpt_valid;
    logic [5:0] riscv_intrpts_valid;
    logic store_misaligned_exception;
    logic load_misaligned_exception;
    logic smode, umode;
    logic lpf_from_dtlb_hit, spf_from_dtlb_hit;
    logic dtlb_hit_for_store;
    logic dtlb_hit_for_load;
    logic ptw_error_for_lsu;
    logic lpf_during_ptw;
    logic spf_during_ptw;
    logic valid_pte_rd_for_store, valid_pte_rd_for_load;
    logic legal_pte_rd_for_store, legal_pte_rd_for_load;
    logic legal_leaf_pte_rd_for_store, legal_leaf_pte_rd_for_load;
    logic legal_nonleaf_pte_rd_for_store, legal_nonleaf_pte_rd_for_load;
    logic [TLB_ENTRIES-1: 0] dtlb_entry_valid;
    logic dtlb_full;
    logic dtlb_full_with_4kb_pages;
    logic dtlb_full_with_2mb_pages;
    logic dtlb_full_with_mix_page_sizes;
    logic dtlb_has_all_page_size;
    logic [TLB_ENTRIES-1: 0] entry_has_4kb_page;
    logic [TLB_ENTRIES-1: 0] entry_has_2mb_page;
    logic [TLB_ENTRIES-1: 0] entry_has_1gb_page;
    logic ptw_req_for_dtlb_miss, ptw_req_for_itlb_miss;
    logic branch_flush, exception_flush, interrupt_flush;
    logic dcache_hit, dcache_miss, dcache_fill_return;
    logic [PIPELINE_STAGES-1:0] stall_pipeline_stages;
    logic [BRANCH_PMU_EVENTS-1:0] branch_pmu_events;
    logic rs1_bypass, rs2_bypass, rs3_bypass; // rs3 only for FPU op
    logic [PIPELINE_STAGES-1:0] pipeline_stages_flush;
    generate
        if (drac_pkg::FP_PRESENT) begin
            logic [3:0] exu_stalling_ops;
            logic [2:0] forwarded_regs;
            `define FPU_IS_PRESENT
        end
        else begin
            logic [2:0] exu_stalling_ops;
            logic [1:0] forwarded_regs;
        end
    endgenerate
    

    assign canonical_violation              =   en_ld_st_translation_i && !((&resp_dcache_cpu_i.addr[63:riscv::VLEN-1]) == 1'b1 || (|resp_dcache_cpu_i.addr[63:riscv::VLEN-1]) == 1'b0) && from_rr_i.instr.unit == UNIT_MEM;
    assign load_page_fault                  =   (to_wb_o.ex.cause == LD_PAGE_FAULT) && to_wb_o.ex.valid?  1'b1    :   1'b0;
    assign store_amo_page_fault             =   (to_wb_o.ex.cause == ST_AMO_PAGE_FAULT) && to_wb_o.ex.valid?  1'b1    :   1'b0;
    assign store_misaligned_exception       =   (to_wb_o.ex.cause == ST_AMO_ADDR_MISALIGNED) && to_wb_o.ex.valid?  1'b1    :   1'b0;
    assign load_misaligned_exception        =   (to_wb_o.ex.cause == LD_ADDR_MISALIGNED) && to_wb_o.ex.valid?  1'b1    :   1'b0;
    assign smode                            =   (ld_st_priv_lvl_i == riscv::PRIV_LVL_S)? 1'b1 : 1'b0;
    assign umode                            =   (ld_st_priv_lvl_i == riscv::PRIV_LVL_U)? 1'b1 : 1'b0;
    assign lpf_from_dtlb_hit                =   lsu_exception_o.valid && (lsu_exception_o.cause == riscv::LOAD_PAGE_FAULT);
    assign spf_from_dtlb_hit                =   lsu_exception_o.valid && (lsu_exception_o.cause == riscv::STORE_PAGE_FAULT);
    assign dtlb_hit_for_store               =   lsu_req_q && dtlb_hit_q && lsu_is_store_q;
    assign dtlb_hit_for_load                =   lsu_req_q && dtlb_hit_q && !lsu_is_store_q;
    assign ptw_error_for_lsu                =   ptw_active && !walking_instr && ptw_error && lsu_exception_o.valid;
    assign lpf_during_ptw                   =   ptw_error_for_lsu && (lsu_exception_o.cause == riscv::LOAD_PAGE_FAULT);
    assign spf_during_ptw                   =   ptw_error_for_lsu && (lsu_exception_o.cause == riscv::STORE_PAGE_FAULT);
    assign valid_pte_rd_for_store           =   pte_lookup && data_rvalid_q && !walking_instr && lsu_is_store_i;
    assign valid_pte_rd_for_load            =   pte_lookup && data_rvalid_q && !walking_instr && !lsu_is_store_i;
    assign legal_pte_rd_for_store           =   valid_pte_rd_for_store && pte.v && !(!pte.r && pte.w);
    assign legal_pte_rd_for_load            =   valid_pte_rd_for_load && pte.v && !(!pte.r && pte.w);
    assign legal_leaf_pte_rd_for_store      =   legal_pte_rd_for_store && (pte.r || pte.x);
    assign legal_leaf_pte_rd_for_load       =   legal_pte_rd_for_load && (pte.r || pte.x);
    assign legal_nonleaf_pte_rd_for_store   =   legal_pte_rd_for_store && !(pte.r || pte.x);
    assign legal_nonleaf_pte_rd_for_load    =   legal_pte_rd_for_load && !(pte.r || pte.x);
    assign dtlb_full                        =   &dtlb_entry_valid;
    assign dtlb_full_with_4kb_pages         =   &entry_has_4kb_page;
    assign dtlb_full_with_2mb_pages         =   &entry_has_2mb_page;
    assign dtlb_has_all_page_size           =   (|entry_has_4kb_page && |entry_has_2mb_page  && |entry_has_1gb_page);
    assign dtlb_full_with_mix_page_sizes    =   dtlb_has_all_page_size & dtlb_full;
    assign ptw_req_for_itlb_miss            =   en_translation_i &  itlb_access_i & ~itlb_hit;
    assign ptw_req_for_dtlb_miss            =   en_ld_st_translation_i & dtlb_access_i & ~dtlb_hit;
    assign interrupt_blocked                =   csr_interrupt_i && (from_rr_i.instr.unit == UNIT_MEM);
    assign machine_external_intrpt_valid    =   exe_to_wb_wb.ex.valid && (exe_to_wb_wb.ex.cause == riscv::M_EXT_INTERRUPT);
    assign machine_software_intrpt_valid    =   exe_to_wb_wb.ex.valid && (exe_to_wb_wb.ex.cause == riscv::M_SW_INTERRUPT);
    assign machine_timer_intrpt_valid       =   exe_to_wb_wb.ex.valid && (exe_to_wb_wb.ex.cause == riscv::M_TIMER_INTERRUPT);
    assign supervisor_external_intrpt_valid =   exe_to_wb_wb.ex.valid && (exe_to_wb_wb.ex.cause == riscv::S_EXT_INTERRUPT);
    assign supervisor_software_intrpt_valid =   exe_to_wb_wb.ex.valid && (exe_to_wb_wb.ex.cause == riscv::S_SW_INTERRUPT);
    assign supervisor_timer_intrpt_valid    =   exe_to_wb_wb.ex.valid && (exe_to_wb_wb.ex.cause == riscv::S_TIMER_INTERRUPT);
    assign riscv_intrpts_valid              =   {machine_external_intrpt_valid, machine_software_intrpt_valid, machine_timer_intrpt_valid,
                                                supervisor_external_intrpt_valid, supervisor_software_intrpt_valid, supervisor_timer_intrpt_valid};
    assign branch_flush                     =   (exe_cu_i.valid && ~correct_branch_pred_i && !pipeline_ctrl_int.stall_exe) || id_cu_i.valid_jal; // coditional branch mispredicted at EXE || unpredicted jal at id stage
    assign exception_flush                  =   csr_excpt_intrpt && !csr_cause[XLEN-1];
    assign interrupt_flush                  =   csr_excpt_intrpt && csr_cause[XLEN-1];
    assign dcache_miss                      =   |miss_req;
    assign dcache_hit                       =   |rd_hit_oh && dcache_en_i;
    assign dcache_fill_return               =   mem_rtrn_vld_i;
    assign stall_pipeline_stages            =   {pmu_flags_o.stall_wb, pmu_flags_o.stall_exe, pmu_flags_o.stall_rr, pmu_flags_o.stall_id, pmu_flags_o.stall_if};
    assign branch_pmu_events                =   {pmu_flags_o.branch_not_taken_hit, pmu_flags_o.branch_taken_addr_miss, pmu_flags_o.branch_taken_b_not_detected,
                                                 pmu_flags_o.branch_taken_hit, pmu_flags_o.branch_taken, pmu_flags_o.is_branch_false_positive,
                                                 pmu_flags_o.is_branch_hit, pmu_flags_o.branch_miss, pmu_flags_o.is_branch
                                                };

    assign exu_stalling_ops                 =   drac_pkg::FP_PRESENT?   {stall_fpu&stall_o, stall_mem&stall_o, stall_div&stall_o, stall_mul&stall_o}  :   {stall_mem&stall_o, stall_div&stall_o, stall_mul&stall_o};
    assign rs1_bypass                       =   (((from_rr_i.instr.rs1 != 0) & (from_rr_i.instr.rs1 == from_wb_i.rd)  & from_wb_i.valid & !from_rr_i.instr.use_fs1 & !from_wb_i.fregfile_we) |
                                                ((from_rr_i.instr.rs1 == from_wb_i.frd) & from_wb_i.valid &  from_rr_i.instr.use_fs1 &  from_wb_i.fregfile_we));
    assign rs2_bypass                       =   (((from_rr_i.instr.rs2 != 0) & (from_rr_i.instr.rs2 == from_wb_i.rd)  & from_wb_i.valid & !from_rr_i.instr.use_fs2 & !from_wb_i.fregfile_we) |
                                                ((from_rr_i.instr.rs2 == from_wb_i.frd) & from_wb_i.valid &  from_rr_i.instr.use_fs2 &  from_wb_i.fregfile_we));
    assign rs3_bypass                       =   ((from_rr_i.instr.rs3 == from_wb_i.frd) & from_rr_i.instr.use_fs3 & from_wb_i.valid & from_wb_i.fregfile_we); // only some FP instructions have rs3 field
    assign forwarded_regs                   =   drac_pkg::FP_PRESENT?   {rs3_bypass, rs2_bypass, rs1_bypass}    :   {rs2_bypass, rs1_bypass};
    assign pipeline_stages_flush            =   {pipeline_flush_o.flush_wb, pipeline_flush_o.flush_exe, pipeline_flush_o.flush_rr, pipeline_flush_o.flush_id, pipeline_flush_o.flush_if};
    
    always_comb begin
        for (int entry=0; entry<TLB_ENTRIES; entry++) begin
            dtlb_entry_valid[entry]     = dtlb_tags_q[entry].valid;
            entry_has_4kb_page[entry]   = !dtlb_tags_q[entry].is_2M && !dtlb_tags_q[entry].is_1G && dtlb_tags_q[entry].valid;
            entry_has_2mb_page[entry]   = dtlb_tags_q[entry].is_2M && dtlb_tags_q[entry].valid;
            entry_has_1gb_page[entry]   = dtlb_tags_q[entry].is_1G && dtlb_tags_q[entry].valid;
        end
    end


    /* ----- Declare coverage MACROS here -----*/ 

    // macro to check whether two events collide each other with the given clock cycles difference
    `define event1_collides_event2(sig1, sig2, cycle_diff) \
    property ``sig1``_collides_``sig2``_``cycle_diff``_p; \
        @(negedge clk_i) disable iff(~rsn_i) \
        ``sig1`` |-> ##``cycle_diff`` ``sig2``; \
    endproperty \
    cover property(``sig1``_collides_``sig2``_``cycle_diff``_p);

    // macro to check whether two events follow each other within a given clock cycles window
    `define event2_follows_event1(sig1, sig2, window) \
    property ``sig2``_follows_``sig1``_``window``_p; \
        @(negedge clk_i) disable iff(~rsn_i && ~en_ld_st_translation_i) \
        ``sig1`` |=> ((!$rose(``sig1``)) throughout (##[0:``window``] ``sig2``)); \
    endproperty \
    cover property(``sig2``_follows_``sig1``_``window``_p);
    
    /* ----- Declare cover properties here -----*/ 
    generate
        begin: lsu_cover_properties
            // Dcache
            begin: dcache_events_colliding

                // dcache miss
                begin: dcache_miss_colliding
                    begin: dcache_miss_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_miss_colliding_branch_flush
                            `event1_collides_event2(dcache_miss, branch_flush, i)
                        end
                    end: dcache_miss_colliding_branch_flush

                    begin: dcache_miss_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_miss_colliding_exception_flush
                            `event1_collides_event2(dcache_miss, exception_flush, i)
                        end
                    end: dcache_miss_colliding_exception_flush

                    begin: dcache_miss_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_miss_colliding_interrupt_flush
                            `event1_collides_event2(dcache_miss, interrupt_flush, i)
                        end
                    end: dcache_miss_colliding_interrupt_flush

                    begin: dcache_miss_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_miss_colliding_icache_flush
                            `event1_collides_event2(dcache_miss, icache_flush, i)
                        end
                    end: dcache_miss_colliding_icache_flush

                    begin: dcache_miss_colliding_dtlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_miss_colliding_dtlb_flush
                            `event1_collides_event2(dcache_miss, dtlb_flush, i)
                        end
                    end: dcache_miss_colliding_dtlb_flush

                    begin: dcache_miss_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_miss_colliding_interrupt_pending
                            `event1_collides_event2(dcache_miss, interrupt_pending, i)
                        end
                    end: dcache_miss_colliding_interrupt_pending
                end: dcache_miss_colliding

                // dcache hit
                begin: dcache_hit_colliding
                    begin: dcache_hit_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_hit_colliding_branch_flush
                            `event1_collides_event2(dcache_hit, branch_flush, i)
                        end
                    end: dcache_hit_colliding_branch_flush

                    begin: dcache_hit_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_hit_colliding_exception_flush
                            `event1_collides_event2(dcache_hit, exception_flush, i)
                        end
                    end: dcache_hit_colliding_exception_flush

                    begin: dcache_hit_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_hit_colliding_interrupt_flush
                            `event1_collides_event2(dcache_hit, interrupt_flush, i)
                        end
                    end: dcache_hit_colliding_interrupt_flush

                    begin: dcache_hit_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_hit_colliding_icache_flush
                            `event1_collides_event2(dcache_hit, icache_flush, i)
                        end
                    end: dcache_hit_colliding_icache_flush

                    begin: dcache_hit_colliding_dtlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_hit_colliding_dtlb_flush
                            `event1_collides_event2(dcache_hit, dtlb_flush, i)
                        end
                    end: dcache_hit_colliding_dtlb_flush

                    begin: dcache_hit_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_hit_colliding_interrupt_pending
                            `event1_collides_event2(dcache_hit, interrupt_pending, i)
                        end
                    end: dcache_hit_colliding_interrupt_pending
                end: dcache_hit_colliding

                // dcache fill return
                begin: dcache_fill_return_colliding
                    begin: dcache_fill_return_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_fill_return_colliding_branch_flush
                            `event1_collides_event2(dcache_fill_return, branch_flush, i)
                        end
                    end: dcache_fill_return_colliding_branch_flush

                    begin: dcache_fill_return_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_fill_return_colliding_exception_flush
                            `event1_collides_event2(dcache_fill_return, exception_flush, i)
                        end
                    end: dcache_fill_return_colliding_exception_flush

                    begin: dcache_fill_return_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_fill_return_colliding_interrupt_flush
                            `event1_collides_event2(dcache_fill_return, interrupt_flush, i)
                        end
                    end: dcache_fill_return_colliding_interrupt_flush

                    begin: dcache_fill_return_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_fill_return_colliding_icache_flush
                            `event1_collides_event2(dcache_fill_return, icache_flush, i)
                        end
                    end: dcache_fill_return_colliding_icache_flush

                    begin: dcache_fill_return_colliding_dtlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_fill_return_colliding_dtlb_flush
                            `event1_collides_event2(dcache_fill_return, dtlb_flush, i)
                        end
                    end: dcache_fill_return_colliding_dtlb_flush

                    begin: dcache_fill_return_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dcache_fill_return_colliding_interrupt_pending
                            `event1_collides_event2(dcache_fill_return, interrupt_pending, i)
                        end
                    end: dcache_fill_return_colliding_interrupt_pending
                end: dcache_fill_return_colliding

            end: dcache_events_colliding

            // Dtlb
            begin: dtlb_events_colliding

                // Dtlb miss
                begin: dtlb_miss_colliding
                    begin: dtlb_miss_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_miss_colliding_branch_flush
                            `event1_collides_event2(dtlb_miss, branch_flush, i)
                        end
                    end: dtlb_miss_colliding_branch_flush

                    begin: dtlb_miss_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_miss_colliding_exception_flush
                            `event1_collides_event2(dtlb_miss, exception_flush, i)
                        end
                    end: dtlb_miss_colliding_exception_flush

                    begin: dtlb_miss_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_miss_colliding_interrupt_flush
                            `event1_collides_event2(dtlb_miss, interrupt_flush, i)
                        end
                    end: dtlb_miss_colliding_interrupt_flush

                    begin: dtlb_miss_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_miss_colliding_icache_flush
                            `event1_collides_event2(dtlb_miss, icache_flush, i)
                        end
                    end: dtlb_miss_colliding_icache_flush

                    begin: dtlb_miss_colliding_dtlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_miss_colliding_dtlb_flush
                            `event1_collides_event2(dtlb_miss, dtlb_flush, i)
                        end
                    end: dtlb_miss_colliding_dtlb_flush

                    begin: dtlb_miss_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_miss_colliding_interrupt_pending
                            `event1_collides_event2(dtlb_miss, interrupt_pending, i)
                        end
                    end: dtlb_miss_colliding_interrupt_pending
                end: dtlb_miss_colliding

                // Dtlb hit
                begin: dtlb_hit_colliding
                    begin: dtlb_hit_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_hit_colliding_branch_flush
                            `event1_collides_event2(dtlb_hit, branch_flush, i)
                        end
                    end: dtlb_hit_colliding_branch_flush

                    begin: dtlb_hit_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_hit_colliding_exception_flush
                            `event1_collides_event2(dtlb_hit, exception_flush, i)
                        end
                    end: dtlb_hit_colliding_exception_flush

                    begin: dtlb_hit_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_hit_colliding_interrupt_flush
                            `event1_collides_event2(dtlb_hit, interrupt_flush, i)
                        end
                    end: dtlb_hit_colliding_interrupt_flush

                    begin: dtlb_hit_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_hit_colliding_icache_flush
                            `event1_collides_event2(dtlb_hit, icache_flush, i)
                        end
                    end: dtlb_hit_colliding_icache_flush

                    begin: dtlb_hit_colliding_dtlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_hit_colliding_dtlb_flush
                            `event1_collides_event2(dtlb_hit, dtlb_flush, i)
                        end
                    end: dtlb_hit_colliding_dtlb_flush

                    begin: dtlb_hit_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_hit_colliding_interrupt_pending
                            `event1_collides_event2(dtlb_hit, interrupt_pending, i)
                        end
                    end: dtlb_hit_colliding_interrupt_pending
                end: dtlb_hit_colliding

                // Dtlb fill return
                begin: dtlb_fill_return_colliding
                    begin: dtlb_fill_return_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_fill_return_colliding_branch_flush
                            `event1_collides_event2(dtlb_fill_return, branch_flush, i)
                        end
                    end: dtlb_fill_return_colliding_branch_flush

                    begin: dtlb_fill_return_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_fill_return_colliding_exception_flush
                            `event1_collides_event2(dtlb_fill_return, exception_flush, i)
                        end
                    end: dtlb_fill_return_colliding_exception_flush

                    begin: dtlb_fill_return_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_fill_return_colliding_interrupt_flush
                            `event1_collides_event2(dtlb_fill_return, interrupt_flush, i)
                        end
                    end: dtlb_fill_return_colliding_interrupt_flush

                    begin: dtlb_fill_return_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_fill_return_colliding_icache_flush
                            `event1_collides_event2(dtlb_fill_return, icache_flush, i)
                        end
                    end: dtlb_fill_return_colliding_icache_flush

                    begin: dtlb_fill_return_colliding_dtlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_fill_return_colliding_dtlb_flush
                            `event1_collides_event2(dtlb_fill_return, dtlb_flush, i)
                        end
                    end: dtlb_fill_return_colliding_dtlb_flush

                    begin: dtlb_fill_return_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: dtlb_fill_return_colliding_interrupt_pending
                            `event1_collides_event2(dtlb_fill_return, interrupt_pending, i)
                        end
                    end: dtlb_fill_return_colliding_interrupt_pending
                end: dtlb_fill_return_colliding

            end: dtlb_events_colliding

            begin: lsu_events_following_each_other
                begin: dtlb_hit_followed_by_dcache_hit
                    `event2_follows_event1(dtlb_hit, dcache_hit, 5)
                end

                begin: dtlb_hit_followed_by_dcache_miss
                    `event2_follows_event1(dtlb_hit, dcache_miss, 5)
                end
            end: lsu_events_following_each_other

        end: lsu_cover_properties
    endgenerate

    /* ----- Declare cover groups here -----*/
    covergroup backend_exceptions_cg;
        /* --- Load page Fault ---*/
        lpf_bad_VA: coverpoint(canonical_violation && load_page_fault) iff (rsn_i) {ignore_bins ignore = {0};} // Bad VA or canonical violation, RTL should translate it into load page fault exception as per RISCV spec
        lpf_upage_violation: coverpoint(daccess_err && smode && lpf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // SUM is not set and we are trying to access a user page in supervisor mode for load op
        lpf_spage_violation: coverpoint(daccess_err && umode && lpf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // this is not a user page but we are in user mode and trying to access it for load op
        lpf_non_readable_page: coverpoint(dtlb_hit_for_load && !dtlb_pte_q.r && lpf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // DTLB hit entry for store op does not have W flag set
        lpf_non_accessed_page: coverpoint(dtlb_hit_for_load && !dtlb_pte_q.a && lpf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // DTLB hit entry for store op does not have W flag set
        lpf_during_page_table_walk: coverpoint(lpf_during_ptw) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // load page fault during page table walk due to any reason
        lpf_pte_invalid: coverpoint(valid_pte_rd_for_load && !pte.v) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // load page fault during page table walk due to PTE being invalid
        lpf_pte_illegal_rw_combination: coverpoint(valid_pte_rd_for_load && (!pte.r && pte.w)) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // writeable page without read permissions is an illegal combination in RISCV
        lpf_leaf_pte_a_flag_zero: coverpoint(legal_leaf_pte_rd_for_load && !pte.a) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // a flag is zero in leaf PTE read for load address translation
        lpf_leaf_pte_r_flag_zero: coverpoint(legal_leaf_pte_rd_for_load && !pte.r && !mxr_i) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // leaf page table entry has r=0. non readable page is also non write-able so it means it is execute only page, so check mxr field in mstatus is not set
        lpf_misaligned_superpage_1GB: coverpoint(legal_leaf_pte_rd_for_load && ptw_lvl_1 && pte.ppn[17:0] != '0) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // Allocation of 1 GiB misaligned superpage
        lpf_misaligned_superpage_2MB: coverpoint(legal_leaf_pte_rd_for_load && ptw_lvl_2 && pte.ppn[8:0] != '0) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // Allocation of 2 MiB misaligned superpage
        lpf_translation_too_deep: coverpoint(legal_nonleaf_pte_rd_for_load && ptw_lvl_3) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // Leaf page table entry is not found even at the last level (3rd for Sv39)

        /* --- Store page Fault ---*/
        spf_bad_VA: coverpoint(canonical_violation && store_amo_page_fault) iff (rsn_i) {ignore_bins ignore = {0};} // Bad VA or canonical violation, RTL should translate it into store page fault exception as per RISCV spec
        spf_upage_violation: coverpoint(daccess_err && smode && spf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // SUM is not set and we are trying to access a user page in supervisor mode for store op
        spf_spage_violation: coverpoint(daccess_err && umode && spf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // this is not a user page but we are in user mode and trying to access it for store op
        spf_non_writeable_page: coverpoint(dtlb_hit_for_store && !dtlb_pte_q.w && spf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // DTLB hit entry for store op does not have W flag set
        spf_non_dirty_page: coverpoint(dtlb_hit_for_store && !dtlb_pte_q.d && spf_from_dtlb_hit) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // DTLB hit entry for store op does not have W flag set
        spf_during_page_table_walk: coverpoint(spf_during_ptw) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // store page fault during page table walk due to any reason
        spf_pte_invalid: coverpoint(valid_pte_rd_for_store && !pte.v) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // store page fault during page table walk due to PTE being invalid
        spf_pte_illegal_rw_combination: coverpoint(valid_pte_rd_for_store && (!pte.r && pte.w)) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // writeable page without read permissions is an illegal combination in RISCV
        spf_leaf_pte_a_flag_zero: coverpoint(legal_leaf_pte_rd_for_store && !pte.a) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // a flag is zero in leaf PTE read for store address translation
        spf_leaf_pte_w_flag_zero: coverpoint(legal_leaf_pte_rd_for_store && !pte.w) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // leaf page table entry has w=0. store request going to either execute-only, read-only or read-execute page
        spf_leaf_pte_d_flag_zero: coverpoint(legal_leaf_pte_rd_for_store && !pte.d) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // leaf page table entry has d=0. generate page fault so that software can update PTEs!
        spf_misaligned_superpage_1GB: coverpoint(legal_leaf_pte_rd_for_store && ptw_lvl_1 && pte.ppn[17:0] != '0) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // Allocation of 1 GiB misaligned superpage
        spf_misaligned_superpage_2MB: coverpoint(legal_leaf_pte_rd_for_store && ptw_lvl_2 && pte.ppn[8:0] != '0) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // Allocation of 2 MiB misaligned superpage
        spf_translation_too_deep: coverpoint(legal_nonleaf_pte_rd_for_store && ptw_lvl_3) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // Leaf page table entry is not found even at the last level (3rd for Sv39)
        
        /* --- Address Misaligned ---*/
        load_address_misaligned: coverpoint(load_misaligned_exception) iff (rsn_i) {ignore_bins ignore = {0};}
        store_address_misaligned: coverpoint(store_misaligned_exception) iff (rsn_i) {ignore_bins ignore = {0};}

        /* --- Access Fault ---*/
        lsu_pa_outside_pa_boundary_wo_translation: coverpoint((resp_dcache_cpu_i.addr > ({32{1'b1}}-1)) && (from_rr_i.instr.unit == UNIT_MEM)) iff (rsn_i && !en_ld_st_translation_i) {ignore_bins ignore = {0};} // access fault according to orignal access type should be reported by RTL
        lsu_pa_outside_pa_boundary_wt_translation: coverpoint((resp_dcache_cpu_i.addr > ({32{1'b1}}-1)) && (from_rr_i.instr.unit == UNIT_MEM)) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};} // access fault according to orignal access type should be reported by RTL
        
        /* --- RISCV standard interrupts ---*/
        interrupts_valid: coverpoint(riscv_intrpts_valid) iff (rsn_i) {
                                                                        bins M_EXTERNAL      = {6'b10_0000};
                                                                        bins M_SOFTWARE      = {6'b01_0000};
                                                                        bins M_TIMER         = {6'b00_1000};
                                                                        bins S_EXTERNAL      = {6'b00_0100};
                                                                        bins S_SOFTWARE      = {6'b00_0010};
                                                                        bins S_TIMER         = {6'b00_0001};
                                                                    }

        
    endgroup: backend_exceptions_cg
    backend_exceptions_cg backend_exceptions_cg_inst;

    covergroup backend_structures_stressed_cg;
        // MMU
        dtlb_is_full: coverpoint(dtlb_full) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};}
        dtlb_is_full_with_4KiB_pages: coverpoint(dtlb_full_with_4kb_pages) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};}
        dtlb_is_full_with_2MiB_pages: coverpoint(dtlb_full_with_2mb_pages) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};}
        dtlb_is_full_with_mix_page_sizes: coverpoint(dtlb_full_with_mix_page_sizes) iff (rsn_i && en_ld_st_translation_i) {ignore_bins ignore = {0};}
        dtlb_flush_comes_when_dtlb_was_full: coverpoint(dtlb_full && dtlb_flush) iff (rsn_i) {ignore_bins ignore = {0};}
        ptw_req_for_dtlb_itlb_collide: coverpoint(ptw_req_for_dtlb_miss && ptw_req_for_itlb_miss) iff (rsn_i) {ignore_bins ignore = {0};} //dtlb and itlb miss at the same cycle trying to trigger simultaneous page table walk. RTL gives priority to DTLB miss!
        // Dcache
        dcache_access_requests: coverpoint(dcache_rd_req) iff (rsn_i) {bins ld_ptw_st_access = {[1 : $]};} // dache can be access by load unit, ptw unit, and store unit simultaneously. Check whether we are covering all possible combinations of these three accesses?
    endgroup: backend_structures_stressed_cg
    backend_structures_stressed_cg backend_structures_stressed_cg_inst;

    covergroup backend_general_cg;
        interrupt_blocked_memop_inflight: coverpoint(interrupt_blocked) iff (rsn_i) {ignore_bins ignore = {0};} // block the pending interrupt from getting valid/taken if there is pending memory operation
        lsu_4KiB_page_allocation: coverpoint(|entry_has_4kb_page) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        lsu_2MiB_page_allocation: coverpoint(|entry_has_2mb_page) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        lsu_1GiB_page_allocation: coverpoint(|entry_has_1gb_page) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        dtlb_has_all_page_sizes: coverpoint(dtlb_has_all_page_size) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        dtlb_multi_hit: coverpoint($countones(dtlb_lu_hit) > 1) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // We can hit if there is a base page lying inside a super-page, both pages are in different DTLB entries, and we try to access shared region. Software bug, RTL should be able to handle it???
        access_nc_addr_dc_disable: coverpoint((|paddr_is_nc) && ~dcache_en_i) iff (rsn_i) {ignore_bins ignore = {0};} // fetch from non cacheable addr due to dcache being disabled from a custom CSR
        access_nc_addr_pma: coverpoint((|paddr_is_nc) && dcache_en_i) iff (rsn_i) {ignore_bins ignore = {0};} // fetch from non cacheable addr : region has non cacheable physical memory attribute (PMA). dcache is enabled though!
        // PMU : pipeline stages stall
        pipeline_stages_stall: coverpoint(stall_pipeline_stages) iff (rsn_i) {wildcard bins ifu_stall = {5'b????1};
                                                                              wildcard bins decode_stall = {5'b???1?};
                                                                              wildcard bins read_register_stall = {5'b??1??};
                                                                              wildcard bins exu_stall = {5'b?1???};
                                                                              wildcard bins write_back_stall = {5'b1????};
                                                                              wildcard bins stall_combinations[] = {[5'b00001 : 5'b00011], [5'b00100 : 5'b00111], [5'b01000 : 5'b01011], [5'b10000 : 5'b10011]};   // 15 separate bins should be created, upper 3 bits can be onehot only
                                                                              ignore_bins ignore = {5'b00000};
                                                                             }
        
        // PMU : pipeline stages flush
        pipeline_stages_flush: coverpoint(pipeline_stages_flush) iff (rsn_i) {wildcard bins ifu_flush = {5'b????1};
                                                                              wildcard bins decode_flush = {5'b???1?};
                                                                              wildcard bins read_register_flush = {5'b??1??};
                                                                              wildcard bins exu_flush = {5'b?1???};
                                                                              //wildcard bins write_back_flush = {5'b1????}; not possible
                                                                              bins flush_possible_combinations[] = {5'b01111, 5'b01000, 5'b01110, 5'b00111, 5'b00001}; 
                                                                              ignore_bins ignore = {5'b00000};
                                                                             }
         
        // PMU : Exu stall due to different ops
        `ifdef FPU_IS_PRESENT
            exu_stall: coverpoint(exu_stalling_ops) iff (rsn_i) {wildcard bins mul_stall = {4'b???1};
                                                                 wildcard bins div_stall = {4'b??1?};
                                                                 wildcard bins mem_stall = {4'b?1??};
                                                                 wildcard bins fpu_stall = {4'b1???};
                                                                 ignore_bins ignore = {0};
                                                                }
        `else
            exu_stall: coverpoint(exu_stalling_ops) iff (rsn_i) {wildcard bins mul_stall = {3'b??1};
                                                                 wildcard bins div_stall = {3'b?1?};
                                                                 wildcard bins mem_stall = {3'b1??};
                                                                 ignore_bins ignore = {0};
                                                                }                                                
        `endif

        // EXU operand/register forwarding/bypassing
        exu_bypass: coverpoint(forwarded_regs) iff (rsn_i) {bins bypass_reg_combinations[] = {[1 : $]};} // All possible combinations of source registers forwarding/bypasing

    endgroup: backend_general_cg
    backend_general_cg backend_general_cg_inst;

    covergroup pmu_events_cg with function sample(bit [BRANCH_PMU_EVENTS-1:0] sig, int position);
        branch_PMU_events: coverpoint (position) iff (sig[position]==1) {bins pmu_branch_events[] = {[0:BRANCH_PMU_EVENTS-1]};}
    endgroup: pmu_events_cg
    pmu_events_cg pmu_events_cg_inst;

    /* ----- Instantiate cover groups here -----*/
    initial
    begin
        backend_exceptions_cg_inst          =   new();
        backend_structures_stressed_cg_inst =   new();
        backend_general_cg_inst             =   new();
        pmu_events_cg_inst                  =   new();
    end

    /* ----- Sample cover groups here -----*/
    always @ (negedge clk_i)
    begin
        backend_exceptions_cg_inst.sample();
        backend_structures_stressed_cg_inst.sample();
        backend_general_cg_inst.sample();

        for(int i=0; i<BRANCH_PMU_EVENTS; i++) begin
            pmu_events_cg_inst.sample(branch_pmu_events, i);
        end
    end

endmodule

// bind lagarto_m20 cov_backend coverage_backend (
//     .clk_i(core_ref_clk),
//     .rsn_i(sys_rst_n)
// );