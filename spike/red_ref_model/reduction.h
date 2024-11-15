#include "reduction_op.h"

extern "C" void reduction(const uint64_t scalar, const uint32_t ins,
                          const uint32_t vsew, const uint32_t vl,
                          const uint32_t frm, const uint64_t *vmask,
                          const uint64_t *vs2, uint64_t *vd,
                          uint_fast8_t *fflagsi, int verb_lvl,
                          int act_verb_lvl, char tree_merge_enable, uint64_t pc);

extern "C" void setup_reduction(const char *path, uint64_t lane_num,
                                uint64_t accum_num_fp, uint64_t accum_num_int);
