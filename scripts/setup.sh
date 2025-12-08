#!/usr/bin/env bash
set -u
## ==============================================================================
## Clean and argument-driven installer for Bootlin cross toolchains
## By AHMZ - November 2025
## Usage: sudo lab-setup [options]
## ==============================================================================

# Defaults (kept from the original)
SUPPORTED_ARCHS=("mips" "s390x" "aarch64" "armv7" "riscv64" "i386")
TOOLCHAIN_VER="stable-2025.08-1"
LIBC="glibc"
FORCE=0
TAG=""

# Colors
GREEN='\033[0;32m'
YLW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MGN='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    cat <<USG
Usage: $0 [options]

Options:
  -T, --tag TAG            Use a predefined architecture tag (supported: ${SUPPORTED_ARCHS[*]})
  -t, --target ARCH        Specify target triplet manually (don't use with --tag)
  -l, --libc LIBC          Specify libc name (glibc/musl/ulibc) (default: ${LIBC})
  -v, --version VER        Specify toolchain version string (default: ${TOOLCHAIN_VER})
  -d, --install-dir DIR    Specify installation directory (overrides tag default)
  --arch-abbrev ABBREV     Explicitly set short architecture abbreviation (overrides tag)
  --arch-abbrev-upper STR  Explicitly set uppercase abbreviation (overrides tag)
  -f, --force              Force re-install / overwrite existing install
  -h, --help               Show this help

Default Behavior:
  If no arguments are provided, the script sets up nasm and amd64 development environment.

Examples:
  # Use a predefined tag (recommended):
  sudo $0 --tag s390x

  # Use a tag but override the install directory:
  sudo $0 --tag aarch64 --install-dir /opt/custom-aarch64

  # Specify everything manually (no tag):
  sudo $0 --target riscv64-lp64d --version stable-2025.08-1 --install-dir /opt/riscv-lab

  # Default setup for nasm and amd64:
  sudo $0

  # Force reinstallation:
  sudo $0 --tag s390x --force
USG
}

APT_MISSING=()
PACMAN_MISSING=()
DNF_MISSING=()
YUM_MISSING=()
check_tool() {
    local binary="$1"
    local apt_pkg="$2"
    local pac_pkg="$3"
    local dnf_pkg="$4"
    if ! command -v "$binary" >/dev/null 2>&1; then
        [ -n "$apt_pkg" ] && APT_MISSING+=("$apt_pkg")
        [ -n "$pac_pkg" ] && PACMAN_MISSING+=("$pac_pkg")
        [ -n "$dnf_pkg" ] && DNF_MISSING+=("$dnf_pkg")
        [ -n "$dnf_pkg" ] && YUM_MISSING+=("$dnf_pkg")
    fi
}

