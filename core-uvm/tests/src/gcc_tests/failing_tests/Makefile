CC=riscv64-unknown-elf-gcc
AR=riscv64-unknown-elf-ar

LIBDIR=../libs

CFLAGS=-march=rv64imaf -mabi=lp64f -static -mcmodel=medany
LDFLAGS=-nostartfiles -nostdlib -T ../link.ld -L$(LIBDIR) -lmylib -lc -Xlinker --noinhibit-exec

SOURCES=$(wildcard *.c)
OBJDIR=build
OBJ=$(patsubst %.c, $(OBJDIR)/%.x, $(SOURCES))

all: create_lib $(LIBDIR)/entry.o $(OBJ)

mylib.o:
	$(CC) -fPIC -c $(LIBDIR)/mylib.S -march=rv64imaf -mabi=lp64f -o $(LIBDIR)/mylib.o

create_lib: mylib.o
	$(AR) rcs $(LIBDIR)/libmylib.a $(LIBDIR)/mylib.o

$(LIBDIR)/entry.o:
	$(CC) -fPIC -nostartfiles -nostdlib -static -c $(LIBDIR)/entry.S -march=rv64imaf -o $@

$(OBJDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $^ -o $@

$(OBJDIR)/%.x: $(LIBDIR)/entry.o $(OBJDIR)/%.o
	$(CC) $(CFLAGS) $< $(LDFLAGS) $(LIBDIR)/entry.o -o $@

.PHONY: clean
clean:
	rm -f ../libs/*.o
	rm -f ../libs/*.a
	rm -f ../entry.o
	rm -f build/*