// vdivu.vx vd, vs2, rs1
require(P.core_type != SARGANTANA);
VI_VX_ULOOP
({
  if (rs1 == 0)
    vd = -1;
  else
    vd = vs2 / rs1;
})
