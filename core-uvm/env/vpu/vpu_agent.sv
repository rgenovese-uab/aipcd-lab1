
`ifndef VPU_AGENT_SV
`define VPU_AGENT_SV

// Instruction management agent
class vpu_agent extends uvm_agent;
    `uvm_component_utils(vpu_agent)

    vpu_agent_cfg m_vpu_cfg; //has interfaces

    vpu_monitor_post m_monitor_post;

    vpu_isa_scoreboard m_isa_scoreboard;

    protocol_base_class m_protocol_class;

    function new(string name = "vpu_agent", uvm_component parent);
        super.new(name,parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(vpu_agent_cfg)::get(this,"","m_vpu_agent_cfg", m_vpu_cfg))
            `uvm_fatal("VPU AGENT", "m_vpu_agent_cfg - get failed");

        m_isa_scoreboard = vpu_isa_scoreboard::type_id::create("m_isa_scoreboard", this);
        m_isa_scoreboard.m_cfg = m_vpu_cfg;

        m_monitor_post = vpu_monitor_post::type_id::create("m_monitor_post", this);


    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_protocol_class = m_vpu_cfg.m_dut_if.m_protocol_class;

        m_monitor_post.m_cfg = m_vpu_cfg;
        m_monitor_post.m_protocol_class = m_protocol_class;
    endfunction : connect_phase

    // Task: run_phase
    virtual task run_phase(uvm_phase phase);
        m_protocol_class.do_protocol();
    endtask : run_phase

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
    endfunction : start_of_simulation_phase
endclass

`endif