install_missing_packages() {
    if command -v apt-get >/dev/null 2>&1; then
        if [ ${#APT_MISSING[@]} -gt 0 ]; then
            echo -e "${CYAN}>>> Installing missing packages via APT: ${APT_MISSING[*]}${NC}"
            apt-get update -y && apt-get install -y "${APT_MISSING[@]}"
        fi
    elif command -v pacman >/dev/null 2>&1; then
        if [ ${#PACMAN_MISSING[@]} -gt 0 ]; then
            echo -e "${CYAN}>>> Installing missing packages via Pacman: ${PACMAN_MISSING[*]}${NC}"
            pacman -Sy --noconfirm --needed "${PACMAN_MISSING[@]}"
        fi
    elif command -v dnf >/dev/null 2>&1; then
        if [ ${#DNF_MISSING[@]} -gt 0 ]; then
            echo -e "${CYAN}>>> Installing missing packages via DNF: ${DNF_MISSING[*]}${NC}"
            dnf install -y "${DNF_MISSING[@]}"
        fi
    elif command -v yum >/dev/null 2>&1; then
        if [ ${#YUM_MISSING[@]} -gt 0 ]; then
            echo -e "${CYAN}>>> Installing missing packages via YUM: ${YUM_MISSING[*]}${NC}"
            yum install -y "${YUM_MISSING[@]}"
        fi
    else
        echo -e "${YLW}Warning: Could not detect package manager. Please manually install missing tools.${NC}"
    fi
}

# Parse args
while [ "$#" -gt 0 ]; do
    case "$1" in
        -T|--tag)
            TAG="$2"; shift 2;;
        -t|--target)
            TARGET_ARCH="$2"; shift 2;;
        --arch-abbrev)
            ARCH_ABBREV="$2"; shift 2;;
        --arch-abbrev-upper)
            ARCH_ABBREV_UPPER="$2"; shift 2;;
        -l|--libc|--libc=*)
            if [[ "$1" == *=* ]]; then LIBC="${1#*=}"; shift; else LIBC="$2"; shift 2; fi;;
        -v|--version)
            TOOLCHAIN_VER="$2"; shift 2;;
        -d|--install-dir)
            INSTALL_DIR="$2"; shift 2;;
        -f|--force)
            FORCE=1; shift;;
        -h|--help)
            usage; exit 0;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"; usage; exit 1;;
    esac
done

# Ensure variables are defined before accessing them
: "${TARGET_ARCH:=}"  # Default to empty if not set
: "${ARCH_ABBREV:=}"  # Default to empty if not set
: "${ARCH_ABBREV_UPPER:=}"  # Default to empty if not set
: "${INSTALL_DIR:=}"  # Default to empty if not set

# Validate conflicting or incomplete options
if [ -n "$TAG" ] && [ -n "$TARGET_ARCH" ]; then
    echo -e "${RED}Error: --tag (-T) and --target (-t) cannot be used together.${NC}"
    exit 1
fi

if [ -n "$TARGET_ARCH" ]; then
    if [ -z "$ARCH_ABBREV" ] || [ -z "$ARCH_ABBREV_UPPER" ] || [ -z "$INSTALL_DIR" ]; then
        echo -e "${RED}Error: When using --target (-t), you must also specify --arch-abbrev, --arch-abbrev-upper, and --install-dir.${NC}"
        exit 1
    fi
fi

# Supported architectures registry: tag:TARGET_ARCH:ARCH_ABBREV:ARCH_ABBREV_UPPER:INSTALL_DIR
# Add or remove entries as needed. Users can pass --tag <tag> to pick one.
SUPPORTED_ARCHS=(
    "amd64:amd64:amd64:AMD64:/opt/amd64-lab"
    "mips:mips32el:mipsel:MIPS:/opt/mips-lab"
    "s390x:s390x-z13:s390x:S390x:/opt/s390x-lab"
    "aarch64:aarch64:aarch64:AARCH64:/opt/aarch64-lab"
    "armv7:armv7-eabihf:arm:ARM-v7:/opt/armv7-lab"
    "riscv64:riscv64-lp64d:riscv64:RISC-V:/opt/riscv64-lab"
    "i386:x86-core2:i386:x86-32bit:/opt/i386-lab"
)

# If a tag was provided, try to resolve it
if [ -n "${TAG}" ]; then
    # Normalize some common aliases (allow mipsel, x86_64, arm, x86, etc.)
    case "${TAG,,}" in
        mipsel|mips32el|mips) TAG="mips" ;;
        amd64|x86_64) TAG="amd64" ;;
        arm|armv7|armv7-eabihf) TAG="armv7" ;;
        i386|x86|i86pc) TAG="i386" ;;
        aarch64|arm64) TAG="aarch64" ;;
        riscv|riscv64) TAG="riscv64" ;;
        s390x|s390) TAG="s390x" ;;
        *) ;;
    esac
    found=0
    OLDIFS=$IFS; IFS=':'
    for entry in "${SUPPORTED_ARCHS[@]}"; do
        read -r tag targ abbrev abv_up instdir <<< "$entry"
        if [ "$tag" = "$TAG" ]; then
            TARGET_ARCH="$targ"
            ARCH_ABBREV="$abbrev"
            ARCH_ABBREV_UPPER="$abv_up"
            INSTALL_DIR="$instdir"
            found=1
            break
        fi
    done
    IFS=$OLDIFS
    if [ "$found" -ne 1 ]; then
        echo -e "${RED}Unknown tag: ${TAG}. See SUPPORTED_ARCHS in the script.${NC}"
        exit 1
    fi
