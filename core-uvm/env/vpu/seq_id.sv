`ifndef SEQ_ID
`define SEQ_ID

class seq_id;

    logic [SEQ_ID_VREG_WIDTH-1:0]   vreg;
    logic [SEQ_ID_EL_ID_WIDTH-1:0]  el_id;
    logic [SEQ_ID_EL_OFF_WIDTH-1:0] el_off;
    logic [SEQ_ID_EL_COUNT_WIDTH-1:0]     el_count;
    logic [EPI_pkg::SB_WIDTH-1:0] sb_id;

    function logic [EPI_pkg::SEQ_ID_WIDTH-1:0] to_logic();
        return {sb_id, el_count, el_off, el_id, vreg};
    endfunction : to_logic

    function set_values(logic [SEQ_ID_VREG_WIDTH-1:0] vreg, logic [SEQ_ID_EL_ID_WIDTH-1:0] el_id, logic [SEQ_ID_EL_OFF_WIDTH-1:0] el_off, logic [SEQ_ID_EL_COUNT_WIDTH-1:0] el_count, logic [EPI_pkg::SB_WIDTH-1:0] sb_id);
        this.vreg = vreg;
        this.el_id = el_id;
        this.el_off = el_off;
        this.el_count = el_count;
        this.sb_id = sb_id;
    endfunction : set_values

    function copy(seq_id seq_id);
        vreg = seq_id.vreg;
        el_id = seq_id.el_id;
        el_off = seq_id.el_off;
        el_count = seq_id.el_count;
        sb_id = seq_id.sb_id;
    endfunction : copy

endclass : seq_id

`endif
