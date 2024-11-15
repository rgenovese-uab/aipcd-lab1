// Very very basic test for divider unit
#include <stdio.h>
#include <stdlib.h>

typedef struct T {
    int d;
    int z;
    int q;
    int r
} T;

T tests[] = {
    //  Divisor	  Divider   Quotient  Remainder
    {   100000,      100,       1000,        0 },
    {   100099,      100,       1000,       99 }
};

// volatile to ensure that we really do the test (otherwise just optimized away0
void test(volatile T test)
{
    if (test.d / test.z != test.q) abort();
    if (test.d % test.z != test.r) abort();
}

int main()
{
    int i;
    for (i = 0; i < sizeof(tests)/sizeof(T); i++) {
	test(tests[i]);
    }
    return 0;
}
