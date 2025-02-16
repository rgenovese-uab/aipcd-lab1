// vssrl.vv vd, vs2, vs1
require(P.core_type != SARGANTANA);
VRM xrm = P.VU.get_vround_mode();
VI_VV_ULOOP
({
  int sh = vs1 & (sew - 1);
  uint128_t val = vs2;

  INT_ROUNDING(val, xrm, sh);
  vd = val >> sh;
})
