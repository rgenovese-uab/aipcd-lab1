	.file	"dhry_1.c"
	.option nopic
	.attribute arch, "rv64i2p0_m2p0_a2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	Proc_1
	.type	Proc_1, @function
Proc_1:
	addi	sp,sp,-32
	sd	s2,0(sp)
	lla	s2,Ptr_Glob
	ld	a5,0(s2)
	sd	s0,16(sp)
	ld	s0,0(a0)
	ld	a3,0(a5)
	ld	a1,32(a5)
	ld	a2,40(a5)
	sd	ra,24(sp)
	sd	s1,8(sp)
	ld	a6,8(a5)
	ld	a7,16(a5)
	ld	a4,48(a5)
	mv	s1,a0
	ld	a0,24(a5)
	sd	a3,0(s0)
	ld	ra,0(s1)
	li	t0,5
	sd	a7,16(s0)
	sd	a0,24(s0)
	sd	a1,32(s0)
	sd	a2,40(s0)
	sd	a6,8(s0)
	sd	a4,48(s0)
	sw	t0,16(s1)
	sd	ra,0(s0)
	ld	t1,0(a5)
	lw	a1,Int_Glob
	sw	t0,16(s0)
	sd	t1,0(s0)
	ld	t2,0(s2)
	li	a0,10
	addi	a2,t2,16
	call	Proc_7
	lw	t3,8(s0)
	beq	t3,zero,.L5
	ld	t4,0(s1)
	ld	ra,24(sp)
	ld	s0,24(t4)
	ld	s2,16(t4)
	ld	t5,0(t4)
	ld	t6,8(t4)
	ld	a3,32(t4)
	ld	a6,40(t4)
	ld	a5,48(t4)
	sd	s0,24(s1)
	ld	s0,16(sp)
	sd	s2,16(s1)
	sd	t5,0(s1)
	sd	t6,8(s1)
	sd	a3,32(s1)
	sd	a6,40(s1)
	sd	a5,48(s1)
	ld	s2,0(sp)
	ld	s1,8(sp)
	addi	sp,sp,32
	jr	ra
.L5:
	lw	a0,12(s1)
	li	s1,6
	addi	a1,s0,12
	sw	s1,16(s0)
	call	Proc_6
	ld	a7,0(s2)
	lw	a0,16(s0)
	addi	a2,s0,16
	ld	a4,0(a7)
	ld	ra,24(sp)
	ld	s1,8(sp)
	sd	a4,0(s0)
	ld	s0,16(sp)
	ld	s2,0(sp)
	li	a1,10
	addi	sp,sp,32
	tail	Proc_7
	.size	Proc_1, .-Proc_1
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC0:
	.string	"Running Dhrystone Benchmark, Version 2.1 (Language: C)\n"
	.align	3
.LC3:
	.string	"\n"
	.align	3
.LC4:
	.string	"Program compiled with 'register' attribute\n"
	.align	3
.LC5:
	.string	"Program compiled without 'register' attribute\n"
	.align	3
.LC6:
	.string	"Execution starts, %d runs through Dhrystone\n"
	.align	3
.LC9:
	.string	"Execution ends\n"
	.align	3
.LC10:
	.string	"Final values of the variables used in the benchmark:\n"
	.align	3
.LC11:
	.string	"Int_Glob:            %d\n"
	.align	3
.LC12:
	.string	"        should be:   %d\n"
	.align	3
.LC13:
	.string	"Bool_Glob:           %d\n"
	.align	3
.LC14:
	.string	"Ch_1_Glob:           %c\n"
	.align	3
.LC15:
	.string	"        should be:   %c\n"
	.align	3
.LC16:
	.string	"Ch_2_Glob:           %c\n"
	.align	3
.LC17:
	.string	"Arr_1_Glob[8]:       %d\n"
	.align	3
.LC18:
	.string	"Arr_2_Glob[8][7]:    %d\n"
	.align	3
