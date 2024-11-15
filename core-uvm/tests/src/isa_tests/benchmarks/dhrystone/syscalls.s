	.file	"syscalls.c"
	.option nopic
	.attribute arch, "rv64i2p0_m2p0_a2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	putchar
	.type	putchar, @function
putchar:
	lui	a4,%tprel_hi(buflen.1)
	add	a3,a4,tp,%tprel_add(buflen.1)
	lw	a6,%tprel_lo(buflen.1)(a3)
	lui	a1,%tprel_hi(.LANCHOR0)
	add	a5,a1,tp,%tprel_add(.LANCHOR0)
	addi	t0,a5,%tprel_lo(.LANCHOR0)
	addiw	a2,a6,1
	add	t1,t0,a6
	sw	a2,%tprel_lo(buflen.1)(a3)
	sb	a0,0(t1)
	li	t2,10
	beq	a0,t2,.L2
	li	a0,64
	beq	a2,a0,.L2
	li	a0,0
	ret
.L2:
	add	t3,a1,tp,%tprel_add(.LANCHOR0)
	li	a7,64
	li	a0,1
	addi	a1,t3,%tprel_lo(.LANCHOR0)
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	add	a2,a4,tp,%tprel_add(buflen.1)
	sw	zero,%tprel_lo(buflen.1)(a2)
	li	a0,0
	ret
	.size	putchar, .-putchar
	.align	2
	.type	sprintf_putch.0, @function
sprintf_putch.0:
	ld	a5,0(a1)
	sb	a0,0(a5)
	ld	t0,0(a1)
	addi	t1,t0,1
	sd	t1,0(a1)
	ret
	.size	sprintf_putch.0, .-sprintf_putch.0
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC0:
	.string	"(null)"
	.text
	.align	2
	.type	vprintfmt.constprop.1, @function
vprintfmt.constprop.1:
	addi	sp,sp,-320
	sd	s0,312(sp)
	sd	s1,304(sp)
	sd	s2,296(sp)
	sd	s3,288(sp)
	sd	s4,280(sp)
	sd	s5,272(sp)
	sd	s6,264(sp)
	li	a3,37
	li	t0,32
	li	s3,-1
	li	t6,85
	lla	t5,.L14
	li	t4,9
	li	t2,1
	li	s1,48
	li	s0,120
	li	s2,45
	j	.L287
.L10:
	beq	a4,zero,.L277
	ld	t3,0(a0)
	addi	a1,a1,1
	sb	a5,0(t3)
	ld	a7,0(a0)
	addi	s6,a7,1
	sd	s6,0(a0)
.L287:
	lbu	a5,0(a1)
	sext.w	a4,a5
	bne	a5,a3,.L10
	lbu	a7,1(a1)
	addi	t3,a1,1
	mv	a4,t3
	li	s5,32
	li	s4,-1
	li	t1,-1
	li	a6,0
.L11:
	addiw	a1,a7,-35
	andi	s6,a1,0xff
	addi	a1,a4,1
	bgtu	s6,t6,.L12
.L289:
	slli	a5,s6,2
	add	s6,a5,t5
	lw	a5,0(s6)
	add	s6,a5,t5
	jr	s6
	.section	.rodata
	.align	2
	.align	2
.L14:
	.word	.L28-.L14
	.word	.L12-.L14
	.word	.L27-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L26-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L23-.L14
	.word	.L24-.L14
	.word	.L12-.L14
	.word	.L23-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L22-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L21-.L14
	.word	.L20-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L19-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L70-.L14
	.word	.L17-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L16-.L14
	.word	.L12-.L14
	.word	.L15-.L14
	.word	.L12-.L14
	.word	.L12-.L14
	.word	.L13-.L14
	.text
.L277:
	ld	s0,312(sp)
	ld	s1,304(sp)
	ld	s2,296(sp)
	ld	s3,288(sp)
	ld	s4,280(sp)
	ld	s5,272(sp)
	ld	s6,264(sp)
	addi	sp,sp,320
	jr	ra
.L23:
	mv	s5,a7
	lbu	a7,1(a4)
	mv	a4,a1
	addiw	a1,a7,-35
	andi	s6,a1,0xff
	addi	a1,a4,1
	bleu	s6,t6,.L289
.L12:
	ld	a5,0(a0)
	mv	a1,t3
	sb	a3,0(a5)
	ld	s4,0(a0)
	addi	a6,s4,1
	sd	a6,0(a0)
	j	.L287
.L22:
	addiw	s4,a7,-48
	lbu	a7,1(a4)
	mv	a4,a1
	addiw	a5,a7,-48
	sext.w	a1,a7
	bgtu	a5,t4,.L30
.L31:
	lbu	a7,1(a4)
	slliw	s6,s4,2
	addw	s4,s6,s4
	slliw	a5,s4,1
	addw	a1,a5,a1
	addiw	s6,a7,-48
	addiw	s4,a1,-48
	addi	a4,a4,1
	sext.w	a1,a7
	bleu	s6,t4,.L31
.L30:
	bge	t1,zero,.L11
	mv	t1,s4
	li	s4,-1
	j	.L11
.L28:
	lbu	a7,1(a4)
	mv	a4,a1
	j	.L11
.L27:
	ld	s5,0(a0)
	sb	a3,0(s5)
	ld	a4,0(a0)
	addi	t1,a4,1
	sd	t1,0(a0)
	j	.L287
.L26:
	lw	s4,0(a2)
	lbu	a7,1(a4)
	addi	a2,a2,8
	mv	a4,a1
	j	.L30
.L17:
	ld	a5,0(a0)
	addi	t3,a2,8
	li	a7,16
	sb	s1,0(a5)
	ld	a6,0(a0)
	addi	s6,a6,1
	sd	s6,0(a0)
	sb	s0,1(a6)
	ld	s4,0(a0)
	addi	a5,s4,1
	sd	a5,0(a0)
.L53:
	ld	a4,0(a2)
	mv	a2,t3
.L52:
	remu	s4,a4,a7
	addi	t3,sp,4
	li	a6,1
	sw	s4,0(sp)
	bltu	a4,a7,.L290
.L61:
	divu	a4,a4,a7
	addi	t3,t3,4
	mv	s6,a6
	addiw	a6,a6,1
	remu	s4,a4,a7
	sw	s4,-4(t3)
	bgeu	a4,a7,.L61
	ble	t1,a6,.L58
.L57:
	sb	s5,0(a5)
	ld	t3,0(a0)
	sext.w	a7,t1
	sub	t1,a7,a6
	addi	a5,t3,1
	addiw	a4,t1,-1
	sd	a5,0(a0)
	addiw	t1,a7,-1
	andi	s4,a4,7
	ble	t1,a6,.L58
	sext.w	a7,s4
	beq	s4,zero,.L62
	li	a4,1
	beq	a7,a4,.L252
	li	s4,2
	beq	a7,s4,.L253
	li	a4,3
	beq	a7,a4,.L254
	li	s4,4
	beq	a7,s4,.L255
	li	a4,5
	beq	a7,a4,.L256
	li	s4,6
	beq	a7,s4,.L257
	sb	s5,1(t3)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a5,a5,1
	sd	a5,0(a0)
.L257:
	sb	s5,0(a5)
	ld	t3,0(a0)
	addiw	t1,t1,-1
	addi	a5,t3,1
	sd	a5,0(a0)
.L256:
	sb	s5,0(a5)
	ld	a7,0(a0)
	addiw	t1,t1,-1
	addi	a5,a7,1
	sd	a5,0(a0)
.L255:
	sb	s5,0(a5)
	ld	a4,0(a0)
	addiw	t1,t1,-1
	addi	a5,a4,1
	sd	a5,0(a0)
.L254:
	sb	s5,0(a5)
	ld	s4,0(a0)
	addiw	t1,t1,-1
	addi	a5,s4,1
	sd	a5,0(a0)
.L253:
	sb	s5,0(a5)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a5,a5,1
	sd	a5,0(a0)
.L252:
	sb	s5,0(a5)
	ld	t3,0(a0)
	addiw	t1,t1,-1
	addi	a5,t3,1
	sd	a5,0(a0)
	ble	t1,a6,.L58
.L62:
	sb	s5,0(a5)
	ld	a7,0(a0)
	addiw	t1,t1,-8
	addi	a4,a7,1
	sd	a4,0(a0)
	sb	s5,1(a7)
	ld	s4,0(a0)
	addi	t3,s4,1
	sd	t3,0(a0)
	sb	s5,1(s4)
	ld	a5,0(a0)
	addi	a7,a5,1
	sd	a7,0(a0)
	sb	s5,1(a5)
	ld	s4,0(a0)
	addi	a4,s4,1
	sd	a4,0(a0)
	sb	s5,1(s4)
	ld	t3,0(a0)
	addi	a5,t3,1
	sd	a5,0(a0)
	sb	s5,1(t3)
	ld	a7,0(a0)
	addi	s4,a7,1
	sd	s4,0(a0)
	sb	s5,1(a7)
	ld	t3,0(a0)
	addi	a4,t3,1
	sd	a4,0(a0)
	sb	s5,1(t3)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
	bgt	t1,a6,.L62
.L58:
	slli	a6,s6,2
	add	a4,sp,a6
	addi	s5,sp,-4
	sub	t1,a4,s5
	addi	s6,t1,-4
	srli	a7,s6,2
	addi	s4,a7,1
	andi	t3,s4,3
	beq	t3,zero,.L65
	li	a6,1
	beq	t3,a6,.L249
	li	t1,2
	beq	t3,t1,.L250
	lw	s6,0(a4)
	addi	a4,a4,-4
	sgtu	a7,s6,t4
	addiw	s4,a7,-1
	andi	t3,s4,-39
	addiw	a6,t3,87
	addw	t1,a6,s6
	sb	t1,0(a5)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
.L250:
	lw	s6,0(a4)
	addi	a4,a4,-4
	sgtu	a7,s6,t4
	addiw	s4,a7,-1
	andi	t3,s4,-39
	addiw	a6,t3,87
	addw	t1,a6,s6
	sb	t1,0(a5)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
.L249:
	lw	s6,0(a4)
	addi	a4,a4,-4
	sgtu	a7,s6,t4
	addiw	s4,a7,-1
	andi	t3,s4,-39
	addiw	a6,t3,87
	addw	t1,a6,s6
	sb	t1,0(a5)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
	beq	s5,a4,.L287
