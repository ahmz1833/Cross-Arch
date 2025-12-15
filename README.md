# Cross-Arch Assembly Lab

The **Cross-Arch** repository is a comprehensive, unified environment designed for **Computer Structure and Assembly Language** courses. It provides a seamless toolchain (GCC, GDB, QEMU) to compile, run, and debug assembly code across multiple architectures without leaving your terminal.

This repository also has useful examples and rich documents related to each architecture (*This part is under construction!*)

### 🚀 Supported Architectures

This repository now supports 7 architectures, with a primary focus on the syllabus standards:

- **[MIPS32 (Little Endian)](archs/mipsel/)** `mips` - *Core Syllabus of RISC systems*
- **[Intel x86_64 (AMD64 and i386)](archs/x86/)** `amd64` and `i386` - *Core Syllabus of CISC systems*
- **[IBM s390x (Z13)](archs/s390x/)** `s390x` - *Core Syllabus (Mainframe)*
- **[RISC-V (64-bit)](archs/riscv64/)** `riscv64` - *An open source and flexible architecture*
- **[ARMv7 (32-bit)](archs/armv7/)** `armv7` - *A good example for addressing modes*
- **[AArch64 (ARM 64-bit)](archs/aarch64/)** `aarch64` - *Up-to-date RISC systems use it*

---

## 📥 Installation Guide

Choose the method that best fits your Operating System.

### 🐧 Linux Users

You have full control. We recommend the **Direct (Native)** method for the best performance and integration, but the **Docker method** is available if you prefer keeping your system clean.

### 🪟 Windows Users

**Do not use PowerShell/CMD directly.**

1. Install **WSL2** (Windows Subsystem for Linux) with Ubuntu.
2. Open your WSL terminal.
3. Follow the **Direct (Native)** installation method below.

### 🍎 macOS Users

You have two options:

