#include <sys/types.h>
#include <sys/times.h>

#include "util.h"
#include "pmu.h"


int main(){
    
    int error_code = 0;
    int a,b,c; 
    a = 2;
    b = 3;

    uint32_t cycles           ;
    uint32_t test_reset_pmu   ;
    uint32_t test_enable_pmu  ;
    uint32_t test_disable_pmu ;
    
    reset_pmu();
    test_reset_pmu = test_reset();
    if (test_reset_pmu != 2) error_code = 1;

    enable_PMU_32b();
    test_enable_pmu = test_reset();
    if (test_enable_pmu != 1) error_code = 2;

    //---------------------------------------------
    
    disable_PMU_32b ();
    
    print_PMU_events();
    
    printf("\nSuccessful!!\n\n");
    
    cycles = get_cycles_32b()   ; 
    if (cycles == 0) error_code = 4;


    // not necessary
    // tohost_exit(error_code); 
    return 0;
}


