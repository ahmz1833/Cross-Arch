#!/usr/bin/env bash
set -euo pipefail
## ==============================================================================
## Lab Build Helper for Cross-Arch Toolchains
## By AHMZ - November 2025
##
## This script standardizes compilation, assembly, and linking across multiple
## architectures (x86, MIPS, ARM, RISC-V, s390x) for educational labs.
##
## Usage: lab-build [options] [--] <sources / flags / objects>
##
## Key Features:
## 1. Abstraction: "lab-build -T mips main.c" works the same as "lab-build -T armv7 main.c".
## 2. Tag Resolution: Resolves architecture from CLI (-T), ENV (LAB_ARCH), or defaults to native.
## 3. Security/Debug Flags: Sets baseline flags to make debugging assembly easier (disabling PIE).
## 4. NASM Support: Handles both 64-bit and 32-bit Intel NASM assembly.
## ==============================================================================

LAB_BASE_DIR="/opt"
SCRIPT_NAME="${0##*/}"

# --- GLOBAL DEFAULT FLAGS ---
# These flags are applied to ALL builds to ensure a consistent, debuggable environment.

# CFLAGS (GCC/Clang):
# -O0:              Disable optimizations. Crucial for labs so assembly matches C source 1:1.
# -g:               Generate debug information (DWARF).
# -fno-pie:         Do NOT generate Position Independent Executable code.
#                   This ensures functions/data have fixed absolute addresses, making GDB easier.
# -no-pie:          Tell the linker not to randomize the load address (disable ASLR for this binary).
# -z noexecstack:   Mark the stack as non-executable (Security Best Practice).
#                   *Note*: Shellcode labs might need to override this with "-z execstack" in arguments.
BASE_CFLAGS=(-O0 -g -fno-pie -no-pie -z noexecstack)

# ASFLAGS (GNU Assembler):
# -g:               Generate debug info.
BASE_ASFLAGS=(-g)

# NASMFLAGS (Netwide Assembler):
# -g:               Generate debug info.
# -F dwarf:         Format debug info as DWARF (standard for GDB on Linux).
BASE_NASMFLAGS=(-g -F dwarf)

# LDFLAGS (Linker):
# -z noexecstack:   Consistent with CFLAGS security.
BASE_LDFLAGS=(-z noexecstack)

declare -a USER_ARGS=()

# Registry of supported architectures/tags
SUPPORTED_TAGS_INFO=(
  "amd64:Native x86_64 (amd64) lab"
  "mips:MIPS32r2 little-endian lab"
  "s390x:IBM Z (z13) lab"
  "aarch64:AArch64 lab"
  "armv7:ARMv7 hard-float lab"
  "riscv64:RV64GC lab"
  "i386:x86 32-bit lab"
)

# --- UTILITIES ---

# ANSI Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YLW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

die() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

info() {
    echo -e "${CYAN}>>> $*${NC}"
}

warn() {
    echo -e "${YLW}Warning: $*${NC}"
}

# Print the command being executed for transparency
print_cmd() {
    local -a cmd=("$@")
    printf "${BLUE}>>>" >&2
    printf ' %q' "${cmd[@]}" >&2
    printf "${NC}\n" >&2
}

usage() {
    echo -e "${BOLD}Usage:${NC} ${SCRIPT_NAME} [options] [--] <sources / flags / objects>

${BOLD}Modes:${NC}
    ${GREEN}compile${NC} (default)   GCC-style driver. Links with libc. Best for C or mixed C/ASM.
    ${GREEN}asm${NC}                 Pure GNU Assembly. Assembles via 'as', links via 'ld' ${BOLD}without${NC} libc.
    ${GREEN}nasm${NC}                Pure NASM. Assembles via 'nasm', links via 'ld' ${BOLD}without${NC} libc.
    ${GREEN}nasm-gcc${NC}            Mixed NASM. Assembles via 'nasm', links via 'gcc' ${BOLD}with${NC} libc.

${BOLD}Options:${NC}
  ${YLW}-T, --tag TAG${NC}     Architecture tag (amd64, mips, s390x, aarch64, armv7, riscv64, i386).
                    If omitted, uses LAB_ARCH env. If both missing, uses native host.
  ${YLW}-M, --mode MODE${NC}   compile | asm | nasm | nasm-gcc
  ${YLW}--list-tags${NC}       Show supported tags and exit.
  ${YLW}-h, --help${NC}        Show this help and exit.
  ${YLW}--${NC}                Treat remaining arguments as toolchain flags/files.

${BOLD}Examples:${NC}
  Compile C for MIPS:
    ${CYAN}${SCRIPT_NAME} -T mips main.c -o main_mips${NC}
  Assemble NASM for native x86_64 (amd64):
    ${CYAN}${SCRIPT_NAME} -M nasm program.asm -o program${NC}
  Assemble GNU Asm for ARMv7:
    ${CYAN}${SCRIPT_NAME} -T armv7 -M asm startup.s -o startup_arm${NC}
  Compile with LAB_ARCH environment variable:
    ${CYAN}export LAB_ARCH=riscv64
    ${SCRIPT_NAME} main.c -o main_riscv${NC}
"
}

