// vfwsub.wv vd, vs2, vs1
require(P.core_type != SARGANTANA);
VI_VFP_WV_LOOP_WIDE
({
  vd = f32_sub(vs2, vs1);
},
{
  vd = f64_sub(vs2, vs1);
})
