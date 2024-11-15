// See LICENSE for license details.

#ifndef __UTIL_H
#define __UTIL_H

extern void setStats(int enable);

#include <stdint.h>

#define static_assert(cond) switch(0) { case 0: case !!(long)(cond): ; }

//#define NUMBER_OF_RUNS		10 /* Default number of runs */


// Added functions to messure the time
#ifdef TIME

#define CLOCK_TYPE "time()"
#undef HZ
#define HZ	(1) /* time() returns time in seconds */
extern long     time(); /* see library function "time"  */
#define Too_Small_Time 2 /* Measurements should last at least 2 seconds */
#define Start_Timer() Begin_Time = time ( (long *) 0)
#define Stop_Timer()  End_Time   = time ( (long *) 0)

#else

#ifdef MSC_CLOCK /* Use Microsoft C hi-res clock */

#undef HZ
#undef TIMES
#include <time.h>
#define HZ	CLK_TCK
#define CLOCK_TYPE "MSC clock()"
extern clock_t	clock();
#define Too_Small_Time (2*HZ)
#define Start_Timer() Begin_Time = clock()
#define Stop_Timer()  End_Time   = clock()

#elif defined(__riscv)

#define HZ 1000000
#define Too_Small_Time 1
#define CLOCK_TYPE "rdcycle()"
#define Start_Timer() Begin_Time = rdcycle()
#define Stop_Timer() End_Time = rdcycle()

#else
                /* Use times(2) time function unless    */
                /* explicitly defined otherwise         */
#define CLOCK_TYPE "times()"
#include <sys/types.h>
#include <sys/times.h>
#ifndef HZ	/* Added by SP 900619 */
#include <sys/param.h> /* If your system doesn't have this, use -DHZ=xxx */
#else
	*** You must define HZ!!! ***
#endif /* HZ */
#ifndef PASS2
struct tms      time_info;
#endif
/*extern  int     times ();*/
                /* see library function "times" */
#define Too_Small_Time (2*HZ)
                /* Measurements should last at least about 2 seconds */
#define Start_Timer() times(&time_info); Begin_Time=(long)time_info.tms_utime
#define Stop_Timer()  times(&time_info); End_Time = (long)time_info.tms_utime

#endif /* MSC_CLOCK */
#endif /* TIME */

#define Mic_secs_Per_Second     1000000


static int verify(int n, const volatile int* test, const int* verify)
{
  int i;
  // Unrolled for faster verification
  for (i = 0; i < n/2*2; i+=2)
  {
    int t0 = test[i], t1 = test[i+1];
    int v0 = verify[i], v1 = verify[i+1];
    if (t0 != v0) return i+1;
    if (t1 != v1) return i+2;
  }
  if (n % 2 != 0 && test[n-1] != verify[n-1])
    return n;
  return 0;
}

static int verifyDouble(int n, const volatile double* test, const double* verify)
{
  int i;
  // Unrolled for faster verification
  for (i = 0; i < n/2*2; i+=2)
  {
    double t0 = test[i], t1 = test[i+1];
    double v0 = verify[i], v1 = verify[i+1];
    int eq1 = t0 == v0, eq2 = t1 == v1;
    if (!(eq1 & eq2)) return i+1+eq1;
  }
  if (n % 2 != 0 && test[n-1] != verify[n-1])
    return n;
  return 0;
}

static void __attribute__((noinline)) barrier(int ncores)
{
  static volatile int sense;
  static volatile int count;
  static __thread int threadsense;

  __sync_synchronize();

  threadsense = !threadsense;
  if (__sync_fetch_and_add(&count, 1) == ncores-1)
  {
    count = 0;
    sense = threadsense;
  }
  else while(sense != threadsense)
    ;

  __sync_synchronize();
}

static uint64_t lfsr(uint64_t x)
{
  uint64_t bit = (x ^ (x >> 1)) & 1;
  return (x >> 1) | (bit << 62);
}

static uintptr_t insn_len(uintptr_t pc)
{
  return (*(unsigned short*)pc & 3) ? 4 : 2;
}

static void printArray(const char name[], int n, const int arr[])
{
#if HOST_DEBUG
  int i;
  printf( " %10s :", name );
  for ( i = 0; i < n; i++ )
    printf( " %3d ", arr[i] );
  printf( "\n" );
#endif
}

#ifdef __riscv
#include "encoding.h"
#endif

#define stringify_1(s) #s
#define stringify(s) stringify_1(s)
#define stats(code, iter) do { \
    unsigned long _c = -read_csr(mcycle), _i = -read_csr(minstret); \
    code; \
    _c += read_csr(mcycle), _i += read_csr(minstret); \
    if (cid == 0) \
      printf("\n%s: %ld cycles, %ld.%ld cycles/iter, %ld.%ld CPI\n", \
             stringify(code), _c, _c/iter, 10*_c/iter%10, _c/_i, 10*_c/_i%10); \
  } while(0)

#endif //__UTIL_H
