// See LICENSE for license details.

#include "mmu.h"
#include "arith.h"
#include "simif.h"
#include "processor.h"

mmu_t::mmu_t(simif_t* sim, memif_endianness_t endianness, processor_t* proc)
 : sim(sim), proc(proc),
#ifdef RISCV_ENABLE_DUAL_ENDIAN
  target_big_endian(endianness == memif_endianness_big),
#endif
  check_triggers_fetch(false),
  check_triggers_load(false),
  check_triggers_store(false),
  matched_trigger(NULL)
{
#ifndef RISCV_ENABLE_DUAL_ENDIAN
  assert(endianness == memif_endianness_little);
#endif
  flush_tlb();
  yield_load_reservation();
}

mmu_t::~mmu_t()
{
}

void mmu_t::flush_icache()
{
  for (size_t i = 0; i < ICACHE_ENTRIES; i++)
    icache[i].tag = -1;
}

void mmu_t::flush_tlb()
{
  memset(tlb_insn_tag, -1, sizeof(tlb_insn_tag));
  memset(tlb_load_tag, -1, sizeof(tlb_load_tag));
  memset(tlb_store_tag, -1, sizeof(tlb_store_tag));

  flush_icache();
}

static void throw_access_exception(bool virt, reg_t addr, access_type type, int tval_type = 0)
{

  switch (type) {
    case FETCH: throw trap_instruction_access_fault(virt, addr, 0, 0, tval_type);
    case LOAD: throw trap_load_access_fault(virt, addr, 0, 0, tval_type);
    case STORE: throw trap_store_access_fault(virt, addr, 0, 0, tval_type);
    default: abort();
  }
}

reg_t mmu_t::translate(reg_t addr, reg_t len, access_type type, uint32_t xlate_flags, int tval_type)
{
  if (!proc)
    return addr;

  bool virt = proc->state.v;
  bool hlvx = xlate_flags & RISCV_XLATE_VIRT_HLVX;
  reg_t mode = proc->state.prv;
  if (type != FETCH) {
    if (!proc->state.debug_mode && get_field(proc->state.mstatus->read(), MSTATUS_MPRV)) {
      mode = get_field(proc->state.mstatus->read(), MSTATUS_MPP);
      if (get_field(proc->state.mstatus->read(), MSTATUS_MPV) && mode != PRV_M)
        virt = true;
    }
    if (xlate_flags & RISCV_XLATE_VIRT) {
      virt = true;
      mode = get_field(proc->state.hstatus->read(), HSTATUS_SPVP);
    }
  }

  reg_t paddr = walk(addr, type, mode, virt, hlvx, tval_type) | (addr & (PGSIZE-1));
  if (!pmp_ok(paddr, len, type, mode))
    throw_access_exception(virt, addr, type, tval_type);
  return paddr;
}

reg_t mmu_t::tlb_translate(reg_t addr, reg_t len, access_type type, reg_t satp, reg_t priv_lvl, reg_t mstatus, reg_t* exc_error)
{
  *exc_error = 0;
  if (!proc)
    return addr;
  bool virt = proc->state.v;
  bool hlvx = 0;//xlate_flags & RISCV_XLATE_VIRT_HLVX; //xlate_flags are 0 when translate is called
  //reg_t mode = proc->state.prv;//out of sync with rtl privilege level, maybe pass RTL privilege level then.
  reg_t mode = priv_lvl;

  if (type != FETCH) {
    //mstatus can come from proc->state.mstatus->read() //out of sync with rtl privilege level, maybe pass RTL privilege level then.
    if (!proc->state.debug_mode && get_field(mstatus, MSTATUS_MPRV))
      mode = get_field(mstatus, MSTATUS_MPP);
    if (get_field(mstatus, MSTATUS_MPV) && mode != PRV_M)
        virt = true;
    //if (xlate_flags & RISCV_XLATE_VIRT) {
    //  virt = true;
      //mode = get_field(proc->state.hstatus->read(), HSTATUS_SPVP); //[TOCHECK] from KA, should we get hstatus also as argument?
    //}
  }


  reg_t paddr = tlb_walk(addr, type, satp, priv_lvl, mstatus, exc_error);

  paddr = paddr | (addr & (PGSIZE-1));
  if (!pmp_ok(paddr, len, type, mode)){
      // throw_access_exception(addr, type);
      *exc_error = 1;
      }
    // fprintf(stdout, "TLB Translate vaddr = 0x%016" PRIx64 " and paddr = 0x%016" PRIx64 " .. \n", addr, paddr);
  return paddr;
}

