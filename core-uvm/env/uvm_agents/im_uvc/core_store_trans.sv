`ifndef CORE_STORE_TRANS
`define CORE_STORE_TRANS

class core_store_trans extends uvm_transaction;

    logic [63:0] store_data;
    logic [63:0] rob_entry;

    `uvm_object_utils_begin(core_store_trans)
        `uvm_field_int(store_data, UVM_ALL_ON)
        `uvm_field_int(rob_entry, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "core_store_trans");
        super.new(name);
    endfunction : new

endclass : core_store_trans

`endif
