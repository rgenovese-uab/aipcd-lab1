// See LICENSE for license details.

#include "cfg.h"
#include "sim.h"
#include "mmu.h"
#include "remote_bitbang.h"
#include "cachesim.h"
#include "extension.h"
#include <dlfcn.h>
#include <fesvr/option_parser.h>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <string>
#include <memory>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <string>
#include "../VERSION"
#include "spike.h"
#include "spike_errors.h"
// #include "reduction.h"


using namespace std;

#define OPIVV 0x0
#define OPFVV 0x1
#define OPMVV 0x2
#define OPIVI 0x3
#define OPIVX 0x4
#define OPFVF 0x5
#define OPMVX 0x6
#define OPCFG 0x7

union fpr
{
  freg_t r;
  float s;
  double d;
};

static void help(int exit_code = 1)
{
  fprintf(stderr, "Spike RISC-V ISA Simulator " SPIKE_VERSION "\n\n");
  fprintf(stderr, "usage: spike [host options] <target program> [target options]\n");
  fprintf(stderr, "Host Options:\n");
  fprintf(stderr, "  -p<n>                 Simulate <n> processors [default 1]\n");
  fprintf(stderr, "  -m<n>                 Provide <n> MiB of target memory [default 2048]\n");
  fprintf(stderr, "  -m<a:m,b:n,...>       Provide memory regions of size m and n bytes\n");
  fprintf(stderr, "                          at base addresses a and b (with 4 KiB alignment)\n");
  fprintf(stderr, "  -d                    Interactive debug mode\n");
  fprintf(stderr, "  -g                    Track histogram of PCs\n");
  fprintf(stderr, "  -l                    Generate a log of execution\n");
#ifdef HAVE_BOOST_ASIO
  fprintf(stderr, "  -s                    Command I/O via socket (use with -d)\n");
#endif
  fprintf(stderr, "  -h, --help            Print this help message\n");
  fprintf(stderr, "  -H                    Start halted, allowing a debugger to connect\n");
  fprintf(stderr, "  --log=<name>          File name for option -l\n");
  fprintf(stderr, "  --debug-cmd=<name>    Read commands from file (use with -d)\n");
  fprintf(stderr, "  --isa=<name>          RISC-V ISA string [default %s]\n", DEFAULT_ISA);
  fprintf(stderr, "  --pmpregions=<n>      Number of PMP regions [default 16]\n");
  fprintf(stderr, "  --priv=<m|mu|msu>     RISC-V privilege modes supported [default %s]\n", DEFAULT_PRIV);
  fprintf(stderr, "  --varch=<name>        RISC-V Vector uArch string [default %s]\n", DEFAULT_VARCH);
  fprintf(stderr, "  --pc=<address>        Override ELF entry point\n");
  fprintf(stderr, "  --hartids=<a,b,...>   Explicitly specify hartids, default is 0,1,...\n");
  fprintf(stderr, "  --ic=<S>:<W>:<B>      Instantiate a cache model with S sets,\n");
  fprintf(stderr, "  --dc=<S>:<W>:<B>        W ways, and B-byte blocks (with S and\n");
  fprintf(stderr, "  --l2=<S>:<W>:<B>        B both powers of 2).\n");
  fprintf(stderr, "  --big-endian          Use a big-endian memory system.\n");
  fprintf(stderr, "  --device=<P,B,A>      Attach MMIO plugin device from an --extlib library\n");
  fprintf(stderr, "                          P -- Name of the MMIO plugin\n");
  fprintf(stderr, "                          B -- Base memory address of the device\n");
  fprintf(stderr, "                          A -- String arguments to pass to the plugin\n");
  fprintf(stderr, "                          This flag can be used multiple times.\n");
  fprintf(stderr, "                          The extlib flag for the library must come first.\n");
  fprintf(stderr, "  --log-cache-miss      Generate a log of cache miss\n");
  fprintf(stderr, "  --log-commits         Generate a log of commits info\n");
  fprintf(stderr, "  --extension=<name>    Specify RoCC Extension\n");
  fprintf(stderr, "                          This flag can be used multiple times.\n");
  fprintf(stderr, "  --extlib=<name>       Shared library to load\n");
  fprintf(stderr, "                        This flag can be used multiple times.\n");
  fprintf(stderr, "  --rbb-port=<port>     Listen on <port> for remote bitbang connection\n");
  fprintf(stderr, "  --dump-dts            Print device tree string and exit\n");
  fprintf(stderr, "  --dtb=<path>          Use specified device tree blob [default: auto-generate]\n");
  fprintf(stderr, "  --disable-dtb         Don't write the device tree blob into memory\n");
  fprintf(stderr, "  --kernel=<path>       Load kernel flat image into memory\n");
  fprintf(stderr, "  --initrd=<path>       Load kernel initrd into memory\n");
  fprintf(stderr, "  --bootargs=<args>     Provide custom bootargs for kernel [default: console=hvc0 earlycon=sbi]\n");
  fprintf(stderr, "  --real-time-clint     Increment clint time at real-time rate\n");
  fprintf(stderr, "  --dm-progsize=<words> Progsize for the debug module [default 2]\n");
  fprintf(stderr, "  --dm-sba=<bits>       Debug system bus access supports up to "
      "<bits> wide accesses [default 0]\n");
  fprintf(stderr, "  --dm-auth             Debug module requires debugger to authenticate\n");
  fprintf(stderr, "  --dmi-rti=<n>         Number of Run-Test/Idle cycles "
      "required for a DMI access [default 0]\n");
  fprintf(stderr, "  --dm-abstract-rti=<n> Number of Run-Test/Idle cycles "
      "required for an abstract command to execute [default 0]\n");
  fprintf(stderr, "  --dm-no-hasel         Debug module supports hasel\n");
  fprintf(stderr, "  --dm-no-abstract-csr  Debug module won't support abstract CSR access\n");
  fprintf(stderr, "  --dm-no-abstract-fpr  Debug module won't support abstract FPR access\n");
  fprintf(stderr, "  --dm-no-halt-groups   Debug module won't support halt groups\n");
  fprintf(stderr, "  --dm-no-impebreak     Debug module won't support implicit ebreak in program buffer\n");
  fprintf(stderr, "  --blocksz=<size>      Cache block size (B) for CMO operations(powers of 2) [default 64]\n");
  fprintf(stderr, "  --eprocessor-mode   Enable eProcessor mode (narrow FP, narrow INT, SA)\n"); // TODO replace with proper RV extension
  fprintf(stderr, "  --reduction-config=<L>:<F>:<I>:<T> Reduction configuration: L lanes, F fp accums, I int accums, T -> tree enabled\n");
  fprintf(stderr, "  --core-type=<T>       Core type T [STANDARD [default], SARGANTANA, LAGARTO_KA, LAGARTO_OX, VPU\n");
  fprintf(stderr, "  --reset-vector=<addr> PC after reset (default = %x)\n", DEFAULT_RSTVEC);
  fprintf(stderr, "  --bootrom-file=<filename>  Load bootrom with content from filename (bin)\n");
  fprintf(stderr, "  --has-mboot-main-id  Implement cincoranch boot csr (MBOOT_MAIN_ID)\n");
  fprintf(stderr, "  --mboot-main-id-val=<val>  Value of the cincoranch boot csr (MBOOT_MAIN_ID)\n");

  exit(exit_code);
}

static void suggest_help()
{
  fprintf(stderr, "Try 'spike --help' for more information.\n");
  exit(1);
}

static bool check_file_exists(const char *fileName)
{
  std::ifstream infile(fileName);
  return infile.good();
}

static std::ifstream::pos_type get_file_size(const char *filename)
{
  std::ifstream in(filename, std::ios::ate | std::ios::binary);
  return in.tellg();
}