list_tags() {
    echo -e "${BLUE}Supported tags:${NC}"
    for entry in "${SUPPORTED_TAGS_INFO[@]}"; do
        IFS=':' read -r tag desc <<< "$entry"
        printf '  %-8s %s\n' "$tag" "$desc"
    done
}

lower() {
    tr '[:upper:]' '[:lower:]'
}

ensure_trailing_slash() {
    local path="$1"
    [[ -z "$path" ]] && { echo "$path"; return; }
    [[ "$path" == */ ]] || path="${path}/"
    echo "$path"
}

cleanup_tmpdir() {
    local dir="${1:-}"
    [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir"
}

# Determine which architecture tag to use based on priority:
# 1. CLI Argument (-T)
# 2. Environment Variable (LAB_ARCH)
# 3. Empty (Native)
resolve_tag() {
    local cli_tag="$1"
    if [[ -n "$cli_tag" ]]; then
        echo "$cli_tag"
        return
    fi
    local env_tag="${LAB_ARCH:-}"
    if [[ -n "$env_tag" ]]; then
        local env_lower
        env_lower=$(printf '%s' "$env_tag" | lower)
        # Normalize various names for native to empty string
        if [[ "$env_lower" == "amd64" || "$env_lower" == "x86_64" || "$env_lower" == "native" ]]; then
            echo ""
        else
            echo "$env_tag"
        fi
    else
        echo ""
    fi
}

# --- TOOLCHAIN SETUP ---

CC_BIN=""
AS_BIN=""
NASM_BIN=""
LD_BIN=""
AS_WRAPS_CC=0   # Flag: Is 'as' actually 'gcc -c'? (Some toolchains lack standalone 'as')
MODE_NATIVE=1   # Flag: Are we using the host system's toolchain?
TOOLCHAIN_TAG=""

setup_toolchain() {
    local tag="$1"
    TOOLCHAIN_TAG="${tag:-native}"

    # 1. Native Setup (Host System)
    if [[ -z "$tag" ]]; then
        MODE_NATIVE=1
        CC_BIN=$(command -v gcc || true)
        [[ -n "$CC_BIN" ]] || die "gcc not found in PATH."
        
        NASM_BIN=$(command -v nasm || true)
        # NASM is optional unless NASM modes are used
        
        AS_BIN=$(command -v as || true)
        if [[ -z "$AS_BIN" ]]; then
            AS_BIN="$CC_BIN"
            AS_WRAPS_CC=1
        else
            AS_WRAPS_CC=0
        fi
        
        LD_BIN=$(command -v ld || true)
        [[ -n "$LD_BIN" ]] || LD_BIN="$CC_BIN"
        return
    fi

    # 2. Cross-Compiler Setup (/opt/TAG-lab)
    MODE_NATIVE=0
    NASM_BIN=""
    local toolchain_dir="${LAB_BASE_DIR}/${tag}-lab"
    [[ -d "$toolchain_dir" ]] || die "Toolchain directory ${toolchain_dir} not found."
    
    # Source the 'activate' script if present to set ENV vars (SYSROOT, etc.)
    if [[ -f "$toolchain_dir/activate" ]]; then
        # shellcheck disable=SC1090
        source "$toolchain_dir/activate" > /dev/null
    else
        export PATH="$toolchain_dir/bin:$PATH"
    fi

    local bin_dir="$toolchain_dir/bin"
    [[ -d "$bin_dir" ]] || die "Toolchain bin directory ${bin_dir} missing."

    # Heuristic: Find first available gcc/as/ld with prefix in the bin dir
    CC_BIN=$(find "$bin_dir" -maxdepth 1 -name "*-gcc" | head -n1 || true)
    [[ -n "$CC_BIN" ]] || die "No cross gcc found under ${bin_dir}."
    
    AS_BIN=$(find "$bin_dir" -maxdepth 1 -name "*-as" | head -n1 || true)
    if [[ -z "$AS_BIN" ]]; then
        AS_BIN="$CC_BIN"
        AS_WRAPS_CC=1
    else
        AS_WRAPS_CC=0
    fi
    
    LD_BIN=$(find "$bin_dir" -maxdepth 1 -name "*-ld" | head -n1 || true)
    [[ -n "$LD_BIN" ]] || LD_BIN="$CC_BIN"

    # Special Case: i386 (32-bit Intel).
    # Cross toolchains usually don't ship 'nasm'.
    # If we are building for i386, we can use the host's 'nasm' if available.
    if [[ "$tag" == "i386" ]]; then
        NASM_BIN=$(command -v nasm || true)
    fi
}

ARCH_CFLAGS=()
ARCH_ASFLAGS=()
ARCH_NASMFLAGS=()
ARCH_LDFLAGS=()

# Sets flags specific to the architecture (ABI, Endianness, Instruction Sets)
apply_arch_defaults() {
    local tag="$1"
    ARCH_CFLAGS=()
    ARCH_ASFLAGS=()
    ARCH_NASMFLAGS=()
    ARCH_LDFLAGS=()
    
    case "$tag" in
        mips)
            # MIPS32 Release 2, Little Endian, 32-bit ABI
            ARCH_CFLAGS=(-march=mips32r2 -EL -mabi=32)
            ARCH_ASFLAGS=(-EL)
            ARCH_LDFLAGS=(-EL)
            ;;
        s390x)
            # IBM Z, z13 generation
            ARCH_CFLAGS=(-march=z13)
            ;;
        aarch64)
            # ARM 64-bit
            ARCH_CFLAGS=(-march=armv8-a)
            ;;
        armv7)
            # ARM 32-bit Hard Float
            ARCH_CFLAGS=(-march=armv7-a -mfpu=neon -mfloat-abi=hard)
            ;;
        riscv64)
            # RISC-V 64-bit General Purpose
            ARCH_CFLAGS=(-march=rv64gc -mabi=lp64d)
            ;;
        i386)
            # x86 32-bit
            ARCH_CFLAGS=(-m32)
            ARCH_ASFLAGS=(--32)
            # NASM: 32-bit ELF output
            ARCH_NASMFLAGS=(-f elf32)
            ARCH_LDFLAGS=(-m elf_i386) # Hint for raw ld
            ;;
        native|"")
            # Native (assumed x86_64 linux)
            # NASM: 64-bit ELF output
            ARCH_NASMFLAGS=(-f elf64)
            ;;
        *)
            warn "No arch-specific defaults registered for tag '${tag}'."
            ;;
    esac
}

