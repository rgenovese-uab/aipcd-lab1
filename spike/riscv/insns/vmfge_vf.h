// vmfge.vf vd, vs2, rs1
require(P.core_type != SARGANTANA);
VI_VFP_VF_LOOP_CMP
({
  res = f16_le(rs1, vs2);
},
{
  res = f32_le(rs1, vs2);
},
{
  res = f64_le(rs1, vs2);
})
