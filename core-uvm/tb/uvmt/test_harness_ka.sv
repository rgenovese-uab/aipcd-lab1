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
import EPI_pkg::*;
import vpu_pkg::*;
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

    // Variables: brom_if
    brom_if brom_if();

    //------------------------------------------ VPU
    //Variable: renaming_unit_if
    //VPU renaming unit virtual interface
    renaming_unit_if renaming_unit_if();

    // Variable: vreg_if
    // VPU registers virtual interface
    vreg_if  vreg_if();

    // Variable: mrf_if
    // VPU MRF Interface
    mrf_if  mrf_if();

    // Variable: restore_vstart_if
    // Restore event and enable bits interface for vstarts != 0
    restore_vstart_if restore_vstart_if();

    // Variable: m_ovi_if
    // OVI Interface
    ovi_if m_ovi_if();

    // Variable: vpu_if.ovi
    // OVI Interface
    vpu_if vpu_if(m_ovi_if, renaming_unit_if, vreg_if, restore_vstart_if);


// Variables
    uint64_t io_reset_address;

    logic [1:0]             csr_priv_lvl;

    logic                          csr_spi_config = '0;
    logic                          en_ld_st_translation;
    logic                          en_translation;

    ptw_dmem_comm_t ptw_dmem_comm;
    dmem_ptw_comm_t dmem_ptw_comm;

    assign dmem_ptw_comm.dmem_ready = dc_if.dcache_req_ready[0];
    assign dmem_ptw_comm.resp.valid = dc_if.dcache_resp_valid[0];
    assign dmem_ptw_comm.resp.data = (HPDCACHE_REQ_WORDS == 1) ? dc_if.dcache_resp[0].rdata :
                                 dc_if.dcache_resp[0].rdata[ptw_dmem_comm.req.addr[$clog2(HPDCACHE_REQ_WORDS)+(HPDCACHE_REQ_WORDS==1)+2:3]];