.L65:
	lw	s6,0(a4)
	lw	a7,-4(a4)
	lw	t3,-8(a4)
	sgtu	s4,s6,t4
	addiw	a6,s4,-1
	andi	t1,a6,-39
	addiw	s4,t1,87
	addw	s6,s4,s6
	sb	s6,0(a5)
	ld	a6,0(a0)
	sgtu	a5,a7,t4
	addiw	t1,a5,-1
	andi	s6,t1,-39
	addi	s4,a6,1
	addiw	a5,s6,87
	sd	s4,0(a0)
	addw	a7,a5,a7
	sb	a7,1(a6)
	ld	s6,0(a0)
	sgtu	a6,t3,t4
	addiw	t1,a6,-1
	andi	a5,t1,-39
	lw	a7,-12(a4)
	addi	s4,s6,1
	addiw	a6,a5,87
	sd	s4,0(a0)
	addw	t3,a6,t3
	sb	t3,1(s6)
	ld	s6,0(a0)
	sgtu	t1,a7,t4
	addiw	a5,t1,-1
	andi	s4,a5,-39
	addi	a6,s6,1
	addiw	t3,s4,87
	sd	a6,0(a0)
	addw	a7,t3,a7
	sb	a7,1(s6)
	ld	s6,0(a0)
	addi	a4,a4,-16
	addi	a5,s6,1
	sd	a5,0(a0)
	bne	s5,a4,.L65
	j	.L287
.L20:
	addi	t3,a2,8
	bgt	a6,t2,.L288
	beq	a6,zero,.L50
.L288:
	ld	a4,0(a2)
.L49:
	ld	a5,0(a0)
	blt	a4,zero,.L51
	mv	a2,t3
	li	a7,10
	j	.L52
.L19:
	lbu	a7,1(a4)
	addiw	a6,a6,1
	mv	a4,a1
	j	.L11
.L13:
	li	a7,16
.L18:
	ld	a5,0(a0)
	addi	t3,a2,8
	bgt	a6,t2,.L53
	bne	a6,zero,.L53
	lwu	a4,0(a2)
	mv	a2,t3
	j	.L52
.L16:
	ld	a6,0(a2)
	addi	a2,a2,8
	beq	a6,zero,.L34
	ble	t1,zero,.L35
	bne	s5,s2,.L69
	lbu	a7,0(a6)
	bne	a7,zero,.L67
	j	.L44
.L76:
	lla	a6,.LC0
.L69:
	sext.w	a7,t1
	mv	a5,a6
	beq	s4,zero,.L38
	andi	a4,s4,7
	add	t1,a6,s4
	beq	a4,zero,.L37
	li	t3,1
	beq	a4,t3,.L230
	li	s6,2
	beq	a4,s6,.L231
	li	t3,3
	beq	a4,t3,.L232
	li	s6,4
	beq	a4,s6,.L233
	li	t3,5
	beq	a4,t3,.L234
	li	s6,6
	beq	a4,s6,.L235
	lbu	a4,0(a6)
	beq	a4,zero,.L279
	addi	a5,a6,1
.L235:
	lbu	t3,0(a5)
	beq	t3,zero,.L279
	addi	a5,a5,1
.L234:
	lbu	s6,0(a5)
	beq	s6,zero,.L279
	addi	a5,a5,1
.L233:
	lbu	a4,0(a5)
	beq	a4,zero,.L279
	addi	a5,a5,1
.L232:
	lbu	t3,0(a5)
	beq	t3,zero,.L279
	addi	a5,a5,1
.L231:
	lbu	s6,0(a5)
	beq	s6,zero,.L279
	addi	a5,a5,1
.L230:
	lbu	a4,0(a5)
	beq	a4,zero,.L279
	addi	a5,a5,1
	beq	a5,t1,.L279
.L37:
	lbu	t3,0(a5)
	beq	t3,zero,.L279
	lbu	s6,1(a5)
	addi	a5,a5,1
	mv	a4,a5
	beq	s6,zero,.L279
	lbu	t3,1(a5)
	addi	a5,a5,1
	beq	t3,zero,.L279
	lbu	s6,2(a4)
	addi	a5,a4,2
	beq	s6,zero,.L279
	lbu	t3,3(a4)
	addi	a5,a4,3
	beq	t3,zero,.L279
	lbu	s6,4(a4)
	addi	a5,a4,4
	beq	s6,zero,.L279
	lbu	t3,5(a4)
	addi	a5,a4,5
	beq	t3,zero,.L279
	lbu	s6,6(a4)
	addi	a5,a4,6
	beq	s6,zero,.L279
	addi	a5,a4,7
	bne	a5,t1,.L37
.L279:
	sub	t1,a5,a6
	subw	t1,a7,t1
	ble	t1,zero,.L35
.L38:
	andi	a4,t1,7
	ld	a5,0(a0)
	beq	a4,zero,.L41
	li	a7,1
	beq	a4,a7,.L236
	li	t3,2
	beq	a4,t3,.L237
	li	s6,3
	beq	a4,s6,.L238
	li	a7,4
	beq	a4,a7,.L239
	li	t3,5
	beq	a4,t3,.L240
	li	s6,6
	beq	a4,s6,.L241
	sb	s5,0(a5)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a5,a5,1
	sd	a5,0(a0)
.L241:
	sb	s5,0(a5)
	ld	a4,0(a0)
	addiw	t1,t1,-1
	addi	a5,a4,1
	sd	a5,0(a0)
.L240:
	sb	s5,0(a5)
	ld	a7,0(a0)
	addiw	t1,t1,-1
	addi	a5,a7,1
	sd	a5,0(a0)
.L239:
	sb	s5,0(a5)
	ld	t3,0(a0)
	addiw	t1,t1,-1
	addi	a5,t3,1
	sd	a5,0(a0)
.L238:
	sb	s5,0(a5)
	ld	s6,0(a0)
	addiw	t1,t1,-1
	addi	a5,s6,1
	sd	a5,0(a0)
.L237:
	sb	s5,0(a5)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a5,a5,1
	sd	a5,0(a0)
.L236:
	sb	s5,0(a5)
	ld	a4,0(a0)
	addiw	t1,t1,-1
	addi	a5,a4,1
	sd	a5,0(a0)
	beq	t1,zero,.L35
.L41:
	sb	s5,0(a5)
	ld	a7,0(a0)
	addiw	t1,t1,-8
	addi	t3,a7,1
	sd	t3,0(a0)
	sb	s5,1(a7)
	ld	s6,0(a0)
	addi	a4,s6,1
	sd	a4,0(a0)
	sb	s5,1(s6)
	ld	a5,0(a0)
	addi	a7,a5,1
	sd	a7,0(a0)
	sb	s5,1(a5)
	ld	t3,0(a0)
	addi	s6,t3,1
	sd	s6,0(a0)
	sb	s5,1(t3)
	ld	a5,0(a0)
	addi	a4,a5,1
	sd	a4,0(a0)
	sb	s5,1(a5)
	ld	a7,0(a0)
	addi	t3,a7,1
	sd	t3,0(a0)
	sb	s5,1(a7)
	ld	s6,0(a0)
	addi	a5,s6,1
	sd	a5,0(a0)
	sb	s5,1(s6)
	ld	a4,0(a0)
	addi	a5,a4,1
	sd	a5,0(a0)
	bne	t1,zero,.L41
.L35:
	lbu	a7,0(a6)
	beq	a7,zero,.L287
.L67:
	andi	s5,s4,7
	beq	s5,zero,.L68
	blt	s4,zero,.L45
	ld	t3,0(a0)
	addi	a6,a6,1
	addiw	s4,s4,-1
	sb	a7,0(t3)
	ld	a7,0(a0)
	addiw	t1,t1,-1
	addi	s6,a7,1
	sd	s6,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
	li	a5,1
	beq	s5,a5,.L68
	li	a4,2
	beq	s5,a4,.L259
	li	t3,3
	beq	s5,t3,.L260
	li	s6,4
	beq	s5,s6,.L261
	li	a5,5
	beq	s5,a5,.L262
	li	a4,6
	beq	s5,a4,.L263
	blt	s4,zero,.L45
	ld	s5,0(a0)
	addi	a6,a6,1
	addiw	s4,s4,-1
	sb	a7,0(s5)
	ld	a7,0(a0)
	addiw	t1,t1,-1
	addi	t3,a7,1
	sd	t3,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
.L263:
	blt	s4,zero,.L45
	ld	s6,0(a0)
	addi	a6,a6,1
	addiw	s4,s4,-1
	sb	a7,0(s6)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a4,a5,1
	sd	a4,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
.L262:
	blt	s4,zero,.L45
	ld	s5,0(a0)
	addi	a6,a6,1
	addiw	s4,s4,-1
	sb	a7,0(s5)
	ld	a7,0(a0)
	addiw	t1,t1,-1
	addi	t3,a7,1
	sd	t3,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
.L261:
	blt	s4,zero,.L45
	ld	s6,0(a0)
	addi	a6,a6,1
	addiw	s4,s4,-1
	sb	a7,0(s6)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a4,a5,1
	sd	a4,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
.L260:
	blt	s4,zero,.L45
	ld	s5,0(a0)
	addi	a6,a6,1
	addiw	s4,s4,-1
	sb	a7,0(s5)
	ld	a7,0(a0)
	addiw	t1,t1,-1
	addi	t3,a7,1
	sd	t3,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
.L259:
	blt	s4,zero,.L45
	ld	s6,0(a0)
	addi	a6,a6,1
	addiw	s4,s4,-1
	sb	a7,0(s6)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a4,a5,1
	sd	a4,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
