# IBM z/Architecture (s390x)

## Introduction

This directory contains resources, examples, and documentation for the **IBM z/Architecture (s390x)**. This is a **Big Endian**, CISC architecture known for its reliability and massive I/O throughput, commonly used in IBM mainframes.

## Documentation & Resources

### Important Links
*   [z/Architecture Principles of Operation](https://www.ibm.com/docs/en/module_1678991624569/pdf/SA22-7832-13.pdf): The official and definitive reference manual (The "PoP").
*   [Linux on zSeries ABI](https://refspecs.linuxbase.org/ELF/zSeries/lzsabi0_zSeries.html#AEN760): Official ABI documentation for Linux on s390x.
*   [GNU Assembler s390 Options](https://sourceware.org/binutils/docs/as/s390-Options.html): GNU Assembler documentation for s390.

### Local Documentation
Useful PDF references can be found in the `docs/` directory:
*   [Principle-of-Operation.pdf](docs/dz9zr006-Principle-of-Operation.pdf): Complete z/Architecture reference.
*   [Instructions-Reference-Summary.pdf](docs/Instructions-Reference-Summary.pdf): Quick instruction reference.
*   [Persian_Notes.md](docs/Persian_Notes.md): A guide in Persian covering mnemonics, registers, and conventions.

---

## How to Build and Run

### 1. Using Lab Tools (Recommended)
The easiest way to compile and run programs in this environment is using the provided wrapper scripts.

- First, activate the s390x toolchain environment:
```bash
source lab-activate s390x
```

- Build command for **libc-linked** programs:
```bash
# Syntax: lab-build <source_file> -o <output_file>
lab-build code.s -o hello.elf
# or
lab-build -m libc code.s -o hello.elf
```

- Build command for **nolibc** (bare-metal/syscall) programs:
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
For those who want to understand the underlying toolchain commands:

**Assemble:**
```bash
s390x-buildroot-linux-gnu-as -g -m64 -o program.o program.s
```

**Link (nolibc):**
```bash
s390x-buildroot-linux-gnu-ld -o program.elf program.o
```

**Compile and Link (with libc):**
```bash
s390x-buildroot-linux-gnu-gcc -static -m64 -o program.elf program.s
```

---

## Examples & Macros

The `examples/` directory contains a progressive series of assembly programs.

| Example | Mode | Description | Key Concepts |
| :--- | :--- | :--- | :--- |
| `00_hello_syscall.s` | `nolibc` | Minimal Hello World | `svc` (syscall), `SYS_WRITE`, `SYS_EXIT`, `.asciz`. |
| `01_hello_libc.s` | `libc` | Hello World (Libc) | Linking with C, `brasl` (call), stack frame setup. |
| `02_arithmetic.s` | `nolibc` | Math Operations | `agr` (add), `sgr` (sub), `msgr` (mul), `dsgr` (div). |
| `03_control_flow.s` | `nolibc` | Logic & Loops | `cgr` (compare), `jg` (jump), condition codes. |
| `04_functions.s` | `nolibc` | Function Calls | `enter`/`leave` macros, `stmg`/`lmg`, stack frames. |
| `05_recursion.s` | `nolibc` | Recursive Functions | Factorial example, saving/restoring R14. |
| `06_array_sum.s` | `nolibc` | Arrays & Memory | Iterating arrays, `lg`/`stg` (load/store). |
| `07_float_ops.s` | `libc` | Floating Point | FPR usage (`%f0`-`%f15`), `adbr`, `mdbr`. |
| `sort.s` | `nolibc` | Sorting in File | ASM Masters Challange |

### Macros (`include/macros.inc`)
To simplify development, we provide a set of macros in `include/macros.inc`:
*   `call function, arg1, arg2...`: Variadic function calls handling s390x ABI (up to 8 args).
*   `enter [size] [first]` / `leave [first]`: Stack frame setup and teardown.
*   `push reg` / `pop reg`: Stack operations.
*   `print_str label`: Print a null-terminated string.
*   `print_int reg, [base], [width]`: Print integer in any base.
*   `print_hex reg` / `print_bin reg`: Print in hex/binary.
*   `print_newline`: Print newline character.
*   `read_int reg`: Read integer from stdin.
*   `read_char reg`: Read single character.
*   `ret`: Simple return (`br %r14`).

### How to Run Examples

1. Activate the s390x environment:
```bash
source lab-activate s390x
```

2. Navigate to the s390x directory:
```bash
cd Cross-Arch/archs/s390x
```

3. Build an example:
```bash
lab-build -m <libc|nolibc> examples/NN_example.s -I include/ -o NN.elf
```

4. Run the example:
```bash
lab-run NN.elf
```

---

## Architecture Details

### Registers
s390x has 16 General Purpose Registers (GPRs, 64-bit) and 16 Floating Point Registers (FPRs, 64-bit).

| Register | Role (Linux ABI) |
| :--- | :--- |
| **R0, R1** | Scratch / System use. R1 holds syscall number. |
| **R2** | **1st Argument** / **Return Value**. |
| **R3 - R6** | **2nd - 5th Arguments**. |
| **R7 - R11** | Callee-Saved Variables. |
| **R12** | GOT Pointer / Base. |
| **R13** | Literal Pool Pointer. |
| **R14** | **Return Address** (Link Register). |
| **R15** | **Stack Pointer**. |

**Floating Point Registers:**
*   `%f0` - `%f15`: Used for floating point operations.
*   `%f0`, `%f2`, `%f4`, `%f6` are used for FP arguments/return values.

### Instruction Naming (Mnemonics)
The instruction names encode operand size and type:

| Suffix | Meaning | Example |
| :--- | :--- | :--- |
| **G** | 64-bit (Great) | `lgr` - Load Great Register |
| **F** | 32-bit (Full) | `lr` - Load Register (32-bit) |
| **GF** | 32→64 sign-extend | `lgfr` - Load Great from Full |
| **H** | 16-bit (Half) | `lh` - Load Halfword |
| **I** | Immediate | `lghi` - Load Great Halfword Immediate |
| **R** | Register operands | `lgr` - Load Great Register |
| **L** | Logical (unsigned) | `algr` - Add Logical Great |
| **RL** | Relative Label | `larl` - Load Address Relative Long |

> **Tip**: Always use `...rl` instructions (like `larl`, `lgrl`) when working with labels to avoid base register complexity.

### Calling Convention (s390x ELF ABI)
*   **Arguments**: First 5 arguments in `R2`-`R6`. Additional arguments on stack.
*   **Return Value**: Stored in `R2`.
*   **Stack Alignment**: Stack must be 8-byte aligned.
*   **Register Save Area**: Caller allocates 160 bytes for callee to save registers.

### The Stack Frame
The stack grows **downward**. `R15` points to the current frame.

```
High Address
+------------------+
| Caller's Frame   |
+------------------+ <- Previous R15
| Back Chain (8)   | 0(%r15)
| Reserved (8)     | 8(%r15)
| R2 Save (8)      | 16(%r15)
| R3 Save (8)      | 24(%r15)
| ...              |
| R6 Save (8)      | 48(%r15)
| R7 Save (8)      | 56(%r15)
| ...              |
| R15 Save (8)     | 120(%r15)
| FPR Saves        | 128-160
+------------------+ <- Current R15
| Local Variables  |
+------------------+
Low Address
```

*   **Minimum Frame**: 160 bytes (for register save area).
*   **Back Chain**: `0(R15)` points to the previous stack frame.

### Condition Codes (CC)
s390x uses a 2-bit Condition Code (values 0, 1, 2, 3) instead of individual flags.

| CC | Meaning (Compare) | Branch |
| :--- | :--- | :--- |
| 0 | Equal | `je` (Jump Equal) |
| 1 | Less Than | `jl` (Jump Low) |
| 2 | Greater Than | `jh` (Jump High) |
| 3 | Overflow | `jo` (Jump Overflow) |

### Arithmetic: Multiplication & Division

#### Multiplication
*   **32-bit**: `msr R1, R2` — Multiply Single Register. Result in R1.
*   **64-bit**: `msgr R1, R2` — Multiply Single Great. Result in R1.
*   **Immediate**: `mghi R1, imm` — Multiply Great Halfword Immediate.

#### Division (Register Pairs)
Division uses an **even-odd register pair** (e.g., R0:R1, R2:R3).

*   **64-bit**: `dsgr R1, R2` (R1 must be even).
    *   **Input**: 128-bit dividend in R1:R(1+1) pair.
    *   **Output**:
        *   **Remainder** → Even register (R1).
        *   **Quotient** → Odd register (R1+1).

```asm
/* Example: R6 = R6 / 10, R0 = R6 % 10 */
lghi    %r0, 0          /* Clear high part */
lgr     %r1, %r6        /* Dividend low */
lghi    %r9, 10         /* Divisor */
dsgr    %r0, %r9        /* Divide R0:R1 by R9 */
/* Now: R0 = remainder, R1 = quotient */
```

### Instruction Set Overview

#### Data Movement
*   `lgr R1, R2`: Load Great Register (64-bit copy).
*   `lghi R1, imm`: Load Great Halfword Immediate.
*   `larl R1, label`: Load Address Relative Long.
*   `lg R1, D(B)`: Load Great from memory.
*   `stg R1, D(B)`: Store Great to memory.
*   `stmg R1, R3, D(B)`: Store Multiple Great (R1 to R3).
*   `lmg R1, R3, D(B)`: Load Multiple Great.

#### Arithmetic
*   `agr R1, R2`: Add Great Register.
*   `sgr R1, R2`: Subtract Great Register.
*   `msgr R1, R2`: Multiply Single Great.
*   `dsgr R1, R2`: Divide Single Great.
*   `aghi R1, imm`: Add Great Halfword Immediate.

#### Logic & Compare
*   `cgr R1, R2`: Compare Great Register.
*   `cghi R1, imm`: Compare Great Halfword Immediate.
*   `ngr R1, R2`: AND Great.
*   `ogr R1, R2`: OR Great.
*   `xgr R1, R2`: XOR Great.

#### Control Flow
*   `brasl R14, target`: Branch and Save Long (function call).
*   `br R14`: Branch to Register (return).
*   `jg label`: Jump (unconditional).
*   `je`/`jne`/`jl`/`jh`/`jle`/`jhe`: Conditional jumps.

#### System
*   `svc imm`: Supervisor Call (syscall). Syscall number in R1.

---

## Assembler Notes (GNU as)
*   **Comments**: Use `/*...*/` for block comments, `#` for line comments.
*   **Directives**: `.text` (code), `.data` (data), `.globl` (export), `.asciz` (string).
*   **Register Prefix**: Always use `%` prefix: `%r0`, `%r15`, `%f0`.
*   **Immediates**: Can use decimal, hex (`0x`), or character literals (`'A'`).