# --- ARGUMENT PARSING HELPER ---

# Splits user arguments into Source Files, Assembler Flags, and Linker Flags.
# This is necessary because 'nasm' or 'as' will choke on linker flags like '-lfoo',
# so we must segregate them and pass them only to the final link step.
split_asm_args() {
    local -n _sources=$1
    local -n _asmflags=$2
    local -n _linkargs=$3
    shift 3
    local -a exts=("$@") # Accepted extensions for sources (e.g. .s .asm)
    [[ ${#exts[@]} -gt 0 ]] || die "split_asm_args requires at least one extension"

    local pending=""
    for arg in "${USER_ARGS[@]}"; do
        # Handle arguments with values (e.g., -I /path)
        if [[ -n "$pending" ]]; then
            local value="$arg"
            if [[ "$pending" == "-I" || "$pending" == "-i" ]]; then
                value=$(ensure_trailing_slash "$value")
            fi
            _asmflags+=("${pending}${value}")
            pending=""
            continue
        fi

        # Check if arg is a source file
        local matched_ext=0
        for ext in "${exts[@]}"; do
            if [[ "$arg" == *"${ext}" ]]; then
                matched_ext=1
                break
            fi
        done
        if [[ $matched_ext -eq 1 ]]; then
            _sources+=("$arg")
            continue
        fi

        # Categorize flags
        case "$arg" in
            # Flags taking an argument next
            -I|-i|-P|-p|-D|-U|-f|-o)
                pending="$arg"
                ;;
            # Flags joined with argument (e.g. -I/path)
            -I*|-i*)
                local prefix=${arg:0:2}
                local value=${arg:2}
                _asmflags+=("${prefix}$(ensure_trailing_slash "$value")")
                ;;
            # Linker specific flags (libraries, search paths, layout)
            -l*|-L*|-static|-shared|-pie|-no-pie|-z*)
                _linkargs+=("$arg")
                ;;
            # Other assembler flags (defines, warnings)
            -P*|-p*|-D*|-U*|-f*|-w*|-M*)
                _asmflags+=("$arg")
                ;;
            # Output flag joined (-oFile)
            -o*)
                 _linkargs+=("$arg")
                 ;;
            *)
                # Unknown/Generic args go to linker (like object files .o)
                _linkargs+=("$arg")
                ;;
        esac
    done
    [[ -z "$pending" ]] || die "Flag ${pending} expects a value"
}

