// See LICENSE for license details.

#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <limits.h>
#include "util.h"

#define SYS_write 64
#define SYS_exit 93
#define SYS_stats 1234

// initialized in crt.S
int have_vec;
extern volatile int tohost;
long cores_jump_address = 0;

extern void asm_set_hyperram_config(unsigned long data);

static long handle_frontend_syscall(long which, long arg0, long arg1, long arg2)
{
  volatile uint64_t magic_mem[8] __attribute__((aligned(64)));
  magic_mem[0] = which;
  magic_mem[1] = arg0;
  magic_mem[2] = arg1;
  magic_mem[3] = arg2;
  char * text = (char *)arg1;
  __sync_synchronize();
  // loop to sent all the data
  for (int i=0; i<arg2; i++){
	// Create pakage
	long pack = *text;
	pack = pack << 8;
	pack |= (SYS_write << 24);
	// Send data
	//asm volatile ("sw %0, tohost, t5" :: "rK"((long)(pack)));
	#ifndef TEST_CI
        write_csr(0x9F0, (long)(pack));
	#endif
	text++;
  }
//  while (swap_csr(mfromhost, 0) == 0);
  return magic_mem[0];
}

// In setStats, we might trap reading uarch-specific counters.
// The trap handler will skip over the instruction and write 0,
// but only if a0 is the destination register.
#define read_csr_safe(reg) ({ register long __tmp asm("a0"); \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

//#define NUM_COUNTERS 18
#define NUM_COUNTERS 2
static long counters[NUM_COUNTERS];
static char* counter_names[NUM_COUNTERS];
static int handle_stats(int enable)
{
  //use csrs to set stats register
  if (enable)
    //asm volatile ("csrrs a0, stats, 1" ::: "a0");
    asm volatile ("csrrs a0, 0xc0, 1" ::: "a0");
  int i = 0;
#define READ_CTR(name) do { \
    while (i >= NUM_COUNTERS) ; \
    long csr = read_csr_safe(name); \
    if (!enable) { csr -= counters[i]; counter_names[i] = #name; } \
    counters[i++] = csr; \
  } while (0)
  //READ_CTR(cycle);   READ_CTR(instret);
  //READ_CTR(uarch0);  READ_CTR(uarch1);  READ_CTR(uarch2);  READ_CTR(uarch3);
  //READ_CTR(uarch4);  READ_CTR(uarch5);  READ_CTR(uarch6);  READ_CTR(uarch7);
  //READ_CTR(uarch8);  READ_CTR(uarch9);  READ_CTR(uarch10); READ_CTR(uarch11);
  //READ_CTR(uarch12); READ_CTR(uarch13); READ_CTR(uarch14); READ_CTR(uarch15);
  READ_CTR(mcycle);
  READ_CTR(minstret);

#undef READ_CTR
  if (!enable)
    //asm volatile ("csrrc a0, stats, 1" ::: "a0");
    asm volatile ("csrrc a0, 0xc0, 1" ::: "a0");
  return 0;
}

void tohost_exit(long code)
{
  //write_csr(mtohost, (code << 1) | 1);
  asm volatile ("li t0, 1");
  asm volatile ("sw t0, tohost, t5");
  write_csr(0x9F0, 1);
  //asm volatile ("csrrw t0, mcycle, t0");
  while (1);
}

long handle_trap(long cause, long epc, long regs[32])
{
  int* csr_insn;
  //asm ("jal %0, 1f; csrr a0, stats; 1:" : "=r"(csr_insn));
  asm ("jal %0, 1f; csrr a0, 0xc0; 1:" : "=r"(csr_insn));
  long sys_ret = 0;

  if (cause == CAUSE_ILLEGAL_INSTRUCTION &&
      (*(int*)epc & *csr_insn) == *csr_insn)
    ;
  else if (cause != CAUSE_USER_ECALL /*TODO this was added to enable the machine option*/&& cause != CAUSE_MACHINE_ECALL)
    tohost_exit(1337);
  else if (regs[17] == SYS_exit)
    tohost_exit(regs[10]);
  else if (regs[17] == SYS_stats)
    sys_ret = handle_stats(regs[10]);
  else
    sys_ret = handle_frontend_syscall(regs[17], regs[10], regs[11], regs[12]);

  regs[10] = sys_ret;
  return epc+4;
}