// Module instantiation

    boot_rom u_boot_rom(
        .i_clk      ( clock_if.clk      ),
        .i_rsn      ( reset_if.rsn      ),
        .brom_if    ( brom_if           ),
        .i_rst_addr ( io_reset_address  )
    );

    lagarto_ka_subtop core( // TODO cleanup unused signals
        //------------------------------------------------------------------------------------
        // ORIGINAL INPUTS OF LAGARTO
        //------------------------------------------------------------------------------------
        .CLK			( clock_if.clk		),
        .RST			( reset_if.rsn		),
        .SOFT_RST		( '0				),
        .RESET_ADDRESS	( io_reset_address	),
        .CORE_ID        ( 64'b0             ),
        //------------------------------------------------------------------------------------
        // DEBUG RING SIGNALS INPUT
        // debug_halt_i is istall_test
        //------------------------------------------------------------------------------------
        .debug_halt_i	( '0 ),          // Halt core / debug mode
        .debug_pc_addr_i('0),            // Address to set in the PC of the fetch stage
        .debug_pc_valid_i('0),           // Write the address debug_pc_addr_i into the PC of the fetch stage
        .debug_reg_read_valid_i('0),     // Read the physical register address corresponding to the register indicated in debug_reg_read_addr_i
        .debug_reg_read_addr_i('0),      // Address of the architectural register to be translated to the physical register address
        .debug_preg_write_valid_i('0),   // Enable the write of debug_preg_write_data_i into the physical register indicated by debug_preg_addr_i
        .debug_preg_write_data_i('0),    // Data to write into the physical register indicated by debug_preg_read_valid_i
        .debug_preg_addr_i('0),          // Address of the physical register which will be read or written into
        .debug_preg_read_valid_i('0),    // Enable the read of the contents of the physical register indicated by debug_preg_addr_i
        //-----------------------------------------------------------------------------------
        // DEBUGGING MODULE SIGNALS
        //-----------------------------------------------------------------------------------
        .debug_fetch_pc_o(),             // PC of the instr. at fetch stage
        .debug_decode_pc_o(),            // PC of the instr. at decode stage
        .debug_register_read_pc_o(),     // PC of the instr. at register read stage
        .debug_execute_pc_o(),           // PC of the instr. at execute stage
        .debug_writeback_pc_p0_o(),      // PC of the instr. at writeback stage
        .debug_writeback_pc_p1_o(),      // PC of the instr. at writeback stage
        .debug_writeback_pc_valid_p0_o(),// Indicates if the instr. at writeback stage is valid
        .debug_writeback_pc_valid_p1_o(),// Indicates if the instr. at writeback stage is valid
        .debug_writeback_addr_o(),       // Address of the destination register of the instr. at writeback
        .debug_writeback_we_p0_o(),      // Indicates if the instr. at writeback stage writes to the regfile
        .debug_writeback_we_p1_o(),      // Indicates if the instr. at writeback stage writes to the regfile
        // .debug_mem_addr_o(),             // Address of the latest access to memory
        // .debug_backend_empty_o(),        // Indicates if the backend is empty (i.e. no instruction in the graduation list)
        .debug_preg_addr_o(),            // Physical register address corresponding to the register indicated by debug_reg_read_addr_i
        .debug_preg_data_o(),            // Data contained in the register indicated by debug_preg_addr_i

        //-----------------------------------------------------------------------------
        // BOOTROM CONTROLER INTERFACE
        //-----------------------------------------------------------------------------
        .brom_ready_i			( brom_if.req.ready 	 ),
        .brom_resp_data_i		( brom_if.resp.bits_data ),
        .brom_resp_valid_i		( brom_if.resp.valid	 ),
        .brom_req_address_o	( brom_if.req.addr		 ),
        .brom_req_valid_o		( brom_if.req.valid	 ),

        .csr_spi_config_i	( csr_spi_config ),

        //-------------------------------------------------------------------------------------------------
        // I-CACHE INPUT INTERFACE
        //-------------------------------------------------------------------------------------------------
        .iflush_o			(),
        .lagarto_ireq_o	( ic_if.lagarto_ireq	),

        //-------------------------------------------------------------------------------------------------
        // I-CACHE OUTPUT INTERFACE
        //-------------------------------------------------------------------------------------------------
        .icache_resp_i	( ic_if.icache_resp ),

        //-------------------------------------------------------------------------------------------------
        // D-CACHE  INTERFACE
        //-------------------------------------------------------------------------------------------------
        //request
        .dcache_req_valid_o	( dc_if.dcache_req_valid[1] ),
        .dcache_req_o			( dc_if.dcache_req[1] 	 ),

        //response
        .dcache_req_ready_i	( dc_if.dcache_req_ready  ),
        .dcache_rsp_valid_i	( dc_if.dcache_resp_valid ),
        .dcache_rsp_i			( dc_if.dcache_resp	  ),
        .wbuf_empty_i			( dc_if.wbuf_empty		  ),
        .dmem_is_store_o		(),
        .dmem_is_load_o		(),

        //-------------------------------------------------------------------------------------------------
        // CSR
        //-------------------------------------------------------------------------------------------------
        .addr_csr_hpm		(),
        .data_csr_hpm		(),
        .data_hpm_csr		(),
        .we_csr_hpm		(),
        .csr_priv_lvl_o	( csr_priv_lvl		 ),
        .en_translation_o	( en_translation ),
        //-----------------------------------------------------------------------------
        // PCR
        //-----------------------------------------------------------------------------
        //PCR req inputs
        .pcr_req_ready_i	(), // ready bit of the pcr
        //PCR resp inputs
        .pcr_resp_valid_i		(), // ready bit of the pcr
        .pcr_resp_data_i		(), // read data from performance counter module
        .pcr_resp_core_id_i	(), // core id of the tile that the date is sended

        //PCR outputs request
        .pcr_req_valid_o	(), // valid bit to make a pcr request
        .pcr_req_addr_o	(), // read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
        .pcr_req_data_o	(), // write data to performance counter module
        .pcr_req_we_o		(), // Cmd of the petition
        .pcr_req_core_id_o	(), // core id of the tile

        //-----------------------------------------------------------------------------
        // INTERRUPTS
        //-----------------------------------------------------------------------------
        .soft_irq_i( int_if.m_soft_irq ),
        .time_irq_i	(int_if.time_irq), // timer interrupt
        .irq_i			(int_if.irq), // external interrupt in
        .time_i		(), // time passed since the core is reset

        //------------------------------------------------------------------------------------------------
        // INSTRUCTION NON-CACHEABLE BUFFER
        //------------------------------------------------------------------------------------------------
        //- From L2
        .io_mem_grant_valid		(),
        .io_mem_grant_bits_data	(),
        //------------------------------------------------------------------------------------------------
        // PMU INTERFACE
        //------------------------------------------------------------------------------------------------
        .pmu_counters_o	(),
        //------------------------------------------------------------------------------------------------
        // PTW INTERFACE
        //------------------------------------------------------------------------------------------------

        .itlb_ptw_comm_i	(),
        .ptw_itlb_comm_o	(),

        .dmem_ptw_comm_i	( dmem_ptw_comm ),
        .ptw_dmem_comm_o	( ptw_dmem_comm ),

        .pmu_ptw_hit_o		(),
        .pmu_ptw_miss_o	    (),
        .pmu_dtlb_access_o  (),
        .pmu_dtlb_miss_o    ()

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

    assign m_ovi_if.clk = clock_if.clk;
    assign m_ovi_if.rsn = reset_if.rsn;

    // VPU interfaces
    assign m_ovi_if.issue_valid = core.vitruvius.vpu.issue_i.valid;
    assign m_ovi_if.issue_instr = core.vitruvius.vpu.issue_i.inst ;
    assign m_ovi_if.issue_data = core.vitruvius.vpu.issue_i.scalar_opnd ;
    assign m_ovi_if.issue_sb_id = core.vitruvius.vpu.issue_i.sb_id ;
    assign m_ovi_if.issue_csr = core.vitruvius.vpu.issue_i.vcsr ;
    assign m_ovi_if.issue_credit = core.vitruvius.vpu.issue_credit_o ;

    assign m_ovi_if.dispatch_sb_id = core.vitruvius.vpu.dispatch_i.sb_id ;
    assign m_ovi_if.dispatch_nxt_sen = core.vitruvius.vpu.dispatch_i.next_senior ;
    assign m_ovi_if.dispatch_kill = core.vitruvius.vpu.dispatch_i.kill ;

    assign m_ovi_if.completed_sb_id = core.vitruvius.vpu.completed_o.sb_id ;
    assign m_ovi_if.completed_fflags = core.vitruvius.vpu.completed_o.fflags ;
    assign m_ovi_if.completed_vxsat = core.vitruvius.vpu.completed_o.vxsat ;
    assign m_ovi_if.completed_valid = core.vitruvius.vpu.completed_o.valid ;
    assign m_ovi_if.completed_dst_reg = core.vitruvius.vpu.completed_o.xdst ;
    assign m_ovi_if.completed_vstart = core.vitruvius.vpu.completed_o.vstart ;
    assign m_ovi_if.completed_illegal = core.vitruvius.vpu.completed_o.illegal ;

    assign m_ovi_if.memop_sync_start = core.vitruvius.vpu.memop_sync_start_o ;
    assign m_ovi_if.memop_start_sb_id = core.vitruvius.vpu.memop_sb_id_i ;
    assign m_ovi_if.memop_sync_end = core.vitruvius.vpu.memop_sync_end_i ;
    assign m_ovi_if.memop_sb_id = core.vitruvius.vpu.memop_sb_id_i ;
    assign m_ovi_if.memop_vstart_vlfof = core.vitruvius.vpu.memop_vstart_vlfof_i ;

    assign m_ovi_if.load_valid = core.vitruvius.vpu.load_valid_i ;
    assign m_ovi_if.load_data = core.vitruvius.vpu.load_data_i ;
    assign m_ovi_if.load_seq_id = core.vitruvius.vpu.load_seq_id_i ;
    assign m_ovi_if.load_mask_valid = core.vitruvius.vpu.load_mask_valid_i ;
    assign m_ovi_if.load_mask = core.vitruvius.vpu.load_mask_i ;

    assign m_ovi_if.store_valid = core.vitruvius.vpu.store_valid_o ;
    //assign m_ovi_if.store_sb_id = core.vitruvius.store_sb_id_o ;
    assign m_ovi_if.store_data = core.vitruvius.vpu.store_data_o ;
    assign m_ovi_if.store_credit = core.vitruvius.vpu.store_credit_i ;

    assign m_ovi_if.mask_idx_valid = core.vitruvius.vpu.mask_idx_valid_o ;
    //assign m_ovi_if.mask_idx_sb_id = core.vitruvius.mask_idx_sb_id_o ;
    assign m_ovi_if.mask_idx_item = core.vitruvius.vpu.mask_idx_item_o ;
    assign m_ovi_if.mask_idx_last_idx = core.vitruvius.vpu.mask_idx_last_idx_o ;
    assign m_ovi_if.mask_idx_credit = core.vitruvius.vpu.mask_idx_credit_i ;

    assign m_ovi_if.dbg_re_i = core.vitruvius.vpu.dbg_re_i ;
    assign m_ovi_if.dbg_we_i = core.vitruvius.vpu.dbg_we_i ;
    assign m_ovi_if.dbg_address_i = core.vitruvius.vpu.dbg_address_i ;
    assign m_ovi_if.dbg_write_data_i = core.vitruvius.vpu.dbg_read_data_o ;
    assign m_ovi_if.dbg_read_data_o = core.vitruvius.vpu.dbg_write_data_i ;

    assign renaming_unit_if.roll_back_vstart_o = core.vitruvius.vpu.core.reorder_buffer_inst.rollback_vstart_o;

    assign vreg_if.rename_vdest = core.vitruvius.vpu.core.reorder_buffer_inst.commit_vreg_o;
    assign restore_vstart_if.enable = core.vitruvius.vpu.core.reorder_buffer_inst.enable_o;
    assign restore_vstart_if.commit = core.vitruvius.vpu.core.reorder_buffer_inst.commit_o;

    assign vreg_if.wb_data = core.vitruvius.wb_data_o;
    assign vreg_if.vl = core.vitruvius.vl_table[core.vitruvius.vpu.core.completed_o.sb_id]; // TODO: check where to connect
    assign vreg_if.incomplete = core.vitruvius.vmv_table[core.vitruvius.vpu.core.completed_o.sb_id]; // TODO: check where to connect

    //mref IF connection for the scoreboard
    assign mrf_if.mask_data = core.vitruvius.mask_data;
    assign mrf_if.vl = core.vitruvius.vl_table[core.vitruvius.completed_o.sb_id];

    //renaming_unit signals
    assign renaming_unit_if.commit_vsew_i = (core.vitruvius.vpu.core.reorder_buffer_inst.rollback_vreg_commit_o) ? core.vitruvius.vpu.core.reorder_buffer_inst.rollback_vsew_o : core.vitruvius.vpu.core.renaming_logic_inst.commit_vsew_i;
    assign renaming_unit_if.commit_vlen_i = (core.vitruvius.vpu.core.reorder_buffer_inst.rollback_vreg_commit_o) ? core.vitruvius.vpu.core.reorder_buffer_inst.rollback_vlen_o : core.vitruvius.vpu.core.renaming_logic_inst.commit_vlen_i;

    // Aux code for interface: registered vpu is_nop signals
    logic pop_nop_q;
    always_ff @(posedge clock_if.clk or negedge reset_if.rsn) begin
       if (!reset_if.rsn) pop_nop_q <= 1'b0;
       else pop_nop_q <= core.vitruvius.vpu.core.reorder_buffer_inst.pop_nop;
    end
    assign renaming_unit_if.is_nop = pop_nop_q;

    // Aux code for interface: registered version of lagarto_core.lagarto_ka_mapper.both_signals
    logic [31:0] rnm_inst_p0_q1, rnm_inst_p1_q1;

    always_comb begin
        if (!reset_if.rsn) begin
            rnm_inst_p0_q1 = '0;
            rnm_inst_p1_q1 = '0;
        end else if (core.lagarto_ka.lka_disp.lock_i) begin
            rnm_inst_p0_q1 = core.lagarto_ka.lka_reg_rnm_disp.rnm_instr_data_q[0].instr;
            rnm_inst_p1_q1 = core.lagarto_ka.lka_reg_rnm_disp.rnm_instr_data_q[1].instr;
        end
    end

    // Variables: dut_wrapper if signals
    assign fetch_if.mapper_id_inst_valid    = core.lagarto_ka.lka_disp.disp_instr_valid_o;
    assign fetch_if.mapper_id_inst_p0       = rnm_inst_p0_q1;//registered version of lagarto_core.lagarto_ka_mapper.rnm_inst_p0_i
    assign fetch_if.mapper_id_inst_p1       = rnm_inst_p1_q1;//registered version of lagarto_core.lagarto_ka_mapper.rnm_inst_p1_i
    assign fetch_if.mapper_id_pc_p0         = core.lagarto_ka.lka_reg_rnm_disp.rnm_disp_instr_data_o[0].pc;
    assign fetch_if.mapper_id_pc_p1         = core.lagarto_ka.lka_reg_rnm_disp.rnm_disp_instr_data_o[1].pc;
    assign fetch_if.xcpt                    = core.lagarto_ka.barrier_xcpt;
    assign fetch_if.branch                  = core.lagarto_ka.brob_miss;
    assign fetch_if.rob_new_entry_p0        = core.lagarto_ka.rob_new_entry[0];
    assign fetch_if.rob_new_entry_p1        = core.lagarto_ka.rob_new_entry[1];
    assign fetch_if.mapper_disp_branch_p0   = core.lagarto_ka.lka_reg_rnm_disp.rnm_disp_instr_ctrl_o[0].bctrl.valid;
    assign fetch_if.mapper_disp_branch_p1   = core.lagarto_ka.lka_reg_rnm_disp.rnm_disp_instr_ctrl_o[1].bctrl.valid;

    assign int_if.interrupt_o = core.csr_interrupt;
    assign int_if.interrupt = core.lagarto_ka.lka_barrier.lka_brr_csr_hndlr.rob_xcpt; //one cycle before core
    assign int_if.interrupt_cause = core.lagarto_ka.lka_barrier.lka_brr_csr_hndlr.extract_xcpt.cause; //one cycle before core


    assign ic_if.csr_en_translation = en_translation;
    assign ic_if.csr_status = core.csr_ptw_comm.mstatus;
    assign ic_if.csr_satp = core.csr.satp_q;
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
    assign tohost_if.csr_tohost_valid = (core.pcr_req_addr_o == 12'h9F0) & core.pcr_req_valid_o;
    assign clearmip_if.csr_clearmip_valid = (|core.csr.mip_q) & !(|core.csr.mip_d);

        for (genvar i = 0; i < REGFILE_DEPTH; i++) begin
            assign reg_if.regfile[i] = core.lagarto_ka.lagarto_ka_regfile.regfile_regs.registers[i];
        end

    function logic [63:0] encode_cause(logic [4:0] ka_cause);
        // Transform Lagarto Ka cause into RISC-V cause
        logic [63:0] cause;
        cause[63] = ka_cause[4];
        cause[62:4] = '0;
        cause[3:0] = ka_cause[3:0];
        return cause;
    endfunction


    always_comb begin 
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            completed_if.valid[i] = core.lagarto_ka.rob_commit[i];
            completed_if.pc[i] = core.lagarto_ka.rob_pc[i];
            completed_if.result[i] = reg_if.regfile[core.lagarto_ka.rob_pdest[i]];
            completed_if.result_valid[i] = core.lagarto_ka.rob_ldest_valid[i];
            completed_if.pdest[i] = core.lagarto_ka.rob_pdest[i];
            completed_if.xcpt_cause[i] = encode_cause(core.lagarto_ka.lka_rob.rob_cause[i]);
            completed_if.rob_head[i] = core.lagarto_ka.rob_head[i];
            completed_if.instr[i] = '0;
            completed_if.vd[i] = '0;
            completed_if.store_data[i] = core.lagarto_ka.store_data;
            completed_if.rob_entry_miss[i] = core.lagarto_ka.rob_entry_miss;
            completed_if.store_valid[i] = (i == 0) && core.lagarto_ka.lagarto_ka_memp.instruction_to_dcache.is_store && !core.lagarto_ka.lagarto_ka_memp.instruction_to_dcache.is_vector;
            completed_if.xcpt[i] = core.lagarto_ka.barrier_xcpt;
            completed_if.core_req_valid[i] = (i == 0) && core.lagarto_ka.core_req_valid_o;
            completed_if.branch[i] = core.lagarto_ka.brob_miss;
            completed_if.fault[i] = core.lagarto_ka.lka_fetch.xcpt_access_fault_int | core.lagarto_ka.lka_fetch.xcpt_tlb_int;
            completed_if.mem_req_rob_entry[i] = (i == 0) && core.lagarto_ka.lagarto_ka_memp.mem_req_rob_entry_o;
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
        .clk_i                  ( clock_if.clk                  ),
        .rsn_i                  ( reset_if.rsn                  ),
        .csr_priv_lvl_i         ( core.csr_priv_lvl             ),
        .csr_rw_rdata_i         ( core.csr_r_data_core          ),
        .csr_csr_stall_i        ( core.csr_csr_stall            ),
        .csr_xcpt_i             ( core.csr_csr_xcpt             ),
        .csr_xcpt_cause_i       ( core.csr_csr_xcpt_cause       ),
        .csr_eret_i             ( core.csr_eret                 ),
        .csr_evec_i             ( {24'h0,core.csr_epc_o}        ),
        .csr_interrupt_i        ( core.csr_interrupt            ),
        .csr_interrupt_cause_i  ( core.csr_interrupt_cause      ),
        .csr_csr_replay_i       ( core.csr_csr_replay           ),
        .csr_tval_i             ( core.csr_csr_tval             ),
        .csr_rw_addr_o          ( core.csr_rw_addr              ),
        .csr_rw_cmd_o           ( core.csr_rw_cmd               ),
        .csr_rw_wdata_o         ( core.csr_rw_wdata             ),
        .csr_exception_o        ( core.csr_exception            ),
        .csr_cause_o            ( core.csr_cause                ),
        .csr_pc_o               ( {24'h0, core.csr_pc[39:0]}    ),
        .csr_retire_o           ( core.csr_retire               )
    );
`endif

// Coverage
`ifdef COVERAGE
    bind lagarto_ka_bpu : core.lagarto_ka.lagarto_ka_bpu cov_bpu u_cov_bpu(
        .i_clk                      (clk_bpu            ),
        .i_rsn                      (rst_bpu            ),
        .i_rob_branch_p0            (rob_branch_p0_i    ),
        .i_rob_branch_p1            (rob_branch_p1_i    ),
        .i_brob_enable              (brob_enable_i      ),
        .i_bpu_miss                 (bpu_miss_o         ),
        .i_bpu_predict              (bpu_predict_o      )
    );

    bind csr_bsc : core.csr cov_csr u_cov_csr(
        .i_clk                      (clk_i             ),
        .i_rsn                      (rstn_i            ),
        .i_csr_exception            (csr_xcpt_o        ),
        .i_csr_cause                (csr_xcpt_cause_o  ),
        .i_csr_rw_cmd               (rw_cmd_i          ),
        .i_csr_eret                 (eret_o            ),
        .i_csr_stall                (csr_stall_o       ),
        .i_csr_interrupt_cause      (interrupt_cause_o ),
        .i_csr_interrupt            (interrupt_o       ),
        .i_priv_lvl                 (priv_lvl_o        )
    );

    bind lka_frl : core.lagarto_ka.lka_frl cov_frl u_cov_frl(
        .i_clk                      (clk_frl                ),
        .i_rsn                      (rst_frl                ),
        .i_frl_rd_p0                (frl_pdest_p0_o         ),
        .i_frl_rd_p1                (frl_pdest_p1_o         ),
        .i_frl_lock                 (frl_lock_i             ),
        .i_rob_pdst_p0              (rob_pdest_p0_i         ),
        .i_rob_pdst_p1              (rob_pdest_p1_i         )
    );

    bind lagarto_ka_decoder : core.lagarto_ka.lagarto_ka_decoder cov_idecode u_cov_idecode(
        .i_clk                      (clk_decode             ),
        .i_rsn                      (rst_decode             ),
        .i_if_inst_val              (if_inst_val_i          ),
        .i_if_xcpt                  (if_xcpt_i              ),
        .i_id_illegal               (id_illegal             ),
        .i_id_flush                 (id_flush_i             ),
        .i_id_lock                  (id_lock_i              ),
        .i_id_stall_req             (id_stall_req           ),
        .i_id_flush_req             (id_flush_req           ),
        .i_id_xcpt                  (id_xcpt_o              ),
        .i_id_xcpt_cause            (id_xcpt_cause_o        ),
        .i_csr_interrupt            (csr_interrupt_i        )
    );

    bind lagarto_ka_fetch : core.lagarto_ka.lka_fetch cov_ifetch u_cov_ifetch(
        .i_clk                      (clk_fetch              ),
        .i_rsn                      (rst_fetch              ),
        .i_pc_req_int               (pc_req_int             ),
        .i_pc_offset                (next_pc_offset_int     ),
        .i_invalidate               (barrier_icache_invalidate_i    ),
        .i_kill                     (icache_req_bits_kill_o ),
        .i_valid_response           (datablock_valid_int    ),
        .i_id_jal_p0                (id_jal_p0_i            ),
        .i_id_jal_p1                (id_jal_p1_i            ),
        .i_issue_jalr_p0            (issue_jalr_p0_i        ),
        .i_issue_jalr_p1            (issue_jalr_p1_i        ),
        .i_bpu_miss                 (bpu_miss_i             ),
        .i_bpu_predict              (bpu_predict_i          ),
        .i_rob_recovery             (rob_recovery_i         ),
        .i_pc_lock                  (pc_lock_i              ),
        .i_if_lock                  (if_lock_i              ),
        .i_if_flush                 (if_flush_i             ),
        .i_id_fence                 (barrier_icache_invalidate_i    ),
        .i_if_xcpt                  (if_xcpt_o              ),
        .i_if_xcpt_cause            (if_xcpt_cause_o        ),
        .i_tlb_xcpt                 (tlb_resp_xcpt_if_i     )
    );

    cov_isa u_cov_isa_p0(
        .i_clk                      (fetch_if.clk                       ),
        .i_valid                    (fetch_if.mapper_id_inst_valid[0]   ),
        .i_rsn                      (fetch_if.rsn                       ),
        .i_instruction              (fetch_if.mapper_id_inst_p0         )
    );

    cov_isa u_cov_isa_p1(
        .i_clk                      (fetch_if.clk                       ),
        .i_valid                    (fetch_if.mapper_id_inst_valid[1]   ),
        .i_rsn                      (fetch_if.rsn                       ),
        .i_instruction              (fetch_if.mapper_id_inst_p1         )
    );
`endif // COVERAGE

endmodule : test_harness
