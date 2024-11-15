.global asm_basic_loop_arith
asm_basic_loop_arith:
  li x10, 0x7ffffffe12345678
  li x11, 0xffffffff80000000
  li x12, 0xdeadcafedeadcafe
  fmv.d.x f18, x10
  fmv.d.x f19, x11
  fmv.d.x f20, x12
  xor x5, x5, x5
  blez a0, fin_loop
ini_loop:
  fmadd.d f0, f18, f18, f18
  fmadd.d f1, f19, f19, f19
  fmadd.d f2, f20, f20, f20
  fmadd.d f3, f18, f18, f18
  fmadd.d f4, f19, f19, f19
  fmadd.d f5, f20, f20, f20
  fmul.d f6, f18, f19
  fmul.d f7, f18, f19
  fmul.d f8, f18, f19
  fmul.d f9, f18, f19
  fmul.d f10, f18, f19
  fmul.d f11, f18, f19
  fmin.d f12, f18, f19
  fmin.d f13, f18, f19
  fmin.d f14, f18, f19
  fmin.d f15, f18, f19
  fmin.d f16, f18, f19
  fmin.d f17, f18, f19
  addi x5,x5,1
  bne  x5,a0, ini_loop
fin_loop:
  ret