// BSC implemented
reg_t mmu_t::sneaky_translate(reg_t addr, reg_t len, access_type type)
{
  if (!proc){
    return addr;
  }

  reg_t mode = proc->state.prv;//utilizar modo del RTL en vez del de spike
  //how about the ASID address space ID?
  if (type != FETCH) {
    if (!proc->state.debug_mode && get_field(proc->state.mstatus->read(), MSTATUS_MPRV))
      mode = get_field(proc->state.mstatus->read(), MSTATUS_MPP);
  }

  reg_t paddr = sneaky_walk(addr, type, mode) | (addr & (PGSIZE-1));
  return paddr;
}


tlb_entry_t mmu_t::fetch_slow_path(reg_t vaddr)
{
  check_triggers(triggers::OPERATION_EXECUTE, vaddr);

  tlb_entry_t result;
  reg_t vpn = vaddr >> PGSHIFT;
  if (unlikely(tlb_insn_tag[vpn % TLB_ENTRIES] != (vpn | TLB_CHECK_TRIGGERS)) || DISABLE_PGSIZE_CHECK) {
    reg_t paddr = translate(vaddr, sizeof(fetch_temp), FETCH, 0);
    if (auto host_addr = sim->addr_to_mem(paddr)) {
      result = refill_tlb(vaddr, paddr, host_addr, FETCH);
    } else {
      if (!mmio_load(paddr, sizeof fetch_temp, (uint8_t*)&fetch_temp))
        throw trap_instruction_access_fault(proc->state.v, vaddr, 0, 0);
      result = {(char*)&fetch_temp - vaddr, paddr - vaddr};
    }
  } else {
    result = tlb_data[vpn % TLB_ENTRIES];
  }

  check_triggers(triggers::OPERATION_EXECUTE, vaddr, from_le(*(const uint16_t*)(result.host_offset + vaddr)));

  return result;
}

reg_t reg_from_bytes(size_t len, const uint8_t* bytes)
{
  switch (len) {
    case 1:
      return bytes[0];
    case 2:
      return bytes[0] |
        (((reg_t) bytes[1]) << 8);
    case 4:
      return bytes[0] |
        (((reg_t) bytes[1]) << 8) |
        (((reg_t) bytes[2]) << 16) |
        (((reg_t) bytes[3]) << 24);
    case 8:
      return bytes[0] |
        (((reg_t) bytes[1]) << 8) |
        (((reg_t) bytes[2]) << 16) |
        (((reg_t) bytes[3]) << 24) |
        (((reg_t) bytes[4]) << 32) |
        (((reg_t) bytes[5]) << 40) |
        (((reg_t) bytes[6]) << 48) |
        (((reg_t) bytes[7]) << 56);
  }
  abort();
}

bool mmu_t::mmio_ok(reg_t addr, access_type UNUSED type)
{
  // Disallow access to debug region when not in debug mode
  if (addr >= DEBUG_START && addr <= DEBUG_END && proc && !proc->state.debug_mode && (proc->core_type == STANDARD))
    return false;

  return true;
}

bool mmu_t::mmio_load(reg_t addr, size_t len, uint8_t* bytes)
{
  if (!mmio_ok(addr, LOAD))
    return false;

  return sim->mmio_load(addr, len, bytes);
}

bool mmu_t::mmio_store(reg_t addr, size_t len, const uint8_t* bytes)
{
  if (!mmio_ok(addr, STORE))
    return false;

  return sim->mmio_store(addr, len, bytes);
}

void mmu_t::sneaky_store(reg_t addr, reg_t len, const uint8_t* bytes)
{
  reg_t paddr = sneaky_translate(addr, len, STORE);

  if (!matched_trigger) {
    reg_t data = reg_from_bytes(len, bytes);
    /*matched_trigger =*/ throw_access_exception(0, addr,STORE); //trigger_exception(triggers:OPERATION_STORE, addr, data);
    //if (matched_trigger)
      //throw *matched_trigger;
  }

  if (auto host_addr = sim->addr_to_mem(paddr)) {
    memcpy(host_addr, bytes, len);
    if (tracer.interested_in_range(paddr, paddr + PGSIZE, STORE))
      tracer.trace(paddr, len, STORE);
    else
      refill_tlb(addr, paddr, host_addr, STORE);
  } else if (!mmio_store(paddr, len, bytes)) {
    throw trap_store_access_fault(0, addr, 0, 0);
  }
}


void mmu_t::check_triggers(triggers::operation_t operation, reg_t address, std::optional<reg_t> data)
{
  if (matched_trigger || !proc)
    return;

  triggers::action_t action;
  auto match = proc->TM.memory_access_match(&action, operation, address, data);

  switch (match) {
    case triggers::MATCH_NONE:
      return;

    case triggers::MATCH_FIRE_BEFORE:
      throw triggers::matched_t(operation, address, action);

    case triggers::MATCH_FIRE_AFTER:
      // We want to take this exception on the next instruction.  We check
      // whether to do so in the I$ refill path, so flush the I$.
      flush_icache();
      matched_trigger = new triggers::matched_t(operation, address, action);
      return;
  }
}

