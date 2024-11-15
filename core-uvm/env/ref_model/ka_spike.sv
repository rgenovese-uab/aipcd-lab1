//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : ka_spike 
// File          : ka_spike.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This is ka_spike class extended from ka_iss_wrapper. 
//                 Providing Spike as reference model.
//----------------------------------------------------------------------
`ifndef KA_SPIKE_SV
`define KA_SPIKE_SV

class ka_spike extends core_uvm_pkg::core_spike;
    `uvm_object_utils(ka_spike)

    function new(string name = "ka_spike");
        string lanes;
        super.new(name);
        $sformat(lanes, "%0d", utils_pkg::N_LANES);
        reduction_config = {lanes,":7:3:3"};
    endfunction : new

    virtual function void setup();
        core_type = "LAGARTO_KA";
        vlen = 256*64; // TODO Package
        isa = "RV64IMAFDV";
        $sformat(reduction_config, "%0d:7:3:3", utils_pkg::N_LANES);
        super.setup();
    endfunction : setup

endclass : ka_spike

`endif


