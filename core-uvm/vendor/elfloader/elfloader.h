// See LICENSE for license details.

#ifndef _ELFLOADER_H
#define _ELFLOADER_H

#include "elf.h"
#include <map>
#include <string>


class memif_t;
std::map<std::string, uint64_t> load_elf(const char* fn, memif_t* memif, reg_t* entry);

extern "C" void read_elf(const char* filename);
extern "C" void read_section(long long address, const svOpenArrayHandle buffer);
extern "C" char get_section(long long* address, long long* len);

#endif
