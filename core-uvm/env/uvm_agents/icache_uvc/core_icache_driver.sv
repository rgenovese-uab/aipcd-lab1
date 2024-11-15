//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_icache_driver 
// File          : core_icache_driver.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_driver. This class instantiates 
//                 the icache driver and also drives the icache_sequence's data 
//                 from icache_sequencer to DUT through icache_interface. 
//----------------------------------------------------------------------
`ifndef CORE_ICACHE_DRIVER_SV
`define CORE_ICACHE_DRIVER_SV

typedef class core_mem_model;

class core_icache_driver extends uvm_driver #(core_icache_rand_trans);
    `uvm_component_utils(core_icache_driver)

    // Variable: m_cfg
    core_icache_cfg m_cfg;

    // Variable: icache_if
    virtual interface icache_if ic_dr_if;

    // Variable: dut_req_ap
    uvm_blocking_get_port #(core_icache_trans) dut_req_ap; // for driver to know the request situations..

    // Variable: trans, rand_trans
    core_icache_trans trans;
    core_icache_trans miss_trans;
    core_icache_rand_trans rand_trans;
    core_icache_rand_trans miss_rand_trans;
    core_iss_wrapper m_iss;

    // Variable: m_mem_model_wrapper
    core_mem_model#(64, 128) m_mem_model;

    logic   miss_state = 0;

    function new(string name = "core_icache_driver", uvm_component parent);
        super.new(name, parent);
        dut_req_ap = new("dut_req_ap", this); // for driver to know the request situations..
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        trans = core_icache_trans::type_id::create("trans");
        initial_ref_model(trans);
    endfunction : build_phase

    // Function: connect_phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_mem_model = core_mem_model#(64, 128)::create_instance();
    endfunction : connect_phase

    task run_phase(uvm_phase phase);

        fork
            // Getting and treating transaction
            begin

                forever begin
                    longint exc_error = 0;
                    longint leaf_addr = 0;
                    longint leaf_data = 0;
                    seq_item_port.get_next_item(rand_trans);
                    dut_req_ap.get(trans);
                    initial_ref_model(trans);
                    `uvm_info("CORE_ICACHE_DRIVER",$sformatf("hit_miss_flag: %d - Received icache ready condition transaction, driving icache ready", rand_trans.hit_miss_flag), UVM_DEBUG)
                    trans.icache_resp.vaddr = {trans.lagarto_ireq.vpn,trans.lagarto_ireq.idx};
                    if (trans.csr_en_translation) begin
                        `uvm_info("CORE_ICACHE_DRIVER", $sformatf("Virtual address: %h", trans.icache_resp.vaddr), UVM_DEBUG)
                        trans.paddr = m_iss.tlb_address_translate(trans.icache_resp.vaddr, 0, 2, trans.csr_satp, trans.csr_priv_lvl, trans.csr_status, exc_error, leaf_addr);
                        `uvm_info("CORE_ICACHE_DRIVER", $sformatf("Physical address: %h - virtual address: %h - exc_error: %d", trans.paddr, trans.icache_resp.vaddr, exc_error), UVM_DEBUG)
                    end else begin
                        trans.paddr = trans.icache_resp.vaddr;
                    end
                    if (0 /*update_ad_bits*/) begin
                        `uvm_info("CORE_ICACHE_DRIVER", "Checking if there is exception", UVM_DEBUG)
                        //update A bit if needed, if spike is doing so, indicated by leaf_addr
                        if (leaf_addr != 0) begin
                            `uvm_info("CORE_ICACHE_DRIVER", $sformatf("updating A bit for pTE with address %h", leaf_addr), UVM_DEBUG)
                            leaf_data = m_mem_model.read32(leaf_addr);
                            leaf_data = leaf_data | (64'h1 << 6);/*PTE_A*/
                            m_mem_model.write_byte(leaf_addr, leaf_data[7:0]); //first byte of PTE contains the permission bits
                        end
                    end
                    check_exc(trans, exc_error);
                    if (trans.icache_resp.xcpt == 1) begin
                        exc_ref_model(trans);
                    end
                    else begin
                        if (rand_trans.hit_miss_flag == 1'b1) begin
                            hit_ref_model(trans);
                        end
                        else begin
                            miss_ref_model(trans);
                        end
                    end
                    seq_item_port.item_done();
                end
            end
            // Driving signals
            begin
                forever begin
                    @(posedge ic_dr_if.clk) begin
                        idle_state();
                        if (miss_state) begin
                            drive_miss_state();
                        end
                        else begin
                            if (trans.drive) begin
                                drive(trans);
                                trans.drive = 0;
                            end
                        end
                    end
                end
            end
        join_none
    endtask : run_phase


    task idle_state();
        {ic_dr_if.icache_resp.valid, ic_dr_if.icache_resp.data, ic_dr_if.icache_resp.vaddr, ic_dr_if.icache_resp.xcpt} = 'b0;
        ic_dr_if.icache_resp.ready = 1'b1; //We are assuming initially icache is ready to process any request from core..
    endtask : idle_state

    task miss_signal_state();
        {ic_dr_if.icache_resp.valid, ic_dr_if.icache_resp.data, ic_dr_if.icache_resp.vaddr, ic_dr_if.icache_resp.xcpt} = 'b0;
        ic_dr_if.icache_resp.ready = 1'b0; //We are assuming initially icache is ready to process any request from core..
    endtask : miss_signal_state

    function void initial_ref_model(core_icache_trans trans);
        trans.icache_resp.ready = 1'b1; //We are assuming initially icache is ready to process any request from core..
        {trans.icache_resp.valid, trans.icache_resp.data, trans.icache_resp.vaddr, trans.icache_resp.xcpt, trans.drive} = 'b0;
    endfunction : initial_ref_model

    task hit_ref_model(core_icache_trans trans);
        // case2 Note - icache is not busy //upper level of memory send icache data// never apear for now..
        if (m_mem_model.read_cache(trans.paddr) == 'bx) begin // HIT  conditions // data is unknown to the cache.. // Not_possible..
            `uvm_fatal("CORE_ICACHE_DRIVER", "Requested data is unknown to the icache model.")
        end else begin // m_mem_model.read(trans.icache_resp.vaddr) !== 'bx) // HIT  conditions // data in the cache..
            trans.icache_resp.valid = 1'b1;
            trans.icache_resp.data = m_mem_model.read_cache(trans.paddr);
            `uvm_info(get_full_name(), $sformatf("Icache_read Mem : Addr[0x%0h], Data[0x%0h] hit/miss: %d", trans.icache_resp.vaddr, trans.icache_resp.data, rand_trans.hit_miss_flag), UVM_DEBUG)
            //trans.icache_resp.ready = 1'b0; // To Increase PC for next request..
        end
        trans.drive = 1;
    endtask : hit_ref_model

    task miss_ref_model(core_icache_trans trans);
        // MISS and EXCEPTION from spike... put flg with randomise .. DONT do it for now..
	    `uvm_info("CORE_ICACHE_DRIVER", $sformatf("hit_miss_flag: %d - served first miss_condition", rand_trans.hit_miss_flag), UVM_DEBUG)
        // => REASON - AS WE KNOW WHEN MISS=1 AND KILL=1 THEN CACHE NO NEED TO DO ANYTHING AND JUST BREAK THE OPERATIONS.. OR IGNORE..
        miss_trans = new trans;
        miss_rand_trans = new rand_trans;
        trans.drive = 1;
        miss_state = 1;
    endtask : miss_ref_model

    task exc_ref_model(core_icache_trans trans);
        `uvm_info("CORE_ICACHE_DRIVER", "Executing exception model and driving.", UVM_DEBUG)
        trans.icache_resp.valid = 1;
        trans.drive = 1;
    endtask : exc_ref_model

    task check_exc (core_icache_trans trans, longint exc_error);
        if (trans.icache_resp.vaddr % 4) trans.icache_resp.xcpt = 1; // TODO Use parameter for alignment check
        if (exc_error > 0) trans.icache_resp.xcpt = 1;
        `uvm_info("CORE_ICACHE_DRIVER", $sformatf("trans.icache_resp.xcpt: %0d", trans.icache_resp.xcpt), UVM_DEBUG)
    endtask : check_exc

    task drive(core_icache_trans trans);
        `uvm_info("CORE_ICACHE_DRIVER", $sformatf("ready: %d - valid: %d - data: 0x%h - vaddr: 0x%h - xcpt: %d", trans.icache_resp.ready, trans.icache_resp.valid, trans.icache_resp.data, trans.icache_resp.vaddr, trans.icache_resp.xcpt), UVM_DEBUG)
        ic_dr_if.icache_resp.ready <= trans.icache_resp.ready;
        ic_dr_if.icache_resp.valid <= trans.icache_resp.valid;
        ic_dr_if.icache_resp.data <= trans.icache_resp.data;
        ic_dr_if.icache_resp.vaddr <= trans.icache_resp.vaddr;
        ic_dr_if.icache_resp.xcpt <= trans.icache_resp.xcpt;
    endtask : drive

    task drive_miss_state();
        if (miss_rand_trans.delay > 0) begin
            miss_rand_trans.delay--;
            miss_signal_state();
        end
        else begin
            hit_ref_model(miss_trans);
            drive(miss_trans);
            miss_state = 0;
        end
    endtask : drive_miss_state
endclass : core_icache_driver

`endif