void mmu_t::load_slow_path_intrapage(reg_t addr, reg_t len, uint8_t* bytes, uint32_t xlate_flags, int tval_type)
{
  reg_t vpn = addr >> PGSHIFT;
  if (xlate_flags == 0 && vpn == (tlb_load_tag[vpn % TLB_ENTRIES] & ~TLB_CHECK_TRIGGERS) && !DISABLE_PGSIZE_CHECK) {
    auto host_addr = tlb_data[vpn % TLB_ENTRIES].host_offset + addr;
    memcpy(bytes, host_addr, len);
    return;
  }

  reg_t paddr = translate(addr, len, LOAD, xlate_flags, tval_type);

  if (auto host_addr = sim->addr_to_mem(paddr)) {
    memcpy(bytes, host_addr, len);
    if (tracer.interested_in_range(paddr, paddr + PGSIZE, LOAD))
      tracer.trace(paddr, len, LOAD);
    else if (xlate_flags == 0)
      refill_tlb(addr, paddr, host_addr, LOAD);

    if (xlate_flags & RISCV_XLATE_LR) {
      load_reservation_address = paddr;
    }
  } else if ((xlate_flags & RISCV_XLATE_LR) || !mmio_load(paddr, len, bytes)) {
    throw trap_load_access_fault((proc) ? proc->state.v : false, addr, 0, 0, tval_type);
  }
}

void mmu_t::load_slow_path(reg_t addr, reg_t len, uint8_t* bytes, uint32_t xlate_flags, int tval_type)
{
  check_triggers(triggers::OPERATION_LOAD, addr);

  if ((addr & (len - 1)) == 0) {
    load_slow_path_intrapage(addr, len, bytes, xlate_flags, tval_type);
  } else {
    bool gva = ((proc) ? proc->state.v : false) || (RISCV_XLATE_VIRT & xlate_flags);
#ifndef RISCV_ENABLE_MISALIGNED
    throw trap_load_address_misaligned(gva, addr, 0, 0, tval_type);
#else
    if (xlate_flags & RISCV_XLATE_LR)
      throw trap_load_access_fault(gva, addr, 0, 0, tval_type);

    reg_t len_page0 = std::min(len, PGSIZE - addr % PGSIZE);
    load_slow_path_intrapage(addr, len_page0, bytes, xlate_flags, tval_type);
    if (len_page0 != len)
      load_slow_path_intrapage(addr + len_page0, len - len_page0, bytes + len_page0, xlate_flags, tval_type);
#endif
  }

  check_triggers(triggers::OPERATION_LOAD, addr, reg_from_bytes(len, bytes));
}

void mmu_t::store_slow_path_intrapage(reg_t addr, reg_t len, const uint8_t* bytes, uint32_t xlate_flags, bool actually_store, int tval_type)
{
  reg_t vpn = addr >> PGSHIFT;
  if (xlate_flags == 0 && vpn == (tlb_store_tag[vpn % TLB_ENTRIES] & ~TLB_CHECK_TRIGGERS) && !DISABLE_PGSIZE_CHECK) {
    if (actually_store) {
      auto host_addr = tlb_data[vpn % TLB_ENTRIES].host_offset + addr;
      memcpy(host_addr, bytes, len);
    }
    return;
  }

  reg_t paddr = translate(addr, len, STORE, xlate_flags, tval_type);

  if (actually_store) {
    if (auto host_addr = sim->addr_to_mem(paddr)) {
      memcpy(host_addr, bytes, len);
      if (tracer.interested_in_range(paddr, paddr + PGSIZE, STORE))
        tracer.trace(paddr, len, STORE);
      else if (xlate_flags == 0)
        refill_tlb(addr, paddr, host_addr, STORE);
    } else if (!mmio_store(paddr, len, bytes)) {
      throw trap_store_access_fault((proc) ? proc->state.v : false, addr, 0, 0, tval_type);
    }
  }
}

