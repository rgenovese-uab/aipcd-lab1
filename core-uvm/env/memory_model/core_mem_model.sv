//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_mem_model 
// File          : core_mem_model.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is core_mem_model file. Providing static memory_model
//                 which will be loaded with riscv binary which further helps 
//                 to communicate with dut. 
//----------------------------------------------------------------------

class core_mem_model #(
    parameter     ADDR_WIDTH = 64,
    parameter     DATA_WIDTH = 128
) extends uvm_object ;

    localparam      NB_BYTE = 8;

    typedef bit [ADDR_WIDTH - 1 :0] mem_addr_t;
    typedef bit [DATA_WIDTH - 1 :0] mem_data_t;

    bit     [NB_BYTE        - 1 : 0]    system_memory[mem_addr_t];
    logic   [ADDR_WIDTH     - 1 : 0]    acquired_exclusive_addr[$];

    core_iss_wrapper m_iss;

    `uvm_object_param_utils(core_mem_model#(ADDR_WIDTH, DATA_WIDTH))

    // Singleton
    static core_mem_model#(ADDR_WIDTH, DATA_WIDTH) mem_model_single;

    static function core_mem_model#(ADDR_WIDTH, DATA_WIDTH) create_instance(string name = "avispado_mod_mem_model");
        if (mem_model_single == null)
        begin
            `uvm_info("MEMORY MODEL", $sformatf("CREATING MEMORY MODEL WITH ADDR WIDTH = %d, DATA WITDH = %d", ADDR_WIDTH, DATA_WIDTH), UVM_HIGH)
            mem_model_single = core_mem_model#(ADDR_WIDTH, DATA_WIDTH)::type_id::create(name);
        end
        else
            `uvm_info("MEMORY MODEL", $sformatf("MEMORY MODEL ALREADY CREATED"), UVM_HIGH)

        return mem_model_single;
    endfunction : create_instance

    static function core_mem_model get_instance(); // for future alternative of create_instance (only 1 time) but this (can be multiple time)
        return mem_model_single;
    endfunction : get_instance

    function new(string name = "avispado_mod_mem_model");
        super.new(name);
    endfunction : new

    function bit [NB_BYTE   - 1 : 0] read_byte(mem_addr_t addr);
        bit [NB_BYTE    - 1 :0] data;
        if (system_memory.exists(addr)) begin
            data = system_memory[addr];
            //`uvm_info(get_full_name(),$sformatf("Read Mem  : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_HIGH)
        end
       else
       begin
           `uvm_info(get_full_name(), $sformatf("read to uninitialzed addr 0x%0h", addr), UVM_DEBUG)
       end
        return data;
    endfunction

    function void write_byte(mem_addr_t addr, bit [NB_BYTE - 1 :0] data);
        `uvm_info(get_full_name(), $sformatf("Write Mem : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_DEBUG)
        system_memory[addr] = data;
    endfunction

    function void write(input mem_addr_t addr, mem_data_t data);
        bit [NB_BYTE - 1 : 0] byte_data;
        for (int i = 0; i < DATA_WIDTH/NB_BYTE; i++)
        begin
            byte_data = data[(i+1)*NB_BYTE - 1 -: NB_BYTE];
            write_byte(addr + i, byte_data);
        end
        `uvm_info(get_full_name(), $sformatf("Write Mem : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_DEBUG)
    endfunction


    function void write_el(input mem_addr_t addr, logic [63:0] data, int sew);
        bit [7:0] byte_data;
        for (int i = 0; i < sew / 8; i++)
        begin
            byte_data = data[7:0];
            write_byte(addr + i, byte_data);
            data = data >> 8;
        end
    endfunction

    function mem_data_t read(mem_addr_t addr);
        mem_data_t data;
        for (int i = DATA_WIDTH/NB_BYTE - 1; i >= 0; i--)
        begin
            data[(i+1)*NB_BYTE - 1 -: NB_BYTE]  = read_byte(addr + i);
        end
        `uvm_info(get_full_name(), $sformatf("Read Mem : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_DEBUG)
        return data;
    endfunction


    function logic [63:0] read64(mem_addr_t addr);
        mem_data_t data;
        for (int i = 64 / 8 - 1; i >= 0; i--) begin
            data = data << 8;
            data[7:0] = read_byte(addr + i);
        end
        `uvm_info(get_full_name(), $sformatf("Read Mem : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_DEBUG)
        return data;
    endfunction

    function logic [31:0] read32(mem_addr_t addr);
        mem_data_t data;
        for (int i = 32 / 8 - 1; i >= 0; i--) begin
            data = data << 8;
            data[7:0] = read_byte(addr + i);
        end
        `uvm_info(get_full_name(), $sformatf("Read Mem : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_DEBUG)
        return data;
    endfunction

    function mem_data_t read_cache(mem_addr_t addr);
        mem_addr_t addr_in = addr;
        mem_data_t data;
        addr_in[3:0] = 0;
        data = read(addr_in);
        `uvm_info(get_full_name(), $sformatf("Read Mem : Addr[0x%0h], Data[0x%0h]", addr_in, data), UVM_DEBUG)
        return data;
    endfunction

endclass : core_mem_model