static void read_file_bytes(const char *filename,size_t fileoff,
                            mem_t* mem, size_t memoff, size_t read_sz)
{
  std::ifstream in(filename, std::ios::in | std::ios::binary);
  in.seekg(fileoff, std::ios::beg);

  std::vector<char> read_buf(read_sz, 0);
  in.read(&read_buf[0], read_sz);
  mem->store(memoff, read_sz, (uint8_t*)&read_buf[0]);
}

bool sort_mem_region(const mem_cfg_t &a, const mem_cfg_t &b)
{
  if (a.base == b.base)
    return (a.size < b.size);
  else
    return (a.base < b.base);
}

void merge_overlapping_memory_regions(std::vector<mem_cfg_t> &mems)
{
  // check the user specified memory regions and merge the overlapping or
  // eliminate the containing parts
  assert(!mems.empty());

  std::sort(mems.begin(), mems.end(), sort_mem_region);
  for (auto it = mems.begin() + 1; it != mems.end(); ) {
    reg_t start = prev(it)->base;
    reg_t end = prev(it)->base + prev(it)->size;
    reg_t start2 = it->base;
    reg_t end2 = it->base + it->size;

    //contains -> remove
    if (start2 >= start && end2 <= end) {
      it = mems.erase(it);
    //partial overlapped -> extend
    } else if (start2 >= start && start2 < end) {
      prev(it)->size = std::max(end, end2) - start;
      it = mems.erase(it);
    // no overlapping -> keep it
    } else {
      it++;
    }
  }
}

static std::vector<mem_cfg_t> parse_mem_layout(const char* arg)
{
  std::vector<mem_cfg_t> res;

  // handle legacy mem argument
  char* p;
  auto mb = strtoull(arg, &p, 0);
  if (*p == 0) {
    reg_t size = reg_t(mb) << 20;
    if (size != (size_t)size)
      throw std::runtime_error("Size would overflow size_t");
    res.push_back(mem_cfg_t(reg_t(DRAM_BASE), size));
    return res;
  }

  // handle base/size tuples
  while (true) {
    auto base = strtoull(arg, &p, 0);
    if (!*p || *p != ':')
      help();
    auto size = strtoull(p + 1, &p, 0);

    // page-align base and size
    if (!DISABLE_PGSIZE_CHECK) {
        auto base0 = base, size0 = size;
        size += base0 % PGSIZE;
        base -= base0 % PGSIZE;
        if (size % PGSIZE != 0)
          size += PGSIZE - size % PGSIZE;

        if (size != size0) {
          fprintf(stderr, "Warning: the memory at  [0x%llX, 0x%llX] has been realigned\n"
                      "to the %ld KiB page size: [0x%llX, 0x%llX]\n",
              base0, base0 + size0 - 1, long(PGSIZE / 1024), base, base + size - 1);
        }
    }

    if (!mem_cfg_t::check_if_supported(base, size)) {
      fprintf(stderr, "unsupported memory region "
                      "{base = 0x%llX, size = 0x%llX} specified\n",
                      (unsigned long long)base,
                      (unsigned long long)size);
      exit(EXIT_FAILURE);
    }

    res.push_back(mem_cfg_t(reg_t(base), reg_t(size)));
    if (!*p)
      break;
    if (*p != ',')
      help();
    arg = p + 1;
  }

  merge_overlapping_memory_regions(res);

  return res;
}

static std::vector<std::pair<reg_t, mem_t*>> make_mems(const std::vector<mem_cfg_t> &layout)
{
  std::vector<std::pair<reg_t, mem_t*>> mems;
  mems.reserve(layout.size());
  for (const auto &cfg : layout) {
    mems.push_back(std::make_pair(cfg.base, new mem_t(cfg.size)));
  }
  return mems;
}

static unsigned long atoul_safe(const char* s)
{
  char* e;
  auto res = strtoul(s, &e, 10);
  if (*e)
    help();
  return res;
}

static unsigned long atoul_nonzero_safe(const char* s)
{
  auto res = atoul_safe(s);
  if (!res)
    help();
  return res;
}

static std::vector<int> parse_hartids(const char *s)
{
  std::string const str(s);
  std::stringstream stream(str);
  std::vector<int> hartids;

  int n;
  while (stream >> n) {
    hartids.push_back(n);
    if (stream.peek() == ',') stream.ignore();
  }

  return hartids;
}

void spike_wrapper::start_execution() {
  auto return_code = s->run();
}

