.set IRQ_S_SOFT,   1
.set IRQ_H_SOFT,   2
.set IRQ_M_SOFT,   3
.set IRQ_U_TIMER,  4
.set IRQ_S_TIMER,  5
.set IRQ_H_TIMER,  6
.set IRQ_M_TIMER,  7
.set IRQ_U_EXT,    8
.set IRQ_S_EXT,    9
.set IRQ_H_EXT,    10
.set IRQ_M_EXT,    11
.set IRQ_COP,      12
.set IRQ_HOST,     13

.set MIP_SSIP, (1 << IRQ_S_SOFT)
.set MIP_HSIP, (1 << IRQ_H_SOFT)
.set MIP_MSIP, (1 << IRQ_M_SOFT)
.set MIP_UTIP, (1 << IRQ_U_TIMER)
.set MIP_STIP, (1 << IRQ_S_TIMER)
.set MIP_HTIP, (1 << IRQ_H_TIMER)
.set MIP_MTIP, (1 << IRQ_M_TIMER)
.set MIP_UEIP, (1 << IRQ_U_EXT)
.set MIP_SEIP, (1 << IRQ_S_EXT)
.set MIP_HEIP, (1 << IRQ_H_EXT)
.set MIP_MEIP, (1 << IRQ_M_EXT)

.set UIE,   (1<<0)
.set SIE,   (1<<1)
.set HIE,   (1<<2)
.set MIE,   (1<<3)
.set UPIE,  (1<<4)
.set SPIE,  (1<<5)
.set HPIE,  (1<<6)
.set MPIE,  (1<<7)
.set SPP,   (1<<8)
.set MPP,   (3<<9)
.set MPP_U, (0<<9)
.set MPP_S, (1<<9)
.set MPP_H, (2<<9)
.set MPP_M, (3<<9)
.set FS_OFF,  (0<<11)
.set FS_INIT, (1<<11)
.set FS_CLEAN,(2<<11)
.set FS_DIRTY,(3<<11)

.set TIMER_INTERVAL, 1

#ifndef RUN_UNDER_PK
#include "test_macros.h"
.globl _start
.type  _start, @function
#endif
#include "test_macros.h"
.globl main
.section .text

#ifndef RUN_UNDER_PK
_start:           
                  csrr x5, mhartid
                  li x6, 0
                  li x7, 0x800000000084112d
                  csrw misa, x7
                  # Program mstatus so that we return to U-mode 
                  # on mret
                  # SXL  = bits [35:34] = 64b     = 10
                  # UXL  = bits [33:32] = 64b     = 10
                  # FS   = bits [14:13] = Init    = 01
                  # MPP  = bits [12:11] = Umode   = 00
                  # MPIE = bit      [7] = Disable = 0 
                  # li x7, 0xa00002000
				  li x7, 0xa00003800
                  csrw mstatus, x7
kernel_sp:        
                  la x10, kernel_stack_end

trap_vec_init:    
                  la x7, mtvec_handler
                  ori x7, x7, 0
                  csrw 0x305, x7 # MTVEC

mepc_setup:       
                  la x7, main
                  csrw mepc, x7
                  j init_machine_mode

init_machine_mode:

                  # First thing we do is disable the timer
                  # to avoid an RTL / Spike miscorrelation
                  # The timer in UVM starts with the timer 
                  # wire set to 1, so unless we force it down
                  # to zero, MIP will reflect a value of 0x80 (MTIP set).
                  # However, Spike has no clue that the MTIP is
                  # actually setm because we only tell to Spike
                  # that is set when we do a spike_tick(). 
                  # So, to avoid trouble, let's turn off the timer.
                  # We'll program it later again.
                  li a0, 0x200BFF8 /*mtime*/
                  ld a0, 0(a0)
                  addi a0, a0, -1
                  li t1, 0x2004000 /*mtimecmp*/
                  sd a0, 0(t1)

                  # Add this point, it's actually safe to 
                  # read the MIP and we should not have a SPIKE/RTL mismatch
                  # This is here just to test things are working fine.
                  # It doesn't do anything really useful
                  csrr  x7, mip

                  # Program mstatus so that we return to U-mode 
                  # on mret
                  # SXL  = bits [35:34] = 64b     = 10
                  # UXL  = bits [33:32] = 64b     = 10
                  # FS   = bits [14:13] = Init    = 01
                  # MPP  = bits [12:11] = Umode   = 00
                  # MPIE = bit      [7] = Disable = 0 
                  # li x7, 0xa00002000
				  li x7, 0xa00003800
                  csrw mstatus, x7

init_plic:
                  li a0, MIP_MEIP    /*enable m external interrupts*/  
                  csrs mie, a0;                                                   
                  li a0, MIP_HEIP    /*enable h external interrupts*/  
                  csrs mie, a0;                                                   
                  li a0, MIP_SEIP    /*enable s external interrupts*/  
                  csrs mie, a0;                                                   
                  li a0, MIP_UEIP    /*enable u external interrupts*/  
                  csrs mie, a0;                                                   
                  li a0, 0x0c000004; /*PLIC addr*/                                
                  li t1, 0x1;                                                     
                  sw t1, 0(a0);                                                   
                  li a0, 0x0c002000; /*PLIC addr*/                                
                  li t1, 0x2;                                                     
                  sw t1, 0(a0);                                                   
init_timer:
                  li a0, MIP_MTIP
                  csrs mie, a0
                  li a0, MIP_HTIP
                  csrs mie, a0
                  li a0, MIP_STIP
                  csrs mie, a0
                  li a0, MIP_UTIP
                  csrs mie, a0

#                  li a0, 0x200BFF8 /*mtime*/
#                  ld a0, 0(a0)
#                  addi a0, a0, -1
#                  li t1, 0x2004000 /*mtimecmp*/
#                  sd a0, 0(t1)

                  /* Read MIE and MIP just so that spike prints their value
                   */
                  csrr x5, mie
                  csrr x5, mstatus
                  mret
#endif

main:             
                  li x0, 0x5b6ce776
                  li x1, 0xa
                  li x2, 0x0
                  li x3, 0x429583c6
                  li x4, 0xe
                  li x6, 0x2a541b2d
                  li x7, 0xf4ec0570
                  li x8, 0xfeec5ec6
                  li x9, 0x80000000
                  li x11, 0xad9e1f4a
                  li x12, 0x22d34872
                  li x13, 0x6
                  li x14, 0x0
                  li x15, 0x7
                  li x16, 0x80000000
                  li x17, 0x3b428453
                  li x18, 0x5
                  li x19, 0x8
                  li x20, 0x0
                  li x21, 0xb
                  li x22, 0xed1ace85
                  li x23, 0x7ac71268
                  li x24, 0x8
                  li x25, 0x0
                  li x26, 0x80000000
                  li x27, 0x2
                  li x28, 0x9500466e
                  li x29, 0x0
                  li x30, 0x7d61cd71
                  li x31, 0x66109ec4
                  la x5, user_stack_end
                  fcvt.d.l f0, x27
                  fcvt.d.l f1, x12
                  fcvt.d.l f2, x20
                  fcvt.d.l f3, x5
                  fcvt.d.l f4, x24
                  fcvt.d.l f5, x14
                  fcvt.d.l f6, x14
                  fcvt.d.l f7, x1
                  fcvt.d.l f8, x7
                  fcvt.d.l f9, x14
                  fcvt.d.l f10, x18
                  fcvt.d.l f11, x31
                  fcvt.d.l f12, x24
                  fcvt.d.l f13, x15
                  fcvt.d.l f14, x24
                  fcvt.d.l f15, x24
                  fcvt.d.l f16, x10
                  fcvt.d.l f17, x7
                  fcvt.d.l f18, x12
                  fcvt.d.l f19, x25
                  fcvt.d.l f20, x1
                  fcvt.d.l f21, x1
                  fcvt.d.l f22, x13
                  fcvt.d.l f23, x7
                  fcvt.d.l f24, x22
                  fcvt.d.l f25, x23
                  fcvt.d.l f26, x13
                  fcvt.d.l f27, x21
                  fcvt.d.l f28, x25
                  fcvt.d.l f29, x1
                  fcvt.d.l f30, x2
                  fcvt.d.l f31, x18
                  fsrmi 3
                  li      x2, 256
                  vsetvli t0, x2, e64, m1
                  vxor.vv v0, v0, v0
                  vxor.vv v1, v1, v1
                  vxor.vv v2, v2, v2
                  vxor.vv v3, v3, v3
                  vxor.vv v4, v4, v4
                  vxor.vv v5, v5, v5
                  vxor.vv v6, v6, v6
                  vxor.vv v7, v7, v7
                  vxor.vv v8, v8, v8
                  vxor.vv v9, v9, v9
                  vxor.vv v10, v10, v10
                  vxor.vv v11, v11, v11
                  vxor.vv v12, v12, v12
                  vxor.vv v13, v13, v13
                  vxor.vv v14, v14, v14
                  vxor.vv v15, v15, v15
                  vxor.vv v16, v16, v16
                  vxor.vv v17, v17, v17
                  vxor.vv v18, v18, v18
                  vxor.vv v19, v19, v19
                  vxor.vv v20, v20, v20
                  vxor.vv v21, v21, v21
                  vxor.vv v22, v22, v22
                  vxor.vv v23, v23, v23
                  vxor.vv v24, v24, v24
                  vxor.vv v25, v25, v25
                  vxor.vv v26, v26, v26
                  vxor.vv v27, v27, v27
                  vxor.vv v28, v28, v28
                  vxor.vv v29, v29, v29
                  vxor.vv v30, v30, v30
                  vxor.vv v31, v31, v31
#ifdef RUN_UNDER_PK
pk_init_plic:
                  la a0, plic_addr
                  ld a0, (a0)
                  li t1, 0x1;                                                     
                  sw t1, 4(a0);                                                   
                  li t1, 0x2;                                                     
                  la t2, 8192
                  add a0, a0, t2
                  sw t1, (a0);                                                   
#endif
random:
.include "vector_section.s"
                  j test_done
test_done:        

#ifdef FLUSH_L2_LOOP
                  # Now do a  loop that reads 1MB memory from the "region_zero"
                  # This should cause the HN/L2 to be completel auto-flushed to memory
                  la x2, zero_1MB_region
                  li x3, 16384
