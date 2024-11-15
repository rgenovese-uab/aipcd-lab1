// See LICENSE for license details.

//**************************************************************************
// Median filter bencmark
//--------------------------------------------------------------------------
//
// This benchmark performs a 1D three element median filter. The
// input data (and reference data) should be generated using the
// median_gendata.pl perl script and dumped to a file named
// dataset1.h You should not change anything except the
// HOST_DEBUG and PREALLOCATE macros for your timing run.

#include <sys/types.h>
#include <sys/times.h>

#include "util.h"
#include "median.h"
#include "dataset1.h"
#include "pmu.h"

#define NUMBER_OF_RUNS		10 /* Default number of runs */

int main( int argc, char* argv[] ){
    int Run_Index                       ;
    int Number_Of_Runs = NUMBER_OF_RUNS ;
    int results_data[DATA_SIZE]         ;

    printf("\n   *** MEDIAN BENCHMARK TEST ***\n\n")    ;
    printf("Size of the vector: %d\n",DATA_SIZE)        ;


    // Output the input array
    printArray( "input",  DATA_SIZE, input_data  );
    printArray( "verify", DATA_SIZE, verify_data );

#if PREALLOCATE
    // If needed we preallocate everything in the caches
    median( DATA_SIZE, input_data, results_data );
#endif
  
    reset_pmu();
    enable_PMU_32b();
  
  
    //----------------------------------------------------------------
    for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index){
        median( DATA_SIZE, input_data, results_data );
    }
    //----------------------------------------------------------------
  
    disable_PMU_32b ();  

    // Print out the results
    printArray( "results", DATA_SIZE, results_data );
    
    print_PMU_events();

    // Check the results
    return verify( DATA_SIZE, results_data, verify_data );
}
