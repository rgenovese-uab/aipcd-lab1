#include "bf16.h"
#include "cpfloat_binary32.h"

float16_t bf16_add (float16_t s0, float16_t s1) {

    FUNC_2SRC(cpf_addf)

}

float16_t bf16_sub (float16_t s0, float16_t s1) {

    FUNC_2SRC(cpf_subf)

}

float16_t bf16_mul (float16_t s0, float16_t s1) {

    FUNC_2SRC(cpf_mulf)

}

float16_t bf16_mulAdd (float16_t s0, float16_t s1, float16_t s2) {

    FUNC_3SRC(cpf_fmaf)

}

float16_t bf16_div (float16_t s0, float16_t s1) {

    FUNC_2SRC(cpf_divf)

}

float16_t bf16_sqrt (float16_t s0) {

    FUNC_1SRC(cpf_sqrtf)

}

float16_t bf16_min (float16_t s0, float16_t s1) {

    FUNC_2SRC(cpf_fminf)

}

float16_t bf16_max (float16_t s0, float16_t s1) {

    FUNC_2SRC(cpf_fmaxf)

}

uint_fast16_t bf16_classify(float16_t s0) {

    bool inf_or_NaN        = (exp_bf16(s0.v) == 0xFF);
    bool subnormal_or_zero = (exp_bf16(s0.v) == 0);
    bool sign              = sign_bf16(s0.v);
    bool mant_zero         = (mant_bf16(s0.v) == 0);
    bool isNaN             = inf_or_NaN && !mant_zero;
    bool isSNaN            = inf_or_NaN && get_bit(s0.v, 14);

      return
        (  sign && inf_or_NaN && mant_zero )           << 0 |
        (  sign && !inf_or_NaN && !subnormal_or_zero ) << 1 |
        (  sign && subnormal_or_zero && !mant_zero )   << 2 |
        (  sign && subnormal_or_zero && mant_zero )    << 3 |
        ( !sign && subnormal_or_zero && mant_zero )    << 4 |
        ( !sign && subnormal_or_zero && !mant_zero )   << 5 |
        ( !sign && !inf_or_NaN && !subnormal_or_zero ) << 6 |
        ( !sign && inf_or_NaN && mant_zero )           << 7 |
        ( isNaN &&  isSNaN )                           << 8 |
        ( isNaN && !isSNaN )                           << 9;
}

float16_t f32_to_bf16(float32_t s0) {

    float16_t vd;

    vd.v = float16_tO_FP32_BITS(s0.v);

    return vd;

}

float32_t bf16_to_f32(float16_t s0) {

    float32_t vd;

    vd.v = FP32_TO_BF16_BITS(s0.v);

    return vd;

}

int_fast16_t bf16_to_i16(float16_t s0) {

    INIT_CPFLOAT

    int *excp = excp;

    union bf16_u r0;
    r0.ui = float16_tO_FP32_BITS(s0.v);

    int_fast16_t dst = dst;

    cpf_lrintf(&dst, excp, &r0.f, 1, fpopts);

    dst = dst & 0xFFFF;

    free_optstruct(fpopts);

    return dst;

}