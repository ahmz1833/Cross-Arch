#!/usr/bin/env bash
set -u
## ==============================================================================
## Debugging helper script for cross-architecture binaries
## By AHMZ - November 2025
## Usage: lab-debug [options] <executable> [program-args...]
## ==============================================================================

# --- Configuration ---
DEFAULT_PORT=1234
LAB_BASE_DIR="/opt"
SESSION_BASE_NAME="debug-session"

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YLW='\033[0;33m'
NC='\033[0m'

# --- Helper Functions ---

usage() {
    echo -e "${BLUE}Usage: $0 [options] <executable> [program-args...]${NC}"
    echo
    echo "Options:"
    echo "  -p, --port <port>   Starting port"
    echo "  -T, --tag <arch>    Architecture tag (e.g., mips, aarch64)."
    echo "                      Default: \$LAB_ARCH variable or native debugging if unset."
    echo "  -h, --help          Show this help"
    echo
    echo "Examples:"
    echo "  $0 ./native_program                 (Native Debugging)"
    echo "  $0 -T mips ./mips_program           (Cross Debugging with QEMU)"
    echo "  LAB_ARCH=mips $0 ./my_host_program  (Cross Debugging with QEMU)"
    exit 1
}

find_free_port() {
    local port=$1
    if ! command -v ss &> /dev/null; then 
        echo -e "${YLW}Warning: 'ss' not found. Using default port $port.${NC}" >&2
        echo "$port"
        return
    fi
    
    while ss -lptn "sport = :$port" 2>/dev/null | grep -q ":$port"; do
        echo -e "${YLW}Port $port is busy, trying next...${NC}" >&2
        ((port++))
    done
    echo "$port"
}

get_qemu_binary() {
    local tag=$1
    case "$tag" in
        mips)    echo "qemu-mipsel" ;;
        i386)    echo "qemu-i386" ;;
        armv7)   echo "qemu-arm" ;;
        aarch64) echo "qemu-aarch64" ;;
        riscv64) echo "qemu-riscv64" ;;
        s390x)   echo "qemu-s390x" ;;
        *)       echo "qemu-$tag" ;;
    esac
}

# --- Argument Parsing ---

TAG=""
PORT=$DEFAULT_PORT
EXECUTABLE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -T|--tag)
            TAG="$2"; shift 2;;
        -p|--port)
            PORT="$2"; shift 2;;
        -h|--help)
            usage;;
        -* )
            echo -e "${RED}Unknown option: $1${NC}"; usage;;
        * )
            # First non-option is the executable; everything after it are program args
            if [[ -z "${EXECUTABLE}" ]]; then
                EXECUTABLE="$1"
                shift
                # Capture remaining args as program arguments
                EXEC_ARGS=("$@")
                break
            else
                shift
            fi
            ;;
    esac
done

# Ensure `EXEC_ARGS` is an array and is empty when no program args were provided.
if [ "${EXEC_ARGS+set}" != "set" ]; then
    EXEC_ARGS=()
else
    # normalize to an array (preserve empty-string elements if explicitly provided)
    EXEC_ARGS=("${EXEC_ARGS[@]}")
fi

# Fallback to LAB_ARCH env when -T/--tag was omitted
if [[ -z "$TAG" ]]; then
    LAB_ARCH_ENV="${LAB_ARCH:-}"
    if [[ -n "$LAB_ARCH_ENV" ]]; then
        LAB_ARCH_LOWER=$(printf '%s' "$LAB_ARCH_ENV" | tr '[:upper:]' '[:lower:]')
        if [[ "$LAB_ARCH_LOWER" != "amd64" && "$LAB_ARCH_LOWER" != "x86_64" ]]; then
            TAG="$LAB_ARCH_ENV"
            echo -e "${CYAN}>>> Using LAB_ARCH=${LAB_ARCH_ENV} for cross debugging.${NC}"
        fi
    fi
fi

