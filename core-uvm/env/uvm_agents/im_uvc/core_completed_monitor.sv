//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_completed_monitor
// File          : core_completed_monitor.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_monitor. This class instantiates
//                 the completed_monitor and also monitors the core's ROB for
//                 completed or killed instructions, and the VRF results. And
//                 Sends these to the instruction manager.
//----------------------------------------------------------------------

`ifndef CORE_COMPLETED_MONITOR
`define CORE_COMPLETED_MONITOR

class core_completed_monitor extends uvm_monitor;
    `uvm_component_utils (core_completed_monitor)

    // Variable: completed_if
    // Instruction start virtual interface
    virtual interface core_completed_if completed_vif;

    // Variable: reg_vif
    virtual interface core_regfile_if reg_vif;

    // Variable: analysis_port
    // Analysis port connecting completed monitor with Instruction Management Module
    uvm_analysis_port #(core_completed_trans) analysis_port;

    uvm_analysis_port #(core_store_trans) store_port;

    // Variable: completed_queue
    core_completed_trans completed_queue [$];
    // Variable heartbeat_objection
    uvm_callbacks_objection heartbeat_objection;

    // Variable: pool
    // Pointer to global uvm_event_pool
    uvm_event_pool pool = uvm_event_pool::get_global_pool();

    // Variable: rob_recovery_event
    uvm_event rob_recovery_event = pool.get("rob_recovery_event");
    uvm_event iss_finished = pool.get("iss_finished");

    // Variable: intr_xcpt
    uvm_event intr_xcpt = pool.get("intr_xcpt");
    uvm_event timer_intr_xcpt = pool.get("timer_intr_xcpt");
    uvm_event sw_intr_xcpt = pool.get("sw_intr_xcpt");
    core_env_cfg m_env_cfg;
    logic [63:0] store_queue [$];
    function new(string name = "core_completed_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        store_port = new("store_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env_cfg = new();
        if (!uvm_config_db #(core_env_cfg)::get(this, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end
    endfunction : build_phase

    task wait_and_send();
        core_completed_trans m_completed;
        #1 //up until the regfile is actually written
        for (int i = 0; i < COMMIT_WIDTH; ++i) begin
            if (completed_queue.size() <= 0)
                break;
            m_completed = completed_queue.pop_front();
            if (m_env_cfg.core_type == core_uvm_pkg::LAGARTO_KA) begin
                m_completed.result = reg_vif.regfile[m_completed.pdest];
            end
            analysis_port.write(m_completed);
        end
    endtask : wait_and_send

    virtual task target_item_processing(core_completed_trans trans, core_completed_item item, int i);
    endtask

    virtual task target_branch_processing(core_completed_trans trans, core_completed_item item, int i);
    endtask

    virtual task target_store_processing(core_store_trans trans, core_completed_item item, int i);
    endtask

    task run_phase(uvm_phase phase);
        core_completed_trans branch_pc_q[$];
                forever begin
                    @(posedge completed_vif.clk);
                    if (iss_finished.is_on()) begin
                        break;
                    end
                    if (branch_pc_q.size() > 0) begin
                        branch_pc_q[0].pc = completed_vif.pc[0];
                        `uvm_info(get_type_name(),$sformatf("Triggering rob_recovery_event on PC %h for rob_entry_miss %h branch_pc_q size %d", branch_pc_q[0].pc, branch_pc_q[0].rob_entry_miss, branch_pc_q.size()), UVM_HIGH)
                        rob_recovery_event.trigger(branch_pc_q.pop_front());
                    end
                    if (completed_vif.core_req_valid[0] && completed_vif.store_valid[0]) begin // TODO Separate from completed if
                        core_store_trans store_trans;
                        store_trans = core_store_trans::type_id::create("store_trans");
                        store_trans.store_data = completed_vif.store_data[0];
                        store_trans.rob_entry = completed_vif.mem_req_rob_entry[0];
                        store_port.write(store_trans);
                        `uvm_info(get_type_name(),$sformatf("Completed Store Transaction:: Store-Data: %0h, ROB entry  %0h", store_trans.store_data, store_trans.rob_entry), UVM_HIGH)
                    end
                    for (int i = 0; i < COMMIT_WIDTH; i++) begin
                        if (completed_vif.valid[i]) begin
                            core_completed_trans m_completed;
                            m_completed = core_completed_trans::type_id::create("m_completed");
                            m_completed.pc = completed_vif.pc[i];
                            m_completed.result = completed_vif.result[i];
                            m_completed.instr = completed_vif.instr[i];
                            m_completed.dest_valid = completed_vif.result_valid[i];
                            m_completed.pdest = completed_vif.pdest[i];
                            m_completed.stored_value = completed_vif.result[i];
                            m_completed.xcpt = completed_vif.xcpt[i];
                            m_completed.xcpt_cause = completed_vif.xcpt_cause[i];
                            m_completed.rob_head = completed_vif.rob_head[i];
                            for (int j = 0; j < riscv_pkg::VLEN/64; j++) begin
                                m_completed.vd[j] = completed_vif.vd[i][j*64 +:64];
                            end
                            `uvm_info(get_type_name(),$sformatf("Completed Transaction Recorded at the End of the Instruction:: i: %d Commit-PC: %0h, Commit-Data: %0h, Commit-Instruction: %0h, Commit-RegAddress: %0h Exception %0h Cause %0h store_valid: %d", i, m_completed.pc, m_completed.result, m_completed.instr, m_completed.pdest, m_completed.xcpt, m_completed.xcpt_cause, completed_vif.store_valid[i]), UVM_HIGH)
                            completed_queue.push_back(m_completed);
                        end
                        if ((completed_vif.xcpt[i] || completed_vif.branch[i]) && (branch_pc_q.size() == 0)) begin // Just one such event per cycle makes sense. All fetched instructions will be flushed
                            core_completed_trans branch_pc;
                            branch_pc = core_completed_trans::type_id::create("branch_pc");
                            branch_pc.xcpt = completed_vif.xcpt[i];
                            // TODO Separate into different interface
                            branch_pc.rob_entry_miss    = completed_vif.rob_entry_miss[i];
                            branch_pc.rob_head          = completed_vif.rob_head[i];
                            branch_pc.fault             = completed_vif.fault[i] && completed_vif.xcpt[i];
                            branch_pc.ext_intr = ((completed_vif.xcpt_cause[i][62:0] == 'd11 || completed_vif.xcpt_cause[i][62:0] == 'd9) && completed_vif.xcpt_cause[i][63]); //MEIP|SEIP
                            // TODO: Supervisor?
                            branch_pc.timer_intr = ((completed_vif.xcpt_cause[i][62:0] == 'd7) && completed_vif.xcpt_cause[i][63]); //MTIP
                            // TODO: Supervisor?
                            branch_pc.sw_intr = ((completed_vif.xcpt_cause[i][62:0] == 'd3) && completed_vif.xcpt_cause[i][63]); //MSIP
                            branch_pc_q.push_back(branch_pc);
                            if (branch_pc.ext_intr) begin
                                `uvm_info(get_type_name(), $sformatf("Completed Transaction has external interrupt exception - PC: %0h Instruction: %0h", branch_pc.pc, branch_pc.instr ), UVM_LOW)
                                intr_xcpt.trigger();
                            end else if (branch_pc.timer_intr) begin
                                `uvm_info(get_type_name(), $sformatf("Completed Transaction has timer interrupt exception - PC: %0h Instruction: %0h", branch_pc.pc, branch_pc.instr ), UVM_LOW)
                                timer_intr_xcpt.trigger();
                            end else if (branch_pc.sw_intr) begin
                                `uvm_info(get_type_name(), $sformatf("Completed Transaction has software interrupt exception - PC: %0h Instruction: %0h", branch_pc.pc, branch_pc.instr ), UVM_LOW)
                                sw_intr_xcpt.trigger();
                            end else begin
                                `uvm_info(get_type_name(), $sformatf("Completed Transaction has another exception or branch - PC: %0h Instruction: %0h xcpt: %d fault: %d branch: %d ROB entry miss: %d ROB head: %d", branch_pc.pc, branch_pc.instr, branch_pc.xcpt, branch_pc.fault, completed_vif.branch[i], branch_pc.rob_entry_miss, branch_pc.rob_head), UVM_LOW)
                            end
                        end
                    end
                    fork
                        @(posedge reg_vif.clk); // Data has one cycle delay, the first cycle is the same you are in the commit, you have to wait another.
                        wait_and_send();
                    join_none
                end
    endtask : run_phase

endclass

`endif


