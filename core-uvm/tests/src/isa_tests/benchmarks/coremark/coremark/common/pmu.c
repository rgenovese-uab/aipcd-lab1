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


void read_test_loop(uint32_t entry, uint32_t exit,uint32_t aligment){
    volatile uint32_t *var;
    volatile uint32_t reader;
    printf("\n *** Memory dump***\n\n");
    for(uint32_t i=entry;i<exit+4;i=i+aligment){
        var=(uint32_t*)(i);
        reader=*var;
        printf("addres:%x \n",i);
        printf("value :%d \n",reader);
    }
   printf("\n *** END DUMP ***\n\n");
}
void search_loop(uint32_t entry, uint32_t exit,uint32_t aligment, uint32_t key){
    volatile uint32_t *var;
    volatile uint32_t reader;
    printf("\n *** Memory dump***\n\n");
    for(uint32_t i=entry;i<exit+4;i=i+aligment){
        var=(uint32_t*)(i);
        reader=*var;
        if (reader==key){
        printf("addres:%x \n",i);
        printf("value :%d \n",reader);
            i=exit;
        }

    }
   printf("\n *** END DUMP ***\n\n");
}

void enable_PMU_32b (void){
    uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    *var=1;
}

void disable_PMU_32b (void){
    uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    *var=0;
}

uint32_t get_cycles_32b (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CYCLES*4);
    #ifdef DEGUB_PMU
    printf("CYCLES\n");
    printf("value :%d \n",*var);
    printf("Is the CYCLES counter at address :%x \n",var);
    #endif
    return *var;
}

uint32_t get_imiss (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IMISS*4);
    return *var;
}

uint32_t get_dmiss (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+DMISS*4);
    return *var;
}

uint32_t get_itlb_miss (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+ITLBMISS*4);
    return *var;
}

uint32_t get_dtlb_miss (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+DTLBMISS*4);
    return *var;
}

uint32_t get_store (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STORES*4);
    return *var;
}

uint32_t get_load (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+LOAD*4);
    return *var;
}

uint32_t get_branch_miss (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+BRANCH_MISS*4);
    return *var;
}

uint32_t get_all_branch (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IS_BRANCH*4);
    return *var;
}

uint32_t get_branch_taken (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+BRANCH_TAKEN*4);
    return *var;
}

uint32_t get_icache_req (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IREQ*4);
    return *var;
}

uint32_t get_icache_kill (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IKILL*4);
    return *var;
}

uint32_t get_stall_time (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALL_TIME*4);
    return *var;
}

uint32_t get_stall_id (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLID*4);
    return *var;
}

uint32_t get_stall_frontend (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLID*4);
    return *var;
}

uint32_t get_stall_rr (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLRR*4);
    return *var;
}

uint32_t get_load_after_store (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLRR*4);
    return *var;
}

uint32_t get_stall_exe (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLEXE*4);
    return *var;
}

uint32_t get_stall_backend (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLEXE*4);
    return *var;
}

uint32_t get_stall_wb (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STALLWB*4);
    return *var;
}

uint32_t get_imiss_l2hit (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IMISS_L2HIT*4);
    return *var;
}

uint32_t get_imiss_time (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IMISS_TIME*4);
    return *var;
}

uint32_t get_icache_bussy (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+ICACHE_BUSSY*4);
    return *var;
}

uint32_t get_ikill_time (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+IKILL_TIME*4);
    return *var;
}

uint32_t get_load_store (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+LOAD_STORE*4);
    return *var;
}

uint32_t get_data_depend (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+DATA_DEPEND*4);
    return *var;
}

uint32_t get_struct_depend (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+STRUCT_DEPEND*4);
    return *var;
}

uint32_t get_grad_list_full (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+GRAD_LIST_FULL*4);
    return *var;
}

uint32_t get_free_list_empty (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+FREE_LIST_EMPTY*4);
    return *var;
}

uint32_t get_instr_32b (void){
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+INSTR*4);
    #ifdef DEGUB_PMU
    printf("INSTRUCTIONS\n");
    printf("value :%d \n",*var);
    printf("Is the CYCLES counter at address :%x \n",var);
    #endif
    return *var;
}

uint32_t reset_pmu(void){
    //reset counters 
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    *var=2;
}

uint32_t get_cycles(void){
    //reset counters 
    volatile uint32_t *var;
    var=(uint32_t*)(PMU_BASE+CONG_REG_1_OFFSET);
    *var=2;
}

uint32_t test_pmu(void){
    //enable PMU 
    read_test_loop(PMU_BASE,PMU_BASE+MASK3,4);
    printf("\n ***Reset***\n\n");
    reset_pmu();
    read_test_loop(PMU_BASE,PMU_BASE+MASK3,4);
    printf("\n ***Enable***\n\n");
    enable_PMU_32b();
    read_test_loop(PMU_BASE,PMU_BASE+MASK3,4);
    printf("\n ***Disable***\n\n");
    disable_PMU_32b ();
    read_test_loop(PMU_BASE,PMU_BASE+MASK3,4);
    return(0);
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