void mmu_t::store_slow_path(reg_t addr, reg_t len, const uint8_t* bytes, uint32_t xlate_flags, bool actually_store, bool UNUSED require_alignment, int tval_type)
{
  if (actually_store)
    check_triggers(triggers::OPERATION_STORE, addr, reg_from_bytes(len, bytes));

  if (addr & (len - 1)) {
    bool gva = ((proc) ? proc->state.v : false) || (RISCV_XLATE_VIRT & xlate_flags);
#ifndef RISCV_ENABLE_MISALIGNED
    throw trap_store_address_misaligned(gva, addr, 0, 0, tval_type);
#else
    if (require_alignment)
      throw trap_store_access_fault(gva, addr, 0, 0, tval_type);

    reg_t len_page0 = std::min(len, PGSIZE - addr % PGSIZE);
    store_slow_path_intrapage(addr, len_page0, bytes, xlate_flags, actually_store, tval_type);
    if (len_page0 != len)
      store_slow_path_intrapage(addr + len_page0, len - len_page0, bytes + len_page0, xlate_flags, actually_store, tval_type);
#endif
  } else {
    store_slow_path_intrapage(addr, len, bytes, xlate_flags, actually_store, tval_type);
  }
}

tlb_entry_t mmu_t::refill_tlb(reg_t vaddr, reg_t paddr, char* host_addr, access_type type)
{
  reg_t idx = (vaddr >> PGSHIFT) % TLB_ENTRIES;
  reg_t expected_tag = vaddr >> PGSHIFT;

  tlb_entry_t entry = {host_addr - vaddr, paddr - vaddr};

  if (proc && get_field(proc->state.mstatus->read(), MSTATUS_MPRV))
    return entry;

  if (DISABLE_PGSIZE_CHECK) return entry;

  if ((tlb_load_tag[idx] & ~TLB_CHECK_TRIGGERS) != expected_tag)
    tlb_load_tag[idx] = -1;
  if ((tlb_store_tag[idx] & ~TLB_CHECK_TRIGGERS) != expected_tag)
    tlb_store_tag[idx] = -1;
  if ((tlb_insn_tag[idx] & ~TLB_CHECK_TRIGGERS) != expected_tag)
    tlb_insn_tag[idx] = -1;

  if ((check_triggers_fetch && type == FETCH) ||
      (check_triggers_load && type == LOAD) ||
      (check_triggers_store && type == STORE))
    expected_tag |= TLB_CHECK_TRIGGERS;

  if (pmp_homogeneous(paddr & ~reg_t(PGSIZE - 1), PGSIZE)) {
    if (type == FETCH) tlb_insn_tag[idx] = expected_tag;
    else if (type == STORE) tlb_store_tag[idx] = expected_tag;
    else tlb_load_tag[idx] = expected_tag;
  }

  tlb_data[idx] = entry;
  return entry;
}

bool mmu_t::pmp_ok(reg_t addr, reg_t len, access_type type, reg_t mode)
{
  if (!proc || proc->n_pmp == 0)
    return true;

  for (size_t i = 0; i < proc->n_pmp; i++) {
    // Check each 4-byte sector of the access
    bool any_match = false;
    bool all_match = true;
    for (reg_t offset = 0; offset < len; offset += 1 << PMP_SHIFT) {
      reg_t cur_addr = addr + offset;
      bool match = proc->state.pmpaddr[i]->match4(cur_addr);
      any_match |= match;
      all_match &= match;
    }

    if (any_match) {
      // If the PMP matches only a strict subset of the access, fail it
      if (!all_match)
        return false;

      return proc->state.pmpaddr[i]->access_ok(type, mode);
    }
  }

  // in case matching region is not found
  const bool mseccfg_mml = proc->state.mseccfg->get_mml();
  const bool mseccfg_mmwp = proc->state.mseccfg->get_mmwp();
  return ((mode == PRV_M) && !mseccfg_mmwp
          && (!mseccfg_mml || ((type == LOAD) || (type == STORE))));
}

reg_t mmu_t::pmp_homogeneous(reg_t addr, reg_t len)
{
  if ((addr | len) & (len - 1))
    abort();

  if (!proc)
    return true;

  for (size_t i = 0; i < proc->n_pmp; i++)
    if (proc->state.pmpaddr[i]->subset_match(addr, len))
      return false;

  return true;
}