.L68:
	blt	s4,zero,.L45
	addiw	s4,s4,-1
	beq	s4,s3,.L42
	ld	s5,0(a0)
	addi	a6,a6,1
	mv	s6,a6
	sb	a7,0(s5)
	ld	t3,0(a0)
	addiw	t1,t1,-1
	addi	a7,t3,1
	sd	a7,0(a0)
	lbu	a7,0(a6)
	beq	a7,zero,.L42
	blt	s4,zero,.L45
	sb	a7,1(t3)
	ld	a4,0(a0)
	addiw	a5,s4,-1
	addi	a6,a6,1
	addi	s4,a4,1
	sd	s4,0(a0)
	lbu	a7,0(a6)
	addiw	t1,t1,-1
	beq	a7,zero,.L42
	blt	a5,zero,.L45
	sb	a7,1(a4)
	ld	s5,0(a0)
	addiw	t3,a5,-1
	addi	a6,s6,2
	addi	a7,s5,1
	sd	a7,0(a0)
	lbu	a7,2(s6)
	addiw	t1,t1,-1
	beq	a7,zero,.L42
	blt	t3,zero,.L45
	sb	a7,1(s5)
	ld	a4,0(a0)
	addiw	a5,t3,-1
	addi	a6,s6,3
	addi	s4,a4,1
	sd	s4,0(a0)
	lbu	a7,3(s6)
	addiw	t1,t1,-1
	beq	a7,zero,.L42
	blt	a5,zero,.L45
	ld	s5,0(a0)
	addiw	a4,a5,-1
	addi	a6,s6,4
	sb	a7,0(s5)
	ld	t3,0(a0)
	addiw	t1,t1,-1
	addi	a7,t3,1
	sd	a7,0(a0)
	lbu	a7,4(s6)
	beq	a7,zero,.L42
	blt	a4,zero,.L45
	sb	a7,1(t3)
	ld	s4,0(a0)
	addiw	a5,a4,-1
	addi	a6,s6,5
	addi	s5,s4,1
	sd	s5,0(a0)
	lbu	a7,5(s6)
	addiw	t1,t1,-1
	beq	a7,zero,.L42
	blt	a5,zero,.L45
	sb	a7,1(s4)
	ld	a4,0(a0)
	addiw	t3,a5,-1
	addi	a6,s6,6
	addi	a7,a4,1
	sd	a7,0(a0)
	lbu	a7,6(s6)
	addiw	t1,t1,-1
	beq	a7,zero,.L42
	blt	t3,zero,.L45
	sb	a7,1(a4)
	ld	a5,0(a0)
	addiw	s4,t3,-1
	addi	a6,s6,7
	addi	s5,a5,1
	sd	s5,0(a0)
	lbu	a7,7(s6)
	addiw	t1,t1,-1
	bne	a7,zero,.L68
.L42:
	ble	t1,zero,.L287
.L44:
	andi	a7,t1,7
	ld	a5,0(a0)
	beq	a7,zero,.L47
	li	s6,1
	beq	a7,s6,.L242
	li	t3,2
	beq	a7,t3,.L243
	li	s4,3
	beq	a7,s4,.L244
	li	a4,4
	beq	a7,a4,.L245
	li	s5,5
	beq	a7,s5,.L246
	li	a6,6
	beq	a7,a6,.L247
	sb	t0,0(a5)
	ld	a5,0(a0)
	addiw	t1,t1,-1
	addi	a5,a5,1
	sd	a5,0(a0)
.L247:
	sb	t0,0(a5)
	ld	a7,0(a0)
	addiw	t1,t1,-1
	addi	a5,a7,1
	sd	a5,0(a0)
.L246:
	sb	t0,0(a5)
	ld	s6,0(a0)
	addiw	t1,t1,-1
	addi	a5,s6,1
	sd	a5,0(a0)
.L245:
	sb	t0,0(a5)
	ld	t3,0(a0)
	addiw	t1,t1,-1
	addi	a5,t3,1
	sd	a5,0(a0)
.L244:
	sb	t0,0(a5)
	ld	s4,0(a0)
	addiw	t1,t1,-1
	addi	a5,s4,1
	sd	a5,0(a0)
.L243:
	sb	t0,0(a5)
	ld	a4,0(a0)
	addiw	t1,t1,-1
	addi	a5,a4,1
	sd	a5,0(a0)
.L242:
	sb	t0,0(a5)
	ld	s5,0(a0)
	addiw	t1,t1,-1
	addi	a5,s5,1
	sd	a5,0(a0)
	beq	t1,zero,.L287
.L47:
	sb	t0,0(a5)
	ld	a6,0(a0)
	addiw	t1,t1,-8
	addi	a7,a6,1
	sd	a7,0(a0)
	sb	t0,1(a6)
	ld	s6,0(a0)
	addi	t3,s6,1
	sd	t3,0(a0)
	sb	t0,1(s6)
	ld	s4,0(a0)
	addi	a4,s4,1
	sd	a4,0(a0)
	sb	t0,1(s4)
	ld	s5,0(a0)
	addi	a5,s5,1
	sd	a5,0(a0)
	sb	t0,1(s5)
	ld	a6,0(a0)
	addi	a7,a6,1
	sd	a7,0(a0)
	sb	t0,1(a6)
	ld	s6,0(a0)
	addi	t3,s6,1
	sd	t3,0(a0)
	sb	t0,1(s6)
	ld	s4,0(a0)
	addi	a4,s4,1
	sd	a4,0(a0)
	sb	t0,1(s4)
	ld	s5,0(a0)
	addi	a5,s5,1
	sd	a5,0(a0)
	bne	t1,zero,.L47
	j	.L287
.L24:
	not	a7,t1
	srai	a5,a7,63
	and	t1,t1,a5
	lbu	a7,1(a4)
	sext.w	t1,t1
	mv	a4,a1
	j	.L11
.L21:
	lw	t1,0(a2)
	ld	s5,0(a0)
	addi	a2,a2,8
	sb	t1,0(s5)
	ld	s6,0(a0)
	addi	s4,s6,1
	sd	s4,0(a0)
	j	.L287
.L45:
	ld	s6,0(a0)
	addi	a4,a6,1
	addiw	t1,t1,-1
	sb	a7,0(s6)
	ld	t3,0(a0)
	addi	s5,t3,1
	sd	s5,0(a0)
	lbu	a6,1(a6)
	beq	a6,zero,.L42
	addw	s4,t1,a4
.L43:
	sb	a6,0(s5)
	ld	a5,0(a0)
	addi	a4,a4,1
	subw	t1,s4,a4
	addi	s5,a5,1
	sd	s5,0(a0)
	lbu	a6,0(a4)
	bne	a6,zero,.L43
	j	.L42
.L290:
	li	s6,0
	bgt	t1,t2,.L57
	j	.L58
.L50:
	lw	a4,0(a2)
	j	.L49
.L70:
	li	a7,8
	j	.L18
.L15:
	li	a7,10
	j	.L18
.L51:
	sb	s2,0(a5)
	ld	a5,0(a0)
	neg	a4,a4
	mv	a2,t3
	addi	a5,a5,1
	sd	a5,0(a0)
	li	a7,10
	j	.L52
.L34:
	ble	t1,zero,.L75
	bne	s5,s2,.L76
.L75:
	lla	a6,.LC0
	li	a7,40
	j	.L67
	.size	vprintfmt.constprop.1, .-vprintfmt.constprop.1
	.align	2
	.type	vprintfmt.constprop.0, @function
vprintfmt.constprop.0:
	addi	sp,sp,-304
	sd	s0,296(sp)
	sd	s1,288(sp)
	lui	s0,%tprel_hi(buflen.1)
	lui	s1,%tprel_hi(.LANCHOR0)
	add	t5,s1,tp,%tprel_add(.LANCHOR0)
	add	a6,s0,tp,%tprel_add(buflen.1)
	addi	t1,t5,%tprel_lo(.LANCHOR0)
	sd	s2,280(sp)
	sd	s3,272(sp)
	sd	s4,264(sp)
	sd	s5,256(sp)
	mv	a3,a0
	mv	t6,a1
	li	t4,37
	li	t3,10
	lla	t2,.L301
	mv	t0,a6
	addi	t5,t5,%tprel_lo(.LANCHOR0)
.L292:
	lbu	a4,0(a3)
	sext.w	a0,a4
	beq	a4,t4,.L293
.L471:
	beq	a0,zero,.L450
	lw	s2,%tprel_lo(buflen.1)(a6)
	addi	a3,a3,1
	addiw	a2,s2,1
	add	a7,t1,s2
	sw	a2,%tprel_lo(buflen.1)(a6)
	sb	a4,0(a7)
	beq	a0,t3,.L461
	li	a0,64
	bne	a2,a0,.L292
.L461:
	li	a7,64
	li	a0,1
	mv	a1,t1
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(a6)
	lbu	a4,0(a3)
	sext.w	a0,a4
	bne	a4,t4,.L471
.L293:
	lbu	a1,1(a3)
	addi	s5,a3,1
	mv	a2,s5
	li	s3,32
	li	s4,-1
	li	s2,-1
	li	a7,0
	li	a0,85
	li	a4,9
.L298:
	addiw	a5,a1,-35
	andi	a5,a5,0xff
	addi	a3,a2,1
	bgtu	a5,a0,.L299
.L472:
	slli	a5,a5,2
	add	a5,a5,t2
	lw	a5,0(a5)
	add	a5,a5,t2
	jr	a5
	.section	.rodata
	.align	2
	.align	2
.L301:
	.word	.L315-.L301
	.word	.L299-.L301
	.word	.L314-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L313-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L310-.L301
	.word	.L311-.L301
	.word	.L299-.L301
	.word	.L310-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L309-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L308-.L301
	.word	.L307-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L306-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L372-.L301
	.word	.L304-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L303-.L301
	.word	.L299-.L301
	.word	.L302-.L301
	.word	.L299-.L301
	.word	.L299-.L301
	.word	.L300-.L301
	.text
.L450:
	ld	s0,296(sp)
	ld	s1,288(sp)
	ld	s2,280(sp)
	ld	s3,272(sp)
	ld	s4,264(sp)
	ld	s5,256(sp)
	addi	sp,sp,304
	jr	ra
.L310:
	mv	s3,a1
	lbu	a1,1(a2)
	mv	a2,a3
	addi	a3,a2,1
	addiw	a5,a1,-35
	andi	a5,a5,0xff
	bleu	a5,a0,.L472
.L299:
	lw	s3,%tprel_lo(buflen.1)(a6)
	li	a2,64
	mv	a3,s5
.L465:
	addiw	a1,s3,1
	add	a5,t1,s3
	sw	a1,%tprel_lo(buflen.1)(a6)
	sb	t4,0(a5)
	bne	a1,a2,.L292
	j	.L461
.L309:
	addiw	s4,a1,-48
	lbu	a1,1(a2)
	mv	a2,a3
	addiw	a5,a1,-48
	sext.w	a3,a1
	bgtu	a5,a4,.L317
.L318:
	lbu	a1,1(a2)
	slliw	a5,s4,2
	addw	s4,a5,s4
	slliw	a5,s4,1
	addw	a3,a5,a3
	addiw	a5,a1,-48
	addiw	s4,a3,-48
	addi	a2,a2,1
	sext.w	a3,a1
	bleu	a5,a4,.L318
.L317:
	bge	s2,zero,.L298
	mv	s2,s4
	li	s4,-1
	j	.L298
.L315:
	lbu	a1,1(a2)
	mv	a2,a3
	j	.L298
.L314:
	lw	s3,%tprel_lo(buflen.1)(a6)
	li	a2,64
	j	.L465
.L313:
	lw	s4,0(t6)
	lbu	a1,1(a2)
	addi	t6,t6,8
	mv	a2,a3
	j	.L317