L2loop:
                  ld x1, (x2)
                  addi x2, x2, 64
                  addi x3, x3, -1
                  blt x0,x3, L2loop
#endif

# Jump to PK
                  li gp, 1
                  li a1, 0
                  li a2, 0
                  li a3, 0
                  li a4, 0
                  li a5, 0
                  li a7, 93 # syscall exit
                  ecall  # Putting this bakc in for VCS -- roger, I took the ecall out for spike. This needs probably to be back for vcs
write_tohost:     
                  sw gp, tohost, t5

_exit:            
                  j write_tohost

instr_end:        
                  nop

.section .data
.align 6
.global uart_addr; 
.global clint_addr; 
.global plic_addr; 
uart_addr:
       .quad 0x480010000800; # This is a magic address where VICTOR has mapped the UART under PK
clint_addr:
       .quad 0x480002000000; # This is a magic address where VICTOR has mapped the CLINT under PK
plic_addr:
       .quad 0x48000c000000; # This is a magic address where VICTOR has mapped the PLIC under PK
.align 6; 
.global tohost; 
tohost: 
       .dword 0;
.align 6; 
.global fromhost; 
fromhost: 
        .dword 0;
.section .user_stack,"aw",@progbits;
.align 2
user_stack_start:
.rept 4999
.8byte 0x0
.endr
user_stack_end:
.align 6; 
.global region_0; # 4KB region
.include "data_section.s"
.global amo_0; # 64 Bytes
amo_0:
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.global lzcdata; # 64 Bytes
.align 3
lzcdata:
.word 0x00000000, 0x00000001 
.word 0x00000000, 0x00000002 
.word 0x00000000, 0x00000004 
.word 0x00000000, 0x00000008 
.word 0x00000000, 0x00000010 
.word 0x00000000, 0x00000020 
.word 0x00000000, 0x00000040 
.word 0x00000000, 0x00000080 
.word 0x00000000, 0x00000100 
.word 0x00000000, 0x00000200 
.word 0x00000000, 0x00000400 
.word 0x00000000, 0x00000800 
.word 0x00000000, 0x00001000 
.word 0x00000000, 0x00002000 
.word 0x00000000, 0x00004000 
.word 0x00000000, 0x00008000 
.word 0x00000000, 0x00010000 
.word 0x00000000, 0x00020000 
.word 0x00000000, 0x00040000 
.word 0x00000000, 0x00080000 
.word 0x00000000, 0x00100000 
.word 0x00000000, 0x00200000 
.word 0x00000000, 0x00400000 
.word 0x00000000, 0x00800000 
.word 0x00000000, 0x01000000 
.word 0x00000000, 0x02000000 
.word 0x00000000, 0x04000000 
.word 0x00000000, 0x08000000 
.word 0x00000000, 0x10000000 
.word 0x00000000, 0x20000000 
.word 0x00000000, 0x40000000 
.word 0x00000000, 0x80000000 
.word 0x00000001, 0x00000000
.word 0x00000002, 0x00000000 
.word 0x00000004, 0x00000000 
.word 0x00000008, 0x00000000 
.word 0x00000010, 0x00000000 
.word 0x00000020, 0x00000000 
.word 0x00000040, 0x00000000 
.word 0x00000080, 0x00000000 
.word 0x00000100, 0x00000000 
.word 0x00000200, 0x00000000 
.word 0x00000400, 0x00000000 
.word 0x00000800, 0x00000000 
.word 0x00001000, 0x00000000 
.word 0x00002000, 0x00000000 
.word 0x00004000, 0x00000000 
.word 0x00008000, 0x00000000 
.word 0x00010000, 0x00000000 
.word 0x00020000, 0x00000000 
.word 0x00040000, 0x00000000 
.word 0x00080000, 0x00000000 
.word 0x00100000, 0x00000000 
.word 0x00200000, 0x00000000 
.word 0x00400000, 0x00000000 
.word 0x00800000, 0x00000000 
.word 0x01000000, 0x00000000 
.word 0x02000000, 0x00000000 
.word 0x04000000, 0x00000000 
.word 0x08000000, 0x00000000 
.word 0x10000000, 0x00000000 
.word 0x20000000, 0x00000000 
.word 0x40000000, 0x00000000 
.word 0x80000000, 0x00000000 
    .align 6;
    .global region_idx8
    region_idx8:
    .byte 175
