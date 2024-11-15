#include <pmu.h>

typedef enum { false, true } bool;
#define CYCLES          0
#define IMISS           1
#define ITLBMISS        2
#define DMISS           3
#define DTLBMISS        4
#define STORES          5
#define LOAD            6
#define BRANCH_MISS     7
#define INSTR           8
#define IREQ            9
#define IKILL           0XA    //10
#define STALL_TIME      0XB    //11
#define STALLID         0XC    //12
#define STALLRR         0XD    //13
#define STALLEXE        0XE    //14
#define STALLWB         0XF    //15
#define IMISS_L2HIT     0X10   //16
#define IMISS_TIME      0X11   //17
#define ICACHE_BUSSY    0X12   //18
#define IKILL_TIME      0X13   //19
#define IS_BRANCH       0X14   //20
#define BRANCH_TAKEN    0X15   //21
#define LOAD_STORE      0X16   //22
#define DATA_DEPEND     0X17   //23
#define STRUCT_DEPEND   0X18   //24
#define GRAD_LIST_FULL  0X19   //25
#define FREE_LIST_EMPTY 0X1A   //26

void enable_PMU_32b (void){
    #ifndef TEST_CI
    uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    *var=1;
    #endif
}

void disable_PMU_32b (void){
    #ifndef TEST_CI
    uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    *var=0;
    #endif
}

uint32_t get_cycles_32b (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CYCLES*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_imiss (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IMISS*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_dmiss (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+DMISS*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_itlb_miss (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+ITLBMISS*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_dtlb_miss (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+DTLBMISS*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_store (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STORES*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_load (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+LOAD*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_branch_miss (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+BRANCH_MISS*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_all_branch (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IS_BRANCH*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_branch_taken (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+BRANCH_TAKEN*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_icache_req (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IREQ*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_icache_kill (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IKILL*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_stall_time (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALL_TIME*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_stall_id (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLID*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_stall_frontend (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLID*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_stall_rr (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLRR*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_load_after_store (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLRR*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_stall_exe (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLEXE*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_stall_backend (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLEXE*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_stall_wb (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLWB*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_imiss_l2hit (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IMISS_L2HIT*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_imiss_time (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IMISS_TIME*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_icache_bussy (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+ICACHE_BUSSY*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_ikill_time (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IKILL_TIME*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_load_store (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+LOAD_STORE*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_data_depend (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+DATA_DEPEND*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_struct_depend (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STRUCT_DEPEND*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_grad_list_full (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+GRAD_LIST_FULL*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_free_list_empty (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+FREE_LIST_EMPTY*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t get_instr_32b (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+INSTR*8);
    return *var;
    #else
    return 0;
    #endif
}

uint32_t reset_pmu(void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    *var=2;
    #else
    return 0;
    #endif
}


uint32_t test_reset (void){
    #ifndef TEST_CI
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    return *var;
    #else
    return 0;
    #endif
}

void print_PMU_events(void){
    printf("-PMU   NUMBER OF EXEC CYCLES         :%d\n", get_cycles_32b()      );
    printf("-PMU   INSTRUCTION COUNTER           :%d\n", get_instr_32b()       ); 
    printf("\n"); 
    printf("-PMU   ICACHE REQ EVENT COUNTER      :%d\n", get_icache_req()      ); 
    printf("-PMU   IMISS EVENT COUNTER           :%d\n", get_imiss()           );
    printf("-PMU   IMISS TIME COUNTER            :%d\n", get_imiss_time()      ); 
    printf("-PMU   ICACHE KILL EVENT COUNTER     :%d\n", get_icache_kill()     ); 
    printf("-PMU   ICACHE KILL TIME  COUNTER     :%d\n", get_ikill_time()      ); 
    printf("-PMU   ICACHE BUSSY TIME COUNTER     :%d\n", get_icache_bussy()    ); 
    printf("-PMU   ITLB MISS COUNTER             :%d\n", get_itlb_miss()       );
    printf("\n"); 
    printf("-PMU   DMISS EVENT COUNTER           :%d\n", get_dmiss()           );
    printf("-PMU   STORE EVENT COUNTER           :%d\n", get_store()           );
    printf("-PMU   LOAD EVENT COUNTER            :%d\n", get_load()            );
    printf("-PMU   DTLB MISS COUNTER             :%d\n", get_dtlb_miss()       );
    printf("\n"); 
    printf("-PMU   BRANCH EVENT COUNTER          :%d\n", get_all_branch()      );
    printf("-PMU   BRANCH TAKEN EVENT COUNTER    :%d\n", get_branch_taken()    );
    //printf("-PMU   BRANCH MISS EVENT COUNTER     :%d\n", get_branch_miss()     );
    printf("\n"); 
    printf("-PMU   STALL BY CSR TIME COUNTER     :%d\n", get_stall_time()      ); 
    //printf("-PMU   STALL BY EXE TIME COUNTER     :%d\n", stall_idPMU           ); 
    //printf("-PMU   STALL BY EXE-MUL TIME COUNTER :%d\n", get_stall_rr()        ); 
    //printf("-PMU   STALL BY EXE-DIV TIME COUNTER :%d\n", stall_exePMU          ); 
    printf("-PMU   STALL BY EXE-MEM TIME COUNTER :%d\n", get_stall_wb()        ); 
    printf("\n");   
    printf("-PMU   IMISS & L2 HIT COUNTER        :%d\n", get_imiss_l2hit()     );
    printf("////////////////////////////////////////////\n");
    printf("-PMU   BRANCH MISSPREDICTIONS        :%d\n", get_branch_miss()     );
    printf("-PMU   STALLS FRONTEND               :%d\n", get_stall_frontend()  );
    printf("-PMU   STALLS BACKEND                :%d\n", get_stall_backend()   );
    printf("-PMU   NUMBER OF LOADS AND STORES    :%d\n", get_load_store()      );
    printf("-PMU   CYCLES LOAD BLOCKED BY STORE  :%d\n", get_load_after_store());
    printf("-PMU   STALL BY DATA DEPENDENCY      :%d\n", get_data_depend()     );
    printf("-PMU   STALL BY STRUCTURAL RISK      :%d\n", get_struct_depend()   );
    printf("-PMU   STALL BY GRADUATION LIST FULL :%d\n", get_grad_list_full()  );
    printf("-PMU   STALL BY FREE LIST EMPTY      :%d\n", get_free_list_empty() );
}