.L304:
	lw	a7,%tprel_lo(buflen.1)(a6)
	li	a2,48
	li	s5,64
	add	s4,t1,a7
	addiw	a4,a7,1
	sb	a2,0(s4)
	sw	a4,%tprel_lo(buflen.1)(a6)
	addi	s4,t6,8
	beq	a4,s5,.L473
	addiw	a2,a7,2
	add	a0,t1,a4
	li	a7,120
	sw	a2,%tprel_lo(buflen.1)(a6)
	sb	a7,0(a0)
	li	a5,16
	bne	a2,s5,.L351
	li	a7,64
	li	a0,1
	mv	a1,t1
	li	a2,64
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	li	a2,0
	sw	zero,%tprel_lo(buflen.1)(a6)
.L351:
	ld	a4,0(t6)
	mv	t6,s4
.L348:
	remu	a7,a4,a5
	addi	a1,sp,4
	li	s4,1
	sw	a7,0(sp)
	bltu	a4,a5,.L474
.L359:
	divu	a4,a4,a5
	addi	a1,a1,4
	mv	s5,s4
	addiw	s4,s4,1
	remu	a0,a4,a5
	sw	a0,-4(a1)
	bgeu	a4,a5,.L359
	ble	s2,s4,.L356
.L355:
	add	a7,s1,tp,%tprel_add(.LANCHOR0)
	sext.w	a4,s2
	add	a5,s0,tp,%tprel_add(buflen.1)
	addi	a1,a7,%tprel_lo(.LANCHOR0)
	li	s2,64
.L363:
	addiw	a0,a2,1
	add	a7,a1,a2
	sw	a0,%tprel_lo(buflen.1)(a5)
	sext.w	a2,a0
	sb	s3,0(a7)
	beq	a2,s2,.L475
	addiw	a4,a4,-1
	blt	s4,a4,.L363
.L356:
	slli	s5,s5,2
	add	a5,sp,s5
	addi	s4,sp,-4
	sub	a1,a5,s4
	addi	s3,a1,-4
	srli	s2,s3,2
	add	a0,s1,tp,%tprel_add(.LANCHOR0)
	andi	a7,s2,1
	li	s5,9
	add	s3,s0,tp,%tprel_add(buflen.1)
	addi	a1,a0,%tprel_lo(.LANCHOR0)
	bne	a7,zero,.L367
	lw	a4,0(a5)
	addiw	s2,a2,1
	bgtu	a4,s5,.L455
	add	a2,a1,a2
	addiw	a0,a4,48
	sb	a0,0(a2)
	sw	s2,%tprel_lo(buflen.1)(s3)
	sext.w	a2,s2
.L457:
	li	a4,64
	beq	a2,a4,.L476
.L403:
	addi	a5,a5,-4
	beq	s4,a5,.L292
.L367:
	lw	s2,0(a5)
	bleu	s2,s5,.L364
.L478:
	addiw	a4,a2,1
	add	a7,a1,a2
	addiw	s2,s2,87
	sw	a4,%tprel_lo(buflen.1)(s3)
	sb	s2,0(a7)
	sext.w	a2,a4
	bne	s2,t3,.L477
.L365:
	li	a7,64
	li	a0,1
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	lw	a0,-4(a5)
	sw	zero,%tprel_lo(buflen.1)(s3)
	li	a7,0
	addi	a5,a5,-4
	bleu	a0,s5,.L402
.L479:
	addiw	a2,a7,1
	addiw	a0,a0,87
	add	a7,a1,a7
	sw	a2,%tprel_lo(buflen.1)(s3)
	sb	a0,0(a7)
	bne	a0,t3,.L457
.L404:
	li	a7,64
	li	a0,1
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(s3)
	addi	a5,a5,-4
	li	a2,0
	beq	s4,a5,.L292
	lw	s2,0(a5)
	bgtu	s2,s5,.L478
.L364:
	addiw	a7,a2,1
	addiw	a0,s2,48
	add	a2,a1,a2
	sw	a7,%tprel_lo(buflen.1)(s3)
	sb	a0,0(a2)
.L369:
	li	a2,64
	beq	a7,a2,.L365
	lw	a0,-4(a5)
	addi	a5,a5,-4
	bgtu	a0,s5,.L479
.L402:
	add	a4,a1,a7
	addiw	a2,a7,1
	addiw	s2,a0,48
	sb	s2,0(a4)
	sw	a2,%tprel_lo(buflen.1)(s3)
	li	a4,64
	bne	a2,a4,.L403
.L476:
	li	a2,64
	j	.L404
.L307:
	li	a0,1
	addi	s4,t6,8
	bgt	a7,a0,.L462
	beq	a7,zero,.L346
.L462:
	ld	a4,0(t6)
.L345:
	lw	a2,%tprel_lo(buflen.1)(a6)
	blt	a4,zero,.L347
.L463:
	mv	t6,s4
	li	a5,10
	j	.L348
.L300:
	li	a5,16
.L305:
	li	s5,1
	lw	a2,%tprel_lo(buflen.1)(a6)
	addi	s4,t6,8
	bgt	a7,s5,.L351
	bne	a7,zero,.L351
	lwu	a4,0(t6)
	mv	t6,s4
	j	.L348
.L303:
	ld	a4,0(t6)
	addi	t6,t6,8
	beq	a4,zero,.L322
	ble	s2,zero,.L323
	li	a1,45
	bne	s3,a1,.L370
	lbu	a7,0(a4)
	sext.w	a0,a7
	bne	a7,zero,.L368
	mv	s4,s2
	j	.L339
.L370:
	sext.w	s5,s2
	mv	a5,a4
	beq	s4,zero,.L326
	andi	s2,s4,7
	add	a1,a4,s4
	beq	s2,zero,.L325
	li	a2,1
	beq	s2,a2,.L441
	li	a7,2
	beq	s2,a7,.L442
	li	a0,3
	beq	s2,a0,.L443
	li	a2,4
	beq	s2,a2,.L444
	li	a7,5
	beq	s2,a7,.L445
	li	a0,6
	beq	s2,a0,.L446
	lbu	s2,0(a4)
	beq	s2,zero,.L452
	addi	a5,a4,1
.L446:
	lbu	a2,0(a5)
	beq	a2,zero,.L452
	addi	a5,a5,1
.L445:
	lbu	a7,0(a5)
	beq	a7,zero,.L452
	addi	a5,a5,1
.L444:
	lbu	a0,0(a5)
	beq	a0,zero,.L452
	addi	a5,a5,1
.L443:
	lbu	s2,0(a5)
	beq	s2,zero,.L452
	addi	a5,a5,1
.L442:
	lbu	a2,0(a5)
	beq	a2,zero,.L452
	addi	a5,a5,1
.L441:
	lbu	a7,0(a5)
	beq	a7,zero,.L452
	addi	a5,a5,1
	beq	a5,a1,.L452
.L325:
	lbu	a0,0(a5)
	beq	a0,zero,.L452
	lbu	s2,1(a5)
	addi	a5,a5,1
	mv	a2,a5
	beq	s2,zero,.L452
	lbu	a7,1(a5)
	addi	a5,a5,1
	beq	a7,zero,.L452
	lbu	a0,2(a2)
	addi	a5,a2,2
	beq	a0,zero,.L452
	lbu	s2,3(a2)
	addi	a5,a2,3
	beq	s2,zero,.L452
	lbu	a7,4(a2)
	addi	a5,a2,4
	beq	a7,zero,.L452
	lbu	a0,5(a2)
	addi	a5,a2,5
	beq	a0,zero,.L452
	lbu	s2,6(a2)
	addi	a5,a2,6
	beq	s2,zero,.L452
	addi	a5,a2,7
	bne	a5,a1,.L325
.L452:
	sub	a1,a5,a4
	subw	s2,s5,a1
	ble	s2,zero,.L323
.L326:
	lw	a0,%tprel_lo(buflen.1)(a6)
	li	s5,64
.L331:
	addiw	a2,a0,1
	add	a7,t1,a0
	sw	a2,%tprel_lo(buflen.1)(a6)
	sext.w	a0,a2
	sb	s3,0(a7)
	beq	a0,s5,.L480
	addiw	s2,s2,-1
	bne	s2,zero,.L331
.L323:
	lbu	a7,0(a4)
	sext.w	a0,a7
	beq	a7,zero,.L292
.L368:
	li	s5,-1
.L335:
	blt	s4,zero,.L379
.L482:
	addiw	s3,s4,-1
	beq	s3,s5,.L377
.L340:
	lw	a5,%tprel_lo(buflen.1)(a6)
	addiw	a2,a5,1
	add	a1,t1,a5
	sw	a2,%tprel_lo(buflen.1)(a6)
	sb	a7,0(a1)
	beq	a0,t3,.L332
	li	a0,64
	beq	a2,a0,.L332
.L333:
	lbu	a7,1(a4)
	addiw	s2,s2,-1
	addi	a4,a4,1
	sext.w	a0,a7
	beq	a7,zero,.L377
	blt	s4,zero,.L481
	mv	s4,s3
	bge	s4,zero,.L482
.L379:
	mv	s3,s4
	j	.L340
.L311:
	not	a1,s2
	srai	a5,a1,63
	and	s2,s2,a5
	lbu	a1,1(a2)
	sext.w	s2,s2
	mv	a2,a3
	j	.L298
.L308:
	lw	s3,%tprel_lo(buflen.1)(a6)
	lw	a7,0(t6)
	addi	s2,t6,8
	addiw	a2,s3,1
	add	a4,t1,s3
	sw	a2,%tprel_lo(buflen.1)(a6)
	sb	a7,0(a4)
	beq	a7,t3,.L320
	li	s4,64
	mv	t6,s2
	bne	a2,s4,.L292
.L320:
	li	a7,64
	li	a0,1
	mv	a1,t1
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(a6)
	mv	t6,s2
	j	.L292
.L306:
	lbu	a1,1(a2)
	addiw	a7,a7,1
	mv	a2,a3
	j	.L298
.L481:
	mv	s3,a4
	addw	a4,s2,a4
	j	.L338
.L483:
	li	a7,64
	beq	a2,a7,.L336
.L337:
	lbu	a7,1(s3)
	addi	s3,s3,1
	subw	s4,a4,s3
	sext.w	a0,a7
	beq	a7,zero,.L334
.L338:
	lw	s4,%tprel_lo(buflen.1)(t0)
	addiw	a2,s4,1
	add	s2,t5,s4
	sw	a2,%tprel_lo(buflen.1)(t0)
	sb	a7,0(s2)
	bne	a0,t3,.L483
.L336:
	li	a7,64
	li	a0,1
	mv	a1,t5
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(t0)
	j	.L337
.L475:
	li	a7,64
	li	a0,1
	li	a2,64
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(a5)
	addiw	a4,a4,-1
	li	a2,0
	blt	s4,a4,.L363
	j	.L356
