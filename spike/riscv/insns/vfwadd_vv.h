// vfwadd.vv vd, vs2, vs1
require(P.core_type != SARGANTANA);
VI_VFP_VV_LOOP_WIDE
({
  vd = f32_add(vs2, vs1);
},
{
  vd = f64_add(vs2, vs1);
})
