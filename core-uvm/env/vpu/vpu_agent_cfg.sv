`ifndef VPU_AGENT_CFG_SV
`define VPU_AGENT_CFG_SV

class vpu_agent_cfg extends uvm_object;
    `uvm_object_utils(vpu_agent_cfg)

    function new(string name = "");
        super.new(name);
    endfunction : new

    // Variable: active
    uvm_active_passive_enum active = UVM_ACTIVE;
    bit disable_checks = 1'b0;

    virtual interface vpu_if m_dut_if;
    virtual interface vreg_if m_vreg_if;
    virtual interface restore_vstart_if m_restore_vstart_if;

endclass : vpu_agent_cfg

`endif
