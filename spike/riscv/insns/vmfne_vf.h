// vmfne.vf vd, vs2, rs1
require(P.core_type != SARGANTANA);
VI_VFP_VF_LOOP_CMP
({
  res = !f16_eq(vs2, rs1);
},
{
  res = !f32_eq(vs2, rs1);
},
{
  res = !f64_eq(vs2, rs1);
})
