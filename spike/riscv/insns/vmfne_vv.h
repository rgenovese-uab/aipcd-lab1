// vmfne.vv vd, vs2, rs1
require(P.core_type != SARGANTANA);
VI_VFP_VV_LOOP_CMP
({
  res = !f16_eq(vs2, vs1);
},
{
  res = !f32_eq(vs2, vs1);
},
{
  res = !f64_eq(vs2, vs1);
})
