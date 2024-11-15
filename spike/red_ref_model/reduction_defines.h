#ifndef REDUCTION_DEFINES_H
#define REDUCTION_DEFINES_H

#define vredsum 0
#define vredand 1
#define vredor 2
#define vredxor 3
#define vredminu 4
#define vredmin 5
#define vredmaxu 6
#define vredmax 7

#define vfredsum 1
#define vfredosum 3
#define vfredmin 5
#define vfredmax 7

#define vfwredsum 49
#define vfwredosum 51

#define vwredsumu 48
#define vwredsum 49

#define FRED 1
#define WRED 0
#define RED 2

// rounding modes
#define RNE 0
#define RTZ 1
#define RDN 2
#define RUP 3
#define RMM 4

#define MASK_BIT 25
#define WIDEN_BITS 30
#define FUNCT3 12
#define FUNCT6 26

#define sew8 0
#define sew16 1
#define sew32 2
#define sew64 3

#define Bsew8 1
#define Bsew16 2
#define Bsew32 4
#define Bsew64 8

#endif
