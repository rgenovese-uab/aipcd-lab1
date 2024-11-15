// vfmerge_vf vd, vs2, vs1, vm
require(P.core_type != SARGANTANA);
VI_VF_MERGE_LOOP({
  vd = use_first ? rs1 : vs2;
})