# --- EXECUTION MODES ---

# Mode: Compile
# Driver: GCC
# Use Case: C files, or Assembly files that need standard library (libc).
run_compile_mode() {
    local -a cmd=("$CC_BIN")
    cmd+=("${BASE_CFLAGS[@]}")
    cmd+=("${ARCH_CFLAGS[@]}")
    cmd+=("${USER_ARGS[@]}")
    print_cmd "${cmd[@]}"
    "${cmd[@]}"
}

# Mode: Asm
# Driver: GNU as + ld
# Use Case: Pure assembly without libc. Good for shellcode/kernel/bare-metal.
run_asm_mode() {
    local -a asm_sources=()
    local -a asm_flags=()
    local -a link_args=()
    split_asm_args asm_sources asm_flags link_args ".s" ".S"
    [[ ${#asm_sources[@]} -gt 0 ]] || die "ASM mode requires at least one .s/.S file."

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'cleanup_tmpdir "${tmpdir:-}"' EXIT

    local -a objects=()
    local src obj base
    for src in "${asm_sources[@]}"; do
        [[ -f "$src" ]] || die "Assembly source '$src' not found."
        base=$(basename "$src")
        obj="$tmpdir/${base%.*}.o"
        local -a asm_cmd
        asm_cmd=("$AS_BIN")
        asm_cmd+=("${BASE_ASFLAGS[@]}")
        asm_cmd+=("${ARCH_ASFLAGS[@]}")
        asm_cmd+=("${asm_flags[@]}")
        # If AS is GCC, it needs -c to stop it from linking immediately
        if [[ $AS_WRAPS_CC -eq 1 ]]; then
            asm_cmd+=(-c "$src" -o "$obj")
        else
            asm_cmd+=("$src" -o "$obj")
        fi
        print_cmd "${asm_cmd[@]}"
        "${asm_cmd[@]}"
        objects+=("$obj")
    done

    # Linking with raw ld
    local -a link_cmd=("$LD_BIN")
    link_cmd+=("${BASE_LDFLAGS[@]}")
    link_cmd+=("${ARCH_LDFLAGS[@]}")
    link_cmd+=("${objects[@]}")
    link_cmd+=("${link_args[@]}")
    print_cmd "${link_cmd[@]}"
    "${link_cmd[@]}"

    cleanup_tmpdir "$tmpdir"
    trap - EXIT
}

# Mode: Nasm
# Driver: nasm + ld
# Use Case: Pure Intel syntax assembly without libc.
run_nasm_mode() {
    [[ -n "$NASM_BIN" ]] || die "nasm binary not detected in PATH."

    local -a asm_sources=()
    local -a asm_flags=()
    local -a link_args=()
    split_asm_args asm_sources asm_flags link_args ".asm" ".ASM"
    [[ ${#asm_sources[@]} -gt 0 ]] || die "NASM mode expects at least one .asm file."

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'cleanup_tmpdir "${tmpdir:-}"' EXIT

    local -a objects=()
    local src obj base asm_cmd
    for src in "${asm_sources[@]}"; do
        [[ -f "$src" ]] || die "Assembly source '$src' not found."
        base=$(basename "$src")
        obj="$tmpdir/${base%.*}.o"
        asm_cmd=("$NASM_BIN")
        asm_cmd+=("${BASE_NASMFLAGS[@]}")
        asm_cmd+=("${ARCH_NASMFLAGS[@]}")
        asm_cmd+=("${asm_flags[@]}")
        asm_cmd+=("$src" -o "$obj")
        print_cmd "${asm_cmd[@]}"
        "${asm_cmd[@]}"
        objects+=("$obj")
    done

    # Using raw ld
    local -a link_cmd=("$LD_BIN")
    link_cmd+=("${BASE_LDFLAGS[@]}")
    link_cmd+=("${ARCH_LDFLAGS[@]}")
    link_cmd+=("${objects[@]}")
    link_cmd+=("${link_args[@]}")
    print_cmd "${link_cmd[@]}"
    "${link_cmd[@]}"

    cleanup_tmpdir "$tmpdir"
    trap - EXIT
}

# Mode: Nasm-GCC
# Driver: nasm + gcc
# Use Case: Intel syntax assembly that calls printf/scanf/etc.
run_nasm_gcc_mode() {
    [[ -n "$NASM_BIN" ]] || die "nasm binary not detected in PATH."

    local -a asm_sources=()
    local -a asm_flags=()
    local -a link_args=()
    split_asm_args asm_sources asm_flags link_args ".asm" ".ASM"
    [[ ${#asm_sources[@]} -gt 0 ]] || die "NASM-GCC mode expects at least one .asm file."

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'cleanup_tmpdir "${tmpdir:-}"' EXIT

    local -a objects=()
    local src obj base asm_cmd
    for src in "${asm_sources[@]}"; do
        [[ -f "$src" ]] || die "Assembly source '$src' not found."
        base=$(basename "$src")
        obj="$tmpdir/${base%.*}.o"
        asm_cmd=("$NASM_BIN")
        asm_cmd+=("${BASE_NASMFLAGS[@]}")
        asm_cmd+=("${ARCH_NASMFLAGS[@]}")
        asm_cmd+=("${asm_flags[@]}")
        asm_cmd+=("$src" -o "$obj")
        print_cmd "${asm_cmd[@]}"
        "${asm_cmd[@]}"
        objects+=("$obj")
    done

    # Using GCC driver to link (provides libc and start files)
    local -a link_cmd=("$CC_BIN")
    link_cmd+=("${BASE_CFLAGS[@]}") # Use CFLAGS for link-time options like -no-pie
    link_cmd+=("${ARCH_CFLAGS[@]}")
    link_cmd+=("${objects[@]}")
    link_cmd+=("${link_args[@]}")
    print_cmd "${link_cmd[@]}"
    "${link_cmd[@]}"

    cleanup_tmpdir "$tmpdir"
    trap - EXIT
}

# --- MAIN ENTRY POINT ---

main() {
    local cli_tag=""
    local mode="compile"
    USER_ARGS=()

    # Parse CLI Arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -T|--tag)
                [[ $# -ge 2 ]] || die "--tag requires an argument"
                cli_tag="$2"; shift 2;;
            -M|--mode)
                [[ $# -ge 2 ]] || die "--mode requires an argument"
                mode="$2"; shift 2;;
            --list-tags)
                list_tags; exit 0;;
            -h|--help)
                usage; exit 0;;
            --)
                shift
                USER_ARGS+=("$@")
                break;;
            *)
                USER_ARGS+=("$1"); shift;;
        esac
    done

    [[ ${#USER_ARGS[@]} -gt 0 ]] || die "No compilation arguments provided."

    # Normalize Mode Strings
    case "$mode" in
        asm|assemble)
            mode="asm";;
        compile|c|default)
            mode="compile";;
        nasm|native-asm)
            mode="nasm";;
        nasm-gcc|nasm-libc|native-nasm-gcc)
            mode="nasm-gcc";;
        *)
            die "Unsupported mode '$mode'."
            ;;
    esac

    # Resolve Architecture Tag
    local resolved_tag
    resolved_tag=$(resolve_tag "$cli_tag")
    
    # Informational logging about what config is active
    if [[ -z "$cli_tag" && -n "${LAB_ARCH:-}" ]]; then
        local env_lower
        env_lower=$(printf '%s' "${LAB_ARCH:-}" | lower)
        if [[ -z "$resolved_tag" ]]; then
            info "LAB_ARCH=${LAB_ARCH:-} maps to native toolchain."
        else
            info "Using LAB_ARCH=${LAB_ARCH:-} (tag ${resolved_tag})."
        fi
    fi

    # Initialize Paths and Flags
    setup_toolchain "$resolved_tag"
    apply_arch_defaults "$resolved_tag"
    
    # Guard against using NASM on non-Intel architectures
    # NASM is valid for 'native' (assumed x86_64) and 'i386'
    if [[ "$mode" == "nasm" || "$mode" == "nasm-gcc" ]]; then
        if [[ $MODE_NATIVE -ne 1 && "$resolved_tag" != "i386" ]]; then
             die "NASM modes are only available for native (x64) and i386 builds. Current tag: ${resolved_tag:-native}"
        fi
    fi

    info "Mode: ${mode^^} | Toolchain: ${TOOLCHAIN_TAG}"

    # Dispatch to specific mode handler
    case "$mode" in
        compile)
            run_compile_mode
            ;;
        asm)
            run_asm_mode
            ;;
        nasm)
            run_nasm_mode
            ;;
        nasm-gcc)
            run_nasm_gcc_mode
            ;;
    esac
}

declare -a USER_ARGS
main "$@"
