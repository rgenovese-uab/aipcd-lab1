

import EPI_pkg::MEM_DATA_WIDTH;
import EPI_pkg::LOAD_MASK;
import EPI_pkg::ITEM_WIDTH;

typedef enum {SEQUENTIAL_CL, RANDOM_CL, REALISTIC_CL} lines_modes_t;
typedef enum {SEQUENTIAL_L, RANDOM_L, REALISTIC_L} loads_modes_t;
typedef enum {ENABLED, DISABLED} exception_modes_t;
typedef enum {BURST, RANDOM, DELAY} drive_modes_t;
typedef enum {REALISTIC, INSTANT} credit_modes_t;

typedef struct {
    logic [MEM_DATA_WIDTH-1:0]  data;
    bit                         masked;
    logic [LOAD_MASK-1:0]       mask;
    seq_id                    seq_id;
} cache_line_t;

typedef struct {
    core_uvm_types_pkg::iss_state_t   iss_state;
    bit                         valid_sb_id;
    logic [EPI_pkg::SB_WIDTH-1:0]        sb_id;
    bit                         dispatched;
    bit                         nxt_sen;
    bit                         kill;
    bit                         sync_started;
    bit                         sync_ended;
    logic [EPI_pkg::CSR_VLEN_WIDTH-1:0]  vstart_vlfof;
    int                         vstart;
    cache_line_t                load_lines [$];
    longint unsigned            store_data [$];
    int                         mask_count;
    logic [EPI_pkg::ITEM_WIDTH-1:0]      mask_items [$];
    logic [EPI_pkg::MAX_VLEN/EPI_pkg::MIN_SEW-1:0]        mask_bits;
    core_uvm_types_pkg::vec_els_t                   vreg_data;
    logic                       illegal;
    logic [EPI_pkg::FFLAG_WIDTH-1:0]     fflags;
    logic                       vxsat;
    logic [EPI_pkg::XREG_WIDTH-1:0]      dst_reg;

} protocol_instr_t;
