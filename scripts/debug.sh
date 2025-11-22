#!/usr/bin/env bash
set -u

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
    echo -e "${BLUE}Usage: $0 [options] <executable>${NC}"
    echo
    echo "Options:"
    echo "  -T, --tag <arch>    Architecture tag (e.g., mips, aarch64)."
    echo "                      If OMITTED, runs in NATIVE mode (Host Debugging)."
    echo "  -p, --port <port>   Starting port"
    echo "  -h, --help          Show this help"
    echo
    echo "Examples:"
    echo "  $0 ./my_host_program          (Native Debugging)"
    echo "  $0 -T mips ./mips_program     (Cross Debugging with QEMU)"
    exit 1
}

find_free_port() {
    local port=$1
    if ! command -v ss &> /dev/null; then echo -e "${RED}Error: ss command not found. Please install iproute2 package.${NC}"; exit 1; fi
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
        -*)
            echo -e "${RED}Unknown option: $1${NC}"; usage;;
        *)
            EXECUTABLE="$1"; shift;;
    esac
done

# --- Validation Common ---
if [ -z "$EXECUTABLE" ] || [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Executable not found."
    exit 1
fi
[ ! -x "$EXECUTABLE" ] && chmod +x "$EXECUTABLE"

# --- Prepare Commands ---
FINAL_PORT=$(find_free_port "$PORT")
if [ -z "$TAG" ]; then
    # === NATIVE MODE ===
    MODE="NATIVE"
    RUNNER_CMD="gdbserver localhost:$FINAL_PORT ./$EXECUTABLE"
	GDB_BIN="gdb"
	if ! command -v gdb &> /dev/null; then echo -e "${RED}Error: gdb not found.${NC}"; exit 1; fi
	if ! command -v gdbserver &> /dev/null; then echo -e "${RED}Error: gdbserver not found.${NC}"; exit 1; fi
else
    # === CROSS MODE ===
    MODE="CROSS"
    QEMU_BIN=$(get_qemu_binary "$TAG")
    source "/opt/${TAG}-lab/activate" || { echo -e "${RED}Error: Could not source toolchain for tag: $TAG${NC}"; exit 1; }
	RUNNER_CMD="QEMU_LD_PREFIX=\"$QEMU_LD_PREFIX\" $QEMU_BIN -g $FINAL_PORT ./$EXECUTABLE"
	GDB_BIN=$(find "/opt/${TAG}-lab/bin" -name "*-linux-gdb" | head -n 1)
    if [ -z "$GDB_BIN" ] || [ ! -x "$GDB_BIN" ]; then echo -e "${RED}Error: Cross GDB binary not found in /opt/${TAG}-lab/bin.${NC}"; exit 1; fi
    if ! command -v "$QEMU_BIN" &> /dev/null; then echo -e "${RED}Error: $QEMU_BIN not found. Please install QEMU user binaries.${NC}"; exit 1; fi
fi

# --- Wrap Commands in Shell ---
CMD_SERVER_RAW="echo -e \"${GREEN}>>> Starting Program under Debugger...${NC}\"; $RUNNER_CMD; \
	echo -e \"${YLW}>>> Program exited with code \$?. Pressing any key to close...${NC}\"; read -n 1 -s"

CMD_CLIENT_RAW="sleep 1; echo -e \"${GREEN}>>> Connecting GDB to Target...${NC}\"; $GDB_BIN -q ./$EXECUTABLE \
	-ex \"target remote localhost:$FINAL_PORT\" \
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