void spike_wrapper::setup(int nargs,const char** args)
{
  bool debug = false;
  bool halted = false;
  bool histogram = false;
  bool log = false;
  bool UNUSED socket = false;  // command line option -s
  bool dump_dts = false;
  bool dtb_enabled = true;
  const char* kernel = NULL;
  reg_t kernel_offset, kernel_size;
  std::vector<std::pair<reg_t, abstract_device_t*>> plugin_devices;
  std::unique_ptr<icache_sim_t> ic;
  std::unique_ptr<dcache_sim_t> dc;
  std::unique_ptr<cache_sim_t> l2;
  bool log_cache = false;
  bool log_commits = false;
  const char *log_path = nullptr;
  std::vector<std::function<extension_t*()>> extensions;
  const char* initrd = NULL;
  const char* dtb_file = getenv("DTB_PATH");;
  uint16_t rbb_port = 0;
  bool use_rbb = false;
  unsigned dmi_rti = 0;
  reg_t blocksz = 64;
  const char* reduction_config = "8:7:3:1";

  debug_module_config_t dm_config = {
    .progbufsize = 2,
    .max_sba_data_width = 0,
    .require_authentication = false,
    .abstract_rti = 0,
    .support_hasel = true,
    .support_abstract_csr_access = true,
    .support_abstract_fpr_access = true,
    .support_haltgroups = true,
    .support_impebreak = true
  };
  cfg_arg_t<size_t> nprocs(1);

  cfg_t cfg(/*default_initrd_bounds=*/std::make_pair((reg_t)0, (reg_t)0),
            /*default_bootargs=*/nullptr,
            /*default_isa=*/DEFAULT_ISA,
            /*default_priv=*/DEFAULT_PRIV,
            /*default_varch=*/DEFAULT_VARCH,
            /*default_core_type=*/core_type_from_string(DEFAULT_CORE_TYPE),
            /*default_endianness*/memif_endianness_little,
            /*default_pmpregions=*/16,
            /*default_mem_layout=*/parse_mem_layout("2048"),
            /*default_hartids=*/std::vector<int>(),
            /*default_real_time_clint=*/false);

  auto const device_parser = [&plugin_devices](const char *s) {
    const std::string str(s);
    std::istringstream stream(str);

    // We are parsing a string like name,base,args.

    // Parse the name, which is simply all of the characters leading up to the
    // first comma. The validity of the plugin name will be checked later.
    std::string name;
    std::getline(stream, name, ',');
    if (name.empty()) {
      throw std::runtime_error("Plugin name is empty.");
    }

    // Parse the base address. First, get all of the characters up to the next
    // comma (or up to the end of the string if there is no comma). Then try to
    // parse that string as an integer according to the rules of strtoull. It
    // could be in decimal, hex, or octal. Fail if we were able to parse a
    // number but there were garbage characters after the valid number. We must
    // consume the entire string between the commas.
    std::string base_str;
    std::getline(stream, base_str, ',');
    if (base_str.empty()) {
      throw std::runtime_error("Device base address is empty.");
    }
    char* end;
    reg_t base = static_cast<reg_t>(strtoull(base_str.c_str(), &end, 0));
    if (end != &*base_str.cend()) {
      throw std::runtime_error("Error parsing device base address.");
    }

    // The remainder of the string is the arguments. We could use getline, but
    // that could ignore newline characters in the arguments. That should be
    // rare and discouraged, but handle it here anyway with this weird in_avail
    // technique. The arguments are optional, so if there were no arguments
    // specified we could end up with an empty string here. That's okay.
    auto avail = stream.rdbuf()->in_avail();
    std::string args(avail, '\0');
    stream.readsome(&args[0], avail);

    plugin_devices.emplace_back(base, new mmio_plugin_device_t(name, args));
  };

  option_parser_t parser;
  parser.help(&suggest_help);
  parser.option('h', "help", 0, [&](const char UNUSED *s){help(0);});
  parser.option('d', 0, 0, [&](const char UNUSED *s){debug = true;});
  parser.option('g', 0, 0, [&](const char UNUSED *s){histogram = true;});
  parser.option('l', 0, 0, [&](const char UNUSED *s){log = true;});
#ifdef HAVE_BOOST_ASIO
  parser.option('s', 0, 0, [&](const char UNUSED *s){socket = true;});
#endif
  parser.option('p', 0, 1, [&](const char* s){nprocs = atoul_nonzero_safe(s);});
  parser.option('m', 0, 1, [&](const char* s){cfg.mem_layout = parse_mem_layout(s);});
  // I wanted to use --halted, but for some reason that doesn't work.
  parser.option('H', 0, 0, [&](const char UNUSED *s){halted = true;});
  parser.option(0, "rbb-port", 1, [&](const char* s){use_rbb = true; rbb_port = atoul_safe(s);});
  parser.option(0, "pc", 1, [&](const char* s){cfg.start_pc = strtoull(s, 0, 0);});
  parser.option(0, "hartids", 1, [&](const char* s){
    cfg.hartids = parse_hartids(s);
    cfg.explicit_hartids = true;
  });
  parser.option(0, "ic", 1, [&](const char* s){ic.reset(new icache_sim_t(s));});
  parser.option(0, "dc", 1, [&](const char* s){dc.reset(new dcache_sim_t(s));});
  parser.option(0, "l2", 1, [&](const char* s){l2.reset(cache_sim_t::construct(s, "L2$"));});
  parser.option(0, "big-endian", 0, [&](const char UNUSED *s){cfg.endianness = memif_endianness_big;});
  parser.option(0, "log-cache-miss", 0, [&](const char UNUSED *s){log_cache = true;});
  parser.option(0, "isa", 1, [&](const char* s){cfg.isa = s;});
  parser.option(0, "pmpregions", 1, [&](const char* s){cfg.pmpregions = atoul_safe(s);});
  parser.option(0, "priv", 1, [&](const char* s){cfg.priv = s;});
  parser.option(0, "varch", 1, [&](const char* s){cfg.varch = s;});
  parser.option(0, "device", 1, device_parser);
  parser.option(0, "extension", 1, [&](const char* s){extensions.push_back(find_extension(s));});
  parser.option(0, "dump-dts", 0, [&](const char UNUSED *s){dump_dts = true;});
  parser.option(0, "disable-dtb", 0, [&](const char UNUSED *s){dtb_enabled = false;});
  parser.option(0, "dtb", 1, [&](const char *s){dtb_file = s;});
  parser.option(0, "kernel", 1, [&](const char* s){kernel = s;});
  parser.option(0, "initrd", 1, [&](const char* s){initrd = s;});
  parser.option(0, "bootargs", 1, [&](const char* s){cfg.bootargs = s;});
  parser.option(0, "real-time-clint", 0, [&](const char UNUSED *s){cfg.real_time_clint = true;});
  parser.option(0, "extlib", 1, [&](const char *s){
    void *lib = dlopen(s, RTLD_NOW | RTLD_GLOBAL);
    if (lib == NULL) {
      fprintf(stderr, "Unable to load extlib '%s': %s\n", s, dlerror());
      exit(-1);
    }
  });
  parser.option(0, "dm-progsize", 1,
      [&](const char* s){dm_config.progbufsize = atoul_safe(s);});
  parser.option(0, "dm-no-impebreak", 0,
      [&](const char UNUSED *s){dm_config.support_impebreak = false;});
  parser.option(0, "dm-sba", 1,
      [&](const char* s){dm_config.max_sba_data_width = atoul_safe(s);});
  parser.option(0, "dm-auth", 0,
      [&](const char UNUSED *s){dm_config.require_authentication = true;});
  parser.option(0, "dmi-rti", 1,
      [&](const char* s){dmi_rti = atoul_safe(s);});
  parser.option(0, "dm-abstract-rti", 1,
      [&](const char* s){dm_config.abstract_rti = atoul_safe(s);});
  parser.option(0, "dm-no-hasel", 0,
      [&](const char UNUSED *s){dm_config.support_hasel = false;});
  parser.option(0, "dm-no-abstract-csr", 0,
      [&](const char UNUSED *s){dm_config.support_abstract_csr_access = false;});
  parser.option(0, "dm-no-abstract-fpr", 0,
      [&](const char UNUSED *s){dm_config.support_abstract_fpr_access = false;});
  parser.option(0, "dm-no-halt-groups", 0,
      [&](const char UNUSED *s){dm_config.support_haltgroups = false;});
  parser.option(0, "log-commits", 0,
                [&](const char UNUSED *s){log_commits = true;});
  parser.option(0, "log", 1,
                [&](const char* s){log_path = s;});
  FILE *cmd_file = NULL;
  parser.option(0, "debug-cmd", 1, [&](const char* s){
     if ((cmd_file = fopen(s, "r"))==NULL) {
        fprintf(stderr, "Unable to open command file '%s'\n", s);
        exit(-1);
     }
  });
  parser.option(0, "blocksz", 1, [&](const char* s){
    blocksz = strtoull(s, 0, 0);
    const unsigned min_blocksz = 16;
    const unsigned max_blocksz = PGSIZE;
    if (blocksz < min_blocksz || blocksz > max_blocksz || ((blocksz & (blocksz - 1))) != 0) {
      fprintf(stderr, "--blocksz must be a power of 2 between %u and %u\n",
        min_blocksz, max_blocksz);
      exit(-1);
    }
  });
  parser.option(0, "eprocessor-mode", 0, [&](const char* s){eprocessor_mode = true;});
  parser.option(0, "reduction-config", 1, [&](const char* s){reduction_config = s;});
  parser.option(0, "core-type", 1, [&](const char* s){cfg.core_type = core_type_from_string(s);});
  parser.option(0, "reset-vector", 1, [&](const char* s){cfg.reset_vector = strtoul(s, 0, 0);});
  parser.option(0, "bootrom-file", 1, [&](const char* s){cfg.bootrom_file = s;});
  parser.option(0, "has-mboot-main-id", 0, [&](const char* s){cfg.has_mboot_main_id = true;});
  parser.option(0, "mboot-main-id-val", 1, [&](const char* s){cfg.mboot_main_id_val = strtoul(s, 0, 0);});

  auto args1 = parser.parse(args);
  std::vector<std::string> htif_args(args1, (const char*const*)args + nargs);

  // if (!*args1)
  //   help();

  std::vector<std::pair<reg_t, mem_t*>> mems = make_mems(cfg.mem_layout());

  if (kernel && check_file_exists(kernel)) {
    const char *isa = cfg.isa();
    kernel_size = get_file_size(kernel);
    if (isa[2] == '6' && isa[3] == '4')
      kernel_offset = 0x200000;
    else
      kernel_offset = 0x400000;
    for (auto& m : mems) {
      if (kernel_size && (kernel_offset + kernel_size) < m.second->size()) {
         read_file_bytes(kernel, 0, m.second, kernel_offset, kernel_size);
         break;
      }
    }
  }

  const char* fp = strchr(reduction_config, ':');
  if (!fp++) help();
  const char* ip = strchr(fp, ':');
  if (!ip++) help();
  const char* tp = strchr(ip, ':');
  if (!tp++) help();

  reduction_lanes = atoi(std::string(reduction_config, fp).c_str());
  reduction_fp_accums = atoi(std::string(fp, ip).c_str());
  reduction_int_accums = atoi(std::string(ip, tp).c_str());
  reduction_tree_enable = atoi(tp);

  if (initrd && check_file_exists(initrd)) {
    size_t initrd_size = get_file_size(initrd);
    for (auto& m : mems) {
      if (initrd_size && (initrd_size + 0x1000) < m.second->size()) {
         reg_t initrd_end = m.first + m.second->size() - 0x1000;
         reg_t initrd_start = initrd_end - initrd_size;
         cfg.initrd_bounds = std::make_pair(initrd_start, initrd_end);
         read_file_bytes(initrd, 0, m.second, initrd_start - m.first, initrd_size);
         break;
      }
    }
  }

#ifdef HAVE_BOOST_ASIO
  boost::asio::io_service *io_service_ptr = NULL; // needed for socket command interface option -s
  boost::asio::ip::tcp::acceptor *acceptor_ptr = NULL;
  if (socket) {  // if command line option -s is set
     try
     { // create socket server
       using boost::asio::ip::tcp;
       io_service_ptr = new boost::asio::io_service;
       acceptor_ptr = new tcp::acceptor(*io_service_ptr, tcp::endpoint(tcp::v4(), 0));
       // aceptor is created passing argument port=0, so O.S. will choose a free port
       std::string name = boost::asio::ip::host_name();
       std::cout << "Listening for debug commands on " << name.substr(0,name.find('.'))
                 << " port " << acceptor_ptr->local_endpoint().port() << " ." << std::endl;
       // at the end, add space and some other character for convenience of javascript .split(" ")
     }
     catch (std::exception& e)
     {
       std::cerr << e.what() << std::endl;
       exit(-1);
     }
  }
#endif

  if (cfg.explicit_hartids) {
    if (nprocs.overridden() && (nprocs() != cfg.nprocs())) {
      std::cerr << "Number of specified hartids ("
                << cfg.nprocs()
                << ") doesn't match specified number of processors ("
                << nprocs() << ").\n";
      exit(1);
    }
  } else {
    // Set default set of hartids based on nprocs, but don't set the
    // explicit_hartids flag (which means that downstream code can know that
    // we've only set the number of harts, not explicitly chosen their IDs).
    std::vector<int> default_hartids;
    default_hartids.reserve(nprocs());
    for (size_t i = 0; i < nprocs(); ++i) {
      default_hartids.push_back(i);
    }
    cfg.hartids = default_hartids;
  }
if (dtb_file == NULL) {
    dtb_file = (char*) "lib/dtb.dat";
  }
  fprintf(stdout, "SPIKE - SPIKE.CC DTB FILE %s\n",dtb_file );
   s = new sim_t(&cfg, halted,
      mems, plugin_devices, htif_args, dm_config, log_path, dtb_enabled, dtb_file,
#ifdef HAVE_BOOST_ASIO
      io_service_ptr, acceptor_ptr,
#endif
      cmd_file);
  std::unique_ptr<remote_bitbang_t> remote_bitbang((remote_bitbang_t *) NULL);
  std::unique_ptr<jtag_dtm_t> jtag_dtm(
      new jtag_dtm_t(&s->debug_module, dmi_rti));
  if (use_rbb) {
    remote_bitbang.reset(new remote_bitbang_t(rbb_port, &(*jtag_dtm)));
    s->set_remote_bitbang(&(*remote_bitbang));
  }

  if (dump_dts) {
    printf("%s", s->get_dts());
    // return 0;
    exit(3);
  }

  if (ic && l2) ic->set_miss_handler(&*l2);
  if (dc && l2) dc->set_miss_handler(&*l2);
  if (ic) ic->set_log(log_cache);
  if (dc) dc->set_log(log_cache);
  for (size_t i = 0; i < cfg.nprocs(); i++)
  {
    if (ic) s->get_core(i)->get_mmu()->register_memtracer(&*ic);
    if (dc) s->get_core(i)->get_mmu()->register_memtracer(&*dc);
    for (auto e : extensions)
      s->get_core(i)->register_extension(e());
    s->get_core(i)->get_mmu()->set_cache_blocksz(blocksz);
  }

  s->set_debug(debug);
  s->configure_log(log, log_commits);
  s->set_histogram(histogram);

  auto return_code = s->run();

  // for (auto& mem : mems)
  //   delete mem.second;

  // for (auto& plugin_device : plugin_devices)
  //   delete plugin_device.second;

  // return return_code;
}

