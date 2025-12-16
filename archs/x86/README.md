# Intel x86 Architecture (AMD64 & i386)

## Introduction

This directory contains resources, examples, and documentation for the **Intel x86** architecture, covering both **AMD64 (x86-64)** and **i386 (32-bit)** modes. x86 is the dominant architecture for personal computers and servers, known for its rich (CISC) instruction set, backward compatibility, and high performance.

This guide focuses primarily on **64-bit Assembly (NASM syntax)** on Linux, which is the standard for modern systems.

#### **Workshop Video :** [Google Drive Link](https://drive.google.com/file/d/1po04lNEboSfPHZfMsDIv1QHp0IIHCK0F/view)

## Documentation & Resources

### Essential Reading (Web)
*   **[x86 Assembly/Architecture (Wikibooks)](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture)**: The best brief introduction to the ISA.
*   **[x86 Instruction Reference (Felix Cloutier)](https://www.felixcloutier.com/x86/)**: The definitive searchable reference for all instructions.
*   **[Linux System Call Table (x64)](https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)**: Essential for bare-metal programming (`syscall`).
*   **[NASM Documentation](https://www.nasm.us/doc/nasm03.html)**: Syntax guide for the Netwide Assembler.
*   **[System V AMD64 ABI](https://wiki.osdev.org/System_V_ABI#x86-64)**: The rules for calling functions and interfacing with C.
*   **[x86-64 Assembly Slides](https://markfloryan.github.io/pdr/slides/08-assembly-64bit.html#/cover)**: Comprehensive visual guide.
*   **[x86 Assembly Guide (32-bit)](https://www.cs.virginia.edu/~evans/cs216/guides/x86.html)**: Good reference for legacy 32-bit mode.

### Local Documentation (`docs/`)
*   **[Intel_Microprocessors-Ebook.pdf](docs/Intel_Microprocessors-Ebook.pdf)**: In-depth textbook on the architecture.
*   **[x86_64-abi-0.99.pdf](docs/x86_64-abi-0.99.pdf)**: Official System V Application Binary Interface specification.

---

## How to Build and Run

### 1. Using Lab Tools (Recommended)
The easiest way to compile and run programs in this environment is using the provided wrapper scripts.

- First, you should activate the desired toolchain environment:
```bash
source lab-activate amd64  # For 64-bit
# or
source lab-activate i386   # For 32-bit
```

- Build command for **libc-linked** programs:
```bash
# Syntax: lab-build -m nasm-gcc <source_file> -o <output_file>
lab-build -m nasm-gcc code.asm -o hello.elf
```

- Build command for **not-libc** (bare-metal) programs:
```bash
# Syntax: lab-build -m nasm <source_file> -o <output_file>
lab-build -m nasm code.asm -o hello.elf
```

- **Run:**
```bash
# Syntax: lab-run <executable>
lab-run hello.elf
```

### 2. Manual Compilation (AMD64 only)
For those who want to understand the underlying toolchain commands, you can invoke the compiler directly.

**Assemble:**
```bash
nasm -f elf64 program.asm -o program.o
```

**Link (Without Libc):**
```bash
ld -o program.elf program.o
```

**Link (With Libc):**
```bash
gcc -no-pie -static -o program.elf program.o
```

---

## Examples Roadmap

The `examples/` directory contains a progressive series of assembly programs. Each example is designed to teach specific concepts.

| Example | Mode | Description | Key Concepts |
| :--- | :--- | :--- | :--- |
| **Basics** | | | |
| `00_hello_world.asm` | `nasm` | Minimal Hello World | `syscall` (1=write, 60=exit), `.data`, `.text`. |
| `01_hello_libc.asm` | `nasm-gcc` | Hello World (Libc) | Linking with C, `extern printf`, `main` entry point. |
| `02_input_output.asm` | `nasm` | Basic I/O | Reading stdin, writing stdout, buffers. |
| **Logic & Control** | | | |
| `03_data_types.asm` | `nasm` | Data Sizes | Byte, Word, Dword, Qword, Endianness. |
| `04_control_flow.asm` | `nasm` | Logic & Loops | `cmp`, `je/jne`, `jmp`, `loop` instruction. |
| **Floating Point** | | | |
| `05_floating_point.asm` | `nasm-gcc` | SSE Math | `xmm` registers, `addsd`, `cvtsi2sd`, `printf` with floats. |
| **Functions & ABI** | | | |
| `06_functions.asm` | `nasm-gcc` | Stack Frames | `push rbp`, `mov rbp, rsp`, `argc`, `argv`. |
| `07_recursion.asm` | `nasm-gcc` | Recursion | Recursive calls, stack depth, base cases. |
| `08_many_args.asm` | `nasm-gcc` | System V ABI | Passing >6 arguments (Stack passing), Alignment. |
| **Advanced** | | | |
| `09_file_libc.asm` | `nasm-gcc` | File I/O (Libc) | `fopen`, `fprintf`, `fscanf`, `fclose`. |
| **Legacy 32-bit Mode** | | | |
| `10_hello_32bit.asm` | `nasm` | Legacy 32-bit | `int 0x80`, 32-bit registers (`eax`, `ebx`). |
| `11_libc_32bit.asm` | `nasm-gcc` | 32-bit Libc | Linking with C in 32-bit mode, `cdecl` convention. |

*Note: Before execute commands, you should activate the appropriate environment using `source lab-activate amd64` (or `source lab-activate i386`). Also you should be in the `archs/x86` directory.*

### 🟢 Basics & Syscalls
*   **`00_hello_world.asm`**: The absolute minimum. Uses direct Linux syscalls (`sys_write`, `sys_exit`) to print to stdout.
	```
	lab-build -m nasm examples/00_hello_world.asm -I include/ -o 00.elf && lab-run 00.elf
	```
*   **`01_hello_libc.asm`**: The "Standard" way. Links with C library (glibc) to use `printf`. Shows how to define `main` instead of `_start`.
    ```
	lab-build -m nasm-gcc examples/01_hello_libc.asm -I include/ -o 01.elf && lab-run 01.elf
	```
*   **`02_input_output.asm`**: Basic interaction. Reads from stdin and writes to stdout using syscalls.
    ```
	lab-build -m nasm examples/02_input_output.asm -I include/ -o 02.elf && lab-run 02.elf
	```

### 🟡 Logic & Control Flow
*   **`03_data_types.asm`**: Understanding sizes. Demonstrates `byte`, `word`, `dword`, `qword` and Endianness.
    ```
	lab-build -m nasm examples/03_data_types.asm -I include/ -o 03.elf && lab-run 03.elf
	```
*   **`04_control_flow.asm`**: Decision making. Uses `cmp` (compare) and conditional jumps (`je`, `jne`, `jg`) to implement `if/else` and loops.
    ```
	lab-build -m nasm examples/04_control_flow.asm -I include/ -o 04.elf && lab-run 04.elf
	```

### 🔵 Floating Point (SSE)
*   **`05_floating_point.asm`**: Modern Math. Uses the **SSE** unit (`xmm` registers) for floating point arithmetic (`addsd`, `mulsd`). Shows how to print floats using `printf`.
    ```
	lab-build -m nasm-gcc examples/05_floating_point.asm -I include/ -o 05.elf && lab-run 05.elf
	```

### 🟣 Functions & Stack
*   **`06_functions.asm`**: Structure. Defines reusable functions, manages stack frames (`push rbp`), and handles command line arguments (`argc`, `argv`).
    ```
	lab-build -m nasm-gcc examples/06_functions.asm -I include/ -o 06.elf && lab-run 06.elf
	```
*   **`07_recursion.asm`**: Advanced Stack. A recursive factorial function demonstrating stack depth and return addresses.
    ```
	lab-build -m nasm-gcc examples/07_recursion.asm -I include/ -o 07.elf && lab-run 07.elf
	```
*   **`08_many_args.asm`**: The ABI Limit. Demonstrates passing more than 6 arguments, forcing the use of the stack for argument passing.
    ```
	lab-build -m nasm-gcc examples/08_many_args.asm -I include/ -o 08.elf && lab-run 08.elf
	```

### 🔴 Advanced I/O
*   **`09_file_libc.asm`**: High-level I/O. Uses C standard library functions (`fopen`, `fprintf`, `fscanf`) for file operations.
    ```
	lab-build -m nasm-gcc examples/09_file_libc.asm -I include/ -o 09.elf && lab-run 09.elf
	```

### 🟠 Legacy 32-bit Mode
*   **`10_hello_32bit.asm`**: Legacy Mode. A 32-bit program using `int 0x80`.
    ```
	lab-build -m nasm -t i386 examples/10_hello_32bit.asm -o 10.elf && lab-run 10.elf
	```
*   **`11_libc_32bit.asm`**: 32-bit Libc. Demonstrates the **cdecl** calling convention (arguments on stack) used in 32-bit C programs.
    ```
	lab-build -m nasm-gcc -t i386 examples/11_libc_32bit.asm -o 11.elf && lab-run 11.elf
	```

---

## Architecture Deep Dive

For a comprehensive study, please refer to the **[Wikibooks x86 Architecture Guide](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture)**.

### Registers & Data Sizes
x86-64 extends 32-bit registers (`EAX`) to 64-bit (`RAX`).
*   **Hierarchy**: `RAX` (64) -> `EAX` (32) -> `AX` (16) -> `AL` (8).
*   **Zero-Extension**: Writing to a 32-bit register **zeroes** the upper 32 bits of the 64-bit register.
*   **More Info**: [General Purpose Registers](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture#General-Purpose_Registers_(GPR)_-_16-bit_naming_conventions)

### Memory & Addressing
*   **Syntax**: `[base + index*scale + displacement]`.
*   **MOV vs LEA**: `MOV` loads the **content** at an address. `LEA` loads the **address** itself (calculation only).

### Control Flow & Flags
*   **RFLAGS**: Contains status bits like **ZF** (Zero), **SF** (Sign), **OF** (Overflow).
*   **CMP**: Performs subtraction to set flags but discards result.
*   **Jumps**: `je` (Equal), `jne` (Not Equal), `jg` (Greater - Signed), `ja` (Above - Unsigned).
*   **More Info**: [EFLAGS Register](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture#EFLAGS_Register)

### Arithmetic Quirks
*   **Multiplication**: `mul rbx` -> Result in `RDX:RAX` (128-bit).
*   **Division**: `div rbx` -> Divides `RDX:RAX` by `RBX`. **Trap**: You must clear `RDX` (or sign-extend using `cqo`) before division, or you'll get a Floating Point Exception.

---

## System-V AMD64 ABI (Calling Convention)

This defines how functions call each other.

### Function Calls vs. Syscalls
*   **Function Call (`call`)**: Uses **System V ABI**. Args in `RDI, RSI, RDX, RCX, R8, R9`. Return in `RAX`.
*   **System Call (`syscall`)**: Uses **Kernel ABI**. Args in `RDI, RSI, RDX, R10, R8, R9`. Return in `RAX`. Syscall number in `RAX`.
    *   *Note the difference in the 4th argument (`RCX` vs `R10`)!*

### The Rules (Function Calls)
1.  **Args**: First 6 in `RDI, RSI, RDX, RCX, R8, R9`. Rest on stack (reverse order).
	**Remember:** ***Di**enna's **Si**lk **D**ress **C**osts **89**$*
2.  **Return**: `RAX`.
3.  **Preserved**: `RBX, RBP, R12-R15`.
4.  **Stack Alignment**: `RSP` must be **16-byte aligned** before `call`.

---

## Assembler Macros

We provide high-level macros in `include/macros.inc` to simplify learning.

### Printing & I/O
*   `print_str <label/reg>`: Print a null-terminated string.
*   `print_int <reg>`: Print a signed integer.
*   `print_hex <reg> [width]`: Print in hexadecimal.
*   `print_bin <reg> [width]`: Print in binary.
*   `print_newline`: Print a `\n`.
*   `read_line <buffer>, <size>`: Read a line of text from stdin.
*   `read_char <dest>`: Read a single character.

### System Wrappers
*   `exit`: Exit the program cleanly.
*   `sys_write`, `sys_read`, `sys_open`, `sys_close`: Direct syscall wrappers (defined in `syscalls.inc`).
