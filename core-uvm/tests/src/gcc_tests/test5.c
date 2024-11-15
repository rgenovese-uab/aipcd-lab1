#include <stdio.h>
#include <stdlib.h>

int main();
static int fact(int n);

volatile int x[32];
volatile int i;

static int fact(int n);

int __attribute((noinline, optimize("-fno-ipa-cp","-fno-tree-copy-prop"))) main()
{
    int y, j;
    int z = 2;
    asm volatile ("" ::: "memory");
    while(z>0)
    {
      for (i = 0; i < 10; i++)
        {
         printf("hello this is a very long story i=%d z=%d \n", i, z);
         if (z>1)
           printf("hello i=%d z=%d \n", i, z);
         else
           printf("hello z=%d i=%d \n", z, i);
         }
      i = 0;
      y = fact(8);
      --z;
    }

    for (j = 0; j < 8; j++)
        y = y + x[j];
    x[0] = y;

    exit(0);
}

static int __attribute((noinline)) fact(int n)
{
    x[i++] = n;
    return n > 1 ? n * fact(n-1) : 1;
}
