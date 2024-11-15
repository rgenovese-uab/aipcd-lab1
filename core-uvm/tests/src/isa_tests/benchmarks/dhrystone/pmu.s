	.file	"pmu.c"
	.option nopic
	.attribute arch, "rv64i2p0_m2p0_a2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC0:
	.string	"\n *** Memory dump***\n\n"
	.align	3
.LC1:
	.string	"addres:%x \n"
	.align	3
.LC2:
	.string	"value :%d \n"
	.align	3
.LC3:
	.string	"\n *** END DUMP ***\n\n"
	.text
	.align	2
	.globl	read_test_loop
	.type	read_test_loop, @function
read_test_loop:
	addi	sp,sp,-64
	sd	s0,48(sp)
	sd	s1,40(sp)
	mv	s0,a0
	addiw	s1,a1,4
	lla	a0,.LC0
	sd	s2,32(sp)
	sd	ra,56(sp)
	sd	s3,24(sp)
	sd	s4,16(sp)
	mv	s2,a2
	call	printf
	bgeu	s0,s1,.L2
	lla	s4,.LC1
	lla	s3,.LC2
.L3:
	slli	a5,s0,32
	srli	ra,a5,32
	lw	t0,0(ra)
	mv	a1,s0
	mv	a0,s4
	sext.w	t1,t0
	sw	t1,12(sp)
	call	printf
	lw	a1,12(sp)
	addw	s0,s2,s0
	mv	a0,s3
	sext.w	a1,a1
	call	printf
	bltu	s0,s1,.L3
.L2:
	ld	s0,48(sp)
	ld	ra,56(sp)
	ld	s1,40(sp)
	ld	s2,32(sp)
	ld	s3,24(sp)
	ld	s4,16(sp)
	lla	a0,.LC3
	addi	sp,sp,64
	tail	printf
	.size	read_test_loop, .-read_test_loop
	.align	2
	.globl	search_loop
	.type	search_loop, @function
search_loop:
	addi	sp,sp,-80
	sd	s0,64(sp)
	sd	s3,40(sp)
	mv	s0,a0
	addiw	s3,a1,4
	lla	a0,.LC0
	sd	s1,56(sp)
	sd	s2,48(sp)
	sd	s4,32(sp)
	sd	ra,72(sp)
	sd	s5,24(sp)
	sd	s6,16(sp)
	mv	s4,a1
	mv	s2,a2
	mv	s1,a3
	call	printf
	bgeu	s0,s3,.L8
	lla	s6,.LC1
	lla	s5,.LC2
	addw	s4,s4,s2
.L11:
	slli	a5,s0,32
	srli	ra,a5,32
	lw	t0,0(ra)
	sext.w	t1,t0
	sw	t1,12(sp)
	lw	t2,12(sp)
	sext.w	a0,t2
	beq	a0,s1,.L13
	addw	s0,s2,s0
	bltu	s0,s3,.L11
.L8:
	ld	s0,64(sp)
	ld	ra,72(sp)
	ld	s1,56(sp)
	ld	s2,48(sp)
	ld	s3,40(sp)
	ld	s4,32(sp)
	ld	s5,24(sp)
	ld	s6,16(sp)
	lla	a0,.LC3
	addi	sp,sp,80
	tail	printf
.L13:
	mv	a1,s0
	mv	a0,s6
	call	printf
	lw	a1,12(sp)
	mv	a0,s5
	mv	s0,s4
	sext.w	a1,a1
	call	printf
	bltu	s4,s3,.L11
	j	.L8
	.size	search_loop, .-search_loop
	.align	2
	.globl	enable_PMU_32b
	.type	enable_PMU_32b, @function
enable_PMU_32b:
	li	a5,1074921472
	li	a4,1
	sw	a4,108(a5)
	ret
	.size	enable_PMU_32b, .-enable_PMU_32b
	.align	2
	.globl	disable_PMU_32b
	.type	disable_PMU_32b, @function