.LC19:
	.string	"        should be:   Number_Of_Runs + 10\n"
	.align	3
.LC20:
	.string	"Ptr_Glob->\n"
	.align	3
.LC21:
	.string	"  Ptr_Comp:          %d\n"
	.align	3
.LC22:
	.string	"        should be:   (implementation-dependent)\n"
	.align	3
.LC23:
	.string	"  Discr:             %d\n"
	.align	3
.LC24:
	.string	"  Enum_Comp:         %d\n"
	.align	3
.LC25:
	.string	"  Int_Comp:          %d\n"
	.align	3
.LC26:
	.string	"  Str_Comp:          %s\n"
	.align	3
.LC27:
	.string	"        should be:   DHRYSTONE PROGRAM, SOME STRING\n"
	.align	3
.LC28:
	.string	"Next_Ptr_Glob->\n"
	.align	3
.LC29:
	.string	"        should be:   (implementation-dependent), same as above\n"
	.align	3
.LC30:
	.string	"Int_1_Loc:           %d\n"
	.align	3
.LC31:
	.string	"Int_2_Loc:           %d\n"
	.align	3
.LC32:
	.string	"Int_3_Loc:           %d\n"
	.align	3
.LC33:
	.string	"Enum_Loc:            %d\n"
	.align	3
.LC34:
	.string	"Str_1_Loc:           %s\n"
	.align	3
.LC35:
	.string	"        should be:   DHRYSTONE PROGRAM, 1'ST STRING\n"
	.align	3
.LC36:
	.string	"Str_2_Loc:           %s\n"
	.align	3
.LC37:
	.string	"        should be:   DHRYSTONE PROGRAM, 2'ND STRING\n"
	.align	3
.LC1:
	.string	"DHRYSTONE PROGRAM, SOME STRING"
	.align	3
.LC2:
	.string	"DHRYSTONE PROGRAM, 1'ST STRING"
	.align	3
.LC7:
	.string	"DHRYSTONE PROGRAM, 2'ND STRING"
	.align	3
.LC8:
	.string	"DHRYSTONE PROGRAM, 3'RD STRING"
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-272
	lla	a0,.LC0
	sd	ra,264(sp)
	sd	s0,256(sp)
	sd	s1,248(sp)
	sd	s2,240(sp)
	sd	s3,232(sp)
	sd	s4,224(sp)
	sd	s5,216(sp)
	sd	s6,208(sp)
	sd	s7,200(sp)
	sd	s8,192(sp)
	sd	s9,184(sp)
	sd	s10,176(sp)
	sd	s11,168(sp)
	call	printf
	lla	a5,.LC1
	lla	a4,.LC2
	ld	a0,8(a4)
	lw	s0,0(a5)
	lw	t2,4(a5)
	lw	t0,8(a5)
	lw	t6,12(a5)
	lw	t5,16(a5)
	lw	t4,20(a5)
	lw	t3,24(a5)
	lhu	t1,28(a5)
	lbu	a7,30(a5)
	ld	a6,0(a4)
	ld	a1,16(a4)
	lw	a2,24(a4)
	lhu	a3,28(a4)
	li	s2,1
	addi	ra,sp,104
	lla	s6,Ptr_Glob
	lla	s1,Next_Ptr_Glob
	slli	s3,s2,33
	li	s4,40
	sd	ra,0(s1)
	sd	ra,0(s6)
	sd	ra,104(sp)
	sw	t2,128(sp)
	sw	t0,132(sp)
	sw	t6,136(sp)
	sw	t5,140(sp)
	sw	t4,144(sp)
	sw	t3,148(sp)
	sh	t1,152(sp)
	sb	a7,154(sp)
	sd	a6,40(sp)
	sd	a0,48(sp)
	sd	a1,56(sp)
	sw	a2,64(sp)
	sd	s3,112(sp)
	sw	s4,120(sp)
	sw	s0,124(sp)
	sh	a3,68(sp)
	lbu	s5,30(a4)
	li	s7,10
	lla	s8,Arr_2_Glob
	lla	a0,.LC3
	sw	s7,1628(s8)
	sb	s5,70(sp)
	call	printf
	lw	s9,Reg
	beq	s9,zero,.L7
	lla	a0,.LC4
	call	printf
	lla	a0,.LC3
	call	printf
