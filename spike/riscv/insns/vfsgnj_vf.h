// vfsgnj vd, vs2, vs1
require(P.core_type != SARGANTANA);
VI_VFP_VF_LOOP
({
  vd = fsgnj16(vs2.v, rs1.v, false, false);
},
{
  vd = fsgnj32(vs2.v, rs1.v, false, false);
},
{
  vd = fsgnj64(vs2.v, rs1.v, false, false);
})
