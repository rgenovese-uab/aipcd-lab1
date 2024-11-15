`ifndef CORE_DCACHE_STORE_TRANS_SV
`define CORE_DCACHE_STORE_TRANS_SV

class core_dcache_store_trans extends uvm_sequence_item;
    `uvm_object_utils(core_dcache_store_trans)

    function new(string name = "core_dcache_store_trans");
        super.new(name);
    endfunction : new

    drac_pkg::bus64_t data;
    logic[7:0]           tag;

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
    endfunction : do_print

endclass : core_dcache_store_trans

`endif
