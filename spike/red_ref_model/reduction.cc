#include "reduction.h"

#include <iostream>

reduction_op reduction_v;

void v64_to_v8(const uint64_t *v64, uint8_t *v8, uint32_t vl, int sew) {
    uint64_t v8_count = 0;
    for (uint64_t i = 0; i < ((vl + (8 / sew) - 1) / (8 / sew)); ++i) {
        for (int j = 0; j < 8 and v8_count < vl * sew; ++j) {
            v8[v8_count] = ((v64[i] >> (j * 8)) % 256);
            ++v8_count;
        }
    }
}

extern "C" void reduction(const uint64_t scalar, const uint32_t ins,
                          const uint32_t vsew, const uint32_t vl,
                          const uint32_t frm, const uint64_t *vmask,
                          const uint64_t *vs2, uint64_t *vd,
                          uint_fast8_t *fflagsi, int act_verb_lvl,
                          int verb_lvl, char tree_merge_enable, const uint64_t pc) {
    uint8_t vs[vl * vsew / 8];
    uint8_t mask[vl * vsew / 8];
    v64_to_v8(vs2, vs, vl, vsew / 8);
    v64_to_v8(vmask, mask, vl, vsew / 8);
    reduction_v.reduction_setup(vsew, vl, scalar, vs, mask, ins, frm, verb_lvl,
                                act_verb_lvl, tree_merge_enable, pc);
    
    // Assign SEW bits of result (either 32 or 64 bits)
    *vd = (( 0xFFFFFFFFFFFFFFFFul >> (64 - reduction_v.get_dec_result_sew()) ) & reduction_v.do_reduction());

    // Apply tail agnostic policy to the ELEN-SEW bits
    *vd = (~( 0xFFFFFFFFFFFFFFFFul >> (64 - reduction_v.get_dec_result_sew()) )) | (*vd);

    *fflagsi = reduction_v.get_fflags();
    return;
}

extern "C" void setup_reduction(const char *path, uint64_t lane_num,
                                uint64_t accum_num_fp, uint64_t accum_num_int) {
    reduction_v.set_accum_num(accum_num_fp, accum_num_int);
    reduction_v.set_lane_num(lane_num);
    reduction_v.set_up_log(path);
}
