/*
 * syscalls.inc - s390x Syscall Wrappers
 */

.include "constants.inc"

/* sys_exit(code) */
.macro sys_exit code=0
    _load_arg   %r2, \code
    svc         I_SYS_EXIT
.endm

/* sys_write(fd, buf, len) */
/* fd: File descriptor */
/* buf: Label/Address of buffer */
/* len: Length */
.macro sys_write fd, buf, len
    _load_arg   %r2, \fd
    _load_arg   %r3, \buf
    _load_arg   %r4, \len
    svc         I_SYS_WRITE
.endm

/* sys_read(fd, buf, len) */
.macro sys_read fd, buf, len
    _load_arg   %r2, \fd
    _load_arg   %r3, \buf
    _load_arg   %r4, \len
    svc         I_SYS_READ
.endm
