// See LICENSE for license details.

// *************************************************************************
// multiply filter bencmark
// -------------------------------------------------------------------------
//
// This benchmark tests the software multiply implemenation. The
// input data (and reference data) should be generated using the
// multiply_gendata.pl perl script and dumped to a file named
// dataset1.h You should not change anything except the
// HOST_DEBUG and VERIFY macros for your timing run.

#include "util.h"
#include "pmu.h"
#include "multiply.h"
#include "dataset1.h"

#define NUMBER_OF_RUNS		10 /* Default number of runs */

int main( int argc, char* argv[] ){
    int Run_Index;
    int Number_Of_Runs = NUMBER_OF_RUNS;
    int i;
    int results_data[DATA_SIZE];

    printf("\n   *** MULTIPLY BENCHMARK TEST ***\n\n");
    printf("Size of the vector:%d\n",DATA_SIZE);

    // Output the input arrays
    printArray( "input1",  DATA_SIZE, input_data1  );
    printArray( "input2",  DATA_SIZE, input_data2  );
    printArray( "verify", DATA_SIZE, verify_data );

#if PREALLOCATE
    for (i = 0; i < DATA_SIZE; i++){
        results_data[i] = multiply( input_data1[i], input_data2[i] );
    }
#endif

    reset_pmu();
    enable_PMU_32b();

//---------------------------------
    for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index){
        for (i = 0; i < DATA_SIZE; i++){
            results_data[i] = multiply( input_data1[i], input_data2[i] );
        }
    }
//---------------------------------

    disable_PMU_32b ();  

    // Print out the results
    printArray( "results", DATA_SIZE, results_data );
    
    print_PMU_events();

    // Check the results
    return verify( DATA_SIZE, results_data, verify_data );
}
