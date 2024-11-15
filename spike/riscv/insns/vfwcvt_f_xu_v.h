// vfwcvt.f.xu.v vd, vs2, vm
require(P.core_type != SARGANTANA);
require(!P.is_vpu() || P.VU.vsew == e32);
VI_VFP_WCVT_INT_TO_FP(
  { vd = ui32_to_f16(vs2); },                    // BODY8
  { vd = ui32_to_f32(vs2); },                    // BODY16
  { vd = ui32_to_f64(vs2); },                    // BODY32
  { require(p->extension_enabled(EXT_ZVFH)); },  // CHECK8
  { require_extension('F'); },                   // CHECK16
  { require_extension('D'); },                   // CHECK32
  uint                                           // sign
)