.L8:
	li	a1,2000
	lla	a0,.LC6
	call	printf
	call	reset_pmu
	call	enable_PMU_32b
	lla	a5,.LC7
	lhu	s0,28(a5)
	lw	a4,24(a5)
	lbu	t2,30(a5)
	ld	s11,0(a5)
	ld	s10,8(a5)
	ld	s9,16(a5)
	sh	s0,16(sp)
	sw	a4,8(sp)
	sb	t2,24(sp)
	li	s1,1
	lla	s3,Ch_1_Glob
	lla	s4,Bool_Glob
	lla	s0,Ch_2_Glob
	lla	s5,Int_Glob
.L15:
	lw	t4,8(sp)
	lhu	t3,16(sp)
	lbu	t1,24(sp)
	li	t0,1
	li	t6,65
	li	t5,66
	addi	a1,sp,72
	addi	a0,sp,40
	sb	t6,0(s3)
	sw	t0,0(s4)
	sb	t5,0(s0)
	sw	t4,96(sp)
	sh	t3,100(sp)
	sb	t1,102(sp)
	sw	t0,36(sp)
	sd	s11,72(sp)
	sd	s10,80(sp)
	sd	s9,88(sp)
	call	Func_2
	seqz	a7,a0
	li	a6,7
	addi	a2,sp,32
	li	a1,3
	li	a0,2
	sw	a7,0(s4)
	sw	a6,32(sp)
	call	Proc_7
	lw	a3,32(sp)
	lla	a1,Arr_2_Glob
	li	a2,3
	lla	a0,.LANCHOR0
	call	Proc_8
	ld	a0,0(s6)
	li	s7,9
	call	Proc_1
	lbu	a0,0(s0)
	li	a1,64
	bleu	a0,a1,.L9
	li	s8,65
	li	s2,3
	lla	s7,.LC8
.L13:
	mv	a0,s8
	li	a1,67
	call	Func_1
	lw	a2,36(sp)
	sext.w	a5,a0
	addiw	a3,s8,1
	beq	a2,a5,.L21
	lbu	ra,0(s0)
	andi	s8,a3,0xff
	bgeu	ra,s8,.L13
.L12:
	slliw	t1,s2,1
	addw	s7,t1,s2
.L9:
	lw	a7,32(sp)
	lbu	a0,0(s3)
	li	a1,65
	divw	a6,s7,a7
	mv	ra,a6
	bne	a0,a1,.L14
	lw	a3,0(s5)
	addiw	a5,a6,9
	subw	ra,a5,a3
