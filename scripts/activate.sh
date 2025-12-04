#!/bin/bash
## ==============================================================================
## Lab Environment Activation Script
## By AHMZ - November 2025
## Usage:
##   1. Exec:   lab-activate <TAG>        (Spawns new shell)
##   2. Source: source lab-activate <TAG> (Modifies current shell, Bash/Zsh only)
## ==============================================================================

# --- 1. Helper Functions ---

get_shell_name() {
    basename "${SHELL:-/bin/bash}"
}

is_sourced() {
    # Detect if script is being sourced or executed
    if [ -n "$ZSH_VERSION" ]; then 
        [[ -o ksharrays ]] && [[ "${#funcstack[@]}" -gt 0 ]] || [[ -n "${ZSH_EVAL_CONTEXT}" && "${ZSH_EVAL_CONTEXT}" != "toplevel" ]]
    elif [ -n "$BASH_VERSION" ]; then
        [[ "${BASH_SOURCE[0]}" != "${0}" ]]
    else
        return 1
    fi
}

validate_args() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: lab-activate <ARCH-TAG> | native"
        return 1
    fi
    TAG="$1"
    LAB_DIR="/opt/${TAG}-lab"
    
    # Handle Native/Reset
    if [[ "$TAG" =~ ^(native|amd64|x86_64)$ ]]; then
        return 0
    fi

    if [[ ! -d "$LAB_DIR" ]]; then
        echo "Error: Directory '${LAB_DIR}' not found."
        return 1
    fi
    return 0
}

# --- 2. Shell Specific Logics ---

spawn_bash() {
    local rcfile
    rcfile=$(mktemp)
    
    cat <<EOF > "$rcfile"
        # 1. Load User Configs
        [ -f /etc/bash.bashrc ] && source /etc/bash.bashrc
        [ -f ~/.bashrc ] && source ~/.bashrc
        
        # 2. Lab Configs
        rm -f "$rcfile"  # Self-destruct temp file
        if [[ "$TAG" =~ ^(native|amd64|x86_64)$ ]]; then
            unset LAB_ARCH
            export PS1="\${PS1//($OLD_TAG-lab)/}"
            echo -e "\033[0;36m>>> Reset to Native.\033[0m"
        else
            export LAB_ARCH="$TAG"
            [ -f "$LAB_DIR/activate" ] && source "$LAB_DIR/activate" || export PATH="$LAB_DIR/bin:\$PATH"
            export PS1="\[\e[1;33m\]($TAG-lab)\[\e[0m\] \$PS1"
            echo -e "\033[0;32m>>> Environment: $TAG\033[0m"
        fi
EOF
    exec bash --rcfile "$rcfile" -i
}

spawn_zsh() {
    local zdot
    zdot=$(mktemp -d)
    
    # Zsh needs a .zshrc in ZDOTDIR
    cat <<EOF > "$zdot/.zshrc"
        # 1. Load User Configs
        [ -f ~/.zshrc ] && source ~/.zshrc
        
        # 2. Lab Configs
        if [[ "$TAG" =~ ^(native|amd64|x86_64)$ ]]; then
            unset LAB_ARCH
            echo -e "\033[0;36m>>> Reset to Native.\033[0m"
        else
            export LAB_ARCH="$TAG"
            [ -f "$LAB_DIR/activate" ] && source "$LAB_DIR/activate" || export PATH="$LAB_DIR/bin:\$PATH"
            export PROMPT="%F{yellow}($TAG-lab)%f \$PROMPT"
            echo -e "\033[0;32m>>> Environment: $TAG\033[0m"
        fi
EOF
    export ZDOTDIR="$zdot"
    exec zsh
}

spawn_fish() {
    local cmds
    if [[ "$TAG" =~ ^(native|amd64|x86_64)$ ]]; then
        cmds="set -e LAB_ARCH; echo -e '\033[0;36m>>> Reset to Native.\033[0m'"
    else
        # Note: Fish cannot source Bash scripts directly. We manually set vars.
        # If your toolchain 'activate' has aliases, they won't load in Fish (limitation).
        cmds="
            set -gx LAB_ARCH $TAG;
            set -gx PATH $LAB_DIR/bin \$PATH;
            functions -c fish_prompt _old_fish_prompt;
            function fish_prompt; set_color yellow; echo -n '($TAG-lab) '; set_color normal; _old_fish_prompt; end;
            echo -e '\033[0;32m>>> Environment: $TAG\033[0m';
        "
    fi
    exec fish -C "$cmds"
}

# --- 3. Main Execution Flow ---

validate_args "$@" || exit 1
TAG="$1"
OLD_TAG="${LAB_ARCH:-}" # Save old tag to remove from prompt if resetting

# A. Source Mode (Modifies CURRENT Shell) - Only Bash/Zsh
if is_sourced; then
    if [[ "$TAG" =~ ^(native|amd64|x86_64)$ ]]; then
        unset LAB_ARCH LAB_DIR 2>/dev/null

        # Clear aliases and functions if any
        LAB_COMMANDS=("ar" "as" "g++" "gcc" "ld" "objdump" "readelf" "strip")
        for cmd in "${LAB_COMMANDS[@]}"; do
            unalias "lab-$cmd" 2>/dev/null
            unset -f "lab-$cmd" 2>/dev/null
            alias "lab-$cmd"=$cmd 2>/dev/null
        done
        alias lab-run="env PATH=.:$PATH" 2>/dev/null

        # Try to clean prompt (Best effort)
        [ -n "$BASH_VERSION" ] && export PS1="${PS1//($OLD_TAG-lab)/}"
        echo "Environment reset to native (amd64)."
        return 0
    fi

    export LAB_ARCH="$TAG"
    if [ -f "$LAB_DIR/activate" ]; then
        source "$LAB_DIR/activate"
    else
        export PATH="$LAB_DIR/bin:$PATH"
    fi
    
    # Simple Prompt update for Source mode
    if [ -n "$BASH_VERSION" ]; then
        export PS1="($TAG-lab) $PS1"
    elif [ -n "$ZSH_VERSION" ]; then
        export PROMPT="($TAG-lab) $PROMPT"
    fi
    echo "Environment loaded for $TAG."
    return 0
fi

# B. Exec Mode (Spawns NEW Shell) - Supports Bash, Zsh, Fish
CURRENT_SHELL=$(get_shell_name)

case "$CURRENT_SHELL" in
    bash|sh) spawn_bash ;;
    zsh)     spawn_zsh ;;
    fish)    spawn_fish ;;
    *)       echo "Unsupported shell: $CURRENT_SHELL. Defaulting to Bash."; spawn_bash ;;
esac