.byte 52
.byte 54
.byte 133
.byte 181
.byte 226
.byte 90
.byte 209
.byte 222
.byte 36
.byte 51
.byte 130
.byte 55
.byte 38
.byte 245
.byte 112
.byte 132
.byte 144
.byte 114
.byte 207
.byte 90
.byte 220
.byte 212
.byte 7
.byte 90
.byte 176
.byte 91
.byte 105
.byte 31
.byte 126
.byte 133
.byte 56
.byte 236
.byte 8
.byte 245
.byte 213
.byte 254
.byte 59
.byte 121
.byte 225
.byte 198
.byte 17
.byte 141
.byte 104
.byte 140
.byte 190
.byte 206
.byte 65
.byte 213
.byte 247
.byte 5
.byte 163
.byte 241
.byte 55
.byte 210
.byte 203
.byte 184
.byte 252
.byte 218
.byte 63
.byte 137
.byte 210
.byte 197
.byte 250
.byte 153
.byte 56
.byte 138
.byte 60
.byte 54
.byte 183
.byte 216
.byte 243
.byte 226
.byte 177
.byte 248
.byte 129
.byte 30
.byte 26
.byte 74
.byte 236
.byte 175
.byte 17
.byte 218
.byte 54
.byte 192
.byte 115
.byte 116
.byte 128
.byte 185
.byte 14
.byte 18
.byte 21
.byte 169
.byte 32
.byte 2
.byte 10
.byte 12
.byte 250
.byte 193
.byte 60
.byte 122
.byte 225
.byte 15
.byte 200
.byte 123
.byte 180
.byte 16
.byte 168
.byte 88
.byte 127
.byte 40
.byte 144
.byte 56
.byte 228
.byte 50
.byte 199
.byte 95
.byte 59
.byte 27
.byte 26
.byte 135
.byte 75
.byte 104
.byte 33
.byte 215
.byte 244
.byte 211
.byte 97
.byte 211
.byte 44
.byte 120
.byte 159
.byte 74
.byte 101
.byte 106
.byte 55
.byte 175
.byte 14
.byte 135
.byte 23
.byte 159
.byte 144
.byte 177
.byte 192
.byte 235
.byte 237
.byte 241
.byte 149
.byte 215
.byte 167
.byte 16
.byte 61
.byte 250
.byte 70
.byte 180
.byte 106
.byte 177
.byte 222
.byte 5
.byte 111
.byte 122
.byte 61
.byte 160
.byte 235
.byte 71
.byte 105
.byte 21
.byte 20
.byte 136
.byte 139
.byte 114
.byte 160
.byte 11
.byte 244
.byte 132
.byte 206
.byte 27
.byte 25
.byte 108
.byte 131
.byte 69
.byte 111
.byte 248
.byte 100
.byte 8
.byte 35
.byte 143
.byte 96
.byte 38
.byte 120
.byte 81
.byte 56
.byte 47
.byte 147
.byte 254
.byte 56
.byte 8
.byte 31
.byte 138
.byte 251
.byte 155
.byte 176
.byte 197
.byte 152
.byte 160
.byte 83
.byte 59
.byte 53
.byte 153
.byte 33
.byte 249
.byte 16
.byte 217
.byte 179
.byte 116
.byte 70
.byte 122
.byte 81
.byte 34
.byte 41
.byte 145
.byte 29
.byte 71
.byte 126
.byte 27
.byte 186
.byte 121
.byte 253
.byte 11
.byte 86
.byte 30
.byte 169
.byte 56
.byte 29
.byte 253
.byte 142
.byte 206
.byte 132
.byte 138
.byte 8
.byte 59
.byte 123
.byte 132
.byte 126
.byte 166
.byte 95
.byte 1
.byte 146
.byte 252
.byte 11
.byte 160
.byte 216
.byte 252
.byte 133
.byte 120
.byte 8
.byte 159
.byte 251
.byte 118
.byte 97
.byte 2
.byte 252
.byte 217
.byte 46
.byte 114
.byte 7
.byte 120
.byte 182
.byte 92
.byte 242
.byte 110
.byte 19
.byte 185
.byte 188
.byte 179
.byte 17
.byte 206
.byte 203
.byte 249
.byte 148
.byte 100
.byte 200
.byte 86
.byte 95
.byte 126
.byte 231
.byte 39
.byte 77
.byte 194
.byte 72
.byte 148
.byte 245
.byte 54
.byte 31
.byte 221
.byte 151
.byte 158
.byte 146
.byte 8
.byte 60
.byte 50
.byte 81
.byte 228
.byte 73
.byte 97
.byte 216
.byte 251
.byte 99
.byte 135
.byte 91
.byte 53
.byte 163
.byte 152
.byte 126
.byte 26
.byte 109
.byte 206
.byte 181
.byte 160
.byte 105
.byte 246
.byte 56
.byte 176
.byte 189
.byte 12
.byte 17
.byte 121
.byte 255
.byte 136
.byte 152
.byte 234
.byte 55
.byte 110
.byte 50
.byte 151
.byte 70
.byte 47
.byte 225
.byte 62
.byte 211
.byte 140
.byte 36
.byte 178
.byte 153
.byte 111
.byte 233
.byte 110
.byte 187
.byte 65
.byte 150
.byte 178
.byte 53
.byte 1
.byte 241
.byte 131
.byte 228
.byte 0
.byte 82
.byte 151
.byte 127
.byte 7
.byte 20
.byte 240
.byte 161
.byte 122
.byte 13
.byte 175
.byte 231
.byte 218
.byte 225
.byte 60
.byte 72
.byte 138
.byte 189
.byte 221
.byte 112
.byte 137
.byte 216
.byte 100
.byte 15
.byte 94
.byte 129
.byte 98
.byte 101
.byte 157
.byte 66
.byte 11
.byte 53
.byte 106
.byte 173
.byte 143
.byte 51
.byte 201
.byte 161
.byte 135
.byte 99
.byte 237
.byte 62
.byte 113
.byte 200
.byte 166
.byte 93
.byte 4
.byte 3
.byte 61
.byte 217
.byte 208
.byte 80
.byte 150
.byte 210
.byte 242
.byte 139
.byte 192
.byte 225
.byte 115
.byte 107
.byte 199
.byte 43
.byte 119
.byte 4
.byte 84
.byte 199
.byte 12
.byte 199
.byte 221
.byte 50
.byte 107
.byte 244
.byte 175
.byte 242
.byte 39
.byte 93
.byte 212
.byte 37
.byte 210
.byte 72
.byte 123
.byte 237
.byte 172
.byte 156
.byte 133
.byte 234
.byte 141
.byte 5
.byte 227
.byte 253
.byte 247
.byte 160
.byte 94
.byte 47
.byte 84
.byte 129
.byte 77
.byte 209
.byte 197
.byte 36
.byte 185
.byte 155
.byte 11
.byte 177
.byte 22
.byte 105
.byte 165
.byte 138
.byte 70
.byte 214
.byte 23
.byte 243
.byte 105
.byte 141
.byte 224
.byte 179
.byte 93
.byte 82
.byte 178
.byte 85
.byte 230
.byte 227
.byte 43
.byte 25
.byte 156
.byte 52
.byte 232
.byte 69
.byte 49
.byte 24
.byte 253
.byte 170
.byte 93
.byte 232
.byte 55
.byte 6
.byte 214
.byte 64
.byte 119
.byte 235
.byte 171
.byte 119
.byte 125
.byte 226
.byte 164
.byte 241
.byte 9
.byte 253
.byte 89
.byte 101
.byte 168
.byte 87
.byte 89
.byte 191
.byte 198
.byte 152
.byte 245
.byte 168
.byte 9
.byte 136
.byte 218
.byte 131
.byte 43
.byte 80
.byte 234
.byte 152
.byte 242
.byte 68
.byte 145
.byte 91
.byte 122
.byte 161
.byte 194
.byte 162
.byte 235
.byte 147
.byte 59
.byte 172
.byte 97
.byte 105
.byte 106
.byte 152
.byte 216
.byte 24
.byte 35
.byte 123
.byte 159
.byte 150
.byte 89
.byte 108
.byte 226
.byte 4
.byte 86
.byte 179
.byte 250
.byte 116
.byte 4
.byte 39
.byte 61
.byte 248
.byte 117
.byte 241
.byte 65
.byte 40
.byte 188
.byte 181
.byte 208
.byte 132
.byte 178
.byte 74
.byte 248
.byte 175
.byte 116
.byte 114
.byte 250
.byte 230
.byte 31
.byte 180
.byte 216
.byte 129
.byte 9
.byte 115
.byte 136
.byte 8
.byte 124
.byte 41
.byte 219
.byte 11
.byte 179
.byte 16
.byte 112
.byte 17
.byte 229
.byte 3
.byte 226
.byte 202
.byte 6
.byte 122
.byte 222
.byte 191
.byte 134
.byte 42
.byte 214
.byte 215
.byte 46
.byte 24
.byte 38
.byte 82
.byte 184
.byte 94
.byte 70
.byte 60
.byte 143
.byte 35
.byte 176
.byte 160
.byte 156
.byte 2
.byte 178
.byte 202
.byte 158
.byte 10
.byte 97
.byte 246
.byte 23
.byte 222
.byte 218
.byte 106
.byte 216
.byte 36
.byte 1
.byte 222
.byte 215
.byte 164
.byte 38
.byte 129
.byte 85
.byte 81
.byte 105
.byte 143
.byte 173
.byte 106
.byte 23
.byte 119
.byte 211
.byte 216
.byte 241
.byte 243
.byte 243
.byte 246
.byte 23
.byte 232
.byte 235
.byte 205
.byte 145
.byte 116
.byte 186
.byte 22
.byte 238
.byte 161
.byte 169
.byte 102
.byte 116
.byte 175
.byte 134
.byte 56
.byte 175
.byte 195
.byte 241
.byte 43
.byte 227
.byte 206
.byte 147
.byte 233
.byte 54
.byte 230
.byte 88
.byte 88
.byte 92
.byte 99
.byte 74
.byte 214
.byte 191
.byte 177
.byte 214
.byte 134
.byte 81
.byte 245
.byte 216
.byte 132
.byte 188
.byte 62
.byte 112
.byte 174
.byte 178
.byte 131
.byte 196
.byte 52
.byte 143
.byte 39
.byte 113
.byte 90
.byte 26
.byte 248
.byte 0
.byte 37
.byte 239
.byte 120
.byte 68
.byte 83
.byte 169
.byte 241
.byte 241
.byte 96
.byte 209
.byte 57
.byte 31
.byte 122
.byte 205
.byte 39
.byte 185
.byte 97
.byte 84
.byte 187
.byte 176
.byte 153
.byte 211
.byte 2
.byte 74
.byte 127
.byte 222
.byte 208
.byte 20
.byte 144
.byte 135
.byte 120
.byte 59
.byte 106
.byte 186
.byte 137
.byte 44
.byte 18
.byte 87
.byte 204
.byte 32
.byte 219
.byte 207
.byte 151
.byte 33
.byte 250
.byte 185
.byte 142
.byte 181
.byte 6
.byte 36
.byte 118
.byte 144
.byte 102
.byte 127
.byte 49
.byte 152
.byte 136
.byte 239
.byte 116
.byte 20
.byte 43
.byte 210
.byte 129
.byte 220
.byte 213
.byte 32
.byte 130
.byte 167
.byte 55
.byte 179
.byte 175
.byte 140
.byte 222
.byte 128
.byte 88
.byte 81
.byte 18
.byte 176
.byte 234
.byte 73
.byte 174
.byte 117
.byte 253
.byte 219
.byte 177
.byte 22
.byte 31
.byte 135
.byte 110
.byte 124
.byte 10
.byte 96
.byte 87
.byte 152
.byte 201
.byte 4
.byte 142
.byte 126
.byte 117
.byte 124
.byte 217
.byte 132
.byte 45
.byte 54
.byte 137
.byte 53
.byte 165
.byte 165
.byte 236
.byte 23
.byte 41
.byte 78
.byte 180
.byte 212
.byte 11
.byte 26
.byte 145
.byte 119
.byte 165
.byte 171
.byte 215
.byte 36
.byte 82
.byte 79
.byte 178
.byte 143
.byte 23
.byte 83
.byte 56
.byte 28
.byte 198
.byte 59
.byte 228
.byte 28
.byte 4
.byte 251
.byte 42
.byte 60
.byte 53
.byte 135
.byte 132
.byte 109
.byte 39
.byte 145
.byte 249
.byte 127
.byte 99
.byte 186
.byte 36
.byte 223
.byte 198
.byte 73
.byte 143
.byte 47
.byte 234
.byte 251
.byte 239
.byte 221
.byte 219
.byte 93
.byte 144
.byte 229
.byte 56
.byte 171
.byte 109
.byte 111
.byte 123
.byte 223
.byte 249
.byte 172
.byte 64
.byte 211
.byte 111
.byte 106
.byte 143
.byte 204
.byte 100
.byte 93
.byte 30
.byte 188
.byte 227
.byte 111
.byte 205
.byte 103
.byte 65
.byte 203
.byte 114
.byte 32
.byte 188
.byte 237
.byte 249
.byte 130
.byte 42
.byte 162
.byte 163
.byte 103
.byte 209
.byte 165
.byte 6
.byte 181
.byte 207
.byte 222
.byte 202
.byte 218
.byte 236
.byte 91
.byte 21
.byte 157
.byte 31
.byte 199
.byte 132
.byte 195
.byte 223
.byte 228
.byte 223
.byte 212
.byte 179
.byte 183
.byte 114
.byte 191
.byte 59
.byte 206
.byte 121
.byte 214
.byte 55
.byte 90
.byte 197
.byte 200
.byte 107
.byte 242
.byte 138
.byte 59
.byte 174
.byte 12
.byte 134
.byte 18
.byte 193
.byte 55
.byte 201
.byte 235
.byte 62
.byte 32
.byte 76
.byte 191
.byte 15
.byte 221
.byte 22
.byte 224
.byte 212
.byte 106
.byte 54
.byte 126
.byte 213
.byte 82
.byte 252
.byte 37
.byte 62
.byte 54
.byte 117
.byte 34
.byte 137
.byte 104
.byte 241
.byte 43
.byte 45
.byte 103
.byte 214
.byte 217
.byte 245
.byte 167
.byte 141
.byte 169
.byte 39
.byte 207
.byte 85
.byte 10
.byte 245
.byte 203
.byte 43
.byte 50
.byte 124
.byte 88
.byte 48
.byte 78
.byte 231
.byte 27
.byte 151
.byte 44
.byte 236
.byte 244
.byte 242
.byte 153
.byte 125
.byte 121
.byte 239
.byte 193
.byte 0
.byte 208
.byte 49
.byte 28
.byte 187
.byte 189
.byte 134
.byte 238
.byte 253
.byte 149
.byte 200
.byte 157
.byte 170
.byte 222
.byte 233
.byte 173
.byte 86
.byte 254
.byte 42
.byte 72
.byte 140
.byte 216
.byte 61
.byte 156
.byte 59
.byte 93
.byte 78
    .global region_idx16
    region_idx16:
    .hword 452