disable_PMU_32b:
	li	a5,1074921472
	sw	zero,108(a5)
	ret
	.size	disable_PMU_32b, .-disable_PMU_32b
	.align	2
	.globl	get_cycles_32b
	.type	get_cycles_32b, @function
get_cycles_32b:
	li	a5,1074921472
	lw	a0,0(a5)
	sext.w	a0,a0
	ret
	.size	get_cycles_32b, .-get_cycles_32b
	.align	2
	.globl	get_imiss
	.type	get_imiss, @function
get_imiss:
	li	a5,1074921472
	lw	a0,4(a5)
	sext.w	a0,a0
	ret
	.size	get_imiss, .-get_imiss
	.align	2
	.globl	get_dmiss
	.type	get_dmiss, @function
get_dmiss:
	li	a5,1074921472
	lw	a0,12(a5)
	sext.w	a0,a0
	ret
	.size	get_dmiss, .-get_dmiss
	.align	2
	.globl	get_itlb_miss
	.type	get_itlb_miss, @function
get_itlb_miss:
	li	a5,1074921472
	lw	a0,8(a5)
	sext.w	a0,a0
	ret
	.size	get_itlb_miss, .-get_itlb_miss
	.align	2
	.globl	get_dtlb_miss
	.type	get_dtlb_miss, @function
get_dtlb_miss:
	li	a5,1074921472
	lw	a0,16(a5)
	sext.w	a0,a0
	ret
	.size	get_dtlb_miss, .-get_dtlb_miss
	.align	2
	.globl	get_store
	.type	get_store, @function
get_store:
	li	a5,1074921472
	lw	a0,20(a5)
	sext.w	a0,a0
	ret
	.size	get_store, .-get_store
	.align	2
	.globl	get_load
	.type	get_load, @function
get_load:
	li	a5,1074921472
	lw	a0,24(a5)
	sext.w	a0,a0
	ret
	.size	get_load, .-get_load
	.align	2
	.globl	get_branch_miss
	.type	get_branch_miss, @function
get_branch_miss:
	li	a5,1074921472
	lw	a0,28(a5)
	sext.w	a0,a0
	ret
	.size	get_branch_miss, .-get_branch_miss
	.align	2
	.globl	get_all_branch
	.type	get_all_branch, @function
get_all_branch:
	li	a5,1074921472
	lw	a0,80(a5)
	sext.w	a0,a0
	ret
	.size	get_all_branch, .-get_all_branch
	.align	2
	.globl	get_branch_taken
	.type	get_branch_taken, @function
get_branch_taken:
	li	a5,1074921472
	lw	a0,84(a5)
	sext.w	a0,a0
	ret
	.size	get_branch_taken, .-get_branch_taken
	.align	2
	.globl	get_icache_req
	.type	get_icache_req, @function
get_icache_req:
	li	a5,1074921472
	lw	a0,36(a5)
	sext.w	a0,a0
	ret
	.size	get_icache_req, .-get_icache_req
	.align	2
	.globl	get_icache_kill
	.type	get_icache_kill, @function
get_icache_kill:
	li	a5,1074921472
	lw	a0,40(a5)
	sext.w	a0,a0
	ret
	.size	get_icache_kill, .-get_icache_kill
	.align	2
	.globl	get_stall_time
	.type	get_stall_time, @function
get_stall_time:
	li	a5,1074921472
	lw	a0,44(a5)
	sext.w	a0,a0
	ret
	.size	get_stall_time, .-get_stall_time
	.align	2
	.globl	get_stall_id
	.type	get_stall_id, @function
get_stall_id:
	li	a5,1074921472
	lw	a0,48(a5)
	sext.w	a0,a0
	ret
	.size	get_stall_id, .-get_stall_id
	.align	2
	.globl	get_stall_frontend
	.type	get_stall_frontend, @function