spike_wrapper::spike_wrapper(){

    if(const char* env_p = std::getenv("SMD_ENV")) {
      int mode = atoi(env_p);
      if (mode) {
        SMD_mode = true;
      }
    }

    vector_reg_file = malloc(NVPR * (VLEN/8));
    if (this->vector_reg_file == NULL)
    {
        std::cout << "[SPIKE-DPI] Bad_alloc Exception :: out Of Memory " << std::endl;
        std::cout << "[SPIKE-DPI] Exiting" << std::endl;
        throw 12; //ENOMEM
    }

    reduction_lanes = 1;
    reduction_fp_accums = 1;
    reduction_int_accums = 1;
    reduction_tree_enable = 0;

}

spike_wrapper::~spike_wrapper() {

  for (auto& mem : mems)
    delete mem.second;

  for (auto& plugin_device : plugin_devices)
    delete plugin_device.second;

  std::cout << "cry time" << std::endl;
  delete s;

}

#define check_exit_code(code) \
    if (code != 0) { \
        std::cout << "[SPIKE-DPI] Something went wrong, exit code is " << code << std::endl; \
        return code; \
    } \

#define copy_regs_from_state(state) \
    if (state != NULL) { \
        copy_scalar_reg_file(state->XPR); \
        copy_fp_reg_file(state->FPR); \
    }

bool is_memop(insn_t ins) {

    uint64_t i26 = ins.x(26, 3);
    uint64_t i20 = ins.rs2();
    uint64_t i12 = ins.rm();

    switch(ins.x(0,6)) {
        case 0x7:
            return true;

        case 0x27:
            return true;
    }
    return false;

}

bool is_fp_reduction_ins(insn_t ins) { //just reduction reference model implementations
    uint64_t funct6 = ins.x(26, 6);
    uint64_t i20 = ins.rs2();
    uint64_t i12 = ins.rm();
    uint64_t funct3 = ins.x(12,3);
    uint64_t opcode = ins.x(0,7);

    if ((funct6 == 0x1 || funct6 == 0x31) && funct3 == 0x1 && opcode == 0x57)
        return true;

    return false;
}

bool spike_wrapper::is_not_vector(insn_t ins) {
    uint64_t width = ins.v_width();
    uint64_t i20 = ins.rs2();
    uint64_t i12 = ins.rm();
    uint64_t i14= ins.x(12, 3);

    switch(ins.x(0, 7)) {
        case 0x7:
            /* OPCODE 000 0111 */
        case 0x27:
            /* OPCODE 010 0111 */
            return (((width >= 1) && (width <= 4)) || ins.v_mew()); // widths 1,2,3,4 are used for FP, not vector. mew = 1 is reserved
            break;
        case 0x57:
            if (i14 != 7) //vsetvli
                return false;
        default:
            return true;
    }

    return true;
}
int spike_wrapper::load_uint(uint64_t* data, uint64_t address) {

    processor_t* core = s->get_core(0);
    try {
        switch(core->VU.vsew){
            case 64:
                *data = core->get_mmu()->load<uint64_t>( (addr_t) address);
                break;
            case 32:
                *data = core->get_mmu()->load<uint32_t>( (addr_t) address);
                break;
            case 16:
                *data = core->get_mmu()->load<uint16_t>( (addr_t) address);
                break;
            case 8:
                *data = core->get_mmu()->load<uint8_t>( (addr_t) address);
                break;
            default:
                return 2;
        }
    }
    catch(trap_t& t) {
        *data = 0;
        std::cout << "[SPIKE-DPI] Memory access to address " << std::hex << address << " has thrown an exception" << std::endl;
    }

    return 0;

}

