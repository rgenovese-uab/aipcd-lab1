QUESTAHOME ?= /eda/mentor/2019-20/RHELx86/QUESTA-CORE-PRIME_2019.4/questasim/include/

all: elfloader.so

elfloader.so:
	g++ -fPIC -shared -O3 -g3 -std=c++11 -I$(QUESTAHOME) elfloader.cc -o elfloader.so

clean:
	rm -f elfloader.so
