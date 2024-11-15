#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "core_type.h"

core_type_t core_type_from_string(const char* s){
    if (strcasecmp(s, "STANDARD") == 0) return STANDARD;
    else if (strcasecmp(s, "SARGANTANA") == 0) return SARGANTANA;
    else if (strcasecmp(s, "LAGARTO_KA") == 0) return LAGARTO_KA;
    else if (strcasecmp(s, "LAGARTO_OX") == 0) return LAGARTO_OX;
    else if (strcasecmp(s, "VPU") == 0) return VPU;
    else {
        fprintf(stderr, "Unknown core type (%s)\n", s);
        exit(-1);
    }
}
