/*----------------------------------------------------------------------*
 * To make this program compile under our assumed embedded environment,
 * we had to make several changes:
 * - Declare all functions in ANSI style, not K&R.
 *   this includes adding return types in all cases!
 * - Declare function prototypes
 * - Disable all output
 * - Disable all UNIX-style includes
 *
 * This is a program that was developed from mm.c to matmult.c by
 * Thomas Lundqvist at Chalmers.
 *----------------------------------------------------------------------*/


#include <sys/types.h>
#include <sys/times.h>
#include "util.h"

#include "pmu.h" //--PMU Neie*Leyva 

/*
 * MATRIX MULTIPLICATION BENCHMARK PROGRAM:
 * This program multiplies 2 square matrices resulting in a 3rd
 * matrix. It tests a compiler's speed in handling multidimensional
 * arrays and simple arithmetic.
 */

#define UPPERLIMIT 64 

typedef int matrix [UPPERLIMIT*UPPERLIMIT];

int Seed;
matrix ArrayA, ArrayB, ResultArray;

void Multiply(matrix A, matrix B, matrix Res);
void InitSeed(void);
void Test(matrix A, matrix B, matrix Res);
void Initialize(matrix Array);
int RandomInteger(void);
void PrintMatrix(matrix A);

int main() {
   unsigned long cycles1, cycles2, instr2, instr1;
   
    InitSeed();

    printf("\n   *** MATRIX MULTIPLICATION BENCHMARK TEST ***\n\n");
    printf("RESULTS OF THE TEST:\n");
   

    reset_pmu();
    enable_PMU_32b();


    //--------------------------------------------------
    Test(ArrayA, ArrayB, ResultArray);
    //--------------------------------------------------

    disable_PMU_32b ();  

    printf("\nArrayA:\n");
    PrintMatrix(ArrayA);
    printf("ArrayB:\n");
    PrintMatrix(ArrayB);
    printf("ResultArray:\n");
    PrintMatrix(ResultArray);

    print_PMU_events();
    
}


void PrintMatrix(matrix X)
{  
   for (int i = 0; i < UPPERLIMIT; ++i)
   {
    printf("|");
     for (int j = 0; j < UPPERLIMIT; ++j)
     {
       printf("%d   ",X[i*UPPERLIMIT+j] );
     }
     printf("|\n");
   }
   printf("\n");
}

void InitSeed(void)
/*
 * Initializes the seed used in the random number generator.
 */
{
  /* ***UPPSALA WCET***:
     changed Thomas Ls code to something simpler.
   Seed = KNOWN_VALUE - 1; */
  Seed = 0;
}


void Test(matrix A, matrix B, matrix Res)
/*
 * Runs a multiplication test on an array.  Calculates and prints the
 * time it takes to multiply the matrices.
 */
{
   long StartTime, StopTime;
   long TotalTime;

   Initialize(A);
   Initialize(B);

   Multiply(A, B, Res);
}


void Initialize(matrix Array)
/*
 * Intializes the given array with random integers.
 */
{
   int OuterIndex, InnerIndex;

   for (OuterIndex = 0; OuterIndex < UPPERLIMIT; OuterIndex++)
      for (InnerIndex = 0; InnerIndex < UPPERLIMIT; InnerIndex++)
         Array[OuterIndex*UPPERLIMIT+InnerIndex] = 10;
}


int RandomInteger(void)
/*
 * Generates random integers between 0 and 8095
 */
{
   Seed = ((Seed * 133) + 81) % 8095;
   return (Seed);
}

void Multiply(matrix A, matrix B, matrix Res)
/*
 * Multiplies arrays A and B and stores the result in ResultArray.
 */
{
   register int Outer, Inner, Index;

   for (Outer = 0; Outer < UPPERLIMIT; Outer++)
      for (Inner = 0; Inner < UPPERLIMIT; Inner++)
         {
         int sum = 0;
         for (Index = 0; Index < UPPERLIMIT; Index+=2){
            sum += A[Outer*UPPERLIMIT+Index] * B[Index*UPPERLIMIT+Inner];
            sum += A[Outer*UPPERLIMIT+Index+1] * B[(Index+1)*UPPERLIMIT+Inner];
	      }
         Res [Outer*UPPERLIMIT+Inner] = sum;
      }
}
