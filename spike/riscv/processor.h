// See LICENSE for license details.
#ifndef _RISCV_PROCESSOR_H
#define _RISCV_PROCESSOR_H

#include "decode.h"
#include "config.h"
#include "trap.h"
#include "abstract_device.h"
#include <string>
#include <vector>
#include <unordered_map>
#include <map>
#include <cassert>
#include "debug_rom_defines.h"
#include "entropy_source.h"
#include "csrs.h"
#include "isa_parser.h"
#include "triggers.h"
#include "memif.h"
#include "core_type.h"

#define N_LOGICAL_REGS 32
#define DEFAULT_VLEN 16384
#define MAX_VLEN DEFAULT_VLEN
#define MEM_DATA_WIDTH 512
#define CHUNK_NUM 32
#define CHUNK_SIZE 64
#define CHUNK_MULTIPLIER 10

#define MAX_SEW 64
#define VECTOR_ELEMENTS_e64 MAX_VLEN/64
#define VECTOR_ELEMENTS_e32 MAX_VLEN/32
#define VECTOR_ELEMENTS_e16 MAX_VLEN/16
#define VECTOR_ELEMENTS_e8 MAX_VLEN/8

class processor_t;
class mmu_t;
typedef reg_t (*insn_func_t)(processor_t*, insn_t, reg_t);
class simif_t;
class trap_t;
class extension_t;
class disassembler_t;

reg_t illegal_instruction(processor_t* p, insn_t insn, reg_t pc);

struct insn_desc_t
{
  insn_bits_t match;
  insn_bits_t mask;
  insn_func_t rv32i;
  insn_func_t rv64i;
  insn_func_t rv32e;
  insn_func_t rv64e;

  insn_func_t func(int xlen, bool rve)
  {
    if (rve)
      return xlen == 64 ? rv64e : rv32e;
    else
      return xlen == 64 ? rv64i : rv32i;
  }

  static insn_desc_t illegal()
  {
    return {0, 0, &illegal_instruction, &illegal_instruction, &illegal_instruction, &illegal_instruction};
  }
};

// regnum, data
typedef std::unordered_map<reg_t, freg_t> commit_log_reg_t;

// addr, value, size
typedef std::vector<std::tuple<reg_t, uint64_t, uint8_t>> commit_log_mem_t;

enum VRM{
  RNU = 0,
  RNE,
  RDN,
  ROD,
  INVALID_RM
};

template<uint64_t N>
struct type_usew_t;

template<>
struct type_usew_t<8>
{
  using type=uint8_t;
};

template<>
struct type_usew_t<16>
{
  using type=uint16_t;
};

template<>
struct type_usew_t<32>
{
  using type=uint32_t;
};

template<>
struct type_usew_t<64>
{
  using type=uint64_t;
};

template<uint64_t N>
struct type_sew_t;

template<>
struct type_sew_t<8>
{
  using type=int8_t;
};

template<>
struct type_sew_t<16>
{
  using type=int16_t;
};

template<>
struct type_sew_t<32>
{
  using type=int32_t;
};

template<>
struct type_sew_t<64>
{
  using type=int64_t;
};

// architectural state of a RISC-V hart
struct state_t
{
  void reset(processor_t* const proc, reg_t max_isa);

  reg_t pc;
  regfile_t<reg_t, NXPR, true> XPR;
  regfile_t<freg_t, NFPR, false> FPR;

  //scalar mem operation
  reg_t vaddr;
  reg_t store_data;
  reg_t store_mask;

  // control and status registers
  std::unordered_map<reg_t, csr_t_p> csrmap;
  reg_t prv;    // TODO: Can this be an enum instead?
  bool v;
  misa_csr_t_p misa;
  mstatus_csr_t_p mstatus;
  csr_t_p mstatush;
  csr_t_p mepc;
  csr_t_p mtval;
  csr_t_p mtvec;
  csr_t_p mcause;
  wide_counter_csr_t_p minstret;
  wide_counter_csr_t_p mcycle;
  mie_csr_t_p mie;
  mip_csr_t_p mip;
  csr_t_p medeleg;
  csr_t_p mideleg;
  csr_t_p mcounteren;
  csr_t_p mevent[29];
  csr_t_p scounteren;
  csr_t_p sepc;
  csr_t_p stval;
  csr_t_p stvec;
  virtualized_csr_t_p satp;
  csr_t_p scause;

