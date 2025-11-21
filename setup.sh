#!/bin/bash
#######################################
# Installer of bootlin cross-compilation tools
# for any architecture lab environment.
# By AHMZ
# November 2025
TARGET_ARCH="s390x-z13"
ARCH_ABBREV="s390x"
ARCH_ABBREV_UPPER="S390x"
TOOLCHAIN_VER="stable-2025.08-1"
LIBC="glibc"
#######################################

FILENAME="${TARGET_ARCH}--${LIBC}--${TOOLCHAIN_VER}.tar.xz"
DOWNLOAD_URL="https://toolchains.bootlin.com/downloads/releases/toolchains/${TARGET_ARCH}/tarballs/${FILENAME}"
INSTALL_DIR="/opt/${ARCH_ABBREV}-lab"

GREEN='\033[0;32m'
YLW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MGN='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo
echo -e "${CYAN}>>> Starting ${ARCH_ABBREV_UPPER} Lab Setup (Bootlin ${TOOLCHAIN_VER})...${NC}"

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Please run as root (sudo ./setup.sh)${NC}"
  exit 1
fi

# 2. Install system dependencies
echo 
echo -e "${CYAN}>>> Installing System Dependencies...${NC}"
if command -v apt-get &> /dev/null; then  # Debian, Ubuntu
    apt-get update && apt-get install -y qemu-user gdb-multiarch make wget xz-utils file
elif command -v pacman &> /dev/null; then # Arch Linux, Manjaro
    pacman -Sy --needed --noconfirm qemu-user gdb make wget xz
elif command -v dnf &> /dev/null; then    # Fedora, RHEL, CentOS
    dnf install -y qemu-user gdb make wget xz file
else
    echo -e "${RED}Unsupported package manager. Please install dependencies manually.${NC}"
    exit 1
fi
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install dependencies. Please check your package manager.${NC}"
    exit 1
fi

# 3. Download and extract the toolchain (idempotent)
echo
# If the toolchain appears already installed (contains bin files), skip download/extract
if [ -d "$INSTALL_DIR" ] && [ -n "$(find "$INSTALL_DIR/bin" -maxdepth 1 -type f 2>/dev/null | head -n 1)" ]; then
    echo -e "${YLW}>>> Toolchain already appears installed in ${INSTALL_DIR}. Skipping download/extract.${NC}"
else
    echo -e "${CYAN}>>> Downloading Toolchain (${FILENAME})...${NC}"
    mkdir -p "$INSTALL_DIR"
    wget -q --show-progress "$DOWNLOAD_URL" -O "/tmp/toolchain.tar.xz"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Download failed! Check the URL or Version.${NC}"
        exit 1
    fi

    echo -e "${BLUE}>>> Extracting...${NC}"
    tar xf "/tmp/toolchain.tar.xz" -C "$INSTALL_DIR" --strip-components=1
    rm "/tmp/toolchain.tar.xz"
fi

# 4. Automatically find sysroot path
SYSROOT_PATH=$(find "$INSTALL_DIR" -type d -name "sysroot" | head -n 1)

if [ -z "$SYSROOT_PATH" ]; then
    echo -e "${RED}Error: Could not find sysroot directory inside the toolchain!${NC}"
    exit 1
fi

echo
echo -e "${GREEN}>>> Found Sysroot at: $SYSROOT_PATH${NC}"

# 5. Create activation script
echo
echo -e "${CYAN}>>> Creating Activation Script...${NC}"
ACTIVATE_FILE="$INSTALL_DIR/activate"

cat > "$ACTIVATE_FILE" <<EOL
# Lab Environment
export PATH="$INSTALL_DIR/bin:\$PATH"
export QEMU_LD_PREFIX="$SYSROOT_PATH"
echo -e "${MGN}>>> Setting QEMU_LD_PREFIX to: ${BOLD}\$QEMU_LD_PREFIX${NC}"

# Aliases for ease of use
# Note: Binary names might be different based on the toolchain naming conventions
for _TOOL in as ar gcc g++ ld objdump readelf strip gdb; do
    if [ -z "\$(find $INSTALL_DIR/bin -name "*-linux-gnu-\${_TOOL}" | head -n 1)" ]; then
        echo "${YLW}Warning: Could not find \${_TOOL} in the toolchain. ${NC}"
    fi
    alias ${ARCH_ABBREV}-\${_TOOL}="\$(find $INSTALL_DIR/bin -name "*-linux-gnu-\${_TOOL}" | head -n 1)"
done
echo 
echo -e "${GREEN}${BOLD}>>> ${ARCH_ABBREV_UPPER} Environment (${TARGET_ARCH}) Activated!${NC}"
echo -e "${CYAN}>>> You can now use ${BOLD}${ARCH_ABBREV}-gcc, ${ARCH_ABBREV}-as, ${ARCH_ABBREV}-gdb, etc.${NC}"
echo 
EOL

chmod +x "$ACTIVATE_FILE"

echo
echo
echo -e "${GREEN}${BOLD}>>> Installation Complete!${NC}"
echo -e "Run: ${MGN}${BOLD}source $ACTIVATE_FILE${NC} to start."
echo 
