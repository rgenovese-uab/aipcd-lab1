// vfcvt.x.f.v vd, vd2, vm
require(P.core_type != SARGANTANA);
VI_VFP_CVT_FP_TO_INT(
  { vd = f16_to_i16(vs2, softfloat_roundingMode, true); }, // BODY16
  { vd = f32_to_i32(vs2, softfloat_roundingMode, true); }, // BODY32
  { vd = f64_to_i64(vs2, softfloat_roundingMode, true); }, // BODY64
  int                                                      // sign
)