  csr_t_p mtval2;
  csr_t_p mtinst;
  csr_t_p hstatus;
  csr_t_p hideleg;
  csr_t_p hedeleg;
  csr_t_p hcounteren;
  csr_t_p htval;
  csr_t_p htinst;
  csr_t_p hgatp;
  sstatus_csr_t_p sstatus;
  vsstatus_csr_t_p vsstatus;
  csr_t_p vstvec;
  csr_t_p vsepc;
  csr_t_p vscause;
  csr_t_p vstval;
  csr_t_p vsatp;

  csr_t_p gmx_p;
  csr_t_p gmx_t;
  csr_t_p gmx_tb_lo;
  csr_t_p gmx_tb_hi;
  csr_t_p gmx_pos;
  csr_t_p gmx_save;

  reg_t to_host;
  reg_t from_host;

  csr_t_p dpc;
  dcsr_csr_t_p dcsr;
  csr_t_p tselect;
  tdata2_csr_t_p tdata2;
  bool debug_mode;

  mseccfg_csr_t_p mseccfg;

  static const int max_pmp = 16;
  pmpaddr_csr_t_p pmpaddr[max_pmp];

  float_csr_t_p fflags;
  uint32_t last_fflags;
  float_csr_t_p frm;

  csr_t_p menvcfg;
  csr_t_p senvcfg;
  csr_t_p henvcfg;

  csr_t_p mstateen[4];
  csr_t_p sstateen[4];
  csr_t_p hstateen[4];

  csr_t_p htimedelta;
  time_counter_csr_t_p time;
  csr_t_p time_proxy;

  csr_t_p stimecmp;
  csr_t_p vstimecmp;

  bool serialized; // whether timer CSRs are in a well-defined state

  // When true, execute a single instruction and then enter debug mode.  This
  // can only be set by executing dret.
  enum {
      STEP_NONE,
      STEP_STEPPING,
      STEP_STEPPED
  } single_step;

#ifdef RISCV_ENABLE_COMMITLOG
  commit_log_reg_t log_reg_write;
  commit_log_mem_t log_mem_read;
  commit_log_mem_t log_mem_write;
  reg_t last_inst_priv;
  int last_inst_xlen;
  int last_inst_flen;
#endif

  insn_t current_instruction;
};
// this class represents one processor in a RISC-V machine.
class processor_t : public abstract_device_t
{
public:
  processor_t(const isa_parser_t *isa, const char* varch, core_type_t core,
              simif_t* sim, uint32_t id, bool halt_on_reset,
              reg_t reset_vector,
              memif_endianness_t endianness,
              bool has_mboot_main_id, uint64_t mboot_main_id_val,
              FILE *log_file, std::ostream& sout_); // because of command line option --log and -s we need both
  ~processor_t();

  const isa_parser_t &get_isa() { return *isa; }