static long syscall(long num, long arg0, long arg1, long arg2)
{
  register long a7 asm("a7") = num;
  register long a0 asm("a0") = arg0;
  register long a1 asm("a1") = arg1;
  register long a2 asm("a2") = arg2;
  asm volatile ("scall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7));
  return a0;
}

void exit(int code)
{
  syscall(SYS_exit, code, 0, 0);
  while (1);
}

void setStats(int enable)
{
  syscall(SYS_stats, enable, 0, 0);
}

void printstr(const char* s)
{
  syscall(SYS_write, 1, (long)s, strlen(s));
}

void __attribute__((weak)) thread_entry(int cid, int nc)
{
  // multi-threaded programs override this function.
  // for the case of single-threaded programs, only let core 0 proceed.
  while (cid != 0);
}

int __attribute__((weak)) main(int argc, char** argv)
{
  // single-threaded programs override this function.
  printstr("Implement main(), foo!\n");
  return -1;
}

//static void init_tls()
//{
//  register void* thread_pointer asm("tp");
//  extern char _tls_data;
//  extern __thread char _tdata_begin, _tdata_end, _tbss_end;
//  size_t tdata_size = &_tdata_end - &_tdata_begin;
//  memcpy(thread_pointer, &_tls_data, tdata_size);
//  size_t tbss_size = &_tbss_end - &_tdata_end;
//  memset(thread_pointer + tdata_size, 0, tbss_size);
//}

static void init_tls()
{
  register void* thread_pointer asm("tp");
  extern char _tdata_begin, _tdata_end, _tbss_end;
  size_t tdata_size = &_tdata_end - &_tdata_begin;
  memcpy(thread_pointer, &_tdata_begin, tdata_size);
  size_t tbss_size = &_tbss_end - &_tdata_end;
  memset(thread_pointer + tdata_size, 0, tbss_size);
}

void _init(int cid, int nc)
{
  init_tls();
  thread_entry(cid, nc);

  // only single-threaded programs should ever get here.
  int ret = main(0, 0);

  char buf[NUM_COUNTERS * 32] __attribute__((aligned(64)));
  char* pbuf = buf;
  for (int i = 0; i < NUM_COUNTERS; i++)
    if (counters[i])
      pbuf += sprintf(pbuf, "%s = %d\n", counter_names[i], counters[i]);
  if (pbuf != buf)
    printstr(buf);

  exit(ret);
}

// It wakes up the hardware cores to start execution
void _cores_fork_(int nc)
{
/*
  // Copies the content of the return address for the cores
  __asm__ __volatile__ (
	"sd ra, %[fork]\n\t"
	: [fork] "+A" (cores_jump_address)
	: // no input list
	: // no clobber list
  );
*/
}

// Function to put back the cores into the idle section
void _core_idle_(int cid)
{
  int register addre;
  cores_jump_address = 0;
  if (cid!=0){
    __asm__ __volatile__ (
	  "la %[addr], _idle_back_\n\t"
	  "jalr %[addr]"
	  : [addr] "+r" (addre)
	  : // no input list
	  : // no clobber list
    );

  }
}

int get_core_count()
{
	return tohost;
}

int get_core_id(void){
	register int id = 0;
	// subroutine to read the hardware id
	__asm__ __volatile__ (
		"nop\n\t"
		"csrr %[output], mhartid\n\t"
	: [output] "=r" (id)
	: // no input list
	: // no clobber list
	);

	return id;
}

// Function to mantain the cores waiting for the core 0 to wake them up
void _idle_section_()
{
  register int function_address = 0;
  while(1)
  {
    while (function_address == 0)
    {
      __asm__ __volatile__ (
  	    "amoadd.d %[addr], zero, %[tty] \n\t"
	    : [addr] "+r" (function_address), [tty] "+A" (cores_jump_address)
	    : // no input list
  	    : // no clobber list
      );
    }
    // This section sets the stack pointer for enough space to store all the registers plus space to store the recovery pointer and jumps to execution
    __asm__ __volatile__ (
	  "addi sp, sp, -272\n\t"
	  "la ra, _idle_back_\n\t"
	  "sd ra, 264(sp)\n\t"
	  "addi s0, sp, 256\n\t"
	  "jalr %[jaddr]\n\t"
	  "_idle_back_:\n\t"
	  "addi sp, sp, 272\n\t"
	  "mv s0, sp\n\t"
	  : [jaddr] "+r" (function_address)
	  : // no input list
	  : // no clobber list
    );
  }

}

// Function used as second init for those test were the core0 initializes and the other cores wait for its fork signal
void _init_(int cid, int nc)
{
  // Initialize all the threads memory
  init_tls();
  if (cid!=0)
	_idle_section_();

  // Call the constructor of the function main
  int ret = main(0, 0);

  exit(ret);
}

#undef putchar
int putchar(int ch)
{
  static __thread char buf[64] __attribute__((aligned(64)));
  static __thread int buflen = 0;

  buf[buflen++] = ch;

  if (ch == '\n' || buflen == sizeof(buf))
  {
    syscall(SYS_write, 1, (long)buf, buflen);
    buflen = 0;
  }

  return 0;
}

void printhex(uint64_t x)
{
  char str[17];
  int i;
  for (i = 0; i < 16; i++)
  {
    str[15-i] = (x & 0xF) + ((x & 0xF) < 10 ? '0' : 'a'-10);
    x >>= 4;
  }
  str[16] = 0;

  printstr(str);
}

static inline void printnum(void (*putch)(int, void**), void **putdat,
                    unsigned long long num, unsigned base, int width, int padc)
{
  unsigned digs[sizeof(num)*CHAR_BIT];
  int pos = 0;

  while (1)
  {
    digs[pos++] = num % base;
    if (num < base)
      break;
    num /= base;
  }

  while (width-- > pos)
    putch(padc, putdat);

  while (pos-- > 0)
    putch(digs[pos] + (digs[pos] >= 10 ? 'a' - 10 : '0'), putdat);
}

static unsigned long long getuint(va_list *ap, int lflag)
{
  if (lflag >= 2)
    return va_arg(*ap, unsigned long long);
  else if (lflag)
    return va_arg(*ap, unsigned long);
  else
    return va_arg(*ap, unsigned int);
}

static long long getint(va_list *ap, int lflag)
{
  if (lflag >= 2)
    return va_arg(*ap, long long);
  else if (lflag)
    return va_arg(*ap, long);
  else
    return va_arg(*ap, int);
}

static void vprintfmt(void (*putch)(int, void**), void **putdat, const char *fmt, va_list ap)
{
  register const char* p;
  const char* last_fmt;
  register int ch, err;
  unsigned long long num;
  int base, lflag, width, precision, altflag;
  char padc;

  while (1) {
    while ((ch = *(unsigned char *) fmt) != '%') {
      if (ch == '\0')
        return;
      fmt++;
      putch(ch, putdat);
    }
    fmt++;

    // Process a %-escape sequence
    last_fmt = fmt;
    padc = ' ';
    width = -1;
    precision = -1;
    lflag = 0;
    altflag = 0;
  reswitch:
    switch (ch = *(unsigned char *) fmt++) {

    // flag to pad on the right
    case '-':
      padc = '-';
      goto reswitch;
      
    // flag to pad with 0's instead of spaces
    case '0':
      padc = '0';
      goto reswitch;

    // width field
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      for (precision = 0; ; ++fmt) {
        precision = precision * 10 + ch - '0';
        ch = *fmt;
        if (ch < '0' || ch > '9')
          break;
      }
      goto process_precision;

    case '*':
      precision = va_arg(ap, int);
      goto process_precision;

    case '.':
      if (width < 0)
        width = 0;
      goto reswitch;

    case '#':
      altflag = 1;
      goto reswitch;

    process_precision:
      if (width < 0)
        width = precision, precision = -1;
      goto reswitch;

    // long flag (doubled for long long)
    case 'l':
      lflag++;
      goto reswitch;

    // character
    case 'c':
      putch(va_arg(ap, int), putdat);
      break;

    // string
    case 's':
      if ((p = va_arg(ap, char *)) == NULL)
        p = "(null)";
      if (width > 0 && padc != '-')
        for (width -= strnlen(p, precision); width > 0; width--)
          putch(padc, putdat);
      for (; (ch = *p) != '\0' && (precision < 0 || --precision >= 0); width--) {
        putch(ch, putdat);
        p++;
      }
      for (; width > 0; width--)
        putch(' ', putdat);
      break;

    // (signed) decimal
    case 'd':
      num = getint(&ap, lflag);
      if ((long long) num < 0) {
        putch('-', putdat);
        num = -(long long) num;
      }
      base = 10;
      goto signed_number;

    // unsigned decimal
    case 'u':
      base = 10;
      goto unsigned_number;

    // (unsigned) octal
    case 'o':
      // should do something with padding so it's always 3 octits
      base = 8;
      goto unsigned_number;

    // pointer
    case 'p':
      static_assert(sizeof(long) == sizeof(void*));
      lflag = 1;
      putch('0', putdat);
      putch('x', putdat);
      /* fall through to 'x' */

    // (unsigned) hexadecimal
    case 'x':
      base = 16;
    unsigned_number:
      num = getuint(&ap, lflag);
    signed_number:
      printnum(putch, putdat, num, base, width, padc);
      break;

    // escaped '%' character
    case '%':
      putch(ch, putdat);
      break;
      
    // unrecognized escape sequence - just print it literally
    default:
      putch('%', putdat);
      fmt = last_fmt;
      break;
    }
  }
}

int printf(const char* fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);

  vprintfmt((void*)putchar, 0, fmt, ap);

  va_end(ap);
  return 0; // incorrect return value, but who cares, anyway?
}

