#!/bin/bash
set -e

# --- Configuration ---
REPO_URL="https://github.com/ahmz1833/Cross-Arch.git"
INSTALL_DIR="/opt/cross-arch"
BIN_DIR="/usr/local/bin"

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YLW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}>>> Cross-Arch Lab Installer (Native Mode)${NC}"

# 1. Check Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Please run as root (or use sudo).${NC}"
  echo -e "Example: ${CYAN}curl -sL ... | sudo bash${NC}"
  exit 1
fi

# 2. Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    exit 1
fi

# 3. Clone or Pull Repository
echo -e "${BLUE}>>> Fetching Repository...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing repository in $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull
else
    echo "Cloning into $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 4. Ensure BIN_DIR is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo -e "${YLW}>>> $BIN_DIR is not in PATH. Adding to shell config...${NC}"
    SHELL_RC=""
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        USER_HOME="$HOME"
    fi
    
    if [ -f "$USER_HOME/.zshrc" ]; then
        SHELL_RC="$USER_HOME/.zshrc"
    elif [ -f "$USER_HOME/.bashrc" ]; then
        SHELL_RC="$USER_HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_RC" ]; then
        if ! grep -q "export PATH=.*$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
            echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
            echo -e "${GREEN}Added $BIN_DIR to $SHELL_RC${NC}"
            echo -e "${YLW}Note: Run 'source $SHELL_RC' or restart your terminal.${NC}"
        fi
    fi
fi

# 5. Create Symlinks
echo -e "${BLUE}>>> Installing Symlinks to $BIN_DIR...${NC}"

# Core Scripts
ln -sf "$INSTALL_DIR/scripts/setup.sh"        "$BIN_DIR/lab-setup"
ln -sf "$INSTALL_DIR/scripts/build.sh"        "$BIN_DIR/lab-build"
ln -sf "$INSTALL_DIR/scripts/debug.sh"        "$BIN_DIR/lab-debug"
ln -sf "$INSTALL_DIR/scripts/activate.sh"     "$BIN_DIR/lab-activate"

echo -e "${GREEN}>>> Installation Complete!${NC}"
echo -e "Next Steps:"
echo -e "  1. Install a toolchain:  ${CYAN}sudo lab-setup -T mips${NC}"
echo -e "  2. Activate env:         ${CYAN}source lab-activate mips${NC}"
