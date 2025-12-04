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

echo -e "${BLUE}>>> Cross-Arch Lab Installer (Docker Mode)${NC}"

# 1. Check Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Please run as root (or use sudo).${NC}"
  echo -e "Example: ${CYAN}curl -sL ... | sudo bash${NC}"
  exit 1
fi

# 2. Check Dependencies
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"; exit 1
fi
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not found. Please install Docker Desktop.${NC}"; exit 1
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

# 5. Install Wrappers
echo -e "${BLUE}>>> Configuring Docker Wrappers in $BIN_DIR...${NC}"

# Install the config manager
ln -sf "$INSTALL_DIR/scripts/d_activate.sh" "$BIN_DIR/lab-activate"

# Install the core smart wrapper
WRAPPER_SRC="$INSTALL_DIR/scripts/d_wrapper.sh"
chmod +x "$WRAPPER_SRC"
ln -sf "$WRAPPER_SRC" "$BIN_DIR/__lab_wrapper"

# 5. Create Symlinks for ALL tools
# These commands will all be routed through the Docker wrapper
LAB_COMMANDS=("ar" "as" "build" "debug" "g++" "gcc" "ld" "objdump" "readelf" "run" "strip")
for cmd in "${LAB_COMMANDS[@]}"; do
	if ! command -v "lab-$cmd" &> /dev/null; then
		echo "Installing lab-$cmd command..."
		ln -sf "$BIN_DIR/__lab_wrapper" "/usr/local/bin/lab-$cmd"
	fi
done

echo -e "${GREEN}>>> Installation Complete!${NC}"
echo -e "Next Steps:"
echo -e "  1. Activate architecture:  ${CYAN}source lab-activate mips${NC}"
echo -e "  2. Build code:             ${CYAN}lab-build main.S -o main${NC}"
echo -e "  3. Debug code:             ${CYAN}lab-debug ./main${NC}"
