#ifndef SPIKE_WRAPPER
    #define SPIKE_WRAPPER

#include "config.h"
#include "sim.h"
#include "mmu.h"
#include "remote_bitbang.h"
#include "cachesim.h"
#include "extension.h"
// #include <dlfcn.h>
#include <fesvr/option_parser.h>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <string>
#include <memory>
#include "../VERSION"
#include <fstream>
#include "decode.h"
#include "red_ref_model/reduction.h"

using namespace std;

enum class csr_vlmul_t : uint8_t {
    VFLMUL2  = 7,
    VFLMUL4  = 6,
    VFLMUL8  = 5,
    RESERVED = 4,
    VLMUL8   = 3,
    VLMUL4   = 2,
    VLMUL2   = 1,
    VLMUL1   = 0
};

struct csr_t_spike {
    // Exceptions
    uint8_t  trap_illegal;
    uint64_t mcause;
    uint64_t scause;
    // Vector
    uint32_t vstart;
    uint32_t vl;
    uint8_t vxrm;
    csr_vlmul_t vlmul;
    uint8_t vsew;
    uint8_t vill;
    uint8_t vxsat;
    uint8_t vta;
    uint8_t vma;
    // FP (Shared by Vector and Scalar)
    uint8_t  frm;    // floating-point rounding  Mode
    uint8_t  fflags; // floating-point accrued exception fflags
    // Scalar
    uint64_t mstatus;
    uint64_t misa;
};

struct core_state_t {
    // Instruction
    uint64_t           core_id;
    uint64_t           pc;
    uint32_t           ins;
    char*              disasm;
    // Sources/dst (and values for scalar)
    uint8_t            dst_valid;
    uint8_t            dst_num;
    uint64_t           dst_value;
    uint8_t            src1_valid;
    uint8_t            src1_num;
    uint64_t           src1_value;
    uint8_t            src2_valid;
    uint8_t            src2_num;
    uint64_t           src2_value;
    // Memory access info
    uint64_t           vaddr;
    uint64_t           paddr;
    uint64_t           store_data;
    uint64_t           store_mask;
    // Status
    struct csr_t_spike csr;
    uint8_t            exc_bit;
};

class spike_wrapper {
public:

    sim_t* s;
    int prev_pc;
    void* vector_reg_file;
    static const int VLEN = MAX_VLEN;

    bool SMD_mode = false;
    bool eprocessor_mode = false;
    std::vector<std::pair<reg_t, mem_t*>> mems;
    std::vector<std::pair<reg_t, abstract_device_t*>> plugin_devices;

    reg_t XPR[NXPR];
    freg_t FPR[NFPR];

    int reduction_lanes;
    int reduction_fp_accums;
    int reduction_int_accums;
    //int reduction_tree_intra;
    //int reduction_tree_inter;
    int reduction_tree_enable;

    spike_wrapper();

    ~spike_wrapper();

    // Setups the configuration for spike and assigns a sim_t instance to s
    void setup(int nargs, const char** args);

    // Calls the run method to run the program once and the resets the core so it can execute step by step
    void start_execution();

    int run_and_inject(uint32_t instr, core_state_t* core_state);

    // Executes an instruction and returns the info of the core thorugh the core_info
    void step(core_state_t* core_info);

    int run_until_vector_ins(core_state_t* core_info);

    // rgenovese - aipcd lab3 ------------------------------------------
    int run_until_rgb2yuv_instruction(core_state_t* core_info);
    bool is_not_rgb2yuv(insn_t ins);
    // -----------------------------------------------------------------

    // Gets the data of the memory mem
    int load_uint(uint64_t* data, uint64_t address);

    // Given a processor_t pointer, copy its Vectorial Unit register file into ours
    void copy_vector_reg_file(processor_t* core);

    void copy_scalar_reg_file(regfile_t<reg_t, NXPR, true> regfile);

    void copy_fp_reg_file(regfile_t<freg_t, NFPR, false> regfile);

    reg_t get_csr(int which);

    reg_t get_prv_lvl();
    void set_mip_ei(reg_t val);

    // Embeeds the vpu result to the least significant 64 bits of vdest inside the register file
    void feed_reduction_result(uint64_t vpu_result, uint32_t vdest);

    void print_core_state(core_state_t* core_state);

    void* calculate_addrs (core_state_t* core_info, bool* misaligned, char* misaligned_cause);

    void save_scalar_state(processor_t* core, core_state_t* core_state);

    void save_vector_state(processor_t* core, core_state_t* core_state);

    bool is_not_vector(insn_t ins);
    //void set_mip_ei(reg_t val);

    reg_t address_translate(reg_t addr, reg_t len, access_type type, reg_t satp, reg_t priv_lvl, reg_t mstatus,  reg_t* exc_error);

    void set_csr_fflags(const reg_t);

    void set_fp_reg(int reg_dst, reg_t val);

    void set_dest_reg(int reg_dst, reg_t val);

    bool is_vector(insn_t ins);

    // Utils to encode info when communicating with testbench
    csr_vlmul_t encode_vlmul(float vflmul);
};

#endif
