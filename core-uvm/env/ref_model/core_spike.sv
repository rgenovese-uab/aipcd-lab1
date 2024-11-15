//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_spike 
// File          : core_spike.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is core_spike class extended from core_iss_wrapper. 
//                 Providing Spike as reference model.
//----------------------------------------------------------------------
`ifndef CORE_SPIKE_SV
`define CORE_SPIKE_SV

import "DPI-C" function void spike_setup(input longint argc, input string argv);
import "DPI-C" function int run_and_inject(input int instr, output iss_scalar_state_t scalar_state);
import "DPI-C" function int exit_code();
import "DPI-C" function void set_tohost_addr(input longint tohost_addr, input longint fromhost_addr);
import "DPI-C" function void set_clearmip_addr(input longint clearmip_addr);
import "DPI-C" function void get_memory_data(output longint mem_element, input longint mem_addr);
import "DPI-C" function void start_execution();
import "DPI-C" function int set_memory_data(input int unsigned data, input longint unsigned address, input int size);
import "DPI-C" function void do_step(input int unsigned n);
import "DPI-C" function void spike_set_external_interrupt(int mip_val);
import "DPI-C" function longint unsigned address_translate(input longint addr, input longint len, input longint typ, input longint satp, input longint priv_lvl, input longint mstatus, output longint exc_error, output longint leaf_addr);
import "DPI-C" function longint spike_get_csr( int csr );
import "DPI-C" function int spike_get_prv_lvl();
import "DPI-C" function void spike_set_fp_reg_value(input int reg_dst, input longint value);
import "DPI-C" function void spike_plic_set_interrupt_level(input int id, input int level);
import "DPI-C" function void spike_get_plic_enable(input int ctx, output int unsigned enable[]);
import "DPI-C" function void spike_clint_set_increment(input int val);

// function added in the spike for the Setting the timer register's value.
import "DPI-C" function void spike_set_dest_reg_value(input int reg_dst, input longint value);

//FROM EPI SPIKE
import "DPI-C" function void get_src_vreg(input int reg_id, output longint unsigned vreg []);
import "DPI-C" function void get_dst_vreg(input int reg_id, output longint unsigned vreg []);
import "DPI-C" function void get_mem_addr(output longint unsigned vreg []);
import "DPI-C" function void get_mem_elem(output longint unsigned vreg []);
import "DPI-C" function logic is_vector(input longint unsigned instr);


