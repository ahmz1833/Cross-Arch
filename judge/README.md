# Assembly Static Analyzer

This directory contains `analyze.py`, a Python script designed to perform static analysis on assembly code. It works by parsing the output of `objdump` (or similar disassembly tools) to reconstruct control flow, identify function calls, and detect system calls.

## Features

- **Multi-Architecture Support**: Works with MIPS, x86 (32/64-bit), ARM (v7/v8), and s390x.
- **Call Graph Construction**: Identifies functions and their relationships (caller/callee).
- **Syscall Detection**: Attempts to resolve system call numbers statically.
- **Instruction Listing**: Lists all instructions used in a function (or recursively).

## Usage

The script expects a disassembly file (objdump output) as input.

### 1. Generate Disassembly

First, compile your code and generate a dump:

```bash
# Compile
lab-gcc main.s -o main

# Generate dump
lab-objdump -d main > main.dump
```

### 2. Run Analyzer

```bash
python3 analyze.py main.dump --arch <arch> [OPTIONS]
```

**Supported Architectures (`--arch`):**
- `mips` / `mipsel`
- `x86` (for i386 and amd64)
- `arm`
- `aarch64`
- `s390x`

### Options

- `--dump-graph`: Print the full function call graph.
- `--list-funcs`: List all identified functions.
- `--list-callees <FUNC>`: List functions called directly by `<FUNC>`.
- `--list-callees-recursive <FUNC>`: List all functions called by `<FUNC>` (deep).
- `--list-syscalls <FUNC>`: List syscalls made directly in `<FUNC>`.
- `--list-syscalls-recursive <FUNC>`: List syscalls made by `<FUNC>` and its callees.
- `--list-instrs <FUNC>`: List unique instructions used in `<FUNC>`.

## Examples

**Check if `main` calls `printf`:**
```bash
python3 analyze.py main.dump --arch x86 --list-callees-recursive main
```

**List all syscalls used in the program:**
```bash
python3 analyze.py main.dump --arch mips --list-syscalls-recursive main
```