.hword 344
.hword 510
.hword 12
.hword 28
.hword 434
.hword 472
.hword 312
.hword 102
.hword 154
.hword 104
.hword 56
.hword 20
.hword 404
.hword 472
.hword 222
.hword 388
.hword 222
.hword 26
.hword 240
.hword 324
.hword 210
.hword 60
.hword 262
.hword 384
.hword 322
.hword 208
.hword 220
.hword 26
.hword 498
.hword 424
.hword 202
.hword 292
.hword 108
.hword 394
.hword 500
.hword 344
.hword 150
.hword 222
.hword 316
.hword 356
.hword 424
.hword 6
.hword 2
.hword 172
.hword 144
.hword 398
.hword 272
.hword 390
.hword 232
.hword 454
.hword 36
.hword 312
.hword 228
.hword 482
.hword 54
.hword 284
.hword 126
.hword 256
.hword 382
.hword 100
.hword 90
.hword 398
.hword 340
.hword 354
.hword 498
.hword 234
.hword 126
.hword 44
.hword 132
.hword 64
.hword 486
.hword 58
.hword 340
.hword 192
.hword 394
.hword 80
.hword 404
.hword 440
.hword 372
.hword 460
.hword 500
.hword 438
.hword 140
.hword 310
.hword 264
.hword 304
.hword 340
.hword 456
.hword 362
.hword 208
.hword 98
.hword 30
.hword 448
.hword 240
.hword 416
.hword 282
.hword 134
.hword 280
.hword 278
.hword 80
.hword 150
.hword 400
.hword 186
.hword 374
.hword 272
.hword 116
.hword 276
.hword 282
.hword 272
.hword 404
.hword 278
.hword 2
.hword 324
.hword 140
.hword 8
.hword 240
.hword 70
.hword 432
.hword 240
.hword 408
.hword 362
.hword 76
.hword 260
.hword 236
.hword 322
.hword 154
.hword 496
.hword 204
.hword 372
.hword 276
.hword 480
.hword 254
.hword 8
.hword 72
.hword 228
.hword 62
.hword 180
.hword 66
.hword 360
.hword 430
.hword 474
.hword 10
.hword 20
.hword 102
.hword 28
.hword 488
.hword 344
.hword 32
.hword 176
.hword 18
.hword 102
.hword 198
.hword 488
.hword 76
.hword 6
.hword 288
.hword 140
.hword 172
.hword 168
.hword 106
.hword 400
.hword 510
.hword 286
.hword 174
.hword 168
.hword 328
.hword 86
.hword 446
.hword 110
.hword 472
.hword 18
.hword 208
.hword 428
.hword 498
.hword 58
.hword 370
.hword 420
.hword 298
.hword 70
.hword 354
.hword 462
.hword 184
.hword 346
.hword 216
.hword 180
.hword 300
.hword 200
.hword 166
.hword 144
.hword 392
.hword 108
.hword 128
.hword 466
.hword 406
.hword 94
.hword 76
.hword 90
.hword 110
.hword 184
.hword 384
.hword 502
.hword 134
.hword 238
.hword 406
.hword 180
.hword 400
.hword 510
.hword 130
.hword 378
.hword 36
.hword 482
.hword 84
.hword 126
.hword 384
.hword 386
.hword 432
.hword 456
.hword 196
.hword 270
.hword 84
.hword 216
.hword 38
.hword 150
.hword 110
.hword 290
.hword 500
.hword 98
.hword 86
.hword 220
.hword 44
.hword 348
.hword 402
.hword 334
.hword 314
.hword 358
.hword 272
.hword 300
.hword 228
.hword 0
.hword 358
.hword 12
.hword 356
.hword 296
.hword 216
.hword 494
.hword 118
.hword 98
.hword 430
.hword 366
.hword 84
.hword 220
.hword 272
.hword 70
.hword 354
.hword 16
.hword 326
.hword 364
.hword 316
.hword 72
.hword 338
.hword 152
.hword 448
.hword 204
.hword 186
.hword 360
.hword 320
.hword 198
.hword 356
.hword 196
.hword 302
.hword 406
.hword 462
.hword 2
.hword 334
.hword 384
.hword 216
.hword 266
.hword 432
.hword 276
.hword 250
.hword 176
.hword 270
.hword 46
.hword 298
.hword 46
.hword 164
.hword 174
.hword 368
.hword 368
.hword 50
.hword 456
.hword 444
.hword 414
.hword 386
.hword 408
.hword 180
.hword 2
.hword 114
.hword 98
.hword 198
.hword 482
.hword 412
.hword 444
.hword 16
.hword 64
.hword 238
.hword 324
.hword 130
.hword 220
.hword 446
.hword 2
.hword 210
.hword 408
.hword 356
.hword 482
.hword 182
.hword 470
.hword 168
.hword 196
.hword 166
.hword 402
.hword 346
.hword 254
.hword 492
.hword 500
.hword 106
.hword 492
.hword 328
.hword 394
.hword 134
.hword 240
.hword 280
.hword 460
.hword 276
.hword 114
.hword 230
.hword 108
.hword 254
.hword 284
.hword 450
.hword 418
.hword 44
.hword 30
.hword 424
.hword 400
.hword 236
.hword 486
.hword 170
.hword 278
.hword 90
.hword 108
.hword 416
.hword 322
.hword 302
.hword 100
.hword 372
.hword 198
.hword 160
.hword 358
.hword 200
.hword 194
.hword 466
.hword 246
.hword 492
.hword 278
.hword 378
.hword 172
.hword 382
.hword 38
.hword 354
.hword 260
.hword 300
.hword 248
.hword 304
.hword 218
.hword 492
.hword 94
.hword 384
.hword 26
.hword 334
.hword 422
.hword 96
.hword 272
.hword 500
.hword 500
.hword 266
.hword 500
.hword 482
.hword 296
.hword 364
.hword 250
.hword 20
.hword 94
.hword 274
.hword 194
.hword 456
.hword 402
.hword 26
.hword 492
.hword 442
.hword 306
.hword 314
.hword 314
.hword 22
.hword 482
.hword 190
.hword 64
.hword 14
.hword 312
.hword 0
.hword 298
.hword 458
.hword 104
.hword 382
.hword 396
.hword 148
.hword 60
.hword 58
.hword 32
.hword 26
.hword 248
.hword 468
.hword 152
.hword 320
.hword 222
.hword 82
.hword 56
.hword 348
.hword 230
.hword 510
.hword 224
.hword 402
.hword 494
.hword 228
.hword 368
.hword 416
.hword 470
.hword 380
.hword 398
.hword 44
.hword 402
.hword 472
.hword 442
.hword 452
.hword 130
.hword 302
.hword 218
.hword 260
.hword 448
.hword 116
.hword 34
.hword 426
.hword 28
.hword 220
.hword 330
.hword 296
.hword 464
.hword 86
.hword 406
.hword 108
.hword 408
.hword 504
.hword 184
.hword 252
.hword 302
.hword 416
.hword 394
.hword 424
.hword 406
.hword 502
.hword 296
.hword 502
.hword 408
.hword 232
.hword 12
.hword 486
.hword 482
.hword 186
.hword 444
.hword 310
.hword 26
.hword 420
.hword 214
.hword 466
.hword 470
.hword 268
.hword 262
.hword 212
.hword 46
.hword 372
.hword 494
.hword 232
.hword 182
.hword 342
.hword 264
.hword 410
.hword 322
.hword 430
.hword 426
.hword 130
.hword 446
.hword 292
.hword 334
.hword 12
.hword 484
.hword 408
.hword 112
.hword 64
.hword 462
.hword 446
.hword 96
.hword 208
.hword 456
.hword 84
.hword 110
.hword 406
.hword 368
.hword 102
.hword 418
.hword 200
.hword 198
.hword 290
.hword 58
.hword 184
.hword 184
.hword 90
.hword 30
.hword 206
.hword 336
.hword 72
.hword 356
.hword 368
.hword 136
.hword 86
.hword 332
.hword 246
.hword 28
.hword 286
.hword 16
.hword 482
.hword 208
.hword 40
.hword 248
.hword 476
.hword 8
.hword 106
.hword 302
.hword 430
.hword 426
.hword 46
.hword 210
.hword 506
.hword 382
.hword 412
.hword 76
.hword 32
.hword 270
.hword 108
.hword 404
.hword 280
.hword 348
.hword 268
.hword 398
.hword 322
.hword 368
.hword 236
.hword 60
.hword 374
.hword 52
.hword 178
.hword 498
.hword 90
.hword 246
.hword 16
.hword 374
.hword 166
.hword 348
.hword 218
.hword 22
.hword 336
.hword 254
.hword 412
.hword 266
.hword 122
.hword 412
.hword 252
.hword 492
.hword 118
.hword 148
.hword 486
.hword 30
.hword 330
.hword 242
.hword 346
.hword 14
.hword 270
.hword 196
.hword 144
.hword 138
.hword 102
.hword 124
.hword 336
.hword 0
.hword 470
.hword 128
.hword 108
.hword 162
.hword 292
.hword 466
.hword 270
.hword 44
.hword 328
.hword 392
.hword 300
.hword 370
.hword 138
.hword 166
.hword 354
.hword 464
.hword 138
.hword 334
.hword 334
.hword 48
.hword 152
.hword 104
.hword 42
.hword 204
.hword 64
.hword 494
.hword 426
.hword 134
.hword 62
.hword 218
.hword 168
.hword 286
.hword 146
.hword 182
.hword 28
.hword 358
.hword 306
.hword 338
.hword 408
.hword 30
.hword 508
.hword 218
.hword 478
.hword 398
.hword 24
.hword 326
.hword 130
.hword 234
.hword 210
.hword 372
.hword 448
.hword 342
.hword 184
.hword 428
.hword 290
.hword 26
.hword 336
.hword 274
.hword 152
.hword 338
.hword 296
.hword 344
.hword 26
.hword 472
.hword 244
.hword 210
.hword 192
.hword 406
.hword 182
.hword 402
.hword 120
.hword 136
.hword 418
.hword 136
.hword 450
.hword 482
.hword 454
.hword 166
.hword 202
.hword 212
.hword 132
.hword 308
.hword 50
.hword 162
.hword 344
.hword 338
.hword 168
.hword 148
.hword 140
.hword 268
.hword 190
.hword 286
.hword 284
.hword 408
.hword 82
.hword 440
.hword 492
.hword 348
.hword 374
.hword 138
.hword 22
.hword 236
.hword 156
.hword 288
.hword 24
.hword 152
.hword 116
.hword 480
.hword 146
.hword 54
.hword 366
.hword 426
.hword 366
.hword 218
.hword 22
.hword 484
.hword 300
.hword 272
.hword 490
.hword 372
.hword 320
.hword 376
.hword 490
.hword 356
.hword 194
.hword 24
.hword 234
.hword 318
.hword 252
.hword 458
.hword 472
.hword 430
.hword 194
.hword 468
.hword 502
.hword 226
.hword 278
.hword 232
.hword 110
.hword 412
.hword 52
.hword 154
.hword 88
.hword 390
.hword 20
.hword 258
.hword 354
.hword 134
.hword 264
.hword 328
.hword 376
.hword 150
.hword 400
.hword 342
.hword 476
.hword 290
.hword 58
.hword 368
.hword 94
.hword 306
.hword 280
.hword 388
.hword 66
.hword 510
.hword 46
.hword 238
.hword 340
.hword 306
.hword 370
.hword 52
.hword 430
.hword 486
.hword 468
.hword 304
.hword 226
.hword 52
.hword 500
.hword 204
.hword 18
.hword 40
.hword 444
.hword 254
.hword 164
.hword 140
.hword 470
.hword 174
.hword 112
.hword 34
.hword 378
.hword 390
.hword 216
.hword 430
.hword 194
.hword 70
.hword 30
.hword 384
.hword 360
.hword 64
.hword 88
.hword 42
.hword 236
.hword 58
.hword 72
.hword 16
.hword 308
.hword 192
.hword 118
.hword 486
.hword 304
.hword 460
.hword 484
.hword 168
.hword 470
.hword 406
.hword 102
.hword 422
.hword 50
.hword 76
.hword 20
.hword 116
.hword 424
.hword 352
.hword 126
.hword 134
.hword 144
.hword 480
.hword 114
.hword 118
.hword 430
.hword 408
.hword 500
.hword 388
.hword 386
.hword 256
.hword 420
.hword 134
.hword 316
.hword 16
.hword 270
.hword 424
.hword 368
.hword 192
.hword 18
.hword 174
.hword 30
.hword 22
.hword 350
.hword 76
.hword 170
.hword 188
.hword 250
.hword 352
.hword 400
.hword 106
.hword 294
.hword 82
.hword 412
.hword 134
.hword 214
.hword 144
.hword 146
.hword 208
.hword 120
.hword 184
.hword 66
.hword 36
.hword 18
.hword 316
.hword 26
.hword 66
.hword 138
.hword 444
.hword 142
.hword 440
.hword 194
.hword 36
.hword 302
.hword 210
.hword 388
.hword 244
.hword 100
.hword 508
.hword 388
.hword 128
.hword 70
.hword 324
.hword 506
.hword 234
.hword 144
.hword 392
.hword 428
.hword 126
.hword 96
.hword 348
.hword 486
.hword 66
.hword 422
.hword 6
.hword 184
.hword 8
.hword 214
.hword 252
.hword 0
.hword 394
.hword 128
.hword 294
.hword 148
.hword 18
.hword 230
.hword 282
.hword 70
.hword 56
.hword 244
.hword 494
.hword 342
.hword 180
.hword 190
.hword 256
.hword 118
.hword 172
.hword 280
.hword 238
.hword 14
.hword 490
.hword 174
.hword 132
.hword 270
.hword 366
.hword 170
.hword 386
.hword 176
.hword 96
.hword 434
.hword 372
.hword 478
.hword 330
.hword 422
.hword 148
.hword 50
.hword 266
.hword 148
.hword 302
.hword 364
.hword 428
.hword 498
.hword 62
.hword 124
.hword 496
.hword 458
.hword 392
.hword 378
.hword 272
.hword 502
.hword 396
.hword 46
.hword 374
.hword 202
.hword 234
.hword 244
.hword 172
.hword 344
.hword 506
.hword 334
.hword 452
.hword 464
.hword 486
.hword 428
.hword 24
.hword 28
.hword 416
.hword 248
.hword 456
.hword 208
.hword 244
.hword 510
.hword 456
.hword 218
.hword 50
.hword 348
.hword 30
.hword 144
.hword 148
.hword 314
.hword 12
.hword 104
.hword 350
.hword 308
.hword 474
.hword 444
.hword 150
.hword 8
.hword 336
.hword 258
.hword 238
.hword 502
.hword 130
.hword 80
.hword 470
.hword 92
.hword 490
.hword 240
.hword 68
.hword 444
.hword 392
.hword 288
.hword 96
.hword 260
.hword 248
.hword 44
.hword 184
.hword 492
.hword 124
.hword 176
.hword 346
.hword 128
.hword 436
.hword 210
.hword 398
.hword 212
.hword 368
    .global region_idx32
    region_idx32:
    .word 468