.L332:
	li	a7,64
	li	a0,1
	mv	a1,t1
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(a6)
	j	.L333
.L477:
	mv	a7,a2
	j	.L369
.L455:
	addiw	a7,a4,87
	add	a4,a1,a2
	sw	s2,%tprel_lo(buflen.1)(s3)
	sb	a7,0(a4)
	sext.w	a2,s2
	beq	a7,t3,.L404
	j	.L457
.L377:
	mv	s4,s2
.L334:
	ble	s4,zero,.L292
.L339:
	lw	a5,%tprel_lo(buflen.1)(a6)
	li	s5,32
	li	s2,64
.L343:
	addiw	a1,a5,1
	add	a2,t1,a5
	sw	a1,%tprel_lo(buflen.1)(a6)
	sext.w	a5,a1
	sb	s5,0(a2)
	beq	a5,s2,.L484
.L341:
	addiw	s4,s4,-1
	beq	s4,zero,.L292
	addiw	a1,a5,1
	add	a2,t1,a5
	sw	a1,%tprel_lo(buflen.1)(a6)
	sext.w	a5,a1
	sb	s5,0(a2)
	bne	a5,s2,.L341
.L484:
	li	a7,64
	li	a0,1
	mv	a1,t1
	li	a2,64
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(a6)
	addiw	s4,s4,-1
	beq	s4,zero,.L292
	li	a5,0
	j	.L343
.L474:
	li	s5,0
	bgt	s2,s4,.L355
	j	.L356
.L346:
	lw	a4,0(t6)
	j	.L345
.L372:
	li	a5,8
	j	.L305
.L302:
	li	a5,10
	j	.L305
.L347:
	addiw	t6,a2,1
	add	s5,t1,a2
	li	a5,45
	sext.w	a2,t6
	sw	t6,%tprel_lo(buflen.1)(a6)
	sb	a5,0(s5)
	li	a1,64
	beq	a2,a1,.L485
	neg	a4,a4
	j	.L463
.L485:
	li	a7,64
	li	a0,1
	mv	a1,t1
	li	a2,64
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	li	a2,0
	sw	zero,%tprel_lo(buflen.1)(a6)
	neg	a4,a4
	j	.L463
.L473:
	li	a7,64
	li	a0,1
	mv	a1,t1
	li	a2,64
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	li	s5,1
	li	a4,120
	sw	s5,%tprel_lo(buflen.1)(a6)
	sb	a4,0(t1)
	li	a2,1
	li	a5,16
	j	.L351
.L322:
	ble	s2,zero,.L387
	li	a2,45
	lla	a4,.LC0
	bne	s3,a2,.L370
	li	a7,40
	li	a0,40
	li	s5,-1
	j	.L335
.L480:
	li	a7,64
	li	a0,1
	mv	a1,t1
	li	a2,64
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	sw	zero,%tprel_lo(buflen.1)(a6)
	addiw	s2,s2,-1
	beq	s2,zero,.L323
	li	a0,0
	j	.L331
.L387:
	lla	a4,.LC0
	li	a0,40
	li	a7,40
	li	s5,-1
	j	.L335
	.size	vprintfmt.constprop.0, .-vprintfmt.constprop.0
	.align	2
	.globl	tohost_exit
	.type	tohost_exit, @function
tohost_exit:
	slli	a5,a0,1
	ori	t0,a5,1
 #APP
# 85 "../common/syscalls.c" 1
	csrw 0x9F0, t0
# 0 "" 2
 #NO_APP
.L487:
	j	.L487
	.size	tohost_exit, .-tohost_exit
	.section	.rodata.str1.8
	.align	3
.LC1:
	.string	"mcycle"
	.align	3
.LC2:
	.string	"minstret"
	.text
	.align	2
	.globl	handle_trap
	.type	handle_trap, @function
handle_trap:
	li	a5,2
 #APP
# 93 "../common/syscalls.c" 1
	jal a3, 1f; csrr a0, 0xc0; 1:
# 0 "" 2
 #NO_APP
	beq	a0,a5,.L542
	addi	sp,sp,-128
	sd	ra,120(sp)
	addi	a4,sp,63
	li	t0,8
	andi	ra,a4,-64
	beq	a0,t0,.L492
	li	t1,11
	bne	a0,t1,.L543
.L492:
	ld	t2,136(a2)
	li	a6,93
	ld	a0,80(a2)
	beq	t2,a6,.L544
	li	a7,1234
	beq	t2,a7,.L545
	ld	t3,88(a2)
	sd	t2,0(ra)
	ld	t4,96(a2)
	sd	a0,8(ra)
	sd	t3,16(ra)
	sd	t4,24(ra)
	mv	a5,t3
	fence	iorw,iorw
	ble	t4,zero,.L499
	andi	t5,t4,7
	add	a0,t3,t4
	li	t6,1073741824
	beq	t5,zero,.L500
	li	a3,1
	beq	t5,a3,.L527
	li	a4,2
	beq	t5,a4,.L528
	li	t0,3
	beq	t5,t0,.L529
	li	t1,4
	beq	t5,t1,.L530
	li	t2,5
	beq	t5,t2,.L531
	li	a6,6
	bne	t5,a6,.L546
.L532:
	lbu	t3,0(a5)
	slli	t5,t3,8
	or	a3,t5,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, a3
# 0 "" 2
 #NO_APP
	addi	a5,a5,1
.L531:
	lbu	a4,0(a5)
	slli	t0,a4,8
	or	t1,t0,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t1
# 0 "" 2
 #NO_APP
	addi	a5,a5,1
.L530:
	lbu	t2,0(a5)
	slli	a6,t2,8
	or	a7,a6,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, a7
# 0 "" 2
 #NO_APP
	addi	a5,a5,1
.L529:
	lbu	t4,0(a5)
	slli	t3,t4,8
	or	t5,t3,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t5
# 0 "" 2
 #NO_APP
	addi	a5,a5,1
.L528:
	lbu	a3,0(a5)
	slli	a4,a3,8
	or	t0,a4,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t0
# 0 "" 2
 #NO_APP
	addi	a5,a5,1
.L527:
	lbu	t1,0(a5)
	slli	t2,t1,8
	or	a6,t2,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, a6
# 0 "" 2
 #NO_APP
	addi	a5,a5,1
	beq	a5,a0,.L499
.L500:
	lbu	a7,0(a5)
	slli	t4,a7,8
	or	t3,t4,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t3
# 0 "" 2
 #NO_APP
	lbu	t5,1(a5)
	slli	a3,t5,8
	or	a4,a3,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, a4
# 0 "" 2
 #NO_APP
	lbu	t0,2(a5)
	slli	t1,t0,8
	or	t2,t1,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t2
# 0 "" 2
 #NO_APP
	lbu	a6,3(a5)
	slli	a7,a6,8
	or	t4,a7,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t4
# 0 "" 2
 #NO_APP
	lbu	t3,4(a5)
	slli	t5,t3,8
	or	a3,t5,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, a3
# 0 "" 2
 #NO_APP
	lbu	a4,5(a5)
	slli	t0,a4,8
	or	t1,t0,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t1
# 0 "" 2
 #NO_APP
	lbu	t2,6(a5)
	slli	a6,t2,8
	or	a7,a6,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, a7
# 0 "" 2
 #NO_APP
	lbu	t4,7(a5)
	slli	t3,t4,8
	or	t5,t3,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t5
# 0 "" 2
 #NO_APP
	addi	a5,a5,8
	bne	a5,a0,.L500
.L499:
	ld	a0,0(ra)
.L490:
	ld	ra,120(sp)
	sd	a0,80(a2)
	addi	a0,a1,4
	addi	sp,sp,128
	jr	ra
.L543:
	li	s0,4096
	addi	a1,s0,-1421
 #APP
# 85 "../common/syscalls.c" 1
	csrw 0x9F0, a1
# 0 "" 2
 #NO_APP
.L493:
	j	.L493
.L542:
	lw	t2,0(a3)
	lw	a6,0(a1)
	and	a7,t2,a6
	beq	t2,a7,.L547
	li	a2,4096
	addi	t4,a2,-1421
 #APP
# 85 "../common/syscalls.c" 1
	csrw 0x9F0, t4
# 0 "" 2
 #NO_APP
.L539:
	j	.L539
.L545:
	sext.w	ra,a0
	beq	ra,zero,.L496
 #APP
# 59 "../common/syscalls.c" 1
	csrrs a0, 0xc0, 1
# 0 "" 2
 #NO_APP
.L496:
 #APP
# 72 "../common/syscalls.c" 1
	csrr a0, mcycle
# 0 "" 2
 #NO_APP
	lla	t6,.LANCHOR1
	bne	ra,zero,.L497
	ld	a5,0(t6)
	lla	a3,.LC1
	sd	a3,16(t6)
	sub	a0,a0,a5
.L497:
	sd	a0,0(t6)
 #APP
# 73 "../common/syscalls.c" 1
	csrr a0, minstret
# 0 "" 2
 #NO_APP
	bne	ra,zero,.L498
	ld	a4,8(t6)
	lla	t0,.LC2
	sd	t0,24(t6)
	sub	t1,a0,a4
	sd	t1,8(t6)
 #APP
# 78 "../common/syscalls.c" 1
	csrrc a0, 0xc0, 1
# 0 "" 2
 #NO_APP
	li	a0,0
	j	.L490
.L547:
	li	t3,0
	sd	t3,80(a2)
	addi	a0,a1,4
	ret
.L498:
	sd	a0,8(t6)
	li	a0,0
	j	.L490
.L546:
	lbu	a5,0(t3)
	slli	a7,a5,8
	or	t4,a7,t6
 #APP
# 36 "../common/syscalls.c" 1
	csrw 0x9f0, t4
# 0 "" 2
 #NO_APP
	addi	a5,t3,1
	j	.L532
.L544:
	call	tohost_exit
	.size	handle_trap, .-handle_trap
	.align	2
	.globl	exit
	.type	exit, @function
exit:
	li	a7,93
	li	a1,0
	li	a2,0
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
.L549:
	j	.L549
	.size	exit, .-exit
	.align	2
	.globl	setStats
	.type	setStats, @function
setStats:
	li	a7,1234
	li	a1,0
	li	a2,0
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	ret
	.size	setStats, .-setStats
	.align	2
	.globl	printstr
	.type	printstr, @function
printstr:
	lbu	a5,0(a0)
	mv	a1,a0
	li	a2,0
	beq	a5,zero,.L552
	mv	a2,a0
.L553:
	lbu	t0,1(a2)
	addi	a2,a2,1
	bne	t0,zero,.L553
	sub	a2,a2,a1
