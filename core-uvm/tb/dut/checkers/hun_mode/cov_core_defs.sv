package cov_core_defs;
parameter WINDOW_SIZE  = 5;
parameter IMPLEMENTED_VA_SIZE = 39;
parameter IMPLEMENTED_PA_SIZE = 32;
parameter TLB_ENTRIES = 16;
parameter NUM_IS_BRANCH_ENTRIES = 64;
parameter Dcache_Ports  = 3; //0 = core load, 1 = ptw load, 2 = core store
parameter PIPELINE_STAGES = 5;
parameter BRANCH_PMU_EVENTS = 9;

typedef struct packed {
      logic [ariane_pkg::ASID_WIDTH-1:0] asid;
      logic [8:0]            vpn2;
      logic [8:0]            vpn1;
      logic [8:0]            vpn0;
      logic                  is_2M;
      logic                  is_1G;
      logic                  valid;
    } [TLB_ENTRIES-1:0] tlb_tags_q_t;

endpackage