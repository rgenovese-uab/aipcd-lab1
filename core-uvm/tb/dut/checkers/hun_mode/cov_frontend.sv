/* -----------------------------------------------------------
* Project Name  : MEEP
* Organization  : Barcelona Supercomputing Center
* Email         : zeeshan.ali@bsc.es-
* Description   : To code uArchitectural functional coverpoints and cover properties
                : for frontend of the core (fetch, decode, read register stages)
* ------------------------------------------------------------*/
import drac_pkg::*;
import riscv_pkg::*;
import ariane_pkg::*;
import wt_cache_pkg::*;
import EPI_pkg::*;
import cov_core_defs::*;

module cov_frontend (
    input logic                                             clk_i,
    input logic                                             rsn_i,
    input logic                                             en_translation_i,       // translation is enabled if SATP.MODE = Sv39 && current_priv_mode != MACHINE
    input logic                                             en_ld_st_translation_i, // if ((VM mode is Sv39 in SATP AND current priv mode != Machine) OR (mprv == 1 && mpp != Machine && stap.mode == Sv39))
    input logic                                             iaccess_err,            // insufficient privilege to access this instruction page (U flag violation)
    input riscv::priv_lvl_t                                 priv_lvl_i,
    input ariane_pkg::icache_areq_i_t                       icache_areq_o,
    input ariane_pkg::icache_areq_o_t                       icache_areq_i,
    input logic                                             match_any_execute_region,
    input logic                                             pte_lookup,
    input logic                                             data_rvalid_q,          // PTE data read from dcache/memory is valid on this cycle
    input riscv::pte_t                                      pte,
    input logic                                             walking_instr,          // PTW is walking because of an ITLB miss
    input logic                                             ptw_lvl_1, ptw_lvl_2, ptw_lvl_3,
    // icache events
    input logic [ariane_pkg::ICACHE_SET_ASSOC-1:0]          cl_hit,
    input logic                                             icache_miss,
    input logic                                             icache_flush,
    input logic                                             icache_fill_return,
    // itlb events
    input logic                                             itlb_hit,
    input logic                                             dtlb_hit,
    input logic                                             itlb_miss,
    input logic                                             itlb_flush,
    input logic                                             itlb_fill_return,
    // flushes
    input drac_pkg::exe_cu_t                                exe_cu_i,
    input drac_pkg::pipeline_ctrl_t                         pipeline_ctrl_int,
    input logic                                             correct_branch_pred_i,
    input drac_pkg::id_cu_t                                 id_cu_i,
    input bus64_t                                           csr_cause,
    input logic                                             csr_excpt_intrpt,
    input logic                                             interrupt_pending,
    input logic                                             ifu_dispatch_valid,
    input tlb_tags_q_t                                      itlb_tags_q,
    input logic [TLB_ENTRIES-1:0]                           itlb_lu_hit,
    input logic                                             itlb_access_i,
    input logic                                             dtlb_access_i,
    // branch prediction
    input logic                                             branch_at_exu,
    input drac_pkg::addrPC_t                                pc_execution_i,
    input logic                                             paddr_is_nc,
    input logic                                             cache_en_q
    );

    /* ----- Declare internal signals & develop internal logic for coverage here -----*/ 
    logic canonical_violation;
    logic [XLEN-1:0] fe_exception_cause;
    logic fe_exception_valid;
    logic smode, umode;
    logic instr_page_fault;
    logic instr_access_fault;
    logic too_big_pa;
    logic pte_is_invalid;
    logic valid_pte_rd_for_pc;
    logic valid_leaf_pte;
    logic valid_non_leaf_pte;
    logic icache_hit;
    logic branch_flush;
    logic exception_flush;          // exception is taken
    logic interrupt_flush;          // interrupt is taken
    logic [TLB_ENTRIES-1: 0] itlb_entry_valid;
    logic itlb_full;
    logic itlb_full_with_4kb_pages;
    logic itlb_full_with_2mb_pages;
    logic itlb_full_with_mix_page_sizes;
    logic itlb_has_all_page_size;
    logic [TLB_ENTRIES-1: 0] entry_has_4kb_page;
    logic [TLB_ENTRIES-1: 0] entry_has_2mb_page;
    logic [TLB_ENTRIES-1: 0] entry_has_1gb_page;
    logic ptw_req_for_itlb_miss;
    logic ptw_req_for_dtlb_miss;
    logic [MOST_SIGNIFICATIVE_INDEX_BIT_BP : LEAST_SIGNIFICATIVE_INDEX_BIT_BP] btb_index_from_pc;


    assign canonical_violation              = (icache_areq_i.fetch_req && !((&icache_areq_i.fetch_vaddr[riscv::VLEN-1:IMPLEMENTED_VA_SIZE-1]) == 1'b1 || (|icache_areq_i.fetch_vaddr[riscv::VLEN-1:IMPLEMENTED_VA_SIZE-1]) == 1'b0));
    assign fe_exception_cause               = icache_areq_o.fetch_exception.cause;
    assign fe_exception_valid               = icache_areq_o.fetch_exception.valid;
    assign smode                            = (priv_lvl_i == riscv::PRIV_LVL_S)? 1'b1 : 1'b0;
    assign umode                            = (priv_lvl_i == riscv::PRIV_LVL_U)? 1'b1 : 1'b0;
    assign instr_page_fault                 = (fe_exception_valid && fe_exception_cause == riscv::INSTR_PAGE_FAULT)? 1'b1 : 1'b0;
    assign instr_access_fault               = (fe_exception_valid && fe_exception_cause == riscv::INSTR_ACCESS_FAULT)? 1'b1 : 1'b0;
    assign too_big_pa                       = icache_areq_o.fetch_paddr > ({IMPLEMENTED_PA_SIZE{1'b1}} - 1);
    assign pte_is_invalid                   = !pte.v || (!pte.r && pte.w);
    assign valid_pte_rd_for_pc              = pte_lookup && data_rvalid_q && walking_instr;
    assign valid_leaf_pte                   = valid_pte_rd_for_pc && !pte_is_invalid && (pte.r || pte.x);
    assign valid_non_leaf_pte               = valid_pte_rd_for_pc && !pte_is_invalid && !(pte.r || pte.x);
    assign icache_hit                       = |cl_hit;
    assign branch_flush                     = (exe_cu_i.valid && ~correct_branch_pred_i && !pipeline_ctrl_int.stall_exe) || id_cu_i.valid_jal; // coditional branch mispredicted at EXE || unpredicted jal at id stage
    assign exception_flush                  = csr_excpt_intrpt && !csr_cause[XLEN-1];
    assign interrupt_flush                  = csr_excpt_intrpt && csr_cause[XLEN-1];
    assign itlb_full                        = &itlb_entry_valid;
    assign itlb_full_with_4kb_pages         = &entry_has_4kb_page;
    assign itlb_full_with_2mb_pages         = &entry_has_2mb_page;
    assign itlb_has_all_page_size           = (|entry_has_4kb_page && |entry_has_2mb_page  && |entry_has_1gb_page);
    assign itlb_full_with_mix_page_sizes    = itlb_has_all_page_size & itlb_full;
    assign ptw_req_for_itlb_miss            = en_translation_i &  itlb_access_i & ~itlb_hit;
    assign ptw_req_for_dtlb_miss            = en_ld_st_translation_i & dtlb_access_i & ~dtlb_hit;
    assign btb_index_from_pc                = branch_at_exu ?   pc_execution_i[MOST_SIGNIFICATIVE_INDEX_BIT_BP : LEAST_SIGNIFICATIVE_INDEX_BIT_BP]  :   'bx;
    
    always_comb begin
        for (int entry=0; entry<TLB_ENTRIES; entry++) begin
            itlb_entry_valid[entry]     = itlb_tags_q[entry].valid;
            entry_has_4kb_page[entry]   = !itlb_tags_q[entry].is_2M && !itlb_tags_q[entry].is_1G && itlb_tags_q[entry].valid;
            entry_has_2mb_page[entry]   = itlb_tags_q[entry].is_2M && itlb_tags_q[entry].valid;
            entry_has_1gb_page[entry]   = itlb_tags_q[entry].is_1G && itlb_tags_q[entry].valid;
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
        @(negedge clk_i) disable iff(~rsn_i && ~en_translation_i) \
        ``sig1`` |=> ((!$rose(``sig1``)) throughout (##[0:``window``] ``sig2``)); \
    endproperty \
    cover property(``sig2``_follows_``sig1``_``window``_p);

    // macro to track BTB aliasing: BTB aliasimg means, two different PCs having branch instructions are indexing into the same BTB entry, corrupting each others' history. 
    // Two branch instructions 128 bytes apart from each other will alias in the BTB as BTB is indexed by PC[6:1].
    // Save BTB index and PC of the first branch and check after any number of clock cycles later, branch instruction from a DIFFERENT PC is indexing into the SAME BTB entry
    `define track_btb_aliasing \
    sequence btb_alias_seq; \
        logic [MOST_SIGNIFICATIVE_INDEX_BIT_BP : LEAST_SIGNIFICATIVE_INDEX_BIT_BP] btb_index_first_branch; \
        addrPC_t pc_first_branch; \
        (branch_at_exu, btb_index_first_branch = btb_index_from_pc, pc_first_branch = pc_execution_i) ##[1:$] (branch_at_exu && (btb_index_from_pc == btb_index_first_branch) && (pc_execution_i != pc_first_branch)); \
    endsequence \
    property track_btb_aliasing_p; \
        @(negedge clk_i) disable iff (~rsn_i)\
        btb_alias_seq \
    endproperty \
    cover property(track_btb_aliasing_p);

    
    /* ----- Declare cover properties here -----*/ 
    generate
        begin: ifu_cover_properties

            // Icache
            begin: icache_events_colliding

                // Icache miss
                begin: icache_miss_colliding
                    begin: icache_miss_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_miss_colliding_branch_flush
                            `event1_collides_event2(icache_miss, branch_flush, i)
                        end
                    end: icache_miss_colliding_branch_flush

                    begin: icache_miss_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_miss_colliding_exception_flush
                            `event1_collides_event2(icache_miss, exception_flush, i)
                        end
                    end: icache_miss_colliding_exception_flush

                    begin: icache_miss_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_miss_colliding_interrupt_flush
                            `event1_collides_event2(icache_miss, interrupt_flush, i)
                        end
                    end: icache_miss_colliding_interrupt_flush

                    begin: icache_miss_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_miss_colliding_icache_flush
                            `event1_collides_event2(icache_miss, icache_flush, i)
                        end
                    end: icache_miss_colliding_icache_flush

                    begin: icache_miss_colliding_itlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_miss_colliding_itlb_flush
                            `event1_collides_event2(icache_miss, itlb_flush, i)
                        end
                    end: icache_miss_colliding_itlb_flush

                    begin: icache_miss_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_miss_colliding_interrupt_pending
                            `event1_collides_event2(icache_miss, interrupt_pending, i)
                        end
                    end: icache_miss_colliding_interrupt_pending
                end: icache_miss_colliding

                // Icache hit
                begin: icache_hit_colliding
                    begin: icache_hit_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_hit_colliding_branch_flush
                            `event1_collides_event2(icache_hit, branch_flush, i)
                        end
                    end: icache_hit_colliding_branch_flush

                    begin: icache_hit_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_hit_colliding_exception_flush
                            `event1_collides_event2(icache_hit, exception_flush, i)
                        end
                    end: icache_hit_colliding_exception_flush

                    begin: icache_hit_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_hit_colliding_interrupt_flush
                            `event1_collides_event2(icache_hit, interrupt_flush, i)
                        end
                    end: icache_hit_colliding_interrupt_flush

                    begin: icache_hit_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_hit_colliding_icache_flush
                            `event1_collides_event2(icache_hit, icache_flush, i)
                        end
                    end: icache_hit_colliding_icache_flush

                    begin: icache_hit_colliding_itlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_hit_colliding_itlb_flush
                            `event1_collides_event2(icache_hit, itlb_flush, i)
                        end
                    end: icache_hit_colliding_itlb_flush

                    begin: icache_hit_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_hit_colliding_interrupt_pending
                            `event1_collides_event2(icache_hit, interrupt_pending, i)
                        end
                    end: icache_hit_colliding_interrupt_pending
                end: icache_hit_colliding

                // Icache fill return
                begin: icache_fill_return_colliding
                    begin: icache_fill_return_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_fill_return_colliding_branch_flush
                            `event1_collides_event2(icache_fill_return, branch_flush, i)
                        end
                    end: icache_fill_return_colliding_branch_flush

                    begin: icache_fill_return_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_fill_return_colliding_exception_flush
                            `event1_collides_event2(icache_fill_return, exception_flush, i)
                        end
                    end: icache_fill_return_colliding_exception_flush

                    begin: icache_fill_return_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_fill_return_colliding_interrupt_flush
                            `event1_collides_event2(icache_fill_return, interrupt_flush, i)
                        end
                    end: icache_fill_return_colliding_interrupt_flush

                    begin: icache_fill_return_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_fill_return_colliding_icache_flush
                            `event1_collides_event2(icache_fill_return, icache_flush, i)
                        end
                    end: icache_fill_return_colliding_icache_flush

                    begin: icache_fill_return_colliding_itlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_fill_return_colliding_itlb_flush
                            `event1_collides_event2(icache_fill_return, itlb_flush, i)
                        end
                    end: icache_fill_return_colliding_itlb_flush

                    begin: icache_fill_return_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: icache_fill_return_colliding_interrupt_pending
                            `event1_collides_event2(icache_fill_return, interrupt_pending, i)
                        end
                    end: icache_fill_return_colliding_interrupt_pending
                end: icache_fill_return_colliding

            end: icache_events_colliding

            // Itlb
            begin: itlb_events_colliding

                // Itlb miss
                begin: itlb_miss_colliding
                    begin: itlb_miss_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_miss_colliding_branch_flush
                            `event1_collides_event2(itlb_miss, branch_flush, i)
                        end
                    end: itlb_miss_colliding_branch_flush

                    begin: itlb_miss_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_miss_colliding_exception_flush
                            `event1_collides_event2(itlb_miss, exception_flush, i)
                        end
                    end: itlb_miss_colliding_exception_flush

                    begin: itlb_miss_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_miss_colliding_interrupt_flush
                            `event1_collides_event2(itlb_miss, interrupt_flush, i)
                        end
                    end: itlb_miss_colliding_interrupt_flush

                    begin: itlb_miss_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_miss_colliding_icache_flush
                            `event1_collides_event2(itlb_miss, icache_flush, i)
                        end
                    end: itlb_miss_colliding_icache_flush

                    begin: itlb_miss_colliding_itlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_miss_colliding_itlb_flush
                            `event1_collides_event2(itlb_miss, itlb_flush, i)
                        end
                    end: itlb_miss_colliding_itlb_flush

                    begin: itlb_miss_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_miss_colliding_interrupt_pending
                            `event1_collides_event2(itlb_miss, interrupt_pending, i)
                        end
                    end: itlb_miss_colliding_interrupt_pending
                end: itlb_miss_colliding

                // Itlb hit
                begin: itlb_hit_colliding
                    begin: itlb_hit_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_hit_colliding_branch_flush
                            `event1_collides_event2(itlb_hit, branch_flush, i)
                        end
                    end: itlb_hit_colliding_branch_flush

                    begin: itlb_hit_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_hit_colliding_exception_flush
                            `event1_collides_event2(itlb_hit, exception_flush, i)
                        end
                    end: itlb_hit_colliding_exception_flush

                    begin: itlb_hit_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_hit_colliding_interrupt_flush
                            `event1_collides_event2(itlb_hit, interrupt_flush, i)
                        end
                    end: itlb_hit_colliding_interrupt_flush

                    begin: itlb_hit_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_hit_colliding_icache_flush
                            `event1_collides_event2(itlb_hit, icache_flush, i)
                        end
                    end: itlb_hit_colliding_icache_flush

                    begin: itlb_hit_colliding_itlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_hit_colliding_itlb_flush
                            `event1_collides_event2(itlb_hit, itlb_flush, i)
                        end
                    end: itlb_hit_colliding_itlb_flush

                    begin: itlb_hit_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_hit_colliding_interrupt_pending
                            `event1_collides_event2(itlb_hit, interrupt_pending, i)
                        end
                    end: itlb_hit_colliding_interrupt_pending
                end: itlb_hit_colliding

                // Itlb fill return
                begin: itlb_fill_return_colliding
                    begin: itlb_fill_return_colliding_branch_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_fill_return_colliding_branch_flush
                            `event1_collides_event2(itlb_fill_return, branch_flush, i)
                        end
                    end: itlb_fill_return_colliding_branch_flush

                    begin: itlb_fill_return_colliding_exception_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_fill_return_colliding_exception_flush
                            `event1_collides_event2(itlb_fill_return, exception_flush, i)
                        end
                    end: itlb_fill_return_colliding_exception_flush

                    begin: itlb_fill_return_colliding_interrupt_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_fill_return_colliding_interrupt_flush
                            `event1_collides_event2(itlb_fill_return, interrupt_flush, i)
                        end
                    end: itlb_fill_return_colliding_interrupt_flush

                    begin: itlb_fill_return_colliding_icache_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_fill_return_colliding_icache_flush
                            `event1_collides_event2(itlb_fill_return, icache_flush, i)
                        end
                    end: itlb_fill_return_colliding_icache_flush

                    begin: itlb_fill_return_colliding_itlb_flush
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_fill_return_colliding_itlb_flush
                            `event1_collides_event2(itlb_fill_return, itlb_flush, i)
                        end
                    end: itlb_fill_return_colliding_itlb_flush

                    begin: itlb_fill_return_colliding_interrupt_pending
                        for (genvar i=0; i<WINDOW_SIZE; i++) begin: itlb_fill_return_colliding_interrupt_pending
                            `event1_collides_event2(itlb_fill_return, interrupt_pending, i)
                        end
                    end: itlb_fill_return_colliding_interrupt_pending
                end: itlb_fill_return_colliding

            end: itlb_events_colliding

            // IFU dispatch valid
            begin: ifu_dispatch_valid_colliding
                begin: ifu_dispatch_valid_colliding_branch_flush
                    for (genvar i=0; i<WINDOW_SIZE; i++) begin: ifu_dispatch_valid_colliding_branch_flush
                        `event1_collides_event2(ifu_dispatch_valid, branch_flush, i)
                    end
                end: ifu_dispatch_valid_colliding_branch_flush

                begin: ifu_dispatch_valid_colliding_exception_flush
                    for (genvar i=0; i<WINDOW_SIZE; i++) begin: ifu_dispatch_valid_colliding_exception_flush
                        `event1_collides_event2(ifu_dispatch_valid, exception_flush, i)
                    end
                end: ifu_dispatch_valid_colliding_exception_flush

                begin: ifu_dispatch_valid_colliding_interrupt_flush
                    for (genvar i=0; i<WINDOW_SIZE; i++) begin: ifu_dispatch_valid_colliding_interrupt_flush
                        `event1_collides_event2(ifu_dispatch_valid, interrupt_flush, i)
                    end
                end: ifu_dispatch_valid_colliding_interrupt_flush

                begin: ifu_dispatch_valid_colliding_icache_flush
                    for (genvar i=0; i<WINDOW_SIZE; i++) begin: ifu_dispatch_valid_colliding_icache_flush
                        `event1_collides_event2(ifu_dispatch_valid, icache_flush, i)
                    end
                end: ifu_dispatch_valid_colliding_icache_flush

                begin: ifu_dispatch_valid_colliding_itlb_flush
                    for (genvar i=0; i<WINDOW_SIZE; i++) begin: ifu_dispatch_valid_colliding_itlb_flush
                        `event1_collides_event2(ifu_dispatch_valid, itlb_flush, i)
                    end
                end: ifu_dispatch_valid_colliding_itlb_flush

                begin: ifu_dispatch_valid_colliding_interrupt_pending
                    for (genvar i=0; i<WINDOW_SIZE; i++) begin: ifu_dispatch_valid_colliding_interrupt_pending
                        `event1_collides_event2(ifu_dispatch_valid, interrupt_pending, i)
                    end
                end: ifu_dispatch_valid_colliding_interrupt_pending
            end: ifu_dispatch_valid_colliding

            begin: ifu_events_following_each_other
                begin: itlb_hit_followed_by_icache_hit
                    `event2_follows_event1(itlb_hit, icache_hit, 5)
                end

                begin: itlb_hit_followed_by_icache_miss
                    `event2_follows_event1(itlb_hit, icache_miss, 5)
                end
            end: ifu_events_following_each_other

            begin: frontend_general_cover_props
                begin: btb_aliasing
                    `track_btb_aliasing
                end
            end: frontend_general_cover_props

        end: ifu_cover_properties
    endgenerate

    /* ----- Declare cover groups here -----*/
    covergroup frontend_exceptions_cg;
        /* --- Instruction Page Faults ---*/
        ipf_bad_VA: coverpoint(canonical_violation && instr_page_fault) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // Bad VA or canonical violation, RTL should translate it into instruction page fault exception as per RISCV spec
        ipf_upage_violation: coverpoint(iaccess_err && smode && instr_page_fault) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}   // Attempt is made to access user instruction page in S mode (Note: MSTATUS.SUM field only impacts data pages)
        ipf_spage_violation: coverpoint(iaccess_err && umode && instr_page_fault) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}   // Attempt is made to access supervisor instruction page in U mode
        ipf_pte_invalid: coverpoint(valid_pte_rd_for_pc && !pte.v) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // PTE is invalid at PTE lookup state during PTW for ITLB miss
        ipf_pte_illegal_rw_combination: coverpoint(valid_pte_rd_for_pc && (!pte.r && pte.w)) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // writeable page without read permissions is an illegal combination in RISCV
        ipf_leaf_pte_no_x_permission: coverpoint(valid_leaf_pte && !pte.x) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // Leaf PTE is valid but does not grant execute page permissions
        ipf_leaf_pte_a_flag_zero: coverpoint(valid_leaf_pte && !pte.a) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // Leaf PTE is valid but has A flag zero, RTL should generate page fault to let software set A flag by updating PTEs (RISCV allows software as well as hardware management of A and D flags)
        ipf_misaligned_superpage_1GB: coverpoint(valid_leaf_pte && ptw_lvl_1 && pte.ppn[17:0] != '0) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // misaligned 1GB superpage translation. leaf PTE.PPN[17:0] bits not zero.
        ipf_misaligned_superpage_2MB: coverpoint(valid_leaf_pte && ptw_lvl_2 && pte.ppn[8:0] != '0) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // misaligned 2MB superpage translation. leaf PTE.PPN[8:0] bits not zero.
        ipf_translation_too_deep: coverpoint(valid_non_leaf_pte && ptw_lvl_3) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // Leaf PTE is not found even at the last(3rd) level.
        /* --- Instruction Access Faults ---*/
        iaf_too_big_pa_without_translation: coverpoint(too_big_pa && instr_access_fault) iff (rsn_i && !en_translation_i) {ignore_bins ignore = {0};}   // PA > physically available memory, translation is off (jump/branch amount is the culprit)
        iaf_too_big_pa_with_translation: coverpoint(too_big_pa && instr_access_fault) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}   // PA > physically available memory, translation is on (PTE.PPN or ITLB.PPN is the culprit)
        iaf_non_exutable_region_without_translation: coverpoint(!match_any_execute_region && !too_big_pa && instr_access_fault) iff (rsn_i && !en_translation_i) {ignore_bins ignore = {0};}  // PA is within the range of physically available memory but not inside the executable region, translation is off (PC incrementation is the culprit)
        iaf_non_exutable_region_with_translation: coverpoint(!match_any_execute_region && !too_big_pa && instr_access_fault) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}  // PA is within the range of physically available memory but not inside the executable region, translation is on (PTE.PPN or ITLB.PPN is the culprit)
    endgroup: frontend_exceptions_cg
    frontend_exceptions_cg frontend_exceptions_cg_inst;

    covergroup ifu_events_colliding_cg;
        ifu_dispatch_itlb_flush_icache_miss_collide: coverpoint(ifu_dispatch_valid && itlb_flush && icache_miss) iff (rsn_i) {ignore_bins ignore = {0};}   // All three occuring on same cycle, uArch limitation? sfence.vma flushes the pipeline as well making ifu dispatch invalid???
        ifu_dispatch_itlb_flush_icache_hit_collide: coverpoint(ifu_dispatch_valid && itlb_flush && icache_hit) iff (rsn_i) {ignore_bins ignore = {0};}     // uArch limitation? can icache hit & ifu dispatch valid occur at the same cycle given IFU is not pipelined???
        ifu_dispatch_icache_flush_itlb_miss_collide: coverpoint(ifu_dispatch_valid && icache_flush && itlb_miss) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}   // uArch limitation? will fence.i flush the pipeline as well aking ifu dispatch invalid? Moreover, can non pipelined design of IFU have dispatch valid and itlb miss on same cycle?
        ifu_dispatch_icache_flush_itlb_hit_collide: coverpoint(ifu_dispatch_valid && icache_flush && itlb_hit) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}     // same micro-architectural RTL limitations as mentioned above can make this coverpoint unreachable
    endgroup: ifu_events_colliding_cg
    ifu_events_colliding_cg ifu_events_colliding_cg_inst;

    covergroup frontend_structures_stressed_cg;
        // MMU
        itlb_is_full: coverpoint(itlb_full) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        itlb_is_full_with_4KiB_pages: coverpoint(itlb_full_with_4kb_pages) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        itlb_is_full_with_2MiB_pages: coverpoint(itlb_full_with_2mb_pages) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        itlb_is_full_with_mix_page_sizes: coverpoint(itlb_full_with_mix_page_sizes) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // Need atleast 1GiB + 2MiB + 14*4KiB total executable space + minimum 1GiB continuous executable space to hit this coverpoint.
        itlb_flush_comes_when_itlb_was_full: coverpoint(itlb_full && itlb_flush) iff (rsn_i) {ignore_bins ignore = {0};}
        ptw_req_for_itlb_dtlb_collide: coverpoint(ptw_req_for_itlb_miss && ptw_req_for_dtlb_miss) iff (rsn_i) {ignore_bins ignore = {0};} //itlb and dtlb miss at the same cycle trying to trigger simultaneous page table walk. RTL gives priority to DTLB miss!
        // branch prediction
        //is_branch_prediction_table_full: coverpoint(&is_branch_table_valid) iff (rsn_i) {ignore_bins ignore = {0};} // One way to fill this table is to have 64 branch instructions on consecutive PCs (PC[6:1] bits are used to index into branch prediction structures (is_branch table, btb, pht))
    endgroup: frontend_structures_stressed_cg
    frontend_structures_stressed_cg frontend_structures_stressed_cg_inst;

    covergroup frontend_general_cg;
        ifu_4KiB_page_allocation: coverpoint(|entry_has_4kb_page) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        ifu_2MiB_page_allocation: coverpoint(|entry_has_2mb_page) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        ifu_1GiB_page_allocation: coverpoint(|entry_has_1gb_page) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        itlb_has_all_page_sizes: coverpoint(itlb_has_all_page_size) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};}
        itlb_multi_hit: coverpoint($countones(itlb_lu_hit) > 1) iff (rsn_i && en_translation_i) {ignore_bins ignore = {0};} // We can hit if there is a base page lying inside a super-page, both pages are in different ITLB entries, and we try to access shared region. Software bug, RTL should be able to handle it???
        fetch_nc_addr_ic_disable: coverpoint(paddr_is_nc && ~cache_en_q) iff (rsn_i) {ignore_bins ignore = {0};} // fetch from non cacheable addr due to icache being disabled from a custom CSR
        fetch_nc_addr_pma: coverpoint(paddr_is_nc && cache_en_q) iff (rsn_i) {ignore_bins ignore = {0};} // fetch from non cacheable addr : region has non cacheable physical memory attribute (PMA). icache is enabled though!
    endgroup
    frontend_general_cg frontend_general_cg_inst;

    /* ----- Instantiate cover groups here -----*/
    initial
    begin
        frontend_exceptions_cg_inst             =   new();
        ifu_events_colliding_cg_inst            =   new();
        frontend_structures_stressed_cg_inst    =   new();
        frontend_general_cg_inst                =   new();
    end

    /* ----- Sample cover groups here -----*/
    always @ (negedge clk_i)
    begin
        frontend_exceptions_cg_inst.sample();
        ifu_events_colliding_cg_inst.sample();
        frontend_structures_stressed_cg_inst.sample();
        frontend_general_cg_inst.sample();
    end

endmodule

// bind lagarto_m20 cov_frontend coverage_frontend (
//     .clk_i(core_ref_clk),
//     .rsn_i(sys_rst_n)
// );