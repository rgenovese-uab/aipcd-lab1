#ifndef _RISCV_CORE_TYPE
#define _RISCV_CORE_TYPE

#include <stdlib.h>
#include <map>
#include <string>

typedef enum {
    STANDARD,
    SARGANTANA,
    LAGARTO_KA,
    LAGARTO_OX,
    VPU
} core_type_t;

typedef std::map<std::string, core_type_t> core_type_map_t;

core_type_t core_type_from_string(const char* s);

#endif
