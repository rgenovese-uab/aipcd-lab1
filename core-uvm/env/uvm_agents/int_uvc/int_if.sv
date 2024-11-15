//----------------------------------------------------------------------
// Project       : core-uvm
// Unit          : int_if 
// File          : int_if.sv
//----------------------------------------------------------------------
// Created by    : R. Ignacio Genovese 
//----------------------------------------------------------------------
// Description   : Interface used to drive timer/software and external
//                 interrupts from UVM to PLIC or Core
//----------------------------------------------------------------------
`ifndef INT_IF
`define INT_IF

import dut_pkg::*;
import core_uvm_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

interface int_if;

    logic                   clk;
    logic                   rsn;
    logic                   time_irq;           // timer interrupt
    logic [254:0]           irq;                // external interrupt in
    logic                   m_soft_irq;         // Machine software interrupt form the axi module
    logic                   interrupt;          // Interruption wire to the core
    logic [64-1:0]          interrupt_cause;    // Interruption cause
    logic                   interrupt_o;        // Interrupt output from csr
    int                     prv_level;

    longint                 last_cleared_irq_id = 0; //ID from the last claimed external interrupt
    int                     timer_sum           = 0; //counter for timer interrupts

    core_env_cfg m_env_cfg;
    core_int_monitor          mon_proxy;
    uvm_event_pool          pool = uvm_event_pool::get_global_pool();
    uvm_event               test_clearmip_event = pool.get("test_clearmip");
    uvm_event               increment_clint_event = pool.get("increment_clint_event");


    task drive(core_int_trans tx);
        if (rsn == 0) begin
            irq = 0;
            @(posedge rsn);
        end

        //External interrupt drive
        if (tx.interrupt) begin
            `uvm_info("INT_IF", $sformatf("Received interrupt transaction w/value %h, generating stimulus...", tx.interrupt), UVM_DEBUG)
            time_irq = 1'b0;
            m_soft_irq = 1'b0;
            irq = tx.interrupt;
            prv_level = tx.prv_level;

            while( irq ) begin
                @(posedge clk);
                test_clearmip_event.wait_trigger();

                if (m_env_cfg.is_cpu_ss) begin
                    uvm_config_db #(longint)::get(null, "*", "last_cleared_irq_id", last_cleared_irq_id);
                    `uvm_info("INT_IF", $sformatf("Last cleared external interrupt %h", last_cleared_irq_id), UVM_DEBUG) 
                    if( irq[last_cleared_irq_id -1] ) begin //-1 as irq doesn't exist
                        `uvm_info("INT_IF", $sformatf("Correctly cleared external interrupt %h", last_cleared_irq_id), UVM_DEBUG) 
                        irq[last_cleared_irq_id -1] = 1'b0;  //-1 as irq doesn't exist
                    end
                    else begin
                        `uvm_error("INT_IF", $sformatf("Uncorrectly cleared external interrupt %h", last_cleared_irq_id)) 
                    end
                end else begin
                    irq = 'd0;
                end
                time_irq = 1'b0;
                m_soft_irq = 1'b0;
            end //while
            @(posedge clk);
        end

        //Timer interrupt ACK
        else begin
            irq = 'd0;
            time_irq = (timer_sum==0);
            m_soft_irq = 1'b0;
            timer_sum = (timer_sum + 1)%10;
            if( time_irq ) 
                increment_clint_event.trigger();

            @(posedge clk);
        end
    endtask : drive

    task monitor();
        core_int_trans item;

        forever begin
            @(posedge clk)
            if (interrupt && interrupt_cause[64-1]) begin
                item = core_int_trans::type_id::create("item");
                item.interrupt = interrupt;
                item.interrupt_cause = interrupt_cause;
                mon_proxy.notify_transaction(item);
            end
        end
    endtask : monitor

    task setup();
        if (!uvm_config_db #(core_env_cfg)::get(null, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal("int_if", "Environment configuration is not set")
        end
    endtask
endinterface

`endif
