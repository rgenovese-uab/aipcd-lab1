// vfncvt.f.xu.v vd, vs2, vm
require(P.core_type != SARGANTANA);
require(!P.is_vpu() || P.VU.vsew == e32);
VI_VFP_NCVT_INT_TO_FP(
  {;},                              // BODY16
  { vd = ui32_to_f16(vs2); },       // BODY32
  { vd = ui64_to_f32(vs2); },       // BODY64
  {;},                              // CHECK16
  { require_extension(EXT_ZVFH); }, // CHECK32
  { require_extension('F'); },      // CHECK64
  uint                              // sign
)