# --- Validation Common ---
if [ -z "$EXECUTABLE" ] || [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Executable not found."
    exit 1
fi
[ ! -x "$EXECUTABLE" ] && chmod +x "$EXECUTABLE"

# Determine full path to executable
if [[ "$EXECUTABLE" == /* ]]; then
    TARGET_BIN="$EXECUTABLE"
else
    TARGET_BIN="./$EXECUTABLE"
fi

# --- Prepare Commands ---
FINAL_PORT=$(find_free_port "$PORT")

# --- Detect Architecture Mismatch (Docker on Apple Silicon) ---
#USE_QEMU_FOR_AMD64=0
#if [ -z "$TAG" ] && [ -f "/.dockerenv" ]; then
#    if grep -qE "aarch64|arm64" /proc/version; then
#        echo -e "${YLW}>>> Detected Docker on Apple Silicon. Forcing QEMU for x86_64/amd64.${NC}"
        USE_QEMU_FOR_AMD64=1
#    fi
#fi

if [ -z "$TAG" ] && [ "$USE_QEMU_FOR_AMD64" -eq 0 ]; then
    # === NATIVE MODE (Real Linux amd64) ===
    MODE="NATIVE"

    # Build escaped argument string
    EXEC_ARGS_ESC=""
    for __a in "${EXEC_ARGS[@]}"; do
        __esc=${__a//\\/\\\\}
        __esc=${__esc//\"/\\\"}
        EXEC_ARGS_ESC+=" \"$__esc\""
    done
    
    if [[ -n "${EXEC_ARGS_ESC}" ]]; then
        RUNNER_CMD="gdbserver localhost:$FINAL_PORT $TARGET_BIN$EXEC_ARGS_ESC"
    else 
        RUNNER_CMD="gdbserver localhost:$FINAL_PORT $TARGET_BIN"
    fi

    EXTRA_SET_COMMAND="-ex \"set disassembly-flavor intel\""
    
    GDB_BIN="gdb"
    if ! command -v gdb &> /dev/null; then echo -e "${RED}Error: gdb not found.${NC}"; exit 1; fi
    if ! command -v gdbserver &> /dev/null; then echo -e "${RED}Error: gdbserver not found.${NC}"; exit 1; fi

else
    # === CROSS MODE OR EMULATED AMD64 ===
    MODE="CROSS"
    
    if [ "$USE_QEMU_FOR_AMD64" -eq 1 ]; then
        QEMU_BIN="qemu-x86_64"
        GDB_BIN="gdb"
        EXTRA_SET_COMMAND="-ex \"set disassembly-flavor intel\""
    else
        QEMU_BIN=$(get_qemu_binary "$TAG")
        source "/opt/${TAG}-lab/activate" > /dev/null || { echo -e "${RED}Error: Could not source toolchain for tag: $TAG${NC}"; exit 1; }
        
        if [ -z "${QEMU_LD_PREFIX:-}" ]; then
            CURRENT_SYSROOT=$(grep "export QEMU_LD_PREFIX" "$ACTIVATE_SCRIPT" | cut -d'"' -f2)
        else
            CURRENT_SYSROOT="$QEMU_LD_PREFIX"
        fi
        EXTRA_SET_COMMAND="-ex \"set sysroot $CURRENT_SYSROOT\""
        
        if command -v gdb-multiarch &> /dev/null; then
            GDB_BIN="gdb-multiarch"
        elif command -v gdb &> /dev/null; then
            GDB_BIN="gdb"
        else
            echo -e "${RED}Error: Neither 'gdb-multiarch' nor 'gdb' found.${NC}"
            exit 1
        fi
    fi

    # Build escaped argument string
    EXEC_ARGS_ESC=""
    for __a in "${EXEC_ARGS[@]}"; do
        __esc=${__a//\\/\\\\}
        __esc=${__esc//\"/\\\"}
        EXEC_ARGS_ESC+=" \"$__esc\""
    done

    # QEMU Command Construction
    if [[ -n "${EXEC_ARGS_ESC}" ]]; then
        RUNNER_CMD="QEMU_LD_PREFIX=\"${QEMU_LD_PREFIX:-}\" $QEMU_BIN -g $FINAL_PORT $TARGET_BIN$EXEC_ARGS_ESC"
    else 
        RUNNER_CMD="QEMU_LD_PREFIX=\"${QEMU_LD_PREFIX:-}\" $QEMU_BIN -g $FINAL_PORT $TARGET_BIN"
    fi

    if ! command -v "$QEMU_BIN" &> /dev/null; then echo -e "${RED}Error: $QEMU_BIN not found. Please install QEMU user binaries.${NC}"; exit 1; fi
fi

# --- Wrap Commands in Shell ---
CMD_SERVER_RAW="echo -e \"${GREEN}>>> Starting Program under Debugger...${NC}\"; $RUNNER_CMD; \
	echo -e \"${YLW}>>> Program exited with code \$?. Pressing any key to close...${NC}\"; read -n 1 -s"

CMD_CLIENT_RAW="sleep 1; echo -e \"${GREEN}>>> Connecting GDB to Target...${NC}\"; \
	export TERM=xterm-256color; \
	$GDB_BIN -q $TARGET_BIN \
	-ex \"target remote localhost:$FINAL_PORT\" \
	${EXTRA_SET_COMMAND:-} \
	-ex \"layout asm\" \
	-ex \"layout regs\" \
	-ex \"focus cmd\" \
	-ex \"refresh\""

CMD_SERVER_FINAL="/bin/bash -c '${CMD_SERVER_RAW}'"
CMD_CLIENT_FINAL="/bin/bash -c '${CMD_CLIENT_RAW}'"

# --- Tmux Execution (No Shell Mode) ---
if ! command -v tmux &> /dev/null; then echo -e "${RED}Error: tmux not found.${NC}"; exit 1; fi

SESSION_NAME="${SESSION_BASE_NAME}-${TAG:-native}"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    SESSION_NAME="${SESSION_NAME}-$((RANDOM % 1000))"
fi

echo -e "${CYAN}>>> Starting Session: $SESSION_NAME (Port: $FINAL_PORT)${NC}"
tmux new-session -d -s "$SESSION_NAME" "$CMD_SERVER_FINAL"
tmux split-window -h -t "$SESSION_NAME" "$CMD_CLIENT_FINAL"
tmux set-option -t "$SESSION_NAME" mouse on
tmux attach-session -t "$SESSION_NAME"
echo -e "${CYAN}>>> Session Ended: $SESSION_NAME${NC}"
