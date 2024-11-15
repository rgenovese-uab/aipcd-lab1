//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_iss_wrapper 
// File          : core_iss_wrapper.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is core_iss_wrapper file. Providing reference_model wrapper
//                 which can be override by spike through core_base_test. 
//----------------------------------------------------------------------
`ifndef CORE_ISS_WRAPPER_SV
`define CORE_ISS_WRAPPER_SV

class core_iss_wrapper extends uvm_object;
    `uvm_object_utils(core_iss_wrapper)

    int active;

    function new(string name = "core_iss_wrapper");
        super.new(name);
    endfunction : new

    virtual function void setup();

        active = 1;

    endfunction : setup

    virtual function void run_and_retrieve_results(int unsigned instr, ref iss_state_t results);

    endfunction : run_and_retrieve_results

    virtual function void read_n_words_at_address(input int unsigned n, input logic [63:0] address, output logic [7:0] read_memory[]);

    endfunction : read_n_words_at_address

    virtual function void write_n_bytes_at_address(input int unsigned n, input logic [63:0] address, input logic [7:0] data[]);

    endfunction : write_n_bytes_at_address

    virtual function void write_if_not_initialized(input logic[63:0] addr, input logic [127:0] data, input int size);

    endfunction : write_if_not_initialized

    virtual function void step(input int unsigned n);

    endfunction : step

    virtual function void set_interrupt(input int unsigned value);

    endfunction : set_interrupt

    virtual function longint unsigned tlb_address_translate(longint addr, longint len, longint typ, longint satp, longint priv_lvl, longint mstatus, ref longint exc_error, ref longint leaf_addr);

    endfunction : tlb_address_translate

    virtual function void set_external_interrupt(input int unsigned value);

    endfunction : set_external_interrupt

    virtual function longint get_mie();

    endfunction : get_mie

    virtual function int get_prv_lvl();

    endfunction : get_prv_lvl

    virtual function void set_fp_reg_value(input int unsigned reg_dst, input longint value);

    endfunction : set_fp_reg_value
    virtual function void set_destination_reg_value(input int unsigned reg_dst, input longint value);

    endfunction : set_destination_reg_value
    
    virtual function int run_until_vector_ins(ref iss_state_t iss_state);

    endfunction : run_until_vector_ins
    virtual function logic is_vector_ins(input longint unsigned instr);

    endfunction

    virtual function void set_plic_interrupt_level(input int id, input int level);

    endfunction : set_plic_interrupt_level

    virtual function void get_plic_enable(input int ctx, output int unsigned enable[8]);
    
    endfunction

    virtual function void clint_increment(input int val);
    
    endfunction
endclass : core_iss_wrapper

`endif