get_stall_frontend:
	li	a5,1074921472
	lw	a0,48(a5)
	sext.w	a0,a0
	ret
	.size	get_stall_frontend, .-get_stall_frontend
	.align	2
	.globl	get_stall_rr
	.type	get_stall_rr, @function
get_stall_rr:
	li	a5,1074921472
	lw	a0,52(a5)
	sext.w	a0,a0
	ret
	.size	get_stall_rr, .-get_stall_rr
	.align	2
	.globl	get_load_after_store
	.type	get_load_after_store, @function
get_load_after_store:
	li	a5,1074921472
	lw	a0,52(a5)
	sext.w	a0,a0
	ret
	.size	get_load_after_store, .-get_load_after_store
	.align	2
	.globl	get_stall_exe
	.type	get_stall_exe, @function
get_stall_exe:
	li	a5,1074921472
	lw	a0,56(a5)
	sext.w	a0,a0
	ret
	.size	get_stall_exe, .-get_stall_exe
	.align	2
	.globl	get_stall_backend
	.type	get_stall_backend, @function
get_stall_backend:
	li	a5,1074921472
	lw	a0,56(a5)
	sext.w	a0,a0
	ret
	.size	get_stall_backend, .-get_stall_backend
	.align	2
	.globl	get_stall_wb
	.type	get_stall_wb, @function
get_stall_wb:
	li	a5,1074921472
	lw	a0,60(a5)
	sext.w	a0,a0
	ret
	.size	get_stall_wb, .-get_stall_wb
	.align	2
	.globl	get_imiss_l2hit
	.type	get_imiss_l2hit, @function
get_imiss_l2hit:
	li	a5,1074921472
	lw	a0,64(a5)
	sext.w	a0,a0
	ret
	.size	get_imiss_l2hit, .-get_imiss_l2hit
	.align	2
	.globl	get_imiss_time
	.type	get_imiss_time, @function
get_imiss_time:
	li	a5,1074921472
	lw	a0,68(a5)
	sext.w	a0,a0
	ret
	.size	get_imiss_time, .-get_imiss_time
	.align	2
	.globl	get_icache_bussy
	.type	get_icache_bussy, @function
get_icache_bussy:
	li	a5,1074921472
	lw	a0,72(a5)
	sext.w	a0,a0
	ret
	.size	get_icache_bussy, .-get_icache_bussy
	.align	2
	.globl	get_ikill_time
	.type	get_ikill_time, @function
get_ikill_time:
	li	a5,1074921472
	lw	a0,76(a5)
	sext.w	a0,a0
	ret
	.size	get_ikill_time, .-get_ikill_time
	.align	2
	.globl	get_load_store
	.type	get_load_store, @function
get_load_store:
	li	a5,1074921472
	lw	a0,88(a5)
	sext.w	a0,a0
	ret
	.size	get_load_store, .-get_load_store
	.align	2
	.globl	get_data_depend
	.type	get_data_depend, @function
get_data_depend:
	li	a5,1074921472
	lw	a0,92(a5)
	sext.w	a0,a0
	ret
	.size	get_data_depend, .-get_data_depend
	.align	2
	.globl	get_struct_depend
	.type	get_struct_depend, @function
get_struct_depend:
	li	a5,1074921472
	lw	a0,96(a5)
	sext.w	a0,a0
	ret
	.size	get_struct_depend, .-get_struct_depend
	.align	2
	.globl	get_grad_list_full
	.type	get_grad_list_full, @function
get_grad_list_full:
	li	a5,1074921472
	lw	a0,100(a5)
	sext.w	a0,a0
	ret
	.size	get_grad_list_full, .-get_grad_list_full
	.align	2
	.globl	get_free_list_empty
	.type	get_free_list_empty, @function
get_free_list_empty:
	li	a5,1074921472
	lw	a0,104(a5)
	sext.w	a0,a0
	ret
	.size	get_free_list_empty, .-get_free_list_empty
	.align	2
	.globl	get_instr_32b
	.type	get_instr_32b, @function