.L552:
	li	a7,64
	li	a0,1
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	ret
	.size	printstr, .-printstr
	.align	2
	.weak	thread_entry
	.type	thread_entry, @function
thread_entry:
	beq	a0,zero,.L557
.L559:
	j	.L559
.L557:
	ret
	.size	thread_entry, .-thread_entry
	.section	.rodata.str1.8
	.align	3
.LC3:
	.string	"Implement main(), foo!\n"
	.section	.text.startup,"ax",@progbits
	.align	2
	.weak	main
	.type	main, @function
main:
	lla	a2,.LC3
	mv	a5,a2
.L561:
	lbu	a4,1(a5)
	addi	a5,a5,1
	bne	a4,zero,.L561
	li	a7,64
	li	a0,1
	lla	a1,.LC3
	sub	a2,a5,a2
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	li	a0,-1
	ret
	.size	main, .-main
	.text
	.align	2
	.globl	_cores_fork_
	.type	_cores_fork_, @function
_cores_fork_:
	ret
	.size	_cores_fork_, .-_cores_fork_
	.align	2
	.globl	_core_idle_
	.type	_core_idle_, @function
_core_idle_:
	sd	zero,cores_jump_address,a5
	beq	a0,zero,.L564
	li	a5,0
 #APP
# 212 "../common/syscalls.c" 1
	la a5, _idle_back_
	jalr a5
# 0 "" 2
 #NO_APP
.L564:
	ret
	.size	_core_idle_, .-_core_idle_
	.align	2
	.globl	get_core_count
	.type	get_core_count, @function
get_core_count:
	lw	a0,tohost
	ret
	.size	get_core_count, .-get_core_count
	.align	2
	.globl	get_core_id
	.type	get_core_id, @function
get_core_id:
 #APP
# 231 "../common/syscalls.c" 1
	nop
	csrr a0, mhartid
	
# 0 "" 2
 #NO_APP
	sext.w	a0,a0
	ret
	.size	get_core_id, .-get_core_id
	.align	2
	.globl	_idle_section_
	.type	_idle_section_, @function
_idle_section_:
	li	a5,0
	lla	a4,cores_jump_address
	li	a3,0
.L572:
	beq	a5,zero,.L573
.L575:
 #APP
# 258 "../common/syscalls.c" 1
	addi sp, sp, -272
	la ra, _idle_back_
	sd ra, 264(sp)
	addi s0, sp, 256
	jalr a5
	_idle_back_:
	addi sp, sp, 272
	mv s0, sp
	
# 0 "" 2
 #NO_APP
	sext.w	a5,a5
	bne	a5,zero,.L575
.L573:
	mv	t0,a3
 #APP
# 250 "../common/syscalls.c" 1
	amoadd.d t0, zero, 0(a4) 
	
# 0 "" 2
 #NO_APP
	sext.w	a5,t0
	j	.L572
	.size	_idle_section_, .-_idle_section_
	.align	2
	.globl	printhex
	.type	printhex, @function
printhex:
	addi	sp,sp,-176
	sd	s1,160(sp)
	srli	s1,a0,40
	li	a5,9
	andi	s1,s1,15
	sd	s2,152(sp)
	srli	s2,a0,36
	andi	a6,s2,15
	sd	s3,144(sp)
	sgtu	s2,s1,a5
	sd	s4,136(sp)
	sd	s5,128(sp)
	sd	s6,120(sp)
	sd	s7,112(sp)
	sd	s8,104(sp)
	sd	s9,96(sp)
	srli	s8,a0,8
	srli	s9,a0,4
	srli	s7,a0,12
	srli	s6,a0,16
	srli	s5,a0,20
	srli	s4,a0,24
	srli	s3,a0,32
	srli	a1,a0,44
	srli	a2,a0,48
	srli	a3,a0,52
	srli	a4,a0,56
	andi	s3,s3,15
	sw	s2,44(sp)
	sd	s10,88(sp)
	sd	s11,80(sp)
	srliw	s10,a0,28
	andi	s11,a0,15
	andi	s9,s9,15
	srli	a0,a0,60
	andi	s8,s8,15
	andi	s7,s7,15
	andi	s6,s6,15
	andi	s5,s5,15
	andi	s4,s4,15
	andi	a1,a1,15
	andi	a2,a2,15
	andi	a3,a3,15
	andi	a4,a4,15
	sd	a6,0(sp)
	sgtu	t2,s9,a5
	sgtu	t0,s8,a5
	sgtu	t6,s7,a5
	sgtu	t5,s6,a5
	sgtu	t4,s5,a5
	sgtu	t3,s4,a5
	sgtu	t1,s10,a5
	sgtu	a7,s3,a5
	sd	a1,8(sp)
	sd	a2,16(sp)
	sd	a3,24(sp)
	sd	a4,32(sp)
	sd	s0,168(sp)
	sgtu	a6,a6,a5
	sgtu	s0,s11,a5
	sgtu	a1,a1,a5
	sgtu	a2,a2,a5
	sgtu	a3,a3,a5
	sgtu	a4,a4,a5
	mv	s2,a0
	sgtu	a5,a0,a5
	lw	a0,44(sp)
	negw	s0,s0
	negw	t0,t0
	negw	t5,t5
	negw	t3,t3
	negw	a7,a7
	negw	a0,a0
	andi	s0,s0,39
	andi	t0,t0,39
	andi	t5,t5,39
	andi	t3,t3,39
	andi	a7,a7,39
	andi	a0,a0,39
	addiw	s0,s0,48
	addiw	t0,t0,48
	addiw	t5,t5,48
	addiw	t3,t3,48
	addiw	a7,a7,48
	addiw	a0,a0,48
	negw	t2,t2
	negw	t6,t6
	negw	t4,t4
	negw	t1,t1
	addw	s11,s0,s11
	addw	s8,t0,s8
	addw	s0,a7,s3
	addw	t0,a0,s1
	ld	s3,0(sp)
	ld	s1,8(sp)
	ld	a7,32(sp)
	addw	s6,t5,s6
	addw	s4,t3,s4
	ld	t5,16(sp)
	ld	t3,24(sp)
	negw	a6,a6
	negw	a1,a1
	negw	a2,a2
	negw	a3,a3
	negw	a4,a4
	negw	a5,a5
	andi	t2,t2,39
	andi	t6,t6,39
	andi	t4,t4,39
	andi	t1,t1,39
	addiw	t2,t2,48
	addiw	t6,t6,48
	addiw	t4,t4,48
	addiw	t1,t1,48
	andi	a6,a6,39
	andi	a1,a1,39
	andi	a2,a2,39
	andi	a3,a3,39
	andi	a4,a4,39
	andi	a5,a5,39
	addiw	a6,a6,48
	addiw	a2,a2,48
	addw	s9,t2,s9
	addw	s7,t6,s7
	addw	s5,t4,s5
	addw	s10,t1,s10
	addiw	a1,a1,48
	addiw	a3,a3,48
	addiw	a4,a4,48
	addiw	a5,a5,48
	addw	t2,a6,s3
	addw	t4,a2,t5
	addw	t6,a1,s1
	addw	t1,a3,t3
	addw	a6,a4,a7
	addw	a0,a5,s2
	sb	s11,71(sp)
	sb	s9,70(sp)
	sb	s8,69(sp)
	sb	s7,68(sp)
	sb	s6,67(sp)
	sb	s5,66(sp)
	sb	s4,65(sp)
	sb	s10,64(sp)
	sb	s0,63(sp)
	addi	a2,sp,56
	sb	t2,62(sp)
	sb	t0,61(sp)
	sb	t6,60(sp)
	sb	t4,59(sp)
	sb	t1,58(sp)
	sb	a6,57(sp)
	sb	a0,56(sp)
	sb	zero,72(sp)
.L609:
	lbu	a1,1(a2)
	addi	a2,a2,1
	bne	a1,zero,.L609
	addi	a1,sp,56
	li	a7,64
	li	a0,1
	sub	a2,a2,a1
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
	ld	s0,168(sp)
	ld	s1,160(sp)
	ld	s2,152(sp)
	ld	s3,144(sp)
	ld	s4,136(sp)
	ld	s5,128(sp)
	ld	s6,120(sp)
	ld	s7,112(sp)
	ld	s8,104(sp)
	ld	s9,96(sp)
	ld	s10,88(sp)
	ld	s11,80(sp)
	addi	sp,sp,176
	jr	ra
	.size	printhex, .-printhex
	.align	2
	.globl	printf
	.type	printf, @function
printf:
	addi	sp,sp,-96
	addi	t1,sp,40
	sd	a1,40(sp)
	mv	a1,t1
	sd	ra,24(sp)
	sd	a2,48(sp)
	sd	a3,56(sp)
	sd	a4,64(sp)
	sd	a5,72(sp)
	sd	a6,80(sp)
	sd	a7,88(sp)
	sd	t1,8(sp)
	call	vprintfmt.constprop.0
	ld	ra,24(sp)
	li	a0,0
	addi	sp,sp,96
	jr	ra
	.size	printf, .-printf
	.align	2
	.globl	sprintf
	.type	sprintf, @function
sprintf:
	addi	sp,sp,-96
	addi	t1,sp,48
	sd	s0,32(sp)
	sd	a0,8(sp)
	sd	a2,48(sp)
	mv	s0,a0
	mv	a2,t1
	addi	a0,sp,8
	sd	ra,40(sp)
	sd	a5,72(sp)
	sd	a3,56(sp)
	sd	a4,64(sp)
	sd	a6,80(sp)
	sd	a7,88(sp)
	sd	t1,24(sp)
	call	vprintfmt.constprop.1
	ld	a5,8(sp)
	sb	zero,0(a5)
	ld	a0,8(sp)
	ld	ra,40(sp)
	subw	a0,a0,s0
	ld	s0,32(sp)
	addi	sp,sp,96
	jr	ra
	.size	sprintf, .-sprintf
	.align	2
	.globl	memcpy
	.type	memcpy, @function
memcpy:
	or	a3,a1,a2
	or	t0,a3,a0
	andi	t1,t0,7
	mv	a4,a0
	mv	a5,a1
	add	a6,a0,a2
	beq	t1,zero,.L617
	bleu	a6,a0,.L719
	addi	t3,a1,1
	sub	t2,a0,t3
	or	a7,a1,a0
	sltiu	t4,t2,7
	andi	t5,a7,7
	addi	t6,a2,-1
	xori	a3,t4,1
	seqz	t0,t5
	sltiu	t1,t6,10
	and	t2,a3,t0
	xori	a7,t1,1
	and	t4,t2,a7
	andi	t5,t4,0xff
	beq	t5,zero,.L621
	andi	t3,a2,-8
	addi	t6,t3,-8
	srli	a3,t6,3
	addi	t0,a3,1
	andi	t2,t0,7
	add	a7,t3,a1
	beq	t2,zero,.L622
	li	t1,1
	beq	t2,t1,.L696
	li	t4,2
	beq	t2,t4,.L697
	li	t5,3
	beq	t2,t5,.L698
	li	t3,4
	beq	t2,t3,.L699
	li	t6,5
	beq	t2,t6,.L700
	li	a3,6
	bne	t2,a3,.L720
