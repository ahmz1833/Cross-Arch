#!/usr/bin/env bash
set -e
## ==============================================================================
## Docker wrapper script to run lab commands inside the appropriate container
## By AHMZ - November 2025
## It mounts the relevant host paths into the container (using common ancestor)
## (It requires LAB_ARCH to be set, and identifies command by ${0##*/})
## Usage with ln -sf /usr/local/bin/__lab_wrapper to desired command names
## ==============================================================================

# --- 1. Check Environment Variable ---
if [ -z "$LAB_ARCH" ]; then
    echo -e "\033[0;31mError: LAB_ARCH is not set.\033[0m"
    echo "Please activate an architecture first:"
    echo "  source lab-activate <arch>"
    echo "OR"
    echo "  export LAB_ARCH=<arch>"
    exit 1
fi

# Helper function for cross-platform realpath (macOS doesn't have realpath by default)
get_real_path() {
    python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$1"
}

IMAGE_NAME="ghcr.io/ahmz1833/cross-arch:${LAB_ARCH}"
CMD_NAME=$(basename "$0")

# --- 2. Path Translation Logic (Common Ancestor) ---
ARGS=("$@")
FILE_PATHS=()

# Collect file arguments
for arg in "${ARGS[@]}"; do
    if [ -e "$arg" ]; then
        FILE_PATHS+=("$(get_real_path "$arg")")
    fi
done

# Calculate Mount Point
if [ ${#FILE_PATHS[@]} -eq 0 ]; then
    HOST_MOUNT_ROOT=$(pwd)
else
    # Python script to find common path
    HOST_MOUNT_ROOT=$(python3 -c "import os, sys; print(os.path.commonpath(sys.argv[1:]))" "${FILE_PATHS[@]}")
    if [ -f "$HOST_MOUNT_ROOT" ]; then
        HOST_MOUNT_ROOT=$(dirname "$HOST_MOUNT_ROOT")
    fi
fi

CONTAINER_MOUNT_POINT="/workspace"

# Rewrite Arguments
NEW_ARGS=()
for arg in "${ARGS[@]}"; do
    if [ -e "$arg" ]; then
        ABS_ARG=$(get_real_path "$arg")
        REL_PATH="${ABS_ARG#$HOST_MOUNT_ROOT/}"
        if [ "$ABS_ARG" == "$HOST_MOUNT_ROOT" ]; then
             NEW_ARGS+=("$CONTAINER_MOUNT_POINT")
        else
             NEW_ARGS+=("$CONTAINER_MOUNT_POINT/$REL_PATH")
        fi
    else
        NEW_ARGS+=("$arg")
    fi
done

# --- 3. Construct Docker Command ---

CMD_STRING="$CMD_NAME ${NEW_ARGS[*]}"

# Cleanup mechanism to ensure container is removed even if it hangs or script is killed
CID_FILE="/tmp/cross-arch-lab-$$.cid"
cleanup() {
    if [ -f "$CID_FILE" ]; then
        local cid
        cid=$(cat "$CID_FILE")
        if [ -n "$cid" ]; then
            docker rm -f "$cid" >/dev/null 2>&1
        fi
        rm -f "$CID_FILE"
    fi
}
trap cleanup EXIT

# Execute
# --init: Ensures proper signal handling (e.g. segfaults) and zombie reaping
# --cidfile: Tracks container ID for robust cleanup

# Determine flags: Always interactive (-i), but TTY (-t) only if connected to a terminal
# Removed --rm to prevent hanging on some systems; cleanup is handled by trap
DOCKER_FLAGS=(--cap-add=SYS_PTRACE --security-opt seccomp=unconfined -i --init --cidfile "$CID_FILE" --platform linux/amd64)
if [ -t 0 ]; then
    DOCKER_FLAGS+=(-t)
fi

# Disable set -e temporarily to capture exit code
set +e
docker run "${DOCKER_FLAGS[@]}" \
    -u "$(id -u):$(id -g)" \
    -v "$HOST_MOUNT_ROOT:$CONTAINER_MOUNT_POINT" \
    -w "$CONTAINER_MOUNT_POINT" \
    -e LAB_ARCH="$LAB_ARCH" \
    "$IMAGE_NAME" \
    bash -c "$CMD_STRING"
EXIT_CODE=$?
set -e

# Handle Core Dump / Signals (simulate shell message)
if [ $EXIT_CODE -gt 128 ]; then
    SIG=$((EXIT_CODE - 128))
    if [ $SIG -eq 11 ]; then
        echo "Segmentation fault (core dumped)" >&2
    elif [ $SIG -eq 6 ]; then
        echo "Aborted (core dumped)" >&2
    elif [ $SIG -eq 4 ]; then
        echo "Illegal instruction (core dumped)" >&2
    elif [ $SIG -eq 8 ]; then
        echo "Floating point exception (core dumped)" >&2
    elif [ $SIG -ne 2 ] && [ $SIG -ne 15 ]; then # Ignore SIGINT/SIGTERM
        echo "Terminated with signal $SIG" >&2
    fi
fi

exit $EXIT_CODE
