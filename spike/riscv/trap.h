// See LICENSE for license details.

#ifndef _RISCV_TRAP_H
#define _RISCV_TRAP_H

#include "decode.h"
#include <cstdio>

struct state_t;

class trap_debug_mode
{
  /* Used to enter debug mode, which isn't quite a normal trap. */
};

class trap_t
{
 public:
  trap_t(reg_t which) : which(which) {}
  virtual bool has_gva() { return false; }
  virtual bool has_tval() { return false; }
  virtual reg_t get_tval() { return 0; }
  virtual bool has_tval2() { return false; }
  virtual reg_t get_tval2() { return 0; }
  virtual bool has_tinst() { return false; }
  virtual reg_t get_tinst() { return 0; }
  reg_t cause() { return which; }

  virtual const char* name()
  {
    const char* fmt = uint8_t(which) == which ? "trap #%u" : "interrupt #%u";
    sprintf(_name, fmt, uint8_t(which));
    return _name;
  }

  virtual ~trap_t() = default;

 private:
  char _name[16];
  reg_t which;
};

class insn_trap_t : public trap_t
{
 public:
  insn_trap_t(reg_t which, bool gva, reg_t tval)
    : trap_t(which), gva(gva), tval(tval) {}
  bool has_gva() override { return gva; }
  bool has_tval() override { return true; }
  reg_t get_tval() override { return tval; }
 private:
  bool gva;
  reg_t tval;
};

class mem_trap_t : public trap_t
{
 public:
  mem_trap_t(reg_t which, bool gva, reg_t tval, reg_t tval2, reg_t tinst, int tval_type = 0)
    : trap_t(which), gva(gva), tval(tval), tval2(tval2), tinst(tinst), tval_type(tval_type) {}
  bool has_gva() override { return gva; }
  bool has_tval() override { return true; }
  reg_t get_tval() override { 
  reg_t cache_line_addr_mask = 0xFFFFFFFFFFFFFFFFUL;
    fprintf(stderr, "mem_trap: addr %lx mask %lx\n", tval, (cache_line_addr_mask <<  tval_type));
    return tval & (cache_line_addr_mask <<  tval_type);
  }
  bool has_tval2() override { return true; }
  reg_t get_tval2() override { return tval2; }
  bool has_tinst() override { return true; }
  reg_t get_tinst() override { return tinst; }
 private:
  bool gva;
  reg_t tval, tval2, tinst;
  int tval_type;
};

#define DECLARE_TRAP(n, x) class trap_##x : public trap_t { \
 public: \
  trap_##x() : trap_t(n) {} \
  const char* name() { return "trap_"#x; } \
};

#define DECLARE_INST_TRAP(n, x) class trap_##x : public insn_trap_t { \
 public: \
  trap_##x(reg_t tval) : insn_trap_t(n, /*gva*/false, tval) {} \
  const char* name() { return "trap_"#x; } \
};

#define DECLARE_INST_WITH_GVA_TRAP(n, x) class trap_##x : public insn_trap_t {  \
 public: \
  trap_##x(bool gva, reg_t tval) : insn_trap_t(n, gva, tval) {} \
  const char* name() { return "trap_"#x; } \
};

#define DECLARE_MEM_TRAP(n, x) class trap_##x : public mem_trap_t { \
 public: \
  trap_##x(bool gva, reg_t tval, reg_t tval2, reg_t tinst, int tval_type = 0) : mem_trap_t(n, gva, tval, tval2, tinst, tval_type) {} \
  const char* name() { return "trap_"#x; } \
};

#define DECLARE_MEM_GVA_TRAP(n, x) class trap_##x : public mem_trap_t { \
 public: \
  trap_##x(reg_t tval, reg_t tval2, reg_t tinst, int tval_type = 0) : mem_trap_t(n, true, tval, tval2, tinst, tval_type) {} \
  const char* name() { return "trap_"#x; } \
};

DECLARE_MEM_TRAP(CAUSE_MISALIGNED_FETCH, instruction_address_misaligned)
DECLARE_MEM_TRAP(CAUSE_FETCH_ACCESS, instruction_access_fault)
DECLARE_INST_TRAP(CAUSE_ILLEGAL_INSTRUCTION, illegal_instruction)
DECLARE_INST_WITH_GVA_TRAP(CAUSE_BREAKPOINT, breakpoint)
DECLARE_MEM_TRAP(CAUSE_MISALIGNED_LOAD, load_address_misaligned)
DECLARE_MEM_TRAP(CAUSE_MISALIGNED_STORE, store_address_misaligned)
DECLARE_MEM_TRAP(CAUSE_LOAD_ACCESS, load_access_fault)
DECLARE_MEM_TRAP(CAUSE_STORE_ACCESS, store_access_fault)
DECLARE_TRAP(CAUSE_USER_ECALL, user_ecall)
DECLARE_TRAP(CAUSE_SUPERVISOR_ECALL, supervisor_ecall)
DECLARE_TRAP(CAUSE_VIRTUAL_SUPERVISOR_ECALL, virtual_supervisor_ecall)
DECLARE_TRAP(CAUSE_MACHINE_ECALL, machine_ecall)
DECLARE_MEM_TRAP(CAUSE_FETCH_PAGE_FAULT, instruction_page_fault)
DECLARE_MEM_TRAP(CAUSE_LOAD_PAGE_FAULT, load_page_fault)
DECLARE_MEM_TRAP(CAUSE_STORE_PAGE_FAULT, store_page_fault)
DECLARE_MEM_GVA_TRAP(CAUSE_FETCH_GUEST_PAGE_FAULT, instruction_guest_page_fault)
DECLARE_MEM_GVA_TRAP(CAUSE_LOAD_GUEST_PAGE_FAULT, load_guest_page_fault)
DECLARE_INST_TRAP(CAUSE_VIRTUAL_INSTRUCTION, virtual_instruction)
DECLARE_MEM_GVA_TRAP(CAUSE_STORE_GUEST_PAGE_FAULT, store_guest_page_fault)

#endif