.L701:
	ld	t2,0(a5)
	addi	a4,a4,8
	addi	a5,a5,8
	sd	t2,-8(a4)
.L700:
	ld	t1,0(a5)
	addi	a4,a4,8
	addi	a5,a5,8
	sd	t1,-8(a4)
.L699:
	ld	t4,0(a5)
	addi	a4,a4,8
	addi	a5,a5,8
	sd	t4,-8(a4)
.L698:
	ld	t5,0(a5)
	addi	a4,a4,8
	addi	a5,a5,8
	sd	t5,-8(a4)
.L697:
	ld	t3,0(a5)
	addi	a4,a4,8
	addi	a5,a5,8
	sd	t3,-8(a4)
.L696:
	ld	t6,0(a5)
	addi	a5,a5,8
	addi	a4,a4,8
	sd	t6,-8(a4)
	beq	a5,a7,.L718
.L622:
	ld	a3,0(a5)
	addi	a5,a5,64
	addi	a4,a4,64
	sd	a3,-64(a4)
	ld	t0,-56(a5)
	sd	t0,-56(a4)
	ld	t2,-48(a5)
	sd	t2,-48(a4)
	ld	t1,-40(a5)
	sd	t1,-40(a4)
	ld	t4,-32(a5)
	sd	t4,-32(a4)
	ld	t5,-24(a5)
	sd	t5,-24(a4)
	ld	t3,-16(a5)
	sd	t3,-16(a4)
	ld	t6,-8(a5)
	sd	t6,-8(a4)
	bne	a5,a7,.L622
.L718:
	andi	a7,a2,-8
	add	a1,a1,a7
	add	a5,a0,a7
	beq	a2,a7,.L628
	lbu	a2,0(a1)
	addi	a4,a5,1
	sb	a2,0(a5)
	bleu	a6,a4,.L628
	lbu	a3,1(a1)
	addi	t0,a5,2
	sb	a3,1(a5)
	bleu	a6,t0,.L628
	lbu	t2,2(a1)
	addi	t1,a5,3
	sb	t2,2(a5)
	bleu	a6,t1,.L628
	lbu	t4,3(a1)
	addi	t5,a5,4
	sb	t4,3(a5)
	bleu	a6,t5,.L628
	lbu	t3,4(a1)
	addi	t6,a5,5
	sb	t3,4(a5)
	bleu	a6,t6,.L628
	lbu	a7,5(a1)
	addi	a2,a5,6
	sb	a7,5(a5)
	bleu	a6,a2,.L628
	lbu	a6,6(a1)
	sb	a6,6(a5)
	ret
.L617:
	bleu	a6,a0,.L628
	ld	t0,0(a1)
	not	a4,a0
	add	t2,a6,a4
	srli	a3,t2,3
	addi	a5,a0,8
	sd	t0,-8(a5)
	addi	a1,a1,8
	andi	t3,a3,7
	bleu	a6,a5,.L721
	beq	t3,zero,.L620
	li	t1,1
	beq	t3,t1,.L702
	li	t4,2
	beq	t3,t4,.L703
	li	t5,3
	beq	t3,t5,.L704
	li	t6,4
	beq	t3,t6,.L705
	li	a7,5
	beq	t3,a7,.L706
	li	a2,6
	bne	t3,a2,.L722
.L707:
	ld	a4,0(a1)
	addi	a5,a5,8
	addi	a1,a1,8
	sd	a4,-8(a5)
.L706:
	ld	t2,0(a1)
	addi	a5,a5,8
	addi	a1,a1,8
	sd	t2,-8(a5)
.L705:
	ld	a3,0(a1)
	addi	a5,a5,8
	addi	a1,a1,8
	sd	a3,-8(a5)
.L704:
	ld	t3,0(a1)
	addi	a5,a5,8
	addi	a1,a1,8
	sd	t3,-8(a5)
.L703:
	ld	t1,0(a1)
	addi	a5,a5,8
	addi	a1,a1,8
	sd	t1,-8(a5)
.L702:
	ld	t4,0(a1)
	addi	a5,a5,8
	addi	a1,a1,8
	sd	t4,-8(a5)
	bleu	a6,a5,.L723
.L620:
	ld	t5,0(a1)
	addi	a1,a1,64
	addi	a5,a5,64
	sd	t5,-64(a5)
	ld	t6,-56(a1)
	sd	t6,-56(a5)
	ld	a7,-48(a1)
	sd	a7,-48(a5)
	ld	a2,-40(a1)
	sd	a2,-40(a5)
	ld	t0,-32(a1)
	sd	t0,-32(a5)
	ld	a4,-24(a1)
	sd	a4,-24(a5)
	ld	t2,-16(a1)
	sd	t2,-16(a5)
	ld	a3,-8(a1)
	sd	a3,-8(a5)
	bgtu	a6,a5,.L620
	ret
.L724:
	lbu	t1,0(t3)
	addi	t3,t3,8
	addi	a5,a5,8
	sb	t1,-7(a5)
	lbu	t4,-7(t3)
	sb	t4,-6(a5)
	lbu	t5,-6(t3)
	sb	t5,-5(a5)
	lbu	t6,-5(t3)
	sb	t6,-4(a5)
	lbu	a7,-4(t3)
	sb	a7,-3(a5)
	lbu	a2,-3(t3)
	sb	a2,-2(a5)
	lbu	a6,-2(t3)
	sb	a6,-1(a5)
.L625:
	lbu	a1,-1(t3)
	sb	a1,0(a5)
	bne	t3,t0,.L724
.L628:
	ret
.L719:
	ret
.L621:
	add	t0,a1,a2
	sub	a5,t0,t3
	andi	a4,a5,7
	mv	a5,a0
	beq	a4,zero,.L625
	lbu	t2,-1(t3)
	li	a3,1
	addi	a5,a0,1
	sb	t2,-1(a5)
	addi	t3,a1,2
	beq	a4,a3,.L625
	li	a1,2
	beq	a4,a1,.L708
	li	t1,3
	beq	a4,t1,.L709
	li	t4,4
	beq	a4,t4,.L710
	li	t5,5
	beq	a4,t5,.L711
	li	t6,6
	beq	a4,t6,.L712
	lbu	a7,-1(t3)
	addi	a5,a5,1
	addi	t3,t3,1
	sb	a7,-1(a5)
.L712:
	lbu	a2,-1(t3)
	addi	a5,a5,1
	addi	t3,t3,1
	sb	a2,-1(a5)
.L711:
	lbu	a6,-1(t3)
	addi	a5,a5,1
	addi	t3,t3,1
	sb	a6,-1(a5)
.L710:
	lbu	a4,-1(t3)
	addi	a5,a5,1
	addi	t3,t3,1
	sb	a4,-1(a5)
.L709:
	lbu	t2,-1(t3)
	addi	a5,a5,1
	addi	t3,t3,1
	sb	t2,-1(a5)
.L708:
	lbu	a3,-1(t3)
	addi	a5,a5,1
	addi	t3,t3,1
	sb	a3,-1(a5)
	j	.L625
.L722:
	ld	t0,0(a1)
	addi	a5,a5,8
	addi	a1,a1,8
	sd	t0,-8(a5)
	j	.L707
.L720:
	ld	t0,0(a1)
	addi	a5,a1,8
	addi	a4,a0,8
	sd	t0,0(a0)
	j	.L701
.L723:
	ret
.L721:
	ret
	.size	memcpy, .-memcpy
	.align	2
	.globl	memset
	.type	memset, @function
memset:
	or	a5,a0,a2
	andi	t0,a5,7
	add	t5,a0,a2
	beq	t0,zero,.L726
	bleu	t5,a0,.L803
	neg	t1,a0
	andi	t2,t1,7
	addi	a4,t2,7
	li	a6,11
	andi	a1,a1,0xff
	addi	a3,a2,-1
	bgeu	a4,a6,.L731
	li	a4,11
.L731:
	bltu	a3,a4,.L737
	mv	t3,a0
	beq	t2,zero,.L732
	sb	a1,0(a0)
	li	a7,1
	addi	t3,a0,1
	beq	t2,a7,.L732
	sb	a1,1(a0)
	li	t4,2
	addi	t3,a0,2
	beq	t2,t4,.L732
	sb	a1,2(a0)
	li	t6,3
	addi	t3,a0,3
	beq	t2,t6,.L732
	sb	a1,3(a0)
	li	a5,4
	addi	t3,a0,4
	beq	t2,a5,.L732
	sb	a1,4(a0)
	li	t0,5
	addi	t3,a0,5
	beq	t2,t0,.L732
	sb	a1,5(a0)
	li	t1,7
	addi	t3,a0,6
	bne	t2,t1,.L732
	addi	t3,a0,7
	sb	a1,6(a0)
.L732:
	slli	a6,a1,8
	sub	t4,a2,t2
	or	a4,a1,a6
	slli	a3,a1,16
	or	a7,a4,a3
	andi	t6,t4,-8
	slli	a2,a1,24
	or	t0,a7,a2
	addi	t1,t6,-8
	slli	a5,a1,32
	or	a6,t0,a5
	slli	a4,a1,40
	srli	a7,t1,3
	or	a2,a6,a4
	slli	a3,a1,48
	addi	t0,a7,1
	add	a5,a0,t2
	slli	t1,a1,56
	or	a4,a2,a3
	andi	t2,t0,7
	or	a6,a4,t1
	add	t6,t6,a5
	beq	t2,zero,.L734
	li	a7,1
	beq	t2,a7,.L786
	li	a3,2
	beq	t2,a3,.L787
	li	a2,3
	beq	t2,a2,.L788
	li	t0,4
	beq	t2,t0,.L789
	li	t1,5
	beq	t2,t1,.L790
	li	a4,6
	beq	t2,a4,.L791
	sd	a6,0(a5)
	addi	a5,a5,8
.L791:
	sd	a6,0(a5)
	addi	a5,a5,8
.L790:
	sd	a6,0(a5)
	addi	a5,a5,8
.L789:
	sd	a6,0(a5)
	addi	a5,a5,8
.L788:
	sd	a6,0(a5)
	addi	a5,a5,8
