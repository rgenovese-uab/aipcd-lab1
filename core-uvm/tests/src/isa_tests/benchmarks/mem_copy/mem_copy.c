#include <sys/types.h>
#include "util.h"

#include "pmu.h"

#define NumI 10000
uint32_t a[NumI], b[NumI];


int main(int argc, char* argv[]) {

    printf("\n   *** Mem Copy  BENCHMARK TEST ***\n\n");
    printf("N = %d \n", NumI);

    for(uint32_t i = 0; i < NumI; i++){ a[i] = 5; }

    reset_pmu();
    enable_PMU_32b();

    for(uint32_t i = 0; i < NumI; i++){ b[i] = a[i]; }

    disable_PMU_32b ();

    print_PMU_events();

}