.word 64
.word 704
.word 96
.word 888
.word 472
.word 56
.word 568
.word 500
.word 740
.word 420
.word 364
.word 8
.word 20
.word 836
.word 36
.word 104
.word 872
.word 116
.word 128
.word 48
.word 956
.word 204
.word 340
.word 180
.word 596
.word 356
.word 172
.word 672
.word 464
.word 52
.word 896
.word 880
.word 1004
.word 332
.word 784
.word 620
.word 780
.word 12
.word 904
.word 372
.word 248
.word 0
.word 752
.word 168
.word 568
.word 456
.word 264
.word 544
.word 56
.word 156
.word 204
.word 760
.word 664
.word 192
.word 580
.word 116
.word 68
.word 340
.word 572
.word 564
.word 400
.word 1012
.word 12
.word 428
.word 928
.word 436
.word 264
.word 60
.word 564
.word 784
.word 600
.word 184
.word 508
.word 760
.word 244
.word 932
.word 416
.word 784
.word 296
.word 656
.word 440
.word 616
.word 84
.word 464
.word 168
.word 148
.word 140
.word 796
.word 608
.word 488
.word 668
.word 640
.word 932
.word 380
.word 268
.word 204
.word 400
.word 824
.word 636
.word 348
.word 992
.word 884
.word 400
.word 988
.word 296
.word 848
.word 396
.word 128
.word 316
.word 872
.word 84
.word 528
.word 352
.word 244
.word 596
.word 92
.word 184
.word 284
.word 852
.word 140
.word 752
.word 24
.word 568
.word 1008
.word 752
.word 848
.word 324
.word 756
.word 204
.word 196
.word 860
.word 28
.word 836
.word 496
.word 752
.word 756
.word 260
.word 984
.word 348
.word 864
.word 388
.word 912
.word 188
.word 244
.word 776
.word 156
.word 188
.word 252
.word 224
.word 140
.word 48
.word 816
.word 676
.word 924
.word 948
.word 312
.word 492
.word 896
.word 916
.word 56
.word 860
.word 692
.word 812
.word 540
.word 168
.word 280
.word 384
.word 784
.word 676
.word 216
.word 352
.word 424
.word 724
.word 724
.word 292
.word 344
.word 400
.word 872
.word 748
.word 884
.word 120
.word 204
.word 804
.word 448
.word 728
.word 440
.word 460
.word 416
.word 448
.word 512
.word 928
.word 76
.word 732
.word 888
.word 632
.word 296
.word 884
.word 0
.word 336
.word 700
.word 292
.word 664
.word 212
.word 1004
.word 532
.word 736
.word 1008
.word 340
.word 948
.word 972
.word 464
.word 372
.word 112
.word 840
.word 892
.word 340
.word 944
.word 48
.word 172
.word 748
.word 904
.word 356
.word 456
.word 344
.word 8
.word 732
.word 964
.word 328
.word 40
.word 120
.word 32
.word 412
.word 984
.word 840
.word 216
.word 132
.word 568
.word 564
.word 964
.word 132
.word 960
.word 48
.word 176
.word 384
.word 524
.word 672
.word 4
.word 280
.word 92
.word 456
.word 968
.word 500
.word 424
.word 860
.word 152
.word 836
.word 644
.word 0
.word 176
.word 420
.word 1000
.word 668
.word 684
.word 872
.word 376
.word 48
.word 388
.word 640
.word 936
.word 860
.word 916
.word 260
.word 972
.word 208
.word 464
.word 476
.word 868
.word 984
.word 496
.word 708
.word 648
.word 432
.word 516
.word 20
.word 620
.word 568
.word 520
.word 356
.word 156
.word 188
.word 108
.word 512
.word 960
.word 348
.word 520
.word 36
.word 964
.word 740
.word 700
.word 748
.word 88
.word 632
.word 204
.word 860
.word 784
.word 208
.word 180
.word 292
.word 4
.word 468
.word 112
.word 60
.word 488
.word 904
.word 164
.word 500
.word 44
.word 332
.word 760
.word 488
.word 992
.word 332
.word 1000
.word 292
.word 920
.word 456
.word 16
.word 492
.word 244
.word 440
.word 140
.word 560
.word 652
.word 800
.word 868
.word 56
.word 584
.word 828
.word 352
.word 232
.word 932
.word 256
.word 516
.word 612
.word 176
.word 996
.word 544
.word 16
.word 16
.word 688
.word 36
.word 712
.word 640
.word 584
.word 740
.word 8
.word 140
.word 620
.word 544
.word 116
.word 788
.word 76
.word 900
.word 712
.word 484
.word 716
.word 124
.word 908
.word 68
.word 0
.word 876
.word 384
.word 76
.word 12
.word 836
.word 372
.word 444
.word 500
.word 444
.word 540
.word 528
.word 364
.word 136
.word 740
.word 760
.word 424
.word 304
.word 528
.word 612
.word 816
.word 4
.word 176
.word 288
.word 328
.word 40
.word 532
.word 320
.word 784
.word 128
.word 432
.word 68
.word 72
.word 868
.word 1012
.word 372
.word 724
.word 844
.word 740
.word 912
.word 476
.word 516
.word 560
.word 580
.word 1016
.word 660
.word 608
.word 660
.word 224
.word 540
.word 984
.word 608
.word 548
.word 448
.word 20
.word 936
.word 584
.word 736
.word 72
.word 320
.word 540
.word 340
.word 844
.word 464
.word 548
.word 32
.word 380
.word 1012
.word 900
.word 476
.word 948
.word 792
.word 352
.word 160
.word 508
.word 620
.word 1004
.word 388
.word 180
.word 908
.word 304
.word 952
.word 436
.word 636
.word 100
.word 60
.word 276
.word 476
.word 556
.word 16
.word 232
.word 528
.word 700
.word 512
.word 356
.word 424
.word 88
.word 344
.word 780
.word 592
.word 580
.word 180
.word 844
.word 24
.word 368
.word 804
.word 16
.word 804
.word 44
.word 592
.word 812
.word 848
.word 420
.word 524
.word 996
.word 4
.word 848
.word 148
.word 16
.word 468
.word 888
.word 880
.word 216
.word 228
.word 496
.word 32
.word 516
.word 420
.word 60
.word 68
.word 128
.word 560
.word 432
.word 56
.word 656
.word 16
.word 268
.word 964
.word 536
.word 680
.word 388
.word 120
.word 644
.word 568
.word 432
.word 264
.word 872
.word 776
.word 1004
.word 832
.word 932
.word 516
.word 172
.word 416
.word 468
.word 324
.word 468
.word 32
.word 860
.word 572
.word 364
.word 520
.word 560
.word 216
.word 620
.word 544
.word 112
.word 476
.word 568
.word 264
.word 252
.word 760
.word 208
.word 248
.word 256
.word 460
.word 100
.word 544
.word 68
.word 828
.word 660
.word 428
.word 960
.word 208
.word 704
.word 12
.word 316
.word 256
.word 340
.word 768
.word 552
.word 840
.word 884
.word 612
.word 204
.word 968
.word 476
.word 532
.word 508
.word 488
.word 952
.word 852
.word 548
.word 168
.word 796
.word 12
.word 88
.word 900
.word 332
.word 544
.word 624
.word 760
.word 692
.word 644
.word 904
.word 676
.word 604
.word 600
.word 296
.word 740
.word 552
.word 116
.word 728
.word 256
.word 800
.word 488
.word 964
.word 732
.word 192
.word 312
.word 676
.word 824
.word 204
.word 64
.word 324
.word 808
.word 144
.word 712
.word 788
.word 64
.word 932
.word 32
.word 28
.word 860
.word 832
.word 148
.word 244
.word 256
.word 496
.word 916
.word 764
.word 348
.word 516
.word 540
.word 236
.word 28
.word 924
.word 580
.word 604
.word 728
.word 952
.word 576
.word 864
.word 828
.word 896
.word 792
.word 368
.word 488
.word 1008
.word 660
.word 872
.word 280
.word 344
.word 364
.word 916
.word 636
.word 772
.word 676
.word 740
.word 84
.word 4
.word 836
.word 20
.word 652
.word 708
.word 332
.word 284
.word 228
.word 56
.word 616
.word 292
.word 712
.word 856
.word 948
.word 480
.word 188
.word 628
.word 512
.word 816
.word 976
.word 328
.word 928
.word 8
.word 488
.word 328
.word 564
.word 976
.word 936
.word 492
.word 32
.word 580
.word 996
.word 776
.word 1000
.word 116
.word 964
.word 748
.word 988
.word 304
.word 308
.word 396
.word 36
.word 272
.word 288
.word 156
.word 352
.word 368
.word 360
.word 96
.word 696
.word 864
.word 884
.word 312
.word 224
.word 668
.word 456
.word 300
.word 384
.word 212
.word 780
.word 728
.word 324
.word 636
.word 56
.word 220
.word 340
.word 624
.word 360
.word 4
.word 840
.word 180
.word 560
.word 744
.word 536
.word 416
.word 612
.word 208
.word 572
.word 516
.word 696
.word 476
.word 924
.word 648
.word 896
.word 72
.word 504
.word 836
.word 864
.word 56
.word 880
.word 464
.word 808
.word 724
.word 40
.word 352
.word 676
.word 928
.word 320
.word 772
.word 892
.word 436
.word 288
.word 188
.word 940
.word 44
.word 628
.word 820
.word 660
.word 196
.word 908
.word 276
.word 1008
.word 8
.word 316
.word 16
.word 88
.word 232
.word 740
.word 892
.word 68
.word 796
.word 544
.word 788
.word 352
.word 844
.word 396
.word 188
.word 240
.word 1000
.word 716
.word 236
.word 584
.word 152
.word 972
.word 300
.word 364
.word 540
.word 400
.word 124
.word 168
.word 756
.word 624
.word 380
.word 96
.word 580
.word 988
.word 748
.word 928
.word 920
.word 716
.word 836
.word 324
.word 548
.word 364
.word 1012
.word 88
.word 540
.word 252
.word 548
.word 360
.word 160
.word 456
.word 152
.word 472
.word 172
.word 904
.word 604
.word 460
.word 424
.word 980
.word 392
.word 84
.word 128
.word 216
.word 388
.word 396
.word 384
.word 908
.word 632
.word 124
.word 396
.word 360
.word 428
.word 112
.word 276
.word 792
.word 132
.word 288
.word 304
.word 444
.word 40
.word 836
.word 208
.word 168
.word 332
.word 968
.word 148
.word 400
.word 680
.word 336
.word 284
.word 192
.word 628
.word 476
.word 656
.word 1004
.word 456
.word 500
.word 456
.word 460
.word 592
.word 4
.word 268
.word 292
.word 20
.word 232
.word 660
.word 36
.word 620
.word 456
.word 484
.word 136
.word 896
.word 512
.word 520
.word 464
.word 308
.word 228
.word 728
.word 816
.word 984
.word 948
.word 752
.word 136
.word 928
.word 96
.word 112
.word 352
.word 120
.word 624
.word 156
.word 644
.word 716
.word 636
.word 396
.word 588
.word 488
.word 392
.word 268
.word 800
.word 752
.word 976
.word 864
.word 600
.word 164
.word 224
.word 196
.word 572
.word 344
.word 772
.word 284
.word 848
.word 544
.word 732
.word 768
.word 908
.word 812
.word 972
.word 212
.word 500
.word 176
.word 552
.word 372
.word 344
.word 148
.word 672
.word 92
.word 608
.word 248
.word 180
.word 400
.word 708
.word 600
.word 824
.word 740
.word 184
.word 228
.word 168
.word 836
.word 652
.word 32
.word 116
.word 452
.word 828
.word 648
.word 656
.word 296
.word 32
.word 700
.word 788
.word 884
.word 520
.word 88
.word 508
.word 524
.word 316
.word 16
.word 288
.word 284
.word 512
.word 140
.word 0
.word 636
.word 812
.word 252
.word 800
.word 288
.word 752
.word 208
.word 616
.word 248
.word 300
.word 228
.word 672
.word 712
.word 132
.word 976
.word 268
.word 500
.word 44
.word 612
.word 880
.word 836
.word 848
.word 484
.word 460
.word 308
.word 448
.word 972
.word 948
.word 924
.word 688
.word 224
.word 724
.word 716
.word 364
.word 660
.word 296
.word 664
.word 116
.word 848
.word 72
.word 688
.word 924
.word 528
.word 928
.word 864
.word 232
.word 268
.word 36
.word 692
.word 352
.word 716
.word 972
.word 888
.word 312
.word 1020
.word 884
.word 568
.word 832
.word 496
.word 964
.word 612
.word 508
    .global region_idx64
    region_idx64:
    .quad 1344