get_instr_32b:
	li	a5,1074921472
	lw	a0,32(a5)
	sext.w	a0,a0
	ret
	.size	get_instr_32b, .-get_instr_32b
	.align	2
	.globl	reset_pmu
	.type	reset_pmu, @function
reset_pmu:
	li	a5,1074921472
	li	a4,2
	sw	a4,108(a5)
	ret
	.size	reset_pmu, .-reset_pmu
	.align	2
	.globl	get_cycles
	.type	get_cycles, @function
get_cycles:
	li	a5,1074921472
	li	a4,2
	sw	a4,108(a5)
	li	a0,0
	ret
	.size	get_cycles, .-get_cycles
	.section	.rodata.str1.8
	.align	3
.LC4:
	.string	"\n ***Reset***\n\n"
	.align	3
.LC5:
	.string	"\n ***Enable***\n\n"
	.align	3
.LC6:
	.string	"\n ***Disable***\n\n"
	.text
	.align	2
	.globl	test_pmu
	.type	test_pmu, @function
test_pmu:
	addi	sp,sp,-64
	sd	s3,24(sp)
	lla	a0,.LC0
	li	s3,1074987008
	sd	s0,48(sp)
	sd	s1,40(sp)
	sd	s2,32(sp)
	sd	ra,56(sp)
	li	s0,1074921472
	call	printf
	lla	s2,.LC1
	lla	s1,.LC2
	addi	s3,s3,4
.L49:
	lw	a5,0(s0)
	sext.w	a1,s0
	mv	a0,s2
	sext.w	ra,a5
	sw	ra,12(sp)
	call	printf
	lw	a1,12(sp)
	mv	a0,s1
	sext.w	a1,a1
	call	printf
	lw	t0,4(s0)
	addiw	a1,s0,4
	mv	a0,s2
	sext.w	t1,t0
	sw	t1,12(sp)
	call	printf
	lw	t2,12(sp)
	mv	a0,s1
	sext.w	a1,t2
	call	printf
	lw	a2,8(s0)
	addiw	a1,s0,8
	mv	a0,s2
	sext.w	a3,a2
	sw	a3,12(sp)
	call	printf
	lw	a4,12(sp)
	mv	a0,s1
	sext.w	a1,a4
	call	printf
	lw	a6,12(s0)
	addiw	a1,s0,12
	mv	a0,s2
	sext.w	a7,a6
	sw	a7,12(sp)
	call	printf
	lw	t3,12(sp)
	mv	a0,s1
	sext.w	a1,t3
	call	printf
	lw	t4,16(s0)
	addiw	a1,s0,16
	mv	a0,s2
	sext.w	t5,t4
	sw	t5,12(sp)
	call	printf
	lw	t6,12(sp)
	addi	s0,s0,20
	mv	a0,s1
	sext.w	a1,t6
	call	printf
	bne	s0,s3,.L49
	lla	a0,.LC3
	call	printf
	lla	a0,.LC4
	call	printf
	li	a0,1074921472
	li	s2,2
	sw	s2,108(a0)
	li	s3,1074987008
	lla	a0,.LC0
	call	printf
	li	s0,1074921472
	lla	s2,.LC1
	lla	s1,.LC2
	addi	s3,s3,4