fi

# Recompute filename/url after any tag/overrides
FILENAME="${TARGET_ARCH}--${LIBC}--${TOOLCHAIN_VER}.tar.xz"
DOWNLOAD_URL="https://toolchains.bootlin.com/downloads/releases/toolchains/${TARGET_ARCH}/tarballs/${FILENAME}"

echo
echo -e "${CYAN}>>> Starting ${ARCH_ABBREV_UPPER} Lab Setup (Bootlin ${TOOLCHAIN_VER})...${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (sudo $0 ...)${NC}"
	echo 
    exit 1
fi

# If Target Arch is empty or amd64
if [ -z "$TARGET_ARCH" ] || [ "$TARGET_ARCH" = "amd64" ] || [ "$TARGET_ARCH" = "x86_64" ]; then
    echo -e "${CYAN}>>> No arguments provided. Checking dependencies for nasm and amd64...${NC}"
    TAG="amd64"
    TARGET_ARCH="amd64"
    ARCH_ABBREV="amd64"
    ARCH_ABBREV_UPPER="AMD64"
    INSTALL_DIR=""
    # Reset lists
    APT_MISSING=()
    PACMAN_MISSING=()
    DNF_MISSING=()
    YUM_MISSING=()
    # Check for tools specific to Native build
    # Format: check_tool "binary" "apt" "pacman" "dnf"
    check_tool "tmux" "tmux" "tmux" "tmux"
    check_tool "nasm" "nasm" "nasm" "nasm"
    check_tool "make" "build-essential" "base-devel" "make"
    check_tool "gcc"  "build-essential" "base-devel" "gcc"
    # Run Installation
    install_missing_packages
    echo -e "${GREEN}>>> Setup for nasm and amd64 environment checked/completed.${NC}"
    exit 0
fi

echo -e "${CYAN}>>> Checking system dependencies for Cross-Arch...${NC}"
# Reset lists just in case
APT_MISSING=()
PACMAN_MISSING=()
DNF_MISSING=()
YUM_MISSING=()
# Check for tools specific to Cross build
check_tool "tmux" "tmux" "tmux" "tmux"
check_tool "make" "make" "make" "make"
check_tool "wget" "wget" "wget" "wget"
check_tool "curl" "curl" "curl" "curl"
check_tool "xz"   "xz-utils" "xz" "xz"
check_tool "file" "file" "file" "file"
# Check for GDB
# Ubuntu uses gdb-multiarch, Arch/Fedora usually include multiarch support in standard gdb
check_tool "gdb" "gdb-multiarch" "gdb" "gdb"
# Check for QEMU User
check_tool "qemu-${ARCH_ABBREV}" "qemu-user" "qemu-user" "qemu-user"
# Run Installation
install_missing_packages
echo -e "${GREEN}>>> System dependencies checked/completed.${NC}"

# Idempotent install: skip unless FORCE
echo 
if [ -d "$INSTALL_DIR" ] && [ "$FORCE" -ne 1 ] && [ -n "$(find "$INSTALL_DIR/bin" -maxdepth 1 -type f 2>/dev/null | head -n 1)" ]; then
    echo -e "${YLW}>>> Toolchain already installed in ${INSTALL_DIR}. Use --force to reinstall.${NC}"
