// vsqrt.v vd, vd2, vm
require(P.core_type != SARGANTANA);
VI_VFP_V_LOOP
({
  vd = f16_sqrt(vs2);
},
{
  vd = f32_sqrt(vs2);
},
{
  vd = f64_sqrt(vs2);
})