.L50:
	lw	a5,0(s0)
	sext.w	a1,s0
	mv	a0,s2
	sext.w	ra,a5
	sw	ra,8(sp)
	call	printf
	lw	a1,8(sp)
	mv	a0,s1
	sext.w	a1,a1
	call	printf
	lw	t0,4(s0)
	addiw	a1,s0,4
	mv	a0,s2
	sext.w	t1,t0
	sw	t1,8(sp)
	call	printf
	lw	t2,8(sp)
	mv	a0,s1
	sext.w	a1,t2
	call	printf
	lw	a2,8(s0)
	addiw	a1,s0,8
	mv	a0,s2
	sext.w	a3,a2
	sw	a3,8(sp)
	call	printf
	lw	a4,8(sp)
	mv	a0,s1
	sext.w	a1,a4
	call	printf
	lw	a6,12(s0)
	addiw	a1,s0,12
	mv	a0,s2
	sext.w	a7,a6
	sw	a7,8(sp)
	call	printf
	lw	t3,8(sp)
	mv	a0,s1
	sext.w	a1,t3
	call	printf
	lw	t4,16(s0)
	addiw	a1,s0,16
	mv	a0,s2
	sext.w	t5,t4
	sw	t5,8(sp)
	call	printf
	lw	t6,8(sp)
	addi	s0,s0,20
	mv	a0,s1
	sext.w	a1,t6
	call	printf
	bne	s0,s3,.L50
	lla	a0,.LC3
	call	printf
	lla	a0,.LC5
	call	printf
	li	a0,1074921472
	li	s2,1
	sw	s2,108(a0)
	li	s3,1074987008
	lla	a0,.LC0
	call	printf
	li	s0,1074921472
	lla	s2,.LC1
	lla	s1,.LC2
	addi	s3,s3,4
.L51:
	lw	a5,0(s0)
	sext.w	a1,s0
	mv	a0,s2
	sext.w	ra,a5
	sw	ra,4(sp)
	call	printf
	lw	a1,4(sp)
	mv	a0,s1
	sext.w	a1,a1
	call	printf
	lw	t0,4(s0)
	addiw	a1,s0,4
	mv	a0,s2
	sext.w	t1,t0
	sw	t1,4(sp)
	call	printf
	lw	t2,4(sp)
	mv	a0,s1
	sext.w	a1,t2
	call	printf
	lw	a2,8(s0)
	addiw	a1,s0,8
	mv	a0,s2
	sext.w	a3,a2
	sw	a3,4(sp)
	call	printf
	lw	a4,4(sp)
	mv	a0,s1
	sext.w	a1,a4
	call	printf
	lw	a6,12(s0)
	addiw	a1,s0,12
	mv	a0,s2
	sext.w	a7,a6
	sw	a7,4(sp)
	call	printf
	lw	t3,4(sp)
	mv	a0,s1
	sext.w	a1,t3
	call	printf
	lw	t4,16(s0)
	addiw	a1,s0,16
	mv	a0,s2
	sext.w	t5,t4
	sw	t5,4(sp)
	call	printf
	lw	t6,4(sp)
	addi	s0,s0,20
	mv	a0,s1
	sext.w	a1,t6
	call	printf
	bne	s0,s3,.L51
	lla	a0,.LC3
	call	printf
	lla	a0,.LC6
	call	printf
	li	a0,1074921472
	sw	zero,108(a0)
	li	s3,1074987008
	lla	a0,.LC0
	call	printf
	li	s0,1074921472
	lla	s2,.LC1
	lla	s1,.LC2
	addi	s3,s3,4
