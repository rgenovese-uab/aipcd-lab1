#include "test_macros_illegal.h"

.section .init
.globl _start
.globl _exit

INIT_TEST
jal x1, test_done;

END_TEST
.align 4; 
.section .user_stack,"aw",@progbits; 
.align 2 
user_stack_start: 
.rept 4999 
.8byte 0x0 
.endr 
user_stack_end: 
kernel_instr_end: nop 
.section .kernel_stack,"aw",@progbits; 
.align 2 
kernel_stack_start: 
.rept 3999 
.8byte 0x0 
.endr 
kernel_stack_end: 
.8byte 0x0 