1. **Docker (Recommended):** The easiest path. Uses containers to simulate the Linux environment. Works perfectly on Apple Silicon (M1/M2/M3) and Intel.
2. **UTM + Ubuntu (Advanced):** If you want to "feel" the OS and avoid Docker abstractions, install Ubuntu Server via [UTM](https://mac.getutm.app/). Then, use the **Direct (Native)** method inside the VM.

	*Note: You can see [this video](https://raw.githubusercontent.com/MahdiGMK/AMD64-Assembly-Project-Template/refs/heads/master/mac_utm.mp4) to setup **Ubuntu Server** on **UTM**. we only need a terminal connected to that to install our clean and straight tool __"Cross Arch"__ on that.*

------

### Method A: Direct Installation (Native)

*Best for: Linux, Windows (WSL2), macOS (via UTM)*

This installs the management scripts to `/usr/local/bin` and clones the repo to `/opt/cross-arch`. It does **not** install the heavy toolchains immediately; you download them **on demand**.

> **Note:** We use the high-quality, pre-built toolchains provided by [Bootlin](https://toolchains.bootlin.com/). These ensure stability and compatibility across all supported architectures.

1. **Run the Installer:**
   
   ```bash
   curl -fsSL https://raw.githubusercontent.com/ahmz1833/Cross-Arch/main/install-direct.sh | sudo bash
   ```
   
2. **Install a Toolchain (e.g., MIPS):**
   
   ```bash
   sudo lab-setup -T mips
   # mips - amd64 - s390x - armv7 - aarch64 - riscv64 - i386
   ```
   
3. **Activate the Environment:**
   ```bash
   source lab-activate mips 
   # mips - amd64 - s390x - armv7 - aarch64 - riscv64 - i386
   ```

**Note: For Updating the Toolchain scripts, you can use the install script in 1.**

### Method B: Docker Installation

*Best for: macOS (Standard) - Also maybe used for Linux*

This installs wrapper scripts that transparently forward your commands to optimized Docker containers. You don't need to manually manage containers.

**Prerequisite:** Ensure [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed and running. Also, you must ensure that your user is in the docker group and you can run docker commands without sudo/root access.

1. **Run the Installer:**
   
   ```bash
   curl -fsSL https://raw.githubusercontent.com/ahmz1833/Cross-Arch/main/install-docker.sh | sudo bash
   ```
   
2. **Activate the Environment:**
   
   ```bash
   source lab-activate mips 
   # mips - amd64 - s390x - armv7 - aarch64 - riscv64 - i386
   ```
   
   *(Note: This will automatically pull the necessary Docker image if it's not present. Note that each image download consumes about **200 MB** of your Internet traffic.)*

**Note: For Updating the Toolchain scripts, YOU MUST PULL MANUALLY THE DOCKER IMAGES YOU WANT TO UPDATE.**

For example, to update the MIPS toolchain, you can run:
```bash
docker pull ghcr.io/ahmz1833/cross-arch:mips
```

------

## 🛠 Usage

Once installed, the workflow is identical regardless of your OS or installation method.

### Activate an Architecture

Switch your terminal context to the desired architecture. This updates your `PATH` and prompt.

```bash
source lab-activate mips
# Prompt changes to: (mips-lab) user@host $
```

### Compile & Run

You can use the standard GNU tools prefixed with `lab-` (which map to the correct cross-compiler).

```bash
# Compile a C file
lab-build main.c -o main

# Assemble an assembly file (with libc)
lab-build main.S -o main

# Assemble an Assembly file (without libc)
lab-build -m asm main.S -o main

# Assemble a x86 - amd64 NASM file (without libc)
lab-build -m nasm main.asm -o main

# Assemble a x86 - amd64 NASM file (with libc)
lab-build -m nasm-gcc main.asm -o main

# Run the binary with appropriate emulator
lab-run ./main

# Run amd64 binary natively (NOT ON MAC-OS!)
./main
```

### Debug

We provide a pre-configured GDB + QEMU setup that handles port forwarding and execution automatically.

```bash
lab-debug ./main
```

### Switch or Reset

To switch architectures or return to your normal shell:

```bash
# Switch to amd64
source lab-activate amd64

# Reset to native shell
source lab-activate native
```

------

## 🗑 Uninstallation

If you wish to remove the lab environment, follow these steps.

### Remove Scripts and Repository

Removes the helper scripts (`lab-gcc`, `lab-debug`, etc.) and the core repository.

```bash
sudo rm -f /usr/local/bin/lab-* /usr/local/bin/__lab_*
sudo rm -rf /opt/cross-arch
```

### Remove Toolchains (Native Users)

If you used the **Direct** method, the compilers reside in `/opt`.

```bash
# Remove ALL toolchains
sudo rm -rf /opt/*-lab

# Remove ONLY MIPS toolchain
sudo rm -rf /opt/mips-lab
```

### Remove Docker Images (Docker Users)

If you used the **Docker** method, you can reclaim space by removing the images.

```bash
# Remove specific architecture image
docker rmi ghcr.io/ahmz1833/cross-arch:mips

# Remove all cross-arch images
docker images | grep cross-arch | awk '{print $3}' | xargs docker rmi
```

## 🎓 Learning Guide

If you are starting, here is the recommended path:

1. **From MARS to GCC (MIPS Users)**

   If you are coming from the MARS Simulator, things work slightly differently here.

   - **MARS**: You run code directly.

   - **Here**: You Assemble + Link then Run (Linux Emulation).

   Navigate to `archs/mipsel/examples_mars`. These are example assembly codes which run in the **MARS simulator**. Then, you can navigate to `archs/mispel/examples` to see how standard MARS code is adapted for the **GNU Assembler** (gas).

2. **Baremetal vs. Libc (AMD64 Users)**

   Inside `archs/amd64/examples`, you will find two categories:

   - **libc**: Uses standard C library functions (like printf, exit). Easier to write but requires the OS.

   - **baremetal**: Pure assembly using Linux Syscalls (syscall). Closer to the hardware, no libraries attached.

## Architecture Specific Notes and References

You can explore in the `archs/` directory for architecture-specific notes, references, and examples. Also there are links to those in the [top](#-supported-architectures) of this README.

Each architecture folder contains:
- `README.md`: Architecture overview and specifics.
- `examples/`: Sample assembly programs for that architecture.
- `docs/`: Some of useful documents and references.
- Something else...

## Judge System

The `judge/` directory contains tools for static analysis of assembly code. The core script `analyze.py` can parse objdump outputs to extract function call graphs, detect syscalls, and list used instructions. This is useful for automated grading or verifying code structure without running it.

Check [judge/README.md](judge/README.md) for more details.

## Will be added

- Architectures references, and samples
- Judge handling for each architecture
- ...

## 📚 Sources & Resources

Here are some helpful documents, links, and resources useful for students:

- **[Compiler Explorer (Godbolt)](https://godbolt.org/)**: An interactive online compiler that shows the assembly output of your C/C++ code in real-time.
- **[Calling Conventions (Wikipedia)](https://en.wikipedia.org/wiki/Calling_convention)**: Understanding how functions receive parameters and return values is crucial in assembly.
- **[GNU Assembler (GAS) Documentation](https://sourceware.org/binutils/docs/as/)**: The official manual for the assembler used in this lab.
- **[Linux Syscall Table](https://gpages.juszkiewicz.com.pl/syscalls-table/syscalls.html)**: A comprehensive table of system calls for various architectures.
- **[Linux Syscall Man Page](https://man7.org/linux/man-pages/man2/syscall.2.html)**: Official documentation on how to invoke system calls.
- **[Linux Assembly HOWTO](https://tldp.org/HOWTO/Assembly-HOWTO/)**: A classic guide to writing assembly on Linux.

## License

- SPDX: `GPL-3.0-or-later`

This project is licensed under the GNU General Public License v3.0 (or any later
version). See the full license text in the `LICENSE` file included with this
repository.

Summary:
- You are free to copy, modify, and redistribute this project under the terms
   of the GPLv3.
- The project is provided "AS IS", without warranty of any kind — see `LICENSE`
   for the full disclaimer and terms.

If you prefer a different license, replace the `LICENSE` file and update this
section accordingly.

## Special Thanks

Soon

https://www.ctfrecipes.com/pwn/architectures/

<!-- - **Mahdi Bahramian** ([MahdiGMK](https://github.com/MahdiGMK)) for ...
- **AmirHossein Mirzaei** ([radical-1](https://github.com/radical-1)) for ...
- **Pouria Ghafouri** ([pouriaghafouri](https://github.com/pouriaghafouri)) for ...
- **Hirbod Behnam** ([HirbodBehnam](https://github.com/HirbodBehnam)) for ....
- **MohammadAmin Koohi** ([MohammadAminKoohi](https://github.com/MohammadAminKoohi)) for ...

and also [**AmirKasra Ahmadi**](https://github.com) for ... , [**Salam2**](https://github.com) for ..., **Salam3** for ..., **Salam4** for ... -->

<p align="center"> Made by AHMZ with ❤️ for CE Students </p>
