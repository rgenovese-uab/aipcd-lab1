// vfmul.vv vd, vs1, vs2, vm
require(P.core_type != SARGANTANA);
VI_VFP_VV_LOOP
({
  vd = f16_mul(vs1, vs2);
},
{
  vd = f32_mul(vs1, vs2);
},
{
  vd = f64_mul(vs1, vs2);
})
