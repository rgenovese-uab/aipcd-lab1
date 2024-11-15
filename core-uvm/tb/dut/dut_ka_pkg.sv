`ifndef DUT_PKG
`define DUT_PKG

package dut_pkg;

    localparam COMMIT_WIDTH = 2;
    localparam MAX_64BIT_BLOCKS = EPI_pkg::MAX_64BIT_BLOCKS;
    localparam MAX_VLEN = EPI_pkg::MAX_VLEN;
    localparam MIN_SEW = EPI_pkg::MIN_SEW;
    localparam PADDR_WIDTH = 7;
    localparam FFLAG_WIDTH = 5;
    localparam SB_WIDTH = 5;
    typedef logic [6:0]  rob_addr_t;
    localparam FETCH_WIDTH = 2;
    localparam PREG_WIDTH = 7;
    localparam REGFILE_DEPTH = lagarto_ka_pkg::REGFILE_DEPTH;
    localparam VLEN = EPI_pkg::VLEN;
    `include "types.sv"
endpackage : dut_pkg

`endif