reg_t mmu_t::sneaky_walk(reg_t addr, access_type type, reg_t mode)
{
  vm_info vm = decode_vm_info(proc->get_const_xlen(), false, mode, proc->get_state()->satp->read());
  if (vm.levels == 0)
    return addr & ((reg_t(2) << (proc->xlen-1))-1); // zero-extend from xlen

  bool s_mode = mode == PRV_S;
  bool sum = get_field(proc->state.mstatus->read(), MSTATUS_SUM);
  bool mxr = get_field(proc->state.mstatus->read(), MSTATUS_MXR);

  // verify bits xlen-1:va_bits-1 are all equal
  int va_bits = PGSHIFT + vm.levels * vm.idxbits;
  reg_t mask = (reg_t(1) << (proc->xlen - (va_bits-1))) - 1;
  reg_t masked_msbs = (addr >> (va_bits-1)) & mask;
  if (masked_msbs != 0 && masked_msbs != mask)
    vm.levels = 0;

  reg_t base = vm.ptbase;
  for (int i = vm.levels - 1; i >= 0; i--) {
    int ptshift = i * vm.idxbits;
    reg_t idx = (addr >> (PGSHIFT + ptshift)) & ((1 << vm.idxbits) - 1);

    // check that physical address of PTE is legal
    auto pte_paddr = base + idx * vm.ptesize;
    auto ppte = sim->addr_to_mem(pte_paddr);

    if ((proc->core_type == STANDARD && !ppte) || !pmp_ok(pte_paddr, vm.ptesize, LOAD, PRV_S))
      throw_access_exception(0, addr, type);
    else if (!ppte) break;

    reg_t pte = vm.ptesize == 4 ? from_le(*(uint32_t*)ppte) : from_le(*(uint64_t*)ppte);
    reg_t ppn = pte >> PTE_PPN_SHIFT;

    if (PTE_TABLE(pte)) { // next level of page table
      base = ppn << PGSHIFT;
    } else if ((pte & PTE_U) ? s_mode && (type == FETCH || !sum) : !s_mode) {
      break;
    } else if (!(pte & PTE_V) || (!(pte & PTE_R) && (pte & PTE_W))) {
      break;
    } else if (type == FETCH ? !(pte & PTE_X) :
               type == LOAD ?  !(pte & PTE_R) && !(mxr && (pte & PTE_X)) :
                               !((pte & PTE_R) && (pte & PTE_W))) {
      break;
    } else if ((ppn & ((reg_t(1) << ptshift) - 1)) != 0) {
      break;
    } else {
      reg_t ad = PTE_A | ((type == STORE) * PTE_D);
      #ifdef RISCV_ENABLE_DIRTY
        // set accessed and possibly dirty bits.
        if ((pte & ad) != ad) {
          if (!pmp_ok(pte_paddr, vm.ptesize, STORE, PRV_S))
            throw_access_exception(0, addr, type);
          *(uint32_t*)ppte |= to_le((uint32_t)ad);
        }
      #else
        // take exception if access or possibly dirty bit is not set.
        if ((pte & ad) != ad)
          break;
      #   endif
      // for superpage mappings, make a fake leaf PTE for the TLB's benefit.


    reg_t vpn = addr >> PGSHIFT;
    reg_t value = (ppn | (vpn & ((reg_t(1) << ptshift) - 1))) << PGSHIFT;
    return value;
    }
   }
}

