#include <sys/types.h>
#include <sys/times.h>
#include "util.h"

#include "pmu.h"  

static int fib(int i) {return (i>1) ? fib(i-1) + fib(i-2) : i;}

int main() {
    unsigned long cycles1, cycles2, instr2, instr1;
    int aux,i,j;
    int result; 
    
    int n=25;
    int A[25];

    printf("\n   *** FIBONACCI BENCHMARK TEST ***\n\n");
    printf("RESULTS OF THE TEST:\n");
    printf("N = %d \n", n);

    reset_pmu();
    enable_PMU_32b();

    //--------------------------------------------------
    for(j=0; j<n; j++) {
        result=fib(j);
        A[j] = result;
    }
    //--------------------------------------------------
    
    disable_PMU_32b ();

    printf("\nFibonacci sequence: \n");
	
    for (i=0;i<n;i++) { 
	    printf("%d ",A[i]);
	}
	printf("\n");

    print_PMU_events();

} 