.L14:
	addiw	s1,s1,1
	li	s8,2001
	bne	s1,s8,.L15
	sd	ra,24(sp)
	sd	a6,16(sp)
	sd	a7,8(sp)
	call	disable_PMU_32b
	lla	a0,.LC9
	call	printf
	lla	a0,.LC3
	call	printf
	lla	a0,.LC10
	call	printf
	lla	a0,.LC3
	call	printf
	lw	a1,0(s5)
	lla	a0,.LC11
	lla	s11,Arr_2_Glob
	call	printf
	li	a1,5
	lla	a0,.LC12
	call	printf
	lw	a1,0(s4)
	lla	a0,.LC13
	call	printf
	li	a1,1
	lla	a0,.LC12
	call	printf
	lbu	a1,0(s3)
	lla	a0,.LC14
	call	printf
	li	a1,65
	lla	a0,.LC15
	call	printf
	lbu	a1,0(s0)
	lla	a0,.LC16
	lla	s0,Next_Ptr_Glob
	call	printf
	li	a1,66
	lla	a0,.LC15
	call	printf
	lw	a1,.LANCHOR0+32
	lla	a0,.LC17
	call	printf
	li	a1,7
	lla	a0,.LC12
	call	printf
	lw	a1,1628(s11)
	lla	a0,.LC18
	call	printf
	lla	a0,.LC19
	call	printf
	lla	a0,.LC20
	call	printf
	ld	s10,0(s6)
	lla	a0,.LC21
	lw	a1,0(s10)
	call	printf
	lla	a0,.LC22
	call	printf
	ld	s9,0(s6)
	lla	a0,.LC23
	lw	a1,8(s9)
	call	printf
	li	a1,0
	lla	a0,.LC12
	call	printf
	ld	s3,0(s6)
	lla	a0,.LC24
	lw	a1,12(s3)
	call	printf
	li	a1,2
	lla	a0,.LC12
	call	printf
	ld	s4,0(s6)
	lla	a0,.LC25
	lw	a1,16(s4)
	call	printf
	li	a1,17
	lla	a0,.LC12
	call	printf
	ld	s6,0(s6)
	lla	a0,.LC26
	addi	a1,s6,20
	call	printf
	lla	a0,.LC27
	call	printf
	lla	a0,.LC28
	call	printf
	ld	s5,0(s0)
	lla	a0,.LC21
	lw	a1,0(s5)
	call	printf
	lla	a0,.LC29
	call	printf
	ld	t2,0(s0)
	lla	a0,.LC23
	lw	a1,8(t2)
	call	printf
	li	a1,0
	lla	a0,.LC12
	call	printf
	ld	t0,0(s0)
	lla	a0,.LC24
	lw	a1,12(t0)
	call	printf
	li	a1,1
	lla	a0,.LC12
	call	printf
	ld	t6,0(s0)
	lla	a0,.LC25
	lw	a1,16(t6)
	call	printf
	li	a1,18
	lla	a0,.LC12
	call	printf
	ld	t5,0(s0)
	lla	a0,.LC26
	addi	a1,t5,20
	call	printf
	lla	a0,.LC27
	call	printf
	ld	a1,24(sp)
	lla	a0,.LC30
	call	printf
	li	a1,5
	lla	a0,.LC12
	call	printf
	ld	t4,8(sp)
	ld	t1,16(sp)
	lla	a0,.LC31
	subw	a4,s7,t4
	slliw	t3,a4,3
	subw	s2,t3,a4
	subw	a1,s2,t1
	call	printf
	li	a1,13
	lla	a0,.LC12
	call	printf
	lw	a1,32(sp)
	lla	a0,.LC32
	call	printf
	li	a1,7
	lla	a0,.LC12
	call	printf
	lw	a1,36(sp)
	lla	a0,.LC33
	call	printf
	li	a1,1
	lla	a0,.LC12
	call	printf
	addi	a1,sp,40
	lla	a0,.LC34
	call	printf
	lla	a0,.LC35
	call	printf
	addi	a1,sp,72
	lla	a0,.LC36
	call	printf
	lla	a0,.LC37
	call	printf
	lla	a0,.LC3
	call	printf
	call	print_PMU_events
	ld	ra,264(sp)
	ld	s0,256(sp)
	ld	s1,248(sp)
	ld	s2,240(sp)
	ld	s3,232(sp)
	ld	s4,224(sp)
	ld	s5,216(sp)
	ld	s6,208(sp)
	ld	s7,200(sp)
	ld	s8,192(sp)
	ld	s9,184(sp)
	ld	s10,176(sp)
	ld	s11,168(sp)
	li	a0,0
	addi	sp,sp,272
	jr	ra
