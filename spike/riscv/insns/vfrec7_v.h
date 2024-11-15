// vfclass.v vd, vs2, vm
require(P.core_type != SARGANTANA);
VI_VFP_V_LOOP
({
  vd = f16_recip7(vs2);
},
{
  vd = f32_recip7(vs2);
},
{
  vd = f64_recip7(vs2);
})
