IDIR = ./SoftFloat-3e/source/include
SOFTDIR = ./SoftFloat-3e/build/Linux-x86_64-GCC
CC = g++

CC_FLAGS =  -fPIC -O0 -g -I../softfloat/

all: reduction.o reduction_op.o reduction_log.o

reduction.o: reduction.cc reduction_op.h
	$(CC) $(CC_FLAGS) -c $<

reduction_op.o: reduction_op.cc reduction_types.h reduction_defines.h
	$(CC) $(CC_FLAGS) -c $<

reduction_log.o: reduction_log.cc reduction_types.h
	$(CC) $(CC_FLAGS) -c $<

clean:
	rm *.o
