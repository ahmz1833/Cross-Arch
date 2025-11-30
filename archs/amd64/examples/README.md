# amd64 Example Suite

This directory contains curated amd64 examples for two common workflows:

- `libc/`: Programs that link against glibc and follow the System V AMD64 ABI.  They rely on the helper macros in `libc/macros.inc` to introduce `enter 0,0`/`leave` prologues, preserve callee-saved registers, and zero `EAX` before variadic calls (`printf`, `scanf`, …).
- `baremetal/`: Linux user-space programs that avoid libc entirely.  They showcase thin syscall helpers in `baremetal/macros.inc` (e.g., `SYS_WRITE`, `SYS_EXIT`) so each example stays readable.

## File Overview

| Path | Description |
| --- | --- |
| `libc/printf_math.asm` | Greets the user and adds an integer array before printing the sum via `printf`. |
| `libc/scanf_minmax.asm` | Reads three integers with `scanf`, tracks min/max/sum, and reports the results. |
| `baremetal/hello_syscall.asm` | Minimal syscall-only hello world that writes to stdout. |
| `baremetal/uppercase_echo.asm` | Reads from stdin, uppercases ASCII letters in-place, and writes the buffer back out without libc. |

## Building

Use the workspace `lab-build` script so the same commands work for native or cross toolchains:

```bash
# Native libc build
lab-build -M compile archs/amd64/examples/libc/printf_math.asm -I archs/amd64/examples/libc -o printf_math

# Native bare-metal NASM build (no libc)
lab-build -M nasm archs/amd64/examples/baremetal/hello_syscall.asm -I archs/amd64/examples/baremetal -o hello_sys

# Assemble-only, no libc linker (outputs ELF without default CRT)
lab-build -M asm archs/amd64/examples/baremetal/uppercase_echo.asm -I archs/amd64/examples/baremetal -o uppercase
```

All NASM sources assume `default rel` and System V AMD64 calling conventions.
