#include <stdint.h>
#include <stdbool.h>

#include "softfloat.h" // Includes "softfloat_types.h"

#ifdef __cplusplus
extern "C" {
#endif

#define REMAP_RND_MODE \
    switch(softfloat_roundingMode) { \
        case softfloat_round_near_even   : \
            rnd_mode = CPFLOAT_RND_NE;     \
            break; \
        case softfloat_round_minMag      : \
            rnd_mode = CPFLOAT_RND_TZ;     \
            break; \
        case softfloat_round_min         : \
            rnd_mode = CPFLOAT_RND_TN;     \
            break; \
        case softfloat_round_max         : \
            rnd_mode = CPFLOAT_RND_TP;     \
            break; \
        case softfloat_round_near_maxMag : \
            rnd_mode = CPFLOAT_RND_NA;     \
            break; \
        case softfloat_round_odd         : \
            rnd_mode = CPFLOAT_RND_OD;     \
            break; \
        default :  \
            rnd_mode = CPFLOAT_NO_RND; \
    }

#define INIT_CPFLOAT \
    cpfloat_rounding_t rnd_mode;\
    REMAP_RND_MODE \
    optstruct *fpopts = init_optstruct(); \
    fpopts->precision = 8; \
    fpopts->emax = 127; \
    fpopts->subnormal = CPFLOAT_SUBN_USE; \
    fpopts->round = rnd_mode; \
    fpopts->flip = CPFLOAT_NO_SOFTERR; \
    fpopts->p = 0; \
    fpopts->explim = CPFLOAT_EXPRANGE_TARG; \
    int retval = cpfloat_validate_optstructf(fpopts);

#define FUNC_1SRC(F) \
    INIT_CPFLOAT \
    union bf16_u r0; \
    union bf16_u dst; \
    r0.ui = float16_tO_FP32_BITS(s0.v); \
    F(&dst.f, &r0.f, 1, fpopts); \
    float16_t vd; \
    vd.v = FP32_TO_BF16_BITS(dst.ui); \
    free_optstruct(fpopts); \
    return vd;

#define FUNC_2SRC(F) \
    INIT_CPFLOAT \
    union bf16_u r0; \
    union bf16_u r1; \
    union bf16_u dst; \
    r0.ui = float16_tO_FP32_BITS(s0.v); \
    r1.ui = float16_tO_FP32_BITS(s1.v); \
    F(&dst.f, &r0.f, &r1.f, 1, fpopts); \
    float16_t vd; \
    vd.v = FP32_TO_BF16_BITS(dst.ui); \
    free_optstruct(fpopts); \
    return vd;

#define FUNC_3SRC(F) \
    INIT_CPFLOAT \
    union bf16_u r0; \
    union bf16_u r1; \
    union bf16_u r2; \
    union bf16_u dst; \
    r0.ui = float16_tO_FP32_BITS(s0.v); \
    r1.ui = float16_tO_FP32_BITS(s1.v); \
    r2.ui = float16_tO_FP32_BITS(s2.v); \
    F(&dst.f, &r0.f, &r1.f, &r2.f, 1, fpopts); \
    float16_t vd; \
    vd.v = FP32_TO_BF16_BITS(dst.ui); \
    free_optstruct(fpopts); \
    return vd;

#define sign_bf16(bf16) ((bool) ((uint16_t) bf16 >> 15))
#define  exp_bf16(bf16) ((uint16_t) (bf16 >> 7) & 0xFF)
#define mant_bf16(bf16) (bf16 & 0x7F)

#define get_bit(v,b) (bool) ((v >> b) & 1)

#define float16_tO_FP32_BITS(bf16) ((((uint32_t) bf16) << 16) & 0xffff0000)
#define FP32_TO_BF16_BITS(bf16) (uint16_t) (bf16 >> 16)

union bf16_u { uint32_t ui; float f; };

float16_t bf16_add (float16_t s0, float16_t s1);
float16_t bf16_sub (float16_t s0, float16_t s1);
float16_t bf16_mul (float16_t s0, float16_t s1);
float16_t bf16_mulAdd (float16_t s0, float16_t s1, float16_t s2);
float16_t bf16_div (float16_t s0, float16_t s1);
float16_t bf16_sqrt (float16_t s0);
float16_t bf16_min (float16_t s0, float16_t s1);
float16_t bf16_max (float16_t s0, float16_t s1);
uint_fast16_t bf16_classify(float16_t s0);
float16_t f32_to_bf16(float32_t s0);
float32_t bf16_to_f32(float16_t s0);
int_fast16_t bf16_to_i16(float16_t s0);

#ifdef __cplusplus
}
#endif
