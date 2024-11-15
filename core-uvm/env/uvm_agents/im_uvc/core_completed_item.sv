class core_completed_item
    extends uvm_sequence_item;

    localparam COMMIT_WIDTH = 2;
    localparam PADDR_WIDTH = 5;
    `uvm_object_utils(core_completed_item)

    function new(string name = "core_completed_item");
        super.new(name);
    endfunction

    logic                   clk;
    logic                   rsn;
    logic                   valid[COMMIT_WIDTH-1:0];
    logic [63:0]            pc[COMMIT_WIDTH-1:0];
    logic [31:0]            instr[COMMIT_WIDTH-1:0];
    logic [63:0]            result[COMMIT_WIDTH-1:0];
    logic                   result_valid[COMMIT_WIDTH-1:0];
    logic                   xcpt[COMMIT_WIDTH-1:0];
    logic [63:0]            xcpt_cause[COMMIT_WIDTH-1:0];
    logic [PADDR_WIDTH-1:0] pdest;
    logic [63:0]            store_data; // TODO ?
    logic                   store_valid[COMMIT_WIDTH-1:0];
    logic                   branch[COMMIT_WIDTH-1:0];
    logic [dut_pkg::VLEN-1:0] vd[COMMIT_WIDTH-1:0];

endclass
