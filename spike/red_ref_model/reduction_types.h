#ifndef REDUCTION_TYPES_H
#define REDUCTION_TYPES_H

extern "C" {
#include "softfloat.h"
}
#include <vector>

union elem {
    uint64_t val;
    float16_t half_val;
    float32_t float_val;
    float64_t double_val;
};

struct accum_part {
    bool init;
    elem value;
};

typedef std::vector<accum_part> accum;

struct lane {
    uint8_t act_accum;
    std::vector<accum> accums;
};

struct instr {
    bool is_masking;
    bool is_widening;
    bool is_fp;
    bool is_unordered;
    bool is_unsigned;
    uint8_t funct3;
    uint8_t funct6;
    uint64_t pc;
};

struct reduction_return {
    uint64_t result;
    uint_fast8_t fflags;
};

#endif
