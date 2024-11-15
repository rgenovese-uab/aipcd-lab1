`ifndef DUT_PKG
`define DUT_PKG

package dut_pkg;

    // Needed for Lagarto Ka. Eventually remove
    localparam REGFILE_DEPTH = 128;

    // Default values for BSC_CSR params, not defined in any RTL package apparently
    // TODO remove as possible
    localparam word_width = 64;
    localparam addr_width_extended = 40;
    localparam paddr_width = 32;
    localparam csr_addr_width = 12;
    localparam mtvec_par = 'h104;
    localparam start_addr_par = 'h100;
    localparam core_id = 1'b0;
    localparam boot_addr = 'h100;
    localparam AsidWidth = 13;

// TODO Get from RTL package
    localparam COMMIT_WIDTH = 2;
    localparam PADDR_WIDTH = 5;
    localparam MAX_64BIT_BLOCKS = 2;
    localparam MAX_VLEN = 128;
    localparam MIN_SEW = 8;
    localparam FFLAG_WIDTH = 5;
    localparam SB_WIDTH = 5;
    typedef logic [6:0]  rob_addr_t;
    localparam FETCH_WIDTH = 2;
    localparam PREG_WIDTH = 7;
    localparam VLEN = riscv_pkg::VLEN;

    `include "types.sv"

endpackage : dut_pkg

`endif
