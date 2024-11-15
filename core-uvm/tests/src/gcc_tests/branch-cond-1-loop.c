#include <stdio.h>
#include <stdlib.h>

int main();

volatile int i;
int br1;

 main()
{  br1=0;
    for (i = 0; i < 15; i++)
     { printf("hello %d t\n", i);
       br1++;
      }
    printf("br1 %d\n", br1);
    exit(0);
}
