.global asm_basic_loop
asm_basic_loop:
  xor x5, x5, x5
  blez a0, fin_loop
ini_loop:
  xor x6, x6, x6
  xor x7, x7, x7
  xor x28, x28, x28
  xor x29, x29, x29
  xor x30, x30, x30
  xor x31, x31, x31
  addi x6, x6, 2
  addi x7, x7, 3
  addi x28, x28, 4
  addi x29, x29, 5
  addi x30, x30, 6
  addi x31, x31, 7
  add x6, x6, x6
  add x7, x7, x7
  add x28, x28, x28
  add x29, x29, x29
  add x30, x30, x30
  add x31, x31, x31
  addi x5,x5,1
  bne  x5,x10, ini_loop
fin_loop:
  ret
