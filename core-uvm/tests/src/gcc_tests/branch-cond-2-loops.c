#include <stdio.h>
#include <stdlib.h>

int main();

volatile int i;
volatile int j;
int br1;
int br2;

 main()
{  br1=0; br2=0;
    for (i = 0; i < 20; i++)
     { br1++;

        for (j = 0; j < 4; j++)
	br2++;
      }
    printf("br1 %d\n", br1);
    printf("br2 %d\n", br2);
    exit(0);
}
