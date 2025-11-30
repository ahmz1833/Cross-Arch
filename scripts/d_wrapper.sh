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

IMAGE_NAME="ghcr.io/ahmz1833/cross-arch:${LAB_ARCH}"
CMD_NAME=$(basename "$0")

# --- 2. Path Translation Logic (Common Ancestor) ---
ARGS=("$@")
FILE_PATHS=()

# Collect file arguments
for arg in "${ARGS[@]}"; do
    if [ -e "$arg" ]; then
        FILE_PATHS+=("$(realpath "$arg")")
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
        ABS_ARG=$(realpath "$arg")
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

IT_FLAGS=""
if [ -t 0 ]; then IT_FLAGS="-it"; fi

CMD_STRING="$CMD_NAME ${NEW_ARGS[*]}"

# Execute
exec docker run $IT_FLAGS --rm \
    --platform linux/amd64 \
    -u "$(id -u):$(id -g)" \
    -v "$HOST_MOUNT_ROOT:$CONTAINER_MOUNT_POINT" \
    -w "$CONTAINER_MOUNT_POINT" \
    -e LAB_ARCH="$LAB_ARCH" \
    "$IMAGE_NAME" \
    bash -l -c "$CMD_STRING"
