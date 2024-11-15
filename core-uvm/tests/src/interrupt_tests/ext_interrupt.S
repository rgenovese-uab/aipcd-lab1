.globl _start
.section .text

_start:
        li	a1,0x1         #Index sum
        li      a2,0x80010000  #Infinte loop index memory address
        li      a3,0x80020000  #Interrupt handle n times memory address
        li	a4,0x3         #Number of interrupt handle calls
        j	interrupt_init

csr_setup:
#The next two instructions are needed for RTL, it will set the external interrupt mask, it is not supported by spike (yet)
#        li      t1,0x2
#        csrw    0x7e0,t1
        li      t1,0x0000000a00000008
        csrw	mstatus,t1
        li	t1,0xA00
        csrw	mie,t1
        j	infinite_loop

#Using t3 to not interfere with interrupt handler which uses t1 and t2
infinite_loop:
        lw      t3,0(a2)
        add	t3,a1,t3
        sw      t3,0(a2)
        j	infinite_loop

test_done:
        li  x1, 0x0
        sw x1, tohost, t5
        csrw 0x9f0, x1
        csrrw t0, 0xc00, t0 #cycle csr
	j test_done #infinite loop

test_fail:
	li x31, 3 #if the test fails, x31 = 3
	j test_done


interrupt_init:
        la	t1, interrupt_handler
        ori	t1, t1, 0
        csrw 	mtvec, t1
        j       csr_setup

interrupt_handler:
        lw      t2,0(a3)
        add	t2,a1,t2
        sw      t2,0(a3)
        beq	t2,a4,test_done
        mret

.section .data
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
