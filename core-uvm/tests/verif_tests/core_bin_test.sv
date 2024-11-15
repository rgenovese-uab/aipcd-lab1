//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_bin_test 
// File          : core_bin_test.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from core_base_test. This class instantiates the
//                 testcase is fully dedicated for loading the memory_model with 
//                 specific binary data.  
//----------------------------------------------------------------------
`ifndef CORE_BIN_TEST_SV
`define CORE_BIN_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

import "DPI-C" function void read_elf(input string filename);
import "DPI-C" function byte get_section(output longint address, output longint len);
import "DPI-C" context function byte read_section(input longint address, inout byte buffer[]);
import "DPI-C" function byte get_symbol_addr(input string name, inout longint addr);


// Class core_bin_test
class core_bin_test extends core_base_test;
    `uvm_component_utils(core_bin_test)

    // Group: Variables

    // Variable: pool
    uvm_event_pool pool = uvm_event_pool::get_global_pool();

    uvm_event end_test_tohost = pool.get("end_test_tohost");

    uvm_event end_test_sentinel = pool.get("end_test_sentinel");


    // Variable: filename
    string filename;
    string brom_filename;

    // Group: Functions

    // Function: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Function: build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Override the sequence type by the binary one

        if ($test$plusargs("TEST_BIN") && $value$plusargs ("TEST_BIN=%s", filename)) begin
            int filename_fd;
            int found;
            longint tohost_addr;
            longint fromhost_addr;
            longint clearmip_addr;
            string tohost = "tohost";
            string fromhost = "fromhost";
            string clear_mip = "dv_clear_mip";

            `uvm_info(get_type_name(), $sformatf("Test binary to be loaded and executed is %s", filename), UVM_LOW)

            filename_fd = $fopen(filename, "r");

            if(!filename_fd)
                `uvm_fatal(get_type_name(), $sformatf("Filename %s does not exist", filename))

            $fclose(filename_fd);

            read_elf(filename);
            found = get_symbol_addr(tohost, tohost_addr);

            if( !found) begin
                `uvm_info(get_type_name(), "No tohost symbol found", UVM_LOW)
            end
            else begin
                uvm_config_db#(longint)::set(null, "core_bin_test", "tohost_addr", tohost_addr);
                `uvm_info(get_type_name(), $sformatf("tohost symbol: %d",tohost_addr), UVM_LOW)
            end
            found = get_symbol_addr(fromhost, fromhost_addr);

            if(!found) begin
                `uvm_info(get_type_name(), "No fromhost symbol found", UVM_LOW)
            end
            else begin
                uvm_config_db#(longint)::set(null, "core_bin_test", "fromhost_addr", fromhost_addr);
                `uvm_info(get_type_name(), $sformatf("fromhost symbol: %d",fromhost_addr), UVM_LOW)
            end

            found = get_symbol_addr(clear_mip, clearmip_addr);

            if(!found) begin
                `uvm_info(get_type_name(), "No clear_mip symbol found", UVM_LOW)
            end
            else begin
                uvm_config_db#(longint)::set(null, "core_bin_test", "clearmip_addr", clearmip_addr);
                `uvm_info(get_type_name(), $sformatf("clear_mip symbol: %d",clearmip_addr), UVM_LOW)
            end

        end
        else begin
            `uvm_fatal(get_type_name(), "Provide a path to a binary with the argument +TEST_BIN")
        end
    endfunction : build_phase

    function void setup_bootrom();
        if ($test$plusargs("BOOTROM_BIN") && $value$plusargs ("BOOTROM_BIN=%s", brom_filename)) begin
            int filename_fd;
            int brom_num_words;
            logic [7:0] brom_byte;
            logic [63:0] reset_vector;
            brom_num_words = 0;
            `uvm_info(get_type_name(), $sformatf("Bootrom binary to be loaded and executed is %s", brom_filename), UVM_LOW)
            filename_fd = $fopen(brom_filename, "rb");
            if(!filename_fd) begin
                `uvm_fatal(get_type_name(), $sformatf("Cannot oppen bootrom file `%s`", brom_filename))
            end
            if ($test$plusargs("RESET_VECTOR") && $value$plusargs ("RESET_VECTOR=0x%x", reset_vector)) begin
                `uvm_info(get_type_name(), $sformatf("Reset vector addr: %x", reset_vector), UVM_LOW)
            end else begin
                `uvm_fatal(get_type_name(), "Provide a reset vector address with argument +RESET_VECTOR")
            end
            while ($fread(brom_byte, filename_fd)) begin
                m_env.mem_model_write(reset_vector + brom_num_words, brom_byte);
                brom_num_words++;
            end
            `uvm_info(get_type_name(), $sformatf("Bootrom loaded in mem[%x] to mem[%x])", reset_vector, reset_vector + brom_num_words - 1), UVM_LOW)
            $fclose(filename_fd);
        end else begin
            `uvm_fatal(get_type_name(), "Provide a path to a bootrom with the argument +BOOTROM_BIN")
        end
    endfunction : setup_bootrom

    // Function: run_phase
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("core_bin_test", "Raising objection", UVM_DEBUG)
        super.run_phase(phase);
        `uvm_info("core_bin_test", "Dropping objection", UVM_DEBUG)
        phase.drop_objection(this);
    endtask : run_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        longint len, address;
        byte buffer[];

        while(get_section(address, len)) begin
            automatic int num_words = (len+7)/8; // I don't understand why +7 (ariane_tb.sv line 137)

            buffer = new [num_words*8];

            `uvm_info(get_type_name(), $sformatf("Loading Address: %x, Length: %x, Num words: %d", address, len, num_words), UVM_LOW)

            void'(read_section(address, buffer));

            for (int i = 0; i < num_words; i++) begin
                for (int j = 0; j < 8; j++) begin
                    m_env.mem_model_write(address + i*8 + j, buffer[i*8 + j]);
                end
            end

        end

        setup_bootrom();

    endfunction : end_of_elaboration_phase

endclass : core_bin_test

`endif