.L52:
	lw	a5,0(s0)
	sext.w	a1,s0
	mv	a0,s2
	sext.w	ra,a5
	sw	ra,0(sp)
	call	printf
	lw	a1,0(sp)
	mv	a0,s1
	sext.w	a1,a1
	call	printf
	lw	t0,4(s0)
	addiw	a1,s0,4
	mv	a0,s2
	sext.w	t1,t0
	sw	t1,0(sp)
	call	printf
	lw	t2,0(sp)
	mv	a0,s1
	sext.w	a1,t2
	call	printf
	lw	a2,8(s0)
	addiw	a1,s0,8
	mv	a0,s2
	sext.w	a3,a2
	sw	a3,0(sp)
	call	printf
	lw	a4,0(sp)
	mv	a0,s1
	sext.w	a1,a4
	call	printf
	lw	a6,12(s0)
	addiw	a1,s0,12
	mv	a0,s2
	sext.w	a7,a6
	sw	a7,0(sp)
	call	printf
	lw	t3,0(sp)
	mv	a0,s1
	sext.w	a1,t3
	call	printf
	lw	t4,16(s0)
	addiw	a1,s0,16
	mv	a0,s2
	sext.w	t5,t4
	sw	t5,0(sp)
	call	printf
	lw	t6,0(sp)
	addi	s0,s0,20
	mv	a0,s1
	sext.w	a1,t6
	call	printf
	bne	s0,s3,.L52
	lla	a0,.LC3
	call	printf
	ld	ra,56(sp)
	ld	s0,48(sp)
	ld	s1,40(sp)
	ld	s2,32(sp)
	ld	s3,24(sp)
	li	a0,0
	addi	sp,sp,64
	jr	ra
	.size	test_pmu, .-test_pmu
	.section	.rodata.str1.8
	.align	3
.LC7:
	.string	"-PMU   NUMBER OF EXEC CYCLES         :%d\n"
	.align	3
.LC8:
	.string	"-PMU   INSTRUCTION COUNTER           :%d\n"
	.align	3
.LC9:
	.string	"\n"
	.align	3
.LC10:
	.string	"-PMU   ICACHE REQ EVENT COUNTER      :%d\n"
	.align	3
.LC11:
	.string	"-PMU   IMISS EVENT COUNTER           :%d\n"
	.align	3
.LC12:
	.string	"-PMU   IMISS TIME COUNTER            :%d\n"
	.align	3
.LC13:
	.string	"-PMU   ICACHE KILL EVENT COUNTER     :%d\n"
	.align	3
.LC14:
	.string	"-PMU   ICACHE KILL TIME  COUNTER     :%d\n"
	.align	3
.LC15:
	.string	"-PMU   ICACHE BUSSY TIME COUNTER     :%d\n"
	.align	3
.LC16:
	.string	"-PMU   ITLB MISS COUNTER             :%d\n"
	.align	3
.LC17:
	.string	"-PMU   DMISS EVENT COUNTER           :%d\n"
	.align	3
.LC18:
	.string	"-PMU   STORE EVENT COUNTER           :%d\n"
	.align	3
.LC19:
	.string	"-PMU   LOAD EVENT COUNTER            :%d\n"
	.align	3
.LC20:
	.string	"-PMU   DTLB MISS COUNTER             :%d\n"
	.align	3
.LC21:
	.string	"-PMU   BRANCH EVENT COUNTER          :%d\n"
	.align	3
.LC22:
	.string	"-PMU   BRANCH TAKEN EVENT COUNTER    :%d\n"
	.align	3
.LC23:
	.string	"-PMU   STALL BY CSR TIME COUNTER     :%d\n"
	.align	3
.LC24:
	.string	"-PMU   STALL BY EXE-MEM TIME COUNTER :%d\n"
	.align	3
.LC25:
	.string	"-PMU   IMISS & L2 HIT COUNTER        :%d\n"
	.align	3
.LC26:
	.string	"////////////////////////////////////////////\n"
	.align	3
.LC27:
	.string	"-PMU   BRANCH MISSPREDICTIONS        :%d\n"
	.align	3
.LC28:
	.string	"-PMU   STALLS FRONTEND               :%d\n"
	.align	3
.LC29:
	.string	"-PMU   STALLS BACKEND                :%d\n"
	.align	3
.LC30:
	.string	"-PMU   NUMBER OF LOADS AND STORES    :%d\n"
	.align	3
.LC31:
	.string	"-PMU   CYCLES LOAD BLOCKED BY STORE  :%d\n"
	.align	3
.LC32:
	.string	"-PMU   STALL BY DATA DEPENDENCY      :%d\n"
	.align	3
.LC33:
	.string	"-PMU   STALL BY STRUCTURAL RISK      :%d\n"
	.align	3
