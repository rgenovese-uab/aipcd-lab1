//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : core_env_cfg 
// File          : core_env_cfg.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_object. This class is 
//                 common database of config_db for environment class.
//----------------------------------------------------------------------
`ifndef CORE_ENV_CFG_SV
`define CORE_ENV_CFG_SV

// Class: core_env_cfg
class core_env_cfg extends uvm_object;
    `uvm_object_utils(core_env_cfg)

    // Variable: heartbeat_timeout
    int heartbeat_timeout = 50;
    // Variable: imu_agent_cfg
    core_im_agent_cfg imu_agent_cfg;

    // Variable: int_cfg
    core_int_cfg int_cfg;

    // Variable: icache_cfg
    core_icache_cfg ic_cfg;

    // Variable: dcache_cfg
    core_dcache_cfg dc_cfg;

    bit disable_store_checks;
    core_type_t core_type;
    logic [15:0] mtimecmp_offset;
    logic is_cpu_ss;
    logic vpu_enabled;
    logic jtag_test;
    // Group: Functions

    // Function : new
    function new(string name = "");
        super.new(name);
        imu_agent_cfg = core_im_agent_cfg::type_id::create("imu_agent_cfg");
        int_cfg = core_int_cfg::type_id::create("int_cfg");
        ic_cfg = core_icache_cfg::type_id::create("ic_cfg");
        dc_cfg = core_dcache_cfg::type_id::create("dc_cfg");
        disable_store_checks = 1'b0;
        core_type = SARGANTANA; // TODO set externally
        mtimecmp_offset = 'h4000; // CPU_SS LAGARTO Ka -> 'h4008  CPU_SS LAGARTO OX -> 'h4010
        is_cpu_ss = 1'b0; // Default to stand-alone mode. Set to one to enable integration in cpu_subsystem
        vpu_enabled = 1'b0;
        jtag_test = 1'b0;
    endfunction : new

endclass : core_env_cfg

`endif
