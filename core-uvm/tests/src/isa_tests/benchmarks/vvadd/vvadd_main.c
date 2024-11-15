// See LICENSE for license details.

//**************************************************************************
// Vector-vector add benchmark
//--------------------------------------------------------------------------
//
// This benchmark uses adds to vectors and writes the results to a
// third vector. The input data (and reference data) should be
// generated using the vvadd_gendata.pl perl script and dumped
// to a file named dataset1.h The smips-gcc toolchain does not
// support system calls so printf's can only be used on a host system,
// not on the smips processor simulator itself. You should not change
// anything except the HOST_DEBUG and PREALLOCATE macros for your timing
// runs.
 
#include "util.h"
#include "pmu.h"
#include "dataset1-large.h"

#define NUMBER_OF_RUNS		10 /* Default number of runs */

//--------------------------------------------------------------------------
// vvadd function

void vvadd( int n, int a[], int b[], int c[] )
{
  int i;
  for ( i = 0; i < n; i+=2){
    c[i] = a[i] + b[i];
    c[i+1] = a[i+1] + b[i+1];
  }
}


//--------------------------------------------------------------------------
// Main
//--------------------------------------------------------------------------

int main( int argc, char* argv[] ){
    int Run_Index;
    int Number_Of_Runs = NUMBER_OF_RUNS;
    int results_data[DATA_SIZE];

    printf("\n   *** VVADD BENCHMARK TEST ***\n\n");
    printf("Size of the vector:%d\n",DATA_SIZE);
    
    // Output the input array
    printArray( "input1", DATA_SIZE, input1_data );
    printArray( "input2", DATA_SIZE, input2_data );
    printArray( "verify", DATA_SIZE, verify_data );

#if PREALLOCATE
    // If needed we preallocate everything in the caches
    vvadd( DATA_SIZE, input1_data, input2_data, results_data );
#endif

    reset_pmu();
    enable_PMU_32b();

    //----------------------------------------
    for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index){
        vvadd( DATA_SIZE, input1_data, input2_data, results_data );
    }
    //----------------------------------------

    disable_PMU_32b ();  

    // Print out the results
    printArray( "results", DATA_SIZE, results_data );

    print_PMU_events();

    // Check the results
    return verify( DATA_SIZE, results_data, verify_data );
}