.L21:
	addi	a1,sp,36
	li	a0,0
	call	Proc_6
	ld	t2,8(s7)
	ld	s2,0(s7)
	ld	t0,16(s7)
	lw	t6,24(s7)
	lhu	t5,28(s7)
	lbu	t4,30(s7)
	lbu	a4,0(s0)
	addiw	t3,s8,1
	sd	s2,72(sp)
	sd	t2,80(sp)
	sd	t0,88(sp)
	sw	t6,96(sp)
	sh	t5,100(sp)
	sb	t4,102(sp)
	sw	s1,0(s5)
	andi	s8,t3,0xff
	mv	s2,s1
	bgeu	a4,s8,.L13
	j	.L12
.L7:
	lla	a0,.LC5
	call	printf
	lla	a0,.LC3
	call	printf
	j	.L8
	.size	main, .-main
	.text
	.align	2
	.globl	Proc_2
	.type	Proc_2, @function
Proc_2:
	lbu	a4,Ch_1_Glob
	li	a5,65
	beq	a4,a5,.L24
	ret
.L24:
	lw	t0,0(a0)
	lw	t2,Int_Glob
	addiw	t1,t0,9
	subw	a1,t1,t2
	sw	a1,0(a0)
	ret
	.size	Proc_2, .-Proc_2
	.align	2
	.globl	Proc_3
	.type	Proc_3, @function
Proc_3:
	lla	a5,Ptr_Glob
	ld	a2,0(a5)
	beq	a2,zero,.L26
	ld	a4,0(a2)
	sd	a4,0(a0)
	ld	a2,0(a5)
.L26:
	addi	a2,a2,16
	lw	a1,Int_Glob
	li	a0,10
	tail	Proc_7
	.size	Proc_3, .-Proc_3
	.align	2
	.globl	Proc_4
	.type	Proc_4, @function
Proc_4:
	lla	a4,Bool_Glob
	lw	a3,0(a4)
	lbu	a5,Ch_1_Glob
	addi	t0,a5,-65
	seqz	t1,t0
	or	t2,t1,a3
	li	a1,66
	sw	t2,0(a4)
	sb	a1,Ch_2_Glob,a4
	ret
	.size	Proc_4, .-Proc_4
	.align	2
	.globl	Proc_5
	.type	Proc_5, @function
Proc_5:
	li	a5,65
	sb	a5,Ch_1_Glob,a4
	sw	zero,Bool_Glob,a5
	ret
	.size	Proc_5, .-Proc_5
	.globl	Reg
	.globl	Arr_2_Glob
	.globl	Arr_1_Glob
	.globl	Ch_2_Glob
	.globl	Ch_1_Glob
	.globl	Bool_Glob
	.globl	Int_Glob
	.globl	Next_Ptr_Glob
	.globl	Ptr_Glob
	.bss
	.align	3
	.set	.LANCHOR0,. + 0
	.type	Arr_1_Glob, @object
	.size	Arr_1_Glob, 200
Arr_1_Glob:
	.zero	200
	.type	Arr_2_Glob, @object
	.size	Arr_2_Glob, 10000
Arr_2_Glob:
	.zero	10000
	.section	.sbss,"aw",@nobits
	.align	3
	.type	Reg, @object
	.size	Reg, 4
Reg:
	.zero	4
	.type	Ch_2_Glob, @object
	.size	Ch_2_Glob, 1
Ch_2_Glob:
	.zero	1
	.type	Ch_1_Glob, @object
	.size	Ch_1_Glob, 1
Ch_1_Glob:
	.zero	1
	.zero	2
	.type	Bool_Glob, @object
	.size	Bool_Glob, 4
Bool_Glob:
	.zero	4
	.type	Int_Glob, @object
	.size	Int_Glob, 4
Int_Glob:
	.zero	4
	.type	Next_Ptr_Glob, @object
	.size	Next_Ptr_Glob, 8
Next_Ptr_Glob:
	.zero	8
	.type	Ptr_Glob, @object
	.size	Ptr_Glob, 8
Ptr_Glob:
	.zero	8
	.ident	"GCC: (GNU) 10.2.0"