.quad 1888
.quad 1456
.quad 1512
.quad 568
.quad 1776
.quad 992
.quad 1496
.quad 752
.quad 944
.quad 72
.quad 1880
.quad 1248
.quad 1632
.quad 1784
.quad 1312
.quad 1880
.quad 984
.quad 1056
.quad 192
.quad 1568
.quad 1664
.quad 1456
.quad 848
.quad 464
.quad 736
.quad 128
.quad 472
.quad 1528
.quad 1104
.quad 576
.quad 1696
.quad 1120
.quad 592
.quad 1072
.quad 1880
.quad 1672
.quad 808
.quad 1320
.quad 1984
.quad 1728
.quad 1384
.quad 1536
.quad 752
.quad 2040
.quad 2008
.quad 1768
.quad 1216
.quad 432
.quad 1568
.quad 1968
.quad 920
.quad 696
.quad 240
.quad 1240
.quad 1968
.quad 1920
.quad 656
.quad 432
.quad 1872
.quad 1752
.quad 1856
.quad 1952
.quad 192
.quad 1744
.quad 232
.quad 1672
.quad 1248
.quad 536
.quad 72
.quad 832
.quad 856
.quad 1552
.quad 1080
.quad 240
.quad 400
.quad 1816
.quad 1576
.quad 424
.quad 880
.quad 1152
.quad 864
.quad 208
.quad 472
.quad 376
.quad 1816
.quad 1192
.quad 16
.quad 1296
.quad 8
.quad 552
.quad 2032
.quad 240
.quad 40
.quad 1120
.quad 312
.quad 1720
.quad 1808
.quad 408
.quad 1256
.quad 1416
.quad 1272
.quad 784
.quad 968
.quad 1928
.quad 304
.quad 168
.quad 744
.quad 80
.quad 1464
.quad 248
.quad 992
.quad 1600
.quad 1488
.quad 1888
.quad 8
.quad 1680
.quad 1336
.quad 1464
.quad 1208
.quad 112
.quad 1992
.quad 432
.quad 1856
.quad 1912
.quad 1224
.quad 1272
.quad 1176
.quad 952
.quad 184
.quad 1328
.quad 1920
.quad 360
.quad 1440
.quad 1824
.quad 1024
.quad 1344
.quad 1752
.quad 960
.quad 1496
.quad 936
.quad 1152
.quad 1680
.quad 1104
.quad 624
.quad 1896
.quad 280
.quad 1632
.quad 376
.quad 824
.quad 160
.quad 1280
.quad 1040
.quad 400
.quad 1384
.quad 1904
.quad 1912
.quad 1416
.quad 1536
.quad 1960
.quad 1192
.quad 592
.quad 1768
.quad 640
.quad 1824
.quad 1704
.quad 1456
.quad 536
.quad 112
.quad 728
.quad 592
.quad 1808
.quad 688
.quad 1056
.quad 2040
.quad 608
.quad 944
.quad 832
.quad 1560
.quad 1456
.quad 1664
.quad 320
.quad 1336
.quad 1968
.quad 32
.quad 1008
.quad 32
.quad 1560
.quad 1672
.quad 1432
.quad 1512
.quad 1392
.quad 1096
.quad 856
.quad 504
.quad 80
.quad 176
.quad 1512
.quad 336
.quad 1952
.quad 1184
.quad 1032
.quad 1112
.quad 1952
.quad 1920
.quad 1088
.quad 1960
.quad 336
.quad 1176
.quad 488
.quad 1720
.quad 1768
.quad 1656
.quad 1272
.quad 1536
.quad 848
.quad 888
.quad 1632
.quad 792
.quad 1312
.quad 536
.quad 1784
.quad 1912
.quad 1984
.quad 1704
.quad 1328
.quad 360
.quad 1984
.quad 512
.quad 960
.quad 1184
.quad 1720
.quad 840
.quad 1856
.quad 432
.quad 88
.quad 1616
.quad 1768
.quad 0
.quad 832
.quad 696
.quad 808
.quad 1896
.quad 1600
.quad 1552
.quad 504
.quad 816
.quad 64
.quad 1896
.quad 552
.quad 1840
.quad 1328
.quad 104
.quad 1952
.quad 256
.quad 808
.quad 792
.quad 1632
.quad 1896
.quad 408
.quad 1728
.quad 1744
.quad 96
.quad 1560
.quad 1048
.quad 912
.quad 1472
.quad 1832
.quad 560
.quad 72
.quad 1472
.quad 1608
.quad 752
.quad 72
.quad 560
.quad 1768
.quad 800
.quad 360
.quad 1944
.quad 72
.quad 1848
.quad 632
.quad 1864
.quad 360
.quad 1872
.quad 1328
.quad 360
.quad 960
.quad 1832
.quad 264
.quad 432
.quad 1872
.quad 1712
.quad 752
.quad 1104
.quad 576
.quad 488
.quad 1424
.quad 816
.quad 800
.quad 880
.quad 296
.quad 1496
.quad 1192
.quad 1240
.quad 56
.quad 1672
.quad 1280
.quad 808
.quad 1776
.quad 1520
.quad 536
.quad 1616
.quad 1744
.quad 128
.quad 496
.quad 768
.quad 408
.quad 1808
.quad 1464
.quad 1440
.quad 128
.quad 856
.quad 80
.quad 368
.quad 928
.quad 192
.quad 64
.quad 464
.quad 1016
.quad 496
.quad 1328
.quad 752
.quad 464
.quad 360
.quad 1840
.quad 296
.quad 408
.quad 1728
.quad 480
.quad 504
.quad 1864
.quad 1144
.quad 1408
.quad 408
.quad 1080
.quad 1000
.quad 672
.quad 560
.quad 1568
.quad 176
.quad 1200
.quad 2008
.quad 696
.quad 936
.quad 1688
.quad 800
.quad 1624
.quad 400
.quad 1920
.quad 1008
.quad 2032
.quad 1296
.quad 16
.quad 616
.quad 648
.quad 976
.quad 392
.quad 480
.quad 432
.quad 1080
.quad 1768
.quad 1608
.quad 1992
.quad 120
.quad 1920
.quad 1056
.quad 1424
.quad 816
.quad 1136
.quad 144
.quad 1304
.quad 1920
.quad 1752
.quad 528
.quad 8
.quad 1152
.quad 872
.quad 760
.quad 1032
.quad 552
.quad 1888
.quad 1072
.quad 352
.quad 1408
.quad 1520
.quad 1608
.quad 1888
.quad 1296
.quad 1560
.quad 1072
.quad 16
.quad 1584
.quad 1344
.quad 1056
.quad 424
.quad 1992
.quad 1232
.quad 1072
.quad 1168
.quad 648
.quad 1960
.quad 912
.quad 384
.quad 1000
.quad 96
.quad 576
.quad 1248
.quad 320
.quad 704
.quad 880
.quad 1536
.quad 1832
.quad 2032
.quad 520
.quad 816
.quad 736
.quad 304
.quad 1544
.quad 1128
.quad 168
.quad 704
.quad 1688
.quad 1624
.quad 1472
.quad 1088
.quad 1120
.quad 1856
.quad 424
.quad 1712
.quad 184
.quad 1872
.quad 472
.quad 608
.quad 1552
.quad 1848
.quad 1904
.quad 1768
.quad 1504
.quad 1280
.quad 1080
.quad 1864
.quad 1944
.quad 104
.quad 1696
.quad 1608
.quad 1336
.quad 296
.quad 72
.quad 696
.quad 584
.quad 1488
.quad 624
.quad 424
.quad 704
.quad 472
.quad 792
.quad 432
.quad 1920
.quad 928
.quad 1512
.quad 160
.quad 1416
.quad 1808
.quad 872
.quad 1488
.quad 688
.quad 1048
.quad 240
.quad 168
.quad 928
.quad 248
.quad 416
.quad 200
.quad 800
.quad 24
.quad 320
.quad 1360
.quad 704
.quad 1040
.quad 88
.quad 776
.quad 8
.quad 704
.quad 1776
.quad 944
.quad 1312
.quad 968
.quad 1200
.quad 280
.quad 1048
.quad 1088
.quad 1488
.quad 96
.quad 1504
.quad 1920
.quad 1912
.quad 1456
.quad 496
.quad 16
.quad 1608
.quad 584
.quad 2024
.quad 2008
.quad 56
.quad 96
.quad 760
.quad 296
.quad 888
.quad 976
.quad 1680
.quad 720
.quad 24
.quad 2016
.quad 1224
.quad 1104
.quad 1824
.quad 1920
.quad 296
.quad 768
.quad 232
.quad 552
.quad 2040
.quad 584
.quad 1688
.quad 1296
.quad 1424
.quad 1232
.quad 816
.quad 1128
.quad 1744
.quad 384
.quad 1888
.quad 536
.quad 1496
.quad 592
.quad 808
.quad 1768
.quad 1192
.quad 1672
.quad 200
.quad 416
.quad 320
.quad 296
.quad 1600
.quad 208
.quad 56
.quad 136
.quad 96
.quad 2016
.quad 1040
.quad 1656
.quad 344
.quad 32
.quad 600
.quad 8
.quad 816
.quad 1408
.quad 1064
.quad 632
.quad 576
.quad 200
.quad 984
.quad 944
.quad 752
.quad 32
.quad 160
.quad 864
.quad 1768
.quad 480
.quad 576
.quad 536
.quad 1240
.quad 584
.quad 1160
.quad 624
.quad 400
.quad 40
.quad 56
.quad 1160
.quad 1752
.quad 1120
.quad 1016
.quad 1328
.quad 848
.quad 320
.quad 1560
.quad 2032
.quad 64
.quad 272
.quad 1560
.quad 1656
.quad 832
.quad 448
.quad 1128
.quad 896
.quad 1536
.quad 656
.quad 1112
.quad 624
.quad 120
.quad 992
.quad 1488
.quad 488
.quad 1608
.quad 1112
.quad 944
.quad 512
.quad 896
.quad 1992
.quad 512
.quad 488
.quad 1312
.quad 1560
.quad 1800
.quad 960
.quad 1336
.quad 72
.quad 1576
.quad 312
.quad 1712
.quad 1896
.quad 456
.quad 1672
.quad 816
.quad 288
.quad 888
.quad 104
.quad 1144
.quad 312
.quad 96
.quad 1192
.quad 1200
.quad 1296
.quad 176
.quad 776
.quad 1648
.quad 568
.quad 1968
.quad 416
.quad 592
.quad 896
.quad 1032
.quad 40
.quad 1680
.quad 16
.quad 640
.quad 1632
.quad 320
.quad 1080
.quad 1512
.quad 1592
.quad 1424
.quad 232
.quad 1160
.quad 1664
.quad 1928
.quad 1888
.quad 1952
.quad 1088
.quad 1760
.quad 208
.quad 600
.quad 248
.quad 456
.quad 392
.quad 1704
.quad 376
.quad 1328
.quad 1928
.quad 808
.quad 1632
.quad 832
.quad 648
.quad 1744
.quad 1672
.quad 328
.quad 1576
.quad 1928
.quad 720
.quad 1296
.quad 56
.quad 1616
.quad 16
.quad 752
.quad 664
.quad 1200
.quad 88
.quad 1528
.quad 248
.quad 888
.quad 520
.quad 992
.quad 360
.quad 1192
.quad 296
.quad 128
.quad 536
.quad 1760
.quad 1504
.quad 1768
.quad 904
.quad 576
.quad 1352
.quad 1800
.quad 1896
.quad 1520
.quad 0
.quad 984
.quad 1944
.quad 712
.quad 568
.quad 816
.quad 584
.quad 1088
.quad 1288
.quad 840
.quad 736
.quad 856
.quad 160
.quad 408
.quad 1456
.quad 1448
.quad 368
.quad 1248
.quad 1896
.quad 2024
.quad 2016
.quad 288
.quad 368
.quad 232
.quad 1536
.quad 1056
.quad 2024
.quad 304
.quad 1952
.quad 1248
.quad 1152
.quad 400
.quad 632
.quad 984
.quad 16
.quad 1248
.quad 1832
.quad 936
.quad 72
.quad 648
.quad 1176
.quad 1600
.quad 376
.quad 1744
.quad 488
.quad 568
.quad 40
.quad 1664
.quad 72
.quad 800
.quad 712
.quad 992
.quad 1792
.quad 472
.quad 1152
.quad 1280
.quad 1096
.quad 200
.quad 1264
.quad 1208
.quad 1096
.quad 2024
.quad 616
.quad 1536
.quad 1800
.quad 1832
.quad 968
.quad 944
.quad 1536
.quad 288
.quad 1864
.quad 584
.quad 0
.quad 96
.quad 976
.quad 1024
.quad 1232
.quad 1328
.quad 1024
.quad 864
.quad 1848
.quad 1152
.quad 1920
.quad 656
.quad 272
.quad 168
.quad 616
.quad 880
.quad 536
.quad 1120
.quad 1016
.quad 2008
.quad 776
.quad 704
.quad 728
.quad 1384
.quad 1088
.quad 1680
.quad 1000
.quad 680
.quad 952
.quad 1904
.quad 224
.quad 688
.quad 1104
.quad 1984
.quad 120
.quad 0
.quad 1256
.quad 1296
.quad 1272
.quad 1616
.quad 528
.quad 568
.quad 272
.quad 232
.quad 1632
.quad 48
.quad 1576
.quad 152
.quad 1936
.quad 1112
.quad 912
.quad 1712
.quad 640
.quad 128
.quad 616
.quad 224
.quad 368
.quad 8
.quad 712
.quad 576
.quad 256
.quad 1880
.quad 1784
.quad 560
.quad 704
.quad 896
.quad 1120
.quad 360
.quad 136
.quad 232
.quad 568
.quad 368
.quad 456
.quad 424
.quad 1816
.quad 264
.quad 368
.quad 1616
.quad 1624
.quad 976
.quad 576
.quad 1104
.quad 432
.quad 760
.quad 16
.quad 424
.quad 592
.quad 192
.quad 136
.quad 152
.quad 736
.quad 376
.quad 104
.quad 1736
.quad 128
.quad 440
.quad 720
.quad 720
.quad 912
.quad 1168
.quad 680
.quad 1040
.quad 48
.quad 1360
.quad 360
.quad 392
.quad 1920
.quad 1072
.quad 1168
.quad 1568
.quad 1744
.quad 792
.quad 104
.quad 1984
.quad 8
.quad 1176
.quad 1600
.quad 1376
.quad 784
.quad 936
.quad 752
.quad 1752
.quad 480
.quad 920
.quad 328
.quad 1928
.quad 1696
.quad 624
.quad 120
.quad 1768
.quad 1016
.quad 1304
.quad 736
.quad 1632
.quad 560
.quad 72
.quad 1552
.quad 560
.quad 1800
.quad 1728
.quad 392
.quad 648
.quad 152
.quad 1456
.quad 768
.quad 2032
.quad 896
.quad 360
.quad 104
.quad 848
.quad 960
.quad 336
.quad 1944
.quad 312
.quad 784
.quad 1296
.quad 1840
.quad 384
.quad 1736
.quad 984
.quad 888
.quad 2000
.quad 1440
.quad 680
.quad 424
.quad 1784
.quad 272
.quad 808
.quad 0
.quad 536
.quad 144
.quad 688
.quad 1280
.quad 256
.quad 1808
.quad 1384
.quad 2000
.quad 1040
.quad 984
.quad 1256
.quad 280
.quad 616
.quad 0
.quad 1336
.quad 2016
.quad 336
.quad 1672
.quad 1336
.quad 1072
.quad 160
.quad 496
.quad 816
.quad 1056
.quad 1248
.quad 1712
.quad 1744
.quad 1136
.quad 1656
.quad 2032
.quad 1072
.quad 216
.quad 1808
.quad 2008
.quad 1032
.quad 1192
.quad 1056
.quad 1160
.quad 1472
.quad 728
.quad 1792
.quad 80
.quad 1232
.quad 1552
.quad 1928
.quad 560
.quad 472
.quad 712
.quad 1888
.quad 1088
.quad 448
.quad 112
.quad 1072
.quad 16
.quad 1624
.quad 208
.quad 1640
.quad 1504
.quad 568
.quad 384
.quad 2016
.quad 1048
.quad 160
.quad 376
.quad 64
.quad 576
    .global region_idx128
    region_idx128:
    .quad 215
