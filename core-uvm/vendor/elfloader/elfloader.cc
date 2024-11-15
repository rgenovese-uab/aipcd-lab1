#include "elf.h"
#include "memif.h"
#include "byteorder.h"
#include <svdpi.h>
#include <cstring>
#include <string>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <vector>
#include <map>
#include <iostream>

std::vector<std::pair<uint64_t, uint64_t>> sections;
std::map<std::string, uint64_t> symbols;
std::map<reg_t, std::vector<uint8_t>> mems;
int section_index = 0;
reg_t entry;

typedef struct {
    char* name;
    long int addr;
} sym_t;

#define SHT_PROGBITS 0x1
#define SHT_GROUP 0x11

void write(uint64_t address, uint64_t len, uint8_t* buf) {
    uint64_t datum;
    std::vector<uint8_t> mem;

    for (int i = 0; i < len; i++) {
        mem.push_back(buf[i]);
    }
    mems.insert(std::make_pair(address, mem));
}

extern "C" char get_section(long long* address, long long* len) {
    if (section_index < sections.size()) {
        *address = sections[section_index].first;
        *len = sections[section_index].second;
        section_index++;
        return 1;
    }

    return 0;
}

extern "C" void read_section(long long address, const svOpenArrayHandle buffer) {

    void* buf = svGetArrayPtr(buffer);
    assert(mems.count(address) > 0);

    int i = 0;
    for (auto &datum : mems.find(address)->second) {
        *((char *) buf + i) = datum;
        i++;
    }

}

extern "C" void read_elf(const char* fn) {

  int fd = open(fn, O_RDONLY);
  struct stat s;
  assert(fd != -1);
  if (fstat(fd, &s) < 0)
    abort();
  size_t size = s.st_size;

  char* buf = (char*)mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
  assert(buf != MAP_FAILED);
  close(fd);

  assert(size >= sizeof(Elf64_Ehdr));
  const Elf64_Ehdr* eh64 = (const Elf64_Ehdr*)buf;
  assert(IS_ELF32(*eh64) || IS_ELF64(*eh64));
  assert(IS_ELFLE(*eh64));
  assert(IS_ELF_EXEC(*eh64));
  assert(IS_ELF_RISCV(*eh64) || IS_ELF_EM_NONE(*eh64));
  assert(IS_ELF_VCURRENT(*eh64));

  std::vector<uint8_t> zeros;

  #define LOAD_ELF(ehdr_t, phdr_t, shdr_t, sym_t, bswap) do { \
    ehdr_t* eh = (ehdr_t*)buf; \
    phdr_t* ph = (phdr_t*)(buf + bswap(eh->e_phoff)); \
    entry = bswap(eh->e_entry); \
    assert(size >= bswap(eh->e_phoff) + bswap(eh->e_phnum)*sizeof(*ph)); \
    for (unsigned i = 0; i < bswap(eh->e_phnum); i++) {			\
      if(bswap(ph[i].p_type) == PT_LOAD && bswap(ph[i].p_memsz)) {	\
        if (bswap(ph[i].p_filesz)) {					\
          assert(size >= bswap(ph[i].p_offset) + bswap(ph[i].p_filesz)); \
          sections.push_back(std::make_pair(ph[i].p_paddr, ph[i].p_memsz)); \
          write(bswap(ph[i].p_paddr), bswap(ph[i].p_filesz), (uint8_t*)buf + bswap(ph[i].p_offset)); \
        } \
        zeros.resize(bswap(ph[i].p_memsz) - bswap(ph[i].p_filesz)); \
      } \
    } \
    shdr_t* sh = (shdr_t*)(buf + bswap(eh->e_shoff)); \
    assert(size >= bswap(eh->e_shoff) + bswap(eh->e_shnum)*sizeof(*sh)); \
    assert(bswap(eh->e_shstrndx) < bswap(eh->e_shnum)); \
    assert(size >= bswap(sh[bswap(eh->e_shstrndx)].sh_offset) + bswap(sh[bswap(eh->e_shstrndx)].sh_size)); \
    char *shstrtab = buf + bswap(sh[bswap(eh->e_shstrndx)].sh_offset);	\
    unsigned strtabidx = 0, symtabidx = 0; \
    for (unsigned i = 0; i < bswap(eh->e_shnum); i++) {		     \
      unsigned max_len = bswap(sh[bswap(eh->e_shstrndx)].sh_size) - bswap(sh[i].sh_name); \
      assert(bswap(sh[i].sh_name) < bswap(sh[bswap(eh->e_shstrndx)].sh_size));	\
      assert(strnlen(shstrtab + bswap(sh[i].sh_name), max_len) < max_len); \
      if (bswap(sh[i].sh_type) & SHT_NOBITS) continue; \
      assert(size >= bswap(sh[i].sh_offset) + bswap(sh[i].sh_size)); \
      if (strcmp(shstrtab + bswap(sh[i].sh_name), ".strtab") == 0) \
        strtabidx = i; \
      if (strcmp(shstrtab + bswap(sh[i].sh_name), ".symtab") == 0) \
        symtabidx = i; \
    } \
    if (strtabidx && symtabidx) { \
      char* strtab = buf + bswap(sh[strtabidx].sh_offset); \
      sym_t* sym = (sym_t*)(buf + bswap(sh[symtabidx].sh_offset)); \
      for (unsigned i = 0; i < bswap(sh[symtabidx].sh_size)/sizeof(sym_t); i++) { \
        unsigned max_len = bswap(sh[strtabidx].sh_size) - bswap(sym[i].st_name); \
        assert(bswap(sym[i].st_name) < bswap(sh[strtabidx].sh_size));	\
        assert(strnlen(strtab + bswap(sym[i].st_name), max_len) < max_len); \
        symbols[strtab + bswap(sym[i].st_name)] = bswap(sym[i].st_value); \
      } \
    } \
  } while(0)

  if (IS_ELF32(*eh64))
    LOAD_ELF(Elf32_Ehdr, Elf32_Phdr, Elf32_Shdr, Elf32_Sym, from_le);
  else
    LOAD_ELF(Elf64_Ehdr, Elf64_Phdr, Elf64_Shdr, Elf64_Sym, from_le);

  munmap(buf, size);

#ifdef DEBUG
  std::cout << "sections" << std::endl;
  for ( auto section : sections){
      std::cout << section.first << " " << section.second << std::endl;
  }
  std::cout << "symbols" << std::endl;
  for( auto symbol : symbols){
      std::cout << symbol.first << " " << symbol.second << std::endl;
  }
#endif

}

extern "C" int get_symbol_addr(const char* name, uint64_t* addr) {
    auto entry = symbols.find(name);
    if (entry != symbols.end()){
        *addr = entry->second;
    }
    else
        *addr = 0x0;

#ifdef DEBUG
    std::cout << "symbol " << name << " " << addr << std::endl;
#endif

    return entry != symbols.end();
}

//int main(int argc, char **argv) {
//    int tohost_addr;
//    read_elf("../../ka_addi.o");
//    std::cout << "sections" << std::endl;
//    for ( auto section : sections){
//        std::cout << section.first << " " << section.second << std::endl;
//    }
//    std::cout << "symbols" << std::endl;
//    for( auto symbol : symbols){
//        std::cout << symbol.first << " " << symbol.second << std::endl;
//    }
//    get_symbol_addr("tohost", &tohost_addr);
//
//    std::cout << "TOHOST: " << std::hex << tohost_addr << std::endl;
//
//
//
//}
