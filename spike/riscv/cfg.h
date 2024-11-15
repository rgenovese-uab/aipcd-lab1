// See LICENSE for license details.
#ifndef _RISCV_CFG_H
#define _RISCV_CFG_H

#include <optional>
#include <experimental/optional>
#include "decode.h"
#include "mmu.h"
#include "platform.h"
#include <cassert>

template <typename T>
class cfg_arg_t {
public:
  cfg_arg_t(T default_val)
    : value(default_val), was_set(false) {}

  bool overridden() const { return was_set; }

  T operator()() const { return value; }

  T operator=(const T v) {
    value = v;
    was_set = true;
    return value;
  }

private:
  T value;
  bool was_set;
};

// Configuration that describes a memory region
class mem_cfg_t
{
public:
  static bool check_if_supported(reg_t base, reg_t size) {
    // The truth of these conditions should be ensured by whatever is creating
    // the regions in the first place, but we have them here to make sure that
    // we can't end up describing memory regions that don't make sense. They
    // ask that the page size is a multiple of the minimum page size, that the
    // page is aligned to the minimum page size, that the page is non-empty and
    // that the top address is still representable in a reg_t.
    return (DISABLE_PGSIZE_CHECK || ((size % PGSIZE == 0) &&
            (base % PGSIZE == 0))) &&
           (base + size > base);
  }

  mem_cfg_t(reg_t base, reg_t size)
    : base(base), size(size)
  {
    assert(mem_cfg_t::check_if_supported(base, size));
  }

  reg_t base;
  reg_t size;
};

class cfg_t
{
public:
  cfg_t(std::pair<reg_t, reg_t> default_initrd_bounds,
        const char *default_bootargs,
        const char *default_isa, const char *default_priv,
        const char *default_varch,
        const core_type_t default_core_type,
        const memif_endianness_t default_endianness,
        const reg_t default_pmpregions,
        const std::vector<mem_cfg_t> &default_mem_layout,
        const std::vector<int> default_hartids,
        bool default_real_time_clint)
    : initrd_bounds(default_initrd_bounds),
      bootargs(default_bootargs),
      isa(default_isa),
      priv(default_priv),
      varch(default_varch),
      core_type(default_core_type),
      endianness(default_endianness),
      pmpregions(default_pmpregions),
      mem_layout(default_mem_layout),
      hartids(default_hartids),
      explicit_hartids(false),
      reset_vector(DEFAULT_RSTVEC),
      bootrom_file(NULL),
      has_mboot_main_id(false),
      mboot_main_id_val(0),
      real_time_clint(default_real_time_clint)
  {}

  cfg_arg_t<std::pair<reg_t, reg_t>> initrd_bounds;
  cfg_arg_t<const char *>            bootargs;
  cfg_arg_t<const char *>            isa;
  cfg_arg_t<const char *>            priv;
  cfg_arg_t<const char *>            varch;
  cfg_arg_t<core_type_t>             core_type;
  memif_endianness_t                 endianness;
  reg_t                              pmpregions;
  cfg_arg_t<std::vector<mem_cfg_t>>  mem_layout;
  std::experimental::optional<reg_t>               start_pc;
  cfg_arg_t<std::vector<int>>        hartids;
  bool                               explicit_hartids;
  cfg_arg_t<bool>                    real_time_clint;
  cfg_arg_t<reg_t>                   reset_vector;
  bool                               has_mboot_main_id;
  cfg_arg_t<reg_t>                   mboot_main_id_val;
  cfg_arg_t<const char *>            bootrom_file;

  size_t nprocs() const { return hartids().size(); }
};

#endif