.quad 9
.quad 209
.quad 93
.8byte 0x0
.align 2
kernel_instr_start:
.text
.globl mtvec_handler
.type  mtvec_handler, @function
.align           2
mtvec_handler:    
                  csrrw x5, mscratch, x5
                  csrr  x5, mip
                  la    x5, kernel_stack_end-248
                  sd    x1, 8(x5)
                  sd    x2, 16(x5)
                  sd    x3, 24(x5)
                  sd    x4, 32(x5)
                  sd    x5, 40(x5)
                  sd    x6, 48(x5)
                  sd    x7, 56(x5)
                  sd    x8, 64(x5)
                  sd    x9, 72(x5)
                  sd    x10, 80(x5)
                  sd    x11, 88(x5)
                  sd    x12, 96(x5)
                  sd    x13, 104(x5)
                  sd    x14, 112(x5)
                  sd    x15, 120(x5)
                  sd    x16, 128(x5)
                  sd    x17, 136(x5)
                  sd    x18, 144(x5)
                  sd    x19, 152(x5)
                  sd    x20, 160(x5)
                  sd    x21, 168(x5)
                  sd    x22, 176(x5)
                  sd    x23, 184(x5)
                  sd    x24, 192(x5)
                  sd    x25, 200(x5)
                  sd    x26, 208(x5)
                  sd    x27, 216(x5)
                  sd    x28, 224(x5)
                  sd    x29, 232(x5)
                  sd    x30, 240(x5)
                  sd    x31, 248(x5)
                  csrr  x7, mstatus 
                  csrr  x7, mcause 
                  srli  x7, x7, 63
                  bne   x7, x0, mmode_intr_handler

