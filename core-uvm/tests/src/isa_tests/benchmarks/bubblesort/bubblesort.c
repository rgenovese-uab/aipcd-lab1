#include <sys/types.h>
#include <sys/times.h>

#include "util.h"
#include "dataset1.h"

#include "pmu.h"  

int main (void)  {
    unsigned long cycles1, cycles2, instr2, instr1;
    int i,j,k;          
    unsigned long aux;

    printf("\n   *** BUBBLE SORT BENCHMARK TEST ***\n\n");
    printf("Size of the vector:%d\n",DATA_SIZE);


    reset_pmu();
    enable_PMU_32b();


//----------------------------------------------------------
    for (i=0;i<DATA_SIZE;i++) { 
        for (j=0;j<DATA_SIZE-1;j++) { 
            if (input_data[j]>=input_data[j+1]) { 
                aux=input_data[j]; 
			    input_data[j]=input_data[j+1]; 
			    input_data[j+1]=aux; 
            } 
        } 
    } 
//----------------------------------------------------------
    
    disable_PMU_32b ();  
                    
	int error=0;
                
	for (i=0;i<DATA_SIZE;i++) { 
        if (input_data[i] != verify_data[i]){
            error = 1;
            printf("The program failed in element %d ,input_data %d , verify_data %d \n", 
                    i,input_data[i] ,verify_data[i]);
			return error;
		}
	}
            
    printf("Successful\n\n");

    print_PMU_events(); 

    
return error; 
} 
