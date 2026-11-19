/*
 * Minimal newlib system-call layer for the GCC build of the Spectra firmware.
 *
 * All measurement output goes through the ADI UART driver (test_print() in
 * OpenEIT.c).  printf() is only used by the PASS/FAIL/PERF helpers in
 * test_common.c, which under IAR went to the debugger's terminal window;
 * here that output is discarded.
 */
#include <errno.h>
#include <stddef.h>
#include <sys/stat.h>

extern char _heap_start;   /* from gcc/ADuCM350.ld */
extern char _heap_end;

void *_sbrk(ptrdiff_t incr)
{
    static char *brk = &_heap_start;
    char *prev = brk;

    if (brk + incr > &_heap_end) {
        errno = ENOMEM;
        return (void *)-1;
    }
    brk += incr;
    return prev;
}

int _write(int fd, const char *buf, int len) { (void)fd; (void)buf; return len; }
int _read(int fd, char *buf, int len)        { (void)fd; (void)buf; (void)len; return 0; }
int _close(int fd)                           { (void)fd; return -1; }
int _lseek(int fd, int off, int whence)      { (void)fd; (void)off; (void)whence; return 0; }
int _isatty(int fd)                          { (void)fd; return 1; }
int _fstat(int fd, struct stat *st)          { (void)fd; st->st_mode = S_IFCHR; return 0; }
int _getpid(void)                            { return 1; }
int _kill(int pid, int sig)                  { (void)pid; (void)sig; errno = EINVAL; return -1; }

void _exit(int status)
{
    (void)status;
    for (;;) { }
}