mmode_exception_handler:
                  csrr x7, mepc # MEPC
                  csrr x7, mcause # MCAUSE
                  li x4, 0x3 # BREAKPOINT
                  beq x7, x4, ebreak_handler
                  li x4, 0x8 # ECALL_UMODE
                  beq x7, x4, ecall_handler
                  li x4, 0x9 # ECALL_SMODE
                  beq x7, x4, ecall_handler
                  li x4, 0xb # ECALL_MMODE
                  beq x7, x4, ecall_handler
                  li x4, 0x1
                  beq x7, x4, instr_fault_handler
                  li x4, 0x5
                  beq x7, x4, load_fault_handler
                  li x4, 0x7
                  beq x7, x4, store_fault_handler
                  li x4, 0xc
                  beq x7, x4, pt_fault_handler
                  li x4, 0xd
                  beq x7, x4, pt_fault_handler
                  li x4, 0xf
                  beq x7, x4, pt_fault_handler
                  li x4, 0x2 # ILLEGAL_INSTRUCTION
                  beq x7, x4, illegal_instr_handler
                  csrr x4, mtval # MTVAL
                  jal x1, test_done 

ecall_handler:    
                  la x7, _start
                  sd x0, 0(x7)
                  sd x1, 8(x7)
                  sd x2, 16(x7)
                  sd x3, 24(x7)
                  sd x4, 32(x7)
                  sd x5, 40(x7)
                  sd x6, 48(x7)
                  sd x7, 56(x7)
                  sd x8, 64(x7)
                  sd x9, 72(x7)
                  sd x10, 80(x7)
                  sd x11, 88(x7)
                  sd x12, 96(x7)
                  sd x13, 104(x7)
                  sd x14, 112(x7)
                  sd x15, 120(x7)
                  sd x16, 128(x7)
                  sd x17, 136(x7)
                  sd x18, 144(x7)
                  sd x19, 152(x7)
                  sd x20, 160(x7)
                  sd x21, 168(x7)
                  sd x22, 176(x7)
                  sd x23, 184(x7)
                  sd x24, 192(x7)
                  sd x25, 200(x7)
                  sd x26, 208(x7)
                  sd x27, 216(x7)
                  sd x28, 224(x7)
                  sd x29, 232(x7)
                  sd x30, 240(x7)
                  sd x31, 248(x7)
                  j write_tohost

instr_fault_handler:
                  j restore

load_fault_handler:
                  # Clear vstart in case this came from a vector load
                  csrw vstart, 0 
                  # Advance PC by 4. This is incorrect for
                  # Compressed instructions
                  csrr  x7, mepc
                  addi  x7, x7, 4
                  csrw  mepc, x7
                  j restore

store_fault_handler:
                  # Clear vstart in case this came from a vector load
                  csrw vstart, 0 
                  # Advance PC by 4. This is incorrect for
                  # Compressed instructions
                  csrr  x7, mepc
                  addi  x7, x7, 4
                  csrw  mepc, x7
                  j restore

ebreak_handler:   
                  csrr  x7, mepc
                  addi  x7, x7, 4
                  csrw  mepc, x7
                  j restore

illegal_instr_handler:
                  csrr  x7, mepc
                  addi  x7, x7, 4
                  csrw  mepc, x7
                  j restore

pt_fault_handler: 
                  nop
                  j restore

.align 2

mmode_intr_handler:
                  csrr  x7, mstatus # MSTATUS;
                  csrr  x7, mie # MIE;
                  csrr  x7, mcause

                  /* Clear the top bit of mcause (bit 63) that
                   * indicates Interrupt. This way
                   * we can then compare the rest of the mcause register
                   * We shift left by one and then shift right logical by one
                   */
                  slli  x7, x7, 1;                                                 
                  srli  x7, x7, 1;                                                 

                  /*
                   * Now check if we have the MEIP cause set
                   */
                  add   x6, x7, -IRQ_M_EXT
                  beqz  x6, ext_m_interrupt; /*jump to external machine interrupt*/
                  add   x6, x7, -IRQ_M_TIMER
                  beqz  x6, ext_m_timer; /*jump to external timer interrupt*/
                  j other_interrupt; /* other interrups */                        

ext_m_interrupt:                                                
                  /* Clear the bit in the PLIC */
                  li t2, 0xc200004; /*PLIC clear interrupt for source 0*/
                  lw t1, 0(t2); /*reading this address clears the interrupt*/
                  sw t1, 0(t2); /*writing the interrupt id to complete it*/

                  /* Clear the PENDING BIT from MIP */
                  li    x7, MIP_MEIP 
                  csrrc x7, mip, x7 # MIP;
                  j restore 

ext_m_timer:                                                
                  /* Program mtimecmp again with "current time + 1 "
                   */
                  li a0, 0x200BFF8 /*mtime*/
                  ld a0, 0(a0)
                  addi a0, a0, TIMER_INTERVAL
                  li t1, 0x2004000 /*mtimecmp*/
                  sd a0, 0(t1)

                  /* Clear the MTIP PENDING BIT from MIP */
                  li    x7, MIP_MTIP 
                  csrrc x7, mip, x7 # MIP;
                  j restore

other_interrupt:
                  ecall # This will terminate the test

restore:
                  ld  x1, 8(x5)
                  ld  x2, 16(x5)
                  ld  x3, 24(x5)
                  ld  x4, 32(x5)
                  ld  x5, 40(x5)
                  ld  x6, 48(x5)
                  ld  x7, 56(x5)
                  ld  x8, 64(x5)
                  ld  x9, 72(x5)
                  ld  x10, 80(x5)
                  ld  x11, 88(x5)
                  ld  x12, 96(x5)
                  ld  x13, 104(x5)
                  ld  x14, 112(x5)
                  ld  x15, 120(x5)
                  ld  x16, 128(x5)
                  ld  x17, 136(x5)
                  ld  x18, 144(x5)
                  ld  x19, 152(x5)
                  ld  x20, 160(x5)
                  ld  x21, 168(x5)
                  ld  x22, 176(x5)
                  ld  x23, 184(x5)
                  ld  x24, 192(x5)
                  ld  x25, 200(x5)
                  ld  x26, 208(x5)
                  ld  x27, 216(x5)
                  ld  x28, 224(x5)
                  ld  x29, 232(x5)
                  ld  x30, 240(x5)
                  ld  x31, 248(x5)
                  csrrw x5, mscratch, x5
                  mret

kernel_instr_end: nop
.section .kernel_stack,"aw",@progbits;
.align 2
kernel_stack_start:
.rept 3999
.8byte 0x0
.endr
kernel_stack_end:
.8byte 0x0



.section ".memory_end","aw",@progbits
region_edge: #256 bytes at the very end of the physical memory
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff

#ifdef FLUSH_L2_LOOP
.section ".zero_1MB_region","aw",@progbits
.align 20
zero_1MB_region:
.rept  131072
.8byte 0x0
.endr
#endif

