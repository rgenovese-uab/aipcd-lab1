// vfwcvt.f.f.v vd, vs2, vm
require(P.core_type != SARGANTANA);
require(!P.is_vpu() || P.VU.vsew == e32);
VI_VFP_WCVT_FP_TO_FP(
  {;},                                 // BODY8
  { vd = f16_to_f32(vs2); },           // BODY16
  { vd = f32_to_f64(vs2); },           // BODY32
  {;},                                 // CHECK8
  { require_extension(EXT_ZVFHMIN); }, // CHECK16
  { require_extension('D'); }          // CHECK32
)
