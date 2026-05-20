#!/usr/bin/env bash

# beauty-slurm: Automated Uninstaller
# Cleans up the path configurations in user shell configuration files.

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
PURPLE='\033[35m'
CYAN='\033[36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${RED}${BOLD}========================================================================${NC}"
echo -e "                   ${RED}${BOLD}Beauty SLURM Automated Uninstaller${NC}"
echo -e "${RED}${BOLD}========================================================================${NC}"

# Detect shell file
SHELL_NAME=$(basename "$SHELL")
SHELL_RC=""

case "$SHELL_NAME" in
    zsh)
        SHELL_RC="$HOME/.zshrc"
        ;;
    bash)
        if [ -f "$HOME/.bashrc" ]; then
            SHELL_RC="$HOME/.bashrc"
        else
            SHELL_RC="$HOME/.bash_profile"
        fi
        ;;
    *)
        SHELL_RC="$HOME/.profile"
        ;;
esac

if [ -f "$SHELL_RC" ]; then
    echo -e "⚙️  Cleaning up path config in ${CYAN}$SHELL_RC${NC}..."
    
    # Remove the beauty-slurm and slurm-utils blocks using sed
    sed -i.bak '/# >>> beauty-slurm initialize >>>/,/# <<< beauty-slurm initialize <<</d' "$SHELL_RC" 2>/dev/null || \
    sed -i '' '/# >>> beauty-slurm initialize >>>/,/# <<< beauty-slurm initialize <<</d' "$SHELL_RC" 2>/dev/null
    sed -i.bak '/# >>> slurm-utils initialize >>>/,/# <<< slurm-utils initialize <<</d' "$SHELL_RC" 2>/dev/null || \
    sed -i '' '/# >>> slurm-utils initialize >>>/,/# <<< slurm-utils initialize <<</d' "$SHELL_RC" 2>/dev/null
    rm -f "${SHELL_RC}.bak"
    
    echo -e "   ${GREEN}✔ Removed path configurations and environment flags.${NC}"
else
    echo -e "⚠️  No shell configuration file found at $SHELL_RC."
fi

echo -e "${RED}${BOLD}========================================================================${NC}"
echo -e "        ${GREEN}${BOLD}👋 Beauty SLURM has been successfully uninstalled.${NC}"
echo -e "${RED}${BOLD}========================================================================${NC}"
echo -e "Note: Please restart your terminal or reload your shell profile to apply changes."
echo -e "${RED}${BOLD}========================================================================${NC}"
