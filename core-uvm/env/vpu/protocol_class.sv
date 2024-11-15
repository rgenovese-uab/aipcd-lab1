virtual class protocol_base_class;

    // Task: do_protocol
    // Runs the specific protocol of the interface to stimulate the DUT
    pure virtual task do_protocol();

    // Task: wait_for_clk
    // Waits for as many num_cycles cycles in the interface clock
    pure virtual task wait_for_clk(int unsigned num_cycles = 1);

    // Function: drive
    // Pushes the instruction inside the transaction into the pending instructions queue
    pure virtual function drive (vpu_ins_tx req);

    // Function: new_ins_tx
    // Returns whether or not there are new instructions received from the driver
    pure virtual function bit new_ins_tx();

    // Function: monitor_pre
    // Returns the first pending instruction received from the driver
    pure virtual function core_uvm_types_pkg::iss_rvv_state_t monitor_pre();

    // Function: new_dut_tx
    // Returns whether or not there are new completed instructions
    pure virtual function bit new_dut_tx();

    // Function: monitor_post
    // Returns the first pending completed instruction
    pure virtual function core_uvm_types_pkg::dut_rvv_state_t monitor_post();

    // Function: new_protocol_tx
    // Returns whether or not there are new completed instructions
    pure virtual function bit new_protocol_tx();

    // Function: monitor_protocol
    // Returns the first pending completed instruction
    pure virtual function protocol_instr_t monitor_protocol();

    // Function: next_infl_instr
    // Returns the first infl instruction
    pure virtual function protocol_instr_t next_infl_instr();

endclass : protocol_base_class
