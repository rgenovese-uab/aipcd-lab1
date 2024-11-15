.global asm_basic_loop
asm_basic_loop:
  li x20, 0x4010000000000000
  li x21, 0x4000000000000000
  li x22, 0x4020000000000000
  fmv.d.x f18, x20
  fmv.d.x f19, x21
  fmv.d.x f20, x22
  xor x5, x5, x5
  blez a0, fin_loop
ini_loop:
  fsqrt.d f0, f18
  fsqrt.d f1, f18
  fsqrt.d f2, f18
  fsqrt.d f3, f19
  fsqrt.d f4, f19
  fsqrt.d f5, f19
  fdiv.d  f6, f18, f20
  fdiv.d  f7, f18, f20
  fdiv.d  f8, f18, f20
  fdiv.d  f9, f18, f20
  fdiv.d  f10, f19, f20
  fdiv.d  f11, f19, f20
  fsqrt.d f12, f19
  fsqrt.d f13, f19
  fsqrt.d f14, f19
  fsqrt.d f15, f19
  fsqrt.d f16, f19
  fsqrt.d f17, f19
  addi x5,x5,1
  bne  x5,a0, ini_loop
fin_loop:
  ret