  void set_debug(bool value);
  void set_histogram(bool value);
#ifdef RISCV_ENABLE_COMMITLOG
  void enable_log_commits();
  bool get_log_commits_enabled() const { return log_commits_enabled; }
#endif
  void reset();
  void step(size_t n); // run for n cycles
  void set_mip_ei(reg_t val); // Andres interrupt implementation
  void put_csr(int which, reg_t val);
  uint32_t get_id() const { return id; }
  reg_t get_csr(int which, insn_t insn, bool write, bool peek = 0);
  reg_t get_csr(int which) { return get_csr(which, insn_t(0), false, true); }
  reg_t get_prv_lvl();
  mmu_t* get_mmu() { return mmu; }
  state_t* get_state() { return &state; }
  unsigned get_xlen() const { return xlen; }
  std::string get_isa_string() { return isa_string; }
  unsigned get_const_xlen() const {
    // Any code that assumes a const xlen should use this method to
    // document that assumption. If Spike ever changes to allow
    // variable xlen, this method should be removed.
    return xlen;
  }
  unsigned get_flen() const {
    return extension_enabled('Q') ? 128 :
           extension_enabled('D') ? 64 :
           extension_enabled('F') ? 32 : 0;
  }
  extension_t* get_extension();
  extension_t* get_extension(const char* name);
  bool any_custom_extensions() const {
    return !custom_extensions.empty();
  }
  bool extension_enabled(unsigned char ext) const {
    if (ext >= 'A' && ext <= 'Z')
      return state.misa->extension_enabled(ext);
    else
      return isa->extension_enabled(ext);
  }
  // Is this extension enabled? and abort if this extension can
  // possibly be disabled dynamically. Useful for documenting
  // assumptions about writable misa bits.
  bool extension_enabled_const(unsigned char ext) const {
    if (ext >= 'A' && ext <= 'Z')
      return state.misa->extension_enabled_const(ext);
    else
      return isa->extension_enabled(ext);  // assume this can't change
  }
  void set_impl(uint8_t impl, bool val) { impl_table[impl] = val; }
  bool supports_impl(uint8_t impl) const {
    return impl_table[impl];
  }
  reg_t pc_alignment_mask() {
    return ~(reg_t)(extension_enabled('C') ? 0 : 2);
  }
  void check_pc_alignment(reg_t pc) {
    if (unlikely(pc & ~pc_alignment_mask()))
      throw trap_instruction_address_misaligned(state.v, pc, 0, 0);
  }
  reg_t legalize_privilege(reg_t);
  void set_privilege(reg_t);
  void set_virt(bool);
  const char* get_privilege_string();
  void update_histogram(reg_t pc);
  const disassembler_t* get_disassembler() { return disassembler; }

  FILE *get_log_file() { return log_file; }

  void register_insn(insn_desc_t);
  void register_extension(extension_t*);

  // MMIO slave interface
  bool load(reg_t addr, size_t len, uint8_t* bytes);
  bool store(reg_t addr, size_t len, const uint8_t* bytes);

  // When true, display disassembly of each instruction that's executed.
  bool debug;
  // When true, take the slow simulation path.
  bool slow_path();
  bool halted() { return state.debug_mode; }
  int trap_illegal = 0;
  int trap_instr = 0;

  //Supervisor-level external interrupts are made pending based on the logical-OR of the software-writable SEIP bit and the signal from the external interrupt controller.
  reg_t mip_seip_ext = 0; //set MIP_SEIP by PLIC
  reg_t mip_seip_sw = 0;  //set MIP_SEIP by software

  enum {
    HR_NONE,    /* Halt request is inactive. */
    HR_REGULAR, /* Regular halt request/debug interrupt. */
    HR_GROUP    /* Halt requested due to halt group. */
  } halt_request;

  void trigger_updated(const std::vector<triggers::trigger_t *> &triggers);

  void set_pmp_num(reg_t pmp_num);
  void set_pmp_granularity(reg_t pmp_granularity);
  void set_mmu_capability(int cap);

  bool inject_instr;
  insn_t instr_to_inject;
  reg_t pc_to_inject;

  const char* get_symbol(uint64_t addr);

  core_type_t core_type;
  reg_t reset_vector;
  bool has_mboot_main_id;
  reg_t mboot_main_id_val;

  bool is_vpu() {return (core_type == VPU || core_type == LAGARTO_KA);};

private:
  const isa_parser_t * const isa;

  simif_t* sim;
  mmu_t* mmu; // main memory is always accessed via the mmu
  std::unordered_map<std::string, extension_t*> custom_extensions;
  disassembler_t* disassembler;
  state_t state;
  uint32_t id;
  unsigned xlen;
  std::string isa_string;
  bool histogram_enabled;
  bool log_commits_enabled;
  FILE *log_file;
  std::ostream sout_; // needed for socket command interface -s, also used for -d and -l, but not for --log
  bool halt_on_reset;
  std::vector<bool> impl_table;

  std::vector<insn_desc_t> instructions;
  std::map<reg_t,uint64_t> pc_histogram;