int sprintf(char* str, const char* fmt, ...)
{
  va_list ap;
  char* str0 = str;
  va_start(ap, fmt);

  void sprintf_putch(int ch, void** data)
  {
    char** pstr = (char**)data;
    **pstr = ch;
    (*pstr)++;
  }

  vprintfmt(sprintf_putch, (void**)&str, fmt, ap);
  *str = 0;

  va_end(ap);
  return str - str0;
}

//---
//---
void* memcpy(void* dest, const void* src, size_t len)
{
  if ((((uintptr_t)dest | (uintptr_t)src | len) & (sizeof(uintptr_t)-1)) == 0) {
    const uintptr_t* s = src;
    uintptr_t *d = dest;
    while (d < (uintptr_t*)(dest + len))
      *d++ = *s++;
  } else {
    const char* s = src;
    char *d = dest;
    while (d < (char*)(dest + len))
      *d++ = *s++;
  }
  return dest;
}

void* memset(void* dest, int byte, size_t len)
{
  if ((((uintptr_t)dest | len) & (sizeof(uintptr_t)-1)) == 0) {
    uintptr_t word = byte & 0xFF;
    word |= word << 8;
    word |= word << 16;
    word |= word << 16 << 16;

    uintptr_t *d = dest;
    while (d < (uintptr_t*)(dest + len))
      *d++ = word;
  } else {
    char *d = dest;
    while (d < (char*)(dest + len))
      *d++ = byte;
  }
  return dest;
}

size_t strlen(const char *s)
{
  const char *p = s;
  while (*p)
    p++;
  return p - s;
}

size_t strnlen(const char *s, size_t n)
{
  const char *p = s;
  while (n-- && *p)
    p++;
  return p - s;
}