int spike_wrapper::run_and_inject(uint32_t instr, core_state_t* core_state) { //[TOCHECK] from Lagarto KA

    sim_t* sim = s;
    processor_t* core = s->get_core(0);
    string isa = core->get_isa_string();

    // State before executing the instruction
    state_t* p_state = core->get_state();
    //fprintf(stdout, "RUN AND INJECT1 w/P_STATE PC %lx\n",p_state->pc );

    // Copy registers before execting the instruction so rd is not overwritten
    copy_vector_reg_file(core);

    copy_regs_from_state(p_state);

    reg_t pc = p_state->pc; // The pc of the state points to the next instruction to be executed

    //core->get_mmu()->sneaky_store_uint32( (addr_t) pc, instr); // Inject the desired instruction
    core->inject_instr = 1;
    core->instr_to_inject = (long int)(int) instr;
    core->pc_to_inject = pc;

    s->step(1);

    insn_t ins = core->get_state()->current_instruction;

    p_state = core->get_state();

    core_state->pc = pc;
    core_state->ins = ins.bits();

    //fprintf(stdout, "RUN AND INJECT2 AFTER STEP w/P PC %lx and INST %lx \n",pc, ins.bits() );

    //RVCFD64 extension checkings
    // rd signals
    //no compressed and compressed floating point rd, they use the same bits
    bool is_fp_rd = (ins.x(0,7) == 0x7 /*LOAD-FP*/) 
              || (ins.x(0,7) == 0x27 /*STORE-FP*/) 
              || ( (ins.x(0,7) == 0x53 /*OP-FP*/)
                  && !(ins.x(27,5) == 0x14 /*FEQ, FLT, FLE*/)
                  && !(ins.x(27,5) == 0x1C /*FCLASS.S-D, FMV.X.W-D*/)
                  && !(ins.x(27,5) == 0x18 /*FCVT.W-WU-L-LU.S-D*/) )
              || (ins.x(0,7) == 0x43 ) //FMADD
              || (ins.x(0,7) == 0x47 ) //FMSUB
              || (ins.x(0,7) == 0x4B ) //FNMSUB
              || (ins.x(0,7) == 0x4F ) //FNMADD
              || ( (ins.x(0,2) == 0x2 /*Compressed instructions quadrant 2*/)
                  && (ins.x(13,3) == 0x1 /*c.fldsp*/));

    //compressed floating point rd in rvc_rs2s bits
    bool is_fp_rd_rs2s = ( (ins.x(0,2) == 0x0 /*Compressed instructions quadrant 0*/)
                  && (ins.x(13,3) == 0x1 /*c.fld*/));

    //compressed integer rd in rvc_rs2s bits
    bool is_int_rd_rs2s = ( (ins.x(0,2) == 0x0 /*Compressed instructions quadrant 0*/)
                  && !(ins.x(13,3) == 0x1 /*c.fld*/));

    //compressed integer rd in rvc_rs1s bits
    bool is_int_rd_rs1s = ( (ins.x(0,2) == 0x1 /*Compressed instructions quadrant 1*/)
                  && (ins.x(13,3) > 0x3 /*all c instructions from c.srli*/));

    //special case, rd id = 1
    bool is_c_jalr_rd =  ( (ins.x(0,2) == 0x2 /*Compressed instructions quadrant 2*/)
                  && ((ins.x(13,3) == 0x4) && (ins.x(12,1) == 0x1) && (ins.x(2,5) == 0x0) /*c.jalr*/));
    
    if (is_c_jalr_rd) {
      core_state->dst_value = p_state->XPR[X_RA];
      core_state->dst_num = X_RA;
    } else if (is_fp_rd) {
      core_state->dst_value = p_state->FPR[ins.rd()].v[0];
      core_state->dst_num = ins.rd();
    } else if (is_fp_rd_rs2s) {
      core_state->dst_value = p_state->FPR[ins.rvc_rs2s()].v[0];
      core_state->dst_num = ins.rvc_rs2s();
    } else if (is_int_rd_rs2s) {
      core_state->dst_value = p_state->XPR[ins.rvc_rs2s()];
      core_state->dst_num = ins.rvc_rs2s();
    } else if (is_int_rd_rs1s) {
      core_state->dst_value = p_state->XPR[ins.rvc_rs1s()];
      core_state->dst_num = ins.rvc_rs1s();
    } else {
      core_state->dst_value = p_state->XPR[ins.rd()];
      core_state->dst_num = ins.rd();
    }

    //rs1 signals
    //no compressed floating point rs1
    bool is_fp_rs1 = /*LOAD-FP and STORE-FP use integer addressing mode*/
              ( (ins.x(0,7) == 0x53 /*OP-FP*/)
                  && !(ins.x(27,5) == 0x1E /*FMV.D-W.X*/)
                  && !(ins.x(27,5) == 0x1A /*FCVT.S-D.W-WU-L-LU*/) )
              || (ins.x(0,7) == 0x43 ) //FMADD
              || (ins.x(0,7) == 0x47 ) //FMSUB
              || (ins.x(0,7) == 0x4B ) //FNMSUB
              || (ins.x(0,7) == 0x4F );//FNMADD

    //compressed floating point rs1 in rvc_rs1s bits
    bool is_int_rs1_rs1s = (ins.x(0,2) == 0x0 /*Compressed instructions quadrant 0*/)
                  || ( (ins.x(0,2) == 0x1 /*Compressed instructions quadrant 0*/)
                  && (ins.x(13,3) > 0x3 /*all c instructions from c.srli*/));

    //compressed integer rs1 in rvc_rs1 bits
    bool is_int_rs1_crs1 = ( (ins.x(0,2) == 0x1 /*Compressed instructions quadrant 0*/)
                  && (ins.x(13,3) <= 0x3 /*all c instructions before c.srli*/))
                  || (ins.x(0,2) == 0x2 /*Compressed instructions quadrant 2*/);

    if (is_fp_rs1) {
      core_state->src1_value = p_state->FPR[ins.rs1()].v[0];
      core_state->src1_num = ins.rs1();
    } else if (is_int_rs1_rs1s) {
      core_state->src1_value = p_state->XPR[ins.rvc_rs1s()];
      core_state->src1_num = ins.rvc_rs1s();
    } else if (is_int_rs1_crs1) {
      core_state->src1_value = p_state->XPR[ins.rvc_rs1()];
      core_state->src1_num = ins.rvc_rs1();
    } else {
      core_state->src1_value = p_state->XPR[ins.rs1()];
      core_state->src1_num = ins.rs1();
    }

    //rs2 signals
    //no compressed floating point rs2
    bool is_fp_rs2 = (ins.x(0,7) == 0x27 /*STORE-FP*/)
              || (ins.x(0,7) == 0x53 /*OP-FP*/)
              || (ins.x(0,7) == 0x43 ) //FMADD
              || (ins.x(0,7) == 0x47 ) //FMSUB
              || (ins.x(0,7) == 0x4B ) //FNMSUB
              || (ins.x(0,7) == 0x4F ); //FNMADD

    //compressed floating point rs2 in rvc_rs2s bits
    bool is_fp_rs2_rs2s = ( (ins.x(0,2) == 0x0 /*Compressed instructions quadrant 0*/)
                  && (ins.x(13,3) == 0x5 /*c.fsd*/));

    //compressed integer rs1 in rvc_rs1s bits
    bool is_int_rs2_rs2s = (ins.x(0,2) == 0x0 /*Compressed instructions quadrant 0*/)
                  && !(ins.x(13,3) == 0x5 /*c.fsd*/)
                  || (ins.x(0,2) == 0x1 /*Compressed instructions quadrant 0*/);

    //compressed integer rs1 in rvc_rs1 bits
    bool is_int_rs2_crs2 = (ins.x(0,2) == 0x2 /*Compressed instructions quadrant 2: c.fsdsp*/);

    if (is_fp_rs2) {
      core_state->src2_value = p_state->FPR[ins.rs2()].v[0];
      core_state->src2_num = ins.rs2();
    } else if (is_fp_rs2_rs2s) {
      core_state->src2_value = p_state->FPR[ins.rvc_rs2s()].v[0];
      core_state->src2_num = ins.rvc_rs2s();
    } else if (is_int_rs2_rs2s) {
      core_state->src2_value = p_state->XPR[ins.rvc_rs2s()];
      core_state->src2_num = ins.rvc_rs2s();
    } else if (is_int_rs2_crs2) {
      core_state->src2_value = p_state->XPR[ins.rvc_rs2()];
      core_state->src2_num = ins.rvc_rs2();
    } else {
      core_state->src2_value = p_state->XPR[ins.rs2()];
      core_state->src2_num = ins.rs2();
    }
    
    //disasm
    core_state->disasm = (char*) malloc(sizeof(char)*128);
    if (core_state->disasm == NULL)
        core_state->disasm = (char*) malloc(sizeof(char)*128);

    //fprintf(stdout, "INSTRUCTION %s IS FP %d\n", core_state->disasm, is_fp);

    //csr signals
    core_state->csr.frm          = p_state->frm->read();
    core_state->csr.fflags       = p_state->fflags->read();
    core_state->csr.trap_illegal = core->trap_illegal;
    core_state->csr.mcause       = p_state->mcause->read();
    core_state->csr.scause       = p_state->scause->read();
    core_state->csr.mstatus      = p_state->mstatus->read();
    core_state->csr.misa         = p_state->misa->read();

    //trap signals
    core_state->exc_bit = core->trap_illegal | core->trap_instr;

    //scalar mem operation
    core_state->vaddr = p_state->vaddr;
    core_state->store_data = p_state->store_data;
    core_state->store_mask = p_state->store_mask;
    
    //disassemble string
    strcpy(core_state->disasm, core->get_disassembler()->disassemble(ins).c_str());

    // Vector Logic

    if (is_vector(ins)) {
        p_state->last_fflags = 0;

		save_vector_state(core, core_state);

		if(core->trap_illegal){
    	    //std::cout << std::hex << "[SPIKE-DPI] [ " << prev_pc << " ] Illegal instruction on INS: " << ins.bits() << std::endl;
    	    if(const char* env_p = std::getenv("EXIT_ON_ILLEGAL")) {
    	        int mode = atoi(env_p);
    	        if (mode){
    	            return ILLEGAL_INSTR;
    	        }
    	    }
    	}

    	if(core->trap_instr and ! core_state->csr.trap_illegal ){
    	    std::cout << std::hex << "[SPIKE-DPI] Spike error in INS: " << ins.bits() << std::endl;
    	    return TEST_ERROR;
    	}
	}
    //fprintf(stdout, "RUN AND INJECT3 FINISH \n" );
    return !s->done();

}