else
    tmpfile="$(mktemp -p /tmp bootlin.XXXXXX)"
    trap 'rm -f "$tmpfile"' EXIT

    echo -e "${CYAN}>>> Downloading ${FILENAME} ...${NC}"
    if command -v wget >/dev/null 2>&1; then
        wget -O "$tmpfile" "$DOWNLOAD_URL" --progress=dot:giga || { echo -e "${RED}Download failed via wget.${NC}"; exit 1; }
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$tmpfile" "$DOWNLOAD_URL" || { echo -e "${RED}Download failed via curl.${NC}"; exit 1; }
    else
        echo -e "${RED}No downloader (wget/curl) found. Install one and retry.${NC}"; exit 1
    fi

    echo -e "${BLUE}>>> Preparing install directory: ${CYAN}${BOLD}${INSTALL_DIR}${NC}"
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    echo -e "${BLUE}>>> Extracting to ${BOLD}${INSTALL_DIR}${NC} ...${NC}"
    if command -v tar >/dev/null 2>&1; then
        tar xf "$tmpfile" -C "$INSTALL_DIR" --strip-components=1 || { echo -e "${RED}Extraction failed.${NC}"; exit 1; }
    else
        echo -e "${RED}tar not found. Cannot extract.${NC}"; exit 1
    fi
    rm -f "$tmpfile"
    trap - EXIT
fi

# Try to find sysroot
SYSROOT_PATH=""
if [ -d "$INSTALL_DIR/sysroot" ]; then
    SYSROOT_PATH="$INSTALL_DIR/sysroot"
else
    SYSROOT_PATH=$(find "$INSTALL_DIR" -type d -name "sysroot" 2>/dev/null | head -n 1 || true)
fi

echo
if [ -z "$SYSROOT_PATH" ]; then
    echo -e "${YLW}Warning: Could not find 'sysroot' in the toolchain. Attempting to continue...${NC}"
else
    echo -e "${GREEN}>>> Found sysroot: ${SYSROOT_PATH}${NC}"
fi

# Create activation script with explicit values
ACTIVATE_FILE="$INSTALL_DIR/activate"
echo
echo -e "${CYAN}>>> Creating activation script: ${ACTIVATE_FILE}${NC}"
cat > "$ACTIVATE_FILE" <<EOL
#!/usr/bin/env bash
# Activate the ${TARGET_ARCH} toolchain environment
export PATH="$INSTALL_DIR/bin:\$PATH"
$( [ -n "$SYSROOT_PATH" ] && echo "export QEMU_LD_PREFIX=\"$SYSROOT_PATH\"" )
echo 
echo -e "${MGN}>>> Setting QEMU_LD_PREFIX to: ${BOLD}\$QEMU_LD_PREFIX${NC}"
echo -e "${GREEN}${BOLD}>>> ${ARCH_ABBREV_UPPER} Environment (${TARGET_ARCH}) Activated!${NC}"
echo -e "${CYAN}>>> You can now use ${BOLD}lab-gcc, lab-as, lab-run, lab-build, lab-debug etc.${NC}"
echo 
# Convenience helper: prefixed tools (if present)
_TC_DIR="$INSTALL_DIR/bin"
for _TOOL in gcc as g++ ld objdump readelf strip ar; do
    _bin="\$(find $INSTALL_DIR/bin -name "*-linux-\${_TOOL}" | head -n 1)"
    if [ -z "\$_bin" ]; then
        echo -e "${YLW}Warning: Could not find \${_TOOL} in the toolchain. ${NC}"
    fi
    alias lab-\${_TOOL}="\$_bin"
done
alias lab-run="qemu-${ARCH_ABBREV} -L \$QEMU_LD_PREFIX"
EOL
chmod +x "$ACTIVATE_FILE"

echo
echo -e "${GREEN}${BOLD}>>> Installation complete.${NC}"
echo -e "Run: ${MGN}${BOLD}source lab-activate ${TAG}${NC} to start using the toolchain."
echo
