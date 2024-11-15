#include <machine/rvtimer.h>

#define CSR_CYCLE         0xc00

int main (void)
{
    unsigned long a;
    unsigned long b;
    unsigned volatile count;

    //a = rvtimer64->value;
    asm ("csrr %0,%1" : "=r"(a) : "i"(CSR_CYCLE) : /*no input*/);

    count = 2000;
    while (count > 0) {
        count--;
    }
    asm ("csrr %0,%1" : "=r"(b) : "i"(CSR_CYCLE) : /*no input*/);
    //b = rvtimer64->value;
    if (b-a < 500) exit(1);

    exit(0);  

}
