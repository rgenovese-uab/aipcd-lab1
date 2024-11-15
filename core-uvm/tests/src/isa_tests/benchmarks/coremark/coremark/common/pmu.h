#ifndef PMU_HEADER_H
#define PMU_HEADER_H


#define IO_BASE             (0x40000000 )
#define IO_MASK             (0x0001ffff )
#define PMU_BASE            (0x40120000 )
#define MASK3               (0x0000ffff )
#define CONG_REG_1_OFFSET   (0x6C) //Neiel*Leyva -- N_COUNTERS(in hex) * 4 


#include <stdio.h>
//#include "uart.h"
#include <stdint.h>
#include <stdlib.h>
uint32_t test_pmu(void);
void read_test_loop(uint32_t entry, uint32_t exit,uint32_t aligment);
void search_loop(uint32_t entry, uint32_t exit,uint32_t aligment, uint32_t key);
void enable_PMU_32b (void)          ;
uint32_t reset_pmu(void)            ;
void disable_PMU_32b (void)         ;
uint32_t get_instr_32b (void)       ;
uint32_t get_cycles_32b (void)      ;
uint32_t get_imiss (void)           ;
uint32_t get_dmiss (void)           ;
uint32_t get_itlb_miss (void)       ;
uint32_t get_dtlb_miss (void)       ;
uint32_t get_store (void)           ;
uint32_t get_load (void)            ;
uint32_t get_branch_miss (void)     ;
uint32_t get_icache_req (void)      ;
uint32_t get_icache_kill (void)     ;
uint32_t get_stall_time (void)      ;
uint32_t get_stall_id (void)        ;
uint32_t get_stall_frontend (void)  ;
uint32_t get_stall_rr (void)        ;
uint32_t get_load_after_store (void);
uint32_t get_stall_exe (void)       ;
uint32_t get_stall_backend (void)   ;
uint32_t get_stall_wb (void)        ;
uint32_t get_imiss_l2hit (void)     ;
uint32_t get_imiss_time (void)      ;   
uint32_t get_icache_bussy (void)    ; 
uint32_t get_ikill_time (void)      ; 
uint32_t get_all_branch (void)      ;
uint32_t get_branch_taken (void)    ;
uint32_t get_load_store (void)      ;
uint32_t get_data_depend (void)     ;
uint32_t get_struct_depend (void)   ;
uint32_t get_grad_list_full (void)  ;
uint32_t get_free_list_empty (void) ;
void print_PMU_events (void)        ;

#endif