class core_spike extends core_iss_wrapper;
    `uvm_object_utils(core_spike)

    bit enable_bin;
    string reduction_config;
    string isa;
    string core_type;
    int    vlen = 0;
    int extra_params_num;
    int extra_params_string;

    function new(string name = "core_spike");
        super.new(name);
        core_type = "STANDARD";
        isa="RV64GV";
    endfunction : new

    virtual function void setup();
        longint tohost_addr;
        longint fromhost_addr;
        longint clearmip_addr;
        string exec_bin;

        string reset_vector_val;
        string bootrom_bin_val;
        string mboot_main_id_val;
        string m;
        string hartid;
        int nargs=0;
        string params="";

        super.setup();
        `uvm_info(get_type_name(), $sformatf("Starting Spike - ISS Simulator Setup"), UVM_LOW)

        if (isa) begin
            params = {params, $sformatf("--isa=%s ",isa)};
            nargs++;
        end
        if (vlen) begin
            params = {params, $sformatf("--varch=vlen:%0d,elen:64 ", vlen)};
            nargs++;
        end
        if (reduction_config) begin
            params = {params, $sformatf("--reduction-config=%s ", reduction_config)};
            nargs++;
        end
        if (core_type) begin
            params = {params, $sformatf("--core-type=%s ", core_type)}; // TODO get from config
            nargs++;
        end
        if (extra_params_num) begin
            params = {params, extra_params_string};
            nargs += extra_params_num;
        end
        if($test$plusargs("SPIKE_COMMITLOG")) begin
            params = {params, "--log-commits "};
            nargs++;
        end

        if ($value$plusargs("MBOOT_MAIN_ID=%s", mboot_main_id_val)) begin
            params = {params, $sformatf("--mboot-main-id-val=%s ", mboot_main_id_val)};
            params = {params, "--has-mboot-main-id "};
            nargs +=2;
        end

        if ($value$plusargs("HARTID=%s", hartid)) begin
            params = {params, $sformatf(" --hartids=%s ", hartid)};
            nargs++;
        end

        if ($value$plusargs("RESET_VECTOR=%s", reset_vector_val)) begin
            params = {params, $sformatf("--reset-vector=%s ", reset_vector_val)};
            nargs++;
        end

        if ($value$plusargs("BOOTROM_BIN=%s", bootrom_bin_val)) begin
            params = {params, $sformatf("--bootrom-file=%s ", bootrom_bin_val)};
            nargs++;
        end

        if ($value$plusargs("ADDR_SPACE=%s", m)) begin
            params = {params, $sformatf("-m%s ", m)};
            nargs++;
        end

        if (!$value$plusargs("TEST_BIN=%s", exec_bin)) begin
            `uvm_fatal(get_type_name(), "To use spike_seq.sv you need to pass +SPIKE_BIN plusarg")
        end
        params = {params, exec_bin};
        nargs++;

        `uvm_info(get_type_name(), $sformatf("[SPIKE] Calling Setup DPI Function with nargs: %d argv: %p", nargs, params), UVM_LOW)
        spike_setup(nargs, params);

        `uvm_info(get_type_name(), $sformatf("[SPIKE] Starting execution"), UVM_LOW)
        start_execution();

        if(!uvm_config_db#(longint)::get(null, "core_bin_test", "tohost_addr", tohost_addr)) begin
            `uvm_info(get_type_name(), "Spike: No tohost_addr", UVM_HIGH)
        end
        if(!uvm_config_db#(longint)::get(null, "core_bin_test", "fromhost_addr", fromhost_addr)) begin
            `uvm_info(get_type_name(), "Spike: No fromhost_addr", UVM_HIGH)
        end
        else
        begin
            set_tohost_addr(tohost_addr, fromhost_addr);
        end

        if(!uvm_config_db#(longint)::get(null, "core_bin_test", "clearmip_addr", clearmip_addr)) begin
            `uvm_info(get_type_name(), "Spike: No clearmip_addr", UVM_HIGH)
        end
        else
        begin
            set_clearmip_addr(clearmip_addr);
        end

        `uvm_info(get_type_name(), $sformatf("Finishing Spike - ISS Simulator Setup"), UVM_LOW)
    endfunction : setup

    virtual function void run_and_retrieve_results(input int unsigned instr, ref iss_state_t results);
        int exitcode;

        if (!active)
            `uvm_fatal(get_type_name(), $sformatf("Spike has finished but UVM tried to inject instr %h", instr))

        active = run_and_inject(instr, results.scalar_state);

        if( is_vector(instr) ) begin //if the instruction is a vector one, then get results from spike
            get_dst_vreg (results.scalar_state.dst_num, results.rvv_state.vd);
            get_src_vreg (results.scalar_state.src1_num, results.rvv_state.vs1);
            get_src_vreg (results.scalar_state.src2_num, results.rvv_state.vs2);
            get_src_vreg (results.scalar_state.dst_num, results.rvv_state.vs3);
            get_src_vreg (results.scalar_state.dst_num, results.rvv_state.old_vd);
            get_src_vreg (0, results.rvv_state.vmask);

        end
        if (!active) begin
            exitcode = exit_code();
            `uvm_info(get_type_name(), $sformatf("Core has finished with exit code %h", exitcode), UVM_LOW)
        end
    endfunction : run_and_retrieve_results

    virtual function void read_n_words_at_address(input int unsigned n, input logic [63:0] address, output logic [7:0] read_memory[]);
        for (int i = 0; i < n; i++) begin
            get_memory_data(read_memory[i], address + i*8);
        end
    endfunction : read_n_words_at_address

    virtual function void write_n_bytes_at_address(input int unsigned n, input logic [63:0] address, input logic [7:0] data[]);

    endfunction : write_n_bytes_at_address

    virtual function void write_if_not_initialized(input logic[63:0] addr, input logic [127:0] data, input int size);
        void'(set_memory_data(addr,data,size));
    endfunction : write_if_not_initialized

    virtual function void step(input int unsigned n);
        do_step(n);
    endfunction : step

    virtual function void set_interrupt(input int unsigned value);
        iss_state_t tmp;
        `uvm_info(get_type_name(), $sformatf("Spike set_interrupt with value: %h", value), UVM_DEBUG)
        spike_set_external_interrupt((1 << value));
        run_and_retrieve_results(32'h13, tmp);
        spike_set_external_interrupt(0);
    endfunction : set_interrupt

    virtual function longint unsigned tlb_address_translate(longint addr, longint len, longint typ, longint satp, longint priv_lvl, longint mstatus, ref longint exc_error,  ref longint leaf_addr);
        longint unsigned paddr;
        `uvm_info(get_type_name(), $sformatf("Translating address, addr: %h, len: %h, typ: %h, satp: %h, priv_lvl: %h, mstatus: %h, exc_error: %h", addr, len, typ, satp, priv_lvl, mstatus, exc_error), UVM_DEBUG)
        paddr = address_translate(addr, len, typ, satp, priv_lvl, mstatus, exc_error, leaf_addr);
        return paddr;
    endfunction

    virtual function void set_external_interrupt(input int unsigned value);
        `uvm_info(get_type_name(), $sformatf("Spike set_external_interrupt with value: %h", value), UVM_DEBUG)
        spike_set_external_interrupt(value);
    endfunction : set_external_interrupt

    virtual function longint get_mie();
        longint mie = spike_get_csr('h304);
        //`uvm_info(get_type_name(), $sformatf("Spike MIE: %h", mie), UVM_DEBUG)
        return mie;
    endfunction : get_mie

    virtual function int get_prv_lvl();
        int prv_lvl = spike_get_prv_lvl();
        //`uvm_info(get_type_name(), $sformatf("Spike MIE: %h", mie), UVM_DEBUG)
        return prv_lvl;
    endfunction : get_prv_lvl

    virtual function void set_fp_reg_value(input int unsigned reg_dst, input longint value);
        spike_set_fp_reg_value(reg_dst, value);
    endfunction : set_fp_reg_value

    virtual function void set_destination_reg_value(input int unsigned reg_dst, input longint value);
        spike_set_dest_reg_value(reg_dst, value);
    endfunction : set_destination_reg_value

    virtual function logic is_vector_ins(input longint unsigned instr);
        return is_vector(instr);
    endfunction : is_vector_ins

    virtual function void set_plic_interrupt_level(input int id, input int level);
        spike_plic_set_interrupt_level(id, level);
    endfunction : set_plic_interrupt_level

    virtual function void get_plic_enable(input int ctx, output int unsigned enable[8]);
        spike_get_plic_enable(ctx, enable);
    endfunction

    virtual function void clint_increment(input int val);
        spike_clint_set_increment(val);
    endfunction

endclass : core_spike

`endif

