// vfwcvt.rtz.x.f.v vd, vs2, vm
require(P.core_type != SARGANTANA);
require(!P.is_vpu() || P.VU.vsew == e32);
VI_VFP_WCVT_FP_TO_INT(
  {;},                                                     // BODY8
  { vd = f16_to_i32(vs2, softfloat_round_minMag, true); }, // BODY16
  { vd = f32_to_i64(vs2, softfloat_round_minMag, true); }, // BODY32
  {;},                                                     // CHECK8
  { require_extension(EXT_ZVFH); },                        // CHECK16
  { require_extension('F'); },                             // CHECK32
  int                                                      // sign
)
