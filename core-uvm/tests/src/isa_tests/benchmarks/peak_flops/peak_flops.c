#include <sys/types.h>
#include "util.h"

#include "pmu.h"

extern void asm_basic_loop_arith(int);

int main(int argc, char* argv[]) {

    uint32_t Iterations = 1000;

    printf("\n   *** MAX FLOPS BENCHMARK TEST ***\n\n");
    printf("N = %d \n", Iterations);

    reset_pmu();
    enable_PMU_32b();

    asm_basic_loop_arith(Iterations);

    disable_PMU_32b ();

    print_PMU_events();

}