.LC34:
	.string	"-PMU   STALL BY GRADUATION LIST FULL :%d\n"
	.align	3
.LC35:
	.string	"-PMU   STALL BY FREE LIST EMPTY      :%d\n"
	.text
	.align	2
	.globl	print_PMU_events
	.type	print_PMU_events, @function
print_PMU_events:
	addi	sp,sp,-16
	sd	s0,0(sp)
	li	s0,1074921472
	lw	a1,0(s0)
	lla	a0,.LC7
	sd	ra,8(sp)
	sext.w	a1,a1
	call	printf
	lw	t0,32(s0)
	lla	a0,.LC8
	sext.w	a1,t0
	call	printf
	lla	a0,.LC9
	call	printf
	lw	t1,36(s0)
	lla	a0,.LC10
	sext.w	a1,t1
	call	printf
	lw	t2,4(s0)
	lla	a0,.LC11
	sext.w	a1,t2
	call	printf
	lw	a2,68(s0)
	lla	a0,.LC12
	sext.w	a1,a2
	call	printf
	lw	a3,40(s0)
	lla	a0,.LC13
	sext.w	a1,a3
	call	printf
	lw	a4,76(s0)
	lla	a0,.LC14
	sext.w	a1,a4
	call	printf
	lw	a5,72(s0)
	lla	a0,.LC15
	sext.w	a1,a5
	call	printf
	lw	a6,8(s0)
	lla	a0,.LC16
	sext.w	a1,a6
	call	printf
	lla	a0,.LC9
	call	printf
	lw	a7,12(s0)
	lla	a0,.LC17
	sext.w	a1,a7
	call	printf
	lw	t3,20(s0)
	lla	a0,.LC18
	sext.w	a1,t3
	call	printf
	lw	t4,24(s0)
	lla	a0,.LC19
	sext.w	a1,t4
	call	printf
	lw	t5,16(s0)
	lla	a0,.LC20
	sext.w	a1,t5
	call	printf
	lla	a0,.LC9
	call	printf
	lw	t6,80(s0)
	lla	a0,.LC21
	sext.w	a1,t6
	call	printf
	lw	a1,84(s0)
	lla	a0,.LC22
	sext.w	a1,a1
	call	printf
	lla	a0,.LC9
	call	printf
	lw	t0,44(s0)
	lla	a0,.LC23
	sext.w	a1,t0
	call	printf
	lw	t1,60(s0)
	lla	a0,.LC24
	sext.w	a1,t1
	call	printf
	lla	a0,.LC9
	call	printf
	lw	t2,64(s0)
	lla	a0,.LC25
	sext.w	a1,t2
	call	printf
	lla	a0,.LC26
	call	printf
	lw	a2,28(s0)
	lla	a0,.LC27
	sext.w	a1,a2
	call	printf
	lw	a3,48(s0)
	lla	a0,.LC28
	sext.w	a1,a3
	call	printf
	lw	a4,56(s0)
	lla	a0,.LC29
	sext.w	a1,a4
	call	printf
	lw	a5,88(s0)
	lla	a0,.LC30
	sext.w	a1,a5
	call	printf
	lw	a6,52(s0)
	lla	a0,.LC31
	sext.w	a1,a6
	call	printf
	lw	a7,92(s0)
	lla	a0,.LC32
	sext.w	a1,a7
	call	printf
	lw	t3,96(s0)
	lla	a0,.LC33
	sext.w	a1,t3
	call	printf
	lw	t4,100(s0)
	lla	a0,.LC34
	sext.w	a1,t4
	call	printf
	lw	s0,104(s0)
	ld	ra,8(sp)
	lla	a0,.LC35
	sext.w	a1,s0
	ld	s0,0(sp)
	addi	sp,sp,16
	tail	printf
	.size	print_PMU_events, .-print_PMU_events
	.ident	"GCC: (GNU) 10.2.0"