// These two functions are really similar, as this is not expected to be reused I would keep both.
void spike_wrapper::copy_scalar_reg_file(regfile_t<reg_t, NXPR, true> regfile) {
    for (int i = 0; i < NXPR; ++i) {
        this->XPR[i] = regfile[i];
    }
}

void spike_wrapper::copy_fp_reg_file(regfile_t<freg_t, NFPR, false> regfile) {
    for (int i = 0; i < NFPR; ++i) {
        this->FPR[i] = regfile[i];
    }
}

// From Andres interrupt support implementation
reg_t spike_wrapper::get_csr(int which) {
    sim_t* sim = s;
    processor_t* core = s->get_core(0);

    return core->get_csr(which);
}

void spike_wrapper::set_mip_ei(reg_t val) {
    sim_t* sim = s;
    processor_t* core = s->get_core(0);
    core->set_mip_ei(val);
}
reg_t spike_wrapper::get_prv_lvl() {
    sim_t* sim = s;
    processor_t* core = s->get_core(0);

    return core->get_prv_lvl();
}


bool spike_wrapper::is_vector(insn_t ins) {
    // Indicate if the instruction is vector. No need to identify reserved/illegal here, just encodings corresponding to vector instructions
    switch(ins.x(0, 7)) {
        case 0x7: // OPCODE 000 0111 - FP-LOAD - Vector loads
        case 0x27: // OPCODE 010 0111 - FP-STORE - Vector stores
            return (ins.v_width() == 0 or ins.v_width() == 5 or ins.v_width() == 6 or ins.v_width() == 7);
        case 0x57: // OPCODE 010 1111 - OP-V - Vector arithmetic
            return true;
        default:
            return false;
    }
}

void spike_wrapper::copy_vector_reg_file(processor_t* core) {
    memcpy(this->vector_reg_file, core->VU.reg_file, (NVPR * (VLEN/8)));
}

void spike_wrapper::save_scalar_state(processor_t* core, core_state_t* core_state) {
    insn_t ins = core_state->ins;
    state_t* p_state = core->get_state();

    int rd = ins.x(7,5);
    int opcode = ins.x(0,7);
    int rs1 = ins.rs1();
    int rs2 = ins.rs2();

    if (p_state != NULL) {

        core_state->dst_value = p_state->XPR[rd];
        core_state->src1_value  = this->XPR[rs1];
        core_state->src2_value  = this->XPR[rs2];
        core_state->csr.frm    = p_state->frm->read();
        core_state->csr.fflags = p_state->last_fflags;
        core_state->csr.mstatus= p_state->mstatus->read();
        p_state->last_fflags = 0;
    }
    else {
        core_state->csr.fflags = 0;
    }
    core_state->csr.trap_illegal = core->trap_illegal;

}

csr_vlmul_t spike_wrapper::encode_vlmul(float vflmul) {
    if (vflmul == 0.125f) return csr_vlmul_t::VFLMUL8;
    if (vflmul == 0.25f ) return csr_vlmul_t::VFLMUL4;
    if (vflmul == 0.5f  ) return csr_vlmul_t::VFLMUL2;
    if (vflmul == 1.f   ) return csr_vlmul_t::VLMUL1;
    if (vflmul == 2.f   ) return csr_vlmul_t::VLMUL2;
    if (vflmul == 4.f   ) return csr_vlmul_t::VLMUL4;
    if (vflmul == 8.f   ) return csr_vlmul_t::VLMUL8;
    return csr_vlmul_t::RESERVED;
}

void spike_wrapper::save_vector_state(processor_t* core, core_state_t* core_state) {
    insn_t ins = core_state->ins;
    state_t* p_state = core->get_state();

    int rd = ins.x(7,5);
    int opcode = ins.x(0,7);
    int vs1 = ins.x(15, 5);
    int vs2 = ins.x(20, 5);
    int vs3 = ins.x(7, 5);
    int vmask = 0; // Mask register (always v0)

    const int vlen = (int)(core->VU.get_vlen()) >> 3;
    const int elen = (int)(core->VU.get_elen()) >> 3;

    const int num_elem = vlen / elen;

    core_state->csr.vstart       = core->VU.vstart->read();
    core_state->csr.vxrm         = core->VU.vxrm->read();
    core_state->csr.vxsat        = core->VU.last_vxsat;
    core_state->csr.vlmul        = encode_vlmul(core->VU.vflmul);
    core_state->csr.vsew         = core->VU.vsew;
    core_state->csr.vill         = (core_state->csr.vsew > 64 ) ? 1 : core->VU.vill;
    core_state->csr.trap_illegal = (core_state->csr.vsew > 64 ) ? 1 : core_state->csr.trap_illegal;
    core_state->csr.vl           = core->VU.vl->read();
    core_state->csr.vta          = core->VU.vta;
    core_state->csr.vma          = core->VU.vma;

    core_state->disasm = (char*) malloc(sizeof(char)*128);

    char * tmp = new char[128];
    strcpy(tmp , core->get_disassembler()->disassemble(ins).c_str());
    strcpy(core_state->disasm, tmp);

    //std::cout<<"SPIKE SENT INSTRUCTION "<<core_state->disasm<<" CSTRING "<<tmp<<std::endl;

    fpr f_rs1, f_dst;
    f_rs1.r = core->get_state()->FPR[ins.rs1()];
    f_dst.r = core->get_state()->FPR[rd];
    bool fp_dest = (ins.x(12, 3) == 0x1);
    bool fp_src = (ins.x(12, 3) == 0x5);

    // TODO treat when vd is v0
    // Note that we don't support 128 bits
        switch (core_state->csr.vsew) {
            case e64:
                if (fp_src)  core_state->src1_value = f64(f_rs1.r).v;
                if (fp_dest) core_state->dst_value = f_dst.r.v[0];
                break;
        case e16:
        case e8:
        case e32:
                if (fp_src)  core_state->src1_value = f64(f_rs1.r).v;
                if (fp_dest) core_state->dst_value = isBoxedF32(f_dst.r) ? f_dst.r.v[0] : defaultNaNF32UI;
        }

        // Only for vfmv.s.f
        if (ins.x(26, 6) == 0xd and ins.x(12, 3) == 0x5) {
            if (core->get_flen() == 64) {
                core_state->src1_value = f64(f_rs1.r).v;
                core_state->dst_value = f64(f_dst.r).v;
            }
            else {
                core_state->src1_value = f64(f_rs1.r).v;
                core_state->dst_value = f32(f_dst.r).v;
            }
        }

    if (core_state->csr.vl > 0 && !core_state->csr.trap_illegal && is_fp_reduction_ins(core_state->ins)) {

        reduction(((uint64_t*)vector_reg_file)[vs1*num_elem], core_state->ins,
                    core_state->csr.vsew, core_state->csr.vl,
                    core_state->csr.frm,
                    (const uint64_t*) &((uint64_t*) vector_reg_file)[0], // vmask is always reg 0
                    (const uint64_t*) &((uint64_t*) vector_reg_file)[vs2*num_elem],
                    (uint64_t*) &((uint64_t*)core->VU.reg_file)[rd*num_elem],
                    (uint8_t*) &core_state->csr.fflags, 1,1, reduction_tree_enable, core_state->pc);
    }
}