  static const size_t OPCODE_CACHE_SIZE = 8191;
  insn_desc_t opcode_cache[OPCODE_CACHE_SIZE];

  void take_pending_interrupt() { take_interrupt(state.mip->read() & state.mie->read()); }
  void take_interrupt(reg_t mask); // take first enabled interrupt in mask
  void take_trap(trap_t& t, reg_t epc); // take an exception
  void disasm(insn_t insn); // disassemble and print an instruction
  int paddr_bits();

  void enter_debug_mode(uint8_t cause);

  void debug_output_log(std::stringstream *s); // either output to interactive user or write to log file

  friend class mmu_t;
  friend class clint_t;
  friend class plic_t;
  friend class extension_t;

  void parse_varch_string(const char*);
  void parse_priv_string(const char*);
  void build_opcode_map();
  void register_base_instructions();
  insn_func_t decode_insn(insn_t insn);

  // Track repeated executions for processor_t::disasm()
  uint64_t last_pc, last_bits, executions;
public:
  entropy_source es; // Crypto ISE Entropy source.

  reg_t n_pmp;
  reg_t lg_pmp_granularity;
  reg_t pmp_tor_mask() { return -(reg_t(1) << (lg_pmp_granularity - PMP_SHIFT)); }

  class vectorUnit_t {
    public:
      processor_t* p;
      void *reg_file;
      char reg_referenced[NVPR];
      int setvl_count;
      reg_t vlmax;
      reg_t vlenb;
      csr_t_p vxsat;
      vector_csr_t_p vxrm, vstart, vl, vtype;
      reg_t vma, vta;
      reg_t vsew;
      float vflmul;
      reg_t ELEN, VLEN;
      bool vill;
      bool vstart_alu;
      //[TOCHECK] from KA, missing vsftp = 2, altfp, altfp_fcvt 

      // last_* correspond to the set of * bit(s) in the last executed instruction
      reg_t last_vxsat;

      uint64_t *mem_addr_array;
      uint64_t *mem_data_array;

      // vector element for varies SEW
      template<class T>
        T& elt(reg_t vReg, reg_t n, bool UNUSED is_write = false) {
          assert(vsew != 0);
          assert((VLEN >> 3)/sizeof(T) > 0);
          reg_t elts_per_reg = (VLEN >> 3) / (sizeof(T));
          vReg += n / elts_per_reg;
          n = n % elts_per_reg;
#ifdef WORDS_BIGENDIAN
          // "V" spec 0.7.1 requires lower indices to map to lower significant
          // bits when changing SEW, thus we need to index from the end on BE.
          n ^= elts_per_reg - 1;
#endif
          reg_referenced[vReg] = 1;

#ifdef RISCV_ENABLE_COMMITLOG
          if (is_write)
            p->get_state()->log_reg_write[((vReg) << 4) | 2] = {0, 0};
#endif

          T *regStart = (T*)((char*)reg_file + vReg * (VLEN >> 3));
          return regStart[n];
        }
    public:

      void reset();

      vectorUnit_t():
        p(0),
        reg_file(0),
        mem_addr_array(0),
        mem_data_array(0),
        reg_referenced{0},
        setvl_count(0),
        vlmax(0),
        vlenb(0),
        vxsat(0),
        vxrm(0),
        vstart(0),
        vl(0),
        vtype(0),
        vma(0),
        vta(0),
        vsew(0),
        vflmul(0),
        ELEN(0),
        VLEN(0),
        vill(false),
        vstart_alu(false) {
      }

      ~vectorUnit_t() {
        free(reg_file);
        free(mem_addr_array);
        free(mem_data_array);
        reg_file = 0;
        mem_addr_array = 0;
        mem_data_array = 0;
      }

      reg_t set_vl(int rd, int rs1, reg_t reqVL, reg_t newType);

      reg_t get_vlen() { return VLEN; }
      reg_t get_elen() { return ELEN; }
      reg_t get_slen() { return VLEN; }

      VRM get_vround_mode() {
        return (VRM)(vxrm->read());
      }
  };

  vectorUnit_t VU;
  triggers::module_t TM;
};

#endif
