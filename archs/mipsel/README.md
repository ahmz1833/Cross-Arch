# MIPS32 Architecture (Little Endian)

## Introduction

This directory contains resources, examples, and documentation for the **MIPS32 Release 2** architecture, specifically configured for **Little Endian** (`mipsel`) mode. MIPS is a RISC (Reduced Instruction Set Computer) architecture known for its clean design and widespread use in embedded systems, networking equipment, and education.

## Documentation & Resources

### Important Links
*   [GNU Assembler (gas) MIPS Options](https://sourceware.org/binutils/docs/as/MIPS-Options.html)
*   [GCC MIPS Options](https://gcc.gnu.org/onlinedocs/gcc-4.6.1//gcc/MIPS-Options.html)
*   [GNU Assembler MIPS Dependent Features](https://sourceware.org/binutils/docs/as/MIPS_002dDependent.html)

### Local Documentation
Useful PDF references can be found in the `docs/` directory:
*   [MipsInstructionSetReference.pdf](docs/MipsInstructionSetReference.pdf): Complete instruction set reference.
*   [mips-ref-sheet.pdf](docs/mips-ref-sheet.pdf): Quick reference sheet.
*   [o32callingconvention.pdf](docs/o32callingconvention.pdf): Details on the O32 ABI.
*   [MD00565-2B-MIPS32-QRC-01.01.pdf](docs/MD00565-2B-MIPS32-QRC-01.01.pdf): MIPS32 Quick Reference Card.

---

## How to Build and Run

### 1. Using Lab Tools (Recommended)
The easiest way to compile and run programs in this environment is using the provided wrapper scripts.

- First, you should activate the MIPS toolchain environment:
```bash
source lab-activate mips
```

- Build command for **libc-linked** programs:
```bash
# Syntax: lab-build <source_file> -o <output_file>
lab-build code.s -o hello.elf
# or 
lab-build -m libc code.s -o hello.elf
```

- Build command for **not-libc** (bare-metal) programs:
```bash
# Syntax: lab-build -m nolibc <source_file> -o <output_file>
lab-build -m nolibc code.s -o hello.elf
```

- **Run:**
```bash
# Syntax: lab-run <executable>
lab-run hello.elf
```

### 2. Manual Compilation (Advanced)
For those who want to understand the underlying toolchain commands, you can invoke the cross-compiler directly.

**Assemble:**
```bash
mipsel-buildroot-linux-gnu-as -g -march=mips32r2 -EL -o program.o program.s
```

**Link:**
```bash
mipsel-buildroot-linux-gnu-ld -EL -o program.elf program.o
```

Or, directly compile and link (with libc) in one step:
```bash
mipsel-buildroot-linux-gnu-gcc -static -march=mips32r2 -EL -o program.elf program.s
```

---

## Examples & Macros

The `examples/` directory contains a progressive series of assembly programs, each demonstrating specific architectural concepts.
| Example | Mode | Description | Key Concepts |
| :--- | :--- | :--- | :--- |
| `00_hello_world.s` | `nolibc` | Minimal Hello World | Syscalls (`SYS_WRITE`, `SYS_EXIT`), `.asciiz`. |
| `01_hello_libc.s` | `libc` | Hello World (Libc) | Linking with C library, calling `printf`, stack frame setup. |
| `02_input_output.s` | `nolibc` | Basic I/O | Reading integers/strings, printing results. |
| `03_control_flow.s` | `nolibc` | Logic & Loops | `if/else` branching, `while` loops, comparison instructions. |
| `04_functions.s` | `libc` | Function Calls | `jal`, `jr`, preserving registers (`$s0` vs `$t0`), leaf vs non-leaf functions. |
| `05_array_sum.s` | `nolibc` | Arrays & Memory | Iterating over memory, loading/storing words (`lw`, `sw`). |
| `06_min_max.s` | `libc` | Algorithms | Finding min/max values in a dataset. |
| `07_many_args.s` | `libc` | O32 ABI Deep Dive | Handling functions with >4 arguments (stack passing). |
| `08_float_ops.s` | `libc` | Floating Point | FPU usage (`$f0`-$`f31`), arithmetic, `printf` with doubles. |
| `09_file_ops.s` | `libc` | File I/O (Libc) | `fopen`, `fgets`, `fclose`, command line args (`argc`, `argv`). |
| `10_file_syscalls.s` | `nolibc` | File I/O (Syscalls) | Direct kernel syscalls (`open`, `read`, `write`) without libc. |

### Macros (`include/macros.inc`)
To simplify development, we provide a set of macros in `include/macros.inc`. These handle common tasks like:
*   `call function, arg1, arg2...`: Variadic function calls handling O32 ABI.
*   `enter` / `leave`: Stack frame setup and teardown.
*   `push` / `pop`: Stack operations.
*   `print_str`, `print_int`: Helper wrappers for printing.

### How to run Examples

Before anything, you must install the Cross-Arch Lab in your system.

1. Activate the MIPS environment:
```bash
source lab-activate mips
```

2. Clone and Navigate to the MIPS directory:
```bash
git clone https://github.com/ahmz1833/Cross-Arch.git
cd Cross-Arch/archs/mipsel
```

3. Build an example (assuming you want to run example number `nn`):
```bash
lab-build -m <libc|nolibc> examples/nn_XXXX.s -I include/ -o nn.elf
```

4. Run the builded example:
```bash
lab-run nn.elf
```

---

## Architecture Details

### Registers
MIPS registers always begin with a dollar symbol (`$`). General-purpose registers have both names and numbers.

| Number | Name | Comments |
| :--- | :--- | :--- |
| $0 | `$zero` | Always zero. Writes are ignored. |
| $1 | `$at` | Assembler Temporary. Reserved for the assembler. |
| $2, $3 | `$v0`, `$v1` | Return values from functions. |
| $4 - $7 | `$a0` - `$a3` | First four arguments to functions. |
| $8 - $15 | `$t0` - `$t7` | Temporary registers (Caller-saved). |
| $16 - $23 | `$s0` - `$s7` | Saved registers (Callee-saved). |
| $24, $25 | `$t8`, `$t9` | More temporary registers. |
| $26, $27 | `$k0`, `$k1` | Reserved for OS kernel. |
| $28 | `$gp` | Global Pointer. |
| $29 | `$sp` | Stack Pointer. |
| $30 | `$fp` | Frame Pointer. |
| $31 | `$ra` | Return Address. |

**Floating Point Registers:**
*   `$f0` - `$f31`: Used for floating point operations.
*   In O32 ABI, double-precision values use paired registers (e.g., `$f0` and `$f1`).

### Calling Convention (O32)
The default calling convention used here is **O32**.
*   **Arguments**: First 4 arguments passed in `$a0`-$`a3`. Remaining arguments passed on the stack.
*   **Return Values**: Stored in `$v0` and `$v1`.
*   **Stack Alignment**: Stack must be 8-byte aligned.
*   **Shadow Space**: The caller must reserve 16 bytes of "shadow space" on the stack for `$a0`-$`a3`, even if they are not used.

### Instruction Set Overview

The MIPS32 instruction set is divided into several categories:

#### Data Processing
*   **Arithmetic**: `add`, `sub`, `mul`, `div`
*   **Logical**: `and`, `or`, `xor`, `nor`
*   **Shift**: `sll` (Shift Left Logical), `srl` (Shift Right Logical)

#### Control Flow
*   **Jump**: `j` (Jump), `jal` (Jump and Link - for function calls).
*   **Branch**: `beq` (Branch if Equal), `bne` (Branch if Not Equal).
*   **System**: `syscall` (Trigger system call).

#### Memory Access
MIPS is a Load/Store architecture. Arithmetic operations only work on registers.
*   `lw`: Load Word (4 bytes).
*   `sw`: Store Word (4 bytes).
*   `lb` / `sb`: Load/Store Byte.
*   `la`: Load Address (Pseudo-instruction).

#### Floating Point (Coprocessor 1)
*   **Arithmetic**: `add.s` (single), `add.d` (double), `sub.s`, `mul.s`, `div.s`.
*   **Conversion**: `cvt.w.s` (float to int), `cvt.s.w` (int to float).
*   **Load/Store**: `lwc1` (Load Word to Coproc1), `swc1` (Store Word from Coproc1).

## Assembler Notes (GNU as)
*   **Directives**: Common directives include `.text` (code), `.data` (variables), `.globl` (export symbol), `.asciiz` (null-terminated string).
*   **Comments**: Use `#` for line comments.
*   **Pseudo-instructions**: The assembler supports many pseudo-instructions (like `move`, `li`, `la`, `blt`) that expand to one or more real machine instructions.
