// vdivu.vv vd, vs2, vs1
require(P.core_type != SARGANTANA);
VI_VV_ULOOP
({
  if (vs1 == 0)
    vd = -1;
  else
    vd = vs2 / vs1;
})