reg_t mmu_t::s2xlate(reg_t gva, reg_t gpa, access_type type, access_type trap_type, bool virt, bool hlvx, int tval_type)
{
  if (!virt)
    return gpa;

  vm_info vm = decode_vm_info(proc->get_const_xlen(), true, 0, proc->get_state()->hgatp->read());
  if (vm.levels == 0)
    return gpa;

  int maxgpabits = vm.levels * vm.idxbits + vm.widenbits + PGSHIFT;
  reg_t maxgpa = (1ULL << maxgpabits) - 1;

  bool mxr = proc->state.sstatus->readvirt(false) & MSTATUS_MXR;

  reg_t base = vm.ptbase;
  if ((gpa & ~maxgpa) == 0) {
    for (int i = vm.levels - 1; i >= 0; i--) {
      int ptshift = i * vm.idxbits;
      int idxbits = (i == (vm.levels - 1)) ? vm.idxbits + vm.widenbits : vm.idxbits;
      reg_t idx = (gpa >> (PGSHIFT + ptshift)) & ((reg_t(1) << idxbits) - 1);

      // check that physical address of PTE is legal
      auto pte_paddr = base + idx * vm.ptesize;
      auto ppte = sim->addr_to_mem(pte_paddr);
      if ((proc->core_type == STANDARD && !ppte) || !pmp_ok(pte_paddr, vm.ptesize, LOAD, PRV_S)) {
        throw_access_exception(virt, gva, trap_type, tval_type);
      }
      else if (!ppte) break;

      reg_t pte = vm.ptesize == 4 ? from_target(*(target_endian<uint32_t>*)ppte) : from_target(*(target_endian<uint64_t>*)ppte);
      reg_t ppn = (pte & ~reg_t(PTE_ATTR)) >> PTE_PPN_SHIFT;
      bool pbmte = proc->get_state()->menvcfg->read() & MENVCFG_PBMTE;

      if (pte & PTE_RSVD) {
        break;
      } else if (!proc->extension_enabled(EXT_SVNAPOT) && (pte & PTE_N)) {
        break;
      } else if (!pbmte && (pte & PTE_PBMT)) {
        break;
      } else if ((pte & PTE_PBMT) == PTE_PBMT) {
        break;
      } else if (PTE_TABLE(pte)) { // next level of page table
        if (pte & (PTE_D | PTE_A | PTE_U | PTE_N | PTE_PBMT))
          break;
        base = ppn << PGSHIFT;
      } else if (!(pte & PTE_V) || (!(pte & PTE_R) && (pte & PTE_W))) {
        break;
      } else if (!(pte & PTE_U)) {
        break;
      } else if (type == FETCH || hlvx ? !(pte & PTE_X) :
                 type == LOAD          ? !(pte & PTE_R) && !(mxr && (pte & PTE_X)) :
                                         !((pte & PTE_R) && (pte & PTE_W))) {
        break;
      } else if ((ppn & ((reg_t(1) << ptshift) - 1)) != 0) {
        break;
      } else {
        reg_t ad = PTE_A | ((type == STORE) * PTE_D);
#ifdef RISCV_ENABLE_DIRTY
        // set accessed and possibly dirty bits.
        if ((pte & ad) != ad) {
          if (!pmp_ok(pte_paddr, vm.ptesize, STORE, PRV_S))
            throw_access_exception(virt, gva, trap_type, tval_type);
          *(target_endian<uint32_t>*)ppte |= to_target((uint32_t)ad);
        }
#else
        // take exception if access or possibly dirty bit is not set.
        if ((pte & ad) != ad)
          break;
#endif
        reg_t vpn = gpa >> PGSHIFT;
        reg_t page_mask = (reg_t(1) << PGSHIFT) - 1;

        int napot_bits = ((pte & PTE_N) ? (ctz(ppn) + 1) : 0);
        if (((pte & PTE_N) && (ppn == 0 || i != 0)) || (napot_bits != 0 && napot_bits != 4))
          break;

        reg_t page_base = ((ppn & ~((reg_t(1) << napot_bits) - 1))
                          | (vpn & ((reg_t(1) << napot_bits) - 1))
                          | (vpn & ((reg_t(1) << ptshift) - 1))) << PGSHIFT;
        return page_base | (gpa & page_mask);
      }
    }
  }

  switch (trap_type) {
    case FETCH: throw trap_instruction_guest_page_fault(gva, gpa >> 2, 0, tval_type);
    case LOAD: throw trap_load_guest_page_fault(gva, gpa >> 2, 0, tval_type);
    case STORE: throw trap_store_guest_page_fault(gva, gpa >> 2, 0, tval_type);
    default: abort();
  }
}

