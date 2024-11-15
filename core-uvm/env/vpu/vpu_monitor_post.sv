`ifndef MONITOR_POST_SV
`define MONITOR_POST_SV

import core_uvm_pkg::rvv_dut_tx;

class vpu_monitor_post extends uvm_monitor;
    `uvm_component_utils(vpu_monitor_post)

    // Variable: m_cfg
    vpu_agent_cfg m_cfg;

    protocol_base_class m_protocol_class;

    int rec_transactions;

    // Variable: ap
    uvm_nonblocking_put_port #(rvv_dut_tx) dut_results_port;

    function new(string name = "vpu_monitor_post", uvm_component parent);
        super.new(name, parent);
        dut_results_port = new("dut_results", this);
        rec_transactions = 0;
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (m_cfg == null) begin
            //`uvm_fatal("vpu_monitor_post", "Configuration of DUT agent for vpu_monitor_post was not correctly set")
        end

        //m_dut_if.mon_proxy = this;
    endfunction : build_phase

    function void notify_transaction(rvv_dut_tx item);
        dut_results_port.try_put(item);
    endfunction : notify_transaction

    task run_phase(uvm_phase phase);
        rvv_dut_tx m_dut_tx;
        core_uvm_types_pkg::dut_rvv_state_t dut_state;
        super.run_phase(phase);
        fork
        begin
            forever begin
                m_protocol_class.wait_for_clk();
                if (m_protocol_class.new_dut_tx()) begin
                    dut_state = m_protocol_class.monitor_post();
                    m_dut_tx = rvv_dut_tx::type_id::create("m_dut_tx");
                    m_dut_tx.dut_state.rvv_state = dut_state;
                    rec_transactions++;
                    uvm_config_db #(int)::set(null, "*", "rec_transactions", rec_transactions);
                    if(!m_cfg.disable_checks)
                        dut_results_port.try_put(m_dut_tx);
                end
            end
        end
        join
    endtask : run_phase

endclass : vpu_monitor_post

`endif
