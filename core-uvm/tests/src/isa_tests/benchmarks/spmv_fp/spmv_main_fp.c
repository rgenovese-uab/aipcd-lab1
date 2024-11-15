// See LICENSE for license details.

//**************************************************************************
// Double-precision general matrix multiplication benchmark
//--------------------------------------------------------------------------

#include "util.h"
#include "pmu.h"

//--------------------------------------------------------------------------
#include "dataset1.h"

void spmv_fp(int r, const double* val, const int* idx, const double* x,
          const int* ptr, double* y)
{
  for (int i = 0; i < r; i++)
  {
    int k;
    double yi0 = 0, yi1 = 0, yi2 = 0, yi3 = 0;
    for (k = ptr[i]; k < ptr[i+1]-3; k+=4)
    {
      yi0 += val[k+0]*x[idx[k+0]];
      yi1 += val[k+1]*x[idx[k+1]];
      yi2 += val[k+2]*x[idx[k+2]];
      yi3 += val[k+3]*x[idx[k+3]];
    }
    for ( ; k < ptr[i+1]; k++)
    {
      yi0 += val[k]*x[idx[k]];
    }
    y[i] = (yi0+yi1)+(yi2+yi3);
  }
}

//--------------------------------------------------------------------------
// Main
//--------------------------------------------------------------------------

int main( int argc, char* argv[] ) {
    double y[R];

    printf("\n   *** SPARSE MATRIX-VECTOR MULTIPLY DOUBLE (SPMV) BENCHMARK TEST ***\n\n");
    printf("Size of the vector: %d \n",NNZ);

#if PREALLOCATE
    spmv_fp(R, val, idx, x, ptr, y);
#endif

    reset_pmu();
    enable_PMU_32b();
    
    //-----------------
    spmv_fp(R, val, idx, x, ptr, y);
    //-----------------

    disable_PMU_32b ();  

    print_PMU_events();

    // Check the results
    return verifyDouble(R, y, verify_data);

}