reg_t mmu_t::walk(reg_t addr, access_type type, reg_t mode, bool virt, bool hlvx, int tval_type)
{
  reg_t page_mask = (reg_t(1) << PGSHIFT) - 1;
  reg_t satp = proc->get_state()->satp->readvirt(virt);
  vm_info vm = decode_vm_info(proc->get_const_xlen(), false, mode, satp);
  if (vm.levels == 0)
    return s2xlate(addr, addr & ((reg_t(2) << (proc->xlen-1))-1), type, type, virt, hlvx) & ~page_mask; // zero-extend from xlen

  bool s_mode = mode == PRV_S;
  bool sum = proc->state.sstatus->readvirt(virt) & MSTATUS_SUM;
  bool mxr = (proc->state.sstatus->readvirt(false) | proc->state.sstatus->readvirt(virt)) & MSTATUS_MXR;

  // verify bits xlen-1:va_bits-1 are all equal
  int va_bits = PGSHIFT + vm.levels * vm.idxbits;
  reg_t mask = (reg_t(1) << (proc->xlen - (va_bits-1))) - 1;
  reg_t masked_msbs = (addr >> (va_bits-1)) & mask;
  if (masked_msbs != 0 && masked_msbs != mask)
    vm.levels = 0;

  reg_t base = vm.ptbase;
  for (int i = vm.levels - 1; i >= 0; i--) {
    int ptshift = i * vm.idxbits;
    reg_t idx = (addr >> (PGSHIFT + ptshift)) & ((1 << vm.idxbits) - 1);

    // check that physical address of PTE is legal
    auto pte_paddr = s2xlate(addr, base + idx * vm.ptesize, LOAD, type, virt, false, tval_type);
    auto ppte = sim->addr_to_mem(pte_paddr);
    if ((proc->core_type == STANDARD && !ppte) || !pmp_ok(pte_paddr, vm.ptesize, LOAD, PRV_S))
      throw_access_exception(virt, addr, type, tval_type);
    else if (!ppte) break;

    reg_t pte = vm.ptesize == 4 ? from_target(*(target_endian<uint32_t>*)ppte) : from_target(*(target_endian<uint64_t>*)ppte);
    reg_t ppn = (pte & ~reg_t(PTE_ATTR)) >> PTE_PPN_SHIFT;
    bool pbmte = virt ? (proc->get_state()->henvcfg->read() & HENVCFG_PBMTE) : (proc->get_state()->menvcfg->read() & MENVCFG_PBMTE);

    if (pte & PTE_RSVD) {
      break;
    } else if (!proc->extension_enabled(EXT_SVNAPOT) && (pte & PTE_N)) {
      break;
    } else if (!pbmte && (pte & PTE_PBMT)) {
      break;
    } else if ((pte & PTE_PBMT) == PTE_PBMT) {
      break;
    } else if (PTE_TABLE(pte)) { // next level of page table
      if (pte & (PTE_D | PTE_A | PTE_U | PTE_N | PTE_PBMT))
        break;
      base = ppn << PGSHIFT;
    } else if ((pte & PTE_U) ? s_mode && (type == FETCH || !sum) : !s_mode) {
      break;
    } else if (!(pte & PTE_V) || (!(pte & PTE_R) && (pte & PTE_W))) {
      break;
    } else if (type == FETCH || hlvx ? !(pte & PTE_X) :
               type == LOAD          ? !(pte & PTE_R) && !(mxr && (pte & PTE_X)) :
                                       !((pte & PTE_R) && (pte & PTE_W))) {
      break;
    } else if ((ppn & ((reg_t(1) << ptshift) - 1)) != 0) {
      break;
    } else {
      reg_t ad = PTE_A | ((type == STORE) * PTE_D);
#ifdef RISCV_ENABLE_DIRTY
      // set accessed and possibly dirty bits.
      if ((pte & ad) != ad) {
        if (!pmp_ok(pte_paddr, vm.ptesize, STORE, PRV_S))
          throw_access_exception(virt, addr, type, tval_type);
        *(target_endian<uint32_t>*)ppte |= to_target((uint32_t)ad);
      }
#else
      // take exception if access or possibly dirty bit is not set.
      if ((pte & ad) != ad)
        break;
#endif
      // for superpage or Svnapot NAPOT mappings, make a fake leaf PTE for the TLB's benefit.
      reg_t vpn = addr >> PGSHIFT;

      int napot_bits = ((pte & PTE_N) ? (ctz(ppn) + 1) : 0);
      if (((pte & PTE_N) && (ppn == 0 || i != 0)) || (napot_bits != 0 && napot_bits != 4))
        break;

      reg_t page_base = ((ppn & ~((reg_t(1) << napot_bits) - 1))
                        | (vpn & ((reg_t(1) << napot_bits) - 1))
                        | (vpn & ((reg_t(1) << ptshift) - 1))) << PGSHIFT;
      reg_t phys = page_base | (addr & page_mask);
      return s2xlate(addr, phys, type, type, virt, hlvx, tval_type) & ~page_mask;
    }
  }

  switch (type) {
    case FETCH: throw trap_instruction_page_fault(virt, addr, 0, 0, tval_type);
    case LOAD: throw trap_load_page_fault(virt, addr, 0, 0, tval_type);
    case STORE: throw trap_store_page_fault(virt, addr, 0, 0, tval_type);
    default: abort();
  }
}

