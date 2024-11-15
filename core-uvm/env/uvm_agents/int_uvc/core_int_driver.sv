//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_int_driver 
// File          : core_int_driver.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_driver. This class instantiates 
//                 the int driver and also drives the int_sequence's data 
//                 from int_sequencer to DUT through int_interface. 
//----------------------------------------------------------------------
`ifndef CORE_INT_DRIVER_SV
`define CORE_INT_DRIVER_SV

class core_int_driver extends uvm_driver #(core_int_trans);
    `uvm_component_utils(core_int_driver)

    core_env_cfg m_env_cfg;
    core_int_cfg                  m_cfg;
    core_iss_wrapper              m_iss;
    virtual interface   int_if  int_if;

    //Events to synchronize UVM/Spike/RTL
    uvm_event_pool  pool                    = uvm_event_pool::get_global_pool();
    uvm_event       test_clearmip_event     = pool.get("test_clearmip");
    uvm_event       intr_xcpt               = pool.get("intr_xcpt");
    uvm_event       sw_intr_xcpt            = pool.get("sw_intr_xcpt");
    uvm_event       timer_intr_xcpt         = pool.get("timer_intr_xcpt");
    uvm_event       increment_clint_event   = pool.get("increment_clint_event");
    uvm_event       write_mtime_event       = pool.get("write_mtime");

    //Variables
    core_int_trans                trans;
    int                         mie_meip, mie_seip;
    int                         executed_interrupts;
    int                         interrupt_in_progress;
    longint                     last_cleared_irq_id;
    plic_enable_t               plic_enable;
    longint                     mtime;
    longint                     mtimecmp;

    function new(string name = "core_int_driver", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
        executed_interrupts     = 0;
        interrupt_in_progress   = 0;
        last_cleared_irq_id     = 0;
        m_env_cfg = new();
        if (!uvm_config_db #(core_env_cfg)::get(this, "", "top_cfg.env_cfg", m_env_cfg)) begin
            `uvm_fatal(get_type_name(), "Environment configuration is not set")
        end
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        int i, id;
        super.run_phase(phase);
        fork
            //External interrupt drive
            forever begin
                seq_item_port.get_next_item(trans);
                mie_meip                = |(m_iss.get_mie() & (1'b1<<11)) ; //Machine external interrupt enable
                mie_seip                = |(m_iss.get_mie() & (1'b1<<9))  ; //Supervisor external interrupt enable
                id                      = 0;
                interrupt_in_progress   = 0;
                trans.prv_level         = m_iss.get_prv_lvl();

                if (m_env_cfg.is_cpu_ss) begin
                    uvm_config_db #(plic_enable_t)::get(null, "*", "plic_enable", plic_enable);
                    trans.interrupt = (mie_meip && (trans.prv_level==3)                     && |(plic_enable.m_irq_enable & trans.interrupt) )? trans.interrupt :
                                      (mie_seip && (trans.prv_level==3||trans.prv_level==1) && |(plic_enable.s_irq_enable & trans.interrupt) )? trans.interrupt : 'd0;
                end else begin
                    plic_enable = {default:'1};
                    trans.interrupt = (mie_meip && (trans.prv_level==3)                     && |(plic_enable.m_irq_enable & trans.interrupt) )? 'h1 :
                                      (mie_seip && (trans.prv_level==3||trans.prv_level==1) && |(plic_enable.s_irq_enable & trans.interrupt) )? 'h2 : 'd0;
               end

                if( |trans.interrupt ) begin
                    for( i = 0; i < $size(trans.interrupt); i = i+1 ) begin
                        if( trans.interrupt[i] ) begin
                            id = i + 1; //+1 since irq 0 doesn't exist
                            `uvm_info(get_type_name(), $sformatf("RECEIVED INT TX - INT %h CAUSE %d ID %d", trans.interrupt, trans.interrupt_cause, id), UVM_HIGH)
                            if (m_env_cfg.is_cpu_ss) begin
                                m_iss.set_plic_interrupt_level(id, 1);
                             end
                            interrupt_in_progress ++;
                        end
                    end
                end
                uvm_config_db #(int)::set(null, "*", "interrupt_in_progress", interrupt_in_progress);

                int_if.drive(trans);

                repeat(1000)
                    @(posedge int_if.clk); //wait some clocks until interrupt routine is done
                seq_item_port.item_done();
            end

            //External interrupt ACK
            forever begin
                @(posedge int_if.clk)
                if( int_if.interrupt && int_if.interrupt_cause[64-1] && (int_if.interrupt_cause[64-2:0]=='d11 || int_if.interrupt_cause[64-2:0]=='d9) ) //external interrupt ack
                begin
                    int value;
                    intr_xcpt.wait_trigger();
                    value = (int_if.interrupt_cause[64-2:0]=='d11) ? 32'h800 : (int_if.interrupt_cause[64-2:0]=='d9) ? 'h200 : 'h800; //machine by default
                    `uvm_info(get_type_name(), $sformatf("Setting Spike external interrupt - PRVL LEVEL %h VAL %h  @%d", int_if.prv_level, value, $time()), UVM_HIGH)
                    m_iss.set_external_interrupt( value );

                    if (m_env_cfg.is_cpu_ss) begin
                        while( last_cleared_irq_id == 0 ) begin
                            test_clearmip_event.wait_trigger();
                            uvm_config_db #(longint)::get(null, "*", "last_cleared_irq_id", last_cleared_irq_id);
                            `uvm_info(get_type_name(), $sformatf("Last cleared external interrupt %h", last_cleared_irq_id), UVM_DEBUG) 
                        end
                    end else begin
                        test_clearmip_event.wait_trigger();
                    end

                    `uvm_info(get_type_name(), $sformatf("Spike should clear MIP @%d", $time()), UVM_HIGH)
                    m_iss.set_external_interrupt(32'h0);
                    if (m_env_cfg.is_cpu_ss) begin
                        m_iss.set_plic_interrupt_level(last_cleared_irq_id, 0);
                    end
                    last_cleared_irq_id = 0;
                    executed_interrupts++;
                    uvm_config_db #(int)::set(null, "*", "executed_interrupts", executed_interrupts);
                    test_clearmip_event.reset();
                    uvm_config_db #(int)::get(null, "*", "interrupt_in_progress", interrupt_in_progress);
                    interrupt_in_progress --;
                    uvm_config_db #(int)::set(null, "*", "interrupt_in_progress", interrupt_in_progress);
                end
            end

            //Get mtime
            forever begin
                @(posedge int_if.clk)
                write_mtime_event.wait_trigger();
                uvm_config_db #(longint)::get(null, "*", "mtime", mtime);
                `uvm_info(get_type_name(),$sformatf("MTIME WRITE %h ", mtime ), UVM_LOW) 
            end

            //Drive timer interrupt
            forever begin
                @(posedge int_if.clk);
                if (int_if.rsn == 0) begin
                    @(posedge int_if.rsn);
                    write_mtime_event.wait_trigger();
                    repeat(200) @(posedge int_if.clk); //until store to mtime gets to the clint
                end

                increment_clint_event.wait_trigger();
                mtime = mtime + 1;
                uvm_config_db #(longint)::get(null, "*", "mtimecmp_offset", mtimecmp);
                if ( mtime < mtimecmp) begin
                    m_iss.clint_increment(1);
                    `uvm_info(get_type_name(),$sformatf("MTIME INCREASE %h MTIMECMP %h", mtime, mtimecmp ), UVM_LOW) 
                end
                else if (mtime == mtimecmp) begin
                    @(posedge int_if.interrupt); //check also interrupt cause
                    timer_intr_xcpt.wait_trigger();
                    `uvm_info(get_type_name(),$sformatf("TIMER INTERRUPT - MTIME INCREASE %h MTIMECMP %h", mtime, mtimecmp ), UVM_LOW) 
                    m_iss.clint_increment(1);
                end
            end

            //Software interrupt drive
            forever begin
                @(posedge int_if.clk)
                if( int_if.interrupt && int_if.interrupt_cause[64-1] && int_if.interrupt_cause[64-2:0]=='d3 ) //software interrupt ack
                begin
                    sw_intr_xcpt.wait_trigger();
                    `uvm_info(get_type_name(), $sformatf("SETTING SPIKE SOFTWARE INTERRUPT @%d", $time()), UVM_HIGH)
                    m_iss.set_external_interrupt(32'h008);
                    test_clearmip_event.wait_trigger();
                    m_iss.set_external_interrupt(32'h0);
                    test_clearmip_event.reset();
                    sw_intr_xcpt.reset();
                end
            end
        join

    endtask : run_phase

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        uvm_config_db #(int)::set(null, "*", "executed_interrupts", executed_interrupts);
    endfunction : report_phase

endclass : core_int_driver

`endif