int spike_wrapper::run_until_vector_ins(core_state_t* core_state) {
    sim_t* sim = s;
    uint64_t prev_src1_value, prev_src2_value;
    processor_t* core = s->get_core(0);

    // State before executing the instruction
    state_t* p_state = core->get_state();

    // Get the register file before destination register is overwritten
    copy_vector_reg_file(core);
    copy_regs_from_state(p_state)
    reg_t pc = core->get_state()->pc;
    reg_t prev_pc = pc;

    // Maybe we could use check_exit_code inside step
    s->step(1);
    check_exit_code(sim->exit_code());
    insn_t ins = core->get_state()->current_instruction;
    pc = core->get_state()->pc;
    //reg_t prev_pc = pc;
    prev_src1_value = core->get_state()->XPR[ins.rs1()];
    prev_src2_value = core->get_state()->XPR[ins.rs2()];

    core = sim->get_core(0);
    //printf("pc: %x ins: %x\n", prev_pc, ins.bits());

    while(is_not_vector(ins) || core->get_state()->prv == PRV_S || (core->trap_instr && core_state->csr.trap_illegal)) {
      if (not SMD_mode and (uint32_t)ins.bits() == 0xc00022f3)
        return 0;
      if (SMD_mode and (uint32_t)ins.bits() == 0x00000073)
        return 0;
      uint64_t tohost;
      tohost = s->from_target(s->memif().read_uint64(s->get_tohost_addr()));
      if( tohost  ){
        //printf("TOHOST HAS BEEN WRITTEN\n");
        return 0;
      }
      copy_vector_reg_file(core);
      copy_regs_from_state(core->get_state())
      prev_src1_value = core->get_state()->XPR[ins.rs1()];
      prev_src2_value = core->get_state()->XPR[ins.rs2()];
      s->step(1);
      check_exit_code(sim->exit_code());
      ins = core->get_state()->current_instruction;
      prev_pc = pc;
      pc = core->get_state()->pc;
        //printf("prev_pc: %x pc: %x ins: %x\n", prev_pc, pc, ins.bits());
    }
    memif_t mem = s->memif();


    core_state->pc  = prev_pc;
    core_state->ins = ins.bits();
    core_state->dst_num     = ins.rd();
    core_state->dst_value   = core->get_state()->XPR[ins.rd()];
    core_state->src1_num    = ins.rs1();
    core_state->src1_value  = (ins.rs1() == ins.rd()) ? prev_src1_value : core->get_state()->XPR[ins.rs1()]; //if (ins.rs1() == ins.rd()) src1_value = prev_src1_value;
    core_state->src2_num    = ins.rs2();
    core_state->src2_value  = (ins.rs2() == ins.rd()) ? prev_src2_value : core->get_state()->XPR[ins.rs2()]; //if (ins.rs2() == ins.rd()) src2_value = prev_src2_value;
    //when are srcX_values valid?
    /*
    OPIVV no scalar
    OPFVV no scalar
    OPMVV no scalar
    OPIVI no scalar
    OPIVX 1 scalar
    OPFVF 1 scalar
    OPMVX 1 scalar
    OPCFG 1/2 scalars


    OPIVV, OMVV, OPFVV, OPIVI -> no scalar
    OPVX, OPVFV 1 scalar
    el de config (vsetvl) uno (o dos)
    las de memoria van por otro lado. Tienen uno por lo menos, pero pueden tener 2 (si son strided)
    */
    uint64_t funct3 = ins.x(12,3);
    uint64_t opcode = ins.x(0,7);
    uint64_t funct6 = ins.x(26, 6);
    uint64_t mop = ins.x(26, 3);

    if (opcode == 0x57){ //OPV, for vector arithmetic instructions
      switch(funct3){
        case OPIVV:
        case OPFVV:
        case OPIVI:
          core_state->src1_valid = 0;
          core_state->src2_valid = 0;
          break;
        case OPIVX:
        case OPFVF:
        case OPMVX:
          core_state->src1_valid = 1;
          core_state->src2_valid = 0;
          break;
        //check for vext
        case OPMVV:
          core_state->src2_valid = 0;
          if( funct6 == 0xc ) //001100
            core_state->src1_valid = 1;
          else
            core_state->src1_valid = 0;
          break;
        case OPCFG:
          //needs to check for vsetvl/vsetvli
          core_state->src1_valid = 1;
          if(ins.x(31,1)){ //vsetvl
            core_state->src2_valid = 1;
          }
          else{ //vsetvli
            core_state->src2_valid = 0;
          }
          break;
          default:
            core_state->src1_valid = 0;
            core_state->src2_valid = 0;
          break;
      }
    } else if ((opcode == 0x07) || (opcode ==0x27)) {
        core_state->src1_valid = 1;
        core_state->src2_valid = ((mop == 0x2) || (mop == 0x6));
    }

    save_scalar_state(core, core_state);

    save_vector_state(core, core_state);


    if(core->trap_instr and ! core_state->csr.trap_illegal ){
        std::cout << std::hex << "[SPIKE-DPI] Spike error in INS: " << ins.bits() << std::endl;
         return TEST_ERROR;
    }
    if(core->trap_illegal){
       // std::cout << std::hex << "[SPIKE-DPI] [ " << prev_pc << " ] Illegal instruction on INS: " << ins.bits() << std::endl;
        if(const char* env_p = std::getenv("EXIT_ON_ILLEGAL")) {
            int mode = atoi(env_p);
            if (mode){
                return ILLEGAL_INSTR;
            }
        }
    }

    //this->print_core_state(core_state);
    //std::cout<<"SPIKE SENT INSTRUCTION "<<core_state->disasm<<" CSTRING "<<(char*)core->get_disassembler()->disassemble(ins).c_str()<<std::endl;
    return !s->done();
}

// rgenovese - aipcd lab2 ---------------------------------------------------------

bool spike_wrapper::is_not_rgb2yuv(insn_t ins) {
    //check if the instruction is rgb2yub
    //return result negated
    int opcode, funct7, funct3;
    opcode = ins.x(0,7);

    if( opcode == MATCH_CUSTOM1 ){
        return false;
    }
    return true;
}

