.section .text.init
.globl _start
_start:
    # Set the stack pointer to the end of the stack section
    la sp, __stack_end

    # Jump to main
    jal zero, main

.section ".tohost","aw",@progbits
.align 6
.globl tohost
tohost: .dword 0
.align 6
.globl fromhost
fromhost: .dword 0
