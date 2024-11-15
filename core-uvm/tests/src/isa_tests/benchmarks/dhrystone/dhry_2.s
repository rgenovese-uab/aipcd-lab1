	.file	"dhry_2.c"
	.option nopic
	.attribute arch, "rv64i2p0_m2p0_a2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	Proc_6
	.type	Proc_6, @function
Proc_6:
	li	a4,2
	beq	a0,a4,.L2
	li	a5,3
	sw	a5,0(a1)
	li	t0,1
	beq	a0,t0,.L3
	bleu	a0,t0,.L7
	li	a2,4
	bne	a0,a2,.L9
	sw	a4,0(a1)
.L6:
	ret
.L3:
	lw	t1,Int_Glob
	li	t2,100
	ble	t1,t2,.L6
.L7:
	sw	zero,0(a1)
	ret
.L9:
	ret
.L2:
	li	a3,1
	sw	a3,0(a1)
	ret
	.size	Proc_6, .-Proc_6
	.align	2
	.globl	Proc_7
	.type	Proc_7, @function
Proc_7:
	addiw	a0,a0,2
	addw	a1,a0,a1
	sw	a1,0(a2)
	ret
	.size	Proc_7, .-Proc_7
	.align	2
	.globl	Proc_8
	.type	Proc_8, @function
Proc_8:
	addiw	a5,a2,5
	li	a4,200
	mul	t0,a5,a4
	slli	a2,a2,2
	slli	t1,a5,2
	add	a0,a0,t1
	sw	a3,0(a0)
	sw	a5,120(a0)
	sw	a3,4(a0)
	li	t6,4096
	li	a6,5
	add	t2,t0,a2
	add	a7,a1,t2
	lw	a3,16(a7)
	sw	a5,20(a7)
	sw	a5,24(a7)
	addiw	t3,a3,1
	sw	t3,16(a7)
	lw	t4,0(a0)
	add	a1,a1,t0
	add	t5,a1,a2
	add	a5,t6,t5
	sw	t4,-76(a5)
	sw	a6,Int_Glob,a4
	ret
	.size	Proc_8, .-Proc_8
	.align	2
	.globl	Func_1
	.type	Func_1, @function
Func_1:
	andi	a0,a0,0xff
	andi	a1,a1,0xff
	beq	a0,a1,.L15
	li	a0,0
	ret
.L15:
	sb	a0,Ch_1_Glob,a5
	li	a0,1
	ret
	.size	Func_1, .-Func_1
	.align	2
	.globl	Func_2
	.type	Func_2, @function
Func_2:
	lbu	a4,2(a0)
	lbu	a5,3(a1)
	beq	a4,a5,.L18
	addi	sp,sp,-16
	sd	ra,8(sp)
	call	strcmp
	li	t0,0
	ble	a0,zero,.L19
	li	ra,10
	sw	ra,Int_Glob,a4
	li	t0,1
.L19:
	ld	ra,8(sp)
	mv	a0,t0
	addi	sp,sp,16
	jr	ra
.L18:
	j	.L18
	.size	Func_2, .-Func_2
	.align	2
	.globl	Func_3
	.type	Func_3, @function
Func_3:
	addi	a0,a0,-2
	seqz	a0,a0
	ret
	.size	Func_3, .-Func_3
	.ident	"GCC: (GNU) 10.2.0"
