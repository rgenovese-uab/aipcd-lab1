// vfmin vd, vs2, vs1
require(P.core_type != SARGANTANA);
VI_VFP_VV_LOOP
({
  vd = f16_min(vs2, vs1);
},
{
  vd = f32_min(vs2, vs1);
},
{
  vd = f64_min(vs2, vs1);
})