.L787:
	sd	a6,0(a5)
	addi	a5,a5,8
.L786:
	sd	a6,0(a5)
	addi	a5,a5,8
	beq	a5,t6,.L802
.L734:
	sd	a6,0(a5)
	sd	a6,8(a5)
	sd	a6,16(a5)
	sd	a6,24(a5)
	sd	a6,32(a5)
	sd	a6,40(a5)
	sd	a6,48(a5)
	sd	a6,56(a5)
	addi	a5,a5,64
	bne	a5,t6,.L734
.L802:
	andi	t2,t4,-8
	add	a2,t3,t2
	beq	t4,t2,.L804
.L730:
	sb	a1,0(a2)
	addi	t3,a2,1
	bleu	t5,t3,.L739
	sb	a1,1(a2)
	addi	t4,a2,2
	bleu	t5,t4,.L739
	sb	a1,2(a2)
	addi	a6,a2,3
	bleu	t5,a6,.L739
	sb	a1,3(a2)
	addi	t6,a2,4
	bleu	t5,t6,.L739
	sb	a1,4(a2)
	addi	a7,a2,5
	bleu	t5,a7,.L739
	sb	a1,5(a2)
	addi	a3,a2,6
	bleu	t5,a3,.L739
	sb	a1,6(a2)
	addi	t0,a2,7
	bleu	t5,t0,.L739
	sb	a1,7(a2)
	addi	t1,a2,8
	bleu	t5,t1,.L739
	sb	a1,8(a2)
	addi	a4,a2,9
	bleu	t5,a4,.L739
	sb	a1,9(a2)
	addi	a5,a2,10
	bleu	t5,a5,.L739
	sb	a1,10(a2)
	addi	t2,a2,11
	bleu	t5,t2,.L739
	sb	a1,11(a2)
	addi	t3,a2,12
	bleu	t5,t3,.L739
	sb	a1,12(a2)
	addi	t4,a2,13
	bleu	t5,t4,.L739
	sb	a1,13(a2)
.L739:
	ret
.L726:
	andi	a1,a1,0xff
	slli	a2,a1,8
	or	a6,a1,a2
	slli	t6,a6,16
	or	a7,a6,t6
	slli	a3,a7,32
	or	t0,a7,a3
	bleu	t5,a0,.L739
	not	t1,a0
	add	a4,t5,t1
	srli	a5,a4,3
	addi	a7,a0,8
	sd	t0,-8(a7)
	andi	t2,a5,7
	bleu	t5,a7,.L805
	beq	t2,zero,.L729
	li	t3,1
	beq	t2,t3,.L792
	li	t4,2
	beq	t2,t4,.L793
	li	a1,3
	beq	t2,a1,.L794
	li	a2,4
	beq	t2,a2,.L795
	li	a6,5
	beq	t2,a6,.L796
	li	t6,6
	bne	t2,t6,.L806
.L797:
	sd	t0,0(a7)
	addi	a7,a7,8
.L796:
	sd	t0,0(a7)
	addi	a7,a7,8
.L795:
	sd	t0,0(a7)
	addi	a7,a7,8
.L794:
	sd	t0,0(a7)
	addi	a7,a7,8
.L793:
	sd	t0,0(a7)
	addi	a7,a7,8
.L792:
	addi	a7,a7,8
	sd	t0,-8(a7)
	bleu	t5,a7,.L807
.L729:
	sd	t0,0(a7)
	sd	t0,8(a7)
	sd	t0,16(a7)
	sd	t0,24(a7)
	sd	t0,32(a7)
	sd	t0,40(a7)
	sd	t0,48(a7)
	sd	t0,56(a7)
	addi	a7,a7,64
	bgtu	t5,a7,.L729
	ret
.L803:
	ret
.L804:
	ret
.L806:
	sd	t0,0(a7)
	addi	a7,a7,8
	j	.L797
.L807:
	ret
.L805:
	ret
.L737:
	mv	a2,a0
	j	.L730
	.size	memset, .-memset
	.align	2
	.type	init_tls, @function
init_tls:
	addi	sp,sp,-32
	sd	s1,8(sp)
	lla	a1,_tdata_begin
	lla	s1,_tdata_end
	sd	s0,16(sp)
	sub	s0,s1,a1
	mv	a2,s0
	mv	a0,tp
	sd	s2,0(sp)
	sd	ra,24(sp)
	mv	s2,tp
	call	memcpy
	add	a0,s2,s0
	lla	a2,_tbss_end
	ld	s0,16(sp)
	ld	ra,24(sp)
	ld	s2,0(sp)
	sub	a2,a2,s1
	ld	s1,8(sp)
	li	a1,0
	addi	sp,sp,32
	tail	memset
	.size	init_tls, .-init_tls
	.align	2
	.globl	_init_
	.type	_init_, @function
_init_:
	addi	sp,sp,-16
	sd	s0,0(sp)
	mv	s0,a0
	sd	ra,8(sp)
	call	init_tls
	beq	s0,zero,.L811
	call	_idle_section_
.L811:
	li	a1,0
	li	a0,0
	call	main
	call	exit
	.size	_init_, .-_init_
	.section	.rodata.str1.8
	.align	3
.LC4:
	.string	"%s = %d\n"
	.text
	.align	2
	.globl	_init
	.type	_init, @function
_init:
	addi	sp,sp,-160
	sd	ra,152(sp)
	sd	s0,144(sp)
	sd	s1,136(sp)
	sd	s2,128(sp)
	mv	s1,a0
	mv	s2,a1
	sd	s3,120(sp)
	call	init_tls
	mv	a1,s2
	mv	a0,s1
	call	thread_entry
	li	a1,0
	li	a0,0
	call	main
	lla	s2,.LANCHOR1
	ld	a3,0(s2)
	addi	s0,sp,63
	andi	s0,s0,-64
	mv	s1,a0
	bne	a3,zero,.L830
	ld	a3,8(s2)
	mv	s3,s0
	beq	a3,zero,.L817
.L820:
	ld	a2,24(s2)
	mv	a0,s3
	lla	a1,.LC4
	call	sprintf
	add	s3,s3,a0
.L815:
	beq	s0,s3,.L817
	lbu	a5,0(s0)
	mv	a2,s0
	beq	a5,zero,.L818
.L819:
	lbu	ra,1(a2)
	addi	a2,a2,1
	bne	ra,zero,.L819
.L818:
	li	a7,64
	li	a0,1
	mv	a1,s0
	sub	a2,a2,s0
 #APP
# 118 "../common/syscalls.c" 1
	scall
# 0 "" 2
 #NO_APP
.L817:
	mv	a0,s1
	call	exit
.L830:
	ld	a2,16(s2)
	lla	a1,.LC4
	mv	a0,s0
	call	sprintf
	ld	a3,8(s2)
	add	s3,s0,a0
	beq	a3,zero,.L815
	j	.L820
	.size	_init, .-_init
	.align	2
	.globl	strlen
	.type	strlen, @function
strlen:
	lbu	a5,0(a0)
	beq	a5,zero,.L834
	mv	t0,a0
.L833:
	lbu	a4,1(t0)
	addi	t0,t0,1
	bne	a4,zero,.L833
	sub	a0,t0,a0
	ret
.L834:
	li	a0,0
	ret
	.size	strlen, .-strlen
	.align	2
	.globl	strnlen
	.type	strnlen, @function
strnlen:
	add	a3,a0,a1
	mv	a5,a0
	beq	a1,zero,.L886
	sub	a4,a3,a0
	andi	t0,a4,7
	beq	t0,zero,.L839
	li	a2,1
	beq	t0,a2,.L879
	li	t1,2
	beq	t0,t1,.L880
	li	t2,3
	beq	t0,t2,.L881
	li	a1,4
	beq	t0,a1,.L882
	li	a6,5
	beq	t0,a6,.L883
	li	a7,6
	bne	t0,a7,.L890
.L884:
	lbu	t4,0(a5)
	beq	t4,zero,.L888
	addi	a5,a5,1
.L883:
	lbu	t5,0(a5)
	beq	t5,zero,.L888
	addi	a5,a5,1
.L882:
	lbu	t6,0(a5)
	beq	t6,zero,.L888
	addi	a5,a5,1
.L881:
	lbu	a4,0(a5)
	beq	a4,zero,.L888
	addi	a5,a5,1
.L880:
	lbu	t0,0(a5)
	beq	t0,zero,.L888
	addi	a5,a5,1
.L879:
	lbu	a2,0(a5)
	beq	a2,zero,.L888
	addi	a5,a5,1
	beq	a3,a5,.L889
.L839:
	lbu	t1,0(a5)
	beq	t1,zero,.L888
	lbu	t2,1(a5)
	addi	a5,a5,1
	mv	a1,a5
	beq	t2,zero,.L888
	lbu	a6,1(a5)
	addi	a5,a5,1
	beq	a6,zero,.L888
	lbu	a7,2(a1)
	addi	a5,a1,2
	beq	a7,zero,.L888
	lbu	t3,3(a1)
	addi	a5,a1,3
	beq	t3,zero,.L888
	lbu	t4,4(a1)
	addi	a5,a1,4
	beq	t4,zero,.L888
	lbu	t5,5(a1)
	addi	a5,a1,5
	beq	t5,zero,.L888
	lbu	t6,6(a1)
	addi	a5,a1,6
	beq	t6,zero,.L888
	addi	a5,a1,7
	bne	a3,a5,.L839
.L889:
	sub	a0,a3,a0
	ret
.L888:
	sub	a0,a5,a0
	ret
.L890:
	lbu	t3,0(a0)
	beq	t3,zero,.L888
	addi	a5,a0,1
	j	.L884
.L886:
	li	a0,0
	ret
	.size	strnlen, .-strnlen
	.globl	cores_jump_address
	.globl	have_vec
	.bss
	.align	3
	.set	.LANCHOR1,. + 0
	.type	counters, @object
	.size	counters, 16
counters:
	.zero	16
	.type	counter_names, @object
	.size	counter_names, 16
counter_names:
	.zero	16
	.section	.sbss,"aw",@nobits
	.align	3
	.type	cores_jump_address, @object
	.size	cores_jump_address, 8
cores_jump_address:
	.zero	8
	.type	have_vec, @object
	.size	have_vec, 4
have_vec:
	.zero	4
	.section	.tbss,"awT",@nobits
	.align	6
	.set	.LANCHOR0,. + 0
	.type	buf.2, @object
	.size	buf.2, 64
buf.2:
	.zero	64
	.type	buflen.1, @object
	.size	buflen.1, 4
buflen.1:
	.zero	4
	.ident	"GCC: (GNU) 10.2.0"