int spike_wrapper::run_until_rgb2yuv_instruction(core_state_t* core_state) {
    sim_t* sim = s;
    uint64_t prev_src1_value, prev_src2_value;
    processor_t* core = s->get_core(0);

    // State before executing the instruction
    state_t* p_state = core->get_state();

    // Get the register file before destination register is overwritten
    copy_vector_reg_file(core);
    copy_regs_from_state(p_state)
    reg_t pc = core->get_state()->pc;
    reg_t prev_pc = pc;

    // Maybe we could use check_exit_code inside step
    s->step(1);
    check_exit_code(sim->exit_code());
    insn_t ins = core->get_state()->current_instruction;
    pc = core->get_state()->pc;
    //reg_t prev_pc = pc;
    prev_src1_value = core->get_state()->XPR[ins.rs1()];
    prev_src2_value = core->get_state()->XPR[ins.rs2()];

    core = sim->get_core(0);
    //printf("pc: %x ins: %x\n", prev_pc, ins.bits());

    while(is_not_rgb2yuv(ins) || core->get_state()->prv == PRV_S || (core->trap_instr && core_state->csr.trap_illegal)) {
        if (not SMD_mode and (uint32_t)ins.bits() == 0xc00022f3)
            return 0;
        if (SMD_mode and (uint32_t)ins.bits() == 0x00000073)
            return 0;
        uint64_t tohost;
        tohost = s->from_target(s->memif().read_uint64(s->get_tohost_addr()));
        if( tohost  ){
            //printf("TOHOST HAS BEEN WRITTEN\n");
            return 0;
        }
        copy_vector_reg_file(core);
        copy_regs_from_state(core->get_state())
        prev_src1_value = core->get_state()->XPR[ins.rs1()];
        prev_src2_value = core->get_state()->XPR[ins.rs2()];
        s->step(1);
        check_exit_code(sim->exit_code());
        ins = core->get_state()->current_instruction;
        prev_pc = pc;
        pc = core->get_state()->pc;
        //printf("prev_pc: %x pc: %x ins: %x\n", prev_pc, pc, ins.bits());
    }
    memif_t mem = s->memif();


    core_state->pc  = prev_pc;
    core_state->ins = ins.bits();
    core_state->dst_num     = ins.rd();
    core_state->dst_value   = core->get_state()->XPR[ins.rd()];
    core_state->src1_num    = ins.rs1();
    core_state->src1_value  = (ins.rs1() == ins.rd()) ? prev_src1_value : core->get_state()->XPR[ins.rs1()]; //if (ins.rs1() == ins.rd()) src1_value = prev_src1_value;
    core_state->src2_num    = ins.rs2();
    core_state->src2_value  = (ins.rs2() == ins.rd()) ? prev_src2_value : core->get_state()->XPR[ins.rs2()]; //if (ins.rs2() == ins.rd()) src2_value = prev_src2_value;
    
    uint64_t funct3 = ins.x(12,3);
    uint64_t opcode = ins.x(0,7);
    uint64_t funct6 = ins.x(26, 6);
    uint64_t mop = ins.x(26, 3);

    if (opcode == 0x57){ //OPV, for vector arithmetic instructions
      switch(funct3){
        case OPIVV:
        case OPFVV:
        case OPIVI:
          core_state->src1_valid = 0;
          core_state->src2_valid = 0;
          break;
        case OPIVX:
        case OPFVF:
        case OPMVX:
          core_state->src1_valid = 1;
          core_state->src2_valid = 0;
          break;
        //check for vext
        case OPMVV:
          core_state->src2_valid = 0;
          if( funct6 == 0xc ) //001100
            core_state->src1_valid = 1;
          else
            core_state->src1_valid = 0;
          break;
        case OPCFG:
          //needs to check for vsetvl/vsetvli
          core_state->src1_valid = 1;
          if(ins.x(31,1)){ //vsetvl
            core_state->src2_valid = 1;
          }
          else{ //vsetvli
            core_state->src2_valid = 0;
          }
          break;
          default:
            core_state->src1_valid = 0;
            core_state->src2_valid = 0;
          break;
      }
    } else if ((opcode == 0x07) || (opcode ==0x27)) {
        core_state->src1_valid = 1;
        core_state->src2_valid = ((mop == 0x2) || (mop == 0x6));
    }

    save_scalar_state(core, core_state);

    save_vector_state(core, core_state);


    if(core->trap_instr and ! core_state->csr.trap_illegal ){
        std::cout << std::hex << "[SPIKE-DPI] Spike error in INS: " << ins.bits() << std::endl;
         return TEST_ERROR;
    }
    if(core->trap_illegal){
       // std::cout << std::hex << "[SPIKE-DPI] [ " << prev_pc << " ] Illegal instruction on INS: " << ins.bits() << std::endl;
        if(const char* env_p = std::getenv("EXIT_ON_ILLEGAL")) {
            int mode = atoi(env_p);
            if (mode){
                return ILLEGAL_INSTR;
            }
        }
    }

    //this->print_core_state(core_state);
    //std::cout<<"SPIKE SENT INSTRUCTION "<<core_state->disasm<<" CSTRING "<<(char*)core->get_disassembler()->disassemble(ins).c_str()<<std::endl;
    return !s->done();
}
// ------------------------------------------------------------------------------------

void print_core_state(core_state_t* core_state) {

    std::cout << std::hex << core_state->pc << " " <<
               std::hex << core_state->ins << " " <<
               std::hex << core_state->dst_value << " " <<
               std::hex << core_state->dst_num << " " <<
               std::hex << core_state->src1_value << " " <<
               std::hex << core_state->src1_num << " " <<
               std::hex << core_state->src2_value << " " <<
               std::hex << core_state->src2_num << " " <<
               std::hex << core_state->disasm << " " <<
               std::hex << core_state->exc_bit << " " <<
               std::hex << core_state->vaddr << " " <<
               std::hex << core_state->store_data << " " <<
               std::hex << core_state->csr.frm << " " <<
               std::hex << core_state->csr.fflags << " " <<
               std::hex << core_state->csr.trap_illegal << " " <<
            //   std::hex << core_state->csr.mcause << " " <<
            //   std::hex << core_state->csr.scause << " " <<
               std::endl;

}

void spike_wrapper::set_csr_fflags(reg_t val) {
  processor_t* core = s->get_core(0);
  state_t* p_state = core->get_state();
  p_state->fflags->write(val);
}

void spike_wrapper::set_dest_reg(int reg_dst, reg_t val) {
  processor_t* core = s->get_core(0);
  state_t* p_state = core->get_state();
  uint64_t v;
  v = val;
  p_state->XPR.write(reg_dst,v);
  this->XPR[reg_dst] = val;
  fprintf(stdout, "UPDATING DST_REG[%d] with value %lx - RESULT %lx \n", reg_dst, val, p_state->XPR[reg_dst]);
}

void spike_wrapper::set_fp_reg(int reg_dst, reg_t val) {
  processor_t* core = s->get_core(0);
  state_t* p_state = core->get_state();
  float128_t v;
  v.v[1] = p_state->FPR[reg_dst].v[1];
  v.v[0] = val;
  p_state->FPR.write(reg_dst,v);
  this->FPR[reg_dst].v[0] = val;
  //fprintf(stdout, "UPDATING FP REG[%d] with value %lx - RESULT %lx \n", reg_dst, val, p_state->FPR[reg_dst]);
}

reg_t spike_wrapper::address_translate(reg_t addr, reg_t len, access_type type, reg_t satp, reg_t priv_lvl, reg_t mstatus, reg_t* exc_error) {
    sim_t* sim = s;
    processor_t* core = s->get_core(0);
    reg_t input = addr;
    reg_t res;
    res = core->get_mmu()->tlb_translate( (reg_t) input, (reg_t) len, (access_type) type, (reg_t) satp, (reg_t) priv_lvl, (reg_t) mstatus, (reg_t*) exc_error);

    return res;
}


int main(int argc, const char **argv) {
    spike_wrapper *spike;
    spike = new spike_wrapper();
    spike->setup (argc, argv);
    spike->start_execution();
}
