#!/bin/bash
## ==============================================================================
## Activate Cross-Arch Docker-Based Environment
## By AHMZ - November 2025
## Usage: source lab-activate <arch>
## NOTE: This script must be SOURCED, not executed.
## ==============================================================================

# Check if script is sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ -z "$ZSH_EVAL_CONTEXT" ]]; then
    echo "Error: This script must be sourced."
    echo "Usage: source lab-activate <arch>"
    exit 1
fi

TARGET="$1"
VALID_ARCHS="amd64 mips s390x riscv64 armv7 aarch64 i386"

if [ -z "$TARGET" ]; then
    echo "Usage: source lab-activate <arch>"
    echo "Valid: $VALID_ARCHS"
    return 1 2>/dev/null || exit 1
fi

# Validation (Simple grep check)
if [[ ! " $VALID_ARCHS " =~ " $TARGET " ]]; then
    echo "Error: Invalid architecture '$TARGET'"
    return 1 2>/dev/null || exit 1
fi

# Set the variable
export LAB_ARCH="$TARGET"

# Attempt to pull a matching Docker image for this architecture.
# Behavior:
# - If `LAB_IMAGE` environment variable is set, try that exact image first.
# - Otherwise try a short list of common image-name candidates.
# - If `docker` is not available or all pulls fail, abort with an error.
if command -v docker &> /dev/null; then
    # Candidate images to try (in order). Users may override with LAB_IMAGE.
    if [ -n "${LAB_IMAGE:-}" ]; then
        CANDIDATES=("$LAB_IMAGE")
    else
        CANDIDATES=(
            "ghcr.io/ahmz1833/cross-arch:${LAB_ARCH}"
            "cross-arch:${LAB_ARCH}"
        )
    fi

    PULLED_IMAGE=""
    for img in "${CANDIDATES[@]}"; do
        echo ">>> Pulling Docker image: $img"
        if docker pull "$img"; then
            PULLED_IMAGE="$img"
            echo ">>> Successfully pulled: $img"
            break
        else
            echo "--- Failed to pull: $img -- trying next candidate if any"
        fi
    done

    if [ -z "$PULLED_IMAGE" ]; then
        echo "[ERROR] Could not pull any Cross-Arch Docker image for architecture: $LAB_ARCH"
        echo "Tried: ${CANDIDATES[*]}"
        return 1 2>/dev/null || exit 1
    fi

    # Export the successfully pulled image for downstream wrappers to reuse.
    export LAB_DOCKER_IMAGE="$PULLED_IMAGE"
else
    echo "[ERROR] 'docker' command not found. Install Docker to use Docker-mode activation."
    return 1 2>/dev/null || exit 1
fi

# Ensure wrapper script installed
if ! command -v __lab_wrapper &> /dev/null; then
	echo "Error: Wrapper script '__lab_wrapper' not found."
	echo "Please ensure Cross-Arch Docker Wrapper is installed correctly."
	return 1 2>/dev/null || exit 1
fi

# Ensure lab commands are installed and linked to wrapper
LAB_COMMANDS=("ar" "as" "build" "debug" "g++" "gcc" "gdb" "ld" "objdump" "readelf" "run" "strip")
for cmd in "${LAB_COMMANDS[@]}"; do
	if ! command -v "lab-$cmd" &> /dev/null; then
		echo "Installing lab-$cmd command..."
		ln -sf "$(command -v __lab_wrapper)" "/usr/local/bin/lab-$cmd"
	fi
done

# Update Prompt (Optional - for better UX)
# Saves original PS1 to restore later if needed
if [ -z "$ORIG_PS1" ]; then
    export ORIG_PS1="$PS1"
fi

# Set a colored prompt: [Cross-Arch:mips] user@host...
if [ -n "$BASH_VERSION" ]; then
    export PS1="\[\e[36m\][Cross-Arch:$LAB_ARCH]\[\e[m\] $ORIG_PS1"
elif [ -n "$ZSH_VERSION" ]; then
    export PS1="%F{cyan}[Cross-Arch:$LAB_ARCH]%f $ORIG_PS1"
fi

echo ">>> Environment activated for: $LAB_ARCH"
echo ">>> Run 'lab-gcc', 'lab-debug', etc."
