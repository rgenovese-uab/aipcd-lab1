# 1 "../common/crt.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "../common/crt.S"
# See LICENSE for license details.

# 1 "../common/encoding.h" 1
# 4 "../common/crt.S" 2
# 15 "../common/crt.S"
  .section ".text.init"

  .align 6
  .globl _start
_start:
  li x1, 0
  li x2, 0
  li x3, 0
  li x4, 0
  li x5, 0
  li x6, 0
  li x7, 0
  li x8, 0
  li x9, 0
  li x10,0
  li x11,0
  li x12,0
  li x13,0
  li x14,0
  li x15,0
  li x16,0
  li x17,0
  li x18,0
  li x19,0
  li x20,0
  li x21,0
  li x22,0
  li x23,0
  li x24,0
  li x25,0
  li x26,0
  li x27,0
  li x28,0
  li x29,0
  li x30,0
  li x31,0

  # enable FPU and accelerator if present
  li t0, 0x00006000 | 0x00018000
  csrs mstatus, t0

  # make sure XLEN agrees with compilation choice
  li t0, 1
  slli t0, t0, 31

  bgez t0, 1f



2:
  li a0, 1
  sw a0, tohost, t0
  j 2b
1:
# 111 "../common/crt.S"
  # initialize trap vector
  la t0, trap_entry
  csrw mtvec, t0

  # initialize global pointer
.option push
.option norelax
  la gp, __global_pointer$
.option pop

  la tp, _end + 63
  and tp, tp, -64

  # get core id
  csrr a0, mhartid
  # for now, assume only 1 core
  li a1, 1
1:bgeu a0, a1, 1b

  # give each core 128KB of stack + TLS

  add sp, a0, 1
  sll sp, sp, 17
  add sp, sp, tp
  sll a2, a0, 17
  add tp, tp, a2

  j _init

  .align 6
trap_entry:
  addi sp, sp, -272

  sd x1, 1*8(sp)
  sd x2, 2*8(sp)
  sd x3, 3*8(sp)
  sd x4, 4*8(sp)
  sd x5, 5*8(sp)
  sd x6, 6*8(sp)
  sd x7, 7*8(sp)
  sd x8, 8*8(sp)
  sd x9, 9*8(sp)
  sd x10, 10*8(sp)
  sd x11, 11*8(sp)
  sd x12, 12*8(sp)
  sd x13, 13*8(sp)
  sd x14, 14*8(sp)
  sd x15, 15*8(sp)
  sd x16, 16*8(sp)
  sd x17, 17*8(sp)
  sd x18, 18*8(sp)
  sd x19, 19*8(sp)
  sd x20, 20*8(sp)
  sd x21, 21*8(sp)
  sd x22, 22*8(sp)
  sd x23, 23*8(sp)
  sd x24, 24*8(sp)
  sd x25, 25*8(sp)
  sd x26, 26*8(sp)
  sd x27, 27*8(sp)
  sd x28, 28*8(sp)
  sd x29, 29*8(sp)
  sd x30, 30*8(sp)
  sd x31, 31*8(sp)

  csrr a0, mcause
  csrr a1, mepc
  mv a2, sp
  jal handle_trap
  csrw mepc, a0

  # Remain in M-mode after eret
  li t0, 0x00001800
  csrs mstatus, t0

  ld x1, 1*8(sp)
  ld x2, 2*8(sp)
  ld x3, 3*8(sp)
  ld x4, 4*8(sp)
  ld x5, 5*8(sp)
  ld x6, 6*8(sp)
  ld x7, 7*8(sp)
  ld x8, 8*8(sp)
  ld x9, 9*8(sp)
  ld x10, 10*8(sp)
  ld x11, 11*8(sp)
  ld x12, 12*8(sp)
  ld x13, 13*8(sp)
  ld x14, 14*8(sp)
  ld x15, 15*8(sp)
  ld x16, 16*8(sp)
  ld x17, 17*8(sp)
  ld x18, 18*8(sp)
  ld x19, 19*8(sp)
  ld x20, 20*8(sp)
  ld x21, 21*8(sp)
  ld x22, 22*8(sp)
  ld x23, 23*8(sp)
  ld x24, 24*8(sp)
  ld x25, 25*8(sp)
  ld x26, 26*8(sp)
  ld x27, 27*8(sp)
  ld x28, 28*8(sp)
  ld x29, 29*8(sp)
  ld x30, 30*8(sp)
  ld x31, 31*8(sp)

  addi sp, sp, 272
  mret

.section ".tohost","aw",@progbits
.align 6
.globl tohost
tohost: .dword 0
.align 6
.globl fromhost
fromhost: .dword 0
