# MIPS Example Suite

This directory mirrors the amd64 example layout with both bare-metal assembly and libc-linked samples that can be built via `scripts/build.sh`.

## Bare-metal (`examples/baremetal`)

| File | Description |
| --- | --- |
| `macros.inc` | GNU as macros for launching `_start` and issuing Linux syscalls without libc (included via workspace-relative path so no `-I` is required). |
| `hello_syscall.s` | Minimal "hello world" that writes to stdout then exits. |
| `uppercase_echo.s` | Reads up to 128 bytes, converts to uppercase in-place, and prints the transformed buffer. |

Build examples (requires the Bootlin `mips` tag/toolchain):

```bash
# Assemble + link without libc
scripts/build.sh -T mips -M asm \
    archs/mipsel/examples/baremetal/hello_syscall.s \
    -o hello-mips
```

Replace the source path with `uppercase_echo.s` for the interactive demo.

## Libc (`examples/libc`)

| File | Description |
| --- | --- |
| `printf_math.c` | Computes the sum of a static integer array and prints the result. |
| `scanf_minmax.c` | Streams integers from stdin and reports the min/max pair. |

Build with the regular compile mode so the cross GCC links against glibc:

```bash
scripts/build.sh -T mips archs/mipsel/examples/libc/printf_math.c -o printf-mips
scripts/build.sh -T mips archs/mipsel/examples/libc/scanf_minmax.c -o scan-mips
```

Both commands honor extra flags (e.g., `-O2`, `-static`) exactly as if you were driving the toolchain directly.
