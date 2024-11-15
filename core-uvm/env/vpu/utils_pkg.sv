`ifndef UTILS_PKG_SV
`define UTILS_PKG_SV

package utils_pkg;

    import uvm_pkg::*;
    import common_params_pkg::*;
    import EPI_pkg::*;
    `include "uvm_macros.svh"

    localparam N_LANES = EPI_pkg::N_LANES;
    localparam CORE_DATA = 64;
    localparam CORE_MEM_ADDR = 64;
    localparam BYTE = 8;
    localparam SEQ_ID_VREG_WIDTH = EPI_pkg::V_REG_WIDTH;
    localparam SEQ_ID_EL_ID_WIDTH = EPI_pkg::EL_ID_WIDTH;
    localparam SEQ_ID_EL_OFF_WIDTH = EPI_pkg::EL_OFFSET_WIDTH;
    localparam SEQ_ID_EL_COUNT_WIDTH = EPI_pkg::EL_COUNT_WIDTH;
    localparam INDEX_MASK_BIT = 64;

    localparam MAX_INFLIGHT_LOADS = 2;
    localparam MAX_INFLIGHT_STORES = 1;

    typedef enum int {
        EXIT_SUCCESS,
        EXIT_TIMEOUT,
        EXIT_COMP_ERROR,
        EXIT_EXECUTION_ERROR,
        EXIT_SPIKE_ERROR,
        EXIT_ASSERTION_ERROR,
        EXIT_BINARY_ERROR,
        EXIT_ILLEGAL_MISMATCH
    } exit_status_code_t;

    string exit_status_strings [8]  = '{
        "EXIT_SUCCESS",
        "EXIT_TIMEOUT",
        "EXIT_COMP_ERROR",
        "EXIT_EXECUTION_ERROR",
        "EXIT_SPIKE_ERROR",
        "EXIT_ASSERTION_ERROR",
        "EXIT_BINARY_ERROR",
        "EXIT_ILLEGAL_MISMATCH"
    };
    
    `include "macros.sv"
    `include "seq_id.sv"
    `include "vpu_ins_tx.sv"
    `include "utilities.sv"
    `include "protocol_utilities.sv"
    `include "protocol_class.sv"
    
endpackage : utils_pkg

`endif
