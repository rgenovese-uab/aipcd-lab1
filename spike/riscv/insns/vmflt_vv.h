// vmflt.vv vd, vs2, vs1
require(P.core_type != SARGANTANA);
VI_VFP_VV_LOOP_CMP
({
  res = f16_lt(vs2, vs1);
},
{
  res = f32_lt(vs2, vs1);
},
{
  res = f64_lt(vs2, vs1);
})