//Spike TBL Walk
reg_t mmu_t::tlb_walk(reg_t addr, access_type type, reg_t satp, reg_t mode, reg_t mstatus, reg_t* exc_error)
{
  // fprintf(stdout,"--------------------------\n");
  // fprintf(stdout, "TLB walk with address: %0x\n", addr);
  *exc_error = 0;
  reg_t page_mask = (reg_t(1) << PGSHIFT) - 1;
  vm_info vm = decode_vm_info(proc->get_const_xlen(), false, mode, satp); //[TOCHECK] changed from lagarto to new implementation
  // fprintf(stdout, "Privilege mode: %0x - vm.levels: %0x - mstatus: 0x%0x\n", mode, vm.levels, mstatus);
  if (vm.levels == 0){
    return s2xlate(addr, addr & ((reg_t(2) << (proc->xlen-1))-1), type, type, 0, 0) & ~page_mask; // zero-extend from xlen
    //return  addr_res;// zero-extend from xlen
  }

  bool s_mode = mode == PRV_S;
  bool sum = get_field(mstatus, MSTATUS_SUM);
  bool mxr = get_field(mstatus, MSTATUS_MXR);
  // fprintf(stdout, "s_mode: %0x - sum: %0x - mxr: %0x\n", s_mode, sum, mxr);

  // verify bits xlen-1:va_bits-1 are all equal
  int va_bits = PGSHIFT + vm.levels * vm.idxbits;
  reg_t mask = (reg_t(1) << (proc->xlen - (va_bits-1))) - 1;
  reg_t masked_msbs = (addr >> (va_bits-1)) & mask;
  //if (masked_msbs != 0 && masked_msbs != mask){
  //  vm.levels = 0;
  //  std::cout<<"VM LEVELS 0"<<std::endl;
  //}

  reg_t base = vm.ptbase;
  for (int i = vm.levels - 1; i >= 0; i--) {
    int ptshift = i * vm.idxbits;
    reg_t idx = (addr >> (PGSHIFT + ptshift)) & ((1 << vm.idxbits) - 1);

    // check that physical address of PTE is legal
    auto pte_paddr = s2xlate(addr, base + idx * vm.ptesize, LOAD, type, 0, false);
    auto ppte = sim->addr_to_mem(pte_paddr);
    if ((proc->core_type == STANDARD && !ppte) || !pmp_ok(pte_paddr, vm.ptesize, LOAD, PRV_S)){
      // throw_access_exception(addr, type);
      *exc_error = 4;
      }
    else if (!ppte) break;

    reg_t pte = vm.ptesize == 4 ? from_target(*(target_endian<uint32_t>*)ppte) : from_target(*(target_endian<uint64_t>*)ppte);
    reg_t ppn = pte >> PTE_PPN_SHIFT;
    bool pbmte = /*virt ? (proc->get_state()->henvcfg->read() & HENVCFG_PBMTE) :*/ (proc->get_state()->menvcfg->read() & MENVCFG_PBMTE);
    // fprintf(stdout, "pte: %x - ppte: %x - pte_paddr: %x - pte: %x - ppn: %x\n", pte, ppte, pte_paddr, pte, ppn);

    if (pte & PTE_RSVD) {
      break;
    } else if (!proc->extension_enabled(EXT_SVNAPOT) && (pte & PTE_N)) {
      break;
    } else if (!pbmte && (pte & PTE_PBMT)) {
      break;
    } else if ((pte & PTE_PBMT) == PTE_PBMT) {
      break;
    } else if (PTE_TABLE(pte)) { // next level of page table
      if (pte & (PTE_D | PTE_A | PTE_U | PTE_N | PTE_PBMT))
        break;
      base = ppn << PGSHIFT;
    } else if ((pte & PTE_U) ? s_mode && (type == FETCH || !sum) : !s_mode) {
      break;
    } else if (!(pte & PTE_V) || (!(pte & PTE_R) && (pte & PTE_W))) {
      break;
    } else if (type == FETCH /*|| hlvx*/ ? !(pte & PTE_X) :
               type == LOAD          ? !(pte & PTE_R) && !(mxr && (pte & PTE_X)) :
                                       !((pte & PTE_R) && (pte & PTE_W))) {
      break;
    } else if ((ppn & ((reg_t(1) << ptshift) - 1)) != 0) {
      break;
    } else {
      reg_t ad = PTE_A | ((type == STORE) * PTE_D);
#ifdef RISCV_ENABLE_DIRTY
      // set accessed and possibly dirty bits.
      if ((pte & ad) != ad) {
        if (!pmp_ok(pte_paddr, vm.ptesize, STORE, PRV_S))
          throw_access_exception(0, addr, type/*, tval_type*/);
        *(target_endian<uint32_t>*)ppte |= to_target((uint32_t)ad);
      }
#else
      // take exception if access or possibly dirty bit is not set.
      if ((pte & ad) != ad)
        break;
#endif
      // for superpage or Svnapot NAPOT mappings, make a fake leaf PTE for the TLB's benefit.
      reg_t vpn = addr >> PGSHIFT;

      int napot_bits = ((pte & PTE_N) ? (ctz(ppn) + 1) : 0);
      if (((pte & PTE_N) && (ppn == 0 || i != 0)) || (napot_bits != 0 && napot_bits != 4))
        break;

      reg_t page_base = ((ppn & ~((reg_t(1) << napot_bits) - 1))
                        | (vpn & ((reg_t(1) << napot_bits) - 1))
                        | (vpn & ((reg_t(1) << ptshift) - 1))) << PGSHIFT;
      reg_t phys = page_base | (addr & page_mask);
      return s2xlate(addr, phys, type, type, 0, 0) & ~page_mask;
    }
  }

  switch (type) {
    case FETCH: {fprintf(stdout, "Reporting instruction page fault.\n"); *exc_error = 1; break;}
    case LOAD: {fprintf(stdout, "Reporting load page fault.\n"); *exc_error = 2; break;}
    case STORE: {fprintf(stdout, "Reporting store page fault.\n"); *exc_error = 3; break;}
    default: fprintf(stdout, "Reporting unknown page fault.\n"); *exc_error = 4;
  }
  fprintf(stdout, "Returning 0 as value and exc_error as %0x\n", *exc_error);
  return 0;
}

void mmu_t::register_memtracer(memtracer_t* t)
{
  flush_tlb();
  tracer.hook(t);
}
